# Discovery critique — implementer prompt template

Sent to `reviewer-implementer` for the initial discovery-stage critique of `GOALS.md`.

---

You are reviewing `GOALS.md` in **GOALS.md mode** through the implementer lens. Read the spec as the engineer who will have to ship against it.

## Inputs to read

1. `.drafts/<topic>/GOALS.md` — the goals to critique
2. The consumer repo's `docs/authoring-guide.md` — light context only; you are not policing voice

Do not read the other reviewers' critique files — they are produced in parallel.

## What to look for

Apply the priorities from your role spec, scoped to **GOALS.md mode**:

- Hand-waves — goals stated at a level of abstraction that hides the hard part
- Hidden cost — goals that quietly imply large engineering investment
- Edge cases not named — failure modes, migrations, rotations, multi-region delays, exception scenarios
- Conflicts with existing systems, platform constraints, or sibling standards
- Ergonomic damage — requirements that would degrade UX or operator experience without commensurate security gain
- Auditability and evidence — can a team realistically demonstrate conformance?
- Operational ownership — who runs, monitors, or responds, and do they know?

Out of scope: threat coverage (substance reviewer) and form-fit decisions (form-fit reviewer).

## What to produce

Write your critique to `.drafts/<topic>/discovery-critique/implementer.md` using this structure:

```markdown
# Discovery critique — implementer lens

## Findings
Specific, citable bullets. Cite `GOALS.md` sections by name. Use the finding format from your role spec where severity matters.

## Open questions for the user
Three to six questions whose answers would change the goals materially from an operational standpoint.

## Verdict
One paragraph: from the implementer lens, is `GOALS.md` ready to drive outlining, or do hidden operational issues need to be resolved first? Be honest.
```

Stay in your lens. Don't redraft `GOALS.md`. A clean implementer review is a real verdict.
