---
title: Operator Engagement Charter
purpose: Shared discipline methodology for Claude Code ↔ operator engagement on pmo-platform repo changes via the 13-stage pipeline
type: spec
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: "All Claude Code skills + chips + spokes producing operator-directed outputs; the 13-stage pipeline stage shards (operator-engagement contract); decision-discipline.md / reversibility-protocol.md / review-discipline-principles.md (sibling disciplines this charter composes with)"
applies_to: All Claude Code skills + chips + spokes producing operator-directed outputs
parallel_to: decision-discipline.md, reversibility-protocol.md, review-discipline-principles.md
source: "2026-05-04 engagement research brief"
companion_brief: <OPERATOR_INSTANCE_ANALYSIS_PATH>/engagement-research-2026-05-04/SUMMARY.md
---
<!-- reference-durability: allow-link -->

# Operator Engagement Charter

## Purpose

This charter codifies the principles and mechanisms governing Claude Code ↔ operator engagement on `pmo-platform` repo changes via the 13-stage pipeline. It is a peer to [decision-discipline.md](../disciplines/decision-discipline.md), [reversibility-protocol.md](reversibility-protocol.md), and [review-discipline-principles.md](../disciplines/review-discipline-principles.md) — together these four principle docs define the shared discipline methodology that all skills and chips/spokes must apply when producing operator-directed outputs. The charter is lean by design; the depth surface is the companion research brief. External literature anchors each principle to behavioral, HCI, and communications research; platform-internal mechanisms specify the observable behaviors an external auditor (`pmo-qa-auditor` / `build-reviewer`) can detect from artifact state.

## Definition

An **engagement-class output** is any artifact produced by a Claude Code agent that is directed at the operator and intended to either (a) inform operator state without requiring action, (b) request a decision or approval, (c) escalate a blocker, or (d) acknowledge completion of a delegated unit of work. Engagement-class outputs include: PR bodies, sub-task comments, stage routing comments, decision briefings, escalation blocks, RELEASE_LOG appends, daily/weekly digests, ppm-agent Section 5 emissions, and any chip/spoke output posted to a GitHub Issue or sub-task. **Non-engagement-class outputs** include: file writes to platform artifacts (skills, governance, code), git commits, and internal agent reasoning that never reaches the operator.

The charter applies to every engagement-class output. The 5-class taxonomy in §4 partitions all engagement-class outputs into named structures; every output declares its class implicitly via structure or explicitly via a class label.

## Scope

**In scope.** All Claude Code ↔ operator engagement for `pmo-platform` repo changes via the 13-stage pipeline. All skills declaring an `autonomy_tier` in SKILL.md frontmatter. All chips and spokes producing operator-directed output via `gh issue comment` or `mcp__ccd_session__spawn_task`. All decision-class artifacts subject to [reversibility-protocol.md](reversibility-protocol.md). Composes with [decision-discipline.md](../disciplines/decision-discipline.md) M1/M2/M3 mechanisms and [review-discipline-principles.md](../disciplines/review-discipline-principles.md) review discipline.

**Out of scope.** Cowork ↔ `projects/` engagement (separate operator-engagement model — Cowork engages the operator on daily PMO ops; charter governs Claude Code engineering engagement only). Non-Claude-Code AI interactions. End-user-of-the-PMO-platform engagement (the platform's deployed skills engage external project stakeholders separately). Implementation guidance for specific skills (deferred to follow-up issues per charter Out-of-scope).

## Section 1 — Automation tier ↔ engagement hierarchy

### Principle

Engagement granularity scales inversely with Autonomy Tier. Higher-tier autonomy means fewer per-action operator touchpoints; lower-tier autonomy means denser per-action confirmation. The engagement hierarchy is the operator-facing consequence of the platform's tier classification — it is not a separate tier system.

### External grounding

See research brief §Area 1 — Parasuraman & Sheridan (2000) automation-levels framework; Lee & See (2004) trust calibration. See §Area 5 — Endsley (2017) automation conundrum (out-of-loop drift mitigated by appropriate engagement granularity).

### Mechanism

Per-stage Autonomy Tier is declared in [stage-to-skill-mode-mapping.md](../../release/references/specs/stage-to-skill-mode-mapping.md) and per-skill Autonomy Tier in [autonomy-tiers.md](autonomy-tiers.md). The hierarchy is:

- **Autonomy Tier 0 (Manual)** — operator approves every action; per-action touchpoint frequency. Used for IRREVERSIBLE-class operations (production deploy authorization, account deletion).
- **Autonomy Tier 1 (Recommend)** — operator approves each decision before execution; per-decision touchpoint. Default for most pipeline-stage gates.
- **Autonomy Tier 2 (Bounded Auto)** — operator approves a declared scope; agent executes within scope without per-action approval. Used for cascade-allowlist skills (per [OPERATIONS.md § Skill Chaining Protocol](../governance/OPERATIONS.md) C1–C7) and Tier 1 finding remediation per the autonomous-execution model.
- **Autonomy Tier 3 (Autonomous)** — operator approves a framework (release plan, governance policy); agent executes within framework without further engagement until escalation triggers fire. Used for routine routing decisions per the release-orchestration-autonomy discipline.

### Release-level dispatch axis (Release Class)

The Autonomy Tier hierarchy above operates per-action. A release-level dispatch axis — Release Class — operates ABOVE the per-action layer, selecting an engagement posture for the release as a whole. Per [release-class-taxonomy.md](../../release/references/specs/release-class-taxonomy.md), every release carries one of 4 classes declared at Stage 3 Phase B3 in the milestone description. The class selects:

- Engagement density at non-gate boundaries (Tight / Standard / Light) — affects spoke-completion briefing cadence and Procedure-2 routing surface.
- Stage 9 Plan Review depth (Deep / Standard / Light) — affects what hub Empirical Verification surfaces in the Stage 9 Decision Briefing.

Release Class and Autonomy Tier compose multiplicatively, not redundantly. Per-class engagement-posture recommendations are defaults; operator may override per-release with documented rationale in the milestone-description Rationale sub-field.

#### Per-gate-class framing directives (standing config)

The per-release override above lets the operator override per-class posture *defaults*. A **per-gate-class framing directive** is the finer-grained, additive companion: a standing block — authored once in the milestone description alongside the `## Release Class` H2 (NOT a separate config file) — that enriches what a NAMED gate-class renders, without re-deciding the gate. Each field rides an existing rail; together they are **ADD-only** (see the guardrail below).

**Directive schema** (one block per gate-class the operator wishes to enrich):

| Field | Type | Definition |
|---|---|---|
| `gate_class` | enum | The gate the directive applies to. Closed set: `stage-9-go-no-go`, `stage-12-execute`, `d-class-decision`, `collective-review-scope-lock` (the named gates the hub renders in main-thread chat). |
| `require_options` | list[string] | Option labels the gate MUST surface IN ADDITION TO whatever the hub independently enumerates. ADD-only. |
| `surface_dimensions` | list[string] | Decision dimensions the gate's briefing MUST display IN ADDITION TO the hub's defaults (e.g., `blast-radius`, `rollback-feasibility`). Composes with the Decision Briefing Information Sufficiency clause in `hub-spoke-bridge.md`: the directive NAMES the dimensions; the sufficiency clause enforces they are printed before the prompt. ADD-only. |
| `principles_emphasis` | list[`principle_id`] | Design-principle register entry ids (`DP-N`, per `core/standards/design-principle-register.md`) whose conformance verdict the operator wants emphasized in this gate-class's briefing. Values are register `principle_id`s. ADD-only. |
| `pre_decided_default` | string \| OMIT | A standing pre-decided stance for this gate-class that auto-populates the D-Gate `Pre-decided` field when no per-decision pre-decision is on record. A per-decision stance takes precedence (the default is the fallback, not an override). |

**Applicability:**
- A directive block is OPTIONAL per gate-class — omission means the gate renders with hub defaults only (the pre-directive behavior; no regression).
- A directive's fields are individually optional.
- Directives are RECOMMENDATION-enriching, never RECOMMENDATION-replacing: the hub's independent enumeration, dimension surfacing, and recommendation still fire; the directive only guarantees ADDITIONAL named items appear.
- `principles_emphasis` values MUST be `principle_id`s defined in `core/standards/design-principle-register.md`; an id with no matching register entry is a `[STRUCTURAL-DEFECT]` (dangling reference), caught by `deploy.sh --check` Check 45's consumer-id resolution.

**ADD-never-SUBTRACT guardrail:** Framing directives ADD options, dimensions, and principle-emphasis to a rendered gate; they NEVER remove, suppress, or override what the hub independently surfaces. The rendered set is the union of hub-defaults and directive items (`hub-defaults ⊆ rendered`); a directive that would hide a hub-enumerated option, drop a hub-surfaced dimension, or suppress a conformance verdict is a `[STRUCTURAL-DEFECT]`. This is an invariant the hub honors at gate-render time; runtime enforcement is deferred (this pass ships the schema + the render-time read, not a separate union-checking gate). The operator enriches the gate; the operator does not use the directive to render a thinner gate than the hub would produce unaided.

**`principles_emphasis` → register binding:** the field's values are `DP-N` ids from `core/standards/design-principle-register.md` (the source of truth for the id set). A directive naming `principles_emphasis: DP-5, DP-4` instructs the hub to emphasize the Stability and Simplicity conformance verdicts in that gate-class's briefing.

**Worked sample** (authored in the milestone description, alongside `## Release Class`):

```
## Gate-Class Framing Directives
### gate_class: stage-9-go-no-go
require_options:
  - defer-to-next-release
surface_dimensions:
  - blast-radius
  - rollback-feasibility
principles_emphasis:
  - DP-5   # Stability (design-principle-register.md)
  - DP-4   # Simplicity
pre_decided_default: OMIT
```

This directive guarantees the Stage 9 GO briefing surfaces a `defer-to-next-release` option (in addition to the hub's GO/NO-GO), prints the blast-radius + rollback-feasibility dimensions, and emphasizes the DP-5/DP-4 conformance verdicts — all ADD-only.

Cutover discipline: Applies to all releases going forward.

### Applicability

All 13 pipeline stages; all PMO skills declaring `autonomy_tier` in SKILL.md frontmatter; cascade rules C1–C7 in [OPERATIONS.md § Skill Chaining Protocol](../governance/OPERATIONS.md); CLAUDE.md autonomy section. The hierarchy is operator-facing — operators read CLAUDE.md to understand what to expect; agents read [autonomy-tiers.md](autonomy-tiers.md) and [stage-to-skill-mode-mapping.md](../../release/references/specs/stage-to-skill-mode-mapping.md) to determine touchpoint frequency.

## Section 2 — When / Where / What / How of operator touchpoints

### Principle

Every operator touchpoint declares When (lifecycle anchor), Where (surface), What (artifact + decision), and How (interaction modality) — never implicit. Implicit touchpoints produce ambiguous expectations and operator drift.

### External grounding

See research brief §Area 1 — Nielsen Norman Group on progressive disclosure. See §Area 2 — Sweller (1988) Cognitive Load Theory; Davenport & Beck (2001) attention economics; Tversky & Kahneman (1981) framing.

### Mechanism

Each pipeline stage gate, D-class decision, and escalation specifies its When/Where/What/How explicitly in the chip prompt or stage routing comment. Worked examples:

- **PR review.** When = post-Engineering Commit F. Where = GitHub PR diff view. What = file-state ACs + design-spec conformance + scope-lock conformance. How = comment-thread interaction; PR body declares the verification evidence.
- **Stage 9 GO.** When = post-Stage 8 acceptance. Where = parent issue Stage 9 sub-task. What = go/no-go decision against the Plan Review checklist AND the Release Readiness Scan output per [release-readiness-scan-spec.md](../../release/references/specs/release-readiness-scan-spec.md). How = single-comment confirmation per the governance-theater pattern (whole-plan execution, not per-stage gates). The Release Readiness Scan applies to all releases going forward.
- **D-class decision.** When = pre-execution of decision-bound work. Where = parent issue D-Gate sub-task per [hub-spoke-bridge.md § D-Gate Template](../../release/references/how-to/hub-spoke-bridge.md). What = options + recommendation + reversibility tier. How = operator-rendered decision in sub-task comment.

The When/Where/What/How declaration is the touchpoint's contract — agents do NOT extend or modify it without operator authorization (per the governance-theater pattern).

### Applicability

All 13-stage pipeline gates; all D-Gate decisions per [hub-spoke-bridge.md](../../release/references/how-to/hub-spoke-bridge.md); all escalation surfaces per [autonomous-execution-model.md § Escalate Pattern](../disciplines/autonomous-execution-model.md); all operator-directed comments produced by chips/spokes.

## Section 3 — Approval & signoff ergonomics

### Principle

Approvals are 1-click on the fast path; multi-input only when reversibility-confidence pairing demands it. Approval friction must scale with reversibility tier — not with agent caution.

### External grounding

See research brief §Area 1 — Karaa et al. (2018) on IT decision fatigue; NN/g progressive disclosure. See §Area 5 — Bainbridge (1983) Ironies of Automation; Cvach (2012) alert/alarm fatigue.

### Mechanism

Fast-path approval surface is a single comment ("Approved" or equivalent). Multi-input gates fire only at IRREVERSIBLE-class outputs per [reversibility-protocol.md](reversibility-protocol.md). Cascade approval (per [CLAUDE.md § Universal Preferences (Cascade approval bullet)](<OPERATOR_INSTANCE_CLAUDE_MD>) and [OPERATIONS.md § Skill Chaining Protocol](../governance/OPERATIONS.md) C1–C7) elaborates the `cascade_scope` mechanism: a single Document Tier 1 approval authorizes downstream Document Tier 2 writes within the declared scope.

Worked examples of friction-by-tier:

- **CHEAP / MODERATE.** 1-click approval. Stage 9 GO is canonical. Tier 1 finding remediation under cascade.
- **EXPENSIVE.** Single explicit confirmation; agent surfaces consequences in the request. Charter publication (this artifact's class), governance refactor.
- **IRREVERSIBLE.** Multi-input — Stage 9 GO + explicit Stage 12 Execute confirmation + post-deploy verification. Production merge, mass issue closure, label deletion.

The agent does NOT escalate routine routing decisions to multi-input approval (per the release-orchestration-autonomy and governance-theater disciplines).

### Applicability

All decision-class outputs producing approval requests; all D-Gate decisions; Stage 9 Plan Review; Stage 12 Execute authorization; cascade-allowlist skills (`comms-writer`, `delivery-engine`, `tracker-manager`, `artifact-generator`).

## Section 4 — Unified comms taxonomy

### Principle

Every operator-directed message belongs to exactly one of 5 named classes — **Briefing**, **Escalation**, **FYI**, **Approval Request**, **Digest**. Each class has its own structure, lifecycle, and operator-action expectation. Mixed-class messages produce ambiguous operator response.

### External grounding

See research brief §Area 4 — BLUF (US Army field-manual convention); Minto (1987) Pyramid Principle; Doumont (2009) SCQA; SBAR (Haig et al. 2006); SIOR. See §Area 3 — Mercado et al. (2016) IMPACT framework for agent-transparency comms.

### Mechanism

The 5 classes:

- **Briefing.** BLUF structure; ≤ 200 words; used for D-class gate prep, `ppm-agent` Section 5 (Decisions Needed), Decision Briefings per [decision-discipline.md § Section 2](../disciplines/decision-discipline.md). Required fields: bottom line, options, recommendation, reversibility tier, confidence.
- **Escalation.** 4-field block per [autonomous-execution-model.md § Escalate Pattern](../disciplines/autonomous-execution-model.md): **Trigger / Context / Recommendation / Options**. Fires on retry-cap-exhausted, Tier 1 finding requiring operator decision, D-class decision, Tier 0 premise rejection, iteration-threshold breach, ambiguous state.
- **FYI.** Single paragraph; ≤ 100 words; no operator action expected. Status reads, RELEASE_LOG appends, completed-stage announcements.
- **Approval Request.** Specifies What needs approval, Reversibility tier (per [reversibility-protocol.md](reversibility-protocol.md)), Confidence, Default-on-no-response. Approval is 1-click ("Approved") for CHEAP / MODERATE; multi-input for EXPENSIVE / IRREVERSIBLE.
- **Digest.** Bulleted summary of completed work; ≤ 150 words; non-actionable. `daily-status` and `weekly-status-rollup` outputs.

### Applicability

All operator-directed messages from any agent. `ppm-agent` Section 5 emits Briefings; `release-executor` Stage 12 emits Approval Requests; `daily-status` / `weekly-status-rollup` emit Digests; `autonomous-execution-model.md` Escalate Pattern emits Escalations; stage-routing comments emit FYIs. Mixed-class messages are a charter violation — split into separate single-class messages.

## Section 5 — Observability between gates

### Principle

At each gate boundary, the operator can verify state without prompting the agent. Observability is the principal mitigation for out-of-loop drift between Autonomy Tier 2/3 autonomous execution and operator review.

### External grounding

See research brief §Area 1 — Lee & See (2004) on trust calibration via observability. See §Area 3 — Doshi-Velez & Kim (2017) on interpretability dimensions; Endsley (2017) on automation conundrum mitigation via SAT-style transparency.

### Mechanism

Every stage advance posts a structured comment on the parent issue or sub-task with: stage name, observable artifact (PR diff, commit SHA, file-state ACs verified), next-stage routing, and gate decision rendered (or pending). Per-stage state visible via GitHub Projects field updates (Status / Stage). Post-merge observability lives in [RELEASE_LOG.md](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>) per [release-process.md Stage 12 deployment logging](../../release/governance/release-process.md).

The charter does NOT mandate a new observability surface. The existing **GitHub + git + RELEASE_LOG** triad IS the observability mechanism. Agents inherit observability discipline by emitting standard structured artifacts (commit messages, PR bodies, sub-task comments, project-field updates); operators verify state by reading those artifacts directly without needing to re-engage the agent.

### Applicability

All 13-stage transitions; all hub-spoke handoffs per [hub-spoke-bridge.md](../../release/references/how-to/hub-spoke-bridge.md); all post-merge state. The 6-deliverable output structure required by [review-discipline-principles.md](../disciplines/review-discipline-principles.md) (findings, systemic patterns, residual risk, remediation priority, evidence, root cause) IS the observability contract for review-class skills — observability composes with review discipline.

## Section 6 — Knowledge-adaptive comms

### Principle

Engagement detail scales with the operator's domain familiarity for the affected surface. Over-explaining a familiar surface wastes operator attention; under-explaining an unfamiliar one creates drift risk.

### External grounding

See research brief §Area 2 — Anderson (1977) Schema theory on knowledge-driven information processing; Chi, Feltovich & Glaser (1981) on expert-novice information-needs differences. Note: the modern HCI extension of these foundational works to AI-agent contexts is sparse (see brief §Findings F1) — the charter mechanism uses a platform-internal heuristic in lieu of a single named modern source.

### Mechanism

When proposing changes to a surface, the agent infers operator familiarity from `git log --author=<operator> -- <file>` history:

- **HIGH familiarity.** Operator authored the file within the last 90 days → no surface explanation; recommendation only.
- **LOW familiarity.** Operator's last touch on the file is > 180 days ago, or operator has zero authorship → 1-2 sentence orientation precedes the recommendation.
- **AMBIGUOUS** (between 90 and 180 days). Default: assume HIGH (favor terseness; operator can request orientation if needed).

The charter does NOT prescribe a familiarity API or a tooling surface — agents apply the principle via the git-log heuristic. The mechanism is observable from artifact state (recommendation comment with vs. without orientation prefix), and reviewable by operator self-correction.

### Applicability

Decision Briefings (Stages 4-9); Stage 5 design specs targeting unfamiliar surfaces; cross-skill recommendations from one skill's domain into another. Does NOT apply to fixed-template emissions (PR body template, improvement.yml intake) where the template structure is the audience contract.

## Section 7 — Templates, integrations, tools & platforms

### Principle

Operator-facing templates standardize structure across skills; integration touchpoints (GitHub, Teams, email, Confluence) preserve template fidelity. New operator-directed surfaces extend existing templates — they do NOT author parallel ones.

### External grounding

See research brief §Area 4 — BLUF / SBAR / SCQA / SIOR / Pyramid structural templates. Template-driven communication research demonstrates that fidelity to a known template reduces operator parsing cost and improves response consistency.

### Mechanism

Canonical operator-facing templates live at:

- [.github/PULL_REQUEST_TEMPLATE.md](../../.github/PULL_REQUEST_TEMPLATE.md) — PR body
- [.github/ISSUE_TEMPLATE/improvement.yml](../../.github/ISSUE_TEMPLATE/improvement.yml) + `observation.yml` — intake (per [CLAUDE.md § Continuous Improvement](<OPERATOR_INSTANCE_CLAUDE_MD>))
- [hub-spoke-bridge.md § D-Gate Template](../../release/references/how-to/hub-spoke-bridge.md) — decision gates
- [decision-discipline.md § Section 2](../disciplines/decision-discipline.md) — M1/M2/M3 mechanism templates for Decision Briefings
- [autonomous-execution-model.md § Escalate Pattern](../disciplines/autonomous-execution-model.md) — escalation block format
- [core/rules/git-workflow.md § Batch CLI Query Limits](../rules/git-workflow.md) — query-discipline contract referenced when emitting batch-derived state to operators (per pattern-cache BD-7)

Charter mandate: **any new operator-directed surface MUST extend an existing template, not author a parallel one** (per [CLAUDE.md § Universal Preferences (Pre-creation governance check bullet)](<OPERATOR_INSTANCE_CLAUDE_MD>) — see also pattern-cache BD-3). When templates inadequately cover a new surface, the path is template extension via the governed-change protocol, not parallel template creation.

### Applicability

All 5-class taxonomy emissions per §4; all skills producing operator-directed output. Integration platforms (GitHub-native, Teams export, email digest) consume the templates without restructuring — formatting differences are platform-rendering artifacts, not template variants.

## Section 8 — Base-vs-custom leverage

### Principle

Native Anthropic skills (`anthropic-skills:*` namespace) are the default; PMO custom skills are justified only when the [Anthropic Base-vs-Build Registry](anthropic-base-vs-build-registry.md) observes `independent` or substantive `extends` deltas vs Anthropic baseline.

### External grounding

Internal observability via the [Anthropic Base-vs-Build Registry](anthropic-base-vs-build-registry.md) (MERGED 2026-05-04) — NOT external research literature. The registry is the discipline surface. The companion research brief notes (§Findings F2) that §8's grounding is internal by design and reviewers should NOT flag this section as missing literature citation.

### Mechanism

Before authoring a new PMO skill, consult the registry's 22-row catalog at the audit_baseline_sha. The registry's `anthropic_overlap_status` and `build_buy_observation` fields determine the authoring path:

- **`pass-through`** or substantive **`replaces`** — use the Anthropic skill; do not author a custom equivalent.
- **`independent`** or substantive **`extends`** — custom build is observationally justified per the registry's `build_buy_observation` field.

The registry uses observational language only — the charter inherits that discipline. The charter does NOT prescribe migration or consolidation; it states the observational test for build-vs-buy at skill-authoring time. Skill authors record their consultation outcome in the skill's design spec (Stage 5 sub-task comment) so the build-vs-buy evidence is auditable.

### Applicability

All new skill authoring (`pmo-skill-refiner` Mode 2 — Create New); skill modifications that may consolidate with Anthropic skills (`pmo-skill-editor` Mode A); `release-planner` Mode A scoping when a Bundle includes new-skill issues.

## Section 9 — Composition & Cross-References

This charter composes with peer principle docs and is consumed by downstream specs and skills.

### Relationship to peer principle docs

| Peer doc | Charter sections that compose | Composition |
|---|---|---|
| [decision-discipline.md](../disciplines/decision-discipline.md) | §3 (Approval ergonomics), §4 (Briefing class) | Decision Briefing format inherited verbatim; charter §4 names the class, decision-discipline owns the M1/M2/M3 mechanism templates |
| [reversibility-protocol.md](reversibility-protocol.md) | §3 (multi-input gates), §4 (Approval Request reversibility tier field) | Tier vocabulary CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE consumed; process-weight scaling consumed |
| [review-discipline-principles.md](../disciplines/review-discipline-principles.md) | §5 (observability between gates) | 6-deliverable output structure informs gate-transition comment structure |
| [failure-mode-standard.md](../standards/failure-mode-standard.md) | §7 (templates) | 5-field anti-pattern template is one of the canonical templates |
| [autonomy-tiers.md](autonomy-tiers.md) | §1 (engagement hierarchy) | Autonomy Tier 0–3 vocabulary consumed verbatim |
| [stage-to-skill-mode-mapping.md](../../release/references/specs/stage-to-skill-mode-mapping.md) | §1, §5 (per-stage Automation Tier mapping) | Per-stage automation level consumed |
| [autonomous-execution-model.md](../disciplines/autonomous-execution-model.md) | §3, §4 (Escalate Pattern), §5 (observability via Retry/Escalate audit trail) | Escalation block format, retry caps consumed |
| [anthropic-base-vs-build-registry.md](anthropic-base-vs-build-registry.md) | §8 (base-vs-custom leverage) | Registry IS the observability surface for §8 mechanism |

### Downstream consumers

| Consumer | Surface | How it consumes charter |
|---|---|---|
| All chips/spokes producing operator-directed output | Stage routing comments | Apply §4 (5-class taxonomy) when emitting any operator-directed message |
| `pmo-qa-auditor` | G-class audit gates (future gate, none queued at charter publish) | Structural check that operator-directed outputs declare class per §4 |
| `build-reviewer` | Governance-pack review dimensions | Future enrichment: engagement-conformance dimension cites charter |

## §Pattern Cache (Operator-Engagement Patterns)

### Index pattern

Per Stage 4 D-2 (operator-rendered 2026-05-04), confirmed engagement-related patterns live at native specialized surfaces ([failure-mode-standard.md](../standards/failure-mode-standard.md), [review-discipline-principles.md](../disciplines/review-discipline-principles.md), [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>), [engineering/rules/](<OPERATOR_INSTANCE_ENGINEERING_RULES_PATH>)). This appendix is a **one-line index** — entries link to the native home; the home owns the canonical pattern body. Engagement patterns surface from operator corrections via the pattern-cache scan mechanism in [decision-discipline.md § 4](../disciplines/decision-discipline.md).

### Seed entries (13 patterns from 2026-04-24 reorg)

The following entries were absorbed from the 2026-04-24 backlog reorganization session (closed under Engineering Commit E):

- **BD-1 Milestone count ≠ sub-slice count** — `failure-mode-standard.md` § Examples → Reorg / structure-change examples (PROC). Sub-slices are sizing units; milestones are shippable capability containers.
- **BD-2 Reorg scope overreach** — `failure-mode-standard.md` § Examples → Reorg / structure-change examples (PROC). Reorganization scope stops at milestone structure; do not pre-bundle releases.
- **BD-3 Pre-creation governance check** — `CLAUDE.md § Universal Preferences` (Pre-creation governance check bullet). Search existing governance for a defined home before authoring a new file.
- **BD-4 Sizing convenience over best practice** — `failure-mode-standard.md` § Examples → Reorg / structure-change examples (PROC). 5-15 tickets per milestone default; exceed only with N-1 internal-edge cohesion test.
- **BD-5 Thin self-containment in descriptions** — `failure-mode-standard.md` § Examples → Reorg / structure-change examples (OUT). Milestone descriptions must carry goal + scope + lift + prereqs + deliverables + AC + runbook + rollback per Stage 3 Bundle output spec.
- **BD-6 Version-collapse vs work-type signaling** — `failure-mode-standard.md` § Examples → Reorg / structure-change examples (OUT). Major-version boundaries signal work-type transitions; do not collapse multi-phase roadmaps under one major version.
- **BD-7 Query-limit silent truncation** — `engineering/rules/git-workflow.md` § Batch CLI Query Limits. Verify N ≥ total dataset size before any `--limit N` batch operation.
- **BD-8 Intermediate-artifact perpetuity** — `CLAUDE.md § Universal Preferences` (Intermediate-artifact discipline bullet). Sizing analyses + scratch breakdowns are intermediate means; absorb into target structure and discard.
- **GD-1 Numeric verification before subjective grouping** — `review-discipline-principles.md` § 1 Rule 11. Numeric tests (dependency edge counts, threshold scores) preferred over thematic grouping; auditable, repeatable, survives operator handoffs.
- **GD-2 Confidence-tiered evidence with file:line cites** — `review-discipline-principles.md` § 1 Rule 12. Findings carry HIGH/MEDIUM/LOW confidence + cited evidence reference; HIGH ships clean, MEDIUM holds for review, LOW downgrades to observation.
- **GD-3 Per-batch verification on iterated work** — `review-discipline-principles.md` § 1 Rule 13. Verify each batch's outcome before proceeding; failure halts the sequence pending operator decision.
- **GD-4 N-1 internal edges as cohesion test** — `review-discipline-principles.md` § 1 Rule 14. Tight bundle of N items has ≥N-1 internal edges; below threshold, identify weakest cut and split.
- **GD-5 Write-first-speak-second** — `CLAUDE.md § Quality Standards / Guardrails` (existing Write-first-speak-second guardrail; this generalization extends to state mutations broadly — file writes, GitHub Issue/label/milestone changes, batch operations).

### Schema for future additions

When future operator corrections elevate to Confirmed Patterns (per [decision-discipline.md § 4 Pattern Cache Infrastructure](../disciplines/decision-discipline.md)) and have engagement implications, add an index entry here matching the 13-row format:

```
- **<ID> <one-line summary>** — `<native surface path>` § <native section>. <one-sentence why-this-matters>.
```

ID conventions:

- **BD-N** — Drafting/reorg-class patterns (failure modes from solutioning/planning errors)
- **GD-N** — General-discipline patterns (anti-laziness rules)
- **MEM-N** — Memory-promoted patterns (per [decision-discipline.md § 4](../disciplines/decision-discipline.md) emergence rule)

The native surface is canonical — body content does NOT live in this appendix. This file contains pointers only.

---

*Charter authored 2026-05-04 in support of Stage 5 design. Companion research brief: `<OPERATOR_INSTANCE_ANALYSIS_PATH>/engagement-research-2026-05-04/SUMMARY.md`.*
