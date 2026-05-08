---
name: team-review
description: Run parallel code review on existing commits in a worktree. Use when the user asks to review implementation, run reviewers, or invokes /team-review. Inspects the diff to choose a reviewer team (tech-lead and security always run on non-trivial changes; application, infra-platform, and dev-platform specialists are launched when their domains are touched), runs them in parallel, arbitrates conflicts between findings, fixes the resulting issues, and optionally repeats. Assumes commits exist on the branch and .worktree-local/ contains context_detail.md and implementation_guide.md.
---

# Parallel Code Review

Choose a reviewer team based on what changed, run them in parallel, arbitrate conflicts between their findings, fix issues, and optionally repeat.

The reviewer agents are pure role definitions. The per-invocation task — what to review, what output to produce — is supplied by the prompt templates under `prompts/`. Whenever this skill says "send the *<name>* prompt to <agent>", read that template, substitute the listed placeholders, and pass the result as the Agent prompt.

## Prompt templates

All under `plugins/agent-workflow/skills/team-review/prompts/`:

| Template | Purpose | Placeholders |
|----------|---------|--------------|
| `review-initial.md` | Initial parallel review (round 1) | none |
| `review-followup.md` | Focused re-review of the Fixer's changes (round 2) | none |
| `arbiter-detect.md` | Inspect a round's findings for conflicts | `{{ROUND_FINDINGS}}` |
| `conflict-response.md` | Reviewer defends/revises/concedes a conflicting finding | `{{CONFLICT_BLOCKS}}` |
| `arbiter-resolve.md` | Arbiter declares each conflict resolved/unresolved after reviewer responses | `{{ARBITRATION_OUTPUT}}`, `{{CONFLICT_RESPONSES}}` |

The arbiter is always a **fresh invocation of `reviewer-tech-lead`** — even if `reviewer-tech-lead` participated in the round's review, this is a new Agent call without the prior reviewer's context.

## Workflow

### Step 1: Validate Prerequisites

Run `bash plugins/agent-workflow/scripts/validate-prerequisites.sh team-review`. If it fails, relay the error to the user and stop.

### Step 2: Choose the Reviewer Team

Get the list of changed files:

```
git diff --name-only origin/main...HEAD
```

Classify each path into at most one bucket using the rules below (top match wins). Then assemble the reviewer set per the "Reviewer set" rules.

#### Path classification rules (evaluated in order)

1. **Dev-platform** (matches → enable `reviewer-dev-platform`):
   - `Dockerfile.dev*`, `**/Dockerfile.dev*`, `**/dev.Dockerfile`
   - `.devcontainer/**`
   - `docker-compose.dev.*`, `docker-compose.override.*`, `**/dev/docker-compose*.y*ml`
   - `.mise.toml`, `mise.local.toml`, `.tool-versions`, `.nvmrc`, `.ruby-version`, `.python-version`, `.node-version`
   - `bin/dev`, `bin/setup`, `bin/bootstrap`, `scripts/dev/**`, `scripts/setup/**`
   - `.github/workflows/**`, `.gitlab-ci.yml`, `.circleci/**`, `azure-pipelines*.yml`, `buildkite/**`, `.buildkite/**`
   - `Makefile`, `**/Makefile`, `justfile`, `Justfile`
   - `.pre-commit-config.yaml`, `lefthook.yml`, `lefthook.yaml`, `.husky/**`
   - `.editorconfig`, `.eslintrc*`, `.prettier*`, `.rubocop*.yml`, `ruff.toml`, `.flake8`, `.stylelintrc*`, `.markdownlint*`, `.yamllint*`, `tsconfig*.json` (when used as lint/type config), `.golangci*.yml`

2. **Infra-platform** (matches → enable `reviewer-infra-platform`):
   - `*.tf`, `*.tfvars`, `*.tfvars.json`, `terraform/**`, `tofu/**`
   - `pulumi/**`, `Pulumi*.yaml`
   - `cloudformation/**`, `*.cfn.y*ml`, `*.cloudformation.y*ml`
   - `helm/**`, `charts/**`
   - `k8s/**`, `kubernetes/**`, `manifests/**`, `*.k8s.y*ml`
   - `Dockerfile`, `**/Dockerfile` (any Dockerfile NOT already matched as dev-platform above)
   - `docker-compose.y*ml`, `**/docker-compose.y*ml` (any compose file NOT already matched as dev-platform)
   - `fly.toml`, `serverless.y*ml`, `render.y*ml`, `app.json` (Heroku-style), `sst.config.*`, `wrangler.toml`, `vercel.json`, `netlify.toml`, `.do/**` (DigitalOcean App Platform)

3. **Application** (matches → enable `reviewer-application`):
   - Any source/test code (any extension typically used for app code in this repo: `.rb`, `.py`, `.js`, `.ts`, `.tsx`, `.jsx`, `.go`, `.rs`, `.java`, `.kt`, `.swift`, `.cs`, `.cpp`, `.c`, `.h`, `.hpp`, `.scala`, `.ex`, `.exs`, `.erl`, `.php`, `.sql`, `.graphql`, `.gql`, `.proto`, etc.)
   - Tests under `test/**`, `tests/**`, `spec/**`, `__tests__/**`, `*_test.*`, `*_spec.*`
   - Dependency manifests and lockfiles: `package.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Gemfile`, `Gemfile.lock`, `go.mod`, `go.sum`, `requirements*.txt`, `pyproject.toml`, `poetry.lock`, `uv.lock`, `Pipfile`, `Pipfile.lock`, `Cargo.toml`, `Cargo.lock`, `composer.json`, `composer.lock`, `mix.exs`, `mix.lock`, `pubspec.yaml`, `pubspec.lock`

4. **Docs** (does not enable a specialist by itself):
   - `*.md`, `*.mdx`, `*.txt`, `*.rst`, `*.adoc`
   - `docs/**`, `doc/**`
   - `README*`, `CHANGELOG*`, `CONTRIBUTING*`, `AUTHORS*`, `LICENSE*`, `NOTICE*`, `CODEOWNERS`

5. **Other** (no specialist enabled): anything not matched above (e.g. `.gitignore`, repo metadata, asset files). Tech lead and security still cover these.

If the same change-set hits multiple buckets, all matched specialists are enabled.

#### Reviewer set

- **`reviewer-tech-lead`**: always run.
- **`reviewer-security`**: run unless the change is **docs-only AND not security-relevant**.
  - "Docs-only" = every changed file fell into the Docs bucket (no Application, Infra-platform, Dev-platform, or Other matches).
  - "Security-relevant docs" = any changed path's name or directory contains a security marker, case-insensitive: `security`, `threat`, `auth`, `secret`, `vuln`, or matches files like `SECURITY.md`, `THREAT_MODEL*`, `docs/security/**`, `docs/threat*/**`. If any changed doc looks security-relevant, run security.
- **`reviewer-application`**: run if any path matched the Application bucket.
- **`reviewer-infra-platform`**: run if any path matched the Infra-platform bucket.
- **`reviewer-dev-platform`**: run if any path matched the Dev-platform bucket.
- **Docs-only special case**: when the change is docs-only, also enable `reviewer-application` (docs typically describe app behavior, and the app reviewer is the closest specialist for prose accuracy). Tech-lead always runs; security per the rule above.

Briefly tell the user which reviewers were selected and why (one short line, e.g. "Selected: tech-lead, security, application, dev-platform — diff touches app code and CI workflows.").

### Step 3: Round 1 — Parallel Review

Send the **`review-initial.md`** prompt to every selected reviewer **in parallel** (single message, multiple Agent tool calls).

Wait for all to complete. Note which reviewers reported issues vs. responded "No issues found."

If every reviewer reports "No issues found," skip directly to Step 8.

Otherwise, create `.worktree-local/review_dialog.md`:

```
# Review Dialog

## Round 1

### Findings
[Paste combined findings from all reviewers, grouped by reviewer name]
```

### Step 4: Round 1 — Arbitrate Conflicts

Run the [Arbitration Sub-flow](#arbitration-sub-flow) against the round 1 findings, with `## Round 1` as the active round section in `review_dialog.md`.

When the sub-flow returns, all conflicts (if any) have been resolved with a recorded directive or escalated to the user with a recorded human decision.

### Step 5: Round 1 — Fix

Combine the round 1 findings into a single prompt for the `fixer` agent. If the arbitration sub-flow recorded any **Resolution Directives** or **Human Decisions** in `review_dialog.md`, include them prominently — they take precedence over the raw conflicting findings. Pass `.worktree-local/review_dialog.md` to the fixer for full context.

After the fixer returns, append its fix summary under the Round 1 section of `review_dialog.md`:

```
### Fix Actions
[Paste fixer's fix summary here]
```

### Step 6: Round 2 — Parallel Re-review (If Needed)

If any reviewer reported issues in round 1, append a `## Round 2` header to `review_dialog.md`.

Choose the round 2 reviewer set:

- Always re-run `reviewer-tech-lead`.
- Re-run `reviewer-security` if it ran in round 1.
- Re-run any specialist (`reviewer-application`, `reviewer-infra-platform`, `reviewer-dev-platform`) that **reported findings in round 1**. Specialists that approved in round 1 do not re-run.

Send the **`review-followup.md`** prompt to those reviewers **in parallel**.

Wait for all to complete. Append `### Findings` with the new findings to the Round 2 section of `review_dialog.md`.

If every round 2 reviewer responds "No issues found," skip to Step 8.

### Step 7: Round 2 — Arbitrate and Fix

Run the [Arbitration Sub-flow](#arbitration-sub-flow) against round 2 findings, with `## Round 2` as the active round section.

After arbitration completes, send the round 2 findings (with any resolution directives or human decisions) to the `fixer` agent one more time, passing `.worktree-local/review_dialog.md` as input.

After the fixer returns, append its fix summary under `### Fix Actions` in the Round 2 section of `review_dialog.md`.

If issues were reported in round 2 and the Fixer has already run twice, do NOT loop again. Collect any remaining concerns and report them to the user in Step 8.

### Step 8: Report Results

Report to the user:
- Which reviewers were selected and why
- Number of review rounds completed
- Whether any conflicts were arbitrated, and how they were resolved (auto-resolved by arbiter vs. escalated to human)
- Summary of issues found and fixed
- Any remaining issues that could not be resolved (if applicable)

## Arbitration Sub-flow

This sub-flow runs after a round's parallel review produces findings, before the Fixer is invoked. Goal: detect conflicts between reviewers' findings, drive them to convergence with one targeted re-prompt, and escalate to the human if convergence fails.

The sub-flow operates on the **active round section** in `.worktree-local/review_dialog.md` (`## Round 1` or `## Round 2`). All sub-sections written below are appended under that round's header.

### Sub-step A: Detect Conflicts

Send the **`arbiter-detect.md`** prompt to a fresh `reviewer-tech-lead` invocation. Substitute `{{ROUND_FINDINGS}}` with the active round's `### Findings` content.

Append the arbiter's output under the active round section:

```
### Arbitration
[Arbiter's output — either "No conflicts found." or numbered Conflict blocks]
```

If the arbiter reports **no conflicts**, the sub-flow is complete — return to the calling step.

### Sub-step B: Targeted Conflict Re-prompt

For each conflict, identify the reviewers involved. Re-prompt **only those reviewers**, **only with the conflicting findings** (not the full diff or other findings).

Send the **`conflict-response.md`** prompt to each conflicting reviewer **in parallel**. For each reviewer, substitute `{{CONFLICT_BLOCKS}}` with the arbiter's conflict block(s) involving that reviewer (their finding plus the conflicting comment(s) from the other reviewer(s)).

Append their responses under the active round section:

```
### Conflict Responses
[Paste each conflicting reviewer's response, grouped by reviewer name]
```

### Sub-step C: Resolution Check

Send the **`arbiter-resolve.md`** prompt to a fresh `reviewer-tech-lead` invocation. Substitute `{{ARBITRATION_OUTPUT}}` with the prior `### Arbitration` content and `{{CONFLICT_RESPONSES}}` with the prior `### Conflict Responses` content.

Append the arbiter's verdict under the active round section:

```
### Resolution
[Arbiter's per-conflict Resolved/Unresolved verdicts and directives]
```

If every conflict is **Resolved**, the sub-flow is complete. The Resolution Directives are what the fixer should follow for those findings.

### Sub-step D: Escalate Unresolved Conflicts

For each conflict the arbiter marked **Unresolved**, present it to the user via `AskUserQuestion`.

Per question:
- **Question:** brief restatement of the conflict.
- **Options:**
  1. Reviewer A's position (with that reviewer's name and a one-line summary of their finding/stance).
  2. Reviewer B's position (with that reviewer's name and a one-line summary of their finding/stance).
  3. (If 3+ reviewers are involved in the same conflict, include each as an option.)
- The standard "Other" option is provided automatically by `AskUserQuestion` and lets the user supply a free-form override.

Append the user's decisions under the active round section:

```
### Human Decision
**Conflict 1:** [user's choice or free-form text, attributed to the user]
[Repeat per escalated conflict]
```

Human Decisions are authoritative for the fixer — they take precedence over the original findings and any reviewer responses on the conflicting items.
