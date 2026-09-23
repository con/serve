#!/bin/bash
# Does a forge accept refs outside refs/heads/ and refs/tags/?
#
# This is THE question that decides whether the single-repo layout works on a
# given forge. Run it against a scratch repo you can write to:
#
#     ./gh-ref-probe.sh https://github.com/con/serve-monorepo-dev
#
# It pushes a handful of probe refs, reports accepted/rejected per ref,
# checks whether a plain `git clone` picks them up, and deletes them again.
set -uo pipefail
URL=${1:?usage: gh-ref-probe.sh <repo-url>}
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

# NB: do NOT set GIT_CONFIG_GLOBAL here. Credential helpers, proxy settings
# and http.* auth live in the global config; replacing it makes every push
# fail with an indistinguishable 403 and the probe reports false negatives.
# Keep the ambient config and override only what matters, per invocation.
git init -q -b main "$W/r"; cd "$W/r"
git config user.name probe; git config user.email probe@example.com
git config commit.gpgsign false; git config push.negotiate false
echo probe > probe.txt; git add probe.txt; git commit -qm "ref-policy probe"
SHA=$(git rev-parse HEAD)

# Control: an ordinary branch and an ordinary tag. Every forge accepts both.
# If either fails, the failure is environmental (credentials, a push proxy,
# branch protection) and the results below say nothing about ref policy.
echo "== controls =="
for c in "refs/heads/zz-probe-control" "refs/tags/zz-probe-control"; do
  if git push "$URL" "$SHA:$c" >/dev/null 2>&1; then
    echo "  ok       $c"; git push -q "$URL" ":$c" 2>/dev/null
  else
    echo "  FAILED   $c  <- environment problem, not ref policy; results below are void"
  fi
done

REFS=(
  "refs/namespaces/probe/refs/heads/main"                            # flat namespace
  "refs/namespaces/a/refs/namespaces/b/refs/namespaces/c/refs/heads/main"  # 3-deep
  "refs/namespaces/probe/HEAD"                                       # namespace HEAD
  "refs/namespaces/probe/refs/heads/git-annex"                       # git-annex branch
  "refs/bugs/probe"                                                  # git-bug style
  "refs/notes/probe"                                                 # notes
  "refs/artifacts/probe/main"                                        # arbitrary prefix
)

echo "== push probe =="
OK=()
for ref in "${REFS[@]}"; do
  out=$(git push "$URL" "$SHA:$ref" 2>&1)
  if [ $? -eq 0 ] && ! grep -qiE 'rejected|error:|denied|fatal' <<<"$out"; then
    printf '  ACCEPTED  %s\n' "$ref"; OK+=("$ref")
  else
    printf '  REJECTED  %s\n            %s\n' "$ref" \
      "$(grep -iEm1 'rejected|error:|denied|fatal' <<<"$out" | cut -c1-140)"
  fi
done

echo "== are they advertised to a client? (git ls-remote) =="
git ls-remote "$URL" | grep -E 'namespaces|bugs|artifacts|notes' | sed 's/^/  /' || echo "  (none advertised)"

echo "== does a plain 'git clone' drag them in? =="
git clone -q "$URL" "$W/c" 2>/dev/null
if git -C "$W/c" for-each-ref --format='%(refname)' | grep -qE 'namespaces|bugs|artifacts'; then
  echo "  YES -- cheap-clone property LOST"
else
  echo "  NO  -- plain clone stays clean (this is what we want)"
fi

echo "== cleanup =="
for ref in "${OK[@]}"; do git push -q "$URL" ":$ref" 2>/dev/null && echo "  deleted $ref"; done
