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

### Per-requirement table (7 columns)

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Confidence signal | Delta or Premise-Problem Type |
|---|---|---|---|---|---|---|
| AC1 / AC2 / proposed-change-N / risk-N | finding + citation | finding + citation | finding + citation | C1 / C2 / C3 | `CONVERGENT` / `DIVERGENT` / `UNGROUNDED` (per § 3.0) | (C2) proposed delta text; (C3) PT-1 / PT-2 / PT-3 / PT-4 |

**Confidence-signal column (§ 3.0 confidence gate).** The `Confidence signal` column records the consistency-signal state that the **C1/C2 proceed-gate** (§ 3.0) reads before a proceed-classification (C1 or C2) may be committed. It is the observable input to the gate, not the agent's verbalized self-confidence (a self-report is the rejected input per `decision-confidence-protocol.md` § 1.3). A proceed-classification whose signal is `DIVERGENT`/`UNGROUNDED` at a non-trivial reversibility tier must show the bounded pause-to-learn artifact (§ 3.0) before it resolves to C1/C2. A `CONVERGENT` signal — or any proceed at the CHEAP reversibility tier — fills this column and proceeds with no added ceremony. The column is **delta-skippable** under the § 6 delta-only Stage 5 procedure exactly as D1 is (record `delta-skip — gate re-evaluated only on changed signal`).

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

### § 3.0 Confidence gate on the C1/C2 proceed-classification

A C1 or C2 classification is a **proceed decision**: the spoke records the requirement as correct (C1) or correctable-and-correct (C2) and the stage moves forward on that premise. The danger this gate addresses is a **low-confidence proceed** — the spoke commits a C1/C2 on an upstream premise it is not actually grounded on, and a wrong premise then propagates into the release plan or design (undone only in days-to-weeks of downstream rework). This gate promotes the **passive** `Reversibility / Confidence` descriptor the § 9 escalation block already carries into an **active pre-commit check**: before a requirement may be recorded **C1 or C2**, the spoke evaluates decision-confidence per [`reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md) § From Label to Gate (the canonical mechanism is `decision-confidence-protocol.md`).

**The gate predicate (reversibility × confidence-signal, autonomy-modulated).** The spoke reads the **confidence signal** — the three-value consistency state `CONVERGENT` / `DIVERGENT` / `UNGROUNDED`, derived from observable cross-checks, never a verbalized self-report (the rejected input per `decision-confidence-protocol.md` § 1.3) — against the **reversibility of proceeding on this premise**. Proceeding on a stale-but-not-obviously-wrong premise at Stage 4/5 is typically **MODERATE–EXPENSIVE** (the cost-of-error is non-trivial — the wrong premise reaches the plan/design), and the spoke executes under **Autonomy Tier 2/3** (bounded-auto / autonomous within the framework). The disposition follows the `reversibility-protocol.md` § From Label to Gate matrix cell-for-cell:

| Confidence signal | Disposition at the C1/C2 commit point |
|---|---|
| **`CONVERGENT`** (cross-checks corroborate; weakest evidence label ≥ `[INFERRED]`) | **PROCEED** — record C1/C2 with no added ceremony. |
| **`DIVERGENT`** / **`UNGROUNDED`** at **CHEAP** reversibility | **PROCEED** — the cost of a wrong premise is trivial; pausing would be theater. |
| **`DIVERGENT`** / **`UNGROUNDED`** at **MODERATE / EXPENSIVE** reversibility | **PAUSE-TO-LEARN** — the proceed-classification is **gated**; run the bounded loop below before recording C1/C2. |
| **`DIVERGENT`** / **`UNGROUNDED`** at **EXPENSIVE-unresolved or IRREVERSIBLE** reversibility | **ESCALATE** — route to C3 / Tier 0 (§ 9), or to the operator per the Escalate pattern. |

**The bounded pause-to-learn loop (the gated path).** When the predicate returns **PAUSE-TO-LEARN**, the spoke runs the loop specified in [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Pause-to-Learn Pattern — it does **not** silently emit the proceed-classification:

1. **Name the specific gap** — the file, value, version, or dependency state the C1/C2 proceed rests on (CS-2 named gap; an un-nameable gap routes to ESCALATE, not pause).
2. **Inject a new external signal** — fetch the cited canonical source (a `[verify-before-recommend]` read), or, when the premise cites other-release state ("vX.Y has / has not shipped"), **run the § 3.1 freshness-check** as the external-signal injection. The freshness-check is this consumer's ready-made injector — its command + result line **is** the new signal the loop requires. A cycle that injects nothing new is a stall, not a learn-step.
3. **Re-evaluate** the confidence signal with the new input and exit the loop on one of:
   - **(a) resolved** → signal is now `CONVERGENT` → **record C1 / C2**;
   - **(b) real premise problem** → the gap is a genuine stale/subsumed/conflicting premise → **escalate to C3 / Tier 0** (§ 9 block + § 10 authority);
   - **(c) budget exhausted** (default 1 iteration, hard cap 2) without resolution → **escalate to the operator** via the [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Escalate Pattern (HALT + Decision Briefing; the named gap + what the loop tried becomes the Briefing Context).

**Anti-theater contract (load-bearing, not optional).** The gate fires **only where the pause changes the outcome**. A `CONVERGENT` signal, and any proceed at the **CHEAP** reversibility tier, pass the gate with **no** loop and **no** pause artifact — a pause on a certain or trivially-reversible call is the ceremony this contract exists to prevent. When the loop **does** fire, its three load-bearing properties are made observable in the re-review artifact so a downstream guard can confirm the pause was real: **new-signal-injected** (the freshness-check command + result, or the canonical-source fetch), **bounded** (the loop ran ≤ the budget; cycle count reportable), and **has-exit** (the resolution: C1/C2 | C3 | operator-escalate). A pause missing any one of the three is theater. `[per decision-confidence-protocol.md § 5 anti-theater guard]`

**Scope discipline (additive — the C3 / Tier 0 path is unchanged).** This gate governs **only** the C1/C2 proceed-classification — the proceed side of the fork. The C3 path, the Tier 0 — Premise Rejection workflow (§ 9), and the § 10 phased authority are **untouched**: a requirement the spoke already judges a fundamental premise problem still classifies C3 directly and routes to Tier 0 without passing through this gate. The gate's only new outcome is that a **low-confidence would-be-C1/C2** can no longer be emitted silently — it must first close its named gap (pause-to-learn), legitimately resolve to C1/C2, or escalate (to C3/Tier 0 or operator).

| Cls | Name | Definition | Routing |
|---|---|---|---|
| **C1** | **Survives verbatim** | Re-review confirms the requirement is correct and complete; no delta. | Stage proceeds. Artifact records C1 with citations supporting the confirmation (Rule 3 — no finding-free dimensions). |
| **C2** | **Needs refinement** | Re-review identifies a non-fundamental gap, ambiguity, or improvement opportunity. | Stage proceeds with refined requirement. Delta logged as Tier 1 [ADJUST] per Inter-Stage Feedback Protocol — commit the refinement to the issue body or release plan. |
| **C3** | **Should be challenged** | Re-review identifies a fundamental premise problem (stale assumption, subsumption, best-practices conflict, learnings contradiction). | Triggers Tier 0 — Premise Rejection workflow (§ 9 escalation block + § 10 phased authority). Stage HOLDS until operator (Phase 1) or Tier 0 routing (Phase 2) renders decision. |

### Premise-problem types (PT — taxonomy for C3 classifications)

Every C3 classification declares one PT. Citation discipline per PT is strict; soft language (`seems like`, `may have`, `possibly`) in any PT-1 / PT-2 citation auto-routes the rejection to Tier 0b in Phase 2 (see § 10).

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

## Anchor patterns

This standard inherits or cites the following anchor patterns:

- **[`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist + warn-mode/enforce-mode discussion** — anchor for Phase 1 → Phase 2 graduation arc: operator-approved cutover, auto-trigger reversion, ≥3-day shakedown precedent (here: ≥20 invocations across ≥2 evaluation windows), warn-log review precedent (here: Phase 1 instrumentation review).
- **[`review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md) § 1 Anti-Laziness Rules + § 2 Root-Cause Requirement** — Rules 1, 3, 4, 9 inherited verbatim into the re-review schema's output discipline; root-cause format applied to PT classifications.
- **[`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) § 2.1 Mechanism 1 (Localization Check)** — related-not-extension. Mechanism 1 fires at the decision-class briefing point (pre-decision interrogation); the re-review fires at the design-stage entry handoff (pre-design interrogation of upstream output). Cousin patterns; D2 cites Mechanism 1 as a pattern to apply, not a parent doc to extend.
- **Inter-Stage Feedback Protocol Tier 1/2/3** ([`release/governance/release-process.md`](../../governance/release-process.md)) — pattern reused for Tier 0; numbering communicates earlier-temporal-position. Existing escalation rule "When in doubt between Tier N and Tier N+1, escalate" extends naturally to "When in doubt between Tier 0 and Tier 1, escalate to Tier 1" — but in practice, Tier 0 fires before Tier 1 has a chance, so the escalation goes the other direction (Tier 1 finding may be re-classified as Tier 0 if root cause traces to upstream premise).
- **[`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) G2-09 / G2-10 / G3-08 / G3-09** — primary similarity / size detection surface at Triage and Bundle (Stage 2 / Stage 3 execution-time). The re-review's Tier 0 PT-1 stale-assumption escalations may cite specific G2-09 / G3-08 candidate-pair output OR G2-10 / G3-09 size-routing output as the citation backing when premise problem at Stage 4/5 entry traces to a similarity / size routing miss at Triage / Bundle. Operator Action (A) Return-to-Triage re-enters the gate surface where the new criteria fire on re-evaluation. Cross-reference, not invocation — Tier 0 protocol itself unchanged. Cutover: applies to all releases entering Stage 4 going forward.
- **[`reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md) § From Label to Gate + `decision-confidence-protocol.md` + [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Pause-to-Learn Pattern** — the decision-confidence gate this standard wires into the C1/C2 proceed-classification (§ 3.0). This re-review is the gate's first **live consumer**: § 3.0 reads the gate's `CONVERGENT`/`DIVERGENT`/`UNGROUNDED` signal × reversibility-of-proceeding to decide PROCEED / PAUSE-TO-LEARN / ESCALATE on the proceed side of the classification fork; the § 3.1 freshness-check supplies the loop's new-external-signal injection. The gate's mechanism (signal sources, threshold matrix, bounded loop, anti-theater guard) lives in those docs and is referenced, not restated here; this standard only routes the gate into its C1/C2 commit step. The C3 / Tier 0 path is not a consumer of the gate.

---

## Provenance

Design lineage for audit only — not load-bearing on the standard's content (§ 3.0 reads version-agnostically above; the gate it consumes is named by canonical doc filename, never by issue number, in the prose).

- #2289 — the Create ST2 sub-task that wired the decision-confidence gate into this consumer (the live-consumer integration; § 3.0).
- #2288 — the Create ST1 sub-task that promoted the confidence label into the gate (`reversibility-protocol.md` § From Label to Gate) and registered the Pause-to-Learn Pattern as the 3rd pre-action sibling (`autonomous-execution-model.md`). The gate primitive this standard consumes.
- #2286 — the Define ST1 sub-task that scoped the decision-confidence mechanism (signal, threshold matrix, bounded loop, six-domain application, named consumer).
- #2283 — the Define task (spec + ADR) under which the mechanism was authored; named the Stage-4 currency-check (this re-review) as the candidate live consumer.

---

**End of standard.**
