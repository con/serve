---
title: "PhotoPrism"
date: 2026-02-16
description: "AI-powered photo management web application, usable as a browsing frontend over git-annex-managed photo collections"
summary: "A self-hosted, AI-powered photo management application with face recognition, automatic categorization, map views, and album management. In the con/serve architecture, PhotoPrism serves as a rich visualization frontend over git-annex-tracked photo archives, applying the data-visualization separation principle: photos live in git-annex, PhotoPrism provides the browsable UI."
categories: ["Infrastructure"]
tags: ["photos", "gallery", "visualization", "self-hosted", "AI", "face-recognition", "maps", "albums"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/photoprism/photoprism"
  homepage: "https://www.photoprism.app"
  issues: "https://github.com/photoprism/photoprism/issues"
  docs: "https://docs.photoprism.app"
  language: "Go"
  license: "AGPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

[PhotoPrism](https://www.photoprism.app) is a self-hosted photo management application
built in Go with a modern web UI.
It provides AI-powered features including face recognition, automatic content classification,
location-based browsing via maps, and smart album generation.

In the con/serve architecture, PhotoPrism exemplifies
the [data-visualization separation]({{< ref "data-visualization-separation" >}}) principle:
the authoritative photo collection lives in git-annex repositories,
and PhotoPrism is attached as a **read-oriented frontend** for browsing,
searching, and organizing views over that collection.

## Key Features

- **Face recognition** -- automatically groups photos by detected faces, with manual labeling
- **Automatic classification** -- identifies objects, scenes, and colors using TensorFlow
- **Map view** -- browse photos by geographic location using embedded GPS metadata
- **Calendar view** -- navigate by date with year/month/day drill-down
- **Album management** -- manual albums plus auto-generated "moments" and "states"
- **RAW support** -- indexes RAW formats (CR2, NEF, ARW, DNG, etc.) with automatic JPEG conversion
- **Video playback** -- supports common video formats with transcoding via FFmpeg
- **Full-text search** -- search by metadata, labels, faces, locations, colors
- **Multi-user** -- supports multiple user accounts with sharing controls
- **WebDAV** -- built-in WebDAV server for upload and network access

## Role in the Vault

PhotoPrism is not a storage system -- it is a **view layer** over stored photos.
The canonical workflow:

1. **Archive** photos into a git-annex dataset (the authoritative copy)
2. **Point PhotoPrism's originals directory** at the git-annex working tree (or a `git annex get`-ed subset)
3. **Index** -- PhotoPrism scans the directory, builds a SQLite/MariaDB index with face embeddings, labels, and location data
4. **Browse** -- users interact with photos through PhotoPrism's web UI
5. **Changes flow back** -- any organizational decisions (albums, labels, face names) live in PhotoPrism's database, not in the git-annex tree

```
git-annex dataset (authoritative)
    └── photos/
         ├── 2024/
         ├── 2025/
         └── 2026/
              ↑
        PhotoPrism reads from here (originals dir)
              ↓
        PhotoPrism index (sidecar DB + cache)
              ↓
        Web UI: browse, search, share
```

This means PhotoPrism can be rebuilt from scratch at any time --
re-index the git-annex tree and all AI classifications regenerate.
The photos themselves are never modified.

## Integration with Google Takeout

PhotoPrism is a natural destination for photos extracted from
[Google Takeout]({{< ref "google-takeout" >}}) dumps.
After extracting and importing Takeout photos into a git-annex dataset,
point PhotoPrism at the import directory:

```bash
# After importing Takeout photos into git-annex
cd ~/vault/personal/photos
git annex get .  # ensure content is locally available

# Configure PhotoPrism originals path to point here
# (in docker-compose.yml or photoprism.yml)
# PHOTOPRISM_ORIGINALS_PATH: /home/user/vault/personal/photos
```

PhotoPrism will re-derive album structure, GPS locations, and face clusters
from the image data and EXIF metadata.
This is more robust than trying to preserve Google Photos' album structure directly,
since it works from the authoritative image data rather than fragile sidecar JSON.

## Deployment via Lab-in-a-Box

PhotoPrism can be deployed as a service in a
[Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) deployment,
following the same rootless-Podman-per-service pattern
used for Forgejo-Aneksajo and HedgeDoc.

The LiaB deployment currently includes [Photoview]({{< ref "photoview" >}})
as a lighter-weight alternative.
PhotoPrism is heavier (requires more RAM for TensorFlow-based classification)
but offers richer AI features.

## git-annex / DataLad Integration

**Integration level: external.**

PhotoPrism operates on a plain filesystem directory.
It does not understand git-annex symlinks or DataLad datasets directly.
The integration pattern is:

1. `git annex get` the photos you want to browse (making them regular files via symlinks to annex objects)
2. Point PhotoPrism's originals directory at the git-annex working tree
3. PhotoPrism follows the symlinks and indexes the content normally

On systems where git-annex uses symlinks (the default on Linux),
this works transparently.
On systems using adjusted branches (Windows, some configurations),
files appear as regular files and PhotoPrism works without any special handling.

## AI Readiness

**Level: ai-partial.**

PhotoPrism's own database contains rich structured metadata:
face embeddings, object labels, scene classifications, GPS coordinates, timestamps.
This metadata is AI-consumable.
The photos themselves are binary media requiring vision models for direct interpretation.

PhotoPrism's indexing effectively creates an AI-ready metadata layer
on top of ai-manual photo content -- a form of
[metadata extraction]({{< ref "metadata-extraction" >}})
that aligns with the hierarchical summarization pattern.

## Comparison with Alternatives

| Feature | PhotoPrism | [Photoview]({{< ref "photoview" >}}) | [copyparty]({{< ref "copyparty" >}}) |
|---------|-----------|-----------|-----------|
| AI classification | Yes (TensorFlow) | No | No |
| Face recognition | Yes | No | No |
| Map view | Yes | Yes | No |
| Resource requirements | High (2+ GB RAM) | Low | Minimal |
| RAW support | Yes | Yes | No |
| Setup complexity | Moderate (needs DB) | Low | Minimal |
| Album management | Rich (manual + auto) | Basic | Directory-based |

## Limitations and Caveats

- **Resource hungry** -- TensorFlow-based classification requires significant RAM (2-4 GB minimum)
- **Write-back gap** -- album assignments and face labels live in PhotoPrism's database, not in the git-annex tree. Exporting these organizational decisions back into git-tracked metadata requires additional tooling.
- **No deduplication awareness** -- PhotoPrism does not understand git-annex's content-addressed deduplication. If the same photo appears in multiple datasets, PhotoPrism will index it multiple times.
- **Index rebuild time** -- initial indexing of large collections (100K+ photos) can take hours

## See Also

- [Data-Visualization Separation]({{< ref "data-visualization-separation" >}}) -- the principle PhotoPrism exemplifies
- [Photoview]({{< ref "photoview" >}}) -- lighter alternative already deployed in Lab-in-a-Box
- [copyparty]({{< ref "copyparty" >}}) -- minimalist alternative for quick photo album browsing
- [Google Takeout]({{< ref "google-takeout" >}}) -- the primary source of personal photo archives
- [gallery-dl]({{< ref "gallery-dl" >}}) -- archiving photos from hosting platforms
