---
title: "gallery-dl"
date: 2026-02-12
description: "Download image galleries and collections from over 100 websites"
summary: "Command-line tool for downloading image galleries from numerous hosting sites. Extracts images and metadata in structured formats suitable for git-annex archival."
categories: ["Media"]
tags: ["images", "galleries", "download", "metadata"]
media_types: ["images"]
integrations: ["git-annex"]
ai_readiness: ["ai-manual"]
params:
  repo: "https://github.com/mikf/gallery-dl"
  homepage: "https://github.com/mikf/gallery-dl"
  issues: "https://github.com/mikf/gallery-dl/issues"
  language: "Python"
  license: "GPL-2.0"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "gallery-dl Supported Sites"
      url: "https://github.com/mikf/gallery-dl/blob/master/docs/supportedsites.md"
---

**gallery-dl** is a command-line tool for downloading image galleries and collections from a wide range of websites. It supports over 100 sites including Flickr, Tumblr, DeviantArt, Reddit, Twitter/X, Instagram, Pixiv, and many more. For archival workflows, its structured output and metadata extraction make it a natural fit for git-annex-based preservation.

## Overview

gallery-dl fills the same niche for images that [yt-dlp]({{< ref "yt-dlp" >}}) fills for video: a reliable, configurable downloader that handles authentication, pagination, rate limiting, and metadata extraction across many platforms. Key features for archival use:

- **100+ supported sites** -- broad coverage of image hosting platforms, social media, and art communities
- **Metadata extraction** -- outputs JSON metadata alongside downloaded images
- **Configurable output** -- flexible directory and filename templates
- **Authentication support** -- handles login-gated content via cookies or credentials
- **Rate limiting** -- respectful of server resources, configurable delays
- **Incremental downloads** -- archive tracking to avoid re-downloading

## Installation

```bash
pip install gallery-dl
```

Or with [uv](https://github.com/astral-sh/uv):

```bash
uv pip install gallery-dl
```

## Supported Sites

gallery-dl supports a wide range of platforms, including (but not limited to):

- **Art communities**: DeviantArt, Pixiv, ArtStation, Newgrounds
- **Social media**: Twitter/X, Reddit, Tumblr, Instagram, Mastodon
- **Image hosting**: Flickr, Imgur, SmugMug, Google Photos
- **Imageboards**: Various chan-style boards
- **Manga/comics**: MangaDex, Webtoon, and others

The full list is maintained in the [project's supported sites documentation](https://github.com/mikf/gallery-dl/blob/master/docs/supportedsites.md).

## Integration with git-annex

gallery-dl does not have native git-annex integration, but its structured output makes manual integration straightforward.

### Basic Archival Workflow

```bash
# Create a git-annex repository for the image archive
git init image-archive && cd image-archive
git annex init "image gallery archive"

# Download a gallery with metadata
gallery-dl --write-metadata \
  -D ./galleries/ \
  'https://www.flickr.com/photos/username/albums/ALBUM_ID'

# Add images to git-annex, metadata to git
git annex add --include='*.jpg' --include='*.png' --include='*.gif' --include='*.webp'
git add --all  # JSON metadata goes to git
git commit -m "Archive Flickr album ALBUM_ID"
```

### Metadata Extraction

Using `--write-metadata`, gallery-dl creates a JSON file alongside each downloaded image containing all available metadata from the source site:

```json
{
  "category": "flickr",
  "subcategory": "album",
  "filename": "image_title",
  "extension": "jpg",
  "id": 12345678,
  "title": "Sunset at the Lab",
  "description": "Photo from the 2025 retreat",
  "date": "2025-06-15T14:30:00",
  "tags": ["research", "lab", "retreat"],
  "owner": "username",
  "views": 42
}
```

This metadata, stored in git alongside the annex-tracked image files, provides searchable context without needing to open the images themselves.

### Incremental Downloads

gallery-dl supports an archive file to track already-downloaded items:

```bash
gallery-dl --download-archive gallery-dl-archive.db \
  --write-metadata \
  -D ./galleries/ \
  'https://www.reddit.com/r/subreddit/top/?t=month'
```

The SQLite-based archive database prevents re-downloading on subsequent runs, enabling regular incremental updates.

### Configuration for Archival

A `gallery-dl.conf` file can standardize archival behavior:

```json
{
  "extractor": {
    "base-directory": "./galleries/",
    "archive": "./gallery-dl-archive.db",
    "postprocessors": [
      {
        "name": "metadata",
        "mode": "json"
      }
    ],
    "directory": ["{category}", "{subcategory}"],
    "filename": "{id}_{title[:80]}.{extension}"
  }
}
```

This configuration ensures consistent directory structure, automatic metadata output, and archive tracking across all downloads.

## AI Readiness

gallery-dl produces **ai-manual** output:

| Component | AI Ready? | Notes |
|-----------|-----------|-------|
| JSON metadata | Yes | Structured, searchable, parseable |
| Image files | No | Require vision models for content analysis |
| Alt text/captions | Partial | Available from some sources via metadata |

Images are inherently difficult for text-based AI systems. The JSON metadata provides searchable context (titles, tags, descriptions, dates), but the visual content itself requires vision models (GPT-4V, Claude Vision, etc.) or specialized image analysis pipelines for meaningful AI processing.

For research archival, the metadata often provides sufficient context for discovery and cataloging, even if the images themselves are not AI-processable without additional tooling.

## Limitations

- **No native git-annex/DataLad integration** -- requires manual scripting to fit into a DataLad workflow (unlike [annextube]({{< ref "annextube" >}}) for video)
- **Site-specific breakage** -- websites change their APIs and page structures; gallery-dl requires regular updates to maintain compatibility
- **Authentication complexity** -- some sites require browser cookies or OAuth tokens, which can be fragile for long-running automated archival
- **No built-in deduplication** -- the archive database prevents re-downloading but does not deduplicate across different source URLs pointing to the same image (git-annex handles this at the storage layer)

## See Also

- [yt-dlp]({{< ref "yt-dlp" >}}) -- analogous tool for video archival
- [annextube]({{< ref "annextube" >}}) -- DataLad-native video archival (the integration model gallery-dl could benefit from)
