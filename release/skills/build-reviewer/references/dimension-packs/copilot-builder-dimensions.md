---
pack_name: copilot-builder
pack_version: "1.0"
applies_to: "Copilot Builder Agent Document Pack (30 documents + 1 derived artifact)"
detection_patterns:
  - "**/Copilot_Builder_Agent_Document_Pack/**"
  - "**/Doc_0[1-9]_*.md"
  - "**/Doc_[12][0-9]_*.md"
  - "**/Doc_30_*.md"
  - "**/Runtime_Constitutional_Minimum_Set.md"
default_when_no_match: false
dimension_count: 12
principal_dimensions_included: false
---

# Copilot Builder Agent — Dimension Pack

Production-readiness review dimensions for the **Copilot Builder Agent Document Pack** — a 30-document + 1 derived-artifact governance framework designed to control how an AI model builds, reviews, remediates, and governs Microsoft Copilot-related work. The pack has been through approximately 8 rounds of remediation.

This pack supplies the 12 domain-specific dimensions plus pack-specific calibration context. The shared review discipline (anti-laziness rules, root-cause requirement, 6-deliverable output structure, reviewer calibration, anti-patterns) and the 3 Principal Dimensions (Operational Awareness, Organizational Leverage, Mentorship & Culture) are inherited from `build-reviewer/SKILL.md` and `core/disciplines/review-discipline-principles.md`.

**Severity scale:** This pack uses the `CS1_LOW` / `CS2_MEDIUM` / `CS3_HIGH` / `CS4_CRITICAL` severity classes from the Copilot Builder framework's own vocabulary (Doc 07 — Source of Truth Register). This is a pack-specific alias over the platform-wide `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` scale defined in `review-discipline-principles.md` § Section 5. Map: `CS4_CRITICAL` ↔ `CRITICAL`, `CS3_HIGH` ↔ `HIGH`, `CS2_MEDIUM` ↔ `MEDIUM`, `CS1_LOW` ↔ `LOW`.

---

## What You Are Reviewing

The document pack consists of the following files, organized by phase:

**Phase 1 — Constitutional Foundation**
- `01_Project_Charter.md` — mission, scope, non-goals, success criteria
- `02_Guiding_Principles.md` — 11 enduring operating principles
- `03_Operating_Model_Overview.md` — control roles, state gates (0 through 5 + 0-R + 0-E), non-self-certification, Builder no-search prohibition, canonical state/enum registry, operational worker model (W1/W2/W3), shared-runtime integrity, escalation logic, autonomy boundaries
- `04_Document_Architecture_and_Reference_Standard.md` — document uniqueness, anti-overlap, direct references, structured hand-off requirements (Rules 1-12), provisional inferred status marking

**Phase 2 — Knowledge and Source Control**
- `05_Knowledge_Acquisition_Plan.md` — acquisition requests, grounding reports, delta refinement, SV-02 execution lock, freshness tiers (F1/F2/F3)
- `06_Knowledge_Domain_Map.md` — knowledge domain taxonomy (KD-01 through KD-06), volatility baselines (VOL_ENDURING, VOL_MANAGED, VOL_RAPID), claim-type mapping
- `07_Source_of_Truth_Register.md` — source classes (S1-S5), conflict types (A/B/C), severity classes (CS1-CS4), inference rules, exact-string pinning, semantic-equivalence pre-classification, materially relied-upon claim definition

**Phase 3 — Standards and Output Control**
- `08_Document_Standards_Manual.md` — document anatomy, lean critical header (5 fields), anti-fabrication policy, transition-key integrity, sidecar JSON expectations, control-bearing wrapper preservation
- `09_Output_Contract_Library.md` — full schemas for OC-09, OC-10, OC-11, OC-12, SV-01, SV-02, LR-01, RCA-01, RM-01, RM-02, plus validator output extension
- `10_Business_Rules_and_Standardization_Policy.md` — strict non-material allowlist, excluded wording classes, semantic-equivalence restriction, hard-zone severity floor

**Phase 4 — Runtime Behavior and Skills**
- `11_System_Instruction_Copilot_Builder_Agent.md` — executive runtime instruction (15+ rules), pre-flight parse, validator dependency, pulse-breaker runtime, quarantine-aware runtime, verify-then-invoke, W3 masked-context rule
- `12_Skill_Principal_Copilot_Builder.md` — Builder execution posture, assumption-isolation (OC-10), zero-TTL write discipline, W2 scope
- `13_Skill_Standards_and_Governance_Reviewer.md` — reviewer routine, payload-to-artifact comparison, semantic audit, modal inspection, exact-string pinning enforcement, assumption-laundering detection
- `14_Skill_QA_and_Regression_Lead.md` — QA execution posture, assumption-isolation validation, logic-laundering detection, freshness-aware QA, provisional diagnostic momentum
- `15_Skill_Root_Cause_and_Self_Healing_Engineer.md` — RCA routine, remediation routine, provisional-hypothesis handling, W3 masked artifact scope, minimal-change bias

**Phase 5 — QA, Regression, Evaluation, Release**
- `16_QA_Strategy.md` — QA test families (9 families), evidence classes, scope selection, outcome model, freshness-aware and assumption-sensitive QA
- `17_Regression_Test_Framework.md` — regression scope classes (R1-R4), hard-zone regression minimums, no-R0 floor, observable-impact routing
- `18_Evaluation_Matrix.md` — automatic fail conditions (including AF-11 logic laundering), hard-gate semantic materiality rule, under-scoped regression consequence
- `19_Release_Gates_and_Exit_Criteria.md` — release blockers, OC-11 visual inspection queue threshold, local-only collision rule, KD-02 lock rule

**Phase 6 — Self-Healing and Remediation**
- `20_Self_Healing_Policy.md` — self-healing eligibility model, remediation authority classes (RH-1 through RH-4), remediation state model, prohibited autonomous conditions, oscillation detection, pulse-breaker integration, ARCHITECTURAL_DECAY terminal routing
- `21_Minimal_Change_Remediation_Standard.md` — minimal-change principles, blast-radius classification, collateral semantic drift rules, hard-zone restrictions
- `22_Root_Cause_Analysis_Framework.md` — causal classification (CC-1 through CC-4), confidence classes, RCA method (8-step mandatory sequence), competing explanation rule, blind clean-basis distinction, disallowed shortcuts

**Phase 7 — Practical Orchestration**
- `23_Copilot_Build_Playbook.md` — verify-then-invoke gate, cold-boot verification, W3 masked artifact procedure, dependency QA (OC-12), expansion cap, validator integration, SV-02 handling, blind review isolation procedure, schema-version fail-closed
- `24_Copilot_Project_Intake_Template.md` — intake fields, planning signals for orchestration
- `25_Copilot_Model_Governance_Checklist.md` — operator-facing launch integrity, dependency, semantic, lock, lineage, and trust-state checks
- `26_Copilot_Deployment_Readiness_Checklist.md` — environment capability verification for governed operation

**Phase 8 — Assembly and Maintenance**
- `27_README_Copilot_Builder_Agent_Pack.md` — pack orientation, load modes, phase summary, owner-document checkpoints, invalid usage patterns
- `28_Manifest.md` — authoritative inventory, checksums, carry-forward risk disposition register, runtime extraction source manifest
- `29_Suggested_Load_Order.md` — exact worker minimum loads for W1/W2/W3, orientation/audit loads, maintenance loads
- `30_Versioning_and_Maintenance_Guide.md` — change classes, runtime constitutional minimum maintenance, deterministic extraction-build rules, checksum reconciliation

**Derived Artifact**
- `Runtime_Constitutional_Minimum_Set.md` — build-generated exact-string extract of constitutional rules from Docs 02, 03, 04, and 07

---

## Review Dimensions

You must evaluate the complete document pack across every dimension below. For each dimension, you must produce findings or explicitly state that no issues were found with supporting evidence. "Looks fine" is not an acceptable finding.

### Dimension 1 — Constitutional Integrity and Intent Alignment

**What to check:**
- Does the framework as implemented still serve the five primary outcomes stated in `01_Project_Charter.md`? (Build/standardize, QA/regression, self-healing with minimal-change bias, root-cause depth, governance standards)
- Are all 11 guiding principles in Doc 02 actually enforced downstream, or do any degrade into aspirational statements that no downstream document operationalizes?
- Are there success criteria in the Charter that no downstream document concretely satisfies?
- Are there non-goals that a downstream document inadvertently violates?

**Root-cause requirement:** If a principle is unenforced, identify WHERE the enforcement chain breaks (which downstream file should have operationalized it and didn't).

### Dimension 2 — Document Ownership and Anti-Overlap Compliance

**What to check:**
- Does every document have exactly one primary purpose, as defined by Rule 1 and Rule 2 of Doc 04?
- Are there cases where two or more documents assert ownership over the same control concept?
- Are there cases where a document restates a rule verbatim (or near-verbatim) from another document without a reference-over-repetition subordination marker?
- Do ownership boundary declarations match actual content?

**Specific areas of known risk:**
- Doc 03 (Operating Model) and Doc 11 (System Instruction) both address runtime behavior. Is the boundary between constitutional gate/role logic and runtime execution posture actually clean, or does Doc 11 re-own gate behavior?
- Doc 09 (Output Contract Library) and Doc 04 (Document Architecture) both define structured hand-off fields. Is there a conflict between the constitutional minimum field list in Doc 03/04 and the full schema in Doc 09?
- Doc 20 (Self-Healing Policy) and Doc 15 (Skill Root Cause and Self-Healing Engineer) both address remediation. Is the boundary between policy ownership and skill execution behavior clean?
- Doc 23 (Playbook) and Doc 25/26 (Checklists) both address operational readiness. Is there content drift where a checklist introduces a control that belongs in the playbook?
- Docs 16/17/18/19 (QA/Regression/Evaluation/Release) each have tight boundaries. Are there evaluation criteria or regression rules that leak across these files?

**Root-cause requirement:** For each overlap, state which document should own the concept and which should reference it.

### Dimension 3 — Cross-Reference Integrity

**What to check:**
- Every explicit cross-reference (`See X.md, Section Y`) must point to a section that actually exists with that exact name.
- Every reference must point to the correct owning document. A reference should not point to a downstream consumer when the upstream owner is the authoritative source.
- Are there orphaned references (references to documents or sections that were renamed, merged, or restructured during remediation rounds)?
- Are there missing references (places where a document makes a claim that is governed by another document but does not cite it)?

**Specific areas of known risk:**
- Doc 02, Principle 11 references Doc 03 by section name. Verify the exact section name matches.
- Doc 04 references Doc 08 for anatomy ownership. Verify Doc 08 actually asserts that ownership.
- Skill files (12-15) reference upstream controls. Verify every upstream reference is accurate post-remediation.
- Doc 07 references Doc 10 for semantic-equivalence screen. Verify the relationship is bidirectional and consistent.

**Root-cause requirement:** For each broken reference, identify whether the issue is a stale reference, a renamed section, or a misdirected citation.

### Dimension 4 — State Gate and Role Transition Completeness

**What to check:**
- Gate 0 through Gate 5 (plus 0-R and 0-E): For each gate, verify that trigger conditions, required inputs, required outputs, and failure-to-transition handling are fully specified.
- Are there transition paths that are implied by the architecture but never formally defined? For example: what happens after Gate 0-E if the escalation record routes to `READY_FOR_RCA_FROM_ACQUISITION_EXHAUSTION`? Is the RCA entry point for that path fully defined?
- Is the `REOPENED_FOR_CORRECTION` return path from Gate 5 fully specified? What gate does the returned item re-enter? Is this explicit or implied?
- Are all canonical routing states in the Doc 03 enum registry actually consumed by at least one gate or downstream document? Are there orphan states that nothing routes to?
- Worker transitions (W1→W2→W3): Are the inter-worker transition requirements as strict as the inter-role transition requirements? Is there a gap where worker transitions might receive lighter scrutiny than role transitions?

**Root-cause requirement:** For each incomplete transition path, trace the gap to the owning document and the specific section where the path should be defined.

### Dimension 5 — Contract Schema Consistency

**What to check:**
- Doc 03 carries a constitutional minimum field list for `OC-09 Role_Transition_Payload_JSON`. Doc 09 carries the full schema. Are the Doc 03 fields a strict subset of the Doc 09 fields? Is there any field in Doc 03's minimum list that uses a different name, casing, or semantic than the Doc 09 schema?
- For every contract (OC-09, OC-10, OC-11, OC-12, SV-01, SV-02, LR-01, RCA-01, RM-01, RM-02): Are the required fields in the contract definition consistent with how downstream documents reference those fields?
- Are there downstream documents that reference a contract field that doesn't exist in the authoritative schema?
- Are there required fields in a schema that no downstream document ever validates, consumes, or routes on?
- The `SV-01` contract is referenced in Docs 11, 23, 25, 29. Is the field set consistent across all four references?

**Root-cause requirement:** For each schema inconsistency, identify the authoritative source, the deviating reference, and whether the fix belongs upstream (schema needs a field) or downstream (reference needs correction).

### Dimension 6 — Enum and Vocabulary Consistency

**What to check:**
- Severity classes (`CS1_LOW` through `CS4_CRITICAL`): Are these exact strings used consistently everywhere? Any instance of `low`, `high`, `critical` in a control-bearing context (not narrative commentary) that violates the enum rule?
- Execution modes (`ISOLATED_STATE`, `SHARED_RUNTIME_ADVISORY`): Any instance of `ISOLATED_STATE_REQUIRED` or other invalid lexical forms?
- Transition routing states: Is every state in the Doc 03 registry used somewhere? Are there states used in downstream documents that aren't in the registry?
- Remediation authority classes (`RH-1` through `RH-4`): Consistent naming and usage across Docs 15, 20, 21?
- Remediation states: Consistent between Doc 20 definition and downstream consumption in Docs 15, 19, 23?
- Freshness tiers (`F1_HARD_FRESHNESS`, `F2_BOUNDED_STALE_TOLERANCE`, `F3_REFERENCE_ONLY`): Consistent between Doc 05 definition and downstream QA/release consumption?
- Source classes (`S1` through `S5`): Consistent usage across Docs 07, 11, 14, 15?
- Conflict types (`CONFLICT_TYPE_A/B/C`): Consistent definition and downstream handling?

**Root-cause requirement:** For each vocabulary deviation, state the authoritative definition location, the deviating usage location, and the exact string mismatch.

### Dimension 7 — Circular Dependency and Deadlock Analysis

**What to check:**
- Are there circular dependency chains where Document A defers to Document B which defers back to Document A for the same control decision?
- Can the gate model deadlock? For example: Gate 0-R allows N=2 bounded refinement cycles, then routes to Gate 0-E. Gate 0-E can route to `READY_FOR_RCA_FROM_ACQUISITION_EXHAUSTION`. But RCA requires a failed artifact (Gate 3 entry). If no artifact was drafted (because the Builder was blocked), can RCA proceed? Doc 03 says yes if a valid `ACQUISITION_EXHAUSTION_ESCALATION_RECORD` exists. Is that path fully specified end-to-end?
- Is the pulse-breaker runtime rule (3 consecutive pulse failures → terminal stop) achievable in practice given the SV-02 execution lock constraints? Can a legitimate long-running work item be terminated prematurely by the interaction of these two mechanisms?
- Can the W3 expansion cap (50% of artifact context) interact with the masked artifact window (25 lines before/after) in a way that makes small-artifact remediation impossible?

**Root-cause requirement:** For each potential deadlock or circular path, trace the exact mechanism and identify which document(s) must clarify the resolution.

### Dimension 8 — Assumption and Inference Control Chain

**What to check:**
- The OC-10 Assumption_Quarantine_Contract is defined in Doc 09, operationalized in Docs 11 and 12, validated in Docs 14 and 16, and release-blocked in Doc 19. Is this chain complete and consistent?
- Are there places where assumption-bearing content could leak into governed logic despite the quarantine controls? For example: if a Builder drafts with OC-10 active and the draft goes to Standards Review (Gate 1), does the reviewer have access to the OC-10 contract and the assumption-isolation validation family?
- Is the `KD-01/KD-02/KD-04` critical-domain assumption ban consistently enforced? The ban appears in Docs 05, 07, 12, and 20. Are the prohibitions identical in scope and wording, or has drift occurred?
- Is the logic-laundering detection (AF-11) in Doc 18 actually testable given the information available to the evaluation role? What evidence would trigger it?

**Root-cause requirement:** For each leak path or enforcement gap, trace the assumption lifecycle from creation through potential escape to the point where it should have been caught.

### Dimension 9 — Operational Realism and Implementability

**What to check:**
- The framework requires deterministic validators, checksum verification, session isolation, and infrastructure-owned proof surfaces (SV-01). Is there any guidance on what happens in environments where these infrastructure capabilities are partially available?
- The W3 masked artifact procedure requires exactly 25 lines before/after. Is there guidance for artifacts smaller than 50 lines?
- The blind review isolation procedure (23L) requires spawning a new session and proving the prohibited logic set was not loaded. Is this achievable with current AI platform capabilities (e.g., Copilot Studio, Azure AI)?
- Is there a minimum viable deployment profile that identifies which controls are hard requirements vs. aspirational targets for initial deployment?
- The framework defines 10 JSON contract schemas. Is there any guidance on schema validation tooling, or is this left entirely to the orchestrator owner?
- The carry-forward risk disposition register in Doc 28 has a `CFR-04` accepted residual for infrastructure-dependent isolation. What other residual risks exist but are not recorded?

**Root-cause requirement:** For each implementability gap, classify it as: (a) missing guidance that should be added, (b) unrealistic requirement that should be relaxed, or (c) known residual risk that should be explicitly accepted in the register.

### Dimension 10 — Runtime Constitutional Minimum Integrity

**What to check:**
- The Runtime_Constitutional_Minimum_Set.md claims to be a build-generated exact-string extract. Verify that the extracted content actually matches the source documents.
- Are the SHA-256 checksums in the source extraction manifest plausible? (You cannot recompute them, but you can check whether the claimed source sections exist and match the content in the extract.)
- Are there constitutional rules in Docs 02, 03, 04, and 07 that should be in the runtime minimum but are missing? Specifically:
  - Doc 03, Section "Canonical State and Enum Registry" — is this in the extract? It is a critical constitutional surface.
  - Doc 04, Rules 8-10 (Principle-Based Durability, Extensible Addition, Conflict Resolution) — are these in the extract?
  - Doc 07, Sections "Provisional input restrictions", "Silent-resolution constraints", "Critical domain substitution prohibition" — are these in the extract?
- Does the extract include the Doc 11 co-load guard as required by Doc 30?
- Are there sections in the extract that duplicate content also present in Doc 11 (which is separately loaded)? If so, is there a conflict risk?

**Root-cause requirement:** For each missing or misaligned extraction, state the source section, the expected behavior, and whether the gap affects worker execution.

### Dimension 11 — Worker Load Profile Completeness

**What to check:**
- For each worker (W1, W2, W3), does the minimum load set in Doc 29 include every document that the worker's skill file references?
- Does W1 (Gap Analyst) load the knowledge-domain map (Doc 06) and acquisition plan (Doc 05) as required by its function?
- Does W2 (Drafting Specialist) load the business rules (Doc 10) needed for standardization enforcement?
- Does W3 (Remediation Surgeon) load the RCA framework (Doc 22) and the minimal-change standard (Doc 21)?
- Are there circular load dependencies where a loaded document references another document that isn't in the worker's minimum set?
- Does the manifest (Doc 28) worker relevance map match the exact load lists in Doc 29?

**Root-cause requirement:** For each missing load, identify the dependency chain that requires it and the downstream failure that would occur without it.

### Dimension 12 — Gap Analysis Against Original Intent

**What to check against the original development plan:**
- The original plan defined 30 documents across 8 phases. Are all 30 present and accounted for? Are any missing entirely?
- The original plan stated the framework should "guide the model using durable practices and decision rules while still allowing it to adapt to future Copilot capabilities." Has the framework become so control-heavy that adaptability is compromised?
- The original plan emphasized "simplicity first." With 10 JSON contract schemas, 6 control roles, 3 operational workers, 7 state gates, 4 severity classes, 5 source classes, 3 conflict types, 6 freshness tiers, 4 remediation authority classes, and 6 remediation states — is the framework still simple enough for an AI model to reliably execute?
- The original plan stated that the pack should be "easy to load, interpret, and maintain." Given the current complexity, is this still true?
- The original plan stated 5 foundational design rules (simplicity, unique purpose, direct reference, baseline guidance, one source of truth). Are all 5 still intact in the final implementation?

**Root-cause requirement:** For each gap between intent and implementation, classify it as: (a) justified evolution that should be documented as a conscious decision, (b) scope creep that should be remediated, or (c) fundamental design tension that requires an explicit tradeoff acknowledgment.

---

## Pack-Specific Calibration Context

This framework will be used by an IT Program Manager at a wholesale furniture and home goods company to govern AI-assisted Copilot builder work. The operator is technically sophisticated (mechanical engineering background, ERP implementation experience, Agile transformation lead) but the framework must be executable by AI models, not just readable by humans. The primary deployment targets are Microsoft Copilot Studio and potentially Claude-based agent workflows.

The framework's value proposition is reducing ambiguity, preventing shallow fixes, and keeping outputs traceable and reviewable. If the framework itself is ambiguous, contains shallow fixes from prior rounds, or has untraceable internal references, it has failed at its own stated mission.

Severity class aliases (Copilot-native form ↔ platform-normalized form):
- `CS4_CRITICAL` ↔ `CRITICAL` — blocks production release.
- `CS3_HIGH` ↔ `HIGH` — materially degrades correctness or integrity; blocks release unless explicitly carried.
- `CS2_MEDIUM` ↔ `MEDIUM` — noticeable defect with workaround; fix next revision.
- `CS1_LOW` ↔ `LOW` — cosmetic or stylistic drift; fix opportunistically.

When this pack is loaded, findings may be rendered with either label form per Anti-Laziness Rule #7 (no severity inflation/deflation) — choose one form per review and apply it consistently.

---

## Pack Start

Start the review with the highest-risk dimensions for this pack: Dimensions 4, 5, 6, and 7 historically surface the most production-impactful findings in this domain. After pack-specific dimensions complete, the skill's `## Principal Dimensions` section (Operational Awareness, Organizational Leverage, Mentorship & Culture) applies to every finding register regardless of pack.
