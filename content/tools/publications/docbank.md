---
title: "docbank"
date: 2026-08-31
description: "Local-first self-sovereign document system for PDFs, images, and text files with content-addressed versioning"
summary: "Manages PDFs, images, and text files in a local SQLite catalog with stable node IDs, SHA-256 content addressing, ranked full-text search, tagging, and incremental backup with verification."
categories: ["Publications"]
tags: ["pdf", "documents", "sqlite", "content-addressed", "search", "versioning", "local-first"]
media_types: ["documents", "pdf"]
integrations: ["external"]
ai_readiness: ["ai-partial"]
params:
  repo: "https://github.com/kenn-io/docbank"
  homepage: "https://github.com/kenn-io/docbank"
  issues: "https://github.com/kenn-io/docbank/issues"
  language: "Go"
  license: "Apache-2.0"
  maturity: "beta"
  last_verified: "2026-08"
---

docbank is a "self-sovereign document system" for managing records that users
and AI agents need to organize, locate, modify, and verify.
It handles PDFs, images, and text files, keeping them in a local catalog
without requiring cloud storage.

## Storage and Indexing

- **Catalog**: SQLite database (CGO or pure-Go implementation)
- **Content store**: Local filesystem or S3-compatible object storage,
  physically separate from the catalog database
- **Stable node IDs**: Documents retain consistent identifiers even after
  being moved or renamed
- **Immutable versioning**: Each content state receives a permanent SHA-256
  digest
- **Virtual filesystem**: Familiar folder structure over the content store
- **Tags**: Supplement search with categorical labels

## Search

Ranked full-text search over document names and extracted text.
Upstream documentation does not describe the text extraction pipeline or which document
formats support full-text extraction beyond PDFs.

## Preservation Features

- Recoverable deletion with explicit garbage collection
- Incremental backups with verification
- Complete content authentication (SHA-256 digests)
- Optional permanent audited history (all versions retained)

## git-annex / DataLad Integration

**Integration level: external.**

docbank's content-addressed storage and immutable versioning overlap
conceptually with git-annex's design, but the two systems are independent.
docbank manages its own catalog and content store rather than delegating
to git-annex or DataLad.

For the con/serve mission, docbank is relevant as a **local document access
layer** -- particularly for scenarios where researchers want to manage a
personal PDF library with AI-friendly search without the overhead of a
full DataLad dataset.
The `~/.docbank/` store could in principle be snapshotted into a DataLad
dataset for off-site backup, but no established workflow for this exists.

Compared to [Zotero]({{< ref "zotero" >}}) (which manages scholarly references with
metadata, citation keys, and publisher integration), docbank is format-agnostic
and does not attempt citation-level metadata -- it is closer to a
content-addressed file store with search.

## AI Readiness

**Level: ai-partial.**

Catalog metadata (names, tags, versions, SHA-256 digests) and the extracted text used for full-text search are structured and directly queryable. The stored PDFs and images themselves are binary and need text extraction or vision models before an LLM can consume them.

## See Also

- [Zotero]({{< ref "zotero" >}}) -- reference manager with citation metadata and PDF management
- [citations-collector]({{< ref "citations-collector" >}}) -- discovery and archival of scholarly citations
- [agentsview]({{< ref "agentsview" >}}) -- sister kenn-io tool for AI session artifacts
