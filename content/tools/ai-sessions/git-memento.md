---
title: "git-memento"
date: 2026-03-02
description: "Git extension that stores AI coding session transcripts as git notes on commits"
summary: "Attaches cleaned markdown conversation transcripts to commits using native git notes -- the lightest-touch approach to AI session archival"
categories: ["AI Sessions"]
tags: ["ai", "sessions", "git", "git-notes", "claude", "codex", "audit"]
media_types: ["ai-sessions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/mandel-macaque/memento"
  homepage: "https://github.com/mandel-macaque/memento"
  issues: "https://github.com/mandel-macaque/memento/issues"
  language: "F#"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-03"
---

git-memento is a git extension that stores AI coding session transcripts
as **git notes** attached to commits.
It wraps `git commit` so that when you commit with an active AI session,
the conversation transcript is fetched from the provider CLI,
cleaned to readable markdown, and stored as a git note on that commit.

This is arguably the most minimally invasive approach
to AI session archival possible:
git notes are a native git feature that is invisible by default.
A `git log` shows no trace of them unless you ask,
`git clone` does not fetch them unless configured to,
and they add zero overhead to the working tree.

## How It Works

Instead of running `git commit`, you run:

```bash
git memento commit <session-id> -m "your commit message"
```

git-memento:

1. Fetches the session transcript from the AI provider's local storage
2. Renders it as clean markdown (speaker roles, messages, metadata)
3. Runs `git commit` as usual
4. Attaches the transcript as a git note on the resulting commit
   via `git notes add -f -m "<markdown>" <commit-hash>`

Multiple sessions can be attached to a single commit --
git-memento uses HTML comment delimiters to separate them.

## Supported Providers

- **Codex** (default) -- OpenAI's CLI coding assistant
- **Claude Code** -- Anthropic's CLI assistant

The provider system is extensible via configuration.

## Git Notes Primer

Git notes (`refs/notes/commits`) are a native git feature
for attaching arbitrary metadata to commits
without modifying the commit objects themselves.

Key properties:

- **Invisible by default** -- `git log` does not show notes
  unless passed `--notes` or configured via `notes.displayRef`
- **Not cloned by default** -- `git clone` does not fetch notes
  unless the refspec is configured (e.g., `fetch = +refs/notes/*:refs/notes/*`)
- **Survive rebases** -- with git hooks, notes can be preserved
  across history rewrites
- **Native to git** -- no external tools, databases, or branches required

This means a repository using git-memento looks completely normal
to anyone who does not specifically look for notes.
There is, as one commenter put it,
"no knowledge of their existence" unless you choose to surface them.

## Viewing Notes

```bash
# Show notes for a specific commit
git notes show <commit>

# Show all commits with their notes
git log --notes

# Show notes in a specific range
git log --notes main..HEAD
```

## CI Integration

git-memento includes a **GitHub Action** (`action.yml`) with two modes:

- **`comment` mode** -- Posts session notes as comments
  on the corresponding commits in GitHub, making them visible in the web UI.
- **`gate` mode** -- CI gate that fails the workflow
  if commits in the PR range lack session notes.
  Enforces the policy that every AI-assisted commit must have its session recorded.

### Audit Command

```bash
# Verify note coverage for a range of commits
git memento audit --range main..HEAD --strict
```

This checks that every commit in the range has an attached session note
and exits non-zero if any are missing --
useful as a local pre-push check or CI step.

## Notes Sync for Teams

Because git notes are not fetched by default,
git-memento provides a `notes-sync` workflow
with timestamped backups for team collaboration.
Team members can selectively sync notes
without affecting each other's local state.

## How It Differs from Other Tools

| Aspect | git-memento (git notes) | Entire.io (shadow branches) | Git AI (authorship notes) |
|---|---|---|---|
| **Storage** | `refs/notes/commits` | Orphan branches + metadata branch | `refs/notes/ai` + `.git/ai/` |
| **Granularity** | Conversation markdown | Full JSONL transcripts + snapshots | Line-level authorship |
| **Working tree impact** | None | None | None |
| **Clone visibility** | Hidden unless notes fetched | Hidden unless branches fetched | Hidden unless notes fetched |
| **Rewind/resume** | No | Yes | No |
| **CI enforcement** | GitHub Action gate mode | Pre-push hook | Enterprise dashboard |

## Integration with con/serve

For DataLad datasets, git notes integrate naturally:
they are stored as refs in the git repository
and propagate with `git push` when the notes refspec is configured.

A typical workflow:

1. Develop with Claude Code or Codex
2. Commit via `git memento commit <session-id> -m "message"`
3. Configure the remote to push notes: `git config remote.origin.push "+refs/notes/*:refs/notes/*"`
4. `datalad push` propagates both code and session notes

The notes approach is particularly well-suited
to repositories where minimal footprint matters --
small datasets, scripts, and configuration repos
where adding shadow branches or metadata infrastructure
would be disproportionate.

## Limitations

- **GitHub does not render git notes** in its web UI by default.
  The GitHub Action `comment` mode works around this
  by posting notes as commit comments.
- **Notes are fragile across rebases** without hook support.
  git-memento provides hooks to preserve notes during history rewrites.
- **No session rewind** -- notes are metadata-only;
  they do not capture file state snapshots.
- **Provider coverage** is currently limited to Codex and Claude Code.

## See Also

- [Entire.io](../entire-io/) -- Full session archival with shadow branches and rewind
- [Git AI](../git-ai/) -- Line-level AI authorship attribution
- [cctrace](../cctrace/) -- Lightweight Claude Code transcript capture
- [ccexport](../ccexport/) -- Claude Code transcript export to readable formats
- [Git Refs as Side-Channel Databases]({{< ref "concepts/git-refs-side-channels" >}}) -- git notes compared with the other ref-based side channels
