<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
# Release Plan — parallel-launch-quota-budget-gate

> **Status:** Engineering Commit 0 (release branch `release/parallel-launch-quota-budget-gate`).
> **Topology:** D-C SINGLE · **Release Class:** `novel` · **Milestone:** parallel-launch-quota-budget-gate.
> **Identity:** VERSION-LESS (slug identity `parallel-launch-quota-budget-gate`; no version integer — v1.15/v1.16/v1.17 were claimed by concurrent releases). See the Deviation Log for the re-version record.
> **Source:** Stage 4 Release Planning spoke output (transcribed from the Stage 4 planning sub-task #772). The Stage 4 plan was authored proposing version `v1.15`; per the version-less re-version (Deviation Log item a), every load-bearing `v1.15` anchor below is reconciled to the slug identity / the introducing-release merge SHA. The plan substance (dependency graph, sequence, contention map, stage-applicability, risk register, A9, Release Class) is preserved verbatim in meaning.

---

### Summary (30 seconds)

Two sibling `protocol`-class governance/spec issues that together add quota-awareness to the parallel-spoke launch path. **#24 (foundation)** authors the canonical `### Per-Account Usage Window Constraint` subsection in `hub-spoke-bridge.md § Spoke Launch Mechanisms` + a Stage-5-row note; **#23 (active gate)** builds the dual-checkpoint enforcement (Stage 4 plan-time Checkpoint A + Procedure 2 / Spoke-Launch-Mechanisms runtime Checkpoint B) that *references* #24's subsection. **Recommendation: keep separate, sequence #24 → #23** (foundation→gate dependency + heavy shared-file contention under D-C SINGLE). Both edit the SAME three regions, so Engineering serializes at file level regardless.

**Proposed Release Class: `novel`** (new file `quota-budget-protocol.md` + multiple open D-class decisions). **Identity: version-less** (slug `parallel-launch-quota-budget-gate`; the `v12.13.1` anchor in both bodies is pre-re-versioning and is reconciled — see R-2 / Deviation Log). **A9 self-execution verdict: PASS** — this release's own parallel profile is ≤2 parallel-eligible issues per stage; no quota risk to its own spokes.

**Two stale AC premises found** (reconcile at Stage 5, do NOT build to the body as-written): (1) the "Parallelism Rules table in `release-process.md`" does not exist — the table lives ONLY in `hub-spoke-bridge.md`; (2) there is no `spoke-completion` event in the event-log schema to extend — the closest real surface is the `test-run` event-type / `payload` convention. Plus the reflexive-release caveat (the introducing release itself exempt) and the reference-durability Class-V interaction with that exact clause.

---

### Dependency Graph

**In-release (directional):**

```
#24 (foundation: documents constraint, authors ### Per-Account Usage Window Constraint subsection)
   │
   │  authors-the-section-that ──▶ #23 references ("references #24's subsection")
   ▼
#23 (active gate: dual-checkpoint enforcement; cites #24's subsection as the
     constraint it operationalizes)
```

- **Edge:** `#24 ──(soft, authoring-precedence)──▶ #23`. Not a hard data-blocker in the "needs-the-code-merged" sense — #23 could be authored against a forward reference — but #24 *authors the canonical home* (`### Per-Account Usage Window Constraint`) that #23's runtime checkpoint points to. Authoring #23 first would mean #23 references a section that doesn't exist yet, or #23 creates a stub #24 then overwrites. Cleanest authoring order is #24 → #23. Both issue bodies and the #772 hub note assert "#24 authors the subsection that #23 references; sequence #24 before #23 unless evidence shows otherwise" — evidence concurs.
- **Composition (informational, not a sequence edge):** #23 ↔ #984 (decomposition-review enforcement, already shipped) share a routing-tree shape (kept/split/escalate ≈ PROCEED/STAGGER/SERIALIZE/DEFER); #984's Stage 5 verdict-routing schema may inform #23's Stage 5 design. #24 ↔ spoke-return-value-compaction work (historical `#2641`, pre-re-versioning) composes informationally only.

**Out-of-milestone edges (informational only — NOT in release scope, do NOT act on):**
- Per #23 native dependency block: **#23 blocks #286**; **#23 relates-to (composes-with) #320, #321**. These are downstream/sibling roadmap edges surfaced for context; they are out of this milestone and this release does not touch them.

---

### Implementation Sequence

Single ordered Engineering sequence (D-C SINGLE topology assumed default; see Recommendations § D-C topology):

| Seq | Issue | Why this position |
|---|---|---|
| **1** | **#24** | Foundation. Authors `### Per-Account Usage Window Constraint` in `hub-spoke-bridge.md § Spoke Launch Mechanisms` + Stage-5-row note + release-personas Stage-5 anti-pattern. Establishes the canonical constraint home #23 will reference. Smaller (`size:L`), narrower blast radius. |
| **2** | **#23** | Active gate. Adds Checkpoint A (`stage-04-planning.md` new phase), Checkpoint B (Procedure 2 + Spoke Launch Mechanisms), the Parallelism-table orthogonality note, the event-log telemetry field, and the release-personas Stage-4 marker. References #24's subsection (now present). Larger (`size:XL`). |

**Rationale for strict serialization (not parallel Engineering):** Under D-C SINGLE, every Engineering commit lands on `release/parallel-launch-quota-budget-gate` sequentially and concurrent chips race on branch HEAD regardless of file-disjointness (`hub-spoke-bridge.md` Procedure 2 § Engineering serialization). Independently, #23 and #24 are NOT file-disjoint — they co-edit three regions (see Contention Map) — so even under D-C OPTION-A they would collide at PR-merge order. Sequence #24 → #23 is the safe order on both axes.

---

### Stage Applicability Matrix

Both issues are `protocol`-class governance/spec changes (text edits to pipeline specs, the hub-spoke bridge, the event-log schema, and persona cards). No application source code, no skill-logic change to a `SKILL.md` body. Stage-5 activation is **all-or-nothing per release** per `planning-solutioning-handoff.md § 2` — ANY trigger on ANY issue activates Stage 5 for the WHOLE release.

**Stage 5 activation evaluation (per `planning-solutioning-handoff.md § 3`, T1–T6, logical OR):**

| Issue | T1 new-file | T2 skill-logic | T3 structural-design | T4 multiple-approaches | Verdict | Rationale (cite per fired trigger) |
|---|---|---|---|---|---|---|
| **#23** | ✓ | ✗ | ✓ | ✓ | **ACTIVATE** | T1: proposes NEW `release/references/standards/quota-budget-protocol.md` (a named protocol/schema — non-trivial). T3: body literally defers the operator-interaction surface "to Stage 5" + carries "Key design question (defer to Stage 5)" — the `deferred to Stage 5` framing auto-fires T3 per § 3. T4: enumerates Option (a)/(b)/(c)/(d) for quota-state capture AND (a)/(b)/(c) FAIL outcomes — explicit multiple-valid-approaches. |
| **#24** | ✗ | ✗ | ✓ | ✓ | **ACTIVATE** | T3: codifies an identifier/threshold convention (quota-budget threshold, usage-window semantics) — a structural design choice constraining downstream behavior. T4: enumerates the load-bearing mitigation candidates (quota-budgeting / window-aware timing / serialize-on-failure / reduce-consumption) with trade-offs. (Even if #24 alone were borderline, the all-or-nothing rule means #23's triggers activate Stage 5 release-wide.) |

**Release-level Stage 5 verdict: ACTIVATE.** ≥2 issues activate → **Collective Review fires after BOTH Stage 5 sub-tasks close**, before any Engineering routing (`hub-spoke-bridge.md` Procedure 2 Step 3).

**Per-stage applicability (Stages 5–13):**

| Stage | #24 | #23 | Justification |
|---|---|---|---|
| **5 Solutioning** | APPLIES | APPLIES | Activated release-wide (above). Parallel-safe across the two issues (output channel = sub-task comment, no contention surface — Parallelism Rules); both Stage 5 chips may run concurrently; Collective Review after both close. #23's Stage 5 is load-bearing: it settles the open D-Gate (quota-state capture surface), the new-file-vs-section decision for `quota-budget-protocol.md`, and the two reconciliation findings below. |
| **6 Engineering** | APPLIES | APPLIES | Write the files. Write-serialized; sequence #24 → #23. |
| **7 Dev Testing** | APPLIES | APPLIES | **Do NOT skip.** Functional impact: these are protocol changes the pipeline *executes* — Checkpoint B alters hub routing behavior; the event-log field alters the writer/reader contract; mirror-pair sync (Check 9) and reference-durability (Class V on the cutover clause) must be verified. DT verifies spec-vs-corpus conformance, the `domain_practice` provenance label presence, and that the two stale-AC reconciliations were applied. Doc/spec-only ≠ no functional impact when the spec is machine-consumed. |
| **8 QA Testing** | APPLIES | APPLIES | Per-criterion AC verdicts against the (reconciled) AC set; confirms Check 9 mirror-pair, link-check (Check 14 / `link-check.yml`), and reference-durability gates are green; confirms the reflexive-exempt clause is correctly anchored. |
| **9 Plan Review** | APPLIES (release-scoped gate) | — | Single per-release GO/NO-GO gate. **Deep** review depth per `novel` class (see Release Class). No per-issue parallelism axis. |
| **10 Dry Run / 11 Snapshot** | APPLIES (compressed) | — | Git-native compression per `release-process.md § Stage Compression`; PR diff IS the dry-run, git history IS the snapshot. Likely a deploy no-op (text-only; no `skills/`, `packages/`, or harness paths — see Rollback). |
| **12 Execute** | APPLIES (release-scoped) | — | Single release-PR merge + signed-annotated tag. **Per #769 (filed at v1.13 close): Stage 12 / A6.5 MUST re-verify the version/identity is still unclaimed before merge** — directly relevant given the v1.12→v1.13 collision precedent and this release's version-less re-version. |
| **13 Close** | APPLIES (release-scoped) | — | Write-serialized; single Stage 13 chore PR (RELEASE_LOG row + visible-H4 Deployment Log + INDEX + DIGEST + RELEASE_NOTES + CHANGELOG). Register the `[CALIBRATE-AFTER-3]` triggers both issues require. 30-day outcome window (`novel`). |

**No stage skipped.** Justification for not skipping 5 and not skipping 7/8 is given inline above (Stage 5: explicit defer-to-Stage-5 framing + new file + open D-Gate; Stages 7/8: the specs are machine-executed, so "doc-only" does not imply "no functional impact").

---

### Contention Map

Grounded in the actual files read. Three regions are co-edited by BOTH issues — this is the dominant planning constraint.

| Affected file (region) | #24 edits | #23 edits | Contention | Notes (verified) |
|---|---|---|---|---|
| **`release/references/how-to/hub-spoke-bridge.md`** | `### Per-Account Usage Window Constraint` NEW subsection under **§ Spoke Launch Mechanisms** (end-of-section, after Counter-example matrix) | Checkpoint B: NEW step in **§ Procedure 2** (the Parallelism Rules region) + pre-launch hook in **§ Spoke Launch Mechanisms** (the `Agent({...})` invocation site at the `### Default` sub-region) | **HIGH — same file, partially same section.** Both touch § Spoke Launch Mechanisms (#24 adds the constraint subsection at end-of-section; #23 adds the pre-launch invocation hook at the `### Default` sub-region). #23 additionally touches § Procedure 2. | Largest single contention surface. "Shared section is NOT the boundary" — git serializes at file content (`hub-spoke-bridge.md` Procedure 2 § File-contention boundary rules). Sequencing #24→#23 lets #23 reference the subsection #24 just authored. #24's end-of-section placement (P-A) is disjoint from #23's `### Default`-region hook, minimizing rebase friction. |
| **`release-process.md § Procedure 2 § Parallelism Rules`** (both bodies cite `release/governance/release-process.md` + a `.claude/rules/` mirror) | Stage-5-row note: "subject to per-account 5-hour usage-window envelope…" | Orthogonality note: "parallel-safe is coordination semantics, not quota/usage-window semantics; the usage-window gate runs orthogonally" + parallelism-table quota-gate clause | **HIGH (and FLAGGED — premise stale).** Both target the SAME Parallelism Rules table. **BUT: that table does NOT exist in `release/governance/release-process.md`** (grep over the 607-line file: zero hits for `parallel-safe` / `Parallelism Rules`). The canonical table lives ONLY in `hub-spoke-bridge.md` Procedure 2 Step 5. See Risk R-7 + Recommendations. | The intended edit collapses INTO the `hub-spoke-bridge.md` contention above. No separate `release-process.md` edit is needed for the table; the governance file may at most get a one-line pointer (a #23 nicety, not #24 scope). Resolve at Stage 5. |
| **`release/references/specs/release-personas.md`** | Stage **5** persona: add anti-pattern "does not assume parallel-safe means usage-window-free" | Stage **4** persona: add behavioral marker for quota-budget estimation; hub Procedure 2 ongoing-gate discipline | **LOW — different persona cards (Stage 5 vs Stage 4 H2 sections).** Disjoint regions of the same file. | Same-file but non-overlapping H2s; still serializes at git push under D-C SINGLE, but zero merge-conflict risk. |
| **`release/references/pipeline/stage-04-planning.md`** | — | Checkpoint A: NEW phase (A9 Quota-Budget Pre-Check) in Phase A region + `### Quota Budget` plan-output section | **NONE (#23-only).** | #23 sole editor. The current spec has A1–A5 + A0/A0.5/A0.6 phases; the "A9 / A4.5" naming and the A1/A4/A8 references in #23's body are illustrative — reconcile the actual phase label against the live phase set at Stage 5. |
| **`release/references/standards/pipeline-event-log-schema.md`** | — | Extend `spoke-completion` event with optional `tokens_used` field | **NONE (#23-only) — and FLAGGED (premise stale).** | **There is no `spoke-completion` event_type or subtype.** The 10-value event-type enum (§3) has no per-spoke completion event; `actor` already carries `spoke:#N`. Closest real surface = the `test-run` event-type (§3) + its `payload` convention (suite specifics in `payload`, no new columns). See Risk R-8 + Recommendations. |
| **NEW: `release/references/standards/quota-budget-protocol.md`** | — | Possible NEW canonical spec for the dual checkpoint | **NONE (net-new).** | Stage 5 decides new-file-vs-section-in-`stage-04-planning.md`. New file ⇒ confirms `novel` class trigger (a). |
| **`RELEASE_LOG.md` `[CALIBRATE-AFTER-3]`** | register cumulative-draw-budget calibration | register parallel-batch-size + per-spoke-cost calibration | **LOW — append-pattern.** | Both append calibration triggers at Stage 13; append-pattern ⇒ low merge-conflict risk but still commit-serialized. Ref-permitted ledger surface (version/issue refs native here). |

**Net contention picture:** the real, load-bearing overlap is **`hub-spoke-bridge.md`** (both issues, partly same section) and **`release-personas.md`** (both issues, disjoint sections). The two "shared" surfaces the issue bodies emphasize most — the `release-process.md` Parallelism table and the `spoke-completion` event — are BOTH stale premises that dissolve on reconciliation. This materially de-risks the merge picture but requires a Stage 5 correction pass.

---

### Risk Register

| ID | Category | Risk | Severity | Owner | Mitigation |
|---|---|---|---|---|---|
| **R-1** | Reflexive-release | **This release edits the very parallel-launch policy the pipeline uses to launch its own spokes.** If the new quota gate / mitigations were applied to THIS release's Stage 5/7/8 batches mid-flight, the rule would be firing on its own bundling — a reflexive-pipeline loop. | MODERATE | Hub | Both issue bodies + the platform's standing reflexive-exempt discipline require an "introducing release itself is exempt" clause anchored to the introducing-release merge SHA. This release's spokes run under the PRE-gate behavior (no quota gate). The gate binds releases entering the pipeline strictly AFTER the introducing-release merge SHA. (Independently, A9 below shows this release's own profile is PASS anyway — so the exemption is correctness-of-principle, not a safety crutch.) |
| **R-2** | Reference-durability ✕ cutover-anchor | The mandated "introducing release itself is exempt" clause is **exactly the construct the reference-durability Class-V detector flags** — "prose that says a rule applies to releases after a given version, or that a given version is itself exempt" rots on renumber and is flagged on any net-new/modified durable-corpus line. The cutover clause and the durability rule are in direct tension. | MODERATE | Stage 5 design + Engineering | Resolve the form at Stage 5 (D-Gate candidate). Settled (Stage 5 rev-2 / Deviation Log b): author the cutover with NO literal version token — *"applies to releases entering the pipeline on or after this constraint's introducing-release merge SHA recorded in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`; the introducing release itself is exempt"* — the markerless idiom already used by `release-personas.md` § Stage 5. The detector does not match the no-version-token form. The reference-durability hook fires when the plan/spec file is written → DT must confirm green on the added lines (do not forecast from an assumed marker; `hub-spoke-bridge.md` does NOT carry `allow-version-ref`). The version-less re-version makes a bare-version anchor moot anyway; SHA-anchor is the durable form. |
| **R-3** | Dependency | Authoring #23 before #24 leaves #23 referencing a `### Per-Account Usage Window Constraint` subsection that does not yet exist. | LOW | Hub | Sequence #24 → #23 (Implementation Sequence). Enforced by write-serialization regardless. |
| **R-4** | Contention | Both issues edit `hub-spoke-bridge.md § Spoke Launch Mechanisms` (#24 adds the constraint subsection at end-of-section; #23 adds the pre-launch hook at the `### Default` sub-region). Concurrent Engineering chips would collide. | MODERATE | Hub | D-C SINGLE write-serialization + explicit sequence #24→#23 + disjoint sub-region placement (P-A). Hub refuses concurrent Engineering chips touching the same file (Procedure 2 File-contention boundary rules). |
| **R-5** | Scope (over-scope) | #23 is `size:XL` and spans 5+ regions across pipeline spec, hub-spoke bridge, event-log schema, personas, + a possible NEW protocol file. Risk of an oversized single Engineering chip. | MODERATE | Stage 5 / operator | Stage 5 may recommend decomposing #23's Engineering into ordered commits (Checkpoint A first, then Checkpoint B, then telemetry) — same routing-tree family as #984 decomposition-review. Not a split of the *issue*; a sequencing of its commits. Flagged for operator at Collective Review scope-lock. |
| **R-6** | Rollback complexity | Multi-file protocol change across two issues; if a defect surfaces post-merge, the gate logic (Checkpoint B) is behavioral and interacts with live hub routing. | LOW–MODERATE | Operator (Stage 12) | Text-only diff ⇒ single `git revert -m 1` of the release PR fully reverts; no data migration; almost certainly a deploy no-op (no `skills/`/`packages/`/harness paths — mirrors v1.13). Reversibility **CHEAP**. The behavioral risk is bounded because the gate is additive (PRE-behavior is "launch all N"; the gate only adds budget/timing/serialize/defer branches). |
| **R-7** | Stale AC / spec-vs-reality | **Both issue bodies + #772 assert a `release-process.md § Procedure 2 § Parallelism Rules` table that does not exist** (the table is in `hub-spoke-bridge.md` only). Building to the AC as-written produces a spec-vs-reality defect (the exact failure class `release-personas.md` Stage 5 warns about — "invented canonical values that diverge from current state caught at Stage 7 DT or later"). | HIGH | Stage 5 (G-PL1 / A0.5 AC-currency) | Reconciled at Stage 5 Phase A0.5 AC-currency gate (route Tier 1 [ADJUST] — `gh issue edit --body` + this deviation-log entry). The Parallelism-table edit collapses into the `hub-spoke-bridge.md` edit; the `release-process.md` governance file gets at most a one-line pointer (or nothing). The `.claude/rules/` mirror does not exist in the tracked tree — the source-of-truth is `release/governance/`; Check 9 mirror-pair concern applies only to files that actually have a deployed mirror. |
| **R-8** | Stale AC / schema | #23 AC "extend `spoke-completion` event with optional `tokens_used` field" presumes an event that **does not exist** in `pipeline-event-log-schema.md`. | HIGH | Stage 5 (A0.5 / design) | Reconcile at Stage 5 (#23 scope). The real design choice: either (a) add a NEW `event_type`/subtype for spoke completion (governance change — adding a subtype requires Tier 2/3 per the schema's own rule), or (b) carry `tokens_used` in the existing `test-run` event's `payload` (the schema's established "specifics live in payload, no new columns" pattern), or (c) a new `spoke-completion` event_type. This is a structural-design decision (T3) — properly a Stage 5 D-Gate, not a mechanical field-add. |
| **R-9** | Audit-baseline | A9 quota pre-check and the Cross-PR overlap audit (A4) presume a population (parallel-eligible spokes / concurrent PRs) that is observably small/empty at this commit. A later concurrent release could change the picture. | LOW | Stage 4/9 | Per audit-baseline discipline: A9 verdict (below) is pinned to the current bundle profile (2 issues, ≤2 parallel-eligible per stage) at this assessment. Re-check at Stage 9 / Stage 12 A6.5 (the v1.13 precedent: a concurrent release merged into the branch pre-Stage-12). The version-less re-version is itself a consequence of this risk class (v1.15–17 claimed by concurrent releases). |

---

### Recommendations

#### 1. Release Class declaration — D-ReleaseClass D-Gate

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke-proposed class + trigger-condition evidence per `release/references/specs/release-class-taxonomy.md § Class Enum`. Milestone description currently carries NO `## Release Class` H2 section — this Stage 4 proposes it for operator render at Stage 3 Phase B3 equivalent / Phase B approval.
**Gate decision:** Choose between (A) `routine`, (B) `novel`, (C) `cross-cutting`, (D) `hotfix`.
**Proposed class: (B) `novel`.**
**Trigger-condition evidence (per § Class Enum, multi-trigger resolution `cross-cutting` > `novel` > `routine`):**
- **`novel` trigger (a) FIRES:** #23 introduces ≥1 new reference doc — `release/references/standards/quota-budget-protocol.md` (Stage 5 confirms new-file-vs-section, but the proposal is a net-new canonical spec).
- **`novel` trigger (b) FIRES:** ≥1 D-class decision in the release plan — the open quota-state-capture D-Gate (deferred to Stage 5) + this D-ReleaseClass + the durability/cutover-form D-Gate (R-2).
- **`cross-cutting` checked and does NOT fire:** trigger (a) needs ≥3 `pipeline/stage-*.md` files — this release touches exactly ONE (`stage-04-planning.md`). Trigger (b) needs ≥3 of {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, RELEASE_LOG.md, hub-spoke-bridge.md, gate-criteria-spec.md, release-process.md} — this release touches `hub-spoke-bridge.md` (1), arguably `release-process.md` (collapses to a pointer or nothing per R-7), and `RELEASE_LOG.md` (calibration-register, a ledger append, not a governance-rule edit). That is 1–2 genuine governance-surface edits, below the ≥3 threshold. Trigger (c) needs ≥3 in-bundle compositional edges — there is ONE (#24→#23). So `cross-cutting` is correctly NOT selected (avoids the anti-pattern "classifying a single-stage-spec-edit release as cross-cutting").
- **`routine` does NOT fit:** new file added (disqualifies trigger (c) "zero new files") and D-class decisions present (disqualifies trigger (d) "zero new D-class decisions").
- **`hotfix` does NOT fit:** no P1/P2 defect against a deployed release; no trailing-patch version; corrective-scope does not dominate (this is preventive protocol work).

**Differentiation posture (per § Per-Class Mapping, `novel` column):**
- Engagement density: **Standard** (per-D-decision Operator Decision Gate + per-Stage-5 Decision Briefing on completion).
- Stage 9 Plan Review depth: **Deep** (Collective Review N-way consistency + cross-D upstream-compat scan + design-spec conformance; blast-radius assessment of the behavioral routing change).
- Stage 5 activation bias (OPTIONAL): **ALL** (cross-issue compositional surface — the #24↔#23 reference contract + the two reconciliation findings surface design questions; consistent with the already-ACTIVATE verdict).
- Stage 13 outcome-window (OPTIONAL): **30-day** (preventive gate; success = "future N≥4 batches no longer half-fail" observed over a window, not at deploy instant).

**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH — re-classifiable later with operator approval per `release-class-taxonomy.md` Re-Classification Protocol; cheaper-to-stricter (`novel`→`cross-cutting`) is CHEAP/HIGH if Stage 5 widens blast radius.

**Decision-discipline mechanisms applied (D-class decision → M1 / M2 / M3 per § 3 triage):**
- **M1 Localization Check:** Class triggers read against the *current* corpus, not the issue-body assertions — verified the actual `pipeline/stage-*.md` touch count (1, not ≥3) and the actual governance-surface touch count (≤2) against live files; this is what demotes the intuitive "big XL protocol change = cross-cutting" read to `novel`. The reconciliation findings (R-7/R-8) are themselves M1 sub-mechanism (Audit-Snapshot Reconciliation) hits: the issue bodies are 2026-05-25 artifacts predating the current corpus state.
- **M2 Opposing View:** The strongest opposing view is **`cross-cutting`** — "this modifies the hub routing engine + a pipeline stage + the event-log contract + two persona cards; that *feels* cross-cutting." Rebuttal grounded in the enum's own anti-pattern: `cross-cutting` is defined by *breadth thresholds* (≥3 stage files / ≥3 governance surfaces / ≥3 edges), and this release clears none of them — it is *deep in one stage and one bridge doc*, which is the `novel` shape. The opposing view does not change the recommendation but is recorded; if Stage 5 promotes the new-file to ALSO edit ≥2 more stage specs, re-render to `cross-cutting`.
- **M3 Pattern Cache Scan:** Applicable confirmed patterns cited — `feedback_verify_before_recommend` / M1 Audit-Snapshot sub-mechanism (drove R-7/R-8 reconciliation: verify AC premises against canonical source before building); `feedback_release_ops_intake_pre_rendered_artifacts` (inverse check — confirmed these issues are NOT already-shipped: grep shows no quota-gate content in current `hub-spoke-bridge.md`/`stage-04-planning.md`, so this is genuine net-new work, not verify-and-close); `feedback_reconcile_dont_annotate` (the stale ACs get reconciled to current state at Stage 5, not annotated-and-deferred).

---

#### 2. Identity + cutover-anchor recommendation

**Recommended identity: VERSION-LESS (slug `parallel-launch-quota-budget-gate`).**
- The Stage 4 plan originally proposed `v1.15` (latest mainline at plan time = v1.14). During the pipeline run, **v1.15 / v1.16 / v1.17 were claimed by concurrent releases** (confirmed: `release/releases/plans/v1.16_RELEASE_PLAN.md` and `v1.17_RELEASE_PLAN.md` exist on the tree). Rather than re-chase a moving version integer (the v1.12→v1.13 collision class, #769), this release adopts the **version-less slug identity** already in use by sibling releases (`adapter-config-foundation`, `corpus-durability-enforcement`, etc.). See Deviation Log item (a).
- The **`v12.13.1` anchor hardcoded in both issue bodies is from the pre-2026-06 re-versioning scheme** and is reconciled everywhere it appears as a load-bearing anchor (cutover clause, "v12.13.1 itself exempt", `[CALIBRATE-AFTER-3]` calibration baselines) to the no-version-token introducing-release / SHA form. This is a Stage 5 AC-currency reconciliation item alongside R-7/R-8 (Deviation Log item b).

**Reconciled cutover-anchor form (settled at Stage 5 rev-2):** Author the cutover with NO literal version token, anchored to the introducing-release merge SHA, stating the spec rule unconditionally — *"Applies to releases entering the pipeline on or after this constraint's introducing-release merge SHA recorded in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`; the introducing release itself is exempt (reflexive-pipeline-loop discipline)."* This is the markerless idiom already used by `release/references/specs/release-personas.md` § Stage 5. Keep the load-bearing anchor as the SHA (durable across renumber); name no version.

**Reference-durability flag (REQUIRED surface):** The reconciled cutover clause is precisely what the **reference-durability Class-V version-cutover-apparatus detector** keys on ("prose that says a rule applies to releases after a given version, or that a given version is itself exempt … flagged on any net-new/modified durable-corpus line"). The no-version-token form (above) does NOT match the detector's version-apparatus signature, so no `allow-version-ref` marker is needed and none is authored. `hub-spoke-bridge.md` does NOT currently carry an `allow-version-ref` marker (head L1 = `allow-link`, L2 = `repo-integrity: allow-issue-ref`) — do not assume one. The reference-durability hook fires when the spec/plan file is written → **Stage 7 DT MUST confirm green** on the added lines (do not forecast green from an assumed marker — rev-1's error). Fallback if the detector unexpectedly flags the no-version-token form: add `<!-- reference-durability: allow-version-ref -->` once in the file header.

---

#### 3. Merge/split recommendation — KEEP SEPARATE, sequence #24 → #23

**Recommendation: keep #23 and #24 as two separate, sequential issues. Do NOT merge.**

**Rationale:**
- **Clean foundation→gate dependency.** #24 = *what the constraint is* (documentation + canonical subsection); #23 = *the active enforcement that operationalizes it*. They are conceptually distinct deliverables with a directional authoring edge, not two halves of one atomic change. The platform's own framing (#772 hub note, both bodies) treats them as siblings with #24 first.
- **Shared-file contention does NOT argue for merge.** It is fully handled by D-C SINGLE write-serialization + the #24→#23 sequence. Merging would not reduce the edit surface; it would only lose the reviewable foundation/gate boundary and produce one oversized `size:XL+L` chip (worsening R-5).
- **Different blast radii / review needs.** #24 is narrow documentation; #23 is behavioral (alters hub routing) + introduces a new file + carries the open D-Gate. Keeping them separate lets Stage 9 review the gate logic against a settled foundation.
- **Counter-consideration acknowledged:** the two co-edit `hub-spoke-bridge.md § Spoke Launch Mechanisms` so tightly that an Engineering author will have both files open at once. That argues for *adjacency in sequence* (which the plan gives: #24 immediately then #23), not for *merging the issues*. The D-C SINGLE / single-release-PR (D-C SINGLE) topology is the lever for a single review surface — not issue-merge.

**Decision-discipline mechanisms applied (scope-change/merge-split → M1 / M2 / M3 per § 3 triage):**
- **M1 Localization:** the merge-vs-keep call is localized to THIS release's topology (D-C SINGLE) and THIS file-contention picture (verified above) — not a generic "small related issues should merge" heuristic. Under D-C SINGLE the serialization is identical whether merged or sequenced, so the deciding factor is reviewability, which favors keep-separate.
- **M2 Opposing View:** strongest case FOR merging — "they edit the same section of the same file; one PR = one coherent review of the quota feature." Rebuttal: the section co-edit is real but the issues remain conceptually separable (constraint-doc vs enforcement-gate), the merge produces an oversized chip, and the reviewable foundation→gate seam is worth more than a single-PR convenience. Does not change the recommendation; if the operator prefers a single-PR review surface, that is achieved by the SINGLE topology (one release PR for both issues), not by issue-merge.
- **M3 Pattern Cache Scan:** `feedback_issue_creation_duplicate_discipline` (don't collapse distinct tracked scope) and `feedback_hub_spoke_uses_issues_not_chat_prompts` (multi-phase work = issue-per-phase) both favor keep-separate. No confirmed pattern argues for merge.

---

#### 4. A9 Quota-Budget Pre-Check — THIS release's own execution

**Verdict: PASS.**

Per `stage-04-planning.md` / #23 Checkpoint A logic applied to THIS release's own parallel-spoke profile:

| Input | This release |
|---|---|
| Parallel-eligible spoke count per parallel stage | **≤2** — only Stage 5 (×2: #24, #23) and Stages 7/8 (×2) are parallel-safe; everything else is release-scoped (one spoke) or write-serialized. Max concurrent = 2. |
| Cumulative work estimate per batch | 2 spokes × per-spoke startup ≈ negligible against any plausible window envelope. |
| Usage-window envelope | The empirical first-failure was **N=9** spokes near the *tail* of the operator's 5-hour window. N=2 is ~4.5× below that count and a tiny batch unlikely to exhaust a window. |
| Estimated cumulative draw | `cumulative << remaining envelope`. |

**Routing-tree result: PASS** (cumulative << envelope → proceed parallel; no warning, no deferral needed). This release's own Stage 5/7/8 batches may launch in parallel without budgeting deferral or serialization. Note this is *belt-and-suspenders* with the R-1 reflexive exemption: even though the gate this release builds will not bind this release, the release's own profile would pass the gate anyway. **Baseline pin (R-9):** verdict pinned to the current 2-issue bundle at this assessment commit; re-check at Stage 9 / Stage 12 A6.5 if a concurrent release joins the branch.

---

#### 5. Operator Decisions / D-Gates

Surfaced for operator render. D-ReleaseClass (item 1 above) is the first; the remainder are deferred to Stage 5 per the issue contract and the reconciliation findings.

#### D-QuotaStateCapture: How does the hub learn the operator's current quota state? (DEFERRED to Stage 5 — open per #23)
**Gate input:** #23 body explicitly defers this: "Key design question (defer to Stage 5): How does the hub know operator's current quota state?"
**Gate decision:** (a) AskUserQuestion at hub session start capturing `fresh`/`partial-N%`/`near-tail`, propagated with elapsed-time adjustment; (b) per-batch AskUserQuestion before each parallel launch (more friction, more accurate); (c) future platform-side quota API (not queryable from a session today); (d) hybrid — session-start capture + per-batch optional override.
**Blocks:** #23 Checkpoint B operator-interaction surface; the `quota-budget-protocol.md` new-file-vs-section decision.
**Upstream compatibility:** N/A — internal hub-orchestration surface; no skill-authoring surface touched. Upstream compatibility check does not apply.
**Reversibility / Confidence:** MODERATE / MEDIUM — the interaction surface is hard to change once spokes/operators learn it; settle deliberately at Stage 5.
**Recommendation (this spoke):** lean (d) hybrid — session-start capture is low-friction and covers the common case; per-batch override handles the "I just did other work" drift #23 calls out. Settle at Stage 5.

#### D-CutoverAnchorForm: What form does the cutover/exemption clause take, given the reference-durability Class-V detector? (SETTLED at Stage 5 rev-2 — see R-2 / Deviation Log b)
**Gate input:** Reflexive-exempt requirement (R-1) demands an "introducing release itself exempt" clause; reference-durability Class-V flags that exact idiom (R-2).
**Gate decision:** (a) SHA-anchor in spec text + version-in-passing; (b) cutover statement on a ref-permitted ledger surface (RELEASE_LOG) with unconditional spec text; (c) per-file durability override marker.
**Upstream compatibility:** N/A — internal durability convention; no skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH — text form, trivially revisable.
**Settled (Stage 5 rev-2):** the no-version-token introducing-release / SHA form (a refinement of option (a) that names NO version token at all), recording the human-readable cutover on the RELEASE_LOG ledger row at Stage 13 (option (b) combined). The version-less re-version makes this the only coherent form anyway.

#### D-EventTelemetrySurface: Where does `tokens_used` per-spoke telemetry live? (DEFERRED to Stage 5 — surfaced by this plan, R-8; #23 scope)
**Gate input:** #23 AC names a `spoke-completion` event that does not exist in `pipeline-event-log-schema.md`.
**Gate decision:** (a) new `event_type`/subtype for spoke completion (governance change — adding a subtype requires Tier 2/3 per the schema); (b) carry `tokens_used` in the existing `test-run` event `payload` (schema's "specifics in payload, no new columns" pattern); (c) net-new `spoke-completion` event_type with its own subtypes.
**Blocks:** #23 event-log AC; the budget-estimate telemetry consumer.
**Upstream compatibility:** N/A — internal schema; no skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** MODERATE / MEDIUM — schema contract consumed by writer/reader tooling (`append-pipeline-event.sh` / `query-pipeline-event.sh`); changing it later means migrating emitters.
**Recommendation (this spoke):** lean (c) a dedicated `spoke-completion` event_type (cleaner than overloading `test-run`, which is suite-execution-scoped), accepting the governance-change cost the schema requires for new subtypes. Settle at Stage 5 (#23).

**Other operator-judgment items (not full D-Gates, surfaced for awareness):**
- **D-C Branch Topology** (SINGLE vs OPTION-A) — default SINGLE assumed throughout this plan; operator may elect OPTION-A if a single-PR review surface for the quota feature is preferred (SINGLE already gives one release PR for both issues, per item 3 M2).
- **#23 Engineering decomposition** (R-5) — operator confirms at Collective Review whether #23's `size:XL` Engineering runs as one chip or ordered commits (Checkpoint A → Checkpoint B → telemetry).
- **Two stale-AC reconciliations (R-7, R-8)** — route Tier 1 [ADJUST] at Stage 5 Phase A0.5 (`gh issue edit --body` + this deviation-log entry); operator awareness that the issue ACs are amended to match current corpus before Engineering.

---

#### Out-of-scope discoveries (noted, not acted on)
- **R-7/R-8 are spec-vs-reality drift in the issue bodies themselves**, not new corpus bugs — they reconcile within this release at Stage 5. No separate issue needed (the reconciliation is in-scope Stage 5 work).
- **#769** (filed at v1.13 close: Stage 12/A6.5 must verify the version/identity is still unclaimed) is directly relevant to this release's Stage 12 identity-claim step — already tracked; surfaced here as a Stage 12 reminder, no action now. The version-less re-version is itself the mitigation for this risk class.
- The Parallelism Rules table living in only `hub-spoke-bridge.md` while multiple issue authors *believe* it is mirrored in `release-process.md` is a latent documentation-locality confusion; if the operator wants the governance file to carry a pointer to the canonical table, that is a candidate for the #23 edit (a one-liner) rather than a separate issue — Stage 5 decides.

---

### Deviation Log

Departures from the as-filed issue bodies / the as-authored Stage 4 plan, with rationale. Per `core/rules/git-workflow.md` § Parser-clean PR body discipline, no close-family verb precedes any `#N` below.

| # | Deviation | Driver | Rationale |
|---|---|---|---|
| **(a)** | **Version-less re-version: `v1.15` → slug `parallel-launch-quota-budget-gate`.** The Stage 4 plan (#772) and sub-task #781 proposed version `v1.15` and branch `release/v1.15` / plan file `v1.15_RELEASE_PLAN.md`. This release ships **version-less** under the slug identity: branch `release/parallel-launch-quota-budget-gate`, plan file `parallel-launch-quota-budget-gate_RELEASE_PLAN.md`. | v1.15 / v1.16 / v1.17 were claimed by concurrent releases (confirmed: `v1.16_RELEASE_PLAN.md` and `v1.17_RELEASE_PLAN.md` exist on the tree). The #769 version-collision class (v1.12→v1.13) recurred. | Re-chasing a moving version integer is the failure mode #769 names; the slug identity (already used by sibling releases `adapter-config-foundation`, `corpus-durability-enforcement`, etc.) is collision-proof. Every load-bearing `v1.15` anchor in the transcribed plan above is reconciled to the slug / introducing-release-SHA form. |
| **(b)** | **Stage-5 AC reconciliations for #24 (applied this spoke) + #23 (flagged for the #23 spoke).** For **#24**: AC item 2's `release-process.md` Parallelism-table edit target re-points to `hub-spoke-bridge.md` Procedure 2 Step 5 (the table's only home; `release-process.md` has 0 hits); AC item 3's "Check 9 mirror-pair sync" is marked **N/A** (neither `hub-spoke-bridge.md` nor `release-personas.md` is in Check 9's MIRROR_PAIRS set — 7 `core/rules/*` + `release/rules/release-process.md` + the OPERATIONS.md dual-write pair); AC item 4's literal `v12.13.1` cutover token reconciles to the no-version-token introducing-release / SHA form; the Affected-files `release-process.md` / `.claude/rules/` line is corrected (`.claude/rules/` is not a tracked directory; no `release-process.md` edit). The subsection is renamed per the operator's 2026-05-24 Correction comment from `### Per-Account Quota Constraint` → **`### Per-Account Usage Window Constraint`**, and the mitigation framing is re-based from concurrent-peak/stagger to the 5-hour cumulative-usage-window model (stagger demoted to a labeled secondary rate-limit-only note). For **#23**: the parallel `release-process.md`-table / `spoke-completion`-event reconciliations (R-7/R-8) are flagged for the #23 Stage 6 spoke (out of #24 scope). | #24 Correction comment (operator, 2026-05-24: "5-hour usage limit ≠ rate limit"; subsection renamed); independent adversarial review #874 (PRF-1/PRF-2/PRF-3); the Stage 5 rev-2 spec (#780) which is the controlling implementation contract; R-7/R-8 spec-vs-reality findings. | Building to the as-filed ACs would author a note into a table that does not exist and elevate a non-load-bearing mitigation (stagger) for the actual root cause (cumulative usage-window draw). Reconcile-don't-annotate (`feedback_reconcile_dont_annotate`): correct the ACs to current state in the issue body + record here, rather than leaving a contradictory banner. |

---

_Stage 4 Release Planning complete (transcribed). Routing recommendation: **route:stage-5-solutioning** (release-wide ACTIVATE; #24 + #23 Stage 5 chips parallel-safe; Collective Review after both close; two AC-currency reconciliations + three deferred D-Gates carried into Stage 5). Stage 5 rev-2 (#780) and Stage 6 (#24, this commit) executed under the version-less identity per Deviation Log._
