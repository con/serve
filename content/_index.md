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
