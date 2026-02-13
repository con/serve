---
title: "GitHub Discussions Export"
date: 2026-02-12
description: "Export GitHub Discussions to markdown and JSON for archival and offline access"
summary: "Tools for exporting GitHub Discussions -- threaded Q&A and community conversations -- into portable markdown and JSON formats."
categories: ["Code Artifacts"]
tags: ["github", "discussions", "export", "markdown"]
media_types: ["github-discussions"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/King-of-Infinite-Space/gh-discussions-export"
  homepage: "https://github.com/King-of-Infinite-Space/gh-discussions-export"
  issues: "https://github.com/King-of-Infinite-Space/gh-discussions-export/issues"
  language: "JavaScript"
  license: "MIT"
  maturity: "beta"
  last_verified: "2026-02"
---

## Overview

GitHub Discussions is a threaded forum feature built into GitHub repositories,
used for Q&A, announcements, design conversations, and community interaction.
Unlike issues and pull requests, Discussions are not part of the git repository
itself -- they exist only on GitHub's servers and are not captured by
`git clone`, `git bug`, or standard repository backup tools.

This makes Discussions especially vulnerable to loss: if a repository is deleted,
transferred, or if GitHub changes its feature set, the entire discussion history
disappears.

gh-discussions-export addresses this by using the GitHub GraphQL API to export
all Discussions from a repository into portable markdown and/or JSON files.

## Key Features

- **Full export** -- captures all discussions including title, body, category,
  labels, author, timestamps, and the complete reply thread.
- **Multiple output formats** -- markdown files (one per discussion) and/or
  JSON for programmatic access.
- **Category preservation** -- retains the discussion category (Q&A, General,
  Announcements, etc.) in the exported metadata.
- **Threaded replies** -- preserves the reply structure, including nested
  comments and "marked as answer" status for Q&A discussions.
- **GraphQL-based** -- uses the GitHub GraphQL API for efficient, paginated
  data retrieval.

## Basic Usage

```bash
# Install
npm install -g gh-discussions-export

# Export all discussions from a repository
gh-discussions-export --repo owner/repo --token "$GITHUB_TOKEN"

# Export to a specific directory
gh-discussions-export --repo owner/repo --token "$GITHUB_TOKEN" \
    --output ./discussions-archive/
```

## Alternative Approaches

Several tools and approaches exist for exporting GitHub Discussions:

- **GitHub CLI with GraphQL** -- the `gh api graphql` command can query
  Discussions directly using GitHub's GraphQL schema.  This is useful for
  custom export scripts.
- **github-backup** -- some forks of python-github-backup have added
  partial Discussions support.
- **Custom scripts** -- the GraphQL API is well-documented; a focused
  Python or JavaScript script can export Discussions with full control
  over format and filtering.

Example using `gh` CLI directly:

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      discussions(first: 100) {
        nodes {
          title
          body
          category { name }
          createdAt
          comments(first: 100) {
            nodes { body author { login } createdAt }
          }
        }
      }
    }
  }
' -f owner=ORG -f repo=REPO > discussions.json
```

## git-annex / DataLad Integration

**Integration level: git-only.**

Exported Discussions are text files (markdown or JSON) that belong in git proper.
They are small, diffable, and benefit from version tracking.

To integrate into a DataLad dataset:

```bash
# Export discussions into the dataset
gh-discussions-export --repo owner/repo --output ./discussions/

# Track with DataLad
datalad save -m "Archive GitHub Discussions for owner/repo" discussions/
```

For periodic archival, use `datalad run`:

```bash
datalad run -m "Update discussions archive" \
    --output "discussions/" \
    gh-discussions-export --repo owner/repo --output ./discussions/
```

## AI Readiness

**Level: ai-ready.**

GitHub Discussions export produces well-structured content that LLMs can
consume directly:

- **Markdown output** -- human-readable and LLM-friendly.  Each discussion
  is a self-contained document with metadata headers.
- **JSON output** -- structured data with typed fields (title, body, author,
  category, timestamps, replies).  Ideal for programmatic analysis.
- **Threaded context** -- the reply structure is preserved, allowing an LLM to
  understand conversational context (who replied to whom, which answer was
  accepted).

Discussions often contain rich design rationale, usage questions, and community
knowledge that is not captured anywhere else in a project.  Archiving and
indexing this content makes it available for AI-assisted project onboarding,
FAQ generation, and knowledge retrieval.
