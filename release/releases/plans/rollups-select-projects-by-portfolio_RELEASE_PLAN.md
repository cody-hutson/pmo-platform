---
title: Release Plan — rollups-select-projects-by-portfolio (portfolio-level surfaces select their project set by portfolio)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class major; the rule-computed next-free at Engineering Commit 0 is v6.00, equal to the Stage-4 provisional; the concrete number binds at the Stage-12 atomic claim)
milestone: rollups-select-projects-by-portfolio
release_class: novel
reversibility: MODERATE / Confidence HIGH — one card on one branch, one pull request and one merge; each slice reverts by its own commit and the seven skill packages regenerate from the reverted sources; an operations-side move of a composed file into its portfolio's folder is reversed by an operations session. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `rollups-select-projects-by-portfolio`

**Milestone:** `rollups-select-projects-by-portfolio` (milestone 435). One card, **#8478** — portfolio-level surfaces read one `PORTFOLIO.md` and never filter by `portfolio_id`. The Stage-4 planning sub-task **#9150** carries the approved plan (comments 7230930107, part 1/2, and 7230930475, part 2/2) and the Stage-4 gate's Decision Recorded (comment 7231189605). The Stage-5 design is on **#9179**: Parts 1/4–4/4 (comments 7232018181, 7232019362, 7232020747, 7232022003), the round-1 decision record (comment 7232479692), the delta re-spec Parts 1/6–6/6 (comments 7233333470, 7233334169, 7233334840, 7233335940, 7233336898, 7233338135) and the round-2 decision record (comment 7234438317). Its Phase A6.5 adversarial reviews are on **#9197** (comments 7232333730 and 7234064084). The Stage-6 Engineering sub-task is **#9180**; its floored-card disposition is comment 7234535888. This file is Engineering Commit 0.

**Version identity:** **versioned** — bump-class **`major`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v6.00`**, equal to the D-Version determination (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/rollups-select-projects-by-portfolio`, cut from `origin/main` at `8ed5e273`; one pull request opened in **draft**; one merge into `main`.

**Concurrency posture:** **P0 fully serial**: Commit 0, then slices S1 → S2 → S3 → S4 → S5 → S6, built by one Stage-6 Engineering spoke. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #9150 and is amended, in order, by: the Stage-4 gate's Decision Recorded; the Stage-5 design (Parts 1/4–4/4); the round-1 Stage-5 decision record; the delta re-spec (Parts 1/6–6/6), which supersedes Parts 1/4–4/4 wherever they differ; the focused adversarial review of the delta; and the round-2 Stage-5 decision record, which is binding and adopts twelve of that review's items as Stage-6 fixes. Where the plan and a later record differ, the later record wins, and each change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | major — the durable determination (D-Version, a recorded determination at the Stage-4 gate): five operations skills change how they select their project set, per the Bump-Class Selection Guide's row "Skill behavioral change (new mode, altered processing logic)" (v5.00 precedent). Confidence MEDIUM; minor is the operator's override. The rule-computed next-free re-verified at Engineering Commit 0 is `v6.00`. The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-28 (Saturday, UTC) |
| **Release Manager** | Agent-assisted (release-hub; one Stage-6 Engineering spoke) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file) |
| **Branch** | `release/rollups-select-projects-by-portfolio` |
| **PR** | opened in **draft** at Stage 6 |
| **Milestone** | `rollups-select-projects-by-portfolio` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-28, domain: software }`

## Commit-0 Version Re-Verify Record

### Version half (steps 1–3, pre-write)

1. `git fetch --tags origin` and `git fetch origin main` at Commit 0: `origin/main` = `8ed5e273`; the highest version tag is `v5.14`; no `v6*` tag exists.
2. Recomputed next-free for bump-class `major` through the version-claim adapter (`release/tools/claim-version.sh --sha 8ed5e273… --bump major --dry-run`): **`v6.00`**. Control arm, same instrument: `--bump minor` → `v5.15`.
3. `v6.00` is not in the claimed set and equals the recomputed next-free: **PROCEED**. The tag arm binds. Two `release/*` siblings are in flight, both declaring bump-class minor (§ In-Flight Release Roster); a minor sibling that merges first takes `v5.15` and leaves this release's next-free at `v6.00`, and if this release merges first each sibling's next-free minor becomes `v6.01` (risk R8).

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp rollups-select-projects-by-portfolio` — recorded in the Engineering Commit 0 message.

### Commit-0 Survival Set

| # | Element | Where in this file |
|---|---|---|
| 1 | `domain_practice` label | under § Header |
| 2 | File Change Matrix (machine-readable) | § File Change Matrix (as amended in § Deviation Log) |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria (none — a one-card milestone) |
| 4 | Verification Plan | § Verification Plan |
| 5 | the release-version stamp manifest | § Header, the **Version** cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | Stage 4 `8ed5e273`; branch cut at `8ed5e273` (`8ed5e273..origin/main` is empty at Commit 0) |

## Summary (30 seconds)

- **One card, one branch, one PR:** #8478 (P2, parent epic #5828). At `8ed5e273` the card's defect reproduces: `portfolio_id` reads 0 in the five skills, the composer and the write-back contract, against a non-zero `PORTFOLIO.md` control in each.
- **The rule.** `core/standards/portfolio-writeback-contract.md` gains § 7 Portfolio scoping, cited everywhere as "`portfolio-writeback-contract.md` § Portfolio scoping". Membership turns on N, the number of distinct active `portfolio_id` values held by Portfolio records:
  - N = 0: surfaces run unscoped, exactly as before — except that when the rollups name two or more portfolios the run stops and names the Portfolio records to create.
  - N = 1: a project that names that portfolio, or names none, belongs to it; a key naming no record is excluded and listed as unresolved.
  - N ≥ 2: a project belongs to the portfolio its `portfolio_id` names; a project naming none is unassigned, in no output, listed to the operator. Nothing stops.
  - There is **no default portfolio**.
- **One composed file per portfolio folder.** Each portfolio's composed file is `projects/_config/<portfolio_id>/PORTFOLIO.md`; an install with no Portfolio record keeps `projects/_config/PORTFOLIO.md`. While the root file exists beside a Portfolio record, every portfolio-level surface stops and names the move.
- **The composer is the executable half.** `compose-portfolio.py --portfolio <id>` reads the Portfolio records itself, refuses a scoped run at a narrowed root, cross-checks each rollup against its own `PROJECT.md`, and reports excluded projects on standard error, never in the body. The prose surfaces' own text is the primary production control (D8 of the decision record).
- **Scope:** 54 File Change Matrix rows (66 paths) from the Stage-5 delta, plus three rows the Stage-6 absorbed items add (the ADR, two cascade docs). Size **XL**, measured. `core/governance/OPERATIONS.md` is Tier-0-floored: the operator commits its one line on this branch (split disposition); this spoke never edits it.
- **Version:** bump-class major, provisional `v6.00`, binding at the Stage-12 claim.

## Phase A0 — Triage→Design Re-Review

Transcribed from #9150 Part 1/2 (re-review date 2026-11-28, Saturday; baseline `8ed5e273`; G-PL5 cache-read MISS, so PT-1..4 were run in full). Every requirement row classified C1 or C2; no C3 arose, so no Tier 0.

| Requirement | Cls | Delta carried into this plan |
|---|---|---|
| AC1 — every portfolio-level surface, two-portfolio fixture | C2 | the surface set is the D-ScopeGaps set; the method is per surface (§ Verification Plan, per-surface table) |
| AC2 — project-initiator Mode A registers with the named portfolio | C2 | Mode B closure is in scope (D-ScopeGaps (A)); AC2 gains a closure arm |
| AC3 — single-portfolio and no-record output unchanged | C2 | the zero-record case is the committed composer fixture; graded as a byte-identical stakeholder-facing body (PR-4, ratified) |
| AC4 — composer discrimination at each narrowed scan root | C2 | graded on subject rows; every narrowed root is refused for a scoped run (CD-4) |
| Proposed Change 2 + Risk 1 — the defaulting rule | C2 | superseded: no default portfolio (round-1 decision) |
| Proposed Changes 3 and 4 | C1 | verbatim |
| The 2026-10-27 resolver findings | C2 | D-Resolver (C): routed to their owners; rung-2 layout continuity ships here (Change 38) |
| Subsumption vs the cross-tier, roll-up-home and entity-key milestones | C1 | not subsumed |

A0 sub-gates: G-PL1 reference currency PASS · G-PL2 crisping PASS with the C2 refinements · G-PL3 placement SKIP (empty window) · G-PL4 empirical repro admit-still-valid. The currency-decision confidence gate read CONVERGENT and proceeded at the plan gate's authorization.

## Dependency Graph

- **Issue-level:** one card, so no intra-release issue edges. Typed dependencies on #8478: 0 blocked-by, 0 blocking. Parent: #5828.
- **Intra-card slice DAG (substrate before consumer):**

```
S1 rule + carriers (contract § 7, rollup template, entity-model note, schema cell, ADR) ──► S2 composer + fixtures
S1 ──► S3 emitter and composer consumers (ppm-agent emission; weekly-status-rollup; health-check + evals; register row)
S2 ──► S3   (weekly-status-rollup Section 6 and health-check rollup invoke the composer)
S1 ──► S4 direct readers (daily-status; project-initiator Mode A and Mode B)
S1 ──► S5 cascade text (deploy.sh rung 2 and presence; charter template; operations-bridge rule; config docs; disciplines; reference packs)
S3, S4, S5 ──► S6 package rebuild
```

- **Cross-milestone:** this ─(soft, sequence)→ cross-tier-rollup-resolves (#5853 cites the rule); file contention with cross-project-rollups-have-one-home, entity-key-and-referential-contract, governance-surfaces-agree, conformance-and-stewardship-mechanized and ppm-agent-findings-become-artifacts (§ Contention Map); routed cards #9178, #8546 and #2373 are coordinated by comment.

## Implementation Sequence

One card, a Commit-0 plus six slices, each one or more commits on `release/rollups-select-projects-by-portfolio`, pushed after each slice. Change numbers are the Stage-5 delta's (Changes 9 and 10 are withdrawn and stay retired; Change 41 is operator-executed).

0. **Engineering Commit 0** — this file (Change 1), with the Commit-0 version re-verify and `claim-version.sh --verify-stamp`.
1. **S1 — the rule and its carriers.** Change 2 (contract § 7 Portfolio scoping, § 2 join keys, the § 1 / § 3 / § 4 / § 5 reconciliations), Change 7 (rollup template `portfolio_id` line), Change 8 (its provenance sidecar), Change 11 (entity-model Portfolio physicalization note), Change 12 (project-schema § 3b cell), Change 56 (`_frontmatter.py` count), and the ADR `{{ADR:portfolio-scoped-selection}}`. Includes the round-2 contract text: the § 7.2 first-row stop (D-RecordlessTwoIds), the one-to-two-transition rationale (D-UnresolvedAtOnePortfolio), the § 7.1 composed-file exception (D-RecordNotComposedFile), the bounded record walk (FM-D2 / CD-D1), and the § 7.5 folder-file sentence (CD-D2).
2. **S2 — the engine.** Changes 5 and 6 (the two fixture trees), Change 3 (the composer), Change 4 (tools README). Evidence shape: two RED/GREEN pairs. Pair 1 lands the nine Stage-5 arms RED against an interface-only composer, then the literal Stage-5 patch GREEN. Pair 2 lands the round-2 and absorbed arms RED against pair 1's head, then their fixes GREEN.
3. **S3 — emitter and composer consumers.** Change 25 (ppm-agent), Changes 13–15 (weekly-status-rollup and two references), Changes 17–19 (health-check and two references), Changes 20–24 (health-check evals), Change 37 (gate-coverage register row).
4. **S4 — direct readers.** Change 16 (daily-status), Change 26 (project-initiator Mode A and Mode B).
5. **S5 — cascade text.** Change 38 (`deploy.sh`), Change 39 (charter template, plus the Governance File Map clause), Change 40 (operations-bridge rule, a mirror pair), Changes 42–51, and the two PR-D4 cascade rows. Change 41 limb 1 (`core/governance/OPERATIONS.md`, the rung-2 row) is **operator-executed** on this branch after the draft PR opens and before Stage 7; limb 2 is withdrawn (D-DriftCheckF (B)).
6. **S6 — packages.** `bash core/deploy/tools/build-skill-packages.sh` for every skill the change set stales, resolved by `--skills-for-paths` over the branch's changed paths, after the last skill edit; package and `.sha256` committed together.

**Skill-edit discipline (S3, S4, S5).** Each `SKILL.md` and `references/` edit runs in a pmo-skill-editor Mode A (Targeted edit) session: impact analysis against `core/skills/registry.md`, a `version:` bump per `version-field-semantics.md` § Bump Rules, and the audit trailer in the commit message. The skill `version:` field is a literal `vMAJOR.MINOR` (the stamp refuses a release-version token on that line), so each edited skill takes the provisional `v6.00`, re-read at Stage 7 and re-checked at the Stage-12 claim.

### Agent-Editability Read

Re-derived at Stage 6 entry against `core/hooks/block-autonomy-ceiling.sh` and `core/hooks/block-skill-direct-edit.sh` at `8ed5e273` (`8ed5e273..origin/main` empty, so the Stage-4 derivation stands unchanged; plan R15).

| Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Execution path |
|---|---|---|---|---|
| 5 × `operations/skills/<skill>/SKILL.md`; 4 operations `references/*.md` | no | regex ✓ · armed ✓ · exemption undetermined | sanctioned-session-required | pmo-skill-editor Mode A, one session per skill |
| `release/skills/build-reviewer/references/dimension-packs/pmo-platform-dimensions.md`; `release/skills/pmo-skill-refiner/references/pmo-platform-context.md` | no | regex ✓ · armed ✓ · exemption undetermined | sanctioned-session-required | pmo-skill-editor Mode A |
| `packages/*.skill[.sha256]` | — | — | build-script output → class of its source | rebuilt by `build-skill-packages.sh` after the sanctioned edits |
| `core/governance/OPERATIONS.md` (Change 41 limb 1) | **yes** — block 1 `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"`; block 2 `*/OPERATIONS.md` | — | tier-0-floored | **operator-executed** (split disposition, #9180 comment 7234535888); never the hook bypass |
| `core/CLAUDE.md.template`; `core/rules/operations-bridge.md` | no (the `.template` basename and the in-repo rules source are outside both blocks) | regex ✗ | unconstrained | ordinary Engineering spoke |
| every other row | no | regex ✗ | unconstrained | ordinary Engineering spoke |

**Card class:** `tier-0-floored` (most-constrained wins).

## Stage Applicability Matrix

| Issue | S5 Solutioning | S6 Engineering | S7 Dev Testing | S8 QA | S9 Plan Review | S10–11 | S12 Execute | S13 Close |
|---|---|---|---|---|---|---|---|---|
| #8478 | **ACTIVATE** — T2 (five SKILL.md processing steps change) + T3 (structural design: the Portfolio record's physical form, the per-portfolio composed-output layout) | yes | yes (executable composer arms; eval case; walkthroughs; Change 38's loop forms) | yes (AC-1..AC-4 per-criterion verdicts) | yes — Deep (Release Class `novel`) | compressed — satisfied by git-native review and merge (`release-process.md` § Stage Compression) | yes | yes (30-day outcome window) |

## Contention Map

**Within release:** NONE. A one-card release has no two change-specs on one file.

**Cross-milestone** (re-derived at Stage 5 over every open milestoned issue's Affected Files):

| Milestone | Shared files | Order |
|---|---|---|
| cross-project-rollups-have-one-home (#7508) | weekly-status-rollup `SKILL.md`; health-check `SKILL.md`, `references/rollup-mode.md`, `references/mode-intents.md`, `evals/evals.json`, `evals/judges/rollup.md`; project-initiator `SKILL.md`; `core/CLAUDE.md.template`; `core/governance/OPERATIONS.md` (operator-executed on both sides); plus the `.skill` packages | this merges first; the later one rebases and rebuilds its packages |
| entity-key-and-referential-contract (#5843, #5847, #5850) | the contract; `project-entity-model.md`; `project-schema.md`; project-initiator `SKILL.md` | this merges first |
| cross-tier-rollup-resolves (#5853–#5857) | `project-entity-model.md`; the contract, composer and fixtures named in its bodies | this merges first; #5853 cites § Portfolio scoping |
| governance-surfaces-agree (#6846, #6847, #6624, #6437) | `CLAUDE.md.template`, `operations-bridge.md`, `OPERATIONS.md`, `memory-architecture.md`, the build-reviewer pmo-platform pack, health-check `SKILL.md` | row-level edits |
| conformance-and-stewardship-mechanized (#5851, #5848, #5842) | `platform-config-schema.md`, `docs/platform-config-reference.md`, `architecture-overview.md`, `CLAUDE.md.template`, `project-schema.md`, health-check `SKILL.md`, `gate-efficacy-standard.md`, `deploy.sh` | row-level edits |
| ppm-agent-findings-become-artifacts (#7541–#7543) | ppm-agent `SKILL.md` and its package; `gate-efficacy-standard.md`; `OPERATIONS.md` | row-level edits |

`core/deploy/deploy.sh` is a hot file; this release edits three localized hunks and one top-level helper.

### In-Flight Release Roster

**Measured at:** `8ed5e273` · 2026-11-28 (Stage 6 entry) · **Population:** n=2 siblings with a remote `release/*` head.

| Slug | PR | Bump-class | EDITSET ∩ this File Change Matrix |
|---|---|---|---|
| `issue-body-is-the-scope-of-record` | #9201 (open) | minor (provisional `v5.15`) | none. It adds a core ADR at the same next-free number this release takes; whichever merges second is renumbered by `release/tools/renumber-adr.py` at its claim |
| `worktree-sessions-reach-in-repo-homes` | none yet | minor (provisional `v5.15`) | none (its branch changes a hook test and its plan) |

Control: `git ls-remote --heads origin 'release/*'` returns 3 heads, this release's among them.

## File Change Matrix

The release is the Stage-5 delta's 54 rows (66 paths, counting the 14 fixture files) plus the rows § Deviation Log DEV-7 adds. No row is a delete or a move.

```
# ── Commit 0 and S1, the rule and its carriers ──
release/releases/plans/rollups-select-projects-by-portfolio_RELEASE_PLAN.md  ADD
core/standards/portfolio-writeback-contract.md  EDIT
operations/templates/project-rollup-template.md  EDIT
operations/templates/project-rollup-template.md.provenance.yml  EDIT
core/disciplines/project-entity-model.md  EDIT
core/schemas/project-schema.md  EDIT
core/deploy/tools/_frontmatter.py  EDIT
core/ADRs/ADR-242-portfolio-scoped-selection.md  ADD
# ── S2, the engine ──
core/deploy/tools/compose-portfolio.py  EDIT
core/deploy/tools/README.md  EDIT
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/_config/port-alpha/PORTFOLIO.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/_config/port-alpha/portfolio-record.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/_config/port-beta/PORTFOLIO.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/_config/port-beta.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/proj-alpha/04-PMO-Operations/proj-alpha_Rollup.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/proj-alpha/PROJECT.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/proj-beta/04-PMO-Operations/proj-beta_Rollup.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-two-portfolio/proj-beta/PROJECT.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-single-portfolio/_config/port-alpha/PORTFOLIO.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-single-portfolio/_config/port-alpha/portfolio-record.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-single-portfolio/proj-alpha/04-PMO-Operations/proj-alpha_Rollup.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-single-portfolio/proj-alpha/PROJECT.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-single-portfolio/proj-gamma/04-PMO-Operations/proj-gamma_Rollup.md  ADD
core/deploy/tools/tests/fixtures/portfolio-composer-single-portfolio/proj-gamma/PROJECT.md  ADD
# ── S3, emitter and composer consumers ──
operations/skills/ppm-agent/SKILL.md  EDIT
operations/skills/weekly-status-rollup/SKILL.md  EDIT
operations/skills/weekly-status-rollup/references/roll-up-input-coverage-checklist.md  EDIT
operations/skills/weekly-status-rollup/references/metric-registry.md  EDIT
operations/skills/health-check/SKILL.md  EDIT
operations/skills/health-check/references/rollup-mode.md  EDIT
operations/skills/health-check/references/mode-intents.md  EDIT
operations/skills/health-check/evals/evals.json  EDIT
operations/skills/health-check/evals/README.md  EDIT
operations/skills/health-check/evals/judges/rollup.md  EDIT
operations/skills/health-check/evals/cases/rollup-portfolio-two-portfolio.yaml  ADD
operations/skills/health-check/evals/fixtures/portfolio-two-portfolio.md  ADD
core/standards/gate-efficacy-standard.md  EDIT
# ── S4, direct readers ──
operations/skills/daily-status/SKILL.md  EDIT
operations/skills/project-initiator/SKILL.md  EDIT
# ── S5, cascade text ──
core/deploy/deploy.sh  EDIT
core/CLAUDE.md.template  EDIT
core/rules/operations-bridge.md  EDIT
core/governance/OPERATIONS.md  EDIT
core/config/platform-config.toml.template  EDIT
core/schemas/platform-config-schema.md  EDIT
docs/platform-config-reference.md  EDIT
core/disciplines/memory-architecture.md  EDIT
core/disciplines/execution-framework.md  EDIT
core/disciplines/operating-model.md  EDIT
core/disciplines/architecture-overview.md  EDIT
core/standards/AUDIT_FRAMEWORK.md  EDIT
release/skills/build-reviewer/references/dimension-packs/pmo-platform-dimensions.md  EDIT
release/skills/pmo-skill-refiner/references/pmo-platform-context.md  EDIT
docs/workspace-setup.md  EDIT
core/specs/operational-artifact-inventory.md  EDIT
# ── S6, packages (the set resolved by --skills-for-paths; amended in the commit that rebuilds) ──
packages/weekly-status-rollup.skill  EDIT
packages/weekly-status-rollup.skill.sha256  EDIT
packages/daily-status.skill  EDIT
packages/daily-status.skill.sha256  EDIT
packages/health-check.skill  EDIT
packages/health-check.skill.sha256  EDIT
packages/ppm-agent.skill  EDIT
packages/ppm-agent.skill.sha256  EDIT
packages/project-initiator.skill  EDIT
packages/project-initiator.skill.sha256  EDIT
packages/build-reviewer.skill  EDIT
packages/build-reviewer.skill.sha256  EDIT
packages/pmo-skill-refiner.skill  EDIT
packages/pmo-skill-refiner.skill.sha256  EDIT
```

What each non-obvious row depends on:

- `core/governance/OPERATIONS.md` is **operator-executed** (Change 41 limb 1 only, the rung-2 row): the operator commits it on this branch from a hub-supplied command after the draft PR opens and before Stage 7. Limb 2 (check 0(f)) is withdrawn by D-DriftCheckF (B).
- `core/rules/operations-bridge.md` is a mirror-pair source; its deployed copy is re-laid by `deploy.sh --deploy` (Check 9).
- The `packages/` rows are build-script output. The set is re-resolved at S6 from the branch's changed paths; a package the resolver adds or drops is recorded in the commit that rebuilds and in § Deviation Log.

**Read-only inputs (NOT EDITED):** `core/skills/registry.md`, `core/hooks/block-autonomy-ceiling.sh`, `core/hooks/block-skill-direct-edit.sh`, `operations/skills/pmo-portfolio-manager/SKILL.md`, `core/deploy/tools/tests/test_corpus_walker_parity.py`, `core/deploy/allowlists/selftest-coverage-manifest.txt`.

**Release-wide explicit non-scope (NOT EDITED):** `core/schemas/entity-field-schemas.md`, `operations/templates/portfolio-entity-template.md` (no Portfolio template), `core/config/operator.toml.template` and `core/config/operator-toml-schema.json` (no default-portfolio key), `core/deploy/tools/build-doc-index.py`, `core/ADRs/README.md` (a curated thematic document, not an index — ADR-117).

**Domain classification:** every row is an internal pmo-platform artifact; the dominant class is software (five skill bodies and a Python tool with its fixtures), the secondary governance (the write-back contract and the cascade docs). The label is under § Header.

## Tier-A activated design artifacts

| Artifact path | Flow class | Trigger | Activation tier | G-CL6 obligation |
|---|---|---|---|---|
| `core/standards/portfolio-writeback-contract.md` § 7.6 Data flow (Mermaid) | Data flow | a contract file is modified with cross-component data flow (Portfolio records and `PROJECT.md` → ppm-agent → rollup → composer → weekly Section 6 → health-check; the direct readers) | A NEW | declared here at Commit 0; Stage 13 G-CL6 reads this section |

## Risk Register

The control census: risks=26 · control=R3, R4, R14, R16, R17, R18, R28 · owner-act=the rest. Under G-PR4, a control-rested row is accepted only once that control is observed acting.

| ID | Risk | Type | Severity | Mitigation / disposition |
|---|---|---|---|---|
| R1 | One composed file per portfolio multiplies a path the corpus names | scope | High | Settled by the same-filename-per-folder layout: 23 occurrences of the exact root path in 17 files are dispositioned (21 UPDATE / 2 PRESERVE) and the path is not renamed |
| R2 | No on-disk form existed for a Portfolio record | dependency | High | Settled: records are located by frontmatter (`entity_type: Portfolio` + `portfolio_id`), filename-agnostic except that a composed `PORTFOLIO.md` is never a record |
| R3 | A single-portfolio or no-record install changes output (AC3) | rollback | High | `(single-portfolio-unchanged)` byte-identity arm; the committed zero-record fixture's `(idempotency)` arm and empty standard error |
| R4 | A filter inside `discover_rollups` forks the shared corpus-walk predicate | contention | Medium | Filter after discovery; `discover_rollups(root)` untouched; `test_corpus_walker_parity.py` stays green |
| R5 | cross-project-rollups-have-one-home shares nine files plus packages | contention | Medium | Merge this first; the later release rebases and rebuilds its packages |
| R6 | entity-key-and-referential-contract edits the same contract and two schema files | contention | Medium | Sequence this first; additive edits |
| R7 | cross-tier-rollup-resolves cites a rule whose home moves | dependency | Low | The heading is named: `portfolio-writeback-contract.md` § Portfolio scoping |
| R8 | A major landing mid-train moves the siblings' provisional numbers | version | Medium | Commit-0 re-verify and the Stage-12 atomic claim; the hub tells each sibling hub when this Commit 0 lands |
| R9 | Seven sanctioned pmo-skill-editor sessions; the exemption list is undetermined from here | sequencing | Low | The unconstrained S1/S2 land first, so a gate failure costs no engine work |
| R10 | Skill `version:` fields left unbumped | process | Low | Bump every edited skill to the provisional `v6.00`; Stage 7 reads each field |
| R11 | Rung 2 applies one portfolio's override to every project once a caller passes a project path | latent defect | Medium | Routed (D-Resolver (C)); Change 38 reads exactly one composed file or none |
| R12 | The daily drift check 0(d) reads a second portfolio's projects as drift | scope / outcome | Medium | Routed to #8546; the narrowed behavioral correction carries it until then |
| R13 | A reader-graded walkthrough is weaker than an execution | verification | Medium | D-ProseSkillVerification (A); the composer arms carry the executable half |
| R14 | Real ids reach a public fixture or example | public text | High | Placeholder ids only; the depersonalization gate runs on the PR |
| R15 | The Agent-Editability derivation goes stale if a hook file changes first | drift | Low | Re-read at Stage 6 entry (unchanged) |
| R16 | The "7-field" count cascades | scope | Medium | The join key sits outside the seven; no stated count moves |
| R17 | After deploy, an install that gains a record keeps its root file, so every surface stops | rollback | Low | The stop names the move; handoff step 3 moves it; Check 4 accepts either layout |
| R18 | A flag-less run at a narrowed root composes the keyed rollups under it | scope | Low | § Portfolio scoping states it; Section 6 never narrows; scoped narrowed runs are refused |
| R19 | Prose resolution of the served portfolio in five skills is the primary production control and can drift | maintainability / disclosure | **High** | One rule home; the literal report line at every surface; citation probes; walkthroughs; the deterministic served-portfolio resolver held for the Stage 9 filing step |
| R22 | Check 0(f) reads a migrated install as critical drift | outcome | Low | D-DriftCheckF (B): the narrowed correction carries it; the charter's Governance File Map row states the per-folder location |
| R23 | Rung 2 reads no portfolio file with two or more; an archived portfolio's folder counts toward "exactly one" | latent | Low | Stated in `platform-config-schema.md` § 4; handoff step 3 creates every active portfolio's folder file (CD-D2) |
| R24 | Changing a portfolio's id creates a new folder | stability | Low | The charter's rename rule (new `*_id`, supersession) |
| R25 | A `portfolio_id` equal to the config folder's own `releases/` child | config | Low | The composer refuses a reserved `portfolio_id` (CD-D1 (d)) |
| R26 | On a multi-portfolio install every pre-emission unkeyed rollup with a keyed `PROJECT.md` is held, so the first composition is empty | cutover | Low | The handoff hold runs through step 4's re-emission |
| R27 | Wider contention with three milestones; `deploy.sh` is a hot file | contention | Low | Localized hunks; merge order recorded |
| R28 | Check 63, doc-link or reference-durability findings on cascade edits | process | Low | The three checkers run over the edited files at C4 |

R20 and R21 are withdrawn (no `operator.toml` key, no default to re-designate).

## Cross-Issue Acceptance Criteria

None declared. The milestone has one non-sub-task member, and a cross-issue criterion spans at least two issues (population enumerated: #8478). Lint record at Stage 4: `CIAC-LINT-SUMMARY declared=0 parsed=0 clean=0 declared-deferral=0 flagged=0` (exit 0); it is re-run on this file at Stage-6 A1.

## Verification Plan

`ac_baseline: { #8478: 4, read_at: 8ed5e273 }`

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #8478 | AC-1 | `grep -c -F "(portfolio-scope)" core/deploy/tools/compose-portfolio.py` at least 1 [READER-GRADED — each prose skill's selection step, walked on the in-repo two-portfolio fixture, names only the requested portfolio's project; graded at Stage 7 per the per-surface table] | the composer's portfolio-scope arm is present and the CI self-test job runs it green; each skill walkthrough names one project per portfolio · control: `grep -c -F "(idempotency)" core/deploy/tools/compose-portfolio.py` → 3 at 8ed5e273 |
| #8478 | AC-2 | declared, verification deferred to the Stage 7 dry run of project-initiator Mode A then Mode B on the in-repo two-portfolio fixture (read the Step 8 summary and the Mode B closure output) | registered with the named portfolio only; Step 1a demands the input; Step 5a ends with no critical flag; Mode B leaves the other portfolio's composed file unchanged |
| #8478 | AC-3 | `grep -c -F "(single-portfolio-unchanged)" core/deploy/tools/compose-portfolio.py` at least 1 [READER-GRADED — at Stage 7, the pinned composer from 8ed5e273 against the new one on the single-portfolio fixture and on the committed zero-record fixture] | byte-identical stakeholder-facing body on both fixtures (SHA-256 prefixes `8a5fe095e1000962` and `2b128c4fb1e2422f`); the zero-record run writes nothing to standard error · control: the same comparison on the two-portfolio fixture differs (asserted in the same arm) |
| #8478 | AC-4 | `grep -c -F "(portfolio-discrimination)" core/deploy/tools/compose-portfolio.py` at least 1 | 0 subject rows of the other portfolio's rollup at the full root; every narrowed root refused (exit 2) for a scoped run · control: the `(portfolio-scope)` arm on the same fixture asserts the requested portfolio's rollup present |

**Per-surface method table** (reader annotation, not graded by the plan verifier):

| Surface | How it is graded | Who runs it |
|---|---|---|
| `compose-portfolio.py` | `--self-test` arms over two committed fixtures, each null arm with its same-fixture control | CI job "Discovered tool self-tests"; locally `python3 core/deploy/tools/compose-portfolio.py --self-test` |
| health-check `rollup --scope portfolio` | eval case `rollup-portfolio-two-portfolio` under `judges/rollup.md`; the other portfolio in `must_not_mention`, the served one in `must_surface` | the preserved eval harness if a Stage-7 session can run it; otherwise reader-graded against its judge |
| weekly-status-rollup, daily-status, ppm-agent, project-initiator | static rule-citation probes plus a Stage-7 walkthrough of each selection step on the in-repo fixtures | Stage 7 |
| `deploy.sh` rung 2 and the presence helper (Change 38) | the extracted function and helper run under `/bin/bash` with `set -euo pipefail` against five temporary workspaces | Stage 7 (not executed at Stage 5: the script-execution control refused both spokes) |

**Static probes — run by Stage 7.** For each of the five skills: `grep -c -F "Portfolio scoping"`, `grep -c -F "portfolio_id"`, `grep -c -F "names none"` (the one-portfolio clause) and `grep -c -F "beside a Portfolio record"` (the migration stop) at least 1; `grep -c -F "unresolved portfolio_id"` at least 1 on weekly-status-rollup, daily-status, health-check and ppm-agent; `grep -c -F "Portfolio: <portfolio_id, or unscoped>"` at least 1 on project-initiator. All read 0 at 8ed5e273 (control: the contract's own heading carries `Portfolio scoping` after S1).

**Stage 7 walkthroughs:**

| Tree | Skill · step | Input | Observable that must hold |
|---|---|---|---|
| two-portfolio | weekly · Inputs 1 + Section 6 | S = port-beta | member set {proj-beta}; composer `--portfolio port-beta` at the projects root; target `_config/port-beta/PORTFOLIO.md`; checkpoint carries `Portfolio: port-beta — unassigned: none; unresolved portfolio_id: none` |
| two-portfolio | daily-status · Multi-Project | "generate all daily updates", S = port-alpha | only proj-alpha processed; the review opens with the `Portfolio:` line |
| two-portfolio | ppm-agent · status + § 8.8 | status on proj-beta; emission for proj-beta and for an unkeyed copy | reads `_config/port-beta/PORTFOLIO.md` only; emits `portfolio_id: port-beta`; the unkeyed copy emits no `portfolio_id` line; a single-project status for proj-alpha shows its XRC counterpart as `[OTHER PORTFOLIO]` |
| two-portfolio | project-initiator · A 1a/3/5/5a/8; B B1/B6/B8; portfolio move | new project in port-beta; then proj-beta → port-alpha | input demanded; `portfolio_id: port-beta` written; row added to port-beta's file only; 5a item 7 passes; Mode B touches port-beta's file only; the move removes the row from port-beta's file, adds it to port-alpha's, and asks for re-emission |
| two-portfolio | health-check · refusal | active project proj-alpha asked to audit port-beta | refused with "run it from a project in that portfolio"; header carries the `Portfolio:` line |
| two-portfolio + FM-D7 variant | each prose surface's N-resolution | the two-portfolio tree plus an archived `port-gamma` record with its own folder and composed file, and a third active record `port-delta` at the config top with no folder yet | the surface counts **three active portfolios** (port-alpha, port-beta, port-delta) — records, not folders; the archived folder is read by no surface; an unkeyed project is unassigned. A surface that counts folders reads port-alpha, port-beta and port-gamma, and fails this row |
| one-portfolio | weekly · Section 6 | S = port-alpha (the only one) | members {proj-alpha, proj-gamma}; composed bytes = pinned bytes; `unassigned: none` |
| one-portfolio | project-initiator · Mode A | no Portfolio input given | proceeds (input optional with one portfolio); registers in `_config/port-alpha/PORTFOLIO.md` |
| one-portfolio | daily-status, ppm-agent, health-check | anchored on proj-gamma (unkeyed) | resolves to port-alpha; included; no stop |
| no-record (committed fixture) | weekly · Section 6 | — | unscoped; composer run with no flags; bytes = pinned; target `projects/_config/PORTFOLIO.md`; line `Portfolio: unscoped` |
| no-record | project-initiator · Mode A; health-check | — | no Portfolio input asked; registers in the root file; the audit runs unscoped and does not stop |
| migration window | each surface | the one-portfolio tree plus a planted `_config/PORTFOLIO.md` | every surface stops and names the move; composer exit 2 |

**Release-level verification.** `release/tools/verify-release-plan.sh` on this file at C4; `check-count-structure.py`, `check-doc-links.py` and the reference-durability detector over the edited files; `check-rules-budget.py`; package freshness (Check 7 single engine); the mirror-pair parity check. None of these reads the live operations tree.

## Delivery Strategy · Rollback Strategy

- **Delivery.** One branch and one PR, opened in draft at Stage 6. Slices serial (P0); each executable composer change is a RED/GREEN pair; no force-push. Merge at Stage 12 under the atomic version claim (plain merge, signed commits).
- **Per-slice rollback.** Revert the slice's commits; packages regenerate from the reverted sources.
- **Whole-release rollback.** Revert the merge through a PR, rebuild the packages in that PR, and `./deploy.sh --deploy` after it merges. The version tag stays (Tag Retention).
- **Operations-side rollback.** The reverted composer ignores keys and records, and single-file composition resumes at the root file. An operations session moves a one-portfolio install's folder file back to the root; on a multi-portfolio install the root file becomes the first portfolio's again and the other folder files are left for clean-up. The behavioral correction is restored if it was narrowed.
- **Reversibility.** MODERATE / confidence HIGH.

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A). A one-card release has no parallel batch; every launch is a singleton (Stage 5: 1 · Stage 7: 1 · Stage 8: 1). Per-spoke cost: `size:XL` → the high ordinal band (heuristic, § 5). The usage-window envelope is UNSTATED, so the § 3.1 conservative default applies and Checkpoint B re-validates at every launch.

## Parallelization Map (recorded 2026-11-28)

**Verdict:** Tier-B soft-coupled. No hard edge in either direction.

| Other milestone | Direction | Edge type | Body confirmation |
|---|---|---|---|
| cross-tier-rollup-resolves | this-blocks-other | soft + file-contention | #5853 adopts the portfolio-tier rule in `core/standards/portfolio-writeback-contract.md` § Portfolio scoping; shared file `core/disciplines/project-entity-model.md`. This merges first |
| cross-project-rollups-have-one-home | bidirectional | file-contention | nine files and the `.skill` packages (§ Contention Map). This merges first |
| entity-key-and-referential-contract | bidirectional | file-contention | the contract, `project-entity-model.md`, `project-schema.md`, project-initiator `SKILL.md`. This merges first |
| governance-surfaces-agree | bidirectional | file-contention | row-level edits |
| conformance-and-stewardship-mechanized | bidirectional | file-contention | row-level edits |
| ppm-agent-findings-become-artifacts | bidirectional | file-contention | row-level edits |
| issue-body-is-the-scope-of-record | — | ADR-number slot only | no shared file; both add a core ADR at the same next-free number, resolved at the second claim |

## Release Outcome Statement (as amended at Stage 5)

**AFTER** — Each portfolio-level surface — the weekly roll-up and its PORTFOLIO composer, the daily-status multi-project run, the health-check portfolio roll-up audit, the ppm-agent status answer, and project-initiator's registration, validation and closure of a project — selects its project set by portfolio under one rule, `portfolio-writeback-contract.md` § Portfolio scoping, and each portfolio's composed output lives in its own folder, `projects/_config/<portfolio_id>/PORTFOLIO.md`. A project whose `portfolio_id` names another portfolio never appears in a portfolio's output. On an install with two or more portfolios, a project with no `portfolio_id` appears in no portfolio's output and is listed to the operator as unassigned; on a single-portfolio install a project with no `portfolio_id` belongs to the only portfolio; with no Portfolio record, surfaces run unscoped and produce the same output as before.

**BEFORE** — The entity model admits more than one Portfolio record and gives each Project an optional `portfolio_id`, but every portfolio-level surface reads one PORTFOLIO.md and none reads `portfolio_id`. Keeping one portfolio's projects out of another portfolio's roll-ups depends on prose instructions and manual overrides of project-initiator Steps 5 and 5a.

**Actor(s):** the five operations skills and the deterministic composer, run by an operations session; built at Stage 6 under pmo-skill-editor discipline.

**Success Indicator:** the card's own probe, inverted. At the merge SHA, `portfolio_id` occurs at least once in each of the five skills, the composer and the write-back contract (0 in each at 8ed5e273, against a non-zero `PORTFOLIO.md` control), and the composer's `--self-test` passes its portfolio-scope, discrimination and single-portfolio-unchanged arms in the CI self-test job.

**Limb owners:** per-portfolio selection in the five skills and the composer → #8478 · one portfolio-tier rule, `portfolio-writeback-contract.md` § Portfolio scoping → #8478 · one composed file per portfolio folder, with the migration of an existing file → #8478 · unassigned and unresolved projects listed operator-side, nothing stops → #8478 · single-portfolio and no-record output unchanged → #8478

## Release Class declaration

Class: `novel`. Rationale: the plan carries D-class decisions (novel trigger b) and Stage 5 activates on skill-logic and structural-design triggers. No cross-cutting trigger fires: no pipeline stage file is edited, and two of the six rule-defining governance surfaces are (OPERATIONS.md, operator-executed, and the charter template), below trigger (b)'s three. Differentiation posture: engagement density Standard · Stage 9 review depth Deep · Stage 5 activation bias ALL · Stage 13 outcome window 30-day.

## Post-deploy handoff (operations session — not acceptance criteria)

Run immediately after Stage 12 Execute, in one operations session after `./deploy.sh --deploy`. On an install that already holds an active Portfolio record and still has its root composed file, every portfolio-level surface stops from deploy until step 3, by design. **The hold runs from step 1 through step 4:** no roll-up is run until step 4's read-back passes.

1. **Create any missing Portfolio record.**
   - Start from the operator's stated list of the portfolios the install runs — not from the keys projects carry.
   - For each, seed a record per `project-schema.md` § Entity-Seeding Protocol, Portfolio-tier step: `entity_type: Portfolio`, `lifecycle_state: active`, and its `portfolio_id` (a kebab slug, never `releases`), in **its own file** — never inside a composed `PORTFOLIO.md`, which the composer refuses. If the existing composed file's frontmatter carries Portfolio-record keys, move them into the record's own file.
   - Recommended location: `projects/_config/<portfolio_id>/`, created together with that portfolio's composed file (step 3).
   - Read back: the distinct active `portfolio_id` values equal the operator's stated list (a stated portfolio with no record is the state this read-back exists to catch), and every `portfolio_id` a project carries names one of them.
2. **Backfill `portfolio_id`.**
   - With two or more portfolios, every active project's `PROJECT.md` names its portfolio; an unkeyed project is unassigned and in no roll-up until it is keyed.
   - On an install that has been separating portfolios by manual override, backfill is **required at any number of portfolios, one included**: every project the behavioral correction kept out of a portfolio's roll-up carries the key that now keeps it out.
   - Otherwise, with one portfolio, backfill is optional. The key is written with no inline comment.
3. **Move the composed file and give every active portfolio its folder file.**
   - Move `projects/_config/PORTFOLIO.md` whole, frontmatter included (any `platform_config:` value survives), to `projects/_config/<portfolio_id>/PORTFOLIO.md` of the portfolio its projects belong to. On an install that already runs two portfolios by manual override, that is the first portfolio.
   - Create every other active portfolio's folder with an empty composed file in the section shape, so each active portfolio has exactly one folder file from the moment it is active. A record seeded later is seeded together with its folder file.
   - Read back: no root file remains beside a record — the direct read; `deploy.sh --check` Check 4 reads OK on either layout and is not evidence of the move — and each active portfolio has exactly one folder file.
4. **Re-emit the rollups.** Run ppm-agent's rollup emission for every active project, so each rollup carries its `portfolio_id`. Read back: for each portfolio, the composer at the projects root exits 0 with `held for re-emission … none` and `PROJECT.md portfolio_id polluted … none`. The hold ends here.
5. **Read back each portfolio's output.** At each portfolio's weekly Section 6 checkpoint, confirm:
   - the member set is exactly the projects whose `PROJECT.md` names that portfolio (with one portfolio, every project that names it or names none);
   - the report line's unassigned and unresolved fields read `none`;
   - no project of another portfolio appears, and — the sensitivity arm — no project the manual-override correction kept out of a portfolio appears in that portfolio's output (name those projects first, from the correction's own text).
6. **Narrow the behavioral correction; do not remove it.**
   - It now covers Daily Processing Cycle check 0(d), step 14, and check 0(f)'s `PORTFOLIO.md` item, and it states that `projects/_config/PORTFOLIO.md` is **not recreated** beside a Portfolio record (recreating it stops every portfolio-level surface). Those stay in force until #8546 ships; step 14 and check 0(f) are routed there.
   - Remove the rest: project-initiator Steps 5 and 5a no longer need manual overrides.
   - The interim read-back after each new project continues for those daily-cycle steps until #8546 ships.
7. **Recompose the workspace charter** with the next workspace update, so its portfolio rows appear. The deployed rules mirror is re-laid by `deploy.sh --deploy`.

## Operator Decisions — rendered

### Stage 4 plan gate (operator, 2026-11-28)

Recorded on #9150 (comment 7231189605): plan approved with its Outcome Statement and Parallelization Map; Release Class `novel`; **D-RuleHome (C)** — the rule's home deferred to Stage 5; **D-Resolver (C)** — each resolver finding routed to its owner; **D-ScopeGaps (A)** — the health-check and weekly references, the rollup template with contract § 2 and the ppm-agent emission, and project-initiator Mode B carried, the daily drift check 0(d) routed to #8546; **D-ProseSkillVerification (A)**; recorded determinations D-Version major (provisional `v6.00`), D-C SINGLE, D-Concurrency P0, release-identity `versioned · WV-1`.

### Stage 5 design gate, round 1 (operator, 2026-11-28)

Recorded on #9179 (comment 7232479692): the design package approved with the review's fix set plus the `PROJECT.md` cross-check; D-RuleHome (A) contract § Portfolio scoping; D-PortfolioRecordForm (A), counting distinct active `portfolio_id` values; D-EdgeReporting (A); **no default portfolio** (unassigned projects in no roll-up, listed operator-side, nothing stops); D-DefaultCarrier withdrawn; **D-ComposedOutput — the same filename per portfolio folder**; D-CrossPortfolioRefs CD-4; the post-deploy handoff per CD-5.

### Stage 5 design gate, round 2 (operator, 2026-11-28)

Recorded on #9179 (comment 7234438317), binding:
- **D-DriftCheckF (B):** the narrowed behavioral correction carries check 0(f)'s `PORTFOLIO.md` item and says the root file is not recreated beside a Portfolio record; Change 41 keeps limb 1 only; the charter template's Governance File Map row for the operations config folder gains the per-folder clause.
- **D-RecordlessTwoIds (B):** stop, and name the Portfolio records to create — stated in § 7.2's first row and in the report text; an install whose rollups name one portfolio or none still runs unscoped.
- **D-UnresolvedAtOnePortfolio (A):** a key naming no record is excluded and listed as unresolved at every N ≥ 1; the one-to-two-transition rationale is recorded in the contract.
- **D-RecordNotComposedFile (A):** the composer refuses (exit 2) a file named `PORTFOLIO.md` that carries `entity_type: Portfolio`; § 7.1 states this narrow exception to "never by its filename".
- **Twelve items absorbed at Stage 6** from the focused review: PR-D3, PR-D4, PR-D5, FM-D2, FM-D3, FM-D4, FM-D5, FM-D6, FM-D7, CD-D1 (b)–(d), CD-D2, and the Governance File Map clause.

### Stage 6 floored-card disposition (operator, 2026-11-28)

Recorded on #9180 (comment 7234535888): **split** — the Engineering spoke builds every other path and never edits `core/governance/OPERATIONS.md`; the operator commits the Change 41 limb-1 line on this branch from a hub-supplied command, after the draft PR opens and before Stage 7.

## Recommendations

- **Held for the Stage 9 follow-up filing step:** PR-6 — a deterministic served-portfolio resolver for the prose surfaces (R19); the `cmd_report` relative-path defect for its other two governance-presence entries (`follow-up: none · bug`).
- **Routing comments (hub):** #9178 — rung-2 layout continuity ships here, per-project selection stays its own; #2373 — each portfolio's composed file has a folder under `projects/_config/`, an output home keyed by `portfolio_id`, not a classifier; #8546 — check 0(f)'s `PORTFOLIO.md` item and the not-recreated clause, and that the charter's Governance File Map row now names the per-folder location its own criterion grades against.
- **ADR number:** this release and `issue-body-is-the-scope-of-record` both add a core ADR at the same next-free number; the second to merge is renumbered at its claim, and citations here use `{{ADR:portfolio-scoped-selection}}`.

## Deviation Log

| ID | Stage | Deviation | Decision |
|---|---|---|---|
| DEV-1 | 4 | Tier 1 [ADJUST] of the #8478 body after the plan gate: the D-ScopeGaps files in Affected Files, the AC1–AC3 method refinement (per surface), AC2's closure arm, AC3's zero-record case | operator, Stage-4 gate; applied by the hub |
| DEV-2 | 4 → 5 | D-RuleHome rendered (C), deferring the rule's home to Stage 5, against the plan's recommended (A); Stage 5 settled it as (A), the contract's new § 7 Portfolio scoping | operator, Stage-4 gate and Stage-5 round 1 |
| DEV-3 | 5 | The File Change Matrix is the Stage-5 delta's — 54 rows and 66 paths against the plan's 29 unconditional rows — after the round-1 decisions (no default portfolio; the same filename per portfolio folder). Changes 9 and 10 (the `operator.toml` key and schema) are withdrawn. Size L → XL, measured | operator, Stage-5 round 1; the delta re-spec |
| DEV-4 | 5 | D-DriftCheckF (B): Change 41 limb 2 (check 0(f)) is withdrawn; the narrowed correction carries the item; the charter template's Governance File Map row gains the per-folder clause | operator, Stage-5 round 2 |
| DEV-5 | 5 | D-RecordlessTwoIds (B), D-UnresolvedAtOnePortfolio (A) (the hub amends card Proposed Change item 4 and AC3) and D-RecordNotComposedFile (A) refine the round-1 wording for the states it did not contemplate | operator, Stage-5 round 2 |
| DEV-6 | 6 | `core/governance/OPERATIONS.md` (Change 41 limb 1) is built by the operator, not this spoke (split disposition). Until the operator's commit lands, this head carries the other 65 delta paths | operator, #9180 comment 7234535888 |
| DEV-7 | 6 | File Change Matrix rows added by the Stage-6 absorbed items: the ADR (the design calls for one; the delta's matrix omitted the row), `docs/workspace-setup.md` (PR-D4, the § 3 canonical mapping table gains the per-folder clause; was PRESERVE) and `core/specs/operational-artifact-inventory.md` (PR-D4, its `PORTFOLIO.md` row) | the round-2 absorbed list |
