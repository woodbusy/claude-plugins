# Standard Writing Workflow

Automated multi-agent workflow for authoring technical standards. The workflow progresses through discovery, outlining, drafting, and review, with artifacts in `.drafts/<topic>/` providing continuity between stages and the final published standard at `standards/<topic>-standard.md`.

Standards in the target repo share one voice — principle-based by default, with prescriptive and risk-tiered devices used sparingly where a specific requirement needs them. The pipeline's job is to surface where each particular standard wants to depart from that default *early* (in discovery and outlining), so by the time drafting begins the design is settled.

## Artifacts

All intermediate artifacts live in `.drafts/<topic>/` in the consumer repo. The `.drafts/` workspace is expected to be branch-ephemeral (gitignored) with a single active topic per branch. The final published standard lives in `standards/`.

| Artifact | Purpose |
|----------|---------|
| `.drafts/<topic>/GOALS.md` | Spec for the standard: purpose, scope, threats, requirement areas, prohibitions, stakeholders, inferences, and (after critique) **Departure candidates** and **Areas of uncertainty**. The contract that drives outlining and drafting. |
| `.drafts/<topic>/discovery-critique/{substance,form-fit,implementer}.md` | Per-lens critiques of `GOALS.md` produced in parallel during `/discover-standard`. |
| `.drafts/<topic>/discovery-critique-dialog.md` | Append-only log of discovery-critique findings, arbitration outcomes, conflict responses, human decisions, and `goals-author`'s revision summary. |
| `.drafts/<topic>/outlines/{principle,pragmatic,prescriptive}.md` | Three compact outlines along a flexibility axis, produced in parallel by `/outline-standard`. |
| `.drafts/<topic>/OUTLINE.md` | The user-chosen or blended outline. The structural contract that drives drafting. |
| `.drafts/<topic>/draft-critique/{substance,implementer,tech-writer}.md` | Per-role critiques of the published draft produced in parallel during `/review-standard`. |
| `.drafts/<topic>/draft-critique-dialog.md` | Append-only log of draft-critique findings, arbitration outcomes, conflict responses, and human decisions. |
| `standards/<topic>-standard.md` | The published technical standard. Output of `/draft-standard`; iteratively edited during `/review-standard`. |

## Workflow Overview

```
Step 1 -------> Step 2 -------> Step 3 -------> Step 4
Discover       Outline         Draft          Review
   |              |                              |
[User approval] [User picks variant]      [User-directed edits / loops]
```

### Step 1: Discovery

**Skill:** `discover-standard`
**Sub-skill:** `goals-author` (interviewer + writer; runs in the main loop so it can use `AskUserQuestion`)
**Agents:** `reviewer-substance`, `reviewer-form-fit`, `reviewer-implementer`, `reviewer-tech-writer` (arbiter)

The `goals-author` skill interviews the user (via `AskUserQuestion`) and writes `GOALS.md` capturing purpose, scope, threats, requirement areas, prohibitions, stakeholders, open questions, and inferences. Three reviewers then critique `GOALS.md` in parallel along orthogonal lenses:

- **Substance** — coverage, threats, scope, internal contradictions, definitions.
- **Form-fit** — where the eventual standard will want a device (prescriptive or risk-tiered) rather than principle prose; where the user's signal is weak (Areas of uncertainty).
- **Implementer** — operational cost, hand-waves, hidden cost, edge cases, ergonomic damage, ownership gaps.

Conflicts between findings are detected and resolved by a fresh `reviewer-tech-writer` arbiter (with human escalation for unresolved conflicts via `AskUserQuestion`). The `goals-author` skill is then re-invoked to revise `GOALS.md` in place, merging the form-fit findings into the **Departure candidates** and **Areas of uncertainty** sections that drive variation in the outline phase.

`goals-author` is a skill rather than an agent because subagents cannot call `AskUserQuestion`. Skills invoked via the `Skill` tool run in the main conversation loop and therefore retain user-interaction tools — necessary for the discovery interview. The reviewer roles do not interact with the user and remain agents.

**Inputs:** the consumer repo's `docs/authoring-guide.md` (the house voice); user interaction.
**Outputs:** `GOALS.md`, `discovery-critique/`, `discovery-critique-dialog.md`.

### Step 2: Outlining

**Skill:** `outline-standard`
**Agents:** `outliner-principle`, `outliner-pragmatic`, `outliner-prescriptive`

Three outliner agents produce parallel outlines of the standard along a **flexibility axis** — principle (strict), pragmatic, prescriptive. All three share the principle-based house voice; they differ only in how readily they reach for prescriptive thresholds or risk-tiered matrices. The axis is targeted at `GOALS.md`'s **Departure candidates** and **Areas of uncertainty**: where the goals are settled the outlines should converge; where the goals are open they should diverge.

The orchestrator presents a side-by-side comparison and a recommendation, then writes `OUTLINE.md` per the user's direction (pick a variant, blend several, or graft specific structural ideas).

There is no arbitration sub-flow here — the three outlines are proposals, not findings, and the user is the disambiguator by design.

**Inputs:** `GOALS.md`, the consumer repo's authoring guide and device references.
**Outputs:** `outlines/{principle,pragmatic,prescriptive}.md`, `OUTLINE.md`.

### Step 3: Drafting

**Skill:** `draft-standard`
**Agent:** `writer`

A single `writer` agent expands `GOALS.md` + `OUTLINE.md` into the full standard at `standards/<topic>-standard.md`. The writer:

- Follows `OUTLINE.md`'s section list, titles, planned tables, and design decisions faithfully.
- Holds the principle-based house voice throughout.
- Applies RFC 2119 hygiene (boilerplate in section 1, keywords only in normative sections, one normative statement per bullet, individually numbered).
- Resolves every item the outline marked "deferred to drafting" and defaults thresholds where neither input specified them.
- Returns a closing report covering resolved deferrals, defaulted thresholds, anything beyond the outline, any `OUTLINE.md` ↔ `GOALS.md` conflicts encountered, and sections needing stakeholder input.

No parallel variants — variation was settled upstream in outlining. Re-running drafting against the same `OUTLINE.md` rarely produces meaningfully different output.

**Inputs:** `GOALS.md`, `OUTLINE.md`, authoring guide, device references.
**Outputs:** `standards/<topic>-standard.md` + closing report.

### Step 4: Review

**Skill:** `review-standard`
**Agents:** `reviewer-substance`, `reviewer-implementer`, `reviewer-tech-writer`, `reviewer-tech-writer` (arbiter — fresh invocation)

Three reviewers critique the published draft in parallel along orthogonal roles:

- **Substance** (cold read) — clarity of normative language, testability, threat coverage as it reads on the page, apparent gaps, scope, definitions, evidence and audit logistics.
- **Implementer** (cold read) — hand-waves in the normative text, hidden cost, edge cases, conflicts with existing systems, ergonomic damage, defaulted thresholds, implementability cold.
- **Tech-writer** (with context — sees `OUTLINE.md` and `GOALS.md`) — voice drift, conciseness, structural adherence to `OUTLINE.md`, RFC 2119 hygiene, definitions and terminology, readability.

The two cold-read reviewers do **not** receive `GOALS.md` or `OUTLINE.md`. That mirrors how a real consumer encounters the standard and lets the reviewers genuinely notice when something feels missing or hand-wavy rather than silently filling the gap from upstream context. The tech-writer reviewer is structural and *does* see upstream context — adherence and intent-vs-voice are their job.

Conflicts are arbitrated by a fresh `reviewer-tech-writer` invocation (distinct from the one that participated as a reviewer). The orchestrator then runs its own **goals-coverage pass** — opening `GOALS.md` and walking its requirement areas, threats, and prohibitions to confirm each is addressed in the draft. The cold-read reviewers were deliberately blind to `GOALS.md`; coverage is the orchestrator's job.

Findings are presented inline with suggested action paths:

- **In-conversation edit** — small clarity, wording, or scoping fixes. Applied directly via `Edit`.
- **Re-run `/outline-standard`** — structural issues (missing section, wrong device, table that should have been prose).
- **Re-run `/discover-standard`** — substantive issues that trace back to the goals.

The skill iterates with the user on edits / upstream re-runs until they're satisfied.

**Inputs:** `standards/<topic>-standard.md`, `GOALS.md`, `OUTLINE.md`, authoring guide.
**Outputs:** `draft-critique/{substance,implementer,tech-writer}.md`, `draft-critique-dialog.md`, edits to the standard.

## Arbitration Sub-flow

Used by both `discover-standard` and `review-standard`. Goal: detect conflicts between reviewers' findings, drive them to convergence with one targeted re-prompt, and escalate to the human if convergence fails.

```
Round findings
   ↓
Arbiter detect (fresh reviewer-tech-writer)
   ↓
   ├─ "No conflicts found." → sub-flow ends
   ↓
Conflict-response prompt to conflicting reviewers (in parallel)
   ↓
Arbiter resolve (fresh reviewer-tech-writer)
   ↓
   ├─ All conflicts Resolved → directives go to the producer / orchestrator
   ↓
Escalate Unresolved conflicts via AskUserQuestion → human decisions are authoritative
```

The arbiter is always a **fresh** `reviewer-tech-writer` Agent call — even if `reviewer-tech-writer` participated as a reviewer in the round, the arbiter invocation has no prior context from that round.

## Skills and Agent Specs

The workflow is implemented as **skills** (user-invocable via slash commands) and **agent specs** (role definitions that describe sub-agents). Agents define philosophy and outputs, not rigid procedures — this makes them flexible enough to recover from partial failures or be reinvoked.

Skills reference agents by name; Claude matches agents to tasks based on their `name` and `description` frontmatter. Reviewer agents (`reviewer-substance`, `reviewer-implementer`) are dual-mode: the per-invocation prompt tells them whether they are reviewing `GOALS.md` (discovery mode) or the published draft (cold-read mode). The `goals-author` skill is similarly mode-driven via per-invocation prompts (initial / refinement / revision).

| Skill | Purpose | Agents Used |
|-------|---------|-------------|
| `workflow-resume` | Resume/re-enter in-progress workflow — assesses state, prompts user, loops `workflow-start` | (delegates to `workflow-start`) |
| `workflow-start` | Full pipeline orchestrator — sequences the four stage skills, owns user-approval gates after discovery and outlining | (delegates to stage skills) |
| `discover-standard` | Stage 1 — interview, write `GOALS.md`, three-lens critique, arbitrate, revise | sub-skill `goals-author`; agents `reviewer-substance`, `reviewer-form-fit`, `reviewer-implementer`, `reviewer-tech-writer` (arbiter) |
| `outline-standard` | Stage 2 — three parallel outline variants, user compares, write `OUTLINE.md` | `outliner-principle`, `outliner-pragmatic`, `outliner-prescriptive` |
| `draft-standard` | Stage 3 — single writer produces the standard | `writer` |
| `review-standard` | Stage 4 — three-role parallel critique, arbitrate, goals-coverage pass, iterate with user | `reviewer-substance`, `reviewer-implementer`, `reviewer-tech-writer`, `reviewer-tech-writer` (arbiter) |

### Skill and Agent Relationships

```
workflow-resume (resume/re-enter)
└── loops:
    ├── assesses .drafts/<topic>/ state, gathers user intent
    └── calls skill: workflow-start
        ├── calls skill: discover-standard
        │   ├── invokes skill: goals-author (interview + write GOALS.md, or refine)
        │   ├── uses agents (parallel): reviewer-substance
        │   │                            reviewer-form-fit
        │   │                            reviewer-implementer
        │   ├── uses agent: reviewer-tech-writer (fresh, arbiter-detect)
        │   ├── (if conflicts) re-prompts conflicting reviewers in parallel
        │   ├── uses agent: reviewer-tech-writer (fresh, arbiter-resolve)
        │   ├── (if unresolved) escalates via AskUserQuestion
        │   └── invokes skill: goals-author (revision invocation)
        ├── presents revised GOALS.md to user for approval (AskUserQuestion)
        ├── calls skill: outline-standard
        │   ├── uses agents (parallel): outliner-principle
        │   │                            outliner-pragmatic
        │   │                            outliner-prescriptive
        │   ├── side-by-side comparison + recommendation
        │   ├── asks user for direction
        │   └── writes OUTLINE.md
        ├── calls skill: draft-standard
        │   └── uses agent: writer
        └── calls skill: review-standard
            ├── uses agents (parallel): reviewer-substance       (cold read)
            │                            reviewer-implementer    (cold read)
            │                            reviewer-tech-writer    (with context)
            ├── uses agent: reviewer-tech-writer (fresh, arbiter-detect)
            ├── (if conflicts) re-prompts conflicting reviewers in parallel
            ├── uses agent: reviewer-tech-writer (fresh, arbiter-resolve)
            ├── (if unresolved) escalates via AskUserQuestion
            ├── orchestrator goals-coverage pass
            ├── presents findings with suggested action paths
            └── iterates: apply edits directly, or route back to /outline-standard or /discover-standard
```

### Prerequisite Validation

Agent prerequisites are validated via SubagentStart hooks (defined in `hooks/hooks.json`). The hooks call `scripts/validate-prerequisites.sh` to check that required files exist before the agent starts. The script resolves the active topic by locating the single `.drafts/<topic>/` directory; the workspace is branch-ephemeral so a single topic per branch is the norm. Stage skills also validate their own prerequisites at entry; the `goals-author` skill (which is not an agent) validates its own prereqs as Step 1 of its body, since hooks only fire on subagent launch. Dual-mode reviewer-agent prereqs accept either discovery-stage inputs (`GOALS.md`) or draft-stage inputs (`standards/<topic>-standard.md`), so the same hook works for both contexts.

## Orchestrator Responsibilities

The `workflow-start` skill manages the full pipeline:

1. **Status updates:** Provides brief updates to the user between major stages.
2. **User-approval gates:** Presents the revised `GOALS.md` after discovery for approval before proceeding to outlining; the outlining gate is handled inside `/outline-standard` (variant comparison + user direction is the gate); no explicit gate after drafting (the user moves into `/review-standard` directly); review iteration runs inside `/review-standard`.
3. **Escalation:** Surfaces unresolved issues to the user — discovery concerns the `goals-author` skill couldn't address, outline ambiguity, writer-reported `OUTLINE.md` ↔ `GOALS.md` conflicts.

Stage-specific orchestration (parallel launch, arbitration, revision loops) is owned by the stage skills, not the top-level orchestrator. This keeps each stage skill self-contained for standalone use.

## Consumer Repo Conventions

This plugin defers to the consumer repo for the house voice and template:

- `docs/authoring-guide.md` — the standard template, RFC 2119 conventions, file/section rules, and the principle-based house voice. Read by the `goals-author` skill (for context), the outliners (as their default voice), the writer (as the structural template), and `reviewer-tech-writer` (as the conformance reference).
- Device references — typically `docs/device-prescriptive.md` and `docs/device-risk-tiered.md` (or paths the authoring guide names). Define when and how to reach for the two devices the principle-based voice supports.
- Example standards — for tone and depth calibration. Optional but useful.

The plugin's prompt templates reference these paths generically; if the consumer repo organizes them differently, the prompts may need light adjustment.
