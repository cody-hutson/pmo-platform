---
title: Release Plan — pack-conformance-and-parity (pack conformance posture, content lint, and the first pack control)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: pack-conformance-and-parity
release_class: novel
reversibility: CHEAP / Confidence HIGH for two of three members — the posture record and the content lint are additive edits plus new files, and `git revert -m 1` of the merge restores `main` byte-for-byte. MODERATE / Confidence HIGH for the gate-bind member — the commit reverts cleanly, but the reversibility *class* of the pack-gate surface does not revert with it: once a control has been declared in a shipped pack, the control-field layer's MODERATE band applies to the surface thereafter.
---
# Release Plan — `pack-conformance-and-parity`

**Milestone:** `pack-conformance-and-parity` (milestone #374) · hub sub-task **#7259** = the Stage 4 plan source together with its two **Decision Recorded** comments, its CIAC amendment and its CIAC correction · **#7272** = the Stage 5 design source for the posture card · **#7274** = the Stage 6 Engineering sub-task that authored this file.

**Version identity:** **versioned** — bump-class **`minor`**; the concrete `vX.Y` binds only at the Stage-12 atomic claim, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp token. The Commit-0 version re-verify ran in full — see § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch (`release/pack-conformance-and-parity`), one PR opened at Commit 0 as a draft, one merge, base `main`. This plan lands as **Engineering Commit 0**.

**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch. Justified independently by the three-way write on one schema section recorded in § Contention Map. Every non-serial posture prohibits force-push (including `--force-with-lease`) on the shared release branch; P0 is in force, so the prohibition is moot here and is recorded for completeness.

**Release class:** `novel` — rendered by the operator at the Stage-4 gate (**D2**, `routine` → `novel`). Differentiation posture: engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7259, **as amended** by that sub-task's CIAC amendment and its later CIAC correction, together with both **Decision Recorded** comments on it, and reconciles them to the Stage-5 design specification for the posture card posted on sub-task #7272 and its wave-1 gate decision comment. Where a later disposition superseded a Stage-4 value, the transcribed section carries the **ratified** value and § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination, declared at Bundle as intent-to-bump. It sets the floor and binds no concrete number. The Stage-4 recorded determination was the provisional display `v4.61` (anchor `v4.60` + minor bump); the Commit-0 re-verify recomputed the same value against fresh authoritative host state. See § Commit-0 Version Re-Verify Record. |
| **Date Created** | 2026-09-10 (Thursday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/pack-conformance-and-parity` |
| **PR** | (populated at Stage 6 — this release ships as a SINGLE PR, opened draft at Commit 0) |
| **Milestone** | `pack-conformance-and-parity` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-10, domain: governance }`

**Domain classification.** Form **X** (sourcing-exempt): the File Change Matrix is entirely internal `pmo-platform` artifacts — a schema, a standard, an architecture decision record, deploy tooling, test fixtures, pack content and the release corpus — so no external body of practice is consumed and no Form-A citation exists to record. Dominant domain `governance` — the schema, the standard and the decision record are the release's centre of gravity, and the posture card writes nothing but governance. Secondary domain `software` — the content lint's `core/deploy/` rows. Dominant is recorded in the label, secondary noted here, per the A3-time classification rule. Transcribed unchanged from Stage-4 Phase A1.5; no Mode B → Mode A upgrade applies, because no external source is consumed at all.

**A note on the one place a practice citation *does* appear.** The gate-bind card's `[[controls]]` declaration will carry a `source` naming the Kanban Method. That is **pack content declaring its own provenance**, not this release consuming an external body of practice as an input to its design — the distinction the Form-X classification turns on. The classification is unchanged by it.

---

## Commit-0 Version Re-Verify Record

The first Engineering spoke under SINGLE topology re-runs the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1** — refresh authoritative host state | **EXECUTED.** `origin/main` = `a30838589583bcddf5f88183cfff1a8ea2475300`. The Stage-4 baseline pin was `a3083858`; **the substrate did not move between Planning and Engineering** — zero commits landed on `main` in the interval, so the plan's pin and the Commit-0 base are the same commit. | `git fetch --tags origin`; `git fetch origin main`; `git rev-parse origin/main` |
| **2** — recompute next-free for bump-class `minor` | **EXECUTED. Next-free = `v4.61`.** `anchor()` = **v4.60**, the highest claimed version over the refreshed tag set. `FLOOR(minor)` = `(4, 61)`; `v4.61` is absent from the claimed set, so the walk terminates at the floor. | **Tags (host-authoritative, post-fetch):** 204 refs, 199 `vX.Y`-shaped; maximum `v4.60`. **Remote arm:** `git ls-remote --tags origin` returns **0** refs matching `refs/tags/v4.61`. **Ledger arm:** `git show origin/main:release/releases/RELEASE_LOG.md` carries **0** occurrences of `v4.61`. |
| **3** — PROCEED / HALT on claimed-set membership | **PROCEED.** The planned version `v4.61` is **not** in the claimed set **and** equals the recomputed next-free, which is the conjunction the gate requires. No colliding tag and no colliding ledger row exists. | **Sensitivity arm, same readers, same inputs:** `v4.60` resolves **present** on the local tag set (`True`), **1** matching ref on `git ls-remote --tags origin`, and **16** occurrences in the ledger — so membership detection demonstrably fires. **Specificity arm:** the fabricated tag `v9.99` returns **0** on the same tag set the sensitivity arm just resolved non-zero. **The tag arm binds; a missing ledger row is never on its own evidence of freeness.** |
| **3b** — stamp-manifest assertion | **EXECUTED post-write, pre-commit.** `release/tools/claim-version.sh --verify-stamp pack-conformance-and-parity` → **exit 0**. | Read-only and network-free — the identical pre-flight the Stage-12 atomic claim runs. The Header `**Version**` cell carries the literal unresolved `{{RELEASE_VERSION}}` token and no other text, which is what the Stage-12 claim resolves and renames on. |

**Why the number is recorded but not bound.** Step 2's `v4.61` is a Commit-0 *reading* of authoritative state, not a claim. Nothing is held between now and the merge; a concurrent release that merges first takes `v4.61` and this release's claim recomputes upward at the compare-and-swap. Recording the reading makes the Commit-0 PROCEED reproducible without asserting a reservation the allocation rule does not create. **The numbers in this section are deliberately not restamped later** — they are a reading at a named SHA, reproducible by re-running the recorded commands at that SHA.

**`${AUDIT_DATE_UTC}` resolution.** Resolved once at this commit via `date -u +%Y-%m-%d` → **`2026-09-10`**. Its single consumer is the `date:` frontmatter field and the dated `source_observations:` entries of the architecture decision record this release adds. No other artifact in this release hardcodes a date in a load-bearing position. Local civil date at resolution time was 2026-09-10 (Thursday); the UTC anchor and the civil date agree, and the agreement is stated rather than assumed.

**Architecture-decision-record number re-verification at Commit 0.** `python3 release/tools/renumber-adr.py --detect` at this base reports `ANCHOR 194 origin/main` · `NEXT-FREE 195` · `CLAIMED-SET-BRANCH-ONLY 195 (detection only — never binds)`. The hub-assigned number **195** is confirmed against a fresh anchor read; the branch-only claim is detection-only and does not bind. Prose citations stay tokenized as `{{ADR:pack-content-lint-sibling-vs-extend}}` until the Stage-12 stamp; the literal number appears only in the record's filename, title and frontmatter.

---

## Scope

### Issues Included

| # | Issue | Title | Priority | Size | Labels |
|---|-------|-------|----------|------|--------|
| 1 | #6370 | Decide the conformance posture for incomplete packs and kits | P3 | `size:S` (2 pts) | `type:spike`, `project:methodology-packs`, `status: bundled` |
| 2 | #1971 | Bind the Kanban pack set-aggregate WIP gate | P3 | `size:L` (8 pts) | `type:story`, `project:methodology-packs`, `cluster: templates-schemas`, `tracker-schema`, `status: bundled` |
| 3 | #6371 | Lint packs and kits for content completeness | P3 | `size:L` (8 pts) | `type:story`, `project:methodology-packs`, `status: bundled` |

**Bundle size: 18 raw / 21 effective points** (`novel` class weight 1.15; `round_half_up(18 × 1.15) = 21`) — inside the 15-25 target band. The band was reached by recognizing real scope twice, never by padding: the gate-bind card was re-sized `M → L` at the Stage-4 gate when the first `[[controls]]` declaration was absorbed into it, and the content-lint card was re-sized `M → L` at the Stage-5 wave-1 gate when its rule set grew from one family to three.

### Exclusions

Enumerated over the classes the bundle-composition read reasoned about — adjacent open cards on the same epic, coordination edges, and cards on neighbouring milestones:

- **#3607 / #3608** (archetype packs) — downstream consumers that accept against the lint this release ships. Out of bundle by design; they are the work that *reaches* this release's flip criterion, not work this release performs.
- **#5827** (the `bug`-kind-in-`_common` question) — OPEN and carrying **no** milestone. A coordination edge only: nothing in this bundle's write set touches it and no member's acceptance criteria reference it. It receives no close-family reference anywhere in the release PR.
- **#3609** — milestone `archetype-catalog-completion` since 2026-08-30. Correctly excluded.

### Dependency Graph

```
                    #6363 (CLOSED, kit-content-and-defaults) 
                      |  provenance annotation — the surface the
                      |  content lint's source-audit arm reads
                      v
  #6370 ------------> #6371 ------------> #3607, #3608 (out of bundle)
  posture             content lint
  (spike)             (story)
     |
     |  the posture decides the MODE the lint runs in
     |
  #1971  --- no dependency edge to either ---  (independent build)
  gate bind          but see the Contention Map: it writes the same
  (story)            schema section, and it CREATES the instance the
                     lint must be able to grade
```

| Edge | Direction | Class | Verified at the baseline |
|---|---|---|---|
| `#6370 → #6371` | #6371 blocked-by #6370 | **HARD, in-bundle** | Native edge, live: `#6371 blocked-by: #6363, #6370`; `#6370 blocking: #6371, #6359` |
| `#6363 → #6371` | #6371 blocked-by #6363 | **HARD, cross-milestone — CLEARED** | #6363 is CLOSED; its milestone is CLOSED and shipped, its ledger row reads `VERIFIED`. The provenance annotation is on `main`. |
| `#1971 → (none)` | — | **INDEPENDENT** | Native edges empty in both directions. Its only stated dependency is on the meta-schema section, which is corpus, already present, and not a ticket edge. |

**Zero circular chains.** Verified over the complete in-bundle edge set: **1** directed edge across **3** nodes. A cycle requires ≥2 edges among the bundle's own nodes; there is 1. This is a structural argument over an enumerated 3-node graph, not a probe — the denominator is the graph itself and it is stated in full above.

#### Cross-Milestone Dependency Validation

**G3-07 Status:** `PASS — 2 dependency edge(s) checked, 0 cross-milestone violations`. The one cross-milestone edge resolves: its target is Done in a closed milestone.

### Bundle Refresh State

N/A — enumerated over the four refresh triggers (T1 new approved theme-matching issues · T2 priority shift · T3 dependency-state change · T4 Stage 4 boundary); the composition lock recorded on the milestone at Stage 4 entry is the operative state and no trigger has fired since.

---

## Implementation Sequence

The milestone's declared internal sequence was posture → content lint → gate bind. The operator re-sequenced it at the Stage-4 gate (**D4**) to **`{#6370, #1971}` → `{#6371}`** — ordering, not concurrency: Stage 6 stays one chip at a time under P0.

| Wave | Issue | Why here |
|---|---|---|
| **1** | **#6370** (posture spike) | The only true foundation. Its verdict sets the mode the content lint runs in. Nothing else can be designed against an undecided posture. |
| **1** | **#1971** (gate bind) | No dependency edge to either other card. Building it in wave 1 produces the *first non-trivial `checks[]` instance in the corpus* — the fixture the lint most needs to grade — and surfaces the first-`[[controls]]` scope while a wave remains to absorb it. |
| **2** | **#6371** (content lint) | Consumes the posture (mode) and the already-merged provenance annotation. Benefits from the gate bind having landed, but is not blocked by it — the lint can ship against fixtures alone. |

**Merge order is mandatory and is `#6370 → #1971 → #6371`.** It is not the same claim as the wave order, and the difference is load-bearing: all three cards write one schema section, and the content-lint card's edit is the one that must be **true about the other two**. Two independent derivations reach the same order — the Stage-4 contention map, and the Stage-5 blast-radius read of the register's runner-resolution contract (a named-gap row must not carry a runner pointer until the runner exists, so the pointer lands with the runner and not before).

### Issue #6370 — the conformance posture

**Change Specification:**
- **Files modified:** `core/schemas/work-item-type-schema.md` (§1.2.1 gains a posture subsection; one stale corpus count swept) · `core/standards/gate-efficacy-standard.md` (two stale corpus counts swept; one flip-decision row added)
- **Files added:** `core/ADRs/ADR-195-pack-content-lint-sibling-vs-extend.md`
- **Change description:** Record the two-surface posture — a kind with no fields and no criteria **passes** grammar-conformance permanently and **warns** at content-completeness — with the boundary between the two stated as a predicate, the graduation path named with its flip criterion, and the sequencing consequence for the archetype-breadth epic stated. The findable condition is **silence** (a surface whose array is absent), never **emptiness** (`= []` carrying a block-level `source`, which is a reasoned empty set and is complete content).
- **Estimated complexity:** Low (governance authoring; no executable change)
- **Dependencies:** None

### Issue #1971 — the gate bind and the first pack control

**Change Specification:**
- **Files modified:** `core/packs/kanban/pack.toml` (bind the set-aggregate WIP gate; declare the pull-limit control) · `core/schemas/work-item-type-schema.md` (the adjacent scope-boundary paragraph, once a control exists)
- **Files added (conditional):** an architecture decision record for the control-provenance determination, if the determination is recorded as a decision rather than inline in the schema
- **Change description:** Fill the unbound `checks` assignment under the Kanban gate table with a set-aggregate condition, express class-of-service as a `kind_filter` rather than a label group, declare the corpus's **first** `[[controls]]` entry for the pull limit, and record the `source`-on-`[[controls]]` provenance determination the schema assigns to whichever change first declares a control.
- **Estimated complexity:** Medium–High (first use of a grammar facet no shipped pack has exercised; crosses a recorded reversibility band)
- **Dependencies:** None

### Issue #6371 — the content-completeness lint

**Change Specification:**
- **Files modified:** `core/deploy/tools/check-work-hierarchy.py` (a new `--validate-pack-content` mode and a `PACKC-*` rule namespace) · `core/deploy/deploy.sh` (register a new check) · `core/deploy/tools/README.md` (the consumer list) · `core/schemas/work-item-type-schema.md` (the runner is no longer NONE) · `core/standards/gate-efficacy-standard.md` (both named-gap rows gain their runner pointers)
- **Files added:** a discrimination fixture pair under `core/deploy/tests/fixtures/packs/`
- **Change description:** Three rule families over one shared pack reader. Family **C** is kind-scoped and answers *did the author take a position on this surface*. Family **P** is entry-scoped and answers *is each position attributed*. Family **S** is entry-shape and answers *does each entry carry the declared tuple with in-domain values* — it exists so the check-shape register row's runner pointer is honest. The check is a **sibling** of the pack-grammar check over a shared primitive, never an extension of it.
- **Estimated complexity:** High (three rule families, a new check, a new fixture pair, and two register rows)
- **Dependencies:** #6370 (native, hard)

---

## Stage Applicability Matrix

| Issue | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9 Review | S10-11 | S12 Exec | S13 Close |
|---|---|---|---|---|---|---|---|---|
| **#6370** | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY | compress | APPLY | APPLY |
| **#6371** | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY | compress | APPLY | APPLY |
| **#1971** | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY | compress | APPLY | APPLY |

**All stages apply to all three cards. Nothing is skipped, and each is a decision rather than a default.** Solutioning on the posture card *is* the work — skipping it would be skipping the spike. Solutioning on the gate-bind card is mandatory rather than discretionary: the control declaration, the `scope` selection, the unresolved-disposition value and the reversibility-band crossing are all live design decisions with no default answer. Dev testing and QA apply to all three because every card has functional impact — including the posture card, whose flip criterion would otherwise ship with no fixture proving that warn-mode actually warns, which is the exact vacuity the gate-efficacy standard exists to prevent.

**Stages 10 and 11 compress**, on the stage specs' own stated satisfaction rather than a hub judgment: the operator-reviewed PR diff at Stage 9 is the dry run, and git history is the snapshot with the pre-merge commit as the captured state.

**Parallel-eligible spoke count** (Stages 5 / 7 / 8): **3 per stage.** Worst parallel batch = 3, realizable only under a non-serial posture; P0 is in force, so the realized batch width at Engineering is 1.

---

## File Change Matrix

```
# ── #6370 · the conformance posture (sequence position 1) ──
core/schemas/work-item-type-schema.md                                   edit
core/standards/gate-efficacy-standard.md                                edit
core/ADRs/ADR-195-pack-content-lint-sibling-vs-extend.md                add

# ── #1971 · the gate bind and the first pack control (position 2) ──
core/packs/kanban/pack.toml                                             edit
core/schemas/work-item-type-schema.md                                   edit

# ── #6371 · the content-completeness lint (position 3) ──
core/deploy/tools/check-work-hierarchy.py                               edit
core/deploy/deploy.sh                                                   edit
core/deploy/tools/README.md                                             edit
core/schemas/work-item-type-schema.md                                   edit
core/standards/gate-efficacy-standard.md                                edit
core/deploy/tests/fixtures/packs/hollow-kind/pack.toml                  add
core/deploy/tests/fixtures/packs/complete-kind/pack.toml                add

# ── release-scoped ──
release/releases/plans/pack-conformance-and-parity_RELEASE_PLAN.md      add
release/releases/RELEASE_LOG.md                                         edit
```

### CONDITIONAL rows

| Path | Intent | Condition token | Resolves at |
|---|---|---|---|
| `core/ADRs/ADR-NNN-first-pack-control-declaration.md` | add | `CONDITIONAL:control-provenance-is-adr-class` | The gate-bind card's Stage-6 spoke, when it decides whether the `source`-on-`[[controls]]` determination is recorded as a decision record or inline in the schema section that assigns it |

**The posture card's own architecture-decision-record row is NOT conditional and is promoted here.** Stage 4 listed it conditional on whether the posture warranted its own record. Stage 5 resolved that condition: the posture itself needs none (the cross-epic decision it settles was already resolved against the shipped grammar), but the **siting** determination discovered at Stage 5 by measurement — sibling check over a shared primitive versus an in-place extension — is decision-record class on two independent triggers. The row moved into the unconditional set **in this commit**, carrying its now-concrete path, per the authoring contract's fired-conditional rule.

### Read-only inputs

These are READ and never edited by this release:

- `core/deploy/tools/check-label-parity.py` — READ (the label-parity premise the milestone's BEFORE clause once asserted; already fixed on `main`)
- `core/ADRs/ADR-188-pack-configurable-vs-platform-fixed-boundary.md` — READ. Its `source_observations:` block records the corpus as it stood at authoring and is **PRESERVED**, never rewritten; see § Deviation Log DEV-3.
- `core/packs/scrum/pack.toml`, `core/packs/_common/pack.toml` — READ (audited for the hollow-content condition; both clean)

### Release-wide explicit non-scope

- `core/deploy/tools/check-label-parity.py` — **NOT EDITED.** The label-parity gate is not this release's work; the milestone's BEFORE clause that named it was corrected at Stage 4 because the defect it described no longer exists.
- The shared warn-string in the emitter that names a mode file as the graduation form — **NOT EDITED.** A real, small inconsistency found during the Stage-5 survey, correctly out of scope; routed as an intake item rather than absorbed.

### New-executable companion obligations

N/A — enumerated over the matrix's `add` rows: three files are added and none is a tracked executable script (`*.sh` invoked via `bash` / `sh` / `source` / `.`). The two fixture manifests are data read by an existing tool; the decision record is prose. No script-execution allowlist row is owed, and no CI wiring statement is owed.

---

## Agent-Editability Read

**Derivation** — controls read at commit `a3083858`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — `case "$ABS_TARGET"` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: **2 blocks observed**. Four such `case` blocks exist in the file; the other two invoke a different rule id and the tier determination respectively and are not part of the floor. The surviving **tracked** floor set projects to `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md` and `release/governance/RELEASE_PROTOCOL.md`. The mirror **source** at `core/rules/` is not floored; only the deployed mirror is.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — the scope regex requires a `<module>/skills/<name>/` path segment; the exemption list resolved from the deployed hook directory is **undetermined**.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|------|----------------|----------|--------------|-----------|-----------|----------------|
| #6370 | `core/schemas/work-item-type-schema.md` | no | no — conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6370 | `core/standards/gate-efficacy-standard.md` | no | no — conjunct 1 false | `unconstrained` | | |
| #6370 | `core/ADRs/ADR-195-*.md` | no | no — conjunct 1 false | `unconstrained` | | |
| #1971 | `core/packs/kanban/pack.toml` | no | no — conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #1971 | `core/schemas/work-item-type-schema.md` | no | no — conjunct 1 false | `unconstrained` | | |
| #1971 | `core/ADRs/ADR-NNN-*.md` (conditional) | no | no — conjunct 1 false | `unconstrained` | | |
| #6371 | `core/deploy/tools/check-work-hierarchy.py` | no | no — conjunct 1 false | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6371 | `core/deploy/deploy.sh` | no | no — conjunct 1 false | `unconstrained` | | |
| #6371 | `core/deploy/tools/README.md` | no | no — conjunct 1 false | `unconstrained` | | |
| #6371 | `core/deploy/tests/fixtures/packs/*/pack.toml` | no | no — conjunct 1 false | `unconstrained` | | |
| #6371 | `core/schemas/work-item-type-schema.md` | no | no — conjunct 1 false | `unconstrained` | | |
| #6371 | `core/standards/gate-efficacy-standard.md` | no | no — conjunct 1 false | `unconstrained` | | |

**Which conjunct decided:** conjunct 1 (the scope regex) is false for **every** write-set path in this release — no path carries a `<module>/skills/<name>/` segment. Conjuncts 2 and 3 were therefore never reached, and the undetermined exemption list is **not load-bearing here**. Per-path rows are retained, never collapsed into the card class. **All three cards are `unconstrained`** — the correct and informative all-negative output for a write set that is entirely schemas, standards, decision records, deploy tooling and pack content.

---

## Contention Map

| File | #6370 | #1971 | #6371 | Severity |
|---|---|---|---|---|
| **`core/schemas/work-item-type-schema.md`** | **edit** §1.2.1 (add the posture subsection; sweep one count) | **edit** §1.2.1 (the adjacent scope-boundary paragraph, once a control exists) | **edit** §1.2.1 (the runner is no longer NONE) | **MULTI-WAY — 3-way, same section** |
| `core/standards/gate-efficacy-standard.md` | **edit** (sweep two counts; add one flip-decision row) | — | **edit** (both named-gap rows gain runner pointers) | **BINARY** |
| `core/ADRs/ADR-*.md` | **add** | **add** (conditional) | — | **NONE — distinct files** |
| `core/deploy/tools/check-work-hierarchy.py` | — | — | **edit** | NONE |
| `core/deploy/deploy.sh` | — | — | **edit** | NONE |
| `core/deploy/tools/README.md` | — | — | **edit** | NONE |
| `core/deploy/tests/fixtures/packs/…` | — | — | **add** | NONE |
| `core/packs/kanban/pack.toml` | — | **edit** | — | NONE |

**The three-way overlap on one schema section is this release's real contention risk, and it is worse than a line-level conflict.** The three edits are *semantically coupled*: the posture card decides the posture, the content-lint card's edit records that the posture now has a runner, and the gate-bind card's edit changes what that runner must grade. Three spokes editing one section under three different premises is how a corpus section ends up internally inconsistent while every individual diff looks correct. **Mitigation:** the mandatory merge order above, plus the release-scoped cohesion criterion that grades the section's internal consistency after all three land. Under P0 fully-serial the line-level half of the risk is largely absorbed; the *semantic* half is not, which is why the cohesion criterion exists.

**Architecture-decision-record number contention.** If both wave-1 cards author a record they claim from one global gap-free sequence spanning two directories, enforced whole-tree. Two spokes computing next-free independently would collide. **Mitigation, applied:** the hub assigned both numbers from a single anchor read before either spoke launched, and this spoke re-verified its assignment against a fresh anchor read at Commit 0 rather than recomputing next-free on its own.

**Probe record for this map.** The matrix is derived from the change specification, not measured from a repository scan — there was no branch to diff when it was authored. Its denominator is the 14 write-set rows enumerated in the File Change Matrix, each traced to a card's stated affected files or to the surface its acceptance criteria name. **No measured zero is asserted anywhere in this map** — a `NONE` cell means *no second card's specification names this file*, over that enumerated denominator.

---

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| **R1** | **The gate-bind card's `limit_ref` binding requires the corpus's first `[[controls]]` declaration**, and the schema assigns the unresolved `source`-on-controls provenance decision to whichever change first declares a control. | High | High | **Absorbed at the Stage-4 gate (D3).** The card body was amended to name the declaration and the provenance decision as in-scope, three acceptance criteria were added, and the card was re-sized `M → L`. No longer a Stage-6 surprise. | Stage-6 spoke for #1971 |
| **R2** | **The control-field layer's recorded reversibility band crosses CHEAP → MODERATE once packs declare controls**, and this release performs that crossing. The pack-grammar surface's cheap window is already recorded as confirmed shut. | High | High | **A genuine one-way door, gated again at Stage 5 as an explicit operator decision rather than a Stage-6 side effect.** The commit reverts; the *class* does not revert with it. Recorded in the plan's `reversibility:` frontmatter as the release's MODERATE limb. | Operator |
| **R3** | **The three-way write on one schema section** — three spokes editing one section under three different premises. | Medium | Medium | Enforce the merge order; the content-lint card's schema edit is authored last because it must be true about the other two. P0 fully-serial absorbs the line-level half. The release-scoped cohesion criterion grades the semantic half. | Hub |
| **R4** | **The gate-bind card ships a declaration nothing executes.** No consumer anywhere evaluates a set-aggregate condition — independently re-confirmed at Stage 5 as **0** occurrences in executable files. | Medium | Low | **Not a defect — it is the documented corpus/adapter split**: the pack declares what practice prescribes and a deployment's adapter binds it. State it as the intended outcome in the card's acceptance criteria and in the release note, so acceptance grades the declaration's conformance rather than its runtime behaviour. | Stage-6 spoke for #1971 |
| **R5** | **Architecture-decision-record number collision** between the two wave-1 cards across the two-directory global sequence. | Medium | Low | **Mitigated and verified.** Both numbers assigned from one anchor read before launch; re-verified at Commit 0 against a fresh read. | Hub |
| **R6** | **The content lint forks a second pack validator**, creating two readers of the pack corpus that can disagree — on a baseline whose `/usr/bin/python3` is 3.9 with no `tomllib`, so a second reader means a second hand-rolled TOML dialect. | Medium | Medium | **Closed at Stage 5 by determination:** `extend` the primitive (it carries the only 3.9-compatible pack reader in the tree), `net-new` the check. Recorded as an architecture decision so the next author reaching for the same shortcut finds the measured reason not to. | Stage-6 spoke for #6371 |
| **R7** | **The array-scoped trap.** An array-scoped rule (*`checks` is absent-or-empty*) fires on most shipped criteria tables including both of the pack-grammar check's discrimination fixtures, and that branch increments the issue counter outside the warn-mode gate. | Medium | High | The schema had already decided this: the provenance runner must be **entry-scoped**. Stage 5 found that the entry-scoped shape alone cannot satisfy the lint card's first criterion — a hollow kind has no entries to range over — so the answer is **families, not one rule**: entry-scoped provenance plus a kind-scoped completeness rule whose unit is the kind × surface and which does **not** fire on a reasoned empty set. | Stage-6 spoke for #6371 |
| **R8** | **The sibling check's control arm is blocking from day one**, even while its findings are not. The check shape it copies increments the issue counter **outside** the mode gate on the discrimination branch. | High | Low | **Correct and intended — but it must be stated**, because "the check ships warn" is otherwise read as "nothing about it can fail the deploy." The accurate claim is: **findings are non-blocking at ship; loss of discrimination is blocking at ship.** Carried into the lint card's acceptance criteria and into § Verification Plan. | Stage-6 spoke for #6371 |
| **R9** | **The lint ships with no firing population.** The shipped corpus is content-complete, so the check ships green and the specificity reading its own standard requires cannot be taken. | High | Low | **This is the named blocker in the flip-decision row, not a defect.** The flip is criterion-gated on a repo-derivable threshold reached by work already scheduled, never on a calendar. A gate with no sample is not a gate that works; it is a gate not yet observed, and the row says so. | Operator, at the flip |

---

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered) — P0 fully-serial, one spoke at a time |
| **Commit strategy** | One or more coherent commits per card, pushed after each slice. Commit 0 is this plan file. |
| **Review approach** | **Single PR for the entire release**, opened as a draft at Commit 0 and marked ready when the last card lands |
| **Deployment mechanism** | Git merge + `./deploy.sh --deploy`; no skill package is touched by this release |
| **Stacked-base cleanup posture** | N/A — Option A by default; no stacked-base waves are planned under SINGLE topology |

---

## Verification Plan

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6370 | AC-1 | Read the posture subsection in `core/schemas/work-item-type-schema.md` §1.2.1; assert one of the three enum values is stated for each of the two surfaces, and that the thin-generic-floor line is cited by name in the reconciliation | The subsection states `PASS` at grammar-conformance (permanent) and `WARN` at content-completeness (provisional), and reconciles both against the thin-generic floor |
| #6370 | AC-2 | Read the same subsection for the boundary predicate; cross-read the pack-grammar validator for any rule that descends into a criteria block's interior | The predicate is stated verbatim and the two rule sets are disjoint. **Null expectation: 0 occurrences of the token `checks` in `core/deploy/tools/check-work-hierarchy.py`** · control: the same reader over the same file for `PACK-` rule ids → observed **20 distinct ids, 152 occurrences** |
| #6370 | AC-3 | Read the flip-decision row added to `core/standards/gate-efficacy-standard.md` § Flip-decision status | The row names its blocker (no firing population ⇒ no specificity sample), its written sink, its repo-derivable exit (≥4 kind-bearing packs), and the one-token flip form — and its leading token is a member of the closed disposition set |
| #6370 | AC-4 | Read the posture subsection for the sequencing statement | It states that archetype packs proceed **in parallel** with kit content under warn, that a finding is emitted while they do, and what the enforce counterfactual would have cost |
| #6370 | AC-5 | Read issue #6371's body for the posture verdict block | The body carries the recorded posture, the two-families finding and the sibling-check determination (a work-tracker edit, not a file — applied by the hub at the Stage-5 gate) |
| #1971 | AC-1 | Parse `core/packs/kanban/pack.toml`; assert the `checks` assignment under `[kinds.criteria.gate]` is non-empty and its entry carries `guards_transition` plus a `condition` with `kind`, `set{scope, status_filter}`, `aggregate`, `comparator`, exactly one of `{limit, limit_ref}`, and `on_unresolved` | Non-empty array; all Arm-2 required fields present; the exactly-one constraint holds |
| #1971 | AC-2 | Read the set body for `kind_filter`; scan every pack manifest for a `class-of-service` label row | `kind_filter` present in the set body. **Null expectation: 0 `class-of-service:*` label rows added to any pack** · control: the same scan for the label rows that DO exist in the corpus → observed non-zero |
| #1971 | AC-3 | Read the `[[controls]]` entry; assert `value_domain.type = "integer"` and that `applies_to` carries both `levels[]` and `kinds[]` | The control is well-formed and its value domain is the one a `limit_ref` target must declare |
| #1971 | AC-4 | Read the schema's adjacent-scope-boundary paragraph and any decision record this release adds | The `source`-on-`[[controls]]` determination is written down where the schema assigns it — either the key is extended, or the reasoned decision not to extend it is recorded |
| #1971 | AC-5 | Read the binding for `scope` and `scope_ref` | `scope` resolves from the item's own context (`parent` or `project`), or `scope_ref` is absent. **Null expectation: no instance-local value is hardcoded** · control: the same read against a `scope: board` form, which would require a `scope_ref` → the reader distinguishes the two |
| #6371 | AC-1 | Run the lint against a fixture whose kind declares a surface with an **absent** array; run it against one whose array is present-and-empty **with** a block `source` | ≥1 finding on the first (`PACKC-C01`); **zero** on the second — a reasoned empty set is complete content |
| #6371 | AC-2 | Run the lint against fixtures missing an entry `source`, a FieldDecl `source`, a block `source` on a present-and-empty table, and a `[[controls]]` `source` | One finding per altitude (`PACKC-P01`/`P02`/`P03`/`P04`); an **absent** array yields none |
| #6371 | AC-3 | Run the lint against fixtures with an incomplete entry tuple, an out-of-domain `level`, and a missing or non-semver `criteria_version` | One finding per family-S rule (`PACKC-S01`/`S02`/`S03`). **Null expectation: 0 new findings on the shipped corpus** · control: the same three mutations on a scratch copy of a shipped manifest → observed non-zero |
| #6371 | AC-4 | Run `./deploy.sh --check` and observe the new check in the run; run `python3 core/deploy/tools/check-work-hierarchy.py --validate-pack-content --pack-root core/packs` and `--self-test` standalone | The check is registered and runs in the standard path; the primitive runs standalone and its self-test passes |
| #6371 | AC-5 | Read the check's `resolve_check_mode` registration and the warn-log rows it emits | Resolves to `warn`; findings route through the shared emitter and land in the shared sink discriminated by the check id |
| #6371 | AC-6 | Read the check body; assert the control arm runs before the live-corpus arm and that the fixtures it uses are its **own**, not the grammar check's | Own fixture pair; control arm first, in the shape the pack-grammar check uses |
| #6371 | AC-7 | Run the lint against `core/packs/` at the release tip, against the pre-gate-bind form of the Kanban manifest, and against a `source`-stripped copy of the merged one | **Null expectation: zero findings on the first two** · control (mandatory sensitivity arm): the `source`-stripped copy → observed ≥1 finding. Zero on all three arms is a broken lint, not a clean pack |
| #6371 | AC-8 | Re-run the pack-grammar check's two discrimination arms and its live-corpus arm | Byte-unchanged behaviour: its 20 rule ids, its exit codes, its fixtures and its control-arm equality assertion are untouched, and both arms return the same verdicts as at the release base |
| #6371 | AC-9 | Read both named-gap rows in `core/standards/gate-efficacy-standard.md`; run the register's runner-resolution check | Both rows carry a `runner-def:` pointer, both resolve, and each row's stated predicate matches what the runner actually carries |

**AC baseline** — per-issue criterion counts as read at plan time, and the commit read against.

`ac_baseline: { #6370: 5, #6371: 9, #1971: 5, read_at: a30838589583bcddf5f88183cfff1a8ea2475300 }`

> **The lint card's count moved between Stage 4 and Commit 0, and the movement is recorded rather than smoothed.** Its body carried six criteria when the Stage-4 plan read it; the Stage-5 wave-1 gate replaced the list with eight, and the Collective Review added a ninth family-S criterion and widened the provenance one. The baseline above is the count at Commit 0, which is the read the Verification Plan's ordinals are bound to.

### Release-Level Verification

- [ ] File Integrity — every declared unconditional `add` lands; every declared `edit` shows a diff
- [ ] Content Correctness — the schema section is internally consistent after all three edits
- [ ] Cross-Reference Validity — the release-corpus link checker and the plan-depth lint both pass on the plan file
- [ ] Skill Invocation — N/A, enumerated over the deployed skill set: no skill file is in the write set
- [ ] Output Contract Compliance — the new check's findings conform to the shared emitter's row shape

---

## Cross-Issue Acceptance Criteria

Three release-scoped cohesion constraints. Each spans ≥2 issues and is graded on the merged PR at Stage 9. **CIAC-2 and CIAC-3 carry their CORRECTED forms** — the Collective Review superseded both the Stage-4 originals and an earlier same-day amendment, and § Deviation Log records each delta with its authority.

- [ ] **CIAC-1 (#6370 × #6371 on `core/deploy/deploy.sh` → the check registration):** the mode the content-completeness lint runs in, as shipped, is **the same value** the posture record names — and the warn→enforce graduation mechanism is the one the posture's flip criterion specifies, not a second parallel mechanism. *Issues spanned:* #6370, #6371. *Shared surface:* the check's `resolve_check_mode` registration ∩ the posture record and its flip-decision row. *Method:* read the flip-decision row's stated mode and flip form; read the check's `resolve_check_mode "pack-content-completeness"` registration and its committed default; assert equality of the mode value and that the flip form names a committed default rather than a runtime mode file. A lint shipping `enforce` under a `warn` posture, or shipping a bespoke mode flag, is a FAIL. **A second `resolve_check_mode` id is not a bespoke flag** — per-check mode decoupling is the platform's own mechanism, live at three existing checks. *Graded at Stage 9 on the merged PR.*

- [ ] **CIAC-2 (#6371 × #1971 on `core/packs/kanban/pack.toml`):** running the content-completeness lint against the Kanban manifest **as the gate-bind card leaves it** produces **zero** findings; the same file with its **`[kinds.fields]`** block-level `source` removed produces **at least one** (`PACKC-P03`); the pre-gate-bind `checks = []` form produces **zero** as well — the posture working correctly, not a miss. *Issues spanned:* #6371, #1971. *Shared surface:* `core/packs/kanban/pack.toml` ∩ the lint. *Method:* those three runs, **the middle one being the mandatory sensitivity arm**. *Graded at Stage 9 on the merged PR.*

  > **The middle arm names `[kinds.fields]` and not the gate table, and the reason is mechanical.** The gate-bind card's own criteria remove the block-level `source` under `[kinds.criteria.gate]` — that table's array stops being empty. After that card merges, stripping a `source` there is **a mutation that does not apply**: the file is unchanged, the lint correctly returns 0, and a criterion reading that 0 as a FAIL would fail on correct behaviour. The manifest carries exactly two block-level `source` sites; `[kinds.fields]` is the one that survives the merge, and stripping it yields exactly the rule this criterion predicts. An equally valid middle arm strips the gate **entry's** `source`, yielding `PACKC-P01`; `[kinds.fields]` is preferred because it preserves the predicted rule id and exercises the block altitude the reasoned-empty-set posture rests on.

- [ ] **CIAC-3 (#6370 × #1971 × #6371 on `core/schemas/work-item-type-schema.md`):** after all three cards merge, the schema contains **no** surviving claim that contradicts the shipped state — **anywhere in the file**, not only in §1.2.1. *Issues spanned:* #6370, #6371, #1971. *Shared surface:* the whole of `core/schemas/work-item-type-schema.md` ∩ `core/standards/gate-efficacy-standard.md`. *Method:* grep the **whole file** for **four** literals — `Runner: NONE`, `no shipped pack declares a control today`, `deliberate stub`, and `must not be **array-scoped**` — and reconcile each surviving occurrence against what the release actually shipped; then cross-read **both** named-gap rows in the standard and assert each one's runner field names the primitive the schema does. **Control arm, same instrument, same targets:** `entry-scoped` returns **2** occurrences in the schema and **5** in the standard at the release base, so the reader is live and a zero on a graded literal is a measurement rather than an unresolvable-pattern artifact. **PRESERVE-with-reason, and a reviewer must not read these as misses:** the two frozen decision-record occurrences and the section-6.2d occurrence are decision-time records, not live claims, and are never rewritten. *Graded at Stage 9 on the merged PR.*

  > **This criterion grades four literals because a three-literal form missed one, twice in one day.** The original graded two, scoped to one section; a stale claim one section over survived it. The widened form graded three whole-file; the array-scoped clause — which this release falsifies on both limbs — carries none of the three. Recorded here rather than silently fixed, so a later reader sees the pattern: a literal-list criterion grades what it was told to look for, and the claims a release falsifies are found by *reading*, not by grep.

---

## Quota Budget

**Verdict:** **PASS** (per Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **3** · Stage 7: **3** · Stage 8: **3**
**Per-spoke cost estimate:** size-bucket ordinal band — 2 × `size:L` (moderate–high), 1 × `size:S` (lowest). Source: heuristic; no telemetry medians available and the cutover predicate is unmet for every bucket.
**Assumed/stated remaining usage-window envelope:** **UNSTATED** — no operator quota state was captured at hub start; the conservative default applies.
**Estimated cumulative draw % (worst parallel batch):** worst batch is **3 concurrent spokes**. Two moderate–high plus one lowest, against the conservative envelope, sits below the 50 % boundary.
**Routing:** **PASS** → proceed; no warning carried in the plan.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota pools, read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time. Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

**Caveat on the posture interaction.** The parallel-eligible count of 3 is realizable only under a non-serial concurrency posture. Under **P0 fully-serial**, in force here, the Engineering batch width is 1 and the budget question does not arise at that stage at all — the PASS above describes the *worst* case, which the posture does not select for Stage 6.

---

## Release Class declaration

**Class: `novel`** — rendered by the operator at the Stage-4 gate as **D2**, a re-classification from the milestone's declared `routine`.

| Class | Trigger | Fires? | Evidence |
|---|---|---|---|
| `routine` | (a) all issues P3/P4 **and** size:S/M | **NO** | two members are `size:L` after the two re-sizes |
| `routine` | (b) all change-spec files have ≥3 prior release touches | partial | true for the schema and the standard; **false** for the new fixtures and the decision record |
| `routine` | (c) zero new files added | **NO** | the matrix adds three files unconditionally and one conditionally |
| `routine` | (d) zero new D-class decisions in the release plan | **NO** | at minimum: the posture itself, the sibling-versus-extend siting, controls-or-not, the `scope` selection, and the unresolved-disposition value |
| `novel` | (a) ≥1 issue introduces a new reference doc, schema, or skill | **YES** | the posture record and the lint's fixtures are new artifacts |
| `novel` | (b) **≥1 D-class decision in the release plan** | **YES** | the five above — the dominant trigger |
| `novel` | (c) ≥1 Stage-5 architecture decision per the decision discipline | **YES** | the reversibility-band crossing on the control-field layer is decision-class by construction |
| `cross-cutting` | (a) ≥3 pipeline stage files declared as changes | no | zero |
| `cross-cutting` | (b) ≥3 of the 6 rule-defining governance surfaces | no | zero |
| `cross-cutting` | (c) ≥3 in-bundle compositional edges | no | **1** |

**Multi-trigger resolution** (`cross-cutting` > `novel` > `routine`): **`novel`**, dominant trigger **(b)**. The `routine` rationale rested on two premises the Stage-4 premise re-review falsified — the parity precedent it cited is *shipped state* rather than this release's work, and the "established grammar" framing does not cover the gate-bind card, which extends the corpus's use of the grammar into a facet no shipped pack has ever used and crosses a recorded reversibility band. The re-classification is **cheaper-to-stricter**, the safe direction: it adds ceremony, invalidates no downstream artifact, and can revert at the next gate. Reversibility **CHEAP** / confidence **HIGH**.

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #6370 | `git revert <commit>` — the record reverts as a document | Low |
| #1971 | `git revert <commit>` — the manifest reverts to `checks = []` with its stub comment intact; a reverted `[[controls]]` declaration leaves no consumer stranded, because no consumer reads it | **Low for the commit, MODERATE for the surface** — see the caveat below |
| #6371 | `git revert <commit>` — purely additive (a new mode in an existing validator, a new check, new fixtures); revert restores the prior rule set | Low |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated card failure | Revert that card's commits; no card leaves the corpus in a half-state when reverted independently |
| **Full Restore** | Systemic failure | `git revert -m 1` of the merge commit |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch |

**The one caveat, and it is why R2 is an operator decision rather than a spoke decision.** The *reversibility class* of the pack-gate surface does not revert with the commit. Once a control has been declared in a shipped pack, the control-field layer's MODERATE band applies to that surface thereafter, even if the specific declaration is withdrawn. Every other rollback in this release is byte-for-byte.

---

## Operational Deployment Manifest

N/A — enumerated over the propagation classes the deploy carrier handles (skill packages, the deployed rules mirror, harness artifacts, operator-instance seed files): **none** is in this release's write set. The changed surfaces are a schema, a standard, a decision record, deploy tooling, test fixtures and one pack manifest, all of which are read in place from the repository. `./deploy.sh --deploy` is still run at Stage 12 as the standard post-merge step, and `./deploy.sh --check` is the verification surface for the new check.

### Schema Migrations

N/A — enumerated over the migration classes (frontmatter field additions requiring a corpus backfill, identifier renames requiring a cascade, storage-layout moves): none applies. The meta-schema gains a subsection and a runner; no existing key changes meaning, no field is renamed, and no shipped pack is obliged to change by any edit in this release.

---

## Deviation Log

| # | Deviation from the Stage-4 transcription source | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **CIAC-2's sensitivity arm names `[kinds.fields]`, not `[kinds.criteria.gate]`.** The Stage-4 original asserted the lint produces ≥1 finding against the pre-gate-bind `checks = []` form; an earlier same-day amendment corrected that to a `[kinds.criteria.gate]` block-`source` strip. Both are wrong: the pre-gate-bind form is a *reasoned empty set* and is correctly green, and the gate table's block `source` is **removed by the gate-bind card's own criteria**, so stripping one there is a mutation that does not apply and returns a false FAIL. | Collective Review CIAC correction on the Stage-4 sub-task, hub-verified against the live manifest | **RATIFIED. The corrected form is what this plan carries and what Stage 9 grades.** |
| **DEV-2** | **CIAC-3 grades four literals, not two and not three.** The Stage-4 original greped one section for two literals; the same-day amendment widened it to the whole file for three. A fourth stale claim — the clause stating the runner *must not be array-scoped* — carries none of the three and is falsified by this release on both limbs. | Collective Review CIAC correction; hub-verified at **4** occurrence sites across the two files | **RATIFIED.** Independently re-measured at Commit 0: `array-scoped` occurs on **2** lines in the schema and **2** in the standard, total **4**, matching the correction exactly. An initial Commit-0 probe using the narrower literal `must not be array-scoped` found only **2** — the probe was too narrow, not the correction wrong, and the wider probe is the one this plan records. |
| **DEV-3** | **The stale corpus count is `45 of 57` → `51 of 63`, at three live sites, and the frozen decision-record observation is PRESERVED.** | Stage-5 cascade sweep; **re-measured at Commit 0** rather than transcribed | **RATIFIED and re-measured.** A census over all 17 tracked pack manifests reports **21 kinds · 63 criteria tables · 21 fields tables · 84 declaration sites**, of which **51 of 63** criteria tables omit `checks` entirely (control arm: **12** tables carry the key — 8 non-empty, 4 present-and-empty — so the reader finds it where it is; specificity arm: a fabricated key returns 0 over the same 17 files). The figure is re-derived at commit time by design, because the corpus can grow between design and build and that is exactly how the current figure went stale. |
| **DEV-4** | **The sibling check is registered as `deploy.sh` Check 80, not Check 76.** The Stage-5 design illustrated the flip mechanism with a `c76_` variable prefix. | Hub correction, independently re-verified at Commit 0 | **RATIFIED.** Direct read of `core/deploy/deploy.sh` at the release base: check tokens run contiguously **1..79**, `Check 76` is live and occupied (automation-registry admission), and `Check 80` occurs **0** times. Any prefix the lint card carries is `c80_`. **The durable identifier is the check *id*, not the number** — the register's own row-form contract keys resolution on the backticked id in column 1, so the number is decoration for the grader and the id is the join key. |
| **DEV-5** | **The lint card's rule set is three families, not one.** Stage 4 planned a single entry-scoped provenance rule. Stage 5 measured that the mandated entry-scoped shape returns **0 findings on a perfectly hollow pack** — an entry-scoped rule ranges over declarations that exist and a hollow kind has none — so the card's first criterion is not deliverable by it. The Collective Review then added a third, entry-shape family so the check-shape register row's runner pointer can be honest. | Stage-5 design on the posture sub-task (D3/R2); Collective Review | **RATIFIED.** The card was re-sized `M → L` and its criteria replaced; the bundle moved to 18 raw / 21 effective. Carried into § Implementation Sequence and § Verification Plan. |
| **DEV-6** | **The gate-bind card absorbs the corpus's first `[[controls]]` declaration and the provenance decision that rides on it.** The Stage-4 plan surfaced this as undeclared scope on a 4-point card. | **D3** at the Stage-4 gate | **OPERATOR DECISION — absorbed, not split.** The card body was amended to name both as in-scope, three criteria were added, and the size moved `M → L`. The reversibility-band crossing stays an explicit operator decision. |
| **DEV-7** | **The engineering order is `{#6370, #1971}` → `{#6371}`**, not the milestone's declared strictly-serial posture → lint → bind. | **D4** at the Stage-4 gate | **RATIFIED.** Ordering, not concurrency — Stage 6 stays one chip at a time under P0. The *merge* order is separately mandatory and is `#6370 → #1971 → #6371`. |
| **DEV-8** | **The pack-grammar check carries 20 rule ids, not 19.** The hub's Stage-4 brief said 19; its own enumeration summed to 20. | Stage-5 measurement, hub-accepted | **RATIFIED at Stage 5.** Carried into the lint card's byte-unchanged criterion, which now names 20. |
| **DEV-9** | **The posture card's decision-record row moves from CONDITIONAL to unconditional at Commit 0.** Stage 4 conditioned it on whether the posture warranted its own record; Stage 5 resolved the condition in favour of a *different* record — the siting determination, not the posture. | The authoring contract's fired-conditional rule: a conditional row whose condition resolves at or before Engineering Commit 0 is promoted **in that commit**, carrying its now-concrete path | **PROMOTED IN THIS COMMIT**, with the real basis recorded rather than left shielded by a predicate that never fired. |
| **DEV-10** | **The posture card's schema edit leaves `Runner:` at `NONE` and adds no runner pointer to the standard.** A reader comparing this release's *outcome* to the posture card's subject matter might expect the runner to be named here. | The register's runner-resolution contract: a named-gap row carries no runner pointer, and the register's resolution check recomputes every pointer on every run — a pointer at a runner that does not exist yet fails it | **DECLARED, not absorbed.** The posture card decides *what* the runner must be; the lint card *ships* it and flips both surfaces in the same change. Splitting them is what keeps the register honest between the two merges. |

---

## Verification Evidence

(Populated after Stage 12 execution.)

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Change Description

(Authored by the Stage 6 release-engineering spoke at PR-creation time per [`RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Change Description Protocol, once the last card lands. Operator-facing, pre-merge, ~60 lines. Distinct from the user-facing release note authored at Stage 13 Close per [`release-notes-standard.md`](/release/references/standards/release-notes-standard.md).)

---

## Baseline pin

`origin/main` @ **`a3083858`** (`a30838589583bcddf5f88183cfff1a8ea2475300`), measured 2026-09-10. Read by the Stage-9 mid-pipeline divergence re-check. Confirmed unmoved at Engineering Commit 0 — the Stage-4 pin and the Commit-0 base are the same commit.

## Issue References

<!-- repo-integrity: allow-issue-ref — limb 1: a release plan's member enumeration IS its subject matter; the numbers are the release's own scope, not prose citations, and relocating them would delete the plan's scope statement -->

Every member of this milestone is transitioned to closed at Stage 13, by the Stage-13 close-out on the merged PR rather than by an auto-close keyword in the PR body. The members are #6370, #1971 and #6371.

- **#6370** — a declared kind carrying no fields and no criteria has no recorded conformance posture, so a completeness lint has nothing to build against and the archetype-breadth epic cannot know whether its packs may proceed in parallel with kit content.
- **#1971** — the Kanban pack's set-aggregate WIP gate ships with an unfilled `checks` assignment, so the corpus declares a gate the grammar supports and no pack has ever used.
- **#6371** — no content-completeness lint exists anywhere in the deploy tree; the pack-grammar check validates structure only and never descends into a criteria block's interior.

Related, and deliberately **not** referenced with any close-family verb: #5827 remains open as a coordination edge and is not this release's scope; #3607 and #3608 are downstream consumers that accept against the lint this release ships.
