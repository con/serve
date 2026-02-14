---
title: "con/serve"
date: 2026-02-12
description: "Conserve and serve digital research artifacts -- a knowledge base for archiving everything into git-annex/DataLad repositories"
---

## Vision

Research generates far more than code and data.
Every Slack thread, Zoom recording, GitHub discussion, AI coding session, and conference PDF
is a piece of the scholarly record -- and most of it is quietly rotting on someone else's servers.

**con/serve** extends [YODA](https://handbook.datalad.org/en/latest/basics/101-127-yoda.html)
principles to *all* digital research artifacts.
If it matters to your work, it belongs in a version-controlled, content-addressed repository
where you own the bits, not a SaaS provider.

The core idea is a **bidirectional funnel**:

1. **Ingest** from dozens of sources -- messaging platforms, video hosting, code forges,
   cloud storage, reference managers, AI assistants -- into a
   [git-annex](https://git-annex.branchable.com/) / [DataLad](https://www.datalad.org/) vault.
2. **Conserve and distribute** outward to domain archives, cloud backups, institutional
   knowledge bases, and web publications.

{{< mermaid >}}
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#2d3748', 'primaryTextColor': '#fff', 'lineColor': '#718096', 'fontSize': '14px'}}}%%

flowchart LR

    subgraph IN["INBOUND"]
        direction TB
        comm["Communications<br>(Slack, Matrix, Email)"]
        media["Media<br>(YouTube, Zoom)"]
        code["Code Artifacts<br>(Issues, Wikis)"]
        ai["AI Sessions<br>(Claude, Cursor)"]
        pubs["Publications<br>(Citations, PDFs)"]
        cloud_in["Cloud Storage<br>(rclone, 70+ providers)"]

        comm ~~~ media ~~~ code ~~~ ai ~~~ pubs ~~~ cloud_in
    end

    subgraph HUB["THE VAULT"]
        direction TB
        ga["git-annex<br>content-addressed storage"]
        dl["DataLad<br>dataset management"]
        org["YODA / STAMPED<br>organization & principles"]
        surfaces["Working Surfaces<br>(Hugo, HedgeDoc, LLM agents)"]

        ga --- dl
        dl --- org
        dl --- surfaces
    end

    subgraph OUT["OUTBOUND"]
        direction TB
        archives["Domain Archives<br>(OpenNeuro, DANDI, OSF)"]
        backup["Cloud Backup<br>(S3, Glacier, Dropbox)"]
        webpub["Web Publishing<br>(GitHub Pages)"]

        archives ~~~ backup ~~~ webpub
    end

    IN ==>|archive &<br>import| HUB
    HUB ==>|publish &<br>distribute| OUT

    classDef inbound fill:#2b6cb0,stroke:#2c5282,color:#fff,stroke-width:2px
    classDef hub fill:#d69e2e,stroke:#b7791f,color:#1a202c,stroke-width:3px
    classDef outbound fill:#2f855a,stroke:#276749,color:#fff,stroke-width:2px

    class comm,media,code,ai,pubs,cloud_in inbound
    class ga,dl,org,surfaces hub
    class archives,backup,webpub outbound

    style IN fill:#ebf8ff,stroke:#2b6cb0,stroke-width:2px,color:#2b6cb0
    style HUB fill:#fefcbf,stroke:#d69e2e,stroke-width:3px,color:#744210
    style OUT fill:#f0fff4,stroke:#2f855a,stroke-width:2px,color:#2f855a
{{< /mermaid >}}

For the full detailed diagram with all tools and connections,
see the [Architecture](/about/#architecture) section.

See also the closing
[Beyond YODA](https://datasets.datalad.org/centerforopenneuroscience/talks/2026-repronim-YODA-BIDS-webinar.html#/9)
slide and
[video](https://datasets.datalad.org/repronim/ReproTube/web/#/channel/ReproNim/video/1XbTbJ_P2x0?tab=local&wide=1&t=2725&q=beyon&filter=1)
from the YODA & BIDS webinar.

## Explore

| Section | What you will find |
|---|---|
| **[About](/about/)** | Project background, principles, and how to contribute |
| | &ensp; [YODA Principles](/about/#yoda-and-how-conserve-extends-it) -- how con/serve extends YODA to all artifacts |
| | &ensp; [Architecture](/about/#architecture) -- full system diagram (inbound / vault / outbound) |
| | &ensp; [STAMPED Framework](/about/#stamped-principles) -- guiding principles for artifact management |
| | &ensp; [Frozen Frontiers](/about/#frozen-frontiers) -- deliberate working boundaries and traversal |
| | &ensp; [Privacy & Access](/about/#privacy-and-access-control) -- archive aggressively, distribute selectively |
| | &ensp; [Integration Levels](/about/#integration-levels) -- native-datalad, git-annex, git-only, external |
| | &ensp; [AI Readiness](/about/#ai-readiness-levels) -- ai-ready, ai-partial, ai-manual |
| | &ensp; [Contributing](/about/contributing/) -- how to add tools and content |
| **[Tools](/tools/)** | Catalog of archival tools organized by artifact type |
| **[Infrastructure](/infrastructure/)** | Self-hosted services for managing and serving archived artifacts |
| **[Concepts](/concepts/)** | Cross-cutting patterns for ingestion, conservation, and distribution |
