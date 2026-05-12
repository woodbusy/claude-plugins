# Draft critique — substance prompt template

Sent to `reviewer-substance` for a draft-stage critique of the published standard. **Cold-read mode** — the reviewer does not see `GOALS.md` or `OUTLINE.md`.

---

You are reviewing `standards/<topic>-standard.md` in **draft mode** through the substance lens. You are reading the standard the way a real consumer would: you have not seen the goals document or the outline, and you should not look for them. Your only inputs are the published standard and the authoring conventions every standard in this repo follows.

## Inputs to read

1. `standards/<topic>-standard.md` — the draft under review
2. The consumer repo's `docs/authoring-guide.md` — RFC 2119 conventions and the principle-based house voice (reader competence, not context — every consumer of this standard will know these conventions)

**Do not read** `.drafts/<topic>/GOALS.md` or `.drafts/<topic>/OUTLINE.md`. If the prose feels like it's missing something, flag it as a cold-reader observation — don't go upstream to fill the gap. That gap is exactly the signal the user needs.

## What to look for

Apply the priorities from your role spec, scoped to **draft mode**:

- Clarity of each MUST / MUST NOT / SHOULD / SHOULD NOT — could a reasonable engineer read the requirement two different ways?
- Testability — can conformance be evidenced? Flag requirements you cannot translate into an audit check.
- Threat coverage as it reads on the page — of the threats the standard names in its scope or purpose sections, does each have at least one normative statement that meaningfully mitigates it?
- Apparent gaps — controls a competent reader would expect for this topic but doesn't see
- Scope and applicability clarity
- Prohibited uses and exceptions — specific enough to enforce?
- Definitions load-bearing for compliance
- Evidence and audit logistics — concrete enough to build a checklist from?

Out of scope: prose quality / voice (tech-writer reviewer); operational cost / implementability (implementer reviewer).

When something feels missing, phrase it as a cold-reader observation rather than an authoritative gap claim. "Section 4 names credential theft as an in-scope threat but I don't see a MUST anywhere that addresses session fixation" is what you want.

## What to produce

Write your critique to `.drafts/<topic>/draft-critique/substance.md` using this structure:

```markdown
# Draft critique — substance (cold read)

## Findings
Use the finding format from your role spec. Cite sections by number and title (e.g., "Section 7.2 (Session Revocation), requirement 7.2.3").

## Open questions for the user
Three to six questions a cold reader couldn't answer from the standard alone.

## Verdict
One paragraph: from the substance lens, is the draft usable as-is, or does it need revision before publishing? Be honest.
```

A clean substance review is a real verdict — don't manufacture findings to look thorough.
