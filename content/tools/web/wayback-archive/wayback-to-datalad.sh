#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Yaroslav Halchenko <yaroslav.o.halchenko@dartmouth.edu>
# SPDX-License-Identifier: MIT
#
# NOTE: This script was drafted with substantial assistance from a generative
# AI assistant (Anthropic Claude) in iterative collaboration with the author.
# It has been test-driven against a real DataLad dataset, but inspect the
# source and the recorded `datalad run` commands before relying on it for
# anything load-bearing.
#
# wayback-to-datalad.sh -- archive a site's full Wayback history into a
# DataLad dataset, one commit per capture.
#
# For each timestamp returned by the Internet Archive's CDX Server API,
# wipes the working tree and re-runs Wayback-Archive under `datalad run`,
# so each snapshot lands as a `[DATALAD RUNCMD]` commit recording the
# exact invocation used to produce it. Commits are backdated to the
# capture time, so `git log` reads as a timeline of the site.
#
# Usage:
#   wayback-to-datalad.sh <site> [<dataset-dir>] [<collapse>] [<from>] [<to>] [<limit>]
#
# Args:
#   site         Hostname (without scheme), e.g. neuro.debian.net
#   dataset-dir  DataLad dataset to populate (created if absent).
#                Default: ./wayback-<site>
#   collapse     CDX collapse spec; controls density.
#                  timestamp:4 = yearly, :6 = monthly, :8 = daily,
#                  empty = every capture. Default: timestamp:6 (monthly).
#   from         CDX 'from' (YYYY[MM[DD...]]). Default: empty (no lower bound).
#   to           CDX 'to'.                       Default: empty (no upper bound).
#   limit        Max number of timestamps to process. Default: empty (all).
#
# Env knobs:
#   MAX_FILES_PER_SNAPSHOT  Cap files per snapshot (passes through as
#                           Wayback-Archive's MAX_FILES). Useful for smoke
#                           tests; unset for full archival.
#   SNAPSHOT_TIMEOUT        Seconds to wait per snapshot before killing
#                           Wayback-Archive and skipping. Default: 600.
#                           Wayback's per-request timeout (15s) does not
#                           cover slow-trickle responses; older snapshots
#                           with many link-rotted assets each consume
#                           ~7s of fallback retries, so the outer budget
#                           must be generous.
#   TREE                    Subdir within the dataset that holds the
#                           recovered site. Default: site
#
# Exit codes:
#   0 on success (some snapshots may be skipped); 1 on usage / setup error.
set -euo pipefail

SITE="${1:?usage: $0 <site> [dataset-dir] [collapse] [from] [to] [limit]}"
DSDIR="${2:-./wayback-${SITE}}"
COLLAPSE="${3-timestamp:6}"
FROM="${4-}"
TO="${5-}"
LIMIT="${6-}"
TREE="${TREE:-site}"
SNAPSHOT_TIMEOUT="${SNAPSHOT_TIMEOUT:-600}"

command -v datalad >/dev/null || { echo "datalad not found in PATH" >&2; exit 1; }
command -v jq      >/dev/null || { echo "jq not found in PATH"      >&2; exit 1; }
command -v timeout >/dev/null || { echo "timeout(1) not found"      >&2; exit 1; }
python3 -c 'import wayback_archive' 2>/dev/null \
    || { echo "wayback_archive not importable; pip install wayback-archive" >&2; exit 1; }

# 1) Create / reuse the DataLad dataset. -c text2git keeps HTML/CSS/JS in
#    git and only annexes binaries, which is exactly the right mix for
#    a recovered web tree.
if [[ ! -d "$DSDIR/.git" ]]; then
    datalad create -c text2git "$DSDIR"
fi
DSDIR="$(cd "$DSDIR" && pwd)"

# 2) Query CDX for the list of capture timestamps. Filter to HTTP 200 +
#    text/html (we only want successful HTML captures of the root page).
CDX_URL="https://web.archive.org/cdx/search/cdx"
CDX_URL+="?url=${SITE}/&output=json&fl=timestamp,original"
CDX_URL+="&filter=statuscode:200&filter=mimetype:text/html"
[[ -n "$COLLAPSE" ]] && CDX_URL+="&collapse=${COLLAPSE}"
[[ -n "$FROM"     ]] && CDX_URL+="&from=${FROM}"
[[ -n "$TO"       ]] && CDX_URL+="&to=${TO}"
[[ -n "$LIMIT"    ]] && CDX_URL+="&limit=${LIMIT}"

echo "CDX query: $CDX_URL"
# Internet Archive's CDX endpoint is flaky -- 503s and bare timeouts are
# routine. Retry on transient failure rather than silently treating an
# error as "no captures found".
cdx_json="$(mktemp -t wayback-cdx.XXXXXX.json)"
trap 'rm -f "$cdx_json"' EXIT
attempt=0
until curl -fsSL --max-time 180 -o "$cdx_json" "$CDX_URL"; do
    attempt=$((attempt + 1))
    if (( attempt >= 5 )); then
        echo "CDX query failed after ${attempt} attempts; giving up" >&2
        exit 1
    fi
    backoff=$(( attempt * 30 ))
    echo "CDX query failed (attempt ${attempt}); retrying in ${backoff}s" >&2
    sleep "$backoff"
done

# CDX JSON is `[[header],[row],[row]...]`. An empty result is `[]` or just
# the header row. jq -e differentiates "valid JSON, zero data rows" from
# "malformed response" -- we only proceed on the first.
if ! jq -e 'type == "array"' "$cdx_json" >/dev/null; then
    echo "CDX returned non-array JSON; aborting" >&2
    head -c 300 "$cdx_json" >&2; echo >&2
    exit 1
fi
mapfile -t ROWS < <(jq -r '.[1:][] | "\(.[0])\t\(.[1])"' "$cdx_json")
echo "Got ${#ROWS[@]} snapshot(s) to process"
(( ${#ROWS[@]} > 0 )) || { echo "no snapshots from CDX; nothing to do" >&2; exit 0; }

# 3) For each snapshot, run a self-contained datalad run that wipes the
#    tree and repopulates it from that timestamp. Backdate the resulting
#    commit to the actual capture time so `git log --date=iso` reads as
#    a real timeline.
declare -i ok=0 unchanged=0 skipped=0
for row in "${ROWS[@]}"; do
    ts="${row%%$'\t'*}"
    orig="${row#*$'\t'}"
    iso="${ts:0:4}-${ts:4:2}-${ts:6:2}T${ts:8:2}:${ts:10:2}:${ts:12:2}Z"

    echo
    echo "=== ${iso}  (${ts})  ${orig}  ==="

    wb_url="https://web.archive.org/web/${ts}/${orig}"
    msg="snapshot ${iso} of ${SITE}"
    max_files_env=""
    [[ -n "${MAX_FILES_PER_SNAPSHOT:-}" ]] \
        && max_files_env="MAX_FILES=${MAX_FILES_PER_SNAPSHOT} "

    head_before="$(git -C "$DSDIR" rev-parse HEAD)"

    # The whole per-snapshot recipe in ONE datalad run. Wiping the tree is
    # part of the recorded command (so the provenance is self-contained),
    # and `timeout` enforces a per-snapshot wall-clock budget so a single
    # slow Wayback response can't stall the entire timeline.
    # --explicit: only the listed --output paths are expected to change.
    # --kill-after sends SIGKILL if SIGTERM is ignored.
    if GIT_AUTHOR_DATE="$iso" GIT_COMMITTER_DATE="$iso" \
       datalad -C "$DSDIR" run \
            -m "$msg" \
            --explicit \
            --output "$TREE" \
            -- \
            bash -c "rm -rf '$TREE' && mkdir -p '$TREE' && \
                ${max_files_env}WAYBACK_URL='$wb_url' OUTPUT_DIR='$TREE' \
                timeout --kill-after=10 ${SNAPSHOT_TIMEOUT} \
                python3 -m wayback_archive.cli"
    then
        head_after="$(git -C "$DSDIR" rev-parse HEAD)"
        files_in_tree=$(find "$DSDIR/$TREE" -type f -o -type l 2>/dev/null | wc -l)
        if [[ "$head_after" == "$head_before" ]]; then
            # datalad made no commit. Two distinct cases:
            #   - tree non-empty -> recovery succeeded but content is
            #     byte-identical to the previous snapshot (site stable).
            #   - tree empty -> wayback retrieved nothing.
            if (( files_in_tree > 0 )); then
                echo "unchanged ${ts}: ${files_in_tree} files, byte-identical to previous snapshot" >&2
                unchanged+=1
            else
                echo "skip ${ts}: wayback returned no files (no commit made)" >&2
                skipped+=1
            fi
        elif (( files_in_tree == 0 )); then
            # Tree is empty after the run; the wipe-and-replace destroyed
            # the prior snapshot's content without recovering anything.
            # Roll back so git log only contains real captures.
            echo "skip ${ts}: wayback returned no files (rolling back wipe)" >&2
            git -C "$DSDIR" reset --hard "$head_before"
            skipped+=1
        else
            ok+=1
        fi
    else
        # timeout returns 124 (SIGTERM took effect) or 137 (SIGKILL fallback).
        rc=$?
        case $rc in
            124|137) reason="timed out after ${SNAPSHOT_TIMEOUT}s" ;;
            *)       reason="failed (exit $rc)"                   ;;
        esac
        echo "skip ${ts}: wayback_archive ${reason}" >&2
        skipped+=1
        # Restore the tree to whatever HEAD was before this attempt, so the
        # next snapshot starts from a clean state regardless of how datalad
        # left things on the failure path.
        git -C "$DSDIR" reset --hard "$head_before" -- 2>/dev/null \
            || git -C "$DSDIR" reset --hard "$head_before"
        git -C "$DSDIR" clean -fdq -- "$TREE" 2>/dev/null || true
    fi
done

echo
echo "=== done: ok=${ok} unchanged=${unchanged} skipped=${skipped} ==="
echo "Browse the timeline:"
echo "  git -C '$DSDIR' log --date=iso --pretty='%h %ad %s'"
