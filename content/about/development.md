---
title: "Development Roadmap"
date: 2026-02-17
description: "Active and planned development tracks for the con/serve platform -- containerized tools, deployment testing, and ingestion skills"
---

This page outlines the active and near-term development tracks
for the con/serve platform.
Each track is a concrete workstream with a defined goal,
not a speculative wish list.

## Track 1: Containerized Ingestion Tool Collection

**Goal:** A curated collection of OCI containers,
each packaging one ingestion tool with its dependencies,
for consistent and reliable deployment across environments.

### Motivation

Ingestion tools have heterogeneous dependencies --
slackdump needs Go, annextube needs Python and yt-dlp,
tg-archive needs Python, ArchiveBox needs Node and Chromium.
Installing them all on a single host creates conflicts
and makes reproducible deployment difficult.

Containers solve this:
each tool runs in an isolated environment with pinned dependencies,
and the collection can be tested as a unit.

### Scope

The initial collection should cover the tools
from the [user stories](/user-stories/) data sources:

| Container | Tool(s) | User stories |
|-----------|---------|-------------|
| `conserve/slackdump` | [slackdump]({{< ref "slackdump" >}}) | [Neuroimaging Lab]({{< ref "neuroimaging-lab" >}}), [Software Project]({{< ref "software-project" >}}) |
| `conserve/annextube` | [annextube]({{< ref "annextube" >}}), yt-dlp | [Personal Archive]({{< ref "personal-archive" >}}) |
| `conserve/tg-archive` | [tg-archive]({{< ref "tg-archive" >}}) | [Personal Archive]({{< ref "personal-archive" >}}) |
| `conserve/git-bug` | [git-bug]({{< ref "git-bug" >}}) | [Software Project]({{< ref "software-project" >}}), [Neuroimaging Lab]({{< ref "neuroimaging-lab" >}}) |
| `conserve/tinuous` | [con/tinuous]({{< ref "tinuous" >}}) | [Software Project]({{< ref "software-project" >}}), [Neuroimaging Lab]({{< ref "neuroimaging-lab" >}}) |
| `conserve/github-backup` | [python-github-backup]({{< ref "github-backup" >}}) | [Software Project]({{< ref "software-project" >}}) |
| `conserve/gh-export` | [gh-discussions-export]({{< ref "gh-discussions-export" >}}), [gh-md]({{< ref "gh-md" >}}) | [Software Project]({{< ref "software-project" >}}) |

### Design Considerations

- **Base image**: minimal Debian or Alpine,
  with git and git-annex pre-installed
  so containers can interact with vault datasets directly
- **Entrypoint pattern**: each container wraps the tool
  such that it can be invoked as a `datalad run` command,
  enabling provenance-tracked ingestion
- **Registry**: containers published to a registry
  accessible from the [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) deployment
  and from HPC environments (via Singularity/Apptainer conversion)
- **Testing**: each container tested against a synthetic vault
  to verify the ingestion workflow end-to-end

### Relationship to datalad-container

These containers complement [datalad-container]({{< ref "datalad-container" >}}),
which manages containers for *processing* (BIDS Apps).
The ingestion containers serve a different role --
they bring data *into* the vault rather than processing data already in it --
but the registration and invocation patterns should be compatible.

## Track 2: Lab-in-a-Box Deployment and Testing

**Goal:** Streamline the [Lab-in-a-Box]({{< ref "lab-in-a-box" >}})
deployment of Forgejo-Aneksajo, HedgeDoc, and associated services,
with automated testing against the user story scenarios.

### Current State

The `projects/liab-conserve/` directory contains
a working `podman-compose` development stack:

| Service | Status |
|---------|--------|
| [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) (behind go-away proxy) | Working |
| [HedgeDoc]({{< ref "infrastructure/hedgedoc" >}}) | Working |
| User provisioning scripts | Working |
| Vagrant VM testing (Debian, Ubuntu, Rocky) | Working |

The pyinfra deployment in `projects/liab-deployments/`
targets bare Debian servers with rootless Podman and systemd user units.

### Development Goals

1. **Integrate ingestion containers** --
   the containerized tool collection (Track 1)
   should be deployable alongside the core services.
   A Lab-in-a-Box deployment should include
   not just the forge and editor,
   but the ingestion tools needed for the target use case.

2. **User story test scenarios** --
   automated tests that exercise real ingestion workflows
   against the deployed stack:
   - Create a vault on Forgejo-Aneksajo
   - Run an ingestion container to import test data
   - Verify the dataset structure, metadata, and provenance
   - Test distribution-restrictions enforcement

3. **GitHub OAuth integration** --
   the [Software Project]({{< ref "software-project" >}}) story
   requires Forgejo to authenticate via GitHub OAuth
   and sync team memberships.
   This needs to be a tested, documented deployment option.

4. **Multi-distro testing** --
   the Vagrant setup already targets Debian, Ubuntu, and Rocky.
   CI should exercise deployments on all three
   to catch distribution-specific issues.

### Relation to Production

The liab-conserve compose stack is the development environment;
liab-deployments is the production deployment tool.
Changes should flow from dev (compose) to production (pyinfra)
after testing in Vagrant VMs.

## Track 3: Ingestion Skills for Agent-Assisted Operations

**Goal:** Create the first Claude Code skills (`.claude/commands/`)
that encode repeatable ingestion workflows,
bridging the gap between ad-hoc agent use
and the [solidified pipelines]({{< ref "concepts/agents#the-solidification-lifecycle" >}})
they will eventually become.

### Motivation

The [agent TODO sections]({{< ref "concepts/agents#concrete-examples" >}})
identify operations that are candidates for solidification.
Skills are the intermediate step:
more structured than a freeform agent conversation,
less rigid than a deterministic CLI tool.

A skill encodes:
- What questions to ask (source type, access credentials, vault location)
- What tools to invoke and in what order
- What metadata to set
- What verification to perform

Both human operators and agents can invoke skills identically
(`/vault.add-source`, `/vault.discover`),
making them the shared interface
between human and AI-assisted operations.

### Initial Skill Set

Derived from agent TODOs and user story workflows:

| Skill | Agent | Purpose |
|-------|-------|---------|
| `/vault.discover` | discovery-curator | Scan environment for archivable data sources, produce prioritized inventory |
| `/vault.add-source` | ingestion-curator | Walk through adding a new data source: classify ingestion paradigm, create `datalad run` wrapper, set metadata |
| `/vault.audit-ingestion` | ingestion-curator | Audit existing imports for metadata completeness, provenance coverage, idempotency |
| `/vault.triage` | pipeline-operator | Investigate a pipeline failure: check logs, consult experience ledger, propose resolution |
| `/vault.layout` | vault-architect | Design or review vault directory structure against YODA/STAMPED conventions |

### Development Approach

Start with `/vault.add-source` --
it is the most commonly needed operation
and touches all the concepts
(ingestion patterns, metadata annotation, distribution-restrictions, `datalad run`).

The skill should:

1. Ask what kind of source is being added
   (messaging, media, code artifacts, etc.)
2. Identify the appropriate tool from the catalog
3. Generate the `datalad run` wrapper command
4. Specify metadata annotations
5. Recommend a vault location following conventions
6. If a container exists (Track 1), use it

Each skill invocation produces structured output
that can be reviewed, edited, and committed.
Over time, patterns that recur across invocations
become candidates for solidification into deterministic CLI commands --
the `/vault.add-source` skill might eventually generate
a `vault-ingest` config file that a CLI tool consumes.

## Dependencies Between Tracks

```
Track 1: Containers ─────────┐
                              ├──→ Track 2: LiaB Testing
Track 2: LiaB Deployment ────┘        (test containers in deployed stack)
                                           │
Track 3: Skills ───────────────────────────┘
    (skills invoke containers,
     test against deployed stack)
```

Track 1 and Track 2 can proceed in parallel.
Track 3 benefits from both but can start independently
with skills that invoke tools directly (without containers).

## See Also

- [AI Agents and Vault Operations]({{< ref "concepts/agents" >}}) --
  the agent roles and solidification lifecycle that motivate Track 3
- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) --
  the deterministic pipelines that skills will eventually become
- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) --
  the deployment framework that Track 2 extends
- [Contributing]({{< ref "about/contributing" >}}) --
  how to contribute tools and content to con/serve
