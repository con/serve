# con/serve Implementation Plan

## Context

This project creates a comprehensive knowledge base website cataloging tools and approaches for archiving ALL digital research artifacts into git/git-annex/DataLad repositories. It extends YODA/STAMPED principles beyond code and data to encompass communications (Slack, Telegram), media (YouTube, Zoom), code artifacts (GitHub issues, PRs), AI coding sessions, and infrastructure for self-hosting. The name "con/serve" captures both conservation and serving to AIs/knowledge bases.

The working directory (`/home/yoh/doc/papers.withothers/2026-data-hoarder`) is an existing DataLad dataset (has `.datalad/`, `.git/`, `.noannex`). We will build the Hugo site directly within this repo.

We will share this repository under https://github.com/con/serve and serve website from gh_pages there.

## Step 1: Install Hugo and Initialize Site

Use `uv` and `uv pip` where feasible for installation of necessary components.

- Install Hugo via pip under uv: `uv venv && source .venv/bin/activate && uv pip install hugo`
- Verify: `hugo version`
- Initialize Hugo site in the current directory (not `hugo new site` which creates a subdirectory - instead manually create the structure since this is an existing git repo)
- Install Congo theme via git submodule (preferred over Hugo modules since this is a DataLad/git-annex repo where submodules are natural):
  ```
  git submodule add -b stable https://github.com/jpanther/congo.git themes/congo
  ```

## Step 2: Configure Hugo with Congo Theme

Create `config/_default/` directory structure with these files:

- **`config/_default/hugo.toml`** - Base config: `theme = "congo"`, baseURL (initially for GitHub Pages), title "con/serve", taxonomies
- **`config/_default/languages.en.toml`** - English language settings, site title/description
- **`config/_default/markup.toml`** - Markdown rendering settings (goldmark, table of contents)
- **`config/_default/menus.en.toml`** - Navigation: Tools, Infrastructure, AI Sessions, About
- **`config/_default/params.toml`** - Congo parameters: color scheme, homepage layout, article appearance, taxonomy display settings

### Custom Taxonomies

Define in `hugo.toml`:
```toml
[taxonomies]
  category = "categories"        # Communications, Media, Code, AI Sessions, Infrastructure, Web
  tag = "tags"                   # free-form tags
  media_type = "media_types"     # slack, telegram, email, youtube, zoom, github-issues, etc.
  integration = "integrations"   # native-datalad, git-annex, git-only, external
  ai_readiness = "ai_readiness"  # ai-ready, ai-partial, ai-manual
```

## Step 3: Create Content Structure

```
content/
  _index.md                    # Homepage - vision statement, YODA/STAMPED context
  tools/
    _index.md                  # Tools overview page
    communications/
      _index.md                # Section index
      slackdump.md             # rusq/slackdump - Slack archival
      wayslack2.md             # datalad-based Slack archival
      telegram-archive.md      # GeiserX/Telegram-Archive
      tg-archive.md            # knadh/tg-archive
    media/
      _index.md
      annextube.md             # con/annextube - YouTube (PROMINENT)
      yt-dlp.md                # Basic yt-dlp + git-annex import
      gallery-dl.md            # Image gallery archival
      zoom-archival.md         # Zoom recording approaches
    code-artifacts/
      _index.md
      git-bug.md               # Distributed bug tracker with bridges
      github-backup.md         # josegonzalez/python-github-backup
      gh-discussions-export.md # GitHub discussions export
      gh-md.md                 # GitHub markdown backup
      datalad-crawler.md       # DataLad web resource crawler
    web/
      _index.md
      archivebox.md            # ArchiveBox - self-hosted web archiving
      singlefile.md            # SingleFile browser extension
      browsertrix.md           # Browsertrix headless crawler
      httrack.md               # HTTrack website copier
    ai-sessions/
      _index.md                # AI session archival overview
      entire-io.md             # Entire.io - git-native AI session archival
      cctrace.md               # cctrace conversation capture
      specstory.md             # SpecStory - VS Code extension
      claude-code-hooks.md     # Claude Code hooks (PreCompact/Stop/SessionEnd)
      ccexport.md              # ccexport - Claude Code transcript export
  infrastructure/
    _index.md                  # Infrastructure overview
    forgejo-aneksajo.md        # Forgejo fork with git-annex support
    hedgedoc.md                # Collaborative documentation
    pyinfra.md                 # Python infrastructure orchestration
    lab-in-a-box.md            # Full lab deployment (liab-deployments)
    datalad-hub.md             # DataLad Hub hosting service
  about/
    _index.md                  # Project vision, STAMPED principles, Frozen Frontiers
    contributing.md            # How to contribute new tool entries
```

### Content Front Matter Template

Each tool page will use this front matter pattern:
```yaml
---
title: "Tool Name"
date: 2026-02-12
description: "One-line description"
summary: "Brief summary for listing pages"
categories: ["Communications"]
tags: ["slack", "export", "json"]
media_types: ["slack"]
integrations: ["git-annex"]
ai_readiness: ["ai-ready"]
params:
  repo: "https://github.com/org/repo"
  language: "Go"
  license: "GPL-3.0"
  maturity: "stable"        # stable, beta, alpha, concept
  last_verified: "2026-02"
---
```

## Step 4: Write Content Pages

### Priority content (write fully):
1. **Homepage** (`_index.md`) - Vision: extending YODA to all digital artifacts, STAMPED framework, "Frozen Frontiers" concept
2. **annextube.md** - Detailed coverage as the flagship YouTube archival tool (from ~/proj/annextube)
3. **entire-io.md** - AI session archival with shadow branches, metadata branch, attribution tracking
4. **forgejo-aneksajo.md** - Self-hosted git-annex hosting, DataLad Hub foundation
5. **lab-in-a-box.md** - pyinfra-based deployment of complete research infrastructure to "con/serve" to

### Standard content (write with key details):
- All other tool pages with description, features, installation, git-annex/DataLad integration notes, AI readiness assessment

### Integration level definitions:
- **native-datalad**: Direct DataLad integration or plugin (annextube, datalad-crawler, wayslack2)
- **git-annex**: Works with git-annex but not DataLad-specific (yt-dlp import, gallery-dl)
- **git-only**: Stores in git but no annex support (git-bug, gh-md, tg-archive)
- **external**: Requires manual import into git/annex (ArchiveBox, SingleFile, Browsertrix)

### AI readiness definitions:
- **ai-ready**: Output is structured text/JSON that AIs can directly consume
- **ai-partial**: Output has structured metadata but content may need processing
- **ai-manual**: Output is primarily binary/media requiring transcription for AI use

## Step 5: Preserve Conversation History

Save this Claude Code session transcript as a project artifact:
- Export the conversation from `~/.claude/projects/-home-yoh-doc-papers-withothers-2026-data-hoarder/30311ca8-d44c-44d6-b2aa-4f47b9dc9d15.jsonl`
- Store as `artifacts/claude-sessions/2026-02-12-initial-research.jsonl` (git-annex tracked)
- Add a note in README about using Entire.io for future session preservation
- Note: Entire.io (`entireio/cli`) uses shadow branches and a metadata branch to track AI sessions within git repos - ideal for ongoing con/serve development

## Step 6: Create README.md

Include:
- Project name and tagline: "con/serve - conserve and serve digital research artifacts"
- Vision: YODA principles for everything beyond code and data
- Quick start: how to build/serve locally
- Content structure explanation
- How to add new tool entries

### TODOs section in README:
- [ ] Develop Claude Code SKILL (`/conserve.add-tool`) for adding new tool entries with proper taxonomies
- [ ] Set up GitHub Pages deployment via GitHub Actions
- [ ] Create a sample (fully or partially private) deployment at e.g. conserve.centerforopenneuroscience.org
- [ ] Integrate Entire.io for ongoing AI session archival during development
- [ ] Add comparison matrix page (tool x feature grid)
- [ ] Create archival workflow guides (step-by-step for each media type)
- [ ] Add con/ceptualization#2 vision page (config-driven archival orchestrator)
- [ ] Set up CI to validate content front matter schema
- [ ] Create RSS/Atom feed for new tool additions
- [ ] Explore MkDocs alternative for deeper DataLad ecosystem alignment

## Step 7: GitHub Pages Setup

Create `.github/workflows/hugo.yml`:
- Trigger on push to main branch
- Install Hugo (extended version)
- Build site with `hugo --minify`
- Deploy to GitHub Pages
- Configure for con/serve repo under GitHub org

## Step 8: Create .gitignore

Add Hugo-specific ignores:
```
public/
resources/_gen/
.hugo_build.lock
```

## Verification / Testing Success Criteria

1. **Hugo builds without errors**: `hugo` produces output in `public/` with zero errors/warnings
2. **Local preview works**: `hugo server` serves site on localhost, all pages render
3. **Navigation works**: All menu items link to correct sections
4. **Taxonomy pages render**: `/media_types/`, `/integrations/`, `/ai_readiness/` pages list tools correctly
5. **Content completeness**: Every tool page has valid front matter with all required taxonomies
6. **Theme matches TRR379**: Congo theme renders with similar look to pool.trr379.de
7. **README is complete**: README.md contains vision, quickstart, TODOs
8. **Conversation preserved**: Session transcript is stored in artifacts/
9. **Git status clean**: All files committed via DataLad, submodule tracked properly
10. **GitHub Actions workflow**: Workflow file present and syntactically valid (actual deployment after pushing to GitHub)

## Files to Create (Summary)

```
config/_default/hugo.toml
config/_default/languages.en.toml
config/_default/markup.toml
config/_default/menus.en.toml
config/_default/params.toml
content/_index.md
content/tools/_index.md
content/tools/communications/_index.md
content/tools/communications/slackdump.md
content/tools/communications/wayslack2.md
content/tools/communications/telegram-archive.md
content/tools/communications/tg-archive.md
content/tools/media/_index.md
content/tools/media/annextube.md
content/tools/media/yt-dlp.md
content/tools/media/gallery-dl.md
content/tools/media/zoom-archival.md
content/tools/code-artifacts/_index.md
content/tools/code-artifacts/git-bug.md
content/tools/code-artifacts/github-backup.md
content/tools/code-artifacts/gh-discussions-export.md
content/tools/code-artifacts/gh-md.md
content/tools/code-artifacts/datalad-crawler.md
content/tools/web/_index.md
content/tools/web/archivebox.md
content/tools/web/singlefile.md
content/tools/web/browsertrix.md
content/tools/web/httrack.md
content/tools/ai-sessions/_index.md
content/tools/ai-sessions/entire-io.md
content/tools/ai-sessions/cctrace.md
content/tools/ai-sessions/specstory.md
content/tools/ai-sessions/claude-code-hooks.md
content/tools/ai-sessions/ccexport.md
content/infrastructure/_index.md
content/infrastructure/forgejo-aneksajo.md
content/infrastructure/hedgedoc.md
content/infrastructure/pyinfra.md
content/infrastructure/lab-in-a-box.md
content/infrastructure/datalad-hub.md
content/about/_index.md
content/about/contributing.md
artifacts/claude-sessions/2026-02-12-initial-research.jsonl  (git-annex)
README.md
.github/workflows/hugo.yml
.gitignore (update)
themes/congo  (git submodule)
```

~35 content files + 5 config files + README + workflow + submodule
