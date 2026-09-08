---
title: "Lab-in-a-Box"
date: 2026-02-12
description: "Complete research lab infrastructure deployment using pyinfra, bundling Forgejo-Aneksajo, HedgeDoc, and supporting services"
summary: "A pyinfra-based deployment that installs and configures an entire research infrastructure stack -- Forgejo-Aneksajo, HedgeDoc, and supporting services -- on a single server or set of servers. Configuration as code, stored in git."
categories: ["Infrastructure"]
tags: ["CON-contrib", "MIH", "deployment", "lab", "infrastructure", "forgejo", "hedgedoc", "pyinfra", "complete-stack"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments"
  homepage: "https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments"
  issues: "https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments/issues"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
  examples:
    - title: "Psychoinformatics Hub"
      url: "https://hub.psychoinformatics.de"
---

**Lab-in-a-Box** (LiaB) is a [pyinfra]({{< ref "pyinfra" >}})-based deployment project that bundles the entire con/serve infrastructure stack into a single, reproducible deployment. The goal is simple: give a research group a server (physical or virtual), run one deployment, and have a fully configured research infrastructure ready to use.

## The Problem

Setting up self-hosted research infrastructure is tedious and error-prone. A typical lab needs:

- A **git forge** that supports large files and DataLad datasets
- A **collaborative editor** for meeting notes and documentation
- **TLS certificates**, **reverse proxies**, and **DNS configuration**
- **Backup schedules**, **monitoring**, and **log aggregation**
- **User management** and **authentication** across services

Each service has its own installation procedure, configuration format, and operational requirements. Most research groups either give up and use SaaS (losing control of their data) or spend weeks on manual setup that is never documented well enough to reproduce.

## The Solution

Lab-in-a-Box encodes all of this in Python using pyinfra. The deployment is:

- **Declarative** -- the desired state is described in Python, pyinfra makes it so
- **Idempotent** -- running the deployment again after changes only applies the delta
- **Version-controlled** -- the entire deployment configuration lives in a git repository
- **Composable** -- individual services can be deployed or updated independently

## What Gets Deployed

The liab-deployments service catalog currently covers:

| Service | Purpose |
|---------|---------|
| [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) | Git forge with git-annex support: dataset hosting, code repos, issue tracking |
| forgejo-runner | CI runner for Forgejo Actions |
| [HedgeDoc]({{< ref "hedgedoc" >}}) | Collaborative markdown editor (SQLite-backed) |
| [copyparty]({{< ref "copyparty" >}}) | File sharing and upload front-end |
| [Photoview]({{< ref "photoview" >}}) | Photo gallery over a directory tree |
| ntfy | Push notifications |
| gatus | Uptime monitoring |
| dumpthings | Data dump viewer |
| gitannex-staticwww | Static websites served from git-annex repositories |

Caddy provides TLS termination and per-subdomain routing for all of them.

## Architecture

Every service follows the same pattern on a bare Debian server:

1. A dedicated system user (nologin shell, disabled password, fixed UID)
2. A rootless Podman container managed by a user-space systemd unit,
   with `loginctl enable-linger` so it survives logout
3. A Caddy reverse-proxy block for TLS and subdomain routing

```
Internet
   |
 Caddy (:443) -- TLS termination
   |
   +-- forgejo.lab.org  -> localhost:4000   (Podman, user "git")
   +-- hedgedoc.lab.org -> localhost:30000  (Podman, user "hedgedoc")
   +-- photos.lab.org   -> localhost:...    (Podman, user "photoview")
   +-- ...
```

Only Caddy is exposed; services bind to localhost. UFW allows SSH and HTTP(S)
only, fail2ban watches sshd, and secrets in the inventory are encrypted with
privy and decrypted at deploy time from `PRIVY_PASSWORD`.

## Usage

Inventories are Python dictionaries in the deployment scripts, keyed by
service, with per-site entries such as `serve_address`, `container_tag`,
`host_port`, `user` (a `(name, uid)` tuple), and a config asset:

```bash
git clone https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments.git
cd liab-deployments

# Bootstrap a fresh Debian server
pyinfra inventory.py deployments/bootstrap_server_mih-style.py

# Deploy a service
pyinfra inventory.py liab_deployments/deploy/hedgedoc.py

# Provision Forgejo user accounts from a TSV file
pyinfra inventory.py deployments/forgejo_aneksajo_users.py
```

Re-running a deployment applies only the delta. See the repository's
`CONTRIBUTING.md` for the inventory keys and the two deployment styles
(older scripts under `deployments/`, newer ones under `liab_deployments/deploy/`).

## Configuration as Code

Because the inventories, deployment scripts, and config assets all live in
git, every change to the infrastructure is tracked, attributable, and
reversible. You can `git diff` to see what changed, `git blame` to see who
changed it, and `git revert` to undo a problematic change.

## git-annex / DataLad Integration

**Integration level: git-only.**

Lab-in-a-Box does not use git-annex for its own deployment configs (they are small text files that belong in git proper). However, the *primary purpose* of the deployment is to stand up services -- especially Forgejo-Aneksajo -- that provide git-annex and DataLad support to the research group.

The deployment repository itself can be managed as a DataLad dataset for provenance tracking:

```bash
datalad create liab-config
cd liab-config
# ... add deployment configs ...
datalad save -m "Initial Lab-in-a-Box configuration"
```

## AI Readiness

**Level: ai-ready.**

The entire deployment is Python code with clear structure and naming. This makes it well-suited for:

- **AI-assisted configuration** -- LLMs can generate new service deployments from descriptions
- **Security review** -- AI tools can audit configurations for common mistakes
- **Documentation generation** -- deployment code can be summarized into operational runbooks
- **Troubleshooting** -- error logs and deployment state can be analyzed by AI assistants

## How It Ties Together

Lab-in-a-Box is the **integration point** for the entire con/serve infrastructure layer:

1. **[pyinfra]({{< ref "pyinfra" >}})** provides the deployment engine
2. **[Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}})** provides the dataset hosting platform
3. **[HedgeDoc]({{< ref "hedgedoc" >}})** provides collaborative documentation
4. **[DataLad Hub]({{< ref "datalad-hub" >}})** can be thought of as a managed Lab-in-a-Box deployment

For a research group, Lab-in-a-Box answers the question: "We have a server and we want to own our research data infrastructure. What do we install?" The answer is: run the Lab-in-a-Box deployment and you have everything you need.

## Limitations

- **Alpha status**: The deployment is functional but the service lineup and configuration structure are still evolving, and two deployment styles coexist.
- **Single-box focus**: The default deployment targets a single server. Multi-server deployments are possible but require manual inventory configuration.
- **Debian only**: The pyinfra operations target bare Debian servers. Other distributions would require adaptation.
- **Monitoring is basic**: gatus uptime checks and ntfy notifications are included; there is no metrics stack (Prometheus, Grafana).

## See Also

- [pyinfra]({{< ref "pyinfra" >}}) -- the deployment engine
- [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- the core forge service
- [HedgeDoc]({{< ref "hedgedoc" >}}) -- the collaborative editor
- [DataLad Hub]({{< ref "datalad-hub" >}}) -- hosted version of this concept
