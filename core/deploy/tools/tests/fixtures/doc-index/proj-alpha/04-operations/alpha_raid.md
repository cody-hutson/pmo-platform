---
path: proj-alpha/04-operations/alpha_raid.md
filename: alpha_raid.md
file_format: md
domain: managed
type: risk-register
project: proj-alpha
folder: 04-operations
managed_by: file-router
lifecycle_state: current
trust_category: controlled-truth
created_date: 2026-06-02
lifecycle_trigger: retroactive-backfill
relationships:
  - type: BELONGS_TO
    target: "proj-alpha"
    evidence: "backfill 2026-06-02 — folder-path project binding"
    created_date: 2026-06-02
---
# Alpha RAID (fixture)

Synthetic Domain-B (managed) operational tracker for the doc-index builder self-test.
Exercises the `managed`/`current`/`controlled-truth` node core so the portfolio-rollup
(Query-4) knowledge_count column is non-zero for proj-alpha. No real project data.
