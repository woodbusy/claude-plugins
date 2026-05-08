# Agent Development Workflow

Automated multi-agent workflow for implementing changes via worktrees. The workflow progresses through planning, implementation, parallel review, and PR creation, with artifacts in `.worktree-local/` providing continuity between agents.

## Artifacts

All artifacts live in the `.worktree-local/` directory within the worktree.

| Artifact | Purpose |
|----------|---------|
| `context.md` | Essential context on the worktree's purpose (50-200 words). Read by every agent as a starting point. |
| `context_detail.md` | Goals, scope, and constraints for the worktree (200-500 words). Read by agents that need deeper context. |
| `plan.md` | Step-by-step implementation plan. |
| `implementation_guide.md` | Summary of what was changed and why: technical approach, trade-offs, gaps, warnings, gotchas. Lets implementing agents communicate with future agents working on the same code. |
| `review_dialog.md` | Append-only log of reviewer findings, arbitration outcomes, conflict responses, human decisions on escalated conflicts, and fixer actions across review rounds. Created by `team-review` after round 1, read by reviewers (round 2) and the fixer for cross-round context. Prevents information silos between review participants. |

## Workflow Overview

```
Step 0 --> Step 1 --> Step 2 --> Step 3 --> Step 4
Manual     Plan      Implement   Review     PR
            |
       [User Approval]
```

### Step 0: Worktree Setup (Manual)

The user creates a worktree and writes `context.md` before invoking the workflow.

### Step 1: Planning

**Agent:** Planner

The Planner gathers details on goals from the user, the referenced ticket, and any other sources mentioned in `context.md`. It produces a detailed implementation plan and an expanded context document.

The Planner presents the plan to the user for approval before writing `context_detail.md`. If the user requests changes, the Planner revises the plan and asks again. The plan is approved before the Planner returns.

**Inputs:**
- `.worktree-local/context.md`
- User interaction, ticket references, other sources

**Outputs:**
- `.worktree-local/plan.md` (user-approved)
- `.worktree-local/context_detail.md`

### Step 2: Implementation

Three sub-steps run sequentially.

#### Step 2a: Code Implementation

**Agent:** Implementer

The Implementer reads the plan and determines how to group changes into logical commits. It implements the code and writes the implementation guide.

If the Implementer discovers the plan is infeasible during implementation, it may make minor adaptations and document them. For significant deviations that change scope or approach, it stops and reports the issue to the orchestrator.

**Inputs:** `plan.md`, `context_detail.md`
**Outputs:** Code changes (one or more commits), `implementation_guide.md`

The Implementer runs relevant pre-commit checks (rspec, rubocop, shellcheck, terraform fmt, etc.) as part of its work.

#### Step 2b: Guide Review

**Agent:** Guide Reviewer

Reviews `implementation_guide.md` for conciseness, repetition, unhelpful detail, and technical accuracy against the actual commits since `origin/main`.

**Outputs:** Findings report (concise, with line references and suggested fixes)

#### Step 2c: Guide Fixes

The orchestrator evaluates the Guide Reviewer's findings and applies fixes to `implementation_guide.md` as warranted.

### Step 3: Parallel Review (Up to 2 Rounds)

A reviewer team runs in parallel, each member focusing on a different aspect. After the team finishes a round, an **arbiter** (a fresh `reviewer-tech-lead` invocation in Arbiter Mode) inspects the findings for conflicts; conflicts are driven to convergence via a targeted re-prompt to the conflicting reviewers, and any conflicts the arbiter still cannot resolve are escalated to the user via `AskUserQuestion`. Once arbitration is complete, a shared Fixer agent addresses the combined findings (using arbitration outcomes and human decisions where they apply). This cycle runs up to 2 rounds. All reviews operate on the cumulative diff from `origin/main`. A shared `review_dialog.md` artifact accumulates findings, arbitration, conflict responses, human decisions, and fix actions across rounds, giving all participants visibility into the full review history and preventing fixes from reintroducing issues addressed in earlier rounds.

The team is chosen per change-set. The `team-review` skill inspects `git diff --name-only origin/main...HEAD` and selects reviewers based on which categories of files are touched.

| Reviewer | When it runs | Focus |
|----------|--------------|-------|
| **Tech Lead** (`reviewer-tech-lead`) | Always | Intent, correctness, simplification, documentation across the whole diff |
| **Security** (`reviewer-security`) | Any change to code, infra, or dev tooling; or security-relevant docs | Security impacts on the overall system |
| **Application** (`reviewer-application`) | App source/tests/dependency manifests changed; also runs for docs-only changes | App-code correctness, conventions, idioms, refactoring opportunities |
| **Infra Platform** (`reviewer-infra-platform`) | Production IaC changed (Terraform/Pulumi/CloudFormation, Helm, k8s, prod Dockerfiles, cloud platform config) | Resource correctness, blast radius, platform consistency, operational impact |
| **Dev Platform** (`reviewer-dev-platform`) | Local dev tooling, devcontainer, dev Dockerfiles/compose, tool-version files, dev scripts, CI/CD workflows, lint/format/hook configs | Pipeline reliability, contributor ergonomics, dev/CI parity |

Tech-lead always runs as a generalist pass; specialists provide deeper coverage where their domain is touched. Some overlap on technical correctness is intentional - it reduces the risk of any single reviewer being the sole gate.

The full path classification rules and edge cases (docs-only, security-relevant docs, prod vs. dev Dockerfiles) live in `skills/team-review/SKILL.md`.

#### Round 1

##### Step 3a: Parallel Review

The selected reviewers run in parallel and each produce a concise findings report with issues prioritized by impact.

##### Step 3b: Arbitrate Conflicts

**Agent:** `reviewer-tech-lead` (fresh invocation, distinct from the reviewer-tech-lead that participated in 3a). The arbiter task is supplied by `team-review`'s prompt templates, not baked into the agent spec.

The arbiter inspects the round's findings for **conflicts**: direct contradictions on the same code, incompatible recommended approaches to the same finding, and cross-finding tensions where one fix would step on another. It does not re-review the diff.

If the arbiter detects conflicts, the orchestrator targets a **single** re-prompt at only the conflicting reviewers with only the conflicting findings, asking each to defend, revise, or concede. The arbiter is then re-invoked to evaluate the responses and declare each conflict resolved or unresolved.

Any conflict the arbiter declares **unresolved** is escalated to the user via `AskUserQuestion`, with the conflicting positions as options plus the standard free-form "Other" override. The user's decision is authoritative for the fixer.

##### Step 3c: Fix

**Agent:** Fixer

The Fixer receives all findings from every selected reviewer, plus any **resolution directives** (from the arbiter) and **human decisions** (from escalated conflicts) recorded in `review_dialog.md`. Where a directive or decision applies to a finding, the Fixer follows that guidance over the raw finding.

It reads `implementation_guide.md` for implementation context and `context_detail.md` for goals/scope, plus diffs and code as needed.

**Default conflict-resolution priority** (when no arbitration directive applies, e.g. for tensions that didn't rise to a flagged conflict): Security > Correctness (any reviewer) > Domain-consistency (specialist concerns within their territory) > Simplification. Within the same tier, the specialist's view wins on their own turf. The Fixer documents trade-offs in `implementation_guide.md`.

**Outputs:**
- Code fixes (logically grouped commits)
- Updated `implementation_guide.md` (integrated edits, not appended sections)

The Fixer runs relevant pre-commit checks as part of its work.

#### Round 2 (If Needed)

If any reviewer in round 1 reported issues, a subset re-runs in parallel:

- Tech-lead always re-runs.
- Security re-runs if it ran in round 1.
- Each specialist re-runs only if it had findings in round 1.

Resumed reviewers focus on the Fixer's new changes rather than re-reviewing the full diff. Each either approves or reports remaining issues. The same arbitration sub-flow then runs against the round 2 findings before the Fixer is invoked one more time. If issues persist after round 2, the orchestrator reports them to the user rather than continuing to loop.

### Step 4: PR Creation

**Agent:** PR Author

Distills `implementation_guide.md` into a reviewer-friendly PR description and creates a draft PR.

## Skills and Agent Specs

The workflow is implemented as **skills** (user-invocable via slash commands) and **agent specs** (role definitions that describe sub-agents). Agents define philosophy and outputs, not rigid procedures - this makes them flexible enough to recover from partial failures or be reinvoked for missing artifacts.

Skills reference agents by name; Claude matches agents to tasks based on their `name` and `description` frontmatter.

| Skill | Purpose | Agents Used |
|-------|---------|-------------|
| `workflow-resume` | Resume/re-enter in-progress workflow - assesses state, prompts user, loops `workflow-start` | (delegates to `workflow-start`) |
| `workflow-start` | Full pipeline orchestrator | `planner`, `implementer`, `guide-reviewer`, `pr-author` (+ calls `team-review`) |
| `team-review` | Step 3 only | `reviewer-tech-lead`, `reviewer-security`, `reviewer-application`, `reviewer-infra-platform`, `reviewer-dev-platform`, `fixer` (selected per change-set) |

### Skill and Agent Relationships

```
workflow-resume (resume/re-enter)
└── loops:
    ├── assesses artifact state, gathers user intent
    └── calls skill: workflow-start
        ├── uses agent: planner (includes user approval gate)
        ├── uses agent: implementer
        ├── uses agent: guide-reviewer
        ├── calls skill: team-review
        │   ├── classifies diff -> selects reviewer team
        │   ├── uses agents (parallel): reviewer-tech-lead
        │   │                            reviewer-security        (if applicable)
        │   │                            reviewer-application     (if applicable)
        │   │                            reviewer-infra-platform  (if applicable)
        │   │                            reviewer-dev-platform    (if applicable)
        │   ├── uses agent: reviewer-tech-lead (fresh, with arbiter-detect prompt)
        │   ├── (if conflicts) re-prompts conflicting reviewers in parallel
        │   │                  with conflict-response prompt
        │   ├── uses agent: reviewer-tech-lead (fresh, with arbiter-resolve prompt)
        │   ├── (if unresolved) escalates via AskUserQuestion
        │   ├── uses agent: fixer
        │   ├── (round 2 if needed)
        │   ├── resumes agents (parallel): reviewer-tech-lead
        │   │                               reviewer-security      (if it ran in round 1)
        │   │                               specialists with prior findings
        │   │                               (review-followup prompt)
        │   ├── uses agent: reviewer-tech-lead (fresh; round 2 arbitration sub-flow)
        │   └── uses agent: fixer (if needed)
        └── uses agent: pr-author
```

### Prerequisite Validation

All agent prerequisites are validated via SubagentStart hooks (defined in `hooks/hooks.json`). The hooks call `scripts/validate-prerequisites.sh` to check that required files and commits exist before the agent starts. The `team-review` skill additionally validates its own prerequisites before launching reviewers.

## Orchestrator Responsibilities

The `workflow-start` skill manages the full pipeline:

1. **Status updates:** Provides brief updates to the user between major steps
2. **Escalation:** Surfaces unresolved issues to the user (plan deviation from implementer, persistent review findings after 2 rounds)

Review-specific orchestration (parallel launch, round management) is owned by `team-review`, not the top-level orchestrator. This keeps `team-review` self-contained for standalone use.
