---
title: "Ingestion Patterns"
date: 2026-02-12
description: "Common patterns for pulling data into git-annex/DataLad repositories from external sources"
---

Every tool in the con/serve [Tools](/tools/) catalog performs some form of ingestion -- extracting artifacts from an external source and placing them into a git or git-annex repository. Despite the diversity of sources (messaging platforms, video hosts, cloud storage, scholarly databases), the ingestion strategies fall into a small number of recurring patterns.

Understanding these patterns helps when evaluating new tools, designing custom ingestion pipelines, or choosing the right approach for an unsupported source.

## Pattern 1: Direct Download

**Pull a file from a URL and store it in git-annex.**

This is the simplest pattern. A tool fetches content from a known URL and places it in the working tree, where git-annex or DataLad tracks it.

**Examples:**
- [yt-dlp]({{< ref "tools/media/yt-dlp" >}}) downloads videos from YouTube and other platforms
- [gallery-dl]({{< ref "gallery-dl" >}}) downloads images from gallery sites
- [annextube]({{< ref "annextube" >}}) wraps yt-dlp with DataLad integration

**Characteristics:**
- Content has a known, stable URL (at least at download time)
- Downloads are typically large binary files suitable for git-annex
- git-annex can record the URL as a content source via `git annex addurl`
- Incremental updates are possible by checking what is already downloaded

**git-annex integration:**

```bash
# Register a URL and download content
git annex addurl https://example.org/dataset.tar.gz

# Or via DataLad
datalad download-url https://example.org/dataset.tar.gz
```

## Pattern 2: API Extraction

**Query a service's API and store the structured response.**

Many platforms provide REST or GraphQL APIs that return structured data (JSON, XML). The ingestion tool authenticates, paginates through results, and stores the output.

**Examples:**
- [slackdump]({{< ref "slackdump" >}}) uses the Slack API to export messages and files
- [citations-collector]({{< ref "citations-collector" >}}) queries CrossRef, OpenCitations, DataCite, and OpenAlex APIs
- [git-bug]({{< ref "git-bug" >}}) bridges use GitHub/GitLab APIs to import issues

**Characteristics:**
- Output is structured text (JSON, YAML) -- often stored in git proper, not annex
- Attachments and binary content are downloaded separately and annexed
- Rate limiting and pagination must be handled
- Incremental sync is possible using timestamps or cursors
- API tokens or credentials are required

**Typical structure:**

```
export/
  messages/
    2026-01-15.json    # git (small, structured)
    2026-01-16.json    # git (small, structured)
  attachments/
    file-abc123.pdf    # git-annex (binary, large)
    image-def456.png   # git-annex (binary, large)
```

## Pattern 3: Crawler-Based

**Recursively discover and download content from a web source.**

Crawlers navigate web pages, follow links, and download content they find. Unlike direct download (which targets known URLs), crawlers discover URLs as they traverse the source.

**Examples:**
- [datalad-crawler](https://github.com/datalad/datalad-crawler) -- DataLad extension for web crawling with annex integration
- [ArchiveBox]({{< ref "archivebox" >}}) -- web page archival with multiple output formats
- [wget](https://www.gnu.org/software/wget/) / [HTTrack](https://www.httrack.com/) -- general-purpose web crawlers

**Characteristics:**
- URL discovery is dynamic -- the set of content is not known upfront
- Output includes both content (HTML, images, PDFs) and structural metadata (link graphs, sitemaps)
- Deduplication is important (same content reachable via multiple URLs)
- Crawl depth and scope must be controlled to avoid unbounded downloads
- git-annex's content addressing naturally deduplicates identical files

## Pattern 4: Mount-and-Copy

**Mount a remote filesystem and import content locally.**

Some sources are best accessed as a mounted filesystem rather than through an API or web protocol. The content is rsynced or copied from the mount point into the git-annex repository.

**Examples:**
- [rclone mount]({{< ref "rclone" >}}) -- mount any of 70+ cloud providers as a FUSE filesystem
- NFS / SMB mounts -- institutional file servers
- USB drives and external disks

**Characteristics:**
- The source appears as a local directory
- Standard Unix tools (rsync, cp, find) can be used
- git-annex's `import` command can ingest from a directory:

```bash
# Import from a mounted cloud drive
rclone mount gdrive:shared-data /mnt/gdrive &
git annex import /mnt/gdrive/project-files --to main
```

- Useful when the source does not have a structured API
- Incremental updates via rsync's `--checksum` or git-annex's content addressing

## Pattern 5: Bridge-Based

**Synchronize structured data between a platform and a local representation.**

Bridges maintain a bidirectional or unidirectional mapping between an external platform's data model and a local representation. Unlike API extraction (which does a one-time dump), bridges maintain identity mappings and support incremental sync.

**Examples:**
- [git-bug bridges]({{< ref "git-bug" >}}) -- bidirectional sync between GitHub/GitLab/Jira issues and local git-bug database
- [con/versations]({{< ref "conversations" >}}) -- Matrix room archival with incremental sync
- Zotero sync in [citations-collector]({{< ref "citations-collector" >}}) -- sync Zotero library changes into the local dataset

**Characteristics:**
- Maintains identity mappings (remote ID to local ID)
- Supports incremental sync (only new or changed items)
- May be bidirectional (push changes back to the source)
- The local representation is often a custom data model, not raw API responses
- Conflict resolution may be needed for bidirectional bridges

## Choosing the Right Pattern

| Pattern | Best For | Complexity | Incremental? |
|---------|----------|------------|-------------|
| Direct download | Known URLs, binary files | Low | By URL tracking |
| API extraction | Structured platform data | Medium | By timestamp/cursor |
| Crawler-based | Web content, unknown scope | High | By crawl state |
| Mount-and-copy | Filesystem-accessible sources | Low | By checksum/mtime |
| Bridge-based | Ongoing sync with platforms | High | Native |

Most tools in the con/serve catalog use one or two of these patterns. When designing a custom ingestion pipeline for an unsupported source, start by identifying which pattern fits best, then look for existing tools that implement that pattern as a foundation.

## See Also

- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- the outbound counterpart
- [Domain Extensions]({{< ref "domain-extensions" >}}) -- domain-specific ingestion pipelines
