---
name: cw-workflow
description: Run the full agent development workflow from planning through PR creation. Use when the user asks to run the full workflow, execute the pipeline, or invokes /cw-workflow. Sequences planning, user approval, implementation, parallel review, and PR creation. Assumes a .worktree-local/ directory exists with a context.md file.
---

# Agent Development Workflow

Run the full pipeline from planning through PR creation.

## Workflow

### Step 1: Planning

Invoke the `/cw-planner` skill to produce `.worktree-local/plan.md` and `.worktree-local/context_detail.md`. The planner handles user approval of the plan internally — when it returns, the plan is approved.

### Step 2: Implementation

Invoke the `/cw-implement-plan` skill to implement the plan, commit changes, and produce `.worktree-local/implementation_guide.md`.

If the implementer reports a significant deviation from the plan, stop and surface it to the user before proceeding to review.

### Step 3: Review

Invoke the `/cw-review` skill to run parallel review and fixing.

If unresolved issues remain after review, present them to the user and ask whether to proceed with PR creation or address the issues first.

### Step 4: PR Creation

Use the `pr-author` agent to create a draft PR from `.worktree-local/implementation_guide.md`.

Report the PR URL to the user.

## Status Updates

Provide brief updates between major steps:
- "Planning complete, starting implementation..."
- "Implementation complete, starting review phase..."
- "Review complete, creating PR..."

## Escalation

Surface issues to the user rather than proceeding blindly:
- Plan deviations reported by the implementer
- Persistent review findings after 2 rounds
- Any agent failures or missing prerequisites
