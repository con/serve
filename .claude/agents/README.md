# Claude Code Agent Specifications for con/serve

## Specification Format

Agents are defined as Markdown files with YAML frontmatter,
stored in `.claude/agents/` (project-level) or `~/.claude/agents/` (user-level).
See the [official docs](https://code.claude.com/docs/en/sub-agents) for the full reference.

```markdown
---
name: agent-name
description: When Claude should delegate to this agent
tools: Read, Grep, Glob, Bash, Edit, Write  # or subset
model: sonnet  # or opus, haiku, inherit
memory: project  # or user, local -- persistent cross-session knowledge
skills:
  - skill-name  # preloaded skill content
maxTurns: 25
permissionMode: default
---

System prompt body in Markdown.
```

### Frontmatter Fields

| Field             | Required | Description |
|-------------------|----------|-------------|
| `name`            | yes | Unique identifier, lowercase with hyphens |
| `description`     | yes | When Claude should delegate to this agent; include "use proactively" for auto-delegation |
| `tools`           | no  | Tool allowlist; inherits all if omitted. Common sets: read-only (`Read, Grep, Glob`), research (`+ WebFetch, WebSearch`), code writer (`+ Write, Edit, Bash`) |
| `disallowedTools` | no  | Tool denylist, removed from inherited or specified list |
| `model`           | no  | `sonnet`, `opus`, `haiku`, or `inherit` (default) |
| `memory`          | no  | `user` (all projects), `project` (this repo, version-controllable), `local` (this repo, gitignored) |
| `skills`          | no  | Skills to preload into context at startup |
| `maxTurns`        | no  | Maximum agentic turns before stopping |
| `permissionMode`  | no  | `default`, `acceptEdits`, `dontAsk`, `plan`, `bypassPermissions` |
| `hooks`           | no  | Lifecycle hooks scoped to this agent |
| `mcpServers`      | no  | MCP servers available to this agent |

### Best Practices

- **Limit to 3-4 active agents** -- more causes decision overhead
  ([source](https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/))
- **Focused descriptions** -- Claude uses the description to decide when to delegate
- **Use `memory: project`** for vault agents so knowledge accumulates across sessions
  and can be version-controlled
- **Progressive disclosure** -- keep the system prompt focused;
  reference separate docs for detailed specifications
- Frontier LLMs follow ~150-200 instructions reliably;
  beyond that, compliance degrades linearly
  ([source](https://www.humanlayer.dev/blog/writing-a-good-claude-md))

## Agents in This Directory

| Agent | Model | Purpose |
|-------|-------|---------|
| [vault-architect](vault-architect.md) | opus | Architectural design: vault layout, dataset hierarchies, storage strategies, distribution policies |
| [ingestion-curator](ingestion-curator.md) | sonnet | Formalizing data imports: `datalad run` wrappers, metadata annotation, idempotency, auditing |
| [pipeline-operator](pipeline-operator.md) | sonnet | Operations: pipeline monitoring, failure triage, freshness checks, escalation resolution, recovery |
| [discovery-curator](discovery-curator.md) | sonnet | Discovery: scanning environments for archivable data sources, inventorying platforms, prioritizing ingestion targets |

## TODO

- **Formalize operations as tool commands**: most agent operations should be
  backed by deterministic CLI commands (existing or new) rather than relying
  on LLM judgment for routine decisions. Agents should invoke these commands
  and understand their underlying specifications. Examples:
  - Ingestion: if a directory contains `.annextube` config, the ingestion-curator
    should deterministically run `annextube` (not reason about what tool to use)
  - Metadata: a `vault-annotate` command that sets standard git-annex metadata
    fields (distribution-restrictions, source-url, license, etc.) from a template
  - Freshness: a `vault-status` command that reports last ingestion date per source
    against expected schedule
  - QC: a `vault-check` command that validates metadata completeness,
    distribution-restrictions coverage, and provenance chain integrity
- **Write formal specifications** for these commands and the conventions
  they enforce (directory markers, metadata schemas, ingestion paradigm detection)
- **Create skills** (`.claude/commands/`) for common multi-step workflows
  (e.g., `/vault.add-source`, `/vault.audit`, `/vault.publish`)
  that agents and humans can invoke identically
- **Test agents against real vault operations** and update memory files
  with discovered patterns and edge cases

## References

- [Official subagent docs](https://code.claude.com/docs/en/sub-agents)
- [Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Skills deep dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [VoltAgent collection](https://github.com/VoltAgent/awesome-claude-code-subagents) (127+ agent examples)
- [wshobson/agents](https://github.com/wshobson/agents) (112 agents with plugin architecture)
