---
title: "Entire.io"
date: 2026-02-12
description: "Git-native AI session archival using shadow branches with cross-session indexing and attribution tracking"
summary: "Stores AI coding session transcripts on separate git shadow branches, preserving full provenance without polluting the working tree"
categories: ["AI Sessions"]
tags: ["ai", "sessions", "git", "shadow-branches", "metadata", "attribution", "claude", "cursor"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/entireio/cli"
  homepage: "https://entire.io"
  issues: "https://github.com/entireio/cli/issues"
  language: "TypeScript"
  license: "MIT"
  maturity: "beta"
  last_verified: "2026-02"
  examples:
    - title: "Entire.io CLI"
      url: "https://github.com/entireio/cli"
---

Entire.io takes a fundamentally different approach to AI session archival
compared to export-based tools like [cctrace](../cctrace/) or [ccexport](../ccexport/).
Instead of exporting transcripts to files in the working tree,
it stores session data on **shadow branches** -- dedicated git branches
that coexist with your project history but never appear in your working directory.

This is a significant architectural choice:
your project's file tree stays clean, your `.gitignore` needs no AI-specific entries,
and yet the complete record of every AI-assisted development session
is preserved in the same repository, subject to the same backup and replication
strategies as your code.

## Shadow Branch Architecture

The core insight behind Entire.io is that git branches are cheap
and need not correspond to lines of development.
A shadow branch is an orphan branch (no shared commit ancestry with your main branch)
that stores only session data.

When you run an AI coding session with Entire.io active,
the tool writes structured JSONL transcript data to a branch
named something like `entire/sessions/<session-id>`.
This branch contains:

- The complete conversation transcript (prompts, responses, tool calls, file edits)
- Session metadata (start time, end time, AI model used, project context)
- File diffs showing exactly what changed during the session
- Attribution markers indicating which edits were human-initiated versus AI-generated

Because shadow branches are orphan branches,
they share no history with your main development branch.
A `git log main` shows only your project commits;
`git log entire/sessions/abc123` shows only that session's data.
The two histories coexist in the same `.git` directory
without interfering with each other.

### Metadata Branch

In addition to per-session branches, Entire.io maintains a **metadata branch**
(`entire/meta` by convention) that serves as a cross-session index.
This branch contains:

- A session manifest listing all archived sessions with timestamps and summaries
- Attribution aggregates -- which files in the project were touched by AI,
  and in which sessions
- Cross-references between sessions (e.g., "session B continued the work started in session A")
- Tags and annotations added by the developer

The metadata branch makes it possible to answer questions like:
"Which AI sessions contributed to this module?"
or "What percentage of this file was AI-authored?"
without scanning every individual session branch.

## Supported AI Tools

Entire.io supports multiple AI coding assistants:

- **Claude Code** -- Captures sessions from Anthropic's CLI assistant.
  Reads the JSONL transcripts stored in `~/.claude/projects/`
  and archives them to shadow branches.
- **Cursor** -- Captures AI interactions from Cursor's VS Code fork.
  Integrates with Cursor's session storage to extract conversation data.
- **Additional tools** -- The architecture is extensible;
  any tool that produces structured session data can be supported
  via adapter plugins.

This multi-tool support is particularly valuable for teams
where different developers use different AI assistants.
The metadata branch provides a unified view across all tools.

## Attribution Tracking

One of Entire.io's most distinctive features is **attribution tracking** --
maintaining a record of which code was authored by a human
versus generated or suggested by an AI assistant.

For each session, Entire.io records:

- Which files were modified and the specific diffs
- Whether each change originated from a human edit or an AI response
- The prompt context that led to each AI-generated change
- The human's accept/reject/modify decisions for AI suggestions

This information is aggregated on the metadata branch,
enabling project-level attribution analysis.
For research software, this provenance trail is essential:
it answers questions about intellectual contribution,
supports licensing compliance (some AI-generated code may have
different IP status depending on jurisdiction),
and satisfies emerging requirements from journals and funders
about AI involvement in research outputs.

## Installation and Basic Usage

Install the CLI tool via npm:

```bash
npm install -g @entireio/cli
```

Initialize Entire.io in an existing git repository:

```bash
entire init
```

This creates the shadow branch infrastructure
(the metadata branch and configuration)
without modifying your working tree or existing branches.

To archive a Claude Code session:

```bash
entire capture claude --session <session-id>
```

To list all archived sessions:

```bash
entire list
```

To view attribution summary for the current project:

```bash
entire attribution summary
```

## How It Differs from Export Tools

The table below compares Entire.io's shadow branch approach
with file-based export tools:

| Aspect | Entire.io (shadow branches) | cctrace / ccexport (file export) |
|---|---|---|
| **Storage location** | Orphan git branches in same repo | Files in working tree or separate directory |
| **Working tree impact** | None -- shadow branches are invisible to `git status` | Adds files that must be committed or gitignored |
| **Cross-session indexing** | Built-in via metadata branch | Manual; requires external tooling |
| **Attribution tracking** | Native, aggregated per-file | Not available |
| **Multi-tool support** | Claude Code, Cursor, extensible | Tool-specific (one tool each) |
| **Repository size** | Session data in packfiles, efficiently compressed | Session data as regular files, may be large |
| **Discoverability** | Requires knowledge of shadow branches | Files visible in directory listing |
| **Portability** | Travels with `git clone --mirror`; lost with default `git clone` | Always present after clone |

The portability trade-off is worth noting:
a default `git clone` does not fetch orphan branches
unless the remote is configured to advertise them
or the clone uses `--mirror`.
For archival purposes this is often acceptable
(a `git push --all` to a backup remote preserves everything),
but teams should be aware that shallow clones
will not include session data.

## Integration with con/serve

Entire.io is particularly well-suited for the con/serve project itself.
Every development session that builds this knowledge base
can be archived in the same repository,
creating a complete record of how the project evolved --
not just the commits, but the conversations that produced them.

For DataLad datasets, shadow branches integrate naturally:
DataLad tracks the git repository as a whole,
so shadow branches are included in `datalad save` and `datalad push` operations
without special configuration.
The session data becomes part of the dataset's provenance,
alongside run records and metadata.

To incorporate Entire.io into a DataLad workflow:

1. Initialize Entire.io in the DataLad dataset root
2. Use Claude Code Hooks (see [Claude Code Hooks](../claude-code-hooks/))
   to trigger `entire capture` at session end
3. Session data flows to shadow branches automatically
4. `datalad push --all` propagates session archives to siblings

## Limitations and Considerations

- **Beta status** -- Entire.io is under active development.
  The shadow branch schema and CLI interface may change between releases.
- **Clone behavior** -- As noted above, default `git clone` does not fetch
  orphan branches. Use `--mirror` for full archival clones,
  or configure the remote to advertise session branches.
- **Repository growth** -- While git packfiles compress session data efficiently,
  long-running projects with many sessions will accumulate data.
  Consider periodic garbage collection (`git gc --aggressive`)
  and monitor repository size.
- **Privacy** -- AI session transcripts may contain sensitive information
  (API keys pasted into prompts, proprietary code discussed with the assistant).
  Review sessions before pushing to shared remotes,
  or use Entire.io's filtering options to redact sensitive content.

## See Also

- [cctrace](../cctrace/) -- Lightweight alternative for Claude Code-only capture
- [ccexport](../ccexport/) -- Export Claude Code transcripts to readable formats
- [Claude Code Hooks](../claude-code-hooks/) -- Trigger Entire.io capture automatically
- [SpecStory](../specstory/) -- VS Code/Cursor extension with a different archival approach
