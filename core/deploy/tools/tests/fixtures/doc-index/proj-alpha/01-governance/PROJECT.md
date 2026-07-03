---
path: proj-alpha/01-governance/PROJECT.md
filename: PROJECT.md
file_format: md
domain: source
type: reference
project: proj-alpha
folder: 01-governance
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
# proj-alpha — Project governance root (fixture)

The project's governance-root node. The doc-index builder resolves any `BELONGS_TO
target: "proj-alpha"` edge from other files in this project to THIS node's file_id
(the project-name→schema-file-FK seam of the relationship-edge population), so a file whose only edge is BELONGS_TO
is correctly NOT an orphan. Its own BELONGS_TO to proj-alpha is a self-edge (skipped).
No real project data.
