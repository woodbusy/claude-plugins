# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code plugin marketplace repository containing reusable plugins that extend Claude Code with skills and agent specs. Plugins are installed into other projects to provide domain-specific workflows.

## Structure

- `.claude-plugin/marketplace.json` — Plugin registry; lists all plugins with their `source` directory under `plugins/`
- `plugins/<name>/.claude-plugin/plugin.json` — Plugin metadata (name, version, author)
- `plugins/<name>/skills/<skill>/SKILL.md` — Skill definitions (user-invocable via `/skill-name`); YAML frontmatter defines `name`, `description`, and optionally `allowed-tools`
- `plugins/<name>/agents/<agent>.md` — Agent specs (prompt files for sub-agents); YAML frontmatter defines `name`, `description`, `tools`, and `color`
- `plugins/<name>/docs/` — Plugin documentation
- `plugins/<name>/scripts/` — Helper scripts used by skills and hooks
- `plugins/<name>/hooks/hooks.json` — Plugin hooks (e.g., SubagentStart for prerequisite validation)

## Plugins

### agent-workflow

Multi-agent workflow for implementing changes via git worktrees. The pipeline: **Plan → Implement → Review → PR**.

Skills:
- `workflow-resume` — Resume/re-enter an in-progress workflow; prompts user for what to do, delegates to `workflow-start`, re-prompts until done
- `workflow-start` — Full pipeline orchestrator; directly uses planner, implementer, guide-reviewer, and pr-author agents, delegates review to `team-review`
- `team-review` — Parallel review (correctness, simplification, security) with up to 2 fix rounds

Agent prerequisites are validated via SubagentStart hooks. Workflow artifacts live in `.worktree-local/` within the target worktree.

### issue-tracking-github

Standalone GitHub issues skill.

## Conventions

- Skills use YAML frontmatter for metadata; the body is a markdown prompt
- Agent specs follow the same frontmatter pattern with `tools` listing allowed tool names
- Agent specs are role definitions (philosophy and outputs), not rigid procedures
- Prerequisites validation uses SubagentStart hooks calling `validate-prerequisites.sh`
- No build system, tests, or linting — this is a pure markdown/shell repository
