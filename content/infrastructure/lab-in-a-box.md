---
title: "Lab-in-a-Box"
date: 2026-02-12
description: "Complete research lab infrastructure deployment using pyinfra, bundling Forgejo-Aneksajo, HedgeDoc, and supporting services"
summary: "A pyinfra-based deployment that installs and configures an entire research infrastructure stack -- Forgejo-Aneksajo, HedgeDoc, and supporting services -- on a single server or set of servers. Configuration as code, stored in git."
categories: ["Infrastructure"]
tags: ["CON-contrib", "MIH", "deployment", "lab", "infrastructure", "forgejo", "hedgedoc", "pyinfra", "complete-stack"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments"
  homepage: "https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments"
  issues: "https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments/issues"
  language: "Python"
  license: "MIT"
  maturity: "alpha"
  last_verified: "2026-02"
  examples:
    - title: "Psychoinformatics Hub"
      url: "https://hub.psychoinformatics.de"
---

**Lab-in-a-Box** (LiaB) is a [pyinfra]({{< ref "pyinfra" >}})-based deployment project that bundles the entire con/serve infrastructure stack into a single, reproducible deployment. The goal is simple: give a research group a server (physical or virtual), run one deployment, and have a fully configured research infrastructure ready to use.

## The Problem

Setting up self-hosted research infrastructure is tedious and error-prone. A typical lab needs:

- A **git forge** that supports large files and DataLad datasets
- A **collaborative editor** for meeting notes and documentation
- **TLS certificates**, **reverse proxies**, and **DNS configuration**
- **Backup schedules**, **monitoring**, and **log aggregation**
- **User management** and **authentication** across services

Each service has its own installation procedure, configuration format, and operational requirements. Most research groups either give up and use SaaS (losing control of their data) or spend weeks on manual setup that is never documented well enough to reproduce.

## The Solution

Lab-in-a-Box encodes all of this in Python using pyinfra. The deployment is:

- **Declarative** -- the desired state is described in Python, pyinfra makes it so
- **Idempotent** -- running the deployment again after changes only applies the delta
- **Version-controlled** -- the entire deployment configuration lives in a git repository
- **Composable** -- individual services can be deployed or updated independently

## What Gets Deployed

A Lab-in-a-Box deployment sets up the following services:

### Core Services

| Service | Purpose | Details |
|---------|---------|---------|
| [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) | Git forge with git-annex support | Primary dataset hosting, code repos, issue tracking |
| [HedgeDoc]({{< ref "hedgedoc" >}}) | Collaborative markdown editor | Meeting notes, lab notebooks, brainstorming |

### Supporting Infrastructure

| Component | Purpose |
|-----------|---------|
| Reverse proxy (Caddy/Nginx) | TLS termination, routing, automatic HTTPS |
| PostgreSQL | Database backend for Forgejo and HedgeDoc |
| Backup scripts | Automated backup of databases and git repositories |
| Monitoring | Basic health checks and alerting |

## Architecture

```
                          Internet
                             |
                        [Reverse Proxy]
                        (Caddy + TLS)
                       /       |
                      /        |
            forgejo.lab.org   hedgedoc.lab.org
                  |                |
          [Forgejo-Aneksajo]  [HedgeDoc]
                  |                |
              [PostgreSQL]    [PostgreSQL]
                  |
          [Filesystem Storage]
          /data/forgejo/
            - git repos
            - annex content
            - LFS objects
```

All services run on a single machine (the "box") or can be distributed across multiple hosts by adjusting the pyinfra inventory.

## Usage

### Prerequisites

- A Debian/Ubuntu server with SSH access
- Python 3.10+ on your local machine
- pyinfra installed (`pip install pyinfra`)

### Deployment

```bash
# Clone the deployment repository
git clone https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments.git
cd liab-deployments

# Configure your target host and domain
cp inventory.example.py inventory.py
# Edit inventory.py with your server details

# Deploy everything
pyinfra inventory.py deploy.py
```

### Updating

```bash
# Pull latest deployment configs
git pull

# Re-run -- pyinfra only applies changes
pyinfra inventory.py deploy.py
```

### Deploying Individual Services

```bash
# Deploy only Forgejo-Aneksajo
pyinfra inventory.py deploys/forgejo.py

# Deploy only HedgeDoc
pyinfra inventory.py deploys/hedgedoc.py
```

## Configuration as Code

All configuration lives in the git repository:

```
liab-deployments/
  inventory.py           # Target hosts
  deploy.py              # Main deployment entrypoint
  deploys/
    forgejo.py           # Forgejo-Aneksajo deployment
    hedgedoc.py          # HedgeDoc deployment
    caddy.py             # Reverse proxy and TLS
    postgres.py          # Database setup
    backup.py            # Backup configuration
  templates/
    forgejo/app.ini.j2   # Forgejo configuration template
    caddy/Caddyfile.j2   # Reverse proxy config
  group_data/
    all.py               # Shared variables (domains, paths, versions)
```

Because this is all in git, every change to the infrastructure is tracked, attributable, and reversible. You can `git diff` to see what changed, `git blame` to see who changed it, and `git revert` to undo a problematic change.

## git-annex / DataLad Integration

**Integration level: git-only.**

Lab-in-a-Box does not use git-annex for its own deployment configs (they are small text files that belong in git proper). However, the *primary purpose* of the deployment is to stand up services -- especially Forgejo-Aneksajo -- that provide git-annex and DataLad support to the research group.

The deployment repository itself can be managed as a DataLad dataset for provenance tracking:

```bash
datalad create liab-config
cd liab-config
# ... add deployment configs ...
datalad save -m "Initial Lab-in-a-Box configuration"
```

## AI Readiness

**Level: ai-ready.**

The entire deployment is Python code with clear structure and naming. This makes it well-suited for:

- **AI-assisted configuration** -- LLMs can generate new service deployments from descriptions
- **Security review** -- AI tools can audit configurations for common mistakes
- **Documentation generation** -- deployment code can be summarized into operational runbooks
- **Troubleshooting** -- error logs and deployment state can be analyzed by AI assistants

## How It Ties Together

Lab-in-a-Box is the **integration point** for the entire con/serve infrastructure layer:

1. **[pyinfra]({{< ref "pyinfra" >}})** provides the deployment engine
2. **[Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}})** provides the dataset hosting platform
3. **[HedgeDoc]({{< ref "hedgedoc" >}})** provides collaborative documentation
4. **[DataLad Hub]({{< ref "datalad-hub" >}})** can be thought of as a managed Lab-in-a-Box deployment

For a research group, Lab-in-a-Box answers the question: "We have a server and we want to own our research data infrastructure. What do we install?" The answer is: run the Lab-in-a-Box deployment and you have everything you need.

## Limitations and Caveats

- **Alpha status**: The deployment is functional but the service lineup and configuration structure are still evolving.
- **Single-box focus**: The default deployment targets a single server. Multi-server deployments are possible but require manual inventory configuration.
- **Debian/Ubuntu only**: The pyinfra operations target Debian-family distributions. Other distributions would require adaptation.
- **No built-in monitoring stack**: Basic health checks are included but a full monitoring solution (Prometheus, Grafana) is not yet part of the bundle.

## See Also

- [pyinfra]({{< ref "pyinfra" >}}) -- the deployment engine
- [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- the core forge service
- [HedgeDoc]({{< ref "hedgedoc" >}}) -- the collaborative editor
- [DataLad Hub]({{< ref "datalad-hub" >}}) -- hosted version of this concept
