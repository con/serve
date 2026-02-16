# con/serve — Project Instructions

## What This Is

A Hugo website / knowledge base cataloging tools, infrastructure, and patterns
for archiving digital artifacts — both **research** and **personal** — into git-annex/DataLad repositories.
Not just code and data — communications (Slack, Telegram, Matrix), media (YouTube, Zoom),
code forge artifacts (issues, PRs, discussions), AI sessions, publications,
and personal data (Google Takeout, photo collections, personal messaging channels).

- **Site**: Hugo with the Congo theme (Tailwind CSS), planned for GitHub Pages at `con.github.io/serve/`
- **Repo**: `con/serve` under Center for Open Neuroscience
- **Build**: `git submodule update --init && hugo server`
- **Content lives in**: `content/` with sections: `tools/`, `infrastructure/`, `concepts/`, `user-stories/`, `about/`
- **Taxonomy axes**: category, integration level (native-datalad / git-annex / git-only / external), AI readiness, media type
- **Sister projects in `projects/`**: `liab-conserve/`, `liab-deployments/` (Lab-in-a-Box pyinfra deployments)
- **Code utilities in `code/`**: `con_serve_tracker` (git-annex file existence checker)

## Content Tone

This project is in an **early exploratory phase** — assembling the landscape of tools, services, and user stories.

- **Do NOT** spec out detailed implementation workflows, step-by-step howtos, or prescriptive code examples for processes that have not been tried yet. Invented workflows look authoritative but are misleading.
- **Do NOT** enumerate "gaps to fill" or "needs building" lists — what needs building will become clear as the picture gets more complete.
- **DO** describe what tools exist, what they do, and how they relate to each other.
- **DO** honestly state when something is unsolved or has no good automated workflow yet, without fabricating one.
- **DO** describe desired end states (vault layout, frontends) but keep them concise.

In short: document what is known, flag what is not, and resist the urge to fill unknowns with speculative detail.
