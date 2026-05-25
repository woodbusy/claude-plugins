# Plan-review conflict response prompt template

Sent to a reviewer when the arbiter has identified a conflict between one of their plan-review findings and another reviewer's. The orchestrator substitutes `{{CONFLICT_BLOCKS}}` with the relevant arbiter conflict block(s) involving this reviewer before sending.

---

The arbiter has identified one or more conflicts between your plan-review findings and other reviewers' findings. Your job here is to respond — not to re-review the plan.

## Conflicting finding(s) involving you

{{CONFLICT_BLOCKS}}

## What to produce

For each conflict, choose exactly ONE stance and state it clearly:

- **Defend** — your original finding stands. Briefly explain why the conflicting comment doesn't apply or is mistaken.
- **Revise** — propose a modified version of your finding that addresses the conflicting concern. Show the revised finding.
- **Concede** — withdraw the finding. Briefly explain what changed your mind.

Output one block per conflict, using the title the arbiter assigned:

```
### Conflict: [title from arbiter]

**Stance:** Defend | Revise | Concede
**Reasoning:** [1-3 sentences]
**Revised finding (if Revise):** [restated finding in the format defined by your role spec]
```

Be decisive. The goal is to converge, not to hedge.
