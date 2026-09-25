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
#6893 --c--> #6685   (D31, INT-7: G15 and #6848's round-2 group stay green on #6685's head)
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
| 2 | #6180 | D17 (A′): the class-hint path removed; one in-method declaration form; the stale internal line reference in the classifier doctrine reconciled; suite group G14 (V6180-AC5a/b/c); the D-6180 ADR file (#7641) | D49 |
| 3 | #6893 | D30 (A): the probe step ahead of every keyword arm and the narrow deferral fix, with suite group G15 and the R-M2 split; the shared quote-aware command predicate (D38), landed here as its first consumer; arms V7531-AC3 and V6837-AC2; Decision 6 appended to #7641. Re-opened for D45 (round-2 design #7834); D-6893b rendered D50, which places the four deploy-route limbs in #6848's slice at step 5, so this step is round 1 plus the shared predicate | D49, D50 |
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

### Step 1 (#7531) — as landed

Commits: `6360031a` (suite group G12 and its two fixtures, RED on the pre-fix executor) · `a3683b80` (the fix, with the `SCHEMA_VERSION` bump) · the plan update that carries this section. Scope: D18 option (d) with its in-slice fixes, D19's tripwire framing, D37's first-limb reading and D40's bump.

- **Mechanism.** Both dispatch loops in `main()` run their body with fd 0 on the null device. `eval_free_run` refuses a reader whose input is, or cannot be shown not to be, stdin (status 4), and `count_from_output` names the refusal: `stdin-reader:<verb>`, `device-operand:<input>` or `unmodelled-option:<opt>`. A first-limb stdin reader reads ERROR `stdin-reader:<verb>` (D37). Each loop counts the records it read; a short count emits a `stream-truncated` ERROR, the md roll-up carries the DEGRADED marker with "read K of N", the JSON roll-up reports `stream_state` `truncated`, and the run exits 1 (D19).
- **FM-1.** One shared renderer, `unreadable_observed`, used by both handlers, renders a refusal as a refusal with its remedy (`stdin-reader:grep (not run — …)`). A command that ran and failed keeps the matcher text byte-for-byte.
- **FM-3.** The FD-0 doctrine scopes every loop whose fd 0 is redirected, whatever the form, and names the six it exempts by measurement with the basis for each: `count_from_output`'s two loops, `extract_command`'s here-document loop, `fcm_match_adds`' file-fed loop, `handle_fcm_delivery`'s loop and `emit_md`'s loop.
- **CD-2.** `reads_stdin_cmd` is a closed, arity-aware model, and a helper, `stdin_input_refusal`, holds its one input rule: `-`, or any input under `/dev/` or `/proc/`, with repeated slashes collapsed first. Four resolutions the design text did not settle:
  - an unknown long option is refused in either spelling, `--name=value` or `--name value`, not only the separate one;
  - the separate form of grep's `--context` is refused as unmodelled, because GNU grep takes the next word and BSD grep 2.6.0 does not (measured); its attached form is modelled;
  - head, wc and cat model only the options every platform's copy shares, and no long option, because those three report a usage error as exit 1, which the count reader takes for a legitimate zero;
  - a `/dev/fd/N` operand is refused under CD-2, where the design's earlier unit table listed `cat /dev/fd/3` as must-pass.
- **PR-2: the reachability arm, not the declared residual.** G12-12 runs the executor's loop form on the bash that runs the suite and fails if an exec'd child sees any descriptor its baseline does not; G12-12b is its sensitivity pair, one inherited copy on fd 9, seen and read through (3 records). Chosen because it turns OQ-1 from an inference into a measurement on every CI run, at no cost to the runtime tripwire. Measured on bash 3.2.57, both locally and on the macOS CI job, which runs bash 3.2.57 rather than the newer bash the design inferred; both clean. No job runs the suite under bash 5, so bash 5 stays unmeasured: the arm measures whatever bash the suite runs on, and the tripwire reports a shortened stream at runtime.
- **PR-1.** G12-R grades v3.65.1 per criterion — AC-3, AC-5 and AC-9 each ERROR `stdin-reader:grep` — plus 11 of 11 rows emitted, never as a refusal count.
- **D40.** `SCHEMA_VERSION` 4 → 5 with its 4 → 5 note, which asks #6848 and #6854 to record themselves there as later contributors.
- **R2.** The child-route arm's sync row names its invocation in backticks — source-to-deployed via `deploy.sh --check` — and the arm asserts that the deploy child ran (G12-8) before it asserts 4 of 4 rows (G12-9).
- **The arms.** G12 carries 34 assertions; the design estimated about 35. Beyond the design's arms: a FM-1 control (G12-7), a `stream_state` arm (G12-10), the loop-form check (G12-11), the reachability pair, a status-4 unit (G12-15), and two more mutations — M4 renders the refusal as a matcher outcome, M5 removes the device rule. M1 and M3 assert exit 1, not the design's exit 3 (D19). The verb fixture carries CD-2's two refusal classes, a device path and an unmodelled option, so it has 15 rows rather than the design's 11.
- **`RUNNABLE_VERBS`.** Byte-identical: the line's sha256 is `8fcbe4d4` before and after the slice.
- **Rule for later slices.** Keep `do {` and `} </dev/null; done` on both loops, and each loop's read counter as the first statement of its body. G12's mutation arms anchor on the two loop closers, the refusal line in `eval_free_run`, the renderer's `stdin-reader` arm and the device rule, and the harness fails when a mutation stops taking — so a slice that rewrites one of those lines updates its arm in the same commit.

### Step 1 (#7531) — Evidence-Grounding (D42)

The canonicalizations D18 and D19 introduced, beyond the four the Stage-5 design grounded (`stdin-reader:<verb>`, status 4, the `stream-truncated` family, and the fixture names with G12). Every survey ran on 2026-09-25 at `e92543a9`, the branch head before this slice.

**E1 — the refusal reasons `device-operand:<input>` and `unmodelled-option:<opt>` (CD-2).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| executor emit sites | `<kebab-reason>:<subject>`, e.g. `tool-invocation-outside-executor-allowlist:$verb`, `placeholder-unresolvable:$path` | 16 sites, 14 tokens | `grep -oE '[a-z]+(-[a-z]+)+:\$[{]?[a-zA-Z_]+' release/tools/verify-release-plan.sh` |
| the Stage-5 design's canonicalization #1 | `stdin-reader:<verb>` | 1 | the #7586 design's Evidence-Grounding |

Survey denominator: 16 reason-token sites. Control: the survey returns `tool-invocation-outside-executor-allowlist:$verb` (2 sites). Canonical choice: `device-operand:<input>` and `unmodelled-option:<opt>`, each carrying its subject as written. Justification: documented rationale — D18 adopted CD-2 (the #7586 decision record); both follow the file's reason grammar and name the class, not one spelling of it. Out-of-scope drift: none.

**E2 — the refusal's rendered text (FM-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| executor observed strings with an explanation after the reason | `<reason> (<explanation>)` | 8 sites | `grep -oE '[a-z]+(-[a-z]+)+:\$[{]?[a-zA-Z_]+[}]? \([a-z]+ [a-z]+' release/tools/verify-release-plan.sh` |
| the not-run precedent | `tool-invocation-outside-executor-allowlist:$verb (not executed here; …)` | 2 | the same survey |
| the matcher wrapper | `count-unreadable:$cval (the matcher produced no readable result; …)` | 2 | the same survey |

Survey denominator: 8 sites. Control: the survey returns the matcher wrapper (2 sites). Canonical choice: `<reason> (not run — <remedy>)` for the three refusal classes; the matcher wrapper stays for a command that ran. Justification: documented rationale — D18 adopted FM-1 from the #7639 review; the form follows the file's own not-executed precedent. Out-of-scope drift: none.

**E3 — the measurement-state tokens (D19).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| tracked `.sh` and `.py` emitters, Register B | `DEGRADED` | 30 files | `grep -rlw -F DEGRADED --include='*.sh' --include='*.py' core release operations` |
| the same emitters, Register A literals | `"degraded"` 41 · `"not-run"` 35 · `"fixture"` 31 · `"fetched"` 28 · `"truncated"` 21 | 156 literals | `grep -rhoE '"(fetched\|truncated\|degraded\|not-run\|fixture)"' --include='*.sh' --include='*.py' core release` |

Survey denominator: the tracked `.sh` and `.py` files under `core/`, `release/` and `operations/`. Control: `"fetched"` returns 28. Canonical choice: the md roll-up carries `**DEGRADED:**`, the Register B token for "measured, but partial"; the JSON roll-up carries `stream_state` `fetched` or `truncated`, the Register A members for "examined in full" and "examined, but a sample" — not `degraded`, which Register A keeps for a read that failed and left the population unmeasured. Justification: documented rationale — PV-7a in § 8.1 of the review-discipline principles, adopted for this tripwire by D19. Out-of-scope drift: none.

**E4 — the exit code of a DEGRADED run (D19).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| this executor's exit constants | `EXIT_OK` 0 · `EXIT_INTERNAL` 1 · `EXIT_BAD_TARGET` 2 · `EXIT_CHECK_FAILED` 3 | 4 | `grep -c '^readonly EXIT_' release/tools/verify-release-plan.sh` returns 4 |
| the tree-wide measurement-state convention | an unmeasured result exits 3 — NOT-EVALUATED in one, "input failure / broken probe" in the other | 2 tools | the EXIT CODES headers of `release/tools/check-selftest-coverage.py` and `core/deploy/tools/check-pv7-vocabulary.sh` |

Survey denominator: 4 constants and 2 convention-bearing tools. Control: the constant count returns 4. Canonical choice: exit 1, `EXIT_INTERNAL`. Justification: documented rationale — D19 (the #7586 decision record): the verifier lost records, so this is not a verdict on the plan, and 3 is already this tool's plan-failure code. Out-of-scope drift: the tree-wide convention spends 3 on an unmeasured result, while this executor has spent 3 on "one or more checks FAIL or ERROR" since its first schema. A DEGRADED run is a partial measurement, not a withheld one, so exit 1 does not borrow the convention's meaning, but a reader comparing exit 3 across tools reads two different facts — accepted-residual, recorded here and not introduced by this slice.

**E5 — the closed option model (CD-2).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| reader commands the corpus dispatches, by the executor's own extraction | option and operand shapes | 454 commands in 217 plans | the census below |
| platform behaviour, BSD grep 2.6.0 on macOS | `--context 1 x f` takes no separate word; `cat -A` is illegal (exit 1); `wc -L` and `head -2` work | 4 probes | direct runs |

Survey: the executor's own `parse_verification_plan`, `classify_family`, `extract_command` and `parse_ciac`, eval-extracted as the suite does, over every plan under `release/releases/plans/`; each dispatched reader classified by `reads_stdin_cmd`; ground truth from running the same argv at a stub root with stdin on `/dev/null` and on a directory. Survey denominator: 454 reader commands (plus 10 `test`/`ls` and 1 untokenizable). Control: ground truth flags 16 stdin readers in 8 plans. Canonical choice: the per-verb tables in `reads_stdin_cmd`, with anything else refused as `unmodelled-option`. Justification: documented rationale — D18 adopted CD-2 from the #7639 review; the corpus cost is measured: 16 true positives, 0 false negatives, 0 false positives, 437 true negatives, and 0 `unmodelled-option` or `device-operand` refusals. The specificity population, 26 pattern-less greps, all run. Out-of-scope drift: the design's G-1 still holds for file operands — `wc`, `cat` and `head` exit 1 on an unreadable file, which the count reader takes for a legitimate zero. The closed model keeps those three to portable options, so no platform-divergent option reaches that path; the finding stays routed where the design routed it.

### Step 1b (#6236) — as landed

One commit, after #7531's slice (D44, authorized by D49): the `V6236-AC4` arm set, its fixture, and these notes. Scope: the #6236 design's Change 2c and its Change 3 rows `V6236-AC4`, `AC4 replay`, `AC4 M1` and `AC4 M2` (D25). The executor is unchanged.

- **The fixture.** `release/tools/tests/fixtures/verify-plan-historical-skips.md` carries Change 2c's text: the issue-reference override on line 1, the fixture comment, the H1 and a one-line blockquote naming the arm. It then has one per-issue row per historical SKIP shape: a refused tool, an identifier in the command position, no runnable command, and a declared deferral in both spellings (the phrase and the bracket). Its five CIACs are two refused tools, prose, a method on the entry's next line, and a declared deferral. It has no Predicate class column, so D-6180 does not touch it. The override line adds no record: the fixture yields 12 records with the line and 12 without it.
- **Suite group `G13`.** It is the id free at this step's parent commit `925cbd16`, where the suite uses G1 to G12 and never `G13`. It has a header entry, and every message carries `G13` and `V6236-AC4`. Its 13 assertions:
  - G13-0 checks, denominator first, that the fixture still declares its 5 per-issue rows and 5 CIACs.
  - G13-1 to G13-3 run the fixture on the shipped tool. They require 12 records (5 per-issue, 5 CIAC and the 2 always-on coverage records). None of AC-1 to AC-5 or CIAC-1 to CIAC-5 may be absent, FAIL or ERROR. The record set must hold 0 FAIL and 0 ERROR, and the run must exit 0.
  - G13-R, five times, checks v4.43's CIAC-1 to CIAC-5. Each must be present and neither FAIL nor ERROR, read per row and never by the exit code. That plan's stub-root run exits 3 through the delivery family alone.
  - G13-M1 adds SKIP to the exit predicate. It is proved to apply at exactly 1 site, then detected: the same 12 non-failing records exit 3.
  - G13-M2 disables the verb check. It is proved to apply at exactly 2 sites, one per handler, then detected: AC-1, AC-2, CIAC-1 and CIAC-2 read ERROR `count-unreadable:matcher-exit-3`, no other row moves, and the run exits 3.
- **Every arm grades "neither FAIL nor ERROR", never "= SKIP".** A later verdict that keeps a decline non-failing therefore keeps the arms green. The M1 and M2 pair proves that the arms observe the exit predicate and the verb check. INT-3 grades the fixture's exit 0 on #6848's commit.
- **Two helpers are group-local rather than shared (DEV-26).**
  - `g13_verdict` and `g13_observed` read a record from its own line. The shared `verdict_of` and `observed_of` isolate a record with `[^{}]*`, so a record whose text carries a brace reads as absent. v4.43's CIAC-3 method quotes a set in braces, and the first run of G13-R failed on exactly that row.
  - `m6236` is the suite's mutate-and-prove shape plus the exact-site count this step requires. Every group after G9-M carries its own copy of that shape, because the directory `mutate_proved` writes to is removed at the end of G9-M.
- **Left for step 10**, whose lint arms take the group id that is free at their own parent commit:
  - `AC4 M3`, which needs #6848's can't-run token (step 5);
  - Change 1a, with its doctrine comment and the FM-6 correction;
  - the `--ciac-lint` mode, the `lint_run` and `lint_of` helpers, the `V6236-AC1` group and its two fixtures;
  - every governance text.
- **Group ids for later slices.** The plan's step-2 row, DEV-2 and #6893 AC-1's Expected cell name `G13` for #6180's group. D41 and § Integration Points name `G14` for #6893's. Those ids were set before D44 placed this step ahead of step 2. Under the design's rule each slice takes the id free at its own parent commit, so #6180's group is `G14` on this commit. The rows that name the earlier ids belong to their own slices and are not edited here.
- **Rule for later slices.** G13-M1 anchors on the exit predicate's `$6=="FAIL"||$6=="ERROR"{found=1}` in `main()`. G13-M2 anchors on the two handlers' `if ! is_runnable_verb "$verb"; then`. Their site counts fail loudly when either text moves, so a slice that rewrites one of those lines updates G13-M in the same commit.

### Step 1b (#6236) — Evidence-Grounding (D42)

One canonicalization this step introduced, beyond the fixture name and the arm label that the #6236 design grounded (its canonicalization #5). The survey ran on 2026-09-25 at `925cbd16`, the branch head before this step.

**E1 — the suite group id `G13`.**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| group ids the suite uses | `G1` to `G12` | 12 ids; `G12` occurs 205 times | a token census of `release/tools/tests/test_verify_release_plan.sh` |
| `G13` in the suite | — | 0 | the same census |

Survey denominator: the suite's 2,289 lines. Control: `G12` returns 205. Canonical choice: `G13`. Justification: documented rationale — the #6236 design takes each slice's group id at its parent commit, never hard-coded (its canonicalization #5, after the #6180 review's FM-1). Out-of-scope drift: the plan's step-2 row, DEV-2 and #6893 AC-1's Expected cell name `G13` for #6180, and D41 and § Integration Points name `G14` for #6893 — routed to the hub. The group's helper names follow the suite's own precedent (`m<issue>`, `g<group>_*`, `MUTD<n>`), so they add no vocabulary.

### Step 2 (#6180) — as landed

Commits: `bb025b00` (suite group G14 and its two fixture twins, RED on the pre-removal executor) · `c4e7fdba` (the removal, the stage-04 bullet, the D-6180 ADR file and the regenerated release ADR index) · the plan update that carries this section. Scope: D17 (A′) with the #7640 review's fixes CD-1, PR-2, FM-1, FM-2 and FM-3, and D26's consequence for the ADR text. Behaviour-neutral: no emitted byte and no exit code changes (§ Verification Evidence).

- **The removal.** `classify_family` takes the method as its only argument; its hint arm is gone and its steps read 0, 1 and 2. The per-issue parser resolves no class value, and its in-source note is replaced by a comment stating that a predicate header cell is a schema word whose data cells are never read. The one call site no longer passes an empty class. The `--help` CHECK FAMILIES line names the method cell as the only input. A no-bump note sits above `SCHEMA_VERSION`, after step 1's 4 → 5 note: this slice is not a contributor to that bump. Kept byte-identical: ADR-168's latch line and the header role of `h_pred`, `parse_ciac`'s own Predicate field (4 `col_pred` lines), `RUNNABLE_VERBS` and `SCHEMA_VERSION`.
- **CD-1 — one declaration form.** The classifier comment names the declared-deferred form in its two spellings, `[DEFERRED — <reason>]` and "declared, verification deferred to <runner>", as the one way a row says this executor is not its runner, and documents `suite-skip` and `suite-fail` only as runtime-suite subtype tokens. Fixture AC-1 carries the bracket spelling and AC-2 the phrase spelling, so G14 pins both.
- **FM-3 — the step-0 residual, stated.** The classifier comment and the ADR's Consequences state that step 0 reads the whole cell, so a deferred phrase inside a backticked probe displaces that probe. The fix is #6893's slice (D30, recorded as Decision 6), with the shared quote-aware predicate (D38).
- **FM-2.** stage-04's Limb-1 bullet on extra columns no longer names the Predicate class column as its example; it states that an extra column is a reader annotation the verifier does not read to decide how a row is graded. #6837 AC-3's authoring surfaces now carry 0 occurrences of the column name (1 at the pin).
- **The stale internal line reference.** It is the `(:363-371)` citation in the fcm-delivery reconciliation note, which points at the `RUNNABLE_VERBS` closure; that range is now argument parsing. The Stage-4 plan named it ("reconcile the stale `:363-371` ref while in the file"). Before: "is closed on purpose (:363-371):". After: "is closed on purpose (see the RUNNABLE_VERBS doctrine above):" — the text #6893's design specifies for the same line (its Site H), so that slice finds the edit made and its gate, `(:363-371)` counting 0, holds. The line sits outside #6180's Contention Map regions (DEV-27). One further stale line reference, `_extract_section (:238)` in the fcm-delivery extraction note, is not this row's and is routed to the hub.
- **Suite group `G14` (FM-1).** It is the id free at this step's parent `51d1c0cb`, where the suite uses G1 to G13. It has a header entry and 12 assertions, each message carrying `G14` and its label:
  - G14-0 checks, denominator first, that both twins still declare their 4 rows.
  - G14-1 to G14-4 (V6180-AC5a): no surface of the executor claims a predicate-class hint; the per-issue parser resolves no class value; control — the CIAC parser keeps its own Predicate field; ADR-168's latch line is intact.
  - G14-5 to G14-9 (V6180-AC5b): every row is present and grades identically in both twins; AC-1 and AC-2 read deferred/SKIP; AC-3 is present and not PASS; AC-4 reads per-issue/PASS.
  - G14-M (V6180-AC5c): a class read re-introduced ahead of the keyword arms is proved to apply at exactly 1 site, then detected — AC-3 grades runtime-suite with the column and unclassified without it.
  - The shared `family_of` and `verdict_of` readers are used: no fixture record carries a brace, and G14-5 fails on an absent row, so no negated assertion can pass vacuously (DEV-28).
- **RED, then GREEN, each predicted before its run.** At the parent the suite gives 262 passed / 2 failed in a stub root. With G14 on the pre-removal executor: 272 / 4, the two new failures exactly G14-1 (4 lines claim the hint) and G14-2 (4 `col_pred` lines). With the removal: 274 / 2, +12 `ok` and 0 new failures. The 2 are P1 and M9's control, which need a repository. All 264 earlier outcome lines are unchanged in outcome and text on both runs.
- **The ADR file.** Decisions 1 to 5 of #7641, authored to the ADR authoring guide: AC-4 restated as REINTERPRET-WITH-RATIONALE with its breakdown, and the 28 method-silent declared rows listed by plan file and line in its source observations (PR-2); under D26 those rows grade by their method cell, so the text says so rather than "stay ERROR". Its number follows the ADR-number sequence rule: `release/tools/renumber-adr.py --detect` at authoring → `ANCHOR 206 · NEXT-FREE 207 · CLAIMED-SET-BRANCH-ONLY -` (ms#392's release merged its two records after Commit 0), and the file took the next free number. Every issue reference sits in its `## References` block. Decision 6 (#6893) and Decision 7 (#6848) append to the same file.
- **Rule for later slices.** G14-M anchors on the per-issue parser's data-row emit, `rec(issue, ac, "PENDING", method, expected)`: a slice that rewrites that line updates G14-M in the same commit. The G14 fixtures carry no backticked command except AC-4's probe, and AC-3's control family under the mutant is asserted present and different rather than pinned to `unclassified`, so D30's probe step and D26's residual keep G14 green.

### Step 2 (#6180) — Evidence-Grounding (D42)

The canonicalizations D17 introduced, beyond the two the Stage-5 design grounded (the method cell as the declaration seam, its canonicalization #1; the fixture and ADR names, its #2). Every survey ran on 2026-09-25 at `51d1c0cb`, the branch head before this step, or over the plan corpus of that date.

**E1 — the one declared-deferred form (CD-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the executor's deferred matchers | step 0 reads `[deferred`, `declared, verification deferred`, `verification deferred` and `deferred to #`; the per-issue and CIAC guards read `DEFERRED`, `declared, verification deferred` and `deferred to #` | 3 sites | `grep -n -E` over the executor for the `case` arms carrying the word |
| stage-04's statements of the form | the honesty note ("declared, verification deferred"); AC-Binding Limb 1's coverage bullet (`[DEFERRED — <reason>]`); the CIAC Verification method row ("declared, verification deferred to #<executor>") | 3 statements | `grep -n -i -E` for both spellings over stage-04 |
| per-issue rows the executor's own classifier sends to `deferred` | bracket 18 · "declared, verification deferred" 7 · "verification deferred" without "declared," 9 | 34 rows / 8 plans | the executor's parser and classifier, eval-extracted as the suite does, over the pinned corpus and the mainline corpus (identical) |
| rows the runtime-suite subtype arm claims | `suite-skip` / `suite-fail` | 0 rows | the same survey |

Survey denominator: 1,078 classifiable per-issue rows in the 217-plan mainline corpus (1,056 in the 215-plan pinned corpus), the executor's 3 matcher sites and stage-04's 3 statements. Control: the same survey over two suite fixtures returns 2 deferred rows, one per spelling, and 2 runtime-suite rows. Canonical choice: the declared-deferred form in its two spellings, `[DEFERRED — <reason>]` and "declared, verification deferred to <runner>", named in the classifier comment, the ADR's Decision 1 and fixture AC-1 and AC-2; `suite-skip` and `suite-fail` documented only as runtime-suite subtype tokens. Justification: documented rationale — D17 adopted CD-1 from the #7640 review; the subtype arm routes to FAIL on an uppercase FAIL anywhere in the method, and no corpus row used it. Out-of-scope drift: (1) step 0 also accepts a bare "verification deferred" (9 historical rows) and "deferred to #"; the canonical form names the two spellings authors are told to write, and narrowing the matcher would re-grade immutable rows, so it is left as is; (2) stage-04's CIAC Verification method row still documents `dispatch the runtime-suite for <domain>` as a method form — the #7640 review's routed item, on #6236's surface (step 10); (3) the step-0 matcher reads inside a backticked probe — FM-3, #6893's slice (D30).

**E2 — the suite group id `G14` (FM-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| group ids the suite uses at the parent | `G1` to `G13` | 13 ids; `G13` occurs 60 times | a token census of the suite at `51d1c0cb` |
| `G14` in the suite at the parent | — | 0 | the same census |

Survey denominator: the suite's 2,473 lines at `51d1c0cb`. Control: `G12` returns 205. Canonical choice: `G14`. Justification: documented rationale — the #7640 review's FM-1 as #7591 states it: the id free at the slice's parent commit, never hard-coded. Out-of-scope drift: the plan's `G14` for #6893's group (D41, § Integration Points' INT-5 and INT-7, the dependency graph's INT-7 note, and the Commit-0 re-binds bullet for #6837 AC-2) now names #6180's group; #6893's group takes the id free at its own parent — routed to the hub.

### Step 3 (#6893) — as landed

Commits: `22399359` (suite group G15 and the G10 R-M2 split, RED on the pre-fix executor) · `e14bb9ca` (the probe step, the shared quote-aware predicate, the span-kind deferral read, `usage()`, and Decision 6 in the D-6180 ADR) · the plan update that carries this section. Scope: D30 (A) with the #7663 review's FM-1, FM-2, FM-4 and FM-5, PR-1 and PR-2 recorded; Change 0 of the round-2 design, D38's shared predicate. D-6893b rendered D50: the round-2 deploy-route limbs land in #6848's slice at step 5, not here.

- **The probe step.** `classify_family` step 1: when `extract_command`'s pick is a closed backtick span with the shape of a probe this executor runs — an allowlisted verb, at least one argument, and no shell operator outside quotes — the row goes to the per-issue handler ahead of every keyword arm. `runnable_probe_of` returns that pick. `is_runnable_probe` is the shape test, and its comment names the run-time gates that decide faithfulness (the stdin-reader refusal and the exit-status reader) rather than promising it (FM-1). A tool command, a pipeline and a bare verb keep the keyword route. The steps now read 0 (declared deferral), 1 (runnable probe), 2 (keywords) and 3 (unclassified).
- **Change 0 — the shared predicate (D38).** `span_shell_operator` is the one quote-aware shell-syntax test. It scans the raw span outside quotes for `|`, `&`, `;`, `<` or `>`, treats `$(` or a backtick anywhere and an unterminated quote as syntax, prints what it found, and returns 1 when there is none. `is_runnable_probe` calls it in place of a private operator list. The name is the round-2 design's, so #6848's scope step and handler refusal and #6236's CIAC lint call it by that name.
- **FM-2 — the deferral read.** `method_outside_verb_spans` blanks every backtick span whose leading token is an allowlisted verb, over the spans `extract_command` reads (the even pieces of a split on backticks, an unclosed last one included). Step 0 and both handler guards read it, and the guards make no `runnable_probe_of` call. The design's `method_outside_probe` is renamed because FM-2 changed what it blanks — the span's kind, not the routing pick — and G15's M2 and M3 target the new name. The cell reaches `awk` through the environment, which `awk` does not escape-process, and `awk` reads no stdin.
- **FM-5 — the precedence.** A row naming both a runnable probe and the `deploy.sh --check` span is graded by the probe, and the deploy check does not run for it. The classifier's doctrine paragraph and step 1 state it, `usage()` reads "a declared deferral, then a runnable probe, else method keyword", and G15's AC-18 pins it. Naming the unrun deploy span is D29's, at step 4, whose slice extends the step-1 comment.
- **`usage()` and the in-file text.** The CHECK FAMILIES line reads "(dispatched from the Verification method cell alone: a declared deferral, then a runnable probe, else method keyword)", and the per-issue line names `${RUNNABLE_VERBS}`, wrapped to the help's column layout. The obsolete "THE RESIDUAL, DECLARED" paragraph is replaced by the precedence statement, the runtime-suite doctrine sentence now credits step 1, and a no-bump note sits above `SCHEMA_VERSION`.
- **The stale `(:363-371)` reference.** #6180's slice already applied Site H's text (its DEV-27). The gate `grep -c -F '(:363-371)'` reads 0, and the line reads "(see the RUNNABLE_VERBS doctrine above)".
- **The ADR.** Decision 6 is appended to the D-6180 ADR as #7641 states it, with its source observation (re-measured at this step), its alternatives line and its D30 provenance. Two resolutions:
  - its last bullet is written without round 2's qualification ("except the deploy check's, which Decision 7 closes to prose"), because D50 places that qualification with Decision 7 in #6848's slice (INT-11);
  - its reversibility is recorded as MODERATE, per the D30 record, where #7641's body reads "Decisions 1–6 CHEAP" (routed to the hub).

  The Consequences section is unedited: the ADR authoring guide forbids editing an Accepted record's consequences, and its residual paragraph already names Decision 6 as the fix. The release ADR index verifies COUNT 0, so no regeneration is owed.
- **Co-discharge (D50).** AC-2's limb "no prose keyword routes a row to the deploy oracle", AC-3's "the deploy check is reached only by declaration" and AC-4's prose-route revert are graded by #6848's round-2 arms on #6848's head. This slice's arms grade the probe-precedence limbs.
- **Suite group `G15`.** It is the id free at this step's parent `f25a6350`, where the suite uses G1 to G14. A header entry and 29 assertions, each message carrying its label:
  - G15-0: the denominator — all 18 stub-plan rows emit.
  - V6893-AC2 a–j: no prose displaces a runnable probe (a–e, and h–j: a quoted marker is literal, a phrase inside a quoted-marker probe is its pattern, a probe outranks the deploy-check span); a declaration outside the probe still wins (f); a bare verb and a pipeline are not probes (g), each asserted present.
  - V6893-AC3: rows with no runnable probe keep the keyword fallback, each control carrying a routing keyword.
  - V6837-AC2 a–c (D41): a declared prose row is a named SKIP; an unreadable probe input is ERROR; an empty method cell is ERROR, rc 3.
  - V7531-AC3: `--help` carries CHECK FAMILIES, claims no class hint, and names the method cell and a runnable probe; M4 restores the old wording, which must read 1.
  - V6893-AC4 M1–M3, and M5 under V6893-AC2: each seeded failure is proved to apply at exactly its sites (1, 1, 2 and 1), and an arm whose mutation did not take is not graded.
- **G10's R-M2 split.** R-M2a restores the prose keyword route alone and asserts AC-2 stays per-issue, because the probe step holds it. R-M2b also removes the probe step, and keeps the original detection.
- **RED, then GREEN, each predicted before its run.** In stub roots the parent gives 274 passed / 2 failed. With G15 on the pre-fix executor: 286 / 16 — the 13 G15 arms for new behaviour, R-M2a, and the 2 stub failures. With the fix: 305 / 2. All 274 earlier outcome lines are unchanged in outcome and text on both runs. CI: `22399359` **290 passed, 14 failed** (exactly the 14 predicted); `e14bb9ca` **309 passed, 0 failed**, ALL PASS.
- **Rule for later slices.** G15's mutations anchor on the probe-step line `if [ -n "$probe" ]; then echo "per-issue"; return; fi` (M1, and G10's R-M2b), step 0's `prose=` line (M2), the two guards' `case "$(method_outside_verb_spans "$method")" in` (M3), the CHECK FAMILIES parenthetical, which must carry no `)` (M4), and `span_shell_operator`'s quote arm ending `q="$ch" ;;` (M5). A slice that rewrites one of those lines updates G15 in the same commit. The design's AC numbering is kept, and AC-16 to AC-18 follow it, so round 2's restatements of AC-7, AC-8, AC-10 and M1 (D50, #6848's slice) apply to G15 as landed.

### Step 3 (#6893) — Evidence-Grounding (D42)

The canonicalizations D30 and D38 introduced, beyond the three the round-1 design grounded (what counts as a runnable probe, where the step sits, and the helper and label names). Every survey ran on 2026-09-25 over the release branch's 217 plans — the round-2 pin's 216 plus this plan — through the executor's own parser and helpers, eval-extracted as the suite does.

**E1 — the probe test is a shape test over the designated span, quote-aware (D30, FM-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the executor's command notions at the parent | `is_runnable_verb` (the verb alone) · `looks_like_command` (a command-shaped leading token) · `extract_command` (the designated span) · `eval_free_run` (tokens with no shell; refuses a token carrying `$(` or a backtick) | 4 functions | the executor at `f25a6350` |
| designated commands on indexed rows | verb-led with at least one argument | 376 of 1,110 | the survey |
| the same picks | a shell operator outside quotes | 6 (four pipelines, two angle-bracket placeholders) | the survey |
| the same picks | an operator character only inside quotes | 27 | the survey |
| round 1's token test vs the quote-aware scan | disagreements over the verb-led picks | 0 of 376 | the survey, reproducing the #7663 review's R10 |

Survey denominator: 1,110 indexed per-issue rows. Control: 369 rows carry a runnable probe, of which 31 are this plan's; the other 338 reproduce the round-2 design's P2 at its pin exactly. Canonical choice: `extract_command`'s pick, a closed backtick span, an allowlisted verb, at least one argument, and no shell syntax per `span_shell_operator`. Justification: documented rationale — D30 adopted the design's canonicalization with the #7663 review's FM-1, which states the test as a shape test and names the run-time gates. Out-of-scope drift: the 6 picks with an operator outside quotes keep their keyword route until the handlers' refusal lands (R9, #6848's slice, the D50 owner assignment); `extract_command`'s pick order is unchanged (#6837's re-expression, INT-4).

**E2 — one shared quote-aware shell-syntax predicate, `span_shell_operator` (D38).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| operator tests in the executor at the parent | `eval_free_run`'s per-token `$(` and backtick guard | 1 | the executor at `f25a6350` |
| operator lists the release's designs would each have carried | round 1's router: a de-quoted token list · #6848's scope step: any token containing a pipe, placeholders exempt · #6236's lint: standalone operators | 3 lists | the #7663 review's CD-1 |
| picks a quote-blind character scan would refuse | an operator character only inside quotes | 27 of 376 | the survey |

Survey denominator: the executor's operator tests plus the 376 verb-led picks. Control: a 46-case unit battery passes on the shipped helper and fails 8 cases on a quote-blind variant. Canonical choice: `span_shell_operator <span>`, the round-2 design's name and body (its Change 0): the raw span is scanned outside quotes for `|`, `&`, `;`, `<` and `>`; `$(` or a backtick anywhere, and an unterminated quote, count as syntax; it prints what it found and returns 0, else returns 1. Justification: documented rationale — D38 (one shared quote-aware predicate for the router, the handlers, the scope step and the CIAC lint, landing with its first consumer). Out-of-scope drift: the three consumers still to adopt it, each in its own slice by the D50 record's owner assignment.

**E3 — a deferral is read outside every span led by an allowlisted verb (FM-2).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| step 0 on the raw cell vs the blanked cell | per-issue rows reading deferred | 45 and 45 (0 change) | the survey |
| the handler guard, raw vs blanked, over cross-issue methods | methods reading deferred | 2 and 2, of 390 (0 change) | the survey |
| backticked declarations | spans led by `[DEFERRED`, which is not a verb, so kept | 6 historical rows | the #7663 review's R14 |

Survey denominator: 1,110 indexed per-issue rows and 390 cross-issue methods. Control: G15's M2 (step 0 on the raw cell) turns AC-4 and AC-17 deferred again, and M3 (raw guards) turns AC-4 into a declared-deferred SKIP. Canonical choice: every backtick span whose leading token is an allowlisted verb is blanked, by the span's kind rather than the routing pick, in `method_outside_verb_spans`. Justification: documented rationale — D30 adopted the #7663 review's FM-2, which is #7640 FM-3's rule. Out-of-scope drift: a table-form CIAC method reaches the handler with its backticks already stripped, so a phrase inside that bare command is still read as a declaration; 0 of the 390 cross-issue methods are affected, and it is routed to the hub.

**E4 — the suite group id `G15`.**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| group ids the suite uses at the parent | `G1` to `G14` | 14 ids; `G14` occurs 75 times | a token census of the suite at `f25a6350` |
| `G15` in the suite at the parent | — | 0 | the same census |

Survey denominator: the suite's 2,581 lines at `f25a6350`. Control: `G12` returns 205. Canonical choice: `G15`. Justification: documented rationale — the id free at the slice's parent commit, never hard-coded (the #7640 review's FM-1). Out-of-scope drift: none; the plan's `G14` literals for #6893's group are re-bound at this step (§ Integration Points, the dependency graph, the Commit-0 re-binds and D41).

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
| `extract_command` / `handle_per_issue` | #6837, #6848 · #7531 (the non-OK render call only, FM-1; DEV-25) · #6893 (the deferral guard's subject only, FM-2; DEV-29) | Stage 4; step 1; step 3 |
| `handle_integration` | #6848, #6236 · #7531 (the non-OK render call only, FM-1; DEV-25) · #6893 (the deferral guard's subject only, FM-2; DEV-29) | Stage 4; step 1; step 3 |
| the probe helpers (`span_shell_operator`, `is_runnable_probe`, `runnable_probe_of`, `method_outside_verb_spans`) — new at step 3, after `extract_command` | #6893 · #6848 (its scope step and the handlers' shell-operator refusal call `span_shell_operator`, D38, D50) · #6236 (its CIAC lint calls it, D38) · #6837 (INT-4: `runnable_probe_of`'s pick stays `extract_command`'s designated span) | step 3 |
| `dispatch_check` | #6848, #6854 | Stage 4 |
| `emit_md` / `emit_json` roll-up | #6854, #6848 · #7531 (D19's DEGRADED clause) | Stage 4; #6854 R10 |
| header `SCHEMA_VERSION` | **#7531 carries the one 4 → 5 bump**; #6848 and #6854 record themselves as later contributors; #6180 owes none | Stage 4, restated by D40 |
| `usage` | #6180, #6893, #6848, #7531 (AC-3, co-discharged; and the EXIT CODES line for D19, landed at step 1), #6837 | Stage 4; delta; #6837 R6; step 1 |
| `eval_free_run` `:911–934` | #7531 (isolation) · #6837 AC-4 · #6848 · #6854 (reader exit and operand rules) | delta; #6854 R10 |
| per-issue dispatch loop `:2466–2483` | #7531 · #6180, #6893 (call site `:2476` inside the body) | delta |
| CIAC dispatch loop `:2488–2503` | #7531 · #6848, #6236 | delta |
| children on the dispatch path `:1081`, `:1177` | #7531 · #6848 (a fixed `git` child) | delta |
| `RUNNABLE_VERBS` `:717` | NOT CHANGED (#6848 AC-3 asserts the literal) | delta |
| `count_from_output` | #7531, #6854, #6848 | #7531 R5; #6854 R10 |
| the version-metadata block | #7531, #6180, #6848, #6854 · #6893 (a no-bump note, DEV-29) | #7531 R5; #6854 R10; step 3 |
| the FD-0 doctrine block | #7531 | #7531 R5 |
| the refusal model (`stdin_input_refusal`, `reads_stdin_cmd`) and the renderer (`unreadable_observed`) — new at step 1 | #7531 · #6854 (its reader exit and operand rules sit beside them) | step 1 |
| the `main()` exit block | #7531 (the EXIT_INTERNAL branch for a DEGRADED stream, D19; DEV-25) | step 1 |
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
- Stage-5 amendments to the designs' criteria: #6893's INT-5 (vs #6854) reads "G15 green on #6854's head; D28's verb-scoped exit-0 rule lands in the same merge as the probe step", and INT-7 (vs #6685) is added — G15 and #6848's round-2 group green on #6685's head (D30, D31; extended under D50, which places round 2's group in #6848's slice). G15 is #6893's group, the id free at step 3's parent; the designs named it G14 before steps 1b and 2 took G13 and G14.

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
| R15 | **#6893's scope is re-opened while later slices wait** | D45 re-opened #6893's Solutioning; D-6893b may move the tool-command half into #6848's slice | MEDIUM / CHEAP | Resolved: D-6893b rendered (D50–D54, the record on #7834). The four deploy-route limbs land in #6848's slice at step 5; #6893's step 3 is round 1 plus D38's shared predicate, and its rows here were updated at step 3 |

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
| #6180 | AC-4 | declared, verification deferred to Stage 8 named read of the D-6180 ADR (remove branch only) | REINTERPRET-WITH-RATIONALE (PR-2, adopted by D17): of the 133 class cells on 11 plans, 73 are redundant, 16 contradict their probe or cannot route, 16 are overridden by the keyword fallback, and 28 declared rows on 5 plans are left unconsumed, accepted — the 28 are listed in the ADR's source observations |
| #6180 | AC-5 | `grep -c -F "V6180-AC5" release/tools/tests/test_verify_release_plan.sh` at least 1 | paired mutation arm shows a behavioural difference |
| #6893 | AC-1 | `grep -c -F 'classify_family ""' release/tools/verify-release-plan.sh` expect 0 | 0, the empty-hint call gone · control: `grep -c -F 'classify_family' release/tools/verify-release-plan.sh` → 3 at pin · column cells: V6180-AC5a (G14) |
| #6893 | AC-2 | `grep -c -F "V6893-AC2" release/tools/tests/test_verify_release_plan.sh` at least 1 | REINTERPRET (D30, D45): a runnable probe is graded by its probe whatever the prose, and a declaration outside it still wins — graded here (G15); the deploy-check oracle grades only a row whose command is its invocation — co-discharged by #6848's round-2 arms, graded on #6848's head (D50) |
| #6893 | AC-3 | `grep -c -F "V6893-AC3" release/tools/tests/test_verify_release_plan.sh` at least 1 | rows with no runnable probe keep their declared route or keyword arm, controls carrying routing keywords — graded here (G15); the deploy check is reached only by declaration — graded on #6848's head (D50) |
| #6893 | AC-4 | `grep -c -F "V6893-AC4" release/tools/tests/test_verify_release_plan.sh` at least 1 | reverting either step moves a named row: without the probe step a keyword steals a probe — graded here (G15 M1–M3); with the prose route restored a no-command row reaches the oracle — graded on #6848's head (D50) |
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
- **#6837 AC-1** re-binds to V6180-AC5b (#6893 design Change 4). **#6837 AC-2 stays on V6837-AC2**, authored in #6893's group G15 (D41; the decision named it G14, before steps 1b and 2 took G13 and G14). **#6837 AC-3** takes the runnable method and its control from #6837's design (R4, Change 5); it is RED until #6180's `:491` rewrite lands.
- **Co-discharges, graded once:** #6837 AC-1/AC-2 on #6180's and #6893's arms; #7531 AC-3 on the arm in #6893's slice; #6685 AC-1's undeclared limb on D26's residual, landed in #6854's slice; #6893 AC-2's and AC-3's deploy-route limbs and AC-4's prose-route revert on #6848's round-2 arms, graded on #6848's head (D50).

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
| **D41** | Where #6837 AC-2 is graded | On V6837-AC2, in #6893's group — G15 as landed (the decision named it G14, before steps 1b and 2 took G13 and G14); AC-1 re-binds to V6180-AC5b |
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
| DEV-2 | #7640 — review of #6180's design (`issuecomment-5819808125`; aggregate Major) | Minor findings PR-3, FM-1, FM-2, FM-3 | D17; D30 | FM-1 (suite group G14 — the id free at step 2's parent, after step 1b took G13) and FM-2 (the column example dropped from stage-04 `:491`) adopted (D17); FM-3's residual stated in #6180's slice, with its matcher fix landing in #6893's slice under the rule D30 adopted; PR-3 carried no disposition. The Majors (PR-1, PR-2, CD-1) adopted as D17 (A′) |
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
| DEV-25 | `release/tools/verify-release-plan.sh`, regions outside #7531's Contention Map rows (step 1) | Three small edits outside the rows #7531 held: the non-OK branch of `handle_per_issue` and of `handle_integration` now calls the shared renderer `unreadable_observed`, one line each, in regions held by #6837/#6848 and #6848/#6236; and the `main()` exit block, an unlisted region, gains the EXIT_INTERNAL branch for a DEGRADED stream. The Contention Map now names #7531 on those regions, and adds rows for the refusal model and the renderer that step 1 introduced | D18 adopted FM-1, whose remedy renders the refusal in the handlers; D19 set the exit. A minor adjustment under Stage 6 B3; serial order (P0) resolves the overlap with the later slices | APPLIED at `a3683b80` |
| DEV-26 | `release/tools/tests/test_verify_release_plan.sh`, suite group G13 (step 1b) | Two helpers are group-local where the #6236 design named shared ones. G13 reads each record from its own line (`g13_verdict`, `g13_observed`) rather than through `verdict_of` / `observed_of`, and carries its own mutate-and-prove copy (`m6236`) rather than `mutate_proved` | Measured: the shared readers isolate a record with `[^{}]*`, so v4.43's CIAC-3, whose method quotes a set in braces, reads as absent, and the first G13-R run failed on that row. The directory `mutate_proved` writes to is removed at the end of G9-M, which is why G10 to G12 each carry their own copy; `m6236` adds the exact-site count step 1b requires. A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED in the step-1b commit |
| DEV-27 | `release/tools/verify-release-plan.sh`, the fcm-delivery reconciliation note (step 2) | One comment line outside #6180's Contention Map regions: the stale `(:363-371)` reference now names the `RUNNABLE_VERBS` doctrine instead of a line range that has moved | The plan's step-2 row assigns "the stale internal line reference" to this step, and the Stage-4 plan named this one; the new text is #6893's Site H text for the same line, so #6893's gate stays green. A minor adjustment under Stage 6 B3 | APPLIED at `c4e7fdba` |
| DEV-28 | `release/tools/tests/test_verify_release_plan.sh`, suite group G14 (step 2) | G14 carries 12 assertions where the #6180 design's block carried 11: a denominator arm (G14-0); the row-equality arm fails on an absent row; the seeded class read is proved to apply at exactly 1 site, not only to change the bytes; and AC-3's family under the mutant must read runtime-suite in the fixture and be present and different in the control | Each closes a vacuous-pass path: the shared readers return empty for an absent record, so an equality between two absent rows and an inequality against one both pass. The exact-site count follows G13's precedent. A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED at `bb025b00` |
| DEV-29 | `release/tools/verify-release-plan.sh`, regions outside #6893's Contention Map rows (step 3) | Three regions the D30-rendered design names but the Commit-0 map did not assign to #6893: the deferral guards in `handle_per_issue` and `handle_integration` (their `case` subject only), a no-bump note in the version-metadata block, and a new helper region after `extract_command` (`span_shell_operator`, `is_runnable_probe`, `runnable_probe_of`, `method_outside_verb_spans`). No existing line of `extract_command`, `main()`'s loops, `eval_free_run`, `parse_ciac`, `RUNNABLE_VERBS` or `SCHEMA_VERSION` changed. The Contention Map now names #6893 on those rows and adds the helpers' row | D30 adopted FM-2, whose remedy is in both guards, and the design's Sites A and C place the note and the helpers. A minor adjustment under Stage 6 B3; serial order (P0) resolves the overlap with the later slices | APPLIED at `e14bb9ca` |
| DEV-30 | `release/tools/tests/test_verify_release_plan.sh`, suite group G15 (step 3) | G15 carries 29 assertions where the round-1 design's G14 block carried 24. The three rows D30 mandates — FM-1's two rows and FM-5's pin row — sit in a fourth table as AC-16 to AC-18, so the design's AC-1 to AC-15 numbering, which round 2's restatements cite, is kept. A quote-blind mutation (M5) proves AC-16 observes the quote-aware test. Every seeded failure is proved to apply at exactly its sites, and an arm whose mutation did not take is not graded. The boundary arm requires its records present | Each closes a vacuous-pass path: the design's M1 to M3 would read a mutation that did not take as a detection on the unmutated tool, and a negated family test passes on an absent record. Follows G13's and DEV-28's precedent. A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED at `22399359` |
| DEV-31 | `release/ADRs/ADR-207-a-rows-grading-route-is-declared-in-its-method-cell.md` (step 3) | Beyond Decision 6, its source observation and its alternatives line: the Status gains a Decision-6 provenance sentence and `deciders:` names the D-6893 gate; Reversibility splits Decisions 1–5 (CHEAP) from Decision 6 (MODERATE, per the D30 record), where #7641's body reads "Decisions 1–6 CHEAP"; Decision 6's third bullet carries D30's own wording, "under D29 it is named not run"; and its last bullet is unqualified, because D50 places the qualification with Decision 7 in #6848's slice. The Consequences section is unedited | The ADR authoring guide's record-versus-revise boundary: each edit records a rendered decision and revises none, and the guide's closed forbidden list keeps an Accepted record's consequences unedited. #7641's reversibility line is routed to the hub. A minor adjustment under Stage 6 B3, inside the ADR's matrix row | APPLIED at `e14bb9ca` |

---

## Documentation Impact

Each row lands with its card's slice; the slice records the status and the commit.

| Issue | Declared docs | Status | Commit | Notes |
|---|---|---|---|---|
| #7531 | `--help` agrees with dispatch (co-discharged under D-6180) | UPDATED — step 3: the CHECK FAMILIES and per-issue lines describe the dispatch the classifier performs | step 1: `a3683b80` · step 3: `e14bb9ca` | Graded on V7531-AC3, in G15. Step 1 also updated `--help`'s EXIT CODES block (exit 1 now covers a DEGRADED verdict stream, D19) and added the executor's in-file FD-0 doctrine; step 2 retired the predicate-class wording |
| #6180 | stage-04 AC-Binding Limb 1 (`:491`); the D-6180 ADR (#7641) | UPDATED (the stage-04 bullet) · CREATED (the ADR file) — step 2 | `c4e7fdba` | Card declares no Documentation Impact section; the design's Changes 2 and 5 carry it. Step 2 also rewrote the executor's `--help` CHECK FAMILIES line and regenerated the release ADR index |
| #6893 | the classifier doctrine and the `usage()` per-issue line; Decision 6 in #7641 | UPDATED (the classifier doctrine; `usage()`'s CHECK FAMILIES and per-issue lines) · UPDATED (the D-6180 ADR: Decision 6 appended) — step 3 | `e14bb9ca` | Card declares no Documentation Impact section; the round-1 design's Changes 1 and 3 carry it. Round 2's `usage()` and stage-04 text land with #6848's slice (D50) |
| #6837 | stage-04 Limb 1 bullet (after the #6180 edit) | lands with step 4 | — | AC-3 grades the authoring surfaces |
| #6848 | stage-04 "What the plan verifier can execute" paragraph; `usage()`; the partition ADR (#7647) | lands with step 5 | — | — |
| #6854 | stage-04 "A method with nothing to run" paragraph; the stage-07 laundering-guard line; its Decision lines in #7647 | lands with step 6 | — | — |
| #6685 | none expected (card: parity with an existing disposition); its Decision line in #7647 | lands with step 7 | — | NONE unless the slice adds text |
| #6876 | the runtime-suite selection map; stage-06/07/08 citations by role; the ADR (#7672) | lands with step 8 | — | The map is itself the documentation surface |
| #7494 | stage-07/08 payload fields; the criterion-namespace section; the binder help; eval-writer P1/P2; the ADR (#7676) | lands with step 9 | — | Card declares no Documentation Impact section |
| #6236 | stage-04 CIAC authoring text; `release-process.md` QC3.5 reading table; stage-09 A3.6; G-PR10 / G4-06 in `gate-criteria-spec.md`; its Decision lines in #7647 | lands with step 10 | — | Card declares no Documentation Impact section. Step 1b (the V6236-AC4 arm set and its fixture) lands no declared doc |

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
| **Step 1 (#7531) — the suite, RED then GREEN** | Stub root = a `git archive` of the branch with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line. Baseline (the unmodified suite) 215 passed / 2 failed. RED — the G12 arms (`6360031a`) on the pre-fix executor: **220 / 31**, the prediction stated before the run. GREEN (`a3683b80`): **249 / 2**, likewise predicted. The 2 are P1 and M9's control, which fail identically on the unmodified suite because the always-on FCM family reads `diff-unresolvable` outside a repository; every one of the 217 pre-existing assertions keeps its outcome. The stub log stayed empty on every suite run; its sensitivity arm, a one-sync-row plan, logged 1 line. CI on `a3683b80`: **253 passed / 0 failed** (macOS job, bash 3.2.57) |
| **Step 1 — RED and GREEN per fixture** | Drain fixture: 3 of 6 rows and 2 of 3 CIACs, the planted cells graded `count=3` and `count=1` → 6 of 6 and 3 of 3, both cells ERROR `stdin-reader:grep`. Verb matrix: 2 of 15 and 2 of 7 → 15 of 15 and 7 of 7, 10 named refusals. Child route: 1 of 4 rows with exit 0 → 4 of 4 with exit 0. v3.65.1: 3 of 11 → 11 of 11, with AC-3, AC-5 and AC-9 each ERROR `stdin-reader:grep` |
| **Step 1 — `RUNNABLE_VERBS`** | sha256 of the line: `8fcbe4d4…` before and after the slice; the literal occurs exactly once. Control: a one-byte edit of the line moves the hash |
| **Step 1 — this plan, through the executor (C4, hermetic)** | Fixed executor on this file in the stub root: `**Verdict roll-up:** 7 PASS / 33 FAIL / 12 SKIP / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`; JSON roll-up `stream_state` fetched, 48 of 48 records read. The pre-fix executor on the same file reads 4 / 36 / 12 / 1, the Commit-0 figure. Exactly 3 records change, all this slice's: #7531 AC-1 and AC-2 (FAIL → PASS, the arm labels now present) and CIAC-4 (FAIL → PASS, `SCHEMA_VERSION="5"` counted once). #7531 AC-3 and CIAC-6 stay FAIL until steps 3 and 4 land their arms. The one ERROR is `FCM-COVERAGE diff-unresolvable`, from the stub not being a repository |
| **Step 1 — runtime suite (map row 4)** | `release/tools/verify-release-plan.sh` selects row 4; the tests, fixtures and this plan match no row. Row 4's runner, `check-selftest-coverage.py --run`, does not exercise the verifier: 0 of its 77 discovered tools reference it (control: the suite references it 49 times) — the residual #6876 closes. CI on `a3683b80`: **74 of 74** in the ubuntu partition. Locally, against the stub root: 69 of 74, the 5 failures each a stub artifact (4 need a repository; 1 is the inert event-writer stub). One `test-run/suite-pass` event emitted and read back |
| **Step 1 — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with this slice's 5 paths on stdin: 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 1 — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over this plan and the two new fixtures: 0 findings. Control: a run-directory copy with one planted broken link returns 1 |
| **Step 1 — ADR index** | N/A — this slice adds no record under `release/ADRs/` |
| **Step 1b (#6236) — the suite** | Stub root: a `git archive` of `925cbd16`, with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line. The unmodified suite gives 249 passed / 2 failed. With G13 it gives **262 passed / 2 failed**: the 13 new assertions all pass. The 2 failures are P1 and M9's control, which fail identically on the unmodified suite because the stub is not a repository. All 251 earlier outcome lines are unchanged, in outcome and in text. The stub log stayed empty on every run. The suite ran on bash 3.2.57 |
| **Step 1b — V6236-AC4 and its arms, each predicted before its run** | Each result below matched the prediction written before the run. The fixture on the shipped tool: 12 records (5 AC, 5 CIAC, 2 coverage), all 12 SKIP, exit 0. The fixture without its override line gives the same 12 records. v4.43 on the shipped tool: CIAC-1 to CIAC-5 all SKIP (three refused tools and two documented-decision rows); the run exits 3 through the delivery family alone. M1 applies at 1 site and moves the exit from 0 to 3 on the same 12 records. M2 applies at 2 sites: AC-1, AC-2, CIAC-1 and CIAC-2 read ERROR `count-unreadable:matcher-exit-3`, the other six rows are unchanged, and the run exits 3 |
| **Step 1b — this plan's #6236 AC-4 row, through the executor (C4, hermetic)** | The same stub root, with the head executor run on this file. Against the suite at `925cbd16`: `7 PASS / 33 FAIL / 12 SKIP / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`, with #6236 AC-4 FAIL `count=0 (wanted >= 1)`. With G13: `8 PASS / 32 FAIL / 12 SKIP / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`, with #6236 AC-4 PASS `count=26 (>= 1)`. Exactly that one record changes; the JSON roll-up reads `stream_state` fetched and 48 of 48 records. These notes add no parsed row: the edited file yields the same 53 records, and only the provenance record's line count moves (960 to 1004) |
| **Step 1b — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with the step's 3 paths on stdin, returns 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 1b — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over the new fixture and this plan: 0 findings, exit 0. Control: a run-directory copy of the fixture with one planted broken link returns 1 finding, exit 1 |
| **Step 1b — runtime suite (map row)** | None of the step's three paths matches a map row: the suite and the fixture sit under `release/tools/tests/`, which row 4's `release/tools/*.sh` does not reach (the residual #6876 closes), and the plan is not code. The selection is therefore row 6, the honest `test-run/suite-skip`, and the explicit suite run above is this step's runtime evidence (R8). Control: the same resolver sends `release/tools/verify-release-plan.sh` to row 4 |
| **Step 1b — ADR index** | N/A — this step adds no record under `release/ADRs/` |
| **Step 2 (#6180) — the suite, RED then GREEN** | Stub root: a `git archive` of each tree with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line. The parent `51d1c0cb` gives 262 passed / 2 failed. RED — G14 on the pre-removal executor: **272 / 4**, the two new failures exactly G14-1 and G14-2. GREEN — the removal: **274 / 2**, +12 `ok` and 0 new failures. Each figure was predicted before its run. The 2 are P1 and M9's control, which fail identically at the parent because the stub is not a repository. All 264 earlier outcome lines are unchanged in outcome and text on both runs, and the stub log stayed empty on every suite run (sensitivity: one direct call of the stubbed deploy check logged 1 line). CI on the macOS smoke job: `bb025b00` **276 passed, 2 failed** (exactly G14-1 and G14-2); `c4e7fdba` **278 passed, 0 failed**, ALL PASS |
| **Step 2 — behaviour-neutrality** | The pre-removal and the removal executor side by side in one stub root, `--format=json`, stdin on the null device: **byte-identical output and equal exit codes on 291 of 291 inputs** — 217 plans and 74 test-fixture markdown files. Controls: the pre-removal executor against itself, 3 of 3 identical; a class-read variant differs on a class-column plan and on the class-inert fixture, and not on this plan, which has no class column. The stubbed deploy check absorbed every sync and regression delegation, 58 calls, evenly split between the two executors |
| **Step 2 — this plan, through the executor (C4, hermetic)** | The parent tree gives `8 PASS / 32 FAIL / 12 SKIP / 1 ERROR`. This step's tree gives **`14 PASS / 26 FAIL / 12 SKIP / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`**, as predicted: exactly 6 of 53 records change, each FAIL → PASS — #6180 AC-5 (`count=29`), #6837 AC-1 (`count=13`), #6837 AC-3 and #6893 AC-1 (`count=0 (== 0)`), and CIAC-1 and CIAC-2 (`co-occurrence count=0`). These notes change no parsed row: the edited file yields the same 53 records and verdicts, and only the provenance record's line count moves. The one ERROR stays FCM-COVERAGE `diff-unresolvable` |
| **Step 2 — the class-column measurement** | The executor's own parser and classifier, eval-extracted as the suite does, over the pinned corpus (215 plans) and the mainline corpus (217): 1,058 and 1,080 indexed rows; 133 class cells on 11 plans in both; wiring as coded moves 49 (28 unclassified → family, 21 between families, the Stage-5 breakdown exactly); the 28 method-silent rows sit on 5 plans at the same file and line in both corpora, and those 5 plans are byte-identical between the two. Control: a re-implementation of the hint arm agrees with the extracted classifier on every class row (0 mismatches) |
| **Step 2 — the ADR file and index** | `renumber-adr.py --detect` → `ANCHOR 206 · NEXT-FREE 207 · CLAIMED-SET-BRANCH-ONLY -`. `generate-adr-index.py --verify` reads `MISSING` for the new record, COUNT 1, before `--write`, and **COUNT 0** after. `check-adr-durability.py --diff-base 51d1c0cb` → COUNT 0 (sensitivity: a copy with a non-enum status → R1 and R7; a copy with an unanchored live count → R2-COUNT). `check-adr-numbers.py` on this branch's tree reports a gap, because the mainline's two newest records are not on this branch; on the merge-ref ADR set (the mainline's two ADR directories plus the new file) it reads PASS, contiguous, and CI's ADR-number integrity gate passed on `c4e7fdba`. Issue references: 10, all in `## References` and all issues (none a pull request); a replica of the gate's placement rule reads 0 outside the block (sensitivity: a planted reference in the Context → 1); CI's Issue-reference validity gate passed |
| **Step 2 — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with the step's 8 paths on stdin, returns 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 2 — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over the ADR, the release ADR index, stage-04, the two fixtures and this plan: 0 findings, exit 0. Control: a run-directory copy of the ADR with one planted broken link returns 1 finding, exit 1 |
| **Step 2 — runtime suite (map row 4)** | `release/tools/verify-release-plan.sh` selects row 4; the suite, the fixtures, the ADR, stage-04 and this plan match no row. Row 4's runner, `check-selftest-coverage.py --run`, does not exercise the verifier: it is absent from the discovered set (control: `version-grammar.sh` is present) — the residual #6876 closes — so the explicit suite runs above are this step's runtime evidence (R8). CI on `c4e7fdba`: ARM A **74 of 74**. Locally, in stub roots of the parent and of this step: 69 of 74 on both, the same 5 environment failures, with identical per-tool status lines. One `test-run/suite-pass` event emitted and read back |
| **Step 3 (#6893) — the suite, RED then GREEN** | Stub roots: a `git archive` of each tree with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line, the original text kept. The parent `f25a6350` gives 274 passed / 2 failed. RED — G15 and the R-M2 split on the pre-fix executor: **286 / 16**, the new failures exactly the 13 G15 arms for new behaviour and R-M2a. GREEN — the fix: **305 / 2**. Each figure was predicted before its run. The 2 are P1 and M9's control, which need a repository. All 274 earlier outcome lines are unchanged in outcome and text on both runs (sensitivity: a planted flip reads 1 changed), and the stub log stayed empty on every suite run (sensitivity: one direct call of the stubbed deploy check logged 1 line). CI on the macOS smoke job: `22399359` **290 passed, 14 failed** (exactly the 14 predicted); `e14bb9ca` **309 passed, 0 failed**, ALL PASS. The stale `(:363-371)` reference counts 0, as #6180's slice left it |
| **Step 3 — the helpers, unit battery** | 46 cases over `span_shell_operator`, `is_runnable_probe`, `runnable_probe_of` and `method_outside_verb_spans`, extracted from the shipped executor and run on bash 3.2.57: 46 of 46. Control: the same battery on a quote-blind variant fails 8 |
| **Step 3 — corpus and fixture differential** | The pre-fix and the step-3 executor side by side in one stub root, `--format=json`, stdin on the null device, over every plan (217) and every test-fixture markdown file (47): 258 of 264 inputs byte-identical, and exactly 7 records change, all probe-bearing, in 6 plans, as predicted. v4.56 `#6366` and `#6380` and v4.60 `#6419` AC-4: integration → per-issue, the same PASS. v4.55 `#5653` AC4: regression → per-issue, FAIL (stub) → PASS `count=25 (>= 15)`. v3.50 `#501`: regression → per-issue, FAIL → ERROR `matcher-exit-2`. freshness-gate `#4332` AC-4: sync → per-issue, FAIL → PASS `command-succeeded`. v4.20 s3: unclassified → per-issue, ERROR → PASS `command-succeeded` (its content unchecked until D28 lands at step 6). 0 fixture records, 0 CIAC records and 0 exit codes change, and D39's masked exit changes on 0 of the 6 plans (v3.50 reads 4 → 5 failing rows and v4.20 5 → 4, both failing before and after). Control: the pre-fix executor against itself, 264 of 264 identical |
| **Step 3 — population survey** | The executor's own parser and helpers, eval-extracted, over the 217 plans: 1,110 indexed rows, 369 carrying a runnable probe (the 338 outside this plan match the round-2 design's P2 exactly); 376 verb-led designated commands, 6 with a shell operator outside quotes and 27 with an operator character only inside quotes; round 1's token test and the shipped quote-aware test disagree on 0 of the 376; the span-kind deferral read changes 0 of the 45 deferred per-issue rows and 0 of the 390 cross-issue methods |
| **Step 3 — this plan, through the executor (C4, hermetic)** | The parent tree on its own plan gives `14 PASS / 26 FAIL / 12 SKIP / 1 ERROR`. The step-3 tree with this plan gives **`19 PASS / 21 FAIL / 12 SKIP / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`**, as predicted: exactly 5 of 53 records change, each FAIL → PASS — #6893 AC-2 (`count=28`), AC-3 (`count=3`) and AC-4 (`count=15`), #6837 AC-2 (`count=11`) and #7531 AC-3 (`count=14`) — and the provenance record's line count moves. JSON roll-up `stream_state` fetched, 48 of 48 records. The FCM seam on a run-directory copy parses as before: `declared=50 interpreted=50 obligations=6 excluded=9 conditional=0 uninterpreted=0 pathless=0 prose_led=0`. `check-ac-binding.py --ordinals-only` → VERDICT BOUND. The one ERROR stays FCM-COVERAGE `diff-unresolvable` |
| **Step 3 — the ADR and the index** | `check-adr-durability.py --diff-base f25a6350` → COUNT 0 (sensitivity: a copy with an unanchored count planted in Decision 6 → R2-COUNT). `generate-adr-index.py --verify` → COUNT 0, so no regeneration is owed and the index row stays as step 2 generated it (sensitivity: a copy with a drifted title → DRIFT, COUNT 1). Issue references: 13, all in `## References`, all issues and none a pull request; a replica of the gate's placement rule reads 0 outside the block (sensitivity: a planted reference in the Context → 1) |
| **Step 3 — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with the step's 4 paths on stdin, returns 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 3 — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over the ADR and this plan: 0 findings, exit 0. `check-release-links.py --check-anchors --images` over the same two files: 0 broken. Control: a copy of the ADR with one planted broken link returns 1 finding from each checker |
| **Step 3 — SIGPIPE idiom and identity** | The SIGPIPE gate's five idiom patterns, extracted from the workflow and evaluated with BSD grep over the step's 405 added shell lines: 0 (sensitivity: each idiom alone → 5 of 5; specificity: `x \|\| true` → 0). An identity and public-surface scan of every added line and each commit message: 0 hits beyond each message's one noreply trailer (sensitivity: 4 of 4 planted lines) |
| **Step 3 — runtime suite (map row 4)** | `release/tools/verify-release-plan.sh` selects row 4; the suite, the ADR and this plan match no row. Row 4's runner, `check-selftest-coverage.py --run`, run under § 3's recipe for the row (`none (read-only)`, so no `HOME` override), does not exercise the verifier — it is absent from the discovered set, the residual #6876 closes — so the explicit suite runs above are this step's runtime evidence (R8). CI on `e14bb9ca`: ARM A **74 of 74**. Locally, in stub roots of the parent and of this step: 69 of 74 on both, the same 5 environment failures, identical per-tool status lines. One `test-run/suite-pass` event emitted and read back |

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
- **#7834** — #6893's round-2 Solutioning sub-task (D45), in flight at Commit 0; it carries the D-6893b record (D50–D54) and the hub's owner correction, both rendered before step 3.
- **#7587** — the Stage-6 Engineering sub-task that authored this file (Engineering Commit 0 and #7531's slice).
- **#7638** — the in-flight sibling release PR observed at Commit 0 (shared version and ADR-number slots).
