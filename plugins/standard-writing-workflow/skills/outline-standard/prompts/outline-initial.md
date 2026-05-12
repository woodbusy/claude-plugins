# Outline initial prompt template

Sent to each outliner agent (`outliner-principle`, `outliner-pragmatic`, `outliner-prescriptive`) in parallel. The agent already knows its flexibility level from its role spec; this prompt supplies the inputs, output format, and reading order.

---

Produce a structural outline of the standard at the point on the flexibility axis defined by your role. The outline is *not* a draft — it is a structural sketch the user will compare side-by-side against the other two variants before committing to a direction.

## Inputs to read (in order)

1. `.drafts/<topic>/GOALS.md` — the goals the standard must satisfy, including its **Departure candidates** and **Areas of uncertainty** sections. These are the spots where the three variants are expected to diverge.
2. The consumer repo's `docs/authoring-guide.md` — the template and house voice. This is your default; do not depart from it.
3. The consumer repo's references for the two devices (typically `docs/device-prescriptive.md` and `docs/device-risk-tiered.md`, or paths defined by the authoring guide). Read both even if you're the strict-principle variant, so you know what the more flexible variants will do differently.
4. An example standard the authoring guide cites (if any) — tone calibration only; the outline is much shorter than this.

Do not read the other variants' outlines — they are produced in parallel.

## What to produce

A compact outline at `.drafts/<topic>/outlines/<your-variant>.md` (the variant slug — `principle`, `pragmatic`, or `prescriptive` — is part of your agent identity) using this structure:

```markdown
# Outline (variant: <variant>)

## Approach summary
Two to four sentences naming the central design choices this outline makes — specifically, which Departure candidates and Areas of uncertainty you treated as device-shaped versus principle-shaped, and why. The user should be able to read this and the section list and understand the shape of the resulting standard.

## Section list
A numbered list of the standard's sections, matching the authoring-guide template. For each section, include:
- **Title**
- **One-line purpose** — what this section does in this draft
- **Approximate length** — short / medium / long, relative to the example standard
- **Key requirement bullets** — three to seven bullets per normative section, each a one-line summary of a requirement (no full RFC 2119 phrasing yet, just the substance)
- **Tables / structures planned** — name any tables, matrices, or non-prose elements you intend to include and what they enumerate

Cover sections 1–4 (Purpose, Scope, Definitions, etc.) very briefly — one or two lines each. Most of the outline's value lives in sections 5+ where the flexibility choices show up.

## Key design choices and tradeoffs
A short bulleted list of the meaningful design decisions this outline embodies. Frame each as a fork: "X over Y, because…". Highlight the choices driven by your position on the flexibility axis.

## Decisions deferred to drafting
Anything you considered but left for the drafter to resolve, with one-line notes. The strict-principle variant will tend to have more of these; the prescriptive variant will resolve more in the outline itself.

## Goals coverage check
A short table mapping each requirement area in `GOALS.md` to the section(s) of this outline that cover it. Flag anything in `GOALS.md` you couldn't fit in, and anything in your outline that goes beyond `GOALS.md` (with reason).
```

## Style

- **Structural, not prose.** No paragraphs of standard text.
- **Specific.** "Section 6.3: Token issuance — three requirements covering entropy, single-use, and binding to the requesting client" beats "Section 6.3 covers token issuance".
- **Stay in your voice.** All three variants share the principle-based house voice. If your outline reads like a different document entirely (different tone, different terminology, requirements that aren't testable), you've drifted out of voice. Your variant is about flexibility on the device-vs-principle axis only.
- **Diverge where you should, agree where you should.** Expect to differ from the other variants at the Departure candidates and Areas of uncertainty. Outside those, the outlines should look quite similar — convergence is signal, not failure.
- **Short.** Aim for an outline a careful reader can absorb in two or three minutes.
