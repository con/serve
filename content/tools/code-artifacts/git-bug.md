---
title: "git-bug"
date: 2026-02-12
description: "Distributed bug tracker embedded in git, with bridges to GitHub, GitLab, Jira, and Launchpad"
summary: "A distributed, offline-first bug tracker that stores issues directly in git refs, with bidirectional bridges to major issue trackers."
categories: ["Code Artifacts"]
tags: ["bugs", "issues", "distributed", "bridges", "github", "gitlab", "jira"]
media_types: ["github-issues"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/git-bug/git-bug"
  homepage: "https://github.com/git-bug/git-bug"
  issues: "https://github.com/git-bug/git-bug/issues"
  language: "Go"
  license: "GPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

git-bug is a standalone, distributed bug tracker that embeds directly inside a git repository.
Instead of relying on a centralized service (GitHub Issues, Jira, etc.), every bug, comment,
label, and status change lives as structured data in special git refs (`refs/bugs/*`).
This means bugs travel with the repository -- they are cloned, pushed, pulled, and merged
just like code.

Because the data is entirely in git, it survives platform migrations, works offline, and
can be distributed across any number of remotes without a single point of failure.

## Key Features

- **Fully embedded in git** -- no external database, no server, no SaaS dependency.
  Bugs live in `refs/bugs/*` using a custom DAG-based data model that supports concurrent
  edits and conflict-free merges (similar to CRDTs).
- **Offline-first** -- create, edit, and search bugs without network access.
  Changes sync when you push/pull.
- **Bidirectional bridges** -- import and export bugs to/from GitHub, GitLab, Jira, and
  Launchpad.  Bridges maintain identity mappings so round-trips are clean.
- **Rich CLI and TUI** -- `git bug ls`, `git bug show`, `git bug add`, plus an
  interactive terminal UI (`git bug termui`).
- **Web UI** -- built-in GraphQL API and web interface (`git bug webui`).
- **Incremental bridge sync** -- bridges remember their last sync point and only
  transfer deltas.

## How Data is Stored

git-bug uses a DAG (directed acyclic graph) of operations stored as git tree objects
under `refs/bugs/`.  Each bug is identified by a content-addressed hash.
Operations include "create", "add comment", "set status", "set label", etc.
Multiple users can edit the same bug concurrently; operations are ordered and merged
deterministically.

This architecture means:

- Every change is versioned and auditable.
- No data is ever overwritten -- the full edit history is preserved.
- The bug database can be replicated to any git remote.

## git-annex / DataLad Integration

**Integration level: git-only.**

git-bug stores all data in git proper (not the annex) because bugs are small,
structured text objects.  This is appropriate -- there is no benefit to content-addressing
bug text through git-annex.

To archive a project's issues into a DataLad dataset:

1. **Use the bridge to import issues** from GitHub/GitLab/Jira into the repo:
   ```bash
   git bug bridge configure --name github-bridge --target github \
       --owner ORG --project REPO --token "$GITHUB_TOKEN"
   git bug bridge pull github-bridge
   ```
2. **Push the bug refs to your DataLad-tracked remote**:
   ```bash
   git push origin 'refs/bugs/*:refs/bugs/*'
   ```
3. **Re-export** later if needed:
   ```bash
   git bug bridge push github-bridge
   ```

Because bugs are in git refs, `datalad save` will not directly track them
(DataLad operates on the working tree).  However, you can export bugs to JSON
for inclusion in the tracked tree:

```bash
git bug ls -f json > .bugs/bugs.json
datalad save -m "Update bug tracker export" .bugs/
```

## AI Readiness

**Level: ai-ready.**

git-bug's data is structured text throughout:

- `git bug ls -f json` produces machine-readable JSON with full bug metadata
  (title, status, labels, author, timestamps, comments).
- The GraphQL API provides typed, queryable access to all bug data.
- Comments are plain text or markdown -- directly consumable by LLMs.
- The JSON export is ideal for feeding into AI analysis pipelines
  (e.g., "summarize all open bugs", "categorize issues by component").

No transcription or format conversion is needed.  An LLM can read the JSON
export and produce useful summaries, triage suggestions, or cross-repository
analyses immediately.
