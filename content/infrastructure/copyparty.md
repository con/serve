---
title: "copyparty"
date: 2026-02-12
description: "Portable, self-contained file server with multi-protocol support, deduplication, and rich web UI"
summary: "A single-file Python file server supporting HTTP, WebDAV, SFTP, FTP, and TFTP with resumable uploads, content-based deduplication, media indexing, and a full-featured web interface. Useful as an ingestion front-end and quick file sharing tool within research infrastructure."
categories: ["Infrastructure"]
tags: ["file-server", "sharing", "webdav", "sftp", "ftp", "dedup", "self-hosted", "python"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/9001/copyparty"
  homepage: "https://github.com/9001/copyparty"
  issues: "https://github.com/9001/copyparty/issues"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

[copyparty](https://github.com/9001/copyparty) is a portable, self-contained file server that turns any machine into a multi-protocol file sharing hub. It ships as a single Python file (`copyparty-sfx.py`) or standalone executable with no mandatory dependencies beyond Python 3.3+. It supports HTTP(S), WebDAV, SFTP, FTP(S), and TFTP simultaneously, with resumable uploads, content-based deduplication, a media indexer, and a feature-rich web interface.

copyparty fills a niche that heavier solutions (Nextcloud, Seafile) often overshoot: **quick, low-ceremony file sharing** within a research group or across devices, without requiring a database, Docker orchestration, or account provisioning.

## Key Features

- **Multi-protocol** -- serves files over HTTP(S), WebDAV, SFTP, FTP(S), TFTP, and even SMB/CIFS from a single process
- **Resumable uploads** -- accelerated, multithreaded "up2k" uploads with no filesize limit and automatic resume on failure
- **Content-based deduplication** -- duplicate uploads are detected by content hash and replaced with symlinks, saving storage
- **Rich web UI** -- file manager with cut/paste/rename, grid-view thumbnails, audio/video player with transcoding, markdown editor, image gallery, CBZ comic reader, syntax-highlighted text viewer
- **Full-text search** -- search by filename, path, date, size, and metadata (ID3 tags, filesystem xattrs)
- **Zero-install deployment** -- runs from a single `.py` file, a standalone `.exe`, or a container
- **Per-user permissions** -- configurable read/write/admin per folder, per user
- **Zeroconf** -- mDNS/SSDP announcement for automatic discovery on local networks

## Role in the VAULT

In the con/serve architecture, copyparty can serve as a **low-friction ingestion front-end**. Research collaborators, lab instruments, or field devices can upload files via any supported protocol (a simple WebDAV mount, FTP push, or drag-and-drop in the web UI). Those files can then be periodically swept into git-annex for permanent archival:

```bash
# copyparty receives uploads into an inbox directory
# A cron job or script moves them into a DataLad dataset

rclone copy /srv/copyparty/inbox/ ./incoming/
git annex add incoming/
datalad save -m "Ingest uploads from copyparty inbox"
```

copyparty's content-based deduplication provides a useful first layer of dedup before files enter git-annex (which does its own content-addressing).

For quick file distribution, copyparty can also serve files directly from a git-annex working tree -- any files that have been `git annex get`-ed are regular files on disk and copyparty will serve them with thumbnails, search, and streaming playback.

## git-annex / DataLad Integration

**Integration level: external.**

copyparty does not integrate with git or git-annex directly. It operates on a plain filesystem directory tree. The workflow for incorporating copyparty into a git-annex-based infrastructure is:

1. **Configure copyparty** to write uploads to a designated inbox directory
2. **Periodically ingest** the inbox into a DataLad dataset (manually or via cron)
3. **Optionally serve** a git-annex working tree through copyparty for browsing and download

The WebDAV support is particularly useful: clients can mount the copyparty server as a network drive and drop files in, which then flow into the archival pipeline.

## AI Readiness

**Level: ai-partial.**

copyparty's file listings and search results are accessible via its HTTP API. The web UI exposes structured metadata (filenames, sizes, dates, ID3 tags). The actual AI readiness depends on the uploaded content -- text files and structured data are directly consumable, while binary media requires domain-specific processing.

## Photo Album Browsing

copyparty's rich web UI includes a built-in image gallery with grid-view thumbnails,
making it a surprisingly capable tool for **browsing photo collections**
without installing a dedicated photo management application.
When pointed at a git-annex working tree containing photos,
copyparty serves thumbnails, supports keyboard navigation,
and handles common image formats out of the box.

For personal photo archives (e.g., imported from
[Google Takeout]({{< ref "tools/cloud-storage/google-takeout" >}})),
copyparty can serve as a zero-setup browsing frontend:
start the single-file server, point it at the photo directory,
and navigate albums in the browser.
This is useful for quick review and triage before committing
to a heavier solution like [PhotoPrism]({{< ref "photoprism" >}})
or [Photoview]({{< ref "photoview" >}}).

```bash
# Browse a photo collection with zero setup
python3 copyparty-sfx.py -a photos::r ~/vault/personal/photos
# Open http://localhost:3923/photos/ in browser
```

## See Also

- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- patterns for bringing external files into git-annex
- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) -- the pyinfra-based lab deployment that could include copyparty as a service
- [rclone]({{< ref "rclone" >}}) -- can bridge between copyparty's WebDAV and git-annex special remotes
- [PhotoPrism]({{< ref "photoprism" >}}) -- full-featured photo management with AI classification
- [Photoview]({{< ref "photoview" >}}) -- lightweight photo gallery for structured collections
