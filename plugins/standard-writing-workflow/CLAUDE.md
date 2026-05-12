# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Plugin Overview

Multi-agent workflow plugin for authoring technical standards. The pipeline: **Discover (GOALS.md) → Outline (3 variants → OUTLINE.md) → Draft → Review**. No build system, tests, or linting - this is a pure markdown/shell repository.

For full workflow documentation including step-by-step details, artifact descriptions, and orchestration behavior, see `docs/standard-writing-workflow.md`.

## Architecture

**Agents** are role definitions - they describe who the agent is, what it produces, and how it thinks. They define philosophy and outputs, not rigid step-by-step procedures. This makes agents flexible: if an agent fails partway through, it can be reinvoked and pick up from where it left off based on what already exists. The reviewer agents that participate in both discovery and draft critiques (`reviewer-substance`, `reviewer-implementer`) are dual-mode: the per-invocation prompt tells them whether they are reviewing `GOALS.md` (the spec) or the published draft. `reviewer-tech-writer` is similarly mode-driven — review mode (draft critique, with full context) plus arbiter mode (a fresh invocation that runs the conflict sub-flow for both discovery and draft critiques).

**Skills** are user-invocable slash commands (SKILL.md files) that handle orchestration - sequencing agents, managing parallel execution, and coordinating critique cycles. The `workflow-start` skill orchestrates the full pipeline. The `workflow-resume` skill provides a re-entry point for resuming in-progress workflows. The four stage skills (`discover-standard`, `outline-standard`, `draft-standard`, `review-standard`) own their respective sub-flows: parallel critique launches, arbitration, and producer/writer revision. Each stage skill is also user-invocable standalone for iteration.

The `goals-author` skill is a sub-skill of `discover-standard`, not a stage skill. It is implemented as a skill rather than an agent because the discovery interview needs `AskUserQuestion` and subagents cannot call that tool — only the main loop can. Skills invoked via the `Skill` tool run in the main loop, so `goals-author` retains user-interaction tools. It is mode-driven via per-invocation prompts (initial / refinement / revision), the same way the dual-mode reviewer agents are.

The skill-to-agent mapping and workflow steps are documented in `docs/standard-writing-workflow.md` under "Skills and Agent Specs".

### Prerequisites Validation

Agent prerequisites are validated via SubagentStart hooks (defined in `hooks/hooks.json`). The hooks call `scripts/validate-prerequisites.sh` to check that required files exist before the agent starts. The hooks resolve the active topic by locating the single `.drafts/<topic>/` directory; the `.drafts/` workspace is branch-ephemeral so a topic is unambiguous within a branch. The stage skills also validate their own prerequisites before launching agents. The `goals-author` skill (which is not an agent) validates its own prereqs as Step 1 of its body, since hooks only fire on subagent launch.

### Agent Model Assignments

Some agents specify explicit model preferences in frontmatter:
- `writer`: opus (final-draft authoring)
- All others: default model

The `goals-author` skill cannot pin a model preference (skill frontmatter has no model field). It inherits the session's model. Interview + GOALS.md authoring benefits from opus; users running the workflow on a smaller model should expect lower-quality interviews.

## Conventions

- YAML frontmatter in skills defines `name`, `description`, and optionally `allowed-tools`
- YAML frontmatter in agents defines `name`, `description`, `tools`, `color`, and optionally `model`
- Critique-specific orchestration (parallel launch, arbitration) is owned by `discover-standard` and `review-standard`, not `workflow-start`, keeping each stage skill self-contained for standalone use
- `GOALS.md` and `standards/<topic>-standard.md` are revised in-place by their author agents (no appended "revision sections")
- The user-approval gate after discovery lives in `workflow-start`. The outlining gate lives inside `/outline-standard` itself — the side-by-side variant comparison and user pick *is* the gate. `workflow-start` only gates after discovery.
- The plugin defers to the consumer repo's `docs/authoring-guide.md` for the house voice. The default tone is security-engineering: role openings in the `goals-author` skill and the `writer`, outliners, `reviewer-substance`, and `reviewer-implementer` agents frame them as an experienced security engineer. The orchestration architecture is reusable for other standards domains, but consumers outside security may want to fork the role openings to match their domain.
