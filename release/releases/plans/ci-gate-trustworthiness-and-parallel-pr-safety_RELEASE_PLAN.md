<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
## Stage 4 Release Planning — 36-ci-gate-trustworthiness-and-parallel-pr-safety

### Summary (30 seconds)
Four issues in Milestone #114 (`36-ci-gate-trustworthiness-and-parallel-pr-safety`, project:governance-hygiene). Theme: make `deploy.sh --check` gates trustworthy (assert content not proxy; close detection gaps) and make parallel hook PRs safe (de-monolith `bypass-mode-readiness.md`). The dominant planning fact is **file contention on `core/deploy/deploy.sh`** — three of four issues edit it (#1101 Check 7, #673 Check 6, #18 Check 9), so under single-branch topology Engineering serializes on that file regardless of disjoint check blocks.

Three determinations:
1. **#1101 scope** → **FOLD IN** (4 cards). It is the most on-theme issue (it *is* "gate trustworthiness") and shares the `deploy.sh` contention surface; deferring it would leave the milestone's headline capability half-built. [SOURCE: milestone #114 description records "Cards (3): #18 #90 #673" but `open_issues:4`; #1101 is `status: proposed` while the other three are `status: bundled`.]
2. **#90 gating precondition** → **UNMET → DEFER #90 out of this release** (stays blocked). The Check 25 warn-mode shakedown log and the mode file both live at the operator-instance path and are **not observable in the public repo**; no flip-to-enforce evidence exists in git history; the standard's own §10.5.3 residual register shows the warn-mode discipline is still surfacing deferred findings. Evidence below.
3. **deploy.sh contention** → mapped; drives a strict serial Engineering sequence #1101 → #673 → #18 on the shared file.

**Proposed Release Class: `cross-cutting`** (≥3 in-bundle compositional edges to the same file + new-standard authoring). Effective points land the trimmed 3-issue release inside the 15-25 band.

---

### Dependency Graph

Directional (`A → B` = B depends on A):

```
#1101 (gate-efficacy standard + Check 7 content-hash)
   │  (soft/sequencing edge — establishes the "gates assert content" standard
   │   that #673's Check 6 detection-gap fix and #18's Check 9 update should
   │   conform to; also first-mover on deploy.sh — see Contention Map)
   ├──► #673 (Check 6 detection-gap fix)
   └──► #18  (Check 9 mirror-pair-sync update for directory-vs-single-file shape)

#673 (Check 6 detection-gap fix) ──► #18 (only via deploy.sh file-contention; no logical dep)

#90 (pre-commit-layer spike)
   ╳ BLOCKED-BY (EXTERNAL): Check 25 warn-mode shakedown log must EXIST + warn-window ELAPSED
     → precondition UNMET (see #90 gating verdict) → #90 is NOT dependency-reachable this release
```

Edge classification (Hard-vs-Soft per release-planner dependency-analysis convention):
- **#1101 → #673** and **#1101 → #18**: **soft edges** — no AC of #673/#18 *blocks on* #1101's output; the relationship is (a) conformance (the new gate-efficacy standard is the doctrine #673/#18's checks should satisfy) and (b) file-contention serialization on `deploy.sh`. [INFERRED from #1101 body "every required/advisory gate must assert its claimed invariant" — a doctrine #673/#18 inherit.]
- **#673 ↔ #18**: **file-contention edge only** (both edit `deploy.sh`); no logical dependency — Check 6 (#673) and Check 9 (#18) are disjoint blocks. [SOURCE: `core/deploy/deploy.sh` Check 6 @ line 1590, Check 9 @ line 1758 — separate functions.]
- **#90 external blocked-by**: **hard edge to an off-release precondition** (the Check 25 shakedown). Unmet → #90 cannot start. [SOURCE: #90 body "Blocked by: the Check 25 warn-mode shakedown / flip-to-enforce assessment (G-1 Check-N) — confirm complete before starting"; `core/standards/universal-vs-localized-context.md:154` "G-4 … gated on G-1 shakedown".]

---

### Implementation Sequence

Single-branch topology serializes all `deploy.sh` Engineering. Sequence (3 in-scope issues; #90 deferred out):

1. **#1101 first** — authors the new gate-efficacy standard (`core/standards/<gate-efficacy>.md`) AND lands the Check 7 mtime→content-hash change. First-mover on `deploy.sh` so the standard's "assert content not proxy" doctrine is in the tree before #673/#18's check edits, which should conform to it. Also touches `.github/workflows/` (per-workflow required-vs-advisory declarations) and `core/standards/` — both disjoint from #673/#18, so only the `deploy.sh` half serializes.
2. **#673 second** — Check 6 detection-gap root-cause determination + predicate/iteration/run-context fix. Edits a `deploy.sh` block (Check 6 @ ~line 1590-1645) disjoint from Check 7 and Check 9, so it rebases cleanly on #1101's `deploy.sh` state. **Run the full-catalog dry pass (`./core/deploy/deploy.sh --check`) BEFORE flipping** Check 6 stricter (risk R-3).
3. **#18 third** — the structural change (bypass-mode-readiness.md split D1/D2/D3 + Check 9 mirror-pair-sync update for the directory shape). Sequenced last because it is the largest blast radius (47 inbound cross-references to rewrite + the deployed mirror) and its Check 9 edit lands cleanly on top of #1101+#673's `deploy.sh` state. The D1/D2/D3 choice is an operator decision at Stage 5 (REQUIRED — see Stage Applicability).

Rationale for ordering: dependency direction (#1101 doctrine first) + contention (serialize deploy.sh) + blast-radius-last (#18) all agree. No ordering conflict. [SOURCE: contention map below; `deploy.sh` block line offsets.]

---

### Stage Applicability Matrix

Default = all stages 5-13 apply. Type-aware (per hub determination): #18 type:story (D-class, Stage 5 REQUIRED) · #90 type:spike (decision-only) · #673 type:task (root-cause @ Stage 5) · #1101 type:task (new standard, full pipeline).

| Stage | #1101 (task) | #673 (task) | #18 (story) | #90 (spike) |
|---|---|---|---|---|
| **5 Solutioning** | **APPLY** — standard scope + Check 7 hash mechanism design | **APPLY** — produces the root-cause determination (predicate/iteration/run-context) + fix mechanism (AC#1) | **APPLY (REQUIRED)** — operator renders D1/D2/D3 (genuine D-class decision) | **DEFERRED OUT** (see verdict) — if it were in, Stage 5 would be the recorded decision itself |
| **6 Engineering** | APPLY | APPLY | APPLY | N/A (deferred) |
| **7 Dev Testing** | **APPLY** — controlled-repro: touched-but-unchanged `.skill` must NOT pass (AC#2) | **APPLY** — controlled repro: removing a `version:` field / over-threshold-without-references must turn Check 6 red (AC#2, AC#3) | **APPLY** — simulate two concurrent hook-adding PRs → confirm no shared-file conflict (AC#4) | N/A |
| **8 QA Testing** | APPLY | APPLY | APPLY | N/A |
| **9 Plan Review** | APPLY (Deep — cross-cutting) | APPLY (Deep) | APPLY (Deep) | N/A |
| **10 Cleanup** | APPLY | APPLY | APPLY | N/A |
| **11 Docs** | APPLY — new standard is itself doc; CHANGELOG | **SKIP-eligible** — #673 declares "no documentation impact" unless the fix changes Check 6 semantics in `skill-deployment.md` [SOURCE: #673 "Documentation Impact: None"]; promote to APPLY iff `skill-deployment.md` is edited | APPLY — rewrite all 47 `bypass-mode-readiness.md` xrefs + the rule itself | N/A |
| **12 Execute** | APPLY | APPLY | APPLY | N/A |
| **13 Close** | APPLY — `#1101 → Closed at Stage 13` | APPLY — `#673 → Closed at Stage 13` | APPLY — `#18 → Closed at Stage 13` | **Close-with-rationale** — `#90 → marked deferred/blocked` (NOT closed-as-done): record unmet-precondition; it remains a live blocked spike for a future release once the Check 25 shakedown lands |

No Stage 5/7/8 skips for the three in-scope issues — all have functional impact on `deploy.sh` behavior and each carries verifiable repro ACs. The only justified skip is #673 Stage 11 (declared zero doc impact, conditional on `skill-deployment.md` staying untouched). [SOURCE: #673 Documentation Impact field; #1101/#18 ACs requiring content-repro and conflict-simulation.]

---

### Contention Map

Per-file, exhaustive across the 3 in-scope issues (#90 deferred → contributes none):

| File | #1101 | #673 | #18 | Contention class |
|---|---|---|---|---|
| `core/deploy/deploy.sh` | **EDIT** Check 7 (mtime→content-hash) + required-vs-advisory declarations | **EDIT** Check 6 (iteration scope / predicate / run-context fix) | **EDIT** Check 9 (mirror-pair sync for directory-vs-single-file shape) | **HARD (single-branch serialization)** — 3-way. Blocks differ (Check 7 @ ~1650 / Check 6 @ ~1590 / Check 9 @ ~1758) so they are append-pattern-like at the hunk level, BUT under single-branch topology Engineering still serializes on the file. [SOURCE: deploy.sh line offsets confirmed.] |
| `core/standards/` (new gate-efficacy standard file) | **ADD** new file | — | — | None (sole author) |
| `.github/workflows/*.yml` | **EDIT** per-workflow invariant assertions / required-vs-advisory | — | — | None (sole author; 10 workflow files present in tree) |
| `core/rules/bypass-mode-readiness.md` | — | — | **EDIT/SPLIT** (D1/D2: split or generate; D3: anchored-append convention) | None (sole author) — but largest single-file blast radius |
| `.claude/rules/bypass-mode-readiness.md` (deployed mirror) | — | — | **EDIT** (mirror must track the split shape; Check 9 asserts the pair) | None (sole author) — NOTE: mirror is gitignored/absent in the public repo; reconcile path refs at build. [SOURCE: `.claude/rules/bypass-mode-readiness.md` not present in tracked tree.] |
| ~47 files cross-referencing `bypass-mode-readiness.md § <section>` | — | — | **EDIT** all section-anchor xrefs if D1/D2 changes the shape | None (sole author), but high edit count. [SOURCE: 47 inbound refs counted via `grep -rln bypass-mode-readiness core/ release/ operations/`.] |
| `core/rules/skill-deployment.md` | — | **POSSIBLE EDIT** (only if documented Check 6 semantics change) | — | None |

**Driver for the Implementation Sequence:** the 3-way `deploy.sh` hard-serialization is the binding constraint. Disjoint check blocks do not relax it under single-branch topology. Sequence #1101 → #673 → #18 on `deploy.sh`; #18's heavy xref/mirror work is confined to non-contended files so it parallelizes against nothing and is safely sequenced last.

---

### File Change Matrix (machine-readable, one path per line in a fenced block)

```
core/deploy/deploy.sh
core/standards/gate-efficacy-standard.md
.github/workflows/repo-integrity.yml
.github/workflows/reference-durability.yml
core/rules/skill-deployment.md
core/rules/bypass-mode-readiness.md
.claude/rules/bypass-mode-readiness.md
core/specs/autonomy-tiers.md
core/disciplines/build-philosophy.md
core/disciplines/operating-model.md
core/disciplines/autonomous-execution-model.md
core/disciplines/concurrency-safeguards.md
core/schemas/gate-criteria-spec.md
core/rules/doc-link-maintenance.md
core/rules/harness-deployment.md
core/ADRs/ADR-010-secrets-handling-policy-substrate.md
core/ADRs/ADR-007-core-module-boundary.md
core/standards/review-composition-framework.md
core/standards/doc-link-maintenance-protocol.md
core/standards/public-repo-vs-operator-instance-taxonomy.md
core/standards/design-artifact-standard.md
core/standards/upstream-reference-catalog.md
core/standards/initiative-roadmap-framework.md
core/standards/template-storage.md
core/standards/universal-vs-localized-context.md
core/deploy/tools/README.md
CHANGELOG.md
```

Notes on the matrix (NOT machine-read — read these as caveats):
- `core/standards/gate-efficacy-standard.md` is a **proposed** path for #1101's new standard; exact filename is a Stage 5 decision ([SOURCE: #1101 "core/standards/ (new gate-efficacy standard — exact path at Planning)"]). The matrix lists a concrete candidate so the add-intent is explicit.
- The `.github/workflows/*.yml` lines are #1101's candidate targets for required-vs-advisory invariant assertions; the exact workflow set is Stage 5 scope. `repo-integrity.yml` + `reference-durability.yml` are the most likely (they already encode gate logic).
- The long block of `core/*` paths from `core/specs/autonomy-tiers.md` downward are #18's cross-reference-rewrite surface (files citing `bypass-mode-readiness.md`); they are EDIT-only-if D1/D2 changes the section-anchor shape. Under D3 (anchored-append) most xrefs are untouched.
- `.claude/rules/bypass-mode-readiness.md` is the deployed mirror — gitignored/absent in the public repo; listed because Check 9 asserts the source↔mirror pair and #18 must keep them coherent. Reconcile its path-class at build, not by committing the mirror.

---

### Risk Register

| ID | Risk | Type | Severity | Owner-action / Mitigation | Reversibility |
|---|---|---|---|---|---|
| **R-1** | `deploy.sh` 3-way contention (#1101/#673/#18) causes merge churn if Engineering attempts parallel edits | Contention | **HIGH** | Enforce the serial sequence #1101 → #673 → #18 on `deploy.sh`; under single-branch topology this is automatic. Do NOT split deploy.sh edits across concurrent branches. | CHEAP (re-sequence) |
| **R-2** | #18 splits the bypass-mode monolith and breaks Check 9 (mirror-pair) and/or leaves dangling `bypass-mode-readiness.md § <section>` xrefs across the 47 inbound references | Regression | **HIGH** | Stage 7 AC#5 (Check 9 still green) + a corpus-wide grep sweep of all 47 xrefs after the D1/D2 shape change; D3 (anchored-append) avoids the xref rewrite entirely and is the lowest-regression option. [SOURCE: #18 AC "Check 9 still passes" + 47-ref count.] | MODERATE (xref rewrite is wide; revert = re-merge monolith) |
| **R-3** | Tightening Check 6 (#673) and/or Check 7 (#1101) surfaces **latent red findings on other skills** at flip time (e.g., a skill currently passing on a proxy that fails on content) | Scope (latent-finding) | **MEDIUM-HIGH** | **Run a full-catalog dry pass (`./core/deploy/deploy.sh --check`) BEFORE flipping either check to its stricter form.** Triage any newly-red skill in-release or carry-forward. This is the named #673 risk. [SOURCE: #673 "Tightening Check 6 may surface latent findings … run a full-catalog dry pass first".] | CHEAP (checks are warn-flippable) |
| **R-4** | #1101's new standard is authored but the checks are not actually retrofitted to assert it (standard-without-enforcement — the exact anti-pattern #1101 exists to kill) | Scope (theater) | **MEDIUM** | Stage 7 AC#2 is the guard: a touched-but-unchanged `.skill` must NOT pass Check 7. Verify the content-hash assertion empirically, not just the standard's prose. [SOURCE: #1101 AC "a touched-but-unchanged package does not pass".] | CHEAP |
| **R-5** | #90's external precondition (Check 25 shakedown) is assumed met without the log → a speculative pre-commit hook is designed against absent evidence (the exact failure #90's build-rule forbids) | Dependency | **MEDIUM** (mitigated by deferral) | **DEFER #90 out** (this plan's verdict). Keep it blocked; do not design speculatively. [SOURCE: #90 "do NOT design a pre-commit hook speculatively; the warn-log evidence is the trigger".] | CHEAP (deferral is reversible when the log lands) |
| **R-6** | #1101 was `status: proposed` (never folded into the bundle) → if left un-reconciled, downstream stages mis-count scope / skip it | Scope (audit) | **LOW-MEDIUM** | FOLD-IN verdict: transition #1101 → `status: bundled`; refresh milestone #114 description to "Cards (4): #18 #90 #673 #1101"; add the missing `## Release Class` + `## Parallelization Map` sections (both absent). [SOURCE: milestone description "Cards (3)" vs `open_issues:4`; no Parallelization Map / Release Class H2 present.] | CHEAP |
| **R-7** | Check 7 content-hash change (#1101) regresses package-freshness detection (false-green or false-red on legitimately-rebuilt packages) | Rollback-complexity | **MEDIUM** | Stage 7 must verify BOTH directions: touched-but-unchanged → pass (no false-red) AND genuinely-stale-content → fail (no false-green). Current Check 7 is pure mtime (`stat -f '%m'` compare, deploy.sh ~line 1665-1668); the hash path is net-new logic. | MODERATE (revert to mtime is one block) |

**Severity method (decision-discipline § 3 triage):** R-1/R-2 are HIGH because they are the two contention/regression risks the milestone theme is *about* and both have wide blast radius (shared file; 47 xrefs). R-3 is the explicitly-named #673 latent-finding risk. Localization Check applied: I did NOT apply a generic "new-standard releases are low-risk" heuristic — THIS release's standard is enforcement-bearing (retrofits live checks), so R-4 (theater) is a real, release-specific risk, not boilerplate.

---

### Quota Budget (Checkpoint A)

Frame: **usage-window cumulative-draw budget**, not a rate-limit/stagger problem (per quota-budget-protocol.md § 1 + hub-spoke-bridge § Per-Account Usage Window Constraint).

- **Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix; parallel-safe stages = 5/7/8 per Procedure 2 Step 5):**
  - **Stage 5: 3** (#1101, #673, #18 — #90 deferred → not eligible)
  - **Stage 7: 3** (#1101, #673, #18)
  - **Stage 8: 3** (#1101, #673, #18)
  - Worst parallel batch = **3 concurrent spokes**.
- **Per-spoke cost estimate (size-bucket ordinal band, quota-budget-protocol.md § 5; no telemetry medians yet):** #18 = `size:L` → moderate-high; #90 = `size:M` → low-moderate (N/A, deferred); #673, #1101 = unlabeled tasks → infer `size:M` (Check-block-scoped tasks, single-file primary surface) → low-moderate. Worst batch ≈ **2 × moderate (M) + 1 × moderate-high (L)**.
- **Assumed remaining usage-window envelope:** operator quota state UNSTATED at hub start → **conservative default** per protocol § 6 (treat as a partial, not fresh, window).
- **Estimated cumulative draw % (worst parallel batch):** 3 spokes (max M+M+L) against a conservative-default envelope ≈ **low-to-mid fraction of the envelope**. Three parallel spokes is a small batch; the canonical first-failure was **9** spokes at window-tail (v11.27, 2026-05-24). A 3-spoke batch is well under that scale.
- **Verdict: PASS** (cumulative draw estimated < 50% of a conservative envelope). Proceed parallel at Stages 5/7/8 with no batch split required.
- **Routing:** PASS → proceed parallel; no warning required in plan.
- **Note:** Checkpoint B re-validates at every parallel wave at runtime (load-bearing) with PROCEED / SERIALIZE / DEFER / REDUCE-scope; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Bands + cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM. If the operator reports a near-tail window at any Stage 5/7/8 wave, Checkpoint B may still SERIALIZE the 3-spoke batch — the PASS here is an early-window estimate, not a standing clearance.

---

### Release Class (proposed)

**Proposed class: `cross-cutting`** (operator renders; I propose).

**Trigger-condition evidence (release-class-taxonomy.md § Class Enum):**
- **cross-cutting trigger (c) — ≥3 in-bundle compositional edges per the Stage 4 A2 DAG:** the 3-way `deploy.sh` contention (#1101 Check 7, #673 Check 6, #18 Check 9) plus the #1101→#673 and #1101→#18 conformance edges constitute ≥3 in-bundle edges on a shared surface. [SOURCE: Contention Map; Dependency Graph.] This is the dominant trigger.
- **novel trigger (a) ALSO fires — ≥1 issue introduces a new reference doc/schema:** #1101 authors a new `core/standards/` gate-efficacy standard. [SOURCE: #1101 Affected Files.]
- **novel trigger (b) ALSO fires — ≥1 D-class decision in the release plan:** #18's D1/D2/D3 is a genuine operator D-class decision at Stage 5. [SOURCE: #18 AC "An operator-rendered choice of approach is recorded (D1/D2/D3)".]

**Multi-trigger resolution (taxonomy § Multi-trigger resolution):** highest-ceremony class wins, `cross-cutting` > `novel` > `routine`. Both cross-cutting and novel fire → **`cross-cutting`** is dominant. (`hotfix` is excluded — no P1/P2 defect against a deployed release; this is a forward-improvement bundle, and #1101's new-standard component would disqualify hotfix per the hotfix anti-pattern anyway.)

**Differentiation posture (per the Per-Class Mapping table, RECOMMENDATION):**
- **Engagement density: Tight** (REQUIRED) — per-spoke completion surfaces a consolidated Decision Briefing; the #18 D-decision gets an explicit cross-D upstream-compatibility scan.
- **Stage 9 Plan Review depth: Deep** (REQUIRED) — Collective Review N-way consistency + blast-radius assessment (the 47-xref + deploy.sh-3-way surface demands it).
- **Stage 5 Activation bias: ALL** (OPTIONAL) — the cross-issue compositional surface (shared deploy.sh + the gate-efficacy doctrine #673/#18 inherit) is exactly where design questions hide; bias toward activating Stage 5 for all three.
- **Stage 13 Outcome-window: 30-day** (OPTIONAL) — standard; gate-trustworthiness changes want a real post-deploy observation window (a tightened check's latent-finding behavior shows up over time).

---

### Recommendations

**1. #1101 scope call → FOLD IN (move to 4 cards).** [VERDICT: FOLD]
- Evidence: milestone #114 description records "**Cards (3):** #18 #90 #673" but the API reports `open_issues: 4` [SOURCE: `gh api repos/{REPO}/milestones`]; #1101 carries `status: proposed` while #18/#90/#673 carry `status: bundled` — it was added after the bundle was composed and never folded.
- Rationale: #1101 is the single most on-theme issue (its title is literally "gate-efficacy standard — gates assert their claimed invariant") and it is P2-High, the highest priority in the milestone. It shares the `deploy.sh` contention surface and supplies the gate-efficacy doctrine #673/#18's checks should conform to. Deferring it would ship the milestone's headline capability ("CI gate trustworthiness") without its keystone.
- Sequencing impact of folding in: #1101 becomes the **first** Engineering item (doctrine-first + first-mover on deploy.sh). Adds one Stage 5/7/8 parallel spoke (3 total) — Quota Budget still PASS.
- Mechanical follow-ups (hub, post-approval): transition #1101 `status: proposed → bundled`; refresh milestone #114 description to "**Cards (4):** #18 #90 #673 #1101"; add the absent `## Release Class` H2 (`cross-cutting`) and a `## Parallelization Map (recorded <date>)` H2 (neither is currently present in the description). These are Document-Tier-1 milestone-description edits — hub's job, not this spoke's.

**2. #90 gating verdict → UNMET → DEFER #90 OUT (stays blocked).** [VERDICT: PRECONDITION UNMET]
Commands run and observed results:
- `grep -n "Check 25\|DC1..DC4\|DC6" core/deploy/deploy.sh` → **Check 25 EXISTS** at `core/deploy/deploy.sh:2919` ("Check 25: Universal-vs-localized-context authoring guardrail (DC1-DC4 + DC6)"). [SOURCE]
- Mode wiring: `core/deploy/deploy.sh:1679` sets `local DEPLOY_CHECK_MODE="warn"` (default); `:1680-1681` resolves the mode file as `${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/deploy-check.mode`, falling back to `.claude/hooks/deploy-check.mode`. Check 25's DC1 hard-enforces; **DC2-DC6 stay signal-not-verdict (mode-driven warn)** per `:3118-3129`. So Check 25 ships **warn-mode-initial** exactly as #90's body states. [SOURCE]
- `find . -name "deploy-check.mode" -not -path "./.git/*"` → **no result** (the mode file is NOT in the tracked tree). `cat .claude/hooks/deploy-check.mode` → **NO .claude/hooks/deploy-check.mode in tree**. So the live mode is the code default `warn`. [SOURCE]
- Warn-log surface: `core/deploy/deploy.sh:1689` defines `WARN_LOG="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/deploy-check-warn-log.jsonl"`. `find . -name "deploy-check-warn-log.jsonl"` → **no result**; `find . -path "*pmo-instance*"` → **no result**. The warn-log + the entire `pmo-instance` operator-instance directory are **not observable in the public repo** (gitignored/operator-local by design). [SOURCE]
- Git history: `git log --all -i --grep="flip-to-enforce|deploy-check.mode|Check 25|universal-vs-localized"` → **no commit evidencing a Check-25 flip-to-enforce or a completed shakedown-log review.** [SOURCE]
- Corroborating standard state: `core/standards/universal-vs-localized-context.md:154` — G-4 (which is #90) is "**Own triage, gated on G-1 shakedown**"; `:151` — G-1 (the Check-N implementation) is "Already tracked." The standard's own §10.5.3 residual register (`:282`) records NEW K1 content (including `release-class-taxonomy.md`, 126 `#N` refs) **"Deferred to carry-forward"** under the DC6 discipline — i.e., the warn-mode pass is still surfacing un-remediated findings, so the warn-window has NOT cleanly elapsed/flipped. [SOURCE]
- **Conclusion:** #90's AC requires "the Check 25 warn-mode shakedown log is reviewed (confirm it exists and the warn-window has elapsed first)." The log surface is not present/observable, the mode is still `warn`, no flip evidence exists, and the governing standard still carries deferred findings. **Precondition UNMET.** Per #90's own build-rule ("If the shakedown is not yet complete at triage, keep DEFERRED until G-1's flip-to-enforce assessment lands") and ("do NOT design a pre-commit hook speculatively") → **DEFER #90 out of this release.** It stays a live BLOCKED spike; re-enters a future release once the shakedown log exists and the warn-window has elapsed. At Stage 13, `#90 → marked deferred/blocked` with the unmet-precondition cited (NOT closed-as-done).
- Caveat (audit-baseline discipline): this verdict rests on the public-repo tree only. The warn-log legitimately lives operator-local; the OPERATOR may have a populated `deploy-check-warn-log.jsonl` + elapsed window outside this repo. If the operator can attest the shakedown log exists AND the warn-window has elapsed, #90 flips to **PROCEED as a decision-class spike** (Stage 5 = the recorded decision; output = "pre-commit needed → follow-up design issue" OR "not needed → close with rationale"). Absent that attestation, the evidence-grounded default is DEFER.

**3. Merge/split.** No merges recommended (#1101/#673/#18 are distinct capability surfaces — a new standard, a detection-gap fix, a structural split — that share a file but not a deliverable; bundle-composition doctrine merges by dep-edges/capability-coherence, not by shared-file). No splits recommended within issues. The only scope adjustment is the #1101 fold-in (rec 1) and the #90 defer-out (rec 2), netting **3 in-scope issues** for this release.

**4. Capacity / effective-points check (target band 15-25, class_weight cross-cutting = 1.3).**
- In-scope sizes: #18 = `size:L`; #673, #1101 = unlabeled (infer `size:M`); #90 deferred (excluded). [SOURCE: `gh issue view … --json labels` — #673 + #1101 carry no size label; #18 carries size:L; #90 carries size:M.]
- Rough story-point mapping (S=2, M=3, L=5, XL=8, platform-typical): #18(L)=5 + #673(M)=3 + #1101(M)=3 = **11 raw pts**.
- Effective = round_half_up(11 × 1.3) = round_half_up(14.3) = **14 effective pts** — marginally **below** the 15-25 band.
- Read: this is a **slightly-under-band** release, NOT over-scoped. That is acceptable and arguably correct given the HIGH contention/regression risk concentration (R-1/R-2/R-3 all touch the same surfaces) — a leaner bundle reduces the serial-deploy.sh churn surface. Localization Check: I did NOT pad scope to hit the band; under-band here is a feature (lower contention), and the operator may accept it or pull a sibling deploy-hygiene issue forward. Flag for operator: **14 effective pts < 15** — accept as-is (recommended) or add one adjacent governance-hygiene issue.

**5. Out-of-scope discoveries (noted, not actioned):**
- Milestone #114 description lacks BOTH a `## Release Class` H2 and a `## Parallelization Map (recorded YYYY-MM-DD)` H2 — the Stage 4 Parallelization-Map currency check (stage-04-planning.md Phase A0) would flag this as a finding for a post-cutover release. Hub should add both at the same time it folds in #1101. [SOURCE: milestone description body — neither section present.]
- #673's Notes reference three further deploy-toolchain verification gaps from the v1.10 Stage 12 output (R1 `detect_changed_skills()` BSD-sed alternation no-op; R2 `build-skill-packages.sh` ALL_SKILLS stale; R3 Check 1 nested-target false positive) as a possible bundle — they are explicitly NOT in #673's scope as filed and are NOT in this milestone. Candidate for a sibling deploy-hygiene milestone, not this release. [SOURCE: #673 Risks & Cross-Cutting Impact.]
- The `.claude/rules/bypass-mode-readiness.md` deployed mirror is absent from the tracked tree (operator-instance/gitignored). #18's Check 9 work must reconcile the source↔mirror path-class at build time, not by committing the mirror — flag for the #18 Stage 5 spoke. [SOURCE: `ls .claude/rules/bypass-mode-readiness.md` → not present.]

---

*Plan authored read-only at Stage 4 (Planning). No files modified, no branches created. Scope/sequence only — no dates (single-operator PMO). Operator renders the Release Class, the #1101 fold-in, and the #18 D1/D2/D3 choice.*

