---
title: "kata"
date: 2026-08-31
description: "Local-first issue tracking for AI-assisted software work, agent-friendly CLI and terminal UI"
summary: "Durable task ledger for AI coding agents and human supervisors. Issues live in local SQLite under KATA_HOME; repos stay clean. Agent-friendly CLI and MCP server with optional one-way GitHub sync and team federation."
categories: ["Code Artifacts"]
tags: ["issue-tracking", "sqlite", "local-first", "ai-agents", "cli", "tui"]
media_types: ["code-artifacts"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/kenn-io/kata"
  homepage: "https://github.com/kenn-io/kata"
  issues: "https://github.com/kenn-io/kata/issues"
  language: "Go"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-08"
---

kata is a local-first issue tracker designed for workflows where AI coding
agents create, claim, update, and close issues as part of their work,
while human supervisors oversee progress via a terminal UI or browser.

## Design Philosophy

Issue state lives in SQLite under `KATA_HOME`; the git repository contains
only a small, secret-free `.kata.toml` configuration file.
This keeps issue history out of commit history and avoids requiring a hosted
tracker (GitHub Issues, Linear, Jira) as a dependency for development work.

A single Go binary with no runtime dependencies handles the full lifecycle.

## Key Capabilities

- Agents create, claim, relate, and close issues with evidence attached
- Human TUI and browser UI for oversight and triage
- GitHub sync (one-way: GitHub issues are mirrored into kata and stay GitHub-owned)
- Optional remote daemon mode with PostgreSQL backend for team sharing
- Federation for distributed deployments
- In-process HTTP service for embedding in Go applications

## Relation to Other kenn-io Tools

kata integrates with [roborev]({{< ref "roborev" >}}) for correlating
code review findings with issue records.
[forge]({{< ref "forge" >}}) provides the broader maintainer console context (PRs, CI)
within which kata issues live.

## git-annex / DataLad Integration

**Integration level: external.**

kata's local SQLite store is a natural archival target: issue history, agent
activity records, and evidence attachments can be snapshotted into a DataLad
dataset alongside the code.
The `.kata.toml` in the repository provides the linkage between issue state
and the commit graph.

No established workflow for DataLad-native kata archival exists yet.

## AI Readiness

**Level: ai-ready.**

Issue records are structured rows in SQLite, and the CLI is designed for agents to create, claim, and close issues programmatically. The evidence attached to issues is text (logs, links, notes) that an LLM can read directly.

## See Also

- [forge]({{< ref "forge" >}}) -- local-first maintainer console for PRs and issues across forges
- [git-bug]({{< ref "git-bug" >}}) -- distributed issue tracking stored directly in git objects
- [github-backup]({{< ref "github-backup" >}}) -- full JSON export of GitHub Issues and PRs
- [roborev]({{< ref "roborev" >}}) -- AI code review database, integrates with kata
