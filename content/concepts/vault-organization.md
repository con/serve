---
title: "Vault Organization"
date: 2026-02-13
description: "Survey of directory organization approaches and how they inform the layout of a DataLad superdataset vault for heterogeneous research artifacts"
---

The con/serve vault is a DataLad superdataset containing archived digital research artifacts
of many types -- messaging histories, video recordings, code forge metadata,
AI coding sessions, CI logs, scholarly publications, web captures, cloud storage mirrors,
and more.
How should this heterogeneous collection be organized on disk?

This page surveys existing approaches to directory organization,
evaluates their fit for the vault use case,
and identifies the principles that should guide the layout.

## The Challenge

The vault's organizing problem is unusual.
Most directory layout standards assume a single artifact type
(neuroimaging sessions, data science notebooks, library holdings)
or a single organizational axis (by project, by date, by type).
The vault must handle:

- **Multiple artifact types** with fundamentally different internal structures
  (JSON message exports, video files, git repositories, tabular metadata)
- **Multiple sources** (Slack, Telegram, GitHub, YouTube, Zoom, Strava, ...)
  that each have their own identity model and access patterns
- **Multiple organizational axes** -- by source platform, by project/team,
  by time period, by access level
- **Nesting** -- each leaf may itself be a DataLad dataset
  with its own internal structure and history
- **Selective distribution** -- some content is public, some private,
  some embargoed (see [Privacy-Aware Distribution]({{< ref "conservation-to-external#privacy-aware-distribution" >}}))

## Survey of Existing Approaches

### Personal Knowledge Management

**[PARA Method](https://fortelabs.com/blog/para/)** (Tiago Forte) --
Four top-level buckets: **P**rojects (active, time-bound), **A**reas (ongoing responsibilities),
**R**esources (reference material), **A**rchives (inactive).
Designed for personal productivity.
The actionability axis (active vs. archived) is interesting
but the categories don't map to artifact types or provenance.
An institutional vault is almost entirely "Archive" in PARA terms.

**[Johnny Decimal](https://johnnydecimal.com/)** --
Max 10 "areas" (numbered `10-19`, `20-29`, ...), max 10 "categories" per area,
then individual items below.
The constraint is deliberately rigid -- "no more than ten things in any folder."
Could inspire numbering discipline,
but the 10x10=100 ceiling is too small for a multi-source vault,
and the system explicitly discourages deep nesting --
opposite of what DataLad subdatasets encourage.

### Research Project Templates

**[Cookiecutter Data Science](https://cookiecutter-data-science.drivendata.org/)** --
`data/` (external, interim, processed), `notebooks/`, `models/`, `reports/`, `src/`.
Good for a single analysis project.
Entirely code+data oriented --
no concept of communications, media, or heterogeneous artifact types.

**[Kedro](https://docs.kedro.org/en/stable/get_started/kedro_concepts.html)** --
A Python data engineering framework that adds two ideas on top of Cookiecutter-style layout:
a **numbered data-layer hierarchy**
(`data/01_raw/`, `02_intermediate/`, `03_primary/`, ... `08_reporting/`)
encoding pipeline stages in directory names,
and a **Data Catalog** (`conf/catalog.yml`)
that decouples logical dataset names from physical paths and formats.
The catalog abstraction is an interesting parallel to DataLad metadata --
both let you refer to data by name rather than path.
But Kedro is fundamentally a pipeline execution framework (a DAG of Python functions),
not a storage layout standard;
its directory structure serves pipeline stages, not archival organization.
For a detailed comparison of Kedro and DataLad/YODA approaches,
see the [DataLad Handbook draft chapter](https://github.com/datalad-handbook/book/pull/1282).

**[Harvard RDM](https://datamanagement.hms.harvard.edu/plan-design/directory-structure)** /
university guides --
Generic advice: organize by project, time, location, or file type.
Document your scheme. Keep depth to 3-4 levels.
Acknowledge heterogeneous data but don't provide a concrete taxonomy.

### Digital Preservation Standards

**[BagIt](https://datatracker.ietf.org/doc/html/rfc8493)** (Library of Congress, RFC 8493) --
A packaging format: `data/` payload + manifest + checksums.
A bag is a transfer unit, not an organizational hierarchy.
Relevant as a transport mechanism
(git-annex already does content-addressing better)
but provides no guidance for what goes *inside*.

**[OCFL](https://ocfl.io/1.1/spec/)** (Oxford Common File Layout) --
Content-addressed objects with versioned directories
(`v1/content/`, `v2/content/`, ...) and `inventory.json`.
Forward deltas, immutable versions.
Very close in spirit to git-annex
(content-addressed, versioned, self-describing).
But OCFL organizes *per object* --
the hierarchy above the object root is left to the repository.

**[RO-Crate](https://www.researchobject.org/ro-crate/)** (Research Object Crate) --
A directory with `ro-crate-metadata.json` (JSON-LD, schema.org-based)
describing all contained files.
Lightweight, composable, domain-agnostic.
Doesn't prescribe internal folder structure -- it describes whatever is there.
Could complement DataLad as a metadata layer
but doesn't solve the layout question.

### BIDS: More Than Neuroimaging

**[BIDS](https://bids-specification.readthedocs.io/en/stable/common-principles.html)**
(Brain Imaging Data Structure) --
Often dismissed as neuroimaging-specific, but its *general compositional principles*
are highly relevant:

**Entity-label system** --
BIDS encodes metadata directly in path components using key-value entities:
`sub-01/ses-retest/anat/sub-01_ses-retest_T1w.nii.gz`.
Each path segment carries structured meaning
without requiring a database or sidecar lookup.

**Hierarchical specificity** --
Information becomes progressively specific moving down the tree:
dataset → subject → session → data type → file.
Higher levels define context; lower levels define content.

**Metadata inheritance** --
Sidecar JSON files at higher levels apply to all files below,
with lower-level sidecars overriding specific fields.
Reduces duplication while allowing per-file precision.

**Separation of concerns** --
Raw data, source data (`sourcedata/`), and derived outputs (`derivatives/`)
live in separate directory trees, preventing accidental modification
and clarifying provenance.

**Study-level structure** --
A BIDS dataset is also a *project*:
`dataset_description.json` at the root, `participants.tsv` for the subject registry,
`code/`, `docs/`, `CHANGES`.
The [EMBER study template](https://github.com/emberarchive/study-template)
makes this explicit: `code/`, `derivatives/`, `docs/`, `logs/`, `scratch/`, `sourcedata/raw/`.

**[Nipoppy](https://nipoppy.readthedocs.io/)** extends BIDS
with a full study lifecycle layout:
`sourcedata/imaging/{pre_reorg,post_reorg}/` for DICOMs before and after reorganization,
`bids/` for converted data, `derivatives/<pipeline>/<version>/output/` for processing results,
`tabular/` for phenotypic data, `containers/` for Apptainer images,
`pipelines/` for per-stage configs, and `manifest.tsv` as the ground-truth participant registry.
It also maintains **processing status trackers** --
`curation_status.tsv` and `processing_status.tsv` --
that record per-subject/per-session pipeline completion
(see [Metadata Extraction]({{< ref "metadata-extraction#prior-art-nipoppy-trackers-and-neurobagel-digest" >}})).
Nipoppy does not use DataLad/git-annex underneath,
but its layout conventions and tracker outputs are
complementary components worth integrating.

These principles -- entity-labeled paths, metadata inheritance,
raw/derivative separation -- apply to *any* structured collection,
not just brain scans.

### Hive Partitioning

BIDS path structure is essentially
[hive partitioning](https://github.com/bids-standard/bids-2-devel/issues/92) --
the same pattern used by DuckDB, Apache Arrow, and Parquet datasets:

```
# Hive partitioning (DuckDB, Arrow)
orders/year=2021/month=01/data.parquet

# BIDS (current syntax)
sub-01/ses-retest/anat/sub-01_ses-retest_T1w.nii.gz

# BIDS (proposed = syntax, aligning with hive convention)
sub=01/ses=retest/anat/sub=01_ses=retest_T1w.nii.gz
```

When directory names encode `key=value` pairs,
any tool that understands hive partitioning --
DuckDB, Pandas, Polars, Arrow --
can query the directory tree directly as a dataset, without an index.
This is a powerful property for a vault:
the folder hierarchy *is* the queryable schema.

**[mykrok](https://github.com/mykrok/mykrok)** demonstrates this pattern
outside neuroimaging -- it organizes Strava activity backups
(GPS tracks, photos, metadata) using hive-partitioned paths:

```
data/
├── athletes.tsv
├── mykrok.html
└── athl=alice/
    ├── athlete.json
    ├── sessions.tsv
    └── ses=2024-03-15T08-30/
        ├── info.json
        ├── tracking.parquet
        └── photos/
```

Text files tracked by git, binary content by git-annex --
the same split the vault uses.
The `athl=` / `ses=` hierarchy is directly queryable
by DuckDB's `read_parquet('data/athl=*/ses=*/tracking.parquet', hive_partitioning=true)`.

### DataLad Native Nesting

DataLad's own [nesting model](https://handbook.datalad.org/en/latest/basics/101-106-nesting.html)
is the vault's foundational mechanism:
a superdataset tracks subdataset *state* (commit SHA),
not content.
Each subdataset has its own annex and history.
The YODA convention adds:
`inputs/` for consumed data,
`code/` for scripts,
and `outputs/` for results --
but that's per-analysis, not per-vault.

Nesting depth is unlimited,
and subdatasets can live on different servers,
making the superdataset a *curated catalog* pointing to distributed storage.

## Emerging Principles

From this survey, several principles emerge for the vault layout:

1. **Entity-labeled paths** (from BIDS / hive partitioning) --
   encode organizational metadata in directory names
   so the hierarchy is self-describing and queryable

2. **Shallow top, deep leaves** (from Johnny Decimal + DataLad nesting) --
   keep the top-level vault structure broad and flat (artifact categories),
   but allow each subdataset to have arbitrarily rich internal structure

3. **Separation of raw and derived** (from BIDS / Cookiecutter) --
   keep ingested raw artifacts separate from any processed/derived outputs

4. **Metadata at every level** (from BIDS / RO-Crate / OCFL) --
   each directory level should carry a description file
   (`dataset_description.json`, `.datalad/`, or equivalent)
   that makes it self-contained

5. **Distribution metadata alongside content** (from con/serve privacy model) --
   `distribution-restrictions` and provenance annotations
   travel with the data, enabling selective outbound distribution

6. **Queryable without a database** (from hive partitioning / mykrok) --
   directory structure doubles as a query schema for tools like DuckDB,
   eliminating the need for a separate catalog database

## See Also

- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- how data enters the vault
- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- how data leaves the vault
- [Domain Extensions]({{< ref "domain-extensions" >}}) -- domain-specific internal structures within subdatasets
