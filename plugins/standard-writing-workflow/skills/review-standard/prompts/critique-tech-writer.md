# Draft critique — tech-writer prompt template

Sent to `reviewer-tech-writer` for a draft-stage critique of the published standard. **Contextualized mode** — the reviewer sees `OUTLINE.md` and `GOALS.md` because structural adherence and intent-vs-voice are their job.

---

You are reviewing `standards/<topic>-standard.md` in **review mode**. Read the draft as an experienced technical editor asked to copy-edit and structurally review a finished standard. Your focus is on prose and shape — voice, conciseness, structural fidelity to `OUTLINE.md`, alignment with the house voice.

## Inputs to read (in order)

1. `standards/<topic>-standard.md` — the draft under review
2. `.drafts/<topic>/OUTLINE.md` — the structural plan the draft was supposed to follow
3. `.drafts/<topic>/GOALS.md` — the goals the standard must satisfy (intent context, not coverage checklist)
4. The consumer repo's `docs/authoring-guide.md` — the template, RFC 2119 conventions, and principle-based house voice
5. An example standard the authoring guide cites (if any) — calibration for length and depth

## What to look for

Apply the priorities from your role spec, scoped to **review mode**:

- Voice drift — does the draft hold the principle-based house voice throughout?
- Conciseness vs. verbosity — sections only as long as their job requires
- Overall length — compare against the example standard and the planned section lengths in `OUTLINE.md`
- Structural adherence to `OUTLINE.md` — section list, titles, planned tables. Flag every deviation
- RFC 2119 hygiene — keywords used correctly and only in normative sections; bullets individually numbered; one normative statement per bullet
- Definitions and terminology — used consistently, formatted correctly, defined where used in normative statements
- Readability for a competent engineer — clean sentence structure, paragraphs around one idea each
- Frontmatter and template adherence — YAML frontmatter, `confluence_page_id:` field, section template

Out of scope: threat coverage (substance reviewer), implementability (implementer reviewer), second-guessing `OUTLINE.md`'s structural decisions (judge whether the draft built what the outline specified, not whether the outline specified the right thing).

## What to produce

Write your critique to `.drafts/<topic>/draft-critique/tech-writer.md` using this structure:

```markdown
# Draft critique — tech-writer

## Findings
Use the finding format from your role spec. Cite sections by number and title (e.g., "Section 6.3 (Token Issuance), requirement 6.3.2").

## Structural deviations from OUTLINE.md
List every place the draft deviates from the outline — added sections, skipped sections, tables not built, structural reorderings. One line each.

## Verdict
One paragraph: is the writing and structure clean enough to publish, or does the draft need another pass? Be honest.
```

A clean tech-writer review is a real verdict — don't manufacture findings to look thorough.
