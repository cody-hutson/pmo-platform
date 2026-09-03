---
title: Release Plan — hooks-block-only-their-scope (each guard hook enforces exactly its declared scope, and nothing wider)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; concrete number bound at the Stage-12 atomic claim)
milestone: hooks-block-only-their-scope
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `hooks-block-only-their-scope`

**Milestone:** `hooks-block-only-their-scope` (#383) · hub sub-task #6648 = Stage 4 plan source (re-run, 7-card bundle) · #6709 = #6172 Stage 5 Solutioning source · #6710 = this Engineering slice (Commit 0 author)
**Version identity:** **versioned** — bump-class `minor` declared at Phase 1. The plan is authored slug-primary / pre-claim and carries the stamp-manifest token in its Header `**Version**` cell; the concrete number is computed and claimed atomically at Stage 12 per `release/governance/RELEASE_PROTOCOL.md` § Versioning § Phase 2. The Commit-0 re-verify was executed and is recorded in § Commit-0 Version Re-Verify below.
**Topology:** D-C SINGLE — one release branch (`release/hooks-block-only-their-scope`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial — Stage 6 slices route one at a time in dependency order on the single branch. Force-push (including `--force-with-lease`) on the shared release branch is prohibited under any non-serial posture; moot at P0, recorded for completeness.
**Release class:** `cross-cutting` — re-derived independently at the Stage 4 re-run on trigger (c), 3 compositional edges over the 7-card bundle. See § Release Class Declaration.
**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-02, domain: software }` — determined at Stage 4 Phase A1.5. The File Change Matrix consists entirely of internal pmo-platform artifacts (hook scripts, their test suites, an allowlist, rule fragments, one ADR, one how-to), so the release is **sourcing-exempt** — Form X verbatim. Domain is `software`: the dominant matrix evidence is executable hook code and its tests, with `governance` secondary.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #6648 (the re-run, 7-card bundle comment), together with the Stage-4 gate-passage record on the same sub-task, and reconciles the #6172 rows to the approved **Stage-5 Solutioning** design posted on #6709. Where a Stage-5 design refined a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and § Deviation Log records the ratified delta. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #6710, card #6172).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — declared at Phase 1. Anchor at authoring time is the highest `RELEASE_LOG.md` Deployment Log row on `origin/main`; the floor is anchor + one minor. The concrete number binds only at the Stage-12 compare-and-swap. |
| **Date Created** | 2026-09-02 (Wednesday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/hooks-block-only-their-scope` |
| **Baseline pin** | `origin/main` @ `4f7e1ce3acf43fc015100a6949d42145882447da` |
| **PR** | (populated at PR creation, Stage 6 — draft until the Stage 9 gate) |
| **Milestone** | `hooks-block-only-their-scope` (#383) |

**Baseline-pin note (audit-baseline discipline).** The Stage-4 plan pinned `bd961c05` at its own authoring instant (2026-09-02T18:15:34Z). `origin/main` advanced to `4f7e1ce3` before the release branch was cut, and the branch is cut from `4f7e1ce3`. The Header pin above is the **branch baseline** and is the operand Stage 9 Phase A6.5 re-checks for divergence; `bd961c05` is retained here as the Stage-4 measurement instant so the plan's own probe figures remain reproducible against the state they were measured on.

---

## Commit-0 Version Re-Verify

Executed at Engineering Commit 0 per `release/references/how-to/hub-spoke-bridge.md` § Procedure 0, before this file was committed. This release is `versioned`, so every step applies in full — none is dispositioned N/A.

| Step | Result |
|---|---|
| **1** — `git fetch --tags origin && git fetch origin main` | **EXECUTED.** `origin/main` = `4f7e1ce3acf43fc015100a6949d42145882447da`. |
| **2** — recompute next-free for the `minor` bump class | **EXECUTED.** Ledger read via `git show origin/main:release/releases/RELEASE_LOG.md` — never the worktree copy. Anchor = the highest Deployment Log row = **v4.47** (`adr-corpus-status-integrity`, VERIFIED 2026-09-02). Next-free = anchor + one minor. Branch-side claims are non-binding and were **not** admitted to the computation: the rule is anchor + 1, never `max(claimed) + 1`. |
| **3** — PROCEED/HALT on claimed-set membership | **PROCEED.** The planned version is absent from all three claimed surfaces and equals the recomputed next-free. Tag surface: absent (highest `v*` tag is `v4.47`). Ledger surface: absent (no row). Plan-file surface: 0 of 191 plan files on `origin/main` mention it, against a sensitivity arm (`4.47` → 2 files) that fired. See § Evidence-of-record for the probe records. |
| **3b** — `release/tools/claim-version.sh --verify-stamp hooks-block-only-their-scope` | **EXECUTED after this file was written and before it was committed.** Read-only, network-free; runs the identical pre-flight the Stage-12 atomic claim runs, so the Commit-0 PROCEED rehearses the real claim rather than a lookalike. Exit 0 was the precondition for committing this file. |

**Consequence for this plan file:** the Header `**Version**` cell carries the stamp-manifest token literally, and the bump-class determination lives in the adjacent `**Bump Class**` row rather than in the version cell. `claim-version.sh` resolves the token and performs the `git mv` to `plans/v<MAJOR>/` on the CAS-win path at Stage 12; a version cell carrying prose instead of the token would make that rename decline.

---

## Scope

### Summary

Seven cards, one dominant file. `core/hooks/block-destructive.sh` is touched by four cards (#6166, #6167, #6172, #6229) and is the central sequencing constraint. **Narrow before widen** is the organising rule, and it rests on verified line ranges rather than assertion: #6172's parse-only exemption lands in the flag walk that #6167's widened interpreter set will traverse, so #6167-after-#6172 inherits the exemption while the reverse order forces a retrofit across a larger set.

Two corrections the Stage-4 re-run made to its own inputs, both load-bearing on how this release is read:

- **The guards are not uniformly in warn mode.** `core/hooks/block-destructive.sh:219` states the hook is MODE-INDEPENDENT and declares no `MODE_FILE`; its only `MODE_FILE` token is inside that comment. The **interpreter and source arms of BLOCK-DESTRUCTIVE-022 are always-enforce and blocking today** — #6172 and #6229 describe live refusals, not would-fires. Only the *exec* arm is phase-gated at `warn`, via the per-rule constant `DESTRUCTIVE_022_EXEC_PHASE` (line 640). The mode-gated hooks are the other two: `block-fs-boundary.sh:54` and `block-draft-files.sh:36`.
- **#5555's named repro has zero instances in its own evidence.** Of 4,605 BLOCK-FS-BOUNDARY-003 warn records, 0 carry an empty operand — the no-operand pipe case the card's title, repro and AC all describe. 4,496 (97.6%) carry a variable-bearing operand across nine verbs. Shipped to its written AC the card would close 0 of 4,605 observed false positives. Re-scoped and re-sized `S → M` at Wave 0.

### Members

Seven open cards, confirmed live against milestone #383 at Commit 0:

| Card | Subject | Primary file |
|---|---|---|
| **#5555** | BLOCK-FS-BOUNDARY-003 false-positives on unresolvable path operands (re-scoped at Wave 0) | `core/hooks/block-fs-boundary.sh` |
| **#5653** | Four security hooks share one positional anchor (AC1 = ADR; AC4 = control arm) | `core/ADRs/` + four test suites |
| **#6115** | `block-draft-files` applies the platform's layout allowlist to nested non-platform repos | `core/hooks/block-draft-files.sh` |
| **#6166** | BLOCK-DESTRUCTIVE-022's hint omits the allowlisted-relative retry | `core/hooks/block-destructive.sh` (hint strings) |
| **#6167** | BLOCK-DESTRUCTIVE-022 anchors on an interpreter token, so shebang-direct invocations escape | `core/hooks/block-destructive.sh` (verb classifier) |
| **#6172** | BLOCK-DESTRUCTIVE-022 refuses `check-convention.sh`, its drift-guard test, and any `bash -n` syntax check | `core/hooks/block-destructive.sh` (flag walk) + allowlist |
| **#6229** | BLOCK-DESTRUCTIVE-022 refuses a report that quotes a script invocation | `core/hooks/block-destructive.sh` (suppression/segmentation) |

Two further cards (#6118, #6175) were closed as already-delivered before this bundle was scaffolded and are **not** members.

### Release Outcome Statement

Every guard hook in the bypass-mode layer refuses exactly what its rule declares, and nothing wider. Today four matchers on three hooks refuse work that is inside no rule's stated scope: a destructive-script rule that blocks the one invocation form which executes nothing, blocks a report that merely quotes a command, and points a refused caller at a retry that cannot match; a filesystem-boundary rule that fires on operands it cannot resolve; and a draft-file rule that applies this repository's layout allowlist to a nested repository that never adopted it.

---

## Release Class Declaration

**Class: `cross-cutting`** — an upward override of the injected `novel` default, re-derived independently from the current 7-card bundle. The prior proposal's evidence base is **not** inherited: it cited edges over 9 cards, two of which lost an endpoint to closure, one of which was invalidated by #5653's own re-scope, and one of which had its direction reversed.

| Trigger | Fires? | Evidence |
|---|---|---|
| `cross-cutting` (a) ≥3 `pipeline/stage-*.md` files | **NO** | zero |
| `cross-cutting` (b) ≥3 of the 6 rule-defining governance surfaces | **NO** | 1 — `hub-spoke-bridge.md` (#6166 AC4) |
| **`cross-cutting` (c) ≥3 in-bundle compositional edges** | **YES** | **3** on the strict reading (E1, E2, E4 — all compositional); 5 counting E3 (semantic) and E5 (verification-ordering) |
| `novel` (a) ≥1 new reference doc / schema / skill | YES | #5653 AC1 adds an ADR |
| `novel` (b) ≥1 D-class decision | YES | D-Concurrency Posture, D-Version, D-ReleaseClass |
| `novel` (c) ≥1 Stage 5 ADR | YES | #5653 AC1 |
| `routine` | **NO** | (a) fails — #6115 is High/release-blocking, #6172 is P2; (c) fails — the ADR is a new file; (d) fails |
| `hotfix` | **NO** | (b) fails — 7 issues, not ≤3 |

Multi-trigger resolution gives `cross-cutting` (`cross-cutting > novel > routine`). The anti-pattern check passes on substance: the three compositional edges are verified ordering constraints on one always-enforce security matcher, not thematic resemblance — landing them out of order reintroduces the exact false positives the milestone exists to remove.

**Differentiation posture:** engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

---

## Dependency Graph

Directional. `A → B` reads *"B lands after A."* Nodes are the 7 open cards only.

```
  GENERATOR 1 — BLOCK-DESTRUCTIVE-022's own private lexical model
  (core/hooks/block-destructive.sh — 4 cards, 1 file, 4 disjoint regions)
  ----------------------------------------------------------------------
      #6172 ──(narrows: allowlist rows + parse-only flag exemption)──┐
                                                                     │
      #6229 ──(narrows: heredoc modelling, script_qbail at :1269)────┼──► #6167
                                                                     │    (WIDENS the
      #6166 ──(guidance must precede widened enforcement)────────────┘     interpreter set)

      #6172 ──(supplies the allowlist entries the new hint points at)──► #6166

  GENERATOR 2 — shared positional anchor (lib/command-position.awk, 4 hooks)
  -------------------------------------------------------------------------
      #5555 ──(AC4's control arm spans block-fs-boundary.sh)──► #5653 (AC4 only)

      #5653 ──╳── {#6166, #6167, #6172, #6229}      EDGE NEGATED — see below

  GENERATOR 3 — nested-repo scope class
  -------------------------------------
      #6115   (no in-bundle edge on the additive-predicate design;
               becomes an edge to EVERY card if the fix changes
               lib/scope-guard.sh's shared contract — see Risk R-4)
```

**Edge inventory with evidence:**

| Edge | Type | Evidence |
|---|---|---|
| **E1** `#6172 → #6167` | compositional, ordering-critical | #6172's parse-only exemption belongs in the flag walk. #6167 widens the verb classifier at both of its views and the operand domain in `script_operand_domain_hit`. Landing the widening first forces the exemption to be retrofitted across a larger interpreter set instead of inherited from the walk. **Outcome, measured:** #6172's per-interpreter table needed no change — all five newly-admitted keys correctly hit its documented explicit null, and #6167 owed it test evidence rather than a code edit (`T-NSI-05a`..`T-NSI-05e`). *Line numbers dropped: the Stage-4 cites were invalidated by #6172 and #6229 landing first, and unevenly — the classifier moved ~470 lines while `script_operand_domain_hit` did not move at all.* |
| **E2** `#6229 → #6167` | compositional, ordering-critical | #6229's root cause is `block-destructive.sh:1269` — `*'<<'*) script_qbail=1 ;;` — with the in-file comment at `:1222` reading that heredocs are not modelled and suppression is switched off entirely for any command containing `<<`. Widening the adjudicated token population before that residual is modelled enlarges exactly the false-positive class #6229 removes. |
| **E3** `#6172 → #6166` | semantic / content-correctness | #6166's new hint names the allowlisted-relative retry **first**. For the two paths #6172 names, that retry has nothing to match: both are absent from the allowlist's 289 non-comment entries. The hint is untruthful for those paths until #6172's rows land. |
| **E4** `#6166 → #6167` | compositional | #6167's own body: enforcement without guidance leaves a blocked agent with no correct next move. Widening enforcement on an always-enforce rule ahead of the corrected hint strands newly-blocked agents on the old text. **Direction corrected** at the Stage-4 re-run. |
| **E5** `#5555 → #5653` | verification-ordering (soft) | #5653's AC4 control arm spans the four anchor-carrying hooks, one of which is `core/hooks/block-fs-boundary.sh` — #5555's file. Running AC4 before #5555 lands measures a superseded state. Applies to AC4 only; AC1 is unblocked. |

**Two negated / corrected edges. Their absence is load-bearing, so it is recorded rather than left silent.**

- **`#5653 ↛ {#6166, #6167, #6172, #6229}` — NEGATED, verified at source.** `core/hooks/block-destructive.sh:150-153` states that BLOCK-DESTRUCTIVE-022 is deliberately not routed through the shared positional anchor: its segment loop and cumulative quote-parity tracking read the command directly and own their own lexical model. The shared-anchor card does **not** gate the -022 cluster, and the cluster must not be sequenced behind it.
- **`#5653 → #5555` — INVALIDATED** (carried by the prior plan as its E4). The premise was that a #5653 parser selection would relocate #5555's fix site. #5653's scope revision records that the shipped implementation is the widened shared matcher, not the parse-based decision, and that what remains is recording it plus one control arm. Neither changes a token stream, so neither can relocate anything. The surviving relationship runs the other way and is weaker: E5.
- **`#6167 → #6166` — DIRECTION REVERSED.** The prior rationale assumed the hint enumerates the covered interpreter set. It does not, and need not. Recorded as **E4**; co-delivery in adjacent commits is an equally safe discharge and is the recommended form.

**Cycles: zero.** Longest chain is `#6172 → #6166 → #6167` (depth 3), no revisit. Probe record in § Evidence-of-record.

---

## Implementation Sequence

Dependency-ordered. Per the milestone-is-one-PR convention these are **commit waves on a single release branch**, not separate PRs. This is the Stage-6 dispatch order.

**Wave 0 — Tier 1 [ADJUST] gate (no code, no branch). Completed before Wave 1 opened.**

| Card | Action | Basis |
|---|---|---|
| **#5555** | RE-SCOPE + RE-SIZE | Its named repro class has 0 of 4,605 instances. Retargeted to *unresolvable path operands* across the measured nine-verb set, dominated (97.6%) by variable-bearing operands. Re-sized **S → M**. |
| **#6167** | AC4 mechanism correction | AC4 demanded a committed warn default read from a mode declaration the hook does not have. Retargeted to a per-rule phase constant in the `DESTRUCTIVE_022_EXEC_PHASE` pattern. |

**Wave 1 — file-disjoint, parallel-safe.**
- **#6172** — `core/config/allowlists/script-execution-allowlist.txt` (4 relative-form rows) + `core/hooks/block-destructive.sh` flag walk (parse-only exemption) + `core/rules/bypass-mode-readiness/block-destructive.md`. **Narrows first, deliberately.** Sole Wave-1 owner of `block-destructive.sh`.
- **#6115** — `core/hooks/block-draft-files.sh` (+ `core/hooks/lib/scope-guard.sh` **only if** Stage 5 selects the shared-contract design; see R-4). Sole owner of `block-draft-files.sh`.
- **#5555** (re-scoped) — `core/hooks/block-fs-boundary.sh`, `resolve_and_classify()` / `extract_target_tokens()` / `check_verb()`'s strict branch. Sole owner.
- **#5653 (AC1 only)** — the ADR recording the matcher-vs-parser decision. New file; no hook edit; no in-bundle edge.

**Wave 2 — #6229.** `core/hooks/block-destructive.sh`, the suppression/segmentation region. Serial on the file. Line-disjoint from Wave 1's flag walk, so the serialization is a risk posture on a security matcher, not a merge necessity — see R-2.

**Wave 3 — #6166.** `check_script_target()` hint strings at `block-destructive.sh:597`, `:603`, `:609`, plus the spoke-brief guidance in `release/references/how-to/hub-spoke-bridge.md`. Depends on #6172 (E3). Line-disjoint from every other card.

**Wave 4 — #6167 (re-scoped).** Verb classifier at both views + per-interpreter operand domains in `script_operand_domain_hit()`, plus the new per-rule phase constant family and its verdict router. Lands **after** both narrowings (E1, E2) and after the corrected guidance (E4). Last of the -022 cluster by construction.

**Wave 5 — #5653 (AC4 only).** The control arm across the four anchor-carrying hooks, run after #5555 lands (E5).

**Why narrow-before-widen — verified against the diffs, not adopted.** #6167 increases what is adjudicated; #6172 and #6229 decrease what is refused. Landing the widening first opens a window in which agents are newly blocked on parse-only syntax checks and on posting reports that quote invocations — the two failure modes this milestone exists to remove, reintroduced by its own sequencing.

---

## Stage Applicability Matrix

Stages 9–13 are release-scoped (one sub-task each for the whole release), so per-card variation exists only at 5–8.

| Card | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA Testing | 9–13 |
|---|---|---|---|---|---|
| **#5555** | **RUN** — the resolution policy for a variable-bearing operand is an open design question | RUN | RUN | RUN | release-scoped |
| **#5653** | **RUN** — AC1 *is* a design-record act (ADR authorship) | RUN | RUN | RUN | release-scoped |
| **#6115** | **RUN** — must produce a positive reproduction (R-5) and select additive-predicate vs shared-contract (R-4) | RUN | RUN | RUN | release-scoped |
| **#6166** | **SKIP — trivial** | RUN | RUN | RUN | release-scoped |
| **#6167** | **RUN** — the phase-gate mechanism is unresolved after the Wave-0 AC4 correction | RUN | RUN | RUN | release-scoped |
| **#6172** | **RUN** — the parse-only exemption must be scoped per-interpreter, not to a literal `-n` (CIAC-2) | RUN | RUN | RUN | release-scoped |
| **#6229** | **RUN** — largest design surface in the bundle; modelling heredocs is a declared-open residual, not a bug fix | RUN | RUN | RUN | release-scoped |

**#6166 Stage-5 SKIP rationale, and its limit.** The change is a reordering of three existing hint strings plus one added sentence plus a brief-template addition — no predicate moves, and the matcher is untouched. It does **not** skip Dev Testing or QA: the hint is emitted output, AC1 asserts ordering and AC3 asserts a zero-line allowlist diff, and both are gradable only by running them.

**No other card skips Dev Testing or QA.** Every remaining card changes a predicate on a security hook — functional impact by construction.

---

## Contention Map

**Primary contention: `core/hooks/block-destructive.sh` — 4 of 7 cards.** The four regions are disjoint at line level, which is what makes the wave structure a sequencing choice rather than a merge necessity.

| Card | Region in `block-destructive.sh` | Approx. lines | Overlaps |
|---|---|---|---|
| **#6172** | flag walk + parse-only predicate | ~1470–1520, ~1695–1725 | adjacent to #6167 |
| **#6167** | verb classifier (both views) + `script_operand_domain_hit()` + the new constant family and router | *named by content, not line — see the Wave-4 matrix note* | **adjacent to #6172, and it collided at the classifier as predicted** |
| **#6229** | `script_qnext()` / `script_qadvance()`, `script_qbail` heredoc branch, segment splitter | 784–889, 1160–1162, ~1269 | none |
| **#6166** | `check_script_target()` message strings | 660, 666, 672 (as landed; 597/603/609 at Stage-4 baseline, before #6172 and #6229 shifted the file) | none |

**#6167 and #6172 are the only line-adjacent pair.** Everything else on this file is line-disjoint.

**Second contention surface: `core/hooks/lib/scope-guard.sh`** — sourced by 13 of 27 hook scripts. If #6115's fix changes the shared contract rather than adding a predicate, it becomes the widest-blast-radius change in the bundle, reaching both #5555's hook and the -022 cluster's hook. Design-gated at Stage 5; see R-4.

**Third surface: `core/hooks/lib/command-position.awk`** — consumed by 4 hooks plus 4 test suites, the CI layout helper, and the refresh-hooks test. **No card in this bundle edits it.** A shared surface with zero in-bundle write contention.

**Secondary contention — `core/hooks/tests/block-destructive.test.sh` (5 cards) and `core/rules/bypass-mode-readiness/block-destructive.md` (4 cards).** Both are **append-pattern** surfaces (`overlap_class = append-pattern` per ADR-005). Structurally HIGH, operationally LOW. No sequencing mitigation required beyond the wave order the hook file already imposes.

**Cross-PR contention at baseline: none.** In-Flight Release Roster measured at the Stage-4 instant, n=5 siblings, every bump-class `UNRESOLVABLE` (recorded rather than blank: no sibling declares a bump-class readable from its head, so the slot comparison could not be made — an unknown, not an absence). Two siblings warrant a Stage-9 re-check: `hub-spoke-run-and-planning-discipline` could touch `release/references/how-to/hub-spoke-bridge.md`, which #6166 edits; `adr-corpus-integrity` could touch `core/ADRs/`, where #5653 adds a file. Neither intersection is observable pre-merge from a draft head — the verdict belongs to Stage 9 Phase A6.6.

---

## File Change Matrix

Union across the 7 cards, transcribed from Stage 4 and reconciled to the approved Stage-5 design for #6172 (#6709). One path per line.

```
# EDIT — #5555 (Wave 1)
core/hooks/block-fs-boundary.sh                              EDIT   #5555 — unresolvable-operand handling in resolve_and_classify() / extract_target_tokens() / check_verb() strict branch
core/hooks/tests/block-fs-boundary.test.sh                   EDIT   #5555 — arms for the nine-verb unresolvable-operand set
core/rules/bypass-mode-readiness/block-fs-boundary.md        EDIT   #5555 — published coverage boundary follows the shipped predicate
core/rules/bypass-mode-readiness.md                          EDIT   #5555 — GENERATED index (ADR-030): regenerated via core/deploy/tools/build-hook-registry.py, never hand-edited. Row absent from the Stage-4 matrix; added per the Stage-5 correction (D-D). The section anchor derives from the heading, so the rule-ID range change desyncs the index link unless it is regenerated and committed

# ADD — #5653 (Wave 1 AC1, Wave 5 AC4)
core/ADRs/ADR-182-command-position-is-a-canonicalizer-not-a-parser.md   ADD    #5653 — AC1: records the command-start position decision. Reconciled from the Stage-4 placeholder row `ADR-NNN-matcher-vs-parser.md` to the delivered filename; the number was allocated at authoring and the slug follows the approved Stage-5 design, so the placeholder was unsatisfiable by construction
core/hooks/tests/command-position-fp-control.test.sh                    ADD    #5653 — AC4 control arm. ONE cross-cutting Tier-1 arm at the canonicalizer boundary, reversing the Stage-4 assumption of four per-hook suite EDITs per the approved Stage-5 design: the subject is a single shared primitive, so four copies would reproduce the card's own one-implementation anti-pattern. This card leaves all four per-hook suites unchanged: `block-egress.test.sh` and `block-rm-prefer-trash.test.sh` see no change on this branch, and the two that do change are `block-destructive.test.sh` (#6166/#6167) and `block-fs-boundary.test.sh` (#5555), each declared under its own card

# EDIT — #6115 (Wave 1)
core/hooks/block-draft-files.sh                              EDIT   #6115 — nested-repo scope predicate
core/hooks/lib/scope-guard.sh                                EDIT?  #6115 — CONDITIONAL:shared-contract-design-selected (see R-4); absent under the additive-predicate design
core/hooks/tests/block-draft-files.test.sh                   EDIT   #6115 — positive-reproduction arm + nested-repo arms

# EDIT — #6166 (Wave 3)
core/hooks/block-destructive.sh                              EDIT   #6166 — check_script_target() hint strings, landed at :660, :666, :672 (hint text only; no predicate moves)
release/references/how-to/hub-spoke-bridge.md                EDIT   #6166 — spoke-brief guidance addition
core/hooks/tests/block-destructive.test.sh                   EDIT   #6166 — hint-ordering arms + zero-line allowlist-diff arm

# EDIT — #6167 (Wave 4) — reconciled to what shipped. Line numbers deliberately
# NOT cited: the Stage-4 row named :1477 / :1491, which #6172 and #6229 had already
# invalidated before this card ran — the classifier had moved ~470 lines while
# script_operand_domain_hit had not moved at all, so a spot-check of the stable
# anchor would have read as confirmation. Anchors are named by CONTENT.
core/hooks/block-destructive.sh                              EDIT   #6167 — verb classifier (both raw and normalized views) gains the five interpreter literals; script_set_interp_domain() + four sibling operand-domain arms beside the byte-preserved interp body; exec domain widened to the union; DESTRUCTIVE_022_INTERP_* constant family + destructive_022_interp_verdict(); log_would_fire_022() gains an `arm` field; DESTRUCTIVE_022_EXEC_ARMED re-dated as a recorded decision; domain threading at the three call sites
core/hooks/tests/block-destructive.test.sh                   EDIT   #6167 — the T-NSI-* family (+46 arms) incl. two paired mutation arms and the #6724 pin; T-EXEC-7 retargeted, its subject having moved arms
core/deploy/deploy.sh                                        EDIT   #6167 — Check 71 parameterized over the constant-family list (EXEC, INTERP) rather than copied a third time; drain split on the `arm` field, absent field read as `exec`
core/config/allowlists/script-execution-allowlist.txt        EDIT   #6167 — header enumerates the adjudicated invocation shapes; NEW non-shell section, deliberately EMPTY, stating rows come from drain evidence
core/rules/bypass-mode-readiness/block-destructive.md        EDIT   #6167 — declared scope follows the widened classifier; per-interpreter operand-domain table; interpreter-arm rollout paragraph; three declared residuals
core/rules/bypass-mode-readiness.md                          EDIT   #6167 — registry row + the per-RULE-ARM, drain and readiness-checklist claims that said the rule had exactly one phase-gated arm
core/rules/bypass-mode-readiness/_cross-cutting.md           EDIT   #6167 — the same three mirrored claims
core/ADRs/ADR-150-block-destructive-022-governs-execution-capability.md  EDIT   #6167 — Consequences records that the accepted scope reaches non-shell interpreters and that the phase-gate pattern was reused; no new ADR, to avoid a second source of truth for one rationale

# EDIT — #6172 (Wave 1) — reconciled to the approved Stage-5 design on #6709
core/config/allowlists/script-execution-allowlist.txt        EDIT   #6172 — +4 repository-relative-form rows (2 per script) in 2 commented blocks, each carrying the CIAC-1 four-form-divergence guard
core/hooks/block-destructive.sh                              EDIT   #6172 — NEW script_interp_noexec_flag(); capture script_interp_base at both verb-classifier branches; script_noexec reset + set in the flag walk; parse-only exemption after the walk's arity guard
core/hooks/tests/block-destructive.test.sh                   EDIT   #6172 — +12 PARSE-* arms (exemption, per-interpreter null, executing-form fixture table, allowlist controls, mutation arm)
core/rules/bypass-mode-readiness/block-destructive.md        EDIT   #6172 — parse-only exemption paragraph + note on the -022 registry row

# EDIT — #6229 (Wave 2)
core/hooks/block-destructive.sh                              EDIT   #6229 — NEW script_hd_delim_ok() + script_heredoc_prescan() inserted after script_qadvance and before script_resolve_head; the blunt `*'<<'*) script_qbail=1` latch REPLACED by the prescan call plus a narrowed residual-bail; the segment splitter reads script_hdstripped and now runs AFTER the pre-pass; the "HEREDOCS ARE NOT MODELLED" invariant paragraph rewritten to the modelled contract + four residuals; the falsified `$( )` / backtick / `<( )` command-position claim corrected in comment only
core/hooks/tests/block-destructive.test.sh                   EDIT   #6229 — +33 HD-* arms (transport parity, carrier x delimiter matrix, stdin-executing controls, post-terminator, receiver-resolution-across-a-separator, unresolvable-bail, structural non-heuristic probe, paired mutation arm). Append-only; arm AC-FP-2x PRESERVED UNCHANGED as the inherited control
core/rules/bypass-mode-readiness/block-destructive.md        EDIT   #6229 — heredoc-modelling contract + the four named residuals replace the "outside the model" paragraph
core/rules/bypass-mode-readiness.md                          EDIT   #6229 — GENERATED index (ADR-030): regenerated via core/deploy/tools/build-hook-registry.py, never hand-edited. Carries a byte-identical duplicate of the per-hook here-document paragraph and is absent from every other card's matrix in this bundle; without this row the umbrella index would assert the opposite of the shipped behaviour

# RELEASE ARTIFACTS (pipeline-standard)
release/releases/plans/hooks-block-only-their-scope_RELEASE_PLAN.md   ADD    — this plan (Engineering Commit 0); renamed to plans/v<MAJOR>/ at the Stage-12 claim
release/releases/RELEASE_LOG.md                              EDIT   — Stage 12 Deployment Log row
CHANGELOG.md                                                 EDIT   — Stage 13
```

**No skill packages are affected. No `deploy.sh` check changes.** The deployed allowlist is regenerated by `deploy.sh` from the source file.

**domain_practice:** `{ source: N/A — pipeline-internal release, date: 2026-09-02, domain: software }` — the File Change Matrix is entirely internal pmo-platform artifacts (hook scripts, test suites, an allowlist, rule fragments, one ADR, one how-to) → sourcing-exempt, `domain: software` with `governance` secondary.

---

## Cross-Issue Acceptance Criteria

Testable predicates spanning ≥2 issues, graded on the merged PR at Stage 9 (QC3.5). Transcribed verbatim from the Stage-4 re-run plan.

- [ ] **CIAC-1 (#6172 × #6166 on `core/config/allowlists/script-execution-allowlist.txt` + the -022 hint):** every path this release adds to the allowlist is reachable by the invocation form the new hint names **first**, so the hint is truthful for the paths the same release introduces. *Shared surface:* the allowlist file and the `check_script_target()` hint strings. *Method:* for each line added to `core/config/allowlists/script-execution-allowlist.txt` in this PR, assert the line is a repository-relative form and that the hint's first-named retry describes that form. Control arm: an absolute-path spelling of the same script is **not** matched by the added entry — an observed non-zero refusal. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#6172 × #6167 on `core/hooks/block-destructive.sh` flag walk):** the parse-only exemption is expressed as a **per-interpreter** table, not a literal `-n`, so #6167's widened interpreter set inherits it rather than retrofitting it. *Shared surface:* the flag walk and verb classifier. *Method:* read the implementation; assert the exemption is keyed by interpreter and that every interpreter admitted by #6167 carries either a parse-only entry or an explicit documented null. Control arm: an **executing** form of a non-shell interpreter on a non-allowlisted script is still refused — an observed non-zero block. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#6166 × #6167 × #6172 × #6229 on `core/hooks/tests/block-destructive.test.sh`):** after all four land, every assertion the suite carried at the baseline still holds, and each card's own must-block control arm fires. *Shared surface:* the -022 test suite. *Method:* run `core/hooks/tests/block-destructive.test.sh`; assert the baseline assertion count is met or exceeded with zero prior-arm regressions, and assert each of the four new control arms returns an observed non-zero block. A suite that goes green by **removing** arms fails this criterion. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#6167 × #6172 on the -022 phase mechanism):** no change in this release introduces a shared-`.mode` read into `core/hooks/block-destructive.sh`; any new phase gate is a per-rule constant in the `DESTRUCTIVE_022_EXEC_PHASE` pattern. *Shared surface:* `block-destructive.sh`'s mode posture. *Method:* assert the file's only `MODE_FILE` occurrence remains the line-219 comment stating the hook declares none, and that any new phase gate is a `readonly` per-rule constant. **Null predicate — control arm:** the same instrument against `core/hooks/block-fs-boundary.sh` returns an observed non-zero `MODE_FILE` count (5 at baseline), proving the probe discriminates a mode-gated hook from a mode-independent one rather than returning a vacuous zero. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-5 (#5555 × #6115 × #6167 on the shared mode dial):** this release performs no warn-to-enforce mode flip. *Shared surface:* `core/hooks/.mode.template` and any `.mode` read. *Method:* assert zero lines changed in `core/hooks/.mode.template` (baseline content: `warn`) and that no card adds a `.mode` write. **Null predicate — control arm:** the same diff instrument reports a non-zero changed-line count for `core/hooks/block-destructive.sh`, a file this release does change — so a zero on the template is a real zero and not an unresolvable path. *Graded at Stage 9 QC3.5 on the merged PR.*

---

## Risk Register

| ID | Risk | Severity | Reversibility | Mitigation |
|---|---|---|---|---|
| **R-1** | **Widening lands early and re-blocks the class this milestone removes.** #6167 widens adjudication on an arm that is always-enforce, not warn-gated. If it lands before #6172/#6229, agents are newly refused on parse-only checks and on reports quoting invocations. | **HIGH** | MODERATE | Wave order E1/E2/E4. **CIAC-3** grades the parity. Verified at line level, not thematically. |
| **R-2** | **Four cards, one file, one always-enforce security matcher.** Regression here weakens a live control rather than a warn-only one. | **HIGH** | MODERATE | Serial waves on `block-destructive.sh` even where line-disjoint. Every card carries its own must-block control arm; **CIAC-3** asserts prior arms hold. |
| **R-3** | **#6167's AC4 named a mechanism the hook does not have.** The hook declares no `MODE_FILE` and lines 624–640 explicitly reject the shared `.mode` for this purpose. | **HIGH** | CHEAP | Wave 0 [ADJUST]: retarget AC4 to a per-rule phase constant. **CIAC-4** asserts no `MODE_FILE` appears and no shared-`.mode` read is introduced. |
| **R-4** | **#6115's blast radius is design-dependent, spanning 1 hook to 13.** An additive repo-identity predicate touches `block-draft-files.sh` alone. A change to `scope_guard_root()`'s contract reaches all 13 consumers. | **MEDIUM** | MODERATE→EXPENSIVE | Stage-5 gate: select additive-predicate, or escalate. The `scope-guard.sh` row is **CONDITIONAL** in the matrix and promotes in-commit if the condition fires. |
| **R-5** | **#6115 rests on the weakest evidence in the bundle, and the evidence is partly mis-attributed.** 64 BLOCK-DRAFT-001 warn records; the `examples/`+`outputs/` majority (42 of 64) are platform-repo paths at non-governed roots — the rule working correctly, not the defect. At most ~12 records are plausibly the nested-repo class. | **MEDIUM** | CHEAP | Positive reproduction at Stage 5. Do **not** run a second absence probe. If reproduction fails, route Tier 1 [ADJUST]. |
| **R-6** | **#5555 shipped to its written AC would close 0 of 4,605 observed false positives.** | **HIGH** | CHEAP | Wave 0 re-scope + re-size, completed before Engineering. |
| **R-7** | **A shared-file rollback is not per-card.** Reverting one -022 card after four have landed on one file means reverting a range, not a commit. | **MEDIUM** | MODERATE | One card per commit, no squashing within the -022 cluster, each commit naming its card and its region. Rollback unit = the commit; the wave order makes later-to-earlier revert the safe direction. |
| **R-8** | **Sibling-release collision on two shared surfaces.** `hub-spoke-bridge.md` (#6166) and `core/ADRs/` (#5653) are plausible targets for two in-flight siblings whose intersection is unobservable from a draft head. | **LOW** | CHEAP | Recorded in the In-Flight Roster; verdict at Stage 9 Phase A6.6 against a fresh measurement. |
| **R-9** | **Mode-flip pressure.** Four of these cards narrow an always-enforce rule and two narrow warn-gated rules; a reviewer may read the pairing as an argument to flip `.mode` to `enforce`. | **LOW** | EXPENSIVE | **Explicitly out of scope.** No card touches `.mode` or `.mode.template`. **CIAC-5** asserts the null with a control arm. |

**Reversibility of the release as a whole: MODERATE · confidence HIGH.** Every change is a file edit on a git-tracked hook with per-card test arms; nothing is data-destructive and nothing crosses a host boundary. The MODERATE (rather than CHEAP) tier is set by R-7.

---

## Verification Plan

### AC baseline

**`core/hooks/tests/block-destructive.test.sh` carries 398 arms at baseline `4f7e1ce3`** — `Total: 398  PASS: 398  FAIL: 0`, measured by running the suite from the **materialized CI layout** emitted by `core/hooks/tests/setup-ci-layout.sh`. This is the **runner's own reported total**, not a source grep, and the distinction is load-bearing: a grep-anchored baseline stays green after arms are deleted, which is precisely the failure CIAC-3 exists to catch.

**Why every grep-family figure undercounts.** The suite computes `Total` as `PASS + FAIL` accumulated across **11 distinct assertion-increment sites**, of which only four are the named `test_case` / `exec_warn_case` / `exec_notflag_case` / `sandbox_case` helpers. A call-site count of those four families returns **323** at this baseline (control arm: a non-existent helper returns 0), missing the other seven increment sites entirely. Any baseline in the 320s is therefore a helper-family count wearing a runner label. **398 is the figure every `≥ baseline` assertion in this plan is written against.**

Whole-suite baseline at `4f7e1ce3`, same invocation: **AGGREGATE PASS=1165 FAIL=0** across 21 suites.

### Per-Issue Verification

| Issue | AC | Predicate class | Verification Method | Expected Result |
|---|---|---|---|---|
| #6172 | AC-1 | runtime | Run the hook suite from the materialized CI layout (`setup-ci-layout.sh` then `test-runner.sh`) and assert arms `PARSE-01`..`PARSE-05` are present and green: the four relative spellings of `core/deploy/tools/check-convention.sh` and `core/deploy/tests/test_check49_mode_identifier_unification.sh` return exit 0. Control arm that must fire: `bash core/deploy/tools/no-such-tool-xyz.sh` returns exit 2 with `BLOCK-DESTRUCTIVE-022` | Four spellings ALLOW; control arm observed BLOCK, so a green AC-1 cannot be a dead allowlist |
| #6172 | AC-2 | content | file-state grep: every line added to `core/config/allowlists/script-execution-allowlist.txt` is a repository-relative form, and the added block carries the inline four-form-divergence guard comment | Added rows relative-only (4 rows); guard comment present; absolute spelling still refused |
| #6172 | AC-3 | runtime | Assert arm `PARSE-07` is present and green — `bash -n <non-allowlisted>.sh` returns exit 0. Sensitivity arm that must fire: the same path without `-n` returns exit 2 + `BLOCK-DESTRUCTIVE-022` | Subject ALLOW and sensitivity arm BLOCK, both observed; a green subject without a red arm is a blanket allow |
| #6172 | AC-4 | runtime | Per-interpreter scoping (CIAC-2): `sh -n` and `zsh -n` return exit 0; control arms `source -n` and `. -n` return exit 2 + `BLOCK-DESTRUCTIVE-022` | Shell trio exempt; the two builtins still blocked, proving the table is keyed by interpreter and not by the token |
| #6172 | AC-5 | runtime | Assert arms `PARSE-12a`..`PARSE-12g` are present and green. Executing-form fixture table: `bash <p>`, `bash -x <p>`, `bash -s <p>`, `bash -- <p>`, `bash -c 'echo hi' -n <p>`, `bash -n -c 'echo hi' <p>` each return exit 2 + `BLOCK-DESTRUCTIVE-022`; control arm `bash -n <p>` returns exit 0 in the same run | Six executing forms BLOCK, control ALLOW — the table discriminates rather than blanket-blocking |
| #6172 | AC-6 | runtime | Assert arms `PARSE-14a`..`PARSE-14c` are present and green. Paired mutation arm: copy the hook to a sibling path, revert the exemption, re-run AC-3's subject. Assert PASS on the shipped hook and FAIL on the mutant | Both verdicts recorded; a mutation leaving AC-3 green is inert and fails this criterion |
| #6172 | AC-7 | regression | Run the suite from the materialized layout; assert total arms ≥ 398 with zero failures, and that `bash -n core/deploy/deploy.sh` still returns exit 0 | Arm count ≥ baseline, zero failures; a suite green by removing arms fails |
| #6172 | AC-8 | content | doc-conformance grep of `core/rules/bypass-mode-readiness/block-destructive.md` for the parse-only exemption, its per-interpreter scoping, and both declared residuals (clusters, `-o noexec`). Control arm: the same instrument against the pre-change file returns zero matches | All three present post-change; control arm zero, so the assertion is not vacuous |
| #5555 | AC-all | content | `grep -c BLOCK-FS-BOUNDARY-004 core/hooks/tests/block-fs-boundary.test.sh` returns ≥ 5 — the advisory-admit arms and their paired must-block control arms are present, so a variable-bearing operand across the measured nine-verb set is adjudicated by the guard cascade rather than blanket-refused under BLOCK-FS-BOUNDARY-003. Control arm that must fire: the same instrument against the pre-change file returns 0. The suite itself runs from the materialized CI layout (`setup-ci-layout.sh` then `test-runner.sh`) — 76 arms, 0 failures, up from 48 — and the population replay is graded at Stage 7 | Advisory arms and their must-block twins present; pre-change control returns zero, so the assertion is not vacuous |
| #5653 | AC1 | content | file-state check: `test -f` the ADR under `core/ADRs/`; assert it is present and carries the canonical section headers, and records the widened-shared-matcher decision | ADR present and schema-conformant |
| #5653 | AC4 | runtime | `grep -c '^check_case ' core/hooks/tests/command-position-fp-control.test.sh` returns ≥ 15 — the false-positive corpus meets the AC4 floor. ONE cross-cutting Tier-1 arm at the canonicalizer boundary, not four per-hook suite edits (Stage-5 reversal of the Stage-4 assumption): the four hooks sit behind the scope guard, so an end-to-end FP assertion passes vacuously when the payload cwd falls out of scope. (An earlier revision of this row added that "the armed fs-boundary FP baseline is already red for reasons this card does not own" — that claim was false, descended from an unsupported source-tree suite run, and is retracted: `block-fs-boundary.test.sh` reports 76 arms, 0 failures through the materialized layout. The Tier-1 design stands unchanged on the vacuity ground stated immediately above, which the retraction does not touch.) Control arm that must fire: the same instrument against the pre-change tree returns 0. The suite runs from the materialized CI layout (`setup-ci-layout.sh` then `test-runner.sh`) — 1294 arms, 0 failures, up from 1235 — and the AC4 disposition is read from the arm's own `AC4-TIER1-VERDICT` line, never the runner aggregate. Run after #5555 lands (E5), on a corpus carrying the variable-bearing operand shapes across #5555's nine verbs | armed=yes, corpus=25, newly-blocked=0, fp-matches=0, start-live=11/11. Arming sentinel observed firing; with the canonicalizer neutered to a pass-through the same file emits `INSTRUMENT-UNARMED` and exits 1 while newly-blocked is still 0 — so the zero is readable rather than vacuous |
| #6115 | AC-all | runtime | Positive reproduction first (the obvious probe fail-opens from a non-repo cwd), then `core/hooks/tests/block-draft-files.test.sh` from the materialized layout; assert the new arms are present and green and that AC3's `PMO_SCOPE_GUARD_ROOT` narrowing is not introduced | Reproduction observed before the fix and absent after; suite green; no env-narrowing introduced |
| #6166 | AC1,AC2 | runtime | Run the hook suite from the materialized CI layout (`setup-ci-layout.sh` then `test-runner.sh`) and assert arms `HINT-01a`..`HINT-03b` are present and green. Each `b` arm pins the Override line positionally — `Override: ` immediately followed by the retry, then `repository root`, then `AS WRITTEN`, then the allowlist, then the bypass — so presence alone cannot pass it; each paired `a` arm pins which cause class emitted the string, so a payload that drifted to another arm cannot satisfy its partner. Line numbers are deliberately not cited: the Stage-4 row named `:597/:603/:609`, which #6172 and #6229 had already invalidated before this card ran | All six arms green; the retry is named first in all three strings, and the bypass is present and last |
| #6166 | AC3 | content | file-state grep: zero lines changed in `core/config/allowlists/script-execution-allowlist.txt` across this card's commits, with a control arm on `core/hooks/block-destructive.sh` — a file this card does change and which must therefore report non-zero, so a zero on the allowlist means the file was never touched, rather than that the diff never ran. The behavioural twin is graded with the AC1/AC2 suite run above: the quoted bare-relative spelling the hint itself prints is permitted, and the ABSOLUTE spelling of that same script is still refused — the asymmetry the hint asserts, and the guard that goes red if anyone broadens the allowlist to absolute forms | Allowlist diff zero lines; control arm non-zero; the relative spelling allows and the absolute one blocks |
| #6166 | AC4 | content | `grep -c Retrying release/references/how-to/hub-spoke-bridge.md` returns >= 1 — the spoke-brief template's § Hook-Response Discipline carries the allowlisted-relative retry, so a spoke inherits it rather than rediscovering it. The bullet leads the "look like evasion and are not" list, which is where the tension it resolves is created: the paragraph directly above forbids re-attempting a refused action, and a spoke reasoning from that alone concludes the retry is prohibited. Sensitivity arm on the known-present adjacent clause "look like evasion and are not"; specificity arm on a token absent from the file | Count >= 1; retry ordered ahead of widening and the bypass, with the bypass still present and last; sensitivity arm non-zero, specificity arm zero |
| #6167 | AC-all | runtime | Run the hook suite from the materialized CI layout (`setup-ci-layout.sh` then `test-runner.sh`) and assert arms `T-NSI-00`..`T-NSI-11e` are present and green: a non-allowlisted script invoked through each of `python`, `python3`, `perl`, `ruby` and `node` is adjudicated and writes one drain row carrying `arm=interp-nonshell`. Control arms that must fire in the same run: the identical operand once allowlisted writes NO row and the pair re-closes when the row is removed (`T-NSI-02a`..`T-NSI-02c`); an out-of-domain operand under the same interpreter is not adjudicated, and `bash` with a `.py` operand is not, while `bash` with a `.sh` operand hard-refuses (`T-NSI-03a`..`T-NSI-03e`); the shell trio and `source` hard-refuse with a ZERO drain delta while the same fixture stem under `python3` returns success and writes a row (`T-NSI-04a`..`T-NSI-04e`); `-n` is not exempted for any newly-admitted interpreter while `bash -n` still is (`T-NSI-05a`..`T-NSI-05e`); the extensionless residual stays pinned (`T-NSI-06e`). The phase gate is graded BEHAVIOURALLY across all three enum values, never by reading the literal: the shipped constant allows with a notice, an `enforce` copy hard-refuses, a `shadow` copy allows silently and still writes its row, and an out-of-enum copy fails closed (`T-NSI-10a`..`T-NSI-10e`). Two paired mutation arms each assert the mutant differs from the shipped hook before anything it reports is believed — reverting the classifier to the shell trio, and removing only the operand domains, which must ALSO go inert and so proves the verb widening alone adjudicates nothing (`T-NSI-11a`..`T-NSI-11e`). Check 71's parameterization is graded separately at Stage 7 by reading its own emitted verdict lines, one per constant family | 1381 arms, 0 failures, up from 1335; `block-destructive.test.sh` 507, up from 461. Reverting the classifier and re-running the whole harness turns 20 of the new arms red while every must-not-flag control stays green, so the arms are live detectors. Check 71 emits a CTRL, DENOM and verdict line for `destructive-022-exec-graduation` and `destructive-022-interp-graduation`, both extractor control arms discriminating and neither contributing a finding against the shipped hook; with an out-of-enum value planted in either family it emits a finding naming that family, so the gate is observed discriminating rather than uniformly silent |
| #6229 | AC-all | runtime | Run the hook suite from the materialized CI layout (`setup-ci-layout.sh` then `test-runner.sh`) and assert arms `HD-01a`..`HD-16` are present and green: a report quoting an interpreter invocation as evidence, delivered by here-document into a carrier, returns exit 0, and so does the same report delivered by file path — the transport no longer decides. Control arms that must fire in the same run: an interpreter reading its program from a here-document (`HD-02a`..`HD-02c`), a real execution after the terminator (`HD-05`), a carrier ahead of a separator that does not vouch for the real receiver (`HD-11`), and a wrapper in front of a carrier (`HD-08c`) each return exit 2 with `BLOCK-DESTRUCTIVE-022`. Paired mutation arm `HD-09a`..`HD-09c` asserts the excision is live before anything the mutant reports is believed | 1327 arms, 0 failures, up from 1294; `block-destructive.test.sh` 453, up from 420. Transport asymmetry closed (both forms exit 0); every named control arm observed non-zero; `HD-09a` observed the mutation live and `HD-09b` observed the mutant refusing the payload the shipped hook allows. Arm `AC-FP-2x` green unmodified |

### Release-Level Verification

Per `verification-checklist.md`:
- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity (doc-link integrity via `deploy.sh --check` Check 14)
- [ ] Hook suite parity — every touched hook's suite run from the **materialized CI layout** emitted by `core/hooks/tests/setup-ci-layout.sh`. Running a suite from the source tree is an unsupported invocation whose failures are documented expected behaviour and must not be reported as regressions.
- [ ] Output Contract Compliance
- [ ] CIAC-1..5 verdicts (graded release-level at Stage 9 QC3.5)

---

## Rollback Strategy

### Per-Issue Rollback

One card per commit, no squashing within the -022 cluster, each commit naming its card and its region. The rollback unit is the commit. Because four cards share `core/hooks/block-destructive.sh`, a late per-card revert is a **range** revert rather than a single-commit revert — the wave order makes later-to-earlier the safe direction (R-7).

### Whole-Release Rollback

`git revert -m 1` of the merge commit. Every change is a file edit on a git-tracked hook; nothing is data-destructive and nothing crosses a host boundary. **MODERATE / HIGH.**

---

## Deviation Log

| # | Deviation | Basis |
|---|---|---|
| **DEV-1** | **AC baseline restated to 398 arms — measured, superseding BOTH prior figures.** The Stage-5 spec for #6172 anchored the CIAC-3 regression baseline to a source-pattern count of ~320; the Stage-6 dispatch brief corrected it to 327 "the runner total". Neither is the runner total. Running the suite from the materialized CI layout at `4f7e1ce3` reports **`Total: 398  PASS: 398  FAIL: 0`**. Both prior figures are helper-family call-site counts (the four named helpers total 323 here), and the suite increments its counters at **11** distinct sites. | A grep-anchored assertion stays green after arms are deleted — exactly the failure CIAC-3 exists to catch — and the same defect re-enters if a *different* grep is relabelled "the runner total". The figure is now the runner's own emitted line, reproducible by the invocation recorded in § AC baseline. Ratified at Commit 0. |
| **DEV-2** | **Baseline pin advanced `bd961c05` → `4f7e1ce3`.** The Stage-4 plan pinned its own measurement instant; `origin/main` advanced before the branch was cut. | Audit-baseline discipline: the branch baseline is the operand Stage 9 A6.5 re-checks. Both SHAs are recorded so the plan's probe figures stay reproducible against the state they were measured on. Verified no in-bundle surface moved between the two commits. |

---

## Evidence-of-record (Commit 0)

Probe records for every zero / N-of-M claim this file asserts on its own behalf, per `core/disciplines/review-discipline-principles.md` § 1 Rule 15 and § 8.

| Claim | PV-0 invocation | PV-1 denominator | PV-4 sensitivity (observed non-zero) | PV-5 specificity (observed zero) | PV-3 |
|---|---|---|---|---|---|
| The planned version is absent from every plan file | `python3` regex scan over `git show origin/main:<path>` for each plan | 191 plan files on `origin/main` | `4.47` → 2 files | planned version → 0 files | non-empty |
| The planned version is absent from the tag surface | `git tag --list 'v*' \| sort -V` | full `v*` tag set; highest is `v4.47` | `v4.47` present | planned version absent | non-empty |
| The release branch did not already exist | `git ls-remote --heads origin` on the release ref | 1 ref queried | `refs/heads/main` → 1 row | release ref → 0 rows | non-empty |
| The 7-card member set is current | `gh issue list --milestone … --state open`, `sub-task`-labelled members excluded | 33 open milestone members | 7 non-sub-task cards returned | — | non-empty |
| Suite baseline = 398 arms | `core/hooks/tests/setup-ci-layout.sh` then the materialized `test-runner.sh`; read the suite's own emitted `Total:` line | 21 suites, aggregate 1165 arms | `block-destructive.test.sh` → 398 | — (the run is the measurement, not an absence claim) | non-empty; 21 of 21 suites reported |
| Grep-family counts undercount the runner | `python3` call-site scan for the 4 named helpers over 2,696 lines | 11 counter-increment sites in the suite | 4 helpers → 323 call sites | `no_such_helper_zzz` → 0 | non-empty |
| #6172's two named paths are absent from the allowlist | `python3` substring scan of non-comment entries | 289 non-comment source entries | `setup-ci-layout` → 4 rows; `test-runner` → 8 rows | `check-convention` → 0; `test_check49…` → 0; control `no-such-zzz` → 0 | non-empty |

**Probe hazards actively avoided.** The local `grep` is `ugrep`, so every load-bearing detector above was written in `python3` with a control arm that must fire. The ledger was read via `git show origin/main:…` rather than the worktree copy, so a branch-side edit cannot influence the anchor. Next-free was computed as **anchor + 1**, never `max(claimed) + 1` — branch-side claims are non-binding.

---

## Change Description

*Scaffolded at Engineering Commit 0; authored in full at Stage 6 Phase C1 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, before the draft PR is transitioned to ready-for-review at the Stage 9 gate. Operator-facing voice.*

### Outcome

Every guard hook in the bypass-mode layer refuses exactly what its rule declares, and nothing wider. Four matchers across three hooks currently refuse work that is inside no rule's stated scope; this release removes each false-positive class without widening what any rule permits.

### Issues resolved

#5555 · #5653 · #6115 · #6166 · #6167 · #6172 · #6229. Each is marked as closed at Stage 13 per the close-out procedure; no close-family keyword is carried in this file or in the PR body outside the PR's dedicated Issue References block.

### Key decisions

- **D-Version** — recorded determination, rule-determined rather than an operator gate: bump-class `minor`, concrete number bound at the Stage-12 atomic claim.
- **D-C Branch Topology** — SINGLE.
- **D-Concurrency Posture** — P0 fully-serial.
- **D-ReleaseClass** — `cross-cutting`, re-derived on a materially rebuilt evidence base.
- **D-A/B/C/D (#6172, Stage 5)** — allowlist admission rather than the relative-invocation form; repository-relative rows only; bare `-n` for the shell trio only via a per-interpreter table; the `-c` exclusion enforced both structurally and by an explicit conjunct.

### Reversibility

**MODERATE / HIGH** for the release as a whole — one PR, one merge, rollback is `git revert -m 1` of the merge commit. The single asymmetry is R-7: four cards share one file, so a late per-card revert is a range revert.

### Downstream impact

Populated at Phase C1 when the full change-set has landed.

### Cross-references

Populated at Phase C1.
