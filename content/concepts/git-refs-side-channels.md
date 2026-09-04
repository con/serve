---
title: "Git Refs as Side-Channel Databases"
date: 2026-09-04
description: "Using git's object store and ref namespaces to version, distribute, and merge information that is complementary to -- but not part of -- the file trees on the branches of direct interest"
standards: ["TSV", "JSON", "JSON-LD"]
---

Two related ideas keep resurfacing across the tools cataloged here.
Neither is new, but neither has been stated explicitly on this site.

**A database is often just a file tree.**
The [Data-Visualization Separation]({{< ref "data-visualization-separation" >}}) page
calls the Model a set of structured files in standard formats.
[Vault Organization]({{< ref "vault-organization" >}}) shows the layouts
(BIDS, hive partitioning) that make such a tree queryable without a server.
[Metadata Extraction]({{< ref "metadata-extraction" >}}) shows how summaries
aggregate upward through the hierarchy.
Put together: a collection of `.tsv`, `.json`, and `.parquet` files
with an entity-labeled layout, under git, *is* the database.
DuckDB, VisiData, or a Svelte page are its query engines.
No MySQL, and often not even SQLite, is required.

**Not everything belongs in that tree.**
A branch records the state of a file tree.
Much useful information is *about* that tree, or about its history,
without being part of its state:
where annexed content currently lives,
which AI session produced a commit,
extracted metadata that is expensive to recompute,
issues mirrored from a forge,
line-level authorship.
Committing such information into the main tree would
churn the history, confuse consumers of the tree,
and force every clone to carry it.

Git offers a way out that several projects have independently adopted:
the object store holds any tree or blob,
and any ref makes those objects durable, versionable, pushable, and fetchable.
A ref outside `refs/heads/` is a **side channel** --
a parallel, complementary database that lives in the same repository,
travels through the same remotes,
and never touches the working tree.

## The Mechanisms Git Provides

| Mechanism | What it attaches to | Fetched by default `git clone`? | Merge story |
|---|---|---|---|
| Orphan branch (`refs/heads/<name>`) | Nothing -- independent history | Yes, since it is a branch | Whatever the tool defines; git's default is content merge |
| Notes (`refs/notes/<name>`) | Individual commits (also other objects) | No; needs a `fetch` refspec | `git notes merge` with `manual`, `ours`, `theirs`, `union`, `cat_sort_uniq` strategies |
| Custom namespace (`refs/<name>/...`) | Anything the tool decides | No; needs a refspec | Entirely tool-defined |
| Bare object refs (ref pointing at a tree or blob) | A single object, kept reachable | No; needs a refspec | Not applicable; a ref is replaced, not merged |
| Commit trailers (`Key: value` lines in the message) | The commit itself, as a pointer *out* to a side channel | Yes, part of the commit | Not applicable; lost on squash or rewrite |
| Git namespaces (`GIT_NAMESPACE`) | A whole set of refs sharing one object store | Only the requested namespace | Not applicable |

The first column is the choice each project below has made.
The third column is the recurring operational cost:
anything outside `refs/heads/` and `refs/tags/` is invisible
to a default clone and to most forge web UIs.

## Projects Already Using the Pattern

### git-annex: the `git-annex` branch

The oldest and most mature instance.
git-annex keeps a branch named `git-annex`,
unconnected to `master` or any content branch,
that is a file-tree database about repositories and keys:
`uuid.log`, `remote.log`, `trust.log`, `group.log`,
`preferred-content.log`, per-key location logs under
a hashed two-level layout (`aaa/bbb/<key>.log`),
`<key>.log.web` for URLs, `<key>.log.met` for user metadata,
`export.log`, `transitions.log`, and more
([internals](https://git-annex.branchable.com/internals/)).

Every line carries a timestamp
and the files are designed to be merged by concatenation:
when two clones disagree, union-merge the files,
and the newest timestamp per key and repository wins.
This gives "most recent availability information"
without any coordination between clones.

History can be pruned:
`git annex forget` rewrites the branch to drop old location history
and records the fact in `transitions.log`,
so that other clones running git-annex apply the same rewrite
when they next merge the branch.
Clones not running git-annex must be force-pushed to manually.

The branch is fetched and merged by `git annex sync`,
and DataLad's `push`/`update` handle it as a matter of course.
It is the model the rest of this page is measured against.

### git-annex-remote-gitobjects: content in the object store

A [proof-of-concept special remote](https://github.com/datalad/datalad/blob/maint/sandbox/git-annex-remote-gitobjects)
in DataLad's sandbox pushes the pattern to its extreme:
annexed *content* itself is written with `git hash-object -w`
and kept reachable by one ref per key, `refs/annex-gitobjects/<key>`.
Storing means `git push remote ref:ref`; retrieving means `git fetch remote ref:ref`
followed by `git cat-file -p`; dropping means pushing an empty ref.
No merge is needed because each key has its own ref.
The script itself warns that the longevity of such refs on a remote is not guaranteed
and that it is not performant.
It is nonetheless a clean demonstration that
"a git remote" can be a content store when nothing else is available.

### datalad-metalad: extracted metadata as git objects

[datalad-metalad](https://github.com/datalad/datalad-metalad)
stores extracted metadata not in the working tree
but as git blobs and trees kept reachable under `refs/datalad/*`
via the [metadata-model](https://github.com/datalad/metadata-model) package.
The refs in use include
`refs/datalad/dataset-tree-version-list`,
`refs/datalad/dataset-uuid-set`,
and `refs/datalad/object-references-2.0`,
the last being a tree that indexes every stored object by hash
so that garbage collection does not remove them.
Aggregation up a superdataset hierarchy copies objects
between repositories.

There is no timestamp-union or logical-clock merge here:
the refs are replaced on each write,
and concurrent extraction in two clones is not a supported scenario.
This is the storage layer the
[Metadata Extraction]({{< ref "metadata-extraction" >}}) page
proposes to build on, and it is one of the open questions there:
whether extracted metadata belongs in a side channel like this
or in-tree as summary tables.

### git-bug: issues in `refs/bugs/`

[git-bug]({{< ref "tools/code-artifacts/git-bug" >}})
stores each bug and each identity as its own chain of commits
under `refs/bugs/<id>` and `refs/identities/<id>`.
A commit's tree holds an `ops` blob (a JSON array of operations
from one edit session) and optional media blobs.
Concurrent edits from different clones form a DAG that is
ordered deterministically using Lamport clocks
encoded in tree entry names (`edit-clock-137`),
with the pack identifier as tiebreaker
([data model](https://github.com/git-bug/git-bug/blob/master/doc/design/data-model.md)).
Wall-clock timestamps are kept for display only.

The [dandi-bib](https://github.com/dandi/dandi-bib/blob/master/.github/workflows/sync-git-bug.yml)
workflow shows the distribution side in practice:
a GitHub Action fetches `refs/identities/*` and `refs/bugs/*`,
runs the GitHub bridge to pull issues,
and pushes the same refspecs back.
Identities are fetched first so that repeated CI runs
reuse them instead of creating duplicates.
The mirror is one-directional because the bridge cannot
create issues on GitHub on behalf of other authors.

### Entire: session checkpoints on an orphan branch

[Entire]({{< ref "tools/ai-sessions/entire-io" >}})
keeps a permanent orphan branch, `entire/checkpoints/v1`,
plus short-lived local shadow branches that are never pushed.
The checkpoints branch is a sharded file tree:
`<2 hex>/<10 hex>/metadata.json` with per-session subdirectories
holding `full.jsonl`, `prompt.txt`, and `context.md`
([bids-utils example](https://github.com/bids-standard/bids-utils/tree/entire/checkpoints/v1),
[how it works](https://julien.danjou.info/blog/how-entire-works-under-the-hood/)).
The link from a code commit to its checkpoint is a commit trailer,
`Entire-Checkpoint: <id>`, and the link back is a search for that trailer.

Merging is "conflict-free by design":
checkpoint identifiers are random,
so two developers' trees are combined by tree union.
There is no retention policy;
the branch grows forever.
Squash-merging a pull request discards the trailers,
which breaks the linkage for those commits.

### git-memento and Git AI: notes on commits

[git-memento]({{< ref "tools/ai-sessions/git-memento" >}})
attaches a cleaned session transcript to each commit as a note
in `refs/notes/commits`;
[Git AI]({{< ref "tools/ai-sessions/git-ai" >}})
attaches line-level authorship logs under `refs/notes/ai`.
Both rely on git's own notes machinery,
including its merge strategies and its requirement
that a `fetch` refspec be configured to see them.
Notes are the lightest option when the unit of association
is exactly "one commit".

## Recurring Design Choices

Reading the projects side by side,
each has answered the same set of questions.

**Unit of storage and addressing.**
git-annex and Entire store file trees addressed by a hashed path.
git-bug and metalad store bare objects addressed by hash
and keep them alive through refs.
Notes address by the commit they annotate.
File trees are inspectable with ordinary git commands;
object graphs need the tool to read them.

**Linkage to the main tree.**
git-annex links by key, which the main tree's symlinks and pointer files carry.
Entire links by commit trailer.
Notes link by commit hash.
git-bug and metalad link by dataset or repository identity, not by commit.
Trailers are the only linkage that lives in the main history
and therefore the only one that can be destroyed by rewriting it.

**Merge strategy.**
Four different strategies appear:

| Strategy | Used by | Requires |
|---|---|---|
| Union of lines, newest timestamp wins | git-annex | Roughly synchronized clocks; append-only semantics |
| Logical (Lamport) clocks with deterministic tiebreak | git-bug | The tool to serialize the clock into the object names |
| Random identifiers, tree union | Entire | Nothing; collisions are assumed impossible |
| Replace, no merge | metalad, gitobjects | A single writer per ref |

git's built-in notes merge strategies (`union`, `cat_sort_uniq`)
sit between the first and third rows.
The git-annex approach is the most battle-tested
and the cheapest to implement when records are naturally
"latest state per (entity, source)" pairs,
which describes most availability and status information.

**Pruning and history.**
Only git-annex has a documented way to shrink the side channel
(`git annex forget`, coordinated through `transitions.log`).
Entire acknowledges unbounded growth.
Notes can be dropped with `git notes prune` for commits that no longer exist.
The rest keep everything.

**Distribution.**
Every side channel except orphan branches
is invisible to a default clone and to forge web UIs.
Each project therefore ships its own sync:
`git annex sync`, git-bug's push/pull commands,
Entire's pre-push hook, git-memento's `notes-sync`.
DataLad handles the `git-annex` branch;
any other namespace needs explicit refspecs
in the remote's `fetch` and `push` configuration
or in a workflow such as the dandi-bib one above.
Whether a forge preserves arbitrary refs through
mirroring, forking, and garbage collection
is not something any of these tools can control.

## Relevance for con/serve

The vault already depends on this pattern through git-annex,
and will depend on it more through the projects above.
The question is which information should go where.

- **In the tree**: anything that is a property of the data
  and that consumers should see without special tooling.
  The summary tables of the
  [Metadata Extraction]({{< ref "metadata-extraction" >}}) page
  belong here; they are
  [Frozen Frontiers]({{< ref "/_index.md#frozen-frontiers" >}})
  meant to be opened in DuckDB or VisiData.
- **In a side channel**: information about the tree or its history
  rather than of it. Availability and remote configuration (git-annex),
  per-commit provenance (notes, trailers), session transcripts (Entire, git-memento),
  mirrored external state that has its own lifecycle (git-bug),
  and caches of extracted metadata that are recomputable (metalad).

Where a self-contained per-entity subdataset
(see [Vault Organization]({{< ref "vault-organization#emerging-principles" >}}))
archives a repository together with its issues, CI logs, and discussions,
custom ref namespaces are one of the options under consideration
for keeping those aspects in one repository
without inventing satellite repositories.
git-bug's `refs/bugs/` is the working precedent;
the same shape could hold `refs/tinuous/...` or `refs/discussions/...`,
but no tool does this today and it remains an open question
in the [self-contain-github-repo](/projects/self-contain-github-repo/) project.

## Open Questions

- **Forge behavior** --
  which forges preserve `refs/bugs/*`, `refs/notes/*`, and `refs/datalad/*`
  across mirroring, forking, and server-side garbage collection?
  Forgejo, GitHub, and GIN have not been compared on this.
- **Merge semantics for extracted metadata** --
  metalad replaces refs; if two clones extract concurrently,
  something like git-annex's timestamped union
  or git-bug's logical clocks would be needed.
  Which fits metadata records that are keyed by
  (dataset, version, extractor)?
- **Retention** --
  only git-annex can forget.
  Session and checkpoint side channels grow without bound;
  whether a vault wants to prune them, and how to do so
  across clones, is unexplored.
- **Discoverability** --
  a side channel is only useful to those who know it exists.
  Should a dataset advertise its side channels
  in `.datalad/config` or `dataset_description.json`?

## See Also

- [Data-Visualization Separation]({{< ref "data-visualization-separation" >}}) --
  the file tree as the Model
- [Metadata Extraction and Dependencies]({{< ref "metadata-extraction" >}}) --
  hierarchical aggregation and the metalad storage question
- [Vault Organization]({{< ref "vault-organization" >}}) --
  layouts that make a file tree queryable; the vault-to-forge mapping problem
- [git-annex internals](https://git-annex.branchable.com/internals/) --
  the `git-annex` branch file formats
- [git-annex forget](https://git-annex.branchable.com/git-annex-forget/) --
  coordinated history pruning
- [git-bug data model](https://github.com/git-bug/git-bug/blob/master/doc/design/data-model.md)
- [How Entire works under the hood](https://julien.danjou.info/blog/how-entire-works-under-the-hood/)
- [datalad metadata-model](https://github.com/datalad/metadata-model) --
  the `refs/datalad/*` storage layer behind metalad
- [git-annex-remote-gitobjects](https://github.com/datalad/datalad/blob/maint/sandbox/git-annex-remote-gitobjects) --
  annexed content in the git object store
- [git notes documentation](https://git-scm.com/docs/git-notes)
