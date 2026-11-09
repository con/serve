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
  **inside its own namespace** (`.../09/refs/heads/git-annex`), colliding with
  nothing. This is safe only when the forge is plain git storage -- on a forge
  that is *itself* an annex remote it breaks, see the aneksajo section
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

| Forge | `GIT_NAMESPACE` | Custom refs |
| --- | --- | --- |
| stock git (`git-http-backend`, gitolite, ssh) | yes, documented | yes |
| Forgejo-aneksajo 16.0.7 | absent | **accepted** (tested) |
| Forgejo-aneksajo 1.21 | absent | **accepted** (tested) |
| Gitea (current source) | absent | **accepted** (tested) |
| GitHub | not client-selectable | untested |
| GitLab | ignored; folded into the default | partial |

"Custom refs" means refs outside `refs/heads/` and `refs/tags/`. Gitaly
additionally rejects pushes into GitLab's *own* internal ref namespaces. On
GitHub the branch-prefix fallback is verified working regardless of how the
custom-ref question resolves.

### Gitea, read and then tested

Source read against `go-gitea/gitea` at `191287d`, then **built from source
(SQLite) and run**, and both questions probed against the live instance.
Forgejo is a soft fork of Gitea and has not diverged in this code path;
Forgejo-aneksajo was then tested directly -- see below -- so its row is no
longer inherited.

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

### Forgejo-aneksajo, built and run

This is the intended production target, so it was tested rather than
inferred. `codeberg.org` is unreachable from the environment this was written
in, so neither the container image nor a git clone was available -- but **the
Go module proxy serves the source**, because Google's proxy can reach Codeberg
even when we cannot:

```
go list -m -versions codeberg.org/forgejo-aneksajo/forgejo-aneksajo
go mod download -json codeberg.org/forgejo-aneksajo/forgejo-aneksajo@v1.21.11-1.git-annex0
```

`v1.21.11-1.git-annex0` is the newest version reachable that way; later
releases renamed the module to `forgejo.org`, which is blocked. Two wrinkles
in building it: the module zip omits the generated `options/locale/locale_*.ini`
(copy `options/locales/gitea_*.ini` over them), and Forgejo 1.21 has a logger
data race that Go 1.24+ turns into a fatal error, so build it with
`GOTOOLCHAIN=go1.21.13`.

Results against the running instance, `[annex] ENABLED = true`, builtin SSH:

| Question                                    | Result                                     |
| ------------------------------------------- | ------------------------------------------ |
| custom refs, incl. 3-deep `refs/namespaces` | accepted, with branch+tag controls passing |
| are they advertised to `ls-remote`?         | yes                                        |
| does a plain clone pull them?               | no                                         |
| `GIT_NAMESPACE`                             | absent from the source, ignored live       |
| annex **content** stored on the forge       | works, with the constraint below           |

**The constraint: one `git-annex` branch per repository.** Giving each member
its own namespaced annex branch breaks content transfer. `git annex copy --to`
uploads the bytes and then fails server-side:

```
fatal: not a valid object name refs/heads/git-annex
git-annex: user error (git [... "commit-tree" ... "-p" "refs/heads/git-annex"] exited 128)
```

`git-annex-shell` records location state in the repository's *canonical*
`refs/heads/git-annex`, which does not exist when every member namespaces its
own. The content lands but the bookkeeping does not, which is worse than a
clean failure.

The fix is to let all members **share** the canonical `refs/heads/git-annex`
and namespace only their content branches. That works, and works well: the
branch union-merges across members, and after two members had pushed, the
shared `uuid.log` correctly listed the forge plus both members. Because annex
keys are content-addressed, the single object store also deduplicates content
across members -- the same property namespaces give for git objects.

Verified end to end: two members (`.../2026/09` and `.../2026/10`) pushed to
namespaced content branches with content uploaded to the forge, then fetched
into fresh clones by refspec, with `git annex get` pulling **from the forge**
rather than from a web URL. A plain clone of the repository still returned
only `README.md`.

One rough edge: `git annex sync` pushes the content branch to canonical
`refs/heads/*`, bypassing the namespaced layout. Set `remote.<r>.push`
explicitly (`git-monorepo clone` does) and prefer `--no-content` plus an
explicit push.

So the two deployment modes want different annex layouts:

| Forge's role                            | `git-annex` branch               |
| --------------------------------------- | -------------------------------- |
| plain git storage, content elsewhere    | per member, inside its namespace |
| annex remote (aneksajo) holding content | one shared canonical branch      |

### Forgejo-aneksajo 16.0.7, in a container

The open question -- whether a *current* aneksajo accepts custom refs -- is
now answered, by running the hub's exact version locally:

```
docker pull codeberg.org/forgejo-aneksajo/forgejo-aneksajo:v16.0.7-git-annex1-rootless
docker run -d --network host -e FORGEJO__security__INSTALL_LOCK=true \
  -e FORGEJO__annex__ENABLED=true <image>
```

reporting `16.0.7-git-annex1+gitea-1.22.0`, byte-identical to the hub. With an
ordinary branch and tag passing as controls, all seven probe refs were
accepted, advertised to `ls-remote`, absent from a plain clone, and deletable
-- including the 3-deep `refs/namespaces` path and a per-member `git-annex`
branch. So the design holds on aneksajo 16 as it did on 1.21.

The whole demo was then built and verified against that instance: a plain
clone of 192K on `main` pulling no member, all five members listed, each
fetchable alone, `git annex get` working at the top and both leaves, and three
real issues exported into the `issues` member.

Two traps the real forge sprang, both now handled by
`tools/populate-demo-repo.sh`:

1. **The target repository must be empty.** The populator writes the project's
   own history to `refs/heads/main`, so a repository created with "Initialize
   this repository" already has an unrelated root there and the push is
   rejected -- after the members have been written, which is the worst time to
   find out. It now checks up front and refuses, with `FORCE=1` to override.
2. **The default branch ends up wrong.** On an empty Forgejo/Gitea repository
   the first branch pushed under `refs/heads/` becomes the default, and that is
   `refs/heads/git-annex`, because the first annexed member creates the shared
   annex branch before the project exists. A plain clone then checks out
   `git-annex`. The populator resets it through the API, and says so loudly
   when it has no API credentials to do it with.

Note on running this in a cloud session: `dockerd`, `containerd` and `runc` are
present and the daemon starts fine; with no usable bridge, `--network host`
publishes the port. The image comes from `codeberg.org`, which the environment
must allow.

### Annex content over HTTP: the P2P-HTTP endpoint

**Correction.** An earlier version of this file claimed aneksajo was
"HTTPS read-only" for annex content and that uploads needed SSH. That was
wrong. The evidence for it was git-annex printing

```
Remote origin not usable by git-annex; setting annex-ignore
```

which is the *client* declining, and says nothing about what the server can
do. Forgejo-aneksajo implements git-annex's P2P-HTTP protocol and content
uploads over plain HTTP(S) work.

`routers/web/web.go` registers the handler at the server **root**, not under
the repository path, because the uuid in the path selects the repository:

```go
m.Group("", func() {
    m.Methods("GET,POST", "/git-annex-p2phttp/git-annex/{uuid}/*", repo.AnnexP2PHTTP)
}, ignoreCSRF, annexEnabled, annexP2PHTTPEnabled)
```

and `modules/setting/annex.go` makes it **opt-out**, so it is on wherever
`[annex] ENABLED` is:

```go
Enabled        bool   `ini:"ENABLED"`
DisableP2PHTTP bool   `ini:"DISABLE_P2PHTTP"`
P2PHTTPCPUs    string `ini:"P2PHTTP_CPUS"`
P2PHTTPJobs    string `ini:"P2PHTTP_JOBS"`
```

Three things have to line up on the client, and all three were wrong here:

| Requirement | What went wrong |
| --- | --- |
| git-annex new enough | the test client was 10.20240129, which has no `p2phttp` command at all -- P2P-HTTP postdates it |
| `remote.<name>.annexUrl` set | it is **not** auto-discovered; without it git-annex probes `<url>/config`, finds nothing and sets `annex-ignore` |
| the host reachable | against a localhost instance git-annex's SSRF guard also refuses, needing `annex.security.allowed-ip-addresses` |

The annexUrl is derived from the repository url -- scheme and host only, then
the fixed path:

```
repo:      https://forge.example.org/owner/repo.git
annexUrl:  annex+https://forge.example.org/git-annex-p2phttp/git-annex/
```

With that set, `git annex copy --to origin` works over HTTP. Verified with
git-annex 10.20261026 against aneksajo 16.0.7: a `git-monorepo import` over a
plain `http://` url put 8 objects (2.3M) into the forge's annex store, and
fresh per-member clones pulled every one of them back. SSH still works too,
through `git-annex-shell`; it is simply not required.

Both `git-monorepo` and `populate-demo-repo.sh` now set `annexUrl`
themselves.

### Leave the git-annex branch to git-annex

Earlier versions of these tools maintained the shared `refs/heads/git-annex`
by hand: `git annex merge`, then a manual `git push` of that branch, then a
retry loop when the pushes kept being rejected as non-fast-forwards. That is a
reimplementation of `git annex sync`, and a worse one -- the branch is a
moving target, since every member adds to it and the forge appends to it when
content lands.

**The git-annex branch belongs to git-annex.** `git annex sync` fetches,
merges and pushes it, and other commands maintain it as they go. Both tools
now call

```bash
git config remote.origin.push '+refs/heads/main:<namespace>/refs/heads/main'
git annex sync --no-content origin
```

and never touch the branch themselves. Two things fall out of that for free:

- sync honours `remote.<name>.push`, so the member's content branch still
  lands in its namespace rather than on `refs/heads/main`;
- sync pushes the content branch and the annex branch as **separate** pushes,
  which an empty repository requires. Sending both in one push makes the forge
  reject the annex branch with `[remote rejected] git-annex (reference already
  exists)` even though `ls-remote` shows no refs at all. That failure, and the
  retry loop added to paper over it, both disappeared with sync.

A member clone likewise fetches the shared branch only to
`refs/remotes/origin/git-annex` and stops; `git annex init` merges it.

### The demo now stores its content on the forge

`populate-demo-repo.sh` copies annexed content to the forge over P2P-HTTP
after each member is pushed, so the repository is self-contained rather than
depending on the public URLs. Verified end to end: seven objects in the
forge's annex store, and a member clone fetching them with

```console
git annex get --from origin logs/
```

Content stays registered against its public URLs as well, so a clone has two
sources and still works if the forge is unreachable.

### Settling the GitHub question yourself

`tools/gh-ref-probe.sh` answers it in under a minute from anywhere push
access works. It needs only git:

```bash
git clone -b claude/determined-feynman-ub6vnd https://github.com/con/serve
cd serve/projects/self-contain-github-repo/tools
./gh-ref-probe.sh https://github.com/<you>/<scratch-repo>
```

It pushes an ordinary branch and tag as **controls** first and refuses to
report anything if either fails -- that is what caught the false negative from
a sandbox whose proxy allowed only `refs/heads/*`. Then it pushes seven custom
refs (a flat namespace, a 3-deep one, a namespace `HEAD`, a `git-annex`
branch, `refs/bugs/`, `refs/notes/`, an arbitrary prefix), checks they can be
fetched back by refspec and that a plain clone ignores them, prints a verdict,
and deletes them again. Probe refs are uniquely named per run, so a leftover
from an earlier run cannot poison the next one.

Exit status is `0` accepted, `1` rejected, `2` inconclusive. Both branches are
tested: against Forgejo-aneksajo 16.0.7 it reports

```
VERDICT: ACCEPTED -- the namespace layout works on this forge.
```

and against a proxy that blocks tag pushes it reports

```
VERDICT: INCONCLUSIVE.
  A plain branch or tag could not be pushed, so this says nothing about
  whether the forge accepts custom refs.
```

On ACCEPTED, build the real thing with `./populate-demo-repo.sh <push-url>
<repo-basename>` against an empty repository. On REJECTED, the same script
with `LAYOUT=branches`.

One thing the probe cannot answer: whether GitHub keeps such refs through
garbage collection, repository maintenance, forks and transfers. That needs
time rather than a script -- push the refs, come back in a week, re-run
`git ls-remote`.

### On GitHub: `LAYOUT=branches`

The namespace layout still cannot be exercised against GitHub from here --
this session's git proxy permits pushes only to `refs/heads/*`, and an
ordinary **tag** gets the same 403 as a custom ref, so the probe's controls
fail and its result is void. That is the proxy, not GitHub.

What does work on GitHub is the fallback: `LAYOUT=branches` puts each member
on an ordinary branch, `m/<namespace>/main`. Pushed to
`con/serve-monorepo-dev` and verified:

| Check | Result |
| --- | --- |
| members pushed | `m/tinuous/main`, `m/tinuous/2025/main`, `m/tinuous/2026/main`, `m/issues/main` |
| `git submodule update --init --recursive` | **works natively**, all three levels, no helper |
| annexed pointers | present at every level, content retrieved from the recorded URLs |
| plain clone | 224K |

Native submodule resolution is the real advantage here: the gitlink commits
are reachable from `refs/heads/*`, so stock git walks the hierarchy with no
tooling at all. The price is the one measured earlier -- members are ordinary
branches, so every clone fetches them and the branch list fills up (15 refs in
that repository now).

Three bugs surfaced only once this ran against a second forge:

1. **`git annex sync` was eating the submodules.** By default sync commits
   outstanding working-tree changes first. A member's submodules are gitlinks
   added with `update-index --cacheinfo` and have no directory on disk, so
   sync read them as deletions and committed that -- stripping every submodule
   from the tree it had just been told to publish. `--no-commit` fixes it.
2. **`git annex sync` was merging the wrong branch.** sync pulls as well as
   pushes, and merges the remote branch of the same name into the current one.
   Against a repository that already had an unrelated `refs/heads/main` it
   died with `refusing to merge unrelated histories`, exit 1, taking the run
   with it. Restricting `remote.origin.fetch` to
   `+refs/heads/git-annex:refs/remotes/origin/git-annex` leaves sync exactly
   the one branch it is supposed to merge.
3. **Relative submodule URLs scaled with depth.** git resolves a submodule's
   relative url against its *immediate superproject's* url, not against how
   deep the path is -- and every member here has the same repository url. The
   `../../` at level two ate the owner
   (`.../con/repo.git` + `../../repo.git` -> `.../repo.git`) and nested
   submodules failed to clone. It is one `../` at every level.

### Running the populator yourself

It needs nothing but a push URL, so it can be run from anywhere credentials
work:

```bash
git clone -b claude/determined-feynman-ub6vnd https://github.com/con/serve
cd serve/projects/self-contain-github-repo
export HUB_API=https://hub.centerforopenneuroscience.org/api/v1
export HUB_REPO=<owner>/<repo>
export TOKEN=<a token with write:repository>
./tools/populate-demo-repo.sh \
  "https://<user>:$TOKEN@hub.centerforopenneuroscience.org/$HUB_REPO.git" \
  "$(basename "$HUB_REPO")"
```

`HUB_API`/`HUB_REPO`/`TOKEN` are optional and used only to export the forge's
real issues into the `issues` member and to set the default branch back to
`main`. The target repository must be empty.

### A demo repository on hub.centerforopenneuroscience.org

The CON hub runs **Forgejo-aneksajo 16.0.7-git-annex1+gitea-1.22.0** -- far
newer than the v1.21 that was buildable from the module proxy, so it is the
first chance to check this design against a current aneksajo.

`tools/populate-demo-repo.sh <push-url>` builds the whole demo into one
repository:

```
refs/heads/main                                         the project
refs/heads/git-annex                                    shared annex branch
refs/namespaces/tinuous/refs/heads/main                 CI archive root
refs/namespaces/tinuous/refs/namespaces/2025/...        2025 logs (annexed)
refs/namespaces/tinuous/refs/namespaces/2026/...        2026 logs (annexed)
refs/namespaces/issues/refs/heads/main                  issue export
```

`main` carries two members as submodules (`tinuous`, `issues`) and `tinuous`
carries two more (`2025`, `2026`), so the hierarchy is three levels deep with
annexed content at the top and at both leaves. Each `.gitmodules` entry points
its `url` back at the same repository and names the member in a
`monorepo-namespace` key, since the forge serves no per-namespace URL.

Verified against a local bare repo over HTTP: a plain clone is 192K and pulls
no member, `git-monorepo ls` lists all five, each member fetches on its own,
and `git annex get` retrieves content at every level.

Two things that only showed up once the demo was built, both consequences of
the shared annex branch:

1. **Pushing the shared branch needs a union merge.** Each member's
   `git-annex` branch is an independent root, so the second and later members
   are rejected as non-fast-forward. `git annex merge` against the fetched
   remote branch is what reconciles them; `populate-demo-repo.sh` does this
   before every annexed push.
2. **The annex branch now lives in one of two places**, and tooling has to
   look in both: inside the member's namespace when the forge is plain git
   storage, or at the canonical `refs/heads/git-annex` when members share it.
   `git-monorepo clone` fetches whichever exists directly into the local
   `refs/heads/git-annex`, because git-annex only ever consults that name -- a
   clone that misses it gets an empty annex branch and every pointer dangles.

Status: not yet populated on the hub, blocked on one credential detail. The
session's egress proxy injects a saved `Authorization` header for the hub, so
whatever token a client sends is discarded -- a request with *no* header, one
with a valid token and one with a garbage token all return the identical
authenticated error, which is how this was established. The injected token
belongs to `yarikoptic-gitmate` and demonstrably holds `read:repository` and
`write:issue` but not `write:repository`: reads and issue creation succeed
while git push and the contents API return 403, and the repository reports
`{admin: false, push: false, pull: true}` even after that account was granted
collaborator write. So the fix is the token's scopes, not the collaborator
grant and not the token's format.

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
- Whether newer Forgejo-aneksajo (v7+/v14, module renamed to `forgejo.org`)
  still behaves as v1.21 does here. The pre-receive dispatch is unchanged
  between aneksajo 1.21 and Gitea at `191287d`, which is reassuring but not
  proof.

## Related

- [Vault Organization](../../content/concepts/vault-organization.md)
- [Git content-store side channels](../../content/concepts/git-content-store-side-channels.md)
- [Software Project user story](../../content/user-stories/software-project.md)
- [gitnamespaces(7)](https://git-scm.com/docs/gitnamespaces)
