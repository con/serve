#!/bin/bash
# Probe a Forgejo-aneksajo instance for BOTH questions this project cares about:
#
#   1. does it accept refs outside refs/heads/ and refs/tags/?
#   2. does it honour GIT_NAMESPACE (i.e. serve namespaces as repositories)?
#
# Spins up a throwaway container, so it needs podman or docker and network
# access to codeberg.org. The container image and admin bootstrap follow
# datalad-fuse's fixture, which is the known-good recipe:
#   datalad_fuse/tests/conftest_forgejo.py  (datalad/datalad-fuse#127)
#
# If codeberg.org is unreachable but proxy.golang.org is not, you can still
# get an instance -- the Go module proxy mirrors the source:
#
#   go list -m -versions codeberg.org/forgejo-aneksajo/forgejo-aneksajo
#   go mod download -json codeberg.org/forgejo-aneksajo/forgejo-aneksajo@v1.21.11-1.git-annex0
#   # unzip it, then, from the source root:
#   cp options/locales/gitea_en-US.ini options/locale/locale_en-US.ini
#   GOTOOLCHAIN=go1.21.13 go build -tags "sqlite sqlite_unlock_notify" -o forgejo .
#
# The locale copy is needed because the module zip omits generated files, and
# the pinned toolchain because Forgejo 1.21 has a logger data race that Go
# 1.24+ turns into a fatal error. Then point this script at that instance:
#   ./forgejo-probe.sh http://127.0.0.1:3001 <user> <pass>
#
#   ./forgejo-probe.sh            # start a container, probe, tear down
#   ./forgejo-probe.sh <url> <user> <pass>   # probe an instance you already run
set -uo pipefail

IMAGE=${FORGEJO_IMAGE:-codeberg.org/forgejo-aneksajo/forgejo-aneksajo:v14.0.3-git-annex2-rootless}
NAME=serve-monorepo-probe-$$
USER_=${2:-probeadmin}; PASS=${3:-probepass123!}
HERE=$(cd "$(dirname "$0")" && pwd)
OWN_CONTAINER=0

if [ $# -ge 1 ]; then
  URL=$1
else
  RT=$(command -v podman || command -v docker) || { echo "need podman or docker"; exit 1; }
  RT=$(basename "$RT"); OWN_CONTAINER=1
  echo "== starting $IMAGE via $RT =="
  CID=$($RT run -d --rm --name "$NAME" -p 3000 -e FORGEJO__security__INSTALL_LOCK=true "$IMAGE") || exit 1
  trap '[ $OWN_CONTAINER = 1 ] && $RT rm -f "$NAME" >/dev/null 2>&1' EXIT
  PORT=$($RT port "$CID" 3000 | head -1 | sed 's/.*://')
  URL=http://127.0.0.1:$PORT
  echo "   $URL"
  for _ in $(seq 60); do curl -sf "$URL/api/v1/version" >/dev/null && break; sleep 2; done
  $RT exec "$CID" forgejo admin user create --admin --username "$USER_" \
      --password "$PASS" --email probe@test.nil --must-change-password=false >/dev/null
fi

echo "== instance =="
curl -sf "$URL/api/forgejo/v1/version" | head -c 200; echo
echo "   (a version string containing 'git-annex' means this is aneksajo, not stock Forgejo)"

REPO=refprobe
curl -sf -u "$USER_:$PASS" -H 'Content-Type: application/json' \
     -d "{\"name\":\"$REPO\",\"auto_init\":true}" "$URL/api/v1/user/repos" >/dev/null
PUSH="http://$USER_:$PASS@${URL#http://}/$USER_/$REPO.git"

echo
echo "== question 1: custom refs =="
"$HERE/gh-ref-probe.sh" "$PUSH"

echo
echo "== question 2: GIT_NAMESPACE =="
W=$(mktemp -d); trap 'rm -rf "$W"' RETURN 2>/dev/null || true
git init -q -b main "$W/r"; (
  cd "$W/r"
  git config user.name probe; git config user.email probe@test.nil
  git config commit.gpgsign false; git config push.negotiate false
  echo ns > f.txt; git add f.txt; git commit -qm "namespace probe"
  # If the forge honoured namespaces, this would land in namespace 'probe'
  # and be invisible to a plain clone.
  GIT_NAMESPACE=probe git push -q "$PUSH" HEAD:refs/heads/nsprobe 2>&1 | tail -2
)
echo "   refs the server reports:"
git ls-remote "$PUSH" | sed 's/^/     /'
echo
echo "   If 'refs/heads/nsprobe' appears at top level, GIT_NAMESPACE was ignored"
echo "   and the push landed in the default namespace -- the expected result:"
echo "   GIT_NAMESPACE appears nowhere in the Gitea/Forgejo source."
