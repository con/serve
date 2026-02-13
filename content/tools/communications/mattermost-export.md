---
title: "Mattermost Export"
date: 2026-02-12
description: "Mattermost bulk export via mmctl for archiving team messages, channels, and files to JSONL"
summary: "Built-in Mattermost export tooling using mmctl to produce JSONL archives of teams, channels, users, and posts, suitable for long-term preservation in git-annex."
categories: ["Communications"]
tags: ["mattermost", "export", "jsonl", "mmctl", "bulk-export"]
media_types: ["mattermost"]
integrations: ["external"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/mattermost/mattermost"
  homepage: "https://docs.mattermost.com/manage/bulk-export-tool.html"
  issues: "https://github.com/mattermost/mattermost/issues"
  language: "Go"
  license: "AGPL-3.0"
  maturity: "stable"
  last_verified: "2026-02"
---

Mattermost provides a built-in bulk export tool, accessible through the
`mmctl` command-line interface, that exports workspace data -- teams,
channels, users, and posts -- to JSONL (JSON Lines) format. This is the
officially supported method for extracting data from Mattermost instances
for archival, migration, or backup purposes.

## Key Features

- **Official tooling**: Part of the Mattermost core distribution; `mmctl` is
  the supported CLI for server administration including data export.
- **JSONL output**: Produces JSON Lines format where each line is a
  self-contained JSON object, making output streamable and easy to process
  incrementally.
- **Comprehensive data coverage**: Exports teams, channels (public and
  private), users, and posts. File attachments can be included with the
  `--attachments` flag.
- **Server-side execution**: Export jobs run on the Mattermost server,
  ensuring data consistency and access to all content.
- **Job management**: Export operations run as background jobs with status
  monitoring via `mmctl export job show`.

## Export Commands

```bash
# Create an export (without attachments)
mmctl export create

# Create an export with file attachments
mmctl export create --attachments

# List available exports
mmctl export list

# Check export job status
mmctl export job show <job-id>

# Download a completed export
mmctl export download <export-name> --output mattermost-export.zip
```

## Output Format

The export produces a JSONL file where each line is a JSON object. The file
begins with a version object followed by team, channel, user, and post
records:

```jsonl
{"type":"version","version":1}
{"type":"team","team":{"name":"myteam","display_name":"My Team",...}}
{"type":"channel","channel":{"team":"myteam","name":"general","type":"O",...}}
{"type":"user","user":{"username":"john.doe","email":"john@example.com",...}}
{"type":"post","post":{"team":"myteam","channel":"general","user":"john.doe","message":"Hello world","create_at":1706000000000,...}}
```

When exported with `--attachments`, file attachments are included in the
export archive alongside the JSONL data file.

## git-annex Integration

Mattermost exports require manual import into git-annex since the export
runs server-side and produces a downloadable archive. A recommended workflow:

```bash
# Create a DataLad dataset for Mattermost archives
datalad create mattermost-archive
cd mattermost-archive

# Download the export
mmctl export download latest-export --output export.zip
unzip export.zip -d export/

# Separate text data from binary attachments
# JSONL files are small and diffable -- keep in git
# Attachments go into annex
echo '*.jsonl annex.largefiles=nothing' >> .gitattributes
echo 'data/attachments/** annex.largefiles=anything' >> .gitattributes

# Save with DataLad
datalad save -m "Mattermost export $(date -I)"
```

For periodic archival, wrap the download and extraction in `datalad run`:

```bash
datalad run -m "Mattermost periodic export import" \
  --output export/ \
  "mmctl export download latest-export --output export.zip && unzip -o export.zip -d export/"
```

## API-Based Alternatives

For more granular control or when `mmctl` bulk export is not available (e.g.,
Mattermost Cloud without admin access), the Mattermost REST API can be used
to extract data programmatically:

```bash
# List channels
curl -H "Authorization: Bearer $TOKEN" \
  https://mattermost.example.com/api/v4/teams/$TEAM_ID/channels

# Get posts from a channel
curl -H "Authorization: Bearer $TOKEN" \
  https://mattermost.example.com/api/v4/channels/$CHANNEL_ID/posts

# Get file attachments
curl -H "Authorization: Bearer $TOKEN" \
  https://mattermost.example.com/api/v4/files/$FILE_ID
```

API-based extraction allows incremental archival (fetching only new posts
since a timestamp) and can be scripted for cron-based operation. The JSON
responses have the same structured format suitable for git storage.

## Current Limitations

- Export requires server administrator access (System Admin role).
- Deleted messages and objects are not included in exports.
- Some data types (webhooks, bot messages, custom integrations) may not
  be fully captured.
- No built-in incremental export -- each export captures the full dataset.
  For incremental archival, the REST API approach is more appropriate.

## AI Readiness

**ai-ready** -- The JSONL export format is fully structured with typed fields
for every record. Each line is an independent JSON object with clear type
discrimination (`version`, `team`, `channel`, `user`, `post`), making it
trivial to parse and filter. Post objects contain the full message text,
timestamps, channel context, and user attribution -- all directly consumable
by language models for summarization, search indexing, and knowledge
extraction. File attachments referenced in posts require separate content
extraction.

## See Also

- [slackdump]({{< ref "slackdump" >}}) -- Similar export capability for Slack
  workspaces, with the advantage of not requiring admin privileges.
