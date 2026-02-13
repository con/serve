---
title: "matrix-archive"
date: 2026-02-12
description: "Archive Matrix room messages to YAML files with media and avatar preservation"
summary: "Python tool for exporting Matrix room messages to structured YAML files, with support for media downloads, E2E encrypted rooms, and SSO authentication."
categories: ["Communications"]
tags: ["matrix", "yaml", "export", "media"]
media_types: ["matrix"]
integrations: ["git-only"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/russelldavies/matrix-archive"
  homepage: "https://github.com/russelldavies/matrix-archive"
  issues: "https://github.com/russelldavies/matrix-archive/issues"
  language: "Python"
  license: "Apache-2.0"
  maturity: "beta"
  last_verified: "2026-02"
---

matrix-archive is a Python tool for exporting Matrix room messages into
structured YAML log files alongside downloaded media and member avatars. It
supports end-to-end encrypted rooms, SSO authentication, and batch processing
of multiple rooms in a single operation.

## Key Features

- **YAML message logs**: Exports room messages to timestamped YAML files
  containing sender information, message content, and media references.
- **Media preservation**: Downloads all associated media files (images,
  documents, videos) and member avatars, storing them alongside the YAML
  logs.
- **E2E encryption support**: Can decrypt messages from end-to-end encrypted
  rooms using locally exported encryption keys (from Element or another
  Matrix client).
- **SSO authentication**: Supports single sign-on for enterprise Matrix
  deployments where password-based login is not available.
- **Batch processing**: Archive multiple rooms in a single invocation via
  command-line flags.
- **Interactive and automated modes**: Supports both interactive room
  selection and batch/scripted operation.

## Prerequisites

```bash
# Python 3.8+
# libolm 3.1+ (required for E2E decryption)

# Debian/Ubuntu
sudo apt install libolm-dev

# macOS
brew install libolm
```

## Installation

```bash
# Clone and install dependencies
git clone https://github.com/russelldavies/matrix-archive
cd matrix-archive
pip install -r requirements.txt
```

## Usage

```bash
# Basic usage -- interactive room selection
./matrix-archive.py /path/to/output

# You will be prompted for:
# 1. Homeserver URL
# 2. Authentication credentials
# 3. Room selection

# For E2E encrypted rooms, first export your keys from Element:
# Element -> Security & Privacy -> Export E2E room keys
# Then provide the key file when prompted
```

## Output Format

```
output/
  room-name/
    messages.yaml
    media/
      image1.jpg
      document.pdf
      ...
    avatars/
      @user1.png
      @user2.png
```

The YAML files contain structured message data:

```yaml
- sender: "@user:matrix.org"
  timestamp: "2026-01-15T10:30:00Z"
  type: "m.room.message"
  content:
    msgtype: "m.text"
    body: "The message text content"
- sender: "@user2:matrix.org"
  timestamp: "2026-01-15T10:31:00Z"
  type: "m.room.message"
  content:
    msgtype: "m.image"
    body: "photo.jpg"
    url: "media/photo.jpg"
```

## git Integration

The YAML + media output can be committed to a git repository. Since media
files may be large, using git-annex or a DataLad dataset is recommended:

```bash
# Create a DataLad dataset
datalad create matrix-rooms
cd matrix-rooms

# Run the archive
../matrix-archive/matrix-archive.py .

# Configure annex for media files
echo 'media/** annex.largefiles=anything' >> .gitattributes
echo 'avatars/** annex.largefiles=anything' >> .gitattributes

# Save
datalad save -m "Matrix room archive $(date -I)"
```

YAML message files remain in git (small, diffable, searchable), while media
files are tracked by git-annex for efficient storage.

## AI Readiness

**ai-partial** -- The YAML message logs are fully structured and directly
parseable, with typed fields for sender, timestamp, message type, and content.
Text messages are immediately accessible to language models. However, the
archive also includes binary media (images, documents, videos) and avatars
that require additional processing -- OCR for images, transcription for audio,
content extraction for documents -- before they can be consumed by text-based
AI systems. The YAML format itself is well-suited for programmatic access and
LLM ingestion.

## See Also

- [con/versations]({{< ref "conversations" >}}) -- DataLad-native Matrix
  archival tool that produces plain text output without media, better suited
  for automated, cron-based archival workflows where text content is the
  primary concern.
