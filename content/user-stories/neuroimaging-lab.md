---
title: "Neuroimaging Lab"
date: 2026-02-17
description: "A research lab running MRI experiments needs a vault for DICOMs, behavioral data, communications, code, and processed derivatives"
summary: "A neuroimaging research lab doing MRI experiments with ReproIn-convention DICOMs, ReproStim stimulus capture, CurDes BIRCH behavioral events, Slack for communication, Google Calendar for scheduling, and GitHub for processing code. Data flows through HeuDiConv into BIDS, then MRIQC and fMRIPrep for preprocessing, with results published to OpenNeuro or DANDI."
tags: ["user-story", "neuroimaging", "BIDS", "MRI", "lab"]
---

## The Goal

A neuroimaging research lab wants a **unified vault**
that captures everything their experiments produce --
from raw scanner data through processed derivatives --
alongside the communications, code, and scheduling artifacts
that surround the science.

The lab runs MRI experiments, collects behavioral and stimulus data,
communicates over Slack, tracks events in Google Calendar,
and develops processing code on GitHub.
Today these live in disconnected silos:
DICOMs on a PACS server, event files on a lab workstation,
Slack threads in Slack's cloud, code on GitHub,
and processed results scattered across lab members' home directories.

## Data Sources

### MRI Acquisitions (DICOMs)

The primary data stream.
The lab acquires structural and functional MRI data
using the [ReproIn](https://github.com/repronim/reproin) naming convention,
which encodes BIDS-compatible metadata directly in DICOM series descriptions.
This means conversion to [BIDS](/standards/bids/) can be fully automated
via [HeuDiConv](https://github.com/nipy/heudiconv).

| Source | Format | Volume per session | Frequency |
|--------|--------|-------------------|-----------|
| Structural (T1w, T2w) | DICOM | 200-500 MB | Per subject |
| Functional (BOLD) | DICOM | 2-10 GB | Multiple runs per session |
| Field maps | DICOM | 50-200 MB | Per session |
| Diffusion (DWI) | DICOM | 1-5 GB | Optional |

### Stimulus Capture (ReproStim)

[ReproStim](https://github.com/ReproNim/reprostim) captures
the actual audio/video stimuli presented during scanning sessions --
screen recordings with QR-code-embedded timing synchronization.
This is critical for relating brain activity to specific stimulus events.

The captured media lands in git-annex as binary content
and can later be annotated via [Annotation Garden]({{< ref "annotation-garden" >}})
to produce BIDS-compliant events files with HED tags.

### Behavioral Events (CurDes BIRCH)

The CurDes BIRCH response box records
participant button presses, response times, and event timing
during MRI experiments.
These event logs are the behavioral counterpart to the fMRI data --
they document what the participant did and when.

Event files need to be converted to BIDS events format
(`*_events.tsv` with onset, duration, and trial type columns)
and aligned with the functional imaging data timing.

### Slack (Lab Communication)

The lab uses Slack for internal communication:
experiment coordination, data quality discussions,
analysis troubleshooting, paper drafts, and general lab life.

[slackdump]({{< ref "slackdump" >}}) archives these conversations
into structured JSON with full threading, reactions, and file attachments.

Key channels to archive:

| Channel | Content | Privacy |
|---------|---------|---------|
| `#experiments` | Session scheduling, scanner issues, protocol changes | private |
| `#analysis` | Processing questions, pipeline debugging, results discussion | private |
| `#papers` | Manuscript drafts, reviewer responses, submission coordination | private |
| `#general` | Lab announcements, social coordination | private |

### Google Calendar (Scheduling)

Scanner time slots, lab meetings, deadlines, conference dates.
Available via Google Takeout or CalDAV API export.
Low volume but useful for correlating events
("when did we change the protocol?" maps to a calendar entry).

### GitHub (Code and Project Management)

The lab maintains repositories for:

- **Processing pipelines** -- scripts that orchestrate HeuDiConv, MRIQC, fMRIPrep
- **Analysis code** -- statistical analysis, figures, manuscripts
- **Stimulus code** -- PsychoPy/PsychToolbox experiment scripts
- **Lab wiki/docs** -- protocols, onboarding materials

The code is already in git, but associated artifacts --
issues, pull request discussions, wiki pages, CI logs --
are platform-hosted and at risk of loss.
[con/tinuous]({{< ref "tinuous" >}}) archives CI logs,
[git-bug]({{< ref "git-bug" >}}) bridges issues into git,
and [python-github-backup]({{< ref "github-backup" >}})
captures the full repository metadata.

The lab's [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) instance
(deployed via [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}))
can mirror GitHub repositories and use GitHub as an OAuth2 authentication source,
so lab members log in with their existing GitHub accounts.
See the [Software Project]({{< ref "software-project" >}}) story
for a deeper treatment of GitHub organization archival.

## Processing Pipeline

Once data enters the vault, the processing pipeline runs:

```
DICOMs (ReproIn convention)
    → HeuDiConv + ReproIn heuristic → BIDS dataset
        → BIDS validator → pass/fail gate
            → MRIQC → QC reports (visual review)
                → fMRIPrep → preprocessed derivatives
```

Each step is wrapped in `datalad run`
(via [datalad-container]({{< ref "datalad-container" >}})
for containerized BIDS Apps)
so the full processing provenance is recorded.
[con/duct](https://github.com/con/duct) captures resource telemetry
(memory, CPU, wall time) for each step.

### BIDS Apps

| App | Purpose | Container |
|-----|---------|-----------|
| [MRIQC](https://mriqc.readthedocs.io/) | Image quality metrics and visual reports | Singularity via datalad-container |
| [fMRIPrep](https://fmriprep.org/) | Standardized fMRI preprocessing (motion correction, registration, confound estimation) | Singularity via datalad-container |

These are run as containerized BIDS Apps
registered in the dataset via `datalad containers-add`,
following the [ReproNim/containers](https://github.com/ReproNim/containers)
collection pattern.

## Hypothetical Vault Organization

> **TODO:** AI-generated layout, to be curated.

A lab typically runs multiple studies concurrently.
The vault groups data by study under `studies/`,
with shared sourcedata at the top level
and per-study BIDS datasets and derivatives below.
The BIDS-converted data lives under `sourcedata/bids-raw/`
following the BIDS convention for raw data placement
(see [bids-specification#2191](https://github.com/bids-standard/bids-specification/pull/2191)
for related discussions on directory naming).
Preprocessing may happen per recording session
(since sessions arrive incrementally from the scanner),
with study-level aggregation happening later.

```
lab-vault/                               # DataLad superdataset
    ├── sourcedata/                      # Raw acquisitions (all studies)
    │   ├── dicoms/                      # Raw DICOMs (ReproIn naming)
    │   │   ├── {date}/{session}/        # Per-session, routed by ReproIn study name
    │   │   └── ...
    │   ├── reprostim/                   # Stimulus capture recordings
    │   │   └── {date}/{session}/
    │   ├── birch/                       # Behavioral event logs
    │   │   └── {date}/{session}/
    │   └── physio/                      # Physiological recordings (if any)
    ├── studies/                          # Per-study BIDS datasets
    │   ├── study-taskswitch/            # One study
    │   │   ├── sourcedata/bids-raw/    # BIDS-converted (aggregated from sourcedata)
    │   │   │   ├── dataset_description.json
    │   │   │   ├── participants.tsv
    │   │   │   └── sub-01/
    │   │   │       ├── ses-01/
    │   │   │       │   ├── anat/
    │   │   │       │   ├── func/
    │   │   │       │   └── fmap/
    │   │   │       └── ...
    │   │   └── derivatives/
    │   │       ├── mriqc/               # QC reports for this study
    │   │       └── fmriprep/            # Preprocessed data
    │   ├── study-language/              # Another study
    │   │   ├── sourcedata/bids-raw/
    │   │   └── derivatives/
    │   └── ...
    ├── code/                            # Processing scripts, heuristics
    │   ├── heudiconv-heuristic.py
    │   └── processing-pipeline.sh
    ├── communications/
    │   └── slack/                       # Archived Slack channels
    ├── calendar/                        # Exported Google Calendar events
    ├── docs/                            # Lab protocols, SOPs
    └── .datalad/
```

DICOMs arrive per session and land in `sourcedata/dicoms/`.
The ReproIn study name in the DICOM headers
routes converted data to the correct study under `studies/`.
Derivatives can be produced per session as data arrives
(fMRIPrep on a single session)
and later aggregated into study-level summaries.

Each study, each derivative, and the communications dataset
are nested DataLad subdatasets,
following [YODA principles]({{< ref "about#yoda-and-how-conserve-extends-it" >}}).

## Distribution and Privacy

| Content | Distribution | Rationale |
|---------|-------------|-----------|
| BIDS sourcedata/bids-raw (defaced) | OpenNeuro / DANDI | Public sharing after defacing |
| Derivatives | OpenNeuro (as derivative dataset) | Public, no PII |
| Raw DICOMs | Private (encrypted backup only) | Contains facial features, PHI |
| Slack archives | Private (lab remote only) | Confidential communications |
| Calendar | Private | Lab scheduling details |
| Code | GitHub (public or private per repo) | Already public in most cases |
| ReproStim recordings | Private or restricted | May contain faces, voices |
| BIRCH event logs | Public (with BIDS dataset) | No PII in button presses |

Use git-annex `wanted` expressions with `distribution-restrictions` metadata
to enforce these policies automatically.
See [Privacy and Access Control]({{< ref "about#privacy-and-access-control" >}}).

## Workflow Overview

> **TODO:** AI-generated layout, to be curated.

{{< mermaid >}}
flowchart TD
    scanner[MRI Scanner] -->|DICOMs with ReproIn naming| dicoms[sourcedata/dicoms/]
    reprostim[ReproStim] -->|screen capture + QR timing| stim[sourcedata/reprostim/]
    birch[CurDes BIRCH] -->|event timing logs| events[sourcedata/birch/]

    dicoms -->|HeuDiConv + ReproIn routing| studies["studies/*/sourcedata/bids-raw/"]
    stim -->|timing extraction + annotation| studies
    events -->|convert to BIDS events.tsv| studies

    studies -->|BIDS validator| validate{valid?}
    validate -->|yes| mriqc[MRIQC -- QC reports]
    validate -->|no| fix[Fix issues]
    fix --> studies

    mriqc -->|visual review| qc_gate{QC pass?}
    qc_gate -->|yes| fmriprep[fMRIPrep -- preprocessing]
    qc_gate -->|flag| review[Human review]

    fmriprep --> derivatives["studies/*/derivatives/"]

    slack[Slack] -->|slackdump| comms[communications/slack/]
    gcal[Google Calendar] -->|export| calendar[calendar/]
    github[GitHub] -->|CI logs via con/tinuous| code[code/]

    subgraph vault[Lab Vault -- git-annex / DataLad]
        dicoms
        stim
        events
        studies
        mriqc
        derivatives
        comms
        calendar
        code
    end

    derivatives -->|datalad push| openneuro[OpenNeuro / DANDI]
    studies -->|defaced| openneuro
{{< /mermaid >}}

## Relevant Tools

| Component | Tool | Status |
|-----------|------|--------|
| DICOM to BIDS conversion | [HeuDiConv](https://github.com/nipy/heudiconv) + [ReproIn](https://github.com/repronim/reproin) | Mature, production-ready |
| Stimulus capture | [ReproStim](https://github.com/ReproNim/reprostim) | Active development |
| Stimulus annotation | [Annotation Garden]({{< ref "annotation-garden" >}}) | Alpha |
| Quality control | [MRIQC](https://mriqc.readthedocs.io/) | Mature |
| Preprocessing | [fMRIPrep](https://fmriprep.org/) | Mature |
| Container management | [datalad-container]({{< ref "datalad-container" >}}) | Stable |
| Resource telemetry | [con/duct](https://github.com/con/duct) | Stable |
| Slack archival | [slackdump]({{< ref "slackdump" >}}) | Working |
| CI log archival | [con/tinuous]({{< ref "tinuous" >}}) | Stable |
| Issue archival | [git-bug]({{< ref "git-bug" >}}) | Stable |
| Repository backup | [python-github-backup]({{< ref "github-backup" >}}) | Stable |
| Self-hosted forge | [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) | Beta |
| Deployment | [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) | Alpha |

## See Also

- [Domain Extensions: Neuroimaging]({{< ref "domain-extensions#example-neuroimaging-extension" >}}) --
  the neuroimaging domain extension that this story exercises
- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) --
  orchestration patterns for the DICOM-to-derivatives pipeline
- [Experience Ledger]({{< ref "experience-ledger" >}}) --
  capturing processing failures and resource baselines
- [Brain Imaging Center]({{< ref "brain-imaging-center" >}}) --
  the complementary story from the facility's perspective
- [Software Project]({{< ref "software-project" >}}) --
  deeper treatment of GitHub organization archival and Forgejo mirroring
