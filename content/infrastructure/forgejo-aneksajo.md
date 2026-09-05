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
  repo: "https://codeberg.org/forgejo-aneksajo/forgejo-aneksajo"
  homepage: "https://codeberg.org/forgejo-aneksajo/forgejo-aneksajo"
  issues: "https://codeberg.org/forgejo-aneksajo/forgejo-aneksajo/issues"
  language: "Go"
  license: "GPL-3.0-or-later"
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

**Forgejo-Aneksajo** is a fork of [Forgejo](https://forgejo.org) -- itself a community fork of Gitea -- that adds native support for [git-annex](https://git-annex.branchable.com/). This means a Forgejo-Aneksajo instance can serve as a full git-annex remote: clients can `git annex copy --to` and `git annex get --from` the server, not just push and pull git refs.

This is the critical missing piece in the self-hosted research infrastructure stack. Standard forges (GitHub, GitLab, Gitea, Forgejo) handle git repositories well but choke on git-annex content because they do not understand the annex protocol. Forgejo-Aneksajo solves this by supporting `git-annex-shell` on the server side (over SSH), with read-only "dumb HTTP" access and, in newer releases, git-annex's p2phttp protocol on top, making annexed content a first-class citizen alongside code and metadata. It is a soft fork: releases are tagged `v<forgejo-version>-git-annex<n>` and track upstream Forgejo.

## Why This Matters

The entire con/serve architecture depends on having a place to *host* DataLad datasets -- not just the git metadata, but the annexed content too. Without Forgejo-Aneksajo, you face an awkward split:

- **Git refs** (metadata, small files, configs) go to a forge like GitHub or Forgejo
- **Annexed content** (large files, binaries, media) goes to a separate storage backend (S3, rsync server, etc.)

This split works but it creates operational overhead, complicates access control, and means the forge's web UI cannot display the full picture. With Forgejo-Aneksajo, a single service handles both layers.

## Key Features

### Native git-annex Support

With `[annex] ENABLED = true` in `app.ini`, Forgejo-Aneksajo allows clients to:

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
# Create a sibling on your Forgejo-Aneksajo instance (Forgejo is Gitea-API compatible)
datalad create-sibling-gitea --name lab-forgejo \
    --api https://forgejo.lab.example.org \
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

Forgejo-Aneksajo keeps Forgejo's repository storage and adds git-annex on top: when `git-annex-shell` is enabled, annexed content is stored under the server-side repository in git-annex's usual object layout, so the same filesystem-level backup tools that cover the git repositories also cover the annexed content.

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

Forgejo-Aneksajo can be deployed as a container image, from the [release binaries](https://codeberg.org/forgejo-aneksajo/forgejo-aneksajo/releases), or through the [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) pyinfra deployment.

### Container

Images are published on Docker Hub as `mihanke/forgejo-aneksajo` and, as used by Lab-in-a-Box, at `hub.datalad.org/forgejo/forgejo-aneksajo:<version>-rootless-amd64`. Lab-in-a-Box runs them as rootless Podman containers behind Caddy.

### Configuration

Forgejo-Aneksajo uses the same configuration format as Forgejo (`app.ini`). git-annex support must be switched on explicitly:

```ini
[annex]
ENABLED = true
```

Without it the instance behaves like a vanilla Forgejo.

## AI Readiness

**Level: ai-partial.**

The git metadata, issue discussions, and repository information served through the API and web interface are structured and AI-consumable. However, the annexed content itself (large files, binaries, media) requires domain-specific processing before AI systems can work with it. The Forgejo API provides programmatic access to repository metadata, making it straightforward to build automated workflows.

## Limitations

- **Beta status**: Forgejo-Aneksajo tracks upstream Forgejo releases but with a delay. Breaking changes in Forgejo may take time to propagate.
- **Storage management**: Unlike cloud-native object stores, the annexed content storage is filesystem-based. Large deployments need to plan storage capacity and backup strategies.
- **Single-instance**: No built-in clustering or high-availability. For critical deployments, standard infrastructure HA patterns (load balancer, shared storage, database replication) must be applied manually.

## See Also

- [DataLad Hub]({{< ref "datalad-hub" >}}) -- hosted Forgejo-Aneksajo instance
- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) -- automated deployment including Forgejo-Aneksajo
- [HedgeDoc]({{< ref "hedgedoc" >}}) -- collaborative editing, documents stored in Forgejo repos
