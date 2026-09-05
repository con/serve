---
title: "GitHub Discussions Export"
date: 2026-02-12
description: "Export GitHub Discussions to markdown files with an index and feed"
summary: "A Deno script, usable as a GitHub Actions template, that exports a repository's Discussions to markdown files with an index page and RSS/JSON feed."
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

GitHub Discussions is a threaded forum feature built into GitHub repositories,
used for Q&A, announcements, design conversations, and community interaction.
Unlike issues and pull requests, Discussions are not part of the git repository
itself -- they exist only on GitHub's servers and are not captured by
`git clone`, `git bug`, or standard repository backup tools.

This makes Discussions especially vulnerable to loss: if a repository is deleted,
transferred, or if GitHub changes its feature set, the entire discussion history
disappears.

gh-discussions-export addresses this by exporting all Discussions from a
repository into markdown files, plus an index of posts and an RSS or JSON feed.

## Key Features

- **Markdown export** -- one `.md` file per discussion.
- **Index and feed** -- generates an index of posts and an RSS or JSON feed
  of recent ones, so the export doubles as a small static site.
- **Runs in CI** -- the repository is a template meant to run as a scheduled
  GitHub Actions workflow, committing the exported files back.

## Usage

The tool is a [Deno](https://deno.com/) script, not a packaged CLI. Either use
the repository as a template and let its GitHub Actions workflow run on a
schedule, or run it locally:

```bash
git clone https://github.com/King-of-Infinite-Space/gh-discussions-export
cd gh-discussions-export
# set GITHUB_TOKEN, then edit scripts/config.js (repository, output paths)
deno run --allow-net --allow-env --allow-read --allow-write scripts/fetchPosts.js
```

## Alternative Approaches

Several tools and approaches exist for exporting GitHub Discussions:

- **GitHub CLI with GraphQL** -- the `gh api graphql` command can query
  Discussions directly using GitHub's GraphQL schema.  This is useful for
  custom export scripts.
- **[python-github-backup]({{< ref "github-backup" >}})** -- exports Discussions,
  comments, and replies as JSON with `--discussions`.
- **[gh-md]({{< ref "gh-md" >}})** -- syncs Discussions (and issues and PRs)
  to local markdown files with `gh md pull owner/repo --discussions`.
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
# Run the export with its output configured to land in the dataset, then
datalad save -m "Archive GitHub Discussions for owner/repo" discussions/
```

For periodic archival, wrap the `deno run ...` invocation in `datalad run`,
or let the template's scheduled workflow commit into a repository that the
vault mirrors.

## AI Readiness

**Level: ai-ready.**

GitHub Discussions export produces well-structured content that LLMs can
consume directly:

- **Markdown output** -- human-readable and LLM-friendly; each discussion
  is a self-contained document.
- **Feed** -- the JSON feed gives a machine-readable index of recent posts.
- For per-comment structured data, python-github-backup's JSON export is the
  richer source.

Discussions often contain rich design rationale, usage questions, and community
knowledge that is not captured anywhere else in a project.  Archiving and
indexing this content makes it available for AI-assisted project onboarding,
FAQ generation, and knowledge retrieval.
