<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — closeout-output-set-integrity

> **Milestone:** `closeout-output-set-integrity` (#304) · **Release Class:** novel (Standard / Deep / ALL / 30-day) · **Version:** `v<X.Y>` — **bound at the Stage-12 atomic claim (ADR-092)**; this release deliberately carries **no pre-claim version token** · **Scope:** 5 issues, 20 raw pts (23 effective at class weight 1.15) · **Topology:** D-C `SINGLE` · **Concurrency posture:** P0 fully-serial · One release branch, one PR, one merge gate · **Branch:** `release/closeout-output-set-integrity` (slug-only).

This plan is the Stage-4 release plan (rendered on sub-task #4239, 2026-07-30 Thursday), reconciled with the six D-verdicts rendered at the Procedure 0 gate, the four Stage-5 Solutioning outputs, and the **Collective Review scope-lock** (LOCKED, 2026-07-30). Deltas discovered after Stage 4 are folded into the Deviation Log below rather than silently applied.

## Release Identity — slug-primary, no pre-claim version

**This release binds no version before Stage 12.** The plan file is slug-named, the branch is slug-named, and no version token appears in either. The version is computed and claimed **once**, atomically, at the Stage-12 merge tag, where git's ref compare-and-swap is the authority — a colliding tag push is rejected, and the loser recomputes and retries.

**Why, stated as a rule rather than as this release's circumstance.** Stamping a version into a filename at Engineering Commit 0 converts a Stage-12 compare-and-swap into a Stage-6 land-grab with no arbitration. Three concurrent releases can each read a version as free and each write it into a plan file, because a pushed release branch carrying a version-titled plan is a *recorded but unsettled* claim that the settled-claim surfaces (git tags, published Releases, `RELEASE_LOG` rows) do not see. Binding the version only at the atomic claim removes that window entirely, and preserves the platform's **ship-order = merge-order = tag-order** guarantee: a release that took a higher number early and merged first would invert tag order against merge order.

**Precedent, stated precisely.** Slug-only plan filenames already exist in the corpus — `governance-ci-gates_RELEASE_PLAN.md` and `governance-ci-checks_RELEASE_PLAN.md` (version-less releases) and `pda-rollup-and-portfolio_RELEASE_PLAN.md` (which shipped as a versioned release). What is new here is adopting the slug-only form **deliberately and from Commit 0, because the version is not yet bound**, rather than as a naming preference. The freeness-oracle defect that motivates it — the adapter's reference implementation omits the in-flight claim surface its own normative contract requires — is tracked as its own work item and is **not** in this release's scope.

## Summary (30 seconds)

Five defects in the release close-out surface. After this release, a published release's ledger footprint is complete and the gate that grades that completeness is actually armed.

- **#3727** backfills the **complete** Stage-13 output set for `v3.69.1` — a security patch (two coordinated-disclosure advisories) that shipped its tag and published Release on 2026-07-11 but landed in **zero** ledgers. Per **D-J**, the scope is five artifacts, not four: the four ledgers plus the release-notes file.
- **#4176** arms the close-completeness gate. `CLOSE_COMPLETENESS_CHECK_CUTOFF` has **no committed carrier anywhere in the repo** — it is an environment variable nothing sets — so the gate has been evaluating dormant since it shipped. Per **D-E** the carrier is a committed default in `core/deploy/deploy.sh`, cutoff `v3.89`.
- **#3113** is the structural core: scaffold-residue detection, preflight acceptance of pre-authored notes, executed (not merely emitted) primary-checkout sync, an anchor-parity regression guard, and the `RELEASE_PROTOCOL.md` file-structure reconcile. Per **D-I** it ships **keep-whole-but-narrow**.
- **#1550** ships automated filled-register production. Per **D-G** it lands as a **standalone tool**, not as a new phase inside an already-large close-out script.
- **#2422** records the instance-absence tolerance as a **spec anchor plus a red-today regression test** (per **D-H**), rather than building an instance-aware code branch ahead of the design that will own it.

**The headline sequencing rationale in the milestone description is empirically false and is superseded.** The milestone sequences `#4176 → #3727` so the armed check catches the ledger gap. Check 48 is **LOG-row-driven** — its own header records the blind spot verbatim: a close that never wrote its `RELEASE_LOG` row is invisible to it — and `v3.69.1` has zero `RELEASE_LOG` rows. Arming first therefore cannot see the gap **at any cutoff**. Backfill first; arm against the final ledger. **Approved sequence: `#3727 → #4176 → #3113 → #1550 → #2422`.**

## Dependency Graph

Directional edges. `⇒` hard (blocking) · `→` soft (sequencing preference) · `⟷` contention-only (no direction).

```
#3727 ──→ #4176        (soft, INVERTED from the milestone proposal)
#3727 ──→ #3113        (soft — AC4 grades the row-count parity #3727 perturbs)
#3113 ──⟷ #2422        (contention: release/tools/automated-closeout.sh — see the correction below)
#1550 ──→ #2422        (soft — WITHDRAWN at Stage 5; D-G resolved to the standalone tool)
#4176 ──⟷ #3113        (weak contention: the close-completeness surface)
```

**E1 — `#3727 → #4176` (the milestone has this backwards).**
Check 48's own header documents the blind spot: a close that never wrote its `RELEASE_LOG` row is invisible to it. Empirically, with no `v3.69.1` row present, the probe at cutoffs `v4.01 / v4.0 / v3.100 / v3.98 / v3.95 / v3.90 / v3.89` verdicts CLEAN and names `v3.69.1` in **none** of them. With the row simulated at its chronological position, cutoff `v3.69` yields **10 findings**, four of them `v3.69.1` — including `missing notes file`. There is no hard edge in either direction **provided the cutoff is forward-dated**; the soft edge runs `#3727 → #4176` because the arming chip should choose its cutoff and demonstrate CLEAN against the **post-backfill** ledger, not against a state it is about to change. **CHEAP · HIGH.**

**E1a — derived hard bound on #4176 (a correctness bound, not a dependency).** The chosen cutoff MUST resolve to a `RELEASE_LOG` row **at or after `v3.89`**, and at a file position strictly after the backfilled `v3.69.1` row.

**E2 — `#1550 → #2422`: WITHDRAWN.** The Stage-4 edge was conditional on D-G resolving to "new phase inside `automated-closeout.sh`". **D-G resolved to (C)** — a standalone tool — so `automated-closeout.sh` gains no instance-path awareness from #1550, the edge does not fire, and CIAC-5 is withdrawn with it.

**E3 — `#3727 → #3113` (soft).** #3113 AC4 asserts that the `RELEASE_INDEX` row count matches the `RELEASE_LOG` release-row count. Live baseline is **149 / 149 — at parity**. #3727 adds one row to each; a partial backfill (a LOG row without an INDEX row) makes AC4 fail *and* breaks the corpus linter's "INDEX surface row count >= LOG entry count" check. AC4 grades a surface #3727 perturbs, so #3727 goes first. **CHEAP · HIGH.**

**E4 — `#3113 ⟷ #2422` (contention, corrected).** See § Contention Map — this is a trivial rebase, not the 3-way hazard Stage 4 recorded.

**Non-edges, stated with evidence:** #4176 ⟷ #1550 — disjoint files, except a shared documentation touch on `release/references/pipeline/stage-13-close.md` in different sections (append-pattern). #3727 ⟷ #1550, #3727 ⟷ #2422, #3727 ⟷ #4176 — fully disjoint at file level.

## Implementation Sequence

**Approved: `#3727 → #4176 → #3113 → #1550 → #2422`** (inverted from the milestone's proposed `#4176 → #3727 → #1550 → #3113 → #2422`; two moves — the leading pair swaps per E1, and #1550 moves after #3113).

| # | Issue | Size | Why here |
|---|---|---|---|
| 1 | **#3727** | S (2) | Pure data; no code; zero upstream dependencies. Establishes the ledger state that #4176's cutoff decision and #3113's AC4 both read. Shape is fully determined by two in-corpus precedents (`v3.65.1`, `v3.73.1`). |
| 2 | **#4176** | S (2) | Cutoff chosen against the final ledger; AC2 is evidenced by a post-backfill non-vacuous CLEAN probe. Touches `core/deploy/deploy.sh` — disjoint from the `automated-closeout.sh` block that follows. |
| 3 | **#3113** | L (8) | The structural core of the `automated-closeout.sh` / `lint_release_corpus.py` surface. Landing it first means the smaller script changes are authored against the hardened script. |
| 4 | **#1550** | M (4) | Adds the standalone producer tool and its Stage-13 invocation step; authored against #3113's landed phase table. |
| 5 | **#2422** | M (4) | Last, per the milestone's own correct reasoning — it shares the edit-set with #3113 (a 4-line header comment) and its spec anchor is authored against the final state of the surface. |

**#3113 internal build order** (one card; its ACs are not independent):

```
AC8  RELEASE_PROTOCOL.md File-Structure reconcile   (isolated; zero code coupling)
AC2  preflight accepts pre-authored notes file      (must land before AC1 so the AC1 gate is
                                                     exercised against an accepted note)
AC1  scaffold-residue detector                      (largest and most invasive; spans
                                                     phase_scaffold_release_notes +
                                                     phase_lint_release_notes + lint_release_corpus.py)
AC7  primary-checkout sync executed, not emitted    (independent phase; after AC1 to avoid racing
                                                     the same file's phase table)
AC5  tagger-identity guard                          (method narrowed to ANNOTATED tags — see Deviation Log)
AC4  anchor-parity regression guard                 (set-based, with the dated exemption set;
                                                     backfill routed OUT — see § Scope Carve-Outs)
AC3  §7 enforcement point                           (narrower than the AC text implies — a posture
                                                     question on an existing criterion, not a new one)
AC6  hermeticity + PR-open trigger                  (LAST — both halves look already-resolved;
                                                     run as verify-and-record, not build)
```

## Stage Applicability Matrix

Stages 5–13. `Y` = applies · `N` = skipped (justified) · `R` = release-scoped (fires once for the whole release).

| Issue | 5 Solutioning | 6 Eng | 7 DevTest | 8 QA | 9 Review | 10 Dry-Run | 11 Snapshot | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|---|
| **#3727** | **N** | Y | Y | Y | R | N | N | R | R |
| **#4176** | Y | Y | Y | Y | R | N | N | R | R |
| **#3113** | Y | Y | Y | Y | R | N | N | R | R |
| **#1550** | Y | Y | Y | Y | R | N | N | R | R |
| **#2422** | Y | Y | Y | Y | R | N | N | R | R |

**Every skip justified.**

- **Stage 5 SKIP — #3727 only.** Zero design choices; the artifact shapes are dictated by two in-corpus worked examples. The one open question — whether the notes file is in scope — is a **scope** question, not a design question, and was routed to **D-J** at the Procedure 0 gate rather than to Stage 5. Recorded as a deliberate, evidenced exception to the `novel` class's ALL activation bias.
- **Stage 5 ACTIVATE — the other four**, each on a named design question rather than on class bias: #4176 (where the armed cutoff lives — no carrier existed), #3113 (AC1's detector mechanism, explicitly deferred to Stage 5 by the card itself, plus the AC3/AC5 re-scopes), #1550 (producer siting), #2422 (the card states the open design question itself).
- **Stages 7/8 — no skips.** Every issue has functional impact. #3727 is data-only but carries a machine-runnable AC that DT must execute. **#2422's Stage-7 shape resolved under D-H = (A)+(D):** a documentation-conformance check plus a **negative control** — its AC1 is vacuously satisfied on today's code (`--check-paths` already exits 0), so DT must prove the probe is not passing on nothing.
- **Stages 10/11 SKIP — release-wide, by governance, not by judgment.** On the Claude Code path, PR review *is* the dry-run governance gate: the diff is reviewable and git history is the snapshots. Stages 10/11 are the Cowork-path mechanisms; they are absorbed, not omitted.
- **Stages 9/12/13 are release-scoped** — one Plan Review, one Execute, one Close, because D-C `SINGLE` means one PR and one merge.

**Parallel-eligible spoke counts:** Stage 5 = 4 · Stage 7 = 5 · Stage 8 = 5.

## Contention Map

### Within-release

| File | Issues | Overlap class | Resolution |
|---|---|---|---|
| `release/tools/automated-closeout.sh` | **#3113 (substantive) · #2422 (4-line header comment)** | `line-range-overlap` (trivial) | **CORRECTED from the Stage-4 3-way finding.** #1550 touches this file **not at all** under D-G = (C); #2422's edit is a four-line comment in the `check_paths()` header. **#3113 is the sole substantive editor.** Residual risk is a trivial rebase, not a merge hazard. |
| `release/references/pipeline/stage-13-close.md` | #4176 · #1550 | `append-pattern` | Different sections (gate-status note vs. register-production step). Sequence-only. |
| `.github/workflows/release-tooling-smoke.yml` + `core/config/allowlists/script-execution-allowlist.txt` | #1550 · #2422 | `append-pattern` | Logged, not escalated. #1550 lands first; #2422 rebases onto its landed state before appending. #2422's cascade targets were verified not to collide with #1550's counter bump — that header counts tool `--self-test` invocations, not standalone suites. |
| close-completeness surface (`.github/close-completeness.enforce`, `.github/workflows/close-completeness.yml`) | #4176 · #3113 (declined) | `line-range-overlap` | Weak, and now **declined**. #3113's proposal to have Check 48 additionally assert the velocity field and the learnings triple is **not in AC1–AC8** and is **not admitted to this release** — see § Scope Carve-Outs. `core/deploy/deploy.sh` is therefore **#4176-sole**. |

**No within-release contention:** `core/deploy/deploy.sh` (#4176 sole), `core/deploy/tools/lint_release_corpus.py` (#3113 sole), the four ledgers and the notes file (#3727 sole).

### Cross-milestone (Tier-S) — milestone #298 `release-closeout-integrity`

`EDITSET(#298) ∩ SURFACE(#304)` is non-empty on **five files**:

| Shared file | #304 claimant | #298 claimant |
|---|---|---|
| `release/tools/automated-closeout.sh` | #3113, #2422 | its open-issue-detection and stale-verification-count cards |
| `CHANGELOG.md` | #3727 | its placeholder-entry backfill card |
| `release/releases/RELEASE_DIGEST.md` | #3727 | its placeholder-entry + date-anchor cards |
| `release/releases/RELEASE_LOG.md` | #3727 | its milestone-ref fix + date-anchor cards |
| `release/releases/RELEASE_INDEX.md` | #3727 | its date-anchor card |

**Disposition: this release PROCEEDS and races #298 to land first.** See Risk R1 — the Stage-4 remediation's premise inverted and the risk was re-rendered rather than re-asserted. Whoever lands second re-baselines.

`.gitattributes` carries `merge=union` on `RELEASE_INDEX.md` / `RELEASE_DIGEST.md` / `CHANGELOG.md` but deliberately **not** on `RELEASE_LOG.md`, whose status column is state-bearing. Concurrent appends to the three take-both; `RELEASE_LOG.md` conflicts loudly instead. The asymmetry is correct — do not add `RELEASE_LOG.md` to the union set to make a rebase easier.

### Cross-PR

**Baseline pinned:** `origin/main` @ `c4dde614`, 2026-07-30. Open PRs at planning time: **zero**. **Audit-baseline caveat — this is not load-bearing on its own:** the open-PR population is transiently empty and a single PR opened later silently invalidates it, so the bounded window is the last ten merged PRs (#4193…#4234), **all ten** of which are close-out chore PRs touching the four ledgers. That is the release's real cross-PR signal: **the four ledgers are the highest-traffic append surface in the repo.** Re-run this audit at Stage 9.

## File Change Matrix

Machine-readable — one path per line, whitespace-delimited: `<path> <INTENT> <issue> [<condition>]`. Extract with `awk '{print $1}'`.

```
release/releases/RELEASE_LOG.md                                 EDIT  #3727
CHANGELOG.md                                                    EDIT  #3727
release/releases/RELEASE_INDEX.md                               EDIT  #3727
release/releases/RELEASE_DIGEST.md                              EDIT  #3727
release/releases/notes/v3.69.1_RELEASE_NOTES.md                 ADD   #3727
core/deploy/deploy.sh                                           EDIT  #4176
.github/close-completeness.enforce                              EDIT  #4176
.github/workflows/close-completeness.yml                        EDIT  #4176
core/standards/gate-efficacy-standard.md                        EDIT  #4176
release/references/pipeline/stage-13-close.md                   EDIT  #4176
release/tools/automated-closeout.sh                             EDIT  #3113
core/deploy/tools/lint_release_corpus.py                        EDIT  #3113
release/governance/RELEASE_PROTOCOL.md                          EDIT  #3113
core/schemas/gate-criteria-spec.md                              EDIT  #3113  CONDITIONAL:AC3-posture-flip
release/tools/synthesize-release-learnings.sh                   EDIT  #3113  CONDITIONAL:AC6-still-open
release/references/pipeline/stage-13-close.md                   EDIT  #1550
release/tools/produce-learnings-register.sh                     ADD   #1550
release/tools/automated-closeout.sh                             EDIT  #2422
release/references/standards/corpus-home-adapter-constraints.md ADD   #2422
core/config/allowlists/script-execution-allowlist.txt           EDIT  #1550 #2422
.github/workflows/release-tooling-smoke.yml                     EDIT  #1550 #2422
core/standards/repo-host-adapter-versioning.md                  EDIT  release-scoped
release/ADRs/<self-arming-conditional-gate-posture>.md          ADD   release-scoped
release/releases/plans/closeout-output-set-integrity_RELEASE_PLAN.md  ADD  release-scoped
```

**Read-only inputs** (consumed, never edited — listed so DT does not mistake them for scope):

```
core/deploy/lib-instance-path.sh                                READ  #1550 #2422
release/references/templates/release-learnings-register-template.md  READ  #1550
release/references/standards/release-notes-standard.md          READ  #3727
.gitattributes                                                  READ  #3727
```

**Four amendments to the Stage-4 matrix, each with its basis:**

1. **REMOVED `release/tools/check-anchor-hygiene.sh`.** Dropped at the Collective Review scope-lock — the anchor-hygiene guards site **inside** `automated-closeout.sh` per the `extend`-over-new stance. Zero net-new files for #3113.
2. **ADDED `core/config/allowlists/script-execution-allowlist.txt` and `.github/workflows/release-tooling-smoke.yml`.** Prerequisites, not scope growth: without the allowlist entry a new executable is hook-blocked agent-side, and without the workflow wiring its `--self-test` never runs in CI. This was missed by the Stage-4 matrix and rediscovered independently by two Stage-5 spokes (N=2) — `release/tools/tests/` holds four suites and **zero** allowlist entries, so all four are currently unrunnable agent-side.
3. **ADDED a 1-line See-also cross-reference in `core/standards/repo-host-adapter-versioning.md`.** Additive; approved at the scope-lock.
4. **ADDED one release-scoped ADR** recording the **self-arming conditional gate** posture — a gate that ships armed by a committed default rather than deferring the arming to a later step that can be forgotten. One ADR covering #4176 and #2422 **jointly**, not two card-scoped ones. The concrete ADR number is allocated at authoring time from the global monotonic sequence across both ADR homes.

**Placement forward-check.** `git log <release-base>..origin/main --name-status --find-renames` over this release's base→main window returns empty (base == main tip at branch creation). No structural reorganization merged after the base, so no not-yet-authored file needs re-homing; every ADD above is placed at current-main topology.

## Scope Carve-Outs

Three items are deliberately **out** of this release. Each is recorded here so a reader does not mistake the omission for an oversight.

1. **#3113 AC4's four-reference backfill is ROUTED OUT.** This release ships the set-based anchor-parity **guard** with a dated exemption set of exactly `{v3.31, v3.65.1, v3.28, v3.29}`. The data backfill becomes its own work item. This mirrors the mechanism/data split already agreed with the sibling placeholder-content card in milestone #298.
2. **The `v3.80` re-tag is DEFERRED.** The guard ships with `v3.80` exempted until remediated. Re-tagging a published release is a discrete operator decision with its own reversibility profile and does not belong inside a bundled release.
3. **The Check-48 velocity/learnings assertion proposal is DECLINED for this release.** #3113's later comment proposes that the close-out script emit — or Check 48 assert — the Phase-B velocity field and the Phase-A7 learnings triple. That is **not in AC1–AC8**; admitting it would put #3113 into direct `core/deploy/deploy.sh` contention with #4176 and add a ninth AC to a card that already trips the decomposition predicate. Routed to intake as its own work item.

## Verification Plan

Per-issue acceptance-criterion method classes, consumed by Stage 7 Dev Testing and Stage 8 QA.

| Issue | Method class | Expected result |
|---|---|---|
| **#3727** | file-content assertion ×5 + row-count invariant | `^\|\s*v3\.69\.1\s*\|` matches in `RELEASE_LOG.md`; `## [v3.69.1]` in `CHANGELOG.md`; a `v3.69.1` row in `RELEASE_INDEX.md` whose Release Notes link resolves; `### v3.69.1` in `RELEASE_DIGEST.md`; `release/releases/notes/v3.69.1_RELEASE_NOTES.md` exists and passes the release-corpus note-content lint; INDEX release-rows == LOG release-rows (**150 / 150**) |
| **#4176** | predicate evaluation (re-run the cited expression) | the close-completeness probe reports `<n> VERIFIED release(s) in scope … — OK` with `n >= 1` and exits 0; the resolved arm row is asserted, not assumed; the enforce-sentinel token is recorded in this plan |
| **#3113** | mixed: file-content (AC8) · behavioral with declared method (AC1/AC2/AC7) · system-state probe (AC4/AC5) · verify-and-record (AC3/AC6) | AC1: seed an unfilled scaffold → preflight exits non-zero **and** names the offending token. AC2: pre-authored note → exit 0. AC7: primary checkout behind `origin/main` → fast-forwarded after. AC4/AC5: probes return the asserted **set**, under the narrowed annotated-tag method |
| **#1550** | file-content + behavioral | the register file materializes at the resolved operator-instance register path; the Kerth and PMBOK sections are seeded from the learnings triple's three fields; the tool's `--self-test` passes |
| **#2422** | behavioral **with mandatory negative control** | the path probe exits 0 on instance absence **and** exits non-zero on a genuine broken path. The control is what makes the criterion non-vacuous |

**Anti-vacuity requirement, stated once and binding on all five.** Three criteria in this release are satisfiable by code that does nothing: #4176's probe exits 0 when unarmed, #2422's `--check-paths` already exits 0 today, and #3113's AC6 halves both appear already-resolved. For each, Stage 7 must run a **negative control that makes the check fail** before the criterion is graded MET. An exit-0 observation on today's code proves nothing.

**Declared-verification-deferred note.** #3113's AC5 guard and AC4 regression probe declare methods whose executor is authored in this release. Declaring the method is what makes the criterion honest at planning; building the executor is Stage 6/7's concern.

## Cross-Issue Acceptance Criteria

**Four entries.** CIAC-5 is **withdrawn** (D-G = (C) removes the shared instance-path surface). CIAC-1's Stage-4 method was **defective and is replaced** by the corrected `INT-1` below. Graded at Stage 9 on the merged PR.

**INT-1 (#3727 × #4176 on `RELEASE_LOG.md` row order ∩ the close-completeness cutover arm)** — *supersedes the Stage-4 CIAC-1 method, which false-fails.*

*Predicate:* after both land, the armed probe returns a **non-vacuous** clean verdict, the backfilled `v3.69.1` row is **provably out of scope**, and the arm row is the intended one.

*Why the Stage-4 method was defective:* it asserted that stdout matches `CLEAN [1-9]`. The probe emits **no literal `CLEAN`** — its clean verdict string is `close-completeness: <n> VERIFIED release(s) in scope have the complete Stage-13 output-set — OK`, and both callers strip the token. The corrected method matches on `[0-9]+ VERIFIED`.

*Method:*

```bash
OUT="$(bash core/deploy/deploy.sh --check-close-completeness 2>&1)"; RC=$?
printf '%s\n' "$OUT" | grep -qE '[0-9]+ VERIFIED release\(s\) in scope' && [ "$RC" -eq 0 ]
printf '%s\n' "$OUT" | grep -qE 'in scope have the complete Stage-13 output-set — OK'
N="$(printf '%s\n' "$OUT" | sed -nE 's/.*: ([0-9]+) VERIFIED release\(s\).*/\1/p')"; [ "$N" -ge 1 ]
A="$(grep -nE '^\|[[:space:]]*v3\.69\.1[[:space:]]*\|' release/releases/RELEASE_LOG.md | cut -d: -f1)"
B="$(grep -nE '^\|[[:space:]]*v3\.89[[:space:]]*\|'   release/releases/RELEASE_LOG.md | cut -d: -f1)"
[ "$A" -lt "$B" ]                                         # backfilled row precedes the arm row
printf '%s\n' "$OUT" | grep -q 'armed at LOG row v3.89'   # the arm row is the intended one
```

The third clause closes the prefix-match hazard at the acceptance surface: the criterion as originally written could pass with the **wrong** arm row.

**CIAC-2 (#3727 × #3113 on ledger row-count parity).**
*Predicate:* the `RELEASE_INDEX` release-row count equals the `RELEASE_LOG` release-row count on the merged PR — the invariant #3113 AC4 turns into a regression guard. Baseline **149 / 149**; expected after the backfill **150 / 150**.
*Method:* `test "$(grep -cE '^\|[[:space:]]*v[0-9]' release/releases/RELEASE_INDEX.md)" -eq "$(grep -cE '^\|[[:space:]]*v[0-9]+\.[0-9]+' release/releases/RELEASE_LOG.md)"`

**CIAC-3 (#3113 × #2422 on `release/tools/automated-closeout.sh`).**
*Predicate:* two issues co-editing one large script leave every contract intact — the self-test suite passes, the path probe passes, **and** the path probe still hard-fails on a genuine resolution defect.
*Method:* `bash release/tools/automated-closeout.sh --self-test` → exit 0; `--check-paths` → exit 0; then re-point one corpus path at a non-existent file and re-run → exit non-zero.

**CIAC-4 (#4176 × #3113 on gate-posture honesty).**
*Predicate:* every close-completeness posture surface agrees with live state, and **no surface reads "armed" while asserting zero rows**. The enforce sentinel, the check mode, and the armed cutoff are mutually consistent; the armed cutoff resolves to a real `RELEASE_LOG` row; and the reported in-scope row count is never zero. This is the release's thesis as a testable predicate — *a gate that skips silently reads identically to a gate that passes.*
*Method:* run the probe and assert the reported in-scope row count is `>= 1` and matches an independent count of VERIFIED `RELEASE_LOG` rows at or after the armed cutoff; assert the enforce-sentinel token is one of `warn` / `enforce` and that this plan records which.

## Risk Register

Severity · Reversibility tier · Confidence.

**R1 — Sibling milestone #298 shared edit-set. `[CRITICAL · MODERATE · HIGH]` — RE-RENDERED.**
Milestone #298 `release-closeout-integrity` intersects this release on **five files** (table above). The Stage-4 remediation read *"#304 merges first and #298 re-baselines (#304 is further along — it has a plan)."* **That premise is now false** — #298 pushed an Engineering Commit 0 with a plan file to `origin` within ten minutes of this release's Stage-5 scope-lock, and a third milestone did the same. Nothing in the repo mechanically prevents it, and a governance prohibition written into #298's own description did not prevent it either: **a governance record is not an interlock.**
**Disposition — re-rendered on different grounds, not re-asserted: this release PROCEEDS and races to land first.** The grounds are design-completeness and size, not commit count: this release is 5 issues / 20 pts with every Stage-5 specification implementation-ready, while #298 carries substantially more open scope and has so far touched only its own plan file. The race is acknowledged, not assumed away.
**If this release lands second:** it re-baselines five files. Three of them carry `merge=union` and take both sides; `RELEASE_LOG.md` conflicts loudly and is resolved by hand, which is the correct behaviour for a state-bearing ledger. **MODERATE, not EXPENSIVE.**
**Standing mitigation:** re-run the sibling-merge self-invalidation trigger — `git log <release-base>..origin/main --name-status --find-renames` intersected with this release's surface — at Stage 9 entry. This is already mandated; R1 is the concrete reason it matters here.

**R2 — Check-48 arming self-collision. `[HIGH · CHEAP · HIGH]`**
A cutoff at or before `v3.89` puts pre-existing legacy close-out debt into scope: `v3.88` → 1 finding, `v3.85` → 1, `v3.80` → 2, `v3.70` → 6, `v3.69` → 6 (10 once the backfilled row lands).
**Correction to the recorded rationale — the `v3.89` bound does NOT rest on "it would turn this release's PR red."** That claim is false: the enforce sentinel reads `warn` and the probe exits **0** at `v3.69`, `v3.88`, and `v3.89` alike. The bound stands on **calibration integrity**: a warn log pre-poisoned by known legacy debt cannot evidence the ">= 3-day warn review with zero false positives" threshold that gates the flip to enforce. Arming lower would not break the build — it would silently destroy the shakedown's evaluability, which is worse, because the failure is invisible.
**Mitigation:** bound the cutoff to `>= v3.89` (E1a) and require Stage 7 to record the literal reported in-scope row count with `n >= 1`.

**R3 — #3113 oversize / partial completion. `[HIGH · MODERATE · HIGH]`**
Eight ACs across six-plus files on a single `size:L` card inside a 20-pt release; the card's own body records tripping the decomposition predicate. A partially-satisfied umbrella cannot be marked closed, which blocks milestone close.
**Mitigation:** D-I rendered **keep-whole-but-narrow**. The internal build order front-loads the isolated ACs so partial progress is still shippable, and places the two probably-already-resolved ACs last so effort is not spent building what exists. If Stage 6 finds AC1's detector materially larger than estimated, split becomes the correct answer and the decision is re-rendered rather than defended.

**R4 — Class re-classification busts the capacity band. `[MEDIUM · MODERATE · HIGH]`**
If #3113's AC3 lands as a new criterion in `core/schemas/gate-criteria-spec.md`, the release touches three of the seven named governance surfaces and fires the `cross-cutting` trigger. At weight 1.3 that is `20 × 1.3 = 26 > 25` — a capacity breach with a split disposition.
**Mitigation:** the AC3 re-scope makes the edit *smaller* — a posture question on an existing criterion rather than a new one — which may keep the file out of the matrix entirely. The matrix marks it CONDITIONAL for exactly this reason.

**R5 — The backfill is incomplete against the canonical output set. `[MEDIUM · CHEAP · HIGH]` — RESOLVED by D-J.**
The canonical Stage-13 output set is five artifacts plus tag plus published Release; #3727's criteria name four. Two concrete consequences of shipping four: (a) every one of the 149 existing `RELEASE_INDEX` rows carries a Release Notes link, so a `v3.69.1` row either links a non-existent file or breaks the row shape; (b) the release-link checker **deliberately skips** all `_RELEASE_NOTES.md` link targets, so a dangling link would ship **silently and permanently** — no gate catches it.
**Resolution:** D-J = (B). Five artifacts. The over-delivery against the card's literal criteria is recorded as a Tier-1 adjustment rather than absorbed silently.

**R6 — #2422's completion condition is unfalsifiable as written. `[MEDIUM · CHEAP · MEDIUM]`**
Its AC1 antecedent is false today — there is no instance-aware resolution — so the criterion is vacuously satisfied: the path probe already exits 0. **Confirmed at Stage 5:** pointing the instance-path variable at a nonexistent directory also exits 0, because nothing reads it. The naive tolerance test would be green for the wrong reason.
**Mitigation:** D-H = (A)+(D). The red-today regression test must be constructed against an instance-homed-corpus fixture — the only construction that is genuinely red today.

**R7 — AC-currency drift inside #3113. `[MEDIUM · CHEAP · HIGH]`**
Four of eight ACs moved against live `main` since filing (details in the Deviation Log). Left unreconciled, Stage 8 grades against stale predicates and either false-fails or false-passes.

**R8 — Cutoff prefix-match hazard. `[LOW · CHEAP · HIGH]`**
The cutover arms on the first `RELEASE_LOG` row satisfying a **string prefix match, not a version comparison**. `v3.9` prefix-matches `v3.90`…`v3.99`; `v3.10` prefix-matches `v3.100`. A plausible typo silently arms at the wrong row with no error.
**Mitigation:** the arming change records the *resolved* row count and the *resolved* arm row at runtime, so a wrong cutoff shows up immediately. INT-1 clause three grades it. Replacing the prefix match with a real version comparison is routed to intake as its own card — it is not absorbed into a `size:S` arming ticket.

**R9 — A vacuously-armed gate. `[LOW · CHEAP · HIGH]`**
Setting the cutoff to a version with no `RELEASE_LOG` row yields zero rows in scope, which reads identically to a passing gate.
**Mitigation:** DT asserts `n >= 1`, never merely exit 0.

**R10 — Rollback complexity. `[LOW · CHEAP · HIGH]`**
The only change with repo-wide verdict impact is #4176's arming, and it reverts in one edit.

## Quota Budget

**Verdict: WARN.** Parallel-eligible spokes: Stage 5 = 4 · Stage 7 = 5 · Stage 8 = 5.
**Per-spoke cost estimate:** size-bucket ordinal band — #4176 S and #3727 S lowest · #1550 M and #2422 M low-to-moderate · #3113 L moderate-to-high. *Source: heuristic, not telemetry* — the per-bucket telemetry cutover predicate has not been evaluated for these buckets, so the ordinal band is retained as the floor.
**Worst parallel batch:** Stage 7 or Stage 8 — five concurrent spokes spanning `S+S+M+M+L`, a size-weight proxy of 20 against a release band whose upper bound is 25, fired as one wave. Against a conservative (operator-unstated) envelope this lands in the WARN band.
**Routing:** window-aware launch timing plus a split batch. **Wave A = {#3113}** alone; **wave B = {#4176, #3727, #1550, #2422}**. This caps any single wave's cumulative draw at roughly half the unsplit batch. Stage 5 needs no split.
**Note:** this checkpoint is advisory. The load-bearing gate is the pre-wave re-validation the hub runs before every parallel wave against the *remaining* envelope. This is a cumulative-draw budget, not a rate-limit problem — staggering is a rate-limit defense and is never the mitigation for a window overrun.

## Rollback Strategy

D-C `SINGLE` means one release branch, one PR, one merge — so `git revert -m 1 <merge-sha>` restores all five issues atomically (**CHEAP · HIGH**). Per issue:

- **#4176 — CHEAP.** Revert the carrier edit; the cutoff returns to its unset sentinel and the gate returns to documented dormancy. No data touched.
- **#3727 — CHEAP.** Line-deletes on four ledgers plus one file removal. `merge=union` on INDEX/DIGEST/CHANGELOG makes the revert clean; `RELEASE_LOG.md` is a single-row delete.
- **#3113 — MODERATE.** Largest blast radius: two scripts plus a governance file plus (conditionally) a schema. Revert is mechanical but touches the close-out path every release runs — re-run `automated-closeout.sh --self-test` after any revert.
- **#1550 — CHEAP.** A standalone tool plus its invocation step; removing it restores the current manual-register status quo.
- **#2422 — CHEAP.** A spec anchor, a comment, and a test. Single-commit revertible.

## Operator Decisions (D-Gate Block)

All six D-decisions were rendered by the operator at the Procedure 0 gate on 2026-07-30 (Thursday). **These are recorded verdicts, not open questions — do not re-open them as gates.**

| Decision | Verdict | Spoke recommendation | Divergence |
|---|---|---|---|
| **D-A Release Class** | **`novel`** | `novel` | — |
| **D-E Check-48 arming** | **committed default in `core/deploy/deploy.sh`, cutoff `v3.89`** | same | — |
| **D-G Register producer** | **(C)** new standalone tool `release/tools/produce-learnings-register.sh` | (C) | operator chose the spoke recommendation over the reuse-first-implied in-script option; recorded as a deliberate override |
| **D-H #2422 done-condition** | **(A)+(D)** spec anchor + red-today regression test | (A)+(D) | — |
| **D-I #3113 disposition** | **(C)** keep whole but narrow | (C) | — |
| **D-J Backfill scope** | **(B)** four ledgers **plus** `release/releases/notes/v3.69.1_RELEASE_NOTES.md` | (B) | — |

**Class rationale.** The milestone declared `routine`; that class requires **zero** new D-class decisions in the release plan and this plan carries **six**, so trigger (d) fails categorically. `novel` fires on the same evidence. Capacity is safe at `20 × 1.15 = 23 <= 25`; `cross-cutting` would be `26 > 25` and breach — which is why R4 watches the AC3 surface count.
**Differentiation posture under `novel`:** engagement density Standard · Stage 9 review depth **Deep** · Stage 5 activation bias ALL (one evidenced exception, #3727) · Stage 13 outcome window **30-day**.

**Recorded determinations (not gates):**

- **D-C Branch Topology = `SINGLE`.** One milestone, one PR, one merge. The release's dominant contention is a single-file overlap that a multi-PR topology would relocate to merge order rather than remove, at the cost of extra chore PRs.
- **D-Concurrency Posture = `P0` (fully-serial).** One Engineering chip at a time; the next chip waits until the prior commit lands on this branch. **Force-push — including `--force-with-lease` — is prohibited on this shared release branch under any multi-chip activity.**
- **D-Version = deferred to the Stage-12 atomic claim.** No version token pre-claim. See § Release Identity.

## Deviation Log

Departures from the Stage-4 plan, with severity. Each is recorded here rather than silently applied.

| # | Deviation | Severity | Basis |
|---|---|---|---|
| 1 | **Version deferred; plan file and branch are slug-only.** The Stage-4 plan targeted a version-prefixed plan filename. | scope (release identity) | Operator re-render of D-Version, 2026-07-30, recorded on sub-task #4294. The pre-claim version token was removed entirely rather than re-pointed at a different number. |
| 2 | **CIAC count 5 → 4, and CIAC-1's method replaced.** CIAC-5 withdrawn; CIAC-1 superseded by `INT-1`. | minor | CIAC-5 is a consequence of D-G = (C). CIAC-1's method asserted a literal `CLEAN` token the probe never prints — it would have false-failed. |
| 3 | **Contention Map corrected from 3-way to 1 substantive editor** on `release/tools/automated-closeout.sh`. | minor | Live verification at Stage 5: #1550 touches the file not at all under D-G = (C); #2422's edit is a four-line header comment. |
| 4 | **File Change Matrix: one path removed, four added.** | minor | Scope-lock verdicts — the anchor-hygiene script dropped (`extend` over new); the allowlist and smoke-workflow added as prerequisites; the versioning-standard See-also and the joint ADR approved. |
| 5 | **#3113 AC4's data backfill routed out; the `v3.80` re-tag deferred.** | scope | Scope-lock verdicts. Mirrors the mechanism/data split already agreed with the sibling content card in milestone #298. |
| 6 | **The `v3.89` bound's recorded rationale corrected** from "an earlier arm point turns this release's PR red" to **calibration integrity**. | minor (record accuracy) | The stated reason is disproven — the probe exits 0 at `v3.69`, `v3.88`, and `v3.89` alike and the enforce sentinel reads `warn`. Leaving a false rationale on the record invites a future reader to "safely" arm lower and silently destroy the shakedown's evaluability. |
| 7 | **#3727 ships five artifacts where its acceptance criteria name four.** | minor (additive, in-plan) | D-J = (B). Recorded as a Tier-1 adjustment on sub-task #4294 for operator-batched application; the issue body is historical record and is not auto-amended. |
| 8 | **#3113 AC currency:** AC3's population re-measured and both claimed enforcement points found to already exist; AC4 re-framed from a count claim to a set claim; AC5's method narrowed to **annotated** tags (its stated method returns three rows, two of which are lightweight tags — a different defect class, so the criterion is unsatisfiable by fixing the one malformed identity); the Affected-Files over-correction that removed the corpus linter restored. | minor | Stage-5 findings, batched for one operator-approved body edit. |
| 9 | **A note file is authored for a patch release.** The release-notes standard's File Location section states that a hotfix emits no separate notes file. | minor (conflict, resolved by verdict + precedent) | D-J = (B) governs. Both prior patch releases (`v3.65.1`, `v3.73.1`) carry notes files, the corpus filename regex admits the three-component form, and every `RELEASE_INDEX` row carries a resolving notes link. The standard's clause is inconsistent with its own corpus; reconciling it is routed to intake, not done here. |

## Closure Phrasing

Every issue in this release is **marked as closed at Stage 13** via the automated close-out path, not auto-closed from the release PR. This plan is transcribed into PR bodies at Engineering, where the auto-close parser fires on close-family verbs adjacent to an issue reference **regardless of section context or surrounding negation**. Safe phrasing is used throughout this plan and must be preserved in transcription.

## Change Description

Operator-facing. Authored incrementally as each Engineering chip lands, per the Change Description Protocol, and complete before this PR is transitioned out of draft at the Stage 9 gate.

### Outcome

After this release, the release close-out output set is trustworthy as read: every published release's ledger footprint is complete, and the gate that grades that completeness is armed against a real row rather than evaluating dormant.

### Issues resolved

| Issue | Contribution | Status |
|---|---|---|
| **#3727** | Complete Stage-13 output-set backfill for `v3.69.1` — `RELEASE_LOG` row plus its visible-H4 Deployment Log block, `CHANGELOG` section, `RELEASE_INDEX` row with a resolving notes link, `RELEASE_DIGEST` entry, and the authored release-notes file. INDEX/LOG row parity moves 149/149 → 150/150. | DONE |
| **#4176** | Arms the close-completeness gate via a committed default carrier at cutoff `v3.89`. | pending |
| **#3113** | Close-out script and corpus-linter hardening — scaffold-residue detection, pre-authored-note acceptance, executed primary-checkout sync, anchor-parity guard, protocol file-structure reconcile. | pending |
| **#1550** | Standalone automated filled-register producer plus its Stage-13 invocation step. | pending |
| **#2422** | Instance-absence tolerance recorded as a corpus spec anchor plus a red-today regression test. | pending |

### Key decisions

Six operator decisions were rendered before Engineering — release class, the arming carrier and its cutoff value, the register producer's siting, #2422's done-condition, #3113's disposition, and the backfill's scope. All six are recorded in § Operator Decisions with their bases. The seventh determination, D-Version, was re-rendered to **defer the version to the Stage-12 atomic claim**, which is why this plan carries no version token.

### Reversibility

**CHEAP · HIGH** at release scope — one merge, revertible with `git revert -m 1`. The one MODERATE surface is #3113's edits to the close-out path every release runs; re-run its self-test after any revert.

### Downstream impact

The armed close-completeness gate begins reporting against real rows from its cutoff forward. It ships in **warn** posture, so no PR is blocked by this release; the flip to enforce is a later operator decision gated on a clean warn-log review window — which is precisely why the cutoff is bounded at `v3.89` rather than lower.

### Cross-references

- Milestone: `closeout-output-set-integrity` (#304)
- Stage-4 release plan and the Procedure-0 decision record: sub-task #4239
- Stage-6 Engineering Commit 0 and the D-Version re-render: sub-task #4294
