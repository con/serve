---
title: "msgvault"
date: 2026-08-31
description: "Archive a lifetime of email and chat into a local, searchable, offline-first database"
summary: "Downloads and archives email (Gmail, Outlook, MBOX, PST), chat (Teams, Discord, Slack, Beeper), calendar, contacts, SMS, and meeting transcripts into a local SQLite/DuckDB store with FTS and semantic search."
categories: ["Communications"]
tags: ["email", "chat", "slack", "discord", "teams", "gmail", "sms", "sqlite", "duckdb", "mcp", "semantic-search"]
media_types: ["email", "chat", "calendar", "contacts"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/kenn-io/msgvault"
  homepage: "https://github.com/kenn-io/msgvault"
  issues: "https://github.com/kenn-io/msgvault/issues"
  language: "Go"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-08"
---

msgvault downloads and archives personal communications into a local database
so that search, analytics, and AI access work without any network connection.
Its stated philosophy: "Your messages are yours.
Decades of correspondence, attachments, and history shouldn't be locked behind
a web interface or an API."

## Supported Sources

**Email**
- Gmail (OAuth/IMAP)
- Microsoft Outlook (IMAP)
- Apple Mail (local mailboxes)
- MBOX exports
- PST archives

**Chat and Messaging**
- Microsoft Teams
- Discord
- Slack
- Beeper Desktop -- a unified inbox that bridges WhatsApp, Signal, Telegram,
  iMessage, and other protocols

**Other**
- Google Calendar events (organizers, attendees)
- CardDAV address books (contacts)
- SMS/MMS via Android SMS Backup & Restore
- Granola and Circleback meeting transcripts

## Storage Architecture

Data is stored in `~/.msgvault/` (configurable) as a SQLite database.
DuckDB powers aggregate analytics queries.
Attachments are content-addressed by SHA-256 and optionally packed to reduce
filesystem overhead.
No data leaves the machine during operation -- only the initial download from
the provider APIs touches the network.

## Search Capabilities

- FTS5 full-text search with Gmail-like syntax (`from:`, `has:attachment`, date ranges)
- Vector/semantic search via self-hosted embeddings (Ollama, llama.cpp)
- Hybrid BM25 + vector search using Reciprocal Rank Fusion
- DuckDB-powered aggregate analytics (message volume by sender, thread statistics)
- Interactive TUI and web UI interfaces

## MCP Server

msgvault exposes an MCP server, allowing AI agents to search and retrieve
message content programmatically without requiring network access to the
original provider.

## Relation to git-annex / DataLad Archival

msgvault manages its own content-addressed attachment store rather than
delegating to git-annex.
It is a self-contained archive designed for interactive use and AI access,
not for integration into a version-controlled DataLad superdataset.

For the con/serve mission, msgvault covers the **access and search** layer well.
The underlying `~/.msgvault/` store could in principle be snapshotted into a
DataLad dataset for off-site backup and provenance, but no established workflow
for this exists yet.

## Comparison with Section Peers

| Tool               | Primary target         | Storage      | Incremental | Semantic search |
| ------------------ | ---------------------- | ------------ | ----------- | --------------- |
| msgvault           | Email + multi-platform | SQLite+DuckDB | yes         | yes (Ollama)    |
| slackdump          | Slack only             | JSON files   | yes         | no              |
| tg-archive         | Telegram only          | HTML/JSON    | yes         | no              |
| conversations      | SMS/MMS (Android)      | DataLad      | yes         | no              |

## See Also

- [slackdump](../slackdump/) -- Slack-specific archival with more complete data coverage
- [conversations](../conversations/) -- SMS archival with native DataLad integration
- [tg-archive](../tg-archive/) -- Telegram channel archival
