---
title: Release Class Taxonomy
purpose: Release-level dispatch axis classifying every release into one of 4 named classes; selects per-release engagement posture, Stage 9 review depth, and optional Stage 5 activation bias + Stage 13 outcome-window. Consumed by Stage 3 Bundle milestone description, hub-spoke-bridge Procedures 0/1/5, engagement-charter Section 1, release-process Methodology Variation section.
applies_to: All releases entering Stage 3 going forward.
parallel_to: autonomy-tiers.md (orthogonal — Release Class is per-release dispatch; Autonomy Tier is per-action authorization); reversibility-protocol.md (orthogonal — Release Class informs ceremony density; reversibility tier informs per-act process weight); engagement-charter.md (Release Class is the release-level dispatch axis ABOVE the per-action engagement hierarchy in Section 1).
disambiguates_from: Document Tier (CLAUDE.md File Management Protocol), Skill Tier (OPERATIONS.md skill classification), Automation Tier (`pipeline/` + 10 schemas), Autonomy Tier (per-action) — Release Class is the 5th tier convention operating at release level; always named explicitly, never bare "Class N" per autonomy-tiers.md Tier Disambiguation Table discipline.
source: "Stage 5 spec for Release Class taxonomy + differentiated lifecycle; operator D-decisions at Collective Review 2026-05-24."
version: v11.27
---

# Release Class Taxonomy

## Purpose

Every release through the 13-stage pipeline receives one of 4 named classes declared at Stage 3 Bundle Phase B3 (alongside milestone scope-commit). The class drives differentiated lifecycle treatment along 2 REQUIRED dimensions (engagement density + Stage 9 review depth) + 2 OPTIONAL dimensions (Stage 5 activation bias + Stage 13 outcome-window). Class operates ABOVE the per-action Autonomy Tier hierarchy — the two compose multiplicatively, not redundantly: a Tier 2 Bounded-Auto action in a `cross-cutting` release still produces structured handoff comments at every transition; the same Tier 2 action in a `routine` release surfaces only at gate boundaries. Disambiguated from the 4 prior tier conventions (Document Tier / Skill Tier / Automation Tier / Autonomy Tier) per autonomy-tiers.md Tier Disambiguation Table discipline — Release Class is a 5th convention with its own surface (release-level) and is always named explicitly.

## Definition

A **Release Class** is a closed-enum classification of a single release that selects per-release engagement posture. The 4 values — `routine` | `novel` | `cross-cutting` | `hotfix` — derive from a composite industry survey (ITIL 4 change-classes / CAB tiers / GitFlow / SRE conventions) plus PMO-specific evidence (the `cross-cutting` value names a release shape empirically frequent in PMO that pure ITIL `standard/normal/emergency` does not capture). The class is declared in the milestone description "## Release Class" H2 section at Stage 3 Phase B3; queryable via `gh api repos/{REPO}/milestones/<N> --jq .description`. Re-classification at any later stage requires operator approval per § Re-Classification Protocol; cheaper-to-stricter re-classifications are CHEAP; stricter-to-cheaper require explicit risk acceptance per reversibility-protocol.md.

## Scope

**In scope.** Every release passing through Stages 3-13 of the pipeline. The class field is part of the milestone description schema (Stage 3 Phase B3 output). The per-class mapping table is RECOMMENDATION — operator MAY override per-release with documented rationale in the milestone description Rationale sub-field.

**Out of scope.** Non-release-shape categorizations (governance-surface category, defect-severity, work-type prefix) are NOT modeled as Release Classes — they live in label-taxonomy.md and ticket-information-architecture.md. Per-action Autonomy Tier assignment is orthogonal and unchanged (per autonomy-tiers.md). Per-decision reversibility tier is orthogonal and unchanged (per reversibility-protocol.md). Per-stage Automation Tier is orthogonal and unchanged (per pipeline/ schemas).

## Class Enum

The Release Class enum is CLOSED — 4 values, no extension without governed-change protocol. Each value is named explicitly throughout the platform (never bare "Class N") per autonomy-tiers.md Tier Disambiguation Table discipline.

| Class | Definition | Trigger (any one fires) |
|---|---|---|
| `routine` | Bounded scope; well-understood patterns; low blast radius; CHEAP-MODERATE reversibility per reversibility-protocol.md. | (a) all issues are P3/P4 + size:S/M; (b) all change-spec files have ≥3 prior release touches; (c) zero new files added; (d) zero new D-class decisions in the release plan. |
| `novel` | First-of-kind protocol, new file class, or structural pattern; design uncertainty surfaced at Stage 5. | (a) ≥1 issue introduces a new reference doc, schema, or skill; (b) ≥1 D-class decision in release plan; (c) ≥1 Stage 5 ADR per decision-discipline.md § 3. |
| `cross-cutting` | Modifies ≥3 pipeline stages OR ≥3 governance surfaces; expanded coordination scope. | (a) File Change Matrix touches ≥3 `pipeline/stage-*.md` files; (b) File Change Matrix touches ≥3 of {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, RELEASE_LOG.md, hub-spoke-bridge.md, gate-criteria-spec.md, release-process.md}; (c) ≥3 in-bundle compositional edges per Stage 4 A2 DAG. |
| `hotfix` | Narrow corrective scope addressing a P1/P2 defect found in a deployed release; sub-release patch (vX.Y.Z trailing dot); CHEAP reversibility. | (a) source defect is a P1/P2 Issue raised against a deployed release; (b) bundle contains ≤3 issues; (c) bundle scope is corrective ("fix:" commit posture dominates); (d) version-string carries trailing patch number. |

### Anti-patterns per class

- **routine**: classifying a 10-issue cross-cutting reorganization as `routine` because individual issues are small. Aggregate scope is the relevant signal, not per-issue size.
- **novel**: classifying a routine [Process] ticket as `novel` because the ticket itself is new. Ticket-newness is not protocol-newness; the trigger is "introduces a new reference doc, schema, or skill", not "ticket has never been written before".
- **cross-cutting**: classifying a single-stage-spec-edit release as `cross-cutting` because the edit happens to be in a `pipeline/stage-*.md` file. The trigger is ≥3 stage files, not 1.
- **hotfix**: classifying a P1 fix that ALSO introduces a new protocol as `hotfix`. The new-protocol component disqualifies `hotfix`; the release shape is `novel` or `cross-cutting` with the P1 fix as an issue in the bundle.

### Industry-precedent provenance

The 4-value enum was canonicalized at Stage 5 per the composite survey: `routine` maps to ITIL 4 *standard* (low-risk, well-understood, pre-approved) + CAB *Standard* + GitFlow *minor*; `novel` maps to ITIL *normal* (planned, risk-assessed, authorized) + CAB *Normal/Major* + GitFlow *major*; `cross-cutting` maps to ITIL *normal* (often categorized as Major for high impact) + CAB *Major* (very high-risk requiring impact study) — a release shape pure semantic-versioning does not name; `hotfix` maps universally to ITIL *emergency* + CAB *Emergency* + GitFlow *hotfix*. Alternative shapes (3-value ITIL-faithful, 5-value novel-protocol/novel-content split, 5-value governance-as-separate-class) were evaluated and rejected at Stage 5 per Stage 5 Canonicalization 1.

## Per-Class Mapping

The mapping table below is RECOMMENDATION, not enforcement — operator MAY override per-release with documented rationale in the milestone-description Rationale sub-field. Two dimensions are REQUIRED (every release sets them); two are OPTIONAL (set them when the release engages those surfaces; otherwise omit).

| Dimension | routine | novel | cross-cutting | hotfix |
|---|---|---|---|---|
| Engagement density (REQUIRED) | Light | Standard | Tight | Light |
| Stage 9 Plan Review depth (REQUIRED) | Standard | Deep | Deep | Light |
| Stage 5 Activation bias (OPTIONAL) | SKIP-where-trivial | ALL | ALL | SKIP-where-trivial |
| Stage 13 Outcome-window (OPTIONAL) | 30-day | 30-day | 30-day | 7-day OR immediate |

### Engagement density semantics

- **Light**: Procedure-2 routing absorbed into Tier-3 Standing-GO per autonomous-execution-model.md; spoke completions batched into consolidated Decision Briefing rendered at gate boundaries only. Per-D-decision briefings still fire (D-decisions are gate-class), but routine routing of non-D-class work does not surface.
- **Standard**: per-D-decision Operator Decision Gate per hub-spoke-bridge.md § D-Gate Template + per-Stage-5 Decision Briefing on completion. Spoke completions surface as routing comments; Operator Decision Gates surface as in-chat AskUserQuestion per main-thread narrowing convention.
- **Tight**: per-spoke completion surfaces consolidated Decision Briefing; cross-D upstream-compatibility scan explicit at every D-decision per the D-Gate Template's Upstream compatibility subsection; N-way consistency table per Collective Review Protocol R4 receives explicit cross-D check by hub at every D-decision (not only at Collective Review).

### Stage 9 Plan Review depth semantics

- **Light**: verify the defect is fixed + regression-clean + rollback-feasibility (hotfix posture). PR diff review focuses on the defect-fix block + adjacent regression surface; design discussion is out-of-scope.
- **Standard**: verify PR metadata + verification evidence section in the release plan (routine posture). PR diff review includes implementation-conformance check against the release plan's File Change Matrix.
- **Deep**: verify Collective Review N-way consistency + cross-D upstream compatibility scan + Tier-A design-artifact refresh-gate G-CL6 per gate-criteria-spec.md (novel + cross-cutting posture). PR diff review includes blast-radius assessment + design-spec conformance + Empirical Verification.

### Stage 5 Activation bias semantics (OPTIONAL)

- **SKIP-where-trivial**: Default Stage 5 activation logic (per release-process.md § Stage 5 Activation paragraph) applies BUT bias is toward SKIP when the trigger criteria are met-by-letter-only (no design uncertainty surfaced; no new files; no D-class decisions). Routine bug-fix releases and hotfix releases typically activate this bias.
- **DEFAULT**: Standard activation per existing Stage 5 logic — all-or-nothing per release based on design-uncertainty criteria.
- **ALL**: Bias toward activating Stage 5 even when trigger criteria are borderline. Novel and cross-cutting releases activate this bias because the cross-issue compositional surface usually surfaces design questions that the per-issue activation triggers miss.

### Stage 13 Outcome-window semantics (OPTIONAL)

Composes with decision-outcome-tracking.md (SUCCESS/PARTIAL/ROLLBACK/DEFERRED enum at 30-day window default per the 30-day default):

- **30-day**: Standard outcome-window — Stage 13 spoke captures `**Outcome:**` field on the visible-H4 Deployment Log block at Stage 13 close; outcome state is locked at 30-day post-deploy review.
- **7-day**: Shortened outcome-window for hotfix releases where the defect-fix verifies quickly (corrective scope, narrow blast radius). Outcome state locks at 7-day post-deploy review.
- **immediate**: Outcome-window collapses to the Stage 13 close itself when the hotfix is verified by direct observation at deploy time (e.g., a P1 production-blocker fix verified by the operator at Stage 12 Execute). Outcome state locks at Stage 13 chore-PR merge.

## Classification Procedure

Operator renders the class at Stage 3 Phase B (alongside Milestone scope-commit), embedded in the milestone description as a `## Release Class` H2 section. The Stage 3 spoke proposes the class per the trigger conditions in § Class Enum; operator confirms or overrides at the D-ReleaseClass D-Gate per hub-spoke-bridge.md Procedure 0 D-Gate Template.

### Milestone-description template

```
## Release Class

Class: routine | novel | cross-cutting | hotfix
Rationale (max 2 sentences): why this class fires per trigger conditions
Differentiation posture:
  - Engagement density: Tight | Standard | Light
  - Stage 9 review depth: Deep | Standard | Light
  - Stage 5 activation bias: ALL | DEFAULT | SKIP-where-trivial   (OPTIONAL)
  - Stage 13 outcome-window: 30-day | 7-day | immediate           (OPTIONAL)
```

### Multi-trigger resolution

When triggers from multiple classes fire (e.g., a bundle that introduces 1 new file [novel trigger (a)] AND touches 3 pipeline/stage-*.md files [cross-cutting trigger (a)]), the highest-ceremony class wins per the order: `cross-cutting` > `novel` > `routine` (`hotfix` is mutually exclusive with the other three by the hotfix anti-pattern). The Rationale sub-field enumerates each fired trigger and names the dominant one.

### Edge cases

- **Empty bundle**: A milestone with zero issues cannot bundle; classification does not apply.
- **Mixed-shape bundle**: When the operator decomposes a single ticket into multiple issues with heterogeneous shape, classification applies to the bundle's aggregate shape per multi-trigger resolution.
- **Methodology variation**: Release Class is orthogonal to delivery-approach (Scrum / Kanban / Waterfall / SAFe / Custom) per release-process.md § Methodology Variation table — `routine` in a Scrum context retains the end-of-sprint cadence; `cross-cutting` in a Waterfall context retains the milestone-gate cadence.

## Re-Classification Protocol

Class MAY re-render at any later stage with operator approval; re-classification logged at the gate sub-task where the decision is rendered.

### Mechanics

1. Operator (or hub spoke) identifies signal that the original class no longer fits (e.g., Stage 5 surfaces a new D-class decision, transitioning `routine` → `novel`; or Stage 7 DT discovers blast radius is wider than the Stage 3 trigger conditions captured, transitioning `novel` → `cross-cutting`).
2. Operator renders re-classification at the current stage's sub-task with rationale sentence + new class declaration.
3. Hub updates the milestone description "## Release Class" H2 section via `gh api repos/{REPO}/milestones/<N> --field description=...`.
4. Hub posts a structured comment on the current stage sub-task: `[RECLASSIFY <old> → <new>] <rationale>` with link to the new milestone description.
5. Downstream stages consume the updated class via the same milestone-description read mechanism as Stage 3 Phase B3.

### Reversibility-confidence pairing per reversibility-protocol.md

- **Cheaper-to-stricter** (e.g., `routine` → `novel` or `novel` → `cross-cutting`): CHEAP reversibility — the new class adds ceremony, the per-action authorization signatures remain intact, no downstream artifacts are invalidated. HIGH confidence — the new class can revert to the original at the next gate if the original was correct.
- **Stricter-to-cheaper** (e.g., `cross-cutting` → `novel` or `novel` → `routine`): MODERATE reversibility — the new class drops ceremony; downstream stages that already absorbed the stricter posture (e.g., a Deep Stage 9 review already conducted) cannot be un-done. Requires explicit risk acceptance per reversibility-protocol.md § 3 process-weight scaling.
- **To/from hotfix**: EXPENSIVE reversibility — `hotfix` posture is defined by the corrective-scope trigger; switching to or from `hotfix` mid-release usually indicates the release scope itself is mis-defined and the release should re-bundle per § Bundle Mutability Protocol A7 in release-process.md.

## Composition

### With Autonomy Tier (per autonomy-tiers.md)

Release Class and Autonomy Tier are ORTHOGONAL. The two compose multiplicatively, not redundantly:

- Release Class operates at release level — selects engagement posture for the release as a whole.
- Autonomy Tier operates at per-action level — selects per-action authorization signature.
- A Tier 2 action in a `cross-cutting` release still produces structured handoff comments at every transition (Tight engagement density).
- The same Tier 2 action in a `routine` release surfaces only at gate boundaries (Light engagement density).

The orthogonality preserve principle drops "Autonomy Tier defaults per class" as a mapping dimension — conflating release-level class with per-action tier would create the very confusion the autonomy-tiers.md Tier Disambiguation Table discipline guards against.

### With reversibility-protocol.md

Release Class informs DENSITY of touchpoints; reversibility tier informs PROCESS WEIGHT per touchpoint. The two compose: a CHEAP-class D-decision in a `cross-cutting` release still uses 1-click approval (CHEAP reversibility) — but the Tight engagement density means the consolidated Decision Briefing on completion surfaces it, not the per-D briefing. An IRREVERSIBLE-class D-decision in a `routine` release still uses multi-input approval (IRREVERSIBLE reversibility) — but the Light engagement density means the surface around it is otherwise minimal.

### With engagement-charter.md Section 1

Section 1 declares per-action Autonomy Tier hierarchy as the per-action engagement layer. Release Class operates ABOVE the per-action layer as the release-level dispatch axis. The two layers compose: Section 1 selects per-action engagement frequency by Autonomy Tier; Release Class selects per-release density by class. Section 1's Release-level dispatch axis sub-section names this composition explicitly.

### With Methodology Variation (per release-process.md)

The Methodology Variation table parameterizes release cadence by `delivery_approach` (Scrum / Kanban / Waterfall / SAFe / ...). Release Class is a SECOND orthogonal variation axis. The two axes compose: `routine` in a Scrum context retains end-of-sprint cadence with Light engagement density; `cross-cutting` in a Waterfall context retains milestone-gate cadence with Tight engagement density.

### With Release Outcome Statement (composition flagged at Collective Review)

The Outcome Statement (release-outcome-statement-template.md) and Release Class (this doc) BOTH land sections in the milestone description. Position convention per [`release-outcome-statement-template.md § 2`](release-outcome-statement-template.md): `### Release Outcome Statement` H3 sits at top-of-description ABOVE any metadata bullets (operator-visible at-a-glance). `## Release Class` H2 sits below (drives subsequent posture; consumed by the 13-dim Readiness Scan dimension-3 anchor per release-readiness-scan-spec.md dim 3). The N-way consistency table at Collective Review confirms heading levels and positions.

### With operator-touchpoint inventory + shadow→warn→enforce convention (future siblings)

Release Class composes with two future-roadmap siblings:
- **Operator-touchpoint inventory + phase-out schema** (future): when shipped, the inventory will enumerate the operator-engagement points per release class so the per-class density column (Light/Standard/Tight) becomes auditable per-engagement-touchpoint, not just declaratively.
- **Pipeline-wide shadow→warn→enforce convention** (future): when shipped, the convention will provide a uniform graduation path applicable to per-class checks (e.g., a hotfix-only gate may enter shadow at first hotfix release, warn at second, enforce at third).

This doctrine reserves the composition surface; future siblings populate it. No action required now.

### With Discovery Discipline

Release-class re-classification IS a discovery surface — operator discovers "this is actually `cross-cutting`, not `routine`" at Stage 5 or Stage 7. Discovery Discipline § 4 names re-classification as one of the discovery outputs that surface at stage boundaries.

## Cutover

Applies to all releases entering Stage 3 going forward. Class assignment applies to every Stage 3 release.

## Cross-references

| Surface | Consumption |
|---|---|
| `release/references/pipeline/stage-03-bundle.md` | G3-10 gate criterion (Phase A1 table) + Phase 4 "Set at Bundle" field appended |
| `core/specs/engagement-charter.md` | Section 1 Release-level dispatch axis sub-section added (release-level layer above per-action Autonomy Tier hierarchy) |
| `release/references/how-to/hub-spoke-bridge.md` | Procedure 0 spoke-template bullet 7 (class proposal) + D-ReleaseClass D-Gate block; Procedure 1 Step 2.5 (class read at scaffolding); Procedure 5 Stage 9 row note (review-depth-by-class) |
| `release/governance/release-process.md` + mirror | § Methodology Variation H3 Release-Class Variation table extension |
| `core/specs/autonomy-tiers.md` | Tier Disambiguation Table extends to 5 conventions (Document / Skill / Automation / Autonomy / Release Class — see § Composition with Autonomy Tier above for orthogonality discipline) |
| `core/specs/reversibility-protocol.md` | Re-Classification Protocol consumes the 4-tier reversibility vocabulary (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) |
| `release/references/standards/decision-outcome-tracking.md` | Stage 13 Outcome-window OPTIONAL dimension composes with the SUCCESS/PARTIAL/ROLLBACK/DEFERRED enum + 30-day default window |
