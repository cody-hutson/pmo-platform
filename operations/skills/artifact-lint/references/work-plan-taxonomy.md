> Operator-confirmed at Stage 9 (v2.08): the Canonical-10 + Situational-7 derivation below is accepted as the authoritative work-plan taxonomy. The original artifact-lineage-graph split card was deleted; this table is the evidence-grounded reconstruction. Provenance below.

# Work-Plan Taxonomy — 17 Types

This taxonomy is the lookup table the **displaced-content check (Check 4)** uses to test an artifact's `folder`/`target_folder` against its `artifact_type` canonical home, and the **per-type derivative mapping** the sibling-duplicate and version-chain checks use to reason about what a given type typically GENERATES.

## Provenance (why these 17)

No literal 17-row taxonomy survives in the canonical corpus — the original artifact-lineage-graph split card that defined it was deleted (FINDING 2, Stage 5). This table is the **evidence-grounded reconstruction**:

- **Canonical 10** ≡ the Domain-C synthesis `artifact_type` value set in `core/schemas/frontmatter-schema.md` (Type Taxonomy, Domain C — Synthesis): `executive-summary`, `decision-package`, `readiness-assessment`, `weekly-rollup`, `daily-status-output`, `processing-run`, `draft-communication`, `sop`, `runbook`, `analysis`. These are the artifact types the generated surface actually carries.
- **Situational 7** ≡ the plan-type taxonomy set + the waterfall/cutover rows: `plan:comms`, `plan:training`, `plan:hypercare`, `plan:cutover`, `plan:change-management`, `plan:raid`, and `phase-gate-review-package`. These are situational deliverables that appear in waterfall/cutover-governed projects.

This derivation was **operator-confirmed at Stage 9 Collective Review (v2.08)** as the authoritative taxonomy. The displaced-content check (Check 4) therefore treats a canonical-home mismatch as a firm finding — still recommend-only per the skill's Autonomy Tier 1 posture (the operator approves any move), but no longer gated behind taxonomy confirmation.

## Canonical 10 (Domain-C synthesis types)

| # | artifact_type | Tier | Expected parent_artifact class | Typical GENERATES derivative | Canonical target folder |
|---|---|---|---|---|---|
| 1 | `executive-summary` | Synthesis (C) | a decision-package or analysis it summarizes | a stakeholder `draft-communication` | `01-Governance/` |
| 2 | `decision-package` | Synthesis (C) | source transcript / analysis | an `executive-summary`; a RAID/decision-record entry | `01-Governance/` |
| 3 | `readiness-assessment` | Synthesis (C) | a cutover/test plan | a `phase-gate-review-package` input | `01-Governance/` |
| 4 | `weekly-rollup` | Synthesis (C) | the week's `daily-status-output` set | an exec `draft-communication` | `04-PMO-Operations/` |
| 5 | `daily-status-output` | Synthesis (C) | carry-forward tracker + transcripts | rolls up into a `weekly-rollup` | `04-PMO-Operations/` |
| 6 | `processing-run` | Synthesis (C) | the source artifact processed | tracker updates; follow-up tags | `08-Generated/` (working) |
| 7 | `draft-communication` | Synthesis (C) | the artifact it communicates (summary/decision) | a sent comm (promoted to 06-Emails) | `06-Emails/` |
| 8 | `sop` | Synthesis (C) | a process map / requirements doc | a `runbook` (operational variant) | `07-Reference/` |
| 9 | `runbook` | Synthesis (C) | an `sop` or an architecture/FDD | operational checklists | `07-Reference/` |
| 10 | `analysis` | Synthesis (C) | source transcript(s) / export(s) | a `decision-package`; an `executive-summary` | `08-Generated/` then `01-Governance/` |

## Situational 7 (plan-type taxonomy + waterfall/cutover)

| # | artifact_type | Tier | Expected parent_artifact class | Typical GENERATES derivative | Canonical target folder |
|---|---|---|---|---|---|
| 11 | `plan:comms` | Situational plan | a stakeholder/audience analysis | per-audience `draft-communication`s | `01-Governance/` |
| 12 | `plan:training` | Situational plan | a change-impact assessment | training materials; a readiness input | `01-Governance/` |
| 13 | `plan:hypercare` | Situational plan | a cutover plan / readiness assessment | hypercare metrics; issue-tracking setup | `01-Governance/` |
| 14 | `plan:cutover` | Situational plan | a `readiness-assessment` / FDD | a go/no-go `decision-package` | `01-Governance/` |
| 15 | `plan:change-management` | Situational plan | a change-impact assessment | `plan:training`, `plan:comms` | `01-Governance/` |
| 16 | `plan:raid` | Situational plan | the project's RAID register | RAID-log entries (Domain B) | `04-PMO-Operations/` |
| 17 | `phase-gate-review-package` | Situational | a `readiness-assessment` + plans | a phase-gate go/no-go decision-record | `01-Governance/` |

## How Check 4 uses this table

For each scanned artifact, read its `artifact_type` and `folder`/`target_folder`. Look up the canonical target folder above. When the artifact's current folder contradicts the canonical home AND the artifact's state indicates it should have landed there (e.g., `artifact_state: PROMOTED` / `lifecycle_state: published` but `folder: 08-Generated/`), emit a displaced-content finding proposing the correct folder. Working-state artifacts legitimately in `08-Generated/` (e.g., a `processing-run`, or an `analysis`/`draft-communication` still in DRAFT) are NOT displaced — displacement keys on the state-vs-folder contradiction, not on presence in staging.

Notes:
- A type whose canonical home IS `08-Generated/` (rows 6) is never flagged as displaced while in staging.
- Folder names follow the project 01-08 structure; a project that customizes folder names supplies the mapping via its project-level configuration. Absent a project mapping, the 01-08 names above are the default.
- This taxonomy is operator-confirmed (Stage 9, v2.08) — a canonical-home mismatch is a firm displaced-content finding (recommend-only per Autonomy Tier 1; the operator approves any move).

### Sources
- #334 — the artifact-lineage-graph split whose deleted split card originally defined the 17-row taxonomy; this table is the evidence-grounded reconstruction.
- #159 — the plan-type taxonomy that seeds the Situational 7 tier.
