# OPERATIONS.md – Program-Level Context for Project Management

**Effective:** 2026-03-18
**Scope:** All PMO project management work across the workspace
**Owner:** [COMPANY_X] PMO / [OPERATOR_NAME]
**Status:** Production (v3)

---

## Purpose

This file defines behavioral rules, skill protocols, cross-project rules, and operational workflows for all PMO project management work. It is the operational backbone of the workspace and supersedes generic PM practices.

**Read order:** Start at "Skills Section" if new to PMO work. Start at "Operational Artifacts" if processing a project.

---

## Skills Section

The PMO skill suite consists of 16 production skills. Each skill has a defined scope boundary and cannot cross into other skills' lanes.

### Production Skills (16)

| Skill | Role | Trigger Tag | Scope Boundary |
|-------|------|------------|----------------|
| **PPM Agent** (Skill Tier 1) | Strategic Brain / Entry Point | — (entry point) | Triages all artifacts. Routes specialist work via tags. Does NOT perform technical analysis, change management, or comms drafting. Owns strategic routing, DECISION escalations, [RISK] intake. |
| **Delivery Engine** (Skill Tier 1) | Operational Backbone | `[DELIVERY]` | Backlog health, sprint planning, DoR/DoD gates, velocity tracking, RAID updates for delivery blockers. Does NOT generate comms or review FDD content. Owns carry-forward ticker. |
| **Comms Writer** (Skill Tier 1) | Communications Voice | `[COMMS]` | Audience-calibrated communications: exec summaries, stakeholder digests, status language, meeting recaps. Does NOT perform CM analysis, risk assessment, or technical review. Owns MSG-## lifecycle. |
| **Change Management** (Skill Tier 2) | People-Side of Deploy | `[CHANGE]` | Impact assessment, training plans, hypercare metrics, readiness checklists, adoption tracking. Does NOT draft status comms or review technical designs. Owns CM-specific RAID entries. |
| **Technical Analyst** (Skill Tier 2) | Engineering Judgment | `[TECHNICAL]` | FDD review, integration risk, architecture assessment, dependency identification, feasibility feedback. Does NOT write requirements or draft comms. Owns TA-specific RAID entries. |
| **Process Designer** (Skill Tier 2) | Requirements Rigor | `[PROCESS]` | REQ-### definitions, traceability matrix, gap analysis, compliance mapping, process flows. Does NOT review FDD technical content or draft comms. Owns PD-specific RAID entries. |
| **Daily Status** (Skill Tier 1) | Daily Heartbeat | — (direct invoke) | Generates AM/PM status updates from carry-forward trackers and recent transcripts. Produces Teams-ready updates using Daily Status Update Framework. Does NOT process transcripts or update trackers. |
| **Weekly Status Roll-Up** (Skill Tier 1) | Weekly Synthesis | — (direct invoke) | Generates cross-project weekly summaries for leadership. Writes back health indicators to PORTFOLIO.md. Does NOT perform daily processing or specialist analysis. |
| **QA Auditor** (Meta) | Quality Gate | — (direct invoke) | Reviews skill output against principal standard: evidence sourcing, decision rigor, tracker consistency, guardrail compliance. Does NOT produce project artifacts. |
| **Skill Editor** (Meta) | Suite Maintenance | — (direct invoke) | Edit, audit, regression-test skills. Maintains skill definitions and cross-skill protocols. Does NOT process project artifacts. |
| **Project Initiator** (Automation) | Project Lifecycle | — (direct invoke) | Scaffolds new projects from template. Closes completed projects. Updates PORTFOLIO.md. Does NOT process project artifacts. |
| **File Router** (Automation) | File Classification | — (on file intake) | Classifies and routes files to correct project folder. Does NOT process file content. |
| **Tracker Manager** (Automation) | Update Engine | — (on Document Tier 2 approval) | Generic update engine for operational artifacts in 04-PMO-Operations/. Validates against schemas. Does NOT generate new artifacts. |
| **Artifact Generator** (Automation) | Production Engine | — (on demand or gap detection) | Produces/stages missing artifacts in 08-Generated/. Does NOT promote files to target folders or update trackers. |
| **Release Planner** (Automation) | Release Planning Engine | — (direct invoke) | Analyzes IMP backlog, maps dependencies, suggests release bundles, generates release plan files, produces dry-run diffs. Read-only — never modifies governance files. Handles RELEASE_PROTOCOL.md Steps 1-5. |
| **Release Executor** (Automation) | Release Execution Engine | — (direct invoke) | Executes approved release plans: snapshots, file changes, IMP closure, RELEASE_LOG updates, post-release verification, rollback. Requires approved plan with Dry-Run Record. Handles RELEASE_PROTOCOL.md Steps 6-9. |

---

## KM Governance Ownership

KM corpus governance — ownership / approval / retirement / meta-governance for K1 codified-knowledge artifacts — is delegated to [`core/standards/km-governance-framework.md`](../core/standards/km-governance-framework.md). The framework codifies the 4-value owner-class enum (`operator-class` / `role-class` / `artifact-class` / `future-collective-class`), the 2-tier storage model (framework-catalog `owner` column authoritative + frontmatter `owner:` cache for K1 reference docs), the approval protocol composing with [`corpus-curation.md`](../core/disciplines/corpus-curation.md) ET1–ET5, and the 4-source retirement protocol composing with [`practice-efficacy-framework.md`](../core/standards/practice-efficacy-framework.md) (efficacy) + [`corpus-curation.md`](../core/disciplines/corpus-curation.md) (curation) + [`km-protocols.md`](../core/disciplines/km-protocols.md) (staleness) + reserved slot for contraindication-prevalence.

The authoritative ownership registry of record is [`framework-catalog.md`](../core/specs/framework-catalog.md) `owner` column (col 11 of 11-col schema) per `km-governance-framework.md` §2.4 Tier 1. Frontmatter `owner:` field on K1 reference docs is the Tier 2 cache; conflict resolution rule: registry wins. Cadence + amendment protocol + Tier 2 [SCOPE CHANGE] escalation are defined in `km-governance-framework.md` §5 (Meta-Governance) and apply reflexively to the framework itself per §5.5 cutover discipline.

---

## Follow-Up Tag Routing

After PPM Agent triage, specialist work is routed via tags. Each tag maps to a target skill and defines which skills may emit it.

| Tag | Target Skill | Emitting Skills | Constraint |
|-----|-------------|-----------------|-----------|
| `[DELIVERY]` | Delivery Engine | PPM, TA | Backlog/sprint work |
| `[COMMS]` | Comms Writer | PPM, DE, CM, PD | Communications/messaging |
| `[DECISION]` | PPM Agent (self) | PPM only | Escalates to strategic review |
| `[RISK]` | PPM Agent (self) | PPM, CM | Escalates to risk intake |
| `[TECHNICAL]` | Technical Analyst | PPM | Design/integration review |
| `[PROCESS]` | Process Designer | PPM | Requirements/traceability review |
| `[CHANGE]` | Change Management | PPM, DE, TA | Readiness/adoption work |

**Routing Constraint:** Max-depth-2 tree from PPM. No skill may tag another skill's work for re-routing (breaks transparency).

---

## Cross-Skill Protocols

### Evidence Quality Labeling

All output must label the source and confidence of evidence. Use this vocabulary consistently across all skills:

| Label | Meaning | Requirement |
|-------|---------|------------|
| `[SOURCE]` | Directly stated in artifact | Cite location: timestamp, Jira field, doc section, person name |
| `[INFERRED]` | Reasonable conclusion from multiple points | Include 2–3 sentence reasoning chain |
| `[ASSUMPTION – CONFIRM]` | Not in any source; proposed answer | Include proposed answer AND basis (e.g., "Assumed Tuesday Feb 18, typical sprint velocity suggests...") |
| `[CONTEXT]` | From project memory | Label which PROJECT.md field (e.g., `[CONTEXT: phase]`) |
| `[RECOMMENDED]` | Agent-recommended date/action | Distinguish clearly from stakeholder-committed dates |

Example usage:
```
Blocker: Late FDD approval [SOURCE: Daily Connect Feb 18, 14:35, Alex stated "We're 2 days behind FDD sign-off"]
Target date impact: Moves go-live 1 week [INFERRED: FDD late + 3-day review cycle + 4-day buffer = 10 days slip]
Mitigation: Parallel testing [ASSUMPTION – CONFIRM: Assumes parallel testing adds 30% capacity without rework]
```

### Skill Chaining Protocol

This protocol governs auto-invocation policy. The framework spec consumers bind against is at [`agent-handoff-framework.md`](../core/standards/agent-handoff-framework.md).

Governs auto-invocation from one skill to another (skill chaining) and post-approval cascade (a single user approval authorizing downstream dependent updates). Operationalizes the existing max-depth-2 architectural constraint codified in **XC-05** (`core/standards/regression-checks.md`) and the routing tree in `pmo-platform/reference/knowledge-base/dependency-graph.md` for the specific case of auto-invocation and cascading writes. This subsection does not modify XC-05 or dependency-graph.md — it cites them as the architectural source of the depth bound and extends their scope to programmatic invocation.

**Platform capability.** The Cowork `Skill` tool permits programmatic invocation from within one skill's execution. Rules C1–C7 constrain when that capability fires automatically; outside these rules, the capability is still present but invocation remains manual (informational handoff tags for the operator).

| Rule | Name | Specification |
|---|---|---|
| **C1** | **Depth bound** | Max 2 skill invocations per PPM trigger (PPM → Specialist → optional 1-hop terminal). Mirrors XC-05. Enforcement is programmatic: the Skill-tool invocation records `cascade_depth: N`; the target skill refuses invocation if N≥2 and emits an informational handoff instead. |
| **C2** | **Breadth bound** | A single PPM response may auto-invoke ≤3 downstream skills per run. When more than 3 tags qualify, auto-invoke the top 3 by urgency (URGENT > APPROACHING > ADVISORY, tiebreak on earliest deadline); surface remaining tags with explicit note "Auto-invocation skipped: breadth-bound exceeded." |
| **C3** | **Context gate** | Auto-invoke requires ALL five handoff fields populated (Tag, Context, Source, Scope, Inputs) AND `evidence_quality` ∈ {`[SOURCE]`, `[INFERRED]`}. An `[ASSUMPTION – CONFIRM]` on any field demotes the action to manual — prevents amplifying uncertainty downstream. |
| **C4** | **Tier gate** | Only Document Tier 2 (operational tracker) writes auto-execute. Document Tier 1 (stakeholder-facing) writes always require explicit user approval, regardless of how the action was triggered. The downstream skill produces a draft; the user approves; then the write happens. |
| **C5** | **Governance gate** | Governance-file updates (CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, PROJECT.md, any file in `core/`/`operations/`/`release/`) never auto-cascade. Always require GitHub Issue + release plan per [`.claude/rules/governance-files.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/governance-files.md). |
| **C6** | **Approval scope** | A Document Tier 1 user approval authorizes cascade only within the artifact's declared `cascade_scope` (field in Handoff Manifest — see `operations/skills/ppm-agent/SKILL.md` Section 10). Cascade does not escalate outside the named scope without a new approval. |
| **C7** | **Allowlist** | Auto-cascade is permitted only for these source→target pairs: PPM `[COMMS]` + complete context → comms-writer (Document Tier 2 draft); PPM `[DELIVERY]` + complete context → delivery-engine (Document Tier 2 tracker); PPM `TRACKER_UPDATE` block → tracker-manager (Document Tier 2 tracker); PPM `[ARTIFACT_GAP]` + complete context → artifact-generator (08-Generated/ staging only). Adding a new allowlist pair requires a GitHub issue + Release. |

**Post-approval cascade semantics (C6 elaborated).**
- User approves Document Tier 1 artifact X declaring `cascade_scope: [tracker-A, tracker-B, comms-draft-C]`.
- Platform auto-writes to tracker-A and tracker-B (Document Tier 2; C4 satisfied).
- Platform stages comms-draft-C in 08-Generated/ (Document Tier 1 — not auto-written to the stakeholder-facing location; presented for a second explicit approval).
- Each auto-write confirms in the response ("Wrote tracker-A row 47"), per the Write-first-speak-second guardrail.
- Cascade terminates at the allowlist boundary: if a tracker-A update would normally trigger a downstream skill, that secondary invocation is suppressed under the same user approval — a new trigger is required.

**Termination conditions.** Auto-cascade stops when ANY of the following fire:

1. Depth = 2 reached (C1)
2. Breadth = 3 exceeded (C2)
3. Tag lacks complete context (C3)
4. Document Tier 1 write required (C4)
5. Governance file required (C5)
6. Action outside approved `cascade_scope` (C6)
7. Target not on allowlist (C7)

Terminating the cascade is always safe — the pending work falls back to a manual handoff tag, not a silent drop. The downstream action remains visible to the operator for manual invocation.

**4-skill cascade allowlist (per C7).** The four auto-cascade target skills are: **comms-writer**, **delivery-engine**, **tracker-manager**, **artifact-generator**. Each target carries a "Chained Invocation Contract" section in its SKILL.md documenting upstream invokers, chained-context pre-fill from the Handoff Manifest, and `chained=true` argument semantics. All other skills remain manual-invocation and do not participate in auto-cascade. Adding a new target requires a GitHub issue + release.

**Relationship to the Handoff Manifest.** The Handoff Manifest schema (`operations/skills/ppm-agent/SKILL.md` Section 10) carries the cascade metadata fields (`target_skill`, `cascade_scope`, `auto_invoke`, `chain_skip_askuserquestion`, `evidence_quality`, `dependencies`, `deadline`). Rules C1–C7 consume those fields to compute whether auto-invocation fires. The Manifest defines the contract; this protocol defines the enforcement.

**Alternative design (not active).** If Cowork could not chain skills programmatically, the fallback would be AD-1 "tag bundle": PPM emits a copy/paste block listing all qualifying tags; the user clicks once to expand into parallel invocations. AD-1 preserves the breadth/depth bounds but loses the push-to-resolve latency benefit. Documented here for portability to environments without Skill-tool chaining; not active in the current platform.

### Mode Selection Protocol

Governs how multi-mode skills select which mode to run on a given invocation. Parallel to the Skill Chaining Protocol above — chaining defines when auto-invocation fires; mode selection defines how the receiving skill decides what to do. Operationalized via a three-step pattern (chain-skip → trigger-heuristic-or-AskUserQuestion → execute) placed as the first operational subsection (`## Mode Selection`) in every multi-mode SKILL.md. Structural placement IS the forcing function: a reader encounters mode-selection instruction before any mode-specific content, so mode selection cannot be bypassed without skipping half the file.

**Three-tier classification.** Every skill in the PMO Agent Suite falls into exactly one tier:

| Tier | Behavior on direct invocation | Skills |
|---|---|---|
| **Always-ask** | AskUserQuestion fires every time; no trigger-match heuristic. Reserved for skills with destructive asymmetry or production-critical inverse operations. | project-initiator, release-planner, release-executor (3) |
| **Ask-when-ambiguous** | Trigger-match heuristic auto-routes when the request clearly matches one mode; AskUserQuestion fires only as a fallback when the request is ambiguous across modes. | delivery-engine, change-management, pmo-process-designer, pmo-qa-auditor, pmo-skill-editor, pmo-technical-analyst, comms-writer, eval-writer (8) |
| **Never-ask** | Single-mode skill, or mode auto-detects reliably from input artifacts / trigger phrasing. No `## Mode Selection` section. | artifact-generator, build-reviewer, daily-status, file-router, implementation-planner, ppm-agent, prompt-builder, skill-creator, tracker-manager, weekly-status-rollup (10) |

**Total:** 3 always-ask + 8 ask-when-ambiguous + 10 never-ask = 21 skills.

**Classification rule.** Always-ask when (a) modes have destructive or production-critical asymmetry, OR (b) modes produce substantially different outputs that cannot be recovered from wrong-mode execution. Ask-when-ambiguous when ≥2 named modes exist AND trigger phrases can plausibly match more than one mode. Never-ask when the skill has a single mode, OR mode auto-detects reliably from input artifacts / trigger phrasing. Tier reclassification requires a GitHub Issue and Release per the No-Ungoverned-Changes guardrail.

**Three-step pattern (applied in every `## Mode Selection` section of multi-mode SKILL.md).**

1. **Step 1 — Chain-skip check.** Detect `chained=true` token in the Skill-tool `args` string (see Skill Chaining Protocol above for arg semantics). When present, read the `mode=<value>` token from the same string (pre-filled from the Handoff Manifest action entry per `operations/skills/ppm-agent/SKILL.md` Section 10) and skip AUQ entirely.
2. **Step 2 — Tier-conditional default.** Always-ask tier invokes AUQ unconditionally; ask-when-ambiguous tier applies a per-skill trigger-match heuristic first and invokes AUQ only on ambiguous or no-match; never-ask tier has no Step 2 (no `## Mode Selection` section at all).
3. **Step 3 — Execute.** Once the mode is resolved (via Step 1, heuristic, or AUQ), proceed to the corresponding mode section in the skill body.

**Chain-skip live / dormant state.** The chain-skip mechanism is uniformly present across all 11 multi-mode SKILL.md files for maintenance consistency and forward-compat. Operationally, chain-skip fires only for the multi-mode cascade-allowlist skills — currently **comms-writer** and **delivery-engine** (2 live). The other 9 multi-mode skills carry the chain-skip Step 1 as a **dormant forward-compat branch** — it is present but does not fire under the cascade allowlist (comms-writer, delivery-engine, tracker-manager, artifact-generator per rule C7). Tracker-manager and artifact-generator are on the cascade allowlist but are never-ask tier — no AUQ exists to skip, so their Chained Invocation Contract sections cover the chained-context read directly without a Mode Selection block. Adding a multi-mode skill to the cascade allowlist (requires a GitHub Issue and Release per rule C7) converts its dormant branch to live without further code changes.

**Relationship to Skill Chaining Protocol.** Skill Chaining Protocol (above) owns the arg-name `chained=true` contract, the Handoff Manifest schema, and rules C1–C7 governing when auto-invocation fires. Mode Selection Protocol (this subsection) owns the receiving-skill behavior: how a skill detects the chain-skip signal, how it resolves its mode when chained, and how it falls back when not chained. Cross-reference boundary: the manifest field `chain_skip_askuserquestion: true` (owned by the ppm-agent manifest schema) is the signal; the arg token `chained=true` (owned by the receiving-skill Mode Selection) is the operational detection mechanism. Both sides converge on the same semantic contract.

**Backward compatibility.** Manual invocations (direct user → skill, no `chained=true` in args) preserve the prior flow for all skills — always-ask tier continues to invoke AUQ, ambiguous-tier applies trigger-heuristic, never-ask tier is unchanged. Only the 11 multi-mode skills gained new `## Mode Selection` sections; the 11 never-ask skills are untouched.

**Enforcement.** Structural placement (Mode Selection as first operational subsection of SKILL.md body) is the load-bearing enforcement mechanism for always-ask tier — agents reading SKILL.md encounter the AUQ instruction before any mode-specific content. Guardrails text in individual skill bodies serves as a secondary reminder. A post-hoc pmo-qa-auditor gate check (Layer 3 in the layered forcing-function pattern) is deferred; activate via a new GitHub Issue if drift is observed across the 3 always-ask skills.

**Skill ↔ pipeline alignment (upstream design contract).** The three tiers above govern *when a skill asks for its mode*; the upstream question — *is mode-resolution a human decision or a state-read, and how does a skill's gate/checklist vocabulary stay aligned to the canonical pipeline gate IDs* — is governed by the [skill-pipeline-alignment standard](../core/standards/skill-pipeline-alignment.md). Its decision-test DT-1 (ask-for-mode vs read-pipeline-state) composes with this tier classification and feeds the tier choice; DT-2 (parallel-vocabulary-leak vs gate IDs) and DT-3 (shared-stage-work extraction) operationalize [ADR-019](../core/ADRs/ADR-019-specialists-compose-not-absorb.md) at the skill↔pipeline seam. Consult it when authoring or reviewing a multi-mode SKILL.md.

### Output Priority

1. **Analysis and judgment** → Synthesized findings, recommendations, evidence chains
2. **File output** → Tracker updates, register entries, artifact modifications
3. **Copy/paste block** → Only when explicitly requested by user

Do NOT flood response with transcribed data. Synthesize. Show work.

### SPM Bridge (Conditional)

Activates **only** when `PROJECT.md` has `spm_comanaged: true`. Produces dual framing:
- **Agile track:** Sprint-level progress, velocity, backlog health
- **Waterfall track:** Milestone gates, phase approval, stage gates

Both tracks must resolve to single decision/action. Use "Both tracks converge on..." language.

### Guardrails (Hard Rejections)

Same as CLAUDE.md, plus PMO-specific:

- **No status theater:** Don't say "on track" without evidence. Say "3 blockers, 2 in progress mitigation."
- **No invention:** Never fabricate sprint metrics, dates, or names.
- **No task dumping:** Don't end with "Next steps: [list of open questions]." Close what you can.
- **No template language:** Don't copy standard PM phrases. Write specific to context.
- **No question flooding:** Max 5 clarifying questions per invocation.
- **No passive risk voice:** Say "Owner (Alex) is blocked by FDD approval" not "FDD approval is pending."
- **No unmarked dates:** Validate day-of-week on all dates. Label recommended vs. committed dates.
- **Vendor label consistency:** Use consistent naming for tools (Jira, not "the ticket system"; Confluence, not "wiki").
- **Day-of-week validation:** Always validate: "March 18 (Tuesday)" not "March 18."
- **No generalized dates:** All project dates in communications and status outputs must be specific and verified. Never substitute a vague range ("week of April 6") for a specific date ("April 2, Thursday"). When sources conflict, surface the conflict — don't paper over it with generalization.
- **Write-first-speak-second:** All file changes follow: plan → user approves → write → confirm. Never report "tracker updated" or "file written" until the write has succeeded. If a write fails, report the failure. No file is modified without prior user approval; no completion is reported without prior file modification. Write sequences follow the Document Tier defined in CLAUDE.md File Management Protocol. Operational trackers (Document Tier 2) are auto-written after processing — do not wait for explicit write instructions. Stakeholder-facing documents (Document Tier 1) require user approval before writing.
- **Project-scoped output:** All generated artifacts must route to the active project's 01-08 folder structure or its 08-Generated/ staging area. Active project = the project whose PROJECT.md is loaded. If ambiguous, ask the user. Governance files at Projects/ root are exempt.
- **No ungoverned changes:** Any modification to governance files, skills, folder structure, or protocols requires a GitHub Issue via `improvement.yml` template (any category label per `label-taxonomy.md`) + implementation plan + user approval before execution. Self-generated improvements are logged only — do not attempt to resolve unless the user requests it. See "Continuous Improvement Protocol" below.

### Continuous Improvement Protocol

All skills auto-log improvements by creating a GitHub Issue via the `improvement.yml` (or `observation.yml`) template — with the matching category label per `label-taxonomy.md` — whenever they encounter:
- A gap (missing artifact, undefined handoff, unimplemented step)
- An inconsistency (context files disagree, skill behavior doesn't match spec)
- A broken or degraded handoff (tag emitted but receiver can't parse it)
- A process friction point (manual step that could be automated, repeated workaround)
- A quality finding (evidence quality failure, guardrail violation pattern)

**Format:** Use the GitHub Issue improvement template. Include: title with [Category] prefix, severity (P1-P4 in body Priority field), category (selected from required Category dropdown in `improvement.yml`), and body sections (Description, Evidence, Affected Files, Proposed Change, Acceptance Criteria) with enough detail to generate an implementation plan without re-reading the original conversation. The category label corresponding to the dropdown selection is applied at Stage 2 Triage CER Resolve.

**Do not:** Ask the user before creating the Issue. Do not mention it conversationally without also creating the Issue. Do not filter by perceived importance — log everything, let the user triage on GitHub.

**Two paths for improvements:**

**Path A — Self-generated (skill finds a gap during processing):**
1. Apply the **tier-selection test** (symmetric content-shape routing, per `release/references/pipeline/stage-01-intake.md` §5 Path A) to choose the intake template, then create the GitHub Issue immediately using the chosen template:
   - **Observation tier** — author with `observation.yml` when EITHER (a) the insight reduces to "X is missing / drifting / suspect" with next action "look at it" rather than "do this specific thing", OR (b) the "what good looks like" answer fits in one sentence and no specific change / affected file / AC has been proposed yet. Three fields (what is missing, what good looks like in one sentence, which file or section). `observation` label auto-applied. Promotion to Proposal at Triage includes category selection.
   - **Proposal tier** — author with `improvement.yml` when both observation-tier triggers are absent AND every required field can be filled with substantive content. The required Category dropdown must be selected — Triage (Stage 2) applies the matching category label at CER Resolve. Severity is set in the body Priority field.

   Free-form bodies that skip template scaffolding are not permitted.
2. **Do NOT attempt to resolve the gap in the current session.** Continue current work.
3. User triages on GitHub: close = reject, add `approved` label = approved, assign Milestone = bundle. For Observations, the triage agent may also draft a full Proposal for operator approval and close the Observation with `promoted to #N`.
4. Only work on the improvement if the user explicitly requests it.
5. When requested → generate implementation plan → user approves → execute.

- **Temporal-window AC discipline:** Acceptance Criteria with post-close measurement windows (30-day rescore, 60-day adoption survey) fail T3 (Verifiable AC) at merge time and route to **Notes as monitoring commitments** per the Anti-pattern D rule at [`intake-style-guide.md` § 4 Anti-pattern D](../release/references/how-to/intake-style-guide.md). Follow-up tracking issues are filed per the R2 DEFERRED convention when a temporal commitment requires its own lifecycle.

**Path B — User-suggested (user asks for a change in conversation):**
1. Create GitHub Issue (captures the "what" and "why" for paper trail)
2. Assess priority with user: resolve now (same session) or defer to a release?
3. If now: present implementation plan → user approves → execute → close the Issue with implementation comment
4. If deferred: Issue stays open for triage and future release bundling

**Failure handling:** If `gh issue create` fails, include the full Issue body in the conversation output so the user can create it manually. Never silently swallow an improvement.

**User triage:** The user reviews open `improvement` Issues weekly (via weekly-status-rollup Section 4) or ad hoc. Approved Issues get assigned to Milestones for release bundling.

### Closed-Loop Processing Protocol

Every artifact processing cycle follows a closed loop. This protocol defines the cycle; skills are invoked at each step and communicate through files and structured output.

1. **Pre-read** (PPM Agent): Load operational trackers and relevant project artifacts per PPM Pre-processing cross-reference.
2. **Process** (PPM Agent): Extract decisions, actions, risks, blockers from the artifact.
3. **Direct updates** (PPM Agent): Generate TRACKER_UPDATE instructions for changes directly evidenced in the artifact.
4. **Dependency scan** (PPM Agent): Extract entities from each proposed update. Cross-reference against all loaded trackers. Generate Tracker Impact Matrix for secondary effects.
5. **Apply** (Tracker Manager — invoke skill): Consume TRACKER_UPDATES and Impact Matrix. Classify updates by Document Tier (per CLAUDE.md File Management Protocol). Auto-write operational tracker updates. Present stakeholder-facing document updates for user approval.
6. **Close** (PPM Agent): After Tracker Manager completes, confirm pipeline status. Set to CLOSED only when all Impact Matrix entries are resolved or explicitly deferred with reason.

**Skill invocation model:** The PPM Agent produces structured output (TRACKER_UPDATES + Impact Matrix). The Tracker Manager is invoked as a separate skill to consume that output. Skills do not call each other directly — they communicate through files and structured output blocks. The protocol governs the sequence; each skill owns its steps.

This protocol applies to PPM Agent processing. See § Skill Chaining Protocol above for the generalized cascade mechanism — it applies to any skill that produces tracker updates, governed by rules C1–C7.

### Template Protocol

Governs when a skill should produce an artifact via a canonical template versus author it ad-hoc. The protocol owns artifact-family classification, lifecycle state machine (DRAFT→REVIEWED→APPROVED→DEPRECATED→ARCHIVED), provenance schema, and 5 trigger conditions (T1-T5) + 5 promotion gates (P1-P5). Authoritative spec lives at [`core/standards/template-protocol.md`](../core/standards/template-protocol.md); canonical template-family taxonomy lives at [`core/standards/template-taxonomy.md`](../core/standards/template-taxonomy.md). Consumer skills (the 6 template-authoring skills: project-initiator, delivery-engine, eval-writer, pmo-process-designer, pmo-skill-refiner, release-planner) consult the protocol's T1-T5 trigger evaluation before authoring a templatizable artifact and the P1-P5 promotion gates before promoting a skill-internal template to canonical. See the [`template-architecture` roadmap](<OPERATOR_INSTANCE_ROADMAPS_PATH>/template-architecture.md) (operator-local) for the architected path-to-done across downstream initiatives.

### Release Management Protocol

Platform changes follow the release lifecycle defined in `release/governance/RELEASE_PROTOCOL.md`. That file governs: lifecycle steps (intake → triage → bundle → plan → dry-run → snapshot → execute → close → verify), versioning, GitHub Issue requirements, implementation plan format, dry-run protocol, pre-change snapshot protocol with retention policy, and rollback procedures.

See `release/governance/RELEASE_PROTOCOL.md` for the full protocol. Do not duplicate release process rules in this file.

### Stale-RAID Auto-Escalation Protocol

Open RAID items age. This protocol defines age-based auto-escalation so a stale risk or issue surfaces a recommended escalation action instead of silently sitting open. It is cross-skill: PPM Agent owns the RAID weekly review and `[RISK]` / DECISION escalation; Delivery Engine owns RAID updates for delivery blockers. Both apply the same age thresholds; the action they emit differs by skill role.

**Doc-of-record.** The risk-scoring matrix (probability × impact = score 1–25), the tier-routing rules, and the canonical age-threshold table live in [`escalation-thresholds.md`](skills/ppm-agent/references/escalation-thresholds.md) (the PPM Agent reference doc). That doc is authoritative for threshold values and routing; this protocol states the operational trigger (when the check runs, who acts, what action results) and does not re-derive the scoring matrix. Where `raid-templates.md §9`'s generic ">30 days = auto-escalate" note overlaps, this typed table is authoritative for RAID age-escalation; reconciling `raid-templates.md §9` to the type-split is tracked as a deferred follow-up.

**Age thresholds (days open since the RAID entry's open/created date).** A RAID item's age is `today − open-date`, validated against the RAID Log `[Project]_RAID_Log.csv` (Document Tier 1, PPM-owned). Two warning/escalate bands, by RAID type:

| RAID type | Warning at | Escalate at |
|---|---|---|
| Issue (`I-*`) | age > 14 days | age > 30 days |
| Risk (`R-*`) | age > 30 days | age > 60 days |

Assumptions and Dependencies are not age-escalated by this protocol (no threshold defined); they age per their own closure rules in the RAID Log.

**Action by band (the warning → escalate ladder).**

| Band | Condition | Agent action |
|---|---|---|
| **Nominal** | age ≤ warning threshold | No escalation. Item carries forward normally. |
| **Warning** | warning < age ≤ escalate | Flag the item in the RAID review output with a `[RECOMMENDED]` nudge to the owner ("R-PPM-007 open 38 days — past the 30-day risk-warning threshold; confirm mitigation status"). PPM Agent: surface under "what needs your attention". Delivery Engine (RAID Update mode): include in the carry-forward ticker with the warning flag. No tier change. |
| **Escalate** | age > escalate | Flag with an **escalation action**, naming the owner, the breached threshold, and the routed tier per `escalation-thresholds.md`. PPM Agent: raise as a `[RISK]` / `[DECISION]` escalation (per Follow-Up Tag Routing) and route to the tier the doc-of-record assigns to the item's score. Delivery Engine: emit the escalation in the RAID Update output and hand the tag back to PPM Agent for routing (no self-routing — Routing Constraint, max-depth-2 from PPM). |

**Reversibility.** Each escalation is a CHEAP, recommend-tier action (a flag + routed tag the operator reviews) — the protocol recommends; it never auto-closes, auto-reassigns, or mutates the RAID Log without the normal Document Tier 1 approval gate.

**Worked example (AC).** A RAID Log issue (`I-PPM-012`) opened 35 days ago: age 35 > 30 (issue-escalate threshold) → **Escalate** band → agent flags `I-PPM-012` with an escalation action naming the owner and the breached 30-day threshold, and routes per `escalation-thresholds.md` tier rules.

**Evidence labels.** Age computations carry `[INFERRED: today − open-date]`; threshold-breach claims cite the RAID Log row `[SOURCE: <RAID_ID>, open-date]`. See § Evidence Quality Labeling above.

---

## Methodology Awareness Protocol

Skills that consume `PROJECT.md` MUST read the `delivery_approach` field at invocation and parameterize their behavior per the methodology archetype — not hardcode sprint-centric Agile assumptions. This protocol is load-bearing for the release-planner-bundle work (HARD handoff) and future role-skills work (HARD handoff).

**Cross-references:**

- [`schemas/project-schema.md`](../core/schemas/project-schema.md) — `delivery_approach` enum + `custom_methodology_definition` block + V1-V12 validation rules
- [`methodology-parameterization-v1.md`](../release/references/specs/methodology-parameterization-v1.md) — 8 archetype normative definitions + Skill Consumption Pattern (3-branch logic) + 5 domain-specific failure modes
- [`methodology-archetype-matrix.md`](../release/references/specs/methodology-archetype-matrix.md) — per-archetype variation table + Custom row schema + 3 worked examples

### Rule 1 — Read `delivery_approach` at invocation

Every skill that reads PROJECT.md MUST read the `delivery_approach` field and treat it as the primary methodology signal. Skills MAY cache the value for the duration of the invocation but MUST NOT cache across invocations — the field is project-level mutable and the operator may revise between invocations.

### Rule 2 — Consult `methodology-archetype-matrix.md` for per-archetype behavior

The matrix (`release/references/specs/methodology-archetype-matrix.md`) is the canonical data contract for archetype variation. Skills consult the row matching `delivery_approach` for:

- **Lifecycle** — determines iteration pattern (`continuous` / `phased` / `timeboxed`); governs primitive selection (WIP/throughput vs. phase-gate vs. velocity/sprint-goal).
- **Ceremonies** — determines which events the skill recognizes as sync points for status aggregation and decision cadence.
- **Artifacts** — determines which work-products the skill expects as input and generates as output.
- **Cadence** — informs scheduling defaults (sprint-close weeks, PI-midpoint, stage-boundary).

### Rule 3 — Handle `delivery_approach: Custom` via typed extension block

When `delivery_approach: Custom`, skills MUST read the `custom_methodology_definition` block and branch on it per the authoritative 3-branch logic in [`methodology-parameterization-v1.md § 5 Skill Consumption Pattern`](../release/references/specs/methodology-parameterization-v1.md):

1. **CASE 2 — `base_archetype` is one of the 8 enum values.** Skill MAY use the matrix row for the base archetype as a default, overridden by any fields in the Custom block that differ.
2. **CASE 3 — `base_archetype` is `null`.** Skill MUST use the Custom block's `lifecycle` / `ceremonies` / `artifacts` / `cadence` fields directly — NO archetype fallback. If the skill cannot parameterize from these fields alone, skill MUST emit a methodology-agnostic output with an explicit caveat. The skill MUST NOT silently default to Scrum or any other archetype.

`null` is an explicit signal the variant is genuinely novel. Respecting `null` as intentional prevents the PROC-3 Base-archetype blind fallback failure mode.

### Rule 4 — Failure modes to avoid

See [`methodology-parameterization-v1.md § 6 Failure Modes`](../release/references/specs/methodology-parameterization-v1.md) for the 5 domain-specific anti-patterns (category tags per [`failure-mode-standard.md`](../core/specs/failure-mode-standard.md)):

- **INPUT-1 Methodology conflation** — conflating `delivery_approach` with `spm_comanaged`.
- **PROC-2 Custom-block skip** — reading `Custom` without reading the block.
- **PROC-3 Base-archetype blind fallback** — silently defaulting `null` base_archetype to Scrum.
- **PROC-4 Hardcoded sprint presumption** — using DoR/DoD/velocity gates for non-timeboxed lifecycles.
- **HAND-5 Enum-drift** — adding a 9th archetype in one skill without governance promotion.

Skill authors MUST design against these modes; `pmo-qa-auditor` references them when reviewing methodology-aware skill output quality.

### Rule 5 — Governance promotion for recurring Custom variants

A Custom variant recurring with identical `name` across ≥2 projects within a 180-day window is an **emergence candidate** per [`decision-discipline.md § 4.2`](../core/disciplines/decision-discipline.md). When observed:

1. Skills log the occurrence toward the emergence rule (pattern cache N=1 → N=2).
2. The operator MAY elevate the variant to a 9th enum value in a future minor release (v11.x+1) via a governed change per `CLAUDE.md` "No ungoverned changes" protocol — GitHub Issue with `improvement` label + implementation plan + PR.
3. Skills MUST NOT promote archetypes unilaterally. Elevation is operator authority only.

Elevation triggers coordinated updates across:

- New row in [`methodology-archetype-matrix.md`](../release/references/specs/methodology-archetype-matrix.md).
- New archetype H3 section (normative definition) in [`methodology-parameterization-v1.md § 3`](../release/references/specs/methodology-parameterization-v1.md).
- New enum value in [`schemas/project-schema.md`](../core/schemas/project-schema.md) `delivery_approach` field.
- Consumer-skill updates (release-planner, role-skills).

### Relationship to SPM Bridge (Conditional)

The legacy `spm_comanaged: true` binary remains operative and is **NOT deprecated** by this protocol. Reconciliation:

- `delivery_approach: Hybrid` is the **methodological classification** — it describes the dual-lifecycle nature of the project.
- `spm_comanaged: true` is the **operational dual-framing trigger** — it activates the SPM Bridge output in downstream skills (`ppm-agent`, `delivery-engine`, `daily-status`, `weekly-status-rollup`).

Canonical valid combinations:

| `delivery_approach` | `spm_comanaged` | Interpretation |
|---|---|---|
| `Hybrid` | `true` | SPM co-managed project — dual-framing active |
| `Hybrid` | `false` | Self-hosted dual-lifecycle — no dual-framing |
| Non-Hybrid | `true` | **Configuration-validation candidate** — `project-initiator` Mode C flags for operator review |
| Non-Hybrid | `false` | Single-methodology project — no dual-framing |

Skills reading `delivery_approach: Hybrid` for methodology parameterization MUST ALSO read `spm_comanaged` before producing output. Future deprecation of `spm_comanaged` in favor of `delivery_approach: Hybrid` is a future concern and is OUT OF SCOPE. See [`methodology-parameterization-v1.md § 7 Relationship to SPM Bridge`](../release/references/specs/methodology-parameterization-v1.md) + [`schemas/project-schema.md § 7 Migration Notes`](../core/schemas/project-schema.md) for the posture.

---

## Platform-Config Resolution Protocol

Platform configuration is split across two surfaces by concern and resolved by a single cascading resolver. This protocol defines the resolution order, the default-fallback, and the two-track update governance. It **composes with** the Methodology Awareness Protocol above — `default_delivery_approach` is a hierarchy-resolvable field whose resolution this protocol governs, while the `delivery_approach` enum + validation + Custom-block handling stay canonical in the Methodology Awareness Protocol and its cross-referenced schema. This protocol does NOT duplicate the methodology vocabulary.

**Two surfaces (per [`core/ADRs/ADR-022-platform-config-vs-operator-toml-split.md`](../core/ADRs/ADR-022-platform-config-vs-operator-toml-split.md)):**

- [`core/config/operator.toml.template`](../core/config/operator.toml.template) — operator-ENVIRONMENT / IDENTITY: identity, paths, `[adapters]` host-selectors (`repo_host`/`ticketing`/`kb`/`ai_tool` — the onboarding seam), `[methodology].default_delivery_approach`. Security-sensitive (`chmod 600`; depersonalization token vocabulary).
- [`core/config/platform-config.toml.template`](../core/config/platform-config.toml.template) — platform-BEHAVIOR: `[bundling]` (`bundle_doctrine_frame`, `release_size_target_pts`), `[release_class].default_release_class`, `[relationship_mapping]`, `[calibration]`. Freely tunable; no PII. Field schema: [`schemas/platform-config-schema.md`](../core/schemas/platform-config-schema.md).

**Cross-references:**

- [`schemas/platform-config-schema.md`](../core/schemas/platform-config-schema.md) — field / type / allowed-values / default / calibration-policy / consuming-surface / cutover-SHA
- [`config/platform-config.toml.template`](../core/config/platform-config.toml.template) + [`config/operator.toml.template`](../core/config/operator.toml.template) — the two surfaces (Layer-1 defaults)
- [`standards/composition-surface-spec.md`](../core/standards/composition-surface-spec.md) — the durability contract platform-config.toml carries
- [`docs/platform-config-reference.md`](../docs/platform-config-reference.md) — the human-readable catalog

### Rule 1 — Resolve the effective value via the 5-rung cascade

A consumer asking "what is the effective value of field `F` for scope `S`?" resolves by precedence — **most-specific overrides least-specific**:

| Rung | Precedence | Surface | Layer |
|---|---|---|---|
| 1 | lowest | global default — `platform-config.toml.template` / `operator.toml.template` | Layer 1 (always present) |
| 2 | ↑ | portfolio override — `projects/_config/PORTFOLIO.md` frontmatter `platform_config: {...}` | Layer 2 (optional) |
| 3 | ↑ | program override — `projects/<Program>/_config/program-config.toml` | Layer 2 (optional) |
| 4 | ↑ | project override — `projects/<Project>/PROJECT.md` frontmatter `platform_config: {...}` | Layer 2 (optional) |
| 5 | **highest** | individual override — `~/.config/pmo-platform/platform-config.toml` `[overrides]` (and `operator.toml` for identity/adapters) | Layer 2 (optional) |

`effective(F, S)` = the value of `F` at the **highest-precedence rung that SETS `F`**; fall through to rung 1 (global default) if no higher rung sets it.

**Individual is highest precedence** deliberately: an individual operator's explicit override is the most-specific intent and wins even over a project setting. This matches git's `--local > --global` *specificity* logic and the existing `operator.local.toml > operator.toml` precedent. (This is the one genuinely-designed ordering choice; CHEAP to flip to individual-as-base if the operator later intends that.)

**No per-tier operator value ever lands in a tracked Layer-1 file.** The Layer-1 templates ship defaults + schema; per-tier values live in the Layer-2 surfaces above. This mirrors the `delivery_approach` precedent exactly (enum Layer-1 / value Layer-2).

### Rule 2 — Apply the 3-level default-fallback (never hard-fail)

1. Field set at ≥1 rung → resolve per Rule 1.
2. Field set ONLY at rung 1 (global default) → use the default. **Common case** — and the reason the Layer-1 templates ship a value for every field.
3. Field absent even from rung 1 (operator deleted it, or a consumer references a not-yet-added field) → the consumer uses its **own documented hardcoded fallback** and logs `[platform-config: field <F> unresolved; using consumer default <V>]`. A consumer MUST declare its fallback so an absent/corrupt config never hard-fails a release. (Mirrors the methodology-parameterization CASE-3 "emit WITH caveat — never silently default" discipline.)

### Rule 3 — Single resolution at the hub; spokes read injected values

To avoid hub-vs-spoke divergence, config is resolved ONCE at the hub (release-pipeline Procedure 0) and the resolved values are injected into each spoke's chip prompt. **Spokes do NOT re-resolve** — they read the value the hub injected. `release-planner` (Mode A) and `release-executor` (Mode A) resolve their named fields at session start. `deploy.sh` / hooks extend the existing `operator.toml` rung-reader idiom to also read `platform-config.toml` (`resolve_platform_config`).

### Rule 4 — Two-track update governance (split on the Layer boundary)

| Track | What changes | Governance weight |
|---|---|---|
| **Track A — schema / default change (Layer 1)** | edit a default in a template, add/remove a field, change an allowed-values set, edit `platform-config-schema.md` | **Full governed PR** — GitHub Issue (`improvement.yml`) + plan + PR review per CLAUDE.md "No ungoverned changes." These are governance files (a default changes behavior for every install that has not overridden — same blast radius as a governance-rule change). The PR diff IS the dry-run. |
| **Track B — per-tier value set (Layer 2)** | operator sets a field for their own portfolio / program / project / individual scope | **No PR — operator-instance write.** Same as setting `delivery_approach: Kanban` in a PROJECT.md. Layer 2 is git-ignored + Cowork-owned; it never enters the release PR. The operator's own instance history is their audit trail. |

The AC "audit trail: git history of config field changes is the canonical change record" applies to **Track A** (the tracked templates + schema); Layer-2 value sets are audited by the operator's own instance history, not the platform repo.

### Rule 5 — Cutover

This resolution protocol applies to releases entering the pipeline **after this release's merge SHA**; **this release (adapter-config-foundation) itself is exempt** (reflexive-pipeline-loop discipline). Engineering anchors the SHA at Stage 12. Merge SHA: `71047a527eed34d24a0bf059acfc73c20b7ec6b5` (adapter-config-foundation, v1.14).

---

## Framework Review Cadence Protocol

The platform references many named frameworks (PMBOK, SAFe, Nonaka SECI, Diátaxis, ADKAR, Cost of Delay, three-gulfs-methodology, failure-mode-standard, …). Every such framework is registered in [`framework-catalog.md`](../core/specs/framework-catalog.md) — the single source of truth for its version anchor, applicability, and review tier. The convention, primitive, and enforcement surface are codified in [`standards/framework-corpus-discipline.md`](../core/standards/framework-corpus-discipline.md); **this section is the authoritative copy of the tier-assignment rule and review trigger** (the catalog and the protocol doc reference back here per `duplicate-source-discipline.md` register-or-remove).

### Rule 1 — Tier assignment (objective, not vibes)

Every catalog row carries a `tier` ∈ {`stable`, `evolving`, `emerging`}. Tier is assigned by the following objective criterion — not by intuition:

| Tier | Assignment criterion | Cadence | `next_review_due` |
|---|---|---|---|
| **stable** | EXTERNAL: canonical source unchanged ≥5y AND no active revision program. INTERNAL: unchanged ≥2 minor releases | 36 months | `last_reviewed` + 36mo |
| **evolving** | EXTERNAL: major revisions on a 1–3y cadence. INTERNAL: edited within the last 2 minor releases | 12 months | `last_reviewed` + 12mo |
| **emerging** | Industry not yet settled, OR an INTERNAL standard in its first 2 minor releases of life | continuous | `continuous` (review every release touching the consuming surface) |

`review_cadence` is denormalized into the catalog for human scan; `deploy.sh --check` Check 18a asserts it matches `tier`.

### Rule 2 — Catalog-driven schedule (not a uniform calendar)

There is **no "review every framework every quarter" calendar.** The operative review query is: *scan the catalog for rows where `next_review_due ≤ today`.* This is surfaced automatically by `deploy.sh --check` Check 18c (the cadence-aging signal, parallel to Check 17's `status: proposed` aging signal). `emerging`-tier rows (`next_review_due: continuous`) are reviewed every release that touches their consuming surface, not on a date.

### Rule 3 — What a triggered review checks

When a framework's `next_review_due` arrives (or Check 18c flags it), the reviewer confirms:

1. **Anchor currency** — is the catalog `version_anchor` still the current edition/release? (e.g., is `SAFe 6.0` still current, or has a newer edition shipped?)
2. **Tier correctness** — does the framework still meet its tier's assignment criterion? A framework may graduate `emerging → evolving → stable` (or regress) as its source's revision behavior changes. Re-tier if the criterion no longer holds.
3. **Bookkeeping** — bump `last_reviewed` to the review date and recompute `next_review_due` per the (possibly new) tier cadence.
4. **Doc consistency** — for frameworks whose `canonical_doc` carries YAML frontmatter, confirm `framework_version_anchor:` still matches the catalog (also enforced by Check 18b).

### Rule 4 — Escalation when overdue

Check 18c emits an informational (P3) aging signal for overdue rows. The operator triages each: (a) perform the review per Rule 3, (b) re-tier if the cadence was wrong, or (c) accept-as-residual with documented rationale. Persistent un-triaged aging across consecutive releases is itself a reviewable signal (the catalog is not being maintained) — escalate to the workspace owner.

### Rule 5 — Responsible party + governance

The workspace owner ([OPERATOR_NAME]) is accountable for catalog maintenance. Adding, re-tiering, or anchor-correcting a framework is a governed change per `CLAUDE.md` "No ungoverned changes" — GitHub Issue + plan + PR. New frameworks enter the platform *via the catalog* by convention (the catalog-completeness surface is the governed mechanism); a framework referenced only in prose but absent from the catalog is caught by the manual-checklist clause in [`standards/framework-corpus-discipline.md`](../core/standards/framework-corpus-discipline.md) § 6, not by automated prose scan.

---

## Pattern Review Cadence Protocol

The Observation tier (per `observation.yml`, applied via `label-taxonomy.md` `observation` category label) accumulates lightweight gap-capture tickets that are NOT triaged on the Approve/Defer/Reject axis. Observations exist so that patterns emerge from accrued empirical signal — cross-release recurrence is the signal, not the individual observation. This section defines the cadence that scans the observation accumulator for emergent patterns, promotes qualifying patterns to Proposals, and reports on cycle hygiene.

The protocol composes with `decision-discipline.md` § 4.1 (Observation Log) and § 4.2 (Emergence Rule, N=2 same-(domain, theme) within 180 days); § 4.1 / § 4.2 own the schema and threshold; this section owns the operational cadence that fires the scan. Triggered scans are executed in two phases per the planner→executor skill convention: the DRAFT phase is owned by the `release-planner` skill Mode D — Pattern Review (read-only; per `release/skills/release-planner/SKILL.md` § Mode D); the EXECUTE phase is owned by the `release-executor` skill Mode G — Pattern Review Execute (write-authorized; per `release/skills/release-executor/SKILL.md` § Mode G). Operator-explicit handoff (NOT chained=true cascade) bridges the two phases on operator PROMOTE verdict.

### Rule 1 — Trigger (event-bound, not calendar-based)

Pattern Review fires on ANY of the following events. There is **no "review observations weekly" calendar.**

| Trigger | Detection mechanism |
|---|---|
| T1: Observation count threshold | `gh issue list --label observation --state open --json number --jq 'length'` returns ≥ N=2 since last Pattern Review (delta, not absolute count). N=2 matches `decision-discipline.md` § 4.2 N=2 emergence threshold — single canonical threshold, no calibration-flag overhead. The T1 firing triggers Mode D execution; Mode D itself applies § 4.2 N=2 against (domain, theme) groups to determine cluster candidates. T1 false-positive = Mode D runs but surfaces zero clusters; this is cheap. |
| T2: Time-since-last fallback | **60 days** have elapsed since last Pattern Review with zero T1 firings (prevents indefinite accumulation when filing rate is low). Anchor: `RELEASE_LOG.md` last `Pattern Review` row, OR if absent, this protocol's ship date. |
| T3: Release-close hook (informational) | Stage 13 Close emits a `pattern-review-row` event to `<OPERATOR_INSTANCE_PIPELINE_EVENT_LOG>` per the Rule 5 schema. Additionally, IF (since last Pattern Review) ≥1 release has closed AND open-observation count > 0, Stage 13 emits a `pattern-review-due` **informational note** suggesting the operator run Pattern Review at their convenience. The note is informational — NOT auto-routing. The next time the operator invokes release-planner directly (via the `Always-ask` AUQ at SKILL.md Step 2), they may choose Pattern Review per the AUQ option list. T3 emits a notification; it does NOT pre-select Mode D. The existing Always-ask discipline remains intact. |
| T4: Operator-explicit | Operator runs `release-planner` directly and selects Mode D. Always available regardless of T1/T2/T3 state. |

Cadence is **event-bound + 60-day fallback** — same shape as the Structural-audit cadence proposed at sibling issue. The fallback prevents indefinite accumulation under low-filing rates; the events catch the high-filing case where N=2 fires faster than the calendar.

### Rule 2 — What a triggered review checks

When Pattern Review fires, the `release-planner` Mode D execution:

1. **Enumerates** open observations: `gh issue list --label observation --state open --json number,title,body,createdAt --limit 5000`.
2. **Parses** each observation body for the (domain, theme) tag pair — derived from `## What is missing or incomplete` + `## What good looks like (1 sentence)` content per the `observation.yml` 3-field schema and the two-pass heuristic in `decision-discipline.md` § 4.3 (Domain and Theme Tagging). Pass 1 derives a kebab-case narrow tag; Pass 2 broadens to the parent mechanism. Surfaces uncategorized observations (Pass-2 produces `unknown-mechanism`) for operator-rendered theme assignment BEFORE clustering.
3. **Groups** observations by (domain, Pass-2 broadened theme) tuple over a 180-day rolling window from observation `createdAt`.
4. **Applies emergence rule** (§ 4.2 of `decision-discipline.md`): any group with count ≥ 2 within the window surfaces as a candidate pattern.
5. **Drafts graduation candidates** — for each candidate, drafts the literal Proposal-tier issue body per Rule 3 (Graduation Protocol) below. The drafted body is what `gh issue create -F <body>` will literally receive at Mode G execution time.
6. **Surfaces output** as a structured Decision Briefing (read-only, inline verbatim Proposal bodies) for operator review. Operator renders verdict per candidate: PROMOTE (graduate to Proposal), DEFER (keep observing), or CLOSE (no longer relevant).

### Rule 3 — Graduation Protocol (observation → Proposal)

When the emergence rule fires (≥2 same-(domain, theme) within 180 days), the `release-planner` drafts a new Proposal-tier issue (`improvement.yml`) with the following field mapping from the cluster's observations:

| `improvement.yml` field | Source | Generation rule |
|---|---|---|
| `### Priority` | NEW (not in observation schema) | Default to `P3 - Medium`; operator adjusts at Triage. |
| `### Category` (dropdown) | NEW | `release-planner` selects best-fit per the theme (`protocol` for cross-cutting cadence items, `documentation` for spec-clarification clusters, etc.); operator may re-select at Triage. |
| `### Description` | Synthesized header paragraph + verbatim source observation bodies | **Header paragraph (2-3 sentences):** Open with `**Pattern observed across N observations: #<obs1>, #<obs2>[, ...]**`; summarize the emergent theme in 2-3 sentences identifying the (domain, theme) tuple and why the cluster surfaced. **Source observation bodies (verbatim quoted blocks):** Following the header paragraph, embed each source observation body as a markdown blockquote prefixed `> #<obs_number> (filed YYYY-MM-DD by operator):` and indented per blockquote syntax. One block per source observation. Preserves source-text fidelity; supports Stage 2 Triage readers (Triage reviewer sees what operator literally wrote, not synthesis); supports audit trail at promotion time (synthesis-vs-source mismatches detectable). The literal verbatim-quoted-block-with-header structure is what release-executor Mode G files via `gh issue create -F <approved_body_file>` per the LITERAL-body discipline. |
| `### Evidence` | Source observation citations | One bullet per source observation in the form `[SOURCE: #<obs_number>] — <one-line summary>`. |
| `### Affected Files` | Union of `### Which file or section this touches` from each source observation | Deduplicate paths; list each affected file once. |
| `### Acceptance Criteria` | NEW (observations don't have AC) | Draft 2-4 AC capturing the pattern's resolution surface; operator refines at Triage. |
| `### Origin` | Pattern Review session | "Promoted from Observation tier via Pattern Review on `YYYY-MM-DD` per OPERATIONS.md § Pattern Review Cadence Protocol. Source observations: #<obs1>, #<obs2>[, ...]." |
| `### Dependencies` | NEW | Default `None`; agent flags any cross-observation dependency that surfaces. |

After drafting and operator-PROMOTE verdict, the `release-executor` Mode G execute phase (operator-explicit handoff from `release-planner` Mode D, NOT chained=true cascade per the 4-skill allowlist exclusion):

1. Files the new Proposal via `gh issue create -F <approved_body_file>` using `improvement.yml`. The `<approved_body_file>` is the LITERAL body the operator approved in the Decision Briefing — Mode G performs NO synthesis, NO re-rendering, NO field-substitution post-approval.
2. Each source observation is updated: post a closing comment `Promoted to #<new-proposal> via Pattern Review YYYY-MM-DD`; close the observation with reason `not planned` (operator can re-open if needed).
3. `RELEASE_LOG.md` Pattern Review row is appended (per Rule 5 below).

**Operator approval gate (LITERAL body).** Operator PROMOTE verdict in release-planner Mode D Step 6 is rendered against the verbatim Proposal body inline in the Decision Briefing — NOT against a cluster summary abstraction. The release-executor Mode G consumes that LITERAL approved body file via `gh issue create -F <approved_body_file>` with NO synthesis, NO re-rendering, NO field-substitution post-approval. This is the C5 cascade approval-rule discipline expressed as a load-bearing artifact: the body the operator literally read is the body that gets filed.

### Rule 4 — Escalation when overdue

When T2 (60-day fallback) fires for the second consecutive cycle with zero emergent patterns (i.e., observations are accumulating but no (domain, theme) group has reached N=2), the operator triages:

- (a) **Pattern Review cadence is too aggressive** — extend N=2 → N=3 OR 60-day → 90-day; document in this section.
- (b) **Theme tagging is too narrow** — observations are not clustering because the (domain, theme) tuple is too specific; broaden per `decision-discipline.md` § 4.3 (Theme tagging guidance: "Use broad mechanism-level tags as the default. Narrow per-instance tags … prevent emergence under small N").
- (c) **Observation rate is genuinely low** — accept-as-residual; the observation accumulator is healthy; emergent patterns will surface when they do.

Repeated cycles of (c) with stable observation count is a **healthy state**, not a failure mode. The cadence design avoids forcing pattern emergence; patterns earn promotion via accrued evidence.

### Rule 5 — Responsible party + audit-trail

The workspace owner is accountable for Pattern Review verdicts at the PROMOTE / DEFER / CLOSE point per Rule 3. The `release-planner` Mode D execution is the DRAFT-phase producer (read-only); the `release-executor` Mode G execution is the EXECUTE-phase writer (operator-explicit handoff); the operator is the renderer of PROMOTE/DEFER/CLOSE verdicts at the Mode D Decision Briefing.

`release-executor` Mode G appends one row per Pattern Review to `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` under a `## Pattern Reviews` H2 (one-time bootstrap if absent), with columns:

| Date | Trigger | Open observations | Clusters surfaced | PROMOTE / DEFER / CLOSE verdicts |
|---|---|---|---|---|

**Pattern-review-row event schema (canonical — inline because no pipeline-event-log-schema.md exists in core/standards/):**

```yaml
event_type: pattern-review-row
schema_version: 1
required_fields:
  - timestamp: ISO 8601 UTC datetime (when the Pattern Review fired)
  - trigger: enum {T1, T2, T3, T4} (which Rule 1 trigger fired — T1 obs-count, T2 60-day fallback, T3 release-close informational, T4 operator-explicit)
  - observations_scanned_count: integer (total open observations at scan time per release-planner Mode D Step 1 enumeration)
  - clusters_surfaced_count: integer (number of (domain, Pass-2 broadened theme) groups meeting N ≥ 2 emergence per § 4.2)
  - verdicts: map<cluster_id, enum {PROMOTE, DEFER, CLOSE}> (operator-rendered verdicts at Mode D Step 6 Decision Briefing)
  - promotions: list<map> (per PROMOTE cluster — fields: source_observation_ids: list<integer>, new_proposal_id: integer)
  - producer: string literal "release-planner Mode D" (consistent string for grep-ability)
  - executor: string literal "release-executor Mode G" (consistent string when promotions list is non-empty; null otherwise — no Mode G fired when zero PROMOTE verdicts rendered)
optional_fields:
  - notes: free-text operator note (e.g., calibration observations, false-positive detection notes, theme-tag-quality observations)
```

**Emission location.** Stage 13 Close emits this event row to `<OPERATOR_INSTANCE_PIPELINE_EVENT_LOG>` (resolved per OPERATOR_INSTANCE_PIPELINE_EVENT_LOG variable — operator-instance path). For runs where Mode G fired (PROMOTE verdicts rendered), Mode G ALSO emits the same event row at its Step 5 (the duplicate emission is intentional — Mode G's emission captures the post-execution state; Stage 13's emission captures the cadence audit-trail; both are reconcilable via shared `timestamp` field). If a `pipeline-event-log-schema.md` is authored in a future release, the schema migrates there with a back-reference from this section.

**Cutover discipline:** Applies to all releases entering Stage 12 going forward.

---

## Platform Health Audit Protocol

The platform catalogs every PMO source-roster skill against the Anthropic skill catalog in the
[`anthropic-base-vs-build-registry.md`](../core/specs/anthropic-base-vs-build-registry.md) instance.
This section owns the **operational cadence** (trigger, responsible party, escalation, audit-trail)
for re-auditing that instance; the **methodology** is owned by
[`platform-health-audit-framework.md`](../release/references/protocols/platform-health-audit-framework.md)
(cite-not-duplicate per `duplicate-source-discipline.md`). The executor is **pmo-qa-auditor Mode E —
Platform Health Audit** (see [`../skills/pmo-qa-auditor/SKILL.md`](../core/skills/pmo-qa-auditor/SKILL.md)
§Modes), an **OBSERVE-only** producer mode.

### Rule 1 — Trigger (event-bound + quarterly fallback)

Platform Health Audit fires on a quarterly cadence plus reactive drift signals. There is **no
"audit the platform every week" full-audit calendar** — the full audit is quarterly; a lightweight
weekly sentinel watches for drift only.

| Trigger | Detection mechanism |
|---|---|
| T-quarterly | The `platform-health-quarterly-audit` scheduled task (cron `0 9 1 1,4,7,10 *` — 09:00 on the 1st of Jan/Apr/Jul/Oct, LOCAL timezone) spawns a session that invokes Mode E. |
| T-drift-watch | The `platform-health-drift-watch` scheduled task (weekly) runs ONLY the framework §3.5 T1–T5 drift detection; any drift self-routes to a single observation issue-draft. |
| T-reactive | A §3.5 drift signal observed out-of-band (a new plugin pack, a new `anthropic-skills:*` skill, a new PMO skill) per the framework §3.5 trigger taxonomy. |
| T-operator | Operator invokes pmo-qa-auditor Mode E directly. Always available. |

Quarterly is chosen over a tighter full-audit cadence because the Anthropic-catalog surface changes
slowly (the registry baseline held 41 days to the first observed T5 drift). Scheduled tasks run only
while the app is open (deferred-to-launch otherwise — see Rule 4). Schedule is evaluated in LOCAL
timezone; the audit-folder date stamp uses UTC (`date -u`) — intentional, do not unify.

### Rule 2 — What a triggered audit checks

When the audit fires, the pmo-qa-auditor Mode E execution:

1. **Loads** the registry instance + the framework methodology; extracts the recorded `audit_baseline_sha` + `audit_baseline_date` from the registry header.
2. **Re-enumerates** the Anthropic catalog per framework §3.1 Hybrid baseline (Source A plugin-cache ∪ Source B `anthropic-skills:*` namespace, deduped).
3. **Re-enumerates** the PMO source roster (`ls -1d {core,operations,release}/skills/*/`) and diffs it against the registry's row set (the §3.5 **T5** check); diffs the re-enumerated Anthropic catalog against the recorded baseline (the §3.5 **T1–T4** checks).
4. **Classifies drift** per the §3.5 trigger table → each item maps to a §3.3 (a/b/c) update path; applies the registry-header Overlap Detection Rubric and Scorecard Weighting.
5. **Emits** the audit folder (`<OPERATOR_INSTANCE_ANALYSIS_PATH>/platform-health-${AUDIT_DATE_UTC}/` — operator-instance, git-ignored): SUMMARY.md, findings-register.md, base-build-deltas.md, and ≥3 `issue-drafts/NNN-*.md` in observation format.
6. **Observational self-check** — scans output for prescriptive verbs (`recommend`, `migrate`, `consolidate`, `should`) per the audit-class output discipline; rewrites any to observational form.

### Rule 3 — Drift disposition (observe → observation-issue)

Mode E **observes** drift and emits `issue-drafts/` in observation format (`observation.yml` 3-field
schema). The operator triages each on GitHub (PROMOTE to a Proposal / DEFER / CLOSE) — the same
draft→operator-verdict split as the Pattern Review Cadence Protocol. The registry §3.3 row write is a
**separate human-gated change** ("No ungoverned changes"); Mode E never mutates the registry. Authority:
framework **§3.3(a)** assigns the registry row-add to the skill author's creation PR, structurally
distinct from an audit mode.

### Rule 4 — Escalation when overdue

If the quarterly job has not run for **2 consecutive quarters** (app-closed accumulation — scheduled
tasks only run while the app is open), the operator runs Mode E manually. Mirrors the Framework Review
Check-18c aging-signal posture: a persistently un-run audit is itself a reviewable signal that the
catalog is not being maintained.

### Rule 5 — Responsible party + audit-trail

The workspace owner ([OPERATOR_NAME]) is accountable for triaging Mode E findings at the PROMOTE /
DEFER / CLOSE point per Rule 3. Each audit folder is the durable audit-trail; the audit-folder date
is the cadence anchor. The two scheduled-task registrations are non-git MCP state (install-root); their
registration is recorded as a Stage 12 deploy-log line item, and rollback is deregistration (`enabled:false`
or task delete), NOT `git revert`.

---

## Corpus Research & Adoption Protocol

Before any methodological practice enters the K1 corpus, the proposing agent or operator MUST research its evidence base and emit a curation Intake record. This protocol is the **operational producer** of [`corpus-curation.md`](../core/disciplines/corpus-curation.md) curation-protocol Step 1 (Intake) — the doc owns the *rubric* (evidence tiers, source taxonomy, evidence labels); this section owns the *procedure*, exactly as the Methodology Awareness Protocol operationalises `methodology-parameterization-v1.md`. The corpus is the K1 Codified set per [`knowledge-architecture.md#k1-codified`](../core/disciplines/knowledge-architecture.md#k1-codified); contextual K2–K5 knowledge is never curated here.

**Cross-references:**

- [`corpus-curation.md`](../core/disciplines/corpus-curation.md) — ET1–ET5 rubric, 6-step curation protocol, 6-domain source taxonomy, evidence-label extension (the rubric this procedure feeds)
- [`corpus-curation.md#evidence-tiers`](../core/disciplines/corpus-curation.md#evidence-tiers) — evidence-tier acceptance thresholds (Step 1 evidence research)
- [`corpus-curation.md#source-taxonomy`](../core/disciplines/corpus-curation.md#source-taxonomy) — preferred-source lookup by domain (Step 2 domain identification)
- [`knowledge-architecture.md#tier-classifier`](../core/disciplines/knowledge-architecture.md#tier-classifier) — the universality (K1) gate applied at Step 3
- [`decision-discipline.md`](../core/disciplines/decision-discipline.md) — emergence-rule promotion is one valid Intake source (an ET4 candidate path)

### Step 1 — Research the evidence base

Before proposing a candidate practice, research its evidence against the [`corpus-curation.md#evidence-tiers`](../core/disciplines/corpus-curation.md#evidence-tiers) acceptance thresholds. Determine the strongest ET tier the available evidence can support — cite the specific source (review + year; framework + edition; standard + edition; originating release/issue + internal-application count; or single source). Do not assert a tier the evidence cannot clear.

### Step 2 — Identify domain + preferred source

Classify the candidate into one of the [`corpus-curation.md#source-taxonomy`](../core/disciplines/corpus-curation.md#source-taxonomy) domains (D1–D6) and look up that domain's named authoritative sources + default tier. Prefer the taxonomy's named source; deviate only when the candidate's specific evidence warrants a different ET, and record why.

### Step 3 — Emit a curation Intake record

Produce a curation Intake record with all four required fields per the `corpus-curation.md` curation-protocol Step 1: (1) source citation, (2) proposed ET tier, (3) universality position — the practice MUST classify as K1 per [`knowledge-architecture.md#tier-classifier`](../core/disciplines/knowledge-architecture.md#tier-classifier) (contextual K2–K5 is not corpus), (4) domain. An incomplete record does not pass the Intake gate.

### Step 4 — Escalate when no source clears ≥ ET4

When no available source clears at least ET4, do not silently admit or silently drop the candidate. Escalate to the workspace owner with the evidence findings and a recommended disposition from the bounded set:

1. **Defer** — hold pending stronger evidence (no corpus change).
2. **Accept as ET5 with mandatory paired contraindication** — admit only with the explicit `[EXPERT-OPINION:]` label + a paired contraindication reference + a scheduled re-review date (per the `corpus-curation.md` ET5 row and the applicability seam).
3. **Reject** — the candidate does not qualify for the corpus; route any contextual content to its `knowledge-architecture.md` placement home.

The operator renders the disposition; the agent does not self-authorize an ET5 admission.

---

## RAID ID Namespacing

Risks, Assumptions, Issues, Dependencies are tracked in the RAID Log. Each skill owns its own prefix to prevent collision:

| Skill | Prefix | Example |
|-------|--------|---------|
| PPM Agent | `R-PPM-###` | R-PPM-047 |
| Delivery Engine | `R-DE-###` | R-DE-012 |
| Change Management | `R-CM-###` | R-CM-005 |
| Technical Analyst | `R-TA-###` | R-TA-008 |
| Process Designer | `R-PD-###` | R-PD-003 |

Format: `[TYPE]-[SKILL]-[COUNTER]` where TYPE = R/A/I/D.
Example: `A-PPM-018` = Assumption 018 from PPM Agent.

---

## Standard Project Folder Structure

All projects follow this structure. Do NOT create project-specific subfolders outside this hierarchy.

### Platform Boundary Enforcement

All PMO operational skills operate within Layer 2 (Operations domain — `Projects/` and its subfolders). Skills that write operational data — trackers, status logs, transcripts, generated artifacts — must target Layer 2 paths exclusively. No operational skill may modify Layer 1 files (`CLAUDE.md`, `core/`/`operations/`/`release/`, `.claude/settings.json`, `.claude/rules/`) without an approved IMP entry and a release executed through RELEASE_PROTOCOL.md. Bridge files (Layer 3) follow their dual-ownership rules defined in CLAUDE.md "Platform vs. Working Content Boundary."

```
[Project Name]/
├── PROJECT.md                              ← Transient state: phase, people, dates
├── 01-Governance/
│   ├── Charter
│   ├── Kickoff Notes
│   ├── Stakeholder Map
│   ├── Cutover Plans
│   ├── Communication Plans/                    ← Stakeholder comm plans, escalation protocols
│   └── Change-Management/                     ← Impact assessments, readiness, go/no-go, hypercare
├── 02-Design/
│   ├── FDDs/                               ← Functional Design Documents
│   ├── Process Flows/
│   ├── Training/                              ← Project-authored training plans and materials
│   └── Architectures/
├── 03-Testing/
│   ├── Jira Export/                        ← test exports, ticket snapshots
│   ├── Test Plans/
│   └── Test Results/
├── 04-PMO-Operations/                      ← Operational artifacts live here
│   ├── [Project]_Daily_Status_Log.md
│   ├── [Project]_Communications_Tracker.md
│   ├── [Project]_Open_Meetings_Tracker.md
│   ├── [Project]_Transcript_Register.md
│   ├── [Project]_Daily_Status_Update_Framework.md
│   ├── Executive_Status_Report_Prompt.md
│   ├── [Project]_RAID_Log.csv
│   └── Key Terms Glossary.csv
├── 05-Transcripts/
│   ├── Daily-Connects/                     ← YYYY-MM-DD.txt
│   ├── AM-Testing/                         ← YYYY-MM-DD.txt
│   ├── PM-Testing/                         ← YYYY-MM-DD.txt
│   ├── Weekly-Status/                      ← Weekly reports
│   ├── Touch-Base/                         ← Ad-hoc sync notes
│   └── Topic-Sessions/                     ← Focused deep-dives
├── 06-Emails/                              ← Raw emails, Teams messages, provided comms (reference archive)
│   └── (Raw files: forwarded emails, Teams messages, QA status PDFs, comms digests)
├── 07-Reference/
│   ├── SOPs/
│   ├── Runbooks/
│   ├── Vendor Documentation/                  ← Vendor guides, system manuals, external training
│   └── Historical Artifacts/
└── 08-Generated/
    └── _unclassified/                      ← Staging area for auto-generated artifacts
```

## Folder Routing Guidelines

Route files by **content function**, not by format or keyword match. When a file could fit multiple folders, ask: What is this document's primary purpose? → Which folder serves that purpose?

**Routing authority:** File Router (`file-router/references/routing-patterns.md`) is the single source of truth for classification patterns and routing rules. This section defines folder purpose — what belongs where and why. File Router implements the mechanics — how files get there.

| Folder | Purpose |
|--------|---------|
| **01-Governance/** | Project-level governance and change control: charters, project plans, SOWs, approval records, cutover/go-live plans, communication plans, stakeholder maps, change management artifacts (impact assessments, readiness checklists, go/no-go criteria, hypercare plans, adoption tracking) |
| **02-Design/** | Functional and technical design: FDDs, process flows, architecture docs, project-authored training plans and materials |
| **03-Testing/** | Test execution and quality assurance: test plans, test scripts, defect exports, QA/UAT results, test-related Jira exports |
| **04-PMO-Operations/** | Skill-managed operational artifacts (see Operational Artifacts table for authoritative list). Document Tier classification governs approval requirements regardless of folder placement |
| **05-Transcripts/** | Meeting recordings and transcriptions, organized by meeting type subfolder. Raw evidence — never modified after filing |
| **06-Emails/** | Communication evidence archive: forwarded emails, Teams message exports, comms digests. Raw evidence — decision records extracted from emails belong in Governance |
| **07-Reference/** | External reference material not authored by this project: vendor documentation, SOPs, standards, glossaries |
| **08-Generated/** | Claude-generated artifacts staged for promotion. Temporary — promoted to target folder on user approval, auto-archived after 10 business days |

**Operational override principle:** Documents listed in the Operational Artifacts table reside in 04-PMO-Operations/ regardless of where standard PMO taxonomy would place them. Their Document Tier classification (Document Tier 1 or Document Tier 2) maintains the appropriate governance oversight. The Operational Artifacts table is the authoritative list — this section does not enumerate its contents.

**Ambiguity rule:** When a file's content serves multiple purposes (e.g., a Jira export that contains both project plan milestones and test case data), route by primary function. A project plan exported from Jira routes to 01-Governance/ even though it's a Jira CSV. A test-specific export routes to 03-Testing/. When genuinely ambiguous, File Router presents both options to the user.

---

## File Format Conventions

Format selection governs **how** an artifact is stored on disk. It is orthogonal to the Document Tier classification (see [/CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) § File Management Protocol), which governs **what** an artifact is and its approval gate. A RAID Log is Document Tier 1 (approval-gated) *and* stored as CSV; the two classifications compose — they do not substitute for one another.

| Format | Use For | Don't Use For |
|---|---|---|
| **Markdown (`.md`)** | Docs, templates, skill definitions, status logs, carry-forward trackers, draft artifacts | Computation-heavy data, stakeholder-facing final deliverables |
| **CSV (`.csv`)** | Structured tracker data (RAID, transcript register, any row-based log) | Prose content; diagrammatic content |
| **JSON / YAML** | Machine-readable schemas; configs; automated tool output | Narrative documentation |
| **Excel (`.xlsx`)** | Computation-heavy trackers with formulas; stakeholder-shared plans with cell-level collaboration; project finance | Plain tabular data (use CSV); narrative content (use MD) |
| **PDF (`.pdf`)** | Final-form external deliverables (signed plans, audit reports, training decks for distribution) | Work-in-progress content; internal trackers |
| **HTML (`.html`)** | Rendered-for-viewing artifacts only; NOT a source-of-truth format | Source content (use MD → convert on export) |
| **Word (`.docx`)** | Received stakeholder artifacts (preserve original); stakeholder drafts where they require Word | Internal content (use MD) |

### README-Per-Folder Convention

Every major folder carries a `README.md` so contributors and agents get cold-start context without consulting `/CLAUDE.md` or this file. The README states folder purpose, organization, governing doc, and the file-management Layer.

**Template (4-line header):**

```markdown
# <Folder display name>

**Purpose:** <one sentence — what lives here>
**Organization:** <how files/subdirs are arranged>
**Governance:** <governing doc — /CLAUDE.md §X / core/governance/OPERATIONS.md §Y / RELEASE_PROTOCOL.md>
**Layer:** <1 (Engineering, git-tracked) | 2 (Operations) | 3 (Bridge)>
```

**`Layer:` semantics.** The 4th line states the file-management domain so a cold-start agent knows git-tracked-Engineering vs. Cowork-owned-Operations vs. Bridge *before* editing — editing a Layer 2 file from Claude Code violates the operations-bridge boundary. This is the highest-value cold-start field in this two-domain workspace.

**Three index classes:**

| Class | Applies to | Contract |
|---|---|---|
| **Index-style** | `core/skills/`/`operations/skills/`/`release/skills/`, `core/schemas/`, `operations/templates/` | 4-line header **+ `## Index` table**. `skills/`: parameterized roster — `deploy.sh` the per-module arrays (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS) + `SUPPLEMENTARY_SKILLS` + canary is the source of truth, `deploy.sh --check` Check 5 asserts the count; never hardcode a skill number. `schemas/`: one row per `*.md` with coverage area (regenerate from directory listing). `templates/`: preserve the existing registry (augment-not-regenerate). |
| **Map-pointer** | `core/README.md` | Owned per the canonical reference-README convention — the canonical Diátaxis quadrant map. Per-folder READMEs never author quadrant prose. |
| **Lightweight** | all other folders | 4-line header + at most a 1–3 line "key entries / see <governing doc>" pointer — **no exhaustive file enumeration** (a hand-maintained file list rots; avoids duplicate-source drift vs. governing docs). |

**`core/` cross-link rule.** `core/README.md` is the canonical Diátaxis quadrant map for the reference tree. Per-folder READMEs inside `core/` carry the lightweight 4-line header only and link up to it for the quadrant taxonomy — they do **not** restate the map. Each carries exactly one pointer line:

```markdown
> Quadrant taxonomy: see `core/README.md`.
```

**Link convention.** All links in per-folder READMEs use **workspace-rooted absolute form** (`core/...`/`operations/...`/`release/...`, `.claude/...`, `projects/...`, `memory/...`; leading-slash `/CLAUDE.md` for workspace-root files) — zero `../`, depth-invariant, so a future reorganization does not re-break them (per Amendment 1).

---

## Operational Artifacts (04-PMO-Operations/)

These are living documents. Update cadence and ownership are defined below.

| Artifact | Purpose | Update Document Tier | Owner | Cadence |
|----------|---------|----------------------|-------|---------|
| `[Project]_Daily_Status_Log.md` | Carry-forward tracker: blockers, decisions, actions, deferred items, retest queue. Single source of truth for daily processing. | Document Tier 2 | Delivery Engine | Daily → update post-transcript |
| `[Project]_Communications_Tracker.md` | MSG-## entries, lifecycle (ACTIVE/CORE/ARCHIVE), response tracking, recipient list. | Document Tier 2 | Comms Writer | On-send + weekly cleanup |
| `[Project]_Open_Meetings_Tracker.md` | MTG-## entries, scheduling status, agenda, participants, outcomes, action items. | Document Tier 2 | Delivery Engine | Post-meeting update |
| `[Project]_Transcript_Register.md` | TR-### entries, tags, 3-sentence summaries, file paths, processing status (UNASSIGNED/PROCESSING/CLOSED). | Auto-write | PPM Agent | Post-file-route |
| `[Project]_Daily_Status_Update_Framework.md` | Prompt templates for status updates: exec, stakeholder, team, technical. | Document Tier 2 | Comms Writer | Quarterly review |
| `Executive_Status_Report_Prompt.md` | Leadership report template with leadership-specific sections. | Document Tier 2 | Comms Writer | Quarterly review |
| `[Project]_RAID_Log.csv` | Risks, Assumptions, Issues, Dependencies. RAID_ID namespaced per skill. Active/Archive split — closed items archived, never purged. Schema in tracker-schemas.md. | Document Tier 1 | PPM Agent | Weekly review. Closure moves to ARCHIVE section. |
| `Key Terms Glossary.csv` | Terminology, acronyms, team-specific language. | Document Tier 1 | Process Designer | As-needed |

### Document Tier Definitions

- **Document Tier 1 (Stakeholder-Facing):** FDDs, RAID logs, plans, requirements, governance docs. Updated manually by [OPERATOR_NAME] or on explicit direction.
- **Document Tier 2 (Operational):** Trackers, status logs, comms tracking. Updated via approval process: Claude identifies changes, presents summary, executes on approval.
- **Document Tier 3 (New Files):** Uploaded transcripts, emails, exports. Classified and routed by File Router; may trigger Document Tier 2 updates.
- **Document Tier 4 (Context Files):** PROJECT.md, OPERATIONS.md, CLAUDE.md. Updated when evidence contradicts stated state.

### Content Tracking Pattern

The workspace follows a two-layer model for all incoming content:

**Layer 1 — Raw archive:** Source material stored in its original form (05-Transcripts/ for recordings, 06-Emails/ for correspondence). The archive is the evidence store — never deleted, never modified.

**Layer 2 — Summary tracker:** Operational trackers in 04-PMO-Operations/ extract, structure, and lifecycle-manage the actionable content from raw archives. The tracker is the operational view.

**Rule for new content types:** When a new content type enters the workspace, it must have either: (a) a dedicated summary tracker with a defined schema in tracker-schemas.md, or (b) an explicit exemption. Content types are exempt from dedicated tracking when a live external system (Jira MCP, Confluence MCP) provides real-time access to the same data — the raw file serves as a point-in-time offline reference only.

**Exemption criteria:** A content type is exempt from a dedicated tracker when: (1) a live MCP connector provides real-time access to the same data, AND (2) the raw file is filed as a reference snapshot, not as a lifecycle-managed artifact. Currently exempt: Jira exports (Jira MCP), FDD versions (Confluence MCP), QA status PDFs (status extracted to Daily Status Log during processing).

---

## Daily Processing Cycle

Execute this cycle once per day, triggered by user or automation:

0. **Drift Check** — Validate key claims in context files against observable reality before processing begins.
   - **(a) Skills count:** OPERATIONS.md Skills Section skill count matches actual `.skills/skills/` directory count.
   - **(b) Issue tracking:** GitHub Issues with `improvement` label are accessible (`gh issue list --limit 1` succeeds).
   - **(c) Session freshness:** SESSION_STATE.md `last_updated` freshness (per staleness rule in CLAUDE.md).
   - **(d) Portfolio accuracy:** PORTFOLIO.md project list matches actual `Projects/` subdirectories (excluding `_governance/`, `Reference/`, `_Skill-Packages/`, `Archive/`).
   - **(e) Release sync:** RELEASE_LOG.md latest version matches RELEASE_PROTOCOL.md status line.
   - **(f) Governance file presence:** All expected files exist in `Projects/_governance/`: OPERATIONS.md, PORTFOLIO.md, SESSION_STATE.md, RELEASE_PROTOCOL.md, CORRECTIONS.md, Releases/RELEASE_LOG.md. Missing or relocated governance files = **critical drift** — block processing until resolved.
   Flag discrepancies as `⚠️ DRIFT DETECTED:` with proposed correction. Critical drift blocks processing; moderate/low drift is flagged and processing continues.
1. **File Intake** — Check for new files from Google Drive (MCP), user uploads, Jira exports.
2. **Transcript Surfacing** — Resurface `UNASSIGNED` / `PENDING` transcripts from Transcript Register (>3 business days escalates).
3. **File Classification** — File Router (when active) classifies new files by pattern; routes to correct folder.
4. **PPM Triage** — PPM Agent processes all new/unprocessed transcripts against Daily Status Log carry-forward.
5. **Register Update** — Transcript Register written with TR-### entry, tags, summary, path, status → `PROCESSING`.
6. **Follow-up Tags** — PPM emits tags (`[DELIVERY]`, `[COMMS]`, `[TECHNICAL]`, `[CHANGE]`, `[RISK]`, `[DECISION]`) for specialist work.
7. **Specialist Processing** — Each tagged skill processes its work in parallel.
8. **Comms Digest** — If comms digest available, process for MSG-## entries and response tracking.
9. **External Sync** — Jira MCP pulls ticket statuses; Confluence MCP checks for drift in FDDs/RAID logs.
10. **Consolidated Update** — Tracker Manager prepares single change summary: what's changing, where, why, evidence.
11. **User Approval** — User reviews summary; approves or requests modifications.
12. **Execution** — On approval, all Document Tier 2 tracker updates written; Transcript Register status → `CLOSED`.
13. **Artifact Check** — Artifact Generator identifies missing/outdated artifacts (FDD approval sign-offs, process flows, training). Flags for creation.
14. **Portfolio Sync** — PORTFOLIO.md updated with project status roll-up.
15. **Orphan Detection** — Check Projects/ root and Claude/ root for files that appear to be project artifacts (not governance files). If found, flag: "⚠️ ORPHAN FILE: [filename] found at [path]. Likely belongs in [project]/[folder]. Route now?" User confirms routing or marks as intentional.
16. **Proactive Next Steps** — Surface upcoming decisions, escalations, risk events based on timeline.
17. **Session State Update** — Before concluding, update SESSION_STATE.md per its Session-End Update Checklist. Overwrite the Last Session Summary (do not append). Mandatory for any session that modified governance files, processed transcripts, created/promoted artifacts, or changed project state.

---

## Evidence Gate for Closing Items

Items leave carry-forward (Daily Status Log) **only** with evidence. No evidence = stays in backlog.

| Item Type | Closure Requirement | Example Evidence |
|-----------|-------------------|------------------|
| Blocker | Resolved OR mitigation approved | Transcript: "Alex confirms FDD submitted"; Jira: ticket moved to In Progress |
| Action | Completed with confirmation | Transcript: "Maria confirmed training schedule posted"; Email: confirmation receipt |
| Decision | Made and recorded | Transcript: "Team decided to defer Phase 2 testing"; Confluence: RAID log updated with decision |
| Retest Queue | Test plan confirms pass | Jira: test case marked Pass; Transcript: "Regression suite passed Thursday" |

---

## Lifecycle Transitions (Communications & Meetings)

Messages and meetings move through lifecycle states. Apply these rules consistently:

| State | Meaning | Entry Condition | Exit Condition | Hold Duration |
|-------|---------|-----------------|-----------------|---------------|
| `ACTIVE` | Awaiting response or action | Created / sent | Response received | Until response |
| `CORE` | Response received; still supporting open parent (RAID/decision) | Response received | Parent RAID/decision closed | 5 business days |
| `ARCHIVE` | Response received; no open parent; awaiting age-out | Parent closed OR no parent + response 3bd old | Auto-purge | Purged at +3bd or +5bd (if CORE) |
| (Never archive) | — | Comm Plan items, exec escalation chains, decision-changing messages | — | Permanent reference |

Meetings follow the same lifecycle: ACTIVE (scheduled) → CORE (completed, outcomes open) → ARCHIVE (outcomes resolved, no follow-up).

---

## Transcript Processing Protocol

Transcripts are the primary evidence source. Apply this protocol to all transcripts (daily connects, testing sessions, topic dives, status calls).

### Transcript Intake
- **File route** — Classified by filename pattern (see "New File Routing Rules" below).
- **Path validation** — Verified against project folder structure on register write.
- **Single-source detection** — Flagged as `[SINGLE-SOURCE RECORDING]` when only one speaker but content references multiple viewpoints or "we" language. Note participant extraction from content mentions (not speaker attribution).
- **Summary format** — 3 sentences: (1) primary outcome, (2) key blocker/decision, (3) next action + owner.
- **Tags** — Controlled vocabulary: `[CATEGORY:value]` or `[CATEGORY]`. Examples: `[BLOCKER:FDD Approval]`, `[DECISION]`, `[CHANGE]`.

### Unassigned Transcript Escalation
- Transcripts remain `UNASSIGNED` until PPM processes them.
- Resurface every daily cycle.
- After >3 business days: escalate to strategic review (flag in Transcript Register as `[ESCALATION PENDING]`).
- After >5 business days: escalate to project lead with "Response required" note.

### Path Validation on Register Write
- Check that file physically exists at registered path.
- If broken: flag as `[PATH:BROKEN]` and surface for file recovery/re-routing.
- Do NOT process a transcript with broken path; mark as `UNASSIGNED` pending path resolution.

---

## New File Routing Rules

**Note:** These are simplified filename patterns. For authoritative content-based classification, see `file-router/references/routing-patterns.md` (the routing authority per Folder Routing Guidelines).

Classify incoming files by pattern and route to correct folder. If pattern doesn't match, route to `05-Transcripts/Topic-Sessions/` or `07-Reference/` as fallback.

| Pattern | Route To | Owner |
|---------|----------|-------|
| `AM Testing YYYY-MM-DD.txt` | `05-Transcripts/AM-Testing/` | File Router |
| `PM Testing YYYY-MM-DD.txt` | `05-Transcripts/PM-Testing/` | File Router |
| `Daily Connect YYYY-MM-DD.txt` | `05-Transcripts/Daily-Connects/` | File Router |
| `*Weekly status Report*` | `05-Transcripts/Weekly-Status/` | File Router |
| `*monday touch base*` (case-insensitive) | `05-Transcripts/Touch-Base/` | File Router |
| `FW_*` or `RE:*` (email forwards) | `06-Emails/` | File Router |
| `QA*UAT*status*` (PDF, case-insensitive) | `06-Emails/` | File Router |
| `*Teams*` or `*teams message*` (case-insensitive) | `06-Emails/` | File Router |
| User-provided email digests, screenshots, or comms | `06-Emails/` | File Router |
| `FDD*` or `*Functional Design*` | `02-Design/FDDs/` | File Router |
| `*Cutover*` or `*Go-Live*` | `01-Governance/` | File Router |
| Jira export (`.csv` with test-case columns) | `03-Testing/Jira Export/` | File Router |
| Other `.txt` transcripts | `05-Transcripts/Topic-Sessions/` | File Router |
| `SOP`, `runbook` | `07-Reference/` | File Router |
| `training*` (project-authored) | `02-Design/Training/` | File Router |
| `training*` (vendor/external) | `07-Reference/Vendor Documentation/` | File Router |

**Post-routing action:** "This file may trigger operational updates. Process through PPM Agent?"

**Raw archive pattern:** 06-Emails/ stores raw source material (forwarded emails, Teams message exports, QA status PDFs) as a reference archive — the same pattern as 05-Transcripts/ for meeting recordings. Summary tracking and lifecycle management happens in 04-PMO-Operations/ via the Communications Tracker (MSG-## entries). When processing content from 06-Emails/, extract actionable items into the appropriate tracker — do not treat raw files as the tracking mechanism.

**Jira export routing note:** Project plan exports from Jira route to `01-Governance/` per Folder Routing Guidelines — route by content function, not file format. Only test-related Jira exports (test case data) route to `03-Testing/Jira Export/`.

**Training routing note:** Training material authorship determines routing: project-authored → `02-Design/Training/`, vendor/external → `07-Reference/Vendor Documentation/`. File Router determines authorship by content analysis.

---

## Cross-Project Awareness

When processing artifacts for one project, flag references to other projects:

```
⚠️ CROSS-PROJECT: This transcript references [Other Project Name].
[Specific finding]. Check [Other Project]/PROJECT.md for impact.
```

This ensures timeline conflicts, shared stakeholder overload, and system dependencies are visible across projects.

---

## PROJECT.md Maintenance (Drift Detection)

Monitor PROJECT.md for contradictions with observed evidence. When detected, flag with evidence and propose specific edit:

```
🚩 DRIFT DETECTED:
PROJECT.md states: phase = "Testing" (line 12)
Evidence: AM Testing transcript 2026-03-17 states "UAT closes Friday; cutover planning starts Monday"
Proposed edit: phase = "Testing (cutover prep starting)" or phase = "Hypercare"
Affected: Comms tone, RAID escalation, Tracker cadence
```

Monitor for:
- Phase change (Testing → Hypercare, Hypercare → Closed)
- Date change (go-live slip, milestone delay)
- People change (lead departure, stakeholder change)
- Scope change (Phase 2 deferred, optional features cut)

---

## Integration Architecture

| Source | Access | Auto-Pull | Primary Use | Refresh |
|--------|--------|-----------|------------|---------|
| **Jira** | MCP Connector | Yes | Sprint data, ticket status, backlog health, test exports | Daily (post-standup) |
| **Confluence** | MCP Connector | Yes | FDD versions, RAID/Decision logs, process flows | On-drift-detect or weekly |
| **Google Drive** | MCP Connector | Yes | Sembly transcripts, shared docs | Daily (9am check) |
| **Smartsheet** | Manual export | No | Waterfall milestone tracking, gate approvals | Weekly (Friday) |
| **Email / Teams** | User-provided digest | No | Comms tracking, leadership notes | As-provided |

**Local copy principle:** Workspace maintains local copies of all artifacts. MCP refreshes cloud source; discrepancies flagged in drift detection. Truth lives locally until sync completes.

---

## Connector Configuration (per PROJECT.md)

Each project includes these connector settings in PROJECT.md. Do NOT assume defaults; read the project's context file first.

```yaml
jira_project_key: "[PROJECT_KEY]"                    # Required for Jira MCP
jira_query_scope: "Sprint >= 5"            # JQL filter for backlog queries
confluence_space: "[PROJECT_KEY]-Impl"               # Space key
confluence_page_ids:                       # FDD, RAID, processes
  - "123456"    # RAID Log
  - "123457"    # FDD Index
  - "123458"    # Process Flows
gdrive_folder: "1aB2cD3eF4gH5i..."        # Google Drive folder ID for transcripts
spm_comanaged: false                       # True if Smartsheet + SPM bridge active
spm_sharepoint_folder: null                # SharePoint path if spm_comanaged=true
spm_smartsheet_id: null                    # Smartsheet grid ID if spm_comanaged=true
```

---

## Status Theater Prevention

**Rejection patterns** — Do NOT output these:

| Pattern | Why | Alternative |
|---------|-----|-------------|
| "Project is on track" | No evidence. | "3 blockers in mitigation: FDD approval (Day 2), test environment setup (Day 3), training schedule (Action: Maria by Wed). Velocity 42 pts this sprint, 38 baseline — +1 buffer." |
| "UAT status: green" | Vague. | "UAT passed 87/92 test cases. Failures: 2 environment-related (blocked on infra team), 3 data-related (blocked on data steward). Retest Wed pm." |
| "Cutover planning on schedule" | For whom? | "Cutover scheduled Friday March 22. Readiness: training 85% complete (Action: finish by Wed). Parallel run docs approved. Rollback plan in review (Action: Tech lead by Thu)." |

Always ground status in **specific blockers, actions, owners, dates** (with day-of-week).

---

## Glossary of Terms

| Term | Definition |
|------|-----------|
| **Carry-forward** | Items remaining in Daily Status Log from prior cycle (blockers, decisions, retest queue) |
| **Drift** | Evidence contradicts stated project state (phase, date, scope, people) |
| **Jira test export** | Jira export of test-case data; shows test case status |
| **MSG-##** | Communication entry ID (e.g., MSG-047) |
| **MTG-##** | Meeting entry ID (e.g., MTG-012) |
| **SPM Bridge** | Dual-track (Agile + Waterfall) framing for comanaged projects |
| **TR-###** | Transcript register entry ID (e.g., TR-034) |
| **Document Tier 1–4** | File update governance (Stakeholder, Operational, New Files, Context) |

---

## Quick Reference: When to Route & Tag

| Situation | Route To | Tag | Owner |
|-----------|----------|-----|-------|
| "Backlog looks healthy but sprint has 3 new blockers" | Delivery Engine | `[DELIVERY]` | DE prioritizes |
| "FDD approval is 2 days late" | PPM Agent + Technical Analyst | `[TECHNICAL]` | TA reviews FDD; PPM escalates |
| "Stakeholders confused about training scope" | Comms Writer | `[COMMS]` | Comms produces stakeholder digest |
| "Hypercare metrics show low adoption" | Change Management | `[CHANGE]` | CM proposes readiness plan |
| "New legal requirement affects go-live date" | PPM Agent | `[DECISION]` + `[RISK]` | PPM escalates; RAID added |
| "Process flow has gap vs. FDD" | Process Designer | `[PROCESS]` | PD traces requirements |

---

## Last Updated

**2026-03-19** — update. Skills Section updated to 16 production skills (added release-planner, release-executor). Governance files migrated to `Projects/_governance/` . Drift detection Step 0 added to Daily Processing Cycle with 6 checks including governance file presence. All governance file path references updated. Lifecycle management requirement added to RELEASE_PROTOCOL.md . Governance File Map added to CLAUDE.md .
