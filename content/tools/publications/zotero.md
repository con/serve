---
title: "Zotero Integration"
date: 2026-02-12
description: "Reference management and export for version-controlled scholarly collections"
summary: "Integration with the Zotero reference manager for synchronizing curated reference collections with DataLad datasets. Export BibTeX, JSON, and structured metadata for git-tracked bibliography management."
categories: ["Publications"]
tags: ["zotero", "references", "bibliography", "bibtex", "export"]
media_types: ["publications"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/zotero/zotero"
  homepage: "https://www.zotero.org"
  issues: "https://github.com/zotero/zotero/issues"
  language: "JavaScript"
  license: "AGPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

## Overview

[Zotero](https://www.zotero.org) is a free, open-source reference manager used by millions of researchers for collecting, organizing, and citing scholarly publications. It captures bibliographic metadata from the web, stores PDFs and annotations, organizes references into collections, and generates citations and bibliographies in hundreds of formats.

In the con/serve ecosystem, Zotero serves as the **human-facing reference management interface**. Researchers interact with Zotero in their daily workflow (saving papers, annotating PDFs, writing manuscripts), and the con/serve infrastructure synchronizes these collections into version-controlled DataLad datasets for long-term preservation and AI-assisted analysis.

## Key Features

- **Browser integration** -- the Zotero Connector captures metadata and PDFs from publisher sites, Google Scholar, arXiv, and dozens of other sources
- **PDF management** -- store, annotate, and full-text search PDFs
- **Collection organization** -- hierarchical folders, tags, and saved searches
- **Citation generation** -- integrates with Word, LibreOffice, and Google Docs via plugins
- **BetterBibTeX** -- popular plugin for automatic BibTeX/BibLaTeX key generation and export
- **Zotero API** -- REST API for programmatic access to libraries and collections
- **Sync** -- built-in cloud sync (limited free storage) or WebDAV for self-hosted PDF storage

## git-annex / DataLad Integration

**Integration level: external.**

Zotero does not natively integrate with git or DataLad. The integration is through export and synchronization:

### Manual Export Workflow

```bash
# Export a Zotero collection to BibTeX (via Zotero UI or BetterBibTeX auto-export)
# Result: references.bib in your project directory

# Track in DataLad
datalad save -m "Update bibliography from Zotero" references.bib

# Export as JSON for programmatic use
# (Zotero UI: right-click collection -> Export -> "Zotero JSON")
datalad save -m "Update Zotero JSON export" zotero-export.json
```

### BetterBibTeX Auto-Export

The [BetterBibTeX](https://retorque.re/zotero-better-bibtex/) plugin supports automatic export: whenever the Zotero collection changes, the BibTeX file is re-exported to a specified path. Combined with a file watcher or periodic `datalad save`, this creates a near-real-time sync from Zotero to git.

### citations-collector Integration

[citations-collector]({{< ref "citations-collector" >}}) provides deeper Zotero integration:

- Import Zotero collections as seed publications for citation discovery
- Push discovered citations back to Zotero
- Keep DataLad dataset and Zotero library in sync

## AI Readiness

**Level: ai-ready.**

Zotero's export formats are highly structured and AI-consumable:

| Format | AI Use Case |
|--------|------------|
| **BibTeX/BibLaTeX** | Structured citation data, parseable by any bibtex library |
| **Zotero JSON** | Full metadata including abstracts, tags, notes, attachments |
| **CSL JSON** | Citation Style Language data, standardized across tools |
| **RIS** | Interchange format, widely supported |

Zotero notes and annotations (especially PDF annotations in Zotero 6+) are plain text or HTML, making them directly accessible for LLM analysis -- summarization, theme extraction, or literature review generation.

## Typical Workflow in con/serve

```
Researcher                    con/serve infrastructure
    |                               |
    |-- Saves paper in Zotero       |
    |-- Annotates PDF               |
    |-- Adds to collection          |
    |                               |
    |-- BetterBibTeX auto-export -->|-- references.bib updated
    |                               |-- datalad save (version tracked)
    |                               |
    |                               |-- citations-collector discover
    |                               |   (finds new citing papers)
    |                               |
    |                               |-- citations-collector sync-zotero
    |<-- New citations in Zotero ---|   (pushes discoveries back)
    |                               |
    |-- Reviews new citations       |
    |-- Curates collection          |
```

## Limitations and Caveats

- **No native git integration**: Zotero stores its database in SQLite, not git. The export step is required for version control.
- **Sync storage limits**: Zotero's free cloud sync provides limited storage for PDFs. Self-hosted WebDAV or local-only mode avoids this.
- **Export lag**: BetterBibTeX auto-export triggers on collection changes but there is a small delay. Manual export is instant.
- **Annotation format changes**: Zotero 6+ changed the annotation storage format. Older annotations may need migration.

## See Also

- [citations-collector]({{< ref "citations-collector" >}}) -- automated citation discovery with Zotero sync
- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- publishing curated reference collections
