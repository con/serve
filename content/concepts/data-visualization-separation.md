---
title: "Data-Visualization Separation"
date: 2026-02-13
description: "The principle of strictly separating collected data from the tools that visualize and navigate it, and the role of hierarchical summarization in making this practical"
---

Software engineering settled this decades ago:
the [Model-View-Controller](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) pattern
separates the data (Model) from its presentation (View)
and the logic that prepares one for the other (Controller).
The same principle applies -- and matters even more -- when archiving research artifacts.

**Data is the durable asset. Visualization is disposable.**

A well-structured archive can outlive any particular viewer, dashboard, or UI framework.
But a dataset welded to a specific application (a `.xlsx` with embedded charts,
a Notion workspace, a SaaS dashboard) is trapped:
the data dies with the tool.

The con/serve vault follows the MVC split rigorously:

| Role | In the vault | Examples |
|---|---|---|
| **Model** | Structured files in standard formats (TSV, JSON, Parquet) tracked by git/git-annex | `videos.tsv`, `metadata.json`, `tracking.parquet` |
| **View** | Lightweight, client-side frontends that read from those files | annextube's Svelte UI, mykrok's single-file HTML |
| **Controller** | Summarization pipelines that distill detail into navigable indices | `metadata.json` files &rarr; `videos.tsv` &rarr; `channels.tsv` |

## Hierarchical Summarization

Raw archived data is often too granular to navigate directly.
Thousands of individual `metadata.json` files are not a useful starting point.
The solution is **hierarchical summarization** --
building progressively coarser summaries that let you start with an overview
and drill into detail on demand.

This is itself a [Frozen Frontier]({{< ref "/_index.md#frozen-frontiers" >}}):
each summary level is a working surface
that frees you from the burden of the level below.

### annextube

[annextube]({{< ref "tools/media/annextube" >}}) archives YouTube channels
and builds a three-tier summary pyramid:

```
archive/
  channels.tsv                        # all channels at a glance
  {channel}/
    channel.json                      # per-channel stats + metadata
    videos/
      videos.tsv                      # all videos in this channel
      {year}/{month}/{video_id}/
        metadata.json                 # full detail for one video
        video.mkv                     # content (git-annex)
        captions.tsv                  # caption index
```

The Svelte frontend loads `channels.tsv` first,
then `videos.tsv` when you select a channel,
then `metadata.json` only when you drill into a specific video.
It runs entirely client-side -- no server, no database --
and works from `file://` or any static HTTP server.

### mykrok

[mykrok](https://github.com/mykrok/mykrok) archives Strava activities
with the same pattern (see also [Vault Organization]({{< ref "vault-organization" >}})
for its hive-partitioned directory layout):

```
data/
  athletes.tsv                        # all athletes
  athl=alice/
    athlete.json                      # per-athlete metadata
    sessions.tsv                      # all sessions for this athlete
    ses=2024-03-15T08-30/
      info.json                       # per-session detail
      tracking.parquet                # GPS/sensor data
```

A single self-contained `mykrok.html` file serves as the entire frontend.
The hive-partitioned naming (`athl=`, `ses=`) means the same directory tree
is directly queryable by DuckDB:

```sql
SELECT * FROM read_parquet('data/athl=*/ses=*/tracking.parquet',
                           hive_partitioning=true)
WHERE athl = 'alice' AND ses > '2024-01-01'
```

### The pattern

Both tools follow identical architecture:

1. **Collect** raw data into per-item directories (one video, one session)
2. **Summarize** upward into TSV indices at each grouping level
3. **Present** via a static frontend that loads summaries first, detail on demand
4. **Store** text in git, binaries in git-annex -- the viewer never needs to know

This mirrors how [BIDS](https://bids-specification.readthedocs.io/) organizes neuroimaging data:
common metadata and summary files live at higher directory levels
(`dataset_description.json`, `participants.tsv`)
while per-subject, per-session detail lives deeper in the tree.
The principle is the same regardless of artifact type.

## Use-Case-Appropriate Tooling

When data lives in standard formats rather than proprietary applications,
you are free to choose the best viewer for each situation.
The same `videos.tsv` or `sessions.tsv` can be opened in:

- **[VisiData](https://www.visidata.org/)** -- a terminal-based interactive multitool
  for tabular data. Fast, keyboard-driven, handles millions of rows.
  No need for heavyweight spreadsheet applications.
  Sticking to basic tabular formats (TSV, CSV) like
  [BIDS](https://bids-specification.readthedocs.io/) does
  naturally enables this kind of lightweight exploration --
  leading to use-case-specific customizations like
  [ABCD-visidata](https://github.com/ReproNim/ABCD-visidata)
  for navigating the ABCD neuroimaging dataset.

- **[Datasette](https://datasette.io/)** -- an "explore and publish" tool
  for SQLite databases. Load your TSVs into SQLite,
  and Datasette serves a searchable, faceted web interface
  plus a JSON API with a single command.
  Its `datasette publish` packages data + viewer into a Docker container
  for one-command deployment to cloud platforms.
  The philosophy is *data in a box*: the SQLite file is the durable artifact,
  the web UI is a generic, replaceable shell around it.

- **DuckDB** -- analytical SQL engine that reads TSV, Parquet,
  and hive-partitioned directory trees directly.
  No import step, no server, just `SELECT` against the files.

- **Pandas / Polars** -- for programmatic analysis in Python or Rust.

- **A custom Svelte/HTML frontend** -- for public-facing or project-specific views
  (as annextube and mykrok demonstrate).

- **[PhotoPrism]({{< ref "photoprism" >}}) / [Photoview]({{< ref "photoview" >}})** --
  self-hosted photo galleries that read from the filesystem.
  Point them at a git-annex working tree of photos
  and get a browsable web interface with thumbnails, maps,
  and (in PhotoPrism's case) AI-powered face recognition and classification.
  The photos are the durable asset in git-annex;
  the gallery is a replaceable visualization layer.

- **[copyparty]({{< ref "copyparty" >}})** -- a single-file Python file server
  whose built-in image gallery mode provides zero-setup photo album browsing
  over any directory tree, including git-annex working trees.

None of these tools need to understand how the data was collected.
They operate on the summarized, structured output --
the frozen frontier that the ingestion pipeline established.

## Contrast with Coupled Approaches

Many tools merge data and presentation into a single artifact:

- **Google Sheets / Excel** -- data, formulas, charts, and formatting
  are one inseparable blob. Collaboration requires the same tool.
  Export to CSV loses the visualizations; keep the `.xlsx` and you are locked in.

- **Jupyter notebooks** -- mix code, data, and rendered output.
  Useful for exploration, but the notebook *is* the visualization.
  Extracting the underlying data for a different viewer requires effort.

- **SaaS dashboards** (Grafana, Notion databases, Airtable) --
  data lives inside the platform. Export is an afterthought.
  When the service changes or shuts down, both data and visualization disappear.

The con/serve approach inverts this:
archive the data first, in standard formats, under version control.
Then attach whatever viewer suits the moment --
and replace it freely when something better comes along.

## Relation to Other Concepts

- **[Metadata Extraction and Dependencies]({{< ref "metadata-extraction" >}})** --
  the extraction pipelines and dependency tracking
  that keep the summary tables current as data evolves.
  This page describes how summaries are presented;
  that page describes how they are produced and updated.

- **[Frozen Frontiers]({{< ref "/_index.md#frozen-frontiers" >}})** --
  each summarization level is a frozen frontier:
  a working surface for the next stage
  that does not require loading everything below it.

- **[Vault Organization]({{< ref "vault-organization" >}})** --
  hive partitioning, BIDS layouts, and the directory conventions
  that make hierarchical summarization possible.

- **[Ingestion Patterns]({{< ref "ingestion-patterns" >}})** --
  the collection stage that produces the raw data
  the separation principle then structures and surfaces.
