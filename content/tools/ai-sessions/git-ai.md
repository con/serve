---
title: "Git AI"
date: 2026-03-02
description: "Line-level AI authorship attribution for git repositories"
summary: "Tracks which lines of code were written by AI vs humans, storing attribution logs as git notes that survive rebases, squashes, and cherry-picks"
categories: ["AI Sessions"]
tags: ["ai", "attribution", "git", "git-notes", "blame", "authorship", "compliance"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/git-ai-project/git-ai"
  homepage: "https://usegitai.com"
  issues: "https://github.com/git-ai-project/git-ai/issues"
  language: "Rust"
  license: "Apache-2.0"
  maturity: "beta"
  last_verified: "2026-03"
---

Git AI approaches the AI session recording problem
from a different angle than transcript archival tools:
it tracks **line-level authorship** --
recording exactly which lines of code were written by an AI assistant
versus a human developer.

Where [git-memento]({{< ref "git-memento" >}}) preserves *conversations*
and [Entire.io]({{< ref "entire-io" >}}) preserves *sessions*,
Git AI preserves *attribution* at the finest granularity git supports.

## How It Works

Git AI installs pre/post-edit hooks into supported AI agents.
When an agent modifies a file, Git AI records a **checkpoint** --
a small diff stored in `.git/ai/` --
capturing exactly what the agent changed.

On commit, these checkpoints are processed
into an **Authorship Log** attached as a git note
under `refs/notes/ai`.
The log records, for each file in the commit,
which line ranges were AI-authored
and which were human-authored.

## Agent Support

Git AI supports the broadest range of AI coding agents:

- Claude Code
- GitHub Copilot
- Cursor
- Continue
- Gemini
- Codex
- OpenCode
- Droid
- Junie
- Rovo Dev

This breadth makes it suitable for teams
where developers use different tools.

## Key Features

### AI-Aware Blame

```bash
git ai blame path/to/file.py
```

A drop-in replacement for `git blame`
that annotates each line with its authorship source
(human or AI, and which AI agent).
Available as CLI output and as IDE decorations
in VS Code, Cursor, Windsurf, and Emacs (magit).

### Attribution Survives History Rewrites

Authorship logs stored as git notes
are designed to survive rebases, squashes,
cherry-picks, and amends.
This is critical for teams that rebase feature branches
or squash-merge pull requests.

### Enterprise Dashboards

For organizations, Git AI provides dashboards
showing AI adoption metrics across repositories:
percentage of AI-authored code, trends over time,
and per-developer breakdowns.

## How It Differs from Transcript Tools

Git AI and transcript-based tools like git-memento or Entire.io
are **complementary**, not competing:

| | Git AI | git-memento / Entire.io |
|---|---|---|
| **What it records** | Which lines are AI-written | The conversation that produced the code |
| **Primary question answered** | "Who wrote this line?" | "Why was this change made?" |
| **Granularity** | Per-line | Per-session |
| **Use case** | Compliance, `blame`, adoption metrics | Code review, debugging, onboarding |

A team could use both:
Git AI for line-level attribution and compliance reporting,
and git-memento or Entire.io for preserving the reasoning context.

## git-annex / DataLad Integration

**Integration level: git-only.**

For research software projects tracked with DataLad,
Git AI's authorship logs provide a provenance layer
that maps naturally to research attribution concerns:

- Which parts of an analysis pipeline were AI-generated?
- What proportion of a software tool was human-authored?
- Can authorship claims in publications be supported by git evidence?

The git notes storage (`refs/notes/ai`) integrates with DataLad
the same way as git-memento's notes --
propagated via configured refspecs on push.

## Agent Trace Specification

Git AI's approach aligns with the emerging
**Agent Trace** specification
([github.com/cursor/agent-trace](https://github.com/cursor/agent-trace)),
an open RFC backed by Cursor, Cognition (Devin), Cloudflare,
Vercel, and Google Jules.
Agent Trace defines a vendor-neutral JSON schema
for AI code attribution metadata.
As this spec matures, tools like Git AI
may converge on a common format
for interoperability.

## Limitations

- **Does not preserve conversations** --
  authorship logs tell you *what* was AI-written
  but not *why* or *how*.
  Pair with a transcript tool for full context.
- **Checkpoint overhead** -- `.git/ai/` accumulates diffs
  during active sessions.
  Long sessions with many edits may produce significant checkpoint data.
- **Enterprise features** require a commercial license.

## AI Readiness

**Level: ai-ready.**

Authorship logs are structured records attached as git notes, and `git ai blame` renders them as plain text. Both are directly consumable by an LLM or a script; no binary content is involved.

## See Also

- [git-memento]({{< ref "git-memento" >}}) -- Conversation-level archival via git notes
- [Entire.io]({{< ref "entire-io" >}}) -- Full session archival as checkpoint refs
- [Agent Trace spec](https://github.com/cursor/agent-trace) -- Open attribution standard
- [Git Content Store as Side-Channel Databases]({{< ref "concepts/git-content-store-side-channels" >}}) -- `refs/notes/ai` in the context of the general pattern
