---
title: "matrix-archive"
date: 2026-02-12
description: "Archive Matrix room messages to JSON event logs with media and avatar preservation"
summary: "Python tool for exporting Matrix room messages to structured JSON event logs, with support for media downloads, E2E encrypted rooms, and SSO authentication."
categories: ["Communications"]
tags: ["matrix", "json", "export", "media"]
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
structured JSON event logs alongside downloaded media and member avatars. It
supports end-to-end encrypted rooms, SSO authentication, and batch processing
of multiple rooms in a single operation. (The upstream README still describes
the output as YAML; the current code writes JSON.)

## Key Features

- **JSON event logs**: Exports the raw Matrix events of a room to one JSON
  file per room, with the sender's display name and local media path added
  to each event.
- **Media preservation**: Downloads all associated media files (images,
  documents, videos) and member avatars, storing them alongside the event
  logs.
- **E2E encryption support**: Can decrypt messages from end-to-end encrypted
  rooms using locally exported encryption keys (from Element or another
  Matrix client).
- **SSO authentication**: Supports single sign-on for enterprise Matrix
  deployments where password-based login is not available.
- **Batch processing**: Archive multiple rooms in a single invocation via
  command-line flags (`--batch`, `--all-rooms`, `--room`, `--roomregex`).
- **Interactive and automated modes**: Supports both interactive room
  selection and batch/scripted operation; `--no-media` and `--redact`
  control what is written.

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
python matrix-archive.py /path/to/output

# You will be prompted for:
# 1. Homeserver URL
# 2. Authentication credentials
# 3. Room selection

# Unattended: all joined rooms, credentials and keys on the command line
python matrix-archive.py /path/to/output --batch --all-rooms \
    --server https://matrix.example.org --user @me:example.org \
    --userpass "$PASS" --keys element-keys.txt --keyspass "$KEYPASS"

# For E2E encrypted rooms, first export your keys from Element:
# Element -> Security & Privacy -> Export E2E room keys
```

## Output Format

```
output/
  Room Name_!roomid:server.json          # one JSON array of events per room
  Room Name_!roomid:server_media/        # downloaded attachments
    image1.jpg
    document.pdf
  Room Name_!roomid:server_avatars/      # member avatars, one per user ID
    @user1:server
    @user2:server
```

Each entry in the JSON file is the raw Matrix event source
(`sender`, `origin_server_ts`, `type`, `content`, ...)
with two fields added by the tool:
`_sender_name` (display name) and, for media events,
`_file_path` (the local path of the downloaded file).

## git-annex / DataLad Integration

**Integration level: git-only.**

The JSON + media output can be committed to a git repository. Since media
files may be large, using git-annex or a DataLad dataset is recommended:

```bash
# Create a DataLad dataset
datalad create matrix-rooms
cd matrix-rooms

# Run the archive
python ../matrix-archive/matrix-archive.py . --batch --all-rooms ...

# Configure annex for media and avatar directories
echo '*_media/** annex.largefiles=anything' >> .gitattributes
echo '*_avatars/** annex.largefiles=anything' >> .gitattributes

# Save
datalad save -m "Matrix room archive $(date -I)"
```

JSON event files remain in git (small, diffable, searchable), while media
files are tracked by git-annex for efficient storage.

## AI Readiness

**Level: ai-partial.**

The JSON event logs are fully structured and directly
parseable, with typed fields for sender, timestamp, message type, and content.
Text messages are immediately accessible to language models. However, the
archive also includes binary media (images, documents, videos) and avatars
that require additional processing -- OCR for images, transcription for audio,
content extraction for documents -- before they can be consumed by text-based
AI systems. The JSON format itself is well-suited for programmatic access and
LLM ingestion.

## See Also

- [con/versations]({{< ref "conversations" >}}) -- DataLad-native Matrix
  archival tool that produces plain text output without media, better suited
  for automated, cron-based archival workflows where text content is the
  primary concern.
