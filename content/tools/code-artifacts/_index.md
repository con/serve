---
title: "Code Artifacts"
date: 2026-02-12
description: "Tools for archiving issues, pull requests, discussions, and wikis from code forges"
cascade:
  showEdit: true
---

A git repository preserves source code, but the surrounding context --
issues, pull requests, code reviews, discussions, and wiki pages --
lives on the forge platform and is not captured by `git clone`.

When a project migrates between forges, or a forge shuts down,
this context is often lost.
The tools in this section extract these artifacts
so they can be archived alongside the code they describe.

## Artifact Types

**Issues and Pull Requests** -- Bug reports, feature requests, and code review threads.
[git-bug](git-bug/) stores them as distributed git objects;
[python-github-backup](github-backup/) exports them as JSON.

**Discussions** -- Forum-style threads (GitHub Discussions).
[gh-discussions-export](gh-discussions-export/) renders them to markdown;
[gh-md](gh-md/) syncs issues, pull requests, and discussions to local markdown files;
python-github-backup exports them as JSON.

**Wikis** -- Project documentation hosted on the forge.
Every GitHub wiki is a git repository (`REPO.wiki.git`) that can be cloned directly;
python-github-backup does so with `--wikis`.

**CI Logs and Artifacts** -- Build logs, test output, and release assets that CI
platforms expire after weeks. [con/tinuous](tinuous/) archives them from
GitHub Actions, Travis CI, Appveyor, and CircleCI into DataLad datasets.

**Computational Environments** -- Container images that accompany code.
[datalad-container](datalad-container/) registers and version-controls them
alongside the data they process.

**Crawled Resources** -- Broader web resources associated with a project.
[datalad-crawler](datalad-crawler/) provides a DataLad-native approach to
tracking and versioning web-hosted resources.

**Local-First Working Copies** -- Not archival tools, but local mirrors of forge
state built for day-to-day work with AI agents:
[forge (kenn-io)](forge/) syncs PRs, issues, and CI status from several forges into SQLite;
[kata](kata/) is a local issue tracker for agent-driven development.

## Why Archive Code Artifacts?

Code artifacts carry institutional knowledge:
the *why* behind design decisions, the history of bugs and their fixes,
and community discussions that shaped the project.
This context is often more valuable than the code itself for
understanding and reproducing research software.

Archiving code artifacts also enables AI-assisted development workflows --
an LLM with access to the full issue history can provide
significantly better code review and bug analysis.
