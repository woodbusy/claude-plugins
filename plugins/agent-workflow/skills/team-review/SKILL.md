---
name: team-review
description: Run parallel code review on existing commits in a worktree. Use when the user asks to review implementation, run reviewers, or invokes /team-review. Inspects the diff to choose a reviewer team (tech-lead and security always run on non-trivial changes; application, infra-platform, and dev-platform specialists are launched when their domains are touched), runs them in parallel, fixes findings, and optionally repeats. Assumes commits exist on the branch and .worktree-local/ contains context_detail.md and implementation_guide.md.
---

# Parallel Code Review

Choose a reviewer team based on what changed, run them in parallel, fix issues, and optionally repeat.

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

### Step 3: Round 1 - Parallel Review

Launch all selected reviewers **in parallel** (single message, multiple Agent tool calls). Each reviewer reads the same inputs (`context_detail.md`, `implementation_guide.md`, the diff) and produces a findings report.

Wait for all to complete. Collect their findings reports and note which reviewers reported issues vs. approved ("No issues found.").

### Step 4: Round 1 - Evaluate Findings

If every reviewer reports "No issues found," skip to Step 8.

Otherwise, create `.worktree-local/review_dialog.md` with this structure:

```
# Review Dialog

## Round 1

### Findings
[Paste combined findings from all reviewers, grouped by reviewer name]
```

Combine the findings into a single prompt and use the `fixer` agent to address them. Include `.worktree-local/review_dialog.md` as input so the fixer has the full dialog context.

After the fixer returns, append the fixer's reported fix summary under the Round 1 section of `review_dialog.md`:

```
### Fix Actions
[Paste fixer's fix summary here]
```

### Step 5: Round 2 - Parallel Re-review (If Needed)

If any reviewer reported issues in round 1, append a `## Round 2` header to `review_dialog.md` before resuming reviewers.

Choose the round 2 reviewer set:

- Always re-run `reviewer-tech-lead`.
- Re-run `reviewer-security` if it ran in round 1.
- Re-run any specialist (`reviewer-application`, `reviewer-infra-platform`, `reviewer-dev-platform`) that **reported findings in round 1**. Specialists that approved in round 1 do not re-run.

Resume those reviewers in parallel for a second round. Instruct each to read `.worktree-local/review_dialog.md` for accumulated context on what was found and fixed in round 1. Each reviewer focuses on the Fixer's changes rather than re-reviewing the full diff (this behavior is defined in the reviewer agent specs).

Wait for all to complete. Append `### Findings` with the new findings to the Round 2 section of `review_dialog.md`.

### Step 6: Round 2 - Evaluate Findings

If every round 2 reviewer approves, skip to Step 8.

Otherwise, combine the remaining findings and use the `fixer` agent one more time, including `.worktree-local/review_dialog.md` as input.

After the fixer returns, append the fixer's fix summary under `### Fix Actions` in the Round 2 section of `review_dialog.md`.

### Step 7: Escalate Persistent Issues

If issues were reported in round 2 and the Fixer has already run twice, do NOT loop again. Collect any remaining concerns and report them to the user in Step 8.

### Step 8: Report Results

Report to the user:
- Which reviewers were selected and why
- Number of review rounds completed
- Summary of issues found and fixed
- Any remaining issues that could not be resolved (if applicable)
