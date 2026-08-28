---
title: Release Plan — pipeline-spec-self-consistency
purpose: Stage-4 release plan for the pipeline spec self-consistency reconciliation bundle — seven cards reconciling stage specs with each other, with the tools that implement them, and with the event vocabularies they declare.
type: release-plan
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->

# Release Plan: pipeline-spec-self-consistency — Pipeline Spec Self-Consistency

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092); this file is authored **slug-primary / pre-claim** and carries the placeholder above rather than a digit. Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure: floor = `(anchor.major, anchor.minor + 1, 0)`, walked past the claimed set. Anchor tag max = **v4.38**; `RELEASE_LOG` max version row = **v4.38** (198 rows, zero in `DEPLOYED` state), so next-free is **v4.39** — matching the provisional recorded at Stage 4. See § Verification Plan → *Commit-0 version re-verify*. |
| **Date Created** | 2026-08-24 (Monday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | `release/pipeline-spec-self-consistency` |
| **PR** | not yet opened — SINGLE topology, one PR opened after the build completes |
| **Milestone** | `pipeline-spec-self-consistency` (#350) |
| **Release Class** | `cross-cutting` — `class_weight` **1.3**. Re-classified 2026-08-23 (Sunday) at the Stage-4 plan-review gate (operator decision **D-1**). Trigger (a) fires: the matrix touches **5** `pipeline/stage-*.md` files (`stage-04`, `stage-08`, `stage-09`, `stage-12`, `stage-13`) against a threshold of 3. |
| **Raw points** | **24** — #4732 M=4 · #4719 S=2 · #4923 S=2 · #4978 M=4 · #5069 S=2 · #5523 S=2 · #5816 L=8 |
| **`effective_pts`** | **31** — `round_half_up(24 × 1.3)`. **OVER the 15–25 ceiling.** The `>25` split disposition fired and was **operator-accepted with recorded rationale** — see § Operator Decisions Recorded (**D-5**) and the Milestone Amendment Log entry of 2026-08-24. Not re-adjudicated at Engineering. |
| **Branch topology** | **SINGLE** (D-C SINGLE) — one branch, one PR, one merge gate |
| **Concurrency posture** | **P0 fully-serial** at Stage 6. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `8dc00db1` — re-confirmed at Commit 0 (`git rev-parse origin/main` = `8dc00db134b500d16f7168e16bfe4cd604d41b8e`) |
| **Provenance** | Bundled 2026-08-14 (Friday) by `release-planner` Mode A/B; re-formed 2026-08-15 (Saturday) at `release-hub` Mode R readiness pre-flight; Stage-4 plan approved 2026-08-23 (Sunday); Stage 5 complete 7 of 7, scope-locked 2026-08-24 (Monday). |

## Scope

**Outcome.** Pipeline stage specs agree with each other, with the tools that implement them, and with the event vocabularies they declare.

**BEFORE.** Seven surfaces disagree on which stage owns the Surface-1 emit; a stage spec contradicts itself on when an Override Record attaches; a release-class threshold counts a row every release writes; a HARD-STOP gate rejects evidence that is not deficient; a provenance field is lost between two stages; two declared event subtypes carry no enforced payload vocabulary; and the event log cannot tell a record that is present from one that is current, complete, or mine.

**Out of scope.** Repair of the operator-instance pipeline event log itself (Layer-2, outside the repo tree — see **R-2**); the Lane-1/Lane-2 Step-4 verification-set divergence (#5288's class); `verify-release-plan.sh`'s `operations/` path-allowlist defect (#5757, OPEN — see § Verification Plan); and the `effective_pts` re-check mechanism (**#6117**, deliberately not added to this bundle).

### Domain Practice Provenance

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-24, domain: governance }`

Mode-A exempt path per `stage-04-planning.md` § 5.7: this release's entire File Change Matrix consists of internal pmo-platform artifacts (pipeline specs, governance docs, schemas, release tooling, intake templates, ADRs), so A1.5 *external sourcing* does not trigger. The `domain:` class points at `core/standards/domain-best-practices/governance`, which is the encoding of the platform's own internal-deliverable practice. The label is authored here rather than inherited — this release's own Stage-4 comment carried none, which is the exact defect #4978 fixes.

## Card Labels

| Card | Size | Type | Cluster | Project | Title |
|---|---|---|---|---|---|
| #4732 | `size:M` | `type:bug` | `cluster: pipeline-definitions` | `project:pipeline` | Surface-1 Release emit is spec'd at Stage 12 but produced at Stage 13 |
| #4719 | `size:S` | `type:bug` | `cluster: pipeline-definitions` | `project:pipeline`, `project:platform-quality` | `stage-08-qa-testing.md` contradicts itself on the non-AC-blocking PARTIAL Override Record |
| #4923 | `size:S` | `type:task` | `cluster: pipeline-definitions` | `project:pipeline`, `project:platform-quality` | G1-03's evidence predicate recognises one convention of two |
| #4978 | `size:M` | `type:bug` | `cluster: pipeline-definitions` | `project:pipeline`, `project:platform-quality` | `domain_practice` provenance emitted at Stage 4, dropped at Commit-0 transcription |
| #5069 | `size:S` | `type:task` | `cluster: process-protocol` | `project:pipeline`, `project:platform-quality` | Release-class trigger (b) counts the mandatory `RELEASE_LOG` row |
| #5523 | `size:S` | `type:task` | `cluster: templates-schemas` | `project:pipeline`, `project:platform-quality` | `qc4-05-result` / `qc4-06-result` declare no payload vocabulary |
| #5816 | `size:L` | *(unlabelled)* | *(unlabelled)* | *(unlabelled)* | The pipeline event log cannot tell present from current, complete, or mine |

**Two label facts recorded rather than silently normalised.** (1) #4719 was re-sized `size:XS` → `size:S` at the Stage-4 gate (**D-3**) and #5816 `size:M` → `size:L` at Stage-5 exit (**R-5**); both labels are current. (2) **#5816 carries only `size:L` and `status: bundled`** — it has no `type:`, `cluster:` or `project:` label. That is a live label-hygiene gap on a member of this release; it does not block the build and is routed rather than fixed here (see § Deviation Log).

## Dependency Graph

```
#5069   #4719   #4978        (independent)

#4923 ──INT-1, file-serialization──▶ #4732
        (core/deploy/deploy.sh)

#5523 ──CIAC-1, tool-lockstep serialization──▶ #5816
        (pipeline-event-log-schema.md + append-pipeline-event.sh)
```

**Native GitHub `blocked-by` edges among the seven members: 0.** The Stage-4 finding of *zero* dependency edges is **superseded** — Stage 5 created one.

- **INT-1 (#4923 → #4732), new at Stage 5.** #4923's design promoted `core/deploy/deploy.sh` from READ to EDIT because G1-03 is *implemented* there (6 references). #4732 reads the same file for its AC6 Check-48 assertion. The edge is file-serialization plus a read-after-write ordering constraint, not a semantic dependency: #4732's correctness does not depend on #4923's content, but its AC6 evidence must be gathered against the post-#4923 file.
- **#5523 → #5816** is a serialization edge. Both cards edit `pipeline-event-log-schema.md` and `append-pipeline-event.sh`, and the tool's `--self-test` asserts schema↔fallback lockstep **bidirectionally**, so a one-sided edit by either card fails the other's gate. #5523 lands first because its change is fully specified down to the literal label sets; #5816's validator is written against the post-#5523 registry.
- **#5523's single declared textual dependency (#4235) is satisfied** — #4235 reached terminal state and shipped on 2026-08-15 (`corpus-tolerance-and-hygiene`). Terminal, not carried.

**Cross-milestone edge (soft, directional, recorded — no relocation).** The #4732 ruling makes `deploy.sh` Check 48 the load-bearing Surface-1 backstop; **#4326 / #4328** govern Check 48's own integrity and remain homed in milestone `release-anchor-and-tag-integrity` (315). Neither blocks the other. **Stage-5 update:** Check 48's network cutover is **ARMED** at `v3.96`, not dormant — which makes the ruling's backstop premise *stronger*, not weaker. Re-check at Stage 9 Phase A6.5.

**Reflexive coupling (named, not an edge).** #4978 edits `stage-04-planning.md` and #5069 edits `release-class-taxonomy.md` — the two specs governing this very stage; #4732 edits `automated-closeout.sh`, the tool that runs this release's own Stage 13. A release cannot fire its own new rules on its own planning. #4978's § 6 Survival-Set clause and #5069's trigger-(b) block each carry an **introducing-release-exempt cutover**; #4732's change is proven on offline fixtures before Stage 12 (see **R-6**).

## Implementation Sequence

Single branch, serial commits. Sequence is driven by (1) contention serialization, (2) risk front-loading, (3) the one dependency edge.

| Commit | Card | Deliverable |
|---|---|---|
| **0** | — | Release branch cut off `origin/main` @ `8dc00db1`; **version re-verified** (next-free minor = `v4.39`, PROCEED); this plan authored token-bearing and asserted with `claim-version.sh --verify-stamp` |
| 1 | **#5069** | `release-class-taxonomy.md` trigger-(b) set membership + anti-pattern clause + ADR |
| 2 | **#4923** | G1-03 second evidence shape: `gate-criteria-spec.md` + `deploy.sh` predicate + `intake-style-guide.md` § 8 + 2 intake templates + ADR |
| 3 | **#4719** | Override-Record PARTIAL trigger reconciled across `stage-08` / `stage-09` / QA template / personas |
| 4 | **#5523** | § 11.8.1 subtype-vocabulary registry + widened label charset + `stage-13-close.md` 1-line + ADR |
| 5 | **#5816** | `decision-superseded` subtype, `check-event-record-integrity.sh` + 11 fixtures, allowlists, playbook, package rebuild + ADR |
| 6 | **#4978** | `provenance-survival` check family + Stage-4 § 6 Survival Set + bridge pointer + `v4.13` backfill + tests/fixtures + ADR |
| 7 | **#4732** | Surface-1 provenance: `automated-closeout.sh` phase 15.5/15.55 + `stage-12` / `stage-13` / `release-notes-standard` / `release-process` + ADR |

**Two orderings are load-bearing and must not be reversed.**

1. **#5523 before #5816** — the bidirectional lockstep assertion in `append-pipeline-event.sh --self-test`. Re-run the self-test after the **second** card lands, not only after each.
2. **#4923 before #4732** — INT-1. `deploy.sh` is edited by #4923 and read by #4732's AC6; gathering AC6 evidence against the pre-#4923 file would grade a state the release does not ship.

**Why #4732 sits at the tail.** It edits `automated-closeout.sh` phase 15.5 — the tool that closes *this* release. Every commit landing after it executes against a close-out path this release just changed. Last position minimises the window in which an undetected defect in the changed tool compounds with unrelated work.

**Sequence delta from Stage 4, recorded.** Stage 4 ordered `#5069 → #4923 → #4719 → #5523 → #5816 → #4978 → #4732`. That order is **retained unchanged** — INT-1 (discovered at Stage 5) already sits correctly within it, since #4923 is position 2 and #4732 position 7.

## File Change Matrix

Recomputed at Stage 6 as the authoritative path union of the **seven Stage-5 specifications**. The Stage-4 matrix (19 rows, all `edit`, zero `add`) is **SUPERSEDED and was not copied** — see the Milestone description's supersession table and § Deviation Log for the row-level reconciliation.

Path-first columnar form with an explicit intent verb per row. A marker-less path is `unknown`, never `edit`.

```
# ── #5069 — release-class trigger (b) set membership ──
release/references/specs/release-class-taxonomy.md                          edit

# ── #4923 — G1-03 second evidence shape ──
core/schemas/gate-criteria-spec.md                                          edit
core/deploy/deploy.sh                                                       edit
release/references/how-to/intake-style-guide.md                             edit
.github/ISSUE_TEMPLATE/improvement.yml                                      edit
.github/ISSUE_TEMPLATE/bug.yml                                              edit
# Added at Stage 6 by operator ruling. S-5 hoisted the G1-03 predicate to a
# top-level function, which moved it outside the C22-EVAL region this harness
# extracts; the repair belongs in build_runner. See § Deviation Log.
core/deploy/tests/test_g1_form_family.sh                                    edit

# ── #4719 — Override-Record PARTIAL trigger ──
release/references/pipeline/stage-08-qa-testing.md                          edit
release/references/pipeline/stage-09-plan-review.md                         edit
operations/templates/qa-acceptance-report-template.md                       edit
release/references/specs/release-personas.md                                edit

# ── #5523 — § 11.8.1 subtype-vocabulary registry ──
release/references/standards/pipeline-event-log-schema.md                   edit
release/tools/append-pipeline-event.sh                                      edit
release/references/pipeline/stage-13-close.md                               edit

# ── #5816 — event-record integrity + decision supersession ──
release/skills/release-hub/references/orchestration-playbook.md             edit
release/tools/query-pipeline-event.sh                                       edit
core/config/allowlists/script-execution-allowlist.txt                       edit
core/deploy/allowlists/selftest-coverage-manifest.txt                       edit
release/tools/check-event-record-integrity.sh                               add
release/tools/tests/fixtures/event-record/                                  add
packages/release-hub.skill                                                  edit
packages/release-hub.skill.sha256                                           edit

# ── #4978 — domain_practice provenance survival ──
release/references/pipeline/stage-04-planning.md                            edit
release/references/how-to/hub-spoke-bridge.md                               edit
release/tools/verify-release-plan.sh                                        edit
release/releases/plans/v4/v4.13_RELEASE_PLAN.md                             edit
release/tools/tests/test_verify_release_plan.sh                             edit
release/tools/tests/fixtures/                                               add

# ── #4732 — Surface-1 emit provenance ──
release/references/pipeline/stage-12-execute.md                             edit
release/references/standards/release-notes-standard.md                      edit
release/tools/automated-closeout.sh                                         edit
release/governance/release-process.md                                       edit

# ── Stage-7 rework (Pass 2) — operator-approved FCM addition ──
# The owning surface of #5816's issue-ref finding is the GATE, not the fixtures.
core/deploy/tools/check-issue-ref-validity.sh                               edit

# ── ADRs — number allocated at authoring time, never reserved ──
release/ADRs/ADR-*.md                                                       add     ADR:#5069
release/ADRs/ADR-*.md                                                       add     ADR:#4923
release/ADRs/ADR-*.md                                                       add     ADR:#5523
release/ADRs/ADR-*.md                                                       add     ADR:#5816
release/ADRs/ADR-*.md                                                       add     ADR:#4978
release/ADRs/ADR-*.md                                                       add     ADR:#4732

#### Read-only inputs
core/deploy/deploy.sh                                                       READ    #4732 AC6 (edited by #4923 — see INT-1)
release/references/how-to/hub-spoke-bridge.md                               READ    #4732 (verified conformant; edited by #4978)
release/skills/release-executor/SKILL.md                                    READ    #4732 (verified conformant — avoids a .skill rebuild)

#### Release-wide explicit non-scope
core/standards/hub-action-tracking.md                                       NOT EDITED
release/skills/release-hub/SKILL.md                                         NOT EDITED
release/skills/pmo-qa-auditor/SKILL.md                                      NOT EDITED
release/skills/pmo-qa-lead/SKILL.md                                         NOT EDITED
operations/skills/weekly-status-rollup/SKILL.md                             NOT EDITED
release/references/standards/_examples/dual-write-illustrative-v2.01.md     NOT EDITED
```

**Counts.** **26 distinct `edit` paths** (24 source + 2 package artifacts) · **3 `add` path groups** (one new tool, two fixture directories — `event-record/` 11 files, `prov-*` ~8 files) · **6 ADR `add` rows** · **3 READ-only** · **6 explicit non-scope**. One `.skill` package rebuild (**1 of 55**).

**ADR numbers are NOT pre-allocated.** Three Stage-5 spokes independently specified `ADR-142`, because `renumber-adr.py --next-free` is a **read, not a reservation** — an unwritten specification leaves no trace the oracle can see. Engineering allocates each number **at the moment it authors that ADR**, in implementation-sequence order, via `python3 release/tools/renumber-adr.py --next-free` (anchor + 1 across **both** ADR directories). **Never reserve, and never reserve high**: a duplicate is mechanically renumberable, a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole. The `ADR:#NNNN` marker in column 3 binds each row to its owning card so a delivered ADR is attributable without a pre-baked number.

**`packages/release-hub.skill` is a build artifact**, regenerated by `bash core/deploy/tools/build-skill-packages.sh release-hub` after #5816's `orchestration-playbook.md` edit lands — never hand-edited. Its `.sha256` sidecar is emitted by the same run.

**Two fixture directories are declared as directory rows**, not enumerated file-by-file, because their exact membership is set by the card's case ladder at build time (#5816: 11 files under `release/tools/tests/fixtures/event-record/`; #4978: ~8 `prov-*` files under `release/tools/tests/fixtures/`). Stage 9 grades the delivered set against each card's Stage-5 case list, not against a count frozen here.

**No file move, rename, or directory restructure** — the milestone's A9.6.1 declaration **holds** across all seven cards. This release is therefore not a serialization point for concurrent releases referencing these paths.

## Contention Map

| File | Claimants | Order | Resolution |
|---|---|---|---|
| `release/references/standards/pipeline-event-log-schema.md` | #5523, #5816 | 4 → 5 | **Different tables, same file.** #5523 adds `#### 11.8.1`; #5816 adds a decision-supersession subtype to the event-type registry. Append-pattern pair, low collision risk on one branch. Graded as **CIAC-1**. |
| `release/tools/append-pipeline-event.sh` | #5523, #5816 | 4 → 5 | **Genuine coupling.** `--self-test` asserts schema↔fallback lockstep bidirectionally; a one-sided edit by either card fails the other's gate. Re-run the self-test after the **second** card lands. Graded as **CIAC-1**. |
| `core/deploy/deploy.sh` | #4923 (edit), #4732 (read) | 2 → 7 | **INT-1.** #4923 changes the G1-03 predicate; #4732 reads Check 48 for AC6. Serial by sequence; #4732's AC6 evidence is gathered against the post-#4923 file. |
| `release/references/pipeline/stage-13-close.md` | #5523 (1 line at `:524`), #4732 (§ B5.6, flow-block, `:189`, `:360`) | 4 → 7 | **Disjoint regions, same file.** #5523's edit is a 1-line token back-ticking; #4732's edits are §-scoped. Serial by sequence; #4732 re-anchors by quoted text, not line number. |
| `release/references/how-to/hub-spoke-bridge.md` | #4978 (edit), #4732 (read) | 6 → 7 | #4732 requires **no edit** — L1264-1278 is already ruling-conformant. **Sequencing note:** if #4978's edit relocates or renumbers the Stage-12 Chip Pattern block, re-verify #4732's cross-reference before the PR opens. |
| `release/tools/tests/fixtures/` | #4978 (`prov-*`), #5816 (`event-record/`) | 5 → 6 | **Sibling namespaces under one parent, not a shared file.** #5816 writes a subdirectory; #4978 writes flat `prov-*` files. No collision. |
| `packages/release-hub.skill` (+ `.sha256`) | #5816 only | 5 | Single claimant. One rebuild, after the `orchestration-playbook.md` edit. |

**19 of 26 edit paths are single-claimant.** No pair beyond the six rows above shares a file.

**Cross-PR contention — baseline-pinned, and the population is transiently empty.** Open PRs = **0** and the one remote `release/*` head is fully contained in `main`, measured at `8dc00db1` / 2026-08-24T00:46Z. A default-to-zero over a transiently-empty in-flight population is **not load-bearing on its own** — a sibling branching tomorrow silently invalidates it. **Re-measure at Stage 9 Phase A6.6 before the GO** (**R-10**).

## Integration Points

| # | Seam | Cards | Contract | State |
|---|---|---|---|---|
| **INT-1** | `core/deploy/deploy.sh` — G1-03 predicate vs Check 48 assertion | #4923 → #4732 | #4923 changes the G1-03 evidence predicate (Layer-B(g)); #4732 asserts Check 48 is **unchanged in meaning** and adds no duplicating Surface-1 assertion. The two touch disjoint regions of one file; #4732's AC6 grades the post-#4923 state. | Created at Stage 5; supersedes Stage 4's zero-edge finding |
| **INT-2** | Schema ↔ static-mirror lockstep in `append-pipeline-event.sh` | #5523 ↔ #5816 | Both cards add to `pipeline-event-log-schema.md` and must mirror into `_FALLBACK_LABEL_SETS`. The `--self-test` lockstep assertion is bidirectional, so the contract is **symmetric**: neither card may leave the mirror one-sided. Token count moves 11 → 19 (#5523) → 23 (#5816). | Graded as **CIAC-1** |
| **INT-3** | `#### 11.8.1` registry as the shared vocabulary home | #5523 → #5816 | #5523 creates the registry section; #5816 registers `decision-superseded` **into it** rather than into the § 11.8 `--source` table (which § 11.8's own text prohibits). The awk parser's `^#{1,3} ` scan does not match `####`, so the registry is additive with zero parser-structure change. | One-directional; #5816 depends on #5523's section existing |
| **INT-4** | Surface-1 state token across the three emit paths | #4732 (internal) | `SURFACE1-STATE=<CREATED\|EDITED\|NO-OP>` extends a vocabulary already live at `hub-spoke-bridge.md:1273` and `release-executor/SKILL.md:475` to its **third** emit path (`automated-closeout.sh` phase 15.5). Both existing sites are **verified conformant and not edited**. | Extend-before-create; no cross-card seam |
| **INT-5** | `verify-release-plan.sh` reads this plan | #4978 → this file | #4978 adds a `provenance-survival` family that asserts a release plan carries a `domain_practice` label absolutely (not only by delta). **This plan carries one** (§ Domain Practice Provenance) and is therefore conformant under both the pre- and post-#4978 wording. | Reflexive; introducing-release-exempt cutover on the § 6 clause |

## Cross-Issue Acceptance Criteria

Four release-scoped cohesion constraints, each spanning ≥2 issues, graded at **Stage 9 QC3.5 / Phase A3.6** on the merged PR under the Stage-8 per-criterion verdict enum.

- [ ] **CIAC-1 (#5523 × #5816 — the lockstep invariant).** After **both** cards land, `bash release/tools/append-pipeline-event.sh --self-test` passes with the § 11.8.1 QC4 label-set registration **and** the `decision-superseded` registry entry both present, and the schema↔fallback lockstep assertion covers both additions. *Shared surface:* `pipeline-event-log-schema.md` § 11.8.1 + the L151 subtype registry, mirrored by `_FALLBACK_LABEL_SETS` in `append-pipeline-event.sh`. *Method:* self-test exit 0 on the merged PR, **plus the falsification arm** — edit one side only, assert non-zero exit and a named divergent token, then revert. **A lockstep guard that cannot be made to fail has not been extended.**

- [ ] **CIAC-2 (#4732 × #4719 × #4923 × #5069 — the one-normative-statement invariant).** For each rule this release canonicalises — the Surface-1 emit owner (#4732), the Override-Record PARTIAL trigger (#4719), the G1-03 admissible-evidence set (#4923), and the trigger-(b) countable-touch rule (#5069) — the merged corpus carries **exactly one** normative statement, and every other in-corpus mention **cites** it rather than restating it. *Method:* per rule, enumerate every occurrence of its obligation clause across the merged tree, classify each normative-or-citing, assert 1 normative + N−1 citing; **state the denominator and run both arms** (sensitivity: the enumeration returns non-zero on the known-bearing file; specificity: zero on a file with no such clause). *Stage-5 sharpened this:* #4732's own contribution is **IS-5** — turning `release-process.md` L612 from a restatement into a citation; without it CIAC-2 fails by construction, which is why the FCM gained that path. **The release's most load-bearing CIAC:** a fix that re-restates is the same defect in new clothes, and only a cross-issue check sees it.

- [ ] **CIAC-3 (#4923 × #5523 × #4719 — the both-arms invariant; no gate left unable to fail).** Every predicate this release widens, registers, or reconciles carries a **recorded negative-arm result** on the merged PR: the widened G1-03 still FAILs an evidence-free body; the registered QC4 vocabularies still REJECT an off-vocabulary label; the reconciled Override-Record trigger still identifies a case that requires a record. *Method:* for each of the three, a recorded FAIL/REJECT observation against a named fixture — #4211 plus a synthetic evidence-free body (#4923); a `mood:` label on a `qc4-06-result` row (#5523); a worked non-AC-blocking PARTIAL example paired with a firing case (#4719). **A recorded PASS without its paired FAIL is NOT MET.**

- [ ] **CIAC-4 (#4978 × #5816 — producer↔consumer join checks).** Both cards' core remedy is a **two-surface comparison**, and both must land as a **population sweep with a specificity arm** — not as a per-write assertion alone. *Shared surface:* the producer↔consumer join pattern — Stage-4 comment ↔ committed plan file (#4978), and action-item ledger ↔ event log (#5816). *Method:* read both delivered checks on the merged PR; assert each (i) enumerates a whole population rather than one write, (ii) reports a denominator, and (iii) carries a specificity arm on a non-existent identifier. *Stage-5 strengthened both:* #4978's delta-only limb is **vacuous** on the `v4.37` shape (both surfaces empty), which forced an absolute-presence limb; #5816's AC3 passes 13/13 today while **12 of 13 rows are stale**, which forced an ID join *plus terminal-state agreement*. **A check that cannot fail on the case that motivated it is not a check.**

## Verification Plan

| Family | Check | Applies to | Method |
|---|---|---|---|
| **Commit-0 version re-verify** | Planned version is not claimed, and equals recomputed next-free | release | `git fetch --tags origin` + `git fetch origin main`; ledger read via `git show origin/main:release/releases/RELEASE_LOG.md` (never the worktree copy); `claim-version.sh --sha <baseline> --bump minor --dry-run`. **Result: `v4.39`, PROCEED.** |
| **Commit-0 stamp manifest** | The pre-claim plan resolves at the Stage-12 claim | this file | `release/tools/claim-version.sh --verify-stamp pipeline-spec-self-consistency` → **exit 0**. Read-only, network-free; runs the identical pre-flight the Stage-12 claim runs, so a PROCEED here rehearses the real claim rather than a lookalike. |
| Per-issue | Each card's own acceptance criteria | all seven | Graded at Stage 8 per card; per-card predicates are enumerated on each Stage-5 sub-task |
| Integration | The four cross-issue criteria above | cross-cutting | CIAC-1 / 2 / 3 / 4, graded at Stage 9 QC3.5 |
| Tool self-test | `bash release/tools/append-pipeline-event.sh --self-test` | #5523, #5816 | exit 0 **after the second card lands**; `lockstep OK (23 tokens, both directions)` |
| Tool self-test | `bash release/tools/automated-closeout.sh --self-test` | #4732 | Arms (e) CREATED / (f) NO-OP / (g) EDITED / (h) specificity / (i) aggregation non-regression all green; **arm (h) must be demonstrated capable of failing** |
| Tool self-test | `bash release/tools/check-event-record-integrity.sh --self-test` | #5816 | exit 0; per-check assertion count printed; V7 (orphan entry) exits 1 naming the orphan SHA |
| Tool self-test | `bash release/tools/tests/test_verify_release_plan.sh` | #4978 | Cases P1–P12; **P5a is load-bearing** — on the `v4.37` shape the delta limb PASSes and the run must still FAIL on `PROV-PRESENCE` |
| Gate regression | `./deploy.sh --check` | all | Check 48 result and meaning unchanged (#4732 AC6); Check 22 emits no new G1-03 finding over this milestone (#4923); Check 7 clean after the `release-hub` package rebuild (#5816) |
| Syntax | `bash -n core/deploy/deploy.sh`; `bash -n` on every edited `release/tools/*.sh` | #4923, #4732, #5523, #5816, #4978 | clean; no unbound-variable regression under `set -u` |
| Coverage | `python3 core/deploy/tools/check-selftest-coverage.py --reconcile` | #5816 | exit 0 — manifest and discovery agree (CI Arm B(ii)) |
| Document verification | Site enumeration with both arms | #4719, #5069 | Neither card has an executable surface; their Dev Testing is document verification with a countable, failable predicate and a stated denominator |
| Plan conformance | `bash release/tools/verify-release-plan.sh` on this file | release | FCM declaration parse + coverage; **see the caveat below** |

**⚠️ The automated FCM check cannot see one row of this matrix — bug #5757, still OPEN.** `verify-release-plan.sh`'s `pathof()` matches declared paths against a closed prefix allowlist (`core|release|docs|packages|projects|roadmaps|.github|.claude`) that **omits `operations/`**. Dropped rows are not counted as `uninterpreted`, so the checker reports a clean parse while the row is invisible.

**Exactly one row of this matrix is affected:** `operations/templates/qa-acceptance-report-template.md` (#4719). Every other declared path begins `core/`, `release/`, `packages/` or `.github/` and is inside the allowlist.

**Consequence for Stage 9.** G-PR11's `fcm-delivery` verdict on this release is **partial, not clean** — it cannot detect a declared-but-undelivered `operations/` file. That single row must be graded by **direct diff inspection** against this matrix. Treating an `fcm-delivery` PASS as full coverage here would be a false green. The blast radius is one row rather than the 21 that made this defect material on `v4.37`, but the gate's blindness is identical in kind.

## Risk Register

| # | Class | Sev | Risk | Owner / Mitigation | Reversibility |
|---|---|---|---|---|---|
| **R-1** | Contention | HIGH | #5523 and #5816 share `pipeline-event-log-schema.md` and `append-pipeline-event.sh`; the tool's `--self-test` asserts lockstep **bidirectionally**, so a one-sided edit by either card fails the other card's own gate. | Stage 6. Serialize #5523 → #5816 (commits 4, 5). Re-run `--self-test` after the **second** card lands, not only after each. Graded as **CIAC-1**. | CHEAP · HIGH |
| **R-2** | Scope | HIGH | **#5816's remediation straddles the Layer-1 / Layer-2 boundary.** The live pipeline event log resolves through `lib-instance-path.sh` to the operator-instance path and is git-ignored — it is outside the repo tree entirely. Its historical row loss is operator-local and cannot be repaired in this PR. | **Discharged at Stage 5.** ACs re-scoped to grade against **committed fixtures**, never the live log. The "20 malformed rows" figure was re-derived and is **0 of 2,686** — the original probe counted bare pipes rather than unescaped-pipe field splits. | MODERATE · HIGH |
| **R-3** | Cascade | MEDIUM | #5816 edits a skill surface (`release-hub/references/orchestration-playbook.md`), triggering the skill-edit discipline and a `.skill` package rebuild; a missed rebuild fails `deploy.sh --check` Check 7 with package drift. | Stage 6. Route the edit through `pmo-skill-editor` discipline; rebuild `packages/release-hub.skill` in the same PR (carried as an FCM row). **Scope narrowed at Stage 5:** `release-hub/SKILL.md` is no longer edited, so the rebuild set is **1 of 55**. | CHEAP · HIGH |
| **R-4** | Classification | — | *(Closed.)* The declared `routine` under-provisioned review depth for a 5-stage-spec release. | **Resolved by D-1** — re-classified `cross-cutting` at the Stage-4 gate. Tight engagement density, **Deep** Stage-9 depth, 30-day outcome window. | CHEAP · HIGH |
| **R-5** | Scope | — | *(Closed.)* #4719's AC5 sweep had live hits while the card was sized as if it did not. | **Resolved.** Re-sized `size:XS` → `size:S` (**D-3**); the SKILL-surface cascade resolved to **zero** genuine sites (the `weekly-status-rollup` "Override Record" is a homonym), so **0 of 55 packages rebuild for #4719**. Upper bound of "14 lines across 5 files" resolved to **exactly 2** genuine contradictions, both approved into the FCM under **R-1**. | CHEAP · HIGH |
| **R-6** | Rollback | MEDIUM | **#4732 changes the tool that runs this release's own close-out.** This release is the first to exercise the changed `automated-closeout.sh` phase 15.5, so a defect would surface at its own Stage 13 with no prior release having run it. | **Mitigation strengthened at Stage 5.** (i) Phase 15.5 stays **idempotent** — state machine and every return code untouched — so a wrong `SURFACE1-STATE` verdict degrades to a *mislabelled but present* Surface 1, never a missing one. (ii) Both arms run **offline against fixtures before Stage 12**, on the existing hermetic `$GH`-stub harness — no fixture tag, no public mutation. (iii) Self-test arm (i) re-proves the `:6221` aggregation non-regression on every run. | MODERATE · MEDIUM |
| **R-7** | Reflexive | MEDIUM | This release edits `stage-04-planning.md` (#4978) and `release-class-taxonomy.md` (#5069) — the two specs governing this stage — and cannot fire its own new rules on its own planning. | **Discharged at Stage 5.** Both changes carry an **introducing-release-exempt cutover** clause. #4978's `source:` grammar needs none — it tightens a three-form set § 5.7 already codifies, and this plan takes the pipeline-internal form, conformant under both wordings. The `provenance-survival` check itself carries no cutover: a check is code and cannot be release-conditional. | CHEAP · HIGH |
| **R-8** | Cross-milestone | LOW | The #4732 ruling makes `deploy.sh` Check 48 the load-bearing Surface-1 backstop; **#4326 / #4328** govern Check 48's integrity in milestone 315. | Recorded as a **soft, directional** edge. Neither blocks the other; **no relocation proposed**. **Stage-5 update:** Check 48's network cutover is **ARMED** at `v3.96` — the backstop premise is *stronger* than the ruling knew. Re-check at Stage 9 Phase A6.5. | n/a |
| **R-9** | Process | — | *(Closed.)* Milestone 350 carried no `## Parallelization Map` H2, so Phase A0's currency check had nothing to read. | **Resolved** — the milestone description now carries a dated Parallelization Map plus the FCM supersession table and the Amendment Log. | CHEAP · HIGH |
| **R-10** | Audit-baseline | MEDIUM | Open PRs = 0 and the one remote `release/*` head is fully merged. A default-to-zero over a **transiently-empty** in-flight population is not load-bearing on its own; a sibling branching tomorrow silently invalidates it. | Baseline pinned at `8dc00db1` / 2026-08-24T00:46Z and recorded in § Contention Map. **Re-measure at Stage 9 Phase A6.6 before the GO.** | n/a |
| **R-11** | Evidence | — | *(Closed, and falsified on both limbs.)* The Stage-4 plan claimed #4978's symptom was dormant and that its AC3 second plan does not resolve at `main`. | **Both false at `8dc00db1`.** `v4.37_RELEASE_PLAN.md` (merged 2026-08-23) carries **zero** `domain_practice`; `release/releases/plans/v4/v4.18_RELEASE_PLAN.md` exists at 456 lines and was backfilled in-release by `e56ba057`. AC3 becomes **satisfied-by-evidence** for that plan, with the evidence cited rather than the criterion dropped. | CHEAP · HIGH |
| **R-12** | Estimation | — | *(Closed.)* The quota heuristic's size-bucket table has no `size:XS` row, so #4719 fell outside the band table. | **Absorbed by D-3** — the re-size to `size:S` lands it inside the table. | CHEAP · HIGH |
| **R-13** | Premise | — | *(Closed.)* #5816 never passed Mode R; it entered on its `status: bundled` label after the pre-flight closed, so its interior claims were un-vetted at bundle scope. | **Discharged at Stage 5**, which gave #5816 a full premise re-review. Two interior claims were falsified (the malformed-row count; AC3's presence-vs-currency framing) and one live defect was found and absorbed (**#6116**). | CHEAP · MEDIUM |
| **R-14** | Capacity | MEDIUM | **`effective_pts` 31 against a 25 ceiling — 24% over band.** The 1.3 weight models coordination and review load; Stage 9 runs **Deep** review over an oversize bundle, and the Stage-6 build is write-serialized across seven cards. | **Operator-accepted with recorded rationale (D-5).** Not re-adjudicated at Engineering. If Stage-9 review surfaces strain, the recorded split remains available — Slice A (#4732 #4923 #4719) = 10 pts, Slice B (#4978 #5523 #5816 #5069) = 21 pts; **INT-1 sits inside A and CIAC-1 inside B, so neither coupling is severed.** The absence of a mechanical `effective_pts` re-check is filed as **#6117**, deliberately not added to this release. | MODERATE · HIGH |
| **R-15** | Gate coverage | MEDIUM | **`verify-release-plan.sh` cannot see this matrix's one `operations/` row** — #5757 is OPEN, and dropped rows are not reported as `uninterpreted`, so the checker reports clean while the row is invisible. | Stage 9. Grade `operations/templates/qa-acceptance-report-template.md` by **direct diff inspection** against the matrix. Treating an `fcm-delivery` PASS as full coverage would be a false green. Blast radius here is **1 row**, not the 21 that made this material on `v4.37`. | CHEAP · HIGH |
| **R-16** | Allocation | MEDIUM | **Six ADRs are authored on one branch and none has a reserved number.** The oracle is a read, so two ADRs authored back-to-back without re-running it collide; reserving ahead creates a **gap**, which blocks the repo. | Stage 6. Re-run `renumber-adr.py --next-free` **immediately before authoring each ADR**, in implementation-sequence order. Never batch-allocate. A duplicate is mechanically renumberable; a gap is not. Contiguity anchor at `8dc00db1`: ADR-141 is the highest merged across both directories. | CHEAP · HIGH |

## Delivery Strategy

Single branch, one PR, one merge gate. **Stage 6 is fully serial and write-serialized** — one build spoke at a time, in the § Implementation Sequence order. Stages 5, 7 and 8 are parallel-eligible per card; Stages 6 and 13 are write-serialized. Stages 10 and 11 are **compressed** for git-native releases — the git history is the snapshot and the PR diff is the dry run — and their sub-tasks are created then immediately closed so the rationale has a durable home.

The PR is opened **once**, after the build completes. No card opens its own PR; no card merges anything. Per-issue closure is a **Stage-13** action — every member is marked as closed there, never in an Engineering commit or PR body, since GitHub's auto-close parser fires on a close-family verb adjacent to `#N` regardless of section context.

## Stage Applicability Matrix

Stages 5–8 are per-issue. Stages 9–13 are release-scoped singletons.

| Stage | Applies | Note |
|---|---|---|
| 4 Planning | ✅ | this document |
| 5 Solutioning | ✅ | **complete, 7 of 7** — all returned COMPLETE, zero BLOCKED, zero repo mutations |
| 6 Engineering | ✅ | **fully serial**, 7 build spokes + Commit 0 |
| 7 Dev Testing | ✅ | parallel-eligible ×7 (#4719 and #5069 are document-verification) |
| 8 QA Testing | ✅ | parallel-eligible ×7 |
| 9 Plan Review | ✅ | **Deep** review depth per `cross-cutting` class; N-way consistency table + cross-D upstream-compatibility scan |
| 10 Dry Run | ⏭️ | compressed — the PR diff is the dry run |
| 11 Snapshot | ⏭️ | compressed — git history is the snapshot |
| 12 Execute | ✅ | version claimed here; the braced RELEASE_VERSION token resolved and this plan renamed into `plans/v<MAJOR>/` on the CAS-win path |
| 13 Close | ✅ | **30-day** outcome window per `cross-cutting` class |

**Per-issue Stage-5 applicability was not a default.** Each of the seven cards named its own unresolved design decision, and the two skip candidates on triviality (#4719, #5069) both failed the test — #4719 because its AC5 sweep had live hits, #5069 because its own Proposed Change presented two framings and argued for one while naming what it loses. That is a decision, not an edit.

## Quota Budget

**Verdict:** **WARN** (per `quota-budget-protocol.md` Checkpoint A)

**Parallel-eligible spokes per parallel stage:** Stage 5: **0** (complete) · Stage 6: **0** (serial) · Stage 7: **7** · Stage 8: **7**

**Worst remaining parallel batch:** **7** spokes.

**Per-spoke cost estimate:** size-bucket **ordinal band** per § 5 (`[CALIBRATE-AFTER-3]`, MEDIUM). Batch mix: 4 × `size:S` (*lowest*) + 2 × `size:M` (*low-moderate*) + 1 × `size:L` (*moderate*). Source: heuristic — the § 5.1 cutover to observed medians has not been evaluated for any bucket, so the ordinal floor is retained. The `spoke-launch` / `quota-reservation` telemetry substrate is declared in the schema but not emitted, and no `estimate-usage.sh` median was supplied.

**Assumed/stated remaining usage-window envelope:** **not stated.** No operator quota state was injected at hub start, so a **conservative default** applies per § 3.1.

**Estimated cumulative draw % (worst parallel batch):** **50–80% band (projected, not measured).** Three quantities are absent — an absolute per-spoke token figure, an absolute envelope, and an operator-stated band — so **no numeric percentage is rendered**. Per § 6.1's refuse-to-synthesize rule, a fabricated percentage here would be a projection presented as a measurement. The band is placed by ordinal reasoning: 7 concurrent spokes is the largest remaining wave, and the mix is now heavier than at Stage 4 (the #5816 re-size moved one member from *low-moderate* to *moderate*).

**Routing:** **WARN → window-aware launch timing + quota-budgeting (split batch) recommended.** Concretely: split each of the Stage 7 / Stage 8 waves into **4 + 3**. Stagger is explicitly **not** the mitigation — it is a rate-limit defense and does not reduce cumulative consumption, which is the specific error § 4.4 names.

**Note.** Checkpoint B re-validates at **every** `Agent`-tool launch — wave or singleton, every stage — with PROCEED / SERIALIZE / DEFER / REDUCE-scope for a wave and the reduced PROCEED / DEFER form for a singleton. Bands and the cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM. **This plan-time estimate is advisory and gates nothing** — the load-bearing gate is Checkpoint B at Procedure 2 Step 5.5.

## Rollback Strategy

### Per-Issue Rollback

Every authored file is git-tracked and each card's commits are revertible in isolation, in reverse sequence order (#4732 → #4978 → #5816 → #5523 → #4719 → #4923 → #5069). Two constraints on a partial revert:

1. **#5523 and #5816 revert together or not at all.** The lockstep assertion is bidirectional, so reverting one leaves `append-pipeline-event.sh --self-test` red. Reverting the pair restores a consistent state.
2. **`packages/release-hub.skill` is regenerated, not reverted by hand.** A revert of #5816's source edit must be followed by `bash core/deploy/tools/build-skill-packages.sh release-hub`, or Check 7 reports package drift in the opposite direction.

`release/releases/plans/v4/v4.13_RELEASE_PLAN.md` is a **terminal release record** whose #4978 backfill is additive and independently revertible.

### Whole-Release Rollback

Revert the merge commit. All 26 edit paths are text or tracked-config edits; the two fixture directories and the one new tool are additive; the six ADRs are new files. **No schema migration, no data movement, no path move** — so the release reverts as one unit. Reversibility **MODERATE · confidence HIGH**.

### The one asymmetry, stated rather than hidden

**#4732 changes the tool that performs this release's own Stage-13 close.** If a defect in the changed phase 15.5 surfaced at that close, a `git revert` of the release merge would not retroactively un-run the close-out. Three properties bound that exposure, and each is asserted rather than asserted-about: phase 15.5 remains **idempotent** with every return code and outcome token unchanged, so a wrong provenance verdict degrades to a *mislabelled but present* Surface 1 and never to a missing one; both arms are proven **offline on fixtures before Stage 12**, so the changed path is exercised before it is trusted; and the self-test's aggregation arm re-proves the `automated-closeout.sh:6221` non-regression on every run. The residual is a **mislabelled close-out record**, which is repairable by editing the record — not a lost Surface 1.

## Operator Decisions Recorded

Decisions carried **into** Engineering from Stages 3–5.

| # | Decision | Verdict | Reversibility |
|---|---|---|---|
| **D-1** | Release Class | `routine` → **`cross-cutting`** — trigger (a) fires at 5 stage-spec files against a threshold of 3; the prior `routine` declaration failed its own trigger (a), since three members are P2 | CHEAP · HIGH |
| **D-2** | Release Outcome Statement | BEFORE clause 6 (orphaned by #5229's departure) swapped for an #5816 clause; AFTER unchanged | CHEAP · HIGH |
| **D-3** | #4719 sizing | `size:XS` → **`size:S`** | CHEAP · HIGH |
| **D-4** | Stage-4 release plan | **APPROVED** — authorises Procedure 1 scaffolding | MODERATE · HIGH |
| **R-1** | Tier-2 `[SCOPE CHANGE]` × 4 (wave A) | **APPROVED, all** — including the optional #4923 S-7 | MODERATE · HIGH |
| **R-2** | Outcome Statement BEFORE clause 1 | **"Four" → "Seven"** surfaces — the clause understated the reconciliation target by three, in a block that G3-11, G-PR7 and QC4-06 / G-CL7 all read by heading level | CHEAP · HIGH |
| **R-3** | Wave B launch | **AUTHORIZED** — #5523, #5816, #5069, carrying wave A's outcomes | MODERATE · HIGH |
| **R-4** | Wave-B File Change Matrix changes | **APPROVED** — #5816 (+6 edit, +2 add, 1 package rebuild, +1 ADR); #5523 (1-line `stage-13-close.md`); #5069 (none). #5816's SC-2 was **not discretionary**: `BLOCK-DESTRUCTIVE-022` blocks the new tool without the allowlist entry, and CI Arm B(ii) fails without the manifest row | MODERATE · HIGH |
| **R-5** | #5816 sizing | `size:M` → **`size:L`** — six edits, two adds, a new tool with 11 fixtures and a package rebuild is not a 4-pt card | CHEAP · HIGH |
| **R-6** | #6116 disposition | **ABSORBED into #5816**, not added as an eighth member. Filed for traceability; delivered inside #5816's scope via a hub-direct Stage-5 addendum | CHEAP · HIGH |
| **R-7** | Collective Review scope-lock | **LOCKED** at 7 members / 24 raw pts. Stage 6 recomputes the authoritative path union from the seven Stage-5 specifications, **not** from the Stage-4 matrix | MODERATE · HIGH |
| **D-5** | `effective_pts` band breach | **ACCEPTED with recorded rationale** — 31 against a 25 ceiling. Grounds: one coherent AFTER outcome across all seven members; all seven Stage-5 designs complete and interlocking; splitting now would cost a re-bundle (clearing the Composition Lock), a second milestone, a re-scaffold and a second full Stage 6–13 run. Cost recorded, not discounted — see **R-14** | MODERATE · HIGH |
| **D-Version** | Release identity | **Token-bearing / slug-primary per ADR-092.** Bump class `minor`; no digit in the filename, the branch, or this plan's identity prose. Provisional **v4.39** recorded at Stage 4, **re-verified and confirmed at Engineering Commit 0**, claimed only at the Stage-12 CAS | CHEAP · HIGH |
| **D-C** | Branch topology | **SINGLE** — one release branch; this plan commits as Engineering Commit 0 | CHEAP · HIGH |
| **D-ADR** | ADR number allocation | **Hub determination (rule-determined, not a gate).** No number is allocated at design time — the oracle is a *read*, not a reservation. Engineering allocates each at authoring time, in implementation-sequence order. A duplicate is renumberable; a **gap blocks the repo** | CHEAP · HIGH |

## Decisions of Record — this release

The rows above are decisions carried **into** the release. The rows below are decisions rendered **during** it, at Stages 5–6. They are recorded here because the release plan is the surface a spoke greps: a decision that exists only in the pipeline event log and in issue comments is, from inside a spoke, indistinguishable from a decision that was never made.

| # | Card | Decision |
|---|---|---|
| **D-4732-1** | #4732 | Phase 15.5 emits `SURFACE1-STATE=<CREATED\|EDITED\|NO-OP>` **prefixed to the phase detail, outcome token untouched**. Rejected: a new outcome token — it silently inverts `automated-closeout.sh:6221`, making a genuinely-created Release report as *"Surface 1 not emitted this run"*; a new phase 15.51 — it would have to re-derive the pre-mutation state after 15.5 already mutated it; prose-only enrichment — that is materially what ships today. The vocabulary is **reused**, not invented: it is already live at 2 of the 3 Surface-1 emit paths. |
| **D-4732-2** | #4732 | Phase B5.6 is re-framed from an **existence** check to a **provenance** check, **report-not-block**. Rejected: a pre-backstop blocking existence check — it would hard-block **11 of the last 12 closes, including this release's own**, which is the reflexive-pipeline-loop pathology the tool's own exit-2/3 rationale names; dual independent probes — net-new where infrastructure covers, and the two probes can disagree. Absence of the token resolves `UNVERIFIED`, **never PASS**. |
| **D-4719-1** | #4719 | **RULE-A wins** — the Override-Record obligation attaches to an **AC-blocking** PARTIAL. Won on merits, not on count: across **46** normative Override-Record lines, **zero** state the unqualified rule in reasoned form. Shape is one normative statement + N citing, with `AC-blocking` given a definitional anchor. "Qualify every site" was rejected as re-restating the defect in new clothes. |
| **D-4923-1** | #4923 | G1-03 admits a **second evidence shape** — label-position probe markers, **≥2 co-present**, scoped to the `### Evidence` section for both arms. Marker set of 6, derived from `review-discipline-principles.md` § 8.2's own field labels. Layer split: **Layer-B(g) predicate only**; Layer-A `validations:` unchanged. The semantically most attractive option was rejected on measured corpus behaviour — it admits **2 of 239** bodies. |
| **D-4978-1** | #4978 | `source:` grammar → **ROUTE, not EXTEND** (closed three-form grammar); a two-limb `provenance-survival` family in `verify-release-plan.sh` modelled on `fcm-delivery`; normative in `stage-04-planning.md` § 6 with a cite-not-restate pointer in the bridge; AC3 backfill on `v4.13` plus a Deviation-Log row. The **absolute-presence limb is mandatory** — a delta-only comparison is vacuous when both surfaces are empty. |
| **D-5069-1** | #5069 | **Framing (b)** — remove `RELEASE_LOG.md` from the trigger-(b) named set, leaving **6** rule-defining surfaces. Chosen on measurement: across 20 pinned shipped releases the divergence against the operator's declared class was literal **2**, framing (a) **1**, framing (b) **0**. **(a)'s exclusion list is open-ended; (b)'s removal is closed.** Generalisable principle: *a classification predicate must not count an artifact the classified process is itself mandated to produce.* |
| **D-5523-1** | #5523 | A `#### 11.8.1` subtype-vocabulary registry **inside** § 11.8 (the existing awk parser's `^#{1,3} ` scan does not match `####`, so zero parser-structure change), plus a widened label-token charset `[a-z0-9_-]+`. The card's own proposed remedy — rows in the `--source` table — is **prohibited by § 11.8's own text**, authored three days before the card was filed. |
| **D-5816-1** | #5816 | Declare `decision` / `decision-superseded` with its vocabulary in #5523's `#### 11.8.1` registry; add a **read-only** `check-event-record-integrity.sh` with 5 checks and both-arms fixtures; declare the cutover instant in schema § 4.1 and parse it in the tool. AC3 re-stated from a **presence** predicate to an **ID join plus terminal-state agreement** — it passed 13/13 while 12 of those 13 rows were stale. |
| **D-5816-2** | #5816 | **#6116** (the `--self-test` concurrent-append defect) resolves by **Option D — run the self-test against a temporary copy so the live log is never opened for write**, chosen over identity-based revert, advisory locking and snapshot-restore on the grounds that those three *guard* a mutation while D *removes* it. |
| **D-6-1** | release | **Engineering Commit 0 re-verified the version.** Next-free for bump class `minor` recomputed against `origin/main` @ `8dc00db1`: tag anchor max `v4.38`, `RELEASE_LOG` max version row `v4.38` over 198 rows with **zero** `DEPLOYED` rows, so next-free = **`v4.39`** — equal to the Stage-4 provisional and absent from the claimed set. **PROCEED.** No plan file was overwritten. |
| **D-6-2** | release | **The Stage-4 File Change Matrix was not copied.** The 26-path union in § File Change Matrix is recomputed from the seven Stage-5 specifications. Three Stage-4 rows are **retired** and are recorded in § Deviation Log rather than silently dropped. |

## Deviation Log

A declared ADD that legitimately does not ship requires a row here carrying the literal `NOT DELIVERED` and the declared path.

| Path or token | Status | Basis |
|---|---|---|
| `core/standards/hub-action-tracking.md` | **RETIRED from FCM** (Stage-4 row, superseded) | Declared for #5816 at Stage 4. #5816's Stage-5 specification does not edit it — the design's remedy is a read-only validator plus a schema registration, neither of which touches the action-tracking standard. Listed under § File Change Matrix → *Release-wide explicit non-scope* so its absence from the diff reads as a recorded decision. |
| `release/skills/release-hub/SKILL.md` | **RETIRED from FCM** (Stage-4 row, superseded) | Declared for #5816 at Stage 4. Stage 5 scoped the skill-surface edit to `release-hub/references/orchestration-playbook.md` alone (Procedure 4a). The package rebuild is still owed and is still an FCM row; the `SKILL.md` edit is not. |
| `packages/release-hub.skill` | **RECLASSIFIED** — `edit` (Stage-4) → build artifact regenerated by `build-skill-packages.sh` | Same path, same delivery obligation; the verb is corrected so Stage 9 grades it as a rebuild output rather than a hand edit. Its `.sha256` sidecar is added as an explicit row. |
| The braced RELEASE_VERSION token | **UNRESOLVED, by design** | This plan is authored **pre-claim / token-bearing** per ADR-092. The Header `**Version**` cell is the **single** braced-token site in this file — deliberately, so the stamp has one verifiable substitution point and a post-claim residue scan has an exact sensitivity arm (**1** pre-claim occurrence must become **1** resolved literal and **0** residue). Every other mention in this plan, including this row, names the token **unbraced** precisely because `claim-version.sh`'s substitution is global: a braced mention inside prose would be rewritten too, turning this row's own verdict into a self-contradiction the moment the claim ran. `claim-version.sh --stamp-slug` resolves the Header cell post-CAS at the Stage-12 claim and `git mv`s this file to `plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md`. Asserted at Commit 0 by `claim-version.sh --verify-stamp pipeline-spec-self-consistency` → **exit 0**. |
| ADR numbers (× 6) | **UNALLOCATED, by design** | No number is reserved. Each is allocated at the moment its ADR is authored, via `renumber-adr.py --next-free`, in implementation-sequence order. Contiguity anchor at `8dc00db1`: ADR-141 highest merged across both directories. See **R-16**. |
| `operations/templates/qa-acceptance-report-template.md` | **DECLARED — invisible to the automated FCM check** | #5757 (OPEN): `verify-release-plan.sh`'s `pathof()` allowlist omits `operations/`, and dropped rows are not reported as `uninterpreted`. This is the matrix's **only** affected row; it must be graded by direct diff inspection at Stage 9. See **R-15**. |
| #5816 `type:` / `cluster:` / `project:` labels | **MISSING — recorded, not fixed here** | #5816 carries only `size:L` and `status: bundled`. A live label-hygiene gap on a release member; it does not block the build and is routed rather than silently normalised inside an Engineering commit. |
| Stage-6 rework, Pass 2 (DT↔Engineering iteration loop) | **CONSOLIDATED REWORK PASS** | One batched Engineering pass closing Stage-7 Dev Testing findings across three cards — operator ruling, to avoid two rework and two re-review cycles. Origin and disposition, in severity order: **#4978 F-1 (BLOCKER)** the suite pinned `schema v2` against an emitted `v3` — the expectation is now DERIVED from `SCHEMA_VERSION`, with a non-empty arm so the derivation cannot pass vacuously; **#4978 F-2 / #5816 F-1 (SIGPIPE ×6)** rewritten, no T2/T3 marker taken; **#4923 F-1 (CIAC-2)** `gate-criteria-spec.md` `:328` + `:558` reconciled to cite `§ Gate 1 G1-03` rather than restate the superseded predicate; **#5816 F-2** a `**/tests/fixtures/**` exclusion in the issue-ref gate; **#5816 F-3** the `integrity_cutover` escape given a Stage-12 executor and a failing arm. **#4923's shell-harness regression is diagnosed but NOT landed** — see its own row below. No card scope was implemented beyond these findings. |
| SIGPIPE remedy — two reviewers prescribed CONFLICTING forms | **RESOLVED PER CALL SITE, not by picking a side** | #4978's reviewer prescribed a here-string; #5816's explicitly prescribed **not** the here-string, because it discards the writer's status under `set -e`. Both are right within their own scope, and the discriminator is whether the producer's exit status is load-bearing. `verify-release-plan.sh`'s four sites write `printf` on a variable — no status to lose — so a here-string is exact, and it is already this file's own documented form at its `recorded=1` `SIGPIPE-REWRITE`. `check-event-record-integrity.sh`'s two sites write `run_engine`, which carries a real status (1 = findings, 2 = unreadable surface), so they capture to a variable per the harness's own `arm()` idiom. Verified with the shipped gate's own five regex constants over both populations: 6 of 6 pre-edit lines fire, 0 of 10 post-edit lines match. |
| `.github/workflows/repo-integrity.yml` | **APPROVED for the FCM, NOT USED** | The operator approved two paths for the issue-ref fix on the premise that the workflow carries a twin implementation asserted identical to the script. **That premise is stale**: the job is already a THIN CALLER (`bash core/deploy/tools/check-issue-ref-validity.sh`) and its own comment records that it holds no pattern, resolver or identifier literal — the twin was eliminated by an earlier extraction. One implementation, so one file changed. The `--equivalence` arm compares against the **pre-extraction** body materialised from git history, and it still passes: all 15 destinations in the shared fixture manifest sit under `docs/`, `.github/`, `core/rules/` or `release/releases/`, so the exclusion is a no-op on that corpus. Delivering narrower than authorised is the right direction to err; the row is not added. |
| `core/deploy/tests/test_g1_form_family.sh` | **FCM ADDED by operator ruling at Stage 6 — fix landed** | #4923's `Shell harness (macOS)` regression (29 passed / 3 failed, fixtures #900007 / #900008 / #900014, *"presence leaked into shape"*). **Root cause, and it is not the predicate.** The harness extracts the C22-EVAL sentinel region from `deploy.sh` into a synthesised runner. #4923's S-5 extraction moved the G1-03 predicate to a top-level function so Check 22 and `--self-test` group EV share one code path — but that put it **outside** the extracted region. The region carries 2 references to `_g1_03_evaluate` and **0 definitions**; the runner runs under `set -uo pipefail`, so the call returns 127, `!` inverts it, and every body whose applicability gate is satisfied (an `### Evidence` section is *present*) takes an unconditional G1-03 FAIL. That is precisely *presence leaking into shape*. The predicate itself is correct — verified standalone on the exact failing bodies, and 243/243 against an independent reference at Stage 7. The fix belongs in `build_runner`, which already synthesises the region's other dependencies: splice the SHIPPED predicate in rather than stubbing it, and fail loudly when extraction is empty. **Applied and executed during the Stage-7 pass: 29/3 → 32 passed, 0 failed. Then reverted**, because the harness was on no FCM row and no glob covered it. Committing it would either have added an unapproved path or shipped an undeclared one — and an undeclared changed path is exactly what this release's own `fcm-delivery` check exists to catch. **Resolved at Stage 6: the operator approved the FCM addition (+1 row, `edit`, under #4923), and the patch is now landed.** The root cause was re-derived before applying rather than pasted from the prior pass: on this branch the C22-EVAL region (`deploy.sh` L6659–L7457) carries **1 live-code reference** to `_g1_03_evaluate` (L7248, plus a comment at L7243 — the "2 references" of the earlier count) and **0 definitions**, while the definition sits at **L3959, outside the region**; at the baseline `8dc00db1` the region carried 0 references and 0 definitions, the predicate being inline. Re-executed after applying: **32 passed, 0 failed.** |
| `release/references/pipeline/stage-12-execute.md` — cross-card use | **DECLARED PATH, DIFFERENT CARD** | The path is an FCM `edit` row under **#4732**; this pass's Phase B3.2 addition serves **#5816's** F-3. The path is declared, so the automated FCM-delivery check is satisfied; the card attribution differs and is recorded here rather than left for Stage 9 to infer. |
| `core/schemas/stage-io-contracts.md:50`, `release/references/pipeline/stage-01-intake.md:90` | **STALE — out of FCM, reported not fixed** | Surfaced while grading CIAC-2 by enumeration rather than match count. Both restate G1-03's superseded bracket-only predicate (*"≥1 evidence-labeled claim"*), and both are invisible to a `G1-03`-keyed sweep because neither line carries the token — which is why Stage 7 did not see them. `stage-01-intake.md:90` both **cites and restates**, the case #6106 caveat 3 names. Neither file is on the FCM, so both are reported. `ADR-144:35` carries the same string as an **archival blockquote** in its Context section and is correctly untouched — editing it would falsify the decision's own history (caveat 1). |
| Stage-6 build order — #4732, #4719 | **LANDED OUT OF SEQUENCE** | § Implementation Sequence orders `#5069 → #4923 → #4719 → #5523 → #5816 → #4978 → #4732`. Builds 1 and 2 landed **#4732 at position 1 instead of 7** — reversing **INT-1**, which requires #4923 before #4732 — and **#4719 at 2 instead of 3**. Cause: the hub routed from a fabricated sequence rather than from this table. Remediation: **AI-001** (`verification`, open) re-verifies #4732's AC6 against the post-#4923 `core/deploy/deploy.sh` once #4923 lands; the remaining builds follow this table. Residual **accepted**: #4732's tail-position rationale (**R-6**) is inverted — the tool that performs this release's own close-out was changed first, so every later commit executes against it. |
| `core/ADRs/README.md`, `release/ADRs/README.md` | **CHANGED, ON NO FCM ROW — renumber-tool output, recorded for Stage 9** | Both are `M` in the branch diff, and neither is matched by any § File Change Matrix row, glob, READ-only row or non-scope row — the token `README` occurs **zero** times in § File Change Matrix. That measurement is deliberately scoped to the matrix, not to this file: this row names both paths, so a whole-plan count would be falsified by the row asserting it. **Both are R4 output of `release/tools/renumber-adr.py`, not hand edits**, and the mechanism differs per file. `release/ADRs/README.md` is a **PROJECTED** surface (`PROJECTED_INDEXES`, ADR-117): R4 regenerates it through `generate-adr-index.py` from the on-disk file set, so its six added rows inside the `ADR-INDEX` markers are a projection of the delivered records, not a typed table — hand-editing that region is precisely what its own verification posture fails. `core/ADRs/README.md` is deliberately **absent** from that map — a curated thematic document, never an index — and R4 rewrites it in place; its one changed line is the § Renumber log append. **This is not a gate failure.** The `fcm-delivery` family is inbound-only **by design**: `verify-release-plan.sh:884-885` records that the outbound direction (*"every delivered add is declared"*) is *"a real and separate gap and is deliberately NOT solved here"*. All **50** checks are green, measured at `226372e3`. The row exists because a Stage-9 reviewer grading scope **by reading the diff** sees undeclared paths and cannot tell from the diff alone that they are tool output rather than unapproved scope. **State the denominator:** exactly **three** changed paths sit outside the matrix — these two, plus this plan file itself, which **D-C** declares as Engineering Commit 0. **Context.** `142 → 148` was the single legal move: the sibling `selftests-actually-test` release merged its own `release/ADRs/ADR-142-resolve-the-root-do-not-exempt-the-fixture.md` into the mainline first, and 143–147 are this branch's own five records, so 148 was the only slot that neither collides nor opens a gap. That also supersedes the `8dc00db1` contiguity anchor carried by the *ADR numbers (× 6)* row above and by **R-16**: ADR-141 was the highest merged across both directories then, ADR-142 is now. The move is **ADR-115**'s claim-binds-at-merge rule resolving in the mainline's favour — not a batch-allocation defect (**R-16**'s risk, which did not fire) and not drift. `python3 release/tools/check-adr-numbers.py` → **PASS (148 ADRs, contiguous `001..148`, no duplicates)**. |
