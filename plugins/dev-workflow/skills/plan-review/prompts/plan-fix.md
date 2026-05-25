# Plan-fix prompt template

Sent to the `planner` agent to revise `plan.md` (and `context_detail.md` if needed) in response to a round of plan-review findings. The orchestrator substitutes `{{ROUND_FINDINGS}}` and `{{ARBITRATION_DIRECTIVES}}` before sending.

---

Your plan has been reviewed. Revise `plan.md` and (if needed) `context_detail.md` to address the findings below. This is NOT a fresh plan — preserve the parts that weren't called out.

## Inputs to read

- `.worktree-local/context.md`
- `.worktree-local/context_detail.md` — current version
- `.worktree-local/plan.md` — current version
- `.worktree-local/plan_review_dialog.md` — full review history including any prior arbitration

## Findings to address

{{ROUND_FINDINGS}}

## Arbitration directives and human decisions

{{ARBITRATION_DIRECTIVES}}

When a directive or human decision applies to a finding, follow that guidance over the raw finding. Human decisions are authoritative.

## How to revise

- Edit `plan.md` and `context_detail.md` in place. Do not append "revision sections" — the documents should read clean as if originally written this way.
- If a finding identifies a real issue, revise the plan to fix it.
- If a finding is wrong (e.g. based on a misread of the plan), make the plan less ambiguous so the same misread is unlikely. Don't simply ignore it.
- Stay within the original goals stated in `context_detail.md`. If a finding pushes scope beyond those goals, push back in your revision summary rather than silently expanding scope.
- Don't introduce new design choices the reviewers haven't seen unless they're necessary to address a finding.

## What to produce

After editing, respond with a concise revision summary structured as:

```
## Revision Summary

**Changes to plan.md:** [bulleted list of substantive edits, citing sections]
**Changes to context_detail.md:** [bulleted list, or "(none)"]
**Findings not addressed:** [any findings you chose not to act on, with brief rationale; or "(none)"]
```

Do not present the revised plan to the user for approval — the orchestrator handles that gate after plan review concludes.
