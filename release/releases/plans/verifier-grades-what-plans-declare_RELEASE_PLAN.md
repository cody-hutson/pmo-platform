---
title: Release Plan — verifier-grades-what-plans-declare (the plan verifier and the AC binder grade what a plan declares, and say plainly what they did not grade)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.69; the concrete number binds at the Stage-12 atomic claim)
milestone: verifier-grades-what-plans-declare
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH — one branch and one merge, so reverting the merge restores the prior executor, binder, map and `SCHEMA_VERSION` byte-for-byte; the qualification is that the executor is a tool every release runs, so plans authored during the window regrade under the old vocabulary (no data loss), and two skill packages are rebuilt. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `verifier-grades-what-plans-declare`

**Milestone:** `verifier-grades-what-plans-declare` (ms#405, epic #6619) · Stage-4 sub-task **#7547** = the approved plan (`issuecomment-5816695727`), its approved delta for #7531 (`issuecomment-5817893990`), and the decision records D1–D16 and D37–D49 · Stage-5 sub-tasks **#7586** (#7531) · **#7590** (#6180) · **#7594** (#6893) · **#7598** (#6837) · **#7606** (#6848) · **#7610** (#6854) · **#7602** (#6685) · **#7614** (#6876) · **#7618** (#7494) · **#7622** (#6236), each carrying its design and its decision record (D17–D36) · Phase A6.5 reviews **#7639 · #7640 · #7643 · #7645 · #7648 · #7650 · #7663 · #7665 · #7669 · #7671** · ADR issues **#7641 · #7647 · #7672 · #7676** · Stage-6 sub-task **#7587** = the spoke that authored this file (Engineering Commit 0).

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.69`**. The Stage-4 provisional display was `v4.68`; another release claimed that slot, and the Collective Review re-minted the claim key to `4.69.0` (D43). The concrete number binds only at the Stage-12 atomic claim, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp placeholder. The Commit-0 re-verify ran in full, both halves — see § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch (`release/verifier-grades-what-plans-declare`), one PR, one merge, base `main`. This plan lands as **Engineering Commit 0**, and the PR is opened in draft right after it.

**Concurrency posture:** **P0 fully serial** (D-Concurrency, ratified at Gate 1): one Engineering spoke at a time, in the order of § Implementation Sequence. Force-push stays prohibited on the shared release branch.

**Release class:** `cross-cutting` (D4). Differentiation posture: engagement density **Tight** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**.

**Scope lock:** locked on D1–D48 by the Collective Review (D49), with one governed re-opening: #6893's Solutioning re-opened for the keyword-precedence limbs (D45), whose round-2 design (#7834) and gate D-6893b are in flight at this commit. A later scope change goes to the operator through a Decision Briefing with its impact.

> **Provenance.** This file transcribes the approved Stage-4 plan and its approved delta on #7547, together with every decision record on #7547 (D1–D16; the Collective Review, D37–D49) and the Stage-5 decision records D17–D36, applied as the Commit-0 edits those records and their designs specify. **Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority.** Line anchors (`:NNN`) are as of the Stage-4 pin `0c759aaf`; every later slice anchors by content. #6893's rows are transcribed as they stand; #6893's slice updates them when D-6893b renders.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination (D5, re-run as D15; protocol, spec and reference changes; no new skill or governance file). Provisional display `v4.69`, recomputed free at Engineering Commit 0 against fresh authoritative host state; it sets the floor and binds no concrete number. The number binds at the Stage-12 atomic claim (ADR-092). |
| **Date Created** | 2026-09-25 (Friday) — Engineering Commit 0 |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/verifier-grades-what-plans-declare` |
| **PR** | **#7839** — opened in **draft** by the first Stage-6 spoke right after Engineering Commit 0; it transitions to ready-for-review at the Stage-9 gate. |
| **Milestone** | `verifier-grades-what-plans-declare` (ms#405) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-24, domain: software }`

**Domain classification (A3).** Form **X** (sourcing-exempt): every File Change Matrix row is an internal platform artifact. The dominant deliverable is executable verification tooling plus its suite, so the class is **`software`**; `governance` is secondary (stage specs, QC3.5, the gate register). Transcribed unchanged from the Stage-4 plan; every Stage-5 design carried it forward unchanged.

### Date Variable

`${AUDIT_DATE_UTC}` = **`2026-09-25`**, resolved at Engineering Commit 0 via `date -u +%Y-%m-%d`. The dated identifiers this release creates are the `date:` fields of its four new ADR files; each slice that authors an ADR resolves the variable at its own first commit, per its design.

---

## Commit-0 Version Re-Verify Record

Run in full at Engineering Commit 0, both halves, per the Stage-6 first-spoke procedure (the hub-spoke bridge's single-branch canonical-location rule).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin` and `git fetch origin main` | exit 0 and exit 0; `origin/main` = `8e0ee08450a5e1d64f352279a3ab0f4a6ce46f6d`, the commit this branch is cut from |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 8e0ee08450a5e1d64f352279a3ab0f4a6ce46f6d --bump minor --dry-run` (the adapter's own `anchor()` + `claimed_set()`; no tag pushed) | **`v4.69`** — equal to the planned version |
| **3** | PROCEED only if the planned version is outside the claimed set and equals the recomputed next-free (the tag arm binds; published Releases and the ledger corroborate and never authorize) | **tag arm free; PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.69*' | wc -l
             gh release list --limit 5000 --json tagName  -> tagName startswith "v4.69"
             git show origin/main:release/releases/RELEASE_LOG.md | grep -c 'v4\.69'
Denominator: 213 v* origin tag refs (dereferenced lines excluded); 211 published Releases
             (read at --limit 5000); the RELEASE_LOG at origin/main
Control - sensitivity: the SAME readers on the neighbouring v4.68 slot: origin tags
             'refs/tags/v4.68*' -> the tag and its dereference; published releases starting
             "v4.68" -> ["v4.68"]; RELEASE_LOG 'v4\.68' -> 9 lines. All three arms non-zero,
             so each reader resolves and a zero on v4.69 is a real negative
Control - specificity: NOT TRIGGERED - slot occupancy over an exact tuple has no near-miss
             class; v4.68 is a different tuple, not a near-miss of v4.69
Extraction:  full ls-remote output; the full 211-row release list; the full RELEASE_LOG
Result:      0 occupants of the (4,69) slot on every arm
Verdict:     CLEAN - v4.69 is free on the binding tag arm; no HALT
```

**In-flight sibling observed at Commit 0 (not a HALT).** Open draft PR #7638 (`release/egress-hook-batch`, ms#392) carries the same provisional display `v4.69` at bump-class `minor`. A provisional display is not a claim: the claim is the tag pushed at merge. This is the Tier-S version-slot edge the milestone's Parallelization Map records (D43); the Stage-12 atomic claim serializes the two releases (merge order equals tag order), and Stage-9 Phase A6.6 renders the contention verdict.

**ADR-number sequence at Commit 0 (measured, not typed).** `release/tools/renumber-adr.py --detect` → `ANCHOR 204` (`origin/main`) · `NEXT-FREE 205` · `CLAIMED-SET-BRANCH-ONLY 205,206` (ms#392's draft PR; detection only, never binding) · this tree adds no ADR yet. This release adds four records under `release/ADRs/`. Each takes its number from the one global sequence (mainline anchor plus one, then contiguous within this branch) when its slice authors the file, and whichever of this release and ms#392 merges second renumbers at merge through the governed tool. No ADR number is typed into this plan: the matrix names each record as `ADR-NNN-<slug>`, and prose cites the ADR issue.

### Manifest half (step 3b, post-write / pre-commit)

`release/tools/claim-version.sh --verify-stamp verifier-grades-what-plans-declare` — run after this file was written and before it was committed. Required exit **0**. Result recorded in § Verification Evidence.

This plan carries **exactly one** double-brace `RELEASE_VERSION` placeholder — the Header `**Version**` cell — and every other mention names the placeholder rather than reproducing it. The claim tool resolves the token by global substitution across the whole file, so a literal prose citation would be rewritten at Stage 12 along with the record site.

### Commit-0 Survival Set

Every element the Stage-4 gate determined that a named downstream consumer reads **from this file**. A transcription that drops one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, no Mode-B rationale required) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1`..`CIAC-6`) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (42 per-issue rows, with the Commit-0 re-binds) | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, named rather than reproduced) | § Header `**Version**` cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class Declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | § Baseline Pin |

---

## Scope

### Issues Included

| # | Issue | Title | Priority | Size / pts | Labels |
|---|---|---|---|---|---|
| 1 | #7531 | verify-release-plan.sh silently truncates its own verdict rows when a method cell's grep reads stdin | P2 - Material | S / 2 | `bug`, `cluster: pipeline-definitions` |
| 2 | #6180 | A plan-authored column feeds an unreachable classifier branch — assessed and declined twice, now unowned | P2 - High | S / 2 | `improvement`, `cluster: automation`, `project:platform-quality` |
| 3 | #6893 | The plan verifier discards the declared predicate class and routes rows by prose keywords | P2 - Material | S / 2 | `bug`, `project:platform-quality` |
| 4 | #6837 | Plan-verification executor parses Predicate class then leaves it unwired — prose method cells grade as errors | P3 - Annoyance | **M / 4** (D44) | `bug` |
| 5 | #6848 | verify-release-plan.sh is silent on awk/git AC methods, and silence is indistinguishable from a pass | P2 - Medium | M / 4 | `improvement`, `structure` |
| 6 | #6854 | Behavioural AC rows have no named SKIP, so they land as ERROR and swamp the roll-up | P2 - Material | S / 2 | `bug` |
| 7 | #6685 | verify-release-plan.sh — a documented-decision method on a per-issue row can only ERROR | P2 - Material | S / 2 | `bug` |
| 8 | #6876 | runtime-suite-selection-map's globs cannot reach release/tools/tests/, so the test suites it routes to are unselectable | P2 - High | M / 4 (D6) | `improvement`, `cluster: pipeline-definitions`, `project:pipeline` |
| 9 | #7494 | Acceptance-criterion ordinals collide across three namespaces, and the oracle reader recognizes one heading form | P2 - Material | M / 4 | `bug`, `project:pipeline` |
| 10 | #6236 | A CIAC whose method falls outside the executor allowlist can be graded by no permitted party | P2 | M / 4 | `improvement`, `project:platform-quality` |

- **Record member, neither graded nor counted:** #6894 (closed 2026-09-20 as already fixed; attached as a record).
- **Scheduled into this release, not a milestone member:** #7635 — the markdown presenter drops every record with an empty issue field. D27 folds its fix into #6854's slice (the `(plan)` header, graded by V6854-AC4), and D44 closes it with this release's PR.
- **Size (G3-15, D44):** `effective_pts: raw 30 × 1.3 = 39 — above band, reframe-and-keep with Override vs band 15-25`. **Override:** the members form one capability — the plan verifier and the AC binder grade what a plan declares and say plainly what they did not grade — sharing one surface and root-cause class C10. The operator kept every member at Gate 1 (D4), added #7531 by re-bundle (D8/D9), restated the disposition at the delta gate (D14), and re-sized #6837 S → M at the Collective Review (D44).
- **Composition lock:** locked at Stage-4 Planning entry on 2026-09-24; cleared and re-locked by the #7531 re-bundle (D9); scope locked at the Collective Review (D49).

### Release Outcome Statement (D13-amended)

> **AFTER** — The plan verifier grades what a plan declares and says plainly what it did not grade: a declared predicate class either routes its row or is no longer offered as if it could; a row this executor is not the runner for resolves to a named SKIP, a method it cannot run here is reported apart from a pass, and ERROR is kept for input it could not read; a method cell can no longer read the record stream the executor is iterating, so no row after it drops out of the verdict stream and the cell itself is not graded on input it never had; a multi-limb method is graded in full or names the limbs it skipped; the runtime-suite map selects a runner that exercises the suites it names; a CIAC is authored gradable at Stage 4 and QC3.5 states what a SKIP means; and an acceptance verdict crossing a stage boundary names the criterion namespace it indexes.
>
> **BEFORE** — 38 of 47 rows on a live plan grade ERROR as unreadable; a method cell with no file operand reads the executor's own record stream and silently removes every row after it — 45 rows across 7 plans at the pin; the one column plans author to say how a row should be graded is parsed and discarded; QC3.5 is unsatisfiable by construction for a release whose CIACs need a tool; the map reaches 0 of the 17 suites it exists to select; and "AC-6 MET" can name three different criteria.
>
> **Actor(s):** platform engineering session.
>
> **Success Indicator:** each member's suite arm is observed RED before its fix and GREEN after, and a self-hosting differential of the pre-release and merged verifier over the pinned plan corpus, read from the executor's record stream rather than its markdown presenter, attributes every changed row — including each row that newly appears — to a named member, with none unattributed.

### Exclusions

N/A — enumerated over {deferred cards, split cards, cards moved to another milestone}; none present in this release. Membership changed once, by addition (#7531, D8/D9); nothing was moved out.

---

## Dependency Graph

**Native edges** (the dependency API, re-read at Commit 0): #6180 **blocks** #6893, #6837, #6854 and #6685; #6854 and #6848 **block** #6685 (added by D31). Six edges; #7531 has none in either direction; no external blocker. Every edge points forward in the sequence below, so the Collective Review's finding holds: all six native blocked-by edges are satisfied by the sequence.

**Derived graph.** Each edge is tested as build-blocking (B) or coordination (c). Stage-4 edges, the delta's edges and the Stage-5 additions:

```
#6180 --B--> #6893 --B--> #6854   (declared-class fixture; roll-up after #6848)
  |            \--B--> #6685      (per-issue fixture on the wired path)
  |             \-B--> #6837 AC-1/2 (co-discharge)
  +--B--> #6837 AC-3 (remove branch only)      #6837 AC-4 : no edge to #6180
  +--B--> #7531 AC-3            (D-6180's branch defines what "agree" means)
#6848 --c--> #6854 AC-4   (roll-up counts the final vocabulary)
#6848 --c--> #6236 AC-2   (QC3.5 must disposition the can't-run token)
#6236 AC-4 --c--> #6848 AC-2   (constraint: no historical SKIP -> failure)
#6837 AC-4 --c--> #6236 AC-1   (one span-extraction primitive)
#7494 --c--> #6236   (Stage-8 verdict shape; can build in parallel)
#6876 --c--> #7494   (map rows cited in stage-07/08; line-disjoint)
#6893 --c--> #7531 AC-3            (co-discharge: arm V7531-AC3 lands in #6893's slice, graded once)
#7531 AC-1/2 --c--> #6893          (shared per-issue loop region; #7531 first)
#7531 AC-1/2 --c--> #6837 AC-4     (per-limb dispatch runs through the isolated path -> CIAC-6)
#7531 AC-1/2 --c--> #6848          (its native git child runs on the per-issue path)
#7531 --c--> Stage-7 differential  (row appearances and verdict flips attributed to #7531)
#6854 --B--> #6685   (D31: its arms need D26's residual and D28's operand refusal landed)
#6848 --B--> #6685   (D31: its arms need D22's identifier guard landed)
#6893 --c--> #6685   (D31, INT-7: G14 stays green on #6685's head)
```

Zero cycles: every edge points forward in the sequence. #7494 → #6236 is coordination, not a build dependency: #6236's SKIP semantics can be built without the namespace field.

---

## Implementation Sequence

Topology SINGLE, posture P0: one branch, one PR, commits in this order. Every remediation lands its **RED arm first**; where an arm grades behaviour that is already correct, it uses the armed-red-then-revert form with its prediction stated before the run. Each coherent slice is pushed as it lands.

| # | Card | Slice | Authorized |
|---|---|---|---|
| 0 | — | Commit 0: this plan file. The Header Version cell carries the stamp placeholder; the Commit-0 re-verify ran both halves | this commit |
| 1 | #7531 | Input isolation per D18 (d) over both record loops: each dispatch loop's body runs with fd 0 on the null device, and `eval_free_run` refuses stdin readers (status 4 → ERROR `stdin-reader:<verb>`), with D18's in-slice fixes and D19's completeness tripwire (DEGRADED marker, "read K of N", exit 1). Arms **V7531-AC1** and **V7531-AC2** in suite group G12, RED on the pre-fix executor (prediction for a 6-row / 3-CIAC fixture with the cell third and second: 3 of 6 rows and 2 of 3 CIACs emit). **Carries the one `SCHEMA_VERSION` 4 → 5 bump** (D40), with a 4 → 5 note in the version history. The `RUNNABLE_VERBS` line stays byte-identical | D49 |
| 1b | #6236 | **V6236-AC4** and its fixture only — the non-retroactivity arm — as its own commit (D44) | D49 |
| 2 | #6180 | D17 (A′): the class-hint path removed; one in-method declaration form; the stale internal line reference in the classifier doctrine reconciled; suite group G13 (V6180-AC5a/b/c); the D-6180 ADR file (#7641) | D49 |
| 3 | #6893 | D30 (A): the probe step ahead of every keyword arm and the narrow deferral fix, with G14 and the R-M2 split; the shared quote-aware command predicate (D38); arms V7531-AC3 and V6837-AC2; Decision 6 appended to #7641. Re-opened for D45 (round-2 design #7834, gate D-6893b), which may place the tool-command half in #6848's slice | after D-6893b |
| 4 | #6837 | D29 (B): the designated command graded on its own comparator, every other command named *not run*, never PASS while one exists; the shared primitive (`method_spans`, `comparator_phrases`, the `CMP_*_ALT` constants) and `VERDICT_PARTIAL_SLOT`; arm V7531-CIAC6 | after D-6893b |
| 5 | #6848 | D21–D24: UNRUNNABLE as a fifth, non-failing verdict (roll-up counter, stderr note); tools named only from invocation-shaped spans; the native scope family with its three guards; `emit_table` widened; INT-4 re-binds `VERDICT_PARTIAL_SLOT` to UNRUNNABLE. Writes the partition ADR (#7647) with D37's reconciled table. A later contributor to the bump (D40). AC-3's literal reads PASS at the pin, so it is proved armed-red-then-revert | after D-6893b |
| 6 | #6854 | D26–D28: the per-issue residual (SKIP `no-executable-command-in-method`), the roll-up over the true population with the `(plan)` header (the #7635 fix), the reader exit and operand rules; the stage-07 laundering-guard line (D46). A later contributor to the bump (D40) | after D-6893b |
| 7 | #6685 | D31–D32: two fixtures and one arm group, 0 executor lines; lands after #6854 and #6848, its two native build edges | after D-6893b |
| 8 | #6876 | D33–D34: map grammar and reference resolver, rows 6 and 7, the fallback as row 8 cited by role; the connector's offline `--self-test`; the exclusions line; the package rebuild; the install-tests comment; the ADR file (#7672). 8a (Changes 1–4) before 8b (Changes 5–7) | after D-6893b |
| 9 | #7494 | D35–D36: `Namespace` and `Maps-to` on the Stage-7 AC map, the class-keyed `ns:` declaration, the binder's `ns:` and MAP limb, the criterion-namespace section in stage-08 § 4; the P1/P2 amendment in a pmo-skill-editor Mode A session (its own commit) with the eval set and the package rebuild; the ADR file (#7676) | after D-6893b |
| 10 | #6236 | D25 (A′): the rest of its slice — the `--ciac-lint` authoring check (G4-06), the QC3.5 / A3.6 / G-PR10 reading; no standalone ADR (its decisions are Decision lines in #7647, D47). Last, because it consumes steps 5–9 | after D-6893b |

**Why #7531 goes first** (delta, re-affirmed by D40 and D44):
1. AC-1 and AC-2 do not depend on D-6180; AC-3 is designed and armed inside #6893's step.
2. Every later arm, fixture and C4 re-run then grades on an executor that cannot lose rows.
3. #6837's per-limb dispatch and #6848's in-loop git child are built on isolated loops rather than retrofitted.
4. The Stage-7 differential can attribute #7531's row appearances to one isolated commit.
5. It carries the release's one emitted-contract bump, so every later slice lands on schema 5 (D40).

**Why V6236-AC4 lands at step 1b** (D44): the arm bounds #6848's verdict change (no historical SKIP may become a failure) and needs nothing from steps 2–9, so it lands before the slice it constrains.

**Evidence grounding (D42).** Each Stage-6 slice adds Evidence-Grounding rows, to the artifacts it commits, for the canonicalizations its own decisions introduced.

Then Stage 7 runs the **self-hosting differential**: the pre-release versus the head executor over the pinned plan corpus (stub root, so it is hermetic), with every changed row attributed to a card (§ Verification Plan → Release-Level Verification).

---

## Stage Applicability Matrix

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Stage 5 | Rationale |
|---|---|---|---|---|---|---|---|---|
| #7531 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | APPLY, W1 | T3: the planted cell's verdict is an emitted-contract choice inside the one partition. T4: AC-1 names two mechanisms with different reach. T6: the corpus effect and the child route are not in the body |
| #6180 | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | APPLY | New ADR (T1); record contract (T3); wire/remove (T4); 49/1,056 blast radius not in body (T6) |
| #6893 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | APPLY | AC-1 is itself a two-option choice |
| #6837 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | APPLY | Multi-limb: full grading vs partial marking |
| #6854 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | APPLY | Roll-up is emitted contract; one name vs class routing (RCA) |
| #6685 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | APPLY | Route depends on D-6180 |
| #6848 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | APPLY | "No mechanism committed"; gate ruling owned by Solutioning |
| #6876 | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ | APPLY | `**` vs explicit pair; newly-matched set unmeasured |
| #7494 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | APPLY | Payload schema field; restated in 2 unlisted files |
| #6236 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | APPLY | Three remedy candidates enumerated |

**Release-level verdict: ACTIVATE.** §3.1 rider: each T3 design names the seam it extends — the ADR-075 family registry and output contract, the Stage-8 enum, the eval-writer heading vocabulary. §3.2 rider: reviewed→retained/changed for the enum, the classifier precedence, and the AC-map columns. Collective Review fired and locked scope (D37–D49).

| Stage | Applies | Basis |
|---|---|---|
| 5 | all 10, two waves (ran in five sub-waves) | W1 {#6180, #6848, #6876, #7494, #6236, #7531}; W2 {#6893, #6837, #6854, #6685} after D-6180 rendered. Collective Review rendered the outcome partition (D37) and the bump placement (D40) |
| 6 | all 10 | Write set non-empty; every card `unconstrained` except #7494, whose P1-VOCAB reference row is `sanctioned-session-required` (§ Agent-Editability Read) |
| 7 | all 10 | Functional change to the executor and the binder: a RED-first arm plus the stream-read differential |
| 8 | all 10 | 42 criteria. #6837 AC-1/AC-2 graded once on the co-discharging arms; #7531 AC-3 graded once on the arm in #6893's slice; #6876 AC-5 by the Stage-7 resolver run |
| 9 | yes | **Deep** (cross-cutting, D4) |
| 10/11 | COMPRESS | Git-native: the diff is the dry run. Sub-tasks are created, then closed with the Skip Closure Format |
| 12 | yes | Versioned: atomic claim, signed tag, GitHub Release; the slot is contested (Tier-S, § Contention Map) |
| 13 | yes | Versioned close-out set; outcome window 30-day |

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. The Stage-5 CONDITIONAL rows whose conditions resolved are promoted into the unconditional set in this commit (authoring rule 5); each promoted row's label names the condition token it carried. The rows whose conditions did not fire, or that the operator kept inert, stay CONDITIONAL at the end of the fence.

```
# ── Engineering Commit 0 ──
release/releases/plans/verifier-grades-what-plans-declare_RELEASE_PLAN.md  ADD
# ── Production ──
release/tools/verify-release-plan.sh  EDIT
release/tools/check-ac-binding.py  EDIT
# ── Verification ──
release/tools/tests/test_verify_release_plan.sh  EDIT
release/tools/tests/fixtures/verify-plan-*.md  ADD
# ── Pipeline specs and governance ──
release/references/pipeline/stage-04-planning.md  EDIT
release/references/pipeline/stage-07-dev-testing.md  EDIT
release/references/pipeline/stage-08-qa-testing.md  EDIT
release/references/pipeline/stage-09-plan-review.md  EDIT
release/governance/release-process.md  EDIT
release/references/standards/runtime-suite-selection-map.md  EDIT
core/standards/gate-efficacy-standard.md  EDIT
# ── #6854 — the laundering-guard line beside stage-07 Phase A (D46) ──
release/references/pipeline/stage-07-dev-testing.md  EDIT
# ── #7494 — stage-04 AC-Binding Limb 1, anchored by text after the #6180 and #6837 edits (D35, R5) ──
release/references/pipeline/stage-04-planning.md  EDIT
# ── ADR records — each number comes from the one global sequence when its slice authors the file ──
# #6180 — the D-6180 ADR, issue #7641 (D17; Decision 6 appended by the #6893 slice, D30); was token D6180-ADR
release/ADRs/ADR-NNN-a-rows-grading-route-is-declared-in-its-method-cell.md  ADD
# #6848 — the release partition ADR, issue #7647 (D21 to D24, D37, D47); was token VERDICT-ENUM-CHANGE
release/ADRs/ADR-NNN-a-method-the-verifier-cannot-run-is-reported-unrunnable.md  ADD
# #6876 — the selection-map grammar ADR, issue #7672 (D33)
release/ADRs/ADR-NNN-runtime-suite-selection-one-glob-grammar.md  ADD
# #7494 — the criterion-namespace ADR, issue #7676 (D35)
release/ADRs/ADR-NNN-acceptance-verdicts-name-their-criterion-namespace.md  ADD
# the projected release ADR index, regenerated by generate-adr-index.py because this release adds release/ADRs records (token ADR-ADDED, resolved true)
release/ADRs/README.md  EDIT
# ── Promoted at Commit 0 — each Stage-5 condition resolved ──
# fired GPR10-VERDICT-SET (D25): Gate 4 gains G4-06 and the G-PR10 body is refined
core/schemas/gate-criteria-spec.md  EDIT
# fired ACMAP-FIELD (D35): the Stage-7 AC map gains Namespace and Maps-to
core/schemas/stage-io-contracts.md  EDIT
# fired REPORT-COLUMN (D35): a class-keyed ns declaration, a field and not a column
operations/templates/qa-acceptance-report-template.md  EDIT
# fired MAP-RENUMBER (D33, D34): the fallback row is cited by role
release/references/pipeline/stage-06-engineering.md  EDIT
# fired CONNECTOR-SELFTEST (D33): the connector gains an offline self-test, under the skill-editor discipline
core/skills/finops-usage-extractor/scripts/provider-usage-connector.sh  EDIT
# fired SKILL-SCRIPT-SCOPE (D33) — the exclusions row only
core/deploy/allowlists/selftest-coverage-exclusions.txt  EDIT
# ── #6876 — rows approved at D33 as Tier-2 changes (its R2 package rebuild; its review FM-5 comment) ──
packages/finops-usage-extractor.skill  EDIT
packages/finops-usage-extractor.skill.sha256  EDIT
.github/workflows/install-tests.yml  EDIT
# ── #7494 — P1-VOCAB, fired by D36 (b-i); executed in one pmo-skill-editor Mode A session ──
core/skills/eval-writer/references/acceptance-assertion-type.md  EDIT  sanctioned-session: pmo-skill-editor Mode A
core/skills/eval-writer/evals/stage-gates/stage-08-qa-testing/evals.json  EDIT  sanctioned-session: pmo-skill-editor Mode A
packages/eval-writer.skill  EDIT  sanctioned-session: pmo-skill-editor Mode A
packages/eval-writer.skill.sha256  EDIT  sanctioned-session: pmo-skill-editor Mode A
# ── CONDITIONAL — not fired, or kept inert, at Stage 5 ──
# not fired (D17): the class-hint path is removed but the header word is kept, and every existing plan fixture grades byte-identically
release/tools/tests/fixtures/verify-plan-3175-canonical.md  EDIT  CONDITIONAL:D6180-REMOVE
release/tools/tests/fixtures/verify-plan-count-modes.md  EDIT  CONDITIONAL:D6180-REMOVE
release/tools/tests/fixtures/verify-plan-escaped-pipe.md  EDIT  CONDITIONAL:D6180-REMOVE
release/tools/tests/fixtures/verify-plan-escaped-pipe-control.md  EDIT  CONDITIONAL:D6180-REMOVE
# not fired (D25): the CIAC authoring check ships as the executor's own --ciac-lint mode, not a new script
core/config/allowlists/script-execution-allowlist.txt  EDIT  CONDITIONAL:NEW-CHECK-SCRIPT
# not fired (D25): the five-field CIAC schema is retained
release/references/how-to/hub-spoke-bridge.md  EDIT  CONDITIONAL:CIAC-FIELD-ADDED
release/references/specs/release-personas.md  EDIT  CONDITIONAL:CIAC-FIELD-ADDED
# kept inert (D33): the manifest row and the smoke-workflow trigger row
core/deploy/allowlists/selftest-coverage-manifest.txt  EDIT  CONDITIONAL:SKILL-SCRIPT-SCOPE
.github/workflows/release-tooling-smoke.yml  EDIT  CONDITIONAL:SKILL-SCRIPT-CI-TRIGGER
```

#### Read-only inputs

```
core/hooks/block-autonomy-ceiling.sh  READ
core/hooks/block-skill-direct-edit.sh  READ
release/ADRs/ADR-073-cross-issue-integration-check-stage9-extension.md  READ
release/ADRs/ADR-075-plan-verification-executor-shared-contract.md  READ
release/ADRs/ADR-115-adr-number-claim-binds-at-merge.md  READ
release/ADRs/ADR-119-selftest-coverage-is-discovered-with-a-committed-manifest-floor.md  READ
release/ADRs/ADR-168-a-verification-claim-is-a-named-schema-column.md  READ
release/ADRs/ADR-181-adr-citations-bind-at-the-claim-not-at-authorship.md  READ
.github/ISSUE_TEMPLATE/*.yml  READ
```

#### Release-wide explicit non-scope

- **`RUNNABLE_VERBS`** — the executor's allowlist line stays byte-identical (#6848 AC-3 asserts the literal; #7531's edit to `eval_free_run`'s case arms leaves it untouched). It is a security boundary: this release widens neither the allowlist nor the hub's authority to run a CIAC method.
- **`.github/workflows/release-tooling-smoke.yml`** — not edited: its trigger-block row stays inert (D33). Its "26 assertions, G1..G5" comment is stale (the suite runs 219) and is routed out, not fixed here.
- **`core/skills/**`** — not edited except the connector script (CONNECTOR-SELFTEST) and the eval-writer reference and eval set (P1-VOCAB). If eval-writer's `SKILL.md` `version:` is ruled material by the skill editor, it is bound after the Stage-12 claim with a second package rebuild (D36), outside this PR.

**New-executable companion obligation: evaluated, does not fire.** No row adds a tracked `*.sh` the platform invokes: the CIAC authoring check is a mode of the executor (`--ciac-lint`), so NEW-CHECK-SCRIPT stays unfired and no allowlist row is owed.

**Release ADR index (C4).** This release adds records under `release/ADRs/`, so the index is regenerated with `python3 release/tools/generate-adr-index.py --write` in the slice that adds each record and confirmed with `--verify` → `COUNT 0`; its row above is declared EDIT, never hand-edited.

**Downstream chore-PR artifacts** (separate PRs, not the release PR): the Stage-12 `RELEASE_LOG` row; the Stage-13 INDEX, DIGEST and release notes.

---

## Contention Map

**Within the release, by region of `verify-release-plan.sh`** — the Stage-4 rows, the delta's rows, and the regions the Stage-5 designs added (#7531 R5, #6837 R6, #6854 R10):

| Region | Cards | Source |
|---|---|---|
| `classify_family` | #6180, #6893, #6848 (+#6854/#6685 under remove) | Stage 4 |
| parse awk record | #6180, #6893, #6837 (remove) | Stage 4 |
| dispatch loop `:2476` | #6180, #6893 | Stage 4 |
| `extract_command` / `handle_per_issue` | #6837, #6848 | Stage 4 |
| `handle_integration` | #6848, #6236 | Stage 4 |
| `dispatch_check` | #6848, #6854 | Stage 4 |
| `emit_md` / `emit_json` roll-up | #6854, #6848 · #7531 (D19's DEGRADED clause) | Stage 4; #6854 R10 |
| header `SCHEMA_VERSION` | **#7531 carries the one 4 → 5 bump**; #6848 and #6854 record themselves as later contributors; #6180 owes none | Stage 4, restated by D40 |
| `usage` | #6180, #6893, #6848, #7531 (AC-3, co-discharged), #6837 | Stage 4; delta; #6837 R6 |
| `eval_free_run` `:911–934` | #7531 (isolation) · #6837 AC-4 · #6848 · #6854 (reader exit and operand rules) | delta; #6854 R10 |
| per-issue dispatch loop `:2466–2483` | #7531 · #6180, #6893 (call site `:2476` inside the body) | delta |
| CIAC dispatch loop `:2488–2503` | #7531 · #6848, #6236 | delta |
| children on the dispatch path `:1081`, `:1177` | #7531 · #6848 (a fixed `git` child) | delta |
| `RUNNABLE_VERBS` `:717` | NOT CHANGED (#6848 AC-3 asserts the literal) | delta |
| `count_from_output` | #7531, #6854, #6848 | #7531 R5; #6854 R10 |
| the version-metadata block | #7531, #6180, #6848, #6854 | #7531 R5; #6854 R10 |
| the FD-0 doctrine block | #7531 | #7531 R5 |
| `extract_command` / `extract_threshold` | #6837 (consumed by #6848 and #6236) | #6837 R6 |
| the hook after each DEFERRED arm | #6837 | #6837 R6 |
| the suite loader `:290–295` | #6837 | #6837 R6 |
| `usage()` VERDICTS and the `main()` note | #6848, #6854 | #6854 R10 |

The Stage-4 cells conditioned on D-6180 resolve under D17 (remove): #6854's residual changes the classifier's terminus (D26), and #6685 edits no executor line (D31). The #6893 overlap is region adjacency, not a shared line, and serial order resolves every overlap above: no scope split is needed.

**Other shared files:**
- The **test suite** takes arms from **8** cards (#7531, #6236, #6180, #6893, #6837, #6848, #6854, #6685).
- **`stage-04`:** #6180, #6837, #6236, **#7494** (D35, R5: Limb 1, anchored by text after #6180's and #6837's edits to the same bullet list); the Stage-4 "#6848 conditional" resolved as fired — #6848's design adds one paragraph, and #6854's design adds one after it.
- **`stage-07`:** #6876 (row citations by role), #7494 (the AC-map columns and the Phase-B sentence), #6854 (the laundering-guard line, D46). **`stage-08`:** #6876, #7494 (the criterion-namespace section after `:38`). #6876 lands first and #7494's edits are line-disjoint; #7494 does not introduce the literal CIAC-5 counts.
- **`stage-06`:** #6876 (MAP-RENUMBER fired).
- **The runtime map:** #6876 AC-1–AC-5. **The self-test exclusions:** #6876 (D33).

**Cross-PR (Stage 4):**
```
Probe:       gh pr list --state open --limit 500 --json number --jq length
Denominator: whole open-PR population (limit >> count; non-truncating)
Control:     same reader, --state merged --limit 3 -> 3
Result:      0 open PRs at 2026-09-24T14:37:26Z; re-measured at the delta, 0 at 2026-09-24T15:58:25Z
Verdict:     CLEAN as a probe, VACUOUS for contention at N=0 - a pinned baseline; the hub re-checks per wave
```

**Cross-PR at Commit 0 (an observation; Stage-9 A6.5/A6.6 render the verdicts).** One open PR: draft #7638 (`release/egress-hook-batch`, ms#392). Its 12 changed files share **0** paths with this matrix (its ADR records, the core ADR index, the egress hook and its tests, the egress allowlist, the rules registry, `docs/UPDATE.md`, its own plan). It shares two slots: the version slot (both carry provisional `v4.69`) and the ADR-number slot (it holds 205 and 206). Between the Stage-4 pin and the branch point, `main` advanced by 18 commits touching 20 files (the ms#386 `v4.68` release and its close-out). **None of them is an add or edit target in this matrix.** One is a read-only input — `core/hooks/block-autonomy-ceiling.sh`, which gained the ms#386 membership helper — and it was re-read at the branch point for § Agent-Editability Read.

**Same-file siblings outside the milestone** (the delta's table, reconfirmed at the Collective Review, D43):

| Card | Milestone | Shared file / region | Overlaps |
|---|---|---|---|
| #6257 | ms#395 (in Stage 4, #7682) | executor fcm-delivery range | no region overlap; semantic coupling — #6848's scope family reuses `fcm_resolve_diff` unmodified (D23), so #6257's change reaches it |
| #6224 | ms#416 | executor `emit_json` + suite | #6854's roll-up region |
| #4993 | ms#338 (in Stage 4, #7684) | `runtime-suite-selection-map.md` | #6876's map rows; whichever merges first, the other rebases |
| #6114 | ms#406 | `check-selftest-coverage.py` Arm D | semantic: #6876's row 6 patterns are Arm D's `TEST_SUITE_GLOBS` verbatim, so a widening there is a visible decision on both |
| #6122 | ms#415 | `release-tooling-smoke.yml` trigger block | **moot** — D33 kept that row inert |
| #6844, #5503 | ms#365 | `release-tooling-smoke.yml` steps | **moot** under D33 |

Whichever release merges first, the other re-plans its matrix against the merged file.

**Tier-S (structural blast radius).** The mover-set is empty (no rename, relocate or delete). The **version slot** re-minted to `Δversion/4.69.0` after ms#386 claimed `v4.68` (D43); it intersects ms#392, and the Stage-12 atomic claim serializes the two releases. The **ADR-number slot** intersects ms#392's draft PR (205, 206); whichever merges first takes them, and the other renumbers.

**Parallelization Map.** The milestone description carries the map (recorded 2026-09-24, reconfirmed at the Collective Review by its own procedure, D43): no hard edges; file-contention edges soft (ms#395, ms#416, ms#338; ms#415 and ms#365 moot); semantic edges to ms#395 and ms#406; the version and ADR-number slots shared with ms#392; the ms#386 edge resolved.

---

## Agent-Editability Read

**Derivation** — controls read at the Stage-4 pin `0c759aaf` and re-read at the branch point `8e0ee084`:
- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — **2** `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`.
  - Block 1 arms: `"${PRIMARY_ROOT}/CLAUDE.md"` · `"${PRIMARY_ROOT}/projects/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/.claude/settings.json"` · `"${PRIMARY_ROOT}/.claude/hooks/"*` · `"${PRIMARY_ROOT}/.claude/rules/"*`
  - Block 2 (membership) arm: `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`
  - At the branch point the hook carries the ms#386 membership helper: block 2 now calls `always_block` twice (a helper-missing fail-closed call and the membership call), with its arm unchanged. The derived basename set is unchanged.
  - Tracked projections: `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md`, `release/governance/RELEASE_PROTOCOL.md`. The CLAUDE.md, `.claude/` and `projects/` projections track 0 files and are discarded, with the membership patterns unioned in.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` (0-line diff between the pin and the branch point).
  - `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`
  - arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$` — eval-writer's `SKILL.md` carries it (armed)
  - exemption list at `<deploy-root>/.claude/skill-editor-exemption-list.txt` — **present (1 entry)**, naming another skill

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| (Commit 0) | this plan | none | conjunct 1 false | unconstrained | unconstrained | ordinary Engineering spoke |
| #7531, #6180, #6893, #6837, #6848, #6854, #6685, #6236 | every row they write: the executor, the suite and its fixtures, the stage specs, `release-process.md`, `gate-criteria-spec.md`, `gate-efficacy-standard.md`, their ADR records and the ADR index | none (no basename match) | conjunct 1 false — no path under `*/skills/*/` | unconstrained | unconstrained | ordinary Engineering spoke |
| #6876 | the map, stage-06/07/08, `core/skills/finops-usage-extractor/scripts/provider-usage-connector.sh`, the exclusions list, `packages/finops-usage-extractor.skill` + `.sha256`, `.github/workflows/install-tests.yml`, its ADR record | none | conjunct 1 false for every row — the connector sits under `scripts/`, which the scope regex does not match | unconstrained | unconstrained | ordinary Engineering spoke; process note: the connector edit follows the skill-editor discipline (D12) though no hook gates it |
| #7494 | `core/skills/eval-writer/references/acceptance-assertion-type.md` | none | conjuncts 1 ∧ 2 true (armed), 3 true (not exempt) | **sanctioned-session-required** | **sanctioned-session-required** (most-constrained-wins) | `sanctioned-session: pmo-skill-editor Mode A` — open the session immediately before the gated writes and batch them in one window; never the bypass |
| #7494 | `core/skills/eval-writer/evals/stage-gates/stage-08-qa-testing/evals.json`, `packages/eval-writer.skill` + `.sha256` | none | conjunct 1 false (not `SKILL.md` or `references/*.md`) | unconstrained | (card row above) | written in the same Mode A session commit (D36) |
| #7494 | `release/tools/check-ac-binding.py`, stage-04/07/08, `core/schemas/stage-io-contracts.md`, `operations/templates/qa-acceptance-report-template.md`, `core/standards/gate-efficacy-standard.md`, its ADR record | none | conjunct 1 false | unconstrained | (card row above) | ordinary Engineering spoke |

**The #7494 rows supersede its Stage-4 card class.** At Stage 4 every card read `unconstrained`, with one contingent row pre-registered for a `core/skills/{pmo-qa-auditor,eval-writer}/references/*.md` write. D36 rendered (b-i), which fires that contingent row, so #7494's card class is now `sanctioned-session-required`. The all-`unconstrained` reading of the other nine cards is a discriminating negative: the derived Tier-0 set is non-empty and the scope regex matches real skill paths, yet no other write-set path intersects either set.

---

## Integration Points

- The executor feeds Stage-6 C4, the Stage-7 re-execution, and Stage-9 A3.6/A3.7 (G-PR10, G-PR11).
- The CIAC grammar feeds `parse_ciac`. The binder feeds the Stage-7/8 payloads and the register row at `:299`.
- The map feeds Stage-6/7/8 row citations; after #6876 every consumer cites the fallback by role (D34).
- Candidate INT-N named at Stage 4, each now specified in its Stage-5 design: each #6180→dependent edge on the classifier/dispatch contract; #6848↔#6236 on the can't-run token; #7494↔#6236 on the Stage-8 shape; #7531↔#6837 (limb dispatch), #7531↔#6848 (the child on the dispatch path), #7531↔#6893 (the shared loop; AC-3).
- Stage-5 amendments to the designs' criteria: #6893's INT-5 (vs #6854) reads "G14 green on #6854's head; D28's verb-scoped exit-0 rule lands in the same merge as the probe step", and INT-7 (vs #6685) is added — G14 green on #6685's head (D30, D31).

---

## Risk Register

| # | Risk | Evidence | Sev / Rev | Mitigation |
|---|---|---|---|---|
| R1 | **Reflexive self-grading.** Commit-0 C4 runs the pre-release executor; later C4 runs, Stage 7 and Stage 9 run the branch executor, and a vocabulary change flips this plan's rows. Restated at the delta: it also covers row completeness | The release edits its own grader; C4, Stage 7 and A3.6 all read the executor's output | HIGH / MODERATE | The authoring rules in § Verification Plan. At each rung, diff pre versus head verdicts on this plan and attribute every flip. Stage 9 reads head-SHA verdicts plus the differential. This plan has no stdin-reading cell, so #7531 cannot flip its own rows |
| R2 | **Every later release inherits a regression** — C4, Stage 7, G-PR10 and G-PR11 all run this tool | 215 plans graded by it | HIGH / MODERATE | Corpus differential with zero unattributed transitions; the masked-exit non-regression (D39); one bump (CIAC-4) |
| R3 | **Wiring steals executable rows** | 12 per-issue→runtime-suite moves at Stage 4; mixed cells hit the `behavioral` arm before `file-path`; doctrine `:406–427` | HIGH / CHEAP | Resolved by D17 (remove): the class hint is not wired. D30's probe step keeps a runnable probe ahead of every prose keyword |
| R4 | **Capacity** | raw 30 × 1.3 = 39 against the 15–25 band (D44); #6837 re-sized S → M | HIGH / CHEAP | Override recorded (D4, restated by D14 and D44); § Scope |
| R5 | **Partition divergence** — several Stage-5 spokes each designed part of one vocabulary | C10 is the shared root cause | HIGH / MODERATE | The Collective Review rendered one table (D37), carried by the partition ADR (#7647, D47); CIAC-3 and CIAC-4 |
| R6 | **Retired as an external risk.** #7531 joined under D8/D9. Restated as R6a–R6c | — | — | — |
| R6a | **Point fix (C18 class).** A redirect inside `eval_free_run` closes the verb route only; a child outside it still shares the loop's input | Delta P3: a stdin-reading child in the sync family dropped rows with the redirect in place | MEDIUM / CHEAP | Resolved by D18 (d): each loop's body runs with fd 0 on the null device, so every child inherits the null device; the rule is in-file doctrine |
| R6b | **Planted cell graded on nothing** | 2 of 9 corpus offenders were false PASS at the pin | MEDIUM / CHEAP | Resolved by D18: `eval_free_run` refuses a stdin reader before it runs (ERROR `stdin-reader:<verb>`); a first-limb stdin reader reads that ERROR (D37) |
| R6c | **Differential attribution** | Rows appear in 7 plans; the markdown presenter hides 186 records in 22 plans | MEDIUM / CHEAP | #7531 lands alone as step 1; the differential reads the record stream; #7635's `(plan)` header lands in #6854's slice |
| R7 | **Sibling same-file edits** | § Contention Map, siblings table (reconfirmed by D43) | MEDIUM / CHEAP | Per-wave re-check; Stage 9 A6.5 |
| R8 | **Pre-#6876 map misroutes this release's own A8** | The verifier is outside the discovered self-test set; tests/ changes match no row | MEDIUM / CHEAP | Explicit suite runs are mandatory at Stage 7; CI already runs the suite |
| R9 | **Contract-bearing ADRs** | Four new records: #7641 (the remove branch keeps ADR-168's `h_pred`), #7647 (a new verdict value amends ADR-075 decision 5), #7672, #7676 | MEDIUM / CHEAP | Promoted ADD rows named by slug; numbers from the one global sequence at authorship (`renumber-adr.py --detect`, both ADR dirs); citations bind at the claim (ADR-181) |
| R10 | **JSON output is invalid on 43 of 215 plans** (#6224) | Parsed every `--format=json` output | LOW / CHEAP | Build no JSON consumer in this release; the roll-up change asserts md output only |
| R11 | **Rollback** | Single merge | LOW / MODERATE | Revert; tag retained; no data loss |
| R12 | **Version-slot collision** — restated by D43 | ms#386 claimed `v4.68`; ms#392 (draft #7638) carries provisional `v4.69`, as does this release | LOW / CHEAP | Stage-12 compare-and-swap (merge order equals tag order); later claimant recomputes; Stage 9 A6.6 re-measures |
| R13 | **The binder cannot read #7531's criteria** | The binder read checkbox items only; #7531's criteria were an ordered list | LOW / CHEAP | Resolved: #7531's criteria were converted to checkbox form at the delta gate (D10) |
| R14 | **#6876 AC-5 widens into declared non-scope** | Four conditional rows at the delta | MEDIUM / CHEAP | Resolved by D33: the connector and exclusions rows fired; the manifest and workflow rows stay inert |
| R15 | **#6893's scope is re-opened while later slices wait** | D45 re-opened #6893's Solutioning; D-6893b may move the tool-command half into #6848's slice | MEDIUM / CHEAP | D49 authorizes steps 1, 1b and 2 only; every later step waits for D-6893b, and #6893's slice updates its rows here when it renders |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential, dependency-ordered (P0): Commit 0, then steps 1, 1b, 2–10 of § Implementation Sequence |
| **Commit strategy** | Commit 0 carries the plan. Each slice carries its RED arm before its fix. Commit messages carry the `verifier-grades-what-plans-declare:` prefix and name the source card |
| **Review approach** | Single PR for the whole milestone, one merge after Stage 9; no per-slice merges; never merge red CI |
| **Branch** | `release/verifier-grades-what-plans-declare` |
| **PR title** | `release(verifier-grades-what-plans-declare): the plan verifier and the AC binder grade what a plan declares` |
| **Deployment mechanism** | (1) Git merge. (2) Stage-12 atomic version claim. (3) Sync the primary to `origin/main`. (4) Skill deploy for the two skills below. (5) Verify by hash |
| **Stacked-base cleanup posture** | N/A — enumerated over {Option A base-shift, Option B defer to D0}; a single branch has no stacked bases |
| **PR body** | Parser-clean: close-family keywords adjacent to an issue number appear only in the Issue References block, which carries one closing line per open member, per ADR issue (#7641, #7647, #7672, #7676) and for #7635 (D44); #6894 is referenced only (a record) |

### Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/skills/finops-usage-extractor/` (the connector script with its new `--self-test`) | the installed `finops-usage-extractor` skill | S-2 direct copy via `deploy.sh --deploy` | `diff` shows no differences; `deploy.sh --check` Check 7 reads the rebuilt package fresh |
| 2 | `packages/finops-usage-extractor.skill` + `.sha256` | package artifact (repository) | rebuilt in #6876's slice from the final connector bytes (D33, R2) | the `skill-package-freshness` gate |
| 3 | `core/skills/eval-writer/` (the amended reference and eval set) | the installed `eval-writer` skill | S-2 direct copy via `deploy.sh --deploy` | `diff` shows no differences |
| 4 | `packages/eval-writer.skill` + `.sha256` | package artifact (repository) | rebuilt in #7494's Mode A session (D36) | the `skill-package-freshness` gate |

**`deliverable_state`:** the two skill deliverables reach `deployed-copy-synced` at Stage 12; every other deliverable is a repository-only change to tooling and specs — the "declares no propagation target" limb of the same state.

**Schema migrations:** N/A — enumerated over {tracker schemas, frontmatter schemas, `operator.toml` / `platform-config` keys, state-file schema}; none present. The executor's emitted contract moves from schema 4 to 5 (CIAC-4); that is a versioned output contract, not a stored-data migration.

---

## Verification Plan

**Authoring rules for this plan.** Its own executor grades it before and after it changes, so:
- every `grep` names an **explicit file operand** — a bare grep reads the dispatch loop's stdin and silently drops every later row (the #7531 class; 45 rows across 7 plans at the pin);
- use `grep -c -F` (literal, portable across BSD and GNU grep);
- exactly **one** comparator phrase per method cell;
- no `unchanged`, `deploy`, `integration`, `cross-issue`, `FAIL` or `deferred` tokens inside a method cell, except in the declared-deferred form;
- single-limb methods;
- reader-graded rows use the declared-deferred form, which SKIPs under both executor revisions.

Suite arms carry the label token `V<issue>-AC<n>`, absent at the pin in both the suite and the binder (control: suite `verify-release-plan` → 9; binder `AC` → 52). Their presence is executor-graded; their RED→GREEN run is Stage-7 evidence, and CI runs the suite on `release/tools/**`.

**AC baseline** — per-issue criterion counts as read at plan time and the commit read against; re-read at Commit 0 against the live bodies, and every count is unchanged:

`ac_baseline: { #6180: 5, #6893: 4, #6837: 4, #6854: 4, #6685: 4, #6848: 4, #6876: 5, #7494: 5, #6236: 4, #7531: 3, read_at: 0c759aaf992726c2cba5e43400ca6daa4056fdf3 }`

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7531 | AC-1 | `grep -c -F "V7531-AC1" release/tools/tests/test_verify_release_plan.sh` at least 1 | an operand-less stdin-reading verb (grep, head, wc, cat) planted in the per-issue and the CIAC record loops leaves every later row emitted |
| #7531 | AC-2 | `grep -c -F "V7531-AC2" release/tools/tests/test_verify_release_plan.sh` at least 1 | planted-fixture arm RED on the pre-fix executor (3 of 6 rows and 2 of 3 CIACs emitted), GREEN after; the planted row itself never PASS |
| #7531 | AC-3 | `grep -c -F "V7531-AC3" release/tools/tests/test_verify_release_plan.sh` at least 1 | co-discharged under D-6180 (arm authored in the #6893 slice): help text and dispatch agree on the rendered branch; graded once |
| #6180 | AC-1 | declared, verification deferred to Stage 8 named read of the D-6180 ADR | decision recorded; measured reclassification and bump condition both stated |
| #6180 | AC-2 | declared, verification deferred to Stage 8 named read of the D-6180 ADR (wire-branch criterion; N/A-WITH-RATIONALE under the rendered remove branch) | reclassification enumerated before/after; unclassified→family set separated |
| #6180 | AC-3 | declared, verification deferred to Stage 8 named read of the D-6180 ADR (wire-branch criterion; N/A-WITH-RATIONALE under the rendered remove branch) | per-row handler review of executing-handler moves incl. the 12 steals |
| #6180 | AC-4 | declared, verification deferred to Stage 8 named read (remove branch only) | the 11 column-authoring plans shown to lose nothing |
| #6180 | AC-5 | `grep -c -F "V6180-AC5" release/tools/tests/test_verify_release_plan.sh` at least 1 | paired mutation arm shows a behavioural difference |
| #6893 | AC-1 | `grep -c -F 'classify_family ""' release/tools/verify-release-plan.sh` expect 0 | 0, the empty-hint call gone · control: `grep -c -F 'classify_family' release/tools/verify-release-plan.sh` → 3 at pin · column cells: V6180-AC5a (G13) |
| #6893 | AC-2 | `grep -c -F "V6893-AC2" release/tools/tests/test_verify_release_plan.sh` at least 1 | REINTERPRET (D30): a runnable probe is graded by its probe whatever the prose; a declaration outside it still wins |
| #6893 | AC-3 | `grep -c -F "V6893-AC3" release/tools/tests/test_verify_release_plan.sh` at least 1 | rows with no runnable probe keep the keyword fallback (controls carry routing keywords) |
| #6893 | AC-4 | `grep -c -F "V6893-AC4" release/tools/tests/test_verify_release_plan.sh` at least 1 | reverting the probe step flips a failing probe back to the deploy oracle's PASS |
| #6837 | AC-1 | `grep -c -F "V6180-AC5b" release/tools/tests/test_verify_release_plan.sh` at least 1 | co-discharged: prose row with non-machine class not ERROR |
| #6837 | AC-2 | `grep -c -F "V6837-AC2" release/tools/tests/test_verify_release_plan.sh` at least 1 | co-discharged (arm authored in #6893's slice): genuinely unevaluable row still ERROR |
| #6837 | AC-3 | `grep -rc -F 'Predicate class' release/references release/skills release/governance core/standards core/schemas` expect 0 | 0 across the Stage-4 authoring surfaces once #6180's `:491` rewrite lands (1 at the pin) · control: `grep -rc -F 'Predicate class' release/tools/tests/fixtures` → 10 |
| #6837 | AC-4 | `grep -c -F "V6837-AC4" release/tools/tests/test_verify_release_plan.sh` at least 1 | false non-first limb not PASS; limbs named |
| #6848 | AC-1 | `grep -c -F "V6848-AC1" release/tools/tests/test_verify_release_plan.sh` at least 1 | scope assertion dispatches and executes; failing control FAILs |
| #6848 | AC-2 | `grep -c -F "V6848-AC2" release/tools/tests/test_verify_release_plan.sh` at least 1 | awk-based AC reported UNRUNNABLE, never PASS |
| #6848 | AC-3 | `grep -c -F "RUNNABLE_VERBS='grep test ls head wc cat'" release/tools/verify-release-plan.sh` expect 1 | RUNNABLE_VERBS unchanged (1 at pin) |
| #6848 | AC-4 | `grep -c -F "V6848-AC4" release/tools/tests/test_verify_release_plan.sh` at least 1 | clean exit on a scope-asserting plan |
| #6854 | AC-1 | `grep -c -F "V6854-AC1" release/tools/tests/test_verify_release_plan.sh` at least 1 | behavioural criterion resolves to a named SKIP |
| #6854 | AC-2 | `grep -c -F "V6854-AC2" release/tools/tests/test_verify_release_plan.sh` at least 1 | ERROR reserved for evaluate-and-could-not |
| #6854 | AC-3 | `grep -c -F "V6854-AC3" release/tools/tests/test_verify_release_plan.sh` at least 1 | broken method still ERROR |
| #6854 | AC-4 | `grep -c -F "V6854-AC4" release/tools/tests/test_verify_release_plan.sh` at least 1 | roll-up separates not-my-runner from failed-to-evaluate |
| #6685 | AC-1 | `grep -c -F "V6685-AC1" release/tools/tests/test_verify_release_plan.sh` at least 1 | declared → declared-deferred with its reason in the method; undeclared (fixture and v4.46's three cited rows) → per-issue no-command SKIP (co-discharged on D26) |
| #6685 | AC-2 | `grep -c -F "V6685-AC2" release/tools/tests/test_verify_release_plan.sh` at least 1 | fixture CIAC-1 and v4.46 CIAC-1 → integration documented-decision SKIP, unchanged |
| #6685 | AC-3 | `grep -c -F "V6685-AC3" release/tools/tests/test_verify_release_plan.sh` at least 1 | malformed method ERROR on the keyword and residual routes; padded `test -f` → ERROR `no-operand:test` (D28) |
| #6685 | AC-4 | `grep -c -F "V6685-AC4" release/tools/tests/test_verify_release_plan.sh` at least 1 | both fixtures present and parsed (3 + 3 rows) |
| #6876 | AC-1 | declared, verification deferred to Stage 7 resolver run over the 17 suites | every suite matched AND exercised; not fnmatch |
| #6876 | AC-2 | declared, verification deferred to Stage 7 resolver run with a match-nothing control | resolver named explicitly |
| #6876 | AC-3 | declared, verification deferred to Stage 8 named read of the PR | every path whose row changes under the grammar is named, including the two config templates (D33 FM-2) |
| #6876 | AC-4 | declared, verification deferred to Stage 8 named read of the map | nesting bound stated with reason |
| #6876 | AC-5 | declared, verification deferred to Stage 7 resolver run over the 8 core/skills scripts with a no-match control | all 8 matched by a map row whose selected runner executes each; a path outside every row still resolves to the no-match fallback; resolver named |
| #7494 | AC-1 | `grep -c -F "namespace" release/references/pipeline/stage-08-qa-testing.md` at least 1 | verdict payload names its namespace (0 at pin; stage-07 read at Stage 8) |
| #7494 | AC-2 | `grep -c -F "V7494-AC2" release/tools/check-ac-binding.py` at least 1 | divergent-namespace fixture mapping resolves every ordinal |
| #7494 | AC-3 | `grep -c -F "V7494-AC3" release/tools/check-ac-binding.py` at least 1 | namespace on every binding verdict line |
| #7494 | AC-4 | `grep -c -F "Completion condition" release/tools/check-ac-binding.py` at least 1 | heading forms bind, one fixture each (0 at pin) |
| #7494 | AC-5 | `grep -c -F "V7494-AC5" release/tools/check-ac-binding.py` at least 1 | negative heading still reports no criteria oracle |
| #6236 | AC-1 | `grep -c -F "V6236-AC1" release/tools/tests/test_verify_release_plan.sh` at least 1 | non-allowlisted CIAC flagged at Stage 4; allowlisted control clean |
| #6236 | AC-2 | declared, verification deferred to Stage 8 named read of QC3.5 and A3.6 | declined-by-design distinguished from failed; which blocks is stated |
| #6236 | AC-3 | declared, verification deferred to Stage 8 named read of stage-04 and stage-09 | documented-decision class disposition stated |
| #6236 | AC-4 | `grep -c -F "V6236-AC4" release/tools/tests/test_verify_release_plan.sh` at least 1 | historical SKIP verdicts not converted to failures |

**Commit-0 re-binds, and what each row's disposition is.**
- **#6180 AC-2 and AC-3** read N/A-WITH-RATIONALE under the rendered remove branch (D17) and SKIP under either executor revision; AC-1, AC-4 and AC-5 stand as planned (#6180 design Change 6). V6180-AC5 covers the landed labels V6180-AC5a/b/c.
- **#6893 AC-2** is REINTERPRET, graded on V6893-AC2 (D30 supersedes D17's N/A line for it).
- **#6837 AC-1** re-binds to V6180-AC5b (#6893 design Change 4). **#6837 AC-2 stays on V6837-AC2**, authored in #6893's G14 (D41). **#6837 AC-3** takes the runnable method and its control from #6837's design (R4, Change 5); it is RED until #6180's `:491` rewrite lands.
- **Co-discharges, graded once:** #6837 AC-1/AC-2 on #6180's and #6893's arms; #7531 AC-3 on the arm in #6893's slice; #6685 AC-1's undeclared limb on D26's residual, landed in #6854's slice.

**Stage-4 self-run, for the record** (the rows before the Commit-0 re-binds, live executor at the pin, hermetic): the merged 42 rows and 6 CIACs gave 42/42 indexed · **0 ERROR · 0 lost** · 10 declared-deferred SKIP · 31 FAIL (arms not yet written — RED by design) · 1 PASS (#6848 AC-3, the unchanged-set literal → armed-red-then-revert at Stage 6). The Commit-0 run on this file is in § Verification Evidence.

### Release-Level Verification (Stage 7; not executor rows)

- Run `bash release/tools/tests/test_verify_release_plan.sh` (baseline at the pin: **219 passed / 0 failed**) and `python3 release/tools/check-ac-binding.py --self-test` (33/0). Before #6876's fix, map row 4 does not run the verifier's suite, so these explicit runs are mandatory rather than map-selected.
- **The non-regression criterion is the masked exit (D39):** FAIL or ERROR over the per-issue and CIAC records, outside the `fcm-delivery`, `provenance-survival`, `regression` and `sync` families. No plan that is masked-clean before may become masked-failing unless the change is attributed to a named member. The raw process exit does not discriminate in the stub (every in-corpus plan exits 3 there, through `fcm-delivery`).
- **The Stage-7 harness stubs `core/deploy/deploy.sh` by prefixing an `exit 97` line to its original content,** so probes that read the file still see its real text, and it **pins the plan population by path list at the pin** (D39).
- **Read the stream, not the markdown.** The self-hosting differential compares the per-record stream (`--format=json` read line by line, or `--format=table`), never the markdown block, and attributes every changed row — including each row that newly appears — to a named member, with none unattributed.
- **The laundering guard (D46):** a row that graded FAIL or ERROR earlier and grades SKIP or UNRUNNABLE later is a finding, whatever slice moved it.
- **Predictions:** the delta stated #7531's corpus predictions at Stage 4; each Stage-5 design restates its own card's Stage-7 predictions at its rendered branch, and those supersede the Stage-4 figures.
- Run the corpus replay of the D-6180 enumeration; under D17 (remove) it asserts byte-identical records.
- **Cross-stage citations:** this release's own Stage-7 and Stage-8 spokes cite criteria as (namespace, issue, label) and use the new AC-map columns, as the introducing release's first worked example (D35, the design's R7).

---

## Cross-Issue Acceptance Criteria

Each entry is single-limb, names an explicit file and uses `-F`. Each was parsed and graded by the live executor — at the Stage-4 pin, and again at Commit 0 (hermetic, § Verification Evidence), where CIAC-5 carries its re-bound literal — and each reads NOT MET in the pre-fix state, so each discriminates. CIAC-4's and CIAC-5's conditions fired at Stage 5 (D21 and D40; D33), so both are carried with their literals bound. #6180's slice discharges CIAC-1 and CIAC-2 (its design's Sites 7 and 6); CIAC-4 is unaffected by it.

- [ ] **CIAC-1 (#6180 × #6893 on `release/tools/verify-release-plan.sh`):** the starved call site that hands the classifier an empty class argument is gone under either branch. *Method:* `grep -c -F 'classify_family ""' release/tools/verify-release-plan.sh` expect 0. *Graded at Stage 9 QC3.5 on the merged PR.* Control arm, same instrument and target: the classifier's name occurs 3 times in that file at the pin.
- [ ] **CIAC-2 (#6180 × #6893 × #6837 on `release/tools/verify-release-plan.sh`):** the in-source note describing the starved seam is retired, so the tool no longer describes a state it has left. *Method:* `grep -c -F "DELIBERATELY not emitted" release/tools/verify-release-plan.sh` expect 0. *Graded at Stage 9 QC3.5 on the merged PR.* Control arm: 1 at the pin.
- [ ] **CIAC-3 (#6848 × #6236 on `release/references/pipeline/stage-09-plan-review.md`):** the Stage-9 CIAC reading names and dispositions the new can't-run outcome that the executor emits. *Method:* `grep -c -F "UNRUNNABLE" release/references/pipeline/stage-09-plan-review.md` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#6848 × #6854 × #6893 on `release/tools/verify-release-plan.sh`, CONDITIONAL:EMITTED-CONTRACT-CHANGE):** every emitted-contract change in the release lands as one coordinated bump. *Method:* `grep -c -F 'readonly SCHEMA_VERSION="5"' release/tools/verify-release-plan.sh` expect 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#6876 × #7494 on `release/references/pipeline/stage-07-dev-testing.md`, CONDITIONAL:MAP-RENUMBER):** the A8 row-range sentence agrees with the renumbered map. *Method:* `grep -c -F "the last row is the explicit no-match fallback" release/references/pipeline/stage-07-dev-testing.md` expect 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-6 (#7531 × #6837 on `release/tools/verify-release-plan.sh`):** every limb that runs goes through the stdin-isolated dispatch, so an operand-less stdin-reading limb in any position truncates no later row. *Method:* `grep -c -F "V7531-CIAC6" release/tools/tests/test_verify_release_plan.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*

**The bump, restated (D40).** CIAC-4's one coordinated bump lands with #7531 at step 1: D19's DEGRADED clause is an emitted-contract change, by the precedent of the 3 → 4 bump for an additive roll-up change. #6848 and #6854 record themselves as later contributors, and #6180 owes none (D17). CIAC-4's head keeps the Stage-4 spanned set; its carrier is named here.

**Authoring trap, verified in the parser.** `parse_ciac` starts the Method clause at the **first** occurrence of "method" on the line, so a predicate containing that word displaces the clause. The predicates above avoid it. **Reading at QC3.5:** an UNRUNNABLE CIAC, a partially run one included, reads NOT MET (unverified) (D37).

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|---|---|---|
| #7531 | `git revert` of its commit; restored rows disappear again and schema 5 reverts to 4 | Low when isolated; Medium once later slices land on schema 5 |
| #6180, #6893, #6837, #6848, #6854, #6685, #6236 | `git revert` in reverse sequence order; each slice is one card's commits on the same file | Medium: shared regions of the executor (§ Contention Map) |
| #6876 | `git revert` of its two commits restores the map, the three specs, the connector and the prior package bytes | Low |
| #7494 | `git revert` of its commits, including the Mode A session commit (which restores the eval-writer reference and package) | Low |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|---|---|---|
| **Full Restore** | Systemic verdict regression after merge | Revert the merge commit (single PR). That restores the prior executor and `SCHEMA_VERSION`; plans authored during the window regrade under the old vocabulary, with no data loss. Re-deploy the two skills from the reverted tree |
| **Partial Revert** | An isolated card defect | Revert that card's commits only, in reverse sequence order |
| **Forward Fix** | A minor, well-understood defect | A fix branch per the rollback protocol |

**The claimed version tag is retained on rollback:** revert the merge and record the rollback; version tags are host-protected and are never deleted on the remote. **Reversibility: MODERATE / Confidence: HIGH.**

---

## Quota Budget

**Verdict:** **WARN** (Checkpoint A, recomputed at the delta). The usage-window basis is **UNSTATED**, so no figure is synthesized.
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 10 (W1 6 + W2 4) · Stage 7: 10 · Stage 8: 10
**Per-spoke cost estimate:** 5 × `size:S` → lowest band; 5 × `size:M` → low–moderate band (§ 5 ordinal heuristic; #6837 is M under D44).
**Assumed/stated remaining usage-window envelope:** UNSTATED, so the conservative default applies. The operator-held rule of thumb is roughly one-twentieth of a 5-hour window per spoke; if that holds, a 10-wide batch is near half a fresh window `[ASSUMPTION – CONFIRM]`.
**Estimated cumulative draw % (worst parallel batch):** not synthesized (UNSTATED basis).
**Routing:** window-aware timing plus split batches. Under UNSTATED, Checkpoint B renders `W_max 2`: Stages 7 and 8, N=10 → 5 sub-waves each; each sub-wave is re-gated. Stage 6 is serial (P0).
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton, and it also reads the host-API axis at runtime, combined DEFER-dominant. STAGGER defends against rate limits only. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Cross-PR Overlap Audit

- **Scope and baseline.** Audited at Stage 4 against `0c759aaf` (the approved plan and its delta) for open PRs and same-file siblings; re-observed at Commit 0 (§ Contention Map).
- **Open PRs at Stage 4: 0 repo-wide** (control on the same instrument: merged, limit 3 → 3). Append-pattern / overlap_class: N/A — enumerated over {`append-pattern`, `line-range-overlap`, `single-pr`}; with no open PR there were no hunk-range arrays to classify.
- **Structural blast radius:** the mover-set is ∅, so the Tier-S edges are the version slot and the ADR-number slot (§ Contention Map → Tier-S).

### Baseline SHA

`0c759aaf992726c2cba5e43400ca6daa4056fdf3` — `origin/main` pinned at Stage-4 Phase A0 (2026-09-24, Thursday) and re-read, unchanged, at the delta. The release branch is cut from `8e0ee08450a5e1d64f352279a3ab0f4a6ce46f6d`, the `origin/main` head at Commit 0; the 18 commits between the two touch no add or edit target in this matrix, and one read-only input (`core/hooks/block-autonomy-ceiling.sh`), re-read at the branch point.

### In-Flight Release Roster

**Measured at:** `0c759aaf` · `2026-09-24T15:58:25Z` · **Population:** n=0 sibling(s)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| none in flight at `0c759aaf` / 2026-09-24T15:58:25Z | — | — | — | — | — | — |

The roster is the Stage-4 pinned measurement and carries no verdict; Stage-9 Phase A6.6 re-measures the population fresh. At Commit 0 the population is no longer empty — draft #7638 (`egress-hook-batch`, head `e660b5db`, bump-class `minor`, carried `v4.69`, recomputed next-free `v4.69`, EDITSET ∩ FCM = ∅) — recorded as an observation, not re-rendered as a roster row, because the roster is Stage 4's baseline input to A6.6.

---

## Release Class Declaration

Class: cross-cutting

**Rationale:** Cross-cutting trigger (a) fires on the cards' own Affected Files — four `pipeline/stage-*.md` files (04, 07, 08, 09), and a fifth (06) since MAP-RENUMBER fired — and multi-trigger resolution selects the highest-ceremony class (D4, `[RECLASSIFY routine → cross-cutting]`). Cross-cutting (b) counts the rule-defining surfaces `release-process.md` and `gate-criteria-spec.md` (GPR10-VERDICT-SET fired). Novel (b) fires as well (the D-class decisions D17–D36), and routine fails on (a), (c) and (d).

**Differentiation posture:** engagement density Tight · Stage-9 review depth Deep · Stage-5 activation bias ALL · Stage-13 outcome window 30-day. **Size check:** raw 30 pts; effective 39 at the cross-cutting weight 1.3 — above the 15–25 band, reframe-and-keep with the recorded Override (§ Scope).

---

## Tier-A Activated Design Artifacts

Enumerated over the ten Stage-5 designs' Tier-A declarations; three fire.

| Card | Artifact | Flow class | Tier | G-CL6 obligation |
|---|---|---|---|---|
| #7494 | `release/references/pipeline/stage-08-qa-testing.md` § 4, the "Criterion namespace" section (embedded; inserted after `:38`, the end of § 4 — D35 FM-2) | data-flow | A (new) | Stage 13 verifies a non-trivial delta on the release branch |
| #6876 | `release/references/standards/runtime-suite-selection-map.md` (whole file; marker below the H1) | data-flow | A (new declaration; the tables are the artifact) | Stage 13 verifies a non-trivial delta on the release branch |
| #6236 | `release/governance/release-process.md` § QA Checkpoint 3.5, "Reading an emitted CIAC verdict" (embedded; marker `name=ciac-verdict-reading`) | data-flow | A (new) | refresh when the executor partition or the QC3.5 reading changes |

The other seven designs record no Tier-A activation (no new schema, explanation or discipline file).

---

## Decision Record

### Stage 3 → 4 boundary and Stage 4 (operator, 2026-09-24)

| ID | Decision | Verdict |
|---|---|---|
| **D1** | G3-14 disposition | (A) repair B6 + B7, recompute, then plan; the recompute read 9/9 clean |
| **D2** | Stage 4 plan | Approved as posted — D-C SINGLE, D-Concurrency P0, Stage 5 in two waves, Stages 6–13 per the applicability matrix, and the Tier-1 [ADJUST]s the plan lists |
| **D3** | Release Outcome Statement | Adopt the revised statement (amended by D13) |
| **D4** | D-ReleaseClass | `cross-cutting`, keep every member, with an `Override:` line |
| **D5** | D-Version (recorded determination) | `versioned` · bump minor · provisional display `v4.68`, binding only at the Stage-12 claim |
| **D6** | #6876 second gap (skill scripts no map row matches) | Absorbed as #6876 AC-5; #6876 re-sized S → M |
| **D7** | The Mode O entry-readiness gap story | Filing authorized |
| **D8** | Pull #7531 into this milestone | Chosen (diverged from the hub's recommendation) |
| **D9** | Re-bundle with #7531 (confirms D8) | Re-bundle: clear the lock, move #7531 in, re-run Stage 3 A1–A5 and a Stage-4 delta pass |
| **D10** | Delta plan | Approved: #7531 as step 1, Stage-5 W1 of six, CIAC-6, the four delta rows, the FCM delta, #7531's criteria in checkbox form |
| **D11** | #7531 size and priority | S (2 pts) · P2 - Material |
| **D12** | #6876 AC-5 write set | Admit the four CONDITIONAL rows; a fired row is promoted at Commit 0; a skill-script edit follows the skill-editor discipline |
| **D13** | Release Outcome Statement (amends D3) | Adopt the statement carrying the #7531 clause (§ Scope) |
| **D14** | Size disposition after the re-bundle (hub-recorded) | raw 28 × 1.3 = 36, reframe-and-keep, Override restated |
| **D15** | D-Version re-run (hub-recorded) | `versioned` · minor · provisional `v4.68`, unchanged at that time |
| **D16** | Procedure 1 scaffold review (hub-recorded) | 45 stage sub-tasks scaffolded; Step 6.5 read-back clean |

### Stage 5 — decisions rendered per card (operator, 2026-09-24)

| ID | Card | Verdict (the record lives on the card's Stage-5 sub-task) |
|---|---|---|
| **D17** | #6180 | (A′) remove the executor's use of the column; one in-method declaration form; the review's text fixes (#7590) |
| **D18** · **D19** | #7531 | (d) body redirect plus stdin-reader refusal, with in-slice fixes; the completeness tripwire shipped with the DEGRADED / exit-1 framing (#7586) |
| **D20** | review isolation | The remaining Phase A6.5 reviews ran without worktree isolation (#7590) |
| **D21**–**D24** | #6848 | UNRUNNABLE as a fifth, non-failing verdict; command-shape tool naming; the scope family with three guards; the residual `unrunnable` step (#7606) |
| **D25** | #6236 | (A′) the lint, the declared route and one reading table, plus the review's counter-designs and text fixes (#7622) |
| **D26**–**D28** | #6854 | (B) the per-issue residual with the DP-8 sign-off; (A)+(i) the roll-up with the #7635 fix; (A) the reader exit and operand guards (#7610) |
| **D29** | #6837 | (B) now; (A)'s later-limb execution deferred until OQ-2 (#7598) |
| **D30** | #6893 | (A) the probe step and the narrow deferral fix, with the review's fixes; AC-2 REINTERPRET (#7594) |
| **D31** · **D32** | #6685 | 1(A) co-discharge by sequence, after #6854; 2(A) the SKIP tokens reused by route (#7602) |
| **D33** · **D34** | #6876 | (A) with the review's fixes, R2 and R3 approved as Tier-2; (i) the fallback cited by role, new rows 6 and 7, fallback row 8 (#7614) |
| **D35** · **D36** | #7494 | (A) namespace fields and the MAP limb, with the review's fixes; (B1) + (b-i) + h3 with FM-3 (#7618) |

### Collective Review — scope-lock (operator, 2026-09-24)

| ID | Question | Verdict |
|---|---|---|
| **D37** | How Stage 9 reads a partially run row | As UNRUNNABLE — NOT MET (unverified) at QC3.5; #6236's conditional PARTIAL row dropped; the reconciliation pass takes the agreed rows, the wording fixes, #6876's R5 reading table and #7494's NOT-EVALUATED reason split |
| **D38** | What counts as a runnable command | One shared quote-aware predicate, landing with #6893 (step 3); the per-issue guard; one reader-semantics table; the lint reads a deferral as the executor does |
| **D39** | The Stage-7 non-regression measure | The masked exit; the deploy stub keeps the file's text; the plan population pinned by path list |
| **D40** | Where the one `SCHEMA_VERSION` 4 → 5 bump lands | At step 1 (#7531); #6848 and #6854 record themselves as later contributors |
| **D41** | Where #6837 AC-2 is graded | On V6837-AC2, in #6893's G14; AC-1 re-binds to V6180-AC5b |
| **D42** | Evidence-grounding coverage | Override; Stage 6 adds Evidence-Grounding rows for the decision-introduced canonicalizations |
| **D43** | The cross-release map | Reconfirmed by its own procedure (§ Contention Map) |
| **D44** | Scope and size | #6837 S → M; V6236-AC4 and its fixture at step 1b; override restated at 39; #7635 closes with this release's PR |
| **D45** | The keyword-precedence limbs D30 did not reach | Fixed in this release, with a carve-out keeping the declared `deploy.sh --check` route (diverged from the hub's recommendation) |
| **D46** | A durable laundering guard | Codified at stage-07 beside its Phase-A text; one stage-07 line in #6854's write set |
| **D47** | The ADR home | One partition ADR (#7647) carrying the reconciled table and the Decision lines of #6854, #6236, #6685 and #6837 |
| **D48** | Authoring forms and single items | Defaults: OQ-2 stays deferred; the 56 "= N" rows go to a follow-up; markdown-emphasis tolerance joins the comparator vocabulary |
| **D49** | Scope-lock | Adjust: locked on D1–D48; #6893 re-opened for D45 (round-2 design, review, gate D-6893b); Engineering authorized for steps 1, 1b and 2; every later step once D-6893b renders |

---

## Deviation Log

Rows DEV-1..DEV-10 carry one row per Phase A6.5 review: the routing of its Minor findings per the decision records that ingested them (the card's Stage-5 record and the Collective Review), cited by the review's comment. The findings themselves are not restated. Rows DEV-11 onward record each Commit-0 change to the approved Stage-4 plan with its authority.

| # | Surface | Change | Basis | Disposition |
|---|---|---|---|---|
| DEV-1 | #7639 — review of #7531's design (`issuecomment-5819933837`; aggregate Major, on PR-1 alone) | Minor findings PR-2, PR-3, FM-1, FM-2, FM-3, CD-1, CD-2 | D18, D19; Collective Review | FM-1, FM-3, CD-2 and PR-2 adopted in #7531's slice (D18); FM-2 adopted with the DEGRADED / exit-1 framing (D19); CD-1 presented and not chosen (D18); PR-3 (advisory) carried no disposition. The Major PR-1 settled by D37 |
| DEV-2 | #7640 — review of #6180's design (`issuecomment-5819808125`; aggregate Major) | Minor findings PR-3, FM-1, FM-2, FM-3 | D17; D30 | FM-1 (suite group G13) and FM-2 (the column example dropped from stage-04 `:491`) adopted (D17); FM-3's residual stated in #6180's slice, with its matcher fix landing in #6893's slice under the rule D30 adopted; PR-3 carried no disposition. The Majors (PR-1, PR-2, CD-1) adopted as D17 (A′) |
| DEV-3 | #7643 — review of #6848's design (`issuecomment-5821708802`; aggregate Major) | Minor findings PR-2, FM-2, CD-2 | D21–D24; D39; D44; D46 | PR-2 (the F2 remedy) settled by the masked exit (D39); FM-2 settled by the stage-07 laundering guard (D46, through #6854's R4); CD-2's minimum adopted (the ADR, `usage()` and the stage-04 paragraph state that the scope family grades the release diff) and per-issue scope kept at that minimum (D44). The Majors adopted (D22, D23; FM-3 re-derived against #7531's roll-up) |
| DEV-4 | #7645 — review of #6236's design (`issuecomment-5822051036`; aggregate Major) | Minor findings PR-1, PR-2, FM-5, FM-6, CD-3 | D25; D29; D37; D48 | PR-1, PR-2 and FM-6 adopted as D25's text fixes; FM-5 reconciled by D37; CD-3 not taken in this release — later-limb execution stays deferred with OQ-2 (D29, D48). The Majors answered by D25's CD-1 and CD-2 |
| DEV-5 | #7648 — review of #6854's design (`issuecomment-5823279183`; aggregate Major) | Minor findings PR-1, PR-3, PR-4, CD-1, CD-2 | D26; D30; D38; D40; D46 | PR-1 adopted (the Stage-6 branch line and the Stage-7 predictions re-issued on the rendered D22/D24 branch); PR-3 settled by D30 (the command-shape step lands in #6893's slice) and D38; PR-4 settled by D40; CD-1 settled by D38 (one reader-semantics table); CD-2 settled by D46 (the lint's per-issue extension not taken). The Majors settled by D46, D28 and D27 |
| DEV-6 | #7650 — review of #6837's design (`issuecomment-5823765261`; aggregate Major) | Minor findings FM-2, FM-3, FM-4, CD-2 | D29; D48 | FM-4 adopted (the INT-2 scope sentence, D29); FM-2 and FM-3 fall with (A)'s later-limb execution, which D29 defers; CD-2 adopted by D48 (markdown emphasis around N, no wider). The Majors answered by D29 (B) and its Change 4 sentence, and reconciled by D37 |
| DEV-7 | #7663 — review of #6893's design (`issuecomment-5824426195`; aggregate Minor) | All eight findings Minor: PR-1, PR-2, FM-1..FM-5, CD-1 | D30; D38 | FM-1, FM-2, FM-4 and FM-5 adopted (D30); PR-1 and PR-2 recorded with D30; FM-3 moot — it binds only if (C) or (D) renders, and D30 rendered (A); CD-1 settled by D38 (one shared quote-aware predicate) |
| DEV-8 | #7665 — review of #6685's design (`issuecomment-5824747669`; aggregate Minor) | All six findings Minor: PR-1, FM-1..FM-4, CD-1 | D31; D38 | PR-1, FM-2, FM-3 and FM-4 adopted (D31); FM-1 recorded (the fixture's authoring constraint and its partition row, D31); CD-1 settled by D38 (the per-issue guard) |
| DEV-9 | #7669 — review of #6876's design (`issuecomment-5825442975`; aggregate Major, on FM-1) | Minor findings PR-1, PR-2, FM-2, FM-3, FM-4, FM-5, CD-1 | D33; D34; D37 | PR-2, FM-2, FM-3 (R2 and R3 approved as Tier-2), FM-4 and FM-5 adopted (D33); PR-1 not taken (D33); CD-1 not taken (D34). The Major FM-1 adopted (D33); its mitigation 5 not taken (D37) |
| DEV-10 | #7671 — review of #7494's design (`issuecomment-5825647914`; aggregate Major, on FM-1) | Minor findings PR-1, PR-2, FM-2, FM-3, FM-4, CD-1, CD-2 | D35; D36 | PR-1, FM-2 and FM-4 adopted (D35); FM-3 adopted (D36); PR-2 resolved by D36 rendering (b-i) and h3 together; CD-1's full tier routed to a follow-up (D35 record); CD-2 carried no explicit disposition — D35 places the single definition in stage-08 § 4 (FM-2). The Major FM-1 adopted (D35) |
| DEV-11 | § Implementation Sequence | #7531 at step 1 carries the one `SCHEMA_VERSION` bump; V6236-AC4 and its fixture at step 1b; #6685 moves after #6854 (steps: #6848 5, #6854 6, #6685 7) | D40, D44, D31 | APPLIED |
| DEV-12 | The bump, wherever stated | The approved plan put the one bump in #6854's slice and said #7531 owes none; restated — the bump lands with #7531 (D19's DEGRADED clause is an emitted-contract change), and #6848 and #6854 record themselves as later contributors | D40 | APPLIED in § Implementation Sequence, § Contention Map and § Cross-Issue Acceptance Criteria |
| DEV-13 | Sizes | #6837 S → M (4 pts); totals 30 raw / 39 effective; the G3-15 override restated at 39 | D44 | APPLIED in § Scope and § Release Class Declaration |
| DEV-14 | § Verification Plan rows | #6180 AC-2 and AC-3 methods → the declared-deferred N/A-under-remove form (#6180 design Change 6); #6837 AC-1 → V6180-AC5b (#6893 design Change 4); #6837 AC-3 → the runnable method with its control (#6837 design R4, Change 5); #6893 AC-1..AC-4 Expected cells (#6893 design Change 4; AC-2 REINTERPRET, D30); #6685 AC-1..AC-4 Expected cells (#6685 design Change 4 as amended by D31); #6876 AC-3 Expected names every path whose row changes under the grammar (D33 FM-2). #6837 AC-2 stays on V6837-AC2 (D41) | the named designs and decisions | APPLIED |
| DEV-15 | § Cross-Issue Acceptance Criteria | CIAC-5's Method re-bound to the by-role literal (D33, #6876 R3); CIAC-6's predicate reads "every limb that runs goes through the stdin-isolated dispatch" (D29's Tier-1 [ADJUST]) | D33; D29 | APPLIED |
| DEV-16 | § File Change Matrix | Promoted: the D-6180 ADR row (#7641, slug from #6180 design Change 5), the partition ADR row (#7647, the release's single partition ADR, D47), GPR10-VERDICT-SET, ACMAP-FIELD, REPORT-COLUMN, MAP-RENUMBER, CONNECTOR-SELFTEST, SKILL-SCRIPT-SCOPE (the exclusions row only). Added: the ADR rows for #7672 and #7676; #6876's package rows and the `install-tests.yml` comment row (Tier-2, D33); #7494's P1-VOCAB rows with their sanctioned-session execution path (D36); #7494's stage-04 attribution (D35, R5); #6854's stage-07 row (D46). Not added: #6236's standalone ADR row (its decisions are Decision lines in #7647, D47). Marked not fired: the four D6180-REMOVE fixture rows (#6180 design Change 6) | the named designs and decisions | APPLIED |
| DEV-17 | `release/ADRs/README.md` row form | Written as an unconditional EDIT row. The source row spelled `CONDITIONAL:ADR-ADDED`; that condition resolved true at Commit 0, because four `release/ADRs/` ADD rows are unconditional here, and the matrix contract promotes a fired conditional in the same commit (Stage-4 FCM rule 5). The row is tool output: regenerated, never hand-edited | Stage-4 FCM authoring contract, rule 5 | APPLIED |
| DEV-18 | § Tier-A Activated Design Artifacts | New section: #7494's criterion-namespace artifact (D35 FM-2), plus the two other Tier-A artifacts the Stage-5 designs declared (#6876's map; #6236's CIAC-verdict reading) | D35; the #6876 and #6236 designs | APPLIED |
| DEV-19 | § Contention Map | The region rows from #7531's R5, #6837's R6 and #6854's R10; #7494 as a stage-04 writer (D35, R5); the `SCHEMA_VERSION` row restated (D40); the siblings table and Tier-S reconfirmed (D43) | the named designs and decisions | APPLIED |
| DEV-20 | § Operational Deployment Manifest | New section: `finops-usage-extractor` deploy and package (D33, R2) and `eval-writer` deploy and package (D36) | D33; D36 | APPLIED |
| DEV-21 | § Release-Level Verification | The masked-exit non-regression measure, the stub form of `deploy.sh`, and the plan population pinned by path list (D39); the laundering guard (D46); the Stage-4 predictions superseded by each design's own | D39; D46 | APPLIED |
| DEV-22 | § Implementation Sequence | Each Stage-6 slice adds Evidence-Grounding rows for the canonicalizations its decisions introduced | D42 | APPLIED as a standing obligation on steps 1–10 |
| DEV-23 | Provisional display version | `v4.68` → `v4.69`: ms#386 claimed `v4.68`, and the claim key was re-minted to `4.69.0`; re-verified free at Commit 0 | D43; the Commit-0 re-verify | APPLIED in § Header and § Commit-0 Version Re-Verify Record |
| DEV-24 | § Contention Map, § Cross-PR Overlap Audit, § Baseline Pin | Corrected right after Commit 0 by the spoke that authored it. Three sentences said the 18 commits between the Stage-4 pin and the branch point touched 0 paths in the matrix. A set-intersection probe of those 20 files against the 50 declared paths found one: `core/hooks/block-autonomy-ceiling.sh`, a **read-only input**, which the Agent-Editability derivation had already re-read at the branch point. No add or edit target changed | A Tier-1 [ADJUST] to this spoke's own Commit-0 transcription; a factual correction that changes no scope | APPLIED |

---

## Documentation Impact

Each row lands with its card's slice; the slice records the status and the commit.

| Issue | Declared docs | Status | Commit | Notes |
|---|---|---|---|---|
| #7531 | `--help` agrees with dispatch (co-discharged under D-6180) | lands with step 3 | — | Graded on V7531-AC3 |
| #6180 | stage-04 AC-Binding Limb 1 (`:491`); the D-6180 ADR (#7641) | lands with step 2 | — | Card declares no Documentation Impact section; the design's Changes 2 and 5 carry it |
| #6893 | the classifier doctrine and the `usage()` per-issue line; Decision 6 in #7641 | lands with step 3 | — | — |
| #6837 | stage-04 Limb 1 bullet (after the #6180 edit) | lands with step 4 | — | AC-3 grades the authoring surfaces |
| #6848 | stage-04 "What the plan verifier can execute" paragraph; `usage()`; the partition ADR (#7647) | lands with step 5 | — | — |
| #6854 | stage-04 "A method with nothing to run" paragraph; the stage-07 laundering-guard line; its Decision lines in #7647 | lands with step 6 | — | — |
| #6685 | none expected (card: parity with an existing disposition); its Decision line in #7647 | lands with step 7 | — | NONE unless the slice adds text |
| #6876 | the runtime-suite selection map; stage-06/07/08 citations by role; the ADR (#7672) | lands with step 8 | — | The map is itself the documentation surface |
| #7494 | stage-07/08 payload fields; the criterion-namespace section; the binder help; eval-writer P1/P2; the ADR (#7676) | lands with step 9 | — | Card declares no Documentation Impact section |
| #6236 | stage-04 CIAC authoring text; `release-process.md` QC3.5 reading table; stage-09 A3.6; G-PR10 / G4-06 in `gate-criteria-spec.md`; its Decision lines in #7647 | lands with step 10 | — | Card declares no Documentation Impact section |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification; extended by each slice, at Stage 7 and Stage 8, and at Stage 13.*

| Check | Result |
|---|---|
| **Commit-0 version half** | recorded in § Commit-0 Version Re-Verify Record: `v4.69` recomputed next-free and free on the binding tag arm; PROCEED |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp verifier-grades-what-plans-declare` → **exit 0**, *"verify-stamp OK — … carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s)); package-consequence checks not exercised"*; pre-flight line: the manifest stales 0 packages. Control on the same verb: a slug with no pre-claim plan → exit 1 (*"NO PRE-CLAIM PLAN"*). Exactly one double-brace `RELEASE_VERSION` placeholder in this file (the Header `**Version**` cell), counted at 1 by a fixed-string count of the braced form. Re-run after this row was written: exit 0 |
| **Hermetic self-verify (C4, Commit 0)** | Stub root = a `git archive` of the branch head `8e0ee084` plus this file, with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by an `exit 97` line (the original text kept after it); the executor invoked by its repo-relative path with `--root` on the stub. Roll-up: **`4 PASS / 36 FAIL / 12 SKIP / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`**, exit 3. Per-issue rows: 42/42 indexed, **0 ERROR**, 11 declared-deferred SKIP, 30 FAIL (arm labels absent — RED by design; #6837 AC-3 reads `count=1 (wanted == 0)`, its predicted pre-#6180 state), 1 PASS (#6848 AC-3, proved armed-red-then-revert at step 5). CIACs: 6/6 emitted, all FAIL (the pre-fix state). The one ERROR is `FCM-COVERAGE diff-unresolvable` — the stub is not a git tree, and the family never reads an absent diff as an empty one. Provenance: COVERAGE, PRESENCE and GRAMMAR PASS (`form=X date=2026-09-24`); DELTA PASS (`prov-no-loss`, 4 comment elements) on a second run supplied the Stage-4 plan comment. Controls on the same executor and stub, each a run-directory copy with one planted row: an empty method cell → the roll-up reads `2 ERROR — over 43 per-issue row(s)`; an operand-less grep placed first → 1 of 43 per-issue records emitted (the #7531 defect, live at the branch point). So the 0-ERROR and 0-lost readings on this file are real |
| **File Change Matrix parse** | The executor's determinism seam on a run-directory copy of this file outside the corpus, with an empty delivered set: `declared=50 interpreted=50 obligations=6 excluded=9 conditional=0 uninterpreted=0 pathless=0 prose_led=0`; the six obligations are this plan, the fixtures glob and the four ADR records. Control on the same copy: the D-6180 ADR row's label rewritten to carry the word for a conditional row → `obligations=5 conditional=1`, so the parser reads the labels and the promoted rows parse as unconditional |
| **AC binding** | `release/tools/check-ac-binding.py --ordinals-only` on this file → `VERDICT BOUND` (10 issues; each baseline equals `ac_baseline`); `--fetch` against the live issue bodies → **42/42 BOUND** |
| **Links and durability constructs** | `release/tools/check-release-links.py --roots release --files <this plan> --check-anchors --images` → 0 broken; `--plan-depth-lint` → 0 depth-sensitive links. Control: the checker's own `check_file` on a run-directory copy carrying one planted workspace-rooted link to a missing file → 1. Markdown-link sequences 0, cutover-idiom matches 0 (the reference-durability hook's pattern, fence-stripped), raw GitHub URLs 0; each reader returns 1 on a planted input |
| **ADR index** | This release adds records under `release/ADRs/`: the index is regenerated in each slice that adds one (§ File Change Matrix); no record exists yet at Commit 0 |

---

## Change Description

*Authored at Stage 6 per the RELEASE_PROTOCOL Change Description Protocol, and refreshed by each slice as it lands; the last Engineering slice completes it before the Stage-9 ready-for-review transition.*

### Outcome

**The plan verifier and the AC binder will grade what a plan declares, and say plainly what they did not grade.** At this commit no behaviour has changed: this commit is the plan. As the slices land, a method cell stops being able to read the executor's own record stream; a row the executor is not the runner for resolves to a named SKIP; a method it cannot run is reported UNRUNNABLE, apart from a pass; ERROR is kept for input it could not read; the runtime-suite map selects runners that reach the suites it names; a CIAC is linted gradable at Stage 4; and an acceptance verdict names the criterion list its ordinal counts in.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #7531 | A method cell can no longer drain the record stream; stdin readers are refused before they run; a shortened stream is reported DEGRADED | pending — step 1 |
| #6180 | The dormant class-hint path is removed; routes are declared in the method cell | pending — step 2 |
| #6893 | A runnable probe is graded by its probe, whatever the prose says | pending — step 3 |
| #6837 | A multi-command method is graded on its designated command and names the rest not run | pending — step 4 |
| #6848 | A method the executor cannot run is UNRUNNABLE, naming a real tool; scope assertions get a native family | pending — step 5 |
| #6854 | A command-less row is a named SKIP; the roll-up counts its true population | pending — step 6 |
| #6685 | A documented-decision method on a per-issue row reaches its named SKIP | pending — step 7 |
| #6876 | The selection map has one grammar and reaches the tool suites and skill scripts | pending — step 8 |
| #7494 | Verdicts name their criterion namespace; the binder reads both heading forms | pending — step 9 |
| #6236 | A CIAC is linted gradable-or-declared at Stage 4; QC3.5 reads every emitted outcome | pending — steps 1b and 10 |

### Key decisions

- **D17 / D30:** the grading route lives in the method cell alone; a runnable probe outranks prose.
- **D18 / D19 / D40:** stdin isolation by body redirect plus refusal, with a DEGRADED tripwire; the one schema bump lands with #7531.
- **D21–D24 / D37 / D47:** UNRUNNABLE as a fifth, non-failing verdict inside one reconciled outcome partition, recorded in one partition ADR.
- **D33 / D35–D36:** one glob grammar for the selection map; criterion namespaces named where they vary.

### Reversibility

**MODERATE — HIGH confidence.** Reverting the merge commit restores the prior executor, binder, map and schema version; plans regrade under the old vocabulary with no data loss, and the two skills are re-deployed from the reverted tree.

### Downstream impact

- Every later release's plan is graded by the changed executor at C4, Stage 7 and Stage 9 (schema 5).
- Stage-7/8 payloads gain namespace fields; Stage 9 reads UNRUNNABLE as NOT MET (unverified).
- Plan authors get a Stage-4 CIAC lint and one declared-deferred form.

### Cross-references

- Release plan: this file, top section
- Milestone: `verifier-grades-what-plans-declare`
- User-facing release notes: authored at Stage 13 Close per the release-notes standard

---

## Baseline Pin

`origin/main` @ **`0c759aaf`** (`0c759aaf992726c2cba5e43400ca6daa4056fdf3`), measured at Stage-4 Phase A0 and re-read unchanged at the delta. The release branch is cut at Engineering Commit 0 from `8e0ee08450a5e1d64f352279a3ab0f4a6ce46f6d`; the 18 commits between the two touch no add or edit target in the File Change Matrix, and one read-only input (`core/hooks/block-autonomy-ceiling.sh`), re-read at the branch point. Read by the Stage-9 mid-pipeline divergence re-check.

---

## Issue References

<!-- repo-integrity: allow-issue-ref — limb 1: a release plan's member and sub-task enumeration IS its subject matter; the numbers are the release's own scope and provenance, not prose citations -->

- **#7531 · #6180 · #6893 · #6837 · #6848 · #6854 · #6685 · #6876 · #7494 · #6236** — the ten open members; each closes with this release's PR.
- **#6894** — a record member: closed 2026-09-20 as already fixed; neither graded nor counted.
- **#7635** — the markdown presenter defect; its fix lands in #6854's slice and it closes with this release's PR (D44).
- **#7641 · #7647 · #7672 · #7676** — the ADR issues; each closes when its ADR file merges with this release.
- **#7547** — the Stage-4 planning sub-task: the plan of record, its delta, and the decision records D1–D16 and D37–D49.
- **#7586 · #7590 · #7594 · #7598 · #7602 · #7606 · #7610 · #7614 · #7618 · #7622** — the Stage-5 sub-tasks carrying the designs and decisions D17–D36.
- **#7639 · #7640 · #7643 · #7645 · #7648 · #7650 · #7663 · #7665 · #7669 · #7671** — the Phase A6.5 adversarial design reviews.
- **#7834** — #6893's round-2 Solutioning sub-task (D45), in flight at Commit 0.
- **#7587** — the Stage-6 Engineering sub-task that authored this file (Engineering Commit 0 and #7531's slice).
- **#7638** — the in-flight sibling release PR observed at Commit 0 (shared version and ADR-number slots).
