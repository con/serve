---
title: "slackdump"
date: 2026-02-12
description: "Export Slack workspace messages, threads, files, and metadata without admin privileges"
summary: "Go-based tool for archiving Slack workspaces into JSON exports, supporting messages, threads, files, emojis, and users -- no admin access required."
categories: ["Communications"]
tags: ["slack", "export", "json", "messages", "threads", "files"]
media_types: ["slack"]
integrations: ["git-annex"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/rusq/slackdump"
  homepage: "https://github.com/rusq/slackdump"
  issues: "https://github.com/rusq/slackdump/issues"
  language: "Go"
  license: "GPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

Slackdump is a mature, actively maintained Go tool that exports Slack workspace
data -- messages, threads, files, users, channels, and emojis -- without
requiring workspace admin privileges. It is one of the most capable Slack
archival tools available and produces structured JSON output that is
well-suited for long-term preservation in git-annex repositories.

## Key Features

- **No admin required**: Works with regular user tokens or browser-based
  authentication; does not need a Slack workspace admin to grant permissions.
- **Multiple output modes**:
  - **Archive** (v3 native format): Memory-efficient streaming format optimized
    for large workspaces.
  - **Export**: Produces output compatible with Slack's standard workspace export
    format, also usable for Mattermost migration.
  - **Dump**: Single-channel-per-file format for quick extraction without full
    workspace metadata.
- **Complete data coverage**: Messages, threaded replies, file attachments,
  user profiles, channel metadata, and custom emojis.
- **Search and browse**: Built-in viewer for inspecting archives, including
  image display in the terminal.
- **Incremental operation**: Can resume interrupted exports.

## Output Format

Slackdump produces JSON output across all modes. The **Export** mode generates
a directory structure matching Slack's official export format:

```
export/
  channels.json
  users.json
  2026-01-15/
    general.json
    random.json
  ...
```

Each JSON file contains an array of message objects with fields such as `ts`,
`user`, `text`, `thread_ts`, `files`, and `reactions`. This structured format
makes slackdump output directly consumable by language models and text analysis
pipelines.

## Installation

```bash
# macOS
brew install slackdump

# From pre-built binaries (Linux, macOS, Windows)
# Download from https://github.com/rusq/slackdump/releases

# From source
go install github.com/rusq/slackdump/v3/cmd/slackdump@latest
```

## Usage

```bash
# Authenticate (interactive browser-based login)
slackdump auth

# Export entire workspace in Slack export format
slackdump export -o workspace-export

# Dump a specific channel
slackdump dump -o channel-dump C01ABCDEF

# List channels
slackdump list channels

# List users
slackdump list users
```

## git-annex Integration

Slackdump output integrates naturally with git-annex for long-term archival.
JSON message files are text and can be stored directly in git for
diff-friendliness, while binary file attachments should go into git-annex.

A recommended workflow:

```bash
# Create a DataLad dataset for the archive
datalad create slack-archive
cd slack-archive

# Run the export
slackdump export -o export/

# Configure annex to handle large files
# Text/JSON in git, binaries in annex
echo '* annex.largefiles=(largerthan=100kb)' >> .gitattributes

# Save with DataLad
datalad save -m "Slack workspace export $(date -I)"
```

For periodic archival, wrap the slackdump command in `datalad run` to capture
full provenance:

```bash
datalad run -m "Incremental Slack export" \
  --output export/ \
  slackdump export -o export/
```

## AI Readiness

**ai-ready** -- Slackdump's JSON output is fully structured with typed fields
for timestamps, user IDs, message text, thread relationships, reactions, and
file metadata. This format can be directly ingested by language models for
summarization, search indexing, or knowledge extraction without any
preprocessing. File attachments (images, PDFs) would require separate
processing for content extraction.

## Considerations

- Slack may send security alerts to workspace administrators when slackdump
  accesses the API, depending on workspace security policies.
- Rate limiting applies; large workspaces may take considerable time to export.
- User tokens expire and may need periodic renewal.
- For DataLad-native Slack archival with tighter integration, see
  [wayslack2]({{< ref "wayslack2" >}}).
