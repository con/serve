---
title: "GIN (G-Node Infrastructure)"
date: 2026-02-12
description: "Gogs-based research data management platform with git-annex support, popular among European neuroscience researchers"
summary: "A fork of Gogs with git-annex support for versioning large research data files, operated by G-Node (German Neuroinformatics Node) at LMU Munich with BMBF funding."
categories: ["Infrastructure"]
tags: ["CON-contrib", "git-annex", "gogs", "self-hosted", "forge", "neuroscience", "research-data"]
integrations: ["git-annex"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/G-Node/gogs"
  homepage: "https://gin.g-node.org"
  issues: "https://github.com/G-Node/gogs/issues"
  language: "Go"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "gin.g-node.org (public instance)"
      url: "https://gin.g-node.org"
---

[GIN](https://gin.g-node.org) (G-Node Infrastructure) is a research data management platform built on a [fork of Gogs](https://github.com/G-Node/gogs) with added git-annex support. It is operated by the [German Neuroinformatics Node](https://g-node.github.io/) (G-Node) at Ludwig Maximilian University Munich and provides free data hosting for neuroscience researchers.

GIN and Forgejo-Aneksajo address the same fundamental problem -- standard git forges cannot handle git-annex content -- but arrived at it from different directions and lineages:

- **Gogs** (2014) was the original lightweight Go git forge
- **Gitea** (2016) forked from Gogs with a more open governance model
- **Forgejo** (2022) forked from Gitea after governance concerns
- **GIN** forked Gogs directly, adding git-annex support
- **Forgejo-Aneksajo** added git-annex support to Forgejo

GIN is supported by the German Federal Ministry of Education and Research (BMBF, grant 01GQ1302) and the Bernstein Center Munich, reflecting the same recognition that drove DataLad's funding: neuroscience needs proper infrastructure for large research data.

## Key Features

- **git-annex integration** -- large file versioning via git-annex, transparent to users through the web interface and [GIN CLI](https://github.com/G-Node/gin-cli)
- **DOI registration** -- publish datasets and receive a DOI for citation
- **Web interface** -- browse repositories, file trees, and commit history
- **Private and public repos** -- access control for sensitive data with the option to publish when ready
- **GIN CLI** -- dedicated command-line client (`gin upload`, `gin download`, `gin get`) that wraps git and git-annex operations into simpler commands

## GIN vs Forgejo-Aneksajo

| | GIN | Forgejo-Aneksajo |
|---|---|---|
| Base forge | Gogs | Forgejo |
| git-annex support | Yes | Yes |
| Active upstream | Gogs is less actively developed | Forgejo is very actively developed |
| Known instances | gin.g-node.org (single public instance) | hub.datalad.org, hub.psychoinformatics.de, hub.edu.datalad.org |
| Self-hosting | Possible but uncommon | Designed for self-hosting |
| DataLad integration | Native (`datalad create-sibling-gin`) | Native (`datalad create-sibling-gitea`) |
| Community | Popular among EU neuroscience academics | Growing DataLad/research data community |
| Funding | BMBF (German federal) | Community-driven |

## git-annex / DataLad Integration

**Integration level: git-annex.**

GIN supports the git-annex protocol, so `git annex copy --to` and `git annex get --from` work against GIN repositories. DataLad datasets can use GIN as a sibling:

```bash
# DataLad has a dedicated command for GIN (defaults to gin.g-node.org)
datalad create-sibling-gin my-dataset --name gin

datalad push --to gin
```

The GIN CLI provides a simplified interface that hides git-annex complexity:

```bash
gin login
gin create my-dataset
gin upload .
gin download my-dataset
```

## AI Readiness

**Level: ai-partial.**

Repository metadata and file listings are accessible via the Gogs API. Actual data content depends on what researchers upload -- structured formats (NIfTI, BIDS) are AI-processable, while raw binary data may need domain-specific tooling.

## See Also

- [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- the more actively maintained alternative with similar goals
- [DataLad Hub]({{< ref "datalad-hub" >}}) -- a Forgejo-Aneksajo deployment for DataLad datasets
