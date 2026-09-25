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

**Scope lock:** locked on D1–D48 by the Collective Review (D49), with one governed re-opening: #6893's Solutioning re-opened for the keyword-precedence limbs (D45). Its round-2 design (#7834) was in flight at Commit 0; the D-6893b gate then rendered D50–D54, placing the round-2 limbs in #6848's slice at step 5. A later scope change goes to the operator through a Decision Briefing with its impact.

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
| 5 | #6848 | verify-release-plan.sh is silent on awk/git AC methods, and silence is indistinguishable from a pass | P2 - Medium | **L / 8** (D54) | `improvement`, `structure` |
| 6 | #6854 | Behavioural AC rows have no named SKIP, so they land as ERROR and swamp the roll-up | P2 - Material | S / 2 | `bug` |
| 7 | #6685 | verify-release-plan.sh — a documented-decision method on a per-issue row can only ERROR | P2 - Material | S / 2 | `bug` |
| 8 | #6876 | runtime-suite-selection-map's globs cannot reach release/tools/tests/, so the test suites it routes to are unselectable | P2 - High | M / 4 (D6) | `improvement`, `cluster: pipeline-definitions`, `project:pipeline` |
| 9 | #7494 | Acceptance-criterion ordinals collide across three namespaces, and the oracle reader recognizes one heading form | P2 - Material | M / 4 | `bug`, `project:pipeline` |
| 10 | #6236 | A CIAC whose method falls outside the executor allowlist can be graded by no permitted party | P2 | M / 4 | `improvement`, `project:platform-quality` |

- **Record member, neither graded nor counted:** #6894 (closed 2026-09-20 as already fixed; attached as a record).
- **Scheduled into this release, not a milestone member:** #7635 — the markdown presenter drops every record with an empty issue field. D27 folds its fix into #6854's slice (the `(plan)` header, graded by V6854-AC4), and D44 closes it with this release's PR.
- **Size (G3-15, D44, D54):** `effective_pts: raw 34 × 1.3 = 44 — above band, reframe-and-keep with Override vs band 15-25`. **Override:** the members form one capability — the plan verifier and the AC binder grade what a plan declares and say plainly what they did not grade — sharing one surface and root-cause class C10. The operator kept every member at Gate 1 (D4), added #7531 by re-bundle (D8/D9), restated the disposition at the delta gate (D14), re-sized #6837 S → M at the Collective Review (D44), and re-sized #6848 M → L when the D-6893b gate placed #6893's round 2 in its slice, restating the override at 44 (D54).
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
| 4 | #6837 | D29 (B): the designated command graded on its own comparator, every other command named *not run*, never PASS while one exists; the shared primitive (`method_spans`, `comparator_phrases`, the `CMP_*_ALT` constants) and `VERDICT_PARTIAL_SLOT`; arm V7531-CIAC6. As landed: suite group G16 (V6837-AC4, V7531-CIAC6) with the fixture `verify-plan-multi-limb.md`, D48's emphasis tolerance in the shared vocabulary, and the stage-04 Limb-1 bullet carrying FM-1's null sentence | D49, D50 |
| 5 | #6848 | D21–D24: UNRUNNABLE as a fifth, non-failing verdict (roll-up counter, stderr note); tools named only from invocation-shaped spans; the native scope family with its three guards; `emit_table` widened; INT-4 re-binds `VERDICT_PARTIAL_SLOT` to UNRUNNABLE. Writes the partition ADR (#7647) with D37's reconciled table and #6837's Decision line. A later contributor to the bump (D40). AC-3's literal reads PASS at the pin, so it is proved armed-red-then-revert. Carries #6893's round 2 (D50): the declared deploy route (D51, D53), D52's partial rule for a declared row, the handlers' shell-operator refusal, and Decision 7 appended to #7641's file. Suite groups G17 and G18 | D49, D50 |
| 6 | #6854 | D26–D28: the per-issue residual (SKIP `no-executable-command-in-method`), the roll-up over the true population with the `(plan)` header (the #7635 fix), the reader exit and operand rules; the stage-07 laundering-guard line (D46). A later contributor to the bump (D40). As landed: D38's per-issue guard (placed here by the hub's owner correction on #7834) and its reader-semantics table, the stage-04 paragraph, and Decisions 9–11 in the partition ADR (#7647, D47); suite group G19 | D49, D50 |
| 7 | #6685 | D31–D32: two fixtures and one arm group, 0 executor lines; lands after #6854 and #6848, its two native build edges. As landed: suite group G20 over `verify-plan-documented-decision.md` and its control twin, with the #7665 review's fixes (FM-1 to FM-3, O-2, O-3); Decision 12 in the partition ADR (#7647, D47); the suite header gains G18's entry | D49, D50 |
| 8 | #6876 | D33–D34: map grammar and reference resolver, rows 6 and 7, the fallback as row 8 cited by role; the connector's offline `--self-test`; the exclusions line; the package rebuild; the install-tests comment; the ADR file (#7672). 8a (Changes 1–4) before 8b (Changes 5–7). As landed: 8a with FM-1, FM-2, PR-2 in its forbidding form and D37's reading table in the map's § 4; 8b under a pmo-skill-editor Mode A session, the SKILL.md unchanged; the ADR file for #7672 with the regenerated release ADR index; 0 executor, suite or fixture lines | after D-6893b |
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

### Step 4 (#6837) — as landed

Commits: `c1671607` (suite group G16, its fixture, and the G12 reading of a bare verb, RED on the pre-fix executor) · `b49ce79e` (the multi-command path, the shared primitive, the emphasis tolerance, `usage()` and the stage-04 bullet) · the plan update that carries this section. Scope: D29 (B) with sub-choices (iii) and (R); the review's FM-1 sentence and FM-4 scope sentence and CIAC-6's wording, adopted with D29; D37's scoping and wording; D48's emphasis tolerance. (A)'s later-limb execution and its refusal clause are not built (D29, D48).

- **The designated command.** `extract_command` is re-expressed on `method_spans`: it returns the first backticked span whose leading token is an allowlisted verb and that carries an argument, skips a bare verb (sub-choice (R)), and keeps its fallback and its bare-string tail. `runnable_probe_of` still calls it, so the probe step's pick is this designated span, and `span_shell_operator`, `is_runnable_probe`, `runnable_probe_of`, `method_outside_verb_spans`, `classify_family`, `eval_free_run` and `main()` are byte-unchanged (INT-4).
- **The multi-command path (D29 B).** In both handlers, right after the declared-deferral guard, `method_limbs` reads the method's commands and `limbs_are_multi` sends a method naming two or more of them to `grade_limbs`. The designated command runs through `eval_free_run` inside the dispatch loop's body and is graded on the comparator written after it, up to the next command (`limb_comparator`): two that disagree read ERROR `comparator-ambiguous`, and none keeps the exit-status reading. Every other command is reported as "did not run (<reason>)". A FAIL or ERROR from the designated command stands; a designated PASS takes `VERDICT_PARTIAL_SLOT`, observed `partial-execution: limbs run 1 of <N>: <each command in order>`. A method naming one command, or none, takes the one-command path unchanged.
- **The reasons (DEV-34).** "names no input" for a further reader that `reads_stdin_cmd` refuses as a stdin reader — sub-choice (iii) for an undeclared one, and the same reason for one that carries a comparator of its own, because under (B) neither runs and a missing input is what its author has to fix (a device or unmodelled-option refusal is named by its own token); "outside the verb set" for a tool `span_invokes_tool` names; otherwise "only the designated command runs". (A)'s declaration reasons, "no comparator of its own" and "comparators that disagree", are not reported: under (B) they are not why a command did not run.
- **The shared primitive (#6236 AC-1).** `method_spans` keeps the design's record, `<ordinal> TAB <class> TAB <leading-token> TAB <prose-after> TAB <span>`, with the span last and the classes runnable · bare-verb · not-runnable · mention. `span_invokes_tool` is the stub a tool catalog replaces (#6848, D22). `comparator_phrases` reads the constants `CMP_GE_ALT`, `CMP_LE_ALT`, `CMP_EQ_ALT` and `CMP_EMPH_ALT`, which `extract_threshold` now reads too, so the one-command path and the designated-command path share one vocabulary. `VERDICT_PARTIAL_SLOT` is bound to `$VERDICT_SKIP` in one line, which #6848 re-binds to UNRUNNABLE at step 5 (D37, INT-4).
- **D48.** One markdown emphasis run (`**`, `__` or `*`) between a comparator and N is read; "= N", "→ N" and "returns N" are not. It moves one-command rows too: the 2 FAIL → PASS rows the review measured, 18 v4.60 rows whose count now matches their emphasised expectation, and v4.60 `#5651` AC-1 (see Step 4 — Evidence-Grounding E4 and the Verification Evidence rows).
- **Text.** stage-04 Limb 1 gains the rule for its own table (D37), with FM-1's sentence: "A null needs `expect 0` or `expect zero`: a command followed by no comparator is graded on its exit status, which reads a zero count as FAIL". `usage()` gains MULTI-COMMAND METHODS. A no-bump note sits above `SCHEMA_VERSION`. The FD-0 doctrine names the four new loops, which take the body form, and drops `extract_command`'s old exemption (DEV-32).
- **G15's AC-18 is unchanged at this step (DEV-36).** `span_invokes_tool` is a stub until #6848's catalog (D22) replaces its body, so the `bash core/deploy/deploy.sh --check` span is a mention here, AC-18 names one command, and arm V6893-AC2 j still reads per-issue/PASS `count=1`. When the catalog names that span a tool at step 5, the row becomes multi-command and reads the slot, naming the deploy check "did not run (outside the verb set)"; #6848's slice then updates arm j (keep the per-issue family, assert the slot and that reason) and extends `classify_family`'s step-1 PRECEDENCE comment. G16's M5 pins that seam.
- **Suite group `G16`.** The id free at this step's parent `96ed0a10`, where the suite uses G1 to G15 and never `G16`. A header entry and 32 assertions:
  - G16-0: the denominator — the fixture still plants its paired rows, and all 14 rows and 5 CIACs emit;
  - V6837-AC4: the slot is bound once, to a declared verdict that is not PASS; a–l over the fixture — two commands with the designated one holding (a), a false non-first command never PASS in either loop (b), the same false value in the first command FAILs (c, the AC's control), a comparator binds to its own command (d), a further command with no comparator the vocabulary reads (e), a null graded on its own `expect 0` (f), one-command rows unchanged (g), the cross-issue handler (h), a leading bare verb (i), a tool span that stays prose under the stub (j), emphasis read (k) and "returns 0" not read (l);
  - V7531-CIAC6 a–c: an operand-less further command, undeclared and declared, reads "did not run (names no input)" in both loops, and every row after it emits with the controls PASS;
  - V6837-AC4 m–q: `extract_command`'s 11 pinned cases, `comparator_phrases`, `limb_comparator`, one vocabulary in both bodies, and `--help`;
  - seeded failures and a seam, each proved to apply at exactly its sites: M1 (the hook removed, 2 sites: AC-2 and AC-8 PASS again), M2 (the comparator read from the whole cell, 1 site: AC-8 ERROR `comparator-ambiguous`), M3 (a further command run outside the stdin-isolated dispatch, 3 sites: the per-issue loop drains to 5 of 14 rows, the still-isolated CIAC loop keeps 5 of 5, exit 1 — the armed-red-then-revert proof for CIAC-6's already-true property), M4 (a bare verb taken as the command, 1 site: AC-13 no longer PASS), M5 (a tool catalog in `span_invokes_tool`, 1 site: AC-14 reads the slot, naming python3 "did not run (outside the verb set)").
  - G12-5 now counts 9 named readers, G12-5b reads the stdin-verb fixture's bare `cat` (its AC-8) as prose, and `g12_refused` accepts a designated command's refusal named inside a command list, which v3.65.1 AC-9 now reads (DEV-33).
- **RED, then GREEN, each predicted before its run.** Stub roots, each a `git archive` with logging `exit 97` delegation stubs: the parent `96ed0a10` gives 305 passed / 2 failed; RED (`c1671607`, on the pre-fix executor) **311 / 24**, the new failures exactly G12-5b and 21 G16 arms; GREEN (`b49ce79e`) **338 / 2**. The 2 are P1 and M9's control, which need a repository. All 307 earlier outcome lines keep their outcome on both runs; the one text change is G12-5's reader count, 10 → 9. CI on the macOS smoke job (bash 3.2.57): `c1671607` **315 passed, 22 failed** (exactly the 22 predicted); `b49ce79e` **342 passed, 0 failed**, ALL PASS, with G16's 32 assertions green.
- **Rule for later slices.** G16's mutations anchor on the two handlers' hook line `  if limbs_are_multi "$limbs"; then grade_limbs "$limbs"; return; fi` (M1), `method_limbs`' `cmp="$(limb_comparator "${L_prose[$i]}")"` (M2), `grade_limbs`' `      stdin)` arm together with G12's refusal and per-issue redirect anchors (M3), `extract_command`'s ` bare-verb) continue ;; esac` (M4) and the line `span_invokes_tool() {` (M5). A slice that rewrites one of those lines updates G16 in the same commit. The arms derive the slot's value from `readonly VERDICT_PARTIAL_SLOT="$VERDICT_<NAME>"`, so #6848's re-binding keeps them green if the line keeps that shape; M5 changes when the catalog replaces the stub's body, and #6848's slice restates it then.
- **For the partition ADR (#7647, D47).** The Decision line #6848's slice carries into the file, with this card's issue in its References block: "A method that names more than one command is graded on its designated command — the first allowlisted verb that carries an argument — against the comparator written after that command. Every other command it names is reported as "did not run (reason)", and the row is never PASS: a FAIL or ERROR from the designated command stands, and a designated PASS takes the can't-run outcome (UNRUNNABLE), naming the command that ran and each one that did not. A bare verb (a tool named in prose, with no argument) is never a command, and the further commands are not run."

### Step 4 (#6837) — Evidence-Grounding (D42)

The canonicalizations D29 and D48 introduced, beyond the five the Stage-5 design grounded (the splitter record and span classes, limb roles and reasons, `CMP_*_ALT` and `VERDICT_PARTIAL_SLOT`, the fixture and labels, the AC-3 surface set), several of which (B) re-reads. Every survey ran on 2026-09-25 at `96ed0a10`, the branch head before this step, or over its 217-plan corpus, through the parent and step-4 executors side by side in one stub root.

**E1 — the designated command: the first allowlisted verb that carries an argument, never a bare verb (D29, sub-choice (R)).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the executor's command notions at the parent | `extract_command` (the first span led by an allowlisted verb, a bare one included) · `is_runnable_probe` (at least one argument) · `runnable_probe_of` (the pick, if it is a probe) | 3 functions | the executor at `96ed0a10` |
| corpus picks a bare verb made at the parent | a bare `grep` or `cat` span taken as the command | 19 rows / 9 plans, plus 1 fixture row | the differential: 17 FAIL → SKIP and 2 FAIL → ERROR `stdin-reader:grep`, each crash-born |
| rows naming two or more commands | a designated command and at least one other | 97 rows / 26 plans (82 per-issue, 15 cross-issue) | the differential |

Survey denominator: 265 inputs (217 plans and 48 fixture files), 152 records moved. Control: the parent executor against itself moves 0. Canonical choice: the designated command is `extract_command`'s pick, re-expressed on `method_spans` — the first runnable-class span — and every reader of "the command a row runs" takes it from there. Justification: documented rationale — D29 kept (R); INT-4 binds the probe step's pick to it. Out-of-scope drift: a whole-method bare verb with no backticks (the bare-string tail) is still taken as a command; 0 corpus rows have that shape, and (Z)'s zero-argument refusal, which would close it, was not chosen (D29).

**E2 — the not-run naming: "did not run (<reason>)" in an ordered command list (D29, D37).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the executor's not-executed renderings at the parent | `tool-invocation-outside-executor-allowlist:<verb> (not executed here; …)` · `<refusal> (not run — <remedy>)` | 2 families | the executor at `96ed0a10` |
| D37's partition wording | an unexecuted command is reported as "did not run (reason)" | 1 | the Collective Review record, D37 |
| reasons the corpus now reads | "names no input" 34 · "only the designated command runs" 112 · "outside the verb set" 0 (a stub) | 146 commands in 97 rows | the differential's observed texts |

Survey denominator: 97 multi-command rows (63 with two commands, 26 with three, 8 with four to six). Control: the fixture's AC-5 and AC-6 read "names no input", and AC-14 reads "outside the verb set" under G16's M5. Canonical choice: `partial-execution: limbs run 1 of <N>: limb <k> <verb> <verdict> <observed>; limb <j> <verb> did not run (<reason>) — a command that did not run is not a pass` on a slot row, and the same list without the head token on a FAIL or ERROR row; the reasons are the ones that are causal under (B). Justification: documented rationale — D29 kept (iii) and D37 set the wording; the design's `partial-execution:` head token (its canonicalization #2) is kept. Out-of-scope drift: none.

**E3 — the partial slot `VERDICT_PARTIAL_SLOT`, bound to SKIP until step 5 (D37).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| verdict constants at the parent | `readonly VERDICT_PASS/FAIL/SKIP/ERROR` | 4 | `grep -c '^readonly VERDICT_' release/tools/verify-release-plan.sh` at `96ed0a10` |
| the partition slot a partial row takes | can't-run-here, which D21's UNRUNNABLE carries from step 5 | 1 slot | D37; the partition ADR issue's Decision 7 |
| the exit predicate | FAIL or ERROR only | 1 site | `main()`, byte-unchanged |

Survey denominator: the executor's verdict constants and its one exit predicate. Control: G13-M1 (SKIP added to the exit predicate) still applies at exactly 1 site. Canonical choice: `readonly VERDICT_PARTIAL_SLOT="$VERDICT_SKIP"`, one line, with the suite deriving the value from it. Justification: documented rationale — D37: a partial row reads as UNRUNNABLE and carries no distinguishing field, and #6848 re-binds the line at step 5 (INT-4); the slot stays non-failing, so 0 plans change exit. Out-of-scope drift: none.

**E4 — the emphasis tolerance `CMP_EMPH_ALT` (D48).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| plan lines with a comparator whose N carries emphasis | `expect **N**`, `at least **N**`, and kin | 61 lines / 23 plans (49 in a table row or a CIAC entry) | a regex census of the 217 plans |
| records the tolerance moves | FAIL → PASS 2 (v4.04 CIAC-3, v4.57 CIAC-1) · PASS, observed now a count 18 (v4.60) · PASS → FAIL 1 (v4.60 `#5651` AC-1) | 21 records / 3 plans | the differential |
| the one fail-ward move | `grep -c 'co-deployed-lib' core/deploy/deploy.sh` — expect **10**; the file now carries 11 | 1 | the file reads 10 at the Stage-4 pin `0c759aaf` and 11 from `41b22d81`, a commit that landed between the pin and this branch's base |

Survey denominator: 217 plans. Control: the forms D48 leaves out stay unread — the fixture's AC-12 ("returns 0") reads FAIL `command-exit-1` under both executors, and `comparator_phrases` reads nothing from "returns 0 and = 2 and → 4" (G16's V6837-AC4 n). Canonical choice: `CMP_EMPH_ALT='\*\*|__|\*'`, one optional run between the comparator and N, in `extract_threshold` and `comparator_phrases` alike. Justification: documented rationale — D48 adopted the #7650 review's CD-2 and widened no further. Out-of-scope drift: the review measured 0 fail-ward moves at the Stage-4 pin; the one move here is a historical plan's pinned expectation meeting a file that grew after the pin, so v4.60 turns masked-failing, attributed to this step (D39). The 56 "= N" rows stay with the follow-up D48 routed.

**E5 — the suite group id `G16`.**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| group ids the suite uses at the parent | `G1` to `G15` | 15 ids; `G15` occurs 24 times | a token census of the suite at `96ed0a10` |
| `G16` in the suite at the parent | — | 0 | the same census |

Survey denominator: the suite's 2,833 lines at `96ed0a10`. Control: `G12` returns 205. Canonical choice: `G16`. Justification: documented rationale — the id free at the slice's parent commit, never hard-coded (the #7640 review's FM-1). Out-of-scope drift: none.

### Step 5 (#6848) — as landed

Commits: `c25471fa` (suite group G17 and its two fixtures, RED on the pre-fix executor) · `6083214b` (UNRUNNABLE, the tool catalog and its command-shape test, the residual step, the scope family and its guards, the slot re-bind, with the G13, G15 and G16 restatements and the first stage-04 paragraph) · `4183b220` (suite group G18 for #6893's round 2, with the G5 and G15 restatements, RED on the step's first executor) · `ed47d5f6` (round 2: the declared deploy route, D52's partial rule, the handlers' shell-operator refusal, and the second stage-04 paragraph) · `804434e5` (the partition ADR, Decision 7 appended to the D-6180 ADR, and the release ADR index) · `a57a341c` (the second stage-04 paragraph prescribes the runnable spelling) · the plan update that carries this section. Scope: D21–D24 with the #7643 review's CD-1, FM-1 and FM-3 and CD-2's minimum; INT-4; D37's partial-row reading; D38's shared predicate in the scope step and the handlers; #6837 R7's remainder; and #6893's round 2 by D50, with D51, D52 and D53.

- **UNRUNNABLE (D21).** `VERDICT_UNRUNNABLE` sits between SKIP and ERROR among the verdict constants. The markdown roll-up counts it (`… / N UNRUNNABLE / …`), the JSON roll-up carries `"unrunnable"` after `"skip"`, a stderr note names the count whenever a row reads it, and `emit_table`'s verdict column is ten characters wide. The exit predicate names FAIL and ERROR only and is byte-unchanged. `VERDICT_PARTIAL_SLOT` is re-bound to `$VERDICT_UNRUNNABLE` on its one line (INT-4). A later-contributor note sits in the version block; there is no second bump (D40).
- **The tool catalog and the command-shape test (D22, D24, the review's CD-1).** `span_invokes_tool` carries a closed catalog of 85 words (interpreters, shell keywords and builtins, and common tools) plus the script shape: a relative path, optionally `./`-prefixed, with no `..` segment and a script suffix, named by its basename. A span names a tool only when it is invocation-shaped — two or more tokens, a bare interpreter, or the whole method — and a shell keyword or builtin also needs an argument. `method_spans` computes the whole-method flag and passes it as a second argument (DEV-37). `extract_command`'s fallback returns only a span that invokes a tool, and a backticked identifier blocks the bare-string path; `looks_like_command`'s body is unchanged and its comment now says it recognises an identifier (#6837 R7's remainder). The three decline routes share `handle_unrunnable`, which keeps the reason token the SKIP carried, `tool-invocation-outside-executor-allowlist:<tool>`, so current readers still match.
- **The residual step (D24).** `classify_family` step 3: an unclassified row whose designated command leads with a word outside the verb set goes to the `unrunnable` family. A row with no such span still reaches the unclassified ERROR.
- **The scope family (D23, FM-1, CD-2).** Step 1b routes a designated `git diff --name-only <range> -- <pathspec>…` span that carries a comparator to `handle_scope`. The range is `origin/main` or a `<placeholder>` on each side of `..` or `...`. The pathspecs are data, matched in-process against the release diff that `fcm_resolve_diff` returns, unmodified and cached once per run. The guards run in order: the test seam aimed at a live plan reads ERROR `scope-fixture-mode-on-live-plan`; comparators that disagree, read through `limb_comparator` and `comparator_phrases`, read UNRUNNABLE `scope-comparator-ambiguous`; then `scope-pathspec-placeholder`, `scope-diff-unresolvable`, `scope-diff-empty`, and — for `==` and `<=` — `scope-pathspec-selects-nothing` for a pathspec that selects no existing and no changed path, each UNRUNNABLE. Otherwise the row reads PASS or FAIL `scope count=N (op want) over K changed path(s) in the release diff`. A scope row that names another command follows the partial rule through `command_list` (DEV-38). `span_shell_operator` is the one syntax test (D38), run with placeholders blanked.
- **Round 2 (D50–D53).** `is_deploy_check_invocation` accepts only the oracle's own spellings — `core/deploy/deploy.sh`, `./core/deploy/deploy.sh`, and the root shims `deploy.sh` and `./deploy.sh` — optionally after `bash`, with `--check` as the only argument and no shell operator. `declares_deploy_check` holds only when the designated command IS that invocation and the method carries it in backticks (D51). `classify_family`'s keyword block is split: the integration keyword first, then the declared route on one line (Site D; among declared rows the regression words select regression, else sync), then the per-issue and runtime-suite arms (FM-2). `usage()` Site B states the route; a no-bump note sits in the version block. `dispatch_check` passes the method to `handle_deploy_check`, which applies D52: an oracle PASS beside another command reads the slot, `partial-execution: limbs run 1 of <N>: …`, naming each other command "did not run (reason)"; an oracle FAIL stays FAIL and carries the same list.
- **The handlers' shell-operator refusal (D38, the D50 owner assignment).** In `handle_per_issue`, in `handle_integration`, and in `grade_limbs`' designated limb, a command that carries shell syntax outside quotes reads UNRUNNABLE `shell-operator:<op>`, rendered by `shell_operator_observed`: a pipe, a list or a redirect is named by its operator, and `$(` or a backtick as a command substitution.
- **Text.** stage-04 gains "What the plan verifier can execute" (the three shapes; the scope family grades the release diff, CD-2; and, from `ed47d5f6`, the shell-syntax sentence) and "The deploy check is reached by declaration" (FM-2's wording: the row's only command, the two precedences that pre-empt a declaration, the exit status covering the whole run, and warn-mode checks never failing it). The second paragraph first listed the root-shim spelling as a form to write, which the selftest-discovery gate's Arm F reports as an invocation the agent-side allowlist does not admit; `a57a341c` prescribes `bash core/deploy/deploy.sh --check` and states the other spellings in words (DEV-40). `usage()` gains the scope and unrunnable family lines, a VERDICTS block, round 2's Site B, and EXIT CODES 0 reading "PASS, SKIP and UNRUNNABLE only".
- **The ADRs.** The partition record (#7647) is written with Decisions 1–7 as the D-6848 gates rendered them with the review's fixes, D37's table, and #6837's Decision line, verbatim, as Decision 8. Its number came from `renumber-adr.py --detect` (the mainline anchor is 206, and this branch already holds 207), and in-release prose cites it by its slug token. Decision 7 is appended to the D-6180 ADR (#7641) and Decision 6's last bullet qualified; Decisions 1–5 are unchanged (INT-11). The ADR authoring guide closes an Accepted record's Consequences to in-place edits, so the per-decision consequence lines for Decisions 6 and 7 are carried in its `source_observations`, and the one line D53 rules into Consequences is added there (DEV-39). The release ADR index is regenerated.
- **Co-discharge (D50).** #6893's AC-2 limb "the deploy-check oracle grades only a row whose command is its invocation", its AC-3 limb "the deploy check is reached only by declaration", and its AC-4 prose-route revert are graded here, by G18's V6893-AC2, V6893-AC3 and V6893-AC4 arms (D45-a to D45-f, D52, M5 to M7 and M9) on this step's head.
- **Suite group `G17`.** The id free at this step's parent `3239907e`, where the suite uses G1 to G16. A header entry and 43 assertions:
  - G17-0: the denominator — the scope fixture declares and emits 13 rows, and the unrunnable fixture 10 rows and 4 CIACs;
  - V6848-AC1 a–i: a scope assertion dispatches and executes (an exclusion and a glob among the rows), its control reaches the changed paths, a violated assertion FAILs naming the path, forms outside the grammar never PASS, an empty diff is vacuous, the seam is refused on a live plan, a non-synthetic replay over one historical commit's four delivered paths (read UNRUNNABLE `scope-diff-unresolvable` in a stub or a shallow clone), the guards h1–h4, and a scope assertion beside a command that did not run reads the slot;
  - V6848-AC2 a–k: the residual step, every decline route, identifiers never named, prose around an identifier never run, a runnable probe still executes, the command-shape test over 19 identifiers and mentions, the counter, the exit and the stderr note, the two specificity arms (a mention-only span never reads UNRUNNABLE, and the residual step keys on the same test), and INT-4's grep beside awk in both orders and both loops;
  - V6848-AC3 armed red on the `RUNNABLE_VERBS` literal, and V6848-AC4, a clean exit on a plan whose scope rows hold;
  - seeded failures M1, M2, M3, M5, M6, M7, M8 (2 sites) and M9, each proved to apply at exactly its sites. The design's M4 — UNRUNNABLE added to the exit predicate — is #6236's AC4 M3, which step 1b left to step 10 because it needs this step's token; the property it guards is asserted here by V6848-AC2 h and V6848-AC4 (DEV-43).
- **Suite group `G18`.** The id free at `6083214b`, where the suite uses G1 to G17. A header entry and 31 assertions over a 21-row stub plan and a CIAC, in two stub roots (a deploy check that exits 0, and one that exits 1): G18-0, the denominator; D45-a over the four command-less rows; D45-bc over the tool rows, the near-miss (another file named `deploy.sh`) and a pipeline led by the invocation; D45-d, D45-e and D45-f (a declared row keeps the oracle in every spelling, a runnable probe still outranks it, an integration keyword still comes first); D52's PASS and FAIL; the refusal over a pipe, a redirect, a multi-command method and the cross-issue handler, with a quoted-operator control; and M5 to M9, each proved to apply at exactly its sites.
- **Restated in the same commits.** G13-M2 now covers three rows (AC-2's backticked `PORTFOLIO.md` is an identifier); G15 arm j and AC-18's Expected cell (the deploy span is named "did not run (outside the verb set)"); G16 j, m and M5 (M5 re-targeted to the catalog's function line); the multi-limb fixture's AC-14 Expected cell; G5's two rows backticked; G15's AC-7, AC-8, AC-10, M1 and M5 and V6893-AC3's message; and G17 M3's and G18 M6's detections (DEV-41). `classify_family`'s step-1 PRECEDENCE comment now says the deploy check is named as a command that did not run (DEV-36's hand-off).
- **RED, then GREEN, each predicted before its run.** Stub roots, each a `git archive` with logging `exit 97` delegation stubs: the parent `3239907e` gives 338 passed / 2 failed; RED 1 (`c25471fa`, G17 on the pre-fix executor) **342 / 33**; GREEN 1 (`6083214b`) **381 / 2**; RED 2 (`4183b220`, G18 on the step's first executor) **385 / 25**; GREEN 2 (`ed47d5f6`) first gave **411 / 4** against a prediction of 413 / 2 — the two stale detections of DEV-41 — and, re-predicted after restating them, **413 / 2** in a fresh stub. The 2 are P1 and M9's control, which need a repository. Every earlier outcome line keeps its outcome, apart from the restated arms. The stub logs stayed empty on every suite run. CI on the macOS smoke job (bash 3.2.57): `c25471fa` **346 passed, 31 failed**; `6083214b` **385 passed, 0 failed**; `4183b220` **389 passed, 23 failed**; `ed47d5f6` **417 passed, 0 failed**, ALL PASS. CI counts two assertions a stub does not reach, as at step 4, and passes P1 and M9's control.
- **The transit to step 6 (DP-5, INT-9).** On this head 8 released rows read an unclassified ERROR: the 7 command-less rows the D-6893b gate disclosed, and v4.44 `#5236` AC-1, whose `ls … | wc -l` names a command but no family. #6854's per-issue residual (D26) routes the 7 to the no-command SKIP and the eighth to a handler, whose shell-operator refusal reads it UNRUNNABLE: a what-if on this head that routes the unclassified fallback to per-issue reads it UNRUNNABLE `shell-operator:|`, and with the refusal also removed it reads FAIL `command-exit-1`. None of the 8 changes a plan's masked exit, because each plan already fails it (DEV-42).
- **Rule for later slices.** G17's mutations anchor on the residual step's test line `  if [ -n "$lead" ] && ! is_runnable_verb "$lead"; then echo "unrunnable"; return; fi` (M1), `handle_unrunnable`'s one-line printf (M2), `extract_command`'s `  if [ "$identifier" -eq 1 ]; then return; fi` (M3), `scope_path_selected`'s exclusion arm (M5), the `scope-diff-empty` printf (M6), `  cmpr="$(limb_comparator "$method")"` (M7), the placeholder arm and the selects-nothing test (M8, 2 sites), and `if ! scope_pathspec_selects "${s#+}" "$paths"; then` (M9). G18's anchor on Site D's one line (M5), `declares_deploy_check`'s last line (M6), `is_deploy_check_invocation`'s last line (M7), the two handlers' refusal line (M8) and `handle_deploy_check`'s `  if [ -n "$method" ] && [ "$n" -ge 2 ]; then` (M9). A slice that rewrites one of those lines updates G17 or G18 in the same commit. #6854's residual changes G18's D45-a rows from ERROR to the no-command SKIP; their arms grade "not the oracle's", so they stay green.

### Step 5 (#6848) — Evidence-Grounding (D42)

The canonicalizations D22–D24, D51–D53 and the handlers' refusal introduced, beyond the family values and reason tokens #6848's design grounded (its canonicalization #4) and the helper names round 2's design grounded. Every survey ran on 2026-09-25 over the release branch's 217 plans, through the step-4 and the step-5 executors side by side in one stub root.

**E1 — a tool is named only from an invocation-shaped span (D22, D24, CD-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the names the step-4 executor's refusals give | the method's first bare word | 102 identifier mentions, 92 distinct (file names, labels, function names, commit hashes) | a named-tool census of the 2,587 records |
| the names the step-5 executor gives, over the same records | catalog words · script basenames · identifiers | 19 · 19 · 0 distinct (237 · 31 · 0 mentions, on 263 records) | the same census |
| records carrying a one-token script span | named · unnamed (22 unclassified ERROR, 6 no-command SKIP) · graded otherwise | 26 · 28 · 24, of 78 | the script-name census |

Survey denominator: 2,587 records over 217 plans. Control: the step-4 executor over the same records names 102 identifier mentions, so the census discriminates. Canonical choice: `span_invokes_tool <span> [<whole>]` — a span names a tool when it has two or more tokens, is a bare interpreter, or is the whole method; a shell keyword or builtin needs an argument; the name is a catalog word or a script basename. Justification: documented rationale — D22 and D24 adopted the #7643 review's CD-1. Out-of-scope drift: a hand read classes 14 of the 28 unnamed one-token scripts as clear invocations, 11 as mentions and 3 as unclear — the review's estimate was about 17 — so they read as methods with no command; a catalog word used with an argument in prose is still named (the review measured 4 such patterns).

**E2 — the scope family's guard tokens (D23, FM-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the fcm-delivery family's reason vocabulary | `diff-unresolvable` · `fcm-fixture-mode-on-live-plan` · the `declared-add-*` tokens | kebab condition names | the executor at `3239907e` |
| the scope family's reasons | `scope-fixture-mode-on-live-plan` (ERROR) · `scope-comparator-ambiguous` · `scope-pathspec-placeholder` · `scope-diff-unresolvable` · `scope-diff-empty` · `scope-pathspec-selects-nothing` (each UNRUNNABLE) | 6 tokens | the executor at the head |
| plan rows that move into the scope family | — | 0 | the differential |

Survey denominator: the executor's reason tokens and the 217 plans. Control: the scope fixture's AC-9 to AC-13 each read their own guard's token (G17 h1–h4 and i, M8, M9). Canonical choice: `scope-` plus the fcm family's condition name where the condition is the same, and a condition phrase for each of the three new guards. Justification: documented rationale — the design's canonicalization #4, extended by the guards D23 adopted from the review's FM-1. Out-of-scope drift: none; no corpus row is a scope assertion.

**E3 — the declared deploy check's spellings (D51, D53 FM-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| designated invocations on the rows that keep the oracle | `bash core/deploy/deploy.sh --check` 13 · `core/deploy/deploy.sh --check` 3 · `./deploy.sh --check` 4 · `deploy.sh --check` 2 | 22 rows / 15 plans, all sync | the oracle census at the head |
| rows that reached the oracle at the parent | the same 22, plus 22 that designate no invocation | 44 rows / 25 plans (29 sync, 15 regression) | the same census at `3239907e` |
| another file named `deploy.sh` | a test fixture's own `deploy.sh` | 1 path | the tree |

Survey denominator: every record over the 217 plans. Control: a 26-case unit battery over `is_deploy_check_invocation` and `declares_deploy_check`, and G18's D45-bc near-miss arm. Canonical choice: an optional `bash`, then exactly one of the four spellings, then `--check` alone, no shell operator; the designated command must be that invocation and appear in backticks. Justification: documented rationale — D51 (exact and backticked) and D53 (FM-1's spellings). Out-of-scope drift: none; every kept row already uses one of the four. The authoring text prescribes the first spelling (DEV-40).

**E4 — the refusal's observed form `shell-operator:<op>` (D38, the D50 owner assignment).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the executor's refusal renderings at the parent | `stdin-reader:<verb>` · `device-operand:<input>` · `unmodelled-option:<…>`, each with `(not run — <remedy>)` | 3 families | the executor at `3239907e` |
| rows the refusal reads on this head | `shell-operator:\|` 5 · `shell-operator:;` 4 · `shell-operator:<` 3 | 12 rows / 11 plans | the differential |

Survey denominator: 468 changed plan records. Control: G18's quoted-operator control (a quoted operator character is literal, and its probe runs and PASSes). Canonical choice: `shell-operator:<op> (not run — …)`, the refusal renderer's shape with the operator `span_shell_operator` prints, and a command substitution named as such. Justification: documented rationale — D38's one predicate, applied in the handlers by the D50 owner assignment. Out-of-scope drift: the three `<` rows carry angle-bracket placeholders (`<both files>`, `<pr-body-file>`, `<extraction + attribution module source>`) that the shared predicate reads as a redirect, as step 3's E1 recorded; each read ERROR `matcher-exit-2` before, because the placeholder reached grep as file operands.

**E5 — the suite group ids `G17` and `G18`.**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| group ids the suite uses at `3239907e` | `G1` to `G16` | 16 ids; `G16` occurs 48 times | a token census of the suite |
| `G17` at `3239907e` · `G18` at `6083214b` | — | 0 · 0 | the same census |

Survey denominator: the suite's 3,091 lines at `3239907e` and 3,466 at `6083214b`. Control: `G12` returns 209 at both. Canonical choice: `G17`, then `G18`. Justification: documented rationale — the id free at each group's parent commit, never hard-coded (the #7640 review's FM-1). Out-of-scope drift: none.

### Step 6 (#6854) — as landed

Commits: `b42a9bfa` (suite group G19 and its fixture, RED on the pre-fix executor) · `8d76fa12` (the per-issue residual, the per-issue guard, the reader-semantics table, the roll-up over its true population with the `(plan)` header, `usage()`, the stage-04 paragraph, the stage-07 laundering-guard line, and the suite restatements) · `4918b280` (Decisions 9–11 in the partition ADR) · `8c7d9780` (`--help` names the `(plan)` group, the presenter defect's declared documentation) · the plan update that carries this section. Scope: D26 (B) with its DP-8 sign-off and stated residual; D27 (A)+(i) with the #7635 fix; D28 (A) with the #7648 review's FM-1; D38's per-issue guard (the #7665 review's CD-1, placed here by the hub's owner correction) and its reader-semantics table (the #7648 review's CD-1); D46's stage-07 line; D47's Decision lines; a later contributor to the bump (D40).

- **The residual (D26).** `classify_family` step 4 names `per-issue` instead of `unclassified`, on one line (G19 M1's anchor), so a row no step claims is inspected by the per-issue handler: a runnable command runs, a tool is declined by name, and a method with no command reads SKIP `no-executable-command-in-method`. `dispatch_check`'s fallback reads `unknown-family:<value> (internal inconsistency: …)`, because the residual always names a family. The runtime-suite doctrine comment and `usage()`'s CHECK FAMILIES line (", else the per-issue handler") say so. #6848's step 3 still precedes it (INT-3), so a recognised tool keeps the `unrunnable` family.
- **The per-issue guard (D38).** `per_issue_command` returns `extract_command`'s pick only when that pick is a backtick span of the method: a cell with no backtick, or a pick that carries one (the whole-cell fallback), names no command in the per-issue handler. It covers the rendered case, a method with no backticked span, and its one sibling, verb-initial prose beside a backticked path, which the handlers' shell-operator refusal otherwise read as a command substitution (DEV-46). `handle_integration` keeps the fallback a table-form CIAC cell needs, since `parse_ciac` strips that cell's backticks.
- **The reader-semantics table (D28, D38).** `reader_rule <verb> <column>` holds one row per allowlisted verb and four columns — what exit 1 means, the operand the command must name, how a count is read, and whether exit 0 with no comparator is the claim — and every reader asks it:
  - `count_from_output`: exit 1 is a zero only where the table reads `zero` (grep, test), else ERROR `matcher-exit-1` (G-1); status 5 reads ERROR `no-operand:<verb>`; wc's count is its first field on its last line; and `count_mode_cmd` finds a count mode only for the verb whose count column is its count flag, grep (DEV-49).
  - `eval_free_run` refuses a command that names no operand its verb needs (`names_no_operand`, status 5), after the stdin refusal: grep's pattern, read through the one grep option model (`reads_stdin_cmd` returns 2 when grep names none, DEV-45); test's expression and a unary primary's operand (operand-aware, the review's FM-1); ls's path.
  - `exit_zero_grades`: with no comparator, exit 0 is a PASS only for grep, test and an ls naming files or carrying `-d`; cat, head, wc and an ls listing a directory read ERROR `no-comparator:<verb>` (DEV-47), in the per-issue handler, the cross-issue handler and a designated command.
  - `unreadable_observed` renders `no-operand:` and `no-comparator:` with their remedies, and `usage()` gains READER SEMANTICS, with its VERDICTS SKIP and ERROR lines naming the new readings.
- **The roll-up (D27).** `rollup_counts` is the one reader for `emit_md`, `emit_json` and `main()`'s stderr note. The line is `P PASS / F FAIL / S SKIP / U UNRUNNABLE / E ERROR over R record(s) (N per-issue row(s), C cross-issue, A always-on) — not graded by this run: S SKIP (D declared-deferred, X no command in method, O other) and U UNRUNNABLE; could not evaluate: E ERROR`, with step 1's DEGRADED clause kept verbatim after it. The JSON roll-up gains `records`, `cross_issue_records`, `always_on_records`, `no_command` and `skip_other`, keeps step 1's `stream_state`, `records_parsed` and `records_read`, and `declared_deferred` counts the observed reason. The stderr note names the rows this run did not grade, with no command or UNRUNNABLE. The version block gains the later-contributor note, and the 3 → 4 note's false clause (the counters "computed over" the per-issue rows) is corrected; there is no second bump (D40), and CIAC-4 holds.
- **The `(plan)` header (#7635, D27).** `emit_md` keys a record with no issue value as `(plan)`, so it shares the bucket the parser already attributes to `(plan)`, and every counted record renders in a table (G19 M8's anchor). The JSON and table presenters and the stream are unchanged.
- **Text.** stage-04 gains "A method with nothing to run" after "What the plan verifier can execute" (the design's Change 4, with D28's reader rules and D38's guard). stage-07 gains the verdict-laundering guard beside Phase A's plan-verification paragraph (D46). The partition ADR gains Decisions 9–11 (D47), and its partition table's could-not-read examples name the reasons this release emits (DEV-50).
- **Suite group `G19`.** The id free at this step's parent `1d60350b`, where the suite uses G1 to G18. A header entry and 44 assertions over a 23-row, 2-CIAC fixture, `verify-plan-not-my-runner.md`:
  - G19-0: the denominator;
  - V6854-AC1 a–d: declared deferrals in both spellings; the residual's no-command SKIP; the CIAC's documented decision; the per-issue guard over three prose shapes;
  - V6854-AC2 a–c: a keyword-less probe executed; no unclassified terminus, and an internal-inconsistency fallback; every ERROR names why;
  - V6854-AC3 a–j: the broken-method controls; G-1; G-2 for grep, test and ls; the exit-0 rule for cat in three sites and for a directory listing; wc's first field; the controls where exit 0 is the claim; every cell of the table;
  - V6854-AC4 a–e: the exact roll-up line; the JSON identities; rendered rows = R with the `(plan)` header; a control with no unattributed record; the stderr note;
  - ten seeded failures — M1, M1b, M1c and M2 to M8 — each proved to apply at exactly its sites.
- **Restated in the same commits.** G8's unit block extracts `reader_rule` with the reader it feeds (DEV-49); G10's R-2 comment, R-3c message and D-2b anchor (`(4 per-issue row(s), `); G17 M1's detection, since without step 3 the awk row now falls to the residual and reads per-issue/UNRUNNABLE naming the tool (DEV-48); G18's header note on the released command-less rows.
- **RED, then GREEN, each predicted before its run.** Stub roots derived from a `git archive` of the parent, with logging `exit 97` delegation stubs; the suite ran by its repository-relative path from the stub's root. The parent `1d60350b` gives 413 passed / 2 failed. RED (`b42a9bfa`, G19 on the pre-fix executor): **423 / 27**, the new failures exactly the 25 predicted G19 arms. GREEN (`8d76fa12`): **457 / 2**. The 2 are P1 and M9's control, which need a repository. All 415 earlier outcome lines keep their outcome on both runs; on GREEN 12 change text only — the restated messages, and interpolated readings that now show the residual's SKIP, `no-operand:grep` or `matcher-exit-1`. The stub log stayed empty on every suite run.
- **V6854-AC2's a-limb, re-derived at the parent (INT-5; #6893's design R5).** At `1d60350b` the fixture's AC-6, a runnable probe no keyword claims, already reads per-issue/PASS through #6893's probe step. The limb is therefore GREEN at the parent and is armed red by mutation: with the probe step removed, the residual alone still executes it and the fixture's roll-up is unchanged (M1b); with both removed it reads unclassified/ERROR (M1c). The limb's RED at the pin (unclassified/ERROR) is not observable at this parent; V6854-AC2's RED claim rests on limb b (the classifier's unclassified terminus and the `unclassified-method` records, both present at the parent) and on M1c (DEV-44).
- **v4.20 `s3`, attributed (INT-5).** Pin: unclassified/ERROR. Step 3, #6893's probe step: per-issue/PASS `command-succeeded`, its content unchecked. This step, D28's exit-0 rule: per-issue/ERROR `no-comparator:cat`. Pin to head it reads ERROR → ERROR, the family moved by #6893 and the reason by #6854.
- **The transit from step 5 closes (INT-9).** The 7 command-less rows #6848's slice released read per-issue/SKIP `no-executable-command-in-method` on this head, and v4.44 `#5236` AC-1 reads per-issue/UNRUNNABLE, its command list naming `shell-operator:|` — DEV-42's what-if, now observed. G18's D45-a arms stay green.
- **PR-1 — the branch line and the Stage-7 predictions, re-derived at the parent.** Branch: D26 (B), D27 (A)+(i) with the `(plan)` header, D28 (A) with FM-1, D38's guard and table, D46's line. Measured over the branch's 217 plans by a record-stream differential of the parent's executor against this step's, in one stub root:
  - **The residual.** 429 rows in 53 plans at the parent read 428 SKIP `no-executable-command-in-method` (53 plans) and 1 UNRUNNABLE; 0 execute and 0 stay unclassified. Stage 5 predicted 407 SKIP in 50 plans on the rendered D22/D24 branch: all 407 are the pin's rows, in the same 50 plans, and read the SKIP. The other 21: 8 rows #7531's slice recovered (v3.65.1, v4.02, v4.0), 7 command-less rows #6848's round 2 released from the deploy oracle (INT-9), and 6 in v4.68, a plan merged after the pin; v3.65.1, v4.0 and v4.68 are the 3 extra plans. The eighth released row, v4.44 `#5236` AC-1, is the 1 UNRUNNABLE. Stage 5's "1 executed", v4.20 `s3`, left the residual at step 3.
  - **v4.48.** Its 38 pin-residual rows read 3 UNRUNNABLE (step 5) and 35 SKIP (this step), as Stage 5 predicted, and `#5058` AC-4, released at step 5, reads the SKIP too. Its line on this head: `4 PASS / 2 FAIL / 43 SKIP / 7 UNRUNNABLE / 2 ERROR over 58 record(s) (47 per-issue row(s), 6 cross-issue, 5 always-on) — not graded by this run: 43 SKIP (0 declared-deferred, 42 no command in method, 1 other) and 7 UNRUNNABLE; could not evaluate: 2 ERROR`; one of the 2 ERROR is the stub's FCM record.
  - **The masked exit (D39).** 34 plans stop failing: exactly the 27 Stage 5 named; 1 through the per-issue guard (v3.65, whose `#99` AC-3 was its other failing row); and 6 whose other pin-failing rows steps 4 and 5 cleared (v4.04, v4.18, v4.19, v4.29, v4.46, v4.64). 1 starts, v4.55, through the operand-aware G-2 on `#5653` AC1 — the tightening D28 accepted.
  - **The reader table.** 12 plan records move: 7 pattern-less greps change their reason from `matcher-exit-2` to `no-operand:grep` (ERROR both sides); v4.55 `#5653` AC1 goes PASS → ERROR, and v4.47 `#6230` AC-6 and `#5823` AC-5 go UNRUNNABLE → ERROR (`no-operand:test`); v3.65.1 AC-10 goes FAIL → ERROR (`matcher-exit-1`); and v4.20 `s3` goes PASS → ERROR (`no-comparator:cat`). Stage 5's "18 bare `grep` rows FAIL → ERROR" no longer arise, because step 4's bare-verb rule made those spans prose (DEV-45).
- **Rule for later slices.** G19's mutations anchor on the residual line `  echo "per-issue"   # residual: inspected by the per-issue handler, never guessed` (M1, M1c), on the probe-step line G15 M1 also anchors on (M1b, M1c), on `count_from_output`'s `printf 'ERROR\tmatcher-exit-%s'` (M2), on the exit-1 line `  if [ "$rc" -eq 1 ] && [ "$(reader_rule "$verb" exit1)" != zero ]; then …` (M3), on `  if names_no_operand "$cmd"; then return 5; fi` (M4), on `exit_zero_grades`' `  return 1   # no comparator: this exit 0 is not the claim` (M5), on the wc line `  if [ "$(reader_rule "$verb" count)" = first-field ]; then …` (M6), on `handle_per_issue`'s `cmd="$(per_issue_command "$method")"` (M7), and on `emit_md`'s `k = ($1 == "" ? "(plan)" : $1)` (M8). V6854-AC3 j pins every cell of `reader_rule`. A slice that rewrites one of those lines, or a table cell, updates G19 in the same commit. #6685's arms at step 7 read D26's residual and D28's operand refusal as they landed here (D31): an undeclared command-less row reads the no-command SKIP, and a padded `test -f` reads ERROR `no-operand:test`.

### Step 6 (#6854) — Evidence-Grounding (D42)

The canonicalizations D26–D28 and D38's two parts introduced, beyond the five the Stage-5 design grounded (the SKIP/ERROR boundary, the reused `no-executable-command-in-method` reason and `per-issue` family, the roll-up clauses and JSON keys, `no-operand:<verb>` with status 5 and `matcher-exit-1`, and the fixture name). Every survey ran on 2026-09-25 at `1d60350b`, this step's parent, or over its 217-plan corpus through the parent's and this step's executors side by side in one stub root.

**E1 — the dispatch fallback's reason `unknown-family:<value>` (D26).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| executor reason sites in the `<kebab-reason>:<subject>` grammar at the parent | `tool-invocation-outside-executor-allowlist:$tool`, `placeholder-unresolvable:$path` and kin | 15 sites | `grep -oE '[a-z]+(-[a-z]+)+:\$[{]?[a-zA-Z_]+'` over the executor |
| the fallback's reason at the parent | `unclassified-method (no family match)`, with no subject | 1 | `dispatch_check` |
| rows that reach the fallback on this head | — | 0 | the differential |

Survey denominator: 15 reason sites at the parent (19 on this head, the 4 new ones being `unknown-family:$family` and three `no-comparator:$verb`). Control: the survey returns `tool-invocation-outside-executor-allowlist:$tool`. Canonical choice: `unknown-family:<value> (internal inconsistency: the classifier returned a family no handler owns)`, the design's Change 1b text. Justification: documented rationale — D26 rendered (B), under which the residual always names a family, so the arm is a guard rather than a verdict a row can earn; the token follows the file's reason grammar and names its subject. Out-of-scope drift: none.

**E2 — the `(plan)` header for a record with no issue value (D27, #7635).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the parser's own attribution of an issue-less record | `(plan)` on the unindexable-table latch, the parity-error record and the empty-method record | 3 emit sites | `parse_verification_plan` |
| the completeness record | `(plan)` on the stream-truncated record | 1 | `main()` |
| records with no issue value at this parent | the empty string, shown by no table | 203 records in 22 plans | the parent's JSON records, read by line |

Survey denominator: 4 `(plan)` sites at the parent and every record over the 217 plans. Control: the parity-error fixture's record carries `(plan)`. Canonical choice: render the empty-issue bucket under the existing `(plan)` label, merged with the parser's `(plan)` records, in `emit_md` only. Justification: documented rationale — D27 folded the #7648 review's FM-2 into Change 1f, and the label is the one the parser already uses for a record no issue owns, so no new label is coined. Out-of-scope drift: why those rows carry no issue value upstream (a table with no Issue column above no issue header) is left as it is; #7635's upstream option was not rendered.

**E3 — the reason `no-comparator:<verb>` for a command whose exit status is not its claim (D28, FM-1).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the refusal and unreadable reasons at the parent | `stdin-reader:%s`, `device-operand:%s`, `count-unreadable:%s`, `shell-operator:%s` | 7 printf-format sites | `grep -oE '[a-z]+(-[a-z]+)+:%s'` over the executor |
| the review's offer for the rule | SKIP `no-comparator:<verb>` or ERROR, "CR chooses" | 1 | the #7648 review's FM-1 mitigation 2 |
| plan rows that reach it on this head | — | 1 (v4.20 `s3`) | the differential |

Survey denominator: 7 reason sites at the parent. Control: the survey returns `stdin-reader:%s` twice. Canonical choice: ERROR `no-comparator:<verb>`, rendered as "ran, but not graded — …" with its remedy. Justification: documented rationale — D28 required "a named non-PASS", and the partition (D37) places a row the executor tried to evaluate and could not in ERROR: the command ran, so the row is neither another runner's job nor a method with nothing to run (DEV-47). Out-of-scope drift: none.

**E4 — the reader-semantics table, `reader_rule`, and its column vocabulary (D38).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| readers of a command's result at the parent | `count_from_output`, and the no-comparator branch of `handle_per_issue`, `handle_integration` and `grade_limbs` | 4 sites, each with its own exit-status reading | the executor |
| per-verb closed lists at the parent | `RUNNABLE_VERBS`; the tool catalog's word lists; `reads_stdin_cmd`'s per-verb option `case` | 3 idioms | the executor |
| per-verb reader tables at the parent | — | 0 | the same |

Survey denominator: the executor's readers of a result and its closed-list idioms. Control: the survey finds `reads_stdin_cmd`'s per-verb `case`, the precedent for a per-verb table in a `case`. Canonical choice: one function, `reader_rule <verb> <column>`, with one row per allowlisted verb in a `case` and four columns — `exit1` (`zero` · `unreadable`), `operand` (`pattern` · `expression` · `path` · `file`), `count` (`count-flag` · `lines` · `first-field`) and `exit0` (`claim` · `existence` · `not-the-claim`) — read through `names_no_operand` and `exit_zero_grades`. Justification: documented rationale — D38 adopted the #7648 review's CD-1 ("one per-verb table") as the durable form of G-1, operand-aware G-2, the exit-0 rule and wc counting; a `case` needs no loop, so the FD-0 doctrine is untouched. Out-of-scope drift: none.

**E5 — the per-issue guard: only a backtick span is a command in the per-issue handler (D38).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| readers that already require a backticked span | the probe step's `runnable_probe_of`, the declared route's `declares_deploy_check` | 2 | the executor |
| `extract_command` call sites, the fallback's consumers | the classifier (twice), the probe and route readers, `method_limbs`, both handlers, `handle_unrunnable`, `handle_deploy_check`, the scope family | 9 | the executor |
| per-issue rows the fallback ran at the parent | verb-initial prose with no backtick | 1 (v3.65 `#99` AC-3); 0 beside a backticked path | the corpus scan below |

Survey denominator: 9 call sites, and the parent's per-issue records whose method opens with an allowlisted verb word (1 with no backtick, 0 with one). Control: the fixture's AC-18 to AC-20 are all three shapes and read ERROR, ERROR and UNRUNNABLE at the parent. Canonical choice: `per_issue_command`, which returns the pick only when it is a backtick span of the method. Justification: documented rationale — D38 adopted the #7665 review's CD-1, which applies D30's rule ("only a backticked span qualifies") to the handler; the hub's owner correction on #7834 placed it here. Out-of-scope drift: a table-form CIAC cell still takes the fallback in `handle_integration`, by design.

**E6 — the suite group id `G19`.**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| group ids the suite uses at the parent | `G1` to `G18` | 18 ids; `G18` occurs 27 times | a token census of the suite at `1d60350b` |
| `G19` at the parent | — | 0 | the same census |

Survey denominator: the suite's 3,704 lines at `1d60350b`. Control: `G12` returns 209. Canonical choice: `G19`. Justification: documented rationale — the id free at the slice's parent commit, never hard-coded (the #7640 review's FM-1). Out-of-scope drift: the suite's top header list carries no entry for `G18`; G18's own section header is in place. Routed to the hub.

### Step 7 (#6685) — as landed

Commits: `ae3ea050` (suite group G20, its two fixtures, and the header entries for G18 and G20) · `19bacff0` (Decision 12 in the partition ADR) · `b1bc0704` (the plan notes, evidence and Change Description row), then two corrections to this step's plan text: `ceb2017f` (DEV-53 and E3) and the commit that states why M2 and M5 apply at 0 sites before #6854's slice. Scope: D31 1(A) with the #7665 review's PR-1, FM-2, FM-3 and FM-4, FM-1 recorded, and the hub-routed O-2 and O-3; D32 2(A); D47's Decision line. **No executor byte changes:** `release/tools/verify-release-plan.sh` has the same blob at the parent `aa8cd0d3` and at this head, so no corpus record moves at this step.

- **The fixtures.** `verify-plan-documented-decision.md` is the design's Change 1: three per-issue rows under a synthetic issue — AC-1 and AC-2 in the declared-deferred form's two spellings, AC-3 an undeclared named read of a named surface — and a CIAC-1 whose method is a named read with nothing to run. Its intro adds O-2's sentence (CIAC-1 is undeclared on purpose, as the control for the integration family's own hatch) and states FM-1's constraint (no documented-decision row opens with an allowlisted verb word or carries a backticked span). `verify-plan-documented-decision-control.md` is Change 2: AC-1 and AC-2 carry an unterminated quote, on the keyword route and on the residual route, and AC-3 is the padding the card names, a backticked `test -f` with no operand. Its intro and its AC-1 and AC-2 Expected cells state what the head reads (DEV-53). Each fixture carries the issue-reference override on line 1, in the declared form; the override line adds no record.
- **What each limb reads on this head.** The declared rows read `deferred`/SKIP `declared-deferred` through step 0 (D17). The undeclared row reads `per-issue`/SKIP `no-executable-command-in-method` through the residual (D26), and the fixture exits 0. The three rows the card cites on v4.46 (`#3616` AC-3, `#3616` AC-4, `#2577` AC-6) read the same SKIP, and none names a word it only mentions (D22). The fixture's CIAC-1 and v4.46's own CIAC-1 read `integration`/SKIP `documented-decision-method (no runnable command)`, byte-identical (D32). The two unterminated-quote controls reach the per-issue handler and read UNRUNNABLE `shell-operator:"`, never a named SKIP and never a PASS (DEV-53); the padded row reads ERROR `no-operand:test` (D28), and the control exits 3.
- **Suite group `G20`.** The id free at this step's parent `aa8cd0d3`, where the suite uses G1 to G19. A header entry and 28 assertions (DEV-54), each message carrying its `V6685-AC<n>` label:
  - V6685-AC4 (2): both fixtures are in the corpus, and they parse as planted (3 + 3 per-issue rows and the main fixture's CIAC-1);
  - V6685-AC1 (7): the authoring arm (FM-1's constraint and INT-2's precondition, read against `RUNNABLE_VERBS`); the declared limb, AC-1 and AC-2; the undeclared limb and its exit 0; the non-synthetic replay of the three cited rows; the reader control;
  - V6685-AC2 (2): v4.46's CIAC-1 and the fixture's CIAC-1;
  - V6685-AC3 (4): control AC-1 on the keyword route and AC-2 on the residual route, each per-issue and ERROR or UNRUNNABLE; the padded row, ERROR `no-operand:test`; the control's exit 3;
  - seeded failures (13): M1 (step 0 removed), M2 (the residual reverted), FM-2's route precondition, M3 (a residual that makes every row it reaches a SKIP) with its keyword-route control, M4 (the integration hatch made an ERROR) and M5 (the operand rule's unary-primary arm removed), each proved to apply at exactly 1 site and each observed.
- **O-3 — the reader.** `g20_line` reads a record by its issue and its id together, from its own line, in either field order, and matches both as fixed strings, so the `CIAC (integration)` issue label is literal. v4.46 carries four AC ids under both of its issues, so an id-keyed reader cannot address its rows. The shared readers isolate a record with `[^{}]*` and read none whose text carries a brace; G11's `field_by_issue` keys on the issue alone and reads it as a pattern. The reader control proves the key: `#2577` AC-3, which shares its id with the cited `#3616` AC-3, reads its own record.
- **FM-2 — the route precondition.** Ahead of M3, the residual line is renamed to a sentinel family, `residual-route`, which no handler owns. The arm requires control AC-2 to carry that family and control AC-1 not to. When the route moves, the arm fails with a named re-authoring instruction ("re-author control AC-2 so that no step ahead of the residual claims it …") and M3 is not graded. INT-2 drops its clause about #6893's router and keeps what #6685 needs from #6893: step 0 reads the declared rows, which carry no command span.
- **FM-3.** The two "rationale travels" arms are not carried. The JSON presenter echoes the method on every record, so they passed on an ERROR row too; the declared-limb reading and M1 carry AC-1's declared property.
- **FM-1, re-measured at the parent.** The per-issue guard (D38, step 6) reads verb-initial prose as a named read. Four per-issue twins read `per-issue`/SKIP `no-executable-command-in-method`: "grep the merged ADR's Decision section …" (keyword-routed, with an apostrophe), the same without it, and the keyword-less "test …" and "head …" forms. So does the one corpus row, v3.65 `#99` AC-3. At the Stage-4 pin the four read ERROR `matcher-exit-3`, ERROR `matcher-exit-2` and two unclassified ERRORs; at `1d60350b` the apostrophe form read UNRUNNABLE `shell-operator:'`. The seven verb-initial cross-issue criteria the review counted still read ERROR (3) or UNRUNNABLE (4), because `handle_integration` keeps the bare-string reading a table-form criterion needs. That half is O-1, which lands with #6236's lint at step 10. The constraint is kept, and the authoring arm pins it.
- **M5, derived at the parent against D28's landed refusal line.** `s/(in -\[bcdefghkLnOGNprsStuwxz\]\)) return 0 ;; esac$/\1 : ;; esac/` turns off only the operand rule's unary-primary arm in `names_no_operand`: `test` with no expression is still refused. With it, the padded method reads PASS `command-succeeded` and the control exits 0.
- **The header list.** It gains G18's entry, which step 6 recorded as missing, beside G20's (DEV-55).
- **RED, then GREEN, each predicted before its run.** Stub roots, each a `git archive` of `aa8cd0d3` with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line, the original text kept. The parent gives 457 passed / 2 failed. GREEN (this slice's suite and fixtures): **485 / 2**, G20 28 of 28, and all 459 earlier outcome lines identical. The slice changes no executor byte, so its RED is observed two ways:
  - **The co-discharge RED.** G20 alone, in a trimmed harness built from the suite's own lines, reads **19 / 7** on the executor before #6854's slice (`1d60350b`). The 7 are exactly the arms graded on #6854's rules: the undeclared limb, its exit 0, the three-row replay, control AC-2's route, the padded row, and M2 and M5, which apply at 0 sites there (the residual line already reads `unclassified`, and the unary-primary arm does not exist). It reads 19 / 7 with the same 7 on the Stage-4 pin executor too, where control AC-1 reads ERROR `matcher-exit-3` as the design's P7 measured. The same harness on this head's executor reads 28 / 0.
  - **Armed red, then reverted.** Each of M1 to M5 is proved to take and is detected in the GREEN run.

  The 2 are P1 and M9's control, which need a repository. The stub logs stayed empty on every suite and harness run.
- **INT-7 (vs #6893).** G15 reads 30 of 30 and G18 31 of 31 on this head. G19 reads 44 of 44, and V6236-AC4 13 of 13: the exit predicate and both `is_runnable_verb` checks are untouched, so G13-M's anchors hold.
- **Rule for later slices.** G20's mutations anchor on step 0's `      echo "deferred"; return ;;` (M1), on `classify_family`'s one two-space `echo` line, the residual, which M2, M3 and the route sentinel rewrite through an edit scoped to the function, on `handle_integration`'s `"$VERDICT_SKIP" "documented-decision-method (no runnable command)"` (M4), and on `names_no_operand`'s `in -[bcdefghkLnOGNprsStuwxz]) return 0 ;; esac` (M5). A slice that rewrites one of those lines updates G20 in the same commit. The replay reads v4.46 by path and first requires the four entries it cites.

### Step 7 (#6685) — Evidence-Grounding (D42)

The canonicalizations D31 and D32 introduced, beyond the two the Stage-5 design grounded (the named SKIP by route, its canonicalization #1; the fixture names, synthetic ids, labels and group id, its #2). Every survey ran on 2026-09-25 at `aa8cd0d3`, this step's parent, or over the executors at `aa8cd0d3`, `1d60350b` and the Stage-4 pin in stub roots.

**E1 — the suite group id `G20`.**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| group ids the suite uses at the parent | `G1` to `G19` | 19 ids; `G19` occurs 97 times | a token census of the suite at `aa8cd0d3` |
| `G20` at the parent | — | 0 | the same census |

Survey denominator: the suite's 4,009 lines at `aa8cd0d3`. Control: `G12` returns 209. Canonical choice: `G20`. Justification: documented rationale — the id free at the slice's parent commit, never hard-coded (the #7640 review's FM-1; the design's canonicalization #2). Out-of-scope drift: none.

**E2 — the issue-qualified, order-tolerant record reader `g20_line` (O-3).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the suite's record readers at the parent | id-keyed with `[^{}]*` isolation (`verdict_of`, `family_of`, `observed_of`, `field_by_id`) · id-keyed by line (`g13_verdict`, `g13_observed`, `g17_family`) · issue-keyed alone, read as a pattern (`field_by_issue`) | 8 readers | the suite at `aa8cd0d3` |
| the design's reader | keyed on the adjacency of `issue` and `id` | 1 (`g6685_obj`) | the #7602 design's Change 3 |
| AC ids the replayed plan carries under both of its issues | `AC-1` to `AC-4` | 4 of 15 ids, 19 records | v4.46 on the head executor, read by line |

Survey denominator: 8 suite readers and v4.46's 19 records. Control: the reader control arm, `#2577` AC-3 read by issue and id, returns its own PASS record, where an id-keyed reader returns the cited `#3616` AC-3. Canonical choice: one group-local reader, `g20_line <json> <issue> <id>`, keyed on both fields, read from the record's own line in either field order, matching both as fixed strings. Justification: documented rationale — the #7665 review's O-3, adopted with D31, and the suite's line-read precedent (DEV-26). Out-of-scope drift: `field_by_issue` reads an issue label as a pattern, which its own comment records for the `(plan)` label; left as it is.

**E3 — the malformed-method control reads "never a named SKIP and never a PASS" (DEV-53).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| the partition (Decision 7 of the partition ADR, #7647) | could not read → ERROR; can't run here → UNRUNNABLE, `shell-operator:<op>` among its reasons | 2 outcomes | the ADR's partition table |
| the control rows AC-1 / AC-2 / AC-3 by executor | pin: ERROR / unclassified ERROR / PASS · `1d60350b`: UNRUNNABLE / unclassified ERROR / PASS · head: UNRUNNABLE / UNRUNNABLE / ERROR `no-operand:test` | 3 executors | the harness runs |
| the suite's precedent for a verdict a later slice may rename | G13 grades "neither FAIL nor ERROR", never "= SKIP" | 1 group | G13 at `aa8cd0d3` |

Survey denominator: the control's 3 rows over 3 executors. Control: M3 turns control AC-2 into a SKIP, and the arm moves. Canonical choice: control AC-1 and AC-2 must be per-issue and ERROR or UNRUNNABLE; the padded row must be ERROR `no-operand:test`. Justification: documented rationale — the card's AC-3 names what the control is for ("so the fix cannot be satisfied by making everything SKIP"), D31 grades it "on both malformed-method routes", and the partition (D37, with D38's refusal, landed at step 5) places an unterminated quote in the can't-run outcome. Out-of-scope drift: a single malformed command reads ERROR only on the probe route on this head (DEV-53). A command in an unclosed backtick span is not claimed by the probe step, which requires a closed span, yet `per_issue_command` runs it, so the probe step and the per-issue guard read "a backticked span" two ways; measured on a scratch plan (an unclosed `head` on a missing file reads ERROR `matcher-exit-1` through the residual), and routed to the hub.

**E4 — the route sentinel `residual-route` (FM-2).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| mutations of the classifier residual in the suite at the parent | reverted to `unclassified` (G19 M1, M1c) | 2 | the suite at `aa8cd0d3` |
| the executor's guard for a family no handler owns | ERROR `unknown-family:<value>` | 1 site | `dispatch_check` |
| `residual-route` in the executor and the suite at the parent | — | 0 and 0 | a token census |

Survey denominator: the classifier's family values and the suite's residual mutations. Control: under the sentinel, control AC-2 and the main fixture's AC-3 carry the sentinel family, and control AC-1 and AC-3 keep `per-issue`. Canonical choice: a sentinel family no handler owns, written on the residual line by the same function-scoped edit M2 and M3 use. The row the residual reaches carries that family, and dispatch's guard reads it ERROR, which the precondition does not grade. Justification: documented rationale — the #7665 review's FM-2 mitigation 1 ("the classifier with its residual line replaced by a sentinel, which M3 already edits"), adopted with D31. Out-of-scope drift: none.

### Step 8 (#6876) — as landed

Commits: `efacc6ac` (8a: the map, the three stage specs and the install-tests comment) · `ea83ed39` (8b: the connector's self-test, the exclusions line, and the package with its `.sha256`) · `fc6a3af8` (the ADR file for #7672 and the regenerated release ADR index) · the plan update that carries this section. Scope: D33 (A) with the Phase A6.5 review's FM-1 to FM-5 and PR-2, R2 and R3 as Tier-2 rows; D34 (i); the Collective Review's D37 reading table and D43 coupling. The review's PR-1 and CD-1 are not taken (D33, D34). **No executor, suite or fixture byte changes:** the executor's blob is `f8a4c25d` and the suite's `840e6c2d` at the parent `ab5152a0` and at this head, so no corpus record moves at this step.

- **8a — the map (Changes 1a–1e, with FM-1, FM-2, PR-2, D37 and D43).** § 2 opens with three rules: the glob grammar; the reference resolver, git's pathspec with `top` and `glob` over the `--no-renames` change set, with the three non-conformant matchers in a table; and longest-literal-prefix precedence. A **Runner input** paragraph states once that every selected runner runs with stdin on the null device (FM-1 mitigation 1), and the rows 6 and 7 runner forms carry `</dev/null`. Row 5 gains `core/config/*.template` (FM-2). Row 6 carries the four `TEST_SUITE_GLOBS` patterns verbatim and its Notes name that constant (D43, and the review's text note), with the depth bound and the review's per-suite wording for the fixture relation. Row 7 runs `--self-test` only on a script ADR-119's advertise predicate accepts, and names any other matched script a map gap (FM-1 mitigation 3). Rows 6 and 7 share a Sandbox cell that is a membership rule, and the per-member parentheticals the review found false are gone (FM-1 mitigation 4). The fallback is row 8, with the design's note. A **Per-path runners** paragraph after the table states the per-path guarantees, including `test-run/suite-skip` with `reason:matched-path-deleted` for a matched path the change deletes (FM-1 mitigation 2). § 4 cites the fallback by role, gains a row for a matched path that runs no suite, and gains a **Reads as** column carrying D37's reading table (DEV-57). The Tier-A marker sits below the H1 (Change 1e). The frontmatter `purpose:` keeps "most-specific glob wins", as the design's cascade sweep preserved it: the precedence rule is what defines most-specific.
- **PR-2 — the chosen form: the grammar forbids, rather than adopts.** A leading `**`, and a `**` that shares its segment with another character, are never written in the *Changed-path glob* column. The adopting form was measured and not chosen: git also resolves an in-segment `**` by its position, which its documentation calls invalid, so adopting the leading-`**/` rule alone would still leave git and a conformant matcher reading those placements differently. A wildcard-free directory name selects every path below it under git, and the grammar states that reading, so git conforms on every pattern the column admits (DEV-56; Step 8 Evidence-Grounding E1). DP-9's line reads "aligned on framing; conformance is established at each verification by the resolver run", which is how this step's resolver runs establish it.
- **8a — the consumers (Changes 2–4, D34).** stage-06 C4 and stage-07 A8 read "(any row but its last; the last row is the explicit no-match fallback)". stage-08 cites "the map's no-match row" in its runtime-evidence table, its two worked examples and its doc-release paragraph, and its Case A selection sentence drops the stale row-4 description. CIAC-5's literal occurs exactly once in stage-07.
- **FM-5 — the install-tests comment.** The Check 16 suite's placement comment records reason 1, governed routing, as retired, in the comment's own retired-reason form: the map's row 6 now claims that suite. The comment's opening now reads one reason standing, reason 2, and two retired.
- **8b — the connector (Change 5, FM-4), under the skill-editor discipline.** A pmo-skill-editor Mode A session made the edit. Its materiality call: not material to the skill. The SKILL.md's triggers, modes, process steps, failure modes, output contract and cross-references are unchanged, so its `version:` is unchanged; the SKILL.md is byte-unchanged, so the editor-trailer check does not apply. Its impact analysis: the skill registry gives `finops-usage-extractor` no inbound `DEPENDS_ON` edge, and the connector's contract readers — the skill's purpose line, the store schema's reserved `provider` record and the estimator's comment — each stay true, because `--self-test` emits no record and the default and enabled paths are unchanged. `--self-test` runs five cases, each in a child shell with stdin on the null device and the key blanked, or replaced by a sentinel on the enabled case, so a real key in the caller's environment is never used (DEV-58). The usage and exit-code lines name the mode, and the "When implemented it MUST" list gains FM-4's rule.
- **8b — the exclusions line (Change 6) and the package (Change 7, R2).** Once the connector advertises `--self-test`, Arm C reports it uncovered until the exclusions line names it. The package is rebuilt from the final connector bytes, and exactly one of its members changes, the connector. The deploy manifest already carried the skill (§ Operational Deployment Manifest rows 1 and 2, written at Commit 0), so R2's manifest half needed no edit.
- **The ADR (#7672).** Decisions 1–5 as the ADR issue states them, with PR-2's form in Decision 1 and D43's coupling in Decision 3; D37's reading is Decision 6 (DEV-59). `renumber-adr.py --detect` read `ANCHOR 206 · NEXT-FREE 207 · CLAIMED-SET-BRANCH-ONLY 207,208`, the last being this branch's two records, and the file took the next number contiguous within the branch, by the plan's ADR-number rule. Every issue reference sits in its `## References` block, and in-release citations use slug tokens.
- **What the new rows select from earlier steps.** Under the map as this step leaves it, `release/tools/tests/test_verify_release_plan.sh`, which steps 1 to 7 changed, selects row 6, whose runner is the suite's bare invocation; the fixtures under `release/tools/tests/fixtures/` are `.md` files and select no row; `release/tools/verify-release-plan.sh` keeps row 4. The earlier steps' runtime evidence for the suite is their explicit suite runs, which this step's run reproduces.
- **The regions this step edited in stage-07 and stage-08, for #7494's line-disjoint edits.** stage-07: the row citation in the A8 opening sentence only. stage-08: the SKIP row of the runtime-evidence table; Case A's Step 1; Case B's Step 1; and the doc-release no-op paragraph's first numbered clause.
- **Rule for later slices.** CIAC-5 counts exactly one occurrence of "the last row is the explicit no-match fallback" in stage-07, so a slice that edits stage-07 must not add a second. Row 6's patterns are Arm D's `TEST_SUITE_GLOBS` verbatim: a change to either is a decision on both (D43).

### Step 8 (#6876) — Evidence-Grounding (D42)

The canonicalizations D33 and D34 introduced, beyond the five the Stage-5 design grounded (the grammar and reference resolver, longest-literal-prefix precedence, the depth bound, the fallback by role, and the row-7 flag), and the two reason tokens FM-1's mitigations required. Every survey ran on 2026-09-25 at `ab5152a0`, this step's parent, or on the map as landed.

**E1 — where `**` may stand, and the wildcard-free reading (PR-2, D33).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| git's glob pathspec rules | a leading `**/` matches in every directory; `/**/` matches zero or more directories; a trailing `/**` matches everything below; any other placement is documented invalid | 4 placements | gitglossary's `glob` magic |
| an in-segment `**` under git | resolved by position: `release/tools**` selects 159 tracked paths and `release/tools*` 0; `release/tools/tests/**.sh` selects 14, the same as `release/tools/tests/*.sh` | 3 patterns | `git diff --name-only --no-renames <empty tree> HEAD -- ':(top,glob)<pattern>'` |
| a wildcard-free directory under git | `core/deploy` selects the same 201 paths as `core/deploy/**` | 1 pattern | the same command |
| the map's patterns as landed | `**` only as a trailing `/**` | 4 of 20 patterns | the map's § 2 table |

Survey denominator: the map's 20 patterns and the 2,087 tracked paths. Control: `core/*/tools`, a wildcard pattern that names a directory, selects 0, so git extends only a wildcard-free name to the paths below it. Canonical choice: `**` only as a whole segment; a leading or in-segment `**` never written; a wildcard-free directory name covering every path below it. Justification: documented rationale — D33 adopted PR-2 and left the form to Stage 6, "the form that keeps the reference resolver conformant"; the forbidding form is the one under which git conforms on every admitted pattern. Out-of-scope drift: git's glob also reads a backslash as an escape; no tracked path carries one, and the grammar is silent on it.

**E2 — the fallback cited by role (D34).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| live citations of the fallback at the parent | by number: "(rows 1–5; row 6 is …)" in stage-06 and stage-07, "no-match row 6", "row 6 (no match)" and "(row 6)" in stage-08, "(row 6)" in the map's § 4 | 6 lines in 4 files | a case-insensitive sweep for `row[ -]6`, `rows 1[–-]5`, `top-to-bottom` and `most-specific` over the map and the three specs |
| the same four files on this head | by role only | 0 by number | the same sweep |
| historical records | "row 6" for the fallback | ADR-074; the merged v3.68, v4.46, v4.52 and v4.56 plans; this plan's step-1b and step-7 evidence rows | a tree-wide sweep for `row[ -]6` beside no-match wording |

Survey denominator: 10 lines in the map and the three specs matched the sweep at the parent. Control: the same sweep on this head returns 1 line, the preserved frontmatter `purpose:`. Canonical choice: "the last row is the explicit no-match fallback", and "the map's no-match row" in prose. Justification: documented rationale — D34 (i), the design's canonicalization #4. Out-of-scope drift: the historical records keep "row 6", which D34 names historical record; the fallback's event payload stays `selected-by:no-match`.

**E3 — the reason tokens `reason:matched-path-deleted` and `reason:map-gap-no-self-test` (FM-1 mitigations 2 and 3).**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| `reason:` tokens across `core/`, `release/`, `docs/` and `.github/` | kebab-case causes: `runner-error` (5), `doc-only-change` (1), and 12 others outside `test-run` | 14 distinct | `git grep -h -o -E "reason:[a-z][a-z0-9-]*"` |
| the event writer | no validation of `test-run` payload keys | — | `release/tools/append-pipeline-event.sh` |
| FM-1's own wording | "a named reason"; "a named map gap" | 2 | the #7669 review's FM-1 |

Survey denominator: the 14 distinct `reason:` tokens. Control: the survey returns `reason:runner-error` 5 times. Canonical choice: `reason:matched-path-deleted` and `reason:map-gap-no-self-test`, in the corpus's kebab-case reason grammar, each naming its cause. Justification: documented rationale — D33 adopted FM-1's mitigations 2 and 3, which require a named reason and a named map gap and name no token. Out-of-scope drift: none.

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
# #6180 — the D-6180 ADR, issue #7641 (D17; Decision 6 appended by the #6893 slice, D30; Decision 7 appended by the #6848 slice, D50); was token D6180-ADR
release/ADRs/ADR-NNN-a-rows-grading-route-is-declared-in-its-method-cell.md  ADD
# #6848 — the release partition ADR, issue #7647 (D21 to D24, D37, D47; it carries #6837's Decision line, and #6854's, #6685's and #6236's join from their slices); was token VERDICT-ENUM-CHANGE
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
| `classify_family` | #6180, #6893, #6848 (+#6854/#6685 under remove) · #6848 also carries round 2's split keyword block and the one-line declared route (Site D, D50) and the scope step 1b | Stage 4; step 5 |
| parse awk record | #6180, #6893, #6837 (remove) | Stage 4 |
| dispatch loop `:2476` | #6180, #6893 | Stage 4 |
| `extract_command` / `handle_per_issue` | #6837, #6848 · #7531 (the non-OK render call only, FM-1; DEV-25) · #6893 (the deferral guard's subject only, FM-2; DEV-29) · #6854 (`handle_per_issue`'s command through the per-issue guard, D38, and its no-comparator reading, D28; DEV-52) | Stage 4; step 1; step 3; step 6 |
| `handle_integration` | #6848, #6236 · #7531 (the non-OK render call only, FM-1; DEV-25) · #6893 (the deferral guard's subject only, FM-2; DEV-29) · #6854 (the no-comparator reading only, D28; DEV-52) | Stage 4; step 1; step 3; step 6 |
| the probe helpers (`span_shell_operator`, `is_runnable_probe`, `runnable_probe_of`, `method_outside_verb_spans`) — new at step 3, after `extract_command` | #6893 · #6848 (its scope step and the handlers' shell-operator refusal call `span_shell_operator`, D38, D50) · #6236 (its CIAC lint calls it, D38) · #6837 (INT-4: `runnable_probe_of`'s pick stays `extract_command`'s designated span) · #6854 (`is_runnable_probe`'s comment names the operand and exit gates its slice added; DEV-52) | step 3; step 6 |
| `dispatch_check` | #6848, #6854 · #6848 passes the method to `handle_deploy_check` (D52) | Stage 4; step 5 |
| `emit_md` / `emit_json` roll-up | #6854, #6848 · #7531 (D19's DEGRADED clause) | Stage 4; #6854 R10 |
| header `SCHEMA_VERSION` | **#7531 carries the one 4 → 5 bump**; #6848 and #6854 record themselves as later contributors; #6180 owes none | Stage 4, restated by D40 |
| `usage` | #6180, #6893, #6848, #7531 (AC-3, co-discharged; and the EXIT CODES line for D19, landed at step 1), #6837 · #6848 also carries round 2's Site B (D50) · #6854 (the residual in CHECK FAMILIES, the VERDICTS SKIP and ERROR lines, READER SEMANTICS) | Stage 4; delta; #6837 R6; step 1; step 5; step 6 |
| `eval_free_run` `:911–934` | #7531 (isolation) · #6837 AC-4 · #6848 · #6854 (reader exit and operand rules) | delta; #6854 R10 |
| per-issue dispatch loop `:2466–2483` | #7531 · #6180, #6893 (call site `:2476` inside the body) | delta |
| CIAC dispatch loop `:2488–2503` | #7531 · #6848, #6236 | delta |
| children on the dispatch path `:1081`, `:1177` | #7531 · #6848 (a fixed `git` child) | delta |
| `RUNNABLE_VERBS` `:717` | NOT CHANGED (#6848 AC-3 asserts the literal) | delta |
| `count_from_output` | #7531, #6854, #6848 · #6854 also makes `count_mode_cmd` read the table's count column (DEV-49) | #7531 R5; #6854 R10; step 6 |
| the version-metadata block | #7531, #6180, #6848, #6854 · #6893 (a no-bump note, DEV-29) · #6837 (a no-bump note, DEV-32) · #6848 (the later-contributor note, and round 2's no-bump note, D50) | #7531 R5; #6854 R10; step 3; step 4; step 5 |
| the FD-0 doctrine block | #7531 · #6837 (the list of loops that take the body form, DEV-32) | #7531 R5; step 4 |
| the verdict constants — `VERDICT_PARTIAL_SLOT`, new at step 4 | #6837 · #6848 (adds `VERDICT_UNRUNNABLE` and re-binds the slot at step 5, D37, INT-4) | step 4 |
| the multi-command helpers (`span_invokes_tool`, `method_spans`, `comparator_phrases`, `limb_comparator`, `method_limbs`, `limbs_are_multi`, `grade_limbs`) — new at step 4, after `compare_threshold` | #6837 · #6848 (replaces `span_invokes_tool`'s body with its tool catalog, D22; D52's partial rule reads `method_spans` in `handle_deploy_check`) · #6236 (its CIAC lint calls `method_spans` and `comparator_phrases`) · #6854 (`grade_limbs`' designated command reads the no-comparator rule, D28; DEV-52) | step 4; step 6 |
| the refusal model (`stdin_input_refusal`, `reads_stdin_cmd`) and the renderer (`unreadable_observed`) — new at step 1 | #7531 · #6854 (its reader exit and operand rules sit beside them; `reads_stdin_cmd` returns 2 when grep names no pattern, DEV-45; the renderer gains `no-operand:` and `no-comparator:`) | step 1; step 6 |
| the reader-semantics table and its readers (`reader_rule`, `names_no_operand`, `exit_zero_grades`) — new at step 6, after `reads_stdin_cmd` | #6854 (D28, D38) | step 6 |
| `per_issue_command` — new at step 6, before `handle_per_issue` | #6854 (the per-issue guard, D38) | step 6 |
| `rollup_counts` — new at step 6, before `emit_md` | #6854 (D27) | step 6 |
| the `main()` exit block | #7531 (the EXIT_INTERNAL branch for a DEGRADED stream, D19; DEV-25) | step 1 |
| `extract_command` / `extract_threshold` | #6837 (consumed by #6848 and #6236) | #6837 R6 |
| the hook after each DEFERRED arm | #6837 | #6837 R6 |
| the suite loader `:290–295` | #6837 | #6837 R6 |
| `usage()` VERDICTS and the `main()` note | #6848, #6854 | #6854 R10 |
| the declared-route helpers (`is_deploy_check_invocation`, `declares_deploy_check`) — new at step 5, after `runnable_probe_of` | #6848 (round 2, D50, D51, D53) | step 5 |
| `handle_deploy_check` | #6848 (D52's partial rule, through `command_list`) | step 5 |
| the decline and naming helpers (`handle_unrunnable`, `command_list`, `shell_operator_observed`) — new at step 5 | #6848 | step 5 |
| the scope family (`scope_spec_of`, `scope_pattern_matches`, `scope_path_selected`, `scope_pathspec_selects`, `scope_delivered_set`, `handle_scope`) — new at step 5, after `handle_fcm_delivery` | #6848 (#6257, outside the milestone, reaches it through `fcm_resolve_diff`; see the siblings table) | step 5 |

The Stage-4 cells conditioned on D-6180 resolve under D17 (remove): #6854's residual changes the classifier's terminus (D26), and #6685 edits no executor line (D31). The #6893 overlap is region adjacency, not a shared line, and serial order resolves every overlap above: no scope split is needed.

**Other shared files:**
- The **test suite** takes arms from **8** cards (#7531, #6236, #6180, #6893, #6837, #6848, #6854, #6685).
- **`stage-04`:** #6180, #6837, #6236, **#7494** (D35, R5: Limb 1, anchored by text after #6180's and #6837's edits to the same bullet list); the Stage-4 "#6848 conditional" resolved as fired — #6848 added "What the plan verifier can execute" and, carrying #6893's round 2 (D50), "The deploy check is reached by declaration" after the method-class table; #6854's design adds one paragraph after the first.
- **`stage-07`:** #6876 (row citations by role), #7494 (the AC-map columns and the Phase-B sentence), #6854 (the laundering-guard line, D46). **`stage-08`:** #6876, #7494 (the criterion-namespace section after `:38`). #6876 lands first and #7494's edits are line-disjoint; #7494 does not introduce the literal CIAC-5 counts.
- **`stage-06`:** #6876 (MAP-RENUMBER fired).
- **The ADR files.** The D-6180 ADR: #6180 (the file), #6893 (Decision 6, D30), #6848 (Decision 7, D50). The partition ADR: #6848 (the file, with #6837's Decision line), then #6854, #6685 and #6236, each adding its Decision lines (D47).
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
- #6837's criteria, as D29 renders them (graded at Stage 8 Phase B): **INT-1 (vs #7531)** — every limb that runs goes through the stdin-isolated dispatch: only the designated command runs, through #7531's `eval_free_run` inside the null-fd-0 dispatch body, so an operand-less further command truncates no later row (G16's V7531-CIAC6 a–c and M3); (A)'s half, a declared further command run and refused, is not built. **INT-2 (vs #6180)** — #6837 leaves `classify_family` and the D17 method-cell declaration untouched, and its hook sits after the declared-deferral guard, so a declared-deferred method reads SKIP before any command is read; AC-4 covers a method that reaches the per-issue or cross-issue handler whole (the #7650 review's FM-4); #6837 AC-1 and AC-2 grade on V6180-AC5b and V6837-AC2 (D41).
- #6685's criteria, as D31 renders them with the #7665 review's fixes (graded at Stage 8 Phase B):
  - **INT-1 (vs #6180).** On #6685's head the fixture's declared rows read `deferred`/SKIP `declared-deferred` through step 0, with the classifier taking the method as its only argument. V6180-AC5a and V6180-AC5b stay green.
  - **INT-2 (vs #6893), restated by FM-2.** Step 0 reads the declared rows, which carry no command span. The clause about #6893's router is dropped: G20's route precondition observes, on the head, that control AC-2 reaches the residual, rather than asserting a property of a sibling's predicate.
  - **INT-3 (vs #6854), restated at step 7 (DEV-53).** Fixture AC-3 and the three v4.46 rows the card cites read `per-issue`/SKIP `no-executable-command-in-method` (D26). Both unterminated-quote controls reach the per-issue handler and read neither a named SKIP nor a PASS: on this head, UNRUNNABLE naming the unterminated quote, through the handlers' refusal (#6848's slice, D38). The padded row reads ERROR naming `no-operand:test` (D28). V6854-AC1 b and V6854-AC3 stay green.
  - **INT-4 (vs #6848).** `#3616` AC-3 (`state CLOSED`) and `#2577` AC-6 (`delivery_approach`) name no tool: they read the no-command SKIP, never a tool-invocation refusal and never UNRUNNABLE.
  - **INT-7 (vs #6893).** G15 and #6848's round-2 group, G18, stay green on #6685's head.

---

## Risk Register

| # | Risk | Evidence | Sev / Rev | Mitigation |
|---|---|---|---|---|
| R1 | **Reflexive self-grading.** Commit-0 C4 runs the pre-release executor; later C4 runs, Stage 7 and Stage 9 run the branch executor, and a vocabulary change flips this plan's rows. Restated at the delta: it also covers row completeness | The release edits its own grader; C4, Stage 7 and A3.6 all read the executor's output | HIGH / MODERATE | The authoring rules in § Verification Plan. At each rung, diff pre versus head verdicts on this plan and attribute every flip. Stage 9 reads head-SHA verdicts plus the differential. This plan has no stdin-reading cell, so #7531 cannot flip its own rows |
| R2 | **Every later release inherits a regression** — C4, Stage 7, G-PR10 and G-PR11 all run this tool | 215 plans graded by it | HIGH / MODERATE | Corpus differential with zero unattributed transitions; the masked-exit non-regression (D39); one bump (CIAC-4) |
| R3 | **Wiring steals executable rows** | 12 per-issue→runtime-suite moves at Stage 4; mixed cells hit the `behavioral` arm before `file-path`; doctrine `:406–427` | HIGH / CHEAP | Resolved by D17 (remove): the class hint is not wired. D30's probe step keeps a runnable probe ahead of every prose keyword |
| R4 | **Capacity** | raw 34 × 1.3 = 44 against the 15–25 band (D44, D54); #6837 re-sized S → M, and #6848 M → L | HIGH / CHEAP | Override recorded (D4, restated by D14, D44 and D54); § Scope |
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
| #6837 | AC-3 | `grep -rc -F 'Predicate class' release/references release/skills release/governance core/standards core/schemas` expect 0 | 0 across the Stage-4 authoring surfaces once #6180's `:491` rewrite lands (1 at the pin) · control: `grep -rc -F 'Predicate class' release/tools/tests/fixtures` → 15, in 9 files (re-derived at step 4's parent `96ed0a10`; 10 at the Stage-4 pin, before steps 1 and 2 added fixtures) |
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
| #6685 | AC-3 | `grep -c -F "V6685-AC3" release/tools/tests/test_verify_release_plan.sh` at least 1 | malformed method never a named SKIP or a PASS on the keyword and residual routes (UNRUNNABLE on this release's head, naming the unterminated quote; DEV-53); padded `test -f` → ERROR `no-operand:test` (D28) |
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
| #6876 | `git revert` of `fc6a3af8`, `ea83ed39` and `efacc6ac`, in that order, restores the map, the three specs, the workflow comment, the connector, the exclusions list and the prior package bytes, and removes the ADR and its index row; the step's plan commits carry notes only | Low |
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

**Differentiation posture:** engagement density Tight · Stage-9 review depth Deep · Stage-5 activation bias ALL · Stage-13 outcome window 30-day. **Size check:** raw 34 pts; effective 44 at the cross-cutting weight 1.3 — above the 15–25 band, reframe-and-keep with the recorded Override (§ Scope).

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

### Stage 5 round 2 — D-6893b (operator, 2026-09-25)

The record lives on #7834, #6893's round-2 Solutioning sub-task, beside the round-2 design and its Phase A6.5 review (#7840).

| ID | Question | Verdict |
|---|---|---|
| **D50** | Where #6893's keyword-precedence limbs land | (D): all four limbs in #6848's slice at step 5, signed off with its costs disclosed at the gate — #6893's titular fix in a sibling's slice, #6848 grows, and 7 command-less rows read ERROR from step 5 until #6854's residual lands at step 6 (diverged from the hub's recommendation, (A)) |
| **D51** | How strict the declared route is | Exact and backticked: the command the verifier designates IS the invocation, written as a span |
| **D52** | A declared deploy row that also names another command | Graded as partial in this release: an oracle PASS reads UNRUNNABLE, naming the command that did not run; a FAIL stays FAIL |
| **D53** | The review's placement-independent fixes | FM-1 (the oracle's own spellings, with a near-miss arm), FM-2 (the stage-04 wording, and Site B after the integration keyword) and PR-2's residual (14 of the 22 kept rows claim one Check's output) adopted |
| **D54** | #6848's size after D50 | L; #6893 stays S; the release is 34 raw / 44 effective, and the override is restated at 44 |

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
| DEV-32 | `release/tools/verify-release-plan.sh`, regions outside #6837's Contention Map rows (step 4) | Four regions the D29-rendered design places but the Commit-0 map did not assign to #6837: a no-bump note in the version-metadata block (the design's hunk 1a), `VERDICT_PARTIAL_SLOT` among the verdict constants (1b), the multi-command helpers after `compare_threshold` (1e), and the FD-0 doctrine's scope paragraph, which listed `extract_command`'s loop as exempt and now names the four loops that take the body form. No line of `classify_family`, `eval_free_run`, `main()`, `RUNNABLE_VERBS` or `SCHEMA_VERSION` changed. The Contention Map now names #6837 on those regions and adds rows for the two new ones | The design's hunks place the first three; the doctrine edit keeps the rule true of the file, because this step changes the loop it named. A minor adjustment under Stage 6 B3; serial order (P0) resolves the overlap with the later slices | APPLIED at `b49ce79e` |
| DEV-33 | `release/tools/tests/test_verify_release_plan.sh` group G12 and `release/tools/tests/fixtures/verify-plan-stdin-verbs.md` (step 4) | Sub-choice (R) makes the stdin-verb fixture's bare `cat` (its AC-8) prose, so that row reads SKIP `no-executable-command-in-method` rather than a stdin-reader refusal, and D29 makes v3.65.1 AC-9 list its commands. G12-5 now counts 9 named readers, G12-5b pins AC-8's new reading, and `g12_refused` accepts a designated command's refusal named inside a command list. The fixture's note says why its AC-8 differs. The fixture sits under the matrix's fixture glob, which is declared ADD; this is an edit | #7531's intent is kept: every row still emits, and the zero-argument `cat` refusal stays pinned at the unit level (G12-13) and in a dispatch loop (CIAC-6). A minor adjustment under Stage 6 B3 | APPLIED at `c1671607` |
| DEV-34 | #6837's rendered design, read under D29 (B) (step 4) | Three resolutions the (A)-shaped design text did not settle. (1) The not-run reasons are the causal ones under (B) — "names no input" for any further stdin reader, declared or not (sub-choice (iii) names the undeclared one; under (B) the declared one does not run either), "outside the verb set", and otherwise "only the designated command runs"; (A)'s "no comparator of its own" and "comparators that disagree" are not reported. (2) The observed text is an ordered command list with D37's "did not run (reason)" wording. (3) The fixture grows from the design's 10 rows to 14 — AC-11 (emphasis), AC-12 ("returns 0" is not a comparator), AC-13 (a leading bare verb) and AC-14 (a tool span) — and its Expected cells carry the (B) readings | D29 kept (iii) and (R); D37 set the wording; D48 added the emphasis tolerance, which the design did not carry. A minor adjustment under Stage 6 B3 | APPLIED at `c1671607` and `b49ce79e` |
| DEV-35 | `release/tools/tests/test_verify_release_plan.sh`, suite group G16 (step 4) | G16 carries 32 assertions where the design's group carried 22. Under (B) its M3 is rebuilt as the armed-red-then-revert proof of CIAC-6's already-true property (a further command run outside the stdin-isolated dispatch drains the loop), M4 and M5 are added, and every arm first requires its record and derives the slot rather than pinning it | Each closes a vacuous-pass path, following G13's, DEV-28's and DEV-30's precedent. A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED at `c1671607` |
| DEV-36 | G15's AC-18 and the step-3 note "Naming the unrun deploy span is D29's, at step 4" (step 4) | At this step the `bash core/deploy/deploy.sh --check` span is not a command, so AC-18 still names one command and arm V6893-AC2 j is unchanged. The deploy span is named "did not run (outside the verb set)" once #6848's catalog replaces `span_invokes_tool`'s body at step 5; #6848's slice then updates arm j and extends `classify_family`'s step-1 PRECEDENCE comment | The rendered design keeps `span_invokes_tool` a stub until the catalog (its hunk 1e), and D22 governs which spans name a tool. A minor adjustment under Stage 6 B3; handed to #6848's slice | APPLIED — recorded, no code |
| DEV-37 | `release/tools/verify-release-plan.sh`, `span_invokes_tool` and `method_spans` (step 5) | `span_invokes_tool` takes a second argument, the whole-method flag, which `method_spans` computes from its own segmentation, where INT-4 read "swap only `span_invokes_tool`'s body" | D22's "or the whole method" clause cannot be decided from the span alone, and `method_spans` already holds the segmentation. The first argument and the output are unchanged, and G16's M5 is re-targeted to the function line. A minor adjustment under Stage 6 B3 | APPLIED at `6083214b` |
| DEV-38 | The scope family (step 5) | A scope assertion that names another command follows D37's partial rule through `command_list`: a PASS reads the can't-run slot, naming the command that did not run, and a FAIL stays FAIL. The design graded the scope row alone | D37: one partition, so a scope PASS beside a command that did not run is unverified, as it is in the per-issue and cross-issue handlers. Pinned by G17's V6848-AC1 i. A minor adjustment under Stage 6 B3 | APPLIED at `6083214b` |
| DEV-39 | `release/ADRs/ADR-207-a-rows-grading-route-is-declared-in-its-method-cell.md` (step 5) | Decision 7 in #7641's text, plus D51's "written as a backticked span" (#7641's text leaves out the backtick requirement, which the D-6893b record states and the executor implements); Decision 6's last bullet qualified; `deciders:` names the D-6893b gate; the Status gains Decision 7's provenance; three source observations (the round-2 measure with PR-2's residual, this step's re-measure, and the measured effects of Decisions 6 and 7); the D-6893b alternatives line; a Decision 7 reversibility line (MODERATE, D50); the partition record under Related ADRs, by slug token; #7840 and #6848 under References. The per-decision consequence lines for Decisions 6 and 7 are carried in `source_observations` rather than appended to Consequences, and the one line D53 rules into Consequences is added there | The ADR authoring guide's closed forbidden list keeps an Accepted record's consequences unedited, as step 3 read it (DEV-31); D53 names the Consequences line itself, as D30 and D50 name the appended decisions. A minor adjustment under Stage 6 B3, inside the ADR's matrix row | APPLIED at `804434e5` |
| DEV-40 | `release/references/pipeline/stage-04-planning.md`, "The deploy check is reached by declaration" (step 5) | The paragraph first listed three backticked spellings, the root shim's among them. The selftest-discovery gate's Arm F reads a pipeline spec's backticked invocations as commands an agent is told to type, and the agent-side allowlist admits `core/deploy/deploy.sh` but not the root shim, so the reconcile read BLOCKING on `ed47d5f6`. `a57a341c` prescribes `bash core/deploy/deploy.sh --check` and says in words that the verifier reads the same invocation without `bash` or through the shim. The plan update also changes "the repository root's shim" to "the root shim", because the shim lives at the workspace root, not in this repository | FM-2's required content is unchanged, and what the verifier accepts is unchanged (D53 FM-1). The finding was correct: the text told an author, and an agent following it, to type a command the agent cannot run. A Tier-1 [ADJUST] to this slice's own text | APPLIED at `a57a341c` and in the plan update |
| DEV-41 | `release/tools/tests/test_verify_release_plan.sh`, G17 M3 and G18 M6 (step 5) | The GREEN run for `ed47d5f6` first read 411 / 4 against a prediction of 413 / 2. Both mutants were still caught but surfaced differently: G17 M3's (the identifier guard removed) now meets the handlers' refusal, which reads the prose's backticks as a substitution before any verb runs, and G18 M6's (a mention declares the route) now reaches the oracle and reads the slot under D52 rather than PASS. M3's detection accepts either surface and requires the verdict not to be SKIP; M6's reads the family. Re-predicted, then observed: 413 / 2 | The two detections were written against the step's first executor, and the defect each mutant plants still changes its row. The miss is recorded, not re-run away. A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED at `ed47d5f6` |
| DEV-42 | The ERROR transit to step 6 (step 5) | D-6893b disclosed 7 command-less rows reading ERROR from step 5 until #6854's residual lands (DP-5). An eighth transits as well: v4.44 `#5236` AC-1, whose designated command is the pipeline `ls packages/*.skill \| wc -l`, reaches no family on this head and reads the unclassified ERROR. The gate record's reading of it, UNRUNNABLE through the handlers' refusal, holds once the residual routes it to a handler: a what-if on this head that sends the unclassified fallback to per-issue reads it UNRUNNABLE `shell-operator:\|`, and FAIL `command-exit-1` with the refusal also removed | Each of the 8 rows sits on a plan that already fails the masked measure, so no plan's masked exit changes, and the transit is visible only between steps 5 and 6. Recorded, and routed to the hub for INT-9 | APPLIED — recorded, no code |
| DEV-43 | Suite group G17 (step 5) | 43 assertions, beyond the design's arm plan: the D23 guards (h1–h4, M7, M8 at 2 sites, M9), the specificity arms D22 and D24 required (V6848-AC2 i and j), INT-4's arm (k), and a scope row beside a command that did not run (V6848-AC1 i). The design's M4, UNRUNNABLE added to the exit predicate, is not added: it is #6236's AC4 M3, which step 1b left to step 10 because it needs this step's token, and the property it guards is asserted here by V6848-AC2 h and V6848-AC4 | Each added arm closes a vacuous-pass path, following G13's, DEV-28's, DEV-30's and DEV-35's precedent, and one mutation is graded once. A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED at `c25471fa` |
| DEV-44 | V6854-AC2's a-limb (step 6) | The design's RED for the limb, a keyword-less runnable probe reading unclassified/ERROR at the pin, is not observable at this step's parent: #6893's probe step (step 3) already executes that row. The limb is kept, GREEN at the parent, and armed red by mutation — M1b removes the probe step and the residual alone still executes the row with the fixture's roll-up unchanged; M1c removes both and the row reads unclassified/ERROR. V6854-AC2's RED at the parent rests on limb b, the classifier's unclassified terminus and the `unclassified-method` records | The brief directs the a-limb's RED claim to be re-derived at this slice's parent (#6893's design R5, INT-5). A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED at `b42a9bfa` |
| DEV-45 | The operand rule for `grep`, and the design's fixture row AC-10 (step 6) | The design's AC-10, `grep` expect 0, is a bare verb, and step 4's rule reads a bare verb as prose, so it no longer reaches `eval_free_run`. The fixture's no-operand grep row is `grep -c` (flags and no pattern), which read ERROR `matcher-exit-2` at the parent. Operand-aware G-2 reads grep's pattern through the one grep option model: `reads_stdin_cmd`'s no-pattern line returns 2, printing `no-operand:grep`, where it returned 1. Its callers already treat any non-zero status as "not a stdin reader", so method limbs, command lists and G12's unit tables read the same (G12-14's must-pass list carries `grep`, `grep -c` and `grep -c -e`, and stays green). Stage 5's "18 bare `grep` rows FAIL → ERROR" does not arise; 7 flag-only greps change their reason, ERROR both sides | The review's FM-1 made G-2 operand-aware, and keeping grep's argument grammar in one model avoids a second copy. One line in #7531's refusal-model region. A minor adjustment under Stage 6 B3 | APPLIED at `8d76fa12` |
| DEV-46 | The per-issue guard's form (step 6) | Implemented as "the per-issue handler runs only a backtick span": `per_issue_command` returns `extract_command`'s pick only when it is a span of the method. That covers the rendered case, a method with no backticked span, and one sibling the rendered wording leaves open — verb-initial prose beside a backticked path, which is not an identifier, so the bare-string fallback took it and the handlers' refusal read it as a command substitution (`shell-operator:$(`). The corpus effect is the rendered one: 1 plan row (v3.65 `#99` AC-3), and 0 rows of the sibling shape | D38's rule ("unbackticked prose never runs as a command") and the #7665 review's CD-1, which applies D30's "only a backticked span qualifies" to the handler. The fixture pins both shapes (AC-18 to AC-20). A minor adjustment under Stage 6 B3 | APPLIED at `8d76fa12` |
| DEV-47 | The verdict for a command with no comparator whose exit status is not its claim (step 6) | ERROR `no-comparator:<verb>`. D28 required "a named non-PASS", and the #7648 review offered SKIP or ERROR; the command ran, so the row is neither another runner's job nor a method with nothing to run, and the partition (D37) places a row the executor tried to evaluate and could not in ERROR. On the corpus it moves 1 row, v4.20 `s3`, PASS → ERROR, on a plan that already fails the masked measure | D28 and D37; the ADR's alternatives line records SKIP as not chosen. A minor adjustment under Stage 6 B3 | APPLIED at `8d76fa12` |
| DEV-48 | G17 M1's detection (step 6) | Without #6848's residual step, the fixture's awk row no longer falls to an unclassified ERROR: it reaches #6854's residual and the per-issue handler declines the same tool. M1 is detected by the family, per-issue/UNRUNNABLE naming awk, where it read unclassified/ERROR. Its anchor line is unchanged | The design foresaw it: #6854's residual subsumes the purpose of #6848's step, and the redundancy is one line (the design's "D-6848d rendered" note). A minor adjustment under Stage 6 B3, inside the suite's matrix row | APPLIED at `8d76fa12` |
| DEV-49 | `count_mode_cmd` and G8's unit block (step 6) | `count_mode_cmd` finds a count mode only for the verb whose table count column is its count flag, grep: a `-c` on head counts bytes and on ls sorts by time, and neither prints a count. G8's unit block, which extracts the reader and its helpers from the shipped file, now extracts `reader_rule` too; its anchors (`if count_mode_cmd "$cmd"; then`, `if [ "$rc" -ge 2 ]; then`) are unchanged, so G8-M1 and G8-M2 still take | The table's count column is the rule (D38); a reader that reads the table needs the table beside it in a unit test. A minor adjustment under Stage 6 B3 | APPLIED at `8d76fa12` |
| DEV-50 | The partition ADR's partition table (step 6) | The "Could not read" row's example reasons drop `unclassified-method (no family match)`, which Decision 9 retires in the same record, for the reasons this release emits (`count-unreadable:…`, `stdin-reader:<verb>`, `no-operand:<verb>`, `no-comparator:<verb>`, `method-cell-empty`). The outcome, verdict and "fails the run" cells are unchanged | Records the release's final vocabulary rather than revising the partition: D37's partition carried #6854's own proposal, whose ERROR row never listed the retired token. The ADR authoring guide's record-versus-revise boundary. A minor adjustment under Stage 6 B3, inside the ADR's matrix row | APPLIED at `4918b280` |
| DEV-51 | Suite group G19 and its fixture (step 6) | 44 assertions over a 23-row, 2-CIAC fixture, where the design's group carried about 25 over 10 rows and 1 CIAC. Added: AC-0 for the `(plan)` header; the review's four shapes as AC-11 to AC-14; the per-issue guard's three prose shapes; the controls where exit 0 is the claim; the no-operand ls row; CIAC-2 and AC-22 for the exit-0 rule's other two sites; the table's every cell; the JSON identities; the stderr note; M1b and M1c for DEV-44, and M5 to M8 for the rules the design did not seed | Each added arm closes a vacuous-pass path or proves one rule at every site it applies, following DEV-28's, DEV-30's, DEV-35's and DEV-43's precedent, and one mutation is graded per rule. A minor adjustment under Stage 6 B3, inside the suite's and the fixture glob's matrix rows | APPLIED at `b42a9bfa` |
| DEV-52 | `release/tools/verify-release-plan.sh`, regions outside #6854's Contention Map rows (step 6) | `handle_per_issue`'s command read (the per-issue guard) and its no-comparator branch; `handle_integration`'s no-comparator branch; `grade_limbs`' designated no-comparator branch; `count_mode_cmd`; `reads_stdin_cmd`'s no-pattern line (DEV-45); `is_runnable_probe`'s comment, which names the gates it defers to; and three new regions — the reader table with its two readers after `reads_stdin_cmd`, `per_issue_command` before `handle_per_issue`, and `rollup_counts` before `emit_md`. No line of `main()`'s loops, the exit predicate, `RUNNABLE_VERBS`, `SCHEMA_VERSION` or either handler's `is_runnable_verb` check changed. The Contention Map now names #6854 on those rows and adds the new regions | D28's rules apply wherever a result is read, D38 placed the guard and the table here, and D27 asked for one roll-up reader. Serial order (P0) resolves the overlap with the later slices. A minor adjustment under Stage 6 B3 | APPLIED at `8d76fa12` |
| DEV-53 | #6685's malformed-method control, its AC-3 Expected cell and INT-3 (step 7) | The design read the two unterminated-quote rows — control AC-1 on the keyword route, AC-2 on the residual route — as ERROR `count-unreadable:matcher-exit-3`, measured at the pin. On this head both read UNRUNNABLE `shell-operator:"`: the handlers' shell-operator refusal (#6848's slice, D38 and the D50 owner assignment) reads an unterminated quote through `span_shell_operator`, as that predicate's contract states, before `eval_free_run`'s tokenizer is reached. G20's arms assert what the control exists for — the row reaches the per-issue handler and is never a named SKIP and never a PASS, ERROR or UNRUNNABLE — rather than pinning ERROR; the padded `test -f` keeps ERROR `no-operand:test`. The control fixture's intro and its AC-1 and AC-2 Expected cells state that property, and #6685 AC-3's Expected cell and INT-3's clause are restated to match | The card's AC-3 names the control's purpose, "so the fix cannot be satisfied by making everything SKIP", and D31 grades AC-3 "on both malformed-method routes and on the padding (ERROR `no-operand:test`)"; both hold, and the card's "still ERRORs" is met by the padded row. On this head a single malformed command that reaches the handler by a keyword or by the residual is refused before it runs: the probe step claims every closed backticked command this executor can run, so a malformed command reads ERROR only on the probe route — a well-shaped probe the matcher cannot evaluate, or the padded row. Two shapes fall outside that reading, both measured: a multi-command row whose prose states disagreeing comparators reads ERROR `comparator-ambiguous` on any route, and a command in an unclosed backtick span still runs on the keyword and residual routes (routed to the hub). Measured: control AC-1 reads ERROR at the pin and UNRUNNABLE from `1d60350b`, green under the property on every executor. A minor adjustment under Stage 6 B3, surfaced to the hub; no executor byte changes | APPLIED at `ae3ea050` and in the plan update |
| DEV-54 | Suite group G20 and the main fixture's intro (step 7) | 28 assertions where the design's group, with FM-3 applied, carried 24. Added: an authoring arm pinning FM-1's constraint and INT-2's precondition (the documented-decision rows carry no backticked span and open with no allowlisted verb word, read against `RUNNABLE_VERBS`), which the fixture's intro also states in words; a reader control on v4.46 (`#2577` AC-3, which shares its AC id with the cited `#3616` AC-3, reads its own record); and FM-2's route precondition, with its mutation's site count. Each seeded failure is proved to apply at exactly its sites (the suite's `m19` contract) in place of the design's one-line diff count, M2 and M5 also assert the exit code their rule moves, and the design's helper names become `g20_*` and `m20` after the suite's own precedent | Each closes a vacuous-pass path or proves a rule at every site it applies, following DEV-28's, DEV-30's, DEV-35's, DEV-43's and DEV-51's precedent. A minor adjustment under Stage 6 B3, inside the suite's and the fixture glob's matrix rows | APPLIED at `ae3ea050` |
| DEV-55 | The suite's header group list (step 7) | Gains G18's entry, which it lacked, beside G20's | Step 6 recorded the gap and routed it to the hub (its E6), and the hub placed it in this step as a minor adjustment. The list is the suite's own documentation, inside its matrix row | APPLIED at `ae3ea050` |
| DEV-56 | The map's § 2 grammar (step 8) | PR-2's forbidding form, applied to every placement it covers. The design's bullets defined `/**/` and a trailing `/**` only; the grammar now also says that a leading `**` and a `**` sharing its segment are never written in the column, and that a wildcard-free directory name covers every path below it | Measured at this step (Step 8 Evidence-Grounding E1): git resolves an in-segment `**` by its position and a wildcard-free directory name recursively, so the design's grammar and git would have disagreed on both, beyond the leading-`**/` case PR-2 named. D33 left PR-2's form to Stage 6 as "the form that keeps the reference resolver conformant", and this is that form. A minor adjustment under Stage 6 B3, inside the map's matrix row | APPLIED at `efacc6ac` |
| DEV-57 | The map's § 2 and § 4 text (step 8) | Beyond the design's Change 1: § 2 gains the Runner input and Per-path runners paragraphs; row 6's Notes name `TEST_SUITE_GLOBS` and take the review's per-suite wording for the fixture relation; § 4 gains a row for a matched path that runs no suite, with its two named reasons, and a **Reads as** column carrying D37's reading table | FM-1's mitigations 1–4 (D33) needed a home in § 2; D43 and the review's text note asked for the constant to be named; D37 adopted the design's R5 reading table for this card, and § 4 is where the map states its outcomes. A minor adjustment under Stage 6 B3, inside the map's matrix row | APPLIED at `efacc6ac` |
| DEV-58 | The connector's `--self-test` (step 8) | Beyond the design's Change 5: each child case runs with stdin on the null device; the key is blanked on the four cases that do not carry the sentinel, so a real key in the caller's environment is never used; the exit-code line names 1 for a failed assertion; and two seeded failures prove the cases observe what they claim — an unknown argument that exits 0, and an enabled path that prints the key — where the design seeded one | Hermeticity by construction rather than by the caller's environment; a header that states every exit the script now has; and a second seeded failure that proves the key assertion is not vacuous, the weakness the review's FM-4 named. A minor adjustment under Stage 6 B3, inside the connector's matrix row | APPLIED at `ea83ed39` |
| DEV-59 | The ADR file for #7672 (step 8) | Decision 6 records D37's reading of the map's outcomes, beyond the five decisions the ADR issue lists; Decision 1 carries PR-2's chosen form and Decision 3 D43's coupling | The ADR issue was drafted before the Collective Review rendered D37 and D43 for this card. Recording a rendered decision is the ADR authoring guide's record, not revise. A minor adjustment under Stage 6 B3, inside the ADR's matrix row | APPLIED at `fc6a3af8` |

---

## Documentation Impact

Each row lands with its card's slice; the slice records the status and the commit.

| Issue | Declared docs | Status | Commit | Notes |
|---|---|---|---|---|
| #7531 | `--help` agrees with dispatch (co-discharged under D-6180) | UPDATED — step 3: the CHECK FAMILIES and per-issue lines describe the dispatch the classifier performs | step 1: `a3683b80` · step 3: `e14bb9ca` | Graded on V7531-AC3, in G15. Step 1 also updated `--help`'s EXIT CODES block (exit 1 now covers a DEGRADED verdict stream, D19) and added the executor's in-file FD-0 doctrine; step 2 retired the predicate-class wording |
| #6180 | stage-04 AC-Binding Limb 1 (`:491`); the D-6180 ADR (#7641) | UPDATED (the stage-04 bullet) · CREATED (the ADR file) — step 2 | `c4e7fdba` | Card declares no Documentation Impact section; the design's Changes 2 and 5 carry it. Step 2 also rewrote the executor's `--help` CHECK FAMILIES line and regenerated the release ADR index |
| #6893 | the classifier doctrine and the `usage()` per-issue line; Decision 6 in #7641 | UPDATED (the classifier doctrine; `usage()`'s CHECK FAMILIES and per-issue lines) · UPDATED (the D-6180 ADR: Decision 6 appended) — step 3 | `e14bb9ca` | Card declares no Documentation Impact section; the round-1 design's Changes 1 and 3 carry it. Round 2's `usage()` Site B, its stage-04 paragraph and Decision 7 landed with #6848's slice at step 5 (D50): `ed47d5f6`, `804434e5`, `a57a341c` |
| #6837 | stage-04 Limb 1 bullet (after the #6180 edit) | UPDATED — step 4: stage-04 Limb 1 gains the rule for a cell naming several commands, scoped to its own table (D37), with FM-1's null sentence and D48's comparator forms · UPDATED — `usage()` gains MULTI-COMMAND METHODS | `b49ce79e` | The card's own declared impact — under the remove branch, no authoring surface still names the column — landed with #6180's step-2 rewrite (`c4e7fdba`), and AC-3 grades it: 0 hits across the five authoring roots. The multi-command rule is the design's Change 4 and hunk 1g |
| #6848 | stage-04 "What the plan verifier can execute" paragraph; `usage()`; the partition ADR (#7647) | UPDATED — step 5: stage-04 gains "What the plan verifier can execute" and, for #6893's round 2 (D50), "The deploy check is reached by declaration" · UPDATED — `usage()`: the scope and unrunnable families, VERDICTS, EXIT CODES and round 2's Site B · CREATED — the partition ADR (#7647) · UPDATED — the D-6180 ADR (#7641): Decision 7 appended | `6083214b` · `ed47d5f6` · `804434e5` · `a57a341c` | The release ADR index is regenerated. The partition ADR carries #6837's Decision line; #6854's, #6685's and #6236's join from their slices |
| #6854 | stage-04 "A method with nothing to run" paragraph; the stage-07 laundering-guard line; its Decision lines in #7647 | UPDATED — step 6: stage-04 gains "A method with nothing to run" (with the reader rules and the per-issue guard) · UPDATED — stage-07 gains the verdict-laundering guard beside Phase A's plan-verification paragraph (D46) · UPDATED — the partition ADR (#7647): Decisions 9–11 · UPDATED — `usage()`: the residual in CHECK FAMILIES, VERDICTS, READER SEMANTICS, and the `--format` line naming the `(plan)` group | `8d76fa12` · `4918b280` · `8c7d9780` | The card declares the executor's SKIP vocabulary as its documentation surface. The `(plan)` header is the #7635 fix, whose declared impact is exactly that `--help` names the group, which the `--format` line now does. The release ADR index verifies COUNT 0: no regeneration owed |
| #6685 | none expected (card: parity with an existing disposition); its Decision line in #7647 | UPDATED — step 7: the partition ADR (#7647): Decision 12 · NONE otherwise: the card declares no documentation surface, and the slice adds no user-facing text | `19bacff0` | The suite's header lists G18 and G20 (`ae3ea050`), which is the suite's own documentation, not a declared doc. The release ADR index verifies COUNT 0: no regeneration owed |
| #6876 | the runtime-suite selection map; stage-06/07/08 citations by role; the ADR (#7672) | UPDATED — step 8: the map (§ 2's grammar, reference resolver, non-conformant matchers, precedence and runner input; rows 5 to 8; the per-path runner guarantees; § 4 by role, with the no-suite row and the **Reads as** column; the Tier-A marker) · UPDATED — stage-06 C4, stage-07 A8 and stage-08 cite the fallback by role · UPDATED — the install-tests placement comment (FM-5) · UPDATED — the connector's header (usage, exit codes, the "When implemented it MUST" list) · CREATED — the ADR (#7672), with the release ADR index regenerated | `efacc6ac` · `ea83ed39` · `fc6a3af8` | The map is itself the documentation surface. The finops skill's SKILL.md does not list the connector's flags; the design routed that to an optional follow-up, and the skill-editor's materiality call leaves the SKILL.md unchanged |
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
| **Step 4 (#6837) — the suite, RED then GREEN** | Stub roots: a `git archive` of each tree with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line, the original text kept. The parent `96ed0a10` gives 305 passed / 2 failed. RED — G16, its fixture and the G12 reading of a bare verb, on the pre-fix executor (`c1671607`): **311 / 24**, the new failures exactly G12-5b and 21 G16 arms (the slot binding; a, b, d, e, f, h, i and k; V7531-CIAC6 a and b; m to q; and M1 to M5, which cannot take on the pre-fix file). GREEN (`b49ce79e`): **338 / 2**. Each figure was predicted before its run. The 2 are P1 and M9's control, which need a repository. All 307 earlier outcome lines keep their outcome on both runs, and the one text change is G12-5's reader count (sensitivity: a planted flip reads 1 changed). The stub logs stayed empty on every suite run. CI on the macOS smoke job (bash 3.2.57): `c1671607` **315 passed, 22 failed** (exactly the 22 predicted); `b49ce79e` **342 passed, 0 failed**, ALL PASS |
| **Step 4 — the helpers, unit battery** | 46 cases, the functions sed-extracted from the shipped executor and run on bash 3.2.57 under `set -euo pipefail`: `extract_command` 13 (the design's 11 pinned cases among them), `method_spans` 3, the comparator vocabulary (`comparator_phrases`, `extract_threshold`, `limb_comparator`) 17, `method_limbs` and `limbs_are_multi` 10, and `runnable_probe_of` 3 — 46 of 46. Controls: the same battery fails 4 cases on a bare-verb-blind variant and 3 on an emphasis-blind variant |
| **Step 4 — corpus and fixture differential** | The parent and the step-4 executor side by side in one stub root (the step-4 tree, with the parent's executor copied in for the parent side), `--format=json`, stdin on the null device, over every plan (217) and every test-fixture markdown file (48): 230 of 265 inputs byte-identical, and 152 records change — 137 in 33 plans and 15 in 2 fixtures (14 in the new one, plus the stdin-verb fixture's AC-8, ERROR → SKIP under (R)). 0 record-count changes and 0 exit-code changes. The 137 plan records: 84 PASS → the slot (multi-command rows whose designated command passes, 20 plans); 13 keep FAIL or ERROR and now name their other commands (6 FAIL, 7 ERROR); 19 bare-verb rows in 9 plans (17 FAIL → SKIP, 2 FAIL → ERROR `stdin-reader:grep`); and 21 moved by D48's emphasis tolerance — v4.04 CIAC-3 and v4.57 CIAC-1 FAIL → PASS, 18 v4.60 rows keep PASS with their count now read, and v4.60 `#5651` AC-1 PASS → FAIL `count=11 (wanted == 10)`. D39's masked exit: governance-ci-gates clears, and v4.60 turns masked-failing through that one row — attributed to this step (D48); its method cell pins a count the file outgrew after the Stage-4 pin. D46: none of the 17 FAIL → SKIP moves is laundering — every method cell is byte-identical, and each FAIL came from a bare verb run with no argument, which aborts the child on bash 3.2 rather than grading anything. Control: the parent executor against itself, 265 of 265 identical |
| **Step 4 — this plan, through the executor (C4, hermetic)** | The parent tree on its own plan gives `19 PASS / 21 FAIL / 12 SKIP / 1 ERROR`. The step-4 tree gives **`21 PASS / 19 FAIL / 12 SKIP / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`**, as predicted: exactly 2 of 53 records change verdict, each FAIL → PASS — #6837 AC-4 (`count=59`) and CIAC-6 (`co-occurrence count=14`) — and #7531 AC-1's count moves 41 → 43, PASS both times. JSON roll-up `stream_state` fetched, 48 of 48 records. These notes change no parsed row: the edited file yields the same 53 records and verdicts, and only the provenance record's line count moves. The FCM seam on a run-directory copy parses as before: `declared=50 interpreted=50 obligations=6 excluded=9 conditional=0 uninterpreted=0 pathless=0 prose_led=0`. `check-ac-binding.py --ordinals-only` → VERDICT BOUND. The one ERROR stays FCM-COVERAGE `diff-unresolvable` |
| **Step 4 — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with the step's 6 paths on stdin (the diff from `96ed0a10`, plus this plan), returns 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 4 — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over stage-04, the two fixtures and this plan: 0 findings, exit 0. Control: a planted broken link in a stub copy of the tree returns 1 finding, exit 1 |
| **Step 4 — SIGPIPE idiom and identity** | The SIGPIPE gate's pattern block, copied from the workflow and evaluated with BSD grep with its continuation join, over the step's 594 added shell lines: 0 (sensitivity: each idiom alone → 5 of 5; specificity: `x \|\| true` → 0). An identity and public-surface scan of every added line (739, this plan's included) and each commit message: 0 hits beyond each message's one noreply trailer (sensitivity: 4 of 4 planted lines) |
| **Step 4 — runtime suite (map row 4)** | `release/tools/verify-release-plan.sh` selects row 4; the suite, the fixtures, stage-04 and this plan match no row. Row 4's runner, `check-selftest-coverage.py --run`, run under § 3's recipe for the row (`none (read-only)`, so no `HOME` override) in stub roots of the parent and of this step: 69 of 74 on both, the same 5 environment failures, and identical per-tool status lines apart from a live-process count. The verifier is absent from its discovered set (0 mentions; control: `version-grammar` 4) — the residual #6876 closes — so the explicit suite runs above are this step's runtime evidence (R8). CI on `b49ce79e`: ARM A **74 of 74**. One `test-run/suite-pass` event emitted and read back |
| **Step 4 — ADR index** | N/A — this step adds no record under `release/ADRs/` |
| **Step 5 (#6848) — the suite, RED then GREEN** | Stub roots, each a `git archive` of the tree with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line, the original text kept; the suite ran in each by its repository-relative path from the stub's root. The parent `3239907e` gives 338 passed / 2 failed. RED 1 — G17 and its two fixtures on the pre-fix executor (`c25471fa`): **342 / 33**, the new failures exactly 31 G17 arms. GREEN 1 (`6083214b`): **381 / 2**. RED 2 — G18, with the G5 and G15 restatements, on that executor (`4183b220`): **385 / 25**, the new failures exactly G15's new M1 arm, G15 M5 as restated, and 21 G18 arms. GREEN 2 (`ed47d5f6`): first **411 / 4** against a prediction of 413 / 2 (DEV-41), then, re-predicted, **413 / 2** in a fresh stub. Each figure was predicted before its run. The 2 are P1 and M9's control, which need a repository. Every earlier outcome line keeps its outcome apart from the restated arms, and the stub logs stayed empty on every suite run. CI on the macOS smoke job (bash 3.2.57): `c25471fa` **346 passed, 31 failed**; `6083214b` **385 passed, 0 failed**; `4183b220` **389 passed, 23 failed**; `ed47d5f6` **417 passed, 0 failed**, ALL PASS; `a57a341c` **417 passed, 0 failed** |
| **Step 5 — CI beyond the suite** | The selftest-discovery job on `ed47d5f6`: Arm A **74 of 74**, and the reconcile BLOCKING, because Arm F read the new stage-04 paragraph's root-shim spelling as an invocation the agent-side allowlist does not admit (DEV-40). Reproduced on a stub of `804434e5` (exit 1), and cleared on the same stub with `a57a341c`'s text (EXPECTED-RESIDUAL, exit 4, as at the parent); CI's job passed on `a57a341c`. The macOS smoke job on `a57a341c` failed on `release/tools/automated-closeout.sh --self-test`, at its check-5 (j), a two-second wall-clock bound across a settle group, while the executor suite in the same job read 417 / 0; that commit changes one line of stage-04, and the same job passed on `804434e5` and `ed47d5f6` (routed to the hub). The ADR durability, ADR-number integrity, Issue-reference validity and Dead-file-reference gates passed on `804434e5` and `a57a341c` |
| **Step 5 — the helpers, unit batteries** | Two batteries, the functions sed-extracted from the shipped executor and run on bash 3.2.57 under `set -euo pipefail`: the tool catalog and the command-shape test, `method_spans`' whole-method flag, `extract_command`'s identifier guard, the scope grammar and pathspec matching, and `command_list` — 54 of 54; the declared-route helpers and the refusal renderer — 26 of 26. They were development batteries: their controls are the suite's seeded failures (G17's M1 to M9, G18's M5 to M9), not a separate variant run |
| **Step 5 — corpus and fixture differential** | The step-4 and the step-5 executor side by side in one stub root (the step-5 tree, with the step-4 executor copied in for its side), `--format=json`, stdin on the null device, over every plan (217) and every test-fixture markdown file (50). No input is byte-identical, because every roll-up gains the UNRUNNABLE counter. 507 records change: 468 in 96 plans, and 39 in 4 fixtures (24 in the two new ones, 11 in the multi-limb fixture, 4 in the historical-skips fixture). 0 record-count changes; 2 exit-code changes, the two new fixtures (3 → 0). The 468 plan records, each attributed: **84** slot rows SKIP → UNRUNNABLE (INT-4; 32 of them now name a tool span in their command list); **31** tool-span rows, against the design's estimate of about 29 — 22 PASS → the slot, and 9 that keep FAIL or ERROR and now name the tool (D22); **115** tool declines SKIP → UNRUNNABLE, 16 under a different name, 11 of which had named an identifier, and **3** whole-method scripts newly named (D21, D22); **101** refusals that named an identifier or a one-token mention → the no-command SKIP (D22, D24, CD-1); **98** unclassified ERROR → UNRUNNABLE naming the tool (D24's residual step); **12** rows whose designated command carries shell syntax → UNRUNNABLE `shell-operator:<op>`, 11 from ERROR and 1 from PASS (the handlers' refusal, D38, D50); and **24** deploy-route rows (round 2, D50–D53): 22 leave the oracle — 11 to UNRUNNABLE naming a tool, 3 to the no-command SKIP, and 8 to the unclassified ERROR (the 7 command-less rows and v4.44 `#5236` AC-1, DEV-42) — and 2 declared rows that name another command keep FAIL under the stub, now with the command list (D52). No record newly reads PASS. D39's masked exit: 6 plans stop failing (v3.70, v3.96, v4.01, v4.06, v4.21, v4.67.1), each through rows that now read UNRUNNABLE, and none starts. D46: 123 FAIL or ERROR → SKIP or UNRUNNABLE moves, all attributed — 98 residual-step rows, 11 refusals and 14 rows released from the oracle. Every method cell is byte-identical, and each move replaces a verdict that did not grade the row's claim: an unclassified ERROR on a row that was read, a matcher error from shell syntax reaching grep as operands, or the deploy check's exit status, which tests none of those claims. Control: the step-4 executor against itself, 267 of 267 byte-identical |
| **Step 5 — the named-tool and oracle censuses** | Named tools over the 2,587 records of the 217 plans: 263 records name a declined tool, with 38 distinct names (19 catalog words, 19 script basenames) and 0 identifiers; the step-4 executor names 102 identifier mentions over the same records (control). Rows that reach the deploy-check oracle: 22 on 15 plans, all sync, each carrying the backticked invocation, against 44 on 25 plans at the parent (29 sync, 15 regression) — the round-2 design's figures (INT-8). One-token script spans: 78 records — 26 named, 28 unnamed (22 unclassified ERROR, 6 no-command SKIP), and 24 graded otherwise |
| **Step 5 — this plan, through the executor (C4, hermetic)** | The step-4 tree on its own plan gives `21 PASS / 19 FAIL / 12 SKIP / 1 ERROR`. The step-5 head (`a57a341c`) on this plan before this update gives **`24 PASS / 16 FAIL / 12 SKIP / 0 UNRUNNABLE / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`**, as predicted: exactly 3 of 53 records change verdict, each FAIL → PASS — #6848 AC-1 (`count=53`), AC-2 (`count=53`) and AC-4 (`count=4`) — and #6848 AC-3 stays PASS `count=1 (== 1)`, the `RUNNABLE_VERBS` literal unchanged. CIAC-3 and CIAC-5 stay FAIL until steps 10 and 8. With this update the same 53 records keep their verdicts, and only the provenance record's line count moves (1,235 to 1,350); the stub's delegation log stayed empty. The FCM seam on a copy outside the corpus, with an empty delivered set, parses as before: `declared=50 interpreted=50 obligations=6 excluded=9 conditional=0 uninterpreted=0 pathless=0 prose_led=0` (control: a planted conditional label → `obligations=5 conditional=1`). `check-ac-binding.py --ordinals-only` → VERDICT BOUND. One double-brace `RELEASE_VERSION` placeholder. The one ERROR stays FCM-COVERAGE `diff-unresolvable` |
| **Step 5 — integration criteria** | INT-8 (internal): the declared route reads the command the handlers decline — the 22 kept rows each designate the invocation, and every released tool row reads UNRUNNABLE naming a tool, never an identifier (the censuses above); D45-bc and D45-d are green. INT-10 (vs #7531): G12-8 (the backticked child-route sync row reaches the oracle and its stdin-reading child runs), G12-9 and G12-M1 are green on this head. INT-11 (vs #6180's ADR file): Decisions 1–5 are byte-identical to the parent's, Decision 6 differs only by its last bullet's qualification, and Decision 7 is added. INT-9 (vs #6854) grades on #6854's head; on this head the 7 command-less rows and v4.44 `#5236` AC-1 read the unclassified ERROR (DEV-42) |
| **Step 5 — the ADRs and the index** | `renumber-adr.py --detect` → `ANCHOR 206 · NEXT-FREE 207 · CLAIMED-SET-BRANCH-ONLY 207`; the partition record takes 208, and both of this branch's claims read BINDS. `generate-adr-index.py --verify` reads `MISSING ADR-208`, COUNT 1, before `--write`, and **COUNT 0** after. `check-adr-durability.py --diff-base 3239907e` over both files → COUNT 0 (sensitivity: a stub copy with a planted commit SHA, the operator handle and an identity-field issue reference → R2-SHA, R3 and R4, COUNT 3). `check-adr-numbers.py` on this branch's tree reports the gap the mainline's two newest records leave, as at step 2; on the mainline's ADR set plus these two it reads PASS, contiguous to 208. Issue references: 12 in the partition record and 15 in the D-6180 record, all under `## References`, all issues and none a pull request (control: the release PR's number resolves to a pull request); a replica of the placement rule, reading the gate's own heading pattern, finds 0 outside the block (sensitivity: a planted line-2 reference → 1). CI's ADR durability, ADR-number integrity and Issue-reference validity gates passed on `804434e5` |
| **Step 5 — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with the step's 10 paths on stdin (the diff from `3239907e`, plus this plan), returns 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 5 — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over stage-04, both ADRs, the release ADR index, the three fixtures and this plan: 0 findings, exit 0. `check-release-links.py --check-anchors --images` over the same eight files: 0 broken. Control: a planted broken link in a stub copy of the partition ADR returns 1 finding from each checker |
| **Step 5 — SIGPIPE idiom and identity** | The SIGPIPE gate's pattern block, as the earlier steps evaluated it, with BSD grep and its continuation join, over the step's 1,342 added shell lines: 0 (sensitivity: each idiom alone → 5 of 5; specificity: `x \|\| true` → 0). An identity and public-surface scan of every added line (1,550 before this plan update) and each commit message: 0 hits beyond each message's one noreply trailer (sensitivity: 4 of 4 planted lines) |
| **Step 5 — runtime suite (map row 4)** | `release/tools/verify-release-plan.sh` selects row 4; the suite, the fixtures, the ADRs, the index, stage-04 and this plan match no row. Row 4's runner, `check-selftest-coverage.py --run`, run under § 3's recipe for the row (`none (read-only)`, so no `HOME` override) in stub roots of the parent and of this step: 69 of 74 on both, the same 5 environment failures (4 need a repository; 1 is the inert event-writer stub), and identical per-tool status lines. The verifier is absent from its discovered set (0 mentions; control: `version-grammar` 4) — the residual #6876 closes — so the explicit suite runs above are this step's runtime evidence (R8). CI: ARM A **74 of 74** on `ed47d5f6` and on `a57a341c`. One `test-run/suite-pass` event emitted and read back |
| **Step 6 (#6854) — the suite, RED then GREEN** | Stub roots, each a `git archive` of the tree with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line, the original text kept; the suite ran in each by its repository-relative path from the stub's root. The parent `1d60350b` gives 413 passed / 2 failed. RED — G19 and its fixture on the pre-fix executor (`b42a9bfa`): **423 / 27**, the new failures exactly the 25 predicted G19 arms. GREEN (`8d76fa12`): **457 / 2**; the code head `8c7d9780` gives **457 / 2** again, its 459 outcome lines identical to GREEN's. Each figure was predicted before its run. The 2 are P1 and M9's control, which need a repository. All 415 earlier outcome lines keep their outcome on both runs, and on GREEN 12 change text only (the restated messages, and readings that now show the residual's SKIP, `no-operand:grep` or `matcher-exit-1`). The stub logs stayed empty on every suite run. CI on the macOS smoke job (bash 3.2.57): `b42a9bfa` **427 passed, 25 failed**, exactly the 25 G19 arms; `8d76fa12`, `4918b280` and `8c7d9780` **461 passed, 0 failed** |
| **Step 6 — corpus and fixture differential** | The parent and the step-6 executor side by side in one stub root (the step-6 tree, with the parent's executor copied in for its side), `--format=json`, stdin on the null device, over every plan (217) and every test-fixture markdown file (51). No input is byte-identical, because every roll-up takes the new line and keys (D27). 460 records change: 442 in 54 plans, and 18 in 4 fixtures (15 in the new one, and one unclassified row each in the two class-inert fixtures and the runtime-hijack fixture, which now reads the no-command SKIP). 0 record-count changes; 2 exit-code changes, the two class-inert fixtures (3 → 0), whose one ERROR each was that row. The 442 plan records, each attributed: **428** residual rows → the no-command SKIP and **1** → UNRUNNABLE naming `shell-operator:\|` (D26); **1** row the per-issue guard moves, ERROR → the no-command SKIP (D38); and **12** through the reader table (D28, D38) — 7 pattern-less greps whose reason moves to `no-operand:grep` (ERROR both sides), 3 lone `test -f` rows → ERROR `no-operand:test` (1 from PASS, 2 from UNRUNNABLE), 1 `ls` on a missing path FAIL → ERROR `matcher-exit-1`, and 1 cat with a textual expectation PASS → ERROR `no-comparator:cat`. 0 unattributed. No plan record newly reads PASS; the one new PASS is the fixture's `wc` control. D39's masked exit: 34 plans stop failing and 1 starts (v4.55), attributed in § Step 6 — as landed. D46: 438 FAIL or ERROR → SKIP or UNRUNNABLE moves — 429 plan and 7 fixture residual rows, and 1 plan and 1 fixture guard row. Every method cell is byte-identical, and each move replaces a verdict that graded nothing: an unclassified ERROR on a row no handler inspected, or prose run whole as a command. Control: the parent executor against itself, 268 of 268 byte-identical |
| **Step 6 — this plan, through the executor (C4, hermetic)** | The parent tree on its own plan gives `24 PASS / 16 FAIL / 12 SKIP / 0 UNRUNNABLE / 1 ERROR — over 42 per-issue row(s); 11 declared-deferred`. The code head `8c7d9780` on this plan, with this update, gives **`28 PASS / 12 FAIL / 12 SKIP / 0 UNRUNNABLE / 1 ERROR over 53 record(s) (42 per-issue row(s), 6 cross-issue, 5 always-on) — not graded by this run: 12 SKIP (11 declared-deferred, 0 no command in method, 1 other) and 0 UNRUNNABLE; could not evaluate: 1 ERROR`**, as predicted: exactly 4 of 53 records change verdict, each FAIL → PASS — #6854 AC-1 (`count=20`), AC-2 (`count=16`), AC-3 (`count=42`) and AC-4 (`count=18`) — and only the provenance record's line count moves. The other SKIP is PROV-DELTA: the stub run supplies no Stage-4 comment. The JSON roll-up reads `records` 53, `cross_issue_records` 6, `always_on_records` 5, `no_command` 0 and `skip_other` 1, with `stream_state` fetched and 48 of 48 records read. The FCM seam on a copy outside the corpus, with an empty delivered set, parses as before: `declared=50 interpreted=50 obligations=6 excluded=9 conditional=0 uninterpreted=0 pathless=0 prose_led=0` (control: a planted conditional label → `obligations=5 conditional=1`). `check-ac-binding.py --ordinals-only` → VERDICT BOUND. One double-brace `RELEASE_VERSION` placeholder. The one ERROR stays FCM-COVERAGE `diff-unresolvable` |
| **Step 6 — integration criteria** | INT-5 (vs #6893): G15 is green on this head (30 of 30); D28's exit-0 rule lands in the same merge as the probe step; V6854-AC2's a-limb is re-derived at the parent, GREEN there and armed red by M1b and M1c (DEV-44); and v4.20 `s3` reads ERROR `no-comparator:cat`, its family moved by step 3 and its reason by this step. INT-9 (vs #6848): the 7 command-less rows #6848's slice released read per-issue/SKIP `no-executable-command-in-method`, and v4.44 `#5236` AC-1 reads per-issue/UNRUNNABLE, its command list naming `shell-operator:\|`; G18 is green (31 of 31). V6236-AC4 stays green (13 of 13) |
| **Step 6 — the ADR and the index** | `check-adr-durability.py --diff-base 1d60350b` → COUNT 0 (sensitivity: a run-directory copy of the partition record with a planted commit SHA and an unanchored count in Decision 9 → R2-SHA and R2-COUNT, COUNT 2; the unmodified copy → COUNT 0). `generate-adr-index.py --verify` → COUNT 0, so no regeneration is owed (sensitivity: a copy with a drifted title → DRIFT ADR-208, COUNT 1). Issue references: 18, all under `## References`; a replica of the placement rule reads 0 outside the block (sensitivity: a planted reference in the Context → 1). CI's ADR durability, ADR-number integrity and Issue-reference validity gates passed on `8c7d9780` |
| **Step 6 — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with the step's 7 paths on stdin (the diff from `1d60350b`, plus this plan), returns 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 6 — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over the partition ADR, stage-04, stage-07, the new fixture and this plan: 0 findings, exit 0. `check-release-links.py --check-anchors --images` over the same five files: 0 broken; `--plan-depth-lint` on this plan: 0. Control: a planted broken link in a stub copy of the partition ADR returns 1 finding from each checker |
| **Step 6 — SIGPIPE idiom and identity** | The SIGPIPE gate's pattern block, as the earlier steps evaluated it, with BSD grep and its continuation join, over the step's 689 added shell lines: 0 (sensitivity: each idiom alone → 5 of 5; specificity: `x \|\| true` → 0). An identity and public-surface scan of every added line (901, this plan's update included) and each of the step's 4 code commit messages: 0 hits beyond each message's one noreply trailer (sensitivity: 4 of 4 planted lines). CI's SIGPIPE-idiom, Depersonalization and Commit-message depersonalization gates passed on `8c7d9780` |
| **Step 6 — runtime suite (map row 4)** | `release/tools/verify-release-plan.sh` selects row 4; the suite, the fixture, the ADR, stage-04, stage-07 and this plan match no row. Row 4's runner, `check-selftest-coverage.py --run`, run under § 3's recipe for the row (`none (read-only)`, so no `HOME` override) in stub roots of the parent and of this step: 69 of 74 on both, the same 5 environment failures (4 need a repository; 1 is the inert event-writer stub), and identical per-tool status lines. The verifier is absent from its discovered set (0 mentions; control: `version-grammar` 4) — the residual #6876 closes — so the explicit suite runs above are this step's runtime evidence (R8). CI: ARM A **74 of 74** on `b42a9bfa`, `8d76fa12`, `4918b280` and `8c7d9780`, and the reconcile reads EXPECTED-RESIDUAL (exit 4), as at the parent. One `test-run/suite-pass` event emitted and read back |
| **Step 7 (#6685) — the suite, GREEN, and the co-discharge RED** | Stub roots, each a `git archive` of `aa8cd0d3` with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line, the original text kept; each suite and harness ran by its path inside its own stub, with stdin on the null device. The parent gives 457 passed / 2 failed. GREEN (the slice's suite and fixtures, `ae3ea050`): **485 / 2**, G20 28 of 28, and all 459 earlier outcome lines identical in outcome and text (sensitivity: a planted flip in a copy reads 1 changed). The 2 are P1 and M9's control, which need a repository. The co-discharge RED, with G20 alone in a harness sliced from the suite's own lines: **19 / 7** on the executor before #6854's slice (`1d60350b`) and on the Stage-4 pin executor, the 7 predicted in each, and **28 / 0** on this head's executor. Each figure was predicted before its run. The stub logs stayed empty on every suite and harness run (sensitivity: one declared deploy row delegated through the executor logged 1 line). CI on the macOS smoke job (bash 3.2.57): `ae3ea050` and `19bacff0` **489 passed, 0 failed** |
| **Step 7 — no executor byte changes** | `git rev-parse` of `release/tools/verify-release-plan.sh` at `aa8cd0d3` and at this step's head gives the same blob, `f8a4c25d`; the `RUNNABLE_VERBS` literal and `SCHEMA_VERSION` are therefore unchanged, and no corpus record can move at this step |
| **Step 7 — this plan, through the executor (C4, hermetic)** | The parent tree on its own plan gives `28 PASS / 12 FAIL / 12 SKIP / 0 UNRUNNABLE / 1 ERROR over 53 record(s)`. The step-7 tree on this plan, with this update, gives **`32 PASS / 8 FAIL / 12 SKIP / 0 UNRUNNABLE / 1 ERROR over 53 record(s) (42 per-issue row(s), 6 cross-issue, 5 always-on) — not graded by this run: 12 SKIP (11 declared-deferred, 0 no command in method, 1 other) and 0 UNRUNNABLE; could not evaluate: 1 ERROR`**. As predicted, exactly 4 of 53 records change verdict, each FAIL → PASS: #6685 AC-1 (`count=29`), AC-2 (`count=12`), AC-3 (`count=24`) and AC-4 (`count=6`). Not predicted: two rows keep PASS with their count one higher, #6893 AC-2 (47 → 48) and #6848 AC-2 (53 → 54), because G18's new header entry names both labels; the provenance record's line count moves. The JSON roll-up reads `records` 53, `cross_issue_records` 6, `always_on_records` 5, `no_command` 0 and `skip_other` 1, with `stream_state` fetched and 48 of 48 records read. The one ERROR stays FCM-COVERAGE `diff-unresolvable`, and the other SKIP is PROV-DELTA |
| **Step 7 — integration criteria** | INT-1: the fixture's declared rows read `deferred`/SKIP `declared-deferred`; V6180-AC5a and V6180-AC5b are green (G14 12 of 12). INT-2: the declared rows carry no command span (G20's authoring arm), and the route precondition observes control AC-2 on the residual. INT-3: fixture AC-3 and the three cited v4.46 rows read the no-command SKIP; both unterminated-quote controls read UNRUNNABLE `shell-operator:"`; the padded row reads ERROR `no-operand:test`; V6854-AC1 b and V6854-AC3 are green (G19 44 of 44). INT-4: `#3616` AC-3 and `#2577` AC-6 read the no-command SKIP, naming no tool. INT-7: G15 30 of 30 and G18 31 of 31. V6236-AC4 stays green (13 of 13) |
| **Step 7 — FM-1, re-measured** | The per-issue guard reads verb-initial prose as a named read. Four per-issue twins and the one corpus row, v3.65 `#99` AC-3, read the no-command SKIP. The seven verb-initial cross-issue criteria read ERROR (3) or UNRUNNABLE (4); that is O-1, #6236's at step 10. Control: the same probe on the Stage-4 pin executor reads the four twins ERROR `matcher-exit-3`, ERROR `matcher-exit-2` and two unclassified ERRORs, and all 8 corpus uses ERROR, as the #7665 review measured |
| **Step 7 — the ADR and the index** | `check-adr-durability.py --diff-base aa8cd0d3` → COUNT 0, SCANNED 206 (sensitivity: a run-directory copy of the partition record with a planted commit SHA in Decision 12 → R2-SHA, COUNT 1; the unmodified copy → COUNT 0). `generate-adr-index.py --verify` → COUNT 0, so no regeneration is owed (sensitivity: a copy with ADR-208's title drifted → DRIFT, COUNT 1). Issue references: 20 in the partition record, all under `## References`, each an issue and none a pull request (control: the release PR's number resolves to a pull request); a replica of the placement rule reads 0 outside the block. The fixtures' synthetic ids sit under their whole-file override. CI's ADR durability, ADR-number integrity and Issue-reference validity gates passed on `19bacff0` |
| **Step 7 — C3 package cascade** | `core/deploy/tools/build-skill-packages.sh --skills-for-paths`, with the step's 5 paths on stdin (the diff from `aa8cd0d3`, plus this plan), returns 0 skills. Control: `operations/skills/intake-desk/SKILL.md` returns `intake-desk`. No package is rebuilt |
| **Step 7 — links** | `python3 core/deploy/tools/check-doc-links.py --require-targets` over the partition ADR, the two fixtures and this plan: 0 findings, exit 0. `check-release-links.py --check-anchors --images` over the same four files: 0 broken; `--plan-depth-lint` on this plan: 0. Control: a planted workspace-rooted link to a missing file, in a copy of the partition ADR, returns 1 finding from each checker |
| **Step 7 — SIGPIPE idiom and identity** | The SIGPIPE gate's pattern block, copied from the workflow and joined as bash joins it, with BSD grep, over the step's 283 added shell lines: 0 (sensitivity: each idiom alone → 5 of 5; specificity: `x \|\| true` → 0). An identity and public-surface scan of every added line (448, this plan's update included) and each of the step's commit messages: 0 hits beyond each message's one noreply trailer (sensitivity: 4 of 4 planted lines; a clean line → 0). CI's SIGPIPE-idiom, Depersonalization and Commit-message depersonalization gates passed on `ae3ea050` and `19bacff0` |
| **Step 7 — runtime suite (map row 6)** | The step's paths — the suite and its two fixtures under `release/tools/tests/`, the partition ADR and this plan — match no row of the selection map: row 4's `release/tools/*.sh` does not reach `tests/` (the residual #6876 closes). The selection is therefore row 6, the honest `test-run/suite-skip`, and the explicit suite runs above are this step's runtime evidence (R8). Control: the same map sends `release/tools/verify-release-plan.sh` to row 4. CI on `ae3ea050` and `19bacff0`: ARM A **74 of 74**, and the reconcile reads EXPECTED-RESIDUAL (exit 4), as at the parent. One `test-run/suite-skip` event emitted and read back |
| **Step 8 (#6876) — RED, then GREEN, each predicted before its run** | Stub roots, each a `git archive` of the tree with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` each prefixed by a logging `exit 97` line, the original text kept. **The resolver run** — the Stage-7 arms, run on the reference resolver: plain `git diff --name-only --no-renames <empty tree> HEAD -- ':(top,glob)<pattern>'` commands, one per pattern, read by a script that runs no matcher of its own — on the parent's map: **6 FAIL / 8 PASS**, the FAILs being AC-1 twice, AC-5, AC-4 and the two config-template controls; on the map as landed: **14 PASS / 0 FAIL**. **The connector:** `--self-test` exits 2 at the parent (`FATAL (exit 2): unknown argument: --self-test`), and exits 0 with "self-test OK (5 assertions passed)" on `ea83ed39`. **CIAC-5:** FAIL `co-occurrence count=0 (wanted == 1)` on the parent's stub, PASS `count=1 (== 1)` on `efacc6ac`'s. **Arm C, armed red:** with the self-test and without the exclusions line, `check-selftest-coverage.py --reconcile` names exactly 1 uncovered advertiser, the connector; with the line, ARM C PASSED; the verdict is EXPECTED-RESIDUAL (exit 4) throughout, as at the parent. Each figure matched the prediction written before its run, and the stub logs stayed empty |
| **Step 8 — the resolver run (AC-1, AC-2, AC-4, AC-5)** | Over the 2,087 tracked paths at the parent, with the map as landed: the 17 suites under `release/tools/tests/` and the 2 under `core/deploy/tools/tests/` select row 6; the 8 skill scripts select row 7; the 5 runnable fixtures select no row; no path ties. Controls: the parent's row-4 globs match 0 of the 17 suites under the resolver and all 17 under `fnmatch`; the match-nothing pattern `core/skills/*/scripts/tests/*.sh` selects 0; `docs/INSTALL.md` selects no row, `core/deploy/compose.py` row 1, `core/deploy/tools/check-doc-links.py` row 4, `core/hooks/tests/test-runner.sh` row 3, both config templates under `core/config/` row 5, and `core/hooks/.mode.template` row 3. Against the parent's map read by `fnmatch`, 91 paths change their row, in 9 classes; the PR body names every one (AC-3) |
| **Step 8 — the connector's self-test and its seeded failures** | Run by its repository-relative path with stdin on the null device: 5 of 5, stderr empty. M-A, the unknown-argument arm made to exit 0 (proved at 1 site): exit 1, "self-test FAIL: an unknown argument must exit 2 (rc=0)". M-B, the enabled path made to print the key as well (proved at 1 site): exit 1, "self-test FAIL: the enabled path must exit 0 and never print the key (rc=0)". Each mutation was applied to the committed file, run and reverted; the tree read clean after each, and the self-test passed again. The seven other skill scripts are unchanged by this step |
| **Step 8 — the package (R2)** | `build-skill-packages.sh --skills-for-paths` names `finops-usage-extractor` for the connector. The rebuild moves the sidecar from `a0d81d40…` to `1eff71e0…`, and exactly one of the archive's 40 members changes, the connector, from 2,801 to 5,075 bytes (control: the old archive against itself, 0). Freshness by content, without the deploy check: `build-skill-packages.sh --root` on a stub of `ea83ed39` reproduces `1eff71e0…` (sensitivity: one appended comment line in the stub's connector moves it to `ef9b2f3c…`), and the real tree stayed clean. CI's Skill package content-freshness gate passed on `ea83ed39`. The SKILL.md's description reads 1,024 characters after the validator's strip, unchanged by this step |
| **Step 8 — the self-test coverage engine** | `check-selftest-coverage.py --reconcile` at the parent: ARM B PASSED (77 paths), ARM C PASSED, 1 unwired suite under Arm D (`ac3_concurrent_load.sh`), ARM E PASSED, EXPECTED-RESIDUAL (exit 4); at this head the same, with 16 exclusions in force where there were 15. The engine's own `--self-test`: 63 of 63. CI's discovered-tool self-tests on `ea83ed39`: the engine's self-test 63 of 63, ARM A **74 of 74**, ARM C PASSED, EXPECTED-RESIDUAL (exit 4) |
| **Step 8 — the executor suite (no executor, suite or fixture byte changes)** | The suite ran by its repository-relative path from each stub's root, with stdin on the null device, through a harness that sets the child's working directory. This head: **485 passed / 2 failed**; the parent `ab5152a0`: **485 / 2**; 487 of 487 outcome lines identical, in order (sensitivity: one flipped line reads 1 differing). By group: G12 35, G13 13 (V6236-AC4), G14 12, G15 30, G16 32, G17 43, G18 31, G19 44 and G20 28, each with 0 failures. The 2 are P1 and M9's control, which need a repository. The stub logs stayed empty. CI on the macOS smoke job: `ea83ed39` **489 passed / 0 failed** |
| **Step 8 — this plan, through the executor (C4, hermetic)** | The parent tree on its own plan gives `32 PASS / 8 FAIL / 12 SKIP / 0 UNRUNNABLE / 1 ERROR over 53 record(s)`. This head, with this update, gives **`33 PASS / 7 FAIL / 12 SKIP / 0 UNRUNNABLE / 1 ERROR over 53 record(s) (42 per-issue row(s), 6 cross-issue, 5 always-on) — not graded by this run: 12 SKIP (11 declared-deferred, 0 no command in method, 1 other) and 0 UNRUNNABLE; could not evaluate: 1 ERROR`**, as predicted: exactly 1 of 53 records changes verdict, CIAC-5, FAIL → PASS `co-occurrence count=1 (== 1)`, and the provenance record's line count moves. #6876's five rows stay declared-deferred SKIP, for Stage 7's resolver run and Stage 8's named reads, and #7494 AC-1 stays FAIL `count=0`: this step adds no "namespace" to stage-08. The JSON roll-up reads `records` 53, `cross_issue_records` 6, `always_on_records` 5, `no_command` 0 and `skip_other` 1, with `stream_state` fetched and 48 of 48 records read. The matrix parses `declared=50 interpreted=50 obligations=6 excluded=9 conditional=0 uninterpreted=0 pathless=0 prose_led=0` on a copy outside the corpus with an empty delivered set (control: a planted conditional label → `obligations=5 conditional=1`). `check-ac-binding.py --ordinals-only` → VERDICT BOUND. One double-brace `RELEASE_VERSION` placeholder. The one ERROR stays FCM-COVERAGE `diff-unresolvable`, and the other SKIP is PROV-DELTA |
| **Step 8 — the ADR and the index** | `renumber-adr.py --detect`: `ANCHOR 206 · NEXT-FREE 207 · CLAIMED-SET-BRANCH-ONLY 207,208`; the record took the next number contiguous within the branch, and after the commit its claim reads BINDS. `generate-adr-index.py --verify`: MISSING, COUNT 1, before `--write`; COUNT 0 after. `check-adr-durability.py --diff-base ea83ed39`: COUNT 0 over 207 records, with the section rule active (sensitivity: a copy with a planted SHA and a planted live count → R2-SHA and R2-COUNT, COUNT 2). The mainline's ADR set plus this branch's three records: 1 to 209, 0 gaps, 0 duplicates. 7 issue references, all under `## References`, each an issue (control: the release PR's number resolves to a pull request). CI's Repository integrity passed on `fc6a3af8`, its ADR durability, ADR-number integrity and Issue-reference validity jobs included |
| **Step 8 — links, host binding, SIGPIPE, identity** | `check-doc-links.py --require-targets` over the map, stage-06/07/08, the ADR and the index: 0 findings. `check-release-links.py --check-anchors --images` over the same: 0 broken, and 1 missing anchor that predates this step, in stage-06's Inputs line (warn-mode). Check 42's primitive over the four docs: FINDINGS 0. Sensitivity: a copy of the map with a planted broken link and a planted "the canonical mechanism is `git diff`" line → 1 and 1. SIGPIPE: 0 of the connector's 33 added lines carry a pipe at all (control: the file's 2 pre-existing pipe lines). Identity: 0 hits over every added line and each commit message beyond its noreply trailer (sensitivity: 4 of 4 planted lines; specificity: 0 of 1 clean line). CI's Repository integrity, Doc-link check, Release link check and Reference durability passed on `efacc6ac`, `ea83ed39` and `fc6a3af8` |
| **Step 8 — C3 package cascade** | `build-skill-packages.sh --skills-for-paths` over the step's 12 paths (the diff from `ab5152a0`, plus this plan): `finops-usage-extractor`, and no other skill — the sensitivity arm the connector supplies. Specificity: the map and this plan alone name no skill. The package and its `.sha256` are rebuilt in this step (row above) |
| **Step 8 — the citation sweep (D34)** | [REFCASCADE: a case-insensitive sweep for `row[ -]6` not followed by a digit, `rows 1[–-]5`, `top-to-bottom` and `most-specific` over the map and stage-06/07/08 → pre 10 / post 1, the preserved frontmatter `purpose:`]. A tree-wide sweep for `row[ -]6` beside no-match wording finds only historical records: ADR-074, merged plans, and this plan's step-1b and step-7 evidence rows. CIAC-5's literal occurs exactly once in stage-07 |
| **Step 8 — runtime suite (map rows 7 and 2)** | The reference resolver over the step's own diff — one plain `git diff --name-only --no-renames ab5152a0 HEAD -- ':(top,glob)<pattern>'` command for each of the 20 patterns in rows 1 to 7, with the step's parent in place of the merge base so that the selection is this slice's — selects **row 7** for the connector and **row 2** for `core/deploy/allowlists/selftest-coverage-exclusions.txt`; the other 10 of the step's 12 paths match no row and select the no-match row. Control: the same invocations return those two paths, and the match-nothing pattern returns 0. **Row 7:** the connector's `--self-test`, 5 of 5 (rows above); one `test-run/suite-pass` event, `selected-by:glob-7`, emitted and read back. **Row 2:** the deploy suite — the `run:` steps of the install-tests workflow's Shell harness (macOS) job, each establishing its own sandbox — read from CI, which is authoritative for it: on `ea83ed39` the job passed, 42 of 42 steps, and every other job of that workflow run passed; one `test-run/suite-pass` event, `selected-by:glob-2`, emitted and read back. That runner does not read the exclusions list: its reader is row 4's engine, run above, armed red without the line and PASSED with it. **The no-match row is honest for the other 10:** the map, the three stage specs, the ADR, the index and this plan are documents; the workflow edit is comment-only — its parsed YAML is equal at the parent and this head (sensitivity: one perturbed `run:` step compares unequal), and 0 of its 20 changed lines sit outside a comment; the package and its `.sha256` carry the row-7 script, checked by content above and by CI's freshness gate |

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
| #6848 | A method the executor cannot run is UNRUNNABLE, naming a real tool; scope assertions get a native family; with #6893's round 2, a row reaches the deploy check only by declaring it | landed — step 5 |
| #6854 | A command-less row is a named SKIP; the roll-up counts its true population | landed — step 6 |
| #6685 | A documented-decision method on a per-issue row reaches its named SKIP | landed — step 7 |
| #6876 | The selection map has one grammar and reaches the tool suites and skill scripts | landed — step 8 |
| #7494 | Verdicts name their criterion namespace; the binder reads both heading forms | pending — step 9 |
| #6236 | A CIAC is linted gradable-or-declared at Stage 4; QC3.5 reads every emitted outcome | pending — steps 1b and 10 |

### Key decisions

- **D17 / D30:** the grading route lives in the method cell alone; a runnable probe outranks prose.
- **D18 / D19 / D40:** stdin isolation by body redirect plus refusal, with a DEGRADED tripwire; the one schema bump lands with #7531.
- **D21–D24 / D37 / D47:** UNRUNNABLE as a fifth, non-failing verdict inside one reconciled outcome partition, recorded in one partition ADR.
- **D50–D54:** #6893's round 2 lands in #6848's slice — the deploy check is reached by declaration only, and a declared row beside another command is partial.
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
- **#7840** — the round-2 design's Phase A6.5 adversarial review, whose fixes D53 adopted.
- **#7587** — the Stage-6 Engineering sub-task that authored this file (Engineering Commit 0 and #7531's slice).
- **#7638** — the in-flight sibling release PR observed at Commit 0 (shared version and ADR-number slots).
