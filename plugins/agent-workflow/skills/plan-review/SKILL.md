---
name: plan-review
description: Run a complexity-tiered review of a plan before implementation begins. Use when the user asks to review a plan, vet the planner's output, or invokes /plan-review. A fresh reviewer-tech-lead triages tier (Low/Moderate/High) and selects reviewers; the selected team reviews plan.md and context_detail.md in parallel, conflicts are arbitrated, and the planner revises. Assumes .worktree-local/ contains plan.md and context_detail.md.
---

# Plan Review

Catch requirements misunderstandings and design issues at the planning stage, before implementation. A fresh `reviewer-tech-lead` invocation acts as Triage Tech Lead — it reads the plan, classifies complexity, and recommends a reviewer set. The selected team reviews `plan.md` and `context_detail.md` in parallel, conflicts are arbitrated by another fresh `reviewer-tech-lead`, and the planner revises in response to findings.

The reviewer agents are pure role definitions. The per-invocation task — that this is a plan review, not a code review — is supplied by the prompt templates under `prompts/`. Whenever this skill says "send the *<name>* prompt to <agent>", read that template, substitute the listed placeholders, and pass the result as the Agent prompt.

## Complexity tiers

| Tier | Reviewer set | Rounds | Arbitration |
|------|--------------|--------|-------------|
| **Low** | Tech Lead only | 1 | N/A (single reviewer) |
| **Moderate** | Tech Lead + Triage's specialists | 1 | Yes; unresolved → user |
| **High** | Tech Lead + Security + domain specialists the plan touches | Up to 2 | Yes each round; unresolved → user |

The High floor is `tech-lead + security` plus whichever domain specialists (`reviewer-application`, `reviewer-infra-platform`, `reviewer-dev-platform`) the plan touches. Application is not forced in on plans that don't involve app code.

## Prompt templates

All under `plugins/agent-workflow/skills/plan-review/prompts/`:

| Template | Purpose | Placeholders |
|----------|---------|--------------|
| `triage.md` | Triage Tech Lead classifies tier and picks reviewers | none |
| `review-initial.md` | Initial parallel plan review (round 1) | none |
| `review-followup.md` | Focused re-review after the planner's revision (round 2, High only) | none |
| `arbiter-detect.md` | Inspect a round's findings for conflicts | `{{ROUND_FINDINGS}}` |
| `conflict-response.md` | Reviewer defends/revises/concedes a conflicting finding | `{{CONFLICT_BLOCKS}}` |
| `arbiter-resolve.md` | Arbiter declares each conflict resolved/unresolved after reviewer responses | `{{ARBITRATION_OUTPUT}}`, `{{CONFLICT_RESPONSES}}` |
| `plan-fix.md` | Planner revises plan/context in response to findings + directives | `{{ROUND_FINDINGS}}`, `{{ARBITRATION_DIRECTIVES}}` |

The Triage Tech Lead and the Arbiter are always **fresh invocations of `reviewer-tech-lead`** — even if `reviewer-tech-lead` participated in a round's review, each is a new Agent call without prior context.

## Workflow

### Step 1: Validate Prerequisites

Run `bash plugins/agent-workflow/scripts/validate-prerequisites.sh plan-review`. If it fails, relay the error to the user and stop.

### Step 2: Triage

Send the **`triage.md`** prompt to a fresh `reviewer-tech-lead` invocation.

The triage call writes `.worktree-local/plan_review_plan.md` with the following structure:

```markdown
# Plan Review Plan

**Tier:** Low | Moderate | High
**Reviewers:** reviewer-tech-lead, reviewer-security, reviewer-application, ...
**Rationale:** [1-3 sentences explaining the tier and reviewer choices]
```

Read it back. If the file is malformed or missing fields, ask the triage tech lead to retry once. Briefly tell the user the tier, reviewers, and rationale (one short line, e.g. "Plan review tier: Moderate. Team: tech-lead, security, infra-platform — plan introduces new IAM bindings and cross-account access.").

### Step 3: Round 1 — Parallel Review

Send the **`review-initial.md`** prompt to every reviewer listed in `plan_review_plan.md` **in parallel** (single message, multiple Agent tool calls).

Wait for all to complete. Note which reviewers reported issues vs. responded "No issues found."

If every reviewer reports "No issues found," skip directly to Step 7.

Otherwise, create `.worktree-local/plan_review_dialog.md`:

```
# Plan Review Dialog

## Round 1

### Findings
[Paste combined findings from all reviewers, grouped by reviewer name]
```

### Step 4: Round 1 — Arbitrate Conflicts (Moderate and High only)

Skip this step if the tier is **Low** (only one reviewer ran, so no conflicts are possible).

Run the [Arbitration Sub-flow](#arbitration-sub-flow) against the round 1 findings, with `## Round 1` as the active round section in `plan_review_dialog.md`.

When the sub-flow returns, all conflicts (if any) have been resolved with a recorded directive or escalated to the user with a recorded human decision.

### Step 5: Round 1 — Plan Fix

Re-invoke the `planner` agent with the **`plan-fix.md`** prompt. Substitute `{{ROUND_FINDINGS}}` with the round 1 findings and `{{ARBITRATION_DIRECTIVES}}` with any Resolution Directives or Human Decisions recorded in `plan_review_dialog.md` (or "(none)" if no arbitration ran). Pass `.worktree-local/plan_review_dialog.md` to the planner for full context.

The planner edits `plan.md` and (if needed) `context_detail.md` in place.

After the planner returns, append its revision summary under the Round 1 section of `plan_review_dialog.md`:

```
### Plan Revisions
[Paste planner's revision summary here]
```

### Step 6: Round 2 — Parallel Re-review (High tier only, if needed)

Skip this step if the tier is **Low** or **Moderate**. For **High**, only proceed if any reviewer reported issues in round 1.

Append a `## Round 2` header to `plan_review_dialog.md`.

Re-run **every reviewer that participated in round 1**, regardless of whether they reported findings. A reviewer whose domain was in scope for round 1 stays in scope for round 2: the planner's revisions could affect their domain even if they had no issues with the original plan.

Send the **`review-followup.md`** prompt to those reviewers **in parallel**.

Wait for all to complete. Append `### Findings` with the new findings to the Round 2 section of `plan_review_dialog.md`.

If every round 2 reviewer responds "No issues found," skip to Step 7.

Otherwise run the [Arbitration Sub-flow](#arbitration-sub-flow) against round 2 findings, with `## Round 2` as the active round section.

Re-invoke the `planner` once more with the **`plan-fix.md`** prompt for round 2 findings + directives. Append its revision summary under `### Plan Revisions` in the Round 2 section.

If issues were reported in round 2 and the planner has already revised twice, do NOT loop again. Collect any remaining concerns and report them in Step 7.

### Step 7: Report Results

Report to the user:
- Tier and reviewer team chosen by triage, with rationale
- Number of review rounds completed
- Whether any conflicts were arbitrated, and how they were resolved (auto-resolved by arbiter vs. escalated to human)
- Summary of findings and revisions
- Any remaining concerns the planner could not address (if applicable)

## Arbitration Sub-flow

This sub-flow runs after a round's parallel review produces findings, before the planner is re-invoked. Goal: detect conflicts between reviewers' findings, drive them to convergence with one targeted re-prompt, and escalate to the human if convergence fails.

The sub-flow operates on the **active round section** in `.worktree-local/plan_review_dialog.md` (`## Round 1` or `## Round 2`). All sub-sections written below are appended under that round's header.

### Sub-step A: Detect Conflicts

Send the **`arbiter-detect.md`** prompt to a fresh `reviewer-tech-lead` invocation. Substitute `{{ROUND_FINDINGS}}` with the active round's `### Findings` content.

Append the arbiter's output under the active round section:

```
### Arbitration
[Arbiter's output — either "No conflicts found." or numbered Conflict blocks]
```

If the arbiter reports **no conflicts**, the sub-flow is complete — return to the calling step.

### Sub-step B: Targeted Conflict Re-prompt

For each conflict, identify the reviewers involved. Re-prompt **only those reviewers**, **only with the conflicting findings**.

Send the **`conflict-response.md`** prompt to each conflicting reviewer **in parallel**. For each reviewer, substitute `{{CONFLICT_BLOCKS}}` with the arbiter's conflict block(s) involving that reviewer.

Append their responses under the active round section:

```
### Conflict Responses
[Paste each conflicting reviewer's response, grouped by reviewer name]
```

### Sub-step C: Resolution Check

Send the **`arbiter-resolve.md`** prompt to a fresh `reviewer-tech-lead` invocation. Substitute `{{ARBITRATION_OUTPUT}}` with the prior `### Arbitration` content and `{{CONFLICT_RESPONSES}}` with the prior `### Conflict Responses` content.

Append the arbiter's verdict under the active round section:

```
### Resolution
[Arbiter's per-conflict Resolved/Unresolved verdicts and directives]
```

If every conflict is **Resolved**, the sub-flow is complete. The Resolution Directives are what the planner should follow for those findings.

### Sub-step D: Escalate Unresolved Conflicts

For each conflict the arbiter marked **Unresolved**, present it to the user via `AskUserQuestion`.

Per question:
- **Question:** brief restatement of the conflict.
- **Options:**
  1. Reviewer A's position (with that reviewer's name and a one-line summary).
  2. Reviewer B's position (with that reviewer's name and a one-line summary).
  3. (If 3+ reviewers are involved in the same conflict, include each as an option.)
- The standard "Other" option is provided automatically by `AskUserQuestion` and lets the user supply a free-form override.

Append the user's decisions under the active round section:

```
### Human Decision
**Conflict 1:** [user's choice or free-form text, attributed to the user]
[Repeat per escalated conflict]
```

Human Decisions are authoritative for the planner — they take precedence over the original findings and any reviewer responses on the conflicting items.
