---
title: "Photoview"
date: 2026-02-16
description: "Lightweight, self-hosted photo gallery with map view and face detection, deployed in Lab-in-a-Box"
summary: "A simple, self-hosted photo gallery designed for photographers who want a clean browsing experience over existing folder structures. Already deployed as a service in Lab-in-a-Box. Lighter than PhotoPrism, it reads photos directly from the filesystem without requiring import or database migration."
categories: ["Infrastructure"]
tags: ["photos", "gallery", "visualization", "self-hosted", "lightweight", "liab"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/photoview/photoview"
  homepage: "https://photoview.github.io"
  issues: "https://github.com/photoview/photoview/issues"
  docs: "https://photoview.github.io/docs/"
  language: "Go"
  license: "AGPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

[Photoview](https://photoview.github.io) is a lightweight, self-hosted photo gallery
built in Go with a React frontend.
It is designed for photographers who already have their photos organized in directories
and want a web-based browsing experience without moving files into a new system.

Photoview reads directly from the filesystem, following existing directory structure.
It generates thumbnails, extracts EXIF metadata, and provides map-based browsing
and basic face detection.
This filesystem-native approach makes it a natural fit for browsing
git-annex-managed photo collections.

## Key Features

- **Filesystem-native** -- reads photos from existing directory structure, no import step
- **Map view** -- browse photos by GPS location from EXIF metadata
- **Face detection** -- basic face grouping (less sophisticated than PhotoPrism's)
- **RAW support** -- handles RAW formats via Darktable/LibRaw
- **Video support** -- plays common video formats with FFmpeg transcoding
- **Multi-user** -- separate user accounts with per-directory access
- **Sharing** -- generate shareable links for albums
- **Low resource usage** -- runs comfortably on 512MB RAM

## Deployed in Lab-in-a-Box

Photoview is already part of the [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) service catalog,
deployed using the standard rootless-Podman-per-service pattern:

```
Internet → Caddy (TLS) → photos.lab.org → Photoview (localhost:port)
                                              ↓
                                          [filesystem]
                                    /home/photoview/data/
                                         ↑ (symlink or bind mount)
                                    git-annex working tree
```

This makes Photoview immediately available to any LiaB deployment
without additional configuration.

## Role in the Vault

Like [PhotoPrism]({{< ref "photoprism" >}}), Photoview serves as a
**visualization layer** that embodies the
[data-visualization separation]({{< ref "data-visualization-separation" >}}) principle.
The photos live in git-annex; Photoview provides the browsable web interface.

The key difference from PhotoPrism is Photoview's simplicity:
it does not attempt to reorganize or deeply classify your photos.
It presents what is on disk, as-is.
For collections that are already well-organized
(e.g., photos structured by date/event after import from
[Google Takeout]({{< ref "google-takeout" >}})),
this "just browse what's there" approach is often sufficient.

## git-annex / DataLad Integration

**Integration level: external.**

Photoview reads from the filesystem and follows symlinks,
so git-annex's symlink-based storage works transparently on Linux.
Point Photoview at a git-annex working tree where content has been `git annex get`-ed
and it will index and serve the photos.

```bash
# Make photo content available
cd ~/vault/personal/photos
git annex get 2025/ 2026/  # get recent years

# Configure Photoview to read from this path
# (in LiaB deployment config)
```

## AI Readiness

**Level: ai-partial.**

Photoview's generated index (thumbnails, EXIF extraction, face clusters)
provides a structured metadata layer over binary photo content.
The metadata is consumable by AI workflows;
the photos themselves require vision models.

## Comparison with Alternatives

See the comparison table in [PhotoPrism]({{< ref "photoprism#comparison-with-alternatives" >}}).
Photoview occupies the "low resource, low complexity" end of the spectrum:
it does less, but what it does, it does simply and reliably.

## Limitations and Caveats

- **No AI classification** -- unlike PhotoPrism, Photoview does not use machine learning for content classification. You get what EXIF provides.
- **Basic face detection** -- detects faces but clustering/labeling is less refined than PhotoPrism
- **No smart albums** -- albums are directory-based only, no automatic grouping by content
- **SQLite/MySQL dependency** -- requires a database for its index, though SQLite is sufficient for personal use

## See Also

- [PhotoPrism]({{< ref "photoprism" >}}) -- heavier alternative with AI-powered classification
- [copyparty]({{< ref "copyparty" >}}) -- zero-dependency alternative for quick photo browsing
- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) -- the deployment stack that includes Photoview
- [Data-Visualization Separation]({{< ref "data-visualization-separation" >}}) -- the architectural principle
