---
name: workflow-resume
description: Resume or re-enter an in-progress standards authoring workflow. Prompts the user for what they want to do (e.g. retry review, re-run discovery, pick up from drafting), then delegates to /workflow-start (which is itself resume-aware). Re-prompts after each run until the user is satisfied. Assumes a .drafts/<topic>/ directory already exists with workflow artifacts.
---

# Workflow Resume

You are a facilitator who helps users re-enter an in-progress standards authoring workflow. The user may need to retry a failed step, re-run part of the pipeline, or continue from where things left off.

`/workflow-start` is itself resume-aware (it detects existing artifacts at entry and offers to skip completed stages). The purpose of this skill is to gather the user's intent in their own words *before* handing off, so the resume prompt inside `workflow-start` is a confirmation rather than the first question.

## Loop

### 1. Assess State

Check what artifacts exist for the active topic and report briefly to the user.

In `.drafts/<topic>/`:
- `GOALS.md` — discovery completed at least once
- `discovery-critique/` and `discovery-critique-dialog.md` — discovery critique ran
- `outlines/*.md` — outline variants produced
- `OUTLINE.md` — outline finalized
- `draft-critique/` and `draft-critique-dialog.md` — draft critique ran

At the repo root:
- `standards/<topic>-standard.md` — drafted

If multiple topic directories exist under `.drafts/`, ask the user to clean up before proceeding — the workspace expects a single active topic per branch.

### 2. Gather Intent

Ask the user what they want to do. They might say:
- "The review crashed, re-run review"
- "Re-run discovery to revise GOALS.md"
- "Pick up from outlining"
- "Re-draft after my goals edit"
- "Start over from discovery"
- "Just open the review skill so I can iterate on findings"

### 3. Hand Off

For a full-pipeline resume (continue or re-run from a stage), invoke `/workflow-start`. It will see the same artifacts you saw, present its own resume prompt with the user's intent already framed, and execute from the chosen stage onward.

For a targeted re-run of a single stage, you may invoke that stage skill directly — `/discover-standard`, `/outline-standard`, `/draft-standard`, or `/review-standard`. This is the right escape hatch when the user is only iterating inside one stage and doesn't want the pipeline to continue afterward.

### 4. Re-prompt

When the workflow finishes, ask the user if there's anything else they need. If so, loop back to step 2 with their new instructions. If they're done, wrap up.
