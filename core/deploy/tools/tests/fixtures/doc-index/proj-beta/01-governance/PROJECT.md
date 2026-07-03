---
path: proj-beta/01-governance/PROJECT.md
filename: PROJECT.md
file_format: md
domain: source
type: reference
project: proj-beta
folder: 01-governance
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
---
# proj-beta — Project governance root (fixture)

The second project's governance-root node — the BELONGS_TO resolution target for
proj-beta files. Note: PROJECT.md appears in BOTH projects, so the bare filename
`PROJECT.md` is AMBIGUOUS on its own; BELONGS_TO resolves by PROJECT NAME (not filename)
to the per-project representative, so the ambiguity does not block project binding.
No real project data.
