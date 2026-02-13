---
title: "SingleFile"
date: 2026-02-12
description: "Browser extension and CLI tool to save complete web pages as single self-contained HTML files"
summary: "A browser extension (and CLI tool) that saves a complete web page -- including CSS, images, fonts, and iframes -- into a single, self-contained HTML file."
categories: ["Web"]
tags: ["browser", "extension", "html", "single-file", "web"]
media_types: ["web"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/gildas-lormeau/SingleFile"
  homepage: "https://github.com/gildas-lormeau/SingleFile"
  issues: "https://github.com/gildas-lormeau/SingleFile/issues"
  language: "JavaScript"
  license: "AGPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

SingleFile is a browser extension (available for Chrome, Firefox, Edge, and
Safari) and a companion CLI tool that saves a complete web page into a single
HTML file.  Unlike "Save As" which produces an HTML file plus a folder of
assets, SingleFile embeds everything -- CSS stylesheets, images, fonts, SVGs,
iframes, and canvas elements -- directly into the HTML using data URIs and
inline styles.

The result is a single `.html` file that faithfully reproduces the original
page appearance when opened in any browser, with no external dependencies.
This makes SingleFile output ideal for long-term archival: the file is
self-contained, portable, and requires only a web browser to view.

## Key Features

- **Complete page capture** -- embeds all resources (CSS, images, fonts, SVGs,
  favicons, canvas, iframes) into a single HTML file.
- **Faithful rendering** -- preserves the visual appearance of the page as seen
  in the browser, including dynamically loaded content and JavaScript-rendered
  elements.
- **Browser extension** -- one-click saving from Chrome, Firefox, Edge, or
  Safari.  Configurable via extension options.
- **CLI tool** -- `single-file` command-line interface for automated and batch
  archiving (uses headless Chromium).
- **Annotation support** -- optionally add highlights and notes to pages before
  saving.
- **Auto-save** -- can be configured to automatically save pages based on rules
  (URL patterns, time intervals).
- **Compact output** -- compresses embedded resources to minimize file size.
- **Metadata preservation** -- saves the original URL, page title, and save
  date in HTML meta tags and comments.

## Basic Usage

### Browser Extension

1. Install from the browser's extension store.
2. Navigate to a page you want to archive.
3. Click the SingleFile icon in the toolbar.
4. The page is saved as a single `.html` file in your downloads folder.

### CLI Tool

```bash
# Install the CLI
npm install -g single-file-cli

# Save a single page
single-file "https://example.com/important-page" \
    --output "example-page.html"

# Batch save from a list of URLs
while read url; do
    single-file "$url" --output "archive/$(echo $url | md5sum | cut -c1-8).html"
done < urls.txt
```

## git-annex / DataLad Integration

**Integration level: external.**

SingleFile produces standalone HTML files that can be directly added to
git-annex.  Because each file is self-contained (no external dependencies),
it is an ideal format for content-addressed storage.

### Adding SingleFile Output to a DataLad Dataset

```bash
# Create or use an existing dataset
datalad create web-pages
cd web-pages

# Configure large file handling (SingleFile HTML can be several MB)
echo "*.html annex.largefiles=largerthan=100kb" >> .gitattributes

# Save a page and add to the dataset
single-file "https://example.com/page" --output "pages/example-page.html"
datalad save -m "Archive example.com/page via SingleFile"
```

### Batch Archival with Provenance

```bash
datalad run -m "Archive pages from urls.txt via SingleFile" \
    --input urls.txt \
    --output "pages/" \
    'while read url; do
        slug=$(echo "$url" | sed "s|https\?://||;s|/|_|g")
        single-file "$url" --output "pages/${slug}.html"
    done < urls.txt'
```

### Integration with ArchiveBox

SingleFile is also used internally by ArchiveBox as one of its archiving
methods.  If you use ArchiveBox, SingleFile output is already included in
each snapshot.  For standalone use, SingleFile is lighter weight and produces
a single file per page rather than a directory structure.

## AI Readiness

**Level: ai-partial.**

SingleFile HTML files contain the full text content of the page, which is
extractable by LLMs, but the content is interleaved with base64-encoded
images, inline CSS, and HTML markup:

- **Text content** -- the actual article or page text is present in the HTML
  and can be extracted using standard HTML-to-text tools (BeautifulSoup,
  readability, trafilatura).  Once extracted, it is fully ai-ready.
- **Structure** -- HTML heading hierarchy, lists, and tables provide semantic
  structure that LLMs can interpret.
- **Noise** -- navigation elements, ads, footers, and boilerplate are preserved
  along with the main content.  A readability extraction step is recommended
  before feeding to LLMs.
- **Embedded binary data** -- images and fonts are base64-encoded inline.
  These increase file size significantly but are ignored by text-processing
  LLMs.

For AI workflows, the recommended pipeline is:
1. Archive with SingleFile (preserves full fidelity for human viewing).
2. Extract article text using a readability library (for AI consumption).
3. Store both the full HTML and extracted text in the dataset.
