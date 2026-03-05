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

Two reviewers run in parallel, each focusing on a different aspect. A shared Fixer agent addresses their combined findings. This cycle runs up to 2 rounds. All reviews operate on the cumulative diff from `origin/main`.

#### Round 1

##### Step 3a: Parallel Review

| Reviewer | Focus |
|----------|-------|
| **Technical Reviewer** | Correctness of the implementation and simplification opportunities |
| **Security Reviewer** | Security impacts of the changes on the overall system |

Each reviewer produces a concise findings report with issues prioritized by impact.

##### Step 3b: Fix

**Agent:** Fixer

The Fixer receives all findings from both reviewers. It reads `implementation_guide.md` for implementation context and `context_detail.md` for goals/scope, plus diffs and code as needed.

**Conflict resolution priority:** Security > Correctness > Simplification. When findings conflict, the higher-priority concern wins. The Fixer documents the trade-off in `implementation_guide.md`.

**Outputs:**
- Code fixes (logically grouped commits)
- Updated `implementation_guide.md` (integrated edits, not appended sections)

The Fixer runs relevant pre-commit checks as part of its work.

#### Round 2 (If Needed)

If either reviewer in round 1 reported issues, both reviewers run again in parallel, resumed with their round 1 context preserved. They focus on the Fixer's new changes rather than re-reviewing the full diff.

Each reviewer either approves or reports remaining issues. If issues remain, the Fixer runs one more time. If issues persist after round 2, the orchestrator reports them to the user rather than continuing to loop.

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
| `team-review` | Step 3 only | `reviewer-technical`, `reviewer-security`, `fixer` |

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
        │   ├── uses agents (parallel): reviewer-technical
        │   │                            reviewer-security
        │   ├── uses agent: fixer
        │   ├── (round 2 if needed)
        │   ├── resumes agents (parallel): reviewer-technical
        │   │                               reviewer-security
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
