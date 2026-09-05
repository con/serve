---
title: "ccexport"
date: 2026-02-12
description: "Claude Code transcript export utility that converts JSONL sessions to readable markdown and HTML"
summary: "Exports Claude Code JSONL session transcripts to human-readable markdown and HTML, with secret redaction, for archival and review"
categories: ["AI Sessions"]
tags: ["claude-code", "export", "transcript", "markdown", "html"]
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
and produces markdown or HTML output
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
  with role markers, code blocks for tool calls,
  and collapsible sections for verbose output.
  This format is ideal for reading in a text editor,
  rendering on GitHub, or including in project documentation.

- **HTML preview** -- A styled HTML rendering of the same content
  (`--preview`), using a customizable template.

- **Secret redaction** -- Detected secrets (via TruffleHog) are redacted
  before export and logged separately, which matters when transcripts
  contain pasted credentials.

## Installation

Install from RubyGems:

```bash
gem install ccexport
```

## Usage

By default ccexport exports all sessions of the current project:

```bash
# Export all sessions for the current project to markdown
ccexport --out .ai-sessions/

# One session, with timestamps
ccexport --session <session-id> --timestamps --out .ai-sessions/

# Today's sessions only, as an HTML preview
ccexport --today --preview

# A date range from another project's session directory
ccexport --in ~/.claude/projects/-home-me-proj --from 2026-02-01 --to 2026-02-12
```

Run `ccexport --help` for the full option list (`--clean`, `--template`,
`--stdout`, `--jsonl`, and others).

## git-annex / DataLad Integration

**Integration level: git-only.**

ccexport is designed for post-hoc export --
run it after a session to convert the transcript for archival:

```bash
ccexport --out .ai-sessions/
git add .ai-sessions/
git commit -m "Archive Claude Code sessions"
```

For automated archival, pair ccexport with
[Claude Code Hooks]({{< ref "claude-code-hooks" >}}):
a `SessionEnd` hook receives the session ID on standard input
and can run `ccexport --session "$id" --out .ai-sessions/`.

## Comparison with cctrace

ccexport and [cctrace]({{< ref "cctrace" >}}) serve similar purposes --
both export Claude Code session data --
but differ in focus:

| Aspect | ccexport | cctrace |
|---|---|---|
| **Output formats** | Markdown and HTML | Markdown, XML, raw JSONL, portable session bundle |
| **Focus** | Human readability and secret redaction | Export and re-import of sessions |
| **Batch export** | All sessions of a project by default | Per session, or in-repo bundles |
| **Analysis support** | Readable transcripts | Raw JSONL for programmatic use |

For readable, redacted transcripts ccexport is the simpler choice;
for raw data or moving a session to another machine, cctrace.

## Limitations

- **Alpha status** -- Early development; CLI interface and output formats may change.
- **Claude Code only** -- Reads Claude Code's specific JSONL format.
  Does not support Cursor, Copilot, or other AI tools.
- **Post-hoc only** -- Does not capture sessions in real-time.
  For live capture, use [SpecStory]({{< ref "specstory" >}}) (VS Code)
  or [Entire.io]({{< ref "entire-io" >}}) (checkpoint refs in git).
- **No deduplication** -- If the same session is exported multiple times,
  ccexport does not detect or merge duplicates.
  Use content-addressed filenames or append-only JSONL
  to mitigate this in archival scripts.

## AI Readiness

**Level: ai-ready.**

The markdown export reads naturally as conversation context for an LLM, and the HTML rendering carries the same content for human review. For programmatic analysis the raw JSONL that Claude Code writes remains the richer source.

## See Also

- [cctrace]({{< ref "cctrace" >}}) -- Alternative Claude Code transcript capture tool
- [Entire.io]({{< ref "entire-io" >}}) -- Git-native archival as checkpoint refs
- [Claude Code Hooks]({{< ref "claude-code-hooks" >}}) -- Automate ccexport via lifecycle hooks
