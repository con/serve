---
title: "rclone"
date: 2026-02-12
description: "Swiss army knife for cloud storage -- sync, copy, and mount 70+ cloud providers with git-annex special remote support"
summary: "Universal cloud storage adapter supporting 70+ providers. Serves a dual role in con/serve: ingestion (pull files from cloud) and distribution (push archives to cloud as a git-annex special remote). The universal adapter between the git-annex vault and the cloud storage ecosystem."
categories: ["Cloud Storage"]
tags: ["cloud", "storage", "google-drive", "s3", "dropbox", "sync", "backup", "special-remote"]
media_types: ["cloud-storage"]
integrations: ["git-annex"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/rclone/rclone"
  homepage: "https://rclone.org"
  issues: "https://github.com/rclone/rclone/issues"
  language: "Go"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "rclone git-annex documentation"
      url: "https://rclone.org/commands/rclone_gitannex/"
    - title: "DataLad Handbook: Dropbox via rclone"
      url: "https://handbook.datalad.org/en/latest/basics/101-139-dropbox.html"
---

**rclone** is a command-line program for managing files on cloud storage. It supports over 70 cloud providers -- from the major platforms (Google Drive, Dropbox, OneDrive, S3, Azure Blob) to specialized services (Backblaze B2, Wasabi, MEGA, pCloud, Storj) and generic protocols (SFTP, FTP, WebDAV, HTTP).

In the con/serve architecture, rclone is the **universal adapter** between the git-annex vault and the cloud storage ecosystem. It plays a dual role that no other single tool covers:

1. **Ingestion**: pull files from any cloud provider into a local directory for git-annex import
2. **Distribution**: act as a git-annex special remote so archived content can be pushed back to cloud storage for backup, sharing, or compliance

This bidirectionality makes rclone the most versatile tool in the cloud storage section.

## Why rclone?

Research groups accumulate files across dozens of cloud services -- Google Drive folders shared by collaborators, Dropbox directories synced from instruments, S3 buckets holding processed datasets, OneDrive directories mandated by institutional IT. Each service has its own API, authentication flow, and sync semantics.

rclone provides a single, consistent interface to all of them. Learn one tool, access everything.

## Supported Providers

rclone supports [over 70 providers](https://rclone.org/overview/). Key ones for research workflows:

| Provider | Use Case |
|----------|----------|
| **Google Drive** | Institutional G Suite accounts, shared drives |
| **Dropbox** | Collaborator file sharing |
| **Amazon S3** | Archival storage, compute data staging |
| **Backblaze B2** | Low-cost archival storage |
| **Microsoft OneDrive** | Institutional Office 365 accounts |
| **Box** | Enterprise file sharing (common in universities) |
| **SFTP** | Any server with SSH access |
| **WebDAV** | OwnCloud, Nextcloud, and other WebDAV servers |
| **Azure Blob** | Microsoft cloud research credits |
| **Google Cloud Storage** | GCP-based research infrastructure |
| **Wasabi** | Hot cloud storage, S3-compatible, no egress fees |

## Core Operations

### Configuration

```bash
# Interactive configuration wizard
rclone config

# Result: named remotes stored in ~/.config/rclone/rclone.conf
# Example: a remote named "gdrive" pointing to Google Drive
```

### Sync and Copy

```bash
# Copy files from Google Drive to local directory
rclone copy gdrive:shared-project/ ./local-copy/

# Sync (make destination match source, deleting extras)
rclone sync gdrive:shared-project/ ./local-copy/

# Copy with progress and stats
rclone copy gdrive:shared-project/ ./local-copy/ --progress

# Copy only files newer than a date
rclone copy gdrive:shared-project/ ./local-copy/ --min-age 0 --max-age 30d
```

### Mount as Filesystem

```bash
# Mount Google Drive as a local filesystem (FUSE)
rclone mount gdrive:shared-project/ /mnt/gdrive --daemon

# Now access cloud files as if they were local
ls /mnt/gdrive/
cp /mnt/gdrive/important-file.csv ./

# Unmount when done
fusermount -u /mnt/gdrive
```

### List and Check

```bash
# List files on a remote
rclone ls gdrive:shared-project/

# Check for differences between local and remote
rclone check ./local-copy/ gdrive:shared-project/

# Show storage usage
rclone about gdrive:
```

## git-annex Integration

rclone's most important role in the con/serve stack is as a **git-annex special remote** via [git-annex-remote-rclone](https://github.com/DanielDent/git-annex-remote-rclone). This lets git-annex use any rclone-supported provider as a storage backend.

### Setup

```bash
# Install the bridge
pip install git-annex-remote-rclone

# Or from source
git clone https://github.com/DanielDent/git-annex-remote-rclone.git
cp git-annex-remote-rclone/git-annex-remote-rclone ~/bin/
```

### Configure a Special Remote

```bash
# Initialize an rclone-backed special remote
git annex initremote gdrive-backup type=external \
    externaltype=rclone \
    target=gdrive \
    prefix=annex-backup \
    encryption=shared \
    chunk=50MiB

# Copy content to the remote
git annex copy --to gdrive-backup .

# Verify
git annex whereis .
```

### Ingestion Workflow

Pull files from cloud storage into a git-annex repository:

```bash
# 1. Copy from cloud to local staging area
rclone copy gdrive:lab-data/experiment-2026/ ./staging/

# 2. Add to git-annex
cd my-dataset
git annex add ../staging/*
datalad save -m "Import experiment data from Google Drive"

# Or use git annex import directly
git annex import gdrive:lab-data/experiment-2026/ --to main
```

### Distribution Workflow

Push archived content to cloud storage for backup:

```bash
# Push all content to Google Drive backup
git annex copy --to gdrive-backup .

# Push specific files
git annex copy --to gdrive-backup data/large-files/

# Set up preferred content expressions
git annex wanted gdrive-backup "include=data/* and not copies=gdrive-backup:1"

# Auto-distribute based on preferred content
git annex sync --content
```

## Complete Example: Lab File Consolidation

A research group has files scattered across Google Drive, Dropbox, and an institutional S3 bucket. Here is how to consolidate them into a single DataLad dataset:

```bash
# Create the dataset
datalad create lab-archive
cd lab-archive

# Pull from Google Drive
rclone copy gdrive:shared-lab-data/ ./google-drive-import/
git annex add google-drive-import/
datalad save -m "Import shared lab data from Google Drive"

# Pull from Dropbox
rclone copy dropbox:instrument-outputs/ ./dropbox-import/
git annex add dropbox-import/
datalad save -m "Import instrument outputs from Dropbox"

# Pull from S3
rclone copy s3:research-bucket/processed/ ./s3-import/
git annex add s3-import/
datalad save -m "Import processed data from S3"

# Set up backup remotes
git annex initremote wasabi type=external externaltype=rclone \
    target=wasabi prefix=lab-archive encryption=shared
git annex copy --to wasabi .

# Now everything is in one versioned, deduplicated, backed-up dataset
git annex whereis .
```

## AI Readiness

**Level: ai-partial.**

rclone itself is a transport tool -- it does not transform content. The AI readiness depends entirely on what is being transferred:

- **Structured data** (JSON, CSV, markdown) synced from cloud storage is immediately AI-consumable
- **Binary content** (images, videos, proprietary formats) requires domain-specific processing
- **rclone's own configuration and output** (JSON flags, `rclone lsjson`) is structured and AI-friendly

rclone's `lsjson` command is particularly useful for AI-assisted workflows:

```bash
# Get structured file listing from any provider
rclone lsjson gdrive:shared-project/ --recursive
```

This produces JSON that can be processed by LLMs to understand directory structures, identify file types, or plan ingestion strategies.

## Comparison with Direct Provider Tools

| Feature | rclone | Provider-specific tools |
|---------|--------|----------------------|
| Provider coverage | 70+ | One each |
| Learning curve | Learn once | Learn each separately |
| git-annex integration | Via git-annex-remote-rclone | Manual or none |
| FUSE mount | Yes | Varies |
| Unified CLI | Yes | Different tools, flags, behaviors |
| Bandwidth control | Built-in (`--bwlimit`) | Varies |
| Encryption | Client-side (`crypt` remote) | Provider-dependent |

## Limitations and Caveats

- **Authentication complexity**: Each provider has its own auth flow (OAuth2, API keys, service accounts). Initial setup requires navigating provider-specific credential management.
- **Rate limits**: Cloud providers impose API rate limits. Large sync operations may need `--tpslimit` and `--transfers` flags tuned per provider.
- **Eventual consistency**: Some providers (especially S3-compatible ones) have eventual consistency guarantees. Operations immediately after writes may not see the latest state.
- **FUSE mount performance**: `rclone mount` works but is not as fast as local filesystem access. Suitable for browsing and occasional file access, not for heavy random I/O.
- **Provider-specific quirks**: Google Drive's file versioning, Dropbox's case sensitivity, OneDrive's character restrictions -- rclone handles most of these but edge cases exist.

## See Also

- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- outbound distribution patterns using rclone
- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- inbound ingestion patterns including mount-and-copy
