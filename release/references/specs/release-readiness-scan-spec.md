---
title: Release Readiness Scan Spec
purpose: 14-dimension agent-driven pre-merge readiness scan executed at Stage 9 Phase A6; aggregates Stage 4-8 outputs into a fixed-dimension operator-presentable briefing before GO/NO-GO
type: spec
source: "Release Readiness Scan parent spec + Stage 5 spec"
parallel_to: gate-criteria-spec.md, handoff-coordinator-spec.md, review-discipline-principles.md, evidence-grounding-standard.md, pipeline-event-log-schema.md, engagement-charter.md
reversibility: CHEAP
consumers:
  - hub-spoke-bridge.md § Procedure 5 Gate Handling (Stage 9 Decision Briefing)
  - pipeline/stage-09-plan-review.md § 5 Phase A6 + § 11 Audit-Trail Capture
  - gate-criteria-spec.md § Gate 9 G-PR1
  - engagement-charter.md § 2 Stage 9 GO worked example
  - pmo-qa-auditor (downstream consumer; Stage 13 retrospective)
version: v11.27
---
<!-- reference-durability: allow-link -->

# Release Readiness Scan Spec

## 1. Purpose + Scope

The **Release Readiness Scan** is a 14-dimension agent-driven briefing executed at Stage 9 Phase A6 (between evidence assembly and Phase B Tiered Presentation). The scan aggregates state that already exists at Stage 9 entry — release plan, DT report, QA report, PR diff, Tier-A artifacts, audit-trail events, R1/R4 outputs — into a fixed-dimension table the operator reads before rendering GO/NO-GO.

**Aggregation, not parallel review.** Every dimension cites an evidence anchor against existing stage outputs. The scan does NOT introduce new gates, new approvals, or new checkpoints. It surfaces existing checkpoint outputs through a single 14-row lens so the operator sees coverage rather than inferring it.

**In scope.** Stage 9 Phase A6 execution; 13 operator-enumerated readiness dimensions (per parent spec body) plus one derived gate-state row (dimension 14, per § 5.1), 14 rows in total; per-dim evidence-anchor schema; 4-value status enum; output template (markdown table + audit-trail row); composition with existing gate/handoff/review-discipline infrastructure.

**Out of scope.** New skill authoring (per D-ScanInvocationMechanism the scan is hub-native, not a new skill or pmo-qa-auditor Mode). New gate criteria beyond the aggregate verdict cited in `gate-criteria-spec.md` G-PR1. Per-dimension rubric depth beyond the 5-field evidence-anchor schema (Stage 13 retrospective informs future depth via the audit-trail row).

## 2. The 14 Dimensions

| Dim # | Operator concern (verbatim from parent spec body) | Dim name |
|---|---|---|
| 1 | Does the agent have a clear understanding of the in-scope tickets | In-scope clarity |
| 2 | Are assumptions clear before starting / unclear questions answered | Assumptions resolved |
| 3 | What is this release supposed to provide / goal or output | Release outcome |
| 4 | Does the release contain the right granularity and scope to deliver on the goal | Granularity + scope |
| 5 | Does the release consider all dependencies (lateral, upstream, downstream) | Dependencies |
| 6 | Did the release create a high-quality, durable, repeatable, reliable solution | Solution quality |
| 7 | Did the release consider a solution at the individual work-item level AND the full cohesive package | Item + package coherence |
| 8 | Was the proposed solution properly outlined and documented | Documentation |
| 9 | Did the solution receive an adversarial review to ensure right solution + right design | Adversarial review |
| 10 | Was the solution properly tested / were all scenarios covered (provided and discovered) | Test coverage |
| 11 | Were all fixes applied and tested to the same level of verification on all passes | Fix-verification consistency |
| 12 | Was there proper separation of agents to prevent excessive agency and promote quality | Agent separation |
| 13 | Was there a comprehensive release package review to ensure nothing was missed | Comprehensive package review |
| 14 | Are the release PR required gates green, and is the PR in a mergeable state | Required-gate + mergeability |

The 13 are operator-enumerated. Industry release-readiness frameworks vary (Google SRE PRR axis-based, ITIL CAB / ITIL 4 release-management dimensions, Continuous Delivery 2025 maturity dimensions, DORA 4 keys, Independent Project Monitor readiness reviews, OneUptime / DX 7-dim production-readiness — surveyed during Stage 5 R1 evidence-grounding) — there is no single canonical industry count to defer to. The 13-stage pipeline is the platform's existing cognitive unit; preserving 13 aligns the scan to that frame. Per D-DimensionCount = CONFIRM-13.

Per D-DimensionCount-14, which supersedes D-DimensionCount = CONFIRM-13 without disturbing it: the ratified claim was the **operator enumeration** of 13 concerns, and that enumeration is preserved intact above. Row 14 is a **derived gate-state row** — not a 14th operator concern — added because five review layers and the scan itself passed a release whose required CI gate was failing. Dimensions 1–13 remain the operator-enumerated set; the table is 14 rows because it now also carries one derived row. Both statements are true at once, and every count in this spec means one or the other, never both.

## 3. Per-Dimension Evidence-Anchor Schema (5-field)

Each dimension is specified by 5 fields:

| Field | Description |
|---|---|
| **Name** | Short label per § 2 (`In-scope clarity`, `Assumptions resolved`, etc.) |
| **Definition** | One-sentence concern statement quoted/derived from parent spec body |
| **Evidence command** | Concrete command, file-read, or surface the hub queries at Phase A6 to populate the dim status. Structural dims cite executable commands (`gh issue list`, `grep`, `gh pr view`); judgment dims cite the artifact + section the hub reads + LLM-assesses |
| **Status enum** | One of `PASS` / `FAIL` / `PARTIAL` / `N/A` per § 4 |
| **Responsible stage** | Upstream stage(s) whose output feeds the evidence anchor — the scan does NOT re-execute the stage; it aggregates the stage's existing output |

The 5-field shape adopts the gate-criteria-spec.md per-criterion row precedent + the failure-mode-standard.md 5-field anti-pattern shape. Per D-PerDimMechanism = HYBRID (9 dims graded structural-auto via the Evidence command; 5 dims graded judgment-recommend via LLM assessment of the cited artifact).

## 4. Status Enum (4-value)

| Status | Definition |
|---|---|
| **PASS** | Evidence anchor returns expected result; dim is satisfied |
| **FAIL** | Evidence anchor returns deficient result; dim is NOT satisfied; aggregate verdict trends toward NO-GO |
| **PARTIAL** | Evidence anchor returns mixed result; some sub-concerns met, others gapped; aggregate verdict trends toward GO-WITH-CONDITIONS |
| **N/A** | Dimension is not applicable to this release (e.g., dim-9 adversarial-review N/A for hotfix class per release-class-taxonomy.md scan-depth modulation) |

The 4-value enum follows hub-spoke-bridge.md Procedure 7 verification-table precedent (PASS/FAIL/PENDING/N/A — PARTIAL substitutes for PENDING because the Stage 9 scan runs at single-point-in-time). pmo-qa-auditor SKILL.md forbids PARTIAL at per-gate altitude as cop-out; the scan operates at higher aggregation altitude where PARTIAL is meaningful (e.g., 4 of 5 AC verified, 1 partially verified). The prohibition co-exists; no conflict.

## 5. The 14 Dimensions x 5-Field Rows (canonical mapping)

| Dim # | Name | Definition | Evidence command / surface | Mechanism | Responsible stage(s) |
|---|---|---|---|---|---|
| 1 | In-scope clarity | Agent has clear understanding of in-scope tickets | `gh issue list --milestone "v<X.Y>" --search "label:bundled"` + cross-ref Stage 4 release plan § Implementation Sequence — assert per-issue mapping | structural-auto | Stage 4 |
| 2 | Assumptions resolved | Assumptions clear / unclear questions answered before starting | Read Stage 4 release plan § Operator Decisions + Stage 5 sub-task `## Decisions & Recommendations` — assert no `[ASSUMPTION - CONFIRM]` markers remain unaddressed | judgment-recommend | Stage 4 + Stage 5 |
| 3 | Release outcome | Release goal / output defined | Read `### Release Outcome Statement` H3 from milestone description (`gh api repos/{REPO}/milestones/<N> --jq .description`) per the Outcome Statement spec + G-PR7; assert AFTER/BEFORE present | structural-auto | Stage 3 |
| 4 | Granularity + scope | Right granularity + scope to deliver on goal | Read Stage 3 § A4 (bundle composition) + § A6 (new-track placement) + bundle-composition-doctrine.md — assert composition gate metrics PASS | judgment-recommend | Stage 3 |
| 5 | Dependencies | All deps (lateral / upstream / downstream) considered | Run `gh issue view <N> --json body --jq .body | grep -E 'FS[+0-9]?d'` per release-scoped issue + Stage 2 G2-04 + Stage 3 G3-07 + Stage 4 § Dependency Graph + native-dep mirror per Native Dependencies spec — assert all deps in compatible states | structural-auto | Stage 2 + Stage 3 + Stage 4 |
| 6 | Solution quality | High-quality / durable / repeatable / reliable solution | Read Stage 7 DT verdict + Tier-A artifact refresh-status + R1 Evidence-Grounding artifacts (per Evidence-Grounding standard) — LLM-assess across artifacts | judgment-recommend | Stage 5 + Stage 6 + Stage 7 |
| 7 | Item + package coherence | Both per-item AND full-package solution considered | Read Stage 5 per-issue Solutioning outputs + Stage 5 Collective Review N-way consistency table — assert per-issue PASS + cross-issue ALIGNED | judgment-recommend | Stage 5 |
| 8 | Documentation | Solution properly outlined + documented | Read Tier-A Design Artifacts (per Tier-A Design Artifacts standard) declared in release plan § Tier-A activated design artifacts + doc-impact lifecycle + release-notes (per release-notes-standard.md) — assert per-artifact `Last commit SHA within release branch` + diff >3 lines per G-CL6 | structural-auto | Stage 5 + Stage 6 + Stage 13 |
| 9 | Adversarial review | Adversarial review performed (right solution + right design) | Read Stage 5 adversarial-review phase + R3 Empirical Verification artifacts — LLM-assess for findings + remediation | judgment-recommend | Stage 5 |
| 10 | Test coverage | All scenarios covered (provided + discovered) | Read Stage 4 § Verification Plan AV-N declared assertions + Stage 7 DT pass-N final verdict + Stage 8 QA acceptance verdict — assert AC count matches AV count + Stage 8 PASS | structural-auto | Stage 4 + Stage 7 + Stage 8 |
| 11 | Fix-verification consistency | All fixes verified to same level on all passes | Read Stage 7 § DT iteration loop (per Stage 7 DT iteration loop spec) pass-N log — assert each pass re-executed the original AV-N assertion set | structural-auto | Stage 7 |
| 12 | Agent separation | Proper separation (prevents excessive agency; promotes quality) | Read hub-spoke-bridge.md § Spoke vs Hub assertions + per-stage persona declarations in release-personas.md + autonomy-tiers.md per-stage anchor — assert no hub-side spoke work + no spoke-side hub work | structural-auto | All stages |
| 13 | Comprehensive package review | Comprehensive review (nothing missed) | Stage 8 QA + Stage 9 Phase A1-A5 + Stage 13 G-CL6 + completion-verification check — escape detection absorbed here (items that traversed Stage 7-8 without being caught) | judgment-recommend | Stage 8 + Stage 9 + Stage 13 |
| 14 | Required-gate + mergeability | The release PR carries green required CI gates and is in a state that can merge when the time comes | `gh pr checks <PR> --required --json name,state,bucket,link` (ONE call, no poll; in this `--json` form it exits **0** even when a row is failing or pending — the exit code signals only an unresolvable PR or an auth failure — so branch on the parsed rows, never on the exit code) PLUS `gh pr view <PR> --json isDraft,mergeable,mergeStateStatus` PLUS the branch-protection required-context count as the denominator floor. Classify to exactly one state per the precedence table in section 5.1 and record the state name in Notes | structural-auto | Stage 6 + Stage 9 |

**Mechanism split summary (per D-PerDimMechanism = HYBRID):**

- **9 structural-auto:** dims 1, 3, 5, 8, 10, 11, 12, 14, and (implicitly 13 audit-trail check; LLM-graded on the package-quality narrative) — see annotation
- **5 judgment-recommend:** dims 2, 4, 6, 7, 9, 13 — LLM-graded

Note: dim 13's split posture acknowledges that completion-verification IS structurally checkable (a discrete file-state assertion list) while the "comprehensive review" assessment is itself judgment-graded. Treat dim 13 row's grading as judgment-recommend (5 judgment, 9 structural baseline).

### 5.1 Dimension 14 — state precedence, degraded states, and aggregate effect

Dimension 14 resolves to exactly ONE named state. States are evaluated in the order
below and the FIRST match wins. State 6 is the OTHERWISE arm, so the set is total by
construction: no combination of check buckets and merge-state values can fall through
it, and a host enum member this spec does not name — `HAS_HOOKS` is a current one —
degrades to an honest PARTIAL rather than a silent mis-classification. The order is
load-bearing: `checks-failing` is evaluated BEFORE `draft-blocked`, so a draft PR can
never mask a failing required check.

| Order | State | Derivation | Dim status | Operator action |
|---|---|---|---|---|
| 1 | `checks-failing` | at least one required row has a `bucket` of `fail` | FAIL — a NO-GO recommendation input | fix the named failing check |
| 2 | `checks-unreadable` | the read did not complete (command error, API error, rate limit, empty or unparseable output), OR the branch-protection required-context count could not be read, OR the observed required-row count is fewer than that count | PARTIAL — never PASS | re-run the read; if it still fails, record the reason and the missing context names |
| 3 | `checks-unresolved` | every required row was observed and, after the settle allowance below, at least one still carries a `bucket` other than `pass` — pending, cancel, skipping, or any value this spec does not name | PARTIAL — never PASS | re-read before rendering GO; name the unresolved contexts |
| 4 | `draft-blocked` | every required row is `pass` AND `isDraft` is true | PASS — record the state name in Notes | none; the PR is draft by design at this phase and the Stage 9 draft-to-ready transition clears it |
| 5 | `clean` | every required row is `pass`, `isDraft` is false, and the merge-state value is one the Stage 12 pre-merge mergeability step accepts | PASS | none |
| 6 | `merge-blocked-other` | OTHERWISE — record the observed merge-state value verbatim in Notes | PARTIAL | per the recorded value |

**Read `isDraft` for the draft predicate — it is the only field that carries draft-ness.**
The host merge-state enum has no draft member, and merge-state does not encode
draft-ness at all: it reports mergeability and check state, so one and the same draft
pull request reports different merge-state values at different moments as its checks
move. Never derive draft-ness from merge-state, and do not state any fixed relationship
between the two — measured at two different times, the same draft PR will contradict it.

**State 5 borrows its pass set; it does not author one.** The merge-state values state 5
accepts are exactly the values the Stage 12 pre-merge mergeability step treats as PASS
(`stage-12-execute.md` Phase A.6.2 — `MERGEABLE` together with a merge-state of `CLEAN`,
`UNSTABLE`, or `BLOCKED`). Stage 9 is deliberately not stricter than the gate that
actually merges: a value the merge step accepts must not become a Stage-9 condition, or
the briefing manufactures a finding the merge will not reproduce. If Phase A.6.2's pass
set changes, this row follows it — the set is stated in one place.

**Settle allowance before state 3.** A required context that has not yet reported is a
timing artifact, not a finding, and Phase A6 runs immediately after evidence assembly on
a freshly-pushed head — the moment most likely to observe one. Before classifying to
state 3, apply the same bounded backoff the Stage 12 mergeability step already uses for
a pending host computation (`stage-12-execute.md` Phase A.6.4 — 4 attempts at 3s, 5s,
10s, 12s, 30s wall-clock cap), re-reading between attempts. Classify to state 3 only
after the cap. This reuses an existing pattern rather than inventing one, and it keeps a
not-yet-reported check from downgrading an otherwise healthy release.

**Fail-closed posture.** An unreadable or incomplete measurement is never rendered as
clean. States 2 and 3 exist so that "the gates are green" and "we could not confirm the
gates" are distinguishable outputs; a zero-row read is a shortfall against the
required-context count, not a vacuously satisfied universal. Dimension 14 is `N/A` only
when the release has no PR at all — a failed read is state 2, never `N/A`.

**Draft state is expected, not deficient.** The release PR is created in draft at
Engineering and transitions to ready-for-review during Stage 9 evidence assembly, AFTER
this scan runs. Grading a draft PR as anything other than PASS would place every release
into the ANY-PARTIAL branch of the aggregate rule below by construction. The
merge-readiness of a draft PR is separately guarded at Stage 12, which carries its own
draft-state guard immediately before the merge, and PR mergeability is separately
asserted by the Gate 9 deployment-readiness criterion, which reads the `mergeable` field
and is draft-agnostic; this dimension names states for the briefing and does not
duplicate that gate.

**Reachability, stated rather than implied.** At Phase A6 the release PR is draft by
specification, so a healthy release resolves to state 4 and states 5 and 6 are reached
only on a Stage-9 re-entry after the draft-to-ready transition. They are specified
anyway because re-entry is a real path and because a state set that cannot classify an
observed value is the defect this dimension exists to prevent.

**Aggregate-verdict trace.** The consuming rule is the aggregation step in section 8:
ALL-PASS recommends GO, ANY-FAIL recommends NO-GO, ANY-PARTIAL with no FAIL recommends
GO-WITH-CONDITIONS. Dimension 14 therefore has three distinct aggregate effects and no
fourth: a red required gate (state 1) pushes the release into the NO-GO-recommendation
branch, which is the behaviour this dimension exists to produce; an unresolved or
unreadable gate state (states 2, 3, 6) pushes it into GO-WITH-CONDITIONS with the
unresolved contexts named as the condition; and a healthy release (states 4, 5) leaves
the aggregate exactly as it was before this dimension existed. The aggregation rule
itself is NOT modified.

**No new gate authority.** A dimension-14 FAIL is a NO-GO **recommendation** input
carrying the same authority as the other recommendation inputs at this stage — the
operator may override with recorded rationale. Branch protection on the default branch
remains the authoritative enforcement of every required check; this dimension adds no
hard-fail path.

**Cutover discipline:** Applies to all releases going forward.

## 6. Output Template

The hub emits the scan output as a markdown table on the Stage 9 Plan Review sub-task comment, AND emits one row to `pipeline-event-log.md` per D-ScanOutputPersistence = DUAL-SURFACE.

### 6.1 Sub-task comment template

```markdown
## Release Readiness Scan — v<X.Y> (Stage 9 Phase A6)

**Aggregate verdict:** <ALL-PASS recommends GO / ANY-FAIL recommends NO-GO / ANY-PARTIAL recommends GO-WITH-CONDITIONS>
**Scan timestamp:** <ISO-8601 UTC>
**Scan depth (per release-class-taxonomy.md):** <Deep / Standard / Light>

| Dim # | Name | Status | Evidence cite | Notes (if FAIL / PARTIAL) |
|---|---|---|---|---|
| 1 | In-scope clarity | PASS | `gh issue list --milestone "v<X.Y>"` returns N=<count>; matches release-plan § Implementation Sequence | — |
| 2 | Assumptions resolved | <STATUS> | Release-plan § Operator Decisions: N decisions resolved; Stage 5 D-decisions: M ratified | — |
| 3 | Release outcome | PASS | Milestone description `### Release Outcome Statement` H3 present + AFTER/BEFORE populated | — |
| ... | (repeat for dims 4-14) | | | |

**Aggregate verdict rationale:** <1-paragraph synthesis of the 14-dim table — names any FAIL/PARTIAL dims + their downstream implication for GO/NO-GO>
```

### 6.2 pipeline-event-log.md row

```
| <ts_iso> | v<X.Y> | 9 | gate-outcome | plan-review-readiness-scan | hub | release-level | CHEAP | resolved | aggregate_verdict:<ALL-PASS|ANY-FAIL|ANY-PARTIAL>; pass_count:<N>; fail_count:<N>; partial_count:<N>; na_count:<N>; sub_task_comment:<URL> |
```

The dual-surface emit composes with the audit-trail capture pattern — the comment is the human-readable artifact; the log row is the queryable breadcrumb.

## 7. Composition with Existing Infrastructure

| Existing surface | Composition |
|---|---|
| [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) | G-PR1 description references the scan as Phase A6 deliverable; aggregate verdict feeds operator's GO/NO-GO under G-PR-G/NO-GO rendering |
| [`handoff-coordinator-spec.md`](../../../core/schemas/handoff-coordinator-spec.md) | Stage 9 transition consumes the aggregate verdict as one input to the Tier 1 Contract Validation pass |
| [`review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md) | The 14-dim table satisfies the 6-deliverable output structure for the Stage 9 evidence package (findings = FAIL/PARTIAL rows, evidence = per-dim citation column, residual risk = aggregate verdict rationale paragraph) |
| [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) | Each dim's `Evidence command / surface` field IS the grounding artifact; R3 Empirical Verification is the dim-9 input |
| [`pipeline-event-log-schema.md`](../standards/pipeline-event-log-schema.md) | New `plan-review-readiness-scan` event subtype under `gate-outcome` event-type (additive closed-enum extension per § 4) |
| [`engagement-charter.md`](../../../core/specs/engagement-charter.md) | § 2 Stage 9 GO worked example references the scan as part of the "What" surface; § 4 5-class taxonomy classifies the scan output as a Briefing (≤ 200 words for aggregate; 14-row evidence table appendable) |

## 8. Stage 9 Phase A6 Invocation

5-step procedure (hub-native execution per D-ScanInvocationMechanism = HUB-NATIVE-NO-NEW-SKILL):

1. **Read inputs.** Hub reads release plan (file on release branch), Stage 7 DT report (sub-task comment), Stage 8 QA report (sub-task comment), PR diff (`gh pr view <PR>`), Tier-A design artifacts declared in release plan, audit-trail events from `pipeline-event-log.md`, R1/R4 outputs from Collective Review sub-task.
2. **Compute per-dim status.** For each of the 14 dims per § 5: execute the Evidence command (structural dims) OR LLM-assess the cited artifact (judgment dims); assign PASS / FAIL / PARTIAL / N/A per § 4.
3. **Synthesize aggregate verdict.** Apply rule: ALL-PASS → recommend GO; ANY-FAIL → recommend NO-GO; ANY-PARTIAL (no FAIL) → recommend GO-WITH-CONDITIONS.
4. **Emit sub-task comment.** Post output per § 6.1 template on the Stage 9 Plan Review sub-task.
5. **Emit pipeline-event-log row.** Append row per § 6.2 template via `release/tools/append-pipeline-event.sh` per `pipeline-event-log-schema.md` § 11.

The aggregate verdict surfaces in the Procedure 5 Decision Briefing (per hub-spoke-bridge.md § Procedure 5 Step 3) as ONE input to the operator GO/NO-GO. The operator may override the scan recommendation per the canonical Tier 3 (Human-only) discipline at Stage 9 — the scan is a briefing, not a binding gate.

## 9. Cutover

**Cutover discipline:** Applies to all releases going forward. The scan runs at Stage 9 Phase A6 for every release.

## 10. Version History

| Version | Date | Change |
|---|---|---|
| — | 2026-05-25 | Initial authoring at Stage 6. 13 operator-enumerated dimensions; 5-field evidence-anchor schema; 4-value status enum; DUAL-SURFACE output (sub-task comment + pipeline-event-log row); HUB-NATIVE invocation at Stage 9 Phase A6 (no new skill, no new pmo-qa-auditor Mode). |
| — | 2026-08-07 | Added dimension 14 `Required-gate + mergeability` as a **derived gate-state row** — the operator enumeration stays at 13 and is unchanged; the table is 14 rows. Added § 5.1: a 6-state precedence set (`checks-failing` before `draft-blocked`), two never-PASS degraded states with a branch-protection denominator floor, an OTHERWISE arm that makes the set total, a settle allowance borrowed from the Stage 12 pending-computation backoff, a `clean` pass set borrowed from the Stage 12 pre-merge mergeability step rather than authored here, and an explicit aggregate-verdict trace. Draft state grades PASS — it is the specified state at this phase. The aggregation rule in § 8 is unchanged and no new gate authority is created. |
