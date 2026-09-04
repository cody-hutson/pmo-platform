---
title: Agent Handoff Framework
purpose: K1 codified-knowledge standard defining the platform-level contracts for agent-to-agent handoffs — sync vs async processing, the 9-field handoff manifest schema, the 3-layer confirmation loop, the 5-state disposition state machine, the tier-cascade ordering rule, and the 4-class QA integration taxonomy
type: standard
status: ACTIVE
source: ""
parallel_to: "OPERATIONS.md § Skill Chaining Protocol (C1–C7 + 4-skill allowlist — auto-invocation policy this framework composes with), handoff-coordinator-spec.md (5-phase stage-level orchestration this composes with), stage-io-contracts.md (per-stage-boundary contracts this cites without redefining), ppm-agent SKILL.md § Section 10 (existing 5-field manifest this extends additively to 9 fields), Mode Selection Protocol at OPERATIONS.md (chained=true arg this composes with), gate-criteria-spec.md (gate criteria this cites at L2 confirmation), template-protocol.md + template-taxonomy.md (template lifecycle this cites at disposition state machine T2)"
reversibility: MODERATE / HIGH confidence (framework doc is per-commit `git revert`able; downstream skills do not yet bind against it per PULL-IN model; reversion impact bounded to citation-graph repair)
consumers: "PULL-IN model — adoption is opportunistic per downstream skill revision occasion, not gated. Declared consumers (Dimension 8 blast-radius surface): file-router, ppm-agent, tracker-manager, comms-writer, artifact-generator, delivery-engine, pipeline stage handoff schemas (Stage 7→8 per the per-stage handoff contracts; Stage 5→6 per the planning-to-engineering handoff schema). No consumer updates in this release."
version: ""
---
<!-- reference-durability: allow-link -->

# Agent Handoff Framework

## 1. Purpose + Scope

This framework defines the platform-level **contracts** for agent-to-agent handoffs across the PMO platform: how a skill describes what it is handing off, how the recipient knows the handoff is well-formed, how disposition is tracked through the artifact's lifecycle, how cascades order their tier-2 vs tier-1 writes, and how QA integrates by agent class. It is **K1 codified knowledge** (universal, transferable, enforcement-carrying) per [knowledge-architecture.md §3 Placement Model](../disciplines/knowledge-architecture.md).

The framework **composes with — does not replace** — five pre-existing assets:

| Asset | Authority | Composition |
|---|---|---|
| [`OPERATIONS.md § Skill Chaining Protocol`](../governance/OPERATIONS.md) C1–C7 + 4-skill allowlist | Auto-invocation policy | Framework's 9-field manifest binds against C1 (depth), C2 (breadth), C3 (context), C4 (tier), C5 (governance), C6 (approval-scope), C7 (allowlist) |
| [`handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md) | Stage-level orchestration (5-phase: pre-transition validation / gate evaluation / transition routing / iteration tracking / trend reporting) | Framework's L2 confirmation layer IS the handoff-coordinator's Phase 1 pre-transition validation |
| [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) | Per-stage-boundary artifact contracts | Framework cites the per-boundary contracts as instances of the framework's protocol; no redefinition |
| [`ppm-agent/SKILL.md § Section 10`](../../operations/skills/ppm-agent/SKILL.md) | 5-field handoff manifest (Tag, Context, Source, Scope, Inputs) | Framework's 9-field manifest preserves the 5 fields verbatim + adds 4 new framework fields (source_agent, intent, confirmation_requirement, error_handling) |
| [`OPERATIONS.md § Mode Selection Protocol`](../governance/OPERATIONS.md) — `chained=true` invocation contract | Mode auto-selection for chained skill invocations | Framework's `intent` field composes with the `chained=true` arg to replace target-side mode inference |

**Scope.** Agent-to-agent and skill-to-skill handoff contracts. Stage-to-stage handoffs invoke this framework's protocol via [`stage-io-contracts.md`](../schemas/stage-io-contracts.md). Operator-to-agent inputs use existing prompts and AskUserQuestion surfaces — not this framework's domain.

**Out of scope.** Skill-INTERNAL state. Operator-to-agent prompts. Connector implementations (Teams / Slack / email — none currently exist in the platform). Stage-boundary gate criteria (owned by [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md)). Per-skill output contracts (owned by [`per-skill-output-contracts.md`](../schemas/per-skill-output-contracts.md)).

**Cutover:** Applies to skill outputs and stage handoffs produced by skills/stages entering execution going forward.

## 2. Dimension 1 — Processing Models (Sync vs Async)

**Two-model taxonomy with one boundary criterion.**

| Model | Definition | Boundary criterion | Examples |
|---|---|---|---|
| **Sync (user-present)** | Operator awaits response in real-time within an active session/chat. Output is the unit of value. | An operator awaits this output's **rendering**. | ppm-agent invoked from chat for meeting review; daily-status invoked at standup; file-router triaging a freshly uploaded file in active chat; release-planner Mode A invoked from chat |
| **Async (background)** | No operator-present at invocation; output is a queued artifact awaiting subsequent disposition. | An operator awaits this output's **disposition** (or no operator awaits at all). | folder-watch on `projects/Transcripts/` triggering file-router; registry-declared scheduled cron routines; `loop` skill self-pacing iterations; spawn_task spokes running while operator is in another session; release-executor running Stage 12 chore-PR sequences |

**Boundary test (single discriminator):** *"Does an operator await this output's RENDERING (sync) or its DISPOSITION (async)?"* — RENDERING means the operator is watching the output appear; DISPOSITION means the operator's next interaction is reviewing what landed.

**Composition with the Agent-tool orchestration mechanism.** That mechanism's Agent-tool orchestration is **sync** by construction (the parent session is running the Agent invocation and consumes the spoke's result). The Async model fires for connector-driven entries (folder-watch, scheduled tasks, MCP remote triggers) that the mechanism layer does not govern. The framework does NOT redesign the mechanism's invocation pattern; it categorizes the resulting handoffs.

**Anti-pattern (PROC failure-mode class):** treating an async output (transcript routed via folder-watch) as sync-class (expecting operator-attention-now). Symptom: skills auto-write Document Tier 1 artifacts on async paths, bypassing the approval gate. Mitigation: the disposition state machine (Dimension 5) enforces approval-on-promotion regardless of entry channel.

## 3. Dimension 2 — Agent-to-Agent Handoff Protocol (9-field Manifest)

**Canonical schema.** The manifest extends the existing PPM 5-field manifest (Tag, Context, Source, Scope, Inputs) per [`OPERATIONS.md § Skill Chaining Protocol`](../governance/OPERATIONS.md) with 4 new framework fields. Pre-existing rule-derived fields (`cascade_depth` from C1; `evidence_quality` from CLAUDE.md guardrails) are cited by reference, not redeclared.

```yaml
handoff_manifest:
  # ─── Existing 5 fields (preserved verbatim from PPM Section 10) ───
  tag: "[COMMS] | [DELIVERY] | [ARTIFACT_GAP] | TRACKER_UPDATE | ..."
  context: "human-readable one-liner describing what should happen next"
  source:  "evidence pointer (file path / issue # / transcript section)"
  scope:   "cascade_scope per C6 — declared list of downstream artifacts the
            single user-approval authorizes"
  inputs:  "structured payload data the target needs to act"

  # ─── 4 new framework fields (this framework) ───
  source_agent: "skill-name (originating skill — explicit, replaces implicit
                 inference)"
  intent:       "named mode/operation in the target (replaces target-side
                 mode-inference; composes with Mode Selection Protocol's
                 chained=true arg per OPERATIONS.md § Mode Selection)"
  confirmation_requirement: "none | ack | round-trip"
  error_handling:           "fail-loud | retry | escalate"

  # ─── Pre-existing rule-derived fields (cited by reference, not redeclared) ───
  cascade_depth:    integer  # per C1, max 2
  evidence_quality: "[SOURCE] | [INFERRED] | [ASSUMPTION – CONFIRM] |
                    [CONTEXT] | [RECOMMENDED]"  # per CLAUDE.md guardrails
```

**Composition with C1–C7** ([OPERATIONS.md § Skill Chaining Protocol](../governance/OPERATIONS.md)):

| Rule | Framework binding |
|---|---|
| C1 (depth bound: max 2) | `cascade_depth` is set by invoker; target refuses invocation if `cascade_depth ≥ 2`. Framework does not modify C1. |
| C2 (breadth bound: ≤3 auto-invocations per PPM run) | Invoker-side check; framework cites the existing rule. |
| C3 (context gate) | All 9 manifest fields MUST populate AND `evidence_quality ∈ {[SOURCE], [INFERRED]}` for auto-invocation. `[ASSUMPTION – CONFIRM]` demotes to manual. |
| C4 (tier gate) | `target_agent` × `intent` resolve to a target-skill mode whose output tier MUST be checked against Document Tier 2 (auto-write) vs Document Tier 1 (queued for approval). |
| C5 (governance gate) | Governance-file writes never auto-cascade regardless of manifest contents. |
| C6 (approval scope) | The `scope` field IS `cascade_scope`. Framework formalizes the field name. |
| C7 (allowlist) | `source_agent` × `target_agent` pair MUST appear in the 4-skill allowlist (comms-writer, delivery-engine, tracker-manager, artifact-generator) OR the invocation degrades to informational handoff. |

**Error-handling semantics (3-value enum):**

| Value | Semantics | Use when |
|---|---|---|
| `fail-loud` | Target raises and surfaces error to operator; cascade halts | Default for Document Tier 1 staging; default when target operates on production-impacting state |
| `retry` | Target attempts retry up to a policy-defined cap (Tier 1 self-repair per [autonomous-execution-model.md](../disciplines/autonomous-execution-model.md)) | Transient external dependencies (CLI rate-limits, network blips) |
| `escalate` | Target surfaces to operator with Tier 2/3 routing per [release-process.md § Inter-Stage Feedback Protocol](../../release/governance/release-process.md) | Cross-stage cascades that hit a scope-change or plan-rejection condition |

**Confirmation requirement semantics (3-value enum):**

| Value | Semantics | Connector requirement |
|---|---|---|
| `none` | Fire-and-forget; invoker proceeds without awaiting evidence | No connector |
| `ack` | Target writes ACK (sub-task comment, log line, or write-confirmation per Write-first-speak-second guardrail) — invoker reads ACK before proceeding | File-system + GitHub API (already present); no NEW connector |
| `round-trip` | Target executes + downstream connector returns disposition (e.g., email-sent receipt; Slack message-id; tracker row written + read-back) | NEW connector requirement — see Dimension 3 L3 |

**Cutover:** Applies to skill-to-skill handoffs invoked by skill outputs produced going forward.

## 4. Dimension 3 — Confirmation Loop (3-layer L1/L2/L3)

**The question this dimension answers:** how does the system know an output was acted on (email sent, artifact promoted, tracker updated)?

**Three-layer confirmation model** (composition with existing surfaces):

| Layer | Mechanism | Coverage TODAY | Coverage GAP (future-state) |
|---|---|---|---|
| **L1 — Write-confirmation** | Target skill confirms file write or GitHub state mutation in its response (per CLAUDE.md "Write-first-speak-second" guardrail). Invoker reads the confirmation in the response. | Full coverage. All in-repo writes + `gh` mutations confirm by inspection. | None. |
| **L2 — Stage contract validation** | [`handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md) Phase 1 pre-transition validation matches downstream-stage handoff payload against [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) boundary contract. Missing artifact = HOLD. | Full coverage for inter-stage handoffs. | None at the stage-boundary surface. |
| **L3 — Connector callback** | External-system connector returns a callback or callback-equivalent token (email message-id, Slack ts, Teams reply-link) proving the action landed at the destination system. | **NONE** — no Teams/Slack/email connector currently exists in the platform. | Connector capability — out of scope. Framework establishes the SCHEMA for `confirmation_requirement: round-trip` so future connector implementations have the contract to bind against. |

**Chaining pattern for multi-step cascades (L1 + L2 composition):**

1. Invoker emits manifest with `confirmation_requirement: ack`.
2. Target executes; writes ACK (Layer 1).
3. Invoker reads ACK; updates `cascade_depth` and emits next-stage manifest if applicable.
4. At stage boundary: handoff-coordinator (Layer 2) revalidates contract before forward progression.

**Operator-attested confirmation (L3 stand-in until connectors land).** For Document Tier 1 sends that exit the platform (Teams post, email send, Slack message), the framework documents an OPERATOR-ATTESTED confirmation step — operator returns to the platform and posts an attestation comment ("posted to #channel at <timestamp>"). The attestation IS the disposition transition trigger. This is interim; Layer 3 connector implementations will automate it later.

## 5. Dimension 4 — Disposition Tracking (5-state State Machine)

**Canonical lifecycle.** 5 states with 6 named transitions. State names map to existing operational vocabulary (CLAUDE.md 08-Generated/ staging rule, OPERATIONS.md cascade post-approval semantics).

**States:**

| # | State | Definition | Storage location |
|---|---|---|---|
| 1 | `staged` | Generated; landed at staging location; awaiting promotion decision | Document Tier 1: `projects/[Project]/08-Generated/<file>`; Document Tier 2: written directly (state skipped) |
| 2 | `promoted` | Moved to canonical authoritative filepath (or written-in-place for Document Tier 2) | Target folder per Document Tier; CLAUDE.md File Management Protocol |
| 3 | `confirmed-sent` | Downstream connector returned success OR operator-attested send | External system + operator attestation comment |
| 4 | `stale` | 10-business-day timer expired without promotion (per CLAUDE.md 08-Generated/ auto-archive rule) | Same staging location; flagged |
| 5 | `archived` | Auto-cleanup completed; artifact moved to Archive/ or git-deleted | `projects/Archive/` or removed |

**Transitions:**

| # | From → To | Trigger | Authority |
|---|---|---|---|
| T1 | (none) → `staged` | Target skill generates artifact | Skill-internal |
| T2 | `staged` → `promoted` | Document Tier 1: operator approval; Document Tier 2: auto-write success | Operator (Tier 1) / Skill (Tier 2) |
| T3 | `promoted` → `confirmed-sent` | Connector callback (L3) OR operator-attested send (interim) | Connector / Operator |
| T4 | `staged` → `stale` | 10-business-day timer expires | Automated cleanup |
| T5 | `stale` → `archived` | Auto-archive (per CLAUDE.md 08-Generated/ rule) | Automated cleanup |
| T6 | `promoted` → `archived` | Manual operator decision (rare) | Operator |

**Composition with Document Tier classification** (CLAUDE.md File Management Protocol):

- **Document Tier 1** (stakeholder-facing — RAID Log, Project Plan, governance docs): MUST pass through `staged` state before T2 to `promoted`. Approval gate at T2.
- **Document Tier 2** (operational trackers — Daily Status Log, Communications Tracker): SKIP `staged`; transition directly to `promoted`. No approval gate; write-confirmation per Write-first-speak-second guardrail is the disposition record.
- **Document Tier 3** (Transcripts/Emails — auto-routed): SKIP `staged`; transition directly to `promoted` at canonical filepath (per CLAUDE.md Auto-Write Folders rule).

**State storage convention.** Disposition state lives implicitly in the artifact's location (08-Generated/ = `staged`; canonical path = `promoted`; Archive/ = `archived`) PLUS one optional `_disposition.md` companion file written alongside the artifact when round-trip confirmation is required (records the operator attestation OR connector callback evidence). The state machine does NOT require a new central state-store; transitions are observable from filesystem and GitHub state.

**Cutover:** Applies to artifact dispositions produced going forward.

## 6. Dimension 5 — Tiered Cascading (Trackers First, then Artifacts)

**Canonical ordering.** Within a single cascade triggered by a Document Tier 1 approval, the cascade fires Document Tier 2 tracker updates BEFORE Document Tier 1 artifact staging.

**Rationale.** Trackers are operational memory the next step depends on (e.g., comms-writer drafting an external send needs the artifact-generator's staged copy registered in the communications-tracker BEFORE drafting). Reverse ordering (artifacts first) creates references to artifacts whose tracker rows do not yet exist.

**Composition with existing rules:**

- Rules C1–C7 at [`OPERATIONS.md § Skill Chaining Protocol`](../governance/OPERATIONS.md) are NORMATIVE; this dimension does NOT modify them.
- The cascade allowlist (PPM `[COMMS]` → comms-writer; PPM `[DELIVERY]` → delivery-engine; `TRACKER_UPDATE` → tracker-manager; PPM `[ARTIFACT_GAP]` → artifact-generator) is NORMATIVE per C7; framework does NOT modify it.
- CLAUDE.md "Cascade approval" universal preference cross-references OPERATIONS.md C1–C7 + 4-skill allowlist; framework does NOT modify the universal preference text.

**What the framework adds:** the **ordering rule** ("trackers first, then artifacts") + the **disposition-state binding** (Document Tier 2 cascade writes drive `staged → promoted` direct transition; Document Tier 1 cascade entries drive `T1 → staged` only and queue for approval).

**Cutover:** Applies to cascades fired by skill outputs produced going forward.

## 7. Dimension 6 — QA Integration (4-class Agent Taxonomy)

**Canonical taxonomy.** 4 agent classes with per-class default QA policy. Aligns with pmo-qa-auditor's existing invocation surface.

| Agent class | Examples | Default QA policy | Invocation timing |
|---|---|---|---|
| **Decision-class** | ppm-agent, principal-engineer (future), release-planner | INLINE per output; [decision-discipline.md](../disciplines/decision-discipline.md) framework (M1/M2/M3) governs | Per-decision-briefing; mandatory |
| **Review-class** | build-reviewer, pmo-qa-auditor | INLINE by definition (the skill IS the review) | Self-invoking |
| **Tracker-update** | tracker-manager, delivery-engine (Mode B/C) | BACKGROUND SAMPLING at release-close (Stage 13) | Cadence-based |
| **Comms drafts** | comms-writer | INLINE if Document Tier 1; BACKGROUND SAMPLING if Document Tier 2 draft | Per-output / cadence |

**Cross-cutting cadence.** pmo-qa-auditor runs at every release-close (Stage 13) regardless of agent class — this is already operational per existing protocols and is NOT modified by this framework.

**Inline vs background vs cadence-based discriminators:**

- **Inline:** runs on the output before the output reaches its target audience; blocks output emission until pass.
- **Background sampling:** runs on a random sample (or all, depending on volume) of outputs after emission; findings route as Tier 1 [ADJUST] for next-release remediation.
- **Cadence-based:** runs at fixed pipeline gates (release-close); applies the existing release-close QA discipline (per [`.claude/rules/release-process.md` Stage 13](../../release/governance/release-process.md)).

**Default-policy override.** Any agent may override the default via the `qa_policy` frontmatter field on its SKILL.md (added by consumer skills in their own future Stage 5 specs).

**Cutover:** Applies to QA invocations on skill outputs produced going forward.

## 8. Dimension 7 — Template / Schema Standardization (Cross-reference, do not duplicate)

**Canonical posture.** The framework names the existing canonical sources for handoff-adjacent contract categories and cites them. It does NOT redefine schemas owned by other docs. This matches the duplicate-source-discipline principle ([`duplicate-source-discipline.md`](duplicate-source-discipline.md)) — register or remove, never restate.

| Category | Canonical source | Framework role |
|---|---|---|
| Handoff manifest schema | THIS framework (Dimension 2) | Owner |
| Gate criteria | [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) | Consumer — framework's confirmation-loop L2 cites gate criteria validation |
| Artifact templates | [`template-protocol.md`](template-protocol.md) + [`template-taxonomy.md`](template-taxonomy.md) | Consumer — framework's disposition state machine cites template lifecycle (DRAFT → REVIEWED → APPROVED → DEPRECATED → ARCHIVED) at the Document Tier 1 promotion gate |
| Stage 7/8 Handoff Payload | [`stage-07-dev-testing.md § DT↔QA Handoff Protocol`](../../release/references/pipeline/stage-07-dev-testing.md) | Consumer — Stage 7→8 handoff IS an instance of the framework's agent-to-agent handoff protocol; framework cites the per-stage schema |
| Per-skill output contracts | [`per-skill-output-contracts.md`](../schemas/per-skill-output-contracts.md) | Consumer — per-skill output contract is the per-target-skill specialization of the handoff manifest's `payload` field |
| Stage-boundary I/O contracts | [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) | Consumer — stage-boundary handoff IS an instance of the framework's protocol; framework cites the boundary contract format |

**Anti-duplication discipline.** The framework MUST NOT redefine the gate-criteria spec, template-protocol, or stage-io-contracts schemas. It points at them.

## 9. Dimension 8 — Blast-Radius Surface (PULL-IN Model)

**Canonical posture.6 downstream skill consumers + 1 stage-handoff surface**. NO downstream skill updates in this release. Consumers adopt the framework in their own future Stage 5 specs.

| # | Consumer | Current state | Adoption pattern | Future-release adoption owner |
|---|---|---|---|---|
| 1 | file-router | Auto-routes Transcripts / Emails / 08-Generated; lacks framework citation | Adopt async processing model + disposition state machine | Future Stage 5 spec for file-router enhancements |
| 2 | ppm-agent | Implements 5-field handoff manifest at Section 10 | Extend to 9-field framework manifest | Future ppm-agent revision |
| 3 | tracker-manager | On cascade allowlist (C7); auto-write Document Tier 2 | Cite framework's tier-cascade ordering rule; cite Dimension 6 background-sampling QA default | Future tracker-manager revision |
| 4 | comms-writer | On cascade allowlist (C7); produces Document Tier 1 drafts | Cite framework's disposition state machine + L3 connector requirement (until connectors land) | Future comms-writer revision |
| 5 | artifact-generator | On cascade allowlist (C7); stages to 08-Generated/ | Cite framework's `staged → promoted` transition + 10-bday auto-archive | Future artifact-generator revision |
| 6 | delivery-engine | On cascade allowlist (C7); writes Document Tier 2 trackers | Cite framework's tier-cascade ordering rule | Future delivery-engine revision |
| 7 | Pipeline stage handoff schemas (Stage 7→8; Stage 5→6) | Per-boundary contracts in [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) | Cross-reference framework's protocol as the parent contract pattern | Future stage-io-contracts revision (incremental) |

**PULL-IN justification.** This milestone bundle is at the upper end of the A4 5–8 issue capacity heuristic (7 issues, 1×L + 6×M); adding 6+ downstream skill modifications would push the milestone well past 1.5× capacity and violate Stage 4's "no scope expansion mid-release" discipline. Downstream skills adopt the framework when their own bundle reaches their respective milestones — this is governed by their own Stage 5 specs.

**Cross-release sequence check.** NO downstream skill milestone is currently bundled with a "framework adoption" dependency. Adoption is opportunistic per skill-revision occasion, not gated.

## 10. Dimension 9 — Coordination with the Agent-Tool Mechanism Layer

**Coordination citation only — no co-modification.**

The mechanism layer (sibling Stage 5 sub-task) ships the Agent-tool orchestration mechanism (replaces per-spoke `spawn_task` chip clicks with in-session `Agent` tool invocations from the hub). The Agent Handoff Framework defines the CONTRACT layer over that mechanism.

**Composition surface:**

| The mechanism layer ships | This framework defines |
|---|---|
| `Agent` tool invocation pattern with `subagent_type` + `prompt` + `model` parameters (latter per the mechanism layer) | `source_agent`, `target_agent`, `payload` fields of the handoff manifest that the Agent invocation embeds |
| Click-free in-session orchestration | Sync processing model (Dimension 1) — confirms Agent-tool invocations are sync-class by construction |
| Main-thread approval surface per the mechanism's narrowing | Confirmation loop L1 (write-confirmation) for the queued-resumption case |

**Citation pattern.** The framework cites [`hub-spoke-bridge.md § Spoke Launch Mechanisms`](../../release/references/how-to/hub-spoke-bridge.md) (once the mechanism layer lands) for the Agent-tool invocation mechanism; the framework does NOT redesign that invocation pattern.

**Sequencing constraint.** Per Stage 4 plan §Recommendations bullet 5: this framework lands FIRST per implementation sequence #1 (substrate first) on the release branch — the mechanism layer's Engineering work can cite the landed framework when authoring the hub-spoke-bridge sections.

## 11. Dimension 10 — D-2 Placement Justification

**Decision.** NEW file at `core/standards/agent-handoff-framework.md` (this file).

**Cross-reference to R1 Evidence-Grounding artifact.** Full rationale is documented in the framework's Stage 5 spec (closing comment, § "Evidence-Grounding (per R1) — Canonicalization 1: Framework doc location"). Summary:

| Question | Answer |
|---|---|
| Is the content K1 codified knowledge? | YES — universal across PMO-platform deployments per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) §3 Q1 classifier |
| Is the content enforcement-carrying? | YES — manifest schema + state machine + ordering rule are normative ("MUST use these fields", "MUST transition through these states") |
| Does `standards/` house enforcement-carrying specs? | YES — canonical-skill-structure, evidence-grounding-standard, version-field-semantics, decision-outcome-tracking, doc-link-maintenance-protocol, partial-deployment-recovery, etc. |
| Why not section-in-existing-file? | Three section-placement alternatives explicitly rejected: `hub-spoke-bridge.md` (would violate single-responsibility — this release already adds 4 new sections); `decision-discipline.md` (wrong scope — decision-rendering vs orchestration); `OPERATIONS.md § Skill Chaining Protocol` (inverts the citation graph — policy embeds spec). |

**Operational consequence.** CLAUDE.md § Universal Preferences "Cascade approval" bullet and OPERATIONS.md § Skill Chaining Protocol both cross-reference this file as the implementation spec their policy rules bind against. The citation graph closure matches existing precedent (cf. how `hub-spoke-bridge.md` Operating Principle cross-references `decision-discipline.md`).

## 12. Cross-References

**Composes with (this framework's load-bearing parents):**

- [`OPERATIONS.md § Skill Chaining Protocol`](../governance/OPERATIONS.md) — rules C1–C7 + 4-skill allowlist; the auto-invocation policy this framework's manifest binds against.
- [`handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md) — 5-phase stage-level orchestration; the L2 confirmation layer this framework cites.
- [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) — per-boundary contracts; the cite-only schema source for stage-boundary handoffs.
- [`ppm-agent SKILL.md § Section 10`](../../operations/skills/ppm-agent/SKILL.md) — existing 5-field manifest the 9-field schema preserves verbatim.
- [`OPERATIONS.md § Mode Selection Protocol`](../governance/OPERATIONS.md) — `chained=true` invocation contract this framework's `intent` field composes with.
- [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) — gate criteria the L2 confirmation cites.
- [`template-protocol.md`](template-protocol.md) + [`template-taxonomy.md`](template-taxonomy.md) — template lifecycle the disposition state machine cites at T2.

**Cited from (downstream consumers — PULL-IN model, no consumer updates):**

- CLAUDE.md § Universal Preferences (Cascade approval bullet) — thin cross-reference.
- OPERATIONS.md § Skill Chaining Protocol (intro paragraph) — thin cross-reference.
- file-router, ppm-agent, tracker-manager, comms-writer, artifact-generator, delivery-engine (consumer SKILL.md files) — future revisions adopt per their own Stage 5 specs.
- Stage 7→8 Handoff Payload schema per [`stage-07-dev-testing.md`](../../release/references/pipeline/stage-07-dev-testing.md) — pre-existing instance of the framework's protocol.

**Supporting standards:**

- [`evidence-grounding-standard.md`](evidence-grounding-standard.md) — R1 artifact discipline; this framework's D-2 placement is grounded per the Stage 5 R1 artifact.
- [`decision-discipline.md`](../disciplines/decision-discipline.md) — Mechanism 1 (Localization Check) consulted for D-2 placement decision.
- [`canonical-skill-structure.md`](canonical-skill-structure.md) — file-placement convention `standards/` vs `explanation/`.
- [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1 classification (Q1 universality test).
- [`duplicate-source-discipline.md`](duplicate-source-discipline.md) — register-or-remove rule applied to Dimension 7.
- [`autonomous-execution-model.md`](../disciplines/autonomous-execution-model.md) — Tier 1 self-repair semantics cited at error_handling `retry`.

## 13. Version History

| Version | Date | Change | Reference |
|---|---|---|---|
|  | 2026-05-24 | Initial authoring | Stage 5 + Stage 6 sub-tasks |
