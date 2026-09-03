---
title: Release Plan — governance-declarations-match-enforcement (the charter declares only what the platform actually enforces)
type: release-plan
plan_type: release
status: ACTIVE
release: version-less (theme-named; no tag claimed)
milestone: 369-governance-declarations-match-enforcement
release_class: routine
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `governance-declarations-match-enforcement`

**Milestone:** `governance-declarations-match-enforcement` (#369) · hub sub-task #6748 = first Stage-4 plan · #6832 = Stage-4 **re-plan** (the approved plan of record) · #6800 = #5518 Stage 5 Solutioning source · #6801 = #1772 Stage 5 Solutioning source · #6803 = #5518 Engineering slice (this plan lands here as Engineering Commit 0) · #6804 = #1772 Engineering slice
**Version identity:** **version-less / theme-named** — the milestone title is slug-only, so the release carries no version key. **No tag is claimed at Stage 12**; the Engineering-Commit-0 version re-verify and the Stage-12 atomic version claim are **INAPPLICABLE** (there is no version slot to contend for). **No release-version stamp token is emitted anywhere in this plan** — deliberately, and the token is not written even in prose, because the stamp-manifest detector is a literal substring scan and a prose mention would register as a manifest this plan does not have. `claim-version.sh --verify-stamp` is not run. See § Operator Decisions § D-Version for the finding and its basis.
**Topology:** D-C SINGLE — one release branch (`release/governance-declarations-match-enforcement`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial. Stage 6 is write-serialized on one shared file: #5518's slice lands first, #1772's slice follows on this same branch, authored against post-#5518 text.
**Release class:** `routine` · Light engagement · Standard Stage-9 · 30-day outcome window.
**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-02, domain: governance }` — determined at Stage 4 Phase A1.5 on #6748 (Form X verbatim, § 5.7 exemption: the File Change Matrix is entirely internal `core/` artifacts, so the design depends on no external best-practice). Carried forward unchanged through the re-bundle — the re-plan narrowed the composition but did not change the matrix's domain. See § Deviation Log Δ1.

> **Provenance.** This file transcribes the approved **Stage-4 re-plan** posted on hub sub-task **#6832** (operator-approved 2026-09-02, decision **D-13**), reconciled to the approved **Stage-5 Solutioning** designs posted on #6800 (#5518) and #6801 (#1772). Where the re-plan superseded a first-Stage-4 (#6748) determination, the transcribed section carries the re-plan's value and the **§ Deviation Log** records the delta. Authored at Engineering Commit 0 by the first Engineering spoke (#6803).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (theme-named; no tag, no stamp manifest) |
| **Date Created** | 2026-09-02 (Wednesday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/governance-declarations-match-enforcement` |
| **Baseline pin** | `origin/main` @ `77947f74e2375530660fe9dbe42b70bd62b35dc6` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `governance-declarations-match-enforcement` (#369) |

---

## Scope

### Summary

Two doc-only cards, one file, no live dependency edge. Both carry implementation-ready Stage-5 specs. Every gate passes or correctly skips; both headline defects **still reproduce on current main**, verified with control arms. The single planning judgment is sequencing on the shared file, and it is already settled: **#5518 then #1772, two commits on one branch, do not merge the cards.**

The release's capability outcome: **the charter declares only what the platform actually enforces.** Two statements in `core/CLAUDE.md.template` currently outrun their enforcement surface — an unqualified session-end mandate that instructs a cross-domain write the agent is prohibited from performing, and a Bridge Files table whose membership rule is unstated. Each is corrected in place, on the ADR-122 composition-surface SSOT.

### Members

| # | Issue | Size | Pts | Surface | Slice |
|---|-------|------|-----|---------|-------|
| 1 | **#5518** CLAUDE.md mandates a session-end SESSION_STATE.md write that the layer model forbids | S | 2 | `core/CLAUDE.md.template` § Session Management | Engineering spoke 1 (#6803 — this slice) |
| 2 | **#1772** Bridge Files (Layer 3) table states no membership rule | XS | 1 | `core/CLAUDE.md.template` § Bridge Files (Layer 3) | Engineering spoke 2 (#6804) |

Raw Σ = 3 pts × `routine` 1.0 = **3 effective**. **No merge, no split** — merging collapses #1772's **AC5**, the only mechanical carrier of the Outcome Statement amendment obligation.

### Capability Outcome Statement

**BEFORE:** the charter carried declarations that its own enforcement surfaces did not implement — a session-end mandate stated unconditionally for every session including the ones structurally unable to perform it, and a Layer-3 bridge table whose membership rule a reader had to infer.
**AFTER:** each declaration states the agent it binds, the posture-independent rule it rests on, and the posture-dependent severity at which the platform enforces it — so a reader on a default install can tell what is required from what is merely unblocked.

---

## Change Description

### Outcome

The platform's charter told every session to update two operations-domain files at session end. A platform-engineering session cannot correctly perform either write: the files are Layer 2, Cowork-owned, and the agent is prohibited from writing them by a live `status: ACTIVE` rule. The charter said otherwise, without qualification, on a single sentence carrying **two** such mandates.

The fix is not to relax the rule, and it is not to recite the hook's mode table as though the hook were the source of permission. It is to separate two axes the card conflated. **The rule** — may the engineering agent perform the write? — is posture-independent and owned by `core/rules/operations-bridge.md`; the answer is no, under every posture. **The enforcement severity** — what does the platform *do* about it? — is posture-dependent, gated by `BLOCK-AUTONOMY-004`, and sits below a master-activation gate that ships **off**, so on a fresh install the hook contributes nothing at all: not a block, not a warn, not a log row.

That yields the sentence the whole release turns on: **the absence of a block is not permission.** Writing the three-mode table alone, without the master-activation precondition, would itself have shipped a false charter declaration — the exact defect class this milestone exists to eliminate, reintroduced at the surface being repaired.

The second card states the Bridge Files table's membership rule, so the table stops reading as an exhaustive inventory of Layer-3 files when it is a scoped list.

### Issues resolved

| Issue | What landed |
|---|---|
| **#5518** | Two hunks on `core/CLAUDE.md.template` § Session Management: the `**Session end:**` line scoped to an operations-rooted session (**both** mandates — `SESSION_STATE.md` *and* `CORRECTIONS.md`), and a new paragraph stating the rule/enforcement split, the `-004` mode table, the `MASTER_ENABLE_CLASS="workflow"` master-activation precondition, the `enforce`-posture stage-and-hand-off obligation, and the Layer/Bridge re-read. Marked as closed at Stage 13. |
| **#1772** | Not yet built — its slice lands on this same branch and PR in the next Engineering spoke (#6804), authored against post-#5518 text. Marked as closed at Stage 13 alongside its sibling. |

### Key decisions

- **Rule and enforcement severity are two axes, stated explicitly** (operator decision **D-8**). AC4's "posture-dependent" attaches to *enforcement severity*, not to *ownership*: asserting ownership as posture-dependent would contradict `core/rules/operations-bridge.md`. Both are stated in the delivered text so the Stage-8 verdict is not left to grader interpretation.
- **No ADR.** `ADR-149` (`status: Accepted`, 2026-08-24) already records the directional split, the mode-gating, the placement below the master gate, and the master-OFF audit-trail consequence. This card **consumes** that decision at a lagging surface and renders no new structural decision; authoring an ADR would be ceremony per `decision-discipline.md` G2. See § Operator Decisions § D-ADR.
- **Scope correction inside the repaired sentence.** The `**Session end:**` line carries two unqualified cross-domain mandates, not one. Qualifying only `SESSION_STATE.md` would ship a half-fix on the very sentence being repaired.
- **No hook change, no generated-file edit.** `core/CLAUDE.md.template` is the ADR-122 composition-surface SSOT; a direct edit to the generated workspace-root `CLAUDE.md` is overwritten at update time.

### Reversibility

**CHEAP** · confidence **HIGH**. Doc-only, single file, no migration, no state change, no schema or interface change. Rollback is a single revert of the release-branch merge.

### Downstream impact

**Behavioral (2–5 live consumers)** per `blast-radius-protocol.md` § 5 — not Structural. `core/disciplines/memory-architecture.md` cites § Session Management for read order only and owns the writer fact this change **cites rather than restates**, so no reciprocal edit is owed and no shadow SSOT is created. `core/specs/operational-artifact-inventory.md`, `operations/CLAUDE.md.template`, `core/disciplines/context-lifecycle-model.md`, and `core/disciplines/execution-framework.md` carry structural citations with no content dependency. Exactly one consumer needs a follow-on — `core/governance/OPERATIONS.md` § Daily Processing Cycle step 17 — and it is out of scope per #5518 AC5 and routed forward (§ Findings routed forward).

### Cross-references

- [`core/rules/operations-bridge.md`](/core/rules/operations-bridge.md) — § Rules for Claude Code rules 1–2, the posture-independent prohibition.
- [`core/specs/autonomy-tiers.md`](/core/specs/autonomy-tiers.md) — § Irreducible Human Tasks item 7a, the canonical phrasing shape this edit adopts.
- [`core/disciplines/memory-architecture.md`](/core/disciplines/memory-architecture.md) — rows 41–42, the writer SSOT for `CORRECTIONS.md` and `SESSION_STATE.md`.
- [`core/ADRs/ADR-149-cross-domain-bridge-writes-are-not-symmetric.md`](/core/ADRs/ADR-149-cross-domain-bridge-writes-are-not-symmetric.md) — the decision this card completes the declared cascade of.

---

## Dependency Graph

```
#5518 ──▶ (none)
#1772 ──file contention (shared surface, not a dependency)──▶ #5518
```

**No cross-issue dependency edge exists.** The order is imposed by **file contention**, not dependency. #5518 is the upstream of the one directional relationship that does exist: #1772's **AC2** requires its new scope sentence to point the reader to § Session Management, and that pointer must resolve to a section that actually states the session-surface write rule — which is #5518's Hunk B. So #1772's spoke authors its pointer against post-#5518 text.

**Cross-release:** none. The 24-commit divergence window between the first plan's pin and this one does **not** touch `core/CLAUDE.md.template` (subject 0 / sensitivity 7 — valid probe). PR #6638 merged into base; PR #6621 no longer intersects this file set after #5827's re-home.

---

## Implementation Sequence

1. **Engineering Commit 0** — this plan file, `release/releases/plans/governance-declarations-match-enforcement_RELEASE_PLAN.md`.
2. **#5518** — session-end mandate qualification, `core/CLAUDE.md.template` § Session Management (`~:307` at the pin). Standalone commit touching only the template.
3. **#1772** — Bridge Files scope sentence, `core/CLAUDE.md.template` § Bridge Files (Layer 3) (`~:154` at the pin). Second commit on the same branch.

**#5518 first** because #1772's AC2 pointer into § Session Management must be authored against post-#5518 text. Each card commits separately so each diff is independently gradable at Stage 8.

---

## Stage Applicability Matrix

**Verdict: stages 5–9 and 12–13 apply to both members. Stages 10 and 11 are PLATFORM-SATISFIED** (`stage-10-dry-run.md` § Classification; `stage-11-snapshot.md` § 3 — "git history IS snapshot"), so they are structurally N/A, not skipped by judgment.

| Stage | #5518 | #1772 | Basis |
|---|---|---|---|
| **5 Solutioning** | **APPLIED** | **APPLIED** | Both ran to completion — specs on #6800 and #6801. The first plan's conditional `SKIP` verdicts (under `routine`'s `SKIP-where-trivial` bias) were superseded: #5518's SKIP was conditional on an AC1 [ADJUST] and Stage 5 ran instead, which is what surfaced the rule-vs-severity distinction. See § Deviation Log Δ2. |
| **6 Engineering** | APPLIES | APPLIES | Only writing stage. Write-serialized on the shared file — 1 spoke at a time. |
| **7 Dev Testing** | APPLIES | APPLIES | Doc-only ≠ no functional impact: **every AC on both cards is a runnable probe**, and #1772 AC3 ships a **control arm** that must actually be exercised. `core/CLAUDE.md.template` is also a composition surface generated into a live `CLAUDE.md` at update time (ADR-122). |
| **8 QA / Acceptance** | APPLIES (per-issue) | APPLIES (per-issue) | 4 ACs on #5518, 5 on #1772 — per-criterion verdicts. |
| **9 Plan Review** | \<release-scoped\> | \<release-scoped\> | Always. Depth **Standard** under `routine`. |
| **10 Dry Run** | N/A | N/A | PLATFORM-SATISFIED — the PR diff **is** the dry run. |
| **11 Snapshot** | N/A | N/A | PLATFORM-SATISFIED — git history **is** the snapshot. |
| **12 Execute** | \<release-scoped\> | \<release-scoped\> | Always. **No version claim** — version-less. |
| **13 Close** | \<release-scoped\> | \<release-scoped\> | Always. Mark #5518 and #1772 as closed at Stage 13. |

**Parallel-eligible spoke counts:** Stage 6 **1** (write-serialized) · Stage 7 **2** · Stage 8 **2**. Worst parallel batch = **n=2**.

---

## Contention Map

**In-bundle file contention: exactly one file, and it is resolved by sequencing.**

| File | #5518 | #1772 | Contention |
|------|-------|-------|------------|
| `core/CLAUDE.md.template` | § Session Management — `**Session end:**` line (`~:307`) + insert before `**Rotation focus (per project):**` | § Bridge Files (Layer 3) — insert above the table (`~:154`) | **`line-range-overlap = NO`** — `~:154` vs `~:307`, **≥149 lines** and one H2 boundary apart. Even at git's default 3-line context the hunks are disjoint by ~143 lines. **Sequence, do not split or merge.** |

**Do not merge the cards.** Merging collapses #1772's **AC5**, the only mechanical carrier of the Outcome Statement amendment obligation.

**#1772's AC3 probe is unaffected by #5518's hunks:** it ranges `awk '/^### Bridge Files/,/^### Classification/'` (lines 154–160 at the pin). Neither #5518 hunk enters that range.

---

## Cross-PR Overlap Audit

### Baseline SHA

`77947f74e2375530660fe9dbe42b70bd62b35dc6` — `origin/main` at Stage-4 re-plan audit start, re-verified at Engineering Commit 0 (`git fetch origin main`; `HEAD == origin/main`, `HEAD..origin/main` = **0** commits).

**The pin is recorded rather than assumed.** The prior pin `0b04639e` went stale during the planning session — main advanced **24 commits** mid-planning. That is exactly why this value is pinned and re-verified at each stage entry rather than carried on trust.

### In-Flight Release Roster

Roster n=5 at re-plan time; intersection with `core/CLAUDE.md.template` → **0**. Probe valid: the roster arm is non-empty (sensitivity), the intersection is empty (subject).

---

## Risk Register

| Risk | Owner | Mitigation | Reversibility |
|---|---|---|---|
| #1772's scope sentence reads as demoting the three session/account files | Stage 6 | **CIAC-1** grades the two hunks together at Stage 9 | CHEAP |
| Mid-pipeline divergence on the shared file | Stage 9 A6.5 | Baseline pinned at `77947f74`; re-check at Stage 9 entry — main moved 24 commits during planning alone | CHEAP |
| #1772 AC4 false-pass via cwd-relative pathspec | Stage 7 | `:(top)CLAUDE.md` mandated — git pathspecs are cwd-relative, so from `core/` the bare form resolves to a nonexistent path and returns empty, greening the AC even if a root `CLAUDE.md` were added. This harness resets Bash cwd between calls, which makes the false pass reachable in practice | CHEAP |
| Charter ships a claim that outruns enforcement | Stage 8 | **D-8** fixed the axis: rule posture-independent, severity posture-dependent. Both stated explicitly in the delivered text | MODERATE |

### Rollback strategy

Single revert of the release-branch merge. Doc-only, no migration, no state change, no deployed-copy divergence. **CHEAP** · confidence **HIGH**.

---

## Cross-Issue Acceptance Criteria

**CIAC-1** · spans **#5518 + #1772** · **Predicate:** after both land, `core/CLAUDE.md.template` contains no unqualified cross-domain write mandate **AND** the Bridge Files table's membership rule is stated — i.e. the two cards do not contradict each other on Layer-3 bridge semantics. #1772's scope sentence must not read as demoting `SESSION_STATE.md` / `CORRECTIONS.md`, which #5518's hunk simultaneously describes as agent-prohibited-but-operator-owned. · **Shared surface:** `core/CLAUDE.md.template`. · **Verification:** read both hunks together on the merged PR; graded at Stage 9 QC3.5 / Phase A3.6.

---

## File Change Matrix

Machine-readable path list — one path per line, `<VERB>  <path>`. Intent tokens: `add` (new file) · `edit` (modify).

```
# ── Engineering Commit 0 — the plan file ──
add   release/releases/plans/governance-declarations-match-enforcement_RELEASE_PLAN.md
# ── slice 1 — #5518 ──
edit  core/CLAUDE.md.template
# ── slice 2 — #1772 — same file, disjoint hunk ──
```

| Path | Intent | Issue | Note |
|------|--------|-------|------|
| `release/releases/plans/governance-declarations-match-enforcement_RELEASE_PLAN.md` | add | release | **Flat in `plans/`** — version-less releases are not version-keyed, so there is no `v<MAJOR>/` home and no Stage-12 `git mv`. Workspace-rooted links only. |
| `core/CLAUDE.md.template` | edit | #5518 | § Session Management, **two hunks**. (A) the `**Session end:**` line — scope **both** mandates (`SESSION_STATE.md` *and* `CORRECTIONS.md`) to an operations-rooted session. (B) a new bolded paragraph inserted after `**Corrections management:**` — the rule/enforcement split, the `-004` mode table, the master-activation precondition, the stage-and-hand-off obligation, the Layer/Bridge re-read. **Surgical:** no other section is reworded. |
| `core/CLAUDE.md.template` | edit | #1772 | § Bridge Files (Layer 3), insert above the table (`~:154`) — cross-domain-only membership sentence + pointer to § Session Management. **Second commit, disjoint hunk.** Same path as the row above; declared once in the fenced block. |

**No `add` rows for tracked executables**, so the new-executable companion obligation (script-execution allowlist row + CI wiring statement) does **not** fire.

#### Read-only inputs (NOT EDITED — excluded from the delivery obligation set)

| Path | Why read | Issue |
|------|----------|-------|
| `core/hooks/block-autonomy-ceiling.sh` | READ — the source of every posture claim the delivered text makes (`MASTER_ENABLE_CLASS`, the `-004` mode branches, the precedence chain). **No hook change** per #5518 AC5 | #5518 |
| `core/hooks/lib/master-enable.sh` | READ — the `workflow` class semantics and the shipped master-`off` default | #5518 |
| `core/rules/operations-bridge.md` | READ — rules 1–2, the posture-independent prohibition the text cites rather than restates | #5518 |
| `core/specs/autonomy-tiers.md` | READ — item 7a, the canonical phrasing shape adopted | #5518 |
| `core/disciplines/memory-architecture.md` | READ — rows 41–42 own the writer fact; **cited, never restated**, to avoid forking the SSOT | #5518 |
| Generated workspace-root `CLAUDE.md` | NOT EDITED — generated from the template per ADR-122; a direct edit is overwritten at update time | both |
| `core/governance/OPERATIONS.md` | NOT EDITED — step 17's latent contradiction is real but out of scope per #5518 AC5; routed forward | #5518 |

---

## Verification Plan

### AC baseline

Per-issue acceptance-criterion counts as read at plan time, with the commit the read was taken against. The ordinal in the `AC` column is positional, so this baseline is what makes ordinal drift countable rather than silent. **The baseline is a pinned measurement and carries no verdict.**

| Issue | AC count at plan time | Read at |
|-------|----------------------|---------|
| #5518 | **5** | `77947f74e2375530660fe9dbe42b70bd62b35dc6` |
| #1772 | **5** | `77947f74e2375530660fe9dbe42b70bd62b35dc6` |

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|--------------------|-----------------|
| #5518 | AC-1 | `grep -c 'operations-rooted session' core/CLAUDE.md.template` · control arm, same instrument, same target: `grep -c 'Session end:'` → non-zero, so a zero on the subject is a real absence rather than an unreadable file | The mandate names the agent that performs the write, and the `-004` mode table is present verbatim — `warn` → allow + log · `enforce` → block · `off` → allow |
| #5518 | AC-2 | `grep -c 'MASTER_ENABLE_CLASS' core/CLAUDE.md.template` · control arm, same instrument, same target: `grep -c 'BLOCK-AUTONOMY-004'` → non-zero | The master-activation precondition is stated, not just the mode table: `MASTER_ENABLE_CLASS="workflow"`, *below the master-activation gate*, master `off` by shipped default, and the consequence — *not a block, not a warn, not a log row*. The load-bearing sentence **"the absence of a block is not permission"** is present |
| #5518 | AC-3 | `grep -c 'Hook-Blocked' core/CLAUDE.md.template` · control arm, same instrument, same target: `grep -c 'stages the intended update'` → non-zero | The `enforce`-posture obligation is explicit — the session stages the intended update and hands it off per the Hook-Blocked → User-Side Handoff convention, named as a **standing instance** rather than an ad-hoc firing |
| #5518 | AC-4 | `grep -c 'they state \*\*ownership\*\*' core/CLAUDE.md.template` · control arm, same instrument, same target: `grep -c 'enforcement severity'` → non-zero | The Layer/Bridge tension is resolved in text as posture-dependent **on the enforcement axis** and categorical on the ownership axis, stated explicitly so the verdict is not left to grader interpretation |
| #5518 | AC-5 | `git diff --name-only origin/main...HEAD` for the #5518 commit names only `core/CLAUDE.md.template` · control arm: the same invocation across the branch is non-empty | Edits confined to the ADR-122 SSOT surface. No hook change, no generated-file edit |
| #1772 | AC-1 | `grep -A4 'Bridge Files (Layer 3)' core/CLAUDE.md.template` shows the scope sentence | Control arm: confirm the referenced heading exists verbatim |
| #1772 | AC-2 | The scope sentence points the reader to § Session Management | Pointer resolves to post-#5518 text, which states the session-surface write rule |
| #1772 | AC-3 | `awk '/^### Bridge Files/,/^### Classification/' core/CLAUDE.md.template \| grep -c '^\|'` → **3** | Control arm: insert a second data row → **4**. Both arms fire, so the criterion is live rather than inert |
| #1772 | AC-4 | `git diff --name-only origin/main...HEAD -- ':(top)CLAUDE.md'` → empty | Control arm: the same invocation on `core/CLAUDE.md.template` → non-empty. **`:(top)` is mandatory** — git pathspecs are cwd-relative and the bare form false-passes from any subdirectory |
| #1772 | AC-5 | Outcome Statement no longer claims the table lists every bridge file | **Already satisfied** — amended at the first Stage-4 gate; verify only |

---

## Release-Scoped Verification

Held in its own H2, deliberately. The plan verifier extracts everything under `## Verification Plan` and parses every markdown table it finds there as per-issue check rows, so a second table with different columns living inside that section is read at the per-issue column indices and emits spurious records. Promoting this table out of the section is the authoring fix; the column names below are also deliberately distinct from the per-issue table's.

| # | Release-scoped check | Invocation | Result required |
|---|----------------------|-----------|-----------------|
| **V-1** | Plan conformance | `bash release/tools/verify-release-plan.sh release/releases/plans/governance-declarations-match-enforcement_RELEASE_PLAN.md` | Every family PASS or a named SKIP. The `release-version-stamp` element is **correctly absent** — it fires only when a version-stamp token is present, and a version-less plan emits none |
| **V-2** | Doc-link integrity | `core/deploy/deploy.sh --check` Check 14 over the modified `.md` files | Every internal markdown link in a modified file resolves. All intra-repo links in this plan use the **workspace-rooted** form, so they resolve both at `plans/` and one directory deeper |
| **V-3** | Hook-source fidelity | For every posture claim the delivered text makes, re-read the claim from `core/hooks/block-autonomy-ceiling.sh` and `core/hooks/lib/master-enable.sh` at the branch tip, with comment-prefix and line-wrap normalization | Each claim matches its source **verbatim in substance**. Normalization is required, not optional: the load-bearing phrase spans a wrapped comment line, so a line-anchored probe returns a false zero. Sensitivity + specificity arms on every count |
| **V-4** | No generated-file edit | `git diff --name-only origin/main...HEAD -- ':(top)CLAUDE.md'` → empty | Control arm: the same invocation on `core/CLAUDE.md.template` → non-empty. ADR-122 holds — the template is the only edited surface |
| **V-5** | No hook change | `git diff --name-only origin/main...HEAD -- 'core/hooks/'` → empty | Control arm: the same invocation on `core/` → non-empty. #5518 AC5 and #1772's scope both forbid a hook change |
| **V-6** | Parser-clean PR body | `grep -inE "(close\|closes\|closed\|fix\|fixes\|fixed\|resolve\|resolves\|resolved) +#?\[?[0-9]"` over the PR body | Zero matches outside the dedicated **Issue References** block. Control arm: the Issue References block itself matches, so a global zero would mean the probe is broken |

---

## Delivery Strategy

- **One branch, one PR, one merge** (D-C SINGLE). #1772's slice lands on this same branch and PR in the next Engineering spoke.
- **P0 fully-serial.** Stage 6 is write-serialized on the shared file; no force-push on the shared branch under multi-chip activity.
- **Sub-task container: PR-body checklist.** The decomposition is 2 file-level units (plan file + #5518's template edit) plus the 3 always-generated special units (sync / plan-update / verification) — clears the ≤5 threshold, doc-only, single logical unit. The checklist rows in the PR body **are** the decomposition record.
- **Commit messages reference their source issue.** Close-family verbs bound to an issue number appear only in the PR body's dedicated Issue References block — never in a commit message, a plan section, or a PR narrative section.
- **`deliverable_state`: `artifact-accepted`.** Both members are doc-class deliverables whose definition of done *is* the edited artifact at its declared canonical path. There is no Layer-2 propagation target: `core/CLAUDE.md.template` composes into the generated workspace-root `CLAUDE.md` at update time (ADR-122), which is not a release-branch sync step.

---

## Quota Budget

**Verdict:** **PASS** (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 6: **1** (write-serialized) · Stage 7: **2** · Stage 8: **2**
**Per-spoke cost estimate:** ordinal size-bucket band (no telemetry medians available; the cutover conditions are met for neither bucket, so every bucket keeps its band floor). #5518 `size:S` → **lowest**; #1772 `size:XS` → **lowest**.
**Assumed/stated remaining usage-window envelope:** **UNSTATED** by the operator at hub start → conservative default assumed.
**Estimated cumulative draw % (worst parallel batch):** worst batch = **n=2** lowest-band spokes, the smallest non-trivial parallel batch the protocol models. Well below the 50 % PASS boundary.
**Host-API quota at plan time:** `core 5000/5000`, `graphql 5000/5000`.
**Routing:** **PASS — proceed parallel; no warning required in plan.**
**Confidence:** `[CALIBRATE-AFTER-3]` **MEDIUM** — bands and cumulative-draw budget are provisional.
**Note:** the load-bearing gate remains **Procedure 2 Step 5.5 Checkpoint B at every launch** — wave or singleton — not this plan-time estimate. Checkpoint B also gates on the host-API quota pools, read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time.

---

## Operator Decisions (recorded)

### D-Version — RECORDED DETERMINATION (rule-determined; not an operator gate)

**Version-less / theme-named.** The milestone title is slug-only, so the release carries no version key and there is no version slot to contend for.

**The Commit-0 version re-verify is INAPPLICABLE, and that finding is stated rather than silently skipped.** The `hub-spoke-bridge.md` Procedure 0 § Canonical location re-verify has two halves and neither has a subject here:

- **Version half (steps 1–3, pre-write)** — its trigger is *"the planned version is taken."* No version is planned, so there is nothing to recompute next-free against and nothing that can be claimed by a concurrent release.
- **Manifest half (step 3b, post-write / pre-commit)** — `release/tools/claim-version.sh --verify-stamp <slug>` asserts that the plan carries a resolvable release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, not written literally here for the reason given above). A version-less plan **deliberately emits no such token**, so the verb would report `TOKEN-LESS PLAN` and exit 1. That non-zero would be a *correct reading of a plan that is correct as authored* — the HALT text's remedy ("restore the token in the Header **Version** cell") is exactly what this release must not do, because there is no version for the token to resolve to and no `plans/v<MAJOR>/` rename at Stage 12 for it to feed.

**Running the assertion anyway would manufacture a false HALT and invite a false fix.** The verb is therefore not run, on the same basis as the shipped precedent at [`declarations-have-a-firing-surface_RELEASE_PLAN.md`](/release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md), which records the identical determination for the identical reason. The plan-conformance check that *does* apply is **V-1**, whose `release-version-stamp` element is correctly absent.

### D-ReleaseClass — SETTLED: `routine`

Re-derived at the Stage-3 re-composition (**D-11**) after the re-bundle. Light engagement · Standard Stage-9 review depth · 30-day outcome window. The first Stage-4 (#6748) planned a three-card composition under which the class was briefly re-classified `novel`; the re-bundle to `{#5518, #1772}` returned it to `routine`. See § Deviation Log Δ2.

### D-C Branch Topology — **SINGLE**

One release branch, one PR, one merge. This plan lands as Engineering Commit 0.

### D-Concurrency Posture — **P0 fully-serial**

Stage 6 is write-serialized: both cards edit the same file, so chips route one at a time in the Implementation Sequence order and the next chip waits until the prior commit lands.

### D-7 / D-10 — Re-bundle and re-composition

At the Stage-5 Collective Review the operator elected **re-bundle** (**D-7**), whose stated price is re-running Stage 4. The Stage-3 re-composition (#6820) committed **{#5518 KEEP, #1772 KEEP, #5827 RE-HOME}** (**D-10**).

### D-8 — Rule vs enforcement severity: **TWO AXES, BOTH STATED**

The **rule** (may the engineering agent perform the write?) is posture-independent and owned by `core/rules/operations-bridge.md` rules 1–2 — *"Both remain prohibited to the agent; only the enforcement severity differs."* The **enforcement severity** (what the platform does about it) is posture-dependent, gated by `BLOCK-AUTONOMY-004` below the master-activation gate. #5518 AC4's "posture-dependent" attaches to the **enforcement** axis; asserting *ownership* as posture-dependent would contradict a live `status: ACTIVE` rule.

### D-ADR — **NO ADR**

`ADR-149` already records the directional split and its consequences. This card consumes that decision at a lagging surface and renders no new structural decision. Authoring one would be ceremony per `decision-discipline.md` G2.

### D-13 — Plan approval / scope lock

Plan **APPROVED** by the operator 2026-09-02. Composition re-locked on `{#5518, #1772}`; baseline pinned at `origin/main` = `77947f74`.

---

## Non-coverage — what this release does NOT deliver

1. **It does not make `SESSION_STATE.md` fresher.** Qualifying the mandate names the correct writer; it does not perform the write. The freshness gap is now explicitly an **operator step every release**, exactly as the card's option (a) predicted. Options (b) a Stage-13 staged-handoff output and (c) splitting the file remain the durable answers and remain **out of scope** per the 2026-09-02 re-scope. Recorded here so Stage 13's outcome window measures the right thing rather than crediting this release with a staleness fix it did not ship.
2. **It does not change any hook.** `BLOCK-AUTONOMY-004`, `BLOCK-AUTONOMY-002`, the master-activation gate, and the workspace-scope gate are read-only inputs. The release changes what the charter *declares*, never what the platform *enforces*.
3. **It does not edit the generated workspace-root `CLAUDE.md`.** That file is composed from the template at update time (ADR-122); a direct edit is overwritten.
4. **It does not resolve `OPERATIONS.md` step 17.** A second unqualified session-end mandate lives there, and the Context File Hierarchy makes OPERATIONS.md (Tier 2) *more specific* than CLAUDE.md (Tier 1), so on a shared claim it would override the qualification this release ships. Editing it violates #5518 AC5. Routed forward below.
5. **The `enforce`-posture handoff path is declared but unexercised.** It cannot be observed on a default install (master `off` ⇒ `-004` inert), so no Stage-7 test can exercise it end-to-end without an operator enabling the hook suite **and** flipping `.autonomy-mode` to `enforce`. Dev Testing grades the paragraph as a **documentary** assertion — text present, claims match the hook source — **not** as a behavioural one. Confidence **MEDIUM** that the handoff text is operationally right; **HIGH** that it is the correct thing to declare.

---

## Findings routed forward (not fixed in this release)

| # | Finding | Why not here | Routing |
|---|---|---|---|
| **F-1** | `core/governance/OPERATIONS.md` § Daily Processing Cycle step 17 carries a second unqualified cross-domain session-end mandate, and its trigger clause (*"any session that modified governance files"*) names an act characteristic of platform-engineering sessions. Latent rather than active — its containing protocol is an operations-domain cycle — but OPERATIONS.md outranks CLAUDE.md on a shared claim | #5518 **AC5** confines edits to `core/CLAUDE.md.template` | Intake, proposal tier (`improvement.yml`), `project:governance-hygiene`. Squarely this milestone family's class |
| **F-2** | G-PL3's directory-crossing filter does not exclude the ADR-092 version claim it names as its own example — the claim moves `plans/` → `plans/v<MAJOR>/`, which crosses directories and is therefore not filtered. **Every versioned release trips G-PL3 this way** | Gate-internal defect, unrelated to either card's subject matter | Intake |
| **F-3** | `core/specs/operational-artifact-inventory.md` — the `SESSION_STATE.md` row carries `[ASSUMPTION – CONFIRM]` on `source_entity` / `reconciliation_flag`, flagged upstream as a candidate no-entity-home awaiting downstream triage | Pre-existing, tracked at its own home, unrelated to this card's scope | Accepted residual |
| **F-4** | `core/hooks/block-autonomy-ceiling.sh` — the scope-gate comment states of itself that it *"is directly above incomplete as written: scope no longer gates ONLY the STEP-2 ceiling."* Self-documented and self-corrected two lines later | No hook change in scope per AC5 | Accepted residual |

---

## Deviation Log

| # | Deviation | Basis | Disposition |
|---|---|---|---|
| **Δ1** | The Stage-4 **re-plan** comment (#6832) does not restate the `domain_practice` label. It was determined at the **first** Stage 4 (#6748, Phase A1.5) as `{ source: N/A — pipeline-internal release, date: 2026-09-02, domain: governance }` | Survival-Set row 1 must survive transcription; the re-bundle narrowed the composition but did not change the File Change Matrix's domain — it is still entirely internal `core/` artifacts, so the Form X § 5.7 exemption still holds verbatim | **Carried forward from #6748 with its basis recorded**, rather than re-derived or dropped |
| **Δ2** | The Stage Applicability Matrix transcribed above differs from #6748's in two ways: the `#5827` column is dropped, and the Stage-5 row reads **APPLIED** rather than the conditional **SKIP** #6748 recorded | #5827 was **re-homed** at the Stage-3 re-composition (**D-10**), so it is not a member. #5518's `SKIP` was explicitly conditional on an AC1 [ADJUST] landing first; Stage 5 ran for both cards instead and completed (#6800, #6801) — which is what surfaced the rule-vs-severity distinction the release now turns on | **Reconciled to what actually happened**, recorded here so the change is legible rather than a silent rewrite |
| **Δ3** | The Stage-5 spec on #6800 was authored and verified at base `0b04639e`. This plan and its implementation are pinned at `77947f74` — **24 commits later** | Audit-baseline discipline: a claim verified against a stale tree is unverified. Every load-bearing hook-source claim in #6800's spec was **re-read at `77947f74`** before implementation | **All claims re-confirmed at the current pin** with sensitivity + specificity arms. One apparent drift was a **broken probe on the verifier's side**, not real drift — see Δ4 |
| **Δ4** | A line-anchored probe for the hook's phrase *"not a block, not a warn, not a log row"* returned **0** at `77947f74`, contradicting #6800's `CONFIRMED verbatim` | The phrase spans a **wrapped comment line** (`block-autonomy-ceiling.sh:837–838`), each line carrying a `#` prefix. The single-line probe could not match it. Control arms fired (`BLOCK-AUTONOMY-004` → 8), which is what exposed the zero as suspect rather than authoritative | **Re-probed with comment-prefix and whitespace normalization → 1 occurrence.** The Stage-5 claim holds. Recorded because a zero whose control arm fires is still a broken probe if the pattern shape is wrong, and V-3 now mandates the normalization |
| **Δ5** | The Stage-5 scaffold on #6800 declares Release Class **`novel`** · Deep Stage-9 · Stage-5 bias ALL. This plan declares **`routine`** · Light · Standard | The `novel` value predates the re-bundle. The Stage-3 re-composition re-derived the class to `routine` (**D-11**) and the #6832 re-plan body carries that value | **`routine` is authoritative.** No behavioural consequence for Stage 6; it sets Stage-9 review depth |

---

## Verification Evidence

*(Populated at Stage-6 C4 self-verification and refreshed at Stage 7 / Stage 13. See § Verification Plan for the declared methods and § Release-Scoped Verification for V-1 … V-6.)*

### Close mechanism

Both members are marked as closed at **Stage 13** by the automated close-out procedure, on the single release-branch merge. No close-family verb bound to an issue number appears in any commit message or in any PR narrative section — only in the PR body's dedicated **Issue References** block.
