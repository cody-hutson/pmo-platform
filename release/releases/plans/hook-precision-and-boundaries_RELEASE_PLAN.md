---
title: Release Plan — hook-precision-and-boundaries (a stated, checkable boundary between corpus and public surface, with hooks that fire precisely and spokes that respond to them honestly)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: hook-precision-and-boundaries
release_class: novel
domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-07, domain: software }
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `hook-precision-and-boundaries`

**Milestone:** `hook-precision-and-boundaries` (milestone 310). Three members, sliced into five ordered work-units, on one branch, one pull request, one merge.
**Version identity:** **slug-only** per **ADR-092**. This file is `hook-precision-and-boundaries_RELEASE_PLAN.md` and the branch is `release/hook-precision-and-boundaries`; no version stem appears in the filename, in the branch name, or in this plan's identity prose. Bump class is `minor`. The concrete number binds at the **Stage-12 atomic compare-and-swap**, which renames this file into its major-version bucket and resolves the `{{RELEASE_VERSION}}` token carried below.
**Topology:** **SINGLE** — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial.** Stage-6 work routes one work-unit at a time in the approved sequence on the shared branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`novel`** (operator verdict at the Stage-4 gate, overriding the milestone's `routine` claim). Posture: engagement density **Standard** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output, reconciled forward through the Stage-5 Solutioning designs, the independent adversarial design review, the pre-Collective-Review blocking-findings decisions, the Collective Review scope-lock, the serialization hold and its discharge, and the Commit-0 version re-verify recorded below. Where a later measurement superseded a Stage-4 figure, **this file carries the decided state** and the Deviation Log records the delta. The Stage-4 and Stage-5 output comments are the historical record and are not edited. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` — slug-only pre-claim (ADR-092); bump class `minor` |
| **Date Created** | 2026-08-07 (Friday) — Stage-4 planning |
| **Commit 0 authored** | 2026-08-08 (Saturday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Baseline** | Stage-4 planning measured at a pre-serialization mainline head; **Stage 6 builds on the post-serialization-discharge mainline** — see the Deviation Log |
| **Topology** | SINGLE — one branch, one pull request, one merge |
| **Rollback** | Revert the release merge commit; two carve-outs recorded under Rollback |

### Commit-0 version re-verify

The Stage-4 version determination is **provisional** until the Stage-12 atomic claim. This rung is load-bearing on this release specifically: the slot has now been claimed out from under this release **four separate times** by concurrent siblings, and the fourth claim was taken by the very merge this release was serialized behind. A prior Stage-6 spoke reached this step, found the then-planned slot claimed, and **HALTed** rather than self-authorizing a re-version — the mandated behaviour, and the reason this run exists.

Re-run at this Commit 0 against the current mainline head, with a controlled probe on every arm:

| Arm | Probe | Result |
|---|---|---|
| **Target** | the recomputed next-free version present on the origin tag surface? | **0 occurrences** — not claimed |
| **Sensitivity control** (known PRESENT) | the immediately preceding version on the same surface | **1 occurrence** — the probe detects a real claim, so the target's zero is discriminating |
| **Specificity control** (known ABSENT) | two versions beyond the recomputed next-free, never allocated | **0 occurrences** — a zero is reachable, not a regex artifact |
| **Independent recomputation** | the version adapter's own next-free computation for a `minor` bump, dry-run against the current mainline head | recomputed next-free **equals** the target, exit 0, no tag pushed |
| **Ledger cross-read** | the release ledger read from the mainline rather than any worktree copy | the ledger's highest row and the tag surface's highest tag **agree**; one intermediate slot carries a tag with no mainline ledger row, which is a sibling's in-flight close-out and is already accounted for by the adapter's in-flight-row input |

**Verdict: PROCEED.** The recomputed next-free is absent from the claimed set on the authoritative surface and equals the adapter's independent computation. The value observed at this Commit 0 was **`v4.19`**, measured at **`2026-08-08T04:32:17Z`** against mainline head `54f75d2c`. **That value is a measurement, not a binding.** It is recorded so the re-verify is reproducible, not so anything downstream may cite it: the branch, this file, the pull-request title, and every commit message on this branch stay slug-primary and rename on no re-derivation. Freeness re-verifies once more at the Stage-12 pre-merge check, and **the Stage-12 atomic claim is the only rung that binds a version to this release.**

**Carried forward as a release learning.** Four consecutive re-anchors on one release is not a version-computation defect — every determination was correct at its measurement instant and was invalidated by concurrent contention. It is evidence that a plan-time version literal has negative value under contention, and that the slug-primary-until-Stage-12 model is the mitigation working as designed rather than an inconvenience to be routed around by pinning the number earlier.

---

## Change Description

*Operator-facing. Authored at Stage 6 Phase C1 as required before the pull request is marked ready for review. This Commit-0 revision covers the plan and the first work-unit; later Engineering slices refresh it against the branch's own change set and commit log — not against a summary of either.*

### Outcome

The platform states, once and checkably, where the boundary between its own corpus and a public surface falls; makes the hook that guards that boundary fire precisely rather than over-broadly; and tells a spoke what it owes a control that fires on its work.

Three failures motivate it, and they compose. A guard that hard-blocks on a condition unrelated to the thing it guards trains everyone to route around it. A brief that names an absolute home path in a public-bound artifact leaks the operator's identity through a surface nobody reviews. And a spoke that meets a firing control with no stated legitimate move will invent one — which is precisely what happened: a spoke obfuscated a token to get past a security reminder, and no rule in the corpus said not to.

### Issues resolved

| Work-unit | Card | What lands |
|---|---|---|
| 1 | Corpus-to-public-surface boundary | The boundary clause in the depersonalization spec and the analysis-workspace standard — what may be quoted from the corpus into a public surface, and what may not |
| 2 | Spoke hook-response discipline | The two-move rule — reword or surface, never obfuscate to evade — as a rendered clause in the spoke-prompt template plus a named guard in the hub's launch policy |
| 3 | Spoke-brief path convention | The path-form convention the orchestrator injects into a rendered brief, authored as a delta on the run-directory section that landed one release ahead |
| 4 | Mode-couple the dependency-missing guard | Nine mode-bearing hooks stop hard-blocking on a missing library when the operator has the hook in warn or off; four always-enforce hooks are deliberately untouched; a superseding architecture decision record states the posture shift and the retained invariant |
| 5 | Per-rule mode surface for the path-leak rule | The dedicated mode file that makes a *scoped* posture change possible at all, shipped at **`warn`** — the mechanism, not the final posture |

### Key decisions

Recorded in the Deviation Log. The three that change what ships: the path-leak rule gets its own mode file rather than a shared-cohort flip; it ships at `warn` rather than `enforce`, with the flip deferred until the re-home produces real log data; and the mode snapshot is taken into a read-only value above the dependency guard, because the guard sources an untrusted library inside its own condition and a hostile library could otherwise redefine the mode reader.

### Reversibility

**MODERATE / Confidence HIGH.** Revert the release merge commit. Two carve-outs keep this above CHEAP — see Rollback.

### Downstream impact

Every spoke prompt this platform renders gains one discipline block and one mandatory output line. Nine security hooks change their behaviour on one failure path — in the permissive direction, only for operators who have explicitly set warn or off, and never for the always-enforce floor. One new mode file ships as a template.

### Cross-references

See the References block at the foot of this file.

---

## Scope

### Summary

Three members. One states a boundary; one makes a guard precise; one tells a spoke how to behave when a guard fires. The first is sliced into three work-units with genuinely different dependency profiles, which is why the milestone's own three-card sequence is re-expressed below as five ordered units.

### Members

| Card | Size | What it is |
|---|---|---|
| Corpus-to-public-surface boundary + path convention + enforce-promotion | S | Sliced s1/s2/s3. State the boundary; codify the path form the orchestrator injects into a brief; deliver the per-rule mode surface for the path-leak guard |
| Spoke hook-response discipline | S | Reword or surface, never obfuscate a token to evade a firing control. Doc-only diff, behavioral acceptance criterion |
| Mode-couple the dependency-missing guard | M | The `LIB-MISSING` guard becomes mode-coupled across the nine mode-bearing hooks; a superseding architecture decision record supersedes the prior fail-closed determination |

### Scope lock

**HELD** at Collective Review. Three cards, unchanged; slices and sequence unchanged. Four within-card decisions were rendered at that gate and change no milestone membership. Stage 5 ran three parallel adversarial design reviews after the design set was fixed; their findings are carried in the Deviation Log rather than reopening scope.

---

## Dependency Graph

Directed, hard edges only.

```
                    s1  state the boundary
              (corpus -> public-surface clause)
                              |
              +---------------+---------------+
              |                               |
             s2                          hook-response
    spoke-brief path convention           discipline
              |                               |
              +-------> [contention] <--------+
                              |
                     mode-couple the
                  dependency-missing guard
                              |
                              v
                             s3
              per-rule mode surface for the
                     path-leak rule
```

**Directional edges (2 cross-issue, evidence-grounded):**

- **E1 · hook-response discipline → s3 (requires).** s3 delivers the mechanism by which a control's posture can be tightened at all. The hook-response discipline codifies what a spoke does when a control fires. Delivering the tightening mechanism before the sanctioned response exists recreates the exact condition the discipline card was filed about — a spoke with no legitimate move choosing circumvention. Order is a safety property, not a convenience.
- **E2 · dependency-guard mode-coupling → s3 (requires).** Both act on the path-leak hook. Today a broken or stale library hard-blocks every Bash and Write in both enforce and warn, with no mode or bypass escape. Adding a posture surface on top of an un-mode-coupled dependency guard layers a deliberate posture change onto an acknowledged over-block. Mode-coupling first makes the posture change a clean, well-understood decision.
- **E3 · intra-card s1 → {s2, s3}.** The boundary must be stated before the brief convention and the gate posture can cite it.

**Non-edges (explicitly tested, not assumed):**

- **s2 ↔ hook-response discipline is contention, not dependency.** Both add a heading-level guard section to the same short launch-policy file; neither's content depends on the other's. Either could be authored first — but they must not be authored concurrently.
- **hook-response discipline ↔ dependency-guard mode-coupling share no file.** Their coupling is a design constraint, captured as CIAC-3, not a build-order edge.

**Circularity:** none. Two cross-issue edges over three nodes, verified acyclic by inspection — the discipline card and the mode-coupling card are both sources; s3 is the single sink.

---

## Implementation Sequence

Single release branch, single pull request, single merge. Five ordered work-units:

| # | Work-unit | Card | Rationale |
|---|---|---|---|
| **1** | Corpus-to-public-surface clause — depersonalization spec + analysis-workspace standard | s1 | Foundational; both downstream units cite it |
| **2** | Hook-response discipline — canonical clause in the spoke-prompt template, named guard in the launch-policy file, pointer in the planning template | hook-response | Must precede the posture-surface unit (E1). Doc-only, CHEAP |
| **3** | Spoke-brief path convention — second guard in the launch-policy file; reconcile the standing-guard ordinal exactly once | s2 | Immediately follows unit 2 so both guards land in one coherent pass on a short file, and the ordinal sentence is corrected once, not twice |
| **4** | Mode-couple the dependency-missing guard across the nine mode-bearing hooks; superseding architecture decision record; sweep the hook-dependency-hardening check and the affected test files | mode-coupling | Largest unit; must precede the posture-surface unit (E2) |
| **5** | Per-rule mode surface for the path-leak rule, shipped at `warn`; governance record in the bypass-mode readiness rule; reconcile the stale shared-mode cohort list | s3 | Sink of both edges |

**No card is split into separate issues.** The three slices of the boundary card are one coherent outcome; splitting would create governance churn and a second pull request against the milestone-equals-one-pull-request convention.

**No cards are merged.** The hook-response discipline and the path convention both edit the same launch-policy file but state genuinely different rules — behavioral response to a firing control versus path form in an emitted brief. Merging them would blur two distinct guards into one.

---

## Stage Applicability Matrix

| Card | 5 Solutioning | 6 Eng | 7 DevTest | 8 QA | 9 Review | 10 Dry-Run | 11 Snapshot | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|---|
| Boundary + path convention + posture surface | APPLY | APPLY | APPLY | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY |
| Hook-response discipline | APPLY | APPLY | **APPLY (light)** | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY |
| Dependency-guard mode-coupling | APPLY | APPLY | APPLY | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY |

**No stage is skipped for any card.** Release class `novel` carries activation bias ALL. Dev testing applies at different weight: the two hook cards are executable-code changes to security controls and take the full ladder; the discipline card is doc-only in its diff, but its second acceptance criterion is behavioral — a rendered spoke prompt must carry the clause — which requires observation, not inspection. Marked **light** rather than skipped: "doc-only" describes the diff, not the acceptance criterion.

Parallel-eligible stages are 5 / 7 / 8. Stages 6 / 12 / 13 are write-serialized by design.

---

## Contention Map

### Within-release

| File | s1 | s2 | discipline | s3 | mode-coupling | `overlap_class` | Severity |
|---|---|---|---|---|---|---|---|
| The hub's spoke-launch policy reference | — | yes | yes | — | — | append-pattern (two new guard sections) **+ one shared line** (the standing-guard ordinal sentence) | **HIGH** |
| The path-leak hook | — | — | — | yes | yes | line-range-overlap — both edit the guard/mode region | **HIGH** |
| The bypass-mode readiness rule | — | — | — | yes | yes | line-range-overlap — both edit the warn-versus-enforce block | **HIGH** |
| The depersonalization spec | yes | — | — | — | — | single-pr | none |
| The analysis-workspace standard | yes | — | — | — | — | single-pr | none |
| The hub-and-spoke bridge reference | — | yes | yes | — | — | append-pattern, distinct sections | LOW |
| The eight other mode-bearing hooks + their tests | — | — | — | — | yes | single-pr | none |
| New architecture decision record | — | — | — | — | yes | single-pr (add) | none |

Three files are contended by two work-units each. This is not an independent-changes release, and it is the primary input to the SINGLE topology.

### Cross-release

**The Tier-S serialization edge is DISCHARGED.** The open draft pull request that edited essentially this release's entire change matrix — all thirteen dependency-guarded hooks, both bypass-mode readiness files, the launch-policy reference, the bridge reference, and the hook test harness — **merged to `main` as `303de6e0`**. The Stage-4 R1 hold is satisfied and Stage 6 proceeds on the post-merge mainline. Every design anchor in this release was re-read against the merged state at Commit 0 rather than carried from the pre-merge design baseline.

The Parallelization Map is amended accordingly: the standing "Hard-blocked by: none" claim was **false** at Stage-4 entry and is now **true again by discharge rather than by having always been true**. Recorded so a future reader does not conclude the map was accurate all along.

---

## Risk Register

| ID | Risk | Sev | Owner | Mitigation | Reversibility |
|---|---|---|---|---|---|
| **R1** | **Cross-PR collision with the concurrent execution-safety release.** | ~~CRITICAL~~ **DISCHARGED** | Operator | Serialized; the upstream merged first and this release re-baselines onto it. Every anchor re-verified at Commit 0 against the merged state | — |
| **R2** | **Version contention.** The provisional slot has been claimed by a concurrent sibling four times | **HIGH** | Operator | Slug-primary in flight; nothing this release authors carries a version literal. Re-verify at Commit 0 (done) and atomic claim at Stage 12 | CHEAP |
| **R3** | **The posture flip has no per-rule mechanism without new code.** The shared mode file covers eight hooks and is git-ignored | **HIGH** | Operator (decided) | Decided: dedicated per-rule mode file, following the established three-hook precedent. Not a cohort flip | MODERATE |
| **R4** | **The mode-coupling card changes a security control's fail-closed posture.** A defect degrades the perimeter — the direction two prior advisories closed | **MODERATE** | Engineering | The enforce arm must still exit non-zero — assert it explicitly per hook. Sweep the hardening check plus the affected test files. The new decision record states the posture shift and the retained invariant. Do not disturb the master-enable fail-open gate or its position | MODERATE |
| **R5** | **Triple contention on a short file.** The launch-policy reference takes two new guard sections from two different work-units and carries a single shared ordinal line | **MODERATE** | Engineering | Sequence work-units 2 and 3 adjacently and never concurrently; fix the ordinal exactly once, in unit 3. SINGLE topology makes this structurally safe within the release | CHEAP |
| **R6** | **The mode-coupling sweep would over-apply.** Treating the guarded population as homogeneous injects a meaningless mode read into four always-enforce security-floor hooks | **LOW-MOD** | Engineering | Scope to the nine mode-bearing hooks; record the four as intentionally unchanged in the decision record | CHEAP |
| **R7** | **In-flight decision-record number collisions.** Sibling branches claim numbers already taken on the mainline, and the number checker reads the worktree and passes on a taken number | **LOW** | Engineering | Allocate from the mainline tree listing, never from the checker. Reconcile at Stage 12 | CHEAP |
| **R8** | **The posture surface ships at `warn` with the hook wiring un-re-homed, so the observable set is empty and the flip trigger cannot fire.** A warn-mode control nobody's session loads produces zero log lines that look identical to zero violations | **MODERATE** | Operator | Repaired: the re-home step is a **tracked post-deploy operator action with a verification**, not a deferral. See the Deviation Log | CHEAP |

**Rollback strategy.** Single release branch, single two-parent merge commit — reverting the merge restores the entire corpus and hook surface atomically. Reverting the hook changes restores the unconditional fail-closed dependency posture, which is the safe direction, so a rollback carries no security regression. Reverting the new decision record leaves the prior determination as the governing record, which is coherent.

**Two rollback gaps, stated rather than glossed:**

1. **The mode value is not revertible by git.** The per-rule mode file's operative value lives in a git-ignored operator-local file; the tracked artifact is its template. A revert restores the template, not the operator's setting. Record the pre-change value in the Stage-11 snapshot so the restore target is known. **MODERATE**, not CHEAP.
2. **Published issue and pull-request content is not revertible at all.** Editing a public issue does not scrub its edit history. Anything this release's spokes post is permanent. **IRREVERSIBLE** — which is precisely why the boundary work-unit leads the sequence rather than trailing it.

---

## Cross-Issue Acceptance Criteria

Three cohesion constraints span two or more cards. Graded at Stage 9 QC3.5 / Phase A3.6 on the merged pull request.

- [ ] **CIAC-1 (hook-response discipline × path convention, on the hub's spoke-launch policy reference).** After both guards land, the file carries the hook-response discipline and the spoke-brief path convention as **two distinct heading-level guard sections**, and the standing-guard enumeration is internally consistent.
  *Method — stated relatively, not as an absolute count.* Limb 1: `grep -c '^## '` on the launch-policy reference **increases by exactly 2 from this release branch's merge-base with `main`**, and both new headings resolve.
  Limb 2: the pre-spawn-guard enumeration in that file **is consistent with the number of such guards present** — the ordinal sentence names the correct position for the guard it describes, and neither new section is a pre-spawn guard, so the ordinal is reconciled by verification rather than by increment.
  *Why relative and why limb 2 is an internal-consistency assertion.* The Stage-4 form asserted an absolute count of 10 against a pre-merge baseline of 8. The upstream merge took the file to 9 before this release started, so the absolute figure fails on a correct build. A cross-issue criterion whose value depends on an unmerged upstream must be expressed relatively — the same failure class as embedding a pre-computed sum where derivation logic belonged. And the Stage-4 form's second limb demanded that no occurrence of the ordinal sentence survive; that is wrong. Deleting the sentence would make the enumeration *less* correct, not more. The sentence describes a genuine ordinal position that neither new section changes.
  *Graded at Stage 9 QC3.5 on the merged pull request.*

- [ ] **CIAC-2 (mode-coupling × posture surface, on the path-leak hook and the bypass-mode readiness rule).** The documented mode posture equals the implemented mode posture. The shared-mode cohort list in the readiness rule's warn-versus-enforce section **matches the set of hooks actually reading the shared mode file** — currently documented as four when the true cohort is eight — and the path-leak hook's post-change dependency guard and mode posture are described as implemented, at `warn`.
  *Method:* derive the cohort by grep and diff it against the hook names enumerated in that section; the two sets must be equal.
  *Graded at Stage 9 QC3.5 on the merged pull request.*

- [ ] **CIAC-3 (hook-response discipline × mode-coupling, on the warn/off degrade path).** The mode-coupled dependency-missing degrade path must emit a **surfaceable notice** on stderr in warn and off, rather than a silent success exit. The hook-response discipline gives a spoke exactly two moves when a control fires — reword, or surface to the hub — and a silent degrade leaves nothing to surface, making the sanctioned move unavailable by construction.
  *Method:* for each of the nine mode-bearing hooks, run the hook in warn with an unreadable dependency library; assert a zero exit **and** non-empty stderr carrying the hook's dependency-missing marker.
  *Declared here; verification runs on the Stage-7 dev-test ladder. Graded at Stage 9 QC3.5 on the merged pull request.*

---

## File Change Matrix

Machine-readable path list — one path per line, for deterministic extraction by downstream stage prompts. Derived from the Stage-4 change matrix, reconciled forward through each card's Stage-5 declarations and the Collective Review amendments.

```
core/standards/depersonalization-spec.md
core/standards/analysis-workspace-standard.md
core/standards/failure-mode-standard.md
release/references/how-to/hub-spoke-bridge.md
release/skills/release-hub/SKILL.md
release/skills/release-hub/references/spoke-launch.md
release/skills/release-hub/references/orchestration-playbook.md
packages/release-hub.skill
packages/release-hub.skill.sha256
core/rules/bypass-mode-readiness.md
core/rules/bypass-mode-readiness/_cross-cutting.md
core/rules/bypass-mode-readiness/_header.md
core/hooks/block-egress.sh
core/hooks/block-fragile-refs.sh
core/hooks/block-fs-boundary.sh
core/hooks/block-gh-path-leak.sh
core/hooks/block-mcp-writes.sh
core/hooks/block-shell-injection.sh
core/hooks/block-skill-direct-edit.sh
core/hooks/block-autonomy-ceiling.sh
core/hooks/block-scope-segregation.sh
core/hooks/tests/check-hook-dep-hardening.sh
core/hooks/tests/hook-fail-closed.test.sh
core/hooks/tests/block-egress.test.sh
core/hooks/tests/block-fs-boundary.test.sh
core/hooks/tests/block-gh-path-leak.test.sh
core/hooks/tests/block-mcp-writes.test.sh
core/hooks/tests/block-scope-segregation.test.sh
core/hooks/tests/block-skill-direct-edit.test.sh
core/hooks/tests/block-autonomy-ceiling.test.sh
core/hooks/tests/ghsa-g9g6-primitive-fail-closed.test.sh
core/ADRs/ADR-078-security-hook-dependency-resolution-posture.md
release/releases/plans/hook-precision-and-boundaries_RELEASE_PLAN.md
```

**Intent per path class.** `edit` for all listed paths except: the new mode-coupling decision record = **add** (allocate at authoring time — see the numbering note); this plan file = **add**; the prior dependency-posture decision record = **edit, status and supersession header only** (its body is the founding record and is not rewritten in place); `packages/release-hub.skill` and its checksum sidecar = **rebuild**.

**Six paths added at Commit 0 beyond the Stage-4 matrix** — the Stage-4 matrix listed only the launch-policy reference for the discipline card, and Stage-5 design plus the adversarial review established five more surfaces the card cannot ship without:

| Added path | Why it is required, not discretionary |
|---|---|
| The hub-and-spoke bridge reference | The spoke-prompt template lives here and is the render surface. A clause placed anywhere else does not reach a spoke prompt |
| The release-hub skill definition | It enumerates what the launch-policy reference covers; adding a guard leaves that enumeration a stale subset |
| The orchestration playbook reference | It enumerates the hub's prompt-construction disciplines; the new clause is one |
| `packages/release-hub.skill` | The launch-policy reference, the skill definition, and the playbook are all **inside** this archive. Package freshness is asserted by content, so editing them without a rebuild is a pre-merge gate failure |
| `packages/release-hub.skill.sha256` | The package's content baseline sidecar; regenerated with the package |
| The failure-mode standard | The design cites the standard's promotion rule as a reason to ship. The rule prescribes a catalog entry. Citing the rule and skipping the entry is the one option that is not defensible |

**Two paths deliberately absent.** The shared mode file is git-ignored and operator-local — it is not a tracked change. The workspace-global directives file lives outside this repository and is always-blocked to automated edits; the new clause **cites** its hook-blocked handoff template rather than editing it.

**No new executable script is added**, so the script-execution allowlist companion obligation is N/A. If work-unit 4 authors a new test script rather than extending the existing ones, that obligation activates and the allowlist row ships in the same pull request.

**Decision-record numbering.** Measured at Commit 0 from the mainline tree listing across both record directories: 128 records, highest **ADR-128**, contiguous; next-free on the mainline is therefore **ADR-129**. Sensitivity arm — a known-present record → 1. Specificity arm — a never-allocated number → 0. Allocate from the mainline tree listing at authoring time and **not** from the number checker, which reads the worktree and passes on a number already taken on the mainline.

---

## Verification Plan

Consumed by the plan-verification executor at Stage 6 Phase C4. A row whose work-unit has not yet landed declares its verification **deferred to that work-unit's own C4 self-verification** — an honest SKIP, never a fabricated pass and never a FAIL against unbuilt work. Rows are promoted from deferred to runnable by the spoke that lands their work-unit.

**Every row carries a non-empty `Issue` cell, and this is load-bearing rather than cosmetic.** The executor emits its parsed rows as tab-separated fields and reads them back with the field separator set to a tab. A tab is field-separator whitespace, so a leading **empty** issue cell is stripped on read and every remaining field shifts left by one — the executor then classifies on the *Expected* cell instead of the *Verification method* cell and dispatches the wrong family. A plan table without an issue column therefore verifies the wrong thing while reporting confidently. Surfaced as an out-of-scope observation; not fixed by this card.

| Issue | AC | Verification method | Expected result |
|---|---|---|---|
| s1 | Boundary clause present at both homes | Declared, verification deferred to work-unit 1 | The clause is present at both codified homes and states the quoting boundary; a sensitivity control must fail if the clause were deleted |
| hook-response | Canonical clause reaches the render surface | `grep -c '^## Hook-Response Discipline (all spokes)' release/references/how-to/hub-spoke-bridge.md` — expect 1 | The canonical clause resolves inside the Procedure 3 spoke-prompt template, which is the verbatim-render surface |
| hook-response | Named guard present | `grep -c '^## Hook-response guard' release/skills/release-hub/references/spoke-launch.md` — expect 1 | The named guard resolves in the hub's launch-policy file |
| hook-response | Null-case output line | `grep -c 'Control firings:' release/references/how-to/hub-spoke-bridge.md` — expect 3 | The mandatory control-firings line appears in the output schema, is named as the compensating control inside the clause's honest-scope paragraph, and is carried by the planning-template pointer |
| hook-response | Planning-template pointer, not a copy | `grep -c 'Hook-Response Discipline' release/references/how-to/hub-spoke-bridge.md` — expect 4 | The Procedure 0 planning template carries a pointer that cites the canonical clause rather than restating its body |
| hook-response | Failure-mode catalog entry | `grep -c '^### Control-evasion by token obfuscation' core/standards/failure-mode-standard.md` — expect 1 | One entry, five template fields, exactly one category tag, inside the existing hub-and-spoke example family |
| hook-response | Cascade reconciliation of both enumerations | `grep -c 'hook-response guard' release/skills/release-hub/SKILL.md` — expect 1 | The skill definition's enumeration of the launch-policy file's contents is no longer a stale subset |
| hook-response | **Behavioral render** | Declared, verification deferred to Stage 7 dev testing — observation of a spoke prompt rendered by the hub after this merge | The rendered prompt carries or cites the clause. **A file-presence grep does not discharge this**; the propagation path is hub-mediated and observably lossy, so only an observed render is evidence |
| hook-response | Non-contradiction with the git-idiom subsection | Declared, verification deferred to Stage 7 dev testing — LLM-graded read-back of the new clause against the pre-existing hook-safe git-idiom subsection | A reader concludes the two are consistent, not conflicting. Highest-value graded check on this card |
| s2 | Path convention present | Declared, verification deferred to work-unit 3 | The convention is present as a delta on the run-directory section, and the standing-guard ordinal is reconciled exactly once |
| mode-coupling | Per-hook mode matrix | Declared, verification deferred to work-unit 4 and the Stage-7 ladder | For each of the nine: enforce with an unreadable dependency library still exits non-zero; warn and off exit zero **with non-empty stderr** carrying the dependency-missing marker. The enforce arm is load-bearing — a matrix that only proves the permissive arm has verified the regression, not the invariant |
| mode-coupling | Always-enforce floor untouched | Declared, verification deferred to work-unit 4 | The four always-enforce hooks are byte-identical to their merge-base state and the decision record states the exclusion was deliberate |
| s3 | Posture surface shipped at `warn` | Declared, verification deferred to work-unit 5 | The per-rule mode template ships and its content is `warn`; the readiness rule's cohort list equals the grep-derived cohort |
| release-wide | Skill-package freshness | Declared, verification deferred to the final Engineering slice — the pre-merge package-freshness gate is the authoritative runner | The release-hub package is content-fresh against its edited sources |
| release-wide | Doc-link integrity | Declared, verification deferred to the final Engineering slice — the deploy link-resolver check is the authoritative runner | Every internal markdown link in every modified file resolves |

---

## Quota Budget

**Verdict: PASS** at plan time, advisory. Worst parallel batch is three spokes at Stages 5, 7, and 8, weighted small/small/medium — among the lightest batch shapes the ordinal bands describe. The remaining envelope was not stated at hub start, so the conservative default applies.

**This is a usage-window budget, not a rate-limit problem, and the plan-time estimate is advisory.** The load-bearing gate is the hub's per-launch checkpoint, re-validated at every launch — wave or singleton — against the *remaining* envelope, with the verdict rendered every time including on PROCEED.

**Caveat with teeth:** the PASS assumes the batch actually runs at width three. Under the SINGLE topology the Stage-6 units run one at a time regardless. The binding constraint on this release is **contention, not quota**.

---

## Delivery Strategy

Single release branch `release/hook-precision-and-boundaries`, one pull request, one merge — **milestone equals one pull request equals one merge**. This plan lands as Engineering Commit 0 after the Commit-0 version re-verify above. Stage-6 spokes commit sequentially on the shared branch under posture P0.

The pull request opens in **draft** at Commit 0 plus the first work-unit, so later Engineering slices land against a live pull request; it is marked ready only after the remaining work-units land and the Stage-9 gate renders GO.

Commit messages and the pull-request title are **slug-primary**: `release(hook-precision-and-boundaries): …`. No version literal appears in any of them, in the branch name, or in this file's identity prose.

All three members are **marked as closed at Stage 13** through the pull request's Issue References block. Close-family keywords appear **only** in that block, never in the summary or implementation sections — the auto-close parser is lexical, so section context and negation do not constrain it.

---

## Rollback

**Reversibility: MODERATE / Confidence HIGH.** Revert the release merge commit. No schema migration, no data mutation, no destructive host operation, no tag deletion.

Two carve-outs, which are why the release-level tier is MODERATE rather than CHEAP:

1. **The per-rule mode value lives outside the repository.** The tracked artifact is a template; the operative value is a git-ignored operator-local file. A revert restores the template, not the setting.
2. **One operator-executed post-deploy action lives outside the repository** — the hook-wiring re-home. The repository can neither see nor gate it. Reverting the merge does not unwind it; the operator does.

---

## Deviation Log

Each entry states what changed, the basis, and the reversibility and confidence tier. Entries D-1 through D-H are the operator-rendered gates; entries A-1 onward are the Tier 1 [ADJUST] amendments carried into this plan at Commit 0 without a gate.

**D-Plan · Stage-4 plan approved as briefed** — re-sequenced with the boundary card sliced into three; SINGLE topology; single-branch revert. MODERATE / HIGH.

**D-ReleaseClass · `routine` → `novel`.** Zero routine triggers fire and all three novel triggers do. The milestone's stated rationale was reasonable at bundle time and is falsified by two discoveries: the release does create a new governance artifact, and the posture work *is* an enforcement-surface change rather than a bounded correction. Cheaper-to-stricter, so CHEAP / HIGH.

**D-1 · The posture flip gets a dedicated per-rule mode file, not a shared-cohort flip.** The shared mode file covers eight hooks; flipping it would promote seven out-of-scope hooks with no shakedown. Three hooks already carry their own mode file, so per-hook mode scoping is established precedent rather than a new invention. MODERATE / HIGH.

**R1 · Serialization hold on the concurrent execution-safety release — HOLD, now DISCHARGED.** Scaffolding and Stage 5 proceeded; Stage 6 was gated on that release merging. It merged as `303de6e0`. MODERATE / HIGH.

**D-A · The posture change moves the last of four coverage conditions, and the dependency is stated rather than implied.** The condition that actually gates hook loading is delivered by an operator-run re-home step from the upstream release. Named in the clause, in the release notes, and in the post-deploy operator actions. **The flip is never described as the remedy.** MODERATE / HIGH.

**D-B · The path-leak rule ships at `warn`, not `enforce`.** The forty-eight-day warn window's zero deployed warn-log lines is not weak evidence of safety — it is *no evidence either way*, because the hook was not loaded in the sessions that matter. A zero whose instrument was never connected measures the wiring, not the behavior. Shipping enforce on that basis would be acting on a broken probe. **s3 therefore delivers the per-rule mode surface with a `warn` default — the mechanism, not the final posture.** All three of the card's outcomes remain in scope. MODERATE / MEDIUM.

**D-E · Snapshot the mode into a read-only value above the dependency guard.** The guard sources the untrusted library inside its own condition, so a library defining a permissive mode reader overwrites a hoisted definition and yields a success exit with enforce on disk. A read-only value cannot be overwritten by the sourced library. MODERATE / HIGH.

**D-F · The dependency-backstop invariant is false; ship the coupling anyway and file the invariant defect separately.** A syntactically-valid corrupt library makes all three always-enforce guarantors exit zero silently — a syntax precheck checks syntax, not meaning. The coupling work is correct; only its stated rationale was overstated. Pre-existing, not introduced by this release. MODERATE / MEDIUM.

**D-G · Repair the `warn`-mode deferral.** `warn` plus un-re-homed wiring produces an empty observable set indistinguishable from clean, so the enforce-flip trigger cannot fire. The re-home step therefore becomes a **tracked post-deploy operator action with a verification** — not a note, not a deferral — and it carries the Bash-over-block seam for re-check at flip time. Without this repair the release would ship a control whose promotion criterion is structurally unreachable. CHEAP / HIGH.

**D-H · The upstream release's public run-directory echo — blocked on fix-forward.** The Stage-6 hold was extended until that mandate was dropped or narrowed to a relative directory name. **Discharged:** the merged text mandates the relative form and explicitly forbids the resolved absolute path, on the stated ground that the scratch base embeds the operator's OS username and the output comment is a public surface. MODERATE / HIGH.

**A-1 · CIAC-1 restated relatively, and its second limb re-aimed.** See the criterion above. The absolute count was invalidated by the upstream merge before this release began; the string-removal limb would have made the enumeration wrong. Major / CHEAP / HIGH.

**A-2 · File Change Matrix amended with six paths.** Enumerated in the matrix section with a per-path necessity reason. An unlisted required path is how a package-freshness failure reaches Stage 12. Major / CHEAP / HIGH.

**A-3 · The mode-coupling card's acceptance criteria restated to the achievable outcome.** The card is often read as removing the over-block outright. It does not, and cannot. **What ships:** the over-block is removed for the **version-skew** case — the condition the card's own problem statement describes, where an operator running a stale or partially-updated library sees every Bash and Write hard-blocked by a guard unrelated to what it guards. **What does not ship, and why:** the over-block is **not** removable for the library-absent case while three always-enforce hooks retain an unconditional non-zero exit on a missing library. Those hooks have no warn or off state to degrade into; giving them one would invent a mode surface they deliberately do not have and weaken a security floor. The criterion is written to the first case and states the second as a retained, deliberate residual. Major / CHEAP / HIGH.

**A-4 · The hook-response clause's honest-scope declaration gains one sentence, and one of its supporting reasons is narrowed.** The declaration quoted the canonical correction record while dropping the clause immediately preceding it — the record routed this remedy class to a **harness signal rather than an agent-judgment one**. The clause is not that remedy, and now says so. Separately, the reason "no corpus-level rule stood behind the prior instruction" is **false**: the brief did name the workspace-global hook-blocked handoff convention, an auto-loaded corpus rule, and it was still not followed. The true, narrower form is that **no rule prohibited tool substitution specifically** — re-attempting a refused action through a second tool or endpoint to reach the outcome a control declined. Major / CHEAP / HIGH.

**A-5 · A mandatory null-case line is added to the spoke output contract.** The clause requires an evidence record only when a control fires, so an evading spoke and a clean spoke emit byte-identical output. One line — `Control firings: none | <list>` — rendered every time, makes the null case emit. An omitted mandatory field is a schema defect a QA pass can see; an omitted optional one is invisible. This is the convention the output block already uses for its provenance match field, and the upstream release states the same reasoning twice in its own additions. Major / CHEAP / HIGH.

**A-6 · A failure-mode catalog entry ships with the clause.** The design cites the standard's N≥2 promotion rule as a reason to ship. The rule prescribes an entry. Two independent instances are on the record from this release alone, so the promotion threshold is met by this release's own evidence. Major / CHEAP / HIGH.

**A-7 · One sentence cut from the launch-policy guard as out-of-acceptance-criteria scope.** The drafted guard carried a normative precondition binding *future* releases — that the guard is a precondition for tightening any control from warn to enforce. No gate, checklist, or check reads the launch-policy file at the moment an enforce-promotion is decided, so the constraint would be discoverable only by someone who already knew it existed — the same enforcement gap the card was filed to address. Cut rather than kept-and-registered: the work order already satisfies it and the card did not ask for it. Minor / CHEAP / HIGH.

**A-8 · No mechanical check ships in the discipline card, and the deferred check is re-aimed.** The prohibited act is not mechanically detectable: obfuscation is definitionally the absence of the token any matcher would key on, the block log records a one-way digest with no session attribution, and a call that succeeds leaves no row at all. The deferred check therefore belongs in **the hub-side pre-spawn scan of the rendered brief** that work-unit 3 introduces — **not** in the enum-parity engine, which parses enum value sets rather than heading sets and was absent from the mainline when it was named, and **not** as static template-to-template parity, which would have caught neither observed failure **because the render dropped the content, not the templates**. Informational / CHEAP / HIGH.

**A-9 · Four further Tier 1 amendments carried for the downstream hook work-units.** (a) The hook-dependency-hardening check greps guard *text* and is therefore green in exactly the scenario that fails at runtime — the same defect shape as A-8's. (b) The test census is short by two, both of them backstop hooks with zero dependency-missing coverage, so only one of the invariant's three guarantors is tested. (c) Five artifacts in the boundary card's spec still assume the superseded enforce default, including a warn message naming a file the hook no longer reads with no test covering that line, and an exclusivity test that passes for a non-exclusive build under `warn`. (d) The path convention is authored as a **delta** on the upstream release's run-directory section rather than as an independent guard, because that section already governs where scratch goes and uniqueness; the residual this release owns is the *path form* the orchestrator injects into the brief. Major / CHEAP / HIGH.

**A-11 · The Stage-4 planning-template pointer takes its own heading rather than a bare appended line.** The design specified "one pointer line, not a copy," to avoid deepening the parallel-block debt the two spoke templates already carry. A bare paragraph appended after the preceding block would read as that block's continuation, which is the wrong owner. The pointer therefore takes its own heading and stays four lines — still a pointer, still not a copy, and the debt the design declined to deepen is the duplicated *body*, which this does not duplicate. Cosmetic / CHEAP / HIGH.

**A-10 · Decision-record number re-derived at Commit 0.** The design body cited a number that concurrent merges have since taken. Next-free on the mainline is now ADR-129, measured with both probe arms. Allocate at authoring time from the mainline tree listing, never from the checker. Cosmetic / CHEAP / HIGH.

---

Entries E-1 onward are Stage-6 Engineering deviations, recorded at the commit that carried them.

**E-1 · The breaking-assertion census was short by one, and the miss is in the probe's scope rather than its execution.** Both the design and the independent review reported *exactly three* assertions encoding the superseded unconditional posture, and both were right within their denominator: each probed `core/hooks/tests/block-*.test.sh`. A fourth lives in `ghsa-g9g6-primitive-fail-closed.test.sh`, which does not match that glob, and it surfaced by running the suite rather than by reading it. Re-pointed with the rest. The generalizable point: a census over a glob is only as complete as the glob, and two independent reviewers sharing a denominator do not constitute two independent checks of it. Minor / CHEAP / HIGH.

**E-2 · Two paths added to the File Change Matrix.** `core/rules/bypass-mode-readiness/_header.md` carries the registry-membership-versus-mode-cohort text this card is explicitly scoped to reconcile, and the matrix listed only the cross-cutting fragment. `core/hooks/tests/hook-fail-closed.test.sh` is the glob-derived behavioral meta-test and the only correct home for the runtime posture matrix. Both are required, not discretionary. Minor / CHEAP / HIGH.

**E-3 · The runtime arm went to the behavioral test, and the static check states its own blind spot instead.** The Tier 1 amendment asked that the hardening check either gain a runtime arm or say plainly what it does not cover. It got the second, deliberately: that file is a static grep guard whose companion behavioral test already declares the split — static catches source drift, behavioral catches the runtime semantic. Putting an execution arm inside the grep script would blur a documented separation to satisfy the letter of the amendment. The runtime arm exists, in the behavioral test, where the other runtime arms live; the static check names the scenarios in which its own green is uninformative and points at it. Minor / CHEAP / HIGH.

**E-4 · Per-hook warn/off arms were not duplicated into four more test files.** The design asked for a warn/off arm in each cohort hook's own test. The glob-derived matrix asserts all nine hooks across all three modes structurally, from source classification rather than a name-list, so per-file copies would be four duplicate assertions that a tenth hook would not inherit. The three files whose assertions actually broke were edited, and three of them additionally carry a hostile-library arm. Coverage is strictly greater than the design specified; its distribution is not. Minor / CHEAP / HIGH.

**E-5 · Decision-record number allocated at ADR-129, per A-10 above and against a later spoke-level instruction to reserve ADR-130.** The mainline tops out at ADR-128, so 129 is the true next-free slot. 130 was proposed on the ground that an unmerged sibling claims 129 — but the naming convention states the opposite rule verbatim: an unmerged claim does not bind the sequence, a number is allocated at authorship and *claimed at merge*, first-to-merge takes it and the other claimant renumbers by tool, and pre-reserving a higher slot is explicitly no remedy because the integrity checker fails a gap as readily as a duplicate. Confirmed live — the checker FAILS at 130 (`GAP: missing ADR-129`) and PASSES at 129 (`contiguous 001..129`). The risk is asymmetric: a collision at 129 is resolved mechanically at merge, whereas 130 lands a gap on the mainline if this release merges first, and that gap then fails every subsequent pull request. Major / CHEAP / HIGH.

---

## References

Designated reference block. Each entry pairs the tracker number with a summary noun phrase, so the meaning survives even if the number does not.

| Number | What it is |
|---|---|
| Milestone **310** | `hook-precision-and-boundaries` — this release's milestone; three members sliced into five ordered work-units, composition locked at Collective Review. |
| **#4186** | The corpus-to-public-surface boundary card — state the boundary, codify the spoke-brief path form, deliver the per-rule mode surface for the path-leak rule. Sliced s1/s2/s3. |
| **#3805** | The spoke hook-response discipline — reword or surface, never obfuscate a token to evade a firing control. |
| **#3429** | The dependency-missing guard mode-coupling — the guard hard-blocks regardless of the operator's declared mode; couple it across the nine mode-bearing hooks. |
| **#4924** | The concurrent hub-and-spoke execution-safety release this one was serialized behind; merged, discharging the Tier-S edge. |
| **#4989** | The Stage-4 release-planning sub-task carrying this plan's source output and the plan-gate decision record. |
| **#5000** | The Stage-5 Solutioning sub-task for the hook-response card, carrying its design, the independent adversarial review, and the Collective Review scope-lock. |
| **#5001** | The Stage-6 Engineering sub-task for the hook-response card, where this Commit 0 is reported. |
| **ADR-092** | Release identity is slug-primary until the Stage-12 atomic claim — the decision this plan's version handling implements. |
| **ADR-078** | The prior security-hook dependency-resolution posture, whose fail-closed determination work-unit 4's new record supersedes. |
| **ADR-115** | An unmerged decision-record number claim does not bind; collisions reconcile at Stage 12. |
