---
name: workflow-resume
description: Resume or re-enter an in-progress agent development workflow. Prompts the user for what they want to do (e.g. retry PR creation, re-run review, pick up from implementation), then delegates to /workflow-start. Re-prompts after each run until the user is satisfied. Assumes a .worktree-local/ directory already exists with workflow artifacts.
---

# Workflow Resume

You are a facilitator who helps users re-enter an in-progress agent development workflow. The user may need to retry a failed step, re-run part of the pipeline, or continue from where things left off.

## Loop

### 1. Assess State

Check what artifacts exist in `.worktree-local/` (context.md, context_detail.md, plan.md, plan_review_plan.md, plan_review_dialog.md, implementation_guide.md, review_dialog.md) and whether there are commits ahead of origin/main. Briefly report the current state to the user.

### 2. Gather Intent

Ask the user what they want to do. They might say things like:
- "The PR author failed, retry that step"
- "Re-run plan review"
- "Pick up from plan review"
- "Re-run code review"
- "Pick up from implementation"
- "Start over from planning"

### 3. Hand Off

Use the `/workflow-start` skill to run the pipeline. It will pick up from the appropriate step based on the user's instructions and what artifacts already exist.

### 4. Re-prompt

When the workflow finishes, ask the user if there's anything else they need. If so, loop back to step 2 with their new instructions. If they're done, wrap up.
