---
title: Release Plan — expected-red-never-masks-regression (an expected finding must never share an exit member with a clean or a genuinely-regressed one)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: expected-red-never-masks-regression
release_class: novel
reversibility: MODERATE / Confidence HIGH — every member is a bounded edit to a tracked file and `git revert -m 1` of the merge restores `main` byte-for-byte, but the revert is **not neutral**: it re-arms two gates that publish a non-failing conclusion over degraded or unmeasured state. That is the pre-existing condition rather than a new fault, and it is the reason this release is MODERATE and not CHEAP.
---
# Release Plan — `expected-red-never-masks-regression`

**Milestone:** `expected-red-never-masks-regression` (milestone #412) · hub sub-task **#7443** = the Stage-4 plan source and its two **Decision Recorded** comments · **#7444** = card #7193's Stage-5 design source and the Phase A6.5 findings bearing on it · **#7445** = card #7440's Stage-5 design source, the full Phase A6.5 adversarial review, and the release-wide **Collective Review scope-lock** record · **#7446** = card #7201's Stage-5 source (integration criterion `INT-1`) · **#7447** = the Stage-6 Engineering sub-task that authored this file at Engineering Commit 0.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete `vX.Y` binds only at the Stage-12 atomic claim per ADR-092, so the branch and this file stay slug-primary while in flight and the Header **Version** cell carries the unresolved stamp token. The Commit-0 version re-verify ran in full — see § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch (`release/expected-red-never-masks-regression`), one PR, one merge, base `main`. This plan file lands as **Engineering Commit 0**.

**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch; the next spoke starts only after the prior commit lands. Two of the three members edit the same function of the same file roughly fifteen lines apart, so serialization is the correct read of the contention map rather than a fallback. Force-push on the shared branch is prohibited, `--force-with-lease` included.

**Release class:** `novel` — **re-classified from `routine`** at the Stage-4 Plan Approval gate (2026-09-12); see § Release Class declaration and § Operator Decisions.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7443 together with both **Decision Recorded** comments there, reconciles it to the approved Stage-5 Solutioning designs posted on #7444 (#7193) and #7445 (#7440, jointly with #7201), and applies the **binding corrections** ratified at the Collective Review scope-lock recorded on #7445. Where a later disposition supersedes a Stage-4 or Stage-5 value, the transcribed section carries the **ratified** value and § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #7447, card #7193).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination. It sets the floor and binds no concrete number. The Stage-4 recorded determination was **v4.64** (anchor `v4.63` + minor bump); the Commit-0 re-verify recomputed the same value against fresh authoritative host state, with the **tag arm binding** and the ledger and adapter arms corroborating. See § Commit-0 Version Re-Verify Record. |
| **Date Created** | 2026-09-12 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/expected-red-never-masks-regression` |
| **Baseline pin** | `origin/main` @ `343fbd2046d48fe26ca34bb6e83a0a4a1d73f3eb` |
| **PR** | (populated at Stage 6 Phase C — this release ships as a SINGLE PR, opened draft by the first spoke) |
| **Milestone** | `expected-red-never-masks-regression` (#412) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-12, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): the File Change Matrix is entirely internal `pmo-platform` artifacts — one shell engine (`core/deploy/deploy.sh`), one Python tool (`release/tools/check-selftest-coverage.py`), two CI workflow definitions, one committed sentinel and one standards register — so no external body of practice is consumed and no Form-A citation exists to record. **Mode-B rationale: NOT APPLICABLE — Stage 4 Phase A1.5 emitted Form X, not Mode B**, so the Stage-5 § 5.7 upgrade obligation does not fire and the label travels unchanged through Stage 5 into this file. Dominant domain **`software`** (the dominant rows are executable tooling and CI workflow definitions); secondary domain **`governance`** (`core/standards/gate-efficacy-standard.md`). Dominant is recorded in the label, secondary noted here, per the A3-time classification rule. Transcribed unchanged from Stage-4 Phase A1.5 and re-affirmed at both Stage-5 passes.

---

## Commit-0 Version Re-Verify Record

The first Engineering spoke under SINGLE topology re-runs the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1** — refresh authoritative host state | **EXECUTED.** `origin/main` = `343fbd2046d48fe26ca34bb6e83a0a4a1d73f3eb`. The Stage-4 baseline pin was `343fbd20`; **the substrate did not move between Planning and Engineering** — the plan's pin and the Commit-0 base are the same commit, so no rebase step exists. | `git fetch --tags origin` · `git fetch origin main` · `git rev-parse origin/main` |
| **2** — recompute next-free for bump-class `minor` | **EXECUTED. Next-free = `v4.64`.** `anchor()` = **v4.63**, the highest claimed `vX.Y` in the mainline lineage. `FLOOR(minor)` = `(4, 64)`; `v4.64` is absent from `claimed_set()`, so the walk terminates at the floor. | Three independently-read arms. **Tag arm (BINDING)** — `git ls-remote --tags origin 'refs/tags/v*'`, **207** distinct `vX.Y` names, **207/207 parsed by the integer-tuple comparator, 0 unparsed**, max `v4.63`, `v4.64` × **0**. **Ledger at the remote tip** — `git show origin/main:release/releases/RELEASE_LOG.md`, 2,461 lines, 212 version data rows, `v4.64` rows × **0**, and **zero `DEPLOYED`-not-`VERIFIED` in-flight rows** (all 212 read `VERIFIED`). **Adapter** — `CLAIM_REPO=… release/tools/claim-version.sh --sha 343fbd20… --bump minor --dry-run` → `v4.64`, exit 0, no tag pushed. The adapter is the authoritative mechanism; the two hand-read arms corroborate it rather than re-deriving it. |
| **3** — PROCEED / HALT on claimed-set membership | **PROCEED.** `v4.64` is **not** in the claimed set **and** equals the recomputed next-free — the conjunction the gate requires. **The verdict rests on the tag arm alone**, per the precedence rule: any arm showing the version claimed may raise a HALT, but only the tag arm reading it free may clear one, because a missing ledger row is not evidence of freeness (a sibling's ledger chore PR merges *after* the release PR it describes). The ledger and adapter arms corroborate and did not authorize. | **Sensitivity arm** — the identical readers resolve **`v4.63` as present** on the tag arm (× 1) and in the ledger (× 1), so membership detection demonstrably fires; a `v4.6[0-3]` glob over the same tag population returns **4**. **Specificity arm** — `v4.64` and every higher name (`v4.6[4-9]`, `v4.7*`, `v4.8*`, `v4.9*`, `v5.*`) return **0** over that same non-empty 207-name population. |
| **3b** — stamp-manifest assertion | **EXECUTED post-write, pre-commit.** `release/tools/claim-version.sh --verify-stamp expected-red-never-masks-regression` → **exit 0** (`verify-stamp OK`). | Read-only and network-free — the identical pre-flight the Stage-12 atomic claim runs before its compare-and-swap, so this Commit-0 PROCEED rehearses the real claim rather than a lookalike. The Header **Version** cell carries the literal unresolved `{{RELEASE_VERSION}}` token and no other text; the bump class lives in the **Bump Class** row beside it, because the Version cell is a machine-read stamp manifest rather than prose. The manifest is plan-only (no `--stamp-file` entries), so a zero package consequence is correct and announced rather than an error. |

**Why the number is recorded but not bound.** Step 2's `v4.64` is a Commit-0 *reading* of authoritative state, not a claim. Nothing is held between now and the merge; a concurrent release that merges first takes `v4.64` and this release's claim recomputes upward at the compare-and-swap. Recording the reading makes the Commit-0 PROCEED reproducible without asserting a reservation the allocation rule does not create. **The numbers in this section are deliberately not restamped later** — they are a reading at a named SHA, reproducible by re-running the recorded commands at that SHA.

**A Stage-12 `--stamp-slug` note, recorded now because it is cheap now and expensive later.** With this file committed, the depth-1 pre-claim plans directory carries **two** `{{RELEASE_VERSION}}`-bearing candidates — this plan and the in-flight `declarations-have-a-firing-surface_RELEASE_PLAN.md`. `claim-version.sh`'s slug derivation **refuses** on two or more candidates rather than guessing, so the Stage-12 Phase B3 invocation **must pass `--stamp-slug expected-red-never-masks-regression` explicitly**. This is the ordinary in-flight-overlap condition the explicit-pass rule exists for, not a defect in either release.

**`${AUDIT_DATE_UTC}`: NOT DECLARED.** The File Change Matrix creates no downstream load-bearing `YYYY-MM-DD` identifier — no audit-folder path, no ADR (Phase A5 returned *no ADR* on both Stage-5 passes), no dated verifier id. No literal date appears in a load-bearing position in any member's change. Local civil date and UTC date agree at authoring time (both 2026-09-12, Friday), so no divergence needs naming.

---

## Scope

### Summary

Three cards, one root cause, **two checkers**, **9 points**. The capability outcome: **an expected finding never masks a genuine regression** — every exit space this release touches gains a partition in which `0` has exactly one producer, and the reader-facing surface says which state occurred.

Both amended probes today collapse distinct verdicts onto one integer. Check 32 (`deploy.sh --check-release-corpus`) maps `CLEAN`, `SKIP` and `INCOMPLETE`-under-`warn` all to exit `0`, so a consumer cannot tell a check that ran and found nothing from one that did not evaluate. `check-selftest-coverage.py --reconcile` collapses eight assertion sites onto one non-zero member, so an expected residual and a genuine regression are indistinguishable at the check surface. The remedy in both cases is the exit-space convention the repository already carries twice — `cmd_check_package_freshness` (FRESH 0 / advisory 2 / not-evaluated 3 / blocking 1) as extended by `cmd_check_decision_emission` — applied to two more probes, with each probe's own `--self-test` asserting the partition as a **population** property and carrying a sensitivity arm that fires on a deliberately collapsed mapping.

**This release authors zero new files** other than this plan. Every other row is an in-place edit.

### Issues Included

| # | Issue | Size / Pts | Primary surface | Sequence |
|---|-------|-----------|-----------------|----------|
| 1 | **#7193** — Check 32 collapses CLEAN, INCOMPLETE and SKIP onto exit 0 | `size:M` / 4 | `core/deploy/deploy.sh` | position 1 |
| 2 | **#7440** — `mode_reconcile`'s eight assertion sites share one non-zero exit member | `size:M` / 4 | `release/tools/check-selftest-coverage.py` | position 2 |
| 3 | **#7201** — the Arm F annotation does not carry the posture marker | `size:XS` / 1 | `release/tools/check-selftest-coverage.py` | position 3 |

**Raw Σ = 9 pts** — not the 5 the milestone description carried before the Stage-4 correction (#7440's Scope-table row still read `TBD at Stage 2 / —`). `effective_pts` = 9 × 1.15 = **10**, below the 15–25 band, which the milestone description already justifies as first-class for a small-slice shape. Band read from `release/tools/compute-release-velocity.sh` (XS=1, S=2, M=4, L=8, XL=16).

### Exclusions

- **#6114** (milestone `nothing-passes-on-nothing`) — adds Arm D as a new writer into the exact exit space #7440 partitions. **Tier-S serialization edge, recorded on both; not a build dependency and not relocated.** Whichever lands second re-expresses its arm in the other's exit vocabulary.
- **Two out-of-scope observations routed to next-release issues, neither executed here:** (a) `deploy.sh:19236` and `:11682` claim a `required` posture / *"SINGLE canonical required-context"* for a job absent from `main`'s registered contexts — a posture-declaration correction with an operator decision behind it; (b) `_c32_compute_verdict` collapses two materially different SKIP causes (ledger absent vs. ledger header unparseable) onto one token — a diagnostic-granularity improvement that would expand the verdict set #7193's first acceptance criterion is written against.

### Dependency Graph

**Native GitHub dependency edges among the three cards: ZERO**, measured over a 511-issue denominator with a firing sensitivity arm (47/511 carry a non-empty `blockedBy`, 35/511 a non-empty `blocking`); a first, narrower sweep returned zero subjects *and* zero controls and was reported BROKEN rather than clean. Parent edges (a different relation, populated): #7201 → epic #7176 · #7193 → epic #6619 · #7440 → none.

Derived (non-native) edges:

- **#7193 — INDEPENDENT in both directions.** Different file, different checker, no shared runtime surface with the other two. Its only in-release intersection is a *different row* of one governance register.
- **#7440 → #7201 — DESIGN DEPENDENCY (hard), with a corrected rationale.** The milestone recorded this as *"#7440 sets the exit contract #7201's annotation rides"*. That is not the operative mechanism. #7440's own body defers its remediation shape to Stage 5 and names *"changing how the job consumes the result"* as an alternative under which #7201 becomes **moot rather than done**. The true edge is **"#7201's disposition is an output of #7440's Stage-5 decision"** — which is why the sequence is preserved and why AI-001 existed.
- **Circular chains: ZERO.** Denominator 3 nodes, 2 derived edges, both directional; the graph is a forest. Sensitivity arm: the #7440 → #7201 edge is a genuine non-empty edge in the same graph, so the zero is not the artifact of an empty edge set.

#### Cross-Milestone Dependency Validation

`#6114 ↔ #7440` on `release/tools/check-selftest-coverage.py` is the only cross-milestone edge, and the milestone under-stated it: Arm D is currently WARN-only and sets no `failed` flag, so #6114's fix adds a **new writer** into the exit space #7440 is partitioning. Classified **Tier-S serialization**, not a build dependency; neither card relocates.

### In-Flight Release Roster

**Measured at** `343fbd20` · 2026-09-12T18:03:44Z · **population n = 3 siblings** (open PRs with a `release/*` head, unioned with remote `release/*` heads carrying no open PR — `git ls-remote` returned exactly the same 3 refs, so the union adds nothing).

| Slug | PR | Head SHA | Bump-class | Recomputed next-free | EDITSET ∩ this release's FCM |
|---|---|---|---|---|---|
| `deploy-tools-and-tests-batch` | #7404 (draft) | `6b73e2e7` | UNRESOLVABLE | UNRESOLVABLE | `.github/workflows/release-tooling-smoke.yml`, `core/deploy/deploy.sh` |
| `authoring-bar-and-consumers` | #7410 (draft) | `62abeec3` | UNRESOLVABLE | UNRESOLVABLE | — |
| `hub-emits-state-gates-read` | #7416 (draft) | `c8f0499d` | UNRESOLVABLE | UNRESOLVABLE | — |

**#7404's intersection is real but LOW-severity: the regions do not overlap.** Its workflow hunks land at ~L318, ~L355 and ~L1102 — the last inserting a step at the tail of the job *preceding* `selftest-discovery` (which begins at L1105), so it does not enter the job whose step ordering #7440 depends on and does not disturb the "Arm F must stay last" constraint. Its `deploy.sh` hunk is a single line at `cmd_check()` L9369, roughly 9,900 lines from #7193's nearest edit. Expect line-offset rebases, not conflicts. The roster carries **no verdict**; Stage 9 Phase A6.6 re-measures.

---

## Implementation Sequence

**`#7193 → #7440 → #7201`** — re-ordered from the milestone's declared `#7440 → #7201 → #7193` on measured evidence, and ratified as operator decision **D-1**.

| # | Card | Pts | Why here |
|---|---|---|---|
| 1 | **#7193** | 4 | Independent in both directions, and it carries **by far the highest rebase exposure**: `core/deploy/deploy.sh` has **65 commits in the last 14 days / 358 all-time**, against 2 / 7 for `check-selftest-coverage.py` and 4 / 61 for the smoke workflow (control arm: a quiet governance file reads 1, a nonexistent path reads 0, so the probe discriminates). Every day it waits is a day of drift against a file changing ~4.6×/day. It also has a **complete in-repo template**, making it the lowest-design-risk card to land first |
| 2 | **#7440** | 4 | Sets the exit contract and resolves the mechanism question #7201's disposition depends on |
| 3 | **#7201** | 1 | Strictly after #7440's design decision. **AI-001 resolved to branch (b)** at the Stage-5 joint design pass — the chosen mechanism retains a red-with-annotation surface, so #7201 is **implemented** as the posture-leading prefix on the Arm F residual message, and graded on its own acceptance criteria |

The declared order was not *wrong* — `#7440 → #7201` is preserved. The change moves the free-floating card to the front, where its rebase cost is lowest, rather than to the back, where it is highest.

---

## Stage Applicability Matrix

| Stage | #7193 | #7440 | #7201 | Note |
|---|---|---|---|---|
| **5 Solutioning** | **APPLY** | **APPLY** | **APPLY — jointly with #7440, not independently** | Release Class `novel` sets Stage-5 activation bias **ALL**. #7440's card *itself* defers its mechanism to Stage 5, so activation there is self-declared rather than inferred. #7201's design question is not separable from #7440's — one joint pass covering both, whose output had to record #7201's disposition (AI-001). #7193 needed Stage 5 despite its strong template, because the **consumer re-wiring** is a genuine design call the template does not make for it |
| **6 Engineering** | APPLY | APPLY | APPLY | Serial, one branch |
| **7 Dev Testing** | APPLY | APPLY | APPLY | All three are functional changes; no skip is defensible |
| **8 QA / Acceptance** | APPLY | APPLY | APPLY | Per-criterion verdicts — #7193 carries 5 acceptance criteria, #7440 6, #7201 2 |
| **9 Plan Review** | release-scoped | release-scoped | release-scoped | Depth **Deep** per Release Class `novel` |
| **10–13** | APPLY | APPLY | APPLY | Standard |

**Nothing is skipped.** Stage 5 was the one place a skip was plausibly arguable (#7201 is one line) and it was explicitly **not** taken: the line's *content* was undetermined until #7440's mechanism was chosen, so skipping would have handed Engineering a card whose text nobody had decided.

**Parallel-eligible counts** (feeding the Quota Budget): Stage 5 → **2** (the joint #7440+#7201 pass, and #7193) · Stage 7 → **3** · Stage 8 → **3**. Stages 9 / 12 / 13 are release-scoped singletons.

---

## File Change Matrix

Machine-readable, one path per line, `<path>  <VERB>`. Intent markers normalize to the `add | edit | delete` enum.

```
# ── release-scoped (Engineering Commit 0) ──
release/releases/plans/expected-red-never-masks-regression_RELEASE_PLAN.md   add

# ── #7193 · Check 32 exit-space partition + its consumer (sequence position 1) ──
core/deploy/deploy.sh                                                        edit
.github/workflows/release-corpus-completeness.yml                            edit
core/standards/gate-efficacy-standard.md                                     edit
.github/release-corpus-completeness.enforce                                  edit

# ── #7440 · mode_reconcile finding-class ledger + exit space (position 2) ──
release/tools/check-selftest-coverage.py                                     edit
.github/workflows/release-tooling-smoke.yml                                  edit
core/standards/gate-efficacy-standard.md                                     edit

# ── #7201 · Arm F residual annotation posture prefix (position 3) ──
release/tools/check-selftest-coverage.py                                     edit
```

**8 declared path×card write obligations over 6 distinct paths**, plus the one `add` row for this plan file. `core/standards/gate-efficacy-standard.md` is written by two members on **disjoint rows** (#7193 → the Check-32 register row; #7440 → the `check-selftest-coverage` register row); `release/tools/check-selftest-coverage.py` is written by two members in the **same hunk** (§ Contention Map carries the ordering).

**Two rows were added after the card bodies were written, and both are recorded rather than absorbed.** `.github/workflows/release-corpus-completeness.yml` was added at **Stage 4** (Tier 1 [ADJUST]) — #7193's own fourth acceptance criterion requires editing the merge-blocking consumer, and the card's Affected Files omitted it. `.github/release-corpus-completeness.enforce` was added at **Stage 5**, same class of addition: its mode legend states the collapse this release removes and becomes factually false on the commit. Neither is scope creep; both are surfaces the card's own criteria already reach.

### Read-only inputs

```
.github/workflows/skill-package-freshness.yml                                READ
.github/workflows/decision-emission.yml                                      READ
```

Both are shipped consumers of a multi-code probe, read as the shape #7193's consumer copies. Neither is edited.

### Release-wide explicit non-scope

```
.github/workflows/behavioral-regression.yml                                  NOT EDITED
core/deploy/deploy.sh :: cmd_check Check 32 lifecycle arm (~L11742-11767)     NOT EDITED
core/deploy/deploy.sh :: cmd_check_required_subset (~L19181-19225)            NOT EDITED
core/standards/gate-efficacy-standard.md :: L286 (paths-roster invariant)     NOT EDITED
.github/workflows/release-corpus-completeness.yml :: L18 (job posture line)   NOT EDITED
core/standards/gate-efficacy-standard.md :: ## Flip-decision status           NO ROW AUTHORED
```

Each is asserted rather than assumed. The lifecycle arm reduces a verdict **string** and never sees an exit code, so `deploy.sh --check`'s aggregate PASS/FAIL total is invariant. Check 32 is **not** a member of the required-subset roster (which carries Checks 38, 73, 77 and 78), so the new codes cannot reach that runner's fail-closed arm. `behavioral-regression.yml` is a name collision its own header disclaims. L18 states the **job posture**, which this change does not alter — only the exit space moves. **No `## Flip-decision status` row is authored for Check 32**: none exists today, and creating one is an operator flip decision outside every card's criteria.

---

## Agent-Editability Read

**Derivation** — controls read at commit `343fbd20`, transcribed from Stage-4 Phase A3.5 and re-affirmed at Commit 0. Skill-gate legend: **`no ¹`** = conjunct 1 decided — the path does not match the sanctioned-session scope regex (it is not under any `<module>/skills/<name>/`), so conjuncts 2 and 3 are not reached and no conjunct reads `undetermined`.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class |
|---|---|---|---|---|
| release-scoped | `release/releases/plans/expected-red-never-masks-regression_RELEASE_PLAN.md` | no | `no ¹` | `unconstrained` |
| #7193 | `core/deploy/deploy.sh` | no | `no ¹` | `unconstrained` |
| #7193 | `.github/workflows/release-corpus-completeness.yml` | no | `no ¹` | `unconstrained` |
| #7193 | `.github/release-corpus-completeness.enforce` | no | `no ¹` | `unconstrained` |
| #7193 · #7440 | `core/standards/gate-efficacy-standard.md` | no | `no ¹` | `unconstrained` |
| #7440 · #7201 | `release/tools/check-selftest-coverage.py` | no | `no ¹` | `unconstrained` |
| #7440 | `.github/workflows/release-tooling-smoke.yml` | no | `no ¹` | `unconstrained` |

**Card class: `unconstrained` for all three. Execution path: ordinary Engineering spoke for every member.** The all-`unconstrained` result is authored rather than omitted, per the section's own rule — the discriminating negative is what makes the flag mean something when it does fire. **`unconstrained` means no control refuses the write; it does not mean the change is ungoverned.**

---

## Contention Map

| File | #7193 | #7440 | #7201 | #6114 (cross-ms) | #7404 (in-flight) |
|---|---|---|---|---|---|
| `core/deploy/deploy.sh` | **edit** — `_c32_compute_verdict` tail, `cmd_check_release_corpus`, the lifecycle falsification note, the dispatcher comment, the `--help` line, and self-test group RC | — | — | — | **edit** — single hunk at `cmd_check()` L9369 |
| `.github/workflows/release-corpus-completeness.yml` | **edit** — falsification header, two "warn swallows" copies, the Gate-decision step | — | — | — | — |
| `.github/release-corpus-completeness.enforce` | **edit** — comment-only mode legend | — | — | — | — |
| `core/standards/gate-efficacy-standard.md` | **edit** — the Check-32 register row's falsification cell | **edit** — the `check-selftest-coverage` register row's falsification cell | — | — | — |
| `release/tools/check-selftest-coverage.py` | — | **edit** — verdict vocabulary, `record()` ledger, Arm F split, docstring, `_selftest()` fixtures | **edit** — the residual-path message text, **same hunk as the Arm F split** | **edit** — Arm D | — |
| `.github/workflows/release-tooling-smoke.yml` | — | **edit** — producer/gate-decision pair, probe-2 assertions, Arm F posture paragraph | — | — | **edit** — path-filter rows + a step at ~L1102 |

**In-release contention:**

- **#7440 ∩ #7201 on `check-selftest-coverage.py` — HIGH, and tighter than the bundle recorded.** Both edit `mode_reconcile`; #7201's corrected target sits *inside* the same branch #7440 restructures, roughly fifteen lines from #7440's own edit. This is co-location, not adjacency, and it is the reason **P0 fully-serial is mandatory rather than preferred**. Mitigated entirely by the serial sequence on the shared branch.
- **#7193 ∩ #7440 on `gate-efficacy-standard.md` — LOW.** Different rows of one register (L272 vs. L276); a table-row conflict at worst, and P0 serial removes the collision mechanism.
- **#7193's four files — internal only, and the coupling is hard.** The `deploy.sh` mapping and the `release-corpus-completeness.yml` re-wiring **must land in the same commit**; see § Risk Register R2 and § Delivery Strategy.

**Cross-milestone (record, do not relocate):** #6114 ↔ #7440 is a **Tier-S serialization edge**, recorded on both cards. Whichever lands second re-expresses Arm D in the other's exit vocabulary — a semantic re-expression, not a textual merge.

---

## Risk Register

| ID | Risk | Sev | Reversibility | Mitigation |
|---|---|---|---|---|
| **R1** | **#7201 was specified against the wrong file.** An Engineering spoke following the card as written would have searched `release-tooling-smoke.yml` for an Arm F `::error::` that is not there | HIGH | CHEAP | **CLOSED at Stage 4** — Tier 1 [ADJUST] re-pointed the card to `release/tools/check-selftest-coverage.py` before Engineering |
| **R2** | **#7193's two halves cannot be split.** The consumer branches solely on `if [ "$RC" -eq 0 ]`, so the moment the mapping ships, `RC=2` — the **ordinary** outcome at the pin — sends the job to `exit 1` | HIGH | CHEAP | **Both halves in ONE commit.** Not a precaution: the live verdict at the pin is `INCOMPLETE — 4 230` exiting 0, and the workflow's PR paths filter includes `core/deploy/deploy.sh`, so a deploy.sh-only commit turns **this release's own PR red** before Stage 7 runs |
| **R3** | **#7193's severity premise is overstated.** *"A false clean here can admit a merge"* is not true today — the enforce sentinel reads `warn` and the gate is not among `main`'s 18 required contexts | MED | — | Re-framed as **latent, becoming live at flip**. This strengthens the case for fixing before the flip. Separately measured and **live today**: the gate publishes a green conclusion over `INCOMPLETE 4 230` — a different proposition, not a re-litigation |
| **R4** | **`core/deploy/deploy.sh` churn** — 65 commits/14d, 358 all-time; the hottest file in the release by ~16× | MED | CHEAP | Sequenced **first** per D-1. Re-baseline before Stage 12 |
| **R5** | **Sibling #7404 edits 2 of the 6 distinct files** | LOW | CHEAP | Regions verified non-overlapping. Re-check at Stage 9 Phase A6.6 — draft PRs move |
| **R6** | **#6114 semantic contention on the exit space** (not merely textual) | MED | CHEAP | Tier-S edge recorded on both cards |
| **R7** | **`main` has read red for 6 days on `selftest-discovery`** — 17 consecutive failures | MED | — | **Stage 7 / 8 spokes must be briefed that this red is baseline, not their regression.** The discriminator is specific: the *expected* red names only `.py` operands under `Arm F MANDATE REACHABILITY` and prints `ARM F POSTURE:`. Any Arm B / C / D / E / runner-partition line, or a non-`.py` operand under Arm F, is a genuine regression. This release exists to make that discrimination unnecessary |
| **R8** | **The fix re-creates the masking defect one level down** — #7440's own named trade-off | MED | MODERATE | Stage 5 stated, for each new exit member, which consumer reads it and what it does. **#7193's residual is stated honestly**: codes 2 and 3 land on separate `case` arms with separate reader-facing sections, separate annotations and separate remedies, but under `warn` both produce the same *job conclusion* — the discrimination is in the reported surface, not yet in the conclusion, and it becomes a conclusion-level difference for 0-vs-{2,3} immediately and for {2,3}-vs-1 at flip |
| **R9** | **Partial rollback strands consumers.** Reverting #7193's `deploy.sh` half without the workflow half (or vice versa) leaves the consumer branching on codes that no longer exist | MED | MODERATE | **Revert as a unit.** One PR, so `git revert -m 1` of the merge commit is the whole rollback. Never revert a single file from this release |
| **R10** | **The Stage-4 sub-task body's bound checklist over-enumerates** — it lists Phase `A3.1`, `A3.2`, `A3.6`, `A4.2`, `A6.5`, `A6.6` as Stage-4 steps; the canonical spec defines none of them as Stage-4 phases | LOW | CHEAP | Recorded N/A-with-reason in the Stage-4 attestation. A scaffolding-template fix, not a release change |
| **R11** | **A6.5's rejected justification could be transcribed into shipped code.** The Stage-5 design justified #7193's sensitivity arm by asserting the `DE-10c` precedent *"counts zero-producers with no arm proving the count can move"* — which is **false**: `deploy.sh:17560` asserts `_de_zero_producers -eq 2`, a *positive* expected count, so a dead predicate yields 0, `0 -eq 2` fails, and `DE-10c` **fails** | MED (record accuracy) | CHEAP | **CLOSED IN THIS RELEASE.** Operator disposition F2: keep the sensitivity arm, write the **corrected** reason — the vacuity is created by the new population arm's own inversion to `violations -eq 0`, where a dead predicate returns the *pass* value; the sensitivity arm closes exactly that hole. The false weakness about a shipped gate reaches neither code, comment, nor PR body |

**Rollback strategy:** single-PR release → revert the merge commit as one unit. Git history is the snapshot; no separate snapshot mechanism is needed. Reversibility **CHEAP** for #7440 / #7201, **MODERATE** for #7193 — see § Rollback Strategy for why the revert is not neutral.

---

## Delivery Strategy

- **One branch** — `release/expected-red-never-masks-regression`, cut from `main` at `343fbd20`. Slug-primary, no version stem (ADR-092).
- **One commit group per member**, in Implementation-Sequence order, message referencing the member's issue number. **Unsquashed at merge.**
- **One PR**, created in **draft** by the first Engineering spoke and transitioned to ready-for-review at the Stage-9 gate.
- **Serial spokes (P0)** — the next Engineering spoke starts only after the prior commit lands on the branch.
- **No force-push** on the shared branch, `--force-with-lease` included.
- **#7193's four files land in ONE commit**, and splitting it is not permitted. #7440's tool change and its `_selftest()` fixture updates likewise land together — the fixtures assert the new exit member, so a tool-only commit fails the job's first step and nothing else runs.
- **Deviations** route per the inter-stage feedback protocol: a minor adjustment commits with its rationale and a § Deviation Log row; a scope change is a Tier 2 `[SCOPE CHANGE]` to the operator; a plan rejection stops and returns upstream. **The Collective Review scope-lock is in force — a needed addition is a Tier 2 escalation, never a quiet inclusion.**

---

## Verification Plan

### Per-Issue Verification

`ac_baseline: { #7193: 5, #7440: 6, #7201: 2, total: 13, read_at: 343fbd20 }`

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #7193 | AC-1 — each verdict maps to a distinct exit code; no degraded or unmeasured verdict shares a code with `CLEAN` | Read the factored mapping function and drive it directly through all 8 `(verdict × sentinel)` pairs from `--self-test`, without invoking the probe | `CLEAN`/either → 0 · `INCOMPLETE`/warn → 2 · `INCOMPLETE`/enforce → 1 · `SKIP`/warn → 3 · `SKIP`/enforce → 1 · unrecognised/either → 1. Exactly **2** of the 8 pairs produce 0 and both are `CLEAN` |
| #7193 | AC-2 — a self-test asserts the mapping as a **population** property | The population predicate runs over the whole `(verdict × sentinel)` space in **both** directions — a non-`CLEAN` pair producing 0 is a violation, and a `CLEAN` pair *not* producing 0 is equally one — and returns a violation count | Violation count **0**, plus a companion assertion that exactly **2** pairs produce 0. A future verdict token added with no `case` arm lands on the catch-all → 1 and is caught here rather than silently joining the clean set |
| #7193 | AC-3 — the self-test carries a sensitivity arm that fires on a deliberately collapsed mapping | The **identical** population predicate is re-run against a mapping byte-identical to the real one except that `SKIP`/warn returns 0 — the exact pre-fix collapse. The predicate takes the mapping **by name**, which is what makes this possible without duplicating it | Violation count **≥ 1**. Failure message states plainly that a zero here means the predicate is broken and the population arm's zero proves nothing. **This arm is what makes AC-2's zero evidence rather than an artifact** |
| #7193 | AC-4 — the merge-blocking consumer branches on the new codes and re-encodes no predicate of its own | Read the diff for three properties: (i) the workflow never opens the `.enforce` sentinel — the probe stays its single reader; (ii) it never parses the verdict token out of the captured output; (iii) every arm is a literal integer the engine can produce, with a fail-closed catch-all | A four-arm `case` structurally identical to the shipped 4-code consumer at `skill-package-freshness.yml`. Mapping 2 and 3 to a non-failing job conclusion is **not** a policy decision the workflow makes: under `enforce` those codes cannot occur, because the engine already escalated them to 1 |
| #7193 | AC-5 — the falsification note is corrected so it no longer describes the collapse as designed | The identical sentence exists at **three** `falsification:` sites, not the one the card names, and a **fourth** file states the collapse in its mode legend. All four are rewritten to one text, adapted only to each site's comment prefix | Each site reads as an executable recipe naming the specificity case, and no site describes any collapse as intended. The `.enforce` edit touches **comment lines only**; the probe re-run afterwards still reports `token != enforce` |
| #7440 | AC-1..AC-6 | `[OWED — Stage 6 position 2]` — populated by the #7440 Engineering spoke from its own design's verification section, then re-executed at Stage 7 | `[OWED]` |
| #7201 | AC-1..AC-2 | `[OWED — Stage 6 position 3]` — populated by the #7201 Engineering spoke. **AI-001 resolved to branch (b)**, so this member is *implemented* and graded on its own criteria, not recorded satisfied-by-design | `[OWED]` |

**The two `[OWED]` rows are scaffolds with a named owner and a named filling moment, not blanks.** A member reaching Stage 7 with an empty row leaves both Stage 6 self-verification and Stage 7 re-execution grading against an empty artifact; each subsequent Engineering spoke fills its own row in its own commit.

### Release-Level Verification

| # | Check | Method | Expected |
|---|---|---|---|
| RV-1 | The `deploy.sh` self-test suite stays green | `bash core/deploy/deploy.sh --self-test`, run by each Engineering spoke after its own commit and re-run at Stage 7 | `EXIT=0`, zero anchored `FAIL` lines. **Baseline read at the pin: exit 0** — a loose `grep -c FAIL` returns 3 (arm-summary prose), so the anchored form is the one that discriminates and its zero is a measurement rather than a dead read |
| RV-2 | The corrected exit space is observable end-to-end | `bash core/deploy/deploy.sh --check-release-corpus` on the branch | Verdict `INCOMPLETE`, **exit 2** (was 0). The whole of #7193 in one integer |
| RV-3 | The enforce escalation works without editing the committed sentinel | Same probe with `RELEASE_CORPUS_ENFORCE_FILE` pointed at a scratch `enforce` sentinel | **exit 1** |
| RV-4 | The unmeasured state is distinguishable | `C32_LOG` at a nonexistent path | `SKIP`, **exit 3** under warn and **exit 1** with the enforce override |
| RV-5 | The deploy-time aggregate is invariant | `bash core/deploy/deploy.sh --check` — the Check 32 lifecycle arm reads the verdict **string**, never an exit code | Check 32's PASS/FAIL contribution unchanged. This is the no-regression control for #7193's engine edit |
| RV-6 | The sensitivity arm can actually be made to fail | Point the population predicate at the deliberately collapsed mapping and confirm the suite turns **red** | Suite red. **A self-test that cannot be made to fail has asserted nothing** |
| RV-7 | `check-selftest-coverage.py`'s own suite stays green | `python3 release/tools/check-selftest-coverage.py --self-test` after #7440 and after #7201 | `EXIT=0`. **Note R7: `main`'s `selftest-discovery` job has read red for 6 days on the Arm F residual — that red is baseline, not a regression introduced here** |
| RV-8 | Doc-link integrity over the changed corpus | `python3 core/deploy/tools/check-doc-links.py` over the Check-14 scan scope, and `python3 release/tools/check-release-links.py` on the changed delta | zero broken internal links |
| RV-9 | Plan-depth lint on this file | `python3 release/tools/check-release-links.py --plan-depth-lint` | **zero relative intra-repo links** — this file ships one directory deeper at the Stage-12 claim, so only the leading-`/` workspace-rooted form is correct at both depths |
| RV-10 | Plan structural conformance | `bash release/tools/verify-release-plan.sh release/releases/plans/expected-red-never-masks-regression_RELEASE_PLAN.md` | Commit-0 Survival Set rows 1–5 PASS; the always-on `fcm-delivery` and `provenance-survival` checks resolve |
| RV-11 | Skill-package freshness | `printf '%s\n' <changed-path> \| bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` (**STDIN, not argv** — an argv invocation returns empty for every input, which reads as *nothing to rebuild* while having measured nothing) | Expected **empty**: no path in the File Change Matrix lies under a rostered skill tree. The STDIN form is named because the empty result is only meaningful from the invocation that can be non-empty |
| RV-12 | ADR index freshness | This release adds **no** record under either ADR tree — Phase A5 returned *no ADR* on both Stage-5 passes, graded against all three authoring triggers | The honest no-op. Recorded so Stage 7's new-file-conditional scans are correctly skipped rather than silently absent |
| RV-13 | Parser-clean PR body | `grep -inE "(close\|closes\|closed\|fix\|fixes\|fixed\|resolve\|resolves\|resolved) +#?\[?[0-9]" <pr-body-file>` | zero matches outside the dedicated Issue References block |

---

## Cross-Issue Acceptance Criteria

Two declared. Both assert cohesion constraints that **no single card's own acceptance criteria grade**. Transcribed verbatim from the Stage-4 planning output on #7443.

- [ ] **CIAC-1 (#7440 × #7193 on the PV-7 exit-contract convention):** Every exit mapping this release authors or amends has **exactly one producer of the clean member**, and no degraded, expected-residual, or unmeasured verdict shares an exit member with the clean verdict. Each amended tool's own `--self-test` asserts this as a **population** property over all verdict-by-sentinel pairs and carries a sensitivity arm that fires on a deliberately collapsed mapping. *Shared surface:* the exit-contract convention whose in-repo authoring home is `cmd_check_package_freshness` (FRESH 0 / advisory 2 / not-evaluated 3 / blocking 1) as extended by `cmd_check_decision_emission`, both in `core/deploy/deploy.sh`. *Method:* `python3 release/tools/check-selftest-coverage.py --self-test` and `bash core/deploy/deploy.sh --check-release-corpus` each exercised across their verdict set, asserting exit 0 is reached only from the clean verdict; **control arm** — re-run each self-test against a deliberately collapsed mapping and observe a non-zero, non-passing result, so the pass is not the artifact of an assertion that never evaluated. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#7440 × #7201 on `release/tools/check-selftest-coverage.py` `mode_reconcile`):** The reader-facing annotation surface and the process exit code **agree about which state occurred**. On a residual-only run the pair (annotation text, exit code) must not describe an expected residual in one channel while signalling a regression in the other; and where #7440's chosen mechanism already makes the job conclusion discriminating, #7201 is recorded **satisfied-by-design** against #7440 AC4 with that evidence cited, rather than left silently unimplemented. *Shared surface:* the Arm F branch of `mode_reconcile` — the `err()` call at ~L1035 and the `return 1 if failed else 0` at ~L1065. *Method:* run `--reconcile` against a residual-only tree, capture both the annotation stream and `$?`, and assert agreement; **control arm** — inject the Arm B regression #7440 AC2 already specifies (manifest path on disk, `--self-test` dispatch removed) and observe a **different** (annotation, exit) pair, so agreement is not trivially satisfied by a channel that never varies. *Graded at Stage 9 QC3.5 on the merged PR.*

**CIAC-2's conditional limb is now decided, and the decision does not amend the criterion.** AI-001 resolved to **branch (b)** at the Stage-5 joint design pass: the chosen mechanism retains a red-with-annotation surface, so #7201 is **implemented** rather than recorded satisfied-by-design. The criterion is transcribed verbatim because that is what it says; the resolved branch is recorded here and in § Operator Decisions so a Stage-9 grader reads the criterion against the branch actually taken.

**Deliberately not a CIAC.** A third criterion spanning all three cards on the Release Outcome Statement was considered and rejected: CIAC-1 already binds the two cards that author exit spaces, and adding #7201 to it would be padding rather than a constraint.

---

## Quota Budget

**Verdict: PASS** (Checkpoint A).

| Field | Value |
|---|---|
| Parallel-eligible spokes per parallel stage | Stage 5: **2** · Stage 7: **3** · Stage 8: **3** |
| Per-spoke cost estimate | ~5% of a 5-hour usage window (heuristic band; **source: heuristic, not telemetry medians** — no finops median was read) |
| Remaining envelope | not operator-stated at hub start; conservative default of a full window assumed |
| Worst parallel batch | 3 concurrent spokes → ~**15%** cumulative draw |
| Routing | **PASS — proceed.** The pathological shape for this envelope is a wide fan-out (order 16 concurrent); a 3-card release cannot reach it |

This is a one-time plan-time estimate and is **not** the load-bearing gate. Checkpoint B re-validates at every spoke launch — wave or singleton — and additionally gates on the host-API quota axis Checkpoint A deliberately does not read. Bands are `[CALIBRATE-AFTER-3]` MEDIUM confidence.

---

## Release Class declaration

**`novel` — RE-CLASSIFIED from `routine`** at the Stage-4 Plan Approval gate as operator decision **D-ReleaseClass**. Trigger evidence, derived rather than inherited:

| Trigger | Fires? | Evidence |
|---|---|---|
| routine (a) all issues P3/P4 + `size:S`/`M` | **no** | #7440 is P2; #7201 is `size:XS`, outside the S/M band |
| routine (b) all change-spec files have ≥3 prior release touches | **no** | `.github/workflows/release-corpus-completeness.yml` has **2** prior touches, below the ≥3 floor. The other files clear it easily (358 / 92 / 61 / 7); control arm: a nonexistent path reads 0 |
| routine (c) zero new files added | **YES** | Exactly one `add` row — this plan file. No member adds a file |
| routine (d) zero new D-class decisions | **no** | See `novel` (b) |
| **novel (b) ≥1 D-class decision in the release plan** | **YES — the dominant trigger** | #7440's own body defers its remediation mechanism to Stage 5 with a named trade-off: *"the trade-off between maintenance burden and re-creating the masking defect one level down is a design call this item deliberately does not make."* That is a release-specific design fork, deferred to a named owner, to be recorded in the plan. The recurring rule-determined D-decisions (D-Version, D-C Topology, D-Concurrency) are **deliberately excluded** from this count — including them would fire `novel` (b) on every release and empty the `routine` class entirely |
| novel (a) new reference doc / schema / skill | **no** | none added |
| novel (c) an ADR authored by a member that reached Stage 5 | **no** | Phase A5 returned *no ADR* on both Stage-5 passes, graded against all three authoring triggers |
| cross-cutting (a) ≥3 `pipeline/stage-*.md` | **no** | 0 |
| cross-cutting (b) ≥3 of the 6 rule-defining surfaces | **no** | 1 (`core/standards/gate-efficacy-standard.md`) |
| cross-cutting (c) ≥3 in-bundle edges | **no** | 2 |

**Multi-trigger resolution is `cross-cutting` > `novel` > `routine`.** Both `novel` (b) and `routine` (c) fire; `novel` is dominant. **The operator declined the offered off-ramp** — ratifying #7440's mechanism as a template application of the existing exit-contract convention, which would have collapsed the D-class decision to rule-determined and left `routine` standing on (c). Declining it was an explicit call, not an omission.

**Differentiation posture (`novel`):** engagement density **Standard** (per-D-decision Operator Decision Gate + per-Stage-5 Decision Briefing) · Stage 9 Plan Review depth **Deep** (Collective Review N-way consistency + cross-D upstream-compatibility scan + blast-radius assessment) · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

`effective_pts: raw 9 × 1.15 = 10 — BELOW band vs band 15-25`. The class change carries no size-bound consequence.

---

## Operator Decisions

| ID | Decision | Rendered | Reversibility |
|---|---|---|---|
| **D-1** | **Release plan APPROVED as briefed**, committing three departures from the milestone as originally written: the re-ordered implementation sequence `#7193 → #7440 → #7201`; #7201 stays a **separate** card (SPLIT) governed by AI-001; and the Scope table corrected to 9 pts with two primary-file cells repaired | Stage-4 gate, 2026-09-12 | MODERATE / HIGH |
| **D-ReleaseClass** | **RECLASSIFY `routine` → `novel`**; off-ramp declined | Stage-4 gate, 2026-09-12 | CHEAP / HIGH |
| **D-Version** | **`v4.64`** — recorded determination, rule-determined, binds at the Stage-12 atomic claim | Stage-4, re-verified at Commit 0 | — |
| **D-Concurrency** | **P0 fully-serial**; force-push prohibited on the shared branch | Stage-4 | — |
| **D-CollectiveReview** | **Scope-lock HOLDS. All three A6.5 findings folded into Stage 6.** No re-design, no scope change, no premise rejection | Stage-5 Collective Review, 2026-09-12 | MODERATE / HIGH |

**Action items.**

- **AI-001 — RESOLVED.** #7440's Stage-5 output was required to record #7201's disposition on exactly one branch. It recorded **branch (b)**: the chosen mechanism retains a red-with-annotation surface, so #7201 is **implemented** as the posture-leading prefix on the Arm F residual message and graded on its own criteria. A6.5 did not overturn the reasoning.
- **AI-002 — OPEN.** A6.5 Findings **F1** and **F3** are covered by **no acceptance criterion on any card** — they originated in adversarial review rather than in intake, so nothing downstream grades them without a ledger row. Verified at Stage 8 QA acceptance for #7440. **HARD gate before Milestone close.**

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|-------|----------------|-----------|
| #7193 | `git revert` of the member's commit group — **as a unit, never a single file** | Low mechanically; see the note below on why the outcome is not neutral |
| #7440 · #7201 | `git revert` of the member's commit group | Low — each is local to a named region in one tracked file, and #7201's revert is a message-text restoration |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated member failure | Revert that member's commit group on a fix branch |
| **Full Restore** | Systemic failure | `git revert -m 1 <merge-sha>` — the merge commit is two-parent by construction. **The version tag is NOT deleted**: `refs/tags/v*` is host-protected, and the tag remains as the record that the version was claimed and then withdrawn |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch off `main` |

**Reversibility MODERATE, and the operator should see why it is not CHEAP.** Reverting restores two gates that publish a non-failing conclusion over degraded or unmeasured state. That is the pre-existing condition rather than a new fault — but the revert is **not neutral**: it re-arms the false-green. Confidence **HIGH**.

**One coupling sits outside the per-file guarantee and is called out rather than implied.** #7193's engine change and its consumer re-wiring are a matched pair. Reverting one without the other leaves the workflow branching on codes the engine no longer produces, or the engine producing codes the workflow sends to a failing conclusion. **Revert #7193 as a unit or not at all.**

---

## Operational Deployment Manifest

**No propagation target exists in this release.** Enumerated over the four classes `./deploy.sh --deploy` carries, against the declared File Change Matrix: **0** paths under any `skills/` tree · **0** under `packages/` · **0** under `core/rules/` · **0** under `core/hooks/`. `core/deploy/deploy.sh` is the deploy engine itself rather than a deployed artifact; `release/tools/check-selftest-coverage.py` is neither a rostered skill nor a distribution package. Both owe **zero** S-2 copy and **zero** `.skill` rebuild — inapplicable by construction, not deferred. Confirmed against the merged diff at Stage 12.

### Schema Migrations

**N/A** — enumerated over the classes a migration could take (data-format change on a persisted store, frontmatter schema field addition or removal, config-file key rename, registry re-keying). None is present. Both members change the **exit vocabulary** of an existing probe without changing any persisted record, any file format, or any key set. The `.enforce` sentinel's **token line is untouched**; only its comment legend changes.

---

## Deviation Log

| # | Deviation from the Stage-4 / Stage-5 transcription source | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **The Stage-5 design's justification for #7193's sensitivity arm is factually wrong.** It asserted that the `DE-10c` precedent *"counts zero-producers with no arm proving the count can move"*. `deploy.sh:17560` asserts `_de_zero_producers -eq 2` — a **positive** expected count — so a dead predicate yields 0, `0 -eq 2` fails, and `DE-10c` **fails**. It was never vulnerable in the way described | Phase A6.5 finding **F2**; hub-verified against source; ratified in the Collective Review scope-lock as binding on this sub-task | **CORRECTED AT COMMIT 0 AND CARRIED INTO THE CODE.** The arm is **kept** — it is necessary — and its reason is inverted to the true one: the new population arm inverts the precedent's polarity to a zero-is-pass assertion (`violations -eq 0`), where a dead predicate returns the *pass* value, and the sensitivity arm is what closes exactly that hole. **The false weakness about a shipped gate is written into neither code, comment, nor PR body.** The hub's follow-on question is answered too: #7440 does not inherit the weakness — its own population arm asserts a positive count and carries an explicit sensitivity arm |
| **DEV-2** | **#7193's Affected Files omitted the merge-blocking consumer its own fourth criterion requires editing** | Stage-4 Tier 1 [ADJUST] | **APPLIED BEFORE ENGINEERING.** `.github/workflows/release-corpus-completeness.yml` added to the matrix. Both halves land in one commit |
| **DEV-3** | **#7193's severity framing was aspirational.** *"A false clean here can admit a merge"* is not true today | Stage-4 Tier 1 [ADJUST] | **RECONCILED to latent-rather-than-live**, with the body left as historical record. A public issue edit does not scrub its history, and the design is built against current state |
| **DEV-4** | **The falsification note is a three-site cascade, and a fourth file states the collapse too.** The card's Documentation Impact says *"the gate's falsification note"* — singular | Stage-5 Phase 0.5 substrate-drift finding, class C2 | **DESIGN COVERS ALL FOUR.** `.github/release-corpus-completeness.enforce` added to Affected Files at Stage 5, the same class of addition Stage 4 made for the workflow |
| **DEV-5** | **#7193's Affected Files says "the register/**flip** rows" of `gate-efficacy-standard.md`, plural.** Exactly **one** row has the gate as its subject; there is **no** Check-32 row in the flip-decision section | Stage-5 Phase 0.5, class C2 | **DESIGN AGAINST CURRENT STATE: edit the register row only.** No flip-decision row is authored — a flip decision is an operator call and outside this card's criteria. Body left unamended |
| **DEV-6** | **#7201's Affected Files named the wrong file entirely** | Stage-4 Tier 1 [ADJUST] | **RE-POINTED BEFORE ENGINEERING** to `release/tools/check-selftest-coverage.py`, with Documentation Impact and Proposed Change reconciled to match |
| **DEV-7** | **#7193's SKIP is sentinel-AWARE — a deliberate departure from the nearest sibling precedent** (Check 61's SKIP is sentinel-agnostic) | Stage-5 design decision, grounded on a measured premise | **RATIFIED.** Check 61's agnosticism rests on its not-evaluated state being *structurally unreachable to fix in CI*. That premise is **false for Check 32**: its verdict input is a **tracked** file, present and parseable on every CI checkout, so a CI `SKIP` means the PR deleted or broke the ledger — which the PR author can fix in the PR. Importing the sibling's remedy would ship a gate that goes quiet the instant its ledger is deleted. **Bound worth recording:** the argument's strength is a property of *this workflow's checkout configuration* (full `actions/checkout`, no sparse-checkout, no filter), not merely of the file being tracked |

---

## Verification Evidence

`[OWED]` — populated as each stage produces observed results. Per-member acceptance is transcribed here from each member's own Stage-7 Dev Testing and Stage-8 Acceptance Review sub-task reports; **no figure is re-derived in this section and no suite is re-run in order to write it.** Where a check cannot be observed until merge or until the PR is non-draft, that is stated rather than filled.

---

## Change Description

(Authored by the Stage-6 Engineering spoke at PR-creation time per the release protocol's Change Description Protocol, once the last card lands. Operator-facing, pre-merge, six sub-sections. Distinct from the user-facing release note authored at Stage 13 Close.)

---

## Baseline pin

`origin/main` @ **`343fbd20`** (`343fbd2046d48fe26ca34bb6e83a0a4a1d73f3eb`), measured 2026-09-12T18:03:44Z at Stage-4 Planning and **confirmed unmoved at Engineering Commit 0** on 2026-09-12 — the Stage-4 pin and the Commit-0 base are the same commit. Every population count in this plan is measured against this pin. Read by the Stage-9 mid-pipeline divergence re-check.

---

## Issue References

<!-- repo-integrity: allow-issue-ref — limb 1: a release plan's member enumeration IS its subject matter; the numbers are the release's own scope, not prose citations, and relocating them would delete the plan's scope statement -->

Every member of this milestone is transitioned to closed at Stage 13, by the Stage-13 close-out on the merged PR rather than by an auto-close keyword in the PR body. The members are #7193, #7440 and #7201.

- **#7193** — Check 32 collapses `CLEAN`, `INCOMPLETE` and `SKIP` onto exit 0, so an unmeasured state is indistinguishable from a clean one in a merge-blocking gate.
- **#7440** — `mode_reconcile`'s eight assertion sites share one non-zero exit member, so an expected residual and a genuine regression reach the reader as the same signal.
- **#7201** — the Arm F annotation does not carry the posture marker, so the discriminating information exists only in the runtime log.
