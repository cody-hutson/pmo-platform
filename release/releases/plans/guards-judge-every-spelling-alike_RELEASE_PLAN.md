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
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file), then #8314's slice and #8444's; #8315 follows in its own spoke |
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

### #8444 — change specification (the second card; Stage-5 design on #8630)

ROUTE-CANON — transformation (e): a `; ` before every assignment the prefix walk skips, bound to #8314's new assignment branch by its semantics, not by a line number (the review's FMF-3 note); the declaration-builtin and append line; 8444c, the same for -023; a neutrality arm on the deletion hook's exits; the heredoc over-block declared; a named successor for `env -u PATH` / `env -S`; D-Scope-023 covering every position the change reaches. Files: `core/hooks/lib/command-position.awk`, `core/hooks/block-destructive.sh` (the -020 and -023 block), `core/hooks/tests/block-destructive.test.sh`, `core/hooks/tests/block-rm-prefer-trash.test.sh` (the neutrality arm), the corpus, `block-destructive.md` (the -020 and -023 rows), `_cross-cutting.md` (lines 49, 69 and 222, after #8314), the registry, and #8314's decision record (one decision item). Complexity: Medium.

### #8315 — change specification (the third card; Stage-5 design on #8629, delta pending)

The nine classes of the amended AC1, each on its rung; NO-ADOPT selected (the -007 walk stays its own). Files as the Stage-4 plan names them — `core/hooks/block-egress.sh` (the head walk and the prefix locator), `core/hooks/tests/block-egress.test.sh`, the Command position row of `core/rules/bypass-mode-readiness/block-egress.md`, the registry, the corpus — plus `block-destructive.md` line 23 after #8314. The delta (AR-P1: the unparseable-branch test the design did not touch; AR-P2: the fast-path gaps; AR-P3: the undeclared refused→recorded move; AR-P4: a successor whose criteria can close residuals 6 and 7b) is reviewed by the hub before this card's Stage 6, and this specification is re-read against it then. Complexity: High.

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
core/hooks/tests/fixtures/walk-payload-corpus.txt  EDIT  one seed block per card, each in that card's fix commit
core/rules/bypass-mode-readiness.md  EDIT  generated; regenerated in every commit that edits a fragment
core/hooks/lib/command-position.awk  EDIT  8314 WIDEN-CANON and the exit view · 8444 ROUTE-CANON transformation (e)
core/hooks/block-destructive.sh  EDIT  8314 two comment blocks and the canary · 8444 the -020 and -023 block
core/hooks/tests/block-destructive.test.sh  EDIT  8314 WRAP_DECL, row-parity, face and precision arms · 8444 AC-D020 arms
core/rules/bypass-mode-readiness/_cross-cutting.md  EDIT  8314 lines 46, 49, 222 and the canonical-form table · 8444 lines 49, 69, 222
core/rules/bypass-mode-readiness/block-destructive.md  EDIT  8314 line 23 · 8444 the -020 and -023 rows · 8315 line 23
core/hooks/block-egress.sh  EDIT  8314 the canary · 8315 the -007 head walk and prefix locator
core/hooks/tests/block-egress.test.sh  EDIT  8314 face and canary arms · 8315 its arms
core/hooks/tests/block-rm-prefer-trash.test.sh  EDIT  8314 RM-ARMS and the exit sentinels · 8444 the neutrality arm
core/hooks/block-rm-prefer-trash.sh  EDIT  8314 the canary and the two exits on the exit view (D-S5-8314-EXITS (A))
core/ADRs/ADR-*-command-position-walks-wrapper-grammar-from-asserted-rows.md  ADD  8314 author · 8444 one decision item
core/ADRs/README.md  EDIT  8314
# ── #8314 (WIDEN-CANON; rows COPY; EXITS (A)) ──
core/hooks/tests/command-position-fp-control.test.sh  EDIT
core/hooks/block-fs-boundary.sh  EDIT  the canary
core/hooks/tests/block-fs-boundary.test.sh  EDIT
core/rules/bypass-mode-readiness/block-rm-prefer-trash.md  EDIT
core/rules/bypass-mode-readiness/block-fs-boundary.md  EDIT
# ── #8315 (rows re-read against its Stage-5 delta) ──
core/rules/bypass-mode-readiness/block-egress.md  EDIT
# ── conditional ──
core/hooks/tests/fixtures/README.md  EDIT  CONDITIONAL:NEW-READER
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
| #8315 | AC-1 | [DEFERRED — per-class arms and corpus rows named by #8315's Stage-5 delta; bound at its slice] | each of the nine classes refused on the day-one repair rung beside a refused plain-form control and an allowed true near-miss, or a residual the operator accepts at this card's Stage 9 GO with a named successor; a shadow record is not a refusal |
| #8315 | AC-2 | [DEFERRED — runner, as #8314 AC-2c] | no refused or allowlisted write moves to allow except a declared precision improvement, and no allow row moves to refuse undeclared · control: `EGRESSCORPUS-DET-counter-fires` and `EGRESSCORPUS-DET-lookahead-fires` read non-zero |
| #8315 | AC-3 | [DEFERRED — runner .claude/hooks/tests/test-runner.sh at Stage 7 and in CI] | `block-egress.test.sh` FAIL 0, Total at least 413 (its Total at the pin) plus the arms the release adds |
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
| **DEV-07** | **Partial scope-lock for #8315:** its Stage-5 design is re-opened on #8629 for a bounded delta (AR-P1..AR-P4). Its rows here stay as the Stage-4 plan wrote them and are re-read at its slice against the delta the hub reviews. NO-ADOPT is selected, so the Stage-4 `_cross-cutting.md` line-55 row (ADOPT-CANON only) does not fire | Collective Review scope-lock, #8315 Blocker (A) | **RECORDED** — pending the delta |
| **DEV-08** | **Shared-line write-set additions and their order:** `_cross-cutting.md` lines 49 and 222, #8314 then #8444; `block-destructive.md` line 23, #8314 then #8315. The Stage-4 Contention Map carried neither | Collective Review scope-lock, Write sets and serialization | **APPLIED** — § Contention Map |
| **DEV-09** | **NEW-READER and NEW-TEST-SCRIPT stay conditional** for #8315's delta: #8314 and #8444 add rows only for guards whose suites already read the corpus, and #8314's design adds no suite (its finding 13 also records that the allowlist's existing globs admit a new `*.test.sh`) | #8314's and #8444's Stage-5 designs | **APPLIED** — § File Change Matrix |
| **DEV-10** | **The decision record's number.** Next-free on the mainline is 229 (`release/tools/renumber-adr.py --detect` at this commit: anchor 228, next-free 229), and ms#443's open PR holds 229 branch-locally. The record is authored with the mainline next-free in its filename, cited everywhere by its slug token, and renumbered at the Stage-12 bind if ms#443 merges first (ADR-181); the matrix names it by a glob so a renumber does not stale the row | ADR-181; #8314's design § ADR Pointers | **APPLIED** |
| **DEV-11** | **The Phase A1–A2 checkpoint** the Stage-6 spec places before B1 is presented after the fact, in the spoke's output: the hub's brief directs Engineering Commit 0, #8314's slice and the draft pull request end to end under the scope-lock | The hub's Stage-6 brief, under the operator's scope-lock | **RECORDED** |
| **DEV-12** | **The Mode R briefing is cited as `#8605 comment 6613987950`**, never by URL; the Stage-4 Phase A0 artifact itself is not transcribed (it is not a Commit-0 Survival Set element) | The Stage-4 plan's transcription note; the hub's Stage-6 brief | **APPLIED** |
| **DEV-13** | **A self-repair for #8314 opens #8444's slice.** The seven version-skew canary arms the SIGPIPE-idiom gate reported read their captured stderr from a here-string instead of a pipe into a short-circuiting reader; none of the gate's listed non-equivalences applies (a scalar haystack, one reader, fixed non-empty needles). Attributed to #8314 | The hub's Stage-6 brief for #8444 (routed self-repair) | **APPLIED** |
| **DEV-14** | **#8444 edits `core/hooks/tests/command-position-fp-control.test.sh`**, a row the matrix names for #8314 alone and the #8444 design's Change 5 left unedited. Transformation (e) changes the default canonical form of the two exact-form pins whose input carries a prefix-run assignment (the assignment behind a wrapper, and the eleven-token cap row), so their default-output expectations take the marked form; their exit-view expectations, and every other pin, are unchanged | (e)'s text contract in the #8444 design; Stage-6 B3 minor adjustment | **APPLIED** |
| **DEV-15** | **BLOCK-DESTRUCTIVE-023's two export-capable lines also read the append operator.** The approved 8444c (the design's option (i)) carries the declaration-builtin alternation to those lines; this slice adds the append form -020's line reads as well, so an appending assignment of either variable is refused. A one-token tightening per line on an anti-injection rule, pinned by `AC-D023-APPEND` and `AC-D023-APPEND-SCOPE`, CHEAP to strike | The slice's reading of "the same for -023"; for the operator to ratify or strike at Stage 9 | **RECORDED** — Stage 9 ratification |
| **DEV-16** | **No successor is named for `env`'s split-string and unset-option spellings** of a PATH or anti-injection assignment. An issue search found no open owner, and the split-value card the script walk carries cannot reach an assignment written inside a split string. Filing is outside an Engineering spoke's write scope, so the -020 registry row routes the two spellings, with a program's own variable operand and the indirect spellings it declares, to their own card; the hub files it before this card's Stage 9 GO, and the fragment's References block then names it | The Collective Review's "a named successor" item; the adversarial review's FM3 | **OPEN** — the hub's |
| **DEV-17** | **#8444's corpus seed block landed in its fix commit**, seed 9: 73 rows in 13 groups with the fix commit's verdicts, a cap group pinning the prefix cap's boundary (judged behind ten prefix-run tokens, not behind eleven). The design's Commit-0 placement is superseded per DEV-03 | Collective Review security rating | **APPLIED** |
| **DEV-18** | **The FM1 neutrality arm is an in-suite differential** (`AC-D020-NEUTRAL-*` in the deletion hook's suite): a copy of the canonicalizer with (e)'s two marked lines removed, shown live, and six witnesses at both allow-on-match exits on which the exit view and the hook's verdict are byte-identical across the two copies while the default view carries the mark | The adversarial review's FM1, adopted at the Collective Review | **APPLIED** |

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
