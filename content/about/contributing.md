---
title: "Contributing"
date: 2026-02-12
description: "How to add new tool entries and contribute to the con/serve knowledge base"
cascade:
  showEdit: true
---

con/serve is a community knowledge base.
If you know of a tool for archiving digital research artifacts
that is not yet cataloged here, we welcome contributions.

## Adding a New Tool Entry

### 1. Choose the right section

Place your tool page in the appropriate subdirectory under `content/tools/`:

| Section | Artifact type |
|---|---|
| `communications/` | Messaging platforms (Slack, Telegram, Matrix, email) |
| `media/` | Video, audio, images |
| `code-artifacts/` | Issues, PRs, discussions, wikis from code forges |
| `cloud-storage/` | Cloud-hosted files (Google Drive, S3, Dropbox) |
| `publications/` | Scholarly citations, PDFs, references |
| `web/` | Web pages and sites |
| `ai-sessions/` | AI coding sessions and conversations |

If your tool does not fit any existing section, open an issue to discuss
whether a new section is warranted.

### 2. Create the file

Create a new markdown file in the appropriate section directory.
Use a URL-friendly slug for the filename (e.g., `my-tool.md`).

### 3. Fill in the front matter

Every tool page **must** include the following front matter:

```yaml
---
title: "Tool Name"
date: 2026-02-12
description: "One-line description of what the tool does"
summary: "Brief summary for listing pages"
categories: ["Communications"]
tags: ["slack", "export", "json"]
media_types: ["slack"]
integrations: ["git-annex"]
ai_readiness: ["ai-ready"]
params:
  # URLs (required -- every tool must have at least repo + homepage + issues)
  repo: "https://github.com/org/repo"
  homepage: "https://tool.example.com"
  issues: "https://github.com/org/repo/issues"
  # URLs (optional but encouraged)
  discussions: "https://github.com/org/repo/discussions"
  docs: "https://tool.readthedocs.io"
  changelog: "https://github.com/org/repo/blob/main/CHANGELOG.md"
  # Metadata
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
---
```

### 4. Front matter field reference

**Required fields:**

| Field | Description |
|---|---|
| `title` | Human-readable tool name |
| `date` | Date the entry was created (YYYY-MM-DD) |
| `description` | One-line description |
| `summary` | Brief summary for listing pages |
| `categories` | One of: Communications, Media, Code Artifacts, Cloud Storage, Publications, Web, AI Sessions |
| `integrations` | One or more of: `native-datalad`, `git-annex`, `git-only`, `external` |
| `ai_readiness` | One or more of: `ai-ready`, `ai-partial`, `ai-manual` |
| `params.repo` | Source code repository URL |
| `params.homepage` | Project homepage or documentation URL (can be same as repo) |
| `params.issues` | Bug tracker / issue tracker URL |
| `params.language` | Primary programming language |
| `params.license` | SPDX license identifier |
| `params.maturity` | One of: `stable`, `beta`, `alpha`, `concept` |
| `params.last_verified` | When URLs and content were last verified (YYYY-MM) |

**Optional fields:**

| Field | Description |
|---|---|
| `tags` | Free-form tags for discoverability |
| `media_types` | Specific format or platform identifiers |
| `params.discussions` | Forum, GitHub Discussions, mailing list, or chat URL |
| `params.docs` | Dedicated documentation site URL |
| `params.changelog` | Changelog URL |

### 5. Write the content

Structure the page body with these sections (adapt as needed):

```markdown
## Overview

What the tool does, who maintains it, and why it matters for archival.

## Installation

How to install the tool. Prefer package managers and reproducible methods.

## Usage with git-annex / DataLad

How to integrate the tool's output into a git-annex or DataLad repository.
Include concrete commands and examples.

## AI Readiness

What the output looks like from an LLM's perspective.
What processing (if any) is needed to make it consumable?

## Limitations

Known limitations, caveats, and workarounds.

## See Also

Links to related tools, upstream documentation, and relevant concepts pages.
```

### 6. Choosing taxonomy values

**Integration level** (`integrations` field) -- choose one or more of:
[`native-datalad`](/integrations/native-datalad/),
[`git-annex`](/integrations/git-annex/),
[`git-only`](/integrations/git-only/),
[`external`](/integrations/external/).
See [Integration Levels](/about/#integration-levels) for detailed definitions and examples.

**AI readiness** (`ai_readiness` field) -- choose one or more of:
[`ai-ready`](/ai_readiness/ai-ready/),
[`ai-partial`](/ai_readiness/ai-partial/),
[`ai-manual`](/ai_readiness/ai-manual/).
See [AI Readiness Levels](/about/#ai-readiness-levels) for detailed definitions and examples.

When in doubt, a tool can have multiple values
(e.g., a tool that produces both JSON metadata and video files
might be `["ai-ready", "ai-manual"]`).

### 7. Verify URLs

All URLs in `params` are checked by CI.
Before submitting, verify that:

- `repo` points to an active, public repository
- `homepage` resolves and contains relevant documentation
- `issues` points to a working issue tracker
- Any optional URLs also resolve correctly

### 8. Submit

Open a pull request against the
[con/serve repository](https://github.com/con/serve).
The CI pipeline will validate front matter schema and check all URLs.
