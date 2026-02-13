---
title: "python-github-backup"
date: 2026-02-12
description: "Backup GitHub repositories and all associated metadata including issues, pull requests, wikis, and stars"
summary: "A Python tool that creates comprehensive backups of GitHub repositories and their metadata -- issues, PRs, releases, wikis, stars, and more."
categories: ["Code Artifacts"]
tags: ["github", "backup", "repositories", "issues", "stars", "wiki"]
media_types: ["github-issues"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/josegonzalez/python-github-backup"
  homepage: "https://github.com/josegonzalez/python-github-backup"
  issues: "https://github.com/josegonzalez/python-github-backup/issues"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

python-github-backup (also available as the `github-backup` CLI command) creates
local backups of GitHub repositories along with their associated metadata.  Unlike
a simple `git clone`, it captures the full ecosystem around a repository: issues,
pull requests, milestones, labels, releases, wikis, stars, watchers, and forks
metadata.

This makes it a practical tool for archiving the social and project-management
layer of GitHub that would otherwise be locked into the platform and lost during
migrations or account closures.

## Key Features

- **Repository cloning** -- bare or mirror clones of the git repository itself.
- **Issue and PR backup** -- all issues and pull requests with their full comment
  threads, labels, milestones, and assignees, saved as JSON files.
- **Release assets** -- download release tarballs and attached binaries.
- **Wiki backup** -- clone the wiki repository (if present).
- **Stars and watchers** -- record who starred or watches the repository.
- **Organization-wide backup** -- iterate over all repositories in a GitHub
  organization with a single command.
- **Incremental** -- re-running updates existing backups with new data.
- **GitHub Enterprise support** -- works with self-hosted GitHub instances.

## Basic Usage

```bash
pip install github-backup

# Backup a single repository with all metadata
github-backup USER --token "$GITHUB_TOKEN" \
    --repository REPO \
    --issues --pulls --milestones --labels --releases \
    --wikis --stars --watchers \
    --output-directory ./backups/

# Backup all repositories in an organization
github-backup ORG --token "$GITHUB_TOKEN" \
    --organization \
    --issues --pulls --releases --wikis \
    --output-directory ./backups/
```

## Output Structure

The backup produces a directory per repository containing:

```
REPO/
  repository/          # bare git clone
  issues/              # one JSON file per issue
  pull_requests/       # one JSON file per PR
  milestones/          # milestone metadata
  releases/            # release metadata + downloaded assets
  wiki/                # wiki git repository clone
  stars.json           # list of stargazers
  watchers.json        # list of watchers
```

## git-annex / DataLad Integration

**Integration level: git-only.**

python-github-backup writes its output to a local directory.  The JSON metadata
files are small and well-suited for direct git tracking, while release assets
(binaries, tarballs) can be large and are better suited for git-annex.

A recommended workflow for archiving into a DataLad dataset:

```bash
# Create a DataLad dataset for GitHub backups
datalad create github-archive
cd github-archive

# Run the backup
github-backup ORG --token "$GITHUB_TOKEN" \
    --organization --all \
    --output-directory .

# Save everything -- git-annex will handle large files automatically
# based on .gitattributes annex.largefiles settings
datalad save -m "GitHub backup $(date +%Y-%m-%d)"
```

For periodic backups, wrap the command with `datalad run` to record
provenance:

```bash
datalad run -m "Update GitHub backup" \
    --output "ORG/" \
    github-backup ORG --token "$GITHUB_TOKEN" \
        --organization --all \
        --output-directory .
```

## AI Readiness

**Level: ai-ready.**

The tool produces JSON files for all metadata (issues, PRs, milestones, releases,
stars).  These are directly parseable by any programming language or LLM:

- Issue and PR JSON includes full comment threads with timestamps and author info.
- The structured format makes it straightforward to build summaries, search across
  issues, or analyze project activity patterns.
- Wiki content (cloned as a git repository of markdown files) is immediately
  readable by LLMs.

No format conversion is needed for AI consumption.  The JSON metadata is
well-structured and self-describing.
