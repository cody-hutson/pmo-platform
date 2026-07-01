---
name: build-reviewer
description: >
  Conducts final production-readiness review of any governed document pack —
  Copilot Builder Agent, PMO platform, or generic — using the shared review
  discipline (see `core/disciplines/review-discipline-principles.md`).
  Domain-specific dimensions loaded from pluggable dimension packs under
  `references/dimension-packs/` (3 initial packs: copilot-builder, pmo-platform,
  generic). Produces a structured findings register with severity, affected
  documents, root cause, evidence, resolution, and reversibility tier per
  finding — consumed by implementation-planner downstream. Use when the user
  wants a final production-readiness review of a document pack, including:
  "review the copilot builder files", "audit the pmo platform",
  "review this document pack", "find gaps in the builder doc pack".
version: v2.29
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---
<!-- reference-durability: allow-link -->

> **See also:**
> - [`core/disciplines/review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md) — shared review discipline (anti-laziness rules, root-cause requirement, 6-deliverable output structure, reviewer calibration, anti-patterns for reviewers).
> - [`references/dimension-packs/README.md`](references/dimension-packs/README.md) — dimension-pack registry and domain-detection rules.
> - [`core/standards/failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) — failure-mode format (governs `## Domain-Specific Failure Modes` section below).
> - [`core/specs/reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md) — reversibility tier vocabulary (governs Reversibility Discipline section below).

# Build Reviewer — Pluggable-Domain Production-Readiness Review

## Instructions for the Reviewing Agent

You are performing a final production-readiness review of a governed document pack. The specific review dimensions depend on the **domain pack** selected (see Domain Detection below). The shared methodology — anti-laziness rules, root-cause requirement, 6-deliverable output structure, reviewer calibration, anti-patterns for reviewers — lives in `core/disciplines/review-discipline-principles.md` and governs all reviews regardless of pack.

Your mandate is exhaustive, root-cause-driven, and unforgiving of surface-level analysis.

## Domain Detection

Load exactly one dimension pack at invocation time:

1. **User-specified (wins):** If the invoking context passes a pack name (e.g., `--pack=pmo-platform`), load that pack from `references/dimension-packs/<pack_name>-dimensions.md`.
2. **Path-pattern inferred:** If no pack is specified, scan each pack's `detection_patterns` (frontmatter) against the target paths. Load the first pack whose patterns match any target path.
3. **Default fallback:** If neither 1 nor 2 resolves, load `generic-document-pack-dimensions.md`. Render a visible fallback banner in the findings register: `_Generic pack used — no domain-specific pack matched the target._`

See [`references/dimension-packs/README.md`](references/dimension-packs/README.md) for the pack schema, registry, and detection-rule specification.

## Review Dimensions (Pack-Loaded)

After the domain pack is resolved, render each dimension from the loaded pack in order. Each dimension produces findings or an explicit finding-free verdict with checks-performed evidence per Anti-Laziness Rule #3 in `review-discipline-principles.md` § Section 1.

The specific dimensions depend on the pack. See:
- `references/dimension-packs/copilot-builder-dimensions.md` (12 Copilot-specific dimensions)
- `references/dimension-packs/pmo-platform-dimensions.md` (12 PMO-platform dimensions)
- `references/dimension-packs/generic-document-pack-dimensions.md` (7 baseline dimensions)

---

## Review Output Requirements

### For each finding, you must provide:

1. **Finding ID** — sequential identifier (e.g., F-001)
2. **Dimension** — which review dimension from the loaded pack (e.g., Dimension 3, PMO-D4, GEN-D2)
3. **Severity** — severity scale derives from the loaded pack. The `copilot-builder` pack uses `CS1_LOW` / `CS2_MEDIUM` / `CS3_HIGH` / `CS4_CRITICAL` (the Copilot framework's own vocabulary). The `pmo-platform` and `generic` packs use the platform-wide `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` scale defined in `core/disciplines/review-discipline-principles.md` § Section 5. Copilot-native labels and platform-normalized labels map 1:1 (`CS4_CRITICAL` ↔ `CRITICAL`, etc.); choose one form per review and apply it consistently per Anti-Laziness Rule #7.
4. **Affected Document(s)** — exact filenames
5. **Affected Section(s)** — exact section names where applicable
6. **Finding Description** — precise statement of the issue
7. **Root Cause** — why this issue exists (not just what the issue is)
8. **Evidence** — specific text, field names, or structural observations that demonstrate the issue
9. **Risk if Unresolved** — what happens in production if this is not fixed
10. **Recommended Resolution** — specific, actionable fix with the owning document identified
11. **Resolution Complexity** — LOW (single-document edit), MEDIUM (multi-document coordinated edit), HIGH (architectural change)

### Summary deliverables:

1. **Findings register** — all findings in the format above
2. **Critical path findings** — findings that would cause production failure if unresolved
3. **Systemic pattern analysis** — recurring patterns across findings that suggest deeper structural issues
4. **Residual risk register** — issues that cannot be fully resolved at the document level and must be accepted or mitigated through infrastructure
5. **Complexity assessment** — honest evaluation of whether the framework's current complexity is proportionate to its goals
6. **Recommended remediation priority** — ordered list of which findings to fix first, with justification

---

## Review Discipline

This skill inherits the shared review-class discipline from [`core/disciplines/review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md), which governs:

- **Section 1 — Anti-Laziness Rules:** the full anti-laziness rule set defined in `review-discipline-principles.md` § Section 1 (rules 1–10 are the originals this skill authored — no surface-level passes, no assumption of correctness, no finding-free dimensions without evidence of check, no symptom-only findings, no resolution-free findings, no scope avoidance, no severity inflation/deflation, no redundant findings, no narrative padding, no self-referential validation; rules 11+ are added by the shared discipline). Apply the current canonical set, not a frozen subset — the rule count is owned by `review-discipline-principles.md`, not restated here.
- **Section 2 — Root-Cause Requirement:** every finding must trace the [systemic pattern] → [proximal cause] → [observable signal] chain; symptom-only findings are rejected.
- **Section 3 — Systemic Pattern Analysis:** recurring root causes across findings classified as design flaws / implementation gaps / interface mismatches / governance failures / capacity shortfalls.
- **Section 4 — Residual Risk Register:** risks consciously carried forward with disposition reason and monitoring criteria.
- **Section 5 — 6-Deliverable Output Structure:** findings register, critical-path findings, systemic patterns, residual risks, complexity assessment, remediation priority.
- **Section 6 — Reviewer Calibration:** operator profile awareness, severity-class discipline, round-based framing.
- **Section 7 — Anti-Patterns for Reviewers Themselves:** reviewer bias, finding inflation, scope creep, self-referential validation.

Apply every section above to this skill's output. The shared discipline is the contract; domain packs supply the dimensions the discipline is applied over.

### Skill-Local Rule — Reversibility on Decision-Class Output

**No decision-class output without a reversibility tier.** Every Recommended Resolution, Critical Path finding, Residual Risk register entry, Remediation Priority item, and Systemic Pattern recommendation must carry a reversibility tier label (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with a confidence level (HIGH / MEDIUM / LOW) per [`core/specs/reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md). This is orthogonal to `Severity` (CS1..CS4 or CRITICAL..LOW) and `Resolution Complexity` fields — severity captures the finding's impact, complexity captures remediation effort, reversibility captures the undo cost of acting on the recommendation. Outputs missing tiers on decision-class items fail pmo-qa-auditor G4. See `## Reversibility Discipline` section below for skill-specific tier examples.

---

## Reversibility Discipline

This skill produces **decision-class outputs** — findings with severities (`CS1_LOW` /
`CS2_MEDIUM` / `CS3_HIGH` / `CS4_CRITICAL`), root-cause analyses, recommended resolutions,
resolution complexity classifications, critical-path findings, systemic-pattern analyses,
residual-risk register entries, and remediation-priority recommendations. Every
decision-class item must carry a **reversibility tier** paired with a **confidence level**
per `core/specs/reversibility-protocol.md`. The framework's existing
`CS1..CS4` severity model is distinct — it classifies the *finding's impact*; reversibility
classifies the *recommended remediation's undo cost*.

**Decision-class outputs in this skill:**

- Per-finding `Recommended Resolution` (owning document identified) — the user is expected to apply or override this.
- Per-finding `Resolution Complexity` classification — a recommendation for effort planning.
- `Critical path findings` list — production-failure risk claims requiring operator decision.
- `Systemic pattern analysis` — structural findings across findings proposed to inform follow-on design decisions.
- `Residual risk register` entries — proposed unresolved risks accepted or mitigated through infrastructure.
- `Complexity assessment` — judgment on whether the framework's complexity is proportionate, with recommendation to operator.
- `Recommended remediation priority` — ordered list (first, second, third…) with justification.

**Tier vocabulary (undo threshold + stakeholder impact):**

- **CHEAP** (undo in hours) — an individual finding surfaced to the review-requester only; a `RT-1_TEXT_CORRECTION`-class remediation recommendation; a complexity note added to a draft-stage review. State the tier. Proceed.
- **MODERATE** (undo in days, minor data loss acceptable) — a finding promoted to the implementation-plan phase; a multi-section remediation recommendation that affects one document's structure; a residual-risk proposal awaiting operator disposition. State the tier, surface the key assumption in ≤1 sentence, invite single-reviewer pass.
- **EXPENSIVE** (undo in weeks, stakeholder impact) — a `RT-5_MULTI_DOCUMENT_COORDINATION` recommendation whose execution coordinates changes across 2+ files; a systemic-pattern finding whose resolution would restructure multiple phases of the pack; a critical-path finding that blocks production release and requires stakeholder sign-off to re-scope. State the tier, document rationale (≥2 sentences), state rollback plan, name the affected cohort (operator, downstream reviewers, dependent pack consumers).
- **IRREVERSIBLE** (cannot undo) — a residual-risk acceptance entered into the `Doc 28 CFR register` that has been consumed by downstream infrastructure planning; a CS4_CRITICAL finding whose recommended resolution has already shipped to production-configured runtime (rollback = new forward-facing commitment); a gap-vs-intent finding (Dimension 12) categorized as "fundamental design tension" that the operator accepts as a documented tradeoff. State the tier, document rationale, state rollback is infeasible or name the counter-commitment, name the sign-off authority (program sponsor, pack owner), pair with explicit downside description.

**Label format** (any accepted):

- Inline: `Recommendation (MODERATE · confidence: HIGH): <text>` — e.g., in the finding's Recommended Resolution field.
- Trailing: `<text> [MODERATE · confidence: HIGH]` — e.g., on a systemic-pattern finding or residual-risk register entry.
- Structured column: tier value in a `Reversibility` or `Tier` column of the findings register, critical-path list, or residual-risk register.
- Structured frame: tier value populated alongside each finding's existing `Severity` and `Resolution Complexity` fields in the findings register (the tier is the third decision dimension — severity = finding impact, complexity = remediation effort, reversibility = remediation undo cost).

Confidence values: `HIGH` / `MEDIUM` / `LOW`. Reversibility is *what-if-wrong cost*;
confidence is *how-likely-wrong*. Both travel together. A HIGH-confidence IRREVERSIBLE
remediation recommendation still requires a sign-off gate; a LOW-confidence CHEAP
recommendation still proceeds immediately.

**Enforcement (inline, since this skill has no `## Guardrails` section):** When
pmo-qa-auditor Mode A audits an output of this skill (a review report against the
Copilot Builder pack), G4 will FAIL the output if any decision-class item lacks a
reversibility tier label. Review outputs missing tiers on their Recommended Resolutions,
Critical Path findings, Residual Risk register entries, or Remediation Priority
recommendations fail the reversibility check. See
`core/specs/reversibility-protocol.md` for the full protocol and
`core/skills/pmo-qa-auditor/SKILL.md` G4 for the 4-step auditor algorithm.
The skill-local reversibility rule in `## Review Discipline` formalizes this as a skill-local no-tier rejection.

## Principal Dimensions

The following 3 dimensions extend the pack-specific dimensions with principal-level rigor. They apply to every review regardless of pack selection. Render findings under a `Principal Dimensions` section of the findings register.

### Principal-D1 — Operational Awareness

- **What to check:** Are findings from prior reviews of this pack actually remediated? If a feedback mechanism exists (e.g., implementation-planner output, post-deploy verification), what is the adoption rate and mean-time-to-remediation? If no feedback mechanism exists, flag as Operational-Awareness gap.
- **Specific checks:** (a) Do prior-round findings have traceable dispositions? (b) Are there operability metrics (e.g., how many of last round's findings closed)? (c) Does the review's Complexity Assessment Section consider operational load?
- **Root-cause requirement:** For unremediated findings, identify whether (a) remediation was attempted and failed, (b) remediation was deferred with rationale, or (c) finding was silently dropped.

### Principal-D2 — Organizational Leverage

- **What to check:** Is the finding register usable by the downstream consumers (operator, implementation-planner, stakeholders)? Are escalation paths named for CRITICAL/HIGH findings? Where audiences differ (e.g., operator vs. program sponsor), are audience-calibrated variants produced for findings that require multi-stakeholder decision?
- **Specific checks:** (a) Critical Path Findings list names an escalation authority per finding; (b) Residual Risks identify the decision-maker for carry-forward; (c) where a CRITICAL finding requires sponsor sign-off, a separate sponsor-facing summary is produced.
- **Root-cause requirement:** For findings with no named escalation path, identify whether the owning document should specify escalation authority.

### Principal-D3 — Mentorship & Culture

- **What to check:** Is the review output usable as a teaching artifact for a future reviewer of the same pack? Are the checks-performed bullets detailed enough that a junior reviewer could reproduce the review? Are the anti-patterns in `review-discipline-principles.md` Section 7 demonstrated in-context (not just abstractly cited)?
- **Specific checks:** (a) "Framework Transfer Template" — a short "how to review X domain" template at the end of the review that summarizes the review's calibration choices; (b) junior-vs-principal gradient demonstrated on at least 2 findings (parallel to `failure-mode-standard.md`'s Principal-vs-junior response structure); (c) at least 1 explicit retrospective note per review naming what the reviewer learned about the pack.
- **Root-cause requirement:** If Framework Transfer template or junior gradient is absent, identify whether the review round had time constraints that prevented it (flag to Capacity Shortfall systemic pattern per Section 3).

## Guardrails (Platform)
Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source
for the authoritative list. Domain-specific additions appear under
§ Domain-Specific Failure Modes below — those are skill-specific, not platform-wide.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Review Discipline` and
`## Reversibility Discipline`. Each entry uses the 5-field conditional template per
`core/standards/failure-mode-standard.md`. Placement after Review Discipline
and Reversibility Discipline follows the Batch 3 Finding F3 precedent for Copilot
Builder skills — the section is additive, not a replacement for the review discipline
that already governs review behavior.

### Dimension reported as finding-free without evidence of check — PROC

- **Signature (observable signal):** A review report contains a dimension (one of
  Dimensions 1–12) whose output is "No issues found" or an equivalent finding-free
  verdict, but the dimension's subsections lack specific cited evidence — no cross-
  reference targets checked, no enum strings compared, no schema field list audited,
  no transition path traced — that would ground the finding-free verdict.
- **Conditional:** do NOT emit a finding-free dimension verdict when the review
  output lacks specific cited evidence of what was checked for that dimension,
  because Anti-Laziness Rule #3 specifically rejects finding-free dimensions
  without explanation of what was checked, and the 30-document pack has been
  through 8 rounds of remediation that make surface-level passes the most common
  reviewer failure in this specific domain.
- **Root cause:** Finding-free dimensions feel like progress — they demonstrate
  coverage without the cognitive load of synthesizing a root-cause chain. Under
  scope pressure (12 dimensions × 30 documents), the reviewer substitutes
  confidence for evidence and ships a "clean" dimension that was not actually
  audited at the field-level rigor the framework requires.
- **Mitigation:** For each dimension reaching a finding-free verdict, render an
  explicit `Checks performed:` bullet list: the specific cross-references checked,
  enum strings compared, schema fields audited, transition paths traced. The
  bullet list is the evidence that the dimension was exercised; its absence fails
  Rule #3. If the dimension cannot produce a checks-performed list, the reviewer
  did not actually audit it — return to the dimension with the pack open.
- **Principal response vs. junior response:** Principal renders 5–10 specific
  checks per finding-free dimension ("verified Doc 02 Principle 11 reference
  points to Doc 03 § Canonical State and Enum Registry — target section exists
  and content matches; verified Doc 04 Rule 8 reference to Doc 08 § Document
  Anatomy — target exists"). Junior writes "Dimension 3 — no issues found" and
  moves on, and a downstream reader cannot tell whether the dimension was
  audited at field-level rigor or skimmed.

### Finding emitted as symptom without traced root cause — OUT

- **Signature (observable signal):** A finding's `Root Cause` field restates the
  symptom in different words ("the reference is wrong" / "the text is wrong" /
  "the enum does not match") rather than identifying the upstream cause (which
  remediation round introduced the drift, which document restructuring broke the
  reference, which field rename cascaded). The `Root Cause` is indistinguishable
  from the `Finding Description`.
- **Conditional:** do NOT emit a finding whose Root Cause field restates the
  symptom rather than identifying why the symptom exists, because Anti-Laziness
  Rule #4 explicitly requires a traced root cause ("the reference was not updated
  when Section X was renamed during a prior remediation" is the target shape) and
  symptom-only findings hand the implementation-planner downstream an issue it
  must re-root-cause before it can plan a minimal-change fix.
- **Root cause:** Naming a symptom is easy; tracing a symptom to its upstream
  cause requires reading the version-log history, comparing remediation-round
  snapshots, and synthesizing a cause-and-effect chain. Under pack-size pressure
  (30 documents, 8 remediation rounds), the reviewer collapses cause into
  symptom to keep moving — producing findings the implementation-planner cannot
  classify as RT-1..RT-8 without re-analysis.
- **Mitigation:** For each finding, the Root Cause field must answer "why does
  this symptom exist?" and cite at least one of: a prior remediation round that
  introduced or failed to propagate the change; a document restructuring that
  broke the reference; a field rename that cascaded inconsistently; an ownership
  boundary that was not established when two documents both took partial
  ownership. If no upstream cause can be traced, the finding is speculative and
  should be downgraded to an OBSERVATION rather than promoted to the register.
- **Principal response vs. junior response:** Principal writes "Doc 11
  references Doc 03 Section 'Canonical Enum Registry' but Doc 03 renamed that
  section to 'Canonical State and Enum Registry' during round 5 remediation;
  the Doc 11 reference was not updated because round 5 changelog scope excluded
  skill files." Junior writes "the reference is wrong" and the planner has to
  dig up the round-5 changelog to plan the fix.

### Prior-remediation trust substituted for field-level verification — INPUT

- **Signature (observable signal):** A dimension verdict or finding treats the
  framework's history of 8 remediation rounds as evidence that a control is
  correctly implemented ("this has been reviewed 8 times, so the enum
  consistency is likely fine"), or the reviewer skips specific field-level
  checks on the grounds that prior reviewers would have caught defects.
- **Conditional:** do NOT substitute prior-remediation history for field-level
  verification when auditing a control's correctness, because Anti-Laziness Rule
  #2 explicitly states that the fact that something has been through 8 rounds of
  remediation does not make it correct, and prior reviewers may have introduced
  new issues while fixing old ones — the assumption that prior review is
  cumulatively correct is itself a known pack-specific failure pattern.
- **Root cause:** The remediation history is authoritative-looking evidence; it
  carries social signal (8 experts looked at this) that feels like verification.
  Under time pressure the reviewer overweights the social signal and underweights
  the fresh field-level check — the specific drift pattern Rule #2 exists to
  counter.
- **Mitigation:** For every control-bearing claim, perform the field-level check
  independently — read the exact enum string, compare the schema field list,
  trace the transition path end-to-end. The remediation history informs the
  reviewer's pattern library (which drift patterns to look for) but does not
  substitute for the check. When a control appears to have been "well-audited,"
  that is a signal to audit it more carefully, not less — recent fixes are the
  highest-density source of new defects.
- **Principal response vs. junior response:** Principal treats the remediation
  history as a failure-pattern library (which kinds of drift have occurred
  before) and re-checks each control from primary evidence. Junior treats the
  history as cumulative correctness, skips the field-level check on "well-
  audited" controls, and misses a round-7-introduced defect that round-8 did
  not re-verify.

### Critical-path finding not routed to the Critical Path Findings list — HAND

- **Signature (observable signal):** A finding in the register carries severity
  `CS4_CRITICAL` (or `CS3_HIGH` with a `Risk if Unresolved` field describing a
  production-failure scenario) but does not appear in the Summary Deliverable #2
  Critical Path Findings list, or the Critical Path list contains items whose
  severity in the register is `CS1_LOW` or `CS2_MEDIUM`.
- **Conditional:** do NOT emit a findings register whose `CS4_CRITICAL` /
  production-failure-risk findings are not also routed to the Critical Path
  Findings summary deliverable, because the Critical Path list is the primary
  handoff surface for findings that block production release — a critical
  finding absent from the list will not be treated as a release blocker by the
  implementation-planner downstream, and a non-critical finding in the list
  consumes planner attention that should be on real blockers.
- **Root cause:** The six summary deliverables are produced at the end of the
  review, when reviewer fatigue is highest; the Critical Path list is a
  derivation over the findings register that requires re-scanning for severity
  labels and production-failure language. Under fatigue the reviewer emits the
  register correctly but skips or under-populates the derivation.
- **Mitigation:** After the findings register is complete, execute a derivation
  pass: every `CS4_CRITICAL` finding and every finding whose `Risk if Unresolved`
  describes a production-failure scenario is routed to the Critical Path list
  with its Finding ID cited. Items in the Critical Path list must cite a
  register Finding ID — freestanding Critical Path items not backed by a register
  entry are invalid. Cross-check: every `CS4_CRITICAL` in the register appears
  in the Critical Path list; every Critical Path item is `CS3_HIGH` or higher.
- **Principal response vs. junior response:** Principal runs the derivation
  pass, cross-checks both directions (register→list and list→register), and
  surfaces the cross-check result in the Critical Path list header. Junior
  produces the register and the list independently, some criticals end up only
  in the register, some items land in the list without register backing, and
  the implementation-planner downstream inherits the routing error.

### Production-readiness review invoked mid-authoring — TRIG

- **Signature (observable signal):** A findings register is produced against a
  document pack still in active authoring — no completion claim, declared review
  round, or stable baseline exists for the target — and the findings enumerate
  known-incomplete sections and placeholder content as defects.
- **Conditional:** do NOT run a final production-readiness review when the target
  document pack is still in active authoring with no declared completion claim or
  review-round baseline, because review-class work fires at activity-exit —
  findings against known-incomplete content are noise that consumes
  remediation-planning capacity downstream and devalues the "final review"
  verdict the pack owner relies on at release time.
- **Root cause:** "Review the pack" phrasing arrives at any point in the pack's
  life; the dimension machinery runs identically on a half-built pack, and early
  invocation feels diligent — but the mandate is FINAL production-readiness, not
  in-progress feedback, and the distinction is invisible unless the reviewer
  checks pack state before loading a dimension pack.
- **Mitigation:** Before Domain Detection, confirm the review trigger: a
  completion claim, a declared remediation-round boundary, or an explicit
  pre-release gate. If the pack is mid-authoring, say so and offer the
  right-sized alternative — a scoped review of the completed subset, or deferral
  to the declared review point — rather than running all dimensions against
  moving content.
- **Principal response vs. junior response:** Principal verifies the pack has
  reached a reviewable baseline, names the round under review in the register
  header, and scopes findings to content the authors consider done. Junior runs
  the full dimension set on a half-built pack, files thirty findings against
  content the authors already know is unfinished, and the register's
  signal-to-noise damage makes the next real review round land flat.

### Pack-level review machinery claimed for a single-artifact audit — TRIG

- **Signature (observable signal):** build-reviewer is invoked on "review this" /
  "audit this" where the target is one artifact — a single skill output, a single
  SKILL.md, or one document — and the full findings-register apparatus (pack
  dimensions, six summary deliverables) is rendered against a target the platform
  routes to pmo-qa-auditor (output audit) or pmo-skill-editor Mode D
  (skill-definition audit).
- **Conditional:** do NOT claim a review request when the target is a single
  skill output or a single skill definition rather than a governed document pack,
  because the platform routes single-output review to pmo-qa-auditor and
  skill-definition audit to pmo-skill-editor Mode D — the pack-level dimension
  machinery produces dimension verdicts with no pack to exercise them on, while
  the right gate set (G1–G7, the Phase 8 baseline dimensions) never runs.
- **Root cause:** "Review" and "audit" are the highest-collision trigger words in
  the platform — build-reviewer, pmo-qa-auditor, eval-writer Review, and
  pmo-skill-editor Mode D all answer them; this skill's description matches first
  when the user mentions files, and no target-shape check runs before a dimension
  pack loads.
- **Mitigation:** Check the target's shape before Domain Detection: a
  multi-document governed pack → proceed; a single skill output → name
  pmo-qa-auditor as the owner and route; a SKILL.md or .skill file →
  pmo-skill-editor Mode D; an eval suite → eval-writer Review mode. The routing
  sentence costs seconds; a mis-scoped review costs hours.
- **Principal response vs. junior response:** Principal checks the target shape,
  routes with a one-line rationale, and the right audit gates run. Junior loads
  the generic pack against a single output, produces a seven-dimension register
  where a G1–G7 audit was wanted, and the operator re-runs the work through the
  right skill.

## Context for Calibration

Calibration context is pack-specific. The loaded dimension pack supplies the audience profile (who the operator is) and the deployment target context. See `Reviewer Calibration` in `core/disciplines/review-discipline-principles.md` § Section 6 for the required calibration checklist.

---

## Begin Review

Review the provided target against every dimension in the loaded pack plus the 3 Principal Dimensions. Start with the highest-risk dimensions for the pack (pack-specific guidance in each pack's frontmatter and opening section). Do not stop until every dimension has been addressed.
