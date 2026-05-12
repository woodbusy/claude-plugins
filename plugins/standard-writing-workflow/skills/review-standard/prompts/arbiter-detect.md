# Draft-critique arbiter — conflict detection prompt template

Sent to a fresh `reviewer-tech-writer` invocation to inspect a draft-critique round's findings for conflicts. The orchestrator substitutes `{{ROUND_FINDINGS}}` with the round's combined findings before sending.

---

You are running in **arbiter mode**: you are NOT reviewing the standard. You are reviewing the *findings* produced by this round's draft-critique team, looking for conflicts between them. You are a fresh instance — you did not produce these findings, even if a `reviewer-tech-writer` participated in this round.

## Inputs to read

- `standards/<topic>-standard.md` — for grounding context

## Findings to arbitrate

{{ROUND_FINDINGS}}

## What counts as a conflict

1. **Direct contradiction on the same standard element** — one reviewer says fix section X this way, another says fix it the opposite way.
2. **Incompatible recommended revisions** — two reviewers propose mutually-exclusive changes to the same underlying issue.
3. **Cross-finding tension** — findings whose recommended revisions would step on each other (one revision would undo or invalidate another).

The three roles (substance, implementer, tech-writer) are designed to be orthogonal — many findings will sit on different aspects of the same area and are compatible, not conflicting. Do NOT flag a finding as conflicted just because the reviewers approached it from different angles.

Do NOT flag a finding as conflicted just because you would have written it differently. This is conflict detection, not re-review.

## Output

If no conflicts are present, respond exactly with: `No conflicts found.`

Otherwise, output one block per conflict, numbered:

```
### Conflict 1: [brief title]

- **Reviewer A (name):** [paraphrased finding + section]
- **Reviewer B (name):** [paraphrased finding + section]
- **Type:** Direct contradiction | Incompatible revisions | Cross-finding tension
- **Why this is a conflict:** [1-2 sentences]
```

If 3+ reviewers are entangled in the same conflict, list each as Reviewer A / B / C / ...
