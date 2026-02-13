---
title: "Forgejo-Aneksajo"
date: 2026-02-12
description: "Forgejo fork with native git-annex support, serving as the foundation for self-hosted DataLad dataset hosting"
summary: "A fork of Forgejo that adds native git-annex protocol support, enabling self-hosted web browsing, cloning, and collaboration on DataLad datasets. Foundation of the DataLad Hub service."
categories: ["Infrastructure"]
tags: ["CON-ecosystem", "MIH", "forgejo", "git-annex", "self-hosted", "forge", "datalad-hub"]
integrations: ["native-datalad"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://codeberg.org/matrss/forgejo-aneksajo"
  homepage: "https://codeberg.org/matrss/forgejo-aneksajo"
  issues: "https://codeberg.org/matrss/forgejo-aneksajo/issues"
  language: "Go"
  license: "MIT"
  maturity: "beta"
  last_verified: "2026-02"
  examples:
    - title: "DataLad Hub"
      url: "https://hub.datalad.org"
    - title: "Psychoinformatics Hub"
      url: "https://hub.psychoinformatics.de"
    - title: "DataLad Edu Hub"
      url: "https://hub.edu.datalad.org"
---

**Forgejo-Aneksajo** is a fork of [Forgejo](https://forgejo.org) -- itself a community fork of Gitea -- that adds native support for the [git-annex](https://git-annex.branchable.com/) protocol. This means a Forgejo-Aneksajo instance can serve as a full git-annex remote: clients can `git annex copy --to` and `git annex get --from` the server, not just push and pull git refs.

This is the critical missing piece in the self-hosted research infrastructure stack. Standard forges (GitHub, GitLab, Gitea, Forgejo) handle git repositories well but choke on git-annex content because they do not understand the annex protocol. Forgejo-Aneksajo solves this by implementing git-annex's HTTP-based protocol directly in the forge, making annexed content a first-class citizen alongside code and metadata.

## Why This Matters

The entire con/serve architecture depends on having a place to *host* DataLad datasets -- not just the git metadata, but the annexed content too. Without Forgejo-Aneksajo, you face an awkward split:

- **Git refs** (metadata, small files, configs) go to a forge like GitHub or Forgejo
- **Annexed content** (large files, binaries, media) goes to a separate storage backend (S3, rsync server, etc.)

This split works but it creates operational overhead, complicates access control, and means the forge's web UI cannot display the full picture. With Forgejo-Aneksajo, a single service handles both layers.

## Key Features

### Native git-annex Protocol

Forgejo-Aneksajo implements the git-annex HTTP protocol, allowing clients to:

- **Push annexed content** to the server using `git annex copy --to origin`
- **Pull annexed content** from the server using `git annex get`
- **Check content availability** using `git annex whereis`

This works transparently with DataLad's `datalad push` and `datalad get` commands, so existing DataLad workflows require no changes.

### Web UI for Annexed Content

The Forgejo web interface is extended to handle git-annex content gracefully:

- **Symlink resolution** -- annexed files (which are symlinks in git) are displayed with their actual file information rather than showing raw symlink targets
- **Content browsing** -- users can browse the full dataset structure through the web interface
- **File size and availability** -- the UI shows whether annexed content is available on the server

### DataLad Sibling Support

A Forgejo-Aneksajo instance can serve as a DataLad sibling, meaning:

```bash
# Create a sibling on your Forgejo-Aneksajo instance
datalad create-sibling-gogs --name lab-forgejo \
    --api https://forgejo.lab.example.org/api/v1 \
    --credential lab-token

# Push everything -- git refs AND annexed content
datalad push --to lab-forgejo
```

This is the same workflow researchers already use with GitHub or GitLab siblings, but with the added benefit that annexed content goes to the same server instead of requiring a separate special remote.

### Fork and Pull Request Workflows

Because Forgejo-Aneksajo is a full Forgejo instance, it supports all the standard forge features:

- Repository forking and pull requests
- Issue tracking
- Organizations and teams with fine-grained permissions
- Webhooks and CI integration
- Container registry, package registry, and release management

These features make it suitable as the *primary forge* for a research group, not just a specialized storage backend.

## Architecture

Forgejo-Aneksajo extends Forgejo at the HTTP handler level. When a client initiates a git-annex protocol exchange, the server recognizes the request pattern and routes it to the annex storage backend instead of the standard git HTTP handler.

Annexed content is stored on the server's filesystem in the same content-addressed layout that git-annex uses locally (`.git/annex/objects/`). This means standard filesystem-level backup tools work, and storage can be pointed at any mountable filesystem (local disk, NFS, FUSE-mounted cloud storage).

## Role in the con/serve Stack

Forgejo-Aneksajo is the **centerpiece** of the con/serve infrastructure layer:

```
                     Researchers
                         |
                    Web browser / git / datalad
                         |
                 +------------------+
                 | Forgejo-Aneksajo |
                 |  - git repos     |
                 |  - annex content |
                 |  - web UI        |
                 |  - API           |
                 +------------------+
                    /     |      \
                   /      |       \
            DataLad    git-annex   Forge features
            datasets   content     (issues, PRs, CI)
```

- **[Lab-in-a-Box]({{< ref "lab-in-a-box" >}})** deploys Forgejo-Aneksajo as the primary service
- **[DataLad Hub]({{< ref "datalad-hub" >}})** is a hosted instance of Forgejo-Aneksajo
- **[HedgeDoc]({{< ref "hedgedoc" >}})** documents are exported and pushed to repos hosted here
- All [Tools](/tools/) that produce DataLad datasets can push to a Forgejo-Aneksajo instance

## Installation

Forgejo-Aneksajo can be deployed as a standalone binary, a Docker container, or through the [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) pyinfra deployment.

### Docker

```bash
docker pull codeberg.org/matrss/forgejo-aneksajo:latest
docker run -d --name forgejo-aneksajo \
    -p 3000:3000 -p 2222:22 \
    -v /srv/forgejo:/data \
    codeberg.org/matrss/forgejo-aneksajo:latest
```

### Binary

Download from the [releases page](https://codeberg.org/matrss/forgejo-aneksajo/releases) and run:

```bash
./forgejo-aneksajo web
```

### Configuration

Forgejo-Aneksajo uses the same configuration format as Forgejo (`app.ini`). The git-annex functionality is enabled by default and requires no additional configuration beyond standard Forgejo setup.

## AI Readiness

**Level: ai-partial.**

The git metadata, issue discussions, and repository information served through the API and web interface are structured and AI-consumable. However, the annexed content itself (large files, binaries, media) requires domain-specific processing before AI systems can work with it. The Forgejo API provides programmatic access to repository metadata, making it straightforward to build automated workflows.

## Limitations and Caveats

- **Beta status**: Forgejo-Aneksajo tracks upstream Forgejo releases but with a delay. Breaking changes in Forgejo may take time to propagate.
- **git-annex version compatibility**: The server's git-annex protocol support targets a specific protocol version. Very old or very new git-annex clients may have compatibility issues.
- **Storage management**: Unlike cloud-native object stores, the annexed content storage is filesystem-based. Large deployments need to plan storage capacity and backup strategies.
- **Single-instance**: No built-in clustering or high-availability. For critical deployments, standard infrastructure HA patterns (load balancer, shared storage, database replication) must be applied manually.

## See Also

- [DataLad Hub]({{< ref "datalad-hub" >}}) -- hosted Forgejo-Aneksajo instance
- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) -- automated deployment including Forgejo-Aneksajo
- [HedgeDoc]({{< ref "hedgedoc" >}}) -- collaborative editing, documents stored in Forgejo repos
