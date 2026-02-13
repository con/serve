---
title: "HTTrack"
date: 2026-02-12
description: "Website copier and mirroring tool for creating offline browsable copies of entire websites"
summary: "A mature, well-established website mirroring tool that creates offline-browsable copies of entire websites, preserving directory structure and link integrity."
categories: ["Web"]
tags: ["mirror", "website", "copier", "offline", "html"]
media_types: ["web"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/xroche/httrack"
  homepage: "https://www.httrack.com"
  issues: "https://github.com/xroche/httrack/issues"
  language: "C"
  license: "GPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

HTTrack is a long-established, free utility for downloading entire websites from
the internet to a local directory, building recursively all directories, getting
HTML, images, and other files from the server to your computer.  The result is a
mirror of the original site that can be browsed offline with a standard web
browser, with all internal links rewritten to work locally.

First released in 1998, HTTrack is one of the most mature website mirroring tools
available.  It handles complex sites with cookies, forms, redirects, and
authentication.  While it does not execute JavaScript (unlike Browsertrix), it is
fast, reliable, and produces clean directory structures that map directly to the
original site's URL hierarchy.

## Key Features

- **Full site mirroring** -- recursively downloads an entire website, preserving
  directory structure and file organization.
- **Link rewriting** -- rewrites internal links in downloaded HTML to work
  correctly in the local copy.  The mirror is immediately browsable offline.
- **Resumable downloads** -- interrupted mirrors can be resumed without
  re-downloading completed files.
- **Update mode** -- re-run HTTrack on an existing mirror to download only
  new or changed files.
- **Configurable scope** -- control crawl depth, file size limits, URL
  inclusion/exclusion patterns, and allowed file types.
- **Authentication support** -- handles cookies, HTTP authentication, and
  form-based login.
- **Bandwidth control** -- configurable connection limits, download rate
  limits, and retry settings.
- **GUI and CLI** -- graphical interface (WinHTTrack) on Windows, command-line
  interface on all platforms.
- **Proxy support** -- works through HTTP/SOCKS proxies.

## Basic Usage

```bash
# Mirror a website
httrack "https://docs.example.com" \
    -O "./mirrors/docs-example" \
    --depth=5 \
    --ext-depth=0

# Update an existing mirror (only download changes)
httrack --update -O "./mirrors/docs-example"

# Mirror with restrictions
httrack "https://example.com" \
    -O "./mirrors/example" \
    --max-size=10000000 \        # skip files > 10MB
    --depth=3 \                  # limit crawl depth
    -*.zip -*.tar.gz             # exclude archives
```

## Output Structure

HTTrack produces a directory tree that mirrors the site's URL structure:

```
mirrors/docs-example/
  docs.example.com/
    index.html
    guide/
      getting-started.html
      advanced.html
    api/
      reference.html
    images/
      logo.png
      diagram.svg
    css/
      style.css
  hts-cache/                    # HTTrack metadata (crawl state)
  hts-log.txt                   # crawl log
```

## Comparison with Other Web Archival Tools

| Feature | HTTrack | SingleFile | ArchiveBox | Browsertrix |
|---|---|---|---|---|
| JavaScript rendering | No | Yes (browser) | Yes (Chromium) | Yes (Chromium) |
| Output format | Directory tree | Single HTML | Multiple formats | WARC |
| Offline browsing | Native | Native | Via web UI | Via replay tools |
| Incremental updates | Yes | No | Yes | Yes |
| Batch/automated | CLI | CLI available | CLI + API | Docker + API |
| Best for | Static sites, docs | Individual pages | Mixed archiving | JS-heavy sites, SPAs |

HTTrack is the best choice for mirroring static or server-rendered sites where
you want a clean, browsable directory structure.  For JavaScript-heavy modern
sites, consider Browsertrix or ArchiveBox instead.

## git-annex / DataLad Integration

**Integration level: external.**

HTTrack produces a standard directory tree of files that can be imported
directly into git-annex.  The output maps cleanly to a filesystem hierarchy.

### Importing HTTrack Mirrors into a DataLad Dataset

```bash
# Create a dataset for website mirrors
datalad create site-mirrors
cd site-mirrors

# Configure git-annex for web content
cat >> .gitattributes << 'EOF'
*.html annex.largefiles=nothing
*.css annex.largefiles=nothing
*.js annex.largefiles=nothing
*.png annex.largefiles=anything
*.jpg annex.largefiles=anything
*.gif annex.largefiles=anything
*.svg annex.largefiles=nothing
*.pdf annex.largefiles=anything
hts-cache/** annex.largefiles=nothing
EOF

# Mirror a site
httrack "https://docs.example.com" -O "./docs-example" --depth=5

# Save with DataLad
datalad save -m "Mirror docs.example.com via HTTrack"
```

### Periodic Mirror Updates with Provenance

```bash
datalad run -m "Update mirror of docs.example.com" \
    --output "docs-example/" \
    httrack --update -O "./docs-example"
```

HTTrack's update mode is particularly well-suited for `datalad run` because
it only modifies files that have changed on the source site, resulting in
clean, minimal diffs in the git history.

## AI Readiness

**Level: ai-partial.**

HTTrack mirrors contain the original HTML of web pages, which includes both
the content and the presentation markup:

- **HTML text content** -- the actual text of web pages is present and
  extractable.  For documentation sites, blog posts, and text-heavy pages,
  standard HTML-to-text extraction (BeautifulSoup, trafilatura, readability)
  produces clean, AI-consumable text.
- **Structure preserved** -- the directory hierarchy mirrors the site's URL
  structure, providing organizational context that aids navigation and
  understanding.
- **Boilerplate** -- navigation bars, footers, sidebars, and other repeated
  elements are present in every page.  Readability extraction can strip these.
- **No JavaScript content** -- dynamically loaded content is not captured.
  Pages that require JavaScript to display their main content will appear
  empty or incomplete.

For AI workflows, HTTrack mirrors of documentation sites and static content
are particularly valuable.  The directory structure provides natural
organization, and the HTML content can be bulk-extracted into a text corpus
for indexing and RAG pipelines.
