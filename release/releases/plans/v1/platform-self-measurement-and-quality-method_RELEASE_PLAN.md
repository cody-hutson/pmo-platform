<!-- reference-durability: allow-issue-ref -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — platform-self-measurement-and-quality-method

**Milestone:** platform-self-measurement-and-quality-method · **Release Class:** novel · **Topology:** D-C SINGLE
**Issues:** #359 (failure-mode-standard target-range amend) + #358 (pmo-qa-auditor platform-health mode) + #754 (RCA method + migration playbook) + #125 (verified triage)
**Stage 4 source:** the Release Planning sub-task comment (Stage 4 spoke output on #776), reproduced verbatim below as the committed release plan (Engineering Commit 0).

---

## Stage 4 Release Planning — platform-self-measurement-and-quality-method

> Stage 4 release-scoped spoke (Release Manager persona, Skills-Map §13 Mode 1). Read-only — no file writes, no commits. Sole side effects: this comment + closing #776. Baseline SHA `a87b994` (HEAD at audit-start, 2026-06-13). All factual claims carry evidence-quality labels; audit-snapshot reconciliations carry `[VERIFIED …]` trailers per decision-discipline.md § 2.1.1.
>
> **Platform-config fallback (LOGGED):** No `platform-config.toml` / `operator.toml` exists in the repo. Per Procedure 0 single-resolution contract, this spoke falls back to documented stage defaults: `bundle_doctrine_frame` = vertical-capability-slice (default); `release_size_target_pts` = unset (single-operator PMO — sequence not points, per Stage 4 §8); `default_release_class` = derived from trigger conditions (no config override). Recorded here so downstream stages know the values were defaulted, not config-resolved.

### Summary (30 seconds)

Four OPEN issues, all genuine net-new work (Procedure 0a verification: **none already shipped** — every issue's ACs map to gaps live on `main` at `a87b994`). The release is a **mixed bundle**: three authoring efforts (#358 pmo-qa-auditor platform-health mode; #359 failure-mode-standard target-range amend; #754 RCA method + migration playbook) plus one **analysis-class** deliverable (#125 — *verified triage* of a 34-day-stale audit, NOT a restatement).

Headline verification results:
- **#125 is the load-bearing risk.** Of its 5 findings, **F2 is RESOLVED** (4 link-check CI workflows now exist), **F4 is RESOLVED-by-pruning** (calibration-data.md / iteration-log.md deleted tree-wide), **F1 is PARTIALLY-RESOLVED** (eval dirs 2→4; `evals/results/` still absent), **F3 is UNVERIFIABLE-HERE** (runtime hook `.mode` lives install-root, not in repo), **F5 is UNVERIFIED→install-root** (Check 2 logic is a pure install-path presence check; verdict depends on operator's install root). Net: only **F1 (residual) + F5 (triage-which)** plausibly survive as in-release proposals; F2/F4 must NOT be re-filed.
- **#359's cutover risk is MOOT.** v1.10 `failure-mode-coverage-completion` SHIPPED (tag v1.10, PR #658, 2026-06-12) and **all 5 per-category remediation issues (#6/#138/#139/#140/#141) are CLOSED**. The risk #359's body names (remediation reviewed against old floor while #359 adds new target-range) cannot occur — remediation is already merged.
- **#358's predecessor inputs all EXIST** at their re-homed paths; the §4 placeholder is live; the mode is genuinely unbuilt.
- **D-Version stale-by-one:** the chip's "next = v1.14" is wrong — **v1.14 already shipped** (tag present, PR #775/#777, 2026-06-13). Next number is **v1.15** [INFERRED] — and per the platform's own collision history (#769), the number should be claimed at Stage 12, not pinned at Stage 4.

**Proposed Release Class: `novel`** (introduces ≥1 new reference doc/skill-mode + ≥1 D-class decision). **Capacity read: at the upper edge of a single coherent release** — recommend proceeding as one release with #754 split into two engineering efforts and #125 scoped to verified-live findings only.

---

### Dependency Graph

Directional (`A → B` = A should land before B). Cross-issue and cross-release edges:

```
CROSS-RELEASE (already satisfied — verified):
  v1.10 failure-mode-coverage-completion (#6/#138/#139/#140/#141 CLOSED) ──✓──> #359
  v11.01f (platform-health-audit-framework.md + anthropic-base-vs-build-registry.md, re-homed) ──✓──> #358
  #412 intake-desk (CLOSED/shipped) ──✓──> #754

WITHIN-RELEASE (this milestone):
  #359 (amend failure-mode-standard target-range) ──soft──> [pmo-qa-auditor G7 coaching surface]
        └─ soft edge only: #359 AC6 wants pmo-skill-editor to cite the new range; #358 touches
           pmo-qa-auditor SKILL.md. Different skills, different sections — NOT a hard edge.
  #125 (verified triage) ──informs──> future-milestone proposals (F1 residual, F5)
        └─ #125's OUTPUT is triage/sequencing; it does not block or depend on #358/#359/#754.
  #754 (RCA method + migration playbook) ── independent ── (no producer/consumer edge to the other 3)
```

**No hard (producer→consumer) edges exist among the four issues.** [INFERRED from file-change analysis] The only intra-bundle relationship is a *soft* one: #359 amends a skill-authoring standard whose coaching surface (pmo-skill-editor) is adjacent to #358's pmo-qa-auditor G7 work, but they edit different files. Sequencing is therefore driven by *risk-minimization and review-coherence*, not dependency.

`[VERIFIED 2026-06-13: gh issue list --milestone … --search "failure mode coverage" --state all → #6/#138/#139/#140/#141 all CLOSED; tag v1.10 present; PR #658 merged]`
`[VERIFIED 2026-06-13: test -f release/references/protocols/platform-health-audit-framework.md && test -f core/specs/anthropic-base-vs-build-registry.md → both EXIST]`
`[VERIFIED 2026-06-13: gh issue view 412 → state=CLOSED]`

---

### Implementation Sequence

Dependency-ordered (no hard edges → ordered by *substrate-first* + *blast-radius-ascending* + review coherence):

1. **#359** — Amend `core/specs/failure-mode-standard.md` § Minimum Count with the 6–10 target-range addendum. **First** because it is a single-file doc edit, sets clearer expectations, and its only dependency (v1.10 remediation) is already closed — lowest risk, fastest to land, unblocks the soft coaching-surface edge for #358.
2. **#358** — Integrate `platform-health` mode into pmo-qa-auditor + resolve the deferred v11.01f body ACs. **Second** because it is the highest-blast-radius issue (7 files incl. a new analysis folder + a scheduled-task registration) and benefits from #359's amended standard being already live (G7 coaching coherence).
3. **#754** — Codify the RCA method + migration playbook (recommend **split** — see Merge/Split). **Third**; independent, authoring-class, two new docs + intake-desk handoff wiring. Sequence after #358 so pmo-qa-auditor/OPERATIONS.md churn from #358 settles before #754 touches adjacent `core/disciplines/` and `core/` how-to surfaces.
4. **#125** — Produce the *verified* triage deliverable (analysis-class). **Last**; its input is the now-current platform state (which #358/#359/#754 partially change), so triaging after the authoring work lands keeps the finding-disposition current. **#125 does not gate or get gated by the other three** — it could equally run first; placed last so its "current platform quality posture" snapshot reflects this release's own contributions.

> Sequencing is a **recommendation** (Tier 2). The absence of hard edges means the operator MAY reorder freely; #359-first / #125-last is the review-coherence optimum, not a constraint.

---

### Stage Applicability Matrix

Per-issue Stages 5–13 (Stage 4 already complete at release level). Default = all apply; SKIP justified explicitly.

| Issue | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9 PlanReview | S10–11 | S12 Execute | S13 Close | Notes |
|---|---|---|---|---|---|---|---|---|---|
| **#358** | **APPLY** | APPLY | APPLY | APPLY | APPLY (Deep) | compress (git-native) | APPLY (deploy: pmo-qa-auditor skill + package rebuild) | APPLY | Skill-authoring surface (SKILL.md mode) + new protocol section + scheduled-task registration → design uncertainty real. S5 designs mode contract, registry-header rubric/weighting, audit-folder shape. **Upstream-compat REQUIRED at S5** (touches skill structure). |
| **#359** | **APPLY** | APPLY | APPLY | APPLY | APPLY (Standard) | compress | APPLY (doc-only; **deploy no-op** — no skill/package/harness change) | APPLY | Issue body + #359 Notes both state "Stage 5 Solutioning likely activates" (skill-authoring *standard* change). S5 resolves the distribution-forecast buckets + cutover framing (now simplified since remediation is closed). |
| **#754** | **APPLY** (ADR-011 Variant candidate too) | APPLY | APPLY | APPLY | APPLY (Deep) | compress | APPLY (doc-only; deploy no-op unless authored as a skill) | APPLY | Authors NEW discipline docs (RCA method + migration playbook) → S5 designs method structure, invocation points, intake-desk handoff contract. If authored as a *skill* (AC offers "focused skill" option), S12 gains a deploy step. |
| **#125** | **ADR-011 Stage 5 Variant (Research-Methodology Design)** | APPLY (produce triage artifact) | **SKIP** | **SKIP** | APPLY (Standard) | compress | APPLY (analysis artifact; **deploy no-op**) | APPLY | Analysis-class: no functional/runtime change → S7 DevTest + S8 QA SKIP (no code/behavior to test; the deliverable is a triage document reviewed at S9). S5 runs as the **Research-Methodology Design variant** (ADR-011) — design the triage method + finding-disposition rubric, not a code design. |

**Rationale for #125 S7/S8 SKIP:** Stages 7–8 verify functional/behavioral impact; #125 produces a sequencing/triage deliverable with zero runtime surface. The verification that matters for #125 is *evidence quality of the triage* — handled at S9 Plan Review, not DevTest/QA. [INFERRED per Procedure 1 Step 2 "Skip Dev Testing / QA only if the change has no functional impact."]

**Rationale for all-APPLY S5:** Three of four issues touch skill-authoring or new-doc-authoring surface, and the milestone proposes Release Class `novel` (Stage 5 Activation bias = ALL). Even #359 (single-file) carries a self-declared S5-activation note in its own body.

---

### Contention Map

**Within-release file contention:** Effectively **none.** The four issues touch disjoint file sets, with two near-adjacencies (not collisions):
- #358 edits `core/skills/pmo-qa-auditor/SKILL.md`; #359 edits `core/specs/failure-mode-standard.md` and (AC6) references pmo-skill-editor — **different files**.
- #358 and #754 both touch `core/` discipline/governance surfaces (#358 → `core/governance/OPERATIONS.md`, `core/rules/operations-bridge.md`; #754 → `core/disciplines/` new doc). **No shared file path.**
- The single nominal overlap candidate is `core/governance/OPERATIONS.md`: #358 ADDS a "Platform Health Audit Protocol" section; no other issue edits OPERATIONS.md. **Single-writer → no contention.**

**Cross-PR contention (A4 extension, baseline-pinned per the audit-baseline-empty-target discipline):**
- **Baseline:** audit-start SHA `a87b994` (HEAD). **Open PRs at baseline = 0.** Last-8-merged window: #777/#775/#771/#770/#768/#767/#766/#759 (all 2026-06-13, all v1.12–v1.14 close-out + adapter-config-foundation).
- Because the open-PR population is **observably empty** at the baseline SHA, the default-to-zero "no cross-PR contention" classification is **not load-bearing on its own** — pinned here so a PR opening between Stage 4 and Stage 6 doesn't silently invalidate it. **Re-check open PRs at Stage 7/8 entry and at Stage 9 Phase A6.5** (the mid-pipeline divergence checkpoint) before relying on this.
- `[VERIFIED 2026-06-13: gh pr list --state open → 0 PRs at a87b994]`

#### File Change Matrix (machine-readable — one path per line for deterministic Stage 7/8/9 extraction)

```
core/specs/failure-mode-standard.md
core/skills/pmo-qa-auditor/SKILL.md
core/governance/OPERATIONS.md
core/specs/anthropic-base-vs-build-registry.md
release/references/protocols/platform-health-audit-framework.md
core/rules/operations-bridge.md
core/skills/pmo-qa-auditor/references/
core/disciplines/
core/references/how-to/
operations/skills/intake-desk/SKILL.md
packages/pmo-qa-auditor.skill
```

> **Matrix notes (not part of the machine-readable list):**
> - `core/skills/pmo-qa-auditor/references/` — #358 may add a platform-health mode reference; exact filename set at S5.
> - `core/disciplines/` (#754 RCA method) and `core/references/how-to/` (#754 migration playbook) — **the AC's proposed `core/references/how-to/` path does NOT exist yet** as a directory; S5 must confirm the home (the AC offers `core/disciplines/` OR `operations/skills/` for RCA, and `core/reference[s]/how-to/` OR a knowledge doc for the playbook). `[VERIFIED 2026-06-13: find core -type d -name 'how-to' → no core/references/how-to/ exists; core/disciplines/ exists]`
> - `operations/skills/intake-desk/SKILL.md` — #754 wires the handoff (intake-desk "captures and hands off, does not perform RCA/migration inline"). **NOTE: intake-desk SKILL.md is a migrated skill — edits MUST route through `pmo-skill-editor` (block-skill-direct-edit hook).** Same applies to pmo-qa-auditor SKILL.md (#358).
> - `packages/pmo-qa-auditor.skill` — MANDATORY rebuild at S12 after #358's SKILL.md edit (Check 7 package-freshness). #359/#754/#125 add **no** package rebuilds unless #754 ships as a skill.
> - A new analysis folder (#358 inaugural platform-health audit) targets the operator-instance analysis path — the issue body's `pmo-platform/analysis/…` path is **pre-restructure**; current home is `<OPERATOR_INSTANCE_ANALYSIS_PATH>/platform-health-YYYY-MM-DD/` per the analysis-folder convention. It is operator-instance (git-ignored), so it is **excluded from the tracked-file matrix above** by design.
> - The scheduled-task registration (#358 AC2, via `mcp__scheduled-tasks`) is a runtime registration, **not a tracked repo file** — excluded from the matrix.

---

### Risk Register

| ID | Risk | Type | Issue(s) | Reversibility | Mitigation |
|---|---|---|---|---|---|
| R1 | **#125 findings re-filed despite being already resolved** (F2 link-CI, F4 calibration prune) → duplicate issues, eroded operator trust | Scope / duplicate-discipline | #125 | CHEAP | Verified triage below classifies each finding; F2/F4 dispositioned RESOLVED with evidence; only F1-residual + F5 eligible for proposal. Enforces the issue-creation duplicate-discipline. |
| R2 | **F1 / F5 work duplicates existing open issues** (Epic #325 regression-suite, #199 eval extensions, #7 DORA-in-calibration) | Scope / duplicate-discipline | #125 | CHEAP | Triage routes F1-residual to **enrich #325/#199** (comment + thin pointer), NOT a new issue. F5 (Check 2 triage) is a deploy.sh concern — candidate for `deploy-sh-script-health` milestone, not this release. |
| R3 | **#754 over-scoped as one engineering effort** — RCA method and migration playbook are independent deliverables with different homes, different consumers | Scope / rollback | #754 | MODERATE | **Split into two S6 efforts** (RCA / migration-playbook) under one milestone — see Merge/Split. Each is independently revertable; bundling them risks a half-done revert. |
| R4 | **#358 scheduled-task registration is non-git runtime state** — cannot be PR-reverted; S12 deploy step is MCP-side | Rollback complexity | #358 | MODERATE | Issue body already flags removability via `mcp__scheduled-tasks`. S12 records the registration as a deploy-log line; rollback = explicit task-deregister, not `git revert`. Flag at S9. |
| R5 | **pmo-qa-auditor + intake-desk SKILL.md edits bypass pmo-skill-editor** → block-skill-direct-edit hook blocks at edit-time | Process / contention | #358, #754 | CHEAP | S6 chips MUST route both SKILL.md edits through pmo-skill-editor (Mode A). Version field bump required. Surface in S6 chip prompts. |
| R6 | **#754 target path `core/references/how-to/` does not exist** — AC names a non-existent home | Scope ambiguity | #754 | CHEAP | S5 Solutioning resolves the home (create the dir, or use `core/disciplines/` + an existing how-to home). G-PL1 AC-currency: this is a CURRENCY-MISMATCH → Tier 1 [ADJUST] the AC at S5. |
| R7 | **Cross-PR contention false-negative** — open-PR population empty at baseline; a concurrent release could claim shared files (or the version number) mid-pipeline | Contention / dependency | all | MODERATE | Baseline pinned (R-pin above). Re-check at S7/S8 entry + S9 A6.5. **Version-collision specifically:** claim vX.Y at S12 per #769, not at S4. |
| R8 | **#359 distribution-forecast buckets push utility skills to over-author** (6–10 applied to wrong bucket) | Scope (content) | #359 | CHEAP | #359 body Mitigation already specifies the 4-bucket revised forecast (high 6–10 / med 4–6 / utility 3–4 / authoring-infra 3–4). S5 enforces bucket-appropriate framing. |

**Per-issue reversibility tier (summary):** #358 **MODERATE** (SKILL.md + OPERATIONS.md PR-revertable; scheduled-task is MCP-side removal — the non-git component sets the tier). #359 **CHEAP** (single-file doc edit, additive, `git revert`). #754 **MODERATE** (two new docs + skill-handoff wiring; if shipped as a skill, deploy adds re-sync surface). #125 **CHEAP** (analysis artifact; triage is informational, no runtime change).

---

### #125 Findings — Verified Triage

Per the Procedure 0a mandate, each finding re-verified against live state at `a87b994` (34 days after the 2026-05-10 audit). **#125's deliverable is this verified triage — not a restatement of the stale snapshot.**

**F1 — Eval coverage near-zero — verdict: PARTIALLY-RESOLVED**
2026-05-10 claimed 2/22 skills with eval files, 0 with `evals/results/` entries. Now **4 skills** carry `evals/` dirs (eval-writer, prompt-builder, intake-desk, release-planner); `evals/results/` **does not exist** anywhere in the tree. The *measurement-data* gap (empty results) persists; the *coverage* gap halved. **Disposition: enrich existing owner, do NOT re-file.** Live homes already exist — Epic #325 (regression & eval suite, milestone=none, roadmap-governed), #199 (eval framework extensions incl. calibration aggregation), #17 (skill-compliance trigger-rate measurement). Route the F1-residual ("evals/results still empty; eval coverage 4/22") as a **comment on #325** + thin pointer, NOT a new issue.
`[VERIFIED 2026-06-13: find {core,release,operations}/skills -type d -name evals → 4 dirs (eval-writer, prompt-builder, intake-desk, release-planner)]`
`[VERIFIED 2026-06-13: find . -type d -name results | grep eval → 0 results dirs (core/evals/results, release/evals/results absent)]`
`[VERIFIED 2026-06-13: gh issue list --search "eval coverage OR calibration" --state all → #325/#199/#17/#7 OPEN and topical]`

**F2 — Broken markdown links across governance + reference — verdict: RESOLVED (largely)**
2026-05-10 claimed 93 broken intra-repo links + "deploy check has no link-resolution assertion." Now **four link-check CI workflows exist** (`link-check.yml`, `release-link-check.yml`, `reference-durability.yml`, `operator-memory-ref.yml`) AND `deploy.sh` Check 14 (doc-link maintenance) is implemented and invokes the shared `check-doc-links.py` primitive. The exact gap F2 named — "no link-resolution assertion at deploy" — is closed. Residual broken-link *backlog drainage* is tracked separately (`doc-link-drift-drainage` milestone, 4 open). **Disposition: do NOT re-file. The mechanism gap is closed by cross-reference-integrity-ci / corpus-durability-enforcement (both VERIFIED shipped 2026-06-13).**
`[VERIFIED 2026-06-13: ls .github/workflows/ → link-check.yml, release-link-check.yml, reference-durability.yml, operator-memory-ref.yml all present]`
`[VERIFIED 2026-06-13: grep -n "Check 14" core/deploy/deploy.sh → Check 14 doc-link maintenance implemented, invokes check-doc-links.py]`
`[VERIFIED 2026-06-13: git log --since=2026-05-10 -- core/deploy/tools/check-doc-links.py → multiple commits (af69c57, 8685dbc, 29ad21e …) post-audit]`

**F3 — Warn-mode shakedown without transition date — verdict: UNVERIFIABLE-HERE (install-root check)**
2026-05-10 cited `.claude/hooks/*.jsonl` warn-log volumes (832 MCP entries) and `.claude/hooks/.mode` still at `warn`. The **runtime hook state (`.mode` + warn-log JSONL) lives in the install-root `.claude/hooks/`, NOT in the repo tree** — the repo carries hook *source* at `core/hooks/`, not the runtime mode file. This finding cannot be verified from the repository; it is an **install-root operational check**, not a corpus gap. **Disposition: route to the operator as an install-root flip-readiness check** (per bypass-mode-readiness.md Shakedown→Enforce Checklist), NOT an in-release proposal against tracked corpus. The warn→enforce flip is a runtime `.mode` edit, governed but not a repo change.
`[VERIFIED 2026-06-13: find . -name '.mode' → no .claude/hooks/.mode in repo tree; core/hooks/ exists (source only)]`

**F4 — Calibration + iteration logs instrumentation-only — verdict: RESOLVED-by-pruning**
2026-05-10 cited `pmo-platform/engineering/evals/results/calibration-data.md` (4 rows, Accuracy blank) and `iteration-log.md` (0 rows), and named "prune the files" as one decision option. Both files **no longer exist anywhere in the tree** — the restructure/pruning that the finding itself proposed has occurred. The empty-instrumentation governance-theater risk F4 named is gone *because the empty files were removed*. **Disposition: do NOT re-file as a gap.** The *forward* question — "where does calibration data live now / should DORA telemetry be generated" — is a distinct, already-owned concern (#7 DORA telemetry in calibration-data.md schema; #199 calibration aggregation; #758 codify `OPERATOR_INSTANCE_EVALS_RESULTS_PATH`). Surface to operator only as confirmation that F4 is closed-by-pruning.
`[VERIFIED 2026-06-13: find . -name 'calibration-data.md' -o -name 'iteration-log.md' → 0 matches tree-wide]`
`[VERIFIED 2026-06-13: gh issue list --search "calibration" --state all → #7/#199/#758 OPEN cover the forward concern]`

**F5 — Drift check reports all 22 .skill packages "not installed" — verdict: UNVERIFIED → install-root-dependent (Check 2 logic confirmed source-side correct)**
2026-05-10 claimed Check 2 reports DRIFT on every package; Check 7 reports OK (source-to-package sync current). 22 `.skill` packages **are present** in `packages/`. Check 2 logic (deploy.sh L1369–1387) diffs `packages/*.skill` against `$(dirname "$INSTALL_PATH")/packages/` — a **pure install-path presence + byte-identity check**. Whether it false-positives depends entirely on whether the operator's *install root* has the packages — **not determinable from the repo tree**. The skill-deployment.md doc records that explicit-name `./deploy.sh --deploy <skill>` now installs each named skill's package (narrowing the historical false-positive surface), but the "all 22 not installed" symptom requires `./deploy.sh --check` against the live install root to confirm/refute. **Disposition: route F5 as a `deploy-sh-script-health`-milestone triage item** ("confirm whether Check 2 false-positive persists vs 22 real install gaps — run `./deploy.sh --check`"), NOT this release. Needs install-root execution the spoke cannot perform read-only from corpus.
`[VERIFIED 2026-06-13: ls packages/*.skill | wc -l → 22 packages present]`
`[VERIFIED 2026-06-13: deploy.sh L1369-1387 → Check 2 = install-path presence/byte-identity diff; no repo-side determination possible]`
`[VERIFIED 2026-06-13: git log --since=2026-05-10 -- core/deploy/deploy.sh → only a stale-comment fix (433025f) touched Check-area; no Check-2 install-detection logic change]`

**#125 triage net:** 2 RESOLVED (F2, F4) · 1 PARTIALLY-RESOLVED (F1) · 1 UNVERIFIABLE-HERE/install-root (F3) · 1 install-root-dependent (F5). **Zero findings warrant a fresh in-this-release proposal.** F1-residual → enrich #325/#199. F3 → operator install-root flip check. F5 → `deploy-sh-script-health` triage item. F2/F4 → closed, surface evidence only. This is the disposition the milestone's "triage into proposals + sequencing" goal resolves to once verified against current state.

---

### Operator Decisions

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke trigger-condition analysis per release-class-taxonomy.md § Class Enum.
**Gate decision:** Choose (A) routine · (B) **novel** · (C) cross-cutting · (D) hotfix.
**Blocks:** Stage 3 Phase B3 milestone-description `## Release Class` section; downstream per-class differentiation posture (engagement density, S9 review depth).
**Trigger evidence (novel fires):** novel-(a) **≥1 new reference doc/schema/skill** — #754 authors a NEW RCA method doc + NEW migration playbook; #358 adds a NEW pmo-qa-auditor *mode* + NEW OPERATIONS.md protocol section. novel-(b) **≥1 D-class decision in the plan** — this plan carries D-ReleaseClass, D-C, D-Version (+ #754 split is a D-candidate). **cross-cutting does NOT fire:** File Change Matrix touches **0** `pipeline/stage-*.md` files and **<3** of the cross-cutting governance set (only OPERATIONS.md among {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, …}); in-bundle hard edges = 0 (<3). **hotfix excluded:** no P1/P2 deployed-release defect; introduces new protocol (anti-pattern disqualifier).
**Differentiation posture (novel):** Engagement density = **Standard** · Stage 9 depth = **Deep** · Stage 5 activation bias = **ALL** · Stage 13 outcome-window = **30-day**.
**Upstream compatibility:** N/A — Release Class is PMO-platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable later per release-class-taxonomy.md Re-Classification Protocol; cheaper-to-stricter is CHEAP).
**Recommendation: (B) novel.**

#### D-C: Branch Topology — single-branch vs per-issue branches/PRs?
**Gate input:** 4-issue bundle; intra-bundle hard-edge count = 0; recent-release precedent (v1.10–v1.14 all D-C SINGLE per RELEASE_LOG).
**Gate decision:** **SINGLE-branch** (default — one `release/<slug>` branch, plan as Engineering Commit 0, sequential per-issue commits) vs **OPTION-A** (per-issue branches + per-issue PRs + a Stage-4 release-plan chore PR).
**Blocks:** Procedure 1 scaffolding shape; where the plan file is committed; per-issue merge cadence.
**Recommendation: SINGLE-branch.** Rationale: (1) **zero hard edges** means no early-merge-to-unblock benefit that OPTION-A buys; (2) the bundle is small (4 issues) and every recent release (v1.10–v1.14) ran D-C SINGLE successfully; (3) #125 is analysis-class with no deploy and #359 is doc-only — splitting them into separate PRs adds ceremony without isolation value; (4) the one genuine deploy (#358 pmo-qa-auditor) is naturally the last skill-touching commit and gates cleanly at S12.
**Blast radius:** SINGLE concentrates all four issues behind one merge — a release-wide `git revert -m 1` reverts everything (acceptable here: only #358 has a non-git component, handled separately). OPTION-A would isolate per-issue reverts but at 3× chore-PR overhead (#769 collision-surface multiplies with more PRs).
**Upstream compatibility:** N/A — branch topology does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** SINGLE is MODERATE reversibility (whole-release revert) / HIGH confidence; switching to OPTION-A mid-release is CHEAP before scaffolding, EXPENSIVE after.

#### D-Version: What version identity does this release carry?
**Gate input:** Milestone is slug-named (`platform-self-measurement-and-quality-method`) with **no version stamp** anywhere in `release/releases/` or CHANGELOG. Tag lineage is the v1.NN line. **The chip prompt's "latest VERIFIED = v1.13 → next v1.14" is STALE:** v1.14 already shipped.
**Gate decision:** (1) numbered **v1.15** vs version-less slug-only identity; (2) WHEN to claim the number.
**Audit-snapshot reconciliation (decision-discipline.md § 2.1.1 — the chip's version claim is itself a stale snapshot):**
`[VERIFIED 2026-06-13: git tag | tail → v1.10 … v1.14 present (v1.14 IS the latest tag, not v1.13)]`
`[VERIFIED 2026-06-13: gh pr list --state merged --limit 8 → #775/#777 = "chore(v1.14): Stage 12/13", merged 2026-06-13]`
`[VERIFIED 2026-06-13: grep "platform-self-measurement" release/releases/ CHANGELOG.md → 0 hits (no version pinned yet)]`
So the next number is **v1.15** [INFERRED], not v1.14.
**Recommendation:** Carry the **milestone slug as the working identity** through the pipeline (branch `release/v1.15-platform-self-measurement` or slug-only `release/platform-self-measurement-and-quality-method`); **assign the numeric v1.15 tag at Stage 12**, not at Stage 4. Rationale: the RELEASE_LOG documents **two consecutive mid-pipeline version collisions** (v1.12→v1.13, v1.13→v1.14) where concurrent releases claimed the lower number first, and **#769 was filed at v1.13 close specifically to require a "is this number still unclaimed" check at Stage 12/A6.5**. Pinning v1.15 at Stage 4 re-creates exactly that collision risk. Operator assigns the final number; the spoke recommends **v1.15** as the current-best candidate **subject to a fresh unclaimed-check at S12**.
**Upstream compatibility:** N/A — version identity does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** Deferring the number to S12 = CHEAP / HIGH (the slug is collision-proof; the number is claimed once, late, after a check).

> **Upstream-compatibility note for the skill-authoring D-decisions deferred to Stage 5:** #358 (pmo-qa-auditor `platform-health` mode — a new mode + possible new frontmatter/reference structure) and #359 (failure-mode-standard amendment — skill-authoring *discipline*) BOTH touch skill-authoring surface and will require the **REQUIRED Upstream-compatibility subsection at their Stage 5 D-decisions** per the D-Gate Template. Preliminary check (this spoke): `anthropic-skills:skill-creator` defines **no failure-mode authoring discipline and no `platform-health` audit-mode convention** — these are PMO-extension surfaces, so no conflict is anticipated (do NOT emit the literal `**CONFLICT.**` string — none exists). #359's own body already records this verdict from v11.01c ("PMO-extension surface — skill-creator defines no failure-mode authoring discipline"). Stage 5 must still perform and date the check per the D-Gate evidence-format rule, and consult `core/standards/upstream-reference-catalog.md` for the `skill-md-frontmatter` entry if #358's mode adds frontmatter.

---

### Recommendations

**1. #754 — SPLIT into two engineering efforts (RCA / migration-playbook) under one milestone.** [RECOMMENDED]
The issue was "bundled WHOLE by operator scope-commit," so the *milestone scope* stays whole — but the two deliverables are independent (different homes: RCA → `core/disciplines/`; playbook → a `core/` how-to/knowledge home; different consumers; different content provenance — #428 vs #429). Plan **both halves** (do NOT drop the migration-playbook half), but as **two S6 commits / two S5 design passes** so each is independently authored, reviewed, and revertable. A single combined effort risks a half-done revert (R3) and conflates two design problems. Decision-discipline: this is a *scope-split D-candidate* — surface as `D-754-Split` at Stage 5 if the operator wants it formalized; otherwise the plan treats it as two sequenced commits on the single release branch.

**2. #125 — produce the verified triage as the deliverable; route residuals, do NOT re-file.** [RECOMMENDED]
The verified triage above IS #125's S6 output (a finding-disposition artifact). Concrete routing: **F1-residual → comment on Epic #325 + thin pointer** (eval coverage 4/22, evals/results still empty); **F3 → operator install-root flip-readiness check** (not a corpus change); **F5 → `deploy-sh-script-health` milestone triage item** (run `./deploy.sh --check` against live install root); **F2 + F4 → surface as closed with evidence** (no action). This honors the issue-creation duplicate-discipline (enrich existing owners — #325/#199/#7 already own the live concerns) and the verify-before-recommend discipline (no stale re-recommendation). **#125 itself marks as closed at Stage 13** once the triage artifact + routing land.

**3. Capacity / over-scope read: at the upper edge — proceed as ONE release with the two adjustments above.** [INFERRED]
Four issues, but the *effective* engineering load is: 1 single-file doc edit (#359), 1 multi-file skill+protocol build (#358, the heavy one), 2 new-doc authoring passes (#754 split), 1 analysis/triage artifact (#125). That is a coherent `novel` release, comparable to recent 3–5 issue releases (v1.10 = 5 issues, v1.13 = 3). **Not over-scoped** *provided* #125 is scoped to verified-live findings only (else it balloons into re-litigating 5 stale findings) and #754 is split (else one effort carries two unrelated designs). No recommendation to defer any issue out of the milestone.

**4. Pre-flight obligations to carry into Stage 5/6 (so they aren't rediscovered late):**
- **G-PL1 AC-currency [ADJUST] at S5:** #754 AC names `core/references/how-to/` which does not exist (R6) → adjust the AC to a confirmed home. #358's issue-body paths are pre-restructure (`pmo-platform/analysis/…`, `pmo-platform/skills/…`) — already re-homed in the body's own preamble; S5 confirms current paths.
- **Skill-edit routing (R5):** #358 (pmo-qa-auditor SKILL.md) and #754 (intake-desk SKILL.md handoff wiring) MUST route through `pmo-skill-editor` Mode A — surface in the S6 chip prompts; both are migrated skills behind block-skill-direct-edit.
- **#358 non-git deploy surface (R4):** the scheduled-task registration is MCP-side; S12 deploy-log records it; rollback ≠ `git revert`.
- **Version-collision guard (R7/#769):** claim vX.Y at S12 after a fresh unclaimed-check, not at S4.
- **Cross-PR re-check (R7):** open-PR population is empty at baseline `a87b994` — re-verify at S7/S8 entry + S9 A6.5 before relying on "no cross-PR contention."

**5. Out-of-scope discoveries (noted, NOT acted on per scope guard):**
- #358's body surfaces two systematic Stage-6 self-verification gaps (markdown link-path *resolution* check + section-anchor citation check at `deploy.sh --check`). The link-resolution half is now **largely addressed by Check 14 + link-check.yml** (see F2); the **section-anchor citation check remains a gap** — candidate for a separate improvement issue (the dead-file-reference gate's anchor checking is warn-mode-initial per repo-integrity.yml, so partial coverage exists). Do NOT fold into this release; file separately if the operator wants it.
- #358's auxiliary follow-up (an `implementer` skill entry in the Cowork install not present in source roster) is a roster-reconciliation item — out of scope; file separately if desired.

> **Decision-discipline pattern-cache scan (Mechanism 3, applied to this Stage 4 decision set):** Confirmed patterns checked and cited — the verify-before-recommend discipline (drove the #125 5-finding verification + the D-Version stale-snapshot catch); the intake-pre-rendered-artifacts discipline (the verification-first posture; here it INVERTS — work is genuinely live, so authoring proceeds, NOT verification-only); the issue-creation duplicate-discipline (drove the "enrich #325/#199, don't re-file F1" routing); the audit-baseline-empty-target discipline (drove the Cross-PR baseline-pin given 0 open PRs); the umbrellas-not-milestoned discipline (confirmed #325 correctly milestone=none — route F1 there by comment, don't milestone the umbrella). No new observation to log (no operator correction occurred in this spoke).
