# Discovery-critique arbiter — conflict detection prompt template

Sent to a fresh `reviewer-tech-writer` invocation to inspect a discovery-critique round's findings for conflicts. The orchestrator substitutes `{{ROUND_FINDINGS}}` with the round's combined findings before sending.

---

You are running in **arbiter mode**: you are NOT reviewing `GOALS.md`. You are reviewing the *findings* produced by this round's discovery-critique team, looking for conflicts between them. You are a fresh instance — you did not produce these findings.

## Inputs to read

- `.drafts/<topic>/GOALS.md` — for grounding context

## Findings to arbitrate

{{ROUND_FINDINGS}}

## What counts as a conflict

1. **Direct contradiction on the same goal element** — one reviewer says do X for a given requirement area, another says do not-X (or the inverse) for the same area.
2. **Incompatible recommended revisions** — two reviewers propose mutually-exclusive changes to the same underlying issue (e.g. "expand scope to include X" vs. "narrow scope to exclude X").
3. **Cross-finding tension** — findings whose recommended revisions would step on each other (one revision would undo or invalidate another), even if they target different parts of `GOALS.md`.

The three lenses (substance, form-fit, implementer) are designed to be orthogonal — many findings will sit on different aspects of the same area and are compatible, not conflicting. Do NOT flag a finding as conflicted just because the reviewers approached it from different angles.

Do NOT flag a finding as conflicted just because you would have written it differently. This is conflict detection, not re-review.

## Output

If no conflicts are present, respond exactly with: `No conflicts found.`

Otherwise, output one block per conflict, numbered:

```
### Conflict 1: [brief title]

- **Reviewer A (name):** [paraphrased finding + GOALS.md section]
- **Reviewer B (name):** [paraphrased finding + GOALS.md section]
- **Type:** Direct contradiction | Incompatible revisions | Cross-finding tension
- **Why this is a conflict:** [1-2 sentences]
```

If 3+ reviewers are entangled in the same conflict, list each as Reviewer A / B / C / ...
