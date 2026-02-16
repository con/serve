---
title: "Annotation Garden"
date: 2026-02-16
description: "Open infrastructure for collaborative, standards-based annotation of neuroscience stimuli using git branches as annotation layers"
summary: "An initiative providing open infrastructure for collaborative annotation of stimuli used in neuroscience research. Uses git branches as stackable annotation layers, BIDS/HED standards for interoperability, and AI-accelerated annotation generation with human refinement. Directly relevant to ReproStim-captured audio/video stimuli and generalizable to any experiment with media needing temporal annotation."
categories: ["Infrastructure"]
tags: ["annotation", "HED", "BIDS", "neuroscience", "stimuli", "video", "images", "AI", "ReproStim", "CON-contrib"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/annotation-garden"
  homepage: "https://annotation.garden"
  issues: "https://github.com/annotation-garden/management/issues"
  docs: "https://docs.annotation.garden"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
---

## Overview

The [Annotation Garden Initiative](https://annotation.garden) addresses a fundamental
problem in neuroscience: labs repeatedly re-annotate identical stimuli in isolation.
The same movie clip, the same image set, the same audio stimulus gets described
from scratch by each research group that uses it.
Those annotations end up in supplementary materials or lab servers
and are lost when people move on.

Annotation Garden provides open infrastructure for **collaborative, cumulative annotation**
of shared stimuli, built on git-based collaboration, BIDS/HED standards compliance,
and AI-accelerated annotation generation.

## Core Design

### Branches as Annotation Layers

Different annotation perspectives -- scene descriptions, emotional valence,
object inventories, auditory events -- live on separate git branches.
Branches can be stacked, merged, and compared,
letting multiple research groups contribute complementary annotations
to the same stimulus set without conflicts.

This is a natural fit for git-annex/DataLad repositories:
the stimulus media lives in git-annex (content-addressed, large files),
while annotations live in git proper (small, structured, diffable).

### Standards-Based

All annotations target established neuroscience specifications:

- **[HED](https://www.hedtags.org/)** (Hierarchical Event Descriptors) --
  a standardized vocabulary and syntax for describing events in experiments.
  Machine-readable, composable, and supported by BIDS.
- **[BIDS](https://bids-specification.readthedocs.io/)** --
  particularly the Stim-BIDS extension for stimulus file organization
  and events files for temporal annotations.
- **[OpenNeuro](https://openneuro.org)** integration for publishing annotated datasets.

### AI-Accelerated, Human-Refined

Vision Language Models generate initial annotation drafts;
humans review, correct, and refine.
This flips the annotation workflow from manual-first to AI-draft-first,
significantly reducing the effort for large stimulus sets
while keeping human judgment as the final authority.

## Components

### HEDit

[HEDit](https://github.com/annotation-garden/HEDit) is a multi-agent system
(built on LangGraph) that converts natural language descriptions
into valid HED annotation strings.
Four agents operate in a feedback loop:

1. **Annotation Agent** -- generates initial HED tags from descriptions
2. **Validation Agent** -- checks syntax against the HED schema
3. **Evaluation Agent** -- assesses whether annotations match the description
4. **Assessment Agent** -- final completeness check

The loop runs until annotations pass all checks or reach a retry limit.
Supports multiple LLM backends via OpenRouter.

### Image Annotation Tool

[image-annotation](https://github.com/annotation-garden/image-annotation) is a
web-based tool for annotating static images using VLMs
(OLLAMA local models, GPT-4V, Claude).
Targets large-scale datasets -- designed to handle 25K+ annotations
with batch processing and progress tracking.
Outputs BIDS-compliant JSON with HED tags.

## Flagship Datasets

| Dataset | Phase | Scope |
|---------|-------|-------|
| Natural Scenes Dataset (NSD) | Active (Phase 1) | 73,000 COCO images from 7T fMRI studies |
| Forrest Gump | Phase 2 (Q2 2026) | 2-hour film with temporal annotations |
| HBN Movies | Phase 3 (Q3-Q4 2026) | Developmental EEG movie-watching collection |

## Relevance to ReproStim

[ReproStim](https://github.com/ReproNim/reprostim) captures audio/video stimuli
during neuroimaging experiments -- screen recordings, stimulus presentations,
timing synchronization via QR codes.
The captured media lands in git-annex as `ai-manual` binary content.

Annotation Garden provides the **annotation layer** that makes this media useful
beyond raw archival:

- Temporal annotations of what happens when in a stimulus video
  (scene changes, speech events, visual objects appearing/disappearing)
- Semantic tagging using HED vocabulary so annotations are machine-readable
  and comparable across studies
- AI-generated initial annotations that reduce the manual effort
  of describing hours of stimulus footage

The combination is: ReproStim captures and archives the stimuli,
Annotation Garden annotates them,
and the result is a BIDS-compliant dataset where both the raw media
and its structured annotations live in the same git-annex/DataLad repository.

More broadly, this pattern applies to **any experiment with audio/video
that needs annotation** -- not just neuroimaging.
The git-branch-as-layer model and HED vocabulary are domain-general enough
to support behavioral experiments, linguistic studies,
or any research involving temporal media annotation.

## git-annex / DataLad Integration

**Integration level: git-only.**

Annotations are structured text (HED strings in BIDS events files, JSON sidecars)
that belong in git proper, not git-annex.
The stimuli they annotate are large binary files that belong in git-annex.
This clean split is exactly how BIDS datasets already work:
metadata in git, data in git-annex.

## AI Readiness

**Level: ai-ready.**

The entire point of HED annotations is machine-readability.
HED-annotated events files are structured, standardized,
and directly consumable by analysis pipelines and LLM-based workflows.
Annotation Garden's own tooling (HEDit) demonstrates this:
LLMs can both generate and consume HED annotations.

## See Also

- [Domain Extensions]({{< ref "domain-extensions" >}}) -- how con/serve extends to neuroimaging and other domains
- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) -- ReproStim capture-to-annotation pipelines
- [Data-Visualization Separation]({{< ref "data-visualization-separation" >}}) -- annotations as a metadata layer over archived media
