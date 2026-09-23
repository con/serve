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
Forgejo/Gitea do not -- for Gitea/Forgejo this is now confirmed by both the
source and a live instance. But the layout that namespaces define --
`refs/namespaces/<a>/refs/namespaces/<b>/refs/heads/main` -- is just refs, and
a client can address those refs directly with explicit refspecs on any forge
that accepts refs outside `refs/heads/` and `refs/tags/`. So: **store in
namespace layout, access by refspec today, and the same repository becomes a
set of real namespaced repositories the moment it is served by
`git-http-backend` or gitolite.** No conversion step.

If a forge turns out to reject custom refs outright, the fallback is to put
each member on an ordinary `refs/heads/` branch. That is **verified working on
GitHub today**, at the price of the cheap-clone property and of some
sharp edges (directory/file ref conflicts, git-annex branch collisions) that
the namespace layout does not have.

## How namespaces actually behave

Verified locally against git 2.43 (`tools/build-demo.sh`):

| Behaviour                          | Result                                                    |
| ---------------------------------- | --------------------------------------------------------- |
| `GIT_NAMESPACE=x git ls-remote`    | only that namespace's refs, rewritten to `refs/heads/*`   |
| plain `git clone URL`              | `refs/heads/*` only; namespaced refs **not** pulled       |
| `git clone` of a local *path*      | namespace ignored; use `file://` (see note 1)             |
| namespace `HEAD`                   | **required**, and must be fully qualified (note 2)        |
| hierarchical `a/b/c`               | interleaves `refs/namespaces/` between components         |
| object store                       | shared; a duplicate push added **0** objects              |
| `git gc`                           | all namespaces reachable, nothing pruned                  |
| persisting a namespace client-side | `uploadpack`/`receivepack` config, non-http only (note 3) |

1. A local *path* clone copies objects and reads refs directly, bypassing
   `upload-pack`, which is what interprets `GIT_NAMESPACE`. Use a `file://`
   URL to force the real transport.
2. `refs/namespaces/x/HEAD` must point at
   `refs/namespaces/x/refs/heads/main`. Pointing it at `refs/heads/main`
   silently serves the *top-level* branch instead -- the clone succeeds and
   checks out the wrong tree.
3. `remote.origin.uploadpack = "env GIT_NAMESPACE=x git-upload-pack"` (and
   the matching `receivepack`) pins a namespace without any environment
   variable, for `ssh://` and `file://`. Over http the server decides, so
   this does not work there.

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

| Forge                                         | `GIT_NAMESPACE`                  | Custom refs           |
| --------------------------------------------- | -------------------------------- | --------------------- |
| stock git (`git-http-backend`, gitolite, ssh) | yes, documented                  | yes                   |
| Gitea / Forgejo                               | **ignored** (tested)             | **accepted** (tested) |
| GitHub                                        | not client-selectable            | untested              |
| GitLab                                        | ignored; folded into the default | partial               |

"Custom refs" means refs outside `refs/heads/` and `refs/tags/`. Gitaly
additionally rejects pushes into GitLab's *own* internal ref namespaces. On
GitHub the branch-prefix fallback is verified working regardless of how the
custom-ref question resolves.

### Gitea and Forgejo, read and then tested

Source read against `go-gitea/gitea` at `191287d`, then **built from source
(SQLite) and run**, and both questions probed against the live instance.
Forgejo is a soft fork of Gitea and has not diverged in this code path;
Codeberg and `forgejo.org` were unreachable from the environment this was
written in, so Forgejo itself was not exercised -- treat its row as inherited
from Gitea rather than independently confirmed. `tools/forgejo-probe.sh`
repeats both probes against a real Forgejo-aneksajo container.

**Namespaces: ignored.** `GIT_NAMESPACE` and `refs/namespaces` appear nowhere
in the codebase -- not in the git wrapper, the HTTP routes, the config, or
the templates; there is nothing to enable. Confirmed live: a push with
`GIT_NAMESPACE=probe` landed at top level as `refs/heads/nsprobe`, and
`ls-remote` under that namespace returned the plain view unchanged. So the
long-standing claim that Forgejo "does not support namespaces" is right, and
the reason is simply that the feature was never wired up.

**Custom refs: accepted.** `routers/private/hook_pre_receive.go` dispatches
each incoming ref by kind -- branch, tag, or `refs/for/` (agit) -- and
everything else falls through to:

```go
default:
        ourCtx.assertCanWriteRef(refFullName)
```

a plain write-permission check, so a pusher with write access to the code
unit may create any ref name. The forge then ignores it:
`hook_post_receive.go` gates indexing, notification and default-branch logic
on `IsBranch()`/`IsTag()`, and `GC_ARGS` defaults to empty, so maintenance
runs a plain `git gc`, which treats every ref as a root.

Confirmed live, with an ordinary branch and tag as controls. All seven probe
refs were accepted, advertised to `ls-remote`, absent from a plain clone, and
deletable again:

```
ACCEPTED  refs/namespaces/probe/refs/heads/main
ACCEPTED  refs/namespaces/a/refs/namespaces/b/refs/namespaces/c/refs/heads/main
ACCEPTED  refs/namespaces/probe/HEAD
ACCEPTED  refs/namespaces/probe/refs/heads/git-annex
ACCEPTED  refs/bugs/probe
ACCEPTED  refs/notes/probe
ACCEPTED  refs/artifacts/probe/main
```

Then the whole design, in refspec mode against that instance: the four
members pushed, `git-monorepo ls` listing them, a plain clone bringing back
`README.md` and nothing else, and `git-monorepo clone` of the leaf followed
by `git annex get` pulling content from the web remote. **So Forgejo is a
working target for this design today** -- no namespace support needed, and no
open question of the kind GitHub still has.

One cosmetic gap: refspec-mode pushes cannot set a member's `HEAD` symref
(that needs server-side access), so `git-monorepo ls` shows `--------` in the
HEAD column. It matters only for namespace-mode clones.

### A note on where to test

Codeberg is not the place for it. In 2026 Codeberg amended its terms to ban
repositories consisting mostly of generative-AI output without human
oversight, passed by member vote. A scratch repo full of machine-generated
scaffolding is squarely what that targets, whatever the intent. Use a local
container (`tools/forgejo-probe.sh`) or your own instance.

### Tested on GitHub: the branch-prefix fallback

`tools/gh-branch-layout-demo.sh` built the same 3-deep hierarchy on the real
`con/serve-monorepo-dev`, using **only** `refs/heads/*` -- the layout to fall
back on if a forge will not take custom refs. Members live on `m/**` branches
and every submodule URL is the relative `../serve-monorepo-dev`, i.e. the
repository points at itself.

It works, end to end:

- `git clone -b <branch>` then `git submodule update --init --recursive`
  walks all three levels, each cloned from the same GitHub URL
- the git-annex leaf resolves and `git annex get` pulls content from the
  public URLs recorded at ingest
- relative submodule URLs mean the whole thing relocates by moving the repo

Two costs are now measured rather than assumed, and both are arguments for
the namespace layout:

- **Members are ordinary branches**, so they are advertised to every clone,
  every `git branch -a`, and every branch dropdown. The cheap-clone property
  is gone; `--single-branch` recovers it for the top level only.
- **Directory/file conflict.** `refs/heads/m/tinuous` cannot coexist with
  `refs/heads/m/tinuous/2026/...`; GitHub rejects the push with
  `cannot lock ref ...: 'refs/heads/m/tinuous/2026/09/git-annex' exists`.
  So a member can never sit at a prefix of another member's path, and every
  member needs a trailing component (`m/tinuous/main`). The namespace layout
  interleaves `refs/namespaces/` between components and is structurally
  immune to this.
- **git-annex branch collision.** Every git-annex repository insists on
  `refs/heads/git-annex`. With one branch namespace, all members collide on
  it, so each needs a renamed branch plus a fetch refspec mapping it back in
  *every* clone:

  ```
  fetch = +refs/heads/m/tinuous/2026/09/git-annex:refs/heads/git-annex
  ```

  Under namespaces each member gets its own `refs/heads/git-annex` for free.
  This is the single strongest argument for the namespace layout.

### The custom-ref question on GitHub remains open

Still unanswered, and for an environmental reason rather than a GitHub one.
In the session where this was written the git proxy permitted pushes only to
`refs/heads/*`: an ordinary branch succeeded, while an ordinary **tag**
(`refs/tags/zz-probe-tag`) and every custom ref returned an identical
`HTTP 403`, and the REST refs API answered *"Write access to this GitHub API
path is not permitted through this proxy."* Since GitHub unquestionably
accepts tags, that 403 is the proxy, not GitHub, and it makes the probe
uninformative in that environment.

`tools/gh-ref-probe.sh` now pushes an ordinary branch **and an ordinary tag
as controls first**, and declares its results void if either fails -- exactly
the false negative that bit this investigation.

Evidence short of a test: GitHub is a compliant git implementation and
[community discussion #30507](https://github.com/orgs/community/discussions/30507)
states custom refs can be pushed and pulled, though they are invisible in the
web UI and reachable only through the REST refs API. The known rejections are
GitHub's *own* hidden refs (`refs/pull/*`). So the expectation is that it
works, with these risks left to confirm from an unproxied clone:

- whether `refs/namespaces/*` specifically is rejected as reserved
- whether such refs survive GitHub's GC and repository maintenance
- whether they survive fork, transfer and mirror operations
- whether repository size limits count them (they will)

## Tools

| File                             | What it does                                                                     |
| -------------------------------- | -------------------------------------------------------------------------------- |
| `tools/git-monorepo`             | list / clone / push / attach members of a single-repo collection, in either mode |
| `tools/ns-http-server.py`        | namespace-aware smart-HTTP server (`/~<ns>/<repo>.git`) over `git-http-backend`  |
| `tools/build-demo.sh`            | builds the verified 3-deep + git-annex demo from scratch                         |
| `tools/gh-ref-probe.sh`          | probes a forge's ref-name policy, non-destructively, with controls               |
| `tools/gh-branch-layout-demo.sh` | builds the branch-prefix fallback on a real GitHub repo                          |

Quickstart:

```bash
REPO_ROOT=/tmp/mono/server python3 tools/ns-http-server.py 8178 &
bash tools/build-demo.sh
tools/git-monorepo ls    http://127.0.0.1:8178/monorepo.git
tools/git-monorepo clone http://127.0.0.1:8178/monorepo.git a/tinuous/2026/09 /tmp/leaf
```

## Remaining unknowns

- GitHub's custom-ref policy and GC behaviour (above) -- blocking for the
  namespace layout. The branch-prefix fallback works today and is the
  answer if custom refs turn out to be rejected.
- Per-member access control: namespaces share one repository, so they share
  its ACL. Splitting "code is public, CI logs are internal" needs separate
  repositories or a gateway that filters refs.
- Discoverability: nothing in a forge UI lists members. `git-monorepo ls`
  reconstructs the list from `ls-remote`; a manifest ref would be cheaper.
- Growth: one repository accumulates every artifact. Namespaces do not bound
  size, and forge size limits apply to the whole thing.
- Whether `datalad clone` can be taught a refspec-mode member, or whether it
  needs the namespace-aware URL form.
- Whether Forgejo-aneksajo's git-annex support interacts with member refs at
  all -- `tools/forgejo-probe.sh` starts the right container but was not
  runnable where this was written (no usable container runtime, and
  `codeberg.org` blocked, so the image could not be pulled).

## Related

- [Vault Organization](../../content/concepts/vault-organization.md)
- [Git content-store side channels](../../content/concepts/git-content-store-side-channels.md)
- [Software Project user story](../../content/user-stories/software-project.md)
- [gitnamespaces(7)](https://git-scm.com/docs/gitnamespaces)
