---
name: workflow-start
description: Run the full standards authoring workflow from discovery through review. Use when the user asks to author a standard end-to-end, run the pipeline, or invokes /workflow-start. Resume-aware - detects existing .drafts/<topic>/ artifacts at entry and offers to pick up from the first incomplete stage. Assumes the consumer repo's docs/authoring-guide.md describes the house voice.
---

# Standards Authoring Workflow

You are the editor-in-chief orchestrating the authoring of a technical standard. Each stage of the pipeline has its own skill that owns its sub-flow; your job is to sequence those skills, hold the human-approval gate after discovery, and surface escalations to the user when a stage flags something the team couldn't resolve.

This skill is resume-aware: if `.drafts/<topic>/` artifacts already exist, it will ask the user where to pick up rather than restarting from scratch.

## Step 0: Validate Prerequisites and Detect State

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-prerequisites.sh workflow-start`. If it fails (typically because the consumer repo is missing `docs/authoring-guide.md`), relay the error to the user and stop.

Then detect the current workflow state:

1. **Resolve the active topic.** Scan `.drafts/*/` for directories. If none exist, the workflow is fresh — skip to Step 1 (Discovery).
2. If exactly one topic exists, record the slug and check which completion artifacts are present:
   - `.drafts/<topic>/GOALS.md` → discovery complete
   - `.drafts/<topic>/OUTLINE.md` → outlining complete
   - `standards/<topic>-standard.md` → drafting complete
3. If multiple topics exist under `.drafts/`, stop and ask the user to clean up — the workspace is branch-ephemeral and expects exactly one active topic.

### Resume prompt

If at least one completion artifact is present, summarize the state to the user and ask via `AskUserQuestion` how to proceed. Tailor the options to what was found, but always offer:

- **Resume** — pick up from the first incomplete stage.
- **Re-run from a specific stage** — let the user name a stage to re-execute (Discovery / Outlining / Drafting / Review). Re-running a stage invalidates *that* stage's artifact for resume purposes but does not delete downstream artifacts; warn the user that downstream artifacts may now be stale.
- **Start fresh** — `AskUserQuestion` provides "Other" automatically; treat any free-form response that asks to start over as a request to clean `.drafts/<topic>/` (and possibly `standards/<topic>-standard.md`). Confirm before deleting anything.

Record the user's choice. From here on, "skip stage X" means the stage's completion artifact already exists *and* the user opted to resume past it.

## Step 1: Discovery

**Skip if:** `.drafts/<topic>/GOALS.md` exists and the user opted to resume past discovery. Print `"Discovery already complete (GOALS.md present), skipping."` and proceed to Step 2 — *do not run the post-discovery user-approval gate, since it was passed in a prior run.*

**Otherwise:** Use the `/discover-standard` skill to interview the user (via the `goals-author` sub-skill), write `GOALS.md`, run the three-lens parallel critique, arbitrate any conflicts, and revise.

When `/discover-standard` returns, summarize the resulting `GOALS.md` for the user at a high level (post-revision) and ask for approval via `AskUserQuestion`. If the user requests changes, re-invoke `/discover-standard` with their direction and ask again. Only proceed once the user approves.

## Step 2: Outlining

**Skip if:** `.drafts/<topic>/OUTLINE.md` exists and the user opted to resume past outlining. Print `"Outlining already complete (OUTLINE.md present), skipping."` and proceed to Step 3.

**Otherwise:** Use the `/outline-standard` skill. It will produce three parallel outline variants, present a side-by-side comparison, ask the user to pick or blend, and write `OUTLINE.md`.

When `/outline-standard` returns, the user has already directed the outline shape inside the skill (the variant comparison *is* the human-review surface). Confirm `OUTLINE.md` was written and surface any flags (e.g. ambiguity the skill couldn't resolve). If the user wants to revise the goals after seeing the outlines, send them back to Step 1 (and clear the skip flag for discovery).

## Step 3: Drafting

**Skip if:** `standards/<topic>-standard.md` exists and the user opted to resume past drafting. Print `"Drafting already complete (standard present), skipping."` and proceed to Step 4.

**Otherwise:** Use the `/draft-standard` skill. The `writer` agent will produce `standards/<topic>-standard.md` and return a closing report covering thresholds it defaulted, deferred items it resolved, and anything beyond `OUTLINE.md` or flagged for stakeholder input.

If the writer flags a conflict between `OUTLINE.md` and `GOALS.md`, stop and surface it to the user before proceeding to review.

## Step 4: Review

Review has no single completion artifact — it's iterative with the user — so it is never auto-skipped. Use the `/review-standard` skill. It will run the three-role parallel critique, arbitrate conflicts, do an orchestrator goals-coverage pass, and present findings with suggested action paths (in-conversation edit, re-run outline, re-run discover).

When `/review-standard` returns, the user will direct the next move from within that skill — edits, upstream re-run, or "ready to ship". You don't gate at this step; the review skill iterates with the user directly until they're satisfied.

## Status Updates

Provide brief updates between major steps. Examples:
- "GOALS.md already present, skipping discovery. Starting outlining..."
- "Discovery complete, summarizing GOALS.md for approval..."
- "GOALS.md approved, starting outlining..."
- "OUTLINE.md ready, starting drafting..."
- "Draft complete, starting review..."

## Escalation

Surface issues to the user rather than proceeding blindly:
- Multiple topics in `.drafts/` (cannot resolve which is active)
- Missing `docs/authoring-guide.md` in the consumer repo
- Unresolved discovery concerns the `goals-author` could not address
- Outline ambiguity the outline skill couldn't resolve
- Writer-reported conflict between `OUTLINE.md` and `GOALS.md`
- Any agent failures or missing prerequisites
