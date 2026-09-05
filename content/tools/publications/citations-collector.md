---
title: "citations-collector"
date: 2026-02-12
description: "Multi-source scholarly citation discovery, open-access PDF acquisition, and Zotero sync, designed to run under datalad run with PDFs in git-annex"
summary: "Discovers citations across CrossRef, OpenCitations, DataCite, and OpenAlex; syncs with Zotero; fetches open-access PDFs via Unpaywall into git-annex; and records everything in TSV files following a LinkML schema aligned with CiTO and FaBiO. Built to be driven by datalad run inside a DataLad dataset, as dandi-bib does daily."
categories: ["Publications"]
tags: ["CON", "citations", "scholarly", "crossref", "opencitations", "datacite", "openalex", "zotero", "pdf", "provenance"]
media_types: ["publications"]
standards: ["LinkML", "TSV", "YAML"]
integrations: ["native-datalad"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/con/citations-collector"
  homepage: "https://github.com/con/citations-collector"
  issues: "https://github.com/con/citations-collector/issues"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-09"
  examples:
    - title: "dandi-bib citations pipeline"
      url: "https://github.com/dandi/dandi-bib/tree/master/citations"
---

**citations-collector** is a tool for building and maintaining comprehensive, version-controlled collections of scholarly citations. Given a set of seed publications (your lab's papers, a project's key references), it discovers citing works across multiple sources, fetches open-access PDFs where available, syncs with Zotero for reference management, and records everything in plain TSV files that can be tracked in git, with PDFs optionally in git-annex.

## The Problem

Scholarly citation management is fragmented:

- **Discovery** is scattered across databases: CrossRef has DOI metadata, OpenCitations has citation graphs, DataCite covers datasets, OpenAlex aggregates from multiple sources. No single service has complete coverage.
- **PDF acquisition** is manual: you search Google Scholar, check Unpaywall, try preprint servers, and download one PDF at a time. The provenance (where did this PDF come from?) is lost.
- **Reference management** lives in Zotero or Mendeley -- proprietary databases that do not version-track changes or integrate with data management workflows.
- **Citation relationships** (who cites whom, and how) are not captured in reference managers at all.

citations-collector addresses the first three in a single, file-based workflow, and takes a first step on the fourth by classifying citation relationships with CiTO types.

## Architecture

```
my-citations//                         # DataLad dataset
  collection.yaml                      # Seed publications and settings (input)
  citations.tsv                        # Discovered citations with per-source provenance (git)
  pdfs/
    <doi>/article.pdf                  # git-annex
    <doi>/article.bib                  # BibTeX record for the PDF (git)
    <doi>/extracted_citations.json     # citation contexts from the PDF (git-annex)
    <doi>/classifications.json         # CiTO classification of each context
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

For each discovered citation, `fetch-pdfs` looks up an open-access copy through the [Unpaywall](https://unpaywall.org/) API. With `--git-annex`, each PDF is added to git-annex with its download URL registered, so `git annex whereis` shows where it came from and `git annex get` can re-fetch it after a storage failure. Other OA channels (preprint servers, institutional repositories) are not queried directly.

### Citation Context and Classification

Two further subcommands go beyond the citation list: `extract-contexts` pulls the sentences around each citation out of the fetched PDFs, and `classify` uses an LLM to label the relationship with CiTO types (cites as data source, cites as authority, and so on). `detect-merges` flags records that refer to the same work.

### Designed for `datalad run`

citations-collector does not call DataLad itself; it is built to be *driven by*
`datalad run` inside a DataLad dataset. Every output is a plain file --
`citations.tsv` diffs cleanly in git, PDFs and extracted contexts go to
git-annex -- and each pipeline step is idempotent and incremental, so
re-running a `datalad run` record does the right thing. See the integration
section below for the workflow this was developed against.

## Usage

```bash
# Describe the seed publications in collection.yaml, then discover citing works
# (--email joins CrossRef's polite pool; --sources selects the databases)
citations-collector discover collection.yaml --email you@example.org --output citations.tsv

# Seeds given as GitHub repositories or Zenodo concept records are expanded to DOIs
citations-collector discover collection.yaml --expand-refs --output citations.tsv

# Import an existing Zotero library or a DANDI dataset's references as seeds
citations-collector import-zotero --help
citations-collector import-dandi --help

# Fetch open-access PDFs (with a BibTeX file next to each), tracking them in git-annex
citations-collector fetch-pdfs --config collection.yaml --git-annex

# Flag records that refer to the same work
citations-collector detect-merges --config collection.yaml --fuzzy-match

# Push the collection to Zotero
citations-collector sync-zotero --config collection.yaml

# Re-run discovery: incremental by default, --full-refresh to start over
citations-collector discover collection.yaml --full-refresh --output citations.tsv
```

The [USAGE guide](https://github.com/con/citations-collector/blob/master/USAGE.md) walks through the bundled ReproNim and DANDI example collections.

## AI Readiness

**Level: ai-ready.**

citations-collector produces highly structured, AI-consumable output at every level:

| Component | Format | AI Use Case |
|-----------|--------|-------------|
| Citation records | TSV following a LinkML schema | Metadata extraction, summarization, DuckDB queries |
| Citation contexts | JSON | Why-cited analysis, CiTO classification |
| PDF full text | PDF (many with text layers) | RAG, literature review, question answering |
| Zotero library | via `sync-zotero` | Bibliography generation, duplicate detection |
| LinkML schema | YAML | Schema-aware querying, validation |

The structured metadata and citation contexts are immediately usable by LLMs for tasks like:

- "Summarize the key themes across all papers citing our dataset"
- "Identify the most influential papers in this citation network"
- "Generate a literature review section covering these 50 citations"
- "Find papers that cite both our method paper and our competitor's"

The LinkML schema provides type information that AI systems can use for schema-aware processing, reducing hallucination and improving extraction accuracy.

## Limitations

- **Alpha status**: The tool is functional but the CLI interface, schema, and output format are still evolving.
- **API rate limits**: CrossRef, OpenCitations, DataCite, and OpenAlex all have rate limits. Large discovery runs need to respect these.
- **PDF availability**: Not all papers have legally accessible PDFs. Acquisition uses Unpaywall only.
- **Zotero API**: Zotero's API has its own rate limits and authentication requirements.
- **Citation completeness**: No single source has complete citation data. The multi-source approach improves coverage but gaps remain, especially for very recent publications.

## See Also

- [Zotero]({{< ref "zotero" >}}) -- reference management integration
- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- publishing citation datasets
- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- API extraction pattern used by citations-collector
- [LinkML]({{< ref "/standards/linkml" >}}) -- the schema language behind the data model
