---
title: "datalad-container"
date: 2026-02-12
description: "DataLad extension for managing and executing computational containers alongside datasets"
summary: "Integrates Docker and Singularity/Apptainer container images into DataLad datasets, enabling reproducible computational workflows where both data and execution environments are version-controlled."
categories: ["Code Artifacts"]
tags: ["CON-ecosystem", "datalad", "containers", "singularity", "apptainer", "docker", "reproducibility"]
media_types: ["containers"]
integrations: ["native-datalad"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/datalad/datalad-container"
  homepage: "https://github.com/datalad/datalad-container"
  issues: "https://github.com/datalad/datalad-container/issues"
  docs: "https://docs.datalad.org/projects/container/"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "ReproNim containers collection"
      url: "https://github.com/ReproNim/containers"
---

## Overview

[datalad-container](https://github.com/datalad/datalad-container) is a DataLad extension that brings computational containers (Docker, Singularity/Apptainer) into the DataLad dataset management framework. It allows you to register container images as part of a dataset, version-control them alongside data, and execute analyses inside those containers with full provenance tracking.

The core insight is that reproducible science requires archiving not just data but also the **execution environment**. A neuroimaging analysis that worked in 2024 may not work in 2027 if the software versions have changed. By storing container images in git-annex alongside the data they process, datalad-container ensures the complete computational context is preserved.

## Key Features

- **Container registration** -- `datalad containers-add` registers a container image (Docker, Singularity/Apptainer) in a dataset
- **Version-controlled images** -- container images are stored in git-annex (content-addressed, deduplicated)
- **Provenance-tracked execution** -- `datalad containers-run` executes commands inside containers and records the run in git history
- **Multiple container support** -- a dataset can have multiple registered containers for different analysis stages
- **Image discovery** -- `datalad containers-list` shows available containers in a dataset

## Installation

```bash
pip install datalad-container
```

## Usage

```bash
# Register a Singularity image in your dataset
datalad containers-add fmriprep \
    --url https://hub.datalad.org/repronim/containers/src/branch/master/images/bids/bids-fmriprep--24.1.1.sing

# List registered containers
datalad containers-list

# Run an analysis inside the container (with provenance)
datalad containers-run -n fmriprep \
    --input data/sub-01 \
    --output results/sub-01 \
    '{img} data results participant --participant-label 01'
```

The `containers-run` command combines `datalad run` provenance tracking with container execution -- the git commit records which container was used, what inputs were consumed, and what outputs were produced.

## git-annex / DataLad Integration

**Integration level: native-datalad.**

Container images are stored as git-annex files within the dataset. This means:

- Images are content-addressed and deduplicated across datasets
- `datalad get` fetches container images on demand
- `datalad push` replicates images to siblings alongside data
- Container metadata (name, image path, call format) is stored in `.datalad/config`

## ReproNim Containers Collection

The primary example of datalad-container in action is [ReproNim/containers](https://github.com/ReproNim/containers) -- a DataLad dataset that provides a curated collection of Singularity container images for neuroimaging analysis. It includes containerized versions of:

- FSL, FreeSurfer, ANTs, AFNI
- BIDS Apps (fMRIPrep, MRIQC, etc.)
- Connectome Workbench, MRtrix3
- And many more

While ReproNim/containers has its own tooling for building and managing the collection, the underlying mechanism for registering and tracking images is datalad-container.

## AI Readiness

**Level: ai-partial.**

Container metadata (names, URLs, call formats) is structured and AI-readable. The container images themselves are opaque binaries, but the provenance records from `containers-run` are structured git commits that AI systems can parse to understand computational workflows.

## See Also

- [datalad-crawler]({{< ref "datalad-crawler" >}}) -- another DataLad extension for web resource tracking
- [con/tinuous]({{< ref "tinuous" >}}) -- archives CI build artifacts (complementary: tinuous captures build logs, datalad-container captures build environments)
