---
title: Release Plan — docs-match-shipped-state
purpose: Stage-4 release plan for the docs-match-shipped-state bundle, amended for every Stage-5 outcome and the Collective-Review scope-lock.
type: release-plan
plan_type: release
status: ACTIVE
release_class: novel
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->

# Release Plan — `docs-match-shipped-state`

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #5770, reconciled to the approved **Stage-5 Solutioning** designs (#5771 for #3698, #5775 for #4321) and the **Collective Review scope-lock** dispositions posted on #5771. Where a Stage-5 or scope-lock disposition superseded a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at **Engineering Commit 0** by the first Engineering spoke (sub-task #5772, issue #3698).

## Header

| Field | Value |
|---|---|
| Milestone | `docs-match-shipped-state` (#346) |
| Version | **{{RELEASE_VERSION}}** — identity **slug-only** per ADR-092. The concrete number binds at the **Stage-12 atomic claim**, when `claim-version.sh --stamp-slug` resolves this token. **D-Version was DETERMINED `version-less` (condition B) at Stage 4** — see § Open at plan time. Mainline at Commit 0 was `v4.35`. |
| Bump Class | `minor` |
| Release Class | `novel` — re-classified from `routine` at the Stage-4 plan-approval gate (2026-08-21, Friday); operative basis is novel trigger (b) plus multi-trigger resolution, **not** elimination-by-failed-triggers |
| Differentiation posture | Engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day** |
| Size | 22 pts across 9 issues — within the 15–25 pt band |
| Branch topology | **D-C SINGLE** — one branch (`release/docs-match-shipped-state`), one PR, one merge gate |
| Concurrency | Stage 6 **fully serial (P0)** — write-serialized on the single branch, dependency order beginning with #3698 |
| Baseline | `origin/main` @ `6d0e2080` (*Merge pull request #5820 … chore/v4.35-stage-13-corpus-update*), 2026-08-22 |
| Provenance | Bundled 2026-08-14 by `release-planner` Mode A/B; readiness cleanup 2026-08-16 (`release-hub` Mode R); composition locked at Stage-4 planning entry, 2026-08-21, sub-task #5770 |

---

## Scope

**Release Outcome Statement — AFTER this release:** published docs and release records match what actually shipped.

**BEFORE:** 84 CHANGELOG `[Full notes]` links are broken, 110 release notes sit foldered against a standard that forbids subfolders, and 39 published Release bodies are structurally drifted.

> **Read the 39 as a PRE-STATE, not as #4747's cohort.** 39 is the drift count measured at `origin/main`. This release itself authors 19 more (#3698's link repair rewrites notes whose bodies are already published), so the population #4747 must emit is **58**. See **D-4747-D**.

**Members (9):** #4747 · #3698 · #4321 · #4323 · #5192 · #4748 · #5191 · #5271 · #5072.

**Out of scope, release-wide.** `release/releases/plans/**` layout (ADR-092-backed, lint-enforced) · the `automated-closeout.sh` / `claim-version.sh` / `produce-learnings-register.sh` producers · `RELEASE_BODY_DRIFT_CHECK_CUTOFF` · the `WARN_MODE` / `deploy.sh` Check-14 posture flip (separate protocol, operator-owned) · pipeline stage specs · `CLAUDE.md` · `core/governance/OPERATIONS.md`.

---

## Dependency Graph

```
#3698 ──HARD──────▶ #4321        (the notes-layout mechanism sets #4321's repair-set size)
  │
  └──SERIALIZE────▶ #4747        (published bodies resolve the in-repo note BY PATH)

#4323   #5192   #4748   #5191   #5271   #5072      (independent — no in-bundle edges)
```

**`#3698 → #4321` is a HARD edge.** Under the settled mechanism (A-prime) #4321's CHANGELOG repair set is **4**, not the 84 the card records — 80 of its 84 defects are repaired by the rename with zero link edits.

**`#3698 → #4747` is a SERIALIZE edge** (new at Stage 4, not in the milestone description). A published GitHub Release body *is* the frontmatter-stripped in-repo note, and `reemit-release-bodies.sh` resolves that note **by path at a git ref**. #4747 may be designed and dry-run concurrently; it must not `--execute` or run its AC4 full-population re-probe until #3698 has merged to `origin/main`.

**Measured consequence — the waves are a build order inside ONE branch, not two merges.** The #4321 Stage-5 design ran the real link checker across five tree states: pin **0** / #4321-alone **5** / #3698-alone **39** / D-1+skip **175** / D-1+D-5+skip **75** / **full design 0**. Four of five intermediate states are red. There is no ordering of separate PRs that keeps `main` green.

---

## Implementation Sequence

Single branch, serial commits, dependency order.

| Wave | Cards | Note |
|---|---|---|
| **0** | — | Engineering Commit 0: this plan file |
| **1** | #4748 · #5191 · #5271 · #5072 · #4323 · #5192 | Six independents; no in-bundle edges, no shared files |
| **2** | **#3698** | The release's decision, now rendered (D-3698 = A-prime) |
| **3** | #4321 · #4747 | Consumers; both strictly after Wave 2 |

---

## Decision Record — D-3698 (rendered 2026-08-22, operator)

**VERDICT: Option A-prime — class-scoped migrate-flat.**

| | |
|---|---|
| Moves | **100** (`notes/v1/` 24 + `notes/v2/` 44 + `notes/v3/` 32) → flat `release/releases/notes/` |
| Retained | `release/releases/notes/_unversioned/` (10 notes) — **not moved, contents untouched** |
| Standard amendment | `release-notes-standard.md` — the no-subfolders rule names `_unversioned/` as the single permitted subfolder |
| Reference rewrites (D-5) | **207 across 5 files** |
| Absorbed link rewrites | **75** inside the moved notes (Collective Review) |
| Producer changes | **0** |
| ACs satisfied | All four verbatim, including AC2's *"gone **or named as permitted by the standard**"* |
| Reversibility | MODERATE / confidence HIGH |

**Why the card's two-option framing was rejected.** The card asked "flat or sharded?", assuming ONE convention. The corpus runs TWO, split by release-identity mode: versioned notes are written **flat** by the shipped producer (`v4.35`, flat, 2026-08-22), version-less notes to `notes/_unversioned/` by that same producer plus two others. **Option A (pure flat) is self-defeating**: if this release ships version-less, its own Stage-13 close-out would re-create `notes/_unversioned/`, breaking the standard the release had just finished enforcing.

**Binding constraints carried to Engineering:**

1. **D-1 without D-5 turns Check 23 red — by design.** Both land in ONE PR.
2. **`RELEASE_INDEX.md`: 200 occurrences edited ROW-IN-PLACE only.** ADR-105 calls a full regenerate *"a destruction event"* — it destroys grandfathered `Date` cells and the sole-copy `Theme` column. Oracle is `generate_release_index.py --verify` (deploy.sh Check 23).
3. **The pure-rename commit contains ZERO content edits** or the 100-file diff stops rendering as renames.
4. Clears 100 currently-standing Check-32 findings.
5. Stage 4 under-counted note-path consumers: **13 executable / 90 first-order**, not 3.

---

## Decision Record — D-4747-A (rendered 2026-08-22, operator) — **SUPERSEDED by D-4747-D**

> **Superseded.** The verdict below is preserved as rendered. Its figure of 39 was correct against the `origin/main` pre-state and is **no longer the operative scope**: **D-4747-D (below) raises it to 58.** Do not execute against this row.

**VERDICT: ALL 39 published Release bodies** (Cohort A 26 + Cohort B 13), superseding the approved 26.

- `main` is red today: Check 47 ships `enforce` with cutoff `v3.78`; observed `FAIL: release-body-drift — 13 body-drift finding(s) across 59 logged release(s)`.
- #4747's AC4 is structurally unpassable if Cohort B is deferred — it demands full-population zero DRIFT.
- 13 live public pages link to a 404 (root cause: the ADR-092 plan re-identification rewrote the note and never re-emitted Surface 1).
- The card's claim *"Check 47's cutoff contains zero of this cohort, so CI is unaffected"* is **falsified by observation**.

---

## Decision Record — D-4747-D · Cohort C (rendered 2026-08-22, operator) — **THE OPERATIVE SCOPE**

**VERDICT: INCLUDE ALL 58 published Release bodies**, and fix the frontmatter-strip so the three YAML-leak bodies can emit. Supersedes D-4747-A's 39.

**Why the cohort moved from 39 to 58: this milestone authors the extra 19.** #3698's link-repair commit `b8db817e` rewrites an outbound relative link inside **37** of the 100 migrated notes (not all 100 — the 100-file move is a pure rename; only 37 carry a link that needed depth repair). Of those 37, **32** have a published Release: **13** were already drifted at `origin/main`, **19** are NEWLY drifted at the branch tip, **0** still MATCH. The set of new-drift versions minus the set `b8db817e` rewrote is **empty**, so `b8db817e` is the sole author of Cohort C. `strip_frontmatter(note)` is therefore **not** byte-identical across the migration.

| Cohort | Count | Origin |
|---|---:|---|
| A | 26 | deferred structural / content-tail / whitespace population this card already owned |
| B | 13 | ADR-092 plan re-identification rewrote the note and never re-emitted Surface 1 |
| **C** | **19** | **authored by this release** — `b8db817e`'s link repair inside the moved notes |
| **Total** | **58** | 39 (A+B) is a strict SUBSET of 58; A∪B∪C reconciles with no overlap |

**Consequences that bind Stage 12:**

1. **AC4 grades against 58**, not 39. Emitting 39 leaves 19 bodies drifted — precisely the outcome this decision was rendered to prevent.
2. **The `#3698 → #4747` SERIALIZE edge is now load-bearing on CONTENT, not only on evidence.** A pre-merge `--execute` publishes the pre-repair links and the very next merge re-drifts every one of the 19. Stage 5's **IAC-3** ("emitted bytes are ordering-invariant") is **discharged as FALSIFIED**.
3. **The frontmatter strip must be fixed before emit.** `v1.08` / `v1.09` / `v1.10` carry a line before their opening `---`, so the shipped `sed` range ends on the OPENING delimiter and the whole YAML block survives into the body. Emitting them publishes raw frontmatter — the §5.1 defect this card exists to repair, reintroduced by the repair. The pre-execute gate's **A4** arm blocks on exactly these three.

**Reversibility:** MODERATE / confidence HIGH. **Source:** operator, sub-task #5780, 2026-08-22 (Saturday).

### Cohort C — per-version shape record (discharges AC1 for the 19)

AC1 asks for *"the version list with each version's shape — structural / content-tail / whitespace"*. Stage 5's D-1 supplied that for Cohort A (10 single-line · 14 multi-line structural · 2 whitespace) and Cohort B (13). D-4747-D supplied Cohort C's **count and cause** but not its shapes. This is the missing record. It is **derived, never hardcoded**: the cohort is re-computed from `b8db817e`'s file list each time, and the classifier below is a rule, not a table.

**Derivation.** `b8db817e` rewrites **37** notes. Per-version verdict at `origin/main` vs the branch tip: **19 newly drifted · 13 already drifted at main · 0 still MATCH · 5 no published Release = 37**, balanced. Reproduces D-4747-D on every cell.

**Classifier**, applied in order to the trailing-newline-normalised pair *(published body, `strip_frontmatter(branch-tip note)`)* — the same normalisation `check-release-body-drift.sh` applies (accepted-residual AR-1):

| # | Test | Shape |
|---|---|---|
| 1 | byte-equal | MATCH — not in the cohort |
| 2 | identical token sequence | **whitespace** |
| 3 | one body is a strict prefix of the other | **content-tail** |
| 4 | exactly one 1↔1 replace opcode | **structural (single-line)** |
| 5 | otherwise | **structural (multi-line)** |

**All 19 classify as `structural (single-line)`** — one line replaced per version, the outbound relative-link depth repair (`../../` → `../`) that `b8db817e` performed. The shape is uniform because the cause is: a single mechanical rewrite applied once per note.

| Version | Shape | Line replaced | Published → note-body delta |
|---|---|---:|---:|
| `v1.07` | structural (single-line) | 46 | −6 |
| `v1.11` | structural (single-line) | 48 | −6 |
| `v1.13` | structural (single-line) | 53 | −6 |
| `v1.16` | structural (single-line) | 47 | −6 |
| `v1.19` | structural (single-line) | 34 | −6 |
| `v1.20` | structural (single-line) | 39 | −6 |
| `v1.21` | structural (single-line) | 36 | −6 |
| `v1.22` | structural (single-line) | 45 | −6 |
| `v1.23` | structural (single-line) | 40 | −6 |
| `v1.24` | structural (single-line) | 38 | −3 |
| `v2.04` | structural (single-line) | 37 | −6 |
| `v2.09` | structural (single-line) | 41 | −6 |
| `v2.14` | structural (single-line) | 38 | −6 |
| `v2.15` | structural (single-line) | 51 | −6 |
| `v2.18` | structural (single-line) | 46 | −6 |
| `v2.22` | structural (single-line) | 36 | −6 |
| `v2.25` | structural (single-line) | 39 | −6 |
| `v2.26` | structural (single-line) | 33 | −6 |
| `v2.36` | structural (single-line) | 49 | −11 |

**A uniform result needs a control arm, or it is a broken classifier.** Two fired. (1) The same classifier over the **13 already-drifted** versions from the same commit returns **13 multi-line structural**, 0 single-line — so it is not answering "single-line" to everything. (2) Driven over synthetic pairs, all five branches are reachable: MATCH, whitespace, content-tail, single-line, multi-line — **5 of 5**. Neither `whitespace` nor `content-tail` has a member in Cohort C; both remain live classes with members elsewhere in the population (`whitespace` has 2 in Cohort A).

**What this does and does not discharge.** It discharges **AC1** for the 19: every cohort member now carries a per-version shape from a live sweep. It does **not** discharge **AC3**, which asks for a per-version *disposition* — that is produced against the dry-run diff at Stage 12 and is separately flagged as not gradeable as written.

**Consequence for Stage 12.** All 19 are the same mechanical shape, so D-2's per-body-judgement obligation does not attach to any of them; they take the mechanical lane. The 3 lead-in versions (`v1.08` / `v1.09` / `v1.10`) are **not** in Cohort C — they are already-drifted at main, and their blocker was the frontmatter strip, repaired in this release.

---

## Decision Record — Collective Review scope-lock (rendered 2026-08-22, operator)

**RELEASE SCOPE IS LOCKED at 9 cards.** Stage 6 Engineering authorized, write-serialized, single branch, single PR.

### D-3698 amendment — absorb the 75 link rewrites into #3698

The A-prime migration breaks the moved notes' **own outbound relative links**. A note at `notes/v3/x.md` carrying `](../../RELEASE_LOG.md)` resolves to `release/releases/RELEASE_LOG.md` today; at `notes/x.md` the same `../../` resolves to `release/RELEASE_LOG.md` — one level too high, broken.

**Population: 70 depth-corrections across 36 files, plus 4 plan-shard and 1 bare = 75.** Independently reproduced by the hub and by this Engineering spoke. Control arm: 196 tree entries under `notes/`, 100 migrating, 10 staying. **Specificity arm: 11 `_unversioned` depth-2 links are correctly EXCLUDED** — those notes do not move under A-prime, and counting them would have inflated the figure to 81 and read as a disagreement.

#3698's original F4 `PRESERVE` disposition (3 items) is **REVISITED**: its sweep scanned only `*_RELEASE_NOTES.md` tokens and never considered the moved files' own relative links losing a directory level. The governing principle is #4321's own: *a broken link is not a factual claim*.

### AC amendments recorded (card-body edits are operator-owned; the hub records, it does not mutate cards)

| Card | AC | Amendment |
|---|---|---|
| #4321 | AC3 | Not dischargeable as written — its named third surface has 0 markdown links and 11 bare prose tokens; no link checker resolves a bare token. **Re-scope to the link population (404 links).** |
| #4748 | AC3 | **Scope to the two named sites plus a regression arm** — the live claim-shape population is larger and most instances are legitimate claims about other pairs. |
| #4747 | AC4 | Follows **D-4747-D**: full-population zero DRIFT across **all 58** (A 26 + B 13 + C 19). *Amended at Stage 6 — D-4747-A's 39 is superseded.* |
| CIAC-4 + FCM | path | Names `core/config/allowlists/skip-doc-link-check-ci.txt`; **the live path is `core/deploy/allowlists/skip-doc-link-check-ci.txt`** (hub-verified: 1740-file control arm, exactly 1 match). CIAC-4 cannot be graded until corrected. |

### Trap carried to Engineering

`check-release-links.py` **already fails closed** — no code change is needed to arm it; removing one allowlist line takes it 0 → 84 findings. But its `--self-test` is a hard gate asserting those shapes ARE skippable, so it **AssertionErrors unless rewritten in the same change**. At Stage 7 this would present as an unrelated test failure.

The stale premise is **not one allowlist** — four suppressors across three files plus a posture dial, two citing each other circularly. Premise authored `64c9c7ef` (2026-06-05) when the tree held 7 notes / 5 plans (true then); restated verbatim 2026-07-22 when it held 135/117 (false, carried forward without re-derivation).

### Routed separately, not absorbed

- `core/deploy/tools/check-pv7-vocabulary.sh` is present but mode `100644`, **not executable** — a gate doing `[[ -x ]]` fails with a "cannot assert" message that reads as absence.
- ADR-032 remains `status: Accepted` while its migration was deferred and later redesigned; four governance surfaces derived a false premise from it.

---

## File Change Matrix

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-22, domain: governance }`

```
# ── Engineering Commit 0 ──
release/releases/plans/docs-match-shipped-state_RELEASE_PLAN.md   add    # this file

# ── #3698 D-1 — file moves (pure-rename commit, ZERO content edits) ──
release/releases/notes/v1/*_RELEASE_NOTES.md      rename -> release/releases/notes/   # 24
release/releases/notes/v2/*_RELEASE_NOTES.md      rename -> release/releases/notes/   # 44
release/releases/notes/v3/*_RELEASE_NOTES.md      rename -> release/releases/notes/   # 32
release/releases/notes/_unversioned/              RETAINED                            # 10, untouched

# ── #3698 D-3 / D-4 — governance surfaces ──
release/references/standards/release-notes-standard.md   edit   # the flat rule names _unversioned/ as the single permitted subfolder
release/releases/notes/README.md                         edit   # reconcile: flat except _unversioned/; drop the plans/README delegation
release/releases/plans/README.md                         edit   # reconcile: strike "The same scheme applies to ../notes/"; narrow "Every plan and note" to plans

# ── #3698 D-5 — reference repair, 207 occurrences / 5 files ──
release/releases/RELEASE_INDEX.md                                      edit  # 200 — Release-Notes cell, ROW-IN-PLACE ONLY (never regenerate: ADR-105)
release/releases/RELEASE_LOG_ARCHIVE-v1.md                             edit  # 4
core/deploy/tools/generate_release_index.py                            edit  # 1 path + the rglob rationale comment
core/references/reference/operator-instance-home-and-isolation-key.md  edit  # 1
release/references/how-to/re-version-recovery.md                       edit  # 1

# ── #3698 D-7 — comment reconciles (recursion RETAINED in all four) ──
core/deploy/tools/lint_release_corpus.py     edit   # rglob rationale; the layout-independence comment PRESERVED verbatim
core/deploy/tools/generate_release_index.py  edit   # rglob rationale (same file as D-5 above)
release/tools/check-release-body-drift.sh    edit   # subfolder rationale; both fallbacks PRESERVED
release/tools/reemit-release-bodies.sh       edit   # subfolder rationale; both fallbacks PRESERVED

# ── #3698 ABSORBED at Collective Review — 75 link rewrites inside the moved notes ──
release/releases/notes/<36 moved notes>   edit   # R-depth 70
release/releases/notes/<4 moved notes>    edit   # R-plan-shard 4
release/releases/notes/v2.36_RELEASE_NOTES.md  edit  # R-bare 1

# ── #4321 — residual repair + check re-arm ──
CHANGELOG.md                                       edit   # 4 residual [Full notes] targets (C-5), token-anchored
core/deploy/allowlists/skip-doc-link-check-ci.txt  edit   # retire the CHANGELOG.md entry + its rationale block; reconcile the header parenthetical
release/tools/check-release-links.py               edit   # delete the note/plan skip + its premise comment; correct the docstring; REWRITE run_self_test()
core/deploy/allowlists/doc-link-target-paths.txt   edit   # reconcile the CHANGELOG routing rationale; KEEP the release/releases/ exclusion
core/rules/doc-link-maintenance.md                 edit   # strike the instance-side CHANGELOG clause — MIRROR-PAIR, re-sync or Check 9 fails

# ── #4747 — external surface + captures + the pre-execute gate ──
release/releases/_captures/<date>-release-body-reemit/*.published.txt   add   # capture-before-overwrite, one per re-emitted version (AC2) — 58 files (D-4747-D)
release/tools/preflight-release-body-reemit.py                         add   # the pre-execute gate: 5 fail-closed arms, derived aggregate verdict, 69-assertion self-test. A3 asserts capture CORRESPONDENCE (SHA-256 vs the live published body), not presence; strip model tracks the repaired transform
release/tools/reemit-release-bodies.sh                                 edit  # --execute INVOKES the gate (exit 4 on refusal); self-test Case T keeps it wired. ALSO the §5.1 strip repair (D-4747-D limb 2). Distinct region from #3698's D-7 comment reconcile below
release/tools/check-release-body-drift.sh                              edit  # the same §5.1 strip repair — this tool is the emitter's post-edit verifier, so the two transforms must move together or a correct emit reports DRIFT forever

# ── Wave 1 independents ──
core/ADRs/ADR-112-decision-time-adherence-trigger-layer.md   edit   # 4748 claim site 1
core/specs/decision-confidence-protocol.md                   edit   # 4748 claim site 2
core/standards/duplicate-source-discipline.md                edit   # 4748 register entry
core/rules/skill-deployment.md                               edit   # 5191 third source tree + package count
core/deploy/tests/test_upgrade_config_durability.sh          edit   # 5271 site 1
core/hooks/tests/prime-autonomy-ceiling-cache.test.sh        edit   # 5271 site 2
docs/scripts/setup-workspace.sh                              edit   # 5271 site 3
release/references/how-to/hub-spoke-bridge.md                edit   # 5072 Check 29 prose
release/releases/RELEASE_LOG_ARCHIVE-v2.md                   edit   # 4323 shape A x4
release/releases/RELEASE_LOG_ARCHIVE-v3.md                   edit   # 4323 shape A x2 + shape B x2
release/releases/RELEASE_LOG_ARCHIVE-version-less.md         edit   # 5192 Mechanism line

#### Read-only inputs (excluded from the obligation set)
release/releases/RELEASE_LOG.md   READ
core/deploy/deploy.sh             READ   # 5072 corrects the DOC to match the check; the check is NOT modified
core/rules/decision-time-adherence.md   READ
packages/*.skill                  READ
release/tools/automated-closeout.sh          READ   # producer already at the A-prime target state
release/tools/claim-version.sh               READ   # plans producer
release/tools/produce-learnings-register.sh  READ   # registers corpus

#### Release-wide explicit non-scope
release/releases/plans/**                 NOT EDITED   # except plans/README.md's notes clauses (D-4) and this plan file
release/references/pipeline/stage-*.md    NOT EDITED   # zero pipeline stage specs touched (bears on Release Class)
CLAUDE.md                                 NOT EDITED
core/governance/OPERATIONS.md             NOT EDITED
```

**External (non-file) change surface — #4747.** **58** published GitHub Release bodies re-emitted via `gh release edit` (**D-4747-D**; was 39 under the superseded D-4747-A). These are not repository files and carry no FCM row; they are recorded here so the matrix is not read as the release's complete change surface.

---

## Contention Map

| Shared surface | Issues | Class | Resolution |
|---|---|---|---|
| `release/references/standards/release-notes-standard.md` | **#3698** (write) · #4321 (read) · #4747 (read) | 3-way, 1 writer | **#3698 owns the write.** Enforced by the Wave 2 → Wave 3 boundary. |
| `release/releases/notes/**` (100 moved paths) | **#3698** (move + link repair) · #4747 (read via resolver) | mover × reader | Serialize. #4747 never writes these paths. |
| `CHANGELOG.md` | **#4321** (write) · #3698 (repairs 80 of 84 by rename, edits nothing) | single writer | No conflict — #3698 contributes zero `CHANGELOG.md` edits. |
| `release/releases/RELEASE_LOG_ARCHIVE-*.md` | #4323 (`-v2`, `-v3`) · #5192 (`-version-less`) · **#3698** (`-v1`, 4 D-5 occurrences) | **disjoint files** | **No contention.** Three writers, three disjoint archive segments. |
| `core/deploy/tools/generate_release_index.py` | **#3698** (D-5 path + D-7 comment) | single writer | Both edits land in #3698's commits. |
| `release/tools/reemit-release-bodies.sh` | **#3698** (D-7 comment reconcile) · **#4747** (pre-execute gate wiring, added at Stage 6) | 2 writers, **disjoint regions** | No conflict. #3698 edits the NOTE-RESOLUTION rationale comment; #4747 adds a header block, a `PREFLIGHT_TOOL` config line, the `--execute` gate, and self-test Case T. Stage 6 is write-serialized, so the two land in sequence on one branch. |

**Cross-PR contention.** Measured at `6d0e2080`: PR #5765 (`operational-folder-enforcement-migration`) **MERGED** 2026-08-22; the Stage-4 `EDITSET ∩ FCM = ∅` finding survives the merge — the 7 commits between the Stage-4 pin and the Stage-5 pin touch none of #3698's change set.

---

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#3698 × #4321):** the layout the standard states and the layout on disk agree, AND every note-link target across all tracked `*.md` resolves. *Method:* enumerate `release/releases/notes/*/`; extract every `*_RELEASE_NOTES.md` target from tracked markdown excluding the notes tree; `git cat-file -e` each; report resolved/denominator with both arms. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-2 (#3698 × #4747):** `check-release-body-drift.sh` resolves a source-of-record note for every logged version that has one — no `MISSING` verdict attributable to path resolution under the settled layout. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-3 (#4323 × #5192):** across all five log surfaces, zero milestone-denoting bare `#N` remain AND no row/body Tag divergence remains, against a sensitivity arm that still reports the 63 correct-form `milestone #N` occurrences. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-4 (#4321 × #4747) — PATH CORRECTED:** no gate in this release is left suppressed by a premise this release falsified. *Method:* assert **`core/deploy/allowlists/skip-doc-link-check-ci.txt`** (not `core/config/…`) no longer suppresses the CHANGELOG `[Full notes]` class, and that `RELEASE_BODY_DRIFT_CHECK_CUTOFF` carries a recorded decision. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-5 (#4748 × #5191 × #5072):** no file this release touches asserts a count, roster, or non-duplication property that its own cited artifact falsifies. *Graded at Stage 9 QC3.5.*

---

## Verification Plan

### #3698 — refined acceptance criteria (Stage 5)

- **AC1** `release/releases/notes/` and `release-notes-standard.md` agree. *Method:* enumerate `notes/*/` → expect exactly `_unversioned/`; read the standard's File Location section → it names `_unversioned/` as the single permitted subfolder.
- **AC2** All four original subfolders dispositioned. *Method:* `v1/`, `v2/`, `v3/` absent from the tree; `_unversioned/` present **and** named permitted by the standard.
- **AC3** Every `RELEASE_INDEX.md` note link resolves. *Method:* `python3 core/deploy/tools/generate_release_index.py --verify` → **0 `notes_link` findings**; plus extract every `notes/…md` target and `git cat-file -e` each → 100% resolve, reported with both arms against a live denominator (never a hardcoded 110).
- **AC4** (fires — a subfolder is retained) `automated-closeout.sh` and the drift gate both resolve an `_unversioned/` note. *Method:* `bash release/tools/check-release-body-drift.sh <a version-less slug>` → a real verdict, **not** exit 3 `MISSING`; cite `notes_abs_path()` as the producer of that same path.
- **AC5 (new)** No note file moved in this change differs in content **in the rename commit**. *Method:* `git diff --find-renames --numstat <pure-rename-commit>` → every one of the 100 rows reads `0  0`.
- **AC6 (new)** The recursion is retained in all four recursive consumers and only their rationale prose changed. *Method:* assert `rglob(` / `ls-tree -r` still present in each of the four files.
- **AC7 (absorbed at Collective Review)** Every outbound relative link inside a moved note resolves after the move. *Method:* enumerate markdown links in the 100 moved notes; resolve each against the tracked tree; expect **0** unresolved, with the pre-move control arm (70 depth≥2 links resolving today) reported alongside.

### #4321 — verification sequence at Engineering

1. `python3 release/tools/check-release-links.py --self-test` → **exit 0** (guards the self-test rewrite).
2. `python3 release/tools/check-release-links.py` → **0 broken links**.
3. `python3 core/deploy/tools/check-doc-links.py --target-paths-file core/deploy/allowlists/doc-link-target-paths.txt --allowlist core/deploy/allowlists/skip-doc-link-check-ci.txt --require-targets --exclude-code-blocks` → **0 findings**.
4. Seed one broken note link → re-run (1) and (2) → **exit 1** (the fail-closed proof).
5. `python3 core/deploy/tools/generate_release_index.py --verify` → 0 `notes_link` findings.
6. `./deploy.sh --check` → confirm Check 9 (mirror byte-identity) and Check 14 both clean.

### #4747 — Stage-12 execution sequence

**Read this as the execution contract. The cohort is 58 (D-4747-D), not 39.**

1. **#3698 must already be merged to `origin/main`.** The `#3698 → #4747` edge is a SERIALIZE edge and it is load-bearing on CONTENT (D-4747-D consequence 2). A pre-merge `--execute` publishes the pre-repair links and the next merge re-drifts all 19 of Cohort C.
2. **Fix the frontmatter strip** — **ALREADY DONE at Stage 6** (D-4747-D limb 2; Deviation Log rows 16–17). Both executables now run `sed -n '/^---$/,$p'` before the shipped idiom, and A4 is green across all 195 corpus notes. No action remains at Stage 12; the step is retained so the sequence still reconciles.
3. **Capture all 58 bodies**, commit, and **merge the captures to `origin/main`**. On-disk captures are not durable; the gate's A3 arm proves durability with `git cat-file` at the ref. `capture-release-bodies.sh` is currently blocked to agent-side invocation by `BLOCK-DESTRUCTIVE-022`; that gap is owned and scheduled under **#5227**. Until it clears, this step is operator-side.
   > **A3 now also requires the capture to be CURRENT**, not merely durable — SHA-256-identical to the body GitHub publishes at gate time. Two operational consequences. (a) **Capture and emit are one window.** If any body in the cohort is edited between the capture and the gate run, A3 blocks that version as `STALE` and names it; the repair is a NEW dated capture directory, never an overwrite (`capture-release-bodies.sh` refuses to overwrite, and that refusal is correct). Keep the capture → commit → merge → gate → emit sequence tight, and re-run the gate — never reuse an earlier run's exit 0. (b) **The Part A directories can never satisfy A3.** All 29 of their captures are stale against today's bodies; pointing `--capture-dir` at one now yields `A3 BLOCK — 29 STALE` rather than the `A3 PASS` the pre-repair arm printed.
4. **Run the gate**, and read every arm:
   `python3 release/tools/preflight-release-body-reemit.py --capture-dir release/releases/_captures/<dated-dir> <58 versions>`
   Exit 0 is the only value that authorizes step 5. Paste the output into the execution record.
5. **Emit.** `./reemit-release-bodies.sh --execute <capture-dir> <58 versions>` — this **re-runs the gate itself** and refuses with exit 4 if it does not pass, so step 4 is a read-the-arms rehearsal, not the only barrier.
6. **Re-probe the full population** for AC4: 0 DRIFT across all 58, tally reconciled, both arms reported.
7. **Render AC6** on `RELEASE_BODY_DRIFT_CHECK_CUTOFF` — decide or decline, but record it. Measured input: 13 of the 58 sit at or above the current `v3.78` cutoff, across 59 logged releases; 45 sit below it and are invisible to CI today. Re-emitting the cohort turns Check 47 green **without** touching the cutoff. Lowering it **before** the re-emit would arm the gate against 45 knowingly-red bodies.

### Release-level

| Issue | Verification method class | Expected result |
|---|---|---|
| #3698 | file-content / system-state assertion | `notes/*/` enumeration and the standard's rule agree; all four subfolders dispositioned; 0 unresolved links inside the movers |
| #4321 | evaluate predicate against current state | link sweep resolves 100% of the **live** denominator (never a hardcoded 161/165/166), both arms reported |
| #4747 | reproduction-and-observe (network sweep) | full-population drift sweep returns 0 DRIFT across **all 58** (D-4747-D), tally reconciles, both arms reported |
| #4323 | file-content assertion | shape-A + shape-B probes return 0 across all 5 surfaces; 63 correct-form occurrences survive |
| #5192 | file-content assertion + external oracle | body no longer claims a tag; `git tag -l` confirms none exists |
| #4748 | evaluate predicate (shingle measurement) | the two named sites corrected; regression arm holds; register entry resolves to both headings |
| #5191 | file-content assertion | all three source trees named; package count is a live probe, not a literal |
| #5271 | reproduction-and-observe | both test suites pass; no prose asserts the installer omits `[automation]` |
| #5072 | cross-output-coherence | `hub-spoke-bridge.md` Check-29 description matches the shipped `deploy.sh` behavior |

---

## Risk Register

| # | Risk | Owner | Likelihood | Impact | Mitigation | Reversibility |
|---|---|---|---|---|---|---|
| **R1** | **#4321 AC3 unreachable as written** — its named third surface is a token population no link checker resolves. | #4321 | Certain (measured) | Gate FAIL at S8 | **AC amended at Collective Review** — re-scoped to the link population (404 links). | CHEAP |
| **R2** | **#4747's cohort was under-scoped at 26, then at 39.** The second under-scope is self-inflicted: this release authors 19 more bodies than it started with. | #4747 | Certain (measured) | Wrong scope, AC4 unpassable | **D-4747-D: all 58** (A 26 + B 13 + C 19), superseding D-4747-A's 39. | MODERATE |
| **R3** | A corpus-wide probe for #4748's claim phrase returns 3, not 2. | #4748 | Medium | False FAIL | Scope the probe to the two named claim sites plus a regression arm. | CHEAP |
| **R4** | Migrate-flat leaves four recursive consumers carrying rationale prose that names the `v1\|v2\|v3` layout. | #3698 | High | Stale prose | D-7 reconciles the four comments in the same change; the recursion itself is **retained** (it still serves `_unversioned/`). | CHEAP |
| **R5** | Re-emitting published Release bodies reaches outside the repo and is not `git revert`-able. | #4747 | Low | Public surface | Capture-before-overwrite under `release/releases/_captures/` (AC2), **enforced on the mechanism**: `--execute` invokes `preflight-release-body-reemit.py` and refuses (exit 4) unless its A3 arm proves every capture DURABLE at `origin/main`. No skip flag. | **MODERATE** |
| **R6** | Retiring the CHANGELOG allowlist entry red-fails CI if any note link remains broken at merge. | #4321 | Medium | Blocked merge | Retire only after the link sweep is green; the fail-closed demonstration is the proof. | CHEAP |
| **R7** | #5271 edits land inside executable test files. | #5271 | Low | Silent test break | Stage 7 retained; run both suites before and after. | CHEAP |
| **R8** | **100-file rename buries the substantive edits.** | #3698 | Medium | Weak S9 review | **Pure-rename commit, zero content edits**, so `--find-renames` renders it compactly. Verified `0 0` numstat on all 100 rows. | CHEAP |
| **R9** | **`check-release-links.py --self-test` hard-fails** if the skip is narrowed without rewriting the self-test. Highest-likelihood implementer miss. | #4321 | High | Gate red for an unrelated reason | The self-test rewrite is called out as **mandatory**, not tidy-up; it is a Stage-7 gate. | CHEAP |
| **R10** | **Mirror-pair desync** on `core/rules/doc-link-maintenance.md` → Check 9 byte-identity fails. | #4321 | Medium | Check 9 red | Called out as MIRROR-SYNC; on the Stage-7 checklist. | CHEAP |
| **R11** | **`origin/main` moves during Engineering** (3× during the #4321 Stage-5 spoke alone). | release | High | Line-number drift | Every edit is **token-anchored**, never line-anchored. | CHEAP |
| **R12** | **D-1 without D-5 turns Check 23 red.** | #3698 | Certain (by design) | Gate red | Both land in the same PR; Check 23 is the completeness oracle, not a regression. | CHEAP |

---

## Stage Applicability Matrix

| Issue | Size | S5 | S6 | S7 | S8 | S9–S13 | Rationale for any SKIP |
|---|---|---|---|---|---|---|---|
| **#3698** | M | **REQUIRED** | ✔ | **REQUIRED** | ✔ | ✔ | D-class mechanism decision; 100 file moves; 13 executable consumers resolve note paths |
| **#4321** | M | **REQUIRED** | ✔ | **REQUIRED** | ✔ | ✔ | Modifies a CHECK + CI allowlist — must demonstrate fail-closed |
| **#4747** | M | **REQUIRED** | ✔ | **REQUIRED** | ✔ | ✔ | Mutates published public content; capture-before-overwrite is the reversibility control |
| **#4748** | XS | **REQUIRED** | ✔ | SKIP | ✔ | ✔ | Prose + register entry, no executable |
| **#5271** | S | SKIP | ✔ | **REQUIRED** | ✔ | ✔ | Edits land inside two executable test files |
| **#5072** | S | SKIP | ✔ | SKIP | ✔ | ✔ | Doc-only; the check is not modified |
| **#5191** | S | SKIP | ✔ | SKIP | ✔ | ✔ | Doc-only rule-file prose |
| **#4323** | S | SKIP | ✔ | SKIP | ✔ | ✔ | Anchored full-phrase edit strategy |
| **#5192** | XS | SKIP | ✔ | SKIP | ✔ | ✔ | Single-line body correction |

---

## Quota Budget

**Verdict:** PASS (Checkpoint A). Parallel-eligible spokes: Stage 5 **2** · Stage 7 **2** · Stage 8 **6**. Per-spoke cost estimated on the ordinal size-bucket band; no absolute token figure is available, and none is fabricated. Checkpoint B re-validates at every `Agent`-tool launch.

---

## Rollback Strategy

| Layer | Mechanism | Tier |
|---|---|---|
| All in-repo file changes | `git revert -m 1` of the single release-PR merge commit | **CHEAP** |
| The 100-note migration | Reverted by the same merge revert; the pure-rename commit reverts cleanly under `--find-renames` | **CHEAP** |
| Retired allowlist entry / re-armed check | Restored by the same revert; CI returns to its prior suppressed state | **CHEAP** |
| **58 published Release bodies (#4747)** | **NOT git-revertible** — restore each from its pre-edit capture under `release/releases/_captures/` via `gh release edit` | **MODERATE** |

**Rollback-infeasibility statement.** The published-body layer is the only component whose rollback depends on an artifact this release must itself create. If captures are not written before overwrite, that layer becomes **IRREVERSIBLE**. Capture-before-overwrite is therefore a hard gate at Stage 12 Execute, not a best practice.

**The capture population is 58, and the Part A directories are not a substitute.** `release/releases/_captures/2026-08-05-release-body-precapture-partA-ext` already holds captures for 18 of this cohort's versions. They capture the **pre-Part-A** body, all 18 of those foldered versions **aborted** without being overwritten, and the state they describe has since been superseded by this release's note migration. A fresh capture is required for all 58.

**The gate is now on the mechanism.** `reemit-release-bodies.sh --execute` invokes `release/tools/preflight-release-body-reemit.py` itself before the first mutation and refuses (exit 4) unless it passes. Its **A3** arm proves each capture is DURABLE at `origin/main` via `git cat-file` — on-disk existence is not durability — so a capture living only in a working tree cannot satisfy the rollback layer. Since the Stage-6 remediation it also proves each capture is **CURRENT**: SHA-256-identical to the body GitHub publishes at gate time, read with the same `gh release view … --jq .body` command that wrote the capture. Durability alone proved the capture was a committed *file*; currency is what makes it a *rollback source*. A live body that cannot be read is a BLOCK, never a pass. There is no skip flag.

---

## Operator Decisions Recorded

| ID | Decision | Rendered | Reversibility / confidence |
|---|---|---|---|
| D-PlanApproval | Stage 4 release plan + Release Outcome Statement | 2026-08-21 | MODERATE / HIGH |
| D-ReleaseClass | `routine` → `novel` | 2026-08-21 | CHEAP / HIGH |
| D-4747-Posture | Accept the G-PL4 pass-through on the 26-body count | 2026-08-21 | CHEAP / MEDIUM |
| **D-3698** | **A-prime — class-scoped migrate-flat** | 2026-08-22 | MODERATE / HIGH |
| **D-4747-A** | **ALL 39 bodies** (Cohort A 26 + Cohort B 13) — **SUPERSEDED by D-4747-D** | 2026-08-22 | MODERATE / HIGH |
| **D-3698-amend** | **ABSORB the 75 link rewrites into #3698** | 2026-08-22 | CHEAP / HIGH |
| **D-ScopeLock** | **Scope locked at 9 cards; 4 ACs amended; route Stage 6** | 2026-08-22 | MODERATE / HIGH |
| **D-4747-D** | **ALL 58 bodies** (A 26 + B 13 + **C 19, authored by this release**), and fix the frontmatter-strip so `v1.08` / `v1.09` / `v1.10` can emit. **This is the operative scope for Stage 12.** | 2026-08-22 | MODERATE / HIGH |

### Open at plan time — resolve at Stage 12

**D-Version is UNRESOLVED and is surfaced here rather than decided by Engineering.** Stage 4 recorded `version-less` per D-Version condition **(B)** (slug-only milestone title). Live precedent contradicts that reading: **every** slug-named milestone from `v4.22` through `v4.35` — including the immediately-preceding `operational-folder-enforcement-and-migration` — claimed a concrete `vX.Y` at its Stage-12 atomic claim, and that release needed a corrective commit (`8f3ce9fe`) to add the `{{RELEASE_VERSION}}` token its Stage-4 plan had omitted.

This plan therefore carries the token in its Header **Version** cell, which is the **universal pre-claim form for both identity modes** per `release/releases/plans/README.md` § File naming. Carrying a placeholder is not claiming a version. The Commit-0 version re-verify steps that recompute next-free and compare it against the claimed set were **HALTed as inapplicable** under the recorded version-less determination — no version was computed and none was written. The operator re-renders D-Version at Stage 12: a `versioned` outcome resolves the token and renames this file to `plans/v<MAJOR>/`; a `version-less` outcome strikes the token and resolves this file to `plans/_unversioned/`.

---

## Deviation Log

| # | Stage-4 plan of record | Ratified delta | Source |
|---|---|---|---|
| 1 | D-3698 undecided; two options (migrate-flat vs amend-the-standard) | **A-prime** — class-scoped migrate-flat; `_unversioned/` retained and named permitted | D-3698, 2026-08-22 |
| 2 | "Migrate-flat = 0 link edits" | **207 D-5 rewrites** across 5 files; the zero-edit claim is true of `CHANGELOG.md` only | #3698 Stage-5 design |
| 3 | 110 notes migrate | **100** migrate; `_unversioned/`'s 10 stay | D-3698 |
| 4 | #3698's F4 disposition: 3 items PRESERVE | **REVISITED** — 75 moved-note links REWRITE, absorbed into #3698 | Collective Review, 2026-08-22 |
| 5 | #4747 cohort = 26 | **39** (Cohort A 26 + Cohort B 13) | D-4747-A, 2026-08-22 |
| 6 | #4321 repair set = 84 CHANGELOG links | **4** residual; 80 repaired free by the rename | #3698 + #4321 Stage-5 designs, independently reproduced |
| 7 | "3 consumers resolve a note path" | **13 executable / 90 first-order** | #3698 Stage-5 design |
| 8 | 1 governance surface asserts a notes layout | **3** — the standard plus both READMEs | #3698 Stage-5 design |
| 9 | 85 flat notes | **84** at `57f75e3a` (Stage 4 counted `notes/README.md` as a note); **85** at `6d0e2080` after the v4.35 close-out added one. Both values reported; designed against the live count. | Hub R1 + Commit-0 re-measure |
| 10 | Waves 2 → 3 are two merges | **One branch, one PR, one merge** — four of five intermediate tree states are red | #4321 Stage-5 state matrix |
| 11 | CIAC-4 names `core/config/allowlists/skip-doc-link-check-ci.txt` | **`core/deploy/allowlists/skip-doc-link-check-ci.txt`** | Collective Review |
| 12 | CHANGELOG `[Full notes]` denominator 161 → 165 | **166** at `6d0e2080`; broken count unchanged at **84**. No denominator is hardcoded in any AC. | #4321 Stage-5 design |
| 13 | #4747 cohort = **39** (row 5 above) | **58** — A 26 + B 13 + **C 19**. Cohort C is authored by this release: `b8db817e` rewrites an outbound link in 37 of the 100 migrated notes; 32 of the 37 have a published Release; 19 of those newly drift at the branch tip. 39 is a strict subset of 58. | **D-4747-D**, 2026-08-22 (operator, sub-task #5780) |
| 14 | #4747 delivers one FCM row (the captures) | **Plus two tool files** — `release/tools/preflight-release-body-reemit.py` (new, the pre-execute gate) and an edit to `release/tools/reemit-release-bodies.sh` wiring the gate into `--execute`. Both are recorded in the FCM at § File Change Matrix. | Stage 6 remediation, 2026-08-22 |
| 15 | "`b8db817e` rewrites one outbound-link line inside **every** moved note" | **FALSE — 37 of 100.** The conclusion it supported (Cohort C = 19, `b8db817e` is its sole author) is nonetheless correct and was re-derived independently. Corrected at every site in this plan; the claim also stands uncorrected in two issue comments, which are operator-owned. | Stage 7 Dev Testing F-07, sub-task #5781 |
| 16 | #4747's tool surface is two files (row 14) | **Three.** `release/tools/check-release-body-drift.sh` also takes the §5.1 strip repair. It is the emitter's post-edit verifier: if only the emitter's transform were fixed, a correctly-emitted body would compare against the verifier's unrepaired one and report DRIFT on every run. The two are one transform and must move together. | Stage-6 remediation pass 2 |
| 17 | D-4747-D limb 2 ("fix the frontmatter-strip") not implemented at the branch tip | **Implemented.** Both executables now run `sed -n '/^---$/,$p'` before the shipped `1,/^---$/d; …` idiom, and the gate's A4 model tracks it. Strict composition, so 192 of 195 corpus notes compute byte-identical bodies; the 3 that change are exactly `v1.08` / `v1.09` / `v1.10`. YAML-leaking bodies 3 → 0, EMPTY bodies 0 → 0. **Not the portability defect** — that is a different defect in the same idiom, tracked separately, and stage 2 retains the idiom verbatim. | Stage-6 remediation pass 2 |

---

## Closure Posture

All nine members are to be **marked as closed at Stage 13**, not before. #4321 and #4747 in particular must not be marked resolved until their re-armed checks demonstrate fail-closed behavior.
