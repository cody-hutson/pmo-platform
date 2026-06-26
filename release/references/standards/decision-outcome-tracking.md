---
title: Decision Outcome Tracking
purpose: K1 codified-knowledge standard for the structurally elevated `**Outcome:**` field on RELEASE_LOG.md visible-H4 Deployment Log blocks and the JOIN protocol that correlates Stage 9 GO decisions with deployment outcomes
type: standard
parallel_to: pipeline-event-log-schema.md (the GO decision schema this composes with; provides `gate-outcome/plan-review-go` event_type), release-corpus-schema.md (the RELEASE_LOG.md structural standard this extends with one additive sibling field), gate-evaluation-spec.md (the Layer 3 calibration surface that JOINs against this for GO-quality assessment)
reversibility: CHEAP (forward-only schema; pre-cutover releases lack the field and consumers treat as NULL; field is removable in a future release without data loss — Outcome value can be inferred from `**Result:**` prose for SUCCESS cases)
consumers: "release/governance/release-process.md Stage 13 § Audit-trail capture (capture surface); release-planner Mode B (per-release health check + velocity); pmo-qa-auditor (GO-decision quality calibration); automated-closeout.sh (closeout report consumer); synthesize-release-learnings.sh (MAY compose Outcome into release-synthesis row payload); Future Platform Health Audit"
version: v12.12
---
<!-- reference-durability: allow-link -->

# Decision Outcome Tracking

## 1. Purpose

The PMO platform records Stage 9 GO decisions as `event_type=gate-outcome, event_subtype=plan-review-go` rows in `pipeline-event-log.md` and records Stage 12/13 deployment facts as visible-H4 `#### Deployment Log v<X.Y>` blocks in `RELEASE_LOG.md`. Until this standard, no structured field correlated a GO decision back to the deployment outcome it authorized. The question "What % of GO decisions led to clean deployments?" required manual inspection of free-form `**Result:**` prose per release.

This standard codifies a structurally elevated **`**Outcome:**` field** as an additive sibling line inside the visible-H4 Deployment Log block, populated at Stage 13 close with one of 4 enum values (SUCCESS / PARTIAL / ROLLBACK / DEFERRED). It establishes the schema, the placement, the capture protocol, the optional `**Outcome rationale:**` sub-field, and the 2-source JOIN query pattern that correlates the field against the `gate-outcome/plan-review-go` events keyed on `version`.

**Scope:** Terminal deployment-correctness judgment captured at Stage 13 close per release. The field is a release-level structured projection of the SUCCESS/PARTIAL judgment buried in the free-form `**Result:**` prose; `**Result:**` continues to carry the deployment narrative unchanged.

**Out of scope:** Per-issue outcome tracking (the field is release-level only — a mixed-outcome release records a single PARTIAL with rationale, not per-constituent rows); engineering-cycle quality (Stage 6 quality lives in Stage 7/8 review records, not Stage 13); gate-time caveats (the `PROCEED WITH CAVEATS` signal lives in the Stage 9 GO decision row per [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md), not the Stage 13 Outcome row). The PARTIAL value's recovery semantics defer to partial-deployment-recovery.md — this standard owns the field schema; partial-deployment-recovery.md owns the protocol when PARTIAL fires.

## 2. Outcome Field Schema (4-value enum)

**Placement:** Inside the visible-H4 `#### Deployment Log v<X.Y>` block per D-RELEASE_LOG-Field-Placement (B), as a sibling structured field to existing `**Mechanism:**` / `**Timestamp:**` / `**Result:**` lines. Position recommendation: immediately AFTER `**Result:**` (which is unstructured prose; `**Outcome:**` is the structured projection of the SUCCESS/PARTIAL judgment buried in `**Result:**` narrative).

**Schema:**

```markdown
**Outcome:** <ENUM>
**Outcome rationale:** <one-line free text, optional — omit when ENUM = SUCCESS unless additional context warrants>
```

**Enum semantics (4 values; closed; minimum-viable signal):**

| Value | Definition | Set by |
|---|---|---|
| **SUCCESS** | All in-scope deliverables shipped; QC4-01 through QC4-05 PASS; no post-deploy regression surfaced within the 30-day post-deploy review window. Default value when Stage 13 Checkpoint 4 closes clean. | Stage 13 spoke (autonomous when QC4 all-PASS) |
| **PARTIAL** | Stage 12 deployed but ≥1 file/skill/target failed S-2 copy, Phase H deploy, Phase J.5 rebuild, OR ≥1 QC4 invariant FAIL'd post-deploy. Detail + recovery routing defers to [`partial-deployment-recovery.md`](partial-deployment-recovery.md). | Operator (when partial-deploy condition fires) |
| **ROLLBACK** | Release was reversed via `git revert -m 1 <merge-SHA>` post-deploy OR equivalent reversal mechanism (tag deletion, manual file restoration). Reversal SHA cited in rationale line. | Operator (post-rollback ceremony) |
| **DEFERRED** | Stage 12 was attempted, HALTed before merge per Tier 2 [SCOPE CHANGE] (e.g., Phase A.5 main-divergence too wide, mergeStateStatus persistent UNKNOWN, dependent-PR blocker), and never re-attempted within the release's open window. Distinct from a release that has not yet started Stage 12 — DEFERRED is terminal. | Operator (after explicit defer decision) |

**Rationale for closed 4-value enum (per evidence-grounding survey at Stage 5):**

- `SUCCESS` matches the dominant observed `**Result:**` value (10 of 14 pre-cutover Deployment Log instances at survey commit `c0841ca` 2026-05-23).
- `PARTIAL` matches the existing line-23 legend (`Result: [SUCCESS / PARTIAL — detail per file if partial]`) but has zero observed instances in the pre-cutover corpus — the new field structurally elevates a documented-but-unused state.
- `ROLLBACK` is documented in `release-process.md` Stage 9/12/13 self-repair sections as the operator-authorized post-deploy reversal path; zero observed instances but a known capability ([`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Rollback Pattern).
- `DEFERRED` covers a prior release's Stage 12 first-attempt HALT (Tier 2 [SCOPE CHANGE]) — a release that HALTs without re-attempt warrants its own terminal value distinct from ROLLBACK (which implies a merge actually occurred and was reversed).

**What this enum does NOT cover (intentional omissions for lightweight discipline):**

- `FAILED` — overlaps with `ROLLBACK` (a deploy that "failed" gets rolled back; the rollback IS the terminal state) AND with `PARTIAL` (a partial-deploy "fails" some targets but ships others). Adding `FAILED` would force operator disambiguation at every non-SUCCESS outcome.
- `PENDING` / `IN_PROGRESS` — the main-table `Status` column already tracks Stage 12 vs Stage 13 lifecycle state (`DEPLOYED` → `VERIFIED`). The Outcome field is terminal — captured ONLY when Stage 13 closes. A release with no Outcome row is "Stage 13 not yet complete."
- `SUCCESS_WITH_CAVEATS` — Stage 9 already has a `PROCEED WITH CAVEATS` recommendation per [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md); that signal lives in the GO decision row, not the Outcome row. Stage 13 Outcome reflects deploy + 30-day-window correctness, not GO-time caveats.

Extension of the enum requires governance change per the same closed-enum precedent governing [`pipeline-event-log-schema.md § 3`](pipeline-event-log-schema.md) — `improvement.yml` Issue + Stage 4/5 cycle.

## 3. Placement

The `**Outcome:**` field lands as an ADDITIVE sibling inside the visible-H4 `#### Deployment Log v<X.Y>` block — NOT as:

- A rename of `**Result:**` (would break 14 pre-cutover Deployment Log blocks per § 2 Rationale above)
- A new main-table column (rejected per Stage 4 D-RELEASE_LOG-Field-Placement (B); main-table churn is high-cost)
- A new event_subtype in `pipeline-event-log.md` (rejected per D-AuditTrailReuse (A); closed-enum schema preserved — see § 6 below)

**Position within the block:** immediately AFTER `**Result:**`. Rationale: `**Result:**` carries the prose narrative; `**Outcome:**` is the structured projection. Reading order matches mental model — narrative first, then enum.

**Co-residence with the `**Cycle-Time:**` field:** Both new fields are structured sibling lines inside the same visible-H4 block. Field ordering convention: `**Files deployed:** … **Mechanism:** … **Timestamp:** … **Cycle-Time:** … **Result:** … **Outcome:** … **Outcome rationale:** …`. No structural contention — different field names, same block. Per [`deployment-cycle-time.md`](deployment-cycle-time.md) § 3.1 the cycle-time field anchors to the latest-emitted Stage 12 event; per this standard the Outcome field anchors to the Stage 13 close decision — temporally distinct, structurally co-resident.

## 4. Capture Protocol

**Default capture point:** the **Stage 13 chore PR** (`chore/v<X.Y>-stage-13-corpus-update`) per the chore-PR convention. The Stage 13 chore PR already transitions the RELEASE_LOG row `DEPLOYED` → `VERIFIED`; appending the `**Outcome:**` field to the visible-H4 block is a same-commit edit. Direct-to-main commit is prohibited per [`git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do".

**Stage 13 scope expansion (load-bearing per Stage 5 Finding 3):** the Stage 12 chore PR writes the visible-H4 Deployment Log block; the Stage 13 chore PR **edits** that block to ADD the Outcome field. This is a deliberate Stage 13-scope expansion. At Stage 12 close, QC4 has not yet run and the 30-day-window post-deploy review has not elapsed; SUCCESS cannot be authoritatively asserted. At Stage 13 close, both QC4 results and (optionally) the 30-day-window review feed the Outcome decision. R12 risk (Stage 13 expands beyond `DEPLOYED→VERIFIED` transition) explicitly accepted at Stage 5 Collective Review.

**Capture-decision automation:**

| Capture path | Trigger | Mechanism |
|---|---|---|
| **Autonomous (Stage 13 spoke)** | QC4-01 through QC4-05 all PASS at Stage 13 close | Stage 13 spoke appends `**Outcome:** SUCCESS` (rationale omitted unless extra context warrants) |
| **Operator-authored** | QC4 surfaces any FAIL OR Stage 12 HALT without re-attempt OR post-deploy rollback executed | Operator records the value + rationale; Stage 13 spoke embeds in the chore PR commit |
| **Retroactive amendment** | 30-day-window review surfaces post-deploy regression | Operator amends the prior release's `**Outcome:** SUCCESS` → `PARTIAL` or `ROLLBACK`; amendment lands as a Tier 1 [ADJUST] commit on the next release's branch OR a dedicated `chore/vX.Y-outcome-amendment` PR (still chore-PR pattern, never direct-to-main) |

**Stage 12-only fast-path (explicitly-permitted variant):** A release MAY land `**Outcome:** SUCCESS` at the Stage 12 chore PR when QC4 PASS is verified at that point AND operator opts-out of the 30-day-window review (e.g., low-risk doc-only releases). Rationale: the 30-day window is a backstop, not a hard gate. Per lightweight discipline, operator may collapse to Stage 12 capture when nothing warrants Stage 13 delay. Stage 13 capture remains the default; the fast-path is recorded as an explicitly-permitted variant.

## 5. Optional `**Outcome rationale:**` sub-field

**Schema:** one-line free text immediately following the `**Outcome:**` line.

**Conditional requirement (load-bearing per Stage 5 Finding 4):**

| Outcome value | Rationale field |
|---|---|
| `SUCCESS` | **OPTIONAL** — omit by default; include only when additional context warrants (e.g., narrow-shave QC4-05 PASS where rationale clarifies disposition; first non-self application of a new protocol) |
| `PARTIAL` | **REQUIRED** — cite affected files + routing (e.g., "Constituent 3 of 5 partially-failed Phase H deploy; see partial-deployment-recovery.md protocol assessment") |
| `ROLLBACK` | **REQUIRED** — cite reversal SHA + reason (e.g., "Reverted via PR #NNNN at SHA `<sha>`; post-deploy regression on file F per #NNNN") |
| `DEFERRED` | **REQUIRED** — cite HALT cause (e.g., "Tier 2 SCOPE CHANGE at Phase A.5 — main 26 commits ahead, operator deferred to next milestone") |

**Why optional for SUCCESS, required for non-SUCCESS:** Lightweight-discipline rationale — requiring rationale on every release adds friction to the 95%-of-releases-are-SUCCESS case. Non-SUCCESS values genuinely need rationale for audit-trail completeness — they are the rows readers will inspect.

**Future-state tightening:** the conditional-required posture is additive-compatible. A future release may promote to always-required without breaking existing rows (adding a required-when-empty field, not changing semantics).

## 6. JOIN to GO Decisions

**Question to answer:** "What % of GO decisions led to clean deployments?"

**Implementation:** 2-source query keyed on `version`. No new pipeline-event-log subtype; no new capture surface. Outcome field projects from `RELEASE_LOG.md`; GO decision projects from `pipeline-event-log.md`. Per D-AuditTrailReuse (A), the closed-enum schema in [`pipeline-event-log-schema.md § 3`](pipeline-event-log-schema.md) is preserved unchanged.

**Query primitive (read pattern):**

```bash
# 1. List all post-cutover releases and their GO timestamps
./release/tools/query-pipeline-event.sh \
  --event-type gate-outcome \
  --event-subtype plan-review-go

# 2. For each version returned, look up the Outcome value
for VERSION in $(./release/tools/query-pipeline-event.sh \
  --event-type gate-outcome --event-subtype plan-review-go \
  | awk -F' \\| ' 'NR>2 {print $3}'); do
  OUTCOME=$(awk -v ver="Deployment Log $VERSION" '
    $0 ~ ver { in_block=1 }
    in_block && /^\*\*Outcome:\*\*/ { sub(/^\*\*Outcome:\*\* */, ""); print; exit }
  ' <OPERATOR_INSTANCE_RELEASE_LOG_PATH>)
  echo "$VERSION  ->  ${OUTCOME:-MISSING}"
done

# 3. Aggregate: count SUCCESS / PARTIAL / ROLLBACK / DEFERRED / MISSING
```

**Justification for 2-source pattern over single-surface alternative (load-bearing per Stage 5 Finding 2):**

- D-AuditTrailReuse (A) mandates composition with existing capture.
- Adding `release-synthesis/decision-outcome` as a new event_subtype requires a schema change per [`pipeline-event-log-schema.md § 3`](pipeline-event-log-schema.md) — out of scope for this standard's lightweight scoping.
- `version` is a stable JOIN key (every release has a unique version tag; both surfaces capture it).
- The 2-source pattern is operationally identical to the JOIN pattern already documented in (Worked Example: Cross-Surface JOIN in pipeline-event-log-schema.md § 6).
- The RELEASE_LOG.md field IS the register per [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md); a parallel duplicate in pipeline-event-log would violate the register-or-remove rule.

**Future schema evolution (OUT OF SCOPE, routed to next-release planning):** If aggregation use cases grow beyond the manual-query frequency that automated-closeout.sh serves, a future release MAY add `release-synthesis/decision-outcome` subtype + emit the Outcome value into pipeline-event-log at Stage 13. That promotes the JOIN from a 2-source query to a single-surface query. Cost: schema governance change + pre-cutover release backfill consideration. Defer until measured need.

**Graceful degradation:** When the source surface for `gate-outcome/plan-review-go` events is empty (current state per Stage 5 Finding 6 — zero such rows in `pipeline-event-log.md` despite schema definition; pre-cutover instrumentation gap), the 2-source query degrades to a list of releases with their Outcome values only. This standard works whether or not GO capture is currently active — the JOIN composes when both surfaces populate; the Outcome surface alone is still informative.

## 7. Consumer Surfaces

| Consumer | Today | Future |
|---|---|---|
| **`release-planner` Mode B** (velocity / per-release health) | Reads Outcome to compute SUCCESS-rate over last N releases; informs Stage 4 risk-register for future releases (rolling SUCCESS rate < threshold → surface as risk) | Active downstream consumer post-N=3 non-N/A Outcomes; aligns with the N=3 baseline-trigger pattern per [`deployment-cycle-time.md § 5`](deployment-cycle-time.md) |
| **`pmo-qa-auditor`** (review surface) | GO-decision quality calibration — when SUCCESS-rate diverges from Stage 9 PROCEED rate, the gap signals miscalibration of QC3/QC4 rigor | Active downstream consumer; one signal among multiple in gate-quality assessment |
| **automated-closeout.sh** | Reads Outcome value as one of the close-out report's per-release facts (ships in this release) | Active downstream consumer in same release — Stage 13 wrapper script |
| **synthesize-release-learnings.sh** | MAY compose Outcome value into release-synthesis row payload alongside the `surprise` / `would-change` / `watch-for` triple | Active downstream consumer in same release — Stage 13 synthesizer |
| **Future Platform Health Audit** | Aggregation over Outcome history feeds platform-level health metrics | Active downstream consumer (future) |

**Aggregation rationale (parallel to cycle-time consumers per [`deployment-cycle-time.md § 8`](deployment-cycle-time.md)):** Outcome and cycle-time together form the Stage 13 deployment-quality projection. Outcome answers "did it work?" — cycle-time answers "how long did it take?" Joint consumption gives release-planner Mode B a 2-dimensional capacity signal and gives pmo-qa-auditor a 2-dimensional gate-calibration signal.

## 8. Forward Compatibility

| Compatibility concern | Resolution |
|---|---|
| Pre-cutover releases lack `**Outcome:**` field | Consumers treat as NULL / "pre-cutover". No backfill required. Schema is additive at structural level. |
| Future enum extension (e.g., add `EXPECTED_PARTIAL` for canary-style controlled partial deployments) | Requires governance change per [`pipeline-event-log-schema.md § 3`](pipeline-event-log-schema.md) closed-enum precedent. Enum is **closed**; extension requires `improvement.yml` Issue + Stage 4/5 cycle. |
| `**Outcome rationale:**` sub-field optional → required transition | Today: optional when SUCCESS, required when non-SUCCESS. Future-state may make rationale required always (audit-trail tightening); schema accommodates that promotion without breaking existing rows (adding a required-when-empty field, not changing semantics). |
| Schema migration to `release-synthesis/decision-outcome` event_subtype (single-surface JOIN) | Path forward documented in § 6 above. Cost: schema governance change + per-release Stage 13 emit step + (optional) pre-cutover backfill. Defer until measured need. |
| Aggregation across mixed-cutover corpus | release-planner Mode B + pmo-qa-auditor MUST filter to post-cutover releases when computing SUCCESS-rate. Pre-cutover releases contribute denominator but not numerator (artificially deflates SUCCESS-rate) — filter is correct. |
| Cross-platform Outcome surface (if PMO platform forks for multi-org use) | Each fork carries its own RELEASE_LOG.md → its own Outcome surface. Standards doc is fork-agnostic. |

**Pre-cutover release queried for Outcome:** Field is absent on pre-cutover Deployment Log blocks. Consumers treat missing field as NULL or "pre-cutover (outcome inferable from `**Result:**` prose only)". The 2-source JOIN query degrades gracefully: pre-cutover releases return `MISSING` in step 2 output.

## 9. Anti-Patterns

The following are **NOT** valid uses of the Outcome field:

- **Per-issue Outcome rows** — Outcome is release-level only. A 5-PR release where 1 constituent partially-failed and 4 shipped clean → `**Outcome:** PARTIAL` (release-level), rationale cites the affected constituent. Recording per-issue Outcome rows would duplicate information already in the per-PR merge state.
- **Conflating PARTIAL with the partial-recovery PROTOCOL** — this standard describes WHAT the PARTIAL value means (status); [`partial-deployment-recovery.md`](partial-deployment-recovery.md) describes WHAT HAPPENS when PARTIAL fires (decision tree, assessment, fix-forward / rollback). Single source of truth per [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md).
- **Treating Outcome as a Stage 9 GO-quality signal** — Outcome reflects Stage 13 post-deploy correctness, not Stage 9 GO-time assessment. The `PROCEED WITH CAVEATS` signal lives in the Stage 9 GO row per [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md). pmo-qa-auditor's gate-quality calibration JOINs the two signals — it does not collapse them into one field.
- **Adding new enum values without governance change** — closed-enum discipline per § 8 and [`pipeline-event-log-schema.md § 3`](pipeline-event-log-schema.md). Drift in any consumer that "extends" the enum locally produces silently-divergent corpus statistics.
- **Renaming `**Result:**` to `**Outcome:**`** — would break 14 pre-cutover Deployment Log blocks per § 2 Rationale. The fields are SIBLINGS, not synonyms; `**Result:**` carries the prose narrative, `**Outcome:**` carries the structured enum.
- **Capturing the field at Stage 12 close by default** — at Stage 12 close, QC4 has not yet run and the 30-day-window post-deploy review has not elapsed; SUCCESS cannot be authoritatively asserted. Default capture point is Stage 13 close per § 4. The Stage 12-only fast-path is an explicitly-permitted variant, not the default.

## 10. Cutover

**Applies to:** all releases going forward.

**First application:** the next release that closes Stage 13.

**Pre-cutover releases:** exempt. No backfill of historical Outcome values. The line-23 legend update (per Finding 7) does NOT retroactively assert `**Outcome:**` field on pre-cutover blocks — it documents the field schema for post-cutover releases.

**Instrumentation-gap interaction with § 6 JOIN:** The 2-source JOIN's `gate-outcome/plan-review-go` source surface is currently empty (zero such rows in `pipeline-event-log.md` per Stage 5 Finding 6 — Stage 9 GO capture wiring not yet exercised). Until the gap closes, the JOIN degrades to a list of releases with their Outcome values only. The Outcome capture per this standard works regardless; full correlation activates when both surfaces populate. The instrumentation gap itself is out of scope for this release (routed to a future `improvement.yml` per Stage 5 Finding 6).

## 11. Failure modes

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **PROC** | Autonomous Outcome capture without QC4 verification | When Stage 13 spoke encounters a QC4 FAIL (any of QC4-01 through QC4-05), do NOT write `**Outcome:** SUCCESS` autonomously — autonomous capture is conditional on all-PASS per § 4 | "QC4 surfaced a non-load-bearing FAIL, but the release is clearly successful" rationalization — Outcome is the structured projection of QC4 + 30-day-window, not an operator-feel signal | This standard § 4 makes autonomous capture conditional on "QC4-01 through QC4-05 all PASS"; ANY FAIL routes to operator-authored capture with rationale | Principal: surfaces the QC4 FAIL to operator + drafts the proposed Outcome+rationale + awaits decision; rationale cites affected check IDs + remediation routing. Junior: writes `**Outcome:** SUCCESS` "because the release shipped" → misclassifies a PARTIAL as SUCCESS, downstream SUCCESS-rate aggregation biased upward, gate-calibration signal corrupted |
| FM2 | **OUT** | Direct-to-main commit of Outcome field updates | When transitioning `**Outcome:** SUCCESS` → `PARTIAL` / `ROLLBACK` (retroactive amendment per § 4) OR appending the initial Outcome field, do NOT push directly to main — use the Stage 13 chore-PR pattern OR a dedicated `chore/vX.Y-outcome-amendment` PR | [`git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do" prohibits direct-to-main commit regardless of update size; cosmetic / metadata edits are not exempt | This standard § 4 explicitly cites the chore-PR mechanism for both initial capture and retroactive amendment; cross-references the chore-PR convention; field placement inside the visible-H4 block inherits the same chore-PR discipline as `**Result:**` and `**Timestamp:**` | Principal: opens a `chore/vX.Y-outcome-amendment` branch (or piggybacks on the next release's Stage 13 chore PR), edits RELEASE_LOG.md, opens chore PR per the chore-PR convention. Junior: pushes directly to main "because it's a documentation-only update" → Stage 12/13 chore-PR convention violation, no reviewable diff, audit trail incomplete |
| FM3 | **HAND** | Conflating Outcome enum with `**Result:**` prose semantics | When reading an Outcome value, do NOT interpret it through the `**Result:**` prose narrative — the fields are SIBLINGS not synonyms. `**Result:**` carries the deployment narrative; `**Outcome:**` carries the structured terminal-correctness judgment | Pre-cutover `**Result:** SUCCESS — <prose>` form trained reader habit to look for status in the Result line; the new field requires distinct attention | This standard § 2 (Schema) + § 3 (Placement) + § 9 (Anti-Patterns) repeat the fields-are-siblings discipline; the line-23 legend update per Stage 5 Finding 7 documents both fields' value spaces side-by-side | Principal: reads both fields per release — Result for the narrative context, Outcome for the structured value; aggregation queries hit Outcome only (deterministic enum). Junior: parses the `**Result:**` prose with regex to extract status → catches SUCCESS reliably but misclassifies PARTIAL narratives that lead with "Deployed successfully but…", DEFERRED narratives that omit status, etc. |
| FM4 | **TRIG** | Treating Outcome as a per-issue field on multi-PR releases | When a release ships multiple constituent PRs with mixed deployment outcomes, do NOT record per-constituent Outcome rows — the field is release-level only per § 9 (Anti-Patterns) | "We have N constituents; surely each gets its own Outcome value" — release-level granularity is by design; per-issue detail lives in the rationale line + the partial-recovery protocol | This standard § 1 (Scope) + § 9 (Anti-Patterns) repeat the release-level discipline; the rationale field accommodates constituent-citation for PARTIAL cases | Principal: records one release-level `**Outcome:** PARTIAL` + rationale citing affected constituents. Junior: appends 5 separate Outcome lines (one per PR) → schema corruption, downstream queries break, JOIN keyed on `version` ambiguous |

## 12. Cross-references

| Surface | Reference | Role |
|---|---|---|
| GO decision schema (JOIN source) | [`pipeline-event-log-schema.md § 3`](pipeline-event-log-schema.md) | Closed-enum schema definition for `gate-outcome/plan-review-go` event_type; this standard composes with, does not extend |
| Event capture surface (JOIN source) | [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) | Append-only event stream; data source for the GO half of the 2-source JOIN |
| Query primitive | [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) | Read helper; § 6 JOIN query composes over it |
| RELEASE_LOG.md structural standard | [`release-corpus-schema.md`](release-corpus-schema.md) | Visible-H4 Deployment Log block schema this extends with one additive sibling field |
| Gate calibration surface | [`gate-evaluation-spec.md § Layer 3 Calibration`](../../../core/schemas/gate-evaluation-spec.md) | pmo-qa-auditor's gate-quality calibration JOINs Stage 9 GO-time + Stage 13 Outcome; Outcome is one signal in the assessment |
| PARTIAL value semantics | [`partial-deployment-recovery.md`](partial-deployment-recovery.md) | This standard owns field schema; partial-deployment-recovery.md owns protocol when PARTIAL fires |
| Cycle-Time co-resident field | [`deployment-cycle-time.md`](deployment-cycle-time.md) | Both fields are structured sibling lines inside the same visible-H4 block; cycle-time anchors to Stage 12 close, Outcome anchors to Stage 13 close |
| Stage 13 capture protocol | [`release/governance/release-process.md`](../../governance/release-process.md) § Stage 13 § Audit-trail capture | Stage 13 spoke invokes this standard's capture protocol at the Stage 13 chore PR |
| Chore PR convention | [`release/governance/release-process.md`](../../governance/release-process.md) § Stage 13 § Chore PR convention | All RELEASE_LOG.md Outcome field edits land via chore PR, never direct-to-main |
| Rollback semantics | [`autonomous-execution-model.md § Rollback Pattern`](../../../core/disciplines/autonomous-execution-model.md) | `**Outcome:** ROLLBACK` value is set after operator-authorized rollback per this pattern |
| Single-source-of-truth discipline | [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md) | RELEASE_LOG.md `**Outcome:**` field IS the register; no parallel duplicate in pipeline-event-log |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at `core/standards/` |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags (TRIG / INPUT / PROC / OUT / HAND) |
| Cross-issue (cycle-time) | `deployment-cycle-time.md` (sibling release) | Co-resident sibling field inside the same visible-H4 block |
| Cross-issue (PARTIAL) | `partial-deployment-recovery.md` (sibling release) | This standard owns field schema; partial-deployment-recovery.md owns the value's recovery protocol |
| Cross-issue (closeout) | `automated-closeout.sh` (sibling release) | Reads `**Outcome:**` field for closeout report |
| Cross-issue (synthesizer) | `synthesize-release-learnings.sh` (sibling release) | MAY compose Outcome value into release-synthesis row payload |
| Source Stage 5 spec | Stage 5 Solutioning canonical spec | Stage 5 Solutioning canonical spec (relayed from mis-routed sibling ticket) |

## Version History

| Version | Date | Change |
|---|---|---|
| Initial | 2026-05-23 | Initial authoring — release-metrics-and-recovery release |
