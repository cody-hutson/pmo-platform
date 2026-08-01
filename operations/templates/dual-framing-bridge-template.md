---
artifact_type: template
template_family: Dual-Framing Bridge
domain: project
canonical_path: operations/templates/dual-framing-bridge-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-21
updated: 2026-08-01
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Development Approach and Life Cycle Performance Domain
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered Dual-Framing Bridge instances — an instance starts at the H1 below. -->

# {{PROJECT_NAME}} Dual-Framing Bridge

**Purpose:** Maps Agile sprint progress to Waterfall milestones for Sponsor view stakeholders. Produces dual-framed status for projects co-managed by PMO view and Sponsor view.
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

---

## Milestone-to-Sprint Mapping

| Sponsor view Milestone | Target Date | Mapped Sprint(s) | Sprint Status | Milestone Status | Evidence |
|--------------|------------|------------------|--------------|-----------------|----------|
| (populate from Phase-Gate Timeline) | | | | | |

---

## Dual-Frame Status

### Agile Frame (PMO view)
| Dimension | Status | Detail |
|-----------|--------|--------|
| Sprint Progress | — | No sprints started |
| Velocity | — | Not yet established |
| Backlog Health | — | Not yet assessed |
| Technical Blockers | — | None identified |

### Waterfall Frame (Sponsor view)
| Dimension | Status | Detail |
|-----------|--------|--------|
| Phase | Initiation | Project onboarding |
| Milestone Progress | — | No milestones due |
| Deliverable Status | — | No deliverables due |
| Risk Summary | — | No risks identified |

---

## Notes

- This bridge is updated alongside the Daily Status Log during each processing cycle.
- When output touches milestones or delivery status, both framings are produced automatically.
- Sponsor view stakeholders receive Waterfall-framed updates; PMO view stakeholders receive Agile-framed updates.
