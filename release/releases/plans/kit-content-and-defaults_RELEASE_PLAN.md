---
title: Release Plan — kit-content-and-defaults (the pack configurable/fixed boundary, content provenance, the Scrum and Kanban kit content, and a pack's declared default)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: kit-content-and-defaults
release_class: cross-cutting
reversibility: CHEAP / Confidence HIGH — every card is additive authoring into existing files plus four new files; no deletion, no path relocation, no consumer contract narrowed
---
# Release Plan — `kit-content-and-defaults`

**Milestone:** `kit-content-and-defaults` · hub sub-task **#6909** = Stage 4 plan source and the operator decision record · **#6970** = #6378's Stage 5 design source (re-spawn, two A6.5 passes) · **#6971** = the Stage 6 Engineering sub-task that authored this file
**Version identity:** **versioned** — bump-class **`minor`**; the concrete `vX.Y` binds only at the Stage-12 atomic claim per [`RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Versioning Phase 2, so the plan file and branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp token. The Commit-0 version re-verify ran in full and **caught a real collision** — see § Commit-0 Version Re-Verify Record.
**Topology:** D-C **SINGLE** — one release branch (`release/kit-content-and-defaults`), one PR, one merge, base `main`; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch. Every non-serial posture prohibits force-push (including `--force-with-lease`) on the shared release branch; P0 is in force, so the prohibition is moot here and is recorded for completeness.
**Release class:** `cross-cutting` — rendered by the operator at the Stage-4 gate (D-ReleaseClass). Differentiation posture: engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #6909 together with every **Decision Recorded** comment on that sub-task (Plan Review · scaffold-precondition withdrawal · Procedure 4 routing · sub-wave 1 close · Stage 5 wave close · Stage 5 close · Collective Review · Stage 6 entry), and reconciles them to the five Stage-5 design specifications. Where a later disposition superseded a Stage-4 assumption, the transcribed section carries the **ratified** value and § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #6971, card #6378).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — declared at Bundle as intent-to-bump; it sets the floor and binds no concrete number. Next-free was recomputed at Commit 0 against fresh authoritative host state and moved from the Stage-4 reading (see § Commit-0 Version Re-Verify Record). |
| **Date Created** | 2026-09-04 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/kit-content-and-defaults` |
| **PR** | #7017 — created **draft** at Stage 6; the hub transitions it to ready-for-review at the Stage 9 gate |
| **Milestone** | `kit-content-and-defaults` |

`domain_practice: { source: core/disciplines/work-organization-mapping-framework.md §3.2, name: Scrum Guide 2020 + INVEST (Cohn — User Stories Applied), date: 2026-09-04, domain: process }`

**The label is CORRECTED against the Stage-4 transcription source, and the correction is the point.** Stage 4 Phase A1.5 emitted **Mode B / `UNSOURCED-DOMAIN`** on the ground that *"the platform encodes no Scrum Guide / INVEST / Kanban Method corpus."* **That premise is false at the pin.** [`core/disciplines/work-organization-mapping-framework.md`](/core/disciplines/work-organization-mapping-framework.md) §3.2 `:157` ships a **Story best-practice default sourced by name** — *"Source of best practice: Scrum Guide 2020 + INVEST (Cohn, \"User Stories Applied\") — referenced by name"* — and [`core/schemas/work-item-type-schema.md`](/core/schemas/work-item-type-schema.md) §1.4 `:367` makes **consuming** it an obligation rather than an option (*"The shipped best-practice defaults are consumed, not re-authored here"*). #6365's Stage 5 adopted the shipped default rather than inventing a field set; **#6366's §5.7 upgraded Mode B → Mode A**. The label transcribed here is the upgraded one. See **DEV-1** in § Deviation Log — this is a hub obligation being discharged at Commit 0, not a spoke-side reinterpretation.

**Domain classification.** `domain: process` (the authored content encodes methodology practice) with `governance` secondary (the File Change Matrix targets `core/schemas/`, `core/standards/`, `core/packs/`, `core/ADRs/`). Dominant recorded in the label, secondary noted here, per the A3-time classification rule. Sourcing is **not** exempt: the release ships methodology content whose external bodies of practice are named, so Form X does not apply and Form A is the correct form.

---

## Commit-0 Version Re-Verify Record

[`hub-spoke-bridge.md`](/release/references/how-to/hub-spoke-bridge.md) § Procedure 0 § Canonical location requires the **first** Engineering spoke under SINGLE topology to re-run the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1** — refresh authoritative host state | **EXECUTED.** `origin/main` = `5facfded2f09e7ef9162a11ae71a6bf025ccaefc`. The Stage-4 baseline pin was `ef008d6d`; **the substrate moved by 7 commits between Planning and Engineering.** | `git fetch --tags origin`; `git fetch origin main`; `git rev-parse origin/main` |
| **2** — recompute next-free for bump-class `minor` | **EXECUTED. Next-free = `v4.54`.** `anchor()` = **v4.53** — the highest claimed version across all three `claimed_set()` arms, **not** the highest published Release (v4.52). `FLOOR(minor)` = `(4, 54)`; `v4.54` is absent from `claimed_set()`, so the walk terminates at the floor. | `release/tools/claim-version.sh --sha 5facfded2f09e7ef9162a11ae71a6bf025ccaefc --bump minor --dry-run` → `v4.54`. Independently reproduced across the three arms: **published Releases** `gh release list` latest = `v4.52`; **origin tags** `git tag -l 'v4.5*'` = `{v4.50, v4.51, v4.52, v4.53}` over 54 `v4.*` refs; **RELEASE_LOG** read via `git show origin/main:release/releases/RELEASE_LOG.md` — highest row `v4.53 \| hook-guards-fail-closed-fasttrack \| … \| VERIFIED \| 2026-09-04`. |
| **3** — PROCEED / HALT on claimed-set membership | **PROCEED.** `v4.54` is free on all three arms. **The Stage-4 reading of `v4.53` was stale and would have collided** — a concurrent release, `hook-guards-fail-closed-fasttrack` (PR #6997, tag claimed at `1b143be4`), took the slot during this milestone's Stage 5. Writing the plan on the stale value would have overwritten a shipped release's plan file. **The hub ran this check once at Stage-6 entry and it caught the collision; this is the second, independent run, and it confirms the same answer.** | Sensitivity arm — `v4.53` **is** present in the claimed set (tag ref + `VERIFIED` ledger row), so the reader demonstrably resolves membership. Specificity arm — `v4.54` returns **0** occurrences in the ledger read at `origin/main`, and no `v4.54` tag ref exists, while the same reader finds v4.50–v4.53. |
| **3b** — stamp-manifest assertion | **EXECUTED post-write, pre-commit.** `release/tools/claim-version.sh --verify-stamp kit-content-and-defaults` → **exit 0** (`verify-stamp OK`). | Read-only, network-free — the identical pre-flight the Stage-12 atomic claim runs. The Header `**Version**` cell carries the literal unresolved `{{RELEASE_VERSION}}` token and nothing else, which is what the Stage-12 claim resolves and renames on. |

**Why the number is recorded but not bound.** Step 2's `v4.54` is a Commit-0 *reading* of authoritative state, not a claim. Nothing is held between now and the merge; a concurrent release that merges first takes `v4.54` and this release's claim recomputes upward at the compare-and-swap. Recording the reading makes the Commit-0 PROCEED reproducible without asserting a reservation the allocation rule does not create. **This release is itself the worked example of why:** the Stage-4 reading was correct when taken and wrong 14 hours later.

---

## Baseline Pin

**`origin/main` @ `5facfded2f09e7ef9162a11ae71a6bf025ccaefc`** (short `5facfded` — merge of PR #7012, the v4.53 Stage-13 corpus update). Every count, line number and hunk range in this plan is measured against this pin and is reproducible from it.

**The pin MOVED from the Stage-4 value and the move is recorded rather than silently re-anchored.** Stage 4 pinned `ef008d6d`. Seven commits landed on `main` during Stage 5 — the `hook-guards-fail-closed-fasttrack` release merge (PR #6997), its stamp commit, its Stage-12 and Stage-13 chore PRs (#7008, #7012), and one independent playbook fix (PR #7005, issue #7003).

**Mid-pipeline divergence check — CLEAN, with both arms.**

| | |
|---|---|
| Files the divergence touched (`ef008d6d..5facfded`) | **16** |
| This release's declared write set | **15** paths (§ File Change Matrix) |
| **Overlap** | **0** |
| Sensitivity — is the divergence set populated? | **Fires.** `.version`, `CHANGELOG.md`, `core/hooks/block-destructive.sh`, `core/hooks/tests/block-destructive.test.sh`, `core/rules/bypass-mode-readiness.md`, `core/rules/bypass-mode-readiness/_cross-cutting.md`, `core/rules/bypass-mode-readiness/block-destructive.md`, `core/standards/analysis-workspace-standard.md`, `packages/release-hub.skill`, `packages/release-hub.skill.sha256`, `release/releases/RELEASE_DIGEST.md`, `release/releases/RELEASE_INDEX.md`, `release/releases/RELEASE_LOG.md`, `release/releases/notes/v4.53_RELEASE_NOTES.md`, `release/releases/plans/v4/v4.53_RELEASE_PLAN.md`, `release/skills/release-hub/references/orchestration-playbook.md` |
| Specificity — does any write-set path appear? | **0.** The concurrent release worked on hook guards and release corpus; this release works on pack grammar and pack content. |

The hub reported this result at Stage-6 entry over the same 16-file set. **It is re-run here against the *current* pin rather than carried forward**, because `main` advanced two further merges after the hub's check — and a divergence result is a property of a pin, not of a release.

**Stage-9 obligation.** Phase A6.5's mid-pipeline divergence re-check re-measures against this pin, not against `ef008d6d`. Three Stage-5 designs measured their blast radius at `ef008d6d` and one (#6363's re-spawn) at `5facfded`; the schema and register files are untouched by the divergence, so no measurement is invalidated — but that is a read of the overlap result above, not an assumption.

---

## Scope

### Issues Included

| # | Issue | Title | Size | Type | Labels |
|---|-------|-------|------|------|--------|
| 1 | **#6378** | Decide the boundary between methodology-configurable and platform-fixed | `size:S` | `type:spike` | `project:methodology-packs` |
| 2 | **#6363** | Carry provenance on kit content so its source is auditable | `size:M` | `type:story` | `project:methodology-packs` |
| 3 | **#6365** | Author the Scrum-shaped kit content | `size:L` | `type:story` | `project:methodology-packs` |
| 4 | **#6366** | Author the Kanban-shaped kit content | `size:M` | `type:story` | `project:methodology-packs` |
| 5 | **#6380** | Ship a default kit with every methodology pack | `size:M` | `type:story` | `project:methodology-packs` |

**5 cards · 22 pts · band-conformant** against the hub-injected `15-25` band. Composition lock intact; `issues_added = 0` at Collective Review.

### Dependency Graph

Probe: GitHub Dependencies API, `blocked_by` / `blocking` on all five cards. **The amendment recorded two edges; the API carries four**, and two more were added by hub determination after #6380's Stage 5.

```
#6378 (the boundary)                #6363 (provenance)
   ├──blocks──▶ #6365                  ├──blocks──▶ #6365
   └──blocks──▶ #6366                  └──blocks──▶ #6366

#6380 ◀──blocked_by── #6365 · #6366   (hub-added; finding D-1)
```

| Edge | In milestone amendment? | Native edge? | Verdict |
|---|---|---|---|
| `#6365 ⇠ #6363` | Yes | Yes | CONFIRMED |
| `#6366 ⇠ #6363` | Yes | Yes | CONFIRMED |
| `#6365 ⇠ #6378` | **No** | **Yes** | Under-recorded by the 2026-09-02 sweep |
| `#6366 ⇠ #6378` | **No** | **Yes** | Under-recorded by the 2026-09-02 sweep |
| `#6380 ⇠ #6365` · `#6380 ⇠ #6366` | Implied only | **Added by hub determination** | Finding D-1 resolved at sub-wave 1 close: **build-gating, not merely acceptance-gating** — #6380 ships `INT-1`/`INT-2` as CI-run arms that read the authored content |

**Circularity: none.** The six edges form a DAG with sources `{#6378, #6363}` and sink `{#6380}`. Control arm — the same `blocking`/`blocked_by` reads returned non-empty for #6363 (5 rows) and #6378 (4 rows), so any empty result is a real absence rather than a dead reader.

**Out-of-bundle, confirmed and with no in-release effect:** #6363 blocks #6371 and #3607/#3608; #6378 blocks #6367 and the parent epic #6358.

### Exclusions

- **#6371** (*Lint packs and kits for content completeness*) — OPEN in milestone `pack-conformance-and-parity` (**ms 374**). It is the intended runner for this release's three named gaps, and it is **deliberately not pulled forward**: an array-scoped completeness rule added to `--validate-packs` hard-fails `deploy.sh --check` on **both** Check-75 discrimination arms (see § Accepted Residuals).
- **#1971** (Kanban pull-limit gate) — ms 374. #6366 AC5 forbids duplicating it; **CIAC-3** is the seam that keeps this release from pre-empting it.
- **`[meta].schema_version`** and the **`checks`-presence** gap — both routed to ms 374 by #6363's Stage 5. **Not re-filed here**: a duplicate issue is governance debt.

---

## Stage Applicability Matrix

Per [`planning-solutioning-handoff.md`](/core/standards/planning-solutioning-handoff.md) § 3 (T1–T6, logical OR, release-wide rollup). **No card skips a stage.**

| Issue | T1 new file | T2 skill logic | T3 structural design | T4 multi-approach | T5 ≥3 gov files | T6 blast-radius uncertain | Verdict |
|---|---|---|---|---|---|---|---|
| **#6378** | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | **ACTIVATE** |
| **#6363** | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ | **ACTIVATE** |
| **#6365** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | **ACTIVATE** |
| **#6366** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | **ACTIVATE** |
| **#6380** | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | **ACTIVATE** |

**Release-level rollup: ACTIVATE.** Per-issue applicability for Stages 5–13 is ✓ across the board; Stages 9–13 are release-scoped singletons, not per-issue.

**#6378 routes through Engineering / DT / QA — it does not short-circuit, and the load-bearing finding is that no spike carve-out rule exists.** Probe: `git grep -i -E "spike"` over `release/references`, `core/standards`, `core/specs`, `release/governance`, filtered to lines also matching stage/skip/short-circuit/route/engineering/qa → **zero** results state or imply that a `type:spike` card skips any stage. Sensitivity: the bare token `spike` returns **28 occurrences across 8 files** in the same denominator. Specificity: a fabricated token returns **0**. The general rule therefore applies: activation keys on T1–T6, never on `type:`; #6378's six completion conditions are gradable, so Stage 8 has a subject; and the card produces a durable corpus artifact.

---

## Release Class declaration

**`cross-cutting`** — rendered at the Stage-4 gate. The declared `routine` was retired because **zero of its four triggers fire.**

| Class | Trigger | Fires? | Evidence |
|---|---|---|---|
| `routine` | (a) all P3/P4 + `size:S/M` | ✗ | #6365 is `size:L` |
| `routine` | (b) all change-spec files ≥3 prior release touches | ✗ | `scrum`/`kanban` `pack.toml` = 3 commits each, **all in v3.54** ⇒ 1 release touch |
| `routine` | (c) zero new files added | ✗ | three ADRs + two fixtures |
| `routine` | (d) zero new D-class decisions | ✗ | ≥8 rendered |
| `novel` | (a) ≥1 new reference doc / schema / skill | ✓ | the §1.5 boundary record; #6363's grammar amendment |
| `novel` | (b) ≥1 D-class decision in the plan | ✓ | see § Decisions Rendered |
| `cross-cutting` | (a) ≥3 `pipeline/stage-*.md` files | ✗ | zero |
| `cross-cutting` | (b) ≥3 of the 6 rule-defining governance surfaces | ✗ | zero |
| `cross-cutting` | (c) ≥3 in-bundle compositional edges per the A2 DAG | **✓** | **6 edges** |

Selected under multi-trigger resolution (`cross-cutting` > `novel` > `routine`), dominant trigger **(c)**.

**The tension is recorded rather than smoothed over.** `cross-cutting`'s *definition* — modifies ≥3 pipeline stages OR ≥3 governance surfaces — is **not** met; this release touches zero of either. Only the edge-count trigger fires. `novel` was available as a documented override and was not taken. The practical delta is one dimension: engagement density **Tight** rather than Standard. Stage 9 depth is **Deep** either way; Stage 5 bias is **ALL** either way.

---

## File Change Matrix

**FROZEN**, with the two ratified amendments folded in (`D-Matrix` → `core/standards/gate-efficacy-standard.md` on #6378 and #6363; `D-R2-QualifierRestore` → `work-item-type-schema.md` §7.3 into #6378's scope). Machine-readable, one path per line, `<path>  <VERB>` (path-first columnar-in-fence form):

```
# ── #6378 · the configurable/fixed boundary (wave 1) ──
core/schemas/work-item-type-schema.md                                      edit
core/standards/gate-efficacy-standard.md                                   edit
core/packs/README.md                                                       edit
core/ADRs/ADR-185-pack-configurable-vs-platform-fixed-boundary.md          add

# ── #6363 · content provenance (wave 2) ──
core/ADRs/ADR-186-kit-content-provenance-key.md                            add

# ── #6365 / #6366 · the authored kit content (wave 3) ──
core/packs/scrum/pack.toml                                                 edit
core/packs/kanban/pack.toml                                                edit

# ── #6380 · a pack's declared default (wave 3) ──
core/deploy/tests/fixtures/packs/pack-default/pd-base/pack.toml            add
core/deploy/tests/fixtures/packs/pack-default/pd-plan/pack.toml            add
core/deploy/tools/check-work-hierarchy.py                                  edit
core/ADRs/ADR-187-pack-default-is-the-declared-kind-set.md                 add

# ── release-scoped ──
release/releases/plans/kit-content-and-defaults_RELEASE_PLAN.md            add
```

`core/schemas/work-item-type-schema.md`, `core/standards/gate-efficacy-standard.md` and `core/packs/README.md` each appear **once** in the fenced set and are written by more than one card; § Per-card attribution below carries the multi-writer breakdown, and § Contention Map carries the ordering. **12 declared paths; 15 path×card write obligations.**

### Read-only inputs

```
core/deploy/deploy.sh                                                      READ
core/disciplines/work-organization-mapping-framework.md                    READ
core/schemas/project-schema.md                                             READ
core/schemas/entity-field-schemas.md                                       READ
core/specs/label-taxonomy.md                                               READ
core/packs/_common/pack.toml                                               READ
core/ADRs/ADR-180-work-item-kit-first-class-unit.md                        READ
core/ADRs/ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md   READ
```

### Release-wide explicit non-scope

```
core/deploy/deploy.sh                                                      NOT EDITED
core/deploy/tests/fixtures/packs/meta-schema-sens/                         NOT EDITED
core/deploy/tests/fixtures/packs/meta-schema-spec/                         NOT EDITED
core/packs/_common/pack.toml                                               NOT EDITED
core/schemas/platform-config-schema.md                                     NOT EDITED
core/schemas/entity-field-schemas.md                                       NOT EDITED
core/config/allowlists/script-execution-allowlist.txt                      NOT EDITED
```

The non-scope block is **explicit and load-bearing, not hygiene**. `deploy.sh:14189-14201` runs Check 75's discrimination control **before** the live-corpus run and increments `ISSUES` **outside** the warn-mode gate; a new `PACK-*` rule firing on either fixture flips `c75_sens_rule` or `c75_spec_rc` and hard-fails `--check`. Declaring `deploy.sh` and both fixture roots out of scope is what makes that boundary falsifiable. **No `add` row names a tracked executable script**, so the `script-execution-allowlist.txt` companion obligation does not fire — an enumerated non-trigger, not an omission. (`check-work-hierarchy.py` is an `edit`, and its existing allowlist row is unchanged.)

### Per-card attribution

| Path | #6378 | #6363 | #6365 | #6366 | #6380 |
|---|---|---|---|---|---|
| `core/schemas/work-item-type-schema.md` | **new §1.5** (after §1.4) + **§7.3 qualifier restore** | §1.2 `criteria`/FieldDecl rows · §1.2.1 fifth base field + 4 worked examples · §3.1/§3.2 projection · §6.2d | — | — | — (**dropped** at Stage 5) |
| `core/standards/gate-efficacy-standard.md` | **3 named-gap rows** (F2 · F3 · F4) | 1 named-gap row (unenforced requiredness) | — | — | — |
| `core/packs/README.md` | pointer to §1.5 + the register rows | provenance-key pointer | — | — | `###` subsection inside `## Kit selection and precedence` |
| `core/packs/scrum/pack.toml` | — | — | **sole writer** | — | — |
| `core/packs/kanban/pack.toml` | — | — | — | **sole writer** | — |
| `core/deploy/tools/check-work-hierarchy.py` | — (**R-7: no `PACK-*` id minted**) | — | — | — | self-test arms only (`PD-00`…`PD-03`) |
| `core/ADRs/ADR-18N-*.md` | **185** | **186** | — | — | **187** |
| fixtures `packs/pack-default/**` | — | — | — | — | **sole writer** |

---

## Contention Map

### Within-release contention (one branch, one PR, P0 fully-serial)

| File | Cards | Class | Severity | Resolution |
|---|---|---|---|---|
| `core/schemas/work-item-type-schema.md` | #6378, #6363 | `line-range-overlap` | **HIGH → reduced to BINARY** | #6380's Stage 5 **dropped** the file, so the Stage-4 3-way became 2-way **by construction rather than by assertion**. #6378 writes §1.5 (new, after §1.4) and §7.3; #6363 writes §1.2 / §1.2.1 / §3.x / §6.2d. **Disjoint line ranges.** Order: #6378 → #6363. |
| `core/standards/gate-efficacy-standard.md` | #6378, #6363 | append-pattern (row adds to an established table) | **BINARY — LOW** | New 2-way created by `D-Matrix`. Both writes are row appends. **#6378 precedes #6363** under P0; its three rows land first, #6363's row appends after. |
| `core/packs/README.md` | #6378, #6363, #6380 | append-pattern | **MULTI-WAY — LOW** | Three additive pointer edits, no anchor moved. **The `## Kit selection and precedence` H2 heading MUST NOT be renamed** — `core/schemas/project-schema.md:304` and `core/schemas/platform-config-schema.md:88` both cite it by section name, and repo-wide anchor links to `packs/README.md#` = **0** against a control of 14 files carrying plain-path references. Order: #6378 → #6363 → #6380. |
| `core/packs/scrum/pack.toml` · `core/packs/kanban/pack.toml` | #6365 / #6366 | — | **NONE** | The Stage-4 predicted 2-way contentions with #6380 **do not materialize**: #6380 dropped both manifests. Each card is the sole writer of its own file. |

**P0 fully-serial makes every row above a sequencing statement rather than a merge risk.** One Engineering spoke at a time on one branch; the write order is the Implementation Sequence order.

### Cross-release contention

**Re-measured at the current pin, not carried from Stage 4.** Stage 4 measured **0 of 19** against in-flight PR #6745 (`release/hooks-block-only-their-scope`) at `ef008d6d`. That PR's counterparty release (`hook-guards-fail-closed-fasttrack`) has since **merged**, and its 16-file divergence set intersects this write set at **0** (§ Baseline Pin, both arms).

**Per the audit-baseline discipline this is a pinned measurement carrying no verdict.** An in-flight roster that is empty or small today is not "no siblings"; **Stage 9 Phase A6.6 re-measures** against whatever roster exists then.

---

## Implementation Sequence

Dependency-ordered. Three waves driven by the six edges, on one branch under P0 fully-serial.

| # | Card | Pts | Why here |
|---|------|-----|----------|
| **0** | **Engineering Commit 0 — this plan file** | — | Carries the Commit-0 Survival Set; version re-verify + `--verify-stamp` pre-flight executed per Procedure 0 § Canonical location |
| **1** | **#6378** (wave 1) | 2 | Sole graph source with two out-edges. Blocks #6365 and #6366 natively. Owns the boundary both content cards cite (CIAC-4) and writes first on all three shared files. |
| **2** | **#6363** (wave 2) | 4 | Second graph source. The `source` key must exist in the grammar before content can carry it (#6365 AC3, #6366 AC3). Writes second on the schema, the register and the README. |
| **3a** | **#6365** (wave 3) | 8 | Predecessors satisfied. Sole writer of `core/packs/scrum/pack.toml`. **Must land after #6363's §1.2/§1.2.1 amendment** — committing first ships 29 declarations carrying a key the grammar does not yet name. |
| **3b** | **#6366** (wave 3) | 4 | Same predecessor rule; sole writer of `core/packs/kanban/pack.toml`. |
| **3c** | **#6380** (wave 3) | 4 | Last: its `PD-02` arm reads the **live** `core/packs` root and grades CIAC-5 over the authored content, and its README subsection appends behind #6378's and #6363's. |

**Commit granularity.** Each card lands in its **own commit**, distinct from Engineering Commit 0, so any card reverts independently.

**#6378 is a hard predecessor, not a discretionary early start.** The 2026-09-02 sweep recorded it as *"FREE to build (ship-gated only)"* — true of its *inputs*, but its *outputs* gate two cards via native edges the sweep did not record. "Start #6378 early" and "hold the bundle to one sequence" are therefore the **same** ordering, which is what dissolved D-Sequence on evidence.

### Agent-Editability Read

**Derivation** — controls read at commit `ef008d6d` (Stage 4) and unchanged by the divergence, which touched neither hook:

- **Tier-0 floor** — `core/hooks/block-autonomy-ceiling.sh`: **2** `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`. Block 1 arms, verbatim: `${PRIMARY_ROOT}/pmo-platform/`\*`/OPERATIONS.md` · `${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md` · `${PRIMARY_ROOT}/pmo-platform/`\*`/RELEASE_PROTOCOL.md` · `${PRIMARY_ROOT}/.claude/settings.json` · `${PRIMARY_ROOT}/.claude/hooks/`\* · `${PRIMARY_ROOT}/.claude/rules/`\*. Block 2 (repository-membership, guarded by `is_platform_worktree`): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`.
- **Sanctioned-session gate** — `core/hooks/block-skill-direct-edit.sh`: `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|------|----------------|----------|--------------|-----------|-----------|----------------|
| #6378 | `core/schemas/work-item-type-schema.md` · `core/standards/gate-efficacy-standard.md` · `core/packs/README.md` · `core/ADRs/ADR-185-*.md` | ∅ | ∅ | unconstrained | **unconstrained** | ordinary Engineering spoke |
| #6363 | same three + `core/ADRs/ADR-186-*.md` | ∅ | ∅ | unconstrained | **unconstrained** | ordinary Engineering spoke |
| #6365 | `core/packs/scrum/pack.toml` | ∅ | ∅ | unconstrained | **unconstrained** | ordinary Engineering spoke |
| #6366 | `core/packs/kanban/pack.toml` | ∅ | ∅ | unconstrained | **unconstrained** | ordinary Engineering spoke |
| #6380 | `core/packs/README.md` · `core/deploy/tools/check-work-hierarchy.py` · fixtures · `core/ADRs/ADR-187-*.md` | ∅ | ∅ | unconstrained | **unconstrained** | ordinary Engineering spoke |

Per-path rows are retained, never collapsed into the card class. **All-`unconstrained` is the correct and informative output here**: no write-set path sits under `.claude/`, is a root governance file, or matches `*/skills/*`. Conjunct 1 of the skill gate decided every row — the paths do not match `SKILL_SCOPE_RE` — so conjuncts 2 and 3 were never reached, which is stated so a reader can tell a discriminating read from a lucky one.

---

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#6363 × #6365 × #6366 on `core/packs/*/pack.toml`):** Every field and criterion authored by #6365 and #6366 carries a `source` key declared by #6363's convention — no authored content is source-less. *Method:* extract every `[kinds.criteria.*]` check entry and every `fields.kind_specific[]` FieldDecl across `core/packs/scrum/pack.toml` and `core/packs/kanban/pack.toml` and assert each carries a non-empty `source`; **control arm** — the same extraction must return a non-zero entry count, else the probe is broken rather than the content clean. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#6365 × #6366 on named bodies of practice):** No `source` value on any authored kit content names a repo-internal artifact. *Method:* `grep -nE 'source *= *"[^"]*(\.github|ISSUE_TEMPLATE|pmo-platform|label-taxonomy|improvement\.yml|bug\.yml|observation\.yml)' core/packs/scrum/pack.toml core/packs/kanban/pack.toml` — expect 0 hits; **control arm** — the same pattern with `Scrum Guide|INVEST|Kanban` must return non-zero, proving the extraction reaches the `source` values at all. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#6366 × #6380 on the Kanban `[kinds.criteria.gate]` block):** #6366's authoring populates `readiness` and `done` for the `card` kind while leaving the pull-limit `gate` block's `checks` empty, so #1971's scope is not pre-empted. *Method:* assert `checks = []` still holds under `[kinds.criteria.gate]` in `core/packs/kanban/pack.toml` while `[kinds.criteria.readiness]` and `[kinds.criteria.done]` are non-empty; **control arm** — the readiness/done assertion must observe non-empty, else the whole file failed to author and the gate-empty result is vacuous. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#6378 × #6365 × #6366 on the boundary record):** Both content cards cite #6378's boundary in their acceptance, per #6378's completion condition 6. *Method:* anchor-resolution — `core/schemas/work-item-type-schema.md#the-configurable-fixed-boundary` resolves in the merged tree, and each content card's Stage-8 evidence cites it **once per authoring decision class** (criteria-content placement · field-set placement · the reasoned-empty-set justification · the Kanban `gate`-block preservation), each naming **which of Q1–Q4 it answered NO to** and, for a Q2 `YES (b)`, the consumer **and its ticket**. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#6380 × #6365 × #6366 — pack-resolved kind-set appropriateness):** Each shipped pack, resolved with no kit selected, yields a **non-empty** kind set that is **disjoint in `kind_id`** from every other shipped pack's, and whose kinds are the ones that pack's methodology names. *Method:* `python3 core/deploy/tools/check-work-hierarchy.py --resolve Scrum --pack-root core/packs` and `--resolve Kanban --pack-root core/packs`; assert `COUNT > 0` on each and assert the `KIND` id sets are disjoint (`epic`/`story`/`task` vs `card`); **control arm** — each resolution must return a non-empty kind set, else disjointness is vacuous. *Graded at Stage 9 QC3.5 on the merged PR.*

**CIAC-5 is RESTATED from the approved Stage-4 wording** (`D-CIAC5`). As approved it graded *"each pack's **named default kit**"* — and #6380's AC1 disposition is that **no named default kit exists**, so the criterion would have graded an artifact that will not exist: a **vacuous pass**, the silent kind. The restatement binds it to a predicate executable today; the hub verified both invocations return `COUNT 3` and `COUNT 1` against the shipped corpus.

---

## Verification Plan

**AC baseline as read at `5facfded`:** #6378 — **6** criteria · #6363 — **5** · #6365 — **6** · #6366 — **5** · #6380 — **6**. A count that no longer matches this baseline is the mechanical signal to re-bind the ordinals.

`ac_baseline: { #6378: 6, #6363: 5, #6365: 6, #6366: 5, #6380: 6, read_at: 5facfded2f09e7ef9162a11ae71a6bf025ccaefc }`

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6378 | AC-1 | `grep -cE '^\| \*\*C[0-9]+\*\*' core/schemas/work-item-type-schema.md` — expect 12 C-rows. **Control arm** (the reader is live): `grep -cE '^\| \*\*F[0-9]+' core/schemas/work-item-type-schema.md` must return non-zero over the same file and the same instrument | **12** C-rows, each naming its unit of choice and either an enforcing-gate rule id or an explicitly-labelled gap |
| #6378 | AC-2 | `grep -c 'NAMED GAP' core/schemas/work-item-type-schema.md` — expect 3 labelled gaps in the F-table. **Paired register read:** `grep -c 'NAMED GAP' core/standards/gate-efficacy-standard.md` must rise from its pin value of 3 to at least 6 | **6** F-rows; every `Reason` cell non-empty; **3** cells explicitly labelled a named gap; **6** falsification tests, each recording the arm that ran and its observed result |
| #6378 | AC-3 | `grep -c 'guards_transition' core/schemas/work-item-type-schema.md` and read every hit — assert the readiness/done placement table lands the key on exactly one side. **Control arm:** the same instrument on `criteria_version` must return non-zero | 10 placement rows, no key on both sides. **`guards_transition` in particular** — its F4/C11 double-placement is the defect this AC grades |
| #6378 | AC-4 | `grep -c 'M[1-8]' core/ADRs/ADR-185-pack-configurable-vs-platform-fixed-boundary.md` — expect at least 8 references to the A6.5 reviewer's independent candidate set, present alongside the design's own eight. **Control arm:** `grep -c 'Q2' <same file>` must return non-zero | Both candidate sets reported **with their denominators**. Every candidate resolves to FIXED / CONFIGURABLE / NOT PLACED, or is recorded as determinately unanswerable with the arm that makes it so. **Reporting only the design's set is not acceptance evidence.** |
| #6378 | AC-5 | `grep -c 'lifecycle_behavior' core/schemas/work-item-type-schema.md` — expect at least 6, spanning §1.2, §7.4 and the new §1.5 reconciliation paragraph. **Control arm:** `grep -c 'zzq-not-a-key' <same file>` must return 0 | The §7.4 reconciliation states the orthogonality, the composition seam, and the corrected presence-vs-value split — `PACK-K01` enforces `lifecycle_behavior` **presence**; nothing reads its value |
| #6378 | AC-6 | Anchor resolution + per-class citation — **CIAC-4 verbatim**; no parallel path | `#the-configurable-fixed-boundary` resolves; both content cards cite it per authoring decision class |
| #6363 | AC-1…AC-5 | `grep -c 'source' core/schemas/work-item-type-schema.md` — expect at least 20 once §1.2/§1.2.1/§3.x/§6.2d land. Substance is graded against #6363's Stage-5 design (sub-task #6974) and **D-AC4 (A)** — AC4 against the reworded predicate (*the annotation is machine-readable and its absence is detectable by a reader over the whole population*), **not** the stale body text | Fifth base field declared; the four worked `checks[]` examples each carry it; the issue body is unamended per ADR-062 |
| #6365 | AC-1…AC-6 | `grep -c 'source = ' core/packs/scrum/pack.toml` — expect at least 25 (21 check entries + 7 FieldDecls, less block-level rollups). AC6's *"nine empty criteria arrays resolved"* is graded per #6365's Stage-5 design (sub-task #6978) as **6 blocks populated + 3 `gate` blocks left `checks = []` each carrying a block-level `source`** — the ratified reasoned-empty-set reading | `--validate-packs` `COUNT 0`, exit 0 · sensitivity: remove any `[kinds.lifecycle_behavior]` → `PACK-K01`, exit 1 |
| #6366 | AC-1…AC-5 | `grep -c 'source = ' core/packs/kanban/pack.toml` — expect at least 6. Substance per #6366's Stage-5 design (sub-task #6982); AC5 is **CIAC-3** | `--validate-packs` clean; `[kinds.criteria.gate].checks = []` preserved with its rationale comment |
| #6380 | AC-1…AC-6 | `grep -c 'PD-0' core/deploy/tools/check-work-hierarchy.py` — expect at least 4 self-test arms: `PD-00` (non-vacuity) · `PD-01` + `PD-01c` (control) · `PD-02` (= CIAC-5) · `PD-03` (AC3's teeth). Substance per #6380's Stage-5 design (sub-task #6986) | `PD-01`'s union is exactly `pd-plan`'s `kind_id` set with **zero** `role=kit` rows, against `PD-01c`'s ≥1 `role=kit` row over the `selection` fixture root — **the zero is measured, not assumed** |

**Every null expectation above carries its arm.** #6378 AC-2's "3 named gaps" is a positive count, not a null; #6380 `PD-01`'s zero `role=kit` rows carries `PD-01c`; CIAC-2's zero-hit expectation carries its `Scrum Guide|INVEST|Kanban` control. **The third-arm rule applies to `PD-03`**: `--resolve Waterfall --pack-root core/packs` → `COUNT 0` is a property of *the corpus* (zero kits ship there), not of the resolver — so the arm must also assert that the population it examined could have exhibited the construct, which `PD-01c` supplies over a root that does carry kits.

### Release-Level Verification

Per `verification-checklist.md`:

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity
- [ ] Skill Invocation — **N/A, enumerated:** the write set contains zero `*/skills/*` paths and zero `packages/**` artifacts, so no skill surface changes and no package is staled. Verified against the matrix above, not assumed.
- [ ] Output Contract Compliance
- [ ] `deploy.sh --check` — **Check 62** (gate-coverage register) recomputes from `core/standards/gate-efficacy-standard.md`; **Check 75** (pack conformance) runs `--validate-packs` over `core/packs`. Both must be re-read after every register and manifest edit.

---

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered), **P0 fully-serial** |
| **Branch topology** | **D-C SINGLE** — one branch `release/kit-content-and-defaults`, one PR, one merge, base `main` |
| **Commit strategy** | One commit per card, plus Engineering Commit 0 for this plan file |
| **Review approach** | Single PR for the entire release; **draft on create**, transitioned to ready at the Stage 9 gate |
| **Deployment mechanism** | Git merge. **No S-2 skill copy and no manifest execution** — see § Operational Deployment Manifest |
| **Stacked-base cleanup posture** | N/A — SINGLE topology; no stacked bases planned |

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|-------|----------------|-----------|
| #6378 | `git revert <commit>` | **Low** — one new ADR plus additive edits to three files; no anchor moves |
| #6363 | `git revert <commit>` | **Low** if reverted before #6365/#6366 land; **Medium** after — the content cards' `source` keys would then reference a grammar key that no longer exists |
| #6365 · #6366 | `git revert <commit>` | **Low** — content-only edits to one manifest each |
| #6380 | `git revert <commit>` | **Low** — two new fixture files, self-test arms, one ADR, one README subsection |

### Whole-Release Rollback

**CHEAP · confidence HIGH.** `git revert -m 1` of the merge commit. All five cards are additive: no file is deleted, no path relocates, no consumer contract narrows, no meta-schema version moves (the pack-composition, controls-facet and kit extensions are all additive-in-effect at meta-schema v1). The one caveat is the ordering coupling above — revert in reverse wave order, or revert the merge.

---

## Risk Register

| # | Risk | Owner | Reversibility / Confidence | Mitigation |
|---|---|---|---|---|
| **R-1** | **Content sourced from this deployment rather than from the named body of practice.** The failure the milestone names twice: an authoring spoke with this repo in context produces a readiness criterion that reads correctly but derives from `.github/ISSUE_TEMPLATE/` or the platform's own label set. Nothing about the output looks wrong. | Stage 8 QA | MODERATE / MEDIUM | Three runnable arms. **(1) Provenance-value audit** — CIAC-1 + CIAC-2, mechanical once #6363 ships the `source` key, which is why #6363 is a hard predecessor. **(2) Reverse-lexical overlap probe** — `grep -Ff` the authored criterion strings against `.github/ISSUE_TEMPLATE/*.yml` and `core/packs/_common/pack.toml`; a hit is a finding to be defended, not proof; seed the probe with a string known present to confirm it fires. **(3) Positive-citation spot-check** — INVEST's six letters, the Scrum Guide's Definition of Done and the Kanban Method's core practices are small closed sets; a criterion citing INVEST that maps to none of the six is a mis-citation wearing a citation. |
| **R-2** | **The repaired placement test ships without facing an independent attacker.** A6.5 ran twice on #6378 and is not scheduled again; Stage 7 and Stage 8 grade the *implementation*, not the test's adversarial robustness. | Operator (accepted) | MODERATE / HIGH | **Accepted at `D-PlacementTest-ToStage6`, recorded so it is traceable rather than reconstructed.** Mitigation is the dual-denominator acceptance evidence: Engineering reports placement on the A6.5 reviewer's independent candidate set **as well as** the design's own, so a regression on the adversarial set is visible at Stage 8 rather than in use. |
| **R-3** | **Stale ADR reference on #6378's ship-gate.** The milestone amendment says *"reconcile against merged ADR-170"*; the kit ADR is **ADR-180**. Slot 170 now holds an unrelated portfolio-framework ADR. Reconciling against the wrong ADR satisfies the ship-gate vacuously. | Stage 13 | CHEAP / HIGH | Reconciliation target corrected to **ADR-180** (`core/ADRs/ADR-180-work-item-kit-first-class-unit.md`, `status: Accepted`). **ADR-170-portfolio is a *secondary* target, not irrelevant** — it independently carries a `pack-grammar-boundary` decision and the line *"variability that is not work-item-type variability does not belong in the type layer"*, which is F5's grounding. The renumber itself is governed behaviour, not a defect; what was stale is the reference. |
| **R-4** | **`work-item-type-schema.md` is a 103 KB file written by two cards.** Concurrent edits risk conflict. | Stage 6 | CHEAP / HIGH | **P0 fully-serial** plus disjoint line ranges (§ Contention Map). #6378 writes §1.5 and §7.3; #6363 writes §1.2/§1.2.1/§3.x/§6.2d. |
| **R-5** | **The three named gaps have no runner in this release**, so §1.5's fixed surface is declared-but-unenforced on three of six rows. | #6371 (ms 374) | CHEAP / HIGH | **Deliberate, and closing them here is worse than leaving them open** — see § Accepted Residuals. The rows land in the gate-coverage register with their declared observables and falsification tests, so the gap is countable rather than invisible. |
| **R-6** | **#6365 is `size:L`, the largest card**, authoring 21 check entries and 7 new FieldDecls across three kinds. A late split would slice against the wrong axis. | Stage 6 | MODERATE / MEDIUM | No split. D-ContentHome (A) freezes its write set to **one file**, which removes the reason a split was contemplated at Stage 4. |
| **R-7** | **CIAC-4's anchor does not exist until #6378's Engineering lands.** A Stage-8 read of #6365 or #6366 before that would fail on an absence that is not theirs. | Stage 8 / Stage 9 | CHEAP / HIGH | **Grading order is explicit:** CIAC-4 resolves the anchor on the *merged* PR, never on an intermediate commit. The Implementation Sequence puts #6378 first for exactly this reason. |
| **R-8** | **`gh api rate_limit` is a dead gauge on this deployment** — it reports `5000/5000 used=0` on both pools while live calls return 403. Every host-API quota verdict this release rendered read that gauge. | Hub | CHEAP / HIGH | Open `escalation`/`tier-2`. Probe with a **real call**; a refusal on quota grounds is positive evidence of exhaustion. REST and GraphQL have separate pools — on refusal, **switch rather than wait**. Exercised at Commit 0: a GraphQL TLS timeout was resolved by switching to REST `gh api`, and both reads returned at full length. |

---

## Accepted Residuals

| # | Residual | Why it is accepted rather than fixed |
|---|---|---|
| **AR-1** | **Three named gaps ship unenforced** — F2 (the check shape + the three `criteria` sub-objects), F3 (`required_edges[]`), F4 (the `lifecycle_behavior` value + the readiness/done `condition` prohibition). | **The naive close breaks `deploy.sh --check` on both control arms.** Measured with a structural cross-check: across all **15** `pack.toml`, **19 `[[kinds]]` × 3 = 57** criteria tables, **12** `checks =` keys (all empty), therefore **45 tables omit `checks` entirely** — both Check-75 discrimination fixtures among them. An **array-scoped** rule (*"`checks` absent-or-empty"*) fires on all 45, flipping `c75_spec_rc` and `c75_sens_rule`, and `deploy.sh:14199` increments `ISSUES` **outside** the warn-mode gate. An **entry-scoped** rule fires on **zero** entries and is trap-safe. The runner is therefore #6371's lint over the live pack root — a separate runner that never touches Check 75's fixtures. |
| **AR-2** | **Check 75 is warn-mode** (`deploy.sh:14146`, `:14170`), so no `PACK-*` finding blocks a deploy today. | Any fixed-surface claim reading as *"enforced"* is over-stated until the flip. Recorded in the F-table's `Posture` column rather than smoothed. **Qualified:** it does **not** hold for the discrimination branch at `:14199`, which blocks regardless of mode. |
| **AR-3** | **The `value_domain` "fail-loud" contradiction.** The grammar says further `[[controls]]` types are *"RESERVED (the §1.2.1 reserve pattern — fail-loud…)"*; an arm setting `value_domain = { type = "duration" }` returns exit 0 / COUNT 0. It fails **silent**. | Folded into C8's gap row rather than filed separately — a duplicate issue is governance debt, and the row is where a register reader looks. |
| **AR-4** | **`--resolve` has no arity for "resolved to no kit"** — `default_work_item_kit = ""` and an unnarrowed diagnostic view share one invocation. | Currently unobservable (**0** kits ship). Registered as a named-gap row by #6380 and **routed to ms 374** alongside #6371, whose lint is the natural runner. |
| **AR-5** | **`epic` does not declare `level_role = "grouping"`** though Layer-2 §2.2 and `intake-desk/type-map.md` both call it a grouping kind, while the validator emits `grouping=0 execution=4`. | **Out of scope** — it is a FIXED-key surface change, not content authoring. Routed, not taken. |

---

## Quota Budget

**Verdict: PASS on a fresh envelope; WARN if the window is ≥40% drawn at Engineering entry.** Per [`quota-budget-protocol.md`](/release/references/standards/quota-budget-protocol.md) § 3, Checkpoint A.

| Input | Value | Basis |
|---|---|---|
| Parallel-eligible spokes per parallel stage | Stage 5: **5** · Stage 7: **5** · Stage 8: **5** | Stage Applicability Matrix — all five ACTIVATE |
| Per-spoke cost estimate | ordinal band by `size` label: #6378 `S` lowest · #6363 `M` low–moderate · #6365 `L` **moderate–high** · #6366 `M` · #6380 `M` | § 5 ordinal floor — the § 5.1 cutover conditions to observed medians are **not met for any bucket**; no telemetry population exists |
| Assumed remaining usage-window envelope | **NOT STATED at hub start** → conservative default | `[ASSUMPTION – CONFIRM]` per § 6.1 |
| Estimated cumulative draw, worst parallel batch | **high-20s %** of a full window at 5 spokes weighted for one `size:L`; **materially lower** at the wave-respecting shape (worst batch 3) | Matrix + the wave sequence |
| **Routing** | **PASS** (<50%) on a fresh envelope; crosses into **WARN** (50–80%) once ~40% is already consumed — an ordinary mid-session state, so the WARN limb is not hypothetical | |

**Two honesty notes, both load-bearing.** First, every figure here is the retained **ordinal floor, not a measurement**. Second, **this estimate is advisory and is not the gate** — the gate is **Checkpoint B at Procedure 2 Step 5.5**, re-validated at every `Agent`-tool launch against the *remaining* envelope. A PASS here licenses nothing at runtime. This is a cumulative-draw budget, not a rate-limit problem; staggering launches does not reduce cumulative consumption and is not a mitigation on this axis. **See R-8: the host-API axis of Checkpoint B reads a dead gauge on this deployment.**

---

## Decisions Rendered

Every row is operator-rendered at a named gate unless marked *(rule-determined)*. Each also emits a `pipeline-event-log.md` row.

| ID | Verdict | Gate | Note |
|---|---|---|---|
| **D-PlanApproval** | **APPROVED** | Stage 4 Plan Review | Authorizes Procedure 1 scaffolding and wave-1 routing |
| **D-ReleaseClass** | **`cross-cutting`** | Stage 4 Plan Review | Dominant trigger (c), 6 edges; the definitional tension recorded above |
| **D-Sequence** | wave 1 `#6378` → wave 2 `#6363` → wave 3 `#6365`/`#6366`/`#6380` | Stage 4 Plan Review | The native edges require it; the "early start vs internal sequence" framing dissolved on evidence |
| **D-Concurrency Posture** | **P0 fully-serial** | Stage 4 Plan Review | Undeclared default, independently justified — the schema-file overlap is `line-range-overlap`, so ADR-005's append-pattern carve-out does not apply |
| **D-AC4** | **(A) reword to current capability** | Stage 4 Plan Review | #6363's AC4 is graded against *"the annotation is machine-readable and its absence is detectable by a reader over the whole population"*. **(B) was available and not taken** — it would have collapsed a ship-gating relationship into a build-gating one and idled work that could proceed. Body unamended per ADR-062 |
| **D-ContentHome** | **(A) content on the pack kinds** | Procedure 4, wave 1 | Deferred at Stage 4 to #6378's spike output, then rendered. Freezes the File Change Matrix; #6365/#6366 populate the existing `[kinds.criteria.*]` blocks and #6380 becomes a thin resolver |
| **D-6378-Rework** | **RE-SPAWN #6378 Stage 5** | Procedure 4, sub-wave 1 | Completion condition 4 broke on 4 of 8 candidates. Sub-task #6970 **reopened** rather than superseded, so the record says plainly that Stage 5 did not complete |
| **D-CIAC5** | **RESTATE** | Procedure 4, sub-wave 1 | As approved it graded an artifact that will not exist — a vacuous pass. Restated above |
| **D-Matrix** | **AMEND** — `core/standards/gate-efficacy-standard.md` added to **both** #6378 and #6363 | Procedure 4, sub-wave 1 | Matrix unfrozen for this one amendment and re-frozen after. Creates the new 2-way contention, which under P0 costs sequencing rather than correctness |
| **D-Subwave2** | **LAUNCH #6365 and #6366** | Procedure 4, sub-wave 1 | Accepted risk: both cite a boundary concurrently under rework. Mitigated in the briefs — each names which parts are **in flux** versus **stable**, and instructs citing only the stable parts |
| **D-R2-QualifierRestore** | **restore the scoping qualifier, cite §0, author nothing new** *(supersedes `D-R2-Reconcile`)* | Stage 5 close | §7.3's `Conditional` regains the *"a project's"* scoping §0 `:33` already carries. **No new statement of the rule is authored** — a second full statement would be the duplicate-source pattern. The earlier decision was rendered on a hub mis-classification of §0 `:37` as prohibiting when it permits |
| **D-PlacementTest-ToStage6** | **carry the repairs into Stage 6; no third design pass** | Stage 5 close | Three root causes plus Counter-test A's third arm. **The A6.5 reviewer's candidate set is Stage 6's acceptance evidence**; implementation reports placement on *both* sets |
| **D-ScopeLock** | **APPROVE** | Collective Review | All seven checks pass. Scope hard-locked through Stage 9; override requires a Decision Briefing with impact assessment |
| **D-AnnotationName** | **DEFERRED to Stage 6** | Collective Review | Retain `x-pmo-content-source` + a disambiguation note, versus rename to `x-pmo-practice-source`. **Engineering decides against the real diff, and must render it before #6365/#6366 commit** — the rename is cheap only while neither content card cites the annotation name (measured **0/0** today); that window closes when the content lands |
| **D-Version** *(rule-determined)* | **v4.53 → v4.54** | Stage 6 entry | Re-determined at Commit 0. Next-free is rule-computed, not a judgment call; the *collision* is the reportable event |
| **ADR allocation** *(rule-determined)* | #6378 → **185** · #6363 → **186** · #6380 → **187** | Procedure 4, sub-wave 1 | Sequential from the `origin/main` anchor of **184**, never `max(claimed)+1`. A three-way collision was resolved by wave order after #6363 and #6380 each recorded themselves as *"the second ADR on the branch"* |
| **Finding D-1 edges** *(rule-determined)* | `#6380 blocked_by #6365` · `#6380 blocked_by #6366` | Procedure 4, sub-wave 1 | Build-gating, not merely acceptance-gating. Hub adds edges; spokes do not |
| **D-C Branch Topology** *(rule-determined)* | **SINGLE** | Collective Review | The documented default; the operator's standing position is that a milestone ships as a single PR |

### Carried into Engineering — corrections no runner will catch

Recorded here because each is a claim a reader can falsify in one command, and none is caught by CI:

1. **#6378** — `criteria_version`'s **presence** is unenforced, not merely its format. An arm removing it from all nine blocks returns exit 0 / COUNT 0 against a live `PACK-K01` control on the same corpus. **C3's `Enforcing gate` cell is FALSE, not partial.**
2. **#6378** — `guards_transition` sits on **both sides** of the boundary. §1.2.1 prohibits `condition` on readiness/done; `guards_transition` is governed by **D-A** (`:253`), which binds all three sub-objects **including `gate`** — the one C11 calls configurable. A boundary document that places a key on both sides is the failure this card exists to prevent.
3. **#6378** — Check 62's denominator is **26** resolution pointers, of which only **15** sit inside register rows (across 10 of 41 rows); the extraction is **file-wide**, so the no-pointer rule binds §1.5's pointer prose too, not only the three rows.
4. **#6378** — the `PACK-K09` archetype carve-out's best discharge is **`check-work-hierarchy.py:2969`**, the dedicated `PACK-K06a` scoping arm, not `:3034`.
5. **#6366** — one `[kinds.fields]` block `source` string. Its claim that the Kanban Method *"prescribes no card field set"* is contradicted at `ticket-information-architecture.md`, and its causal clause fails against the grammar: a FieldDecl carries `required (✅/⚪)`, and **an optional field forbids nothing**.
6. **#6366** — **nine statements across seven sections** still carry the superseded `PRESERVE`, one of them a *"preserved byte-for-byte"* transcription instruction that would direct Engineering to do the **opposite** of `D-CriteriaVersion-BlockRule`. Confirmed by execution that `criteria_version = "NOT-A-SEMVER"` passes `--validate-packs` clean on the same file where `PACK-K01` fires — **nothing mechanical catches this.**
7. **#6363** — four worked `checks[]` entries in §1.2.1 (`gate-parent-epic-design-approved`, `gate-blocking-spike-done`, `gate-wip-pull-limit`, `gate-architecture-review-approved`), **0 of 4** carrying a `source` key, plus the §3.2 worked materialization. Under the card's own new rule the grammar would ship **five illustrations violating it**.
8. **#6365** — **four L2 checks to re-level to L3.** `automatable: false` suppresses nothing at L2: the projection rule carries the `automatable` conjunct on the **L1** arm only.
9. **#6380** — ADR-187 D3's ground 2. *"The field makes AC3 violable"* is **false**; AC3 is already violable through `limb_b`. The AC1 decision stands on a stronger ground than the one it loses.

---

## Operational Deployment Manifest

**N/A — enumerated over the three Layer-2 propagation classes; none present in this release.**

| Class | Present? | Basis |
|---|---|---|
| `*/skills/**` — S-2 direct copy | **No** | Zero `skills/` paths in the File Change Matrix |
| `packages/*.skill` + `.sha256` — package rebuild | **No** | No skill source changes, so no package is staled |
| `core/rules/**` — rules sync | **No** | Zero `core/rules/` paths in the matrix |

Stated as an enumerated set rather than a bare "no deployment targets", so the class nobody considered is visible rather than hidden.

### Schema Migrations

**N/A — enumerated over the two migration classes; neither fires.** (1) **Meta-schema version move:** none — the kit extension is additive-in-effect and meta-schema stays v1 per §6.2c; #6363 adds §6.2d on the same basis. (2) **Data migration:** none — `pack_version` and `criteria_version` bumps (`0.1.0 → 0.2.0`) are *data-level additive* changes under §6.1's no-force-migrate rule, not migrations.

---

## Deviation Log

Deviations from the Stage-4 plan of record, each with its ratifying authority. An empty row set would mean no deviation; these are recorded, not silent.

| # | Deviation from the Stage-4 plan | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **`domain_practice` upgraded Mode B → Mode A.** Stage 4 A1.5 emitted `{ source: UNSOURCED-DOMAIN, date: 2026-09-03, rationale: the platform encodes no Scrum Guide / INVEST / Kanban Method corpus, domain: process }`. **The premise is false at the pin:** `core/disciplines/work-organization-mapping-framework.md` §3.2 `:157` ships a Story best-practice default sourced by name to *Scrum Guide 2020 + INVEST (Cohn, "User Stories Applied")*, and `work-item-type-schema.md` §1.4 `:367` makes consuming it an **obligation**. #6365's Stage 5 adopted the shipped default rather than inventing a field set; **#6366's §5.7 upgraded the label to Mode A.** | Hub obligation recorded at the Stage-5 wave close and again at Collective Review: *"the §5.7 Mode B → Mode A upgrade for #6366 needs a release-plan deviation-log entry — the hub owes it and writes it into the plan file at Engineering Commit 0."* | **DISCHARGED HERE.** The Header carries the corrected Form-A label. The Stage-4 wording is preserved above so the delta is legible. **This was the fourth of five recorded hub errors of one class** — trusting a prior artifact's classification over live state — and it is corrected at the surface four downstream consumers read. |
| **DEV-2** | **Baseline pin moved `ef008d6d` → `5facfded`** and **D-Version moved `v4.53` → `v4.54`**. | Commit-0 version re-verify (Procedure 0 § Canonical location); rule-determined | **RATIFIED.** A concurrent release claimed `v4.53` during this milestone's Stage 5. Divergence re-checked against the current pin: 16 files touched, **overlap 0**, both arms recorded. Had Engineering written on the stale value it would have overwritten a shipped release's plan file. |
| **DEV-3** | **File Change Matrix amended and re-frozen twice after Stage 4.** (a) `core/standards/gate-efficacy-standard.md` added to #6378 and #6363; (b) `work-item-type-schema.md` §7.3 brought into #6378's scope. | (a) `D-Matrix`, sub-wave 1 close · (b) `D-R2-QualifierRestore`, Stage 5 close | **RATIFIED before Engineering.** Both folded into the matrix above with per-row authority. A declared-vs-delivered check against the Stage-4 matrix alone would report undeclared edits; against this matrix it is clean. |
| **DEV-4** | **#6380 DROPPED `core/schemas/work-item-type-schema.md` and all three `core/packs/*/pack.toml`** from its declared write set, and added `core/packs/README.md`, two fixtures, self-test arms and an ADR. | #6380 Stage-5 design; confirmed at Collective Review check 2 | **RATIFIED.** Consequence: the Stage-4 3-way `line-range-overlap` HIGH row on the 103 KB schema file becomes **2-way**, and the operator's recorded expectation that *"the two 2-way pack-manifest contentions do not materialize"* becomes true **by construction rather than by assertion**. |
| **DEV-5** | **CIAC-5 restated** from *"each pack's named default kit"* to the pack-resolved kind-set predicate. | `D-CIAC5`, sub-wave 1 close | **RATIFIED.** The approved wording graded an artifact #6380's AC1 disposition means will not exist — a vacuous pass, graded silently at Stage 9 QC3.5. |
| **DEV-6** | **#6378's Stage 5 did not complete on the first pass and was RE-SPAWNED**, then re-entered A6.5. Two A6.5 passes ran on this card against one on each of the others. | `D-6378-Rework`, sub-wave 1 close | **RATIFIED.** Sub-task #6970 was **reopened** rather than superseded by a new sub-task, so the record states plainly that the stage did not complete. |
| **DEV-7** | **The declared Release Class moved `routine` → `cross-cutting`.** | `D-ReleaseClass`, Stage 4 Plan Review | **RATIFIED at the Stage-4 gate.** Zero of `routine`'s four triggers fire; the definitional tension in `cross-cutting` is recorded above rather than smoothed. |
| **DEV-8** | **The #6378 ship-gate reconciliation target moved ADR-170 → ADR-180.** | Stage-4 G-PL1 finding (R-3), Tier 1 `[ADJUST]` | **RATIFIED.** The kit ADR was authored as ADR-170 on 2026-09-01 and renumbered 170→171→177→**180** on 2026-09-03T00:17–00:23, after the 2026-09-02 sweep wrote the reference. Slot 170 now holds an unrelated portfolio-framework ADR. The renumber is **governed behaviour, not a defect**; the reference was stale. |

| **DEV-9** | **Two transcription-level rendering changes made so the mechanical checks can grade at all**, both predicate-preserving. (a) The per-issue Verification-Plan `Method` cells were authored as **runnable probes with thresholds** rather than as prose reads. (b) CIAC-2's *"expecting zero hits"* was rendered as *"expect 0 hits"*. | [`stage-04-planning.md`](/release/references/pipeline/stage-04-planning.md) § Cross-Issue Acceptance Criteria: *"Author the command exactly as the matcher must receive it."* | **RATIFIED by the spec's own authoring instruction; recorded here because it is a change to approved text.** Measured, not asserted: `verify-release-plan.sh` classifies a method by keyword and reports a prose method as `unclassified-method` → **ERROR**, which never grades — as distinct from a FAIL, which does. **Control arm over the shipped corpus:** v4.53 shipped **8 ERROR over 9** per-issue rows and v4.52 **15 over 15**, while v4.51 shipped **0 over 8** — so prose methods are the corpus norm *and* the classified form is demonstrably achievable. CIAC-2's threshold token is the same class: `extract_threshold` matches the literal `expect zero` or `expect <N>`, and *"expecting zero hits"* matches neither, so the row fell through to the exit-status limb where `grep`'s exit 1 for *no matches* — the **desired** outcome — reads as FAIL in perpetuity. **No predicate changed in either case.** |

| **DEV-10** | **#6363's corpus content lands across six commits rather than one**, against § Implementation Sequence's *"Each card lands in its own commit, distinct from Engineering Commit 0, so any card reverts independently."* The six are the §1.2 / §1.2.1 rule and worked examples · the §3.1 / §3.2 projection · §6.2d · the README and register · ADR-186 · one `fix(...)` closing a Check-63 finding. | Stage-6 write-early discipline on the spoke channel: a pushed commit is durable and a re-spawned spoke resumes with the work banked, where a single terminal commit loses everything on a mid-run failure. The branch's own wave-1 practice already split a card across a content commit and two `plan(...)` commits. | **RECORDED, and the plan's intent is preserved rather than defeated.** Every commit references #6363 and touches only this card's declared paths, so the card still reverts independently — as a named contiguous range rather than as one SHA. The § Verification Evidence block below names the range. |

**No `NOT DELIVERED` row exists at Commit 0.** Every unconditional `add` in the matrix is expected to ship. A declared ADD that legitimately does not ship gains a row here carrying the literal `NOT DELIVERED` and its declared path — the row is what converts the `fcm-delivery` finding into a pass.

---

## Verification Evidence

*Populated at Stage 6 Phase C4 self-verification, per card, before handoff to Dev Testing.*

### #6378 — C4 self-verification (executed 2026-09-04)

| Check | Verdict | Observed |
|---|---|---|
| `deploy.sh --check` **Check 62** (gate-coverage register runner-resolution) | **OK** | *"all 26 gate-coverage register resolution pointer(s) resolve"* — **26 before and after the three added rows**, exactly as predicted. A named-gap row correctly carries no pointer, so the verdict is unmoved |
| `deploy.sh --check` **Check 75** (pack-grammar conformance) | **OK** | `0 findings (packs_read=3 kinds_read=4 rules_evaluated=20)`, and its own **CTRL** line reports `sensitivity exit=1 rule='PACK-K05'` / `specificity exit=0` — **both discrimination arms intact.** The Check-75 trap was not tripped, which is the whole reason no rule was minted |
| `deploy.sh --check` overall | exit 0, **2 issue(s)** | Neither is in this write set: `release-body-drift` (13 findings across 77 logged releases) and `count-structure` (three named paths, none of them a file this release touches). Both pre-existing |
| `check-work-hierarchy.py --validate-packs --pack-root core/packs` | **`COUNT 0`, exit 0** | The live corpus is untouched and still validates |
| `claim-version.sh --verify-stamp` | **exit 0** | `verify-stamp OK` |
| `verify-release-plan.sh` provenance-survival | **3 PASS + PROV-DELTA PASS** | `form=A date=2026-09-04`; `prov-no-loss (comment_elements=3 all present in the plan)` |
| `renumber-adr.py --detect` | **ADR-185 BINDS** | `ANCHOR 184 · NEXT-FREE 185` |
| `check-adr-durability.py` | **0 findings** | One `R2-COUNT` finding on a drifting live-corpus count was raised and fixed by citing the deriving command |
| `check-release-links.py --check-anchors` | **0 broken links** | One warn-mode missing-anchor on the explicit `{#…}` heading anchor — a **standing corpus-wide condition**, not introduced here (control: an existing cross-reference to another discipline file warns identically) |
| Falsification arms | **21 arms executed** | Every run self-reported `packs_read=3 rules_evaluated=20`; every subject zero paired with a control firing on the same corpus and invocation. One arm self-rejected on its landed-check and was discarded rather than reported |
| PR-body parser self-check | **CLEAN** | 1 close-family + `#N` occurrence, inside the Issue References block only; control — 13 bare `#NNNN` references, so the reader is live |

### #6363 — C4 self-verification (executed 2026-09-04)

**Corpus-content commits — enumerated rather than given as a range endpoint, so the record cannot go stale as later commits land:** `f97b2df1` · `5a123da0` · `6dfc2316` · `f938aca6` · `a643ee04` · `edca9dff` — six, five authoring and one `fix(...)` closing a check finding (see DEV-10). Every one references #6363 and touches only this card's declared paths, so the card reverts as that enumerated set. The `plan(...)` commits interleaved with them are the A2 *plan update* special sub-task, exactly as wave 1 carried its own.

| Check | Verdict | Observed |
|---|---|---|
| `check-work-hierarchy.py --validate-packs --pack-root core/packs` | **`COUNT 0`, exit 0** | `packs_read=3 kinds_read=4 rules_evaluated=20` — the live corpus is untouched by this card and still validates |
| `claim-version.sh --verify-stamp kit-content-and-defaults` | **exit 0** | `verify-stamp OK — carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file targets)` |
| **`lint_release_corpus.py --check plan-identity`** | **exit 0** | No FAIL line; **zero** findings name this plan. `PLAN-STATUS-DENOM` reports the enum `ACTIVE\|CLOSED\|ABANDONED`; the plan reads `ACTIVE`, a valid member. **This is the tool the wave-1 spoke's self-chosen set could not see** — it is run here because the C4 set is prescribed, not selected |
| `lint_release_corpus.py --check plan-identity` — **falsification arm** | **fires** | Mutated the plan's frontmatter to `status: IN-FLIGHT` → **exit 1**, `PLAN-STATUS-ENUM: … carries status: 'IN-FLIGHT' — the enum is ACTIVE\|CLOSED\|ABANDONED`, naming this plan. Restored byte-identical (`git status` clean). Opposite-verdict pair on the exact predicate |
| `lint_release_corpus.py --self-test` | **49 arms, 0 failures** | Includes its own anti-vacuity arm (`F-4`: the pre-change model disagrees on 6 of 7 fixture cases, so `F-3` discriminates) |
| `verify-release-plan.sh` | **12 PASS / 8 FAIL / 7 SKIP / 0 ERROR** | **0 ERROR is the load-bearing figure** — every method still classifies. The 8 FAIL are waves 3a/3b/3c, unstarted by construction: `#6365`/`#6366`/`#6380` per-issue rows and `FCM-3/4/5` (#6380's declared ADDs). **`FCM-2` PASS** — `declared-add-delivered: core/ADRs/ADR-186-kit-content-provenance-key.md`. `PROV-PRESENCE` / `PROV-GRAMMAR` / `PROV-COVERAGE` PASS (`form=A date=2026-09-04`) |
| `renumber-adr.py --detect` | **ADR-186 BINDS** | `ANCHOR 184 (origin/main) · NEXT-FREE 185`; branch claims 185 and 186, both `BINDS BRANCH-CLAIM`. Run **first**, per the numbering rule; the hub's allocation is the anchor, never `max(claimed)+1` |
| `renumber-adr.py --stamp --check` | **2 residual tokens, 0 in link position** | The expected pre-Stage-12 state per the citation rule: `{{ADR:kit-content-provenance-key}}` appears twice in §6.2d, in prose. **Zero in link position** is the property that matters now — a token in a link target is parsed as a path and reported as a broken cross-reference. No workflow runs `--stamp`; the residual resolves at the Stage-12 claim |
| `check-adr-durability.py` | **0 findings on ADR-186** | Corpus total fell 25 → 23 — exactly the two this card raised and fixed. **Control arm live:** 21 `R2-COUNT` findings still fire elsewhere, so the detector is not passing vacuously. Both fixes were historical anchors on genuinely point-in-time counts, not suppressions |
| `generate-adr-index.py --verify` | **`COUNT 0`** | **ADR index: N/A** — this release adds no record under `release/ADRs/`; ADR-186 lands under `core/ADRs/`, which has no projector and no projected region |
| `check-release-links.py --check-anchors` | **0 broken links** — **and the pass is VACUOUS for this card, stated as such** | `=== 0 broken links across 0 files ===`. The checker is scoped to `release/`; this card's write set is `core/`, so it examined **nothing of mine**. A guard that passes on empty input has told you nothing, so the doc-link verdict for this card comes from Check 14 below, not from here |
| `deploy.sh --check` **Check 14** (doc-link maintenance) | **OK** | *"no broken cross-refs in scope"* — the governance + SKILL.md scope that does cover `core/` |
| `deploy.sh --check` **Check 62** (gate-coverage register runner-resolution) | **OK** | *"all 26 gate-coverage register resolution pointer(s) resolve"* — **26 before and after this card's row**, exactly as predicted. A named-gap row correctly declares no `runner-def:` pointer, so it never joins Check 62's population and the verdict is unmoved. Anti-vacuity holds: the register carries 23 declared pointers, so the `NOSET` arm cannot fire |
| **Check 75 discrimination arms** (reproduced verbatim from `deploy.sh`, same binary, same fixtures) | **INTACT — the trap was not tripped** | sensitivity(`nonconforming-kit`) **exit 1, rule `PACK-K05`** · specificity(`conforming-kit`) **exit 0** · live corpus **exit 0, no rules**. The `FAIL` arm that increments `ISSUES` **outside** the warn-mode gate does **not** fire. **Fixture invariant re-measured and unchanged:** both control fixtures still carry `checks` **0** and `kind_specific` **0**; neither was touched by this card |
| **Falsification arms — the observable this card registers** | **opposite-verdict pair on the observable; SAME-verdict pair on the gate** | Four scratch corpora, every mutation verified landed before the run. *Block altitude:* `source` injected at all 15 present-and-empty tables → extraction reports **15 sites, 0 source-less**; one removed → **15 sites, 1 source-less**, naming its `file:line`. *Entry altitude:* a `checks[]` entry + a FieldDecl authored **with** `source` → **0 source-less**; the identical pair **without** → **1 and 2**. `--validate-packs` returns `COUNT 0`, exit 0 on **all four**, identically. **Validator control arm, same corpus and invocation:** renaming `[kinds.lifecycle_behavior]` away at 3 sites → **`PACK-K01`**, exit 1, `COUNT 3`. Every run self-reported `packs_read=3 kinds_read=4 rules_evaluated=20` |
| **Population re-derivation (sixth independent reader)** | **16, reconciled twice** | Structural block walk over all **15** `pack.toml`: **19** `[[kinds]]` · criteria **12** present-empty / **0** present-non-empty / **45** absent = **57 = 19 × 3** · fields **3** present-empty / **1** non-empty / **15** absent = **19** = one table per kind. **12 + 3 + 1 = 16**, all 16 sites enumerated, all in `core/packs/{scrum,kanban}`. Sensitivity `criteria_version` **57**; specificity `zzq_not_a_real_key` **0**; subject `^source =` **0 / 0** |
| **No-runner re-derivation** | **holds** | `checks` **0** · `automatable` **0** · `statement` **0** in `check-work-hierarchy.py`, word-bounded; controls on the same reader `criteria_version` 3 · `kind_specific` 2 · `lifecycle_behavior` 3 · `KIND_REQUIRED_FIELDS` 2 · `kind_id` 42 · `criteria` 5; specificity `zzq_fabricated_token_7731` **0**. `KIND_REQUIRED_FIELDS` = **9** members (re-derived from its literals), `PACK_RULE_IDS` = **20**. **Third arm:** the corpus *does* contain the constructs such a rule would read (12 present-and-empty blocks, 1 FieldDecl), so the zero is a property of the reader set, not of an absent population |
| **Prohibition arms — the four judgments the design flagged as likeliest to be "helpfully" undone** | **all four hold, each with a live control** | (1) *"is a pack-validation error"* in the provenance block **0**, against **12** file-wide (control live) and an in-block sentinel firing **1**. (2) *"cannot carry provenance"* **0**, against *"property-level keyword"* **1**. (3) `MUST` in the limits paragraph **0**, against **1** in the rule paragraph and a limits-sentinel firing **1**. (4) absence-form *"absent from"* in this card's falsification cell **0**, against **1 each in all three** sibling named-gap rows on a markup-insensitive reader (control live); positive form *"the compliant path emits"* **1**, matching the register row this one is modelled on |
| **Consistency arms — the stated-count forms** | **clean** | *"four base fields"* **0** / *"five base fields"* **1** · *"The 4 existing fields"* **0** / *"The 5 base fields"* **1** · specificity *"seven base fields"* **0**. All four §1.2.1 worked check entries carry a `source` (**4 of 4**, from **0 of 4** at the merge-base), against a live sensitivity arm of **5** `statement:` occurrences |
| Runtime-suite selection | **`test-run/suite-skip` — emitted, not merely declared** | Selection-map **row 6 (no match)**, enumerated rather than assumed: the write set is `core/schemas/`, `core/standards/`, `core/packs/`, `core/ADRs/`, `release/releases/plans/` and matches **none** of rows 1–5. Event appended to the pipeline event log (`stage=6`, `actor=spoke:#6363`, `subject=issue:#6363`) |
| Skill-package freshness | **N/A, enumerated** | Zero `skills/**` paths and zero `packages/**` artifacts in this card's write set, so no package is staled and none is rebuilt |
| Deployed-copy sync (C3) | **N/A, enumerated** | All three Layer-2 propagation classes checked (`*/skills/**`, `packages/*.skill`, `core/rules/**`); none fires. `deliverable_state: artifact-accepted` |
| `deploy.sh --check` **Check 63** (count-structure) | **CAUGHT TWO OF MINE, FIXED, RE-VERIFIED** | The first full run flagged `ADR-186:70` and `work-item-type-schema.md:800` — a stated numeral sitting immediately before a structure of a different size (`stated=[0,0] items=4 (list)`; `stated=[4] items=8 (table)`). Both sentences were correct and the **adjacency** was not, so both were repaired the way the check prescribes — correct the count or the structure, **never** add a baseline row for new drift. Re-verified: `FAIL=3`, the pre-existing baseline of three named paths, and **zero** findings name any file this card touches. **Control arm live** — the checker still fires on all three pre-existing paths and still classifies 71 `KNOWN` rows. **This is the finding the prescribed tool set exists to catch:** none of the other ten tools reads it |
| `deploy.sh --check` overall | **exit 0**, back to the pre-existing **2 issue(s)** | `release-body-drift` (13 findings across 77 logged releases) and `count-structure` (three named paths, none of them a file this card touches). Both pre-existing and both unchanged from the wave-1 reading. The first run read 2 issues with `count-structure` carrying **five** paths — two of them mine; the fix above returns it to three |
| PR-body parser self-check | **CLEAN** | Close-family verb + `#N` occurrences: **2**, both inside the Issue References block, **0** elsewhere. Control arm live — the reader finds bare `#NNNN` references outside the block |

**Two probe defects were self-caught and are published rather than smoothed.** (1) A block-scoped reader used an end anchor missing a trailing period inside the bold markers, so `str.find` returned `-1` and the "block" silently became *the rest of the file* — reporting **4** occurrences of a phrase the block does not contain. Corrected by asserting every anchor index is non-negative and ordered, and by printing the block length against the file length. (2) A polarity control arm searched for `absent from` where the corpus writes `**absent** from`; the markdown emphasis blinded the substring reader and the control returned **0**, so the subject zero rested on nothing. Corrected with a markup-stripping reader, after which all three sibling rows fire. **Both are the same hazard: a control arm proves the reader is live, not that the pattern encodes the right mechanism.**

**ADR index:** this release adds **three** records under `core/ADRs/` — ADR-185, ADR-186, ADR-187 — allocated sequentially from the `origin/main` anchor of 184. `renumber-adr.py --detect` is run **first** by each authoring spoke; branch claims are detection-only and non-binding.

---

## Change Description

*Scaffolded at Engineering Commit 0; authored in full at Stage 6 Phase C1 per [`RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Change Description Protocol, before the draft PR transitions to ready-for-review at the Stage 9 gate. Operator-facing voice.*

### Outcome

A methodology pack can already declare kinds, fields and criteria — but nothing said which of those a methodology owns and which the platform fixes, so an author had no way to tell an over-reach from an under-delivery until a second methodology was written against the boundary. This release writes the boundary down, makes every authored criterion carry the named body of practice it came from, fills the twelve empty criteria arrays in the shipped Scrum and Kanban packs with content sourced from the Scrum Guide, INVEST and the Kanban Method, and states what a pack resolves to when no kit is selected.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| **#6378** | The grammar now says which of a pack's declarations a methodology owns and which the platform fixes — with a test an author applies to a new field, and three invariants the platform states but does not yet enforce recorded as named gaps rather than left invisible | **DONE** |
| **#6363** | Every authored criterion and field carries the body of practice it came from, so its source is auditable rather than asserted — declared at two altitudes, projected as a new annotation class, and registered as a named gap because nothing enforces it yet | **DONE** |
| **#6365** | The Scrum pack's empty criteria arrays are filled from the Scrum Guide and INVEST | *pending — wave 3* |
| **#6366** | The Kanban pack's empty criteria arrays are filled from the Kanban Method, with the pull-limit gate deliberately left as a stub | *pending — wave 3* |
| **#6380** | A pack's default is the kind set it declares — stated, and exercised by fixtures that prove a pack resolves to its own kinds and not a sibling's | *pending — wave 3* |

### Key decisions

- **D-ContentHome: (A) content on the pack kinds.** Deferred at Stage 4 to #6378's spike output and rendered on its evidence rather than ahead of it. It is what froze the File Change Matrix.
- **D-AC4: (A) reword to current capability.** Option (B) — a Stage-13 ship-gate on a later milestone — was available and not taken, because it would have collapsed a ship-gating relationship into a build-gating one and idled work that could proceed.
- **D-R2-QualifierRestore** *(supersedes `D-R2-Reconcile`)*: a failure-mode entry regains the scoping qualifier §0 already carries and cites §0 rather than restating it. The earlier decision was rendered on a mis-reading of §0 as prohibiting when it permits; correcting that shrank the work from authoring a new reconciliation to restoring one word.
- **D-PlacementTest-ToStage6:** the placement test's repairs land during implementation rather than in a third design pass, and **the adversarial reviewer's independent candidate set is the acceptance evidence** — implementation reports placement on both sets.
- **D-CIAC5: restate.** As approved, one cross-issue criterion graded an artifact that will not exist — a vacuous pass, and the silent kind. It now binds to a predicate executable today.
- **D-Version: v4.53 → v4.54** *(rule-determined)*. The Commit-0 re-verify caught a real collision; see § Commit-0 Version Re-Verify Record.
- **D-AnnotationName: RETAIN `x-pmo-content-source` + ship a disambiguation table** *(deferred by the operator at Collective Review to Stage 6, rendered there against the real diff)*. Both candidates measured at zero corpus citations, so the call was genuinely open in either direction. **The design's stated ground for retaining did not survive measurement** — *"every sibling names the annotated thing"* is false across the annotation family — so the retention is re-grounded on three things that do hold: the containment criterion that rejected an earlier candidate does not fire on either of these, so it selects nothing; the entry object's practice-bearing member is already named `practice`, which the alternative stem would stutter against; and the corpus's own remedy for a **strictly worse** collision — an identical field name carrying two meanings — is a disambiguation note rather than a rename. **The deferral's timing premise is also corrected:** the window does not close when the two content cards commit, because neither cites the annotation name; it closes at the first materializer implementation, and none exists.

### Deliverable state

**`artifact-accepted`** for **#6363** — the deliverable is the provenance grammar itself, at its declared canonical paths (`core/schemas/work-item-type-schema.md` §1.2 / §1.2.1 / §3.1 / §3.2 / §6.2d, one named-gap row in `core/standards/gate-efficacy-standard.md`, an extended sourcing bullet in `core/packs/README.md`, and `core/ADRs/ADR-186-kit-content-provenance-key.md`). Same basis as #6378's: the release has no Layer-2 propagation target, so `deployed-copy-synced` would be a fiction.

**`artifact-accepted`** for **#6378** — the deliverable is the boundary record itself, at its declared canonical paths (`core/schemas/work-item-type-schema.md` §1.5 + §7.3, three rows in `core/standards/gate-efficacy-standard.md`, a pointer in `core/packs/README.md`, and `core/ADRs/ADR-185-*.md`). Work whose definition of done **is** the artifact reaches this state, not `deployed-copy-synced`: the release has **no** Layer-2 propagation target (§ Operational Deployment Manifest enumerates all three classes and none fires), so declaring a deployed-copy state would be a fiction. The Artifact-Acceptance Record rows are populated in § Verification Evidence above.

### Reversibility

**CHEAP — HIGH confidence.** `git revert -m 1` of the merge commit. Every card is additive; no file is deleted, no path relocates, no consumer contract narrows, no meta-schema version moves.

### Downstream impact

- **It unblocks the two content cards.** Both must cite the boundary in their acceptance (CIAC-4), and both authored against it while it was still under revision — which is why their briefs named what was in flux versus stable.
- **It hands the next milestone a specified runner.** The three named gaps are not left as prose: each carries a declared observable and an executed falsification arm, so the content-completeness lint has a written contract to build against rather than a re-derivation.
- **It records a trap that would otherwise be re-hit.** The deploy-time conformance check's discrimination branch increments its issue counter outside the warn-mode gate, so an array-scoped completeness rule hard-fails on both control arms. That is now written down with its measurement, in the ADR and in the register rows.
- **Consumer impact is narrow by construction.** No `PACK-*` rule id is minted, so the reachable verdict set of the pack-conformance check is unchanged; no skill, package, hook or deploy gate changes; and the register's own verdict is unmoved at 26 resolution pointers.

### Cross-references

- Release plan: this file
- Milestone: `kit-content-and-defaults`
- User-facing release notes: authored at Stage 13 Close per [`release-notes-standard.md`](/release/references/standards/release-notes-standard.md)

---

## Issue References

<!-- repo-integrity: allow-issue-ref -->

- **#6378** — *Decide the boundary between methodology-configurable and platform-fixed.* `size:S` / `type:spike`. Six completion conditions; the durable output is a new §1.5 in the type-pack grammar plus three named-gap rows in the gate-coverage register.
- **#6363** — *Carry provenance on kit content so its source is auditable.* `size:M`. Declares `source` as the fifth base field on every `criteria.checks[]` entry and every `fields.kind_specific[]` FieldDecl, projecting as `x-pmo-content-source[]`.
- **#6365** — *Author the Scrum-shaped kit content.* `size:L`. Nine criteria arrays across three kinds.
- **#6366** — *Author the Kanban-shaped kit content.* `size:M`. Three criteria arrays on one kind, with the pull-limit `gate` block deliberately preserved as a stub.
- **#6380** — *Ship a default kit with every methodology pack.* `size:M`. Resolves to "a pack's default is the kind set it declares"; adds two fixtures and four self-test arms.
- **#6909** — Stage 4 Release Planning sub-task; the plan source and the operator decision record.
- **#6970** / **#6974** / **#6978** / **#6982** / **#6986** — Stage 5 Solutioning sub-tasks for #6378 / #6363 / #6365 / #6366 / #6380.
- **#6971** / **#6975** / **#6979** / **#6983** / **#6987** — Stage 6 Engineering sub-tasks.
- **#6990** — Stage 9 Plan Review (release-scoped).
- **#6371** — *Lint packs and kits for content completeness.* OPEN in `pack-conformance-and-parity` (ms 374); the intended runner for this release's three named gaps. Out of scope here.
- **#1971** — Kanban pull-limit gate; ms 374. CIAC-3 is the seam that keeps this release from pre-empting it.
- **#6358** — the parent epic.
