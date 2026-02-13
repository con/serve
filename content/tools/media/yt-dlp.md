---
title: "yt-dlp"
date: 2026-02-12
description: "General-purpose video and audio downloader supporting thousands of sites"
summary: "The Swiss army knife of video downloading. Foundation for many archival workflows, usable standalone with git-annex import or as the engine behind annextube's DataLad-native integration."
categories: ["Media"]
tags: ["youtube", "video", "audio", "download", "metadata"]
media_types: ["youtube"]
integrations: ["git-annex"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/yt-dlp/yt-dlp"
  homepage: "https://github.com/yt-dlp/yt-dlp"
  issues: "https://github.com/yt-dlp/yt-dlp/issues"
  language: "Python"
  license: "Unlicense"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "con/annextube (DataLad-native wrapper)"
      url: "https://github.com/con/annextube"
    - title: "git-annex importfeed"
      url: "https://git-annex.branchable.com/tips/using_the_web_as_a_special_remote/"
    - title: "Tube Archivist"
      url: "https://www.tubearchivist.com/"
    - title: "Archive Team YouTube Project"
      url: "https://wiki.archiveteam.org/index.php/YouTube"
---

**yt-dlp** is a feature-rich command-line video and audio downloader that supports extraction from thousands of websites. It is the actively maintained fork of youtube-dl, with significant improvements in speed, features, and site support. In the con/serve ecosystem, yt-dlp serves as both a standalone archival tool and the download engine powering [annextube]({{< ref "annextube" >}}).

## Overview

yt-dlp can download video, audio, subtitles, thumbnails, and metadata from YouTube and [thousands of other sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md). For archival purposes, its key strengths are:

- **Broad site support** -- not just YouTube, but Vimeo, Twitter/X, Reddit, conference hosting platforms, and many more
- **Metadata extraction** -- outputs structured JSON with all available metadata per video
- **Subtitle download** -- auto-generated and manual captions in multiple formats
- **Format selection** -- fine-grained control over video/audio quality and codec
- **Stable output** -- consistent file naming and directory structure for automation

## Installation

```bash
pip install yt-dlp
```

Or via package managers:

```bash
# Debian/Ubuntu
sudo apt install yt-dlp

# macOS
brew install yt-dlp

# With uv
uv pip install yt-dlp
```

## Standalone Usage with git-annex

While [annextube]({{< ref "annextube" >}}) provides a fully integrated DataLad experience, yt-dlp can be used directly with git-annex for simpler archival needs.

### Basic Download and Import

```bash
# Create a git-annex repository
git init video-archive && cd video-archive
git annex init "video archive"

# Download a video with metadata
yt-dlp --write-info-json --write-subs --write-thumbnail \
  -o '%(id)s/%(id)s.%(ext)s' \
  'https://www.youtube.com/watch?v=VIDEO_ID'

# Add to git-annex
git annex add .
git commit -m "Archive video VIDEO_ID"
```

### Using `git annex importfeed` for Podcast and Video Feeds

git-annex has built-in support for importing RSS/Atom feeds, which works well with podcast feeds and YouTube channel RSS feeds:

```bash
git init podcast-archive && cd podcast-archive
git annex init "podcast archive"

# Import from a podcast RSS feed
git annex importfeed https://example.com/podcast/feed.xml

# Import from a YouTube channel RSS feed
git annex importfeed \
  'https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID'
```

The `importfeed` approach is lightweight and does not require yt-dlp at all, but it only captures the media files linked in the feed, not the full metadata that yt-dlp provides.

### Batch Archival with Metadata

For more thorough archival, a scripted approach combines yt-dlp's metadata extraction with git-annex storage:

```bash
#!/bin/bash
# archive-channel.sh - Archive a YouTube channel with full metadata
CHANNEL_URL="$1"
ARCHIVE_DIR="$2"

cd "$ARCHIVE_DIR" || exit 1

# Download new videos with all metadata
yt-dlp \
  --download-archive downloaded.txt \
  --write-info-json \
  --write-subs --write-auto-subs \
  --write-thumbnail \
  --write-description \
  -o '%(upload_date)s-%(id)s/%(id)s.%(ext)s' \
  "$CHANNEL_URL"

# Separate large files (annex) from metadata (git)
git annex add --include='*.mp4' --include='*.webm' --include='*.mkv'
git add --all  # metadata files go to git
git commit -m "Archive update $(date -I)"
```

The `--download-archive downloaded.txt` flag is key: it maintains a list of already-downloaded video IDs, enabling incremental updates without re-downloading.

## Metadata Output

yt-dlp's `--write-info-json` produces a comprehensive JSON file for each video:

```json
{
  "id": "dQw4w9WgXcQ",
  "title": "Video Title",
  "description": "Full video description...",
  "upload_date": "20091025",
  "duration": 212,
  "view_count": 1500000000,
  "like_count": 15000000,
  "channel": "Channel Name",
  "channel_id": "UCuAXFkgsw1L7xaCfnd5JJOw",
  "tags": ["music", "video"],
  "categories": ["Music"],
  "subtitles": {},
  "automatic_captions": {},
  "chapters": [],
  "formats": []
}
```

This structured metadata is directly usable by AI systems, search tools, and analysis pipelines.

## Comparison with annextube

yt-dlp is the general-purpose download engine; [annextube]({{< ref "annextube" >}}) builds on it to provide a DataLad-native archival experience:

| Aspect | yt-dlp (standalone) | annextube |
|--------|-------------------|-----------|
| Download capability | Full | Full (via yt-dlp) |
| Site support | 1000+ sites | YouTube-focused |
| git-annex integration | Manual | Automatic |
| DataLad datasets | Manual setup | Automatic |
| Incremental updates | Via `--download-archive` | Built-in |
| Provenance tracking | None | DataLad run records |
| Metadata organization | Flat or custom | Structured per-video dirs |

**When to use yt-dlp directly:**
- Downloading from non-YouTube sites that annextube does not cover
- One-off downloads where full DataLad integration is unnecessary
- Feeding into `git annex importfeed` for podcast/RSS-based archival
- Custom workflows with specific format or naming requirements

**When to use annextube instead:**
- Systematic channel or playlist archival
- Integration with existing DataLad infrastructure
- Need for automatic incremental updates with provenance
- Building a long-term, versioned video archive

## AI Readiness

yt-dlp produces **ai-partial** output:

- **info.json** files are structured, machine-readable metadata -- immediately usable
- **Subtitle files** (VTT, SRT) provide time-stamped transcripts of video content
- **Description files** are plain text
- **Video/audio files** themselves require transcription (e.g., via Whisper) for text-based AI processing

For archival workflows prioritizing AI readiness, always use `--write-info-json --write-subs --write-auto-subs --write-description` to capture all available text content alongside the media files.

## See Also

- [annextube]({{< ref "annextube" >}}) -- DataLad-native YouTube archival built on yt-dlp
- [gallery-dl]({{< ref "gallery-dl" >}}) -- similar philosophy for image gallery archival
- [Zoom Recording Archival]({{< ref "zoom-archival" >}}) -- archiving video from Zoom
