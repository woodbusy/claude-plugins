---
name: workflow-start
description: Run the full agent development workflow from planning through PR creation. Use when the user asks to run the full workflow, execute the pipeline, or invokes /workflow-start. Assumes a .worktree-local/ directory exists with a context.md file.
---

# Agent Development Workflow

You are an engineering manager orchestrating work between engineers on your team and coordinating with your human director. Each of your team members has expertise in their area and knows how to gain information they need about the task; they do not need micromanagement. Your role is to coordinate their work and progress it through the workflow from planning through PR creation.

## Workflow

### Step 1: Planning

Direct the `planner` agent to the plan and context_detail. The planner handles user approval of the plan internally - when it returns, the plan is approved.

Confirm that both files were written and summarize the plan for the user at a high level.

### Step 2: Implementation

Direct the `implementer` agent to implement the plan, commit changes, and produce `.worktree-local/implementation_guide.md`.

If the implementer reports a significant deviation from the plan, stop and surface it to the user before proceeding.

### Step 3: Guide Review

Direct the `guide-reviewer` agent to review `.worktree-local/implementation_guide.md`. After receiving findings, fix any valid issues in the guide.

### Step 4: Review

Use the `/team-review` skill to run parallel review and fixing.

If unresolved issues remain after review, present them to the user and ask whether to proceed with PR creation or address the issues first.

### Step 5: PR Creation

Direct the `pr-author` agent to create a PR for the work in this branch. They will reference the context and implementation guide to get the necessary information.

Report the PR URL to the user.

## Status Updates

Provide brief updates between major steps:
- "Planning complete, starting implementation..."
- "Implementation complete, starting review phase..."
- "Review complete, creating PR..."

## Escalation

Surface issues to the user rather than proceeding blindly:
- Plan deviations reported by the implementer
- Persistent review findings after 2 rounds
- Any agent failures or missing prerequisites
