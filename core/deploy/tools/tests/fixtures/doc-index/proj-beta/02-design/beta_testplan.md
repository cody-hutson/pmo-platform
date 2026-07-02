---
path: proj-beta/02-design/beta_testplan.md
filename: beta_testplan.md
file_format: md
domain: source
type: test-plan
project: proj-beta
folder: 02-design
managed_by: file-router
lifecycle_state: created
trust_category: evidence
created_date: 2026-06-04
lifecycle_trigger: retroactive-backfill
relationships:
  - type: BELONGS_TO
    target: "proj-beta"
    evidence: "backfill 2026-06-04 — folder-path project binding"
    created_date: 2026-06-04
  - type: DEPENDS_ON
    target: "alpha_fdd.md"
    evidence: "Design review 2026-06-04 — cross-project dependency"
    created_date: 2026-06-04
---
# Beta Test Plan (fixture)

Synthetic Domain-A source artifact in a SECOND project (proj-beta). Carries the
CROSS-PROJECT edge `DEPENDS_ON alpha_fdd.md` (source project Beta != target project
Alpha) — the Query-5 (cross-project-deps) non-empty driver. No real project data.
