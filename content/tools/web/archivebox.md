---
title: "ArchiveBox"
date: 2026-02-12
description: "Self-hosted web archiving solution that saves pages in multiple formats including HTML, PDF, screenshots, and WARC"
summary: "A self-hosted internet archiving tool that takes URLs and saves them in multiple formats -- HTML, PDF, screenshot, WARC, media files -- for long-term preservation."
categories: ["Web"]
tags: ["web", "archiving", "self-hosted", "html", "pdf", "screenshots"]
media_types: ["web"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/ArchiveBox/ArchiveBox"
  homepage: "https://archivebox.io"
  issues: "https://github.com/ArchiveBox/ArchiveBox/issues"
  docs: "https://docs.archivebox.io"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "ArchiveBox Demo"
      url: "https://demo.archivebox.io/public/"
---

## Overview

ArchiveBox is a self-hosted web archiving tool that takes a list of URLs and
saves snapshots of each page in multiple formats simultaneously.  For every URL,
it can produce an HTML copy, a PDF rendering, a full-page screenshot, a WARC
archive, extracted media files, and a git-tracked history of changes.

Unlike browser extensions that save a single page at a time, ArchiveBox is
designed for bulk archiving -- it can ingest URLs from bookmarks exports,
browser history, RSS feeds, Pocket, Pinboard, or plain text lists.  It runs
as a local server with a web UI, CLI, and REST API.

## Key Features

- **Multiple output formats** -- for each URL, ArchiveBox can save:
  - Static HTML (wget mirror)
  - Single-file HTML (via SingleFile)
  - PDF rendering (via headless Chromium)
  - Full-page screenshot (PNG)
  - WARC archive (for replay with tools like ReplayWeb.page)
  - Extracted audio/video/images
  - Git history of page changes over time
  - Plain text extraction
  - DOM dump
- **Bulk import** -- accepts URLs from browser bookmarks (Chrome, Firefox),
  Pocket, Pinboard, RSS/Atom feeds, browser history databases, or plain
  text files.
- **Web UI and API** -- Django-based web interface for browsing archives,
  searching content, and managing snapshots.  REST API for programmatic access.
- **Scheduling** -- built-in scheduler for periodic re-archiving of URLs.
- **Full-text search** -- search across archived page content using Sonic
  or Ripgrep backends.
- **Self-hosted** -- runs on your own hardware; no third-party dependencies
  for archiving.  Docker or bare-metal installation.
- **Deduplication** -- detects and avoids re-archiving identical content.

## Basic Usage

```bash
# Install via pip or Docker
pip install archivebox

# Initialize an archive
mkdir ~/web-archive && cd ~/web-archive
archivebox init

# Add URLs
archivebox add "https://example.com/important-page"

# Import from bookmarks
archivebox add < bookmarks.html

# Import from a text file of URLs
archivebox add < urls.txt

# Start the web UI
archivebox server 0.0.0.0:8000
```

## Output Structure

ArchiveBox organizes its output by URL hash:

```
archive/
  1707123456.789/          # timestamp-based snapshot ID
    index.json             # metadata (URL, title, timestamps, status)
    singlefile.html        # self-contained HTML
    output.pdf             # PDF rendering
    screenshot.png         # full-page screenshot
    warc/                  # WARC archive
    media/                 # extracted media files
    git/                   # git-tracked page history
    readability/           # extracted article text
```

## git-annex / DataLad Integration

**Integration level: external.**

ArchiveBox manages its own storage and does not directly integrate with
git-annex or DataLad.  However, its output directory can be imported into
a DataLad dataset for version-controlled, distributed archival.

### Importing ArchiveBox Output into git-annex

```bash
# Create a DataLad dataset for web archives
datalad create web-archive
cd web-archive

# Configure git-annex to handle ArchiveBox output appropriately
# Large files (PDFs, screenshots, WARCs, media) go to annex
# Small files (index.json, readability text) go to git
cat >> .gitattributes << 'EOF'
*.pdf annex.largefiles=anything
*.png annex.largefiles=anything
*.warc annex.largefiles=anything
*.warc.gz annex.largefiles=anything
*.mp4 annex.largefiles=anything
*.mp3 annex.largefiles=anything
singlefile.html annex.largefiles=anything
index.json annex.largefiles=nothing
EOF

# Copy ArchiveBox output into the dataset
cp -r ~/web-archive/archive/ ./archive/

# Save with DataLad
datalad save -m "Import ArchiveBox snapshots"
```

### Periodic Archival Workflow

```bash
# Run ArchiveBox to update archives
archivebox add < new-urls.txt

# Sync changes into the DataLad dataset
rsync -av ~/web-archive/archive/ ./archive/
datalad save -m "Update web archive $(date +%Y-%m-%d)"
```

For a more automated approach, wrap the archiving step with `datalad run`
to record the full provenance of each archival operation.

## AI Readiness

**Level: ai-partial.**

ArchiveBox produces a mix of AI-friendly and AI-challenging outputs:

- **AI-ready components:**
  - `index.json` -- structured metadata (URL, title, timestamps, tags)
    is immediately parseable.
  - Readability-extracted text -- clean article text stripped of navigation
    and boilerplate.
  - Plain text extractions -- directly consumable by LLMs.

- **AI-partial components:**
  - `singlefile.html` -- contains the full page content but mixed with
    styling, scripts, and layout markup.  Useful but noisy for LLM
    consumption.
  - PDF renderings -- require PDF text extraction for LLM use.

- **AI-manual components:**
  - Screenshots (PNG) -- require OCR or vision models.
  - WARC archives -- require specialized tools to extract and replay content.
  - Media files -- require transcription for audio/video.

The readability extraction and plain text outputs are the most valuable
for AI workflows.  For building a searchable knowledge base from archived
web pages, the text extractions plus `index.json` metadata provide a solid
foundation for RAG (retrieval-augmented generation) pipelines.
