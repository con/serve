---
title: "HedgeDoc"
date: 2026-02-12
description: "Collaborative real-time markdown editor for research documentation and notes"
summary: "Self-hosted collaborative markdown editor for meeting notes, lab notebooks, and documentation. Documents are exported and committed to git for long-term preservation."
categories: ["Infrastructure"]
tags: ["collaborative", "markdown", "editor", "real-time", "documentation"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/hedgedoc/hedgedoc"
  homepage: "https://hedgedoc.org"
  issues: "https://github.com/hedgedoc/hedgedoc/issues"
  language: "TypeScript"
  license: "AGPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "Psychoinformatics HedgeDoc"
      url: "http://hedgedoc.psychoinformatics.de/"
    - title: "HedgeDoc Demo"
      url: "https://demo.hedgedoc.org/"
---

## Overview

[HedgeDoc](https://hedgedoc.org) is a self-hosted, real-time collaborative markdown editor. It fills the same niche as Google Docs or HackMD but runs on your own infrastructure with no SaaS dependency. Multiple users can edit the same document simultaneously with live preview, making it ideal for meeting notes, lab notebooks, brainstorming sessions, and collaborative writing.

In the con/serve stack, HedgeDoc serves as the **working surface** where ephemeral collaborative text is created. The preservation step happens when documents are exported as markdown files and committed to a git repository -- typically one hosted on [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}).

## Key Features

- **Real-time collaboration** -- multiple simultaneous editors with cursor tracking and live preview
- **Markdown-native** -- documents are plain markdown with extensions for diagrams (Mermaid), math (MathJax/KaTeX), and embedded media
- **Self-hosted** -- runs on your own server, no account on an external service needed
- **Export options** -- download as markdown, HTML, or raw text
- **Slide mode** -- present markdown documents as slide decks
- **Permission model** -- documents can be private, editable by logged-in users, or publicly readable

## git-annex / DataLad Integration

**Integration level: external.**

HedgeDoc does not natively integrate with git. The workflow for preserving HedgeDoc content in a DataLad dataset is:

1. **Export documents** from HedgeDoc as markdown files (manually or via the API)
2. **Commit to git** in a DataLad dataset alongside other project artifacts
3. **Track changes** through standard git version control

Because HedgeDoc documents are plain markdown, they integrate cleanly into any git workflow. A periodic export script can automate this:

```bash
# Export a HedgeDoc document via its API
curl -s https://hedgedoc.lab.example.org/api/notes/NOTEID/content \
    -H "Authorization: Bearer $TOKEN" > meeting-notes/2026-02-12.md

# Commit to DataLad dataset
datalad save -m "Export meeting notes 2026-02-12" meeting-notes/
```

## AI Readiness

**Level: ai-ready.**

HedgeDoc documents are markdown text -- the most AI-friendly format possible. Exported documents can be directly consumed by LLMs for summarization, question answering, or knowledge extraction without any format conversion.

## Role in the con/serve Stack

HedgeDoc provides the **collaborative editing surface** that research teams need for day-to-day documentation. It is deployed as part of the [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) infrastructure bundle, giving every research group an instant, self-hosted alternative to Google Docs or Notion.

## See Also

- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) -- deploys HedgeDoc as part of the full infrastructure stack
- [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- hosts the git repos where exported documents are stored
