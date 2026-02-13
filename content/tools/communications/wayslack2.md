---
title: "wayslack2"
date: 2026-02-12
description: "DataLad-based incremental Slack workspace archival with file management"
summary: "Python tool for incremental Slack archival using Slack's export format, with DataLad integration for versioned, provenance-tracked preservation."
categories: ["Communications"]
tags: ["slack", "datalad", "export", "incremental"]
media_types: ["slack"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/huyz/wayslack"
  homepage: "https://github.com/huyz/wayslack"
  issues: "https://github.com/huyz/wayslack/issues"
  language: "Python"
  license: "BSD"
  maturity: "beta"
  last_verified: "2026-02"
---

Wayslack2 is a Python tool for incrementally archiving Slack workspaces into
Slack's standard export format. It is an updated and maintained fork of the
original [wayslack](https://github.com/wolever/wayslack) project, designed
to work within DataLad datasets for versioned, provenance-tracked Slack
preservation.

## Key Features

- **Incremental archival**: Downloads only new messages and files since the
  last run, making it efficient for scheduled (e.g., cron-based) operation.
- **Slack export format**: Produces output in Slack's standard export directory
  structure (JSON files organized by channel and date), ensuring compatibility
  with other Slack tools and viewers.
- **File management**: Downloads shared files and attachments. Can optionally
  delete old files from Slack to free storage on free-tier workspaces via the
  `delete_old_files` option.
- **SQL export**: Includes `wayslack2sql.py` for exporting archived data to a
  PostgreSQL database for querying and analysis.
- **DataLad-native workflow**: Designed to operate within a DataLad dataset,
  where each incremental archive run can be captured as a versioned commit
  with full provenance.

## Relationship to Original wayslack

The original [wayslack](https://github.com/wolever/wayslack) by Jesse Bhatt
provided the foundational approach of incremental Slack archival to a local
directory. Wayslack2 builds on this by:

- Updating compatibility with current Slack API versions.
- Adding the SQL export capability.
- Targeting integration with DataLad for research-grade archival workflows.
- Continuing maintenance as the original project became inactive.

## Installation

```bash
pip install wayslack2

# Or install from source
pip install git+https://github.com/huyz/wayslack
```

## Usage

```bash
# Create an archive directory (or point to an existing one)
wayslack2 /path/to/slack-archive

# This will:
# 1. Create the archive directory if it doesn't exist
# 2. Authenticate with Slack (token required)
# 3. Download all messages and files incrementally
# 4. Store in Slack export format
```

Configuration is managed through a YAML configuration file that specifies
the Slack token and archive options.

## DataLad Integration

Wayslack2 is designed as a native DataLad archival tool. The recommended
workflow:

```bash
# Create a DataLad dataset for the Slack archive
datalad create slack-workspace
cd slack-workspace

# Run wayslack2 under datalad run for provenance tracking
datalad run -m "Incremental Slack archive $(date -I)" \
  --output . \
  wayslack2 .

# Schedule periodic runs via cron
# 0 */6 * * * cd /path/to/slack-workspace && datalad run -m "Scheduled Slack archive" wayslack2 .
```

Each run produces a DataLad commit capturing exactly what changed -- new
messages, updated channels, downloaded files -- with a machine-readable
run record that documents the command, inputs, and outputs.

Binary file attachments are automatically managed by git-annex (based on
the dataset's largefiles configuration), while JSON message files can remain
in git for easy diffing and searching.

## AI Readiness

**ai-ready** -- Output follows Slack's standard JSON export format with
structured fields for messages, users, channels, and metadata. The JSON
files are directly parseable by language models for summarization, topic
extraction, and knowledge base construction. Thread relationships and
user references are preserved as structured data.

## See Also

- [slackdump]({{< ref "slackdump" >}}) -- More feature-rich Slack export tool
  (Go-based, multiple output modes) that can serve as an alternative data
  source, though without native DataLad integration.
