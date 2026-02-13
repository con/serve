---
title: "Conservation to External Resources"
date: 2026-02-12
description: "Patterns for publishing and backing up from git-annex/DataLad repositories to external storage, archives, and services"
---

The con/serve architecture has two halves: **ingestion** (pulling artifacts in) and **conservation** (pushing them out to durable, distributed locations). This page describes the outbound half -- how content in your git-annex vault gets replicated, published, and backed up to external resources.

The guiding principle is simple: **your data should exist in at least two places you control, and ideally also in a domain-specific archive that outlives your lab.**

## git-annex Special Remotes

The primary mechanism for outbound distribution is the [git-annex special remote](https://git-annex.branchable.com/special_remotes/). A special remote is a storage backend that git-annex can push content to and pull content from. git-annex ships with built-in support for several backends and has an extensible protocol for third-party implementations.

### Built-in Special Remotes

| Remote Type | Use Case |
|-------------|----------|
| **S3** | Amazon S3 and S3-compatible services (Wasabi, MinIO, Backblaze B2) |
| **rsync** | Any server with SSH and rsync -- the simplest backup target |
| **web** | Register URLs as content sources (not a backup target, but a distribution mechanism) |
| **bittorrent** | Distribute large datasets via BitTorrent |
| **directory** | Local or mounted filesystem path (USB drives, NAS, NFS mounts) |
| **glacier** | Amazon Glacier for cold archival storage |

### Third-Party Special Remotes

| Remote | Provider Coverage |
|--------|-------------------|
| **[git-annex-remote-rclone](https://github.com/DanielDent/git-annex-remote-rclone)** | 70+ cloud providers via [rclone]({{< ref "rclone" >}}) -- Google Drive, Dropbox, OneDrive, Azure, etc. |
| **[git-annex-remote-globus](https://github.com/CONP-PCNO/git-annex-remote-globus)** | Globus endpoints (CONP-PCNO-specific, not a generic Globus remote) |

### Example: Setting Up S3 Backup

```bash
# Configure an S3 special remote
git annex initremote s3-backup type=S3 \
    bucket=lab-archive-2026 \
    encryption=shared \
    chunk=100MiB

# Copy all content to S3
git annex copy --to s3-backup .

# Verify content is on S3
git annex whereis .
```

### Example: rclone to Google Drive

```bash
# Configure rclone (one-time setup)
rclone config
# ... configure a "gdrive" remote ...

# Configure git-annex to use rclone
git annex initremote gdrive type=external \
    externaltype=rclone \
    target=gdrive \
    prefix=lab-archive

# Copy content
git annex copy --to gdrive .
```

## DataLad Publishing

DataLad provides higher-level commands for publishing datasets to various targets. These wrap git-annex operations with dataset-aware logic (handling nested subdatasets, metadata, etc.).

### datalad push

```bash
# Push to any configured sibling (git remote + optional annex special remote)
datalad push --to origin

# Push including all subdatasets
datalad push --to origin --recursive
```

### datalad create-sibling-*

DataLad includes commands for creating siblings on various platforms:

| Command | Target |
|---------|--------|
| `create-sibling-github` | GitHub repositories |
| `create-sibling-gitlab` | GitLab repositories |
| `create-sibling-gogs` | Gitea/Forgejo/Gogs instances (including [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}})) |
| `create-sibling-osf` | Open Science Framework (via [datalad-osf](https://github.com/datalad/datalad-osf)) |
| `create-sibling-ria` | RIA (Remote Indexed Archive) stores |

### Example: Publishing to OSF

```bash
pip install datalad-osf

# Create an OSF sibling
datalad create-sibling-osf --name osf \
    --title "My Research Dataset" \
    --category data

# Push dataset
datalad push --to osf
```

## rclone as Universal Adapter

[rclone]({{< ref "rclone" >}}) deserves special mention because it serves a **dual role** in the con/serve architecture:

1. **Ingestion**: pull files from cloud storage into git-annex repos
2. **Conservation**: push archived content back to cloud storage as a backup or distribution target

With support for 70+ providers, rclone ensures that no matter where your institution or collaborators keep their cloud storage, you can replicate your archive there.

## Distribution Patterns

### Backup (Resilience)

Replicate content to multiple locations for disaster recovery:

```bash
# Local NAS
git annex initremote nas type=directory directory=/mnt/nas/archive
git annex copy --to nas .

# Cloud (S3)
git annex copy --to s3-backup .

# Off-site (rsync to collaborator's server)
git annex initremote offsite type=rsync \
    rsyncurl=user@remote.example.org:/archive
git annex copy --to offsite .
```

### Publish (Accessibility)

Make datasets discoverable and downloadable by the community:

- **Domain archives**: OpenNeuro, DANDI, EMBER, OSF
- **Institutional repositories**: via RIA stores or institutional Forgejo instances
- **[DataLad Hub]({{< ref "infrastructure/datalad-hub" >}})**: hosted DataLad dataset sharing

### Distribute (Scale)

For very large datasets, use distribution mechanisms that scale:

- **BitTorrent special remote**: peer-to-peer distribution
- **Web special remote**: register download URLs so consumers can `git annex get` from the original source
- **CDN-backed S3**: put content on S3 behind CloudFront or similar

## Content Policies

git-annex's `numcopies` and `required` settings let you express policies about where content must exist:

```bash
# Require at least 2 copies of everything
git annex numcopies 2

# Require that archival content always exists on S3
git annex required s3-backup "include=*"

# Only keep recent data locally, archive everything to cold storage
git annex wanted here "not copies=s3-backup:1"
git annex wanted s3-backup "anything"
```

These policies are stored in the git-annex branch and shared across all clones, ensuring consistent archival behavior regardless of who runs the distribution commands.

## See Also

- [rclone]({{< ref "rclone" >}}) -- universal cloud storage adapter
- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- the inbound counterpart
- [DataLad Hub]({{< ref "infrastructure/datalad-hub" >}}) -- hosted publishing target
