# Discovery critique — form-fit prompt template

Sent to `reviewer-form-fit` for the initial discovery-stage critique of `GOALS.md`. The form-fit output is the bridge to the outline phase: its findings populate `GOALS.md`'s **Departure candidates** and **Areas of uncertainty** sections.

---

You are reviewing `GOALS.md` through the form-fit lens. Read the spec against the principle-based house voice and map where the eventual standard will want to depart from it.

## Inputs to read

1. `.drafts/<topic>/GOALS.md` — the goals to critique
2. The consumer repo's `docs/authoring-guide.md` — the house voice you are mapping the topic against

Do not read the other reviewers' critique files — they are produced in parallel.

## What to look for

Apply the priorities from your role spec:

- **Departure candidates** — requirement areas likely to need a device (prescriptive threshold or risk-tiered matrix) rather than pure principle prose. Name the area, the device, and the concrete evidence in `GOALS.md` that points to it.
- **Areas of uncertainty** — requirement areas where `GOALS.md` reflects weak or absent user signal. Name the area, what's uncertain, and what dimensions of variation the outline phase could explore.
- **Topic resistance** (optional) — spots where the topic itself resists pure principle framing.

You are not the substance reviewer (whether the right control families are covered) or the implementer reviewer (operational cost). Stay in your lens.

## What to produce

Write your critique to `.drafts/<topic>/discovery-critique/form-fit.md` using this structure:

```markdown
# Discovery critique — form-fit lens

## Departure candidates
- **<Requirement area>** — device: prescriptive | risk-tiered. Evidence in GOALS.md: [cite section]. [Brief rationale.]
- ...

## Areas of uncertainty
- **<Requirement area>** — what's uncertain: [...]. Outline-phase exploration: [...].
- ...

## Topic resistance (optional)
[Where the topic resists pure principle framing, if applicable.]

## Verdict
One paragraph: does the principle-based default fit cleanly throughout, or will the outline phase need to vary materially? A clean form-fit review is a real verdict.
```

Stay in your lens. Don't redraft `GOALS.md`. Be structural and specific; cite `GOALS.md` sections by name.
