---
title: "Browsertrix"
date: 2026-02-12
description: "Headless browser-based web crawler for creating high-fidelity WARC archives of websites"
summary: "A cloud-native, headless browser-based web crawler that creates high-fidelity WARC archives, capturing JavaScript-rendered content that traditional crawlers miss."
categories: ["Web"]
tags: ["crawler", "headless", "warc", "web", "archiving"]
media_types: ["web"]
integrations: ["external"]
ai_readiness: ["ai-manual"]
params:
  repo: "https://github.com/webrecorder/browsertrix"
  homepage: "https://browsertrix.com"
  issues: "https://github.com/webrecorder/browsertrix/issues"
  docs: "https://docs.browsertrix.com"
  language: "Python/JavaScript"
  license: "AGPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "Browsertrix Cloud"
      url: "https://app.browsertrix.com/"
    - title: "GovArchive.us"
      url: "https://govarchive.us/"
---

## Overview

Browsertrix (formerly Browsertrix Crawler) is a headless browser-based web
crawler developed by Webrecorder that creates high-fidelity WARC (Web ARChive)
files.  Unlike traditional crawlers (wget, HTTrack) that download raw HTML,
Browsertrix uses a real browser engine (Chromium) to render pages, executing
JavaScript, loading dynamic content, and capturing the page as a user would
actually see it.

This makes Browsertrix essential for archiving modern web applications, single-page
apps (SPAs), sites with lazy-loaded content, and pages that rely heavily on
client-side rendering.  The resulting WARC files can be replayed with pixel-perfect
fidelity using tools like ReplayWeb.page.

Browsertrix is available both as a standalone Docker-based crawler
(Browsertrix Crawler) and as a full cloud-hosted platform (Browsertrix Cloud)
with team collaboration, scheduling, and a web UI.

## Key Features

- **Browser-based crawling** -- uses headless Chromium to render pages exactly
  as a browser would, capturing JavaScript-rendered content, SPAs, and
  dynamically loaded elements.
- **WARC output** -- produces standard WARC files compatible with the broader
  web archiving ecosystem (Wayback Machine, ReplayWeb.page, pywb).
- **Configurable crawling** -- supports seed URLs, URL scoping (same-domain,
  same-path, custom regex), depth limits, and page limits.
- **Behavioral scripts** -- can execute custom behaviors during crawling
  (scroll to load lazy content, click through paginated content, dismiss
  cookie banners, log in to authenticated sites).
- **Parallel crawling** -- runs multiple browser instances concurrently for
  faster crawling of large sites.
- **Docker-native** -- runs as a Docker container, making deployment and
  scaling straightforward.
- **Cloud platform** -- Browsertrix Cloud adds team collaboration, crawl
  scheduling, quality review, and a web-based management interface.

## Basic Usage

### Browsertrix Crawler (Docker)

```bash
# Crawl a single site
docker run -v $PWD/crawls:/crawls \
    webrecorder/browsertrix-crawler crawl \
    --url "https://example.com" \
    --scopeType domain \
    --limit 100

# Output is in ./crawls/collections/
ls crawls/collections/*/
# archive/  indexes/  pages/
```

### Crawl Configuration

```yaml
# crawl-config.yaml
seeds:
  - url: "https://docs.example.com"
    scopeType: prefix
  - url: "https://blog.example.com"
    scopeType: domain

limit: 500
workers: 4
behaviors: autoscroll,autoplay
blockAds: true
```

```bash
docker run -v $PWD:/config -v $PWD/crawls:/crawls \
    webrecorder/browsertrix-crawler crawl \
    --config /config/crawl-config.yaml
```

## WARC Format

WARC (Web ARChive) is an ISO standard (ISO 28500) for storing web crawl data.
Each WARC file contains:

- **HTTP request/response pairs** -- the full network traffic of each page load.
- **Rendered page resources** -- HTML, CSS, JavaScript, images, fonts, and
  media files as served to the browser.
- **Metadata records** -- crawl timestamps, software version, and configuration.

WARC files can be replayed (viewed as the original website) using:
- [ReplayWeb.page](https://replayweb.page/) -- client-side WARC replay in the browser
- [pywb](https://github.com/webrecorder/pywb) -- Python-based Wayback Machine implementation
- [OpenWayback](https://github.com/iipc/openwayback) -- Java-based Wayback Machine

## git-annex / DataLad Integration

**Integration level: external.**

WARC files are binary archives that can be large (hundreds of MB to GB).
They are well-suited for git-annex content-addressed storage.

### Importing Browsertrix Output into a DataLad Dataset

```bash
# Create a dataset for web archives
datalad create web-warcs
cd web-warcs

# Configure annex for WARC files
echo "*.warc annex.largefiles=anything" >> .gitattributes
echo "*.warc.gz annex.largefiles=anything" >> .gitattributes
echo "*.cdx annex.largefiles=nothing" >> .gitattributes

# Run a crawl
docker run -v $PWD/crawls:/crawls \
    webrecorder/browsertrix-crawler crawl \
    --url "https://example.com" --scopeType domain

# Import crawl results
cp -r crawls/collections/*/archive/*.warc.gz ./warcs/
cp crawls/collections/*/indexes/*.cdx ./indexes/

# Save with provenance
datalad save -m "Archive example.com via Browsertrix"
```

### Automated Crawl with Provenance

```bash
datalad run -m "Crawl example.com with Browsertrix" \
    --output "warcs/" --output "indexes/" \
    'docker run -v $PWD/crawls:/crawls \
        webrecorder/browsertrix-crawler crawl \
        --url "https://example.com" --scopeType domain && \
    cp crawls/collections/*/archive/*.warc.gz warcs/ && \
    cp crawls/collections/*/indexes/*.cdx indexes/'
```

## AI Readiness

**Level: ai-manual.**

WARC files are binary archives that are not directly consumable by LLMs:

- **Replay required** -- WARC content must be replayed through a Wayback Machine
  implementation or extracted with specialized tools (warctools, warcio) before
  the text content is accessible.
- **Mixed content** -- a single WARC file contains HTML, CSS, JavaScript, images,
  and other resources interleaved.  Extracting just the text content requires
  parsing.
- **CDX indexes** -- the companion CDX (Capture inDeX) files are structured text
  that provides a machine-readable index of what is in the WARC.  These are
  ai-ready.

For AI workflows, the recommended pipeline is:

1. **Crawl** with Browsertrix to create WARC files (preserves full fidelity).
2. **Extract** text content using warcio or similar WARC processing libraries.
3. **Index** extracted text for search and RAG pipelines.
4. **Keep** the original WARCs in git-annex for long-term preservation and replay.

The WARC format is optimized for archival fidelity, not for AI consumption.
Think of it as the "master copy" from which AI-friendly derivatives can be
produced.
