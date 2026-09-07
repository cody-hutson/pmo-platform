---
title: Release Plan — closeout-correctness-batch (seven correctness defects across the two release close-out tools)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: closeout-correctness-batch
release_class: routine
reversibility: CHEAP / Confidence HIGH — every member is a bounded edit to a tracked file, no member adds a file outside `release/releases/plans/`, and `git revert -m 1` of the merge restores `main` byte-for-byte. Commit-per-issue on the single branch preserves per-member revertability without a whole-release revert.
---
# Release Plan — `closeout-correctness-batch`

**Milestone:** `closeout-correctness-batch` (milestone #389) · hub sub-task **#7216** = the Stage-4 plan source and two **Decision Recorded** comments · **#7217** = card #5649's Stage-5 design source, its Phase A6.5 adversarial review, and the wave-1 decision record · **#7242** = the release-wide scope-lock record carrying the binding corrections · **#7218** = the Stage-6 Engineering sub-task that authored this file at Engineering Commit 0.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete `vX.Y` binds only at the Stage-12 atomic claim per ADR-092, so the branch and this file stay slug-primary while in flight and the Header **Version** cell carries the unresolved stamp token. The Commit-0 version re-verify ran in full — see § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch (`release/closeout-correctness-batch`), one PR, one merge, base `main`. This plan file lands as **Engineering Commit 0**.

**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch; the next spoke waits until the prior commit lands. Six of seven members write one file, so serialization is the desired behaviour rather than a cost. Every non-serial posture prohibits force-push (including `--force-with-lease`) on a shared release branch; P0 is in force, so the prohibition is moot here and is recorded for completeness.

**Release class:** `routine` — **CONFIRMED** at the Stage-4 gate. Differentiation posture: engagement density **Light** · Stage 9 review depth **Standard** · Stage 5 activation bias **SKIP-where-trivial**, *recorded as declared and explicitly not applied* (Stage-4 Phase A0 found genuine design uncertainty on four members) · Stage 13 outcome-window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7216 together with both **Decision Recorded** comments there, reconciles it to card #5649's Stage-5 design on #7217, and applies the **binding corrections** ratified at the Collective Review scope-lock on #7242. Where a later disposition supersedes a Stage-4 or Stage-5 value, the transcribed section carries the **ratified** value and § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #7218, card #5649).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination, declared at Bundle as intent-to-bump. It sets the floor and binds no concrete number. The Stage-4 recorded determination was **v4.61** (anchor `v4.60` + minor bump), provisional; the Commit-0 re-verify recomputed the same value against fresh authoritative host state, with the **tag arm binding** and the other three arms corroborating. See § Commit-0 Version Re-Verify Record. |
| **Date Created** | 2026-09-07 (Monday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/closeout-correctness-batch` |
| **PR** | (populated at Stage 6 Phase C once the last card lands — this release ships as a SINGLE PR) |
| **Milestone** | `closeout-correctness-batch` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-07, domain: governance }`

**Domain classification.** Form **X** (sourcing-exempt): the File Change Matrix is entirely internal `pmo-platform` artifacts — two `release/tools/` shell tools, one `core/standards/`, one `core/rules/`, one `release/references/how-to/`, and two `release/references/pipeline/` specs — so no external body of practice is consumed and no Form-A citation exists to record. Dominant domain **`governance`** (5 of 7 source paths are governance / pipeline / standards documents); secondary domain **`software`** (the two shell tools). Dominant is recorded in the label, secondary noted here, per the A3-time classification rule. Transcribed unchanged from Stage-4 Phase A1.5.

---

## Commit-0 Version Re-Verify Record

The first Engineering spoke under SINGLE topology re-runs the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1** — refresh authoritative host state | **EXECUTED.** `origin/main` = `a30838589583bcddf5f88183cfff1a8ea2475300`. The Stage-4 baseline pin was `a3083858`; **the substrate did not move between Planning and Engineering** — the plan's pin and the Commit-0 base are the same commit. `99b331e8` re-confirmed an **ancestor** of the baseline by **543** commits, so no rebase step exists. | `git fetch --tags origin` · `git fetch origin main` · `git rev-parse origin/main` · `git merge-base --is-ancestor 99b331e8 a3083858` (true) · `git rev-list --count 99b331e8..a3083858` → 543 |
| **2** — recompute next-free for bump-class `minor` | **EXECUTED. Next-free = `v4.61`.** `anchor()` = **v4.60**, the highest claimed `vX.Y` across the claimed-set arms. `FLOOR(minor)` = `(4, 61)`; `v4.61` is absent from `claimed_set()`, so the walk terminates at the floor. | Four independently-read arms. **Tag arm (BINDING)** — `git ls-remote --tags origin 'refs/tags/v*'`, 406 ref lines resolving to **199** distinct `vX.Y` names, max `v4.60`, `v4.61` × **0**. **Published Releases** — `gh release list --limit 400`, 202 rows, `v4.61` × 0. **Ledger at the remote tip** — `git show origin/main:release/releases/RELEASE_LOG.md`, 2,390 lines, `v4.61` rows × 0. **Plans directory** — `release/releases/plans/v4/` max `v4.60_RELEASE_PLAN.md`, no `v4.61` file. |
| **3** — PROCEED / HALT on claimed-set membership | **PROCEED.** `v4.61` is **not** in the claimed set **and** equals the recomputed next-free — the conjunction the gate requires. **The verdict rests on the tag arm alone**, per the precedence rule: any arm showing the version claimed may raise HALT, but PROCEED rests on the tag arm reading it free, and a missing ledger row is not evidence of freeness. The other three arms corroborate and did not authorize. | Sensitivity arm — the identical readers resolve **`v4.60` as present** on every arm (tag × 1, Releases × 1, ledger × 9 rows, plans dir × 1), so membership detection demonstrably fires. Specificity arm — the fabricated `v4.9999` returns **0** on every arm over those same non-empty inputs, and `v4.62` returns 0 on the tag arm. |
| **3b** — stamp-manifest assertion | **EXECUTED post-write, pre-commit.** `release/tools/claim-version.sh --verify-stamp closeout-correctness-batch` → **exit 0** (`verify-stamp OK`). | Read-only and network-free — the identical pre-flight the Stage-12 atomic claim runs before its compare-and-swap. The Header **Version** cell carries the literal unresolved `{{RELEASE_VERSION}}` token and no other text, which is what the Stage-12 claim resolves and renames on. The manifest is plan-only (no `--stamp-file` entries), so a zero package consequence is correct and announced rather than an error. |

**Why the number is recorded but not bound.** Step 2's `v4.61` is a Commit-0 *reading* of authoritative state, not a claim. Nothing is held between now and the merge; a concurrent release that merges first takes `v4.61` and this release's claim recomputes upward at the compare-and-swap. Recording the reading makes the Commit-0 PROCEED reproducible without asserting a reservation the allocation rule does not create. **The numbers in this section are deliberately not restamped later** — they are a reading at a named SHA, reproducible by re-running the recorded commands at that SHA.

**`${AUDIT_DATE_UTC}`: NOT DECLARED.** The File Change Matrix creates no downstream load-bearing `YYYY-MM-DD` identifier — no audit-folder path, no ADR (Phase A5 is N/A on every member that reached Stage 5 with a design), no dated verifier id. No literal date appears in a load-bearing position in any member's change. Local civil date and UTC date agree at authoring time (both 2026-09-07, Monday), so no divergence needs naming.

---

## Scope

### Issues Included

Seven members. `issues_added` = **0** since the composition lock; the lock is in force and the Collective Review scope-lock (#7242) hardened it — additions are FORBIDDEN and removals require a governed override.

| # | Issue | Title (abbreviated) | Priority | Size | Category |
|---|-------|------|----------|------|----------|
| 1 | #5649 | `automated-closeout.sh` exits 1 with no output when `operator.toml` omits an optional key | P3 | S | bug |
| 2 | #5762 | The exit-code comment describes a condition the code does not gate | P3 | XS | bug |
| 3 | #6204 | Release-title composition has no owning stage; the edit path passes no `--title` | P3 | M | bug |
| 4 | #6841 | A non-enum action-item status passes the gate silently instead of failing loudly | P2 | M | bug |
| 5 | #6255 | `phase_await_merge_chore_pr` has no terminal-success arm for an already-merged PR | P3 | S | bug |
| 6 | #6411 | A lock-held worktree classifies REMOVE, and the failure line names the wrong cause | P2 | M | bug |
| 7 | #6207 | The dry-run report projects branches its own worktree removals free | P3 | S | bug |

**Coherent by surface, not by cause.** All seven are correctness defects in the two release close-out tools. They share no root cause; what they share is that a reader of either tool's output cannot currently distinguish a correct run from a defective one.

### Exclusions

None. No member was excluded, split out, or merged. Two merge candidates were examined at Stage 4 and both rejected on stated grounds — `#6411` + `#6207` (same file, one build-order edge: sequencing captures the coupling, merging would discard two independently-graded AC sets and make a partial revert impossible) and `#5649` + `#5762` (both tiny and both in one file, but sharing no surface, mechanism or verification arm). The exclusion class was enumerated over the seven members; none is adopted.

### Dependency Graph

**Native GitHub edges: 0 across all 7 members.** **This zero is UNARMED and is reported as such, not as a measurement.** The same reader returned 0 on epic `#5869`, a known-parent issue, so there is no known-positive case in this repository to arm it against — a broken reader and an empty population are indistinguishable on this instrument. Two independent sources corroborate: the `sub_issues` reader on the same API family *is* live (28 children on `#5869`), and the milestone's own Stage-3 record independently states zero native edges. Re-checked at Stage 9 Phase A6.5 with a differently-shaped read.

**Derived (build-order) edges — 1, and it is real:**

```
#6411 ──build-order──▶ #6207        (release/tools/cleanup-orphan-state.sh)
```

`#6411` changes **which worktrees classify REMOVE** — a lock-held worktree becomes `SKIP — live session`. `#6207`'s fix must project *branches freed by the same run's worktree removals*, so its projection consumes the classifier's output set. Landing `#6207` first would write its projection and its new fixture against a classifier `#6411` then changes. The edge is **build-blocking, not ship-gating** — both ship in one PR.

No other member constrains another. The graph is a single 2-node chain plus 5 isolates, so a cycle is impossible by construction rather than by search.

#### Cross-Milestone Dependency Validation

**A Tier-S serialization edge exists and is recorded rather than left implicit.** Sibling milestone `closeout-verification-rows-consistent` (ms#395, 7 open members, created by this batch's own split) intersects this release on three files — `release/tools/automated-closeout.sh`, `release/references/pipeline/stage-13-close.md`, and `release/references/how-to/hub-spoke-bridge.md`. It has no branch and no PR, so the in-flight roster is empty; it is a **planned** sibling. Whichever milestone merges first, the other re-baselines. The formal predicate `EDITSET(sibling) ∩ SURFACE(R)` is **UNRESOLVABLE as specified** — ms#395 has no Stage-4 plan and therefore no File Change Matrix to intersect — so the intersection above is derived from its members' own Affected Files sections and is a **predicted** intersection, labelled as such: an unknown, not an absence. Three of its members name none of these paths in a matched form, so the intersection may be wider than three members, not narrower.

### In-Flight Release Roster

`none in flight at a3083858` — population **n = 0**. Measured, not assumed: 0 open PRs repo-wide with a `release/*` or `chore/*` head (drafts included), and 0 remote `release/*` / `chore/*` heads. Both readers armed on the same instrument — the PR reader returns 5 on `--state merged`, and the remote-heads reader returns a populated set with no filter. Re-checked before every wave rather than carried from here, per audit-baseline discipline.

### Bundle Refresh State

Refresh outcome path (2) `amend`, with **`issues_added` = 0** — no card entered or left. Applied at the Stage-4 routing point: 6 phantom rows removed (they belong to ms#395), 3 missing members attached, arithmetic reconciled 20/20 → 19/19, internal sequence and Notes re-derived, and the epic-parentage claim corrected to the one member it is true of (`#5762`).

---

## Implementation Sequence

Serial, on one branch, one commit group per member, unsquashed. The order below **supersedes** the milestone description's declared internal sequence in its first two positions; the amendment was routed Tier 1 [ADJUST] at Stage 4 and is carried here as ratified.

| # | Issue | Size | Primary write region | Why here |
|---|-------|------|---|---|
| 1 | #5649 | S | `release/tools/automated-closeout.sh:386-393` | **Load-time abort.** `:388`/`:389` run before argument parsing, so they abort **every** invocation including `--self-test` and `--check-paths` on any host whose `operator.toml` omits either key. That makes this a prerequisite for every other member's verification arm. Cheapest fix in the batch, largest de-risking effect. |
| 2 | #5762 | XS | `release/tools/automated-closeout.sh:207-211` | One comment line, **inside the roster/header block `:17-:211`** that later members also touch. Landing it first means #6204 and #6255 build onto a corrected enumeration rather than the reverse. |
| 3 | #6204 | M | `:6401-6601` + `:6925-7001` | Largest region. Take it while the branch is shallow. |
| 4 | #6841 | M | `:5796-5813` + `:5875-5968` + two sibling copies | Three-file cascade; wants a clean base under it. |
| 5 | #6255 | S | `:5496-5553` | Adds self-test arms adjacent to the group-PS block at `:11573-11753`. |
| 6 | #6411 | M | `release/tools/cleanup-orphan-state.sh` liveness predicate `:483` + message `:1359` | First of the second file; upstream of #6207 per the build-order edge. |
| 7 | #6207 | S | `cleanup-orphan-state.sh:630` / `:1740` / `:1752` / `:1790` + `automated-closeout.sh:7020` | Consumes #6411's classifier output. |

### Issue #5649 — the load-time abort (sequence position 1)

Four commit groups, in this order.

1. **Engineering Commit 0 — this plan file.** Authored and committed before any source edit, carrying the nine-element Commit-0 Survival Set. Preceded by the version re-verify (steps 1–3) and followed by the stamp-manifest assertion (step 3b) before the commit.
2. **The guard fold at `:388`/`:389`.** At each site: insert `-m1`, delete `| /usr/bin/head -1`, append `|| true` inside the substitution. The resulting lines differ from the shipped sibling at `:525` only in variable name and key name. Add a 2–3 line comment above `:388` **pointing at** the canonical rationale block at `:307-319` without restating it, matching that block's own convention. **Do not touch `:320` or `:525`** — both are already correct.
3. **Group `TK` — the class-level source arms**, appended inside `self_test()`, plus one net-new conformant-arm extraction line appended to the terminal echo block. **Whole-file scan** per the binding correction — see § Deviation Log DEV-1.
4. **The D-Sibling-Fold** in `release/tools/cleanup-orphan-state.sh` — `|| true` **only** at `:148`, `:160`, `:161` — plus its own class arm in that file's `self_test()`. See § Deviation Log DEV-2 and DEV-3.

### Issues #5762 · #6204 · #6841 · #6255 · #6411 · #6207

Each member's commit group is authored by its own Engineering spoke from its own Stage-5 design and the binding corrections on #7242, in the sequence order above. Each spoke populates its own rows in § Verification Plan — those rows are a Commit-0 Survival Set element that Stage-6 C4 self-verification and Stage-7 re-execution both consume, so a spoke that leaves its rows empty leaves both stages grading against an empty artifact.

**Do-not-touch list for the six members that follow #5649:** `automated-closeout.sh:320` and `:525` (already-correct guards), and every existing arm inside `self_test()`. Position 1 **appends** to `self_test()` and to the terminal echo block; it rewrites no shared block and adds no phase, so the hand-maintained `usage()`/`--help` phase roster and its four row-asserting arms are untouched by this card.

---

## Stage Applicability Matrix

| Card | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9–S13 | Stage-5 rationale |
|---|---|---|---|---|---|---|
| #5649 | **APPLY** | APPLY | APPLY | APPLY | APPLY | *No trigger of its own* (T1–T7 all `✗`) — activated because Stage-5 activation is all-or-nothing per release. The pass was kept short and no design uncertainty was manufactured. |
| #5762 | **APPLY** | APPLY | APPLY | APPLY | APPLY | *No trigger of its own.* Same all-or-nothing activation. Its one comment line is asserted by the same `--help` / roster arms four self-test checks read, so it carries a real regression surface despite being a comment. |
| #6204 | **APPLY** | APPLY | APPLY | APPLY | APPLY | T3 + T4 + T6 — stage-ownership of title composition constrains two stage specs; the AC states two alternatives; the Stage-12-posts-before-Stage-13-authors ordering may not resolve without moving the emit anchor. |
| #6841 | **APPLY** | APPLY | APPLY | APPLY | APPLY | T3 + T4 + T6 — the alias table's verdict-neutrality claim is a semantic contract; case-folding vs. an explicit alias map; cascade width was wrong on the card (2 named, 3 real). |
| #6255 | **APPLY** | APPLY | APPLY | APPLY | APPLY | Trigger met by letter only (one added `--json` field vs. a separate probe). Activated by the all-or-nothing rule. |
| #6411 | **APPLY** | APPLY | APPLY | APPLY | APPLY | T3 + T4 + T6 — the fail-closed limb's contract changes; three candidate liveness predicates; the distinguishable-failure-line requirement needs the refusal shapes enumerated. |
| #6207 | **APPLY** | APPLY | APPLY | APPLY | APPLY | T3 + T4 — what a dry-run *means* is a contract an operator approval is granted against; projection pass vs. inline prediction. |

**Release-level Stage-5 verdict: ACTIVATE.** T3/T4/T6 fire on four members; activation is codified all-or-nothing per release, so all seven received a Stage-5 chip. **No stage is skipped for any member** — every member has functional impact, including #5762.

**Parallel-eligible counts** (feeding the Quota Budget): Stage 5 → **7** · Stage 7 → **7** · Stage 8 → **7**. Stages 9 / 12 / 13 are release-scoped singletons and apply once.

---

## File Change Matrix

Machine-readable, one path per line, `<path>  <VERB>` (path-first columnar-in-fence form). Intent markers normalize to the `add | edit | delete` enum.

```
# ── release-scoped (Engineering Commit 0) ──
release/releases/plans/closeout-correctness-batch_RELEASE_PLAN.md          add

# ── #5649 · load-time abort on an absent optional key (sequence position 1) ──
release/tools/automated-closeout.sh                                       edit
release/tools/cleanup-orphan-state.sh                                     edit

# ── #5762 · exit-code comment describes an un-implemented gate (position 2) ──
release/tools/automated-closeout.sh                                       edit

# ── #6204 · Release-title composition ownership + the edit path (position 3) ──
release/tools/automated-closeout.sh                                       edit
release/references/pipeline/stage-13-close.md                             edit

# ── #6841 · non-enum action-item status must fail loudly (position 4) ──
release/tools/automated-closeout.sh                                       edit
core/standards/hub-action-tracking.md                                     edit
release/references/how-to/hub-spoke-bridge.md                             edit

# ── #6255 · terminal-success arm for an already-merged chore PR (position 5) ──
release/tools/automated-closeout.sh                                       edit

# ── #6411 · lock-held worktree classification + failure-line cause (position 6) ──
release/tools/cleanup-orphan-state.sh                                     edit
core/rules/git-workflow.md                                                edit

# ── #6207 · dry-run must project its own run's freed branches (position 7) ──
release/tools/cleanup-orphan-state.sh                                     edit
release/tools/automated-closeout.sh                                       edit
release/references/pipeline/stage-13-close.md                             edit
```

**15 declared path×card write obligations over 8 distinct paths.** `release/tools/automated-closeout.sh` is written by six of the seven members plus the D-Sibling-Fold's sibling; § Contention Map carries the ordering.

**#5649 carries a second path, and that is the ratified D-Sibling-Fold, not scope creep.** `release/tools/cleanup-orphan-state.sh` enters this card's row set because the operator rendered **D-Sibling-Fold** as a Tier 1 [ADJUST] folded into this release at the Stage-5 wave-1 routing point. It is an amendment to an approved design, not an addition to the composition — `issues_added` remains 0 and no new member entered the milestone.

### CONDITIONAL rows

```
release/references/pipeline/stage-12-execute.md                           edit    CONDITIONAL:title-ownership-lands-at-stage-12
```

**Condition token: `title-ownership-lands-at-stage-12`.** #6204's Stage-5 design decides *which stage owns Release-title composition*. If the ruling places composition at Stage 12, the Surface-1 emit anchor in `stage-12-execute.md` moves and that file is edited; if it places composition at Stage 13, only `stage-13-close.md` is edited and this row never fires. **Per the FCM authoring contract, this row is promoted into the unconditional set in the commit in which its condition resolves**, carrying its now-concrete path; a row left CONDITIONAL after the ruling has been rendered is an authoring defect. The converse also holds — if the file is edited while the ruling went the other way, the row is promoted with its real basis recorded rather than left shielded by a predicate that never fired.

### Read-only inputs

```
core/deploy/lib-instance-path.sh                                          READ
.github/workflows/repo-integrity.yml                                      READ
.github/workflows/release-tooling-smoke.yml                               READ
core/deploy/allowlists/selftest-coverage-manifest.txt                     READ
release/tools/claim-version.sh                                            READ
core/hooks/block-autonomy-ceiling.sh                                      READ
core/hooks/block-skill-direct-edit.sh                                     READ
```

### Release-wide explicit non-scope

```
release/tools/synthesize-release-learnings.sh                             NOT EDITED
release/tools/audit-epic-rollup-close.sh                                  NOT EDITED
core/skills/finops-usage-extractor/scripts/extract-usage.sh               NOT EDITED
core/deploy/allowlists/selftest-coverage-manifest.txt                     NOT EDITED
```

**The non-scope block is explicit and load-bearing, not hygiene.** The first three files carry the *same defect class* #5649 repairs — the absent-key abort shape at `synthesize-release-learnings.sh:111`/`:112` and `audit-epic-rollup-close.sh:119` (both top-level under `set -euo pipefail`), and the masked-but-not-removed `head`-pipe shape at `extract-usage.sh:79`/`:82` (benign for abort — that file carries `set -uo pipefail` with no `-e` — but idiom-bearing, and it ships inside a distributed `.skill` package). They are **deliberately routed to a later release** rather than folded in: only the two close-out tools this milestone is framed around are in scope, and the scope-lock forbids widening. Declaring them out of scope is what makes the boundary falsifiable — a diff touching them is a scope violation, not a judgement call. `selftest-coverage-manifest.txt` is named because it is the one file a reader would expect to need an edit and does not: the roster is keyed on tools that dispatch `--self-test`, it is **discovered rather than enumerated**, it already carries `automated-closeout.sh` at row 18, and it is regenerated by its own emitter and never hand-edited. Adding arms to an existing tool's suite requires no manifest edit.

### New-executable companion obligations

**None — and this is enumerated rather than assumed.** The matrix carries exactly one `add` row (this plan file, a markdown document), and **zero** `add` rows for a tracked executable. No `*.sh` is created by any member, so no `core/config/allowlists/script-execution-allowlist.txt` companion row and no CI-wiring statement is owed. This also preserves `routine` trigger (c) — zero new files outside the plan — intact.

---

## Agent-Editability Read

**Derivation** — controls read at commit `a3083858`, transcribed from Stage-4 Phase A3.5. Skill-gate legend: **`no ¹`** = conjunct 1 decided — the path does not match `SKILL_SCOPE_RE` (it is not under any `<module>/skills/<name>/`), so conjuncts 2 and 3 are not reached.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class |
|---|---|---|---|---|---|
| #5649 | `release/tools/automated-closeout.sh` | no | `no ¹` | `unconstrained` | `unconstrained` |
| #5649 | `release/tools/cleanup-orphan-state.sh` | no | `no ¹` | `unconstrained` | ″ |
| #5762 | `release/tools/automated-closeout.sh` | no | `no ¹` | `unconstrained` | `unconstrained` |
| #6204 | `release/tools/automated-closeout.sh` | no | `no ¹` | `unconstrained` | `unconstrained` |
| #6204 | `release/references/pipeline/stage-12-execute.md` | no | `no ¹` | `unconstrained` | ″ |
| #6204 | `release/references/pipeline/stage-13-close.md` | no | `no ¹` | `unconstrained` | ″ |
| #6841 | `release/tools/automated-closeout.sh` | no | `no ¹` | `unconstrained` | `unconstrained` |
| #6841 | `core/standards/hub-action-tracking.md` | no | `no ¹` | `unconstrained` | ″ |
| #6841 | `release/references/how-to/hub-spoke-bridge.md` | no | `no ¹` | `unconstrained` | ″ |
| #6255 | `release/tools/automated-closeout.sh` | no | `no ¹` | `unconstrained` | `unconstrained` |
| #6411 | `release/tools/cleanup-orphan-state.sh` | no | `no ¹` | `unconstrained` | `unconstrained` |
| #6411 | `core/rules/git-workflow.md` | **no** — see note | `no ¹` | `unconstrained` | ″ |
| #6207 | `release/tools/cleanup-orphan-state.sh` | no | `no ¹` | `unconstrained` | `unconstrained` |
| #6207 | `release/tools/automated-closeout.sh` | no | `no ¹` | `unconstrained` | ″ |
| #6207 | `release/references/pipeline/stage-13-close.md` | no | `no ¹` | `unconstrained` | ″ |

**All-`unconstrained`, and that is the informative output.** Per-path rows are retained rather than collapsed into the card class, and each records the deciding conjunct. The `core/rules/git-workflow.md` row is the one worth a second look: the Tier-0 floor *does* name a `.claude/rules/*` arm, but that arm addresses the **deploy-produced mirror**, which the repository does not track — the repo-source path is outside every floored arm. An `unconstrained` row means no control refuses the write; it never means the change is ungoverned, and this one carries a mirror obligation regardless (R-5).

---

## Contention Map

**Within-release, by file:**

| File | Members | `overlap_class` | Resolution |
|---|---|---|---|
| `release/tools/automated-closeout.sh` | **6** — #6204 #6841 #6255 #5649 #5762 #6207 | `line-range-overlap` = **none at primary regions**; `append-pattern` at three shared surfaces | Sequence per § Implementation Sequence; single branch |
| `release/tools/cleanup-orphan-state.sh` | **3** — #6411 #6207 #5649 (D-Sibling-Fold) | `line-range-overlap` — #5649 at `:148`/`:160`/`:161`, #6411 at `:483`/`:1359`, #6207 at `:630`/`:1740`/`:1752`/`:1790`; disjoint lines, and #6411→#6207 semantically coupled | #5649 first (position 1, header region); then serialize #6411 before #6207 |
| `release/references/pipeline/stage-13-close.md` | 2 — #6204 · #6207 | `append-pattern` — two clauses in different phases | Single branch; graded by CIAC-4 |
| `core/standards/hub-action-tracking.md` | 1 — #6841 | `single-pr` | none needed |
| `release/references/how-to/hub-spoke-bridge.md` | 1 — #6841 | `single-pr` | R-1 — not declared on the card; added here |
| `core/rules/git-workflow.md` | 1 — #6411 | `single-pr` | mirror-pair obligation — R-5 |
| `release/references/pipeline/stage-12-execute.md` | 1 — #6204 CONDITIONAL | `single-pr` | conditional on the Stage-5 ruling |

**The measurement that decides the topology — primary write regions in `automated-closeout.sh`:**

| Region | Lines | Span | Member |
|---|---|---|---|
| exit-code enumeration | `207-211` | 5 | #5762 |
| repo-slug resolution | `386-393` | 8 | #5649 |
| `phase_await_merge_chore_pr` | `5496-5553` | 58 | #6255 |
| `_ai_eval_predicate` | `5796-5813` | 18 | #6841 |
| `phase_action_item_gate` | `5875-5968` | 94 | #6841 |
| `phase_publish_github_release` | `6401-6601` | 201 | #6204 |
| `phase_check_release_body_drift` | `6925-7001` | 77 | #6204 |
| `phase_invoke_orphan_cleanup` | `7005-7026` | 22 | #6207 |

**Overlapping pairs = 0 of 28.** Sensitivity-armed: a synthetic pair (`L100-200` × `L150-250`) fed through the identical predicate returns `True`, so the zero is a measurement and not a broken comparator.

**Three shared surfaces inside that one file — the contention that is real:**

1. **The `usage()`/`--help` phase roster + header enumerations, `:17-:211`** — a hand-maintained block of **43** numbered rows. #5762's target line (`:210`) is inside it; #6255's phase row is `:42`; #6204's is `:52`. **4** self-test arms assert specific roster rows exist, so a roster edit that drops or misnumbers a row reddens rather than passing.
2. **The self-test body** — #5649 (group `TK`), #6204, #6841, #6255 and #6207 each append arms, at five different group anchors inside one region.
3. **The terminal conformant-arm echo block, `~:14108-14123`** — every group appends one `echo "  <group> validated…"` line. A genuine single append point.

**Cross-PR overlap audit — baseline `a3083858`.** 0 open PRs repo-wide (sensitivity-armed: the same reader returns 5 on `--state merged`). The last-merged relevant PR is **#6845 / `99b331e8`**, already an ancestor of the baseline, so its contention is not a concurrent surface and **no rebase step exists** — see R-3.

---

## Risk Register

| ID | Risk | Severity | Reversibility | Mitigation |
|---|---|---|---|---|
| **R-1** | **#6841's cascade is wider than its card declares.** The `open`/`in-flight` predicate exists at `automated-closeout.sh:5805`, `:5922` **and `hub-spoke-bridge.md:2551`**, and `:5785-5786` states self-test group AI arm (G) runs both script copies over the same fixtures and fails naming both sides on divergence. Fixing two of three reddens the suite; fixing the script alone leaves § Procedure 7a teaching the defect. | HIGH | CHEAP | `release/references/how-to/hub-spoke-bridge.md` is carried in #6841's matrix rows above. Verification: group AI arm (G) must pass — the arm that proves parity rather than presence. |
| **R-2** | **Tier-S serialization with ms#395, previously unrecorded.** Three shared files, ≥3 named sibling members, and the sibling is this batch's own split product. Whichever merges first, the other re-baselines onto a substantially changed `automated-closeout.sh`. | HIGH | MODERATE | Recorded in § Cross-Milestone Dependency Validation as Tier-S, and sequenced explicitly rather than by accident. Re-run the intersection against ms#395's File Change Matrix once it has a Stage-4 plan; the predicate is UNRESOLVABLE until then. |
| **R-3** | **A "rebase onto `99b331e8`" instruction was propagated and is wrong.** It appears in the *Carried to Stage 7* line of all seven Stage-5 decision records. `99b331e8` is an **ancestor** of the pinned baseline by 543 commits; rebasing onto it would move work backward. | MEDIUM | CHEAP | **Superseded release-wide** by the hub correction on #7242 and re-confirmed at Commit 0 (`git merge-base --is-ancestor` true, distance 543). Branch from `main` at `a3083858`, which already carries PR #6845's hunks. **There is no rebase step.** Re-run both tools' `--self-test` at Engineering anyway: the group-PS arms are mutation-validated against pre-fix code, so a bad base reddens rather than silently reverting a guard. |
| **R-4** | **#5649's scope drifted since filing** — the card body still says "three unguarded key reads"; the true population is 4 sites, 2 of which were guarded in a prior cycle. Building to the card's literal text wastes effort on already-correct sites. | MEDIUM | CHEAP | Scope narrowed to `:388`/`:389` at Stage-4 Phase A0 (`re-scope-changed`, operator-confirmed) and independently re-derived at Stage 5, by the adversarial review, and at Commit 0. The card body is an **accepted residual** — a public edit does not scrub its history; Stage 8 grades against the 2-site scope stated here. |
| **R-5** | **`core/rules/git-workflow.md` is a mirror-pair member.** Editing repo source without re-laying the deployed mirror leaves `deploy.sh --check` Check 9 asserting byte-identity against a stale copy. | MEDIUM | CHEAP | The mirror is **deploy-produced, never hand-copied**: after merge run `./deploy.sh --deploy`, then `--check` Check 9. Also verify the edited sentence's own links still satisfy the mirror-pair link form — a target outside the mirrored set takes the leading-`/` workspace-rooted form. |
| **R-6** | **#6204's design question may not be resolvable inside its scope.** Stage 12 posts the Release title; Stage 13 authors the note whose H1 it should match. Fixing it may require moving the Surface-1 emit — a Tier-2 [SCOPE CHANGE] against a prior ruling. | MEDIUM | MODERATE | Stage 5 rendered the ownership decision explicitly. The scope-lock ratified **keeping the `phase_publish_github_release` outcome token unchanged** and recording the withhold in the phase detail instead. The `stage-12-execute.md` row stays CONDITIONAL until the ruling's file consequence resolves. |
| **R-7** | **Parallelization Map absent** on a milestone required to carry one; consumed downstream by the A7 T5 refresh trigger and by Stage-9 sequencing. | MEDIUM | CHEAP | Tier 1 [ADJUST] — author it carrying R-2's Tier-S edge. **Milestone-description surface, operator-owned; not discharged by this plan file.** Carried to Stage 9. |
| **R-8** | **The three shared append surfaces inside `automated-closeout.sh`** collide if Engineering runs multi-branch. Five members append self-test arms; up to three touch the roster. | MEDIUM | CHEAP | D-C **SINGLE** removes the class — append surfaces merge cleanly on one branch. Under SINGLE the FILE-boundary rule serializes chips on this file anyway, which is the desired behaviour here rather than a cost. |
| **R-9** | **Rollback is all-or-nothing if the branch is squashed.** One PR, six members on one file, eight regions. | MEDIUM | MODERATE | **Commit-per-issue on the single branch, in Implementation-Sequence order, unsquashed**, so a single member reverts by commit rather than by PR. Do **not** squash the release branch at merge. |
| **R-10** | **#6841's AC bullet 4 cannot be discharged by this PR.** Re-reading the live drifted ledger rows is an action against **operator-instance** ledgers — Layer 2, outside the repository. A repo PR cannot satisfy it, and Stage 8 will grade it NOT MET if it is bound to a code-only verification row. | MEDIUM | CHEAP | Bind that criterion's verification row to an **operator-executed** read, recorded as such, and route it as a Stage-13 action item rather than a Stage-7 arm. |
| **R-11** | **#6255's primary AC method is not offline-executable** — it needs a real merged PR and a live host CLI, while the existing arms for that phase are explicitly offline. | LOW | CHEAP | Verify the terminal-arm logic offline with a host-CLI stub — the argv-file assertion pattern the file already uses at `:10367`/`:10406` — and treat the live-PR arm as the Stage-12/13 in-situ observation. |
| **R-12** | **The native-dependency zero is unarmed.** If a real edge exists and the reader simply is not returning it, the "5 isolates" claim is wrong and the sequence could violate an unseen constraint. | LOW | CHEAP | Two independent sources agree and the reader is demonstrably functional on the same API family. Re-check at Stage 9 Phase A6.5 with a differently-shaped read. **Do not treat as measured.** |
| **R-13** | **No required check exercises either file this release is about.** Exactly **17** required branch-protection contexts; `Close-out automation smoke (macOS)` and `SIGPIPE-idiom gate` are both **absent**. A bash syntax error, or a regression in any new arm, reaches `main` with every required check green. | HIGH | CHEAP | **Green CI is not evidence for this release.** Every Engineering spoke runs both tools' `--self-test` itself and records the observed counts as evidence; Stage 7 re-executes. Registering the smoke job as a required context is host configuration and therefore operator-only — presented with this evidence at the Stage-9 GO gate. |

**Contention risk, summarized:** the batch's contention is real but concentrated in *shared append surfaces* rather than in the fixes themselves — which is what makes single-branch cheap and multi-branch expensive.

**Rollback complexity: MODERATE.** Both tools are self-testing, both self-tests are green at baseline, and every member's change is local to a named region — so a per-commit revert restores a verifiable state. The complexity is entirely in the number of commits on one file, not in coupling between them.

---

## Delivery Strategy

- **One branch** — `release/closeout-correctness-batch`, cut from `main` at `a3083858`. Slug-primary, no version stem (ADR-092).
- **One commit group per member**, in Implementation-Sequence order, message referencing the member's issue number. **Unsquashed at merge** (R-9).
- **One PR**, created in **draft** at Phase C and transitioned to ready-for-review at the Stage-9 gate.
- **Serial spokes (P0)** — the next Engineering spoke starts only after the prior commit lands on the branch.
- **No force-push** on the shared branch, `--force-with-lease` included.
- **Deviations** route per the inter-stage feedback protocol: a minor adjustment commits with its rationale and a § Deviation Log row; a scope change is a Tier 2 `[SCOPE CHANGE]` to the operator; a plan rejection stops and returns upstream. **The scope-lock is in force — a needed addition is a Tier 2 escalation, never a quiet inclusion.**

---

## Verification Plan

### Per-Issue Verification

`ac_baseline: { #5649: 4, #5762: 3, #6204: 4, #6841: 5, #6255: 4, #6411: 4, #6207: 5, total: 29, read_at: a3083858 }`

**Rows for six of seven members are owed by their own Engineering spokes and are scaffolded, not omitted.** This table is a Commit-0 Survival Set element that Stage-6 C4 self-verification and Stage-7 re-execution both consume; a member reaching Stage 7 with no row leaves both stages grading against an empty artifact. Each scaffolded row below names the criterion count owed and its author, so an unpopulated row is visible rather than silent. A criterion this release deliberately will not verify still carries its row with the method cell reading `[DEFERRED — <reason>]`.

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #5649 | AC-1 — a missing optional key falls through to its default, exactly as an absent `operator.toml` already does | Group `TK` arm **TK-1** over the **whole file**: every `operator.toml` key-read line carries non-match tolerance, with an anti-vacuity floor of **≥ 4** on the enumerated population. Behaviourally confirmed at Stage 7 by re-executing the three-arm `bash` probe against the **patched** file. | 4 of 4 sites carry tolerance · **sensitivity arm (TK-3):** the identical matcher against a known-bad fixture string reports exactly **1**, so a green TK-1 is a measurement · **Stage 7:** unguarded+absent, previously rc 1 with zero output, now reaches the next statement at rc 0 |
| #5649 | AC-2 — a genuinely-required key is named and the exit is deliberate | **Differential, not a citation.** With a fixture `operator.toml` present-and-key-absent, assert the tool reaches the named-error path (the `REPO_SLUG` well-formedness gate at `:4122-4126`, which names both keys and refuses to write a broken Release URL into a durable ledger row) rather than exiting 1 with no output. | **Fails on the unpatched file, passes on the patched one.** On today's file the gate is unreachable in exactly the scenario the criterion describes, because `:388` aborts at load before argument parsing — so the two-line fix is what makes AC-2 observable at all. Citing `:4122-4126` and arm `(f)` alone would grade PASS against both trees and discriminate nothing |
| #5649 | AC-3 — no path exits 1 with zero output | **Graded against the bounded restatement**, not the universal form: *no `operator.toml`-key-read path exits 1 with zero output, over an enumerated population with an anti-vacuity floor.* Method: `TK-1` + `TK-2` over the whole file. | Population ≥ 4 in `automated-closeout.sh` and ≥ 3 in `cleanup-orphan-state.sh`; zero unguarded members; zero lines piping into `head` · **specificity arm (TK-4):** the identical matcher against a correctly-guarded fixture reports **0**. The universal reading ("no path over 14,294 lines") is recorded **out of scope** — it is unfalsifiable at this card's scope and marking it PASS would teach the batch that a universal claim is satisfiable by a two-line diff |
| #5649 | AC-4 — controls: an absent `operator.toml` still succeeds; a required missing key gives a named error | Limb 1: the `[[ -r … ]]` predicate at `:387`, unchanged by this work, plus an absent-file arm. Limb 2: **the same differential as AC-2**, not a citation. | Limb 1 holds (absent file → rc 0, the boundary case that already succeeds) · limb 2 fails on the unpatched file and passes on the patched one |
| #5649 | AC-1..AC-4 (sibling limb) | **D-Sibling-Fold.** `bash release/tools/cleanup-orphan-state.sh --self-test` with the new class arm present, plus a source assertion that all **3** key-read sites at `:148`/`:160`/`:161` carry `\|\| true`. | `EXIT=0`, zero FAIL lines, baseline **16 checks / 0 SKIPPED** preserved or exceeded · **sensitivity arm:** temporarily revert one guard, confirm the arm names that site, restore. An arm never observed failing is not yet evidence |
| #5762 | AC-1..AC-3 | `[OWED — #5762's Engineering spoke, from its Stage-5 design on #7221 and its scope-locked criteria]` | 3 criteria owed |
| #6204 | AC-1..AC-4 | `[OWED — #6204's Engineering spoke, from its Stage-5 design on #7225 and the scope-lock correction: keep the `phase_publish_github_release` outcome token unchanged and record the withhold in the phase detail; AC-3's check is class 3-V and needs wire-it-or-downgrade-it plus a gate-efficacy register row]` | 4 criteria owed |
| #6841 | AC-1..AC-5 | `[OWED — #6841's Engineering spoke, from its Stage-5 design on #7229 and two scope-lock corrections: `BAD` must not outrank `UNRES`, and the live-witness mechanism is an EMPTY field-11 arising from a SHORT ROW, not an `open` token and not an uppercase `OPEN`. A fixture built against the earlier descriptions reproduces a condition that does not occur.]` | 5 criteria owed; bullet 4 is **operator-executed** per R-10 |
| #6255 | AC-1..AC-4 | `[OWED — #6255's Engineering spoke, from its Stage-5 design on #7233 and the scope-lock correction: `MERGE_TIMEOUT=2` on arm (g) only, because `TIMEOUT=1/STEP=1` admits exactly one iteration while the arm asserts ≥2 — the arm would fail against a correct implementation. Do NOT weaken the ≥2 assertion; it is the only pin on design decision D-3.]` | 4 criteria owed |
| #6411 | AC-1..AC-4 | `[OWED — #6411's Engineering spoke, from its Stage-5 design on #7237 and two scope-lock corrections: DROP change-spec item 4 (the live worktree read at `:425` is deliberate; routing it through the snapshot opens a TOCTOU, and item 4's stated rationale is impossible because the recheck loop is demote-only), and `git-workflow.md` carries a COUNT this card makes stale — a count is a reference and must move with the change.]` | 4 criteria owed |
| #6207 | AC-1..AC-5 | `[OWED — #6207's Engineering spoke, from its Stage-5 design on #7238 and the scope-lock correction: RE-PIN E5 at Stage 6, because #6411 builds first and its fourth Totals guard lands at the head of this card's pinned range. No arithmetic collision — the counters are disjoint — but the pins are stale by construction. INT-1 resolves MET.]` | 5 criteria owed |

### Release-Level Verification

| # | Check | Method | Expected |
|---|---|---|---|
| RV-1 | Both close-out tools' self-tests pass | `bash release/tools/automated-closeout.sh --self-test` and `bash release/tools/cleanup-orphan-state.sh --self-test`, run by each Engineering spoke after its own commit and re-run at Stage 7 | `EXIT=0`, zero `FAIL:` lines, with the **observed counts recorded**. Baseline for the sibling: 16 checks, 0 SKIPPED |
| RV-2 | Doc-link integrity over the changed corpus | `python3 core/deploy/tools/check-doc-links.py` over the Check-14 scan scope, and `python3 release/tools/check-release-links.py` on the changed delta | zero broken internal links |
| RV-3 | Plan-depth lint on this file | `python3 release/tools/check-release-links.py --plan-depth-lint` | zero relative intra-repo links — this file ships one directory deeper at the Stage-12 claim, so only the leading-`/` form is correct at both depths |
| RV-4 | Mirror-pair sync after #6411's rules edit | `./deploy.sh --deploy` after merge, then `./deploy.sh --check` Check 9 | mirror in sync; no byte-identity drift |
| RV-5 | Skill-package freshness | `printf '%s\n' <changed-path> \| bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` (STDIN, **not** argv — an argv invocation returns empty for every input, which reads as "nothing to rebuild" while having measured nothing) | expected **empty** — no changed path lies under a rostered skill tree; the empty result is reported with the STDIN form named, so it is a measurement rather than an argv artifact |
| RV-6 | ADR index freshness | This release adds **no** record under `release/ADRs/` | `ADR index: N/A — this release adds no record under release/ADRs/` recorded in § Verification Evidence — the honest no-op |
| RV-7 | Parser-clean PR body | `grep -inE "(close\|closes\|closed\|fix\|fixes\|fixed\|resolve\|resolves\|resolved) +#?\[?[0-9]" pr-body-draft.md` | zero matches outside the dedicated Issue References block |

---

## Cross-Issue Acceptance Criteria

Four CIACs. Each spans ≥2 issues, is graded on the merged PR at Stage 9 QC3.5 / Phase A3.6, and requires no dependency edge between the issues it spans.

- [ ] **CIAC-1 (#5762 × #6255 × #6204 — the `automated-closeout.sh` header enumerations):** after all three land, **no enumeration in the file asserts a state or gate the code does not implement** — the exit-code block and the `usage()`/`--help` phase roster each describe shipped behaviour. Release-scoped, not issue-scoped: #5762's own criterion cannot be graded MET without reading #6255's and #6204's phase-behaviour deltas, because both change what the enumerations describe. *Shared surface:* `release/tools/automated-closeout.sh:17-211`. *Method:* `bash release/tools/automated-closeout.sh --help`, asserting the affected phase rows describe post-fix behaviour and the exit-2 line names no un-implemented condition. **Measure the RENDERED output, not the source** — the render is what the consuming arm reads, and both the spoke and the hub previously reached wrong figures by reading the source for a token instead. *Null-arm control:* `grep -c "tag missing" release/tools/automated-closeout.sh` expects **0**, against a control of `grep -ic "tag"` on the same file expecting its pre-existing non-zero count, so a zero from an unresolvable pattern is distinguishable from a real absence. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#6204 × #6255 × #6841 × #6207 — the roster's row-completeness):** every phase whose behaviour any member changed still carries **exactly one** roster row, and **no roster row is dropped or renumbered** by the independent edits to that block. *Shared surface:* the hand-maintained `usage()`/`--help` phase roster, which **4** existing self-test arms already assert row-wise. *Method:* `bash release/tools/automated-closeout.sh --self-test` must pass with those four arms firing, and a roster row count taken from the **rendered** `--help` must be ≥ the baseline **43**. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#6411 × #6207 — the `cleanup-orphan-state.sh` dry-run report):** the dry-run report agrees with what apply does **in both directions in a single run** — a lock-held worktree reads `SKIP — live session` in dry-run *and* apply, **and** a branch freed by that same run's worktree removals is reported as a predicted consequence rather than as skipped. Release-scoped because each issue fixes one direction of the same divergence and **neither alone makes the report relayable as an approval scope**. *Shared surface:* the dry-run classification path (`:483`, `:630`) and `resolve_freed_branches` (`:1752`, `:1790`). *Method:* `bash release/tools/cleanup-orphan-state.sh --self-test` with both members' new fixtures present in one invocation; assert the projected branch set equals the applied branch set on the fixture where a worktree removal frees a branch, and that the locked-worktree fixture classifies SKIP in both modes. Baseline for comparison: 16 checks, 0 SKIPPED, `EXIT=0`. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#6204 × #6207 — `stage-13-close.md`):** both clauses are present and mutually consistent in the same spec file — the stage that owns Release-title composition is named, **and** Phase C4 names the direct `cleanup-orphan-state.sh --apply` invocation as its apply path. Neither edit silently displaces the other, and the file's links still resolve. *Shared surface:* `release/references/pipeline/stage-13-close.md`. *Method:* assert both anchors resolve in the merged file, then `python3 core/deploy/tools/check-doc-links.py` over the pipeline scan scope and `python3 release/tools/check-release-links.py` on the changed delta. *Graded at Stage 9 QC3.5 on the merged PR.*

**Deliberately not a CIAC.** #6841's three-copy predicate parity spans **one** issue across three files, so it fails the ≥2-issue predicate. It is carried as R-1 and as File-Change-Matrix rows, graded by the existing `--self-test` group AI arm (G) — not manufactured into a CIAC to pad the section.

---

## Quota Budget

**Verdict:** WARN
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **7** · Stage 7: **7** · Stage 8: **7**
**Per-spoke cost estimate:** size-bucket ordinal band (heuristic; telemetry medians not yet available for any bucket). Batch composition: 3× `size:M` (low–moderate), 3× `size:S` (lowest), 1× `size:XS` — the heuristic table has no `XS` row, so #5762 is recorded as reading at or below the `S` band's floor rather than silently mapped to `S`.
**Assumed/stated remaining usage-window envelope:** **not stated by the operator at hub start** → conservative default in force. `[ASSUMPTION – CONFIRM]` the envelope state; a stated figure moves this verdict deterministically.
**Estimated cumulative draw % (worst parallel batch):** worst batch = **7 parallel spokes**, identical at Stages 5, 7 and 8. Against a full window the batch estimates **~35 %** → PASS band; against the conservative half-consumed default the same batch estimates **~70 %** → WARN band.
**Routing:** **WARN → window-aware launch timing + split batches.** Split each 7-wide wave into two sub-waves (4 + 3) rather than launching seven at once. **STAGGER is not a mitigation here** — it is a rate-limit defence and does not change cumulative draw.
**Note:** this is a **one-time plan-time estimate whose verdict is advisory**. The load-bearing gate is Checkpoint B, re-validated at **every** spoke launch — wave or singleton, including the write-serialized Stages 6 and 13 — and it additionally gates the host-API pool axis this estimate deliberately omits.

---

## Release Class declaration

**`routine` — CONFIRMED** at the Stage-4 gate and unchanged by Stage 5 or the Collective Review. Trigger evidence, re-derived rather than inherited:

| Trigger | Fires? | Evidence |
|---|---|---|
| routine (a) all issues P3/P4 + `size:S`/`M` | **no** | #6841 and #6411 are P2; #5762 is XS |
| routine (b) all change-spec files have ≥3 prior release touches | **YES** | commit counts on `origin/main`: `automated-closeout.sh` **124** · `hub-spoke-bridge.md` **115** · `stage-13-close.md` **66** · `stage-12-execute.md` **36** · `git-workflow.md` **33** · `cleanup-orphan-state.sh` **16** · `hub-action-tracking.md` **7**. Minimum is 7; the threshold is 3 |
| routine (c) zero new files added | **YES** | The matrix carries exactly one `add` row — this plan file. No member adds a file |
| routine (d) zero new D-class decisions | **holds** | The plan's D-decisions are *recurring* entries present on every plan. Stage 5 raised no new release-specific D beyond the wave-1 dispositions, and **no ADR is authored by any member that reached Stage 5 with a design**, so novel trigger (c) does not fire |
| novel (a) new reference doc / schema / skill | **no** | none added |
| cross-cutting (a) ≥3 `pipeline/stage-*.md` | **no** | 2 (`stage-12-execute.md` CONDITIONAL, `stage-13-close.md`) |
| cross-cutting (b) ≥3 of the 6 rule-defining surfaces | **no** | 1 (`hub-spoke-bridge.md`) |

**Differentiation posture (routine):** engagement density **Light** · Stage 9 review depth **Standard** · Stage 5 activation bias **SKIP-where-trivial**, recorded as declared and explicitly **not applied** · Stage 13 outcome-window **30-day**.

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #5649 · #5762 · #6204 · #6841 · #6255 · #6207 | `git revert` of the member's commit group | Low — each is local to a named region in a tracked file |
| #6411 | `git revert` of the member's commit group, **then re-run `./deploy.sh --deploy`** | Medium — a revert of the merge does not un-deploy the `core/rules/` mirror |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated member failure | Revert that member's commit group on a fix branch |
| **Full Restore** | Systemic failure | `git revert -m 1 <merge-sha>` — the merge commit is two-parent by construction, so the whole-release revert is available. **The version tag is NOT deleted**: `refs/tags/v*` is host-protected, and the tag remains as the record that the version was claimed and then withdrawn |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch off `main` |

**One limb sits outside the git guarantee and is called out rather than implied:** #6411's rules-file edit propagates to the deployed mirror through `./deploy.sh`, so a revert of the merge does not un-deploy — re-run the deploy after any revert. Reversibility **CHEAP** for the repository; Confidence **HIGH**.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `core/rules/git-workflow.md` | the deployed `.claude/rules/` mirror | `./deploy.sh --deploy` (rules mirror, deploy-produced from the pair-set declaration) — **#6411 only** | `./deploy.sh --check` Check 9 reports the mirror in sync |

**No other propagation target exists in this release.** Enumerated over the four classes `./deploy.sh --deploy` carries — `skills/` S-2 copy, `packages/` `.skill` rebuild, `core/rules/` mirror, and the hook mirror — against the declared File Change Matrix: **0** paths under any `skills/` tree, **0** under `packages/`, **1** under `core/rules/`, **0** under `core/hooks/`. Both `release/tools/` scripts are neither rostered skills nor distribution packages, so they owe **zero** S-2 copy and **zero** `.skill` rebuild — inapplicable by construction, not deferred. Confirmed against the merged diff at Stage 12.

### Schema Migrations

**N/A** — enumerated over the classes a migration could take (data-format change on a persisted store, frontmatter schema field addition or removal, config-file key rename, registry re-keying). None is present. #5649 changes the *failure behaviour* of an existing optional-key read without changing the key set, the file format, or any persisted record.

---

## Deviation Log

| # | Deviation from the Stage-4 / Stage-5 transcription source | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **Group `TK`'s scan region changes from the production region to the whole file.** The Stage-5 design specced `sed -n '1,/^self_test() {/p'`, which yields lines **1–7341**; `self_test()` closes at **`:14124`**, so **170 lines of production code at `:14125-14294` are invisible**, including all of `check_paths()` at `:14154-14210`. The ≥4 anti-vacuity floor is satisfied by the four sites above the cut, so the arm would read healthy while blind — the "site 5" blindness the design exists to prevent, reintroduced at the region level. | Phase A6.5 adversarial review CD-1 (Major); ratified in the Collective Review scope-lock | **RATIFIED BEFORE ENGINEERING.** `TK` scans `"${BASH_SOURCE[0]}"` whole-file and excludes its own fixtures **by construction**, exactly as group `AI` arm **F4** does at `:13609-13616` — F4 must read whole-file because the dispatch lines it asserts over live below `self_test()`. Verified independently at Commit 0: `self_test()` at `:7341`, closing brace at `:14124`, `check_paths()` at `:14154`. |
| **DEV-2** | **The D-Sibling-Fold recipe does not fit the sibling.** The `:388` recipe ("insert `-m1`, delete `\| head -1`, append `\|\| true`") was carried to `cleanup-orphan-state.sh:148/:160/:161`, but those lines **already carry `grep -m1` and have no `head` pipe** — two of the three steps have no referent, and the stated acceptance test ("byte-identical to `:525`") **fails on a correct fix**. | Phase A6.5 adversarial review FM-1 (Major); ratified in the scope-lock | **RATIFIED.** The sibling change is **`\|\| true` only**, and the acceptance test is replaced with the one that discriminates there: the post-change line differs from its current text by exactly the appended `\|\| true`. Verified independently at Commit 0 by reading all three lines. **The class has two remediation shapes, not one** — Shape A (append `\|\| true` only) and Shape B (the full fold) — and this plan records the boundary so a later reader does not re-apply the wrong one. |
| **DEV-3** | **The sibling fold gains its own regression arm.** The design routed the sibling as out-of-scope drift and never carried its own class-level argument across with it, so the fold would have shipped bare while the same release argues a bare guard is insufficient. | Phase A6.5 adversarial review FM-3 (Major); ratified in the scope-lock | **RATIFIED.** `release/tools/cleanup-orphan-state.sh` defines its own `self_test()` at `:3156`, so the arm has a home. **A better precedent than the `TK` shape exists in that same file and is adopted instead of transplanting `TK`:** `selftest_no_live_worktree_pipes()` at `:2654` already reads the whole source and excludes its own known-bad fixtures **by construction**, via a marker comment its own matcher filters out — both DEV-1 properties, already shipped. The sibling arm follows that in-file shape (a named `selftest_*` function plus a dispatch line inside `self_test()`), with an anti-vacuity floor of **≥ 3** measured at Commit 0. |
| **DEV-4** | **AC-2 and AC-4 limb 2 change from a citation to a differential.** The design recorded them "already satisfied; graded by reading, not by building", citing the `REPO_SLUG` well-formedness gate and its existing arm `(f)`. That grade **passes identically on the unpatched file** — arm `(f)` sets the slug directly and never reads a key, and on today's file the gate is unreachable in exactly the scenario the criterion names, because `:388` aborts before argument parsing. | Phase A6.5 adversarial review FM-2 (Major) | **ADOPTED AT COMMIT 0.** "No new code" is kept; the *method* becomes a differential that fails on the unpatched file and passes on the patched one. This is the same unfalsifiability the design correctly caught on AC-3, one row over. |
| **DEV-5** | **AC-3 is re-scoped off its unfalsifiable universal form** ("no path exits 1 with zero output" over a 14,294-line script) to the bounded form: no `operator.toml`-key-read path exits 1 with zero output, over an enumerated population with an anti-vacuity floor. | Operator decision **D-AC-Rebase**, recorded in the Stage-5 wave-1 decision record | **RATIFIED.** The universal reading is recorded out of scope rather than graded PASS. |
| **DEV-6** | **#5649's scope is 2 sites, not the 3 its body states.** The card body says "three unguarded key reads"; the measured population is **4** sites, of which `:320` and `:525` were guarded in a prior cycle. | Stage-4 Phase A0.8 `re-scope-changed`, operator-confirmed; re-derived at Stage 5, by the adversarial review, and at Commit 0 | **RATIFIED, with the body left unamended as an accepted residual** — a public issue edit does not scrub its history, and the design is built against current state. **The two already-correct sites are not touched.** |
| **DEV-7** | **"Rebase onto `99b331e8`" is withdrawn release-wide.** It appears in the *Carried to Stage 7* line of all seven Stage-5 decision records. | Hub correction on #7242, restated in the scope-lock | **SUPERSEDED IN ALL SEVEN.** `99b331e8` is an ancestor of the baseline by 543 commits; the branch is cut from `main` at `a3083858`, which already carries PR #6845's hunks. **There is no rebase step.** |
| **DEV-8** | **The Path-2 rationale is narrowed.** The Stage-5 design asserted that at `:388`/`:389` "a *successful* key read can abort the tool" via a SIGPIPE on `\| head -1`. Measured process-level with both control arms, `grep` returns rc 0 in 5/5 trials on a realistic one-matching-line fixture and SIGPIPEs only above **~3,028 duplicate matching lines**. | Phase A6.5 adversarial review PR-1 (Major, premise accuracy; the design's conclusion unchanged) | **NARROWED, NOT WITHDRAWN — and the fold still stands on two grounds verified at Commit 0.** (1) `\| /usr/bin/head -1` on an **added line** is matched by the `sigpipe-idiom` job's reader list (`head`, "including at the close of a `$(…)` substitution"), and that job scans the added-lines delta — so appending `\|\| true` alone would leave a changed line carrying a matched idiom, while the folded form's post-pipe reader is an `awk` with no `exit` and is not matched. (2) Folding makes all four sites one shape, which is what lets the class arm key on a single predicate rather than a disjunction. **What must not be carried forward** is "a successful key read can abort the tool" as a statement about these two sites. |

---

## Verification Evidence

(Populated by each Engineering spoke as its commit group lands, and consolidated at Phase C4 before the PR is marked ready-for-review.)

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Change Description

(Authored by the Stage-6 Engineering spoke at PR-creation time per [`RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Change Description Protocol, once the last card lands. Operator-facing, pre-merge, ~60 lines, six sub-sections. Distinct from the user-facing release note authored at Stage 13 Close per [`release-notes-standard.md`](/release/references/standards/release-notes-standard.md).)

---

## Baseline pin

`origin/main` @ **`a3083858`** (`a30838589583bcddf5f88183cfff1a8ea2475300`), measured 2026-09-06 at Stage-4 Planning and **confirmed unmoved at Engineering Commit 0** on 2026-09-07 — the Stage-4 pin and the Commit-0 base are the same commit. Read by the Stage-9 mid-pipeline divergence re-check. `99b331e8` is an **ancestor** of this pin by **543** commits.

## Issue References

<!-- repo-integrity: allow-issue-ref — limb 1: a release plan's member enumeration IS its subject matter; the numbers are the release's own scope, not prose citations, and relocating them would delete the plan's scope statement -->

Every member of this milestone is transitioned to closed at Stage 13, by the Stage-13 close-out on the merged PR rather than by an auto-close keyword in the PR body. The members are #5649, #5762, #6204, #6841, #6255, #6411 and #6207.

- **#5649** — `automated-closeout.sh` aborts at load with exit 1 and no output when `operator.toml` exists but omits an optional key.
- **#5762** — the exit-code comment describes a condition the code does not gate, and the roster row disagrees with it.
- **#6204** — no stage owns Release-title composition, and the edit path posts no title at all.
- **#6841** — an action-item status outside the enum passes the gate silently instead of failing loudly.
- **#6255** — the chore-PR merge wait has no terminal-success arm for a PR that is already merged.
- **#6411** — a lock-held worktree classifies REMOVE, and the failure line names a cause that is not the real one.
- **#6207** — the dry-run report counts branches its own run's worktree removals would free as skipped rather than as a predicted consequence.
