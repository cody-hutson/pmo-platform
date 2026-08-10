<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Release Plan — closeout-output-completeness (automated close-out emits every codified output it promises, on every release)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: closeout-output-completeness
release_class: routine
domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-09, domain: software }
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `closeout-output-completeness`

**Milestone:** `closeout-output-completeness` (milestone 314). Seven members — six build cards and one verify-only card — on one branch, one pull request, one merge.
**Version identity:** **slug-only** per **ADR-092**. This file is `closeout-output-completeness_RELEASE_PLAN.md` and the branch is `release/closeout-output-completeness`; no version stem appears in the filename, in the branch name, or in this plan's identity prose. Bump class is `minor`. The concrete number binds at the **Stage-12 atomic compare-and-swap**, which renames this file into its major-version bucket.
**Topology:** **SINGLE** (decision D-C, operator-rendered) — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (decision D-Concurrency Posture, operator-rendered). Stage-6 work routes one card at a time in the approved sequence on the shared branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`routine`** — confirmed at the Stage-4 gate on a corrected evidentiary base (see § Release Class). Posture: engagement density **Light** · Stage-9 review depth **Standard** · Stage-5 activation bias `SKIP-where-trivial`, **activated on 4 of 6** · Stage-13 outcome window **30-day**.

---

## Provenance

This file transcribes the **Stage-4 Release Planning** analysis approved at the plan-approval gate, reconciled forward through the four **Stage-5 Solutioning** designs, the Stage-5 pair-1 and pair-2 decision points, the Phase-A6.5 adversarial review, and the amended design that resolved its blocker. Where a later measurement superseded a Stage-4 figure, **this file carries the decided state** and § Deviation Log records the delta. The Stage-4 and Stage-5 output comments are the historical record and are not edited. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke.

Every issue reference below sits inside this reference block and is accompanied by the summary that makes it readable without opening the ticket.

---

## Release Outcome Statement

**AFTER** — Automated close-out emits every codified output it promises, on every release.

**BEFORE** — Close-out silently drops outputs: Close-Class-Telemetry has never been emitted by the mechanism across roughly thirty releases, the velocity and learnings phases are absent from the close-out report, resolver-routed writes are discarded at commit, and `--dry-run` aborts before its review gate.

**Success Indicator:** every ticket below closes with its acceptance criteria verified, and the gate or check each one names demonstrates a **real failure on a fixture** before it is trusted.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | slug-only pre-claim per ADR-092; bump class `minor`; recorded determination **v4.22** |
| **Date Created** | 2026-08-08 (Saturday) — Stage-4 planning |
| **Commit 0 authored** | 2026-08-09 (Sunday) |
| **Release Manager** | Agent-assisted, release-hub Mode O |
| **Status** | Executing — Stage 6 Engineering |
| **Branch** | `release/closeout-output-completeness` |
| **Base commit** | `db0293de`, equal to `origin/main` at branch cut on 2026-08-09 |
| **Pull request** | populated at PR creation, Stage 6 — one PR across all six build cards |
| **Milestone** | `closeout-output-completeness`, milestone 314 |
| **Release class** | `routine` |
| **Topology and posture** | SINGLE topology, P0 fully-serial posture |

**Commit-0 version re-verify (detect-and-HALT, executed 2026-08-09): PROCEED.** After `git fetch --tags origin && git fetch origin main`, the allocator dry-run `claim-version.sh --bump minor --sha db0293de --dry-run` returned **`v4.22`**, matching the version this release carried into Stage 6. The highest tag on origin is `v4.21`; `v4.22` is unclaimed.

**This release has already been re-versioned twice mid-flight, and the record is kept rather than overwritten.** The Stage-4 determination was **v4.20**; the sibling release `hook-precision-and-boundaries` (pull request #5081) merged and claimed that slot, so Stage 5 pair-2 recomputed **v4.21**; that number was in turn already marked `VERIFIED` for the sibling release `ci-wiring-and-flake-elimination` by the time the amended design ran, so the next-free recomputed to **v4.22**. Two collisions inside one milestone's design phase is the reason **no version literal ships in this release's code** (see § Deviation Log entry D-15) and the reason the plan filename carries no version stem. The number above is a *recorded determination*, not a reservation: it binds only at the Stage-12 compare-and-swap.

---

## Scope

| Ticket | Size | Pts | Disposition | One-line scope |
|---|---|---|---|---|
| #4767 | `size:S` | 2 | build, sequence position 1 | the telemetry tool cannot run on any live milestone |
| #4765 | `size:S` | 2 | build, sequence position 2 | `--dry-run` aborts before its review gate |
| #4773 | `size:S` | 2 | build, sequence position 3 | the close-out report omits phases that ran |
| #4437 | `size:M` | 4 | build, sequence position 4 | close-out never emits Close-Class-Telemetry |
| #4722 | `size:S` | 2 | build, sequence position 5 | resolver-routed skill writes are discarded |
| #4432 | `size:S` | 2 | build, sequence position 6 | version-less close-out documented as it behaves |
| #4710 | `size:S` | 2 | **verify-only**, no build | resolved on `main`, demonstrate then close |

**Raw 16 points** · release class `routine` → `class_weight` **1.0** · **effective points 16** (round-half-up), inside the 15–25 band. The G3-15 gate is an upper-bound predicate only; verdict **PASS**.

### Approved implementation sequence

```
#4767 → #4765 → #4773 → #4437 → #4722 → #4432
```

The verify-only card #4710 is marked closed at Stage 13 on demonstrated evidence, and is not built.

This sequence **inverts** the milestone description's declared order and was re-sequenced at the Stage-4 plan-approval gate, operator-approved. Rationale, stated once: the surviving scope of #4437 is *emit Close-Class-Telemetry*, which requires invoking `compute-close-class-telemetry.sh` — the tool that #4767 reports as unable to run on any live milestone (payload **1,098,975 bytes** against an `ARG_MAX` of **1,048,576**). Building #4437 first would wire a close-out phase to a tool that aborts on every run. The card #4773 likewise precedes #4437, because #4437 adds a phase that would otherwise have to be hand-added to the very enumeration that #4773 is deleting. There is zero membership change, so this is an `amend`-class re-sequence inside sub-window B.

| # | Issue | Why it sits here |
|---|---|---|
| 1 | **#4767** | Sources the hard edge into the telemetry emitter. Isolated file `compute-close-class-telemetry.sh`, zero contention with the other five, so it lands first at no rebase cost downstream. |
| 2 | **#4765** | Restores `--dry-run`, the verification substrate that positions three through six lean on. Landing it second makes those cards testable through the mandated review gate rather than through `--apply` on a live release. |
| 3 | **#4773** | Converts the report's phase enumeration from hand-maintained to derived, before a new phase arrives that would otherwise need hand-adding. |
| 4 | **#4437** | Both hard prerequisites are satisfied: the tool runs, and a new phase self-reports. Emits Close-Class-Telemetry, arms the Check 48 assertion, and carries the backfill decision. |
| 5 | **#4722** | Independent; placed after the coupled cluster so its isolated `changed_skills_from_paths` edit rebases onto a settled file. |
| 6 | **#4432** | Last by design — the widest surface, and placing it after the dry-run restoration lets the version-less disposition reconcile against the settled branch in one coherent pass. |
| — | **#4710** | **No build.** Demonstrate the three acceptance criteria against a fixture, record the evidence, mark closed at Stage 13. |

---

## Release Class

The class is `routine`, confirmed at the Stage-4 gate — but on a narrower evidentiary base than the milestone description claimed.

| `routine` trigger | Verdict | Evidence |
|---|---|---|
| (a) all issues P3/P4 and `size:S`/`size:M` | **FALSIFIED** | two cards carry severity **Major**, and four cards are priority P2 |
| (b) all change-spec files have three or more prior release touches | **FIRES** | `automated-closeout.sh` 49 · `deploy.sh` 213 · `stage-13-close.md` 47 · `compute-close-class-telemetry.sh` 3 |
| (c) zero new files added | **FALSIFIED** | two cards each add a regression suite under `release/tools/tests/` |
| (d) zero new D-class decisions | **FALSIFIED** | two cards each require a recorded decision |

The class stands on trigger **(b) alone**; the enum needs only one. The `novel` class's trigger (b) also fires, so the two are not cleanly separated by trigger sets — the tiebreak is the taxonomy's own `novel` anti-pattern, that ticket-newness is not protocol-newness and the trigger is *introduces a new reference doc, schema, or skill*. No card here introduces a new reference doc, schema, or skill. The aggregate shape is corrective work on three of the most-touched files in the repository. **`routine` is correct, on an honest basis.**

---

## Dependency Graph

Directional. Every edge carries its evidence; no card is called independent without a stated basis.

```
#4767 ──HARD──> #4437
#4773 ──HARD──> #4437
#4765 ──SOFT──> #4773, #4437     (verification-substrate edge)
#4765 <──FILE-REGION──> #4432    (bidirectional contention, not a precedence edge)
#4722   (independent)
#4710   (resolved on main — no edges, no build)
```

| Edge | Class | Evidence |
|---|---|---|
| **#4767 → #4437** | HARD | The surviving acceptance criterion of the emitter card is *close-out emits Close-Class-Telemetry*, and that emitter must call `compute-close-class-telemetry.sh`, whose `count_subtask_evidence()` passes the whole payload as `argv[1]`. The measured failure is fatal to the whole script, so no indicator is produced at all. |
| **#4773 → #4437** | HARD | The `phases=()` array inside `generate_markdown_report` is a hand-maintained enumeration, so a new phase is invisible in the report unless hand-added. The report card's second acceptance criterion replaces that array with a derived set. |
| **#4765 → #4773, #4437** | SOFT | Both downstream cards' criteria read *run a close-out, then assert something in the report*. Dry-run today aborts at phase 9.55 before eleven later phases enumerate, so those criteria are otherwise exercisable only through `--apply` on a live release. |
| **#4765 ↔ #4432** | FILE-REGION | Shared-region contention inside `phase_assert_derived_surfaces`, resolved to **zero** by the version-less decision outcome — see § Contention Map. |
| **#4722 independent** | — | Its edit target is `changed_skills_from_paths`; no other card in the bundle touches that function, and the function is called only from the package-rebuild path. |

**Circular chains: zero.** The denominator is 15 ordered pairs over six build cards. *Sensitivity arm:* the same pairwise procedure yielded four genuine edges, so the probe detects edges when they exist — this is not a default-to-zero.

---

## Stage Applicability Matrix

Per the milestone's own Success Indicator, **no card skips Stage 7 or Stage 8** — every one of them claims a testable failure and every criterion demands an anti-vacuity arm.

| Issue | Stage 5 | Stage 6 | Stage 7 | Stage 8 | Stages 9–13 | Stage-5 rationale |
|---|---|---|---|---|---|---|
| #4767 | **SKIP** | ✓ | ✓ | ✓ | ✓ | Mechanical: move the payload off `argv`. The fix shape is named in the card's own Affected Files. |
| #4765 | **SKIP** | ✓ | ✓ | ✓ | ✓ | Mechanical: add a `MODE` branch mirroring ten sibling phases that already have one. |
| #4773 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Genuine design choice — derive the reported set versus extend the enumeration — plus a consumer-compatibility scan. |
| #4437 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | New phase, new Check-48 sub-check, and a historical-backfill decision. Three surfaces, one of them a corpus mutation. |
| #4722 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Its third criterion requires a fix-shape judgment reconciled against the corrected sibling surface. |
| #4432 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Carries a D-class disposition with two materially different blast radii. |
| #4710 | N/A | N/A | **verify-only** | ✓ | Stage 13 | Implemented on `main`; the remaining work is demonstration, grading, and closure. |

**Departure recorded:** the hub scaffolded **both** Stage 7 and Stage 8 for the verify-only card, against the Stage-4 row that gave it *Stage 7 verify-only, Stage 13 only*. That row was authored under the spoke's recommendation to drop the card from the bundle; the operator instead rendered **demonstrate-then-close**, and without Stage 8 the criteria would be demonstrated but never formally graded. The operator confirmed this departure at the scaffold-review gate.

---

## Contention Map

Six of seven cards edit one file, so the map is resolved at **function** granularity — file granularity would report that everything collides with everything and be useless for merge ordering.

### Within-release — `release/tools/automated-closeout.sh`

| Region | Claimed by | Overlap verdict | Resolution |
|---|---|---|---|
| `is_version_less` and the CLI gate | #4432 | Sole claimant | none needed |
| `phase_assert_derived_surfaces` | #4765 and #4432 | **Resolved to ZERO** | Under the version-less (b2) outcome, the later card touches **zero lines** in this function. The co-tenancy contract binds the dry-run card: it must not touch the three `is_version_less` guards, must not nest its `MODE` test inside the not-applicable limb, must not alter the slice skip, and should place the dry-run guard as an early return at the top of the function. |
| `changed_skills_from_paths` | #4722 | Sole claimant | none needed |
| the `phases=()` array in `generate_markdown_report` | #4773 and #4437 | **TRUE OVERLAP** | Sequencing: the report card at position three lands before the emitter card at position four, so the emitter adds no array entry at all. |
| the CLI dispatch block | #4432 and #4437 | **ADJACENCY**, roughly six lines apart | Sequencing: the emitter card lands before the version-less card. Under SINGLE topology these are sequential commits on one branch, so the adjacency is a rebase concern only. |
| the new emission phase | #4437 | Sole claimant | none needed |

The `overlap_class` per ADR-005 for the surviving true overlap is `line-range-overlap` — an edit to an existing construct, **not** an `append-pattern` — so ADR-005's informational treatment does not apply and the mitigation is sequencing per ADR-001.

### Cross-PR contention

Baseline-pinned at commit `5ffa57c2` and timestamp 2026-08-09T01:23:12Z, re-checked at branch cut `db0293de`.

| Sibling | Intersection with this release's file set | Class | Action |
|---|---|---|---|
| pull request **#5085**, branch `release/ci-wiring-and-flake-elimination` | `core/deploy/deploy.sh` | `line-range-overlap` | Risk R3 — serialize the merge, do not split scope. The new Check-48 sub-check is a new block. |
| pull request **#5081**, branch `release/hook-precision-and-boundaries` | empty at plan time | — | **Merged since**, claiming `v4.20` and touching the script-execution allowlist. That allowlist entered this release's edit set only at the pair-1 gate, so the collision is newly possible; it was re-probed and is additive. |

*Probe validity:* the intersection was computed as `comm -12` over sorted path lists. **Sensitivity:** the identical invocation returned a non-empty result for the first sibling. **Specificity:** the second sibling touches `core/deploy/tests/` and `core/deploy/tools/` while the first touches `release/tools/`, so the probe demonstrably resolves both parent trees; the empty result at plan time was a true empty, not a broken probe.

### Structural blast radius

**No movers.** The bundle declares zero renames, relocations, or deletions — every card is an in-place edit to an existing function, plus new suites under an existing directory. No sibling serializes on a mover axis.

---

## Risk Register

| ID | Risk | Severity | Owner action | Mitigation | Reversibility |
|---|---|---|---|---|---|
| **R1** | **Sequence inversion.** Building the milestone's declared order wires the telemetry emitter to a tool that aborts on every live milestone, producing a phase that always FAILs. | **HIGH** | Adopt the approved sequence | The approved order, with both hard edges evidenced above. **Discharged at plan approval.** | CHEAP / HIGH |
| **R2** | **Same-function contention** between the dry-run card and the version-less card inside `phase_assert_derived_surfaces`. | **MED** | Sequence plus CIAC-3 | **Downgraded:** the version-less (b2) outcome leaves the later card touching zero lines in that function, so the criterion now grades the co-tenancy contract rather than a live conflict. | CHEAP / HIGH |
| **R3** | **Cross-PR contention on `core/deploy/deploy.sh`** with an in-flight sibling release. | **MED** | Serialize merge | Whichever merges second rebases; the new sub-check is a new block, so conflict is likely additive rather than semantic. | CHEAP / MEDIUM |
| **R4** | **Version-slot race.** Two siblings were in flight at plan time. | **LOW** | None at plan time | **Materialized twice**, v4.20 then v4.21. The Stage-12 atomic claim absorbed it as designed: no rollback, no version gap. The residual is further mitigated by shipping **no version literal in code**. | CHEAP / HIGH |
| **R5** | **Historical backfill** across roughly thirty releases would balloon this release's scope well past sixteen points. | **MED** | Backfill decision | **Resolved:** the operator rendered *accept-with-rationale* — fix forward, no historical backfill. | CHEAP / HIGH |
| **R6** | **Self-test blindness recurs.** The root cause of the telemetry defect is a green suite structurally unable to reach it, because synthetic payloads are always under `ARG_MAX`. The same shape can re-ship inside this very release. | **MED** | Anti-vacuity arms | Every card's criteria demand a must-fail arm, and Stage 8 verifies each was **observed** non-zero rather than merely written. The oversized arm joins `--self-test` and carries an exec-level negative control that fails the suite if the fixture ever stops being oversized. | CHEAP / HIGH |
| **R7** | **The report's shape changes**, with an unverified consumer risk at plan time. | **LOW** | Stage 5 | **Discharged:** the consumer scan is complete with sensitivity and specificity arms, finding **zero** programmatic parsers. Downgraded to accepted-residual. | CHEAP / MEDIUM |
| **R8** | **Scope drift on the emitter card.** Its title still claims three dropped outputs; two are resolved. | **MED** | Re-scope before Engineering | **Discharged at Stage 5:** the design was authored against the corrected one-output scope, and the card body is left as historical record per ADR-062. | CHEAP / HIGH |
| **R9** | **Sub-check (l) ships inert.** The telemetry cutover default of `__none__` means the new gate asserts nothing on this release, and an unowned escape hatch is how a gate stays dormant forever. | **MED** | Follow-on issue | The `__none__` branch of the four-branch arm emit **says so out loud on every run**, so dormancy is advertised rather than concealed; arming is a build item on a follow-on issue, not a comment. | CHEAP / HIGH |

**Rollback strategy.** One release branch and one merge, so `git revert -m 1 <merge-sha>` restores every surface atomically. There is no migration, no data mutation, no external state, and — under the accept-with-rationale backfill decision — no corpus backfill to unwind. The one obligation that does not revert with the branch is the operator-instance copy of `core/config/allowlists/script-execution-allowlist.txt`: it is a **composition surface**, and hooks read the token-resolved deployed copy rather than the source, so the operator instance needs `./update.sh --surfaces-only` (the command `deploy.sh --deploy` cannot refresh it). **Overall: CHEAP / HIGH.**

---

## Cross-Issue Acceptance Criteria

Four criteria. Each spans two or more issues, asserts a cohesion constraint no per-issue criterion covers, and is graded on the merged pull request at Stage 9.

**Two of them were REPLACED at the Stage-5 pair-1 decision point**, under the operator-rendered CIAC-revision decision. Both original methods break against the accepted designs, and neither would have failed loudly — both would have gone **green on evidence that cannot discriminate**, which is the worse failure at a go/no-go gate. The criteria below are the **amended** forms and are the ones graded. The first and third carry forward unchanged in claim; the third's grading is restated non-vacuously.

- [ ] **CIAC-1 — the Close-Class-Telemetry emission path, spanning #4767 and #4437.** The close-out's telemetry phase invokes `compute-close-class-telemetry.sh` against a milestone whose sub-task payload exceeds `ARG_MAX`, and receives a non-empty field value rather than an abort.
  *Shared surface:* the emission path from `automated-closeout.sh` into `compute-close-class-telemetry.sh`.
  *Method:* run the emitter against a milestone whose sub-task payload exceeds one mebibyte; assert **exit 0** and a **non-empty, eight-slot-conformant** field value. *Anti-vacuity:* the same payload passed as an `argv` operand to any executed program must fail with `Argument list too long` — if it does not, the fixture is not over-bound and the criterion is vacuous.

- [ ] **CIAC-2 — the report's phase enumeration, spanning #4773 and #4437 — REPLACED.** Every phase the run **recorded** appears in the close-out report, with no second list edited to achieve it.
  *Shared surface:* the derived phase set that `generate_markdown_report` renders.
  *Method (replacement):* source the function slice, seed the record with every dispatched phase plus `post_gate_passage_proof`, render the report, extract the rendered row names, and assert that recorded-minus-rendered is the empty set.
  *Why the original broke:* it extracted from the static `phases=()` array that the accepted design **deletes**, so the method is unrunnable after the fix; and it asserted that definitions are a subset of the reported set, which the fix makes trivially true while the real drift class stays invisible — the **record** set of 33 exceeds the **definition** set of 32, because `post_gate_passage_proof` is recorded through `mark_phase` with no matching phase function.
  *Measured non-vacuous baseline:* **3** at commit `433de822` — the velocity, learnings, and epic-rollup phases. It must read **0** after.

- [ ] **CIAC-3 — the derived-surfaces assertion phase, spanning #4765 and #4432.** The dry-run branch and the version-less disposition agree inside the one function: no `is_version_less` guard survives referencing a path the CLI cannot reach, and no `MODE` branch is left unreachable.
  *Shared surface:* `phase_assert_derived_surfaces`.
  *Method:* assert a `MODE` reference count of at least one in the function body; assert the three `is_version_less` guards intact and reachable per the retained-and-documented outcome; and assert the dry-run guard is sited as an early return outside all three guards. *Anti-vacuity control:* `phase_append_changelog`, a sibling phase carrying exactly one `MODE` reference — a probe returning zero there is broken, not clean.
  *Contention note:* under the retained-and-documented outcome the version-less card touches **zero** lines in this function, so this criterion grades the co-tenancy contract rather than a resolved conflict.

- [ ] **CIAC-4 — the close-out report as audit trail, spanning #4765, #4773 and #4437 — REPLACED.** A full dry-run against a release that has not yet closed exits 0 and renders **exactly as many phase rows as phases the run dispatched**, with no row carrying an empty Result cell.
  *Shared surface:* the generated close-out report.
  *Method (replacement):* run the close-out in dry-run markdown mode; assert exit 0 and that rendered rows equal dispatched phases — 32 dispatched phases plus `post_gate_passage_proof` is **33 rows** at the pre-emitter baseline, and 34 once the telemetry phase lands.
  *Why the original broke:* it asserted *zero placeholder rows in the phase table*. Under a derived report a phase that did not run is **absent**, not placeholder-filled, so the assertion becomes **vacuously true** and would pass on any implementation, including a totally broken one.

---

## File Change Matrix

**Machine-readable path list** — one path per line, so Stage 7, 8 and 9 chips extract this block deterministically:

```
release/releases/plans/closeout-output-completeness_RELEASE_PLAN.md
release/tools/compute-close-class-telemetry.sh
release/tools/automated-closeout.sh
release/tools/tests/test_close_class_telemetry.sh
release/tools/tests/test_closeout_dry_run.sh
core/deploy/deploy.sh
core/config/allowlists/script-execution-allowlist.txt
release/references/pipeline/stage-13-close.md
release/references/templates/release-learnings-register-template.md
```

| Path | Intent | Owning cards |
|---|---|---|
| `release/releases/plans/closeout-output-completeness_RELEASE_PLAN.md` | add | this plan, landing as Engineering Commit 0 |
| `release/tools/compute-close-class-telemetry.sh` | edit | the telemetry-tool card #4767 |
| `release/tools/automated-closeout.sh` | edit | the dry-run, report, emitter, skill-resolver and version-less cards |
| `release/tools/tests/test_close_class_telemetry.sh` | add | the telemetry-tool card #4767 |
| `release/tools/tests/test_closeout_dry_run.sh` | add | the dry-run card #4765 |
| `core/deploy/deploy.sh` | edit | the emitter card #4437, for Check 48 sub-check (l) |
| `core/config/allowlists/script-execution-allowlist.txt` | edit | the telemetry-tool card #4767 — **File Change Matrix deviation 1** |
| `release/references/pipeline/stage-13-close.md` | edit | the version-less card #4432 and the emitter card #4437 |
| `release/references/templates/release-learnings-register-template.md` | edit | the emitter card #4437 — **scope addition**, the A7.1 rollup marker |

**Test-suite filenames are the Stage-6 spokes' allocation.** The two suite paths above are named by their implementing card and registered in the script-execution allowlist in the same commit. The directory `release/tools/tests/` is enumerated **per-suite, not globbed**, so a suite is invisible to the allowlist until it has its own entry.

---

## Verification Plan

### Per-issue

- **The telemetry-tool card #4767** — `compute-close-class-telemetry.sh --self-test` passes, **including** the new oversized-payload arm; the suite `release/tools/tests/test_close_class_telemetry.sh` passes with its sensitivity arm observed **non-zero** (the pre-fix argv form fails on the fixture) and its specificity arm observed **zero** (the shipped function succeeds on the same fixture), with non-empty extraction asserted on both.
- **The dry-run card #4765** — a full dry-run reaches phase 16 and enumerates every later phase, and its suite `release/tools/tests/test_closeout_dry_run.sh` passes.
- **The report card #4773** — recorded-minus-rendered equals the empty set against a seeded record, with the measured baseline moving from three to zero.
- **The emitter card #4437** — the telemetry phase emits a conformant eight-slot field into the resolved Deployment Log surface, and Check 48 sub-check (l) runs its four-branch arm emit and reports its dormant state explicitly.
- **The skill-resolver card #4722** — `changed_skills_from_paths` delegates to the package builder's own resolution rules with a fail-loud guard, and the three map-declared trees resolve.
- **The version-less card #4432** — the scoping sentence, the two-kind fallback-trigger list, the reachability comment, and the corrected line pointer all land, with zero behavior change.
- **The verify-only card #4710** — the three criteria are demonstrated against a fixture with negative-control, sensitivity and specificity arms.

### Release-level

- `core/deploy/deploy.sh --check` — Check 14 doc-link integrity across modified markdown files, against an expected-red baseline pinned at branch cut.
- Runtime-suite selection per the runtime-suite selection map: row 4 (`release/tools/*.sh` → `python3 release/tools/check-selftest-coverage.py --run`) **and** row 5 (`core/config/allowlists/**` → `bash core/deploy/tests/run-install-regression.sh` under the temporary-`HOME` sandbox). One `test-run` event per suite.
- The four Cross-Issue Acceptance Criteria above, run by `release/tools/verify-release-plan.sh` and graded at Stage 9.

---

## Rollback Strategy

A `git revert -m 1 <merge-sha>` on the single merge commit restores every surface atomically. There is no migration, no data mutation, no external state, and no corpus backfill. **CHEAP / HIGH.**

The one obligation that does not revert with the branch is the operator-instance copy of the script-execution allowlist. Hooks read the token-resolved deployed allowlist rather than the source, so a revert of this branch must be paired with a re-run of `./update.sh --surfaces-only` to restore the deployed surface. This is recorded as a Stage-12 prerequisite in both directions.

---

## Domain Practice Provenance

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-09, domain: software }`

Sourcing-exempt: the entire File Change Matrix is internal platform artifacts. The domain is classified from the matrix — the dominant domain is **`software`**, being shell tooling under `release/tools/` and `core/deploy/`, with **`governance`** secondary for the pipeline stage doc and the register template. This is not domain-less: `core/standards/domain-best-practices/software.md` is the guide downstream consumers select.

---

## Deviation Log

Every entry is operator-rendered or hub-recorded at a named decision point, with the surface it deviates from stated.

| # | Deviation | Deviates from | Decision point | Disposition |
|---|---|---|---|---|
| D-1 | **Implementation sequence inverted** to put the telemetry-tool card first | the milestone description's declared order, which put the emitter card first | Stage-4 plan approval | **Adopted.** Zero membership change, so this is an `amend`-class change inside sub-window B. Both hard edges are evidenced. |
| D-2 | **The verify-only card #4710 was retained** rather than dropped from the bundle | the Stage-4 recommendation to drop it | Stage-4 plan approval | **Demonstrate-then-close.** It is implemented on `main` by two merged commits, but was never demonstrated by the method its criteria name. The bundle stays at sixteen points. |
| D-3 | **The emitter card was re-scoped down**, from three dropped outputs to one | the card body's three-dropped-outputs premise | Stage-4 empirical re-run | **Adopted.** The velocity and learnings phases both exist and run, and Check 48 already asserts both. The card body is left as historical record per ADR-062. |
| D-4 | **The report card was re-scoped *up***, from two omissions to three | the card body's two-omission premise | Stage-4 empirical re-run | **Adopted.** The epic-rollup phase is a third omission — the card's own prediction, realized. This makes *derive, do not enumerate* load-bearing rather than stylistic. |
| D-5 | **Backfill decision: accept-with-rationale** | the emitter card's third criterion, which admits either outcome | Stage-4 plan approval | **Fix forward.** A backfill would require running the newly-fixed tool against roughly thirty historical milestones, computing today's values against state that has moved. |
| D-6 | **Version-less decision: retain and document** | both options originally offered at Stage 4 | Stage-5 pair-2 | **Both original premises falsified.** The branches are *not* untested — the self-test dispatches six lines before the version-validation gate and drives twenty-seven arms — and *not* vestigial, since the gate predates the predicate by forty-four days. Retiring is structurally unavailable, because gate criterion G3-19 asserts release-identity mode as a closed enum at Bundle. The real defect is documentation: two files, zero behavior change. |
| D-7 | **Two Cross-Issue Acceptance Criteria methods were REPLACED** | the Stage-4 plan's authored methods | Stage-5 pair-1 | **Adopted.** Both break against the accepted designs and would have gone green on evidence that cannot discriminate. The replacements carry measured non-vacuous baselines. |
| D-8 | **File Change Matrix deviation 1 — allowlist rows folded into the telemetry-tool card** | the Stage-4 File Change Matrix, which did not list the allowlist | Stage-5 pair-1 | **Adopted.** The telemetry tool is absent from the script-execution allowlist — hub-verified as zero hits against a twenty-one-entry control arm — so the agent-side invocation this card's own Stage-7 arm needs is blocked by the destructive-action guard. It was folded into this card because that card owns the tool's runnability. |
| D-8a | **Five path forms, not four** | the allowlist header's four-form convention | Stage-5 pair-2 convention correction | **Adopted.** The sibling merge shipped its rows with a **fifth** generic suffix glob, covering a hub whose checkout is a downstream clone or a differently-named directory — the situation every spoke in this release has run in. This release follows the newer precedent. |
| D-9 | **File Change Matrix deviation 2 — the velocity-ordering criterion was split out** | the report card's authored scope | Stage-5 pair-1 | **Split, not dropped.** The premise was verified live and successor issue #5188 was filed, unmilestoned. Its fix surface lies outside this card's mapped region. |
| D-10 | **The JSON report gains an additive phase key** | the Stage-4 forward-note asserting a parallel enumeration existed there | Stage-5 pair-1 | **Adopted on a corrected premise.** Both Stage-5 spokes independently falsified the forward-note: the JSON report carries no phase list at all. This is therefore a deliberate capability addition, not divergence repair. |
| D-11 | **Skill-resolution fix shape: delegate, do not port** | porting the detection rules into the close-out's own resolver | Stage-5 pair-2, hub-accepted and not gated | **Adopted.** The package builder already implements the identical two-rule detection and the version claimer already consumes it, so the close-out's own copy is a third expression of the same rules — a shadow single-source-of-truth. Not gated, because the evidence is one-sided and manufacturing a choice would be ceremony. |
| D-12 | **The emitter card's Stage-5 design was RETURNED to Solutioning, then amended** | the first accepted design | Phase-A6.5 adversarial review at Collective Review | **Blocker resolved.** The rollup-presence indicator as first specified was **tautologically true**: the caller-supplied flag probed a field that phase 6.5 writes three phases earlier, so it returned present on every apply-mode run and published a fabricated metric under a mechanism label. |
| D-13 | **Indicator 5 measures the A7.1 rollup limb ONLY**, and the caller-supplied override is deprecated | the shipped tool's caller-supplied override | amended design, scope-locked | **Adopted, and folded into the telemetry-tool card** because the change is internal to that file. The outcome-field conjunct is discharged as a documented construction invariant of phase 6.5 rather than probed: a conjunction where one limb is true by construction reduces to the other limb. The value domain widens to present, absent, or not-applicable-with-reason. |
| D-14 | **Register-marker decision: a SEPARATE marker array, mandatory** | appending the rollup marker to the existing canonical-marker array | amended design | **Approved as separate.** Appending would move Indicator 1's denominator from ten to eleven and **retroactively depress retro-conformance on every existing register**, biasing the calibration baseline the field feeds. |
| D-15 | **Cutover-anchor decision: ship the dormant escape plus a follow-on issue** | shipping a version literal for the new sub-check's cutover | amended design | **Adopted.** The literal went stale **twice inside one design card**. The alternative anchor the review proposed was measured and rejected: it resolves to v4.03 with eighteen verified rows at or after v4.04 against a control of three at or below, raising roughly seventeen findings against lawfully grandfathered releases. The sub-check ships **inert by design**, saying so on every run, and arming is a follow-on build item. |
| D-16 | **Hub premise retracted: exit 1 and exit 2 ARE reachable** | the hub's statement that every exit in the telemetry tool is `exit 0` | amended design | **Corrected.** The die helper is `exit "${2:-1}"`, so exit 1 is reachable from six argument-validation sites and exit 2 is explicit at two sites for an unreadable register. The narrower true facts are that an unavailable GitHub CLI does **not** exit non-zero, and that exit 2 is an input/output condition rather than malformed content. **A caller cannot distinguish the CLI-less path by exit code and must read the emitted line.** |
| D-17 | **In-flight sibling roster corrected from three to two** | the hub's injected context | Stage-4 planning | One listed sibling had already merged before planning began. |
| D-18 | **The hub-supplied expected contention surface was over-broad** | the hub's injected hypothesis naming three additional release tools | Stage-4 planning | **Not adopted.** No card names any of the three in its Affected Files. This mattered concretely: one in-flight sibling *is* editing one of them, so had those been in scope there would have been a second cross-PR contention. |
| D-19 | **Six out-of-scope discoveries were routed OUT of the release** | — | Stage-5 pair-2 | Four new issues were filed, one discovery was folded into a card's own commit, and one was verified and closed. **None entered this milestone.** |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing. Refreshed on any Tier 1 adjustment that changes which issues land or which decisions stand.*

### Outcome

Close-out stops silently dropping the outputs it promises. This release fixes the one telemetry tool that could not run at all, restores the dry-run review gate, makes the close-out report derive its own contents instead of reading a hand-maintained list, wires the missing Close-Class-Telemetry emission together with a gate to keep it wired, retires a duplicated skill-resolution rule in favour of the single implementation that already exists, and reconciles the version-less close-out documentation with what the command-line interface actually does.

### Issues resolved (7)

| Issue | What lands |
|---|---|
| **#4767** | The telemetry tool can run on a live milestone. The sub-task payload no longer travels as an `argv` operand, so the tool no longer dies with an argument-list-too-long error on any milestone whose sub-task comment volume crosses the platform limit. Indicator 5 stops publishing a fabricated value, and the caller-supplied override is deprecated. |
| **#4765** | The dry-run reaches its review gate instead of aborting eleven phases early. |
| **#4773** | The close-out report enumerates the phases the run actually recorded, derived rather than read from a hand-maintained array that goes stale on the next phase added. |
| **#4437** | Close-Class-Telemetry is emitted into the Deployment Log block by a dedicated phase, with a check sub-assertion that will grade it once armed. |
| **#4722** | Skill resolution for the package-rebuild path delegates to the one implementation that owns those rules, with a fail-loud guard. |
| **#4432** | The version-less close-out path is documented as it actually behaves, and the fallback-trigger list gains the identity-rejection case that three live rows already took. |
| **#4710** | Demonstrated against a fixture and closed on that evidence — implemented on `main`, but never verified. |

### Key decisions

Nineteen deviations are logged above. The four an operator would most want surfaced are D-13 (Indicator 5 measures the limb the run does not write, removing a fabricated metric), D-15 (the new sub-check ships inert and says so, rather than shipping a version literal that has already gone stale twice), D-5 (no historical backfill — fix forward), and D-6 (version-less support is retained, because the defect was documentation rather than code).

### Reversibility

**CHEAP / HIGH.** One branch, one merge, one `git revert -m 1`. The single non-reverting obligation is the deployed copy of the script-execution allowlist — see § Rollback Strategy.

### Downstream impact

The close-out script gains one phase and loses one static list. The deploy script gains one check sub-assertion that asserts nothing until armed. The telemetry tool widens one slot's value domain and deprecates one flag. No JSON payload key is removed. No release-log row parser is affected, because the field line does not begin with a table delimiter.

**Release-note rationale — why past releases stay blank (carry verbatim into the Stage 13 release note per D-5).** Close-quality telemetry starts with this release and is not backfilled onto the roughly thirty releases that closed without it. Their Deployment Log entries stay blank on purpose. Reconstructing a past release's numbers would mean measuring today's registers and today's issue state against a release that closed months ago — the registers may have been written after the fact, and deferred items have been re-triaged since — so the numbers would be assembled rather than measured, and they would then sit in the same column as the measured ones with nothing to tell them apart. A blank entry says "not measured", which is true. A reconstructed one would say "measured" about a reading nobody took.

### Cross-references

Milestone 314, the planning sub-task #5093 carrying the approved Stage-4 plan and its amendment comments, the four Stage-5 design sub-tasks #5129, #5130, #5131 and #5132, the Stage-6 binding-constraints record #5137, the split-out successor issue #5188, and the four out-of-scope routing issues #5191, #5192, #5193 and #5194.

---

## Verification Evidence

*Populated at Stage 6 self-verification and refreshed by Dev Testing. Emitted by `release/tools/verify-release-plan.sh --format=md` where the check family supports it.*

---

## Deployment Execution Log

*Populated at Stage 12.*
