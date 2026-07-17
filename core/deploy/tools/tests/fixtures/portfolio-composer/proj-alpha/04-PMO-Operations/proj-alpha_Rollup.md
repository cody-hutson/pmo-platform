---
id: proj-alpha-rollup
entity_type: Project Rollup (composed)
owning_agent: ppm-agent
content_lifecycle_pattern: Living
project_id: proj-alpha
last_published: 2026-07-15
status: green
top_risks:
  - risk: "Vendor API rate-limit under peak load"
    owner: "PM-Alpha"
    mitigation: "Client-side backoff + response cache; load-test before cutover"
  - risk: "UAT environment parity gap vs production"
    owner: "TechLead-Alpha"
    mitigation: "Refresh UAT from a prod snapshot weekly"
key_dependencies:
  - from: proj-alpha
    to: shared-identity-service
    state: satisfied
capacity_signal:
  utilization: 0.78
  gap_rag: green
milestone_delta:
  next_milestone: "UAT sign-off"
  target: 2026-08-01
  actual: ""
  state: in-progress
cross_project_conflicts:
  - conflict: "Shared DBA double-booked during cutover week"
    projects_affected: [proj-alpha, proj-beta]
    owner: "DBA-Lead"
    mitigation: "Sequence the two cutover windows one week apart"
---
# Project Rollup — Project Alpha (fixture)

Fixture rollup entity — no real project data. This entity is the FRESH one: its
`last_published` is the maximum across the fixture, so at the `--self-test` anchor
(`max(last_published)`) it reads 0 business days old and renders no `[STALE]`
marker. Structured fields are authored in BLOCK style (block object-lists + block
mappings) to exercise that parse path.
