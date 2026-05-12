---
name: discover-standard
description: Discover the goals and scope of a new technical standard, produce GOALS.md as a reviewable specification, then run a three-lens parallel critique (substance, form-fit, implementer) with arbitration before revising. Use when the user wants to begin or refine work on a standard's goals. Assumes a workspace at .drafts/<topic>/ (created if missing). Trigger on "discover a standard", "start a standard", "define goals for a standard", "draft GOALS.md", "refine GOALS.md", "new standard".
---

# Discover Standard

Produces and refines `.drafts/<topic>/GOALS.md` — the specification that drives the rest of the standards authoring pipeline. `GOALS.md` is the primary point of human review; get the substance right here and later steps fall into place.

The standards in this repo share one voice — principle-based by default, with prescriptive and risk-tiered devices used sparingly. Discovery's job is two-fold: nail the substance, and surface where this particular standard will want to depart from the principle-based default so the outline phase can vary intentionally.

The reviewer agents and the goals-author skill are pure role definitions. The per-invocation task — that this is a discovery critique, not a draft critique; that goals-author should run in initial / refinement / revision mode — is supplied by the prompt templates under `prompts/`. Whenever this skill says "send the *<name>* prompt to <agent>", read that template, substitute the listed placeholders, and pass the result as the Agent prompt. When it says "send the *<name>* prompt to the **goals-author skill**", do the same but invoke via the `Skill` tool with the substituted prompt as `args` — goals-author runs in the main loop so it can interview the user via `AskUserQuestion`.

## Workspace

```
.drafts/<topic>/
├── GOALS.md
├── discovery-critique/
│   ├── substance.md
│   ├── form-fit.md
│   └── implementer.md
└── discovery-critique-dialog.md
```

## Prompt templates

All under `${CLAUDE_PLUGIN_ROOT}/skills/discover-standard/prompts/`:

| Template | Purpose | Placeholders |
|----------|---------|--------------|
| `goals-initial.md` | Tell the goals-author skill to interview and write `GOALS.md` from scratch | none |
| `goals-refine.md` | Re-invoke the goals-author skill to refine an existing `GOALS.md` per user direction | `{{USER_DIRECTION}}` |
| `critique-substance.md` | Initial discovery critique by `reviewer-substance` | none |
| `critique-form-fit.md` | Initial discovery critique by `reviewer-form-fit` | none |
| `critique-implementer.md` | Initial discovery critique by `reviewer-implementer` | none |
| `arbiter-detect.md` | Inspect the round's findings for conflicts | `{{ROUND_FINDINGS}}` |
| `conflict-response.md` | Reviewer defends/revises/concedes a conflicting finding | `{{CONFLICT_BLOCKS}}` |
| `arbiter-resolve.md` | Arbiter declares each conflict resolved/unresolved after responses | `{{ARBITRATION_OUTPUT}}`, `{{CONFLICT_RESPONSES}}` |
| `goals-revise.md` | Goals-author skill revises GOALS.md in response to findings + directives | `{{ROUND_FINDINGS}}`, `{{ARBITRATION_DIRECTIVES}}` |

The arbiter is always a **fresh `reviewer-tech-writer` invocation** — even though `reviewer-tech-writer` does not participate as a reviewer in discovery, it serves as the always-on arbiter for both critique sub-flows.

## Workflow

### Step 1: Validate Prerequisites

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-prerequisites.sh discover-standard`. If it fails, relay the error to the user and stop.

### Step 2: Goals Authoring or Refinement

Locate the active `.drafts/<topic>/` directory.

- **If `.drafts/<topic>/GOALS.md` does NOT exist:** Send the **`goals-initial.md`** prompt to the **goals-author skill** (invoke via the `Skill` tool with the prompt as `args`). The skill will interview the user and write `GOALS.md`. (It chooses the slug as part of the interview.)
- **If `.drafts/<topic>/GOALS.md` exists** and the user invoked this skill to refine it: Ask the user what they want to change, then send the **`goals-refine.md`** prompt to the **goals-author skill** with `{{USER_DIRECTION}}` substituted.

Confirm `GOALS.md` was written. If the user only wanted refinement and not another critique, stop here and report.

### Step 3: Parallel Critique

Send the three critique prompts to the three reviewers **in parallel** (single message, three Agent tool calls):

- `reviewer-substance` ← `critique-substance.md`
- `reviewer-form-fit` ← `critique-form-fit.md`
- `reviewer-implementer` ← `critique-implementer.md`

Wait for all three to complete. Each writes its critique to `.drafts/<topic>/discovery-critique/<lens>.md`. Note which reviewers reported issues vs. responded "No issues found."

If every reviewer responds "No issues found," skip to Step 6.

Otherwise, create `.drafts/<topic>/discovery-critique-dialog.md`:

```markdown
# Discovery Critique Dialog

## Round 1

### Findings
[Paste combined findings from all three reviewers, grouped by reviewer name. Include the form-fit reviewer's Departure candidates / Areas of uncertainty as part of its block.]
```

### Step 4: Arbitrate Conflicts

Run the [Arbitration Sub-flow](#arbitration-sub-flow) against the round's findings.

When the sub-flow returns, all conflicts (if any) have been resolved with a recorded directive or escalated to the user with a recorded human decision.

### Step 5: Revise

Re-invoke the **goals-author skill** with the **`goals-revise.md`** prompt as `args` (via the `Skill` tool). Substitute `{{ROUND_FINDINGS}}` with the round's findings and `{{ARBITRATION_DIRECTIVES}}` with any Resolution Directives or Human Decisions recorded in `discovery-critique-dialog.md` (or "(none)" if no conflicts surfaced). Reference `.drafts/<topic>/discovery-critique-dialog.md` in the args so the skill knows where to read full context.

The goals-author skill edits `GOALS.md` in place (merging form-fit findings into **Departure candidates** and **Areas of uncertainty** along the way) and returns a revision summary.

Append the revision summary to the dialog file:

```
### Revisions
[Paste goals-author's revision summary here]
```

### Step 6: Report Results

Report to the user:
- Which reviewers found issues and which approved cleanly
- Whether any conflicts were arbitrated, and how they were resolved (auto-resolved by arbiter vs. escalated to human)
- Summary of revisions made by the goals-author skill
- Any remaining concerns the agent could not address (rare; flag if present)

Tell the user that `GOALS.md` is ready for `/outline-standard` (unless they want another iteration; re-running this skill on an existing `GOALS.md` is cheap).

## Arbitration Sub-flow

This sub-flow runs after the parallel critique produces findings, before the goals-author skill is re-invoked for revision. Goal: detect conflicts between reviewers' findings, drive them to convergence with one targeted re-prompt, and escalate to the human if convergence fails.

The sub-flow appends sections to the active round in `.drafts/<topic>/discovery-critique-dialog.md`.

### Sub-step A: Detect Conflicts

Send the **`arbiter-detect.md`** prompt to a fresh `reviewer-tech-writer` invocation. Substitute `{{ROUND_FINDINGS}}` with the round's `### Findings` content.

Append the arbiter's output:

```
### Arbitration
[Arbiter's output — either "No conflicts found." or numbered Conflict blocks]
```

If the arbiter reports **no conflicts**, the sub-flow is complete — return to the calling step.

### Sub-step B: Targeted Conflict Re-prompt

For each conflict, identify the reviewers involved. Re-prompt **only those reviewers**, **only with the conflicting findings**.

Send the **`conflict-response.md`** prompt to each conflicting reviewer **in parallel**. For each reviewer, substitute `{{CONFLICT_BLOCKS}}` with the arbiter's conflict block(s) involving that reviewer.

Append their responses:

```
### Conflict Responses
[Paste each conflicting reviewer's response, grouped by reviewer name]
```

### Sub-step C: Resolution Check

Send the **`arbiter-resolve.md`** prompt to a fresh `reviewer-tech-writer` invocation. Substitute `{{ARBITRATION_OUTPUT}}` with the prior `### Arbitration` content and `{{CONFLICT_RESPONSES}}` with the prior `### Conflict Responses` content.

Append the arbiter's verdict:

```
### Resolution
[Arbiter's per-conflict Resolved/Unresolved verdicts and directives]
```

If every conflict is **Resolved**, the sub-flow is complete. The Resolution Directives are what the goals-author skill should follow for those findings.

### Sub-step D: Escalate Unresolved Conflicts

For each conflict the arbiter marked **Unresolved**, present it to the user via `AskUserQuestion`:

- **Question:** brief restatement of the conflict.
- **Options:** Reviewer A's position, Reviewer B's position (and additional reviewers if entangled). The standard "Other" option is provided automatically by `AskUserQuestion`.

Append the user's decisions:

```
### Human Decision
**Conflict 1:** [user's choice or free-form text, attributed to the user]
```

Human Decisions are authoritative for the goals-author skill — they take precedence over the original findings and reviewer responses on the conflicting items.
