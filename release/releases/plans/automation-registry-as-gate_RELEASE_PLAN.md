<!-- reference-durability: allow-link -->
---
title: Release Plan — automation-registry-as-gate (the automation registry is the admission gate)
type: release-plan
plan_type: release
status: EXECUTING
release: "{{RELEASE_VERSION}}"
milestone: 379-automation-registry-as-gate
release_class: cross-cutting
reversibility: CHEAP rollback (additive; `git revert -m 1` on the release merge commit) / Confidence HIGH
---
# Release Plan — `automation-registry-as-gate`

**Topology:** D-C SINGLE — one release branch (`release/automation-registry-as-gate`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (operator-ratified) — Stage-6 slices route one at a time in Implementation-Sequence order on the single branch; no force-push (including `--force-with-lease`) on the shared branch.
**Release class:** `cross-cutting` (D-ReleaseClass, operator-rendered; dominant trigger (c) — four hard in-bundle compositional edges). Engagement density **Tight** · Stage 9 depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.
**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-02, domain: governance }` — Form X, sourcing-exempt, determined at Stage 4 Phase A1.5. The entire File Change Matrix is internal pmo-platform artifacts (a governance data surface, its enforcement gate, an operator-config seam, and protocol-doc migrations); secondary domain `software` noted for the adapter and the gate predicate. No Mode B→A upgrade is possible — the design depends on internal platform conventions, not external practice, so the label travels unchanged.

> **Provenance.** This file transcribes the Stage-4 Release Planning output, reconciled to the operator's Procedure-0 plan-approval decision and to **all three Release Plan Amendments** (post-Stage-5 Wave 0; post-Stage-5 sub-wave 1; Stage 5 complete / entering Engineering). Where an amendment supersedes a Stage-4 determination, the amended form is transcribed here and the § Deviation Log records the delta. Authored at Engineering Commit 0 by the first Engineering spoke (issue #5858, Wave 0).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). |
| **Date Created** | 2026-09-03 (Thursday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/automation-registry-as-gate` |
| **Baseline pin (branch base)** | `origin/main` @ `0bea01515cc19e0fafe6a62b42d0b2e01a55fcff` (Engineering Commit 0 instant, 2026-09-03) |
| **Stage-4 A0 pin** | `origin/main` @ `4f7e1ce3` (2026-09-03T00:37:44Z) · **Stage-5 design pin** `0b04639e` (2026-09-02) |
| **PR** | populated at Stage 6 Phase C2 (created `--draft`; transitioned to ready at the Stage 9 gate) |
| **Milestone** | `automation-registry-as-gate` |

**Version identity.** The `**Version**` cell carries the literal `{{RELEASE_VERSION}}` stamp-manifest token per ADR-092. It is a machine-read manifest, not prose: `claim-version.sh --verify-stamp automation-registry-as-gate` asserts it pre-commit, and the Stage-12 CAS-win path resolves it to the won tag and renames this file under the major-version plans directory. The token is why a lost version slot costs one re-derivation and zero corpus sweeps — the recorded determination moved twice during this release (`v4.48 → v4.49 → v4.50`) at zero sweep cost.

---

## Scope

### Summary

Five issues, one near-linear chain. An ADR fixes the what/how/who decoupling (#5858), a schema plus validator gives the registry a data surface (#5859), a gate makes the registry non-optional (#5861), an adapter makes firing portable (#5860), and the existing consumers migrate onto it (#5862). The milestone's sequencing claim — *#5858 first* — is **CONFIRMED**; its *independent of other lanes* claim is **REFUTED as a file-contention claim** (four in-flight siblings intersect this release's surface) and holds only as an issue-dependency claim, where it is true: no bundled issue is `blocked-by` or `blocking` any issue outside the milestone.

### Capability Outcome

An automation is admitted to the platform only if it carries a validated registry row, and no surface in the release names a firing backend directly — not the migrated consumers, and not the registry itself. The install path stops hardcoding a host scheduler.

### Issues Included

| # | Issue | Title (short) | Size | Wave |
|---|-------|---------------|------|------|
| 1 | #5858 | Record the registry-as-gate decision and the what/how/who decoupling | S | 0 |
| 2 | #5859 | Routine-spec registry schema + validator | M | 1 |
| 3 | #5861 | Registry-currency gate (deploy + CI) | M | 2 |
| 4 | #5860 | Scheduler adapter at the `[adapters]` seam | L | 2 |
| 5 | #5862 | Migrate the hardcoded-backend consumers onto the registry | M | 3 |

---

## Dependency Graph

Directional; edges derived from AC text, not from the milestone description's assertion.

| Edge | From → To | Class | Evidence |
|---|---|---|---|
| **E0** | #5858 → {#5859, #5860, #5861, #5862} | **Design-binding, NOT build-blocking** | #5858's Notes: *"Cut as the first slice… the later slices author against its decision."* Its AC is self-contained, so it does not mechanically block a build — but the decoupling it fixes is the premise all four implement |
| **E1** | #5859 → #5860 | **HARD** | The adapter fires what the routine spec declares; #5860 AC-1 ("one routine declared once runs end-to-end") presupposes the declaration format |
| **E2** | #5859 → #5861 | **HARD** | #5861 AC-3: the gate's verdict names *the missing entry* — the gate must know the entry shape to name its absence |
| **E3** | #5859 → #5862 | **HARD** | #5862 AC-2: each migrated cadence *has a registry entry* — no schema, nothing to register into |
| **E4** | #5860 → #5862 | **HARD** | #5862 AC-3: at least one migrated cadence *fires through the adapter* |
| **E5** | #5862 → #5861 | **SOFT (verification-direction)** | #5861's gate is vacuous over an empty registry; #5862 supplies the real populated set. Not build-blocking in either direction; graded by CIAC-4 |

**Circular chains: zero.** The 6-edge set was topologically sorted; the sort ordered all 5 nodes (denominator 5 nodes / 6 edges). Sensitivity arm: injecting a synthetic `#5862 → #5859` edge leaves 4 nodes unordered, so the detector fires. The zero is a measurement.

---

## Implementation Sequence

Stage-6 Engineering is write-serialized under D-C SINGLE, so this is a strict commit order. Waves matter for the parallel stages (5 / 7 / 8).

| Wave | Order | Issue | Size | Why here |
|---|---|---|---|---|
| **0** | 1 | **#5858** | S | Founding ADR. Wave 0 by convention and by E0 — every later slice cites its decision. Also the earliest point to resolve the ADR-number contention (R-2) |
| **1** | 2 | **#5859** | M | The data surface three other issues consume. Sole predecessor of E1/E2/E3 |
| **2** | 3 | **#5861** | M | Sequenced **before** #5860 despite being parallel-eligible with it: it touches `core/deploy/deploy.sh`, which two siblings are also editing (R-4), so landing it earlier shortens the rebase-exposure window |
| **2** | 4 | **#5860** | L | Adapter. Parallel-eligible with #5861 at Stages 5/7/8 (disjoint surfaces); serialized after it at Stage 6 only by the write-serialization rule |
| **3** | 5 | **#5862** | M | Terminal by E3 + E4 — needs both the schema and the adapter. Its control-armed grep AC is the release's end-to-end proof |

Placing #5861 before #5860 within Wave 2 is a **sequencing preference, not a constraint** — both are unblocked once #5859 lands, and an operator may swap them without violating any edge. The tiebreak is contention exposure only.

---

## Stage Applicability Matrix

| Issue | S5 | S6 | S7 | S8 | S9 | S12 | S13 | Skip rationale |
|---|---|---|---|---|---|---|---|---|
| **#5858** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Not trivial: the ADR names rejected alternatives and fixes a three-way decoupling. DT is real — the ADR-number and durability checks are machine-executable; AC-3's registration limb is human-graded |
| **#5859** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | New schema + validator; functional impact by construction (a malformed entry must be rejected) |
| **#5860** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Largest design surface in the release; AC-1 is "run it" |
| **#5861** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | A gate must be falsification-tested per the gate-efficacy standard; DT is where the falsification repro runs |
| **#5862** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Migration with a control-armed grep AC — directly DT-executable |

**No stage is skipped for any issue.** The skip predicate was evaluated over all 5 issues × 2 skip conditions = 10 evaluations; 0 fired. Sensitivity arm: the same predicate applied to a hypothetical typo-fix card fires the Stage-5 triviality condition, so it discriminates. Under `cross-cutting`, Stage 5 activation bias is **ALL**, which independently corroborates the result.

**Parallel-eligible spoke counts:** Stage 5 = 5 · Stage 7 = 5 · Stage 8 = 5.

---

## File Change Matrix

Per the declared-vs-delivered authoring contract: intent markers normalize to `add | edit | delete`; a marker-less path is `unknown`, never `edit`. Placeholder paths (`<…>`) are the recognized placeholder form and are resolved by the owning issue's own Stage 6 — Stage 5 fixed every path it decided and left the rest honestly unfixed rather than inventing a name.

```
# ── #5858 — founding ADR (Wave 0) ──
core/ADRs/ADR-181-automation-registry-is-the-gate-what-how-who-decoupled.md   add
core/ADRs/README.md                                                          edit
release/releases/plans/automation-registry-as-gate_RELEASE_PLAN.md            add

# ── #5859 — registry schema + validator (Wave 1) ──
core/schemas/automation-registry-schema.md                                   add
core/automations/registry.md                                                 add
core/deploy/tools/<registry-validator>.sh                                    add
core/config/allowlists/script-execution-allowlist.txt                        edit
core/schemas/README.md                                                       edit
core/deploy/tools/README.md                                                  edit

# ── #5861 — registry-currency gate, deploy + CI (Wave 2) ──
.github/workflows/automation-registry-currency-check.yml                     add
core/deploy/tools/check-automation-registry-currency.sh                      add
core/deploy/deploy.sh                                                        edit

# ── #5860 — scheduler adapter (Wave 2) ──
core/deploy/tools/resolve-automation-binding.sh                              add
core/config/operator.toml.template                                           edit
core/config/operator-toml-schema.json                                        edit
core/specs/<scheduler-adapter-spec>.md                                       add

# ── #5862 — consumer migration (Wave 3) ──
release/references/protocols/platform-health-audit-framework.md              edit
release/references/protocols/architecture-conformance-cadence.md             edit
release/references/protocols/process-fitness-cadence.md                     edit
release/references/protocols/structural-audit-cadence.md                     edit
core/standards/c2-intake-sweep-path-a.md                                     edit
core/standards/c3-external-sync-path-b.md                                    edit
core/standards/agent-handoff-framework.md                                    edit
core/specs/anthropic-base-vs-build-registry.md                               edit
docs/INSTALL.md                                                              edit
```

#### Read-only inputs

```
release/references/protocols/decision-audit-cadence.md                       READ
core/skills/registry.md                                                      READ
.github/workflows/skill-registry-currency-check.yml                          READ
core/deploy/tools/check-registry-currency.sh                                 READ
```

#### Release-wide explicit non-scope

```
release/releases/plans/*_RELEASE_PLAN.md                          NOT EDITED
```

The three release-plan files under `release/releases/plans/` that carry the hardcoded backend token are **frozen historical audit trail** and must not be edited by #5862. `decision-audit-cadence.md` is body-clean already: it takes one roster line and one registry row (Amendment 3 R-1), zero body edits — it is the migration exemplar, not a migration target.

**New-executable companion obligation.** Each `add` row for a tracked `*.sh` above carries its `core/config/allowlists/script-execution-allowlist.txt` companion row in the same release; #5861's CI wiring is the `automation-registry-currency-check.yml` job, and #5859's validator is executed by that same consolidated check (D-DeployMirror).

---

## Contention Map

### Within-release

| File | Issues | Class | Resolution |
|---|---|---|---|
| `core/config/allowlists/script-execution-allowlist.txt` | #5859, #5861 | **append-pattern** (ADR-005) | Informational — structurally HIGH, operationally LOW. Each adds one row for its own new script; the sequencing already separates them |
| `core/automations/registry.md` | #5859 creates · #5860 reads · #5861 gates · #5862 populates | **semantic, single-writer** | Not a write collision: exactly one issue creates it and exactly one populates it, two waves apart. #5860 and #5861 read only |

**No other within-release file is claimed by two issues.** The five derived surfaces were pairwise intersected — 10 pairs over the path union; 2 collisions found. Sensitivity arm: the same intersector run over the **boilerplate** `## Affected Files` block returns 10 of 10 pairs colliding, so it detects overlap when overlap exists. Specificity arm: `#5858 ∩ #5862` returns 0 — a genuinely disjoint pair reads clean, so the zeros are not inert-true.

**Phase-0.7 contention resolved by D-3, no new decision.** #5860 and #5862 both need `docs/INSTALL.md` and `core/standards/c3-external-sync-path-b.md`. D-3 placed both files in #5862's scope at the Stage-4 gate, so both edits route to **#5862** and #5860 touches neither.

### Cross-PR — In-Flight Release Roster

**Measured at:** `4f7e1ce3` · `2026-09-03T00:37:44Z` · **Population:** n=7 siblings (6 with open PRs, 1 remote head with none).

| Slug | Bump-class | EDITSET | ∩ this release's FCM |
|---|---|---|---|
| `kit-unit-and-selection` | minor | 31 | **10** — the core ADR README, the operator-config template and schema, `deploy.sh`, the deploy-tools README, and four schemas |
| `label-and-reference-integrity` | UNRESOLVABLE | 26 | **14** — three ADR records, the core ADR README, `deploy.sh`, deploy tools, a reference-durability workflow |
| `adr-corpus-integrity` | minor | 19 | **6** — the core ADR README, the script-execution allowlist, a gate-criteria schema, +3 |
| `pda-decisions-and-conformance-baseline` | UNRESOLVABLE | 4 | **3** — three ADR records |
| `hub-spoke-run-and-planning-discipline` | UNRESOLVABLE | 42 | **3** — workflows, one schema |
| `hooks-block-only-their-scope` | UNRESOLVABLE | 8 | **1** — the script-execution allowlist |
| `operational-folder-enforcement-migration` | UNRESOLVABLE | 0 | 0 — merge-base equals head; inert at this baseline |

`UNRESOLVABLE` records that the sibling declares no bump-class this spoke could read — an unknown, not an absence.

**Tier-S structural blast radius:** no sibling declares a rename, relocate, or delete intersecting this release's surface — zero directory-crossing rename rows and zero delete rows on any FCM path. The one structural edge that applies is the **version-slot virtual path**, a genuine Tier-S serialization edge (R-1).

---

## Risk Register

| ID | Risk | Severity | Reversibility / Confidence | Mitigation |
|---|---|---|---|---|
| **R-1** | **Version-slot collision.** The recorded determination moved twice during this release as siblings claimed each slot mid-run | **HIGH** (observed twice) | **CHEAP / HIGH** | Structural and already in place: the plan carries `{{RELEASE_VERSION}}`, never a baked number (ADR-092), so a loss costs one re-derivation and zero sweeps. Re-run the authoritative-version-selection procedure at Engineering Commit 0 and again at Stage 12. **Do not pre-emptively pick a higher number** — the rule is `anchor + 1`, and measurement never outranks the rule |
| **R-2** | **ADR-number contention, with sweep-class blast radius.** Unlike a version, a prose-committed ADR number costs a **corpus sweep** | **HIGH** | **MODERATE / HIGH** | Run the ADR-number detector at Engineering Commit 0 **and** at Stage 9 entry — never trust a Stage-4 or Stage-5 reading. Keep the number out of prose: cite this record by path and title; confine the number to the filename, the H1, the frontmatter `title:`, and the README entry. A multi-branch collision is **governed, not a defect** — the rule computes `anchor(origin/main) + 1` regardless of branch claims, and merge order arbitrates |
| **R-3** | **#5862's original scope under-counted the real migration surface.** Its AC greps four files; the token's live consumer surface is larger, and includes the install path the Capability Outcome explicitly targets | **HIGH** (scope) | **CHEAP / HIGH** | **RESOLVED by D-3** — the AC and Affected Files expanded in place to the full live surface rather than deferring a remainder. Graded by CIAC-5 |
| **R-4** | **`core/deploy/deploy.sh` cross-PR contention.** #5861 adds a new Check; two siblings are also editing the file | **MODERATE** | **CHEAP / HIGH** | `overlap_class` is `append-pattern` (new Checks append), which ADR-005 classes informational. D-DeployMirror reduces this to **one** insertion at check number 75, not two. Confirm with the line-range overlap checker at Stage 5 |
| **R-5** | **Core ADR README four-way contention.** #5858 plus three siblings all append a thematic entry | **MODERATE** | **CHEAP / HIGH** | Append-pattern. On conflict **re-apply the thematic entry**; never hand-merge competing versions of the section. For this file "regenerate" means re-apply by hand — no projector covers it (ADR-117) |
| **R-6** | **Gate vacuity (#5861).** A registry gate over an empty registry passes trivially, and a synthetic fixture proves nothing about production data | **MODERATE** | **CHEAP / HIGH** | **CIAC-4** binds #5861's gate to #5862's real migrated population. Additionally, author the gate to the gate-efficacy declaration schema — posture / enforcement / invariant / **falsification repro** — modelled on the in-repo skill-registry-currency precedent |
| **R-7** | **Adapter over-engineering (#5860).** The parent epic explicitly warns against a universal scheduler abstraction up front | **LOW** (well-controlled) | **CHEAP / HIGH** | AC-3 carries the control ("assert no unused backend arm ships"). Both claimed backends are verified real, and manual/event degrade is the third path. Hold the arm count at exactly these three |
| **R-8** | **Rollback complexity.** #5861 introduces a CI workflow that could turn red on `main` and block unrelated PRs | **LOW–MODERATE** | **CHEAP / HIGH** | Ship the gate **non-required** (not in branch protection's required contexts), exactly as the skill-registry-currency check does — a red-but-unblocked check honours never-merge-red as a read-and-justify step without a repo-wide block. Promotion to blocking is a later operator-side step. Release-level rollback is `git revert -m 1` on the release merge commit |
| **R-9** | **Operator-config seam contention (#5860).** A sibling edits both the operator template and its JSON schema | **LOW** | **CHEAP / HIGH** | Both are additive edits in distinct sections. Confirm section-level disjointness at Stage 5 |

### Rollback strategy

Additive release: every deliverable is a new file or an append to an existing one, except #5862's mechanical token substitutions and #5858's one-clause deletion. Release-level rollback is `git revert -m 1` on the release merge commit — **CHEAP**, Confidence **HIGH**. The gate ships non-required (R-8), so no rollback path depends on branch-protection changes.

---

## Cross-Issue Acceptance Criteria

Five cohesion constraints. Each spans ≥2 issues, requires no dependency edge, and is graded on the merged PR at Stage 9 QC3.5 / Phase A3.6.

- [ ] **CIAC-1 (#5858 × #5859 × #5860 × #5861 — the decoupling is implemented, not asserted):** The three concerns the ADR decouples are each realized in a *distinct* surface — WHAT in the routine-spec schema, HOW in the scheduler adapter, WHO in the `automation_level` governance path. *Shared surface:* the ADR's Decision section and the three implementing paths it names. *Method:* assert the ADR text contains all three paths — expect 3 of 3. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5859 × #5861 — one schema, not a private copy):** The gate's predicate resolves against the schema #5859 authors rather than a private copy of the field list; a second copy drifts the moment the schema changes. *Shared surface:* the routine-spec schema path. *Method:* literal-match the schema path inside the gate predicate script — expect ≥1. *Non-null expectation, so no null-control limb applies.* *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#5859 × #5862 — every migrated cadence validates):** Every cadence #5862 migrates has a registry entry that validates against #5859's schema; no entry is added that the validator would reject. *Shared surface:* the registry data file. *Method:* run the validator over the full registry, expect exit 0; **control:** inject one deliberately malformed entry against the same validator on the same file and assert non-zero exit, proving the validator discriminates rather than always passing. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#5861 × #5862 — the gate is non-vacuous):** The gate discriminates on the release's own real migrated population, not on a synthetic fixture — the registry is non-empty at the moment the gate runs. *Shared surface:* the registry data file as read by the gate predicate. *Method:* run the gate predicate against the merged tree and assert its enumerated population is ≥ the count of cadences #5862 migrated; **control:** run the same predicate against the pre-migration revision on the same instrument and assert a strictly smaller population, proving the count tracks real data. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#5859 × #5860 × #5862 — the host-binding leak is closed, not relocated) — AMENDED, three arms:** No surface in the release names a firing backend directly — not the migrated consumers, and **not the registry itself**. *Shared surface:* the four migrating protocol documents **plus** the registry data file `core/automations/registry.md`. *Method:* scan both surfaces for the backend token, **covering frontmatter as well as prose body**, expecting **zero**; **control:** the identical invocation against the pre-migration revision returns **19**, proving the probe fires and the paths resolve. *Graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR.*

**Why CIAC-5 gained the registry arm.** Without it, a backend that relocates from the consumers *into* the registry leaves CIAC-5 green while the Capability Outcome is missed — the release's own end-to-end proof would pass in exactly the scenario the design most needs it to fail. **Why it gained the frontmatter arm:** `core/standards/c2-intake-sweep-path-a.md` names the backend in frontmatter at `purpose:` and `consumers:`. `consumers:` is machine-read structured metadata, so a body-only scan returns zero while the file's declared contract still binds the host.

---

## Verification Plan

### AC baseline

Occurrence counts differ by population, and all three readings are correct: **tracked files** = 12 files / 23 occurrences · **tracked minus frozen release plans** = 9 files / 19 occurrences · **unfiltered whole tree** = 428 files / 2813 occurrences. **#5862's AC-1 control arm uses 19** (tracked minus frozen plans). Do not substitute another figure. Every load-bearing detector runs under `python3` or a literal-fixed-string matcher — the local `grep` is `ugrep` and returns a plausible zero on a rejected pattern — and every null claim carries a sensitivity arm with an observed non-zero plus a specificity arm with an observed zero.

### Per-issue verification

| Issue | Check | Method | Expected |
|---|---|---|---|
| **#5858** | AC-1 decoupling stated | Read the ADR `## Decision` section; confirm the three-surface table and the three why-they-separate arguments | Present |
| **#5858** | AC-2 rejected alternative named | Read `## Alternatives Considered`; confirm the "extend the existing scheduled-automation catalog in place" candidate is named explicitly with its kill-reason | Present |
| **#5858** | AC-3 registration (limb 1) | Read the core ADR README § Automation-governance ADRs; confirm the thematic entry | Present — **human-graded at Stage 8**; no machine gate exists (ADR-117) |
| **#5858** | AC-3 reachability (limb 2) | Read the parent epic's comments; confirm a comment names the ADR number, title and repo-relative path | Present — non-repo artifact; Stage 13 must not look for it in the diff |
| **#5858** | ADR-number integrity | The ADR-number checker over both ADR directories | exit 0 (no duplicate, no gap) |
| **#5858** | ADR durability | The ADR durability lint over the new record | R5-NEW clean. **Warn-mode: read the output, do not trust the exit code** |
| **#5858** | Release-index invariance | The ADR index projector in `--verify` mode | **unchanged** — a delta means the core README was wrongly projected |
| **#5858** | Stale-clause reconciliation | Confirm the core ADR README no longer asserts a highest-core-scope-number, and that the record's own thematic entry for that number is untouched | Clause absent; entry intact |
| **#5859** | Schema + validator | Run the validator over the full registry (exit 0) and against a deliberately malformed entry (non-zero) | Discriminates |
| **#5860** | Adapter resolves and degrades | Run the resolver self-test; confirm the `none` default drives the manual/event degrade path | Passes; degrade exercised |
| **#5860** | No unused backend arm | Assert exactly the three bounded arms ship | 3 of 3, no fourth |
| **#5861** | Gate falsification repro | Attempt to add an automation with no registry row; assert the gate blocks and its verdict names the missing entry | Blocks, names the entry |
| **#5861** | Gate runs deploy + CI | Confirm one consolidated check at deploy check number 75 **and** the CI workflow, single-sourced on one predicate | Both paths, one predicate |
| **#5862** | Zero hardcoded backend | Scan the migrated consumer surface for the backend token, frontmatter included | **0**; control arm on the pre-migration revision returns **19** |
| **#5862** | Every migrated cadence registered | Cross-check the roster against registry rows | 8 roster entries, 8 rows |

### Release-scoped verification

Doc-link integrity via the deploy `--check` link check over every modified markdown file · skill-package freshness where a rostered skill's `SKILL.md` or `references/` changed (none expected in this release) · the plan-depth lint on this plan's own links (workspace-rooted form, leading `/`) · the five CIAC methods, run by the plan-verification executor as their sole runner, with Stage 9 consuming the emitted verdicts read-only.

---

## Delivery Strategy

Single release branch `release/automation-registry-as-gate` off `origin/main`, D-C SINGLE topology, one draft PR created at Stage 6 Phase C2 and transitioned to ready at the Stage 9 gate. P0 fully-serial Stage-6 dispatch: one Engineering slice at a time in Implementation-Sequence order, each pushing its own commits before the next starts. Commit messages reference their source issue. No force-push on the shared branch. Release-corpus governance artifacts (the ledger row, the index, the digest, the notes) land via the Stage 12 and Stage 13 chore PRs, never in this PR.

---

## Quota Budget

**Verdict:** **WARN** (Checkpoint A)
**Parallel-eligible spokes per parallel stage:** Stage 5: 5 · Stage 7: 5 · Stage 8: 5
**Per-spoke cost estimate:** size-bucket ordinal band. Worst batch composition: 1 × `size:S` + 3 × `size:M` + 1 × `size:L`. Source: heuristic.
**Assumed/stated remaining usage-window envelope:** **UNSTATED** — no operator quota band was supplied at hub start; the conservative default applies.
**Estimated cumulative draw % (worst parallel batch):** **not computable** `[ASSUMPTION – CONFIRM]`. Per the refuse-to-synthesize rule no percentage is rendered: the usage-window axis has no instrument and the band was never declared. Basis token: `UNSTATED`.
**Routing:** **WARN → window-aware launch timing + batch-splitting recommended.** Split each 5-spoke parallel batch into two sub-waves — `{#5858, #5859, #5861}` then `{#5860, #5862}` — placing the single `size:L` card in the lighter sub-wave. Stagger is a rate-limit defense and does not change cumulative consumption.
**Note:** Checkpoint B re-validates at every spoke launch and gates on a second axis this section deliberately omits — the host-API quota pools, read at runtime and combined DEFER-dominant. Bands and the cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Operator Decisions (recorded)

### D-Version — RECORDED DETERMINATION (rule-determined; not an operator gate)

**Bump class:** `minor` — the durable declaration. **Recorded next-free at Engineering Commit 0:** the value the plan's `{{RELEASE_VERSION}}` token resolves to at the Stage-12 atomic claim.

Lineage this release: **`v4.48 → v4.49 → v4.50`** — each slot claimed by a sibling mid-run, the allocation rule behaving correctly under sustained contention. Re-verified at Engineering Commit 0 against authoritative refs (`git fetch --tags origin && git fetch origin main`; ledger read via `git show origin/main:` never the worktree copy): `anchor(origin/main)` confirmed by the numerically-sorted remote tag maximum, its ancestry in `origin/main`, and the mainline ledger's terminal version-column row, all three agreeing. Next-free = `anchor + 1`, **never** `max(claimed) + 1` — unmerged branch claims do not bind. Binds only at the Stage-12 atomic claim. Reversibility CHEAP / Confidence HIGH.

### D-ReleaseClass — `cross-cutting` (operator-rendered)

Dominant trigger **(c)** — four hard in-bundle compositional edges. Triggers (a) ≥3 pipeline stage specs and (b) ≥3 rule-defining governance surfaces do **not** fire; the qualification is on coordination density, and it fits: a 5-issue bundle with 4 hard edges is a near-linear chain where the schema, its gate, its adapter, and its consumers must all cohere or the registry ships with no proven consumer. `novel` also fires on all three of its triggers; the practical delta between the two candidates is engagement density alone (Tight vs Standard) — both give Stage 9 depth Deep, Stage 5 activation ALL, and a 30-day outcome window. Reversibility CHEAP / Confidence HIGH.

### D-C Branch Topology — **SINGLE** · D-Concurrency Posture — **P0 fully-serial**

Only Wave 2 offers any Stage-6 parallelism at all, across exactly two issues; the available upside is one issue's worth of overlap against giving up the serial guarantee while four siblings actively edit `deploy.sh` and the core ADR README. Not worth it here. Reversibility CHEAP / Confidence HIGH.

### D-3 — #5862 migration scope: **expand the AC in place**

The AC and Affected Files expand to the full live consumer surface rather than deferring a remainder to a follow-up work item. Rationale: the Capability Outcome explicitly targets the install-path portability leak, and the install doc carries it. As originally scoped, CIAC-5's zero-hardcoded-backend predicate would have passed only because its path filter excluded the leak. Card remains `size:M` — the added occurrences are the same mechanical substitution, not new design. Reversibility MODERATE / Confidence HIGH.

### D-RegistryHome — rows at **`core/automations/registry.md`** (net-new directory)

The schema contract stays at `core/schemas/automation-registry-schema.md`. Basis: the contract/instance split ADR-038 established, plus the measured invariant that no file in `core/schemas/` carries appendable instance data. The `core/specs/` residents that share the `-registry.md` suffix are fixed-population disambiguation indexes, a different artifact class from an appendable gate-enforced catalog. Reversibility CHEAP / Confidence HIGH.

### D-DeployMirror — the registry gate runs **deploy + CI, one consolidated check**

Of the deploy-tools check family, six are deploy+CI, three deploy-only, and none CI-only — and the exemplar #5861 models byte-for-byte is itself deploy+CI. CI-only would have shipped the first member of that family to break the convention, with registry conformance invisible to a local `deploy.sh --check`. Resolution: **one** consolidated check at number **75** covering both the schema validator and the roster-to-rows predicate, plus the CI workflow. One insertion on the contention file, not two. Reversibility CHEAP / Confidence HIGH.

### D-SecurityYml — register the scheduled security workflow, do not exclude it

It is the tree's only scheduled workflow, so the gate's scheduled-workflow arm flags it on day one. It gets a real registry row rather than an exclusion line: the gate ships with zero exceptions, and the registry gains a genuine second consumer. Reversibility CHEAP / Confidence HIGH.

### D-CIAC5 — CIAC-5 scope **extended** to three arms

Consumers + registry file + frontmatter coverage, pre-migration control arm retained at 19. Reversibility MODERATE / Confidence HIGH.

---

## Corrections Engineering must carry

These supersede the Stage-4 and Stage-5 originals on their specific claims.

- **The `deploy.sh` selector-enumeration site is line 9963, not 10001.** The real site is the adapter-selector `for` list. Line 10001 is a comment block about tracker schema-anchor fields. Exactly one line in the file names ≥2 selectors (sensitivity: 12 lines name ≥1; specificity: 0). #5860's description — *one token in one `for` list* — was correct; only the address was off.
- **`trigger: scheduled` is not in the closed enum.** For the scheduled security workflow use **`time-driven`** with cron `0 6 * * 1`. A `scheduled` value would be rejected. This resolves the schema-generalization half of AI-002: the workflow is expressible without widening the schema.
- **`[adapters].scheduler` default is `"none"`, deliberately.** The install doc states that nothing runs until the operator registers the tasks, and that this is deliberate — the one step the installer cannot perform. An `agent-runtime` default would assert an unregistered backend and make #5860's AC-2 degrade path fixture-only.
- **`trigger: hybrid` REQUIRES a cron.** All four migrating cadence documents carry both cron signals and event signals, against a control document at zero cron. Without this rule all four migrated entries could be expressed cron-free — a live CIAC-3 failure path.
- **The routine `id` uses the skill-name regex** `^[a-z][a-z0-9-]*$` as carried by the existing registry-currency predicate, not a filename regex. Verified to match the intake-sweep id and reject four control arms. The companion claim that the artifact-naming standard's regex would reject that id is **unverified** — the extraction probe returned no patterns, an unusable probe rather than a refutation. Treat the positive citation as the binding one.
- **#5861's roster marker is list-valued** (SC-1 remedy, option O4). The platform-health framework declares **two** routines, which a scalar identifier cannot express. The marker takes a per-element shape guard and set-membership for its third assertion — verified clean. Engineering implements the amended form, not the Stage-5 original.
- **INT-4 accepted:** #5861's registry workflow adds one hard step running the adapter resolver's self-test. Follows from D-DeployMirror — if the gate runs deploy+CI as one consolidated check, the adapter's resolver belongs in the same executed path rather than shipping untested.
- **`decision-audit-cadence.md` joins as the 8th roster entry** (R-1). One roster line plus one registry row, zero body edits, since the document is already backend-free. Excluding it would ship a known unregistered automation inside a release whose premise is that registration is non-optional.
- **The stale ADR-numbering clause is deleted, not renumbered.** The core ADR README's naming-convention paragraph asserted a highest-core-scope number that is stale by scores of records — and read as three *different* values across this release's own three measurements. **Delete the clause**; resetting the value re-arms the identical rot on the next core ADR. The file already states the durable rule two paragraphs earlier — the file set itself is the authoritative list, and CI enforces its contiguity — so the clause is a hardcoded restatement of a fact the file set owns. Reconcile, do not annotate.

---

## Standing obligations at Engineering Commit 0

- **AI-001 — re-run the ADR-number detector before authoring any ADR number.** Its reading moved from 172 to 176 to 180 across this release's three measurements. Next-free = `anchor(origin/main) + 1`; the detector's own branch-claim line prints *detection only — never binds*. A prose-committed ADR number costs a corpus sweep if wrong. Re-detect at Commit 0 and again at Stage 9.
- **AI-002 — verify the scheduled security workflow is expressible in the six-field schema without loss.** The `time-driven` trigger value clears the known blocker; the item stays open until Engineering confirms the full row validates. **Escalate Tier-2 if a field cannot carry it. Do not widen the schema silently.**
- **Commit-0 version re-verify:** fetch authoritative refs, recompute next-free for the bump class, and HALT rather than overwrite if the recorded slot is taken. Then assert the stamp manifest after writing this plan file and **before** committing it.

---

## Non-coverage — what this release does NOT deliver

- **The existing automation declarations stay physically scattered** across `core/standards/` and `release/references/protocols/`. The registry gives them a row, not a home. Correct scoping — relocation is in no card's AC — but stated out loud rather than discovered later.
- **The scheduler-adapter spec document's path is unfixed here.** This release fixes the *seam*; where #5860's interface document lives is #5860's call.
- **Backend-specific properties are adapter concerns, not routine-spec fields** — completion-notification, the local-schedule versus UTC-stamp split, the host-open caveat. #5859 does not carry them; #5860 does.
- **The registry gate ships non-required.** Promotion to a blocking branch-protection context is a later operator-side step, not part of this release.
- **`core/ADRs/README.md` is not converted to an index.** It stays a curated thematic document by ratified determination; the index projector's population is the release module only.

---

## Findings routed forward (not fixed in this release)

- **F-3 — no Parallelization Map on the milestone description.** The Stage-3 standing convention's map H2 is absent; the milestone carries a Composition Lock without one. Either amend the description from the in-flight roster above or record the standing-applicability suppression explicitly.
- **The shared `## Affected Files` boilerplate.** All five issue bodies carry a byte-identical block cut from one epic decomposition, which is why a naive contention map reports five-way overlap. The derived matrix above supersedes the block; bodies are left intact as historical record per ADR-062.
- **Residual illustrative backend mentions.** Two files reference the backend illustratively rather than as a registration — a forward-looking mention of a *future* registration, and an example row in an async-pattern table. Accepted-residual; #5862's AC states the exclusion so a future reader does not read them as an incomplete migration.

---

## Deviation Log

| # | Deviation | Basis | Disposition |
|---|---|---|---|
| **DV-1** | Stage-4 recorded `v4.48`; the durable record carries `{{RELEASE_VERSION}}` and the determination moved twice | Sibling releases claimed each slot mid-run | Expected and designed-for (R-1). No sweep; one re-derivation per hop |
| **DV-2** | Stage-4 rated the ADR-number collision severity HIGH on branch claims; the authoritative detector reads `anchor + 1` and prints branch claims as non-binding | Hub adversarial evaluation EVF-2 | Severity re-rated; mitigation (re-detect at Commit 0 and Stage 9) retained |
| **DV-3** | Stage-4 reported the consumer surface as 12 files / 23 occurrences; the *live* (tracked minus frozen plans) surface is 9 / 19 | Hub adversarial evaluation EVF-3 | Both correct for their population. #5862's AC-1 control arm uses **19** |
| **DV-4** | Stage-4 named the third cadence document as an under-count (F-1); Stage 5 found a **fifth** routine-declaring document that is already backend-free | Stage-5 grounding, hub-confirmed EVF-4 | Load-bearing correction that *strengthens* the design — it is in-corpus proof the decoupling is statable, and it joins the roster as the 8th entry |
| **DV-5** | Stage-5 designed a CI-only gate posture; the shipped posture is deploy + CI as one consolidated check | Hub adversarial evaluation EVF-12 (D-DeployMirror) | Amended design implemented; one insertion on the contention file, not two |
| **DV-6** | Stage-5's roster marker was scalar; the amended form is list-valued | SC-1 — the platform-health framework declares two routines | Amended form is what Engineering implements |

---

## Verification Evidence

Populated per Engineering slice as each lands. Each entry records the slice, the landing commits, the checks run with their observed results, and the `deliverable_state` declaration.

### #5858 slice (Wave 0, Engineering Commit 0 + the founding ADR)

To be completed by the Wave-0 Engineering spoke on this branch.

---

## Change Description

### Outcome

An automation cannot reach the platform without a validated registry row, and nothing in the release names a firing backend directly. The registry declares **what** runs; the operator's own configuration selects **how** it fires; the existing automation-level dial governs **who** may let it act unattended. Where the platform previously stated a cadence in prose and hardcoded one host's scheduler beside it — including in the install path, on an install where none of those tasks were ever registered — it now declares the routine once, portably, and gates on the declaration.

### Issues resolved

Five issues, marked as closed at Stage 13: the founding ADR recording the decoupling and the registry-as-gate decision (#5858); the routine-spec schema and its validator (#5859); the registry-currency gate running deploy and CI on one predicate (#5861); the scheduler adapter at the operator-config seam with its three bounded backend arms (#5860); and the migration of the live consumer surface onto the registry (#5862).

### Key decisions

The decoupling is **three** surfaces, not two — naming the governance ceiling as a *stored* field is what converts "the routine is governed" from a prose promise into a predicate a gate can grade. The firing backend is **cited, never stored**: it is instance-local and lives behind the operator-config boundary, so storing it in a git-tracked catalog would move an instance-local fact across the public/private line — the exact defect the hardcoding documents exhibit. The adapter seam is a **fifth selector in an already-ratified family**, not a new configuration surface. Its default is **`none`**, deliberately: the shipped install documentation states that nothing runs until the operator registers the tasks, so a backend default would assert something the documentation says is not there.

### Reversibility

**CHEAP** — additive; `git revert -m 1` on the release merge commit. Confidence **HIGH**. The gate ships non-required, so no rollback path depends on branch-protection changes. Trending **MODERATE** as registry rows and citations accumulate.

### Downstream impact

The scheduled-automation library becomes a **view** of the registry rather than its owner. The adapter family gains a fifth axis under its existing seam, unchanged in shape. The automation-level dial, its enum, and its ceiling semantic are **unchanged** — the registry cites the dial as a declared default and never as the effective value. One net-new `core/` directory extends the core-module placement boundary, recorded rather than accreted.

### Cross-references

Release plan: this file. Design specs: the per-issue Stage-5 solutioning records. Founding decision: the ADR added by #5858, registered in the core ADR README's automation-governance section.
