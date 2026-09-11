---
title: Release Plan — deploy-tools-and-tests-batch (deploy tools and tests resolve repo, root, project and dimension correctly at their edges)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the concrete number binds only at the Stage-12 atomic claim)
milestone: deploy-tools-and-tests-batch
release_class: routine
reversibility: CHEAP / Confidence HIGH — every member is a bounded edit to a tracked tool, test or standard, plus one new ADR record; `git revert -m 1` of the merge restores `main` byte-for-byte. One limb is MODERATE: Slice A (#6355 / #5817 / #5832) is entangled across three files and is not independently revertible, so its granularity is the whole merge.
---
<!-- reference-durability: allow-link -->
<!-- The transcribed Stage-4 body carries zero markdown links (measured: 0 inline-link
     occurrences across 42,199 + 46,828 bytes, seeded sensitivity arm 0 -> 1). The marker
     covers the links this Engineering-authored head and tail add, every one of which is
     written in the workspace-rooted leading-slash form the ADR-092 claim-time rename
     requires. -->

# Release Plan — `deploy-tools-and-tests-batch`

**Milestone:** `deploy-tools-and-tests-batch` · hub sub-task **#7257** = Stage 4 plan source and the operator decision record (two **Decision Recorded** comments) · **#7330** = #6355's Stage 5 design source and its Phase A6.5 adversarial review · **#7341** = the Stage 6 Engineering sub-task that authored this file.
**Version identity:** **versioned** — bump-class **`minor`**; the concrete `vX.Y` binds only at the Stage-12 atomic claim per ADR-092, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp token and no other text. The Commit-0 version re-verify ran in full — see § Commit-0 Version Re-Verify Record.
**Topology:** D-C **SINGLE** — one release branch (`release/deploy-tools-and-tests-batch`), one PR opened at the first Engineering commit and held in draft until the last card lands, one merge, base `main`. This plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch. Force-push, including `--force-with-lease`, is prohibited on the shared release branch.
**Release class:** `routine` — rendered by the operator at the Stage-4 gate (**D-A**). Differentiation posture: engagement density **Light** · Stage 9 review depth **Standard, overridden to Deep for the `#6355 / #5817 / #5832` cluster** · Stage 5 activation bias **SKIP-where-trivial** (applied: 5 activate / 4 skip) · Stage 13 outcome-window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7257 — both parts — and is reconciled to the two **Decision Recorded** comments on that same sub-task (the Stage-4 plan-approval gate and the Collective Review scope-lock gate), to the Stage-5 design specification for #6355 posted on sub-task #7330, and to the Phase A6.5 adversarial review posted on that same sub-task. **The transcribed sections preserve the Stage-4 plan of record.** Where a later ratified disposition supersedes a Stage-4 value, the transcription is left standing and the **§ Deviation Log** records the delta with its authority — the plan is not rewritten backwards into agreement with decisions taken after it. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #7341, card #6355).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination. It sets the floor and binds no concrete number; the concrete number binds only at the Stage-12 atomic claim (ADR-092). The Stage-4 recorded determination was **v4.61** (anchor `v4.60` + minor bump), provisional; the Commit-0 re-verify recomputed the same value against fresh authoritative host state. See § Commit-0 Version Re-Verify Record. |
| **Date Created** | 2026-09-10 (Thursday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/deploy-tools-and-tests-batch` |
| **Baseline pin** | `origin/main` @ `a30838589583bcddf5f88183cfff1a8ea2475300` |
| **PR** | (opened as a draft at Engineering Commit 0; this release ships as a SINGLE PR) |
| **Milestone** | `deploy-tools-and-tests-batch` |

**Domain-practice provenance.** The `domain_practice` label determined at Stage-4 Phase A1.5 is carried in its Stage-4 position, inside § File Change Matrix, and is **not duplicated here** — one label, one home. Its determination is Form **X** (sourcing-exempt): every write-set path is an internal `pmo-platform` artifact, so no external body of practice is consumed and no Form-A citation exists to record. Dominant domain `software`; secondary `governance`.

---

## Commit-0 Version Re-Verify Record

The first Engineering spoke under SINGLE topology re-runs the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1** — refresh authoritative host state | **EXECUTED.** `git fetch --tags origin` then `git fetch origin main`. `origin/main` = `a30838589583bcddf5f88183cfff1a8ea2475300`. The Stage-4 baseline pin was `a3083858`; **the substrate did not move between Planning and Engineering** — zero commits landed on `main` in the interval, so the plan's pin and the Commit-0 base are the same commit. | `git rev-parse origin/main` |
| **2** — recompute next-free for bump-class `minor` | **EXECUTED. Next-free = `v4.61`.** `anchor()` = **v4.60**, the highest claimed version across every `claimed_set()` arm. `FLOOR(minor)` = `(4, 61)`; `v4.61` is absent from `claimed_set()`, so the walk terminates at the floor. | **Tag arm (binding)** — `git tag -l 'v*'` = **204** refs, `sort -V` max = `v4.60`, and `git tag -l 'v4.61'` returns empty; zero tags carry a major above 4. **Ledger arms (corroborating, all read via `git show origin/main:<path>`, never the worktree copy)** — `.version` = `v4.60`; `RELEASE_LOG.md` carries **0** occurrences of `v4.61`; `RELEASE_INDEX.md` carries **0**. |
| **3** — PROCEED / HALT on claimed-set membership | **PROCEED.** The planned version `v4.61` is **not** in the claimed set **and** equals the recomputed next-free — the conjunction the gate requires. No colliding tag and no colliding ledger row exists. | **Sensitivity arm** — the identical readers resolve `v4.60` as **present** on every arm: `git tag -l 'v4.60'` → **1**, `RELEASE_LOG.md` → **9** occurrences, `RELEASE_INDEX.md` → **1**. Membership detection demonstrably fires, so the subject zero is a measurement rather than a dead reader. **Specificity arm** — `git tag -l 'v9.99'` → **0** on the same non-empty 204-ref population, so the reader does not flag an absent near-miss shape. **The tag arm binds; a missing ledger row is corroboration and never authorization.** |
| **3b** — stamp-manifest assertion | **EXECUTED post-write, pre-commit.** `release/tools/claim-version.sh --verify-stamp deploy-tools-and-tests-batch` → **exit 0**, reporting `verify-stamp OK — deploy-tools-and-tests-batch carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))`. | Read-only and network-free — the identical pre-flight the Stage-12 atomic claim runs. The Header `**Version**` cell carries the unresolved stamp token and no other text, which is what the Stage-12 claim resolves and renames on. The token is deliberately written **once**, in that cell alone: the claim-time substitution is global, so a second prose occurrence would be rewritten into a sentence asserting that an already-resolved value is unresolved. |

**Why the number is recorded but not bound.** Step 2's `v4.61` is a Commit-0 *reading* of authoritative state, not a claim. Nothing is held between now and the merge; a concurrent release that merges first takes `v4.61` and this release's claim recomputes upward at the compare-and-swap. The Stage-4 plan names exactly this contingency at **R6**: the sibling `closeout-correctness-batch` release (PR #7253, draft at planning) carries the same provisional value. Recording the reading makes the Commit-0 PROCEED reproducible without asserting a reservation the allocation rule does not create. **The numbers in this section are deliberately not restamped later** — they are a reading at a named SHA, reproducible by re-running the recorded commands at that SHA.

**Date variable.** The Stage-5 spec evaluated the date-variable trigger and recorded it **N/A with reason**: this release creates no downstream load-bearing identifier carrying a `YYYY-MM-DD`. The one date Engineering produces is the new ADR's `date:` frontmatter **field** — a record field, not an identifier — stamped at authoring time from `date -u +%Y-%m-%d` and never copied out of a spec.

---

---

## Phase A0 — Triage→Design Re-Review artifact

```
stage: 4-planning
spoke_author: spoke:#7257
re_review_date: 2026-09-10
milestone: deploy-tools-and-tests-batch
baseline_pin: origin/main @ a3083858
rows_source: PT-1..4 re-derived  (G-PL5 cache MISS)
member_count: 9 open / 0 closed
effort_tier: standard
```

**G-PL5 cache-read → MISS.** MISS reason: *no marker-bearing comment from the trusted author set exists on this sub-task* — sub-task #7257 carries **0 comments** at read time. Mode O was invoked directly; no Mode R briefing was relayed. Per the stage spec, cache absence is never a FAIL: PT-1..4 were re-derived below. No currency operand was computed, because there is no recorded operand to compare against.

| # | Requirement | D1 knowledge-currency | D2 reference-currency | D3 premise-soundness | Class |
|---|---|---|---|---|---|
| #6174 | Arm A message distinguishes empty extraction from sentinel fault | current | file + symbol resolve | reproduces at `test_g1_form_family.sh:102` | **C1** |
| #6111 | Preserve assertions for 3 unasserted mode files | current | file + 4 call sites resolve | reproduces — 3 of 4 unasserted | **C1** |
| #5707 | Gate verdict independent of `GITHUB_REPOSITORY`; message names exact-match | current | **stale path** — see below | reproduces, both limbs | **C2** |
| #5817 | One shared dot-segment traversal predicate | current | all 3 walkers resolve | reproduces — 1 of 3 lacks the skip | **C1** |
| #5832 | Depth-1 file emits no self-referential `BELONGS_TO` | current | **imprecise attribution** — see below | reproduces at `stamp-node-frontmatter.py:391` | **C2** |
| #5556 | Script resolves its own absolute path before any `cd` | current | file + 3 sites resolve | reproduces at lines 120/137/143 | **C1** |
| #6242 | Guard detects a genuinely missing function, never a defined one | current | file + line resolve | reproduces at `test_deciders_carveout.sh:66` | **C1** |
| #6251 | Every §2.4 row enforced or visibly marked excluded | current | both files resolve | reproduces — bare `reflexive` absent from the list | **C1** |
| #6355 | `render_s2` emits a distinct resolved value per dimension | current | **stale line refs** — see below | reproduces at `compose-portfolio.py:587` | **C2** |

**Zero C3 classifications.** No premise was rejected; no Tier-0 escalation fires. Three C2 rows route **Tier 1 [ADJUST]** — a reference correction, not a scope change:

- **#5707 — A0.5 / G-PL1 CURRENCY-MISMATCH.** The body's Affected Files reads `.github/workflows/` — "the issue-ref gate step and its failure message". The gate has since been **extracted out of the workflow into `core/deploy/tools/check-issue-ref-validity.sh`**; that file's own header states it (*"It used to live as inline bash inside that job's `run:` block… This file is that logic lifted out verbatim… There is exactly ONE implementation."*). The milestone description already carries the correct path. **[ADJUST]** the issue's Affected Files to the tool path.
- **#5832 — attribution imprecision.** The body names `core/deploy/tools/backfill-relationship-edges.py — _project_of()`. That file does not define `_project_of`; it **imports** it at line 92 (`_project_of = _node._project_of`) from `stamp-node-frontmatter.py`, where it is defined at line 391. The edit site is the shared module. The milestone description is correct here and the issue body is not. **[ADJUST]** the issue's Affected Files.
- **#6355 — stale line refs.** The body cites `compose-portfolio.py:563-571`; the defect now sits at **574-589** (`render_s2`), with the invariant scalar at **587**. Same defect, drifted refs. **[ADJUST]** the citation.

**A0.6 / G-PL2 crisping:** all nine bodies pass the Gate-1 substantive checks (description actionable · change names files-or-protocols · AC verifiable). No crisping pre-gate fires.

**A0.7 / G-PL3 placement forward-check:** **SKIP** — this release authors no new files; every row in the File Change Matrix is an `edit` against a path that exists at the baseline. No not-yet-authored placement to re-home.

**A0.8 / G-PL4 empirical repro (batch, pinned `origin/main` @ `a3083858`):** **9 of 9 admit-still-valid.** Every member's headline defect was re-executed against the pinned baseline and reproduces. Zero `close-resolved`, zero `re-scope-changed`. Per-member evidence is in § Evidence. No card is drift/reconciliation-class (none matches `drift`/`reconcil`, none carries `project:governance-hygiene`, none sits under a drift-themed milestone), so the mandatory no-skip lane is empty and every card ran the general arm.

**Parallelization-Map currency check:** the milestone description carries **no** `## Parallelization Map (recorded YYYY-MM-DD)` H2. Per § Standing applicability the check is **suppressed** for a milestone that predates the convention — not a finding.

**A0 currency-decision confidence gate:** signal = **corroborated-and-grounded**. Three independent sources agree on the same composition delta (the live `gh` member set, the milestone description's own Composition Lock, and the nine per-member repro verdicts). Refresh outcome rendered: **no-op** — `issues_added` is 0, composition is locked, and no trigger T1–T6 fires. No PAUSE-TO-LEARN loop entered.

---

## Summary (30 seconds)

Nine live members, all nine defects **verified reproducing** against pinned `origin/main` @ `a3083858`. The release is coherent and shippable, but **three of the hub's inherited framings are wrong and the plan departs from them**:

1. **The milestone description's "no file contention" is false.** There is a real three-card contention cluster on two shared files — `compose-portfolio.py` (#5817 + #6355) and `stamp-node-frontmatter.py` (#5817 + #5832) — plus a shared-parser edit (`_frontmatter.py`, #6355's folded D-12 limb) that **8 tools import**, three of them other members' files. The description was written against the original six and never reconciled.
2. **Two cards are under-sized, for reasons only visible in the code.** #6355 is labelled `size:S` but carries **two** defects (its own `render_s2` fix plus the folded D-12 frontmatter-parser defect) — recommend **M**. #5707 is `size:S` but its target file carries an **oracle-parity self-test** that fails *any* behaviour change regardless of correctness, so the fix cannot be fixtured through the normal corpus — recommend **M**. Re-sized, the release is **21 pts**, still inside the 15–25 band.
3. **#6355 carries a `sanctioned-session-required` limb** if its governed dimension→metric mapping lands in the weekly-status-rollup skill reference. The plan recommends placing it in `portfolio-writeback-contract.md` instead, which keeps all nine cards `unconstrained`.

**D-C Branch Topology recommendation: SINGLE.** The contention cluster is the argument *for* one branch, not against it — three writers on two files across two branches is a merge conflict by construction, and the operator's standing preference ("a milestone ships as a single PR and a single merge") plus the milestone's own Success Indicator ("one PR") both point the same way.

**Release Class: `routine`** — re-derived by procedure, not inherited. **Quota Budget: PASS** (45% worst single batch), with a stated window-level caution.

---

## Dependency Graph

**Native GitHub dependency edges: zero.** Every member's Stage-2 triage recorded `blocks: 0 · blocked-by: 0`, and the milestone's own Step-3 dep walk found zero native edges. This is the *ticket* axis. The *file* axis below is where this release's real edges live — and it is directional.

```
                    ┌──────────────────────────────────────────┐
   SHARED SUBSTRATE │  #6355 (D-12 limb)                       │
                    │  core/deploy/tools/_frontmatter.py       │
                    │  read_frontmatter() — 8 importers        │
                    └───┬─────────────┬─────────────┬──────────┘
      substrate-before-consumer (soft, behavioural — not textual)
                        │             │             │
                        v             v             v
              ┌─────────────────┐ ┌──────────┐ ┌──────────────┐
              │ #5817           │ │ #5832    │ │ #6251        │
              │ discover_rollups│ │_project_ │ │lint_release_ │
              │ reads FM        │ │ of       │ │corpus reads  │
              └───┬─────────┬───┘ └────┬─────┘ │FM (weak)     │
                  │         │          │       └──────────────┘
   same-file ─────┘         └── same-file ──────┘
   compose-portfolio.py     stamp-node-frontmatter.py
        │                        │
        v                        v
   ┌──────────┐            (#5817 predicate extraction
   │ #6355    │             ∩ #5832 _project_of)
   │ render_s2│
   └──────────┘

   INDEPENDENT (zero shared files, zero edges — with each other or the cluster):
   #5707   #6111   #6174   #6242   #5556
```

**Edge inventory — five edges, all soft, zero circular chains.**

| Edge | From → To | Type | Basis |
|---|---|---|---|
| E1 | #6355 (D-12) → #5817 | substrate-before-consumer (soft) | `discover_rollups` calls `read_frontmatter` at `compose-portfolio.py:473`; #6355's D-12 limb changes that call's return value |
| E2 | #6355 (D-12) → #5832 | substrate-before-consumer (soft) | `stamp-node-frontmatter.py` imports `_frontmatter` |
| E3 | #6355 (D-12) → #6251 | substrate-before-consumer (**weak**) | `lint_release_corpus.py` imports `_frontmatter`, but #6251 edits only the banned-jargon term list — no frontmatter interaction. Recorded for completeness; **not** a sequencing constraint |
| E4 | #5817 ↔ #6355 (primary) | same-file contention | both write `core/deploy/tools/compose-portfolio.py` |
| E5 | #5817 ↔ #5832 | same-file contention | both write `core/deploy/tools/stamp-node-frontmatter.py` (conditional on the #5817 design choice — see § Contention Map) |

**Circular-chain probe:** the five edges form a DAG rooted at #6355's D-12 limb. E4 and E5 are undirected same-file adjacencies, not dependencies, and neither closes a cycle with E1/E2. **Zero circular chains** — probe record in § Evidence (PV-0..PV-7).

---

## Implementation Sequence

Ordering principle: **shared substrate first, then the contended files adjacent and largest-first, then the independents.** The substrate-first rule is what makes a regression attributable — if `_frontmatter.py` changes *after* `discover_rollups` is rewritten, a composed failure cannot be assigned to either change.

| # | Issue | Pts | Primary write | Why here |
|---|---|---|---|---|
| 1 | **#6355** (D-12 limb) | — | `core/deploy/tools/_frontmatter.py` | Shared substrate, 8 importers. Land the parser fix before anything that reads through it |
| 2 | **#6355** (primary limb) | 2→**4** | `core/deploy/tools/compose-portfolio.py` · `core/standards/portfolio-writeback-contract.md` | Same card; `render_s2` is in the contended file, so it leads the cluster |
| 3 | **#5817** | 4 | `core/deploy/tools/compose-portfolio.py` · `stamp-node-frontmatter.py` (+ `build-doc-index.py`, conditional) | Adjacent to #6355 on `compose-portfolio.py`; adjacent to #5832 on `stamp-node-frontmatter.py` — it is the bridge card and must sit between them |
| 4 | **#5832** | 2 | `core/deploy/tools/stamp-node-frontmatter.py` | Adjacent to #5817 on the second contended file |
| 5 | **#5707** | 2→**4** | `core/deploy/tools/check-issue-ref-validity.sh` | Highest design risk (oracle-parity). Sited after the cluster so a design stall does not block the contended files |
| 6 | **#6251** | 2 | `core/deploy/tools/lint_release_corpus.py` · `release/references/standards/release-notes-standard.md` | Independent; two-surface reconciliation |
| 7 | **#6111** | 2 | `core/deploy/tests/test_refresh_hooks.sh` | Independent |
| 8 | **#6174** | 1 | `core/deploy/tests/test_g1_form_family.sh` | Independent |
| 9 | **#6242** | 1 | `release/tools/tests/test_deciders_carveout.sh` | Independent |
| 10 | **#5556** | 1 | `core/deploy/tools/start-skill-editor-session.sh` | Independent, XS, zero coupling — safest last |

**This differs from the milestone description's `## Internal sequence`** (`#6174 → #6111 → #5707 → #5817 → #5832 → #5556`), which covered six members and was built on the "no file contention" premise. That premise is false, so the ordering it produced does not hold. The sequence above is contention-derived and covers all nine.

**Two slices, not ten steps:**

- **Slice A (serial, contended):** steps 1–4 — #6355, #5817, #5832. Three cards, two shared files, one shared substrate. **Must be serial.**
- **Slice B (parallel-safe):** steps 5–10 — #5707, #6251, #6111, #6174, #6242, #5556. Six cards, **zero shared files** with each other or with Slice A.

---

## Stage Applicability Matrix

**Operator stance applied (sub-task item 6):** Stages 7 and 8 run as real stages. A skip must rest on the applicability rule — *no functional impact* — never on "CI already covers it". **Every member here changes the behaviour of a tool, a check, a test, or a self-test**, so Stages 7 and 8 apply to all nine with no exceptions.

| Issue | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9 | S12 | S13 | Stage-5 rationale |
|---|---|---|---|---|---|---|---|---|
| #6355 | **YES** | YES | YES | YES | YES | YES | YES | Two folded defects; non-1:1 dimension→metric mapping to resolve; contract rewrite; A3.5 placement decision |
| #5817 | **YES** | YES | YES | YES | YES | YES | YES | "One shared predicate" is a design choice — minimal patch (1 file) vs. extract-shared-helper (3 files). Write set is not determined until this is decided |
| #5707 | **YES** | YES | YES | YES | YES | YES | YES | Oracle-parity constraint forbids the obvious fixture route; the sanctioned corpus-free pattern must be designed before code |
| #5832 | **YES** | YES | YES | YES | YES | YES | YES | The fix site is a **shared** function with 2+ consumers — fix in `_project_of` (blast radius) vs. guard at the `BELONGS_TO` planning path (local) is a real design decision |
| #6251 | **YES** | YES | YES | YES | YES | YES | YES | Explicit three-way design choice in the body: enforce `reflexive` vs. mark-excluded; derive the count vs. assert it; define overlap-finding cardinality |
| #6174 | SKIP | YES | YES | YES | YES | YES | YES | Message-text widening; the AC prescribes both branches and their arms. No design uncertainty |
| #6111 | SKIP | YES | YES | YES | YES | YES | YES | Mirrors the existing `.mode` preserve assertion three times; the pattern already exists in the same file |
| #6242 | SKIP | YES | YES | YES | YES | YES | YES | The AC names the exact method (`declare -F "$fn" >/dev/null`) and both arms. Single-line change |
| #5556 | SKIP | YES | YES | YES | YES | YES | YES | Resolve SELF from `BASH_SOURCE[0]` before any `cd` — **69 in-repo precedents** for the idiom. Trivial |

**Stage 5: 5 activated · 4 skipped.** This matches the `routine` class's `SKIP-where-trivial` activation bias — the four skips are genuinely trivial with prescribed methods, and none of the five activations is borderline.

---

## File Change Matrix

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-10, domain: software }`

*Classification rationale (A3-time, from this matrix):* every write-set path is an internal pmo-platform artifact — deploy tooling, test harnesses, and two platform standards. The dominant deliverable class is **`software`** (7 of 9 cards edit executable tooling or test code); the secondary class is `governance` (2 standards edited as the documentation half of a code fix). Sourcing-exempt per § 5.7 Form X; domain-classified regardless.

### Unconditional edits

| Issue | Path | Intent |
|---|---|---|
| #6355 | `core/deploy/tools/_frontmatter.py` | edit |
| #6355 | `core/deploy/tools/compose-portfolio.py` | edit |
| #6355 | `core/standards/portfolio-writeback-contract.md` | edit |
| #5817 | `core/deploy/tools/compose-portfolio.py` | edit |
| #5832 | `core/deploy/tools/stamp-node-frontmatter.py` | edit |
| #5707 | `core/deploy/tools/check-issue-ref-validity.sh` | edit |
| #6251 | `core/deploy/tools/lint_release_corpus.py` | edit |
| #6251 | `release/references/standards/release-notes-standard.md` | edit |
| #6111 | `core/deploy/tests/test_refresh_hooks.sh` | edit |
| #6174 | `core/deploy/tests/test_g1_form_family.sh` | edit |
| #6242 | `release/tools/tests/test_deciders_carveout.sh` | edit |
| #5556 | `core/deploy/tools/start-skill-editor-session.sh` | edit |

### CONDITIONAL rows

| Issue | Path | Intent | Condition token |
|---|---|---|---|
| #5817 | `core/deploy/tools/stamp-node-frontmatter.py` | edit | `CONDITIONAL:shared-predicate-extracted` |
| #5817 | `core/deploy/tools/build-doc-index.py` | edit | `CONDITIONAL:shared-predicate-extracted` |
| #6355 | `operations/skills/weekly-status-rollup/references/metric-registry.md` | edit | `CONDITIONAL:mapping-homed-in-skill-reference` |
| #5832 | `core/deploy/tools/backfill-relationship-edges.py` | edit | `CONDITIONAL:guard-sited-at-consumer` |

Each condition resolves at its card's Stage 5. Per § 6 clause 5, **a fired conditional is promoted into the unconditional set in the same commit**, carrying its concrete path — and a row left CONDITIONAL after its condition resolved is an authoring defect, not an exemption.

### Read-only inputs

| Issue | Path | Intent |
|---|---|---|
| #6111 | `docs/scripts/setup-workspace.sh` | READ |
| #6355 | `operations/skills/weekly-status-rollup/references/metric-registry.md` | READ |
| #5817 | `core/deploy/tools/build-doc-index.py` | READ |
| #6242 | `release/tools/lib/deciders-carveout.sh` | READ |

### Release-wide explicit non-scope

| Path | Intent | Why named |
|---|---|---|
| `.github/workflows/repo-integrity.yml` | NOT EDITED | #6242's notes ask whether the shipped `sigpipe-idiom` gate would catch its shape. **It would** — the gate's declared invariant covers `any grep \| head` and `any writer \| grep -q`. The gate is *added-lines-only* by design, so a pre-existing site escaped it. That is correct gate behaviour, not a gate defect, so no workflow change is in scope |
| `core/deploy/allowlists/script-execution-allowlist.txt` | NOT EDITED | The new-executable companion obligation does not fire — this release adds **zero** `add` rows for tracked executables. Every row is an `edit` to a file that already exists and is already wired |

**No `add` rows and no `delete` rows in this release.** Enumerated over the three-value `add | edit | delete` enum; only `edit` is present. Consequently: the script-execution-allowlist obligation is inapplicable by construction, and the `delete`/destructive-control class in A3.5 is empty.

---


### Engineering Commit-0 matrix reconciliation

**The transcribed matrix above is the Stage-4 plan of record and is left standing.** This block is additive and attributed: it promotes the conditional rows whose conditions have since resolved, and declares the paths the Stage-5 designs added after Stage 4 closed. The Stage-4 authoring contract requires exactly this — *a fired conditional is promoted in the same commit, carrying its now-concrete path*, and *a row whose declared condition turns out to be false while the file is edited anyway must be promoted with its real basis recorded, not left shielded by a predicate that never fired*. Nothing above is edited or deleted.

#### Conditional resolutions

| Issue | Path | Condition token | Resolved | Disposition |
|---|---|---|---|---|
| #5817 | `core/deploy/tools/stamp-node-frontmatter.py` | `CONDITIONAL:shared-predicate-extracted` | **FIRED** — **D-D** rendered *shared-predicate extraction* at the Stage-4 gate rather than deferring it | **PROMOTED to unconditional `edit`.** |
| #5817 | `core/deploy/tools/build-doc-index.py` | `CONDITIONAL:shared-predicate-extracted` | **FIRED** — same decision | **PROMOTED to unconditional `edit`.** |
| #6355 | `operations/skills/weekly-status-rollup/references/metric-registry.md` | `CONDITIONAL:mapping-homed-in-skill-reference` | **DID NOT FIRE** — **D-E** homed the governed dimension→metric mapping in `core/standards/portfolio-writeback-contract.md` | **Stays out of the obligation set and stays `READ`-only.** The path keeps its Stage-4 read-only row; #6355's Stage-5 spec forbids editing it, and an edit would reclassify the card `sanctioned-session-required`. |
| #5832 | `core/deploy/tools/backfill-relationship-edges.py` | `CONDITIONAL:guard-sited-at-consumer` | **UNRESOLVED at Commit 0** | Resolves at #5832's own Engineering commit; its spoke promotes or retires the row there. Recorded here as open rather than silently assumed either way. |

#### Stage-5 additions — #6355 (declared by this spoke, at this commit)

| Issue | Path | Intent | Basis |
|---|---|---|---|
| #6355 | `core/deploy/tools/README.md` | edit | Row 67's `Used by` cell holds the **same OLD value** as the `_frontmatter.py` docstring consumer list. The Stage-5 § 5.6 cascade sweep classified it **UPDATE**: fixing the docstring and leaving this is the annotate-and-defer failure the sweep exists to catch. Hub coordination determination assigns the `Used by` cell to this card's C1. |
| #6355 | `core/ADRs/ADR-195-frontmatter-laxity-is-constrained-at-the-consumer.md` | add | The D-12 decision record, authored by Engineering at C2. **This is the release's first `add` row**, which falsifies the Stage-4 line *"No `add` rows and no `delete` rows in this release"* — recorded as **DEV-6** below rather than papered over. The new-executable companion obligation still does **not** fire: the obligation is `*.sh`-scoped and this is a markdown record. **Module corrected to `core/` at Stage 7 — see DEV-16**; this row was declared against `release/ADRs/` at Commit 0 and the record was filed, correctly, under `core/ADRs/`. |

**Mover-set is still empty.** An `add` at a fresh path relocates nothing, so the Stage-4 structural-blast-radius sub-audit's conclusion (`SURFACE(R)` reduces to the version-slot token) survives the two rows above. Zero `delete` rows and zero renames remain correct.

#### Stage-5 additions — sibling cards (declared by their own Engineering spokes)

The Collective Review scope-lock recorded that **two `add` rows enter this release** — *a parity test, and an ADR*. The ADR is #6355's, declared above. The parity test belongs to **#5817** and its concrete path is set by that card's Stage-5 design, which this spoke has not read and does not own. Per the serial sequence, #5817's Engineering spoke promotes its own row at its own commit. **This is declared as a known-pending obligation, not as an absence** — a bare silence here would be indistinguishable from no obligation existing.
---

## Agent-Editability Read

**Derivation** — controls read at commit `a3083858`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: **2 blocks observed** (at lines 703 and 734). Arms quoted verbatim:

  *Block 1 (anchored, lines 703–719):*
  ```
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
  ```
  *Block 2 (repository-membership, anchor-free, lines 734–742):*
  ```
  */CLAUDE.md | */OPERATIONS.md | */RELEASE_PROTOCOL.md      guarded by is_platform_worktree
  ```

  **Unreachable-arm discard:** the three `.claude/` arms project to repo-relative `.claude/settings.json`, `.claude/hooks/*`, `.claude/rules/*`, and **the repository tracks no `.claude/` files at all** — the hook's own comment states this at lines 730–731 ("Those name the DEPLOYED security surface at the workspace root; the repository tracks no `.claude/` files"). Verified against the tracked index at the read SHA. Discarded for this release, and re-derived rather than carried forward. Block 2 is the operative arm for in-repo work: it is basename-anchored to exactly three documents inside a platform worktree.

- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `'(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$'`; arming key = `skill_discipline_migrated_v10_2: true` (grep at line 257, failure branch `exit 0  # not yet gated`); exemption list resolves at `${HOOK_DIR}/../skill-editor-exemption-list.txt` — **`undetermined`** (the deployed hook directory does not exist on this host, so the file the hook actually reads cannot be reached; the in-repo path is not that file and was not substituted).

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #6355 | `core/deploy/tools/_frontmatter.py` | no | conjunct 1 false | `unconstrained` | see below | ordinary Engineering spoke |
| #6355 | `core/deploy/tools/compose-portfolio.py` | no | conjunct 1 false | `unconstrained` | | ordinary Engineering spoke |
| #6355 | `core/standards/portfolio-writeback-contract.md` | no | conjunct 1 false | `unconstrained` | | ordinary Engineering spoke |
| #6355 | `operations/…/weekly-status-rollup/references/metric-registry.md` **(CONDITIONAL)** | no | **1 ∧ 2 true, 3 `undetermined`** | **`sanctioned-session-required`** | **`sanctioned-session-required`** *if the conditional fires*, else `unconstrained` | `sanctioned-session: pmo-skill-editor` *(conditional)* |
| #5817 | `core/deploy/tools/compose-portfolio.py` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #5817 | `core/deploy/tools/stamp-node-frontmatter.py` (COND) | no | conjunct 1 false | `unconstrained` | | ordinary Engineering spoke |
| #5817 | `core/deploy/tools/build-doc-index.py` (COND) | no | conjunct 1 false | `unconstrained` | | ordinary Engineering spoke |
| #5832 | `core/deploy/tools/stamp-node-frontmatter.py` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #5832 | `core/deploy/tools/backfill-relationship-edges.py` (COND) | no | conjunct 1 false | `unconstrained` | | ordinary Engineering spoke |
| #5707 | `core/deploy/tools/check-issue-ref-validity.sh` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6251 | `core/deploy/tools/lint_release_corpus.py` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6251 | `release/references/standards/release-notes-standard.md` | no | conjunct 1 false | `unconstrained` | | ordinary Engineering spoke |
| #6111 | `core/deploy/tests/test_refresh_hooks.sh` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6174 | `core/deploy/tests/test_g1_form_family.sh` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6242 | `release/tools/tests/test_deciders_carveout.sh` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #5556 | `core/deploy/tools/start-skill-editor-session.sh` | no | conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |

**Which conjunct decided, for the one gated row.** Conjunct 1 (scope regex): **true** — `operations/skills/weekly-status-rollup/references/metric-registry.md` matches the `references?/.+\.md` alternative. Conjunct 2 (arming key): **true** — `operations/skills/weekly-status-rollup/SKILL.md` carries `skill_discipline_migrated_v10_2: true` in its frontmatter (read directly; control arm — `name:` also present, so the read was non-empty). Conjunct 3: **`undetermined`**, and per the spec's stated fail-safe rule *conjuncts 1 and 2 true with conjunct 3 `undetermined` classifies `sanctioned-session-required`*. The gate's mode is irrelevant to this classification. **Every other card's path fails conjunct 1**, which is what decided them — no path outside a `skills/` subtree can reach this control.

**The per-path split is retained deliberately, and it presents a scope decision at planning.** #6355 is partly `unconstrained` and, conditionally, partly gated. **Recommendation: home the governed dimension→metric mapping in `core/standards/portfolio-writeback-contract.md`, not in the skill reference.** That satisfies #6355's AC-2 ("mapped to their backing metrics in a governed statement" — a standard *is* the governed surface, and it is already in the card's write set), keeps the skill reference read-only, and leaves the whole release `unconstrained` with no per-session overhead. Routed as **D-E** below.

**Note on `undetermined`.** It is recorded as `undetermined`, never as `absent`. The exemption list may well be empty or may not list this skill — but the planner could not read the file the hook reads, and resolving that unknown *toward* the constraint is what the derivation rule requires. If the operator resolves it (by reading the deployed list), and `weekly-status-rollup` is exempt, the conditional row drops to `unconstrained` and D-E becomes moot.

**An `unconstrained` row means no control refuses the write. It never means the change is ungoverned** — all nine remain governed by the release pipeline.

---

## Contention Map

**The milestone description's `## Notes` line — "Six files under core/deploy/{tools,tests}; no file contention" — is false for the live nine.** It was written against the original six, before #6242, #6251 and #6355 were milestoned. Corrected map:

### Within-release contention

| Contended path | Writers | Functions / regions | Class | Resolution |
|---|---|---|---|---|
| `core/deploy/tools/compose-portfolio.py` | **#5817**, **#6355** | `discover_rollups` (467–476) · `render_s2` (574–589) | `line-range-overlap` — **disjoint ranges, same file**, ~90 lines apart | Sequence adjacent in Slice A; single branch. No scope split needed |
| `core/deploy/tools/stamp-node-frontmatter.py` | **#5817** *(conditional)*, **#5832** | shared traversal predicate near `iter_corpus_files` (651–662) · `_project_of` (391–393) | `line-range-overlap` — **disjoint ranges**, ~260 lines apart. Fires only if #5817's Stage 5 chooses predicate extraction | Sequence adjacent (#5817 → #5832); resolve the condition at #5817's Stage 5 **before** #5832 is dispatched |
| `core/deploy/tools/build-doc-index.py` | **#5817** *(conditional)* | walk at 385–390 | `single-pr` | No contention — one writer |
| `core/deploy/tools/backfill-relationship-edges.py` | **#5832** *(conditional)* | `BELONGS_TO` planning path (247–260) | `single-pr` | No contention — one writer |

**Every other write-set path has exactly one writer.** Enumerated over all 16 rows of the File Change Matrix (12 unconditional + 4 conditional): 2 paths carry 2 writers, 14 carry 1. Probe record in § Evidence.

### Shared-substrate contention (the axis a path-overlap scan cannot see)

`core/deploy/tools/_frontmatter.py` has **one writer** (#6355's D-12 limb) and therefore reads as clean on a path-overlap scan — but it is imported by **8 tools** in `core/deploy/tools/`, three of which are other members' write-set files:

| Importer | Member that writes it | Coupling |
|---|---|---|
| `compose-portfolio.py` | **#5817**, #6355 | `discover_rollups:473` calls `read_frontmatter` — a changed return value changes what `discover_rollups` discovers |
| `stamp-node-frontmatter.py` | **#5832**, #5817 (cond.) | imports `_frontmatter` |
| `lint_release_corpus.py` | **#6251** | imports `_frontmatter` — but #6251 edits only the jargon term list. **Weak; not a sequencing constraint** |
| `build-doc-index.py` | #5817 (cond.) | imports `_frontmatter` |
| `backfill-relationship-edges.py` | #5832 (cond.) | imports `_frontmatter` at line 88 |
| `check-doc-frontmatter.py` · `check-rules-budget.py` · `check-version-anchors.py` | — | not in this release's write set; **regression surface only** |

**This is the single most important thing in this plan, and no path-overlap scan would surface it.** A one-line change to `read_frontmatter` propagates to eight consumers, five of which this release also edits. It is the reason the sequence puts #6355's D-12 limb at step 1 and the reason Slice A is serial.

**Constraint on the D-12 fix:** `core/deploy/tools/fixtures/frontmatter-strip/` exists, and `release/ADRs/ADR-159-one-frontmatter-strip-bound-to-a-conformance-fixture.md` governs it. There is also a shell twin at `release/tools/lib/frontmatter-strip.sh`. The D-12 fix must be designed against that ADR and its conformance fixture — a Python-side change that diverges from the shell twin is a new defect. **Routed to #6355's Stage 5 as a mandatory design input.**

### Cross-PR contention

See § Cross-PR Overlap Audit — **intersection is empty**.

---

## Integration Points

| # | Point | Members | Shared surface | What must hold |
|---|---|---|---|---|
| IP-1 | Frontmatter parse contract | #6355(D-12) → #5817, #5832, #6251 | `_frontmatter.read_frontmatter` return shape | A changed return value must not alter *discovery counts* for any of the 8 importers except where intended |
| IP-2 | Corpus traversal predicate | #5817 → #5832 | `stamp-node-frontmatter.py` | If #5817 extracts a shared predicate, #5832's `_project_of` edit must not be reverted by the extraction commit |
| IP-3 | Portfolio render pipeline | #6355 → #5817 | `compose-portfolio.py` | `discover_rollups` (which rollups exist) and `render_s2` (how each renders) must compose — a dot-segment fix that changes the rollup count changes what `render_s2` iterates |
| IP-4 | Sanctioned-session minter | #5556 → #6355 *(conditional)* | `start-skill-editor-session.sh` | **Soft only.** If #6355's conditional row fires, its Engineering spoke needs a minted session. #5556's defect is confined to the `--self-test` path (lines 120/137/143); the `mint` path at line 165 does not `cd` and is unaffected. Recorded so the coupling is visible, **not** as a blocker |

---

## Risk Register

| ID | Risk | Sev | Likelihood | Owner | Mitigation | Reversibility |
|---|---|---|---|---|---|---|
| **R1** | **#5707's oracle-parity arm rejects the fix regardless of correctness.** `check-issue-ref-validity.sh` runs `--equivalence <pre-sha>`, materialising the pre-extraction inline body from git and asserting **identical report text in both directions**. Its own header states: *"Any fixture added to `fixtures/issue-ref/{cases,manifest.txt}` whose verdict differs between that body and this checker fails the arm in the WEAKENED/STRENGTHENED direction — REGARDLESS OF WHETHER THE CHANGE IS CORRECT. A behaviour fix is exactly such a change."* #5707 **is** a behaviour fix. Moving the anchor forward is also blocked (`extract_oracle` dies unless the pre-extraction `run:` block still contains `REFBLOCK_RE`) | **HIGH** | **Certain** if the obvious route is taken | #5707 Stage 5 | The file **documents its own sanctioned pattern**: site the new assertion as a **corpus-free block inside `run_self_test`** writing under `$HARNESS_TD`, never under `$FX_REPO`; the override-form block is the worked example. Stage 5 must design to this and Stage 6 must not add fixtures to `fixtures/issue-ref/` | CHEAP |
| **R2** | **`_frontmatter.py` blast radius.** One-line parser change reaches 8 importers; 5 are in this release's write set | **HIGH** | Medium | #6355 Stage 5 | Land D-12 first (step 1) and run the full `core/deploy/tests/` + affected `--self-test` suite **before** any consumer edit, so a regression is attributable to one commit. Design against ADR-159 and the `fixtures/frontmatter-strip/` conformance fixture, and keep the Python and `release/tools/lib/frontmatter-strip.sh` twins in agreement | MODERATE |
| **R3** | **#6355 is under-sized at `size:S`.** It carries two distinct defects (its own `render_s2` fix + the folded D-12 parser fix), a contract rewrite, a non-1:1 dimension→metric mapping to resolve, and a conditional sanctioned-session limb | MED | High | Operator (D-B) | Re-size to **M** (4). Release becomes 19 pts — inside 15–25 | CHEAP |
| **R4** | **#5707 is under-sized at `size:S`** given R1 | MED | High | Operator (D-B) | Re-size to **M** (4). Release becomes 21 pts — still inside 15–25 | CHEAP |
| **R5** | **Close-out tooling changes under this release.** PR #7253 (`release/closeout-correctness-batch`, **DRAFT**) rewrites `release/tools/automated-closeout.sh` (+1010/−106) and `release/tools/cleanup-orphan-state.sh` (+863/−61) — the exact tooling this release's Stage 12/13 tail invokes. **Zero file overlap** with this release, so it is a temporal risk, not a contention risk | MED | Medium | Hub, Stage 12 | Re-read both tools at Stage 12 entry rather than assuming the behaviour observed at planning. If #7253 merges first, re-run the Stage-9 A6.5 mid-pipeline divergence check before GO | MODERATE |
| **R6** | **D-Version collision.** #7253 carries the same provisional `v4.61`. Whichever merges first claims it; the other re-derives at its own Stage-12 atomic claim | LOW | Medium | Stage 12 | The ADR-092 atomic claim (`claim-version.sh`, compute-next-free + ref-CAS) handles this by construction. Do **not** hand-type a version. #7253 being a **draft** lowers the near-term likelihood | CHEAP |
| **R7** | **#5817's write set is undetermined until its Stage 5 renders.** Minimal patch = 1 file; shared-predicate extraction = 3 files and creates the #5832 adjacency (E5) | MED | High | #5817 Stage 5 | Settle the #5817 design question **before** dispatching #5832. The milestone's own Outcome Statement says "one shared dot-segment predicate", which biases toward extraction — but that is a stated intent, not a decision. Routed as **D-D** |
| **R8** | **#6242's fixed line becomes an added line and re-enters the sigpipe gate.** The gate scans added lines in changed `*.sh`; editing line 66 makes it newly scanned | LOW | High | #6242 Stage 6 | The AC's own prescribed method (`declare -F "$fn" >/dev/null`) is pipe-free and passes the gate. **Already aligned** — recorded so the spoke does not substitute a piped alternative |
| **R9** | **Two-surface drift on #6251.** The §2.4 table and check 10's stated term count can re-diverge silently | MED | Medium | #6251 Stage 5 | The AC already requires the count be *derived* or *asserted equal* rather than restated. Prefer the lint reading the table so a future row cannot be added and silently go unenforced | CHEAP |
| **R10** | **Rollback of Slice A is not per-card.** Three cards touch two shared files serially; reverting the middle card (#5817) after #5832 lands would conflict | MED | Low | Stage 12 | Under SINGLE topology, rollback granularity is the whole release (revert the merge). Slice A is not independently revertible and the plan does not claim it is — see § Rollback Strategy |

**Zero dependency risks of the blocking kind.** Enumerated over all nine members against the native GitHub dependency graph (`blocks: 0 · blocked-by: 0` on every member) and against cross-milestone edges (the milestone's Dependency Exceptions section registers none). Every edge in this release is a *file* edge, internal to the release, and all five are soft.

---

## Cross-PR Overlap Audit

**Baseline SHA:** `a3083858` · measured 2026-09-10.

### In-Flight Release Roster

**Measured at:** `a3083858` · 2026-09-10 · **Population:** n=1 sibling

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `closeout-correctness-batch` | `#7253` (**draft**) | `284d5cc3` | minor | `v4.61` | `v4.61` | — |

**0 remote `chore/*` branches** at planning entry. **1 open PR repo-wide** (#7253). **1 remote `release/*` head** (the same). The roster is a pinned measurement and carries **no verdict** — the cross-release contention verdict is rendered at Stage 9 Phase A6.6 against a fresh re-measurement.

### Overlap result

**`EDITSET(#7253) ∩ SURFACE(this release) = ∅`.** #7253's 19 changed files are enumerated in § Evidence; not one appears in this release's File Change Matrix. The nearest approach is `release/tools/tests/test_action_item_gate_predicate.sh` (#7253) vs. `release/tools/tests/test_deciders_carveout.sh` (#6242) — the **same directory, different files**. No `overlap_class` computation is required, because no file is contended.

**Structural-blast-radius sub-audit:** this release's mover-set is **empty** — zero `add`, zero `delete`, zero rename rows in the File Change Matrix; every row is an `edit` to an existing path. With an empty mover-set, `SURFACE(R)` reduces to the version-slot virtual-path token `Δversion/v4.61` alone. #7253 contributes the **same** token (carried label `v4.61`, recomputed `v4.61`), so the version axis yields **one Tier-S serialization edge** — recorded as **R6**. No path-class Tier-S edge exists.

**A0.7 / sibling-merge trigger, run once for both questions:** `git log a3083858..origin/main --name-status --find-renames` over the window from this release's base to current `main` returns **empty** — `origin/main` is *at* `a3083858`, so the window is zero-width and no sibling has merged since the pin. Nothing to re-home (A0.7 SKIP) and nothing to re-run (the A4 pin is fresh, not stale).

**Baseline-pin temporal limitation stated plainly:** this audit is pinned at `a3083858`. #7253 is a live draft and may merge before this release reaches Stage 12; a release that branches after this instant is invisible here. Stage 9 Phase A6.5/A6.6 re-measures pre-GO, and Stage 12 Phase A.5 is the post-GO last-line detector.

---

## Delivery Strategy

**Branch topology: SINGLE** (recommended — operator renders at **D-C**).

- **Branch:** `release/deploy-tools-and-tests-batch` — slug-primary, no version stem. The version binds only at the Stage-12 atomic claim (ADR-092).
- **PR:** one PR, one merge. Title form `release(deploy-tools-and-tests-batch): <summary>`.
- **Commits:** one coherent commit per member, in the § Implementation Sequence order, with #6355's two limbs as two commits (D-12 substrate first, then `render_s2`).
- **Commit 0:** the release plan file at `release/releases/plans/deploy-tools-and-tests-batch_RELEASE_PLAN.md`, transcribed from this comment. From Commit 0 the plan file — not this comment — is the durable surface every later stage reads.
- **Parallelism posture (D-Concurrency Posture): P0 fully-serial.** SINGLE topology maps to P0, and P0 is the undeclared default. Slice B's six cards are *analytically* independent, but under SINGLE they share one branch, and non-serial posture on a shared branch requires the force-push prohibition and buys little here. Force-push (including `--force-with-lease`) is prohibited on the release branch regardless.

**Why SINGLE rather than OPTION-A, grounded in the contention map.** OPTION-A would put #5817 and #6355 on separate branches while both write `compose-portfolio.py`, and #5817 and #5832 on separate branches while both may write `stamp-node-frontmatter.py`. That is a merge conflict by construction, on two files, for zero parallelism gain — Slice A must be serial on its own merits. Slice B is genuinely independent and could take separate branches, but splitting six trivial cards across six branches multiplies PR and merge overhead against the operator's standing "one milestone, one PR, one merge" preference and against the milestone's own Success Indicator ("one PR"). **The contention map argues for SINGLE, not against it.**

**Release Class declaration.**

`Class: routine` — **re-derived by the Classification Procedure, not inherited from the milestone description.**

| Class | Fires? | Evidence |
|---|---|---|
| `cross-cutting` | **NO** | Trigger (a) requires the File Change Matrix to declare a change to ≥3 pipeline stages or ≥3 governance surfaces. This matrix touches **zero** `pipeline/stage-*.md` files and **two** standards (`portfolio-writeback-contract.md`, `release-notes-standard.md`) — neither is a member of the named six rule-defining documents, and two is below three regardless |
| `novel` | **NO** | No member introduces a new reference class, protocol, or structural pattern. All nine are corrections to existing behaviour |
| `hotfix` | **NO** | Not a narrow corrective scope against a P1/P2 in a deployed release. Nine members, priorities P3-class |
| `routine` | **YES** | Bounded scope; well-understood patterns; low blast radius; CHEAP–MODERATE reversibility throughout |

**The `routine` anti-pattern was tested against, not assumed past.** The taxonomy warns against "classifying a 10-issue cross-cutting reorganization as `routine` because individual issues are small — aggregate scope is the relevant scale". Nine members is close to that shape, so the aggregate was measured rather than waved through: **12 unconditional + 4 conditional edits across 12 distinct files**, 10 of them in `core/deploy/{tools,tests}`, plus 1 release-test and 2 standards. Zero files added, zero deleted, zero moved. This is not a reorganization — it is nine point corrections on one surface. `routine` holds on aggregate scope, not merely on per-issue size.

**Differentiation posture** (per-class mapping; recommendation, operator may override with documented rationale):

| Dimension | Value | Note |
|---|---|---|
| Engagement density | **Light** | Spoke completions batched into consolidated Decision Briefings |
| Stage 9 Plan Review depth | **Standard**, with a **documented per-release override to Deep for the #6355 / #5817 / #5832 cluster** | Those three carry the shared-substrate blast radius (R2) and the only within-release contention. Standard depth is right for the other six; the cluster earns a cross-D upstream-compatibility scan |
| Stage 5 Activation bias | **SKIP-where-trivial** | Applied — 5 activated / 4 skipped, and none of the four skips is borderline |
| Stage 13 Outcome-window | **30-day** | Standard |

---

---

## Cross-Issue Acceptance Criteria

Four CIACs. Each spans ≥2 issues, names a concrete shared surface, and is gradable MET / NOT MET / PARTIAL from the merged PR at Stage 9 QC3.5 / Phase A3.6.

**Cross-Issue Acceptance Criteria**

- [ ] **CIAC-1 (#5817 × #6355 on `core/deploy/tools/compose-portfolio.py`):** Both edits survive in the merged file — `discover_rollups` applies a dot-segment skip, **and** `render_s2` resolves a per-dimension value rather than one invariant scalar. Neither card's edit reverted the other's. *Method:* `python3 core/deploy/tools/compose-portfolio.py --self-test` returns 0, **and** `grep -n 'startswith("\.")' core/deploy/tools/compose-portfolio.py` returns ≥1 line inside `discover_rollups`, **and** `grep -c '_rag_cell(r\.status)' core/deploy/tools/compose-portfolio.py` returns a count strictly less than its pre-merge value of 2. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#5817 × #5832 on `core/deploy/tools/stamp-node-frontmatter.py`):** The traversal-predicate change and the `_project_of` change coexist — the file exports a `_project_of` that yields no self-referential owner for a depth-1 path, **and** its traversal skip is unchanged or shared, not deleted by the predicate refactor. *Method:* `python3 core/deploy/tools/stamp-node-frontmatter.py --self-test` returns 0, **and** a fixture invoking `_project_of(Path("CLAUDE.md"))` yields a value that is not `"CLAUDE.md"`; *control arm:* `_project_of(Path("proj-alpha/doc.md"))` must still yield `"proj-alpha"` — same instrument, same target, so the probe is not merely detecting change. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#5817 × #5832 × #6355 on the corpus-walk contract):** The milestone Outcome Statement's own claim — *"one shared dot-segment predicate"* — is true after the merge: all three corpus walkers (`compose-portfolio.discover_rollups`, `stamp-node-frontmatter.iter_corpus_files`, `build-doc-index`'s walk) reach the **same** include/exclude verdict on a path carrying a dot-leading segment. *Method:* build a fixture corpus containing one dot-segment `.md` file and one ordinary `.md` file; run each of the three walkers over it and assert the three inclusion sets are equal; *control arm:* remove the dot-segment file and assert all three still agree and the set is non-empty, so an all-empty agreement cannot pass as cohesion. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#6251 × #6355 on the governed-statement ↔ enforcing-code capability):** Each card's documentation half agrees with its code half after the merge — `release-notes-standard.md` §3.2's stated check-10 term count agrees with the enforced list in `lint_release_corpus.py` (derived or asserted, not restated), **and** `portfolio-writeback-contract.md` §4's `S2` row describes what `render_s2` actually emits, with the interim honest-posture sentence replaced rather than left alongside. *Method:* `python3 core/deploy/tools/lint_release_corpus.py --self-test` returns 0, **and** `grep -c 'interim' core/standards/portfolio-writeback-contract.md` returns 0; *control arm:* `grep -c 'S2' core/standards/portfolio-writeback-contract.md` must return ≥1 — same instrument, same target, so a zero from an unreadable path is distinguishable from a zero from a removed sentence. *Graded at Stage 9 QC3.5 on the merged PR.*

**Why there is no CIAC spanning #6174 / #6111 / #6242 / #5556.** Those four are the release's "a check reports the wrong thing" theme, and it is tempting to write a cohesion criterion over them. They share **no concrete surface** — four different files, no common table, schema, anchor, or capability — and the CIAC contract requires one. Their shared property is a *verification obligation*, not a cohesion constraint, so it is discharged per-member in the Verification Plan's discrimination column below rather than manufactured into a CIAC.

---

## Verification Plan

**AC baseline** — per-issue acceptance-criterion counts as read at plan time, against commit `a3083858`:

| Issue | AC count at baseline |
|---|---|
| #6174 | 4 |
| #6111 | 3 |
| #5707 | 4 |
| #5556 | 3 |
| #6242 | 4 |
| #6251 | 3 |
| #6355 | 4 (body) + 3 (folded D-12, from the trusted-authored comment) = **7** |
| #5817 | 0 — observation-tier body, no `### Acceptance Criteria` list |
| #5832 | 0 — observation-tier body, no `### Acceptance Criteria` list |

**#5817 and #5832 carry zero acceptance criteria, and that is a G-PL2 finding this plan does not paper over.** Both were filed observation-tier and both were later flipped to `status: approved` by an operator correction that explicitly said *"Any residual gap is a bundling precondition and is noted on the issue, not a blocker to approval."* Approval is settled; **bundle-readiness is not**. Each needs verifiable ACs before its Stage 5 renders. Both bodies state a one-sentence outcome that is directly convertible, and the derivations are proposed in § Recommendations for operator ratification — routed **Tier 1 [ADJUST]**, not Tier 2, because the premise is sound and only the AC surface is missing.

**Discrimination evidence (sub-task item 7).** Five members are defects *in* a check, a test, or a self-test. For those, a corrected check that passes proves **coverage**, not **discrimination**. Each is therefore bound to a stated discrimination method — a RED arm that reproduces before the fix, or an armed-red-then-revert mutation where the corrected behaviour is believed-correct from the start:

| Issue | AC | Verification Method | Expected Result | Discrimination method |
|---|---|---|---|---|
| #6174 | AC-1 | `bash core/deploy/tests/test_g1_form_family.sh` after pointing `build_runner`'s splice at a non-existent function name | arm A names *empty predicate extraction*, not the sentinel pair | **RED arm before the fix**: the same mutation currently prints `missing or inverted sentinel markers` — reproduced at baseline |
| #6174 | AC-2 | read arm A's two branch messages | each names the file and the unresolved symbol | reviewer-read |
| #6174 | AC-3 | run the new test's two branches | each branch has a sensitivity arm that fires on its own cause and a specificity arm silent on the other | the AC *is* the discrimination requirement |
| #6174 | AC-4 | `bash core/deploy/tests/test_g1_form_family.sh` | `32 passed, 0 failed` | regression floor |
| #6111 | AC-1 | `bash core/deploy/tests/test_refresh_hooks.sh` | each of `deploy-check.mode`, `.gh-path-leak-mode`, `.autonomy-mode` carries a preserve assertion | **RED arm**: at baseline all three appear only in a comment at line 157 — 0 assertions |
| #6111 | AC-2 | mutate the refresh path to clobber each mode file in turn | each mutation makes its own assertion FAIL | **armed-red mutation, one arm per file** |
| #6111 | AC-3 | inspect each new assertion's seed value | no seed equals its own template default | the defect class this derives from — a seed equal to the default makes preserve and overwrite indistinguishable |
| #5707 | AC-1 | run the gate with `GITHUB_REPOSITORY` unset | either a content-independent verdict, or a refusal naming the missing variable — **never** a resolution verdict | **RED arm before the fix**: at baseline `: "${GITHUB_REPOSITORY:=}"` (line 112) makes the API path `repos//issues/N`, which 404s and prints *"does not resolve to an issue in this repo"* |
| #5707 | AC-2 | demonstrate the false red before, absent after | before: red on conforming content; after: green | the AC *is* the discrimination requirement |
| #5707 | AC-3 | read the failure message | it names the exact-match constraint | reviewer-read; at baseline the message enumerates four categories and names no exact-match constraint |
| #5707 | AC-4 | run the gate against genuinely non-conforming content | still fails | **specificity arm** — a fix that makes the red go away by weakening the rule is rejected |
| #5556 | AC-1 | read the script's self-resolution | absolute path resolved once, before any `cd` | reviewer-read |
| #5556 | AC-2 | `./core/deploy/tools/start-skill-editor-session.sh --self-test` vs. the absolute-path form | identical verdicts | **RED arm before the fix**: the relative form fails at baseline (`bash "$0"` inside `( cd "$tmp" && … )` at lines 120/137/143) |
| #5556 | AC-3 | both invocation forms exercised, verdicts compared | equal | the AC *is* the control arm |
| #6242 | AC-1 | `declare -F "$fn" >/dev/null` returns true for a defined function | true | **control arm** — returns false for a genuinely undefined name, so the guard still fires |
| #6242 | AC-2 | delete or rename one of the three functions in a scratch copy of the library | the suite still dies at the guard | **anti-vacuity mutation** — a fix that stops the guard firing on a real absence has removed the check |
| #6242 | AC-3 | the macOS job across **repeated** runs | green every run | a single green is what the flake already produces — repetition is the point |
| #6242 | AC-4 | re-scan `release/tools/tests/**` for the pipeline-into-early-reader shape | count re-derived, not inherited | **re-derived at `a3083858`: 1 of 99** (issue measured 1 of 76 at its filing commit). Denominator grew 76→99; numerator held at 1. Control arm fired at 6 of 65 over `core/deploy/tests/**` — full probe record in § Evidence |
| #6251 | AC-1 | inject each §2.4 row's term individually into a Section 6a bullet of a post-cutover note; record findings-per-term | every row either fires or carries a visible not-enforced marker; **the `reflexive` arm must change state** | **RED arm before the fix**: bare `reflexive` is absent from `BANNED_JARGON_LITERAL` at baseline (the two compound rows are present at lines 372 and 382). Control: an unmutated note returns 0 findings |
| #6251 | AC-2 | add or change a term | the documented count cannot silently disagree | derivation or assertion, not restatement |
| #6251 | AC-3 | inject `reflexive-pipeline loop` | finding count matches the documented expectation | overlap cardinality made explicit rather than incidental |
| #6355 | AC-1 | compose a fixture whose dimensions differ; assert rendered `Status` cells are not all equal | not all equal | **control arm** — a fixture whose dimensions genuinely agree must still render equal cells, so the probe is not merely detecting inequality |
| #6355 | AC-2 | read the governed dimension→metric statement | all five dimensions mapped, including the two non-1:1 cases (Quality composes Risk + Integration Risk; Stakeholders optional / `UNSOURCED-DOMAIN`) | reviewer-read |
| #6355 | AC-3 | `compose-portfolio.py --self-test` new case against pre-fix tree, then post-fix | non-zero before, zero after | **the AC is explicitly a discrimination requirement** — a case passing on both arms does not discriminate |
| #6355 | AC-4 | read `portfolio-writeback-contract.md` | interim honest-posture sentence replaced, not left alongside | reviewer-read; graded jointly by CIAC-4 |
| #6355 | AC-D12-1 | parse a fixture carrying `project_id: x  # note`; assert the resolved key equals `x` | `x` | **control arm** — a fixture with no comment must resolve identically, so the probe is not merely detecting change |
| #6355 | AC-D12-2 | new self-test case, pre-fix then post-fix | fails before, passes after | discrimination required by the AC |
| #6355 | AC-D12-3 | read the declaration site | the chosen behaviour is documented | reviewer-read |
| #5817 | *(AC to be derived — see § Recommendations)* | proposed: all three walkers agree on a dot-segment fixture | equal inclusion sets | **RED arm before the fix**: at baseline `discover_rollups` has no dot-skip while the other two do — reproduced |
| #5832 | *(AC to be derived — see § Recommendations)* | proposed: a depth-1 path emits no `BELONGS_TO` edge | no self-referential edge | **RED arm before the fix**: `_project_of("CLAUDE.md")` returns `"CLAUDE.md"` at baseline — reproduced |

**Release-level regression floor.** Because `_frontmatter.py` reaches 8 importers (R2), the following run green at Commit 0+1 (immediately after the D-12 limb) and again before the PR opens: `core/deploy/tests/` in full, plus the `--self-test` of `compose-portfolio.py`, `stamp-node-frontmatter.py`, `build-doc-index.py`, `lint_release_corpus.py`, `check-doc-frontmatter.py`, `check-rules-budget.py`, `check-version-anchors.py`, `backfill-relationship-edges.py`. **This is a null expectation (no regressions), so it carries its control arm:** a deliberately-perturbed `read_frontmatter` (e.g. returning an empty scalar dict) must make **at least one** of those suites FAIL — same instrument, same targets. A green run whose perturbed twin is also green is a broken probe, not a clean regression floor.

---

## Rollback Strategy

**Granularity is the release, not the card.** Under SINGLE topology with a serial Slice A on two shared files, per-card revert is not available: reverting #5817 after #5832 has landed on `stamp-node-frontmatter.py` conflicts, and reverting #6355's D-12 limb after any consumer edit leaves consumers calling a parser contract that no longer exists. The plan states this rather than implying finer granularity than it has.

| Scenario | Action | Reversibility |
|---|---|---|
| Defect found **pre-merge** | Amend the offending commit on the release branch and re-run the regression floor. Force-push is prohibited on the shared branch — amend forward with a new commit | **CHEAP** |
| Defect found **post-merge, in Slice B** (#5707 / #6251 / #6111 / #6174 / #6242 / #5556) | Revert the single commit. Each Slice-B card is textually independent — zero shared files — so a single-commit revert applies cleanly | **CHEAP** |
| Defect found **post-merge, in Slice A** (#6355 / #5817 / #5832) | Revert the **whole merge**. The three cards are entangled across `_frontmatter.py`, `compose-portfolio.py` and `stamp-node-frontmatter.py`; a partial revert leaves an inconsistent parser/consumer pair | **MODERATE** — one merge revert, no data loss, operator-authorized |
| Version tag already claimed | The tag is **retained and recorded**, never deleted. `refs/tags/v*` is host-protected. Revert the merge and record the rollback in the re-version ledger; the tag stands as the record that the version was claimed and withdrawn | **MODERATE** |

**No rollback path in this release deletes a version tag**, and no step below prescribes one.

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix):** Stage 5: **5** · Stage 7: **9** · Stage 8: **9**
**Per-spoke cost estimate:** ~5% of a 5-hour usage window per spoke (size-bucket band heuristic; `[CALIBRATE-AFTER-3]` MEDIUM confidence — no telemetry medians substituted for the band)
**Assumed/stated remaining usage-window envelope:** conservative default — a full 5-hour window assumed, because no operator quota state was stated at hub start
**Estimated cumulative draw % (worst parallel batch):** worst **single** parallel batch is 9 spokes at Stage 7 or Stage 8 → 9 × 5% = **45%**
**Routing:** PASS — proceed parallel; no warning required in the plan.

**One caution the band does not capture, stated because 45% sits five points under the WARN floor.** Stage 7 and Stage 8 are *separate batches*, so the worst-single-batch reading is correctly 45%. But they are both 9 wide and a 5-hour window can hold both: **co-scheduled in one window they sum to ~90%**, which is FAIL territory for the window even though neither batch is. The verdict stays PASS on the protocol's own terms; the mitigation is scheduling, not scope.

**Recommended wave shape — titrate by shape and timing, never by thinning per-issue rigor:**

- Run Stage 7 and Stage 8 in **different usage windows**. This is the single highest-value scheduling decision in the release.
- Within a stage, use **3 rolling lanes of 3** rather than one 9-wide fan-out. Instantaneous draw caps near **15%**, leaving headroom for a re-spawn without re-planning, and a wave checkpoint between lanes gives three natural stop points.
- Stage 5's 5-wide batch is **25%** and can run as a single wave, or as 2+3 if it shares a window with anything else.
- **No per-spoke rigor is reduced anywhere in this recommendation.** The nine members keep their full Stage 7 and Stage 8 treatment; only width and timing move.

**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant per `quota-budget-protocol.md` § 4.3b. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time (§ 3.1). **The estimate above is advisory. The load-bearing gate is Checkpoint B at every launch, not this number.** Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Operator Decisions (D-Gate Block)

### D-Version — recorded determination, not a question

**`v4.61`** — next-free above the `v4.60` tag, re-verified at planning against the live remote tag list (latest: `v4.55 … v4.60`). **Provisional** until the Stage-12 atomic claim (ADR-092); the concurrent `closeout-correctness-batch` release carries the same provisional value, and whichever merges first claims it while the other re-derives at its own claim. This is a rule-determined recurring D and is **not rendered as an operator click-gate**. Re-verified again at Engineering Commit 0.

### D-A — Release Class

**Proposed: `routine`.** Trigger evidence and the anti-pattern test are in Part 1 § Delivery Strategy → Release Class declaration. Differentiation posture: Engagement **Light** · Stage 9 depth **Standard, overridden to Deep for the #6355 / #5817 / #5832 cluster** · Stage 5 bias **SKIP-where-trivial** (applied: 5 activate / 4 skip) · Stage 13 outcome-window **30-day**. Operator renders at Phase B3 alongside scope-commit.

### D-B — Card re-sizing (scope integrity)

**Proposed: re-size #6355 `S`→`M` and #5707 `S`→`M`.**

| Card | Current | Proposed | Evidence |
|---|---|---|---|
| #6355 | `size:S` (2) | **`size:M` (4)** | Two distinct defects in one card (`render_s2` + the folded D-12 frontmatter-parser fix), a contract rewrite, a non-1:1 dimension→metric mapping to resolve, and a conditional sanctioned-session limb. The D-12 limb alone reaches 8 importers |
| #5707 | `size:S` (2) | **`size:M` (4)** | The target file carries an oracle-parity self-test that rejects *any* behaviour change regardless of correctness (R1); the fix must be built to the file's documented corpus-free pattern rather than the obvious fixture route |

**Effect on the release:** raw **17 → 21 pts**, still inside the `release_size_target_pts` 15–25 band. `class_weight` = routine identity baseline. No member is added or removed, so the Composition Lock is untouched — this is a re-measurement of committed scope, not a scope change.

### D-C — Branch Topology

**Proposed: SINGLE.** Rationale grounded in the contention map is in Part 1 § Delivery Strategy. In short: OPTION-A would put two writers of `compose-portfolio.py` and two writers of `stamp-node-frontmatter.py` on separate branches, which is a merge conflict by construction for zero parallelism gain, since Slice A must be serial regardless. Operator standing preference and the milestone's own Success Indicator ("one PR") both agree.

### D-Concurrency Posture

**Proposed: P0 fully-serial.** SINGLE maps to P0, and P0 is the safe-by-construction undeclared default. Force-push — including `--force-with-lease` — is prohibited on the shared release branch.

### D-D — #5817 fix shape *(may be deferred to #5817's Stage 5)*

**Minimal patch** (add the dot-skip to `discover_rollups` only — 1 file, no new adjacency) **vs. shared-predicate extraction** (one predicate used by all three walkers — 3 files, creates the E5 adjacency with #5832 and the CIAC-3 obligation).

The milestone's own Outcome Statement already says *"one shared dot-segment predicate"*, which biases toward extraction — but a stated intent in a description written against the original six is not a rendered decision, and the choice determines #5817's write set, the `CONDITIONAL:shared-predicate-extracted` rows, and whether #5832 must be sequenced after it. **Recommendation: extraction**, because the defect's own framing is that three hand-rolled predicates disagreeing is the bug, and a fourth hand-rolled fix does not close it. If the operator prefers to defer, it must resolve **before #5832 is dispatched**, not merely before #5817's Engineering commit.

### D-E — #6355 governed-mapping home

**Proposed: `core/standards/portfolio-writeback-contract.md`.** Placing the dimension→metric mapping in the standard satisfies AC-2 ("a governed statement"), keeps `operations/skills/weekly-status-rollup/references/metric-registry.md` **read-only**, and leaves every card in the release `unconstrained` — avoiding the fixed per-session overhead of a sanctioned skill-editor session for one paragraph. The alternative (writing into the skill reference) classifies that path `sanctioned-session-required` per the A3.5 derivation. Operator may also resolve this by reading the deployed exemption list: if `weekly-status-rollup` is exempt, conjunct 3 flips from `undetermined` to false and the constraint disappears.

---

## Reconciled Release Outcome Statement + Scope Table

**Hub PATCH payload.** The milestone description's Outcome Statement, Scope table, points line, `## Internal sequence` and `## Notes` all describe the original six and are stale. The block below covers all nine live members and is ready to PATCH into the description **after the plan-approval gate**. Points shown reflect **D-B**; if the operator declines D-B, substitute 17 for 21 and revert the two `M` cells to `S`.

```markdown
### Release Outcome Statement

**AFTER:** The deploy tools and tests resolve repo, root, project and dimension correctly at
their edges: a GITHUB_REPOSITORY fallback that refuses rather than mis-verdicts, one shared
dot-segment predicate across all three corpus walkers, the corpus-root case of the project
resolver, SELF resolved from BASH_SOURCE before any cd, distinct causes distinguished in the
g1 form-family runner and in the deciders-carveout guard, a mode-template preserve loop over
the whole population, a banned-jargon list whose standard and enforcement agree, and a
portfolio Health Indicators table whose five dimensions carry five resolved values.

**BEFORE:** Each tool carries its own hand-rolled predicate that fails on an edge case its
neighbour already handles, and several checks report a cause other than the one they detected.

**Actor(s):** platform engineering session. **Success Indicator:** every member's own
acceptance signal verified at Stage 8; one PR.

## Release Class

Class: routine

Rationale: a Shape-3 audit-driven batch (bundle-composition-doctrine § 8 Shape 3) — nine
independent bug fixes coherent by SURFACE (the deploy tool + test surface, one reviewer
context), not by cause. Zero cross-milestone dependencies and zero native dependency edges;
each fix is a point correction. Aggregate scope measured rather than assumed: 12 distinct
files, zero added, zero deleted, zero moved.

## Scope

Source: RCA + fix-cluster analysis `rca-bundling-2026-09-02` (operator decision 2026-09-03:
surface batching of the approved unmilestoned bugs). Not cause-derived: no single change
discharges these members; they ship together because they touch one surface.

| Ticket | Size | Pts | Primary file | Title |
|---|---|---|---|---|
| #6355 | M | 4 | `core/deploy/tools/compose-portfolio.py` | compose-portfolio renders one scalar under five Health Indicator labels (+ folded frontmatter join-key defect) |
| #5817 | M | 4 | `core/deploy/tools/compose-portfolio.py` | Three corpus-walking tools disagree on dot-segment skipping |
| #5707 | M | 4 | `core/deploy/tools/check-issue-ref-validity.sh` | issue-ref gate false-reds on an unset GITHUB_REPOSITORY, and its message omits the exact-match constraint |
| #5832 | S | 2 | `core/deploy/tools/stamp-node-frontmatter.py` | Edge planner emits a self-referential BELONGS_TO for any depth-1 corpus-root file |
| #6251 | S | 2 | `core/deploy/tools/lint_release_corpus.py` | A banned-jargon term listed in the standard is not enforced by the check that claims to enforce the list |
| #6111 | S | 2 | `core/deploy/tests/test_refresh_hooks.sh` | Three of four install-if-missing mode files have zero preserve assertions |
| #6174 | XS | 1 | `core/deploy/tests/test_g1_form_family.sh` | test_g1_form_family.sh arm A reports an empty predicate extraction as a sentinel-marker fault |
| #6242 | XS | 1 | `release/tools/tests/test_deciders_carveout.sh` | test_deciders_carveout.sh reports a defined function as missing when a SIGPIPE race lands wrong |
| #5556 | XS | 1 | `core/deploy/tools/start-skill-editor-session.sh` | start-skill-editor-session.sh --self-test fails under relative invocation |

Raw 21 pts · effective_pts = round_half_up(21 × 1.0) = **21**.

## Internal sequence

#6355 → #5817 → #5832 → #5707 → #6251 → #6111 → #6174 → #6242 → #5556
(contention order: shared substrate first, then the two contended files adjacent, then the
six independents).

## Dependency Exceptions

None registered (Step 3 dep walk: zero native edges; Step 4: no member owed by an older
milestone).

## Notes

Twelve files: ten under core/deploy/{tools,tests}, one release test, two platform standards.
**File contention is present, not absent** — `compose-portfolio.py` has two writers
(#5817, #6355) and `stamp-node-frontmatter.py` has two (#5817, #5832). A third coupling is
behavioural rather than textual: `_frontmatter.py` has one writer (#6355) but eight
importers, five of which this release also edits. Slice A (#6355 → #5817 → #5832) is serial
by construction; the remaining six share no files and are parallel-safe.

### Composition Lock
**Locked at:** Stage 4 Planning entry · 2026-09-10 · planning sub-task #7257
```

**Note on the three attribution corrections** folded into the table above: #5707's primary file is the extracted tool, not `.github/workflows/` (the description already had this right; the issue body did not). #5832's primary file is `stamp-node-frontmatter.py`, where `_project_of` is defined (the description had this right; the issue body names the importer). #6355's primary file is `compose-portfolio.py`, with `_frontmatter.py` as its second write. Each routes **Tier 1 [ADJUST]** on the issue body, per Phase A0.

---

## Evidence

**Run directory:** `${SCRATCH_BASE}/spoke-4-7257-5HcsEm`

**Baseline pin:** `origin/main` = `a3083858` (`2026-09-06T18:44:44-05:00`, merge of PR #7215). The session worktree's `HEAD` equals that SHA, so every file probe below read the pinned baseline directly. Tracked-file denominator at baseline: **2030**.

**Membership:** `gh issue list --milestone "deploy-tools-and-tests-batch" --state all --limit 200` returned **10** rows — 9 members + sub-task #7257 itself. 9 open / 0 closed, matching the hub-resolved count. Result count (10) is far below the limit (200), so no batch-CLI truncation. Points re-derived from `size:` labels at the XS=1 · S=2 · M=4 scale: 1+2+2+4+2+1+1+2+2 = **17** raw, confirming the hub's 17/17 against the description's stale 12.

**G-PL5 cache-read:** sub-task #7257 carries **0** comments. MISS on *no marker-bearing comment from the trusted author set exists*. PT-1..4 re-derived.

**Comment-Ingestion Trust Boundary:** all 10 comments read across the member set (#5707 ×1, #5817 ×3, #5832 ×3, #5556 ×2, #6355 ×1) are authored by the repository owner — the trusted author set — and were consumed as stage content. **Zero other-authored comments** were encountered on any member or on the sub-task; nothing was excluded on trust grounds.

**A0.8 / G-PL4 per-member repro at `a3083858` — 9 of 9 admit-still-valid:**

| Member | Probe | Observed |
|---|---|---|
| #6174 | read `test_g1_form_family.sh` | line 102: the `else` branch of `if build_runner …` prints `missing or inverted sentinel markers` for **any** non-zero return, including empty extraction. **Reproduces** |
| #6111 | read `test_refresh_hooks.sh` + `setup-workspace.sh` | 4 `install_mode_template_if_missing` call sites (2604/2605/2610/2621). In the test file `.mode` carries a seeded preserve assertion; `deploy-check.mode`, `.gh-path-leak-mode`, `.autonomy-mode` appear **only** in a comment at line 157 — 0 assertions. Control: `/preserve/` → 17 hits, `/\.mode/` → 14 hits (reader alive). **Reproduces** |
| #5707 | read `check-issue-ref-validity.sh` | line 112 `: "${GITHUB_REPOSITORY:=}"` → line 261 `gh api "repos/${GITHUB_REPOSITORY}/issues/${n}"` → `repos//issues/N` → 404 → line 473 prints *"does not resolve to an issue in this repo"*. The message set (lines 500–513) names four categories and **no** exact-match constraint. Control: `/GITHUB_REPOSITORY/` → 14 hits; negative control `/ZZZQQQ/` → 0. **Both limbs reproduce** |
| #5817 | read all three walkers | `compose-portfolio.discover_rollups:472` — `sorted(root.rglob("*.md"), …)`, **no** dot-skip. `stamp-node-frontmatter.iter_corpus_files:657` — **has** the skip. `build-doc-index:389` — **has** the skip. 1 of 3 diverges. **Reproduces** |
| #5832 | read `stamp-node-frontmatter.py` | line 391–393: `def _project_of(rel_path): return rel_path.parts[0] if rel_path.parts else ""`. For a depth-1 path, `parts[0]` **is** the filename. Control: `/def _segments/` → 1 hit; negative control `/def _QQQ_none/` → 0. **Reproduces** |
| #5556 | read `start-skill-editor-session.sh` | `bash "$0"` inside `( cd "$tmp" && … )` at lines 120, 137, 143. No `BASH_SOURCE` use in the file. **Reproduces** |
| #6242 | read `test_deciders_carveout.sh` | line 66: `if ! type "$fn" 2>/dev/null \| head -1 \| grep -q 'function'; then` — exactly the described idiom, in predicate position. **Reproduces** |
| #6251 | read `lint_release_corpus.py` | `BANNED_JARGON_LITERAL` carries `"reflexive-pipeline self-exemption"` (372) and `"reflexive-pipeline loop"` (382); bare `"reflexive"` is **absent**. Control: `"forward-only"` present at 381 and 14 file-wide hits (reader alive). **Reproduces** |
| #6355 | read `compose-portfolio.py` + `_frontmatter.py` | Primary — line 586–587: `for d in dims: out.append(f"\| {d} \| {_rag_cell(r.status)}{suffix} \|")`, invariant across `dims`. The in-code comment at 575–577 defers to a closed issue. D-12 — `_frontmatter.py` is 152 lines with **zero** comment-stripping in the parse path; line 80 is `keys[key] = _strip_quotes(raw_val.strip())`, and `.strip()` removes whitespace only. Control: `/#/` → 13 hits (all shebang/comment/self-test), `/def /` → 4 (reader alive). **Both limbs reproduce** |

**Probe records (PV-0..PV-7) for every null / N-of-M claim in this plan:**

| Claim | PV-0 population | PV-1 invocation | PV-3 extraction | PV-4 sensitivity arm | PV-5 specificity arm | PV-6 observable |
|---|---|---|---|---|---|---|
| **"All 17 candidate files exist at baseline"** | 2030 tracked paths from a single `git ls-tree -r --name-only origin/main` dump | set-membership test in `python3` against that dump | non-empty — 17 of 17 resolved | n/a (positive claim) | control path `core/deploy/tools/NO_SUCH_FILE_QQQ.py` → **ABSENT**, so the test can return false | 17 EXISTS / 1 ABSENT printed per path |
| **#6242 AC-4 "1 of 99"** | `release/tools/tests/**` = **99** tracked files | regex for a pipe into a short-circuiting reader (`head`, `grep -q`, `egrep -q`), restricted to predicate position (`if`/`elif`/`while`/`until`/`&&`/`\|\|`), comment lines excluded, command-substitution lines excluded | non-empty — 15 raw reader matches before the predicate filter, 1 after | same probe over `core/deploy/tests/**` → **6 files / 12 lines**, non-zero | the predicate filter removed 14 value-extraction matches (e.g. `$(… \| head -1)`) that are **not** the defect shape, so the probe distinguishes shape from mere co-occurrence | `1 of 99` printed with the single matching line quoted |
| **#5556 "shape confined to the subject, 1 of 182"** | **182** tracked `*.sh` | regex for `cd … && … $0` (and the mirror order) on one line, comments excluded | non-empty — 4 raw lines across 2 files | wider arm (`bash \|sh \|exec "$0"`) → **12 files / 23 lines**, non-zero, so the reader sees `$0` broadly | the 4 raw hits were read individually: 3 are the subject's own lines 120/137/143; the 4th (`run-fragile-ref-fixtures.sh:396`) is **awk's** `$0` inside `sub(/^\.\//, "", $0)`, not shell `$0` — a false positive removed by reading, not by pattern. The two `exec "$0"` siblings were opened and neither subshell `cd`s | `1 of 182` with each hit classified |
| **"`EDITSET(#7253) ∩ FCM = ∅`"** | #7253's **19** changed files, read from the PR's own file list | set intersection against this plan's 16 matrix rows | both sides non-empty — 19 and 16 | intersecting the same 19 against a set **containing** one of them returns that element, so the operation can return non-empty | nearest approach identified and named (`test_action_item_gate_predicate.sh` vs `test_deciders_carveout.sh` — same directory, different files) rather than reported as a bare zero | full 19-path list below |
| **"Zero circular chains in the dependency graph"** | the 5 enumerated file edges (E1–E5) | manual DAG walk over E1–E5 | non-empty — 5 edges | E1/E2/E3 are directional and share a common root (#6355 D-12), so a cycle is expressible if one existed | E4/E5 are undirected same-file adjacencies and were tested separately for cycle-closure with E1/E2 | edge table published with type and basis per edge |
| **"14 of 16 matrix paths have exactly one writer"** | all 16 File Change Matrix rows | per-path writer count | non-empty — 16 rows | 2 paths returned a count of 2, so the counter can exceed 1 | the 2 multi-writer paths are named with their functions and line ranges | contention table |

**One residual closed by direct read, not left open.** #6242's AC-4 warns that "a later sweep may find more". PR #7253 adds `release/tools/tests/test_action_item_gate_predicate.sh` (+106 lines) to the very pool #6242's scope claim is measured over. Its added lines were read: the only occurrence of the shape is inside a **comment** (`# fixture through \`printf … | grep -q\` inverts this very control`), which the scan excludes. **#6242's `1 of 99` therefore survives a #7253 merge**, and the re-derivation does not need re-running on that account.

**PR #7253 changed files (19):** `core/rules/git-workflow.md` · `core/standards/gate-efficacy-standard.md` · `core/standards/hub-action-tracking.md` · `packages/release-executor.skill` · `packages/release-executor.skill.sha256` · `packages/release-hub.skill` · `packages/release-hub.skill.sha256` · `release/ADRs/ADR-195-action-item-status-classified-by-membership.md` · `release/ADRs/README.md` · `release/references/how-to/hub-spoke-bridge.md` · `release/references/pipeline/stage-12-execute.md` · `release/references/pipeline/stage-13-close.md` · `release/releases/plans/closeout-correctness-batch_RELEASE_PLAN.md` · `release/skills/release-executor/SKILL.md` · `release/skills/release-hub/references/orchestration-playbook.md` · `release/tools/automated-closeout.sh` · `release/tools/cleanup-orphan-state.sh` · `release/tools/compute-release-velocity.sh` · `release/tools/tests/test_action_item_gate_predicate.sh`

**Canonical-checklist attestation.** Every codified Phase step in `release/references/pipeline/stage-04-planning.md` § 5 (A0–A8) and § 6 ran, or is recorded N/A-with-reason:

| Step | Status |
|---|---|
| A0 Triage→Design re-review (+ G-PL5 cache-read) | RAN — MISS, PT-1..4 re-derived, 9 rows, 0×C3, 3×C2 |
| A0 ticket-architecture reconciliation | RAN — no member touches an ADR, governing discipline, registry/ledger/charter, or roadmap. Two standards are edited as the documentation half of a code fix, neither is a governing-surface citation. **N/A by predicate** |
| A0 architecture evaluative-lens (advisory) | RAN — no component introduced or reshaped; nine point corrections. No lens finding |
| A0.5 / G-PL1 AC-currency | RAN — 3 CURRENCY-MISMATCH findings, all Tier 1 [ADJUST] |
| A0.6 / G-PL2 crisping | RAN — 9 of 9 pass the Gate-1 substantive checks; 2 carry zero ACs, routed as a bundling precondition |
| A0.7 / G-PL3 placement forward-check | RAN — **SKIP** (zero-width window; zero new files) |
| A0.8 / G-PL4 empirical repro | RAN — 9 of 9 admit-still-valid; 0 drift-class cards |
| Parallelization-Map currency check | RAN — **suppressed**, milestone predates the convention |
| A0 currency-decision confidence gate | RAN — corroborated-and-grounded; outcome **no-op**; no pause loop |
| A1 Milestone validation entry gate | RAN — 9 members, all `status: bundled`, milestone assigned |
| A1.5 domain-best-practice sourcing-or-flag | RAN — Form X exempt, `domain: software` classified from the matrix |
| A2 dependency-ordered sequencing | RAN — 5 file edges, 10-step sequence, 2 slices |
| A3 per-issue change specification | RAN — File Change Matrix, 12 unconditional + 4 conditional + 4 read-only + 2 explicit non-scope |
| A3.5 Agent-Editability Read | RAN — 2 Tier-0 blocks quoted; 1 conditional `sanctioned-session-required` row |
| A4 file contention resolution | RAN — 2 contended paths + 1 shared-substrate coupling |
| A4 Cross-PR Overlap Audit + In-Flight Roster | RAN — n=1 sibling, intersection ∅ |
| A4 structural-blast-radius sub-audit | RAN — empty mover-set; 1 Tier-S version-slot edge (R6) |
| A5 release plan assembly | RAN — this document |
| A6 Quota-Budget pre-check | RAN — PASS at 45% |
| § 6 CIAC | RAN — 4 CIACs authored |
| § 6 Commit-0 Survival Set (rows 1–9) | RAN — all nine elements present in this plan |
| § 6 new-executable companion obligation | **N/A** — zero `add` rows for tracked executables |
| § 6 Verification-Plan AC→method mapping + AC-Binding | RAN — per-issue table with AC ordinals, AC baseline pinned at `a3083858`, null results carry control arms |

---

## Recommendations

**Control firings:**

| Control | Rule ID | What tripped it | Action taken |
|---|---|---|---|
| Worktree-isolation git guard (agent harness) | not surfaced in the message | A compound command chaining `git fetch` / `git rev-parse` / a `for`-loop `git cat-file` in one call — the guard reported it "names git in a form too complex to verify that it stays inside the worktree" | **Split into plain, separately-verifiable commands** and re-ran from the worktree. This is the sanctioned response (a guard reporting it cannot verify a compound), not a spelling change: the resulting commands are the ones actually checked. No outcome was reached that the guard had refused |
| Worktree-isolation git guard (agent harness) | not surfaced in the message | A `python3` heredoc containing `subprocess.run(["git", …])` | **Chose a different action** — reused the already-dumped tracked-file list in the run directory instead of invoking git from inside python. No git call was made by a second route |

Both firings were on **form, not substance**, and both were correct: the guard could not verify the compound/embedded form, and a plainer form satisfied it. No control was evaded, no refused outcome was reached by another route, and nothing was reworded to avoid a matcher.

**Out-of-scope discoveries (noted, not actioned):**

1. **`core/deploy/tests/**` carries 6 files / 12 lines of the same predicate-position SIGPIPE shape #6242 fixes** (probe record above; the control arm for #6242's own scan is what surfaced them). #6242's scope claim is correctly bounded to `release/tools/tests/**` and should **not** be widened — but this is a real, adjacent population and warrants its own observation-tier work item. Sites include `test_check31_marker_probe_determinism.sh` (139/141/181/250), `test_g1_06_priority_carrier.sh` (375/376), `test_g1_title_floor.sh` (39/42), `test_refresh_surfaces.sh` (329/332), `test_rehome_hook_wiring.sh` (218). One of them (`test_instance_path_roundtrip.sh:212`) already carries a `# sigpipe-idiom: allow` marker, so the exemption tier is in live use.

2. **#5556's own body asks whether the `$0`-after-`cd` shape exists in sibling tools. It does not** — swept over all 182 tracked `*.sh` and the shape is confined to the subject file. The two nearest candidates (`check-release-body-drift.sh`, `reemit-release-bodies.sh`) `exec "$0"` inside subshells that set env but never `cd`, and both already resolve their libs from `BASH_SOURCE[0]`. **#5556 can be fixed in isolation without a corpus sweep**, and 69 files already use the correct idiom as precedent.

3. **#6242's open question — "would the shipped sigpipe gate's predicate catch this shape?" — is answerable: yes.** The gate's declared invariant in `.github/workflows/repo-integrity.yml` covers *any writer piped into a short-circuiting reader*, naming `head` and `grep -q` explicitly. It is **added-lines-only** by design (whole-file only for git status A or R), so a pre-existing line was never scanned. That is correct gate behaviour, not a gate defect — and it means the fix's replacement line *will* be scanned, which the AC's own `declare -F` method already satisfies (R8).

4. **`_frontmatter.py` has a shell twin** at `release/tools/lib/frontmatter-strip.sh`, and `release/ADRs/ADR-159` binds the frontmatter strip to a conformance fixture at `core/deploy/tools/fixtures/frontmatter-strip/`. #6355's D-12 limb must be designed against both, or it creates a Python/shell divergence. Routed as a **mandatory Stage 5 design input** for #6355, not left to discovery at Engineering.

**Actions requested of the operator before Stage 5 dispatch:**

- Render **D-A** (Release Class), **D-B** (re-sizing), **D-C** (topology), **D-Concurrency Posture**, and **D-E** (#6355 mapping home). **D-D** may be deferred to #5817's Stage 5, provided it resolves before #5832 is dispatched.
- Ratify the three **Tier 1 [ADJUST]** body corrections (#5707 Affected Files → the extracted tool; #5832 Affected Files → `stamp-node-frontmatter.py`; #6355 line refs → 574–589).
- Ratify **acceptance criteria for #5817 and #5832**, which currently carry none. Derived from each body's own stated outcome, for ratification rather than invention:
  - **#5817 AC-1:** all three corpus walkers return the same inclusion verdict for a path carrying a dot-leading segment (method: three-walker fixture comparison; control arm — a corpus with no dot-segment file must still yield equal, non-empty sets). **AC-2:** the traversal predicate exists once and the other walkers call it, rather than three copies (method: read the call sites). **AC-3:** `compose-portfolio.py --self-test` gains a case that fails before the fix and passes after.
  - **#5832 AC-1:** a file with no resolvable owning project emits **no** `BELONGS_TO` edge (method: plan edges for a depth-1 fixture; assert no edge whose target equals the file's own name). **AC-2:** control arm — a depth-2 file still emits its correct `BELONGS_TO`, so the probe is not merely detecting suppression. **AC-3:** the guard is keyed on the **name**, not the stem — the issue records that `target == own filename` is true while `target == own stem` is false, so a stem-keyed guard provably misses this case.
- Confirm the **Stage 7 / Stage 8 window separation** in the Quota Budget, which is the release's highest-value scheduling decision.

---

## Model Provenance

- **Invocation model parameter:** `opus` (passed explicitly by the hub)
- **Agent-definition default:** no `.claude/agents/pmo-*.md` definition exists in this deployment — spoke launched as `general-purpose` with the persona card in the prompt
- **Parent-session model:** Opus 5 (`claude-opus-5`), as reported by this runtime
- **Designated-model match:** **YES** — against `platform-config.toml [spoke_runtime]` (`default_spoke_model` = `opus`, `chip_model` = `opus`); no per-stage override active. Effort: MAX per the immutable directive

---

## Output for Stage 5

**Five cards activate Stage 5**, each with its design question already framed and its mandatory inputs named:

| Card | Design question Stage 5 must answer | Mandatory inputs |
|---|---|---|
| **#6355** | (a) Where does the governed dimension→metric mapping live (D-E)? (b) How are the two non-1:1 dimensions resolved — Quality composes Risk + Integration Risk, Stakeholders is optional / `UNSOURCED-DOMAIN`? (c) How does the D-12 parser fix stay in agreement with its shell twin? | `core/standards/portfolio-writeback-contract.md` §4 `S2`; the weekly-status-rollup metric registry (read-only); `release/ADRs/ADR-159`; `core/deploy/tools/fixtures/frontmatter-strip/`; `release/tools/lib/frontmatter-strip.sh` |
| **#5817** | Minimal patch or shared-predicate extraction (D-D)? The answer determines the write set, the two `CONDITIONAL:shared-predicate-extracted` rows, and whether #5832 must be sequenced after it | all three walkers; the milestone Outcome Statement's "one shared predicate" phrasing; CIAC-3 |
| **#5707** | How is the fix asserted **without** adding to `fixtures/issue-ref/`? | the file's own header (lines 36–60), which documents the sanctioned corpus-free `run_self_test` pattern and names the override-form block as the worked example |
| **#5832** | Fix in the shared `_project_of` (blast radius across 2+ consumers) or guard at the `BELONGS_TO` planning path in the edge planner (local)? | `stamp-node-frontmatter.py:391`; `backfill-relationship-edges.py:247–260`; the issue's stem-vs-name finding |
| **#6251** | Enforce bare `reflexive` (and define the overlap cardinality with the two compound rows) or mark it visibly excluded in the §2.4 table? Derive check 10's count or assert it? | `lint_release_corpus.py` `BANNED_JARGON_LITERAL`; `release-notes-standard.md` §2.4 + §3.2 |

**Four cards skip Stage 5** and route directly to Engineering: #6174, #6111, #6242, #5556. Each has a prescribed method and zero design uncertainty; the skips rest on the applicability rule, not on convenience.

**Slice A (#6355 → #5817 → #5832) must be dispatched serially**, and #5817's D-D must resolve before #5832 launches.

Each member is marked as closed at Stage 13, per the standard close-out; no member closes earlier.

---

## Ratified AC-method substitutions

Two of #6355's seven acceptance criteria state a verification **method** that only the *rejected* limb of a two-limb criterion can satisfy. The design deliberately selects the other limb in both cases, and the issue body is not amended (ADR-062). Stage 8 grades per-criterion against the criterion text, so the substituted methods are recorded **here, in the plan**, which is the surface a Stage-8 grader reads — not only in a Stage-5 comment. Recording them is what converts a correct implementation from unprovable to graded.

| AC | Stated method (binds the rejected limb) | Why it cannot be satisfied | Substituted method (ratified) |
|---|---|---|---|
| **AC-1** (issue body) | *"compose a fixture whose dimensions differ, then assert the rendered `Status` cells are **not all equal**"* | The criterion's own second limb — *"or explicitly renders `—` / `UNSOURCED` for any dimension with no backing metric"* — is the selected limb. **No §2 contract field backs any of the five dimensions**, so every dimension renders the identical `UNSOURCED` string and the cells are equal **by design**. A test asserting inequality of the shipped render would grade a correct implementation NOT MET. | The `(s2-resolver-varies)` self-test case, which tests the property AC-1 is really about — that the **mechanism** resolves per-dimension: `resolve_dimension` bound to two different `Rollup` fields returns two different cells, with the criterion's own control arm preserved verbatim (two rows both bound to `status` must render **equal** cells, so the probe is not merely detecting inequality). Paired with `(s2-per-dimension)`, which fails pre-fix and passes post-fix. |
| **AC-D12-1** (trusted-authored comment) | *"parse a fixture carrying `project_id: x  # note` and assert the resolved key **equals `x`**"* | That method presumes the **first** limb — a comment-strip in `_frontmatter.py`. That limb was **rejected on measurement**: 543 corpus values carry a `#` with no preceding whitespace and a naive strip corrupts all of them, and even a YAML-faithful rule truncates three measured non-template values. The criterion's own second limb — *"or the composer validates `project_id` against the declared slug charset so a polluted value fails loudly"* — is the selected one, and under it the parser resolves `x  # note` **by design**. | The `(join-key-polluted)` self-test case: `compose()` raises `ContractDrift` naming `project_id`, and the CLI returns **1**, on a fixture whose `project_id` line carries a trailing comment. The criterion's own control arm is preserved verbatim (the unmodified fixture still composes at exit 0 with `project_id == "proj-alpha"` — same instrument, same target, so the probe is not merely detecting change). |

**What is ratified is the method, not the criterion.** Both criteria stand exactly as written, including their `or` limbs; only the parenthetical method is substituted, and each substitution keeps the criterion's own control arm word for word.

---

## Deviation Log

| # | Deviation from the Stage-4 transcription source | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **The shared parser has 6 importers, not 8.** The Stage-4 Dependency Graph, Contention Map, Integration Point IP-1 and Risk R2 all state that `_frontmatter.py` is imported by **8** tools. It is **6** — `backfill-relationship-edges.py` · `build-doc-index.py` · `check-doc-frontmatter.py` · `check-version-anchors.py` · `compose-portfolio.py` · `stamp-node-frontmatter.py`. Two of those load it dynamically via `importlib`, which is why a static-import grep under-reports rather than over-reports. | Hub adversarial evaluation at the Stage-4 gate, re-derived independently at Stage 5 (probe P-2, denominator 79 tracked `*.py`, sensitivity arm fired on both a static and a dynamic importer), and measured a third time by the hub before Stage-6 dispatch | **RATIFIED — three independent measurements agree.** The transcribed sections keep the Stage-4 figure as the plan of record; every downstream artifact this release authors uses **6**. |
| **DEV-2** | **Edge E3 (#6355 → #6251) does not exist.** The Stage-4 Dependency Graph records `lint_release_corpus.py` as an importer of the shared parser, on a **weak** substrate-before-consumer edge. It is not an importer — it hand-rolls its own `parse_frontmatter` and is bound to the ADR-159 conformance fixture instead. | Same measurement as DEV-1; confirmed at Stage 5 with `lint_release_corpus.py` as the probe's specificity arm (mentions "frontmatter" 69× across 130,601 bytes read and is correctly **not** flagged) | **RATIFIED.** This *strengthens* the Stage-4 conclusion rather than weakening it: the plan already recorded E3 as "not a sequencing constraint", and it is now not an edge at all. Importers this release also edits: **4**, not 5. Risk **R2** stands as HIGH. |
| **DEV-3** | **The shell-twin agreement constraint is withdrawn.** The Stage-4 Contention Map ("Constraint on the D-12 fix") and Recommendation 4 both bind #6355's D-12 limb to agree with `release/tools/lib/frontmatter-strip.sh` and ADR-159's conformance fixture, and route that as a **mandatory Stage 5 design input**. **The constraint does not exist.** The shell library implements a different transform — emit the body, strip the block — while `_frontmatter.py` parses a block into a key→value dict; and ADR-159's fixture README carries a three-row **Bound implementations** table (the shell library · `preflight-release-body-reemit.py` · `lint_release_corpus.py`) of which `_frontmatter.py` is not a member. | Stage-5 finding **D-A** on #7330, evidenced from the fixture's own declaration of its bound set; **the hub accepted the correction on #7341** in terms — *"a brief is an input, not an authority"* | **RATIFIED AND WITHDRAWN before Engineering.** The shared name-substring plus the fixture's co-location under `core/deploy/tools/` is the plausible origin of the conflation. |
| **DEV-4** | **The D-12 fix takes the criterion's second limb: the parser is frozen, and the constraint lands at the consumer.** The Stage-4 plan and the trusted-authored comment both lead with a comment-strip in `_frontmatter.py`. Measured over 737 tracked files carrying frontmatter and 6,664 top-level keys: **639** values contain a `#` and **543** carry it with no preceding whitespace, so a naive `split("#")` corrupts all 543; and a YAML-faithful rule still truncates three measured non-template values plus a `#` nested inside a quoted string inside a flow list. | Stage-5 **DD-3 / P4** on #7330, on measured evidence; scope-locked at Collective Review | **RATIFIED.** `_frontmatter.py` gains a docstring, a frozen-semantics block and a self-test case, and **no behaviour change**. `project_id` is validated at `compose-portfolio.py` against ADR-179 D1's `^[a-z0-9][a-z0-9-]*$`, raising `ContractDrift` (exit 1) on a polluted value. The two AC methods this displaces are ratified in § Ratified AC-method substitutions above. |
| **DEV-5** | **Scope addition S-1 — the `entity_type` discovery-key guard ships.** Not in the Stage-4 plan. The same pollution hazard is open on `discover_rollups`' *discovery* key, where it fails **worse** than the join key: a polluted `entity_type` does not fail, it fails to **match**, and the composer renders a portfolio missing that project at **exit 0** with no diagnostic. | **D-Scope1** at the Collective Review scope-lock — *"All four accepted"*, this being #6355's limb | **RATIFIED AS A SCOPE ADDITION.** Equality on the accept path stays exact; the guard adds a post-walk raise and does not loosen the key. |
| **DEV-6** | **The release gains its first `add` row.** The Stage-4 File Change Matrix states *"No `add` rows and no `delete` rows in this release"* and the structural-blast-radius sub-audit rests an "empty mover-set" conclusion on it. This release now adds the D-12 ADR (#6355) and a three-walker parity test (#5817). | Collective Review scope-lock finding 4, which names both and states the consequence in terms — *"the new-executable obligation is `*.sh`-scoped and does not fire, and the empty mover-set survives because an `add` is not a mover"* | **DECLARED AT COMMIT 0, not silently absorbed.** Both rows are reconciled under § File Change Matrix → Engineering Commit-0 matrix reconciliation. The zero-`delete`, zero-rename half of the Stage-4 statement is unchanged. |
| **DEV-7** | **`core/deploy/tools/README.md` enters #6355's write set.** The Stage-4 matrix declares three paths for #6355 and does not include it. Row 67's `Used by` cell carries the **same OLD stale value** as the `_frontmatter.py` docstring consumer list, so the two holders must move together. | Stage-5 § 5.6 cascade sweep (trigger **T2**, enumerated-list update) classified it **UPDATE**; the **hub coordination determination on #7341** assigns the `Used by` cell to this card's commit C1 and the `Purpose` cell to sibling card #5817 | **DECLARED.** Fixing the docstring and leaving the README is the annotate-and-defer failure the sweep exists to catch. The row is split by cell, not by file, so the two cards cannot disagree about the consumer count. |
| **DEV-8** | **PRF-1 — the `each [STALE] if aged` clause is reconciled in the same edit that removes the interim sentence.** `core/standards/portfolio-writeback-contract.md:76` column 2 asserts `each [STALE] if aged`. That is **true at head** and **false after this change**: every dimension renders `UNSOURCED`, and `UNSOURCED` carries no marker. The Stage-5 spec's 4a edit begins at character 463 of that line; the falsified clause sits at characters 0–462, outside it, and the spec never names it. AC-4's own verifier passes with the contradiction standing. | Phase **A6.5 adversarial review** on #7330, finding **PRF-1** (Major), with the character offsets measured | **BINDING CORRECTION, APPLIED.** The clause is re-scoped in the same edit, and AC-4's verifier is extended so a future reader cannot re-introduce it. Minimal-change does not mean avoid-the-change: the smallest edit that achieves the goal still includes reconciling the contradiction being touched. |
| **DEV-9** | **PRF-2 — the frozen-semantics block is corrected on two of three axes before it ships.** As specified at Stage 5, **F-2** asserted that only flush-left `key:` lines with no internal space become top-level keys, and **F-3** asserted the value loses exactly one matching pair of surrounding quotes. Both are falsified by the live module: the internal-space guard at `_frontmatter.py:74-78` is **unreachable** (its enclosing condition is False for any flush-left line), so any flush-left line containing a colon becomes a key — the shipped rollup template yields **14** top-level keys, **2** of them full-line `#` comments; and `_strip_quotes` returns `val.strip()` *after* the slice, so `padded: "  T  "` resolves to `T`. | Phase **A6.5 adversarial review** on #7330, finding **PRF-2** (Major), measured against the live module | **BINDING CORRECTION, APPLIED.** F-2 freezes the guard **as unreachable** rather than describing behaviour it does not have; F-3 states the post-slice re-strip. Two matching assertions are added to self-test case (5) — a `#`-comment line resolving as a key, and the padded-quote case — so the corrected clauses are frozen **by test**, not by prose, which is the whole premise of the block. |
| **DEV-10** | **FMF-1 — the AC-1/AC-3 discriminator is anchored structurally, not on section-title string literals.** As specified, `(s2-per-dimension)` extracted its subject window by splitting the composed output on two section titles. The module's own EXTENSION-SEAM banner declares registry/title edits the sanctioned way to change the file; when a title moves, the window empties, the subject assertion passes **vacuously**, and the case's declared BROKEN-PROBE arm — drawn from a different section — still fires, so the collapse is invisible. Demonstrated by running the specified extractor: 10 cells and a correct pre-fix FAIL on the shipped output; **0** cells and a PASS after renaming the title, with 10 dimension rows still carrying the project RAG glyph. | Phase **A6.5 adversarial review** on #7330, finding **FMF-1** (PROC), demonstrated rather than inferred | **BINDING CORRECTION, APPLIED.** The window boundaries resolve from `SECTION_REGISTRY` rather than from literals, and an anti-vacuity assertion — extracted cell count equals `len(HEALTH_DIMENSIONS) × len(ctx.rollups)` — runs **before** the subject is evaluated, appending a BROKEN PROBE failure otherwise. The same anti-vacuity arm the spec already wrote for two of its four cases. |
| **DEV-11** | **FMF-3 / CDF-1 — the discovery-key guard uses normalize-then-compare, and states its false-negative bound.** As specified, the near-miss arm was `et.startswith(ROLLUP_ENTITY_TYPE)`, which is prefix-anchored. Measured: `entity_type: "Project Rollup (composed)"   # note` resolves to a value **beginning with a quote**, because the trailing comment displaces the closing quote so `_strip_quotes` removes no pair — equality False **and** `startswith` False, so the ordinary quoted-plus-comment shape is silently skipped at exit 0, which is the exact failure the guard exists to eliminate. | Phase **A6.5 adversarial review** on #7330, findings **FMF-3** (INPUT) and **CDF-1** (counter-design), each measured with sensitivity and specificity arms | **BINDING CORRECTION, APPLIED — the counter-design is adopted.** The `found` predicate stays **byte-identical to the spec** (exact equality, accept path unchanged, happy path behaviour-preserving); only the near-miss predicate normalizes — strip one matching quote pair, strip a trailing ` #…` run, then test **equality** — used for the guard's comparison only and never for a returned value. **Both bounds are stated:** it cannot over-match (the near-miss arm now tests equality, not a prefix), and its residual false-negative class is named in the guard's own comment rather than left as an unbounded coverage claim. |
| **DEV-12** | **`PROJECT_ID_RE` is declared locally rather than cited from a shared grammar.** ADR-179 D1 declares `ENTITY_REF_RE` *"defined once … and cited, never restated"* and names `core/schemas/entity-field-schemas.md` as its home. That delivery child has **not landed** — the literal appears in exactly 1 file (the ADR itself) across 1,665 tracked files, with a live control token firing in 5 files including that very schema file. | Stage-5 **R-3** on #7330, measured as probe P-3 | **ACCEPTED RESIDUAL, declared not absorbed.** The composer declares `PROJECT_ID_RE` locally with a pointer comment naming the shared grammar as its future home, so the re-point is a discoverable one-line change. Blocking a real defect on an undelivered schema edit would trade a correctness fix for a governance nicety. |
| **DEV-13** | **Three next-release observations are filed, none executed.** **D-B:** the shipped `operations/templates/project-rollup-template.md` authors a trailing `#` comment on its own `project_id:` line and on 8 others, so the template family's documentation convention and the parser's frozen F-4 semantics now disagree by design across 87 measured values in 14 files. **D-D:** `weekly-status-rollup/SKILL.md` names its fifth dimension `Integration Risk` while the contract and the composer both use `Integration`. **D-E-obs:** contract §2's `top_risks[]` row declares a type without an `impact` field while its own Notes cell says `impact` is what the portfolio-rollup query keys on. | Stage-5 **R-4** on #7330 | **OUT OF SCOPE HERE, ROUTED.** D-B is a 14-file template edit; D-D is a skill edit that would reclassify this card `sanctioned-session-required` and undo **D-E**; D-E-obs is a §2 field-shape change carrying the producer cascade that rejected option **O1**. |
| **DEV-14** | **No mechanized parity between contract §4.1 and the composer's `HEALTH_DIMENSIONS`.** §4.1 is the governed SSOT and `HEALTH_DIMENSIONS` its execution form; nothing asserts they agree, and an invariant carried by a pointer comment cannot fail. | Stage-5 **R-2** on #7330 | **ACCEPTED AS RESIDUAL, routed as a next-release issue.** Binding them needs a doc-parsing seam the composer deliberately does not have (stdlib-only, self-contained, reads no path outside its own tree and fixture), and inventing one inside a 4-point card is the wrong place for that architectural call. The risk is bounded today because every row's backing field is `None` — the mapping has no *value* to drift, only labels — so a divergence stays cosmetic until a backing field lands. **Sequence the follow-on ahead of the first backing field, not after it.** |
| **DEV-15** | **`operations/skills/weekly-status-rollup/references/metric-registry.md` is NOT DELIVERED.** The Stage-4 matrix carries it as a `CONDITIONAL:mapping-homed-in-skill-reference` row. | **D-E** at the Stage-4 gate, resolved **by fact rather than by preference**: the hub read the deployed skill-editor exemption list, which exists and carries exactly one entry that is **not** `weekly-status-rollup` (subject probe 0; control arm 1 entry present, so the reader is alive and the zero is meaningful) | **CONDITION DID NOT FIRE — correctly not delivered.** The governed dimension→metric mapping is homed in `core/standards/portfolio-writeback-contract.md` §4.1 instead. That satisfies AC-2 (a standard *is* a governed statement), keeps the skill reference read-only, and leaves every card in the release `unconstrained`. |
| **DEV-16** | **The D-12 decision record is filed under `core/ADRs/`, not the `release/ADRs/` path the Stage-5 additions matrix declared.** The row above declared `release/ADRs/ADR-<frontmatter-laxity-is-constrained-at-the-consumer>.md`; the delivered file is `core/ADRs/ADR-195-frontmatter-laxity-is-constrained-at-the-consumer.md`. **The relocation is correct and the plan was the thing out of date** — the record governs a core deploy tool with six core consumers, carries no release-pipeline mechanics, and validates against a grammar that also lives in core. | `release/ADRs/README.md` § Scope, in terms: *"Decisions that apply platform-wide (cross-module governance, cardinality models, PMBOK alignment, module boundary definitions, tooling design) live in `core/ADRs/`"*. The ADR number sequence is global across both directories, so the module choice does not move the number. | **RECONCILED AT STAGE 7, not at Commit 0 where it should have been.** PR #7404 carried the deviation as D-9 and the Commit-0 output comment asserted every deviation was transcribed into this log; this one was not, so the plan — the surface Stages 8, 9, 12 and 13 all read — declared an `add` the release did not deliver, and `verify-release-plan.sh` reported `FCM-1 | fcm-delivery | … | declared-add-not-delivered` FAIL. The matrix row is corrected to the delivered path and this row records the delta. **The ADR itself is not moved.** |

---

## Verification Evidence

*(Populated at Stage 6 / Stage 7 as each card's verification runs. Each entry names the criterion, the command, and the observed result — a null result carries its control arm on the same instrument against the same target.)*

### #6355 — Engineering (Stage 6)

Recorded on the Stage-6 sub-task **#7341** output comment: the C1/C2 commit SHAs, the regression floor (the shared parser's own self-test, each of the six consumers' self-tests, and the corpus-equivalence probe over every tracked `*.md` at `HEAD~1` and `HEAD` **with its seeded sensitivity arm's observed delta**), and the per-criterion evidence for all seven acceptance criteria.

---

## Deployment Execution Log

*(Populated at Stage 12.)*

---

## Change Description

### Outcome

The deploy tools and tests resolve repo, root, project and dimension correctly at their edges: a `GITHUB_REPOSITORY` fallback that refuses rather than mis-verdicts, one shared dot-segment predicate across all three corpus walkers, the corpus-root case of the project resolver, SELF resolved from `BASH_SOURCE` before any `cd`, distinct causes distinguished in the g1 form-family runner and in the deciders-carveout guard, a mode-template preserve loop over the whole population, a banned-jargon list whose standard and enforcement agree, and a portfolio Health Indicators table whose five dimensions each carry their own resolved value or an honest `UNSOURCED` with its reason.

### Issues resolved

Nine members. Each is marked as closed at Stage 13 per the standard close-out; no member closes earlier, and no close-family keyword appears next to any number outside § Issue References.

### Key decisions

**D-A** Release Class `routine`, Stage-9 depth Deep for the `#6355 / #5817 / #5832` cluster · **D-B** card re-sizing, raw 17 → 21 pts · **D-C** SINGLE topology, P0 fully-serial · **D-D** #5817 ships shared-predicate extraction · **D-E** the governed mapping homes in the contract, not the skill reference · **D-Version** bump-class `minor` · **D-A65** all five Stage-5 outputs receive an independent adversarial design review · **D-Scope1** all four Solutioning scope additions accepted · **D-S3** #5707's equivalence-claim narrowing ratified · **D-S4** #6355's honest-empty S2 posture confirmed, with a rider: an explicit Stage-8 acceptance re-look at how the rendered section actually reads before it ships.

### Reversibility

**CHEAP / Confidence HIGH** for Slice B (#5707 · #6251 · #6111 · #6174 · #6242 · #5556) — six textually independent cards, zero shared files, single-commit revert applies cleanly. **MODERATE / Confidence HIGH** for Slice A (#6355 · #5817 · #5832) — three cards entangled across `_frontmatter.py`, `compose-portfolio.py` and `stamp-node-frontmatter.py`; granularity is the whole merge, and the plan states that rather than implying finer granularity than it has. No schema change, no data migration, no host-side state, no published artifact mutated. **The revert is self-announcing**: the new self-test cases fail on reverted code, so a partial revert turns `selftest-discovery` red rather than silently restoring the defect.

### Downstream impact

`core/deploy/tools/_frontmatter.py` gains a docstring, a frozen-semantics block and a self-test case with **no behaviour change**, so its six consumers see no delta — asserted by the corpus-equivalence probe in the regression floor rather than claimed. `core/standards/portfolio-writeback-contract.md` gains a governed §4.1 mapping and loses its interim render-posture sentence. One new ADR records the decision that a deliberately-lax shared parser is frozen at the reader and constrained at the consumer that declares a shape.

### Cross-references

[`release-process.md`](/release/governance/release-process.md) · [`stage-06-engineering.md`](/release/references/pipeline/stage-06-engineering.md) · [`portfolio-writeback-contract.md`](/core/standards/portfolio-writeback-contract.md) · [`doc-link-maintenance-protocol.md`](/core/standards/doc-link-maintenance-protocol.md)

---

## Baseline pin

`origin/main` @ `a30838589583bcddf5f88183cfff1a8ea2475300` — the Stage-4 planning pin, re-verified unmoved at Engineering Commit 0. Stage-9 Phase A6.5 re-checks mid-pipeline divergence against this anchor.

---

## Issue References

References #6355, References #5817, References #5707, References #5832, References #6251, References #6111, References #6174, References #6242, References #5556.

Every member stays open through Engineering and QA and is marked as closed at Stage 13.
