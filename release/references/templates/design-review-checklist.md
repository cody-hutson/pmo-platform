<!-- reference-durability: allow-link -->
# Design Review Checklist — PMO Platform

> **Source:** Stage 5 Solutioning Phase B review surface.
> **Consumer surface:** [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) Phase B.

---

## How to use

This checklist materializes Stage 5 Phase B review per [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md). Sections 1–5 are evaluation activities run by the Stage 5 spoke against its own draft output before posting; Section 6 is the operator sign-off gate at Phase B. Pass criteria require explicit evidence citation in the spoke output Evidence section — bare ticks without evidence are theater per the governance-theater discipline and are detectable post-hoc by reviewing cited evidence.

| When | Who | Output |
|---|---|---|
| After Phase A § A5 (ADR drafting complete) | Stage 5 spoke (self-review) | Spoke output Evidence section cites each PASS with source link |
| Phase B (operator review) | Operator | Section 6 sign-off line completed |

**Format conventions:**
- `- [ ]` GitHub task-list checkboxes (tick inline as `- [x]`).
- Each section terminates in `**Pass criterion:**` (what counts as PASS) and `**Fail action:**` (where failure routes).
- Cross-references link to canonical sources; this checklist consumes — does not redefine — QC2, schema v1, reversibility tiers, D-Gate Template, M2 concreteness rules.

---

## Section 1 — Blast radius

Consumes blast-radius CLI output per [`release/references/protocols/blast-radius-protocol.md`](../protocols/blast-radius-protocol.md). Schema v1 fields cited: `stats.first_order_count`, `first_order[].path`, `first_order[].reference_count`, `first_order[].matches`.

**Trigger:** Stage 5 Phase A § A3 runs the impact-analysis method selected at Phase A3.1 per [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) against each issue's target file(s). For doc/governance/pipeline-internal deliverables (the DEFAULT) the method is `release/tools/blast-radius.sh` and its schema-v1 output is the input to this section. For a non-doc deliverable whose A3.1 selector chose a domain-appropriate fan-out method (code import-graph / component dependency-tree / solution-component graph), the input is the **opt-out record** per [`blast-radius-protocol.md`](../protocols/blast-radius-protocol.md) § 12 — and checks 1.1–1.3 are satisfied by that record's lines in lieu of the schema-v1 fields, as noted per check below. (The opt-out record is a within-A3 substitution of the *instrument*, not a whole-issue `SKIP`: A3 still fired and design still happened.)

**Reviewer checks:**

- [ ] **1.1** CLI invocation captured in spoke output Evidence section (cite exact command, `cli_version`, `schema_version`). *Non-markdown-method accommodation:* when the A3.1 selector recorded a method other than `blast-radius.sh`, this check is satisfied instead by the opt-out record's `Method selected` + `blast-radius.sh applicability: NOT APPLICABLE` lines plus the `Fan-out performed` command-or-manual-trace line (§ 12) — there is no `cli_version`/`schema_version` to cite because the markdown CLI was correctly not run.
- [ ] **1.2** `first_order_count` value reviewed; impact-classification tier applied per [`blast-radius-protocol.md`](../protocols/blast-radius-protocol.md) §"Impact classification rules" (cosmetic ≤1 / behavioral 2–5 / structural ≥6 OR any reference from a critical file). *Non-markdown-method accommodation:* the § 5 tiers are domain-agnostic — when a non-default method was used, this check is satisfied by the opt-out record's `Impact classification` line computed from the domain-method's first-order count (the same Cosmetic/Behavioral/Structural tiers applied to the import-graph / component-tree / solution-component fan-out).
- [ ] **1.3** Each entry in `first_order[]` triaged: `path` + `reference_count` + a sample `matches[]` snippet quoted in spoke evidence for any path with `reference_count ≥ 3`. *Non-markdown-method accommodation:* when a non-default method was used, this check is satisfied by the opt-out record's `Fan-out performed` line enumerating the first-order consumers (top referrers named), which is the domain-method analogue of the `first_order[]` triage.
- [ ] **1.4** If classification is **structural**: D-class operator decision rendered per [`hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) D-Gate Template — does NOT auto-pass.
- [ ] **1.5** If `first_order_count` exceeds the 90th-percentile baseline for similar-scope changes: flag in Section 5 Risk Register as contention risk.
- [ ] **1.6** *(Conditional — fires only when the change moves or renames at least one durable-corpus file.)* The spoke output contains the complete doc-corpus-reorg ref-form table per [`doc-corpus-reorg-ref-forms.md`](../protocols/doc-corpus-reorg-ref-forms.md) — all six forms (F1 module-rooted literal · F2 relative-inbound · F3 root-escape · F4 mover-internal-outbound · F5 retained-sibling→mover · F6 governed mirror-pair) present, each with a reproducible sweep command and per-occurrence disposition (REWRITE / N/A / MIRROR-SYNC), and a verdict line. This is the confirmation gate: its presence is what lets the exit gate **confirm** completeness-by-construction rather than **discover** an undercount after the rewrite is built. When no file moves, check 1.6 is OMITTED entirely (not marked "N/A") — omission is the non-ceremony signal, the same omission discipline § 5.6 and check 3.5 follow.

**Pass criterion:** Checks 1.1–1.3 all PASS — satisfied either by the `blast-radius.sh` schema-v1 fields (the DEFAULT doc/governance/pipeline-internal path) OR, when the A3.1 selector recorded a non-markdown method, by the § 12 opt-out record's `Method selected` / `applicability` / `Fan-out performed` / `Impact classification` lines (the non-markdown-method accommodation per check). A populated opt-out record IS a PASS; a non-default method does not fail Section 1 for the absence of schema-v1 fields. Checks 1.4–1.5 conditionally PASS (only-if-applicable, explicitly marked N/A with rationale when not triggered). Check 1.6 conditionally PASS — when a durable-corpus file moves or is renamed, the six-form table (F1–F6) must be present and grounded; when no file moves, check 1.6 is OMITTED.
**Fail action:** Block Engineering until first-order findings are documented in spoke output Evidence — for a non-markdown method, the failing condition is an opt-out record missing the `Fan-out performed` line (no command and no manual-trace description), which is an incomplete A3, not the mere absence of `blast-radius.sh` schema-v1 fields. When check 1.6 is triggered and the six-form ref-form enumeration is absent or ungrounded (re-running a cited sweep returns rows the table does not enumerate), block Engineering authorization until the complete enumeration is present; return to Phase A3.2.

---

## Section 2 — Dependency validation (QC2)

Materializes Checkpoint 2 from the QA Checkpoint Framework per [`release/governance/release-process.md`](../../governance/release-process.md) (QC2-01..QC2-04). This section does not redefine QC2 — it routes the existing framework checks into the structured review surface.

**Trigger:** Stage 5 Phase B (per [release-process.md](../../governance/release-process.md) QC2 framework). Mirrors QC2-01..QC2-04 from the framework.

**Reviewer checks:**

- [ ] **2.1 QC2-01** — All declared dependencies still in compatible states (`Approved` / `Bundled` / `In Progress` / `Done`). Verified via `gh issue view <dep>` for each `#N` reference in the issue body.
- [ ] **2.2 QC2-02** — No circular dependency chains introduced by this design (visual trace: `A → B → C ↛ A`).
- [ ] **2.3 QC2-03** — Cross-file impact: files in blast radius (Section 1 `first_order[].path` + Section 3 `second_order[].path`) are not claimed by conflicting design specs from the same release. Cross-reference Stage 4 release plan's Contention Map.
- [ ] **2.4 QC2-04** — New implicit dependencies discovered during this solutioning are registered in the spoke output Evidence section.

**Pass criterion:** All 4 PASS.
**Fail action:** Block Engineering; return to hub for dependency resolution per the QC2 escalation rule in [release-process.md](../../governance/release-process.md).

---

## Section 3 — Cross-file impact

Consumes second-order traversal output from `blast-radius.sh`. Schema v1 fields cited: `stats.second_order_count`, `second_order[].path`, `second_order[].via`, `second_order[].depth`, `second_order[].is_mirror`, `stats.filtered_mirrors`, `filtered_mirrors_detail[]`.

**Reviewer checks:**

- [ ] **3.1** `second_order_count` value reviewed; chains of `depth > 2` traced explicitly. Each chain documented in spoke evidence as `target → via → second_order_path`.
- [ ] **3.2** For each entry in `second_order[]`: `via` chain validated against current main (the file at `via` still exists; the reference is still present).
- [ ] **3.3** Mirror-pair handling: `stats.filtered_mirrors` value reviewed; if `> 0`, audit `filtered_mirrors_detail[]` for any non-mirror false-positive (path-topology match in both `core/rules/` AND `core/rules/` per [`core/rules/skill-deployment.md`](../../../core/rules/skill-deployment.md) Check 9 convention).
- [ ] **3.4** For each `second_order[]` entry with `is_mirror: false` whose `via` is a critical file (CLAUDE.md, `core/rules/*`, `deploy.sh`, any SKILL.md, any governance/schema doc): treat as **structural** per Section 1's impact-tier rule; flag in Section 5 Risk Register.

**Pass criterion:** All 4 PASS.
**Fail action:** Block Engineering; return to Phase A § A3 for deeper traversal or mirror-handling refinement.

---

## Section 3.5 — Cascade-completeness sweep

Applies when the Stage 5 spec includes a count update, enumeration update, or threshold/version-narrative change per [`stage-05-solutioning.md § 5.6`](../pipeline/stage-05-solutioning.md). When no triggering update is in spec scope, this section is **OMITTED entirely** (not filled with "N/A") per [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) § 5 G2 ceremony-management guard — omission IS the non-ceremony signal.

**Trigger:** Stage 5 Phase A4 spec contains a T1 (numeric count update), T2 (enumeration update), or T3 (threshold/version narrative) change to any file in the affected-files matrix.

**Reviewer checks:**

- [ ] **3.5.1** Spec includes a `### Cascade-Sweep` block per § 5.6 schema (one row per (file × OLD-value × occurrence)).
- [ ] **3.5.2** Sweep command(s) section names the exact `grep -nE` invocation per (file × value) pair; commands are reproducible (operator can re-run).
- [ ] **3.5.3** Sweep table is empirically grounded — re-running the cited `grep` against the release branch returns the enumerated rows (verify a 2-row sample for any spec with ≥5 sweep rows; full re-run for any spec with <5 sweep rows). Any grep hit not enumerated in the table is a finding.
- [ ] **3.5.4** Every row carries a disposition (UPDATE / PRESERVE / N/A) AND a rationale; PRESERVE rationales explicitly name the preservation reason (e.g., historical snapshot, intentionally retained metric, semantic coincidence).
- [ ] **3.5.5** No row is marked N/A without rationale; sweep verdict line (`<UPDATE count> / <PRESERVE count> / <N/A count>`) is present.

**Pass criterion:** All 5 checks PASS when triggered. When NOT triggered (spec contains no T1/T2/T3 update), section is OMITTED entirely.
**Fail action:** Block Engineering until Cascade-Sweep block is completed per § 5.6 schema; return to Phase A4 spec authoring.

---

## Section 4 — Design coherence

Consolidates architecture alignment, pattern consistency, ADR quality, and within-release cross-issue coherence into a single coherence-evaluation surface. ADR-specific check fires only when an ADR was drafted in this spoke.

**Reviewer checks:**

- [ ] **4.1 Architecture alignment** — Design follows platform conventions cited explicitly (e.g., bash-native per [`deploy.sh`](../../../core/deploy/deploy.sh) / [`account-switcher.sh`](<OPERATOR_INSTANCE_HARNESS_PATH>/account-switcher/account-switcher.sh); 6-tier governance file map per [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>) "Governance File Map"; mirror-pair posture per [`core/rules/skill-deployment.md`](../../../core/rules/skill-deployment.md)). "Follows conventions" alone is not load-bearing — name the convention.
- [ ] **4.2 Pattern consistency** — Design reuses existing patterns where possible (e.g., new template uses sibling-template structure from [`operations/templates/`](.); new protocol uses sibling-protocol structure from [`release/references/protocols/`](../protocols/)). Cite the sibling reference. Net-new patterns documented with rationale for non-reuse.
- [ ] **4.3 ADR quality (conditional)** — If any ADR drafted in this spoke: trade-offs substantive (≥3 alternatives evaluated per [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) M2 Opposing View concreteness rules); consequences documented; `Reversibility / Confidence` label present per [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>) Reversibility discipline.
- [ ] **4.4 Within-release cross-issue coherence** — Design does not conflict with other Sub-slice spokes' designs in the same release (pre-Collective-Review check per [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) Release-Level Checkpoint).
- [ ] **4.5 R7 stale-path discipline** — Any cited path verified to exist on current main per the verify-before-recommend discipline. Deleted-and-split files redirected to current canonical location.
- [ ] **4.6 Domain-best-practice conformance** — Assess the design against the TARGET domain's authoritative practice, not only the internal conventions checks 4.1/4.2 cover. This check is a WIRING of the shipped applicability framework — it invokes, and does NOT redefine, [`core/disciplines/applicability-framework.md`](../../../core/disciplines/applicability-framework.md) §2 Applicability Profile, §3 Contraindication Catalog (CI-*), and the §4 precedence ladder, plus the per-domain guides under [`core/standards/domain-best-practices/`](../../../core/standards/domain-best-practices/). Procedure:
      - **Resolve the guide.** Read the deliverable's domain class from the `domain:` field inside the release plan's `domain_practice` label (the abstract domain signal the Stage 4 §5.7 substrate populates in EVERY mode — Mode A, Mode B, and the pipeline-internal exemption — so the class is always present; this check consumes that field, it does not re-derive the domain). The guide is `core/standards/domain-best-practices/<domain>.md`. If no guide exists for the resolved domain → mark **`DOMAIN-PRACTICE-NOT-ASSESSED`** naming the unresolved domain (an honest signal, NEVER a silent PASS) and STOP — the missing guide is a corpus-gap demand-signal, not a design defect.
      - (a) **Applicability (§2).** Confirm the guide's Applicability Profile `APPLIES-WHEN` predicate holds for this deliverable; if it does not, mark NOT-APPLICABLE with the reason and STOP.
      - (b) **Contraindication (§3).** Run the `applicability-framework.md` §3 Contraindication check: for each CI-* the guide's `CONTRAINDICATED-WHEN` names, evaluate the §3 Context predicate against the deliverable's K2/K3 context. Any CI-* that FIRES on a practice this design applied is a FINDING, not a pass (cite the CI-ID and the predicate evaluated).
      - (c) **Conformance.** Score the design against the guide's practice dimensions ("what good looks like" per dimension); shortfalls are findings.
      **Governance / pipeline-internal deliverables run the FULL walk — no exemption short-circuit.** A governance deliverable carries `domain: governance`; resolve `core/standards/domain-best-practices/governance.md`, confirm `APPLIES-WHEN`, and run the §3 check (the governance guide's contraindication is CI-3 — research-grade / formal-audit practices imposed where lightweight self-review suffices). A well-behaved governance design does NOT trip CI-3 and meets the compliance/auditability/traceability dimensions → PASS by ASSESSMENT, not by bypass. The Stage 4 §5.7 "sourcing-exempt, not classification-exempt" reconciliation makes this consistent: a pipeline-internal release skips external *sourcing*, but its `domain:` class still resolves the governance guide, which IS the encoding of the platform's own internal-deliverable practice. (The `N/A — pipeline-internal release` token governs the Phase A *provenance* exemption only; it does NOT exempt this conformance check.)
      This check consumes — does not redefine — the Applicability Profile schema ([`applicability-framework.md`](../../../core/disciplines/applicability-framework.md) §2), the Contraindication Catalog (§3), the precedence ladder (§4), and the per-domain guides ([`core/standards/domain-best-practices/`](../../../core/standards/domain-best-practices/)).
      **Cutover (introducing-release-exempt):** Check 4.6 applies to releases entering Stage 5 design review strictly AFTER this criterion's introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the criterion shipping in a release does not fire on its own Stage 5 (it would assess its own not-yet-shipped rule, a reflexive-pipeline loop); the introducing release's own Stage 5 runs under the rules in force before this check shipped.

**Pass criterion:** Checks 4.1, 4.2, 4.4, 4.5 PASS; check 4.3 conditionally PASS (explicitly marked N/A when no ADR drafted); check 4.6 PASS when a domain guide applies (no fired contraindication, conformance met — including the governance/pipeline-internal case, which runs the full walk against the governance guide rather than short-circuiting) OR explicitly marked `DOMAIN-PRACTICE-NOT-ASSESSED` / NOT-APPLICABLE with the domain named — the not-assessed mark is an honest signal and does NOT block Engineering, but is surfaced forward to Stage 7 Phase C for the conformance assessment.
**Fail action:** Return to Phase A § A2 (architecture alignment) or § A5 (ADR drafting) for refinement. A fired §3 contraindication (4.6b) or a conformance shortfall (4.6c) returns to Phase A § A2 for the contraindicated practice or shortfall to be re-designed.

---

## Section 5 — Risk register

Captures contention, scope, rollback-complexity, and one-way-door risks discovered during solutioning. Reversibility tier + confidence labeling is mandatory per [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>) Reversibility discipline.

**Reviewer checks:**

- [ ] **5.1** Risks identified per category: contention, scope, rollback complexity, schema-lock (if any one-way door).
- [ ] **5.2** Each risk has: trigger condition, owner (default: operator), mitigation, residual risk after mitigation.
- [ ] **5.3** Risks linked to Stage 4 release plan Risk Register (consistent severity labels; no orphan risks introduced at Stage 5 without a Stage 4 anchor or explicit rationale).
- [ ] **5.4** Reversibility tier explicitly stated per [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>) Reversibility discipline (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with confidence (HIGH / MEDIUM / LOW).

**Pass criterion:** All 4 PASS for any risk identified. A "no risks" claim is NOT a valid PASS when blast-radius classification (Section 1) is behavioral or structural — that combination forces honest enumeration; mark FAIL and return to Phase A for risk identification.
**Fail action:** Return to Phase A for risk enumeration.

---

## Section 6 — Engineering readiness — sign-off

This is the gate decision derived from Sections 1–5 — distinct from evaluation. Phase B operator runs this section after the spoke posts its self-reviewed output.

**Reviewer checks:**

- [ ] **6.1** All Section 1–5 pass criteria met OR exception-documented (with operator approval citation linking to the prior decision).
- [ ] **6.2** Implementation-ready spec exists in the "Output for Stage 6" section of spoke output: named files, named edits, named verification gates per [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) Phase A § A4.
- [ ] **6.3** AC enforcement plan present: each issue body Acceptance Criterion has a corresponding Stage 6 verification mechanism (named in the spoke output).
- [ ] **6.4** Skip-stage rationale documented for any stage marked SKIP in the Stage 4 applicability matrix.

**Pass criterion:** All 4 PASS.
**Fail action:** Block Engineering; return spoke output to Phase A for completion or escalate to operator.

**Sign-off:**

```
Reviewed-by: <operator-handle>
Date: YYYY-MM-DD
Outcome: [ ] AUTHORIZE ENGINEERING   [ ] RETURN TO SOLUTIONING   [ ] ESCALATE
```

---

## See also

- [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) — Phase B consumer surface for this checklist; § 5.6 Cascade-Completeness Sweep is consumed by Section 3.5.
- [`release/references/protocols/blast-radius-protocol.md`](../protocols/blast-radius-protocol.md) — impact-classification source consumed by Section 1.
- [`release/governance/release-process.md`](../../governance/release-process.md) — QC2 framework consumed by Section 2.
- [`release/references/how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) — D-Gate Template referenced from Section 1 check 1.4.
- [`core/disciplines/decision-discipline.md`](../../../core/disciplines/decision-discipline.md) — M2 concreteness rules referenced from Section 4 check 4.3.
- [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>) — Reversibility discipline referenced from Section 5 check 5.4.
