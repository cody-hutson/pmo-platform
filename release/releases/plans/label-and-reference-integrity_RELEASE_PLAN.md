---
title: Release Plan — label-and-reference-integrity
purpose: Stage-4 release plan for the eight-member label-and-reference-integrity cohort — the label and issue-reference taxonomies are internally consistent and their gates evaluate them correctly.
type: release-plan
plan_type: release
status: EXECUTING
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# Release Plan: label-and-reference-integrity — The Label And Reference Taxonomies Are Internally Consistent

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim. Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against local tags, origin tags, published Releases, the `RELEASE_LOG` ledger and the `plans/v4/` directory; anchor tag **v4.45**, recomputed next-free **v4.46**, free at Commit 0 on all five surfaces. |
| **Date Created** | 2026-09-01 (Tuesday) |
| **Commit-0 Date** | 2026-09-02 (Wednesday) — the resolution instant for every load-bearing date this release writes |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/label-and-reference-integrity` — slug-primary, no version stem |
| **PR** | opened as a DRAFT after the first Engineering spoke's commits; the release ships as a SINGLE PR with one merge gate |
| **Milestone** | `label-and-reference-integrity` (#337) |
| **Release Class** | `novel` — re-classified out of band from the Stage-4 `routine` determination |
| **Effective points** | **25** across **8** issues. Raw sum 22 (5 x `size:S` at 2 = 10, 3 x `size:M` at 4 = 12); `class_weight` for `novel` is 1.15, so `effective_pts = round_half_up(22 x 1.15) = 25` — exactly at the 15-25 band ceiling, not above it. The re-classification is an **operator-recorded out-of-band override** carried into this plan by the hub at Engineering Commit 0; its evidentiary basis is `novel` trigger (c) — a Stage-5 ADR was declared on #5291. Recorded here as an override rather than presented as a Stage-4 computation, because it was not one. |
| **Branch topology** | **SINGLE** (D-C) — one branch, one PR, one merge gate; this plan lands as Engineering Commit 0 |
| **Concurrency posture** | **P0 fully-serial** (D-C) — 4 writers on one file and 3 on another. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `539c4440` — the pinned baseline; every Engineering spoke branches from it |

**Stamp manifest.** The `**Version**` cell above is a machine-read manifest, not prose. It carries the literal `{{RELEASE_VERSION}}` token, which the Stage-12 claim resolves at the merge SHA while renaming this file to `release/releases/plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md`. Asserted read-only at Commit 0 by `release/tools/claim-version.sh --verify-stamp label-and-reference-integrity`; a plan that fails that assertion is never committed, because Stage 12 could then neither resolve the version nor complete the rename. The **Bump Class** row beside it carries the durable half of the determination — the class, never a baked number.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-01, domain: software }`

*Classification rationale (A3-time, from the File Change Matrix):* every path in the matrix is an internal pmo-platform artifact, so the release is **sourcing-exempt** (Form X verbatim). Dominant deliverable class `software` — the majority of write-set paths are executable tooling; secondary class `governance` (`label-taxonomy.md`, `git-workflow.md`, `release-velocity-tracking.md`, the allowlist row).

## Release Outcome Statement

**AFTER** this release: the label and issue-reference taxonomies are internally consistent, and the gates that evaluate them do so over the population they claim to cover.

**BEFORE:** the label taxonomy declares three `triage:` rows that do not exist and four Removed rows that are live; the parity gate accepts any `type:*` label without a pack-declared kind and errors out when the GraphQL quota is exhausted; 32 declared-and-live rows diverge on colour or description with no disposition record; the issue-ref gate's override regex rejects the rationale-carrying marker its own failure message mandates and keeps a hand-maintained enumeration where discovery belongs; the fragile-reference hook's scope gate contradicts its own documentation and resolves a file-scoped override marker against an incoming fragment; and the velocity instrument's label-to-work-class map does not recognise improvement-labelled stories as feature allocation.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Track | Size | Stage 5 |
|---|-------|---------------------|-------|------|---------|
| 1 | #5258 | block-fragile-refs: scope gate contradicts its documentation; marker invisible to an Edit | 4 | S (2) | APPLIED |
| 2 | #5058 | label-parity check errors when the GraphQL quota is exhausted though REST serves the data | 1 | S (2) | APPLIED |
| 3 | #5054 | taxonomy declares three absent `triage:` rows and four live Removed rows | 1 | M (4) | APPLIED |
| 4 | #5291 | parity gate accepts any `type:*` label without a pack-declared kind | 1 | M (4) | APPLIED |
| 5 | #5057 | only 2 of 34 declared-and-live rows match their declaration on colour and description | 1 | M (4) | APPLIED |
| 6 | #5259 | issue-ref gate's override regex rejects the marker its own failure message mandates | 3 | S (2) | APPLIED |
| 7 | #5254 | replace the issue-ref gate's hand-maintained `case` arms with discovery | 3 | S (2) | APPLIED |
| 8 | #4223 | label-to-work-class map does not recognise improvement-labelled stories as feature | 2 | S (2) | APPLIED |

`#5835` is a CLOSED member. The Stage-4 gap review returned **no gap** — all three of its re-scoped criteria shipped on `main` at the baseline — so it carries no per-issue slot here.

Effective scope is **8 members / 25 effective pts**. Stage 5 activation is **ALL**: every member carries an `[ASSUMPTION - CONFIRM]` its own body routes to Solutioning, a canonical-form decision, or a governance-mandated implementation plan. The skip predicate was tested per card and failed on all eight.

### Ratified corrections carried into this file

These supersede the corresponding text in the Stage-4 planning comment. The superseded text is **not** transcribed here.

1. **The taxonomy collision is 3-wide, not 2.** `core/specs/label-taxonomy.md` is written by #5054, #5057 **and** #5291. The Track-1 order is unaffected; the recorded count understated the collision by one.
2. **`routine`'s evidentiary basis was corrected, then the class itself was re-classified.** Trigger (a) — all issues P3/P4 — is falsified (#5058 and #5291 are P2-High); trigger (b) fires cleanly (all nine change-spec files carry ≥3 prior touches, min 3, max 20). The class subsequently moved to `novel` out of band on trigger (c), a Stage-5 ADR declared on #5291.
3. **Track 4 is independent *as scoped*, not independent by construction.** Tracks 3 and 4 both source `core/hooks/lib/fragile-ref-patterns.sh`. Measured inert today; the coupling activates the moment either track relocates a constant into that library. This is R-4.
4. **Three undeclared edits, one root cause.** `core/rules/git-workflow.md`, `core/deploy/tools/README.md` and `release/references/standards/release-velocity-tracking.md` appear in no member's self-declared `Affected Files` section, so they were structurally invisible to the Stage-4 File Change Matrix and Contention Map. All three are declared in the matrix below. This is the same shape as the defect the release exists to close: a consumer cannot see what it was never told about.
5. **#5258's write-set is 2 files, not 4.** `core/hooks/run-fragile-ref-fixtures.sh` is read, run and asserted unchanged (its fixture grammar has no path column and cannot express either limb); `core/standards/reference-durability-standard.md` drops out, its Documentation-Impact clause being conditional on narrowing the scope gate, which the design declines. R-2 downgrades **HIGH → LOW** in consequence.
6. **#4223's write-set is 2 files** (`release/tools/compute-release-velocity.sh` plus `release/references/standards/release-velocity-tracking.md`), with no intersection with any other member's write set. Its one real coupling is a CLI contract, not a file.

## Release Class

**`novel`** — re-classified out of band. Trigger (c) fires: a Stage-5 ADR was declared on #5291. The Stage-4 `routine` determination was verified-not-falsified on trigger (b) and is preserved above as the superseded reading, so the change is legible rather than silent.

**Class arithmetic:** raw Σ 22, `class_weight` 1.15, `effective_pts = round_half_up(22 x 1.15) = 25` — at the 15-25 band ceiling. No split disposition fires at the ceiling.

**Competing-class tests, run rather than assumed.** `cross-cutting` (a) ≥3 `pipeline/stage-*.md` files in the matrix: **0**. (b) ≥3 of the six rule-defining surfaces: **0**. (c) ≥3 in-bundle compositional edges: the DAG carries **2** declared dependency edges, so it does not fire — a serialization edge is an artefact of where the bytes live, not of what the issues compose into. `hotfix`: 8 issues (>3) and no member is raised against a deployed release as a P1/P2 defect; does not fire.

**Differentiation posture:**

| Dimension | Value |
|---|---|
| Engagement density | **Light** — Procedure-2 routing absorbed into Tier-3 Standing-GO; completions batched into a consolidated Decision Briefing at gate boundaries. Per-D-decision briefings still fire. |
| Stage 9 Plan Review depth | **Standard**, RAISED per-decision — explicit sign-off on the R-5 cascades with a rollback-infeasibility statement, plus the R-1/R-2 required-check evidence in the briefing. A per-decision ceremony increase, not a re-classification. |
| Stage 5 Activation bias | **ALL** — exercised per card, zero skips. |
| Stage 13 Outcome-window | **30-day** |

## Implementation Sequence

**Revised order (D-N, Tier 2), P0 fully-serial:**

`#5258` → `#5058` → `#5054` → `#5291` → `#5057` → `#5259` → `#5254` → `#4223`

| # | Issue | Track | Rationale for position |
|---|-------|-------|------------------------|
| 1 | **#5258** | 4 | Leads. An `Edit` of `core/rules/git-workflow.md` line 169 is **blocked today** whenever the replacement fragment carries a markdown link, because the file's `allow-link` declaration at line 162 is invisible to a fragment-scoped marker scan. Two sibling cards are scheduled to write that row. Dependency-free, `size:S`, and it removes a live obstacle from their path. |
| 2 | **#5058** | 1 | Transport swap GraphQL to REST; byte-compatible TSV, no logic change. First in Track 1 so every later parity run in this release is quota-resilient, and a pure-transport diff is the cheapest thing for the next three to rebase onto. |
| 3 | **#5054** | 1 | Adds the Removed-but-live classifier class. Introduces a *new arm* without changing how existing arms resolve. |
| 4 | **#5291** | 1 | Narrows `type:*` to pack-declared kinds plus the tolerated-alias arm. Highest collision risk — the only member touching the checker, the taxonomy and the pack-selection surface. Lands against a settled classifier shape and before the disposition record depends on it. **#5291 builds before #4223**, and its brief specifies two properties its own integration criterion omits: `--list-declared-kinds` must be **offline** and must **exit 0 on an empty result**. |
| 5 | **#5057** | 1 | Attribute-divergence class plus per-row disposition record. Last in Track 1, so the record is authored against the final classifier shape rather than authored twice. |
| 6 | **#5259** | 3 | Decides the canonical override-marker form; makes regex, message and fixtures agree. First in Track 3 because it *settles the form* #5254's discovery must then find, and because #5254 grades against the baseline it settles. |
| 7 | **#5254** | 3 | Replaces the hand-maintained `case` arms with discovery, graded against the `--equivalence` baseline #5259 settles. **R-4 constraint: discovery MUST NOT introduce a new declaration site in `core/hooks/lib/fragile-ref-patterns.sh`.** |
| 8 | **#4223** | 2 | Work-class resolution reads the packs' declared kinds. Resolved extend-seam: **consume #5291's helper, do not fork a second resolver.** |

**Dependency edges: 2 declared.** `#5291 → #4223` (soft — #4223 may ship independently by deriving from the pack source directly, at the cost of later adopting the helper) and `#5259 → #5254` (near-hard — #5254's AC-2 grades its behavioural delta against the fixture baseline #5259 settles).

**Discharged prerequisite.** `#4901`, the sole hard external prerequisite either Track-3 card declared, is closed, and the artefact it owed is present: `check-issue-ref-validity.sh` exposes `--self-test` and `--equivalence <pre-sha>`, with the fixture corpus at `core/deploy/tools/fixtures/issue-ref/`.

**External dependency — negative constraint, not a blocking prerequisite.** `#5291 → #5053` binds on `deploy.sh --check` cleanliness and on #5053's reachability gap, not on merge-ability: Check 51 is not wired into CI at all, so hardening it cannot red this release's PR under any disposition. **Restated for the record: this release must NOT graduate Check 51 out of advisory posture.**

## Stage Applicability Matrix

Default is all-apply. Stage 10 (Dry Run) and Stage 11 (Snapshot) are compressed for git-native releases — the PR diff IS the dry-run, git history IS the snapshot — so both are release-scoped and marked `cmp`. Stages 9, 12 and 13 are release-scoped.

| Issue | S5 | S6 | S7 | S8 | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|
| #5258 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |
| #5058 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |
| #5054 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |
| #5291 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |
| #5057 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |
| #5259 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |
| #5254 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |
| #4223 | APPLY | APPLY | APPLY | APPLY | rel | cmp | cmp | rel | rel |

**Stage 5 applies to 8 of 8 — this is not a default-all.** Each skip was tested and each failed: #5291 hands Solutioning a named unresolved constraint (resolve `type:*` against the *selected* pack set including K4 packs); #5258 is harness tooling and requires an implementation plan before any hook edit; #5058 carries an explicit routed assumption plus an untested pagination arm; #5057's disposition-record home is an assumption and its per-row decision is irreducibly human; #5054's four Removed-but-live labels carry an assumption whose two branches are not git-revertible; #5259's deliverable *is* a decision; #5254's marker-set derivation mechanism is unspecified and determines whether constants relocate into the shared library; #4223's consume-vs-fork call has a stated cost either way.

**Stages 7 and 8 apply to 8 of 8.** Every member changes the behaviour of a gate, a hook or a measurement instrument; none satisfies the no-functional-impact skip predicate. Denominator 8, skips 0. Specificity arm: #5254 is the closest candidate for triviality and still fails the predicate, because it changes what a required status check matches.

**Parallel-eligible spoke counts:** Stage 5 = 8 · Stage 7 = 8 · Stage 8 = 8.

## File Change Matrix

One path per line, fenced, so Stage 7/8/9 chip prompts extract the list deterministically. Intent markers use the shipped enum `add | edit | delete`; a marker-less path is `unknown`, never `edit`.

```
core/deploy/tools/check-label-parity.py                                edit
core/specs/label-taxonomy.md                                           edit
core/deploy/tools/README.md                                            edit
release/tools/compute-release-velocity.sh                              edit
release/references/standards/release-velocity-tracking.md              edit
core/deploy/tools/check-issue-ref-validity.sh                          edit
core/deploy/tools/fixtures/issue-ref/cases                             edit
core/deploy/tools/fixtures/issue-ref/manifest.txt                      edit
core/deploy/tools/fixtures/issue-ref/verdict-map.txt                   edit
core/rules/git-workflow.md                                             edit
core/hooks/block-fragile-refs.sh                                       edit
core/hooks/tests/block-fragile-refs.test.sh                            edit
release/releases/plans/label-and-reference-integrity_RELEASE_PLAN.md   add
```

Track attribution for the rows above, stated in prose so the fenced block stays machine-readable: Track 1 (serialized 5058 → 5054 → 5291 → 5057) owns `check-label-parity.py`, `label-taxonomy.md` and `core/deploy/tools/README.md`; Track 2 (#4223, after #5291) owns `compute-release-velocity.sh` and `release-velocity-tracking.md`; Track 3 (serialized 5259 → 5254) owns `check-issue-ref-validity.sh`, the three `fixtures/issue-ref/` paths and `core/rules/git-workflow.md`; Track 4 (#5258) owns `block-fragile-refs.sh` and `block-fragile-refs.test.sh`. The last row is release-scoped.

**The three corrected paths.** `core/rules/git-workflow.md`, `core/deploy/tools/README.md` and `release/references/standards/release-velocity-tracking.md` were absent from the Stage-4 matrix. They are not late additions to scope — they were always in scope and were invisible to a matrix computed over self-declared `Affected Files` sections. Declared here so Stage 7/8/9 path extraction sees them.

```
#### CONDITIONAL rows
core/packs/_common/pack.toml                                  edit  CONDITIONAL:triage-rows-materialize
core/config/allowlists/label-attribute-dispositions.txt       add   CONDITIONAL:disposition-record-homes-to-a-new-allowlist-file
```

```
#### Read-only inputs
core/packs/scrum/pack.toml                                    READ
core/packs/kanban/pack.toml                                   READ
core/hooks/lib/fragile-ref-patterns.sh                        READ
core/hooks/run-fragile-ref-fixtures.sh                        READ
core/deploy/deploy.sh                                         READ
```

```
#### Release-wide explicit non-scope
core/deploy/deploy.sh                                         NOT EDITED
core/packs/scrum/pack.toml                                    NOT EDITED
core/packs/kanban/pack.toml                                   NOT EDITED
core/hooks/lib/fragile-ref-patterns.sh                        NOT EDITED
core/hooks/run-fragile-ref-fixtures.sh                        NOT EDITED
core/standards/reference-durability-standard.md               NOT EDITED
.github/workflows/repo-integrity.yml                          NOT EDITED
.github/workflows/reference-durability.yml                    NOT EDITED
```

**Notes binding the matrix.**

1. `core/deploy/deploy.sh` sits deliberately in **both** the read-only and the non-scope blocks: #5058 reads Check 51 as its caller, and this release does not change Check 51's posture. That is CIAC-6 and R-8; declaring it explicit non-scope is what makes the negative constraint checkable rather than assumed.
2. `core/packs/scrum/pack.toml` and `core/packs/kanban/pack.toml` are READ and explicitly NOT EDITED. #5291's AC-6 grades exactly this — kinds are operator-local K4 config and are never authored into the corpus.
3. `core/hooks/lib/fragile-ref-patterns.sh` is READ and explicitly NOT EDITED — the R-4 constraint made mechanically checkable. It is **reciprocal**: #5254's discovery must introduce no declaration site there, and #5258's design introduces none either and adds no eighth constant. If Solutioning ever concludes otherwise, the row must be promoted in the same commit with its real basis recorded, and #5254 re-sequenced after #5258.
4. `core/hooks/run-fragile-ref-fixtures.sh` moved from `edit` to READ / NOT EDITED at Stage 5. Its fixture grammar is `expect \t class \t content` with **no path column**, and its classifier never invokes the hook — so it structurally cannot express either of #5258's limbs. It is run unedited as this release's regression arm.
5. **New-executable companion obligation: not owed** — the matrix carries no `add` row for a tracked `*.sh`, so `core/config/allowlists/script-execution-allowlist.txt` is not a required companion row.
6. **Placement is post-reorg-correct.** The plan file goes flat at `release/releases/plans/`; the move into `plans/v<MAJOR>/` happens at the Stage-12 atomic claim, not now. At Stage 13 the release note goes flat at `release/releases/notes/`, the `notes/vN/` collapse having already merged.

## Contention Map

Computed over write-sets only; `READ` rows are excluded from the obligation set, not merely un-flagged.

| Path | Writers | Count | Disposition |
|---|---|---|---|
| `core/deploy/tools/check-label-parity.py` | #5054, #5057, #5058, #5291 | **4** | **SERIALIZE** — Track 1 order 5058 → 5054 → 5291 → 5057 |
| `core/specs/label-taxonomy.md` | #5054, #5057, #5291 | **3** | **SERIALIZE**, same order. Stage 4 recorded 2; measured 3 |
| `core/deploy/tools/README.md` | #5054, #5057, #5058 | **3** | **SERIALIZE** — one table row all three Track-1 tool-changers falsify. Already resolved by Track 1's order; this is a record correction |
| `core/deploy/tools/check-issue-ref-validity.sh` | #5254, #5259 | **2** | **SERIALIZE** — Track 3 order 5259 → 5254 |
| `core/deploy/tools/fixtures/issue-ref/` | #5254, #5259 | **2** | **SERIALIZE**, same order |
| `core/rules/git-workflow.md` line 169 | #5254, #5259 | **2** | **SERIALIZE** — already resolved by Track 3's order. Graded INT-2. Both edit **different columns of the same table row** |
| `release/tools/compute-release-velocity.sh` | #4223 | 1 | None |
| `release/references/standards/release-velocity-tracking.md` | #4223 | 1 | None. This is the SSOT of the label-to-work-class map the script implements |
| `core/hooks/block-fragile-refs.sh` · `core/hooks/tests/block-fragile-refs.test.sh` | #5258 | 1 | None |
| `core/packs/_common/pack.toml` | #5054 (cond.) | 1 | CONDITIONAL on the three `triage:` rows materialising. #4223 and #5291 hold it READ-only, so a write here becomes a 3-way coupling if it fires |

**Cross-track coupling, measured.** `core/hooks/lib/fragile-ref-patterns.sh` declares seven canonical constants and is sourced by the hook, the fixture runner, the reference-durability workflow and the issue-ref gate. Two measurements bound the risk: `OVERRIDE` is **not** one of the seven (it is declared locally in the issue-ref gate, so #5259's regex widen touches no shared byte), and the runner's identity scan is `REFBLOCK_RE`-scoped only, which neither Track-3 card touches. The tracks are safe to run in parallel **at their currently declared scopes**. This is R-4.

**Cross-PR contention.** Zero open PRs repo-wide at the baseline, so no in-flight collision exists — recorded with the baseline pinned alongside it, because a default-to-zero over a transiently-empty population is not load-bearing on its own. The write-set is nonetheless hot: 30-day merge counts are `label-taxonomy.md` 10, `block-fragile-refs.sh` 6, `compute-release-velocity.sh` 6, `check-issue-ref-validity.sh` 4, `_common/pack.toml` 2, `check-label-parity.py` 1, against a control of 1480 commits in window and a fabricated-path specificity arm reading 0. This is R-3.

### In-Flight Release Roster

**Measured at:** `539c4440` · `2026-09-01T18:57:38Z` · **Population: none in flight.**

- Open PRs with a `release/*` head, drafts included: **0**, over a denominator of 0 open PRs repo-wide.
- Remote `release/*` heads carrying no open PR: **1** found and **excluded** — it is an ancestor of `origin/main`, so a merged release branch never deleted, not an in-flight sibling; its edit-set relative to `main` is empty.
- Control (sensitivity): `git ls-remote --heads origin` returns **3** heads, so the extraction is non-empty and the zero is measured rather than a failed read.

The sibling-intersection predicate is vacuous over an empty in-flight population. **No Tier-S structural serialization edge exists for this release.**

## Cross-Issue Acceptance Criteria

Six release-scoped cohesion constraints, each spanning ≥2 issues, graded on the merged PR at Stage 9 QC3.5 under the Stage-8 per-criterion verdict enum. CIAC-1, CIAC-2 and CIAC-6 carry their amended forms; the superseded Stage-4 wording is not transcribed.

- [ ] **CIAC-1 (#5054 x #5057 x #5058 x #5291 on `core/deploy/tools/check-label-parity.py`) — REGRADED:** shape was never the axis. The primitive always emits exactly two tab-separated fields, so a new verdict class preserves column count and order perfectly while the consumer's filter selects on the column-1 **value**; as originally written the criterion passes while the composite is silently false-green. Now grades: **every row the checker emits survives to the consumer's verdict — an unrecognised column-1 value produces a FINDING, never an absence.** *Method:* emit a synthetic row of an unknown class and assert the consumer neither discards it nor logs it as in parity; control arm asserts a known class still routes normally. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#5054 x #5057 x #5291 on `core/specs/label-taxonomy.md`) — AMENDED:** the document makes no positive claim the live label set contradicts — no row is simultaneously declared Removed and live, and every `triage:` row carries a recorded disposition. The criterion **acquires a new false-green under #5054's design**: moving the four Removed-but-live rows out of the ORPHAN arm satisfies the second clause by reclassification alone, whether or not any label is deleted. It therefore **asserts against the live label set**, not against the checker's own classification of it. **Control value restated 15 → 10** — the ORPHAN denominator changes when four rows reclassify, so a grader comparing against 15 is comparing against a stale figure. *Method:* intersect the Removed table's rows with the live label set and assert the intersection is empty; control arm asserts the non-Removed ORPHAN population is still non-zero at **10**, so a zero-Removed result is distinguishable from a probe that read nothing. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#5291 x #4223 on pack-declared kind resolution):** exactly one kind-resolution implementation exists across the parity gate and the velocity instrument — the extend-seam decision's consume-do-not-fork. *Method:* `grep -c 'type:feature' release/tools/compute-release-velocity.sh` returns 0 and the script carries no literal per-label `type:*` case arm; then both consumers resolve a newly-added fixture-pack kind without either file being edited. Control: a fabricated kind absent from every selected pack resolves to `feature` in neither consumer, so the derivation is not over-broad. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#5254 x #5259 on `core/deploy/tools/check-issue-ref-validity.sh` and `core/deploy/tools/fixtures/issue-ref/`):** after both land, the override regex, the failure message and the fixture corpus agree on one canonical override-marker form, and the run-time-discovered marker set includes that canonical form. Neither card can assert this alone — #5259 settles the form before discovery exists, #5254 replaces the enumeration after the form is fixed. *Method:* `bash core/deploy/tools/check-issue-ref-validity.sh --self-test`; assert the canonical form suppresses the gate and a near-miss form does not. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-5 (#5254 x #5259 x #5258 on the required-status-check surface):** the release's own PR reports success on both required contexts whose implementations it touches — the issue-reference validity gate (#5254, #5259) and the durable-corpus fragile-reference delta (#5258 runs its runner unedited as a regression arm). *Method:* read the PR's check-run states and assert both named contexts report success. Control: the other seven required contexts also report success, so a green result is not an artefact of checks having been skipped rather than run. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-6 (#5291 x #5054 x #5057 x #5058 — the negative constraint) — REGRADED:** the Stage-4 form graded a literal string that is **ratified false** — `core/standards/gate-efficacy-standard.md` records Check 51 as RATIFIED ADVISORY on architectural grounds, the flip being declined rather than postponed, because the check's subject is out-of-tree GitHub state and its verdict-input closure over repo paths is empty. Grading the literal string made the criterion forbid correcting the sentence that misstates the constraint it protects. Now grades the **behaviour**: **Check 51 remains advisory after this release and the merged diff introduces no enforce-mode transition for it.** *Method:* read the Check 51 posture declaration and assert it is unchanged from advisory; control asserts the Check 51 declaration site is still locatable in the same file, so a zero on the transition probe is distinguishable from a failed read. The stale prose in the deploy script's Check 51 comment block is routed to #5053 for enrichment, not corrected here and not duplicated. *Graded at Stage 9 QC3.5 on the merged PR.*

## Verification Plan

**AC baseline (pinned measurement, no verdict).** Read at `539c4440`: #4223 = 8 · #5054 = 4 · #5057 = 4 · #5058 = 4 · #5254 = 3 · #5258 = 4 · #5259 = 4 · #5291 = 13. **Total 44.**

**Re-baselined at Engineering Commit 0: total 45.** #4223 gained **AC-9** at Stage 5 (decision D-P) and had **AC-2** and **AC-3** amended in place — both now grade the *emitted* allocation from `work_class()`, not only the self-tested reference `labels_to_work_class()`, because asserting the reference alone certifies a no-op. A criterion count that no longer matches its baseline is a mechanical signal to re-bind the rows below; this one moved by design and is recorded rather than absorbed.

Each row's `AC` cell is the 1-based ordinal of the criterion in its issue body's checkbox list and carries no restatement of the criterion's words. The `Verification Method` cell carries the method the criterion itself declares. A method whose executor is declared but not yet built is a valid method for gate purposes — it is recorded, surfaced and tracked, never silently dropped.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #5258 | AC-1 | `grep -c 'reference-durability-allowlist.txt' core/hooks/block-fragile-refs.sh` — the corrected ledger-exemption comment names the allowlist as the mechanism that spares a release plan, rather than claiming the scope gate excludes it. Control: arm **L1-1** in `core/hooks/tests/block-fragile-refs.test.sh` is the desync detector — it fails if the allowlist entry is ever removed while the comment still says plans are unreachable | count **≥ 1** · control arm L1-1 exits 0 |
| #5258 | AC-2 | Arm **L2-1** in `core/hooks/tests/block-fragile-refs.test.sh`, executed via `bash core/deploy/tests/run-install-regression.sh` — an `Edit` of a marker-bearing file on a link-bearing line. Control: arm **L2-2**, the identical fragment on a marker-free file | L2-1 exit **0** · control L2-2 still exit **2** |
| #5258 | AC-3 | `grep -c 'CLAUDE_HOOK_BYPASS' core/hooks/block-fragile-refs.sh` — the sole override is still declared exactly where it was; paired with a read of `git diff origin/main -- core/hooks/block-fragile-refs.sh` asserting the added code introduces no `exit`, no early `return` and no new environment read. Control: arm **L2-3** proves the marker did not leak to the positional rule | count **≥ 1** · added code confined to marker-source resolution · L2-3 exit **2** |
| #5258 | AC-4 | **Instrument re-pointed (Tier-1 ADJUST).** `core/hooks/run-fragile-ref-fixtures.sh` is content-regex-only and cannot express a path or on-disk property, so the four new arms live in the test harness. Record the pre-change run of the four arms and the post-change run via `bash core/deploy/tests/run-install-regression.sh`; the fixture runner is asserted byte-identical and its execution arm stays CI-owned | L2-1 exits **2** against the pre-change hook and **0** after · post-change suite 18 of 18 · runner diff empty |
| #5058 | AC-1 | Trace the outbound request from `core/deploy/tools/check-label-parity.py`; assert the endpoint is the REST labels path | No GraphQL call on the label-fetch path |
| #5058 | AC-2 | Force the GraphQL path to fail and re-run the checker; assert it still produces its normal TSV output | Determinate verdict, non-3 exit, TSV emitted |
| #5058 | AC-3 | Seed or mock a >100-label response; assert the parsed count equals the seeded count. Control: a <100-label case also passes | Parsed count equals seeded count in both arms |
| #5058 | AC-4 | Capture the Check 51 parsed TSV before and after on an unchanged label set and diff | Byte-identical output |
| #5054 | AC-1 | Run `check-label-parity.py` against a fixture containing one Removed-table entry that is live; assert the output names it in a distinct class | The row appears in a class distinct from MISSING and ORPHAN |
| #5054 | AC-2 | Intersect the `## Removed Labels` table rows with the live label set; assert the intersection is empty, or that the table is withdrawn with rationale | Intersection empty, or table withdrawn with recorded rationale |
| #5054 | AC-3 | Locate each of the three `triage:` names in `core/specs/label-taxonomy.md` and confirm a stated disposition accompanies each | 3 of 3 rows carry an explicit recorded disposition |
| #5054 | AC-4 | Run the parity check and confirm no MISSING row matches `^triage:`. Control: the ORPHAN arm is non-empty on the same invocation and the same target | 0 `triage:` MISSING rows · control ORPHAN non-zero. Graded against this card's three declared rows, not against zero — `auto-promoted-pattern` post-dates the card and is deliberately unowned here |
| #5291 | AC-1 | `grep -n "kind_id" core/specs/label-taxonomy.md` — assert ≥1 match inside the Work-Item-Kind Labels block | ≥1 match inside that block |
| #5291 | AC-2 | Read Rule 7 in `core/specs/label-taxonomy.md`; assert it references `type:*` or the kind label alongside the category label and the title prefix | Rule 7 names the kind label |
| #5291 | AC-3 | Count the live label named `type:observation` | **0** carriers |
| #5291 | AC-4 | Assert the `type:adr` live count is 0 and that the 2 issues which lacked `adr` now carry it. Control: the `adr` carrier count is non-zero before and after, so the probe is not reading an empty population | `type:adr` **0** · control `adr` non-zero on both reads |
| #5291 | AC-5 | Add a fixture K4 pack declaring a `bug` kind to the selected set; assert `type:bug` is absent from the ORPHAN arm. Control: with that pack removed from the selection, `type:bug` IS reported | Absent with the pack selected · reported without it |
| #5291 | AC-6 | Assert the merged diff touches no `[[kinds]]` block in `core/packs/*/pack.toml`. Control: the diff DOES touch `check-label-parity.py`, so the assertion is not passing on an empty diff | 0 pack-kind edits · control non-empty |
| #5291 | AC-7 | Run `./deploy.sh --check` on a fixture whose live set contains a `type:` label absent from every pack's kinds; confirm that label is named in the Check 51 output | The label is named in a non-empty ORPHAN arm |
| #5291 | AC-8 | Assert the union-minus-A difference is 0 over the whole population (open plus closed), where A is the `observation` category label and B is `type:observation`, using a lexical sort | Difference **0** — a numeric sort into `comm` is the known-wrong form |
| #5291 | AC-9 | Fixture live-set containing `type:observation` with the corpus `--source` set; assert it appears in the ORPHAN arm | Count ≥ **1** (must-flag, non-vacuous) |
| #5291 | AC-10 | Same invocation; assert none of `type:epic`, `type:story`, `type:task`, `type:card` appears in the ORPHAN arm | Count **0** (must-not-flag, declared kinds) |
| #5291 | AC-11 | Same invocation; assert `type:subtask` appears in neither the ORPHAN arm nor any new undeclared-kind arm. Control: `type:adr`, still undeclared, does appear | `type:subtask` **0** · control non-zero |
| #5291 | AC-12 | Same invocation with the full live label set loaded; assert no label matching `^project:` or `^epic:` appears in the ORPHAN arm | Count **0** (sibling namespaces still resolve by registration) |
| #5291 | AC-13 | Re-run with `--source` narrowed to `_common` plus scrum only; assert `type:card` appears in the ORPHAN arm while the corpus-declared kinds do not | `type:card` ≥ **1** with the reduced source set |
| #5057 | AC-1 | Count divergent rows from the parity tool and count dispositioned rows in the record; assert equality | Counts equal — no row left undispositioned |
| #5057 | AC-2 | Run against a fixture with one name-matched, colour-divergent row; assert it appears in neither MISSING nor ORPHAN and does appear in the new class | Divergence reported as a distinct class |
| #5057 | AC-3 | Register one row as an accepted override, re-run, assert it is absent from the divergence arm. Control: a non-registered divergent row remains present | Registered row absent · control row still present |
| #5057 | AC-4 | Run Check 51 before and after; assert the parsed TSV column structure is unchanged | Identical column structure |
| #5259 | AC-1 | Read the override regex, the failure message and the fixtures; assert the form the message instructs is the form the regex accepts and the form a fixture exercises. Control: a deliberately non-canonical form is asserted NOT to suppress | All three agree on one form · control does not suppress |
| #5259 | AC-2 | Place the canonical marker in a fixture file carrying a would-be-flagged reference; assert the gate does not fire. Control: the same file without the marker still fires | Marked fixture clean · control still fires |
| #5259 | AC-3 | Assert a marker inside a code fence, and a marker-like string in prose, do NOT suppress the gate | Neither suppresses |
| #5259 | AC-4 | Assert the issue-reference validity gate reports success on a PR touching an unrelated path | Required check green |
| #5254 | AC-1 | Assert the hand-maintained `case` arms are gone and the marker set is derived at run time. Control: a fabricated marker is not discovered, so the discovery is not over-broad | 0 literal `case` arms · control not discovered |
| #5254 | AC-2 | Run the `--equivalence` harness pre- and post-change; assert the report diff is either empty or explicitly enumerated and accepted | Diff empty, or enumerated with a recorded acceptance |
| #5254 | AC-3 | Assert the issue-reference validity gate reports success on a PR exercising each discovered marker class | Required check green across every discovered class |
| #4223 | AC-1 | Assert the literal per-label `case` arms are gone and the mapping is derived from the pack source at run time. Control: a fabricated label is not resolved to `feature`, so the derivation is not over-broad | 0 literal arms · control resolves to `debt` |
| #4223 | AC-2 | **AMENDED at Stage 5 (D-P).** Assert `labels_to_work_class` returns `feature` for a story carrying `improvement`, AND that the **emitted** allocation from `work_class()` agrees. Control: the same call without `improvement` or `type:story` still returns `debt` | `feature` from BOTH implementations · control `debt`. MET only when the emitted allocation agrees — asserting the reference alone certifies a no-op |
| #4223 | AC-3 | **AMENDED at Stage 5 (D-P).** Assert `type:story` resolves to `feature` independently of `improvement`, in the reference AND in the emitted allocation | `feature` from both. This arm is absent today |
| #4223 | AC-4 | `grep -c 'type:feature' release/tools/compute-release-velocity.sh` | **0** — the label does not exist in the live set, so an arm naming it can never fire |
| #4223 | AC-5 | Add a kind to a fixture pack and assert it resolves by rule with no script edit. Control: a kind absent from every selected pack does NOT resolve to `feature` | Resolves by rule · control does not resolve |
| #4223 | AC-6 | Assert an unmapped label returns `debt` by a stated branch with a cited rationale, not by falling off the end of an enumeration | Default reached by rule, with rationale cited at the branch |
| #4223 | AC-7 | Run the script's self-test block; assert the existing `enhancement`, `protocol`, `bug`, `cluster: tech-debt`, `cluster: architecture` and unlabeled cases return their current values | Self-test passes unchanged |
| #4223 | AC-8 | Re-run the velocity computation over v3.100's membership; assert the 3 stories register as feature allocation | No longer reads 0/20/0 |
| #4223 | AC-9 | **ADDED at Stage 5 (D-P).** Assert `labels_to_work_class` (bash) and `work_class()` (python) return the same work class for every fixture label-set. Control: mutate one implementation and assert the check FAILS | Agreement on every fixture · control FAILS on the planted divergence — a check that cannot fail on a planted divergence is not a check |

## Risk Register

| ID | Risk | Severity | Reversibility · Confidence | Owner stage | Mitigation |
|---|---|---|---|---|---|
| **R-1** | **The release changes a required status check that gates its own PR.** The issue-reference validity gate is one of the nine required contexts on `main`; #5254 and #5259 both modify its implementation. A defect blocks the merge, and the failure is self-referential — the check that would report it is the one being changed. | **HIGH** | CHEAP · HIGH | S5 → S7 | Land #5259 first and run `--self-test` plus `--equivalence <pre-sha>` before #5254's discovery change, so the delta is measured against a green baseline rather than argued. #5259's AC-4 already requires the gate to pass on an unrelated-path PR — treat that as a merge precondition, not a closing check. |
| **R-2** | **A second required check runs a script this release touches.** The durable-corpus fragile-reference delta executes `core/hooks/run-fragile-ref-fixtures.sh`. **Downgraded HIGH → LOW at Stage 5:** under the selected design that file is read, run and asserted unchanged, not edited. The residual is the ordinary obligation to keep a green check green. | **LOW** | CHEAP · HIGH | S6 → S7 | Baseline captured at `539c4440`: 51 passed / 0 failed, redeclaration 0 findings across 3 of 3 targets, identity 0 divergent across 308 of 308 paths, 2 pre-existing value-shape advisories dispositioned accepted. Run the exact CI invocation locally before pushing and assert an empty diff on the runner. |
| **R-3** | **The write-set is hot; a long-lived branch accrues rebase debt.** `core/specs/label-taxonomy.md` took 10 commits in 30 days and is written by 3 members; `block-fragile-refs.sh` took 6. Zero open PRs today, but the baseline is pinned, not durable. | MEDIUM | CHEAP · HIGH | S9 | Stage 9 Phase A6.5 is the designed catch; Stage 12 Phase A.5 is the last line. Keep the branch short-lived and land Track 1 as a contiguous run rather than interleaved. |
| **R-4** | **Latent Track-3 / Track-4 collision on `core/hooks/lib/fragile-ref-patterns.sh`.** Both tracks source it. Inert at declared scope, but #5254's derive-the-marker-set-at-run-time could relocate marker constants into that library, whose consumers #5258 is concurrently editing. | MEDIUM | CHEAP · MEDIUM | S5 (#5254) | **Reciprocal constraint, recorded from both sides.** #5254's discovery must not introduce a new declaration site in that library; #5258 introduces none there either and adds no eighth constant. If a declaration proves unavoidable, serialize #5254 after #5258 and re-run the identity scan. |
| **R-5** | **Two irreversible repository-state cascades, neither git-revertible.** #5291 strips `type:observation` from 76 dual-labelled issues and deletes that label plus `type:adr`; #5054 either deletes four live default labels or withdraws a governance table asserting they were removed. Label state is not in git. **Blast radius extended at the Stage-4 gate:** deletion also reaches 7 further issues carrying `type:observation` without the `observation` category, so total label-deletion reach is **83, not 76**. All seven are closed, so the consequence is archival rather than live — but the extension was undeclared on the one action in this release that has no rollback. | MEDIUM | **IRREVERSIBLE (deletion) · MODERATE (re-add)** · HIGH | S9 gate | Operator-authorized, user-side action. Require explicit sign-off at Stage 9 with a rollback-infeasibility statement naming the 83 figure; do **not** execute either cascade from a spoke. |
| **R-6** | **The dual-label exposure is live, growing, and contains two of this release's own members.** 188 issues carry both `bug` and `type:bug`, up from a recorded 187 in about two days. **#5258 and #5259 are both in that set.** Hardening `type:*` without a resolution path leaves a Rule 1 breach at scale, including on cards this release is itself resolving. | MEDIUM | MODERATE · HIGH | S5 (#5291) | Stage 5 picks one of the three paths #5291 names — retire the `bug` category row from `_common`, amend Rule 1 to permit the category-row plus kind-projection pair, or strip one label from the 188. Apply the choice to #5258 and #5259 before Stage 13, so the release does not mark cards as closed at Stage 13 that violate the rule it just hardened. |
| **R-7** | **Check 51's canonical set is corpus-only, so hardening `type:*` orphans a deployment's own declared kinds.** A deployment declaring `bug` in its own K4 pack would see `type:bug` reported as an orphan. Verified live. | MEDIUM | CHEAP · HIGH | S5 (#5291) | #5291's stated design constraint; two of its criteria already grade it. Solutioning owns the mechanism; the card commits the outcome, not the path. |
| **R-8** | **Negative-constraint drift.** If the release is ever scoped to include Check 51's graduation out of advisory posture, `#5291 → #5053` inverts into a hard prerequisite and a Dependency Exceptions block must be registered before Stage 4. #5053 is still open. | LOW | CHEAP · HIGH | S9 gate | State the constraint in this plan and re-assert at Stage 9: this release does not graduate Check 51. Its posture is **ratified advisory** on architectural grounds, so the graduation is declined rather than pending. |
| **R-9** | **#5057's outcome is an operator-disposition backlog, not a code change.** 28 label-edit and 4 label-create commands render today; what does not exist is a record saying which to run. Shipping the divergence class without the dispositions moves the problem rather than resolving it. | MEDIUM | CHEAP · HIGH | S5 → S9 | Scope the disposition pass at Solutioning: either all 32 rows get a recorded disposition in this release, or AC-1 is re-scoped and the residual routed to a successor. Do not let AC-1 grade MET against a partially-populated record. |
| **R-10** | **Rollback complexity is asymmetric.** All four tracks are `git revert`-ible at the code level, but R-5's label mutations and #5057's disposition applications are repository state outside git — a code revert leaves label state changed. | MEDIUM | MODERATE · HIGH | S9 / S12 | Revert the release PR for all code; label-state restoration is a separate operator-run user-side procedure. **Capture the full live label list with names, colours and descriptions to a file before any label mutation** — that capture is the only rollback substrate that will exist. Make it a Stage 9 sign-off precondition, not a Stage 12 step. |

**Severity: 1 HIGH · 7 MEDIUM · 2 LOW.** No CRITICAL, no BLOCKED verdict. R-2 is the downgrade; it entered Stage 4 as HIGH.

## Authorized ADRs

One, on #5291 (its Stage-5 decision D5). This is the `novel` trigger (c) that carries the class re-classification. **No ADR is authorized for #5258** — the decisive question there is already answered in ratified governance and already implemented that way in CI, so the design conforms to a written decision rather than making one.

## Baseline Pin

`origin/main` @ **`539c4440`** · measured `2026-09-01T18:57:38Z` · milestone #337 · local `HEAD` identical, no divergence. Every Engineering spoke branches from this SHA. Stage 9 Phase A6.5 re-checks divergence against it; Stage 12 Phase A.5 is the last line.

## Quota Budget

**Verdict:** WARN at plan time (Checkpoint A), superseded in part by the operator's stated band.
**Parallel-eligible spokes per parallel stage:** Stage 5: 8 · Stage 7: 8 · Stage 8: 8
**Per-spoke cost estimate:** size-bucket ordinal band (no telemetry medians available). Worst batch: 5 x `size:S` plus 3 x `size:M`.
**Assumed/stated remaining usage-window envelope:** the plan-time basis was `UNSTATED`; the operator subsequently stated **substantially fresh (>70%)** of the 5-hour window remaining, which supersedes it. Read conservatively as `partial-70%`, because ">70% remaining" means up to 30% already drawn.
**Estimated cumulative draw % (worst parallel batch):** deliberately **not rendered** at plan time. A draw percentage is only ever a projection of an operator-stated band; with the band `UNSTATED` at Checkpoint A, a sourced-looking number this session could not have obtained is worse than no number.
**Routing:** window-aware launch timing plus quota-budgeting. Stage-5 wave width was set at 3 (8 spokes as 3 re-gated sub-waves).
**Note:** Checkpoint B re-validates at every agent launch — wave or singleton, every stage — and additionally gates on the host-API pools this section deliberately omits. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time. Bands and floors are calibrate-after-3, MEDIUM confidence.

## Merge/Split Recommendations

**No merge, no split.** Four candidates tested; each declined on evidence.

- **Merge #5054 + #5057 + #5291** — declined. They answer three different questions on one surface: presence/absence, attribute divergence, kind resolution. Merging yields one card spanning 21 criteria and three independent remedies, whose partial failure is unattributable. Serialize instead.
- **Merge #5254 + #5259** — declined. They are ordered, not overlapping: #5259 settles the canonical form, #5254 grades its delta against that settled baseline. Merging collapses the baseline into the change and reproduces the equivalence-proof-arguing-with-itself problem that deferred #5254 in the first place.
- **Split #5291** — declined. Reviewed at milestone-readiness and declined by the operator with the rationale recorded on the card. Re-verified: the scope that made a split attractive has narrowed.
- **Split #5058's pagination arm into a successor** — declined. The card frames pagination as what turns an availability bug into a correctness bug if unimplemented, and its AC-3 already grades it with a control. Splitting ships the transport swap with a known under-read.

## Change Log

| Revision | Date | Change | Source |
|---|---|---|---|
| Stage 4 | 2026-09-01 (Tuesday) | Initial release plan authored on sub-task #6444; verdict PROCEED, 6 CIACs, Quota Budget WARN. | Stage-4 planning spoke |
| Gate D-A..D-D | 2026-09-01 (Tuesday) | Plan approved. Quota band stated. Branch topology SINGLE with P0 fully-serial dispatch. Five milestone-description edits authorized. CIAC-6's control value correction routed into this file. | Operator, Stage-4 Plan Review gate |
| PLAN CORRECTION | 2026-09-01 (Tuesday) | CIAC-1 regraded (value, not shape); CIAC-2 amended with control value 15 → 10; CIAC-6 regraded to the behaviour rather than a ratified-false literal string. Contention Map gains `core/rules/git-workflow.md` line 169 and `core/deploy/tools/README.md` line 89. | Operator, D-K |
| PLAN CORRECTION 2 | 2026-09-02 (Wednesday) | File Change Matrix gains `release/references/standards/release-velocity-tracking.md` — the third undeclared-edit instance, same root cause. #4223's write-set established at 2 files. Revised Stage-6 order recorded (D-N, Tier 2): #5258 leads. | Operator, D-N |
| Commit 0 | 2026-09-02 (Wednesday) | Transcribed to this file as Engineering Commit 0, corrections applied. Release Class re-classified `novel` out of band, effective points 25. Version re-verified: next-free `v4.46`, anchor `v4.45`, free on all five surfaces. Verification Plan re-baselined 44 → 45 criteria for #4223's Stage-5 addition. R-2 recorded at its downgraded LOW. | Stage-6 Engineering spoke (#6466) |
