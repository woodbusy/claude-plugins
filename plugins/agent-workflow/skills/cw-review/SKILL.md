---
name: cw-review
description: Run parallel code review on existing commits in a worktree. Use when the user asks to review implementation, run reviewers, or invokes /cw-review. Launches three reviewer agents in parallel (correctness, simplification, security), collects findings, runs a fixer agent, and optionally repeats for a second round. Assumes commits exist on the branch and .worktree-local/ contains context_detail.md and implementation_guide.md.
---

# Parallel Code Review

Run parallel code review on existing commits, fix issues, and optionally repeat.

## Workflow

### Step 1: Validate Prerequisites

Verify that the branch has commits ahead of `origin/main` and that `.worktree-local/context_detail.md` and `.worktree-local/implementation_guide.md` both exist. If any prerequisite is missing, stop and inform the user. Suggest running `/cw-implement-plan` first if the files are missing.

### Step 2: Round 1 — Parallel Review

Launch three reviewer agents **in parallel**:

- Use the `reviewer-correctness` agent to review for correctness
- Use the `reviewer-simplification` agent to review for simplification opportunities
- Use the `reviewer-security` agent to review for security concerns

Wait for all three to complete. Collect their findings reports.

### Step 3: Round 1 — Evaluate Findings

If all three reviewers report "No issues found," skip to Step 7.

Otherwise, combine the findings from all reviewers into a single prompt and use the `fixer` agent to address them.

### Step 4: Round 2 — Parallel Re-review (If Needed)

If any reviewer reported issues in round 1, resume all three reviewer agents for a second round. Each reviewer will focus on the Fixer's changes rather than re-reviewing the full diff (this behavior is defined in the reviewer agent specs).

Wait for all three to complete. Collect their findings reports.

### Step 5: Round 2 — Evaluate Findings

If all three reviewers approve, skip to Step 7.

Otherwise, combine the remaining findings and use the `fixer` agent one more time.

### Step 6: Escalate Persistent Issues

If issues were reported in round 2 and the Fixer has already run twice, do NOT loop again. Collect any remaining concerns and report them to the user in Step 7.

### Step 7: Report Results

Report to the user:
- Number of review rounds completed
- Summary of issues found and fixed
- Any remaining issues that could not be resolved (if applicable)
