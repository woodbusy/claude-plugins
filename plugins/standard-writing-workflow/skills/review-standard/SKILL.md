---
name: review-standard
description: Review a freshly drafted technical standard through three parallel reviewers (substance, implementer, tech-writer), arbitrate conflicts, and present synthesized findings the user can act on. Use when the published standard exists and the user wants critique before shipping. Trigger on "review the standard", "review the draft", "critique the standard", "get reviewer feedback", "next step after the draft".
---

# Review Standard

Sits between `/draft-standard` and final publishing. Reads `standards/<topic>-standard.md` together with the upstream `GOALS.md` and `OUTLINE.md`, then spawns three independent reviewers in parallel — `reviewer-substance` and `reviewer-implementer` (both reading cold), and `reviewer-tech-writer` (with full context). Arbitrates conflicts, runs a goals-coverage pass, synthesizes everything into a findings list the user can act on.

**The two cold-read reviewers read only the published standard and the authoring guide** — not `GOALS.md` or `OUTLINE.md`. That mirrors how a real consumer encounters the standard and lets the reviewers genuinely notice when something feels missing or hand-wavy rather than silently filling the gap from upstream context. The tech-writer reviewer is structural and *does* see `OUTLINE.md` and `GOALS.md` — adherence and intent-vs-voice are their job.

The reviewer agents are pure role definitions. The per-invocation task — that this is a draft critique, not a discovery critique — is supplied by the prompt templates under `prompts/`.

## Workspace

```
.drafts/<topic>/
├── GOALS.md                          (input — context for tech-writer + orchestrator)
├── OUTLINE.md                        (input — structural ground truth for tech-writer)
├── draft-critique/
│   ├── substance.md
│   ├── implementer.md
│   └── tech-writer.md
└── draft-critique-dialog.md

standards/<topic>-standard.md         (input — the draft under review)
```

## Prompt templates

All under `${CLAUDE_PLUGIN_ROOT}/skills/review-standard/prompts/`:

| Template | Purpose | Placeholders |
|----------|---------|--------------|
| `critique-substance.md` | Cold-read draft critique by `reviewer-substance` | none |
| `critique-implementer.md` | Cold-read draft critique by `reviewer-implementer` | none |
| `critique-tech-writer.md` | Draft critique by `reviewer-tech-writer` (with context) | none |
| `arbiter-detect.md` | Inspect the round's findings for conflicts | `{{ROUND_FINDINGS}}` |
| `conflict-response.md` | Reviewer defends/revises/concedes a conflicting finding | `{{CONFLICT_BLOCKS}}` |
| `arbiter-resolve.md` | Arbiter declares each conflict resolved/unresolved | `{{ARBITRATION_OUTPUT}}`, `{{CONFLICT_RESPONSES}}` |

The arbiter is always a **fresh `reviewer-tech-writer` invocation** — distinct from the one that participated as a reviewer. Even though `reviewer-tech-writer` reads the draft as a reviewer, the arbiter invocation is a fresh sub-agent without prior context from this round.

## Workflow

### Step 1: Validate Prerequisites

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-prerequisites.sh review-standard`. If it fails, relay the error to the user and stop.

Confirm `GOALS.md` and `OUTLINE.md` are present (warn the user if either is missing — the cold-read reviewers don't need them, but the tech-writer reviewer's outline-adherence check and the orchestrator's goals-coverage pass will be weaker). If `OUTLINE.md` changed after the draft was written, ask the user whether to re-run `/draft-standard` first.

### Step 2: Parallel Critique

Send the three critique prompts to the three reviewers **in parallel** (single message, three Agent tool calls):

- `reviewer-substance` ← `critique-substance.md` (cold read)
- `reviewer-implementer` ← `critique-implementer.md` (cold read)
- `reviewer-tech-writer` ← `critique-tech-writer.md` (with context)

Each writes its critique to `.drafts/<topic>/draft-critique/<role>.md`. Note which reviewers reported issues vs. responded "No issues found."

If every reviewer responds "No issues found," skip to Step 4 (still do the goals-coverage pass).

Otherwise, create `.drafts/<topic>/draft-critique-dialog.md`:

```markdown
# Draft Critique Dialog

## Round 1

### Findings
[Paste combined findings from all three reviewers, grouped by reviewer name]
```

### Step 3: Arbitrate Conflicts

Run the [Arbitration Sub-flow](#arbitration-sub-flow) against the round's findings.

When the sub-flow returns, all conflicts (if any) have been resolved with a recorded directive or escalated to the user with a recorded human decision.

### Step 4: Goals-Coverage Pass

Open `GOALS.md` and walk its requirement areas, threats, and prohibitions, confirming each is addressed in the draft. The cold-read reviewers were deliberately blind to `GOALS.md`, so coverage is the orchestrator's job. Correlate where you can: if `GOALS.md` names a threat and `reviewer-substance` flagged ambiguity in the same area, that's a high-confidence problem.

### Step 5: Present Findings

Present an inline summary in chat covering:

- **Writing and structure** (from `tech-writer.md`) — voice drift, verbosity/terseness imbalance, structural deviations from `OUTLINE.md`, organizational improvements
- **Substance concerns** (from `substance.md`) — ambiguous normative language, non-testable requirements, evidence problems, things a cold reader couldn't audit against
- **Implementer concerns** (from `implementer.md`) — hand-waves, hidden cost, edge cases, ergonomic damage, ownership gaps in the prose as written
- **Goals-coverage gaps** (from your own pass) — items in `GOALS.md` not visibly addressed in the draft. Note when a cold-read reviewer's "this feels missing" finding lines up with an actual goals gap (strong signal) vs. when the standard covers the goal but unclearly (a clarity problem, not a coverage problem)
- **Cross-role agreement** — places two or three reviewers flagged the same thing. Highest-confidence findings
- **Arbitration outcomes** — any conflicts resolved by the arbiter or escalated to the user
- **Open questions for the user** — consolidated, deduplicated list

For each finding, suggest an action path:

- **In-conversation edit** — small clarity, wording, or scoping fixes. Apply directly via `Edit` when the user gives direction.
- **Re-run `/outline-standard`** — structural issues (missing section, wrong device, table that should have been prose). Fix in `OUTLINE.md` and re-draft.
- **Re-run `/discover-standard`** — substantive issues that trace back to the goals (missing requirement area, scope ambiguity, unstated threat).

Be honest about severity. A clean review is a real verdict.

### Step 6: Iterate with the User

Wait for the user's direction. Then:

- **Apply in-conversation edits** to `standards/<topic>-standard.md` via `Edit`. Show diffs.
- **Hand off** to `/outline-standard` or `/discover-standard` when the user wants to fix upstream.
- **Re-run this skill** after edits if the user wants another pass — re-spawning is cheap.

Keep iterating until the user says the draft is ready.

## Arbitration Sub-flow

This sub-flow runs after the parallel critique produces findings. Goal: detect conflicts between reviewers' findings, drive them to convergence with one targeted re-prompt, and escalate to the human if convergence fails.

The sub-flow appends sections to the active round in `.drafts/<topic>/draft-critique-dialog.md`.

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

If every conflict is **Resolved**, the sub-flow is complete. The Resolution Directives are guidance the orchestrator will follow when proposing edits (or recommending upstream re-runs) on the affected findings.

### Sub-step D: Escalate Unresolved Conflicts

For each conflict the arbiter marked **Unresolved**, present it to the user via `AskUserQuestion`. Options carry each reviewer's position; the standard "Other" option lets the user supply a free-form override.

Append the user's decisions:

```
### Human Decision
**Conflict 1:** [user's choice or free-form text]
```

Human Decisions are authoritative — they take precedence over the original findings and reviewer responses on the conflicting items when the orchestrator decides what edits to propose.
