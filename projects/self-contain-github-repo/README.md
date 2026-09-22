# Self-Contained Repository Archival: one repo, many repos

## Goal

Preserve everything about a project -- code, issues, PRs, CI logs,
discussions, releases -- inside a **single** forge repository, so that the
artifacts share the repository's object store and access control, while a
plain `git clone` still fetches only the code.

The motivating case: `con/tinuous` produces a deep, ever-growing tree of CI
logs and artifacts per project. Making each level a separate forge repository
pollutes the org namespace; making it one giant repository makes every clone
expensive. Neither is acceptable.

## Answer in one paragraph

Git namespaces are the right *storage layout* and the wrong *access
mechanism*. `GIT_NAMESPACE` is interpreted by `git-upload-pack` and
`git-receive-pack` **on the server**; a client cannot select a namespace over
`https://` unless the server offers it at a distinct URL. GitHub, GitLab and
Forgejo/Gitea do not. But the layout that namespaces define --
`refs/namespaces/<a>/refs/namespaces/<b>/refs/heads/main` -- is just refs, and
a client can address those refs directly with explicit refspecs on any forge
that accepts refs outside `refs/heads/` and `refs/tags/`. So: **store in
namespace layout, access by refspec today, and the same repository becomes a
set of real namespaced repositories the moment it is served by
`git-http-backend` or gitolite.** No conversion step.

## How namespaces actually behave

Verified locally against git 2.43 (`tools/build-demo.sh`):

| Behaviour | Result |
| --- | --- |
| `GIT_NAMESPACE=x git ls-remote URL` | shows only that namespace's refs, rewritten to `refs/heads/*` |
| plain `git clone URL` | fetches `refs/heads/*` only -- namespaced refs are **not** pulled |
| `git clone` of a local *path* | namespace ignored -- local clones bypass `upload-pack`; use `file://` |
| namespace `HEAD` | **required**, and must be a *fully-qualified* symref: `refs/namespaces/x/HEAD -> refs/namespaces/x/refs/heads/main`. Pointing it at `refs/heads/main` silently serves the top-level branch |
| hierarchy | `GIT_NAMESPACE=a/b/c` interleaves: `refs/namespaces/a/refs/namespaces/b/refs/namespaces/c/` |
| object store | shared. Pushing identical content into a second namespace added **0** objects |
| `git gc` | sees all namespaces as reachable; nothing pruned |
| persisting a namespace client-side | `remote.origin.uploadpack = "env GIT_NAMESPACE=x git-upload-pack"` (and `receivepack`) works for `ssh://` and `file://`, **not** for http -- there the server decides |

The last row is the crux: over HTTP the namespace is a property of the URL the
server maps, not something the client can assert.

## The two access modes

Both address **the same refs in the same repository**.

**namespace mode** -- server honours `GIT_NAMESPACE`, member repos get real
URLs, every git command works unmodified:

```
http://host/monorepo.git              -> the code
http://host/~a/tinuous/monorepo.git   -> the CI archive
```

`tools/ns-http-server.py` is a ~80-line `git-http-backend` wrapper that does
this; it is the deployment `gitnamespaces(7)` documents. Submodule URLs can be
**relative** (`../~a/tinuous/monorepo.git`, `../2026/monorepo.git`), so the
whole hierarchy relocates between forges without rewriting `.gitmodules`.

**refspec mode** -- forge has no namespace support (GitHub today). One URL,
fully-qualified refspecs:

```
fetch = +refs/namespaces/a/refs/namespaces/tinuous/refs/heads/*:refs/remotes/origin/*
push  = refs/heads/*:refs/namespaces/a/refs/namespaces/tinuous/refs/heads/*
```

Verified: fetching one member this way pulls only that member's objects (25
objects, no project code), and pushing back through the plain URL lands in the
right namespace. The cost is that `git submodule update` cannot do it by
itself -- it clones the submodule URL and expects the gitlink commit to be
reachable from `refs/heads/*`. `tools/git-monorepo clone` fills that gap.

## What was demonstrated

`tools/build-demo.sh` builds, in **one** bare repository:

```
(default namespace)         the project code        <- plain `git clone` gets only this
  a/issues                  issue export
  a/tinuous                 CI archive root          level 1
    a/tinuous/2026          year                     level 2
      a/tinuous/2026/09     month, git-annex         level 3
```

linked by `.gitmodules` at every level with relative URLs. Verified results:

- plain clone: 188K, `artifacts/tinuous` an empty gitlink
- `git submodule update --init --recursive`: walks all three levels, each
  cloned from its own namespaced URL
- the leaf is a genuine git-annex repository; its `git-annex` branch is stored
  **inside its own namespace**
  (`.../09/refs/heads/git-annex`) -- no collision with any other member, and
  none with the top-level repo
- `git annex get` retrieves content from the public URLs recorded at ingest
  (`web` special remote), in both a submodule checkout and a standalone
  refspec-mode clone
- server side: 52 objects total, one pack, all namespaces sharing it

git-annex and namespaces are undocumented together; this appears to be the
first recorded test. It works because a namespaced clone is an ordinary
repository client-side -- the rewriting happens only in the transport.

## Prior art

Nothing found that uses `refs/namespaces/` to hold a *collection of
repositories*. What exists is adjacent:

- **Custom ref prefixes** are the established pattern for side-channel data:
  [git-bug](https://github.com/git-bug/git-bug) (`refs/bugs/*`),
  git-appraise (`refs/notes/devtools/*`), git-series (`refs/series/*`),
  git-annex (`refs/heads/git-annex`). All demonstrate that forges tolerate
  non-branch refs; none nest repositories.
- **[Josh](https://github.com/josh-project/josh)** -- a git proxy that
  virtualizes subdirectories of a monorepo as independent repositories, with
  bidirectional push. Solves the inverse problem (one history, many views);
  worth watching because its proxy architecture is where a namespace-aware
  gateway would live.
- **GitLab object pools** and plain `objects/info/alternates` share an object
  store across repositories -- the dedup benefit without the single-repo
  property.
- **Forgejo [#2629](https://codeberg.org/forgejo/forgejo/issues/2629)**
  proposes storing issues in refs, with the SQL tables as a rebuildable index.
  If it lands, Forgejo grows a reason to care about ref hierarchies.
- **Gitolite** can serve namespaces, being a thin layer over stock git.

Helper tooling for the "many repos in one" case: none found.
`tools/git-monorepo` is a first cut.

## Forge support

| Forge | `GIT_NAMESPACE` | Refs outside `refs/heads`/`refs/tags` |
| --- | --- | --- |
| stock git (`git-http-backend`, gitolite, ssh) | yes, documented | yes |
| GitHub | no client-selectable namespace | **untested here** -- see below |
| GitLab | ignored; pushes land in the default namespace. Gitaly rejects pushes into *its* internal namespaces | partial |
| Forgejo/Gitea | not supported; no UI, API or ACL concept | unverified |

### The GitHub question is still open

The decisive experiment -- does GitHub accept a push to
`refs/namespaces/.../refs/heads/main`? -- **could not be run in this
session**: the Claude GitHub App has read-only access to
`con/serve-monorepo-dev` (`403 Resource not accessible by integration`), and
pushing probe refs to `con/serve` was blocked as a shared-resource write.

Evidence short of a test: GitHub is a compliant git implementation and
[community discussion #30507](https://github.com/orgs/community/discussions/30507)
states that custom refs can be pushed and pulled, though they are invisible in
the web UI and reachable only via the REST refs API. The known rejections are
GitHub's *own* hidden refs (`refs/pull/*`). So the expectation is that it
works, with these risks to confirm:

- whether `refs/namespaces/*` specifically is rejected as reserved
- whether such refs survive GitHub's garbage collection and repo maintenance
- whether they survive fork/transfer/mirror operations
- whether repository size limits count them (they will)

`tools/gh-ref-probe.sh <repo-url>` answers all of the first three in under a
minute and cleans up after itself. **Run it before building on this.**

## Tools

| File | What it does |
| --- | --- |
| `tools/git-monorepo` | list / clone / push / attach members of a single-repo collection, in either mode |
| `tools/ns-http-server.py` | namespace-aware smart-HTTP server (`/~<ns>/<repo>.git`) over `git-http-backend` |
| `tools/build-demo.sh` | builds the verified 3-deep + git-annex demo from scratch |
| `tools/gh-ref-probe.sh` | probes a forge's ref-name policy, non-destructively |

Quickstart:

```bash
REPO_ROOT=/tmp/mono/server python3 tools/ns-http-server.py 8178 &
bash tools/build-demo.sh
tools/git-monorepo ls    http://127.0.0.1:8178/monorepo.git
tools/git-monorepo clone http://127.0.0.1:8178/monorepo.git a/tinuous/2026/09 /tmp/leaf
```

## Remaining unknowns

- GitHub's ref policy and GC behaviour (above) -- blocking.
- Per-member access control: namespaces share one repository, so they share
  its ACL. Splitting "code is public, CI logs are internal" needs separate
  repositories or a gateway that filters refs.
- Discoverability: nothing in a forge UI lists members. `git-monorepo ls`
  reconstructs the list from `ls-remote`; a manifest ref would be cheaper.
- Growth: one repository accumulates every artifact. Namespaces do not bound
  size, and forge size limits apply to the whole thing.
- Whether `datalad clone` can be taught a refspec-mode member, or whether it
  needs the namespace-aware URL form.

## Related

- [Vault Organization](../../content/concepts/vault-organization.md)
- [Git content-store side channels](../../content/concepts/git-content-store-side-channels.md)
- [Software Project user story](../../content/user-stories/software-project.md)
- [gitnamespaces(7)](https://git-scm.com/docs/gitnamespaces)
