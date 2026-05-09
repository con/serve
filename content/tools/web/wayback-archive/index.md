---
title: "Wayback-Archive"
date: 2026-05-08
description: "Python tool that downloads and reconstructs websites from the Internet Archive's Wayback Machine for offline viewing"
summary: "Recovers a complete site from a Wayback Machine snapshot -- HTML, CSS, JS, images, fonts -- rewriting URLs and stripping Wayback artifacts so the result behaves like the original."
categories: ["Web"]
tags: ["web", "wayback-machine", "internet-archive", "recovery", "offline"]
media_types: ["web"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/GeiserX/Wayback-Archive"
  homepage: "https://github.com/GeiserX/Wayback-Archive"
  issues: "https://github.com/GeiserX/Wayback-Archive/issues"
  pypi: "https://pypi.org/project/wayback-archive/"
  language: "Python"
  license: "GPL-3.0"
  maturity: "active"
  last_verified: "2026-05"
---

## Overview

Wayback-Archive fills a niche the other tools in this section do not cover:
recovering a site that is no longer reachable on the live web but has been
captured by the [Internet Archive's Wayback Machine](https://web.archive.org/).
Given a `https://web.archive.org/web/<timestamp>/<original-url>` URL, it walks
the snapshot, downloads HTML/CSS/JS/images/fonts, falls back to nearby
timestamps for assets that 404, and rewrites links to relative paths so the
output is browsable offline.

General-purpose mirrors like `wget --mirror` or HTTrack do not understand
Wayback Machine URL structure (`/web/<timestamp>/...` prefixes,
`<id>im_/`, `<id>js_/` rewrites, embedded toolbar markup) and produce
output that is half-broken when pointed at archive.org. Wayback-Archive is
written specifically for that source.

## Key Features

- **Wayback-aware URL rewriting** -- strips `/web/<timestamp>/` prefixes and
  `_im`/`_js`/`_cs` resource-type suffixes, converting absolute Wayback URLs
  to relative paths that resolve in a local tree.
- **Timestamp fallback** -- when a referenced asset returns 404 at the requested
  snapshot, searches nearby timestamps in the Wayback CDX index and uses the
  closest available capture.
- **Asset recovery** -- downloads fonts (including Google Fonts, locally
  inlined to avoid CORS), background images referenced from CSS, resources
  pulled from `data-*` attributes, and assets discovered while parsing JS.
- **CDN fallback** -- if a critical library (e.g. jQuery) is missing from the
  archive, falls back to fetching it from a public CDN.
- **Cleanup** -- removes the Wayback toolbar, trackers, ads, and (optionally)
  external iframes and `tel:`/`mailto:` links; detects fonts that came back as
  HTML error pages and removes them from CSS.
- **Optional minification** -- HTML always, JS/CSS/images opt-in.
- **Configuration via env vars** -- `WAYBACK_URL`, `OUTPUT_DIR`, plus toggles
  for each cleanup/optimization step; `MAX_FILES` for quick smoke tests.

## Output

Wayback-Archive produces a static directory tree of the recovered site --
plain files, no database or container -- previewable with any HTTP server:

```bash
cd output && python3 -m http.server 8000
```

This makes the output a good fit for git-annex / DataLad: ordinary files,
content-addressable, with a clear distinction between large binary assets
(images, fonts) and small text (HTML, CSS, JS).

## Where It Fits

Most archival tools in this section are oriented toward *forward* preservation:
capturing a site that is currently live so you still have it tomorrow.
Wayback-Archive is *backward* recovery: restoring a site that is already gone
from the live web but is preserved -- imperfectly, distributed across many
timestamps -- in the Internet Archive.

Use it when:

- A project homepage, lab page, or supplementary site referenced from a paper
  has gone dark, and only Wayback snapshots remain.
- You want a self-contained, browsable copy of an archived site rather than
  navigating it via the Wayback Machine UI.
- You need to ingest a recovered site into a git-annex / DataLad repository
  for long-term preservation alongside other research artifacts.

It does not replace [ArchiveBox](../archivebox/), [Browsertrix](../browsertrix/),
[HTTrack](../httrack/), or [SingleFile](../singlefile/) for archiving live sites --
those produce higher-fidelity captures with provenance and (in the WARC case)
standards-compliant replay.

## Scope and Known Gaps

Wayback-Archive operates on **one snapshot per invocation**. `WAYBACK_URL`
is a fixed `/web/<timestamp>/<original-url>`; the downloader parses that
single timestamp at startup and stays there. There is no native mode for:

- enumerating *all* captures of a site from the Internet Archive's CDX
  Server API and iterating over them,
- accumulating multiple snapshots into one tree, or
- emitting per-snapshot artifacts to git.

The "timeframe fallback" inside the tool sounds related but is not: it
walks ±24 h around the requested timestamp only to recover *individual
assets that 404* within one snapshot, not to enumerate the site's history.

For a multi-snapshot history a wrapper around the CDX API is needed
(see below).

## git-annex / DataLad Integration

**Integration level: external.**

Wayback-Archive does not know about git-annex or git. It writes a
directory tree; you decide what to do with it. Two useful patterns:

**Single recovery.** Wrap a one-off run with `datalad run` so the output
and the recovery parameters are recorded together:

```bash
datalad run -m "Recover example.com from Wayback (2025-04-17 snapshot)" \
    --explicit \
    --output recovered/example.com/ \
    'WAYBACK_URL=https://web.archive.org/web/20250417203037/http://example.com/ \
     OUTPUT_DIR=recovered/example.com \
     python3 -m wayback_archive.cli'
```

Configure `.gitattributes` so binary assets (images, fonts, PDFs) go to annex
and text files (HTML, CSS, JS) stay in git -- the SingleFile and ArchiveBox
pages in this section show the same pattern. `datalad create -c text2git`
sets this up automatically.

**Full-history recovery (CDX-driven).** To preserve a site's evolution,
query the [CDX Server API](https://github.com/internetarchive/wayback/tree/master/wayback-cdx-server)
for the list of capture timestamps, then drive Wayback-Archive once per
timestamp into the same tree, committing each result. Output files are
written with `open(..., "wb")` -- they overwrite cleanly -- so the recipe
is wipe-tree, run, `datalad save`/`run`, repeat. Backdate the commit to
the capture time and `git log --date=iso` reads as a timeline of the
site.

A worked example wrapper -- [`wayback-to-datalad.sh`](wayback-to-datalad.sh)
-- ships with this page. It walks the CDX captures of a site, runs
Wayback-Archive once per timestamp under `datalad run`, applies a
per-snapshot wall-clock timeout (Wayback's per-request 15 s timeout does
not cover slow-trickle responses), retries the CDX query on transient
5xx, and rolls back any snapshot that returned no files so `git log` only
contains real captures. Used as:

```bash
SNAPSHOT_TIMEOUT=600 MAX_FILES_PER_SNAPSHOT=10 \
    ./wayback-to-datalad.sh neuro.debian.net ./wayback-neurodebian \
    timestamp:6              # monthly density; :4=yearly, :8=daily
```

Each successful snapshot becomes a `[DATALAD RUNCMD]` commit whose
message embeds the exact recovery command as JSON, so any single point
in the timeline is independently reproducible.

This is purely a wrapper-script pattern today: it would be a clean
upstream feature to expose `WAYBACK_URL_RANGE` / `WAYBACK_FROM` /
`WAYBACK_TO` / `WAYBACK_COLLAPSE` env vars and an internal CDX call.

## AI Readiness

**Level: ai-partial.**

The output is the recovered site's own HTML/CSS/JS, so AI-readiness is
inherited from whatever the original site was: text content is extractable
with readability/trafilatura, structure follows the original markup, and
embedded ads/navigation are preserved (modulo the optional tracker/ad
removal). For RAG-style use, run an HTML-to-text pass over the recovered
tree the same way you would for any other static site capture.
