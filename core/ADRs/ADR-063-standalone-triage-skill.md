<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-063 — Stage-2 Triage executes as a new standalone skill (pipeline-triage), not a delivery-engine / release-planner mode"
status: Accepted
date: 2026-07-01
release: v3.44-pipeline-triage-automation
deciders: "operator (confirmed 2026-07-01) + Stage 5 Solutioning spoke + independent adversarial review"
tags: [architecture, skill, composition, skill-boundary, pipeline, triage, decomposition-axis, module-boundary]
source_observations:
  - "delivery-engine reads the project/Jira backlog, NOT the pipeline improvement backlog: grep -ci 'status: proposed' operations/skills/delivery-engine/SKILL.md -> 0; operating-model.md §1.3 names delivery-engine 'project-ops scoped (sprint-backlog modes are project-ops; not pipeline-improvement-backlog)'. ADR-006 homes delivery-engine in the operations module; every pipeline-stage skill (release-planner, release-executor, release-hub, build-reviewer, implementation-planner, roadmap-curator) lives in the release module."
  - "release-planner Mode A consumes status: approved issues (SKILL.md:99 — read_approved_queue_for_theme / gh issue list --label 'status: approved'), which is DOWNSTREAM of triage; it does not read status: proposed to produce a triage verdict. release-planner is the Stage-3/4 bundle/plan surface, not a Stage-2 triage-decision producer."
  - "ppm-agent produces decision frames from project artifacts (Section 5 Decisions-needed / Section 10 Handoff Manifest); it does not run the Workflow Readiness gate (G1/G2) over the improvement backlog and does not author GitHub Issue triage outcomes."
  - "No triage skill mode exists anywhere in the corpus (grep -rniE '^### Mode [A-Z].*triage' --include=SKILL.md . -> 0). stage-02-triage.md §5 fully specifies A1-A6.5; §9 Gap Summary listed 'no triage skill mode (P2)' as an open gap this release closes. stage-to-skill-mode-mapping.md G2 was a GAP row."
  - "ADR-019 sets the compose-not-absorb rule + the 3-conjunct skill-boundary test (distinct trigger surface AND distinct write-scope AND distinct primary role). No existing skill fits Stage-2 improvement-backlog triage, so the net-new bar (necessary, not plausible) is MET. #34 (pmo-triage agent) + #33 (pmo-intake agent) CLOSED NOT_PLANNED -> the agent-paired standalone option is void; the skill-based standalone is the surviving form."
---

# ADR-063 — Stage-2 Triage executes as a new standalone skill (pipeline-triage)

## Status

Accepted. Flipped from Proposed at the v3.44 Stage-9 Plan Review GO gate (novel class → Deep review), per the Nygard status convention — the operator rendered GO at the Stage-9 human gate on 2026-07-01. This ADR is the committed record of the Stage-5 D-Design decision — re-spun after an independent adversarial review refuted the initially-proposed host and the operator confirmed a standalone skill on 2026-07-01 (#2752).

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/` (global max = ADR-062 at the authoring commit; contiguity enforced by `release/tools/check-adr-numbers.py`). Referenced downstream **by slug**, never by number. Extended or reversed only by a successor / superseding ADR — never by in-place edit.

## Context

The v3.44 slice (milestone 78-pipeline-triage-automation) needs an invokable execution surface that runs Stage-2 triage phases A1–A6.5 over `status: proposed` improvement-backlog GitHub Issues and emits one consolidated triage summary for the operator's B1–B3 verdict (#286), with auto-execute as the operative default (#282). The A1–A6.5 phase *definitions* and the Tier-2 auto-execute *posture* already live in full in `release/references/pipeline/stage-02-triage.md` (§5, §8) — so the open question is purely WHERE the mode that executes them lives, not what it does.

The decision was re-spun twice. An initial Stage-5 pass recommended extending `delivery-engine`. An independent adversarial review refuted that host on module-boundary and backlog-identity evidence; the operator accepted the challenge and re-opened host selection. A second pass recommended extending `release-planner`. The operator, weighing both passes plus the adversarial counter-designs, confirmed a **new standalone skill** on 2026-07-01: all three reuse candidates are ruled out, so ADR-019's net-new bar is met.

The design axis is a pair-by-pair EXTEND-vs-build-new reconciliation that ADR-019 delegates to its reconciliation venue, applied to the Stage-2-triage capability. It clears the ADR threshold: non-obvious (a placement/decomposition-axis call re-decided across three host candidates) and it sets a reusable precedent for future pipeline-stage-as-skill work.

## Decision

**Stage-2 triage executes as a new standalone skill — `pipeline-triage` — in the release module (`release/skills/pipeline-triage/`).** The skill reads `status: proposed` improvement-backlog issues (the untriaged-view filter per `stage-02-triage.md` §5), executes the Phase-A sequence A1–A6.5 by **CITING** `stage-02-triage.md` §5 for the phase definitions (never restating them), COMPOSES the canonical DoR (G1) and similarity (G2-09) gate machinery defined in `gate-criteria-spec.md` (cite, don't copy), and emits one consolidated triage summary. Auto-execute is the operative default (#282): the A1–A6.5 enrichment runs end-to-end without per-action approval; only the state-mutating Reject-close (`gh issue close --reason "not planned"`) is held behind explicit operator confirmation. The Approve/Defer/Reject **verdict** stays operator-only (Tier 3).

The skill is registered as a `function-skill` CI in `core/skills/registry.md`, added to the `RELEASE_SKILLS` array in `core/deploy/deploy.sh`, contract-registered in `core/schemas/per-skill-output-contracts.md` (Skill 15), and packaged as `packages/pipeline-triage.skill`.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| (A) New standalone `pipeline-triage` skill in the release module (this ADR) | **Chosen** | No existing skill reads the `status: proposed` improvement backlog AND produces a triage verdict, so ADR-019's net-new bar (*necessary, not plausible*) is MET. A standalone that composes the canonical gate machinery + cites the phase spec is ADR-019's endorsed "thin Specialist" pattern. Lands in the release module beside the other pipeline-stage skills (ADR-006). Additive, CHEAP-reversible, narrow pipeline-scoped trigger. Cost (registry row + deploy-array member + `.skill` + output-contract + ≥3 failure modes) is the genuine net-new surface, justified because no host owns the capability. |
| (B) Extend delivery-engine with a Triage mode | Rejected | delivery-engine reads the project/Jira backlog, NOT the pipeline improvement backlog: `grep -ci "status: proposed"` → 0; `operating-model.md §1.3` names it "project-ops scoped ... not pipeline-improvement-backlog". ADR-006 homes it in the operations module; homing a pipeline-stage function there is the cross-scope leak ADR-006 partitions against. Its Mode C = G1 mapping is a declared dual-framing citation (DoR↔G1 vocabulary), not evidence it executes Stage-2 triage over GitHub Issues. |
| (C) Extend release-planner with a Triage mode | Rejected | release-planner Mode A consumes `status: approved` issues (`SKILL.md:99`) — downstream of triage; it is the Stage-3/4 bundle/plan surface, not a Stage-2 triage-decision producer. Extending it would widen a Stage-4-planning skill to also own Stage-2 execution+enrichment (a cohesion stretch) and would still require a new triage write-scope. It reads a related backlog but does not produce triage verdicts. |
| (D) Extend ppm-agent | Rejected | ppm-agent produces decision *frames* from project artifacts; it does not run the Workflow Readiness gate (G1/G2) over the improvement backlog nor author GitHub Issue triage outcomes. Wrong function and wrong backlog. |
| (E) Standalone skill paired with the #34 pmo-triage agent | Void | #34 (pmo-triage) + #33 (pmo-intake) CLOSED NOT_PLANNED — the agent premise is superseded. No agent to pair with; the skill-based standalone (Option A) is the surviving form. |
| (F) Inline the A1–A6.5 phase logic in the skill body | Rejected | Duplicates `stage-02-triage.md` §5 → drift target; violates no-duplicate-source. The skill cites phase IDs + the §5 definitions instead. |

## Consequences

**Positive:** the pipeline stages stay one coherent release-module family; A1–A6.5 stays single-sourced in the pipeline spec (the skill cites §5, never restates it); the improvement-backlog read is owned by the one skill scoped to it; the trigger surface is narrow and pipeline-scoped ("triage the proposed queue") — lower cross-skill false-positive risk than a general-delivery skill; the Workflow-Readiness gate over the improvement backlog now has a single named owner.

**Negative / cost:** a net-new skill adds governance surface — a registry CI row, a `RELEASE_SKILLS` array member, a new `.skill` package (Check-7 baseline, milestone-94 cluster), an output-contract block, ≥3 domain-specific failure modes, and a new router description surface. This is the genuine net-new cost; it is justified because no existing host owns the capability (the net-new bar is met, not merely plausible). The skill must be held to the cite-don't-restate discipline at review (it must reference `stage-02-triage.md` §5, not copy it) — a review obligation for pmo-qa-auditor / build-reviewer.

**Reflexive:** the skill's auto-execute default + Stage-2 execution binding apply to releases entering Stage 2 after this release's merge SHA (recorded in `RELEASE_LOG.md`); this release is exempt (reflexive-pipeline-loop discipline).

## Reversibility

**Implementation: CHEAP / HIGH** — a net-new skill file + doc-binding edits + registration surfaces; `git revert` the single merge + `deploy.sh` rebuild removes it cleanly; no corpus-semantics change, no data migration. **Decision axis: MODERATE** per ADR-019's reversibility note — re-homing the capability into an existing skill's mode after the standalone is authored is a multi-surface change (unwind registry + package + deploy array + output-contract) — but the skill's cite-don't-restate discipline (the phase logic lives in `stage-02-triage.md` §5, not the skill) keeps the phase-definition surface host-independent, so a re-home is bounded. CHEAP before the first line is authored under the rule.

## Related ADRs

- ADR-019 — Specialists compose (not absorb) shared function-skills — the governing principle; this ADR is a pair-by-pair application of its EXTEND-vs-build-new reconciliation + the 3-conjunct skill-boundary test (re-run across delivery-engine, release-planner, and ppm-agent — none fits, so a new skill is warranted).
- ADR-006 — Skill-to-module map — homes delivery-engine in operations and pipeline-stage skills in release; the module-boundary evidence that ruled out delivery-engine and placed `pipeline-triage` in the release module.
- ADR-004 — Five-Function Spine — the stable function vocabulary the pipeline skills compose against.

## References

(provenance; prose leads with self-describing roles so meaning survives renumbering)
- The triage-skill-definition slice: #286. The auto-execute-default binding: #282. Milestone: 78-pipeline-triage-automation.
- Superseded agent premise: #34 (pmo-triage), #33 (pmo-intake) — both CLOSED NOT_PLANNED.
- Downstream (NOT this release): #779 (Stage-2 architectural-fit acceptance gate), epic #1188.
