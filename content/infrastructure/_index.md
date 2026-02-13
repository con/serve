---
title: "Infrastructure"
date: 2026-02-12
description: "Self-hosted services for managing, hosting, and deploying archived research artifacts"
cascade:
  showEdit: true
---

The tools in the [Tools](/tools/) section pull artifacts into
git-annex/DataLad repositories.
But a repository on a single workstation is not an infrastructure --
it is a single point of failure with an audience of one.

This section catalogs the **services and deployment systems**
that turn a collection of local repositories
into a resilient, collaborative, self-hosted research platform.

## Core Services

**[Forgejo-Aneksajo](forgejo-aneksajo/)** --
A Forgejo fork with native git-annex support.
It serves as the self-hosted forge for browsing, cloning,
and collaborating on DataLad datasets through a web interface.
It is the foundation of [DataLad Hub](datalad-hub/).

**[HedgeDoc](hedgedoc/)** --
Collaborative real-time markdown editing for documentation,
meeting notes, and lab notebooks.
Documents are exported and committed to git for preservation.

**[DataLad Hub](datalad-hub/)** --
A hosted service built on Forgejo-Aneksajo
for publishing and sharing DataLad datasets.

## Deployment

**[pyinfra](pyinfra/)** --
Python-based infrastructure automation used to deploy
and configure all the services above.

**[Lab-in-a-Box](lab-in-a-box/)** --
A pyinfra-based deployment that bundles Forgejo-Aneksajo,
HedgeDoc, and other services into a single reproducible
"lab infrastructure" stack.
One command, one box, everything a research group needs.

## Design Principles

The infrastructure stack follows the same principles as the data it manages:

- **Configuration as code** -- all deployment logic lives in git,
  versioned and auditable.
- **Self-hosted** -- no dependency on third-party SaaS for core operations.
- **Composable** -- services can be deployed individually or as a bundle.
- **Git-native** -- the forge, the datasets, and the deployment configs
  all live in git repositories.
