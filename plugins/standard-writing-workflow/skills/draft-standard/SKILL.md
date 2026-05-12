---
name: draft-standard
description: Produce the final technical standard markdown by faithfully expanding GOALS.md and OUTLINE.md via the writer agent. Use when GOALS.md and OUTLINE.md both exist and the user is ready to generate the final draft. Trigger on "draft the standard", "write the standard", "draft from the outline", "next step after the outline", "produce the final standard".
---

# Draft Standard

Takes the approved `GOALS.md` and `OUTLINE.md` and produces the published standard at `standards/<topic>-standard.md`. A single `writer` agent does the work — no parallel variants. Variation belongs upstream in `/discover-standard` and `/outline-standard`; by the time drafting begins, the design is settled.

## Workspace

```
.drafts/<topic>/
├── GOALS.md       (input)
└── OUTLINE.md     (input)

standards/<topic>-standard.md   (output)
```

## Prompt templates

Under `${CLAUDE_PLUGIN_ROOT}/skills/draft-standard/prompts/`:

| Template | Purpose | Placeholders |
|----------|---------|--------------|
| `write.md` | Tell `writer` to draft the standard | none |

## Workflow

### Step 1: Validate Prerequisites

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-prerequisites.sh draft-standard`. If it fails, relay the error to the user and stop.

### Step 2: Sanity-Check Inputs

Skim `OUTLINE.md` and `GOALS.md` and confirm:

- The topic slug matches the `.drafts/<topic>/` directory and the planned output path.
- `OUTLINE.md` covers all requirement areas listed in `GOALS.md` (or explicitly notes which it doesn't).
- The outline isn't materially stale — if `GOALS.md` was edited after `OUTLINE.md` was written, ask the user whether to re-run `/outline-standard` first.

If anything looks off, surface it before invoking `writer`.

### Step 3: Invoke the Writer

Send the **`write.md`** prompt to `writer`. It will produce `standards/<topic>-standard.md` and return a closing report.

### Step 4: Report and Hand Off

When `writer` returns, briefly tell the user:

- Where the file landed (`standards/<topic>-standard.md`)
- The writer's closing notes, distilled — deferrals it resolved, thresholds it defaulted, anything beyond the outline, anything flagged for stakeholder input
- Suggested next step: `/review-standard` for the three-role critique

If the writer's notes flag a conflict between `OUTLINE.md` and `GOALS.md`, surface it explicitly so the user can decide whether to revise either input and re-run.

## Notes for the orchestrator

- If the user asks for "another draft", first ask whether they want to revise `OUTLINE.md` (run `/outline-standard` again) or only re-run drafting with the same outline. Re-running drafting against the same outline rarely produces meaningfully different output and is usually a sign the outline needs more work.
- The writer is a fresh sub-agent with no memory; everything it needs must be in `OUTLINE.md`, `GOALS.md`, and the consumer repo's authoring guide.
- The `.drafts/<topic>/` workspace persists after drafting. The user can delete it manually.
