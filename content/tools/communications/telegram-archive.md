---
title: "Telegram-Archive"
date: 2026-02-12
description: "Automated Telegram chat backup system with web viewer and real-time listener"
summary: "Docker-based Telegram archival tool with incremental backups, media preservation, real-time message capture, and a built-in web viewer."
categories: ["Communications"]
tags: ["telegram", "export", "archive", "messages"]
media_types: ["telegram"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/GeiserX/Telegram-Archive"
  homepage: "https://github.com/GeiserX/Telegram-Archive"
  issues: "https://github.com/GeiserX/Telegram-Archive/issues"
  language: "Python"
  license: "GPL-3.0"
  maturity: "beta"
  last_verified: "2026-02"
---

Telegram-Archive is a Docker-based system for automated Telegram chat backup
with a built-in web viewer. It performs scheduled incremental backups, supports
real-time message capture, and preserves media files with deduplication. The
tool provides a Telegram-like web interface for browsing archived messages.

## Key Features

- **Incremental backups**: Only downloads new messages since the last run,
  configurable on a cron schedule (default: every 6 hours).
- **Real-time listener**: Optional WebSocket-based listener captures message
  edits, deletions, and new messages as they happen.
- **Media preservation**: Downloads photos, videos, documents, stickers, GIFs,
  voice messages, and audio files. Media deduplication via symlinks conserves
  disk space.
- **Web viewer**: Built-in dark-themed interface mimicking the Telegram app,
  with mobile-responsive design, keyboard navigation, search, and push
  notifications.
- **JSON export**: Supports exporting messages as JSON with date filtering
  for downstream processing.
- **Security features**: Optional password authentication, chat ID whitelisting,
  mass deletion protection with rate limiting.
- **Database options**: SQLite (default, zero-configuration) or PostgreSQL for
  larger deployments.

## Installation and Usage

Telegram-Archive runs via Docker Compose:

```bash
# Clone the repository
git clone https://github.com/GeiserX/Telegram-Archive
cd Telegram-Archive

# Configure environment
cp .env.example .env
# Edit .env with your Telegram API credentials from https://my.telegram.org

# Authenticate with Telegram
./init_auth.sh

# Start the services
docker compose up -d

# Access the viewer at http://localhost:8000
```

Key configuration variables in `.env`:
- `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`, `TELEGRAM_PHONE` (required)
- `SCHEDULE` for backup frequency (cron format)
- `CHAT_IDS` for whitelist mode
- `ENABLE_LISTENER=true` for real-time synchronization

## git-annex Integration

Telegram-Archive requires manual integration with git-annex since it manages
its own storage via SQLite/PostgreSQL and a media directory. To archive the
output into a git-annex repository:

```bash
# Create a DataLad dataset
datalad create telegram-archive
cd telegram-archive

# After running Telegram-Archive, copy or symlink the data directory
cp -r /path/to/telegram-archive/data/* .

# Configure annex for media files
echo '*.jpg annex.largefiles=anything' >> .gitattributes
echo '*.mp4 annex.largefiles=anything' >> .gitattributes
echo '*.pdf annex.largefiles=anything' >> .gitattributes
echo '*.db annex.largefiles=anything' >> .gitattributes

# Save
datalad save -m "Telegram archive import $(date -I)"
```

Alternatively, the JSON export feature can be used to extract structured
message data that is more git-friendly:

```bash
# Export messages as JSON for a specific date range
# Then store the JSON in git (small, diffable) and media in annex
```

## AI Readiness

**ai-partial** -- The tool stores messages in a structured database (SQLite or
PostgreSQL) and supports JSON export with date filtering, making the textual
content accessible to language models. However, the archive also contains
substantial binary media (photos, videos, voice messages, stickers) that
requires separate processing -- transcription for audio, OCR or captioning
for images -- before it can be consumed by text-based AI systems.

## See Also

- [tg-archive]({{< ref "tg-archive" >}}) -- Lighter-weight alternative that
  produces static HTML/JSON output without requiring Docker, better suited
  for simple archival into git repositories.
