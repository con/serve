---
title: "cctrace"
date: 2026-02-12
description: "Export Claude Code sessions to markdown, XML, and portable bundles that can be re-imported elsewhere"
summary: "Exports Claude Code sessions from local JSONL storage as markdown, XML, and raw JSONL, and packages them as portable bundles that another user can import and resume"
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

cctrace is a set of Python scripts for exporting Claude Code session transcripts
from the local JSONL files that Claude Code stores in `~/.claude/projects/`.
It reads the raw session data, parses the conversation structure,
and writes formatted transcripts and portable session bundles
suitable for archival in a git repository -- and for re-importing
a session on another machine.

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

cctrace is not on PyPI; clone the repository and run its setup script,
which copies the scripts to `~/claude_sessions/` and installs the
`/export-session` and `/import-session` slash commands:

```bash
git clone https://github.com/jimmc414/cctrace.git
cd cctrace && ./setup.sh
```

## Usage

```bash
# Export the most recent session of the current project
python3 ~/claude_sessions/export_claude_session.py

# Export a specific session
python3 ~/claude_sessions/export_claude_session.py --session-id <session-id>

# Export a portable bundle into the repository (.claude-sessions/<name>/)
python3 ~/claude_sessions/export_claude_session.py --in-repo --export-name my-feature

# Import a bundle exported by someone else
python3 ~/claude_sessions/import_session.py .claude-sessions/my-feature/
```

Inside Claude Code the same operations are available as `/export-session`
and `/import-session`.

## Output Formats

A classic export (to `~/claude_sessions/exports/`) contains
`raw_messages.jsonl`, `conversation_full.md`, `conversation_full.xml`,
`session_info.json`, and `summary.txt`.
An in-repo export is a portable `.claude-sessions/<name>/` tree with a
manifest, a rendered markdown transcript, the session JSONL, and the
file history, todos, and plan needed to resume the session elsewhere.

## git-annex / DataLad Integration

**Integration level: git-only.**

A typical workflow for archiving Claude Code sessions with cctrace:

1. After a coding session, run the in-repo export so the bundle lands in `.claude-sessions/`
2. Commit the bundle to git
3. Optionally, use git-annex for large transcript files

For automated archival, combine cctrace with
[Claude Code Hooks]({{< ref "claude-code-hooks" >}}) --
a `SessionEnd` hook receives the session ID on standard input
and can run the export script with `--session-id`.

## Comparison with Other Tools

cctrace focuses on simplicity and directness.
It reads local files and produces formatted output --
no git refs of its own, no indexes, no multi-tool support.

For projects that need only Claude Code transcript archival
and prefer a minimal dependency footprint,
cctrace is a practical choice.
For more comprehensive session management,
see [Entire.io]({{< ref "entire-io" >}}) (checkpoint refs, multi-tool)
or [ccexport]({{< ref "ccexport" >}}) (readable markdown/HTML with secret redaction).

## Limitations

- **Alpha status** -- The tool is in early development.
  The output format and CLI interface may change.
- **Claude Code only** -- Does not support other AI tools
  (Cursor, Copilot, etc.).
- **Script collection, not a package** -- installed by a setup script into
  the home directory; there is no PyPI release.
- **Local storage dependency** -- If Claude Code's local storage format changes,
  cctrace will need to be updated to match.

## AI Readiness

**Level: ai-ready.**

The markdown and XML transcripts are plain text with clear turn delineation --
an LLM can consume it directly to understand what happened in a session,
review the decisions that were made,
or continue work from where a previous session left off.

## See Also

- [ccexport]({{< ref "ccexport" >}}) -- Alternative export tool with markdown/HTML output
- [Entire.io]({{< ref "entire-io" >}}) -- Git-native archival as checkpoint refs
- [Claude Code Hooks]({{< ref "claude-code-hooks" >}}) -- Automate cctrace via lifecycle hooks
