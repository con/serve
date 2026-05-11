#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Yaroslav Halchenko <yaroslav.o.halchenko@dartmouth.edu>
# SPDX-License-Identifier: MIT
#
# NOTE: This script was drafted with substantial assistance from a generative
# AI assistant (Anthropic Claude) in iterative collaboration with the author.
# It has been test-driven; inspect the source before relying on it for
# anything load-bearing.
"""
git-history-to-wacz.py -- export per-commit web captures from a git repo
into a single WACZ file that ReplayWeb.page can replay as a multi-snapshot
archive.

Walks commits that touch a given path (e.g. ``site/``), and for each commit
emits one WARC ``response`` record per file under that path with:

- ``WARC-Target-URI``  reconstructed from file path (top-level dir is
  treated as host if it contains a dot, else falls back to ``--site``)
- ``WARC-Date``        = commit's author date (the IA capture timestamp,
  via the split-identity convention from wayback-to-datalad.sh)
- payload              = the file's blob content at that commit, wrapped in
  a synthetic HTTP/1.1 200 response with a guessed Content-Type

Then bundles the resulting WARC into a WACZ via ``py-wacz``.

Usage
-----
    git-history-to-wacz.py \
        --repo PATH-TO-GIT-REPO \
        --branch BRANCH \
        --site HOSTNAME \
        --tree-path site \
        --output OUT.wacz

Requires: ``warcio``, ``wacz`` Python packages; ``git`` on PATH.
"""

from __future__ import annotations

import argparse
import io
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import OrderedDict
from datetime import datetime, timezone
from email.utils import format_datetime
from pathlib import Path
from typing import Iterable

_TITLE_RE = re.compile(rb"<title[^>]*>([^<]+)</title>", re.IGNORECASE)


def extract_title(body: bytes) -> str | None:
    """Return the page title from an HTML body, or None if not found."""
    m = _TITLE_RE.search(body)
    if not m:
        return None
    try:
        title = m.group(1).decode("utf-8", errors="replace").strip()
    except Exception:
        return None
    return title or None

from warcio.warcwriter import WARCWriter
from warcio.statusandheaders import StatusAndHeaders


def run_git(repo: Path, *args: str) -> str:
    """Run a git command in *repo* and return its stdout (decoded, stripped)."""
    return subprocess.check_output(
        ["git", "-C", str(repo), *args],
        text=True,
        stderr=subprocess.PIPE,
    ).rstrip("\n")


def commits_touching(repo: Path, branch: str, tree_path: str) -> list[str]:
    """Return commit SHAs on *branch* that touched *tree_path*, oldest first."""
    out = run_git(repo, "log", "--reverse", "--pretty=%H", branch, "--", tree_path)
    return [line for line in out.splitlines() if line]


def list_files_at(repo: Path, sha: str, tree_path: str) -> list[str]:
    """List all blob paths under *tree_path* at commit *sha*."""
    out = run_git(repo, "ls-tree", "-r", "--name-only", sha, "--", tree_path)
    return [line for line in out.splitlines() if line]


def read_blob(repo: Path, sha: str, path: str) -> bytes:
    """Return raw bytes of *path* at commit *sha*."""
    return subprocess.check_output(
        ["git", "-C", str(repo), "show", f"{sha}:{path}"],
    )


def commit_author_date(repo: Path, sha: str) -> datetime:
    """Return commit *sha*'s author date as an aware datetime."""
    iso = run_git(repo, "show", "-s", "--format=%aI", sha)
    return datetime.fromisoformat(iso).astimezone(timezone.utc)


# File extensions that signal "this is a file, not a hostname". Paths
# whose first segment matches one of these are mapped under the default
# host even if the segment also contains a dot (so ``index.html`` is a
# file, not a hostname).
_FILE_EXTS = (
    ".html", ".htm", ".css", ".js", ".json", ".xml", ".txt", ".md",
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".webp", ".avif",
    ".pdf", ".zip", ".gz", ".tar", ".woff", ".woff2", ".ttf", ".otf",
    ".eot", ".mp3", ".mp4", ".webm", ".ogg", ".wav", ".flv", ".mov",
)


def _looks_like_host(segment: str) -> bool:
    """Heuristic: does this path segment look like a hostname?

    Hostnames need at least one dot, must not end in a known web file
    extension, and must not start with a dot. Single-word names go
    through unchanged (``theme/css/site.css`` keeps ``theme`` as a
    plain directory under the default host).
    """
    if "." not in segment or segment.startswith("."):
        return False
    return not segment.lower().endswith(_FILE_EXTS)


def path_to_url(rel_path: str, default_host: str) -> str:
    """Map a path inside the captured tree to its original URL.

    wayback-archive lays out cross-domain assets under a subdirectory
    named after the host (e.g. ``fonts.googleapis.com/css-...css``).
    Detect that and use it as the URL host; otherwise fall back to
    *default_host*.
    """
    parts = rel_path.split("/")
    if parts and _looks_like_host(parts[0]) and parts[0] != default_host:
        host = parts[0]
        path = "/" + "/".join(parts[1:]) if len(parts) > 1 else "/"
    else:
        host = default_host
        path = "/" + rel_path
    if path.endswith("/index.html"):
        # Wayback-Archive saves the root page as ``index.html``, but the
        # original URL is the directory path ``/``. Map to that so
        # replay of ``https://<host>/`` resolves the entry page.
        return f"https://{host}{path[:-len('index.html')]}"
    return f"https://{host}{path}"


def guess_content_type(rel_path: str) -> str:
    """Guess a Content-Type header value from the path's extension."""
    ctype, _ = mimetypes.guess_type(rel_path)
    if ctype is None:
        # Anything we can't guess we serve as octet-stream; ReplayWeb will
        # still play it, browsers will sniff for HTML on the entry pages.
        return "application/octet-stream"
    if ctype.startswith("text/") and ctype != "text/html":
        return f"{ctype}; charset=utf-8"
    return ctype


def write_warc_for_commit(
    writer: WARCWriter,
    repo: Path,
    sha: str,
    tree_path: str,
    site: str,
    pages_index: list[dict],
    seen_urls_by_ts: set[tuple[str, str]],
) -> int:
    """Write WARC response records for every file under *tree_path* at *sha*.

    Returns the number of records written. Populates *pages_index* with
    entry-page descriptors (one per HTML root page per commit) and
    *seen_urls_by_ts* with ``(url, timestamp)`` tuples to prevent
    duplicates within a single commit.
    """
    when = commit_author_date(repo, sha)
    warc_date = when.strftime("%Y-%m-%dT%H:%M:%SZ")
    http_date = format_datetime(when, usegmt=True)
    written = 0
    for rel_path in list_files_at(repo, sha, tree_path):
        # Strip the tree_path prefix; rel_path inside the WACZ should be
        # relative to the captured site, not to the git repo.
        if not rel_path.startswith(tree_path.rstrip("/") + "/"):
            continue
        site_rel = rel_path[len(tree_path.rstrip("/")) + 1:]
        if not site_rel:
            continue
        url = path_to_url(site_rel, site)
        key = (url, warc_date)
        if key in seen_urls_by_ts:
            continue
        seen_urls_by_ts.add(key)

        body = read_blob(repo, sha, rel_path)
        ctype = guess_content_type(site_rel)
        http_headers = StatusAndHeaders(
            "200 OK",
            [
                ("Content-Type", ctype),
                ("Content-Length", str(len(body))),
                ("Date", http_date),
            ],
            protocol="HTTP/1.1",
        )
        warc_headers = OrderedDict(
            [
                ("WARC-Date", warc_date),
                # Keep payload digest deterministic so revisits could later
                # be added without breaking byte-identity.
            ]
        )
        record = writer.create_warc_record(
            uri=url,
            record_type="response",
            payload=io.BytesIO(body),
            length=len(body),
            http_headers=http_headers,
            warc_headers_dict=warc_headers,
        )
        writer.write_record(record)
        written += 1

        # Surface every captured HTML page (not just index.html) in
        # pages.jsonl so ReplayWeb.page's Pages view and search can
        # find subpages like ``whoweare.html``. Title is the actual
        # ``<title>`` from the snapshot when available; otherwise a
        # generated label keyed on URL + capture time.
        if ctype.startswith("text/html"):
            html_title = extract_title(body)
            label = html_title or f"{site} {site_rel} @ {warc_date[:10]}"
            pages_index.append(
                {
                    "url": url,
                    "ts": warc_date,
                    "title": label,
                }
            )
    return written


def build_warc(
    repo: Path,
    branch: str,
    tree_path: str,
    site: str,
    output_warc: Path,
) -> tuple[int, list[dict]]:
    """Materialize a single .warc.gz file from *branch*'s history.

    Returns ``(record_count, pages_index)``.
    """
    pages_index: list[dict] = []
    seen: set[tuple[str, str]] = set()
    record_count = 0
    shas = commits_touching(repo, branch, tree_path)
    if not shas:
        sys.exit(
            f"No commits on {branch} touched {tree_path!r}; nothing to export."
        )
    print(f"Exporting {len(shas)} commits from {branch} into {output_warc}")
    with output_warc.open("wb") as fh:
        writer = WARCWriter(fh, gzip=True)
        for n, sha in enumerate(shas, 1):
            count = write_warc_for_commit(
                writer, repo, sha, tree_path, site, pages_index, seen
            )
            record_count += count
            print(f"  [{n}/{len(shas)}] {sha[:7]}: {count} records")
    return record_count, pages_index


def build_wacz(
    warc: Path,
    pages_index: list[dict],
    output: Path,
    title: str | None = None,
) -> None:
    """Bundle *warc* into *output* (a .wacz) with the given entry pages.

    The most recent entry page becomes the WACZ's ``mainPageURL`` /
    ``mainPageDate`` (via ``wacz create --url --date``). Without this,
    ReplayWeb.page's "open WACZ source" flow stalls on the loading
    spinner because it cannot auto-resolve a canonical entry, even
    though deep-link replay (``#url=...&ts=...``) still works.
    """
    with tempfile.TemporaryDirectory() as tmp:
        pages_path = Path(tmp) / "pages.jsonl"
        with pages_path.open("w", encoding="utf-8") as ph:
            ph.write('{"format": "json-pages-1.0", "id": "pages", "title": "Pages"}\n')
            for page in pages_index:
                import json

                ph.write(json.dumps(page) + "\n")
        cmd = [
            "wacz",
            "create",
            "-f",
            str(warc),
            "-o",
            str(output),
            "--pages",
            str(pages_path),
        ]
        if pages_index:
            main = max(pages_index, key=lambda p: p["ts"])
            cmd += [
                "--url", main["url"],
                "--date", main["ts"],
            ]
            if title:
                cmd += ["--title", title]
        print("Running:", " ".join(cmd))
        subprocess.check_call(cmd)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--repo", required=True, type=Path, help="Path to git repo")
    p.add_argument("--branch", default="HEAD", help="Branch / ref to walk (default: HEAD)")
    p.add_argument(
        "--tree-path",
        default="site",
        help="Path inside the repo whose history we export (default: site)",
    )
    p.add_argument(
        "--site",
        required=True,
        help="Default hostname for files whose top-level dir isn't a host",
    )
    p.add_argument(
        "--output",
        required=True,
        type=Path,
        help="Output .wacz file path",
    )
    p.add_argument(
        "--keep-warc",
        action="store_true",
        help="Keep the intermediate .warc.gz next to the .wacz",
    )
    args = p.parse_args(argv)

    if shutil.which("git") is None:
        sys.exit("git not found on PATH")
    if shutil.which("wacz") is None:
        sys.exit("wacz CLI not found on PATH (pip install wacz)")

    output_wacz = args.output.resolve()
    if args.keep_warc:
        warc_path = output_wacz.with_suffix(".warc.gz")
        ctx = None
    else:
        ctx = tempfile.TemporaryDirectory()
        warc_path = Path(ctx.name) / "history.warc.gz"
    try:
        records, pages_index = build_warc(
            args.repo.resolve(), args.branch, args.tree_path, args.site, warc_path
        )
        if records == 0:
            sys.exit("No records written; nothing to package.")
        build_wacz(
            warc_path,
            pages_index,
            output_wacz,
            title=f"{args.site} -- captured history",
        )
        size = output_wacz.stat().st_size
        print(
            f"\nWACZ written: {output_wacz} "
            f"({size / 1024:.1f} KB, {records} records, "
            f"{len(pages_index)} entry pages)"
        )
    finally:
        if ctx is not None:
            ctx.cleanup()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
