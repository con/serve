---
title: "wayslack2"
date: 2026-02-12
description: "Incremental Slack workspace archival into Slack's export format, with file management"
summary: "Python tool for incremental Slack archival into Slack's export format. Published on PyPI as wayslack2, an updated release of the original wayslack."
categories: ["Communications"]
tags: ["slack", "export", "incremental"]
media_types: ["slack"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/huyz/wayslack"
  homepage: "https://github.com/huyz/wayslack"
  issues: "https://github.com/huyz/wayslack/issues"
  language: "Python"
  license: "BSD-2-Clause"
  maturity: "alpha"
  last_verified: "2026-02"
---

wayslack2 is the PyPI package name of an updated release of
[wayslack](https://github.com/wolever/wayslack), a Python tool that
incrementally archives a Slack workspace into Slack's standard export format.
It is not a separate project: the `wayslack2` package is built from the
[huyz/wayslack](https://github.com/huyz/wayslack) fork and installs the same
`wayslack` command.

## Key Features

- **Incremental archival**: Downloads only new messages and files since the
  last run, making it efficient for scheduled (e.g., cron-based) operation.
- **Slack export format**: Produces output in Slack's standard export directory
  structure (JSON files organized by channel and date, plus a `_files/`
  directory), ensuring compatibility with other Slack tools and viewers.
- **File management**: Downloads shared files and attachments. Can optionally
  delete old files from Slack to free storage on free-tier workspaces via the
  `delete_old_files` option (confirmed with `--confirm-delete`).
- **SQL export**: Includes `wayslack2sql.py` for loading archived data into a
  PostgreSQL database for querying and analysis.

## Relationship to the Original wayslack

The original [wayslack](https://github.com/wolever/wayslack) by David Wolever
(last released 2019) provided incremental Slack archival to a local
directory, including the `wayslack2sql.py` exporter. The huyz fork republished
it on PyPI as `wayslack2` (0.4.x) so that it can still be installed; its
changelog does not document the differences, and the fork's own last commit
dates from 2024. Upstream setup metadata still classifies the project as
alpha and carries an "immaturity warning".

## Installation

```bash
pip install wayslack2

# Or install from source
pip install git+https://github.com/huyz/wayslack
```

## Usage

```bash
# Create an archive directory (or point to an existing one)
wayslack /path/to/slack-archive

# This will:
# 1. Create the archive directory if it doesn't exist
# 2. Authenticate with Slack (token required)
# 3. Download all messages and files incrementally
# 4. Store in Slack export format
```

Configuration is managed through `~/.wayslack/config.yaml`, which specifies
the Slack token and archive options.

## git-annex / DataLad Integration

**Integration level: git-only.**

wayslack has no git, git-annex, or DataLad awareness; upstream mentions none
of them. What it offers is a directory of small JSON files plus downloaded
attachments, which is easy to track: JSON in git, `_files/` in git-annex.
A `datalad run` wrapper around `wayslack /path` is one way to record each
incremental run as a provenance-carrying commit, but no established workflow
for this exists yet.

## AI Readiness

**Level: ai-ready.**

Output follows Slack's standard JSON export format with
structured fields for messages, users, channels, and metadata. The JSON
files are directly parseable by language models for summarization, topic
extraction, and knowledge base construction. Thread relationships and
user references are preserved as structured data.

## See Also

- [slackdump]({{< ref "slackdump" >}}) -- More feature-rich and actively
  maintained Slack export tool (Go-based, multiple output modes).
