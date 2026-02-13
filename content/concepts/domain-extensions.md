---
title: "Domain Extensions"
date: 2026-02-12
description: "How the generic con/serve archival platform extends for domain-specific workflows and standards"
---

The con/serve platform is **media-agnostic** at its core. git-annex does not care whether a file is a video, a DICOM scan, a genome sequence, or a PDF -- it stores content-addressed blobs and tracks their locations. DataLad does not care whether a dataset holds Slack exports or neuroimaging data -- it manages versioned collections of files.

This generality is a strength, but real research domains have specific needs: specialized file formats, conversion pipelines, metadata standards, and community archives. **Domain extensions** layer these domain-specific concerns on top of the generic con/serve platform without modifying its core.

## The Extension Model

A domain extension adds four layers to the generic platform:

### 1. Domain-Specific Ingestion

Specialized tools for acquiring data in domain formats:

- **What formats** are produced by instruments and services in this domain?
- **What tools** convert raw acquisitions into standardized representations?
- **What metadata** must be captured alongside the data?

### 2. Conversion Pipelines

Transformations from raw/proprietary formats to community standards:

- **What community standard** does this domain use? (BIDS, NWB, FASTQ, TEI, etc.)
- **What tools** perform the conversion?
- **What validation** ensures correctness?

### 3. Publishing Targets

Domain-specific archives and repositories:

- **Where** does this domain publish datasets?
- **What metadata schemas** do these archives require?
- **What tools** handle the submission process?

### 4. Metadata Standards

Controlled vocabularies, ontologies, and schemas:

- **What ontologies** describe this domain's data?
- **How** are they represented in the DataLad dataset metadata?

## Example: Neuroimaging Extension

Neuroimaging is the most developed domain extension in the con/serve ecosystem, reflecting its origins in the [Center for Open Neuroscience](https://centerforopenneuroscience.org/).

### Ingestion

| Source | Tool | Output |
|--------|------|--------|
| MRI scanner (DICOM) | Direct acquisition / PACS export | Raw DICOM files |
| Stimuli presentation | [ReproStim](https://github.com/ReproNim/reprostim) | Stimulus logs, screen recordings |
| Behavioral events | CurDes BIRCH | Event timing files |
| Environmental sensors | Custom loggers | Temperature, humidity, noise logs |

### Conversion

| From | To | Tool |
|------|-----|------|
| DICOM | BIDS | [HeuDiConv](https://github.com/nipy/heudiconv) with [ReproIn](https://github.com/repronim/reproin) naming |
| Raw physiology | BIDS physio | Custom scripts |
| Stimulus logs | BIDS events | ReproStim exporters |

The [BIDS](https://bids-specification.readthedocs.io/) (Brain Imaging Data Structure) standard defines directory layouts, naming conventions, and metadata files for neuroimaging datasets. HeuDiConv and ReproIn automate the conversion from scanner-native DICOM to BIDS-compliant DataLad datasets.

### Publishing

| Target | Tool | What Gets Published |
|--------|------|-------------------|
| [OpenNeuro](https://openneuro.org) | `datalad push` / OpenNeuro CLI | BIDS datasets |
| [DANDI](https://dandiarchive.org) | `datalad-dandi` | NWB neurophysiology data |
| [EMBER](https://ember.science) | DataLad publish | Multi-modal brain data |
| [OSF](https://osf.io) | `datalad-osf` | Any dataset |

### Metadata Standards

- **BIDS** -- file naming, directory structure, JSON sidecars
- **NWB** (Neurodata Without Borders) -- electrophysiology data format
- **NIDM** (Neuroimaging Data Model) -- provenance and results reporting

## Other Potential Domain Extensions

The extension model is not limited to neuroimaging. Any research domain with specialized formats, conversion needs, and publishing targets can define its own extension.

### Genomics

| Layer | Examples |
|-------|----------|
| Ingestion | FASTQ from sequencers, BAM/CRAM from alignment |
| Conversion | Raw reads to aligned, annotated genomes |
| Publishing | SRA, ENA, GEO, dbGaP |
| Standards | FASTQ, BAM, VCF, BED |

### Environmental Science

| Layer | Examples |
|-------|----------|
| Ingestion | Sensor networks, satellite imagery, weather stations |
| Conversion | Raw telemetry to NetCDF, CF conventions |
| Publishing | PANGAEA, EOSDIS, DataONE |
| Standards | CF conventions, ISO 19115, EML |

### Digital Humanities

| Layer | Examples |
|-------|----------|
| Ingestion | Digitized manuscripts, archival photographs, oral histories |
| Conversion | OCR, TEI encoding, IIIF manifests |
| Publishing | HathiTrust, Internet Archive, institutional repositories |
| Standards | TEI, Dublin Core, METS, IIIF |

## Building a Domain Extension

A domain extension is not a formal plugin system -- it is a pattern. To create one:

1. **Identify the domain-specific tools** that your community already uses
2. **Document the ingestion sources** and the formats they produce
3. **Define conversion pipelines** from raw to standardized formats
4. **List the publishing targets** and their submission requirements
5. **Map the metadata standards** to DataLad dataset metadata

The result is a set of documentation, scripts, and configurations that sit alongside the generic con/serve tools. The core platform handles storage, versioning, and distribution; the domain extension handles everything that is specific to your field.

## See Also

- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) -- generic ingestion strategies used by domain extensions
- [Conservation to External Resources]({{< ref "conservation-to-external" >}}) -- outbound distribution including domain archives
