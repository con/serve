---
title: "AgentsView"
date: 2026-08-31
description: "Local-first analytics and search platform for AI coding session artifacts from 40+ agents"
summary: "Aggregates Claude Code, Copilot, Cursor, and 40+ other agent session logs into a local SQLite database with full-text and semantic search, token analytics, and export capabilities."
categories: ["AI Sessions"]
tags: ["claude-code", "analytics", "search", "sqlite", "sessions", "multi-agent", "mcp"]
media_types: ["ai-sessions"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/kenn-io/agentsview"
  homepage: "https://github.com/kenn-io/agentsview"
  issues: "https://github.com/kenn-io/agentsview/issues"
  language: "Go"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-08"
---

AgentsView is a local-first platform that discovers and indexes AI coding session
artifacts from 40+ agents -- Claude Code, GitHub Copilot, Cursor, Codex, Devin,
OpenHands, Windsurf, and many others -- into a unified searchable interface.
All data stays on the machine; the server binds to `127.0.0.1` by default.

## What It Captures

AgentsView reads agent session directories automatically at startup and indexes:

- Conversation transcripts and message content
- Token consumption (input / output / cache) and cost
- Tool usage patterns and model selections
- Timestamps, session duration, and project path

It does not require any configuration of the individual agents --
it reads their existing session storage locations.

## Storage

Sessions are indexed into a local SQLite database with FTS5 full-text search.
Optional mirrors include DuckDB files for analytical queries and PostgreSQL for
shared team dashboards. The source session files (e.g. Claude Code's JSONL in
`~/.claude/projects/`) are read-only; AgentsView does not modify them.

## Search and Analysis

- Full-text search across all session content, any agent
- Semantic search (opt-in, via any OpenAI-compatible embeddings endpoint)
- Token and cost analytics by agent, model, project, or time range
- "Recent Edits" feed linking sessions to the files they touched
- Session export to HTML or GitHub Gist

## MCP Server

AgentsView exposes an MCP server so AI agents can query session history
programmatically -- enabling workflows where an agent reviews what a previous
session did before continuing work.

## git-annex / DataLad Integration

**Integration level: external.**

AgentsView is primarily an analytics and search tool rather than an archival
system in the preservation sense -- it does not version the session data or
provide immutable storage.
Its value for the con/serve mission is as a **discovery and access layer**:
it makes session artifacts findable across agents and queryable in aggregate,
which is a prerequisite for deciding what is worth archiving into a DataLad
dataset.

The session files AgentsView indexes -- Claude Code JSONL under
`~/.claude/projects/`, Cursor logs under `~/.cursor/projects/`, etc. -- are the actual
preservation targets. Tools like [ccexport]({{< ref "ccexport" >}}) and
[cctrace]({{< ref "cctrace" >}}) handle extracting and converting those files for
archival; AgentsView handles finding and understanding them at scale.

## AI Readiness

**Level: ai-ready.**

The indexed content is the agents' own session transcripts (Claude Code JSONL, Cursor logs, and so on) -- structured text that an LLM can read directly. AgentsView adds full-text and semantic search plus an MCP server, so an agent can query what earlier sessions did without any conversion step.

## See Also

- [cctrace]({{< ref "cctrace" >}}) -- lightweight Claude Code session capture
- [ccexport]({{< ref "ccexport" >}}) -- converts Claude Code JSONL to markdown/JSON for archival
- [entire-io]({{< ref "entire-io" >}}) -- git-native session archival as checkpoint refs
- [roborev]({{< ref "roborev" >}}) -- continuous code review database for AI-generated commits
