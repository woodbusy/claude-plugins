# Plan-review follow-up prompt template

Sent to a reviewer agent for a second-round plan review after the planner has revised in response to round 1 findings.

---

Conduct a follow-up plan review. The planner has revised `plan.md` (and possibly `context_detail.md`) in response to round 1 findings.

## Inputs to read

- `.worktree-local/context.md`
- `.worktree-local/context_detail.md` — possibly revised
- `.worktree-local/plan.md` — revised
- `.worktree-local/plan_review_dialog.md` — round 1 findings, any arbitration outcomes, and the planner's revision summary

## What to produce

Focus on the planner's revisions. Verify they correctly address the round 1 findings (especially yours) without introducing new issues. Do NOT re-report issues already resolved.

If everything is in order, respond exactly with "No issues found."

Otherwise, report only new or unresolved concerns, using the finding format defined in your role spec. Reference plan/context sections in the **File:** line (e.g. `plan.md#step-3`).
