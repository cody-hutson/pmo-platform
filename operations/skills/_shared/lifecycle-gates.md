# Lifecycle Gates — Shared Role-Skill Reference

> **Shared surface.** Consumed by every PMO role-Specialist skill whose scope spans the delivery lifecycle. Authored for longevity — a change here ripples to all consumers. The structure is the contract: the **15-stage lifecycle** (each stage with an entry gate and an exit gate) and the **handoff checklists** (each: from-role → to-role, the artifacts that must transfer). The role-skill factory (`pmo-skill-refiner` → `## Workflow — Consume Feeding Document`) draws on this file as the **lifecycle-gates** substrate; a role's §6 Modes and §5 Input Handling reference the stages the role operates within and the handoffs it owns.

This file is **reference content, not a skill** (no `SKILL.md`; not in any `deploy.sh` roster array; `_`-prefixed sibling of the skill directories).

## 15-Stage Lifecycle

A generalized delivery lifecycle from idea to closure. Each stage carries an **entry gate** (what must be true to start) and an **exit gate** (what must be true to advance). The gates are decision-grade — a role can evaluate them yes/no against the work's state. (This is the role-facing lifecycle reference; it is distinct from, and broader than, the release pipeline's stage-numbered process — a role reasons about where work sits in *this* lifecycle.)

| # | Stage | Entry gate | Exit gate |
|---|---|---|---|
| 1 | Intake | A request exists with an identifiable owner | The item is typed, scoped, and logged to the work tracker |
| 2 | Triage | A logged item awaits disposition | The item is prioritized and routed (accept / defer / reject), with rationale |
| 3 | Discovery | Scope is ambiguous or premises are uncertain | Open questions, gaps, scope-cleavage points, and premises are surfaced and recorded |
| 4 | Definition | The problem is understood; requirements are unwritten | Requirements / acceptance criteria are written and testable |
| 5 | Design / Solutioning | Requirements exist; the how is undecided | Design decisions are made, load-bearing ones recorded with reversibility |
| 6 | Planning | The solution shape is set; sequence is undecided | A sequenced plan with dependencies, owners, and a rollback posture exists |
| 7 | Build / Implementation | A plan and design exist | The change is implemented and self-verified against the spec |
| 8 | Dev Verification | An implementation exists | Functional checks pass (or failures are explained) |
| 9 | Quality Assurance | Dev verification passed | The work meets the quality bar; residual risks are registered |
| 10 | Review / Approval | The work is QA-clean | The accountable approver renders a go / no-go with a recorded decision |
| 11 | Pre-Deploy Readiness | Approval is granted | Impact assessment, training, and readiness validation are complete |
| 12 | Deploy / Cutover | Readiness is validated | The change is live; the deployment is logged; rollback remains available |
| 13 | Hypercare | The change is live | Stabilization metrics are within bounds; no open P1/P2 from the cutover |
| 14 | Closure | Hypercare exited | Trackers finalized, outcomes captured, knowledge transferred, artifact archived |
| 15 | Retrospective | The work is closed | Lessons are captured and routed to the improvement backlog |

## Handoff Checklists

Four canonical role-to-role handoffs. Each checklist names the artifacts that MUST transfer for the receiving role to start without re-discovering context. A handoff is incomplete until every listed artifact is present and current.

### H1 — Discovery → Definition (analyst → requirements owner)

- [ ] Open-question register (with F9 case-classification where applicable)
- [ ] Gap list with what good looks like, one line each
- [ ] Scope-cleavage points (where the work can be split)
- [ ] Premises requiring re-review (the assumptions the definition rests on)
- [ ] Evidence-quality labels on every grounded claim

### H2 — Planning → Build (planner → implementer)

- [ ] Sequenced plan with dependency edges (blocks / depends-on)
- [ ] File / change matrix (what changes, where)
- [ ] Design decisions with reversibility tiers (load-bearing ones recorded)
- [ ] Verification plan (what "done" is checked against)
- [ ] Rollback strategy (how the change is undone)

### H3 — Build → Verification (implementer → tester)

- [ ] Implemented change with self-verification evidence
- [ ] Spec / acceptance criteria the change was built against
- [ ] Deviation log (any departure from the plan, with rationale)
- [ ] Known-gaps / residual-risk notes
- [ ] Test entry conditions (environment, data, fixtures)

### H4 — Deploy → Hypercare (release owner → operations)

- [ ] Deployment log (what shipped, when, by whom)
- [ ] Rollback runbook (the available rollback type + its reversibility tier)
- [ ] Impact assessment + affected-cohort list
- [ ] Stabilization metrics + their bounds (what "healthy" looks like)
- [ ] Escalation path + on-call owner for cutover-originated issues
