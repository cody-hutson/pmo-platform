---
title: Release Plan — adr-corpus-conformance (reconcile the ADR standard, bring the corpus to it, and make concurrent ADR authoring collision-safe)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: adr-corpus-conformance
release_class: cross-cutting
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `adr-corpus-conformance`

**Milestone:** `adr-corpus-conformance` (milestone 286) · hub sub-task #4576 = Stage 4 plan source · #4666 / #4670 / #4674 / #4678 / #4682 / #4686 = Wave-1 Stage 5 Solutioning sources, #4690 = the Wave-2 source · #4667 = Stage 6 Engineering sub-task for the first member (#3914), which lands this plan as Commit 0.
**Version identity:** **slug-only** per **ADR-092**. The plan file is `adr-corpus-conformance_RELEASE_PLAN.md` and the branch is `release/adr-corpus-conformance`; no `vX.Y` stem appears in the plan filename, the branch name, or this plan's own identity prose. Bump class is `minor` (recorded determination, not a gate). The concrete number binds at the **Stage-12 atomic claim** (`git mv` to `plans/v<MAJOR>/{{RELEASE_VERSION}}_RELEASE_PLAN.md`).
**Topology:** D-C **SINGLE** — one release branch, one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial.** Stage-6 chips route one at a time in the approved sequence on the single branch; force-push (including `--force-with-lease`) is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`cross-cutting`** (operator verdict, Stage-4 gate). Posture: engagement density **Tight** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #4576, reconciled to the **Stage-4 gate** verdicts (2026-08-03), the **consolidated Wave-1 gate** verdicts (2026-08-03), and the approved Stage-5 Solutioning designs. Where a later disposition superseded a Stage-4 assumption, the transcribed section carries the **decided** state and the **§ Deviation Log** records the delta against the Stage-4 plan of record. Authored at Engineering Commit 0 by the Stage-6 Engineering spoke for #3914 (#4667).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` — slug-only pre-claim (ADR-092); bump class `minor` |
| **Date Created** | 2026-08-03 (Monday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/adr-corpus-conformance` |
| **PR** | (populated at PR creation — hub-owned, after the final slice) |
| **Milestone** | `adr-corpus-conformance` (286) |
| **Baseline** | `origin/main` @ `41d12ed8` (Commit-0 re-pin **confirms** the Stage-4 pin — zero commits of drift) |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing. **Refreshed by the final Engineering slice** if later slices change which issues land or which decisions stand.*

**Outcome.** The platform's own architecture-decision records stop contradicting the standard that governs them. Seven cards in three movements: **the standard is made self-consistent** (one requirement level for the alternatives section, stated once and cited everywhere; an immutability rule that distinguishes recording a fact from revising a decision), **the corpus is brought to it** (heading normalization, missing-section backfill, durability-anchor hygiene), and **concurrent authoring is made collision-safe** (a tooled merge-time renumber, so two releases can author an ADR at the same time without one of them stalling). After this release, "author to the ADR standard" and "bring the corpus into conformance" name the same target instead of three conflicting ones.

**The through-line.** Every card is an instance or a prevention of the same failure: *a rule stated in more than one place, where the copies have drifted apart and nothing reconciles them.* The requirement level was stated on five surfaces at four different levels. The immutability rule said one thing and the shipped lint assumed another. The release ADR index and the ADR file set disagreed. The fix in each case is the same shape — one authority, everything else cites it — and the release ships the checks that keep it that way.

**Key decisions.** Release class held at **`cross-cutting`**. Entry disposition **two-wave** (Wave 1 now; Wave 2 merge-order-gated on the sibling release PR #4568). `## Alternatives rejected` **satisfies** the alternatives requirement — the contract is decision-recall content, not the heading string — and applying that principle consistently re-sizes the authoring set. `core/ADRs/README.md` is declared a **curated thematic doc, not an index**, so index-completeness scopes to the release index only. ADR-number collision resolves by **tooled merge-time renumber**, not pre-allocation. The ADR `deciders:` carve-out is ratified **name-only** — never the GitHub handle. All four Stage-5 scope changes accepted.

**Reversibility.** **CHEAP** for the standard-reconciliation half (prose and one additive self-test case; no rule behavior changes and no new findings over the corpus) and **MODERATE** for the corpus half (a wide body-edit sweep whose revert restores a non-conformant corpus) and for the numbering mechanism (later releases may adopt the tooled path). Whole-release rollback is `git revert` of the merge commit. **The durability lint's `WARN_MODE` is deliberately NOT flipped in this release** — see § Rollback.

**Downstream impact.** No runtime behavior changes for end users. One ADR-authoring skill package is rebuilt once, at release-cut. The ADR durability lint gains one self-test case and a scope declaration; its corpus verdict is unchanged.

**Cross-references.** Stage-4 plan #4576 · Stage-5 designs #4666 / #4670 / #4674 / #4678 / #4682 / #4686 (Wave 1) and #4690 (Wave 2) · milestone 286. Version identity per **ADR-092**; overlap classes per **ADR-005**; canonical-spec-edit-wins per **ADR-062**.

---

## Scope

### Summary

Seven members (one folded), **43 raw pts** at the Stage-4 pin, one branch, one PR. **Three verified HARD dependency edges**, all running out of #3914. Build posture: **SINGLE branch, P0 fully-serial**, two waves.

Capability outcome: **an ADR author has one unambiguous standard, the corpus conforms to it, and two releases can author into the sequence concurrently.**

**Bundle sizing.** Raw sum = 43 pts; `class_weight`(cross-cutting) → `effective_pts` = 56 against a 15–25 band. The override is operator-accepted on the coherence argument recorded in § Bundle-Coherence Read — two of the three capabilities are gates on each other's *correctness*, not merely adjacent. **#3713 is the recorded clean cleave point** if a split is ever forced.

### Members

| # | Issue | Type | Size | Wave | Surface |
|---|-------|------|------|------|---------|
| 1 | **#3914** reconcile the ADR standard's internal contradictions | story | M | 1 | `adr-schema.md`, `adr-authoring-guide.md`, `adr-template.md`, `check-adr-durability.py`, `.github/ISSUE_TEMPLATE/adr.yml`, +1 new ADR |
| 2 | **#3915** ADR issue-reference rule + reference block | story | M | 1 | `adr-authoring-guide.md`, `.github/workflows/repo-integrity.yml` |
| 3 | **#3708** R2-COUNT recall bound (measured pre-sweep) | story | M | 1 | `check-adr-durability.py`, `adr-authoring-guide.md` |
| 4 | **#3707** ADR `deciders:` name-vs-handle gate reconcile | story | **M** | 1 | `adr-authoring-guide.md`, `core/rules/git-workflow.md` |
| 5 | **#3916** adr-helper scaffold conforms to the reconciled standard | story | M | 1 | `core/skills/adr-helper/**`, `operations/templates/adr-template.md`, `packages/adr-helper.skill` |
| 6 | **#3713** concurrent ADR-number collision resolution | story | L | 1 | `check-adr-numbers.py`, `adr-helper`, index sites, `stage-12-execute.md`, +1 new ADR |
| 7 | **#1488** ADR corpus structural-conformance sweep (**#3383 folded in**) | story | XL | **2** | `core/ADRs/**`, `release/ADRs/**`, both ADR READMEs |

**#3383 is folded into #1488** as a named sub-deliverable of its index-lockstep criterion — it is not a parallel write. It is **marked as closed at Stage 13** with its criteria satisfied by #1488's README pass.

### Wave Structure (Stage 6 Engineering)

Single branch, serial commit order. The hub surfaces one Stage-6 chip at a time.

| Order | Member | Rationale |
|-------|--------|-----------|
| 0 | *(this plan)* | **Commit 0** — plan file lands before any member edit. Carries the version re-verify and both ADR-number derivations. |
| 1 | **#3914** | Foundation. Blocks two cards, and its immutability carve-out is what makes Wave 2's edits *legal*. Writes the § ADR template prose in the hottest file in the release while the branch is clean. |
| 2 | **#3915** | Foundation. Shares `adr-authoring-guide.md` with #3914 → serialized immediately after it, in its own reserved subsection. |
| 3 | **#3708** | **Moved forward from the Stage-4 milestone's "eval last" framing.** Its measurement must be taken against a **pre-sweep** corpus — running it after #1488 would measure a drained population and yield a vacuously clean recall bound. |
| 4 | **#3707** | Placed here so all `check-adr-durability.py` writes land contiguously under one serialization window. |
| 5 | **#3916** | Consumes #3914 + #3915. Skill + template + one package rebuild. |
| 6 | **#3713** | Independent of all six at design; serialized at engineering on the shared skill and index sites. Authors the release's second ADR. |
| — | **GATE** | **Merge-order constraint, not a stop.** Wave 2 may *build* at any time; it must not *merge* before sibling PR #4568 unless the operator accepts the residual. |
| 7 | **#1488** (+#3383) | The corpus wave. Denominator re-derived at execution; criteria expressed as glob predicates. |

Each issue is **marked as closed at Stage 13** on this plan's schedule; no issue closes at merge.

---

## Dependency Graph

Edge legend: **HARD** = downstream cannot correctly start until upstream lands · **SOFT** = ordering preference with a named cost · **CONTENTION** = no dependency; same-file write collision (drives commit order, not dependency).

```
  WAVE 1 (no corpus coupling, no sibling-PR coupling)

   #3914 ─────HARD───────────────────────────────────► #1488   (WAVE 2)
  (standard reconcile)  └──HARD──► #3916                 ▲
                                     ▲                   │
   #3915 ──────HARD───────────────────┘            FOLD-IN│
  (issue-ref rule)                                  #3383 ┘

   #3707  (gate reconcile — INDEPENDENT)
   #3708  (recall bound — MEASURE PRE-SWEEP) ──SOFT──────┘
   #3713  (numbering — INDEPENDENT of all six)
```

**Verified edges (3 HARD):**

| Edge | Evidence |
|---|---|
| `#3914 → #1488` | The conformance sweep cannot author to a self-contradictory standard; and without #3914's immutability carve-out, editing an Accepted ADR body **is a policy violation**, so the sweep is not merely mis-targeted, it is unauthorized. |
| `#3914 → #3916` | #3916's first criterion scaffolds the full required-section set *as defined by the reconciled standard*. |
| `#3915 → #3916` | #3916 requires the scaffold to model the reference block whose form #3915 defines. |

**Edges asserted by the milestone that do NOT exist:** `#1488 → #3707` (its own dependency note states either order is fine, and the population it would collide over is empty) and `#1488 → #3708` (the real edge is **inverted** — see § Implementation Sequence Finding S1).

---

## Implementation Sequence

**Entry disposition: two-wave** (operator verdict, Stage-4 gate D-A). Waves are branch-internal commit ranges on **one release branch, one PR, one merge**; "wave" is a sequencing unit, not a separate PR.

**Finding S1 — the milestone's internal sequence inverts #3708.** The milestone sequenced #3708 as "eval / verification — gated on the conformance pass." That is backwards: #3708's first criterion runs the shipped checker over the corpus with its vocabulary constraint lifted and subtracts the shipped result. #1488's sweep exists to **drain live population counts from durable ADR prose**. Running #3708 after #1488 measures a drained corpus and yields a **vacuously clean recall bound** — precisely the false-coverage reading #3708 was filed to prevent. **Resolution: #3708 sequenced into Wave 1**, measuring live pre-sweep state, with no baseline pinning required. This deviates from the `bundle-composition-doctrine.md` § 9 "eval last" layer rule; the deviation is deliberate — that rule assumes eval *observes* the shipped work, whereas here eval measures a population the shipped work destroys. **Layer-order yields to measurement validity.**

**Second-order sequencing note.** If #3708 must ever run late, its measurement is taken against the release-branch base SHA via `git show ${base}:<path>` — note the shell hazard: brace the ref as `${rev}:path`, never `"$rev:path"`, which mangles silently under zsh and produces a false MISSING.

---

## Stage Applicability Matrix

Default all of Stages 5–13. **Zero skips** — every card carries either a decision gate or a functional gate change; none is trivial. This is consistent with the `cross-cutting` Stage-5 activation bias (ALL) but is not *caused* by it; each activation is independently justified.

| Issue | S5 | S6 | S7 | S8 | S9–S13 | Rationale for S5 activation |
|---|---|---|---|---|---|---|
| **#3914** | YES | YES | YES | YES | YES | Renders the requirement-level decision **and** the heading-equivalence call that sizes the sweep. Functional: binds the durability lint's cited section set. |
| **#3915** | YES | YES | YES | YES | YES | The narrow-marker criterion is a judgment call; the identity-field lint is a functional deliverable. |
| **#3708** | YES | YES | YES | YES | YES | Widen-vocabulary vs. document-the-bound is a genuine design fork with a measured precision cost. S7/S8: self-test cases with mutation-kill controls are the deliverable. |
| **#3707** | YES | YES | YES | YES | YES | Public-surface policy call (name-only vs. name+handle) — operator-class. S7: the fixture pair (handle fires / name passes on both gates) is the test. |
| **#3916** | YES | YES | YES | YES | YES | Scaffold shape consumes two upstream reconciliations. S7: a scaffolded ADR must pass the durability lint with zero findings and without a marker. |
| **#3713** | YES | YES | YES | YES | YES | Three-way direction choice + an ADR is required. S7/S8: "two branches author concurrently and both merge" is behavioral and needs a real two-branch fixture. |
| **#1488** | YES | YES | YES | YES | YES | Per-module wave decomposition over the whole corpus + the index-generation design. S7: all required CI gates pass. |

---

## Contention Map

### Within-release

| ID | File | Written by | Severity | Resolution |
|---|---|---|---|---|
| **C1** | `core/standards/adr-authoring-guide.md` | #3914, #3915, #3708, #3707 | **HIGH** — the hottest file in the release | **Serialize in the Wave-1 order, on the binding disjoint partition below.** Four sequential writers on one file with no coordination is how a reconciliation release ships a self-contradictory guide. **CIAC-1 grades the outcome.** |
| **C2** | `release/tools/check-adr-durability.py` | #3914 (scope + section-set citation), #3708 (R2-COUNT vocabulary + self-test), #3707 (R3) | MEDIUM | Serialize; contiguous in Wave 1 by design. **Three disjoint docstring blocks** — one per writer. One `--self-test` run must pass after all three (**CIAC-3**). |
| **C3** | `core/skills/adr-helper/**` | #3916, #3713 | MEDIUM | Serialize #3916 → #3713. Skill-edit discipline runs before push; the package rebuilds **once** at release-cut, not per-card. |
| **C4** | `release/ADRs/README.md` | #1488 (+#3383 folded), #3713 | **HIGH** | The fold converts a 3-way write into 2-way. #3713's index touch is *mechanism* (the renumber tool updates indices), not content. |
| **C5** | `core/ADRs/README.md` | #1488, #3713 | MEDIUM | Same resolution as C4. Per the ratified scope call, this file is a **curated thematic doc, not an index** — completeness criteria do not target it. |
| **C6** | `operations/templates/adr-template.md` | #3914, #3916 | LOW | Serialize. #3914 sets the requirement level; #3916 realizes it in the scaffold. |
| **C7** | `packages/adr-helper.skill` + `.sha256` | #3916, #3713 | LOW (build artifact) | Rebuild **once** at release-cut. Per-card rebuilds are the known package-drift cluster. |
| **C8** | The ADR corpus files | #1488 only | — | Not contention. Recorded to make the negative explicit: no other card edits ADR bodies. |

**C1 — the binding disjoint partition.** Four Stage-5 spokes independently converged on this partition with zero coordination; it is now binding for Engineering.

| Writer | Exclusive write scope in `adr-authoring-guide.md` | MUST NOT touch |
|---|---|---|
| **#3914** | § ADR template **prose** (the body-section-set sentence) + the fenced template's alternatives **guidance comment** + a **new H3** carve-out appended inside § Supersession + immutability | the `### Durability rules` table rows; the H3 slot reserved for #3915 |
| **#3915** | a **new H3** for the issue-reference rule, placed **after** `### Durability rules` and **before** `## Worked example` — **plus** the reference-block statement | § ADR template prose; the § Supersession carve-out H3; the durability-rules table rows |
| **#3708** | the `### Durability rules` table's **"No stale anchors"** row **only**, plus the exemption paragraph immediately following the table | the other two rows; § Supersession; § ADR template |
| **#3707** | the `### Durability rules` table's **"No operator handle"** row **only** | the other two rows; § Supersession; § ADR template |

**Shared invariant binding all four writers (this is what CIAC-1 grades):** the guide's stated **required-section set appears exactly once**, in § ADR template, and every other surface *cites* it. No writer may introduce a second statement of the set or a second requirement-level claim. A guide that states the level twice is self-contradictory by construction even when both statements happen to agree on the day they are written.

**C2 — the docstring partition.** `SCOPE — WHAT THIS LINT DOES NOT CHECK` is #3914's block; `R2 EXEMPTIONS` is #3708's; `NEVER HARDCODE THE HANDLE` is #3707's. Three disjoint blocks, so CIAC-3's three coexisting statements hold.

### Cross-PR — baseline-pinned

**Open-PR population at the pin: exactly 1** (sibling release PR #4568). A single-member population is fragile — **re-check before the Stage-9 GO**; one new PR silently invalidates the contention finding.

Same-path intersection is **one conditional, append-pattern file** (`core/schemas/gate-criteria-spec.md`, only if #3713's direction lands a named gate ID) — informational, not a serialization point. **The coupling that matters is not same-path.** Four derived-value couplings, none visible to a path-intersection audit:

| # | Coupling | Effect on merge |
|---|---|---|
| **X1** | **ADR namespace.** The sibling PR claims two ADR numbers that are unmerged. **Only `origin/main` binds** — an unmerged claim does not bind the sequence. | Both of this release's ADR numbers are derived at Commit 0 against `origin/main` **only** (see § ADR Number Derivation). Binding at the `main` next-free is safe under **both** merge orders. |
| **X2** | **Corpus denominator.** The corpus grows when the sibling merges. | Wave 2's completeness criteria are **glob predicates over the live corpus**, re-derived at execution — never a frozen count. |
| **X3** | **Index completeness.** The sibling adds release ADRs and no README change, re-creating the exact defect the folded card fixes. | A **generated** index makes the recurrence structurally impossible; plus a coordination request to the sibling. |
| **X4** | **Version slot.** Both releases compute the same next-free minor. | **Expected runtime behavior, not an error.** The atomic claim resolves it: first to merge takes the slot, the other re-versions. Recorded, not mitigated. |

**Not contention — process currency.** The sibling PR edits several pipeline and skill specs that this release **reads** but does not write. If it merges mid-flight, downstream spokes read updated specs — a currency consideration for the Stage-9 re-check, not an edit collision.

---

## ADR Number Derivation (Commit 0)

**The binding anchor is `origin/main` ONLY.** Scanning other branches is for *detection*, never for *binding*. `core/ADRs/README.md` § Renumber log states the reasoning verbatim: an unmerged claim does not bind the sequence, and merging into a gap would land that gap on `main`, where the contiguity gate then fails **every subsequent PR**. Pre-reserving a higher slot is no remedy, because the checker fails a gap as readily as a duplicate. The corpus already carries the precedent — a release ADR was renumbered **down** for exactly this reason.

| Consumer | Number | Home | Derivation |
|---|---|---|---|
| **#3914** (this slice) | **ADR-110** | `core/ADRs/` — cross-cutting platform decision | `anchor(origin/main)` + 1 |
| **#3713** (Wave 1, order 6) | **ADR-111** | its slice's determination | `anchor(origin/main)` + 2, sequenced after this allocation |

Derivation command: `git ls-tree -r --name-only origin/main -- core/ADRs release/ADRs | grep -oE 'ADR-[0-9]{3}' | sort -n | tail -1`, with the contiguity gate (`release/tools/check-adr-numbers.py`) confirming the sequence is gap-free at the anchor. If the sibling PR merges first, the ratified **tooled merge-time renumber** resolves the collision — that mechanism is itself a deliverable of this release, exercised by this release.

---

## Risk Register

| ID | Risk | Class | Sev | Owner-stage | Mitigation | Reversibility · Confidence |
|---|---|---|---|---|---|---|
| **R1** | Four cards write `adr-authoring-guide.md`; a *reconciliation* release ships a self-contradictory guide | Contention | **HIGH** | S6 | The binding C1 partition + the state-it-once invariant; **CIAC-1** grades guide↔scaffold agreement at S9 | CHEAP · HIGH |
| **R2** | The sibling PR merges after Wave 2 → the release ships an index and a completeness claim that are false on arrival | Dependency (cross-release) | **HIGH** | S4/S9 | Two-wave entry; generated index makes it structurally impossible; Stage-9 re-check | MODERATE · HIGH |
| **R3** | This release authors ADRs into a namespace with in-flight claims; binding into a gap fails every subsequent PR | Dependency (cross-release) | **HIGH** | S6 | **Resolved at Commit 0** — derive against `origin/main` only, never pre-allocate; see § ADR Number Derivation | CHEAP · HIGH |
| **R4** | The folded card was sized against a two-row premise and a much larger reality | Scope | **HIGH** | S4 | Re-sized and folded; the index becomes a generated projection | CHEAP · HIGH |
| **R5** | The sweep's headline omission figure is three different jobs — mechanical renames, a judgment call, and genuine decision-recall authoring on Accepted records | Scope | **HIGH** | S5 | The heading-equivalence call is ratified and the authoring set is re-sized (§ Deviation Log Δ-resize); slice the authoring third as its own wave with its own budget | MODERATE · MEDIUM |
| **R6** | The recall bound run after the sweep is **vacuous** — the exact false-coverage reading it was filed to prevent | Sequence | **HIGH** | S4 | Finding S1 — sequenced into Wave 1, measured pre-sweep | CHEAP · HIGH |
| **R7** | Both this release and the sibling compute the same next-free version slot | Contention (version slot) | MEDIUM | S12 | Expected: the atomic claim resolves it; the loser re-versions. Recorded, **not** mitigated | CHEAP · HIGH |
| **R8** | The sweep touches the whole corpus in one PR; post-merge rollback restores a non-conformant corpus | Rollback complexity | **HIGH** | S12 | **Do not flip `WARN_MODE` in this release** (see § Rollback). Wave-structured commits give pre-merge wave-granular rollback | MODERATE · HIGH |
| **R9** | Planning against the milestone's unreproducible corpus-wide citation figure over-scopes the numbering card toward an expensive direction | Scope | MEDIUM | S5 | The decision-relevant figure is **per-ADR**, not corpus-wide; a renumber always targets the newest, least-cited record | CHEAP · HIGH |
| **R10** | Theme breach: three capabilities in one bundle, operator-accepted but unresolved | Scope | MEDIUM | S5 | The two-wave structure is the mitigation; Collective Review re-surfaces it | MODERATE · MEDIUM |
| **R11** | Open-PR population is one; a single new PR silently invalidates the contention finding | Evidence | MEDIUM | S9 | Audit-baseline discipline: baseline pinned; **re-check before GO** | CHEAP · HIGH |
| **R12** | The ADR-authoring skill package rebuilt per-card instead of once at release-cut → package drift | Contention | LOW | S12 | C7: a single rebuild at release-cut | CHEAP · HIGH |

---

## Cross-Issue Acceptance Criteria

Four release-scoped cohesion constraints, graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 (#3914 × #3915 × #3916 on the authoring guide + the ADR-authoring skill):** the authoring guide states **exactly one** requirement level for the alternatives section and **exactly one** issue-reference rule, and the scaffold emits a section set **identical** to the guide's stated required set. *Method:* extract both lists; assert set **and order** equality; **control** — remove one section from the scaffold and confirm the assertion fails.
- [ ] **CIAC-2 (#3914 × #1488 × #3915 on the ADR corpus):** every corpus-scoped acceptance criterion in the merged release is expressed as a **predicate over the live ADR glob**, carrying **zero** hardcoded corpus counts. *Method:* sweep the merged plan and criterion text for three-digit numbers; each survivor must be an ADR identifier or this plan's own recorded baseline pin; **control** — the baseline-pin line MUST match, proving the probe is not returning zero for lack of input.
- [ ] **CIAC-3 (#3707 × #3708 × #3914 on the durability lint):** after all three land, a single `--self-test` run passes, **and** the module docstring states all three writers' statements — the ratified name-vs-handle reading, the R2-COUNT recall bound, and the structural-conformance scope declaration. *Method:* run `--self-test` (expect exit 0); grep the docstring for all three; **control** — mutate a predicate to a no-op and confirm the new cases fail.
- [ ] **CIAC-4 (#1488 × #3383 × #3713 on the release ADR index):** the release ADR index is a **projection** of the file set — index rows ≡ the release ADR glob, zero missing and zero orphan rows — machine-checked. *Method:* set-difference the index-row set against the file-glob set (expect empty both directions); **control** — delete one row and confirm the check fires; **and** the check's own output must state its denominator.

---

## File Change Matrix

Machine-readable — **one path per line**, for deterministic extraction by Stage 7/8/9 chip prompts. Intent in the trailing comment.

```paths
release/releases/plans/adr-corpus-conformance_RELEASE_PLAN.md   # new  — this plan, Engineering Commit 0
core/schemas/adr-schema.md                                      # edit — #3914 § 3 gains the alternatives row + the requirement-level contract (§3.1) + the authority-chain table (§3.2)
core/schemas/README.md                                          # edit — #3914 forced cardinality cascade on the schema index row (Stage-6 finding; see Deviation Log Δ-cascade)
core/standards/adr-authoring-guide.md                           # edit — #3914 § ADR template prose + template guidance comment + § Supersession carve-out H3; #3915 issue-reference H3 + reference block + the post-fence scope sentence + the durability-rules intro clause; #3708 stale-anchor row + exemption paragraph; #3707 operator-handle row
operations/templates/adr-template.md                            # edit — #3914 requirement level (project-ADR population) + body-section cardinality; #3916 scaffold realization
release/tools/check-adr-durability.py                           # edit — #3914 scope block + section-set citation + self-test drift case; #3915 R4 IDENT-REF + shared frontmatter_bounds() + R4 docstring block + 16 self-test cases; #3708 R2-COUNT vocabulary + self-test + repoint source_observation_lines() at frontmatter_bounds(); #3707 R3
.github/ISSUE_TEMPLATE/adr.yml                                  # edit — #3914 fifth requirement-level surface (accepted scope change SC-4)
.github/workflows/repo-integrity.yml                            # edit — #3915 job `issue-ref` REFBLOCK_RE + its failure-summary block (accepted scope change SC-3), and job `adr-durability` findings/fixes message for R4; #3707 job `depersonalization` (GATE 1) — DISJOINT jobs, serialization suffices
core/rules/git-workflow.md                                      # edit — #3707 self-contradiction on the ADR deciders carve-out (accepted scope change SC-2); #3915 forced cascade — the durability-job rule enumeration (see Deviation Log Delta-cascade-gw)
core/skills/adr-helper/SKILL.md                                 # edit — #3916 scaffold conformance; #3713 allocation surface
core/skills/adr-helper/references/scaffolding-procedure.md      # edit — #3916 section-set cardinality cascade (handed over from #3914) + the frozen-restatement citation; #3713 allocation
packages/adr-helper.skill                                       # edit — ONE rebuild at release-cut, after both #3916 and #3713 land
packages/adr-helper.skill.sha256                                # edit — content-baseline sidecar re-emitted by the package builder
release/tools/check-adr-numbers.py                              # edit — #3713 direction (tooled merge-time renumber)
release/references/pipeline/stage-12-execute.md                 # edit — #3713 the named merge-time renumber step
core/schemas/gate-criteria-spec.md                              # edit — #3713 CONDITIONAL: only if the direction lands a named gate ID
core/ADRs/ADR-110-adr-section-set-and-durability-hygiene-carve-out.md   # new — #3914's ADR (number derived at Commit 0 against origin/main; LANDED)
core/ADRs/ADR-111-*.md                                          # new  — #3713's ADR (number sequenced after #3914's; home + kebab are that slice's determination)
core/ADRs/ADR-*.md                                              # edit — #1488 corpus sweep (GLOB, deliberately — the corpus is the population)
release/ADRs/ADR-*.md                                           # edit — #1488 corpus sweep (GLOB)
core/ADRs/README.md                                             # edit — #3915 DEF-1 marker-suppression correction + authoring-discipline item 2 (third writer, ESC-2; region-disjoint); #1488 declare the curated-thematic-doc contract (ratified: NOT an index)
release/ADRs/README.md                                          # edit — #1488 (+#3383 folded) generated index projection
release/releases/RELEASE_LOG.md                                 # edit — Stage-13 close-out ledger row [Stage 13, not this build]
```

**Notes.** (1) The two `ADR-*.md` glob rows are **globs, deliberately** — the corpus is the population, and a hardcoded file list is the very rot class this release exists to eliminate. (2) `core/schemas/gate-criteria-spec.md` is **conditional**. (3) The two new-ADR rows carry their derived numbers per § ADR Number Derivation; if the sibling PR merges first, the ratified tooled renumber resolves the collision. (4) The canonical tool path is `release/tools/`, **not** `core/tools/` — the latter does not exist.

**Explicitly NOT edited:**
- **`core/skills/adr-helper/**` by #3914** — the cardinality cascade landing there is **handed to #3916**, which owns that surface. #3914 sets the contract; #3916 realizes it.
- **`release/releases/**` historical artifacts** (shipped plans, notes, digest, archive) — historical record, untouched by design.
- **The durability lint's `WARN_MODE`** — see § Rollback. No card in this milestone carries the flip as an acceptance criterion; this is a boundary to hold, not a scope change.

---

## Domain Practice Provenance

The File Change Matrix is entirely internal pmo-platform artifacts — governance standards, schemas, the ADR corpus, CI checkers, issue templates, and one skill. Sourcing-exempt (no external practice governs ADR section-set reconciliation for an internally-governed corpus), but the domain class is mandatory in every mode and travels unchanged into Solutioning and Engineering.

domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-03, domain: governance }

---

## Bundle-Coherence Read

The bundle carries a **real, unresolved theme breach**: the capability test is answered three times (an author has one unambiguous standard; a reader finds every ADR conformant and indexed; two concurrent releases can author without colliding). The declined split would have put all three in-band.

**Why hold it anyway.** The three capabilities are not merely adjacent — **two of the three are gates on each other's correctness.** The standard must land before the corpus can be *authored against at all*, not as a sequencing nicety but because the immutability carve-out is what makes editing an Accepted ADR **legal**. And the numbering fix is exercised *by this very release* authoring into a contended namespace. Splitting into three milestones would trade an in-bundle edge for a cross-milestone edge without reducing coupling.

**Recorded cleave point.** **#3713 is the clean cleave line** if a split is ever forced: zero dependency edges to the other six, separable capability, second-largest card. Extracting it leaves a bundle whose remaining members are genuinely one capability chain.

---

## Deviation Log

Deltas between the Stage-4 plan of record (#4576) and the ratified dispositions (Stage-4 gate, consolidated Wave-1 gate), plus Stage-6 implementation findings.

| # | Stage-4 / spec record | Ratified / implemented delta | Basis |
|---|---|---|---|
| **Δ-D-A** | Hub framed two-wave entry as "#3914, #3915 only" | **Wave 1 is six cards, not two.** #3916, #3707, #3708 and #3713 also have zero sibling-PR coupling and zero corpus-count dependency. Holding them would repeat the defer-everything error at smaller scale. The gate is a **merge-order constraint, not a wait** — Wave 2 may build at any time. | Stage-4 gate, D-A |
| **Δ-D-B1** | Card recommended "conditional-required" (presence conditional on ≥2 options) | **`## Alternatives rejected` satisfies the requirement** — the contract for the section is the *decision-recall content*, not the heading string. Normalize the heading; do not author against records whose content is already present. | Stage-4 gate, D-B1 |
| **Δ-D-B2** | Both sweep cards assumed `core/ADRs/README.md` is an index | **Declared a curated thematic doc, not an index.** It is thematic by construction; converting it to a flat index would destroy a useful curation and create a second hand-maintained duplicate of the file set. **Index-completeness criteria scope to `release/ADRs/README.md` only.** | Stage-4 gate, D-B2 |
| **Δ-D-C** | Card stated a preference for defer-to-claim (pre-allocation) | **(C) tooled merge-time renumber.** Pre-allocating from a moving population is the failure, not the specific oracle; any design-time reservation against a globally-sequenced, concurrently-claimed namespace inherits it. The observed failure was a **missing provenance note** — a tooling gap, not a design gap. The version-adapter analogy is real but asymmetric: a tag is a single ref with an atomic compare-and-swap; an ADR number is a filename plus N citations. | Stage-4 gate, D-C |
| **Δ-SC** | Stage-4 File Change Matrix covered neither the fifth requirement-level surface nor three sibling-card surfaces | **All four Stage-5 scope changes accepted.** SC-1 frontmatter-detector repair incl. its stale-anchor half (#3708) · SC-2 `core/rules/git-workflow.md` self-contradiction (#3707) · SC-3 the reference-block pattern + the repo-integrity workflow (#3915) · **SC-4 `.github/ISSUE_TEMPLATE/adr.yml` — the fifth requirement-level surface, now #3914's** (a ~2-line consistency edit under the ratified level). Reconciling 3 of 5 surfaces would have left the contradiction live. | Wave-1 gate |
| **Δ-blocker** | #3916 required a reference-block form that no card owned | **#3915 owns stating the reference block**, landing inside its already-reserved H3, so the four-way C1 partition survives intact. #3916 binds to the outcome via a set-equality criterion. | Wave-1 gate |
| **Δ-resize** | Stage-4 sized the sweep's authoring set at **32** under the ratified heading-equivalence call | **Re-sized to 21.** Applying the ratified content-over-heading principle *consistently* moves 11 files out of the authoring set: **10** record their options under an `Options considered` / `Options Considered` / `Decision Drivers` H2, and **1** records them at H3. The decisive witness: the authoring guide's **own named exemplar for "rejected alternatives recorded"** is scored an omission by a heading-string test — the standard's own exemplar failing the standard's own test is a demonstration that the test measures the wrong property. Net effect: normalize the heading family + promote one H3 + author the residual. **Partition re-verified at Commit 0** against the live corpus with both control arms; sensitivity and specificity arms clean, extraction shown non-empty. **This applies the ratified call; it does not re-open it.** | Wave-1 gate; **pinned at Stage 6 Commit 0** |
| **Δ-size** | #3707 carried `size:S` | **Re-sized to `size:M`** once its accepted scope change (the git-workflow self-contradiction) landed in its surface. | Wave-1 gate |
| **Δ-D1** | Public-surface policy for the ADR `deciders:` carve-out was open | **NAME-ONLY ratified.** The carve-out permits the operator's literal **name**, never the GitHub handle. The spec narrows; the durability lint's handle rule is not touched. | Wave-1 gate |
| **Δ-anchor** | Stage-4 standing constraint read *"derive against `main` **and** all remote branches"* → next-free two above the `main` anchor | **CORRECTED: the binding anchor is `origin/main` ONLY.** The Stage-4 wording conflated **detection** with **binding** and yielded the exact gap-landing value it was written to prevent — binding two above the `main` anchor lands a 2-wide gap on `main` if this release merges first, and the contiguity gate then fails every subsequent PR. Scanning other branches is for *detection*, never for *binding*. **Binding at the `main` next-free is safe under both merge orders.** Raised at Stage 5; hub-verified against the corpus; both numbers derived accordingly at Commit 0. | Stage-5 finding; Wave-1 gate |
| **Δ-baseline** | Stage-4 pinned `origin/main` at the milestone-readiness commit | **Re-pinned at Commit 0 — unchanged, zero commits of drift.** Every chip still re-locates its edit anchors by content, not by line number. | Commit-0 re-verify |
| **Δ-cascade** | The Stage-5 consumer table classified `core/schemas/README.md` as "cites, does not restate → NO update" | **UPDATE — the row does restate the cardinality.** The Commit-0 cascade sweep found the schema index row carrying the literal body-section count, which the §3 change makes stale. Owned by no other card and forced by this card's change, so it is repaired here rather than left to ship a stale count inside the release that exists to eliminate stale counts. Smallest correct edit: the one cardinality token. The adjacent frontmatter-field count is **correct** and was deliberately left alone — making index-row counts structurally durable is the count-vs-structure lint's job, not this card's. **Sweep verdict: 3 UPDATE (1 handed to #3916) / 2 PRESERVE / 2 N/A**, both arms clean. | Stage-6 implementation finding (#3914 chip) |
| **Δ-adr** | Stage-4 left both ADR numbers to be derived at Commit 0 | **ADR-110 allocated and landed** for #3914 (`core/ADRs/`, cross-cutting platform decision), covering both reconciliations in one record — they are a single coherent decision (*what the standard requires, and what may be edited to reach it*), and splitting them would produce two records that must cite each other to be understood. **ADR-111 is #3713's** to author in its slice. The new record is the first authored under the reconciled set and carries all seven sections; it passes the durability lint with **zero** findings and **without** an override marker. | Commit 0; #3914 chip |
| **Δ-version** | Stage-4 recorded a rule-computed provisional next-free minor | **Commit-0 re-verify: PROCEED.** `anchor()` re-derived from authoritative host state (remote tags + the ledger read from `origin/main`, not the worktree copy); the `minor`-floor next-free is **unchanged** from the Stage-4 recorded determination and is still free. Per ADR-092 the concrete number does **not** bind here — it binds at the Stage-12 atomic claim. The sibling release will compute the same slot; that is expected, and the atomic claim resolves it. | Commit-0 re-verify |
| **Δ-refblock** | SC-3 was framed as widening the issue-ref gate's reference-block pattern so `## Related ADRs` is recognized, on the read that it is "the single largest unblocking of the rung-5 rule" | **Implemented as `Source(s)` only; `Related ADRs` deliberately NOT added.** Measured on the live corpus: recognizing `## Related ADRs` moves **one** marker-carrying file out of the still-misplaced set, and the tokens it un-flags are, on inspection, bare `#N` sitting **inside** `## Related ADRs` sections — precisely the zone-1 violations the new rule prohibits and the sweep needs to see. Because these gates treat the first recognized heading as a *cut point*, recognizing it would lift the cut above that section and make the gate accept exactly the placement this release's own rule forbids. The `Source(s)` arm **is** a genuine defect: the gate's own failure message, the core ADR README and the durability standard all named `### Source(s)` as recognized while the regex rejected it — specification-versus-implementation, now corrected. The real unblocking is naming `## References` as the ADR reference block, which is what the guide now does. **Evidence-grounded deviation from the hub's framing, surfaced for Stage 9 — a one-line regex either way, CHEAP to reverse.** | Stage-6 implementation finding (#3915 chip) |
| **Δ-refblock-2gates** | Both the guide draft and the surrounding discussion assumed one recognized reference-block heading set | **There are TWO independent `REFBLOCK_RE` declarations and they already disagree.** The issue-ref gate declares its own inline; the reference-durability gate, its PreToolUse hook and its fixture runner all source a single shared pattern library. `Related` and `Source(s)` are recognized by the issue-ref gate **only**. `## References`, `## Issue References`, `## Provenance`, `## Sources` sit in the **intersection**. The guide is authored to the intersection and states why, rather than offering the union as a menu. **Unifying the two sets is NOT done here** — it is a corpus-wide behavioural change to a shared hook library with its own fixture suite, outside SC-3, and it needs an operator call on which set is canonical. Recorded as a residual. | Stage-6 implementation finding (#3915 chip) |
| **Δ-cascade-gw** | The Stage-5 File Change Matrix did not list `core/rules/git-workflow.md` for #3915 | **UPDATE — forced by R4.** Its § Repository-Integrity Gates paragraph enumerated the durability job's rules with a frozen cardinality, which adding a fourth rule makes false. Repaired as the smallest correct edit: the cardinality is **de-cardinalized** (it now cites the module docstring as the enumerating authority) and the fourth rule is added to the list. The `deciders:` carve-out sentence — the sibling card's declared SC-2 surface — is **byte-untouched**; the two edits are region-disjoint and serialization suffices. | Stage-6 implementation finding (#3915 chip) |
| **Δ-E1** | The binding C1 partition row for #3915 named only "a new H3 … plus the reference-block statement" | **Two further in-scope prose edits were required and made.** (a) The post-template-fence sentence that over-generalised the cross-ADR `never issue #N` note into a blanket ban on body **and frontmatter** references is the contradiction the card exists to remove — leaving it would fail the card's own no-contradiction criterion while the new H3 permits a bare `#N` in `source_observations:` two screens below. (b) The `### Durability rules` **intro clause** stated a frozen count of enforced rules, which R4 falsifies. **Neither is another writer's declared region:** the landed slice-1 edits (§ ADR template prose, template guidance comment, § Supersession H3) and the two reserved table **rows** plus the exemption paragraph are all byte-untouched, verified with a sensitivity control. | Stage-6 implementation finding (#3915 chip) |
| **Δ-E3-dropped** | The Stage-5 spec proposed appending a cross-reference sentence to the trailing prose of `### Durability rules` | **DROPPED.** The consolidated Wave-1 gate assigned that paragraph — the stale-anchor exemption prose — to the sibling stale-anchor card. The cross-reference now lives inside the new H3 instead, which is wholly within this card's region. The spec's "deliberate seam" is closed rather than contested. | Wave-1 gate; #3915 chip |
| **Δ-frontmatter-split** | The Stage-5 spec made repointing `source_observation_lines()` at the shared bound an in-scope prerequisite for this card | **Split: the helper is built here, the repoint is left to the stale-anchor card.** That card owns the frontmatter-detector repair as an accepted scope change, and repointing the exemption here would shift the **R2** corpus verdict from this card's commit, muddying attribution for a rule this card does not own. `frontmatter_bounds()` therefore ships as a shared, comment-tolerant helper consumed by R4 only; `source_observation_lines()` is **byte-identical** to its pre-change form, with a docstring note naming the helper the repair should consume. Measured: the tolerant bound is worth **10** additional identity-field tokens over the shipped line-0 rule. | Stage-6 coordination (#3915 → #3708) |

---

## Rollback

Per `RELEASE_PROTOCOL.md § Rollback protocol` (operator-authorized). One branch, one PR, one merge → release-level rollback is `git revert` of the merge commit on a `fix/` branch through the normal PR path — never a force-push to `main`, never a history rewrite.

**Pre-merge, rollback is wave-granular.** The branch is built in wave order, so each wave is a contiguous commit range. Dropping Wave 2 before merge is a revert of that range or a reset to the Wave-1 tip — Wave 1 has **no** dependency on Wave 2 (all three HARD edges point *into* Wave 2, never out of it). This is a deliberate property of the sequencing: **the recommended order makes the expensive card the last and most droppable one.**

| Surface | Rollback | Tier |
|---|---|---|
| #3914 standard reconciliation + its ADR | `git revert` — prose + one additive self-test case | **CHEAP** |
| #3915, #3707 | `git revert` — documentation + spec text | **CHEAP** |
| #3708 | `git revert` — additive checker vocabulary + self-tests, warn-mode, delta-scoped | **CHEAP** |
| #3916 | `git revert`, then rebuild the ADR-authoring package or it drifts from source | **CHEAP–MODERATE** |
| #3713 + its ADR | `git revert` — but it adds a Stage-12 step other releases may adopt; reverting strands anyone mid-flight on the tooled path | **MODERATE** |
| #1488 (+#3383) | `git revert` is textually clean, **but** it restores a non-conformant corpus | **MODERATE — the binding constraint** |

**Rollback-driven design constraint — the one thing that must not ship in this release.**

**Do NOT flip the durability lint's `WARN_MODE` to enforce in this PR.** The flip is hard-gated on the conformance pass, so it is *tempting* to land both together. If it did, a revert of the sweep would leave an **enforcing gate over a corpus that just reverted to non-conformant** — every subsequent PR red, with the fix already reverted. That is a rollback trap, and the recovery would be a two-step manual operation under CI pressure. Verified as a boundary to hold rather than a scope change: **no issue in this milestone carries the flip as an acceptance criterion** — three cards mention it as forward context, none as a criterion. The flip belongs in a thin follow-up release **after** this one has soaked, where it is a one-line change with a trivial revert.

**Partial-ship safety.** Within #3914, the immutability carve-out is independently revertible from the requirement-level change — though reverting the carve-out alone would re-block the sweep.

No IRREVERSIBLE actions. **No tag is claimed by this plan** — version identity binds at the Stage-12 atomic claim, so there is no tag-rollback surface at Stage 6.

---

*Closure-phrasing note: every per-issue closure reference in this plan is written as "mark #N as closed at Stage 13" — no close-family verb is bound to an issue number, so transcription into PR bodies will not trip GitHub's auto-close parser.*
