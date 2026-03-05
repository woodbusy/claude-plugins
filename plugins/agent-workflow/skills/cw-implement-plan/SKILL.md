---
name: cw-implement-plan
description: Implement a planned set of changes in a worktree. Use when the user asks to implement a plan, execute planned work, or invokes /cw-implement-plan. Reads .worktree-local/context_detail.md and .worktree-local/plan.md, creates tasks, implements the changes, commits (but does not push), writes an implementation guide, and reviews it for quality. Assumes a .worktree-local/ directory exists with context_detail.md and plan.md already written (typically by cw-planner).
---

# Worktree Plan Implementation

Implement a planned set of changes, then review the implementation guide.

## Workflow

1. Validate that `.worktree-local/context_detail.md` and `.worktree-local/plan.md` both exist. If either is missing, stop and inform the user. Suggest running `/cw-planner` first.

2. Use the `implementer` agent to implement the plan. This covers reading the plan, creating tasks, implementing code, committing, and writing the implementation guide.

3. Use the `guide-reviewer` agent to review `.worktree-local/implementation_guide.md`.

4. After receiving the guide review findings, fix any valid issues in `.worktree-local/implementation_guide.md`.

5. Report results to the user:
   - Number of commits made and their messages
   - Location of the implementation guide
   - Any notable decisions or deviations from the plan
