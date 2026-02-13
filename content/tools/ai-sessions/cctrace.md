---
title: "cctrace"
date: 2026-02-12
description: "Claude Code conversation capture tool that extracts and formats session transcripts"
summary: "Captures Claude Code sessions from local JSONL storage and produces structured transcripts for archival in git repositories"
categories: ["AI Sessions"]
tags: ["claude-code", "transcript", "capture", "conversation"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/jimmc414/cctrace"
  homepage: "https://github.com/jimmc414/cctrace"
  issues: "https://github.com/jimmc414/cctrace/issues"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
---

cctrace is a lightweight Python tool for extracting Claude Code session transcripts
from the local JSONL files that Claude Code stores in `~/.claude/projects/`.
It reads the raw session data, parses the conversation structure,
and outputs formatted transcripts suitable for archival in a git repository.

## How It Works

Claude Code stores session data as JSONL (JSON Lines) files
in a project-specific directory under `~/.claude/projects/`.
Each line in these files represents a conversation turn --
a human message, an assistant response, a tool invocation, or a system event.

cctrace reads these files and reconstructs the conversation flow,
producing output that preserves:

- The sequence of human prompts and AI responses
- Tool calls and their results (file reads, edits, shell commands)
- Timestamps for each turn
- Session metadata (model used, project path, session ID)

## Installation

Install from PyPI:

```bash
pip install cctrace
```

Or with uv:

```bash
uv pip install cctrace
```

## Basic Usage

List available sessions for the current project:

```bash
cctrace list
```

Export a specific session:

```bash
cctrace export <session-id>
```

Export all sessions for the current project:

```bash
cctrace export --all
```

## Output Formats

cctrace produces structured transcript output that is both human-readable
and machine-parseable.
The output includes clear delineation between human and assistant turns,
tool call details, and session metadata headers.

The structured output is `ai-ready` --
an LLM can consume it directly to understand what happened in a session,
review the decisions that were made,
or continue work from where a previous session left off.

## Archival Workflow

A typical workflow for archiving Claude Code sessions with cctrace:

1. After a coding session, run `cctrace export --all` to extract new transcripts
2. Store the output in a dedicated directory (e.g., `sessions/` or `.ai-sessions/`)
3. Commit the transcripts to git
4. Optionally, use git-annex for large transcript files

For automated archival, combine cctrace with
[Claude Code Hooks](../claude-code-hooks/) --
a `SessionEnd` hook can trigger `cctrace export` automatically
after each session completes.

Example hook script:

```bash
#!/bin/bash
# .claude/hooks/session-end.sh
SESSION_ID="$1"
cctrace export "$SESSION_ID" >> sessions/archive.jsonl
git add sessions/archive.jsonl
git commit -m "Archive AI session $SESSION_ID"
```

## Comparison with Other Tools

cctrace focuses on simplicity and directness.
It reads local files and produces formatted output --
no shadow branches, no metadata indexes, no multi-tool support.

For projects that need only Claude Code transcript archival
and prefer a minimal dependency footprint,
cctrace is a practical choice.
For more comprehensive session management,
see [Entire.io](../entire-io/) (shadow branches, attribution, multi-tool)
or [ccexport](../ccexport/) (multiple output formats).

## Limitations

- **Alpha status** -- The tool is in early development.
  The output format and CLI interface may change.
- **Claude Code only** -- Does not support other AI tools
  (Cursor, Copilot, etc.).
- **No incremental export** -- Each export re-reads the full session;
  there is no built-in mechanism to export only new turns
  since the last archival run.
- **Local storage dependency** -- If Claude Code's local storage format changes,
  cctrace will need to be updated to match.

## See Also

- [ccexport](../ccexport/) -- Alternative export tool with markdown/JSON output
- [Entire.io](../entire-io/) -- Git-native archival with shadow branches
- [Claude Code Hooks](../claude-code-hooks/) -- Automate cctrace via lifecycle hooks
