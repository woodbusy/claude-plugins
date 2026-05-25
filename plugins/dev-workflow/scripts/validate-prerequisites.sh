#!/usr/bin/env bash
set -euo pipefail

NAME="$1"

check_file() {
  if [ ! -f "$1" ]; then
    echo "ERROR: Required file '$1' not found. $2" >&2
    exit 1
  fi
}

check_commits_ahead() {
  local count
  if ! count="$(git rev-list --count origin/main..HEAD 2>/dev/null)"; then
    echo "ERROR: Cannot compare with origin/main (remote not found or not fetched). $1" >&2
    exit 1
  fi
  if [ "$count" -eq 0 ]; then
    echo "ERROR: No commits ahead of origin/main. $1" >&2
    exit 1
  fi
}

case "$NAME" in
  planner)
    check_file ".worktree-local/context.md" \
      "Create a worktree with a context.md file first."
    ;;
  implementer)
    check_file ".worktree-local/context_detail.md" \
      "Run the planner first."
    check_file ".worktree-local/plan.md" \
      "Run the planner first."
    ;;
  plan-review)
    check_file ".worktree-local/context_detail.md" \
      "Run the planner first."
    check_file ".worktree-local/plan.md" \
      "Run the planner first."
    ;;
  team-review)
    check_commits_ahead "Run the implementer first."
    check_file ".worktree-local/context_detail.md" \
      "Run the implementer first."
    check_file ".worktree-local/implementation_guide.md" \
      "Run the implementer first."
    ;;
  fixer)
    check_commits_ahead "Run the implementer first."
    check_file ".worktree-local/context_detail.md" \
      "Run the implementer first."
    check_file ".worktree-local/implementation_guide.md" \
      "Run the implementer first."
    ;;
  reviewer-tech-lead | reviewer-security | reviewer-application | reviewer-infra-platform | reviewer-dev-platform)
    check_file ".worktree-local/context_detail.md" \
      "Run the planner first."
    if [ -f ".worktree-local/implementation_guide.md" ]; then
      check_commits_ahead "Run the implementer first."
    elif [ ! -f ".worktree-local/plan.md" ]; then
      echo "ERROR: Reviewer needs either plan.md (for plan review) or implementation_guide.md + commits (for code review). Run the planner or implementer first." >&2
      exit 1
    fi
    ;;
  guide-reviewer)
    check_commits_ahead "Run the implementer first."
    check_file ".worktree-local/implementation_guide.md" \
      "Run the implementer first."
    ;;
  pr-author)
    check_commits_ahead "Run the implementer first."
    check_file ".worktree-local/implementation_guide.md" \
      "Run the implementer first."
    ;;
  *)
    echo "ERROR: Unknown name '$NAME'" >&2
    exit 1
    ;;
esac
