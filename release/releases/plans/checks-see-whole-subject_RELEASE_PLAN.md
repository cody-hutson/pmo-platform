---
title: Release Plan — checks-see-whole-subject
purpose: Stage-4 release plan for the nine defects in which an enforcement surface evaluates less than its declared subject and reports clean over the remainder.
type: release-plan
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->

# Release Plan: checks-see-whole-subject — A Check Evaluates Its Whole Declared Subject

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure via `release/tools/claim-version.sh --bump minor --dry-run`: next-free is **v4.39**. Corroborated independently — highest claimed tag is `v4.38`, and the highest `v4.x` row in the release ledger is `v4.38`. `v4.39` is absent from origin's tag set and from the ledger, with a firing control arm on `v4.38` in both populations. |
| **Date Created** | 2026-08-24 (Monday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/checks-see-whole-subject |
| **PR** | (populated at Stage 6 PR creation) |
| **Milestone** | checks-see-whole-subject |
| **Release Class** | `cross-cutting` — re-rendered from `routine` at the Stage-4 D-ReleaseClass gate (`class_weight` 1.3) |
| **Raw points** | **30** — bundling baseline 24, plus #4992 `size:M`→`size:L` (D-3) and #4720 `size:S`→`size:M` (D-9) |
| **Effective points** | **39** — `round_half_up(30 × 1.3)`. **+14 over the 25-pt G3-15 ceiling, shipped under a recorded operator override.** Membership unchanged at 9; no card trimmed to reach the band. |
| **Branch topology** | **SINGLE** (D-C) — one branch, one PR, one merge gate |
| **Concurrency posture** | **P0 fully-serial.** Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `8dc00db1` — the Stage-4 pin, still current at Engineering Commit 0 |

### Release Outcome Statement

**AFTER** this release: a check evaluates its whole declared subject — no silent truncation, scope gap, or blind arm.

**BEFORE:** checks silently scan a subset and report clean over the remainder.

### Differentiation posture (`cross-cutting`)

| Facet | Setting |
|---|---|
| Engagement density | Tight |
| Stage 9 review depth | Deep |
| Stage 5 activation bias | ALL |
| Stage 13 outcome-window | 30-day |

---

## Scope

### Issues Included

| # | Issue | Title | Priority | Size | Band |
|---|-------|-------|----------|------|------|
| 1 | #4981 | `git grep -E` silently returns zero for boundary-escape patterns — count-cascade sweeps can report a false CLEAN | P2 | S | foundation |
| 2 | #4720 | `fetch_stage_titled` silently truncates at the search 1000-cap against a ~2988 population | P2 | M | infra |
| 3 | #5260 | `blast-radius.sh` reports `second_order_count` 0 at depth 1, indistinguishable from a measured empty set | P2 | S | infra |
| 4 | #5074 | `blast-radius.sh` enumerates git-ignored trees, inflating every impact denominator | P2 | S | infra |
| 5 | #4734 | Check 35 classifies single-mode skills as multi-mode by matching a mode marker anywhere in the file | P2 | S | skill-core |
| 6 | #4992 | Token-registry conformance check reaches only half the token surface — one prefix, one file extension, three of four roots | P2 | L | skill-core |
| 7 | #4440 | Check 45(b) drift guard is fragment-based: repointing the b-loop input makes the check a silent no-op that still declares success | P2 | S | skill-core |
| 8 | #5252 | Seven workflows still carry absent-is-pass — disposition each trigger-vs-verdict scope | P2 | M | eval |
| 9 | #4931 | Section anchors cited in issue bodies are never validated against the referenced file | P2 | S | eval |

Point scale: `XS=1 / S=2 / M=4 / L=8 / XL=16`. Raw sum 30; `effective_pts` 39 at `class_weight` 1.3.

### Dependency Graph

No hard build-blocking edge exists between any two cards. Every edge is **soft** — informational or substrate-currency — and the direction is load-bearing even though the blocking is not. The operator ruled at D-ReleaseClass that soft edges count as compositional edges for `cross-cutting` trigger (c); three such edges are enumerated, meeting the threshold.

```
#4981 ──soft(idiom)──▶ every card's control arm
                       (prescribes the whole-token matching idiom the
                        falsification arms are authored against)

#4720 ──soft(precedent)──▶ #5260
                       (#5260 names check-milestone-epic-membership.py's
                        status-handling pattern as the shape to follow)

#5260 ──soft(vocabulary)──▶ #5074
                       (#5074's non-git scan-scope case is a not-computed
                        state; it consumes #5260's typed-status slot)

#4734, #4992, #4440 ── mutually independent (same file family, line-disjoint)
#5252, #4931       ── independent; no in-bundle upstream
```

**Cycles: zero.** Four directed edges over nine nodes, enumerated by hand from issue-body citations and walked for cycles. Sensitivity arm: inserting `#5074 → #5260` alongside the existing `#5260 → #5074` produces a detected 2-cycle, so the walk discriminates. Specificity arm: the acyclic set as authored returns zero cycles.

**Native dependency mirror:** all nine report `blocked-by:` and `blocking:` empty on the GitHub Dependencies surface. Consistent with a soft-only edge set — soft edges are correctly not mirrored as native blockers.

---

## Implementation Sequence

Build order per operator decision **D-5** (the Stage-4 spoke's divergence inside the infra band, adopted):

| Position | Issue | Band | Note |
|---|---|---|---|
| 1 | **#4981** | foundation | Lands the whole-token matching and engine-parity guidance every later card's control arm is authored against. |
| 2 | **#4720** | infra | Its status-handling pattern is the precedent #5260 reads; landing it first keeps that precedent current. |
| 3 | **#5260** | infra | Establishes the typed-status mechanism and the `stats_extra` seam. |
| 4 | **#5074** | infra | Consumes the vocabulary #5260 established. |
| 5 | **#4734** | skill-core | Two predicate sites — the check body and its report mirror. |
| 6 | **#4992** | skill-core | Two arms on the token surface, not three. |
| 7 | **#4440** | skill-core | Pins the b-loop input selector inside the test. |
| 8 | **#5252** | eval | Seven workflows, one disposition sweep. |
| 9 | **#4931** | eval | Last is correct — it benefits most from the preceding eight landing first. |

**#5260 and #5074 build as ONE Engineering unit** (operator decision **D-4**). They are the release's only genuine same-region collision — the same emit block and the same self-test suite — and #5074's hermeticity problem is solved by #5260's typed-status mechanism. Both cards remain open with their own sub-tasks, their own acceptance criteria and their own closure records; the merge is of the *build*, not of the tickets.

**Concurrency posture is P0 fully-serial.** The hub routes one Engineering chip at a time in the order above; the next chip waits until the prior commit lands on the release branch.

---

## Stage Applicability Matrix

Stage 5 is a **release-level** verdict — the All-or-Nothing Rule in [`/core/standards/planning-solutioning-handoff.md`](/core/standards/planning-solutioning-handoff.md) § 2 disables per-issue routing. Triggers T3, T4 and T6 fire on the bundle. **Release-level Stage 5 verdict: ACTIVATE, all nine.**

| Issue | S5 | S6 | S7 | S8 | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|
| #4981 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4720 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #5260 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #5074 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4734 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4992 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4440 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #5252 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4931 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |

**Stages 10 and 11 are PLATFORM-SATISFIED and already closed.** The PR diff is the dry run and git history is the snapshot; no agent action is required. The documented escape hatches — non-git deployments, database state, external integrations, binary artifacts, multi-system coordination — are absent from this release's entire change spec.

**Stage 2 Applicability correction, resolved at Commit 0.** The Stage-4 matrix carried T2 (skill logic changes) as CONDITIONAL, gated on whether #4981's worked probe record landed in a skill reference. #4981's design places the worked record in `core/disciplines/review-discipline-principles.md` § 8.2, **but the card edits a skill reference anyway** for its gate-clause change. **T2 resolves to ✓.** The release-level verdict is unaffected — ACTIVATE already held via T3/T4/T6.

---

## File Change Matrix

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-24, domain: governance }`

Every path is an internal platform artifact — deploy and CI tooling, pipeline specs, standards, disciplines and their fixtures. Secondary domain `software` on the executable surfaces. Dominant domain recorded as `governance`; sourcing-exempt, domain-classified.

**This matrix is the Stage-4 matrix corrected upward against each card's Stage-5 design as amended.** Several cards expanded; one withdrew a file. Every `CONDITIONAL:` row from the Stage-4 matrix is resolved below and carries its concrete path — a row left conditional after its condition has resolved is an authoring defect.

### #4981 — probe validity and engine parity (4 files)

```
core/disciplines/review-discipline-principles.md                          edit
release/references/pipeline/stage-05-solutioning.md                       edit
core/skills/pmo-qa-auditor/references/cascade-completeness-detection.md   edit
core/ADRs/ADR-146-word-boundary-matching-is-engine-parity-not-syntax.md   add
```

Resolves Stage-4 `CONDITIONAL:4981-probe-in-skill` — the row **fires**, but on a re-stated condition. The worked probe record lands in the discipline file, not the skill reference; the skill reference is edited for the gate-clause change instead. Editing a skill's `references/` is a skill edit: the `.skill` package and its content-baseline sidecar rebuild in the same PR.

### #4720 — transport truncation (3 files)

```
core/deploy/tools/check-milestone-epic-membership.py                      edit
core/deploy/deploy.sh                                                     edit
core/deploy/tools/README.md                                               edit
```

### #5260 + #5074 — blast-radius scope and status (8 files, one joint matrix)

Both cards declare the same 8-row matrix because they build as one Engineering unit.

```
release/tools/blast-radius.sh                                             edit
release/tools/lib/schema-v1-emit.sh                                       edit
release/tools/tests/test_structural_blast_radius.sh                       edit
release/tools/tests/fixtures/blast-radius-f1/normalized-golden.json       regenerate
release/tools/tests/fixtures/blast-radius-f1/verify-golden.sh             edit
release/tools/tests/fixtures/blast-radius-f1/README.md                    edit
release/references/protocols/blast-radius-protocol.md                     edit
release/references/templates/design-review-checklist.md                   edit
```

### #4734 — mode-arity predicate (1 edit + 1 add + 1 companion) — **as built**

```
core/deploy/deploy.sh                                                     edit
core/deploy/tools/check-mode-declaration-residual.py                      add
core/deploy/allowlists/selftest-coverage-manifest.txt                     edit   (companion)
```

**Expansion surfaced, not absorbed.** The card's own Stage-5 round-3 amendment states `deploy.sh` is "still the sole file" and, in the same amendment, introduces instruction 1i: land the acceptance oracle as a checked-in `python3` script under `core/deploy/tools/` rather than a session artifact. Those two statements cannot both be true. The added script also triggers the new-executable companion obligation — an allowlist row and stated CI wiring in the same release. **This is a matrix expansion the card did not restate as one; it is recorded here so Stage 9 reviews it rather than discovering it in the diff.**

**The companion resolved to a different file than the matrix predicted, and the substitution is the point.** The predicted companion was a `script-execution-allowlist.txt` row. **No such row is owed**: `BLOCK-DESTRUCTIVE-022` adjudicates only the `bash`/`sh`/`zsh` and `source`/`.` verbs, and this tool is a `.py` invoked through `python3`. Measured across the whole directory — **0 of 24** `core/deploy/tools/*.py` carry a row, against a firing control of **7 of 13** for the `.sh` population there — so the convention is confirmed at population scale rather than asserted. What the tool *does* owe is **CI wiring**, and that is the manifest edit: `release-tooling-smoke.yml` DISCOVERS every tool under `core/deploy/tools/*.py` that dispatches on `--self-test` and runs it, with `core/deploy/allowlists/selftest-coverage-manifest.txt` as the committed floor. The gate caught the omission on its own — `check-selftest-coverage.py --reconcile` failed Arm B(ii) naming the unlisted tool — and passes after regeneration. **Zero workflow edits; the wiring is by discovery, and the discovery was verified to fire rather than assumed.**

### #4992 — token-surface reach (4 files, one withdrawn)

```
core/deploy/deploy.sh                                                     edit
core/standards/depersonalization-spec.md                                  edit
CHANGELOG.md                                                              edit   (allow-marker)
docs/scripts/setup-workspace.sh                                           edit   (allow-marker)
core/ADRs/ADR-<n>-token-surface-reach.md                                  add    (number at Commit 0)
```

**Withdrawn — do not create:** `core/config/allowlists/token-registry-uncodified.txt`. Its round-3 amendment strikes the row explicitly. The un-codified set is derived live from the spec table and the enumerated corpus; if the #4992 Engineering chip finds itself writing a list of token names to disk, the amendment has been mis-read.

**Conditional, operator-gated:** `.github/workflows/repo-integrity.yml` enters only on an affirmative answer to that card's D-14. It is **not** created speculatively.

### #4440 — drift-guard input selector (2 files)

```
core/deploy/tests/test_check45_governing_doc_name_match.sh                edit
core/standards/gate-efficacy-standard.md                                  edit   (falsification column, additive)
```

`core/deploy/deploy.sh` is **READ-only** for this card — the fix pins the selector inside the test; the check itself is unchanged. The second row is a spoke-level expansion over the Stage-4 declaration of one row.

### #5252 — absent-is-pass disposition (8 declared → **10 as built**)

```
.github/workflows/close-completeness.yml                                  edit   (BIND + graduation-note)
.github/workflows/deploy-check-ci.yml                                     edit   (CONVERT)
.github/workflows/release-corpus-completeness.yml                         edit   (RECORD: graduation-note only)
.github/workflows/release-link-check.yml                                  edit   (CONVERT)
.github/workflows/release-tooling-smoke.yml                               edit   (BIND)
.github/workflows/skill-license-check.yml                                 edit   (CONVERT + invariant-line correction)
.github/workflows/version-freeness.yml                                    edit   (BIND)
core/standards/gate-efficacy-standard.md                                  edit   (Requirement (b) criterion + register rows)
.github/workflows/install-tests.yml                                       edit   (was declared READ-only — see below)
core/deploy/tests/test_gate_efficacy_declarations.py                      add    (the declared-vs-actual ratchet)
```

Resolves the four Stage-4 `CONDITIONAL:tier-a-disposition` / `CONDITIONAL:tier-b-disposition` rows into 3 CONVERT / 3 BIND / 1 RECORD.

**Expansion surfaced, not absorbed.** Two rows are additions to the Stage-5 matrix and both follow from adversarial-review findings the operator ruled in as Stage-6 correction items, not from scope creep discovered mid-build. **`install-tests.yml`** was declared READ-only for #4440 and is edited here for two reasons: it asserts, in two separate passages, that `release-tooling-smoke.yml`'s `paths:` filter omits `core/deploy/deploy.sh` — which this card makes false — so leaving them would ship a declared-vs-actual mismatch inside a card whose whole subject is declared-vs-actual accuracy (CIAC-4 obliges the declaration to change in the same commit as the reach); and it is the host for the ratchet below, chosen because it carries no `paths:` filter of its own. **`test_gate_efficacy_declarations.py`** is CD-1's ratchet. **Its new-executable companion obligations were checked rather than assumed and all three resolve to nothing owed** — no `script-execution-allowlist.txt` row (all 257 non-comment rows are `.sh`; 0 are `.py`, and this is a `.py` invoked through `python3`), no `selftest-coverage-manifest.txt` row (the discovery globs are `core/deploy/tools/*.{py,sh}` and `*` does not cross `/`), and no Arm D surveillance (its globs are the two `tests/` trees, neither of which is `core/deploy/tests/`). The one obligation that *is* owed — CI wiring — is the `install-tests.yml` step.

**This card is a two-writer on `core/standards/gate-efficacy-standard.md` (Contention Map rank 4) and it landed second.** #4440's single in-place line change is byte-identical and intact; its coordinate moved 176 → 198. See § Verification Evidence for the full landing coordinates and for the merge-conflict hunks against concurrent draft PR #6119, which edits two of the same workflow files.

### #4931 — issue-body section-anchor validation (7 declared → **9 as built**)

```
core/deploy/tools/check-issue-body-anchors.sh                             add    (D-4931-Landing: new tool)
core/deploy/tools/fixtures/issue-body-anchors/                            add    (11 files: README + 7 bodies + 3 targets)
core/config/allowlists/script-execution-allowlist.txt                     edit   (companion; 4 rows, per-tool form)
core/deploy/allowlists/selftest-coverage-manifest.txt                     edit   (1 row; REGENERATED via --emit-manifest)
core/deploy/deploy.sh                                                     edit   (Check 71 block)
release/references/pipeline/stage-02-triage.md                            edit   (A4.8 advisory criterion)
release/references/how-to/intake-style-guide.md                           edit   (new §2d + one §6 cross-ref row)
core/standards/reference-durability-standard.md                           edit   (one appended paragraph)
core/ADRs/ADR-145-anchor-resolution-is-a-surfacing-instrument-not-a-gate.md  add
```

Resolves Stage-4 `CONDITIONAL:d-4931-new-file` — **fires**. D-4931-Landing resolved to a new tool rather than an extension of the existing issue-reference gate; `CONDITIONAL:d-4931-extend` resolves **NOT-TAKEN** and is struck. The required branch-protection context is **not touched**.

**D-14 settled by measurement, not by choosing a number.** The Stage-5 §A DR-6 row said "5 changed + 4 read-only" and the operator's D-14 record said "8 changed + 4 read-only"; the amendment's `unchanged` list carried the superseded 5 forward, which is pass-2 finding AC-5. Measured against the branch base, the as-built count is **8 changed** on §G's own counting convention (the fixture tree as one row) **plus the ADR = 9**. D-14's figure was the correct one.

**Two rows are net-new to the plan block, both pre-declared in the Stage-5 §G matrix rather than discovered late:** the regenerated selftest-coverage manifest row, and `stage-02-triage.md`. One declared path moved: the fixture corpus lands at `core/deploy/tools/fixtures/issue-body-anchors/` rather than under `tools/tests/fixtures/`, matching where the selftest-discovery engine's `core/deploy/tools/*.sh` scope directive actually looks.

**Two-writer note.** This card is the fourth writer on `core/deploy/deploy.sh` this release and it landed last, appending after Check 70 at a distance of roughly 3,500 lines from the nearest sibling hunk. No sibling shares any other path with it.ence validator, so the required branch-protection context is untouched and blast radius on required contexts stays zero. The `CONDITIONAL:d-4931-extend` row does **not** fire and is struck. The new-executable companion obligation is mandatory in the same release: the allowlist row plus stated CI wiring. Concrete filenames bind when the #4931 chip runs.

### Read-only inputs

```
core/deploy/deploy.sh                        READ  (#4440 — the b-loop selector is pinned FROM here, not changed)
core/deploy/tools/check-pv7-vocabulary.sh    READ  (#5260/#4720 — Register B gate; does NOT cover Register A)
.github/workflows/skill-package-freshness.yml READ (#5252 — filter-free exemplar, already converted)
.github/workflows/link-check.yml             READ  (#5252 — filter-free same-class exemplar)
.github/workflows/install-tests.yml          READ  (#4440 — the runner that invokes the test)
                                             ↳ RECLASSIFIED to `edit` by #5252 at position 8; #4440's read is unaffected — no step, job or trigger it depends on is modified
```

### Release-wide explicit non-scope

```
core/standards/depersonalization-spec.md § registry additions   NOT EDITED  (the name-unregistered angle-bracket tokens are separately owned scope)
core/config/allowlists/token-registry-uncodified.txt            NOT CREATED (withdrawn by #4992's round-3 amendment)
release/references/pipeline/stage-07-dev-testing.md             NOT EDITED  (#4981 routed its unqualified boundary-escape claim to a next-release issue)
core/rules/bypass-mode-readiness.md + its mirror                NOT EDITED  (#4981 accepted-residual; conservative security-hook posture)
core/standards/evidence-grounding-standard.md                   NOT EDITED  (#4981 routed the stale PV range string to a next-release issue)
```

### Package-rebuild consequence

```
packages/pmo-qa-auditor.skill                                             rebuild  (#4981 edits its references/)
packages/pmo-qa-auditor.skill.sha256                                      rebuild  (content-baseline sidecar)
```

Enforced pre-merge by the skill-package-freshness CI gate. The rebuild lands in the same PR as the reference edit, not at release-cut.

---

## Contention Map

| Rank | Shared surface | Issues | `overlap_class` | Operational risk |
|---|---|---|---|---|
| **1** | `release/tools/blast-radius.sh` and `release/tools/lib/schema-v1-emit.sh` | **#5260 × #5074** | `line-range-overlap` | **Resolved by construction** — D-4 merges them into one Engineering unit, one commit sequence, one test pass. |
| **2** | `core/deploy/deploy.sh` | **#4720 × #4734 × #4992 × #4931** | `line-range-overlap` (four in-release writers) | **MEDIUM-HIGH** — see the correction below. |
| **3** | `core/deploy/deploy.sh` × mainline | #4720/#4734/#4992/#4931 | `line-range-overlap` (cross-PR) | **MEDIUM** — highest-traffic file in the repo, roughly 10 commits per fortnight. |
| **4** | `core/standards/gate-efficacy-standard.md` | **#4440 × #5252** | `single-pr` | **LOW-MEDIUM** — see the correction below. |
| **5** | `core/config/allowlists/script-execution-allowlist.txt` | **#4734 × #4931** | `single-pr` | **LOW** — both append companion rows for a new executable; append-only, different rows. |
| 6 | `.github/workflows/*.yml` | #5252 (sole writer) | `single-pr` | LOW |

**Correction 1 — `deploy.sh` has four in-release writers, not two or three.** The Stage-4 map recorded two, corrected at D-6 back to three (#4734, #4992, #4720). #4931's design then landed a Check 71 block in the same file, making four. The hunks remain line-disjoint and marker-anchored, so conflicts should be textual rather than semantic — but a four-writer file under P0 serial execution is the release's largest sequencing constraint after the blast-radius pair, and the build order above already separates the four writers by three positions or more.

**Landed hunks in `deploy.sh`, recorded as each writer lands** — so the three writers after each entry can confirm line-disjointness against measured lines rather than against the plan's estimate.

| Writer | Position | Landed region (post-edit) | Anchor |
|---|---|---|---|
| **#4720** | 2 | **`10638`–`10687`** as landed; `10779`–`10828` after position 5; **now `10835`–`10884`** after position 6 (see the shift notes below) | Inside the Check-56 M3 leg, entirely AFTER the `C56-EMIT-END` sentinel — recorded at `:10615`, then `:10756`, **now `:10812`**. Anchored on the `CAVEAT:` comment text and on the existing `awk -F'\t' '$1=="…"'` reads, never on a line number. |
| **#4734** | 5 | Six regions, all disjoint from the above: **`2183`–`2344`** (the two new top-level helpers) · **`4601`–`4611`** and **`4645`–`4663`** (Check 5(d), per D-13) · **`9020`–`9058`** (Check 35 in `cmd_check`) · **`9126`** (one line) · `14124`–`14154`, **now `14180`–`14210`** after position 6 (the `c35r` mirror). The first five regions sit ABOVE position 6's block and are unshifted. File grows 14,218 → 14,359 lines. | Every site resolved by inline marker: the `# ─── Skill package content-freshness (Check 7 …` neighbour for the helper insertion, `# --- modes: set-equality`, `# Check 35 — Mode-invocation drift`, `log "Check 35:`, and `# --- Mode-invocation drift (Check 35) ---`. No line number was used to locate an edit. |
| **#4992** | 6 | One region: **`9777`–`9874`** (the Check 44 block, grown in place from `9777`–`9819`). Registry read `:9829`–`:9830`, derived prefix alternation `:9832`, the two enumeration limbs `:9843` (square, gating) and `:9850` (angle, advisory). File grows 14,359 → **14,415 split-lines / 14,414 newline-terminated** — the two units are named because the same file yields both. | Anchored on the `# Check 44 —` header comment and the `# (a)` / `# (b)/(d)` markers. No line number was used to locate the edit; the block's own recorded coordinates were re-derived from the header marker at build time and were **stale by +141** as inherited. |

**Shift note for positions 6 and 7 — read this before re-anchoring.** Position 5 inserts **162 lines at `:2183`**, which is ABOVE every other writer's region, and nets **+141 lines** at any point below `:9126`. Line numbers recorded by earlier writers are therefore stale by that amount, and the `#4720` row above has been reconciled rather than left to be discovered. **#4992** (Check 44, estimated `:9636`–`:9667`) and **#4931** (Check 71) should re-derive their own line numbers from markers at build time; the disjointness verdict is unaffected — the nearest approach between any two writers' regions is roughly 1,600 lines.

**Shift note for position 7 — position 6 has landed.** #4992's block grew **+56 lines in place at `:9777`**, so every coordinate BELOW `:9874` is stale by that amount and every coordinate above it is untouched. Both affected sibling rows above are reconciled to measured values rather than left to be discovered: #4720's block and its `C56-EMIT-END` sentinel, and #4734's `c35r` mirror region. The sentinel was re-measured by marker, not by arithmetic. **#4931** (Check 71) should re-derive from markers; the nearest approach from #4992's block to any other writer's region is **~650 lines** (down from ~960 before the growth, because the block grew downward toward #4720), so the disjointness verdict is unchanged and no conflict is expected.

**One row of the map moved by this position, and it is Rank 5.** `script-execution-allowlist.txt` is listed as a `#4734 × #4931` shared surface on the premise that both append a companion row for a new executable. **#4734 appends nothing:** its new tool is a `.py` invoked through `python3`, and `BLOCK-DESTRUCTIVE-022` governs only the `bash`/`sh`/`zsh` and `source`/`.` verbs. Measured across the whole directory: **0 of 24** `core/deploy/tools/*.py` carry an allowlist row, against a firing control of **7 of 13** for the `.sh` population. Rank 5 is therefore a **single-writer** surface (#4931 only), and its `LOW` risk drops to none for this pair.

**Correction 2 — `gate-efficacy-standard.md` is a two-writer surface.** #4440's design added it at DEC-5 as a spoke-level expansion; #5252 already carried it as its sole non-workflow row. Both edits are additive and target different rows — #4440 appends to the falsification column of one gate's row, #5252 amends register membership. The overlap was classified weak and logged by #4440's spoke rather than escalated. **It is recorded here because the Stage-4 Contention Map does not carry it**, and the build order places #4440 at position 7 and #5252 at position 8 — adjacent, which is the sequencing that makes an additive collision cheapest to resolve.

**Shift note for position 8 — position 7 has landed, and it moved nothing.** #4440's edit to `gate-efficacy-standard.md` is **one line, changed in place at line 176** (the `deploy.sh` Check 45(b) row), additive to the falsification column only. The file is **235 lines before and after — zero delta — so every coordinate in this file that #5252 inherits is still current**, and #5252 need not re-derive them. Verified by a structure-shaped probe over the whole file rather than the edited row alone: the escape-aware column-count profile is byte-identical across all five of the file's tables (`{2:5, 3:17, 4:5, 5:28}`), row 176 still splits into 5 cells, and **234 of 235 lines are byte-identical** with 176 the sole difference. The two writers' rows remain disjoint. **Contention rank 2 is also unaffected by this position:** #4440 changed **0 lines** of `core/deploy/deploy.sh`, confirmed by diffing the branch's two commits, so `deploy.sh` still carries four in-release writers and none of their landed coordinates move here.

**Cross-PR Overlap Audit — baseline `8dc00db1`.**

`### In-Flight Release Roster` — **Population: n=0**, recorded explicitly per audit-baseline discipline rather than omitted. Open PRs repo-wide measured at 0 against a whole-repo denominator, not a `release/*` filter, so the zero is not a filter artifact. The one remote `release/*` head at measurement time was an ancestor of `main` — a merged-and-undeleted branch, not an in-flight sibling. **Re-check obligation:** re-measure this population at Stage 9 before it is relied on; a single entry appearing later silently invalidates the row.

**Re-check discharged at position 8 — the n=0 baseline is INVALIDATED, exactly as the obligation anticipated.** Re-measured against the same whole-repo denominator: **n=1**. Draft PR **#6119** (`release/selftests-actually-test` → `main`) is open and **overlaps this release on two files, both of them #5252's**: `.github/workflows/install-tests.yml` (+236/−19) and `.github/workflows/release-tooling-smoke.yml` (+174/−2). The operator ruled **PROCEED and handle at merge**, so no disposition was adjusted to avoid the overlap and no file was left un-reconciled in order to keep a diff small. What position 8 owes instead is legibility, and it is discharged in § Verification Evidence: exact landing hunks in both files in new-file coordinates, plus a statement of what does *not* move — no job, matrix, trigger, step ordering or existing `run:` line in `install-tests.yml`; no step added, removed or reordered in `release-tooling-smoke.yml`.

**A second collision this re-check surfaced, belonging to neither card and routed rather than actioned.** PR #6119 claims `release/ADRs/ADR-142-…` while this branch already carried `core/ADRs/ADR-142-…` from position 1. ADR numbering spans BOTH directories, so that is a **duplicate claim between two unmerged releases** — a duplicate is tooled at merge where a gap would block, but it is a real conflict and someone should own it. It is not #5252's to resolve: that number belongs to position 1 and to another release, and #5252 authored no ADR. **Reconciled at the Stage-9 merge:** PR #6119 landed on `main` first and kept 142, so position 1's record renumbered to **ADR-146** via `release/tools/renumber-adr.py`, leaving 142–146 contiguous.

---

## Risk Register

| ID | Risk | Owner | Severity | Reversibility | Mitigation |
|---|---|---|---|---|---|
| **R-1** | **#5074's original acceptance criteria conflicted with the `blast-radius.sh` self-test's documented hermeticity.** The suite states it uses no git and builds fixtures with bare temp trees; a git-dependent enumeration collapses there. | #5074 | HIGH | MODERATE | **Resolved at Stage 5.** Git-optional scoping: tracked enumeration when the root is a work tree, the existing filesystem walk otherwise, with the non-git case emitted as a distinct typed status rather than a silent fallback. Composes with #5260 and preserves hermeticity. |
| **R-2** | **#4931's landing surface was undeclared.** | #4931 | MEDIUM | CHEAP | **Resolved at Stage 5** — D-4931-Landing rules a new tool, with the allowlist companion row and CI wiring pre-declared in the matrix above. The required branch-protection context is untouched. |
| **R-3** | **#5260's originating body cited the wrong probe-validity element.** Building to the cited element would produce a conformant-looking fix that misses the field-absence requirement. | #5260 | MEDIUM | CHEAP | Engineering cites the measurement-state rider and its absence-not-zero clause; the status vocabulary is adopted verbatim, never re-coined. Graded by CIAC-1. |
| **R-4** | **#4720's transport failure surface grows** from 10 to 54 requests once pagination replaces the capped search. | #4720 | MEDIUM | CHEAP | **Operator ruled IN-SCOPE at D-9** rather than an accepted residual; the card re-sized `size:S` → `size:M`. Mitigated by the partial-transport helper and the five-valued status enum. |
| **R-5** | **G3-15 band breach at +14.** | release | MEDIUM | CHEAP | **Shipped under a recorded operator override.** Every point added came from evidence a Stage-5 spoke produced — a class re-render and two evidence-driven scope corrections — not from bin-packing. |
| **R-6** | **Two of #5252's seven workflows are single-touch files**, and both declare a required posture. Low prior-touch count means low regression coverage and no established edit pattern. | #5252 | MEDIUM | CHEAP | Disposition those two with the most care; treat any filter removal as CI-cost-visible and verify on a PR touching an unrelated path. |
| **R-7** | **`deploy.sh` mainline churn** against four in-release writers. | #4720, #4734, #4992, #4931 | MEDIUM | CHEAP | Marker-anchored edits only, never line-anchored; re-baseline before Stage 9; the build order separates the four writers. |
| **R-8** | **Line citations in several issue bodies have drifted** since the readiness pre-flight. | #4992, #4720 | LOW | CHEAP | Engineering re-resolves by marker, never by the cited line number. Expected churn on a high-traffic file; not a defect in the cards. |
| **R-9** | **#4734's residual is expected to be non-zero.** Its acceptance oracle reports a residual of 5 or 7 files depending on the path taken; a run reporting 0 means the oracle was re-derived from the recognizer under test and is broken. | #4734 | MEDIUM | CHEAP | Stage 7 grades a zero as a **failure**, not a pass. The oracle exits non-zero when any of its own control arms is inconsistent. |
| **R-10** | **#4734's build path is unruled.** The operator has not ruled between the two paths its design offers. | #4734 | LOW | CHEAP | **Default to Path 1** and proceed — do not block. If the operator rules Path 2, the delta is exactly three named changes. |
| **R-11** | **Sibling integration criteria inherited a superseded permitted-form list.** Two cards' integration criteria enumerate probe forms from a list #4981's round-3 amendment superseded, and they grade at Stage 8 under a per-criterion verdict enum — so a correct arm can grade non-conforming. | release | MEDIUM | CHEAP | Two limbs. **(a)** the hub re-issues the corrected form list to the affected sub-tasks at Collective Review; **(b)** #4981's own change states that an integration criterion naming a form list grades against the **shipped** list, not its own inline enumeration. Limb (b) is durable and lands inside a file #4981 owns; it is why the closed-enumeration failure cannot recur. |

**Rollback strategy.** Every card is `git revert`-ible at commit granularity, and the release ships as a single PR and a single merge under D-C SINGLE, so `git revert -m 1 <merge-sha>` reverts the whole release. Two cards deserve a named per-card exit: **#5074** — if the hermeticity resolution proves wrong at Stage 7, revert that commit alone; the self-test is the canary and fails loud. **#5252** — a filter removal that proves too CI-expensive reverts to the filter plus a recorded disposition, with no code change stranded. Destructive reset is blocked by platform settings; only forward-moving `git revert` is permitted.

---

## Cross-Issue Acceptance Criteria

Four criteria. Each spans two or more issues, asserts a cohesion constraint the *integrated* release must hold, and is graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 (#5260 × #5074 × #4720 — measurement-state vocabulary).** Every not-computed, not-measured or truncated state introduced by these three cards is emitted using a member of the closed machine-readable status set defined in [`/core/disciplines/review-discipline-principles.md`](/core/disciplines/review-discipline-principles.md) § 8.1, with no locally-coined token; and on any non-measuring status the counter is **absent**, never `0`. *Method:* extract every status-field literal introduced by the merged diff in the two executable surfaces; assert set-membership in the closed enum, and assert no zero-initializer survives on a non-measuring path. **Control:** a seeded token outside the enum must be reported. *Why release-scoped:* the shipped gate enforces the human-readable register only; the machine-readable register has no enforcing gate, so nothing else binds these three to one vocabulary.

- [ ] **CIAC-2 (#4734 × #4992 × #4440 — two-site parity in `core/deploy/deploy.sh`).** No fix in this release repairs one occurrence of a duplicated predicate while leaving its mirror on the old idiom. *Method:* for #4734 assert zero remaining occurrences of the superseded mode-marker probe across both sites; for #4992 assert both check limbs derive from the same prefix and delimiter source; for #4440, assert that the b-loop input selector is pinned **within the marker-bounded (b) block**, and that the (b) and (c) register-side selectors are **byte-identical**. **Control:** the site counts are re-measured on the merged tree, never carried from this plan.

  > **CIAC-2's #4440 limb was restated here at Stage 6 re-entry (D-14 / D-22).** It previously read *"assert the pinned fragment set covers the b-loop input selector at **both selector sites**"* — which the design deliberately and correctly does not satisfy. Measured on the merged tree: the marker-bounded (b) block spans **`deploy.sh:9925`–`:9998`**; the in-block selector is the loop's own input at **`:9998`**, and the (c) register-side selector is at **`:10000`**, *outside* that block. A block-scoped pin cannot reach `:10000` by construction, so the only way to satisfy the old wording literally is to revert fragment matching to whole-file — which **is** mutation M4's hole, the exact defect this card removes. Line 514's verification row already claimed conformance *"as restated at D-14"*, so until now the evidence conformed to a restatement the criterion had never received. The restated form is strictly stronger than pinning each site against a hardcoded literal: if the register's row grammar legitimately changes, both selectors must change together and the assertion still holds, so it cannot go stale. Verified live at re-entry — both selectors read `^\| DP-[0-9]` and are byte-identical, with a differing-selector control arm returning false.
  >
  > **Correction this restatement carries.** The genuinely *silent* M4-equivalent in sub-check (c) is **not** the register-side selector. Neutering `:10000` fails **loud** (an empty `c45_defined` flags every corpus DP-id). The silent twin is the corpus-side consumer scan at **`deploy.sh:10007`** — Stage 5's R-3, and **out of #4440's scope**; recorded so it is not mistaken for this limb's subject. *(All four line numbers re-derived from markers at re-entry; they sit +10 from the Stage-7 measurement because this re-entry's Check 35 message fix landed 10 lines above them.)*

- [ ] **CIAC-3 (#4981 × #5074 × #5260 × #4992 × #5252 — falsifiable-control parity).** Every new or amended check, probe record or worked example introduced by this release carries **both** control arms with observed results — a sensitivity arm shown non-zero and a specificity arm shown zero over a non-empty input — and no card reports a clean zero whose control arm also returned zero. *Method:* enumerate every zero-, clean-, absent- or N-of-M-shaped claim in the merged evidence; assert each carries invocation, denominator, both arms and an extraction record. **Control:** a deliberately arm-less claim must be flagged. *Why this release:* the outcome statement is that a check evaluates its whole subject — a member shipping an unfalsifiable green would contradict it.

- [ ] **CIAC-4 (#5252 × #4992 × #4931 — declared-versus-actual scope).** Where a card changes what a gate reaches, the gate's own **declared** scope is updated in the same commit as the reach change. *Method:* for each workflow compare the declared posture against the presence or absence of a path filter and assert zero mismatches; and assert the token-vocabulary spec states the widened prefix **and** delimiter set. **Baseline pinned at `8dc00db1`: 22 of 22 workflows carry a declaration and 0 mismatches exist**, so any mismatch present at Stage 8 is attributable to this release. **Control:** a deliberately mismatched fixture is detected.

---

## Verification Plan

All nine cards' acceptance criteria are file-path-plus-state or explicit-predicate class, so each maps to a re-runnable command rather than a declared-but-unbuilt method. No card carries a behavioural criterion whose executor does not yet exist, so no deferred-verification entry applies.

| Family | Check | Scope |
|---|---|---|
| Per-issue | Each card's acceptance criteria re-run against the merged tree at its own Engineering chip and again at Stage 8 | all nine |
| Integration | CIAC-1 … CIAC-4 above | release |
| Regression | `core/deploy/deploy.sh --check` | release |
| Doc-link integrity | `core/deploy/deploy.sh --check` link resolution over every modified markdown file | release |
| Sync | Deployed-copy sync for any mirrored rule file touched | release |
| Package freshness | `.skill` package plus content-baseline sidecar rebuilt for every rostered skill whose `SKILL.md` or `references/` changed | #4981 |
| Runtime suite | The suite selected by the runtime-suite selection map, run under a temporary-home sandbox, per card | per card |

**Seeded-fixture cases.** #4981's worked-probe criterion and #4992's negative-control criterion are the two cards whose criteria require a fixture to be shown **firing** and then shown **clearing** when the fixture is removed. A gate that cannot go red is a broken probe; a fixture arm that is only ever asserted green has not been run.

### The corrected acceptance-criteria wordings — CANONICAL GRADING CONTRACT FOR STAGE 8

**Read this before grading any card. Where a row below gives a corrected wording, Stage 8 grades the CORRECTED wording, not the issue body.** ADR-062 forbids amending issue bodies, so these corrections cannot land at source; this section is where they land instead, and it is the authority. Operator decision **D-22**.

**What was measured, and over what population.** Every Stage 7 spoke was asked to test — in both directions — whether its own card's acceptance criteria could be graded literally. Nine cards, nine spokes, all nine reported. **14 defective criteria across 7 of the 9 cards.** Two cards (**#5260**, **#5074**) tested clean and explicitly recorded that all their criteria are gradeable literally; their rows below say so rather than being omitted, because an absent row and a clean row are different findings.

*On the count.* The hub carried this as "roughly 13"; the re-entry measurement is **14**. The single discriminator is **#4734's issue-body AC-3**, which names a per-file `./deploy.sh --check <path>` invocation that does not exist — the dispatcher compares `$2` only against `--warn` and silently ignores a path argument. It is counted here because, graded literally, its stated method cannot be executed at all, which is the same class as #4720's AC-1. One further item — **#4734's issue-body AC-1** — is recorded below but **deliberately not counted**: its spoke measured both readings and found them set-identical on this corpus, so correct work does not fail on it. It is imprecision, not a defect. State the population with the magnitude: **14 defective of 38 graded criteria across 9 cards**, plus 1 recorded imprecision.

**The shape they share.** These criteria were authored before their designs settled and were never reconciled after the design changed. Several prescribe the exact mechanism their own card's design examined and *correctly rejected* — so satisfying the criterion literally would mean reintroducing the defect the card exists to remove. Graded as written, they fail correct work.

| Card | Criterion | Original wording | Why defective | **Corrected wording — grade this** |
|---|---|---|---|---|
| **#4981** | AC-1 | "The Cascade-Completeness Sweep guidance … names the trap and prescribes `git grep -P` **or** an explicit character-class alternation … never `-E` with `\b`" | The **first disjunct prescribes the rejected mechanism.** The design eliminated `git grep -P` as Candidate A on both limbs (over-match raw, under-match escaped), independently reproduced at Stage 7. The disjunction saves the card — the alternation did ship — but the limb names a mechanism the design ruled out. | "…names the forbidden idiom (POSIX-undefined escapes **as a class**, with the mechanism) and prescribes the permitted set — `git grep -wF` as primary, an explicit word-class alternation `(^\|[^0-9A-Za-z_])TOKEN([^0-9A-Za-z_]\|$)`, `-F` without `-w`, or `python3`. **Do not prescribe `-P`;** it was eliminated on measured evidence." |
| **#4720** | AC-1 | "`fetch_stage_titled` **either paginates past the cap** or fails loudly when the result set is truncated (method: run against a population exceeding the cap …)" | **First disjunct is infeasible.** GitHub's search API caps *item retrieval* at 1,000 regardless of pagination, so no paginate-past-the-cap loop can exist over that transport (measured: `--limit 1000` returns exactly 1000 against a ≥3774 population; `--limit 500` returns 500). An implementation is **correct** for not having such a loop. | "`fetch_stage_titled` retrieves the **whole** stage-title population rather than a capped sample, and emits an in-band completeness assertion whose status distinguishes a complete read (`fetched`) from a short one (`truncated`) and from a failed one (`degraded`). *Method:* run against the live population; confirm `scanned` reaches the connection's own `totalCount`, that `matched` exceeds the retired search transport's 1,000-item ceiling, and that no path returns a silently-partial set." |
| **#5260** | — | — | **No defective criterion.** The spoke tested all four in both directions and recorded that none encodes a rejected mechanism. | **Grade the issue body literally.** |
| **#5074** | — | — | **No defective criterion.** Same finding, tested and recorded. | **Grade the issue body literally.** |
| **#4734** | AC-5 | "The folded-YAML constraint is preserved … assert those skills still parse after the fix" | **The control cannot go red.** Under Path 1 the widened D2 arm independently covers every file carrying a D1 declaration (D1-only = 0), so the line-start anchor moves nothing on the shipped code (33 → 33). Graded literally the control is green on a mutation that changes nothing — the fourth recurrence of that signature in this card's lineage. | "The folded-YAML constraint is preserved. *Method:* assert all **30** mid-line D1 declarations still resolve arity ≥ 2. *Control (re-derived under Path 1):* the line-start anchor drops **22** skills from the **pre-fix** predicate (32 → 10) — recorded as the historical justification for the bound, **not** as a mutation arm on the shipped code, where it moves nothing. The live mutation arm for the shipped predicate is AC-4's." |
| **#4734** | AC-3 (positive control) | "run `--check` against **the file that surfaced this defect**; assert no WARN" | **Names an invocation that does not exist.** `deploy.sh`'s dispatcher compares `$2` only against `--warn`; a path argument is silently ignored and the full suite runs. There is no per-file `--check`. It does not error — it simply does not do what the words say. | "Run `./deploy.sh --check` and assert no `mode-invocation-drift` WARN; **separately** assert `core/skills/adr-helper/SKILL.md` is absent from the scanned population." |
| **#4734** | AC-1 — *recorded, NOT counted* | "…a **frontmatter field**, or a heading at a **defined level**" | The build chose the frontmatter **block** (OPT-A); the *field*-scoped OPT-B was explicitly rejected, and Path 1 accepts **any** level H1–H6, not one defined level. **Tested rather than assumed:** a `description:`-key-scoped D1 and the shipped block-scoped D1 both return 31, symmetric difference **empty**. Correct work does not fail. | **Imprecision only — grade the issue body as written.** AC-1's own assertion clause is exactly right and is met. |
| **#4992** | issue-body AC-1 | "…all **three** registered prefixes …; `grep -n 'CLAUDE_\|COWORK_' …` returns at least one match" | Two defects. Live is **four** registered prefixes, not three. And the first disjunct is **unsatisfiable by the accepted design**: measured **0** literal `CLAUDE_`/`COWORK_` in the block, because the design eliminates hardcoded prefix literals — the stronger property. Saved only by the second disjunct. | "Assert the prefix set is **derived from `depersonalization-spec.md` at runtime** and that both usage limbs consume one derived value. **Do not** assert a prefix count or a literal-prefix grep; a hardcoded prefix literal **is** the defect." |
| **#4992** | issue-body AC-2 | "assert the Check 44 **block** no longer carries a bare `--include='*.md'`" | **Block-scoped where the design is arm-scoped.** Arm (a) — the PVT\* ratchet, explicitly out of scope — retains `--include='*.md'` and the three-root list. Graded literally, correct work fails. | "…assert **arm (b)/(d)'s enumeration limb** carries no `--include` filter and no root list, and that a seeded unregistered token in a `.sh`, a `.md.template` **and** a `.toml.template` fixture is reported. Arm (a) is out of scope and retains its own narrowed scan." |
| **#4992** | issue-body AC-3 | method requires `docs` to "resolve in **the root list**" | **Encodes the rejected mechanism.** D5-3 removes the root list entirely in favour of `git ls-files`. Unsatisfiable by construction against the design it grades. | "…assert the enumeration limb carries **no root list at all**, and that a seeded token under `docs/` is reported. The design removes the root list rather than extending it." |
| **#4992** | issue-body AC-5 | "the **20** tokens legitimately in use" | **Stale count.** Live is **19** square-registered and 19 in use. Not fatal — the substantive requirement (line-by-line explanation) is met — but the literal is wrong. | "…no new finding against the tokens legitimately in use at fix time; **re-derive the count at verification** rather than asserting a literal." |
| **#4992** | design AC-1 | "zero occurrences of the literal `OPERATOR_[A-Z0-9_]+`" | **Ambiguous between two readings.** As the regex *source text* → 0 (pass). As "any string *matching* the regex" → 2, both non-predicate (arm (a)'s remediation advice; arm (d)'s illustrative owned-token name, which carries its own allow-marker). | "…zero occurrences of a **hardcoded prefix literal in any matching predicate** inside the block." |
| **#4992** | design AC-3 | "Assert **no** `--include` and no literal root list **in the block**" | Same block-vs-arm scope error as issue-body AC-2. | "…in **arm (b)/(d)'s enumeration limb** (arm (a) is out of scope and retains both)." |
| **#4440** | CIAC-2 limb | "assert the pinned fragment set covers the b-loop input selector at **both selector sites**" | **Satisfiable only by reintroducing the defect.** The (c) selector sits outside the marker-bounded (b) block, so no block-scoped pin can reach it; whole-file matching is mutation M4's hole. Full ruling and re-derived line numbers at CIAC-2 above. | "…for #4440, assert that the b-loop input selector is pinned **within the marker-bounded (b) block**, and that the (b) and (c) register-side selectors are **byte-identical**." *(Landed at CIAC-2 at this re-entry.)* |
| **#5252** | AC-1 | "…assert each appears in **this issue's disposition table** with a verdict" | **The stated method cannot be executed as written.** ADR-062 forbids authoring the table into the issue body, so the artifact the criterion points at is one no spoke may create. Same class as #4720's AC-1. | "Confirm all 7 are dispositioned (*method:* enumerate `.github/workflows/*.yml` carrying a `paths:` filter **at the release baseline commit**; assert each appears with a named disposition — CONVERT, BIND or RECORD — in **the PR body's disposition roll-up and the register rows landed in `core/standards/gate-efficacy-standard.md`**. Those are the durable artifacts. **Control:** re-measure the filtered-workflow count at that baseline rather than carrying it from the body, and explain every delta from the stated 8-of-21 by name.)" |
| **#4931** | AC-1 | "A citation naming a file plus a section anchor is resolved against that file's actual section headers" | **Broader than the delivered scope on three axes the design deliberately rejected:** named anchors are a counted `not-run`; prefixes outside the modelled five are declared with a measured count; non-markdown and untracked targets are counted `not-run`/`degraded`. Grading literally marks correct work as failing. | "A citation naming a file plus a **numeric** section anchor, behind one of the five modelled prefixes (the section glyph, or Section / Part / Appendix / Phase), and bound to a **tracked markdown** target, is resolved against that file's **complete** set of numbered section headings. Every citation form outside that scope — named anchors, unmodelled prefixes, untracked or non-markdown targets, anchors bound to no path — is counted and declared in the tool's header with its measured baseline count, never silently dropped." **`complete` is load-bearing** — it is the half D-1 broke, and the half this re-entry repaired. |
| **#4931** | AC-3 | "Citations to files the checker **cannot read** are reported distinctly from citations that resolve to nothing" | **Names the wrong criterion.** The shipped predicate is "**not tracked in git**", which is right: an untracked-but-present file is perfectly readable, and a filesystem predicate answers differently in two checkouts of the same commit (verified — `roadmaps/skill-matrix.md` is present in the primary checkout and absent from a worktree). Milder than AC-1 because the intent is met. | "Citations whose target the checker **cannot resolve to exactly one tracked file** are reported distinctly from citations that resolve to nothing." |

**Grading rule.** For every row carrying a corrected wording, a card is MET when it satisfies the **corrected** wording. A card must not be scored NOT MET for failing to exhibit a mechanism its design correctly rejected, nor for failing to produce an artifact ADR-062 forbids creating. Where a row says *grade the issue body literally*, do that — the absence of a correction is itself a measured finding, not an oversight.

**Do not treat this table as closing the underlying gap.** It corrects fourteen instances; it does not fix the process that produced them. That is filed separately as a systemic intake finding and is referenced in Decisions below.

### Verification Evidence

Populated per Engineering chip as each card lands, in the order of § Implementation Sequence. Each entry records the card, the checks run, their observed results, and the landing commit.

#### #4981 — probe validity and engine parity · position 1 · landed `90189947`

| Check | Family | Observed |
|---|---|---|
| Defect-idiom census, re-measured at fix time | per-issue (AC-3) | **0** across both script-class populations — 231 files / 143,805 lines, and 296 files / 152,375 lines with workflow YAML. Tree-wide: exactly **1**, and it is prose in an archived release plan warning about this defect, not an invocation. |
| Detector sensitivity arm | per-issue (AC-2) | 5 seeded must-flag lines carrying the full defect idiom, 2 of them with a git global option between command and subcommand. Original predicate flags **2 of 5**; repaired predicate flags **5 of 5**. PASS — NON-ZERO. Arm input 161 bytes, non-empty. |
| Detector specificity arm | per-issue (AC-2) | 6 near-miss lines, each differing from a true positive in exactly one property. Both predicates flag **0 of 6**. PASS — ZERO. Arm input 178 bytes, non-empty. |
| Cascade-completeness sweep | per-issue | 14 patterns over 3 files / 1,402 lines / 151,169 bytes, engine `python3` `re.search`, file-scoped. Every UPDATE target moved to 0; every PRESERVE target intact — `7 classes` 1, the boundary labels 2, the element-range string 1, `15 rules` 1. Control arms: sensitivity 4 and 8, specificity 0. |
| Doc-link integrity | integration | `deploy.sh --check` Check 14 — **OK, no broken cross-refs in scope.** |
| ADR number integrity | integration | `check-adr-numbers.py` — **PASS**, 142 ADRs contiguous, no duplicates. |
| ADR durability lint | integration | `check-adr-durability.py` — ADR-146 clean; the 2 residual findings are pre-existing on another record. |
| Skill-package freshness | regression | `pmo-qa-auditor` rebuilt and **fresh**; package plus content-baseline sidecar committed in the same commit as the reference edit. |
| Runtime suite | self-verification | **`suite-skip`** — the honest no-op. No changed path matches rows 1–5 of the runtime-suite selection map; the change is doc, governance and spec only. Control: a `core/deploy/deploy.sh` probe selects row 2, so the selector discriminates. |
| Full `deploy.sh --check` | regression | 4 FAIL rows, **none in this change set** — a stale package for a skill this card does not touch, release-body drift across previously logged releases, and a count-structure finding in a file from an earlier release. Probe: 0 of 6 changed paths intersect any FAIL subject; control arm fires at 3 for the subject this card does own. |

**AC-4 resolves via its second limb.** No committed-scripts lint arm ships. The population is measured at zero, and a new executable would carry an allowlist row and CI wiring for no yield. The flip trigger is recorded in ADR-146: the first live occurrence of the forbidden form in a committed script re-opens the decision.

---

#### #4720 — transport truncation · position 2 · landed `bee56cdf`

| Check | Family | Observed |
|---|---|---|
| Self-test suite | per-issue (AC-3) | **104 legs, 104 green.** Fourteen are this card's: T-S1 / T-S1c / T-S1c2 / T-S2 / T-S3 / T-S4 / T-S4c / T-S5 / T-S6 / T-S7 / T-S8-ctrl / T-S9 / T-S11 / T-S11c, plus the rc-bearing T-S10 / T-S10b / T-S10c. |
| Mutation kill-map, both directions | per-issue (AC-3) | **11 mutations, each run against the ASSEMBLED suite**, not against the function in isolation. Every one reddens the legs its row names, and in all 11 the suite stayed intact at 104 rendered legs — so a red leg is attributable to the mutation rather than to an aborted run. The two rows this release turns on: **restoring `_gh` at the call site reddens exactly `{T-S10, T-S10b}` and nothing else** — every rc-0 arm unchanged, which is what makes it attributable to the one token; **dropping the `ndocs == 0` guard reddens `{T-S8-ctrl, T-S10}`**. |
| FM-2 (`max(totalCount)`) | per-issue (operator-folded) | **Fixed and covered.** T-S11 drives a two-document stream whose second page reports a HIGHER `totalCount`; it reads `fetched` under first-page binding and `truncated` under `max()`. Restoring `max()` reddens **T-S11 alone**. Near-miss control T-S11c (a genuinely short walk) stays **truncated** under both, so T-S11 is not satisfiable by a mutation that reads `fetched` everywhere. |
| CD2-2 / AC2-5 (degraded path emits) | per-issue | **Discharged, measured on stdout rather than asserted from code shape.** The degraded `--leg M3` path now emits **2 rows** (`M3_SCAN degraded - - -`, `M4_SCAN not-run - - scope:m3-only`) and then exits 3; **no `COUNT_M3*` row is emitted** (PV-7b absence-not-zero). Control arm over the SAME code path with a measured walk emits **4 rows** including `M3_SCAN fetched 1 1 1` and both `COUNT_M3*` rows, and exits 0 — so neither arm is vacuous and the difference is the measurement state, not the path. |
| Emit-on-every-path | per-issue | Fixture run emits `M3_SCAN fixture - - - scope:fixture`; `--leg M1` emits `M3_SCAN not-run - - - scope:leg-M1` with no M3 rows and no counters. |
| Doc-link integrity | integration | `deploy.sh --check` Check 14 — **OK, no broken cross-refs in scope.** |
| PV-7a Register B spelling (Check 69) | integration (CIAC-1) | **OK, and the check is ENFORCING, not warn-mode.** 1,770 tracked files enumerated, 13 carrying a token rendering, control 81 sanctioned occurrences observed non-zero, 0 unsanctioned. The `DEGRADED` token this card adds to `deploy.sh` is the sanctioned spelling. |
| Runtime suite | self-verification | **Rows 2 and 4 selected** (`core/deploy/**` and `core/deploy/tools/*.py`). Row 4 run: `check-selftest-coverage.py --run` — **ARM A PASSED, 62 of 62** discovered tools, and the modified tool is IN that set with its 104 legs green (verified by name in the run log, not assumed). Row 2 (`install-tests.yml` deploy steps) not run locally — a CI-hosted job; it gates pre-merge. |
| Full `deploy.sh --check` | regression | **4 issues = 2 FAIL + 2 DRIFT, none in this change set.** FAIL: a stale `release-planner` package (that skill is unchanged on this branch — `git log 8dc00db1..HEAD` over its tree is empty) and a `count-structure` finding in `core/references/reference/operator-instance-home-and-isolation-key.md`. DRIFT: `pmo-qa-auditor` installed-copy drift, which is position 1's change not yet deployed to the operator install — operator-instance, never CI. Probe: **0 of 3 changed paths intersect any FAIL subject**; sensitivity control fires at 1 on a seeded row naming this card's file, specificity control returns 0 on a near-miss filename. |

**Accepted Verification 2 and 3 are NOT satisfied and are owed to Stage 7.** The run above could not exercise the new walk live: the GitHub GraphQL quota was exhausted (0 remaining) for the whole session, and **five** gh-dependent checks reported input failure — including Check 56 itself. The live `M3_SCAN` row reading `fetched`, and `matched` exceeding 1,000, are the two assertions that state the card's whole claim as a number the run emits, and neither has been observed. Stage 7 must run them once quota recovers; a green self-test is not a substitute.

**One live observation the rate limit handed us for free.** Check 56's exit 3 came from `fetch_milestones` — the FIRST raise-on-rc fetcher — three calls before the stage-title walk was attempted. That is the empirical premise D-4720-B′ rests on, observed rather than argued: a genuine global input failure never reaches this fetcher, which is why a failure that DOES reach it is a per-leg measurement outage.

---

#### #5260 + #5074 — blast-radius scope and status · positions 3–4, one build unit (D-4) · landed `efd2b821`

*Backfilled at position 5 from the Stage-6 outputs posted on the two sub-tasks; no figure here is invented, and none is re-derived.*

| Check | Family | Observed |
|---|---|---|
| Typed-status discrimination, `--depth` | per-issue (#5260) | The defect is gone by SHAPE, not by prose. On the frozen corpus `--depth=1` and `--depth=2` used to emit 751-byte envelopes differing at exactly one byte — the echo of the requested depth. They now differ structurally: depth 1 → `second_order_status: not-run`, `second_order_count` **absent**, reason names the depth; depth 2 → `second_order_status: fetched`, `second_order_count: 0` — a **measured** empty. |
| Enumeration-drop discrimination, three arms | per-issue (#5074, the pass-2 BLOCKER) | Purpose-built git fixture, precondition `uid=501` asserted first. **SUBJECT** (tracked file behind a mode-000 directory) → `scan_scope_status: degraded`, `total_files_scanned` 3, reason present. **CONTROL** (same fixture, directory readable) → `fetched`, 4, reason absent. **SPECIFICITY** (tracked file *and* tracked directory deleted from the worktree) → `fetched`, 3, reason absent. The records differ in a **status field**, not only in a count no consumer can ground — and the specificity arm is what earns the classifier over a naive `[ -x parent ]` test, which mis-classifies exactly that row. |
| Disjoint-population confirmation | per-issue (#5074) | The SUBJECT arm reads `unreadable_files: 0` **beside** `scan_scope_status: degraded` — the two counters measure disjoint populations, so the census structurally cannot see an enumeration drop and the classifier is the only instrument that can. `scan_scope_status` never branches on `UNREADABLE_COUNT`. |
| `degraded` on the second path | per-issue (#5074) | **T5h** forces `ls-files` to fail against a corrupt index while `rev-parse` still succeeds; the reason names exit 128. `degraded` ships **tested**, not asserted, so the "do not ship an untested member" rule does not fire. |
| R3-2 emit clause, six arms | per-issue (#5260) | Arms A–D as specified, plus **two non-vacuity controls**: arm E (`fetched` + 0) keeps the counter **present at 0**, and arm F confirms every #5074 key survives. Without E and F a clause that simply deleted every zero would pass A–D and destroy the card's whole purpose. Arm C shows the FM2-2 hazard is **unreachable** — its output is identical to arm B. |
| Naive-derivation falsification | per-issue (#5260) | `rtrimstr("_status")` alone reproduces broken in **both** directions — `second_order_count` survives at 0 *and* `scan_scope` is deleted. The shipped `rtrimstr("_status") + "_count"` does neither. |
| Positional-binding detector (INT-1) | per-issue | `python3` literal substring over 15,496 bytes of `schema-v1-emit.sh`. Subject `${16` → 2; `${17`–`${20` → **0**. Sensitivity `${15` → **1** (non-zero); specificity `${99` → 0 over the same extraction (non-vacuous). Registry exactly 7 members, 4 + 3. |
| Sibling byte-identity | regression | `domain-blast-radius.sh` **0 lines changed**; ADR-068 **0 lines changed**. With the library edit complete and `blast-radius.sh` untouched, the F1 golden **reproduced at 751 B and its committed digest** and the domain suite passed 22/22 — byte-identity proved through the amended library against the repo's own pinned oracle. Sibling `.stats` key set unchanged in membership *and* order. |
| Golden regeneration | per-issue | **883 B / `ec46e8a7cd67b2b9e6bf742340f1272a812374cf302f2390b28ec4c7aa461ecb`**, read off the regenerated artifact rather than carried. The predicted digest matches to the full 64 characters. The open 930 B question **resolves to 883 by observation**: `scan_scope_status_reason` is emitted on the fixture root but `normalize()` deletes it, so it never enters the compared surface. Two further README claims measured, not asserted: in-repo-root recipe **881 B**, unwidened del-set **982 B**. |
| Suites | regression | `blast-radius.sh --self-test` **36/36, 0 skipped** (from 13; the inherited 31→33 figure assumed #5260 lands at 21 — it lands at 24, so the composed total reconciles to 13 + 11 + 12 = 36). `test_domain_blast_radius.sh` 22/0/0. `test_structural_blast_radius.sh` 15/0. `check-selftest-coverage.py --run` **ARM A 62 of 62**. `check-adr-numbers.py` PASS, 143 contiguous. Check 14 doc links OK. Check 69 vocabulary 0 unsanctioned, control 81 non-zero. |
| FM-3 — the unexecutable assertion | per-issue (#5260) | **Discharged by substitute, and the blocker is named rather than worked around.** `verify-golden.sh` is still absent from the execution allowlist (`BLOCK-DESTRUCTIVE-022`, reproduced this session, no bypass), so the script could not be run. All **13** `chk` predicates were parsed from the shipped script and reproduced inline against the regenerated golden, plus both spec constants — 13 of 13 expected == actual, with a firing near-miss control that correctly differs. |

**Two claims this unit corrected against itself, recorded because self-correction is the evidence.** The spoke first wrote that "no other card in this release edits `test_domain_blast_radius.sh`" and then withdrew it as over-scoped: the probe's denominator was the **three build units landed at `efd2b821`**, and five of eight had not run. The sound statement is *among landed units, this is the only writer*. **Round-3 Decisions item 5 therefore stays OPEN**, and the release-level file inventory must re-measure the population at the last build unit rather than reading the figure forward. Position 5 adds one data point and no more: **#4734 does not touch that file.**

---

#### #4734 — mode-arity predicate · position 5 · landed `ffaf23e1`

| Check | Family | Observed |
|---|---|---|
| Check 35, live | per-issue (AC-1) | `deploy.sh --check` → **`OK: all 33 multi-mode skill(s) expose a machine-recognizable mode-enum`**. In scope **33** (from 32), findings **0** (from 1). `core/skills/adr-helper/SKILL.md` has left the population. Six independent implementations now agree digit-for-digit on the denominator of **56** and on 32/1 → 33/0. |
| `c35r` report mirror | per-issue (AC-1) | `deploy.sh --report` → **`[PASS] mode-invocation-drift — all 33`**, from `[FAIL]`. |
| AC-2 — both extraction idioms | per-issue | `python3`, never `grep` (the local binary is a ugrep shim that yields a plausible zero on a rejected pattern). Limb 1 `grep -m1 -E 'Modes:'` → **0**. Limb 2 (the 5(d) idiom `grep -oE 'Modes?:[^.]*'`) → **0**. **Controls, all firing:** the same scan returns **19** token-bearing lines overall, and finds exactly **one** definition of `_skill_fm_decl_line` and **one** of `_c35_compute_verdict`. A zero from an inert extraction would fail these. |
| AC-4 — mutation arm | per-issue | **The arm moves for the first time.** As built (widened D2): `(33, 0)` → D2 forced to zero → `(31, 0)` — **MOVES**. The rejected shipped-D2 form: `(31, 0)` → `(31, 0)` — does not move, which is precisely why the original control certified nothing. **Control that the evaluator can produce a finding at all:** the pre-fix predicate returns `(32, 1)`. |
| AC-5 — falsification arm | per-issue | The line-start anchor an unwary fix reaches for drops **22** genuine multi-mode skills (in scope 32 → **10**). Within the frontmatter bound, **31** files carry a declaration and only **1** is line-start-anchored, so the non-anchoring is load-bearing on 30 of 31. **Control:** the body-heading arm fires at 9, so the union is testable. |
| AC-6 — denominators | per-issue | `git ls-files '*SKILL.md'` → **57**; Check-35 evaluated glob → **56**. Difference is exactly `operations/skills/_templates/system-specialist/SKILL.md` — correct by intent (a template is not a deployed skill), per D-4734-3. Both recorded. |
| AC-7 — single engine | per-issue (DD1 / CIAC-2) | Exactly **one** definition of the D1 extraction and **one** of the verdict engine; both Check-35 surfaces and Check 5(d) delegate. Three call sites, zero re-encodings. |
| AC-8 — SIGPIPE idiom | per-issue | **No new suppression comment is owed, and none was added.** Of 258 added lines, 88 are code and **11** carry a pipe; each was read and none pipes into a short-circuiting reader (`sed` without `q`, plus `sort`/`wc`/`tr` full consumers). The `awk` extractor reads its file directly rather than from a pipe — that is the design property, not an accident. The orphaned `U3` suppression at the old 5(d) pipeline was **removed, not carried**, since `head -1` is gone. |
| AC-9 — planted 5(d) fixtures | per-issue (D-13) | The only evidence the bound landed, since the live corpus cannot grade it. Role-Specialist **without** a frontmatter declaration: old extraction lifts the BODY line `'Scaffold — the body says this, and it is not a declaration'`; bounded extraction returns `''`. **With** a declaration plus a decoy body line: both return `Alpha · Beta · Gamma` — the decoy does not win. |
| Check 5(d), live | per-issue (D-13) | `deploy.sh --check` → **OK**, 55 rows, field-currency asserted per role-Specialist. Divergent rows **0 of 21 before and 0 of 21 after** — the expected result. **Control:** 21 of 21 non-empty extractions under **both** arms; rows whose extracted text changes: **0**. |
| **AC-10 — the residual oracle** | per-issue | **RED at 5, as designed.** `check-mode-declaration-residual.py` → residual **5**, enumerated: `artifact-generator`, `daily-status`, `eval-writer`, `pmo-skill-refiner`, `prompt-builder`. **Sensitivity 19** in-scope files fire. **Specificity** `adr-helper` does **not** fire. **Mutation** all four planted fixtures classify correctly, including the single-mode decoy carrying failure-mode prose — the exact shape that caused the original defect — and the one-row `\| Mode \|` table. **Table census** 6 tables, **0** below the ≥2-distinct threshold, so the arm is neither inert nor over-reaching. |
| CI wiring of the new tool | integration | `check-selftest-coverage.py --reconcile` **failed Arm B(ii)** naming the unlisted tool, then passed after `--emit-manifest` — 66 paths, zero `::error::`. The discovery was verified to FIRE, not assumed. `--self-test` exits 0. |
| Full `deploy.sh --check` | regression | Exit 1, **4 FAIL rows, none in this change set**: a stale `release-planner` package (untouched here), release-body drift across previously logged releases, and a count-structure finding in a file from an earlier release. |
| Full `deploy.sh --report` | regression | **Exit 1, and the predicted flip did NOT occur** — correctly. 133 checks, 124 passed, **9 failed**, so Check 35 was not the sole failing row. All 9 enumerated and all operator-instance or pre-existing: two installed-copy drifts, three absent `projects/_config/` files (Layer-2, git-ignored, never present in a worktree), an I2-presence row and three issue-aging rows. The Stage-5 expectation was conditional (*"may flip if Check 35 was the sole failing row"*); the condition is false and the exit code is unchanged. |

**Two probes were broken and are reported as unusable rather than as results — both caught by their own controls, both the same root cause.** (a) A 5(d) parity probe passed its `awk` program through a `bash -c` string; the repr-quoting flattened the program's newlines to literal `\n`, awk bailed, and it returned "no declaration" for **all 21** role-Specialists — a uniform zero that reads exactly like a finding, and which contradicted the live `--check` run. Re-run through `argv`, it returns 21/21. (b) An `OPT-C` arm run inline through nested shell quoting returned in-scope **0**; re-run from a file it returns **10**. Neither zero is relied on anywhere above. **A third attempt — re-implementing the repo-integrity SIGPIPE gate's own patterns to grade AC-8 — failed twice** (a Python translation whose every arm reported INERT on its planted positive while the union reported 9 hits on lines that plainly do not match, then a POSIX lift that missed the gate's four nested shell variables). It was **abandoned rather than reported**, and AC-8 was verified by direct enumeration instead; the authoritative arm is the CI job.

**One control-shaped catch on my own work.** Prose I wrote to explain *why* the `U3` suppression was removed contained the literal suppression token, in two places. The repo-integrity job matches that comment form **un-anchored**, so the explanation would have been read as the directive it was describing. `T2` scope only climbs `|` and `\` continuations, so neither was a live suppression — but both would have reported on the SUPPRESSED channel naming nothing, so the text was reworded to describe the marker without spelling it. A pre-existing suppression at Check 36 whose rationale cross-referenced "the Modes probe" was also reconciled, since this change is what removed the probe it pointed at.

---

#### #4992 — token-registry conformance scope · position 6 · landed `764c90c8`

Every figure below is **re-derived on the shipping tree**, never carried from the design. All corpus detectors are `python3` `re` over `git ls-files`; the shipped shell idiom was then run as an **independent second mechanism** and reconciled against the `python3` oracle before either was reported. PV-1 denominator: **1,772** tracked files, **1,346** scanned after the `release/releases/` exclusion.

| Check | Family | Observed |
|---|---|---|
| Registry read, table-scoped | per-issue (AC-2) | **19 square / 9 angle** after this card's one added row. The `python3` oracle and the shipped `sed` first-cell extraction return the **same two counts**, so the extraction is confirmed by a second mechanism rather than by inspection. The §4 schema metavariable is **absent** from the parsed registry — excluded by table-scoping, not by a name-specific exception. |
| Derived prefix alternation | per-issue (AC-1) | `CLAUDE\|COWORK\|OPERATOR\|PMO` — **4 prefixes**, identical from both mechanisms. One derived value is consumed by both limbs at `:9843` and `:9850`, discharging CIAC-2. |
| Arm (b) finding set — square, gating | per-issue (AC-9) | **EMPTY. 0 tokens / 0 raw matches**, against a firing control of **19** intersecting tokens — so the zero is a real clean, not an empty extraction. The pre-fix set was 3 tokens / 13 occurrences and each is dispositioned line-by-line: `OPERATOR_FIRST_NAME` (11 sites) registered, `OPERATOR_JIRA` (1) and `COWORK_INSTALL_PATH` (1) allow-marked. |
| Arm (d) inventory — angle, advisory | per-issue (AC-5 v) | **16 tokens / 236 raw matches**, both mechanisms agreeing. The delta from the pre-marker 239 is **3, not 2** — the allow marker is line-scoped and `depersonalization-spec.md:132` carries two un-codified tokens on one line. **Unit stated, because the same set yields three numbers**: 236 raw matches / 201 per-line / 194 distinct lines at ship. The asserted figure is the raw-match unit. |
| **Negative control — the gate can go red** | per-issue (AC-6) | **PASS in both directions.** Removing the standing control's allow marker turns arm (b) red on exactly `[COWORK_INSTALL_PATH]` — a `.sh` file under `docs/`, the intersection of the extension and root axes and doubly unreachable by the shipped check. Restoring it clears to empty. Control arm returned **19** in *both* states, so neither the red nor the green is an extraction artifact. |
| Extension + root axes | per-issue (AC-3, AC-4) | Seeded unregistered tokens in a `docs/*.sh` **and** a `core/*.md.template` are **both** reported. The `docs/` root and both previously-unreachable extension classes are confirmed reached. |
| Tracked-file enumeration | per-issue (AC-3) | The same seeded fixture returns **0 while untracked and 1 once tracked** — the enumeration property asserted as a measured state change, not from code shape. |
| Delimiter arm — derived, not stored | per-issue (AC-5 iii) | A seeded angle token appears in arm (d)'s inventory, then **disappears the moment its §4 table row exists**, with no other edit — proving the payload is derived from the registry rather than from a record of it. Control: the inventory still returned **16** on the same run, so the disappearance is not an empty result. |
| Outage is a withheld verdict | per-issue (AC-8) | The guard predicate discriminates: `git rev-parse --is-inside-work-tree` exits **128 outside** a work tree and **0 inside**, so the `flag_not_evaluated` branch is reachable and the `OK:` line is guarded on the enumeration having run. Both arms fire. A full non-work-tree `--check` run is owed to Stage 7. |
| Non-escalation | per-issue (AC-7) | Arm (d) routes through `flag_advisory_only`, whose body carries no mode `case`, no `enforce` branch and no `ISSUES` reference — the guarantee is in the code's shape, not in a flippable default. No angle-family path reaches `flag_warn_or_issue`. |
| Declared scope restated in the same commit | per-issue (AC-10) | `depersonalization-spec.md` §1.5 states the prefix, delimiter, extraction, file-scope, exclusion and degradation axes **and** the two families' differing verdict semantics. Discharges CIAC-4. |
| **Live in-situ run of the shipped check** | per-issue | `bash core/deploy/deploy.sh --check` on the landed tree emits, verbatim: `ADVISORY: depersonalization-token — angle-bracket token inventory: 16 un-codified token(s) / 236 raw match(es) …` and `OK: no PVT* reintroduction; every square-bracket token in tracked corpus is registered`. **No WARN and no FAIL from Check 44.** The shipped code's own numbers match the `python3` oracle and the inline-shell mechanism — three mechanisms, one figure. The `OK:` line firing also confirms the enumeration-ran guard resolved true rather than the line being printed on an outage. |
| Neighbour regression | integration | Check 45, whose block begins two lines after this one and whose every line number this change shifts, reports **OK** on the same run — mechanism presence, register drift and consumer-id resolution all clean. The +56-line growth broke no neighbour. |
| Doc-link integrity | integration | `deploy.sh --check` Check 14 — **OK, no broken cross-refs in scope.** |
| ADR number integrity | integration | `check-adr-numbers.py` — **PASS**, 144 ADRs contiguous `001..144`, no duplicates. ADR-144 is next-free across both ADR directories; no gap, no duplicate. |
| ADR durability lint | integration | `check-adr-durability.py` — **ADR-144 clean.** One R2-COUNT finding on it was **self-caught and fixed** (a live corpus count in durable prose, re-anchored historically); the 2 remaining findings are pre-existing on another release's record, so the lint is not returning an empty result. |
| Net-new fragile references | integration | **0** across **120** added lines in the two durable-corpus files, on all three classes (markdown-link sequence, bare issue reference, raw ledger URL). Both detector controls fire on seeded samples. |
| Full `deploy.sh --check` | regression | **5 issues = 3 distinct FAIL subjects, none in this change set** — the stale `release-planner` package (that skill is untouched on this branch, and it is warn-class exit 2 that will not block the merge), release-body drift across 13 previously-logged releases, and a `count-structure` finding in `core/references/reference/operator-instance-home-and-isolation-key.md` from an earlier release. Probe: **0 of the branch's 26 changed paths** intersect any FAIL subject; the control arm fires at **1** on a subject this card does own, so the zero is discriminating rather than vacuous. |
| Runtime suite | self-verification | **Rows 2 and 5 selected** (`core/deploy/**` and `docs/scripts/**`); row 6 does **not** apply — this is not a doc-only change. **Neither was run locally, and that is surfaced rather than recorded as a pass.** Row 5's runner mandates a `HOME`→`/tmp` sandbox, which this session's worktree-isolation guard blocks; running it unsandboxed would defeat the sandbox the map requires, so it was not run. Both are CI-hosted and gate pre-merge — row 5 at `install-tests.yml:486`, which additionally carries a broken-fixture meta-probe (`:528`–`:537`) proving the harness can fail. **Owed to Stage 7 Phase A8 as the authoritative gate.** |

**One claim I withdrew rather than reported.** I derived from the reference-durability workflow's source that the positional issue-reference rule flags every added line carrying a bare `#N` when the file has no reference-block header — and this plan file has none, which would have made **115** of the branch's added plan lines findings. Before reporting it I tested it against the population: **118 of 179 merged release plans carry bare refs with no reference block**, including each of the four most recent releases, all merged green. The reading is falsified by the outcome, so the finding is withdrawn rather than filed. My 5 ref-bearing added lines follow the identical convention.

**What the widened check does NOT cover, stated because reach is this card's whole subject.** A token whose prefix appears in no registry row is unmatchable by construction — the bound is narrower than the one it replaces and shrinks as the registry grows, but it is not zero. Arm (a), the PVT\* ratchet, still carries the original `--include='*.md'` and three-root narrowing; it is out of this card's acceptance criteria and is a one-line change once this enumeration exists, so it is an intake item rather than a silent scope grab.

#### #4440 — drift-guard match scope and selector liveness · position 7 · landed `934f5b05` + `fd064748`

Every figure below is **re-derived on the shipping tree** at build time, never carried from the design or from the review. All corpus detectors are `python3`, never the shimmed local `grep` and never a `git grep` word boundary. Coordinates are re-derived from inline markers, because five landings shifted this file: the (b) block is `deploy.sh` **9915–9989**, 75 lines, against a whole-file denominator of **14,415**.

| Check | Family | Observed |
|---|---|---|
| The defect, reproduced at head | per-issue (AC-1) | The pre-patch test scores **`13 passed, 0 failed` — GREEN — on all three of** M4 (repoint the (b) input `^\| DP-` → `^\| ZZ-`), M4′ (loosen it by dropping the row anchor), and M2 (delete `c45_ok=0` from the b2 arm), measured by swapping each mutated `deploy.sh` in at the real path because the old test hardcoded its subject. Its baseline on the unmutated tree is the same `13 passed, 0 failed`, so the GREEN is not an artifact of the harness failing to run. |
| Why the prescribed one-line fix fails | per-issue | The short selector `grep -E '^\| DP-[0-9]' "$c45_reg"` occurs **twice** whole-file (`:9988`, `:9990`); the full `done < <(…)` spelling occurs **once** (`:9988`). Control needle `flag_warn_or_issue` → **223** (fires); specificity needle `^\| ZZ-[0-9]` → **0**. Substring matching per line, no regex, so no escaping or word-boundary trap. A whole-file pin on the short form is satisfied by `:9990`, which is why the body's remedy was overridden. |
| Match scope, block-scoped | per-issue (AC-1) | The fragment loop now matches `<<< "$C45B_BLOCK"`. In the baseline block the short selector occurs **1×**; `:9990` is outside by construction. Pin set **6 → 9** (added the b1 finding message, the input selector, and the block terminator). |
| **Extraction bounds, pinned and asserted** | correction item (adversarial PR-1 / FM-1) | The "outside by construction" claim rested on a terminator marker nothing pinned. Measured: renaming `# (c) FMF-2` widens the block **75 → 4,501 lines** (to EOF) and the block is **non-empty**, so the pre-existing `[[ -z ]]` fail-closed branch **does not fire** — it tests emptiness, not extent; the widened block again contains **2** short-selector occurrences, restoring the exact ambiguity the scoping removes. Control arm: renaming the *opening* marker yields **0** lines and NOSET **does** fire, so the guard was asymmetric by construction. The extraction now asserts its own postcondition (the block's last line must carry the terminator) plus a stated extent band, and both markers are pinned. |
| The accidental protector, confirmed and replaced | correction item (adversarial PR-1 / FM-1) | Pre-patch, the terminator rename was caught **only** by the zero-`continue` assertion, and misattributed: the drift guard printed its `ok` line while the suite failed with `15 continue statement(s) in the live Check 45(b) body`. Two independent mechanisms agree on **15** (a `python3` count over the comment-stripped widened region, and the shipped assertion's own output). Post-patch the same mutation reports its actual cause — the block ran to EOF — naming the observed extent. |
| Selector liveness, behavioural | per-issue (AC-1) | The live pattern is extracted from the block and **run**: sensitivity **4 of 4** entry rows on the clean fixture; specificity **0** on a decoy register carrying the header, the separator and three off-row decoys and zero entry rows. The decoy set was widened to defeat *both* loosenings — a bare-id decoy catches dropping the anchor to `DP-[0-9]`, a row-shape decoy carrying a mid-line `\| DP-1` catches dropping only `^`. Without them a loosened pattern selects 0 here and the arm passes vacuously. |
| **Live-subject liveness arm** | correction item (adversarial PR-2 / CD-2) | The two fixture arms prove the pattern is well-formed against a grammar this test authored, not that it still selects the register Check 45(b) reads. Added a third arm on the live `design-principle-register.md`: **9 rows selected**, against a same-shape control pattern selecting **0**. Threshold is `>= 1`, deliberately not `== 9` — this asserts liveness, never content, so a legitimate register edit cannot break it. Read-only; nothing outside `${TMP}` is written, and the file header's now-false "never read" claim was reconciled rather than annotated. |
| Two-site parity | CIAC-2 (as restated at D-14) | (b)'s selector and (c)'s register-side selector are asserted **byte-identical**; both read `^\| DP-[0-9]` today. Located by fixed string with an exactly-one-occurrence precondition, fail-closed on either side. |
| **Arm coverage, computed not restated** | correction item (adversarial FM-2) | The pass message claimed it pinned "the b0/b1/b2 branches" while **b1 was pinned by nothing** (measured: b1's message present in-block once, matched by 0 of the 6 fragments). Rather than correcting the sentence, the claim is now computed: **all 4** finding-emitting lines in the block must be covered by some pin, so adding a branch unpinned FAILS naming the line and the message cannot rot again. |
| Pairing invariant | per-issue (AC-2, M2 closed) | In-block comment-stripped: `flag_warn_or_issue` **4**, `c45_ok=0` **4**, `continue` **0**. Scoping control — the same two counts whole-file are **183 / 8**, so the 4/4 is genuinely block-scoped and not a whole-file artifact. |
| **Falsification harness actually runs** | correction item (adversarial CD-1) | As designed the harness was gated behind an env var **nothing set** — it would have run exactly once, at Stage 6, which is the artifact the design rejects in its own words. It now runs **by default**, so `install-tests.yml:284`, which already invokes this test bare, executes it with **no workflow edit** — `install-tests.yml` stays a read-only row and this card stays clear of the sole workflow writer. Only the harness's own children short-circuit. Cost, measured 3 runs each: **0.21 / 0.21 / 0.23 s** assertions-only vs **3.46 / 3.52 / 3.51 s** with 13 children. |
| Harness attribution, not exit codes | correction item (adversarial FM-3) | **13 rows, all bite by name.** Each mutant must emit *that pin's* named message; an exit code alone is refused. The expected message is itself derived from where the fragment sits — corrupting the block's first line trips NOSET, its last line trips the extent postcondition, anything between is caught by the fragment loop — so no hand-maintained expectation list exists. Anchor uniqueness is asserted in-block before every substitution (count ≠ 1 aborts the row as a setup failure, never a silent skip). |
| **Meta-falsification: the harness can fail, and block-scoping is load-bearing** | per-issue (AC-3) | Reverting *only* the fragment match back to whole-file `"$DEPLOY_SH"` makes the harness **FAIL** the selector row: `suite went red, but NOT for this pin`. The decisive detail is that the suite goes red **anyway** on that mutation — the sensitivity arm still catches it — so an exit-code-only harness would have scored the row a **pass**. The named-message requirement is what detects that the pin stopped biting, and this is direct evidence both that the harness discriminates and that block-scoping does real work. |
| Derived mutation set | per-issue (AC-3) | The harness reads its mutation set from the same `FRAGS` value the drift guard consumes — one value, two consumers, no parallel list — so a pin cannot be added without being falsification-tested. Plus 3 hand-authored rows the pin set cannot express (repoint, loosen, drop `c45_ok=0`) and **1 unmutated control row**, which must stay green so a red is earned rather than the harness's default. |
| External matrix, independent mechanism | per-issue (AC-3) | A `python3` driver rebuilt the mutations outside the test and ran the shipped suite against each with the harness short-circuited, so it measures the same assertion set Stage 5 measured. **12 enumerated rows, agree 12, disagree 0.** M0 GREEN (`21 passed, 0 failed`); M4, M4′, M2, the terminator rename, `M3-alt`, and all 6 original pins RED. Sensitivity 11 of 12 RED, specificity M0 GREEN — so RED is not the default. |
| Assertion count | per-issue | **13 → 22**, plus 13 falsification rows. **No pre-existing assertion was removed** — T1–T6′, the fixture-leakage invariant, the drift guard and the zero-`continue` assertion all survive; the drift guard's scope changed and its pass message became computed. |
| `deploy.sh` untouched | contention (rank 2) | **0 lines changed.** `git diff` over the branch's two commits touches exactly `core/deploy/tests/test_check45_governing_doc_name_match.sh` and `core/standards/gate-efficacy-standard.md`. The comment at the `# (b) FMF-1` block's `The fixture self-test asserts this shape directly` line remains true and was re-read in full rather than assumed. |
| `gate-efficacy-standard.md` two-writer surface | contention (rank 4) | **One line changed in place, at line 176, additive to the falsification column only.** The file is **235 lines before and after — zero delta — so no coordinate in it moves for #5252 at position 8.** Structure-shaped probe over the whole file rather than my row alone: the column-count profile is byte-identical (`{2:5, 3:17, 4:5, 5:28}`), row 176 still splits into 5 cells under escape-aware splitting, and **234 of 235 lines are byte-identical** with 176 the only difference. |
| Check 45 behaviour unchanged | regression (DoD 4) | `deploy.sh --check` Check 45 reports **`OK: conformance subsection present; all register governing_doc targets resolve AND name their own principle; all DP-id references defined`** — unchanged, as required, since `deploy.sh` is not edited. |
| Doc-link integrity | integration | `deploy.sh --check` Check 14 — **OK, no broken cross-refs in scope.** |
| Bash 3.2 compatibility | regression | The suite passes under **`/bin/bash` 3.2.57**, the interpreter the macOS `shell-tests` job runs, as well as under the default `bash`. Worth asserting because the harness re-invokes the suite as a child process. |
| Full `deploy.sh --check` | regression | **5 issues = 3 distinct FAIL subjects, none in this change set** — the stale `release-planner` package (untouched on this branch, warn-class exit 2 that will not block the merge), release-body drift across 13 previously-logged releases, and a `count-structure` finding in `core/references/reference/operator-instance-home-and-isolation-key.md` from an earlier release. Probe: **0 of the branch's 3 changed paths** intersect any FAIL subject; the control arm fires at **1** against a subject this card does own, so the zero is discriminating rather than vacuous. |

**A count I am not carrying, and why.** The systemic whole-file-guard population outside this card has now been measured three times by three parties and reported as three different numbers. This card fixes **one** instance and does not touch the rest, so no figure for that population is load-bearing here; a follow-up should re-derive it live with a hand-classified split rather than inherit any of the three. Recorded as a routing caveat, not a measurement.

**What this card still does not cover, stated because scope is its whole subject.** The liveness arm asserts the selector is not dead against the live register; it cannot assert the register's *rows* are individually well-formed, which is (b)'s own job at deploy time. The specificity arm defeats the two loosenings that have concrete decoys; it is not an enumeration of every conceivable one. And the extent band is a stated band, not a byte-exact pin — it catches a boundary move of thousands of lines, which is the observed failure mode, and deliberately tolerates the handful of lines an ordinary branch edit moves.

---

#### #5252 — absent-is-pass disposition · position 8 · landed `a8470acf` + `fa0c68d9`

Every figure below is **re-measured on the shipping tree** at build time, never carried from the Stage-5 design or from its adversarial review. All detectors are `python3` — never the shimmed local `grep`, never a `git grep` word boundary — and every zero is paired with a control arm observed non-zero on the same extraction.

| Check | Family | Observed |
|---|---|---|
| Per-workflow disposition, as built | per-issue (AC-2) | **3 CONVERT** (`deploy-check-ci`, `release-link-check`, `skill-license-check` — filters deleted, `always-reports=yes`) · **3 BIND** (`close-completeness` +2 roster entries, `release-tooling-smoke` +1, `version-freeness` +2) · **1 RECORD** (`release-corpus-completeness`, declaration only, trigger byte-unchanged). Non-uniform by measurement, not by preference. |
| Post-change population | per-issue (AC-3) | **22 workflows · 4 path-filtered · 18 filter-free · 0 declared-vs-actual mismatches**, from a structural PyYAML read of `on.<event>.{paths,paths-ignore}` compared against the header's field map split on the 2-or-more-space layout (so the compound `required(warn-mode-initial)` token survives). Denominator 22 files, **22 of 22** carrying a `gate-efficacy:` header. |
| **The 0-mismatch control arms — re-armed per FM-1** | per-issue (AC-3) | The Stage-5 record's arms proved only extraction non-emptiness. Replaced with **PV-2a mutation arms**: injecting `always-reports=yes` into a still-filtered header (`version-freeness.yml`) → **FLAGGED**; injecting `skip-semantics=absent-is-pass` into a filter-free header (`link-check.yml`) → **FLAGGED**. Specificity: the unmutated re-run over the same non-empty 22-file input → **0**. The zero is therefore discriminating. |
| The headline gap, re-measured | per-issue (AC-1) | `skill-license-check.yml`'s roster held **8 entries** (4 per event) and **0** equal to bare `LICENSE`, against a sensitivity control of **2** entries naming `packages` and a specificity control of **0** for a fabricated path. `check-skill-licenses.py` sets `ROOT_LICENSE = REPO_ROOT / "LICENSE"` (`:31`), reads it at `:61`, and globs `PACKAGES_DIR` for `*.skill` (`:63`). |
| **The gap is LIVE, not latent** (adversarial PR-1) | correction item | `packages/` holds **55** tracked `.skill` packages / **111** tracked files, **0** untracked-and-unignored, against a sensitivity control of 22 tracked files under `.github/workflows/`. Live run: **`=== 55/55 packages OK ===`, exit 0, 0.047 s**. So one repo-root `LICENSE` edit stales **55 committed packages today** — the design's empty-`packages/` premise was false and the severity is *higher*, not lower. Every artifact resting on that premise was rewritten rather than annotated. |
| **DF-3 withdrawn** | correction item | The Stage-5 design routed a next-release item for "⑥ reports green over an empty population." That condition does not obtain — the population is 55 and the green reflects 55 genuine passes. The routed item is **withdrawn**, not deferred; filing a card against a non-existent defect is governance debt. |
| **FM-2 — the anchor limb struck** | correction item | `--check-anchors` occurs **0 times** in `release-link-check.yml`, against a sensitivity control of **6** for the tool's own name and a specificity control of **0** for a fabricated flag; its help text reads "Default OFF." A heading rename is therefore **not** in ④'s verdict scope, and the shipped header says so explicitly rather than claiming coverage the invocation does not deliver. The disposition is unchanged — file-existence targets still resolve against `REPO_ROOT`, so Limb 1 still fails unclosably. |
| **CORRECTION ITEM 1 — the VIC clause** | correction item (adversarial PR-2) | The `C — control` class ships reading **"Files that are **not git-ignored**"**, never "tracked", with the reason stated inline: an untracked-but-unignored path can appear in a PR because creating it IS the PR. Verified in the landed text: the subsection spans `gate-efficacy-standard.md:72–93` and the C-class clause is line **80**, which carries both the corrected wording and the reason the two sets differ. This was the one finding that would have written the card's own defect into durable governance text, and ⑦'s sentinel tripwire now follows *from* the criterion rather than despite it. |
| **CORRECTION ITEM 2 — the declared-vs-actual ratchet** | correction item (adversarial CD-1) | Confirmed the gap first, and **corrected the review's own figure while doing so.** Outside `.github/workflows/`, `skip-semantics` occurs in exactly **2** tracked files (the standard, and one `gate-efficacy:` annotation at `deploy.sh:1818`) across a decodable denominator of **1,696** — the file count reproduces, but the review's "both occurrences" does not: there are **4** occurrences, and the load-bearing property is that **none of them is an assertion**. So no executable asserted header⇔filter consistency, which is what CD-1 actually rests on. Built `core/deploy/tests/test_gate_efficacy_declarations.py`, wired as a step in `install-tests.yml`'s `shell-tests` job — filter-free, so the ratchet is not skippable by the class of change it polices. Live run: **22/22 conform, exit 0.** **Superseded at Stage 6 re-entry (F-1):** that "22/22" was a **file** count published as a declaration count — the ratchet graded one `gate-efficacy:` header per file, and the tree carries **25 header declarations across 22 files**, so **3 were never graded** (`repo-integrity.yml` carries 3, `security.yml` carries 2). A mutant injecting `skip-semantics` into `repo-integrity.yml`'s **second** declaration **survived**. It is now a differential grader over all declarations, keyed by `file:line`, reporting both counts; new arm **A8** mutates a **non-first** declaration, which every pre-existing arm structurally could not do. Re-run: **25/25 declarations across 22 files conform, exit 0**, and the surviving mutant is now **killed** with an unmutated control staying clean. |
| **The ratchet, mutation-graded** | correction item | **9 mutants, 9 killed, unmutated control green.** One mutant per finding branch (all five), plus a blind detector, an over-matching detector, and a trigger-read forced false. **The grading found a real hole in my own harness and it was fixed rather than reported:** the first arm set covered 3 of 5 branches, so deleting either *value* branch left the suite green (`B3` survived). Arms **A6/A7** were added — one per branch — and the branch mutants then all died. One mutant **survives by construction** and is recorded rather than omitted: deleting the harness's own call site cannot be caught by an in-file arm without a circular self-grep the same edit defeats. That is a self-reference limit, not a coverage gap. |
| Both conversion baselines | per-issue (blast-radius items 3 + 4) | **Green at the landing commit, not deferred to Stage 7.** ④: `--self-test` exit 0, bare exit 0 (`=== 0 broken links across 0 files ===`, 0.322 s), `--plan-depth-lint` exit 0. ⑥: exit 0, `55/55 packages OK`, 0.047 s. Note the ④ output reads `files_with_broken`, i.e. files **with findings** — a clean result over a full `--roots release` walk, not an empty population. |
| `actionlint` — a live required context | integration | **Exit 0** over the 8 edited workflows individually, and **exit 0** over the whole 22-workflow set under the exact CI invocation (`-ignore 'shellcheck reported issue in this script: SC2016:.+'`). Un-ignored, the tree carries 8 `SC2016:info` findings, **all in `reference-durability.yml` and `repo-integrity.yml`** — pre-existing, in files this card does not touch. |
| Workflow-injection surface | integration (security) | Measured over the card's whole landed diff (`203ff25c..HEAD`, excluding this plan file): **0** of the **330** lines added to the eight workflow files carry a GitHub expression-interpolation opener, against a sensitivity control of **18** added lines containing `paths`; **0** across all **696** added lines. No interpolation enters any `run:` block — the only such occurrences in these files are pre-existing `env:` bindings already following the safe pattern, and none is on an added line. Measured with the opener assembled at run time rather than written literally, because a probe that spells the token can be matched by the very detector class it reports on. |
| AC-4 — required contexts | per-issue (AC-4) | Re-read live at build time per PR-3's re-check obligation: **9** contexts, unchanged from the design's read, and **none of the seven** workflows supplies one. This change registers no new context, so it cannot regress AC-4. The three converted jobs add three *reporting* members and **zero** blocking ones. |
| **② joins an existing declared-but-unregistered class, and the accepted-residual count was an undercount** | integration (D-5252-E, corrected) | `deploy-check-ci.yml`'s converted header names `enforcement=branch-protection:"Pre-merge load-bearing check subset"`, a context not in the live 9 — so it joins the class D-5252-E accepted as an already-governed Requirement (c) coverage-audit item rather than a new defect. **That is deliberate and it matches the exemplar exactly:** `skill-package-freshness.yml`, the shipped precedent this card's conversions follow, carries the identical shape and is in the same class; the standard says a `posture=required` declaration records the *intended* posture and that reconciling it is an audit item, not a per-gate edit. **The class is larger than D-5252-E recorded: 7 workflows, not 5.** Re-measured: **25** `gate-efficacy:` header lines across 22 files (three files carry more than one — the design's extraction kept only the last per file and under-reported), **11** workflows declaring a branch-protection surface, **18** declared context names of which **9** are registered and **9** are not. Pre-change the class was **6**; ② makes it 7. Specificity control: a fabricated name is not treated as registered. |
| Doc-link integrity | integration | `check-doc-links.py` under the exact CI invocation — **0 rows** (header only). `--self-test` **OK, 11 fixtures**. |
| Self-containment | integration | Over all **696** authored lines of the card's landed diff excluding this plan file: **0** bare `#NNNN` refs, **0** GitHub URLs, **0** URLs of any kind, **0** personal-email forms, **0** `/Users/` paths, **0** milestone refs. Sensitivity control fires; specificity control returns 0 for a fabricated token. |
| Fragile-reference classes, durable-corpus scope | integration | `core/standards/gate-efficacy-standard.md` is the change set's only path matching the gate's `is_durable()` predicate. Over its **27** added lines: **0** markdown-link sequences, **0** issue refs, **0** raw ledger URLs, **0** version-cutover tokens. The release plan is out of scope by allowlist (`release/releases/plans/` is a directory-prefix exemption). Sensitivity control: 760 added lines repo-wide; specificity control: 0 for a fabricated needle. |
| Runtime suite | self-verification | **Row 2 selects** (`core/deploy/**` — the new suite lives at `core/deploy/tests/`; row 4's globs are `core/deploy/tools/*.{py,sh}` and `*` does not cross `/`, so row 4 does not reach it). Row 2's suite is "the deploy `run:` steps in `install-tests.yml`" — a CI-hosted macOS job that gates pre-merge. **The local form is recorded as UN-RUN rather than run unsandboxed.** The selection map mandates a `HOME`→`/tmp` override for those suites, and the worktree-isolation control refuses a `HOME=` assignment in this session. Running them without the override would point them at the real operator `HOME` — obtaining a green by removing the isolation the sandbox exists to establish — so they were not run. What DID run locally is the one member of that job this card authors: the new ratchet, under `/usr/bin/python3` 3.9.6 (the exact CI interpreter the job's PyYAML step asserts against), **exit 0**. |
| Full `deploy.sh --check` | regression | **5 issues = 3 FAIL + 2 DRIFT, none in this change set**, and the set is unchanged from position 7 — this card introduces nothing. FAIL: the stale `release-planner` package (untouched on this branch — `git log 8dc00db1..HEAD` over its tree and its package is empty; warn-class exit 2, so it will not block the merge), release-body drift across 13 findings / 62 logged releases, and the `count-structure` finding at `core/references/reference/operator-instance-home-and-isolation-key.md:128,182` from an earlier release. DRIFT ×2: `pmo-qa-auditor` installed-copy drift, which is position 1's change not yet deployed to the operator install — operator-instance, never CI. **Discriminating probe: 0 of this card's 11 changed paths intersect any FAIL or DRIFT subject**, against a sensitivity control that fires at 1 when the subject is seeded into the path list and a specificity control that returns 0 on a near-miss filename. |

**Landing coordinates in `core/standards/gate-efficacy-standard.md` — the two-writer surface.** The file is **234 → 260** lines (`wc -l`; +26). My landings: the `### Verdict-Input Closure` subsection at **72–90** (inside Requirement (b), between the declaration-schema bullets and § Realization per surface); the rewritten path-filtered register row at **184**; three new register rows at **203 / 204 / 205**; the Version History row at **260**. **#4440's row moved and its content did not:** its `# (b) FMF-1` marker row was line **176** and is now line **198**, **byte-identical** — the +22 shift is entirely my Requirement (b) insertion sitting above it. #4440's own record pins 176, so a reader following that pin must add 22. This is why that card pins by inline marker rather than by line number, and the pin still resolves.

**Merge-conflict coordinates against concurrent draft PR #6119** (milestone `selftests-actually-test`), which edits the same two workflow files. Recorded as hunks so resolution is mechanical rather than archaeological. The operator ruled PROCEED-and-handle-at-merge, so no disposition was adjusted to avoid the overlap.

| File | Lines | My hunks (new-file coordinates) | What lands |
|---|---|---|---|
| `.github/workflows/install-tests.yml` | 773 → **847** (+74) | `@@ -56,12 +56,35 @@` → **56–90**; `@@ -387,21 +410,27 @@` → **410–436**; `@@ -412,6 +441,51 @@` → **441–491** | (1) header suite enumeration: the `test-status-label-invariant.sh` entry's trigger rationale retired, and a new `test_gate_efficacy_declarations.py` entry added (names the file at **70**). (2) the step comment's "WHY THIS JOB" list: reason 3 marked **RETIRED** with its replacement reason stated (markers at **414**, **425**); reasons 1–2 unchanged. (3) a **new final step in the `shell-tests` job**, inserted immediately before `  hook-tests:` — `run:` at **487**. **No job, matrix, trigger, step ordering or existing `run:` line is modified.** |
| `.github/workflows/release-tooling-smoke.yml` | 1359 → **1388** (+29) | `@@ -266,6 +266,26 @@` → **266–291**; `@@ -294,6 +314,8 @@` → **314–321**; `@@ -708,8 +730,15 @@` → **730–744** | (1) one roster entry appended to `on.pull_request.paths` after `.github/corpus-home-tolerance.arming` — the entry itself at **288**. (2) the same entry appended to `on.push.paths` at **318**. (3) the `release/tools/tests/` block comment: the parenthetical about the sixth suite corrected (the trigger ground retired, the genre ground retained; the suite is **not** moved). **No step is added, removed or reordered; header line 3 and the `:848` narrative restatement are byte-unchanged.** |

**File Change Matrix expansion, surfaced rather than absorbed.** The matrix declared **8 files**; **10** landed. `.github/workflows/install-tests.yml` was declared **READ-only** (for #4440) and is **edited** here, and `core/deploy/tests/test_gate_efficacy_declarations.py` is **added**. Both follow from correction items: the install-tests edits are the CIAC-4 reciprocal of ⑤'s roster widening — that file asserted, in two places, that `release-tooling-smoke.yml`'s filter omits `deploy.sh`, which this card makes false, so leaving them would ship a declared-vs-actual mismatch in a card whose subject is declared-vs-actual accuracy — and the new file is CD-1's ratchet. **New-executable companion obligations, checked rather than assumed:** the tool owes **no** `script-execution-allowlist.txt` row (all **257** non-comment rows are `.sh`; **0** are `.py`, and this is a `.py` invoked through `python3`), **no** `selftest-coverage-manifest.txt` row (discovery globs `core/deploy/tools/*.{py,sh}`, and `*` does not cross `/`, so `core/deploy/tests/` is out of scope), and triggers **no** Arm D warning (its globs are `release/tools/tests/**` and `core/deploy/tools/tests/**`). What it does owe is CI wiring, and that is the `install-tests.yml` step.

**Deviations, disclosed rather than absorbed.**

1. **The first three commits omit the `Refs #5252` trailer**, which every one of the branch's prior 15 commits carries and which Phase B1 requires ("reference issue numbers in messages"; G6-02, warn-mode). The omission is real and is disclosed here rather than repaired by rewriting history: amending three already-pushed commits on a **shared release branch** trades a warn-mode traceability gap for a force-push, and the parallelism taxonomy names force-push on the shared release branch as an excluded class. The trailer is carried from this commit forward, and the lineage it exists to preserve is intact by other means — `a8470acf`, `fa0c68d9` and `86aeda52` are named against this card in the Verification Evidence heading above and in the Stage-6 output comment.
2. **The Requirement (b) edit is a subsection, not the "two sentences" the Stage-5 per-file matrix specified.** The VIC criterion cannot be stated in two sentences and still carry the S/E/C member classes — and the C-class definition is precisely where correction item PR-2 lands, so it had to ship. `gate-efficacy-standard.md:72–93`, 22 lines including a 3-row disposition table.
3. **The File Change Matrix grew 8 → 10.** Recorded in full in § File Change Matrix under this card's block.

**Acceptance-criteria corrections carried forward to Stage 8.**

- **AC-1 is not satisfiable as written** and this is not a defect in the work: it grades against "this issue's disposition table", the issue body contains none, and ADR-062 forbids the spoke from authoring one there. Grade it against the **durable artifacts** — the disposition table in this section, the seven shipped workflow declarations, and the three register rows at `gate-efficacy-standard.md:203–205`. AC-1's **control clause is discharged**: the pre-change filtered count re-measures at **7**, and the delta from the body's 8 is the previously-shipped conversion.
- **AC-2's denominator is 6, not 7.** `release-corpus-completeness.yml` passes Limb 1 and is out of AC-2's reach; grading it as an unfixed disagree-case would be a false NOT MET. Of the six: 3 filters removed, 3 scopes explicitly bound.
- **AC-3's denominator is 22, not 21**, and **its fixture hand-off is corrected per FM-1.** The Stage-5 output offered "PR-1's specificity fixture" — a `paths:`-token-inside-a-`run:`-step near-miss built for the *population* probe, which cannot fail on a *declaration* mismatch. Use a **declaration**-mismatch fixture instead: a filtered workflow declaring `always-reports`, or a filter-free one declaring `skip-semantics`. Both are implemented as arms A1/A2 of the shipped ratchet and can be re-run directly.
- **AC-4 is satisfiable and was re-read live** (9 contexts, none of the seven). Re-read the endpoint again at Stage 8 rather than trusting this row — branch protection is out-of-tree mutable state.

#### #4931 — issue-body section-anchor validation · position 9 · landed `414b49e5` + `1a46f6e6` + `9a60ad83` + `0b5d49aa` + `e5bd8c5b`

**Baseline pin for every count below: 457 open issues / 1,769,763 body bytes / 1,786 tracked paths, 2026-08-25.** The population moved 519 → 515 → 506 → 505 → **457** across five pins in this release alone, so re-measure at merge rather than carrying these figures (audit-baseline discipline).

| What | Scope | Result |
|---|---|---|
| **AC-3 partition, re-measured** | correction item (adversarial AC-3, Major) | The amendment handed Stage 8 a baseline of **229 verdicted / 15 not-run** that a *correct* implementation cannot produce. Measured under the shipped predicate: **204** resolved · **2** UNRESOLVED · **19** degraded-not-tracked · **8** degraded-basename-ambiguous · **7** not-run non-markdown · **2** not-run unnumbered — **242** in-grammar bound citations, of which **206** are verdicted. The `degraded` class is **27 of 242 (11%)** and was absent from the amendment's arithmetic entirely. Adding the named arm (**211**), the out-of-model-prefix class (**181**) and bound-to-no-path (**216**) gives **850** sites entering some Register A member. |
| **P2-1 residual, measured** | correction item (adversarial P2-1, Major) | The CIAC-4 header declared each boundary item as *"carrying its measured baseline count"* with no measurement behind it. Taken: **181** bound citations behind a prefix outside the modelled five, of which **54** name a **real ATX heading** in the tracked markdown file they cite. Every count in the tool's declared coverage boundary is now a number that was taken, reproducible via `--census`. |
| **CD2-1 decided as one scope question with P2-1** | correction item | **CD-B adopted** — publish the measured residual; do **not** widen the citation grammar. Reason, verified independently rather than inherited: admitting the dominant unmodelled prefixes to the citation side **alone** flags correct citations, because §E4's target-side extractor does not model them either. Widening both grammars together is the better instrument and is a larger move than D-20 authorizes. |
| **AC-4 reproduced** | correction item | The amendment re-asserted **#5278** as "the expected finding" in the same paragraph that says re-measure. It is not reachable: all four of its glyph anchors fail B1's connective-only head rule (the gaps carry the word tokens `edit` / `update`), so it lands in `not-run: anchor bound to no path`. The whole-population finding set at this pin is **{#5822 ×2}**. A grader told to expect #5278 would mark correct work as failing. |
| **AC-5 settled by measurement** | correction item (settles **D-14**) | `git diff --stat` against the branch base: **8 changed rows** on §G's counting convention, **plus the ADR = 9**. The operator-recorded D-14 figure ("8 changed + 4 read-only") was correct; the amendment's "5 changed" was the superseded DR-6 row carried forward. |
| **AC-2 discharged** | correction item | The mandated *"this is not a clean result"* clause is in the **detail string**, not assumed from the emitter. Verified at source: the emitter's own log line does not carry it, and its contract comment places the obligation on the detail. Both Check 71 detail strings end in the clause, matching the sibling on #6000 and the sole live existing caller. |
| **FM2-1 discharged** | correction item (**D-20 edit 4**) | A4.8 now states its exit-3 handling: emit a NOT-EVALUATED feasibility flag naming the cause, withhold every per-issue verdict, never report an issue as anchor-clean. The two consumers shared one exit code and only the deploy limb had a stated branch. |
| **D-20, all four edits, and only those** | operator ruling | (1) the dead `resolve_check_mode` call is absent; (2) no warn-shakedown / `.mode`-flip prose in the Check 71 block; (3) the symmetric omission on the A4.8 triage limb; (4) the FM2-1 clause. **F-2 is unchanged, FM-1 was not re-opened, and no other accepted §E5 text was touched.** |
| **Locale defect, found by measuring** | self-verification | The heading extractor addressed the section glyph as its UTF-8 bytes, so under a character-oriented locale it returned a **short** number set rather than erroring — **18** numbers under `LC_ALL=C` vs **2** under `en_US.UTF-8` on the same tracked file. A short set makes real sections invisible and reports correct citations into them as UNRESOLVED. Locale is pinned; a dedicated self-test control arm asserts `fx-alpha.md → 1,2,2.1,3`. |
| **Field-collapse defect, found by the self-test** | self-verification | The grammar emitted an **empty** path field for an unbound anchor; the consumer reads those rows with `IFS=<tab> read`, which collapses runs of IFS whitespace, shifting every later field left. The section number landed in the path slot, resolved as a filename, and was recorded as `degraded: target not tracked`. Both counters stayed plausible and the totals still reconciled. At this baseline it silently recoded **216** citations. Fixed with an explicit sentinel; proven both ways in one run (`a\tb\t\tc` → `(a,b,c,∅)`; `a\tb\t-\tc` → `(a,b,-,c)`). **No assertion was loosened to reach green.** |
| Check-number next-free | integration | **71.** 69 registrations / 68 distinct, min 1, max 70, gaps `[15, 24]` (both RETIRED-RESERVED, never refilled). Specificity control `log "Check 999:` → 0. |
| Check 57 extraction contract | integration | Both halves present: a `# Check 71` def-block **and** a `log "Check 71:"` emitter, so the documented derive-from-source command stays complete. |
| §H cascade sweep — **verified, not carried** | integration | Stage 5 flagged one dependency for Engineering to verify rather than assume. Probed all **1,774** tracked paths (**1,719** read / 34,051,256 bytes): **no tracked file states an authoritative total count of deploy checks**; the single near-hit disclaims one outright (*"NOT 'all ~38 checks'"*). **T1 does not fire.** Sensitivity control `Check 70` fired non-zero; specificity control `Check 9zzqqx` → 0. |
| Lifecycle-table row | integration | **None required, and this resolves the one #6120 contention point.** The table's stated maintenance rule adds a row only when a check is *retired* or *dormant*; Check 71 is live. |
| Selftest-coverage manifest | integration | **Regenerated** with `--emit-manifest`, never hand-edited. Diff is exactly one line. `--reconcile`: **ARM B / ARM C / ARM D all PASSED** (67 paths; runner partition total and disjoint). |
| Static analysis | integration | `shellcheck --severity=warning` **clean** on the new tool and `--severity=error` **clean** on `deploy.sh`. Five real findings fixed en route (an unemitted baseline pin, an unused Register B token, a dropped body-line in the finding payload); one suppressed with a stated reason (`--json number,body` is one argument, not two array elements). |
| ADR numbering | integration | **ADR-145.** The oracle returns 142 because it reads the mainline; 142/143/144 are claimed by siblings on this branch. `check-adr-numbers.py`: **PASS — 145 ADRs, contiguous 001..145, no duplicates.** `check-adr-durability.py`: 145 scanned, **0 findings attributable to this record**. |
| Self-containment | integration | Over the **985** authored lines outside this plan file (19 files): **0** absolute user paths, **0** email addresses, and **1** `#NNNN` reference — the `[#4931]` provenance tag in the Check 71 def-block header, which is the established convention for that surface (**17** pre-existing check headers carry the same tag form). Sensitivity control: 358 in-scope lines contain `#`, so the zero-findings result is not vacuous; specificity control on a fabricated token → 0. |

**Landing hunks — recorded so merge resolution against the two concurrent draft PRs is mechanical.** Both are pure insertions with zero deletions.

| File | Hunk | Lines | Collision |
|---|---|---|---|
| `core/deploy/deploy.sh` | `@@ -12203,0 +12204,73 @@` | 14,414 → **14,488** | **None.** #6120 touches `main:3924` and `main:13265`; the branch's prior landed hunks are at 4436–4482 and 13947. My block appends after Check 70, ≥3,500 lines from the nearest sibling hunk, and needs **no** lifecycle-table row — so #6120's insertion at the lifecycle/`cmd_check` boundary is not contended after all. |
| `core/deploy/allowlists/selftest-coverage-manifest.txt` | `@@ -76,6 +76,7 @@` | +1 at line 79 | **Three-way surface**, union merge. #6119 and #6120 each add one line; all three paths are distinct. |
| `core/config/allowlists/script-execution-allowlist.txt` | `@@ -355,0 +356,17 @@` | +17 | None declared. |

**Deviations, disclosed rather than absorbed.**

1. **The five commits omit the `Refs #4931` trailer** that the branch convention carries. Not corrected by rewriting: § Delivery Strategy prohibits force-push on the shared release branch, *including* `--force-with-lease`, and the commits were already pushed. Same disposition as #5252's first deviation.
2. **The `--self-test` harness and the live scan were NOT executed by this spoke**, and the suite is reported **un-run rather than run unsandboxed**. `BLOCK-DESTRUCTIVE-022` blocks `bash <path>` for any tool absent from the *deployed* allowlist, and the four governed rows this card adds land in the repo source — the deployed copy refreshes at deploy, not at commit. No bypass was set and no second tool was used to reach the same effect. What *was* executed: the shipped `grammar.awk` and `headings.awk`, extracted byte-for-byte from the tool rather than retyped, driven over both the live 457-issue corpus and the fixture corpus. The fixture run reproduces the self-test's assertion table exactly — resolved 4 · unresolved 2 · non-markdown 1 · out-of-model-prefix 1 · not-tracked 1 · no-path 1, locale arm `1,2,2.1,3`. **The bash orchestration layer around those cores is unexercised and is Stage 7's first obligation.**
3. **The fixture corpus landed at `core/deploy/tools/fixtures/issue-body-anchors/`**, not under `tools/tests/fixtures/` as the plan block declared — matching where the selftest-discovery `core/deploy/tools/*.sh` scope directive actually looks.
4. **The File Change Matrix grew 7 → 9.** Both additions were pre-declared in the Stage-5 §G matrix; recorded under this card's § Change Description block.

**Acceptance-criteria corrections carried forward to Stage 8.**

- **AC-1 is broader than the delivered scope on three axes, and grading it literally would fail correct work.** Grade as: *in-grammar numeric anchors into tracked markdown targets are resolved; every other class is counted and declared, none silently dropped.* The three narrowings are (a) numeric only — named anchors are a counted `not-run` (**211** at this pin); (b) five modelled prefixes — anything else is counted and declared (**181**, of which **54** name real headings); (c) verdicts only for tracked **markdown** targets (**7** non-markdown at this pin). This narrowing is the design's central evidence-grounded decision, not a shortfall.
- **AC-2 ships as specified.** Verify the existing-sections payload is the **full** sorted number set rather than a sample, and note the finding row also carries the body line number.
- **AC-3 ships as specified** via the Register A state model. Verify the distinction survives the TSV/JSON boundary — a consumer reading only the finding count must not be able to conflate a degraded read with a clean one.
- **AC-4 ships as §2d** of the intake style guide.
- **The card's motivating exemplar is still not flagged, and that is correct.** `roadmaps/skill-matrix.md` is git-ignored, so it lands in `degraded: target not tracked` (**19** such at this pin). The shipped check does not catch the case that started the card, by design — EG-1 chose tracked-in-git over filesystem-present so the same citation cannot resolve locally and read unreadable in CI.

---

## Delivery Strategy

- **Branch:** `release/checks-see-whole-subject`, cut from `origin/main` @ `8dc00db1`. Slug form, not version form — the version is provisional until the Stage-12 atomic claim.
- **Topology:** D-C **SINGLE**. One branch, one PR, one merge gate. Issues are delivery slices on one branch.
- **Commits:** one commit or short commit sequence per card, in build order, each referencing its source issue. Commit 0 is this plan file.
- **Sub-task container:** GitHub sub-issues (the structured path). The decomposition is nine multi-file, calibration-sensitive units well above the checklist threshold, and several carry native dependency edges.
- **PR:** created in **draft** at Stage 6 and transitioned to ready-for-review at the Stage 9 gate.
- **Version binding:** the `**Version**` cell above carries the placeholder token. It resolves, and this file is renamed to its versioned home, at the Stage-12 claim.
- **Force-push prohibited** on the shared release branch under P0 serial execution, including `--force-with-lease`.

---

## Decisions Register

| # | Decision | Outcome | Gate |
|---|---|---|---|
| D-1 | Plan + Release Outcome Statement | **Approved** | Stage 4 |
| D-2 | Release Class | **Re-rendered `routine` → `cross-cutting`.** Soft edges count as compositional edges per the Stage-4 dependency graph, so trigger (c) fires at three in-bundle edges. Highest-ceremony resolution applies. | Stage 4 |
| D-3 | #4992 sizing | **`size:M` → `size:L`** with a recorded band override; the delimiter-axis split was rejected as contradicting the Release Outcome Statement. | Stage 4 |
| D-4 | #5260 + #5074 | **One Engineering build-unit**, both cards remaining open with their own sub-tasks and closure records. | Stage 4 |
| D-5 | Implementation sequence | **Spoke divergence adopted** — infra band ordered #4720 → #5260 → #5074. | Stage 4 |
| D-6 | Plan amendment (consolidated) | **Approved** — File Change Matrix expanded; Contention Map amended; `deploy.sh` in-release writer count corrected. | Stage 5 wave 1 |
| D-7 | CIAC-1 scope | **Approved** — extraction scoped to status fields, so population labels are not graded as measurement states. | Stage 5 wave 1 |
| D-8 | ADR authorization | **Approved, all three.** Each claims next-free per the renumber oracle; none reserves above a sibling's unmerged claim — a gap blocks the repo, a duplicate is tooled. | Stage 5 wave 1 |
| D-9 | #4720 risk R-4 | **Ruled IN-SCOPE**, diverging from the hub recommendation. Consequence: #4720 re-sized `size:S` → `size:M`. | Stage 5 wave 1 |
| D-22 | Defective acceptance criteria | **Corrected wordings land in this plan as the canonical Stage-8 grading contract** (§ "The corrected acceptance-criteria wordings"), because ADR-062 forbids amending issue bodies. **14 defective criteria of 38 graded, across 7 of 9 cards**, measured at re-entry; two cards tested clean and are recorded as such. The systemic gap behind them — criteria never reconciled against the accepted design — is filed as **#6170** and does **not** gate this release. | Stage 6 re-entry |
| D-Version | Release version | **v4.39**, recorded at Stage 4 and re-verified at Engineering Commit 0. | Stage 4 / Commit 0 |
| D-Concurrency | Concurrency posture | **P0 fully-serial** under D-C SINGLE. | Stage 4 |
| D-ADR-4981 | ADR number for #4981 | **142** — the renumber oracle's next-free at the release baseline, computed across both ADR directories. Assigned at Commit 0 per D-2 of that card's design. | Commit 0 |

### Decisions still requiring operator judgment

| # | Decision | Recommendation | Reversibility / Confidence |
|---|---|---|---|
| **D-A1** | #4981's gate change re-aims an existing check from a zero-occurrence population to a live, currently-failing one. It is the better discharge and makes the check pass on what the release actually does, but it is a materially different gate change from the narrower one approved at the wave-1 gate. | **Adopt** | CHEAP / HIGH |
| **D-A2** | The sibling check inside the same skill reference still mandates the invocation form the re-aimed check now admits alongside others. Left unchanged, one file contradicts itself. | **Adopt** | CHEAP / HIGH |
| **D-A3** | Two sibling cards' integration criteria carry a superseded permitted-form list with a **closed** enumeration, and they grade at Stage 8. A spoke cannot edit a sibling's sub-task. | **(a)** hub re-issues the corrected list at Collective Review, **and (b)** #4981's change states that an integration criterion naming a form list grades against the shipped list. See R-11. | CHEAP / HIGH |
| **D-4734-Path** | #4734's build path is unruled. | Default to Path 1; Stage 6 is unblocked either way. | CHEAP / HIGH |
| **D-4992-D14** | Whether #4992 ships a pull-request-time reporting arm on the repository-integrity workflow. | Operator's call; the workflow file is **not** created speculatively. | CHEAP / HIGH |

---

## Change Description

### Outcome

Nine enforcement surfaces across the deploy, CI, pipeline-spec and disciplines layers each evaluated less than the subject they declared, and each reported clean over the remainder. After this release every one of them either evaluates its whole declared subject or says, in a distinct and machine-readable way, that it did not. The release is deliberately a set rather than a sweep: the failures share a mechanism, so one outcome statement covers them, and the fix is a coherent change to one property — *what a check can see* — rather than nine unrelated point repairs.

### Issues resolved

Nine, listed in § Scope. Each is marked as closed at Stage 13 on its own evidence, including #5260 and #5074, which build as one unit but close separately.

### Key decisions

The release class was re-rendered from `routine` to `cross-cutting` when the original rationale was falsified against live evidence, which carried the point total above the band and put it there under an explicit operator override rather than by trimming a card. Two cards were re-sized upward on evidence a Stage-5 spoke produced. Two cards were merged into a single Engineering unit without merging their tickets. #4981's design was amended twice under adversarial review — the second amendment withdrew a validity rule that would have condemned 18 of 30 correct probes on a working engine, and replaced it with a one-time engine assertion against a purpose-built fixture.

**#4720** was ruled in-release rather than accepted as a residual. Its Stage-5 spoke surfaced that replacing a capped search call with a cursor-paginated walk grows the transport failure surface from 10 requests to 54, and that a transport failure still exits 3 and takes two unrelated legs down with it; the spoke recommended accepting that and the hub concurred. The operator diverged, the card re-sized from `size:S` to `size:M`, and the resilience handling was designed and built rather than deferred. Its change surface widened from one file to three on the same decision — two of the additions being reconciliations of text this change falsifies, not new scope. A second operator decision folded the pass-1 adversarial finding **FM-2** in as a specified build item rather than shipping it as a residual, so the truncation predicate now reads its bound under first-page binding instead of a running maximum.

**#4734** replaces a predicate that had no stated subject. It asked whether a token appeared in a file when the question it meant to ask was whether the skill *declares* two or more modes, and a single prose sentence was enough to separate the two. The fix states the subject in the code and binds it to a location, so body prose is unreachable by construction rather than merely unmatched, and it collapses the two duplicated predicate copies into one engine — which also unified two divergent finding-emission contracts that had stayed invisible because the branch carrying them is unreachable on a clean corpus. Three operator decisions shaped what shipped. **D-13** pulled a third consumer of the same extraction idiom in-release rather than deferring it, which the single-engine factoring made cheap: a third consumer became another caller instead of another copy. The recognizer's **subject was then deliberately widened** under explicit ratification — and the naive widening was measured *first* and rejected, because it admits 12 files of which 10 are false positives, including the very file this card exists to stop flagging, which it re-admits and makes spuriously PASS. And the card's acceptance instrument was **inverted**: its original residual detector was the predicate's own arm, so it was empty by construction on every possible corpus, read 0, and was green — the 0 being the defect. Its replacement never looks at a heading, ships as a checked-in tool rather than a session artifact, grades its own controls rather than its count, and is **expected to report a non-zero residual**. A future run of it reporting zero is a failure, not a pass.

**#4992** is the release's clearest instance of the shared mechanism and the one card whose *premise* had to be corrected before it could be built. The check declared the operator-token vocabulary as its subject and reached 22 percent of it, narrowed on five axes — one prefix of four, one file extension, three roots, and a bracket delimiter larger than the other four combined. The delimiter axis had never appeared in the check's own reachability figure, because that figure was itself derived with a square-bracket matcher: the surface was in neither the numerator nor the denominator of the number describing it. Scope is now derived from the registry at runtime rather than declared in a pattern, and both limbs consume one derived value, so they cannot disagree.

The prescribed remedy was **overridden on the spec's own words**. The brief and the issue body both carried the premise that the vocabulary is one closed set; it is two. One section declares the square family closed, another declares the angle family open and incrementally codified, obliging only *newly authored* tokens to register. A uniform rule would have raised 239 findings the spec sanctions and encoded in the gate a closedness the governing document denies — a spec-versus-reality divergence created by the fix. So the check is family-aware: the square family gates, the angle family is inventoried through a structurally non-escalating emitter.

**The card's own approved scope item was then removed rather than shipped.** A stored baseline of tolerated angle tokens was designed, ruled in scope, and withdrawn under adversarial review: the file gating an authoring obligation is extendable by the very change that violates it, in the same diff, and the acceptance criterion written for it asserted that a baselined token is *not* reported — verifying the bypass rather than the rule. Nothing in the platform's workflow population exists to inherit a growth guard from, measured against a firing control, and the forward-ratchet precedent cited for it ratchets only because its tolerated set is empty by construction. The inventory is derived live instead, so it cannot drift from the registry. This is the inverse of the pattern the release exists to correct: a control whose stated guarantee and actual mechanism had diverged was removed, and the residual stated plainly — at deploy time the angle family is **observed, not gated**. Reach is 100 percent of the declared subject; gating coverage is the square family, 644 of 1,097 occurrence lines.

The obligation the open family does impose is a property of a **diff**, not a working tree, and a deploy-time check does not simulate one. A pull-request-time reporting arm is specified in full and buildable, with a named job, its own base-to-head file scope, no exemption channel, and its failing exit named as the enforcing line — and it is deliberately **not** in this release's change set. **D-4992-D14 remains open**, carried into Engineering on the corrected basis that no enforcement mechanism for that obligation exists today and that this arm would not create one: it would report a violation and turn a check red, and it would block a merge only after a separate operator-side branch-protection registration that no line in a pull request can perform.

**#4440** is the release's thesis turned on one of the release's own instruments. Check 45(b)'s fixture self-test pinned six fragments of `deploy.sh` and matched each against the whole file — so a pin was satisfied by *any* occurrence anywhere. The (b) loop's input selector happens to occur twice, once as (b)'s input and once inside sub-check (c), which meant the one pin that mattered was satisfied by the copy two lines further down. Repointing (b)'s input left every fragment resolving while the live check iterated an empty population and printed its success line. The card's prescribed remedy — pin the selector as one more fragment — was **overridden on a measurement rather than an argument**: the spoke built the prescribed fix exactly as written, ran it, and the mutation still passed. So the fix targets the mechanism. Every pin is now scoped to the marker-bounded block it claims to guard, and the live selector is not merely pinned but **extracted and run**, because a pin proves a string exists while only running it proves the selector still selects anything.

This card is also the one that carried its adversarial review's findings into Engineering as build items rather than residuals, and each of the three was a variant of the same defect one level further in. The block-scoping rested on the terminator marker falling outside the block "by construction" — a claim nothing asserted; renaming that marker widens the block from 75 lines to the remaining 4,501 while the fail-closed branch stays silent, because it tests emptiness and `awk` misses a terminator by running to EOF rather than by returning nothing. The behavioural arms ran only against fixtures the test itself authored, proving the pattern well-formed against a frozen grammar rather than live against the register the check actually reads. And the falsification harness — the instrument meant to prove the guard bites — was gated behind an environment variable nothing in the repository sets, so it would have run exactly once, at implementation, which is the decaying one-time attestation the design rejects in its own words. All three are closed: the extraction asserts its own postcondition and extent, a third arm runs the selector against the live register for liveness (never content, so a legitimate register edit cannot break it), and the harness **runs by default** — the CI step that already invokes this test bare now executes it, with no workflow edit at all. The harness also refuses an exit code as evidence: each mutant must fail with *that pin's named message*, and the value of that refusal is measurable — reverting the match to whole-file makes the suite go red anyway through a different assertion, so an exit-code-only harness scores the regression a pass while the named-message one names it. One further claim was computed rather than corrected: the guard's pass message enumerated the branches it pinned while one of them was pinned by nothing, so the enumeration was replaced by an assertion that every finding branch in the block is covered, which cannot go stale.

**#5252** is the release's mechanism applied to the trigger surface, and it is the card where the uniform answer was available, cheap, and wrong. Seven workflows declared that a skipped check may be read as a pass, and nothing had ever tested whether their path rosters actually covered the inputs that decide their verdicts. Tested individually, they do not agree: five fail on coverage, three declare a required posture their own surface cannot deliver while a filter exists, and exactly one is the legitimate cost control all seven claimed to be. So the card ships **three different outcomes** — three filters deleted, three rosters widened by the named inputs with the closure basis written into the workflow, one declaration corrected against an already-empty residual — and the non-uniformity is the finding, not a compromise. A blanket ruling either way would have been wrong for at least three of the seven, and the design says which three and why.

**Its sharpest finding turned out to be live rather than latent, and the design had it backwards on the reason.** The licence gate asserts every compiled package matches repo-root `LICENSE` byte-for-byte, and `LICENSE` was absent from its trigger roster — so the single edit that breaks every package at once was the one edit that could not fire the gate built to catch it. The design argued this while also asserting the package directory is empty between releases, which would have made the gap harmless; adversarial review measured **55 tracked packages**, so a licence-text edit stales all 55 today. The disposition did not change and its support did: every artifact resting on the empty-directory premise was rewritten against the measurement, and a next-release card filed against a condition that does not obtain was **withdrawn** rather than deferred.

**The card carried its review's open findings into Engineering as build items, and one of them was a defect about to be written into governance.** The criterion this card contributes to the gate-efficacy standard classifies the files that can switch a gate's behaviour, and the design scoped that class to *tracked* paths. An untracked-but-unignored file can appear in a pull request — creating it *is* the pull request — and the card's own ruling adds exactly such a path as a deliberate reversal tripwire, unreachable from its own criterion. One clause, `tracked` to **not git-ignored**, and the tripwire follows from the criterion instead of despite it. Getting that wrong would have shipped this card's own defect into the standard that fixes it.

**And the outcome it is graded on had nothing holding it.** "Zero declared-versus-actual mismatches" was a one-time human measurement: no executable anywhere asserted that a workflow's header agrees with its own trigger, so the very next pull request could add a filter without touching the header and no gate would see it. The review named the asymmetry — the *expensive, blocked* follow-up was routed and the *cheap, unblocked* one was invisible — and the ratchet is built here, hosted in a workflow that carries no filter of its own, because a conformance gate on trigger declarations sitting behind a trigger filter reproduces the defect one level up. Mutation-grading it found a real hole in its own harness — three of five finding branches covered, so deleting either value branch left the suite green — which was fixed to one arm per branch rather than reported. The one mutant that survives is recorded as surviving: a harness cannot assert its own invocation.

### Reversibility

**CHEAP / Confidence HIGH.** Every card reverts at commit granularity and the whole release reverts by reverting the merge. Two cards carry named per-card exits. No migration, no data change, no external system.

### Downstream impact

The probe-validity guidance #4981 lands is cited by every review-class skill that loads the discipline file and by the Stage-5 evidence-grounding review, so its blast radius is delivery-wide even though its diff is prose. The typed-status vocabulary #5260 and #5074 land becomes the shape later tools follow. The workflow dispositions #5252 lands change which checks report on which pull requests.

### Cross-references

Milestone `checks-see-whole-subject`. Stage-6 obligations for this file: each Engineering chip appends its entry to § Verification Evidence, and the final chip refreshes this section if the landed set differs from the plan.

---

## Canonical-checklist attestation

Recorded per stage as each completes. Stage 4 ran every codified phase step or recorded it N/A with reason; Stages 10 and 11 are PLATFORM-SATISFIED and closed.
