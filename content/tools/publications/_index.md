---
title: "Publications"
date: 2026-02-12
description: "Tools for conserving scholarly output, citations, PDFs, and reference collections"
cascade:
  showEdit: true
---

Scholarly publications are the most formal research artifacts,
yet the full pipeline from citation discovery to PDF acquisition
is surprisingly fragile.
DOIs resolve to paywalled pages, preprint servers reorganize,
and personal reference libraries live in proprietary databases
that do not interoperate cleanly.

This section catalogs tools for building durable, version-controlled
collections of scholarly references and their full-text content.

## Scope

**Citation Discovery and Curation** --
Finding all works that cite, are cited by, or are related to
a given set of publications.
[citations-collector](citations-collector/) automates this across
CrossRef, OpenCitations, DataCite, and OpenAlex.

**PDF Acquisition** --
Obtaining full-text PDFs through legal open-access channels
(Unpaywall, publisher OA repositories, preprint servers)
and archiving them with provenance metadata in git-annex.

**Reference Management** --
Synchronizing curated collections with reference managers like
[Zotero](zotero/) for collaborative bibliography management,
BetterBibTeX export, and integration with writing workflows.

## Why Version-Control References?

A reference collection is a living dataset.
New citations appear as papers accumulate downstream citations.
PDFs get updated when authors post corrections.
Metadata improves as aggregators reconcile records.

By storing references and PDFs in a DataLad dataset,
every change is tracked, reproducible, and attributable --
the same principles that apply to code and data
apply to the scholarly record itself.
