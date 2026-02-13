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
[github-backup](github-backup/) exports them as JSON.

**Discussions** -- Forum-style threads (GitHub Discussions, GitLab forums).
[gh-discussions-export](gh-discussions-export/) captures these for offline access.

**Wikis** -- Project documentation hosted on the forge.
[gh-md](gh-md/) backs up GitHub markdown content including wikis.

**Crawled Resources** -- Broader web resources associated with a project.
[datalad-crawler](datalad-crawler/) provides a DataLad-native approach to
tracking and versioning web-hosted resources.

## Why Archive Code Artifacts?

Code artifacts carry institutional knowledge:
the *why* behind design decisions, the history of bugs and their fixes,
and community discussions that shaped the project.
This context is often more valuable than the code itself for
understanding and reproducing research software.

Archiving code artifacts also enables AI-assisted development workflows --
an LLM with access to the full issue history can provide
significantly better code review and bug analysis.
