---
title: "con/tinuous"
date: 2026-02-12
description: "Download build logs, artifacts, and release assets from GitHub Actions, Travis CI, Appveyor, and CircleCI"
summary: "Multi-platform CI log and artifact archival tool with DataLad integration, secret sanitization, and stateful incremental fetching."
categories: ["Code Artifacts"]
tags: ["CON", "ci", "logs", "artifacts", "github-actions", "travis-ci", "appveyor", "circleci", "datalad", "archival"]
media_types: ["ci-logs"]
integrations: ["native-datalad"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/con/tinuous"
  homepage: "https://github.com/con/tinuous"
  issues: "https://github.com/con/tinuous/issues"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "tinuous-inception (self-archiving CI logs)"
      url: "https://github.com/con/tinuous-inception"
    - title: "DataLad release builds"
      url: "https://datasets.datalad.org/?dir=/datalad/packages"
---

## Overview

[con/tinuous](https://github.com/con/tinuous) is a command-line tool for downloading build logs, artifacts, and release assets from multiple CI/CD platforms into a local directory structure suitable for version control with git-annex and DataLad. It supports **GitHub Actions**, **Travis CI**, **Appveyor**, and **CircleCI**.

CI logs are among the most ephemeral research artifacts -- platforms routinely expire logs after 90 days, and when a CI provider shuts down (as Travis CI largely did for open source), years of build history vanish. con/tinuous ensures these artifacts are captured and preserved.

## Key Features

- **Multi-platform** -- single tool covers GitHub Actions, Travis CI, Appveyor, and CircleCI
- **Flexible path templates** -- customizable output directory structure using placeholders (`{year}`, `{month}`, `{ci}`, `{wf_name}`, `{run_id}`, etc.)
- **Asset filtering** -- retrieve specific workflows, build types (push, PR, cron, manual), and date ranges
- **Secret sanitization** -- automatically removes sensitive data from downloaded logs using configurable regex patterns
- **Stateful execution** -- tracks previously fetched builds to avoid redundant downloads on subsequent runs
- **DataLad integration** -- optional `--datalad` flag commits each fetch as a DataLad save with provenance metadata
- **Scheduled operation** -- designed for cron-based automation for continuous archival

## Installation

```bash
pip install con-tinuous
```

## Usage

Configure via `tinuous.yaml` in your repository:

```yaml
repo: con/tinuous
ci:
  github:
    workflows:
      - test.yml
      - release.yml
    logs: true
    artifacts: true
  travis:
    logs: true
  appveyor:
    logs: true

path: '{ci}/{wf_name}/{year}/{month}/{day}/{run_id}/{job_name}.log'

secrets:
  - '\b[A-Za-z0-9+/]{40}\b'  # sanitize base64 tokens
```

Then run:

```bash
# Fetch all new logs since last run
tinuous fetch

# Fetch with DataLad integration (auto-commit with provenance)
tinuous fetch --datalad

# Fetch only GitHub Actions logs from the last 30 days
tinuous fetch --ci github --since 30d
```

## git-annex / DataLad Integration

**Integration level: native-datalad.**

con/tinuous has first-class DataLad support via the `--datalad` flag. When enabled, each fetch operation is committed as a DataLad save with metadata recording what was fetched, from which CI platform, and when. This creates a complete provenance trail for the archived logs.

```bash
# Initialize a DataLad dataset for CI logs
datalad create ci-archive
cd ci-archive

# Copy tinuous config
cp /path/to/tinuous.yaml .

# Fetch with automatic DataLad commits
tinuous fetch --datalad
```

Log text files are committed to git (searchable, diffable), while binary artifacts go into git-annex (content-addressed, deduplicated).

## AI Readiness

**Level: ai-ready.**

CI logs are plain text, immediately consumable by AI systems. This makes con/tinuous archives ideal for:

- **Regression analysis** -- AI agents can diff logs across builds to identify when and why tests started failing
- **Pattern detection** -- find recurring flaky tests, infrastructure issues, or dependency problems
- **Build optimization** -- analyze timing data to identify slow steps

The structured directory layout (`{ci}/{wf_name}/{year}/...`) makes it easy for AI tools to navigate and correlate logs across time and platforms.

## See Also

- [datalad-crawler]({{< ref "datalad-crawler" >}}) -- general-purpose web resource crawler
- [GitHub Backup]({{< ref "github-backup" >}}) -- backs up repository metadata (issues, PRs) but not CI logs
