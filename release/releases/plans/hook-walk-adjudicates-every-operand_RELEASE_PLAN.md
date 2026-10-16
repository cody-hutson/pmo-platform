---
title: Release Plan — hook-walk-adjudicates-every-operand (the script-execution, egress and filesystem-boundary guards adjudicate every operand their token walks reach)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.75; the concrete number binds at the Stage-12 atomic claim)
milestone: hook-walk-adjudicates-every-operand
release_class: novel
reversibility: MODERATE / Confidence HIGH — one branch and one merge; every card reverts with its own commits and a republish of the hook bundle, and reverting the merge restores main. MODERATE rather than CHEAP because the walk changes reach every Bash call on an instance once the hook publisher runs, and a graduated rollout phase, if the operator renders one, is EXPENSIVE to reverse (card #7026's own tag). A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `hook-walk-adjudicates-every-operand`

**Milestone:** `hook-walk-adjudicates-every-operand` (milestone 404). The Stage-4 planning sub-task **#8159** carries the approved four-part plan, the Stage-4 gate's decision record, the card-corrections record and the Collective Review scope-lock record; this file transcribes that plan as those two decision records amend it. The seven Stage-5 designs are on **#8162–#8168**, their independent adversarial reviews on **#8230–#8236**. The Stage-6 Engineering sub-tasks are **#8169–#8175**; this file is Engineering Commit 0, authored by the spoke on **#8171** (card #7019), which also builds the first card slice.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.75`**. The Stage-4 gate recorded `minor` with the display `v4.74`; a sibling release claimed `v4.74` before this release left Stage 5, and the scope-lock record moved the display to `v4.75`. The Commit-0 re-verify below recomputed the slot from live host state and found `v4.75` free. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only.

**Topology:** D-C **SINGLE** — one release branch, `release/hook-walk-adjudicates-every-operand`, one pull request opened in **draft** directly after this commit so the pull-request checks run on every later slice, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — eight commit groups in § Implementation Sequence order, each pushed as it lands. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel` — confirmed at the Stage-4 gate; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8159 (parts 1–4) and is amended by the two decision records on that thread: the Stage-4 plan approval of 2026-10-08 and the Collective Review scope-lock of 2026-10-09. Where the plan and a decision record differ, the decision record wins; where a Stage-5 design and the scope-lock differ, the scope-lock wins. Each such change from the Stage-4 comment is recorded in § Deviation Log with the decision that caused it. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version: guard logic and readiness text inside existing structure; no new skill and no new governance file). Provisional display v4.75, re-verified free at Engineering Commit 0; the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-10-15 (Thursday) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Commit 0 and slices 1 (#7019), 2 (#7018) and 3 (#7020) built; slices 4–7 follow in § Implementation Sequence order |
| **Branch** | `release/hook-walk-adjudicates-every-operand` |
| **PR** | #8306 — opened in draft directly after Engineering Commit 0 |
| **Milestone** | `hook-walk-adjudicates-every-operand` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-10-08, domain: security }`

**Domain classification.** Form **X** (sourcing-exempt): the File Change Matrix is entirely internal — hook sources, their suites, their readiness fragments and the generated registry — so external sourcing is exempt. The deliverable is security controls implemented in shell, so the dominant class is `security` (guide `core/standards/domain-best-practices/security.md`), secondary `software`. Transcribed unchanged from the Stage-4 plan (Phase A1.5) and carried unchanged by every Stage-5 design.

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch origin main`, then `git fetch --tags origin` | both exit 0; `origin/main` = `20197085` (`201970851da959db01111ef155f2f96d6676bfeb`, the merge of the `v4.74` Stage-13 chore). The release branch was created from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 201970851da959db01111ef155f2f96d6676bfeb --bump minor --dry-run` (the adapter's own `anchor()` and `claimed_set()`; no tag pushed) | **`v4.75`** (exit 0; "would claim v4.75 (no tag pushed)") — equal to the planned display |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh api --paginate repos/<owner>/<repo>/releases, tag names    (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each filtered for the v4.75 slot
Denominator: 436 ls-remote lines; 217 published Releases (paginated, not truncated);
             the ledger at origin/main, 2,723 lines
Control - sensitivity: the same three readers on the v4.74 slot — tag v4.74 (peeled ff3eecdf),
             Release v4.74, and the v4.74 ledger row (telemetry-is-computable, VERIFIED) at
             line 254. Every arm returns non-zero, so a zero on the v4.75 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple has
             no near-miss class the probe must reject
Extraction:  the full ls-remote output, the full Release list and the full ledger read from
             origin/main (never the worktree copy)
Result:      0 occupants of the (4,75) slot on every arm; the highest claimed tag is v4.74
Verdict:     CLEAN — v4.75 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** one sibling release branch with a draft pull request, `controls-fail-loud`, bump-class `minor`, which recomputes to the same `v4.75` slot (§ Cross-PR Overlap Audit → In-Flight Release Roster). Merge order arbitrates the slot at the Stage-12 compare-and-swap; no sibling has claimed it, so this is an enumeration, not a collision.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp hook-walk-adjudicates-every-operand`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited, amended by both decision records) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1` to `CIAC-4`, under a markdown heading) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (with the AC baseline and the Commit-0 conversion of this slice's deferred rows) | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence (the approved build order) | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA, and the Commit-0 base beside it) | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| # | Issue | Title | Priority | Primary file | Labels |
|---|-------|-------|----------|--------------|--------|
| 1 | #7019 | A flag token whose leading quote closes early ends the walk, leaving the script operand unadjudicated | P2 (Severity) | `core/hooks/block-destructive.sh` | bug, size:M |
| 2 | #7018 | An argument-taking option before an inert-mode flag lets a -s invocation execute while the guard reads it as parse-only | P2 (Severity) | `core/hooks/block-destructive.sh` | bug, size:M |
| 3 | #7020 | Two sibling guards carry divergent transparent-wrapper sets, and the narrower one omits nice and stdbuf without declaring them | P2 (Severity) | `core/hooks/block-destructive.sh` | bug, size:M (re-sized in scope at the scope-lock; the label is the card's) |
| 4 | #7028 | The -022 enclosure fail-open has no tracker, though shipped documentation says it is tracked separately | P3 (Priority) | `core/hooks/block-destructive.sh` | improvement, size:M |
| 5 | #7004 | The egress prefix-command walk has no option arity, so a separate-argument option hides the gated command behind it | P2 (Severity) | `core/hooks/block-egress.sh` | bug, size:M |
| 6 | #7027 | A parameter-transformation operator creates an execution surface the command-substitution guard cannot see | P3 (Priority) | `core/hooks/block-fs-boundary.sh` (suite and fragment only — no hook edit) | improvement, size:M |
| 7 | #7026 | Nobody owns the warn-to-enforce graduation decision that Check 71 forces on 2026-12-02 | P2 (Priority) | `core/rules/bypass-mode-readiness/block-destructive.md` (constants conditional on its gate) | improvement, size:S |

Priority is each card's own Severity or Priority field, and labels are as the cards carry them at Commit 0 (every card also carries its pipeline `status:` label); the authoritative values are on the cards.

### Exclusions

Enumerated over the classes the two decision records and the Stage-4 plan name; each is out of this release by a recorded decision:

- **The operand fold #7019's design recommended** (its scope option that adds a third view to the shared subject rule): not taken (scope-lock, the concurring set). The split-suffix operand it would have closed is routed to its own card through the intake pass decided at the scope-lock (D8).
- **#7020's handed text for the quoted-assignment-value gap:** declared in this release, the fix routed to its own card (scope-lock D3). That text is not built.
- **#7027's parameter-transformation class:** declared out of scope, pinned and its coverage claim corrected; the class is routed to its own card (scope-lock D6). No hook file is edited for it.
- **The unmilestoned sibling of #7028** (the grouping and `xargs` shapes): stays a separate card (scope-lock, the concurring set).
- **The egress rule's widening-phase graduation:** owned by its own card in another milestone (Stage-4 gate D3); this release records the prefixed position at that rule's current rollout phase.
- **The warn-to-enforce graduation itself:** decided at its own operator gate on #7026's Stage-6 sub-task, not by this plan.

---

## Decision Record

### Stage-4 plan gate (operator, 2026-10-08)

| # | Decision | Operator's choice |
|---|---|---|
| D1 | Approve the release plan and the Release Outcome Statement draft | **Approve** — with it, Release Class `novel`, Branch Topology SINGLE, Concurrency Posture fully serial |
| D2 | R-1 — card #7027 names the wrong guard | **Correct in place** (no membership change) |
| D3 | Q7 — card #7004's outcome for this release | **Accept "evaluated and recorded in shadow"** |

**Recorded determination (not a gate):** D-Version — bump-class `minor`; provisional display `v4.74` at the gate, contested by two in-flight siblings; re-verified at Engineering Commit 0 and bound only at the Stage-12 atomic claim.

### Collective Review scope-lock (operator, 2026-10-09)

Scope is locked for Stage 6 through Stage 9; a change from here is a governed override.

| # | Decision | Operator's choice |
|---|---|---|
| D1 | Scope-lock the concurring set (below) | **Approve** |
| D2 | Where the differential lives | **One tracked corpus**, read by the suite's own harness; every card and reviewer adds rows |
| D3 | The Blocker on #7020's handed text for the quoted-assignment-value gap | **Declare in this release and route the fix to its own card** — that text is not built |
| D4 | #7020 option scope | **Whole wrapper set**, with the review's three stated costs as build conditions; the card is re-sized |
| D5 | #7028 rollout | **Phased** — new findings enter at the warn phase; a later graduation decision is owed |
| D6 | #7027 subject | **Declare out of scope here, pin, correct the coverage claim, route the class to its own card** — no hook edit |
| D7 | Build sequencing against the weekly budget | **Start Stage 6 now, #7019 then #7018 first**, then the rest |
| D8 | Tracking for the out-of-scope gaps found during design | **Bug cards through one intake pass**, with a duplicate search, at security priority |

**The concurring set locked by D1:**

- #7004 — the secondary-locator design, with the review's condition that look-ahead records be distinguishable from records of real invocations.
- Wrapper-vocabulary placement — **per-guard**, not a shared library; the parity arm reads every copy the reviews named.
- #7019 — the design's recommended walk option (a whole word that opens with a quote is read as its unquoted spelling; a fragment still ends the walk; a word of unknown value takes the conservative route under an interpreter and is stepped over under `source`), **plus the review's one additional arm** for the gap it found: the scanner reports a word that carries an unquoted brace, glob or tilde character as a word of unknown value.
- The class of flag spellings claimed by both #7018's and #7019's gates — a flag token that begins with `-`, `+` or a backslash and carries a quote or a backslash — is assigned **once, to #7018**.
- #7018 — the option-run latch, its recommended scope answer, and the fold of the command-string cluster #7019's design routed to it.
- #7028 — close the fail-open; the unmilestoned sibling card stays separate; the two adjacent fail-opens the design found are included, with the review's correction.
- #7020 — the conditional-keywords line, with the reviewer's pin.
- #7019's operand fold — **not** folded.
- #7026 — the decision package and its evidence plan are accepted with the review's corrections; the graduation decision itself is rendered at its own gate on that card's Stage-6 sub-task.
- Card text — the Tier 1 wording deltas the designs and reviews raised, and the six residual inconsistencies left at Stage 4, are applied as operator-gated body edits before Stage 7.

**Recorded determination:** bump-class `minor`; the provisional display moved to `v4.75` when a sibling release claimed `v4.74`.

**One Release Outcome Statement clause is imprecise under D5** — it says the enclosure fail-open is "refused or pinned", and under D5 it is closed at the warn phase first. Flagged for the Stage 9 goal-conformance check rather than re-worded here.

### Hub determination before the first Engineering launch (2026-10-15)

The hub re-ran the plan's Phase A3.5 two-control read over the path D2 added to card #7019's write set (the tracked corpus) and found it `unconstrained`; #7019's card class and #8171's stamp stay `unconstrained` (§ Agent-Editability Read).

---

## Dependency Graph

Native dependency fields: 0 typed blocked-by edges on 7 of 7 members (Stage-4 probe, re-read unchanged at Commit 0 in the milestone description's reconfirm line). The edges below are soft, serialization or release-gate edges.

| Edge | From → To | Type | Status after the scope-lock |
|---|---|---|---|
| E1 | #7018 → #7026 | soft — decision evidence | holds |
| E2 | #7019 → #7026 | soft — decision evidence | holds; this slice turns previously silent family shapes under the phase-gated interpreters into `interp-nonshell` would-fire rows, which #7026's evidence reads as this family's true positives or as the declared extensionless over-block |
| E3 | #7020 → #7026 | soft — decision evidence | holds |
| E4 | #7028 → #7026 | soft — decision evidence | holds |
| E5 | #7004 ↔ #7020 | one build unit under the shared-table placement only | **void** — per-guard placement (scope-lock); #7004 and #7020 are independent slices |
| E6 | canonicalizer → #7027 and four hooks | coupling under the canonicalizer placement only | **void** — that placement was not taken |
| E7 | #7019, #7018, #7020, #7028, #7026 | serialization on one file, one suite, one fragment | holds — serial slices; #7019 and #7018 edit the same loop, strictly in that order |
| E8 | `hook-publisher-republishes` → this release | release gate, not a build edge | holds — re-verified by hash at Stage 12 after the publisher runs |

No circular chain: E1–E4 end at the sink #7026; E7 is a total order by the sequence below.

---

## Implementation Sequence

**Stage 6 — serial, one branch, one pull request.** The order is the scope-lock's (D7 and its consequences), not the Stage-4 comment's.

| Slice | Content | Why here |
|---|---|---|
| **0** | Engineering Commit 0: this plan file, the tracked differential corpus fixture `core/hooks/tests/fixtures/walk-payload-corpus.txt` with its README entry, and the block-destructive suite's corpus reader (`WALKCORPUS-*`), every row recorded at the branch base's verdict | first commit by rule; the corpus is the exit bar every walk card shares, so it lands before the first walk card (scope-lock D2) |
| **1** | #7019 | leads with #7018: #7018's design measured its defect as a shipped regression in which an unlisted script executes, and its walk is designed against #7019's merged view |
| **2** | #7018 | same loop as #7019, strictly after it |
| **3** | #7020 | the wrapper walk, a different region of the same file |
| **4** | #7028 | the segmenter; lands after the walks so the differential attributes cleanly |
| **5** | #7004 | its own guard (`core/hooks/block-egress.sh`), independent under per-guard placement |
| **6** | #7027 | the filesystem-boundary guard's suite and readiness fragment only |
| **7** | #7026 | last: its evidence is re-measured on the branch after slices 1–4, and its operator gate is rendered before any phase constant changes |

**A2 container determination, recorded rather than assumed.** Every card's decomposition is multi-file and structure-changing, so the Phase A2 threshold predicate selects the **GitHub sub-issue container**; the per-card Stage-6 sub-tasks the hub scaffolded (#8169–#8175) are that container, and the change units of each slice are listed in its spoke's output and as checklist rows in the pull-request body. No further sub-issues are created.

**Change specifications (file-level; the design on each card's Stage-5 sub-task is the detailed specification, as the scope-lock amends it).**

- **#7019** (design on #8164; review on #8232) — Files: `core/hooks/block-destructive.sh` (two functions inserted above the shared subject rule `script_operand_implicated`; the flag walk's two `normalize_script_token` call sites become `script_walk_view` calls; five comment blocks reconciled), `core/hooks/tests/block-destructive.test.sh` (three `NOEXEC-QSPLIT` pins flip, two mutant arms re-pointed to a fragment, the `FWALK-QWORD-*` block and one late arm added), `core/rules/bypass-mode-readiness/block-destructive.md` (the never-skipped clause restated for a fragment at two sites, the residual entry restated, limit 3 extended, a new scope-list item), the regenerated registry, and the corpus rows this slice moves. Change: a flag token that opens with a quote and closes every quote it opens is read as its unquoted spelling; a fragment still ends the walk and is never advanced past; a whole word whose value argv does not determine is never read as a flag. The scanner reports an unquoted brace, glob or tilde character as an unknown value (the review's arm). Complexity: High — the shared traversal. Depends on: slice 0.
- **#7018** (design on #8165; review on #8233) — Files: the same hook (the option-run latch and its helpers, the command-string cluster table, and the conservative route for an option the walk cannot read), the suite, the fragment, the regenerated registry. Change: as its design specifies under the scope-lock — the latch with the recommended scope answer, the cluster fold, and the class of raw-led quote- or backslash-bearing flags assigned to it. Complexity: Medium–High. Depends on: slice 1 (same loop; it anchors on the merged view, not on the design's emulation).
- **#7020** (design on #8163; review on #8231) — Files: the same hook (the wrapper walk and one function block for the whole set; the conditional-keywords line), the suite (the parity arm `WRAPVOCAB-PARITY` reads every copy), the fragment, the regenerated registry, and its decision record. Change: the whole wrapper set gains option handling, `nice` and `stdbuf` join it, and the quoted-assignment-value gap is declared with its fix routed to its own card. Complexity: Medium (re-sized at the scope-lock). Depends on: nothing beyond serialization.
- **#7028** (design on #8166; review on #8234) — Files: the same hook (the close branch and the phased delta), the suite, the fragment (its `:39`, `:123`, `:143`, `:155` and the phased paragraphs), the regenerated registry, its decision record, `core/deploy/deploy.sh` (Check 71 gains the third phased family) and `core/rules/bypass-mode-readiness/_cross-cutting.md`. Change: the enclosure fail-open is closed at the warn phase, with the two adjacent fail-opens its design found and the review's correction; a later graduation decision is owed. Complexity: High — the segmentation layer feeds every arm. Depends on: nothing beyond serialization.
- **#7004** (design on #8162; review on #8230) — Files: `core/hooks/block-egress.sh`, `core/hooks/tests/block-egress.test.sh`, `core/rules/bypass-mode-readiness/block-egress.md`, the regenerated registry, and its decision record. Change: the secondary locator finds `gh api` behind a prefix command's option or operand and evaluates it at the rule's current rollout phase, its look-ahead records distinguishable from records of real invocations. Complexity: Medium. Depends on: nothing.
- **#7027** (design on #8167; review on #8235) — Files: `core/hooks/tests/block-fs-boundary.test.sh`, `core/rules/bypass-mode-readiness/block-fs-boundary.md`, the regenerated registry. Change: the operator family is declared out of scope, pinned, and the guard's coverage claim corrected. Complexity: Low. Depends on: nothing.
- **#7026** (design on #8168; review on #8236) — Files: the fragment's rollout paragraphs, the suite's `ROLLOUT-DOC-*` arms, the regenerated registry; conditional on its gate: the two phase constants and their comment records in the hook, `core/deploy/deploy.sh`, the script-execution allowlist, the ADR on execution capability, and two comment-only files. Change: evidence re-measured on the branch, the decision recorded, the stale arming date corrected. Complexity: Low to build, EXPENSIVE to decide. Depends on: E1–E4.

---

## Stage Applicability Matrix

Stage 5 activation, per `core/standards/planning-solutioning-handoff.md` § 3 (logical OR, all-or-nothing) — transcribed from Stage 4; Stage 5 ran for all seven.

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict |
|---|---|---|---|---|---|---|---|
| #7004 | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE |
| #7020 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE |
| #7018 | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ | ACTIVATE |
| #7019 | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ | ACTIVATE |
| #7027 | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ | ACTIVATE |
| #7028 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE |
| #7026 | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ACTIVATE |

| Issue | 5 | 6 | 7 | 8 | 9 | 10–11 | 12 | 13 | Note |
|---|---|---|---|---|---|---|---|---|---|
| #7004, #7020, #7018, #7019, #7027, #7028 | ✓ | ✓ | ✓ | ✓ | release | compressed | release | release | Stages 7 and 8 run as scaffolded stages; each card changes guard behaviour or its declared coverage |
| #7026 | ✓ | ✓ | ✓ | ✓ | release | compressed | release | release | Stage 6 holds at an operator decision gate before any constant changes |

Stages 10–11 compress for a git-native release. Stage 12 carries an operator-instance limb: the merged hooks reach an instance only when the publisher runs, and the release gate E8 is observed there.

---

## File Change Matrix

One path per line, verb after the path. Every conditional row whose condition resolved before Commit 0 is promoted or removed here, with its basis in § Deviation Log.

```
# ── Engineering Commit 0 (slice 0) ──
release/releases/plans/hook-walk-adjudicates-every-operand_RELEASE_PLAN.md  ADD
core/hooks/tests/fixtures/walk-payload-corpus.txt  ADD
core/hooks/tests/fixtures/README.md  EDIT
core/hooks/tests/block-destructive.test.sh  EDIT
# ── block-destructive: #7019, #7018, #7020, #7028, #7026 (slices 1-4 and 7) ──
core/hooks/block-destructive.sh  EDIT
core/hooks/tests/block-destructive.test.sh  EDIT
core/rules/bypass-mode-readiness/block-destructive.md  EDIT
core/rules/bypass-mode-readiness.md  EDIT
# ── #7020 decision record (its slice; subject-add fired with scope-lock D4) ──
core/ADRs/ADR-<N>-script-wrapper-walk-reads-option-grammar-from-rows.md  ADD
# ── #7028 phased delta and decision record (its slice; scope-lock D5) ──
core/ADRs/ADR-<N>-enclosure-positions-are-adjudicated-by-a-second-view.md  ADD
core/deploy/deploy.sh  EDIT
core/rules/bypass-mode-readiness/_cross-cutting.md  EDIT
# ── block-egress: #7004 (slice 5) ──
core/hooks/block-egress.sh  EDIT
core/hooks/tests/block-egress.test.sh  EDIT
core/rules/bypass-mode-readiness/block-egress.md  EDIT
core/ADRs/ADR-<N>-egress-prefix-walk-stops-on-the-gated-verb.md  ADD
# ── block-fs-boundary: #7027 (slice 6; suite and fragment only, scope-lock D6) ──
core/hooks/tests/block-fs-boundary.test.sh  EDIT
core/rules/bypass-mode-readiness/block-fs-boundary.md  EDIT
# ── conditional: #7026, rendered at its own gate (Q6) ──
core/config/allowlists/script-execution-allowlist.txt  EDIT  CONDITIONAL:interpreter-arm-graduates
core/ADRs/ADR-150-block-destructive-022-governs-execution-capability.md  EDIT  CONDITIONAL:decision-recorded-in-the-adr
release/tools/check-selftest-coverage.py  EDIT  CONDITIONAL:first-non-shell-row-lands
.github/workflows/release-tooling-smoke.yml  EDIT  CONDITIONAL:first-non-shell-row-lands
```

#### Read-only inputs

```
core/hooks/lib/command-position.awk  READ
core/ADRs/ADR-187-command-position-is-a-canonicalizer-not-a-parser.md  READ
core/standards/progressive-rollout-convention.md  READ
core/deploy/tools/build-hook-registry.py  READ
core/hooks/tests/setup-ci-layout.sh  READ
```

#### Release-wide explicit non-scope

```
core/hooks/block-fs-boundary.sh  NOT EDITED
core/hooks/block-rm-prefer-trash.sh  NOT EDITED
core/hooks/tests/command-position-fp-control.test.sh  NOT EDITED
.github/workflows/install-tests.yml  NOT EDITED
docs/scripts/setup-workspace.sh  NOT EDITED
core/deploy/tests/test_refresh_hooks.sh  NOT EDITED
core/hooks/tests/hook-fail-closed.test.sh  NOT EDITED
```

Notes that bind the matrix:

- `core/rules/bypass-mode-readiness.md` is **generated** from the per-hook fragments by `core/deploy/tools/build-hook-registry.py`; every slice regenerates it and none hand-edits it. Deploy Check 38 (always-enforce) fails a stale copy.
- **The corpus is read through the layout's existing pointer, so the layout helper is not edited.** The suite resolves the fixture beside itself in a source-tree run, through the `.source-repo-root` pointer `core/hooks/tests/setup-ci-layout.sh` already writes beside the materialized tests (the CI sandbox), and through the repository root above a default-site layout; an unresolved corpus is a FAIL. The helper therefore moves to the read-only inputs (DEV-06).
- **The three decision records are authored in their own cards' slices**, numbered at authorship with `release/tools/renumber-adr.py --detect`; record numbers are contested the way the version slot is (R-12), and the sibling release `controls-fail-loud` adds two of its own. Their designs place them at Engineering Commit 0; DEV-05 records why this commit carries their rows rather than their files.
- No file is renamed or deleted; the release's mover set is empty. The shared wrapper library the Stage-4 matrix carried conditionally is never created (per-guard placement), and the three publishing and test sites it would have registered in stay in the non-scope block.
- No new executable script is introduced, so no script-execution allowlist row is owed by any unconditional row; the corpus is data, read by an existing suite.

---

## Agent-Editability Read

**Derivation** — controls read at commit `4babbba9` by the Stage-4 plan, and re-read unchanged at the Commit-0 base `20197085` (no commit between the two touches either control file):

- Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh` — `case "$ABS_TARGET"` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: **2 block(s) observed**. Arms, verbatim:

```
block 1 (:725-:741), anchored
"${PRIMARY_ROOT}/CLAUDE.md"
"${PRIMARY_ROOT}/projects/CLAUDE.md"
"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"
"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"
"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"
"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"
"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"
"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"
"${PRIMARY_ROOT}/.claude/settings.json"
"${PRIMARY_ROOT}/.claude/hooks/"*
"${PRIMARY_ROOT}/.claude/rules/"*
block 2 (:770-:783), repository-membership (worktree test)
*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md
```

- Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`; arming key = `skill_discipline_migrated_v10_2: true`; exemption list — **undetermined** (not read; no write-set path reaches conjunct 1, so the unread conjunct decides nothing here).

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| all | `release/releases/plans/hook-walk-adjudicates-every-operand_RELEASE_PLAN.md` | no | no (conjunct 1 false) | unconstrained | — | ordinary Engineering spoke |
| #7019 (Commit 0), #7018, #7020 | `core/hooks/tests/fixtures/walk-payload-corpus.txt` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke — added by the Collective Review's D2; the hub's reading of 2026-10-15, which the hub carried unchanged into the #7018 and #7020 briefs |
| #7019 (Commit 0), #7018 | `core/hooks/tests/fixtures/README.md` | no | no (conjunct 1) | unconstrained | | ordinary Engineering spoke — the same reading, by the Commit-0 spoke; #7018's slice extends the row contract (DEV-17) |
| #7020, #7018, #7019, #7028, #7026 | `core/hooks/block-destructive.sh` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| same five | `core/hooks/tests/block-destructive.test.sh` | no | no (conjunct 1) | unconstrained | | ordinary Engineering spoke |
| same five | `core/rules/bypass-mode-readiness/block-destructive.md` | no | no (conjunct 1) | unconstrained | | ordinary Engineering spoke |
| #7020, #7028, #7004 | `core/ADRs/ADR-<N>-<slug>.md` (three new records) | no | no (conjunct 1) | unconstrained | | ordinary Engineering spoke — read by this spoke at Commit 0 |
| #7028 | `core/deploy/deploy.sh`, `core/rules/bypass-mode-readiness/_cross-cutting.md` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke — read by this spoke at Commit 0 (the `.claude/rules/` arm names the workspace root's deployed mirror, not `core/rules/`) |
| #7004 | `core/hooks/block-egress.sh`, its suite, its fragment | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #7027 | `core/hooks/tests/block-fs-boundary.test.sh`, `core/rules/bypass-mode-readiness/block-fs-boundary.md` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| all | `core/rules/bypass-mode-readiness.md` | no | no | generated — class of its sources: unconstrained | | produced by the generator, not by a Write or Edit payload |
| #7026 | the conditional rows above | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |

All rows read `unconstrained`: no control refuses these writes from an Engineering worktree. That is not a statement that they are ungoverned — every one is a security-control change under "No ungoverned changes", approved through this plan and its pull request. The decision-record rows and #7028's two promoted rows change those cards' write sets after their sub-tasks were stamped; the reading above is this spoke's, and the hub's own currency determination for those three briefs is still owed before they launch (Procedure 4, **Editability currency**).

---

## Contention Map

| File | Issues | Intent mix | Severity | Recommendation |
|---|---|---|---|---|
| `core/hooks/block-destructive.sh` | #7019, #7018, #7020, #7028, #7026 (conditional) | edit × 5 | MULTI-WAY | serial slices in the sequence order. Regions: the flag walk `:2576-:2921` (#7019, then #7018 — the same loop, line-range overlap); the wrapper walk `:2208-:2228` (#7020); the splitter and its comment (#7028); the phase constants (#7026) |
| `core/hooks/tests/block-destructive.test.sh` | Commit 0, #7019, #7018, #7020, #7028, #7026 | edit × 6 | MULTI-WAY | mostly appended blocks; #7019 flips three pins and re-points two mutant arms; the corpus reader sits directly above the suite summary, so a later block appended "above the summary" lands after it |
| `core/rules/bypass-mode-readiness/block-destructive.md` | #7019, #7018, #7020, #7028, #7026 | edit × 5 | MULTI-WAY | each paragraph is one physical line; #7019 appends scope-list item 9 and #7018 numbers its item after it; item 8 is reconciled by #7018's slice, not #7019's |
| `core/rules/bypass-mode-readiness.md` | all seven | regenerate × 7 | MULTI-WAY | regenerated in every slice; a conflict is settled by regenerating, never by hand-merging |
| `core/hooks/tests/fixtures/walk-payload-corpus.txt` | Commit 0, then every walk card | edit × 6 | MULTI-WAY | append-pattern: each slice appends its rows and updates only the verdicts its change moves |
| `core/deploy/deploy.sh` | #7028, #7026 (conditional) | edit × 2 | BINARY | serial; also edited by the in-flight sibling `controls-fail-loud` — the second to merge rebases (R-11) |
| `core/hooks/block-egress.sh`, its suite, its fragment | #7004 | edit × 1 | NONE | independent lane |
| `core/hooks/tests/block-fs-boundary.test.sh`, its fragment | #7027 | edit × 1 | NONE | independent lane |

No CONFLICT-severity row: no card deletes a file.

---

## Cross-PR Overlap Audit

### Baseline SHA

`4babbba94f3ddf99a658d39fc0dbb7af0f664066` — the Stage-4 audit start, 2026-10-08T23:47:34Z. Baseline-pinned: a sibling that pushes after that instant is invisible to the Stage-4 audit and is caught at Stage 9 Phase A6.5 / A6.6.

**Commit-0 base:** `201970851da959db01111ef155f2f96d6676bfeb`, 61 commits after the pin. None of them touches the hook, suite, fragment, registry or fixture directory this slice edits (probe in § Verification Evidence), so the Stage-4 line anchors cited by the designs hold at the Commit-0 base.

### In-Flight Release Roster

**Measured at:** `20197085` · `2026-10-15T21:40Z` · **Population:** n=1 sibling (open pull requests with a `release/*` head, drafts included; remote `release/*` heads with no pull request: none)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `controls-fail-loud` | `#7919` | `57924bb9` | `minor` | `v4.70` | `v4.75` | `core/deploy/deploy.sh` (#7028's promoted row); `core/config/allowlists/script-execution-allowlist.txt` (#7026's conditional row) |

`telemetry-is-computable`, on the Stage-4 roster, merged and claimed `v4.74`. This roster is a pinned measurement and carries no verdict. The sibling also adds a hook suite under `core/hooks/tests/` and edits a file under `core/hooks/testdata/`; neither path is in this matrix, and the corpus was placed in `core/hooks/tests/fixtures/` so that it cannot collide with them. When that pull request merges, the runner's suite count moves by its own suite, not by this release's arms.

### Structural sub-audit

This release's mover set is empty (no rename, no delete). Its surface is the version-slot token `Δversion/minor-after-v4.74`, plus decision-record slots in three slices. The one in-flight sibling contributes the same version token: **one Tier-S serialization edge** — whichever release merges first takes the slot and the other recomputes at its own claim.

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R-1 | A scope or placement question surfaces mid-build and re-orders slices | Low after the scope-lock | High | every Q1–Q9 question is rendered; a new one is raised as an inter-stage finding, not decided in a slice | Hub / operator |
| R-2 | #7019's fix re-opens the failure the fragment records as measured (the never-advance-past clause, which #7019's slice restates for a fragment) | Low | High | the walk reads a whole quote-led word only; a fragment still ends the walk; binding controls `F1-QTOK-RESIDUAL-space`, `F1-FP-cmode`, `NOEXEC-ORD-*`; CIAC-2 and CIAC-3 | #7019 slice |
| R-3 | #7027 is built against the wrong guard | **Closed** at the Stage-4 gate (D2) | — | — | — |
| R-4 | #7004 graded NOT MET because AC-1 asks for a block the shadow phase cannot give | **Closed** — AC-1 corrected at Stage 4 (D3) | — | — | — |
| R-5 | Over-blocking: a changed walk refuses legitimate work on a guard that sees every Bash call | Medium | High | must-not-flag near misses per card; the corpus records every verdict, so an added refusal is a reviewed diff; #7028 enters at the warn phase (D5) | Stage 6/7 |
| R-6 | The differential has no tracked corpus | **Closed** — scope-lock D2; slice 0 lands the corpus and its reader | — | — | — |
| R-7 | A shared library ships with a missed registration site | **Void** — per-guard placement | — | — | — |
| R-8 | Graduation mechanics misread (retreating to `shadow` does not turn Check 71 green; the exec arm has used its one re-date; `enforce` on the interpreter arm refuses every tracked Python tool) | Medium | High | #7026's decision package states each option's mechanical form; decided last, by the operator, on evidence re-measured on the branch | Operator |
| R-9 | The release has not merged when Check 71 warns (2026-11-02, Mon) or fails (2026-12-02, Wed) | Unknown | Medium | the decision record ships in this pull request; the operator can record it on its own earlier | Operator |
| R-10 | Version slot `v4.75` is taken by the sibling before this release claims | High | Low | recorded determination; the Stage-12 atomic claim recomputes | Hub |
| R-11 | Cross-PR contention on `core/deploy/deploy.sh` (now an unconditional row) or the allowlist | Medium | Low | the second merger rebases; line-range check at #7028's slice; Stage 9 A6.5 / A6.6 | Hub |
| R-12 | Decision-record numbers collide (three in this release, two in the sibling) | Medium | Low | number at authorship with `renumber-adr.py --detect`; renumber at sync with the repository's own tool | each slice |
| R-13 | Quota: other release sessions share the usage window | High | Medium | serial Stage 6; Checkpoint B at every launch | Hub |
| R-14 | An Engineering spoke's own Bash calls run under the deployed pre-fix hooks, which scan heredoc bodies; a suite run outside the runner reads hundreds of false failures | High | Medium | author arms with the Write and Edit tools; build the layout with `bash core/hooks/tests/setup-ci-layout.sh`; run only `bash .claude/hooks/tests/test-runner.sh`; never set the scope-guard variable by hand | Hub (Procedure 3) |
| R-15 | Host shells differ (reference host bash 3.2 and zsh 5.9; CI on `macos-latest`) | Medium | Medium | arms assert the hook's lexical verdict, which is host-independent; the corpus records ground truth taken when a row was authored and never re-runs it | Stage 5/7 |
| R-16 | Rollback re-opens every closed escape and resets any graduated phase | Low | Medium | § Rollback Strategy; per-card commits allow a partial revert | Operator |
| R-17 | The corpus reader lengthens the hook suite's run on every pull request | Certain | Low | one hermetic copy, each row run once and only recorded refusals through the mutant; the cost is measured and recorded in § Verification Evidence | each walk slice |

---

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#7004 × #7020 on the wrapper vocabulary held by `core/hooks/block-destructive.sh`, `core/hooks/block-egress.sh` and `core/hooks/lib/command-position.awk`):** the suite carries an arm that fails when the wrapper word lists of the two guards and the canonicalizer differ without a declared reason. *Method:* `grep -c -F "WRAPVOCAB-PARITY" core/hooks/tests/block-destructive.test.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#7018 × #7019 on the flag walk's break-and-revoke ordering in `core/hooks/block-destructive.sh`):** both walk changes land with every ordering pin still present. *Method:* `grep -c -F "NOEXEC-ORD" core/hooks/tests/block-destructive.test.sh` at least 10. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#7018 × #7019 on the space-bearing-operand pin that the never-advance-past clause rests on — "a fragment is never advanced past", as #7019's slice restates it):** the pin survives both walk changes, kept or deliberately flipped, never deleted. *Method:* `grep -c -F "F1-QTOK-RESIDUAL-space" core/hooks/tests/block-destructive.test.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#7020 × #7018 × #7019 × #7028 × #7026 on the readiness fragment and its generated registry):** every disposition those five cards record in the block-destructive fragment is carried, unchanged, by the regenerated registry. *Method:* declared, verification deferred to core/rules/bypass-mode-readiness.md *Graded at Stage 9 QC3.5 on the merged PR.*

Transcribed from the Stage-4 plan, with one wording change: CIAC-3 names the never-advance-past clause as #7019's slice restates it (DEV-13); its method is unchanged. The lint record (gate criterion G4-06) taken on this committed file is in § Verification Evidence.

---

## Verification Plan

### Per-Issue Verification

Method classes: a runnable probe where one exists; a named read of a named surface; or the declared-deferred form where the grading arm belongs to a later slice. Suite-graded rows are executed by the documented runner at Stage 7 and by the hook-suite CI job, not by the plan verifier. **#7019's rows are converted to label-presence probes at Commit 0**, as the Stage-4 plan prescribed once Stage 5 named the arms; every other card's deferred rows are bound to label-presence probes by that card's own slice.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7020 | AC-1 | `grep -c -w -F stdbuf core/rules/bypass-mode-readiness/block-destructive.md` at least 1 | the fragment names the word (0 lines at the Commit-0 base); scope-list item 2 states the answer — both words in the walked set, with their options, and the whole set's options walked |
| #7020 | AC-2 | `grep -c -F "WRAPOPT-AC2" core/hooks/tests/block-destructive.test.sh` at least 3 | `nice -n 10 bash <unlisted>.sh` and `stdbuf -o0 bash <unlisted>.sh` refused (`WRAPOPT-AC2-nice`, `WRAPOPT-AC2-stdbuf`), the separate spelling `stdbuf -o 0` refused (`WRAPOPT-stdbuf-o-sep`), the allowlisted near miss allowed (`WRAPOPT-AC2-near`); the suite's CI run grades them; the fresh-session probe is owed at Stage 12 |
| #7020 | AC-3 | [DEFERRED — the exclusion criterion has no subject under D4; graded at Stage 8 on the rendered decision] | no exclusion pin owed |
| #7020 | AC-4 | `grep -c -F "WRAPVOCAB-PARITY" core/hooks/tests/block-destructive.test.sh` at least 1 | the parity arms cover all four lists of the vocabulary in both directions; the fragment's prefix-run paragraph states each list's match form and grammar |
| #7020 | AC-5 | `grep -c -F "M-WRAP-" core/hooks/tests/block-destructive.test.sh` at least 1 | the reverse mutant's marker expressions are present (`WRAPOPT-M0` pins its difference); the red run on the pre-fix hook is recorded in § Verification Evidence, graded by arm class |
| #7020 | AC-6 | `grep -c -F "WR152" core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 1 | the card's rows are in the corpus (block `seed 6`, which carries the rows of tables M-1 to M-3 of the adversarial review); the suite's CI run grades every group, and no row moves toward allow against the pre-fix hook except the declared precision group `wrap-prec` · control: `WALKCORPUS-DET-fires` reports a non-zero count on the operand-walk mutant |
| #7020 | AC-7 | [DEFERRED — runner .claude/hooks/tests/test-runner.sh at Stage 7 and in CI] | FAIL=0; PASS at or above the floor in § Verification Evidence plus the slice's arms |
| #7018 | AC-1 | Named read: the enumerated scope list of the block-destructive fragment carries an item stating the stdin-mode disposition and naming arm PARSE-12c | disposition stated |
| #7018 | AC-2 | `grep -c -F "NOEXEC-TERM-ctl-word" core/hooks/tests/block-destructive.test.sh` at least 1 | the card's line without a script-suffixed word is pinned allowed, as at 9038e2c6; the suite's CI run grades `NOEXEC-TERM-01` and `-02`, the script-suffixed forms, refused as at 9038e2c6 |
| #7018 | AC-3 | `grep -c -F "STDIN-ctl-0" core/hooks/tests/block-destructive.test.sh` at least 4 | the must-not-flag stdin arms are present; the red run on the pre-fix hook is recorded in § Verification Evidence, graded by arm class as the card's corrected criterion states |
| #7018 | AC-4 | `grep -c -F "STDIN-PIN-0" core/hooks/tests/block-destructive.test.sh` at least 3 | the rendered scope answer leaves the program on stdin outside the rule's reach and pins it; `STDIN-M1*` pin why a stdin-fed shell is not refused |
| #7018 | AC-5 | `grep -c -F "ZS13" core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 1 | the card's rows are in the corpus (block `seed 5`); the suite's CI run grades every group, and no row moves toward allow · control: `WALKCORPUS-DET-fires` reports a non-zero count on the operand-walk mutant |
| #7018 | AC-6 | [DEFERRED — runner, as #7020 AC-7] | as #7020 AC-7 |
| #7019 | AC-1 | `grep -c -F "FWALK-QWORD-ctl-allow" core/hooks/tests/block-destructive.test.sh` at least 1 | the near-miss arm is present; the suite's CI run grades the family arms (NOEXEC-QSPLIT-01 to -05 and FWALK-QWORD-*) and the corpus groups fam-x, fam-n and near |
| #7019 | AC-2 | `grep -c -F "NOEXEC-ORD" core/hooks/tests/block-destructive.test.sh` at least 10 | ordering pins intact (10 at the Commit-0 base) |
| #7019 | AC-3 | `grep -c -F "FWALK-QWORD-M1" core/hooks/tests/block-destructive.test.sh` at least 5 | the revert mutant's liveness arm and its four red-before arms are present; the red run on the pre-fix hook is recorded in § Verification Evidence |
| #7019 | AC-4 | `grep -c -F "WALKCORPUS-DET-fires" core/hooks/tests/block-destructive.test.sh` at least 1 | the corpus detector arm is present; the suite's CI run grades every corpus group |
| #7019 | AC-5 | `grep -c -F "closed for a whole word" core/rules/bypass-mode-readiness/block-destructive.md` at least 2 | the residual entry and the scope list both state the disposition |
| #7019 | AC-6 | [DEFERRED — runner .claude/hooks/tests/test-runner.sh at Stage 7 and in CI] | FAIL=0; PASS at or above the Commit-0 floor plus this slice's arms |
| #7027 | AC-1 | Named read: the coverage statement of core/rules/bypass-mode-readiness/block-fs-boundary.md states the transformation-operator disposition | disposition stated on the corrected surface |
| #7027 | AC-2 | [DEFERRED — hook-verdict pin arm in core/hooks/tests/block-fs-boundary.test.sh under D6, bound at #7027's slice; the execution-semantics demonstration is NOT-EVALUATED on a shell that rejects the operator] | quoted and unquoted forms pinned |
| #7027 | AC-3 | [DEFERRED — near-miss arms in the same suite, bound at #7027's slice] | 0 refusals on the near misses · control: the quoted-brace arm AC-5 (G1) still refuses |
| #7027 | AC-4 | [DEFERRED — red-before where the slice adds a refusal; pins otherwise] | as declared at the slice |
| #7027 | AC-5 | [DEFERRED — pinning arm under D6] | pin present |
| #7027 | AC-6 | [DEFERRED — runner] | as #7020 AC-7 |
| #7028 | AC-1 | [DEFERRED — measured shape set recorded by the Stage-5 design; arms in core/hooks/tests/block-destructive.test.sh bound at #7028's slice] | each shape carries a verdict and a control |
| #7028 | AC-2 | [DEFERRED — close branch at the warn phase (D5); would-fire arms bound at #7028's slice] | the shapes are adjudicated at the warn phase |
| #7028 | AC-3 | `grep -c -F "tracked separately" core/rules/bypass-mode-readiness/block-destructive.md` expect 0 | null · control: `grep -c -F "command-substitution" core/rules/bypass-mode-readiness/block-destructive.md` → 3 at the Commit-0 base. The registry keeps one unrelated occurrence |
| #7028 | AC-4 | [DEFERRED — red-before at #7028's slice] | red before, green after |
| #7028 | AC-5 | [DEFERRED — the corpus, graded by WALKCORPUS-* in CI; #7028's slice adds its rows; near-miss arm] | as #7018 AC-5; 0 refusals on the near miss |
| #7028 | AC-6 | [DEFERRED — runner] | as #7020 AC-7 |
| #7026 | AC-1 | Named read: the rollout paragraphs of the block-destructive fragment record a dated decision per arm | recorded before 2026-12-02 (Wed) |
| #7026 | AC-2 | [DEFERRED — conditional on Q6 = graduate; evidence re-measured at #7026's slice] | residual stated as measured, or acceptance recorded |
| #7026 | AC-3 | Named read: the same paragraphs name the next review point when the decision defers | a date, not an open hold |
| #7026 | AC-4 | `grep -c -F "2026-08-24" core/rules/bypass-mode-readiness/block-destructive.md` expect 0 | null · control: `grep -c -F "DESTRUCTIVE_022_EXEC_ARMED" core/rules/bypass-mode-readiness/block-destructive.md` → 1 at the Commit-0 base |
| #7026 | AC-5 | Named read: the decision record cites measurements taken on the release branch after the last functional hook commit | evidence post-dates slices 1–4 |
| #7026 | AC-6 | [DEFERRED — conditional on Q6 = graduate; arms T-EXEC-1 and T-NSI-01a re-pointed, then a fresh-session probe at Stage 12] | refused per graduated arm; decision-record branches exempt |
| #7004 | AC-1 | [DEFERRED — shadow-form arms in core/hooks/tests/block-egress.test.sh, bound at #7004's slice: the option-bearing shape and its no-option wrapper control write the same record; a sandboxed enforce copy refuses] | evaluated, recorded, refused under enforce · control: the plain form still refuses |
| #7004 | AC-2 | [DEFERRED — one arm per measured option and operand, plus a synthetic unlisted option] | every arm locates the gated verb |
| #7004 | AC-3 | [DEFERRED — red-before at #7004's slice] | red before, green after |
| #7004 | AC-4 | [DEFERRED — the corpus, with block-egress rows and a reader in core/hooks/tests/block-egress.test.sh added by #7004's slice] | as #7018 AC-5 |
| #7004 | AC-5 | [DEFERRED — runner] | as #7020 AC-7 |

**AC baseline** — criterion counts read from the issue bodies at their 2026-09-27 revisions, against the Stage-4 pin. The card bodies are being corrected before Stage 7 under the scope-lock's last bullet; a count that no longer matches this line is the mechanical signal to re-bind the affected rows.

`ac_baseline: { #7020: 6, #7018: 6, #7019: 6, #7027: 6, #7028: 6, #7026: 6, #7004: 5, read_at: 4babbba94f3ddf99a658d39fc0dbb7af0f664066 }`

**#7019's criteria are built to the design's corrected reading.** AC-1 is graded as amended by the design's AC1-a, with the review's one-directional qualifier: each quote-led spelling is refused wherever its unquoted twin is refused and the interpreter executes the script, the near miss stays allowed, and four rows are stricter than their twin (the corpus's `G12`, `H11`, `H12`, `H13`). AC-3 is graded by arm class: a refusal this slice introduces is red on the pre-fix hook; a must-stay-allowed control or pin is shown able to fail by a mutant of the fixed hook; a mutant's own liveness or payload arm is red before only because its instrument does not exist yet, and is not red-before evidence.

**#7018's criteria are graded on the card's corrected text,** which the corrections pass applied to the card body on 2026-10-15 under the design's wording gate: AC-1 records that termination alone keeps arm `PARSE-12c`, AC-2 names the script-suffixed forms (the two lines without such a word are allowed at both commits), and AC-3 is graded by arm class in the same way as #7019's. The scope answer the Collective Review locked is the design's recommended one: the command line of a stdin-mode invocation is walked as any other, and the program that arrives on the pipe is declared outside the rule's reach.

**#7020's criteria are now seven, and its rows are re-bound to them.** The corrections pass of 2026-10-15 added the adversarial review's differential criterion as the card's sixth, so the AC baseline's count for #7020 (six) no longer matches the card: AC-6 is bound to the corpus and the runner row moves to AC-7, and the rows of the other cards that pointed at the runner row are re-pointed in the same change (DEV-30). AC-2 is graded on the card's corrected text, which names the separate spelling `stdbuf -o 0` and records the Collective Review's answer — `nice` and `stdbuf` added, with options walked for the whole wrapper set. AC-5 is graded by arm class, as #7019's and #7018's are: a refusal this slice introduces is red on the pre-fix hook, and a pin or control is green before by design.

### Release-Level Verification

- [ ] File integrity: the delivered diff matches the unconditional matrix rows; each fired conditional row is promoted in its slice.
- [ ] Hook suites: `test-runner.sh` aggregate `FAIL=0`.
- [ ] Registry freshness: deploy Check 38 passes on the release head.
- [ ] Cross-issue criteria CIAC-1 to CIAC-4.
- [ ] The corpus: every `WALKCORPUS-*` arm green on the release head, its identity line recorded at Stage 7 and Stage 9.
- [ ] Instance verification at Stage 12: after the publisher runs, the deployed copies of every edited hook are byte-identical to the merged sources, then the fresh-session probes run.

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential, dependency- and contention-ordered (posture P0) |
| **Commit strategy** | Engineering Commit 0 (plan and corpus), then one run of commits per card: the red arms ahead of the fix, the fix, then the readiness text and the regenerated registry |
| **Review approach** | Single pull request for the milestone (topology SINGLE), draft until the Stage 9 gate |
| **Deployment mechanism** | Git merge, then the hook publisher refreshes the instance's hook bundle; no skill package changes |
| **Stacked-base cleanup posture** | Not applicable — no stacked branches under SINGLE |

---

## Rollback Strategy

**Per issue.** Each card is its own run of commits on a linear branch, so one card reverts with `git revert` of its commits. A revert of #7019 or #7018 restores the pins that card flipped and the corpus verdicts it moved; a revert of #7028 restores the "tracked separately" wording.

| Path | When | Steps |
|---|---|---|
| Partial revert | one card misbehaves after merge | revert that card's commits on a fix branch; republish hooks; re-run the suites |
| Full restore | a refusal storm or a fail-closed loop on an instance | revert the merge commit; republish hooks; confirm by hash that the deployed copies equal the reverted sources. The version tag stays — it is never deleted |
| Forward fix | a narrow, understood defect | a fix branch through the pipeline |

What a rollback costs, stated plainly: every escape this release closes re-opens, and a graduated phase constant returns to `warn`, restarting Check 71's clock against the original arming date — so a rollback after a graduation needs its own recorded decision. Reversibility: MODERATE for the walk changes (a revert plus a republish); EXPENSIVE for a graduation, per #7026.

---

## Quota Budget

**Verdict:** WARN (per `quota-budget-protocol.md` Checkpoint A, carried from Stage 4)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 7 · Stage 7: 7 · Stage 8: 7
**Per-spoke cost estimate:** ordinal band by size — 2 × `size:S` (lowest), 5 × `size:M` (low–moderate) (source: heuristic; no per-bucket telemetry median was consulted)
**Assumed/stated remaining usage-window envelope:** as stated by the hub at Stage 4; the share available to this release was `UNSTATED`
**Estimated cumulative draw % (worst parallel batch):** about 35 % of a window for seven design spokes [ASSUMPTION – CONFIRM — a projection, not a measurement]
**Routing:** WARN: window-aware timing plus a split batch; Stage 6 is serial and does not batch (scope-lock D7 starts it ahead of the weekly budget)
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API quota, which this plan-time estimate deliberately does not read. Bands and the cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**Class: `novel`** — trigger (b), at least one D-class decision in the plan (the placement, the walk option, the differential's home, the rollout, the graduation), and trigger (c), Stage-5 decision records (three slices author one). Confirmed at the Stage-4 gate. Posture: engagement density Standard · Stage 9 review depth **Deep** · Stage 5 activation bias ALL · Stage 13 outcome window 30-day. **Named tripwire:** if a later decision moves the wrapper vocabulary into the canonicalizer, re-render to `cross-cutting`; that placement was not taken.

---

## Release Outcome Statement

> **AFTER:** The script-execution rule adjudicates the operand behind a transparent wrapper's own options, with `nice` and `stdbuf` either covered or declared; reads a stdin-mode invocation by where the interpreter stops parsing options, or declares that mode outside its subject; and no longer lets a flag token whose quote closes early strand the operand. The enclosure and grouping fail-open is measured and then refused or pinned. The filesystem-boundary guard's treatment of a parameter-transformation operator is decided and declared. The egress rule's prefix-command walk locates `gh api` behind a prefix command's option or operand (`env -u`, `xargs -I`, `timeout <duration>`, `nice -n`, `stdbuf -o`) and evaluates it at that rule's current rollout phase. The warn-to-enforce decision for the two phase-gated arms is recorded with evidence re-measured on the merged hook.
>
> **BEFORE:** Three pinned arms assert that the early-closing-quote family is allowed; a wrapper's own flags are a declared residual and two wrappers are undeclared; `env -u NAME gh api -X POST …` is not evaluated at all while `env gh api -X POST …` is evaluated in shadow; Check 71 warns from 2026-11-02 (Mon) and fails from 2026-12-02 (Wed) with no decision recorded. The v4.55 escape counts (50, of which 8 undeclared and 42 in one family) were not re-measured at planning.
>
> **Actor(s):** platform engineering session; the deployed hook bundle. **Success Indicator:** every member's acceptance signal verified at Stage 8 against its corrected criteria; one PR for the milestone; at Stage 12 the deployed copies of every edited hook equal the merged sources.

Approved at the Stage-4 gate. One clause is imprecise under scope-lock D5 (the enclosure fail-open is closed at the warn phase first), flagged for Stage 9; and the early-closing-quote clause is true of a whole word that opens with a quote — a quoted word that contains whitespace is the readiness doc's limit 3, which #7019 excludes, and a flag that begins with a sign or a backslash is #7018's.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | every edited hook under `core/hooks/` (`block-destructive.sh`, `block-egress.sh`) | the instance's deployed hook bundle under the workspace root's `.claude/hooks/` | the hook publisher (`docs/scripts/setup-workspace.sh --refresh-hooks`, which `update.sh` delegates to) | SHA-256 of each deployed copy equals the merged source (release gate E8), then the fresh-session probes |
| 2 | `core/rules/bypass-mode-readiness.md` | the deployed rules mirror | `deploy.sh --deploy` | `deploy.sh --check` Check 9 |

### Schema Migrations

N/A — enumerated over the schema surfaces (`core/schemas/`, the drain row, the block-log row, the corpus's own row format); none changes in a way a reader must migrate. #7028's close adds one key to a would-fire row written from a second-view position, which the count Check 71 reads does not consume.

---

## Deviation Log

| ID | Departure from the Stage-4 comment (or from a design) | Decision or authority that caused it | Status |
|---|---|---|---|
| **DEV-01** | The build order is the scope-lock's — Commit 0 with the corpus, then #7019, #7018, #7020, #7028, #7004, #7027, #7026 — not the Stage-4 sequence (which led with #7004 and #7020) | Scope-lock D7 and its consequences | **APPLIED** — § Implementation Sequence |
| **DEV-02** | The tracked differential corpus joins the matrix and lands at Commit 0 with its reader | Scope-lock D2 | **APPLIED** — § File Change Matrix |
| **DEV-03** | The conditional shared-library rows and their five registration rows leave the matrix; E5 and E6 are void; R-7 is void | Scope-lock: per-guard placement | **APPLIED** |
| **DEV-04** | `core/hooks/block-fs-boundary.sh` moves from a conditional row to the explicit non-scope block; #7027 writes no hook file | Scope-lock D6 | **APPLIED** |
| **DEV-05** | Three Stage-5 designs (#7004's, #7020's under subject-add, #7028's close branch) place a new decision record "at Engineering Commit 0". This commit carries their rows, under each card's own block, and not their files: each record is authored at the head of its own card's slice, by the spoke that builds it, numbered at authorship. Engineering Commit 0 is the plan file (Procedure 0 § Canonical location) and the corpus (D2); authoring three records for cards this spoke does not build would put decision text ahead of the reading of its own design. The decisions themselves are unchanged | This spoke, at Commit 0 — routed to the hub, which can redirect before slice 3 | **APPLIED** — rows in § File Change Matrix; flagged in the spoke output |
| **DEV-06** | #7019's design asked for one copy rule in `core/hooks/tests/setup-ci-layout.sh`. The suite instead resolves the corpus through the `.source-repo-root` pointer that helper already writes for exactly this case (a suite grading a tracked file from a sandbox), with the in-place rungs beside it; the helper is not edited | Reuse of an existing mechanism; this spoke at Commit 0 | **APPLIED** — § File Change Matrix notes |
| **DEV-07** | `core/deploy/deploy.sh` and `core/rules/bypass-mode-readiness/_cross-cutting.md` are promoted to unconditional rows for #7028: its phased delta edits Check 71's family list and the cross-cutting fragment | Scope-lock D5 (phased), which fired the Stage-4 conditional before Commit 0 | **APPLIED** |
| **DEV-08** | #7020's decision record is unconditional: its `subject-add` condition fired | Scope-lock D4 (whole wrapper set, which presupposes the add) | **APPLIED** |
| **DEV-09** | #7026's conditional rows are those its design refined (the allowlist, the execution-capability ADR, two comment-only files); its deploy.sh condition rides #7028's now-unconditional row | #7026's design on #8168; its gate unrendered | **APPLIED** |
| **DEV-10** | #7019's Verification Plan rows are converted to label-presence probes now; the other cards' deferred rows stay bound to their own slices. #7020 AC-3 and #7018 AC-4 restate their conditions as rendered | The Stage-4 plan's own instruction; scope-lock D4 and the #7018 bullet | **APPLIED** |
| **DEV-11** | The Phase A1–A2 checkpoint the Stage-6 spec places before B1 is presented after the fact, in the spoke's output: the hub's brief directs Commit 0, the draft pull request and #7019's slice end to end under the scope-lock | The hub's Stage-6 brief, under the operator's scope-lock | **RECORDED** |
| **DEV-12** | #8171's body labels this card "slice 2" (the Stage-4 numbering); under the scope-lock order it is slice 1 | Scope-lock D7 | **RECORDED** |
| **DEV-13** | R-2 and CIAC-3 quoted the readiness fragment's never-advance-past clause in its wording before this release, which stated it of every unresolvable token. #7019's slice restates that clause for a fragment, so both now name it by its subject and quote the restated wording; CIAC-3's method is unchanged | The scope-lock's #7019 bullet (a fragment still ends the walk), applied by the rename sweep at slice 1 | **APPLIED** — § Risk Register, § Cross-Issue Acceptance Criteria |
| **DEV-14** | The Header's PR cell said the pull-request number would be recorded by the first slice commit after it. That commit (#7019's red arms) carried the suite and the corpus only; the number is recorded by the slice-1 readiness-text commit instead | This spoke, at slice 1 | **RECORDED** |
| **DEV-15** | The template's `## Deployment Execution Log` section was missing at Commit 0; it is added at slice 1, empty until Stage 12, ahead of the `## Change Description` section that Stage 6 Phase C1 appends | Template usage rule 1 (every section present); RELEASE_PROTOCOL § Change Description Protocol (placement) | **APPLIED** |
| **DEV-16** | #7018's design adds the route helper `script_take_cmode_route` beside the quoted-word view, which already rewrote a quote-led word of unknown value to `-c` inline; the design's integration criterion INT-4 asks for one definition of that rewrite on the merged hook. Slice 2 moves the rewrite out of the view: the view now reports such a word by its raw spelling under every verb, and the design's top-of-loop line routes it, because that raw spelling opens with a quote and is never plain. No verdict moves with it — every `FWALK-QWORD-*` arm and every corpus row slice 1 recorded grade the same on the fixed hook. The fragment's paragraph on unreadable options says the route has one definition | The hub's slice-2 brief (one definition, no second) and INT-4 | **APPLIED** — `core/hooks/block-destructive.sh` |
| **DEV-17** | The corpus's closed ground-truth set gains two classes: `e`, another extensionless file in the fixture directory ran in the script's place, and `s`, a program fed on standard input ran and no script named on the command line did. They are added to the README's row contract, the reader's well-formedness check (`WALKCORPUS-ROWS`) and the corpus header. #7018's design measured both classes, and no existing class records either without stating something that did not happen. No existing row's meaning moves | This spoke, at slice 2 | **APPLIED** — `core/hooks/tests/fixtures/README.md`, `core/hooks/tests/block-destructive.test.sh`, the corpus header |
| **DEV-18** | Of #7018's design corpus of 374 payloads, 293 are appended as block `seed 5`, with ids `Z` plus the design's own id. 78 are not repeated because the same payload is already in the file, character for character — 66 under an earlier block's id (41 of them rows of block `seed 4`, which slice 1 took from the adversarial review and this design) and 12 under another of the design's own ids — and 3 need a newline, which the row format cannot carry. Their ground truth is the design's, taken on the reference host with marker scripts; the suite does not re-run ground truth | This spoke, at slice 2 | **APPLIED** — `core/hooks/tests/fixtures/walk-payload-corpus.txt` |
| **DEV-19** | The design counts its integration block (`FWALK-INT-*`, five arms) partly red before the fix. On this branch all five are green before it: slice 1's scanner arm already routes each must-refuse word. They are recorded as pins, not red-before arms, and the block's header says so | The hub's slice-2 brief (re-measure on the branch head) | **RECORDED** |
| **DEV-20** | The fragment's recipe for admitting an interpreter now names all three per-interpreter tables the walk asks — parse-only, option-arity and command-string — where the design's Change 7f added the command-string table only. The recipe had omitted the arity table since that table shipped; the design routed that drift into this slice once its text was being edited, and the D8 intake pass left it in-release | The design's evidence-grounding drift row; the D8 intake record | **APPLIED** — `core/rules/bypass-mode-readiness/block-destructive.md` |
| **DEV-21** | Slice 1's arm `FWALK-QWORD-M2i` asserted that the quoted-word deny mutant refuses `bash -ec 'echo a b'`. With the cluster fold that payload takes the `-c` route before the walk reads its program string, so no deny at the walk reaches it and the arm went red on the fixed hook. It is re-pointed to `perl -e 'print 1'`, a program string the walk still reads (the cluster table leaves non-shell interpreters on its null), with a paired must-stay-allowed control `FWALK-QWORD-ctl-program-fp`; `FWALK-QWORD-ctl-cluster-fp` keeps its payload and states its new reason. The design's rehearsal ran the 673 arms of the Stage-4 pin, not slice 1's, so it could not see this | This spoke, at slice 2 — measured, not predicted | **APPLIED** — `core/hooks/tests/block-destructive.test.sh` |
| **DEV-22** | Two small additions to the design's fragment text: the new scope-list item 10 cites arm `STDIN-PIN-03` for the pipe limit and names the corpus's open group, and the unreadable-option paragraph states the route's one definition (DEV-16). Item 9 and the quote-family paragraph are reconciled to the class now being closed; they had recorded it as open | This spoke, at slice 2 (reconcile, don't annotate) | **APPLIED** |
| **DEV-23** | The sudo row lists `-a type` and `-c class` with their long forms `--auth-type` and `--login-class`, which the design's row, built from the reference host's synopsis, omitted. The design required every row entry to be confirmed against the program's published manual at Stage 6 and admits an entry only where a manual names the option; the sudo manual names both as taking an argument. The direction is closing: each consumes the token a flag reading would take for the command word. Row arms `WRAPOPT-row-sudo-14` to `-16` carry them | The design's inclusion rule (Change 1c and its row-sources table); this spoke at slice 3 | **APPLIED** — `core/hooks/block-destructive.sh` |
| **DEV-24** | The first build condition (scope-lock D4: the review's 22 rows that the whole-set text moves from recorded to allowed). The handed text steps over `env`'s attached split string (`env -S<path>`), which executes. The row gains two fields, `script_wsplit` and `script_wlsplit`, and the walk stops on such a token, so it keeps the verdict it had. The review's other two classes — an option argument shaped like a script path, and an `env` operand whose name is not a shell name — execute nothing; they move from recorded to allowed as declared precision improvements, named in the fragment, pinned (`WRAPOPT-optpath`, `-optpath-short`, `-envop-name`) and recorded as corpus group `wrap-prec`. The review's broader form (every token the direct-execution arm claims stays the command word) is not taken; the decision record says why | Scope-lock D4 and the card's differential criterion (AC-6) | **APPLIED** — the hook, the suite, the corpus, the fragment |
| **DEV-25** | The second and third build conditions are met by statement and pins, not by mechanism. The `xargs` deny is reached behind `xargs`'s options for every interpreter family, with no record-only stage (`WRAPOPT-xargs-stdin-py`), and its predicate — no token after the interpreter — leaves an interpreter flag open (`WRAPDIV-xargs-interp-flag`). The fragment's `xargs` paragraph is restated to the predicate that is built. The review's counter-design that would close the flag case (its CD-2) was not adopted at the scope-lock and is not built | Scope-lock D4; the hub's slice-3 brief (CD-2 not adopted) | **APPLIED** |
| **DEV-26** | The parity arms read four lists, not three: the design's three walk copies and the SIGPIPE-idiom lint's wrapper list in the repository-integrity workflow, which the adversarial review named as a fourth copy. Keywords are compared across the three walks, and the lint list is asserted to hold none. The design's documentation arm reads every wrapper word of the four lists, so item 2 now names the lint's four launchers | Scope-lock (the parity arm reads every copy the reviews named) | **APPLIED** |
| **DEV-27** | The design's per-outcome texts are built for the outcomes the scope-lock rendered: Change 1c (whole set) and 1d (keywords added). D-QuotedValue rendered "declare" (D3), so 1e and its arm family are not built, and the design's three declaration pins are (`WRAPDIV-qval-sq`, `-fp`, `-sep`). The reviewer's keyword pin `WRAPDIV-kw-prose` and its clause in the fragment's suppression text are added. The block therefore holds 138 arms, which matches no row of the design's count table: the whole-set and keyword families as designed, the three sudo rows of DEV-23, the build-condition arms of DEV-24 and DEV-25, the reviewer's pin and the three declaration pins | Scope-lock D3, D4 and the concurring set | **APPLIED** |
| **DEV-28** | The corpus block `seed 6` (139 rows, ids `WR`) records ground truth `?` on every row. Every Bash call this spoke makes passes through the deployed pre-fix hook, so a marker script run behind a wrapper option would execute through the very gap this card closes. What each row runs is recorded in the review's tables M-1 to M-3 and in the design's measurements on the host binaries | This spoke, at slice 3 | **RECORDED** |
| **DEV-29** | The design's text places the new table beside "three" per-interpreter tables; slice 2 added a fourth, so the hook's comment says four | The hub's slice-3 brief | **APPLIED** |
| **DEV-30** | #7020 now carries seven criteria (the corrections pass added the review's differential criterion as AC-6). Its Verification Plan rows are re-bound — AC-6 to the corpus, AC-7 to the runner — and the four rows of other cards that pointed at "#7020 AC-6" as the runner row are re-pointed to AC-7 | The plan's AC-baseline rule; the card's corrected text | **APPLIED** — § Verification Plan |
| **DEV-31** | The decision record is numbered 217 at authorship: the repository's detector read anchor 216 and next-free 217, and reported 217 and 218 held on sibling branches (detection only). It binds at the Stage-12 claim and is renumbered at merge if the mainline takes it first (R-12). It is written `Proposed`; the Stage 13 ratification beat owns the transition | DEV-05, accepted by the hub after slice 1 | **RECORDED** — `core/ADRs/ADR-217-script-wrapper-walk-reads-option-grammar-from-rows.md` |

---

## Verification Evidence

Recorded at Engineering Commit 0 by the spoke on #8171. Later slices append their own rows.

| Check | Result |
|---|---|
| **Commit-0 version half** | § Commit-0 Version Re-Verify Record — next-free `v4.75`, absent on every arm, PROCEED |
| **Commit-0 base vs the Stage-4 pin** | `git log 4babbba9..origin/main` over the hook, its suite, its fragment, the registry, the layout helper and the fixture directory → 0 commits (denominator: 61 commits in the range). Control: the same paths over `35dbf418..4babbba9` → 12 commits. The hook's SHA-256 at the base is `2b5b1191…`, the digest #7019's design built against |
| **Runner baseline at the base** | `bash core/hooks/tests/setup-ci-layout.sh`, then `bash .claude/hooks/tests/test-runner.sh` → `AGGREGATE: PASS=1882 FAIL=0`, 25 suites, exit 0, 226 s; `block-destructive.test.sh` 673 of 673 |
| **Runner at Commit 0 (the floor later slices count from)** | the same two commands → `AGGREGATE: PASS=1926 FAIL=0`, 25 suites, exit 0, 318 s; `block-destructive.test.sh` 717 of 717 — the 673 committed arms plus 44 corpus arms: `WALKCORPUS-00`, `-ROWS`, `-SCOPE`, `-OPEN`, `-DET-fires`, `-DET-alive` and one `WALKCORPUS-REC-<group>` arm for each of the corpus's 38 groups. The corpus reader adds about 92 s to a full run (R-17) |
| **The corpus at Commit 0** | 375 `block-destructive` rows, 0 for other guards, resolved through the `.source-repo-root` pointer at the default-site layout; SHA-256 `126e1c7ed2a8da8157915b85e26a9c2c68510644f16855346c1c156fd9e7d15f`, printed by the suite's `RESIDUAL:` line and recomputed from the file with `shasum -a 256` (equal). Every row returned its recorded verdict on the base hook (38 of 38 groups green), so each row's recorded verdict is the base's own. 23 rows are declared open. Detector: the operand-walk mutant moved 20 recorded refusals or warnings to an allow (`WALKCORPUS-DET-fires`) and still refused or warned on the rest (`WALKCORPUS-DET-alive`) |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp hook-walk-adjudicates-every-operand` → **exit 0**, *"verify-stamp OK — hook-walk-adjudicates-every-operand carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s)); package-consequence checks not exercised"* (its pre-flight: the manifest stales 0 packages). Control: the same verb on `hook-walk-adjudicates-every-operand-zz` → exit 1, `NO PRE-CLAIM PLAN`. This file carries exactly one literal double-brace placeholder (a fixed-string count over the file returns 1, and a count of the opening double brace alone returns 1) |
| **The CIAC lint (G4-06) on this file** | `release/tools/verify-release-plan.sh --ciac-lint` on this file → exit 0, `CIAC-LINT-SUMMARY declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, the declared set `CIAC-1 CIAC-2 CIAC-3 CIAC-4`. Control: a copy in which CIAC-1's method names a tool the verifier declines reads `FLAG not-runnable:make`, `flagged=1`, exit 3 |
| **Plan verifier, pre-commit** | `release/tools/verify-release-plan.sh --format=md` on this file before its commit → 8 PASS / 13 FAIL / 34 SKIP / 0 UNRUNNABLE / 0 ERROR over 55 records (41 per-issue, 4 cross-issue, 10 always-on). Every FAIL is a later obligation, as expected at this slice: #7019 AC-1, AC-3 and AC-5 (this slice's own arms and fragment text, not yet landed); #7020 AC-1 and AC-4, #7028 AC-3, #7026 AC-4 and CIAC-1 (their slices); and FCM-1 to FCM-5, the five declared ADDs, of which the plan and the corpus are delivered by this commit and the three decision records by their slices. The provenance family reads PASS on coverage, presence and grammar (Form X, date 2026-10-08) |
| **Slice 1 (#7019) — red, on the pre-fix hook** | Commit `bedb28cb` (the arms and the corpus verdicts; no hook change): `bash core/hooks/tests/setup-ci-layout.sh`, then `bash .claude/hooks/tests/test-runner.sh` → `AGGREGATE: PASS=1915 FAIL=62`, exit 1, 410 s; `block-destructive.test.sh` 706 of 768. The 62 are the expected set and no other. **Red-before evidence, 47:** the 24 refusals this slice introduces (`NOEXEC-QSPLIT-01` to `-05`, the ten must-refuse arms of block (7b)(a), the eight unknown-value arms of (b), and `FWALK-QWORD-py`), the 22 corpus groups whose recorded verdict the fix moves, and `WALKCORPUS-TWIN`. **Instrument-absent, 15, not red-before evidence:** `FWALK-QWORD-M1a`, `-M2a` to `-M2j`, `-M3a`, `-M3b`, `-SCAN-01` and `-SCAN-02`, each of which reads a function or a mutation site the fix adds. **Green before, as designed, 14:** the nine must-stay-allowed controls of (c), `FWALK-QWORD-ctl-claimed`, and `FWALK-QWORD-M1b` to `-M1e` |
| **Slice 1 — the review's scanner arm, measured load-bearing** | The working tree with the walk reading built and the scanner's brace, glob and tilde arm left out (never committed): `block-destructive.test.sh` 766 of 768. Two real failures: `FWALK-QWORD-SCAN-01` read `DISAGREE value ""--{norc,rcfile}` — the shell brace-expands that word into two — and `WALKCORPUS-REC-rv-brace` moved rows RB01, RB05 and RB07 from `B` to `a`, three payloads under which an unlisted script runs. A third failure in that run, `LAYOUT-FRESH-01` (`STALE source-changed core/hooks/block-destructive.sh`), was an artifact: this spoke edited the hook source while the run graded its layout copy, and every later run rebuilt the layout first. That run's aggregate, `PASS=1974 FAIL=3`, is therefore two findings and one artifact |
| **Slice 1 — green, on the fix** | Commit `55f58355` (the hook): the same two commands → `AGGREGATE: PASS=1977 FAIL=0`, 25 suites, exit 0, about 380 s; `block-destructive.test.sh` 768 of 768 — the Commit-0 floor of 717 plus this slice's 51 new arms. The corpus as `bedb28cb` committed it: 375 rows, SHA-256 `3668e7460ad4c5b9d1cad8c71063a43f0a74d72fe37b8261cab6c01d6abb755c`, 38 of 38 groups and `WALKCORPUS-TWIN` green. Against Commit 0's file, 111 rows in 22 groups carry the verdict the fix gives — 104 from `a` to `B` and 7 from `a` to `W`, none toward `a` — and no row's command changed (a row-by-row comparison of the two committed files; 264 rows unchanged). The operand-walk mutant moved 44 recorded refusals or warnings to an allow (`WALKCORPUS-DET-fires`) |
| **Slice 1 — registry** | `python3 core/deploy/tools/build-hook-registry.py` → wrote `core/rules/bypass-mode-readiness.md`; then `--check` → `OK: core/rules/bypass-mode-readiness.md is in sync with its sources`, exit 0. Not hand-edited |
| **Slice 1 — the run on the readiness-text tree** | With the restated fragment and the regenerated registry in place (the content the readiness-text commit carries), the layout rebuilt and the runner run with stdin on the null device → `AGGREGATE: PASS=1977 FAIL=0`, 25 suites, exit 0, 372 s; `block-destructive.test.sh` 768 of 768, its readiness-document arms (`NOEXEC-DOC-*`) reading the new fragment and index; the corpus line unchanged (`3668e746…`, 44 moved by the mutant) |
| **Slice 1 — verification-plan probes** | On the working tree the readiness-text commit carries: #7019 AC-1 `FWALK-QWORD-ctl-allow` → 2 lines; AC-2 `NOEXEC-ORD` → 10; AC-3 `FWALK-QWORD-M1` → 7; AC-4 `WALKCORPUS-DET-fires` → 2; AC-5 `closed for a whole word` in the fragment → 3 (control: 0 in the fragment at `bedb28cb`, where the restated clause's old wording counts 1); CIAC-3 `F1-QTOK-RESIDUAL-space` → 2 |
| **Slice 1 — reference cascade of the restated clause** | `git grep -c -i -F` over seven phrasings of the clause's old wording, repo-wide except the release notes and the release log: 12 lines at `bedb28cb` (the hook 4, the fragment 3, the registry 3, this plan 2) → 0 on the working tree |
| **Slice 1 — skill-package freshness** | The seven changed paths, piped to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` → no skill named, exit 0. Control: `release/skills/release-planner/SKILL.md` through the same command → `release-planner` |
| **Slice 1 — ADR index** | N/A — this slice adds no record under `release/ADRs/` |
| **Slice 1 — plan verifier, CIAC lint and stamp, pre-commit** | `release/tools/verify-release-plan.sh --format=md` on this file → 13 PASS / 8 FAIL / 34 SKIP / 0 UNRUNNABLE / 0 ERROR over 55 records. #7019 AC-1 to AC-5 PASS (AC-6 is the runner's), CIAC-2 and CIAC-3 PASS, FCM-1 and FCM-2 delivered. Every FAIL is a later slice's: #7020 AC-1 and AC-4, #7028 AC-3, #7026 AC-4, CIAC-1, and FCM-3 to FCM-5 (the three decision records). `--ciac-lint` → `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, exit 0, unchanged by CIAC-3's new wording. `release/tools/claim-version.sh --verify-stamp hook-walk-adjudicates-every-operand` → exit 0; the file still carries exactly one literal release-version placeholder |
| **Slice 1 — instance drain, disclosed** | Rows of the instance's BLOCK-DESTRUCTIVE-022 would-fire drain whose working directory is this worktree: 1 before the registry regeneration (an `exec`-arm row naming `core/hooks/block-destructive.sh`, written by the deployed hook during a read-only compound command this spoke ran), 3 after it (the generator and its `--check`, `interp-nonshell` arm, warn phase). 162 rows of the same generator command were already present from other worktrees. All three are this spoke's own traffic; #7026's evidence can exclude them by working directory |
| **Slice 2 (#7018) — baseline on slice 1's head** | `b22b2081`: `bash core/hooks/tests/setup-ci-layout.sh`, then `bash .claude/hooks/tests/test-runner.sh` → `AGGREGATE: PASS=1977 FAIL=0`, 25 suites, exit 0, 425 s; `block-destructive.test.sh` 768 of 768; corpus `3668e746…`, 375 rows, 23 declared open. Equal to slice 1's recorded floor |
| **Slice 2 — red, on the pre-fix hook** | Commit `4b2cdbfd` (the arms, the corpus verdicts and the row-contract extension; no hook change): the same two commands → `AGGREGATE: PASS=2025 FAIL=97`, exit 1, 562 s; `block-destructive.test.sh` 816 of 913; no other suite failed. **Red-before evidence, 63:** the 45 refusals this slice adds — `NOEXEC-TERM-01` to `-21` with `-R1` and `-R2`, `FWALK-CLUSTER-01` to `-10` with `-R1`, `FWALK-OPAQUE-01` to `-10` with `-R1` — and 18 corpus arms: the 17 groups whose rows the fix moves, and `WALKCORPUS-TWIN`. **Instrument-absent, 34, not red-before evidence:** the liveness and payload arms of mutants whose mutation site is the new code — `NOEXEC-TERM-M1a`, `-M2a` to `-M2h`, `-M3a` to `-M3c`, `-M4a`, `-M4c`, `-M5a` to `-M5d`; `FWALK-CLUSTER-M1a`, `-M2a` to `-M2c`, `-M3a`, `-M3b`; `FWALK-OPAQUE-M1a`, `-M2a` to `-M2f`, `-M3a`, `-M4a`, `-M4b`. **Green before, as designed:** every control, pin and must-not-flag arm (the stdin arms and the stdin-deny mutant among them), the five `FWALK-INT-*` integration pins (DEV-19), and the revert mutants' payload arms, which read the pre-fix verdict |
| **Slice 2 — measured on the fixed hook before the green commit** | The working tree with the fix, the arms and the corpus. A first run (block-destructive 905 of 912) found the one slice-1 arm the cluster fold invalidates, `FWALK-QWORD-M2i` (DEV-21), and the 34 rows of earlier blocks whose verdict the fix moves — every one from allow to block, RN35 being the design's declared over-block — while all 293 appended rows returned the verdict the design measured for them. That run's aggregate, `PASS=2113 FAIL=8`, also carried a `LAYOUT-FRESH-01` artifact from editing the suite while it ran. With the moves recorded and the arm re-pointed: `AGGREGATE: PASS=2122 FAIL=0`, 25 suites, exit 0, 461 s; `block-destructive.test.sh` 913 of 913 |
| **Slice 2 — green, on the fix** | Commit `4ef33822` (the hook) carries byte for byte the tree that run graded: hook SHA-256 `4385cb7e202e3e5177cd022902b85c41790788c8efbdc32069246134083a12b2`, corpus SHA-256 `b8b5856644d95d5453d19e7cbef1550d057db7ba1a0b81065038a86ddd7c2db8`. 913 arms = the 768 of slice 1, the design's 127, `FWALK-QWORD-ctl-program-fp`, and 17 new corpus group arms |
| **Slice 2 — the corpus** | 668 rows (375, and 293 appended as block `seed 5`), 8 declared open (group `open-stdin`, a program fed on standard input). Pre-fix against fixed, row by row from the red run's group arms: 148 rows move toward refusal (147 to block, and 1 to warn, `ZH15`, a non-shell interpreter at its warn phase) and none toward allow; the other 520 are unchanged. The 23 rows recorded as open for the raw-led class and the substitution grant are refused and leave their `open-` groups. The operand-walk mutant moves 82 recorded refusals or warnings to an allow (`WALKCORPUS-DET-fires`). The digest is recomputed from the file with `shasum -a 256` and equals the suite's `RESIDUAL:` line |
| **Slice 2 — the run on the readiness-text tree** | With the fragment, the regenerated registry and the hook in place (the content the readiness-text commit carries): `AGGREGATE: PASS=2122 FAIL=0`, 25 suites, exit 0, 572 s, with other commands running beside it; `block-destructive.test.sh` 913 of 913, its readiness-document arms (`NOEXEC-DOC-*`) reading the new fragment and index |
| **Slice 2 — registry** | `python3 core/deploy/tools/build-hook-registry.py` → wrote `core/rules/bypass-mode-readiness.md`; then `--check` → `OK: core/rules/bypass-mode-readiness.md is in sync with its sources`, exit 0. Not hand-edited |
| **Slice 2 — verification-plan probes, verifier, CIAC lint and stamp** | `release/tools/verify-release-plan.sh --format=md` on this file → 17 PASS / 8 FAIL / 30 SKIP / 0 UNRUNNABLE / 0 ERROR over 55 records. #7018 AC-2 to AC-5 PASS (`NOEXEC-TERM-ctl-word` 1 line, `STDIN-ctl-0` 4, `STDIN-PIN-0` 3, `ZS13` 1); #7019 AC-1 to AC-5, CIAC-2 and CIAC-3 still PASS. Every FAIL is a later slice's, the same eight slice 1 recorded. `--ciac-lint` → `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, exit 0. `release/tools/claim-version.sh --verify-stamp hook-walk-adjudicates-every-operand` → exit 0 |
| **Slice 2 — reference cascades** | The raw-led class recorded as open: `git grep -c -i -F` over five phrasings of that claim, the tracked tree minus the release notes and the release log (2,125 tracked files at `b22b2081`) → pre 10 lines (the hook 2, the suite 2, the fragment 2, the registry 2, this plan 2) / post 0. The table count, three to four: `hunting three` and `beside the other two` over the hook, the fragment and the registry → pre 3 / post 0 |
| **Slice 2 — skill-package freshness** | The seven changed paths, piped to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` → no skill named, exit 0. Control: `release/skills/release-planner/SKILL.md` through the same command → `release-planner` |
| **Slice 2 — ADR index** | N/A — this slice adds no record under `release/ADRs/` |
| **Slice 2 — instance drain, disclosed** | Rows of the instance's BLOCK-DESTRUCTIVE-022 would-fire drain whose working directory is this worktree, read at 23:44Z: 6, all `interp-nonshell` at the warn phase — four scratch Python scripts this spoke ran from its run directory, and the registry generator with its `--check`. #7026's evidence can exclude them by working directory |
| **Slice 3 (#7020) — baseline on slice 2's head** | `7301d635`: `bash core/hooks/tests/setup-ci-layout.sh`, then `bash .claude/hooks/tests/test-runner.sh` → `AGGREGATE: PASS=2122 FAIL=0`, 25 suites, exit 0, 487 s; `block-destructive.test.sh` 913 of 913; corpus `b8b58566…`, 668 rows, 8 declared open, the operand-walk mutant moving 82. Equal to slice 2's recorded floor. The hook's SHA-256 before any edit, `4385cb7e…`, equals slice 2's recorded digest (A3) |
| **Slice 3 — the decision record** | Commit `ae0097da`. `release/tools/renumber-adr.py --detect` → anchor 216, next-free 217, 217 and 218 held on sibling branches (detection only); after authoring → `CLAIM ADR-217 … BINDS BRANCH-CLAIM`. `release/tools/check-adr-durability.py --files <the record> --diff-base origin/main` → `COUNT 0`. Control: a copy of the record with a commit SHA and a corpus count planted in its body → `COUNT 2` (`R2-SHA`, `R2-COUNT`) |
| **Slice 3 — measured on the fixed tree before the commits** | The hook, the readiness text, the regenerated registry, the suite and the corpus in the working tree: `AGGREGATE: PASS=2274 FAIL=0`, 25 suites, exit 0, 535 s; `block-destructive.test.sh` 1,065 of 1,065 — the 913 of slice 2's head, 138 new arms in the `WRAP*` block, and 14 new corpus group arms. Every new arm returned its predicted verdict on the first measurement, and every corpus row its predicted verdict. Hook SHA-256 `4ef707ec55db98fca33ac1faad8e455d56971a3e43d2e835ed130e95b29aa157`, corpus SHA-256 `31c9ab26e9050ece06a42a10496ec27f2f75565b76e5666464a1c8a46a85b950` |
| **Slice 3 — red, on the pre-fix hook** | Commit `3a040ae9` (the suite and the corpus; no hook, fragment or registry change), measured by checking that commit out after the green commit was pushed: the same two commands → `AGGREGATE: PASS=2165 FAIL=109`, exit 1, 498 s; `block-destructive.test.sh` 956 of 1,065; no other suite failed. **Red-before evidence, 103:** the 94 pair arms whose hook limb the fix turns (the `WRAPOPT-*` and `WRAPKW-*` refusals and records, the precision arms that move toward allow, and the three over-blocks the change introduces, `WRAPDIV-sudo-long`, `-kw-prose` and `-timeout-malformed`), the rewritten `timeout` pin, `WRAPVOCAB-PARITY-DOC` (the readiness item named neither word), and 7 corpus groups (`wrap-opt`, `wrap-optrec`, `wrap-xargs`, `wrap-prec`, `wrap-kw`, `wrap-overblock`, `wrap-overread`). **Instrument-absent, 6, not red-before evidence:** `WRAPOPT-M0` and `WRAPVOCAB-PARITY-wrappers`, `-keywords`, `-M1`, `-M2`, `-M3`, which read the markers the fix adds. **Green before, as designed, 37:** `WRAP-SCOPE`, every `-ctl-` control, the six describe-only arms, the attached split-string arms (their verdict is the pre-fix one), and every pin the slice declares (`WRAPDIV-redirect`, `-escaped`, `-quoted-word`, `-unlisted-valued`, `-env-S-quoted`, `-env-S-attached-cmd`, `-xargs-interp-flag`, `-xargs-interp-flag-bare`, `-xargs-stdin-py-bare`, `-qval-sq`, `-qval-fp`, `-qval-sep`) |
| **Slice 3 — green, on the fix** | Commit `57732406` (the hook, the readiness fragment and the regenerated registry) carries, byte for byte, the graded files of the fixed-tree run above: `AGGREGATE: PASS=2274 FAIL=0`. The plan commit after it changes no graded file |
| **Slice 3 — the corpus** | 807 rows (668, and 139 appended as block `seed 6`, ids `WR`), 8 declared open. Pre-fix against fixed, row by row from the red run's group arms: 48 rows move — 35 from allow to block, 5 from allow to warn, and 8 toward allow, which are exactly the declared precision group `wrap-prec` (WR71 to WR78: an option's argument, an `env` operand; the program executes neither path). No row of the 668 earlier rows moves, and no executing row moves toward allow: the attached split-string rows of the review's table M-2 keep their record (group `wrap-env-s`). The digest is recomputed from the file with `shasum -a 256` and equals the suite's `RESIDUAL:` line |
| **Slice 3 — registry** | `python3 core/deploy/tools/build-hook-registry.py` → wrote `core/rules/bypass-mode-readiness.md`; then `--check` → `OK: core/rules/bypass-mode-readiness.md is in sync with its sources`, exit 0, re-run after the fixed files were restored for the green commit. Not hand-edited |
| **Slice 3 — verification-plan probes, verifier, CIAC lint and stamp** | `release/tools/verify-release-plan.sh --format=md` on this file → 24 PASS / 4 FAIL / 28 SKIP / 0 UNRUNNABLE / 0 ERROR over 56 records. #7020 AC-1, AC-2, AC-4, AC-5 and AC-6 PASS; AC-3 and AC-7 are declared deferrals; CIAC-1 now PASS; FCM-3, this slice's decision record, is delivered. Every FAIL belongs to a later slice: #7028 AC-3, #7026 AC-4, and FCM-4 and FCM-5. `--ciac-lint` → `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, exit 0. `release/tools/claim-version.sh --verify-stamp hook-walk-adjudicates-every-operand` → exit 0; the file still carries exactly one literal double-brace token, the release-version placeholder |
| **Slice 3 — the manual confirmation the design required** | The published manuals confirm every argument-taking option the rows list: GNU coreutils 9.11 (`env -a/--argv0`, `-C/--chdir`, `-u/--unset`; `nice -n/--adjustment`; `stdbuf -i/-o/-e` and their long forms; `timeout -k/--kill-after`, `-s/--signal`), GNU findutils `xargs` (`-a`, `-d`, `-E`, `-I`, `-L`, `-n`, `-P`, `-s`, the attached-only `-e`, `-i`, `-l`, and the six long forms), GNU time 1.7 (`-f/--format`, `-o/--output`) and sudo (every listed option; the BSD-only and host-only entries — `env -P`, `xargs -J`, `-R`, `-S`, `time -l` — are the reference host's synopses, as the design recorded). The sudo manual also names `-a type` and `-c class`, which the row now lists (DEV-23). No entry was removed |
| **Slice 3 — reference cascade** | `git grep -c -i -F` over six phrasings of the claims this slice retires — that the wrapper set mirrors the canonicalizer's, that a wrapper's own flags terminate the walk, and that `timeout` is not a skipped prefix — over the tracked tree minus the release notes and the release log (2,125 tracked files at `7301d635`) → pre 8 lines (the hook 1, the suite 3, the fragment 2, the registry 2) / post 0. The runner-row identifier `#7020 AC-6` over the tracked tree → pre 4 lines (5 occurrences, all in this file) / post 0 (control: `#7020 AC-7` → 4) |
| **Slice 3 — durable-text probe** | `grep -c -E '#[0-9]|\]\(|https?://'` over the added lines of the fragment's diff (6 lines) → 0. Control: a line holding `#12`, `[a](b)` and `https://z` → 1 |
| **Slice 3 — skill-package freshness** | The seven changed paths, piped to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` → no skill named, exit 0. Control: `release/skills/release-planner/SKILL.md` through the same command → `release-planner` |
| **Slice 3 — ADR index** | N/A — this slice adds no record under `release/ADRs/`; its record is under `core/ADRs/`, whose README is curated and has no projected region |
| **Slice 3 — instance drain, disclosed** | Rows of the instance's BLOCK-DESTRUCTIVE-022 would-fire drain whose working directory is this worktree, read after the red run (the newest such row is stamped 00:59:37Z): 8 of 34,233, all `interp-nonshell` at the warn phase and all tracked repository tools this spoke ran — the ADR-numbering detector twice, the ADR durability lint three times, and the registry generator with its `--check` three times. #7026's evidence can exclude them by working directory |

---

## Deployment Execution Log

*(Populated during Stage 12.)*

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | | |
| Merge PR | | | |
| Tag release | | | the version binds at the Stage-12 atomic claim (ADR-092) |
| Skill deployment | | N/A | no skill source is edited by this release |
| Manifest execution | | | § Operational Deployment Manifest rows 1–2: the hook publisher, then `deploy.sh --deploy` |
| State anchor update | | | |
| Post-execution verification | | | release gate E8 — each deployed hook copy equals its merged source by SHA-256, then the fresh-session probes |

---

## Change Description

Authored by the Stage 6 spoke on #8171 when the pull request opened, per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, and refreshed by the spokes on #8172 and #8170 when slices 2 and 3 landed. This release builds in seven serial slices on one branch, so this section covers the slices that have landed, and each later slice refreshes it: it adds its row to the table and restates the Outcome. It is distinct from the user-facing release note authored at Stage 13.

### Outcome

The script-execution rule (BLOCK-DESTRUCTIVE-022) now adjudicates the script behind two kinds of flag it used to step past without reading. **Slice 1 (#7019):** a flag token whose leading quote closes early no longer hides the script behind it. `bash ""-x <script>`, `bash -n ""+n <script>`, `zsh ''-x <script>` and the rest of that family were allowed while their unquoted spellings were refused; they now take the unquoted spelling's verdict, so a script missing from the allowlist is refused and an allowlisted one still runs. A quote-led flag word whose value the hook cannot know — a `$` expansion, a command substitution, an unquoted brace, glob or tilde character, or a token longer than the reader's limit — is no longer taken for the operand: the walk goes on, and the script behind it is checked. **Slice 2 (#7018):** a bare `-n` is a parse-only grant only where the interpreter really reads it as a flag. A `-n` behind a word that is not an option (`zsh -s -O extglob -n <script>`, `bash <wrapper> -n <script>`), behind an option the walk cannot read exactly (`bash --rcfile"" -n <script>`), or behind an option argument that may be no word at all (`bash --rcfile $X -n <script>`) was exempted while the shell ran the script; those invocations are adjudicated again, as they were before the parse-only exemption existed. A cluster carrying the command-string letter (`bash -ec '<program>'`, `sh -xc`, `bash +ec`) now opens a program string whose words are checked, as a bare `-c` always did, and an option the walk cannot read no longer hides an unlisted script behind an allowlisted one. A program fed to a shell on standard input stays outside the rule's reach, and the readiness doc now says so. **Slice 3 (#7020):** a transparent wrapper's own options no longer stop the walk. `nice`, `stdbuf` and `timeout` join the walked set, and every wrapper's options and operands are read from a per-wrapper row of its option grammar, so `nice -n 10 bash <script>`, `stdbuf -o 0 bash <script>`, `sudo -u <user> bash <script>`, `env -u NAME bash <script>` and `timeout 5 bash <script>` take the verdict of `bash <script>` — a script missing from the allowlist is refused and an allowlisted one still runs. `if`, `while` and `until` join the keyword arm. An `xargs` that feeds an interpreter from standard input is refused behind `xargs`'s own options as it was without them. The four lists of this vocabulary — this walk's, the egress walk's, the shared canonicalizer's and a continuous-integration lint's — are now compared word by word on every run. What stays open is declared and pinned: an option a row does not list that takes a value, an interpreter flag after `xargs <interpreter>`, a command line written as one string, launchers outside the set, and a quoted assignment value ahead of the verb. The walk changes are measured against a committed corpus of 807 payloads, each with a recorded verdict, which the hook suite re-grades on every run; no payload's verdict has moved toward allow except the declared precision rows of slice 3, where nothing executes.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #7019 | A quote-led flag word is read as the word the shell passes the interpreter; the first fragment of a space-bearing quoted path still ends the walk, a declared residual | DONE — built in slice 1; Stages 7 and 8 verify it |
| #7018 | A `-n` the interpreter never reads as a flag is no longer a parse-only grant; a cluster carrying `c` is read as `-c`; an option the walk cannot read takes the conservative route; a program on standard input is declared outside the rule's reach | DONE — built in slice 2; Stages 7 and 8 verify it |
| #7020 | `nice`, `stdbuf` and `timeout` join the wrapper walk, every wrapper's own options are walked from a row, `if`, `while` and `until` join the keyword arm, and the four lists of the vocabulary are asserted against each other; the quoted assignment value is declared and its fix routed to #8319 | DONE — built in slice 3; Stages 7 and 8 verify it |

#7028, #7004, #7027 and #7026 add their rows when their slices land (§ Implementation Sequence).

### Key decisions

- **Scope-lock D2 — one tracked corpus.** `core/hooks/tests/fixtures/walk-payload-corpus.txt` is the release's differential, read by the block-destructive suite's own harness; each later walk card appends its rows and moves only the verdicts its change moves (§ Decision Record).
- **Scope-lock, #7019 in the concurring set — the recommended walk option plus the review's scanner arm, without the operand fold.** Built as locked. The scanner arm was measured load-bearing (§ Verification Evidence); the split-suffix operand the fold would have closed stays with its own card (D8).
- **Scope-lock — the class of flags that begin with `-`, `+` or a backslash and carry a quote or a backslash is #7018's.** Slice 2 closes it, brace and glob spellings included: the option-run latch withholds a parse-only grant behind such a flag, and under an interpreter the flag takes the conservative route. The 23 corpus rows that recorded the class, and the substitution grant, as open are refused now.
- **Scope-lock, #7018 in the concurring set — the option-run latch, its recommended scope answer, and the cluster fold.** Built as locked. The scope answer walks a stdin-mode invocation's command line like any other and declares the program on the pipe outside the rule's reach (readiness item 10); arm `PARSE-12c` keeps refusing, and the item says why. The conservative route has one definition on the merged hook (DEV-16).
- **Scope-lock D4 — the whole wrapper set, with the review's three stated costs as build conditions.** Built: one getopt-notation row per wrapper beside the per-interpreter tables and no fallback scan, as the design's D-1 proposed; the decision record is ADR-217, `script-wrapper-walk-reads-option-grammar-from-rows`, numbered at authorship and binding at the Stage-12 claim (DEV-31), written `Proposed`. The first condition is met in code — `env`'s attached split string keeps its record and the two non-executing classes are declared precision improvements (DEV-24); the second and third by statement and pins — an `xargs`-fed interpreter is refused with no record-only stage, and an interpreter flag after it stays open (DEV-25).
- **Scope-lock, #7020 in the concurring set — the conditional-keywords line, with the reviewer's pin.** Built: `if`, `while` and `until` join the keyword arm; the prose over-block it widens is pinned (`WRAPDIV-kw-prose`) and named in the readiness text's suppression paragraph.
- **Scope-lock — per-guard placement; the parity arm reads every copy the reviews named.** Built over four lists, both directions, with a declared table that fails when a declaration outlives its difference (DEV-26). The shared canonicalizer is not edited; its gaps are owned by #8314.
- **Scope-lock D3 — the quoted assignment value is declared, not built.** Readiness item 3 names it in both directions, three arms pin today's verdicts, and #8319 owns the fix.

### Reversibility

**MODERATE — HIGH confidence.** Each card is its own run of commits on a linear branch and reverts with `git revert` of those commits, or the whole release with a revert of its merge; either way the deployed hooks change only when the hook publisher republishes them.

### Downstream impact

- #7028 builds next, on the segmenter of the same file. Readiness item 2's grouping sentence is byte-identical to its text before slice 3. The function block slice 3 inserted moves every later anchor in the hook, so later slices anchor by text. Three shapes the wrapper walk does not reach are routed (#8316): a `case` arm, `coproc`, and the unreached prefix positions.
- #7004: the parity arms read the egress walk's lists from the first two pattern lines after its one `case "${egress_raw##*/}" in`. If slice 5 changes those lines or that anchor, the declared table in `core/hooks/tests/block-destructive.test.sh` changes in the same pull request (the design's integration criterion INT-1).
- #7026's evidence, from slice 3: a direct execution or a non-shell interpreter behind a wrapper's options now writes an `exec` or `interp-nonshell` row at its phase, and nothing in a row says which position wrote it, so a count taken across the publish boundary is not one population. An `xargs`-fed interpreter of any family is refused and writes no row. One declared over-read writes an `exec` row: `timeout <command>` with no duration.
- #7026's decision evidence: under the phase-gated interpreters, slice 1 turns previously silent quote-led spellings into `interp-nonshell` would-fire rows (dependency edge E2), and slice 2's conservative route adds rows of one declared over-block shape there, `python3 $X-u <allowlisted>.py <unlisted>.py` (dependency edge E1).
- Every later walk card adds its rows to the corpus. Slice 1 measured the corpus reader at about 90 seconds of a full hook-suite run (R-17); with slice 2's 293 rows and new arms the full runner measured 461 s and 572 s on two runs, the second with other commands running beside it, against 425 s on slice 1's head in the same session. Slice 3's 139 rows and 152 arms took the full runner from 487 s on slice 2's head to 535 s in one session.
- Declared over-blocks added by slice 2, each recoverable by respelling the command: `bash -eo pipefail -n <script>`, `bash -o "$VAR" -n <script>`, `bash -nc '<program>'`, a script-suffixed word that a cluster's program string only reads, and an option the walk cannot read in front of an allowlisted script followed by an unlisted one.
- Declared over-blocks added by slice 3, each recoverable by respelling the command: `sudo --list bash <script>` (a long describe-only spelling read as a flag), and prose after a separator in a quoted argument of a command that is no carrier (`git commit -m "note; if bash <script> then"`).
- Still open by declaration: the first fragment of a space-bearing quoted path (readiness limit 3), pinned by `F1-QTOK-RESIDUAL-space` and `FWALK-QWORD-ctl-fragment-noexec`; a program fed on standard input (readiness item 10, corpus group `open-stdin`); zsh's `-b` ahead of a `-n` (arm `NOEXEC-TERM-P1`); and from slice 3, readiness item 2's open list — launchers outside the set, an option a row does not list that takes a value, a command line written as one string, an interpreter flag after `xargs <interpreter>`, the unreached positions (#8316) — and item 3's quoted assignment value (#8319).
- Surfaces changed so far: `core/hooks/block-destructive.sh`, its suite, its readiness fragment, the generated registry, the corpus with its README entry, and the decision record `core/ADRs/ADR-217-script-wrapper-walk-reads-option-grammar-from-rows.md`.

### Cross-references

- Release plan: this file, § Header and § Implementation Sequence
- Milestone: `hook-walk-adjudicates-every-operand` (milestone 404); pull request #8306
- User-facing release notes: authored at Stage 13 Close under `release/releases/notes/`, per `release/references/standards/release-notes-standard.md`
