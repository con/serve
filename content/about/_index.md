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

## Architecture

{{< mermaid >}}
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#2d3748', 'primaryTextColor': '#fff', 'lineColor': '#718096', 'fontSize': '14px'}}}%%

flowchart LR

    %% INBOUND SOURCES
    subgraph IN["INBOUND -- Ingestion"]
        direction TB

        subgraph comm["Communications"]
            slack["Slack<br>(slackdump)"]
            telegram["Telegram<br>(tg-archive)"]
            matrix["Matrix<br>(con/versations)"]
            mattermost["Mattermost<br>(mmctl export)"]
            email["Email<br>(offlineimap)"]
        end

        subgraph media["Media"]
            youtube["YouTube<br>(annextube)"]
            zoom["Zoom<br>recordings"]
            podcasts["Podcasts<br>(yt-dlp)"]
        end

        subgraph code["Code Artifacts"]
            issues["Issues/PRs<br>(git-bug)"]
            discussions["Discussions<br>(gh export)"]
            wikis["Wikis<br>(gh-md)"]
        end

        subgraph neuro["NeuroImaging"]
            dicom["DICOM / PACS"]
            stimuli["Stimuli<br>(ReproStim)"]
            events["Events<br>(CurDes BIRCH)"]
            environ["Environment<br>(temp/humidity)"]
        end

        subgraph ai["AI Sessions"]
            claude["Claude Code<br>(cctrace)"]
            cursor["Cursor<br>(SpecStory)"]
            entireio["Entire.io"]
        end

        subgraph pubs["Publications"]
            citations["Citations<br>(citations-collector)"]
            pdfs["PDFs<br>(Unpaywall)"]
        end
    end

    %% CENTER HUB
    subgraph HUB["THE VAULT"]
        direction TB
        ga["git-annex<br>content-addressed storage"]
        dl["DataLad<br>dataset management"]
        forgejo["Forgejo-aneksajo<br>self-hosted"]
        principles["YODA / STAMPED<br>principles"]

        subgraph harmonize["Data Organization<br>& Harmonization"]
            bids["BIDS<br>(HeuDiConv/ReproIn)"]
            nwb["NWB"]
            yoda_layout["YODA layout"]
        end

        subgraph surfaces["Working Surfaces"]
            hedgedoc_int["HedgeDoc<br>(collaborative docs)"]
            hugo_int["Hugo website<br>(con/serve)"]
        end

        subgraph ai_assist["AI Assistance"]
            llm["LLM agents<br>(Claude Code, etc.)"]
            skills["Skills & prompts<br>(con/serve SKILL)"]
        end

        ga --- dl
        dl --- forgejo
        dl --- principles
        dl --- harmonize
        dl --- surfaces
        ai_assist ---|augment| surfaces
    end

    %% OUTBOUND TARGETS
    subgraph OUT["OUTBOUND -- Conservation & Distribution"]
        direction TB

        subgraph cloud_out["Cloud / Storage"]
            gdrive_out["Google Drive"]
            s3_out["S3 / Glacier"]
            dropbox_out["Dropbox"]
        end

        subgraph archives["Domain Archives"]
            openneuro["OpenNeuro"]
            dandi["DANDI"]
            osf["OSF<br>(datalad-osf)"]
            ember["EMBER"]
            dlhub["DataLad Hub"]
        end

        subgraph kb["Knowledge Bases"]
            inst_wiki["Institutional<br>wikis"]
        end

        subgraph webpub["Web Publishing"]
            ghpages["GitHub Pages"]
        end

        subgraph refmgr["Reference Managers"]
            zotero["Zotero<br>(sync)"]
        end
    end

    %% CONNECTIONS: Inbound -> Hub
    comm -->|archive| HUB
    media -->|import| HUB
    code -->|bridge| HUB
    neuro -->|acquire| HUB
    ai -->|capture| HUB
    pubs -->|collect| HUB

    %% CONNECTIONS: Hub -> Outbound
    HUB -->|"special<br>remote"| cloud_out
    HUB -->|publish| archives
    HUB -->|export| kb
    HUB -->|deploy| webpub
    HUB -->|sync| refmgr

    %% rclone as bidirectional bridge
    rclone{{"rclone<br>(70+ providers)"}}
    rclone <-.->|ingest & backup| HUB
    rclone <-.-> cloud_out

    %% STYLES
    classDef inbound fill:#2b6cb0,stroke:#2c5282,color:#fff,stroke-width:2px
    classDef hub fill:#d69e2e,stroke:#b7791f,color:#1a202c,stroke-width:3px
    classDef outbound fill:#2f855a,stroke:#276749,color:#fff,stroke-width:2px
    classDef bidir fill:#6b46c1,stroke:#553c9a,color:#fff,stroke-width:2px,stroke-dasharray: 5 5
    classDef harmonizeNode fill:#e07b39,stroke:#c05621,color:#fff,stroke-width:2px

    class slack,telegram,matrix,mattermost,email,youtube,zoom,podcasts,issues,discussions,wikis,dicom,stimuli,events,environ,claude,cursor,entireio,citations,pdfs inbound
    class ga,dl,forgejo,principles hub
    class bids,nwb,yoda_layout harmonizeNode
    class hedgedoc_int,hugo_int harmonizeNode
    class llm,skills harmonizeNode
    class gdrive_out,s3_out,dropbox_out,openneuro,dandi,osf,ember,dlhub,inst_wiki,ghpages,zotero outbound
    class rclone bidir

    style IN fill:#ebf8ff,stroke:#2b6cb0,stroke-width:2px,color:#2b6cb0
    style HUB fill:#fefcbf,stroke:#d69e2e,stroke-width:3px,color:#744210
    style OUT fill:#f0fff4,stroke:#2f855a,stroke-width:2px,color:#2f855a

    style comm fill:#bee3f8,stroke:#2b6cb0,color:#2c5282
    style media fill:#bee3f8,stroke:#2b6cb0,color:#2c5282
    style code fill:#bee3f8,stroke:#2b6cb0,color:#2c5282
    style neuro fill:#bee3f8,stroke:#2b6cb0,color:#2c5282
    style ai fill:#bee3f8,stroke:#2b6cb0,color:#2c5282
    style pubs fill:#bee3f8,stroke:#2b6cb0,color:#2c5282
    style harmonize fill:#fbd38d,stroke:#e07b39,stroke-width:2px,color:#744210
    style surfaces fill:#fbd38d,stroke:#e07b39,stroke-width:2px,color:#744210
    style ai_assist fill:#fbd38d,stroke:#e07b39,stroke-width:2px,color:#744210

    style cloud_out fill:#c6f6d5,stroke:#2f855a,color:#276749
    style archives fill:#c6f6d5,stroke:#2f855a,color:#276749
    style kb fill:#c6f6d5,stroke:#2f855a,color:#276749
    style webpub fill:#c6f6d5,stroke:#2f855a,color:#276749
    style refmgr fill:#c6f6d5,stroke:#2f855a,color:#276749
{{< /mermaid >}}

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

Every productive workflow establishes **Frozen Frontiers** --
deliberate boundaries where earlier stages are distilled
into a working surface suitable for the next step.
We compile source code into binaries.
We preprocess raw scans into analysis-ready datasets.
We condense months of Slack threads into a design document.
Each frontier lets you work at the right level of abstraction
without dragging the full burden of prior stages along.

![Frozen Frontiers: working surfaces at different depths](https://datasets.datalad.org/centerforopenneuroscience/talks/pics/surface-depth-v2.jpg "Each working surface is a frozen frontier over deeper layers of raw artifacts")

This is how work gets done -- and it applies across every artifact type:

| Stage | Frozen frontier | Working surface |
|---|---|---|
| Source code | Compilation | Binary / container image |
| Raw neuroimaging data | BIDS conversion | Analysis-ready dataset |
| Slack/Matrix threads | Archival + summarization | Decision log / design doc |
| Literature search | Citation collection | Reference library |
| AI coding sessions | Session export | Commit history + docs |

The risk is not the frontier itself but **losing what lies behind it**.
When the source repo is deleted, the Slack workspace is shut down,
the Zoom recordings expire, or the AI session history is purged,
the frontier is no longer just frozen -- it is **sealed**,
and reproducibility, auditing, and course correction become impossible.

con/serve addresses both sides:

1. **Establish frontiers** -- archive and transform artifacts into durable,
   structured forms ready for the next stage of work.
2. **Keep them traversable** -- because everything lands in a version-controlled,
   content-addressed vault, you retain the ability to go back through
   any frontier that ever existed: from the binary to the source,
   from the figure to the raw data, from the summary to the original conversation.

For more on Frozen Frontiers, see the
[YODA & BIDS webinar slide](https://datasets.datalad.org/centerforopenneuroscience/talks/2026-repronim-YODA-BIDS-webinar.html#/6/23)
and the corresponding
[video segment](https://datasets.datalad.org/repronim/ReproTube/web/#/channel/ReproNim/video/1XbTbJ_P2x0?tab=local&wide=1&t=2711&q=Frontier&filter=1).

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
