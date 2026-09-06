---
title: Release Plan — external-seam-conduct-binds (external-seam conduct becomes a governed discipline, and the allowlist marker-region root cause is fixed)
type: release-plan
plan_type: release
status: Executing
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: external-seam-conduct-binds
release_class: novel
reversibility: CHEAP / Confidence HIGH — one new discipline plus additive bindings, one hook shipped warn-mode, and a bounded corrections limb; no deletion, no path relocation, no consumer contract narrowed
---
# Release Plan — `external-seam-conduct-binds`

**Milestone:** `external-seam-conduct-binds` · hub sub-task **#7048** = Stage 4 plan source and the operator decision record · **#7079** / **#7080** = the two Stage 5 design sources with their Phase A6.5 adversarial reviews · **#7081** = the Stage 6 Engineering sub-task that authored this file
**Version identity:** **versioned** — bump-class **`minor`**; the concrete `vX.Y` binds only at the Stage-12 atomic claim per [`RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Versioning Phase 2, so the plan file and branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp token. The Commit-0 version re-verify ran in full — see § Commit-0 Version Re-Verify Record.
**Topology:** D-C **SINGLE** — one release branch (`release/external-seam-conduct-binds`), one PR, one merge, base `main`; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch. Every non-serial posture prohibits force-push (including `--force-with-lease`) on the shared release branch; P0 is in force, so the prohibition is moot here and is recorded for completeness.
**Release class:** `novel` — verified at the Stage-4 gate against all four classes, only `novel` fires, on two independently sufficient triggers. Differentiation posture: engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7048 together with every **Decision Recorded** comment on that sub-task (D-Version · Plan Approval + D-Scope-6905 · D-ScaffoldReview), and reconciles them to the two Stage-5 design specifications on #7079 / #7080, their two Phase A6.5 adversarial reviews, and the **Collective Review scope-lock**. Where a later disposition superseded a Stage-4 assumption, the transcribed section carries the **ratified** value and § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #7081, card #6905).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Next-free was recomputed at Commit 0 against fresh authoritative host state and **agrees** with the Stage-4 reading; see § Commit-0 Version Re-Verify Record. |
| **Date Created** | 2026-09-05 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing |
| **Branch** | `release/external-seam-conduct-binds` |
| **PR** | #7174 — created **draft** at this Stage-6 pass; transitions to ready-for-review at the Stage 9 gate |
| **Milestone** | `external-seam-conduct-binds` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-05, domain: governance }`

*Classification rationale (Stage-4 A3-time, from the File Change Matrix):* every declared path is an internal pmo-platform artifact — disciplines, rules, hooks, skills, standards. Sourcing-exempt (Form X) and domain-classified `governance`. No secondary domain.

**Baseline pin:** `origin/main` = `18e3e787fe56efeab50a8f96660cffaa322e9d6c` · 2026-09-05T12:46:28-05:00. The release branch was cut from exactly this commit; Stage 9 Phase A6.5 re-checks divergence against it.

---

## Commit-0 Version Re-Verify Record

Per the Commit-0 obligation, next-free was recomputed against **fresh** authoritative host state before this file was written — never carried from the Stage-4 record.

| Step | Invocation | Result |
|---|---|---|
| 1 — refresh | `git fetch --tags origin && git fetch origin main` | 200 tags present locally; `origin/main` = `18e3e787` |
| 2 — recompute | `bash release/tools/claim-version.sh --dry-run --sha 18e3e787fe56efeab50a8f96660cffaa322e9d6c --bump minor` | `v4.57` (exit 0) |
| 3 — collision test | claimed-set probe over four surfaces (below) | **v4.57 absent everywhere → PROCEED** |

**Probe record (claimed-set membership).** Engine `python3`; ledger read via `git show origin/main:release/releases/RELEASE_LOG.md`, never the worktree copy.

| Surface | Denominator | Subject `v4.57` | Sensitivity arm `v4.56` | Specificity arm `v9.99` |
|---|---|---|---|---|
| local tags after `--tags` fetch | 200 tags | **absent** | PRESENT | absent |
| remote tags (`git ls-remote --tags origin`) | 200 refs | **absent** | PRESENT | absent |
| release-log ledger @ `origin/main` | 701,282 bytes / 2,302 lines | **0 occurrences** | 15 occurrences | 3 occurrences |
| plans directory @ `origin/main` | 204 plan files | **0 files** | 1 file (`plans/v4/v4.56_RELEASE_PLAN.md`) | 0 files |

The sensitivity arm fires on **all four** surfaces, so the subject's zero is a measured zero and not a dead reader. The specificity arm's 3 ledger hits were **read, not counted**: all three are prose in prior release rows narrating those releases' *own* specificity control tokens — the documented "control tokens the corpus itself narrates" false-positive class. It does not weaken the subject zero, which stands on a surface whose sensitivity arm returned 15.

**Verdict: PROCEED.** `v4.57` is not in the claimed set AND equals the recomputed next-free. No `[SCOPE CHANGE]` was raised.

---

## Scope

### Issues Included

| # | Issue | Title | Priority | Category | Labels |
|---|-------|-------|----------|----------|--------|
| 1 | #6905 | c3 §9 justifies the never-write invariant on an allowlist fact that is false against a live install | P2 | bug | `bug`, `status: proposed` |
| 2 | #6904 | External-seam conduct is held as an operator correction, not a governed discipline | P2 | governance | `status: proposed` |

### Dependency Graph

```
#6905 ──(soft: corrects the boundary statement #6904 is authored against)──▶ #6904
#6904 ──(no edge)──▶ #6905
```

**Hard edges: 0. Soft edges: 1. Circular chains: 0.**

#### Topologically Sorted Sequence

| Position | Issue | Priority | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 1 | #6905 | P2 | bundled | (none — root) | — |
| 2 | #6904 | P2 | bundled | #6905 (soft/informational) | DEPENDS_ON |

#### Artifact Relationship Graph

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #6904 | DEPENDS_ON | #6905 | #6904 → #6905 | body/analysis (soft, informational — not a native `blocked-by` edge) |
| #6905 | GENERATES | core/hooks/tests/allowlist-add.test.sh | #6905 → file | File Change Matrix (add) |
| #6904 | GENERATES | core/disciplines/external-seam-conduct.md | #6904 → file | File Change Matrix (add) |
| #6904 | GENERATES | core/hooks/block-external-seam-shape.sh | #6904 → file | File Change Matrix (add) |
| #6904 | GENERATES | core/hooks/tests/block-external-seam-shape.test.sh | #6904 → file | File Change Matrix (add) |

**Directional evidence, and the correction that overturned its original basis.** The Stage-4 record justified the ordering partly on a `git grep` finding that `core/mcp-write-allowlist.txt` had no consumer outside the standard. That finding is **falsified** and does not survive into this plan: two live consumers construct the path dynamically as `${HOOK_DIR}/../mcp-write-allowlist.txt` (`core/hooks/block-mcp-writes.sh:43`, `core/hooks/tests/block-mcp-writes.test.sh:11`), which a literal-string search structurally cannot see. The ordering still holds on its own merits — #6905 corrects the §9 statement #6904's Foundation step is authored against — but it no longer rests on the orphan claim. See § Deviation Log D-6-0.

### File Change Matrix

Machine-readable, one path per line, verb-bearing. Intent enum `add | edit | delete`. This is the **post-Collective-Review** set for both cards; the Stage-4 draft is superseded.

```
# ── #6905 — Corrections (step 1) ──────────────────────────────
core/standards/c3-external-sync-path-b.md                          edit
core/hooks/allowlist-add.sh                                        edit
core/hooks/tests/allowlist-add.test.sh                             add
core/rules/bypass-mode-readiness/_cross-cutting.md                 edit

# ── #6904 — Foundation (step 2) ───────────────────────────────
core/disciplines/external-seam-conduct.md                          add

# ── #6904 — Binding, ungated limb (step 3) ────────────────────
core/disciplines/reconcile-dont-annotate.md                        edit
core/disciplines/README.md                                         edit
core/CLAUDE.md.template                                            edit
core/rules/decision-time-adherence.md                              edit
operations/skills/intake-desk/SKILL.md                             edit

# ── #6904 — Binding, sanctioned-session limb (step 4) ─────────
operations/skills/comms-writer/SKILL.md                            edit
operations/skills/delivery-engine/SKILL.md                         edit
operations/skills/daily-status/SKILL.md                            edit
operations/skills/pmo-process-designer/SKILL.md                    edit
operations/skills/health-check/SKILL.md                            edit

# ── #6904 — Enforcement (step 5) ──────────────────────────────
core/hooks/block-external-seam-shape.sh                            add
core/hooks/tests/block-external-seam-shape.test.sh                 add
core/rules/bypass-mode-readiness/_header.md                        edit
core/rules/bypass-mode-readiness.md                                edit
```

```
#### Read-only inputs
core/deploy/compose.py                                             READ
core/hooks/block-mcp-writes.sh                                     READ
core/hooks/tests/block-mcp-writes.test.sh                          READ
core/hooks/tests/test-runner.sh                                    READ
core/hooks/block-scope-segregation.sh                              READ
core/standards/progressive-rollout-convention.md                   READ

#### Release-wide explicit non-scope
core/mcp-write-allowlist.txt                                       NOT EDITED
core/config/allowlists/mcp-write-allowlist.txt                     NOT EDITED
core/deploy/compose.py                                             NOT EDITED
```

**`core/rules/bypass-mode-readiness.md` is REGENERATED, never hand-edited.** It is tool output from `core/deploy/tools/build-hook-registry.py` over the `core/rules/bypass-mode-readiness/` fragment directory. Deploy-check Check 38 is an always-enforce regenerate-and-diff and is carried inside the pre-merge required-check subset, so a hand-edited cell reads as drift and a stale index blocks the merge.

**Regen coordination — the single release-level rule (binding, from Collective Review).** Both cards edit fragments under `core/rules/bypass-mode-readiness/`: #6905 edits `_cross-cutting.md` (the allowlist-maintenance paragraph), #6904 edits `_header.md` and, because its hook takes its own `.seam-shape-mode`, the own-mode-file cohort list in `_cross-cutting.md` as well. **The regeneration runs ONCE, in #6904's Engineering pass, after both cards' fragment edits have landed.** `./deploy.sh --check` is graded clean at **release level**, not per-card. Check 38 reading STALE between #6905's commit and #6904's regeneration is the **approved intermediate state**, not a defect; regenerating out of turn produces an index a later fragment edit immediately invalidates.

**Path-count reconciliation (recorded, not silently averaged).** #6904's Stage-5 output states a total of **17** declared paths; the implementation-sequence table that is its artifact of record enumerates **15**, and the Collective Review adds `_cross-cutting.md` as a sixteenth. The matrix above transcribes the **16 paths the artifact of record supports**, plus #6905's 4, for a release total of **20**. The 1-path gap between #6904's stated total and its own enumeration is #6904's to reconcile at its Engineering pass; it is named here rather than resolved by guess, because the Collective Review's own root-cause finding on this release was a set derived from a restatement rather than from the artifact.

### File Contention Map

| File | Issues | Intent Mix | Severity | Recommendation |
|---|---|---|---|---|
| `core/rules/bypass-mode-readiness/_cross-cutting.md` | #6905, #6904 | edit×2 | **BINARY** | Sequencing required, and it is already imposed: P0 fully-serial with #6905 leading. The two edits are in **different paragraphs** — #6905 in § Allowlist Maintenance (the atomic-append paragraph), #6904 in § Warn-Mode vs. Enforce-Mode (the own-mode-file cohort list) — so this is a same-file, disjoint-region edit under serial execution |
| `core/rules/bypass-mode-readiness.md` | #6905, #6904 | edit×2 (generated) | **BINARY** | Resolved by the single release-level regeneration rule above: exactly one regeneration, owned by #6904's pass, after both fragment edits |

**This map supersedes the Stage-4 `A ∩ B = ∅` finding.** That finding was computed from the hub's own sub-task brief rather than from the designs' declared write sets, and both adversarial reviewers independently falsified it. The intersection is **two files**, both consequences of the operator's D-CascadeRows decision, which was rendered after the Stage-4 disjointness was computed. Recorded as a supersession rather than a correction-in-place so the reasoning chain stays legible.

### Cross-Milestone Dependency Validation

#### G3-07 Status

`PASS — 1 dependency edge checked, 0 cross-milestone violations`

The single edge (#6904 → #6905, soft/informational) is **intra-milestone**: both endpoints sit in `external-seam-conduct-binds`, so no cross-milestone gap exists to measure.

#### Violations

N/A — enumerated over the release's complete dependency-edge set (1 edge, both endpoints read); none crosses a milestone boundary.

#### Resolved Edges (B is Done)

N/A — enumerated over the same 1-edge set; no endpoint is Done in a closed milestone.

#### Registered Exceptions

N/A — enumerated over the violation set, which is empty; an exception can only register against a violation.

### Bundle Refresh State

N/A — enumerated over the four refresh triggers (T1 new-approved-issues, T2 priority shift, T3 dep-state change, T4 Stage-4 boundary). Gate G-BR did not fire non-no-op since the last Mode A/B invocation for this bundle, so the conditional section is correctly absent.

### Exclusions

Items explicitly NOT in this release and why:

- **The deployed-instance allowlist repair** (10 operator entries sitting below the END marker across two deployed allowlists — 8 in `mcp-write`, 2 in `webfetch`). Operator-instance state under the deploy root, outside every session's write domain in this release. Tracked as **AI-001**, owner operator. The tool fix in #6905 prevents recurrence on every future append; it does **not** relocate entries already misplaced. The two are complementary, not alternatives.
- **`core/mcp-write-allowlist.txt`** — NOT edited, and explicitly **NOT retired**. It carries no marker region to fix, and the Stage-4 near-orphan reading that suggested retirement is falsified: it is the in-repo landing surface `block-mcp-writes.sh:43` resolves and `block-mcp-writes.test.sh:11` seeds and restores. Deleting it turns the hook suite red.
- **Lifting the marker grammar into `compose.py` as a `locate-operator-region` subcommand.** The durable fix for having two readers of one fence, and unavailable today: `compose.py` is absent from the deployed `.claude/` tree, so a deployed hook helper cannot call it. Recorded as the reason the point-fix altitude is *forced* rather than chosen.

---

## Implementation Sequence

Dependency-ordered. Commit 0 is this file; steps 1–5 are the two cards' Engineering passes on the single release branch, P0 fully-serial.

| # | Step | Card | Session | Notes |
|---|---|---|---|---|
| **0** | Release plan committed to branch | — | ordinary spoke | Engineering Commit 0 |
| **1** | **Corrections** — §9 rationale + sibling, the allowlist marker-region fix, its test, and the operator-guidance cascade | #6905 | ordinary spoke | Leads. Corrects the boundary statement step 2 is authored against |
| **2** | **Foundation** — `external-seam-conduct.md` | #6904 | ordinary spoke | The artefact everything else cites |
| **3** | **Binding, ungated limb** | #6904 | ordinary spoke | `reconcile-dont-annotate.md` · `disciplines/README.md` · `CLAUDE.md.template` · `decision-time-adherence.md` · `intake-desk/SKILL.md` (not armed → needs no sanctioned session) |
| **4** | **Binding, sanctioned-session limb** | #6904 | `pmo-skill-editor` Mode A | The five armed SKILL.md targets; one session, five edits |
| **5** | **Enforcement** — hook + tests + `_header.md` + **the single release-level index regeneration** | #6904 | ordinary spoke | Runs last, so the one regeneration lands after every fragment edit in the release |

### Issue #6905: c3 §9 justifies the never-write invariant on an allowlist fact that is false against a live install

**Change Specification:**

- **Files modified:** `core/standards/c3-external-sync-path-b.md`, `core/hooks/allowlist-add.sh`, `core/hooks/tests/allowlist-add.test.sh` (new), `core/rules/bypass-mode-readiness/_cross-cutting.md`
- **Change description:** Scope is **option (b)** — correct the standard AND fix the tool — rendered by the operator at D-Scope-6905.
  1. **§9 reason (b)** stops asserting a per-install allowlist-contents fact and instead names where live control state is actually read (the deployed `<deploy-root>/.claude/` surface), with the two read commands a future auditor executes. Reasons (a) and (c) are preserved byte-unchanged. The replacement decouples the invariant from configuration entirely, reusing §8's existing frame — C3 self-limits regardless of enforcement posture — so no future config change can falsify §9 again.
  2. **§9's sibling site** (the "if a future capability genuinely needs external write-back" paragraph) stops naming the in-repo test fixture as where live write verbs would be added, and names the deployed allowlist instead. Rendered YES by the operator at D-2: leaving it makes §9 name two different files as "the allowlist" thirteen lines apart, immediately after an edit whose purpose is to make that surface legible, and it is a plausible CIAC-2 miss.
  3. **`allowlist-add.sh`** inserts the entry immediately before the first `END OPERATOR ADDITIONS` marker that follows the first `BEGIN` — the exact span `compose.py::extract_operator_additions()` preserves — instead of appending at EOF where the extractor silently drops it at the next regeneration. A target with no marker region degrades to the existing EOF append; a target with a marker but no usable span appends and **warns**. The marker grammar is a line-anchored transliteration of `compose.py`'s `_fence_re` and a deliberate strict subset of it.
  4. **A new test suite** asserts the property the card is about — the entry survives the authoritative extractor — rather than a line-position proxy, and carries a RED regression witness, a detector-reachability control, and a marker-spelling agreement arm.
  5. **The operator guidance** in `_cross-cutting.md` § Allowlist Maintenance tells an operator their entry now survives regeneration, and corrects the 8-vs-9 count defect in that same paragraph (the helper validates against 9 known allowlists; the registry table enumerates 8, and the ninth is assigned to another discipline by that file's own § Allowlist Maintenance boundary note).
- **Acceptance criteria:** AC-1..AC-5 from the card, with AC-4 re-targeted at D-Scope-6905 (see § Verification Plan).
- **Estimated complexity:** Medium — one prose limb, one shipped-executable limb with a test.
- **Dependencies:** None.

### Issue #6904: External-seam conduct is held as an operator correction, not a governed discipline

**Change Specification:**

- **Files modified:** the 16 paths enumerated in the File Change Matrix under #6904.
- **Change description:** Author `core/disciplines/external-seam-conduct.md` as the governed home for external-seam conduct, bind it from the charter template, the disciplines README, `reconcile-dont-annotate.md`, a `decision-time-adherence.md` trigger row, and six skill SKILL.md files; ship a warn-mode PreToolUse shape gate with its own `.seam-shape-mode`, its RED/GREEN/CONTROL test set, the `_header.md` registry-external enumeration update, and the single release-level index regeneration.
- **Acceptance criteria:** per the card; graded at Stage 8.
- **Estimated complexity:** High — 16 paths across four artifact classes, one of them requiring a sanctioned session.
- **Dependencies:** #6905 (soft/informational — sequencing only, not blocking).

### Agent-Editability Read

**Derivation** — controls read at commit `18e3e787`:

- Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh` — **2** `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"` (`:703`, `:734`). Block 1's three `.claude/` arms project to paths `git ls-files '.claude/*'` reports as **0 tracked**, so they are discarded for this release under the unreachable-arm rule. Block 2 is the operative anchor-free arm; its basename arms (`*/CLAUDE.md`, `*/OPERATIONS.md`, `*/RELEASE_PROTOCOL.md`) match **3 tracked paths**, none of which is in this release's write set — so the all-`unconstrained` Tier-0 column below is a discriminating negative, not a floor that matches nothing.
- Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`; arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`; exemption list resolved at the deployed path — **present (1 entry)**. Arming-key control arm: **52 of 57** SKILL.md armed corpus-wide, so a `not-armed` reading discriminates.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|------|----------------|----------|--------------|-----------|-----------|----------------|
| #6905 | `core/standards/c3-external-sync-path-b.md` | no | no (c1 false) | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6905 | `core/hooks/allowlist-add.sh` | no | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6905 | `core/hooks/tests/allowlist-add.test.sh` | no | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6905 | `core/rules/bypass-mode-readiness/_cross-cutting.md` | no | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `core/disciplines/external-seam-conduct.md` | no | no (c1 false) | `unconstrained` | **`sanctioned-session-required`** | ordinary Engineering spoke |
| #6904 | `core/disciplines/reconcile-dont-annotate.md` | no | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `core/disciplines/README.md` | no | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `core/CLAUDE.md.template` | no — basename is `CLAUDE.md.template`, matching neither `*/CLAUDE.md` nor the anchored arms | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `core/rules/decision-time-adherence.md` | no — the floor names the deployed `.claude/rules/`, not `core/rules/` | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `operations/skills/intake-desk/SKILL.md` | no | **no — decided at conjunct 2** (arming key ABSENT) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `operations/skills/comms-writer/SKILL.md` | no | **yes** — c1 ∧ c2 ∧ c3 | **`sanctioned-session-required`** | ↑ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6904 | `operations/skills/delivery-engine/SKILL.md` | no | **yes** | **`sanctioned-session-required`** | ↑ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6904 | `operations/skills/daily-status/SKILL.md` | no | **yes** | **`sanctioned-session-required`** | ↑ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6904 | `operations/skills/pmo-process-designer/SKILL.md` | no | **yes** | **`sanctioned-session-required`** | ↑ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6904 | `operations/skills/health-check/SKILL.md` | no | **yes** | **`sanctioned-session-required`** | ↑ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6904 | `core/hooks/block-external-seam-shape.sh` | no — arm discarded (untracked `.claude/`) | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `core/hooks/tests/block-external-seam-shape.test.sh` | no | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `core/rules/bypass-mode-readiness/_header.md` | no | no (c1 false) | `unconstrained` | ↑ | ordinary Engineering spoke |
| #6904 | `core/rules/bypass-mode-readiness.md` *(generated)* | no | no (c1 false) | `unconstrained` — class of its source shards | ↑ | build script (`build-hook-registry.py`), not a `Write`/`Edit` payload |

Per-path rows are retained, never collapsed into the card class. **No path in this release is `tier-0-floored`, and none is `undetermined`** — the exemption list resolved at the deployed path, so no conjunct failed safe.

---

## Stage Applicability Matrix

| Stage | #6904 | #6905 | Basis |
|---|---|---|---|
| **5 Solutioning** | APPLY | APPLY | `novel` biases ALL. #6905 is not the trivial edit it looks like — its root cause sits in a shipped tool |
| **6 Engineering** | APPLY | APPLY | — |
| **7 Dev Testing** | APPLY | **APPLY (now unconditional)** | #6904 ships a hook with a mandated RED/GREEN/CONTROL set. #6905's Stage-7 row was conditional at Stage 4 and is **promoted to unconditional** by D-Scope-6905 option (b): it now ships a modified executable and a new test suite |
| **8 QA / Acceptance** | APPLY | APPLY | Both carry per-criterion ACs requiring verdicts |
| **9 Plan Review** | APPLY — **Deep** | APPLY — **Deep** | `novel` → Deep review depth (release-scoped) |
| **12 Execute** | APPLY | APPLY | Version binds at the atomic claim |
| **13 Close** | APPLY | APPLY | Both marked as closed at Stage 13 |

**No stage is skipped for either card.** Stated as a positive finding: Stage-5 skip-eligibility (trivial-change test) and Stage-7/8 skip-eligibility (no-functional-impact test) were both evaluated for both cards, and all four tests failed.

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| 1 | **Silent loss of security-control state** — a marker-unaware append puts an operator's allowlist entry outside the region `extract_operator_additions()` preserves, so it vanishes at the next regeneration with no error | High (2 of 2 deployed files carrying operator additions are affected) | High | #6905's insert-before-END fix, plus a test whose GREEN arm asserts survival through the real extractor rather than a line-position proxy | Engineering |
| 2 | **A looser marker reader than `compose.py`'s** would find a region the extractor will not honour, insert into it, report success, and **suppress** the malformed-target warning — worse than the status quo on exactly the inputs the warning exists to catch | Medium | High | The helper's grammar is a line-anchored transliteration of `_fence_re` and a deliberate strict subset; the subset relation is asserted by a spelling-matrix test arm, not claimed in prose | Engineering |
| 3 | **A literal implementation of the Stage-5 line citation** (`112-119`) would delete the `ts=` assignment at `:119`, leaving `:120` referencing an unset variable under `set -u` — every successful add would exit non-zero after a successful `mv` | Medium | High | Collective Review binding instruction 2 re-targets the block to `106–116`; the test suite's successful-add arms assert exit 0, so the class is gate-caught | Engineering |
| 4 | **Generated-index staleness / double regeneration.** Both cards edit fragments feeding `bypass-mode-readiness.md`; Check 38 is always-enforce and merge-blocking | Medium | Medium | Single release-level regeneration owned by #6904's pass, after both fragment edits. Check 38 STALE between the two passes is the approved intermediate state | Engineering |
| 5 | **Test-suite structural contract.** `test-runner.sh` counts a suite that does not emit the exact `Total: N  PASS: N  FAIL: N` line (two spaces) as a FAIL even when every assertion passes | Medium | Medium | The summary and exit shape are copied from `block-mcp-writes.test.sh`; the runner's own regex is quoted in the test file's header | Engineering |
| 6 | **Fixture cross-talk.** Two suites now seed and restore the same `core/mcp-write-allowlist.txt`, and the ambient file has no trailing newline | Medium | Low | Byte-faithful save/restore via a temp-file copy on `trap EXIT`, not a `$(cat)` round-trip that strips trailing newlines | Engineering |
| 7 | **Mirror-pair link-form defect on `decision-time-adherence.md`.** A relative link to the new discipline resolves in-repo, passes every pre-merge gate, and breaks only at the deployed mirror | Medium | Medium | Workspace-rooted (`/core/disciplines/…`) form mandated in #6904's brief | Engineering (#6904) |
| 8 | **Rollback asymmetry.** Corpus edits revert with the commit; the hook is copied to the runtime hooks directory by `deploy.sh`, so reverting does not by itself un-deploy it | Low | Medium | Warn-mode-initial bounds the blast radius to log noise; rollback is revert-then-redeploy on a normal schedule | Operator |
| 9 | **Scope density on #6904** — 16 paths across four artifact classes concentrates review load at Stage 9 Deep | Medium | Medium | Five-step execution split with the sanctioned-session limb isolated; per-step commits keep the diff readable | Engineering |
| 10 | **Detector blindness on #6904's shape gate** — an empty payload extraction reads green | Medium → Low | Medium | `block-scope-segregation.sh`'s CD-3 fail-closed extraction is a copyable working precedent; the mandatory CONTROL arm stays | Engineering (#6904) |
| 11 | **Both cards carry `status: proposed`**, never `approved`; the Stage-4 lifecycle expects Bundled with a rendered Triage decision | High | Low | Governance-sequence gap, not a technical one. Recorded; resolved at Stage 13 label transition | Operator |

---

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered), D-C SINGLE, P0 fully-serial |
| **Commit strategy** | Grouped commits — one per Implementation-Sequence step, plus Commit 0 for this plan |
| **Review approach** | Single PR for the entire release (one milestone, one PR, one merge) |
| **Deployment mechanism** | Git merge + S-2 skill copy + `deploy.sh --deploy` for the hook and rules mirror |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (default — Option A). No stacked-base waves are planned |

**Branch:** `release/external-seam-conduct-binds` (slug-primary, pre-claim). The plan file moves one directory deeper at the Stage-12 atomic claim, so **every intra-repo link in this file is workspace-rooted** (leading `/`); no relative form is correct at both depths.

---

## Verification Plan

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6905 | AC-1 | `python3` file-scoped predicate over `core/standards/c3-external-sync-path-b.md`: count lines matching `(?i)(they are NOT|test allowlist whose|does not match the live)`. Engine stated because this host's `grep` is a ugrep shim that can return a plausible zero on a rejected pattern | **0** · control: the identical predicate against the pre-fix file content (`git show 18e3e787:core/standards/c3-external-sync-path-b.md`) → **must return ≥1**; a zero on both arms is a broken probe, not a pass |
| #6905 | AC-2 | `python3` count of `.claude/` occurrences in `core/standards/c3-external-sync-path-b.md` §9, plus presence of both audit-read commands (`mcp-write-allowlist.txt` and `hooks/.mode` under a `.claude/` path) | **≥1 `.claude/` occurrence in §9 and both read commands present** · control: the identical count against the pre-fix file → **0 in §9** |
| #6905 | AC-3 | `git diff 18e3e787 -- core/standards/c3-external-sync-path-b.md`, read the hunk: reasons (a) and (c) must appear in no removed line | Reasons (a) and (c) **byte-identical**; only reason (b) and the sibling paragraph appear in the diff |
| #6905 | AC-4 *(re-targeted at D-Scope-6905)* | `bash core/hooks/tests/allowlist-add.test.sh` — arms T-1 (position), T-2 (survives the real `compose.py` extractor), T-3 (RED witness), T-5 (detector reachability) | **All arms PASS**, and the summary line reports `FAIL: 0`. T-3 must fail on unfixed code — it is the arm that makes T-1/T-2 a genuine RED→GREEN pair rather than a bare positive |
| #6905 | AC-5 | `bash core/deploy/deploy.sh --check`, graded at **release level** after #6904's Enforcement pass lands the single index regeneration | Clean. **Check 38 reading STALE between #6905's commit and that regeneration is expected and approved**, not a finding |
| #6904 | AC-1..AC-8 | Per #6904's Stage-5 design; graded at its own Engineering and QA passes | Per that design |

**AC baseline** — per-issue criterion counts as read at plan time, and the commit SHA read against.

`ac_baseline: { #6905: 5, #6904: 8, read_at: 18e3e787fe56efeab50a8f96660cffaa322e9d6c }`

### Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#6904 × #6905 on the external-seam write-permission premise):** the new discipline artefact does not assert, restate, or depend on the stale §9 reason (b) claim that live connector write verbs are absent from the resolved allowlist — the claim #6905 removes. *Method:* `grep -inE "not (present|in) the allowlist|absent from the allowlist|do(es)? not (appear|match).*allowlist" core/disciplines/external-seam-conduct.md` → expect **0** · control: the same pattern against `core/standards/c3-external-sync-path-b.md` at the pre-#6905 commit → expect **non-zero** (the arm proves the pattern matches the construct it is hunting, on the same instrument). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#6904 × #6905 on live-control-state resolution):** both cards' outputs name the **deployed** `.claude/` resolution surface — not the in-repo `core/mcp-write-allowlist.txt` test fixture — wherever they tell a reader where live control state is read. *Method:* `grep -c "\.claude/" core/standards/c3-external-sync-path-b.md core/disciplines/external-seam-conduct.md` → expect **≥1 in each** · control: `grep -c "core/mcp-write-allowlist.txt" core/disciplines/external-seam-conduct.md` → expect **0**, with the same pattern against the pre-#6905 `c3-external-sync-path-b.md` returning **2** to prove the pattern resolves. *Graded at Stage 9 QC3.5 on the merged PR.*

Both CIACs span 2 issues with no dependency edge required, which is exactly the CIAC (not `INT-N`) case. Both carry control arms per AC-Binding Limb 2 — recorded honestly: Limb 2 is an **authoring convention with no executor today**, so these arms are what a human reviewer checks, not what a gate enforces.

**Integration ACs (`INT-N`): none.** Neither card carries a native `blocked-by` edge; the only edge in the release is soft/informational. Omission is the correct non-ceremony signal, and the cross-card coupling is carried as CIAC-1/CIAC-2 — the right instrument for a no-dependency-edge pair.

### Release-Level Verification

Per the verification checklist:

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity
- [ ] Skill Invocation
- [ ] Output Contract Compliance

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #6905 | `git revert <commit>` — four files, no schema or contract change, CLI contract of the helper byte-identical before and after | Low |
| #6904 | `git revert <commit>` for the corpus limbs; the hook additionally requires `./deploy.sh --deploy` to un-deploy the runtime copy | Medium |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure | Revert the specific commits per the rollback protocol |
| **Full Restore** | Systemic failure | Revert the merge commit per the rollback protocol, then re-run `./deploy.sh --deploy` so the runtime hook tree matches the reverted source |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per the rollback protocol |

Single release branch (D-C SINGLE), so the whole release reverts as one merge-revert — CHEAP for every corpus limb. The one non-corpus limb is #6904's hook; because it ships **warn-mode**, a defective detector produces log entries rather than refusals, so the release is safe to roll back on a normal schedule rather than urgently.

---

## Operational Deployment Manifest

Layer 2 file propagation targets for Stage 12/13:

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `core/hooks/allowlist-add.sh` | `<deploy-root>/.claude/hooks/allowlist-add.sh` | `deploy.sh --deploy` hook sync | `diff -q` shows no differences |
| 2 | `core/hooks/block-external-seam-shape.sh` | `<deploy-root>/.claude/hooks/block-external-seam-shape.sh` | `deploy.sh --deploy` hook sync | `diff -q` shows no differences |
| 3 | `core/rules/decision-time-adherence.md` | `<deploy-root>/.claude/rules/decision-time-adherence.md` | mirror-pair sync (deploy-produced) | `deploy.sh --check` Check 9 in sync |
| 4 | `core/rules/bypass-mode-readiness.md` | `<deploy-root>/.claude/rules/bypass-mode-readiness.md` | mirror-pair sync (deploy-produced) | `deploy.sh --check` Check 9 in sync; Check 38 FRESH |
| 5 | `operations/skills/*/SKILL.md` (6 targets) | installed skill paths | S-2 direct copy + package rebuild | `deploy.sh --check` Check 7 / package freshness |

### Schema Migrations (if applicable)

N/A — enumerated over the migration classes this platform performs (frontmatter-field addition or rename, tracker-schema change, entity-id re-keying, allowlist-format change, generated-index format change). None is present in this release: the allowlist **format** is unchanged and only the *insertion position* moves, and the generated index is regenerated by its existing tool with no format change.

---

## Verification Evidence

(Populated after Stage 12 execution — see the verification checklist for format.)

---

## Deployment Execution Log

(Populated during Stage 12 — see the execution checklist.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

---

## Hub-Rendered D-Decisions

| ID | Decision | Verdict | Authority | Reversibility |
|---|---|---|---|---|
| **D-Version** | This release's next-free version | `v4.57` — a **recorded determination**, not an operator gate; binds at the Stage-12 atomic claim | hub (rule-computed) | CHEAP · HIGH |
| **D-PlanApproval** | Stage 4 release plan | **APPROVED as planned**; #6905 leads, neither card splits, D-C SINGLE | operator | MODERATE · HIGH |
| **D-Scope-6905** | How far does #6905 reach? | **(b) — root-cause fix.** Correct §9 AND fix the tool. Promotes #6905's Stage 7/8 rows to unconditional | operator | CHEAP · HIGH |
| **D-ReleaseClass** | Release class + differentiation posture | `novel`; Standard / Deep / ALL / 30-day | operator | CHEAP · HIGH |
| **D-Concurrency Posture** | Stage-6 dispatch | **P0 fully-serial** (default when undeclared) | hub (rule-determined) | CHEAP · HIGH |
| **D-2** | Include the §9 line-215 sibling fix? | **YES** — §9 would otherwise name two different files as "the allowlist" thirteen lines apart, and it is a plausible CIAC-2 miss | operator | CHEAP · HIGH |
| **D-CascadeRows** | Update the `bypass-mode-readiness` operator guidance? | **YES** — write set 3 → 5 files for #6905; the generated index is regenerated, never hand-edited | operator | CHEAP · HIGH |
| **D-SHARD** | #6904's registry membership | option (a) — recorded on #7080 | operator | CHEAP · HIGH |
| **D-CollectiveReview-ScopeLock** | Cross-card scope | **APPROVED; scope hard-locked through Stage 9**, with three binding Stage-6 instructions (regen coordination · line-range correction · verb-anchored gate) | operator | MODERATE · HIGH |

---

## Deviation Log

| ID | Deviation | Authority | Rationale |
|---|---|---|---|
| **D-6-0** | The Stage-4 "near-orphan / candidate for retirement" finding on `core/mcp-write-allowlist.txt` is **not** carried into this plan; the file is recorded as KEEP under § Exclusions | Stage-5 design (#7079) + independent adversarial confirmation | The finding came from a literal-string `git grep`, which structurally cannot see the two live consumers that construct the path as `${HOOK_DIR}/../mcp-write-allowlist.txt`. Retiring the file would turn the hook suite red |
| **D-6-1** | The Stage-4 `A ∩ B = ∅` contention finding is **superseded** by a two-file BINARY contention map | Collective Review Check 2 | The operator's D-CascadeRows decision, rendered after Stage 4, put both cards on `_cross-cutting.md` and on the generated index. The Stage-4 set was built from a restatement rather than from the designs' declared write sets |
| **D-6-2** | The Stage-5 implementation citation `allowlist-add.sh:112-119` is **not** followed; the edit targets `106–116` | Collective Review binding instruction 2 | The cited range excludes the `mktemp`/`cat` it claims to contain and includes the `ts=` assignment at `:119`; a literal implementation makes every successful add exit non-zero under `set -u` |
| **D-6-3** | The Stage-5 marker-reader claim that "the two readers agree by construction" is **not** carried; the helper's grammar is written as an explicit strict subset of `_fence_re` and the subset relation is asserted by a test arm | Collective Review Check 3 (PRF-2) | A reader looser than the authoritative one finds regions the extractor will not honour and **suppresses** the very warning that exists to catch them |
| **D-6-4** | #6905's write set is **4 files, not 5**: it does not include `core/rules/bypass-mode-readiness.md` | Collective Review binding instruction 1 | The single release-level regeneration is owned by #6904's Engineering pass, which runs after both cards' fragment edits. #6905 committing a regenerated index would produce one that #6904's later `_header.md` edit immediately invalidates |
| **D-6-5** | The helper warns on **either** malformed marker shape — a BEGIN with no usable END, *or* an END with no preceding BEGIN — rather than only the first, which is all the Stage-5 case table enumerated | Engineering, logged here | Both shapes are files whose entries the extractor will drop, and both are the "genuinely-broken path" D-4's own safety property says must be loud. The marker-less path stays silent, so the stated discriminator is preserved and only strengthened. Cost: one additional awk field |
| **D-6-6** | #6904's path count is transcribed as **16** (the artifact of record) rather than the **17** its Stage-5 output states | Engineering, logged here | Naming the 1-path gap is the honest reading; resolving it by guess would repeat the exact defect the Collective Review root-caused — a set derived from a restatement rather than from the artifact |

---

## Change Description

(Authored by the Stage 6 release-engineering spoke at PR-creation time. Operator-facing, pre-merge. Distinct from the user-facing release note authored at Stage 13 Close.)

### Outcome

This release turns external-seam conduct from an operator correction the agent happens to be carrying into a governed discipline with a warn-mode gate behind it, and it fixes a silent-loss defect in the tool operators are told to use when granting an allowlist permission. Before this release, an entry added through `allowlist-add.sh` landed at end-of-file — outside the region the update path preserves — so it disappeared at the next regeneration with no error and no log line. After it, the entry lands inside the preserved region, and a target whose markers are broken says so on stderr instead of failing quietly.

The second half is a legibility fix on the boundary itself: the standard that states the never-write invariant justified it partly on what a particular install's allowlist happened to contain, which was false against a real deployment. It now names where the live control state is actually read and states that the invariant does not depend on it — so a future configuration change cannot falsify the standard again.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #6905 | The never-write rationale stops resting on a per-install fact, and allowlist entries now survive regeneration | DONE |
| #6904 | External-seam conduct becomes a governed discipline, bound from the charter and six skills, with a warn-mode shape gate | DONE |

### Key decisions

- **D-Scope-6905:** option (b) — correct the standard *and* fix the tool. Relocating the misplaced entries alone would have held only until the next marker-unaware append re-broke them.
- **D-2:** include the §9 sibling fix, so the section does not name two different files as "the allowlist" thirteen lines apart.
- **D-CascadeRows:** update the operator-facing allowlist guidance, so an operator learns their entry now survives regeneration.
- **D-CollectiveReview-ScopeLock:** scope hard-locked through Stage 9, with the single release-level index regeneration assigned to #6904's pass.

### Reversibility

**CHEAP — HIGH confidence.** `git revert` of the release merge restores prior behavior exactly for every corpus limb; the helper's CLI contract is byte-identical before and after, so nothing downstream has to change back. The one non-corpus limb is #6904's hook, which additionally needs `./deploy.sh --deploy` to un-deploy the runtime copy — and it ships warn-mode, so a defective detector logs rather than blocks.

### Downstream impact

- Every future `allowlist-add.sh` invocation, on all nine known allowlists, writes into the preserved region — this is the fix that makes the pending operator-instance repair (AI-001) durable rather than temporary.
- The new discipline is the citation target for future external-seam work; its warn-mode gate is the shakedown input for a later flip-to-enforce decision.
- `core/rules/bypass-mode-readiness.md` is regenerated once, at the end of the release; consumers of that index see one change, not two.

### Cross-references

- Release plan: this file, top section
- Milestone: `external-seam-conduct-binds`
- User-facing release notes: authored at Stage 13 Close per the release-notes standard
