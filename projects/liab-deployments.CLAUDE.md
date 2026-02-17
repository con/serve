# liab-deployments — Frozen Frontier Reference

> AI-consumable summary of [lab-in-a-box/liab-deployments](https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments).
> Distilled 2026-02 for future sessions that need deployment context without cloning.

## Architecture overview

**pyinfra** automates bare-Debian deployment via SSH.  Each service gets:

1. A dedicated **system user** (nologin shell, disabled password, specific UID)
2. A **rootless Podman** container managed by a **user-space systemd unit**
3. A **Caddy** reverse-proxy block for TLS termination and subdomain routing
4. **loginctl enable-linger** so services survive logout

```
Internet
   │
   ▼
 Caddy (:443)  ─── TLS termination ───┐
   │                                    │
   ├── service1.example.org ──→ localhost:{port1}  (Podman, user "svc1")
   ├── service2.example.org ──→ localhost:{port2}  (Podman, user "svc2")
   └── ...
```

## One-user-per-service pattern

| Aspect | Detail |
|--------|--------|
| Shell | `/usr/sbin/nologin` |
| Password | `!` (disabled) |
| Groups | `systemd-journal` |
| Home | `/home/{username}/` |
| Lingering | `loginctl enable-linger {username}` |
| Systemd dir | `~/.config/systemd/user/` |
| XDG_RUNTIME_DIR | `/run/user/{uid}` (set in `.bashrc`) |

Users are created with explicit UIDs (e.g., `('hedgedoc', 1006)`) to avoid
conflicts across services.

## Service catalog

### Forgejo-aneksajo (OLD-style deploy)

- **Image**: `hub.datalad.org/forgejo/forgejo-aneksajo:{version}-rootless-amd64`
- **Internal port**: 3000
- **Host port**: typically 4000
- **Volumes**:
  - `~/forgejo:/var/lib/gitea:Z`
  - `~/git:/var/lib/gitea/git:Z`
  - `~/custom:/var/lib/gitea/custom:Z`
  - `~/conf:/var/lib/gitea/custom/conf:Z`
- **UID mapping**: `--uidmap=1000:0:1 --uidmap=0:1:999` (container git → host user)
- **Config**: `app.ini` at `~/conf/app.ini`
- **Admin creation**: `podman exec forgejo forgejo admin user create --admin ...`
- **Customizations**: separate git-annex repo cloned into `~/custom/`

### HedgeDoc (NEW-style deploy)

- **Image**: `quay.io/hedgedoc/hedgedoc:alpine`
- **Internal port**: 3000
- **Host port**: typically 30000
- **Volumes**:
  - `~/db:/db:U` (SQLite + uploads)
  - `~/config:/config:ro`
- **Environment**: `CMD_CONFIG_FILE=/config/config.json`
- **User namespace**: `--userns=keep-id`

### Other services (pattern reference)

- **copyparty** — file sharing (`.container` systemd quadlet style)
- **ntfy** — push notifications
- **forgejo-runner** — CI runner with offline registration
- **gatus** — uptime monitoring
- **photoview** — photo gallery
- **dumpthings** — data dump viewer
- **gitannex-staticwww** — static site from git-annex

## Inventory / config structure

Inventories are **Python dicts** in deployment scripts:

```python
# OLD style (deployments/)
inventory = {
    'forgejo_aneksajo': [{
        'fqdn': "hub.edu.datalad.org",
        'container_tag': "hub.datalad.org/forgejo/forgejo-aneksajo:12-rootless-amd64",
        'app_ini': 'assets/forgejo_eduhub_app.ini',
        'forgejo_admin_user': ('username', 'email', 'encrypted_pw'),
        'user': 'git',
        'host_port': 4000,
        'accounts_specfile': 'assets/forgejo_eduhub_accounts.tsv',
    }],
}

# NEW style (liab_deployments/deploy/)
inventory = {
    'hedgedoc': {
        "sites": [{
            'serve_address': 'hedgedoc.psychoinformatics.de',
            'container_tag': 'quay.io/hedgedoc/hedgedoc:alpine',
            'config_file': 'assets/hedgedoc-psychoinformatics-config.json',
            'user': ('hedgedoc', 1006),
            'host_port': 30000,
        }],
    },
}
```

### Standard inventory keys (from CONTRIBUTING.md)

| Key | Meaning |
|-----|---------|
| `serve_address` | FQDN for the service |
| `container_tag` | Podman image reference |
| `host_port` | Port on host (container always 3000) |
| `user` | `(username, uid)` tuple |
| `config_file` / `config_file_asset` | Path to config asset |
| `data_dir` | Data directory on server |
| `systemd_service_params` | Extra systemd `[Service]` lines |
| `caddyfile_block_tmpl` | Caddy config template |

## Secrets management

Passwords are stored encrypted with **privy** (symmetric Fernet):

```python
'forgejo_admin_user': ('admin', 'admin@example.org', '1$2$dpbxrIP6iOi...==')
```

Decrypted at deploy time via `PRIVY_PASSWORD` environment variable.

## User provisioning model

File: `deployments/forgejo_aneksajo_users.py`

1. Reads a **TSV file**: `Name\tUsername\tEmail\tPassword`
2. Lists existing users: `podman exec forgejo forgejo admin user list`
3. Creates missing accounts:
   ```bash
   podman exec forgejo forgejo admin user create \
     --username {username} --email {email} \
     --password {password} --must-change-password false
   ```
4. Uses pyinfra `python.call()` callback to compare and create dynamically

## Security model

| Layer | Mechanism |
|-------|-----------|
| Containers | Rootless Podman, UID-mapped, no `--privileged` |
| Users | Dedicated nologin accounts, password disabled |
| Systemd | User-space units, lingering for persistence |
| Network | Only Caddy exposed; services bind to localhost |
| Firewall | UFW: allow SSH + HTTP(S) only |
| Brute-force | fail2ban on sshd via systemd journal |
| Sudo | `rootpw` — requires root password, not user's |
| TLS | Caddy auto-HTTPS via ACME |
| Secrets | privy-encrypted in inventory, never plaintext on disk |

## Deployment workflow

```bash
# Bootstrap a fresh Debian server
pyinfra inventory.py deployments/bootstrap_server_mih-style.py

# Deploy a service
pyinfra inventory.py liab_deployments/deploy/hedgedoc.py

# Provision users (Forgejo)
pyinfra inventory.py deployments/forgejo_aneksajo_users.py
```

## Key file locations on deployed servers

```
/home/{service_user}/
├── .config/systemd/user/{service}.service
├── .bashrc                     # XDG_RUNTIME_DIR export
├── conf/app.ini                # (Forgejo)
├── config/config.json          # (HedgeDoc, ntfy, etc.)
├── db/                         # SQLite databases
└── data/                       # Service-specific data

/etc/caddy/Caddyfile            # Reverse proxy config (root-owned)
```
