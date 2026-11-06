#!/bin/bash
# Populate ONE forge repository with a collection of repositories:
#
#   refs/heads/main                      the project      <- plain `git clone` gets only this
#   refs/heads/git-annex                 shared annex branch (see NOTE)
#   refs/namespaces/tinuous/...          CI archive root, itself holding two members
#   refs/namespaces/tinuous/2025/...     annexed CI logs
#   refs/namespaces/tinuous/2026/...     annexed CI logs
#   refs/namespaces/issues/...           issue export
#
# Usage:  populate-demo-repo.sh <push-url> [<repo-basename>]
#   <push-url>       a URL you can push to, credentials included if needed
#   <repo-basename>  what the repo is called, for relative submodule URLs
#                    (default: derived from <push-url>)
#
# NOTE on the annex branch: every git-annex repository insists on
# refs/heads/git-annex, and on a forge that stores annex content
# (Forgejo-aneksajo) git-annex-shell writes location state to exactly that ref.
# So members SHARE one canonical annex branch and namespace only their content
# branches. Giving each member its own namespaced annex branch uploads content
# and then fails to record it.
set -euo pipefail

PUSH=${1:?usage: populate-demo-repo.sh <push-url> [<repo-basename>]}
BASENAME=${2:-$(basename "${PUSH%.git}")}
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

G="git -c commit.gpgsign=false -c push.negotiate=false -c advice.detachedHead=false"
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-con/serve demo}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-demo@example.org}"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

# The project's own history goes to refs/heads/main, so an already-initialised
# repository (Forgejo's "Initialize this repository", GitHub's auto_init) leaves
# an unrelated root commit there and the push is rejected as a non-fast-forward.
# Fail loudly rather than populate the members and silently skip the project.
REMOTE_MAIN=$(git ls-remote "$PUSH" refs/heads/main 2>/dev/null | awk '{print $1}')
if [ -n "$REMOTE_MAIN" ] && [ "${FORCE:-0}" != 1 ]; then
  cat >&2 <<EOM
refs/heads/main already exists on the target (${REMOTE_MAIN:0:12}).

This script writes the project's own history there, so it needs an EMPTY
repository -- create it without "Initialize this repository".

Re-run with FORCE=1 to overwrite the existing main instead.
EOM
  exit 1
fi
MAIN_LEAD=""; [ "${FORCE:-0}" = 1 ] && MAIN_LEAD="+"

ns_prefix() {  # a/b/c -> refs/namespaces/a/refs/namespaces/b/refs/namespaces/c
  local out=""; local IFS=/
  for p in $1; do out="$out/refs/namespaces/$p"; done
  echo "${out#/}"
}
say() { printf '\n== %s\n' "$*"; }

# Push a member's content branch into its own namespace. With --annex, the
# member's git-annex branch also goes to the SHARED refs/heads/git-annex -- and
# because each member's annex branch is an independent root, the shared ref has
# to be union-merged first or every push after the first is rejected as a
# non-fast-forward. `git annex merge` is what performs that union merge.
member_push() {           # member_push <dir> <namespace|""> [--annex]
  local dir=$1 ns=$2 annex=${3:-} dst
  local lead=""
  if [ -z "$ns" ]; then dst=refs/heads/main; lead=$MAIN_LEAD
  else dst="$(ns_prefix "$ns")/refs/heads/main"; fi
  if [ -n "$annex" ]; then
    $G -C "$dir" remote add origin "$PUSH" 2>/dev/null || \
      $G -C "$dir" remote set-url origin "$PUSH"
    # absent on the first member, hence the guard
    $G -C "$dir" fetch -q origin '+refs/heads/git-annex:refs/remotes/origin/git-annex' 2>/dev/null || true
    if $G -C "$dir" rev-parse -q --verify refs/remotes/origin/git-annex >/dev/null; then
      git -C "$dir" -c commit.gpgsign=false annex merge >/dev/null 2>&1
    fi
    $G -C "$dir" push -q "$PUSH" "$lead$(echo main):$dst" "git-annex:refs/heads/git-annex"
  else
    $G -C "$dir" push -q "$PUSH" "$lead$(echo main):$dst"
  fi
  $G -C "$dir" rev-parse main
}

# .gitmodules entry. The forge cannot serve a namespace at its own URL, so the
# url points back at this same repository and the namespace is recorded in a
# monorepo-namespace key that tooling (git-monorepo) reads.
gitmodule() {             # gitmodule <name> <path> <namespace> <depth>
  local name=$1 path=$2 ns=$3 depth=$4 rel=""
  local i; for ((i=0;i<depth;i++)); do rel="../$rel"; done
  cat <<EOF
[submodule "$name"]
	path = $path
	url = ${rel}${BASENAME}.git
	branch = main
	monorepo-namespace = $ns
EOF
}

annex_from_url() {        # annex_from_url <file> <url>
  git annex addurl --file="$1" "$2" >/dev/null 2>&1
}

############################################################ tinuous/2025
say "member tinuous/2025 (annexed CI logs)"
D=$W/t2025; $G init -q -b main "$D"; cd "$D"
git annex init -q "tinuous-2025" >/dev/null 2>&1
mkdir -p logs
cat > logs/index.json <<'EOF'
{"year": 2025, "runs": [{"id": 9001, "workflow": "test.yml", "status": "success"}]}
EOF
$G add logs/index.json; $G commit -qm "2025 run index (small, stays in git)"
annex_from_url logs/run-9001.log https://raw.githubusercontent.com/git/git/master/README.md
$G commit -qm "annexed CI log for run 9001"
SHA_2025=$(member_push "$D" tinuous/2025 --annex)
echo "   $SHA_2025"

############################################################ tinuous/2026
say "member tinuous/2026 (annexed CI logs)"
D=$W/t2026; $G init -q -b main "$D"; cd "$D"
git annex init -q "tinuous-2026" >/dev/null 2>&1
mkdir -p logs
cat > logs/index.json <<'EOF'
{"year": 2026, "runs": [{"id": 9101, "workflow": "test.yml", "status": "failure"},
                        {"id": 9102, "workflow": "build.yml", "status": "success"}]}
EOF
$G add logs/index.json; $G commit -qm "2026 run index"
annex_from_url logs/run-9101.log https://raw.githubusercontent.com/con/duct/main/README.md
annex_from_url logs/run-9102.log https://raw.githubusercontent.com/datalad/datalad/maint/README.md
$G commit -qm "annexed CI logs for runs 9101, 9102"
SHA_2026=$(member_push "$D" tinuous/2026 --annex)
echo "   $SHA_2026"

############################################################ tinuous (root)
say "member tinuous (holds 2025 and 2026 as submodules)"
D=$W/tinuous; $G init -q -b main "$D"; cd "$D"
cat > README.md <<EOF
# con/tinuous CI archive

A member repository of \`$BASENAME\`, living in the \`tinuous\` namespace.
It holds one member per year, each with its CI logs under git-annex.
EOF
$G add README.md; $G commit -qm "tinuous archive root"
{ gitmodule 2025 2025 tinuous/2025 2; gitmodule 2026 2026 tinuous/2026 2; } > .gitmodules
$G update-index --add --cacheinfo 160000,"$SHA_2025",2025
$G update-index --add --cacheinfo 160000,"$SHA_2026",2026
$G add .gitmodules; $G commit -qm "attach 2025 and 2026 as submodules"
SHA_TIN=$(member_push "$D" tinuous)
echo "   $SHA_TIN"

############################################################ issues
say "member issues (issue export)"
D=$W/issues; $G init -q -b main "$D"; cd "$D"
mkdir -p issues
if [ -n "${HUB_API:-}" ] && [ -n "${HUB_REPO:-}" ]; then
  curl -sS --max-time 30 ${TOKEN:+-H "Authorization: token $TOKEN"} \
    "$HUB_API/repos/$HUB_REPO/issues?state=all&limit=50" > issues/issues.json || echo '[]' > issues/issues.json
else
  echo '[]' > issues/issues.json
fi
python3 - <<'PY'
import json, os, pathlib
p = pathlib.Path("issues/issues.json")
try:
    data = json.loads(p.read_text())
except Exception:
    data = []
if not isinstance(data, list):
    data = []
if not data:   # offline / no issues yet: ship a representative sample
    data = [{"number": 1, "title": "Demo issue: namespaces for CI log archives",
             "state": "open", "body": "Placeholder export entry.",
             "user": {"login": "demo"}, "labels": []}]
slim = [{"number": i.get("number"), "title": i.get("title"), "state": i.get("state"),
         "author": (i.get("user") or {}).get("login"),
         "labels": [l.get("name") for l in (i.get("labels") or [])],
         "body": i.get("body")} for i in data]
p.write_text(json.dumps(slim, indent=2) + "\n")
pathlib.Path("issues/README.md").write_text(
    "# Issue export\n\n"
    f"{len(slim)} issue(s), exported from the forge API as flat JSON.\n\n"
    "This is the simplest shape an issues member can take. A git-bug store\n"
    "(`refs/bugs/*`) would be the richer alternative and would live in this\n"
    "same namespace.\n")
PY
$G add issues; $G commit -qm "issue export as flat JSON"
SHA_ISS=$(member_push "$D" issues)
echo "   $SHA_ISS"

############################################################ the project
say "the project itself (refs/heads/main)"
D=$W/main; $G init -q -b main "$D"; cd "$D"
git annex init -q "demo-main" >/dev/null 2>&1
mkdir -p data src
cat > src/analyze.py <<'EOF'
"""Stand-in for the project's actual code."""


def main() -> None:
    print("the project's code lives on refs/heads/main, like any repo")


if __name__ == "__main__":
    main()
EOF
$G add src/analyze.py; $G commit -qm "the project's code"
annex_from_url data/sample.dat https://raw.githubusercontent.com/datalad/datalad/maint/README.md
$G commit -qm "annexed data file in the main repo"
{ gitmodule tinuous tinuous tinuous 1; gitmodule issues issues issues 1; } > .gitmodules
$G update-index --add --cacheinfo 160000,"$SHA_TIN",tinuous
$G update-index --add --cacheinfo 160000,"$SHA_ISS",issues
cat > README.md <<EOF
# $BASENAME

One repository holding a **collection of repositories**. The project's own code
is on \`refs/heads/main\`; everything else lives in a git namespace in this same
repository, sharing its object store and its access control.

\`\`\`
refs/heads/main                                        the project (this)
refs/heads/git-annex                                   shared git-annex branch
refs/namespaces/tinuous/refs/heads/main                CI archive root
refs/namespaces/tinuous/refs/namespaces/2025/...        2025 logs (annexed)
refs/namespaces/tinuous/refs/namespaces/2026/...        2026 logs (annexed)
refs/namespaces/issues/refs/heads/main                 issue export
\`\`\`

## A plain clone stays small

\`\`\`console
git clone <this repo>
\`\`\`

fetches \`refs/heads/*\` only. The members are **not** pulled: you get the code,
\`.gitmodules\` and two empty submodule gitlinks.

## Fetching a member

The forge serves no per-namespace URL, so \`git submodule update\` cannot
resolve these on its own -- the gitlink commits are not reachable from
\`refs/heads/*\` by design. Fetch one explicitly:

\`\`\`console
# the 2026 CI logs, and nothing else
git init tinuous-2026 && cd tinuous-2026
git remote add origin <this repo>
git fetch origin \\
  '+refs/namespaces/tinuous/refs/namespaces/2026/refs/heads/*:refs/remotes/origin/*' \\
  '+refs/heads/git-annex:refs/remotes/origin/git-annex'
git checkout -b main origin/main
git annex init && git annex get logs/
\`\`\`

or let the helper do it:

\`\`\`console
git-monorepo ls    <this repo>
git-monorepo clone <this repo> tinuous/2026 ./tinuous-2026
\`\`\`

\`git-monorepo\` is in
[con/serve](https://github.com/con/serve/tree/master/projects/self-contain-github-repo/tools).

## Where the annexed content comes from

Files under \`data/\` and \`logs/\` are git-annex pointers whose content is
registered against public URLs, so \`git annex get\` works for anyone without
the forge holding a byte. On a Forgejo-aneksajo instance the content can also
be stored on the forge itself; the members share one \`refs/heads/git-annex\`
branch so that \`git-annex-shell\` can record where things are.

## \`.gitmodules\`

Each entry carries a \`monorepo-namespace\` key naming the member's namespace.
\`url\` points back at this same repository, because that is where the member
actually lives.
EOF
$G add README.md .gitmodules; $G commit -qm "project README and member submodules"
echo "   $(member_push "$D" "" --annex)"

# On an empty Forgejo/Gitea repository the FIRST branch pushed under refs/heads/
# becomes the default, and that is refs/heads/git-annex here, because the first
# annexed member creates the shared annex branch before the project exists. Left
# alone, a plain `git clone` checks out git-annex. Put it back.
say "default branch"
if [ -n "${HUB_API:-}" ] && [ -n "${HUB_REPO:-}" ]; then
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 -X PATCH \
    ${TOKEN:+-H "Authorization: token $TOKEN"} ${HUB_BASICAUTH:+-u "$HUB_BASICAUTH"} \
    -H 'Content-Type: application/json' -d '{"default_branch":"main"}' \
    "$HUB_API/repos/$HUB_REPO")
  if [ "$code" = 200 ]; then echo "   set to main via the API"
  else echo "   WARNING: could not set default branch (http $code) -- set it to 'main' in the forge UI"; fi
else
  echo "   NOT SET: pass HUB_API and HUB_REPO (plus TOKEN or HUB_BASICAUTH) to set it,"
  echo "   or set the default branch to 'main' in the forge UI. Until then a plain"
  echo "   clone checks out refs/heads/git-annex."
fi

say "done -- refs now on the forge"
git ls-remote "$PUSH" | sed 's|refs/namespaces/|  ns:|' | sed 's/^/  /'
