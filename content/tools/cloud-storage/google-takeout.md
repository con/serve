---
title: "Google Takeout"
date: 2026-02-16
description: "Export and archive your entire Google account — Gmail, Photos, Drive, YouTube, Calendar, Location History, and 50+ other services"
summary: "Google's official data export service, producing massive archives covering Gmail, Google Photos, Drive, YouTube history, Calendar, Contacts, Location History, and dozens more services. A single Takeout dump is the largest personal data ingestion event most people will ever perform — and a critical starting point for anyone building a personal digital archive."
categories: ["Cloud Storage"]
tags: ["google", "takeout", "export", "personal-data", "gmail", "photos", "drive", "youtube", "calendar", "contacts", "location-history"]
media_types: ["cloud-storage"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/google/takeout"
  homepage: "https://takeout.google.com"
  issues: "https://support.google.com/accounts/answer/3024190"
  language: "N/A (Google service)"
  license: "Proprietary (your data)"
  maturity: "stable"
  last_verified: "2026-02"
---

**Google Takeout** is Google's official data export service.
It lets you download a copy of your data from 70+ Google products
in a single (often enormous) archive.
For anyone building a personal digital archive,
a Takeout dump is typically the **single largest ingestion event** --
tens or hundreds of gigabytes covering years of digital life.

## What You Get

A Takeout export can include data from any combination of these services:

| Service | Format | Typical Size | AI Readiness |
|---------|--------|-------------|--------------|
| **Gmail** | MBOX | Gigabytes | ai-ready (text), ai-partial (attachments) |
| **Google Photos** | JPEG/PNG/MP4 + JSON metadata | Tens of GB | ai-manual (media), ai-ready (metadata) |
| **Google Drive** | Original files or converted (DOCX→PDF) | Variable | Mixed |
| **YouTube** | Watch history, playlists, subscriptions (JSON) | Small | ai-ready |
| **Calendar** | ICS | Small | ai-ready |
| **Contacts** | vCard (VCF) | Small | ai-ready |
| **Location History** | JSON (semantic locations, raw signals) | Moderate | ai-ready |
| **Chrome** | Bookmarks (HTML), history (JSON) | Small | ai-ready |
| **Google Maps** | Reviews, saved places (JSON/GeoJSON) | Small | ai-ready |
| **Keep** | Notes as HTML + JSON | Small | ai-ready |
| **Fit** | Activity data (TCX) | Moderate | ai-partial |
| **Hangouts / Chat** | Conversation history (JSON) | Moderate | ai-ready |
| **Blogger** | Posts (Atom XML) | Small | ai-ready |
| **Google Pay** | Transactions (CSV) | Small | ai-ready |

The full list is much longer -- Takeout supports 70+ products.

## The Challenge

A Takeout archive is a **raw dump**, not a curated dataset.
The challenges for con/serve-style archival are:

1. **Scale** -- a full export can be 50-500+ GB, split across multiple ZIP files
2. **Heterogeneous formats** -- MBOX, JSON, ICS, vCard, HTML, binary media, all mixed together
3. **Metadata coupling** -- Google Photos stores metadata in sidecar `.json` files alongside each image/video, requiring reassembly
4. **No incremental export** -- each Takeout is a full dump. There is no "export only what changed since last time."
5. **Nested archives** -- the export itself is a set of ZIP or TGZ files that must be extracted before processing

## Ingestion Status

No fully automated workflow exists yet for downloading, extracting,
and categorizing a Takeout dump into domain-specific git-annex datasets.
The process today is largely manual:
request the export, download the ZIP files, extract, and sort by hand.

Key pain points that remain unsolved:

- **Download automation** -- Takeout delivers download links via email or pushes to Drive/Dropbox. There is no stable API for triggering or retrieving exports programmatically.
- **Splitting and categorization** -- the raw dump mixes all services into a flat directory tree. Splitting into domain-specific datasets (photos, email, YouTube metadata, etc.) requires manual scripting.
- **Photo metadata reassembly** -- Google Photos stores GPS, descriptions, people tags, and album membership in sidecar `.json` files separate from the images. Merging this metadata back into EXIF is fragile and format-dependent. Various community tools exist but none are comprehensive.
- **Deduplication across exports** -- since each Takeout is a full dump (no incremental mode), successive exports overlap massively. Identifying what is new requires content-based comparison.

[rclone]({{< ref "rclone" >}}) can access Google Drive and Google Photos directly
for incremental sync between Takeout dumps,
but rclone's Google Photos backend is read-only
and does not faithfully export album structure.

## git-annex / DataLad Integration

**Integration level: external.**

Google Takeout produces ZIP/TGZ archives that must be manually extracted
and imported into git-annex.
A dedicated connector that automates extraction, metadata reassembly,
and import into domain-specific datasets would be a valuable contribution
to the con/serve ecosystem (see [Personal Archive user story]({{< ref "user-stories/personal-archive" >}})).

## AI Readiness

**Level: ai-partial.**

Takeout exports are a mixed bag:

- **Structured metadata** (JSON from YouTube, Calendar ICS, Contacts vCard, Location History, Chrome bookmarks) is immediately AI-consumable
- **Email** (MBOX) is text-heavy and highly AI-relevant, but requires parsing MIME structure for attachments
- **Photos/Videos** are binary media requiring vision models or transcription
- **Google Drive documents** exported as PDF/DOCX may need text extraction

The metadata sidecar files are among the most AI-valuable outputs --
they contain structured information about years of digital activity
(where you were, what you watched, who you communicated with)
in machine-readable JSON.

## Limitations and Caveats

- **No incremental export**: every Takeout is a full dump, which means deduplication against previous exports is essential
- **Rate limited**: Google limits how frequently you can request exports and how long download links remain active
- **Format instability**: Google occasionally changes export formats without notice. Community tooling around Takeout metadata parsing can break.
- **Album reconstruction**: Google Photos album membership is in sidecar JSON, not in the file hierarchy. Reconstructing albums requires parsing these files.
- **Shared content**: content shared with you by others may or may not be included, depending on the product

## See Also

- [rclone]({{< ref "rclone" >}}) -- incremental sync from Google Drive/Photos between Takeout dumps
- [Personal Archive]({{< ref "user-stories/personal-archive" >}}) -- the user story for building a complete personal digital archive
- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- patterns for bringing external data into git-annex
- [gallery-dl]({{< ref "gallery-dl" >}}) -- for archiving photos from other image hosting platforms
