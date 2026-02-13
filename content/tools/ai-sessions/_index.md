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

**[Entire.io](entire-io/)** -- Git-native session archival using shadow branches.
Supports multiple AI tools (Claude Code, Cursor) with cross-session indexing
and attribution tracking.

**[cctrace](cctrace/)** -- Lightweight Claude Code conversation capture.
Reads JSONL transcripts and produces structured output for archival.

**[ccexport](ccexport/)** -- Claude Code transcript export to readable formats.
Converts raw JSONL session data to markdown and JSON.

**[SpecStory](specstory/)** -- VS Code/Cursor extension that automatically saves
AI coding sessions as markdown files in a `.specstory/` directory.

**[Claude Code Hooks](claude-code-hooks/)** -- Built-in lifecycle hooks in Claude Code itself.
PreCompact, Stop, and SessionEnd events can trigger automatic session archival.

## Common Patterns

AI session archival tools generally follow one of two strategies:

1. **Post-hoc export** -- Read session data from the AI tool's local storage
   (e.g., `~/.claude/projects/`) and convert it to an archival format.
   Tools like cctrace and ccexport take this approach.

2. **In-situ capture** -- Hook into the AI tool's lifecycle to capture sessions
   as they happen, storing them directly in git.
   Entire.io and Claude Code Hooks take this approach.

The ideal workflow combines both:
lifecycle hooks for real-time capture during active development,
and export tools for backfilling historical sessions.
