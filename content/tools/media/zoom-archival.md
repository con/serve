---
title: "Zoom Recording Archival"
date: 2026-02-12
description: "Approaches for archiving Zoom cloud and local recordings into git-annex repositories"
summary: "Concept-level guide to archiving Zoom meeting recordings using the Zoom API for cloud recordings and filesystem integration for local recordings, with git-annex storage and transcript extraction for AI readiness."
categories: ["Media"]
tags: ["zoom", "video", "meetings", "recordings", "api"]
media_types: ["zoom"]
integrations: ["git-annex"]
ai_readiness: ["ai-manual"]
params:
  repo: "https://developers.zoom.us/docs/api/"
  homepage: "https://developers.zoom.us/docs/api/"
  issues: "https://developers.zoom.us/docs/api/"
  language: "Python"
  license: "various"
  maturity: "concept"
  last_verified: "2026-02"
---

**Zoom Recording Archival** describes approaches for preserving Zoom meeting recordings -- both cloud-hosted and locally saved -- into git-annex repositories. Unlike the other tools in this section, there is no single turnkey tool for Zoom archival. Instead, this page documents the building blocks and patterns for constructing a Zoom archival pipeline.

## The Problem

Zoom is ubiquitous in research: lab meetings, seminars, thesis defenses, collaborator calls, and conference sessions are routinely recorded. But these recordings are fragile:

- **Cloud recordings** are deleted after a configurable retention period (often 30-120 days) or when storage quotas are exceeded
- **Local recordings** live on individual laptops and are rarely backed up systematically
- **Institutional Zoom accounts** may be deprovisioned when personnel leave
- **Zoom's built-in sharing** is not designed for long-term preservation

For research groups, losing these recordings means losing institutional knowledge -- context, decisions, and discussions that are never written down anywhere else.

## Cloud Recordings via the Zoom API

Zoom provides a [REST API](https://developers.zoom.us/docs/api/) that includes endpoints for listing and downloading cloud recordings. This is the most reliable path for automated archival.

### API Approach

```python
# Conceptual workflow -- not a complete implementation
import requests

# 1. Authenticate via Server-to-Server OAuth
access_token = get_zoom_access_token(account_id, client_id, client_secret)

# 2. List recordings for a user or date range
recordings = requests.get(
    "https://api.zoom.us/v2/users/{userId}/recordings",
    headers={"Authorization": f"Bearer {access_token}"},
    params={"from": "2025-01-01", "to": "2025-12-31"}
).json()

# 3. Download each recording file
for meeting in recordings["meetings"]:
    for file in meeting["recording_files"]:
        download_url = file["download_url"] + f"?access_token={access_token}"
        # Download and store in git-annex
```

### Key API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /users/{userId}/recordings` | List cloud recordings for a user |
| `GET /meetings/{meetingId}/recordings` | Get recordings for a specific meeting |
| `GET /accounts/{accountId}/recordings` | List recordings across an account (admin) |
| Download URL from recording object | Download the actual recording files |

### Authentication

Zoom's API uses Server-to-Server OAuth apps (recommended) or JWT (deprecated). Setting up a Server-to-Server OAuth app requires:

1. Creating an app in the [Zoom App Marketplace](https://marketplace.zoom.us/)
2. Configuring scopes: `recording:read:admin` (or `recording:read` for user-level)
3. Obtaining `account_id`, `client_id`, and `client_secret`

### Integration with git-annex

A practical archival script would:

```bash
#!/bin/bash
# zoom-archive.sh - Conceptual archival workflow
ARCHIVE_DIR="$1"
cd "$ARCHIVE_DIR" || exit 1

# Run the Python download script
python zoom_download.py --output ./recordings/

# Each meeting gets a directory:
#   recordings/2025-03-15_Lab-Meeting/
#     video.mp4          -> git-annex
#     audio_only.m4a     -> git-annex
#     transcript.vtt     -> git (text, searchable)
#     chat.txt           -> git (text)
#     meeting_info.json  -> git (metadata)

# Add to git-annex
git annex add --include='*.mp4' --include='*.m4a'
git add --all  # transcripts, chat logs, metadata go to git
git commit -m "Zoom archive update $(date -I)"
```

## Local Recording Archival

For locally saved Zoom recordings (stored on the host machine), the approach is simpler but requires discipline:

### Default Local Recording Location

Zoom saves local recordings to:
- **macOS**: `~/Documents/Zoom/`
- **Windows**: `%USERPROFILE%\Documents\Zoom\`
- **Linux**: `~/Documents/Zoom/`

Each recording creates a directory with:
- `video.mp4` -- the recording video
- `audio_only.m4a` -- audio-only track
- `chat.txt` -- in-meeting chat log (if any)

### Scripted Import

```bash
#!/bin/bash
# import-local-zoom.sh - Import local Zoom recordings to git-annex
ZOOM_DIR="$HOME/Documents/Zoom"
ARCHIVE_DIR="$1"

cd "$ARCHIVE_DIR" || exit 1

# Copy new recordings
for meeting_dir in "$ZOOM_DIR"/*/; do
    meeting_name=$(basename "$meeting_dir")
    if [ ! -d "recordings/$meeting_name" ]; then
        cp -r "$meeting_dir" "recordings/$meeting_name"
    fi
done

# Add to git-annex
git annex add recordings/ --include='*.mp4' --include='*.m4a'
git add --all
git commit -m "Import local Zoom recordings $(date -I)"
```

## Zoom's Built-in Transcripts

Zoom can generate transcripts for cloud recordings automatically. These are valuable for AI readiness:

- **Audio transcript** (.vtt format) -- time-stamped text of spoken content
- **Meeting summary** (if AI Companion is enabled) -- structured summary of the meeting

When downloading via the API, transcript files are included as separate recording file entries with `file_type: "TRANSCRIPT"`. These should be stored in git (not annex) since they are small text files that benefit from version tracking and full-text search.

### Enhancing Transcripts

Zoom's auto-generated transcripts can be improved with:

- **Whisper** (OpenAI) -- run on the downloaded audio for higher-quality transcription
- **Speaker diarization** -- identify who said what (Zoom transcripts sometimes include this; Whisper-based tools like `whisperx` can add it)
- **Manual correction** -- for critical meetings, reviewing and correcting the auto-generated transcript

## AI Readiness

Zoom recordings are **ai-manual** out of the box, but Zoom's transcript features significantly improve this:

| Component | AI Ready? | Notes |
|-----------|-----------|-------|
| Transcripts (.vtt) | Yes | Time-stamped text, directly usable |
| Chat logs | Yes | Plain text, immediately usable |
| Meeting metadata | Yes | JSON from API, structured |
| Video files | No | Require transcription |
| Audio files | No | Require transcription (Whisper) |
| AI Companion summaries | Yes | Structured meeting summaries |

If Zoom's transcription is enabled for cloud recordings, a substantial portion of the meeting content becomes text-searchable and AI-accessible immediately upon archival.

## Tooling Status

The maturity level for Zoom archival is **concept**. There is no single, maintained, open-source tool that provides a complete Zoom-to-git-annex pipeline. The pieces exist:

- Zoom's API is well-documented and stable
- git-annex handles the storage layer well
- Python libraries for Zoom API interaction exist (though none are specifically designed for archival)

What is missing is a purpose-built tool analogous to [annextube]({{< ref "annextube" >}}) for YouTube. This represents an opportunity for the con/serve ecosystem: a `con/zoomtube` or similar tool that handles authentication, incremental download, transcript extraction, and DataLad integration in a single package.

### Existing Partial Solutions

- **[zoom-recording-downloader](https://github.com/ricardorodrigues-ca/zoom-recording-downloader)** -- Python script for bulk downloading cloud recordings via Zoom API
- **[zoomdl](https://github.com/Battleman/zoomdl)** -- Go-based Zoom recording downloader (archived)
- Various institutional scripts shared on GitHub -- search for "zoom recording backup" or "zoom archive script"

None of these integrate with git-annex or DataLad, but they demonstrate the API patterns needed.

## See Also

- [annextube]({{< ref "annextube" >}}) -- the model for what a Zoom archival tool could become
- [yt-dlp]({{< ref "yt-dlp" >}}) -- general video download (does not support Zoom)
