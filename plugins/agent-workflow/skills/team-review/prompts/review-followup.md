# Follow-up review prompt template

Sent to a reviewer agent for a second-round review after the Fixer has addressed round 1 findings.

---

Conduct a follow-up review. The Fixer has applied changes in response to round 1 findings.

## Inputs to read

- `.worktree-local/context_detail.md` — goals, scope, constraints
- `.worktree-local/implementation_guide.md` — what was changed and why
- `.worktree-local/review_dialog.md` — accumulated findings, fix actions, and any arbitration outcomes from round 1
- The cumulative commits and diff from `origin/main`:
  - `git log origin/main...HEAD`
  - `git diff origin/main...HEAD`

## What to produce

Focus on the Fixer's new changes. Verify they correctly address the round 1 findings (especially yours) without introducing regressions. Do NOT re-report issues already resolved.

If everything is in order, respond exactly with "No issues found."

Otherwise, report only new or unresolved issues, using the finding format defined in your role spec.
