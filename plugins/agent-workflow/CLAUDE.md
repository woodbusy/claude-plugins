# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Plugin Overview

Multi-agent workflow plugin for implementing changes via git worktrees. The pipeline: **Plan → Plan Review → Implement → Code Review → PR**. No build system, tests, or linting - this is a pure markdown/shell repository.

For full workflow documentation including step-by-step details, artifact descriptions, and orchestration behavior, see `docs/agent-workflow.md`.

## Architecture

**Agents** are role definitions - they describe who the agent is, what it produces, and how it thinks. They define philosophy and outputs, not rigid step-by-step procedures. This makes agents flexible: if an agent fails partway through, it can be reinvoked and pick up from where it left off based on what already exists. Reviewer agents (`reviewer-tech-lead`, `-security`, `-application`, `-infra-platform`, `-dev-platform`) are dual-mode: the per-invocation prompt tells them whether they are reviewing a plan or a code diff.

**Skills** are user-invocable slash commands (SKILL.md files) that handle orchestration - sequencing agents, managing parallel execution, and coordinating multi-round review cycles. The `workflow-start` skill orchestrates the full pipeline. The `workflow-resume` skill provides a re-entry point for resuming in-progress workflows. The `plan-review` skill handles plan-stage review: a fresh `reviewer-tech-lead` triage call classifies complexity (Low/Moderate/High) and selects a reviewer set, the team reviews `plan.md` and `context_detail.md` in parallel, conflicts are arbitrated, and the planner is re-invoked to revise. The `team-review` skill handles code-stage review: it classifies the diff into change categories, selects an appropriate reviewer team (always-on tech-lead and security plus application/infra-platform/dev-platform specialists when their domains are touched), manages parallel launch and round 2 re-runs, and runs an arbitration sub-flow each round to detect and resolve conflicts between reviewer findings (with human escalation for unresolved conflicts).

The skill-to-agent mapping and workflow steps are documented in `docs/agent-workflow.md` under "Skills and Agent Specs".

### Prerequisites Validation

All agent prerequisites are validated via SubagentStart hooks (defined in `hooks/hooks.json`). The hooks call `scripts/validate-prerequisites.sh` to check that required files and commits exist before the agent starts. The `plan-review` and `team-review` skills additionally validate their own prerequisites before launching reviewers. Reviewer-agent prereqs accept either plan-review mode (plan.md present) or code-review mode (implementation_guide.md + commits present).

### Agent Model Assignments

Some agents specify explicit model preferences in frontmatter:
- `planner`: opus (complex reasoning for plan creation)
- `guide-reviewer`: sonnet (lighter review task)
- `pr-author`: haiku (straightforward text distillation)
- All others: default model

## Conventions

- YAML frontmatter in skills defines `name`, `description`, and optionally `allowed-tools`
- YAML frontmatter in agents defines `name`, `description`, `tools`, `color`, and optionally `model`
- Agents that modify code (implementer, fixer) must commit but never push - `gh pr create` handles pushing
- Agents that modify code must run applicable pre-commit checks from the target repo's CLAUDE.md
- The implementation guide is edited in-place by the fixer (integrated edits, never appended sections)
- Review-specific orchestration (parallel launch, round management, arbitration) is owned by `plan-review` and `team-review`, not `workflow-start`, keeping each review skill self-contained for standalone use
- The plan is revised in-place by the planner during plan-review (no appended "revision sections"), mirroring the fixer's in-place edits to the implementation guide
- The user-approval gate for the plan lives in `workflow-start` (post plan-review), not in the planner itself
