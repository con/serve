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

The diagram below shows the full architecture.

## Architecture

{{< mermaid >}}
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#2d3748', 'primaryTextColor': '#fff', 'lineColor': '#718096', 'fontSize': '14px'}}}%%

flowchart LR

    %% INBOUND SOURCES
    subgraph IN["INBOUND -- Ingestion"]
        direction TB

        subgraph comm["Communications"]
            slack["Slack\n(slackdump)"]
            telegram["Telegram\n(tg-archive)"]
            matrix["Matrix\n(con/versations)"]
            mattermost["Mattermost\n(mmctl export)"]
            email["Email\n(offlineimap)"]
        end

        subgraph media["Media"]
            youtube["YouTube\n(annextube)"]
            zoom["Zoom\nrecordings"]
            podcasts["Podcasts\n(yt-dlp)"]
        end

        subgraph code["Code Artifacts"]
            issues["Issues/PRs\n(git-bug)"]
            discussions["Discussions\n(gh export)"]
            wikis["Wikis\n(gh-md)"]
        end

        subgraph neuro["NeuroImaging"]
            dicom["DICOM / PACS"]
            stimuli["Stimuli\n(ReproStim)"]
            events["Events\n(CurDes BIRCH)"]
            environ["Environment\n(temp/humidity)"]
        end

        subgraph ai["AI Sessions"]
            claude["Claude Code\n(cctrace)"]
            cursor["Cursor\n(SpecStory)"]
            entireio["Entire.io"]
        end

        subgraph pubs["Publications"]
            citations["Citations\n(citations-collector)"]
            pdfs["PDFs\n(Unpaywall)"]
        end
    end

    %% CENTER HUB
    subgraph HUB["THE VAULT"]
        direction TB
        ga["git-annex\ncontent-addressed storage"]
        dl["DataLad\ndataset management"]
        forgejo["Forgejo-aneksajo\nself-hosted"]
        principles["YODA / STAMPED\nprinciples"]

        subgraph harmonize["Data Organization\n& Harmonization"]
            bids["BIDS\n(HeuDiConv/ReproIn)"]
            nwb["NWB"]
            yoda_layout["YODA layout"]
        end

        subgraph surfaces["Working Surfaces"]
            hedgedoc_int["HedgeDoc\n(collaborative docs)"]
            hugo_int["Hugo website\n(con/serve)"]
        end

        subgraph ai_assist["AI Assistance"]
            llm["LLM agents\n(Claude Code, etc.)"]
            skills["Skills & prompts\n(con/serve SKILL)"]
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
            osf["OSF\n(datalad-osf)"]
            ember["EMBER"]
            dlhub["DataLad Hub"]
        end

        subgraph kb["Knowledge Bases"]
            inst_wiki["Institutional\nwikis"]
        end

        subgraph webpub["Web Publishing"]
            ghpages["GitHub Pages"]
        end

        subgraph refmgr["Reference Managers"]
            zotero["Zotero\n(sync)"]
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
    HUB -->|"special\nremote"| cloud_out
    HUB -->|publish| archives
    HUB -->|export| kb
    HUB -->|deploy| webpub
    HUB -->|sync| refmgr

    %% rclone as bidirectional bridge
    rclone{{"rclone\n(70+ providers)"}}
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

## The STAMPED Framework

**STAMPED** provides a set of principles for managing research data and digital artifacts:

- **S**tandardized -- use community conventions and formats
- **T**racked -- version control everything with git/git-annex
- **A**ccessible -- make artifacts findable and retrievable
- **M**odular -- compose datasets from reusable components (YODA nesting)
- **P**ortable -- avoid vendor lock-in; own your bits
- **E**very artifact -- not just code and data, but *everything*
- **D**istributed -- replicate across locations for resilience

con/serve is the practical catalog that puts the **E** into practice:
tools, workflows, and infrastructure for archiving *every* digital artifact
your research touches.

## Frozen Frontiers

Digital artifacts have a half-life.
Slack workspaces get deleted.
Zoom recordings expire.
Free-tier cloud storage vanishes.
SaaS APIs change without notice.
AI conversation history is ephemeral by default.

We call these **Frozen Frontiers** -- the boundary beyond which a research artifact
becomes frozen in place (inaccessible, unrecoverable, or locked behind a defunct service)
if it is not proactively archived.
Every tool cataloged in con/serve pushes that frontier further out,
buying time and preserving access to artifacts that would otherwise be lost.

The goal is not to hoard everything indiscriminately.
It is to make a *deliberate choice* about what to conserve,
and to have the tools and infrastructure to act on that choice
before the frontier freezes over.

## Privacy and the Vault

Not everything in the vault is meant to be shared.
Many ingested artifacts originate from restricted sources --
private Slack workspaces, institutional email lists, access-controlled cloud drives,
embargoed manuscripts, confidential Zoom recordings, or internal wikis behind VPNs.
Archiving them into git-annex does not change their access status;
it simply ensures they are preserved under *your* control
rather than depending on a third party's retention policy.

git-annex's architecture supports this naturally.
Content can live in private special remotes (encrypted S3, local NAS, institutional Forgejo)
while the git history and metadata remain in a repository
that is itself access-controlled.
Custom metadata like `distribution-restrictions` controls what reaches each remote --
you decide what gets published to domain archives or GitHub Pages,
and what stays behind locked doors.

This also means ingestion tools should capture provenance and rights metadata --
original owner, license, source access level, data use conditions
([DUO](https://github.com/EBISPOT/DUO)) -- at archival time,
so that distribution decisions can be made later even if not needed immediately.

The con/serve model is: **archive aggressively, distribute selectively**.
Conservation and openness are complementary goals, not synonymous ones.

## Explore

| Section | What you will find |
|---|---|
| [Tools](/tools/) | Catalog of archival tools organized by artifact type |
| [Infrastructure](/infrastructure/) | Self-hosted services for managing and serving archived artifacts |
| [Concepts](/concepts/) | Cross-cutting patterns for ingestion, conservation, and distribution |
| [About](/about/) | Project vision, STAMPED principles, and how to contribute |
