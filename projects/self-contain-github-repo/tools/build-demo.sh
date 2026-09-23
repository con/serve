#!/bin/bash
# Build a "repo of repos": ONE bare git repo holding a 3-deep submodule
# hierarchy, each level living in its own git namespace, leaf under git-annex.
set -euo pipefail

W=${W:-/tmp/mono}
PORT=${PORT:-8178}
SRV=$W/server/monorepo.git          # the single bare repo == the GitHub repo
BASE=http://127.0.0.1:$PORT

export GIT_CONFIG_GLOBAL=$W/gitconfig
cat > "$GIT_CONFIG_GLOBAL" <<EOF
[user]
	name = Demo
	email = demo@example.com
[commit]
	gpgsign = false
[push]
	negotiate = false
[advice]
	detachedHead = false
[protocol]
	allow = always
[init]
	defaultBranch = main
EOF

rm -rf "$W/server" "$W/work" "$W/clones"; mkdir -p "$W/server" "$W/work" "$W/clones"
git init -q --bare "$SRV"
git -C "$SRV" config http.receivepack true
git -C "$SRV" symbolic-ref HEAD refs/heads/main

# push a working tree into namespace $1 and give that namespace its own HEAD
ns_push() {
  local ns=$1 dir=$2 extra=${3:-}
  local url
  if [ -z "$ns" ]; then url="$BASE/monorepo.git"; else url="$BASE/~$ns/monorepo.git"; fi
  git -C "$dir" push -q "$url" main $extra
  # namespace HEAD must be a FULLY-QUALIFIED symref
  local prefix="refs/namespaces/${ns//\//\/refs\/namespaces\/}"
  [ -z "$ns" ] || git -C "$SRV" symbolic-ref "$prefix/HEAD" "$prefix/refs/heads/main"
}

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

############ level 3 (leaf): annexed CI logs for 2026/09 ############
say "level 3: a/tinuous/2026/09  (git-annex leaf)"
L3=$W/work/l3; git init -q -b main "$L3"; cd "$L3"
git annex init -q "tinuous-2026-09" >/dev/null 2>&1
mkdir -p logs
echo '{"run": 1234, "status": "success", "workflow": "test.yml"}' > logs/run-1234.json
git add logs/run-1234.json && git commit -qm "small metadata stays in git"
# real annexed content, fetched from public URLs (web special remote)
git annex addurl --file=logs/build-01.log \
  https://raw.githubusercontent.com/con/duct/main/README.md >/dev/null 2>&1
git annex addurl --file=logs/build-02.log \
  https://raw.githubusercontent.com/datalad/datalad/maint/README.md >/dev/null 2>&1
git commit -qm "annexed CI log artifacts (content from public URLs)"
ns_push a/tinuous/2026/09 "$L3" git-annex
L3SHA=$(git rev-parse HEAD)
echo "   leaf commit $L3SHA  annexed: $(git annex find | tr '\n' ' ')"

############ level 2: the year ############
say "level 2: a/tinuous/2026  (submodule -> 09)"
L2=$W/work/l2; git init -q -b main "$L2"; cd "$L2"
echo "CI logs for 2026" > README.md; git add README.md; git commit -qm "year 2026"
# The gitlink is written by hand: `git submodule add` insists on cloning the
# URL first, and the member is not reachable from refs/heads/* by design.
cat > .gitmodules <<EOF
[submodule "09"]
	path = 09
	url = ../09/monorepo.git
	branch = main
EOF
git update-index --add --cacheinfo 160000,"$L3SHA",09
git add .gitmodules && git commit -qm "add 09 as submodule (relative URL)"
ns_push a/tinuous/2026 "$L2"
L2SHA=$(git rev-parse HEAD)

############ level 1: the CI archive root ############
say "level 1: a/tinuous  (submodule -> 2026)"
L1=$W/work/l1; git init -q -b main "$L1"; cd "$L1"
echo "con/tinuous archive" > README.md; git add README.md; git commit -qm "tinuous archive root"
cat > .gitmodules <<EOF
[submodule "2026"]
	path = 2026
	url = ../2026/monorepo.git
	branch = main
EOF
git update-index --add --cacheinfo 160000,"$L2SHA",2026
git add .gitmodules && git commit -qm "add 2026 as submodule"
ns_push a/tinuous "$L1"
L1SHA=$(git rev-parse HEAD)

############ a sibling namespace: issues ############
say "sibling: a/issues"
LI=$W/work/li; git init -q -b main "$LI"; cd "$LI"
echo '[{"number":1,"title":"namespaces please"}]' > issues.json
git add issues.json; git commit -qm "issue export"
ns_push a/issues "$LI"

############ level 0: the project itself (what plain clone gets) ############
say "level 0: default namespace = the project code"
L0=$W/work/l0; git init -q -b main "$L0"; cd "$L0"
echo "# The project" > README.md; echo 'print("hi")' > main.py
git add .; git commit -qm "the actual project"
cat > .gitmodules <<EOF
[submodule "artifacts/tinuous"]
	path = artifacts/tinuous
	url = ../~a/tinuous/monorepo.git
	branch = main
EOF
git update-index --add --cacheinfo 160000,"$L1SHA",artifacts/tinuous
git add .gitmodules && git commit -qm "attach CI-log archive as submodule"
ns_push "" "$L0"

say "server refs"
git -C "$SRV" for-each-ref --format='  %(refname)' | sed 's|refs/namespaces/||'
