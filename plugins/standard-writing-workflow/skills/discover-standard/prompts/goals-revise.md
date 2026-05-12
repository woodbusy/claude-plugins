# Goals-revise prompt template

Sent to `goals-author` to revise `GOALS.md` in response to a round of discovery-critique findings + arbitration directives. The orchestrator substitutes `{{ROUND_FINDINGS}}` and `{{ARBITRATION_DIRECTIVES}}` before sending.

---

`GOALS.md` has been reviewed by the discovery-critique team. Revise it to address the findings below. This is NOT a fresh write — preserve the parts that weren't called out.

## Inputs to read

- `.drafts/<topic>/GOALS.md` — current version
- `.drafts/<topic>/discovery-critique-dialog.md` — full critique history including any arbitration

## Findings to address

{{ROUND_FINDINGS}}

## Arbitration directives and human decisions

{{ARBITRATION_DIRECTIVES}}

When a directive or human decision applies to a finding, follow that guidance over the raw finding. Human decisions are authoritative.

## How to revise

- Edit `GOALS.md` in place. Do not append "revision sections" — the document should read clean as if originally written this way.
- **Merge the form-fit reviewer's findings into the `Departure candidates` and `Areas of uncertainty` sections.** This is critical — the outline phase depends on those sections being populated.
- If a substance or implementer finding identifies a real issue, revise the goals to fix it (e.g. add a missing requirement area, clarify scope, name a stakeholder).
- If a finding is wrong, make the goals less ambiguous so the same misread is unlikely. Don't simply ignore it.
- Stay within the standard's stated topic. If a finding pushes scope beyond the topic, push back in your revision summary rather than silently expanding scope.
- Update the **Inferences** section if you bake in new assumptions.

## What to produce

After editing, respond with a concise revision summary structured as:

```
## Revision Summary

**Changes to GOALS.md:** [bulleted list of substantive edits, citing sections]
**Form-fit findings merged into Departure candidates / Areas of uncertainty:** [bulleted list, or "(none)"]
**Findings not addressed:** [any findings you chose not to act on, with brief rationale; or "(none)"]
```

Do not present the revised goals to the user for approval — the orchestrator handles that gate after discovery concludes.
