---
title: "Web"
date: 2026-02-12
description: "Tools for archiving web pages, sites, and online resources"
cascade:
  showEdit: true
---

The web is the connective tissue of modern research --
project homepages, documentation sites, blog posts, institutional pages,
and online supplements all live at URLs that may not persist.

Link rot is well-documented:
studies consistently find that a significant fraction of URLs cited in
published papers become unreachable within a few years.

This section catalogs tools for capturing web content
and archiving it into git or git-annex repositories.

## Approaches

**Full-site archival** -- Tools like [ArchiveBox](archivebox/) and
[HTTrack](httrack/) crawl entire websites and preserve them
as self-contained archives (WARC, static HTML, or single-file snapshots).

**Single-page capture** -- [SingleFile](singlefile/) captures individual pages
as self-contained HTML files with all resources inlined,
ideal for preserving specific pages or articles.

**Headless crawling** -- [Browsertrix](browsertrix/) uses a headless browser
to capture JavaScript-heavy sites that static crawlers cannot handle,
producing standards-compliant WARC archives.

## Integration with git-annex

Web archives can be large (especially WARC files from full-site crawls),
making git-annex the natural storage backend.
The typical pattern is:

1. Run the archival tool to capture content locally
2. Import the output into a git-annex repository
3. Use `git annex addurl` to record the original URL as a retrievable source
4. Replicate to special remotes for backup

For simpler needs, `git annex addurl` and `datalad download-url`
can directly archive individual URLs without an intermediate tool.
