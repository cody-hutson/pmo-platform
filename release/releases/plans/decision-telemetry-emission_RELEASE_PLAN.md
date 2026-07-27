<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# {{RELEASE_VERSION}} Release Plan — decision-telemetry-emission

> **Milestone:** `decision-telemetry-emission` (#295) · **Release Class:** cross-cutting · **Version:** {{RELEASE_VERSION}} (slug-primary / pre-claim per ADR-092 — the concrete number binds at the Stage-12 atomic claim) · **Scope:** 6 issues (#3712, #3704, #4051, #3723, #4025, #4026) · One release branch, one PR, one merge gate.

This plan is the Stage-4 release plan (ratified at the Stage-4 D-Gate on the Stage-4 planning sub-task, 2026-07-26) reconciled with the Wave-1 Stage-5 Solutioning outputs and the hub's Wave-1 Decision Briefing. Two errata carried by the Stage-4 comment are corrected in place below (R7 Check-19 parity; D-1 candidate rule) — see **Deviation Log**.

## Summary (30 seconds)

Five delivery slices that build one chain — **fix the validator → make the hub write → emit the autonomous seams → key the rows to the shipped release → gate on emission** — plus one bundle-amended defect (#4051) in the same file the gate slice already edits. Both bug cards' own repros were re-run against pinned `main`; both still reproduce, with controls passing.

- **Release Class: `cross-cutting`** — triggers (a) and (c) both fire; (b) does not (1 of 7 governance surfaces, not ≥3). Posture: engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.
- **Dependency graph: 2 of 4 declared edges DIVERGE.** `#4025 → #3704` is **SOFT, not HARD** — #4025's actual runtime payloads validate today, unmodified. `#4026 → #3712` is **not a dependency at all** (thematic composition). One undeclared intra-wave ordering edge is added.
- **Wave structure: 3 waves, with the intra-Wave-1 order REVERSED from the milestone description** — build `#3712` **before** `#3704` (both edit the same `--self-test` block; #3712 establishes the dual-path harness #3704 then extends).
- **Top risk resolved at the D-Gate:** #4026 AC-3 is unsatisfiable as scoped (`core/deploy/deploy.sh` contains **zero** `deployment-status` emissions), so Cycle-Time has no `T_DEPLOY` anchor for any release. Resolved **D-3 fork (b)** — document N/A-by-design; file the emitter as follow-up.
- **Contention: the wave structure resolves the two named surfaces and defers the unnamed one.** `append-pipeline-event.sh` and `pipeline-event-log-schema.md` are resolved by sequencing + section-disjointness. `release/skills/release-hub/**` + `packages/release-hub.skill` is **deferred** — two sibling milestones also edit that surface.
- **Warn-mode-first claim: PARTIALLY IMPLEMENTABLE.** `warn` is; **`shadow` is not** — `resolve_check_mode()` accepts exactly `enforce|warn|off`. And the shadow→warn→enforce ladder is owned by `progressive-rollout-convention.md`, not `gate-efficacy-standard.md`.
- **Quota Budget: WARN** (5-spoke worst batch × 3 parallel stages, no telemetry medians — `spoke-launch/quota-reservation` rows = 0 log-wide).
- **Cross-Issue Acceptance Criteria: 5.**

**Live grounding for the whole release** `[SOURCE — operator-instance event log, 2026-07-26]`: 76 data rows / 76 write-log lines across **12 distinct version tags**. Only **4 of 12** event types are ever emitted — `decision` 38, `gate-outcome` 22, `test-run` 15, `escalation` 1. **Zero** rows for `self-repair`, `deployment-status`, `release-synthesis`, `spoke-launch`, `session-retro`, `iteration`, `scope-change`, `re-review`. The version-tag column carries a slug (`governance-ci-gates`) and a sentinel (`v0.0.0`) alongside real versions — the join-key instability #4026 describes, visible directly in the data.

> **Erratum (R7), corrected here.** The Stage-4 comment reported this row/line count as "Check-19 parity intact." The **counts are correct**, but the parenthetical attributed them to an assertion that never ran: `deploy.sh` Check 19 resolves the schema doc at a path that does not exist, so **19b (row-count parity) and 19c (header match) have never executed** — the parity above is an *observed* equality, not a *gate-asserted* one. That defect is #4051, bundle-amended into this release (operator decision D-4).

## Dependency Graph

Directional edges (`A → B` = "A blocks B"). Each classified HARD (code will not work without it) vs SOFT (can build in parallel, integrate later).

```
#3712 ──(SOFT/ordering)──▶ #3704          [undeclared — added by this plan]
#3712 ──(SOFT build / HARD process)──▶ #4025
#3704 ──(SOFT)──▶ #4025                   [DIVERGE from declared HARD]
#3723 ──(SOFT build / HARD AC)──▶ #4026
#3712 ─ ─ ─(none)─ ─ ─▶ #4026             [DIVERGE — not a dependency]
#4051 ─ ─ ─(none)─ ─ ─▶ #4026             [file-adjacent only: same deploy.sh]
this release ──(HARD, cross-release)──▶ the decision-audit-and-learning milestone
```

| # | Declared edge | Verdict | Evidence |
|---|---|---|---|
| E1 | #4025 depends on #3704 (multi-value payload) | **DIVERGE → SOFT** | #4025's *runtime* delegation payload `chose:spoke; why:merit-fork-stage7-parallel; quota:partial-60` → **exit 0, validates today**; its self-repair payload `trigger:suite-fail; cap:2/3; reversibility:CHEAP` → **exit 0**. Neither needs a pipe. #4025 becomes HARD-dependent on #3704 *only if* its payload convention is authored with a multi-value separator — a **design constraint**, not a build dependency (→ CIAC-4). |
| E2 | #4025 depends on #3712 (strict enum mirror) | **DIVERGE → SOFT build / HARD process** | #4025 adds `delegation` to schema §3; the tool parses §3 data-driven whenever the schema is readable (the normal case), so #4025 functions with or without the mirror fix. But ADR-086 §Consequences records the two-site obligation as held by authoring convention, not by a gate — landing #3712's bidirectional self-test **first** makes #4025's mirror edit gate-verified instead of convention-verified. Strong ordering rationale; not a build block. |
| E3 | #4026 composes #3723 (write-side) | **CONFIRM → SOFT build / HARD AC-satisfaction** | `--check-decision-emission` builds and runs against an empty log. But #4026 AC-3 (per-release row-count > 0 for 100% of in-window releases) is **unsatisfiable** without the write-side: the hub emits nothing today (no `release/skills/release-hub/**` file references `append-pipeline-event.sh`). #3723 must land before #4026's AC can be graded. |
| E4 | #4026 composes #3712 (CI self-test gap) | **DIVERGE → not a dependency** | No build coupling and no AC coupling. Both merely touch the "unenforced self-test" *theme*. Down-ranked to a coordination note; not sequenced on. |
| E5 | *(undeclared)* #3712 → #3704 intra-Wave-1 | **ADD → SOFT ordering** | Both edit the **same `--self-test` block** of `append-pipeline-event.sh`. #3712's AC-4 requires the self-test run under **both** enum paths; #3704's AC-4 requires positive multi-value + negative malformed cases *in* the self-test. Building #3712 first establishes the dual-path harness #3704 then extends. Reverse order forces a retrofit. **This reverses the milestone description's declared internal sequence.** |
| E6 | *(cross-release)* this release → the decision-audit-and-learning milestone | **CONFIRM → HARD** | That milestone states it is gated on this one, specifically #4025 + #4026, with its own two downstream slices HELD. This release is on its critical path. |

**Repro re-verification (Phase A0 G-PL4), executed against the pinned baseline:**

| Card | Repro result | Control | Verdict |
|---|---|---|---|
| #3704 | multi-value `triggers` payload with a bare pipe → `ERROR: Payload contains '|'`, exit 1 | single-value `triggers:[T1]` → exit 0 | **admit-still-valid** |
| #3712 | forced-fallback + `--event-type iteration` → `ERROR: Invalid event_type: 'iteration'`, exit 1 | schema-readable, same row → exit 0 | **admit-still-valid** |

**#3712 compounding factor, empirically confirmed.** `--self-test` prints `enum source=static-fallback (11 event types)` on the fallback path and `enum source=schema-§3-data-driven (12 event types)` on the schema path — **and returns PASS on both**. The self-test *displays* the divergence and never *asserts* on it. That is the toothless-guard shape, and it names the minimal fix.

## Implementation Sequence

**Topology: D-C SINGLE** — one release branch `release/decision-telemetry-emission` (slug-primary / pre-claim per ADR-092), one PR, one merge. **Concurrency posture: P0 fully-serial** — the contention map below is severe enough on the skill surface that a non-serial posture buys nothing. "Waves" are therefore *build-order* waves on one branch, not parallel-branch waves; the parallelism that matters is at the review-spoke level (Stages 5 / 7 / 8).

| Wave | Order | Issue | Why here |
|---|---|---|---|
| **1 — validator plumbing** | 1 | **#3712** | Establishes the dual-path (`schema` / forced-fallback) self-test harness + the bidirectional mirror assertion. Smallest slice; unblocks the gate that verifies every later two-site edit. |
| | 2 | **#3704** | Extends the same `--self-test` block with the payload cases. Carries the release's sharpest D-decision (widen the grammar vs amend the stage-shard §11 row). |
| | 3 | **#4051** | Wakes `deploy.sh` Check 19 (three-outcome trichotomy). Placed last in Wave 1 so the `deploy.sh` touch is contiguous with, but ordered before, #4026's Check 61 work. |
| **2 — write-side foundation** | 4 | **#3723** | Independent of Wave 1. Placed before #4025 so all `release/skills/release-hub/**` edits are contiguous and one package rebuild covers both. |
| **3 — emission + gate** | 5 | **#4025** | Needs the enum-lockstep gate (E2) and the skill surface #3723 opened. |
| | 6 | **#4026** | Needs #3723's write-side for AC-3 (E3); reads the join-key surface #4025 just extended. |
| **final commit** | 7 | *(no issue)* | **One `.skill` package rebuild** — `core/deploy/tools/build-skill-packages.sh release-hub` — as the last commit before PR open. Never a per-slice rebuild. |

**Wave boundaries are real, not cosmetic.** Wave 1→2 is a *file* boundary (validator tool/schema/deploy → skill corpus). Wave 2→3 is a *dependency* boundary (E2 + E3 both cross it). Within Wave 1 the boundary is the shared `--self-test` block (E5).

**Internal build order inside #4025:** self-repair emission **first** (zero dependencies, immediate value), delegation subtype **second** (waits on #3712's gate).

## Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Eng | 7 DT | 8 QA | 9 Review | 10 Dry Run | 11 Snapshot | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|---|
| #3712 | yes | yes | yes | yes | yes | — | — | yes | yes |
| #3704 | yes | yes | yes | yes | yes | — | — | yes | yes |
| #4051 | yes | yes | yes | yes | yes | — | — | yes | yes |
| #3723 | yes | yes | yes | yes | yes | — | — | yes | yes |
| #4025 | yes | yes | yes | yes | yes | — | — | yes | yes |
| #4026 | yes | yes | yes | yes | yes | — | — | yes | yes |

- **Stages 10 / 11: PLATFORM-SATISFIED** — no spoke, no sub-task. The Stage-9 PR diff IS the dry run; git history IS the snapshot (both stage shards carry `## Classification: PLATFORM-SATISFIED`).
- **Stage 5 applies to all.** `cross-cutting` sets activation bias **ALL**, and every slice carries a genuine design question — #3704 the grammar fork, #3712 the empty-`iteration`-line question ADR-086 deferred, #4051 the three-outcome trichotomy, #3723 the Procedure-7a non-vacuity semantics, #4025 the payload convention + carve-out narrowing, #4026 the back-stamp-vs-column fork. None is trivial under the skip test.
- **Stages 7/8 apply to all** — every slice has functional impact (validator behavior, gate behavior, or emitted-row behavior). No skip is defensible.

## Contention Map

**Verdict: the wave structure RESOLVES the two named surfaces and DEFERS a third, unnamed one.**

### Within-release contention

| Surface | Issues | Sections touched | Resolved by waves? |
|---|---|---|---|
| `release/tools/append-pipeline-event.sh` | #3704, #3712, #4025 | #3712 → `_FALLBACK_SUBTYPES_LINES` + `--self-test`; #3704 → pipe guard + `--self-test`; #4025 → **one appended mirror token** on the `decision` line | **RESOLVED.** #3712 and #3704 are adjacent in Wave 1 and serialize on one branch; the only genuine co-edit is the `--self-test` block, which E5's ordering makes additive (harness first, cases second). #4025's touch is a single token on a line neither Wave-1 slice restructures. |
| `release/references/standards/pipeline-event-log-schema.md` | #3704, #4025, #4026 | #3704 → §4.3 payload format; #4025 → §3 enum row + a new payload-convention block; #4026 → §2 field table / a new join-key section | **RESOLVED by section-disjointness + serial order.** Residual: #3704's grammar widening may also touch §3 payload examples adjacent to #4025's new block. Low, and caught by ordering (#3704 lands two slices before #4025). |
| `core/deploy/deploy.sh` | #4051, #4026 | #4051 → Check 19 path literals + the shared resolver + one test; #4026 → new Check 61 block + `--check-decision-emission` dispatch | **RESOLVED by build order + hunk-disjointness.** #4051's edit is confined to the Check-19 block and a new shared path resolver; #4026 appends a new check block. Different regions of the same file, serialized. |
| `release/skills/release-hub/` + `packages/release-hub.skill` | #3723, #4025 | #3723 → `references/orchestration-playbook.md`; #4025 → `SKILL.md` | **PARTIALLY** — in-release, Wave 2→3 ordering keeps them contiguous. But see cross-release below. |

### Cross-release contention — the deferred collision

The milestone declares no `## Parallelization Map`; this is what one would have surfaced:

| Sibling milestone | Shared surface | Edge class | Detail |
|---|---|---|---|
| **release-hub-mode-r-depth** | `release/skills/release-hub/SKILL.md`, `packages/release-hub.skill` | **Tier-S / soft serialization** | One open slice extends SKILL.md's Output Contract; that milestone's own map already records a soft edge with the response-convention milestone on this file. #4025 adds a third editor. |
| **release-hub-response-convention-enforcement** | `release/skills/release-hub/SKILL.md`, `references/decision-briefing.md`, `packages/release-hub.skill` | **Tier-S / soft serialization** | Two open slices (reversibility labeling; briefing render / interrupt anchoring) both edit SKILL.md. **Semantic adjacency, not just file adjacency:** that milestone is about *how* the hub renders decision-class turns; #3723/#4025 is about *whether* the hub emits a decision event. Same conceptual seam, two milestones. |
| **agent-finops-intelligence** | `core/deploy/deploy.sh` (probable), version slot | **soft / version** | Open Stage-4 planning sub-task, no open PR. Contributes the same next-free-version claim token. |
| **decision-audit-and-learning** | — | **downstream consumer, no contention** | Explicitly gated on #4025 + #4026. |

**`packages/release-hub.skill` is the sharpest edge and the reason this is HIGH, not MEDIUM.** It is a binary distribution artifact with a committed `.sha256` sidecar; git cannot 3-way-merge it. If a sibling merges between this release's package rebuild and its merge, the artifact conflicts and Check 7 (package-freshness, content-hash, `required`/always-enforce) plus its CI mirror `skill-package-freshness.yml` both go red. **Mitigation is merge-order + rebuild-last, not conflict resolution.**

### Cross-PR churn baseline (21-day window, pinned)

| File | commits/21d | last touched |
|---|---|---|
| `core/deploy/deploy.sh` | **20** | 2026-07-26 |
| `release/references/pipeline/stage-13-close.md` | 11 | 2026-07-24 |
| `release/skills/release-hub/SKILL.md` | 5 | 2026-07-12 |
| `core/standards/gate-efficacy-standard.md` | 5 | 2026-07-24 |
| `release/references/how-to/hub-spoke-bridge.md` | 4 | 2026-07-26 |
| `release/references/pipeline/stage-05-solutioning.md` | 4 | 2026-07-25 |
| `release/references/pipeline/stage-12-execute.md` | 3 | 2026-07-24 |
| `release/tools/append-pipeline-event.sh` | 2 | 2026-07-22 |
| `release/references/standards/pipeline-event-log-schema.md` | 2 | 2026-07-22 |
| `core/disciplines/decision-discipline.md` | 1 | 2026-07-10 |
| `core/disciplines/autonomous-execution-model.md` | **0** | 2026-06-29 |

`deploy.sh` and `hub-spoke-bridge.md` are the live-churn surfaces — **rebase `deploy.sh` immediately before PR open.** `append-pipeline-event.sh` and the schema are quiet.

## File Change Matrix

Machine-readable, one path per line, `intent | issue | note` — for downstream Stage 7/8/9 chip extraction per the hub-spoke-bridge baseline-pin-awareness clause.

```
EDIT   | #3712 | release/tools/append-pipeline-event.sh                              | add `iteration` line (empty subtype field) to _FALLBACK_SUBTYPES_LINES; make --self-test bidirectional (mirror vs schema-§3 member diff, both directions) + exercise it under both enum paths in one invocation
EDIT   | #3712 | release/ADRs/ADR-086-event-log-schema-decision-subtype-extension.md | reconcile §2 + Consequences to the VERIFIABLE-MECHANISM strength (not "gate-held"); strike the "known to diverge today" iteration clause; flip status Proposed → Accepted per operator decision D-6
EDIT   | #3704 | release/tools/append-pipeline-event.sh                              | widen the payload guard per D-1 fork A (admit the escaped multi-value separator); add positive multi-value + negative malformed cases to --self-test
EDIT   | #3704 | release/references/standards/pipeline-event-log-schema.md           | §4.3 — state whether multi-value payload fields are supported, their separator, escaping, and what stays reserved
ADD    | #3704 | release/ADRs/ADR-098-<payload-grammar-axis>.md                      | records D-1 (widen-grammar vs amend-the-stage-shard-row); ADR-098 is next-free (check-adr-numbers.py: 97 ADRs, contiguous 001..097 — re-verified at Engineering Commit 0)
EDIT   | #4051 | core/deploy/deploy.sh                                               | Check 19 three-outcome trichotomy + a shared pmo_evals_results_path() resolver replacing three path literals; the `# ─── Check 19:` def-block and `log "Check 19:"` emitter MUST survive the reshape or Check 57 warns
EDIT   | #4051 | core/deploy/tests/                                                  | one test asserting the trichotomy (instance log absent → SKIP; tracked schema unresolvable → fail-loud; both present → 19b/19c assert)
EDIT   | #3723 | release/skills/release-hub/references/orchestration-playbook.md     | Procedure 4/5 — explicit emit step binding operator-decision resolution to append-pipeline-event.sh, citing the hub-session-continuity mapping table; Procedure 0b — hub-state lazy-creation step; Procedure 7a — distinguish empty action-item set from fully-resolved set
EDIT   | #3723 | release/skills/release-hub/SKILL.md                                 | Output Contract / Mode O — surface the emit + hub-state-creation obligations (co-ordinate section with the two sibling milestones editing this file)
EDIT   | #3723 | release/references/how-to/hub-spoke-bridge.md                       | Procedure 7a — thin cross-reference to the non-vacuous gate semantics (the bridge does NOT duplicate normative content)
EDIT   | #4025 | release/references/standards/pipeline-event-log-schema.md           | §3 — add `delegation` to the `decision` subtype enum; add a `delegation` payload-convention block (keys chose / why / quota)
EDIT   | #4025 | release/tools/append-pipeline-event.sh                              | one appended token `delegation` on the `decision` line of _FALLBACK_SUBTYPES_LINES (two-site obligation, now gate-verified by #3712)
EDIT   | #4025 | core/disciplines/autonomous-execution-model.md                      | Retry / Escalate / Rollback patterns — add the emit-at-the-decision-point rule (payload: trigger, cap state, reversibility tier). File currently contains ZERO emission instructions
EDIT   | #4025 | core/disciplines/decision-discipline.md                             | §3 triage table — narrow the "Exempt: Deterministic routing" / "Exempt: Chip spawning" carve-out so a spawn-vs-hub-direct MERIT fork is emit-eligible; state the loose reviewable selection criterion
EDIT   | #4025 | release/references/how-to/hub-spoke-bridge.md                       | Procedure 2 / Procedure 3 — emit at the spawn-vs-inline merit fork (not per trivial chip)
EDIT   | #4025 | release/skills/release-hub/SKILL.md                                 | Mode O — bind the delegation emit to the routing fork
EDIT   | #4025 | release/tools/lib/                                                  | rollup-attribution delimiter co-change per operator decision D-5 (the milestone creating the hazard carries its mitigation)
EDIT   | #4026 | release/references/pipeline/stage-12-execute.md                     | Phase B3/B5 — back-stamp the claimed version onto the release's event rows at the atomic claim, per D-2
EDIT   | #4026 | release/references/pipeline/stage-13-close.md                       | Phase B — invoke --check-decision-emission; §11 unchanged (no new event type)
EDIT   | #4026 | core/deploy/deploy.sh                                               | new Check 61 block + `--check-decision-emission` standalone probe (mirrors the Check-48 verdict-compute pattern); MUST carry BOTH a `# Check 61` def-block AND a `log "Check 61:"` emitter or Check 57 warns
EDIT   | #4026 | core/standards/gate-efficacy-standard.md                            | add the gate-coverage register row (invariant / gate / surface / posture=advisory + enforcement-surface=deploy-time-only / falsification test) + a Flip-decision-status row
EDIT   | #4026 | release/references/standards/pipeline-event-log-schema.md           | join-key contract section (documented stable key: subject issue/milestone, or back-stamped version); §2 field table only if the new-column fork wins
EDIT   | #4026 | release/tools/query-pipeline-event.sh                               | join-key-aware filter (must tolerate mixed-arity history: legacy 10-col rows + any new 11-col rows)
EDIT   | #4026 | release/references/standards/deployment-cycle-time.md               | R2 remediation, fork (b) — document Cycle-Time as intentionally-N/A-until-deploy-events-are-emitted
EDIT   | none  | packages/release-hub.skill                                          | rebuilt artifact — ONE rebuild as the last commit before PR open (build-skill-packages.sh release-hub)
EDIT   | none  | packages/release-hub.skill.sha256                                   | content-manifest sidecar regenerated with the package (Check 7 baseline)
ADD    | none  | release/releases/plans/decision-telemetry-emission_RELEASE_PLAN.md  | Engineering Commit 0 (slug-primary / pre-claim per ADR-092; version binds at the Stage-12 claim)
```

**Explicitly OUT of scope:** `.github/workflows/release-tooling-smoke.yml`. The Stage-4 matrix originally assigned a hardcoded `append-pipeline-event.sh --self-test` step to #3712; that line is **dropped** as a Tier 1 [ADJUST]. The open CI-self-test-enforcement issue (#3702) owns that surface and requires the tool set be *discovered*, not hardcoded — a hardcoded step added here is a line that issue must then delete. #3712's in-process dual-path design satisfies its AC-4 in one invocation, so the future discovery job picks the tool up with **both** paths already covered.

**Explicitly UNCHANGED by #3712:** `release/references/standards/pipeline-event-log-schema.md`. #3712 adds nothing to §3; its `(12 values)` heading is correct today and stays.

**`domain_practice` label:** `{ source: N/A — pipeline-internal release, date: 2026-07-26, domain: governance }`. The matrix is entirely internal pmo-platform artifacts — sourcing-exempt. Dominant domain **governance**; secondary **software**. Sourcing-exempt does not make the release domain-less.

## Risk Register

| ID | Risk | Sev | Class | Mitigation | Owner |
|---|---|---|---|---|---|
| **R1** | **Cross-milestone serialization on the release-hub skill + its binary package.** Three open milestones edit `release/skills/release-hub/SKILL.md`; `packages/release-hub.skill` is a non-mergeable binary with a committed `.sha256`. A sibling merging inside this release's window turns Check 7 (`required`, always-enforce) and `skill-package-freshness.yml` red. | **HIGH** | contention | (1) Record a Tier-S serialization edge for both sibling milestones in a Parallelization Map (R8). (2) **Rebuild the package as the LAST commit** before PR open — never per-slice. (3) At Stage 12 Phase A.5, re-run the divergence check; if a sibling merged, rebase and **rebuild before merge**. (4) Operator renders merge-order across the three milestones. | operator + Stage 12 |
| **R2** | **#4026 AC-3 is unsatisfiable as scoped.** `deploy.sh` contains **zero** `deployment-status` emissions, so `compute-cycle-time.sh` never resolves a `T_DEPLOY` anchor — Cycle-Time is structurally N/A for **100%** of releases. #4026's declared scope adds no deploy-event emitter. | **HIGH** | scope | **RESOLVED at the D-Gate — D-3 fork (b):** take AC-3's documented-by-design branch, document N/A-until-emitted in `deployment-cycle-time.md`, and file the emitter as follow-up. The subsumed prior Cycle-Time issue stays closed; no reopen. | resolved |
| **R3** | **Reflexivity — the release edits its own orchestration surface, and the two halves behave differently.** | **MED-HIGH** | reflexivity | See the dedicated analysis below. | Stage 5 + hub |
| **R4** | **`deploy.sh` is the highest-churn file in the repo** (20 commits/21d) and the new Check 61 must satisfy **Check 57's extraction contract** — a `# Check 61` def-block AND a `log "Check 61:"` emitter, or Check 57 warns. Check 60 is the current max, so **61 is next-free**. #4051 reshapes Check 19 in the same file and must preserve its own def-block + emitter. | **MED** | contention | Author both surfaces in the same hunk, per check. Rebase `deploy.sh` immediately before PR open. Run `deploy.sh --check` locally and read `grep "  FAIL:"` (warn output on this instance routinely reports non-CI drift). | Stage 6 |
| **R5** | **The `shadow` rung is not implementable as scoped.** `resolve_check_mode()` accepts exactly `enforce\|warn\|off` — there is no `shadow` value. | **MED** | scope / claim | Ship **`warn` only**. Amend the milestone's "(shadow→warn→enforce)" parenthetical to "warn-mode-first per `progressive-rollout-convention.md`; enforce-flip deferred to the operator." Tier 1 [ADJUST]. Cite **both** that convention (owns the ladder) and `gate-efficacy-standard.md` (owns the flip ledger). | Stage 5 |
| **R6** | **Version-slot collision.** Two sibling milestones each carry an open Stage-4 planning sub-task; whichever release reaches the Stage-12 atomic claim first takes the next-free slot. | **MED** | dependency | The slug-primary branch carries no version stem, so the collision surfaces only at the claim. Three detection rungs cover it: Engineering **Commit-0 re-verify** (detect-and-HALT), the Stage-9 divergence re-check, and the Stage-12 **atomic ref-CAS** in `claim-version.sh`. No planning action beyond recording the contention. | Stage 6 / Stage 12 |
| **R7** | **A schema column-add silently breaks a positional reader.** `synthesize-release-learnings.sh` extracts the payload positionally at field `$10`. Inserting a `final_version` column anywhere before `payload` shifts it to `$11` and the synthesizer mis-parses with no error. | **MED** | rollback / correctness | **RESOLVED at the D-Gate — D-2: back-stamp in place** (rewrite the `version` cell, keep 10 columns, retain the provisional value in `payload` for forensics). If a column were ever added it MUST be appended as **column 11, after `payload`**, and every reader must tolerate mixed arity. | resolved |
| **R8** | **The milestone carries no `## Parallelization Map`.** The Phase A0 currency check requires it on milestones post-adoption. | **MED** | governance | Tier 1 [ADJUST] — amend the milestone description with a Parallelization Map recording the R1 Tier-S edges and the R6 version-slot token. The Contention Map above is the content. | hub |
| **R9** | **Check 19 is itself vacuous — the same defect class this release exists to fix.** `deploy.sh` resolves the schema doc at a path that does not exist, so Check 19a always takes the *schema doc missing* branch and **19b (row-count parity) and 19c (header preserved) never execute**. The append-only integrity assertion this release leans on has not run. | **MED** | defect (adjacent) | **RESOLVED at the D-Gate — D-4: filed as #4051 and bundle-amended into this release.** Same file #4026 already edits, same PR. Re-characterized at Wave-1 Stage 5 as three literals + a shared `pmo_evals_results_path()` resolver + one test; `size:S` holds. The literal was **born wrong**, not stale-from-a-reorg — the pre-reorg path was never tracked. | #4051 |
| **R10** | **The new emission gate could itself ship vacuous** — the exact failure #3723 documents at Procedure 7a. A minimum-set assertion that runs only where events already exist, or that treats "log absent" as pass, reproduces the defect one level up. | **MED** | gate-efficacy | #4026 AC-2 already names the falsification test — **hold it as a hard Stage-7 DT requirement, not a checkbox**: DT must empirically drive Check 61 red on a seeded zero-emission fixture and green on a seeded complete one. Add the gate-coverage register row. | Stage 7 DT |
| **R11** | **Rollback: emitted rows survive a code revert.** The event log is operator-instance and git-ignored (append-only, ≥3-year retention, no destruction policy). A `git revert` of the merge removes the `delegation` subtype from schema + mirror but leaves any already-emitted `delegation` rows in the log. | **LOW-MED** | rollback | Verified benign: `query-pipeline-event.sh` filters by grep and does **not** re-validate subtypes, so orphan rows are harmless on read. Redaction, if ever wanted, reuses `scope-change`/`redaction`. No code action. | — |
| **R12** | **Posture over-claim.** A `deploy.sh`-only Check 61 has no pre-merge CI surface; the gate-efficacy requirement obliges it to declare **`advisory`** with `enforcement-surface: deploy-time-only` until a CI mirror ships. | **LOW-MED** | gate-efficacy | Declare `advisory` / `deploy-time-only`. A CI mirror (the thin-caller workflow pattern) is explicitly **out of scope** for this release — noted as follow-up. | Stage 5 |

### R3 — Reflexivity analysis (mandatory entry)

**Does a mid-run change to the playbook take effect for the remaining stages of THIS release, or only the next one?** The answer differs for the two surfaces this release edits, and the asymmetry is the finding.

| Surface | How a running agent reads it | Mid-run edit takes effect? |
|---|---|---|
| `release/skills/release-hub/**` (#3723, #4025) | Via the **deployed mirror** under the runtime skills root, written by `deploy.sh --deploy release-hub` at **Stage 12** | **NO.** The mirror is frozen at its pre-release deploy timestamp for the whole run. The change lands for the **next** release. |
| `release/references/how-to/hub-spoke-bridge.md` (#3723, #4025) | **From the repo working tree**, by the spoke prompt itself. Not mirrored. | **YES — live.** Any spoke launched after the commit lands, into a worktree carrying the release branch, reads the edited text. |
| `release/tools/append-pipeline-event.sh` + the schema (#3704, #3712, #4025) | **From the repo working tree.** Not mirrored. | **YES — live.** |

**Failure mode if a spoke reads a half-updated playbook.** The realistic case: #4025's bridge emit-at-the-fork instruction lands, and a later Stage-7/8 spoke launched into a *stale-base* worktree runs the tool with `--event-subtype delegation` against a validator whose schema does not yet carry the subtype. Result: `ERROR: Invalid event_subtype 'delegation'`, exit 1 — a **loud, fail-closed** failure, because the tool and the schema travel together in the same tree. The dangerous *silent* variant is the inverse — schema updated, mirror not — which produces a wrong-but-green result only on the unreadable-schema path; **that is precisely the hole #3712 closes**, and it is the strongest argument for the E5/E2 ordering.

**Cutover posture — three clauses:**

1. **Self-exempt on the skill surface, and say so explicitly.** #3723 and #4025 carry the standard introducing-release-exempt clause. Here the exemption is not merely conventional — it is **mechanically enforced by the deploy boundary**, a stronger guarantee than the corpus usually gets. State the mechanism in the clause so a future reader does not mistake it for a soft convention.
2. **Do NOT self-exempt the tool/schema surface — it cannot be exempted.** The tool and the schema are read live from the tree by every spoke; a cutover clause on them would be unenforceable prose. Rely instead on fail-closed behavior plus the E5/E2 build order.
3. **Freeze the bridge's live half.** `hub-spoke-bridge.md` is the one surface both **edited by this release** and **read live by its own spokes**. Land its edits in a **single commit at the end of Wave 3**, after all Stage-5 spokes have completed, so no spoke in this run reads a half-updated bridge. If that is not achievable, pin every post-#4025 spoke's worktree base to a SHA at or after the bridge commit.

## Quota Budget

**Verdict: WARN** (per `quota-budget-protocol.md` Checkpoint A).
**Parallel-eligible spokes per parallel stage:** Stage 5: **5** · Stage 7: **5** · Stage 8: **5** (plus #4051 as the bundle-amended sixth card).
**Per-spoke cost estimate:** size-bucket ordinal band — 4 × `size:M` + 2 × `size:S`. Source: **the heuristic, not telemetry medians** — `spoke-launch` / `quota-reservation` rows in the event log = **0** log-wide, so no observed medians exist. Cost sits at the **upper end** of the M band: each spoke must read the schema + the tool + three stage shards + two disciplines + the hub playbook to be competent here.
**Assumed envelope:** not stated at hub start → conservative default (assume a *partial*, not fresh, window).
**Estimated cumulative draw % (worst parallel batch):** worst batch = **5 concurrent spokes**, three times over. Against a conservative partial envelope this lands in the **50–80%** band. Ordinal, `[CALIBRATE-AFTER-3]` MEDIUM confidence.
**Routing: WARN → window-aware launch timing + split batch.** Recommended split, dependency-ordered: **wave A = {#3712, #3704, #4051, #3723}**, **wave B = {#4025, #4026}**. The split is free — it matches the wave boundary the dependency graph already imposes.
**Escalation lever if Checkpoint B renders tighter:** REDUCE-scope by dropping Stage 5 for #3712. **Do not pre-emptively apply it** — #3712 carries the real `iteration`-line design question ADR-086 deferred.
**Note:** Checkpoint B re-validates at **every** parallel wave (runtime, load-bearing). This Checkpoint-A estimate is advisory and one-time. This is a **usage-window (cumulative-draw)** budget, not a rate-limit problem.

## Cross-Issue Acceptance Criteria

Graded at Stage 9 on the merged PR. Each predicate spans ≥2 issues and asserts something **no single issue's AC covers**.

- [ ] **CIAC-1 (#3712 × #3704 × #4025 — the two-site enum lockstep):** the tool's static fallback mirror admits **exactly** the event-type and subtype set that schema §3 admits — including `iteration` and the newly-added `decision`/`delegation` — and `--self-test` **asserts** the equality bidirectionally (a member in §3 but not the mirror fails; a member in the mirror but not §3 fails) rather than merely printing the counts.
  *Shared surface:* schema §3 ↔ `_FALLBACK_SUBTYPES_LINES`.
  *Method:* run `--self-test` under both enum paths and assert **both** exit 0 **and** both report the **same** event-type count. Today this returns `12` vs `11` with PASS on both; post-merge it must return an equal count on both paths. **This is the CIAC no single AC covers:** #3712's AC targets `iteration`; #4025 *adds* a member that must land in both sites, and only a bidirectional guard catches a mirror-only miss on the new member.

- [ ] **CIAC-2 (#3704 × #4025 × #4026 — stage-shard Audit-Trail Capture tables):** every emission codified in a stage shard's `## 11. Audit-Trail Capture` table validates end-to-end through `append-pipeline-event.sh` with the payload that shard specifies — no codified emission remains unwritable.
  *Shared surface:* the §11 tables of the Stage-5 / Stage-12 / Stage-13 shards ↔ the tool's type/subtype **and** payload validators.
  *Method:* for each §11 row, extract its specified payload exemplar and dry-run it; assert exit 0 for every row. Today the Stage-5 shard's `decision`/`cascade-sweep-block` row exits 1. This closes the schema↔stage-shard drift class on **both** axes at once, which neither #3704 (payload axis) nor #4025 (type axis) grades alone.

- [ ] **CIAC-3 (#3723 × #4026 — gate non-vacuity):** the minimum decision-event set that `--check-decision-emission` asserts is a **subset** of what the hub playbook instructs the hub to emit — no gate asserts an event class nothing is instructed to emit, and no instructed class the gate silently ignores.
  *Shared surface:* the playbook emit step ↔ the Check 61 minimum-set predicate ↔ the hub-session-continuity mapping table.
  *Method:* extract the event_type/subtype pairs named in the Check-61 predicate and in the playbook emit step; assert `set(gate) ⊆ set(playbook)` and report any playbook-only pair. **This is the anti-vacuity predicate the release exists to establish.**

- [ ] **CIAC-4 (#3704 × #4025 — payload-convention writability):** every payload-convention block **newly authored or amended** in the schema specifies a payload the shipped validator accepts — enum alternatives are rendered in the form D-1 adopts, never a bare reserved separator.
  *Shared surface:* the schema's payload-convention blocks ↔ the tool's payload guard.
  *Method:* extract every fenced example row and every `payload:` exemplar added by this release and dry-run each; assert exit 0. **Live trap, verified:** #4025's Proposed-Change payload as literally written is **rejected today** by the payload guard, while its runtime form passes. An author who copies the convention notation verbatim ships an unwritable emission; only a cross-issue check catches that.

- [ ] **CIAC-5 (#4025 × #4026 — join-key coherence):** the new autonomous-seam rows (`decision`/`delegation`, `self-repair/*`) carry a `subject` that resolves under #4026's documented stable join key, so they join 1:1 to the shipped release on the **same** key as operator-decision rows — the autonomous seams are not a second, differently-keyed stream.
  *Shared surface:* the `subject` + `version` columns ↔ the join-key contract section.
  *Method:* after a run, query for the delegation and self-repair rows, then assert every returned row resolves to the shipped release via the documented key. Grades the *integration* of #4025's new rows with #4026's keying — neither issue's AC asks whether the new row classes are keyed like the old ones.

## Operator Decisions (rendered at the Stage-4 D-Gate and the Wave-1 Decision Briefing)

- **D-ReleaseClass — `cross-cutting`.** Holds via triggers (a) + (c). Trigger **(b) does NOT fire** (1 of 7 governance surfaces, not ≥3) — the milestone description's rationale overstates this; correction tracked for Stage 13. Posture: Tight / Deep / ALL / 30-day.
- **D-Version — next-free minor.** *Recorded determination, not a gate.* Re-verification rungs: Engineering Commit-0 detect-and-HALT → the Stage-9 divergence re-check → the Stage-12 atomic ref-CAS. **Commit-0 re-verify executed and PASSED** — the planned slot was unclaimed on all three `claimed_set()` surfaces (git tags ∪ published Releases ∪ VERIFIED `RELEASE_LOG` rows) and equalled the recomputed next-free.
- **D-Concurrency — P0 fully-serial, D-C topology SINGLE.** The two release-hub sibling milestones are held until this release merges (neither has an open PR, so the hold is near-free).
- **D-1 — #3704 payload grammar: WIDEN (fork A).** Operator selected widening over amending the stage-shard row. **The adopted mechanism is the #3704 Stage-5 spec's rule: admit the escaped `\|` form as canonical, keep a bare `|` reserved, and reject the raw delimiter and newlines.** Record as ADR-098.

  > **Erratum, corrected here.** An earlier candidate rule — *"reject the spaced delimiter, admit a bare `|`"* — was **falsified** at the Wave-1 Decision Briefing: two consumers (`rollup-attribution.sh` and `append-pipeline-event.sh` itself) split on a **bare** pipe, so admitting one would corrupt them. The adopted rule above is *stricter* than that candidate and makes the stage shard's literal source writable verbatim with **no §11 amendment**. The operator decision (WIDEN, fork A) is unchanged; only the mechanism is corrected.

- **D-2 — join-key: BACK-STAMP IN PLACE.** 10 columns preserved; the provisional value retained in `payload` for forensics. The column fork silently breaks positional `$10` extraction across 8 consumers.
- **D-3 — Cycle-Time disposition: DOCUMENT-BY-DESIGN (fork b).** The subsumed prior issue stays closed; the N/A disposition is documented rather than re-litigated. The deploy-status emitter is filed as follow-up.
- **D-4 — Check 19a: FILE BUG + BUNDLE-AMEND.** Landed as #4051 in this release. Same defect class as #3723's vacuous Procedure-7a gate; the fix is in a file #4026 already edits.
- **D-5 — `rollup-attribution.sh` co-change: FIX IN THIS RELEASE.** The short migration to the shared delimiter lands here — the milestone creating the hazard carries its mitigation. ⚠️ A sibling milestone is actively editing this file — **conflict surface; coordinate at merge.**
- **D-6 — ADR-086: FLIP TO ACCEPTED.** The operator confirms ratification occurred at the v3.80 Stage 9 plan-review gate. The one-line frontmatter flip rides #3712's existing ADR hunk at zero marginal cost. (The Stage-5 spoke correctly refused to infer this from milestone closure — the ADR's own Status section forbids it.)
- **D-7 — Check 19 three-outcome trichotomy:** instance log absent → SKIP (no flag); tracked schema unresolvable → **fail-loud as a path-resolution failure**; both present → 19b/19c assert. **No class-level path fix** — the instance rate is 1 in 42 required literals; point fix now, standing assertion routed as follow-up. **Defer the standalone `--check-event-log-integrity` arm** — env injection already makes tests hermetic, and a second dispatch arm would convert a clean disjoint-hunk compose with #4026 into a real conflict surface.

**Merge / split recommendations — no merges, no splits.**

- **Do NOT merge #3704 + #3712** despite both editing `append-pipeline-event.sh`. They carry distinct ACs, distinct falsification tests, and reconcile **different ADR-086 sections** (the §5 scope-bound vs the §2 mirror guarantee). Within-release file contention is resolved by sequencing on one branch (E5), not by collapsing tickets — the milestone already ships as a single PR, so merging them buys nothing and loses two independently-gradable AC sets.
- **Do NOT split #4025**, even though its two halves have different dependency profiles — the delegation half needs a schema addition, the self-repair half needs **none** (`self-repair/{retry,escalate,rollback}` already validate). Splitting would put two PRs on the same two files and *increase* contention. Apply an internal build order instead (self-repair first, delegation second).
- **Scope note on #4025:** its self-repair half is materially smaller than the issue implies — the Stage-12 shard's §11 **already declares** the `self-repair/retry` and `self-repair/rollback` rows; what is missing is an **emission instruction**, not a schema change. `core/disciplines/autonomous-execution-model.md` contains **zero** references to the writer tool. That is the whole gap.

## Rollback Strategy

**Reversibility: CHEAP · Confidence HIGH.** The release is additive across every surface: three additive hunks in one shell file plus ADR prose (#3712); a widened payload guard plus self-test cases (#3704); a path-resolver extraction plus a branch reshape in one `deploy.sh` check (#4051); playbook and discipline prose (#3723, #4025); a new `deploy.sh` check block plus shard prose (#4026). `git revert -m 1` of the release merge restores prior state exactly — no schema migration, no row-shape change, no column change, no read-model change.

**One residual, verified benign (R11):** rows already emitted to the operator-instance event log survive a code revert. `query-pipeline-event.sh` filters by string equality and does **not** re-validate subtypes, so orphan rows are harmless on read. Redaction, if ever wanted, reuses the existing `scope-change`/`redaction` pair.

**The one non-CHEAP rollback path is the binary package.** If `packages/release-hub.skill` is rebuilt and a sibling milestone merges its own rebuild in the same window, the revert must also restore the sidecar hash — mitigate by rebuild-last + rebase-before-merge (R1), not by conflict resolution.

## Deviation Log (plan-file authoring)

Errata corrected in place while transcribing the Stage-4 comment into this file, per `reconcile-dont-annotate.md`. Both were recorded by the hub at the Wave-1 Decision Briefing; neither changes an operator decision.

| # | Stage-4 comment said | Corrected to | Why |
|---|---|---|---|
| 1 | "76 data rows / 76 write-log lines (**Check-19 parity intact**)" | Same counts, attribution struck — the equality is **observed**, not gate-asserted; Check 19 asserted nothing | Check 19a resolves the schema doc at a non-existent path, so 19b/19c have never executed. The counts are right; the parenthetical credited a gate that never ran. That defect is #4051. |
| 2 | D-1 candidate rule: *"reject the spaced delimiter, admit a bare `\|`"* | The adopted rule is the #3704 Stage-5 spec's: **admit escaped `\|` as canonical, keep bare `\|` reserved**, reject the raw delimiter and newlines | The candidate was derived by extrapolating from one consumer; enumerating all eight showed **two** split on a bare pipe. The adopted rule is stricter and needs no stage-shard amendment. |
| 3 | File Change Matrix assigned `.github/workflows/release-tooling-smoke.yml` to #3712 | **Dropped** (Tier 1 [ADJUST]) | The open CI-self-test-enforcement issue owns that surface and requires discovery-not-hardcoding. #3712's in-process dual-path design already covers both paths in one invocation. |
| 4 | Matrix note for the ADR-086 edit read "the lockstep is now **gate-held**, not convention-held" | "reconcile to the **verifiable-mechanism** strength" | Nothing invokes `--self-test` automatically (0 repo hits). "Gate-held" would re-commit the exact over-claim ADR-086 §2 was amended to correct. |
| 5 | R9 described the Check-19 literal as a "stale pre-reorg path" | "**born wrong**" | `git log --all` over the pre-reorg directory is empty — the path was never tracked, so it is an authoring error, not reorg drift. |

## Issue References

- #3712 — the fallback enum mirror is not strict (`iteration` absent); Wave 1 slice 1.
- #3704 — the payload guard rejects a codified multi-value emission; Wave 1 slice 2, carries ADR-098.
- #4051 — `deploy.sh` Check 19 resolves the event-log schema at a non-existent path, so 19b/19c never run; bundle-amended at the D-Gate (D-4).
- #3723 — the hub playbook carries no emit step, so no decision event is ever written; Wave 2.
- #4025 — the autonomous seams (delegation, self-repair) emit nothing; Wave 3 slice 1.
- #4026 — event rows are not keyed to the shipped release, and no gate asserts emission; Wave 3 slice 2.
- #3702 — the remaining residual after #3712: no CI workflow invokes the `release/tools` self-test suites; owns the CI surface deliberately left out of scope here.
- #295 — the release milestone `decision-telemetry-emission`, under which the five Cross-Issue Acceptance Criteria are graded at Stage 9.
