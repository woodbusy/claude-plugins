# Write prompt template

Sent to the `writer` agent to draft the final standard.

---

Draft the final version of the technical standard. Read these in order:

1. `.drafts/<topic>/OUTLINE.md` — the structural plan you must adhere to
2. `.drafts/<topic>/GOALS.md` — the substantive goals and scope
3. The consumer repo's `docs/authoring-guide.md` — the template, conventions, and principle-based house voice every standard in this repo follows
4. The consumer repo's device references (typically `docs/device-prescriptive.md` and `docs/device-risk-tiered.md`, or paths the authoring guide names) — read whichever ones `OUTLINE.md` called for
5. An example standard the authoring guide cites (if any) — tone and depth reference

Write the complete standard to `standards/<topic>-standard.md`. The topic slug matches the `.drafts/<topic>/` directory.

Follow `OUTLINE.md`'s structure faithfully — do not reshape it. Hold the principle-based house voice throughout. Apply your role spec's hard rules (RFC 2119 hygiene, section template, frontmatter, definition format).

After writing, return a closing report covering:
- Outline items resolved (with the choice for each "deferred to drafting" item)
- Thresholds you defaulted because neither `OUTLINE.md` nor `GOALS.md` specified them
- Anything you added beyond `OUTLINE.md` and why
- Any conflict between `OUTLINE.md` and `GOALS.md` and how you resolved it
- Sections needing stakeholder input
