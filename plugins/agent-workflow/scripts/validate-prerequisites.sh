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
  reviewer-technical)
    check_commits_ahead "Run the implementer first."
    check_file ".worktree-local/context_detail.md" \
      "Run the implementer first."
    check_file ".worktree-local/implementation_guide.md" \
      "Run the implementer first."
    ;;
  reviewer-security)
    check_commits_ahead "Run the implementer first."
    check_file ".worktree-local/context_detail.md" \
      "Run the implementer first."
    check_file ".worktree-local/implementation_guide.md" \
      "Run the implementer first."
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
