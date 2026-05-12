---
name: outline-standard
description: Produce three compact outlines of a technical standard from GOALS.md along a flexibility axis (principle, pragmatic, prescriptive), surface the structural choices each makes, and help the user pick or blend a final OUTLINE.md that drafting will adhere to. Use when GOALS.md exists and the user wants to plan the structure of the standard before drafting. Trigger on "outline a standard", "outline the standard", "produce outlines for the standard", "compare outline approaches", "next step after GOALS.md".
---

# Outline Standard

Takes a finalized `GOALS.md` and produces `.drafts/<topic>/OUTLINE.md` — the structural plan that `/draft-standard` will follow. Outlines are short and compact so the user can usefully compare three along a flexibility axis without drowning in prose.

The three outlines share one voice (the principle-based house voice). They differ in how readily each reaches for a prescriptive or risk-tiered device. The flexibility axis is targeted at `GOALS.md`'s **Departure candidates** and **Areas of uncertainty** — those are the spots where the three outlines should diverge most. Sections the goals settled cleanly will look similar across all three.

Unlike `/discover-standard` and `/review-standard`, this skill has no arbitration sub-flow. The three outlines are *proposals*, not findings; the user is the disambiguator by design.

## Workspace

```
.drafts/<topic>/
├── GOALS.md             (input)
├── outlines/
│   ├── principle.md
│   ├── pragmatic.md
│   └── prescriptive.md
└── OUTLINE.md           (the chosen / blended outline)
```

## Prompt templates

Under `${CLAUDE_PLUGIN_ROOT}/skills/outline-standard/prompts/`:

| Template | Purpose | Placeholders |
|----------|---------|--------------|
| `outline-initial.md` | Tell an outliner agent what to produce. Same prompt for all three — each agent already knows its flexibility level from its role spec. | none |

## Workflow

### Step 1: Validate Prerequisites

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-prerequisites.sh outline-standard`. If it fails, relay the error to the user and stop.

Skim `GOALS.md`. If its **Departure candidates** and **Areas of uncertainty** sections are empty or stale (no critique was run, or the goals changed after the last critique), ask the user whether to re-run `/discover-standard` first. Those sections are the variation signal the outliners depend on.

### Step 2: Three Outlines in Parallel

Send the **`outline-initial.md`** prompt to the three outliner agents **in parallel** (single message, three Agent tool calls): `outliner-principle`, `outliner-pragmatic`, `outliner-prescriptive`.

Each writes its variant to `.drafts/<topic>/outlines/<variant>.md` (the agent knows its own variant slug from its role spec).

### Step 3: Compare and Recommend

Read all three outlines. Present a side-by-side comparison in chat covering:

- **Where the three agree** — sections, requirements, and structures all three converge on. These are load-bearing and will appear in the final outline regardless of which variant you start from.
- **Where they diverge** — concretely list the spots the three differ. Expect divergence at the **Departure candidates** and **Areas of uncertainty** locations in `GOALS.md`. Flag if they diverge somewhere else — that's a signal the variant agent overreached.
- **Decision points for the user** — frame each divergence as a fork the user can pick. Cite the variant and outline location.
- **Standout structural moves** — specific tables, sections, or organizational ideas from any one variant worth lifting into the final regardless of which is the base.
- **Recommendation** — your honest take on which variant is closest to a good fit for `GOALS.md`, and where it would benefit from grafts from the others.

End by asking the user how they want to direct the final outline.

### Step 4: Write OUTLINE.md

Once the user gives direction, write `.drafts/<topic>/OUTLINE.md` reflecting their choices. Apply the same format as the per-variant outlines so `/draft-standard` reads a consistent shape. Mark explicitly which choices were the user's and which were inherited from the chosen base outline.

If the user's direction is ambiguous, ask before guessing. `OUTLINE.md` is a contract with `/draft-standard` — silent ambiguity here turns into bad draft.

### Step 5: Confirm and Hand Off

Show the user `OUTLINE.md` (or its diff against the chosen base) and confirm they're ready to proceed. When they confirm, tell them the next step is `/draft-standard`. Do not invoke drafting from this skill — that's a separate user gate.

## Notes for the orchestrator

- Always run the three outline agents in parallel.
- Outlines are cheap; if the user wants to iterate on goals after seeing the outlines, send them back to `/discover-standard` and re-run this skill afterward — don't try to fix `GOALS.md` from here.
- If `GOALS.md` changes, prior outlines are stale. Either re-run them or have the user blend manually with awareness of the staleness.
- All three variants share the principle-based house voice. They are not competing philosophies. If one variant comes back reading like a different document entirely (different tone, different terminology), the agent overreached — flag and consider re-running just that variant.
