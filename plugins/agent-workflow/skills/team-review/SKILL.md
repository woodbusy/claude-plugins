---
name: team-review
description: Run parallel code review on existing commits in a worktree. Use when the user asks to review implementation, run reviewers, or invokes /team-review. Launches two reviewer agents in parallel (technical, security), collects findings, runs a fixer agent, and optionally repeats for a second round. Assumes commits exist on the branch and .worktree-local/ contains context_detail.md and implementation_guide.md.
---

# Parallel Code Review

Run parallel code review on existing commits, fix issues, and optionally repeat.

## Workflow

### Step 1: Validate Prerequisites

Run `bash plugins/agent-workflow/scripts/validate-prerequisites.sh team-review`. If it fails, relay the error to the user and stop.

### Step 2: Round 1 - Parallel Review

Launch two reviewer agents **in parallel**:

- Use the `reviewer-technical` agent to review for correctness and simplification
- Use the `reviewer-security` agent to review for security concerns

Wait for both to complete. Collect their findings reports.

After collecting findings, create `.worktree-local/review_dialog.md` with this structure:

```
# Review Dialog

## Round 1

### Findings
[Paste combined findings from both reviewers here]
```

### Step 3: Round 1 - Evaluate Findings

If both reviewers report "No issues found," skip to Step 7.

Otherwise, combine the findings from both reviewers into a single prompt and use the `fixer` agent to address them. Include `.worktree-local/review_dialog.md` as input so the fixer has the full dialog context.

After the fixer returns, append the fixer's reported fix summary under the Round 1 section of `review_dialog.md`:

```
### Fix Actions
[Paste fixer's fix summary here]
```

### Step 4: Round 2 - Parallel Re-review (If Needed)

If either reviewer reported issues in round 1, append a `## Round 2` header to `review_dialog.md` before resuming reviewers.

Resume both reviewer agents for a second round. Instruct each reviewer to read `.worktree-local/review_dialog.md` for accumulated context on what was found and fixed in round 1. Each reviewer will focus on the Fixer's changes rather than re-reviewing the full diff (this behavior is defined in the reviewer agent specs).

Wait for both to complete. Collect their findings reports.

After collecting round 2 findings, append `### Findings` with the new findings to the Round 2 section of `review_dialog.md`.

### Step 5: Round 2 - Evaluate Findings

If both reviewers approve, skip to Step 7.

Otherwise, combine the remaining findings and use the `fixer` agent one more time, including `.worktree-local/review_dialog.md` as input.

After the fixer returns, append the fixer's fix summary under `### Fix Actions` in the Round 2 section of `review_dialog.md`.

### Step 6: Escalate Persistent Issues

If issues were reported in round 2 and the Fixer has already run twice, do NOT loop again. Collect any remaining concerns and report them to the user in Step 7.

### Step 7: Report Results

Report to the user:
- Number of review rounds completed
- Summary of issues found and fixed
- Any remaining issues that could not be resolved (if applicable)
