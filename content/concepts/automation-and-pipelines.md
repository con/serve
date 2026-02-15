---
title: "Automation and Pipelines"
date: 2026-02-13
description: "Research survey on automating vault operations -- ingestion triggers, data transformation pipelines, human-and-AI-in-the-loop curation, observability, and idempotent processing over git/git-annex/DataLad"
---

The [vault]({{< ref "vault-organization" >}}) stores heterogeneous research artifacts.
But getting data *into* the vault, transforming it, harmonizing it, and publishing it
requires **automation** (triggering actions when data arrives or changes)
and **pipelines** (multi-step processing chains with quality gates).

This page surveys the design space for both,
with an emphasis on the properties that matter in a git-annex/DataLad ecosystem:
idempotent operations, provenance tracking, selective human intervention,
and full audit trails.

## Two Related Problems

### 1. Operational Automation

Reacting to events -- new data appears in an external source,
a collaborator pushes to a sibling, a scheduled cron fires --
and executing the right ingestion or maintenance action.

Examples:
- A new video is uploaded to a YouTube channel
  → [annextube]({{< ref "tools/media/annextube" >}}) fetches it into the vault
- New DICOMs arrive on PACS
  → archive to the vault, feed to HeuDiConv/ReproIn for BIDS conversion
- A Slack workspace is updated
  → [slackdump]({{< ref "tools/communications/slackdump" >}}) performs incremental export

### 2. Data Transformation Pipelines (ETL)

Multi-step processing chains that transform raw ingested artifacts
into harmonized, quality-controlled, publishable datasets.

Examples:
- **annextube captions**: fetch auto-generated closed captions
  → AI-assisted curation and correction
  → human review of corrections
  → upload fixed captions back to YouTube
- **ReproStim**: capture stimuli video
  → [extract QR codes for timing synchronization](https://github.com/ReproNim/reprostim/issues/14)
  → slice video to match DICOM acquisition timing
  → align with behavioral event logs
  → package as BIDS (BEP044 Stimuli, BEP047 Behavior)
- **MRI processing**: archive raw DICOMs
  → HeuDiConv/ReproIn BIDS conversion
  → MRIQC quality control
  → fMRIPrep preprocessing
  → publish BIDS dataset to OpenNeuro, DANDI, or EMBER
- **Publications**: discover new citations
  → acquire PDFs via Unpaywall
  → sync to Zotero
  → annotate with distribution-restrictions metadata

## The Fundamental Execution Primitive

Every processing step in the vault -- whether a simple file fetch or a multi-hour fMRIPrep run --
should be executed through **`datalad run`**.
This is not one option among many; it is the foundation
on which all automation and orchestration is built.

`datalad run` captures commands with declared `--input` and `--output` files,
producing [machine-readable provenance records](https://handbook.datalad.org/en/latest/usecases/provenance_tracking.html)
that enable automated re-execution via `datalad rerun`:

```bash
# Execute with provenance capture
datalad run -m "Convert DICOMs to BIDS" \
    --input sourcedata/dicoms/ \
    --output sub-01/ \
    heudiconv -f reproin ...

# Re-execute a recorded command
datalad rerun <commit-sha>

# Re-execute all commands since a checkpoint
datalad rerun --since=HEAD~5
```

For finer-grained execution metadata --
resource usage (CPU, memory, I/O), wall time, child processes --
[con/duct](https://github.com/con/duct) wraps individual commands
and produces JSON Lines logs that can be archived alongside the data:

```bash
# Wrap a command with resource monitoring
datalad run -m "Run MRIQC with resource tracking" \
    --input sub-01/ --output derivatives/mriqc/ \
    duct --output-prefix .duct/mriqc- \
    mriqc bids-dir output-dir participant
```

Together, `datalad run` provides **provenance** (what ran, on what inputs, producing what outputs)
and `con/duct` provides **telemetry** (how long, how much memory, at what cost).
Both are committed to the git history, making the full execution record
an auditable, replayable part of the dataset.

## Core Design Principles

### Idempotent Operations

Every operation should be safely re-executable.
Given the same inputs, running a step again should produce the same outputs
without side effects.
This guarantees that we can **reset to a prior state and redo** --
which git/git-annex/DataLad makes structurally possible:

```bash
# Reset to a known good state
git reset --hard <good-commit>
datalad get .  # restore content from annex

# Replay the entire pipeline from that point
datalad rerun --since=<good-commit>
```

The combination of content-addressed storage (git-annex),
recorded provenance (`datalad run`),
and deterministic re-execution (`datalad rerun`)
gives the vault a native idempotency mechanism
that most pipeline frameworks must build from scratch.

### Provenance and Audit Trail

Every automated action must be recorded with enough detail
to answer "what happened, when, why, and by whom (or by which agent)."

The provenance stack:
1. **git commit log** -- the base layer: who, when, what changed
2. **`datalad run` records** -- structured provenance:
   command, inputs, outputs, environment
3. **`con/duct` logs** -- execution telemetry:
   resource usage, timing, child processes
4. **AI session archives** -- for AI-assisted steps:
   which model/agent, what prompt, what was proposed,
   what a human accepted or modified,
   the full conversation trace
   (archived via [Entire.io]({{< ref "tools/ai-sessions/entire-io" >}})
   or [Claude Code hooks]({{< ref "tools/ai-sessions/claude-code-hooks" >}}))

This audit trail is itself an archived artifact in the vault --
a dataset of operational provenance alongside the data it describes.

### Ingestion Formalization

Automation starts at the boundary:
getting data *into* the vault from external sources.
The [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) page catalogs
the different paradigms (direct download, API extraction, crawling, mounting, bridging),
each of which needs its own automation trigger
and its own `datalad run` wrapper
to capture provenance at the point of ingestion.

A formalized ingestion step should:
- Wrap the tool invocation in `datalad run` with `--input` (source specification) and `--output` (destination path)
- Record the source URL, API version, and any authentication context as metadata
- Set `distribution-restrictions` and provenance metadata
  at ingestion time (see [Privacy-Aware Distribution]({{< ref "conservation-to-external#privacy-aware-distribution" >}}))
- Be idempotent -- re-running should produce the same result or a clean incremental update

### Human-and-AI-in-the-Loop

Many vault operations cannot be fully automated.
Closed captions need human judgment to verify AI corrections.
BIDS conversion may surface naming conflicts that require a researcher's decision.
QC reports need expert eyes to flag artifacts.

The automation system must support **escalation points**
where the pipeline pauses, presents the issue to a human operator
(or an AI agent acting under human oversight),
records the decision, and resumes.

Patterns for this:
- **Pull request review gates** -- a pipeline step produces a PR;
  merging it (by human or auto-merge on passing tests) triggers the next step
- **Dashboard notifications** -- an observability UI highlights
  items needing attention, with links to the relevant data and context
- **AI-assisted triage** -- an LLM agent reviews the issue,
  proposes a resolution, and presents it for human approval,
  with the full exchange recorded as provenance

### Branch-Based Workflow Orchestration (BIDS-flux)

[BIDS-flux](https://bids-flux-docs.readthedocs.io/en/latest/)
(Basile Pinsard, UNB)
demonstrates a powerful pattern for pipeline orchestration using git branches:

- **Each data sample is a feature branch** --
  a new MRI session, a new video recording, a new batch of messages
  gets its own branch with commits for each processing stage
  (conversion, configuration, QC, anonymization)
- **Merging triggers downstream processing** --
  merging a raw-data branch into `dev` triggers MRIQC;
  passing MRIQC triggers fMRIPrep; each derivative produces a new PR
- **Human review at merge points** --
  PRs are the natural escalation mechanism;
  CI runs automated checks, humans review failures
- **Pilot branches** for rapid iteration --
  test pipeline configurations on a small subset
  before applying to the full dataset
- **Release branches** for versioned dataset publications --
  tagged releases become the basis for publishing to OpenNeuro/DANDI

This model maps directly onto Forgejo-aneksajo:
Forgejo Actions (built on [act](https://forgejo.org/docs/latest/admin/actions/),
compatible with GitHub Actions workflow syntax)
provide the CI/CD layer,
and git-annex content tracking ensures large files
are handled without bloating the repository.

See also the
[BIDS-flux talk by Basile Pinsard](https://datasets.datalad.org/repronim/ReproTube/DataLad/videos/2025/11/2025-11-12_Basile-Pinsard-BIDS-flux/video.en.vtt)
for a walkthrough of this architecture.

## Remote Compute Offloading

Heavy processing steps -- fMRIPrep on hundreds of subjects,
MRIQC across an entire study, video transcoding, LLM-based curation at scale --
should not be pinned to the machine hosting the vault.
The STAMPED principles of **portability** and **distribution**
apply to compute as much as to data:
a dataset should be shippable to wherever the compute lives,
processed there, and the results pulled back,
all with provenance intact.

### Prior Art

**[ReproMan](https://github.com/ReproNim/reproman)** --
Manages computing environments and orchestrates remote execution.
Its `datalad-pair` orchestrator syncs a local dataset to a remote machine
(via `datalad push` / `datalad create-sibling`),
runs the analysis there (submitting to HTCondor, PBS, SLURM, or local shell),
and fetches results back.
Used by [OpenNeuroDerivatives](https://github.com/OpenNeuroDerivatives)
to run fMRIPrep and MRIQC across hundreds of OpenNeuro datasets
on the TACC Frontera supercomputer -- though that project has not yet
exercised the full remote-offloading path.

**[FAIRly big](https://www.nature.com/articles/s41597-022-01163-2)** --
A DataLad-based framework for reproducible processing of large-scale data collections.
Each subject/session is processed independently as an ephemeral clone:
the dataset is cloned to compute, the BIDS App runs,
outputs are pushed back, and the clone is discarded.
This naturally exercises git-annex's content distribution --
only the needed inputs are fetched to the compute node,
and only the new outputs are pushed back.
The key insight: **the dataset is the unit of portability**,
not the pipeline script.

**[BABS](https://pennlinc-babs.readthedocs.io/)** (BIDS App Bootstrap) --
A user-friendly instantiation of the FAIRly big framework.
BABS auto-generates job submission scripts for SGE and SLURM clusters,
wraps BIDS App execution in `datalad run`,
and records the full audit trail.
Demonstrated at scale on HBN (n=2,565 subjects).
BABS shows that the `datalad run` + ephemeral clone + HPC cluster pattern
works in practice for large neuroimaging datasets.

### Generalization for the Vault

The same pattern applies beyond neuroimaging:

1. **Clone** the relevant subdataset to the compute resource
   (HPC cluster, cloud VM, collaborator's workstation)
2. **Fetch** only the needed inputs via `datalad get`
3. **Execute** the processing step via `datalad run` (+ `con/duct` for telemetry)
4. **Push** outputs back to the vault
5. **Discard** the ephemeral clone

This means the vault itself can run on modest infrastructure
(a Forgejo-aneksajo instance with storage)
while heavy compute is dispatched to wherever resources are available --
a university HPC cluster, a cloud burst instance, or a collaborator's GPU server.

## Orchestration Layer

With `datalad run` as the execution primitive
and remote offloading as the compute model,
the remaining question is: **what triggers and sequences the steps?**

### Forgejo Actions (Native)

The natural first choice for a Forgejo-aneksajo deployment.
Workflows defined in `.forgejo/workflows/` YAML files,
triggered by push, PR, schedule (cron), or webhook events.
[Forgejo Actions](https://forgejo.org/docs/latest/admin/actions/)
are built on [act](https://forgejo.org/docs/latest/admin/actions/),
compatible with GitHub Actions workflow syntax.
Runners execute jobs in containers or on bare metal.
Limitations: no built-in dashboard beyond Forgejo's Actions tab,
limited cross-repository orchestration.

### General-Purpose Orchestrators

Tools from the data engineering world
that could serve as an outer orchestration layer
(wrapping each task as a `datalad run` call):

| Tool | Key Feature | Fit for Vault |
|------|-------------|---------------|
| [Dagster](https://dagster.io/) | Asset-oriented, built-in observability UI, GitOps-friendly | Strong -- asset model maps to DataLad datasets; UI provides the missing dashboard |
| [Prefect](https://www.prefect.io/) | Python-native, event-driven, retries/caching | Good -- flexible triggers, but less asset-oriented |
| [Apache Airflow](https://airflow.apache.org/) | Mature DAG scheduler, large ecosystem | Heavy -- designed for data warehouses, may be over-complex |
| [Kestra](https://kestra.io/) | Declarative YAML workflows, event-driven, built-in UI | Interesting -- YAML workflows parallel Forgejo Actions syntax |

The key integration point:
every orchestrator task wraps a `datalad run` call,
so provenance is captured regardless of which scheduler triggers it,
and every task can optionally offload to remote compute
via the clone-execute-push pattern.

## Observability and Dashboarding

Operators need to see at a glance:
- Which ingestion sources are up to date and which are stale
- Which pipeline steps have succeeded, failed, or are awaiting human review
- Which items have unresolved QC issues or merge conflicts
- The overall health of the vault (storage usage, annex content distribution, broken links)

Options for building this:
- **Forgejo Actions UI** -- basic per-workflow run status
- **Dagster UI** -- asset lineage, run history, sensor status
  (if Dagster is adopted as orchestrator)
- **Custom dashboard** -- a lightweight web app
  (Hugo page, Datasette, or Grafana)
  querying git log, `git annex info`, and CI status APIs
- **[con/tinuous]({{< ref "tools/code-artifacts/tinuous" >}})** --
  could archive CI logs from Forgejo into the vault itself,
  making operational history a first-class archived artifact

## Concrete Pipeline: annextube Caption Curation

A worked example combining automation, AI-in-the-loop, and idempotency:

```
1. Trigger: cron schedule or webhook on new YouTube upload
2. annextube fetch: download video + auto-generated captions
   → datalad run --input=... --output=captions/
3. AI curation: LLM agent reviews captions, proposes corrections
   → datalad run --output=captions-corrected/
   → AI session archived via Entire.io
4. Human review: PR created with diff of original vs. corrected
   → reviewer approves, requests changes, or edits manually
5. Upload: approved captions pushed back to YouTube
   → datalad run --input=captions-corrected/ --output=upload-log/
6. Audit: full chain recorded in git log with datalad provenance
   → resettable to any prior state; re-runnable from any step
```

Each step is idempotent.
The AI session transcript is itself an archived artifact.
The PR review is the human-in-the-loop gate.
The entire chain is re-executable via `datalad rerun`.

## Open Questions

- **Cross-repository orchestration** --
  how to trigger a pipeline in dataset B when dataset A is updated,
  when both are subdatasets of the vault superdataset
- **Credential management** --
  automation needs API tokens for YouTube, Slack, GitHub, etc.;
  where and how to store them securely
  in a Forgejo-aneksajo deployment
- **Scaling** --
  when the vault has hundreds of subdatasets with active pipelines,
  how to prioritize and schedule without overwhelming runners
- **AI agent authorization boundaries** --
  what actions can an AI agent take autonomously
  vs. what requires human approval;
  how to encode these policies declaratively

## See Also

- [Experience Ledger]({{< ref "experience-ledger" >}}) -- compressing execution logs into reusable operational knowledge
- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- how data enters the vault
- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- publishing and backup
- [Vault Organization]({{< ref "vault-organization" >}}) -- directory layout for the vault
- [Domain Extensions]({{< ref "domain-extensions" >}}) -- domain-specific processing pipelines
