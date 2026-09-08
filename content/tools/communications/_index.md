---
title: "Communications"
date: 2026-02-12
description: "Tools for archiving messaging platforms -- Slack, Telegram, Matrix, Mattermost, and email"
cascade:
  showEdit: true
---

Research conversations happen across a fragmented landscape of messaging platforms.
Slack workspaces expire, Telegram groups lose history,
and email threads scatter across individual inboxes.

This section catalogs tools that extract conversations from these platforms
and archive them into git-annex/DataLad repositories,
preserving both the content and its structure (threads, reactions, attachments, metadata).

## Platforms Covered

**Slack** -- Corporate messaging widely used in research labs and collaborations.
Free workspaces have message retention limits, making archival urgent.
See [slackdump](slackdump/) and [wayslack2](wayslack2/) for different approaches.

**Telegram** -- Popular for informal research communities and conference groups.
See [Telegram Archive](telegram-archive/) and [tg-archive](tg-archive/).

**Matrix** -- Federated, open-source messaging used by several open-source and
research communities.
See [con/versations](conversations/) for cron-friendly plain-text archival,
and [matrix-archive](matrix-archive/) for JSON export with media.

**Mattermost** -- Self-hosted team chat common in institutions that need on-premises
messaging.
See [Mattermost Export](mattermost-export/) for bulk export approaches.

**Email** -- The oldest and most universal research communication medium.
Tools like offlineimap and mbsync can synchronize mailboxes locally
for git-annex archival.
See [msgvault](msgvault/) for a local, searchable archive of email
(Gmail, Outlook, MBOX, PST) together with chat, calendar, and contacts.

**Multi-platform** -- [msgvault](msgvault/) also covers Teams, Discord, Slack,
and Beeper-bridged messengers in one SQLite store with full-text and semantic search,
though without git-annex integration.

## Common Patterns

Most communication archival tools follow a similar workflow:

1. Authenticate with the platform API (token, OAuth, or session cookie)
2. Export messages, threads, and attachments in a structured format (JSON, YAML, mbox)
3. Import the exported data into a git or git-annex repository
4. Optionally render to static HTML for browsing

The key differentiator is **integration depth** --
some tools write plain files that drop straight into a git or git-annex repository,
while others keep their own database and need an export or snapshot step.
