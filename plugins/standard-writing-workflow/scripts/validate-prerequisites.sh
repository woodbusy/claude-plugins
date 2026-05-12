#!/usr/bin/env bash
set -euo pipefail

NAME="$1"

# Resolve the active topic by locating .drafts/<topic>/. The .drafts workspace
# is branch-ephemeral so a single topic per branch is the norm.
#
# Returns the topic slug on stdout, or exits with an error if not exactly one
# topic directory exists. Pass "allow_none" to permit zero topics (for
# goals-author initial mode).
resolve_topic() {
  local mode="${1:-require}"
  local topics=()
  if [ -d ".drafts" ]; then
    for d in .drafts/*/; do
      [ -d "$d" ] || continue
      topics+=("$(basename "$d")")
    done
  fi

  if [ "${#topics[@]}" -eq 0 ]; then
    if [ "$mode" = "allow_none" ]; then
      echo ""
      return 0
    fi
    echo "ERROR: No .drafts/<topic>/ directory found. Run /discover-standard first." >&2
    exit 1
  fi

  if [ "${#topics[@]}" -gt 1 ]; then
    echo "ERROR: Multiple topics found under .drafts/ (${topics[*]}). The .drafts workspace is expected to be branch-ephemeral with a single active topic. Remove unused topic directories before continuing." >&2
    exit 1
  fi

  echo "${topics[0]}"
}

check_file() {
  if [ ! -f "$1" ]; then
    echo "ERROR: Required file '$1' not found. $2" >&2
    exit 1
  fi
}

# The consumer repo must define its house voice in docs/authoring-guide.md.
# All four stage agents (goals-author, outliners, writer, reviewer-tech-writer)
# read it, so we fail fast at every entry point if it's missing.
check_authoring_guide() {
  if [ ! -f "docs/authoring-guide.md" ]; then
    echo "ERROR: Required file 'docs/authoring-guide.md' not found. The standard-writing-workflow plugin expects the consumer repo to describe its house voice in docs/authoring-guide.md. Create that file (see plugins/standard-writing-workflow/docs/standard-writing-workflow.md for what it should contain) before running the workflow." >&2
    exit 1
  fi
}

case "$NAME" in
  goals-author)
    # No artifact prerequisite — initial mode creates .drafts/<slug>/ from scratch.
    # If a topic already exists, that's fine (refinement / revision modes).
    # We do enforce the authoring guide, since goals-author reads it.
    check_authoring_guide
    ;;
  outliner-principle | outliner-pragmatic | outliner-prescriptive)
    check_authoring_guide
    topic="$(resolve_topic)"
    check_file ".drafts/$topic/GOALS.md" \
      "Run /discover-standard first."
    ;;
  writer)
    check_authoring_guide
    topic="$(resolve_topic)"
    check_file ".drafts/$topic/GOALS.md" \
      "Run /discover-standard first."
    check_file ".drafts/$topic/OUTLINE.md" \
      "Run /outline-standard first."
    ;;
  reviewer-substance | reviewer-implementer)
    # Dual-mode: discovery critique (needs GOALS.md) or draft critique
    # (needs the published standard). Accept either.
    topic="$(resolve_topic)"
    if [ ! -f ".drafts/$topic/GOALS.md" ] && [ ! -f "standards/$topic-standard.md" ]; then
      echo "ERROR: Reviewer needs either .drafts/$topic/GOALS.md (for discovery critique) or standards/$topic-standard.md (for draft critique). Run /discover-standard or /draft-standard first." >&2
      exit 1
    fi
    ;;
  reviewer-form-fit)
    # Discovery-only reviewer.
    topic="$(resolve_topic)"
    check_file ".drafts/$topic/GOALS.md" \
      "Run /discover-standard first."
    ;;
  reviewer-tech-writer)
    # Reviewer in draft mode (needs the standard + authoring guide) or arbiter
    # in either mode (needs GOALS.md at minimum, since both critiques start
    # from there).
    check_authoring_guide
    topic="$(resolve_topic)"
    if [ ! -f ".drafts/$topic/GOALS.md" ] && [ ! -f "standards/$topic-standard.md" ]; then
      echo "ERROR: reviewer-tech-writer needs either .drafts/$topic/GOALS.md (for discovery-critique arbitration) or standards/$topic-standard.md (for draft critique or its arbitration). Run /discover-standard or /draft-standard first." >&2
      exit 1
    fi
    ;;
  workflow-start)
    # Pipeline entry point. Authoring guide is the only universal precondition
    # — the resume logic inside workflow-start figures out which stage to start
    # from based on existing artifacts.
    check_authoring_guide
    ;;
  discover-standard)
    check_authoring_guide
    # Skill-level prereq. Accept either no topic (initial mode) or an existing
    # topic with GOALS.md (refinement / re-critique).
    topic="$(resolve_topic allow_none)"
    if [ -n "$topic" ] && [ ! -f ".drafts/$topic/GOALS.md" ]; then
      echo "ERROR: .drafts/$topic/ exists but contains no GOALS.md. Remove the empty directory or run goals-author manually." >&2
      exit 1
    fi
    ;;
  outline-standard)
    check_authoring_guide
    topic="$(resolve_topic)"
    check_file ".drafts/$topic/GOALS.md" \
      "Run /discover-standard first."
    ;;
  draft-standard)
    check_authoring_guide
    topic="$(resolve_topic)"
    check_file ".drafts/$topic/GOALS.md" \
      "Run /discover-standard first."
    check_file ".drafts/$topic/OUTLINE.md" \
      "Run /outline-standard first."
    ;;
  review-standard)
    check_authoring_guide
    topic="$(resolve_topic)"
    check_file "standards/$topic-standard.md" \
      "Run /draft-standard first."
    ;;
  *)
    echo "ERROR: Unknown name '$NAME'" >&2
    exit 1
    ;;
esac
