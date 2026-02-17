# Self-Contained GitHub Repository Archival

## Goal

Determine the optimal organization for preserving all GitHub repository
artifacts -- code, issues, PRs, CI logs, discussions, wikis, releases --
within a self-contained unit that can be stored in a DataLad vault
and mirrored to a Forgejo-Aneksajo forge.

## The Duality

There are two sides to this problem, and they have different constraints:

**Vault side** (DataLad superdataset hierarchy):

- Deep nesting with `//` subdataset boundaries
- One superdataset per entity (e.g., per GitHub repo)
- Aspect subdatasets within (`git//`, `issues//`, `tinuous-logs//`)
- Arbitrary depth, independent versioning and access control at each level

**Forge side** (Forgejo/Gitea flat namespace):

- `{org}/{repo}` -- two levels, no deeper
- No native concept of sub-repositories or repo grouping
- Each repo is independent on the forge

The vault layout proposed in
[vault-organization](../../content/concepts/vault-organization.md)
groups everything about `dandi-cli` under `repos/dandi-cli//`.
But when that hierarchy is mirrored to a forge,
the nesting must be flattened somehow.

## What Already Works

**git-bug** stores issues as git refs (`refs/bugs/`)
within the repository itself -- true self-containment.
The issues travel with the repo on clone and push
with no separate dataset needed.

**con/tinuous** creates date-organized directory trees
of CI log archives. Currently these are separate DataLad datasets,
but they could live alongside the repo they belong to.

**python-github-backup** dumps issues, PRs, releases as JSON files
alongside the git history.

## Vault-Side Options

### Per-repo superdataset with aspect subdatasets

The approach proposed in vault-organization:

```
repos/dandi-cli//
    git//              # the repo itself
    issues//           # git-bug or JSON export
    tinuous-logs//     # CI log archive
    discussions//      # exported discussions
```

Each aspect is independently versionable and syncable.
`datalad get repos/dandi-cli` fetches everything;
`datalad get repos/dandi-cli/tinuous-logs` fetches only CI logs.

### Single git repo with everything in refs

git-bug demonstrates that issues can live in `refs/bugs/`
within the repo. Extending this pattern:

```
refs/heads/*         # normal branches
refs/bugs/*          # git-bug issues
refs/tinuous/*       # CI log refs
refs/discussions/*   # exported discussions
```

Most self-contained (everything is one repo),
but requires custom tooling for each ref namespace
and the repo can grow very large.

## Forge-Side Options

### Satellite repos with naming convention

```
dandi/dandi-cli
dandi/dandi-cli--tinuous-logs
dandi/dandi-cli--issues
dandi/dandi-cli--discussions
```

Simple to implement -- each vault subdataset maps to one forge repo.
Pollutes the org namespace (an org with 50 repos
becomes 200+ repos with satellites).

### Git namespaces (`GIT_NAMESPACE`)

Git namespaces partition refs within a single repository
and share the object store.
A clone with `GIT_NAMESPACE=tinuous-logs` fetches only those refs.

- Object deduplication across namespaces (shared packfiles)
- Clean separation of concerns
- **But**: Forgejo/Gitea don't support namespaces natively --
  no UI, no API filtering, no per-namespace access control.
  Would require Forgejo patches or extensions.

### Orphan branches

```
main               # code
tinuous-logs/main  # CI log tree
issues/main        # exported issues
```

Uses standard git branching. All content in one repo.
Branch listing becomes cluttered for large archives.
git-annex may have interactions with multiple unrelated branch trees.

### Custom ref prefixes

Extend the git-bug pattern to other artifact types:

```
refs/bugs/*          # issues (git-bug)
refs/tinuous/*       # CI logs
refs/discussions/*   # discussions
```

Refs are invisible in normal branch/tag listings.
Requires per-tool support for pushing/fetching custom refs.
git-annex already uses `refs/heads/git-annex` --
need to verify there are no conflicts.

## Research Questions

- Can Forgejo be extended or patched to support git namespaces?
  What would the UI and API look like?
- Does git-annex work correctly across git namespaces?
  Are there interactions with the `git-annex` branch or object store?
- What's the UX impact of satellite repos vs. single-repo-with-refs
  for someone browsing the forge?
- How does `datalad clone` interact with namespaced repos?
- What are the storage implications of satellite repos
  (duplicated objects) vs. namespace/ref-based approaches (shared objects)?
- How does this interact with Forgejo's mirroring feature --
  can a namespace or ref prefix be mirrored selectively?

## Related

- [Vault Organization](../../content/concepts/vault-organization.md) --
  the vault-side layout principles, `//` notation, and self-containment principle
- [bids-specification#2191](https://github.com/bids-standard/bids-specification/issues/2191) --
  parallel discussion about naming within nested structures
- [Software Project user story](../../content/user-stories/software-project.md) --
  the motivating use case (DANDI project archival)
