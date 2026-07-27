<!-- reference-durability: allow-link -->
# Triage→Design Re-Review Standard

## Purpose

Defines the re-review artifact required at the Triage→Design handoff (Stage 4 entry, Stage 5 entry) — the schema, dimensions, classifications, premise-problem types, escalation workflow, and phased authority arc that govern how Stage 4/5 spokes interrogate upstream Triage output before producing design output.

This standard closes the design-stages-inherit-Triaged-framing gap: design stages today inherit Triaged-ticket framing without re-interrogating requirements against best practices, platform-localized knowledge, or learnings. After this standard, design stages produce a structured re-review artifact at stage entry per issue, classify each requirement, and route premise-problems through a dedicated `Tier 0 — Premise Rejection` workflow distinct from Tier 1/2/3 mid-execution feedback.

## Status

This standard is the canonical home for the Triage→Design re-review schema. Cross-referenced from:

- [`pipeline/stage-04-planning.md`](../pipeline/stage-04-planning.md#5-process) (Phase A0) and [`pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md#5-process) (Phase 0.5)
- [`release/governance/release-process.md`](../../governance/release-process.md) Inter-Stage Feedback Protocol (Tier 0 — Premise Rejection)
- [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) Stage 3→4 + Stage 4→5 boundaries

Cutover: see § 4. Phase 1 instrumentation: see [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/triage-design-rereview-instrumentation.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/triage-design-rereview-instrumentation.md).

---

## § 1 Schema

The re-review artifact is the **first** section of every Stage 4 sub-task comment (Phase A0 output) and Stage 5 sub-task comment (Phase 0.5 output), placed BEFORE `### Output for Stage N+1`. One artifact per issue per stage entry.

### Header metadata (required, 8 fields)

| Field | Type | Source |
|---|---|---|
| `issue_number` | `#N` | Parent issue |
| `release_milestone` | `vX.Y` | Active Milestone |
| `stage` | `4` or `5` | Stage of detection |
| `spoke_author` | string | Agent identity or operator name |
| `re_review_date` | ISO date | Spoke timestamp |
| `issue_body_revision` | ISO timestamp | `gh issue view --json updatedAt` value at re-review time |
| `triage_decision_date` | ISO date | Date Stage 2 rendered Approved |
| `effort_tier` | `trivial` / `standard` / `complex` | Per § 7 effort-sizing |

### Per-requirement table (6 columns)

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1 / AC2 / proposed-change-N / risk-N | finding + citation | finding + citation | finding + citation | C1 / C2 / C3 | (C2) proposed delta text; (C3) PT-1 / PT-2 / PT-3 / PT-4 |

**Output discipline (inherited verbatim from [`review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md) § 1):**

- **Rule 1 (no surface-level passes)** — every dimension produces a concrete finding or concrete verification.
- **Rule 3 (no finding-free dimensions)** — "no concerns" requires positive evidence, not absence-of-failure.
- **Rule 4 (no symptom-only)** — root-cause format applies to PT classifications: systemic pattern → proximal cause → observable signal.
- **Rule 9 (no narrative padding)** — findings are evidence + citation, not commentary.

---

## § 2 Dimensions

Every requirement is evaluated against three named dimensions. Each dimension MUST produce a finding line per Rule 3 (no finding-free dimensions). Citation discipline is strict per dimension; generic-pattern citations alone are not acceptable.

| Dim | Name | Definition | Required citations |
|---|---|---|---|
| **D1** | **Best practices** | Applicable patterns from platform reference docs that govern review/decision/principal/failure-mode/reversibility discipline. | Cite specific section(s) of [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md), [`review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md), [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), [`reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md), [`principal-standard-checklist.md`](../../../core/standards/principal-standard-checklist.md), or [`AUDIT_FRAMEWORK.md`](../../../core/standards/AUDIT_FRAMEWORK.md) if invoked. "Platform conventions" alone is not a citation. |
| **D2** | **Platform-localized knowledge** | Existing patterns, prior decisions, governance constraints, current architecture. | Cite specific files/sections (e.g., [`architecture-overview.md`](../../../core/disciplines/architecture-overview.md), governance file map in [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>)), closed ADR issue numbers, or recent merged releases by version. "Architecture" alone is not a citation. |
| **D3** | **Learnings** | Outcomes from prior cycles (release retrospectives, deviation logs, post-deploy verification, calibration data, iteration logs, memory feedback). | Cite specific release version + retro section, deviation log entry in [`release/releases/plans/<vX.Y>_RELEASE_PLAN.md`](../../releases/plans/), post-deploy verification line in [`RELEASE_LOG.md`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>), [`calibration-data.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) row, or [`iteration-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md) row. "Prior experience" is not a citation. |

**Cousin pattern (related, not parent):** [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) § 2.1 Mechanism 1 (Localization Check) operates at the decision-class briefing point (pre-decision interrogation by hub). The Triage→Design re-review operates at the design-stage entry handoff (pre-design interrogation by spoke of upstream Triage output). Different operating contexts; cousin patterns. D2 (Platform-localized knowledge) cites Mechanism 1 as a pattern to apply, not a parent doc to extend.

---

## § 3 Classifications

Each requirement is classified as exactly one of three states. The classification determines stage routing.

| Cls | Name | Definition | Routing |
|---|---|---|---|
| **C1** | **Survives verbatim** | Re-review confirms the requirement is correct and complete; no delta. | Stage proceeds. Artifact records C1 with citations supporting the confirmation (Rule 3 — no finding-free dimensions). |
| **C2** | **Needs refinement** | Re-review identifies a non-fundamental gap, ambiguity, or improvement opportunity. | Stage proceeds with refined requirement. Delta logged as Tier 1 [ADJUST] per Inter-Stage Feedback Protocol — commit the refinement to the issue body or release plan. |
| **C3** | **Should be challenged** | Re-review identifies a fundamental premise problem (stale assumption, subsumption, best-practices conflict, learnings contradiction). | Triggers Tier 0 — Premise Rejection workflow (§ 9 escalation block + § 10 phased authority). Stage HOLDS until operator (Phase 1) or Tier 0 routing (Phase 2) renders decision. |

### Premise-problem types (PT — taxonomy for C3 classifications)

Every C3 classification declares one PT **or one § 11 lens class**. The PT taxonomy types *premise-problem* C3s — a premise that is structurally invalid — and routes the Tier 0 workflow (§ 9 / § 10); the § 11 lens types *warrant* and *placement* C3s and routes to an operator-judgment disposition, **never** Tier 0. Citation discipline per PT is strict; soft language (`seems like`, `may have`, `possibly`) in any PT-1 / PT-2 citation auto-routes the rejection to Tier 0b in Phase 2 (see § 10).

| PT | Name | Trigger | Citation discipline |
|---|---|---|---|
| **PT-1** | **Stale-assumption** | Requirement based on platform state that has changed since Triage. | MUST cite specific commit SHA / merged-PR # / governance file move with date. |
| **PT-2** | **Subsumption** | Requirement subsumed/contradicted by closed ADR or merged release. | MUST cite ADR issue # OR release version + RELEASE_LOG line AND a freshness-check command + result line + check timestamp per § 3.1. |
| **PT-3** | **Best-practices conflict** | Requirement contradicts established review/decision/principal/failure-mode discipline. | MUST cite specific `core/<doc>.md` section. |
| **PT-4** | **Learnings contradiction** | Requirement repeats a pattern prior retrospective explicitly flagged as anti-pattern. | MUST cite specific retrospective + finding ID OR `feedback_*` memory file. |

### § 3.1 PT-2 freshness-check sub-step

When a re-review classifies any requirement as **C3 / PT-2 (Subsumption)** —
specifically, premise problems citing other-release state ("vX.Y has shipped"
/ "vX.Y has NOT yet shipped" / "release vX.Y closed-out the issue") — the
spoke MUST execute a freshness-check against current GitHub Milestone state
BEFORE finalizing the PT-2 citation and BEFORE constructing the § 9 Tier 0
escalation block.

**Command:**

```bash
gh api 'repos/{REPO}/milestones?state=all&per_page=100' \
  --jq '.[] | select(.title | startswith("v<VERSION_PREFIX>")) | {title, state, closed_at}'
```

Substitute `<VERSION_PREFIX>` with the citation's version (e.g., `v1.01`,
`v1.07b`, `v1.04b-1`). Use the most-specific prefix the citation supports.
For repos with > 100 total milestones, add `--paginate`.

**Result interpretation:**

| Result | Interpretation | Action |
|---|---|---|
| Empty (no rows) | No milestone matches the citation's version prefix | Reformulate citation OR downgrade C3 → C2 (citation was based on a non-existent release) |
| 1+ rows, ALL `state: open` (no `closed_at`) | Cited release has NOT shipped | PT-2 citation reading "has NOT yet shipped" is CURRENT — proceed to § 9 block construction |
| 1+ rows, ANY `state: closed` (with `closed_at` timestamp) | Cited release HAS shipped | Re-evaluate: does the requirement's premise still hold under shipped-state evidence? If YES, reformulate citation with shipped-state context (cite `closed_at` + RELEASE_LOG line); if NO, downgrade C3 → C2 or C1 (premise was based on stale "not-yet-shipped" framing) |
| Mixed (some open, some closed under same prefix) | Multiple milestones share the prefix (e.g., v1.01* family) | Inspect each row; cite the specific milestone whose state grounds the premise; reformulate ambiguous citations |

**Required block in PT-2 citation (verbatim format):**

```
Freshness-check:
  Command: gh api '...milestones?state=all...' --jq '...startswith("vX.Y")...'
  Result: <one-line JSON from the command, OR "empty (no matches)">
  Checked at: <YYYY-MM-DDThh:mm:ssZ> (re-review timestamp)
```

This block lives in the per-requirement table's "Delta or Premise-Problem
Type" column for the PT-2 row, AND propagates into the § 9 escalation block
template's "Re-review evidence" block as the freshness-check evidence line.

**Cutover:** Applies to all releases entering Stage 4 going forward.

**Originating evidence:** a Stage 4 spoke constructed a Tier 0 PT-2
block on a premise that an upstream release had not shipped; that
release's methodology-parameterization-core milestone had actually
closed 2026-04-24. The Stage 5 spoke caught the gap empirically and
downgraded the escalation to Tier 1 [ADJUST]. The Candidate-A command
would have surfaced the closure at Stage 4 Phase A0 construction time.

**Tier 0a interaction (Phase 2 only):** Per § 10 Phase 2 Tier 0a citation
discipline (PT-1 + PT-2), the freshness-check command + result line is a
HARD requirement of the citation. Citations missing the freshness-check
block, or citing soft-language interpretation of the result, downgrade
autonomously to Tier 0b (operator-approved).

---

## § 4 Cutover

This re-review protocol applies to releases that enter Stage 4 on or after `2026-04-25`. Releases whose Stage 4 sub-task was created prior to that date are exempt — they predate the protocol. The cutover date is recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>).

### Applicability rule

| Release | Re-review protocol |
|---|---|
| Releases that ENTERED Stage 4 (Stage 4 sub-task created) BEFORE the cutover effective date | EXEMPT — pre-protocol releases. Example: any in-flight release with Stage 4 already opened pre-cutover. |
| Releases that ENTER Stage 4 ON OR AFTER the cutover effective date | SUBJECT — re-review artifact required at Stage 4 Phase A0 + Stage 5 Phase 0.5. |

Date comparison: Stage 4 sub-task `created_at` timestamp vs. cutover effective date. Tie-breaker: if same calendar day, the release is SUBJECT (default to enforcement).

---

## § 5 Worked Example

The example below re-reviews two of the originating ticket's own ACs against D1 / D2 / D3, exercising the schema on the kind of input it will receive in production. Self-referential by design — demonstrates the schema's self-application against its own originating ticket.

```
Re-Review Artifact — Issue #N, Stage 5, 2026-04-25

## Header
issue_number: #N
release_milestone: vX.Y-premise-interrogation-hotfix
stage: 5
spoke_author: Stage 5 Solutioning spoke
re_review_date: 2026-04-25
issue_body_revision: 2026-04-25T<HH:MM>Z (last edit pre-Stage-5)
triage_decision_date: 2026-04-25
effort_tier: standard

## Per-requirement table
| Requirement | D1 finding | D2 finding | D3 finding | Cls | Delta/PT |
|---|---|---|---|---|---|
| AC2: schema enumerates 3 named dimensions | review-discipline-principles.md Rule 3 ("no finding-free dimensions") supports requiring all 3 dimensions to produce a finding line — adopting Rule 3 as schema rule strengthens AC2 from enumeration-only to enumeration+enforcement | architecture-overview.md describes core/standards/ as the canonical home for cross-cutting structural standards (canonical-skill-structure, principal-standard-checklist) — supports placing the schema there | a prior retrospective (Evidence section) shows that schema-only enumeration without enforcement let dir-naming canonicalization slip past 4 review layers — supports adding enforcement, not just enumeration | C2 | Refine AC2 to "schema enumerates 3 named dimensions WITH per-dimension required citation discipline." Logged as Tier 1 [ADJUST] commit on standards doc (no change to the issue body since AC2 already reads correctly when the standards doc spec is consulted). |
| AC4: design stages have authority to return to Triage, distinct from Tier 1/2/3 | release-discipline: Inter-Stage Feedback Protocol Tier 1/2/3 fires AT STAGE EXECUTION; AC4 fires AT STAGE ENTRY — architecturally distinct, supports a separate Tier 0 rather than amending Tier 1/2/3 | release/governance/release-process.md L51-75 contains Tier 1/2/3; grep returns 0 matches for "premise rejection" / "return to triage" — confirms gap is real | the pipeline-self-governance discipline: route through pipeline rather than skip to engineering — supports formalizing Tier 0 in protocol rather than ad-hoc out-of-band returns | C1 | (verbatim) |
```

**Sequence demonstrated:** input ticket → re-review output (per-requirement table with D1/D2/D3 findings + citations) → classification (C2 for AC2 / C1 for AC4) → outcome (C2 routes to Tier 1 [ADJUST] refinement of standards doc; C1 routes to stage-proceeds-verbatim).

---

## § 6 Stage 5 delta procedure

Stage 5 Phase 0.5 always-fires per release scoped to the issue. The procedure differs based on staleness and blast-radius context relative to the Stage 4 Phase A0 artifact.

### Delta-only re-review (default)

When ALL of the following hold, Stage 5 produces a **delta-only** artifact that re-evaluates against D2 + D3 only:

- Stage 4 re-review artifact exists for this issue, AND
- Stage 4 re-review predates Stage 5 entry by ≤ 7 days, AND
- Stage 5 A3 blast-radius analysis surfaces no new context invisible at Stage 4

Delta-only artifact format: header metadata + per-requirement table with D2 + D3 columns only (D1 marked "delta-skip — no change to best-practices universe in ≤7 days"). C2 / C3 still trigger their respective routings.

### Full re-review (triggered)

When ANY of the following hold, Stage 5 produces a **full** artifact:

- Stage 4 re-review artifact predates Stage 5 entry by > 7 days
- Stage 5 A3 blast-radius analysis exposes context invisible at Stage 4 (e.g., new dependency, new file claim, new risk)
- Operator manually requests full re-review

Full artifact format identical to § 1 Schema; effort tier may upgrade from Stage 4 (e.g., Stage 4 `standard` → Stage 5 `complex` if blast-radius expands).

---

## § 7 Effort-sizing

Re-review artifact form scales with issue size and scope. The spoke determines tier from issue labels (`size:XS/S/M/L/XL` + content scope) at the top of the re-review artifact. Tier downgrades require operator approval; tier upgrades are autonomous.

| Tier | Trigger | Artifact form |
|---|---|---|
| **Trivial** | Issue size = XS OR S AND scope = doc-only (no skill, no governance, no schema, no protocol change) — XS folds into Trivial alongside S because an XS-sized doc-only change carries the same minimal blast radius as S and warrants the same one-line-per-dimension form | One-line-per-dimension artifact: each of D1 / D2 / D3 gets a single-line finding/verification with at least one citation. Per-requirement table optional. |
| **Standard** | Issue size = M OR scope touches governance / skill / schema / protocol | Full artifact with header metadata + per-requirement table + all 3 dimensions per requirement. |
| **Complex** | Issue size = L/XL OR scope is cross-cutting (≥3 governance files) OR Solutioning activates with non-trivial blast radius | Standard artifact + cross-issue cross-reference section (citations to other issues in the same Milestone) + explicit blast-radius re-validation against the Solutioning Phase A3 output. |

---

## § 8 Phase 1 instrumentation reference

Phase 1 instrumentation captures evidence to evaluate graduation thresholds (§ 10). The instrumentation log is append-only.

**File:** [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/triage-design-rereview-instrumentation.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/triage-design-rereview-instrumentation.md)

**Schema (13 fields per row):**

| Field | Type | Source |
|---|---|---|
| `release_version` | string | Active Milestone version |
| `issue_number` | int | Issue # |
| `stage` | enum | `4` or `5` |
| `re_review_date` | ISO date | Spoke timestamp |
| `effort_tier` | enum | Spoke-determined: `trivial` / `standard` / `complex` |
| `requirements_count` | int | Per-requirement table row count |
| `c1_count` / `c2_count` / `c3_count` | int | Per-classification tallies |
| `c2_deltas_logged` | int | Count of [ADJUST] commits issued for C2 deltas |
| `c3_pt_distribution` | map | PT-1 / PT-2 / PT-3 / PT-4 counts among C3 classifications |
| `c3_outcomes` | enum-list | Per-C3: `return-to-triage` / `override` / `defer-to-next-release` |
| `false_positive_flagged` | bool | Operator-flagged at Stage 13 retro: C3 raised but premise was actually correct |
| `wall_clock_minutes` | int | Spoke-reported re-review duration |
| `downstream_rework_avoided` | int 1-5 | Operator score at Stage 13: did re-review prevent downstream rework? |

**Append cadence:** every Stage 4 Phase A0 invocation and every Stage 5 Phase 0.5 invocation (full or delta) appends one row. `false_positive_flagged` and `downstream_rework_avoided` are filled at Stage 13 mechanical close — no separate retrospective ceremony.

**Stage 13 RELEASE_LOG.md addition:** every vX.Y entry post-cutover includes a `Re-Review Instrumentation` line with row count appended this release, plus operator-rated `downstream_rework_avoided` summary per C2/C3 invocation.

**Phase 1 baseline:** baseline established after N=20 invocations (per § 10 R-Met-2). Until baseline, no graduation assessment is performed.

---

## § 9 Tier 0 — Premise Rejection escalation block template

When any requirement is classified C3, the Stage 4/5 spoke STOPS work on the affected issue, posts the escalation block below on the parent issue (NOT the sub-task), and HOLDS the sub-task open until operator decision (Phase 1) or Tier 0 routing (Phase 2).

```
## [TIER 0 — PREMISE REJECTION]
**Issue:** #{N}
**Stage of detection:** {4 | 5}
**Spoke sub-task:** #{SUB_TASK}
**Re-review artifact:** {comment URL}
**Challenged requirement(s):** {AC reference / proposed-change reference / risk reference}
**Premise-problem type:** {PT-1 stale-assumption | PT-2 subsumption | PT-3 best-practices conflict | PT-4 learnings contradiction}
**Re-review evidence:**
  - D1 (best practices): {finding + citation}
  - D2 (localized knowledge): {finding + citation}
  - D3 (learnings): {finding + citation}
**Freshness-check (REQUIRED for PT-2 per § 3.1):**
  - Command: `<verbatim gh api command>`
  - Result: `<one-line JSON or "empty">`
  - Checked at: `<YYYY-MM-DDThh:mm:ssZ>`
  - Interpretation: `<one of: state-current-proceed | state-changed-reformulated | empty-downgrade-recommended>`
**Premise problem (root cause):** {systemic pattern → proximal cause → observable signal, per review-discipline-principles.md § 2}
**Recommendation (one of):**
  - (A) Return to Triage — re-bundle issue with re-review evidence as input
  - (B) Override + proceed with deviation log — operator reviews and decides re-review evidence is insufficient
  - (C) Defer to next release — issue removed from current Milestone
**Reversibility / Confidence:** {tier} / {confidence}
```

### Operator decision options (verbatim authority list)

- **(A) Return to Triage** — Issue Status → Triage; Stage 4/5 sub-task closed with `Returned to Triage per Tier 0 — Premise Rejection` comment + link to the re-review artifact; Triage re-runs with re-review evidence as Triage input. Issue may re-bundle into the same Milestone if Triage outcome supports, or be excluded from the Milestone (operator decision at re-bundle time).
- **(B) Override + proceed with deviation log** — operator records the override decision with rationale on the issue; Stage proceeds; deviation log entry appended to release plan's "Deviation Log" section. Sub-task continues.
- **(C) Defer to next release** — Issue Status → Approved; issue removed from current Milestone via `gh issue edit --remove-milestone`; Stage 4/5 sub-task closed with `Deferred to next release per Tier 0 — Premise Rejection`.

---

## § 10 Phased rejection authority

The Tier 0 — Premise Rejection workflow phases its authority to align operator load with reliability + quality evidence. Phase 1 = operator-approved on all PT classifications. Phase 2 = tiered, gated on graduation thresholds.

### Phase 1 protocol — Operator-Approved (always)

**Default:** All Tier 0 escalations are operator-approved. No autonomous returns. The escalation block template (§ 9) is posted on the parent issue; the spoke sub-task HOLDS until operator decision (A / B / C).

**Architectural distinction from Tier 1/2/3:** Tier 0 fires at **stage ENTRY** (before the stage produces output); Tier 1/2/3 fire at **stage EXECUTION** (mid-process feedback when downstream stage discovers upstream artifact problem). Numbering communicates "fires earlier than Tier 1" — Tier 0 is not a downgrade of severity; it is a different temporal anchor.

### Graduation criteria schema

**Reliability metrics (must ALL hold for ≥M consecutive evaluation windows to enable graduation):**

| Metric ID | Description | Measurement | Threshold |
|---|---|---|---|
| **R-Met-1** | False-positive rate over rolling N invocations | `false_positive_flagged` ÷ total C3 invocations, computed over trailing N C3 invocations | ≤ 10% over rolling N=10 |
| **R-Met-2** | Total Phase 1 invocations since baseline | Sum of all re-review artifacts, all stages, all releases since baseline | ≥ 20 |
| **R-Met-3** | Operator-approved returns to Triage since baseline | Count of `c3_outcomes = return-to-triage` since baseline | ≥ 5 |

**Quality metrics (must ALL hold for ≥M consecutive evaluation windows):**

| Metric ID | Description | Measurement | Threshold |
|---|---|---|---|
| **Q-Met-1** | Average `downstream_rework_avoided` score | Mean over trailing N=10 invocations | ≥ 3.5 / 5 |
| **Q-Met-2** | Returned-to-Triage tickets re-emerge with materially different scope | Operator-rated at re-bundle time: did the re-bundled issue body differ from pre-return body in non-trivial ways? | ≥ 70% |
| **Q-Met-3** | Critical false-positive incidents in trailing N invocations | "Critical" = operator-flagged "should not have been challenged; caused harm via delay or downstream rework" | 0 |

**Window:** ≥ 2 consecutive evaluation windows; each window = 5 releases or 30 days, whichever first.

### Cutover process (Phase 1 → Phase 2): operator-approved cutover

When metrics cross thresholds, the agent posts a `Phase 1 → Phase 2 Graduation Recommendation` comment on a `governance-improvement` issue tracking the graduation arc. Operator approves or rejects via comment. Approval triggers a governance change (single-line edit in [`release/governance/release-process.md`](../../governance/release-process.md) and mirror, plus a config field in this standards doc) — this is itself a governance change subject to "No ungoverned changes" protocol (separate Issue + plan + approval).

**Why operator-approved (not auto-trigger):** symmetric to [`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist — "Operator confirms readiness via commit to `.mode` change." Auto-trigger inverts agency: the system declares itself ready instead of operator confirming readiness.

### Reversion criteria (Phase 2 → Phase 1): AUTO-TRIGGER

Reversion fires when ANY of:

| Trigger | Threshold |
|---|---|
| Critical false-positive incident | 1 incident, operator-flagged |
| Rolling FP rate exceeds threshold | > 15% over trailing 10 invocations |
| Operator-issued reversion command | Manual override |

**Why auto-trigger reversion (asymmetric with cutover):** symmetric to [`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) "Roll back to `warn` (single-file edit) if issues surface." Reversion is the safety direction (more gates = safer); auto-trigger eliminates a window where harm continues while waiting for operator approval. Cutover is the risk direction; operator-approved.

### Phase 2 protocol — Tiered (Tier 0a + Tier 0b)

#### Tier 0a (autonomous-minor) — applies to PT-1 and PT-2

Premise-problem types with crisp, objectively-verifiable citations: PT-1 cites a specific commit SHA / merged-PR # / file move with date; PT-2 cites a closed ADR # or release version. The agent CAN verify these citations programmatically (`gh issue view`, `git log`, `grep` file existence) — judgment is not load-bearing. Autonomous action is appropriate.

**Tier 0a action:** spoke posts the Tier 0 escalation block as a notification on the operator's project board (not on the parent issue), executes Action (A) Return to Triage autonomously, and proceeds to close the sub-task with `Returned to Triage per Tier 0a — autonomous` comment.

**Tier 0a citation discipline (REQUIRED — strict):**

- PT-1 citation MUST include: file path + commit SHA + commit date + grep-verifiable change.
- PT-2 citation MUST include: ADR issue # closed-state + decision-text excerpt OR release version + RELEASE_LOG line AND, when citing release-state framing, MUST include freshness-check block per § 3.1 (command + result + timestamp). Missing freshness-check block downgrades to Tier 0b automatically.
- Soft language (`seems like`, `may have`, `possibly`) in any citation downgrades to Tier 0b automatically.

#### Tier 0b (operator-approved-major) — applies to PT-3 and PT-4

Premise-problem types where citation criteria are interpretive: PT-3 evaluates whether a requirement contradicts a reference doc rule (subjective when the rule has multiple valid interpretations); PT-4 evaluates whether a requirement repeats a pattern flagged in a retrospective (pattern-matching is judgment-laden). Adversarial spoke posture combined with autonomy can fabricate premise problems in this band.

**Tier 0b action:** identical to Phase 1 protocol — operator-approved, escalation block posted on parent issue, sub-task HOLDS.

### Notification queue

Tier 0a returns are aggregated into a notification queue accessible at session start. Operator reviews at session start, can override any Tier 0a decision (`override + proceed with deviation` retroactively re-classifies the rejection).

---

## § 11 Premise-Provenance & Abstraction-Altitude Lens

A C3 in § 3 asks *"is this requirement's premise structurally invalid?"*. This section asks two different
questions about the work item as a whole: **is the problem real** (warrant), and **is the solution at the
abstraction the live architecture should own** (placement). Neither is a staleness signal — the premise may be
entirely intact — so neither is a PT, and neither routes Tier 0.

**Unit of analysis: the card** (the work item), NOT the requirement. D1 / D2 / D3 evaluate every requirement; this
lens classifies the item once. Do not apply it per-AC.

**Invocation: consumer-invoked, not always-fires.** This section is a capability a named consumer invokes; it adds
no obligation to the § 1 artifact, the § 6 delta procedure, or the § 8 instrumentation, and it changes no existing
schema field. First consumer: the `release-hub` Mode R milestone-readiness checklist, group 9. Omission when no
consumer invokes it is the correct non-ceremony signal.

**Why this is a sibling of the PT taxonomy rather than a member of it.** Three reasons, each independently
sufficient: (1) every PT projects onto the structural staleness band by definition (Tier 0 fires only on a
premise-level finding), whereas a warrant or placement finding leaves the premise intact and sits **off** the
staleness scale entirely; (2) a PT triggers the § 9 Tier 0 workflow, which STOPS work and HOLDS the sub-task,
whereas these findings must reach the operator as a judgment call they may legitimately answer "proceed anyway";
(3) the platform already types an abstraction-altitude premise challenge as a named sibling finding rather than a
PT (the adversarial reviewer's `Premise-Altitude-Finding`). Extending the PT enum to carry a warrant or placement
cause is the rejected alternative.

### § 11.1 PV — problem-evidence provenance (the pull-vs-push classifier)

Classify the card's problem statement into exactly one class. The classification is **total** — every card lands in
exactly one bucket, so a card citing no evidence is classified, never silently defaulted.

| Class | Trigger | Citation discipline (strict) |
|---|---|---|
| **PV-A** | **Observed-pain (pull).** The problem statement cites a **witnessed instance** in this platform or deployment where the absence actually bit. | MUST cite the instance concretely: a named run/milestone + date, a `file:line` of the defective artifact, a commit SHA / merged PR, or a named prior release outcome. A generic "this would help" is NOT observed pain. |
| **PV-B** | **Framework-driven (push).** The problem is derived from completing a **named external** delivery- or governance-framework's artifact, ceremony, or role set — not from a witnessed instance. | MUST name the external framework AND the specific artifact/ceremony/role whose absence motivates the card. |
| **PV-C** | **Article-imported (push).** The problem is imported from an external article, post, talk, or vendor document. | MUST cite the external source. |
| **PV-D** | **Unsourced (push).** The problem statement cites no evidence of any class. | MUST record "no problem-evidence citation found" plus the sections searched. |

**PV-B is scoped to EXTERNAL frameworks.** A card citing the platform's **own** governed corpus — an ADR, a
discipline, a standard, an initiative roadmap — is citing this platform's architecture, not an external push: it is
**PV-A** when it also names a witnessed instance, and **PV-D** when it names none. Without this bound the class
fires on essentially every governance card, and a gate that always fires is a gate the operator learns to override.

**The finding is bundle-level, not card-level.** Classify every card, then compute
`push = |PV-B| + |PV-C| + |PV-D|`. A bundle is **push-dominant** when `push ≥ ½` of its cards. **Push-dominance is
the finding**; a single push-classified card is **logged, not escalated** — framework-derived work can be entirely
legitimate. (This is the existing weak-signal escalation bound applied to a new signal: a single weak signal alone
is logged, not escalated.) The `≥ ½` threshold is `[RECOMMENDED]` / `[CALIBRATE-AFTER-3]`, grounded on the one
observed instance (5 of 7 cards push-classified in the originating milestone).

**Relationship to the upstream acceptance gate (cite, do not duplicate).** The Stage-2 Triage Acceptance-Fit
determination (§ A4.6 / gate G2-13) asks a related but distinct question — *does the idea relate to a named
architectural anchor?* — **per issue**, on a **scoped subset** (agent-authored or component-reshaping cards; it
passes trivially otherwise), with pre-cutover issues grandfathered. This lens asks about **problem provenance**
across **every** card and reports a **bundle-level** property. A card can anchor perfectly to a named epic and
still be framework-push. The two compose; neither re-runs the other.

### § 11.2 AL — abstraction-altitude band mismatch

Compare the band the card's stated remediation **implies** against the band the **nearest existing platform seam**
implies. The band vocabulary is **not defined here** — it is the `point-fix` / `extend-seam` / `new-abstraction`
ladder owned by the design-exploration standard's altitude axis, cited verbatim.

**Three steps, in order:**

1. **Name the nearest existing seam.** Search the platform's extension surfaces — the `operator.toml [adapters]`
   selectors, a module boundary, a config surface — exactly as the design-review seam-composition check mandates.
   Name the nearest seam found, or state that the search found none.
2. **Is there a band mismatch?** If the card's implied band equals the seam-implied band (or the cited seam-search
   concludes none fits), record `AL-FIT` with the seam searched — a positive verification, not a silent pass — and
   stop.
3. **Emit the mismatch with its direction.**

| Outcome | Trigger | Citation discipline (strict) |
|---|---|---|
| **AL-FIT** | Implied band matches the seam-implied band, or a cited seam-search concludes none fits. | MUST record the seam(s) searched. A bare "fine" is not a verification. |
| **AL-LOW** | **Authored below** — the remediation implies `point-fix` where an existing seam implies `extend-seam`. | MUST name the nearest seam AND why the remedy does not compose with it. |
| **AL-HIGH** | **Authored above** — the remediation implies `new-abstraction` where an existing seam implies `extend-seam`. | MUST name the seam the new abstraction would duplicate. |

A bare "this is at the wrong level" **without** the named seam and the direction is not a finding — it is the
unexamined-altitude assertion this lens exists to catch, and it is rejected on the same grounds the design-review
seam-composition check rejects an uncited "no seam exists".

**Scope exclusion — the methodology-archetype sub-case is NOT this lens's.** When the too-low subject is a named
delivery- or governance-methodology's archetype content — its vocabulary, ceremonies, artifacts, roles, or
hierarchy — such that the correct home is a config-selected methodology pack behind the `delivery_approach`
selector, the finding belongs to the **methodology-neutrality** check that already owns it, and this lens emits
nothing. Test it against the published archetype enum, **including its `Custom` row**, which absorbs
operator-invented and non-canonical variants; a framework absent from the enum therefore still routes to the
methodology check rather than falling here by default.

**Distinct from hierarchy altitude.** This lens's altitude is the **abstraction/seam** axis. The
work-organization hierarchy ladder (Portfolio → Program → Project → Milestone/Workstream → Work Item) is a
different axis with a different owner; do not conflate them.

### § 11.3 Routing

A § 11 finding is a **C3 typed by its lens class** (`PV-*` or `AL-*`), carrying **no PT**. It routes to an
**operator-judgment disposition** in the invoking consumer's disposition vocabulary — never to the § 9 Tier 0
escalation block, never to the § 10 phased-authority arc, and never to an autonomous return.

- The finding is **recommend-only**: the classifier names the evidence class or the band mismatch and stops. It
  does not re-triage, re-label, de-bundle, edit, or close the card.
- § 11 findings sit **off the staleness-confidence scale** — warrant and placement are not staleness depths. Do
  not assign them a staleness band.
- § 11 findings are **not** Phase-1 instrumented; the § 8 schema is scoped to the Tier-0 population.

### § 11.4 Boundaries

| Boundary | Relationship | Action |
|---|---|---|
| The **PT taxonomy** (§ 3) | Sibling, not parent. PTs type structural-premise causes; § 11 types warrant and placement. | Do not add a warrant or placement cause to the PT enum. |
| The **altitude band vocabulary** (design-exploration standard, altitude axis) | § 11.2 **consumes** the three bands. | Cite; author no second band vocabulary. |
| The **design-review seam-composition gate** | Same question, **later anchor** — it grades an authored design at design review; § 11.2 grades the card as written, upstream. | Compose; § 11.2 does not gate a design. |
| The **methodology-neutrality check** | Owns the methodology-archetype sub-case of altitude. | Cite and exclude per § 11.2. |
| The **Stage-2 acceptance-fit determination** | Upstream, per-issue, scoped, architectural-anchoring axis. | Cite; § 11.1 does not re-run it. |
| The **hierarchy/backlog altitude ladder** | A different altitude axis with its own owner. | Do not conflate. |

---

## Anchor patterns

This standard inherits or cites the following anchor patterns:

- **[`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist + warn-mode/enforce-mode discussion** — anchor for Phase 1 → Phase 2 graduation arc: operator-approved cutover, auto-trigger reversion, ≥3-day shakedown precedent (here: ≥20 invocations across ≥2 evaluation windows), warn-log review precedent (here: Phase 1 instrumentation review).
- **[`review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md) § 1 Anti-Laziness Rules + § 2 Root-Cause Requirement** — Rules 1, 3, 4, 9 inherited verbatim into the re-review schema's output discipline; root-cause format applied to PT classifications.
- **[`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) § 2.1 Mechanism 1 (Localization Check)** — related-not-extension. Mechanism 1 fires at the decision-class briefing point (pre-decision interrogation); the re-review fires at the design-stage entry handoff (pre-design interrogation of upstream output). Cousin patterns; D2 cites Mechanism 1 as a pattern to apply, not a parent doc to extend.
- **Inter-Stage Feedback Protocol Tier 1/2/3** ([`release/governance/release-process.md`](../../governance/release-process.md)) — pattern reused for Tier 0; numbering communicates earlier-temporal-position. Existing escalation rule "When in doubt between Tier N and Tier N+1, escalate" extends naturally to "When in doubt between Tier 0 and Tier 1, escalate to Tier 1" — but in practice, Tier 0 fires before Tier 1 has a chance, so the escalation goes the other direction (Tier 1 finding may be re-classified as Tier 0 if root cause traces to upstream premise).
- **[`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) G2-09 / G2-10 / G3-08 / G3-09** — primary similarity / size detection surface at Triage and Bundle (Stage 2 / Stage 3 execution-time). The re-review's Tier 0 PT-1 stale-assumption escalations may cite specific G2-09 / G3-08 candidate-pair output OR G2-10 / G3-09 size-routing output as the citation backing when premise problem at Stage 4/5 entry traces to a similarity / size routing miss at Triage / Bundle. Operator Action (A) Return-to-Triage re-enters the gate surface where the new criteria fire on re-evaluation. Cross-reference, not invocation — Tier 0 protocol itself unchanged. Cutover: applies to all releases entering Stage 4 going forward.
- **[`stage-04-planning.md`](../pipeline/stage-04-planning.md) Phase A0.8 / G-PL4 — Bundle-Entry Freshness Re-Verification** — the **batch, bundle-entry, earlier-firing sibling** of the per-spoke PT-1 (stale-assumption) / PT-2 (subsumption) freshness-checks in § 3.1. The two are complementary firings of the same freshness concern on different objects and at different times. **PT-1 / PT-2 fire per-spoke at Stage 4/5 entry, after the hub has fanned out**, and interrogate the requirement's *premise* by judgment (citing a commit SHA / merged-PR / closed ADR / RELEASE_LOG line + the § 3.1 freshness-check). **G-PL4 fires once, in batch, at Stage-4 Phase A0 entry before any per-card spoke launches**, and instead RE-RUNS each bundled card's own verifiable repro/AC command against a pinned live-`main` baseline to observe whether the headline *defect* still empirically reproduces — routing each card admit-still-valid / close-resolved / re-scope-changed. So: G-PL4 is batch + repro-execution + pre-fan-out; PT-1 / PT-2 are per-spoke + premise-judgment + post-fan-out. A general card carrying no machine-runnable check is a documented **pass-through** from G-PL4 to this per-spoke PT-1 / PT-2 check; drift/reconciliation-class cards are re-verified mandatorily at G-PL4 (no-skip). Cross-reference, not invocation.

---

**End of standard.**
