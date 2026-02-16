---
title: "Standards and Formats"
description: "Data standards, file formats, and schema languages used across the con/serve ecosystem"
---

Tools and datasets in the con/serve ecosystem touch a variety of
data standards, file formats, and schema definition languages.
This taxonomy tracks which standards each tool or concept page involves,
making it easy to find everything related to a particular standard.

### Domain Standards

Standards that define how data is organized and described
within specific research domains.
While the con/serve platform itself is domain-agnostic,
the neuroscience ecosystem provides the most developed examples.
See the [poster on the ecosystem of standards in neurosciences](https://zenodo.org/records/18333008)
for an overview of how these standards interrelate.

### File Formats

Structured text formats used for metadata, summaries, and configuration
throughout the vault: [JSON](/standards/json/), [JSON-LD](/standards/json-ld/),
[YAML](/standards/yaml/), [TSV](/standards/tsv/).
These are the working formats that tools produce and consumers read.

### Schema Languages

Languages for defining and validating metadata schemas.
[LinkML](/standards/linkml/) is the common denominator for custom schemas
in the con/serve ecosystem -- used by citations-collector,
the experience ledger, and aligned with [concepts.datalad.org](https://concepts.datalad.org).
[JSON Schema](/standards/json-schema/) provides runtime validation.
