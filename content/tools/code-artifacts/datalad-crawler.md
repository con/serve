---
title: "datalad-crawler"
date: 2026-02-12
description: "DataLad extension for crawling and tracking web resources through configurable pipelines"
summary: "A DataLad extension that provides pipeline-based web crawling for systematically tracking and archiving web resources into DataLad datasets."
categories: ["Code Artifacts"]
tags: ["CON", "datalad", "crawler", "web", "pipeline", "archival"]
media_types: ["web"]
integrations: ["native-datalad"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/datalad/datalad-crawler"
  homepage: "https://docs.datalad.org/projects/crawler/"
  issues: "https://github.com/datalad/datalad-crawler/issues"
  docs: "https://docs.datalad.org/projects/crawler/"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "datasets.datalad.org"
      url: "https://datasets.datalad.org/"
---

## Overview

datalad-crawler is a DataLad extension that provides pipeline-based web crawling
capabilities for systematically tracking and archiving web resources.  It was
originally developed to automate the creation and maintenance of DataLad datasets
from web-hosted data collections -- for example, tracking new releases of
datasets published on scientific data portals.

Unlike general-purpose web crawlers (HTTrack, wget), datalad-crawler is designed
around the concept of **pipelines** -- configurable chains of processing nodes
that fetch, filter, transform, and commit web content into DataLad datasets.
This makes it particularly powerful for structured, repeatable ingestion of
web resources.

## Key Features

- **Pipeline architecture** -- crawling workflows are defined as pipelines of
  composable nodes (fetchers, extractors, transformers, committers).  Pipelines
  can be configured in code or via configuration files.
- **DataLad-native** -- directly creates and updates DataLad datasets.  Downloaded
  files are tracked by git-annex with full provenance (URL, timestamp, checksums).
- **Incremental crawling** -- tracks what has been crawled and only fetches new
  or changed content on subsequent runs.
- **URL tracking** -- registers download URLs with git-annex so content can be
  re-obtained from the original source (`git annex get`).
- **Built-in nodes** -- includes nodes for common tasks: HTTP fetching, HTML
  parsing, S3 bucket listing, tarball extraction, and more.
- **Customizable** -- write custom pipeline nodes in Python for domain-specific
  crawling logic.

## Pipeline Example

A simple pipeline that crawls a web page for links to data files:

```python
from datalad_crawler.pipelines import pipeline

def my_pipeline():
    return [
        crawl_url("https://example.com/data/"),
        a_href_match(r".*\.csv$"),     # extract CSV links
        download,                       # fetch each file
        annex,                          # add to git-annex
    ]
```

## Basic Usage

```bash
# Install the extension
pip install datalad-crawler

# Create a new dataset and configure a crawler
datalad create my-archive
cd my-archive
datalad crawl-init --template simple \
    --save url="https://example.com/data/"

# Run the crawler
datalad crawl

# Re-run later to pick up new content
datalad crawl
```

## Use Cases in con/serve

datalad-crawler bridges the gap between "Code Artifacts" and "Web" categories.
Within the con/serve ecosystem, it is especially useful for:

- **Tracking web-hosted datasets** -- monitor a data portal and automatically
  ingest new releases into a DataLad dataset.
- **Archiving structured web content** -- crawl documentation sites, API
  references, or changelog pages into version-controlled archives.
- **Building dataset collections** -- aggregate files from multiple web sources
  into a single, organized dataset with provenance.
- **Periodic monitoring** -- set up cron jobs or CI pipelines to re-crawl
  sources and detect changes.

## git-annex / DataLad Integration

**Integration level: native-datalad.**

datalad-crawler is a first-class DataLad extension.  It is the most deeply
integrated web ingestion tool in the con/serve catalog:

- **Direct dataset creation** -- crawled content is committed directly into
  DataLad datasets with proper provenance metadata.
- **git-annex URL tracking** -- every downloaded file has its source URL
  registered with git-annex, enabling `git annex get` to re-download
  content from the original source.
- **Incremental updates** -- the crawler maintains state so that re-running
  `datalad crawl` only fetches new or changed content.
- **Full provenance** -- each crawl run creates a DataLad commit recording
  what was fetched, when, and from where.

This native integration means there is no manual import step -- the crawl
output is immediately a well-formed DataLad dataset.

## AI Readiness

**Level: ai-partial.**

The AI readiness of datalad-crawler output depends entirely on what content
is being crawled:

- **Structured text (CSV, JSON, markdown)** -- directly consumable by LLMs.
  The provenance metadata (URLs, timestamps) adds useful context.
- **HTML pages** -- require extraction/conversion to be useful for AI
  processing, though the raw HTML is preserved.
- **Binary files (PDFs, images, archives)** -- require format-specific
  processing (PDF extraction, OCR, etc.) before AI consumption.
- **Metadata** -- git-annex metadata and DataLad provenance records are
  structured and ai-ready regardless of content type.

The tool itself does not determine AI readiness -- it is a transport and
tracking mechanism.  The readiness depends on the nature of the crawled
resources.
