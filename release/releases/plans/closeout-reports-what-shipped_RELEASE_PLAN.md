---
title: Release Plan — closeout-reports-what-shipped (a release's close-out reports what actually shipped)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: closeout-reports-what-shipped
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `closeout-reports-what-shipped`

**Version identity:** **slug-only** per **ADR-092**. This file is `closeout-reports-what-shipped_RELEASE_PLAN.md` and the branch is `release/closeout-reports-what-shipped`; no version stem appears in the plan filename, the branch name, or this plan's identity prose. The bump class is the durable declaration; the concrete number binds at the **Stage-12 atomic claim**, when the claim tool resolves the braced RELEASE_VERSION token this file carries and renames the file into the major-version plans folder. This plan carries **exactly one** such token — the Header `**Version**` cell — so the stamp has a single, verifiable resolution site.

**Topology:** D-C **SINGLE** — one release branch, one PR, one merge gate. This file lands as **Engineering Commit 0**, authored by the first per-issue Stage-6 Engineering spoke.

**Concurrency posture:** **P0 fully-serial**. Stage-6 spokes route one at a time in the approved sequence on the single shared branch; force-push — including the lease-guarded form — is prohibited on that branch under any multi-spoke activity. The posture is rule-determined here rather than chosen: under SINGLE, Stage 6 is write-serialized by rule, and all five cards write the same 10,400-line script.

**Release class:** **`cross-cutting`** — operator verdict at the Stage-4 gate, re-classifying the milestone's declared `routine`. Trigger (c) fired on the Stage-4 dependency DAG's three hard edges; multi-trigger resolution (`cross-cutting` > `novel` > `routine`) bound the outcome. Posture now in force: engagement density **Tight** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window extended.

**Sizing:** 14 raw points across 5 cards. At `cross-cutting` weight 1.3 the effective figure is **18.2 against a 15–25 band** — inside the band. The slice was locked at 14/5 after `DROP-EMITORDER` closed not-a-defect; the Stage-4 plan's 16-point / 6-card figure is superseded and survives only in § Deviation Log as the record of what changed.

**Plan lifecycle note.** The `## Change Description` section required by Stage-6 Phase C1 is **not** part of Engineering Commit 0. It is authored into this file at PR assembly, after the final Engineering commit lands and before the PR is transitioned from draft to ready-for-review, so the operator reads it in the Stage-9 diff.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | **minor** — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). |
| **Date Created** | 2026-08-20 (Thursday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/closeout-reports-what-shipped |
| **PR** | (populated at Stage 6 Phase C) |
| **Milestone** | closeout-reports-what-shipped |

---

## Release Outcome Statement

**AFTER** this release: a release's close-out reports what actually shipped — velocity, phase results, and gate proof are computed, complete, and correct.

**BEFORE:** close-out reports delivered 0 pts, cannot verify its own output set, corrupts audit fields it re-injects, and can abort mid-write.

---

## Card Labels

This plan refers to its work items by durable label rather than by number, so it survives renumbering and re-bundling and so its scope reads without a tracker open. The label-to-number binding lives once, in the § Issue References block at the foot of this file.

| Label | Type | Size | Pts | What it settles |
|---|---|---|---|---|
| **`FIX-CHOREPR`** | bug | S | 2 | The Gate-Passage-Proof `**Chore PR:**` field renders the number twice on the populated path, because a paired set-arm / unset-arm expansion on one variable lets both arms fire. Fix, plus the first both-paths self-test arm in the release. |
| **`FIX-OUTCOMEKEY`** | bug | S | 2 | The `**Outcome:**` field is re-injected under a qualified key because two sites independently assumed a bare key. Settles the permitted-key grammar once, at the standard, and serves both sites from one resolver. |
| **`FIX-PREFLIGHT`** | bug | S | 2 | The Phase-A7 learnings precondition fails at dispatch position 8, after seven phases have already written. Moves the assertion into preflight; the existing late BLOCK is retained as a backstop, not replaced. |
| **`FIX-VELOCITY`** | bug | M | 4 | Velocity is computed from close state before the membership is closed, so a release books `delivered 0`. Replaces the close-state predicate with a close-state-independent one. |
| **`BLD-OUTPUTSET`** | bug | M | 4 | The close-out cannot assert its own required-output set before it commits. Re-scoped to its residual: pre-stamp (lane-1) binding, emit-on-absence, and required/optional membership. |
| ~~`DROP-EMITORDER`~~ | bug | S | — | **Not in this release.** Closed not-a-defect and demilestoned at the Stage-5 Collective Review. |

---

## Scope

Five cards, one capability, one shared script. Every card fails the same way — the close-out emits a record that does not describe what happened — so one AFTER statement covers the set.

**Re-scopes carried into this plan, not left to be rediscovered at Stage 6:**

- **`BLD-OUTPUTSET` is re-scoped** (operator decision `D-OUTPUTSET-Scope`, Stage-4 gate). Its original first two acceptance criteria verify work that already shipped: the deploy check's Stage-13 output-set sub-checks for the velocity field and the Release-Learnings block are **armed** at the outputs cutoff, and the close stage spec's Phase A8 already binds the canonical output set to the bridge's Step-4 table. Build the residual — **pre-stamp lane-1 binding, emit-on-absence, required/optional membership** — not the card as filed.
- **`FIX-VELOCITY`'s delivered predicate is CD-1**, adopted at Collective Review after the Stage-5 label-predicate design was falsified at the Phase A6.5 adversarial review. The predicate **recovers the Phase-A2-demilestoned set into `planned` from timeline events** rather than reading current membership or `size:` labels. The card's own filed remediation — compute `delivered` from the milestone's member set and their `size:` labels — is directional, not a build spec: taken literally it deletes the only predicate separating `delivered` from `planned` and makes the metric tautological.
- **`DROP-EMITORDER` is gone.** It appears nowhere in the sequence, the dependency graph, the contention map, or the file change matrix below. Its only residue is the one conditional matrix row it used to gate, which is now unconditional under `FIX-VELOCITY`.

---

## Release-Wide Ruling — the dry-run / apply pattern

**Rendered by the operator at Collective Review as `AI-013`, binding on every card.** Three of five cards had taken different positions on how a new assertion should behave under `--dry-run` versus `--apply`. One ruling settles it, and it points at a precedent that **already exists in the file** rather than inventing a doctrine:

> Adopt the existing in-file `WARN` token precedent — **non-blocking in dry-run, fatal at apply**.

The shipped exemplar is the `rebuild_skill_packages` phase, which marks `WARN` with an explanatory tail stating that the condition is *not* blocking under `--dry-run` because nothing is committed there, and that the **same condition fails the close at `--apply`**. Any new assertion this release adds that must not abort a dry-run takes that shape: `mark_phase "<phase>" "WARN" "<what was found> — NOT blocking under --dry-run …; this same condition FAILS the close at --apply"`. No card invents a second convention, and no card silently downgrades an apply-path failure to a warning.

---

## Dependency Graph

Directional. `A ==> B` reads *A must settle before B*. `A --> B` is a soft edge — absorbable; sequencing is prudence rather than necessity.

```
FIX-CHOREPR  --(soft: both-paths self-test idiom)-->  FIX-OUTCOMEKEY
     |                                                      |
     +--(soft: same idiom)------------------------->  BLD-OUTPUTSET
                                                            ^
FIX-PREFLIGHT  ==(HARD: settled Phase A7 semantics precede manifest authorship)==+
                                                            ^
FIX-VELOCITY  --(soft: velocity is a manifest item)---------+

FIX-OUTCOMEKEY  --(soft: shared-primitive adjacency, NOT hard — see below)-->  FIX-VELOCITY
```

**Hard edges: 1.**

| Edge | Kind | Evidence |
|---|---|---|
| **`FIX-PREFLIGHT` ==> `BLD-OUTPUTSET`** | authoring-order | Both edit the close stage spec. `FIX-PREFLIGHT` reclassifies the Phase-A7 precondition from an in-sequence beat to an entry precondition, and the learnings triple is a manifest item `BLD-OUTPUTSET` must enumerate. `BLD-OUTPUTSET` must read the reclassified sentence, not the pre-fix one. |

**Soft edges: 4.** `FIX-CHOREPR` to each of `FIX-OUTCOMEKEY` and `BLD-OUTPUTSET` (it establishes the both-paths self-test idiom both need); `FIX-VELOCITY` to `BLD-OUTPUTSET` (the velocity field is one output the residual manifest asserts); `FIX-OUTCOMEKEY` to `FIX-VELOCITY` (adjacency on the field-insert primitive — see the dissolution note).

**The `FIX-OUTCOMEKEY` ==> `FIX-VELOCITY` hard edge is DISSOLVED.** The Stage-4 plan carried it as hard on the reasoning that the "one resolver serves both sites" criterion would generalize the shared `_insert_field_after_in_block` primitive, whose exact-prefix semantics the velocity insert depends on. `FIX-OUTCOMEKEY`'s Stage-5 design **does not touch that function**: it adds a new sibling resolver and performs anchor-string resolution *upstream* of the primitive, leaving the primitive's body byte-unchanged, and it publishes a voluntary integration criterion whose falsifier is a diff showing any added or removed line inside that body. The edge is therefore **soft** — keeping `FIX-OUTCOMEKEY` ahead of `FIX-VELOCITY` in the sequence is belt-and-braces, not load-bearing. Risk **R-4** drops **MEDIUM → LOW** accordingly.

**Cycles: zero.** Five nodes, five edges; longest chain `FIX-PREFLIGHT ==> BLD-OUTPUTSET`, length 2.

**Cross-card dependency edges declared on the tracker: zero.** Every edge above is derived from file/region analysis, not from a declared dependency field.

---

## Implementation Sequence

**Sequence:** `FIX-CHOREPR -> FIX-OUTCOMEKEY -> FIX-PREFLIGHT -> FIX-VELOCITY -> BLD-OUTPUTSET`

One Engineering chip at a time on the single release branch; the next chip waits until the prior commit lands.

| # | Card | Pts | Why here | Primary surface |
|---|---|---|---|---|
| 1 | **`FIX-CHOREPR`** | 2 | Zero upstream edges, smallest and most isolated region, and the sole writer of `generate_markdown_report` in this release. Establishes the both-paths self-test idiom two siblings mirror, at the lowest cost. Also carries Engineering Commit 0 (this file). | the `**Chore PR:**` render line inside `generate_markdown_report` + a new `self_test` arm |
| 2 | **`FIX-OUTCOMEKEY`** | 2 | Renders the permitted-key grammar the standard currently leaves unspecified, and settles the field-key resolution seam before any velocity work sits near it. | new `_resolve_field_key_in_block` + the phase-6.5 idempotency probe + the phase-6.8 anchor block · the decision-outcome standard |
| 3 | **`FIX-PREFLIGHT`** | 2 | Textually disjoint from 1–2. Opens the close stage spec's Phase A7 so the capstone can close over settled semantics. | `phase_preflight` · `phase_append_release_learnings` · close stage spec Phase A7 · the release-executor skill's Mode D and its close-out checklist · the bridge's preflight-block remedy |
| 4 | **`FIX-VELOCITY`** | 4 | Highest design risk. Consumes a settled field-insert seam and lands its historical ledger correction early, well away from Stage 12/13. | the velocity computation script's delivered predicate · `phase_inject_velocity_field` · the velocity-tracking standard · the execute stage spec's cascade site · the ledger's historical rows |
| 5 | **`BLD-OUTPUTSET`** | 4 | Capstone. The residual manifest binding must be authored over a settled Phase A7 (3), a settled velocity emit (4), and a settled Outcome grammar (2). | new `phase_assert_output_set` + one runner line · close stage spec Phase A8 · the gate-criteria schema's G-CL3 row · the bridge's Step-4 table |

At Stage 13 the release **marks all five cards as closed**, by the numbers bound in § Issue References.

---

## Stage Applicability Matrix

Default is *all stages apply*. Every deviation is stated with its reason.

| Card | S5 Solutioning | S6 Engineering | S7 Dev Testing | S8 QA | S9–S13 |
|---|---|---|---|---|---|
| **`FIX-CHOREPR`** | APPLY (complete) — a one-line fix, but its fourth criterion specifies a *self-test design*; an arm that runs only dry-run does not satisfy it | APPLY | APPLY — changes a rendered audit field | APPLY | release-scoped |
| **`FIX-OUTCOMEKEY`** | APPLY (complete) — carries the permitted-key grammar decision the card itself calls the load-bearing half | APPLY | APPLY | APPLY | release-scoped |
| **`FIX-PREFLIGHT`** | APPLY (complete) — moving a gate earlier changes felt ergonomics and adds an idempotency requirement on re-entry | APPLY | APPLY — changes when the run aborts | APPLY | release-scoped |
| **`FIX-VELOCITY`** | APPLY (complete) — the filed remediation is directional, not a build spec | APPLY | APPLY | APPLY | release-scoped |
| **`BLD-OUTPUTSET`** | APPLY (complete) — re-scoped to its residual before designing | APPLY | APPLY | APPLY | release-scoped |

**Zero Stage-5 skips and zero Stage-7/8 skips.** Every card changes shipped script behaviour or a governed gate.

---

## File Change Matrix

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-20, domain: software }`

*Classification rationale:* dominant **`software`** — the change mass is two tracked shell scripts plus their self-test arms; secondary **`governance`** (two pipeline-stage specs, one schema, two standards, one how-to, one skill and its reference). External sourcing is exempt because every path is an internal platform artifact; the `domain:` class is recorded regardless, per the sourcing-exempt-is-not-domain-less rule.

One repo-relative path per line, so a downstream chip extracts the set deterministically.

```
# ── Unconditional edits ──
release/tools/automated-closeout.sh                                      edit
release/tools/compute-release-velocity.sh                                edit
release/references/pipeline/stage-13-close.md                            edit
release/references/pipeline/stage-12-execute.md                          edit
release/governance/release-process.md                                    edit
release/references/how-to/hub-spoke-bridge.md                            edit
release/references/standards/decision-outcome-tracking.md                edit
release/references/standards/release-velocity-tracking.md                edit
core/schemas/gate-criteria-spec.md                                       edit
release/skills/release-executor/SKILL.md                                 edit
release/skills/release-executor/references/close-out-checklist.md        edit
release/releases/RELEASE_LOG.md                                          edit

# ── Additions ──
release/releases/plans/closeout-reports-what-shipped_RELEASE_PLAN.md     add
packages/release-executor.skill                                          add-or-replace
packages/release-executor.skill.sha256                                   add-or-replace

# ── Read-only inputs (excluded from the delivery obligation set) ──
core/deploy/deploy.sh                                                    READ
release/tools/check-selftest-coverage.py                                 READ
.github/workflows/release-tooling-smoke.yml                              READ
.github/workflows/repo-integrity.yml                                     READ

# ── Explicit non-scope ──
release/releases/RELEASE_LOG_ARCHIVE-segments                            NOT EDITED
automated-closeout.sh :: the --no-merge chore-PR deferral message        NOT EDITED
release-velocity-tracking.md :: 3.3 and N6 (field placement)             NOT EDITED
```

**Per-file ownership, and the notes that matter:**

| Path | Owning card(s) | Note |
|---|---|---|
| `release/tools/automated-closeout.sh` | all five | The release's shared surface. Region-level disjointness is the § Contention Map's subject. |
| `release/tools/compute-release-velocity.sh` | `FIX-VELOCITY` | The **primary** fix surface, absent from the card's own Affected Files — the delivered accumulator's close-state gate lives here, not in the close-out script. |
| `release/references/pipeline/stage-13-close.md` | `FIX-PREFLIGHT` (Phase A7), `BLD-OUTPUTSET` (Phase A8) | Sequenced 3 → 5. The first reclassifies the A7 precondition; the second adds the A8 lane-1 binding sentences additively and must reference-not-re-enumerate the output set. |
| `release/references/pipeline/stage-12-execute.md` | `FIX-VELOCITY` | Added at Stage 5 — a live cascade site restating the "authoritative only once membership is closed" predicate the card changes. Absent from the Stage-4 matrix. |
| `release/governance/release-process.md` | `FIX-VELOCITY` | Added at Stage 6 (DV-10) — the **fifth** cascade site for the same predicate, and the only one in a top-level governance doc. Missed by the Stage-5 sweep; found by re-running it at build time. One clause; sole writer, zero contention. |
| `release/references/how-to/hub-spoke-bridge.md` | `FIX-PREFLIGHT`, `BLD-OUTPUTSET` | Moved from READ to edit. The first corrects the preflight-block remedy (the `D-PREFLIGHT-A` scope expansion the operator rendered); the second extends the canonical Step-4 table with a required/optional column plus three rows, and fixes two cascade counts. Two cards, disjoint spans. |
| `release/references/standards/decision-outcome-tracking.md` | `FIX-OUTCOMEKEY` | New permitted-key-forms subsection, plus a frontmatter `version:` bump and a Version History row. |
| `release/references/standards/release-velocity-tracking.md` | `FIX-VELOCITY` | **Promoted from CONDITIONAL to unconditional.** Its Stage-4 condition was gated on a `DROP-EMITORDER` disposition; retiring that card retired the conditional, which would otherwise have left a needed file out of scope. Sections 3.3 and N6 stay **byte-unchanged** — promoting the file does not re-open the retired card. |
| `core/schemas/gate-criteria-spec.md` | `BLD-OUTPUTSET` | The G-CL3 criterion is **extended in place** with the pre-commit completeness limb. No new criterion row — a second one would fork the terminal-record concern across two rows. |
| `release/skills/release-executor/SKILL.md` + its `references/close-out-checklist.md` | `FIX-PREFLIGHT` | Mode D input collection, and the checklist's preflight-block remedy. **Editing either fires the package-rebuild obligation** below. |
| `release/releases/RELEASE_LOG.md` | `FIX-VELOCITY` | Historical Deployment-Log correction. The affected-row population is **seven rows, not the two the card names, and the earliest row it names is not among them** — that row records a real ratio and never carried a zero. Land the correction early, never at Stage 12/13. |

**Package-rebuild obligation (fires; do not skip).** `FIX-PREFLIGHT` edits a rostered skill's `SKILL.md` **and** a file under its `references/`, so the `.skill` package and its `.sha256` content baseline must be rebuilt via the package builder and committed **in this PR**. The `skill-package-freshness` CI gate enforces this pre-merge; a stale package cannot merge green. That obligation is the only reason the `packages/` rows appear in the matrix.

**Script-execution allowlist:** no row adds a *new* tracked executable script, so the allowlist companion obligation does not fire.

---

## Contention Map

**Verdict: heavy, concentrated, and fully absorbed by the resolved topology.** Under D-C SINGLE with P0 serial the contention drives *sequence*, not conflict — there is no concurrent-write surface to race on. The operator's **do-not-partition** verdict stands; partitioning would require Option-A topology, which this map argues against.

| File | Cards | Class | Resolution |
|---|---|---|---|
| `release/tools/automated-closeout.sh` | **5** | mixed | Serial sequence. Regions are function-disjoint except `self_test`, which is append-pattern. |
| `release/references/pipeline/stage-13-close.md` | 2 | append-pattern | Sequence `FIX-PREFLIGHT` → `BLD-OUTPUTSET`; CIAC-3 grades the composed result. |
| `release/references/how-to/hub-spoke-bridge.md` | 2 | disjoint spans | One card edits the preflight-remedy prose; the other edits the Step-4 table and two cascade counts. Different sections, different cards, serial. |
| `release/releases/RELEASE_LOG.md` | 1 | line-range overlap **with this release's own close** | Land the historical correction early (position 4), never at Stage 12/13. Prefer the append-shaped annotation over a recomputed figure. |
| every remaining path | 1 | single-writer | none needed |

**Within `automated-closeout.sh` — region level:**

| Region | Card | Overlap |
|---|---|---|
| `phase_preflight` | `FIX-PREFLIGHT` | none |
| helper span above `phase_preflight` | `FIX-PREFLIGHT` | none |
| `_insert_field_after_in_block` | — | **read-only for every card.** `FIX-OUTCOMEKEY` adds a sibling resolver *after* its closing brace; the body stays byte-unchanged. |
| `phase_inject_outcome_field` (the 6.5 probe) | `FIX-OUTCOMEKEY` | none |
| `phase_inject_velocity_field` | `FIX-VELOCITY` | reads the primitive; does not edit it |
| `phase_append_release_learnings` | `FIX-PREFLIGHT`, `BLD-OUTPUTSET` | **real, and the sharpest in the release** — see the anchor-drift note below |
| `phase_inject_close_class_telemetry_field` | `FIX-OUTCOMEKEY` (6.8 anchor), `BLD-OUTPUTSET` (capability-skip arm) | disjoint arms inside one function; serial |
| `phase_run_verification` render | `BLD-OUTPUTSET` | none |
| new function slot before `phase_bump_version` | `BLD-OUTPUTSET` | none |
| `generate_markdown_report` | **`FIX-CHOREPR` only** | **none.** A full four-sibling region overlay confirmed no sibling writes a single line inside this function. The Stage-4 map's two-card textual overlap was a false positive at the literal reading: the capstone's own design states its new phase renders additively with no renderer change. |
| `self_test` | all five | append-pattern. Structurally maximal, operationally low under P0 serial. |
| runner dispatch block | `BLD-OUTPUTSET` | one-line insertion |

**Anchor drift is the live contention hazard, not merge conflict.** Under write-serialization there is no merge, so nothing races. What *does* move is line numbers: every card that lands earlier shifts every line below it. Two concrete cases the Stage-5 adversarial reviews surfaced, and that Stage 6 must honour:

1. **Locate by construct, never by line number** — and **probe the construct's uniqueness before writing it into a handoff.** A construct that occurs 185 times is a line number wearing a construct's clothes. Every insertion anchor must be verified repo-unique at the moment of the edit.
2. **`phase_append_release_learnings` is edited by two cards** — `FIX-PREFLIGHT` at position 3 and `BLD-OUTPUTSET` at position 5 — and the capstone's declared anchors in that function sit below the earlier card's insertions and *will* have drifted by the time it executes. That function contains two distinct `SKIPPED`-return sites; a line-anchored instruction cannot distinguish them after drift. The capstone re-locates by construct at execution time.

**`self_test` symbol hygiene.** Every card prefixes its arm-local symbols with a card-unique token so no two arms collide on a name, and no card renumbers or rewrites another card's arm.

**Cross-PR contention: none at the baseline.** Zero in-flight sibling releases at the release base (remote-heads arm valid: subject 0, sensitivity 2, specificity 0). The open-PR arm of that roster was a **broken probe** — its control arm also returned zero — and is reported unusable rather than as an empty population. `automated-closeout.sh` is a high-traffic file, so a transiently-empty sibling population is not load-bearing: **re-measure at Stage 9 before GO**, per audit-baseline discipline.

---

## Risk Register

| ID | Sev | Risk | Owner | Mitigation | Reversibility |
|---|---|---|---|---|---|
| **R-1** | **HIGH** | **The capstone builds its filed scope instead of its residual**, re-implementing shipped verification machinery and authoring a parallel structure over a governed home. | Stage 6 (`BLD-OUTPUTSET`) | The operator rendered `D-OUTPUTSET-Scope` = re-scope. Build **pre-stamp lane-1 binding + emit-on-absence + required/optional membership** only. The re-scope is recorded in § Scope above rather than left to be rediscovered. | CHEAP pre-build |
| **R-2** | **HIGH** | **The delivered predicate collapses `delivered` into `planned`.** Dropping the close-state gate without a replacement makes the metric tautological, and the card's own order-independence criterion forecloses the cheaper "just move the dispatch later" alternative. | Stage 6 (`FIX-VELOCITY`) | Adopt **CD-1**: recover the demilestoned set into `planned` from timeline events. The implausibility guard is the backstop that catches a wrong choice before the value lands in the permanent ledger. | CHEAP pre-build; **MODERATE** post-build — the value lands in a durable record |
| **R-3** | **MEDIUM** | **A new assertion aborts a dry-run**, or an apply-path failure is silently downgraded to a warning. Three cards had taken different positions on this axis. | every card | The release-wide ruling above: adopt the existing in-file `WARN` token precedent — non-blocking in dry-run, fatal at apply. One convention, already shipped in this file. | CHEAP |
| **R-4** | **LOW** | **Shared-primitive semantic coupling** between the key-resolution work and the velocity insert. | Stage 6 | **Downgraded MEDIUM → LOW at Stage 5.** `FIX-OUTCOMEKEY` leaves the shared primitive byte-unchanged and publishes a falsifiable integration criterion to that effect; sequencing it ahead of `FIX-VELOCITY` is now prudence rather than necessity. CIAC-1 still grades the composed behaviour on the merged PR. | CHEAP |
| **R-5** | **MEDIUM** | **Anchor drift.** Every card that lands shifts the line numbers below it; two cards edit the same function roughly 250 lines apart, and one declared a 185-way-ambiguous construct anchor. A line-anchored edit lands in the wrong arm silently. | Stage 6 | Locate by construct at execution time, and **probe the anchor's uniqueness before editing**. Card-unique symbol prefixes in `self_test`. This risk replaces the Stage-4 `self_test`-collision framing, which P0 serial already neutralises. | CHEAP if caught at edit time; **MODERATE** if a mis-edit ships |
| **R-6** | **MEDIUM** | **The folded phase-order criterion is unsatisfiable as written.** It requires asserting that the documented phase order matches the script's dispatch order, but the stage spec enumerates no script phase numbers at all — the doc's lettered phases and the script's dispatch are different ontologies, not two versions of one list. | Stage 6 (`FIX-VELOCITY`) | Settled at Stage 5 and routed to the operator as an open item. Do not leave it to be discovered at Stage 8 as an ungradable criterion. | CHEAP |
| **R-7** | **MEDIUM** | **The historical ledger rows are edited in the hot ledger** — the same file this release's own Stage-12/13 close writes. The real affected population is **seven rows, not two**, and one row the card names is a false member. | Stage 6 (`FIX-VELOCITY`) | Land the correction early (position 4), never at Stage 12/13. Prefer the append-shaped annotation over a recomputed figure. Correct the population before editing. | CHEAP (annotation) / MODERATE (recompute) |
| **R-8** | **MEDIUM** | **A shipped assertion returns the pass value on the defect it was written to catch.** The release adds assertions to a suite whose aggregate rule is any-fail-to-exit-1, and an inert assertion is indistinguishable from a green one. | every card | **Every shipped assertion whose failure mode is "returns a plausible value" carries a control counterpart** — the file's own convention, applied to the deliverable and not only to design-time probes. Two instances were caught in review before Engineering; the discipline is now a release-level obligation, graded by CIAC-2. | CHEAP at authoring time |
| **R-9** | **LOW** | **BSD grep on the macOS runner rejects `-P`** (exit 2) and, through the file's count helper's `\|\| true` plus its default-zero, renders exactly `0` — a broken probe that reads clean. | every card | Every matcher in every new arm is **BSD-ERE and backreference-free**. Verified on the runner's own binary. | CHEAP |
| **R-10** | **LOW** | **The SIGPIPE-idiom gate is enforce-day-one with no warn mode**, and reddens on an added pipe-into-a-short-circuiting-reader line in a changed shell file. | every card | Keep every new arm **pipe-free** — here-strings throughout, which is also this file's stated convention. | CHEAP |
| **R-11** | **LOW** | **Stale line references across the cards' bodies.** Every cited number moved at least once; the mechanisms are unchanged and every premise was re-verified live. | Stage 6 | Bodies are left as historical record; Engineering locates by construct. Same mitigation as R-5. | CHEAP |
| **R-12** | **LOW** | **Rollback is not uniformly clean.** Every card is revert-able within the single release PR except the historical ledger data edit and the key-grammar statement, which downstream consumers depend on once stated. | Release | Revert the release PR; both durable-record elements are recorded in § Deviation Log so a revert is reconstructable. | Release-level **MODERATE / HIGH** |

**Severity distribution: 2 HIGH · 5 MEDIUM · 5 LOW.** Both HIGH entries are pre-build scope corrections already rendered by the operator and carried into § Scope above; neither blocks the plan.

---

## Quota Budget

**Verdict:** **WARN** (Checkpoint A).

**Parallel-eligible spokes per parallel stage:** Stage 5 — **0 remaining** (complete) · Stage 6 — **1** (write-serialized by rule under SINGLE; singleton launches only) · Stage 7 — **5** · Stage 8 — **5**.

**Per-spoke cost estimate:** size-bucket ordinal band. The worst batch is 3 × `size:S` (lowest) plus 2 × `size:M` (low–moderate). No bucket meets the cutover predicate, so both retain the ordinal band and no absolute token figure is available. `[ASSUMPTION – CONFIRM]`

**Assumed/stated remaining usage-window envelope:** **`UNSTATED`** — no operator quota band was captured at hub start and none was injected. The conservative default applies.

**Estimated cumulative draw % (worst parallel batch):** **not rendered.** A percentage here would be a projection of a band nobody stated, presented as a measurement. The basis is `UNSTATED`; no figure is synthesized. `[ASSUMPTION – CONFIRM]`

**Routing:** **WARN → window-aware launch timing plus split batches recommended.** Concretely: split the five-spoke Stage-7 and Stage-8 batches rather than launching all five at once, and capture the operator's quota band so Checkpoint B has a real input. The WARN is driven by the unstated envelope, not by an observed overrun — with a stated fresh band, a five-spoke mostly-lowest-bucket batch would plausibly read PASS.

**Contention context.** The parallel-eligible counts are realizable because Stages 7 and 8 are comment-channel output with no shared write surface. The heavy file contention documented above lands entirely on Stage 6, which contributes **N=1** singleton launches, each still gated by Checkpoint B.

---

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (`FIX-OUTCOMEKEY` × `FIX-VELOCITY`, on the field-insert primitive):** After the key-resolution work lands, **every** Deployment-Log field insert still resolves through a single shared key definition, and the `**Velocity:**` field still lands immediately after `**Cycle-Time:**` per the placement norm — the resolver change must not silently relocate or drop a sibling field. *Method:* enumerate every call site of `_insert_field_after_in_block` in `release/tools/automated-closeout.sh` and assert none carries a private matcher; assert the function body is byte-unchanged against the release base; then run the close-out script's `--self-test` and assert the velocity-placement and outcome-idempotency arms both pass. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (all five cards, on the `self_test` block):** Every card whose defect was invisible on the only path the existing arms exercise adds an arm covering the **previously-uncovered** path, and **every shipped assertion whose failure mode is "returns a plausible value" carries a control counterpart**. A release that repairs several "invisible on the exercised path" defects and adds several dry-run-only arms has shipped the blind spot it repaired. *Method:* run `--self-test`; assert the arm count increased by the number of cards adding arms, that each new arm names both the previously-covered and the previously-uncovered path, and that each count-shaped or presence-shaped assertion is paired with a control returning a *different* value on the known-bad input. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (`FIX-PREFLIGHT` × `FIX-VELOCITY` × `BLD-OUTPUTSET`, on the close stage spec):** After all edits land, the stage spec and the script agree — no card leaves the doc describing a precondition or sequence the script no longer runs, and no card leaves the script enforcing a gate the doc does not state. *Method:* extract the runner's phase sequence from the dispatch block and the doc's lettered phase sequence; assert every doc-stated close-out precondition has a live phase and every blocking phase has doc coverage. Note R-6: the doc enumerates no script phase numbers, which is what forces the folded phase-order criterion to be made satisfiable rather than quietly ungraded. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (all five cards, on the required-output set):** The residual manifest binding accounts for every close-out output this release repairs — it is not authored blind to its siblings. The output set it binds names the `**Velocity:**` field, the `#### Release Learnings` block, the `**Outcome:**` field under **both** bare and qualified key forms, and the Gate-Passage-Proof `**Chore PR:**` field, each with a required/optional flag. *Method:* read the delivered manifest binding; assert all four are named and flagged. **Control:** the pre-fix state carries no required/optional flag anywhere in Phase A8, so a non-zero result is a real change rather than a re-count. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (`FIX-CHOREPR` × `FIX-OUTCOMEKEY`, on audit-field singularity):** After both fixes, a full close-out render on a fixed input contains **exactly one** occurrence of each singular audit field — no doubled chore-PR number, and no second `**Outcome` line under a qualified key. The two cards fix the same failure shape (a field emitted twice because two arms both fired) at two unrelated sites; this asserts the shape is gone from the artifact, not merely from each site. *Method:* render the report and the Deployment-Log block on a fixture with the chore-PR number set **and** a qualified Outcome key seeded; assert a per-field occurrence count of exactly 1 for both, **counted by a method that can actually distinguish one occurrence from two**, and assert zero occurrences of a concatenated-number rendering. *Graded at Stage 9 QC3.5 on the merged PR.*

---

## Verification Plan

| # | Check | Method | Owner |
|---|---|---|---|
| **V1** | The close-out script's own suite is green | `bash release/tools/automated-closeout.sh --self-test` → exit 0, zero `FAIL:` lines. Run after **every** Engineering commit, not only at the end. | each Stage-6 spoke |
| **V2** | Discovered tool self-tests pass on the macOS runner | `python3 release/tools/check-selftest-coverage.py --run` — the runtime suite this release's changed paths select (tool-self-test row; read-only, no sandbox). | each Stage-6 spoke (C4) |
| **V3** | Per-card mutation check | Revert only the card's production change, re-run `--self-test`, and assert the arms that name themselves are exactly the arms the card's design predicts. **An expected-kill set that was reasoned rather than executed is a claim, not a proof** — run it. Do not commit the revert. | each Stage-6 spoke |
| **V4** | Doc-link integrity on every modified markdown file | `core/deploy/deploy.sh --check` Check 14. | Stage 6 |
| **V5** | Skill package freshness | Rebuild the release-executor package after `FIX-PREFLIGHT`'s edits and commit the package plus its `.sha256`; the `skill-package-freshness` gate enforces it pre-merge. | Stage 6 (`FIX-PREFLIGHT`) |
| **V6** | Release-corpus lint on this plan file | `python3 core/deploy/tools/lint_release_corpus.py` — filename shape, frontmatter, type coherence. | Engineering Commit 0 |
| **V7** | Stamp manifest resolvable | `release/tools/claim-version.sh --verify-stamp closeout-reports-what-shipped` → exit 0. Asserted **after** this file was written and **before** it was committed. | Engineering Commit 0 |
| **V8** | Cross-issue criteria | The five CIAC methods above. | Stage 9 QC3.5 |
| **V9** | In-flight sibling contention, re-measured | Re-run the remote-heads arm fresh before GO; the Stage-4 measurement is pinned and carries no verdict. | Stage 9 |

**Per-deliverable end state.** Every card reaches `deployed-copy-synced`. Four cards declare **no Layer-2 propagation target** — they change tracked scripts and governed markdown with no deployed copy. `FIX-PREFLIGHT` **does** have one: its skill edits propagate through the package rebuild in V5.

---

## Operator Decisions Recorded

| ID | Decision | Rendered | Reversibility |
|---|---|---|---|
| **D-ReleaseClass** | `routine` → **`cross-cutting`**. Trigger (c) fired on the Stage-4 DAG's three hard edges; multi-trigger resolution binds the highest-ceremony class. `routine` was independently disqualified — four of six cards were P2, and the plan surfaced D-class decisions. | Stage-4 gate | CHEAP (cheaper-to-stricter) / HIGH |
| **D-OUTPUTSET-Scope** | **Re-scope to residual**; do not build as written. The verification machinery the filed criteria assert is already armed. | Stage-4 gate | CHEAP (pre-build) / HIGH |
| **D-Plan-Approval** | Plan and Release Outcome Statement approved; **do-not-partition** accepted. Authorizes end-to-end execution. | Stage-4 gate | MODERATE / HIGH |
| **AI-010** | `FIX-CHOREPR`'s two mandatory test corrections: replace the vacuous occurrence-count assertion with a working counter **plus** its missing control, and correct the mutation-kill set in both directions. | Collective Review | CHEAP / HIGH |
| **AI-013** | The release-wide dry-run/apply ruling — adopt the existing in-file `WARN` token precedent. | Collective Review | CHEAP / HIGH |
| **D-PREFLIGHT-A** | **Scope expansion** — the two out-of-matrix enumerations of the preflight-block remedy come into scope, because for a missing learnings triple the documented remedy is actively harmful: it directs the operator to hand-assemble exactly the unevidenced block the gate exists to refuse. | Collective Review | CHEAP / HIGH |
| **D-EMITORDER** | `DROP-EMITORDER` **closed not-a-defect** and demilestoned. The slice re-locks at 14 pts / 5 cards. | Collective Review | CHEAP / HIGH |
| **D-VELOCITY-Predicate** | The delivered predicate is **CD-1** — recover the demilestoned set into `planned` from timeline events. The Stage-5 label-predicate design was falsified at adversarial review. | Collective Review | CHEAP (pre-build) / HIGH |

**Recorded determinations (rule-determined — not operator gates):** D-Version = next-free **minor**, tool-computed and re-verified at Engineering Commit 0 · D-C Branch Topology = **SINGLE** (default) · D-Concurrency = **P0 fully-serial** (follows by rule from SINGLE) · bundle frame **F1** · size target 15–25 pts.

---

## Rollback Strategy

**Whole-release:** revert the single release PR. All changes are Layer-1 repository content; there is no installed-state migration, no data migration outside the ledger annotation, and no security-detector change.

**Two elements a plain revert does not fully cover** — recorded here so a revert is reconstructable rather than archaeological:

1. **The historical ledger correction.** Seven Deployment-Log rows are a durable audit-record data edit. Reverting the PR restores the pre-correction figures; whether that is *desirable* is a separate operator call, because the pre-correction figures are the ones known to be wrong. Prefer the annotation form for exactly this reason — an annotation is append-shaped, conflict-tolerant, and reverts cleanly without re-asserting a false number.
2. **The permitted-key grammar statement.** Once the standard states the grammar, downstream consumers depend on it. Reverting the code without reverting the statement leaves a documented contract with no implementation.

**Release-level reversibility: MODERATE / Confidence HIGH.**

---

## Deviation Log

| # | Deviation from the Stage-4 plan | Rationale |
|---|---|---|
| **DV-1** | **Slice reduced from 16 points / 6 cards to 14 points / 5 cards.** `DROP-EMITORDER` removed from the sequence, dependency graph, contention map and file change matrix. | Closed not-a-defect and demilestoned at Collective Review. The Stage-4 plan's six-card figures are superseded throughout this file. |
| **DV-2** | **The `FIX-OUTCOMEKEY` ==> `FIX-VELOCITY` hard edge is dissolved to soft;** risk R-4 downgraded MEDIUM → LOW. | The design leaves the shared field-insert primitive byte-unchanged and publishes a falsifiable criterion asserting it. The edge's premise no longer holds. |
| **DV-3** | **The velocity-tracking standard is promoted from CONDITIONAL to unconditional** under `FIX-VELOCITY`. | Its Stage-4 condition was gated on a `DROP-EMITORDER` disposition. Retiring that card retired the conditional, which would otherwise have left a needed file out of scope. Sections 3.3 and N6 stay byte-unchanged. |
| **DV-4** | **The execute stage spec is added** to the file change matrix. | A live cascade site restating the predicate `FIX-VELOCITY` changes; absent from the Stage-4 matrix. |
| **DV-5** | **The hub-spoke bridge moves from READ to edit**, and the release-executor close-out checklist is added. | The `D-PREFLIGHT-A` scope expansion the operator rendered. |
| **DV-6** | **The release-executor package and its `.sha256` are added** to the matrix. | Consequence of `FIX-PREFLIGHT`'s skill edits; the freshness gate makes the rebuild a merge precondition, not an optional beat. |
| **DV-7** | **The historical affected-row population is corrected from two rows to seven**, and the earliest row the card named is removed from it. | That row records a real ratio and never carried a zero; the card's stated population was both under-counted and carried one false member. |
| **DV-8** | **R-5 is reframed** from "`self_test` collision under a non-serial posture" to "anchor drift under serialization". | P0 serial neutralised the collision framing. The residual hazard is that serialization itself moves the line numbers every card's anchors were measured against. |
| **DV-9** | **`FIX-VELOCITY`'s delivery predicate is REPLACED, not adjusted.** The Stage-5 design's label-subtraction predicate (`delivered = planned − terminally-marked members`) was falsified at adversarial review and the operator rendered CD-1 in its place: `delivered` counts milestone members without a terminal not-delivered `status:` label, and `planned` adds back the members Stage-13 Phase A2 removed from the milestone, recovered from their `demilestoned` timeline events. | Phase A2 applies `status: deferred` **and removes the milestone**, and membership is read via `gh issue list --milestone`. The subtracted set was therefore empty by construction on every governed close, pinning the ratio to exactly `1.00` and feeding a constant into the § 6 capacity recalibration — converting a loud filed defect into a silent permanent one. CD-1 recovers the missing set instead, so the ratio carries information again. |
| **DV-10** | **`release/governance/release-process.md` is added to the file change matrix** under `FIX-VELOCITY` (one clause). | A **fifth** cascade site restating the "authoritative only once Stage 13 marks the membership closed" predicate, missed by the Stage-5 Cascade-Sweep and absent from the matrix. Found by re-running the sweep at build time: 5 sites, of which 3 were declared. Leaving it would have shipped the platform's top-level release-process doc asserting a rule the same commit deletes. |
| **DV-11** | **The Phase-A2 recovery under-reports `planned` for a member that was demilestoned and later re-bundled** into a different milestone; such a member loses its terminal `status:` label and leaves the scanned population. Stated as a bound rather than closed. | Closing it needs the Stage-3 membership snapshot the platform does not take (the `planned`-side defect logged as DEBT-1). The bound errs only toward under-reporting `planned`, never toward over-reporting it, and it is documented at the standard's `planned` row rather than left for a later reader to discover. |
| **DV-12** | **`compute-release-velocity.sh --self-test` was NOT executed agent-side**; the seven historical rows were recomputed by hand per the standard's § 7 manual-fill fallback rather than by re-running the tool. | The tool is absent from the operator's script-execution allowlist, so `BLOCK-DESTRUCTIVE-022` blocks every agent-side invocation including `bash -n`. Its sibling tools are registered; this one was never added. Surfaced as a user-side handoff rather than worked around — no allowlist edit, no bypass. `automated-closeout.sh --self-test` (registered) DID run and covers the phase-side change end to end. |

---

## Issue References

The label-to-number binding for this release. Every card above is named by its durable label; this block is the single place the numbers live, so the plan body survives renumbering and a reader still resolves scope without leaving the file.

| Label | Card | Summary |
|---|---|---|
| `FIX-CHOREPR` | #4322 | The Gate-Passage-Proof chore-PR field renders its number twice when the variable is set |
| `FIX-OUTCOMEKEY` | #4222 | The Outcome field is re-injected under a qualified key; settle the permitted-key grammar once |
| `FIX-PREFLIGHT` | #5066 | The Phase-A7 learnings precondition fails eight phases into the close-out, after seven have written |
| `FIX-VELOCITY` | #4927 | Velocity is computed from close state before the membership is closed, so a release books zero delivered |
| `BLD-OUTPUTSET` | #5288 | The close-out cannot assert its own required-output set before it commits |
| `DROP-EMITORDER` | #5188 | Removed from this release — closed not-a-defect at Collective Review |
| Stage-4 planning sub-task | #5709 | Carries the approved Stage-4 plan and the plan-review decision record |
| Milestone | `closeout-reports-what-shipped` | The release milestone this plan implements |
