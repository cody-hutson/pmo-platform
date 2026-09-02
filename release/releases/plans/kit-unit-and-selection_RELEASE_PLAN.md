<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Release Plan — kit-unit-and-selection
purpose: Stage-4 release plan for the five kit-unit-and-selection members — a work-item kit becomes a first-class, archetype-neutral, kind-bearing unit a deployment selects independently of the methodology it runs.
type: release-plan
plan_type: release
status: ACTIVE
reversibility: EXPENSIVE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---

# Release Plan: kit-unit-and-selection — A Work-Item Kit Is a First-Class, Selectable Unit

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim. Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against tags, published Releases and ledger rows; anchor tag **v4.45**, recomputed next-free **v4.46**, free at Commit 0 (no tag, no `RELEASE_LOG` row at `origin/main`, no `plans/v4/` file). |
| **Date Created** | 2026-09-01 (Tuesday) |
| **Commit-0 Date** | 2026-09-01 (Tuesday) — the resolution instant for every load-bearing date this release writes |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/kit-unit-and-selection` |
| **PR** | opened as a DRAFT at the first Engineering spoke's commits; the release ships as a SINGLE PR with one merge gate, transitioned to ready-for-review at the Stage 9 gate |
| **Milestone** | `kit-unit-and-selection` (#371) |
| **Release Class** | `cross-cutting` — re-classified at the Stage-4 plan gate (D-ReleaseClass) from `novel` |
| **Composition** | keystone bundle; single connected dependency component (6 edges over 5 nodes) |
| **Effective points** | **39** — 30 raw × `cross-cutting` weight 1.3, against a 15–25 band. **Over ceiling, dispositioned (C) keep-with-rationale by the operator.** Two independent changes each crossed it: the class re-classification (22 × 1.3 = 29) and #6361's L → XL re-estimate absorbing the meta-schema validator (30 × 1.3 = 39). Splitting is rejected on the dependency graph's own algorithm: the component is connected, so every sub-slice immediately depends on another and a split buys ceremony without isolation. Accepted oversize; reversibility MODERATE, confidence HIGH. |
| **Branch topology** | **SINGLE** (D-C) — one branch, one PR, one merge gate; this plan lands as Engineering Commit 0 |
| **Concurrency posture** | **P0 fully-serial** (D-Concurrency Posture). One Engineering chip at a time in Implementation Sequence order; the next chip waits until the prior commit lands on the release branch. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `539c4440fc1457e8d42d2bbe11c7be663baf596f` — the pinned baseline; every Engineering spoke branches from it |

**Stamp manifest.** The `**Version**` cell above is a machine-read manifest, not prose. It carries the literal `{{RELEASE_VERSION}}` token, which the Stage-12 claim resolves at the merge SHA while renaming this file to `release/releases/plans/v4/vX.Y_RELEASE_PLAN.md`. Asserted read-only at Commit 0 by `release/tools/claim-version.sh --verify-stamp kit-unit-and-selection`; a plan that fails that assertion is never committed, because Stage 12 could then neither resolve the version nor complete the rename.

## Release Outcome Statement

**AFTER** — a deployment declares and selects a work-item kit independently of the methodology it runs; the kit types work at the **Work-Item level** and **projects onto** every organizational level a rollup traverses, introducing no entity at any of them. The full impact chain of the change is mapped before the grammar moves.

**BEFORE** — kind-bearing is welded to archetype identity — a kind-bearing pack must name exactly one archetype, and the methodology-neutral value is reserved for packs that cannot bear kinds. A cross-methodology kit is not expressible. The grouping/execution distinction has no grammar carrier, so a rollup's traversal is invisible to the type system and enforcement falls back to hardcoded literals.

> **Amended 2026-09-01 (Tuesday) at Collective Review (D-OutcomeAmend).** Both clauses previously encoded a mechanism the Stage-5 design **overturned** — that a kit types container tiers directly, and that Work-Item-level anchoring is the defect. Verified: the meta-schema fixes `base` as `const "Work Item"` with *"No other base permitted"*, and `project-entity-model.md` is the FROZEN entity substrate, so a kind at Portfolio / Program / Project would be the very "new entity node" #6381's own AC-2 forbids. Work-Item-level typing is structurally mandatory, not a shortcoming. The real gap, measured: `general_level` is read by **0 of 241** repo executables while its own schema row calls a non-`Work Item` value *"a modeling smell to flag"*, and the grouping/execution distinction has no grammar carrier while live enforcement hardcodes the literal `type:epic` in **6** executables. Amended rather than annotated because the Outcome Statement is the acceptance frame Stage 13's 30-day outcome window grades against; a stale frame mis-grades the release. Card bodies remain untouched as historical record.

## Release Class

Class: **`cross-cutting`**

Re-classified 2026-09-01 (Tuesday) at the Stage-4 plan gate (D-ReleaseClass), from `novel`. Multi-trigger resolution takes the highest-ceremony class: `cross-cutting` > `novel` > `routine`.

| Class | Trigger | Fires? | Evidence |
|---|---|---|---|
| `novel` (a) | ≥1 issue introduces a new reference doc / schema / skill | YES | #6360 adds an ADR; #6377 adds the consumer map |
| `novel` (b) | ≥1 D-class decision in the release plan | YES | D-Version, D-ReleaseClass, D-Concurrency Posture, plus the two placement D-decisions |
| `novel` (c) | ≥1 Stage 5 ADR | YES | #6360 *is* the founding ADR |
| `cross-cutting` (a) | matrix changes ≥3 pipeline stage specs | NO | 0 |
| `cross-cutting` (b) | matrix changes ≥3 of the 6 rule-defining governance surfaces | NO | 0 of 6 |
| `cross-cutting` (c) | ≥3 in-bundle compositional edges | **YES — 6 edges over 5 nodes** | the Stage-4 A2 DAG; robust to the one card-absent edge (5 still clears 3) |

Differentiation delta is narrow and was verified against the dimension table: only **engagement density** moves (Standard → **Tight**). Stage 9 review depth (Deep), Stage 5 activation bias (ALL) and the Stage 13 outcome window (30-day) are identical across the two classes. The consequential change is the **capacity weight** (1.15 → 1.3), recorded in the Header.

**Additive-landing premise, as corrected.** The release does **not** land as "one optional add plus one relaxation." The real shape is **4 adds + 1 relaxation + 1 restriction**, and the meta-schema grammar version stays **v1**. The full enumeration and its grounding are in § Backward-Compat Landing below; the correction is recorded here because Release Class rests on it.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Layer | Size | Stage 5 |
|---|-------|---------------------|-------|------|---------|
| 1 | #6360 | Decide the work-item kit as a first-class unit — founding ADR | foundation | S (2) | APPLIED |
| 2 | #6377 | Map the full link and blast-radius chain | foundation | M (4) | APPLIED |
| 3 | #6361 | Make a work-item kit expressible in the pack grammar | infrastructure | XL (16) | APPLIED |
| 4 | #6362 | Select a work-item kit through the configuration cascade | infrastructure | M (4) | APPLIED |
| 5 | #6381 | Cover every organizational level in the kit, portfolio down | infrastructure | M (4) | APPLIED |

**Total 30 raw points.** #6361 was re-estimated L → XL at the Stage-4 plan gate when it absorbed the meta-schema validator; this is a Stage-4 scope absorption, not a Triage re-estimate.

### Composition Lock

**Locked at:** Stage 4 Planning entry · 2026-09-01 · planning sub-task #6447. Membership **5 in / 5 out**, unchanged. `issues_added` MUST be **0** for the remainder of the release. Work that does not fit an existing member routes to a next bundle and is surfaced, never filed. The lock was enforced once already: a proposed re-home of #6371 into this milestone was **not performed**; the intent was satisfied instead by per-issue scope refinement on #6361, which is explicitly outside what the lock binds.

### Scope-lock (Collective Review)

Scope **LOCKED** at Collective Review, 2026-09-01 (Tuesday): 5 of 5 Solutioning PASS, membership unchanged. Six decisions were rendered; the ones that bind Engineering are carried in § Ratified Corrections below.

## Ratified Corrections Engineering Carries

These are operator-rendered decisions and independently-verified findings that change what Engineering builds. They are recorded here because a spoke reading only its own Stage-5 comment would build the superseded shape.

**D-CarryFindings — the independent adversarial review's findings carry into Stage 6; Stage 5 is NOT re-opened.** Two of them land on this release's foundation cards and are restated in full:

- **`kit_class` generality was overclaimed (falsified).** The Stage-5 design for #6360 claimed the second-kit-class problem was discharged *"by construction, not by promise"* by conditioning facet requiredness on `kit_class`. Its own downstream rule set conditions requiredness on `role` instead — `kinds` required iff `role ∈ {archetype, kit}`, unconditionally for every kit — so a `field` or `workflow` kit declaring no work-item kinds is hard-rejected and the second class costs a grammar re-open. A second symptom of the same root: the `kit_class` value domain is declared OPEN with an unknown class yielding a caveat rather than an error, but the `role`-conditioned `kinds` rule rejects that same pack on a different rule, so the open domain is unreachable as written. **Resolution taken at Stage 6:** ADR-170 states the requiredness rule as a two-level rule — forbidden on `base`, required on `archetype`, and on `kit` **selected by `kit_class`** — and the grammar edit implements it. Detail in § Backward-Compat Landing.
- **The empty-vocabulary premise was falsified by execution (D-EmptyKitRetire).** The premise that "a deployment selecting a kit and licensing no archetype pack resolves to an empty vocabulary and exits 3" is false: a conforming kit is mandatorily kind-bearing, so a kit-only root resolves the kit's own kinds. Executed against the shipped reader at Commit 0 — a kit-only pack root emits its kind and exits **0**; the sensitivity arm (a root whose only pack declares no kinds) exits **3**, so the detector is live; the control arm (the repo root) emits four kinds and exits 0, so the reader is live. **D-EmptyKit is RETIRED by supersession.** No empty-vocabulary constraint is carried into ADR-170. The replacement constraint is identified at Stage 6 by #6362, whose criterion inherited the false predicate.

**D-CompatShape — the corrected backward-compat shape.** Recorded in full in § Backward-Compat Landing. The decision (grammar stays **v1**; additive in effect on shipped packs) is unchanged; only the arithmetic and the restriction axis moved.

**D-MapHome** — the consumer map lands at `core/references/reference/work-item-type-consumer-map.md`. Settled; not relitigated.

**D-FixtureHome** — every fixture pack this release introduces lives under `core/deploy/tests/fixtures/packs/`, **never** under `core/packs/`. The ground is structural, not stylistic: the licensed-kind reader unions `kind_id` rows from any directory under `core/packs/` holding a `pack.toml`, with no allowlist, no naming filter and no underscore-prefix skip, so a fixture inside that tree is silently absorbed into the production gate's vocabulary.

**D-ReadmeSplit + CR-1** — section ownership on `core/packs/README.md`, which three cards name in their acceptance criteria. #6361 owns `## The role and extends model` **plus** the head matter, the H1 and `## Layout`; #6362 owns a new `## Kit selection and precedence`; #6381 owns `## What lives where`. Waves are serial and the release ships as one PR, so this is sequencing, not conflict — but the last writer would otherwise inherit all three obligations blind.

**D-Instrument** — the `SCANNED_TYPES` fix adding `py` to `release/tools/blast-radius.sh` lands as Stage-6 scope on #6377. Two action items are hard-gated at close: the fix MUST ship with a self-test arm exercising at least one `.py` reference under a RED→GREEN assertion (the current suite passes identically patched and unpatched, so shipping the one-line fix alone would re-create the gate-that-cannot-fail class this card exists to document); and `core/deploy/tools/domain-blast-radius.sh` MUST NOT be extended — it already carries `py` and its blindness is architectural, not a type-list omission.

## Backward-Compat Landing

The meta-schema grammar version stays at **v1**. The change is **4 adds + 1 relaxation + 1 restriction**, and the set — not a literal count — is what the grammar's own extension note records, because the population closed one wave after the count was first written.

**Adds (4), all optional; a pack declaring none is byte-identical to a pre-change pack:**

| # | Add | Owner |
|---|---|---|
| 1 | the `kit` member of the `role` enum | #6361 |
| 2 | the `kit_class` field, required iff `role = "kit"` | #6361 |
| 3 | the `"*"` value in the `methodology_projection.archetype` domain | #6361 |
| 4 | the `methodology_projection.level_role` field | #6381 |

**Relaxation (1), asymmetric on the forward axis:** `extends` widens from permitted only on `role = "archetype"` to permitted on `role ∈ {archetype, kit}`. An old validator asserting `extends ⇒ role == "archetype"` would reject a now-valid kit pack. Currently theoretical and measured: **0 of 241** tracked executables validate against the meta-schema, and the validator this release builds is kit-aware from the start rather than retrofitted.

**Restriction (1) — the one shape that can invalidate a previously-valid pack:** `applies_to = "*"` becomes **illegal** on `role = "archetype"`. It is legal today; the role-conditional constraint is one-directional (a `base` pack MUST set `*`) and nothing binds archetype packs. The consequence is bounded by measurement rather than assertion: **0 of 3** shipped packs combine `role = "archetype"` with `applies_to = "*"` — `_common` is `role = base` (which must be `*`, unaffected), `kanban` is `Kanban`, `scrum` is `Scrum`. Control arm live at Commit 0 (`role = base` with `*` → 1), specificity arm 0, so the zero is real and the byte-identity guarantee for the shipped packs holds.

**Restate as: additive in effect on shipped packs, not purely additive in grammar.** The restriction closes a door no shipped pack walked through. The residual is named rather than dismissed: pack *instances* are operator-local configuration by design, so the repo is not the whole population — the restriction ships with zero enforcing validators today, and the grammar's own extension note states the restriction axis explicitly so an adopting deployment reads it before it bites.

**The count was corrected, not the decision.** The fourth add (`level_role`) entered in wave 3, one wave after the shape was recorded at three. A bucket assignment ("it lands in the ADD bucket") was conflated with a count ("the count is unchanged") at that handoff. The obligation this places on #6361 is to **enumerate the ADD set rather than total it**, and to carry `level_role` as a named member.

## Implementation Sequence

Stage-6 Engineering is **P0 fully-serial**. The order below is the authoritative Stage-6 dispatch order.

**#6360 → #6377 → #6361 → #6362 → #6381**

| Position | Issue | Pts | Rationale |
|---|---|---|---|
| 1 | **#6360** | 2 | In-degree 0. The founding ADR every downstream acceptance criterion cites. Lands Engineering Commit 0 (this plan). |
| 2 | **#6377** | 4 | In-degree 0 and genuinely independent of #6360 — neither names the other on any surface. Gates #6361 **and** #6362; the map must exist before the grammar moves. |
| 3 | **#6361** | 16 | The single structural change: the grammar, the validator, the fixture home convention. Every remaining member resolves against it. |
| 4 | **#6362** | 4 | Consumes the grammar. Placed before #6381 to take `core/packs/README.md` first under serial file contention. |
| 5 | **#6381** | 4 | Last writer on `core/packs/README.md`. Its rules ride #6361's validator mode rather than adding an argv branch. |

**Parallel-eligible sets (Stages 5 / 7 / 8 only — coordination semantics, not usage-window semantics):** wave 1 `{#6360, #6377}` · wave 2 `{#6361}` · wave 3 `{#6362, #6381}`. **Stage 6 remains serial regardless of wave.**

## Stage Applicability Matrix

| Issue | S5 | S6 | S7 | S8 | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|
| #6360 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #6377 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #6361 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #6362 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #6381 | YES | YES | YES | YES | YES | YES | YES | YES | YES |

**No stage skips for any member, and each YES rests on positive evidence rather than on default.** #6360's Stage 7 applies because the ADR durability and ADR numbering checks are executable and fire on a new `core/ADRs/ADR-*.md`. #6377's applies because the map is durable corpus subject to doc-link and reference-durability checks, and because its blast-radius fix carries a RED→GREEN self-test arm. #6361 / #6362 / #6381 each carry predicate-form criteria with declared fixture methods that Stages 7 and 8 grade. Nothing here is documentation-only, so the no-functional-impact skip is unavailable to any member.

**Parallel-eligible spoke count per parallel stage:** Stage 5 = 5 · Stage 7 = 5 · Stage 8 = 5.

## Contention Map

| Surface | Writers | Order | Handling |
|---|---|---|---|
| `core/packs/README.md` | #6361, #6362, #6381 | serial per sequence | D-ReadmeSplit + CR-1 assign disjoint sections. Each chip re-reads the file at checkout rather than patching from a stale copy. CIAC-2 grades the merged end state. |
| `core/schemas/work-item-type-schema.md` | #6361, #6381 | serial per sequence | #6361 authors the role / `applies_to` / `extends` / `kinds` / `kit_class` / archetype-domain edits and the extension note; #6381 adds `level_role` inside the existing projection object and is recorded in the ADD set. CIAC-4 grades that no parallel level enum is minted. |
| `core/deploy/tools/check-work-hierarchy.py` | #6361, #6362, #6381 | serial per sequence | #6361 authors both new argv branches; #6362's and #6381's rules **ride** them and add no third branch. The H1/H2 finding set and the existing kind-emit output stay byte-identical, asserted by a regression arm. |
| `operations/skills/intake-desk/references/type-map.md` | #6361, #6381 | serial per sequence | Disjoint lines by assignment: #6361 owns the rung-2 join; #6381 owns the hierarchy-level statement. |
| `core/deploy/tests/fixtures/packs/` | #6361, #6362, #6381 | serial per sequence | #6361 establishes the layout convention (one directory per fixture, root-parameterized read); the other two extend it. CIAC-5 grades the single-home constraint. |

## File Change Matrix

```
# ── #6360 — founding ADR ──
core/ADRs/ADR-170-work-item-kit-first-class-unit.md                       add

# ── #6377 — consumer map + instrument fix ──
core/references/reference/work-item-type-consumer-map.md                  add
release/tools/blast-radius.sh                                             edit

# ── #6361 — the grammar, the validator, the fixture home ──
core/schemas/work-item-type-schema.md                                     edit
core/packs/README.md                                                      edit
core/deploy/tools/check-work-hierarchy.py                                 edit
core/deploy/tools/README.md                                               edit
core/deploy/deploy.sh                                                     edit
operations/skills/intake-desk/references/type-map.md                      edit
core/deploy/tests/fixtures/packs/conforming-kit/pack.toml                 add
core/deploy/tests/fixtures/packs/nonconforming-kit/pack.toml              add

# ── #6362 — selection through the cascade ──
core/config/operator.toml.template                                        edit
core/config/operator-toml-schema.json                                     edit
core/schemas/project-schema.md                                            edit
core/schemas/platform-config-schema.md                                    edit
docs/platform-config-reference.md                                         edit
core/deploy/tests/fixtures/packs/sel-common/pack.toml                     add
core/deploy/tests/fixtures/packs/sel-scrum/pack.toml                      add
core/deploy/tests/fixtures/packs/sel-kanban/pack.toml                     add
core/deploy/tests/fixtures/packs/sel-kit-alpha/pack.toml                  add
core/deploy/tests/fixtures/packs/sel-kit-beta/pack.toml                   add
core/deploy/tests/fixtures/packs/sel-kit-gamma/pack.toml                  add
core/deploy/tests/fixtures/packs/sel-k4-override/pack.toml                add

# ── #6381 — level coverage ──
core/deploy/tests/fixtures/packs/rollup-kit/pack.toml                     add
core/deploy/tests/fixtures/packs/tier-claiming-kit/pack.toml              add
core/deploy/tests/fixtures/packs/nested-grouping-kit/pack.toml            add

# ── Release-wide explicit non-scope ──
core/packs/_common/pack.toml                                              NOT EDITED
core/packs/scrum/pack.toml                                                NOT EDITED
core/packs/kanban/pack.toml                                               NOT EDITED
core/ADRs/README.md                                                       NOT EDITED
core/deploy/tools/domain-blast-radius.sh                                  NOT EDITED
```

### Read-only inputs

```
core/disciplines/project-entity-model.md                                  READ
core/schemas/entity-field-schemas.md                                      READ
core/ADRs/ADR-018-work-item-type-layer.md                                 READ
core/ADRs/ADR-069-methodology-pack-composing-unit.md                      READ
core/ADRs/ADR-070-methodology-pack-composition-grammar.md                 READ
core/ADRs/ADR-077-cross-cutting-control-field-layer.md                    READ
core/deploy/tools/check-label-parity.py                                   READ
core/governance/OPERATIONS.md                                             READ
```

**Notes binding the matrix.**

- **Both Stage-4 CONDITIONAL blocks are PROMOTED at this commit**, carrying their concrete paths. `CONDITIONAL:map-placement-d-decision` resolved to `core/references/reference/work-item-type-consumer-map.md` (D-MapHome). `CONDITIONAL:fixture-home-d-decision` resolved to `core/deploy/tests/fixtures/packs/` (D-FixtureHome), and the three placeholder fixture rows the Stage-4 matrix carried under `core/packs/tests/fixtures/` are superseded by the twelve concrete fixture rows above. Leaving a row CONDITIONAL after its condition has fired is an authoring defect, so the promotion happens here rather than being deferred.
- **The three shipped-pack `NOT EDITED` rows are load-bearing, not decoration.** #6361's byte-identity criterion asserts them; the widened role enum leaves each pack's existing `role` value correct and its kinds archetype-keyed by design.
- **`core/ADRs/README.md` is NOT EDITED, and that is a determination rather than a drop.** The Stage-5 design listed an index-row edit there. That file states in its own text that it is a curated thematic document and **not** an index, that it has never enumerated the module's full record set, and that it must not be converted to a generated index — the authoritative complete list is the file set itself, whose contiguity CI enforces. The Stage-4 plan reached the same conclusion independently from the index generator's scope block. Adding an enumeration row would create the second hand-maintained surface that file exists to refuse.
- **`core/deploy/tools/domain-blast-radius.sh` is NOT EDITED** (D-Instrument / AI-002). It already carries `py` as the first element of its scanned-type list; its blindness is architectural — a shell subprocess is never an import edge — so no type-list edit reaches it.
- **`core/governance/OPERATIONS.md` is READ, not edited, by design.** #6362's criterion requires resolution through the *existing* five-rung cascade and asserts no parallel resolution path is introduced, so the resolver is consumed and never modified. An edit appearing here at Engineering would be evidence the criterion was violated.
- **No new executable script is added**, so the script-execution allowlist companion obligation does not fire. The new deploy check is registered inside the existing script; the validator modes extend an existing tool, adding no new advertiser to the self-test coverage manifest.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-01, domain: governance }`

Sourcing-exempt — every matrix path is an internal pmo-platform artifact (schema, pack grammar, config template, ADR, deploy tooling, release tooling) — and domain-classified `governance`. No secondary domain: there is no application source and no product-facing code in the matrix.

## Risk Register

| ID | Risk | Sev | Root cause | Mitigation (owner) | Reversibility |
|---|---|---|---|---|---|
| **R-1** | **RETIRED at the Stage-4 plan gate.** #6361's first criterion named a meta-schema validator that did not exist, making it ungradable | — | The criterion was authored against a capability the roadmap sequenced after it | #6361 absorbed the validator as its sixth criterion (L → XL). The criterion is now gradable in-release and the deferral is withdrawn (Stage 4 / operator) | CHEAP |
| **R-2** | **#6381's dependency on #6361 is declared nowhere on either card** — milestone-description-only. An actor reading the cards alone would see #6381 as unblocked | MED | Bundle-level sequencing recorded in the milestone description, never mirrored to the card surface | Carried explicitly in the Implementation Sequence above, which is the authoritative order. Serial Stage-6 dispatch makes the edge unviolatable in practice (Stage 4 / operator) | CHEAP |
| **R-3** | **RESOLVED.** Two placement decisions were unresolved at plan time — the map's home and the fixture home | — | Neither card named a path at intake | Both rendered at Collective Review (D-MapHome, D-FixtureHome) and promoted into the matrix above. CIAC-3 and CIAC-5 grade the resulting single-home constraints (Stage 4 / operator) | CHEAP |
| **R-4** | **Rollback is release-atomic, not per-issue — keystone amplification.** Five downstream milestones resolve against this bundle's definition of a kit; #6362 and #6381 are meaningless without #6361, and #6361 is meaningless without #6360's ADR | HIGH | Structural: the bundle ships one definition and four consumers of it, on a single PR under milestone-one-PR discipline | Revert is whole-PR and that is the correct granularity — do not attempt a partial revert. The compensating control is front-loaded: the consumer map is inside the bundle and gates the grammar change. Deep Stage 9 review (Stage 9) | **EXPENSIVE** |
| **R-5** | **`core/packs/README.md` takes three sequential writers.** The last writer sees a file two prior chips have reshaped | MED | 3-way single-file contention under P0 serial Engineering | D-ReadmeSplit + CR-1 assign disjoint sections; each chip re-reads at checkout. CIAC-2 grades the merged end state for mutual consistency (Stage 6 / Stage 9) | CHEAP |
| **R-6** | **The licensed-kind reader silently widens its vocabulary.** It walks every directory under `core/packs/` and unions declared kinds into the SSOT vocabulary; a fixture pack placed there would be absorbed into the live gate's vocabulary | MED | The consumer discovers packs by directory enumeration, not by an explicit registry; it cannot distinguish a shipped pack from a fixture | D-FixtureHome places every fixture outside `core/packs/`, so the union structurally cannot absorb them. Optional hardening (an explicit skip rule in the union) is flagged for a next bundle, not filed (Stage 6 / #6361) | MODERATE |
| **R-7** | **Bundle is over band at 39 effective points against a 25 ceiling** | MED | Two independent changes each crossed it; the component is connected so a split does not isolate | Dispositioned (C) keep-with-rationale by the operator; recorded as a breach carried, not a bound satisfied. The split-by-sub-capability arm remains available at Stage 9 if the bundle proves unwieldy (Stage 4 / operator) | MODERATE |
| **R-8** | **A sibling milestone's parity-gate hardening lands against a moved target.** #6361 changes what a pack-declared kind means; #5291 hardens the gate that validates it, from a different milestone | LOW | Cross-milestone sequencing, correctly recorded as coordination | Coordination-only: the gate stays permissive through this release, so nothing breaks in flight. #5291 reads the post-#6361 definition when it hardens (Stage 13 / #5291's own release) | CHEAP |
| **R-9** | **Five designs deep with no structurally independent review, and the one independent pass that finally ran falsified three premises three prior verification passes had confirmed** | HIGH | No independent-reviewer agent definition exists in this deployment, so every Stage-5 adversarial pass was self-administered; and one hub verification confirmed a constraint by checking that a line of code existed rather than by exercising it | The independent pass ran before Stage 6 (CR-3) and its findings are carried in § Ratified Corrections. The durable mitigation is the conduct rule the release paid for: **existence is not exercise** — a behavioral claim is verified by running it, and every null result carries a control arm that must fire (Stage 6 / every spoke) | MODERATE |

## Cross-Issue Acceptance Criteria

Five criteria. Each spans ≥2 issues, names a shared surface, and is graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 (#6360 × #6361 — the meta-schema version claim on two surfaces):** the backward-compat landing analysis recorded in the founding ADR and the meta-schema's own extension note **agree that the grammar version is unchanged** — one claim, two surfaces, no divergence. *Method:* `grep -n "stays at v1\|stays v1\|version is unchanged\|grammar version" core/schemas/work-item-type-schema.md core/ADRs/ADR-170-work-item-kit-first-class-unit.md` and confirm both assert retention and neither asserts a bump; sensitivity arm — the same probe over the pre-change schema must return the existing extension-note hits, so a zero on the new note is distinguishable from an unresolvable path.

- [ ] **CIAC-1b (#6360 × #6361 × #6381 — the ADD set is enumerated, not totalled):** the extension note enumerates the **four** optional adds by name, `level_role` among them, rather than stating a literal count that closed one wave early. *Method:* `grep -c "level_role" core/schemas/work-item-type-schema.md` returns non-zero inside the extension note's own section body; control arm — `grep -c "kit_class" core/schemas/work-item-type-schema.md` returns non-zero on the same file with the same instrument, so a zero on `level_role` is a real absence and not a dead pattern.

- [ ] **CIAC-2 (#6361 × #6362 × #6381 on `core/packs/README.md`):** the three obligations landing in this one file — pack **composition order**, **kit-vs-override precedence**, and **the kit types the work and does not redefine the tiers** — are all present and **mutually non-contradictory** after the last writer, in the sections D-ReadmeSplit + CR-1 assign. *Method:* `grep -nE "composition order|precedence|does not redefine" core/packs/README.md` returns ≥3 distinct obligation statements in ≥3 distinct sections; a reviewer confirms no statement negates another.

- [ ] **CIAC-3 (#6377 × #6361 × #6362 on the consumer map):** the map is **cited by the acceptance of both consuming stories** — a map nothing cites is the failure mode the card was written to prevent. *Method:* `grep -rn "work-item-type-consumer-map" core/schemas/work-item-type-schema.md core/packs/README.md core/ADRs/ADR-170-work-item-kit-first-class-unit.md` returns ≥1 hit from the grammar surface and ≥1 from the selection surface.

- [ ] **CIAC-4 (#6361 × #6381 on `core/schemas/work-item-type-schema.md`):** #6381's level coverage **reuses the existing level vocabulary** already declared for the controls facet and introduces **no second, parallel level enum**. *Method:* null-expecting, so it carries its arms — `grep -cE '^\s*levels\s*=' core/schemas/work-item-type-schema.md` counts level-enum declaration sites; expect the pre-existing count with no new distinct enum literal set · control: `grep -c 'Portfolio' core/schemas/work-item-type-schema.md` returns a **non-zero** count on the same file with the same instrument, proving the path resolves and the pattern class matches before the null is believed.

- [ ] **CIAC-5 (#6361 × #6362 × #6381 on the fixture home):** all fixtures introduced by this release live under **exactly one** home — no issue mints a parallel fixture tree. *Method:* enumerate every `add` row in the File Change Matrix above whose path contains `fixture`; assert every such path shares the common parent `core/deploy/tests/fixtures/packs/` · control: assert the same enumeration over `core/packs/` returns **0** rows while a probe for `core/packs/` paths anywhere in the matrix returns non-zero, so the zero is a measured absence rather than an unresolvable pattern.

## Verification Plan

**AC baseline, re-read at Engineering Commit 0 against `539c4440`:** #6360 → **5** criteria · #6377 → **6** · #6361 → **6** · #6362 → **5** · #6381 → **6**. **Total 28.**

**The baseline moved from the Stage-4 figure and the move is recorded rather than absorbed.** Stage 4 recorded #6361 at 5 criteria for a total of 27; the live count is 6 for a total of 28. The sixth criterion is the meta-schema validator #6361 absorbed at the Stage-4 scope re-estimate (L → XL) — the same absorption the Header records as one of the two changes that took the bundle over band. The baseline is a pinned measurement carrying no verdict; a criterion count that no longer matches it is a mechanical signal to re-bind, and this is that signal being acted on rather than left for a later stage to discover.

Instrument: `grep -c "^- \[ \]"` over each issue body, read through the REST issues endpoint. Extraction was non-empty for every card (5 / 6 / 6 / 5 / 6, none zero).

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #6360 | AC-1 | `grep -nE "^### D1\|^### D2" core/ADRs/ADR-170-work-item-kit-first-class-unit.md` — the ADR records how a kit bears kinds without naming an archetype (the role decision and the kind-level neutral sentinel are separate, non-severable sub-decisions) and how it composes with a methodology pack | Both decision headings present; the composition order appears in the same record |
| #6360 | AC-2 | `grep -n "five-rung\|cascade" core/ADRs/ADR-170-work-item-kit-first-class-unit.md` — the binding model names what a project selects and how kit selection resolves relative to the methodology selection and to project-level overrides | ≥1 hit stating selection rides the existing cascade with no parallel resolver, and stating the precedence order |
| #6360 | AC-3 | `grep -nE "4 adds\|four .*adds\|relaxation\|restriction" core/ADRs/ADR-170-work-item-kit-first-class-unit.md` — the additive-landing analysis is recorded on both backward-compat axes, per the precedent that kept the meta-schema at v1 through two prior extensions | The add set enumerated (4, `level_role` named), the relaxation grounded separately, and the restriction recorded with its measured 0-of-3 impact |
| #6360 | AC-4 | `grep -n "kit_class" core/ADRs/ADR-170-work-item-kit-first-class-unit.md` — extensibility to a second kit class is addressed explicitly, either designed in or ruled out with a reason. Graded against the carried correction: a claim of generality is graded NOT MET unless the requiredness rule the ADR states is conditioned on `kit_class` for `role = "kit"` | The two-level requiredness rule stated; the cost of a second class named; no unconditioned-on-`role` generality claim survives |
| #6360 | AC-5 | `grep -rn "ADR-170" core/schemas/work-item-type-schema.md core/packs/README.md` — the ADR is referenced by the grammar and selection stories in this epic. Null-expecting on neither arm; control: `grep -rn "ADR-070" core/schemas/work-item-type-schema.md` returns non-zero on the same instrument, so a zero is a real absence | ≥1 citation from the grammar surface and ≥1 from the selection surface · control non-zero |
| #6377 | AC-1 | `grep -nE "^## Read paths" core/references/reference/work-item-type-consumer-map.md` plus a row count of that section's table — every read path of the type system is enumerated with its discovery method | The read-path section present with a row per enumerated consumer; each row names its path and method |
| #6377 | AC-2 | `grep -nE "^## Create / update / delete paths" core/references/reference/work-item-type-consumer-map.md` — create, update and delete paths are enumerated with their execution locus | The CRUD section present; each row names its locus |
| #6377 | AC-3 | `grep -nE "^## Flows beyond this repository" core/references/reference/work-item-type-consumer-map.md` — data flows leaving the repository are enumerated with their exclusion state | The flows section present with the exclusion column populated |
| #6377 | AC-4 | `grep -nE "^## First-order vs second-order impact" core/references/reference/work-item-type-consumer-map.md` — first- and second-order impact are distinguished and keyed to the grammar relaxation | Both tables present and keyed to the relaxation |
| #6377 | AC-5 | `grep -nE "^## Named breakages" core/references/reference/work-item-type-consumer-map.md` — consumers that would break under a decoupled kind unit are named. Graded against the carried correction: the section carries **two** rows, not one, because the higher-precedence rung of the same consumer carries a second archetype-scoped join expressed in prose rather than in the token the original probe searched | ≥2 breakage rows, each naming its rung and its failure mode; the blind-spot section states that a token census cannot see a join expressed in prose |
| #6377 | AC-6 | Tree-resident anchor the executor can run: `grep -c '"py"' release/tools/blast-radius.sh` — the scanned-type list carries the Python entry, and the self-test region carries at least one assertion naming a `.py` reference. The RED→GREEN arm itself is run at Stage 6 and re-run at Stage 7 as `bash release/tools/blast-radius.sh --self-test`, which this executor declines by verb allowlist and reports as an honest skip rather than a fabricated pass | Anchor **≥ 2** — the type-list entry plus the self-test fixture reference · assertion count strictly greater than the pre-change 36, all passing · the new arm observed failing on the unpatched instrument, so the green is falsifiable |
| #6361 | AC-1 | Tree-resident anchor the executor can run: `grep -c 'archetype = "\*"' core/deploy/tests/fixtures/packs/conforming-kit/pack.toml` — the conforming fixture asserts neutrality at the **kind** level, not only at the pack level, because a change relaxing only the pack-level field would validate a kit whose every kind is still archetype-welded and the capability would be absent. The behavioral arm is run at Stage 6 and re-run at Stage 7 as `python3 core/deploy/tools/check-work-hierarchy.py --validate-packs --pack-root core/deploy/tests/fixtures/packs/conforming-kit` | Anchor **≥ 1** · exit 0 with the kit's kinds accepted · the mutation arm removing kind-level neutrality rejected under its own rule identifier and no other |
| #6361 | AC-2 | `grep -nE "composition order" core/packs/README.md` — the unit composes with a methodology pack and the README documents the composition order | The order documented as base → archetype pack(s) → kit → project override, most-specific-wins, field-level merge |
| #6361 | AC-3 | Regression, unchanged-files-intact: the three shipped packs are byte-identical to their pre-change state and still validate. Probe: `git diff --stat origin/main -- core/packs/_common/pack.toml core/packs/scrum/pack.toml core/packs/kanban/pack.toml`. Null-expecting, so it carries its arms · control: the same command over `core/schemas/work-item-type-schema.md` returns a non-zero diffstat on the same instrument, proving the comparison resolves | **Empty diffstat** for all three · control non-zero · all three accepted by the validator |
| #6361 | AC-4 | `grep -nE "6\.2c\|landing analysis" core/schemas/work-item-type-schema.md` — the change lands additively with the grammar version unchanged and the analysis recorded in the founding ADR. Graded as restated by the ratified correction, not as literally worded: the criterion's "one optional add plus one relaxation" is historical | The extension note present, enumerating **4 adds + 1 relaxation + 1 restriction**, version retained at v1, citing ADR-170 |
| #6361 | AC-5 | `grep -nE "as-is\|left as-is" core/packs/README.md` — each shipped pack is either migrated or explicitly left as-is with the reason stated alongside it | Three as-is rows, each carrying the reason that the widened enum leaves its existing role value correct and its kinds archetype-keyed by design |
| #6361 | AC-6 | Tree-resident anchor the executor can run: `grep -c "PACK-P0" core/deploy/tools/check-work-hierarchy.py` — the validator exists in the tree and emits per-rule identifiers, so its arms are attributable rather than a bare exit code. The suite itself is run at Stage 6 and re-run at Stage 7 as `python3 core/deploy/tools/check-work-hierarchy.py --self-test`, with both arms required: accept the three shipped packs, reject the deliberately-nonconforming fixture, and **each mutation arm asserts its own rule identifier and the absence of every other**, so a dead rule fails an arm instead of riding a green suite | Anchor **≥ 1** · suite green with the arm count strictly greater than pre-change · every rule identifier exercised by at least one arm that fails when its rule is mutated |
| #6362 | AC-1 | `grep -n "work_item_kit" core/config/operator.toml.template core/config/operator-toml-schema.json` — a deployment declares a global default kit through operator configuration, schema-registered on both surfaces | The field present in the template's methodology table and as a schema key entry; absence documented as a valid state |
| #6362 | AC-2 | `grep -n "work_item_kit" core/schemas/project-schema.md` — a project overrides the global default on its own frontmatter surface, with the resolution row stated | The optional frontmatter key declared and a resolution row parallel to the existing delivery-approach row |
| #6362 | AC-3 | Regression, unchanged-files-intact on the resolver surface: resolution runs through the existing five-rung cascade and introduces **no parallel resolution path**, so the resolver is consumed and never modified. Probe: `git diff --stat origin/main -- core/governance/OPERATIONS.md`. Null-expecting, so it carries its arms · control: the same command over `core/config/operator.toml.template` returns a non-zero diffstat on the same instrument | **Empty diffstat** on the resolver surface · control non-zero |
| #6362 | AC-4 | Tree-resident anchor the executor can run: `grep -c "SEL-0" core/deploy/tools/check-work-hierarchy.py` — the selection arms exist and emit per-arm identifiers. The behavioral arm is run at Stage 6 and re-run at Stage 7 as `python3 core/deploy/tools/check-work-hierarchy.py --resolve ARCHETYPE --kit PACK_ID --pack-root core/deploy/tests/fixtures/packs`, resolving the same kit under two different archetypes and the same archetype under two different kits, which is what makes orthogonality observable rather than asserted | Anchor **≥ 1** · four resolutions, each emitting the expected kind set with provenance · the kit axis and the methodology axis each vary independently |
| #6362 | AC-5 | `grep -nE "^## Kit selection and precedence" core/packs/README.md` — the README documents kit-to-methodology orthogonality and kit-to-override precedence. Graded against the retired empty-kit premise: prose asserting that a kit selected without an archetype pack is an error state is graded NOT MET, because a kit-only root resolves the kit's own kinds and exits 0 | The section present, stating orthogonality and precedence, and stating the vocabulary-emptiness condition as "no kind-bearing pack at all" rather than as the kit-only case |
| #6381 | AC-1 | Tree-resident anchor the executor can run: `grep -c "level_role" core/deploy/tests/fixtures/packs/rollup-kit/pack.toml` — the acceptance fixture carries the traversal carrier. Graded as restated by the design, not as literally worded: container levels resolve an entity type, never a kind, so a fixture declaring kinds at portfolio, program and project is the **rejection** arm, not the acceptance arm. The behavioral arm is run at Stage 6 and re-run at Stage 7 as `python3 core/deploy/tools/check-work-hierarchy.py --validate-packs --pack-root core/deploy/tests/fixtures/packs/rollup-kit` | Anchor **≥ 1** · exit 0 on the rollup fixture with the full traversal depth reported · the tier-claiming fixture rejected under its own rule identifier and no other |
| #6381 | AC-2 | Null-expecting, stated as a valid extended-regex probe rather than a lookahead the matcher cannot compile: `grep -cE '^[[:space:]]*base[[:space:]]*=[[:space:]]*"[^"]*"' core/deploy/tests/fixtures/packs/rollup-kit/pack.toml` counts every base declaration, and `grep -cE '^[[:space:]]*base[[:space:]]*=[[:space:]]*"Work Item"' <same file>` counts the conforming subset; the two counts must be equal, which is the same assertion without a negative match — no new entity node is introduced at any level · control: the conforming-subset count returns non-zero on the same file with the same instrument | Both counts **equal** and non-zero, so **0** non-`Work Item` bases · control non-zero |
| #6381 | AC-3 | `grep -n "level_role" core/schemas/work-item-type-schema.md` — the grouping/execution distinction has a grammar carrier inside the existing projection object rather than as a new top-level construct | The field declared inside the projection object with a **CLOSED** value domain — an unknown value is an error, distinct from the kit-class field's OPEN domain |
| #6381 | AC-4 | Tree-resident anchor the executor can run: `grep -c "PACK-K09" core/deploy/tools/check-work-hierarchy.py` — the nested-grouping rule exists and carries its own identifier, so a rejection is attributable. The suite arm is run at Stage 6 and re-run at Stage 7 as `python3 core/deploy/tools/check-work-hierarchy.py --self-test`, restricted to the level rules | Anchor **≥ 1** · the nested-grouping fixture rejected under its own rule identifier and no other |
| #6381 | AC-5 | `grep -nE "^## What lives where" core/packs/README.md` — the README states that the kit types the work and does not redefine the tiers held in the entity model | The boundary statement present in the assigned section |
| #6381 | AC-6 | Regression, unchanged-files-intact on behavior rather than on bytes: the existing hierarchy finding set and kind-emit output are byte-identical before and after the change on the same tree. Probe: capture `python3 core/deploy/tools/check-work-hierarchy.py --emit-kinds` at the baseline and at branch head and compare. Null-expecting on the diff, so it carries its arms · control: the same comparison against a seeded extra fixture pack must produce a **non-empty** diff | **Byte-identical** output · control non-empty |

## Quota Budget

**Verdict:** **WARN** (per the quota-budget protocol, Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **5** · Stage 7: **5** · Stage 8: **5**
**Per-spoke cost estimate:** size-bucket ordinal band (heuristic — no telemetry medians available; the per-bucket cutover conditions are unevaluated, so every bucket keeps its band). Worst batch composition = 1 × `size:XL` (high) + 3 × `size:M` (low–moderate) + 1 × `size:S` (lowest).
**Assumed/stated remaining usage-window envelope:** **UNSTATED** — no operator quota band was captured at hub start. The conservative default applies. `[ASSUMPTION – CONFIRM]`
**Estimated cumulative draw % (worst parallel batch):** **not computable — deliberately not synthesized.** A draw percentage is only ever a projection of an operator-stated band; with basis `UNSTATED` no figure may be rendered. A sourced-looking number the session could not obtain is worse than no number.
**Routing:** WARN → **window-aware launch timing + quota-budgeting (split batch)**. This is not a stagger: a stagger is a rate-limit defense and does not change cumulative consumption. Concretely, an `UNSTATED` basis caps Checkpoint B's wave width at **2**, so each 5-spoke parallel batch splits into 3 sub-waves, re-gated before each. Stating the band is what buys width.
**Note:** Checkpoint B re-validates at every agent launch — wave or singleton, every stage — and gates on a second axis these fields deliberately do not carry: the host-API quota pools, read at runtime and combined defer-dominant. Checkpoint A stays usage-window-only, because a plan-time pool reading has no predictive value at Engineering time. Bands and the cumulative-draw budget are calibration-pending at MEDIUM confidence.

**Observed host-API condition, recorded because it is load-bearing for the remaining spokes.** The GraphQL pool has been exhausted twice on this run, and the rate-limit probe was observed reporting a full GraphQL quota while GraphQL calls were being rejected. **The probe is not trustworthy on this run.** A spoke whose issue reads start failing as rate-limited switches to the REST issues endpoints — a separate quota — rather than sleeping. This Engineering spoke used REST exclusively and made no GraphQL call.

## Authorized ADRs

| ADR | Owner | Home | Status at authoring |
|---|---|---|---|
| **ADR-170** — Work-item kit as a first-class, archetype-neutral, kind-bearing pack role | #6360 | `core/ADRs/` | `Proposed`, flipping to `Accepted` when the operator ratifies at the Stage 9 Plan Review gate |

Number **170** verified free at Engineering Commit 0 against both ADR directories and the allocator's next-free oracle. No other ADR is authorized by this release; the two placement recommendations that reached Collective Review were rendered as D-decisions, not as decision records.

## Baseline Pin

`origin/main` @ **`539c4440fc1457e8d42d2bbe11c7be663baf596f`**

Every Engineering spoke branches from this commit, and every measurement in this plan was taken against it. Stage 9 re-checks mid-pipeline divergence against this pin. Confirmed at Engineering Commit 0: `origin/main` still resolves to this SHA after a fresh fetch, so no divergence has accrued between Planning and the first write.

## Delivery Strategy · Verification · Rollback

**Branch topology:** SINGLE — one branch `release/kit-unit-and-selection`, one PR, five issues as delivery slices in Implementation Sequence order.
**Concurrency posture:** P0 fully-serial. Force-push on the shared release branch is prohibited under any posture and is not applicable at P0.
**Version:** rule-computed next-free for a minor bump, anchor `v4.45`. Re-verified at Engineering Commit 0 and re-verified again at the Stage-12 atomic claim; the concrete number binds only there.
**Sub-task decomposition container:** GitHub sub-issue container. The threshold predicate selects it unambiguously — the change matrix carries far more than five file-level units, and the work is multi-file and structure-changing on the pack grammar, so the lightweight checklist path is unavailable.
**Verification:** the per-issue table above is the executor's input; the five cross-issue criteria are the release-level cohesion constraints, graded at Stage 9 on the merged PR.
**Rollback:** whole-PR revert, and that is the correct granularity (R-4). No partial or per-issue revert path exists or should be attempted — the bundle ships one definition and four consumers of it. Reversibility **EXPENSIVE** / confidence **HIGH**.

## Change Description

*Authored incrementally across the Engineering slices; refreshed by the last Engineering spoke before the draft-to-ready transition at Stage 9.*

### Outcome

A work-item kit becomes a first-class unit of the pack grammar: a third pack role that is archetype-neutral at both the pack level and — the limb that carries the capability — at the kind level, kind-bearing without naming an archetype, and selectable through the configuration cascade a deployment already uses for its methodology. The unit is generic over future kit classes by construction rather than by promise, and it types work at the Work-Item level while projecting onto every organizational level a rollup traverses.

### Issues delivered

| Issue | Slice | State |
|---|---|---|
| #6360 | the founding ADR | landed at Engineering Commit 0 + 1 |
| #6377 | the consumer map and the instrument fix | pending |
| #6361 | the grammar, the validator, the fixture home | pending |
| #6362 | selection through the cascade | pending |
| #6381 | level coverage | pending |

Each is marked as closed at Stage 13 against the merged PR; no per-issue close keyword appears in this plan or in the PR body.

### Key decisions

D-ReleaseClass · D-Concurrency Posture · D-Version · D-MapHome · D-FixtureHome · D-Instrument · D-CompatShape · D-ReadmeSplit + CR-1 · D-EmptyKitRetire · D-OutcomeAmend · D-CarryFindings · CR-2 D-KitFieldShape (deferred to Stage 6, owned by #6362).

### Reversibility

**EXPENSIVE / Confidence HIGH.** The grammar becomes a contract the moment a deployment authors kit packs and a consumer resolves against them. Pre-consumption the additions are optional and reversible at MODERATE cost; the release is deliberately taken at the cheap moment for that reason.

### Downstream impact

Five downstream milestones resolve against this bundle's definition of a kit. The consumer map inside the bundle is what makes the grammar change safe to attempt in one merge.

### Cross-references

The founding ADR is subordinate to the work-item-type-layer kernel, extends the methodology-pack composition grammar at the same altitude, and is a sibling to the composing-unit record. It supersedes nothing.

## Deviation Log

| # | Stage | Deviation | Disposition |
|---|---|---|---|
| 1 | 6 | The Stage-5 design for #6360 listed an index-row edit to `core/ADRs/README.md`. That file's own text refuses enumeration rows and the Stage-4 plan reached the same conclusion independently. | Recorded as `NOT EDITED` in the matrix with the reason stated. Minor adjustment; no scope change. |
| 2 | 6 | The AC baseline moved from 27 to 28: #6361 carries 6 criteria, not the 5 Stage 4 recorded. | Re-baselined in the Verification Plan with the instrument and the cause named. Minor adjustment; no scope change. |
| 3 | 6 | Four Verification-Plan rows carried an unescaped pipe inside a regex alternation, breaking table field parity so every cell past the break read at a shifted index. The plan-verification executor refused to index them. | Pipes escaped; re-measured with an independent parity probe over all 102 table rows — 4 mismatches → **0**. Authoring defect on this file, fixed at Commit 0 + 2 rather than carried. |
| 4 | 6 | Nine Verification-Plan rows named a tool invocation with no probe the plan executor's family classifier recognizes, so each graded ERROR as an unreadable check rather than running. | Each row re-cut to lead with a tree-resident anchor the executor can run, naming the behavioral invocation as the arm executed at Stage 6 and re-run at Stage 7. Unclassified rows 9 → **0**. The assertions are unchanged; only their expression moved. |
| 5 | 6 | One row expressed a null expectation as a negative-lookahead regex, which the extended-regex matcher cannot compile — the check could never have run. | Restated as two counts that must be equal, which is the same assertion without a negative match. |

## Issue References

- #6360 — decide the work-item kit as a first-class unit (founding ADR)
- #6377 — map the full link and blast-radius chain before any type-system change
- #6361 — make a work-item kit expressible in the pack grammar
- #6362 — select a work-item kit through the configuration cascade
- #6381 — cover every organizational level in the kit, portfolio down
- #6447 — Stage 4 Release Planning sub-task (closed; the pre-Commit-0 working reference)
- #6591 — Stage 9 Plan Review sub-task, carrying the README reconciliation, the independent adversarial review, and the Collective Review scope-lock
- #5291 — parity-gate hardening in a sibling milestone; coordination edge only, and the owner of the unsanctioned kind-label disposition, so the labels on #6360 and #6377 are not re-typed by this release
- #5827 — an undeclared cross-methodology kind in the base pack; this release's role model supplies its structural answer but the composition lock forbids pulling it in. Surfaced, not filed.
- #6371 — pack and kit content-completeness lint, held in a sibling milestone; the composition lock forbade re-homing it here and the intent was satisfied by scope refinement on #6361 instead.
