---
title: "Experience Ledger"
date: 2026-02-13
description: "Compressing operational experiences into reusable knowledge -- extracting patterns from execution logs, CI archives, and failure histories to guide future processing decisions"
standards: ["LinkML", "PROV-DM"]
---

Every pipeline run produces logs.
Most of them are never looked at again --
until something goes wrong, and then someone wishes they had been
paying attention all along.

An **experience ledger** is a structured, compressed record
of what the vault's automated operations have learned over time:
which processing steps fail and why,
which datasets need special handling,
how resource requirements vary across data types,
and what resolutions worked for past problems.

It is another application of the
[Frozen Frontier]({{< ref "about#frozen-frontiers" >}}) pattern:
raw execution logs are the deep stratum,
the ledger is the working surface --
a condensed, queryable knowledge base
with back-pointers to the original evidence.

## The Raw Material

The vault already produces execution records at multiple levels:

| Layer | Tool | What it captures | Format |
|-------|------|-----------------|--------|
| **Provenance** | `datalad run` | Command, inputs, outputs, environment | JSON in git commit metadata |
| **Telemetry** | [con/duct](https://github.com/con/duct) | CPU, memory (peak/avg RSS, VSZ), I/O, wall time, child processes | JSON Lines (`.duct/`) |
| **CI history** | [con/tinuous](https://github.com/con/tinuous) | Build logs, artifacts, success/failure status from GitHub Actions, Travis, Appveyor | Text logs + metadata in git-annex |
| **Remote jobs** | [ReproMan](https://github.com/ReproNim/reproman) | Job submission scripts, scheduler logs, resource allocation | Provenance records in git history |
| **AI sessions** | [Claude Code hooks]({{< ref "tools/ai-sessions/claude-code-hooks" >}}), [Entire.io]({{< ref "tools/ai-sessions/entire-io" >}}) | Agent reasoning, decisions, session transcripts | JSON / Markdown |

Each layer produces useful data in isolation.
The experience ledger connects them:
a con/duct log showing OOM
links to the datalad run commit that recorded the command,
to the con/tinuous archive of the CI run that triggered it,
and to the dataset version that was being processed.

## Compressing Experience

Raw logs are too voluminous to consult directly.
The ledger compresses them into actionable patterns:

### Failure Patterns

A failure pattern captures:
- **What failed**: processing step, tool, version
- **How it failed**: exit code, failure mode (OOM, timeout, disk full, data error, configuration error)
- **On what**: dataset identity, data characteristics (number of subjects, file sizes, modalities)
- **Evidence**: pointer to the con/duct log, CI log, and git commit
- **Resolution**: what fixed it (more memory, different parameters, data cleanup, upstream bug fix)
- **Recurrence**: how often this pattern has appeared

```
failure_pattern:
  id: fp-001
  type: oom
  tool: fmriprep/24.1.1
  step: bold_hmc (head motion correction)
  trigger: datasets with >300 BOLD volumes per run
  peak_rss_gb: 42.7  # from con/duct
  allocated_gb: 32
  first_seen: 2025-08-14
  occurrences: 17
  affected_datasets:
    - ds003456 (sub-01, sub-07, sub-12)
    - ds004789 (sub-03)
  resolution: "Request 64GB node; upstream fix in fmriprep/25.0.0"
  evidence:
    - duct_log: .duct/fmriprep-ds003456-sub01-20250814.jsonl
    - ci_run: ci/github/push/2025/08/14/fmriprep-process/8834/
    - commit: a1b2c3d4
```

### Resource Baselines

Aggregate con/duct telemetry into per-tool, per-data-type baselines:

| Tool | Data type | Typical peak RSS | Typical wall time | Known edge cases |
|------|-----------|-----------------|-------------------|-----------------|
| fMRIPrep | Single-session functional | 8-12 GB | 4-8 hours | Multi-echo: 2x memory; >300 volumes: risk OOM at 32 GB |
| MRIQC | Structural T1w | 2-4 GB | 15-30 min | Large FOV: 2x time |
| HeuDiConv | DICOM session | 0.5-1 GB | 2-10 min | Non-standard series descriptions: may need custom heuristic |

These baselines guide resource requests for new runs
and trigger alerts when a run deviates significantly from the expected profile.

### Operational Heuristics

Distilled rules of thumb from accumulated experience:

- "fMRIPrep on datasets from scanner X consistently needs `--skull-strip-t1w force`"
- "slackdump incremental exports fail silently if the API token has expired; check freshness first"
- "annextube re-runs on channels with deleted videos produce empty stubs; filter before committing"
- "MRIQC group reports require raw BIDS data even after individual processing; keep inputs available"

These are the kind of knowledge that accumulates in a team's collective memory
and is lost when people move on.
The ledger makes it explicit, version-controlled, and queryable.

## Concrete Use Case: OpenNeuroDerivatives

[OpenNeuroDerivatives](https://github.com/OpenNeuroDerivatives)
runs fMRIPrep and MRIQC across 784+ OpenNeuro datasets
on the TACC Frontera supercomputer
using [BABS](https://pennlinc-babs.readthedocs.io/)
(which wraps execution in `datalad run`).

At this scale, failures are routine:
- Subjects that run out of memory on 32 GB nodes
- Datasets with non-standard BIDS structures that trip validation
- Processing steps that timeout on unusually large acquisitions
- Intermittent infrastructure failures (node crashes, filesystem hiccups)

Without an experience ledger, each failure is investigated from scratch.
The operator reads the log, diagnoses the issue,
applies a fix, and moves on --
carrying the knowledge only in their head.

With a ledger, the pattern is recorded:
the next time a similar dataset arrives,
the system (or a [pipeline-operator]({{< ref "#agents-and-the-ledger" >}}) agent)
can consult past experience
and preemptively allocate more memory,
apply the known workaround,
or flag the dataset for manual review
before wasting a compute allocation on a predictable failure.

## Dataset Identity and the Ledger

The experience ledger must track *which* dataset was processed,
but dataset identity in a DataLad ecosystem is more nuanced
than a single file path.

The same DataLad dataset (git/git-annex repository)
can exist at multiple locations in different versions:
- The canonical copy on Forgejo-aneksajo
- A sibling on GitHub or GIN
- A clone on a compute cluster
- A published snapshot on OpenNeuro or DANDI
- A local working copy on a researcher's laptop

DataLad identifies datasets using
[multiple layers of identity](https://concepts.datalad.org/):

| Identity layer | What it identifies | Persistence |
|---|---|---|
| **Dataset UUID** | The dataset as a whole, across its entire history | Permanent -- created once at `datalad create` |
| **Git commit SHA** | A specific version (snapshot) of the dataset | Immutable -- content-addressed |
| **Annex key** | A specific file content, regardless of path or dataset | Immutable -- content-addressed (typically SHA256) |
| **PID (DOI, Handle)** | A published version, citable and resolvable | Permanent -- assigned at publication |

The [DataLad concepts vocabulary](https://concepts.datalad.org/s/demo-research-information/unreleased/)
formalizes these identity layers using [LinkML](https://linkml.io/):

- **Thing** as the base class with a `pid` (persistent identifier) slot
  and additional context-specific `identifiers`
- **Dataset** with `version_of`, `revision_of`, `derived_from`, `alternate_of`
  relations for tracking how versions relate
- **Distribution** for modeling the same dataset at multiple locations
- **Checksum** (subtypes: DOI, ORCID, ISSN) for integrity and identity verification

The experience ledger links execution records to datasets
via their UUID and commit SHA --
so "fMRIPrep on ds003456 at commit abc123" is an unambiguous reference
regardless of where that dataset lives.
When the same dataset is processed again at a later version,
the ledger can compare outcomes across versions.

### PROV-DM and the Execution Record

The DataLad concepts vocabulary includes a
[PROV-DM](https://www.w3.org/TR/prov-dm/) interface
(`things-prov` schema) that models:

- **Activities**: things that occur over time and act upon entities
  (a pipeline run, an ingestion step, an AI curation session)
- **Entities**: things that are used and generated by activities
  (datasets, files, configuration, the ledger itself)
- **Agents**: things that bear responsibility for activities
  (human operators, AI assistants, automated pipelines)

Each activity connects to entities through qualified relationships:
`Generation` (activity produced entity),
`Usage` (activity consumed entity),
`Derivation` (output entity derived from input entity),
`Revision` (new version of an existing entity).

The experience ledger could extend this provenance model
with execution-specific attributes:
the command recorded by `datalad run`, exit codes,
resource telemetry from con/duct (peak RSS, CPU, wall time),
compute context (local, HPC cluster, cloud instance),
failure mode classification (OOM, timeout, data error),
and resolution notes.
Each execution would be a PROV Activity
with qualified links to the dataset entities it consumed and produced,
the agent (human, AI, or automated pipeline) that triggered it,
and the resource telemetry that characterized it --
keeping the ledger's metadata interoperable
with the broader DataLad metadata ecosystem.

## The Ledger as Frozen Frontier

The experience ledger is itself a Frozen Frontier:

| Stratum | Content | Consumers |
|---------|---------|-----------|
| **Raw logs** | con/duct JSON Lines, CI build output, job scheduler logs, ReproMan provenance records | Forensic debugging, root cause analysis |
| **Condensed ledger** | Failure patterns, resource baselines, operational heuristics, resolution history | Pipeline operators, AI agents, capacity planning |
| **Dashboard** | Items needing attention, overdue ingestions, health metrics | Lab managers, daily operations |

Each level is a compressed context over the one below.
The raw logs live in the vault (archived by con/tinuous,
committed alongside data by con/duct).
The ledger summarizes them.
The dashboard summarizes the ledger.
And because everything is in git-annex,
you can always drill down from the dashboard
through the ledger
to the original log line that explains the anomaly.

## Agents and the Ledger

The vault's [AI agents]({{< ref "concepts/agents" >}}) are
both consumers and producers of the experience ledger.

An AI agent specialized in pipeline operations --
a "pipeline-operator" --
would be the primary consumer of the experience ledger.
When investigating a failure, it should:

1. Query the ledger for similar past failures
   (same tool, same failure mode, similar dataset characteristics)
2. Check whether a known resolution exists
3. If so, propose applying the known fix
4. If not, investigate from scratch using the raw logs,
   then record the new pattern in the ledger

This is how operational knowledge accumulates:
each incident enriches the ledger,
and the agent's effectiveness improves over time --
not because the model changes,
but because the knowledge base it consults grows.

The **ingestion-curator** agent also benefits:
it can check the ledger for source-specific quirks
before formalizing a new ingestion step
("the last three times we ingested from this API,
rate limiting kicked in after 1000 requests;
add backoff to the wrapper").

## Connecting to Data Knowledge

The experience ledger records **operational knowledge** --
what happened when we processed data on this system.
But operational outcomes depend on **data characteristics**:
a dataset with 200 subjects and multi-echo acquisitions
demands very different resources than one with 16 subjects
and short BOLD runs.

The extraction of dataset characteristics --
per-subject summary tables, file counts, sizes, durations --
is covered in [Metadata Extraction and Dependencies]({{< ref "metadata-extraction" >}}).
That is **data knowledge**: intrinsic properties of the data itself,
independent of where or how it is processed.

The experience ledger *consumes* data knowledge
to correlate failures with dataset properties:
"fMRIPrep OOMs on datasets where `bold_voxels_total > 300`."
But it does not produce it.
The data extraction pipeline produces the summary tables;
the experience ledger correlates them with execution outcomes
to build informed strategies for resource allocation,
parallelization, and preemptive failure avoidance.

## Open Questions

- **Schema formalization** --
  should the experience ledger use a formal extension
  of the [DataLad concepts vocabulary](https://concepts.datalad.org/),
  or is a lighter-weight format (YAML records, git-annex metadata) sufficient?
- **Automation boundary** --
  which ledger entries can be extracted automatically from logs
  vs. which require human annotation
  (e.g., "this failure was caused by a known scanner firmware bug")?
- **Cross-vault knowledge** --
  can experience ledgers be shared across vault instances
  (e.g., our lab's fMRIPrep experience is useful to another lab running the same pipeline)?
  What are the privacy implications of sharing operational profiles?
- **Relationship to DataLad Catalog and Registry** --
  the [DataLad Catalog](https://docs.datalad.org/projects/catalog/)
  provides metadata browsing,
  and the [DataLad Registry](https://registry.datalad.org/)
  already indexes 23,000+ datasets.
  Could the experience ledger be surfaced through these existing interfaces?

## See Also

- [AI Agents and Vault Operations]({{< ref "concepts/agents" >}}) --
  the agent roles that consume and produce ledger entries
- [Metadata Extraction and Dependencies]({{< ref "metadata-extraction" >}}) --
  data knowledge extraction that the ledger correlates with operational outcomes
- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) --
  the execution stack that produces the raw material for the ledger
- [Frozen Frontiers]({{< ref "about#frozen-frontiers" >}}) --
  the conceptual framework for compressed working surfaces
- [Vault Organization]({{< ref "vault-organization" >}}) --
  where the ledger dataset lives in the vault hierarchy
- [DataLad concepts vocabulary](https://concepts.datalad.org/) --
  the metadata schema for dataset identity and provenance
