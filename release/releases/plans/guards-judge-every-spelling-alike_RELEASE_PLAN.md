---
title: Release Plan — guards-judge-every-spelling-alike (a guarded command gets the same verdict however it is written)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.82; the concrete number binds at the Stage-12 atomic claim)
milestone: guards-judge-every-spelling-alike
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH — one branch and one merge; each card reverts with its own run of commits and a republish of the hook bundle, and reverting the merge restores main. MODERATE rather than CHEAP because the canonicalizer change reaches every Bash call through four always-on hooks once the hook publisher runs, so a revert must itself be republished and verified by hash. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `guards-judge-every-spelling-alike`

**Milestone:** `guards-judge-every-spelling-alike` (milestone 438). The Stage-4 planning sub-task **#8605** carries the approved two-part plan, the Mode R readiness briefing it adopted (`#8605 comment 6613987950`) and the Stage-4 gate's Decision Recorded. The Stage-5 designs are on **#8628** (#8314), **#8629** (#8315) and **#8630** (#8444); their independent adversarial reviews are on **#8647**, **#8648** and **#8649**. The Collective Review scope-lock Decision Recorded is on **#8628**. The Stage-6 Engineering sub-tasks are **#8631** (#8314), **#8633** (#8444) and **#8632** (#8315); this file is Engineering Commit 0, authored by the spoke on **#8631**, which also builds #8314's slice.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.82`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The two sibling releases that merge first under the recorded merge order (ms#442, minor, and ms#443, major) are expected to take `v4.82` and `v5.00`, after which the claim computes **`v5.01`** for this release.

**Topology:** D-C **SINGLE** — one release branch, `release/guards-judge-every-spelling-alike`, one pull request opened in **draft** at Stage 6 Phase C2 after #8314's slice, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — #8314 → #8444 → #8315, one Engineering spoke at a time, each landing on the release branch before the next starts. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `cross-cutting` — re-rendered from `novel` at the Collective Review scope-lock; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8605 (parts 1/2 and 2/2) and is amended by two decision records, in order: the Stage-4 gate's Decision Recorded on #8605 (plan approved; `novel` pending the Stage-5 tripwire re-check; SINGLE; P0; D-Crisp's six card-body amendments applied; D-HookDeploy (B); D-Scope-023 (A); minor), and the Collective Review scope-lock Decision Recorded on #8628 (D-S5-8314-EXITS (A), the masked exit view; #8315's bounded Stage-5 delta; the security rating; `cross-cutting`; every other design decision approved as recommended). The three Stage-5 designs and the approved findings of their adversarial reviews are design inputs as that record adopts them. Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log with the decision that caused it. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): guard logic, a shared primitive's grammar and readiness text inside existing structure, per the Bump-Class Selection Guide's "protocol text addition or modification". Provisional display `v4.82`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092), where `v5.01` is expected once ms#442 and ms#443 have merged |
| **Date Created** | 2026-11-04 (Wednesday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file), then the slices of #8314, #8444 and #8315, the third and last, each in its own spoke, then a follow-up pass on #8314 decided at the Stage 6 inter-stage gate (D-S6-APPEND (A), DEV-25), then a walk-fix pass shared by #8314 and #8315 decided at the same gate (D-S6-WALKS (A), DEV-29) |
| **Branch** | `release/guards-judge-every-spelling-alike` |
| **PR** | **#8651**, opened in **draft** at Stage 6 Phase C2 after #8314's slice; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `guards-judge-every-spelling-alike` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-03, domain: security }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform hook, hook library, hook suite, test fixture, readiness fragment, generated registry or decision record, so no external body of practice is consumed. Dominant domain **`security`** (guard hooks, their suites and their readiness text); secondary domain software (awk and bash code). The `security` guide under `core/standards/domain-best-practices/` is consulted for design consumption. Transcribed unchanged from the Stage-4 plan (Phase A1.5).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `f8d88626` (`f8d8862668aa373a37f36f309c54eb364fae2d9b`), equal to the Stage-4 baseline pin. The release branch was cut from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha f8d8862668aa373a37f36f309c54eb364fae2d9b --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v4.82`** (exit 0; "would claim v4.82 (no tag pushed)") — equal to the planned display |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each read by one python3 line scan that compares exact version tuples
Denominator: 452 ls-remote lines (227 distinct versions, the highest v4.81); 225 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             2,892 lines
Control - sensitivity: the same scan on the v4.81 slot — 2 tag lines, 1 Release line and
             7 ledger lines. Every arm returns non-zero, so a zero on the v4.82 slot is a
             real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (the comparator is tuple equality)
Extraction:  every line of the three reads, the ledger read from origin/main (never the
             worktree copy)
Result:      0 occupants of the (4,82) slot on every arm
Verdict:     CLEAN — v4.82 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** two sibling releases, both open in draft and neither merged — ms#442 (#8645, minor, recomputed next-free `v4.82`, the same slot) and ms#443 (#8646, major, recomputed next-free `v5.00`). Both merge ahead of this release under the recorded merge order, so a later re-derivation reads `v5.01` (§ Cross-PR Overlap Audit → In-Flight Release Roster). This is the expected state the Stage-4 plan named (R-9), and it is not a HALT at this rung: the slot binds at the claim.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp guards-judge-every-spelling-alike`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-04`** (Wednesday). Every later card that writes a date-bearing identifier consumes this value and writes no other literal. Its one load-bearing use known at this commit is the `date:` frontmatter of #8314's decision record.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited; the Stage-5 conditional resolutions applied at this commit) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria `CIAC-1`..`CIAC-4` | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence (the approved build order, as the scope-lock resolved it) | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA, which is also the Commit-0 base) | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Issue | Priority | Size | Title | Disposition |
|---|---|---|---|---|
| #8314 | P1 | M | Shared command-position canonicalizer skips a wrapper's options and an incomplete wrapper set, so anchored rules in four hooks miss an adjudication | carried; Stage-5 design on #8628 with the adopted findings of its review on #8647 (FMF-1, FMF-2, FMF-4, PRF-1, PRF-2 and CDF-1 (ii′a)) |
| #8444 | P2 | S | PATH-manipulation rule may judge an assignment by its spelling | carried; Stage-5 design on #8630 with its review on #8649, ROUTE-CANON selected |
| #8315 | P1 | L | BLOCK-EGRESS-007's own command-position walk is evaded by alternate spellings, so a write the plain-form day-one deny refuses is admitted | carried; Stage-5 design on #8629 re-opened for a bounded delta (AR-P1..AR-P4 from its review on #8648) that the hub reviews before its Stage 6 |

**Size:** 14 raw points (4 + 2 + 8), **18 effective** under `cross-cutting` (14 × 1.3), inside the acceptable band.

### Exclusions

| Item | Why it is out of scope | Routed to |
|---|---|---|
| #8122 — the deletion hook's line laundering (a `git` subcommand or a target-less deletion verb at one command start exempting the whole line) | The scope-lock keeps it its own card for the per-segment closure; adding it is forbidden under the Composition Lock. #8314 only stops the canonicalizer widening the two exits (the masked exit view) | #8122, unmilestoned |
| Launchers outside every walk's set (`doas`, `setsid`, `ionice`, `chrt`, `caffeinate`, `arch`, `flock`, `watch`, `script`) — #8314 design gap G2 | No owner; outside the -022 parity set the canonicalizer adopts | the hub's routing call; declared as a residual in the readiness text |
| A wrapper's working-directory option (`env -C`, `sudo -D`) not followed for a relative operand — G3 | A different axis (the in-command `cd` family) | the hub's routing call; declared in the readiness text |
| An escaped structural character inside double quotes left unmasked by the canonicalizer — G5 | A pre-existing false-positive class, not a reach gap | the hub's routing call |
| The case-variant command-word class across every case-sensitive anchored rule | Cross-hook; #8315 disposes only the -007 instance | Stage-4 action item AI-002 |
| The hook carrier's `post-merge` re-point into a worktree | A carrier defect | Stage-4 action item AI-003 |

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-03)

| Decision | Rendered |
|---|---|
| Plan + Release Outcome Statement | **Approved as recommended.** The milestone description carries the `**Limb owners:**` line, the Release Class posture line and the recorded Parallelization Map |
| D-ReleaseClass | `novel`, re-checked at Stage 5 against the v4.80 tripwire (superseded at the scope-lock: `cross-cutting`) |
| D-C Branch Topology | **SINGLE**, `release/guards-judge-every-spelling-alike`; the plan lands as Engineering Commit 0 |
| D-Concurrency | **P0**, fully serial |
| D-Crisp | **Six card-body amendments applied** (#8314 AC1 bounds the missing-wrapper face to named words per ADR-187's bounded-enumeration non-claim; #8314 and #8315 AC2 gain the allow→refuse direction; #8315 AC1 enumerates nine classes on the day-one repair rung; #8315 AC3 pins FAIL 0 and Total ≥ 413; #8444 AC1 adds the condition position; the Affected Files additions). The optional Documentation Impact rewrite was not applied |
| D-HookDeploy | **(B):** at Stage 12 the hub runs the hook carrier from the primary checkout by absolute path, with no `cd`; every edited file is verified by SHA-256 against its merged source; a Tier-0 refusal falls back to a user-side handoff |
| D-Scope-023 | **(A):** if #8444 takes ROUTE-CANON, BLOCK-DESTRUCTIVE-023's wrapped spellings fold in as a declared tightening |
| D-Version | A recorded determination, not a gate: minor, provisional `v4.82`, re-derived at Engineering Commit 0 (above) and bound at the Stage-12 claim |

### Collective Review scope-lock (operator, 2026-11-03)

| Decision | Rendered |
|---|---|
| D-S5-8314-EXITS | **(A) masked exit view.** The deletion hook's two whole-line allow exits (Step 1's `git` exemption and Step 2's no-target exit) read a quote-masked, un-widened view from one additive canonicalizer output mode, so they keep today's verdicts. No overlap with #8122, and no new refuse→allow. #8122 stays its own card |
| #8315 Blocker (AR-P1) | **(A) bounded Stage-5 delta** on #8629 covering AR-P1..AR-P4; the hub reviews it before #8315's Stage 6, which runs third. #8314 and #8444 proceed under this lock (a partial scope-lock, recorded in § Deviation Log) |
| Security rating | **Security-relevant bug.** Each card's RED fixtures land in its own fix commit, not at Engineering Commit 0; the red-before run is made in the worktree and recorded as executed evidence (G-PR4) before the commit that carries the fix |
| D-ReleaseClass | **`cross-cutting`**, re-rendered from `novel`: the v4.80 tripwire is met by #8314's WIDEN-CANON |
| Remaining design decisions | **Approved as recommended** — per card in § Implementation Sequence |
| Write sets and serialization | `core/rules/bypass-mode-readiness/_cross-cutting.md` lines 49 and 222: #8314, then #8444. `core/rules/bypass-mode-readiness/block-destructive.md` line 23: #8314, then #8315 |
| Size | 14 raw / 18 effective under `cross-cutting` (#8315 re-sized M → L) |
| Action items | AI-005 (post the residual scope on #8315's successor once its delta settles); AI-006 (at Stage 9, tell the ms#439 and ms#440 hubs that they rebase onto `block-destructive.md` line 23, and that #8491's split-scan change has a twin in the canonicalizer) |

---

## Dependency Graph

```
native edges (GraphQL blockedBy / blocking): 0 / 0 on all three cards (Stage-4 read; control #8493 = 1)
in-release order (compositional; one PR, so they order the work and block nothing):
  Commit 0 -> #8314            the plan
  #8314 -> #8444               ROUTE-CANON: #8444's insertion is bound to #8314's new assignment branch;
                               the condition-position spelling reaches -020 only through #8314's face (d)
  #8314 -> #8315               block-destructive.md line 23 (#8314 first); #8315 runs after its delta
cross-milestone (merge order, not build order): ms#442 and ms#443 merge first; ms#439 and ms#440
  after; ms#441 alongside (this release first); ms#402 unscheduled
```

G3-07: **PASS** — 0 dependency edges cross a milestone.

---

## Implementation Sequence

Single branch `release/guards-judge-every-spelling-alike`, posture **P0 (fully serial)**. Each card is its own Stage-6 spoke and pushes each coherent slice on landing.

| Step | Card | Size | Why here | Key edits (as Stage 5 and the scope-lock resolved them) |
|---|---|---|---|---|
| **0** | Commit 0 | — | The plan file, carrying the Commit-0 Survival Set | this file only — no RED fixture lands here (security rating) |
| **1** | #8314 | M | The shared primitive the other two ride or sit beside | `command-position.awk`: the six missing words, basename lookup, SPELL (A), each wrapper's option grammar from a copy of the -022 rows, and the masked exit view; a version-skew canary probe in all four consumers; the deletion hook's two exits read the exit view; the parity table's six deferral rows retired and the row-parity arms; face, precision, sentinel and single-source arms in five suites; its corpus seed block; the readiness fragments, the regenerated registry and the decision record |
| **2** | #8444 | S | Rides #8314's assignment branch (ROUTE-CANON) | transformation (e) in the canonicalizer, the declaration-builtin and append line, -023's same positions (8444c), the `AC-D020-*` arms, a neutrality arm on the deletion hook's exits, its corpus seed block, the -020 and -023 registry rows, `_cross-cutting.md` lines 49, 69 and 222 after #8314 |
| **3** | #8315 | L | Its Stage-5 delta is reviewed by the hub first | the -007 head walk and prefix locator, per class on its rung, its arms and seed block, the Command position row of its fragment, `block-destructive.md` line 23 after #8314 — as the delta resolves them |

### #8314 — change specification (the first card; Stage-5 design on #8628, the review's adopted findings on #8647)

**Mechanism (D-S5-8314, approved):** **WIDEN-CANON** — the shared canonicalizer resolves command position past a wrapper's own grammar, and the set stays a bounded enumeration.

- **Rows (D-S5-8314-ROWS):** **COPY** — each wrapper's option grammar is a field-for-field copy of the -022 rows (`script_wrapper_row()` in `core/hooks/block-destructive.sh`), asserted equal by new `WRAPROWS-PARITY-*` arms, with mutants shown live. The -022 walk's code is not edited.
- **Words (D-S5-8314-WORDS):** parity with -022 — `nice`, `stdbuf`, `timeout`, `if`, `while`, `until` join the set (11 wrappers, 9 keywords); the six `canon|…|missing` rows of `WRAP_DECL` are retired in the same commit, and `WRAPVOCAB-PARITY-M2` is re-pointed.
- **Match form (D-S5-8314-MATCH):** the basename of every prefix word.
- **Spelling (D-S5-8314-SPELL (A)):** one leading backslash and full-token quotes on a prefix word are normalized before lookup.
- **Precision (D-S5-8314-PREC):** the word-boundary git rules lose a match only where a wrapper's row consumes `git` as an option value or positional (a command that never runs git); declared as a precision improvement and pinned beside a refused control.
- **Exits (D-S5-8314-EXITS (A), from the review's CDF-1 (ii′a)):** one additive canonicalizer output mode, a quote-masked view the widening does not reach, read only by `block-rm-prefer-trash.sh`'s Step 1 `git` exemption and Step 2 no-target exit, so they keep today's verdicts with no new refuse→allow. #8122's per-segment scope is not implemented here.
- **Cap (FMF-1):** the ten-token prefix cap is kept and declared as a readiness residual with one corpus row, in the boundary form #8444's registry row uses.
- **Canary (FMF-2):** a second probe beside each consumer's one-line canary, whose output differs between the pre-change and post-change canonicalizer, so a version-skewed or corrupt row table fails closed; pinned as a suite arm per consumer.
- **Comments (FMF-4):** `core/hooks/block-destructive.sh` lines 144–148 (the PREC class falsifies "never remove one") and lines 3188–3190 (the canonicalizer's match form).
- **Precision figure (PRF-2):** stated as measured by this release's false-positive control, not inherited from ADR-227.

**Files:** `core/hooks/lib/command-position.awk`; the four consumers (`block-destructive.sh` comments and canary, `block-egress.sh` canary, `block-fs-boundary.sh` canary, `block-rm-prefer-trash.sh` canary and the two exits); the suites `block-destructive.test.sh`, `block-egress.test.sh`, `block-fs-boundary.test.sh`, `block-rm-prefer-trash.test.sh` and `command-position-fp-control.test.sh`; the corpus `core/hooks/tests/fixtures/walk-payload-corpus.txt` (its seed block, and `EG160`–`EG162` moved to refused); the fragments `_cross-cutting.md` (lines 46, 49 and 222 and the canonical-form table), `block-rm-prefer-trash.md`, `block-fs-boundary.md` (its G2 boundary and References entry) and `block-destructive.md` (line 23); the regenerated registry; the decision record and `core/ADRs/README.md`. **Complexity:** High — a shared primitive four always-on hooks read. **Commit shape:** the red arms run against the pre-change code in the worktree's hook CI layout first (G-PR4 evidence); the RED fixtures and the fix are pushed together; then the readiness text with the regenerated registry and the decision record.

**Follow-up pass (D-S6-APPEND (A), DEV-25), after all three cards were built.** The default walk recognizes the append form of a prefix assignment, `NAME+=value`, as an assignment word, with the skip, the prefix-cap count and the (e) mark a `NAME=value` word gets. The subscript and array spellings and every other indirect form stay #8652's. The exit view keeps its walk (DEV-26). The second probe of each consumer's version-skew canary puts an append-form word ahead of its wrapper, so a primitive without the form fails the hook closed. Arms in the five suites, red before the change and green after; corpus seed 11; the readiness text names the form, and the -020 and -023 registry rows route their remaining spellings to #8652 through the fragment's References block; decision 4 of the decision record names both assignment forms. **Files:** the canonicalizer, the four consumers' canary probe, the five suites, the corpus, `_cross-cutting.md`, `block-rm-prefer-trash.md`, `block-destructive.md`, the regenerated registry, the decision record and this file, each already a row of the matrix. **Commit shape:** the arms, the corpus rows, the fix and the canary in one commit, pushed together; then the readiness text with the regenerated registry, the decision record and this file.

**Walk-fix pass (D-S6-WALKS (A), DEV-29), shared with #8315.** BLOCK-DESTRUCTIVE-022's interpreter prefix walk steps over the scalar append form of a prefix assignment, `NAME+=value`, with the skip and the bookkeeping a `NAME=value` word gets (the `M-WRAP-APPEND` line), so an interpreter or `source` invocation behind it is adjudicated as its `NAME=value` twin is. An append whose value opens an array still ends the run (the `M-WRAP-APPEND-ARRAY` line), as a subscript and every other indirect form do; those stay #8652's. The predicate is spelled as BLOCK-EGRESS-007's, which #8315's half of the pass asserts. The head resolver the quoted-fragment suppression reads, `script_resolve_head()`, is unchanged: it fails closed, so the append form costs a false positive there and never an admission, and the fragment's residual list names it as a precision limit. One precision class is declared (DEV-30). Arms in the destructive suite (`BLOCK-022 append*`), red before and green after; corpus seed 12's `SW` rows; the readiness text (line 23, scope item 2 and a new item 11); the regenerated registry; and ADR-231's `## Consequences` heading, split so the ADR durability lint reads the section, nothing else in the record changed. **Files:** `block-destructive.sh`, `block-destructive.test.sh`, the corpus, `block-destructive.md`, the registry, ADR-231 and this file, each already a matrix row. **Commit shape:** the fix with its arms and corpus rows in one commit; then the readiness text with the regenerated registry, the decision record's heading and this file.

### #8444 — change specification (the second card; Stage-5 design on #8630)

ROUTE-CANON — transformation (e): a `; ` before every assignment the prefix walk skips, bound to #8314's new assignment branch by its semantics, not by a line number (the review's FMF-3 note); the declaration-builtin and append line; 8444c, the same for -023; a neutrality arm on the deletion hook's exits; the heredoc over-block declared; a named successor for `env -u PATH` / `env -S`; D-Scope-023 covering every position the change reaches. Files: `core/hooks/lib/command-position.awk`, `core/hooks/block-destructive.sh` (the -020 and -023 block), `core/hooks/tests/block-destructive.test.sh`, `core/hooks/tests/block-rm-prefer-trash.test.sh` (the neutrality arm), the corpus, `block-destructive.md` (the -020 and -023 rows), `_cross-cutting.md` (lines 49, 69 and 222, after #8314), the registry, and #8314's decision record (one decision item). Complexity: Medium.

### #8315 — change specification (the third card; Stage-5 design on #8629, delta pending)

The nine classes of the amended AC1, each on its rung; NO-ADOPT selected (the -007 walk stays its own). Files as the Stage-4 plan names them — `core/hooks/block-egress.sh` (the head walk and the prefix locator), `core/hooks/tests/block-egress.test.sh`, the Command position row of `core/rules/bypass-mode-readiness/block-egress.md`, the registry, the corpus — plus `block-destructive.md` line 23 after #8314. The delta (AR-P1: the unparseable-branch test the design did not touch; AR-P2: the fast-path gaps; AR-P3: the undeclared refused→recorded move; AR-P4: a successor whose criteria can close residuals 6 and 7b) is reviewed by the hub before this card's Stage 6, and this specification is re-read against it then. Complexity: High.

**As built, against the delta's Decision Recorded on #8629.** AR-P1 adopted (the respelled reader joined to the unchanged unparseable test by one marked `||` line, at the shipped positions only); AR-P2 adopted (the fast path tests the command with quotes and `$` removed); AR-P3 GUARD (an ANSI-C span keeps the shipped terminator; its two content movements declared); AR-P4 routed to #8650 for the unrecorded residuals, with #6195 kept for the recorded ones; and F-D1 folded in as the tenth class, a method or field flag in its attached or clustered short form, with the fragment's path-location and write-detection rows corrected. The day-one rung covers the six head-of-segment classes and the tenth; classes 6 and 7b and the behind-a-prefix forms are the named residuals. The decision record is `{{ADR:egress-respelling-takes-the-resolved-positions-rung}}`. Deviations from the design are DEV-19 to DEV-24.

**Walk-fix pass (D-S6-WALKS (A), DEV-29), shared with #8314.** The -007 head walk steps over the scalar append form of a prefix assignment with the skip and the position flag (`egress_direct=1`) a `NAME=value` word gets (the `append: walk` and `append: array` lines, spelled as BLOCK-DESTRUCTIVE-022's predicate and asserted line for line by `AC-E007-AP-PARITY`), so a write behind the form takes its twin's rung: a widening, recorded at the shipped phase. An invocation the walk reaches only behind the form advances neither first-invocation counter (the `append: hold` line, DEV-31). The other readers are unchanged, each for a stated reason: `egress_old_reachable_gh_api` and `egress_old_reachable_respelled` pass over no assignment in either spelling, by design, so the form and its twin get one verdict there; the fast path tests for the verb's letters anywhere in the command, which the form does not hide; and `egress_is_redirection`'s `{name}` test reads a named-descriptor redirection, which is no assignment. A precision class and a quoted-spelling movement are declared (DEV-32, DEV-33). Arms `AC-E007-AP*`, red before and green after; corpus seed 12's `EW` rows; the fragment's Command position row, rollout paragraph and precision paragraph; the regenerated registry. **Files:** `block-egress.sh`, `block-egress.test.sh`, the corpus, `block-egress.md`, the registry and this file, each already a matrix row. **Commit shape:** as #8314's half.

**A2 container determination, recorded rather than assumed.** Every card's decomposition is multi-file and structure-changing, so the Phase A2 threshold predicate selects the **GitHub sub-issue container**; the per-card Stage-6 sub-tasks the hub scaffolded (#8631, #8633, #8632) are that container, and the change units of each slice are listed in its spoke's output and as checklist rows in the pull-request body. No further sub-issues are created.

---

## Stage Applicability Matrix

| Card | S5 | S6 | S7 | S8 | S9 | S12 | S13 | Note |
|---|---|---|---|---|---|---|---|---|
| #8314 | ✅ (ran) | ✅ | ✅ | ✅ | release | release | release | Four consuming suites, the corpus and the false-positive control at Stage 7 |
| #8444 | ✅ (ran) | ✅ | ✅ | ✅ | release | release | release | The destructive suite and the corpus at Stage 7 |
| #8315 | ✅ (ran; delta open) | ✅ | ✅ | ✅ | release | release | release | The egress suite, the corpus and the drain at Stage 7 |

No Stage-5 skip (bias ALL; every card had an open mechanism question on a security control) and no Stage-7/8 skip (every card changes a guard's verdict). Stage 9 is release-scoped at depth **Deep**. Stages 10 and 11 are platform-satisfied (the pull-request diff; git), with the hook carrier's `--dry-run` and pre-refresh snapshot as the deployed tier's preview and rollback point. Stage 12 is release-scoped: merge, atomic claim, the release-stamped rules-mirror re-lay, the hook-tier publish per D-HookDeploy (B), hash verification. Stage 13 is release-scoped: the `G-CL10` limb owners and the 30-day outcome window; each card closes at Stage 13 when its criteria are met.

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. A shared path is listed once, under the first card that edits it; the cards that edit it are named after the verb.

```
# ── Engineering Commit 0 ──
release/releases/plans/guards-judge-every-spelling-alike_RELEASE_PLAN.md  ADD
# ── shared surfaces (serial: #8314, #8444, #8315) ──
core/hooks/tests/fixtures/walk-payload-corpus.txt  EDIT  one seed block per card, each in that card's fix commit · 8314 follow-up seed 11 · walk-fix seed 12 (8314 SW rows, 8315 EW rows)
core/rules/bypass-mode-readiness.md  EDIT  generated; regenerated in every commit that edits a fragment
core/hooks/lib/command-position.awk  EDIT  8314 WIDEN-CANON and the exit view · 8444 ROUTE-CANON transformation (e) · 8314 follow-up the append form in the default walk
core/hooks/block-destructive.sh  EDIT  8314 two comment blocks and the canary · 8444 the -020 and -023 block · 8314 follow-up the canary probe · 8314 walk-fix the -022 interpreter walk's assignment predicate
core/hooks/tests/block-destructive.test.sh  EDIT  8314 WRAP_DECL, row-parity, face and precision arms · 8444 AC-D020 arms · 8314 follow-up EXT-APPEND and canary arms · 8314 walk-fix the BLOCK-022 append arms
core/rules/bypass-mode-readiness/_cross-cutting.md  EDIT  8314 lines 46, 49, 222 and the canonical-form table · 8444 lines 49, 69, 222 · 8314 follow-up lines 49, 53 and 224
core/rules/bypass-mode-readiness/block-destructive.md  EDIT  8314 line 23 · 8444 the -020 and -023 rows · 8315 line 23 · 8314 follow-up the -020 and -023 rows and References · 8314 walk-fix line 23, scope item 2 and item 11
core/hooks/block-egress.sh  EDIT  8314 the canary · 8315 the -007 head walk and prefix locator · 8314 follow-up the canary probe · 8315 walk-fix the -007 head walk's assignment predicate and counter hold
core/hooks/tests/block-egress.test.sh  EDIT  8314 face and canary arms · 8315 its arms · 8314 follow-up EXT-APPEND and canary arms · 8315 walk-fix the AC-E007-AP arms
core/hooks/tests/block-rm-prefer-trash.test.sh  EDIT  8314 RM-ARMS and the exit sentinels · 8444 the neutrality arm · 8314 follow-up EXT-APPEND arms, exit sentinels and canary arm
core/hooks/block-rm-prefer-trash.sh  EDIT  8314 the canary and the two exits on the exit view (D-S5-8314-EXITS (A)) · 8314 follow-up the canary probe
core/ADRs/ADR-*-command-position-walks-wrapper-grammar-from-asserted-rows.md  ADD  8314 author · 8444 one decision item · 8314 follow-up decision 4's assignment forms · 8314 walk-fix the Consequences heading
core/ADRs/README.md  EDIT  8314
# ── #8314 (WIDEN-CANON; rows COPY; EXITS (A)) ──
core/hooks/tests/command-position-fp-control.test.sh  EDIT  8314 · 8314 follow-up the append-form face and pins
core/hooks/block-fs-boundary.sh  EDIT  the canary · 8314 follow-up the canary probe
core/hooks/tests/block-fs-boundary.test.sh  EDIT  8314 · 8314 follow-up EXT-APPEND and canary arms
core/rules/bypass-mode-readiness/block-rm-prefer-trash.md  EDIT  8314 · 8314 follow-up the append form in the position list
core/rules/bypass-mode-readiness/block-fs-boundary.md  EDIT
# ── #8315 (rows re-read against its Stage-5 delta) ──
core/rules/bypass-mode-readiness/block-egress.md  EDIT  8315 its rows · 8315 walk-fix the Command position row, the rollout and precision paragraphs
core/ADRs/ADR-*-egress-respelling-takes-the-resolved-positions-rung.md  ADD  8315 author
core/hooks/tests/fixtures/README.md  EDIT  8315 the twin field of a respelled row (the design's Change 9)
# ── conditional ──
core/hooks/tests/*-spelling.test.sh  ADD  CONDITIONAL:NEW-TEST-SCRIPT
core/config/allowlists/script-execution-allowlist.txt  EDIT  CONDITIONAL:NEW-TEST-SCRIPT
```

#### Read-only inputs

```
core/ADRs/ADR-187-command-position-is-a-canonicalizer-not-a-parser.md  READ
core/ADRs/ADR-226-egress-prefix-walk-stops-on-the-gated-verb.md  READ
core/ADRs/ADR-227-script-wrapper-walk-reads-option-grammar-from-rows.md  READ
core/hooks/tests/setup-ci-layout.sh  READ
core/deploy/tools/build-hook-registry.py  READ
docs/scripts/setup-workspace.sh  READ
.github/workflows/repo-integrity.yml  READ
```

The repository-root `update.sh` is read as well (the carrier it delegates to is the Stage-12 publish), and it is named here rather than in the fence, because the fence's path recogniser reads module-prefixed paths only.

#### Release-wide explicit non-scope

```
core/deploy/deploy.sh  NOT EDITED
core/hooks/tests/test-runner.sh  NOT EDITED
core/hooks/tests/hook-fail-closed.test.sh  NOT EDITED
```

**The Stage-4 conditional rows are resolved at this commit.** WIDEN-CANON fired, so the canonicalizer and the false-positive control are unconditional. RE-HOME did not fire, yet both hooks it named are edited on another basis, and each is promoted with that basis stated: `block-rm-prefer-trash.sh` for the masked exit view (D-S5-8314-EXITS (A)) and the canary, `block-fs-boundary.sh` for the canary (the review's FMF-2). FS-ARMS and RM-ARMS fired. ADR-S5 fired: the record is named by a glob because its number binds at the Stage-12 claim (§ Deviation Log DEV-10). ROUTE-CANON fired for #8444, so the canonicalizer row names both cards. NEW-READER does not fire for #8314 or #8444 — their rows name guards whose suites already read the corpus — and stays conditional for #8315's delta. NEW-TEST-SCRIPT stays conditional for #8315's delta: #8314's design adds no suite, and the allowlist's existing globs already admit any new `*.test.sh` (its design finding 13).

**At #8315's slice** the two remaining conditions resolve. NEW-READER does not fire — the egress suite's existing corpus reader grades the new rows — so the fixtures README row is promoted on another basis, the design's Change 9 (the twin field of a respelled row). NEW-TEST-SCRIPT does not fire — the slice adds its arms to the existing egress suite — so the `*-spelling.test.sh` and script-execution allowlist rows stay unmet conditionals. The decision record's row is added as #8315's `ADD`, named by a glob for the reason DEV-10 gives.

**Non-scope reasons.** `deploy.sh`: ms#442 and ms#402 (#6195) own it, and the parity arms belong in a suite. `test-runner.sh`: the runner, edited by ms#402 (#6193). `hook-fail-closed.test.sh`: it co-locates the shipped canonicalizer by copy and needs no change for the canary. The -022 blocks of `block-destructive.sh` (ms#439, ms#440) and the egress drain writers (ms#402 #6194) are untouched regions of files this release edits. `.github/workflows/repo-integrity.yml` holds the SIGPIPE-lint wrapper list the parity table reads, and is read only.

**Zero `ADD` rows for executables** unless NEW-TEST-SCRIPT fires (then its allowlist row and CI wiring ship in the same release). **No path is renamed, moved or deleted** → the mover set is empty.

### Agent-Editability Read

Transcribed from the Stage-4 derivation (controls read at `f8d88626`) and re-applied to the rows promoted at this commit. The Tier-0 floor's surviving union is the basenames `CLAUDE.md`, `OPERATIONS.md` and `RELEASE_PROTOCOL.md`; no matrix path carries one. The sanctioned-session gate's first conjunct needs a `*/skills/<name>/` segment; no matrix path carries one.

| Card | Write-set paths | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| Commit 0 | this file | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #8314 | the canonicalizer · the four consumers · five suites · the corpus · four fragments · the registry · the decision record · the ADR index | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #8444 | the canonicalizer · `block-destructive.sh` · two suites · the corpus · two fragments · the registry · #8314's decision record | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #8315 | `block-egress.sh` · its suite · the corpus · two fragments · the registry (re-read against its delta) | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |

**Outside this read (not a Write/Edit payload):** the Stage-12 hook-tier publish writes the workspace's deployed hook tier, which the Tier-0 floor covers; that is why D-HookDeploy was an operator decision, rendered (B).

---

## Contention Map

**Within release (serial P0 order resolves every row):**

| File | Cards | Overlap class | Resolution |
|---|---|---|---|
| `core/hooks/tests/fixtures/walk-payload-corpus.txt` | all three | append-pattern (one seed block each) | each card appends its block in its own fix commit; ids card-scoped and unique across the file |
| `core/rules/bypass-mode-readiness.md` (generated) | all three | MULTI-WAY | regenerated in every commit that touches a fragment; never hand-merged |
| `core/hooks/lib/command-position.awk` | #8314, #8444 | BINARY (#8444 patches #8314's restructured walk) | #8314 first; #8444 binds transformation (e) to the assignment branch by its semantics |
| `core/rules/bypass-mode-readiness/_cross-cutting.md` | #8314, #8444 | line-range overlap on lines 49 and 222 | #8314 first; #8444 appends its qualifier sentence to the rewritten lines |
| `core/rules/bypass-mode-readiness/block-destructive.md` | #8314 (line 23), #8444 (the -020 and -023 rows), #8315 (line 23) | MULTI-WAY | serial; #8315 appends to #8314's line-23 text |
| `core/hooks/tests/block-destructive.test.sh` | #8314, #8444 | BINARY, disjoint regions | serial |
| `core/hooks/block-egress.sh` · `core/hooks/tests/block-egress.test.sh` | #8314 (canary, face arms), #8315 (the walk, its arms) | BINARY, disjoint regions | serial |
| `core/hooks/tests/block-rm-prefer-trash.test.sh` | #8314, #8444 | BINARY | serial |
| the decision record | #8314 (author), #8444 (one decision item) | BINARY | serial |

**Across milestones:**

| Sibling | Shared surface | Class | Resolution |
|---|---|---|---|
| ms#441 (#8322) | `block-fs-boundary.md` line 49 (the G2 coverage boundary is one physical line) and its References lines; `block-fs-boundary.test.sh`; the registry | line-range overlap, certain | this release first; ms#441 rebases and re-applies its sentence to the rewritten line; its hub was told at Stage 4 (AI-001) |
| ms#439, ms#440 | `block-destructive.sh` (-022 blocks against this release's comments and the -020 block, disjoint); its suite; the corpus (end-of-file appends); `block-destructive.md` line 23; the registry | append-pattern and disjoint ranges | this release first; they rebase; corpus ids unique across the file; AI-006 at Stage 9 |
| ms#402 (#6194) | `block-egress.sh` (drain writers against the canary and the -007 walk); its fragment; its suite | disjoint ranges and one semantic seam (a new look-ahead row joins the drain) | the second merger rebases; #8315 names the drain population of any new look-ahead row |
| ms#442 (#8645) | no path in this matrix; the version slot; Check 38 turning blocking | Tier-S and soft | merges first; this release rebases and regenerates the registry |
| ms#443 (#8646) | `core/ADRs/README.md` and the ADR number its record holds branch-locally (229); the Stage 7/8/9 filing rules | ADR-number axis and soft | merges first; this release's record is renumbered at the Stage-12 bind if it does (ADR-181); the README line merges by hand |

---

## Cross-PR Overlap Audit

### Baseline SHA

`f8d8862668aa373a37f36f309c54eb364fae2d9b` — the Stage-4 Phase A0 pin, re-read unchanged by all three Stage-5 designs and at this commit, and the Commit-0 base: the release branch is cut from exactly this commit.

### In-Flight Release Roster

**Measured at:** `f8d88626` · `2026-11-04T00:53Z` (Engineering Commit 0) · **Population:** n=2 sibling(s)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `required-checks-enforce-as-declared` | #8645 | `c635ba9c` | minor | `v4.82` | `v4.82` | — (its 11 files include `core/deploy/deploy.sh`, which this release does not edit) |
| `releases-file-only-the-follow-ups-that-matter` | #8646 | `30be0e71` | major | `v5.00` | `v5.00` | `core/ADRs/README.md`; and the ADR number 229, which its new record holds branch-locally |

Probe: open pull requests, limit 200 → 2, both `release/*` heads in draft (control: the same reader on merged pull requests, limit 3 → 3); each sibling's file list read whole (11 and 50 files) and intersected with this matrix by a path-prefix scan (sensitivity: the scan returns `core/deploy/deploy.sh` for #8645, a path it was built to find). The recomputed next-free values come from the adapter's own dry-run allocation at this base. This is a pinned measurement with no verdict; Stage 9 Phase A6.6 re-measures it.

### Structural sub-audit

No file is renamed, moved or deleted, so the mover set is empty. `SURFACE(R)` = {`Δversion/4.82.0`}. ms#442 carries the same token (a Tier-S serialization point, resolved by the recorded merge order and the atomic claim); ms#443 mints `Δversion/5.0.0`. Stage 9 entry re-runs `git log f8d88626..origin/main --name-status --find-renames` against `SURFACE(R)`.

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R-1 | The canonicalizer change has a four-hook blast radius with no rollout phase; legitimate commands can move to refuse in always-on hooks | Med | High | A differential in both directions: the false-positive control extended per face with its arming sentinel; the corpus allow rows; the four suites at or above their pin totals; Stage 9 Deep | Stage 6/7 |
| R-2 | A canonicalizer defect breaks the canary, so the four hooks deny every Bash call on the deployed tier | Low | High | The canaries stay suite arms; the publish is operator-authorized with the carrier's pre-refresh snapshot and `--restore-hooks`; a fresh-session probe runs before anything relies on the new tier | Stage 12 |
| R-3 | -007 phase trap: a #8315 spelling fixed as a widening lands at `shadow`, so AC1 reads green on paper only | Med | Med | Per-class rung decided at Stage 5 and its delta; corpus rows recorded `B` | Stage 5/8 |
| R-4 | `WRAP_DECL` goes stale when the six words join the canonicalizer, and the parity arms fail | Certain | Low | The six rows retire in #8314's fix commit (CIAC-3) | Stage 6 |
| R-5 | A fragment edited without regenerating the registry trips Check 38, which blocks once ms#442 has merged | High | Med | Regenerate in the same commit; `build-hook-registry.py --check` before each push (CIAC-4) | Stage 6 |
| R-6 | Newline-bound classes (#8315 ×2) cannot be corpus rows | Certain | Low | Suite arms beside plain-form controls | Stage 6 |
| R-7 | Cross-milestone contention, certain with ms#441 on one physical line; also ms#439, ms#440, ms#402 and ms#443 (the ADR index) | High | Med | Serialize at merge in the recorded order; the later merger rebases by hand; Stage 9 A6.5 and Stage 12 B1.1 sweeps | Hub |
| R-8 | Corpus id collisions with the ms#439/#440 rows after the second merge | Med | Low | Card-scoped id prefixes, re-checked unique at rebase | Stage 6/12 |
| R-9 | Version slot: ms#442 holds the same provisional `v4.82` | High | Low | Expected: the atomic claim binds; `v5.01` expected | Hub |
| R-10 | The hook-tier publish meets the read-only primary and the Tier-0 floor | Certain | Med | D-HookDeploy (B) rendered, with a user-side fallback on a Tier-0 refusal | Operator / hub |
| R-11 | Spokes run under the deployed pre-change hooks: payload text can trip them, and a suite run outside the runner reads false failures | High | Med | Fixtures authored with the Write and Edit tools; measurement only through `bash .claude/hooks/tests/test-runner.sh` after `bash core/hooks/tests/setup-ci-layout.sh`, both from the worktree root; never against the deployed tier | Each spoke |
| R-12 | Suite wall clock exceeds a foreground call (about 18 minutes for the whole harness) | High | Med | The runner in the background with a completion notice; single suites where one answers the question | Stage 6/7 |
| R-13 | ms#443 changes the Stage 7/8/9 filing rules before this release reaches them | Med | Low | Each stage applies the rules in force at its entry | Hub |
| R-14 | The usage window and host-API pools are shared with two sibling hubs | High | Med | Checkpoint B at every launch | Hub |
| R-15 | The case-variant command class is cross-hook | Med | Med | #8315 disposes the -007 instance; the class is routed (AI-002) | Operator |
| R-16 | -023 shares -020's anchored-assignment shape, so ROUTE-CANON moves its wrapped spellings to refuse | Certain under ROUTE-CANON | Low | D-Scope-023 (A): declared as a tightening | #8444 |
| R-17 | Rollback re-opens every closed spelling across four hooks, and a revert must itself be republished | Low | Med | Per-card commits; revert, republish, verify by hash; the tag is retained | Operator |
| R-18 | Latency: the option-grammar walk adds per-call cost to four always-on hooks | Med | Low | Stage 7 times the canonicalizer against the pin | Stage 7 |
| R-19 | Size drift (#8315 grew from six classes to nine) | Realized | Low | Re-sized M → L at the scope-lock; 18 effective, in band | Closed |
| R-20 | The deletion hook's two allow exits read the canonical text, so any widening of it turns refusals into allows (the design's AC2 precondition) | Certain without a remedy | High | D-S5-8314-EXITS (A): the exits read the exit view; `EXT-RA-T*` sentinels pin the vectors, each paired with a mutant that restores the widened read | #8314 |
| R-21 | #8315's delta is unresolved while #8314 and #8444 build | Med | Med | The partial scope-lock: #8315 runs third, after the hub reviews the delta; its rows here are re-read then | Hub |

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8314 × #8444 on BLOCK-DESTRUCTIVE-020's condition-position spelling, `core/hooks/block-destructive.sh` and `core/hooks/lib/command-position.awk`):** a PATH assignment at a compound-command condition position is refused by -020 in the integrated release, whichever card's mechanism carries it. *Method:* `grep -c -F "AC-D020-COND" core/hooks/tests/block-destructive.test.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.* The suite's CI run grades the arm's behaviour; the label is 0 at the pin.
- [ ] **CIAC-2 (#8314 × #8315 × #8444 on the tracked differential corpus `core/hooks/tests/fixtures/walk-payload-corpus.txt`):** all three cards' spelling rows live in the one tracked corpus, each card in its own provenance-headed seed block. *Method:* `grep -c -E "^# --- seed [0-9]+: card #(8314|8315|8444)" core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 3. *Graded at Stage 9 QC3.5 on the merged PR.* It reads 0 at the pin, while 4 existing card blocks match the same pattern shape. The readers' `*CORPUS-REC-*`, `-TWIN`, `-OPEN` and `-ROWS` arms grade the verdicts in CI.
- [ ] **CIAC-3 (#8314 × #8315 on the wrapper vocabulary's parity table in `core/hooks/tests/block-destructive.test.sh`):** after both walks change, no parity declaration still defers a canonicalizer gap to this release's cards. Each surviving difference carries a live reason. *Method:* `grep -c -F "its gaps are routed to their own card" core/hooks/tests/block-destructive.test.sh` expect 0. *Graded at Stage 9 QC3.5 on the merged PR.* Control on the same file: the four launcher declarations the table must keep read 4 at the pin; the subject reads 6 there.
- [ ] **CIAC-4 (#8314 × #8315 × #8444 on the readiness fragments and the generated registry):** every verdict the three cards record in their fragments is carried unchanged by the regenerated registry. *Method:* declared, verification deferred to core/rules/bypass-mode-readiness.md *Graded at Stage 9 QC3.5 on the merged PR.*

The CIAC lint on the Stage-4 body read `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`; it is re-read on this committed file at Stage 6 A1 (§ Verification Evidence) and at Stage 9 A3.6.

---

## Verification Plan

### Per-Issue Verification

Method classes: a runnable probe where one exists; a named read of a named surface; or the declared-deferred form where the grading arm belongs to a later slice. Suite-graded rows are executed by the documented runner at Stage 7 and by the PR's CI hook-test job, not by the plan verifier. **#8314's rows are bound to label-presence probes at this commit**, now that its Stage-5 design has named the arms; each of the other cards' deferred rows is bound by that card's own slice. Every red-before arm's run on the pre-change code is kept as executed evidence: G-PR4 accepts a control only once it is seen acting.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8314 | AC-1a | `grep -c -F "EXT-POS-D16" core/hooks/tests/block-destructive.test.sh` at least 1 | the last destructive face arm is present (0 at the Commit-0 base); the suite's CI run grades `EXT-POS-D6`..`-D16` beside the already-refused plain form |
| #8314 | AC-1b | `grep -c -F "EXT-POS18" core/hooks/tests/block-rm-prefer-trash.test.sh` at least 1 | the deletion hook's face arms `EXT-POS11`..`18` are present (0 at the base) |
| #8314 | AC-1c | `grep -c -F "EXT-POS-F12" core/hooks/tests/block-fs-boundary.test.sh` at least 1 | the filesystem-boundary face arms `EXT-POS-F5`..`F12` are present (0 at the base) |
| #8314 | AC-1d | `grep -c -F "EXT-POS-E11" core/hooks/tests/block-egress.test.sh` at least 1 | the egress face arms `EXT-POS-E5`..`E11` are present (0 at the base) |
| #8314 | AC-2a | `grep -c -F "EXT-RA-T5" core/hooks/tests/block-rm-prefer-trash.test.sh` at least 1 | the refuse→allow sentinels are present, each paired with its restored-read mutant (0 at the base) |
| #8314 | AC-2b | `grep -c -F "N_DECLARED" core/hooks/tests/command-position-fp-control.test.sh` at least 1 | the false-positive control counts a declared tightening apart from a newly-blocked payload (0 at the base) |
| #8314 | AC-2c | [DEFERRED — runner .claude/hooks/tests/test-runner.sh at Stage 7 and on the CI hook-test job] | zero refuse→allow and zero undeclared allow→refuse movements: the destructive, egress, fs-boundary and rm-prefer-trash suites at FAIL 0 with Totals of at least 1417 / 413 / 159 / 118 plus the slice's arms; `command-position-fp-control.test.sh` newly-blocked 0, Total at least 59 · control: the control's arming sentinel and `WALKCORPUS-DET-fires` read non-zero in the same run |
| #8314 | AC-3 | `grep -c -F "CMDPOS-SINGLE-SOURCE-01" core/hooks/tests/command-position-fp-control.test.sh` at least 1 | the single-source arm is present (0 at the base); it fails when any of the four consumers resolves command position through anything but `lib/command-position.awk` |
| #8314 | AC-1e | `grep -c -F "EXT-APPEND-D1:" core/hooks/tests/block-destructive.test.sh` at least 1 | the follow-up pass (D-S6-APPEND (A)): the destructive face arm is present (0 at `27ce7836`); the suite's CI run grades the verb rule (`EXT-APPEND-D1`..`-D5`) and -020 and -023 (`EXT-APPEND-D020-*`, `-D023-*`) reached through the append form of a prefix assignment, each beside its `NAME=value` control, with the near misses (`EXT-APPEND-NEAR-*`) at today's allow and the declared precision pin (`EXT-APPEND-PREC`, DEV-27) beside its refused control |
| #8314 | AC-1f | `grep -c -F "EXT-APPEND-E1:" core/hooks/tests/block-egress.test.sh` at least 1 | the egress arm beside its `NAME=value` control (0 at `27ce7836`) |
| #8314 | AC-1g | `grep -c -F "EXT-APPEND-F1:" core/hooks/tests/block-fs-boundary.test.sh` at least 1 | the filesystem-boundary arm beside its `NAME=value` control (0 at `27ce7836`) |
| #8314 | AC-1h | `grep -c -F "EXT-APPEND-T1:" core/hooks/tests/block-rm-prefer-trash.test.sh` at least 1 | the deletion arm beside its `NAME=value` control (0 at `27ce7836`) |
| #8314 | AC-2d | `grep -c -F "EXT-APPEND-XV-LIVE" core/hooks/tests/block-rm-prefer-trash.test.sh` at least 1 | the two allow-on-match exits keep the exit view's walk (0 at `27ce7836`): the four `EXT-APPEND-X*` sentinels refused, the exit view byte-identical with and without the change, and each sentinel allowed through a copy whose exit view takes the form (DEV-26); the both-direction differential in § Verification Evidence (#8314 follow-up pass) is re-measured at Stage 7 by its named command over its two named commits |
| #8314 | AC-1i | `grep -c -F "BLOCK-022 append: VAR+=v before bash" core/hooks/tests/block-destructive.test.sh` at least 1 | the walk-fix pass (D-S6-WALKS (A)): the -022 interpreter walk's append-form arms are present (0 at `cdfd06e9`); the suite's CI run grades the `BLOCK-022 append*` arms — the must-flag arms beside their `NAME=value` controls in the assignment-prefix block, the near misses at today's allow (an array append among them), the declared precision class beside its twins (DEV-30) and the head resolver's pinned limit — and corpus seed 12's `SW` groups |
| #8314 | AC-2e | [DEFERRED — runner, as AC-2c] | the walk-fix pass's both-direction differential over the destructive hook, re-measured at Stage 7 by the command in § Verification Evidence (walk-fix pass): allow→refuse and allow→record only for the append-form class, refuse→record and record→allow only for the declared precision class, and nothing else |
| #8315 | AC-1 | `grep -c -F "AC-E007-SP-M4" core/hooks/tests/block-egress.test.sh` at least 1 | the tenth class's last arm is present (0 at the Commit-0 base); the suite's CI run grades each class's `AC-E007-SP-*` arm beside the refused plain-form control `AC-E007-W1p` and corpus row EG100 — each of the six head-of-segment classes and the tenth refused on the day-one rung, the residuals at their declared verdicts with #8650 and #6195 their named successors for this card's Stage 9 GO; a shadow record is not a refusal |
| #8315 | AC-1b | `grep -c -F "AC-E007-AP-1:" core/hooks/tests/block-egress.test.sh` at least 1 | the walk-fix pass (D-S6-WALKS (A)): the -007 head walk's append-form arm is present (0 at `cdfd06e9`); the suite's CI run grades the `AC-E007-AP*` arms — the form recorded beside its `NAME=value` control, the counter hold (DEV-31) through its copy without the hold, the precision class (DEV-32) and the quoted spelling (DEV-33) beside their twins, the near misses, the untokenizable pin and the predicate-parity arm — and corpus seed 12's `EW` groups |
| #8315 | AC-2 | [DEFERRED — runner, as #8314 AC-2c] | no refused or allowlisted write moves to allow except a declared precision improvement, and no allow row moves to refuse undeclared · control: `EGRESSCORPUS-DET-counter-fires` and `EGRESSCORPUS-DET-lookahead-fires` read non-zero |
| #8315 | AC-2b | [DEFERRED — runner, as AC-2] | the walk-fix pass's both-direction differential over the egress hook, re-measured at Stage 7 by the command in § Verification Evidence (walk-fix pass): allow→record only for the append-form class, the quoted spelling included, refuse→allow only for the declared precision class, no day-one refusal withdrawn, and nothing else |
| #8315 | AC-3 | [DEFERRED — runner .claude/hooks/tests/test-runner.sh at Stage 7 and in CI] | `block-egress.test.sh` FAIL 0, Total at least 413 (its Total at the pin) plus the arms the release adds — read at #8315's slice as the entry Total 423 plus this card's 105 arms, 528; after #8314's follow-up pass, 531; after the walk-fix pass, 556 (19 `AC-E007-AP*` arms and 6 corpus groups) |
| #8444 | AC-1 | `grep -c -F "AC-D020-WRAPABS" core/hooks/tests/block-destructive.test.sh` at least 1 | the absolute-path wrapper arm is present (0 at the Commit-0 base); the suite's CI run grades every `AC-D020-*` spelling arm beside the refused plain-form controls and the allowed near misses — each arm the fix moves red on the pre-fix hook, as the slice's kept red-before run records — and the declared residuals at their declared verdicts, each an operator-accepted residual with a named successor at this card's Stage 9 GO; CIAC-1 binds `AC-D020-COND` |
| #8444 | AC-2 | Named read: the -020 row of the rule registry in `core/rules/bypass-mode-readiness/block-destructive.md` and its copy in the generated registry | the row states a verdict for each spelling AC-1 names |

**AC baseline** — the criterion counts as read from the card bodies at their D-Crisp revisions (2026-11-03), against the Stage-4 pin; D-Crisp kept every ordinal in place. A count that no longer matches this line is the mechanical signal to re-bind the affected rows.

`ac_baseline: { #8314: 3, #8315: 3, #8444: 2, read_at: f8d8862668aa373a37f36f309c54eb364fae2d9b }`

The face list in #8314's AC-1 is the amended one: a wrapper's separate-argument option (and, as its design measured, a wrapper flag that takes no argument); an absolute-path wrapper; each named wrapper missing from the bounded set (`nice`, `stdbuf`, `timeout`); and the `if`/`while`/`until` condition position.

### Release-Level Verification

- [ ] **File integrity:** the delivered diff matches the unconditional rows, and every fired conditional is promoted.
- [ ] **Hook suites:** the runner reads FAIL 0, with each suite's Total at or above the pin plus the arms added. **Corpus identity:** `sha256` and row counts recorded at Stage 7 and Stage 9. At the pin: `74be7ed0…5789`, 1,313 rows (1,003 destructive with 17 `open`; 310 egress with 13 `open`).
- [ ] **Registry freshness:** Check 38 passes on the release head, and again after the rebase over ms#442.
- [ ] **CIACs:** CIAC-1 to CIAC-4.
- [ ] **Stage-12 instance verification:** after the publish, each deployed edited file under the workspace hook tier equals its merged source by SHA-256 — `lib/command-position.awk`, `block-destructive.sh`, `block-egress.sh`, `block-fs-boundary.sh`, `block-rm-prefer-trash.sh`, and the deployed script-execution allowlist under NEW-TEST-SCRIPT. The sensitivity arm is the pre-publish baseline, equal to the pre-merge sources (first 12 hex at the pin: awk `9b8fb81edcb3`, destructive `d9ce4771ae4b`, egress `172cb4074ca7`, fs-boundary `1c7cbc11b3ca`, rm-prefer-trash `7f31858dcf8a`). Then fresh-session probes: a plain-form guarded command refused, a benign command allowed. The workspace tier is the only one on this workspace.

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential, dependency- and contention-ordered: posture **P0** |
| **Commit strategy** | Engineering Commit 0 (this plan only). Then per card: the red arms run against the pre-change code in the worktree's hook CI layout and kept as executed evidence (G-PR4); the RED fixtures and the fix committed and pushed together, never a failing-fixture commit pushed ahead of its fix; then the readiness text with the regenerated registry (and, for #8314, the decision record). Messages carry the `release(guards-judge-every-spelling-alike):` prefix and a reference-only `(#N)` |
| **Review approach** | One PR for the milestone (topology **SINGLE**), draft until the Stage 9 gate |
| **Rebase** | Before Stage 12, after ms#442 and ms#443 have merged: the hub brings `main` into the branch, re-runs Check 38 and the harness on the new head, and re-derives D-Version |
| **Deployment mechanism** | Git merge. Then Stage-12 B4 re-lays the release-stamped rules mirror (no mirror member changes; `bypass-mode-readiness.md` is not a member). Then the hook-tier publish per **D-HookDeploy (B)**, through the carrier `docs/scripts/setup-workspace.sh --refresh-hooks` (which `./update.sh` delegates to), sourced from the primary checkout once it is fast-forwarded to the merge. No skill package changes |
| **Stacked-base cleanup posture** | Not applicable under SINGLE |

The PR body is parser-clean: the three cards carry a close keyword only in the PR body's dedicated Issue References block; no close-family verb precedes an issue number anywhere else in the body, the title or any commit message.

---

## Rollback Strategy

| Path | When | Steps | Complexity |
|---|---|---|---|
| Per-card revert (pre-merge) | one card misbehaves on the branch | `git revert` that card's run of commits (linear history); re-run the runner. #8314's exit view and its widening land in one commit, so they revert together | Low |
| Partial revert (post-merge) | one card misbehaves after the merge | a fix branch reverting that card; republish the hook tier; verify by hash | Medium (#8314 reopens all four hooks' faces) |
| Full restore | a refusal storm or a fail-closed loop on the instance | operator: `docs/scripts/setup-workspace.sh --restore-hooks` from the pre-refresh snapshot (`--list-hook-snapshots`) for immediate relief; then revert the merge commit and republish; the version tag is never deleted | MODERATE overall |
| Forward fix | a narrow, understood defect | a fix branch through the pipeline | Low |

Ordering: never revert the deletion hook's exit-view read while the widened canonicalizer stays deployed; they ship in one commit for that reason. A partial ship of the words without the rows is safe for AC2 only with the exit view in place.

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A, transcribed from Stage 4)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 3 · Stage 7: 3 · Stage 8: 3
**Per-spoke cost estimate:** ordinal band by size — 1 × `size:L` (moderate–high), 1 × `size:M` (low–moderate), 1 × `size:S` (lowest) (source: heuristic). Stage 7 spokes also hold an about-18-minute harness run, which is wall clock, not draw
**Assumed/stated remaining usage-window envelope:** UNSTATED; two sibling hubs share the account
**Estimated cumulative draw % (worst parallel batch):** about 15 % of one window for three spokes [ASSUMPTION – CONFIRM — a projection from an observed per-spoke figure, not a measurement]
**Routing:** PASS: proceed; Stage 6 is serial and does not batch
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API quota, which this plan-time estimate deliberately does not read. Bands and the cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**Class: `cross-cutting`** — re-rendered from `novel` at the Collective Review scope-lock. The named tripwire recorded in the predecessor release's plan ("if a later decision moves the wrapper vocabulary into the canonicalizer, re-render to `cross-cutting`") is met: #8314's WIDEN-CANON moves the -022 wrapper words and a copy of its option rows into the shared canonicalizer, with a four-hook blast radius. The taxonomy's formal triggers (a) and (b) do not fire; the re-render is cheaper-to-stricter. `effective_pts: 14 × 1.3 = 18`, inside the 15–25 target band. Posture: engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.

---

## Release Outcome Statement

Transcribed from the milestone description at Engineering Commit 0.

**AFTER** — A guarded command gets the same verdict however it is written. The shared command-position canonicalizer reaches the guarded verb behind a transparent wrapper's own options, an absolute-path wrapper, a wrapper outside its set and a compound-command condition position, so the anchored rules of the four hooks that consume it refuse what they refuse in plain form. The egress rule's own walk and the PATH-manipulation rule judge their alternate and wrapped spellings the same way.

**BEFORE** — The canonicalizer stops at a wrapper's first flag and omits several wrappers and the condition positions, so an anchored credential-read rule admits behind a wrapper what it refuses plainly, with no rollout phase to soften it. BLOCK-EGRESS-007's private walk admits six alternate spellings of a write its day-one deny refuses. BLOCK-DESTRUCTIVE-020 refuses a prefix-form PATH assignment and lets the same assignment through when it is handed to a wrapper.

**Actor(s):** any session whose commands pass through the guards; the deployed hook bundle.

**Success Indicator:** every member's must-refuse arms pass beside a plain-form control on a tracked differential corpus, and no corpus allow row changes verdict except a declared precision improvement; one PR for the milestone; at Stage 12 the deployed copies of every edited hook equal the merged sources.

**Limb owners:** the canonicalizer reaches the guarded verb behind a wrapper's own options, an absolute-path wrapper, a wrapper outside its set and a condition position, so the four consuming hooks' anchored rules refuse what they refuse in plain form → #8314 · the egress rule's own walk judges its alternate and wrapped spellings as it judges the plain form → #8315 · the PATH-manipulation rule judges a wrapped or otherwise respelled assignment as it judges the prefix form → #8444

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | every edited hook under `core/hooks/` (`block-destructive.sh`, `block-egress.sh`, `block-fs-boundary.sh`, `block-rm-prefer-trash.sh`) and `core/hooks/lib/command-position.awk` | the instance's deployed hook tier under the workspace root's `.claude/hooks/` | the hook carrier (`docs/scripts/setup-workspace.sh --refresh-hooks`, which `update.sh` delegates to), run per D-HookDeploy (B) | SHA-256 of each deployed copy equals the merged source, then the fresh-session probes |
| 2 | `core/rules/bypass-mode-readiness.md` and its fragments | none — not a rules-mirror member | repository content only | Check 38 on the release head |

**`deliverable_state: deployed-copy-synced`** for the hook sources (row 1, at Stage 12); the readiness text and the decision record ship as repository content.

### Schema Migrations

N/A — enumerated over the corpus row format (unchanged: seven fields; new rows use the existing verdict classes), the block-log and drain row shapes (unchanged), and the hook registry's generated structure (unchanged); none migrates. The canonicalizer gains one output mode that only its new reader requests; its default output keeps its format.

---

## Deviation Log

| ID | Departure from the Stage-4 comment (or from a design) | Decision or authority that caused it | Status |
|---|---|---|---|
| **DEV-01** | Release Class `novel` → **`cross-cutting`**; engagement density Standard → Tight; `effective_pts` recomputed (14 × 1.3 = 18) | Collective Review scope-lock, D-ReleaseClass | **APPLIED** — header, § Release Class declaration |
| **DEV-02** | #8315 re-sized **M → L**: 14 raw / 18 effective (the Stage-4 plan read 10 raw / 12 effective) | Collective Review scope-lock, Size | **APPLIED** — § Scope |
| **DEV-03** | **The Stage-4 "RED fixtures at Commit 0" instruction is superseded.** Commit 0 is this plan file only. Each card's RED fixtures (its corpus seed block, with card-scoped ids, and its suite arms) land in that card's own fix commit, after a red-before run in the worktree recorded as executed evidence (G-PR4). The Stage-4 Implementation Sequence, Delivery Strategy and Contention Map rows that placed all three seed blocks at Commit 0 are re-written to match. Instruction 4 of sub-task #8631's body and the milestone description's internal-sequence line predate the render and are not followed on this point | Collective Review scope-lock, Security rating (Security-relevant bug) | **APPLIED** |
| **DEV-04** | **#8314's design inputs, as the scope-lock adopts them:** WIDEN-CANON; rows COPY with `WRAPROWS-PARITY`; word parity with the six `WRAP_DECL` deferral rows retired; basename lookup; the PREC class declared and pinned beside a refused control; SPELL (A); the masked exit view (the review's CDF-1 (ii′a)) for the AC2 precondition, in place of the design's recommended (i) (#8122 into the milestone, forbidden under the Composition Lock) and its fallback (ii) (a raw read, which the review's PRF-1 measured to admit a quoted-content refuse→allow); the prefix cap declared (FMF-1); the version-skew canary (FMF-2); the `block-destructive.sh` 144–148 comment (FMF-4); the precision figure measured, not inherited (PRF-2) | Collective Review scope-lock: D-S5-8314-EXITS (A) and "remaining design decisions approved as recommended"; the hub's Stage-6 brief | **APPLIED** at #8314's slice |
| **DEV-05** | **Two hooks promoted on a basis other than their Stage-4 condition.** RE-HOME did not fire, yet `core/hooks/block-rm-prefer-trash.sh` is edited (the canary, and Step 1 and Step 2's exits on the exit view) and `core/hooks/block-fs-boundary.sh` is edited (the canary). Each is promoted with its real basis, per the plan-authoring contract's converse rule | D-S5-8314-EXITS (A); the review's FMF-2 | **APPLIED** — § File Change Matrix |
| **DEV-06** | **#8444's route is ROUTE-CANON:** the canonicalizer row names both cards; D-Scope-023 (A) applies, so -023's wrapped spellings move to refuse as a declared tightening; the neutrality arm adds `block-rm-prefer-trash.test.sh` and #8314's decision record to #8444's write set; `_cross-cutting.md` line 69 joins it | Collective Review scope-lock (#8444 bullets); Stage-4 D-Scope-023 (A) | **APPLIED** — rows; built at #8444's slice |
| **DEV-07** | **Partial scope-lock for #8315:** its Stage-5 design is re-opened on #8629 for a bounded delta (AR-P1..AR-P4). Its rows here stay as the Stage-4 plan wrote them and are re-read at its slice against the delta the hub reviews. NO-ADOPT is selected, so the Stage-4 `_cross-cutting.md` line-55 row (ADOPT-CANON only) does not fire | Collective Review scope-lock, #8315 Blocker (A) | **APPLIED** at #8315's slice, against the delta's Decision Recorded on #8629 (§ Implementation Sequence) |
| **DEV-08** | **Shared-line write-set additions and their order:** `_cross-cutting.md` lines 49 and 222, #8314 then #8444; `block-destructive.md` line 23, #8314 then #8315. The Stage-4 Contention Map carried neither | Collective Review scope-lock, Write sets and serialization | **APPLIED** — § Contention Map |
| **DEV-09** | **NEW-READER and NEW-TEST-SCRIPT stay conditional** for #8315's delta: #8314 and #8444 add rows only for guards whose suites already read the corpus, and #8314's design adds no suite (its finding 13 also records that the allowlist's existing globs admit a new `*.test.sh`) | #8314's and #8444's Stage-5 designs | **APPLIED** — § File Change Matrix; resolved at #8315's slice, where neither fires |
| **DEV-10** | **The decision record's number.** Next-free on the mainline is 229 (`release/tools/renumber-adr.py --detect` at this commit: anchor 228, next-free 229), and ms#443's open PR holds 229 branch-locally. The record is authored with the mainline next-free in its filename, cited everywhere by its slug token, and renumbered at the Stage-12 bind if ms#443 merges first (ADR-181); the matrix names it by a glob so a renumber does not stale the row | ADR-181; #8314's design § ADR Pointers | **APPLIED** |
| **DEV-11** | **The Phase A1–A2 checkpoint** the Stage-6 spec places before B1 is presented after the fact, in the spoke's output: the hub's brief directs Engineering Commit 0, #8314's slice and the draft pull request end to end under the scope-lock | The hub's Stage-6 brief, under the operator's scope-lock | **RECORDED** |
| **DEV-12** | **The Mode R briefing is cited as `#8605 comment 6613987950`**, never by URL; the Stage-4 Phase A0 artifact itself is not transcribed (it is not a Commit-0 Survival Set element) | The Stage-4 plan's transcription note; the hub's Stage-6 brief | **APPLIED** |
| **DEV-13** | **A self-repair for #8314 opens #8444's slice.** The seven version-skew canary arms the SIGPIPE-idiom gate reported read their captured stderr from a here-string instead of a pipe into a short-circuiting reader; none of the gate's listed non-equivalences applies (a scalar haystack, one reader, fixed non-empty needles). Attributed to #8314 | The hub's Stage-6 brief for #8444 (routed self-repair) | **APPLIED** |
| **DEV-14** | **#8444 edits `core/hooks/tests/command-position-fp-control.test.sh`**, a row the matrix names for #8314 alone and the #8444 design's Change 5 left unedited. Transformation (e) changes the default canonical form of the two exact-form pins whose input carries a prefix-run assignment (the assignment behind a wrapper, and the eleven-token cap row), so their default-output expectations take the marked form; their exit-view expectations, and every other pin, are unchanged | (e)'s text contract in the #8444 design; Stage-6 B3 minor adjustment | **APPLIED** |
| **DEV-15** | **BLOCK-DESTRUCTIVE-023's two export-capable lines also read the append operator.** The approved 8444c (the design's option (i)) carries the declaration-builtin alternation to those lines; this slice adds the append form -020's line reads as well, so an appending assignment of either variable is refused. A one-token tightening per line on an anti-injection rule, pinned by `AC-D023-APPEND` and `AC-D023-APPEND-SCOPE`, CHEAP to strike | The slice's reading of "the same for -023"; for the operator to ratify or strike at Stage 9 | **RECORDED** — Stage 9 ratification |
| **DEV-16** | **No successor is named for `env`'s split-string and unset-option spellings** of a PATH or anti-injection assignment. An issue search found no open owner, and the split-value card the script walk carries cannot reach an assignment written inside a split string. Filing is outside an Engineering spoke's write scope, so the -020 registry row routes the two spellings, with a program's own variable operand and the indirect spellings it declares, to their own card; the hub files it before this card's Stage 9 GO, and the fragment's References block then names it | The Collective Review's "a named successor" item; the adversarial review's FM3 | **APPLIED** — the hub filed #8652 for these spellings, and #8314's follow-up pass (DEV-25) routes them to it from the -020 and -023 rows through the fragment's References block |
| **DEV-17** | **#8444's corpus seed block landed in its fix commit**, seed 9: 73 rows in 13 groups with the fix commit's verdicts, a cap group pinning the prefix cap's boundary (judged behind ten prefix-run tokens, not behind eleven). The design's Commit-0 placement is superseded per DEV-03 | Collective Review security rating | **APPLIED** |
| **DEV-18** | **The FM1 neutrality arm is an in-suite differential** (`AC-D020-NEUTRAL-*` in the deletion hook's suite): a copy of the canonicalizer with (e)'s two marked lines removed, shown live, and six witnesses at both allow-on-match exits on which the exit view and the hook's verdict are byte-identical across the two copies while the default view carries the mark | The adversarial review's FM1, adopted at the Collective Review | **APPLIED** |
| **DEV-19** | **#8315's design inputs, as the delta's Decision Recorded adopts them:** the prior design's rung doctrine, counter rule, join and keep rule, residual for standard input and case-fold reach (D-1 to D-5); AR-P1 (the respelled reader joined to the unchanged unparseable test by one `||` line, at the shipped positions only); AR-P2 (the fast path on the command with quotes and `$` removed); AR-P3 GUARD (an ANSI-C span keeps the shipped terminator, its two content movements declared); AR-P4 (#8650 owns the unrecorded residuals, #6195 the recorded ones); the minors (`&>` protection shared by both gates, the declared quotation line, the redirection-grammar parity table); and F-D1 as the tenth class. The seed block and the RED arms land in the fix commit, per DEV-03 | The delta's Decision Recorded on #8629; the Collective Review scope-lock | **APPLIED** |
| **DEV-20** | **A quoted `<` or `>` is never read as a redirection.** The design's redirection strip reads the quote-erased tokens, so a quoted word beginning with `>` would be dropped (an allowlisted write behind it allowed, today refused) and a quoted field beginning with `<` would hand its flag the path (an allowlisted write refused, today allowed). The scanner carries each quoted `<` and `>` as a stand-in through the strip and puts it back after, which is the POSIX grammar the design's redirection canonicalization cites. Two marked lines, pinned by `AC-E007-SP-Q1`/`-Q2` beside the `nq` mutant that removes them; no pre-change verdict moves. CHEAP to strike | Stage-6 B3 minor adjustment, to keep AC2's literal zero (the reason the operator chose AR-P3's guard) | **RECORDED** — Stage 9 ratification |
| **DEV-21** | **The tenth class is built from the decision, which carried no Stage-5 specification:** a short-flag reader in the operand walk that follows gh's flag parser (any run of the boolean `-i`, then one value-taking flag whose value is the rest of the word with one leading `=` dropped, or the next word), one marked line, pinned by `AC-E007-SP-M1` to `-M8`, the `ns` mutant and three corpus groups. Its two declared precision improvements: a clustered short flag's separate value is no longer taken for the path (an allowlisted write refused today, allowed now), and an explicit attached read method beside a field flag is a read (recorded today, no record now). Arms: 12, beside the delta's 90 | The delta's Decision Recorded on #8629 (F-D1 folded as the tenth class) | **RECORDED** — Stage 9 ratification |
| **DEV-22** | **The files this slice adds beyond the Stage-4 rows:** the decision record (`{{ADR:egress-respelling-takes-the-resolved-positions-rung}}`, numbered on the branch at the next free slot after the release's first record and cited by its slug token), and the fixtures README promoted on the design's Change 9 basis though NEW-READER does not fire. `core/ADRs/README.md` is not edited: it carries the egress records only in its renumber log, which the renumber tool writes at merge, and has no themed home for one, as #8314 recorded | The #8315 design's Changes 7 to 9 | **APPLIED** |
| **DEV-23** | **Spellings declared without an owner.** The fragment's residual list also names four spellings no open card owns: a nested, sequence, escape-bearing or all-empty brace group; an ANSI-C escape outside the decoded set; a redirection written against the word before it; and a method value that is itself escaped or brace-expanded. Each is a known instance in a list stated as not closed. Filing is outside an Engineering spoke's write scope | The issue's Expected Behavior (declare the class non-exhaustively); the hub's routing call | **OPEN** — the hub's |
| **DEV-24** | **Implementation notes against the design's text.** The seed block's fourth ANSI-C head row is the locale-quoted verb (the design listed one ANSI-C spelling twice); the ANSI-C reverse mutant edits the span helper's own guard line, marked `ansi-guard`; the join reverse mutant turns the keep line into a no-op; the command-word normalization is applied to each token exactly once — by the walk to a token it reaches directly, by the look-ahead on a hit, and to the subcommand — and never again at the verb check, because a second unescape would read an escaped backslash as the verb; a decoded NUL ends the decoded string, as the shell ends it | The #8315 design's Changes 1 to 3, read at Stage 6 | **APPLIED** |
| **DEV-25** | **A follow-up pass on #8314, after all three cards were built.** The canonicalizer's default walk recognizes the append form of a prefix assignment, `NAME+=value`, as an assignment word, with the skip, the prefix-cap count and the (e) mark a `NAME=value` word gets, so a guarded command or assignment behind one sits at a command start for every rule that reads the canonical text. The form existed on `main` before this release, so it is not a regression of this one. The subscript and array spellings and every other indirect form stay #8652's. The pass carries its arms (red before, green after), a both-direction differential, the canary decision, corpus seed 11, the readiness text and decision 4's assignment forms, and the -020 and -023 rows route their remaining spellings to #8652 | The operator's decision at the Stage 6 inter-stage gate (2026-11-03), **D-S6-APPEND (A)**; the hub's follow-up brief on #8631 | **APPLIED** |
| **DEV-26** | **The exit view's assignment test is not widened.** The follow-up brief named both of the canonicalizer's assignment tests. Widening the exit view's test would hand the append form to the deletion hook's two allow-on-match exits, and each of four sentinels refused before and after this pass would be allowed: a git command or a target-less deletion verb behind an append-form word, beside a refused deletion or Trash call (`EXT-APPEND-X1`..`-X4`, each `-PAIR` arm through a copy whose exit view takes the form). That is a refuse→allow movement, which the brief's own bar and D-S5-8314-EXITS (A) both exclude. The exit view stays frozen and its header now states that its walk reads the `NAME=value` form only; the appending spelling at those exits keeps today's verdict, which is a refusal, and the line laundering stays #8122's | D-S5-8314-EXITS (A); the brief's zero refuse→allow bar; Stage-6 B3 minor adjustment | **RECORDED** — Stage 9 ratification |
| **DEV-27** | **One refuse→allow class, by construction, and declared.** #8314's precision class (D-S5-8314-PREC) is now reached behind an append-form word: a wrapper whose own grammar consumes `git` as an option value or a positional runs another program under that name and never runs git, so the move from refused to allowed is the declared precision improvement, and the appending spelling joins the verdict its `NAME=value` spelling already has. Pinned by `EXT-APPEND-PREC` beside `EXT-APPEND-PREC-CTL`, the same wrapper running git, refused. No measured population row or pre-existing arm moves toward allow | D-S5-8314-PREC; Stage-6 B3 minor adjustment | **RECORDED** — Stage 9 ratification |
| **DEV-28** | **Seed 11's header does not take the card-block form CIAC-2 counts.** The follow-up pass's rows are headed as a pass on #8314, not as `card #8314`, so CIAC-2's count still reads 2 and #8314's deferred seed block of the wrapper-grammar faces stays visibly deferred for the Stage 9 gate rather than being satisfied by a block of another class | CIAC-2's intent; the follow-up brief (do not re-author the deferred block) | **RECORDED** |
| **DEV-29** | **A walk-fix pass shared by #8314 and #8315, after the follow-up pass.** Two walks that keep their own prefix logic rather than the canonicalizer's — BLOCK-DESTRUCTIVE-022's interpreter prefix walk and BLOCK-EGRESS-007's head walk — still ended at the append form of a prefix assignment, because each tested the name part of a `NAME=value` word only. Each now steps over the scalar append form with the skip and the bookkeeping `NAME=value` gets, its predicate spelled as the other's; an append whose value opens an array, a subscript and every other indirect form still end the walk and stay #8652's. `script_resolve_head()` is unchanged and declared a precision limit. The pass carries its arms, red before and green after beside `NAME=value` controls, a both-direction differential per card, corpus seed 12 (headed so CIAC-2's count does not change, as DEV-28), the readiness text, and ADR-231's `## Consequences` heading, split so the ADR durability lint reads the section. Deviations from the pass's brief are DEV-30 onward | The operator's decision at the Stage 6 inter-stage gate (2026-11-04), **D-S6-WALKS (A)**; the hub's walk-fix brief on #8631 and #8632 | **APPLIED** |
| **DEV-30** | **One precision class declared in the -022 walk.** Before this pass an append-form word was the command word, so its own value was adjudicated as the program: a value naming an interpreter, ahead of a script, was refused as an interpreter invocation, and a value that is a script path, ahead of another command, was recorded as a direct execution. The word is now the assignment it is, and the word after it is the command, as for its `NAME=value` spelling: the first moves from refused to recorded at the direct-execution arm's rollout phase, because the shell runs that script directly, and the second from recorded to allowed, because nothing executes the value. Each joins its `NAME=value` twin's verdict and is pinned beside that twin (the suite's `BLOCK-022 append precision class` arms; corpus group `swa-prec`) | The brief's bar, which admits a refuse→allow movement only within a declared precision class; the precedent of corpus group `wrap-abbrev-exec`, a word once read as the interpreter whose program runs the script directly; Stage-6 B3 minor adjustment | **RECORDED** — Stage 9 ratification |
| **DEV-31** | **The -007 walk holds both first-invocation counters for an invocation behind the append form.** The brief asked for the plain form's change and position flags alone. With those alone, an invocation the walk newly reaches behind the form would count as the command's first invocation, and a later write at the head of a segment, refused on day one today, would move to the record: measured through a copy without the hold, for a later plain write and a later respelled write (`AC-E007-AP-K1`, `-K2`). One marked line sets `egress_scanhit` for such an invocation, the flag a look-ahead hit sets, so neither counter advances and every shipped day-one refusal stands. The cost is an asymmetry in the strict direction, the one ADR-230's decision 2 already declares for respellings: a read written behind the form, before a write, leaves that write refused, where its `NAME=value` twin, whose read is counted, records it (`AC-E007-AP-K3`; corpus group `ewa-counter` beside `ewa-ctl`) | The brief's bar (no refuse→allow outside a declared precision class); ADR-230 decision 2; Stage-6 B3 minor adjustment | **RECORDED** — Stage 9 ratification |
| **DEV-32** | **One precision class declared in the -007 walk.** Before this pass an append-form word whose value ends in `gh`, ahead of the word `api`, was the command word, and its basename was read as the verb, so a write to an unlisted path behind it was refused on day one. The shell runs `api`, with the assignment in its environment, so there is no gh write there. The word is now the assignment it is, and the spelling takes the allow its `NAME=value` twin already has (`AC-E007-AP-PREC` beside `-PREC-CTL`; corpus group `ewa-prec` beside row EW04). The unparseable branch is untouched by this pass, so a command the scanner cannot tokenize gets the verdict it had | The brief's bar; Stage-6 B3 minor adjustment | **RECORDED** — Stage 9 ratification |
| **DEV-33** | **A quoted append-form word moves from allowed to recorded, joining its quoted twin.** The egress scanner drops quote marks before a word is read, so a quoted assignment word is read as the assignment it spells, although the shell runs it as the command word; the quoted `NAME=value` spelling already records a write behind it, and the quoted append form now does the same (`AC-E007-AP-Q` beside `-Q-CTL`; corpus group `ewa-quote` beside row EW03). The brief offered a quoted word among the near-miss shapes; for this walk it moves, so the -007 near misses are a word after the command word, an invalid name and a doubled plus, and the quoted spelling is listed as a movement of the declared append-form class: an over-read in the strict direction, recorded at the shipped phase | The brief's near-miss item and its movement bar; the scanner's quote handling | **RECORDED** |

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

Recorded by the spoke on #8631 after this file was written and before it was committed, on base `f8d88626`. Later slices append their own sections.

| Check | Result |
|---|---|
| **Commit-0 version half** | § Commit-0 Version Re-Verify Record — next-free `v4.82`, absent on every arm, PROCEED |
| **Commit-0 base vs the Stage-4 pin** | equal: `origin/main` = `f8d8862668aa373a37f36f309c54eb364fae2d9b` after both fetches. The five hook sources hash to the Stage-4 pins (first 12 hex: awk `9b8fb81edcb3`, destructive `d9ce4771ae4b`, egress `172cb4074ca7`, fs-boundary `1c7cbc11b3ca`, rm-prefer-trash `7f31858dcf8a`) and the corpus to `74be7ed024d280f725ade6f0ac4909001ef07f5ee4d9b3b78ce3a0605ea95789` |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp guards-judge-every-spelling-alike` → **exit 0**, *"verify-stamp OK — guards-judge-every-spelling-alike carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s)); package-consequence checks not exercised"* (its pre-flight: the manifest stales 0 packages). Control: the same verb on `guards-judge-every-spelling-alike-zz` → exit 1, `NO PRE-CLAIM PLAN`. This file carries exactly one literal double-brace placeholder (a fixed-string count over the file returns 1, and a count of the opening double brace alone returns 1) |
| **The CIAC lint (G4-06) on this file** | `release/tools/verify-release-plan.sh --ciac-lint` on this file → exit 0, `CIAC-LINT-SUMMARY declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, the declared set `CIAC-1 CIAC-2 CIAC-3 CIAC-4` — equal to the Stage-4 body's reading |
| **Plan verifier, pre-commit** | `release/tools/verify-release-plan.sh --stage4-comment <the two Stage-4 parts>` on this file before its commit → 5 PASS / 12 FAIL / 8 SKIP / 0 UNRUNNABLE / 0 ERROR over 25 records (13 per-issue, 4 cross-issue, 8 always-on). Every FAIL is a later obligation, as expected at this commit: #8314's seven label-presence rows (its arms land in its fix commit), CIAC-1 to CIAC-3 (their slices), and FCM-1 and FCM-2, the two declared ADDs — this file, delivered by this commit, and #8314's decision record, delivered by its slice. `FCM-COVERAGE` PASS: `declared=33 interpreted=33 obligations=2 excluded=10 conditional=1 uninterpreted=0 pathless=0 prose_led=0`. The provenance family reads PASS on coverage, presence, grammar (Form X, date 2026-11-03) and delta (`comment_elements=5 all present in the plan`) |
| **Doc links** | `python3 core/deploy/tools/check-doc-links.py --target-paths <this file> --require-targets` → exit 0, no findings, over a file carrying 0 markdown links (the file names paths in backticks and links nothing) |

### #8444 slice — Stage 6, opened by a self-repair for #8314

Recorded by the spoke on #8633, measured in the worktree's hook CI layout and never against the deployed hooks. The self-repair is commit `74449778`; the fix and its RED fixtures are commit `919313be`; the readiness text, the registry, the decision record's item and this section follow them in one commit.

| Check | Result |
|---|---|
| **Stage 6 A1 (this slice)** | this file read whole; the CIAC lint → `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, unchanged since Engineering Commit 0 → PROCEED |
| **SIGPIPE self-repair** | the seven reported sites read the here-string form (the pipe form counts 7 before and 0 after); the full runner at `74449778` → AGGREGATE PASS 3050, FAIL 0 over 25 suites |
| **Red-before (G-PR4)** | on the pre-fix hook with this slice's fixtures: block-destructive Total 1515, FAIL 45 — the 28 `AC-D020` and 10 `AC-D023` arms the fix moves and 7 corpus groups, whose 40 rows read allowed; the deletion suite's `AC-D020-NEUTRAL-LIVE` and its six witnesses red (no (e) to remove), its sandbox control green; the false-positive control's two updated pins red. Green on both sides by design: the controls, the near misses, the cap pins, the offset-1 and exit-view pins, and `AC-D020-COND-EXPORT`, which #8314's condition face already carries |
| **Green** | the full runner at the fix's sources → AGGREGATE PASS 3130, FAIL 0 over 25 suites: block-destructive 1515, block-rm-prefer-trash 153, block-fs-boundary 171, block-egress 423, command-position-fp-control 130 (`newly-blocked=0`), each FAIL 0 |
| **Corpus identity** | 1,076 block-destructive rows of 1,386; SHA-256 `ecc8a6d8b53368b6626bbf4763670feaf58f42aeee5abb5b2d055c2ed56327ca`; every seed-9 group at its recorded verdict |
| **Registry and links** | `build-hook-registry.py --check` → in sync; `check-doc-links.py --require-targets` over the changed fragments, the decision record and this file → exit 0 |
| **Skill packages** | `build-skill-packages.sh --skills-for-paths` over the slice's changed paths → none (a skill's own `SKILL.md` → its skill, the control) |

### #8315 slice — Stage 6, the third and last

Recorded by the spoke on #8632, measured in the worktree's hook CI layout and never against the deployed hooks. The fix and its RED fixtures are one commit; the readiness text, the registry, the decision record and this section follow it in one commit.

| Check | Result |
|---|---|
| **Stage 6 A1 (this slice)** | this file read whole; the CIAC lint → `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, unchanged since Engineering Commit 0 → PROCEED |
| **Entry** | the egress suite at this slice's entry read Total 423, FAIL 0; the corpus 1,386 rows, SHA-256 `ecc8a6d8b53368b6626bbf4763670feaf58f42aeee5abb5b2d055c2ed56327ca`, 310 of them block-egress with 10 declared open |
| **Red-before (G-PR4)** | on the pre-fix hook with this slice's fixtures: block-egress Total 528, FAIL 89, and every failure is this card's own arm, the re-pointed `AC-E007-W4e` pin, or the corpus twin arm reading this card's rows. 42 behavioural arms red on the shipped-copy limb (the classes the fix moves); 12 no-movement pins red only through the mutant limb their pre-fix copy cannot build; 17 mutant-shape arms whose marked lines did not exist yet; `AC-E007-RDRPARITY-egress`; 15 corpus groups, whose rows read their pre-fix verdicts. Green on both sides by design: the plain-form control, the near misses, the comment and even-backslash contrasts, the parse-cap pin, the lowered-cap shape and the canonicalizer's parity column |
| **Green** | the full runner at this slice's sources → AGGREGATE PASS 3235, FAIL 0 over 25 suites: block-egress 528 (the entry 423 + 105), block-destructive 1515, block-rm-prefer-trash 153, block-fs-boundary 171 and command-position-fp-control 130, each at its entry total, every suite FAIL 0; the corpus reader's detectors are live — the reverse mutant moves 79 recorded W rows to an allow and the counter mutant 158 refusals toward allow |
| **Corpus identity** | 1,499 rows — 423 block-egress (113 of them seed 10, with 7 declared open) and 1,076 for the other guards; SHA-256 `5a11538b011d2fe0b54c4cfb4d6699bd9d88c4f13493cdb69f20180583616eb0`; every seed-10 group and the two new seed-8 groups at their recorded verdicts. CIAC-2's card-seed-header count reads 2 at this head, #8314's block being deferred |
| **AC3** | block-egress Total 528 = the entry 423 + the delta's 90 + the tenth class's 12 + DEV-20's 3, at FAIL 0 |
| **INT-1** | the destructive suite's `WRAPVOCAB-PARITY-*` arms read the egress word list unchanged: block-destructive 1515, FAIL 0 under the runner, with no egress row of `WRAP_DECL` changed |
| **Registry and links** | `build-hook-registry.py --check` → in sync; `check-doc-links.py --require-targets` over the two fragments, the decision record, the fixtures README and this file → exit 0, no findings (`--self-test` → 12 fixtures passed) |
| **Skill packages** | `build-skill-packages.sh --skills-for-paths` over the slice's changed paths → none (a skill's own `SKILL.md` → its skill, the control) |
| **ADR index** | N/A — this release adds no record under `release/ADRs/`; `core/ADRs/README.md` is N/A for the reason DEV-22 gives |

### #8314 follow-up pass — Stage 6 (D-S6-APPEND (A))

Recorded by the spoke on #8631 for the follow-up pass, measured in the worktree's hook CI layout and never against the deployed hooks. The fix, its canary probe and its RED fixtures are commit `10aedea2`; the readiness text, the registry, the decision record and this section follow it in one commit.

| Check | Result |
|---|---|
| **Stage 6 A1 (this pass)** | this file read whole; the CIAC lint → `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, unchanged → PROCEED |
| **Entry** | head `27ce7836`; the runner's entry totals block-destructive 1515, block-rm-prefer-trash 153, block-fs-boundary 171, block-egress 528 and command-position-fp-control 130, aggregate 3235 over 25 suites; the corpus 1,499 rows, SHA-256 `5a11538b011d2fe0b54c4cfb4d6699bd9d88c4f13493cdb69f20180583616eb0` |
| **The gap, verified before the change** | both of the canonicalizer's assignment tests read the `NAME=value` form only (`command-position.awk`, the default walk's and the exit view's); -020 and -023 read the append form on their own variable at a command start only (`block-destructive.sh`, their three lines); `origin/main`'s canonicalizer carries the same test, so the gap predates this release; bash 3.2 and zsh both run the command behind an append-form word, with the assignment in its environment |
| **Red-before (G-PR4)** | the full runner on the sources at `27ce7836` with this pass's suites and corpus → AGGREGATE PASS 3282, FAIL 34 over 25 suites: block-destructive 1541 (FAIL 14), block-egress 531 (2), block-fs-boundary 174 (2), block-rm-prefer-trash 169 (9) and command-position-fp-control 163 (7), every other suite at its total and FAIL 0. The 34 are 15 movement arms (`EXT-APPEND-D1`..`-D5`, `-D020-1`..`-4`, `-D023-1`, `-D023-2`, `-E1`, `-F1`, `-T1`, `-PREC`), corpus group `apnd` (AP10 to AP15 read allowed), and 18 instrument arms: `CMDPOS-SKEW-APPEND` in four suites and the deletion suite's `XV` arms, which find no marked line to revert; `X2-PAIR` and `X3-PAIR`, whose Step-2 exit is reachable only through the widened default walk; and the false-positive control's face sentinel and six default-form pins. Green on both sides by design: every `NAME=value` control, the near misses, `EXT-APPEND-PREC-CTL`, the refusals `EXT-APPEND-X1`..`-X4`, `X1-PAIR` and `X4-PAIR`, the exit-view and unchanged-form pins, groups `apnd-ctl` and `apnd-near`, and every pre-existing arm |
| **Green** | the full runner at the fix's sources → AGGREGATE PASS 3316, FAIL 0 over 25 suites: block-destructive 1541 (the entry 1515 + 26), block-rm-prefer-trash 169 (153 + 16), block-fs-boundary 174 (171 + 3), block-egress 531 (528 + 3) and command-position-fp-control 163 (130 + 33; `newly-blocked=0`), every other suite at its entry total, each FAIL 0 |
| **Both-direction differential** | two commits compared: the five hook sources at `27ce7836` and at `10aedea2`, both graded by `10aedea2`'s suites and corpus. Command: at `10aedea2` or later, `git restore --source=27ce7836 --` the five paths (`core/hooks/lib/command-position.awk` and the four consumers), then `bash core/hooks/tests/setup-ci-layout.sh` and `bash .claude/hooks/tests/test-runner.sh`; restore the five paths to `10aedea2` and run the same two commands; compare the two runs' FAIL lines, where a corpus group's FAIL line names each moved row as `id(recorded->observed)`. **Allow→refuse: 20**, all of the declared append-form class: 14 suite payloads (`EXT-APPEND-D1`..`-D5`, `-D020-1`..`-4`, `-D023-1`, `-D023-2`, `-E1`, `-F1`, `-T1`) and 6 corpus rows (AP10 to AP15). **Refuse→allow: 1**, `EXT-APPEND-PREC`, the declared precision class (DEV-27); none outside a declared class. **No movement** on any pre-existing arm of the 25 suites, on any pre-existing corpus row (1,076 block-destructive, 423 block-egress), or on the false-positive control's 44-payload population, whose every `[B]`, `[C]` and `[D]` line is byte-identical across a direct run of each side (only its 7 instrument lines differ) |
| **Version-skew canary** | extended: a consumer's verdict depends on this change for every append-prefixed command, so the second probe of the canary in all four consumers now opens with an append-form word ahead of its wrapper — no added `awk` call — and a primitive without the form fails the hook closed (`CMDPOS-SKEW-APPEND` in each suite, through a copy whose marked line is reverted, shown live). The deletion hook's exit-view probe keeps its input, because the exit view never takes the form |
| **Corpus identity** | 1,511 rows — 1,088 block-destructive (12 of them seed 11) and 423 block-egress; SHA-256 `adc8dec850339f6b9bcc952ca4a5988da7a3acefea375cf68c92582c0e589d58`; every seed-11 group at its recorded verdict. The reader's detector is live: the operand-walk mutant moves 83 recorded refusals to an allow (89 in the red-before run, the 6 `apnd` rows the difference). CIAC-2's count reads 2 (DEV-28; control: 11 seed headers in the file) |
| **Hashes (first 12 hex)** | pre-change, at `27ce7836`: awk `1b46609f6ad7`, destructive `bd44cc6cbc2c`, egress `bb613ec73e80`, fs-boundary `c22bd4113a37`, rm-prefer-trash `66c3d5db4582`. Post-change, at `10aedea2`: awk `397f2248488a`, destructive `cb50bbaa0c3f`, egress `a84edba0ebfd`, fs-boundary `da3d17cd2ade`, rm-prefer-trash `4520edd074a3` |
| **Registry and links** | `build-hook-registry.py` then `--check` → in sync; `check-doc-links.py --require-targets` over the three fragments, the registry, the decision record and this file → exit 0, no findings |
| **Decision record** | decision 4 names both assignment forms and states that the exit view keeps the plain one. The ADR durability lint reports one finding that predates this pass: the record's `## Consequences` heading carries a suffix, which the net-new structural rule reads as the section missing; the brief limits this pass's edit of the record to its enumeration, so the heading is left for the hub |
| **Skill packages** | `build-skill-packages.sh --skills-for-paths` over the pass's 17 changed paths → none (control: a skill's own `SKILL.md` names its skill) |
| **ADR index** | N/A — this pass adds no record under `release/ADRs/` |

### Walk-fix pass on #8314 and #8315 — Stage 6 (D-S6-WALKS (A))

Recorded by the spoke on #8631 and #8632 for the walk-fix pass, measured in the worktree's hook CI layout and never against the deployed hooks. Each card's fix and its RED fixtures are one commit, and its readiness text, the regenerated registry and its rows of this file the next; #8314's half lands first, its fix commit `f57d23fc`. Every run below is graded by this pass's suites, corpus and readiness text, and only the hook sources differ between runs.

| Check | Result |
|---|---|
| **Stage 6 A1 (this pass)** | this file read whole; the CIAC lint → `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, unchanged → PROCEED; `claim-version.sh --verify-stamp` → OK |
| **Entry** | head `cdfd06e9`; the entry totals block-destructive 1541, block-rm-prefer-trash 169, block-fs-boundary 174, block-egress 531 and command-position-fp-control 163, aggregate 3316 over 25 suites; the corpus 1,511 rows, SHA-256 `adc8dec850339f6b9bcc952ca4a5988da7a3acefea375cf68c92582c0e589d58` |
| **The gap, verified before any edit** | a probe through the CI-layout copies of the two hooks, its plain-form controls refused (the probe live): behind the append form of a prefix assignment, an interpreter or `source` invocation of an unlisted script was allowed by the -022 walk with nothing adjudicated, beside its refused `NAME=value` twin, and a gh api write to an unlisted path was allowed by the -007 walk with no record, beside its recorded twin. The same probe measured, before any change, each class this pass declares rather than assumes: the precision classes of both walks (DEV-30, DEV-32), the day-one refusals the -007 counter must keep (DEV-31) and the quoted spelling (DEV-33) |
| **Red-before (G-PR4)** | the full runner on the five hook sources at `cdfd06e9` (run A) → AGGREGATE PASS 3340, FAIL 24 over 25 suites: block-destructive 1564 (FAIL 11) and block-egress 556 (FAIL 13); every other suite at its entry total and FAIL 0, `setup-ci-layout` 32/32 among them. #8314's 11: the nine `BLOCK-022 append` arms that move — six refusals, one direct-execution record and the two precision-class arms — and corpus groups `swa` (SW10–SW14 read allowed) and `swa-prec` (SW30 read refused, SW31 recorded). Green on both sides by design: the allowlisted control, the five near misses (an array append among them), the two precision-class twins, the head resolver's pinned limit and its control, and groups `swa-ctl` and `swa-near` |
| **#8314 green** | the full runner on #8314's fix, with the egress hook still at `cdfd06e9` (run B) → AGGREGATE PASS 3350, FAIL 14: block-destructive 1564, FAIL 0 (the entry 1541 plus 19 arms and 4 corpus groups). The 14 are #8315's half: its 13 red-before failures, and the predicate-parity arm, which reads the two walks' predicates as unequal until #8315's change lands |
| **#8314 both-direction differential** | run A against run B, whose hook sources differ in `block-destructive.sh` alone. Command: at #8314's fix commit `f57d23fc` or later, `git restore --source=cdfd06e9 --` the five paths (`core/hooks/lib/command-position.awk` and the four consumers), then `bash core/hooks/tests/setup-ci-layout.sh` and `bash .claude/hooks/tests/test-runner.sh`; restore the five paths to `f57d23fc` and run the same two commands; compare the two runs' FAIL lines, where a corpus group's FAIL line names each moved row as `id(recorded->observed)`. **Allow→refuse: 9**, all of the append-form class (six suite payloads, SW10–SW12). **Allow→record: 3**, the same class (one suite payload, SW13, SW14). **Refuse→record: 2** and **record→allow: 2**, the declared precision class (DEV-30; one suite payload and one corpus row each, SW30 and SW31). **Refuse→allow: 0.** No movement on any pre-existing arm of the 25 suites or any pre-existing corpus row (1,088 block-destructive, 423 block-egress). The false-positive control reads the canonicalizer, which this pass does not change, and reads 163, FAIL 0, in every run. The one other difference between the two runs is an instrument arm of #8315's half, the predicate-parity arm |
| **Corpus (#8314's rows)** | seed 12's 15 `SW` rows in four groups, each at its recorded verdict from the fix on; the reader's detector is live — the operand-walk mutant moves 83 recorded refusals or warnings to an allow at the fix (88 in the red-before run, the five `swa` rows the difference). CIAC-2's count reads 2 (DEV-28's header form; control: 12 seed headers in the file) |
| **Readiness text and registry** | `block-destructive.md` line 23 and scope item 2 name the append form and the declared precision class, and a new item 11 names the head resolver's precision limit; `build-hook-registry.py` then `--check` → in sync |
| **Decision record** | ADR-231's `## Consequences — properties of ADR-187 that narrow` is split into `## Consequences` and an H3, `### Properties of ADR-187 that narrow`; nothing else in the record changed. The ADR durability lint (`check-adr-durability.py --diff-base origin/main`) on the record: before, exit 1 with one `R5-NEW` finding (the section read as missing); after, exit 0, `COUNT 0` (control: ADR-230, which carries the exact heading, reads `COUNT 0`) |
| **Hashes (first 12 hex)** | `block-destructive.sh` at `cdfd06e9` `cb50bbaa0c3f`, at `f57d23fc` `90cef8e4f880`; the other four hook sources unchanged by this half (awk `397f2248488a`, egress `a84edba0ebfd`, fs-boundary `da3d17cd2ade`, rm-prefer-trash `4520edd074a3`) |
| **#8315 red-before (G-PR4)** | in run A, block-egress 556 (FAIL 13): the arms that move read their pre-change verdicts (`AC-E007-AP-1` to `-4`, `-Q`, `-PREC`); the two reverse copies' shape arms (`AP0-R`, `AP0-H`) and the counter arms' no-hold limb (`AP-K1`, `-K2`) find no marked line to remove yet; and corpus groups `ewa` (EW10–EW14 read allowed), `ewa-quote` (EW20 allowed) and `ewa-prec` (EW50 refused). Green on both sides by design: the `NAME=value` controls (`AP-CTL`, `-K3`, `-Q-CTL`, `-PREC-CTL`), the three near misses with their ungated, phase-forced limb, the untokenizable pin, the counter arms' shipped and reverted limbs (the later write refused before and after), the predicate-parity arm (the two walks still spelled alike before either changed), and groups `ewa-ctl`, `ewa-counter` and `ewa-near`. Run B read the same 13 and the parity arm, which then reads the two predicates as unequal |
| **Green: the run of record** | the full runner with both halves in place (run C) → AGGREGATE PASS 3364, FAIL 0 over 25 suites: block-destructive 1564 (the entry 1541 plus 23), block-egress 556 (531 plus 25: 19 `AC-E007-AP*` arms and 6 corpus groups), block-rm-prefer-trash 169, block-fs-boundary 174 and command-position-fp-control 163, every other suite at its entry total, every suite FAIL 0, `setup-ci-layout` 32/32. The SHA-256 of every input that run read — the five hook sources, the two edited suites, the corpus, the two edited fragments and the registry — equals the pushed head's; this file and the decision record are read by no suite |
| **#8315 both-direction differential** | run B against run C, whose hook sources differ in `block-egress.sh` alone: #8314's change lands between `cdfd06e9` and this half, so this half is measured from #8314's fix. Command: as #8314's, restoring the five paths to `f57d23fc` for the first run and to #8315's fix commit `ad697aa3` for the second. **Allow→record: 10**, all of the append-form class — three suite payloads and EW10–EW14, and the quoted spelling (DEV-33), one suite payload and EW20. **Refuse→allow: 2**, the declared precision class (DEV-32; one suite payload and EW50). **No verdict move** for one suite payload whose row moves from the look-ahead population to the head-walk one (`AP-4`). Instrument arms that turn green with the change: the two shape arms, the counter arms' no-hold limb and the predicate-parity arm. No refuse→allow outside the declared class; the counter's day-one refusals (EW30, EW31 and the `AP-K1`, `-K2` payloads) stay refused in every run. No movement on any pre-existing arm or corpus row. Read from `cdfd06e9` instead (run A against run C), the two halves' movements add, and nothing else appears |
| **The counter hold, measured** | through the copy without the hold, a read behind the form before a plain write, and before a respelled write, each moves that write from refused to recorded (`AP-K1`, `-K2`); with the hold both stay refused, as on the pre-change hook, and the `NAME=value` twin of the first records the write (`AP-K3`). The corpus reader's counter detector moves 160 recorded refusals toward allow (158 before the pass; EW30 and EW31 the difference) |
| **The other -007 readers** | unchanged, each for its reason: `egress_old_reachable_gh_api` and `egress_old_reachable_respelled` pass over no assignment in either spelling, by design (`AP-U`, beside row ES118 and arm `SP-U0`); the fast path tests for the verb's letters anywhere in the command; `egress_is_redirection`'s `{name}` test reads a named-descriptor redirection, which is no assignment. `_cross-cutting.md` states no predicate the two walks share, so it is not edited |
| **Corpus identity** | 1,544 rows — 1,103 block-destructive (15 of them seed 12) and 441 block-egress (18 of them seed 12); SHA-256 `0b97c78e1d8348fae8fefec2e3d2f58d683714f9641a0ca7fa7df0afcdfafc67`; every seed-12 group at its recorded verdict. The egress reader's look-ahead detector is live: the reverse mutant moves 80 recorded W rows to an allow (85 in the red-before run). CIAC-2's count reads 2 (control: 12 seed headers) |
| **Readiness text and registry** | `block-egress.md`'s Command position row names the append form, the indirect forms that still end the walk and the quoted-word over-read, its rollout paragraph the counter hold, and its precision paragraph the declared class; `build-hook-registry.py` then `--check` → in sync |
| **Hashes (first 12 hex)** | `block-egress.sh` at `cdfd06e9` `a84edba0ebfd`, at `ad697aa3` `7e6598de3a5f`; `block-destructive.sh` at `f57d23fc` `90cef8e4f880`; awk `397f2248488a`, fs-boundary `da3d17cd2ade` and rm-prefer-trash `4520edd074a3`, unchanged by the pass |
| **Skill packages** | `build-skill-packages.sh --skills-for-paths` over the pass's 10 changed paths → none (control: a skill's own `SKILL.md` names its skill) |
| **ADR index** | N/A — this pass adds no record under `release/ADRs/` |

---

## Change Description

Authored by the third and last Stage 6 Engineering spoke, once all three cards were built on this branch, and refreshed by #8314's follow-up pass (DEV-25) and by the walk-fix pass on #8314 and #8315 (DEV-29), per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol. Operator-facing and pre-merge; distinct from the user-facing release note authored at Stage 13 Close.

### Outcome

A guarded command now gets the same verdict however it is written. The shared command-position canonicalizer reaches the guarded verb behind a transparent wrapper's own options, an absolute-path wrapper, a wrapper that was missing from its set, an `if`/`while`/`until` condition, and a prefix assignment written in its append form as well as its plain form, so the anchored rules of the four hooks that consume it refuse what they refuse in plain form; the PATH-manipulation and anti-injection rules read an assignment at every position the canonicalizer resolves; and BLOCK-EGRESS-007 reads a gh api write the way the shell resolves it — refused from day one at the head of a segment in every spelling, and recorded at the unchanged rollout phase everywhere else. The two walks that keep their own prefix logic — the script-execution rule's interpreter walk and BLOCK-EGRESS-007's head walk — step over the append form of a prefix assignment as they step over the plain form, so an interpreter invocation behind it is adjudicated and a gh api write behind it is recorded, as each is behind the plain form.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #8314 | The canonicalizer walks each wrapper's own option grammar from an asserted copy of the script walk's rows, matches a prefix word by basename, and gains `nice`/`stdbuf`/`timeout` and the condition keywords; the deletion hook's two allow-on-match exits read a frozen view and keep today's verdicts; a follow-up pass steps over the append form of a prefix assignment as the plain form is stepped over (D-S6-APPEND (A)); a walk-fix pass does the same in the script-execution rule's interpreter walk, with one precision class declared and its head resolver's plain-form test kept as a declared limit (D-S6-WALKS (A)) | DONE — its corpus seed block deferred to the Stage 9 gate |
| #8444 | BLOCK-DESTRUCTIVE-020 and -023 refuse a PATH or anti-injection assignment handed to a wrapper, behind another assignment or a redirection, after a keyword, at a condition position, inside a group, in a declaration builtin's argument list or with the append operator | DONE — its remaining spellings owned by #8652 (DEV-16) |
| #8315 | BLOCK-EGRESS-007 refuses on day one a head-of-segment write reached through a leading redirection, a continuation between the verb and its subcommand, an escaped, brace-expanded, ANSI-C- or locale-quoted or case-variant verb, a quote-split verb, or an attached or clustered method flag, in a command its scanner can tokenize and in one it cannot; behind a prefix command each is recorded as its plain twin is; a walk-fix pass steps its head walk over the append form of a prefix assignment, holding both first-invocation counters so no day-one refusal moves (D-S6-WALKS (A)) | DONE — four unowned residual spellings for the hub to route (DEV-23) |

### Key decisions

- **D-S5-8314 WIDEN-CANON**, with rows COPY, word parity, a basename match and SPELL (A): the canonicalizer, not a re-homed walk, carries the wrapper grammar, and a parity arm keeps its copy of the rows equal to the script walk's (§ Decision Record).
- **D-S5-8314-EXITS (A), the masked exit view:** the two allow-on-match exits read an un-widened view, so the widening adds no refusal-to-allow there and #8122 stays its own card.
- **D-S5-8444 ROUTE-CANON with D-Scope-023 (A):** the assignment-anchored rules ride the canonicalizer's new assignment branch, and -023's newly refused positions are a declared tightening.
- **D-S5-8315 NO-ADOPT-CANON, with the delta as decided:** the egress rule keeps its own walk; a respelling takes the rung of the position the shell resolves it to; a respelled invocation counts on its own counter; the unparseable branch reads the same spellings; the fast path is derived from its transformations; an ANSI-C span keeps the shipped terminator; and a method or field flag in its attached or clustered short form joined the card as its tenth class.
- **Security rating — security-relevant bug:** each card's RED fixtures landed in its own fix commit after a red-before run kept as executed evidence.
- **D-S6-APPEND (A)**, at the Stage 6 inter-stage gate: a follow-up pass on #8314 has the canonicalizer's default walk step over the append form of a prefix assignment, with the exit view left frozen (DEV-26), the precision class it reaches declared (DEV-27), and each consumer's version-skew canary extended to tell a primitive without the form apart.
- **D-S6-WALKS (A)**, at the same gate: a walk-fix pass on #8314 and #8315 has the script-execution rule's interpreter walk and BLOCK-EGRESS-007's head walk step over the scalar append form with the plain form's skip, their predicate spelled identically and asserted by a parity arm; the egress walk holds both first-invocation counters for an invocation behind the form (DEV-31); one precision class is declared in each walk (DEV-30, DEV-32) and a quoted-spelling movement in the egress walk (DEV-33); the script-execution rule's head resolver keeps its plain-form test as a declared precision limit.
- **D-ReleaseClass `cross-cutting`, D-C SINGLE, P0, D-HookDeploy (B), D-Version minor** — as § Decision Record renders them.

### Reversibility

**MODERATE — HIGH confidence.** Before the merge, `git revert` of one card's run of commits withdraws that card alone, and the follow-up pass's fix and its canary probe share one commit, so they revert together; each card's half of the walk-fix pass is one fix commit and one readiness commit, and reverting #8315's half alone leaves #8314's intact; after it, a revert of the merge commit restores `main`, and the reverted hooks reach an instance only through a republish by the hook carrier, verified by SHA-256 — the version tag is retained, never deleted.

### Downstream impact

- The Stage-12 hook publish carries five edited files: `core/hooks/lib/command-position.awk`, `block-destructive.sh`, `block-egress.sh`, `block-fs-boundary.sh` and `block-rm-prefer-trash.sh`. Each consumer's version-skew canary also tells apart a primitive without the append form of a prefix assignment, so a stale primitive beside the published hooks fails them closed: the two always-enforce hooks deny, and the two mode-capable hooks deny in enforce and degrade to the raw command in warn.
- #8652 owns the spellings BLOCK-DESTRUCTIVE-020 and -023 still admit — `env`'s split-string and unset-option spellings, a program's own variable operand, and the indirect spellings — and the two rules' registry rows route them to it.
- BLOCK-EGRESS-007's graduation card (#6195) inherits every recorded respelled write behind a prefix command, and the drain card (#6194) the populations they land in; #8650 owns the respelled spellings still admitted with no record. The walk-fix pass adds two to those populations: a write behind the append form of a prefix assignment is a head-walk row, and one behind a prefix word followed by that form moves from the look-ahead rows to the head-walk rows at the same verdict.
- #8652 still owns the array append, the subscripts and every other indirect form of an assignment, in both walks the walk-fix pass changed as in the canonicalizer.
- Sibling milestones rebase onto this release's text: ms#441 onto `block-fs-boundary.md` line 49; ms#439 and ms#440 onto `block-destructive.md` line 23 and the corpus; ms#402 onto `block-egress.sh`, its fragment and its suite; ms#443 through the ADR numbering at the Stage-12 claim.
- Routed, not built here: the case-variant command class in the other hooks' anchored rules (AI-002) and the hook carrier's `post-merge` re-point (AI-003).
- CIAC-2's card-seed-header count reads 2 of the 3 planned, because #8314's seed block is deferred; the follow-up pass's seed 11 is headed so that it does not count as that block (DEV-28).

### Cross-references

- Release plan: this file, top section.
- Milestone: `guards-judge-every-spelling-alike`.
- User-facing release note: authored at Stage 13 Close under `release/releases/notes/`, named for the version the Stage-12 claim binds, per `release/references/standards/release-notes-standard.md`.
