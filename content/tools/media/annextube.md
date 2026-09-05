---
title: "con/annextube"
date: 2026-02-12
description: "YouTube channel and playlist archival with native DataLad/git-annex integration"
summary: "Flagship tool for archiving YouTube channels and playlists into git-annex repositories with full metadata preservation. Built on yt-dlp with native DataLad integration for incremental, content-addressed video archival."
categories: ["Media"]
tags: ["CON", "youtube", "video", "datalad", "git-annex", "metadata", "archival", "yt-dlp"]
media_types: ["youtube"]
integrations: ["native-datalad"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/con/annextube"
  homepage: "https://github.com/con/annextube"
  issues: "https://github.com/con/annextube/issues"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
  examples:
    - title: "ReproTube Archive"
      url: "https://datasets.datalad.org/repronim/ReproTube/web"
    - title: "annextube Demo"
      url: "https://con.github.io/annextube/"
---

**annextube** is the flagship tool in the con/serve ecosystem for archiving YouTube content into DataLad/git-annex repositories. It wraps [yt-dlp]({{< ref "yt-dlp" >}}) with native DataLad integration, providing a purpose-built pipeline for preserving video channels and playlists with full metadata, incremental updates, and content-addressed storage.

## Why annextube?

YouTube content is ephemeral. Channels disappear, videos get removed, playlists are reorganized, and community posts vanish without warning. For research groups that rely on educational content, conference recordings, or tutorial series, this creates a real preservation problem.

annextube solves this by treating YouTube archival as a first-class DataLad workflow:

- **Video files** are stored in git-annex (content-addressed, deduplicated, annexable to remote storage)
- **Metadata** (titles, descriptions, upload dates, thumbnails, subtitles) is stored in git (version-tracked, diffable, searchable)
- **Incremental updates** mean you only download what is new since the last run
- **Provenance** is captured automatically through DataLad's run records

## Architecture

annextube builds on a clear separation between large binary content and structured metadata, with summary tables at each level of the hierarchy:

```
my-channel-archive/
  .annextube/config.toml          # git (which channels/playlists to back up)
  channels.tsv                    # git (all channels at a glance)
  <channel>/
    channel.json                  # git (per-channel metadata)
    videos/
      videos.tsv                  # git (all videos in this channel)
      authors.tsv                 # git-annex
      <year>/<month>/<video-dir>/
        metadata.json             # git (full per-video metadata)
        video.mkv                 # git-annex (content-addressed)
        thumbnail.jpg             # git-annex
        video.<lang>.vtt          # git-annex (captions)
        captions.tsv              # git (caption index)
        comments.json             # git-annex
    playlists/                    # symlinks into videos/
```

This layout means:

- `git log` shows you when videos were added or metadata changed
- `git annex whereis` tells you where each video file is stored (local, S3, institutional storage)
- `datalad status` gives you an instant overview of what has changed
- The TSV summaries can be opened directly in DuckDB or VisiData, and drive the bundled Svelte web UI (see [Data-Visualization Separation]({{< ref "data-visualization-separation#annextube" >}}))

## Key Features

### Channel and Playlist Archival

Archive an entire YouTube channel or specific playlists. annextube handles pagination, rate limiting, and error recovery automatically.

### Incremental Updates

After the initial archive, subsequent runs only download new videos and updated metadata. This makes it practical to maintain living archives of active channels without re-downloading everything.

### Metadata Extraction and Storage

For each video, annextube extracts and stores:

- **metadata.json** -- the full yt-dlp metadata including title, description, upload date, duration, view count, tags, categories, chapters, and more
- **Thumbnails** -- preserved in git-annex alongside the video
- **Captions** -- creator-uploaded and auto-generated caption tracks as VTT files, plus a `captions.tsv` index in git
- **Comments** -- archived as `comments.json`

### Caption Archival

Captions are particularly valuable for AI readiness. annextube downloads all available caption tracks and keeps a per-video `captions.tsv` index in git. By default the VTT files themselves are annexed (they can be large), so full-text search over transcripts requires `git annex get` first, or the `build-search-index` subcommand that annextube provides for the web UI.

### DataLad Integration

DataLad is an optional dependency. When available, annextube creates DataLad datasets for new archives and uses `datalad save` and `datalad push` to commit and publish; without it, it falls back to plain git and git-annex. Wrapping `annextube backup` in `datalad run` is how you get provenance records.

## Installation

```bash
pip install annextube
```

Or with [uv](https://github.com/astral-sh/uv):

```bash
uv pip install annextube
```

### Prerequisites

- Python 3.10+
- git-annex 8.0+
- yt-dlp (installed as a dependency)
- ffmpeg (recommended)
- DataLad (optional)

## Usage

```bash
# Create the archive dataset and initialize an annextube config
datalad create -c text2git conference-talks
cd conference-talks
annextube init

# Edit .annextube/config.toml: list the channels and playlists to back up

# Back up everything listed in the config (incremental on repeat runs)
annextube backup

# Generate the static web UI for browsing the archive
annextube generate-web
```

`annextube backup` tracks what has already been downloaded and only fetches new content, so the same command serves as the incremental update. Other subcommands cover collections of archives (`collection init` / `collection backup`), aggregation across archives (`aggregate`), a search index for the web UI (`build-search-index`), integrity checks (`check`), and caption curation (`curate-captions`). Run `annextube --help` for the full list.

## AI Readiness

**Level: ai-partial.**

| Component | AI Ready? | Notes |
|-----------|-----------|-------|
| metadata.json | Yes | Structured JSON, directly parseable |
| videos.tsv / channels.tsv | Yes | Tabular summaries, queryable without a database |
| Captions (VTT) | Yes | Time-stamped text, excellent for RAG (annexed; `git annex get` first) |
| Video files | No | Require transcription (Whisper, etc.) |
| Thumbnails | No | Require vision model for analysis |

The combination of structured metadata and caption text means that a large fraction of a channel's informational content is accessible to AI systems without any transcription step. For videos lacking subtitles, tools like OpenAI Whisper can be run on the git-annex-stored video files to generate transcripts.

## Comparison with yt-dlp

annextube builds on [yt-dlp]({{< ref "yt-dlp" >}}) and shares its download capabilities, but adds the DataLad/git-annex layer:

| Feature | yt-dlp alone | annextube |
|---------|-------------|-----------|
| Video download | Yes | Yes (via yt-dlp) |
| Metadata extraction | Yes | Yes (via yt-dlp) |
| git-annex storage | Manual setup | Automatic |
| DataLad integration | None | Native |
| Incremental updates | Manual tracking | Built-in |
| Content deduplication | No | Via git-annex |
| Remote storage (S3, etc.) | No | Via git-annex special remotes |
| Provenance tracking | No | Via `datalad run` (optional) |

If you just need to download a few videos, yt-dlp is simpler. If you are building a persistent, versioned, deduplicated archive of YouTube content integrated with your research data management infrastructure, annextube is the right tool.

## Limitations

- **YouTube rate limiting**: Heavy archival can trigger rate limits. annextube inherits yt-dlp's throttling behavior but long-running archives of large channels may need to be done in stages.
- **YouTube Terms of Service**: Archiving content for research preservation purposes. Users should be aware of YouTube's ToS and applicable copyright considerations.
- **Early development**: The tool is in use but upstream marks it as early development; the CLI and layout may still change.
- **yt-dlp dependency**: Changes in YouTube's infrastructure occasionally break yt-dlp, which cascades to annextube. Keeping yt-dlp updated is important.

## See Also

- [yt-dlp]({{< ref "yt-dlp" >}}) -- the underlying download engine
- [gallery-dl]({{< ref "gallery-dl" >}}) -- similar concept for image galleries
- [Zoom Recording Archival]({{< ref "zoom-archival" >}}) -- archiving video from another platform
