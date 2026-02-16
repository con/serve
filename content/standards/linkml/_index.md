---
title: "LinkML"
description: "Linked data Modeling Language -- the common denominator for custom metadata schemas in the con/serve ecosystem"
---

[LinkML](https://linkml.io/) is a modeling language for defining data schemas
that can generate JSON Schema, SHACL, SQL DDL, Python dataclasses, and more
from a single YAML source definition.

LinkML serves as the **common denominator for custom metadata schemas**
in the con/serve ecosystem.
By defining schemas in LinkML rather than ad-hoc JSON or YAML,
tools gain automatic validation, documentation generation,
and interoperability with linked data standards.

Used by:
- [citations-collector]({{< ref "citations-collector" >}}) -- citation data model aligned with CiTO/FaBiO ontologies
- [Experience Ledger]({{< ref "experience-ledger" >}}) -- dataset identity and operational knowledge schemas
- [concepts.datalad.org](https://concepts.datalad.org) -- the DataLad metadata vocabulary

Adopting LinkML as the standard schema language means
any tool in the ecosystem can consume schemas defined by other tools,
validate metadata at ingest time,
and produce output that conforms to shared vocabularies.
