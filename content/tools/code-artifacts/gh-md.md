---
title: "gh-md"
date: 2026-02-12
description: "GitHub markdown backup tool for archiving wikis and markdown content from repositories"
summary: "A tool for backing up GitHub wiki pages and markdown documentation into local files for archival and offline access."
categories: ["Code Artifacts"]
tags: ["github", "markdown", "backup", "wiki"]
media_types: ["github-wiki"]
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

## Overview

gh-md is a tool for backing up GitHub wiki pages and other markdown content from
GitHub repositories.  GitHub wikis are separate git repositories
(`REPO.wiki.git`) that are often overlooked during backups despite containing
critical project documentation, onboarding guides, and design decisions.

gh-md focuses specifically on extracting and organizing this markdown content
into a clean, portable directory structure that can be version-controlled
independently of the source repository.

## Key Features

- **Wiki backup** -- clones and organizes GitHub wiki content into structured
  local directories.
- **Markdown extraction** -- pulls markdown files from repositories, preserving
  directory structure.
- **Clean output** -- produces plain markdown files that are portable and
  tool-agnostic.
- **Batch processing** -- can process multiple repositories or organizations.

## Basic Usage

```bash
# Clone a GitHub wiki directly (wikis are separate git repos)
git clone https://github.com/ORG/REPO.wiki.git

# Or use gh-md for structured backup
gh-md backup --repo owner/repo --output ./wiki-archive/
```

## Alternative Approaches

GitHub wikis can also be archived through several other methods:

- **Direct git clone** -- every GitHub wiki is a git repository at
  `https://github.com/OWNER/REPO.wiki.git`.  A simple `git clone` captures
  the full wiki with history.
- **python-github-backup** -- includes `--wikis` flag for wiki backup as part
  of a comprehensive repository backup.
- **GitHub API** -- the REST API provides access to wiki page content, though
  not as conveniently as a direct clone.

For most archival scenarios, the direct `git clone` of the `.wiki.git`
repository is the simplest and most complete approach.  gh-md adds value when
you need structured extraction or batch processing across many repositories.

## git-annex / DataLad Integration

**Integration level: git-only.**

Wiki and markdown content is small text that belongs in git proper, not in
git-annex.  The content is inherently diffable and benefits from line-level
version tracking.

To archive wikis into a DataLad dataset:

```bash
# Create a dataset for documentation archives
datalad create docs-archive
cd docs-archive

# Clone the wiki as a subdirectory
git clone https://github.com/ORG/REPO.wiki.git wikis/REPO/

# Or use gh-md
gh-md backup --repo owner/repo --output ./wikis/REPO/

# Save with DataLad
datalad save -m "Archive wiki for ORG/REPO" wikis/REPO/
```

For periodic updates:

```bash
datalad run -m "Update wiki archive for ORG/REPO" \
    --output "wikis/REPO/" \
    "cd wikis/REPO && git pull origin master"
```

## AI Readiness

**Level: ai-ready.**

Markdown is one of the most AI-friendly formats:

- **Direct consumption** -- LLMs can read and understand markdown natively.
  No parsing, conversion, or preprocessing is needed.
- **Rich structure** -- headings, lists, code blocks, and links provide
  semantic structure that helps LLMs understand document organization.
- **Knowledge extraction** -- wiki pages often contain institutional knowledge
  (setup guides, architecture decisions, troubleshooting tips) that is
  extremely valuable for AI-assisted project understanding.
- **Search and retrieval** -- plain text markdown integrates easily with
  vector databases and RAG (retrieval-augmented generation) pipelines.

Archived wikis are ideal candidates for building project-specific knowledge
bases that AI assistants can reference during development.
