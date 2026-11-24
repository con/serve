---
title: "VibeHub"
date: 2026-11-24
description: "Hosted service that links AI coding session transcripts to the git commits they produced"
summary: "A git-wrapping CLI and a Claude Code plugin capture Claude Code, Codex, Cursor and Aider sessions and attach them to commits; transcripts are stored by the hosted service, not in the repository"
categories: ["AI Sessions"]
tags: ["ai", "sessions", "git", "claude-code", "codex", "cursor", "aider", "hosted"]
media_types: ["ai-sessions"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/aw3-technology/vibehub-plugins"
  homepage: "https://www.vibehub.co"
  issues: "https://github.com/aw3-technology/vibehub-plugins/issues"
  docs: "https://www.vibehub.co/docs"
  changelog: "https://www.vibehub.co/changelog"
  language: "JavaScript"
  license: "MIT"
  maturity: "beta"
  last_verified: "2026-11"
---

VibeHub, made by AW3 Technology, is a hosted service that pairs each git commit
with the AI conversation that produced it.
Its `vb` command-line tool wraps `git`, and a Claude Code plugin captures sessions through hooks.
Unlike [Entire.io]({{< ref "entire-io" >}}) or [git-memento]({{< ref "git-memento" >}}),
it does not write transcripts into the repository:
code goes to git, and conversations go to the VibeHub service, keyed by commit SHA.
The plugin and editor integrations are MIT-licensed in the repository above;
the service itself is closed source.

## Key Features

- **Commit-time capture** -- `vb commit` runs `git commit` and uploads the
  part of the current agent transcript written since the previous capture,
  linked to the new commit. It reads local transcripts from Claude Code,
  Codex, Cursor and Aider.
- **Hook-based capture** -- the Claude Code plugin records prompts, tool calls
  and agent output as a session while you work, without changing how you commit.
- **Import** -- `vb import <file>` uploads an existing Claude Code, Codex,
  Cursor or Aider transcript as a session.
- **Secret redaction** -- the service redacts recognized API keys and tokens
  from transcript text at ingest.
- **Per-commit lookup** -- `vb show <sha>` prints a commit's diff with its
  conversation; `vb blame <path>` gives an approximate blame from the stored diffs.
- **Mirroring** -- `vb push` pushes to the git remote and to an optional
  GitHub, GitLab or Bitbucket mirror.

## Installation

```bash
# vb CLI (macOS / Linux)
curl -fsSL https://www.vibehub.co/install.sh | sh

# Claude Code plugin
claude plugin marketplace add aw3-technology/vibehub-plugins
claude plugin install vibehub@vibehub
```

Both need an account and an API token (`VIBEHUB_TOKEN`).

## Usage

```bash
vb init                    # log in, install the plugin, add a capture hook to this repo
vb commit -m "message"     # commit and attach the transcript
vb log                     # recent commits with conversation counts
vb show <sha>              # diff + conversation for one commit
```

Commands `vb` does not implement fall through to `git`.

## git-annex / DataLad Integration

**Integration level: external.**

Transcripts live in the hosted service, so a clone of the repository
carries no session data. The service offers JSON and Markdown export,
which could be committed into a dataset, but no workflow for that
has been established.

## AI Readiness

**Level: ai-ready.**

Sessions are stored as structured messages (role, text, tool calls),
and export is available as JSON or Markdown, both directly readable by an LLM.
The commit SHA links each conversation to the code change.

## Limitations

- **Hosted storage** -- session data is held by a third-party service,
  not in the repository or its remotes; archival depends on exporting it.
- **Closed-source service** -- only the plugin and integrations are open source.
- **Account required** -- capture needs a VibeHub account and token.
- **Young project** -- launched in 2026; the CLI and API are still changing.

## See Also

- [Entire.io]({{< ref "entire-io" >}}) -- Session checkpoints stored as git refs in the repository
- [git-memento]({{< ref "git-memento" >}}) -- Transcripts as git notes on commits
- [SpecStory]({{< ref "specstory" >}}) -- Sessions as markdown files inside the project
- [Claude Code Hooks]({{< ref "claude-code-hooks" >}}) -- The lifecycle events the VibeHub plugin uses
