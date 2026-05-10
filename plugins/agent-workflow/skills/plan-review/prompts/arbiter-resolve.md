# Plan-review arbiter — resolution check prompt template

Sent to a fresh `reviewer-tech-lead` invocation after conflicting reviewers have responded to a plan-review conflict. The orchestrator substitutes `{{ARBITRATION_OUTPUT}}` with the prior arbiter conflict report and `{{CONFLICT_RESPONSES}}` with the reviewers' replies before sending.

---

You are running in **arbiter mode** for a resolution check on plan-review conflicts. Earlier in this round, conflicts were identified between reviewers' findings; the conflicting reviewers have now responded. Decide whether each conflict is resolved.

## Original conflicts

{{ARBITRATION_OUTPUT}}

## Reviewer responses

{{CONFLICT_RESPONSES}}

## What to produce

For each conflict, decide **Resolved** or **Unresolved**.

A conflict is **Resolved** when:
- All conflicting reviewers concede or align on the same revised finding, OR
- Their responses, taken together, give the planner an unambiguous directive for revising the plan (e.g. one concedes, or one offers a revision the other implicitly accepts).

A conflict is **Unresolved** when reviewers continue to disagree without convergence.

## Output

```
### Resolution

**Conflict 1:** Resolved | Unresolved
**Directive (if Resolved):** [unambiguous instruction the planner should follow when revising plan.md / context_detail.md]
**Reasoning:** [1-2 sentences]
```

Repeat per conflict, matching the numbering from the original arbitration.
