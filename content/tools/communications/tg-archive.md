---
title: "tg-archive"
date: 2026-02-12
description: "Telegram group chat archiver that produces static HTML websites and JSON data"
summary: "Python tool that syncs Telegram group messages to a local SQLite database and generates static HTML archives with navigation, search, and RSS feeds."
categories: ["Communications"]
tags: ["telegram", "export", "html", "json", "static"]
media_types: ["telegram"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/knadh/tg-archive"
  homepage: "https://github.com/knadh/tg-archive"
  issues: "https://github.com/knadh/tg-archive/issues"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
---

tg-archive converts Telegram group chat history into browsable static HTML
websites, similar in spirit to mailing list archives. Messages are synced
incrementally to a local SQLite database and then rendered into navigable
HTML pages with year/month/day indexes, threaded replies, and RSS feeds.

## Key Features

- **Incremental sync**: Downloads only new messages since the last run,
  storing everything in a local SQLite database.
- **Static HTML generation**: Produces a self-contained `site/` directory
  ready for deployment on any static hosting platform.
- **Threaded navigation**: "In reply to" links connect replies to parent
  messages with deep linking across pages.
- **Temporal indexes**: Year, month, and day-based navigation for browsing
  large archives chronologically.
- **Media embedding**: Downloaded photos, documents, and files are embedded
  in the generated pages.
- **RSS/Atom feeds**: Generates feeds of recent messages for subscription.
- **Poll rendering**: Displays poll results inline.
- **Emoji fallbacks**: Substitutes emoji representations for stickers.
- **Customizable templates**: Uses Jinja2 templates for full control over
  the generated HTML.

## Installation

```bash
pip install tg-archive
```

## Usage

```bash
# Initialize a new archive site
tg-archive --new --path=mysite

# Edit the generated config.yaml with your Telegram API credentials
# and target group chat ID

# Sync messages from Telegram
tg-archive --sync --path=mysite

# Build the static HTML site
tg-archive --build --path=mysite

# The generated site is in mysite/site/
```

You need Telegram API credentials from https://my.telegram.org. The first
sync requires interactive authentication; subsequent runs use the saved
session file.

## Output Format

tg-archive stores messages in a SQLite database and generates a static site:

```
mysite/
  config.yaml
  session.session    # Telegram auth session (do NOT commit!)
  data.sqlite        # Message database
  site/
    index.html
    2026/
      01/
        15.html
      ...
    static/
    rss.xml
```

The SQLite database contains structured message data that can be queried
directly for programmatic access.

## git Integration

Since tg-archive produces static files, the output integrates directly with
git. The generated HTML and SQLite database can be committed to a repository:

```bash
# Create a DataLad dataset
datalad create telegram-group-archive
cd telegram-group-archive

# Initialize tg-archive here
tg-archive --new --path=.

# Add session file to .gitignore (contains auth credentials)
echo "session.session" >> .gitignore

# Sync and build
tg-archive --sync --path=.
tg-archive --build --path=.

# Save the archive
datalad save -m "Telegram group archive $(date -I)"
```

For periodic archival:

```bash
datalad run -m "Sync Telegram group archive" \
  --output site/ \
  --output data.sqlite \
  "tg-archive --sync --path=. && tg-archive --build --path=."
```

Note that the SQLite database and media files may grow large over time. If
using git-annex, configure largefiles accordingly:

```bash
echo 'data.sqlite annex.largefiles=anything' >> .gitattributes
echo 'site/static/** annex.largefiles=(largerthan=100kb)' >> .gitattributes
```

## AI Readiness

**ai-ready** -- The SQLite database provides fully structured message data
with typed fields for timestamps, sender information, message text, reply
relationships, and media references. The database can be queried directly
with SQL or exported to JSON for ingestion by language models. The generated
HTML pages also contain the full message text in a parseable structure.
Media files (photos, documents) would need separate processing for content
extraction.

## Considerations

- The project maintainer has indicated reduced active development, though
  pull requests are still reviewed.
- The `session.session` file contains Telegram authentication credentials
  and must never be committed to a public repository.
- For a more full-featured Telegram archival system with a web viewer and
  real-time capture, see [Telegram-Archive]({{< ref "telegram-archive" >}}).

## See Also

- [Telegram-Archive]({{< ref "telegram-archive" >}}) -- Docker-based
  alternative with real-time listener and built-in web viewer.
