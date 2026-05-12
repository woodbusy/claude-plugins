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

Multi-agent workflow for implementing changes via git worktrees. The pipeline: **Plan → Plan Review → Implement → Code Review → PR**.

Skills:
- `workflow-resume` — Resume/re-enter an in-progress workflow; prompts user for what to do, delegates to `workflow-start`, re-prompts until done
- `workflow-start` — Full pipeline orchestrator; directly uses planner, implementer, guide-reviewer, and pr-author agents, delegates plan review to `plan-review` and code review to `team-review`, owns the user-approval gate after plan review
- `plan-review` — Triage Tech Lead classifies plan complexity (Low/Moderate/High) and selects reviewer team; team reviews plan.md and context_detail.md in parallel; conflicts arbitrated; planner re-invoked to revise (1 round at Low/Moderate, up to 2 at High)
- `team-review` — Parallel code review (correctness, simplification, security) with up to 2 fix rounds

Reviewer agents are dual-mode (plan vs code), driven by per-invocation prompts. Agent prerequisites are validated via SubagentStart hooks. Workflow artifacts live in `.worktree-local/` within the target worktree.

### standard-writing-workflow

Multi-agent workflow for authoring technical standards. The pipeline: **Discover → Outline → Draft → Review**.

Skills:
- `workflow-resume` — Resume/re-enter an in-progress workflow; prompts user for what to do, delegates to `workflow-start`, re-prompts until done
- `workflow-start` — Full pipeline orchestrator; detects existing artifacts at entry and resumes from the first incomplete stage, calls the four stage skills in sequence, and owns the user-approval gate after discovery (the outlining gate lives inside `/outline-standard` — variant comparison is the gate)
- `discover-standard` — Interview via `goals-author`, write `GOALS.md`, three-lens parallel critique (substance, form-fit, implementer), arbitrate conflicts, revise
- `outline-standard` — Three parallel outline variants (principle, pragmatic, prescriptive) on a flexibility axis, user picks/blends → `OUTLINE.md`
- `draft-standard` — Single `writer` agent expands `GOALS.md` + `OUTLINE.md` into the final standard
- `review-standard` — Three-role parallel critique (substance/implementer cold, tech-writer with context), arbitrate conflicts, orchestrator-driven goals-coverage pass

Reviewer agents that participate in both critiques (`reviewer-substance`, `reviewer-implementer`) are dual-mode, driven by per-invocation prompts. `reviewer-tech-writer` is also mode-driven: draft reviewer with full context, plus a fresh-invocation arbiter for the conflict sub-flow inside both critiques. Workflow artifacts live in `.drafts/<topic>/` (branch-ephemeral) in the consumer repo, with the final standard at `standards/<topic>-standard.md`.

### issue-tracking-github

Standalone GitHub issues skill.

## Conventions

- Skills use YAML frontmatter for metadata; the body is a markdown prompt
- Agent specs follow the same frontmatter pattern with `tools` listing allowed tool names
- Agent specs are role definitions (philosophy and outputs), not rigid procedures
- Prerequisites validation uses SubagentStart hooks calling `validate-prerequisites.sh`
- No build system, tests, or linting — this is a pure markdown/shell repository
