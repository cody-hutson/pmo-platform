---
title: Release Outcome Statement Template
purpose: Per-release pre-execution goal anchor declared at Stage 3 Phase B3 and embedded in GitHub Milestone description as `### Release Outcome Statement` H3. Carries REQUIRED AFTER/BEFORE paragraphs + OPTIONAL Actor(s) / Success Indicator. Consumed at Stage 9 Plan Review (G-PR7 goal-conformance) and Stage 13 Close (QC4-06 + G-CL7 goal-attainment).
applies_to: All Milestones created going forward.
parallel_to: release-class-taxonomy.md (Outcome shape selects from Release Class per § 4); release-readiness-scan-spec.md (dim 3 reads Outcome Statement); release-notes-standard.md (Outcome is the pre-execution anchor that Release Notes deliver against post-merge).
distinguished_from: Roadmap Capability Outcome Statement (§ 9 disambiguation) — roadmap Outcomes span 5+ releases; this template is per-single-release.
source: "Stage 5 spec for Outcome Statement schema + Stage 3/9/13 verification cascade; operator D-decisions D-OutcomeShape STRUCTURED-AFTER-BEFORE + D-VerificationMechanism HYBRID + D-CutoverPosture REFLEXIVE-EXEMPT-ALL at Collective Review 2026-05-24."
version: v11.27
---

<!-- reference-durability: allow-link -->
<!--
  Class-L override, matching the two sibling surfaces this spec is edited alongside
  (release/references/pipeline/stage-03-bundle.md and
  release/governance/release-process.md, both of which already carry this marker).
  This file is a cross-reference spec: it carries 14 intra-repo doc links on
  pre-existing lines, each pointing at the canonical authority for a rule it
  restates. The delta gate scans ADDED lines, so any edit to a paragraph that
  already ends in such a link re-flags a reference that was never introduced by
  that edit — which is what happened when § 7.1 was reconciled to G3-11's blocking
  posture. Per the reference-durability standard's override mechanism, a per-file
  marker is preferred over a path-allowlist entry when one file needs one class.
  Placed after the frontmatter block so the doc-frontmatter parse is unaffected.
-->

# Release Outcome Statement Template

> **Source:** Stage 5 Outcome Statement spec — pre-execution goal anchor authored at Stage 3, verified at Stage 9 + Stage 13.
> **Spec issue:** Stage 5 Solutioning for Outcome Statement schema.
> **Schema decisions:** D-OutcomeShape **STRUCTURED-AFTER-BEFORE**; D-VerificationMechanism **HYBRID**; D-CutoverPosture **REFLEXIVE-EXEMPT-ALL** (per Stage 4 plan release-wide ratification).

## 1. Purpose

The Release Outcome Statement is a **pre-execution goal anchor** authored at Stage 3 Bundle alongside scope, embedded directly in the GitHub Milestone description. It answers the question *"what will this release deliver, for whom, so that what becomes true post-merge?"* — distinct from scope (which issues are bundled) and from implementation detail (the release plan).

The Outcome serves as the binding intent reference at Stage 9 Plan Review (goal-conformance check per G-PR7) and Stage 13 Close (goal-attainment verification per QC4-06 + G-CL7). Pre-execution intent + post-execution delivery (per the Change Description Protocol) + post-merge user note (per the user-facing Release Notes standard) are three paired artifacts spanning a release's life-cycle.

## 2. Schema

**Heading:** `### Release Outcome Statement` (verbatim H3) — single heading embedded directly in GitHub Milestone description; queryable via `gh api repos/.../milestones/<N> --jq .description`.

**Position:** Top-of-description, ABOVE any `**Position:**` / `**Track:**` / `**Type:**` metadata bullets currently used. Operator-visible at-a-glance on the GitHub Milestone page.

### 2.1 Empty-shape template (canonical)

```markdown
### Release Outcome Statement

**AFTER** — <1–3 sentences naming what the release delivers, for whom, and what becomes true post-merge.>

**BEFORE** — <1–3 sentences naming current state the release transitions from. Same scope and vocabulary as AFTER.>

**Actor(s):** <optional — who/what executes the AFTER capability; defaults to "hub + release-class-appropriate spokes" when omitted>

**Success Indicator:** <optional — one observable signal at Stage 13 that confirms goal attainment; verifiable evidence the AFTER state holds. When omitted, Stage 13 QC4-06 falls back to judgment-only assessment.>
```

### 2.2 Field constraints

| Field | Constraint | Verification mechanism |
|---|---|---|
| `### Release Outcome Statement` heading | Exact verbatim H3 | Stage 3 G3-11 (auto; **blocking** — bundle blocked until satisfied) — grep `^### Release Outcome Statement$` against milestone description |
| **AFTER** paragraph | 1–3 sentences; outcome-focused not scope-focused | Stage 9 G-PR7 LLM-graded recommend check (semantic conformance) |
| **BEFORE** paragraph | 1–3 sentences; current-state baseline | Stage 9 G-PR7 LLM-graded recommend check |
| `Actor(s):` | Optional; free-form | Informational only |
| `Success Indicator:` | Optional; one-line observable signal | Stage 13 QC4-06 evidence anchor when present |
| Total length | ≤6 sentences across AFTER + BEFORE | Stage 3 advisory only — length is a quality signal, not a structural gate |

### 2.3 Audit-finding rationale

R1 survey on 2026-05-24 across the then-current milestone descriptions found **a majority of milestones already use `AFTER...BEFORE`** in `## Goal` or `**Goal (AFTER/BEFORE):**` form. Canonicalizing the existing pattern minimizes authoring lift AND avoids inventing a divergent shape. Heading promoted from H2 → H3 to deconflict with consumer scripts that may grep top-level sections. The establishing release's own milestone description uses the prior `**Goal (AFTER/BEFORE):**` bold-label block form — grandfathered as satisfying the schema intent per §6 below.

## 3. Authoring guidance

The Outcome is an operator-facing voice — engineering-OK plain English, NOT marketing prose. Concrete observable outcomes; avoid status-theater verbs (`will enable`, `will support`, `is positioned to`).

### 3.1 AFTER paragraph guidance

State **post-merge state** in present tense as if the release has already shipped. Three components are typical:
1. **What capability is delivered** (the noun — the thing that now exists or is now true).
2. **For whom** (the beneficiary — usually a stage / role / external user / agent class).
3. **What becomes true** (the binding observable — the test that distinguishes "shipped" from "not shipped").

Aim for 1–3 sentences. Hotfix-class releases may use a single sentence (the post-fix observable). Novel-class releases SHOULD use 2–3 sentences spanning all three components.

### 3.2 BEFORE paragraph guidance

State **current state** in present tense — what is broken / missing / inconsistent / costly today. Use the same scope and vocabulary as AFTER (the diff between BEFORE and AFTER should be the release's delivered work).

Aim for 1–3 sentences. Hotfix-class releases may use a single sentence (or cite the broken behavior issue via `#N`).

### 3.3 Actor(s) sub-field (optional)

Names who or what executes the AFTER capability. Common patterns:
- `release-planner / hub across Stages 2–9` (release-process changes)
- `Stage 6 Engineering spokes` (substrate changes consumed by Stage 6)
- `pmo-qa-auditor` (audit-tool changes)
- `Operator at Stage 9 Plan Review` (gate-criterion changes)

Defaults to "hub + release-class-appropriate spokes" when omitted.

### 3.4 Success Indicator sub-field (optional)

One observable signal at Stage 13 that confirms goal attainment. Examples:
- `gh api repos/.../milestones/<N> --jq .description contains "### Release Outcome Statement"` for schema-establishment releases
- `core/deploy/deploy.sh --check returns exit 0 with Check N=PASS` for hook-introduction releases
- `Subsequent release's Stage 3 spoke auto-populates the Outcome heading from template` for forward-compose validation

REQUIRED for hotfix-class releases (the post-fix observable). RECOMMENDED for novel-class and cross-cutting-class releases. OPTIONAL for routine-class releases.

## 4. Class-varying Outcome shapes

Outcome length+depth varies by Release Class (per sibling [release-class-taxonomy.md](release-class-taxonomy.md) — `routine` | `novel` | `cross-cutting` | `hotfix`). Stage 3 spoke draft selects shape from class; operator may override at Phase B1.

| Class | AFTER length | BEFORE length | Success Indicator |
|---|---|---|---|
| **routine** | 1 sentence | 1 sentence | Optional |
| **novel** | 2–3 sentences | 2–3 sentences | RECOMMENDED |
| **cross-cutting** | 2–3 sentences (emphasize downstream impact) | 2–3 sentences | RECOMMENDED |
| **hotfix** | 1 sentence (post-fix observable) | 1 sentence (or "broken behavior cited in #N") | Required |

Operator override permitted with documented rationale, e.g., "this is technically routine but ships under cross-cutting Outcome shape to emphasize downstream impact."

## 5. Worked examples

### 5.1 Novel-class example (release-process foundation)

```markdown
### Release Outcome Statement

**AFTER** — Stage 3 Bundle authoring produces a canonical `### Release Outcome Statement` H3 block in every new Milestone description, structured as REQUIRED AFTER + REQUIRED BEFORE plus OPTIONAL Actor(s) + Success Indicator. Stage 9 Plan Review applies a judgment-graded goal-conformance check (G-PR7) against the assembled implementation; Stage 13 Close applies a judgment+evidence goal-attainment verification (QC4-06 + G-CL7). The Outcome is queryable via `gh api repos/.../milestones/<N> --jq .description`.

**BEFORE** — Milestone descriptions encode scope (which issues + why bundled) but the pre-execution outcome anchor is implicit, inferred ad-hoc per stage. Stage 9 has no goal-conformance check; Stage 13 verifies integrity / regression / invariants but not goal attainment.

**Actor(s):** release-planner / hub at Stage 3 Phase B3; hub at Stage 9 Phase A; Stage 13 close spoke.

**Success Indicator:** The next release entering Stage 3 (post-cutover) carries a `### Release Outcome Statement` H3 in its milestone description AND Stage 9 G-PR7 + Stage 13 QC4-06 fire against it.
```

### 5.2 Routine-class example (gate-criterion addition)

```markdown
### Release Outcome Statement

**AFTER** — Stage 2 Triage emits a Decision Date on every Approved issue, populated to the Projects Date field via `gh project item-edit`, enforced by gate G2-06.

**BEFORE** — Approved issues had no triage Decision Date field; the date was inferred from the `status: approved` label transition timestamp, which drifted across re-triage iterations.
```

### 5.3 Cross-cutting-class example (mirror discipline)

```markdown
### Release Outcome Statement

**AFTER** — `core/rules/` and `core/rules/` mirror pairs stay byte-identical across releases via `deploy.sh --check` Check 9, with spawned-agent-deny recovery codified at the hub-recovery seam (per `hub-spoke-bridge.md` Procedure 5 mirror-recovery pattern). Engineering spokes write to engineering/rules/; hub recovers core/rules/ partner. The cross-cutting impact: every release touching core/rules/ now has a deterministic recovery path, eliminating the silent-divergence class.

**BEFORE** — Spawned-agent harnesses denied .claude/ writes inconsistently across releases; mirror partners diverged silently in 3 historical releases, surfacing as deploy-time Check 9 failures only after the divergence had landed on main.

**Actor(s):** Stage 6 Engineering spokes (engineering/rules/ writes); hub (mirror recovery commits).

**Success Indicator:** Check 9 returns exit 0 across all post-cutover releases entering Stage 12 deploy verification.
```

### 5.4 Hotfix-class example (broken behavior)

```markdown
### Release Outcome Statement

**AFTER** — `deploy.sh` Check 23 RELEASE_INDEX ↔ RELEASE_LOG consistency check no longer reports false-positive drift on the release's INDEX entry; Check 23 returns exit 0 across all currently-merged releases.

**BEFORE** — Check 23 reported a false-positive drift on the INDEX entry (cited in #N), blocking `deploy.sh --check` exit 0 on every commit since 2026-05-DD.

**Success Indicator:** `core/deploy/deploy.sh --check` exits 0 with `Check 23: PASS` immediately after this release's merge SHA lands on main.
```

## 6. Anti-patterns

Six anti-patterns surface the goal-anchor-as-status-theater risk explicitly flagged in the Outcome Statement spec. Stage 9 G-PR7 LLM-graded check surfaces these on read; operator may accept divergence with documented rationale.

### 6.1 Outcome restated as scope

**Anti-pattern:**

```markdown
**AFTER** — This release ships #N, #M, and #P implementing the milestone scope.
```

**Why bad:** Restates the scope list as the outcome. The reader cannot tell what becomes TRUE from this statement; they would need to read the three issue bodies to derive the outcome.

**Fix:** State the post-merge capability the three issues collectively deliver — the noun that now exists, the test that distinguishes shipped from not-shipped.

### 6.2 Scope-list disguised as Outcome

**Anti-pattern:**

```markdown
**AFTER** — Three things land: (a) #N introduces X, (b) #M introduces Y, (c) #P introduces Z.
```

**Why bad:** Same as 6.1 — the per-issue enumeration with verbs `introduces` is still scope, not outcome. The (a)/(b)/(c) shape signals "scope list" structurally.

**Fix:** Synthesize the three deliveries into one binding capability statement. If the three are independent, declare three Outcome AFTER sentences naming what becomes true for each.

### 6.3 Missing BEFORE

**Anti-pattern:**

```markdown
### Release Outcome Statement

**AFTER** — Stage 13 closes auto-archive deferred items via the `status: deferred` label.
```

**Why bad:** Missing BEFORE breaks the transition framing — releases mediate state changes; without BEFORE the reader cannot tell what is being transitioned from.

**Fix:** Add a BEFORE paragraph naming current state (e.g., "Deferred items required manual operator disposition at Stage 13; no defined label state for re-triage routing existed.").

### 6.4 BEFORE = trivially negation of AFTER

**Anti-pattern:**

```markdown
**AFTER** — The Outcome Statement schema is canonicalized at Stage 3.
**BEFORE** — The Outcome Statement schema is NOT canonicalized at Stage 3.
```

**Why bad:** BEFORE that is mechanically `NOT(AFTER)` provides no information beyond AFTER. The reader cannot judge the size, cost, or risk of the transition.

**Fix:** Describe the current behavioral state that the release transitions from. "Milestone descriptions encode scope but the pre-execution outcome anchor is implicit, inferred ad-hoc per stage" describes the current pain — not the negation of the fix.

### 6.5 Success Indicator restated as AC

**Anti-pattern:**

```markdown
**Success Indicator:** AC #1 of #N is met; AC #2 of #M is met; AC #3 of #P is met.
```

**Why bad:** Per-issue AC verification is QC3/QC4 territory — not the release-level Success Indicator. Success Indicator should be a single observable signal that the AFTER state holds in aggregate.

**Fix:** Pick one observable that, if true post-merge, confirms the AFTER state. Usually a `gh api` query, a `grep` against committed content, a `core/deploy/deploy.sh --check` exit code, or a behavioral observation at the next release's Stage 3 entry.

### 6.6 Outcome that requires reading the release plan to understand

**Anti-pattern:**

```markdown
**AFTER** — The readiness scan ships per the release plan's §3.2 detailed mechanism.
```

**Why bad:** The Outcome should be self-contained at the Milestone description level. A reader visiting the Milestone page should understand what becomes true without opening the release plan file.

**Fix:** State the outcome plainly. "Stage 9 Plan Review applies a Release Readiness Scan against the assembled implementation; the operator sees per-dimension PASS/FAIL evidence in the Decision Briefing" is self-contained. The release plan's §3.2 then details the mechanism for engineers.

## 7. Verification mechanism (HYBRID)

Stage 9 G-PR7 + Stage 13 QC4-06 + G-CL7 form the verification cascade per D-VerificationMechanism HYBRID. Mechanism:

### 7.1 Stage 3 G3-11 (auto, blocking)

After Phase B3 (Milestone creation), assert milestone description contains `### Release Outcome Statement` H3. **Blocking — the bundle is blocked until satisfied**, matching G3-10, alongside which this criterion is always evaluated. Graduated advisory→blocking; the graduating population was measured and it was empty (the milestones lacking the Outcome Statement were *exactly* those lacking the Release Class, which G3-10 already blocks), so the flip newly blocked zero milestones. Pre-cutover-or-exempt releases: the existing `## Goal` / `**Goal (AFTER/BEFORE):**` form is grandfathered for read purposes. See [`gate-criteria-spec.md` Gate 3](../../../core/schemas/gate-criteria-spec.md#gate-3-release-readiness) row G3-11.

### 7.2 Stage 9 G-PR7 (judgment-recommend goal-conformance)

Hub reads the Outcome Statement from the GitHub Milestone description, reads the PR scope, reads the release plan §Implementation Sequence + File Change Matrix, AND reads each release-scoped issue AC. Produces a 1-paragraph conformance narrative answering "does the assembled implementation deliver the AFTER state?" Verdict: **ALIGNED** / **DIVERGED-WITH-RATIONALE** / **MISALIGNED**.

- **ALIGNED** → no operator action; GO recommendation supported.
- **DIVERGED-WITH-RATIONALE** → operator documents in Decision Record before GO.
- **MISALIGNED** → NO-GO recommendation (operator may override).

Recommend-tier (not block-tier) by design — goal-conformance is judgment-graded; the LLM scan provides the recommendation; the operator renders the binding decision. See [`gate-criteria-spec.md` Gate 9](../../../core/schemas/gate-criteria-spec.md#gate-9-plan-review) row G-PR7.

### 7.3 Stage 13 QC4-06 (judgment+evidence goal-attainment, non-blocking)

Stage 13 spoke reads the Outcome Statement from the Milestone description AND reads post-deploy state evidence (Change Description per the Change Description Protocol + QC4-01..04 results + Success Indicator field when present). Produces a 1-paragraph attainment narrative answering "does post-deploy main exhibit the AFTER state?" Verdict: **ATTAINED** / **PARTIALLY-ATTAINED** / **NOT-ATTAINED**.

- **ATTAINED** → narrative cites Change Description + Success Indicator (when present) + ≥1 verifiable evidence anchor. Composes with decision-outcome-tracking.md capture: ATTAINED → SUCCESS.
- **PARTIALLY-ATTAINED** → surface diagnostic for operator routing. Composes with: PARTIALLY-ATTAINED → PARTIAL.
- **NOT-ATTAINED** → surface diagnostic. Composes with: NOT-ATTAINED → SUCCESS-document-divergence OR ROLLBACK per operator.

Non-blocking for milestone close — routing options per Stage 13 Phase A goal-attainment verification protocol (A) immediate-hotfix Issue / (B) carry-forward Issue / (C) accept-as-residual.

### 7.4 Stage 13 G-CL7 (verdict-presence gate, warn-mode initial)

Goal-attainment verification recorded (QC4-06 verdict present in release plan Verification Evidence section). Initial warn-mode posture per [`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent — per-release FAIL logs to `core/hooks/qc4-06-warn-log.jsonl` and Milestone close proceeds. Flip to enforce after 2-3 release shakedown. See [`gate-criteria-spec.md` Gate 13](../../../core/schemas/gate-criteria-spec.md#gate-13-close-readiness) row G-CL7.

## 8. Composition with paired artifacts

Three artifacts span a release's life-cycle. Outcome (pre-execution intent) ↔ Change Description (post-implementation operator-facing) ↔ Release Notes (post-merge user-facing).

| Artifact | Authoring stage | Audience | Voice | Surface | What it answers |
|---|---|---|---|---|---|
| **Release Outcome Statement** (this template) | Stage 3 Bundle (pre-execution) | Operator + agents (intent anchor) | Future-tense plain-but-engineering-OK | GitHub Milestone description (`### Release Outcome Statement` H3) | "What will this release deliver, and from what current state?" |
| **Change Description** (Change Description Protocol) | Stage 6 Engineering (post-implementation, pre-merge) | Operator (pre-merge review) | Past/present-tense engineering-OK | Release plan FILE `## Change Description` section, visible in PR diff at Stage 9 | "What did this release deliver, what changed, what is the reversibility posture?" |
| **User-Facing Release Notes** (User-Facing Release Notes standard) | Stage 13 Close (post-merge) | Non-technical platform users | Past-tense plain language | `release/releases/notes/vX.Y_RELEASE_NOTES.md` | "What user-visible capability changed, what affected my workflow?" |

**Cross-reference rules:**

- This template references [`release/governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Change Description Protocol — Outcome (pre) and Change Description (post) are paired artifacts.
- `RELEASE_PROTOCOL.md` § Change Description Protocol cross-references back to this template: "The Change Description complements the Stage 3 Release Outcome Statement (per this template) — Outcome anchors pre-execution intent; Change Description summarizes post-implementation delivery; release notes target end users at post-merge time."
- [`release-notes-standard.md`](../standards/release-notes-standard.md) cross-references this template: "Release notes are the user-facing third artifact in the Outcome (pre) → Change Description (post-engineering) → Release Notes (post-merge user-facing) chain."

**Verbatim re-use prevention:** The Outcome Statement and Change Description MUST differ. Outcome is intent-forward (future-tense capability statement); Change Description is delivery-narrative (what changed, what files, what decisions). Stage 6 spoke composes the Change Description by reading the Outcome Statement and the actual PR scope; if the two read identically, that is a structural defect surfaced by Stage 9 G-PR7 (the Outcome was scope-restated as scope, not goal-anchored).

## 9. Distinguished from roadmap-level Capability Outcome Statement

`<OPERATOR_INSTANCE_ROADMAPS_PATH>/*.md` files (operator-local) contain `## 1. Capability Outcome Statement` sections per [`initiative-roadmap-framework.md`](../../../core/standards/initiative-roadmap-framework.md). These are a **different concept** from the per-release Outcome Statement defined here.

| Concept | Scope | Surface | Time-horizon |
|---|---|---|---|
| **Roadmap Capability Outcome Statement** | Cross-milestone capability vision (e.g., "automation maturity reaches Tier 2 across all Stage 4-13 spokes") | `<OPERATOR_INSTANCE_ROADMAPS_PATH>/<area>.md` § 1 (operator-local) | Long-tail; spans 5+ releases; reviewed event-bound + 90-day staleness fallback |
| **Release Outcome Statement** (this template) | Per-release goal anchor (e.g., "this release establishes the pre-execution Outcome schema") | GitHub Milestone description `### Release Outcome Statement` H3 | Single-release scope; authored at Stage 3; verified at Stage 9 + Stage 13 |

The two compose: a single roadmap Capability Outcome Statement is delivered incrementally across multiple releases; each contributing release carries its own Release Outcome Statement naming its slice of the roadmap capability.

The naming collision is a residual drift surfaced during R1 survey on 2026-05-24 — readers may confuse the two without explicit disambiguation. This §9 is the disambiguation surface; no file changes to roadmaps are required.

## 10. Cutover

This protocol applies to all Milestones created going forward. Pre-existing milestones are grandfathered — the protocol applies prospectively and does not retroactively amend milestone descriptions authored before it. Stage 13 G-CL7 (QC4-06 verdict presence) is warn-mode initial, flipping to enforce after a 2-3 release shakedown.

**Future-state migration:** The establishing release's existing `**Goal (AFTER/BEFORE):**` block form may later be renamed via an operator-discretion Tier 1 [ADJUST] commit to `### Release Outcome Statement` to align with the canonical schema, OR the existing form is grandfathered indefinitely. Decision deferred — non-blocking.

## 11. Consumers

| Surface | Consumption point | Reference |
|---|---|---|
| Stage 3 Bundle authoring | Phase B3 Milestone-description authoring | [`pipeline/stage-03-bundle.md`](../pipeline/stage-03-bundle.md) § 5 Phase B |
| Stage 9 Plan Review | Phase A goal-conformance check | [`pipeline/stage-09-plan-review.md`](../pipeline/stage-09-plan-review.md) § 5 Phase A |
| Stage 13 Close | Phase A goal-attainment verification | [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) § 5 Phase A |
| Gate criteria schema | G3-11 / G-PR7 / QC4-06 / G-CL7 rows | [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) Gates 3/9/13 |
| Release-process rules | Stage 3 / Stage 9 / Stage 13 entries; Checkpoint 4 table | [`release/governance/release-process.md`](../../governance/release-process.md) (+ mirror [`release/governance/release-process.md`](../../governance/release-process.md)) |
| Hub Decision Briefing | Procedure 0 Phase B1 + Procedure 5 Stage 9 evidence package | [`how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) Procedures 0 + 5 |
| Release planning skill | Mode A Phase A Stage 3 deliverables | [`skills/release-planner/SKILL.md`](../../skills/release-planner/SKILL.md) Mode A |

## 12. Versioning

**Template version:** 1.0
**Source issue:** Stage 5 Outcome Statement spec
**Stage 5 spec:** Outcome Statement Stage 5 sub-task
**Introduced in:** pipeline-fitness-foundation

Future versions follow the pmo-platform standards versioning convention — non-breaking additions bump minor (1.0 → 1.1); breaking changes (heading rename, required-field additions) bump major (1.x → 2.0) with cutover clause.
