---
title: "Metadata Extraction and Dependencies"
date: 2026-02-13
description: "Extracting, summarizing, and keeping up-to-date the data knowledge that lives inside vault datasets -- from per-file metadata to hierarchical summary tables, with git-native dependency tracking for incremental recomputation"
---

Every dataset in the vault contains more knowledge
than its raw files alone express.
A BIDS neuroimaging dataset has per-subject file counts,
scan durations, voxel dimensions, modality coverage.
A YouTube archive has per-channel video counts, total durations,
caption availability.
A Slack export has message counts, attachment sizes, date ranges.

This **data knowledge** -- intrinsic properties of the data itself,
independent of where or how it is processed --
needs to be extracted, summarized into navigable tables,
and kept up to date as the data evolves.

This is distinct from **operational knowledge**
(which processing steps fail on which systems,
how much memory a particular cluster needs) --
that is the domain of the [Experience Ledger]({{< ref "experience-ledger" >}}).
Data knowledge is about the data;
operational knowledge is about the infrastructure.
The two connect -- the experience ledger correlates failures
with dataset characteristics --
but they are maintained separately.

## The Pattern: Hierarchical Extraction

The vault already demonstrates this pattern in several places.
The [Data-Visualization Separation]({{< ref "data-visualization-separation" >}})
page describes the presentation side;
here we focus on the extraction and dependency tracking
that keeps the summaries current.

### Existing Examples

**annextube** builds a three-tier summary pyramid:

```
archive/
  channels.tsv                     # all channels at a glance
  {channel}/
    channel.json                   # per-channel stats
    videos/
      videos.tsv                   # all videos in this channel
      {year}/{month}/{video_id}/
        metadata.json              # full detail for one video
```

Each level is distilled from the one below:
`metadata.json` → `videos.tsv` → `channels.tsv`.

**mykrok** does the same with hive-partitioned paths:

```
data/
  athletes.tsv                     # all athletes
  athl=alice/
    sessions.tsv                   # all sessions for this athlete
    ses=2024-03-15T08-30/
      info.json                    # per-session detail
```

**BIDS** applies the pattern to neuroimaging:
common sidecar metadata (e.g., `task-rest_bold.json`)
at higher directory levels applies to all files below
(metadata inheritance);
`participants.tsv` at the root summarizes all subjects;
`dataset_description.json` describes the dataset as a whole.
HeuDiConv extracts shared acquisition parameters
and places them at the appropriate inheritance level.

**OpenNeuroStudies** extends this with
[`sourcedata+subjects.tsv`](https://github.com/OpenNeuroStudies/study-ds000001/blob/8a9d02a/sourcedata/sourcedata%2Bsubjects.tsv) --
a per-subject operational profile:

| source_id | subject_id | bold_num | bold_size | bold_duration_total | bold_voxels_total | t1w_num | t1w_size | datatypes |
|-----------|-----------|----------|-----------|--------------------|--------------------|---------|----------|-----------|
| ds000001 | sub-01 | 3 | 141871303 | 1800.0 | 405504 | 1 | 5663237 | anat,func |
| ds000001 | sub-02 | 3 | 139465821 | 1800.0 | 405504 | 1 | 5487612 | anat,func |

These summaries distill operationally relevant properties:
file counts and sizes by modality, scan durations, voxel counts --
exactly the fields that predict resource requirements
for downstream processing.

### The General Rule

Every dataset type in the vault should maintain
summary tables at appropriate granularities:

| Artifact type | Per-item summary | Aggregation level | Top-level summary |
|---------------|-----------------|-------------------|-------------------|
| BIDS neuroimaging | per-subject: modalities, file sizes, durations, voxel counts | per-session or per-task | `participants.tsv` + `sourcedata+subjects.tsv` |
| YouTube archive | per-video: duration, resolution, caption availability | per-channel: video count, total duration | `channels.tsv` |
| Slack workspace | per-channel: message count, attachment size, date range | per-workspace | `workspaces.tsv` |
| Citations | per-reference: has PDF, PDF size, year | per-collection | `collections.tsv` |
| Git forge | per-issue/PR: comment count, attachment size | per-repository | `repos.tsv` |

These are **data knowledge** tables --
properties of the content itself,
useful for any consumer (human, AI, pipeline scheduler, dashboard)
regardless of what system processes them.

## Row-Level Dependency Tracking

The key challenge is keeping summaries up to date
without re-extracting everything from scratch.

When `sub-01/ses-01` gets new data,
only that row in `sourcedata+subjects.tsv` needs updating.
When `study-ds000001/` changes in a vault-level `studies.tsv`,
only that study's row needs refreshing.
When a single video is added to a YouTube channel,
only that row in `videos.tsv` and the aggregated `channels.tsv` need updating.

This is a dependency tracking problem,
and git already solves it.

### Git as Dependency Tracker

Git knows exactly what changed between any two states.
The dependency mechanism is:

1. **Detect what changed**: `git diff --name-only` between the last extraction
   and the current state identifies which leaf directories have new or modified content
2. **Map changes to summary rows**: directory structure encodes the mapping --
   a change under `sub-01/ses-01/` maps to the `sub-01` + `ses-01` row
   in the per-subject summary
3. **Re-extract affected rows only**: run the extractor
   scoped to the changed paths
4. **Update summary tables**: merge new rows into existing TSV/Parquet,
   then propagate upward to higher-level aggregations
5. **Commit the update**: `datalad run` wraps the extraction,
   recording provenance (which inputs triggered which summary update)

Because the extraction is wrapped in `datalad run`,
the whole process is **idempotent**:
`git reset --hard` to any prior state
and re-running the extraction pipeline
will regenerate exactly the correct summaries.
No external dependency database is needed --
git *is* the dependency tracker.

### Example: Incremental BIDS Summary Update

```bash
# What changed since last extraction?
git diff --name-only HEAD~1 -- sub-*/ses-*/

# Output: sub-01/ses-02/func/sub-01_ses-02_task-rest_bold.nii.gz
# → only sub-01/ses-02 needs re-extraction

# Re-extract that row
datalad run -m "Update sourcedata+subjects.tsv for sub-01/ses-02" \
    --input sub-01/ses-02/ \
    --output sourcedata+subjects.tsv \
    python code/extract_subject_summary.py --subject sub-01 --session ses-02
```

The `--input` and `--output` declarations
make the dependency explicit in the provenance record.
`datalad rerun` can replay this extraction later
if the extraction script itself is updated.

### Cascading Dependencies

Changes propagate upward through the summary hierarchy:

```
sub-01/ses-02/ changed
  → update row in sourcedata+subjects.tsv         (per-subject summary)
  → update row in sourcedata+datasets.tsv          (per-dataset summary, if in a superdataset)
  → update row in studies.tsv                       (vault-level overview)
```

The same cascade applies to derivatives:
if `sub-01/ses-02` has new raw data,
existing derivatives for that subject/session may need recomputation.
The dependency is the same:
git knows what changed, the pipeline knows what depends on it.

This connects directly to the
[BIDS-flux]({{< ref "automation-and-pipelines#branch-based-workflow-orchestration-bids-flux" >}})
branching model:
a new or updated subject/session arrives on a feature branch;
merging it triggers both metadata re-extraction
and derivative reprocessing
for exactly the affected records.

## Building on datalad-metalad

[datalad-metalad](https://github.com/datalad/datalad-metalad)
provides the extraction framework for this:
pluggable **extractors** that run against datasets and files,
producing structured metadata records
stored in git, aggregated up superdataset hierarchies,
and queried via `meta-dump`.
The [DataLad Registry](https://registry.datalad.org/)
(23,443 datasets, ~2 PB of annexed content)
is built on metalad extractors running at scale.

### Metalad's Extraction Pipeline

| Command | Purpose |
|---------|---------|
| `meta-extract` | Run an extractor against a dataset or file |
| `meta-add` | Store metadata records in the dataset's git repo |
| `meta-aggregate` | Consolidate metadata from subdatasets upward |
| `meta-dump` | Query and filter stored metadata |
| `meta-conduct` | Orchestrate multi-stage extraction pipelines |

### Existing Extractors

| Extractor | Scope | What it captures |
|-----------|-------|-----------------|
| `metalad_core` | dataset + file | Dataset ID, version, contributors, dates, `contentbytesize` (total and per-file), distributions (remote URLs, annex UUIDs) |
| `metalad_annex` | file | git-annex metadata fields (including `distribution-restrictions`, custom key-value pairs) |
| `metalad_runprov` | dataset | [PROV-DM](https://www.w3.org/TR/prov-dm/) records from `datalad run` commits: activities, generated entities, agent associations |
| `bids_dataset` | dataset | BIDS entities present (subjects, sessions, tasks), variable names from TSV files, `dataset_description.json` fields |
| `nifti1` | file | NIfTI header: voxel dimensions, data type, affine, TR, image shape |
| `dicom` | file | DICOM tags: patient, study, series, acquisition parameters |
| `genericjson_dataset/file` | both | Arbitrary JSON metadata from sidecar files |
| `external_dataset/file` | both | Delegate to an external process -- the general extension mechanism |

The `metalad_core` extractor already captures per-file `contentbytesize`
and dataset-level totals --
the raw material for summary tables.
The `nifti1` and `dicom` extractors already read
acquisition parameters from imaging files.
What's missing is the **summarization step**
that compacts per-file metadata into per-subject/per-record rows
and exports them as tabular files.

### What Needs Development

**1. Per-record summary extractors.**
The existing `bids_dataset` extractor captures which entities exist
but does not compute per-subject operational profiles
(file counts by modality, total sizes, durations, voxel counts).
A new extractor (or enhancement of the existing one)
would walk the dataset layout
and produce the per-record summaries
that `sourcedata+subjects.tsv` demonstrates.

The same pattern for other artifact types:
per-channel summaries for YouTube archives,
per-workspace summaries for Slack exports,
per-collection summaries for citations.
Each is implementable as a standalone script
invoked via metalad's `external_dataset` mechanism.

**2. Tabular export.**
Metalad stores metadata as JSON-LD,
which is semantically rich
but not directly usable as the TSV/Parquet summary tables
that operators, dashboards, and query tools need.
A tabular export step --
either a `meta-conduct` processor
or a `meta-dump --format=tsv` output mode --
would flatten extracted metadata
into the columnar format needed for consumption.

**3. Incremental extraction support.**
Metalad currently extracts against a full dataset or file.
For the row-level dependency tracking described above,
the extraction needs to accept a scope
(e.g., "only re-extract for paths matching `sub-01/ses-02/*`")
and merge results into existing summary tables
rather than regenerating from scratch.

**4. Aggregation to vault level.**
Metalad's `meta-aggregate` consolidates metadata
from subdatasets upward through the superdataset hierarchy.
This maps to the cascading dependency pattern:
per-subject summaries aggregate to per-dataset profiles,
which aggregate to a vault-level overview.
The aggregation path needs to support
the same incremental update logic --
when one subdataset's metadata changes,
only that subdataset's contribution to the parent needs updating.

### Alignment with metalad

What fits well:
- The extractor plugin model is extensible --
  new extractors inherit from `MetadataExtractor`
  or run as external scripts
- `meta-conduct` supports multi-stage pipelines
  (extract → transform → store)
- Storage in git means extraction results
  are versioned alongside the data
- JSON-LD output with PROV-DM vocabulary
  is compatible with the [DataLad concepts vocabulary](https://concepts.datalad.org/)

What needs work:
- Incremental/scoped extraction (row-level granularity)
- Tabular export path (JSON-LD → TSV/Parquet)
- Integration with git-based dependency detection
  (using `git diff` to scope what needs re-extraction)
- Testing at vault scale
  (hundreds of subdatasets, heterogeneous artifact types)

### Execution Telemetry and the Experience Ledger

Two of metalad's extractors serve the
[Experience Ledger]({{< ref "experience-ledger" >}})
rather than data knowledge:

- `metalad_runprov` extracts PROV-DM records
  from `datalad run` commits --
  the provenance layer of operational knowledge
- A new **execution telemetry extractor**
  would read con/duct `.duct/` JSON Lines logs
  and produce structured metadata
  (peak RSS, CPU, wall time, exit code)
  linked to the `datalad run` commit

These extractors produce operational knowledge
(specific to the processing system),
not data knowledge (intrinsic to the data).
The metalad framework can host both,
but the outputs feed different consumers:
data summaries feed dashboards and query tools;
execution telemetry feeds the experience ledger
and its failure pattern analysis.

## Relation to Derivatives Recomputation

The dependency tracking mechanism for metadata extraction
is the same one needed for **derivative recomputation**.

If `sub-01/ses-02` gets new raw data:
- The metadata extraction pipeline updates that subject's row
  in the summary table
- The derivative pipeline checks whether existing derivatives
  (fMRIPrep outputs, MRIQC reports) are still valid
  for that subject/session
- If not, it triggers reprocessing --
  but only for the affected records, not the entire dataset

Both are triggered by the same signal (git diff showing what changed),
follow the same pattern (scope to affected records, rerun, commit),
and benefit from the same idempotency guarantee
(`git reset --hard` + `datalad rerun`).

The [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) page
describes the execution primitives (`datalad run`, `con/duct`)
and orchestration (BIDS-flux, Forgejo Actions).
This page describes the **dependency logic**
that determines *what* needs re-execution
and *at what granularity*.

## Open Questions

- **metalad revival scope** --
  how much of metalad's current codebase is reusable as-is
  vs. needing modernization?
  Last released January 2024 with 141 open issues --
  is the extraction pipeline stable enough to build on,
  or does the core need work first?
- **Tabular vs. JSON-LD** --
  operators and agents need flat tables;
  metalad stores rich graphs.
  Is the right answer a tabular export processor in `meta-conduct`,
  a separate `meta-dump --format=tsv` output mode,
  or tabular files generated alongside JSON-LD during extraction?
- **Granularity model** --
  metalad supports file-level and dataset-level extraction.
  Per-subject/per-record summaries are an intermediate level
  that doesn't cleanly map to either.
  How to represent this in the extractor API?
- **Schema alignment** --
  can metalad's JSON-LD output be aligned with
  the [DataLad concepts vocabulary](https://concepts.datalad.org/)
  so that registry, catalog, and extraction results
  all speak the same schema?
- **Cross-vault metadata sharing** --
  if two labs extract the same metadata from similar datasets,
  can they share summary tables
  (without sharing the data itself)
  to pool knowledge about dataset characteristics?

## See Also

- [Data-Visualization Separation]({{< ref "data-visualization-separation" >}}) --
  the presentation side of hierarchical summaries
- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) --
  the execution primitives and orchestration layer
- [Experience Ledger]({{< ref "experience-ledger" >}}) --
  operational knowledge that consumes data characteristics
- [Vault Organization]({{< ref "vault-organization" >}}) --
  directory layout conventions that enable the extraction pattern
- [datalad-metalad](https://github.com/datalad/datalad-metalad) --
  the extraction framework
- [DataLad Registry](https://registry.datalad.org/) --
  metalad extractors running at scale
- [DataLad concepts vocabulary](https://concepts.datalad.org/) --
  the metadata schema for alignment
