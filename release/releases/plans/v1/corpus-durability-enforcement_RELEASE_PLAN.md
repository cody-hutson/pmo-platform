<!-- repo-integrity: allow-issue-ref -->
<!-- repo-integrity: allow-memory-ref -->
<!-- reference-durability: allow-link -->
# Release Plan — corpus-durability-enforcement

> **Status:** Engineering Commit 0 (release branch `release/corpus-durability-enforcement`).
> **Topology:** D-C SINGLE · **Release Class:** `novel` · **Milestone:** corpus-durability-enforcement.
> **Source:** Stage 4 Release Planning spoke output (transcribed verbatim from the Stage 4 planning sub-task; the one `close #N` phrase corrected to safe form per `core/rules/git-workflow.md` § Parser-clean PR body discipline). Scope-locked at Stage 5 Collective Review (operator, 2026-06-13): #316 → Candidate B; #311 → Delta-2-primary build.

---


### Summary (30 seconds)

Two independent `type:task` issues, both "corpus-durability enforcement gate" work, but on **non-overlapping enforcement surfaces** — so the release is cleanly parallelizable in design and serial-trivial in execution. **#316** (P2) single-sources two hand-duplicated shared references and adds an enforcing freshness gate; **#311** (P3) prohibits milestone/issue/PR refs and version-cutover clauses outside the release-tracking ledger and enforces it in CI.

I independently re-ran every load-bearing hub pre-verification finding against canonical source (commands below). **All hub findings confirmed; one finding sharpened.** #316 reproduces exactly as filed (6 byte-identical `output-format.md` copies, md5 `c43de7d8…`, none in `TEMPLATE_SYNC_MAP`; no `depends_on:` frontmatter anywhere → net-new). #311 is substantially pre-shipped: **Delta 3 (version-cutover) is fully enforced today** (fold to verify-only), **Delta 2 (raw `github.com/.../{issues,pull,milestone}` URL prohibition) is genuine net-new** (no hook/CI detects raw URLs), **Delta 1 (5-surface allowlist) is partial**. **Sharpened finding on Delta 1:** `CHANGELOG.md` is the only one of the 5 surfaces that lives at repo top-level — it is **outside the `reference-durability` durable-corpus scope entirely** (that gate only scans `core/`/`release/`/skill paths) AND **outside the `release/releases/*` tracking-surface exemption** that the `repo-integrity` gates carry. So CHANGELOG sits in an un-modeled seam: exempt-by-omission from durability, but in-scope for `repo-integrity` issue-ref + dead-file-ref. Net-new = formalize the named 5-surface allowlist as a single queryable enforcement input AND resolve CHANGELOG's seam explicitly.

**Headline recommendations:** Release Class **`novel`** · Branch Topology **D-C SINGLE** · #311 re-scope **Delta-2-primary build** (Delta 2 net-new + Delta 1 allowlist formalization; Delta 3 verify-only). Both issues keep all stages (no skips) — both ship enforcing gates with functional impact and both carry a real Stage 5 design decision. **No merge/split** — keep as 2 issues on one branch, sequence #316 → #311.

---

### Dependency Graph

```
#316 (single-source + enforced rebuild)        [no edge]        #311 (ref-allowlist + CI prohibition)
```

- **Confirmed: independent — no intra-milestone dependency edge.** Hub finding upheld with evidence.
- **Evidence — disjoint enforcement surfaces:** #316's enforcing gate is `deploy.sh --check` (the Check 13 / `sync_canonical_templates_to_runtime` template-injection family) plus sync-map generation in `core/deploy/deploy.sh`. #311's enforcement is the **CI workflow layer** (`reference-durability.yml` / `repo-integrity.yml`) plus the `block-fragile-refs.sh` PreToolUse hook. Neither issue's deliverable is an input to the other's; no shared symbol; no ordering constraint imposed by either body.
- **All cross-refs are out-of-milestone (coordinate, not block):**
  - #316 → #317 (first consumer), #318 (Check-14 template↔schema), #314 (reference-durability CI position bug), #295 (frontmatter rule) — all in OTHER milestones.
  - #311 → blocks #249, composes-with #30 — both in OTHER milestones; the historical `#538`/`#572` in the issue body predate the 2026-06 re-versioning and do not resolve to current-scheme issues (no current equivalent; treat as historical record only — do not chase).
- **Net:** the DAG is two isolated nodes. Sequencing below is a contention-avoidance and momentum choice, not a dependency requirement.

---

### Implementation Sequence

Execution order (Engineering, Stage 6), under D-C SINGLE — one release branch, serialized commits:

| Order | Issue | Engineering scope | Why this order |
|---|---|---|---|
| 0 | Engineering Commit 0 | Release plan file `release/releases/plans/<version>-corpus-durability-enforcement_RELEASE_PLAN.md` (this plan, transcribed verbatim) | D-C SINGLE topology convention |
| 1 | **#316** | Single-source the 2 shared refs; `depends_on`-style declaration mechanism (per Stage 5 D-decision); sync-map generation + enforcing `deploy.sh --check`; `core/standards/template-storage.md` + `core/rules/skill-deployment.md` updates | Larger/more-central change (P2; touches `core/deploy/deploy.sh` — the platform's highest-traffic tool); land the deploy-surface change first so #311's CI work rebases onto a stable deploy.sh |
| 2 | **#311** | Allowlist standard (named 5-surface set + CHANGELOG seam resolution); net-new raw-URL detector in the CI/hook layer; `core/rules/git-workflow.md` gate-doc update | CI/hook-layer change; no dependency on #316 but sequencing-second keeps the two `core/rules/` edits (skill-deployment.md vs git-workflow.md) on separate commits for a clean diff |

Sequence rationale is **contention-hygiene + blast-radius-descending**, not dependency. Either order is functionally valid; #316-first is recommended because `core/deploy/deploy.sh` is the busiest shared file in the tree and is best landed before adjacent work.

---

### Stage Applicability Matrix

Default is all stages (5–13). Skip Solutioning only if trivial; skip DT/QA (7–8) only if no functional impact. **Neither condition holds for either issue.**

| Stage | #316 | #311 | Rationale |
|---|---|---|---|
| 5 Solutioning | **APPLY** | **APPLY** | Both carry a real, body-flagged design decision. #316: `depends_on:` frontmatter-vs-central-`TEMPLATE_SYNC_MAP`-generation (the issue body explicitly defers this to Stage 5; this is also a **skill-authoring-surface** decision → D-Gate Upstream-Compatibility check vs `anthropic-skills:skill-creator` frontmatter schema is REQUIRED at Stage 5). #311: the re-scope itself (which deltas to build; allowlist representation; CHANGELOG seam; warn-vs-enforce + shadow window) is design work. |
| 6 Engineering | **APPLY** | **APPLY** | Both produce code/doc edits + enforcement wiring. |
| 7 Dev Testing | **APPLY** | **APPLY** | Both ship **enforcing gates** with functional impact. #316 AC requires "mutate a mirror → `deploy.sh --check` exits non-zero" — that is a testable behavior. #311 requires the CI detector to flag a planted raw-URL violation and pass a clean file. |
| 8 QA Testing | **APPLY** | **APPLY** | Gate behavior change to the operator's commit/PR flow → independent QA verification warranted (false-positive surface: #316 sync-map false drift; #311 raw-URL detector over-matching legitimate ledger URLs). |
| 9 Plan Review | **APPLY** (release-scoped) | — | Single per-release gate. **Deep** review depth (novel class). |
| 10–11 | compress (git-native) | compress | Per harness-deployment.md / release-process.md — Stages 10–11 compress for git-native releases. |
| 12 Execute | **APPLY** (release-scoped) | — | Single per-release spoke; includes Stage 12 chore PR (RELEASE_LOG row + visible-H4 Deployment Log). |
| 13 Close | **APPLY** (release-scoped) | — | Single Close chip; INDEX + DIGEST + RELEASE_NOTES + RELEASE_LOG VERIFIED transition. **Includes the standing "Check 14 flip-to-enforce assessment" line item** (doc-link-maintenance.md mandates it at every Stage 13 close). |

**Solutioning composability note:** With ≥2 issues at Stage 5, the **Collective Review protocol fires** after both Stage 5 sub-tasks close and before any Engineering chip routes (per hub-spoke-bridge Procedure 2 step 3). Because the two designs touch disjoint surfaces, expect a low-friction scope-lock — but the N-way consistency check still runs (both #316 frontmatter decision and #311 allowlist representation are governance-touching).

---

### Contention Map

| Surface | #316 | #311 | Contention? |
|---|---|---|---|
| `core/deploy/deploy.sh` | **EDIT** (sync-map gen + enforcing `--check`) | no | **None** — single writer |
| `.github/workflows/reference-durability.yml` | no | **EDIT-candidate** (raw-URL detector) | **None** — single writer |
| `.github/workflows/repo-integrity.yml` | no | **EDIT-candidate** (alt detector home) | **None** — single writer |
| `core/hooks/block-fragile-refs.sh` | no | **EDIT-candidate** (hook-side raw-URL parity) | **None** — single writer |
| `core/rules/` | **EDIT** `skill-deployment.md` | **EDIT** `git-workflow.md` | **Directory-shared, file-disjoint** — different files; no line contention. Both are durable-corpus paths → both writes are subject to the `block-fragile-refs.sh` hook (warn-mode) and `reference-durability.yml` CI; author parser-clean. |
| `core/standards/` | **EDIT** `template-storage.md` | **NEW/EDIT** allowlist standard (e.g., new `core/standards/<name>.md` or a section in `universal-vs-release-pipeline-split-rule.md`) | **Directory-shared, file-disjoint** — no contention; if #311 extends the split-rule doc rather than adding a new file, still a different file from #316's target. |
| `operations/skills/*/references/{output-format,operational-artifacts}.md` | **CONSOLIDATE** (6+2 → canonical) | no | **None** |
| `operations/skills/*/SKILL.md` (frontmatter) | **EDIT** (depends_on declaration) | no | **None** — but routed through `pmo-skill-editor` (Gate 2 hook `block-skill-direct-edit.sh` blocks direct Write/Edit to migrated SKILL.md). Stage 6 chip MUST flow SKILL.md edits through `pmo-skill-editor`, not raw Edit. |
| `CHANGELOG.md` | no | **possible EDIT** (override marker or seam resolution) | **None** |

**Verdict:** **Zero file-level contention** between the two issues. The only shared directories are `core/rules/` and `core/standards/`, both file-disjoint. Under D-C SINGLE the two Engineering commits serialize on branch HEAD regardless (which is the whole point of SINGLE) — and with disjoint files even that serialization carries no merge-conflict risk. Pattern cited: `feedback_release_ops_concurrent_spoke_multi_worktree_contention.md` (N=4) — same-branch concurrent Stage 6 spokes produce 4 git-race classes; **avoided here by serialization (one chip at a time), not recovery.**

---

### File-Level Change Matrix

One path per line; `intent` ∈ {add, edit, delete, consolidate}. Paths are deterministic-extractable by downstream Stage 7/8/9 chips. SKILL.md frontmatter targets (#316) are mechanism-pending at Stage 5 — listed as the recommended-but-unconfirmed surface; Stage 5 may finalize the exact frontmatter key.

```
# --- #316: single-source shared references + enforced rebuild ---
core/deploy/deploy.sh                                                          edit      # sync-map generation from declared deps; enforcing (non-zero exit) --check
core/standards/template-storage.md                                            edit      # §3 propagation, §3.5 drift detection becomes blocking, §6 registration
core/rules/skill-deployment.md                                                edit      # agent-facing rebuild-on-canonical-edit trigger; name trigger paths
operations/skills/comms-writer/references/output-format.md                    consolidate  # → single canonical source
operations/skills/change-management/references/output-format.md               consolidate
operations/skills/delivery-engine/references/output-format.md                 consolidate
operations/skills/pmo-process-designer/references/output-format.md            consolidate
operations/skills/pmo-technical-analyst/references/output-format.md           consolidate
operations/skills/ppm-agent/references/output-format.md                       consolidate
operations/skills/comms-writer/references/operational-artifacts.md            consolidate  # → single canonical source
operations/skills/ppm-agent/references/operational-artifacts.md               consolidate
operations/skills/comms-writer/SKILL.md                                        edit      # depends_on declaration (Stage-5-confirmed mechanism; via pmo-skill-editor)
operations/skills/change-management/SKILL.md                                   edit      # depends_on declaration (via pmo-skill-editor)
operations/skills/delivery-engine/SKILL.md                                     edit      # depends_on declaration (via pmo-skill-editor)
operations/skills/pmo-process-designer/SKILL.md                               edit      # depends_on declaration (via pmo-skill-editor)
operations/skills/pmo-technical-analyst/SKILL.md                              edit      # depends_on declaration (via pmo-skill-editor)
operations/skills/ppm-agent/SKILL.md                                          edit      # depends_on declaration (via pmo-skill-editor)
# canonical home for the two consolidated references (Stage 5 picks exact path; e.g.):
core/standards/output-format.md                                               add       # [Stage-5-confirmed location] single canonical source for the 6 consumers
core/standards/operational-artifacts.md                                       add       # [Stage-5-confirmed location] single canonical source for the 2 consumers
# --- #311: ref-allowlist + CI prohibition (delta over shipped enforcement) ---
core/standards/universal-vs-release-pipeline-split-rule.md                     edit      # formalize named 5-surface ref-permitted allowlist; add CHANGELOG; OR new standard file
.github/workflows/reference-durability.yml                                     edit      # net-new raw github.com/.../{issues,pull,milestone} URL detector (Delta 2)
core/hooks/block-fragile-refs.sh                                              edit      # hook-side raw-URL parity (keep hook ↔ CI detector byte-identical per existing convention)
core/rules/git-workflow.md                                                     edit      # document the new raw-URL prohibition under §Repository-Integrity / §Reference Durability
CHANGELOG.md                                                                   edit      # resolve the top-level seam (override marker or explicit allowlist entry)
```

**Matrix file count: 26** distinct paths (18 for #316, 8 for #311). Two #316 `add` paths and the #311 detector-home path are Stage-5-confirmable (exact canonical location / which workflow file hosts the detector); all other paths are firm. Stage 5 may collapse the `reference-durability.yml` + `repo-integrity.yml` choice to one file — the matrix lists `reference-durability.yml` as the recommended home (it already carries the byte-identical-to-hook `CUTOVER_RE` convention, so a raw-URL detector belongs alongside it).

---

### Risk Register

| ID | Risk | Sev | Source | Mitigation |
|---|---|---|---|---|
| R1 | **#316 enforcing gate blocks commits** — making `deploy.sh --check` exit non-zero on mirror drift is a behavior change to the operator's flow; a false-positive (legitimate divergence flagged as drift) could block an unrelated commit. | MED | #316 body "an enforcing gate can block commits — intended, but a behavior change" | Ship **warn-mode initial** per the `bypass-mode-readiness.md` precedent (Checks 8/9/10/14 all did); flip-to-enforce after a shakedown window with operator sign-off at a Stage 13 close. DT plants a true-drift case AND a legitimate-divergence case to bound false-positive rate. |
| R2 | **#311 over-scope** — re-authoring content the shipped reference-durability standard already delivers (especially Delta 3, fully enforced today). Re-building Class V detection would duplicate `block-fragile-refs.sh` + `reference-durability.yml`. | HIGH | Issue's own 2026-06-03 triage note; hub pre-verification; **independently confirmed** (Class V `CUTOVER_RE` is live in both hook and CI). Pattern: `feedback_release_ops_intake_pre_rendered_artifacts.md` (N=2). | **D-311-Rescope (below) is the primary control.** Plan #311 as the **delta only**: Delta 2 net-new + Delta 1 allowlist formalization; Delta 3 = verify-only with R3-evidence (cite the live detector lines), never re-author. Stage 5 spec must open with the reconciliation table, not a from-scratch standard. |
| R3 | **#316 raw-URL vs #311 ledger-URL false-positive interaction** — #311's new raw-`github.com/.../{issues,pull,milestone}` detector must NOT flag the legitimate URLs in the 5 ledger surfaces; the existing `repo-integrity`/`reference-durability` gates exempt `release/releases/*` but **CHANGELOG.md is top-level and outside that exemption**. | MED | Sharpened Delta-1 finding (this plan) | The #311 detector MUST carry the same tracking-surface exemption AND explicitly cover CHANGELOG.md (override marker `<!-- reference-durability: allow-link -->`-style, or an explicit allowlist entry). DT plants a ledger-URL-in-CHANGELOG case to confirm it is NOT flagged. This is the load-bearing edge case for #311. |
| R4 | **SKILL.md edit path** — #316 edits 6 SKILL.md frontmatters; direct Edit is blocked by `block-skill-direct-edit.sh` (Gate 2) for migrated skills. A Stage 6 chip that uses raw Edit will be hook-blocked. | LOW | `core/rules/skill-deployment.md` §Mandatory Tooling | Stage 6 chip routes SKILL.md edits through `pmo-skill-editor` (Mode A). Note this explicitly in the #316 Engineering chip prompt. |
| R5 | **Rollback complexity** — both changes are durable-corpus + CI/deploy-tool edits; rollback is git-revert of the release PR. #316's reference consolidation deletes 8 mirror files; a revert restores them, but any skill deployed between merge and revert would have shipped against the new canonical. | LOW→MED | Plan analysis | Rollback = revert the release PR on `main` (operator-authorized per RELEASE_PROTOCOL.md §Rollback). Because enforcement ships **warn-mode**, a mid-window revert has no enforce-state to unwind. Re-run `./deploy.sh --deploy` post-revert to re-sync skill mirrors. Reversibility tier: **MODERATE** (file deletes + deploy-tool behavior; days to unwind, minor mirror-state cleanup). |
| R6 | **Cross-PR contention (baseline-pinned)** — A4 audit is baseline-pinned; in-flight releases (v1.09/v1.10 just shipped 2026-06-11/12; any concurrent release) could touch `deploy.sh` or the CI workflows during this release's window. | LOW | stage-04-planning.md §Baseline-pin temporal limitation; `feedback_release_ops_audit_baseline_when_target_population_is_empty.md` | **Baseline pinned: `origin/main` at the merge of PR #668 (v1.11, SHA `38f97d31`, 2026-06-12), with a last-N-merged + open-PR window.** Open-PR population is empty at this baseline (no open PRs observed) — per the audit-baseline pattern, this default-to-zero is NOT load-bearing alone; **re-check the open-PR + recently-merged population at Stage 9 Phase A6.5 and Stage 12 Phase A.5** before relying on "no cross-PR contention." Mid-pipeline divergence is caught at those stage boundaries, not by this Stage 4 snapshot. |

**Highest risk: R2 (#311 over-scope, HIGH)** — the entire judgment value of this release is in scoping #311 to its genuine delta and resisting re-authoring the shipped durability standard.

---

### Recommendations

1. **Approve as 2 issues on ONE branch (D-C SINGLE), no merge/split.** They are independent and surface-disjoint, but bundling them under one release branch + one PR is correct: shared milestone, shared "corpus-durability enforcement gate" theme, trivial serialization cost (disjoint files), and one Stage 9/12/13 cycle covers both. Splitting into two releases would double the release overhead for zero contention benefit. Merging into one issue would lose the distinct AC sets and the distinct enforcement surfaces.
2. **Sequence #316 → #311** at Engineering. Contention-hygiene + blast-radius-descending (`deploy.sh` is the busiest shared file; land it first). Not a dependency — either order is valid.
3. **#311: build the delta, verify the rest** — see D-311-Rescope. Recommended option: **Delta-2-primary build** (build the net-new raw-URL detector + formalize the named 5-surface allowlist incl. the CHANGELOG seam; fold Delta 3 as verify-only with R3-evidence citing the live `CUTOVER_RE` lines). Do NOT re-author Class V detection.
4. **Both gates ship warn-mode initial** (R1, R2) per the established `bypass-mode-readiness.md` shakedown precedent; flip-to-enforce is a later operator decision at a Stage 13 close.
5. **Stage 5 is REQUIRED for both** and triggers the Collective Review before Engineering. The #316 frontmatter decision carries a **REQUIRED Upstream-Compatibility check** against `anthropic-skills:skill-creator` (it modifies what a skill's frontmatter contains) — consult `core/standards/upstream-reference-catalog.md` (`skill-md-frontmatter` entry) at the D-Gate.
6. **#316 SKILL.md edits route through `pmo-skill-editor`** (R4) — bake into the Engineering chip prompt.
7. **CHANGELOG.md seam (sharpened finding)** — Stage 5 #311 spec MUST explicitly decide CHANGELOG's treatment: it is outside both the durable-corpus scan scope and the `release/releases/*` exemption, so it needs either an explicit allowlist entry or an override marker. This is the one place the hub pre-verification under-specified; surfacing it here so it is not discovered at Engineering.

**Out-of-scope discoveries (noted, not acted on):**
- The `core/standards/universal-vs-release-pipeline-split-rule.md` §5 "known divergences" (two verified file misplacements: `per-stage-shard-standard.md`, `planning-solutioning-handoff.md`) are catalogued-for-follow-up, unrelated to this milestone. No action.
- The historical `#538`/`#572` references in #311's body are pre-re-versioning and do not resolve to current-scheme issues. They are correctly framed as historical record in the body; no reconciliation needed, but a future body-hygiene pass could note their non-resolution. Not this release.

---

### Operator Decisions

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke-proposed class + trigger-condition evidence per `release/references/specs/release-class-taxonomy.md`. The milestone description carries no `## Release Class` H2 yet — the operator decision lands it via a milestone-description PATCH at Phase B3.
**Pre-decided (if applicable):** None.
**Gate decision:** Choose between (A) `routine`, (B) `novel`, (C) `cross-cutting`, (D) `hotfix`.
**Recommendation:** **`novel`.** Trigger evidence: (a) #316 introduces a **new canonical reference doc** (the single-sourced `output-format.md`/`operational-artifacts.md` home) and a **new declaration mechanism** (`depends_on:` frontmatter) → novel trigger (a); (b) **≥1 D-class decision in the plan** (this block + D-C + D-311-Rescope, and the Stage-5 frontmatter-mechanism decision) → novel trigger (b). NOT `cross-cutting`: the File Change Matrix touches **0** `pipeline/stage-*.md` files and only **1** of the cross-cutting governance set (`git-workflow.md`); it does not meet the ≥3-stage / ≥3-governance-surface threshold. NOT `routine`: new files added + new D-class decisions both disqualify. NOT `hotfix`: not a corrective patch against a deployed defect.
**Differentiation posture:** Engagement density **Standard**; Stage 9 review depth **Deep** (novel); Stage 5 activation bias **ALL** (both issues activate Stage 5; the cross-issue compositional surface — two enforcement gates — warrants it); Stage 13 outcome-window **30-day**.
**Blocks:** milestone-description `## Release Class` section; downstream per-class posture (Stage 9 depth, Stage 5 activation).
**Upstream compatibility:** N/A — Release Class is PMO-platform-internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable later with operator approval per the Re-Classification Protocol; cheaper-to-stricter is CHEAP).

#### D-C: Branch Topology — SINGLE vs OPTION-A
**Gate input:** Spoke contention analysis (this plan) — 2 independent issues, zero file-level contention, shared `core/rules/` + `core/standards/` directories but file-disjoint.
**Pre-decided (if applicable):** None. (D-C SINGLE is the platform default per hub-spoke-bridge Procedure 0 §Canonical location.)
**Gate decision:** Choose between **D-C SINGLE** (one release branch `release/<version>-corpus-durability-enforcement`; serialized Engineering commits; plan as Engineering Commit 0; one release PR) and **D-C OPTION-A** (per-issue branches + per-issue PRs + a dedicated Stage-4-plan chore PR).
**Recommendation:** **D-C SINGLE.** Rationale: only 2 issues; **zero file-level contention** (so OPTION-A's parallel-commit benefit buys nothing here — there is no contention to isolate); SINGLE's serialized-commit model is trivially satisfied by routing one Engineering chip at a time (#316 then #311); one PR gives the operator a single Stage 9 diff covering both gates, which is the cleaner review surface for related enforcement work. OPTION-A would add two extra chore PRs and a multi-PR merge-order decision at Stage 12 for no contention payoff. Pattern cited: `feedback_release_ops_concurrent_spoke_multi_worktree_contention.md` (N=4) — SINGLE + serialization avoids the 4 same-branch git-race classes by construction.
**Blocks:** Procedure 1 scaffolding (per-issue sub-task shape); Engineering chip routing model; plan-file commit mechanism (Engineering Commit 0 vs Stage-4 chore PR).
**Upstream compatibility:** N/A — branch topology does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (topology is a per-release routing choice; re-selectable before Engineering Commit 0 lands).

#### D-311-Rescope: How much of #311 do we build vs verify-and-fold?
**Gate input:** Hub pre-verification + this spoke's **independent re-verification** of all three deltas against canonical source (commands and results below). #311's own 2026-06-03 triage note instructed "reconcile each AC against shipped enforcement; fold any covered AC, keep only the delta."

*Independent verification (re-run against the worktree at this baseline):*
- **Delta 3 (version-cutover-clause prohibition) → ALREADY SHIPPED.** `core/hooks/block-fragile-refs.sh` carries Class V `BLOCK-FRAGILE-REF-002` with `CUTOVER_RE` (lines 54/61), and `.github/workflows/reference-durability.yml` carries the **byte-identical** `CUTOVER_RE` (line 50) and enforces it on added durable-corpus lines at PR time. **Confirmed enforced today → fold as verify-only.**
- **Delta 2 (raw `github.com/.../{issues,pull,milestone}` URL prohibition) → GENUINE NET-NEW.** `grep` for `github.com` / `/issues/` / `/pull/` / `/milestone` over `block-fragile-refs.sh`, `reference-durability.yml`, and `repo-integrity.yml` returned **empty** in all three (beyond `repo-integrity`'s `#N`-resolution logic, which is a different construct). No detector flags a raw URL form. **Confirmed net-new → BUILD.**
- **Delta 1 (explicit 5-surface ref-permitted allowlist) → PARTIAL.** `universal-vs-release-pipeline-split-rule.md:41` names **4 of 5** surfaces (Release Outcome Statement / RELEASE_LOG / RELEASE_INDEX / RELEASE_DIGEST / RELEASE_NOTES); **CHANGELOG.md is absent** (grep count 0). **Sharpened:** CHANGELOG is top-level → outside the `reference-durability` `is_durable()` scope AND outside the `release/releases/*` exemption the `repo-integrity` gates carry. **Confirmed partial → formalize the named allowlist + resolve the CHANGELOG seam.**

**Gate decision — enumerated options:**
- **(1) Full-delta build** — build Delta 2 detector + formalize Delta 1 allowlist + re-implement Delta 3 enforcement. *Rejected:* Delta 3 re-implementation duplicates live, working enforcement (R2 HIGH) — wasteful and a drift risk (two Class-V detectors).
- **(2) Delta-2-primary build [RECOMMENDED]** — build the net-new raw-URL detector (Delta 2) in the CI/hook layer with the tracking-surface + CHANGELOG exemption; formalize the named 5-surface allowlist incl. CHANGELOG (Delta 1); fold Delta 3 as **verify-only** with R3-evidence citing the live `CUTOVER_RE` lines in hook + CI. Ships warn-mode initial.
- **(3) Verify-and-close-if-fully-covered** — verify #311 as already-satisfied (mark #311 as closed only if fully covered). *Rejected:* Delta 2 is genuinely net-new (no raw-URL detector exists) and Delta 1's CHANGELOG seam is unresolved — the issue is NOT fully covered, so a verify-only closure would leave the named-allowlist AC and the raw-URL-prohibition AC unmet.
**Recommendation:** **Option (2) Delta-2-primary build.** It is the precise delta over shipped enforcement: build what is genuinely missing (raw-URL detector + named allowlist + CHANGELOG seam), verify what already ships (Class V), and re-author nothing the durability standard already delivers. Pattern cited: `feedback_release_ops_intake_pre_rendered_artifacts.md` (N=2, confirmed) — when a finding is substantially pre-shipped, invert to verify + evidence + closure routing for the covered part; never re-author. R3 evidence is still required for the verify-only Delta 3 (cite the detector lines at Stage 7/8).
**Blocks:** #311 Stage 5 Solutioning scope (the spec opens with the reconciliation table, not a from-scratch standard); #311 Engineering scope; #311 AC disposition (which ACs are build-verified vs evidence-folded).
**Upstream compatibility:** N/A — the #311 deltas modify CI/hook enforcement + a governance standard, not skill-authoring surface (no frontmatter/file-layout/naming change to skills). Upstream compatibility check does not apply.
**Reversibility / Confidence:** MODERATE / HIGH. MODERATE because it adds a new CI detector + a governance standard (days to unwind via PR revert; the new detector ships warn-mode so there is no enforce-state to unwind mid-window). HIGH confidence in the option — all three deltas were independently verified against canonical source.

---

*Stage 4 planning spoke output. Model: Opus 4.8 (1M context). All load-bearing hub pre-verification findings independently re-confirmed against canonical source at baseline `origin/main` = `38f97d31` (v1.11). Version assignment (v1.12 expected) is an operator Phase-B decision — presented as proposal, not hardcoded. No calendar dates estimated (single-operator PMO). Per-issue closure phrasing uses safe form throughout (`mark #N as closed at Stage 13`).*

