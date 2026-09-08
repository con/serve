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
  homepage: "https://code.claude.com/docs/en/hooks"
  issues: "https://github.com/anthropics/claude-code/issues"
  language: "n/a (closed-source CLI)"
  license: "LicenseRef-Anthropic-Commercial-Terms"
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

Claude Code exposes dozens of lifecycle events that can trigger hooks
(session start and end, prompt submission, before and after tool use,
context compaction, and more).
Three matter most for archival:

### PreCompact

Fires **before** Claude Code compacts its conversation context
(matcher `manual` or `auto`).
Context compaction summarizes older turns to stay within the context window,
so this hook is the last opportunity to capture the full conversation
before parts of it are condensed.

### Stop

Fires each time Claude finishes responding, once per turn.
Useful for incremental capture during long sessions.

### SessionEnd

Fires when a Claude Code session terminates
(the reasons passed to the hook include `clear`, `resume`, `logout`,
and `prompt_input_exit`).

## Hook Configuration

Hooks are configured in Claude Code's settings files
(`.claude/settings.json` at the project level,
`~/.claude/settings.json` globally, or `.claude/settings.local.json`).
Each event maps to a list of matcher groups, each holding a list of handlers:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/archive-session.sh", "timeout": 30 }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/archive-session.sh" }
        ]
      }
    ]
  }
}
```

A command hook receives a JSON object on standard input with, among other
fields, `session_id`, `transcript_path` (the JSONL file for the session),
`cwd`, and `hook_event_name`.
`CLAUDE_PROJECT_DIR` is exported in the environment.
`timeout` caps the run time in seconds (default 600 for command hooks);
`async: true` lets a hook run without blocking the session.
All matching hooks for an event run in parallel.

## Example: Minimal Archival Script

A small script can copy the raw JSONL transcript into the repository
without any additional tool:

```bash
#!/bin/bash
# .claude/hooks/archive-session.sh -- copy the raw Claude Code transcript into git
set -eu

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r .session_id)
transcript=$(printf '%s' "$input" | jq -r .transcript_path)

archive_dir="$CLAUDE_PROJECT_DIR/.ai-sessions"
mkdir -p "$archive_dir"

if [ -f "$transcript" ]; then
    cp "$transcript" "$archive_dir/${session_id}.jsonl"
    cd "$CLAUDE_PROJECT_DIR"
    git add "$archive_dir/${session_id}.jsonl"
    git commit -q -m "Archive Claude Code session $session_id"
fi
```

The same shape works for the export tools in this section: pass
`session_id` to [ccexport]({{< ref "ccexport" >}}) (`--session`) or
[cctrace]({{< ref "cctrace" >}}) (`--session-id`) instead of copying the file.
[Entire.io]({{< ref "entire-io" >}}) installs its own hooks when enabled
for a repository and does not need a hand-written one.

## git-annex / DataLad Integration

**Integration level: git-only.**

For DataLad datasets, hook scripts can use `datalad save` instead of `git commit`
to ensure proper dataset metadata:

```bash
datalad save -m "Archive AI session $session_id" .ai-sessions/
```

This records the session archival as a DataLad operation,
complete with run provenance if wrapped in `datalad run`.

## Best Practices

- **Use PreCompact as the primary archival trigger.**
  SessionEnd may not fire if the terminal is killed or the system crashes.
  PreCompact fires during normal operation and captures the fullest context.

- **Keep hook commands fast, or mark them async.**
  Synchronous hooks block the Claude Code session while executing.
  If archival is slow (e.g., pushing to a remote),
  have the hook write locally and defer the push to a background job,
  or set `async: true`.

- **Test hooks before relying on them.**
  Run the archival command manually with a known session ID
  to verify it works before registering it as a hook.

- **Handle duplicate exports gracefully.**
  If both PreCompact and SessionEnd fire for the same session,
  the archival script should be idempotent --
  appending to a JSONL file or using content-addressed filenames avoids duplicates.

## Limitations

- **Proprietary** -- Claude Code is closed-source and its hooks system is
  defined by Anthropic. The hooks API may change between releases.
- **Claude Code only** -- These hooks are specific to Claude Code;
  other AI tools (Cursor, Copilot) have their own extension mechanisms.
- **No built-in export** -- The hooks provide *triggers* but not *export logic*.
  You need a companion tool (cctrace, ccexport, Entire.io, or a custom script)
  to actually extract and format the session data.
- **Input format** -- The fields passed on standard input may change
  between Claude Code versions.
  Consult the [hooks reference](https://code.claude.com/docs/en/hooks) for the definitive list.

## AI Readiness

**Level: ai-ready.**

Hooks produce no output of their own; what gets archived is whatever the companion tool writes -- raw JSONL transcripts, or the markdown/JSON produced by cctrace or ccexport. All of these are structured text that an LLM can consume without preprocessing.

## See Also

- [cctrace]({{< ref "cctrace" >}}) -- Pair with hooks for automatic Claude Code transcript export
- [ccexport]({{< ref "ccexport" >}}) -- Alternative export tool for use in hook scripts
- [Entire.io]({{< ref "entire-io" >}}) -- Checkpoint-ref archival that installs its own hooks
