---
title: "forge (kenn-io)"
date: 2026-08-31
description: "Local-first maintainer console syncing PRs, issues, and CI from GitHub, GitLab, Forgejo, and Gitea into local SQLite"
summary: "Single-binary daemon that syncs pull requests, issues, CI status, and reviews from multiple git forges into a local SQLite database, with agent workspace creation and offline access."
categories: ["Code Artifacts"]
tags: ["github", "gitlab", "forgejo", "gitea", "pull-requests", "issues", "ci", "sqlite", "local-first", "ai-agents"]
media_types: ["code-artifacts"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/kenn-io/forge"
  homepage: "https://github.com/kenn-io/forge"
  issues: "https://github.com/kenn-io/forge/issues"
  language: "Go"
  license: "Elastic-2.0"
  maturity: "beta"
  last_verified: "2026-08"
---

forge (kenn-io) is a local-first maintainer console that aggregates pull requests,
issues, CI status, and code reviews from multiple git platforms into a single
interface served from a single binary.
Once synced, the full forge context is available offline.

Note: this is an unrelated project to the DataLad extension also named "forge."

## Supported Platforms

- GitHub
- GitLab
- Forgejo
- Gitea

Capability coverage varies by platform.

## How It Works

forge syncs the repositories you maintain into a local SQLite database and
serves a web UI at `http://127.0.0.1:8091`.
After an initial sync, PRs, issues, CI context, and review comments are
accessible without network connectivity.

From any issue or PR, forge can create a local worktree session linked to a
coding agent, turning triage into an interactive implementation session on
your machine.

## Agent Workspaces

A notable feature for agentic workflows: forge converts any issue or PR into
an agent workspace with a git worktree pre-populated with relevant context
(PR diff, issue description, CI failures).
This provides a structured handoff between human triage and AI implementation.

## License Note

forge is licensed under the Elastic License 2.0, which restricts
managed-service/SaaS redistribution.
The repository notes that prior contributions were made under MIT and those
portions are preserved.

## Relation to Other kenn-io Tools

forge provides the outer triage layer; [kata](../kata/) provides a local
parallel issue tracker that agents can update during implementation;
[roborev](../../ai-sessions/roborev/) adds code review accountability.

## Relevance to Archival

Like [github-backup](../github-backup/), forge's local SQLite sync is a form
of offline archival of forge artifacts.
The key difference is that forge is designed for active use (triage, agent
handoff) rather than preservation -- it syncs on demand and does not
maintain immutable history.

For long-term preservation of forge artifacts, tools like github-backup
(JSON snapshots) or git-bug (git-native storage) are more appropriate.
forge complements them as the access and workflow layer.

## See Also

- [github-backup](../github-backup/) -- JSON export of GitHub artifacts for preservation
- [git-bug](../git-bug/) -- distributed issue tracking stored in git objects
- [kata](../kata/) -- local issue tracking designed for AI agent workflows
- [gh-discussions-export](../gh-discussions-export/) -- export of GitHub Discussions
