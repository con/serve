---
title: "pyinfra"
date: 2026-02-12
description: "Python-based infrastructure automation for deploying and configuring research services"
summary: "Infrastructure automation tool that uses Python for defining deployments. Deployment configurations are stored in git, making infrastructure reproducible and version-controlled."
categories: ["Infrastructure"]
tags: ["deployment", "automation", "infrastructure", "python", "devops"]
integrations: ["git-only"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/pyinfra-dev/pyinfra"
  homepage: "https://pyinfra.com"
  issues: "https://github.com/pyinfra-dev/pyinfra/issues"
  language: "Python"
  license: "MIT"
  maturity: "stable"
  last_verified: "2026-02"
  examples:
    - title: "Lab-in-a-Box (pyinfra-based lab deployment)"
      url: "https://hub.psychoinformatics.de/lab-in-a-box/liab-deployments"
---

## Overview

[pyinfra](https://pyinfra.com) is an infrastructure automation tool that uses Python to define and execute deployments. It connects to target machines over SSH (or locally) and executes operations to install packages, configure services, manage files, and orchestrate multi-service deployments.

pyinfra occupies the same space as Ansible but uses Python directly instead of YAML. This makes deployment definitions testable, composable, and familiar to research teams that already work in Python.

## Key Features

- **Python-native** -- deployments are defined in `.py` files using a straightforward API
- **Agentless** -- connects over SSH, no agent installation on target machines
- **Fast** -- parallel execution across multiple hosts
- **Idempotent** -- operations check current state before making changes
- **Composable** -- deploy functions can be imported and reused across projects

## git-annex / DataLad Integration

**Integration level: git-only.**

pyinfra deployment configurations are Python files stored in a git repository. They do not interact with git-annex or DataLad directly, but the deployment code itself is version-controlled and auditable through standard git workflows.

The [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) project uses pyinfra to deploy the entire con/serve infrastructure stack, with all deployment logic stored in a DataLad-tracked repository.

## AI Readiness

**Level: ai-ready.**

pyinfra configurations are Python source code -- structured, readable, and well-suited for AI-assisted generation, review, and modification. LLMs can help write deployment recipes, review configurations for security issues, or generate new service definitions from natural language descriptions.

## Role in the con/serve Stack

pyinfra is the **deployment engine** behind [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}). It automates the installation and configuration of [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}), [HedgeDoc]({{< ref "hedgedoc" >}}), and other services that make up the self-hosted research infrastructure.

## See Also

- [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) -- the pyinfra-based deployment that bundles all con/serve services
- [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) -- primary service deployed by pyinfra
- [HedgeDoc]({{< ref "hedgedoc" >}}) -- collaborative editor deployed by pyinfra
