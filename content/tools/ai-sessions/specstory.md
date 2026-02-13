---
title: "SpecStory"
date: 2026-02-12
description: "VS Code extension for automatically capturing AI coding sessions as markdown files"
summary: "Saves AI coding sessions from VS Code and Cursor as structured markdown files in a .specstory/ directory within the project"
categories: ["AI Sessions"]
tags: ["vscode", "cursor", "ai", "sessions", "markdown"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/specstoryai/getspecstory"
  homepage: "https://specstory.com"
  issues: "https://github.com/specstoryai/getspecstory/issues"
  language: "TypeScript"
  license: "Apache-2.0"
  maturity: "beta"
  last_verified: "2026-02"
---

SpecStory is a VS Code extension that automatically captures AI coding sessions
and saves them as markdown files in a `.specstory/` directory within your project.
It works with both VS Code and Cursor (which is built on VS Code),
capturing conversations with any AI assistant integrated into the editor.

## How It Works

Once installed, SpecStory runs in the background and monitors AI interactions
in the editor. When an AI coding session occurs -- whether through Cursor's
built-in AI, GitHub Copilot Chat, or another VS Code AI extension --
SpecStory captures the conversation and writes it to disk as a markdown file.

Each session is saved as a separate `.md` file in the `.specstory/` directory,
organized by date. The markdown format includes:

- Human prompts clearly delineated from AI responses
- Code blocks with language annotations
- Timestamps for each interaction
- File references and context that was provided to the AI

## Directory Structure

SpecStory creates a `.specstory/` directory at the project root
with the following layout:

```
.specstory/
  history/
    2026-02-12/
      session-1423-building-api-endpoint.md
      session-1445-fixing-test-failures.md
    2026-02-11/
      session-0930-refactoring-database-layer.md
```

Session files are named with a timestamp prefix and a slug
derived from the conversation topic,
making them easy to browse and identify.

## Installation

Install from the VS Code Marketplace:

1. Open VS Code or Cursor
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "SpecStory"
4. Click Install

Alternatively, install from the command line:

```bash
code --install-extension specstory.specstory
```

## Archival in Git

Because SpecStory writes plain markdown files to a directory in the project,
archiving sessions in git is straightforward --
just commit the `.specstory/` directory.

For projects that want to track sessions in git:

```bash
# Commit session files alongside code changes
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

## Markdown Format and AI Readiness

SpecStory's markdown output is `ai-ready` --
the structured format with clear role delineation (human vs AI)
makes it straightforward for LLMs to parse and understand.

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
| **Editor** | VS Code / Cursor | CLI (Claude Code) | CLI (multiple) |
| **Capture method** | Extension (real-time) | Post-hoc export | Git shadow branches |
| **Output format** | Markdown files | Structured text | JSONL on branches |
| **Storage** | `.specstory/` directory | User-specified | Git orphan branches |
| **Multi-tool** | Any VS Code AI extension | Claude Code only | Claude Code, Cursor |

SpecStory's main advantage is **zero-friction capture** --
once installed, it works automatically without any manual export step.
Its main limitation is that it is tied to the VS Code editor ecosystem;
terminal-based tools like Claude Code require
[cctrace](../cctrace/) or [Entire.io](../entire-io/) instead.

## Limitations

- **VS Code only** -- Requires VS Code or a VS Code-based editor (Cursor, VSCodium).
  Does not capture sessions from terminal-based AI tools.
- **Markdown only** -- Output is markdown, not structured JSON.
  While human-readable, programmatic analysis requires markdown parsing.
- **No attribution tracking** -- Does not provide per-line or per-file
  attribution of human vs AI authorship.
- **Working tree pollution** -- The `.specstory/` directory adds files
  to the working tree, unlike Entire.io's shadow branch approach.
  This is a feature for discoverability but a drawback
  for projects that want a clean file tree.

## See Also

- [Entire.io](../entire-io/) -- Git-native archival without working tree changes
- [cctrace](../cctrace/) -- Claude Code-specific transcript capture
- [Claude Code Hooks](../claude-code-hooks/) -- Automate session archival for Claude Code
