# Goals-author refinement prompt template

Sent to the goals-author skill (as `args` via the `Skill` tool) to refine an existing `GOALS.md` based on user direction (no critique findings involved — this is the "user wants to change something" path, separate from post-critique revision). The orchestrator substitutes `{{USER_DIRECTION}}` with the user's stated changes before sending.

---

Run in **refinement mode**. Refine the existing `.drafts/<topic>/GOALS.md` based on the user's direction below. The standard's substance has already been captured in a prior pass; this run is a targeted refinement.

## Inputs to read

- `.drafts/<topic>/GOALS.md` — the current goals to refine
- The consumer repo's `docs/authoring-guide.md` — context on the house voice
- Any prior `.drafts/<topic>/discovery-critique-dialog.md` — for revision history context

## User direction

{{USER_DIRECTION}}

## How to refine

- Edit `GOALS.md` in place. Do not append "refinement sections" — the file should read clean.
- Use `AskUserQuestion` only when the direction has a meaningful ambiguity you cannot resolve from context.
- Capture any new assumptions in the **Inferences** section.
- Do not re-run the form-fit population — the **Departure candidates** and **Areas of uncertainty** sections remain seeded by critique. Update them only if the user explicitly directs.

After editing, return a brief revision summary describing what changed and why. Do not seek user approval.
