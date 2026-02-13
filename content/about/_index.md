---
title: "About"
date: 2026-02-12
description: "Project vision, principles, and background for con/serve"
cascade:
  showEdit: true
---

## Project Vision

**con/serve** is a knowledge base for archiving digital research artifacts
into git-annex/DataLad repositories.
The name captures both goals: *conserve* research artifacts before they are lost,
and *serve* them to humans, AIs, and automated workflows.

The project grows from a simple observation:
research generates far more than code and data,
yet most tooling for reproducibility and preservation
focuses exclusively on those two artifact types.
Slack conversations, Zoom recordings, GitHub discussions,
AI coding sessions, cloud-hosted documents, and scholarly PDFs
are all part of the research record -- and all at risk of loss.

## YODA and How con/serve Extends It

[YODA](https://handbook.datalad.org/en/latest/basics/101-127-yoda.html)
(YODA's Organigram on Data Analysis) defines principles
for structuring DataLad datasets:

- One dataset per analysis or project component
- Nested datasets for modular composition
- Clean separation of code, inputs, and outputs
- Machine-readable provenance for every result

YODA works well for code and data.
con/serve extends these principles to *all* digital artifacts:
messaging histories, media files, code forge metadata,
AI session transcripts, reference collections, and web captures.

The extension is straightforward:
each artifact type gets its own ingestion tool,
its own dataset structure,
and its own integration with the git-annex/DataLad stack.
The YODA nesting model composes them into a coherent whole.

## STAMPED Principles

**STAMPED** provides the guiding framework:

| Letter | Principle | Meaning |
|---|---|---|
| **S** | Standardized | Use community conventions and formats |
| **T** | Tracked | Version control everything with git/git-annex |
| **A** | Accessible | Make artifacts findable and retrievable |
| **M** | Modular | Compose datasets from reusable components |
| **P** | Portable | Avoid vendor lock-in; own your bits |
| **E** | Every artifact | Not just code and data -- *everything* |
| **D** | Distributed | Replicate across locations for resilience |

con/serve is the practical realization of the **E** principle:
a catalog of tools and workflows for archiving
every type of digital artifact a research group produces or depends on.

## Frozen Frontiers

Digital artifacts have a half-life.
When a SaaS provider changes its API, raises prices, or shuts down,
the artifacts it hosted cross a **Frozen Frontier** --
the boundary beyond which they become inaccessible or unrecoverable.

Examples of Frozen Frontiers:

- Slack free-tier message retention limits (messages older than 90 days disappear)
- Zoom cloud recording expiration (auto-deleted after a configurable period)
- Google Drive storage quota enforcement (files in shared drives become inaccessible)
- Code forge shutdowns (Google Code, Gitorious, BitBucket Mercurial repos)
- AI session history purges (conversation logs deleted after inactivity)

Every tool in con/serve pushes the Frozen Frontier further out:
by archiving artifacts *before* they cross the boundary,
you convert ephemeral, platform-dependent content
into durable, self-hosted, version-controlled assets.

The goal is not to hoard indiscriminately.
It is to make a *deliberate choice* about what to conserve
and to have the infrastructure to act on that choice in time.

## Privacy and Access Control

Archival and openness are complementary goals, not synonymous ones.
Many of the artifacts con/serve helps you archive originate from restricted sources:

- **Private messaging platforms** -- Slack workspaces, Mattermost teams, and Matrix rooms where conversations are confidential by default
- **Access-controlled cloud storage** -- Google Drive folders, Dropbox shared spaces, or institutional OneDrive with restricted permissions
- **Embargoed or pre-publication materials** -- manuscripts under review, grant proposals, internal reports
- **Recordings with consent constraints** -- Zoom meetings, lab meeting recordings, or lectures where participants consented to internal use only
- **Institutional resources** -- internal wikis, VPN-protected intranets, authentication-gated portals

Archiving these into the vault preserves them against platform loss
without altering their confidentiality requirements.
git-annex's content-addressed storage and special remote system
makes this practical:

- **Private remotes**: content can be stored on encrypted S3, local NAS,
  or institutional Forgejo instances with access control,
  while public-facing siblings receive only the subset you choose to publish
- **Selective distribution**: `git annex wanted` expressions
  use custom metadata to control what reaches each remote --
  e.g., `"include=.datalad/* and (not metadata=distribution-restrictions=*)"` ensures
  a public-facing remote only receives content not marked as private or sensitive
- **Repository-level access**: the git repository itself can be private
  (private GitHub/Forgejo repo), even while some of its published datasets
  are openly accessible via domain archives
- **Encryption**: git-annex special remotes support encryption at rest,
  so even backup providers cannot read the archived content

The guiding principle is **archive aggressively, distribute selectively**.
Every artifact should be safely preserved under your control,
but the decision about what to make public is separate from the decision to archive.

This selective distribution only works if the necessary metadata is available.
Ingestion tools should capture provenance and rights information --
original owner, copyright, license, source access level, consent constraints --
at the time of archival, so that distribution decisions can be made later.
For research data, the [Data Use Ontology (DUO)](https://github.com/EBISPOT/DUO)
provides a standardized vocabulary for machine-readable data use conditions.
See [Privacy-Aware Distribution]({{< ref "conservation-to-external#privacy-aware-distribution" >}})
for practical examples.

## Integration Levels

Each tool in the catalog is classified by how deeply it integrates
with the git-annex/DataLad stack:

**native-datalad** -- The tool is a DataLad extension or produces DataLad datasets directly.
Examples: annextube, datalad-crawler, wayslack2, citations-collector.
These provide the smoothest experience: dataset creation, content tracking,
and provenance recording happen automatically.

**git-annex** -- The tool works with git-annex but is not DataLad-specific.
Examples: yt-dlp with `git annex import`, gallery-dl, rclone as special remote.
Integration requires manual steps but is well-supported.

**git-only** -- The tool stores output in git without annex support.
Examples: git-bug, gh-md, tg-archive.
Suitable for text-based artifacts where git's native tracking is sufficient.

**external** -- The tool produces output that must be manually imported into git/annex.
Examples: ArchiveBox, SingleFile, Browsertrix.
These tools are valuable but require wrapper scripts or manual workflows
to fit into the git-annex/DataLad ecosystem.

## AI Readiness Levels

Each tool is also classified by how consumable its output is
for LLM-based workflows:

**ai-ready** -- Output is structured text or JSON that an LLM can consume directly.
Examples: Slack JSON exports, GitHub issue JSON, citation metadata.
These artifacts can feed directly into AI-assisted analysis,
summarization, and search workflows.

**ai-partial** -- Output includes structured metadata but the primary content
may need processing.
Examples: web archives with HTML that needs extraction,
email archives with attachments that need parsing.

**ai-manual** -- Output is primarily binary or media content
that requires transcription, OCR, or other processing before an LLM can use it.
Examples: video recordings, audio files, image datasets.
The metadata (titles, descriptions, timestamps) may still be ai-ready.
