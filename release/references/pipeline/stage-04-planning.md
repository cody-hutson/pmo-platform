<!-- reference-durability: allow-link -->
# Stage 4: Planning

> **Source:** Stage 4 originating spec
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Transform a scoped Milestone into a dependency-ordered implementation plan with file-level change specifications, so the engineer can execute sequentially without re-analyzing scope.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Commit capacity; establish timeline; allocate resources | Sequencing + change specification + risk identification |
| Governance Focus | Capacity feasibility; stakeholder alignment | Can bundle ship as one release? Operator approves plan |
| Artifact Inputs | Charter/scope, requirements, resource plan | Milestone, issue bodies, dep graph, current file state |
| Artifact Outputs | Sprint/PI plan, timeline, resource assignments | Release plan (sequence, file change matrix, risk register, verification, rollback) |

Key compression: No multi-team resource allocation or timeline negotiation. Planning = sequencing + change specification + risk identification.

## 3. Persona

| Role | Skills-Map Ref | Autonomy |
|---|---|---|
| Decision maker: Human operator | — | Tier 3 |
| Release planning: Release Mgr Skill 13, Mode 1 | Dep ordering, readiness, risk, cadence | Tier 2 (Recommend) |
| Technical analysis: PPM Agent Skill 12 | File analysis, change spec drafting, integration mapping | Tier 1 (Auto) |

## 4. Inputs
From Bundle: Milestone with assigned issues, dependency graph, version number.
Set at Planning: Implementation sequence, file change matrix, risk register, delivery strategy, verification plan, rollback strategy.
Contextual: GitHub Issue Dependencies API, current file state, release history, existing plans in `release/releases/plans/`.

## 5. Process

**Cutover:** This re-review protocol applies to releases that enter Stage 4
on or after `2026-04-25`. Releases whose Stage 4 sub-task was created
prior to that date are exempt — they predate the protocol. The cutover
date is recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>) at the introducing release's entry.

**Phase A0 — Triage→Design Re-Review per [triage-design-rereview.md](../standards/triage-design-rereview.md):** spoke produces re-review artifact (header + per-requirement table) at sub-task output head, before A1 begins. C3 classifications trigger Tier 0 — Premise Rejection per [release-process.md](../../governance/release-process.md) Inter-Stage Feedback Protocol. Effort tier per § 7 (trivial / standard / complex). Always-fires for releases subject to cutover.

**Phase A0.5 — AC/substrate currency gate (G-PL1):** [elevates the prior unnamed AC-currency check to a named, enforced phase]. For each per-issue AC in the release scope, the Phase A0 spoke verifies AC-stated context (version refs, file paths, named upstream artifacts) against current platform state. CURRENCY-MISMATCH findings route Tier 1 [ADJUST] (AC refinement via `gh issue edit --body` + release-plan deviation-log entry) OR Tier 2 [SCOPE CHANGE] when the AC's premise itself is invalidated. Composes with Bundle Mutability A7 trigger T4 (Stage 4 boundary currency check) and with the Phase A0 Triage→Design Re-Review D2 column. **G-PL1 criterion:** every release-scoped issue's AC context is reconciled against current state before A1; unreconciled AC context (stale path / version / upstream-artifact ref) is a G-PL1 FAIL → route the issue to Tier 1 [ADJUST] before plan-design. Gate ID per the `G-[stage-abbrev][seq]` convention ([`core/schemas/gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) § Schema).

**Phase A0.6 — Pre-plan crisping gate (G-PL2):** Before A1 plan-design begins, the Phase A0 spoke re-runs the Gate 1 substantive checks (G1-02 Description actionable / G1-04 Proposed Change names files-or-protocols / G1-05 AC verifiable, per [`core/schemas/gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) § Gate 1) against the CURRENT body of each bundled issue. Rationale: bundled bodies may be weak or stale at Stage 4 entry even when they passed at intake (intake-substrate drift). **G-PL2 criterion:** every bundled issue body passes the Gate 1 substantive checks at Stage 4 entry; any FAIL routes the issue to a crisping pre-gate — operator-gated body refinement (via `gh issue edit --body`, reusing the Gate 1 self-repair remediations) BEFORE plan-design proceeds. The crisping responsibility is housed inline in the `release-planner` skill (no cross-module dependency; the operations `pmo-process-designer` skill is NOT invoked — module Public-API discipline, [`core/ADRs/ADR-007`](../../../core/ADRs/ADR-007-core-module-boundary.md)). G-PL2 is judgment-graded (the "is this body crisp enough to plan against" assessment is the same judgment class as G1-02/G1-04/G1-05 recommend-tier).

**Parallelization-Map currency check:** In addition to the AC-currency check above, the Phase A0 spoke verifies the milestone's standing `## Parallelization Map (recorded YYYY-MM-DD)` section — the standing milestone-description convention defined in the Stage 3 Bundle spec — is present and dated within the bundle-creation → Stage 4 entry window. Procedure:

1. Read milestone description via `gh api repos/{REPO}/milestones/<N> --jq .description`.
2. Locate the `## Parallelization Map (recorded YYYY-MM-DD)` H2 header. A **stale-dated map** (date older than the most recent A7 refresh-trigger event for this bundle, OR the map absent on a milestone required to carry one) is a **Phase A0 finding** routed Tier 1 [ADJUST] (re-run the embedded reconfirm procedure via the documented `gh issue list --milestone ... --jq` scan, update the date, amend the milestone description) OR Tier 2 [SCOPE CHANGE] when re-running the scan surfaces new hard-edges that materially change cross-milestone sequencing (operator decides re-sequence vs. defer-with-rationale).
3. The check **composes with Bundle Mutability A7 trigger T5** — it is mechanically a sub-application of trigger T4 (Stage-4-boundary currency check): same procedure surface, narrower scope (the map's date stamp vs. T4's full T1/T2/T3 re-evaluation). The A7 Bundle Mutability Protocol lives in the release-process governance. The hard-vs-soft edge classifier — the reproducible regex-grep that sorts each cross-milestone reference into hard / soft / file-contention — is the canonical source of edge-class semantics applied during reconfirm, and lives as the Hard-vs-Soft Edge Classifier in the release-planner dependency-analysis reference.
4. **Structural-blast-radius (Tier-S) re-derivation.** The currency check additionally re-derives the map's Tier-S verdict (the structural-blast-radius axis defined in the Stage 3 Bundle spec § A9.6.1): if any sibling milestone has declared a rename / relocate / delete in its File Change Matrix since the map's recorded date, re-run the mover-classifier + F1–F6 sweep + the intersection predicate for this release against that sibling. A newly-intersecting sibling not carried as a Tier-S edge in the standing map is a Phase A0 finding routed as above (Tier 1 [ADJUST] to amend the map; Tier 2 [SCOPE CHANGE] when the new structural edge materially changes cross-milestone sequencing). **Cutover:** applies to releases entering Stage 4 strictly AFTER this protocol's introducing-release merge SHA recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline).

**Standing applicability.** The convention does not retroactively bind milestones that predate its adoption — they carry no Parallelization Map section by construction, so the Phase A0 currency check is suppressed for them. Future milestones reaching Stage 4 Planning carry the reconfirm step per this convention.

**Phase A0 currency-decision confidence gate (proceed-vs-pause pre-action check).** The Phase A0 currency check terminates in a single decision: which Bundle Mutability A7 refresh outcome to render — **no-op / amend / re-bundle / defer** (the four refresh-outcome paths in the A7 Bundle Mutability Protocol in the release-process governance, selected via the churn-budget threshold once a trigger T1–T6 fires). That refresh-outcome choice is a decision-class action — a proceed/defer choice on a bundled milestone — so before the spoke renders it, it runs the proceed-vs-pause gate from the Decision-Confidence Protocol (by-name; the spec file is `core/specs/decision-confidence-protocol.md`, which names this Stage-4 currency-check as its primary live consumer). This is the **named live consumer** of the protocol, not a mention: the currency decision computes the signal, consults the matrix, and runs the bounded pause-to-learn loop when the matrix routes to PAUSE.

The gate is the **pre-action check** on the refresh-outcome decision, and it runs as follows:

1. **Compute the confidence signal** for the pending refresh outcome from the three observable sources the protocol defines — does an independent cross-check corroborate the outcome (e.g., the A0.5 AC-currency reconciliation, the A0.6 crisping re-run, and the Parallelization-Map re-derivation above agree on the same composition delta); is the gap nameable (a specific stale path / version / dependency-state, not a vague unease); what is the weakest evidence label under the outcome. The signal collapses to one of the protocol's three states (broadly: corroborated-and-grounded, a named divergence, or an ungrounded assumption). Verbalized self-confidence is **not** an admitted input — the outcome must cite which observable source grounded it.
2. **Select the action from the reversibility × autonomy matrix**, not from a single global cutoff. The refresh-outcome action carries a reversibility tier per `reversibility-protocol.md` (a no-op or an in-window amend with `[BUNDLE AMENDMENT]` is the cheaper end; a re-bundle that rewrites the Milestone and re-executes Stage 3 Phase A1–A5, or a defer that removes the milestone from affected issues, is the more expensive end). A corroborated-and-grounded signal proceeds at the outcome's existing authorization (the A7 paths already route amend / re-bundle / defer to the operator and keep no-op autonomous — the gate **lowers ceremony when grounded, never raises authority**, so it never promotes an operator-gated re-bundle into an autonomous one). A named-divergence or ungrounded signal on a costlier outcome routes to PAUSE-TO-LEARN; an irreversible-class outcome on a non-grounded signal routes straight to escalation.
3. **Run the bounded pause-to-learn loop** (per the protocol, the same pre-action sibling to Retry/Escalate registered as the Pause-to-Learn Pattern in `core/disciplines/autonomous-execution-model.md`) when the matrix routes to PAUSE: name the gap (reuse the specific currency finding — the stale path, the changed dependency state, the new structural edge), inject **one new external signal** (the canonical-source read the gap calls for — re-read the milestone description, re-walk the dependency state via `gh`, re-run the refresh-trigger scan via `release/tools/check-bundle-refresh.sh`), re-evaluate the signal, and exit. The loop is bounded (a small cycle cap) and self-closing: a cycle that injects no new signal is a stall, not a pause. The loop exits by **resolving** (signal grounds → render the A7 outcome at its existing tier), **routing out** (the gap is knowable-only-later → a spike or a ship-and-observe decision), or **escalating** (budget exhausted → surface the named gap plus what was tried as the operator briefing's context, i.e., the Tier 2 [SCOPE CHANGE] escalation the A7 amend/re-bundle/defer paths already route to the operator).

This gate is **additive** to the currency checks above — A0.5 (AC currency), A0.6 (crisping), and the Parallelization-Map check each *feed* the refresh-outcome decision; this gate governs the confidence with which that decision is then rendered. It introduces no new A7 trigger, no new refresh-outcome path, and no new escalation surface — it binds the proceed-vs-pause discipline onto the outcome selection the A7 protocol already defines. **Cutover:** applies to releases entering Stage 4 strictly AFTER this consumer-integration's introducing-release merge SHA recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline).

**Phase A (Agent):** A1 Milestone validation entry gate (metrics + judgment per gate-evaluation-spec.md), A1.5 domain-best-practice sourcing-or-flag step (the SHIP-WITH-FLAG step below), A2 dependency-ordered sequencing (GitHub Dependencies API), A3 per-issue change specification (file-level: what to add/edit/remove), A4 file contention resolution (matrix, merge order, conflict detection), A5 release plan assembly (full plan with Delivery Strategy per Rev 1), A6 quota-budget pre-check (terminal — parallel-batch capacity estimate against the usage-window envelope; § 5.8).

**§ 5.7 — Phase A1.5: Domain-Best-Practice Sourcing-or-Flag Step (SHIP-WITH-FLAG mechanism):** After A1 milestone validation and BEFORE A2 sequencing, the Planning spoke determines whether the release operates on a domain whose external best-practice the platform does not already encode. If so, the spoke EITHER sources authoritative guidance OR explicitly flags the gap to the operator via a machine-readable `domain_practice` provenance label that downstream stages (Stage 5 Solutioning when activated; Stage 7 Dev Testing always) verify.

The provenance label schema is **inlined here** — it lives in this pipeline spec rather than in a separate standard file, keeping the ceremony minimal. The schema also applies to Stage 5 design outputs when Solutioning is activated; the Stage 5 Solutioning spec's Domain-Best-Practice Sourcing Step inherits this label and defines the refinement obligations.

**Two operating modes:**

| Mode | Trigger | `domain_practice` label form | Downstream behavior |
|---|---|---|---|
| **A — Domain pre-known** | Platform already encodes the domain's best-practice (recurring domain; prior release authored the encoding) OR the operator confirms pre-known status at the Phase A1.5 prompt | `domain_practice: { source: <citation URL or repo-relative path>, date: <YYYY-MM-DD>, name: <practice-name>, domain: <domain-class> }` | Sourced design proceeds to A2 sequencing |
| **B — Domain unknown (SHIP-WITH-FLAG path)** | Platform does NOT encode the domain's best-practice AND no inline sourcing happens at the Phase A1.5 prompt (automatic unfamiliar-domain detection is deferred to a follow-up; see Acquisition mechanism below) | `domain_practice: { source: UNSOURCED-DOMAIN, date: <YYYY-MM-DD>, rationale: <one-line operator-prompt result OR explicit "domain detection pending follow-up">, domain: <domain-class> }` | Flag travels with release plan; Stage 7 Dev Testing verifies presence + dated field; Stage 9 Decision Briefing surfaces the flag for operator awareness; pipeline does NOT silently proceed |

**The `domain:` class field (every mode carries a domain class).** The `domain:` field names the abstract domain class of the release's deliverable — the concrete substrate that downstream design-aware mechanisms branch on (the impact-analysis method selector, the design-best-practice review criterion, and the domain-guide index all read this one field). Its value is a domain-class name (e.g., `software`, `governance`, `web`, `data`, `enterprise-platform`, `hardware`) matching a guide under `core/standards/domain-best-practices/<domain>.md` where one exists, OR a free domain name when no guide exists yet (which is itself the demand signal for authoring a guide per the expansion rule). The field is **mandatory in every mode** — Mode A, Mode B, AND the pipeline-internal exemption below — so no release reaches Stage 5/7 carrying an unclassified deliverable. The `domain:` class is an abstract signal, not a hard read of a structured PROJECT.md field; a first-class PROJECT.md domain axis is a follow-up that later becomes an additional authoritative source feeding this same field without reworking the consumers.

**A3-time deliverable-domain classification.** The Planning/Solutioning spoke classifies the deliverable's domain from the **File-Change-Matrix** — the set of files the release adds or edits is the determinative evidence of what kind of deliverable it is (a release editing only `core/`/`release/`/`operations/` governance and pipeline artifacts is `domain: governance`; a release adding application source/tests is `domain: software`; a release whose matrix targets a website/frontend surface is `domain: web`; and so on). The spoke records the classified value in the `domain:` field at A3 change-specification time (the same surface that produces the File-Change-Matrix), and surfaces a one-line classification rationale citing the matrix evidence. When the matrix spans more than one domain, the spoke records the dominant domain and notes the secondary domain(s) in the rationale rather than leaving the field ambiguous.

**Provenance label placement:** The Planning spoke embeds the resolved `domain_practice` label in the release plan file under the `### Release Class declaration` H3 (or as a sibling H3 `### Domain Practice Provenance` when the release plan template predates this convention). The label is machine-readable (single-line, key-value form); the `date` field is mandatory in BOTH modes so staleness is detectable. Releases that re-cite a previously-sourced domain after >180 days SHOULD re-confirm currency at A1.5 (the date field surfaces the gap for operator decision).

**Acquisition mechanism (current state):** operator-prompt at Planning time OR explicit `UNSOURCED-DOMAIN` flag. Auto-detection of "is this an unfamiliar domain?" requires a domain-parameter keystone capability and is deferred to a follow-up — the operator-approved posture is SHIP-WITH-FLAG: ship the convention + flag mechanism now, fill in auto-detection later. The convention + flag mechanism is the current-state surface; the follow-up adds auto-detection on top of it.

**Cutover (the `domain:` class field, introducing-release-exempt):** The mandatory `domain:` class field and the A3-time deliverable-domain classification apply to releases entering Stage 4 Planning strictly AFTER this substrate's introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the substrate shipping in a release cannot retroactively bind its own Planning, which ran before the field existed; the introducing release's own `domain_practice` label is authored to the new shape by hand at Engineering time (its release plan demonstrates the field), and all releases that entered Stage 4 prior to the introducing release are exempt. This mirrors the introducing-release-exempt cutover discipline used by the cross-PR overlap audit and the append-pattern detection above.

**Software / governance / pipeline-internal releases exempt (from external SOURCING — not from domain CLASSIFICATION):** Releases whose entire File Change Matrix consists of internal pmo-platform artifacts (governance edits, pipeline-spec edits, skill-internal changes, ADR work) do NOT trigger A1.5 *external sourcing* — the "domain" is the platform's own internals, whose best-practice the platform now encodes directly in the domain-best-practice guides at `core/standards/domain-best-practices/` (the `governance` guide is the encoding of the platform's own internal-deliverable practice; the `software` guide encodes general engineering practice). The Planning spoke records a `domain_practice` label whose `source` is `N/A — pipeline-internal release` with a date AND a `domain:` class field, and proceeds. This preserves the regression posture for governance/software releases: they add no *external sourcing* step.

  Two distinct properties must not be conflated here:
  - **Sourcing-exempt:** a *platform-internal-deliverable release* is exempt from the external-sourcing step — its `source` is `N/A — pipeline-internal release`. This is a property of *where the deliverable's files live* (all internal).
  - **Domain-classified:** the same release still carries a `domain:` class (typically `governance` for pipeline/governance work, or `software` for skill/tooling code), because the design-aware downstream mechanisms still need the class to select the matching guide under `core/standards/domain-best-practices/`. Being sourcing-exempt does NOT make a release domain-less.

  The label form for an exempt release: `domain_practice: { source: N/A — pipeline-internal release, date: <YYYY-MM-DD>, domain: <governance|software|...> }`. The `domain:` value points the downstream consumer at the guide that encodes that domain's practice; the guide IS the encoding the "already encoded" presumption presumed.

**Cross-PR Overlap Audit (A4 extension):** A4 file contention resolution covers two distinct operations. (1) **Within-release contention**: files claimed by multiple change-specs in the current release plan; resolved via sequencing or scope split. (2) **Cross-PR contention**: files in the current change-spec also being modified by recently-merged or open PRs outside this release; surfaced via baseline-pinned analysis (last-N merged PRs + open PRs at audit-start commit SHA per `<OPERATOR_INSTANCE_ANALYSIS_PATH>/file-overlap-audit-<date>/`). Cross-PR contention informs sequencing (defer until upstream merges) or risk-register entries. **Distinction discipline**: this audit is NOT byte-identity verification of release-plan files at Engineering Commit 0 — that check confirms internal consistency of the plan; this check identifies external collisions across PRs. Both check forms operate at A4 but answer different questions. **Append-pattern detection (per [ADR-005](../../ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md))**: post-cutover audits classify each contended file with an `overlap_class` enum (`append-pattern` / `line-range-overlap` / `single-pr`) computed from per-PR `line_ranges` (hunk-range JSON arrays); files with `overlap_class = append-pattern` are informational (structurally HIGH, operationally LOW — append-pattern PRs almost never conflict at merge time), while `line-range-overlap` retains the ADR-001 sequencing/scope-split mitigation guidance. Canonical implementation: `python3 release/tools/check-line-range-overlap.py` (optional for ≤3-PR audits; recommended for ≥3-PR cases for reproducibility). Cutover: applies to releases entering Stage 4 on or after the ADR-001 introducing-release merge SHA recorded in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`; pre-cutover releases are exempt. Append-pattern detection (ADR-005) applies to releases entering Stage 4 strictly AFTER the ADR-005 introducing-release merge SHA; **the ADR-005 introducing release itself is exempt** (reflexive-pipeline-loop discipline — the rule shipping in a release cannot fire on its own bundling).

**Structural-blast-radius sub-audit (A4 extension — cross-release mover collision).** Beyond the same-path overlap scans above, A4 models the **structural blast radius** of a file-mover release per the Stage 3 Bundle spec § A9.6.1 axis — A4 is the first pipeline point a release branch exists, so it is the **authoritative** structural-detection surface (Stage 3 is advisory pre-branch). Procedure: (1) compute this release's mover-set via the 4-token git mover-classifier (`git diff --name-status --find-renames <base>..<head>`); (2) compute `SURFACE(R)` via the F1–F6 ref-form sweep per [`doc-corpus-reorg-ref-forms.md`](../protocols/doc-corpus-reorg-ref-forms.md) parameterized by the mover-set's old/new path pairs — **consume the Stage 5 Phase A3.2 sweep output when it has already fired** for this release rather than recomputing; the cross-release surface is the union of F1 / F2 / F3 / F5 + the in-tree half of F6 (**F4 mover-internal-outbound is EXCLUDED** — it is the release's own A3.2 rewrite obligation, not an edit to the target files, and including it over-serializes against high-traffic governance files), plus the **version-slot virtual-path token `Δversion/<claim-key>`** per the Stage 3 Bundle spec § A9.6.1 Step 2a — the provisional version is bound at the Stage 4 D-Version gate, so A4 is the **first authoritative** firing of the version axis (Stage 3 is advisory pre-binding); (3) for each open/planned sibling milestone, test `EDITSET(sibling) ∩ SURFACE(R) ≠ ∅` from the sibling's File Change Matrix (a sibling intending the same provisional version slot contributes the same `Δversion/<claim-key>` token, so a version collision surfaces as a Tier-S serialization edge here exactly as a mover collision does). A true intersection is a **serialization point** (one merges, the other re-baselines) recorded as a Tier-S edge in the Parallelization Map and in the Risk Register — not a parallel candidate. The surface is bounded to the mover-set's own rewrite/break surface (never the whole repo), so a sibling editing a path outside the surface is explicitly not serialized. **Scope:** corpus mover-sets (the code-mover case uses the Phase A3.1 domain-aware impact-analysis branch, not this corpus sweep). **Cutover:** applies to releases entering Stage 4 strictly AFTER this protocol's introducing-release merge SHA recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline).

**Baseline-pin temporal limitation:** The A4 audit is **baseline-pinned** — it surveys cross-PR contention against the audit-start commit SHA only. Concurrent releases merging to `main` AFTER the audit but BEFORE Stage 12 are NOT detected by A4. The mid-pipeline divergence checkpoint at [Stage 9 Phase A6.5](../../governance/release-process.md) (PRIMARY, HALT-eligible) plus informational checks at Stage 7/8 entry (SECONDARY, warn-only) complement the A4 baseline snapshot with stage-boundary re-checks; Stage 12 Phase A.5 remains the post-GO ultima-ratio detector per [`pipeline/stage-12-execute.md` § Phase A.5](stage-12-execute.md). **Cutover discipline:** Applies to releases entering Stage 4 strictly AFTER the v1.01-intake merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>); **v1.01-intake itself is exempt** (reflexive-pipeline-loop discipline — this limitation is itself the subject of v1.01-intake, so v1.01-intake's own Stage 4 audit ran AS-IS per this discipline).

**Sibling-merge stale-pin self-invalidation trigger (structural-blast-radius extension).** The baseline-pin limitation above is sharpened for the structural axis: a pinned A4 structural sub-audit at SHA X **self-invalidates** (must be re-run) when a *sibling parallel release merges to `main` after X and before this release's Stage 9*. The trigger predicate — **unified with the Stage 9 G-PR9 sibling-merge revalidation predicate and the Stage 12 Phase A.5 semantic check** so all three surfaces answer the same question the same way (merge-style-agnostic; the repo lands releases via both merge commits AND squash / fast-forward non-merge commits, so a `--merges`-only filter would silently miss a squash landing): at Phase A0 entry and at Stage 9 entry, run `git log X..origin/main --name-status --find-renames` and intersect the touched / renamed / deleted path-set against this release's `SURFACE(R)`. Any intersecting path → re-run the A4 structural sub-audit against the new `main`. This is the durability the audit requires — the pin is reconfirmed where it can go stale, not treated as a one-off. **Cutover:** applies to releases entering Stage 4 strictly AFTER this protocol's introducing-release merge SHA recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline).

**§ 5.8 — Phase A6: Quota-Budget Pre-Check (terminal):** After A5 release-plan assembly, the Planning spoke runs Checkpoint A of the quota-budget protocol — a plan-time estimate of the worst parallel batch's cumulative draw against the per-account 5-hour usage-window envelope. A6 is sited terminally because it summarizes plan-level capacity for the *assembled* plan; it reads the parallel-eligible spoke count from the **A2 Stage Applicability Matrix** (the parallel-safe stages are 5 / 7 / 8 per the Procedure 2 Step 5 Parallelism Rules table) and the contention output from **A4**. The full band definitions, the verdict logic, the per-spoke cost heuristic, and the calibration treatment live in the canonical [`quota-budget-protocol.md`](../standards/quota-budget-protocol.md) — A6 references them rather than re-stating (register-or-remove discipline).

| Input | Source |
|---|---|
| Parallel-eligible spoke count per parallel stage (Stage 5 / 7 / 8) | A2 Stage Applicability Matrix |
| Per-spoke cost estimate | Per-spoke cost-estimate heuristic per [`quota-budget-protocol.md`](../standards/quota-budget-protocol.md) § 5 (size-bucket band until telemetry medians) |
| Cumulative work estimate | parallel-eligible count × per-spoke cost estimate, per parallel batch (worst batch) |
| Assumed/stated remaining usage-window envelope | Operator-stated quota state at hub start, OR a conservative default when unstated |
| Estimated cumulative draw % | cumulative estimate ÷ envelope (worst parallel batch) |

**Routing tree (bands defined in [`quota-budget-protocol.md`](../standards/quota-budget-protocol.md) § 3):**

```
PASS  (cumulative draw < 50% of envelope)   → proceed parallel; no warning in plan
WARN  (cumulative draw 50–80% of envelope)  → window-aware launch timing + quota-budgeting
                                              (split batch) recommended in the plan
FAIL  (cumulative draw > 80% of envelope)   → (a) split-batch / (b) reduce per-spoke cost /
                                              (c) escalate Tier 2 [SCOPE CHANGE]
```

A6's verdict is advisory — it surfaces capacity risk in the plan. The load-bearing gate is Checkpoint B, which re-validates at every parallel wave at runtime ([`../how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) Procedure 2 Step 5.5) with the PROCEED / SERIALIZE / DEFER / REDUCE-scope verdict set; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. **Cutover:** applies to releases entering Stage 4 on or after this gate's introducing-release merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>); the introducing release itself is exempt (reflexive-pipeline-loop discipline — its own A6 ran before the gate existed).

**Phase B (Human):** Approve/modify/split/hold. Plan committed to release branch as first file.
**Handoff:** Routes to Solutioning (Stage 5) when activation criteria met, or directly to Engineering (Stage 6) when skipped. Activation criteria per [`planning-solutioning-handoff.md`](../../../core/standards/planning-solutioning-handoff.md). Stage 4 spoke instantiates the per-release evaluation matrix in the release plan's § Stage Applicability Matrix.

**Ticket lifecycle:** Claim: validate Status=Bundled + Milestone assigned, set Stage→4-Planning. Execute: release plan creation (A1-A5 + B approval). Resolve: post plan reference comment, commit plan to branch. No status change — remains Bundled until Engineering. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md) Ticket Lifecycle Protocol.

**Framework dimensions touched:** Work Breakdown (sub-task decomposition); State Persistence (release plan). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Release plan file (`release/releases/plans/vX.Y_RELEASE_PLAN.md`), committed on release branch. Sections: Implementation Sequence, File Change Matrix, Integration Points, Risk Register, Delivery Strategy, Verification Plan, Rollback Strategy, Quota Budget (Phase A6 output).

The `### Quota Budget` section records the Phase A6 Checkpoint A estimate. Scaffold:

```markdown
### Quota Budget

**Verdict:** PASS | WARN | FAIL (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from A2 Stage Applicability Matrix):** Stage 5: <N> · Stage 7: <N> · Stage 8: <N>
**Per-spoke cost estimate:** <band/heuristic or telemetry median> (source: <heuristic | pipeline-event-log spoke-launch medians>)
**Assumed/stated remaining usage-window envelope:** <operator-stated state at hub start, or conservative default>
**Estimated cumulative draw % (worst parallel batch):** <cumulative ÷ envelope>%
**Routing:** <PASS: proceed | WARN: window-aware timing + quota-budget/split | FAIL: (a) split-batch / (b) reduce cost / (c) Tier-2 scope change>
**Note:** Checkpoint B re-validates at every parallel wave (runtime, load-bearing) with PROCEED/SERIALIZE/DEFER/REDUCE-scope; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Bands + cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM.
```

The committed release-plan file is durable corpus and is governed by the reference-durability standard under the core standards set: state the plan's rules and decisions unconditionally and inline, summarize referenced content rather than linking to it, and confine any unavoidable bare issue reference to a designated reference block with an inline summary. A release-plan version label in the plan's own title is a narrative release identifier, not a load-bearing reference. The reference-durability hook flags violations when the plan file is written.

### Verification-Plan AC→method mapping

Planning maps each in-scope issue's acceptance criteria to a verification-method class, which the per-issue Verification table (the `release-planner` plan template's § Verification Plan → `### Per-Issue Verification` table, columns `Issue | Verification Method | Expected Result`) then records. The recognized method classes mirror the G1-05a admissible AC-predicate patterns:

| AC predicate class | Verification method class | Example |
|---|---|---|
| file-path+state (G1-05a pattern b) | file-content / system-state assertion | `grep -q '<pattern>' <file>` |
| explicit `predicate:` (G1-05a pattern c) | evaluate the predicate expression against current state | re-run the cited expression |
| **behavioral/domain (G1-05a pattern d)** | **the AC's *declared* verification method** — a gate-eval / reproduction-and-observe / judge-rubric / cross-output-coherence run, as declared in the AC's `method:` field | run the declared method against its fixture/target |

A behavioral/domain AC's verification method is whatever its `method:` field declares; Planning records the declared method as the issue's Verification Method even when the executor for that method is not yet built. This block names the recognized method classes; it does not restate the per-issue table — that table is owned by the plan template's § Verification Plan and is populated per release.

**Declared, verification deferred (honesty note).** A behavioral/domain AC may be admitted with its verification method **declared** even before an executor for that method exists. Declaration is what makes the AC honest at intake/planning; building and running the executor is a separate, later concern (Stage 7/8). A declared-but-not-yet-executable method is a valid method for gate purposes — it is recorded, surfaced, and tracked, not silently dropped or lossily rewritten. This is the canonical statement of the note; the G1-05a and G3-05 self-repair cells in `core/schemas/gate-criteria-spec.md` carry the short inline form and defer here for the full rationale.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: dep satisfaction, file coverage verified, change spec completeness, contention resolved, risk register populated, verification plan complete, Delivery Strategy specified, routing decision made.
Judgment (1-5): sequence coherence, risk awareness, verification completeness, plan actionability.
Calibration: planned vs. actual sequence, files, risks, verification — tracked post-release.

## 8. Automation Level
Overall Tier 2. Today: agent runs A1-A5 in conversation. Target: Planning mode in release-planner skill.

## 9. Gap Summary
14 gaps identified. Key items: release plan template (P3), sub-task decomposition (P2), inter-stage feedback (P3), handoff coordinator (P2).

## 10. Retro
Key lessons: Delivery Strategy (branch/PR/merge) must be in every plan. Sub-task decomposition is Engineering's responsibility — Planning hands off issue-level. File contention is the primary challenge for documentation-heavy releases. Inter-stage feedback protocol needed when plans don't survive implementation. Gap discovery rate is highest at Planning (14 gaps) — expected as first stage producing complete engineering handoff.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `decision` | `d-class` | Per D-class decision rendered at the Operator Decision Gate (Phase D) — `subject` is the D-letter (D-A, D-B, …) | `operator` |
| `escalation` | `tier-0` | Phase A0 re-review fires Tier 0 Premise Rejection (C3 classification) per [`triage-design-rereview.md` § 9](../standards/triage-design-rereview.md) | `spoke:#N` |
| `re-review` | `phase-a0-row` | Phase A0 re-review row appended to `triage-design-rereview-instrumentation.md`; pipeline-event-log row carries `projects_to: triage-design-rereview-instrumentation.md:<row-anchor>` | `spoke:#N` |
| `scope-change` | `tier-2-scope-change` | Tier 2 [SCOPE CHANGE] surfaced to operator per § Inter-Stage Feedback Protocol | `spoke:#N` |

Cutover: events occurring on or after the FIRST release entering this stage strictly AFTER this protocol's introducing-release merge SHA. The introducing release itself: exempt (reflexive-pipeline-loop discipline).
