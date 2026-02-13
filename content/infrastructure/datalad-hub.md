---
title: "DataLad Hub"
date: 2026-02-12
description: "A Forgejo-Aneksajo deployment for publishing, sharing, and collaborating on DataLad datasets"
summary: "hub.datalad.org -- a public Forgejo-Aneksajo deployment providing web-based browsing, cloning, and collaboration on DataLad datasets."
categories: ["Infrastructure"]
tags: ["CON", "MIH", "datalad", "hosting", "hub", "datasets", "collaboration", "forgejo"]
integrations: ["native-datalad"]
ai_readiness: ["ai-partial"]
params:
  homepage: "https://hub.datalad.org"
  repo: "https://codeberg.org/matrss/forgejo-aneksajo"
  issues: "https://codeberg.org/matrss/forgejo-aneksajo/issues"
  language: "Go"
  license: "MIT"
  maturity: "beta"
  last_verified: "2026-02"
---

## Overview

[DataLad Hub](https://hub.datalad.org) is a public deployment of [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- the Forgejo fork with native git-annex support. It provides a web interface for publishing, browsing, cloning, and collaborating on DataLad datasets without the need to deploy and maintain your own infrastructure.

DataLad Hub is not a separate tool or codebase -- it is an **instance** of Forgejo-Aneksajo, much like github.com is an instance of GitHub's proprietary forge. The underlying technology is described on the [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) page.

## Key Features

- **Dataset hosting** -- push DataLad datasets including both git metadata and git-annex content
- **Web browsing** -- explore dataset contents, file trees, and metadata through the Forgejo web interface
- **Standard git workflows** -- clone, fork, pull request, and collaborate using familiar git patterns
- **git-annex support** -- full git-annex protocol support means `datalad push` and `datalad get` work seamlessly
- **Organizations and teams** -- group datasets by lab, project, or collaboration with appropriate access controls

## git-annex / DataLad Integration

**Integration level: native-datalad.**

```bash
# Create a sibling on DataLad Hub
datalad create-sibling-gogs --name hub \
    --api https://hub.datalad.org/api/v1 \
    --credential datalad-hub-token

# Push dataset (git refs + annexed content)
datalad push --to hub
```

Because the backend is Forgejo-Aneksajo, both git and git-annex content are handled by the same server. There is no need to configure separate special remotes for annexed content.

## Others to Consider

**[datalad-registry](https://github.com/datalad/datalad-registry)** (live at [registry.datalad.org](https://registry.datalad.org)) -- a service for auto-discovery and metadata extraction of DataLad datasets. Rather than hosting datasets, it indexes datasets discovered on GitHub and other hosts, extracting metadata to make them searchable. Could be a useful complement to DataLad Hub for making archived datasets discoverable.

## AI Readiness

**Level: ai-partial.**

The API provides programmatic access to repository metadata, file listings, and issue discussions -- all structured and AI-consumable. The actual dataset content depends on the specific datasets hosted and may require domain-specific processing.

## Relationship to Lab-in-a-Box

DataLad Hub can be thought of as a **managed Forgejo-Aneksajo deployment** focused on dataset hosting. Research groups that want the same capabilities on their own hardware can deploy [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) instead.

| | DataLad Hub | Lab-in-a-Box |
|---|---|---|
| Hosting | Managed | Self-hosted |
| Setup effort | Create account | Deploy server |
| Customization | Limited | Full control |
| Data location | Hub servers | Your servers |
| Additional services | Dataset hosting only | Forgejo + HedgeDoc + more |

## See Also

- [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- the technology powering DataLad Hub
- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) -- self-hosted alternative
