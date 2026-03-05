---
name: github-issues
description: Use this skill when creating or modifying GitHub issues. Activates on requests like "create an issue", "update issue #N", "view issue", or "draft issue description".
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
  - WebFetch
---

# GitHub Issues Management Skill

This skill helps you work with GitHub issues effectively, focusing on content quality and workflow best practices.

## Core Capabilities

### 1. Creating New Issues

When creating GitHub issues, follow this structure:

**Title Guidelines:**
- Concise and descriptive (50-70 characters ideal)
- Start with action verb when appropriate (Add, Fix, Update, Refactor)
- Include key context (component/area affected)

**Issue Body Guidelines:**
- Do not include sections or content marked as optional unless there is essential information to be conveyed in them that does not fit elsewhere
- In sections or content marked as optional, do not include information already included elsewhere in the issue body
- The summary section should consist of 2-4 sentences describing what needs to be done and the goals of the change (or a summary of the bug, in the case of a bug report)


**Commands to use:**
```bash
# Create issue interactively (will prompt for title and body)
gh issue create

# Create issue with title and body
gh issue create --title "Title here" --body "$(cat <<'EOF'
Issue content here
EOF
)"

# Create issue from a file
gh issue create --title "Title" --body-file /path/to/issue.md

# Assign labels
gh issue create --title "Title" --body "Content" --label bug,enhancement
```

### 2. Viewing Issues

```bash
# View specific issue with all details
gh issue view 123

# List all open issues
gh issue list

# List issues with filters
gh issue list --label bug
gh issue list --state all
```

### 3. Updating Issues

```bash
# Update issue title
gh issue edit 123 --title "New title"

# Update issue body
gh issue edit 123 --body "New content"

# Update from file
gh issue edit 123 --body-file /path/to/updated-content.md

# Add/remove labels
gh issue edit 123 --add-label "needs-review"
gh issue edit 123 --remove-label "in-progress"
```

### 4. Drafting Issue Content

When helping draft issue content:

1. **Ask clarifying questions** to understand:
   - What problem are we solving?
   - What does success look like?
   - Are there any constraints or technical requirements?

2. **Write clear acceptance criteria** that are:
   - Specific and measurable
   - Testable/verifiable
   - Focused on outcomes, not implementation
   - Written from user/stakeholder perspective when possible

3. **Use appropriate formatting**:
   - Checkboxes for acceptance criteria and task lists
   - Code blocks for examples or snippets
   - Links to reference materials
   - Headings to organize longer issues

## Workflow Best Practices

### When Creating Issues

1. **Ask questions to gather information when necessary**:
   - Analyze the information provided by the user about the problem or change and determine whether necessary information is missing
   - If necessary information is missing, pose a minimal set of focused questions and prompt the user. Do not ask unnecessary questions or add questions just for the sake of filling out the list.

2. **Use templates** if available:
   ```bash
   # List available issue templates
   ls .github/ISSUE_TEMPLATE/
   ```

3. **Link related items**:
   - Reference related issues: `#123`
   - Reference PRs: `#456`
   - Link to commits: `abc1234`

### When Updating Issues

1. **Ask questions to gather information when necessary**:
   - Analyze the information provided by the user about the problem or change and determine whether necessary information is missing
   - If necessary information is missing, pose a minimal set of focused questions and prompt the user. Do not ask unnecessary questions or add questions just for the sake of filling out the list.

2. **Comment on changes**: When making significant updates, add a comment explaining what changed and why

3. **Update labels** to reflect current state:
   - Remove stale labels
   - Add status labels (in-progress, blocked, needs-review)

4. **Keep acceptance criteria current**: If requirements change, update the AC and document why

## Common Patterns

### Bug Report Issue
```markdown
## Summary
[Brief description of the bug]

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

### Feature Request Issue
```markdown
## Summary
[What feature is being requested and why it's valuable]

## Background [Optional]
[Optional: Additional context, links to discussions, or related issues only.]

## Acceptance Criteria
- [ ] [Specific outcome 1]
- [ ] [Specific outcome 2]
- [ ] Tests written/updated if necessary
- [ ] Documentation updated
- [ ] Tests pass

## Technical Considerations, Background, etc.
[Optional: Architecture, dependencies, risks]

## Technical Notes [Optional]
[Optional: Implementation hints, architectural considerations, or constraints]

## Resources [Optional]
[Optional: Links to docs, designs, or reference materials]
```

### Task/Chore Issue
```markdown
## Summary
[What needs to be done and the goals of the change]

## Background [Optional]
[Optional: Additional context, links to discussions, or related issues only.]

## Acceptance Criteria
- [ ] Specific, testable outcome 1
- [ ] Specific, testable outcome 2
- [ ] Specific, testable outcome 3

## Technical Notes [Optional]
[Optional: Implementation hints, architectural considerations, or constraints]

## Resources [Optional]
[Optional: Links to docs, designs, or reference materials]
```

## Tips

- **Be specific**: Vague issues lead to confusion and delays
- **Include context**: Help future readers understand the "why"
- **Make it scannable**: Use formatting to make issues easy to skim
- **Keep it focused**: One issue per problem/feature
- **Update as you learn**: Issues are living documents during development
- **Close with references**: When closing, link to the PR or commit that resolved it

## Using This Skill

When the user asks you to work with GitHub issues:

1. **Understand the goal**: Are they creating, viewing, updating, or drafting?
2. **Gather information**: Ask questions to get the details needed
3. **Use gh CLI**: Leverage the GitHub CLI for all operations
4. **Follow templates**: Use the patterns above for consistency
5. **Validate**: Confirm the content meets the user's needs before executing

Remember: Good issues save time for everyone involved in the project!
