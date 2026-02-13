---
title: "Media"
date: 2026-02-12
description: "Tools for archiving video, audio, and image artifacts into git-annex repositories"
cascade:
  showEdit: true
---

Research media -- conference talks, lab meeting recordings, tutorial videos,
podcast episodes, and image datasets -- is some of the hardest content to preserve.
Files are large, hosting platforms impose retention limits,
and binary formats resist version control.

git-annex was designed precisely for this problem:
content-addressed storage that tracks large files without bloating the git repository.

This section catalogs tools for downloading, organizing, and archiving
media artifacts into git-annex/DataLad repositories.

## Platforms and Formats

**YouTube** -- The dominant platform for research talks, tutorials, and conference recordings.
[annextube](annextube/) provides DataLad-native YouTube archival;
[yt-dlp](yt-dlp/) offers a more general-purpose approach.

**Zoom** -- Ubiquitous for lab meetings and virtual conferences.
Recordings often have expiration dates, making proactive archival essential.
See [Zoom Archival](zoom-archival/).

**Podcasts and Audio** -- Research podcasts, interview recordings, and audio datasets.
yt-dlp handles most podcast feeds; specialized tools exist for specific use cases.

**Image Galleries** -- Figures, microscopy images, and photo documentation.
[gallery-dl](gallery-dl/) archives images from numerous hosting platforms.

## AI Readiness

Media files are inherently `ai-manual` -- binary content that requires
transcription or captioning before an LLM can work with it.
However, many tools also capture structured metadata (titles, descriptions,
timestamps, chapter markers) that is `ai-ready` on its own.
A practical archival strategy preserves both the media files (in git-annex)
and their metadata (in git) so that AI workflows can operate on the metadata
while the full media remains available for human review.
