---
title: "Cloud Storage"
date: 2026-02-12
description: "Tools for archiving cloud-hosted files from Google Drive, Dropbox, S3, and 70+ providers"
cascade:
  showEdit: true
---

Research files accumulate across cloud storage providers --
Google Drive folders shared by collaborators,
Dropbox directories synced from lab instruments,
S3 buckets holding processed datasets,
and OneDrive directories mandated by institutional IT.

These files are rarely under version control.
When sharing permissions change, storage quotas are exceeded,
or accounts are deprovisioned, the data can vanish.

This section catalogs tools for pulling cloud-hosted files
into git-annex repositories where they are content-addressed,
version-tracked, and replicated to locations you control.

## The rclone Advantage

[rclone](rclone/) is the central tool here.
It supports 70+ cloud storage providers with a unified interface
and, critically, it serves a **dual role** in the con/serve architecture:

1. **Ingestion** -- pull files from any supported provider into a local directory
   for git-annex import
2. **Distribution** -- act as a git-annex special remote so that archived content
   can be pushed *back* to cloud storage for backup, sharing, or compliance

This bidirectionality makes rclone the universal adapter
between the git-annex vault and the cloud storage ecosystem.

## Integration Patterns

The typical workflow for cloud storage archival:

1. Configure rclone with credentials for the cloud provider
2. Sync or copy files to a local working directory
3. Import into git-annex using `git annex import` or DataLad commands
4. Optionally configure the same rclone remote as a git-annex special remote
   for outbound replication

For providers with REST APIs (S3, Google Cloud Storage, Azure Blob),
git-annex also has native special remote implementations
that can be used without rclone.
