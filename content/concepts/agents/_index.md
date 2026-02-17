---
title: "AI Agents and Vault Operations"
date: 2026-02-17
description: "How AI agents operate within the vault -- discovery, ingestion, architecture, and pipeline monitoring -- and the solidification lifecycle from agent-assisted exploration to deterministic pipelines"
---

The vault is built on git-annex, DataLad, YODA, and STAMPED --
deterministic, version-controlled infrastructure
where every operation has provenance and every artifact has a content address.
AI agents operate *within* this framework, not outside it.

This page describes where AI fits in the vault ecosystem,
how agents are structured,
and the lifecycle by which agent-assisted operations
solidify into deterministic pipelines.

## Where AI Fits in the Vault

AI touches the vault in three distinct roles:

1. **Archival subject** -- AI session transcripts are vault artifacts,
   archived like any other research record.
   See [AI Sessions]({{< ref "tools/ai-sessions" >}}) for the tools.

2. **Classification axis** -- The [AI readiness]({{< ref "about#ai-readiness-levels" >}})
   taxonomy classifies tool outputs by how consumable they are
   for LLM-based workflows (ai-ready, ai-partial, ai-manual).

3. **Operational participant** -- Agents perform discovery, ingestion curation,
   architectural design, and pipeline monitoring
   within the vault's established frameworks.

This page focuses on the third role:
agents as operational participants.

## AI Readiness and Agent Capabilities

The [AI readiness levels]({{< ref "about#ai-readiness-levels" >}})
describe what agents can work with:

- **ai-ready** sources (Slack JSON, GitHub issue exports, citation metadata)
  can feed directly into agent analysis, summarization, and search.
  Agents can reason over this content without preprocessing.
- **ai-partial** sources (web archives with HTML, email with attachments)
  need extraction steps before agent consumption.
  Agents can work with the structured metadata
  but need pipelines for the primary content.
- **ai-manual** sources (video recordings, audio, images)
  require transcription, OCR, or other processing.
  Agents can work with the metadata (titles, timestamps)
  but not the binary content directly.

An agent's effectiveness on a given source
depends on where that source sits on the readiness spectrum.
The [discovery curator](discovery-curator/) assesses this
as part of source inventory.

## The Solidification Lifecycle

Agents provide cognitive flexibility
where deterministic pipelines do not yet exist.
But they are not a permanent substitute for automation.
The goal is **solidification**:
the progression from human judgment through agent-assisted operations
to formalized specifications and deterministic pipelines.

### The Lifecycle

```
manual operation
    → agent-assisted (LLM reasons within framework constraints)
        → formalized specification (the pattern is written down)
            → deterministic pipeline (code implements the spec)
```

At each stage, the operation becomes more reproducible,
cheaper, and less dependent on the specific agent or operator.

| Stage | Who decides | Reproducibility | Cost per operation |
|-------|-------------|-----------------|-------------------|
| **Manual** | Human operator | Low -- depends on memory and notes | High (human time) |
| **Agent-assisted** | LLM within framework constraints | Medium -- follows conventions but non-deterministic | Medium (LLM inference) |
| **Formalized spec** | Written specification | High -- spec is unambiguous | Low (spec is reusable) |
| **Deterministic pipeline** | Code | Perfect -- same inputs, same outputs | Minimal (compute only) |

### Concrete Examples

Each agent's TODO section contains operations
that are candidates for solidification:

- **Ingestion tool detection** (ingestion-curator TODO):
  today the agent reasons about which tool to use for a directory.
  Solidified: if a directory contains `.annextube` config, run `annextube`;
  if it contains `slackdump.yaml`, run `slackdump`.
  The detection logic becomes a deterministic `vault-ingest` CLI.

- **Vault health checks** (pipeline-operator TODO):
  today the agent investigates freshness and storage health ad hoc.
  Solidified: a `vault-status` command reports last ingestion date
  per source against expected schedule;
  `vault-health` checks storage distribution and broken links.

- **Architectural validation** (vault-architect TODO):
  today the agent reviews vault structure against YODA/STAMPED principles.
  Solidified: a `vault-check` command validates metadata completeness,
  distribution-restrictions coverage, and naming conventions
  against a machine-readable specification.

- **Source discovery** (discovery-curator TODO):
  today the agent scans environment configuration manually.
  Solidified: a `vault-discover` CLI reads known configuration locations
  (Ferdium config, rclone remotes, git forges, browser profiles)
  and produces a machine-readable inventory.

### Spec-Driven Development

The specification is the key artifact in solidification.
When an agent discovers a repeatable pattern,
the next step is not to make the agent better at it --
it is to write the pattern down as a specification.

The specification captures:
- What inputs trigger the operation
- What the operation does
- What outputs it produces
- What invariants it maintains

Once the specification exists, anyone (or any tool)
can implement it deterministically.
The agent is no longer needed for that operation.
It moves on to the frontier where patterns have not yet been identified.

This is the opposite of "vibe-coding."
The agent does not replace engineering discipline --
it operates within it, and its discoveries feed back into it.

## Agent Roles

The vault uses specialized agents defined as Claude Code sub-agents
(`.claude/agents/`).
Each agent has a focused role within the vault lifecycle.
The pages linked below show the full agent specification (system prompt)
for each role.

**[Discovery Curator](discovery-curator/)** --
Scans the operator's digital environment for archivable data sources:
messaging platforms, cloud storage, media subscriptions, code forges,
personal data exports.
Operates *before* ingestion -- discovers and inventories sources
for human review, assesses priority based on volatility and risk of loss.

**[Vault Architect](vault-architect/)** --
Designs vault layout, dataset hierarchies, storage strategies,
and distribution policies.
Reasons through trade-offs between YODA, STAMPED, BIDS,
hive partitioning, and other organizational approaches.

**[Ingestion Curator](ingestion-curator/)** --
Formalizes data imports: wraps tool invocations in `datalad run`,
annotates with git-annex metadata (distribution-restrictions, provenance),
classifies ingestion paradigms, and audits existing imports for completeness.

**[Pipeline Operator](pipeline-operator/)** --
Monitors and troubleshoots automated pipelines:
failure triage, freshness checks, escalation resolution,
idempotent recovery via `datalad rerun`.
Primary consumer of the [experience ledger]({{< ref "experience-ledger" >}}).

## Session Archival as Provenance

Agent sessions are themselves vault artifacts.
The conversation between a human operator and an agent --
the questions asked, the reasoning applied, the decisions made --
is a provenance record for whatever operation the agent performed.

These sessions are archived using the tools in
[AI Sessions]({{< ref "tools/ai-sessions" >}}):
[Entire.io]({{< ref "tools/ai-sessions/entire-io" >}}) for git-native capture,
[cctrace]({{< ref "tools/ai-sessions/cctrace" >}}) for Claude Code transcript export,
[Claude Code hooks]({{< ref "tools/ai-sessions/claude-code-hooks" >}})
for lifecycle-triggered archival.

Archived sessions serve a dual purpose:

1. **Provenance trail** -- the session records *why* an architectural decision
   was made, *what* alternatives were considered,
   and *who* (human or AI) made each judgment call.

2. **Experience ledger input** -- patterns discovered during agent sessions
   (failure modes, source-specific quirks, operational heuristics)
   feed into the [experience ledger]({{< ref "experience-ledger" >}}),
   compressing session-level observations into reusable knowledge.

## See Also

- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) --
  the execution and orchestration layer that agents operate within
- [Experience Ledger]({{< ref "experience-ledger" >}}) --
  compressed operational knowledge that agents both consume and produce
- [Ingestion Patterns]({{< ref "ingestion-patterns" >}}) --
  the paradigms agents use to classify data sources
- [Vault Organization]({{< ref "vault-organization" >}}) --
  the structural framework agents design within
- [AI Sessions]({{< ref "tools/ai-sessions" >}}) --
  tools for archiving agent session transcripts
- [AI Readiness Levels]({{< ref "about#ai-readiness-levels" >}}) --
  classification of tool outputs for AI consumption
