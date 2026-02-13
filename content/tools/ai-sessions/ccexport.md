---
title: "ccexport"
date: 2026-02-12
description: "Claude Code transcript export utility that converts JSONL sessions to readable markdown and JSON formats"
summary: "Exports Claude Code JSONL session transcripts to human-readable markdown and structured JSON for archival and analysis"
categories: ["AI Sessions"]
tags: ["claude-code", "export", "transcript", "markdown", "json"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/marcheiligers/ccexport"
  homepage: "https://github.com/marcheiligers/ccexport"
  issues: "https://github.com/marcheiligers/ccexport/issues"
  language: "Ruby"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
---

ccexport is a Ruby utility for converting Claude Code's raw JSONL session transcripts
into human-readable formats.
It reads the session files stored in `~/.claude/projects/`
and produces markdown or JSON output
suitable for archival in git repositories, documentation, or further analysis.

## How It Works

Claude Code stores every session as a JSONL file --
one JSON object per line, each representing a conversation turn
(human message, assistant response, tool use, system event).
While this format is efficient for Claude Code's internal use,
it is difficult for humans to read directly.

ccexport parses these JSONL files and reconstructs the conversation
in a readable format:

- **Markdown output** -- Each turn is formatted as a markdown section
  with role headers (Human, Assistant), code blocks for tool calls,
  and collapsible sections for verbose output.
  This format is ideal for reading in a text editor,
  rendering on GitHub, or including in project documentation.

- **JSON output** -- A structured JSON document with the conversation
  organized into a clean hierarchy of turns, tool calls, and metadata.
  This format is better suited for programmatic analysis --
  scripts that compute session statistics, extract code snippets,
  or feed sessions into other tools.

## Installation

Install from RubyGems:

```bash
gem install ccexport
```

## Basic Usage

Export a session to markdown:

```bash
ccexport --format markdown <session-id>
```

Export to JSON:

```bash
ccexport --format json <session-id>
```

Export all sessions for the current project:

```bash
ccexport --all --format markdown --output-dir .ai-sessions/
```

List available sessions:

```bash
ccexport --list
```

## Output Examples

### Markdown Output

```markdown
# Claude Code Session: abc123
**Date:** 2026-02-12 14:23 UTC
**Model:** claude-opus-4-6
**Project:** /home/user/myproject

---

## Human
Fix the failing test in test_parser.py -- the assertion on line 42 is wrong.

## Assistant
I will look at the test file to understand the failing assertion.

<details><summary>Tool: Read test_parser.py</summary>

[file contents]

</details>

The test expects `parse("foo")` to return `None`,
but the parser now returns an empty list for invalid input...
```

### JSON Output

```json
{
  "session_id": "abc123",
  "timestamp": "2026-02-12T14:23:00Z",
  "model": "claude-opus-4-6",
  "project": "/home/user/myproject",
  "turns": [
    {
      "role": "human",
      "content": "Fix the failing test in test_parser.py...",
      "timestamp": "2026-02-12T14:23:05Z"
    },
    {
      "role": "assistant",
      "content": "I will look at the test file...",
      "tool_calls": [
        {
          "tool": "read",
          "arguments": {"file_path": "test_parser.py"},
          "result": "..."
        }
      ],
      "timestamp": "2026-02-12T14:23:08Z"
    }
  ]
}
```

## Archival Workflow

ccexport is designed for post-hoc export --
run it after a session to convert the transcript for archival.

A typical workflow:

```bash
# Export today's sessions to markdown
ccexport --all --format markdown --output-dir .ai-sessions/markdown/

# Also keep structured JSON for analysis
ccexport --all --format json --output-dir .ai-sessions/json/

# Commit to git
git add .ai-sessions/
git commit -m "Archive Claude Code sessions"
```

For automated archival, pair ccexport with
[Claude Code Hooks](../claude-code-hooks/):

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "command": "ccexport --format markdown $SESSION_ID > .ai-sessions/$(date +%Y-%m-%d)-$SESSION_ID.md && git add .ai-sessions/ && git commit -m 'Archive session $SESSION_ID'",
        "timeout": 60
      }
    ]
  }
}
```

## Comparison with cctrace

ccexport and [cctrace](../cctrace/) serve similar purposes --
both export Claude Code session data --
but differ in focus:

| Aspect | ccexport | cctrace |
|---|---|---|
| **Output formats** | Markdown and JSON | Structured text |
| **Focus** | Human readability and format flexibility | Lightweight capture |
| **Batch export** | `--all` flag for all sessions | Per-session or all |
| **Analysis support** | JSON output for programmatic use | Primarily for archival |

For projects that need both human-readable documentation of sessions
and machine-parseable data for analysis,
ccexport's dual output format is a practical advantage.

## Limitations

- **Alpha status** -- Early development; CLI interface and output formats may change.
- **Claude Code only** -- Reads Claude Code's specific JSONL format.
  Does not support Cursor, Copilot, or other AI tools.
- **Post-hoc only** -- Does not capture sessions in real-time.
  For live capture, use [SpecStory](../specstory/) (VS Code)
  or [Entire.io](../entire-io/) (git shadow branches).
- **No deduplication** -- If the same session is exported multiple times,
  ccexport does not detect or merge duplicates.
  Use content-addressed filenames or append-only JSONL
  to mitigate this in archival scripts.

## See Also

- [cctrace](../cctrace/) -- Alternative Claude Code transcript capture tool
- [Entire.io](../entire-io/) -- Git-native archival with shadow branches and attribution
- [Claude Code Hooks](../claude-code-hooks/) -- Automate ccexport via lifecycle hooks
