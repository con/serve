# con/serve

**Conserve and serve digital research artifacts.**

A comprehensive knowledge base cataloging tools, approaches, and infrastructure for archiving ALL digital research artifacts into git/git-annex/DataLad repositories. Extends [YODA](https://handbook.datalad.org/en/latest/basics/101-127-yoda.html) and STAMPED principles beyond code and data to encompass communications (Slack, Telegram, Matrix), media (YouTube, Zoom), code artifacts (GitHub issues, PRs, discussions), AI coding sessions, publications, and self-hosted infrastructure.

The name "con/serve" captures both **conservation** (preserving digital artifacts before they become frozen/inaccessible) and **serving** (making archived knowledge available to humans and AI systems).

## Quick Start

### Prerequisites

- [uv](https://docs.astral.sh/uv/) (Python package manager)
- Git with git-annex

### Build and serve locally

```bash
# Set up environment and install Hugo
uv venv && source .venv/bin/activate && uv pip install hugo

# Initialize theme submodule
git submodule update --init

# Serve locally with live reload
hugo server
```

Then open http://localhost:1313/ in your browser.

### Build for production

```bash
hugo --minify
```

Output goes to `public/`.

## Content Structure

```
content/
  _index.md                      # Homepage with architecture diagram
  tools/
    communications/              # Slack, Telegram, Matrix, Mattermost
    media/                       # YouTube (annextube), video, images
    code-artifacts/              # Issues, PRs, discussions, wikis
    cloud-storage/               # rclone and cloud providers
    publications/                # Citations, references, PDFs
    web/                         # Web page and site archival
    ai-sessions/                 # AI coding session capture
  infrastructure/                # Self-hosted services (Forgejo, HedgeDoc, etc.)
  concepts/                      # Cross-cutting patterns and principles
  about/                         # Vision, contributing guide
```

## Taxonomy System

Every tool is classified along four axes:

| Axis | Values | Purpose |
|------|--------|---------|
| **Category** | Communications, Media, Code Artifacts, Web, Cloud Storage, Publications, AI Sessions, Infrastructure | What kind of artifact |
| **Integration** | native-datalad, git-annex, git-only, external | How deeply it integrates with the git-annex/DataLad stack |
| **AI Readiness** | ai-ready, ai-partial, ai-manual | How easily AI systems can consume the archived output |
| **Media Type** | slack, telegram, youtube, github-issues, etc. | Specific platform or format |

## Adding a New Tool

See [Contributing](content/about/contributing.md) for the full guide. In brief:

1. Create a new `.md` file in the appropriate `content/tools/<category>/` directory
2. Fill in the front matter template with all required fields (`repo`, `homepage`, `issues`, taxonomies)
3. Write content: overview, features, git-annex/DataLad integration, AI readiness assessment
4. Submit a PR

## TODOs

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
- [ ] Add `click` hyperlinks to Mermaid diagram nodes

## Technology

- **Static site generator**: [Hugo](https://gohugo.io/)
- **Theme**: [Congo](https://jpanther.github.io/congo/) (Tailwind CSS)
- **Version control**: [DataLad](https://www.datalad.org/) / [git-annex](https://git-annex.branchable.com/)
- **Hosting**: GitHub Pages (planned)

## License

Content is provided under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
