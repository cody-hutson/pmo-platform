---
path: proj-beta/08-generated/beta_summary.md
filename: beta_summary.md
file_format: md
domain: generated
type: executive-summary
project: proj-beta
folder: 08-generated
managed_by: file-router
lifecycle_state: published
trust_category: interpretation
created_date: 2026-06-05
lifecycle_trigger: retroactive-backfill
trigger_source: SteerCo 2026-06-04
source_inputs: [beta_testplan.md]
relationships:
  - type: BELONGS_TO
    target: "proj-beta"
    evidence: "backfill 2026-06-05 — folder-path project binding"
    created_date: 2026-06-05
  - type: DEPENDS_ON
    target: "beta_testplan.md"
    evidence: "backfill 2026-06-05 — source_inputs anchor"
    created_date: 2026-06-05
---
# Beta Executive Summary (fixture)

Second Domain-C (generated) synthesis, in proj-beta. `source_inputs: [beta_testplan.md]`
populates a second `synthesis_scope` junction row so the portfolio-rollup (Query-4)
synthesis_count is non-zero for both projects. No real project data.
