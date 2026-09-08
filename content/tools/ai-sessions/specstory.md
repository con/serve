---
title: "SpecStory"
date: 2026-02-12
description: "Editor extensions and a CLI wrapper that automatically save AI coding sessions as markdown files"
summary: "Saves AI coding sessions from Cursor, VS Code Copilot, and terminal agents such as Claude Code as markdown files in a .specstory/history/ directory within the project"
categories: ["AI Sessions"]
tags: ["vscode", "cursor", "claude-code", "ai", "sessions", "markdown"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/specstoryai/getspecstory"
  homepage: "https://specstory.com"
  issues: "https://github.com/specstoryai/getspecstory/issues"
  language: "Go (CLI); extensions closed-source"
  license: "Apache-2.0"
  maturity: "beta"
  last_verified: "2026-02"
---

SpecStory automatically captures AI coding sessions
and saves them as markdown files in a `.specstory/history/` directory within your project.
It comes in two forms: closed-source editor extensions for Cursor and for
GitHub Copilot in VS Code, and an open-source CLI that wraps terminal agents
(Claude Code, Codex CLI, Cursor CLI, Gemini CLI, Droid, and others).

## How It Works

The editor extensions run in the background and watch the editor's AI chat;
the CLI launches the agent (`specstory run claude`) and records what passes
through it.
Either way, each session is written to disk as a markdown file that includes:

- Human prompts clearly delineated from AI responses
- Code blocks with language annotations
- Timestamps for each interaction
- File references and context that was provided to the AI

## Directory Structure

Session files are written flat under `.specstory/history/`,
named with a timestamp prefix and a slug derived from the conversation topic:

```
.specstory/
  history/
    2026-02-12_building-api-endpoint.md
    2026-02-12_fixing-test-failures.md
    2026-02-11_refactoring-database-layer.md
```

## Installation

Editor extensions: install "SpecStory" from within Cursor, or the
"SpecStory for GitHub Copilot" extension from the VS Code Marketplace.

CLI:

```bash
brew tap specstoryai/tap && brew install specstory
specstory run claude     # or codex, cursor, gemini, droid, ...
```

## git-annex / DataLad Integration

**Integration level: git-only.**

Because SpecStory writes plain markdown files to a directory in the project,
archiving sessions in git is straightforward --
just commit the `.specstory/` directory.

```bash
git add .specstory/
git commit -m "Archive AI coding sessions"
```

For projects that want to keep sessions out of the main repository
but still archived, consider:

- Adding `.specstory/` to `.gitignore` in the main repo
  and maintaining a separate git repository for sessions
- Using git-annex to store session files as annexed content
  (useful if sessions become very large)
- Using a DataLad subdataset to nest the session archive
  within the project dataset

## AI Readiness

**Level: ai-ready.**

SpecStory's markdown output has clear role delineation (human vs AI),
which makes it straightforward for LLMs to parse and understand.

This is useful for:

- **Session continuation** -- Feed a previous session's transcript
  to an AI to provide context for continuing the work
- **Code review** -- An LLM can review the reasoning process
  that led to code changes, not just the changes themselves
- **Knowledge extraction** -- Mine sessions for patterns,
  common problems, and solutions specific to the project

## Comparison with Other Tools

| Feature | SpecStory | cctrace | Entire.io |
|---|---|---|---|
| **Editor** | Cursor, VS Code Copilot, terminal agents via CLI | CLI (Claude Code) | CLI (multiple) |
| **Capture method** | Extension or CLI wrapper (real-time) | Post-hoc export | Checkpoint refs at commit time |
| **Output format** | Markdown files | Markdown, XML, JSONL | Transcript files under git refs |
| **Storage** | `.specstory/history/` directory | User-specified | `refs/entire/*` |
| **Multi-tool** | Cursor, Copilot, eight terminal agents | Claude Code only | Eight terminal agents |

SpecStory's main advantage is **zero-friction capture** --
once installed, it works automatically without any manual export step.
Its output lands in the working tree, which is convenient for discovery
but adds files to every commit unless the directory is ignored.

## Limitations

- **Closed-source extensions** -- Only the CLI is open source; the Cursor
  and Copilot extensions are not.
- **Markdown only** -- Output is markdown, not structured JSON.
  While human-readable, programmatic analysis requires markdown parsing.
- **No attribution tracking** -- Does not provide per-line or per-file
  attribution of human vs AI authorship.
- **Working tree pollution** -- The `.specstory/` directory adds files
  to the working tree, unlike Entire.io's checkpoint refs.
  This is a feature for discoverability but a drawback
  for projects that want a clean file tree.

## See Also

- [Entire.io]({{< ref "entire-io" >}}) -- Git-native archival without working tree changes, including for Claude Code
- [cctrace]({{< ref "cctrace" >}}) -- Claude Code-specific transcript capture
- [Claude Code Hooks]({{< ref "claude-code-hooks" >}}) -- Automate session archival for Claude Code
