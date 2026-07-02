---
path: proj-alpha/08-generated/alpha_rollup.md
filename: alpha_rollup.md
file_format: md
domain: generated
type: weekly-rollup
project: proj-alpha
folder: 08-generated
managed_by: file-router
lifecycle_state: published
trust_category: interpretation
created_date: 2026-06-03
lifecycle_trigger: retroactive-backfill
trigger_source: SteerCo 2026-06-03
source_inputs: [alpha_fdd.md]
relationships:
  - type: BELONGS_TO
    target: "proj-alpha"
    evidence: "backfill 2026-06-03 — folder-path project binding"
    created_date: 2026-06-03
  - type: DEPENDS_ON
    target: "alpha_fdd.md"
    evidence: "backfill 2026-06-03 — source_inputs anchor"
    created_date: 2026-06-03
---
# Alpha Weekly Rollup (fixture)

Synthetic Domain-C (generated) synthesis for the doc-index builder self-test.
`source_inputs: [alpha_fdd.md]` drives the `synthesis_scope` junction table, and
`lifecycle_state: published` + a source (`alpha_fdd.md`) whose mtime the self-test
pushes past this `created_date` makes the Domain-C staleness query (Query-6) return
this row — exercising Query-6's discriminating temporal logic [FMF-3]. No real data.
