---
title: "Claude Code Hooks"
date: 2026-02-12
description: "Built-in lifecycle hooks in Claude Code for automatic session archival and custom automation"
summary: "Use Claude Code's PreCompact, Stop, and SessionEnd hooks to trigger automatic archival of AI coding session transcripts into git repositories"
categories: ["AI Sessions"]
tags: ["claude-code", "hooks", "lifecycle", "precompact", "session-end", "automation"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/anthropics/claude-code"
  homepage: "https://docs.anthropic.com/en/docs/claude-code"
  issues: "https://github.com/anthropics/claude-code/issues"
  language: "TypeScript"
  license: "proprietary"
  maturity: "stable"
  last_verified: "2026-02"
---

Claude Code includes a built-in hooks system that fires at key points
in the session lifecycle.
These hooks can execute arbitrary commands,
making them the natural integration point for automatic session archival.

Rather than requiring a separate tool to monitor for session changes,
hooks let you trigger archival actions directly from Claude Code itself --
when a session ends, when context is compacted, or when the user stops the assistant.

## Available Hooks

Claude Code exposes several lifecycle events that can trigger hooks:

### PreCompact

Fires **before** Claude Code compacts its conversation context.
Context compaction discards older turns to stay within the context window,
so this hook is the last opportunity to capture the full conversation
before parts of it are summarized or dropped.

This is the most important hook for archival:
it fires when the context is about to lose detail,
which is exactly when you want to save a snapshot.

### Stop

Fires when the user explicitly stops Claude Code
(e.g., pressing Escape during generation or using `/stop`).
Useful for capturing partial sessions that ended prematurely.

### SessionEnd

Fires when a Claude Code session terminates normally.
This includes both explicit exits (`/exit`, closing the terminal)
and idle timeouts.

## Hook Configuration

Hooks are configured in Claude Code's settings file
(`.claude/settings.json` at the project level
or `~/.claude/settings.json` globally).

The configuration specifies which command to run for each hook event:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "command": "bash /path/to/archive-session.sh $SESSION_ID",
        "timeout": 30
      }
    ],
    "Stop": [
      {
        "command": "bash /path/to/archive-session.sh $SESSION_ID"
      }
    ]
  }
}
```

Each hook entry specifies:

- **command** -- The shell command to execute.
  Environment variables like `$SESSION_ID` and `$PROJECT_PATH`
  are available for context.
- **timeout** -- Maximum seconds to wait for the command to complete.
  Hooks that exceed the timeout are terminated.

Multiple commands can be registered for the same event;
they execute sequentially in the order listed.

## Example: Archival with cctrace

The following setup uses [cctrace](../cctrace/) to export each session
when context is compacted or the session ends:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "command": "cctrace export $SESSION_ID >> .ai-sessions/transcripts.jsonl && git add .ai-sessions/ && git commit -m 'Archive AI session (pre-compact)'",
        "timeout": 60
      }
    ],
    "SessionEnd": [
      {
        "command": "cctrace export $SESSION_ID >> .ai-sessions/transcripts.jsonl && git add .ai-sessions/ && git commit -m 'Archive AI session (end)'",
        "timeout": 60
      }
    ]
  }
}
```

## Example: Archival with Entire.io

For projects using [Entire.io](../entire-io/)'s shadow branch approach:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "command": "entire capture claude --session $SESSION_ID",
        "timeout": 120
      }
    ],
    "SessionEnd": [
      {
        "command": "entire capture claude --session $SESSION_ID",
        "timeout": 120
      }
    ]
  }
}
```

## Example: Minimal Archival Script

For projects that want archival without additional tool dependencies,
a simple shell script can copy the raw JSONL session file into the repository:

```bash
#!/bin/bash
# archive-session.sh -- copy raw Claude Code session data to git
set -eu

SESSION_ID="${1:?Usage: archive-session.sh SESSION_ID}"
PROJECT_DIR="$(git rev-parse --show-toplevel)"
ARCHIVE_DIR="$PROJECT_DIR/.ai-sessions"
SOURCE="$HOME/.claude/projects/$(basename "$PROJECT_DIR")/$SESSION_ID"

mkdir -p "$ARCHIVE_DIR"

if [ -f "$SOURCE" ]; then
    cp "$SOURCE" "$ARCHIVE_DIR/${SESSION_ID}.jsonl"
    cd "$PROJECT_DIR"
    git add "$ARCHIVE_DIR/${SESSION_ID}.jsonl"
    git commit -m "Archive Claude Code session $SESSION_ID"
fi
```

Register it as a hook:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "command": "bash .claude/hooks/archive-session.sh $SESSION_ID",
        "timeout": 30
      }
    ]
  }
}
```

## Integration with DataLad

For DataLad datasets, hook scripts can use `datalad save` instead of `git commit`
to ensure proper dataset metadata:

```bash
datalad save -m "Archive AI session $SESSION_ID" .ai-sessions/
```

This records the session archival as a DataLad operation,
complete with run provenance if wrapped in `datalad run`.

## Best Practices

- **Use PreCompact as the primary archival trigger.**
  SessionEnd may not fire if the terminal is killed or the system crashes.
  PreCompact fires during normal operation and captures the fullest context.

- **Keep hook commands fast.**
  Hooks block the Claude Code session while executing.
  If archival is slow (e.g., pushing to a remote),
  have the hook write locally and defer the push to a background job
  or a separate cron task.

- **Test hooks before relying on them.**
  Run the archival command manually with a known session ID
  to verify it works before registering it as a hook.

- **Handle duplicate exports gracefully.**
  If both PreCompact and SessionEnd fire for the same session,
  the archival script should be idempotent --
  appending to a JSONL file or using content-addressed filenames avoids duplicates.

## Limitations

- **Proprietary** -- Claude Code and its hooks system are proprietary to Anthropic.
  The hooks API may change between releases.
- **Claude Code only** -- These hooks are specific to Claude Code;
  other AI tools (Cursor, Copilot) have their own extension mechanisms.
- **No built-in export** -- The hooks provide *triggers* but not *export logic*.
  You need a companion tool (cctrace, ccexport, Entire.io, or a custom script)
  to actually extract and format the session data.
- **Environment variables** -- The exact set of environment variables
  available to hook commands may vary by Claude Code version.
  Consult the current documentation for the definitive list.

## See Also

- [cctrace](../cctrace/) -- Pair with hooks for automatic Claude Code transcript export
- [ccexport](../ccexport/) -- Alternative export tool for use in hook scripts
- [Entire.io](../entire-io/) -- Shadow branch archival, triggerable via hooks
