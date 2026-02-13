---
title: "con/versations"
date: 2026-02-12
description: "Matrix room archival CLI with DataLad-native storage and cron-friendly operation"
summary: "Python CLI tool for archiving Matrix chat rooms into date-organized plain text files, built on matrix-nio with DataLad-native workflow support."
categories: ["Communications"]
tags: ["CON", "matrix", "datalad", "export", "messages", "rooms"]
media_types: ["matrix"]
integrations: ["native-datalad"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/con/versations"
  homepage: "https://github.com/con/versations"
  issues: "https://github.com/con/versations/issues"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
---

con/versations is a lightweight Python CLI tool for archiving Matrix chat room
messages into plain text files organized by room and date. Built on the
[matrix-nio](https://github.com/matrix-nio/matrix-nio) library, it is designed
for unattended, scheduled operation via cron and integrates naturally with
DataLad datasets for versioned, provenance-tracked archival of Matrix
conversations.

## Key Features

- **Automated archival**: Designed for cron-based scheduling, syncing new
  messages from Matrix rooms on each run.
- **Clean directory structure**: Messages are stored as plain text files
  organized by room name and date (`room-name/YYYY-MM-DD`), creating a
  human-readable, browsable archive.
- **Message sending**: Can send messages during execution, either from
  command-line strings or files, enabling notification workflows.
- **matrix-nio backend**: Uses the mature matrix-nio Python library for
  Matrix protocol support, including end-to-end encryption capabilities.
- **Minimal dependencies**: Lightweight tool focused on doing one thing well --
  archiving room messages to files.

## Prerequisites

The tool requires the `libolm` C library for Matrix encryption support:

```bash
# Debian/Ubuntu
sudo apt install libolm-dev

# Fedora
sudo dnf install libolm-devel
```

## Installation

```bash
# From PyPI or source
pip install git+https://github.com/con/versations

# Or clone and install
git clone https://github.com/con/versations
cd versations
pip install .
```

## Usage

```bash
# Basic usage -- see all options
versations --help

# Archive messages from joined rooms
versations /path/to/archive/

# Send a message to a room
versations --send "Archive run complete" --room '!roomid:server'
```

## DataLad Integration

con/versations is designed as a DataLad-native archival tool. The plain text
output format and date-based directory structure make it ideal for tracking
in a DataLad dataset:

```bash
# Create a DataLad dataset for Matrix archives
datalad create matrix-archive
cd matrix-archive

# Run versations under datalad run for provenance
datalad run -m "Matrix room sync $(date -I)" \
  --output . \
  versations .

# Schedule periodic archival via cron
# 0 */4 * * * cd /path/to/matrix-archive && datalad run -m "Scheduled Matrix sync" versations .
```

Each sync produces a clean DataLad commit showing exactly which rooms had
new messages and what was added. The plain text format means all content
is stored directly in git (not annex), making it fully searchable with
`git log -S` and `git grep`.

## Output Format

```
archive/
  general/
    2026-01-15
    2026-01-16
    2026-02-01
  project-discussion/
    2026-01-20
    2026-02-10
  ...
```

Each date file contains the day's messages in plain text, one message per
line with timestamp and sender information.

## AI Readiness

**ai-ready** -- The plain text output is the most AI-friendly format possible.
Messages are stored as human-readable text organized chronologically, ready
for direct ingestion by language models without any parsing or conversion.
Room organization provides natural topic segmentation. The absence of binary
content means the entire archive is immediately usable for summarization,
search, and knowledge extraction.

## See Also

- [matrix-archive]({{< ref "matrix-archive" >}}) -- Alternative Matrix
  archival tool that produces YAML output with media download support,
  better suited when media preservation is important.
