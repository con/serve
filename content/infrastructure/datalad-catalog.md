---
title: "datalad-catalog"
date: 2026-02-12
description: "Generate user-friendly, browser-based data catalogs from structured metadata"
summary: "A DataLad extension that creates browsable Vue.js web catalogs from dataset metadata, with schema validation and support for arbitrary metadata sources."
categories: ["Infrastructure"]
tags: ["CON-ecosystem", "MIH", "datalad", "catalog", "metadata", "web", "vue"]
integrations: ["native-datalad"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/datalad/datalad-catalog"
  homepage: "https://github.com/datalad/datalad-catalog"
  issues: "https://github.com/datalad/datalad-catalog/issues"
  docs: "https://docs.datalad.org/projects/catalog/"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "SFB 1451 Research Data Catalog"
      url: "https://data.sfb1451.de"
    - title: "DataLad Catalog Demo"
      url: "https://datalad-catalog.netlify.app/"
    - title: "ABCD-J Data Catalog"
      url: "https://hub.psychoinformatics.de/abcd-j/data-catalog"
---

## Overview

[datalad-catalog](https://github.com/datalad/datalad-catalog) is a DataLad extension that generates user-friendly, browser-based data catalogs from structured metadata. It produces a static Vue.js web interface that can be hosted anywhere -- GitHub Pages, institutional servers, or any static file host.

The tool bridges the gap between machine-readable DataLad metadata and human-browsable discovery interfaces. Rather than requiring users to understand git-annex or DataLad commands to find datasets, they get a searchable web catalog with dataset descriptions, file trees, publications, and funding information.

## Key Features

- **Schema-validated metadata** -- incoming metadata is validated against a dedicated JSON Schema
- **Source-agnostic** -- accepts metadata from DataLad-metalad, BIDS, or any source conforming to the schema
- **Static output** -- generates a Vue.js single-page application with JSON metadata files, hostable anywhere
- **Incremental updates** -- add or remove metadata entries without rebuilding the entire catalog
- **Search and browse** -- full-text search, dataset tree navigation, subdataset exploration
- **Rich display** -- publications, funding, authors, file trees, dataset versions

## Installation and Usage

```bash
pip install datalad-catalog

# Create a new catalog
datalad catalog-create --catalog my-catalog

# Add metadata from a DataLad dataset
datalad catalog-add --catalog my-catalog --metadata extracted-metadata.jsonl

# Serve locally for preview
datalad catalog-serve --catalog my-catalog
```

## git-annex / DataLad Integration

**Integration level: native-datalad.**

datalad-catalog integrates with the DataLad metadata ecosystem:

```bash
# Extract metadata with datalad-metalad
datalad meta-extract -d my-dataset metalad_core > metadata.jsonl

# Add to catalog
datalad catalog-add --catalog my-catalog --metadata metadata.jsonl

# The catalog itself can be a DataLad dataset
datalad create my-catalog
datalad catalog-create --catalog my-catalog
datalad save -m "Initial catalog"
```

The catalog output directory can itself be tracked as a DataLad dataset, versioning the catalog alongside the data it describes.

## AI Readiness

**Level: ai-ready.**

The catalog's metadata is stored as structured JSON files, directly consumable by AI systems. The schema provides consistent field names and types across all datasets, making it straightforward for AI agents to query, filter, and summarize catalog contents.

## See Also

- [DataLad Hub]({{< ref "datalad-hub" >}}) -- hosting platform for DataLad datasets
- [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- self-hosted forge with git-annex support
- [datalad-registry](https://github.com/datalad/datalad-registry) -- auto-discovery and indexing service at [registry.datalad.org](https://registry.datalad.org)
