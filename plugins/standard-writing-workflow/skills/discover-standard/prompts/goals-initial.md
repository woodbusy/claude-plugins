# Goals-author initial prompt template

Sent to `goals-author` to interview the user and write `GOALS.md` for a new standard.

---

Interview the user to discover the goals and scope of a new technical standard, then write `.drafts/<slug>/GOALS.md`. You choose the slug (a pithy kebab-case name like `magic-link-security`) as part of the interview; confirm it with the user before writing.

## Inputs to read

- The consumer repo's `docs/authoring-guide.md` — the principle-based house voice (defines what the standard will eventually need to express). Skim for context; you are not writing in that voice yet.
- The consumer repo's `standards/` directory — existing standards for context on terminology and adjacency. Optional.

## What to produce

- `.drafts/<slug>/GOALS.md` following the structure in your role spec.
- Leave **Departure candidates** and **Areas of uncertainty** sections present but empty — the form-fit critique populates them downstream.
- Capture every assumption you bake in (that the user didn't state) in the **Inferences** section.

## How to interview

Use `AskUserQuestion` to gather what you need. Batch 2–3 focused questions per call. Cover scope, threat landscape, requirement areas, prohibitions, stakeholders, and (where you can elicit it) the user's leanings on thresholds, tier schemes, and uncertainty.

Calibrate question depth to the topic. Don't ask the user to settle decisions they genuinely don't have — capture those as Open questions or as signals the outline phase can explore.

After writing the file, return a brief confirmation summarizing the topic, slug, and the requirement areas you captured. Do not seek user approval — the orchestrator runs the critique next and the approval gate comes after.
