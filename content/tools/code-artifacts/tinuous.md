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

[con/tinuous](https://github.com/con/tinuous) is a command-line tool for downloading build logs, artifacts, and release assets from multiple CI/CD platforms into a local directory structure suitable for version control with git-annex and DataLad. It supports **GitHub Actions**, **Travis CI**, **Appveyor**, and **CircleCI**.

CI logs are among the most ephemeral research artifacts -- platforms routinely expire logs after 90 days, and when a CI provider shuts down (as Travis CI largely did for open source), years of build history vanish. con/tinuous ensures these artifacts are captured and preserved.

## Key Features

- **Multi-platform** -- single tool covers GitHub Actions, Travis CI, Appveyor, and CircleCI
- **Flexible path templates** -- customizable output directory structure using placeholders (`{year}`, `{month}`, `{ci}`, `{wf_name}`, `{run_id}`, etc.)
- **Asset filtering** -- retrieve specific workflows, build types (push, PR, cron, manual), and date ranges
- **Secret sanitization** -- automatically removes sensitive data from downloaded logs using configurable regex patterns
- **Stateful execution** -- tracks previously fetched builds to avoid redundant downloads on subsequent runs
- **DataLad integration** -- optional `datalad` section in the config makes each fetch a DataLad save; `//` in path templates marks subdataset boundaries
- **Scheduled operation** -- designed for cron-based automation for continuous archival

## Installation

```bash
pip install 'tinuous[datalad]'
```

## Usage

Configure via `tinuous.yaml` in your repository:

```yaml
repo: con/tinuous
ci:
  github:
    paths:
      logs: '{year}//{month}/{day}/{ci}/{type}/{type_id}/{wf_name}/{build_commit[:7]}/{job}.txt'
      artifacts: '{year}//{month}/{day}/{ci}/{type}/{type_id}/{wf_name}/{build_commit[:7]}/{run_id}/'
    workflows:
      - test.yml
  travis:
    paths:
      logs: '{year}//{month}/{day}/{ci}/{type}/{type_id}/{build_commit[:7]}/{number}/{job}.txt'
since: 2024-01-01T00:00:00Z
types: [cron, manual, pr, push]
secrets:
  github: 'gh[pousr]_[A-Za-z0-9]{36,}'
datalad:
  enabled: true
  cfg_proc: text2git
```

Placeholders differ per CI system (`{run_id}` and `{wf_file}` are GitHub-only,
`{job}` applies to CircleCI); the README has the full table. A `//` in a path
template marks a subdataset boundary, the same convention this site uses in
[vault layouts]({{< ref "vault-organization#dataset-nesting-notation" >}}).

Then run:

```bash
# Fetch all new logs since the last recorded state
tinuous fetch

# Only fetch builds newer than a given time
tinuous fetch --since "3 days ago"

# Sanitize secrets in already-downloaded logs
tinuous sanitize
```

## git-annex / DataLad Integration

**Integration level: native-datalad.**

con/tinuous has first-class DataLad support: with `datalad.enabled: true` in
`tinuous.yaml`, each fetch is committed as a DataLad save, subdatasets are
created at the `//` boundaries of the path templates, and the configured
`cfg_proc` (typically `text2git`) decides what goes to git versus the annex.

```bash
# Initialize a DataLad dataset for CI logs
datalad create -c text2git ci-archive
cd ci-archive

# Copy tinuous config (with the datalad section enabled)
cp /path/to/tinuous.yaml .

# Fetch with automatic DataLad commits
tinuous fetch
```

With `text2git`, log text files are committed to git (searchable, diffable), while binary artifacts go into git-annex (content-addressed, deduplicated).

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
