---
path: proj-alpha/02-design/alpha_fdd.md
filename: alpha_fdd.md
file_format: md
domain: source
type: fdd
project: proj-alpha
folder: 02-design
managed_by: file-router
lifecycle_state: created
trust_category: evidence
created_date: 2026-06-01
lifecycle_trigger: retroactive-backfill
relationships:
  - type: BELONGS_TO
    target: "proj-alpha"
    evidence: "backfill 2026-06-01 — folder-path project binding"
    created_date: 2026-06-01
---
# Alpha FDD (fixture)

Synthetic Domain-A source artifact for the doc-index builder self-test. This is the
cross-project dependency TARGET (beta_testplan DEPENDS_ON alpha_fdd) — the Query-5
non-empty driver. Carries the 11-field node core (source/created/evidence) + a
BELONGS_TO edge in the exact shape the edge tool emits. No real project data.
