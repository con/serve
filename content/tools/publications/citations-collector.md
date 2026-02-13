---
title: "citations-collector"
date: 2026-02-12
description: "Multi-source scholarly citation discovery, PDF acquisition, and curation with DataLad integration and LinkML schema"
summary: "Discovers citations across CrossRef, OpenCitations, DataCite, and OpenAlex; syncs with Zotero; acquires PDFs with git-annex provenance tracking; and stores everything in a DataLad dataset using a LinkML schema aligned with CiTO and FaBiO ontologies."
categories: ["Publications"]
tags: ["CON", "citations", "scholarly", "crossref", "opencitations", "datacite", "openale", "zotero", "pdf", "provenance"]
media_types: ["publications"]
integrations: ["native-datalad"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/con/citations-collector"
  homepage: "https://github.com/con/citations-collector"
  issues: "https://github.com/con/citations-collector/issues"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
---

**citations-collector** is a tool for building and maintaining comprehensive, version-controlled collections of scholarly citations. Given a set of seed publications (your lab's papers, a project's key references), it discovers all citing and cited works across multiple sources, acquires full-text PDFs where available, syncs with Zotero for reference management, and stores everything in a DataLad dataset with full provenance tracking.

## The Problem

Scholarly citation management is fragmented:

- **Discovery** is scattered across databases: CrossRef has DOI metadata, OpenCitations has citation graphs, DataCite covers datasets, OpenAlex aggregates from multiple sources. No single service has complete coverage.
- **PDF acquisition** is manual: you search Google Scholar, check Unpaywall, try preprint servers, and download one PDF at a time. The provenance (where did this PDF come from?) is lost.
- **Reference management** lives in Zotero or Mendeley -- proprietary databases that do not version-track changes or integrate with data management workflows.
- **Citation relationships** (who cites whom, and how) are not captured in reference managers at all.

citations-collector addresses all four problems in a single, DataLad-native workflow.

## Architecture

```
my-citations/                          # DataLad dataset
  .datalad/
  citations/
    seed-papers.yaml                   # Seed publications (input)
    discovered/
      10.1234-paper-a.yaml             # Discovered citation records
      10.5678-paper-b.yaml             # Each with full metadata
      ...
    graph/
      citation-graph.json              # Citation relationships
  pdfs/
    10.1234-paper-a.pdf                # git-annex (content-addressed)
    10.5678-paper-b.pdf                # git-annex (provenance tracked)
  zotero/
    collection-export.json             # Zotero library sync
  schema/
    citation.yaml                      # LinkML schema definition
```

### Data Model

citations-collector uses a [LinkML](https://linkml.io/) schema to define its data model. The schema is aligned with established scholarly ontologies:

- **[CiTO](http://purl.org/spar/cito)** (Citation Typing Ontology) -- classifies citation relationships (cites, cites as authority, cites as data source, etc.)
- **[FaBiO](http://purl.org/spar/fabio)** (FRBR-aligned Bibliographic Ontology) -- describes bibliographic entities (journal article, conference paper, dataset, etc.)

This means citation records are not just flat metadata -- they carry semantic information about *why* one paper cites another and *what kind* of scholarly entity each record represents.

## Key Features

### Multi-Source Citation Discovery

citations-collector queries multiple scholarly databases and merges the results:

| Source | What It Provides |
|--------|-----------------|
| **[CrossRef](https://www.crossref.org/)** | DOI metadata, reference lists, funding information |
| **[OpenCitations](https://opencitations.net/)** | Open citation graph data (who cites whom) |
| **[DataCite](https://datacite.org/)** | Dataset citations and data-paper linkages |
| **[OpenAlex](https://openalex.org/)** | Aggregated scholarly metadata from multiple sources |

By querying all four sources, citations-collector builds a more complete picture than any single database provides. CrossRef may have the DOI metadata but miss the citation graph; OpenCitations has the graph but may lack recent papers; DataCite captures dataset-to-paper links that others miss; OpenAlex fills gaps from its broad aggregation.

### Zotero Synchronization

citations-collector integrates with [Zotero]({{< ref "zotero" >}}) for reference management:

- **Import from Zotero**: pull an existing Zotero library or collection as seed publications
- **Export to Zotero**: push discovered citations back to Zotero for use in writing workflows
- **Sync**: keep the DataLad dataset and Zotero library in sync as new citations are discovered

This bridges the gap between the citation discovery pipeline and the day-to-day reference management that researchers actually use when writing papers.

### PDF Acquisition with Provenance

For each discovered citation, citations-collector attempts to acquire the full-text PDF through legal open-access channels:

- **Unpaywall** -- checks for open-access versions via the Unpaywall API
- **Publisher OA repositories** -- direct links from CrossRef metadata
- **Preprint servers** -- arXiv, bioRxiv, medRxiv, SSRN
- **Institutional repositories** -- where available

Each PDF is stored in git-annex with provenance metadata:

```bash
# git-annex records where the PDF was obtained
git annex whereis pdfs/10.1234-paper-a.pdf
# => web: https://arxiv.org/pdf/2026.12345
# => web: https://doi.org/10.1234/paper-a (via Unpaywall)
```

This means the acquisition source is permanently recorded. If a PDF needs to be re-downloaded (e.g., after a storage failure), git-annex knows where it came from.

### Citation Graph Analysis

Beyond individual citation records, citations-collector builds a citation graph that captures relationships between papers:

```json
{
  "edges": [
    {
      "source": "10.1234/paper-a",
      "target": "10.5678/paper-b",
      "type": "cites",
      "cito_type": "cites_as_data_source"
    }
  ]
}
```

This graph enables analyses like:
- Which of our papers has the most downstream citations?
- What are the key "bridge" papers connecting two research areas?
- Which datasets are most frequently cited by papers in our field?

### DataLad Integration

citations-collector is DataLad-native:

- **Creates proper DataLad datasets** for new citation collections
- **Uses `datalad save`** to commit changes with meaningful messages
- **Supports incremental updates** -- re-running discovery only fetches new citations
- **Tracks provenance** through DataLad run records

## Usage

### Initialize a Citation Collection

```bash
# Create a new citation dataset
citations-collector init my-lab-citations

# Add seed publications (your lab's papers)
citations-collector add-seed --doi 10.1234/our-paper-1
citations-collector add-seed --doi 10.5678/our-paper-2

# Or import seeds from a Zotero collection
citations-collector add-seed --zotero-collection "Lab Papers"
```

### Discover Citations

```bash
# Discover all citing and cited works
citations-collector discover

# This queries CrossRef, OpenCitations, DataCite, and OpenAlex
# and stores results in citations/discovered/
```

### Acquire PDFs

```bash
# Attempt to acquire PDFs for all discovered citations
citations-collector acquire-pdfs

# PDFs are stored in git-annex with provenance URLs
```

### Sync with Zotero

```bash
# Push discovered citations to a Zotero collection
citations-collector sync-zotero --collection "Discovered Citations"
```

### Update

```bash
# Re-run to pick up new citations
citations-collector discover --update

# Only new citations since the last run are fetched
```

## AI Readiness

**Level: ai-ready.**

citations-collector produces highly structured, AI-consumable output at every level:

| Component | Format | AI Use Case |
|-----------|--------|-------------|
| Citation records | YAML with LinkML schema | Metadata extraction, summarization |
| Citation graph | JSON | Network analysis, relationship discovery |
| PDF full text | PDF (many with text layers) | RAG, literature review, question answering |
| Zotero export | JSON/BibTeX | Bibliography generation, duplicate detection |
| LinkML schema | YAML | Schema-aware querying, validation |

The structured metadata and citation graph are immediately usable by LLMs for tasks like:

- "Summarize the key themes across all papers citing our dataset"
- "Identify the most influential papers in this citation network"
- "Generate a literature review section covering these 50 citations"
- "Find papers that cite both our method paper and our competitor's"

The LinkML schema provides type information that AI systems can use for schema-aware processing, reducing hallucination and improving extraction accuracy.

## Limitations and Caveats

- **Alpha status**: The tool is functional but the CLI interface, schema, and output format are still evolving.
- **API rate limits**: CrossRef, OpenCitations, DataCite, and OpenAlex all have rate limits. Large discovery runs need to respect these.
- **PDF availability**: Not all papers have legally accessible PDFs. The acquisition pipeline only uses open-access sources.
- **Zotero API**: Zotero's API has its own rate limits and authentication requirements.
- **Citation completeness**: No single source has complete citation data. The multi-source approach improves coverage but gaps remain, especially for very recent publications.

## See Also

- [Zotero]({{< ref "zotero" >}}) -- reference management integration
- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- publishing citation datasets
- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- API extraction pattern used by citations-collector
