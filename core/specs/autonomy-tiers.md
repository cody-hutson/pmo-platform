---
title: Autonomy Tier Classification
purpose: Canonical classification of agent action autonomy from full-human-control through autonomous execution; consumed by SKILL.md frontmatter, governance approval gates, and downstream PreToolUse hooks.
applies_to: All PMO skills, future SKILL.md `autonomy_tier:` frontmatter, CLAUDE.md autonomy section, `engagement-charter.md`, `autonomous-execution-model.md`, future PreToolUse hooks.
parallel_to: reversibility-protocol.md (orthogonal — autonomy = WHO acts; reversibility = HOW MUCH ceremony per act); composes per `decision-discipline.md` § 2 cross-framework pattern.
disambiguates_from: Document Tier (CLAUDE.md File Management Protocol), Skill Tier (OPERATIONS.md skill classification), Automation Tier (`pipeline/` + 10 schemas) — see § Tier Disambiguation Table.
source: "autonomy-tiers-and-self-repair; operator D-3 decision 2026-05-04 (explicit prefixed terminology, Tier 0-3 numbering manual→autonomous)."
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# Autonomy Tier Classification

## Purpose

This document establishes the canonical Autonomy Tier classification — a 4-tier framework (Tier 0 Manual through Tier 3 Autonomous) classifying agent action autonomy by per-instance authorization signature. Consumed by SKILL.md frontmatter (future outbound), governance approval gates, PreToolUse hooks (TBD outbound), and audit gates (`pmo-qa-auditor` successor). Pairs orthogonally with `reversibility-protocol.md` (autonomy = WHO acts under what authorization; reversibility = HOW MUCH ceremony per act). Disambiguated from three other tier conventions (Document Tier, Skill Tier, Automation Tier) per § Tier Disambiguation Table.

## Definition

Autonomy Tier classifies an agent action by the operator-engagement signature required to execute it. Four named tiers anchor the gradient from full operator control (Tier 0 Manual) through standing-policy authorization (Tier 3 Autonomous), with Tier 1 Recommend and Tier 2 Bounded Auto as intermediate surfaces. The classification is per-action, not per-skill: a single skill may produce actions at multiple tiers (e.g., comms-writer drafts a Tier 1 stakeholder digest AND auto-writes a Tier 2 communications-tracker entry). Tier assignment uses observable indicators — the authorization mechanism, the scope boundary, the audit-trail presence — never subjective categorization. Tier 0 is permanent for the irreducible-human-tasks set (§ Irreducible Human Tasks) regardless of approval state.

## Tier 0 — Manual (full human control)

**Criterion (when this tier applies):** Action requires explicit per-instance operator authorization through the chat interface. Agent can analyze, recommend, draft — but cannot execute. The operator decides AND acts (or explicitly authorizes the agent to act on this specific instance).

**Observable indicators:**
- Action is irreversible or hard-to-reverse (per `reversibility-protocol.md` IRREVERSIBLE/EXPENSIVE).
- Action affects a stakeholder cohort beyond the operator.
- Action modifies governance state (`CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md`, `PORTFOLIO.md`, `SESSION_STATE.md`, SKILL.md).
- Action is on the CLAUDE.md Prohibited Actions list (financial, account creation, security permissions).

**Examples (drawn from current skill behavior):**
- Stage 9 Plan Review GO/NO-GO — operator-only per `pipeline/stage-09-plan-review.md` ("hub presents decision to operator, no spoke launched").
- Tier 1 (Stakeholder-Facing) document write per CLAUDE.md File Management Protocol — RAID Log, FDDs, Project Plan; agent drafts, operator approves before write.

**Boundary conditions:**
- Elevates from Tier 1 when the recommendation surface is *itself* destructive (e.g., approving a `git revert` on a published tag; draft alone has stakeholder impact).
- Descends to Tier 1 when an analogous action exists with sub-instance approval (e.g., a per-section approval mode).

**Process weight:** Heavy. Per-instance operator authorization in chat, no batch-approval, no inferred-consent shortcut.

## Tier 1 — Recommend (agent drafts, human approves before action)

**Criterion (when this tier applies):** Agent produces a proposed action (draft, plan, recommendation) and pauses before execution. Operator reviews and explicitly approves. Approval is per-artifact, not per-class — but a single approval authorizes the *whole drafted package*, not paragraph-by-paragraph.

**Observable indicators:**
- Output is a draft awaiting review (file in `08-Generated/` staging, comment posted for review, plan presented).
- Action is reversible-but-stakeholder-visible (per `reversibility-protocol.md` MODERATE).
- Action requires human judgment the agent cannot encode (style, tone, audience-fit).

**Examples (drawn from current skill behavior):**
- comms-writer drafts a stakeholder communication and stages it for operator review before send (per `OPERATIONS.md` Tier 1 stakeholder-facing protocol).
- tracker-manager produces a consolidated change summary for Tier 1 (RAID Log) updates and waits for explicit user approval before writing (per `tracker-manager/SKILL.md` C4 cascade rule).
- file-router LOW/MEDIUM-confidence routing — proposes route with reasoning, awaits user confirm/correct (per `file-router/SKILL.md` confidence-tier table).

**Boundary conditions:**
- Elevates to Tier 0 when the draft surface itself has stakeholder impact (e.g., draft posted to a shared channel before review).
- Descends to Tier 2 when the action is within a previously-declared `cascade_scope` (Tier 2 trackers per OPERATIONS.md C7 allowlist).

**Process weight:** Light+. Agent surfaces key assumption (≤1 sentence) per the MODERATE pattern in `reversibility-protocol.md`; awaits operator confirm.

## Tier 2 — Bounded Auto (agent acts within pre-authorized scope)

**Criterion (when this tier applies):** Agent executes without per-instance approval, but only within an explicitly-declared scope (cascade_scope, allowlist, confidence threshold, or directory boundary). Operator has prior visibility into the scope; sees outputs post-hoc but does not gate per-action. Action outside scope automatically descends to Tier 1.

**Observable indicators:**
- Scope is named in a manifest, allowlist, or schema (e.g., `cascade_scope` field, `.claude/script-execution-allowlist.txt`, `08-Generated/` directory).
- Action is reversible (per `reversibility-protocol.md` CHEAP/MODERATE).
- Audit trail is automatic (block-log, deploy log, commit history).

**Examples (drawn from current skill behavior):**
- tracker-manager Tier 2 tracker writes within `cascade_scope` — auto-writes operational trackers without per-update approval (per OPERATIONS.md C4 + `tracker-manager/SKILL.md` Allowlist trigger pair).
- artifact-generator stages all output in `08-Generated/` (auto-write per CLAUDE.md File Management Protocol § 08-Generated/), promoted to target folder only on operator approval.
- file-router auto-routes HIGH-confidence (≥90%) files to staging-class folders (`05-Transcripts/`, `06-Emails/`, `08-Generated/`); cross-folder routing into `01-Governance/` etc. drops to Tier 1.

**Boundary conditions:**
- Elevates to Tier 1 when the action target is outside declared scope (e.g., tracker-manager attempting a Tier 1 RAID write — descends to approval gate).
- Descends to Tier 3 when the scope is unbounded by policy and only bounded by safety hooks (e.g., post-merge git operations under `.claude/hooks/` enforcement).

**Process weight:** Substantive at scope-declaration time (operator authorizes the scope once); minimal per-action.

## Tier 3 — Autonomous (agent acts under standing authorization)

**Criterion (when this tier applies):** Agent executes without per-instance or per-scope approval. Authorization is *standing* — encoded in the framework (release plan approval, pipeline stage definition, governance protocol). Operator gates only at framework-level checkpoints (Stage 9 Plan Review, Stage 12 Execute authorization), not per-action within the framework.

**Observable indicators:**
- Authorization is policy-level (release plan approved at Stage 4; pipeline stage definition; governance protocol clause).
- Action is conditional on observable preconditions (dependency met, gate passed, plan committed) — agent verifies precondition before acting.
- Action has automatic audit trail (commit, log, Issue auto-close on PR merge).

**Examples (drawn from current skill behavior):**
- Stage 6 Engineering executing per approved release plan — agent commits file changes per the change matrix without per-commit approval, per the governance-theater pattern ("'Approved' authorizes whole-plan execution").
- Stage 12 Execute deploying skills via `./deploy.sh --deploy` after operator authorization at Stage 9/12 gate — auto-executes file copy, verification, RELEASE_LOG append.
- CLAUDE.md auto-logging rule — agent identifies a gap during processing and creates a GitHub Issue without prompting (per CLAUDE.md "Auto-logging rule").
- DT iteration loop Tier 1 findings routing via `fix(dt):` commits without operator routing approval (per the release-orchestration-autonomy discipline).

**Boundary conditions:**
- Elevates to Tier 1 when a precondition fails (dependency not met, contention discovered, scope-lock challenged) — agent surfaces a Decision Briefing per `decision-discipline.md`.
- Elevates to Tier 0 when the action would modify the standing authorization itself (e.g., release plan amendment requires re-approval).

**Process weight:** Minimal per-action. All ceremony was front-loaded at policy/plan approval time.

## Boundary Tests

When two tiers are plausible, apply these tests in order:

1. **Standing-authorization test** — Is the action covered by an approved plan, framework clause, or allowlist? If yes → Tier 3 (within that scope) or Tier 2 (if scope is named but narrower than full policy). If no → Tier 1 or Tier 0.
2. **Stakeholder-visibility test** — Does the action affect anyone other than the operator? If yes and reversible → Tier 1; if yes and irreversible → Tier 0.
3. **Reversibility-pair test** — Pair with the action's reversibility tier per `reversibility-protocol.md`. IRREVERSIBLE actions cannot be Tier 3 even under standing authorization (Stage 12 Execute is Tier 3 *after* Stage 9 GO, but Stage 9 GO itself is Tier 0 — the gate is the operator's per-instance act).
4. **Governance-modification test** — Does the action modify a governance file (CLAUDE.md, OPERATIONS.md, SKILL.md, RELEASE_PROTOCOL.md)? If yes → Tier 0 unless the change is part of an approved release plan with explicit governance scope (then Tier 3 within plan; never Tier 2 — governance never auto-cascades per OPERATIONS.md cascade rule).

## Tier Disambiguation Table

Per operator D-3 decision 2026-05-04: explicit prefixed terminology throughout. The platform has FOUR distinct tier conventions; never use bare "Tier N" without the disambiguating prefix.

| Tier name | Range | Surface | Concept | Example |
|---|---|---|---|---|
| **Document Tier** | 1-4 | `CLAUDE.md` § File Management Protocol | document approval level (Stakeholder / Operational / New / Context) | Tier 1 = RAID Log; Tier 2 = Daily Status Log; Tier 3 = uploaded transcript; Tier 4 = PROJECT.md |
| **Skill Tier** | 1-2 | `OPERATIONS.md` § Skill Tiers | skill role classification (PPM/Comms/Delivery = Tier 1; Technical/Process/Change = Tier 2) | Tier 1 = ppm-agent, comms-writer, delivery-engine; Tier 2 = pmo-technical-analyst, pmo-process-designer |
| **Automation Tier** | 1-3 | `pipeline/` + 10 schema docs (gate-evaluation-spec.md, gate-criteria-spec.md, stage-io-contracts.md, etc.) | per-stage execution model (Tier 1 Auto, Tier 2 Recommend, Tier 3 Human-only) | Stage 1 Intake = Tier 1; Stage 4 Planning = Tier 2; Stage 9 Plan Review = Tier 3 |
| **Autonomy Tier** | 0-3 | `core/specs/autonomy-tiers.md` (this file) | agent action autonomy (Tier 0 Manual → Tier 3 Autonomous) | Tier 0 = Stage 9 GO; Tier 1 = comms-writer draft; Tier 2 = tracker-manager scoped write; Tier 3 = Stage 6 Engineering per plan |

> **⚠ Critical inversion warning:** Automation Tier and Autonomy Tier use *inverted* numerical orderings. Automation Tier 1 = highest automation (Auto); Autonomy Tier 3 = highest automation (Autonomous). When citing tiers across files, always use the prefixed terminology (e.g., "Automation Tier 1" or "Autonomy Tier 3") — never bare "Tier 1" / "Tier 3" — because the numeric value alone is ambiguous between the two conventions.

**Implementation note:** every existing or new file referencing any of the four conventions MUST use the prefixed terminology. Cross-file consistency is enforced at PR review (Stage 9) and downstream by grep-based audit gates (deferred to a future audit milestone — out of scope for this release).

## Irreducible Human Tasks

The following actions are **never delegable to agents**, regardless of standing authorization, plan approval, or framework clause. They are permanent Tier 0 surfaces.

1. **Financial transactions** — purchases, transfers, or any movement of money, including saved-payment access.
   - *Why irreducible:* Direct fiduciary risk; no recoverable audit trail for unauthorized money movement.
   - *Source rule:* `CLAUDE.md` § Prohibited Actions; `<action_types>` § prohibited_actions.

2. **Account creation** — creating new user / system / service accounts on behalf of the operator.
   - *Why irreducible:* Account ownership and credential custody are non-delegable identity assertions.
   - *Source rule:* `CLAUDE.md` § Prohibited Actions; `<user_privacy>` § SENSITIVE INFORMATION HANDLING.

3. **Security-permission modification** — sharing controls, access grants, document publication, password-based authentication, modifying user access settings.
   - *Why irreducible:* Permission changes have stakeholder-visible blast radius beyond the operator.
   - *Source rule:* `CLAUDE.md` § Prohibited Actions.

4. **Stage 9 Plan Review GO/NO-GO** — release-readiness sign-off before merge.
   - *Why irreducible:* Per pipeline/stage-09-plan-review.md, "hub presents decision to operator, no spoke launched." The gate is the operator's per-instance act.
   - *Source rule:* `release/references/pipeline/stage-09-plan-review.md`; `release/references/specs/release-personas.md` § Stage 9.

5. **Stage 12 Execute authorization** — operator authorizes deployment at the gate; agent executes only post-authorization.
   - *Why irreducible:* Stage 12 deploys to production; rollback EXPENSIVE per reversibility protocol. Authorization is per-instance.
   - *Source rule:* `.claude/rules/release-process.md` § Stage 12; `release/references/pipeline/stage-12-execute.md`.

6. **Governance-file modification without approval** — CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, SKILL.md, etc. require Issue + plan + approval.
   - *Why irreducible:* Per CLAUDE.md "No ungoverned changes." Self-generated improvements log only; never auto-fix. Governance never auto-cascades (OPERATIONS.md Cascade rule C5).
   - *Source rule:* `CLAUDE.md` § Quality Standards § Guardrails ("No ungoverned changes"); `core/governance/OPERATIONS.md` § Skill Chaining Protocol C5.

7. **Cross-domain bridge writes** — Claude Code never writes to `projects/`; Cowork never writes to `pmo-platform/`.
   - *Why irreducible:* Layer separation between Engineering (git-tracked) and Operations (Cowork-owned) is foundational; cross-writes violate layer integrity.
   - *Source rule:* `.claude/rules/operations-bridge.md` § Rules for Claude Code (rules 1, 2, 4).

8. **Destructive operations outside `${HOME}/Claude/`** — `rm`/`rmdir`/`unlink`/`trash` targets resolved outside the workspace root.
   - *Why irreducible:* Per `.claude/hooks/block-rm-prefer-trash.sh` BLOCK-TRASH-001 / BLOCK-TRASH-003: blocks at hook level; permanent. No bypass mechanism.
   - *Source rule:* `.claude/rules/bypass-mode-readiness.md` § block-rm-prefer-trash.sh BLOCK-TRASH-001/003.

## Failure modes

Failure modes follow the `failure-mode-standard.md` 5-field template (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) with category tag (TRIG / INPUT / PROC / OUT / HAND).

**FM-1 — Tier collapse (treating Tier 0 work as Tier 3)** — Category: PROC

- *Signature:* Agent executes an action that should require per-instance operator approval, claiming standing authorization that does not actually cover the specific action.
- *Conditional:* Do NOT treat a release plan approval as authorization for governance-file edits outside the plan's declared scope, because plan approval is bounded by the plan's change matrix, not by the agent's interpretation of "what would have been approved."
- *Root cause:* Agent over-extends the scope of a prior approval; misreads "Stage 6 Engineering authorized" as "any file edit authorized."
- *Mitigation:* The Standing-authorization test (Boundary Test 1) requires the action to be covered by a *named* clause/plan/allowlist. Plus governance-modification test (Boundary Test 4) requires explicit governance scope in the approved plan.
- *Principal-vs-junior response:* Junior — proceeds, claims "approved as part of release"; Principal — confirms specific action is in change matrix; if not, flags scope question to operator before proceeding.

**FM-2 — Tier inflation / governance theater (treating Tier 3 work as Tier 1)** — Category: HAND

- *Signature:* Agent asks operator for approval on an action already authorized by the framework — re-opening per-step approval inside an approved plan.
- *Conditional:* Do NOT solicit per-action approval for actions inside an approved release plan's scope, because the operator approved at the plan level and per-step solicitation creates approval fatigue and pipeline stalls.
- *Root cause:* Agent reaches for a generic "consensus-seeking" heuristic without localizing to the framework's standing-authorization clauses; conflates "safe to ask" with "safe to act per framework."
- *Mitigation:* Per the governance-theater and release-orchestration-autonomy disciplines. Apply Boundary Test 1 (Standing-authorization test) — if the action is covered by a named plan/clause/allowlist, classify as Tier 3 and execute; do not re-prompt.
- *Principal-vs-junior response:* Junior — pauses for "are you sure?" prompt; Principal — names the framework rule (e.g., "Per release-process.md DT↔Engineering Loop Tier 1 protocol, executing fix(dt): commit") and proceeds.

**FM-3 — Self-elevation (agent moves itself from Tier 0/1 to Tier 3 mid-task)** — Category: TRIG

- *Signature:* Agent silently widens scope from the originally-tiered action to an adjacent action that should have been tiered separately.
- *Conditional:* Do NOT extend a Tier 1 draft action into a Tier 3 auto-write of an adjacent file, because the operator approved the draft surface, not the broader context the agent later determined was "obviously also needed."
- *Root cause:* "While I'm here" pattern — agent reads a Stage 6 Engineering authorization as authorization to refactor adjacent code; or a tracker-manager Tier 2 cascade as authorization to write to a Tier 1 target.
- *Mitigation:* Boundary tests reapply at each new file/action, not just at the start. OPERATIONS.md cascade rule C6 ("Approval scope") — Tier 1 approval authorizes only the artifact's declared cascade_scope.
- *Principal-vs-junior response:* Junior — bundles "obvious" adjacent fix into the same operation; Principal — flags adjacent fix as a separate observation (`mcp__ccd_session__spawn_task` chip or new Issue) and continues with original tiered scope.

**FM-4 — Boundary leakage (Tier 2 action outside declared scope)** — Category: PROC

- *Signature:* Agent invokes a Tier 2 cascade write on a target outside the declared `cascade_scope` field of the upstream Tier 1 artifact.
- *Conditional:* Do NOT execute a tracker-manager `TRACKER_UPDATE` block on a target tracker that wasn't named in the originating PPM Agent artifact's `cascade_scope`, because cascade_scope is the explicit boundary; un-listed targets require approval gate.
- *Root cause:* Agent treats "Tier 2 = auto-write" as a global classification rather than a scope-bounded one; misses that Tier 2 authority is conditional on the target being inside the cascade_scope.
- *Mitigation:* OPERATIONS.md C6 (Approval scope) + C7 (Allowlist). tracker-manager validates target against cascade_scope before write; out-of-scope targets are returned to Tier 1 (approval gate).
- *Principal-vs-junior response:* Junior — generalizes "operational tracker = auto-write"; Principal — checks cascade_scope per write; if absent, descends to Tier 1.

## Composition with reversibility-protocol.md

This section establishes orthogonality with `reversibility-protocol.md` to prevent overlap-confusion (mirroring the `decision-discipline.md` § 2 cross-framework composition pattern).

| Dimension | Autonomy Tier | Reversibility Tier |
|---|---|---|
| **Question answered** | Who acts (operator vs agent under what authorization)? | If wrong, how expensive is undoing it? |
| **Granularity** | Per-action (does this action need approval?) | Per-decision (what process weight scales to undo cost?) |
| **Scale** | 0-3 (Manual → Autonomous) | 4 named (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) |
| **Pairing rule** | Tier 0/1 actions can be any reversibility tier; Tier 3 actions cannot be IRREVERSIBLE without standing-authorization sign-off | (mirror) — IRREVERSIBLE decisions require explicit per-instance sign-off regardless of standing authorization |
| **Audit gate** | Future PreToolUse hook + future SKILL.md frontmatter check | pmo-qa-auditor G4 (Evidence Quality) |

**Worked example (Stage 12 Execute):** Autonomy Tier 3 (autonomous post Stage 9 GO) + Reversibility EXPENSIVE (rollback requires operator authorization + RELEASE_LOG entry) — composes cleanly: the autonomy is bounded by the GO gate, not by per-step approval; the reversibility weight is consumed at Stage 9 (where operator validates rollback strategy) not at Stage 12 (where agent executes).

## Application to Skills

### How a skill declares its autonomy tier

SKILL.md frontmatter SHOULD include `autonomy_tier: <tier>` once the frontmatter enrichment lands. Until then, the framework operates on consumer-side classification — agents and gates classify per-action against the criteria above. (Adding the frontmatter field is an outbound handoff to a future release.)

### Multi-mode skills with per-mode tiers

Skills with multiple modes (e.g., pmo-qa-auditor's Modes 1-4, comms-writer's draft vs send) MAY have different tiers per mode. Declare per-mode in the mode-definition section; surface in the skill output by labeling the mode + tier inline.

### Skill tier vs action tier

A Tier 1 skill (per OPERATIONS.md skill classification — e.g., comms-writer) can produce Tier 0 actions (drafting an exec escalation), Tier 1 actions (drafting a stakeholder digest), or Tier 2 actions (auto-writing a Tier 2 communications tracker entry). The skill classification is about *skill role* (strategic vs technical); the autonomy tier is about *per-action authorization*. They do not collapse into each other.

## Consumers (Blast Radius)

### In-release consumers

| Consumer file | Reference type | Path |
|---|---|---|
| `CLAUDE.md` autonomy section | New section cites this file | `CLAUDE.md` (root) |
| `core/disciplines/autonomous-execution-model.md` | Distinguishes Cowork (per-step) from Claude Code (PR-gate); will cite tier semantics for "self-repair within Tier 3 scope" | NEW file in same release |
| `release/references/specs/stage-to-skill-mode-mapping.md` | "Automation level" column will reference Autonomy Tier values for cross-pipeline consistency | NEW file in same release |
| `core/specs/engagement-charter.md` | R1 dimension "Automation tier ↔ engagement hierarchy" | NEW file in same release (D-1: `reference/`) |

### Outbound consumers (soft handoff)

| Consumer | Target release | Reference type |
|---|---|---|
| Future SKILL.md `autonomy_tier:` frontmatter | TBD | Per-skill self-classification using this file's tier names |
| PreToolUse autonomy-ceiling hook (workspace-global) | v2.07 | RESOLVED — implemented as `block-autonomy-ceiling.sh` (C5), payload-triggered (NOT subagent-session-detection — that trigger is infeasible per `subagent-security-posture.md § 3 Mechanism 2`), reading `[automation].automation_level` as the ceiling. The irreducible Tier-0 floor is always-block LIVE for the payload-detectable classes (governance-file + cross-domain bridge writes); the ceiling check is mode-gated (warn-initial) with a permissive default. The subagent-only Tier-1/2/3 approval-evidence gating rows are Phase-2 deferred (they need a session/approval signal the payload lacks). Design source + supersession: `subagent-security-posture.md § 4` + `core/ADRs/ADR-031-autonomy-ceiling-unified-payload-triggered-hook.md` |
| `core/config/operator.toml.template` `[automation].automation_level` | v2.07 | Reads this file's Tier-0 vocabulary + § Irreducible Human Tasks as the ceiling's irreducible floor (`effective = min(automation_level, per-action max)`). Advisory/soft until the C5 PreToolUse autonomy-ceiling hook lands this release (warn-mode-initial per the hook-suite shakedown convention) and the operator flips it warn→enforce; once flipped, the hook hard-blocks only the payload-detectable Tier-0 classes (governance-file + cross-domain bridge paths), while financial / account-creation / security-permission / Stage 9 / Stage 12 stay operator-irreducible by convention |
| `platform-health-audit-framework.md` | TBD | Tier-distribution metrics (% of actions per tier across the platform) |
| pmo-qa-auditor (or successor audit gate) | TBD | Validates skills declare `autonomy_tier:` and that observed actions match declared tier |

**Cross-reference constraints:** This file MUST NOT introduce a runtime dependency on any consumer file (parent-of-children pattern). All listed consumers add references TO this file; this file references peers (`reversibility-protocol.md`, `decision-discipline.md`, `failure-mode-standard.md`, `OPERATIONS.md`, CLAUDE.md) but not its consumers.

## Cross-Reference

- [reversibility-protocol.md](reversibility-protocol.md) — orthogonal companion (reversibility = how-much-ceremony per act); see § Composition with reversibility-protocol.md
- [decision-discipline.md](../disciplines/decision-discipline.md) — § 2 cross-framework composition pattern; § 3 triage rules; § 4.1 observation log
- [failure-mode-standard.md](failure-mode-standard.md) — 5-field template + 5 category tags used in § Failure modes (FM-1..FM-4)
- [review-discipline-principles.md](../disciplines/review-discipline-principles.md) — review-class output discipline (parallel, no inheritance)
- [OPERATIONS.md](../governance/OPERATIONS.md) — Skill Tier classification (1-2) + cascade rules C1-C7
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) — File Management Protocol (Document Tier 1-4); Quality Standards (Reversibility discipline, No ungoverned changes); Prohibited Actions
- `release/references/pipeline/` — Automation Tier 1-3 convention (inverted from this file's Autonomy Tier — see § Tier Disambiguation Table)
