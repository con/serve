#!/bin/bash
# Build the "repo of repos" on a REAL GitHub repo using only refs/heads/*
# (the fallback layout, for a forge that will not take custom refs).
set -euo pipefail
URL=https://github.com/con/serve-monorepo-dev
W=/tmp/ghdemo; rm -rf $W; mkdir -p $W
G="git -c commit.gpgsign=false -c push.negotiate=false -c advice.detachedHead=false"
export GIT_AUTHOR_NAME="Yaroslav Halchenko" GIT_AUTHOR_EMAIL=yaroslav.o.halchenko@dartmouth.edu
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

# ---- level 3: annexed CI logs -------------------------------------------
L3=$W/l3; $G init -q -b main $L3; cd $L3
git annex init -q "tinuous-2026-09" >/dev/null 2>&1
mkdir -p logs; echo '{"run":1234,"status":"success"}' > logs/run-1234.json
$G add -A; $G commit -qm "small metadata stays in git"
git annex addurl --file=logs/build-01.log https://raw.githubusercontent.com/con/duct/main/README.md >/dev/null 2>&1
git annex addurl --file=logs/build-02.log https://raw.githubusercontent.com/datalad/datalad/maint/README.md >/dev/null 2>&1
$G commit -qm "annexed CI artifacts (content from public URLs)"
# NOTE the git-annex branch must be renamed per member, or every member
# collides on refs/heads/git-annex.
$G push -q $URL main:refs/heads/m/tinuous/2026/09/main \
                 git-annex:refs/heads/m/tinuous/2026/09/git-annex
L3SHA=$($G rev-parse main); echo "L3 $L3SHA"

# ---- level 2 -------------------------------------------------------------
L2=$W/l2; $G init -q -b main $L2; cd $L2
echo "CI logs for 2026" > README.md; $G add -A; $G commit -qm "year 2026"
printf '[submodule "09"]\n\tpath = 09\n\turl = ../serve-monorepo-dev\n\tbranch = m/tinuous/2026/09/main\n' > .gitmodules
$G update-index --add --cacheinfo 160000,$L3SHA,09
$G add .gitmodules; $G commit -qm "attach 09"
$G push -q $URL main:refs/heads/m/tinuous/2026/main
L2SHA=$($G rev-parse main); echo "L2 $L2SHA"

# ---- level 1 -------------------------------------------------------------
L1=$W/l1; $G init -q -b main $L1; cd $L1
echo "con/tinuous archive" > README.md; $G add -A; $G commit -qm "tinuous root"
printf '[submodule "2026"]\n\tpath = 2026\n\turl = ../serve-monorepo-dev\n\tbranch = m/tinuous/2026/main\n' > .gitmodules
$G update-index --add --cacheinfo 160000,$L2SHA,2026
$G add .gitmodules; $G commit -qm "attach 2026"
$G push -q $URL main:refs/heads/m/tinuous/main
L1SHA=$($G rev-parse main); echo "L1 $L1SHA"

# ---- level 0: the project (the designated branch) ------------------------
L0=$W/l0; $G init -q -b main $L0; cd $L0
cat > README.md <<'EOF'
# serve-monorepo-dev

Test bed for "one repository holding a collection of repositories".
See con/serve `projects/self-contain-github-repo/`.

Member repositories live on `m/**` branches of THIS repository and are
wired together as submodules pointing back at this same URL.
EOF
echo 'print("the project")' > main.py
$G add -A; $G commit -qm "the project itself"
printf '[submodule "artifacts/tinuous"]\n\tpath = artifacts/tinuous\n\turl = ../serve-monorepo-dev\n\tbranch = m/tinuous/main\n' > .gitmodules
$G update-index --add --cacheinfo 160000,$L1SHA,artifacts/tinuous
$G add .gitmodules; $G commit -qm "attach the CI-log archive as a submodule"
$G push -q -f $URL main:refs/heads/claude/determined-feynman-ub6vnd
echo "L0 $($G rev-parse main)"
