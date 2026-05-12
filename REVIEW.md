## Functionality

### Critical — reviewer agents are missing the Write tool.
All four reviewer agents (reviewer-substance, reviewer-form-fit, reviewer-implementer, reviewer-tech-writer) declare tools: Read, Grep, Glob, Bash. But every critique prompt template instructs them to write a file (e.g. discover-standard/prompts/critique-substance.md:32 — "Write your critique to .drafts/<topic>/discovery-critique/substance.md"; same pattern for form-fit, implementer, tech-writer in both discovery and review). Without Write, the agents would have to shell out via Bash heredocs, which violates global guidance. As designed, the discover-standard and review-standard sub-flows will silently break or produce nonstandard side effects on first run. Fix: add Write to all four reviewer agent specs.

### Minor — workflow-resume isn't really a resume.
skills/workflow-resume/SKILL.md delegates to /workflow-start, but workflow-start always runs Steps 1→4 sequentially with no branching on existing artifacts. The parenthetical "For targeted re-runs … invoke the specific stage skill directly" is the actual escape hatch. Either teach workflow-start to skip stages whose outputs already exist (matching the language in the resume SKILL's Step 3), or have workflow-resume route directly to the relevant stage skill based on user intent instead of going through workflow-start.

### Minor — no early check for the consumer repo's docs/authoring-guide.md.
Every stage agent reads it. If absent, all four stages fail late and inscrutably. A startup check inside workflow-start (or in validate-prerequisites.sh discover-standard) would fail fast.

### Minor — goals-author hook is a no-op.
hooks/hooks.json:5 registers a hook for goals-author; the script's goals-author) case is empty (intentionally — initial mode has no prereq). Either delete the hook entry or note it as a placeholder.

### Minor — goals-author lacks Edit.
Refinement and revision modes are documented as "Edit GOALS.md in place." With only Write, the agent must rewrite the whole file each time. Functional but suboptimal; consider adding Edit.

## Documentation accuracy

### Both CLAUDE.md files misstate where the outlining gate lives.
- Root CLAUDE.md:39: "owns the user-approval gates after discovery and outlining"
- Plugin CLAUDE.md:36: "The user-approval gates after discovery and outlining live in workflow-start, not in the stage skills themselves"

But docs/standard-writing-workflow.md:191 and skills/workflow-start/SKILL.md:18-22 both say the outlining gate lives inside /outline-standard (variant comparison + user direction is the gate). workflow-start owns only the discovery gate. Fix both CLAUDE.md files.

### Both CLAUDE.md files undersell reviewer-tech-writer's mode-driven nature.
They describe reviewer-substance and reviewer-implementer as "dual-mode" and frame reviewer-tech-writer only as "the always-on arbiter." But reviewer-tech-writer is itself mode-driven (review mode in draft critique with full context, plus two arbiter sub-calls in both critiques), as its agent spec and docs/standard-writing-workflow.md make clear. Worth a one-sentence correction so the asymmetry doesn't mislead.

### workflow-resume SKILL.md state list places the published standard under .drafts/<topic>/.
Lines 14–21 list standards/<topic>-standard.md — drafted underneath "Check what artifacts exist in .drafts/<topic>/". The standard actually lives at the repo root in standards/. Cosmetic but confusing.

### "Security standard" framing vs. claimed generic applicability.
CLAUDE.md:37 in the plugin says the prompts are "generic enough to apply to any standards repo," but goals-author, writer, reviewer-substance, reviewer-implementer, and the outliners all open with "You are an experienced security engineer." A non-security user might be surprised. Either soften the role openings to "experienced engineer / writer of technical standards," or own the security bias and note it as the default tone.

## Coherence and completeness

The pipeline is internally coherent: GOALS.md → OUTLINE.md → published standard, with Departure candidates / Areas of uncertainty as the explicit hand-off contract from form-fit critique to the outliners and the variation axis. The cold-read constraint for substance + implementer in draft mode is reinforced in three places (agent spec, prompt template, skill text) — good defense in depth. The arbitration sub-flow is duplicated between discover-standard and review-standard SKILL.md files, but each version is correctly tailored (directives flow to goals-author vs. to the orchestrator), so the duplication reads as intentional self-containment rather than drift.

The docs/standard-writing-workflow.md file is the most accurate authority for the workflow; the two CLAUDE.md files should be reconciled against it.

## Summary of recommended fixes (in priority order)

1. Add Write to all four reviewer agents — blocks functionality.
2. Fix the "outlining gate" claim in root CLAUDE.md:39 and plugin CLAUDE.md:36.
3. Clarify reviewer-tech-writer mode-driven nature in both CLAUDE.md files.
4. Decide on workflow-resume semantics — either make workflow-start resume-aware, or route resume to specific stage skills directly.
5. Cosmetic: fix the standards/ placement in workflow-resume artifact list; delete or document the empty goals-author hook; add an early docs/authoring-guide.md existence check; consider broadening the security-engineer framing.
