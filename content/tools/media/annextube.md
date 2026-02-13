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
  maturity: "beta"
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

annextube builds on a clear separation between large binary content and structured metadata:

```
my-channel-archive/
  .datalad/
  .git/
  .gitattributes
  videos/
    <video-id>/
      <video-id>.mp4              # git-annex (content-addressed)
      <video-id>.info.json        # git (yt-dlp metadata)
      <video-id>.description      # git (video description)
      <video-id>.en.vtt           # git (English subtitles)
      <video-id>.thumbnail.jpg    # git-annex (thumbnail image)
  channel_metadata.json           # git (channel-level metadata)
```

This layout means:

- `git log` shows you when videos were added, metadata changed, or descriptions updated
- `git annex whereis` tells you where each video file is stored (local, S3, institutional storage)
- `datalad status` gives you an instant overview of what has changed
- Standard git tools (diff, blame, log) work on all the text metadata

## Key Features

### Channel and Playlist Archival

Archive an entire YouTube channel or specific playlists. annextube handles pagination, rate limiting, and error recovery automatically.

### Incremental Updates

After the initial archive, subsequent runs only download new videos and updated metadata. This makes it practical to maintain living archives of active channels without re-downloading everything.

### Metadata Extraction and Storage

For each video, annextube extracts and stores:

- **info.json** -- the full yt-dlp metadata dump including title, description, upload date, duration, view count, tags, categories, chapters, and more
- **Description files** -- the video description as a standalone text file for easy searching
- **Thumbnails** -- preserved in git-annex alongside the video
- **Subtitles and transcripts** -- auto-generated and manual subtitles in VTT/SRT format, stored in git for full-text searchability

### Subtitle and Transcript Archival

Subtitles are particularly valuable for AI readiness. annextube downloads all available subtitle tracks (both creator-uploaded and YouTube's auto-generated captions) and stores them as plain text files in git. This means:

- Full-text search across all archived video transcripts using standard `grep`/`git grep`
- LLM-based analysis of video content without needing to process the video files themselves
- Structured subtitle formats (VTT with timestamps) enable time-aligned references back to the source video

### DataLad Integration

annextube operates as a DataLad-aware tool:

- Creates proper DataLad datasets for new archives
- Uses `datalad save` to commit changes with meaningful messages
- Supports DataLad's run mechanism for full provenance tracking
- Works with DataLad siblings for pushing archives to remote storage

## Installation

```bash
pip install annextube
```

Or with [uv](https://github.com/astral-sh/uv):

```bash
uv pip install annextube
```

### Prerequisites

- Python 3.8+
- git-annex
- DataLad
- yt-dlp (installed as a dependency)

## Usage

### Archive a YouTube Channel

```bash
# Create a new DataLad dataset for the archive
datalad create my-channel-archive
cd my-channel-archive

# Archive an entire channel
annextube archive https://www.youtube.com/@ChannelName
```

### Archive a Playlist

```bash
annextube archive https://www.youtube.com/playlist?list=PLxxxxxxxx
```

### Incremental Update

```bash
# Run again later to pick up new videos
annextube archive https://www.youtube.com/@ChannelName
```

annextube tracks what has already been downloaded and only fetches new content.

### Example Workflow: Archiving a Research Channel

A complete workflow for archiving a conference channel and making it available for AI-assisted analysis:

```bash
# 1. Create the archive dataset
datalad create -c text2git conference-talks
cd conference-talks

# 2. Initial archive of the channel
annextube archive https://www.youtube.com/@ConferenceName

# 3. Push video files to institutional S3 storage
git annex initremote s3 type=S3 bucket=conference-archive
git annex copy --to s3 .

# 4. The metadata and subtitles are in git, push to GitHub/Forgejo
datalad push --to origin

# 5. Later: update with new uploads
annextube archive https://www.youtube.com/@ConferenceName

# 6. Search across all archived transcripts
git grep "interesting topic" -- '*.vtt'
```

## AI Readiness

annextube produces **ai-partial** output:

| Component | AI Ready? | Notes |
|-----------|-----------|-------|
| info.json metadata | Yes | Structured JSON, directly parseable |
| Video descriptions | Yes | Plain text, immediately usable |
| Subtitles/transcripts | Yes | Time-stamped text, excellent for RAG |
| Video files | No | Require transcription (Whisper, etc.) |
| Thumbnails | No | Require vision model for analysis |

The combination of structured metadata and subtitle text means that a large fraction of a channel's informational content is immediately accessible to AI systems without any additional processing. For videos lacking subtitles, tools like OpenAI Whisper can be run on the git-annex-stored video files to generate transcripts.

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
| Provenance tracking | No | Via DataLad run records |

If you just need to download a few videos, yt-dlp is simpler. If you are building a persistent, versioned, deduplicated archive of YouTube content integrated with your research data management infrastructure, annextube is the right tool.

## Limitations and Caveats

- **YouTube rate limiting**: Heavy archival can trigger rate limits. annextube inherits yt-dlp's throttling behavior but long-running archives of large channels may need to be done in stages.
- **YouTube Terms of Service**: Archiving content for research preservation purposes. Users should be aware of YouTube's ToS and applicable copyright considerations.
- **Beta status**: The tool is functional and actively used but the API and output format may still evolve.
- **yt-dlp dependency**: Changes in YouTube's infrastructure occasionally break yt-dlp, which cascades to annextube. Keeping yt-dlp updated is important.

## See Also

- [yt-dlp]({{< ref "yt-dlp" >}}) -- the underlying download engine
- [gallery-dl]({{< ref "gallery-dl" >}}) -- similar concept for image galleries
- [Zoom Recording Archival]({{< ref "zoom-archival" >}}) -- archiving video from another platform
