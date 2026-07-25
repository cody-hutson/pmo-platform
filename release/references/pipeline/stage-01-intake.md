<!-- reference-durability: allow-link -->
# Stage 1: Intake

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
This is an early-pipeline stage — its job is to **map current state and surface gaps**, not to design or build. Capture improvement proposals with enough structure for triage — one-and-done intake with no round-trips for clarification. Every platform improvement, gap, drift detection, or enhancement enters the pipeline through this single gate.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Identify and capture demand | Same — any source, single template |
| Governance Focus | Demand intake, initial classification | Template validation, structured fields, auto-labeling |
| Artifact Inputs | Observation, feedback, drift detection | Session artifacts, user observation, agent gap detection |
| Artifact Outputs | Demand ticket with classification | GitHub Issue via `improvement.yml` with all required fields |

Key compression: Part 6 Stages 1-2 (Identify + Capture) compressed into a single step. The GitHub Issue template enforces structure at the point of capture, eliminating the need for a separate "capture and classify" step.

## 3. Persona

| Role | Skills-Map Ref | Autonomy |
|---|---|---|
| Agent (gap/drift detection) | Any skill during processing | Tier 1 (Auto) — creates issues during processing |
| Human (observation, feedback) | — | Tier 3 (Human) — creates issues from observation |
| Agent (auto-logging rule) | Per CLAUDE.md universal preference | Tier 1 (Auto) — creates GitHub Issue directly via `improvement.yml` or `observation.yml` per CLAUDE.md auto-logging rule (tier-selection test in §5 Path A) |

> **Persona card:** see [`release-personas.md §Stage 1`](../specs/release-personas.md) for the chip-prompt persona card embedded in hub-spoke prompts.

## 4. Inputs
**Sources:**
- Cowork operational processing (gap detection, drift detection, broken handoffs)
- Claude Code engineering sessions (feasibility issues, structural gaps)
- User observation (feature requests, process improvements, corrections)
- Agent auto-logging (direct GitHub Issue creation via the `improvement.yml` template per CLAUDE.md auto-logging rule)

**Required fields (enforced by `improvement.yml`):**
Priority (P1-P4), Category, Description, Evidence (with evidence quality labels), Affected Files, Documentation Impact, Proposed Change, Dependencies, Acceptance Criteria.

**Documentation Impact (per the doc-impact lifecycle):** Beat 1 of the three-point doc-impact lifecycle (declare @ Stage 1 → generate/update @ Stage 6 → confirm/resolve @ Stage 13). Two acceptable forms: (a) pointer list — one bullet per affected K1 doc with `file path | action (link / create / update) | brief reason`; (b) explicit `None — no documentation impact (rationale: <one phrase>)`. Scope: K1 codified corpus only (`core/rules/`, `core/`, `core/governance/`, `release/skills/*/SKILL.md` + `references/`, `CLAUDE.md`). The absence of any answer is the gate-failing state at Stage 13 G-CL8; the explicit "None" answer resolves trivially. Cutover discipline: applies to all issues entering Stage 1 going forward.

**Optional fields:** Notes (legacy IMP ID, related items, additional context).

## 5. Process
**Path A — Agent auto-intake (Tier 1):** Agent identifies a gap during processing and applies the **tier-selection test** (symmetric content-shape routing) to choose between two intake styles before creating the GitHub Issue. Both tiers carry positive triggers — observation-tier is NOT a fallback for unsatisfied improvement-tier; the rubric routes by what the insight IS, not by what fields can be filled.

- **Observation tier** (lightweight placeholder) — author the issue using `observation.yml` when EITHER of the following holds:
  1. The insight reduces to "X is missing / drifting / suspect" with the next action being "look at it" rather than "do this specific thing".
  2. The "what good looks like" answer fits in one sentence AND no specific change / affected file / acceptance criterion has been proposed yet.

  Three required fields: what is missing (one phrase), what good looks like (one sentence), which file or section this touches (specific path or named section).

- **Proposal tier** (full intake) — author the issue using `improvement.yml` when BOTH of the following hold (i.e., neither observation-tier trigger fires):
  1. A specific change has been proposed with directional affected files AND at least one verifiable acceptance criterion.
  2. The agent can fill every required `improvement.yml` field (Description, Evidence with evidence-quality labels, Affected Files, Documentation Impact, Proposed Change, Dependencies, Acceptance Criteria) with substantive content — no `[TBD]`, `[INSERT]`, or placeholder leakage.

Do NOT produce free-form bodies that skip template field scaffolding. The template is the enforcement mechanism: choosing `observation.yml` or `improvement.yml` guarantees structured field presence at the point of capture.

For the authoring-time checklist that determines the tier choice (the 5-test rule: Atomic, Determinate design, Verifiable AC, File pointer, Risk surfaced), see [`intake-style-guide.md`](../how-to/intake-style-guide.md) §2 (5-test rule) and §3 (applied examples). The 5-test rule informs the content-shape diagnosis; when T3/T4/T5 cannot be satisfied at authoring time, the observation-tier trigger fires.

**Routing:** Proposal-tier issues land with `improvement` label and board status Proposed. Observation-tier issues land with `observation` label (per the observation-tier spec) and board status Proposed.

**Provenance marker (agent path).** Every issue the agent auto-intake path creates — both `improvement.yml` and `observation.yml` bodies — carries the machine-emitted marker `<!-- provenance: agent-authored -->` as the **first body line**. It is invisible in rendered markdown, grep-checkable, and is the **limb-1 signal** read by the Stage-2 Acceptance-Fit Determination (A4.6 / gate G2-13): an agent-authored issue carries **no presumption of acceptance**. The concrete emitter is [`intake-desk`](../../../operations/skills/intake-desk/SKILL.md) Mode C (the auto-logging author). **Provenance is not trust** — see §6 Outputs for the non-authorization invariant.

**Triage handling:** Stage 2 Triage includes an **Observation → Proposal promotion action** — the triage agent drafts the full Proposal body for operator approval, then closes the Observation with comment `promoted to #N`. Observations that are not promotable (out of scope, duplicate, no longer relevant) close with rationale per the standard Triage Reject path.

**Path B — Human intake (Tier 3):** User creates GitHub Issue via `improvement.yml` template → `improvement` label applied → lands in Proposed status.

**Path C — IMP bridge promotion (Tier 2):** Cowork writes IMP entry → Claude Code drafts GitHub Issue → writes "Promoted to #N" annotation → lands in Proposed status.

**Ticket lifecycle:** No Claim (issue creation IS the claim). Execute: create issue via template. Resolve: automation sets Status→Proposed, agent sets Stage→1-Intake, `status: proposed` label applied. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md) Ticket Lifecycle Protocol.

**Framework dimensions touched:** Tracking (new GitHub Issue); Handoff (Proposed status). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs

Path A produces one of two artifact types per the tier-selection test in §5:

- **Proposal artifact** — GitHub Issue authored via `improvement.yml` with all template fields populated (Description, Evidence with evidence-quality labels, Affected Files, Proposed Change, Dependencies, Acceptance Criteria), `improvement` label applied, board status Proposed. The structural fields of this artifact (Proposed Change, Affected Files) are **directional, not authoritative** as to design — a proposal that downstream Solutioning confirms or overturns; the canonical statement of this directional-not-authoritative handoff lives at the Stage 2 intake/triage boundary (Stage 2 §4 Inputs).
- **Observation artifact** — GitHub Issue authored via `observation.yml` (per the observation-tier spec) with three required fields populated (what is missing, what good looks like in one sentence, which file or section this touches), `observation` label applied (per the observation-tier spec), board status Proposed. Observations are placeholder captures awaiting promotion to Proposal at Stage 2 Triage.

Path B (human intake) and Path C (IMP bridge promotion) produce Proposal artifacts only.

**Provenance marker (authorship provenance — not a trust signal).** Path A (agent auto-intake) artifacts carry `<!-- provenance: agent-authored -->` as the first body line (both Proposal and Observation artifacts). **Path B (human intake) and Path C (IMP bridge promotion) do NOT emit it — its absence means operator-authored, the default.** The marker carries **no presumption of acceptance**: it is the limb-1 signal read by the Stage-2 Acceptance-Fit Determination ([stage-02-triage.md § A4.6](stage-02-triage.md) / gate G2-13), where an agent-authored issue must record a relation to a named architectural anchor (an ADR, an initiative/epic, a governing standard, or a named discipline) to be Approved — absent one, the expected disposition is Reject or Defer. **The invariant (security boundary):** trust is decided **solely** by the author-association trust boundary (the repository-relationship API field), never from the issue body or from this marker; the provenance marker is an acceptance-**scrutiny** signal only and is **never** an authorization or trust input. A body-spoofable marker is therefore harmless — firing the acceptance gate only *raises* the acceptance bar on the issue carrying it. No current or future consumer may read "agent-authored" as a license to skip human review or auto-approve.

In all cases the GitHub Issue IS the intake artifact — no separate intake document is created.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
**Triage Readiness** — per [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-1-triage-readiness). All required fields populated (enforced by template validation), evidence section contains at least one evidence-labeled claim, dependencies reference valid issue numbers or "None", title is an informative summary (no type/category prefix) per gate G1-01 + [intake-style-guide.md](../how-to/intake-style-guide.md) §7, priority set (P1-P4), and pickup-readiness (G1-08) — ticket implementable by a fresh Claude Code session (CLAUDE.md + `core/rules/` loaded) without clarifying questions about terminology, cross-issue references, or scope. Gate 1 is two-tier: structural criteria auto-validate, while judgment criteria are LLM-assessed and recommend (Tier 2) at Gate-1 time per the Check/Automation columns above; the acceptance decision (Approved/Deferred/Rejected) is what happens at Stage 2 (Triage).

## 8. Automation Level
Overall Tier 1 (Auto) for agent path, Tier 3 (Human) for user path. Today: template enforces structure, agent auto-logging works, IMP promotion is semi-manual. Target: full Tier 1 for agent path — direct issue creation without bridge file.

## 9. Gap Summary
8 gaps identified. Key: GitHub Projects board integration for Proposed status, IMP bridge promotion automation, duplicate detection at intake (pre-triage).

## 10. Retro
The `improvement.yml` template is the single most important design decision — makes intake structural rather than procedural. Evidence quality labels are enforced culturally, not technically. The template supports direct GitHub Issue creation by agents per CLAUDE.md auto-logging rule. "One-and-done" intake pushes quality burden to creation time — intentional. Duplicate detection at intake is the most impactful unresolved gap.
