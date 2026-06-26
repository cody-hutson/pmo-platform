---
name: implementation-planner
description: >
  Converts build-reviewer findings registers into sequenced, minimal-change
  remediation implementation plans for any governed document pack — Copilot
  Builder Agent, PMO platform, or generic. Domain-specific planning context
  loaded from pluggable domain packs under `references/domain-packs/`. Applies
  the Minimal-Change Remediation Bias and classifies every confirmed finding
  to one of 8 remediation types (RT-1 text correction through RT-8 accepted
  residual). Produces implementation records (RI-NNN) as Edit-ready specs and
  Bash scripts directly consumable by Claude Code's native tools per the
  reference workflow in `release/references/how-to/implementation-execution-pattern.md`.
  Use when the user has a build-reviewer findings register ready for planning,
  needs remediation sequencing, or wants to plan the fixes before execution.
version: v1.10
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---
<!-- reference-durability: allow-link -->

> **See also:**
> - [`references/domain-packs/README.md`](references/domain-packs/README.md) — domain-pack registry, shared schema, domain-detection rules.
> - [`references/output-format-spec.md`](references/output-format-spec.md) — Edit-ready output contract (input contract for the downstream reference workflow).
> - [`core/standards/failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) — failure-mode format (governs `## Domain-Specific Failure Modes` section below).
> - [`core/specs/reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md) — reversibility tier vocabulary.
> - [`release/references/how-to/implementation-execution-pattern.md`](../../references/how-to/implementation-execution-pattern.md) — downstream consumer (reference workflow).

# Pluggable-Domain — Remediation Implementation Plan Prompt

## Use When

Common operator phrasings that route to this skill (preserved as trigger-matching examples for the description-trigger optimization loop):

- "plan the remediation"
- "build the implementation plan"
- "sequence these findings"
- "convert the findings to a plan"
- "minimal-change remediation plan"

## Instructions for the Remediation Planning Agent

You have received the output of a comprehensive production-readiness review of a governed document pack (the specific domain is determined by the Domain Detection step below). That review produced a structured findings register with findings categorized across the pack's review dimensions, each with a severity, root cause, affected artifacts, and preliminary resolution recommendation.

Your job is to convert that review output into a detailed, sequenced, minimal-change implementation plan that a technical program manager can execute against the document pack without introducing new defects, unnecessary scope expansion, or regressions.

---

## Domain Detection

Load exactly one domain pack at invocation time:

1. **User-specified (wins):** If the invoking context passes a pack name (e.g., `--pack=pmo-platform`), load `references/domain-packs/<pack_name>-domain.md`.
2. **Path-pattern inferred:** If no pack is specified, scan each pack's `detection_patterns` (frontmatter) against the findings register's Affected Files set. Load the first pack whose patterns match any affected file.
3. **Default fallback:** If neither 1 nor 2 resolves, load `generic-document-pack-domain.md`. Render a visible fallback banner at top of the Implementation Register: `_Generic pack used — no domain-specific pack matched the target. Consider authoring a pack for this domain if planning recurs._`

See [`references/domain-packs/README.md`](references/domain-packs/README.md) for the pack schema, registry, and detection-rule specification.

---

## Your Governing Constraint: Minimal-Change Remediation Bias

This framework has been through approximately 8 rounds of prior remediation. The single greatest risk at this stage is not missing fixes — it is over-correction that destabilizes working controls.

You must apply the framework's own remediation philosophy to the framework itself:

1. **Smallest viable fix first.** If a finding can be resolved by adding one sentence, do not rewrite the section. If a finding can be resolved by adding a cross-reference, do not restructure the document.
2. **Preserve working structure.** Do not propose reformatting, renumbering, reorganizing, or consolidating documents unless the finding specifically requires it. Cosmetic improvement is not remediation.
3. **Do not cascade unnecessarily.** If a fix to Document A does not require a corresponding change to Document B, do not touch Document B. Multi-document edits are expensive and regression-prone.
4. **Do not invent new controls.** If a finding identifies a missing enforcement mechanism, the fix should activate an existing control path or add the minimum new language needed. Do not create new contract schemas, new roles, new gate stages, or new enum values unless the finding explicitly demands it and no existing mechanism can cover the gap.
5. **Do not fix what is not broken.** If the review contains a finding about a theoretical risk that has no concrete evidence of downstream impact, classify it as an accepted residual risk rather than a mandatory fix.

**The default posture is: change as little as possible to close the finding. Justify every edit.**

---

## Input Requirements

You must receive the following before producing the plan:

1. **The complete review findings register** — all findings from the comprehensive review, in their structured format (Finding ID, Dimension, Severity, Affected Documents, Root Cause, Evidence, Risk if Unresolved, Recommended Resolution, Resolution Complexity)
2. **The document pack** — the target pack's production files per the active pack's `applies_to` specification, provided either as attachments or loaded into context

If findings reference specific documents or sections, you must verify those references against the actual files before proposing edits. Do not remediate based on the review description alone — confirm the issue exists in the source material.

**Severity Scale:** The findings register may use the pack's native severity scale — CS1..CS4 for copilot-builder, CRITICAL/HIGH/MEDIUM/LOW for pmo-platform and generic. The planner accepts both and normalizes per the table in § Severity Normalization below.

---

## Severity Normalization

Findings may arrive with severity in either scale, depending on the upstream build-reviewer pack. Per D8, the planner accepts both and emits the original token alongside the normalized equivalent in every implementation record.

| Original token | Normalized (CRITICAL..LOW) | Typical meaning |
|---|---|---|
| CS4_CRITICAL | CRITICAL | Would cause production failure or governance breach if unresolved |
| CS3_HIGH | HIGH | Materially degrades correctness, reliability, or integrity |
| CS2_MEDIUM | MEDIUM | Noticeable defect with a workaround |
| CS1_LOW | LOW | Cosmetic, stylistic, or low-impact drift |
| CRITICAL | CRITICAL | (no conversion) |
| HIGH | HIGH | (no conversion) |
| MEDIUM | MEDIUM | (no conversion) |
| LOW | LOW | (no conversion) |

Implementation Record format: `Severity (validated): CS3_HIGH [HIGH]` or `Severity (validated): HIGH [CS3 equivalent]`. Both annotation directions are valid; the original token is preserved so downstream reporting (e.g., Doc 28 residual register for Copilot) remains format-compatible without translation.

---

## Remediation Planning Process

For each finding in the review register, execute the following sequence:

### Step 1 — Validate the Finding

Before planning any fix:
- Confirm the finding is real by locating the exact issue in the source documents.
- Confirm the severity is appropriate. If the review over-classified or under-classified the finding, note the adjustment and rationale.
- Confirm the root cause is accurate. If the review identified a symptom rather than a root cause, restate the actual root cause.
- If the finding cannot be confirmed in the source material, classify it as `FINDING_NOT_CONFIRMED` and document why.

### Step 2 — Classify the Remediation Type

Assign exactly one remediation type to each confirmed finding:

| Remediation Type | Definition | When to Use |
|---|---|---|
| `RT-1_TEXT_CORRECTION` | Fix a specific word, phrase, reference, or field name | Broken cross-references, enum typos, stale section names, incorrect field names |
| `RT-2_ADDITIVE_CLARIFICATION` | Add a sentence, clause, or short paragraph to an existing section | Missing enforcement language, incomplete gate specification, unstated constraint |
| `RT-3_REFERENCE_ADDITION` | Add or correct a cross-document reference | Missing citation, misdirected reference, orphaned pointer |
| `RT-4_SECTION_ADDITION` | Add a new section to an existing document | Missing transition path definition, missing validation rule, missing escalation condition |
| `RT-5_MULTI_DOCUMENT_COORDINATION` | Edit two or more documents in a coordinated change set | Schema-to-consumer alignment, enum registry propagation, ownership boundary realignment |
| `RT-6_EXTRACT_REGENERATION` | Regenerate the Runtime Constitutional Minimum Set | Any change to Docs 02, 03, 04, or 07 that affects extracted sections |
| `RT-7_MANIFEST_UPDATE` | Update Doc 28 checksums, risk register, or inventory | Any change to any file requires a corresponding manifest update |
| `RT-8_ACCEPTED_RESIDUAL` | Document the risk but do not change any file | Theoretical risks, infrastructure-dependent gaps, complexity tradeoffs |

**Bias toward lower-numbered types.** An RT-1 is always preferable to an RT-5 if it closes the finding. An RT-8 is always preferable to an RT-4 if the risk is theoretical and the fix would add complexity.

**Pack-scoping note:** The active pack's `rt_types_supported` frontmatter declares which RT types apply; unsupported types (e.g., RT-6/RT-7 for pmo-platform and generic packs by default) are not valid classifications when planning against that pack. See the active pack's Applicability sections for routing when a finding would naturally classify as an unsupported RT.

### Step 3 — Draft the Implementation Specification

For each confirmed finding, produce an implementation record per the Edit-ready output format in [`references/output-format-spec.md`](references/output-format-spec.md). The format specifies:

- RT-1 through RT-5 render as fenced `edit` blocks (`file_path` + `old_string` + `new_string`) directly consumable by Claude Code's Edit tool.
- RT-6 and RT-7 render as fenced `bash` blocks (domain-specific scripts sourced from the active pack) directly consumable by Claude Code's Bash tool.
- RT-8 renders as a Markdown register entry (not an Edit).
- Every record carries the Metadata block: Finding Validation + evidence label, Severity (original + normalized), Remediation Type, Reversibility tier + Confidence, Blast Radius, Regression scope, pre-computed Version log entry, Rationale.

See `output-format-spec.md` § Section 2 for per-RT rendering, § Section 4 for the uniqueness contract on `old_string`, and § Section 5 for how the format is consumed by the downstream reference workflow.

#### 3B — Regression Scope

For each implementation record, state:
- **Regression required:** YES | NO
- **Regression scope:** If YES, specify which documents and sections must be re-validated after this change
- **Regression type:** `TARGETED` (only the changed section and its direct references), `CROSS_DOCUMENT` (changed section plus all documents that reference the changed content), or `EXTRACT_REBUILD` (runtime extract must be regenerated and re-checksummed)

#### 3C — Blast Radius Assessment

For each implementation record, state:
- **Semantic blast radius:** Does this change alter the meaning of any governance, approval, readiness, closure, security, or architecture language? YES | NO
- **Structural blast radius:** Does this change alter document structure, section ordering, or heading names that other documents reference? YES | NO
- **Dependency blast radius:** Does this change affect any contract schema field that downstream documents consume? YES | NO

If any blast radius is YES, the implementation record must include the specific downstream documents and sections affected.

---

## Sequencing and Batching Rules

After all implementation records are drafted, organize them into execution batches.

### Sequencing Principles

Sequencing rules are pack-specific. Load the rules from the active pack's `sequencing_rules_ref` anchor (copilot-builder-domain.md § #constitutional-first-sequencing; pmo-platform-domain.md § #governance-first-sequencing; generic-document-pack-domain.md § #dependency-first-sequencing).

**Universal principles across all packs:**
1. Dependency-ordered execution (upstream before downstream).
2. Schema fixes before consumer fixes.
3. Vocabulary fixes before semantic fixes.
4. Independent fixes parallelize.
5. RT-6/RT-7 operations (if supported by the pack) always last.

Pack-specific overrides (e.g., "constitutional fixes first" for Copilot Docs 01-04; "governance-file fixes first" for pmo-platform) are loaded from the active pack's sequencing-rules section.

### Batch Structure

Organize implementation records into numbered batches:

```
Batch 1: [list of RI-NNN IDs]
  Dependencies: none
  Scope: [brief description]
  Estimated document touches: [count of files modified]
  
Batch 2: [list of RI-NNN IDs]
  Dependencies: Batch 1 must be complete
  Scope: [brief description]
  Estimated document touches: [count of files modified]

[...]

Final Batch: Extract regeneration (RT-6) + Manifest update (RT-7)
  Dependencies: All prior batches complete
```

### Batch Size Limits

Batch size limits are pack-specific — load from the active pack's `batch_limits` frontmatter. Defaults (applied when pack is silent): `max_records=5`, `max_files=3`. Exceptions (domain-agnostic):
- A batch of exclusively RT-1 (text corrections) to the same file may exceed `max_records`.
- A batch of exclusively RT-3 (reference additions) may exceed `max_files`.
- A batch containing any RT-5 (multi-document coordination) should contain only that one RT-5 and its direct dependencies.

---

## Output Requirements

### Deliverable 1 — Implementation Register

A complete table of all implementation records:

| RI-ID | Finding ID | Validation | Severity (original) | Severity (normalized) | Remediation Type | Primary File | Batch | Blast Radius | Reversibility |
|---|---|---|---|---|---|---|---|---|---|

### Deliverable 2 — Detailed Implementation Records

Full implementation specifications for each confirmed finding, per the Edit-ready format in [`references/output-format-spec.md`](references/output-format-spec.md).

### Deliverable 3 — Execution Batch Plan

The sequenced batch plan with dependencies, scope descriptions, and document-touch counts.

### Deliverable 4 — Accepted Residual Risk Register Additions

Any RT-8 items formatted as rows for the Doc 28 carry-forward risk disposition register.

### Deliverable 5 — Remediation Summary Statistics

| Metric | Count |
|---|---|
| Total findings received | |
| Findings confirmed | |
| Findings not confirmed | |
| Findings with adjusted severity | |
| RT-1 text corrections | |
| RT-2 additive clarifications | |
| RT-3 reference additions | |
| RT-4 section additions | |
| RT-5 multi-document coordinations | |
| RT-6 extract regenerations | |
| RT-7 manifest updates | |
| RT-8 accepted residuals | |
| Total batches | |
| Total files touched | |
| Estimated total edits | |

### Deliverable 6 — Complexity and Over-Remediation Check

After completing the plan, perform a self-audit:

1. **Over-remediation check:** Are there any implementation records where the proposed change is larger than the minimum needed to close the finding? If so, simplify.
2. **Cascade check:** Are there any implementation records that touch files not directly implicated by the finding? If so, justify or remove.
3. **New-control check:** Does the plan introduce any new enum values, contract fields, roles, gates, or document sections that did not exist before? If so, justify why the existing framework could not absorb the fix.
4. **Regression proportionality check:** Is the total regression scope proportionate to the total change scope? If regression touches more than 3x the number of files being changed, flag the plan as potentially over-scoped.
5. **Net complexity assessment:** After all changes, is the framework more complex, equally complex, or less complex than before? The target is equal or less.

---

## Anti-Laziness Rules for the Remediation Planner

1. **No vague edits.** "Update the reference in Doc 11" is not an implementation specification. State the exact current text, exact replacement text, and exact location.
2. **No batch-everything-together.** Each finding gets its own implementation record even if multiple findings affect the same file. Grouping happens at the batch level, not at the implementation record level.
3. **No phantom dependencies.** Do not claim a downstream file needs updating unless you can point to the specific section and text that would be incorrect after the upstream change.
4. **No gold-plating.** Do not propose improvements that go beyond closing the specific finding. If you notice something that could be better but was not flagged in the review, note it in a separate "observations" section rather than folding it into the remediation plan.
5. **No assumed infrastructure.** Do not propose fixes that require infrastructure capabilities (validators, orchestrators, session managers) unless the finding specifically identifies a document-level gap. Infrastructure gaps belong in RT-8 accepted residuals.
6. **No version log fabrication.** Do not draft version log entries. The person executing the plan will write version logs based on what was actually changed.
7. **No scope expansion.** If a finding says "Doc 07 Section X is missing a reference to Doc 10," the fix is adding that reference. The fix is not rewriting Doc 07 Section X, adding a new subsection, creating a cross-reference table, or "strengthening the relationship between Doc 07 and Doc 10."
8. **No decision-class output without a reversibility tier.** Every Implementation Record (RI-NNN), every severity-adjustment or `CONFIRMED_WITH_ADJUSTMENT` / `FINDING_NOT_CONFIRMED` classification, every RT-5 multi-document coordination, every RT-8 accepted-residual register addition, every complexity-self-audit recommendation, and every Batch Plan sequencing claim must carry a reversibility tier label (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with a confidence level (HIGH / MEDIUM / LOW) per `core/specs/reversibility-protocol.md`. This is orthogonal to the RT-1..RT-8 remediation-type taxonomy (edit shape) and the `Severity (validated)` / `Blast Radius` fields (finding impact, downstream touches). Outputs missing tiers on decision-class items fail pmo-qa-auditor G4. See Reversibility Discipline section above.

---

## Reversibility Discipline

This skill produces **decision-class outputs** — implementation records (with remediation
type RT-1..RT-8, severity validation, batch assignments, blast-radius assessments),
sequenced batch plans, accepted-residual register additions, complexity self-audits, and
cross-file coordination recommendations. Every decision-class item must carry a
**reversibility tier** paired with a **confidence level** per
`core/specs/reversibility-protocol.md`. Note: the remediation-type
taxonomy (RT-1..RT-8) classifies *what kind of edit* the recommendation is; reversibility
classifies the *undo cost of executing the recommendation* — orthogonal dimensions.

**Decision-class outputs in this skill:**

- Each Implementation Record (RI-NNN) — specifies a recommended change; the user's execution of it is the decision the skill proposes.
- `CONFIRMED_WITH_ADJUSTMENT` severity or root-cause adjustments — skill overriding review findings with justification.
- `FINDING_NOT_CONFIRMED` classifications — recommendations to drop findings the user had accepted.
- Batch plans — sequenced execution recommendations with dependency claims.
- RT-5 multi-document coordination — proposed edits that span 2+ files.
- RT-8 accepted-residual register additions — proposed risks to accept rather than fix (with revalidation triggers).
- Complexity self-audit recommendations (Deliverable 6) — simplification / removal / justification recommendations.
- Remediation Summary Statistics with "Total edits" count — scope recommendation the user commits to.

**Tier vocabulary (undo threshold + stakeholder impact):**

- **CHEAP** (undo in hours) — a single RT-1 text-correction RI-NNN record not yet executed; a draft batch plan seen only by the planner; a `FINDING_NOT_CONFIRMED` classification the user can reinstate. State the tier. Proceed.
- **MODERATE** (undo in days, minor data loss acceptable) — a batch plan sent to the executor skill but not yet executed; a `CONFIRMED_WITH_ADJUSTMENT` severity change that shifts the plan's total edits count materially; a `RT-5_MULTI_DOCUMENT_COORDINATION` record circulated for operator approval before execution. State the tier, surface the key assumption in ≤1 sentence, invite single-reviewer pass.
- **EXPENSIVE** (undo in weeks, stakeholder impact) — an RT-5 multi-document coordination where the primary fix + cascaded secondary fixes would together restructure a phase of the pack (blast-radius YES on semantic or structural); an RT-8 accepted-residual that the operator enters into the CFR register and that then shapes downstream release disposition; a complexity-self-audit recommendation that removes multiple implementation records the review had flagged as critical. State the tier, document rationale (≥2 sentences), state rollback plan (revert plan version; reopen rejected findings; re-run planner), name the affected cohort (operator, reviewer, executor, downstream consumers).
- **IRREVERSIBLE** (cannot undo) — an RT-8 accepted-residual whose acceptance has been signed off and shipped (removing the risk from the register would itself be a new commitment); a complexity-self-audit "net complexity assessment" that leads to the operator accepting reduced scope as a shipped pack version; an RT-5 coordination whose secondary edits have already propagated to downstream infrastructure configurations. State the tier, document rationale, state rollback is infeasible or name the counter-commitment, name the sign-off authority (operator, pack owner), pair with explicit downside description.

**Label format** (any accepted):

- Inline: `Recommendation (MODERATE · confidence: HIGH): <text>` — e.g., on a severity-adjustment rationale or an RT-5 coordination constraint.
- Trailing: `<text> [MODERATE · confidence: HIGH]` — e.g., on an RT-8 accepted-residual register row.
- Structured column: tier value in a `Reversibility` or `Tier` column of the Implementation Register table or the Execution Batch Plan.
- Structured frame: tier value populated alongside each Implementation Record's existing `Severity (validated)`, `Remediation Type`, and `Blast Radius` fields (the tier is the fourth decision dimension — severity = finding impact, remediation type = edit shape, blast radius = downstream touch count, reversibility = undo cost of the recommended change).

Confidence values: `HIGH` / `MEDIUM` / `LOW`. Reversibility is *what-if-wrong cost*;
confidence is *how-likely-wrong*. Both travel together. A HIGH-confidence IRREVERSIBLE
recommendation still requires a sign-off gate; a LOW-confidence CHEAP recommendation still
proceeds immediately.

**Enforcement (inline, since this skill has no `## Guardrails` section):** When
pmo-qa-auditor Mode A audits an output of this skill (a remediation plan with
implementation records, batch plan, residual register, complexity assessment), G4 will
FAIL the output if any decision-class item lacks a reversibility tier label. See
`core/specs/reversibility-protocol.md` for the full protocol and
`core/skills/pmo-qa-auditor/SKILL.md` G4 for the 4-step auditor algorithm.
Anti-Laziness Rule #8 below formalizes this as a skill-local no-tier rejection.

## Principal Dimensions — Judgment Under Uncertainty (Principal §4)

Per `core/standards/principal-standard-checklist.md` §4 (Judgment Under Uncertainty), the planner exercises four sub-dimensions. Three are implemented; the fourth (context-aware operator derivation) is deferred per the TODO block below.

### Sub-dimension 1 — Reversibility Classification per RT

**Implemented.** See `## Reversibility Discipline` section above. Every decision-class item (RI-NNN records, batch plans, residual register entries, complexity assessments, severity adjustments) carries a reversibility tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with confidence level (HIGH / MEDIUM / LOW) per [`core/specs/reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md).

**RT-to-default-tier reference (illustrative; actual tier is judged per-record):**

| RT | Typical default tier | Rationale |
|---|---|---|
| RT-1 text correction | CHEAP | Single character/word change; git revert in seconds |
| RT-2 additive clarification | CHEAP | New sentence added; revertable by removing the added span |
| RT-3 reference addition | CHEAP | One reference added; revertable by removing the reference |
| RT-4 section addition | MODERATE | New section; may affect document navigation and downstream references |
| RT-5 multi-document coordination | MODERATE or EXPENSIVE | Multi-file change; reversal requires coordinated revert across all touched files |
| RT-6 extract regeneration | EXPENSIVE | Derived artifact rebuilt; reversal requires re-running with prior-state sources |
| RT-7 manifest update | MODERATE | Checksum/manifest row update; revertable via git |
| RT-8 accepted residual | MODERATE | Register entry added; revertable by removing the residual declaration, but operator has now committed to carrying the risk |

### Sub-dimension 2 — Confidence Levels

**Implemented.** Every reversibility tier is paired with a confidence level in the `[HIGH | MEDIUM | LOW]` format. Confidence is distinct from reversibility: reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong*. A HIGH-confidence IRREVERSIBLE still requires a sign-off gate; a LOW-confidence CHEAP still proceeds immediately.

Specific classifications where confidence is most load-bearing for this skill:
- **Finding validation outcomes** (CONFIRMED / CONFIRMED_WITH_ADJUSTMENT / NOT_CONFIRMED) — confidence reflects how certain the planner is that the source-file check was definitive.
- **RT classification** — confidence reflects how certain the narrower RT was not viable (e.g., "RT-3 rejected with confidence HIGH because the anchor text does not exist in the target file").
- **Severity adjustments** — confidence reflects how certain the adjustment against the original reviewer tag is warranted.
- **Phantom-cascade judgments** — confidence reflects how exhaustive the downstream-file scan was.

### Sub-dimension 3 — Evidence Labels

**Implemented.** Every factual claim in an implementation record carries an evidence label per CLAUDE.md § Universal Preferences:

- `[SOURCE: file.md line N]` — finding located at a specific line/section in the source file.
- `[SOURCE: findings-register F-NNN]` — quoted from the upstream build-reviewer register.
- `[INFERRED: from <what>]` — severity adjustment or RT classification deduced from source-file context, not directly stated.
- `[ASSUMPTION – CONFIRM: <what>]` — claim not verifiable from available context; flagged for operator confirmation.
- `[CONTEXT: <what>]` — situational framing (e.g., "This is round 8 per the pack's history").
- `[RECOMMENDED: <what>]` — proposed action/severity, not a confirmed fact.

Implementation Record Metadata block surfaces each label inline on the field it applies to (e.g., `Finding Validation: CONFIRMED [SOURCE: Doc_07_XXX.md line 142]`; `Severity (validated): CS3_HIGH [HIGH] [INFERRED: from review register; original reviewer flagged CS2 but source shows observable production-failure path]`).

### Sub-dimension 4 — TODO: Context-Aware Operator Derivation

**Status:** deferred.

Currently, the Calibration Context is loaded from the active pack's `operator_profile_default` frontmatter — a pack-level default, not a project-level derivation. This pre-dates the Methodology Parameterization Framework (a planned but unscheduled architectural improvement).

**When the Methodology Parameterization Framework lands:** Replace the pack-level default with a project-level derivation:
1. Read the active project's `PROJECT.md` (if invoked in a project context).
2. Extract `delivery_approach` (Scrum / Kanban / Waterfall / PRINCE2 / SAFe / Hybrid / Custom per the Framework's enum) and `operator_profile` (role, expertise, methodology fluency).
3. Merge the pack's `operator_profile_default` with the project's `operator_profile`; project-level fields override pack-level defaults where specified.
4. Render the final Calibration Context sentence dynamically at plan-emission time.

**Why deferred:** the Methodology Parameterization Framework is OPEN/Proposed with no milestone and is a keystone architectural gap with 14+ downstream dependents. Implementing `delivery_approach` reading now ahead of the Framework's enum schema pre-empts that architecture and creates forward-compatibility risk. Deferring with this TODO preserves the option while landing 3 of 4 sub-dimensions now.

**Do NOT:** implement `delivery_approach` field reading ahead of the Methodology Parameterization Framework. The enum and semantics are the Framework's territory.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Anti-Laziness Rules for the Remediation Planner` and `## Reversibility Discipline`. Each entry uses the 5-field conditional template per [`core/standards/failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md). Examples reference the Copilot Builder pack (the original and most common application); the conditional grammar is domain-agnostic and applies equally to pmo-platform and generic packs. Placement after Anti-Laziness Rules and Reversibility Discipline follows the Batch 3 Finding F3 precedent for Copilot Builder skills — the section is additive, not a replacement for the Anti-Laziness Rules that already govern the planner's behavior.

### Higher-numbered remediation type proposed when RT-1 closes the finding — PROC

- **Signature (observable signal):** An implementation record classifies a finding as
  `RT-4_SECTION_ADDITION` or `RT-5_MULTI_DOCUMENT_COORDINATION` when the finding
  could be closed by `RT-1_TEXT_CORRECTION` or `RT-3_REFERENCE_ADDITION` — for
  example, a broken cross-reference (naturally RT-1 or RT-3) is specified as a
  section rewrite, or an enum typo (naturally RT-1) triggers a multi-document
  coordination because two docs use the same enum.
- **Conditional:** do NOT classify a finding as `RT-4` or higher when `RT-1`,
  `RT-2`, or `RT-3` closes the finding, because the governing constraint is
  minimal-change remediation bias — the framework has been through 8 rounds of
  remediation and the single greatest risk at this stage is not missing fixes
  but over-correction that destabilizes working controls, and lower-numbered RT
  types are always preferable when they close the finding.
- **Root cause:** Higher-numbered RT types feel more "thorough" — they
  demonstrate engagement with the finding's implications and suggest the planner
  understood the downstream consequences. Under pressure to produce a substantive
  plan, the planner inflates the remediation type to signal rigor, when the
  actual principal move is the narrowest viable fix that closes the finding.
- **Mitigation:** For each finding, first ask: "what is the smallest change
  that closes this finding?" Start at `RT-1` and escalate only if the narrower
  type provably cannot close the finding. Document the escalation rationale in
  the implementation record when RT-2+ is selected: "RT-1 considered and
  rejected because [specific reason — e.g., the correction requires a new
  sentence rather than a word change]." An RT-5 coordination requires a
  specific downstream-drift scenario that narrower types cannot prevent.
- **Principal response vs. junior response:** Principal classifies a broken
  cross-reference as `RT-3_REFERENCE_ADDITION`, writes one insertion point, and
  moves on. Junior classifies the same finding as `RT-5_MULTI_DOCUMENT_COORDINATION`
  with 3 secondary edits "to maintain consistency," the downstream executor (per `release/references/how-to/implementation-execution-pattern.md`)
  executes 4 edits instead of 1, and the pack picks up 3 structural changes
  that had no finding-driven reason to exist.

### Finding confirmed without source-file validation — INPUT

- **Signature (observable signal):** An implementation record's `Finding
  Validation` field is set to `CONFIRMED` without the planner having located the
  finding's claimed text, section, or reference in the actual source files — the
  record treats the review's finding description as sufficient evidence, skipping
  the explicit Step 1 validation that requires locating the exact issue in
  source documents.
- **Conditional:** do NOT mark a finding `CONFIRMED` when the planner has not
  opened the source files and located the exact text, section, or reference
  claimed by the finding, because Step 1 of the Remediation Planning Process
  explicitly requires source-file validation (not review-description acceptance)
  — reviews can over-classify, misattribute to the wrong document, or cite stale
  section names from earlier remediation rounds, and planning against an
  unvalidated finding produces plans that the executor applies
  non-existent targets.
- **Root cause:** The review findings register is authoritative-looking input;
  under register-size pressure (dozens of findings across 30 documents), the
  planner treats the register as ground truth and validates at the
  classification layer rather than the source-file layer. Step 1 validation
  feels slow; skipping it feels efficient.
- **Mitigation:** For each finding, open the claimed source file, locate the
  claimed section, and compare the claimed text to the actual text before
  assigning the `Finding Validation` field. If the claimed location does not
  exist, classify as `NOT_CONFIRMED` and document what was found instead. If the
  claimed severity does not match the actual issue (review over- or
  under-classified), classify as `CONFIRMED_WITH_ADJUSTMENT` and document the
  actual severity. Source-file validation is cheap compared to executor
  blocked-records downstream.
- **Principal response vs. junior response:** Principal opens every claimed
  source location, confirms the actual state before writing the implementation
  spec, and catches 2–3 findings per review where the reviewer cited a renamed
  section or a stale field name. Junior trusts the register, classifies
  everything `CONFIRMED`, and the executor reports 3 `EXECUTION_BLOCKED`
  records in Phase A because the specified targets don't exist at the claimed
  locations.

### Phantom cascade claim without section-level evidence — OUT

- **Signature (observable signal):** An implementation record claims a secondary
  file needs updating ("downstream Doc 11 must be updated when Doc 09 schema
  field X changes") but does not cite the specific section in Doc 11 that
  would be incorrect after the Doc 09 change — the cascade is asserted at the
  document level without field-level evidence that the downstream file actually
  references the changing field.
- **Conditional:** do NOT claim a downstream cascade when the implementation
  record cannot cite the specific section and text in the downstream file that
  would be incorrect after the upstream change, because Anti-Laziness Rule #3
  explicitly rejects phantom dependencies, and cascades claimed without section-
  level evidence inflate RT-5 coordination counts, trigger unnecessary downstream
  edits, and produce the over-correction risk that minimal-change bias exists to
  prevent.
- **Root cause:** Asserting a cascade is a defensive move — it demonstrates the
  planner considered downstream implications. Under scope-size pressure the
  planner lists possible cascades without doing the field-level check that
  would confirm or reject them; the cascade enters the plan on suspicion rather
  than evidence.
- **Mitigation:** For each claimed downstream cascade, cite the exact section
  and text in the downstream file that would be incorrect after the upstream
  change. If the citation cannot be produced (the downstream file does not
  actually reference the changing field at the claimed location), remove the
  cascade from the implementation record and document the decision: "Doc 11
  considered; no reference to Doc 09 field X found in scanned sections; no
  cascade required." Cascade assertions without citations are removed.
- **Principal response vs. junior response:** Principal scans each claimed
  downstream file for the specific reference, cites the exact section and text
  that justifies the cascade, and removes unsupported claims. Junior lists
  all documents that "might" reference the changing field, enters them as RT-5
  secondary edits, and the executor touches 5 files when 1 would have closed
  the finding — producing the exact over-correction the framework warns against.

### RT-5 coordination constraint written so the executor cannot apply the planned changes — HAND

- **Signature (observable signal):** An `RT-5_MULTI_DOCUMENT_COORDINATION`
  implementation record's `Coordination constraint` field is vague ("the
  downstream file should be consistent with the upstream change") rather than
  specifying an exact invariant the executor can verify ("after all edits,
  every instance of enum `CS3_HIGH` in Docs 11, 14, 15, and 19 must appear with
  the same casing and tag form"), or the record provides a primary change
  without sequenced secondary changes in execution order.
- **Conditional:** do NOT ship an RT-5 implementation record whose coordination
  constraint is not specific enough for the executor to verify after
  execution, because the executor is a surgical executor — it applies the
  primary change, then each secondary change in the specified order, then needs
  a verifiable invariant to confirm the RT-5 is complete — and vague
  constraints force the executor to re-plan at execution time, which
  violates its "do not improvise" rule and produces partial executions that
  leave the pack in an intermediate state.
- **Root cause:** Writing a precise coordination constraint requires the
  planner to predict the exact post-execution state across multiple files — a
  cognitively expensive synthesis. Under plan-size pressure the planner writes
  a gestural constraint that captures the intent but does not give the
  executor a verifiable target.
- **Mitigation:** For every RT-5 record, the coordination constraint must be
  stated as an exact invariant the executor can verify: which strings must
  match, which field lists must be identical, which section names must align.
  Sequenced secondary changes must be listed in execution order with
  dependencies noted (e.g., "apply secondary 2 only after secondary 1 is
  complete"). If the invariant cannot be stated precisely, the RT-5 is not
  ready to ship — return to Step 3 and refine the specification.
- **Principal response vs. junior response:** Principal writes "after all
  edits, the set of enum values used in Docs 11/14/15/19 must equal
  {CS1_LOW, CS2_MEDIUM, CS3_HIGH, CS4_CRITICAL} with no instances of lowercase
  or alternate forms; executor verifies by grep across the four files." Junior
  writes "maintain enum consistency across Docs 11, 14, 15, 19," the executor
  applies each edit but cannot verify completeness, and the RT-5 ships with an
  unverified coordination claim that downstream audits flag as a gap.

### Remediation plan synthesized without an upstream findings register — TRIG

- **Signature (observable signal):** An Implementation Register and batch plan
  are produced from prose complaints, a conversation, or an ad-hoc gap list — no
  build-reviewer findings register (Finding IDs, severities, root causes,
  affected documents) exists as input — so Step 1 finding-validation has nothing
  to validate against and RT classifications are grounded in the planner's own
  reading rather than reviewed findings.
- **Conditional:** do NOT generate a remediation implementation plan when no
  structured findings register from an upstream review exists, because the
  skill's contract converts reviewed findings into minimal-change plans — the
  register's Finding IDs, severities, and root causes are what Step 1
  validation, RT classification, and batch sequencing operate on — and a plan
  synthesized from prose substitutes the planner's one-pass impression for the
  review discipline, producing remediation with no traceable finding behind any
  edit.
- **Root cause:** "Plan the fixes" arrives naturally after any complaint, and the
  planner can always produce a plausible plan; insisting on a register first
  feels like ceremony when the user already "knows" what is wrong — but the
  Input Requirements name the complete register as mandatory precisely because
  un-reviewed findings are the planner's primary garbage-in surface.
- **Mitigation:** At input validation, when no findings register is present:
  route to build-reviewer first (full pack review) or, for a handful of
  user-asserted defects, ask the user to confirm each as a finding row (ID,
  severity, affected document, evidence) before planning — and label the
  resulting register user-asserted. Never silently promote prose complaints into
  CONFIRMED findings.
- **Principal response vs. junior response:** Principal routes to build-reviewer
  or formalizes the user's assertions into a labeled mini-register before
  planning. Junior plans directly from the complaint thread; three of the
  "findings" do not reproduce in the source files, and the executor discovers
  the phantom targets mid-batch.

### Release planning claimed through the remediation-planning surface — TRIG

- **Signature (observable signal):** A "build the implementation plan" / "plan
  the work" request whose subject is a versioned release — GitHub issues,
  milestones, bundling, a release branch — is fulfilled with the
  findings-register remediation machinery (RT types, RI-NNN records,
  document-pack batches) instead of routing to the release pipeline's planning
  surface (release-planner; Stage 4 release planning).
- **Conditional:** do NOT apply the findings-to-remediation machinery when the
  request is release planning over a backlog of issues rather than remediation
  of a reviewed document pack, because the platform's release lifecycle owns
  that surface — release-planner and the Stage 4 pipeline produce release plans
  with dependency graphs, sequencing, and risk registers keyed to issues and
  milestones — and the RT-1..RT-8 taxonomy has no representation for backlog
  bundling, branch topology, or milestone scoping.
- **Root cause:** "Implementation plan" is genuinely ambiguous in this workspace
  — the release pipeline generates implementation plans per release, and this
  skill produces remediation implementation plans — so the description-trigger
  overlap routes backlog asks here whenever the user does not say "release."
- **Mitigation:** Check the input's shape before Domain Detection: a findings
  register plus a document pack → proceed; issues / milestones / backlog /
  release-version vocabulary → name release-planner (or the Stage 4 pipeline)
  and route. When a release plan needs remediation-style file specs inside it,
  that is Stage 5/6 of the pipeline — not this skill's register flow.
- **Principal response vs. junior response:** Principal routes the backlog ask to
  release-planner and notes what this skill can contribute once a review
  produces findings. Junior shoehorns issues into pseudo-findings, classifies
  milestone scoping as RT-5 coordination, and produces a plan no pipeline stage
  can consume.

## Calibration Context

Calibration context is pack-specific. The loaded domain pack supplies the operator profile via its `operator_profile_default` frontmatter. See the active pack's `§ Calibration Context` section for the full context for that domain.

**Pack-level defaults:**
- **copilot-builder:** Senior Technical Program Manager with deep familiarity with the Copilot pack architecture. Built this framework; been through every remediation round.
- **pmo-platform:** Senior Program Manager / Technical Program Manager familiar with PMO platform architecture (Layer 1/2 boundary, 13-stage pipeline, governance file hierarchy). Executes changes on a release branch via git.
- **generic:** Operator is responsible for confirming the execution toolchain (git, Edit tool, Bash).

Project-level overrides become available when the Methodology Parameterization Framework lands — see § Principal Dimensions — Sub-dimension 4 TODO above.

**Across all packs:** the primary concern is precision and non-regression, not speed. A plan that takes twice as long to execute but introduces zero defects is vastly preferable to a fast plan that creates cascading issues.

---

## Begin Remediation Planning

Ingest the review findings register. Perform Domain Detection. Validate each finding against the source documents per the active pack's scope. Classify, specify, sequence, and deliver the implementation plan.
