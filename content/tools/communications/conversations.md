---
title: "con/versations"
date: 2026-02-12
description: "Matrix room archival CLI writing plain-text daily logs, built for cron-driven operation"
summary: "Python CLI tool for archiving Matrix chat rooms into date-organized plain text files, built on matrix-nio. Its plain-file output drops straight into a git repository."
categories: ["Communications"]
tags: ["CON", "matrix", "export", "messages", "rooms"]
media_types: ["matrix"]
integrations: ["git-only"]
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
for unattended, scheduled operation via cron. Because it writes nothing but
small text files, its output can be tracked in a plain git repository or a
DataLad dataset without any adaptation.

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

The package is not published on PyPI; install from the repository:

```bash
pip install git+https://github.com/con/versations

# Or clone and install
git clone https://github.com/con/versations
cd versations
pip install .
```

## Usage

Connection settings are read from `MATRIX_*` environment variables
(homeserver, user, password, E2E key file and passphrase);
`MATRIX_STORE_PATH` sets the output directory (default `./output/`).

```bash
# Basic usage -- see all options
versations --help

# Sync messages from all joined rooms (or one room with --room)
MATRIX_STORE_PATH=/path/to/archive versations sync

# Send a message to a room, from the command line or a file
versations send --room '!roomid:server' "Archive run complete"
```

## git-annex / DataLad Integration

**Integration level: native-datalad.**

con/versations has no git or DataLad awareness of its own; upstream does not
mention either. Its plain text output and date-based directory structure
simply make it easy to track. One way to do so is to point
`MATRIX_STORE_PATH` at a DataLad dataset and wrap each sync in `datalad run`
so the archive grows as a sequence of provenance-carrying commits:

```bash
datalad create matrix-archive
cd matrix-archive
MATRIX_STORE_PATH=. datalad run -m "Matrix room sync $(date -I)" versations sync
```

All content is small text, so it lands in git proper (not the annex) and is
searchable with `git log -S` and `git grep`.

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
line in the form `HH:MM:SS | @sender:server: body`.

## AI Readiness

**Level: ai-ready.**

The plain text output is the most AI-friendly format possible.
Messages are stored as human-readable text organized chronologically, ready
for direct ingestion by language models without any parsing or conversion.
Room organization provides natural topic segmentation. The absence of binary
content means the entire archive is immediately usable for summarization,
search, and knowledge extraction.

## See Also

- [matrix-archive]({{< ref "matrix-archive" >}}) -- Alternative Matrix
  archival tool that produces JSON event logs with media download support,
  better suited when media preservation is important.
