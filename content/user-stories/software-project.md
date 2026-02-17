---
title: "Software Project"
date: 2026-02-17
description: "A multi-repository open-source project on GitHub needs to archive all code forge artifacts and team communications into a vault"
summary: "An open-source software project spanning a GitHub organization with dozens of repositories, active issue trackers, GitHub Actions CI, Discussions, and Slack for team communication. Prototypical target: the DANDI project. Archive all forge artifacts (repos, issues, PRs, Actions logs, Discussions, wikis) with ongoing sync, preserve Slack history, and mirror to a Forgejo-Aneksajo instance with GitHub authentication."
tags: ["user-story", "software", "github", "slack", "CI", "forge"]
---

## The Goal

An open-source software project lives on GitHub:
a GitHub organization with dozens of repositories,
active issue trackers, pull request workflows,
GitHub Actions CI/CD, Discussions for design conversations,
and Slack for real-time team communication.

A prototypical target is the [DANDI project](https://github.com/dandi) --
a neuroscience data archive with ~50 repositories,
thousands of issues and PRs,
extensive CI pipelines,
and an active Slack workspace.

The goal is to **archive all project activity** into a vault
with ongoing synchronization,
so that if GitHub changes terms, restricts access,
or the project migrates platforms,
the complete record of development activity is preserved --
not just the code, but the conversations, decisions, and CI history
that explain *why* the code is the way it is.

## Data Sources

### GitHub Repositories

The code itself is already in git.
But a `git clone` captures only commits and refs --
it misses the platform layer that lives on GitHub's servers.

For each repository, the vault needs:

| Artifact | Tool | Format |
|----------|------|--------|
| Git history (commits, branches, tags) | `git clone --mirror` | Git |
| Issues and PRs (with comments, labels, milestones) | [git-bug]({{< ref "git-bug" >}}), [python-github-backup]({{< ref "github-backup" >}}) | Git refs / JSON |
| Discussions | [gh-discussions-export]({{< ref "gh-discussions-export" >}}) | JSON / Markdown |
| Wiki pages | [gh-md]({{< ref "gh-md" >}}) | Markdown |
| Releases and artifacts | [python-github-backup]({{< ref "github-backup" >}}) | JSON + binaries |

Some repositories are **private**.
These must be archived with `distribution-restrictions=private`
so they are excluded from any public-facing remotes.

### GitHub Actions (CI Logs)

CI runs produce build logs, test output, and artifacts
that are essential for debugging regressions and understanding project history.
GitHub retains Actions logs for 90 days by default;
after that, the build history is gone.

[con/tinuous]({{< ref "tinuous" >}}) archives CI logs
from GitHub Actions (and other CI services)
into git-annex repositories,
preserving the complete build history as a DataLad dataset.

### Slack (Team Communication)

The project's Slack workspace contains:
design discussions, user support threads,
release coordination, triage decisions,
and the informal exchanges that never make it into issues or docs.

[slackdump]({{< ref "slackdump" >}}) archives these conversations
into structured JSON.

| Channel type | Content | Privacy |
|--------------|---------|---------|
| Public channels (`#general`, `#dev`, `#releases`) | Development discussion, announcements | private (workspace-internal) |
| Private channels (`#core-team`, `#security`) | Sensitive design and security discussions | private |
| DMs | One-on-one coordination | private |

### Organization Metadata

Beyond individual repositories, the GitHub organization itself has structure:
teams and their memberships, organization-level settings,
repository permissions, and team discussions.
This metadata defines *who* could do *what* --
important context for understanding the project's governance history.

## Forgejo-Aneksajo Mirror

The vault's forge counterpart is a
[Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) instance
that mirrors the GitHub organization.

### GitHub Authentication

Forgejo supports OAuth2 authentication providers,
including GitHub.
Configuring the Forgejo-Aneksajo instance to use
**GitHub as an authentication source** means:

- Project members log in with their existing GitHub accounts
- No separate credentials to manage
- Team memberships and org roles can be synced
  (Forgejo supports mapping OAuth2 groups to Forgejo organizations/teams)

This makes the Forgejo mirror feel like a natural extension
of the GitHub-based workflow rather than a separate system.

### Repository Mirroring

Forgejo supports **mirror repositories** --
repositories that automatically sync from an upstream source.
Each GitHub repository in the organization
can be configured as a Forgejo mirror:

```bash
# Forgejo API: create a mirror of a GitHub repo
curl -X POST https://forgejo.example.org/api/v1/repos/migrate \
    -H "Authorization: token $FORGEJO_TOKEN" \
    -d '{
        "clone_addr": "https://github.com/dandi/dandi-cli",
        "mirror": true,
        "repo_name": "dandi-cli",
        "repo_owner": "dandi"
    }'
```

This gives the project a self-hosted backup of all code
with a browsable web interface,
independent of GitHub's availability.

### Private Repositories

Private GitHub repositories are mirrored as private Forgejo repositories.
The authentication token used for mirroring needs access to private repos,
and the Forgejo instance's access controls ensure
only authorized team members can see them.

In the vault, content from private repos carries
`distribution-restrictions=private` metadata.

## Hypothetical Vault Organization

> **TODO:** AI-generated layout, to be curated.

```
project-vault/                           # DataLad superdataset
    ├── repos/                           # Git mirrors (one per repo)
    │   ├── dandi-cli/
    │   ├── dandi-archive/
    │   ├── dandischema/
    │   └── ...
    ├── issues/                          # Exported issues/PRs (git-bug or JSON)
    │   ├── dandi-cli/
    │   └── ...
    ├── discussions/                     # Exported GitHub Discussions
    │   ├── dandi-cli/
    │   └── ...
    ├── ci/                              # Archived CI logs (con/tinuous)
    │   ├── github/
    │   │   └── push/2026/02/...
    │   └── ...
    ├── communications/
    │   └── slack/                       # Archived Slack workspace
    ├── releases/                        # Release artifacts
    │   ├── dandi-cli/
    │   └── ...
    └── .datalad/
```

Each repository's forge artifacts (issues, discussions, CI logs)
are separate subdatasets,
enabling independent synchronization schedules --
issues sync frequently, CI logs archive nightly.

## Distribution and Privacy

| Content | Distribution | Rationale |
|---------|-------------|-----------|
| Public repo mirrors | Forgejo (public) | Redundancy, self-hosted access |
| Private repo mirrors | Forgejo (private) + encrypted backup | Access-controlled |
| Issues/PRs (public repos) | Forgejo / vault | Public project metadata |
| Issues/PRs (private repos) | Private only | Contains restricted discussion |
| CI logs | Vault (private) | May contain secrets in error messages |
| Slack archives | Private (encrypted backup) | Workspace-internal communications |
| Discussions | Vault (mirrors repo visibility) | Follows source repo access |
| Release artifacts | Forgejo / public mirrors | Already public |

## Workflow Overview

> **TODO:** AI-generated layout, to be curated.

{{< mermaid >}}
flowchart TD
    gh_org[GitHub Organization] -->|git mirror| repos[repos/]
    gh_org -->|git-bug bridge| issues[issues/]
    gh_org -->|gh-discussions-export| discussions[discussions/]
    gh_org -->|con/tinuous| ci[ci/]
    gh_org -->|python-github-backup| releases[releases/]

    slack[Slack Workspace] -->|slackdump| comms[communications/slack/]

    repos -->|Forgejo mirror sync| forgejo[Forgejo-Aneksajo]
    issues --> forgejo
    forgejo -->|GitHub OAuth| auth[GitHub Authentication]

    subgraph vault[Project Vault -- git-annex / DataLad]
        repos
        issues
        discussions
        ci
        comms
        releases
    end

    subgraph mirror[Self-Hosted Mirror]
        forgejo
        auth
    end
{{< /mermaid >}}

## Relevant Tools

| Component | Tool | Status |
|-----------|------|--------|
| Issue archival | [git-bug]({{< ref "git-bug" >}}) | Stable |
| Repository backup | [python-github-backup]({{< ref "github-backup" >}}) | Stable |
| Discussions export | [gh-discussions-export]({{< ref "gh-discussions-export" >}}) | Beta |
| Wiki export | [gh-md]({{< ref "gh-md" >}}) | Stable |
| CI log archival | [con/tinuous]({{< ref "tinuous" >}}) | Stable |
| Slack archival | [slackdump]({{< ref "slackdump" >}}) | Working |
| Self-hosted forge | [Forgejo-Aneksajo]({{< ref "forgejo-aneksajo" >}}) | Beta |
| Deployment | [Lab-in-a-Box]({{< ref "lab-in-a-box" >}}) | Alpha |

## See Also

- [Automation and Pipelines]({{< ref "automation-and-pipelines" >}}) --
  orchestration patterns for periodic sync and archival jobs
- [Privacy and Access Control]({{< ref "about#privacy-and-access-control" >}}) --
  handling private repositories and confidential communications
- [Neuroimaging Lab]({{< ref "neuroimaging-lab" >}}) --
  a lab-scale story that also archives GitHub and Slack alongside domain data
