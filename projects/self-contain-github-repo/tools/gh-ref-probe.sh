#!/bin/bash
# Does a forge accept refs outside refs/heads/ and refs/tags/?
#
# That single question decides whether the namespace layout -- a whole
# collection of repositories inside one repository, invisible to a plain clone
# -- works on a given forge. Run it against a scratch repo you can write to:
#
#     ./gh-ref-probe.sh https://github.com/you/scratch-repo
#
# It needs nothing but git and push access. It pushes a handful of probe refs,
# checks they can be read back and that a plain clone ignores them, prints a
# verdict, and deletes them again.
#
# Exit status: 0 accepted, 1 rejected, 2 inconclusive (environment problem).
set -uo pipefail
URL=${1:?usage: gh-ref-probe.sh <repo-url>}
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

# NB: do NOT set GIT_CONFIG_GLOBAL here. Credential helpers, proxy settings and
# http.* auth live in the global config; replacing it makes every push fail
# with an indistinguishable 403 and the probe reports false negatives. Keep the
# ambient config and override only what matters, per invocation.
git init -q -b main "$W/r"; cd "$W/r"
git config user.name probe; git config user.email probe@example.com
git config commit.gpgsign false; git config push.negotiate false
echo probe > probe.txt; git add probe.txt; git commit -qm "ref-policy probe"
SHA=$(git rev-parse HEAD)

# Controls first. An ordinary branch and an ordinary tag: every forge takes
# both. If either fails the problem is the environment -- credentials, branch
# protection, a push proxy that only allows refs/heads/* -- and nothing below
# would say anything about the forge's ref policy. This is not hypothetical:
# it is exactly what made an earlier run of this report a false negative.
# Unique per run, and force-pushed: a leftover control ref from an earlier run
# that could not be deleted would otherwise fail with "fetch first" and be
# misread as an access problem.
TAG=zz-probe-$$-${RANDOM:-0}
echo "== controls (ordinary branch and tag) =="
CONTROLS_OK=1; LEFT=()
for c in "refs/heads/$TAG" "refs/tags/$TAG"; do
  if out=$(git push "$URL" "+$SHA:$c" 2>&1); then
    echo "  ok        $c"
    git push -q "$URL" ":$c" 2>/dev/null || LEFT+=("$c")
  else
    CONTROLS_OK=0
    printf '  FAILED    %s\n            %s\n' "$c" \
      "$(grep -iEm1 'rejected|error|denied|fatal' <<<"$out" | cut -c1-140)"
  fi
done
if [ "$CONTROLS_OK" = 0 ]; then
  cat <<'EOM'

VERDICT: INCONCLUSIVE.
  A plain branch or tag could not be pushed, so this says nothing about
  whether the forge accepts custom refs. Fix the access problem and re-run.
EOM
  exit 2
fi

REFS=(
  "refs/namespaces/$TAG/refs/heads/main"                                   # flat namespace
  "refs/namespaces/a/refs/namespaces/b/refs/namespaces/c/refs/heads/main"  # 3 deep
  "refs/namespaces/$TAG/HEAD"                                              # namespace HEAD
  "refs/namespaces/$TAG/refs/heads/git-annex"                              # annex branch
  "refs/bugs/$TAG"                                                         # git-bug style
  "refs/notes/$TAG"                                                        # notes
  "refs/artifacts/$TAG/main"                                               # arbitrary prefix
)

echo "== pushing custom refs =="
OK=(); BAD=0
for ref in "${REFS[@]}"; do
  if out=$(git push "$URL" "+$SHA:$ref" 2>&1) &&
     ! grep -qiE 'rejected|error:|denied|fatal' <<<"$out"; then
    printf '  ACCEPTED  %s\n' "$ref"; OK+=("$ref")
  else
    BAD=1
    printf '  REJECTED  %s\n            %s\n' "$ref" \
      "$(grep -iEm1 'rejected|error:|denied|fatal' <<<"$out" | cut -c1-140)"
  fi
done

echo "== can a client read them back? =="
ADV=$(git ls-remote "$URL" 2>/dev/null | grep -cE 'refs/(namespaces|bugs|artifacts|notes)/') || ADV=0
echo "  $ADV of ${#OK[@]} advertised by ls-remote"
FETCHED=no
if [ "${#OK[@]}" -gt 0 ]; then
  git init -q "$W/f" && git -C "$W/f" remote add origin "$URL"
  if git -C "$W/f" fetch -q origin \
       "+refs/namespaces/$TAG/refs/heads/*:refs/remotes/origin/*" 2>/dev/null &&
     [ -n "$(git -C "$W/f" for-each-ref refs/remotes/origin)" ]; then
    FETCHED=yes
  fi
  echo "  fetch of a namespaced ref by refspec: $FETCHED"
fi

echo "== does a plain 'git clone' drag them in? =="
CHEAP=yes
git clone -q "$URL" "$W/c" 2>/dev/null
if git -C "$W/c" for-each-ref --format='%(refname)' 2>/dev/null \
     | grep -qE 'refs/(namespaces|bugs|artifacts)/'; then
  CHEAP=no; echo "  YES -- the cheap-clone property is LOST"
else
  echo "  NO  -- a plain clone stays clean (this is the point)"
fi

echo "== cleanup =="
for ref in "${OK[@]}"; do
  if git push -q "$URL" ":$ref" 2>/dev/null; then echo "  deleted $ref"
  else LEFT+=("$ref"); echo "  COULD NOT DELETE $ref"; fi
done

echo
if [ "$BAD" = 0 ] && [ "$FETCHED" = yes ] && [ "$CHEAP" = yes ]; then
  echo "VERDICT: ACCEPTED -- the namespace layout works on this forge."
  echo "  Build the real thing with:"
  echo "    ./populate-demo-repo.sh <push-url> <repo-basename>"
  echo "  (default LAYOUT=namespaces; the target repo must be empty)"
  RC=0
elif [ "$BAD" = 1 ]; then
  echo "VERDICT: REJECTED -- this forge refuses some custom refs."
  echo "  Use the fallback: LAYOUT=branches ./populate-demo-repo.sh ..."
  echo "  Members then live on ordinary m/<namespace>/main branches, which"
  echo "  every forge takes and git submodule resolves natively, at the cost"
  echo "  of the members showing up in every clone."
  RC=1
else
  echo "VERDICT: PARTIAL -- refs were accepted but did not behave as needed"
  echo "  (read-back=$FETCHED, cheap-clone=$CHEAP). Read the output above."
  RC=1
fi
[ "${#LEFT[@]}" -gt 0 ] && {
  echo
  echo "NOTE: ${#LEFT[@]} probe ref(s) could not be deleted; remove them by hand:"
  printf '  git push %s :%s\n' "$URL" "${LEFT[@]}"
}
exit $RC
