---
title: "Entire.io"
date: 2026-02-12
description: "Git-native AI session archival as checkpoint refs inside the repository, with session resume and search"
summary: "Stores AI coding session checkpoints as git refs alongside the code, linked to commits by trailers, without touching the working tree"
categories: ["AI Sessions"]
tags: ["ai", "sessions", "git", "checkpoints", "claude", "codex", "cursor", "gemini"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/entireio/cli"
  homepage: "https://entire.io"
  issues: "https://github.com/entireio/cli/issues"
  language: "Go"
  license: "MIT"
  maturity: "beta"
  last_verified: "2026-02"
  examples:
    - title: "Entire.io CLI"
      url: "https://github.com/entireio/cli"
---

Entire.io takes a fundamentally different approach to AI session archival
compared to export-based tools like [cctrace]({{< ref "cctrace" >}}) or [ccexport]({{< ref "ccexport" >}}).
Instead of exporting transcripts to files in the working tree,
it stores session **checkpoints** as git refs inside the same repository --
data that travels with the repository and its remotes
but never appears in your working directory.

This is a significant architectural choice:
your project's file tree stays clean, your `.gitignore` needs no AI-specific entries,
and yet the complete record of every AI-assisted development session
is preserved in the same repository, subject to the same backup and replication
strategies as your code.

## Checkpoint Storage

While an agent works, Entire records progress on a short-lived local
**shadow branch** that is never pushed.
When you commit, that work is condensed into a checkpoint:
its own ref under `refs/entire/checkpoints/<shard>/<id>`,
whose tree holds `metadata.json` and the per-session transcript files.
The code commit carries an `Entire-Checkpoint: <id>` trailer,
which is the link from code to conversation; the link back is a search for
that trailer.
(Earlier releases kept all checkpoints on a single orphan branch,
`entire/checkpoints/v1`, a layout still visible in older repositories.)

Because checkpoint identifiers are random, two developers' checkpoints
never collide, and combining them is a plain union of refs.
Checkpoints are pushed automatically alongside `git push`
(disable with `--skip-push-sessions`), or to a separate repository with
`--checkpoint-remote`.
Secrets are redacted on a best-effort basis before a checkpoint is written.

## Supported AI Tools

Entire.io supports multiple AI coding agents, selected with `--agent` when enabling:
Claude Code, Codex, Copilot CLI, Cursor, Droid, Gemini CLI, OpenCode, and Pi.
For Claude Code it installs its own hooks in `.claude/settings.json`.
This multi-tool support is particularly valuable for teams
where different developers use different AI assistants.

## Installation and Usage

```bash
# Install (Homebrew; a curl installer, Scoop, and `go install` are also offered)
brew tap entireio/tap && brew install --cask entire

# Enable for the current repository and agent
entire enable --agent claude-code

# Inspect
entire status
entire session list
entire checkpoint list
entire checkpoint explain <id>

# Search across checkpoints, or resume a session
entire search "why did we change the parser"
entire session resume <id>
```

Experimental `entire blame` and `entire why` answer which lines came from
which checkpoint.

## How It Differs from Export Tools

The table below compares Entire.io's checkpoint-ref approach
with file-based export tools:

| Aspect | Entire.io (checkpoint refs) | cctrace / ccexport (file export) |
|---|---|---|
| **Storage location** | `refs/entire/*` in the same repo | Files in working tree or separate directory |
| **Working tree impact** | None -- refs are invisible to `git status` | Adds files that must be committed or gitignored |
| **Cross-session search** | Built-in (`entire search`, `checkpoint list`) | Manual; requires external tooling |
| **Session resume** | Yes | No |
| **Multi-tool support** | Eight agents | Claude Code only |
| **Repository size** | Session data in packfiles, efficiently compressed | Session data as regular files, may be large |
| **Discoverability** | Requires knowing the refs exist | Files visible in directory listing |
| **Portability** | Needs a `refs/entire/*` refspec or `--mirror`; not fetched by default | Always present after clone |

The portability trade-off is worth noting:
a default `git clone` fetches branches and tags but not custom refs,
so the checkpoints only travel when the remote is fetched with an explicit
`refs/entire/*` refspec or mirrored.
Entire's own push hook handles the outbound side;
teams should be aware that a plain clone will not include session data.

## git-annex / DataLad Integration

**Integration level: git-only.**

Entire.io is particularly well-suited for the con/serve project itself.
Every development session that builds this knowledge base
can be archived in the same repository,
creating a complete record of how the project evolved --
not just the commits, but the conversations that produced them.

For DataLad datasets the checkpoints live in the same git repository as the
dataset, but under `refs/entire/*`, which `datalad push` does not propagate
unless the sibling's push and fetch refspecs include that namespace.
No established recipe for this exists yet; see
[Git Content Store as Side-Channel Databases]({{< ref "concepts/git-content-store-side-channels" >}})
for the general distribution problem such refs share with git-bug and git notes.

## Limitations

- **Beta status** -- Entire.io is under active development.
  The checkpoint layout has already changed once (from a single branch to
  per-checkpoint refs) and the CLI may change between releases.
- **Clone behavior** -- As noted above, default `git clone` does not fetch
  `refs/entire/*`. Use `--mirror` for full archival clones,
  or add the refspec to the remote configuration.
- **Repository growth** -- Checkpoints are never pruned, so long-running
  projects with many sessions will accumulate data.
- **Privacy** -- AI session transcripts may contain sensitive information
  (API keys pasted into prompts, proprietary code discussed with the assistant).
  Redaction is best-effort; review sessions before pushing to shared remotes.

## AI Readiness

**Level: ai-ready.**

Checkpoints are stored as JSONL transcripts with JSON metadata, plus a plain-text prompt and a markdown context summary per session. All of it is structured text that an LLM can parse directly, and the commit trailer gives a machine-readable link from code to conversation.

## See Also

- [git-memento]({{< ref "git-memento" >}}) -- Lighter-touch approach using git notes instead of checkpoint refs
- [Git AI]({{< ref "git-ai" >}}) -- Line-level AI authorship attribution via git notes
- [cctrace]({{< ref "cctrace" >}}) -- Lightweight alternative for Claude Code-only capture
- [ccexport]({{< ref "ccexport" >}}) -- Export Claude Code transcripts to readable formats
- [Claude Code Hooks]({{< ref "claude-code-hooks" >}}) -- Trigger Entire.io capture automatically
- [SpecStory]({{< ref "specstory" >}}) -- VS Code/Cursor extension with a different archival approach
- [How Entire works under the hood](https://julien.danjou.info/blog/how-entire-works-under-the-hood/) --
  the earlier `entire/checkpoints/v1` branch layout, commit trailers, and tree-union merging
- [Git Content Store as Side-Channel Databases]({{< ref "concepts/git-content-store-side-channels" >}}) --
  the general pattern, compared across git-annex, git-bug, notes, and metalad
