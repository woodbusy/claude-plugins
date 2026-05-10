# Plan-review initial prompt template

Sent to a reviewer agent for its first pass on the plan. This is a **plan review**, not a code review — there is no diff yet.

---

Conduct a **plan review** of the proposed work. No code has been written yet; you are reviewing the plan and the surrounding context for issues that would be cheaper to fix now than after implementation.

## Inputs to read

- `.worktree-local/context.md` — branch goal and references
- `.worktree-local/context_detail.md` — goals, scope, constraints
- `.worktree-local/plan.md` — the implementation plan to review
- The working tree (read-only) — to ground the plan in the existing codebase

There is no diff and no `implementation_guide.md` — those come later.

## What to look for

Apply the priorities from your role spec, but to the **plan and context** rather than to code that exists. Flag things that are cheaper to fix at this stage:

- **Intent and scope** — does the plan actually deliver what `context_detail.md` describes? Are there gaps between stated goals and proposed steps? Is the scope right (too narrow, too broad, missing deliverables)?
- **Approach soundness** — is the proposed approach reasonable given the codebase? Will it work? Are there better-trodden paths the plan ignores? Does it conflict with existing conventions or architecture?
- **Risks the plan does not address** — edge cases, failure modes, data migrations, rollout concerns, dependencies the plan glosses over.
- **Domain-specific concerns within your role** — e.g. security/auth implications for the security reviewer, IaC blast radius for infra-platform, contributor/CI pipeline impact for dev-platform, app conventions for application.
- **Constraints that conflict** — the plan proposes something that violates a stated constraint or an obvious project norm.

Skip pure prose nits and anything an automated linter would catch. Focus on issues that change *what gets built* or *how*.

## What to produce

A concise findings report. Prioritize by impact. Each finding should reference the part of the plan or context it concerns (section name or short quote is fine — there are no line numbers in markdown to cite).

Use the finding format defined in your role spec (`### [severity] title` with **File:** / **Issue:** / **Suggestion:**). For the **File:** line, use `plan.md#section` or `context_detail.md#section` (e.g. `plan.md#step-3` or `plan.md` if it's about the plan as a whole).

If you have no findings, respond exactly with "No issues found."

Do not invent findings to appear thorough.
