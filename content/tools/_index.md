---
title: "Tools"
date: 2026-02-12
description: "Catalog of tools for archiving digital research artifacts into git-annex/DataLad repositories"
cascade:
  showEdit: true
---

This section catalogs tools for ingesting digital research artifacts into
version-controlled, content-addressed repositories.
Each tool entry includes integration guidance for git-annex and DataLad,
an AI readiness assessment, and links to upstream documentation.

## Taxonomy

Every tool is classified along four axes:

**Category** -- the type of artifact the tool handles:
Communications, Media, Code Artifacts, Cloud Storage, Publications, Web, AI Sessions.

**Media type** -- the specific format or platform (e.g., `slack`, `youtube`, `github-issues`).
A tool may handle multiple media types.

**[Integration level](/integrations/)** -- how deeply the tool integrates with the git-annex/DataLad stack:
[`native-datalad`](/integrations/native-datalad/) | [`git-annex`](/integrations/git-annex/) | [`git-only`](/integrations/git-only/) | [`external`](/integrations/external/)
-- see [Integration Levels](/about/#integration-levels) for definitions.

**[AI readiness](/ai_readiness/)** -- how consumable the archived output is for LLM-based workflows:
[`ai-ready`](/ai_readiness/ai-ready/) | [`ai-partial`](/ai_readiness/ai-partial/) | [`ai-manual`](/ai_readiness/ai-manual/)
-- see [AI Readiness Levels](/about/#ai-readiness-levels) for definitions.

## Sections

- [Communications](communications/) -- Slack, Telegram, Matrix, Mattermost, email
- [Media](media/) -- YouTube, Zoom, podcasts, image galleries
- [Code Artifacts](code-artifacts/) -- GitHub issues, PRs, discussions, wikis
- [Cloud Storage](cloud-storage/) -- Google Drive, Dropbox, S3, and 70+ providers via rclone
- [Publications](publications/) -- Scholarly citations, PDFs, reference management
- [Web](web/) -- Web page and site archival
- [AI Sessions](ai-sessions/) -- Claude Code, Cursor, Entire.io session capture
