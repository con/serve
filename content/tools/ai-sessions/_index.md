---
title: "AI Sessions"
date: 2026-02-12
description: "Tools for capturing and archiving AI coding sessions -- Claude Code, Cursor, and multi-tool transcripts"
cascade:
  showEdit: true
---

AI coding assistants are becoming central to research software development,
but the conversations that produce code are ephemeral by default.
Session history lives in provider-controlled storage,
subject to retention limits, format changes, and service discontinuations.

This section catalogs tools that capture AI session transcripts
and archive them into git repositories,
preserving the full context of human-AI collaboration:
prompts, responses, tool use, file edits, and reasoning traces.

## Why Archive AI Sessions?

**Attribution** -- Knowing which code was authored by a human versus an AI assistant
is essential for reproducibility, licensing compliance, and intellectual honesty.
Archived sessions provide a complete provenance trail.

**Reproducibility** -- The prompt sequence that produced a piece of code
is as important as the code itself.
Future researchers (or your future self) can understand *why* a design decision was made
by reading the conversation that led to it.

**Institutional memory** -- AI sessions contain problem-solving strategies,
debugging approaches, and design rationale that never make it into commit messages or documentation.
Archiving them preserves this tacit knowledge.

**Frozen frontier** -- Most AI providers retain session history for limited periods.
Claude Code stores sessions locally in `~/.claude/projects/`,
but these are not version-controlled and can be lost with a disk failure or OS reinstall.

## Tools Covered

### Session Archival

**[Entire.io](entire-io/)** -- Git-native session archival as checkpoint refs
inside the repository. Supports Claude Code, Codex, Copilot CLI, Cursor, Gemini CLI,
OpenCode, and others, with session resume and checkpoint search. Go CLI.

**[git-memento](git-memento/)** -- Stores AI session transcripts as git notes on commits.
The lightest-touch approach: notes are invisible by default, add no branches or files,
and use native git primitives. Supports Codex and Claude Code. F# with NativeAOT compilation.

**[Git AI](git-ai/)** -- Line-level AI authorship attribution.
Tracks exactly which lines were AI-written vs human-authored, stored as git notes.
Supports 10+ agents. Provides `git-ai blame` as an AI-aware replacement for `git blame`.
Rust CLI with IDE decorations and enterprise dashboards.

### Session Capture and Export

**[cctrace](cctrace/)** -- Lightweight Claude Code conversation capture.
Reads JSONL transcripts and produces structured output for archival.

**[ccexport](ccexport/)** -- Claude Code transcript export to readable formats.
Converts raw JSONL session data to markdown and HTML, with secret redaction.

**[SpecStory](specstory/)** -- Cursor and VS Code Copilot extensions, plus an open-source
CLI wrapper for terminal agents (Claude Code, Codex, Gemini CLI, and others), that
automatically save AI coding sessions as markdown files in `.specstory/history/`.

**[Claude Code Hooks](claude-code-hooks/)** -- Built-in lifecycle hooks in Claude Code itself.
PreCompact, Stop, and SessionEnd events can trigger automatic session archival.

### Session Analytics and Review

**[AgentsView](agentsview/)** -- Local-first search and analytics over the session
logs of 40+ coding agents, indexed into SQLite with full-text and semantic search.
A discovery layer over the files the tools above archive, not an archival tool itself.

**[roborev](roborev/)** -- Git-hook-driven review of every AI-generated commit,
kept in a local review database with JSON export.
Records the quality-assurance side of AI-assisted development
alongside the conversations that produced the code.

## Common Patterns

AI session archival tools generally follow one of three strategies:

1. **Post-hoc export** -- Read session data from the AI tool's local storage
   (e.g., `~/.claude/projects/`) and convert it to an archival format.
   Tools like cctrace and ccexport take this approach.

2. **In-situ capture** -- Hook into the AI tool's lifecycle to capture sessions
   as they happen, storing them directly in git or in files.
   Entire.io, SpecStory, and Claude Code Hooks take this approach.

3. **Commit-time attachment** -- Record session context at commit time
   using native git metadata (notes).
   git-memento and Git AI take this approach.

The ideal workflow combines several:
lifecycle hooks for real-time capture during active development,
commit-time notes for lightweight provenance,
and export tools for backfilling historical sessions.

## Related

- [AI Agents and Vault Operations]({{< ref "concepts/agents" >}}) --
  how AI agents operate within the vault, the solidification lifecycle,
  and why archived sessions serve as both provenance and experience ledger input
