---
title: "Concepts"
date: 2026-02-12
description: "Cross-cutting patterns for ingestion, conservation, and distribution of research artifacts"
cascade:
  showEdit: true
---

The [Tools](/tools/) section catalogs individual tools.
The [Infrastructure](/infrastructure/) section describes the services that host them.
This section describes the **patterns and architectural concepts**
that tie everything together.

These are not tool-specific -- they apply across artifact types
and describe *how* the con/serve ecosystem works as a whole.

## Topics

**[Ingestion Patterns](ingestion-patterns/)** --
Common strategies for pulling data into git-annex repositories:
direct download, API extraction, crawling, mounting, and bridging.

**[Conservation to External Resources](conservation-to-external/)** --
How to publish and back up from your git-annex vault
to cloud storage, domain archives, and institutional repositories.

**[Vault Organization](vault-organization/)** --
Survey of directory organization approaches --
PARA, Johnny Decimal, BagIt, OCFL, RO-Crate, BIDS, hive partitioning --
and the principles that should guide
the layout of a heterogeneous DataLad superdataset vault.

**[Data-Visualization Separation](data-visualization-separation/)** --
The MVC principle applied to archived data:
keep collected data in standard formats (TSV, JSON, Parquet),
build hierarchical summaries for navigation,
and let use-case-appropriate viewers (VisiData, Datasette, custom HTML) attach freely.

**[Domain Extensions](domain-extensions/)** --
How the generic con/serve platform extends
to domain-specific workflows like neuroimaging, genomics, or digital humanities,
adding specialized formats, conversion pipelines, and publishing targets.
