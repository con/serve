---
title: "Brain Imaging Center"
date: 2026-02-17
description: "A shared MRI facility serving multiple labs needs streamlined data flow, phantom QA monitoring, and automated preprocessing at scale"
summary: "A brain imaging center operating an MRI scanner for multiple research labs. The center collects DICOMs with ReproIn conventions, captures stimuli with ReproStim and behavioral events with CurDes BIRCH, runs weekly phantom QA to monitor scanner health, records environmental conditions, and provides streamlined preprocessing via HPC. Data flows from a single scanner to many labs, each with their own vault, while the center maintains its own operational datasets."
tags: ["user-story", "neuroimaging", "BIDS", "MRI", "facility", "QA", "HPC"]
---

## The Goal

A brain imaging center operates an MRI scanner
shared by multiple research labs.
The center is not a research lab itself --
it is **infrastructure** that serves many labs.

Its responsibilities are different from a single lab's:

- Collect data for **many labs** with consistent quality
- Monitor **scanner health** through regular phantom acquisitions
- Provide **streamlined preprocessing** so labs receive analysis-ready data
- Maintain **environmental records** (temperature, humidity) for data quality auditing
- Capture **stimuli and behavioral events** for all experiments
- Ensure data flows to the right lab with the right access controls

Today this involves a lot of manual coordination:
DICOMs sit on a PACS, phantom QA images are analyzed ad hoc,
environmental logs are on a separate system,
and each lab fetches their data through informal channels.

## Data Sources

### MRI Acquisitions (DICOMs for All Labs)

The center's primary data stream.
All sessions use the [ReproIn](https://github.com/repronim/reproin) naming convention,
which encodes study name, subject, and session identifiers
directly in DICOM series descriptions.
This allows automated routing:
the study name in the DICOM header determines
which lab's vault receives the converted data.

| Volume | Frequency |
|--------|-----------|
| 5-50 sessions per week | Multiple studies running concurrently |
| 2-15 GB per session | Varies by protocol (structural vs. long functional runs) |

### Phantom QA

Weekly phantom scans monitor scanner performance over time.
This is the center's own data -- not belonging to any research lab.

An example of this in practice is the
[DBIC QA dataset](https://datasets.datalad.org/?dir=/dbic/QA),
which archives phantom QA data from the Dartmouth Brain Imaging Center
as a DataLad dataset.

Key metrics tracked:

| Metric | What it detects |
|--------|----------------|
| Signal-to-noise ratio (SNR) | Overall scanner sensitivity degradation |
| Signal uniformity | Coil failures, gradient issues |
| Ghosting ratio | EPI artifact levels |
| Geometric distortion | Gradient calibration drift |
| Temporal stability | Noise floor for functional imaging |

The QA data flows through MRIQC (or dedicated phantom QA tools)
and produces trend reports.
Deviations from baseline trigger alerts --
a sudden SNR drop could indicate a hardware problem
that would affect all studies running that week.

### Environmental Monitoring

Temperature and humidity sensors in the scanner room
and equipment room produce continuous logs.
These matter because:

- MRI scanner performance is temperature-sensitive
- Humidity affects patient comfort and can cause condensation issues
- Environmental excursions correlate with data quality anomalies
- Regulatory compliance may require environmental records

These are low-volume data streams (a few KB per day)
that need to be archived alongside the imaging data
for quality auditing and troubleshooting.

### Stimulus Capture (ReproStim)

[ReproStim](https://github.com/ReproNim/reprostim) captures
the audio/video stimuli presented during every experiment --
screen recordings with QR-code-embedded timing synchronization.

For the center, this serves as an independent record
of what stimuli were actually presented (as opposed to what was intended),
supporting quality control and reproducibility across all labs.
Captured media can be annotated via [Annotation Garden]({{< ref "annotation-garden" >}}).

### Behavioral Events (CurDes BIRCH)

The CurDes BIRCH response box is shared infrastructure --
the center provides and maintains it,
and all labs use it for recording participant responses.
The center archives the raw event logs
and delivers them to the appropriate lab alongside the imaging data.

## Processing Infrastructure

The center has access to an HPC cluster
for running preprocessing pipelines at scale.
The goal is to provide **turnkey preprocessing**
so labs receive analysis-ready derivatives
without managing their own compute.

### Pipeline Architecture

```
DICOMs arrive (ReproIn naming, per-study routing)
    → HeuDiConv + ReproIn → BIDS dataset (per study)
        → BIDS validation → pass/fail
            → MRIQC → QC report
                → fMRIPrep → preprocessed derivatives
                    → deliver to lab's vault
```

This follows the
[FAIRly big](https://www.nature.com/articles/s41597-022-01163-2) pattern:
each subject/session is processed as an ephemeral clone on the HPC --
clone the dataset, fetch inputs, run the BIDS App via
[datalad-container]({{< ref "datalad-container" >}}),
push outputs back, discard the clone.
[BABS](https://pennlinc-babs.readthedocs.io/) automates
the job submission and `datalad run` wrapping for SGE/SLURM clusters.

The [BIDS-flux](https://bids-flux-docs.readthedocs.io/) branching model
can organize this further:
each session is a feature branch,
processing stages are commits on the branch,
and merging triggers the next pipeline step.

### Scale Considerations

Processing for multiple labs simultaneously:

| Dimension | Challenge |
|-----------|-----------|
| **Scheduling** | Multiple studies compete for HPC allocation |
| **Priority** | Some studies have urgent deadlines, others are archival |
| **Heterogeneity** | Different protocols need different fMRIPrep parameters |
| **Failures** | OOM on large runs, heuristic mismatches, transient HPC issues |

The [experience ledger]({{< ref "experience-ledger" >}})
captures processing failures and resource baselines per study type,
so the center builds institutional knowledge about which protocols
need special handling.

## Vault Organization

The center maintains its own vault,
distinct from each lab's individual vault:

```
center-vault/                            # DataLad superdataset
    ├── incoming/                        # Raw DICOMs before routing
    │   └── {date}/{session}/
    ├── studies/                          # Per-study BIDS datasets
    │   ├── study-alpha/                 # Lab A's study
    │   │   ├── sourcedata/dicoms/
    │   │   ├── rawdata/                 # BIDS
    │   │   └── derivatives/
    │   │       ├── mriqc/
    │   │       └── fmriprep/
    │   ├── study-beta/                  # Lab B's study
    │   └── ...
    ├── qa/                              # Center's own QA data
    │   ├── phantom/                     # Weekly phantom scans
    │   │   ├── {date}/
    │   │   └── trends/                  # Longitudinal QC metrics
    │   └── environmental/               # Temperature, humidity logs
    ├── reprostim/                       # All stimulus captures
    │   └── {date}/{session}/
    ├── birch/                           # All behavioral event logs
    │   └── {date}/{session}/
    └── .datalad/
```

### Data Routing

ReproIn naming enables automatic routing.
A DICOM session with series descriptions like
`anat-scout`, `func-bold_task-rest_run-01`
under study name `alpha`
is automatically placed in `studies/study-alpha/`
by the HeuDiConv conversion step.

Each study directory is a DataLad subdataset
that can be cloned by the corresponding lab:

```bash
# Lab A clones their study from the center
datalad clone center-vault/studies/study-alpha lab-vault/sourcedata/center-data
```

### QA as an Independent Dataset

The phantom QA data is the center's own dataset,
published independently.
The DBIC publishes theirs at
[datasets.datalad.org/dbic/QA](https://datasets.datalad.org/?dir=/dbic/QA) --
a pattern that any center can follow.

Longitudinal QA trends (SNR over time, ghosting ratios, geometric stability)
are extracted into summary tables,
following the [metadata extraction]({{< ref "metadata-extraction" >}}) pattern.
Deviations from baseline are flagged automatically.

## Scanner Health Monitoring

The center needs an at-a-glance view of scanner health:

| Signal | Source | Alert condition |
|--------|--------|----------------|
| SNR trend | Phantom QA (weekly) | >10% deviation from 3-month baseline |
| Ghosting ratio | Phantom QA | Exceeds threshold for EPI sequences |
| Temperature | Environmental sensors | Outside 18-22 C operating range |
| Humidity | Environmental sensors | Above 60% RH |
| Last QA date | Phantom acquisition log | Overdue by >2 days |
| Processing backlog | HPC job queue | >48h of unprocessed sessions |

This is an [observability dashboard]({{< ref "automation-and-pipelines#observability-and-dashboarding" >}})
for the scanner rather than for a single study.
The experience ledger captures the center's
institutional knowledge of scanner behavior --
"the magnet tends to drift after the helium top-up"
or "humidity spikes correlate with ghosting increases in summer."

## Distribution and Privacy

The center has more complex distribution requirements than a single lab,
because data must flow to different labs with different access policies:

| Content | Distribution | Rationale |
|---------|-------------|-----------|
| Study DICOMs | Private, routed to owning lab only | PHI, lab-specific |
| Study BIDS (defaced) | Lab's discretion to publish | Lab decides when/if to share |
| Study derivatives | Lab's discretion | Lab controls publication |
| Phantom QA | Public (DataLad dataset) | No PII, community benefit |
| Environmental logs | Public or restricted | No PII, useful for data quality auditing |
| ReproStim recordings | Private, routed to owning lab | May contain faces/voices |
| BIRCH event logs | Routed to owning lab, publishable with BIDS | No PII |

git-annex `wanted` expressions enforce per-study routing:
each lab's remote only receives content tagged with their study name.

## Workflow Overview

```mermaid
flowchart TD
    scanner[MRI Scanner] -->|DICOMs| incoming[incoming/]
    phantom[Weekly Phantom] -->|DICOMs| qa_raw[qa/phantom/]
    sensors[Temp/Humidity] -->|logs| env[qa/environmental/]
    reprostim[ReproStim] -->|captures| stim[reprostim/]
    birch[CurDes BIRCH] -->|events| events[birch/]

    incoming -->|ReproIn routing + HeuDiConv| studies[studies/{study}/rawdata/]
    qa_raw -->|MRIQC phantom mode| qa_reports[qa/phantom/trends/]
    stim -->|match to session| studies
    events -->|match to session| studies

    studies -->|BIDS validation| validate{valid?}
    validate -->|yes| mriqc[MRIQC]
    validate -->|no| fix[Fix / escalate]

    mriqc --> fmriprep[fMRIPrep on HPC]
    fmriprep --> derivs[studies/{study}/derivatives/]

    derivs -->|datalad push| lab_a[Lab A vault]
    derivs -->|datalad push| lab_b[Lab B vault]
    studies -->|datalad push| lab_a
    studies -->|datalad push| lab_b

    qa_reports -->|trend analysis| dashboard[Scanner Health Dashboard]
    env -->|correlate| dashboard

    subgraph center[Center Vault -- git-annex / DataLad]
        incoming
        qa_raw
        env
        stim
        events
        studies
        qa_reports
        derivs
    end

    subgraph hpc[HPC Cluster]
        fmriprep
    end
```

## Relevant Tools

| Component | Tool | Status |
|-----------|------|--------|
| DICOM to BIDS | [HeuDiConv](https://github.com/nipy/heudiconv) + [ReproIn](https://github.com/repronim/reproin) | Mature |
| Quality control | [MRIQC](https://mriqc.readthedocs.io/) | Mature |
| Preprocessing | [fMRIPrep](https://fmriprep.org/) | Mature |
| HPC job management | [BABS](https://pennlinc-babs.readthedocs.io/) | Active development |
| Container management | [datalad-container]({{< ref "datalad-container" >}}) | Stable |
| Resource telemetry | [con/duct](https://github.com/con/duct) | Stable |
| Stimulus capture | [ReproStim](https://github.com/ReproNim/reprostim) | Active development |
| Stimulus annotation | [Annotation Garden]({{< ref "annotation-garden" >}}) | Alpha |
| Remote compute | [ReproMan](https://github.com/ReproNim/reproman) | Stable |
| Branch workflow | [BIDS-flux](https://bids-flux-docs.readthedocs.io/) | Documentation stage |
| Deployment | [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) | Alpha |

## See Also

- [Neuroimaging Lab]({{< ref "neuroimaging-lab" >}}) --
  the complementary story from a single lab's perspective
- [Domain Extensions: Neuroimaging]({{< ref "domain-extensions#example-neuroimaging-extension" >}}) --
  the neuroimaging domain extension
- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) --
  orchestration patterns, BIDS-flux, remote compute offloading
- [Experience Ledger]({{< ref "experience-ledger" >}}) --
  capturing processing failures and scanner-specific operational knowledge
- [Metadata Extraction]({{< ref "metadata-extraction" >}}) --
  extracting QA trend summaries from phantom data
