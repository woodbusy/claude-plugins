# Initial review prompt template

Sent to a reviewer agent for its first pass on the diff.

---

Conduct a code review of the changes on this branch.

## Inputs to read

- `.worktree-local/context_detail.md` — goals, scope, constraints
- `.worktree-local/implementation_guide.md` — what was changed and why
- The cumulative commits and diff from `origin/main`:
  - `git log origin/main...HEAD`
  - `git diff origin/main...HEAD`
- Any other files in the working tree you need to understand the change

## What to produce

A concise findings report covering the priorities defined in your role spec. Prioritize by impact. Cite a specific `file:line` for every finding and include a concrete suggested fix.

Use the finding format defined in your role spec (`### [severity] title` with **File:** / **Issue:** / **Suggestion:**).

If you have no findings, respond exactly with "No issues found."

Do not report style nits or issues handled by automated linters. Do not invent findings to appear thorough.
