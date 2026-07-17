---
id: proj-beta-rollup
entity_type: Project Rollup (composed)
owning_agent: ppm-agent
content_lifecycle_pattern: Living
project_id: proj-beta
last_published: 2026-07-06
status: red
top_risks:
  - risk: "Data migration reconciliation fails on ~3% of rows"
    owner: "DataLead-Beta"
    mitigation: "Root-cause the mismatch; add a reconciliation gate before go-live"
key_dependencies:
  - from: proj-beta
    to: proj-alpha
    state: broken
  - from: proj-beta
    to: billing-gateway
    state: open
capacity_signal: {utilization: 0.62, gap_rag: red}
milestone_delta:
  next_milestone: "Go-Live readiness review"
  target: 2026-07-20
  actual: ""
  state: at-risk
cross_project_conflicts:
  - conflict: "Contended integration-test window with Alpha"
    projects_affected: [proj-alpha, proj-beta]
    owner: "DBA-Lead"
    mitigation: "Split the shared window; Beta takes mornings"
---
# Project Rollup — Project Beta (fixture)

Fixture rollup entity — no real project data. This entity is the AGED one: its
`last_published` is 7 business days before the `--self-test` anchor, so it renders
`[STALE:DEGRADED]` (age > 5 bd). `capacity_signal` is authored in INLINE FLOW style
and `projects_affected` as an inline flow list, to exercise those parse paths.
