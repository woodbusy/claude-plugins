---
name: cw-planner
description: Plan implementation for changes in a worktree. Use when the user asks to plan work, create an implementation plan, or invokes /cw-planner. Extends built-in plan mode with structured discovery of goals, scope, and constraints, producing a plan file and context detail file. Assumes a .worktree-local/ directory exists with a context.md file.
---

# Worktree Change Planner

Plan implementation for changes in the current worktree.

## Workflow

1. Validate that `.worktree-local/context.md` exists. If missing, stop and inform the user that they need to create a worktree with a `context.md` file first.

2. Use the `planner` agent to create the plan and context detail.

3. When the agent completes, report results to the user:
   - Confirm that `.worktree-local/plan.md` and `.worktree-local/context_detail.md` were written
   - Summarize the plan at a high level
