---
title: "gh-md"
date: 2026-02-12
description: "GitHub CLI extension that syncs issues, pull requests, and discussions to local markdown files"
summary: "A gh CLI extension that pulls a repository's issues, pull requests, and discussions into local markdown files with YAML front matter, and can push edits back."
categories: ["Code Artifacts"]
tags: ["github", "markdown", "issues", "pull-requests", "discussions"]
media_types: ["github-issues", "github-discussions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/jackchuka/gh-md"
  homepage: "https://github.com/jackchuka/gh-md"
  issues: "https://github.com/jackchuka/gh-md/issues"
  language: "Go"
  license: "MIT"
  maturity: "beta"
  last_verified: "2026-02"
---

gh-md is a [GitHub CLI](https://cli.github.com/) extension that syncs a
repository's issues, pull requests, and discussions to local markdown files,
and can push local edits back.  Each item becomes one `.md` file with YAML
front matter for the metadata and comment blocks marked by HTML comments,
stored under `~/.gh-md/owner/repo/{issues,pulls,discussions}/N.md`
(override the root with `GH_MD_ROOT`).

## Key Features

- **Issues, PRs, and Discussions** -- `--issues`, `--prs`, `--discussions`
  select what to pull.
- **Markdown with front matter** -- plain files that are diffable, greppable,
  and readable without the tool.
- **Bidirectional** -- `gh md push <file>` writes local edits back to GitHub;
  `gh md prune` removes files for items that no longer exist.
- **Multi-repo** -- `gh md repos` lists the repositories synced so far.

## Usage

```bash
# Install as a gh extension
gh extension install jackchuka/gh-md

# Pull everything for a repository
gh md pull owner/repo

# Only discussions
gh md pull owner/repo --discussions
```

## Alternative Approaches

- **python-github-backup** -- exports the same items as JSON
  (`--issues --pulls --discussions`), better suited when the raw API records
  matter more than readability.
- **git-bug** -- imports issues into git refs through its bridges, keeping them
  inside the repository rather than beside it.
- **Wikis** are not covered by gh-md; every GitHub wiki is a git repository at
  `https://github.com/OWNER/REPO.wiki.git` that can simply be cloned.

## git-annex / DataLad Integration

**Integration level: git-only.**

The markdown files are small text that belongs in git proper, not in
git-annex.  gh-md writes them under `~/.gh-md/` by default, so point
`GH_MD_ROOT` at a DataLad dataset to keep them there:

```bash
datalad create forge-archive
cd forge-archive

GH_MD_ROOT=$PWD datalad run -m "Sync issues, PRs, and discussions for owner/repo" \
    gh md pull owner/repo
```

## AI Readiness

**Level: ai-ready.**

Markdown is one of the most AI-friendly formats:

- **Direct consumption** -- LLMs can read and understand markdown natively.
  No parsing, conversion, or preprocessing is needed.
- **Rich structure** -- headings, lists, code blocks, and links provide
  semantic structure that helps LLMs understand document organization.
- **Knowledge extraction** -- issue threads and discussions contain design
  rationale and troubleshooting history that is valuable for AI-assisted
  project understanding.
- **Search and retrieval** -- plain text markdown integrates easily with
  vector databases and RAG (retrieval-augmented generation) pipelines.

The synced files are ideal input for project-specific knowledge
bases that AI assistants can reference during development.
