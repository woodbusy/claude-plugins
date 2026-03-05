---
name: linear
description: Use this skill when working with Linear issues for the Pacific Motions project. Activates on requests like "create a Linear issue", "update issue PACMO-N", "view Linear issue", or "draft issue description". Provides project-specific context and content quality guidelines. Relies on the system `linear-cli` skill for CLI command syntax.
---

# Linear Issues Management

This skill guides content quality and workflow for Linear issues in this project. For CLI command syntax and GraphQL API usage, refer to the system `linear-cli` skill.

## Project Configuration

This project uses:
- **Workspace**: `woodbusy-labs`
- **Team ID**: `PACMO`

Issues are identified as `PACMO-N` (e.g., `PACMO-42`).

## Core Capabilities

### 1. Creating Issues

**Title Guidelines:**
- Concise and descriptive (50-70 characters ideal)
- Start with an action verb when appropriate (Add, Fix, Update, Refactor, Remove)
- Include the component or area affected

**Issue Body Guidelines:**
- Omit optional sections unless there is essential information that doesn't fit elsewhere
- Do not repeat information already present elsewhere in the body
- The summary should be 2-4 sentences describing what needs to be done and the goal

**Commands:**
```bash
# Create issue (use --description-file for multi-line content)
cat > /tmp/issue.md <<'EOF'
## Summary
...
EOF
linear issue create --title "Title here" --description-file /tmp/issue.md
```

### 2. Viewing Issues

```bash
# View a specific issue
linear issue view PACMO-42

# List open issues sorted by priority
linear issue list

# List with filters
linear issue list --state "In Progress"
```

### 3. Updating Issues

```bash
# Update title
linear issue update PACMO-42 --title "New title"

# Update description (use --description-file for multi-line)
linear issue update PACMO-42 --description-file /tmp/updated.md

# Update state
linear issue update PACMO-42 --state "In Progress"
```

## Workflow Best Practices

### When Creating Issues

1. **Gather information when necessary**: Analyze what the user has provided and identify missing essential details. Ask a minimal set of focused questions — do not ask unnecessary questions.
2. **Use the appropriate template** from the patterns below.

### When Updating Issues

1. **Gather information when necessary**: Same principle — only ask what's needed.
2. **Update state** to reflect current status.
3. **Keep acceptance criteria current**: If requirements change, update them.

## Issue Templates

### Bug Report

```markdown
## Summary
[Brief description of the bug and its impact]

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Acceptance Criteria
- [ ] Bug is reproducible
- [ ] Root cause identified
- [ ] Fix implemented and tested
- [ ] No regressions introduced
```

### Feature Request

```markdown
## Summary
[What feature is being requested and why it's valuable]

## Background [Optional]
[Additional context, links to discussions, or related issues — only if not covered in summary]

## Acceptance Criteria
- [ ] [Specific outcome 1]
- [ ] [Specific outcome 2]
- [ ] Tests written/updated if necessary

## Technical Notes [Optional]
[Implementation hints, architectural considerations, or constraints]

## Resources [Optional]
[Links to docs, designs, or reference materials]
```

### Task / Chore

```markdown
## Summary
[What needs to be done and the goals of the change]

## Background [Optional]
[Additional context — only if not covered in summary]

## Acceptance Criteria
- [ ] Specific, testable outcome 1
- [ ] Specific, testable outcome 2

## Technical Notes [Optional]
[Implementation hints or constraints]
```

## Tips

- **Be specific**: Vague issues lead to confusion and delays
- **Include the why**: Help future readers understand the motivation
- **Keep it focused**: One issue per problem or feature
- **Make it scannable**: Use formatting to aid quick reading
- **Update as you learn**: Issues are living documents during development
