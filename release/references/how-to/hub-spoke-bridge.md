<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Hub-and-Spoke Release Bridge

An operational mechanism for executing the release process (`release/governance/release-process.md`) using Claude Code chat sessions. Substitutes for skills and automation that don't yet exist.

**What this is:** A tool to operate the pipeline manually with quality guardrails.
**What this is not:** A new release process. The 13-stage pipeline is the process.

---

## Framework Alignment

This document implements the [Execution Framework](../../../core/disciplines/execution-framework.md) as a specific tool for operator-driven release execution. The framework defines 5 execution dimensions; this tool implements them as follows:

| Dimension | How hub-spoke-bridge implements it |
|---|---|
| Work Breakdown | Release → per-issue sub-tasks per stage (Procedure 1 Scaffolding); commits on release branch |
| Assignment | Operator ([Role](../../../core/specs/terminology-glossary.md#term-role)) + Hub (Role, current session) + Spokes (Role, spawned sessions) each embodying a [Persona](../../../core/specs/terminology-glossary.md#term-persona) from `release-personas.md` |
| Tracking | GitHub Issues + `sub-task` labels + Milestone + GitHub Projects board per `github-projects-guide.md` |
| Handoff | Hub ↔ Spoke via sub-task comments (Procedure 4) + Operator ↔ Hub via Decision Briefings in main-thread chat (Operating Principle § Channel subsection) + Inter-stage per `release/governance/release-process.md` Tier 1/2/3 protocol |
| State Persistence | Release plan at `release/releases/plans/vX.Y_RELEASE_PLAN.md` (Procedure 0) + sub-task comments (per-stage) + hub-state substrate (Procedure 0b — pending approvals, action items, session lineage; per [`hub-session-continuity.md`](../../../core/standards/hub-session-continuity.md)). Hub-state ships as CUSTOMIZABLE-PUBLIC schema templates at `release/releases/hub-state/*.template` (tracked); runtime instance lives at the operator-instance path `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/*.md` per [`public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md) §4.3 (NOT tracked). Operator-instance workspace session handoff files (e.g., `projects/_config/SESSION_STATE.md`) are OPTIONAL and live outside the public repo — they supplement, not replace, the hub-state runtime substrate. |

Terminology in this document follows the [terminology glossary](../../../core/specs/terminology-glossary.md). Key term links: [Task](../../../core/specs/terminology-glossary.md#term-task), [Sub-task](../../../core/specs/terminology-glossary.md#term-sub-task), [Milestone](../../../core/specs/terminology-glossary.md#term-milestone), [Release](../../../core/specs/terminology-glossary.md#term-release), [Persona](../../../core/specs/terminology-glossary.md#term-persona).

### Placeholders Used in This Document

This document contains template placeholders that operators substitute when running the pipeline. They are intentionally fork-agnostic so the bridge works in any clone of this repo.

| Placeholder | Meaning | Example value |
|---|---|---|
| `{REPO}` | GitHub `owner/repo` slug of the operator's fork | `your-org/pmo-platform` |
| `{OWNER}` | GitHub owner only (rare; used only where `owner` is a separate field) | `your-org` |
| `{REPO_NAME}` | GitHub repo name only (rare; pairs with `{OWNER}`) | `pmo-platform` |
| `{MILESTONE}` | GitHub Milestone title for the release | `v1.0.0-initial` |
| `{ISSUE_NUMBER}` | Parent issue number for per-issue stages | `123` |
| `{SUB_TASK_NUMBER}` | Sub-task issue number for a specific stage | `456` |
| `{STAGE_NUMBER}` / `{STAGE_NAME}` | Stage in the pipeline | `5` / `Solutioning` |
| `<OPERATOR_INSTANCE_*>` | Operator-instance path (per `core/specs/operational-artifact-inventory.md`) — exists at runtime in the operator's clone, not in the public repo | varies |

---

## For the Operator

### When to Use

After triage and bundling produce an approved Milestone with assigned issues.

### How to Start

1. Copy the Hub Prompt (below) into a new Claude Code session
2. Edit the two quoted values in the header block at the top of the prompt — `MILESTONE` (your release Milestone title) and `REPO` (your fork's GitHub `owner/repo` slug)
3. The hub will read this doc, scaffold sub-tasks, and guide you through the release

### What You Do During a Release

1. **Start hub** — paste hub prompt
2. **Release planning** — hub generates a Stage 4 spoke prompt; you launch it to produce the release plan
3. **Review release plan** — approve the plan (dependency graph, sequencing, stage applicability)
4. **Review scaffolding** — hub uses the plan to create per-issue sub-tasks, you approve
5. **Launch spokes** — hub auto-launches spokes via the Agent tool within authorized scope (no per-spoke click required, per ADR (a) Stage-Conditional Launch Policy in § Spoke Launch Mechanisms); hub falls back to copy/paste prompts when an Agent-tool fallback condition applies or you explicitly request the prompt
6. **Review spoke output** — read the sub-task comment, approve or request iteration
7. **Render gate decisions** — at Stage 9 and 12, the hub presents the decision to you
8. **Close release** — hub verifies all sub-tasks closed, Milestone complete

### Hub Prompt

Edit the two quoted values on lines 1–2 of the pasted prompt — your release Milestone title and your fork's GitHub `owner/repo` slug. The rest of the prompt resolves against those variables; leave everything below the blank line unchanged. All five read steps resolve against intra-repo files; no operator-instance content is required.

```
MILESTONE="<your Milestone title, e.g. v1.0.0-initial>"
REPO="<your repo slug, e.g. your-org/pmo-platform>"

You are operating the release process for Milestone $MILESTONE ($REPO).

Read these in order:
1. README.md (repo overview — entry point for operators)
2. core/rules/ (all files)
3. release/references/how-to/hub-spoke-bridge.md — read the "For the
   Hub Agent" section for your operational instructions
4. release/references/specs/release-personas.md — persona cards you
   embed in spoke prompts
5. gh issue list --milestone "$MILESTONE" --state all --json
   number,title,state --repo $REPO (release scope)

Start by reading the Milestone issues and reporting current state.
Then run release planning (Procedure 0) before scaffolding.
```

---

## For the Hub Agent

This section is your operational guide. Follow these procedures in order.

### Operating Principle: Decision Briefing

The hub is the operator's command center. At every human touchpoint, the hub's primary job is reducing cognitive load by distilling spoke outputs and release state into decision-ready briefings. The hub never routes to the next action without first surfacing all items requiring operator judgment.

**At every touchpoint, the hub produces a Decision Briefing covering:**

1. **Decisions required** — skip recommendations, accepted risks, scope changes, disposition choices, trade-offs with options. Each decision gets: context (what happened), spoke recommendation (with rationale), hub evaluation (concurs or diverges, with rationale), final recommendation, and routing impact. For each option in a trade-off, the hub renders a per-option `### Design-Principle Conformance` line set (ALIGNED / `**CONFLICT.**` / N-A against the matching [`design-principle-register.md`](../../../core/standards/design-principle-register.md) entries) per the D-Gate Template § Design-Principle Conformance — the structural twin of the per-option Upstream-compatibility verdict. Omission on a `scope_predicate`-matching option is a `[STRUCTURAL-DEFECT]` (per `decision-discipline.md` § 5 G2). Each candidate decision is additionally screened for necessity/value-add per the Procedure 4 Step 5 dimension — an accurate-but-inert item is surfaced as a drop-recommendation, not rubber-stamped.
2. **Findings that change the release plan** — new risks, dependency shifts, scope expansions, discoveries outside the current issue's scope.
3. **Status summary** — what completed, quality assessment, any blockers.
4. **Action items surfaced this routing point** — hub-tracked AI-NNN rows from `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md` whose `trigger_type` predicate matches the current routing point per [`hub-action-tracking.md` § 4 Review Cadence](../../../core/standards/hub-action-tracking.md). Subsection format: `| AI-NNN | Category | Description | Trigger fired | Recommended disposition |`. When zero rows trigger, the subsection reads *"No action items triggered at this routing point"* — omission is a structural defect (forcing-function makes the scan observable). Schema + 6-value category enum + 4-value trigger-type enum + 5-state status lifecycle defined in `hub-action-tracking.md` — bridge doc does NOT duplicate normative content.

**Adversarial evaluation:** Spokes provide recommendations grounded in deep implementation context (every line of code, spec, and evidence). The hub interrogates each spoke recommendation adversarially against release-wide concerns and disconfirming evidence — cross-issue dependencies, pattern consistency across spokes, cumulative risk, and platform best practices. Concurrence requires empirical verification — the hub either (a) runs the verification itself (read the cited file, run the cited command, sample the cited data) and documents the result in the briefing's per-recommendation Empirical Verification subsection per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) (R1), or (b) diverges from the spoke pending operator clarification. Concurrence-without-verification is a non-compliant Decision Briefing.

When the hub diverges, it explains what the release context reveals that spoke couldn't see, AND cites the disconfirming evidence (file/section/command + observed result). When the hub concurs after verification, it cites the verification artifact (command run + observed result matching the spoke's claim). The operator always sees both layers with rationale + verification evidence.

**The hub does not proceed to routing until the operator has rendered all decisions.**

This pattern applies across all procedures:

| Procedure | Briefing Trigger | What to Surface |
|---|---|---|
| P0 Release Planning | Spoke posts release plan | Sequencing decisions, scope questions, merge/split recommendations |
| P1 Scaffolding | Hub builds sub-task list | Deviations from release plan, stage skip rationale, any issues requiring special handling |
| P4 Spoke Completion | Spoke(s) complete a stage | Decisions from spoke output (risks accepted, stages recommended for skip, disposition choices, ADRs), quality assessment, findings that affect other issues |
| P5 Gate Handling | Release reaches a gate | Go/no-go framing with full evidence summary |
| P6 Early Merge | Routing reveals dependency bottleneck | Early merge recommendation with downstream impact |

**When multiple spokes complete in a batch:** Produce a single consolidated briefing covering all spoke outputs. Group decisions by type (approvals needed, risks to accept, scope changes). Do not interleave routing with decisions — present all decisions first, get operator approval, then route.

#### Decision Briefing Information Sufficiency

A Decision Briefing is *information-sufficient* before it is rendered: the operator can render every decision in it without the hub going back to read a spec it should already have loaded, and without an unstated option surfacing after the operator has answered. This sub-section is the **construction precondition** on every briefing produced under this Operating Principle — load and enumerate first, render second, call `AskUserQuestion` third. It applies the Localization Check (Mechanism 1) of [`decision-discipline.md` § 2.1](../../../core/disciplines/decision-discipline.md) to the briefing's option space and the operator's stance; it does not redefine that mechanism — § 2.1 remains the parent discipline for localizing a decision against platform-specific context.

The hub satisfies all five gates before the `AskUserQuestion` call (or equivalent in-chat mechanism per the [Channel subsection](#channel-main-thread-chat-canonical)) fires:

1. **Pre-load referenced spec content.** Before drafting the briefing, the hub reads the actual content of every spec, governance rule, schema, register entry, or prior decision the briefing will cite — not the title, not a remembered summary. A decision framed against a citation the hub has not opened this session is under-loaded. (This is the briefing-construction application of the adversarial-evaluation R1 requirement above: the verification artifact cannot be cited if the source was never read.)
2. **Enumerate the full option space, including stance-implied options.** The hub lists every option the decision admits — not only the options it recommends. This explicitly includes options the operator's own prior stance, correction, or directive implies (e.g., if the operator has previously preferred the least-destructive disposition, "park-in-container" is an option that must appear even when the hub recommends a different one). Presenting a curated subset that omits a live option the operator would plausibly choose is under-loading the option space.
3. **Render the full briefing in chat *before* the `AskUserQuestion` call.** The complete briefing — decisions, options, recommendation, rationale, verification evidence — is printed as a chat turn *before* the structured-prompt call fires. The `AskUserQuestion` options are a selection affordance over a briefing the operator has already read in full, never the first place the operator sees the decision content. A gate whose immediately-preceding chat turn lacks the rendered full briefing is a structural defect — tag `[STRUCTURAL-DEFECT: unrendered-gate]`, consistent with the structural-defect marker convention used elsewhere in this document (e.g., the return-value-conformance gate). Warn-mode initial: the marker is logged and the briefing flagged for the operator; flip-to-enforce: the hub HALTS the gate and re-renders the full briefing before re-issuing the prompt.
4. **Stance-scan pre-check.** Before finalizing the option space (gate 2), the hub scans for operator stance bearing on this decision class — prior corrections, standing directives, recorded preferences, and the active correction set — and confirms each stance-implied option is present in the enumeration or explicitly addressed as considered-and-excluded with a reason. A stance the hub is aware of but did not surface as an option (or an explicit exclusion) is a stance-scan miss.
5. **Spec-content-loaded self-check gate.** As the final pre-render gate, the hub self-checks that gate 1 actually happened: for each citation in the drafted briefing, the hub confirms it read the cited content this session (the read is the evidence). A briefing citing a source the spec-content-loaded self-check cannot confirm was loaded is held — the hub loads the source and re-checks before rendering, rather than rendering on a remembered or assumed summary.

**`preview`-field affordance (complement, not replacement).** The `AskUserQuestion` per-option `preview` field MAY carry a compact per-option mini-table — a one-glance trade-off / conformance / reversibility summary keyed to the option — as a structured complement to the full chat-printed briefing. The `preview` mini-table is never a substitute for gate 3: the full briefing is always rendered in chat first, and the `preview` is a convenience surface layered on top of it. A `preview` populated while the full briefing is absent is the gate-3 structural defect, not a satisfied gate.

**Worked example — a compliant, information-sufficient Decision Briefing** (a Stage 5 skip-recommendation decision; demonstrates gates 1–2 — pre-loaded options + full option space including a stance-implied option):

> **Decision required (D-StageSkip):** Skip Stage 7 Dev Testing for a sub-task?
>
> **Context (spec content pre-loaded — gate 1):** Read `release/references/pipeline/stage-07-dev-testing.md` § Applicability this session — Stage 7 applies when an issue ships executable behavior with a fixture. Read the sub-task's File Change Matrix: all edits are grep-verifiable doc/schema assertions, no executable surface. Read the Stage 4 plan's Stage Applicability Matrix row: REDUCE → doc-conformance.
>
> **Option space (full enumeration — gate 2):**
> - **(A) Skip Stage 7 entirely** — no executable code, ACs are grep assertions. *(hub recommendation)*
> - **(B) REDUCE to a doc-conformance grep pass** — run the AC greps as a lightweight Stage 7, no test authoring. *(stance-implied option — gate 4: the operator's standing preference is to keep a verification rung rather than fully skip; surfaced even though the hub leans (A).)*
> - **(C) Apply full Stage 7** — author tests. *(enumerated for completeness; disproportionate to a doc-only change.)*
>
> **Hub recommendation + rationale:** (A), but (B) is the stance-aligned choice and is the hub's fallback if the operator wants a retained rung. (C) is over-process for grep-verifiable ACs.
> **Reversibility / Confidence:** CHEAP / HIGH (a skip is re-openable at Stage 8 QA).
>
> *(This full block is printed in chat — gate 3 — before the `AskUserQuestion` call offering A / B / C, each with a `preview` mini-table summarizing its testing cost and verification coverage.)*

#### Channel: main-thread chat (canonical)

**Engagement channel — main-thread chat (canonical):** Every operator-engagement event the hub surfaces — Decision Briefing for spoke completion (Procedure 4), routine gate handling (Procedure 5: Stage 9 Plan Review, Stage 12 Execute), Tier 2/3 inter-stage escalations (per [`release/governance/release-process.md` § Inter-Stage Feedback Protocol](../../governance/release-process.md)), D-class decisions (per [`decision-discipline.md § 3`](../../../core/disciplines/decision-discipline.md)), Collective Review scope-lock (per [`release/governance/release-process.md` § Collective Review Protocol](../../governance/release-process.md)), Tier 0 Premise Rejection (per [`triage-design-rereview.md § 9`](../standards/triage-design-rereview.md)), early-merge approval (Procedure 6), and post-deploy disposition (Procedure 7 Step 6 `--apply` gate) — surfaces as a structured Decision Briefing **in the main-thread Claude Code chat session** via `AskUserQuestion` or equivalent in-chat mechanism. Operator engagement does NOT propagate to chips (chips are spawn-only), GitHub Issue comments (those are post-decision audit trail per [`hub-session-continuity.md § Decision Log Mechanism`](../../../core/standards/hub-session-continuity.md)), Obsidian edits, or external channels.

**Routine engagement vs spawn (operator-facing classification):**

| Event class | Routine engagement? | Channel |
|---|---|---|
| Spoke prompt approval (operator clicks chip to launch) | NOT routine — this IS the chip's purpose | chip click (one-click launch; not "engagement" per se) |
| Spoke output review (Decision Briefing at Procedure 4) | Routine engagement | **main-thread chat** |
| Stage 9 GO/NO-GO | Routine engagement (gate) | **main-thread chat** |
| Stage 12 Execute authorization | Routine engagement (gate) | **main-thread chat** |
| Collective Review scope-lock | Routine engagement (release-level gate) | **main-thread chat** |
| Tier 1 [ADJUST] | NOT engagement (hub/spoke commits autonomously per `release/governance/release-process.md § Inter-Stage Feedback Protocol`) | N/A (no operator engagement) |
| Tier 2 [SCOPE CHANGE] | Routine engagement (escalation) | **main-thread chat** |
| Tier 3 [PLAN REJECTION] | Routine engagement (escalation) | **main-thread chat** |
| D-class decision | Routine engagement (gate) | **main-thread chat** |
| Tier 0 Premise Rejection | Routine engagement (always-escalate per `triage-design-rereview.md § 9` Phase 1 default) | **main-thread chat** |
| Post-deploy `--apply` approval (Procedure 7 Step 6 orphan-cleanup; release-executor Mode D automated close-out) | Routine engagement (`--apply` is the Tier 1 Recommend gate per CLAUDE.md Autonomy Tier table) | **main-thread chat** |
| Decision RECORDED comment on sub-task (post-decision) | NOT engagement (audit trail) | GH comment (dual-surface per `hub-session-continuity.md`) |
| Event-log emission (post-decision) | NOT engagement (audit trail) | `pipeline-event-log.md` (dual-surface per `hub-session-continuity.md`) |

**`AskUserQuestion` vs "equivalent in-chat mechanism" (interface flexibility):** `AskUserQuestion` is the current structured-prompt mechanism (cited at [`release/governance/release-process.md § Automated close-out`](../../governance/release-process.md) for `release-executor` Mode D approval gate). "Equivalent in-chat mechanism" covers any future structured-prompt mechanism that renders in the main-thread session — a future Decision Briefing renderer, a structured-input UI element, etc. The canonical property is **rendered in main-thread chat AND structured (options + recommendation visible)** — NOT a pin to a specific tool name.

**Surface-role discipline (3 surfaces, 3 distinct roles):** Chip is for **work execution after decision** (spoke spawn per § Spoke Launch Mechanisms — Default subsection); GH comment is for **decision recording after decision** (post-decision dual-surface convention); main-thread chat is for **rendering the decision itself**. Surface overload (chip-for-engagement, comment-for-engagement, etc.) is a structural defect — surfaces a fragmentation problem that 's narrowing was designed to prevent.

**Cutover discipline:** Applies to all releases going forward.

**Decision discipline:** At each Decision Briefing produced under this Operating Principle, the hub applies the decision-discipline framework defined in `core/disciplines/decision-discipline.md`. That file specifies the 3-mechanism templates (Localization Check, Opposing View, Pattern Cache Scan), the decision-class triage table, ceremony-management guards, pattern-cache infrastructure (observation log + emergence rule), and release-close metrics. The hub is one consumer of this framework; future skills replacing hub functions (`release-planner`, `principal-engineer`, etc.) consume the same framework.

For the "does practice P apply in context C" decision sub-class, M1's Localization Check consults `core/disciplines/applicability-framework.md` (the structured applicability criteria/contraindications/conflict-resolution content; ). Composition: provider/consumer per applicability-framework.md §6.

### Procedure 0: Release Planning

**Trigger:** Hub has read all Milestone issues and reported current state.

Release planning runs once per Milestone at release scope (all issues) before any per-issue scaffolding. This is Stage 4 of the pipeline, executed as a release-scoped spoke.

**Steps:**
1. Read all issues in the Milestone (titles, bodies, states, dependencies, sub-issues)
2. Generate a Stage 4 Release Planning spoke prompt using the Release Planning Spoke Template below, and invoke the Agent tool per the Spoke Launch Mechanisms § Default subsection (`Agent({subagent_type, prompt, description, model, isolation, run_in_background})`) — OR fall back to printing the prompt if a fallback condition applies
3. Hub auto-launches the spoke within authorized scope and awaits the result inline; OR, under fallback, the operator copy/pastes the printed prompt into a new session
4. Spoke reads all issues and produces: dependency graph, implementation sequence, contention map, stage applicability per issue, risk register
5. Spoke posts output as a comment on a release planning sub-task (hub creates this sub-task first: `Stage 4 Release Planning — {MILESTONE}`)
6. Hub reads the spoke output and presents the release plan to the operator for review
7. Operator approves, modifies, or requests iteration. The Phase B1 Decision Briefing presentation surface includes a **Release Outcome Statement (draft)** row (per [release-outcome-statement-template.md](../specs/release-outcome-statement-template.md)) — the operator approves the Outcome at the same Phase B1 gate where bundle scope is accepted. After Phase B1 acceptance, hub composes the `gh api repos/.../milestones/<N> -X PATCH` payload to include the `### Release Outcome Statement` H3 block in the Milestone description. **Cutover discipline:** Applies to all releases going forward.

**Platform-config resolution + injection (single resolution at the hub):** During Procedure 0 the hub resolves platform configuration ONCE for the release scope and injects the resolved values into each downstream spoke's chip prompt. The resolver, the 3-level default-fallback, and the two surfaces (`operator.toml` environment/identity + `platform-config.toml` behavior) are defined in [`core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`](../../../core/governance/OPERATIONS.md). The hub resolves the 5-rung cascade (global default → portfolio → program → project → individual; most-specific wins) for the fields a given stage's spoke consumes — e.g., `bundle_doctrine_frame` / `release_size_target_pts` / `default_release_class` for planning-class spokes — and passes the resolved value down. **Spokes do NOT re-resolve** (single resolution avoids hub-vs-spoke divergence); a spoke reads the value the hub injected, falling back to the stage's documented default (logged) only if the hub injected nothing. A release entering the pipeline after the adapter-config-foundation merge SHA carries this injection; the adapter-config-foundation release itself is exempt per the resolution-protocol cutover clause. **Cutover discipline:** Applies to all releases going forward.

**Baseline-pin awareness:** Stage 4 Phase A4 Cross-PR Overlap Audit is baseline-pinned per [`stage-04-planning.md § Cross-PR Overlap Audit (A4 extension)`](../pipeline/stage-04-planning.md). Mid-pipeline divergence (concurrent releases merging to `main` during the subject release's Engineering/DT/QA window) is NOT caught by the Stage 4 audit — it is caught by Stage 9 Phase A6.5 (PRIMARY, HALT-eligible) and Stage 7/8 entry warn-only checks (SECONDARY); Stage 12 Phase A.5 remains the post-GO ultima-ratio detector. The Stage 4 release plan SHOULD include the File Change Matrix in a structurally-machine-readable form (one path per line in a fenced code block within the plan file) so that Stage 7/8/9 chip prompts can extract the path list deterministically. **Cutover discipline:** Applies to all releases going forward.

**Gate:** Release plan approved by operator before proceeding to Procedure 1.

**Canonical location:** The approved plan is committed as `release/releases/plans/vX.Y_RELEASE_PLAN.md` per the topology selected at the D-C Branch Topology decision gate:

- **Single-branch topology** (D-C SINGLE — default): The plan file is committed on the release branch as **Engineering Commit 0** (the first commit on the release branch produced by the first per-issue Stage 6 Engineering spoke). Until that first Engineering commit lands, the Stage 4 sub-task comment is the working reference.

  **Commit-0 version re-verify (FIRST Engineering spoke only, immediately before writing the plan file as Engineering Commit 0).** The version selected at D-Version (recommendation time, Stage 4) may have been claimed by a concurrent release in the window between selection and now — the originating incident surfaced exactly this way (a concurrent release shipped the recommended version; the collision was caught only when the Engineering spoke fetched fresh authoritative refs before the plan-file write). Before authoring `release/releases/plans/<slug>_RELEASE_PLAN.md`, the first Engineering spoke re-runs the authoritative-version-selection check:
    1. `git fetch --tags origin && git fetch origin main` — refresh authoritative host state at Commit-0 time.
    2. Recompute next-free for the plan's bump-class per the D-Version authoritative-version-selection procedure (§ Recurring D-decisions) — the host-agnostic allocation rule consuming the adapter's `anchor()` + `claimed_set()` by name; any ledger input read via `git show origin/main:<ledger-path>`, never the worktree copy.
    3. If the planned version is NOT in the claimed set AND equals the recomputed next-free → **PROCEED**: write the plan file. Else → **HALT**: do NOT overwrite a shipped version's plan file. Post a Tier 2 `[SCOPE CHANGE]` comment on the parent sub-task per `release-process.md` § Inter-Stage Feedback Protocol, naming the planned version, the recomputed next-free, and the colliding tag/ledger row; the operator re-renders D-Version against current state.

     The Commit-0 re-verify is a **single detect-and-HALT** — it does NOT auto-recompute-and-retry. On HALT it hands to the operator, who re-renders D-Version; the spoke then re-runs this same single re-verify against the operator's new value. Bounded retry on sustained contention is the atomic-claim rung's job at the tag (Stage 12), not this rung's. This is detection rung 1 (earliest); it composes with — does not replace — the Stage 9 mid-pipeline divergence re-check (file-divergence axis), the Stage 12 pre-merge freeness check, and the atomic version claim.

- **Option-A topology** (D-C OPTION-A — per-issue branches + per-issue PRs per Procedure 6 early-merge precedent): The plan file is committed via a dedicated **Stage 4 release-plan chore PR** authored by the hub from the approved Stage 4 sub-task comment. Mechanics:
  1. Hub copies the Stage 4 sub-task comment content into a new file at `release/releases/plans/vX.Y_RELEASE_PLAN.md`.
  2. Hub creates branch `chore/vX.Y-stage-4-release-plan` off `main`.
  3. Hub commits with message `chore(vX.Y): Stage 4 — release plan`.
  4. Hub pushes and opens a chore PR titled `chore(vX.Y): Stage 4 — release plan` with milestone `vX.Y-<slug>`, labels mirroring the release issue labels, `--assignee @me`, `--reviewer OPERATOR`, `--project "PMO Pipeline"`.
  5. After operator review of the chore PR diff (which IS the Stage-4-plan dry-run for Option-A), hub merges via `gh pr merge` and the plan file is on `main`.
  6. **All subsequent per-issue Stage 5/6/7/8 spokes read the plan file from `main`.**

  Sequencing: This step fires AFTER operator approves the Stage 4 spoke output (Procedure 0 Step 7) and BEFORE Procedure 1 Scaffolding creates per-issue sub-tasks. Procedure 1 MUST NOT create per-issue sub-tasks until the Stage 4 release-plan chore PR has landed on main.

  The Stage 4 release-plan chore PR is one of three chore PRs per Option-A release: Stage 4 plan / Stage 12 RELEASE_LOG row + visible-H4 Deployment Log / Stage 13 INDEX + DIGEST + RELEASE_NOTES. Branch-naming convention is symmetric: `chore/vX.Y-stage-<N>-<purpose>`.

  **Cutover discipline:** Applies to all releases going forward.

**Release Planning Spoke Template:**
```
This is a spawned Claude Code session — you have no memory of
the hub. The hub session will consume your output from the
release planning sub-task comment after you finish. Stay within
scope and do not spawn additional spokes yourself.

You are executing Stage 4 (Release Planning) for Milestone
{MILESTONE} ({REPO}).

This is a RELEASE-SCOPED stage — you read ALL issues in the
Milestone, not a single issue.

Read these in order:
1. README.md (repo overview)
2. core/rules/ (all files)
3. gh issue list --milestone "{MILESTONE}" --state all --json
   number,title,state,labels --repo {REPO}
4. For each issue: gh issue view {NUMBER} --repo {REPO}
5. release/references/pipeline/stage-04-planning.md
6. release/references/how-to/hub-spoke-bridge.md — Procedure 0

## Persona
{FULL_STAGE_4_PERSONA_CARD_FROM_RELEASE_PERSONAS_MD}

## Task
Produce a release plan for Milestone {MILESTONE} covering:

1. **Dependency graph** — which issues depend on which (directional)
2. **Implementation sequence** — dependency-ordered execution order
3. **Contention map** — which issues share affected files
4. **Stage applicability per issue** — which stages (5-13) apply
   to each issue. Default: all. Skip Solutioning (Stage 5) only
   if the change is trivial. Skip Dev Testing / QA (Stages 7-8)
   only if the change has no functional impact.
5. **Risk register** — dependency risks, contention risks,
   scope risks, rollback complexity
6. **Merge/split recommendations** — issues that should be
   combined or separated based on analysis
7. **Release Class declaration** — propose Release Class per
   release/references/specs/release-class-taxonomy.md Class
   Enum + Classification Procedure. State proposed class +
   trigger-condition evidence + differentiation posture
   (engagement density / Stage 9 review depth + OPTIONAL Stage 5
   activation bias / Stage 13 outcome-window). Operator renders
   the class at Phase B3 alongside scope-commit. Cutover
   discipline: applies to all releases going forward.

## Output
Post your output as a comment on sub-task #{SUB_TASK_NUMBER}:

## Stage 4 Release Planning — {MILESTONE}
### Summary (30 seconds)
### Dependency Graph
### Implementation Sequence
### Stage Applicability Matrix
### Contention Map
### Risk Register
### Recommendations

Then close sub-task #{SUB_TASK_NUMBER}.

## Scope
- Analyze all issues in the Milestone.
- Do not execute implementation — planning only.
- Discoveries outside scope → note in Recommendations.
- Release plan prose that describes per-issue closure actions MUST use safe
  phrasing (`mark #N as closed at Stage 13`, not `close #N at Stage 13`) — the
  release plan is transcribed into PR body Summary/Implementation sections at
  Engineering, where GitHub's auto-close parser fires on close-family verbs +
  `#N` regardless of section context. See Procedure 3 §PR Body Parser-Clean
  Discipline.
```

### D-Gate Template

D-decisions (architectural decisions requiring operator judgment) rendered at
the Operator Decision Gate during Stage 4 Release Planning use this structure.
One block per decision. Included in the release plan's "Operator Decisions"
or "Architectural Decision Gates" section.

### D-<Name>: <Question>
**Gate input:** <what drives the decision — spoke output, audit finding,
  prior-release evidence, operator directive>
**Pre-decided (if applicable):** <operator's pre-decided stance, citing
  directive and date; OMIT if no pre-decision>. **Directive auto-population:**
  when no per-decision pre-decided stance is on record AND the milestone
  description's `## Gate-Class Framing Directives` block carries a
  `pre_decided_default` for this gate's `gate_class`, the hub auto-populates
  this field with that default, citing the directive block + milestone
  description as the source (per `engagement-charter.md` § Per-gate-class
  framing directives). A per-decision stance, when present, takes precedence
  over the directive default (the default is the fallback). The field reads
  OMIT only when neither a per-decision stance nor a matching
  `pre_decided_default` exists.
**Gate decision:** <specific options to choose between, enumerated>
**Blocks:** <which sub-tasks/stages cannot start without this decision>
**Gate-class directive injection (per `engagement-charter.md` § Per-gate-class framing directives):** When the milestone description carries a `## Gate-Class Framing Directives` block whose `gate_class` matches this gate, the rendered gate MUST include — IN ADDITION TO the hub-enumerated options/dimensions above — every `require_options` entry as a selectable option and every `surface_dimensions` entry as a displayed decision dimension, and emphasize each `principles_emphasis` (DP-N) conformance verdict. Directive items are ADD-only (the rendered set is the union of hub-defaults and directive items); the directive never removes a hub-surfaced option or dimension. Absent a matching directive block, the gate renders with hub defaults only (no regression).
**Upstream compatibility:** (REQUIRED per §D-Gate Template — see applicability note)
  - Anthropic skill-creator convention: <quoted convention with source;
    e.g., "Frontmatter is `name:` + `description:` only per
    `anthropic-skills:skill-creator` schema [citation]">
  - If PMO rule conflicts with upstream: <explicit CONFLICT statement +
    enumerated mitigations (register as extension / restrict scope /
    withdraw field / document as PMO-only)>
  - If upstream-compatible: <evidence of the compatibility check
    performed — date of docs review, schema version cited, conflict
    absence confirmed>
  - Sourcing posture (REQUIRED when the D-decision introduces or changes a
    skill's Anthropic coupling): state the chosen posture — own /
    guarded-wrap / pass-through — per
    [ADR-023](../../../core/ADRs/ADR-023-skill-sourcing-coupling-posture.md),
    with the blast-radius × commodity-stability justification.
    Stakeholder-facing / judgment skills are own-only. ADR-023 holds the
    rule; this line cites it.
**Reversibility / Confidence:** <CHEAP|MODERATE|EXPENSIVE|IRREVERSIBLE> /
  <HIGH|MEDIUM|LOW>

**Upstream compatibility applicability:**
- **REQUIRED** when the D-decision touches skill-authoring surface:
  required/optional frontmatter fields, file layout conventions, naming
  patterns, skill directory structure, any rule that modifies what a
  NEW skill must contain or how an EXISTING skill is structured.
- **N/A-with-rationale permitted** when the D-decision does NOT touch
  skill-authoring surface (e.g., release branch naming, merge sequence,
  worktree placement, operator-decision-sub-task-granularity). In that
  case, the subsection reads: "N/A — this D-decision does not modify
  skill-authoring surface. Upstream compatibility check does not apply."
  Omission WITHOUT rationale is a structural defect; the Collective
  Review cross-D scan (release-process.md CR Protocol bullet 5) catches
  missing subsections.
- This check is a specific application of **Mechanism 1 (Localization
  Check)** per `decision-discipline.md` § 2.1 — upstream-Anthropic-
  convention is one of the localization dimensions hub cites. The D-Gate
  template's per-D subsection operationalizes Mechanism 1 at the D-
  decision-content level; the briefing-level Localization Check in the
  Decision Briefing template operates at the hub-recommendation level.
  They are complementary, not redundant.

**Evidence format (load-bearing test):**
- Anthropic convention citation: MUST name a specific schema, doc, or
  `anthropic-skills:skill-creator` field. "Anthropic convention" alone
  is not a citation.
- Conflict statement: MUST use the literal string `**CONFLICT.**` when
  a conflict is identified (structural flag for CR scan and DT
  verification).
- Mitigation: MUST enumerate ≥1 named strategy with named artifact
  (e.g., "register in `version-field-semantics.md` as PMO extension").
- Compatible-path evidence: MUST cite the drift-check date and source
  (e.g., "skill-creator docs review 2026-04-24, schema v<n>, no
  `version:` field in scaffolder output — confirmed no conflict").
- Design-principle citation: MUST name a specific register entry
  (DP-N) + its `governing_doc` path:line. "Aligns with platform
  principles" alone is not a citation (fails `decision-discipline.md`
  § 5 G3).
- Design-principle conflict statement: MUST use the literal string
  `**CONFLICT.**` when a conflict against a design principle is
  identified (structural flag for Check 45 + the CR scan).
- Design-principle mitigation: MUST enumerate ≥1 named strategy
  (e.g., "absorb into the milestone description", "cite the canonical
  source instead of duplicating").

**Upstream-reference catalog:** When the D-decision touches skill-authoring surface, consult [`core/standards/upstream-reference-catalog.md`](../../../core/standards/upstream-reference-catalog.md) for the canonical upstream-source entry (e.g., `skill-md-frontmatter` for frontmatter decisions; `skill-references-directory` for directory-naming decisions). The catalog entry's `upstream_required` / `upstream_optional` / `pmo_extensions` fields directly inform the verdict (aligned / diverged-with-rationale / N/A). When citing a catalog entry whose `last_verified_date` is older than 90 days, the D-Gate verdict notes the staleness — convention may still be aligned, but the catalog itself needs re-verification.

**Design-Principle Conformance:** (REQUIRED when the option touches a
  scope_predicate-matching surface — see applicability note)
  Per option in the Gate decision, score conformance against each
  design-principle register entry whose `scope_predicate` matches the
  option's change surface:
  - ALIGNED: `<DP-N name>` — option upholds the principle. Cite the
    register entry id + `governing_doc` (e.g., "ALIGNED DP-3
    (Maintainability, build-philosophy.md:50) — option cites the
    canonical source, adds no second copy").
  - `**CONFLICT.**` `<DP-N name>` — option violates the principle. State
    the conflict, then enumerate ≥1 named mitigation (e.g.,
    "`**CONFLICT.**` DP-4 (Simplicity) — option adds a parallel tracker;
    mitigation: absorb into the existing milestone description"). A
    CONFLICT is reversibility-tier-gated per the register entry's
    `conflict_reversibility_default`: CHEAP/MODERATE → annotate and
    proceed; EXPENSIVE/IRREVERSIBLE → HALT for operator sign-off (with a
    rollback-infeasibility statement per `reversibility-protocol.md`).
    Gate at the max of the register default and the option's own
    reversibility.
  - N-A: `<DP-N name>` — the principle's `scope_predicate` does not match
    this option's change surface.

**Design-Principle Conformance applicability:**
- REQUIRED for every option whose change surface matches ≥1 register
  entry's `scope_predicate`.
- N/A-with-rationale permitted when NO register `scope_predicate` matches
  the option (e.g., a pure sequencing or branch-naming decision). The
  subsection then reads: "N/A — no design-principle scope_predicate
  matches this option's change surface." Omission WITHOUT rationale on a
  scope_predicate-matching surface is a `[STRUCTURAL-DEFECT]` per
  `decision-discipline.md` § 5 G2 (omission-without-explicit-N/A is the
  non-ceremony signal; here the surface DOES match, so the omission is
  the defect). Check 45 (`deploy.sh --check`) catches the missing
  subsection; the Collective Review cross-D scan aggregates it.
- This check is a specific application of Mechanism 1 (Localization
  Check) per `decision-discipline.md` § 2.1 — agent-operating-principle
  is one localization dimension, the structural twin of the
  upstream-Anthropic-convention dimension the Upstream compatibility
  subsection covers.

**Design-Principle register:** Score each option against
  [`core/standards/design-principle-register.md`](../../../core/standards/design-principle-register.md).
  The entry's statement + `governing_doc` inform the verdict; the
  `scope_predicate` determines whether a verdict is REQUIRED for the
  option. When citing an entry whose `last_verified_date` is older than
  90 days, the verdict notes the staleness.

**Recurring D-decisions:** Some D-decisions fire on every release with the same template shape, varying only by per-release evidence. The Release Planning spoke (Procedure 0 Step 7) renders these inline in the release plan's Operator Decisions block per the D-Gate Template above. The current recurring set:

```
#### D-ReleaseClass: What Release Class does this release carry?
Gate input: Spoke-proposed class + trigger-condition evidence
  per release/references/specs/release-class-taxonomy.md
Gate decision: Choose between (A) routine, (B) novel,
  (C) cross-cutting, (D) hotfix
Blocks: Stage 3 Phase B3 milestone-description authoring;
  downstream per-class differentiation posture
Upstream compatibility: N/A — Release Class is PMO platform
  internal taxonomy; no Anthropic upstream surface.
  Upstream compatibility check does not apply.
Reversibility / Confidence: CHEAP / HIGH (re-classifiable
  later with operator approval per release-class-taxonomy.md
  Re-Classification Protocol)
Recommendation: spoke recommendation per trigger evidence
```

Cutover discipline for D-ReleaseClass: applies to all releases going forward.

```
#### D-Version: What version does this release claim?
Gate input: Spoke-recommended next-free version, computed at
  recommendation time against AUTHORITATIVE host state (never local
  refs / a stale worktree), per the authoritative-version-selection
  procedure below. The concrete number is provisional-display: the
  founding architecture (defer-to-merge — see the version-claim
  determinism ADR recorded on the Version-Claim Determinism
  milestone) binds the number only at the atomic claim moment; the
  durable declaration at plan time is the bump-class.
Gate decision: Operator renders the version identity — (A) accept
  the spoke-recommended next-free, (B) version-less milestone
  (theme-named; no tag claimed at Stage 12), or (C) operator-
  specified override (e.g. when a concurrent release is known to be
  claiming the recommended slot).
Blocks: release branch name (release/<slug>), plan-file path, the
  Stage 12 atomic version claim, and any version: frontmatter the
  release writes.
Upstream compatibility: N/A — version identity is PMO platform
  internal; no Anthropic upstream surface. Upstream compatibility
  check does not apply. (When the version feeds a skill version:
  field, that field's upstream posture is owned by the D-decision
  that edits the skill, not by D-Version.)
Reversibility / Confidence: CHEAP pre-Engineering (recommendation
  only); MODERATE after Engineering Commit 0 (identity propagates
  into branch name, plan-file path, frontmatter) / HIGH.
Recommendation: spoke recommendation = next-free per the procedure
  below.

Authoritative-version-selection procedure (run at recommendation
time; re-run at Engineering Commit 0 before the plan file is
written — see Procedure 0 § Canonical location):
  1. The next-free computation is the host-agnostic version-
     allocation rule (RELEASE_PROTOCOL.md § Versioning): the lowest
     version at or above the bump-class floor not present in the
     claimed set. The floor derives from the bump-class
     (major/minor/patch) per that rule's Bump-Class Selection Guide.
  2. That rule consumes the repository-host adapter operations
     anchor() and claimed_set() BY NAME (the operation interface is
     defined in core/standards/repo-host-adapter-versioning.md). The
     hub does NOT inline a host mechanism here: anchor() returns the
     highest claimed version in the mainline lineage (orphan
     lineages excluded — the adapter's responsibility, not the
     hub's), and claimed_set() returns every currently-claimed and
     in-flight version the candidate must avoid. Do NOT re-derive
     the anchor or re-enumerate the claimed-set membership in this
     block — the adapter owns "how"; the hub calls the named ops.
  3. AUTHORITATIVE-STATE read discipline (the hub's obligation when
     it asks the adapter for these values): the adapter operations
     MUST read authoritative host state, never local refs or a stale
     worktree. Before invoking the selection, refresh authoritative
     state:
       git fetch --tags origin
     — a bare local `git tag` list is NOT authoritative: a
       concurrently-shipped tag is invisible without the fetch (the
       originating defect — a concurrent release shipped the
       recommended version from a local-tag-list selection). Any
       release-ledger input to claimed_set() is read at the remote
       tip, never the worktree copy:
       git show origin/main:<ledger-path>
     — a stale-worktree ledger read was the second half of the
       originating defect; `git show origin/main:` reads the
       authoritative tip regardless of how far behind the worktree
       is. (This is the same authoritative-refs discipline the
       Session-Start sync and the Primary-Checkout comparison
       already mandate in core/rules/git-workflow.md — D-Version is
       the version-touching hub decision that applies it.)
This procedure is the EARLIEST freeness rung; it composes with — it
does not replace — the pre-merge freeness gate, the CI freeness
gate, and the atomic ref-claim (anchor()/claimed_set() reads back
the same single claim the adapter's atomic_claim() arbitrates at
merge), which are the later rungs on this milestone, and with the
Stage 9 mid-pipeline divergence checks (which guard the file-
divergence axis — a different question from version-freeness).
```

Cutover discipline for D-Version: applies to all releases going forward.

---

### Procedure 0a — Audit-Aware Orientation (cross-reference)

**Trigger:** Hub renders any recommendation, chip-prompt scaffolding, or Decision Briefing whose load-bearing platform context is an analysis artifact older than ~24 hours OR an artifact authored before the most recent merge to `main` for the affected file(s). Examples: a Stage 4 release-plan File Change Matrix cited in Stage 6 chip construction; a closed sub-task body referenced as "the spec" without re-reading sibling comments; a Stage 5 spec citing dependency state that has since transitioned; audit `recommendations.md` enumerated items lifted into chip scaffolding without primitive verification.

**Cross-reference:** Canonical specification lives at [`decision-discipline.md` § 2.1.1 Sub-mechanism — Audit-Snapshot Reconciliation](../../../core/disciplines/decision-discipline.md). The sub-mechanism specifies: when-this-fires definition; three verification primitives (`gh issue list --search` for existing tracking; `git log --follow <cited-file> --since="<artifact-date>"` for post-artifact commits; `grep` for cited-symbol existence); `[VERIFIED <YYYY-MM-DD>: <command> → <result>]` evidence trailer format; load-bearing vs. ceremony examples; empirical-basis N=4+ drift table; cutover semantics. Hub does NOT duplicate that content here — read the canonical source. This subsection exists at this surface only to bind the hub-consumer entry point to the sub-mechanism so the discipline fires at the right moment in hub workflow.

**Transitional posture (hub → skill):** This binding survives the eventual hub-to-skill replacement. When `release-planner`, `principal-engineer`, or any future decision-producing skill replaces hub procedures, the skill inherits § 2.1.1 directly from `decision-discipline.md` via § 7.3 (future consumers). The cross-reference paragraph above remains as archival evidence of where the binding fired during the hub era; the canonical sub-mechanism survives intact in `decision-discipline.md` regardless of consumer transition.

---

### Procedure 0b — Hub Session Continuity (cross-reference)

**Trigger:** Hub session start — operator paste of Hub Prompt, scheduled-task hub spawn, or any new hub session resuming an in-flight release. This procedure fires BEFORE Procedure 1 Scaffolding (if release scaffolding has not yet run) AND before any routing decision in an already-scaffolded release.

**Cross-reference:** Canonical specification lives at [`hub-session-continuity.md`](../../../core/standards/hub-session-continuity.md). The standard specifies: persistence format (file-based markdown — schema templates tracked at `release/releases/hub-state/*.template`, runtime instance at the operator-instance path `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/` per [`public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md) §4.3); 3-surface state schema (Surface A `pending-approvals.md` for the queued-approval substrate, Surface B REUSED `pipeline-event-log.md` for decision history, Surface C OPTIONAL `sessions.md` for session lineage); 9-step Resume Procedure with drift detection (Step 9); composite session-ID format `<worktree>__<ISO-start>__<short-sha>`; dual-surface Decision Log Mechanism (sub-task comment + pipeline-event-log row, BOTH required); and the durable-state contract that the queued-resumption mechanism rides on. Hub does NOT duplicate that content here — read the canonical source.

**Why this section exists at this surface:** Procedure 0b binds the hub-consumer entry point to the standard so the Resume Procedure fires at the right moment in hub workflow. Pattern parallel to Procedure 0a's binding of audit-snapshot reconciliation to the hub-decision surface.

**Composition with sibling procedures:**

| Procedure | Relationship to 0b |
|---|---|
| Procedure 0 (Release Planning) | Procedure 0 runs once per release (Stage 4 spoke producing release plan); 0b runs every session start within the release lifecycle |
| Procedure 0a (Audit-Aware Orientation) | 0a covers audit-snapshot reconciliation at decision-rendering time; 0b covers state reconstruction at session-start time — different timing, different anti-patterns, shared discipline of "verify against canonical source before acting" |
| Procedure 1 (Release Kickoff Scaffolding) | If 0b detects an unscaffolded release (no per-issue sub-tasks per Resume Procedure Step 5), Procedure 1 fires next; if 0b detects a scaffolded release with pending approvals (Step 7), hub surfaces those BEFORE any new routing per the Procedure 0b resume contract |
| Procedure 2 (Routing) | 0b's output ("Hub session start" Decision Briefing) feeds the routing recommendation — pending approvals route first per § 7 contract |

**Transitional posture (hub → skill):** This binding survives the eventual hub-to-skill replacement. When `release-planner`, `principal-engineer`, or any future decision-producing skill assumes hub responsibilities, the skill imports `hub-session-continuity.md` directly per the standard's `consumers` field. The cross-reference paragraph above remains as archival evidence of where the binding fired during the hub era.

---

### Procedure 1: Release Kickoff (Scaffolding)

**Trigger:** Release plan from Procedure 0 is approved by operator.

**Rigor-Invariance Principle (scaffolding selects tasks; it never attenuates rigor).** A work-item scaffold determines WHICH tasks exist; it MUST NOT determine the rigor with which any task's codified Phase checklist is reviewed or verified. Every codified Phase step (e.g. `pipeline/stage-12-execute.md` Phase B5.5 Surface-1 emit, `pipeline/stage-13-close.md` Phase B5.6 verify + the Procedure 7 Step 4 completion-verification table) runs whether or not the scaffolded sub-task body names it, and whether the stage runs as a spawned spoke or hub-direct. A sub-task body that paraphrases — rather than binds to — the canonical Phase checklist is therefore a scaffold abbreviation only, never a license to drop a codified step. Two mechanisms enforce this invariant so it does not depend on the hub remembering it: (1) **bind-by-reference** — every sub-task body cites its canonical stage-spec Phase checklist and carries a canonical-checklist attestation (Sub-Task Template below); (2) **the scaffold-independent completion gate** — `deploy.sh --check` Check 48 (the `--check-close-completeness` CI probe) asserts the complete Step 4 output-set on main for every `VERIFIED` `RELEASE_LOG` row, firing with no scaffold, no sub-task body, and no hub session in the loop. The gate is the machine backstop; the attestation is the human-readable forcing function — neither alone is the sole control.

**Hub-direct ≡ spoke (execution-path-agnostic rigor).** Whether a stage is executed by a spawned spoke or run hub-direct, it binds to the **identical** canonical Phase checklist (per the bind-by-reference rule above). Hub-direct execution is NOT an abbreviated path: collapsing stages (e.g. a "combined Stage 12+13" run) does not waive any codified Phase step of either stage, and a hub-direct run is held to the same completion gate (Check 48 is execution-path-agnostic — it reads main's state, not the execution path that produced it). This generalizes the merge-ahead clause in Procedure 7 ("operator direct-merge does NOT waive the close outputs") from the merge-ahead case to **all** hub-direct execution.

**Steps:**
1. Read the approved release plan (Stage 4 spoke output on the release planning sub-task)
2. For each OPEN issue, use the release plan's stage applicability matrix to determine which stages apply:
   - Default: Stages 5-13 (Stage 4 is already complete at release level)
   - Skip Solutioning (Stage 5) per the release plan's applicability determination
   - Skip Dev Testing / QA (Stages 7-8) per the release plan's applicability determination
2.5. **Release Class read.** Read Release Class from the milestone description `## Release Class` H2 section (declared at Stage 3 Phase B3 per [release-class-taxonomy.md](../specs/release-class-taxonomy.md)). Surface the class + differentiation posture (engagement density / Stage 9 review depth / OPTIONAL Stage 5 activation bias / OPTIONAL Stage 13 outcome-window) in the scaffolding-summary Decision Briefing presented to operator. The per-class engagement-density recommendation informs the cadence of subsequent spoke-completion briefings (Tight / Standard / Light per the Per-Class Mapping table). Cutover discipline: applies to all releases going forward.
3. For each CLOSED issue, determine if gap review is needed (was the work done before this formal process existed?)
4. Create one sub-task per stage per issue (both applicable and skipped) using the Sub-Task Template below
5. For each skipped stage (per the applicability matrix), immediately close its sub-task with a skip closure comment using the Skip Closure Format below. Do not generate spoke prompts for skipped sub-tasks.
6. Sequence remaining (applicable) sub-tasks per the release plan's implementation sequence

**Stage 12 + Stage 13 chore-PR scope:** The Stage 12 sub-task scope INCLUDES the Stage 12 chore PR for RELEASE_LOG row + visible-H4 Deployment Log (per [`pipeline/stage-12-execute.md § Phase B5 commit mechanism`](../pipeline/stage-12-execute.md)). The Stage 13 sub-task scope INCLUDES the Stage 13 chore PR for INDEX + DIGEST + RELEASE_NOTES + RELEASE_LOG `VERIFIED` transition (per [`pipeline/stage-13-close.md § Phase B commit mechanism`](../pipeline/stage-13-close.md)). Chore PRs are operational sub-steps within the existing sub-task scope; they do NOT require separate sub-tasks.

7. Present the full scaffolding to the operator for review — include the list of skipped sub-tasks with rationale in the scaffolding summary

**Sub-Task Template:**

Hub: before creating each sub-task, resolve `{PARENT_STATUS_LABEL}` = the parent issue's current `status:` label via `gh issue view {ISSUE_NUMBER} --json labels` at scaffold time, and stamp it on the `Label:` line below alongside `sub-task` (mirror the parent's lifecycle position at creation — a point-in-time snapshot, not auto-resynced on later parent transitions; per [label-taxonomy.md](../../../core/specs/label-taxonomy.md) Rule 6).

```
Title: Stage {N} {Name} — #{ISSUE_NUMBER} ({MILESTONE})
Label: sub-task, {PARENT_STATUS_LABEL}
Body:

## Stage {N} {Stage Name}
**Parent:** #{ISSUE_NUMBER}
**Milestone:** {MILESTONE}
**Release Plan:** `release/releases/plans/vX.Y_RELEASE_PLAN.md` — under single-branch topology, on the release branch (committed at Engineering Commit 0; pre-Engineering: Stage 4 sub-task comment). Under Option-A topology, on main (committed via Stage 4 release-plan chore PR before per-issue sub-task scaffolding; see Procedure 0 § Canonical location).
**Persona:** {PERSONA_NAME} ({SKILLS_MAP_REF})

### Stage Definition
Per pipeline/stage-{NN}-{name}.md:
- Purpose: {COPY FROM PIPELINE_STAGES}
- Inputs: {COPY FROM PIPELINE_STAGES}
- Outputs: {COPY FROM PIPELINE_STAGES}
**Canonical checklist (bind-by-reference):** This sub-task is bound to the canonical Phase checklist in `pipeline/stage-{NN}-{name}.md` §{Phase range}. Execute every codified Phase step there; this body never narrows it. The Purpose/Inputs/Outputs above are stage metadata, NOT the checklist — the stage spec's Phase steps are authoritative, and a step absent from this body is still in scope (Rigor-Invariance Principle, Procedure 1). [Full transcription of the Phase checklist into this body is the permitted alternative to binding-by-reference; binding is the default — it cannot drift from the spec.]

### Instructions
{STAGE_SPECIFIC_INSTRUCTIONS — what the spoke should do for THIS
issue at THIS stage, informed by the issue body and prior stage output}

### Output
Post output as a comment on THIS sub-task using the format:
## Stage {N} {Stage Name} — {MILESTONE}
### Summary (30 seconds)
### Detail
### Evidence
### Output for Stage {NEXT_STAGE}
**Canonical-checklist attestation:** every codified Phase step in `pipeline/stage-{NN}-{name}.md` §{Phase range} ran, or is explicitly recorded N/A-with-reason. (This attestation is the spoke-side forcing function for the Rigor-Invariance Principle; the scaffold-independent completion gate — Check 48 — is the machine backstop.)

Close this sub-task when output is posted and reviewed by operator.
```

**Skip Closure Format:**

When closing a skipped sub-task in Step 5 above, post this comment before closing:

> **Skipped** per Stage 4 applicability matrix.
> **Rationale:** {reason from matrix, e.g., "Documentation-only change — no functional impact to test"}
> **Release plan:** #{PLANNING_SUB_TASK_NUMBER}

### Procedure 2: Routing (What's Next)

**Trigger:** Operator asks "what's next?" or a spoke completes.

**Hub-direct ≡ spoke (routing mirror).** When routing elects to run a stage hub-direct instead of spawning a spoke (a permitted choice), the hub-direct run binds to the **identical** canonical Phase checklist the spoke would have — see the Hub-Direct ≡ spoke equivalence clause in Procedure 1. Hub-direct is a spawn-vs-inline choice, never a rigor choice; the completion gate (Check 48) is execution-path-agnostic.

**Steps:**
1. List all sub-tasks across all issues in the Milestone
2. Identify sub-tasks that are OPEN and whose dependencies are met:
   - Stage N+1 depends on Stage N being closed for the SAME issue
   - Cross-issue dependencies: check if any issue's stage depends on another issue's stage
   - If a sub-task is blocked because it needs another issue's changes on main (not just on the release branch), recommend early merge (Procedure 6) if the upstream issue's per-issue stages are complete

   **Surface only the actionable subset — never chip an unmet dependency.** A sub-task whose declared cross-stage / cross-issue dependency is still OPEN is **not actionable**: do not surface a chip for it. Wait for the dependency to close, then surface the previously-blocked chip on the next routing pass. Do NOT route the chip anyway and hand the dependency check to the spoke via a "wait if the dependency is still open, post a status note and pause" session-start instruction — that outsources dependency discipline to the spoke and overrides this step. Even a disciplined spoke that honors the check produces a "paused" output requiring a re-spawn; sequential routing is cheaper end-to-end (the cost of waiting one routing pass is negligible against the cost of a non-actionable chip). If a chip prompt would need a "wait if dependency open" check, that is the signal the dependency is unmet and the chip should not exist yet. **Exception:** an explicit operator instruction to pre-stage blocked work (e.g., "spawn both anyway, I want the prep staged") overrides this; absent that, follow this step.
3. **Collective review check:** Before routing any Engineering (Stage 6) sub-tasks, check whether the collective review protocol applies. If the release has ≥2 issues with Solutioning activated (per Stage 4 applicability matrix) AND all applicable Solutioning sub-tasks are now closed, trigger the collective review before routing to Engineering. Produce a consolidated Decision Briefing per the Collective Review Protocol (`release/governance/release-process.md`). Engineering sub-tasks are not actionable until the operator renders the scope lock decision. If the collective review has already been completed for this release, skip this check.
4. **Action-item scan (per [`hub-action-tracking.md` § 4 routing point 2](../../../core/standards/hub-action-tracking.md)):** Read `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md` if present; scan for `status:open` rows with `trigger_type:event` or `trigger_type:cross-issue-merge` whose `trigger_detail` predicate matches current GitHub state. Surface triggered rows in the Decision Briefing per the Operating Principle "Action items surfaced this routing point" subsection format; operator MAY elect to route the action item ahead of pipeline work.
5. Present the next actionable sub-task(s) to the operator, applying the parallelism rules below.

   #### Parallelism Rules per Stage

   | Stage | Parallel-actionable across issues? | Mechanism | Rationale |
   |---|---|---|---|
   | **5 Solutioning** | YES — parallel-safe | Spokes post sub-task comments only; no commit/file write on release branch or main | Output channel is GitHub Issue comment — no contention surface. Multiple Stage 5 chips may run concurrently across issues; Collective Review fires after ALL close. Subject to the per-account 5-hour usage-window envelope — concurrent spokes draw **cumulatively** against the remaining window even though the output channel has no file-contention surface; see § Per-Account Usage Window Constraint for quota-budgeting / window-aware-timing / serialize-on-failure mitigation |
   | **6 Engineering** | NO — write-serialized | Hub Procedure 2 routes ONE Engineering chip at a time per release plan's Implementation Sequence | Under D-C SINGLE topology, every Engineering commit lands on `release/vX.Y` sequentially; concurrent chips race on branch HEAD. File-disjoint commits still serialize at git's push level. Under D-C OPTION-A (per-issue branches), parallel commits are mechanically permitted but contention shifts to PR-merge order at Stage 12 — same effective serialization, different surface |
   | **7 Dev Testing / 8 QA Testing** | YES — parallel-safe | Spokes post sub-task comments + structured Handoff Payloads; no PR mutation, no main mutation | Review-only output. DT↔Engineering iteration loop and DT↔QA handoff carry routing context in comment thread — read-only against PR diff and committed evidence |
   | **13 Close** | NO — write-serialized | Single Close chip per release; release-corpus mutations (`RELEASE_LOG.md` row + visible-H4 Deployment Log + `RELEASE_INDEX.md` + `RELEASE_DIGEST.md` + `RELEASE_NOTES`) bundle into ONE Stage 13 chore PR | All mutations land on main via one chore PR; Milestone close is hub Tier-1 per Standing-GO Authorization Model; structurally serial — no axis of parallelism within Close |

   **Release-scoped stages omitted from the table by design:** Stage 4 (Planning), Stage 9 (Plan Review — gate, no spoke), Stage 12 (Execute) each run as a single per-release spoke/gate; there is no cross-issue parallelism axis at these stages, so they do not need an explicit rule. The table covers the per-issue stages (5/6/7/8) plus Close (release-scoped but with internal-mutation serialization concerns).

   **Parallel-safe is coordination semantics, not usage-window semantics (orthogonality note).** "Parallel-safe" in the table above is a *coordination*/file-contention property — it means the stage's output channel has no shared write surface, so concurrent spokes do not race on a commit or file. It is **orthogonal** to the per-account 5-hour usage-window envelope: concurrent Agent-tool spokes still draw *cumulatively* against the shared usage window even when they have no file-contention surface (see § Per-Account Usage Window Constraint). The two gates compose — a stage marked parallel-safe here may still require SERIALIZE / DEFER / REDUCE-scope under the usage-window gate (Step 5.5 below). Do not read "parallel-safe" as "usage-window-free."

   #### Step 5.5: Quota check before parallel launch

   Before issuing N parallel Agent invocations in the same hub response (the parallel-safe stages 5 / 7 / 8 above), the hub runs **Checkpoint B** of the quota-budget protocol ([`../standards/quota-budget-protocol.md`](../standards/quota-budget-protocol.md) § 4) against the *remaining* per-account 5-hour usage-window envelope. This is the load-bearing, ongoing check — it fires before *every* parallel wave, not once at Stage 4, because each wave (Stage 5 batch / Stage 7 batch / Stage 8 batch) faces a potentially different remaining envelope (mid-release quota drift; 5-hour boundary crosses; per-spoke costs varying from the Stage 4 baseline).

   The hub computes `N_planned × per-spoke-cost-estimate` (Checkpoint A baseline refined by observed per-spoke actuals from prior waves this release) and compares it against the remaining envelope (operator-stated state at hub start, adjusted for elapsed-window time and any per-batch override — see the protocol § 6), then renders one verdict on the usage-window axis:

   | Verdict | Hub action |
   |---|---|
   | **PROCEED** | Launch all N in parallel (existing behavior) |
   | **SERIALIZE** | Launch one spoke at a time, halt on first usage-limit failure (reduces simultaneous-draw count) |
   | **DEFER** | Hold the batch for the next window; surface a reset-time estimate (reduces cumulative draw entirely) |
   | **REDUCE-scope** | Launch with a smaller per-wave footprint — compact prompts, narrower scope, fewer canonical reads (reduces per-wave consumption) |

   On **SERIALIZE / DEFER / REDUCE-scope**, the hub produces a Decision Briefing surfacing the verdict + recommendation to the operator **BEFORE** launching any spoke in the wave. **STAGGER** (an in-prompt `sleep` stagger) is a *labeled secondary* rate-limit-only defense — it does not change cumulative consumption and is never the mitigation for a usage-window overrun (§ Per-Account Usage Window Constraint).

   On **DEFER**, the hub offers the operator an explicit **override-to-PROCEED exit** — the escape hatch for a wrong-stated-envelope deadlock. The override is operator-initiated (the hub renders DEFER as *recommended*; the operator chooses to override), is **deviation-logged** as a recorded auditable choice, and is a one-batch exit (it does not reopen the gate at every wave). When DEFER holds, the hub MAY emit an action-item entry per [`../../../core/standards/hub-action-tracking.md`](../../../core/standards/hub-action-tracking.md) (e.g., "Resume Stage N batch after window-reset at HH:MM") so the deferred batch is tracked and resumed.

   **Ongoing-gate discipline.** This check is a standing pre-launch step for every parallel wave, not a one-time Stage 4 estimate — running it once and treating the batch as cleared for the whole release is the failure mode the runtime checkpoint exists to prevent. **No Autonomy-Tier downgrade.** The verdict is a decision about *whether and when* to launch a batch; it does not reclassify the parallel-safe stages' Autonomy Tier (Stage 5 / 7 / 8 remain auto-launch). **Cutover:** applies to releases entering the pipeline on or after this gate's introducing-release merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>); the introducing release itself is exempt (the gate cannot fire on the release that introduces it).

   #### File-contention boundary rules

   The blocker boundary depends on the D-C topology selected by Stage 4:

   | Topology | Blocker boundary | Detection point | Mitigation |
   |---|---|---|---|
   | **D-C SINGLE** (default) | **FILE** — any file touched by any in-flight Engineering chip blocks the next Engineering chip until prior commit lands on `release/vX.Y` | Hub Procedure 2 routing reads release plan's Contention Map; refuses to surface concurrent Engineering chips touching the same file (or, under heavy contention, any file at all) | Sequence per Implementation Sequence; append-pattern files (per ADR-005 `overlap_class`) have lower commit-order risk but still serialize at commit/push |
   | **D-C OPTION-A** | **PR merge order** — per-issue branches isolate commit-time writes; contention surfaces at `gh pr merge` of two PRs touching overlapping line ranges | Stage 4 cross-PR overlap audit (per `release-process.md` § Cross-PR Overlap Audit + ADR-005 append-pattern detection) identifies pairs; Stage 12 Phase B0 dependent-PR check  + Phase A.6 polling  catch unresolved cases at merge time | Sequence PR merges per Procedure 6 Early Merge; base-shift dependents ( Option A) before parent merge |

   **"Shared section" is NOT the relevant boundary.** Git's merge mechanics operate at file content (line-level diff), not at conceptual section/heading boundaries. Two Engineering chips editing disjoint sections of the same `hub-spoke-bridge.md` under SINGLE topology still produce commit-sequential writes — the second chip's `git fetch && git checkout release/vX.Y` plus rebase/merge against the first's commit is the actual serialization mechanism, not a section-level diff comparison.

   **ADR-005 composability:** `overlap_class` enrichment (`append-pattern` / `line-range-overlap` / `single-pr`) informs sequencing risk assessment — not the parallelism rule. An append-pattern file in the release Contention Map signals low merge-conflict risk if commit order is preserved; but concurrent commits still race on push regardless of `overlap_class`. The table above treats topology as the primary axis and ADR-005 as a refinement consumed at Stage 4 (Bundle / Planning) to inform sequencing, not at Procedure 2 routing.

   #### Engineering serialization mechanism

   | Source | Role |
   |---|---|
   | **Stage 4 Release Plan § Implementation Sequence** | Canonical Engineering execution order. The hub treats this section as the authoritative ordering for Stage 6 chip routing |
   | **Stage 4 Release Plan § Contention Map** | Authoritative file-overlap surface. The hub reads this to confirm which files each Engineering chip will touch before routing |
   | **Hub Procedure 2 (Routing)** | Reads Implementation Sequence; identifies the next Engineering sub-task whose dependencies are met (per existing Step 2); presents ONE chip at a time |
   | **Engineering chip prompt Worktree Discipline** (`hub-spoke-bridge.md` Procedure 3) | Already prescribes `git fetch origin release/<milestone> && git checkout release/<milestone>` — implicit "wait for prior commit to land" assumption |
   | **Spoke completion (Procedure 4)** | Hub confirms commit landed on `release/vX.Y` (sub-task closed + commit visible via `git log origin/release/<milestone>`) before routing next Engineering chip |

   **Override-by-spoke detection:** A spoke proceeding when a prior commit has not yet landed produces stale-base or `non-fast-forward` push errors. The Worktree Discipline's `git fetch origin release/<milestone>` step surfaces this at chip-startup time. Hub Procedure 4 spoke-completion handling checks PR/branch state before declaring the sub-task closed; if spoke output shows stale-base symptoms, hub routes to remediation (operator notification + re-run chip after prior commit lands).

   **Hub instruction (operative form):** For Stage 6 Engineering sub-tasks, the hub surfaces one chip at a time, in the order specified by the release plan's Implementation Sequence. The hub does NOT present multiple Engineering chips in parallel under D-C SINGLE topology, regardless of whether the chips touch disjoint files. Under D-C OPTION-A topology, parallel Engineering chips are permitted (one per branch); the hub surfaces PR-merge sequencing decisions at Stage 12 per Procedure 6.

   **Cutover discipline:** Applies to all releases going forward.

### Procedure 3: Spoke Prompt Generation

**Trigger:** Operator asks for a spoke prompt for a specific sub-task.

**Note:** Stage 4 (Release Planning) uses its own template in Procedure 0. This procedure handles Stages 5-13.

**Steps:**
1. Verify the sub-task is open and not marked as skipped. If the sub-task was closed with a skip closure comment (see Procedure 1, Step 5), inform the operator that this stage was skipped — do not generate a spoke prompt.
2. Read the sub-task body for stage instructions
3. Read the persona card from `release/references/specs/release-personas.md` for the matching stage
4. Generate the spoke prompt using the Spoke Template below
5. Embed the full persona card (behavioral markers + anti-patterns) in the prompt
6. Review completed spoke outputs across the release for findings relevant to this spoke's issue. Inject cross-issue context into `{ADDITIONAL_READS}` when applicable (e.g., a DT finding on a related issue that this spoke should be aware of)
7. Invoke the Agent tool per the Spoke Launch Mechanisms § Default subsection (`Agent({subagent_type, prompt, description, model, isolation, run_in_background})`). After invocation, print a brief acknowledgement: *"Hub auto-launches the spoke within authorized scope; awaits result inline (Stage {N} {Name} — #{ISSUE})."* If a fallback condition applies (see subsection), print the prompt for the operator to copy instead.

**Worktree discipline (engineering + content-modifying spokes):**

The Agent tool's `isolation: "worktree"` parameter (per Spoke Launch Mechanisms § Default) creates an isolated git worktree as the spoke's working directory. The harness spawns the worktree at session-start, returns the path + branch in the result if the spoke makes changes, and auto-cleans the worktree if the spoke makes no changes. Engineering spoke prompts (Stage 6) MUST instruct the spoke to operate in that working directory directly.

**The single prohibition is a *nested* worktree — a worktree created *inside* the spoke's session worktree.** The session worktree IS the isolation mechanism; nesting another worktree inside it duplicates the abstraction without adding isolation, and the inner worktree is left orphaned when the harness cleans up the session worktree at session end. The orphan still appears in `git worktree list` (until `git worktree prune` runs) and still holds a lock on its branch, blocking subsequent spoke launches that need the same release branch. A spoke prompt MUST NOT instruct the spoke to create a worktree-inside-a-worktree.

**Do NOT, however, blanket-forbid all `git worktree add`, and do NOT assert the spoke's git location.** The spoke's landing point is not guaranteed to be an isolated worktree — a spawned spoke can land in the primary checkout on the default branch instead. The spoke prompt therefore instructs the spoke to **detect first**, then act:

- Detect the working tree via `git rev-parse --show-toplevel`.
- If in the primary checkout → create an isolated worktree and `cd` into it before any branch work.
- If already in an isolated session worktree → operate in it directly; do NOT create a nested worktree.

This branch-on-detection rule replaces any blanket "never run `git worktree add`" phrasing: the prohibition is scoped to the nested case, not to the command.

Canonical patterns to embed in Stage 6 spoke prompts:

- **First commit on a new release branch** (no branch yet on origin): `git checkout -b release/<milestone> main && git push -u origin release/<milestone>`, then `git checkout --detach` at session end to release the branch lock.
- **Subsequent commits on an existing release branch**: `git fetch origin release/<milestone> && git checkout release/<milestone>`, then `git checkout --detach` at session end.

If a prior Agent invocation's spoke created a nested worktree (visible in `git worktree list` with the `prunable` flag — typically because an earlier spoke prompt instructed `git worktree add`), run `git worktree prune` from the primary before issuing the next Agent invocation.

See Procedure 2 Step 5 Parallelism Rules for the routing-time companion to this spoke-prompt-time discipline.

This discipline emerged from C1 routing (2026-04-25), where a chip prompt instructed `git worktree add` and the resulting nested worktree blocked the next C-chip until manual prune. Memorialized to prevent recurrence across future milestones, fresh hub sessions in separate chats, AND the Agent-tool orchestration era. The semantic preservation is intentional: the discipline binds to the worktree-isolation primitive (whether surfaced via chip-launch or the Agent tool's `isolation: "worktree"` parameter), not to the specific invocation mechanism.

**Cutover discipline:** Applies to all releases going forward.

**PR Body Parser-Clean Discipline (engineering spokes):**

The `gh pr create` invocation submits a PR body that GitHub's auto-close parser scans
lexically. Close-family verbs (`close`, `closes`, `closed`, `fix`, `fixes`, `fixed`,
`resolve`, `resolves`, `resolved`) followed by `#N` trigger auto-close regardless of
section context or surrounding negation. The PR body template
(`.github/PULL_REQUEST_TEMPLATE.md`) provides exactly one dedicated **Issue References**
block at the bottom for these phrases; every other section uses safe phrasing.

Stage 6 chip prompts MUST instruct the spoke to run this self-check before
`gh pr create`:

```bash
grep -inE "(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) +#?\[?[0-9]" \
  <pr-body-draft>
```

Any match outside the dedicated Issue References block requires rewrite. Safe-phrasing
replacements:
- `close #N` / `closes #N` → `mark #N as closed` / `transition #N to closed` /
  `#N → Closed` / `Issue #N closes at Stage 13`
- `fixes #N` → `addresses #N` / `corrects the regression in #N` (note: do not write
  `resolves #N`)
- `resolves #N` → `completes the work on #N` / `wraps up the task in #N`

This discipline emerged from a PR (2026-05-03), where the Summary section
correctly used `References ` per the D-Stage13Successor block-close protocol, but
the test-plan section contained `Stage 13 Close: ... + close  + ...` — the parser
matched the test-plan token and auto-closed  one second before the merge timestamp,
preempting the operator-decision-style block-close ordering. Confirmed pattern:
the PR-body close-keyword discipline (N=2 with prior-PR precedent on 2026-04-25).

For Stage 6 chips specifically, hub adds to `{ADDITIONAL_READS}`:
- `6. .github/PULL_REQUEST_TEMPLATE.md (PR body skeleton — note the dedicated Issue References block)`
- `7. release/references/how-to/hub-spoke-bridge.md § Procedure 3 §PR Body Parser-Clean Discipline (self-check command + safe-phrasing rules)`

The Spoke Template scope-control section gains an explicit bullet:

- Before `gh pr create`, run the parser-clean self-check (per
  `hub-spoke-bridge.md` Procedure 3 §PR Body Parser-Clean Discipline).
  Any close-family verb + `#N` match outside the dedicated Issue References
  block must be rewritten before PR creation.

**Block-close protocol consumers** (D-Stage13Successor and any analogue D-decision that
relies on manual closure timing at Stage 13) carry this as an explicit pre-condition:
**"PR body must be parser-clean — close-family verbs + `#N` confined to the dedicated
Issue References block."** Without parser-clean PR bodies, the auto-close fires at merge
time and preempts the block-close protocol. This is the canonical pre-condition
statement; future D-decision authors cite this section when their D-decision relies on
manual closure timing.

**Repo-Integrity Authoring Discipline (ADR + content-modifying spokes):**

A spoke that authors or edits a durable-corpus markdown file — an
`core/ADRs/ADR-NNN-*.md`, a skill `SKILL.md`, a `references/*.md`, a governance or
standards doc — has its changed files scanned by two PR-time gates in
`repo-integrity.yml` (defined in [`core/rules/git-workflow.md` § Repository-Integrity
Gates](../../../core/rules/git-workflow.md)): the **Issue-reference validity** gate
and the **Depersonalization** gate. These are SEPARATE from, and broader than, the
PR-body close-parser discipline above — they scan file *content*, not the PR body.
ADR files are the common tripwire because they carry `#N` in `source_observations:`
frontmatter and `## Status` / `## Context` provenance prose — out-of-reference-block
locations. The discipline (apply at authoring time, not after red CI):

- **Author every issue cross-reference as bare `#N`, never a full
  `github.com/.../issues/N` URL.** The full URL embeds the operator handle (trips
  Depersonalization) and rots on repo move; bare `#N` clears both the depersonalization
  and the issue-ref gates in one move.
- **Declare the file-level marker once** near the top of any ADR/skill file that
  carries a bare `#N` outside a recognized reference block (`### Issue References` /
  `### References` / `## Related` / `## Provenance` / `### Source(s)`): an HTML comment
  reading `repo-integrity: allow-issue-ref`, placed after the frontmatter / before the
  title. (`## Related ADRs` is not the recognized `## Related` slug — use the marker,
  not heading placement.)
- This composes with the reference-durability discipline (`git-workflow.md` §
  Reference Durability): the durability marker family (`allow-url`) and self-describing
  prose are the durability twin of the integrity marker.
- **Durable-corpus de-fragile pre-check (apply at authoring time).** Beyond the
  bare-`#N` rule above, a spoke authoring durable-corpus `.md` must avoid the
  fragile constructs the reference-durability gate flags BEFORE the first write:
  (1) no numeric section-anchor deep-links (a `file.md` link whose fragment is a
  numbered-heading anchor) — use a plain file link plus the section named in prose,
  so a re-heading does not rot the reference; (2) spell out checklist-item
  references in prose ("criterion 3", "the third rung") rather than a hash-prefixed
  positional number, so the reference survives a renumber of the list; (3) avoid
  hash-prefixed example numbers in prose (write "for example, an issue" rather than
  a literal instance) — the detector strips fenced code blocks but NOT inline code
  spans, so a hash-prefixed number is flagged even inside single-backtick spans;
  name the construct in words. Note the gate's positional issue-reference rule has
  **no per-construct override marker**: the `allow-link` / `allow-version-ref` /
  `allow-url` markers suppress their own classes, but a bare issue reference
  appearing OUTSIDE a recognized reference block has no escape marker — the only
  fix is to rewrite it inline (move it into a reference block with a summary, or
  de-reference it in prose). The full author-time check set is in
  [`reference-durability-standard.md` § Authoring around the gate](../../../core/standards/reference-durability-standard.md).

For ADR-authoring and skill-authoring chips specifically, hub adds to
`{ADDITIONAL_READS}`:
- `core/ADRs/README.md § Repo-integrity authoring discipline (bare #N + allow-issue-ref marker, never full URLs)`
- `core/rules/git-workflow.md § Repository-Integrity Gates (the two gates + override markers)`

The Spoke Template scope-control section gains an explicit bullet for these chips:
- When authoring or editing any `core/ADRs/*.md`, `SKILL.md`, or `references/*.md`
  file, reference issues as bare `#N` (never a full GitHub URL) and declare the
  file-level `repo-integrity: allow-issue-ref` marker after the frontmatter. Apply
  this at authoring time — do not wait for a red CI run.

This codifies the discipline ADR-016's red-CI failure surfaced (#426): the ADR
tripped both the issue-reference-validity and depersonalization gates with full
GitHub URLs + out-of-block `#N`, was fixed reactively, and left no up-front guidance.
8 of the repo's ADRs now carry the marker by trial-and-error — this makes the rule
explicit so the next spoke applies it first.

**Cutover discipline:** Applies to all releases going forward.

**Chip Prompt Spec-Anchor Discipline:**

When a chip prompt references a canonical source spec (parent issue, governance file, release plan, pipeline shard, standards doc), the chip prompt MUST direct the spoke to read the source DIRECTLY rather than embedding a hub-summary of the source content. Hub summaries are snapshots of hub understanding at chip-launch time; canonical sources remain authoritative as governance evolves between chip-launch and spoke-execution. When the snapshot diverges from the source — even subtly — the spoke produces work consistent with the snapshot, not the source.

Operationally, chip prompts use structure like:

```
Read CANONICAL SOURCE SPECS directly — do not rely on summaries.
[Spec 1 with link] is canonical for [scope 1].
[Spec 2 with link] is canonical for [scope 2].
```

rather than embedding spec content inline as paraphrased prose. The hub MAY include orientation summaries (release context, sub-task background) but MUST NOT substitute its summary for the canonical source on scope-defining content (acceptance criteria, schemas, protocols, gate criteria, applicability rules).

**Applicability:** Required for canonical source specs (issue spec, governance file, release plan, pipeline shard, standards doc). NOT required for transient references (status reads, recent commit citations) where summary IS the content.

**Spec types covered:**
- Parent issue body (`gh issue view #N`)
- Governance files under `core/governance/` and `core/`
- Release plans under `release/releases/plans/`
- Pipeline shards under `release/references/pipeline/stage-NN-*.md`
- Standards docs under `core/standards/`
- Mirror-pair `core/rules/` files

**Worked examples (operational use):**

- This very chip prompt for  (Stage 6 Engineering — ): explicit `"Read CANONICAL SOURCE SPECS directly — do not rely on summaries."` with 11 enumerated read-list items each citing canonical source (parent issue, sub-task body, Stage 5 spec, sister sub-task, scope-lock review, PR metadata, target files, pipeline shard).
- Sister Stage 5 / Stage 6 chip prompts: same discipline applied.
- Audit chip prompts for E2 / E3 / E4 (the originating HUB-DISCIPLINE CORRECTION instances per the DT-1 Pass 1 finding): explicit `"Read CANONICAL SOURCE SPECS directly... Stage 5 main 3-part series + closure are canonical for rubric, classification, frame application, hand-off schemas, D4/D5 augmentations, path D-Gate decisions."`

**Sister surface — recommendation construction:** [Procedure 0a — Audit-Aware Orientation](#procedure-0a--audit-aware-orientation-cross-reference) in this same file covers the parallel surface for hub recommendations derived from analysis artifacts. Both surfaces share the same root failure mode (`snapshot-as-current-state`) per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) § Hub-spoke chip-prompt examples. Per-surface specificity is intentional: chip-prompt-construction (this discipline) operates at spoke-launch time; recommendation-construction (Procedure 0a) operates at briefing time. Two operating contexts, two anti-patterns. Canonical mitigation home for both: [`decision-discipline.md` § 2.1.1 Sub-mechanism — Audit-Snapshot Reconciliation](../../../core/disciplines/decision-discipline.md).

**Cutover discipline:** Applies to all releases going forward.

**Chip Prompt Arithmetic Discipline:**

When the hub authors a chip prompt that enumerates a count or sum of items derived from multiple sources (acceptance criteria across an issue body + sibling-issue body + milestone deliverable description; sub-task count across a release; row count for a verification table; etc.), the chip prompt MUST follow one of two patterns. Embedding pre-computed arithmetic without verification creates spoke-side reconciliation overhead AND risks the spoke proceeding with the wrong number when the verification step happens to be skipped.

**Preferred pattern — derivation logic:** Chip prompts reference the derivation logic, not a pre-computed sum.

- ❌ Bad: *"Build a verification table with 14 rows: 11 ACs from issue body A + 3 ACs from issue body B + 4 deliverable ACs from the milestone description."* (11 + 3 + 4 = 18, not 14 — discrepancy embedded into the prompt)
- ✅ Good: *"Build a per-AC verification table with one row per AC. Source ACs from issue body A, issue body B, and the milestone description deliverables. Verify the row count matches the actual AC count derived from these sources."* (no pre-computed sum to drift)

**Fallback — verify before issuance:** If the chip prompt embeds a count or sum (e.g., for spoke-side gate-checking or estimation), the hub MUST verify the count by running the derivation against the actual sources BEFORE prompt issuance. State the verified sum with the derivation cited:

- *"Build a verification table with 18 rows: 11 ACs from issue body A + 3 ACs from issue body B + 4 deliverable ACs from the milestone description (derivation verified at chip-authoring time; reproduce via `gh issue view <N>` AC count + `gh api repos/.../milestones/<N>` deliverable count)."*

If the hub cannot verify the count at chip-authoring time (sources are external, live, or behind a gate the hub cannot read), the chip prompt MUST mark the count explicitly as approximate and direct the spoke to verify:

- *"Build a verification table with ~14 rows (approximate; spoke verifies actual count from the issue bodies and the milestone description)."*

This discipline emerged from Finding F-01 (2026-05-02), where the hub-authored chip prompt for Stage 6 Engineering Pass 1 contained: *"Build a single table with 14 rows: 11 ACs from issue body A + 3 ACs from issue body B + 4 deliverable ACs from the milestone description"* — sum is 18, not 14. Sub-task instruction body separately stated *"11 ACs for issue A + 4 rows for issue B deliverable ACs"* = 15 rows (Finding F-02). Both numbers diverged from arithmetic. Engineering Pass 1 spoke handled gracefully (chose comprehensive 18-row coverage, flagged for operator at Stage 9) — but reconciliation overhead consumed Engineering attention. The codification of this preferred-pattern + fallback as the canonical chip-authoring rule applies going forward.

**Sister surfaces (same hub-orchestration root class, distinct failure mechanism):**
- `Chip Prompt Spec-Anchor Discipline` (this file, above) — chip-prompt embeds a *summary* of canonical-source content (snapshot-as-current-state); spoke trusts the snapshot when the source has drifted.
- `Audit snapshot as current state` (per [`failure-mode-standard.md § Hub-spoke chip-prompt examples`](../../../core/standards/failure-mode-standard.md)) — recommendation-rendering surface variant of the same snapshot-divergence root pattern.
- This discipline (Chip Prompt Arithmetic Discipline) — chip-prompt embeds a *computation* of source enumerations; computation is wrong at authoring time (not drift over time). Distinct root mechanism: hub arithmetic error, not snapshot divergence. Cataloged as a 5-field failure-mode entry at [`failure-mode-standard.md § Chip-prompt embedded arithmetic without verification — INPUT`](../../../core/standards/failure-mode-standard.md).

**Cutover discipline:** Applies to all releases going forward.

**Chip Prompt Verbatim-Source Discipline:**

When the hub authors a chip prompt or sub-task body that references a parent issue — enumerating the parent's options, citing a sub-task number, or naming a routing target — the referencing content MUST be copied VERBATIM from the authoritative source: the parent issue body, the sub-task creation log, or the option list as written. The hub never paraphrases the parent's options into its own wording, and never reconstructs a sub-task number from a "first-in-batch" position heuristic (the assumption that the first sub-task created in a batch maps to the first parent option) — *first-in-batch is not the mapping.* Paraphrase silently drops or re-words an option the spoke then acts on as authoritative; a position-heuristic mis-routes a spoke to the wrong sub-task. Both produce work that is internally consistent but bound to the wrong parent intent. Resolve the mapping by reading the source, not by inferring it from creation order.

**Cutover discipline:** Applies to all releases going forward.

**Multi-Phase Work Uses Issues, Not Chat-Prompt Blocks:**

The default shape for multi-phase work is a new milestone plus one issue per phase — each issue body is the self-contained spoke contract for that phase, carried in durable GitHub state. The hub does NOT draft bespoke copy-paste prompt blocks in the chat thread as a parallel tracking surface for the phases: a chat-resident prompt block is ephemeral, un-queryable, and drifts out of sync with the issue state the moment either is edited. Two surfaces tracking the same work is the failure — the issue body is the single source of truth, and the spoke reads it directly. Exception: a genuinely small one-shot task (a single phase, no hand-off, no downstream consumer) does not warrant a milestone-and-issue scaffold and may run from an inline prompt — but the moment the work has ≥2 phases or a hand-off, it gets issues.

**Cutover discipline:** Applies to all releases going forward.

**Hook-Safe Chip Git Idioms:**

Because the `block-destructive` agent hook matches destructive-git substrings **lexically** in a Bash command string (it scans the literal text, not the parsed git semantics), a chip prompt MUST prescribe git idioms that do not present a destructive substring to the matcher even when the operation is safe:

- **Post issue and comment bodies via a Write-tool temp file + `gh api --input <file>`** (or `gh pr create --body-file` / `gh issue create --body-file`), never by inlining a large body into a `-f body=...` argument — a heredoc or inlined body can carry incidental substrings the lexical matcher trips on, and the temp-file path is also the parser-clean-friendly route.
- **Regenerate a branch with `git checkout -B <branch> origin/main` + `git push --force-with-lease`**, never `git reset --hard` or an unguarded `git push --force` — `checkout -B` re-points the branch without a destructive substring, and `--force-with-lease` is the safe lease-checked push the hook permits where bare `--force` is blocked.

This workaround is load-bearing because of the repo/worktree-session hook-load gap — the PreToolUse hooks that would otherwise enforce destructive-git safety do not load in a repo-rooted or worktree-rooted spoke session the way they do in a workspace-root session, so the lexical-block convention is the discipline the chip must carry explicitly rather than relying on the hook to fire.

**Cutover discipline:** Applies to all releases going forward.

**Stage 6 Chip Pattern — Concurrent-Spoke Contention Recovery:**

When two or more Stage 6 Engineering spokes commit to the SAME release branch in parallel, four git races surface. Each Engineering chip launched into a shared-branch parallel wave MUST enumerate the four detection→recovery procedures so the spoke recovers in-session rather than corrupting the branch. The default push idiom for an already-checked-out branch is the detached-HEAD refspec push `git push origin HEAD:refs/heads/<branch>` (it pushes the current commit to the named branch without requiring the local branch ref to track, sidestepping the checkout-conflict race):

| Race | Detection | Recovery |
|---|---|---|
| Concurrent rebase | `git push` rejected (non-fast-forward) because a sibling spoke's commit landed on the remote branch first | `git fetch origin <branch>` then `git rebase origin/<branch>` onto the sibling's commit; re-run the spoke's verification; push via `git push origin HEAD:refs/heads/<branch>` |
| Staging race | `git add` / `git commit` picks up a sibling's just-pulled changes mixed into the working tree | Stage only the spoke's own paths explicitly (`git add <specific-paths>`), never `git add -A`; verify `git status` shows only the intended files before commit |
| Partial staging | An interrupted or interleaved commit leaves a subset of the spoke's intended files staged while the rest are unstaged | Re-derive the intended file set from the spoke's File Change Matrix, `git add` the complete set explicitly, confirm `git diff --cached --name-only` matches the matrix, then commit |
| Branch-checkout conflict | `git checkout <branch>` fails because the worktree already has the branch checked out elsewhere, or the local branch ref diverges from the sibling-advanced remote | Do not re-checkout; push the current commit directly via the detached-HEAD refspec `git push origin HEAD:refs/heads/<branch>`, which writes to the remote branch without a local-ref checkout |

This pattern is complementary to — not contradictory with — the broader Stage-6 parallelism-postures work (which decides WHEN parallel same-branch commits are permitted at all); this card supplies the recovery procedures FOR the races that arise once they are.

**Cutover discipline:** Applies to all releases going forward.

**Stage 5 Mid-Solutioning Cross-Ticket Escalation Handler:**

When a Stage 5 Solutioning spoke posts a mid-Solutioning Tier 2 `[SCOPE CHANGE]` finding — emitted by the spoke's Phase 0.7 Mid-Spoke Cross-Ticket Scope Detection (per [`stage-05-solutioning.md` § Phase 0.7](../pipeline/stage-05-solutioning.md)) when its design surface overlaps a sibling ticket's concrete files or semantically duplicates a sibling — the hub does NOT silently fold or silently ignore it. The hub decides between two dispositions and surfaces the choice to the operator as a main-thread Decision Briefing item: **(a) expand-scope-now** — pull the overlapping sibling concern into the current spoke's design (when the overlap is tight enough that splitting would fragment one coherent design), or **(b) hold-for-Collective-Review** — record the overlap and defer the merge/split call to the release-level Collective Review scope-lock (when the overlap is real but the tickets remain separately deliverable). The spoke's escalation does NOT self-authorize either path — it is a finding routed up; the hub renders the disposition, and the operator approves at the briefing. This handler is the hub-side receiver for the spoke-side detection rule; the two compose (spoke detects and routes; hub decides and surfaces).

**Cutover discipline:** Applies to all releases going forward.

**Stage 12 Chip Pattern — Tag-SHA-Direct Discipline:**

When the hub authors a Stage 12 Execute chip prompt, the prompt MUST prescribe the tag-SHA-direct pattern (`gh pr merge` → `gh pr view --json mergeCommit.oid` → `git tag <name> <SHA>` → `git push origin <tag>`) for Phase B operations. The chip prompt MUST NOT include any instruction that requires `git checkout main` inside the chip-launched session worktree — that command conflicts with `core/rules/git-workflow.md` § Primary Checkout Discipline, which reserves the `main` branch checkout for the primary at `${HOME}/Claude/` and rejects worktree-side `git checkout main` (`'main' is already used by worktree at ...`). Tagging from the captured merge SHA produces identical functional outcome without requiring a worktree branch checkout.

Concrete bash exemplar block — Stage 12 chip prompts MUST embed this command sequence (or a structurally-equivalent variant) when instructing the spoke through Phase B:

```bash
# Phase B1 — Merge and capture SHA (per Phase B merge verification protocol)
gh pr merge <PR> --merge
MERGE_SHA=$(gh pr view <PR> --json state,mergeCommit \
  --jq 'select(.state == "MERGED" and .mergeCommit != null) | .mergeCommit.oid')

# Phase B3 — Signed-annotated tag, direct from SHA (no branch checkout)
# Repo enforces tag.gpgsign=true → -a produces a signed annotated tag automatically.
# Never bypass signing (no --no-gpg-sign, no -c tag.gpgsign=false) per core/rules/git-workflow.md.
git tag -a -m "v<X.Y>-<milestone-slug> — <N> issues; release SHA = merge of PR #<PR>" v<X.Y> "$MERGE_SHA"
git push origin v<X.Y>
```

This discipline emerged from a Stage 12 Execute (2026-05-03), where the hub-authored chip prompt instructed `git checkout main` in the worktree and the spoke deviated correctly — tagging the merge commit SHA directly via `git tag <name> <SHA>` without a branch checkout, achieving functional equivalence while honoring Primary Checkout Discipline. The signed-annotated form (`-a -m "<message>"`) composes with the tag-SHA-direct pattern: the repo's `tag.gpgsign=true` policy refuses lightweight `git tag <name> <SHA>` (`fatal: no tag message?` exit 128) — see [`pipeline/stage-12-execute.md` § Phase B signing-policy interaction](../pipeline/stage-12-execute.md). Never bypass signing per [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md). The deviation was well-documented but revealed a chip-authoring defect: future Stage 12 chips would re-issue the same flawed instruction. This pattern codifies the signed-annotated tag-SHA-direct form as the canonical chip-authoring rule and references [`pipeline/stage-12-execute.md` § Phase B](../pipeline/stage-12-execute.md) for the in-spec rationale + cutover clause.

**Cutover discipline:** Applies to all releases going forward.

**Stage 12 Chip Pattern — RELEASE_LOG Chore-PR Discipline:**

When the hub authors a Stage 12 Execute chip prompt, the prompt MUST prescribe the chore-PR pattern for RELEASE_LOG row + visible-H4 Deployment Log commit per [`pipeline/stage-12-execute.md § Phase B5 commit mechanism`](../pipeline/stage-12-execute.md). The chip prompt MUST NOT include any instruction that implies direct-to-main commit for the RELEASE_LOG row — that command is prohibited by [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do" AND is blocked by the auto-mode security classifier in current operational state. Per the chicken-and-egg merge-SHA constraint, the LOG row is authored post-merge from a chore branch.

Required chip-prompt content — Stage 12 chip prompts MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"After Phase B3 tag push, create chore branch `chore/v<X.Y>-stage-12-release-log`, edit `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` to append the new row (state = `DEPLOYED`) + visible-H4 `#### Deployment Log v<X.Y>` block per [`pipeline/stage-12-execute.md § Phase B5 emit format`](../pipeline/stage-12-execute.md), commit with message `chore(v<X.Y>): Stage 12 — RELEASE_LOG row + visible-H4 Deployment Log`, push, `gh pr create`, `gh pr merge` — per [`pipeline/stage-12-execute.md § Phase B5 commit mechanism`](../pipeline/stage-12-execute.md)."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"Stage 12 chore PR: `chore(v<X.Y>): Stage 12 — RELEASE_LOG row + visible-H4 Deployment Log` merged to main pre-Stage-13."*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/pipeline/stage-12-execute.md § Phase B5 commit mechanism (chore-PR pattern + bash exemplar + cutover)`

This discipline emerged from a Stage 12 sub-task Finding F-1 (2026-05-15), where the hub-authored chip prompt implied direct-to-main commit and the spoke correctly self-repaired via the chore-PR pattern. This discipline codifies the chore-PR pattern as the canonical chip-authoring rule and references [`pipeline/stage-12-execute.md § Phase B5 commit mechanism`](../pipeline/stage-12-execute.md) for the in-spec rationale + bash exemplar + cutover clause.

**Cutover discipline:** Applies to all releases going forward.

**Stage 12 Chip Pattern — Layer-1 Publication Discipline (Surface 1 emit):**

When the hub authors a Stage 12 Execute chip prompt, the prompt MUST prescribe the Phase B5.5 Surface 1 emit (`gh release create` via view-then-create-or-edit pattern) per [`pipeline/stage-12-execute.md § Phase B5.5`](../pipeline/stage-12-execute.md) AND [`release-notes-standard.md § Part 5`](../standards/release-notes-standard.md). Surface 1 is the canonical public release-notes consumer at `https://github.com/{REPO}/releases/tag/v<X.Y>`. The emit fires AFTER Phase B5 RELEASE_LOG chore PR has merged AND the v<X.Y> tag is pushed (Phase B3). The chip prompt MUST NOT use `gh release create` without the view-then-create-or-edit guard — `gh release create` is NOT independently idempotent and returns HTTP 422 on tag-already-has-release. The chip prompt MUST embed `--target "$MERGE_SHA"` to pin the GitHub Release to the canonical merge commit.

Required chip-prompt content — Stage 12 chip prompts MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"After Phase B5 chore PR merge verified, execute Phase B5.5 Surface 1 emit per [`pipeline/stage-12-execute.md § Phase B5.5`](../pipeline/stage-12-execute.md): verify tag exists on remote (`git ls-remote --tags origin v<X.Y>`); run view-then-create-or-edit state machine — `gh release view v<X.Y> --repo {REPO}`; if release exists AND body matches canonical note → PASS; if release exists AND body differs → `gh release edit v<X.Y> --notes-file release/releases/notes/v<X.Y>_RELEASE_NOTES.md`; if release does NOT exist → `gh release create v<X.Y> --repo {REPO} --title 'v<X.Y> — <H1-headline>' --notes-file release/releases/notes/v<X.Y>_RELEASE_NOTES.md --target \"$MERGE_SHA\"`. Verify final state via `gh release view v<X.Y>` returns 0."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"Surface 1 emit: GitHub Release v<X.Y> exists per `gh release view v<X.Y> --repo {REPO}` exit 0; final state machine state (CREATED / EDITED / NO-OP) recorded; merge SHA used for `--target` recorded."*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/pipeline/stage-12-execute.md § Phase B5.5 (Surface 1 emit — view-then-create-or-edit + idempotency + cutover)`, `release/references/standards/release-notes-standard.md § Part 5 §5.5 (idempotency state machine)`

This discipline composes with the Stage 12 RELEASE_LOG Chore-PR Discipline (existing) — Phase B5.5 fires AFTER the Phase B5 chore PR has merged. The same `$MERGE_SHA` captured at Phase B1 (per Phase B merge verification protocol) is reused at Phase B5.5 as the `--target` value. Surface 1 is the LAST mutation at Stage 12; Stage 13 chore PR handles Surfaces 2+3 (CHANGELOG + RELEASE_LOG VERIFIED transition).

**Composition with `release-executor` Mode F:** When the operator prefers standalone fix-forward invocation (Surface 1 emit outside Stage 12 spoke execution), the same view-then-create-or-edit logic is exposed via [`release-executor`](../../skills/release-executor/SKILL.md) Mode F (Publish Release). Mode F + Phase B5.5 share the idempotency guard — safe re-invocation across paths.

**Cutover discipline:** Applies to all releases going forward.

**Stage 12 Chip Pattern — Phase A.6 Polling Discipline:**

When the hub authors a Stage 12 Execute chip prompt, the prompt MUST prescribe the Phase A.6 mergeStateStatus polling protocol per [`pipeline/stage-12-execute.md § Phase A.6`](../pipeline/stage-12-execute.md). Treat `mergeStateStatus: UNKNOWN` as a wait-condition (NOT a green light) before proceeding to Phase B per-PR merge iteration. The chip prompt MUST NOT include any instruction that implies UNKNOWN is a proceed-condition — that interpretation defers conflict discovery to merge time rather than surfacing it pre-execution.

Required chip-prompt content — Stage 12 chip prompts MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"Before Phase B per-PR merge iteration, run Phase A.6 mergeStateStatus polling per [`pipeline/stage-12-execute.md § Phase A.6`](../pipeline/stage-12-execute.md) for each in-scope PR: initial read `gh pr view <PR> --json mergeable,mergeStateStatus`; on `MERGEABLE` + `CLEAN`/`UNSTABLE`/`BLOCKED` → PASS for this PR and advance; on `CONFLICTING` or `DIRTY` → HALT for WHOLE release + Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md § Inter-Stage Feedback Protocol`](../../governance/release-process.md); on `UNKNOWN` → poll with backoff `3s, 5s, 10s, 12s` (4 attempts; 30s wall-clock cap); on persistent `UNKNOWN` after the 4th attempt → HALT for this PR + Tier 2 [SCOPE CHANGE]."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"Phase A.6 polling results per in-scope PR — all PRs report definitive MERGEABLE/CONFLICTING state pre-Phase-B (initial state, attempts table, final state, decision recorded per A.6.5)."*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/pipeline/stage-12-execute.md § Phase A.6 mergeStateStatus polling protocol (backoff sequence + HALT semantics + cutover)`

This discipline emerged from a Stage 12 sub-task PR (2026-04-20), where the hub-authored chip prompt treated `UNKNOWN` as a green-light and the conflict surfaced only at merge time. This discipline codifies the polling protocol at [`pipeline/stage-12-execute.md § Phase A.6`](../pipeline/stage-12-execute.md) for the in-spec rationale + backoff sequence + HALT semantics.

**Cutover discipline:** Applies to all releases going forward.

**Stage 12 Chip Pattern — Phase B0 Dependent-PR Discipline:**

When the hub authors a Stage 12 Execute chip prompt, the prompt MUST prescribe the Phase B0 dependent-PR pre-merge check per [`pipeline/stage-12-execute.md § Phase B0`](../pipeline/stage-12-execute.md). Before merging any PR with `--delete-branch`, enumerate all open PRs whose base branch is this PR's head; for each dependent PR, shift its base to `main` via `gh pr edit <N> --base main` BEFORE the parent merge. This composes with Phase A.6 polling  — the post-base-shift mergeability re-verification re-enters the Phase A.6 backoff protocol on `UNKNOWN`.

Required chip-prompt content — Stage 12 chip prompts MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"Before each Phase B per-PR merge: enumerate dependent open PRs via `gh pr list --repo {REPO} --base <parent-head-branch> --state open --json number,baseRefName,headRefName,mergeable,mergeStateStatus`. **Option A (default — base-shift):** for each dependent PR `<dep>`, run `gh pr edit <dep> --base main`, then re-verify mergeability per Phase A.6 polling; on `MERGEABLE` for all dependents → proceed to Phase B1 merge. **Option B (opt-in via Delivery Strategy):** drop `--delete-branch` flag on this wave's merge command; log dependents to Stage 12 sub-task output; defer branch cleanup to Phase D0 per [`pipeline/stage-12-execute.md § Phase D0`](../pipeline/stage-12-execute.md)."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"Phase B0 dependent-PR enumeration result + base-shift commands executed (Option A) OR Delivery Strategy declaration of deferred-cleanup posture (Option B)."*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/pipeline/stage-12-execute.md § Phase B0 dependent-PR pre-merge check (Option A base-shift + Option B defer + composability with Phase A.6)`

This discipline emerged from a Stage 12 sub-task (2026-04-20), where merging a PR with `--delete-branch` auto-deleted the base branch of a dependent PR, triggering GitHub auto-close and a recreate-and-recover dance. This discipline codifies the pre-merge enumeration + base-shift mechanism at [`pipeline/stage-12-execute.md § Phase B0`](../pipeline/stage-12-execute.md).

**Cutover discipline:** Applies to all releases going forward.

**Stage 7/8/9 Entry Divergence Re-Check Discipline:**

When the hub authors a Stage 7 Dev Testing, Stage 8 QA Testing, or Stage 9 Plan Review chip prompt, the chip prompt MUST embed a mid-pipeline divergence re-check per [`release-process.md § Mid-Pipeline Divergence Re-Check (G-PR8 — Phase A6.5)`](../../governance/release-process.md) and [`pipeline/stage-09-plan-review.md § Phase A6.5`](../pipeline/stage-09-plan-review.md). The check fires at stage-entry, before the chip's main work. The chip prompt MUST NOT skip the check on the grounds that "Stage 12 Phase A.5 will catch it" — Stage 12 catch is post-GO and forces full re-baseline.

Required chip-prompt content — Stage 7/8/9 chip prompts MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block):
   - **Stage 7/8 (Tier 1 informational):** *"At stage entry, run mid-pipeline divergence re-check: `git fetch origin main && git log <release-branch-base>..origin/main --oneline -- $(cat <release-plan-files-list>)`. If output non-empty: post Tier 1 [ADJUST] comment on parent sub-task naming the diverged commits + affected files; continue chip work. Do NOT HALT — Stage 9 Phase A6.5 is the HALT-eligible boundary."*
   - **Stage 9 (Tier 2 HALT-eligible):** *"At Phase A6.5 (between Phase A6 Release Readiness Scan and Phase A7 Goal-Conformance Check), run mid-pipeline divergence re-check per stage 7/8 form. Three verdicts: CLEAN (zero commits) → record G-PR8=CLEAN, advance to Phase A7; DIVERGED-RELEASE-FILES-UNTOUCHED (commits exist but no release-plan file touched) → record G-PR8=DIVERGED-RELEASE-FILES-UNTOUCHED + informational note in Plan Review comment, advance to Phase A7; DIVERGED-RELEASE-FILES-TOUCHED (commits touch release-plan files) → HALT pre-GO via Tier 2 [SCOPE CHANGE] per [`release-process.md § Inter-Stage Feedback Protocol`](../../governance/release-process.md), do not proceed to Phase B GO."*
   - **Stage 9 — version dimension (advisory; ALSO run at Phase A6.5):** *"After the file-dimension verdict above, run the version-freeness dimension. Resolve the release version via the version-claim adapter (do NOT re-derive the anchor or re-encode the claimed-set union — host mechanism lives only inside the adapter per `core/standards/repo-host-adapter-versioning.md` § 4): `CLAIM_REPO=\"$(gh repo view --json nameWithOwner -q .nameWithOwner)\" release/tools/claim-version.sh --bump <bump-class> [--patch-base v<X.Y>] --sha \"$(git rev-parse origin/main)\" --dry-run`, which computes next-free against the adapter's anchor()/claimed_set() (published Release tags ∪ origin signed tags ∪ in-flight DEPLOYED-not-VERIFIED RELEASE_LOG rows, orphan-filtered, integer-tuple compared) WITHOUT pushing. FREE (dry-run next-free == carried provisional-display) → record version-freeness=FREE; TAKEN (dry-run next-free advanced past the carried version) → record version-freeness=TAKEN + recomputed next-free in the Plan Review comment + Decision Briefing as a re-version signal. ADVISORY ONLY — do NOT HALT the GO on the version dimension (the version is not claimed until Stage 12; the HALT-eligible version stop is Stage 12 Phase A.5.6). The file dimension (G-PR8) retains its HALT-eligibility independently; this version dimension composes with G-PR9's Δversion/<claim-key> staleness token (relative-to-baseline) as the absolute now-claimed predicate — no duplicate gate."*

2. **Output deliverables block** (entry in the chip's required-deliverables list):
   - **Stage 7/8:** *"Mid-pipeline divergence re-check verdict: CLEAN / DIVERGED-with-informational-note. Diverged commits enumerated when non-empty."*
   - **Stage 9:** *"Mid-pipeline divergence re-check verdict (G-PR8): CLEAN / DIVERGED-RELEASE-FILES-UNTOUCHED / DIVERGED-RELEASE-FILES-TOUCHED. If TOUCHED, Tier 2 [SCOPE CHANGE] block posted and HALT recorded. Version-freeness verdict (advisory): FREE / TAKEN; if TAKEN, the recomputed next-free version is recorded in the Plan Review comment + Decision Briefing as a re-version signal (no HALT — the version dimension is advisory at Stage 9)."*

3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/governance/release-process.md § Mid-Pipeline Divergence Re-Check (G-PR8 — Phase A6.5)`, `release/references/pipeline/stage-09-plan-review.md § Phase A6.5`, `release/references/pipeline/stage-04-planning.md § Cross-PR Overlap Audit (A4 extension) — Baseline-pin temporal limitation`, `release/references/pipeline/stage-12-execute.md § Phase A.5.6 (version-freeness pre-merge HALT)`, `core/standards/repo-host-adapter-versioning.md § 4 (version-claim adapter operations — anchor()/claimed_set(); adapter discipline)`.

**Empirical motivation:** a Stage 12 sub-task — Stage 4 A4 audit reported "zero open-PR collision" at baseline `302bc0a`; a structural Diátaxis reorg merged POST-audit (tip `ad756c6`) touching `implementation-execution-pattern.md` + 3 mirror-pair files. Detection occurred only at Stage 12 Phase A.5 (`mergeable:CONFLICTING/DIRTY`) — voiding the Stage 9 GO (`8387f46`) and forcing full re-baseline. The Stage 9 Phase A6.5 check codified here would have surfaced the merge BEFORE the Stage 9 GO and prevented the void event.

**Cutover discipline:** Applies to all releases going forward.

**Stage 5 Chip Pattern — Design-Exploration Discipline:**

When the hub authors a Stage 5 Solutioning chip prompt AND the issue carries a design choice with two or more candidate approaches, the chip MUST direct the spoke to run the design-exploration protocol BEFORE the trade-off matrix — divergent generation of ≥3 genuinely distinct candidates, then convergent narrowing (elimination against hard constraints with one-line kill-reasons), then the trade-off matrix on the survivors. This is the D-D instruction's second landing surface (the first is the Stage-5 Phase A4 spec): routing it into the Stage-5 chip propagates the instruction to spawned spokes so a spoke does not anchor on its first solution and retrofit alternatives to pass the design-review checklist's ≥3-alternatives check. The instruction is OMITTED (with a one-line spoke rationale) when the issue's design has a single forced approach — the same non-ceremony omission signal the protocol itself uses.

Required chip-prompt content — Stage 5 Solutioning chip prompts (when the ≥2-candidate predicate holds) MUST embed:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block, BEFORE the trade-off-matrix / ADR step): *"Run the design-exploration protocol per `release/references/standards/design-exploration.md` BEFORE the trade-off matrix: generate ≥3 genuinely distinct candidate approaches (distinctness test on mechanism / blast radius / reversibility / placement), eliminate against hard constraints with a one-line kill-reason each, then score the survivors on the canonical axes (Reversibility × Confidence × Blast radius × Upstream-compat). Omit with a one-line rationale only if the design has a single forced approach."*
2. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/standards/design-exploration.md (divergent generation → convergent narrowing → trade-off matrix; the §6 worked example + the omission/non-ceremony signal)`.

**Cutover discipline:** Applies to all releases going forward.

**Stage 5 Chip Pattern — Adversarial Design Review Discipline:**

When the hub authors a Stage 5 chip prompt AND Solutioning has fired for the release (Phase 0 Activation Gate ACTIVE), every Stage 5 Solutioning spoke launched via Procedure 3 MUST be paired with a sequential follow-on launch of the `pmo-adversarial` agent (subagent_type `pmo-adversarial`) that reviews the Solutioning spoke's output. The adversarial review fires AFTER the Solutioning spoke posts its output comment AND BEFORE the hub composes the Collective Review Decision Briefing — sequential ordering preserves independence (the adversarial reviewer reads the FINISHED designing-spoke output, then produces 3 structured-list findings advisory to the Operator). The pairing is **uniform** — every in-scope Stage 5 spoke output gets an adversarial review when Solutioning fires; no per-issue selective routing.

Required chip-prompt content — Stage 5 adversarial-review chip prompts MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"Read the Stage 5 Solutioning spoke output comment for #N (the spec). Read the parent issue #N body for AC. Read sibling Stage 5 outputs in the same release for cross-issue context. Produce 3 structured-list outputs (Premise-Rejection-Findings + Failure-Mode-Findings + Counter-Design-Findings) per the schema in `pipeline/stage-05-solutioning.md` § Phase A6.5. Findings are ADVISORY — they inform the Operator's scope-lock decision at Collective Review; they do not gate independently. **Scoped abstraction-altitude exception:** you MAY challenge an operator-pre-decided premise ONLY on the axis of abstraction altitude — a host-concrete point-fix where an existing platform seam (`[adapters]`, a module boundary, a config surface) should be extended — tagging it a **Premise-Altitude-Finding** within Premise-Rejection-Findings; this is an advisory flag the operator weighs at Collective Review scope-lock, NEVER an autonomous reversal and NEVER a relitigation of a settled mechanism choice at the correct altitude. State the altitude concern and the seam it would compose with; do not re-author the design."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"Adversarial-review comment posted on adversarial-review sub-task #M with 3 structured-list findings + summary verdict (Blocker / Major / Minor / Cosmetic)."*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/pipeline/stage-05-solutioning.md § Phase A6.5 (Independent Adversarial Design Review — schema + scope + cutover)`, `core/standards/review-composition-framework.md § RC-5-adversarial-design-review`, `core/disciplines/review-discipline-principles.md` (10 anti-laziness rules), `core/standards/failure-mode-standard.md` (5-field template + 5-category tag), `release/references/standards/triage-design-rereview.md § 3` (PT-1/PT-2/PT-3/PT-4 C3 classification).

The pairing composes with  Stage 5 spec at: D-RoleMechanism (NEW persona + NEW agent definition `.claude/agents/pmo-adversarial.md`) preserves structural independence — different `subagent_type` value → different session lifecycle → no shared session memory; D-ReviewerScope (UNIFORM — every Stage 5 output) matches the Phase 0 all-or-nothing activation posture; D-OutputContract (3 structured-list outputs) matches the AC#3 verbatim 3-axis requirement; D-CompositionWith985 (NEW `RC-5-adversarial-design-review` Catalog entry) preserves [`review-composition-framework.md`](../../../core/standards/review-composition-framework.md) § 7.1 forcing-function compliance.

The chip uses `subagent_type: pmo-adversarial` and `isolation: "worktree"` (read-only review spoke — no file writes, but defensive worktree isolation per Stage 5 spoke convention). Model: `opus` (per `.claude/agents/pmo-adversarial.md` frontmatter default + the workspace's designated-model preference for principal-grade review).

**Cutover discipline:** Applies to all releases going forward.

**Stage 5 Chip Pattern — Solutioning Pre-Read Discipline:**

When the hub authors a Stage 5 Solutioning chip prompt AND the issue carries
rich pre-implementation analysis worth conveying to the implementing agent, the
chip MAY direct the spoke to post a **Solutioning pre-read** on the parent issue
per [`solutioning-output-template.md` § 3.5](../standards/solutioning-output-template.md).
The pre-read is ADVISORY and non-binding — the issue body stays the sole
authoritative contract (per `ticket-information-architecture.md` § Source of
Truth, "the issue body is the single authoritative record"); no downstream stage
reads the pre-read as scope. The instruction is OMITTED (no ceremony) when the
issue has no rich pre-read analysis to convey — the same non-ceremony omission
signal the Design-Exploration chip pattern uses.

Required chip-prompt content — when the pre-read predicate holds, the chip MUST
embed:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"If you have rich pre-implementation analysis to orient the implementing agent, post a Solutioning pre-read comment on the PARENT issue #N per [`solutioning-output-template.md` § 3.5](../standards/solutioning-output-template.md): open with the banner `🧭 **Solutioning pre-read — ADVISORY, not scope**`, state explicitly that it does NOT modify Acceptance Criteria / Proposed Change / Affected Files (the issue body remains the sole contract), and close with a re-verify line. The pre-read is advisory context, never scope."*
2. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/standards/solutioning-output-template.md § 3.5 (Solutioning Pre-Read — advisory/non-binding banner + worked example #545)`.

**Cutover discipline:** Applies to all releases going forward.

**Stage 13 Chip Pattern — Release-Notes Authoring Discipline:**

When the hub authors a Stage 13 Close chip prompt, the prompt MUST instruct the spoke to author `release/releases/notes/vX.Y_RELEASE_NOTES.md` per [`release-notes-standard.md`](../standards/release-notes-standard.md) (9-section format). The user-facing release note is a distinct artifact from `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` (engineering audit trail) and the release plan file (implementation audit trail) — per [`release/governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) Close phase (line 53), all three artifacts are authored at Stage 13 Close. [`release-process.md` Stage 13 Outputs](../../governance/release-process.md) already specifies the gate (*"Milestone close gates on note presence + structural lint pass"*); this subsection ensures the chip-prompt-level mandate matches the spec-level requirement.

Required chip-prompt content — Stage 13 chip prompts MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"Author `release/releases/notes/vX.Y_RELEASE_NOTES.md` per [`release-notes-standard.md`](../standards/release-notes-standard.md) 9-section format."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"User-facing release note: `release/releases/notes/vX.Y_RELEASE_NOTES.md`"*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/standards/release-notes-standard.md`

This discipline emerged from a Stage 13 Close (2026-05-10), where the hub-authored chip prompt instructed only `RELEASE_LOG.md` authoring and omitted the user-facing release note. The spoke followed literal chip instructions and closed the Milestone without authoring the note, requiring retroactive remediation — the empirical motivation. This chip-pattern subsection codifies the chip-pattern-level prevention; Procedure 7 Step 4 adds hub-side completion-verification on top of this pattern (FOUNDATION → VERIFIES → PROVES triad).

**Cutover discipline:** Applies to all releases going forward.

**Stage 13 Chip Pattern — Audit-Class Synthesis Discipline:**

When the hub authors a Stage 13 Close chip prompt AND the release is audit-class (detection: `git diff --name-only main...origin/release/<milestone> -- <OPERATOR_INSTANCE_ANALYSIS_PATH>/ | grep -E 'SUMMARY\.md$'` returns ≥1 new file), the chip prompt MUST instruct the spoke to synthesize the audit's SUMMARY downstream-handoff items into stabilization Issues AND milestone-tag each filed Issue at filing time. This pattern emerged from a retrospective (2026-05-03) which surfaced that the release closed with 0 stabilization Issues filed despite 12 enumerable downstream-handoff items in its SUMMARY — operator pulse-check identified the gap post-release. Defense-in-depth triad re-applied: the chip (FOUNDATION; this subsection) ensures the spoke files the Issues + tags them; Procedure 7 Step 4 (VERIFIES) confirms; Step 4 gate-passage proof comment (PROVES) records — mirroring the FOUNDATION → VERIFIES → PROVES architecture for release-note authoring discipline.

Required chip-prompt content — Stage 13 chip prompts for audit-class releases MUST embed these three additions:

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block) — branches on whether the audit folder pre-authored issue-drafts:
   - If audit folder contains `issue-drafts/<NNN-name>.md` files: *"For each `<OPERATOR_INSTANCE_ANALYSIS_PATH>/<audit-folder>/issue-drafts/*.md` file: file as a new GitHub Issue via `gh issue create --body-file <path>`; immediately set Milestone via `gh issue edit <N> --milestone <target-milestone>` (target = next planned Milestone per Stage 4 D-decision, OR default to next-immediate Milestone surfacing in release sequence)."*
   - Else (no `issue-drafts/` folder): *"Enumerate audit's SUMMARY § downstream-handoff items (typically § 4 Recommendations or § 5 Downstream Sequencing). For each item: `gh issue create --title '<derived>' --body '<derived>' --label 'improvement,<cluster-label>' --milestone <target-milestone>`. Granularity per Stage 4 D-decision (default: 1 Issue per item)."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"Audit synthesis: for audit `<folder-name>`, N Issues filed (#A-#B-...), all Milestone-tagged to `<target-milestone>`. Filed-vs-recommended ratio: N filed / M recommended (per Stage 4 D-decision granularity rule)."*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/how-to/hub-spoke-bridge.md § Procedure 3 §Stage 13 Chip Pattern — Audit-Class Synthesis Discipline (audit-class synthesis discipline + granularity rules)`

**Granularity rule (G-Hybrid):** Default = **1 Issue per audit SUMMARY downstream-handoff item** (per recommendation row in § 4 / § 5 of SUMMARY). The default fires when Stage 4 spoke determines SUMMARY recommendation count ≤ 10 AND single-axis (e.g., "per skill" or "per file"). For high-cardinality audits, Stage 4 produces an override D-decision named `D-AuditSynthesisGranularity` per `hub-spoke-bridge.md` D-Gate Template; granularity options: `A` (1:1) / `B` (per-category bundle, ≤5 buckets) / `C` (per-cluster bundle, operator-defined) / `D` (sample-then-stage — file top-N, defer rest). Threshold calibration: re-tune after 3 post-cutover audit-class releases per the `[CALIBRATE-AFTER-3]` precedent recorded in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`.

**Issue-drafts vs direct creation criteria:** Default to issue-drafts when audit anticipates ≥ 3 follow-up items OR bodies are detailed (full intake-template-shaped Issues). Direct creation when ≤ 2 items OR mechanical (e.g., milestone-orphan retros — short, mechanical, no AC needed). Decision point is the audit's own Stage 5 Solutioning OR Stage 7/8 Dev Testing — if audit ships without drafts AND SUMMARY has ≥ 3 items, Stage 13 spoke is responsible for inline synthesis. The default tilts toward issue-drafts because audit's own Stage 7/8 QA can pre-review draft quality (lower error rate at Stage 13 filing), `gh issue create --body-file` is deterministic, and SUMMARY can cross-reference draft files (`issue-drafts/001-foo.md → #N`) improving traceability.

**Audit-class detection (D-Folder):** Detection runs first; if no new `<OPERATOR_INSTANCE_ANALYSIS_PATH>/<name>-YYYY-MM-DD/SUMMARY.md` files appear in the release diff, the release is non-audit-class and this chip-pattern subsection does not fire (the chip prompt omits the three additions above; Procedure 7 Step 4 conditional rows resolve to N/A). Folder convention is established in CLAUDE.md governance file map; if convention drifts (e.g., audit re-runs append to existing folder vs. new dated folder), detection underfires — mitigation via Stage 4 release plan declaration (`audit_class: true` or equivalent) as fallback when folder detection is ambiguous.

**Cutover discipline:** Applies to all releases going forward.

**Stage 13 Chip Pattern — Release-Corpus Chore-PR Discipline:**

When the hub authors a Stage 13 Close chip prompt, the prompt MUST prescribe the chore-PR pattern for RELEASE_LOG `DEPLOYED` → `VERIFIED` transition + RELEASE_INDEX + RELEASE_DIGEST + RELEASE_NOTES commit per [`pipeline/stage-13-close.md § Phase B commit mechanism`](../pipeline/stage-13-close.md). The chip prompt MUST NOT include any instruction that implies direct-to-main commit for these artifacts — that command is prohibited by [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do" AND is blocked by the auto-mode security classifier in current operational state. The Stage 13 chore PR bundles all release-corpus updates atomically into one main-landing.

Required chip-prompt content — Stage 13 chip prompts MUST embed these three additions (in ADDITION to the existing release-notes authoring chip-pattern requirements):

1. **Step-by-step item** (numbered step within the chip's "Step-by-step (in order)" block): *"After Phase A verification clears + Phase B-OPS verification clears, create chore branch `chore/v<X.Y>-stage-13-corpus-update`, edit `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` to transition v<X.Y> row state `DEPLOYED` → `VERIFIED` (Surface 3 of Layer-1 dual-write) AND append the `**Velocity:**` field to the v<X.Y> visible-H4 `#### Deployment Log v<X.Y>` block (sibling immediately AFTER `**Cycle-Time:**`) — compute via [`release/tools/compute-release-velocity.sh <version> --milestone <N> --merge-sha <MERGE_SHA>`](../../tools/compute-release-velocity.sh) and embed the returned value (manual-fill if the tool cannot run), per [`pipeline/stage-13-close.md § Phase B-velocity`](../pipeline/stage-13-close.md) + [`release-velocity-tracking.md`](../standards/release-velocity-tracking.md) (a release with no `size:*`-labelled membership records `Velocity: N/A`; grandfather — pre-cutover rows + the introducing release carry no field), edit `release/releases/RELEASE_INDEX.md` to append v<X.Y> row, edit `release/releases/RELEASE_DIGEST.md` to append v<X.Y> entry under version-family H2, author `release/releases/notes/v<X.Y>_RELEASE_NOTES.md` per [`release-notes-standard.md`](../standards/release-notes-standard.md) 9-section format, edit `CHANGELOG.md` at repo root to prepend `## [v<X.Y>] - YYYY-MM-DD` H2 section per Keep-a-Changelog 1.1.0 (Surface 2 of Layer-1 dual-write; content per [`release-notes-standard.md § 5.3`](../standards/release-notes-standard.md) §5.3 transform rule; SKIP with PASS if CHANGELOG.md does not exist at repo root — pre-CHANGELOG state), edit `.version` at repo root to stamp the shipped version `v<X.Y>` (release-cut-owned version source-of-truth read by the SessionStart version-skew hook; idempotent — no-op if already `v<X.Y>`; SKIP with PASS for a version-less release) per [`pipeline/stage-13-close.md § Phase B5.7`](../pipeline/stage-13-close.md), verify Surface 1 (GitHub Release v<X.Y>) exists per [`pipeline/stage-13-close.md § Phase B5.6`](../pipeline/stage-13-close.md), commit with message `chore(v<X.Y>): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG`, push, `gh pr create`, `gh pr merge` — per [`pipeline/stage-13-close.md § Phase B commit mechanism`](../pipeline/stage-13-close.md). Chore PR MUST land BEFORE Milestone close."*
2. **Output deliverables block** (entry in the chip's required-deliverables list): *"Stage 13 chore PR: `chore(v<X.Y>): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG` merged to main BEFORE Milestone close. Surface 2 (CHANGELOG entry) committed OR SKIPPED-PASS with rationale. `.version` stamped to v<X.Y> on main per `git show origin/main:.version` (or SKIPPED-PASS with rationale for a version-less release). Surface 1 (GitHub Release) verified present per `gh release view v<X.Y>` exit 0 (or routing decision recorded per Phase B5.6 if missing)."*
3. **`{ADDITIONAL_READS}` entry** (line in the chip's reading list): `release/references/pipeline/stage-13-close.md § Phase B commit mechanism (chore-PR pattern + bash exemplar + cutover)`, `release/references/pipeline/stage-13-close.md § Phase B-velocity (**Velocity:** field append + compute-release-velocity.sh + grandfather)`, `release/references/standards/release-velocity-tracking.md (field schema + label→work-class map + N/A semantics + N=3 recalibration linkage)`, `release/references/pipeline/stage-13-close.md § Phase B5.5 (CHANGELOG append + idempotency)`, `release/references/pipeline/stage-13-close.md § Phase B5.6 (Surface 1 verification)`, `release/references/pipeline/stage-13-close.md § Phase B5.7 (.version stamp + idempotency + version-less SKIP)`, `release/references/standards/release-notes-standard.md § Part 5 §5.3 (per-surface length + format conventions)`

This discipline composes with three sibling Stage 13 chip-pattern subsections: Release-Notes Authoring (existing) ensures the spoke authors `v<X.Y>_RELEASE_NOTES.md`; Audit-Class Synthesis (existing, audit-class only) ensures the spoke files SUMMARY-derived stabilization Issues; Release-Corpus Chore-PR Discipline (this subsection) ensures all the above artifacts land via one Stage 13 chore PR pre-close. Procedure 7 Step 4 completion-verification reads RELEASE_NOTES presence + RELEASE_LOG `VERIFIED` state + INDEX/DIGEST entries from main — all populated by this chore PR landing. Step 4 gate-passage proof comment records the verification result on the Stage 13 sub-task BEFORE the operator's Milestone close action. The triad FOUNDATION → VERIFIES → PROVES holds: this subsection is the Stage-13-side FOUNDATION.

**Concurrent-close conflict resolution:** When two releases' Stage-13 chore PRs are open at the same time, the second-to-merge hits a git merge conflict on all four append-only ledgers (CHANGELOG / RELEASE_INDEX / RELEASE_DIGEST / RELEASE_LOG). Resolve it deterministically per [`pipeline/stage-13-close.md § Concurrent Stage-13 corpus conflict resolution`](../pipeline/stage-13-close.md) — additive ledgers take both entries preserving landing order (never re-sort), and the `RELEASE_LOG` status column reconciles per-row over the `DEPLOYED < VERIFIED` lattice (never a blanket side-pick, which writes a false audit record). The cross-referenced doctrine lives in this same Procedure-3 chip-pattern region (the Release-Corpus Chore-PR Discipline subsection) that Procedure 7 Step 4 completion-verification consumes; a hub authoring a Stage 13 chip for a release that may close concurrently SHOULD add it to the chip's `{ADDITIONAL_READS}`.

Empirical motivation: a Stage 13 chore PR (2026-05-16) is the canonical worked example; an earlier chore PR (2026-05-15) is the historical operator-precedent.

**Cutover discipline:** Applies to all releases going forward.

**Spoke Template:**
```
This is a spawned Claude Code session — you have no memory of
the hub. The hub session will consume your output from the
sub-task comment after you finish. Stay within scope and do
not spawn additional spokes yourself.

You are executing Stage {STAGE_NUMBER} ({STAGE_NAME}) for
#{ISSUE_NUMBER} in Milestone {MILESTONE} ({REPO}).

Read these in order:
1. README.md (repo overview)
2. core/rules/ (all files)
3. gh issue view {ISSUE_NUMBER} --repo {REPO}
4. gh issue view {SUB_TASK_NUMBER} --repo {REPO}
   (your stage instructions)
5. release/references/pipeline/stage-{STAGE_NUMBER_NN}-{name}.md
{ADDITIONAL_READS}

## Persona
{FULL_PERSONA_CARD_FROM_RELEASE_PERSONAS_MD}

## Task
Execute Stage {STAGE_NUMBER} per pipeline/stage-{STAGE_NUMBER_NN}-{name}.md and the
instructions on sub-task #{SUB_TASK_NUMBER}.

## R1 Evidence-Grounding Discipline (Stage 5 spokes)

If your output canonicalizes ANY convention (dir name, frontmatter field, file
path pattern, regex, identifier format, naming scheme, numeric threshold, any
structural-spec value chosen from ≥2 candidates), you MUST produce an
inspectable Evidence-Grounding artifact in your output:

1. Enumerate current state across the codebase (specific files/sections/issue
   citations + reproducible grep command).
2. Justify the canonical choice with citation to (a) an audit finding,
   (b) an upstream-reference catalog entry per R2 (see
   `core/standards/upstream-reference-catalog.md`), or
   (c) a documented governance rationale (ADR issue # or doc section).
3. List any out-of-scope drift observed during the survey, with routing
   recommendation (Tier 1 [ADJUST] / next-release issue / accepted-residual).

Place the artifact as a `### Evidence-Grounding (per R1 )` subsection
in your output, AFTER `### Detail` and BEFORE `### Decisions & Recommendations`.

Failure to ground a canonicalization is a Collective Review rejection
trigger (per `release/governance/release-process.md` Collective Review Protocol
bullet 6 — N-way consistency + evidence-grounding scan). Stage 5 sub-task
output is incomplete without this artifact when applicable.

Full schema at [`core/standards/evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md).
This block applies to Stage 5 Solutioning spokes; other stages may include
the artifact when their output canonicalizes a convention, but it is not
required outside Stage 5.

## Date-Variable Convention (Stage 5 spokes)

If your output's File Change Matrix creates ≥1 downstream load-bearing
identifier carrying a date in `YYYY-MM-DD` form (audit-folder paths, AC
verifier identifiers, ADR source-observation references), you MUST include
a `### Date Variable` block at the top of your output per
[`core/standards/date-variable-convention.md`](../../../core/standards/date-variable-convention.md).
Variable `${AUDIT_DATE_UTC}` resolves at Stage 6 first commit via
`date -u +%Y-%m-%d`. Engineering propagates the resolved value
consistently across all artifacts in the release.

Stage 5 output that hardcodes literal dates in load-bearing positions
(when the trigger predicate holds) is incomplete; Collective Review flags
as a structural defect.

**Cutover discipline:** Applies to all releases going forward.

## Cascade-Completeness Discipline (Stage 5 spokes)

If your change spec includes a **count update**, an **enumeration update**, or a
**threshold / version-narrative change** to any file in your affected-files
matrix, you MUST include a `### Cascade-Sweep` block in your output enumerating
every occurrence of the OLD value across the (file × OLD-value) pairs in scope.

**Trigger predicate — the block is required when ANY hold:**
- A numeric count changes (cardinality N → M — e.g. "20 skills" → "19 skills").
- An enumerated list gains, loses, or renames a member.
- A threshold or narrative version reference changes (e.g. "180-day window" →
  "90-day window"; "N=2" → "N=3").

**Required artifact — a per-(file × OLD-value) Cascade-Sweep table** with the
sweep command(s) cited and a disposition per occurrence: UPDATE (swept) /
PRESERVE-or-N/A (out-of-scope / accepted-residual, each with a one-line reason).
Sweep scope is NARROW by design — only the files in your affected-files matrix
and only the specific OLD value being changed, never the whole codebase.

**Failure consequence:** a spec that makes a triggering change but omits the
`### Cascade-Sweep` block — or whose table misses an OLD-value occurrence a
re-run of the cited grep would surface — is an incomplete spec; Collective
Review rejects it as a structural defect.

This is the chip-launch-time surface of the Cascade-Completeness Sweep rule
(Phase A4.1) authored in the Stage 5 Solutioning spec
([stage-05-solutioning.md](../pipeline/stage-05-solutioning.md)) — that spec is
canonical for the trigger table, the block format, and the load-bearing test.
The two compose with R1 Evidence-Grounding (R1 surveys current state of a
convention BEFORE canonicalizing; Cascade-Sweep surveys OLD-value occurrences
AFTER a state change).

**Cutover discipline:** Applies to all releases going forward.

## Output
Post your output as a comment on sub-task #{SUB_TASK_NUMBER}:

## Stage {STAGE_NUMBER} {STAGE_NAME} — {MILESTONE}
### Summary (30 seconds)
### Detail
### Evidence
### Decisions & Recommendations
For each finding requiring operator judgment:
- **Finding:** What was observed
- **Spoke Recommendation:** What you recommend — and why (grounded in your deep context)
- **Severity:** Blocker / Major / Minor / Cosmetic / Informational
### Output for Stage {NEXT_STAGE}
### Model Provenance

- **Invocation model parameter:** `{model-value-passed-by-hub-at-invocation-site}` (passed explicitly by hub per § Spoke Launch Mechanisms — Model Parameter Required-Explicit subsection)
- **Agent-definition default:** `{model-value-from-frontmatter-at-.claude/agents/<subagent_type>.md}` (per the agent definition's `model:` frontmatter field)
- **Parent-session model:** `{as-reported-by-spoke-runtime; e.g., from claude --version or session metadata}`
- **Designated-model match:** YES / NO (PASS if all three are `opus` and match the agent-definition default OR an operator-declared per-stage override per `core/config/allowlists/agents-model-overrides.txt`)

### Mode Provenance

- **Declared mode:** `{the mode the hub named for this spoke — read verbatim from the sub-task instruction / chip prompt, e.g., "Mode B — Release Planning"}` (write `none-declared` if the hub named no mode)
- **Invoked mode:** `{the mode the spoke actually executed — the SKILL.md ### Mode X section it ran, or `single-mode` for a one-mode skill, or `N/A — no skill (general-purpose persona)` when the spoke ran as a raw persona with no SKILL.md}`
- **Mode source:** `body-heading` (`### Mode X` headings) / `description-list` (the `Modes:` line in the frontmatter `description`) / `n/a-single-mode` / `n/a-no-skill` — names the convention the skill's mode-enum was read from, so the enum's provenance is auditable
- **Mode-match:** PASS / N/A / DRIFT (PASS when Declared == Invoked AND Invoked is in the skill's mode-enum; N/A when the skill is single-mode or no skill applies; DRIFT when Declared ≠ Invoked, OR Invoked is not in the enum, OR a multi-mode skill ran with `none-declared`)

Then close sub-task #{SUB_TASK_NUMBER}.

## Scope
- Stay within #{ISSUE_NUMBER}. Discoveries outside scope → note
  in Evidence section, do not execute.
- No governance file modifications without operator approval.
- If you encounter a blocker, do NOT close the sub-task. Post
  your findings and flag the blocker for the hub.

## Session Start Checklist
Before executing the task, verify:
1. Parent issue #{ISSUE_NUMBER} is OPEN.
2. Sub-task #{SUB_TASK_NUMBER} is OPEN and does not carry a
   prior blocker comment.
3. `spawn_task` is NOT called from within this spoke (no
   recursive spawning).
```

**Model Provenance block cutover (Stage 5 ADR Dimension 6):** The `### Model Provenance` block addition to the Spoke Template above (4 fields: Invocation model parameter / Agent-definition default / Parent-session model / Designated-model match) is the runtime-drift surface of the composite detection mechanism (companion to `deploy.sh --check` Check 27 + Stage 8 QA LLM-graded review).

> **Cutover discipline:** Applies to all releases going forward.

**Mode Provenance block cutover:** The `### Mode Provenance` block addition to the Spoke Template above (4 fields: Declared mode / Invoked mode / Mode source / Mode-match) is the runtime-drift surface of the mode-invocation composite detection mechanism (companion to `deploy.sh --check` Check 35 + Stage 8 QA LLM-graded review). Where Model Provenance catches model drift, Mode Provenance catches mode drift — a spoke silently skipping or mis-selecting a required mode. The Mode source field names which convention sourced the skill's mode-enum (`body-heading` preferred over `description-list` when a skill carries both, since the description list can be a stale subset).

> **Cutover discipline:** Applies to all releases going forward.

### Return Value to Hub

When a hub-spawned spoke session ends (the `Agent({...})` tool invocation completes), the final message the spoke types as its return value lands directly in the hub's transcript. This message is the **routing primitive** the hub's Procedure 2 consumes; the canonical content artifact for that spoke's stage work is the GitHub sub-task comment per Procedure 4 Step 1. The two channels carry different payloads:

- **GitHub sub-task comment** (rich payload) — Spoke Template § Output schema; governance-rigorous; the authoritative content artifact.
- **Agent-tool return value** (minimal payload) — closed-enum schema below; routing-only; governs what flows through the hub-transcript channel.

The hub uses the Agent-tool return value for **routing only**. For content, findings, recommendations, or any rationale, the hub reads the GitHub sub-task comment per Procedure 4 Step 1. The `next:` field is a routing primitive (closed enum) — NOT a recommendation channel. Findings that would change milestone scope, defer to a future release, file follow-up issues, or otherwise exit the pipeline belong in the GitHub comment `### Decisions & Recommendations` section, where they are auditable and operator-gated.

**Schema (canonical form; exactly 4 fields; nothing else):**

```
**Spoke Result — Stage {N} {STAGE_NAME} — #{ISSUE_NUMBER}**
verdict: PASS | FAIL | CONDITIONAL | BLOCKED
sub-task: #{SUB_TASK_NUMBER} ({closed | open-blocker})
comment: {GitHub comment URL — anchor of the canonical artifact}
next: {one of the closed-enum values per § next: closed enum below}
```

**Field semantics:**

| Field | Type | Closed enum? | Purpose |
|---|---|---|---|
| `verdict` | enum | YES — `PASS \| FAIL \| CONDITIONAL \| BLOCKED` | Stage outcome at this spoke. `PASS` = downstream proceeds; `FAIL` = upstream rework needed; `CONDITIONAL` = proceed with caveat documented in comment; `BLOCKED` = spoke cannot proceed (open dependency, prior-stage gap, etc.). |
| `sub-task` | issue ref + state | NO (free form `#N` + parenthetical state) | Identifies the sub-task this spoke owns. State `closed` = sub-task closed by spoke; `open-blocker` = spoke left sub-task OPEN with a blocker comment per the Scope rule above. |
| `comment` | URL | NO (free-form URL) | Direct link to the GitHub sub-task comment carrying the canonical output (Spoke Template § Output). Hub reads this comment via Procedure 4 Step 1; the URL is the cite, not the content. |
| `next` | enum | YES — see § next: closed enum below | Routing primitive. Closed enum mechanically prevents off-ramp drift. Hub Procedure 2 consumes this verbatim. |

#### next: closed enum

**Five allowed enum values (universal — all 7 spokes use this set):**

| Value | When the spoke emits this | Hub action (Procedure 2) |
|---|---|---|
| `route:stage-{N}-{name}` | Spoke PASSED; downstream stage sub-task is ready (e.g., Stage 5 closing → routes to Stage 6 sub-task) | Procedure 2 routes to the named stage open sub-task for the same issue (e.g., `route:stage-6-engineering` / `route:stage-7-dev-testing` / `route:stage-8-qa-testing` / `route:stage-9-plan-review` / `route:stage-12-execute` / `route:stage-13-close`) |
| `iterate:stage-{N}` | Spoke FAILED and prior-stage rework is needed (e.g., Stage 7 DT routes back to Stage 6 Engineering with Tier 1 finding) | Procedure 2 re-spawns the named upstream stage spoke per the DT↔Engineering iteration loop |
| `block:operator-decision-at-stage-{N}` | Spoke produced findings requiring operator judgment at a defined pipeline gate (Stage 9 / 12 / Collective Review scope-lock) | Procedure 4 surfaces Decision Briefing per Procedure 5 (gate handling); operator renders decision at the named gate |
| `block:dependency-#{M}` | Spoke cannot proceed until issue #M (or PR #M) lands; substrate dep is unmet | Hub holds the sub-task; re-routes after the dependency closes per `iterate:` re-spawn convention |
| `complete:sub-task-done` | Terminal sub-task state — no downstream routing remains (e.g., Stage 13 close completed) | Procedure 4 records completion; no further routing for this issue |

**Mechanically-blocked patterns** (these emitted values do NOT match the closed enum; the schema-conformance check at `deploy.sh --check` Check 29 flags them as structural defects):

| Off-ramp pattern (currently possible in free-form returns) | Why it fails closed-enum validation |
|---|---|
| `next: operator should reconsider milestone scope before proceeding` | Free text — schema regex fails |
| `next: recommend deferring this to v3.05 — see comment for rationale` | `defer:milestone-v3.05` is NOT in the allowed enum; deferral findings move to the GitHub comment for operator gating |
| `next: file follow-up for #N-style detection of X` | Out-of-pipeline issue-creation belongs in the GitHub comment; not a routing primitive |
| `next: route:stage-6 (followed by free-form prose explaining the routing)` | Schema IS the entire return value; appendix prose is a structural defect — Stage 7 DT (existing review surface) flags this as a content escape from the schema |
| `next: escalate-scope:` / `next: recommend-defer:` / `next: see-comment-for-routing` | Invented prefixes — fail closed-enum validation; routing-primitive-only discipline holds |

#### Worked example

Stage 7 DT spoke completed successfully on <DATE> (sub-task #<SUB_TASK>) with PASS verdict and a Tier 1 [ADJUST] finding documented in the GitHub comment. The Agent-tool return value emitted by the spoke at session end:

```
**Spoke Result — Stage 7 Dev Testing — #<ISSUE>**
verdict: PASS
sub-task: #<SUB_TASK> (closed)
comment: https://github.com/{REPO}/issues/<ISSUE>#issuecomment-<ID>
next: route:stage-8-qa-testing
```

Hub Procedure 4 reads the GitHub comment for the Tier 1 finding content; Hub Procedure 2 routes to Stage 8 QA Testing sub-task per the `next:` field. The Tier 1 finding is not in the Agent-tool return value — it lives in the comment where it is auditable.

#### Composition with  /  DT↔QA Handoff Payload

The DT↔QA Handoff Payload is the **rich-format GitHub-comment artifact** at the Stage 7↔8 boundary. The minimal-return schema above is the **routing-only Agent-tool channel** for ALL spoke types. Both coexist:

- Stage 7 → Stage 8 forward handoff: comment carries the 9-field Handoff Payload; Agent-tool return carries `verdict: PASS, next: route:stage-8-qa-testing` (or `verdict: FAIL, next: iterate:stage-6-engineering`).
- Stage 8 → Stage 7 return path: comment carries QA Return Payload; Agent-tool return carries `verdict: FAIL, next: iterate:stage-7-dev-testing`.

The Agent-tool channel does NOT duplicate or summarize the Handoff Payload; it carries routing only. The GitHub comment remains authoritative for content per Procedure 4 Step 1.

#### Smoke-test mechanism (three gates)

| Trigger | Mechanism | Outcome |
|---|---|---|
| (a) After EVERY Agent-tool spoke completion (Procedure 4 entry) | Hub regex-tests the Agent return-value message against the 4-field schema + closed-enum membership; on mismatch, emits `[STRUCTURAL-DEFECT: return-value-non-conformant]` and reads the GitHub comment as fallback authority | Warn-mode initial: log to `core/hooks/return-value-warn-log.jsonl`; flip-to-enforce: hub HALTS routing and surfaces Decision Briefing to operator |
| (b) Stage 7 DT review (post-cutover spokes) | LLM-graded content check on free-text content after the 4-field block | Tier 1 finding (Engineering fixes via `fix(dt):` commit per the DT↔Engineering iteration loop) |
| (c) `deploy.sh --check` Check 29 (return-value-conformance lint) | Lints recent Agent-tool return values via sampling parent issue most-recent transcript metadata | Reports drift in `--check` output; warn-mode initial |

Gate (a) is the routing-time gate; gate (b) is the review-time gate; gate (c) is the deploy-time roster check.

#### Warn-mode → enforce-mode shakedown posture

**Initial mode:** warn. Logs to `core/hooks/return-value-warn-log.jsonl` (sibling format to existing `doc-link-warn-log.jsonl` per Check 14 precedent + `egress-warn-log.jsonl` per Check 8 precedent).

**Flip-to-enforce thresholds** (matching `bypass-mode-readiness.md` Shakedown → Enforce Transition Checklist — whichever comes first):

| Threshold | Action |
|---|---|
| 2-3 releases post-merge | Operator-driven warn-log review; non-conformance entries triaged into one of (legitimate-spoke-discovery / allowlist-add / fix Engineering) |
| Warn-log drained to < 10 entries | Flip to enforce via `core/hooks/.mode` or hub-side Procedure 4 enforcement enabling |
| Any release through the shakedown window's end | Operator must explicitly defer flip with rationale at Stage 13 close; silent deferral is a process violation |

#### Enum extension mechanism

The closed enum lives in **this subsection** as the canonical source of truth. Extension of the `verdict` or `next` enums (adding a new value) requires a governed PR with:

1. An R1 Evidence-Grounding artifact per `core/standards/evidence-grounding-standard.md` enumerating current-state usage of existing enum values and justifying the new value against them.
2. Collective Review N-way consistency check on the new value across any sibling Stage 5 specs in the same release that reference the enum.

Drift-by-fiat — silently inventing a new enum value in one spoke's return without governed extension — is a structural defect surfaced by Check 29.

> **Cutover discipline:** Applies to all releases going forward.

#### Spoke drafts the next chip; Hub spawns it

The Hub is the only orchestration agent. It holds the full release context, dependency graph, and operator-authorization scope; spokes do isolated work in their worktree and report results back. A spoke therefore **never launches the next spoke itself** — it does not invoke any spoke-launch primitive (Agent tool or `spawn_task`) for a downstream stage.

When a spoke's deliverable list says "Generate the Stage N chip" (or "generate the next chip"), **"generate" means draft the chip-prompt content for the Hub to use — NOT spawn it.** The spoke:

- Completes its own deliverables (post output comment + close its own sub-task + commit/push if authorized).
- Reports back to the Hub with a brief summary AND the draft chip content inline (the `title` / `tldr` / `prompt` body) so the Hub can spawn it — or modify it before spawning.
- Leaves the spawn step to the Hub.

A spoke that spawns its own next chip bypasses the Hub's orchestration role and breaks the chain of authorization. This composes with the gate-decision ordering below (post decision record + close the gate sub-task before the *Hub* routes the next chip) — both the spoke's verdict closure and the Hub's spawn happen, but the Hub performs the spawn. See also § Recursion prohibited.

### Procedure 4: Spoke Completion Handling

**Trigger:** Operator returns after a spoke session (or batch of spoke sessions).

**Steps:**
1. Read the spoke's output comment on the sub-task(s)
2. Verify sub-task(s) are closed (if not, ask operator if spoke encountered a blocker)
3. Assess: does each output provide what the next stage needs? (check "Output for Stage N+1" section)
4. If output is insufficient, recommend the operator iterate (launch another spoke for the same stage)
5. **Evaluate spoke recommendations** against release context:
   - Cross-issue impact: does this recommendation affect other issues in the release?
   - Pattern consistency: are similar findings across spokes being handled consistently?
   - Cumulative risk: does accepting this recommendation compound risk from other accepted items?
   - Alignment: does the recommendation align with platform conventions, agent operating principles, workflow standards, process governance, and system architecture?
   - Release plan fidelity: does the recommendation deviate from the approved release plan (scope, sequence, stage applicability)?
   - Downstream tier impact: for dependency-tiered execution, does accepting this affect blocked issues in later tiers?
   - **Necessity / value-add:** does this recommendation add something that needs
     to exist? Apply the two-question test: (a) *Does this add
     actionable information that doesn't already exist in the artifact or its
     cross-references?* and (b) *Would removing it change agent or operator
     behavior?* If the answer to both is no, **diverge from the spoke and
     recommend dropping it** — a technically-correct recommendation is not
     automatically a necessary one. Catch-examples the hub diverges on:
     redundant documentation that restates structural semantics already encoded
     elsewhere; unnecessary caveats or interim notes that do not drive a
     downstream decision; defensive "while we're here" additions that expand the
     maintenance surface without changing behavior. This dimension guards against
     rubber-stamping accurate-but-inert spoke output; it is one canonical
     definition — the Decision Briefing's "Decisions required" item (Operating
     Principle §1) applies the same lens at briefing-composition time by
     reference, not by restating it.
   - **Empirical verification** — for each testable claim in the spoke output, the hub runs verification before producing the Decision Briefing. Verification artifacts (commands run, observed results, file:line citations) are quoted in the per-recommendation Empirical Verification subsection of the briefing. Concurrence-without-verification is non-compliant.
6. **Produce a Decision Briefing** per the Operating Principle above, applying mechanisms per `core/disciplines/decision-discipline.md` § 3 triage table:
   - For each decision: spoke recommendation (with rationale) → **Empirical Verification subsection** (per R3 ) → hub evaluation (concurs/diverges with rationale) → final recommendation
   - Per-recommendation Empirical Verification subsection template:
     ```markdown
     ### Spoke recommendation: <one-line summary>
     **Spoke source:** <sub-task # / issue #>
     **Spoke rationale:** <quoted from sub-task output>

     #### Empirical Verification (per R3 )
     **Claim asserted by spoke (testable):** <specific assertion — file exists / command produces output / state matches schema>
     **Verification command / artifact read:** <exact `gh` / `git` / `grep` / file read>
     **Observed result:** <command output OR file:line excerpt OR "matched expected" with evidence>
     **Verdict:** verified-matches / verified-diverges / unverifiable-escalate-to-operator

     #### Hub Evaluation
     **Concur / Diverge:** <concur | diverge>
     **Rationale (release-context overlay):** <hub's broader-context reasoning>
     **Final recommendation to operator:** <action item>
     ```
   - When the spoke recommendation is non-testable (pure design choice, narrative summary), the hub states this explicitly: `Empirical Verification: N/A — recommendation is a design choice with no testable claim` — but only with named rationale. Default-N/A without explanation is a structural defect surfaced by Collective Review.
   - Extract findings that change the release plan (new risks, dependency shifts, discoveries)
   - For batched completions: consolidate into a single briefing, grouped by decision type
7. **Wait for operator to render all decisions** before proceeding
8. Route to next actionable sub-tasks (Procedure 2) only after decisions are approved

### Procedure 4a — Action-Item Scan at Spoke Completion (cross-reference)

**Trigger:** Spoke posts and closes its sub-task — fires as part of Procedure 4 Spoke Completion Handling, before routing the next sub-task per Procedure 2.

**Cross-reference:** Canonical specification lives at [`hub-action-tracking.md` § 4 routing point 3](../../../core/standards/hub-action-tracking.md). The standard specifies: scan `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md` for `status:open` rows with `trigger_type:event` whose `trigger_detail` references this spoke's completion (e.g., *"after Stage 5 closes, post substrate-alignment note"*); auto-transition T2 (`open → in-flight`) for owner-matched rows; hub OR operator executes the action per `owner` field. Hub does NOT duplicate that content here — read the canonical source.

**Why this section exists at this surface:** Procedure 4a binds the hub-consumer entry point to the standard so the action-item scan fires at the right moment in hub workflow — pattern parallel to Procedure 0a's binding of audit-snapshot reconciliation to the hub-decision surface and Procedure 0b's binding of session-resume to session-start.

**Transitional posture (hub → skill):** This binding survives the eventual hub-to-skill replacement. When `release-planner`, `principal-engineer`, or any future decision-producing skill assumes hub responsibilities, the skill imports `hub-action-tracking.md` directly per the standard's `consumers` field. The cross-reference paragraph above remains as archival evidence of where the binding fired during the hub era.

### Procedure 5: Gate Handling

**Trigger:** Next actionable stage is a gate (Stage 9 Plan Review, Stage 12 Execute).

**Pre-condition (main-thread-only narrowing):** Every Decision Briefing rendered at a gate surfaces in the **main-thread Claude Code chat session** via `AskUserQuestion` or equivalent in-chat mechanism per the [Operating Principle § Channel subsection](#channel-main-thread-chat-canonical). The gate decision itself is rendered in main-thread chat; the post-decision record lands as a sub-task comment per Step 4 + a `pipeline-event-log.md` row per the dual-surface convention.

**Steps:**
1. Do NOT generate a spoke prompt — gates are operator decisions
2. Read all prior stage outputs for the issue (release plan from Stage 4, sub-task comments from Stages 5-8)
2a. **Action-item scan (per [`hub-action-tracking.md` § 4 routing point 4](../../../core/standards/hub-action-tracking.md)):** Scan `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md` if present for `status:open` rows with `trigger_type:stage-boundary` whose `trigger_detail` matches the current gate's stage (e.g., "Stage 9", "Stage 12"). Surface triggered rows in the gate Decision Briefing per the Operating Principle "Action items surfaced this routing point" subsection format; operator MAY resolve action item as part of the gate decision.
2b. **Release Readiness Scan (Stage 9 ONLY) per [release-readiness-scan-spec.md](../specs/release-readiness-scan-spec.md):** Hub authors the 13-dimension scan at Stage 9 Phase A6 of evidence assembly per [stage-09-plan-review.md § 5 Phase A](../pipeline/stage-09-plan-review.md). For each of the 13 operator-enumerated dimensions, hub computes status (PASS / FAIL / PARTIAL / N/A) using the per-dim Evidence command per the spec § 5 table. Scan output is dual-surfaced: (a) markdown table posted as a comment on the Stage 9 Plan Review sub-task per spec § 6.1; (b) one `gate-outcome` row with subtype `plan-review-readiness-scan` appended to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per spec § 6.2. The aggregate verdict (ALL-PASS recommends GO / ANY-FAIL recommends NO-GO / ANY-PARTIAL recommends GO-WITH-CONDITIONS) surfaces in the Decision Briefing at Step 3 below as ONE input to the operator GO/NO-GO. The scan is a briefing, not a binding gate — operator may override per the Tier 3 (Human-only) discipline at Stage 9. **Cutover discipline:** Applies to all releases going forward.
3. Present the decision to the operator as a Decision Briefing **in main-thread chat, via `AskUserQuestion` or equivalent in-chat mechanism** (per the Pre-condition above), applying mechanisms per `core/disciplines/decision-discipline.md` § 3 triage table:
   - **Stage 9:** Go/No-Go with summary of what's being released, risk assessment, test results — rendered in main-thread chat via `AskUserQuestion` or equivalent in-chat mechanism.
   - **Stage 9 Empirical Verification:** Hub reads PR diff, RELEASE_LOG entry, and verification evidence section from the release plan; cites observed results in the briefing per the per-recommendation Empirical Verification subsection format (Procedure 4 step 6). Concurrence with spoke verdicts (e.g., "DT PASS", "QA PASS") requires verification — hub re-reads the cited evidence section rather than accepting verdict-as-claim.
   - **Stage 9 review depth by Release Class (per [release-class-taxonomy.md](../specs/release-class-taxonomy.md)):** Hub presents review-depth guidance from the milestone-description `## Release Class` H2 (Standard / Deep / Light) in the Decision Briefing header. `cross-cutting` and `novel` classes invoke **Deep** review (Collective Review N-way consistency + cross-D upstream compatibility + Tier-A artifact refresh-gate G-CL6). `routine` invokes **Standard** review (PR metadata + verification evidence section). `hotfix` invokes **Light** review (defect-fix + regression-clean + rollback-feasibility). Per-class guidance is recommendation, not enforcement — operator may apply Deeper review on any class with documented rationale. Cutover discipline: applies to all releases going forward.
   - **Stage 9 goal-conformance check (G-PR7):** Hub reads the `### Release Outcome Statement` H3 block from the GitHub Milestone description (`gh api repos/{REPO}/milestones/<N> --jq .description`) AND reads PR scope + release plan + each release-scoped issue AC. Renders 1-paragraph synthesis citing AC-trace evidence; produces verdict **ALIGNED** / **DIVERGED-WITH-RATIONALE** / **MISALIGNED**. The verdict appears in the Tier 1 30-second summary AND Tier 2 5-minute detail. Decision Record template extends with optional "Goal-conformance rationale" sub-field (required when verdict = DIVERGED-WITH-RATIONALE). See [`release/references/specs/release-outcome-statement-template.md § 7.2`](../specs/release-outcome-statement-template.md) for the canonical conformance narrative template. **Cutover discipline:** Applies to all releases going forward.
   - **Stage 12:** Execute authorization with deployment procedure summary, rendered in main-thread chat via `AskUserQuestion` or equivalent in-chat mechanism. Note any PRs already merged via Procedure 6 (Early Merge) — these skip the merge step but are included in the release tag and deployment.
   - **Stage 12 Empirical Verification:** Hub runs pre-merge metadata check via `gh pr view <PR> --json milestone,labels,assignees,reviewRequests,projectItems` and cites the JSON output in the briefing; verifies deploy targets exist via `gh api` / `ls` calls cited in the briefing. Concurrence-without-verification at Stage 12 is non-compliant — pre-merge metadata gaps surfaced by verification block the Execute decision pending operator resolution.
   - **Stage 12 chore-PR scope:** Execute authorization in the Decision Briefing covers (a) the release PR merge per Phase B1, AND (b) the Stage 12 chore PR for RELEASE_LOG row + visible-H4 Deployment Log per Phase B5 commit mechanism. The Decision Briefing enumerates both PRs separately when presenting the Stage 12 execution scope; the operator's GO authorizes both.
   - **Gate-class directive enrichment (per `engagement-charter.md` § Per-gate-class framing directives):** Before rendering the `AskUserQuestion` (or equivalent), read the milestone description's `## Gate-Class Framing Directives` block (if present). For the directive whose `gate_class` matches this gate (`stage-9-go-no-go` at Stage 9; `stage-12-execute` at Stage 12), inject each `require_options` entry as an additional selectable option, surface each `surface_dimensions` entry as a displayed dimension, and emphasize each `principles_emphasis` (DP-N) conformance verdict. ADD-only — the directive enriches the briefing; it never suppresses a hub-surfaced item. Composes with the Information Sufficiency clause (the directive NAMES the dimensions; the sufficiency clause enforces they print before the prompt). Absent a matching directive, render hub defaults only.
4. Document the operator's decision as a comment on the gate sub-task
5. Close the gate sub-task

**Decision-then-route ordering (post → close → route):** When the operator renders a gate decision in main-thread chat (a GO/NO-GO, an Execute authorization, or any other operator-judgment verdict), the operator's response IS the trigger to write the decision record — it is NOT a substitute for it. The order is strict and the first two steps come BEFORE any downstream routing:

1. **Post** the decision-record comment on the gate sub-task in the format the sub-task body specifies (typically Decision / Rationale / Risk Acceptance / Outstanding Items; read the sub-task body — other gates may use a different schema).
2. **Close** the gate sub-task with the completed reason.
3. **THEN** route the next chip / next stage.

The decision must be persisted to the Issue surface before the downstream stage starts. Conversational chat history is ephemeral; the audit trail must live on the GitHub Issue. Routing the next chip first leaves the gate sub-task phantom-open while the release moves on — and the milestone close then either sees a dangling sub-task or, worse, closes the milestone with a gate still open. Posting the record retroactively also strands the GitHub timestamp away from the actual decision moment, defeating the audit trail's purpose.

This ordering generalizes to any sub-task whose output spec says "document and close" — gate sub-tasks specifically, but the same discipline applies to any audit-trail artifact the framework requires. Verify at close (Procedure 7): the milestone's open-issue count should read 0 before the milestone is closed; a non-zero count usually means an un-closed gate sub-task carrying a dangling decision record.

**Stage 12 chip-prompt content requirement:** Post-gate, the Stage 12 execution chip prompt MUST reference [`pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md) § Phase J.5 for the rebuild-then-commit hygiene step. Specifically, the chip prompt must instruct the spoke to: (1) compute the rebuilt-package diff against primary via `git -C ${HOME}/Claude diff --name-only packages/` after Phase H deploy completes; (2) if non-empty, stage the explicit package list and commit with message `chore(<version>): rebuilt skill packages from Phase H deploy`; (3) push to main BEFORE the Phase C post-deploy verification block runs. This prevents the orphan-package class observed at Stage 12 — Phase H rebuilt 4 cascade-modified packages but the chip prompt instructed RELEASE_LOG commit only, leaving 4 modifications orphaned on primary's filesystem for ~3 days until forensic discovery. Engineering may copy the full explicit self-exemption cutover form from `pipeline/stage-12-execute.md` § Phase J.5 cutover clause when authoring chip prompts that carry this requirement forward.

**Cutover discipline:** Applies to all releases going forward.

**Stage 12 chip-prompt Deployment Log emit format ( D3):** Post-gate, the Stage 12 execution chip prompt MUST instruct the spoke to emit the Phase B5 Deployment Log content as a **visible H4 `#### Deployment Log v<X.Y>` subsection** appended immediately after the LOG row in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` — NOT as an HTML comment block. The visible-section format surfaces deployment evidence (deployed files, mechanism, timestamp, result per file) to readers in rendered markdown rather than requiring source-view to read HTML comments. See [`pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md) § Phase B5 emit format for the canonical template.

**Cutover discipline:** Applies to all releases going forward.

### Procedure 6: Early Merge

**Trigger:** Routing (Procedure 2) identifies a downstream issue whose next stage is blocked because it needs an upstream issue's changes on main — not just committed to the release branch.

**Criteria (all must be met):**
1. The upstream issue has completed all its per-issue stages (Stages 5-8, as applicable per the Stage 4 applicability matrix)
2. A downstream issue in the release is blocked — its next stage requires the upstream changes to be on main
3. The upstream issue's PR passes pre-merge checks (milestone, labels, assignee, reviewer, project set)
4. Operator approves the early merge

**Steps:**
1. Present the early merge recommendation to the operator as a Decision Briefing:
   - Which issue's PR to merge and why
   - Which downstream issue(s) it unblocks
   - Confirmation that all per-issue stages are complete for the upstream issue
2. On operator approval:
   a. Merge the PR to main: `gh pr merge {PR_NUMBER} --merge`
   b. Pull main: `git checkout main && git pull origin main`
   c. Update the release branch: `git checkout {RELEASE_BRANCH} && git merge main`
   d. Record the early merge in the release state (comment on the release planning sub-task)
3. Resume routing (Procedure 2) — the downstream issue is now unblocked

**State tracking:** The hub maintains a running list of early-merged PRs. At Stage 12 Execute (Procedure 5), these PRs are noted as already merged — the hub skips their merge step but still includes them in the release tag and deployment.

### Procedure 7: Release Close

**Trigger:** All sub-tasks across all issues are closed.

**Standing-GO Authorization Model:**

Stage 9 GO is the operator's irreducible release-authorization decision — it authorizes whole-package execution of every mechanical state-flip downstream of GO, not a per-step gate. Per the governance-theater discipline ("Approved authorizes whole-plan execution, not per-stage gates") and the milestone-close-is-hub-Tier-1 discipline (operator challenge: *"why do I need to do this work?"*), the hub executes the following post-Stage-9-GO actions as **Tier-1 mechanical work under the standing GO authorization** — no per-step operator gate, no operator request:

| Action | Mechanism | Tier |
|---|---|---|
| Merge release PR to main | `gh pr merge <PR>` | Tier-1 (already executed at Stage 12 per `pipeline/stage-12-execute.md` Phase B) |
| Signed-annotated tag push | `git tag -a -m "v<X.Y>-<milestone-slug> — <N> issues; release SHA = merge of PR #<n>" v<X.Y> "$MERGE_SHA" && git push origin v<X.Y>` | Tier-1 (already executed at Stage 12 per `pipeline/stage-12-execute.md` Phase B3) |
| Stage 12 chore PR merge (RELEASE_LOG row + visible-H4 Deployment Log) | `gh pr create` + `gh pr merge` for `chore(v<X.Y>): Stage 12 — RELEASE_LOG row + visible-H4 Deployment Log` | Tier-1 (already executed at Stage 12 per `pipeline/stage-12-execute.md` Phase B5) |
| Stage 13 chore PR merge (INDEX + DIGEST + RELEASE_NOTES + RELEASE_LOG VERIFIED transition) | `gh pr create` + `gh pr merge` for `chore(v<X.Y>): Stage 13 — INDEX + DIGEST + RELEASE_NOTES` | Tier-1 (executed in Step 4 verification pre-conditions per `pipeline/stage-13-close.md § Phase B commit mechanism`) |
| Step 4 completion-verification reads | Five enumerated `gh api` / `git log` / `gh issue list` commands per the Step 4 bash block | Tier-1 (Step 4) |
| Step 4 gate-passage proof comment recording | `gh issue comment <stage-13-subtask> --body "<Verification table + UTC timestamp + merge-SHA>"` | Tier-1 (Step 4) |
| Milestone close | `gh api repos/{REPO}/milestones/<N> -X PATCH -f state=closed` | **Tier-1 (Step 5) — codified by this protocol amendment** |
| Step 6 orphan-state cleanup chip spawn | `mcp__ccd_session__spawn_task` with cleanup script invocation; operator-approves the dry-run report at Tier-1 Recommend gate before `--apply` | Tier-2 within Tier-1 (the chip spawn is hub Tier-1; the `--apply` is the operator's Tier-1-Recommend gate per CLAUDE.md Autonomy Tier table) |

The actually-consequential, hard-to-reverse step (merge to main) executes under the Stage 9 GO at Stage 12; everything downstream is reversible mechanical state recording. **Operator touchpoints are reserved for genuine judgment gates** (Stage 9 GO/NO-GO, Stage 4 D-decisions, Collective Review scope-lock, Tier 0 Premise Rejection, Tier 2/3 inter-stage feedback per `release-process.md § Inter-Stage Feedback Protocol`) — never for reversible mechanical state recording. Re-presenting a routine routing decision as a new operator gate after Stage 9 GO violates the governance-theater principle.

**Operator agency carve-out:** The operator MAY perform any post-Stage-9-GO mechanical state-flip manually if they choose (e.g., closing the Milestone in the GitHub UI; merging a chore PR via the UI). The codification eliminates the *requirement* / *request*, not the *option*. Hub does not request these actions; it executes them and reports observable state changes.

**Mandatory close completeness (outcome-bound):** A release MUST close with its complete enumerated output set produced and verified on main — the canonical Stage 13 output set defined once by the Step 4 Verification table below. The binding is on the **output set**, not on which mechanism produced it. The **mandated mechanism** — the default and expected path — is the automated close-out (release-executor Mode D Close + Mode E Author Note + Mode F Publish, wrapping `automated-closeout.sh`) per `pipeline/stage-13-close.md § Phase A8`. **Hand-assembling the corpus row-by-row is prohibited**: it silently drops outputs (the canonical incident landed only the RELEASE_LOG row of the corpus surfaces — RELEASE_LOG + INDEX + DIGEST + NOTES — leaving the INDEX row, the DIGEST entry, and the RELEASE_NOTES file unwritten until manual review). **Fallback:** when the automated close-out's preflight cannot pass — `gh auth` unavailable, tree not clean, RELEASE_LOG row not yet landed, tag absent (the `automated-closeout.sh` Phase 2 exit-2 conditions) — the operator MAY produce the output set via the documented Phase B chore-PR mechanism per `pipeline/stage-13-close.md § Phase B`; the close is satisfied iff `deploy.sh --check` Check 32 and the Step 4 completion-verification table both pass. Binding one mechanism would strand a close whenever that mechanism's preflight legitimately blocks; binding the outcome and naming the fallback keeps the close always satisfiable.

This mandate is consistent with — and bounded by — the **operator-agency carve-out** directly above: the mandate binds the **output set** (every canonical Stage 13 output exists on main), NOT the *option* for a human to perform an individual mechanical state-flip. The operator MAY still close the Milestone or merge a chore PR via the UI, and MAY perform any single mechanical step of the close by hand; what is mandated is that the outcome — the complete output set, verified — holds however it was produced. A reading that bars a legitimate operator keystroke is a misreading.

**Two gates enforce completeness at different moments.** (1) **Close-time, on-main, full set:** the Step 4 completion-verification table runs before milestone-close and asserts every canonical output is present on main — including the RELEASE_LOG row itself. This gate blocks an incomplete close. (2) **CI regression catch:** `deploy.sh --check` Check 32 is LOG-row-driven and asserts, for each already-landed RELEASE_LOG row, that its INDEX / DIGEST / NOTES (plus post-cutover tag / Release) companions exist (warn-mode-initial during shakedown, per the bypass-mode-readiness ladder). Check 32 cannot flag a release whose LOG row was never written (it iterates LOG rows); LOG-row presence is the Step 4 table's responsibility, not Check 32's.

**Scaffold-independent enforcement of this Step 4 table (Check 48).** The Step 4 completion-verification above is hub-narrative-executed — it fires only if the hub remembers to run Procedure 7. `deploy.sh --check` **Check 48** is its scaffold-independent mirror: it iterates every `VERIFIED` `RELEASE_LOG` row at/after its cutover and asserts the complete canonical Stage 13 output-set (this table's machine-checkable rows) is present on main, **delegating** the note-content sub-assertion to `lint_release_corpus.py --check note-content`, the body-drift sub-assertion to `check-release-body-drift.sh`, and companion-presence to the same path resolution Check 32 uses — no logic is re-implemented. Check 48 fires on a plain `git`-checkout + `deploy.sh --check` with no scaffold, no sub-task body, and no hub session in the loop; the `--check-close-completeness` verdict-driven probe maps the result to a CI exit (fail-closed at the gate surface, swallowed non-blocking by a committed `.github/close-completeness.enforce` sentinel during calibration). Check 48 sits in lane (2) with Check 32 and **inherits the same LOG-row blind spot** — a release whose LOG row was never written is invisible to it; LOG-row presence remains the Step 4 table's responsibility. This is the scaffold-independent completeness gate the Rigor-Invariance Principle (Procedure 1) names as the machine backstop.

**Merge-ahead close-out (operator direct-merge does NOT waive the close outputs):** When the operator merges the release PR directly — bypassing the Stage 12 gate (e.g., an early-merge under Procedure 6, or a direct UI merge to main) — the completeness binding is unchanged: a direct merge satisfies only the "merge to main" step (the one genuinely-consequential, hard-to-reverse action under the Stage 9 GO); it does NOT satisfy, and does NOT waive, the downstream close outputs. The hub still produces the complete canonical Stage 13 output set (the Step 4 Verification table) — default path the automated close-out, fallback the Phase B chore-PR mechanism when preflight blocks (per the outcome-bound mandate above). Where the merge-ahead skipped the signed-annotated tag (per Stage 12 Phase B3) or the published GitHub Release (Surface 1), those are backfilled. Empirical motivation: the recent incomplete closes all originated from a release PR merged directly, after which the close was improvised and dropped outputs. The merge-ahead path is therefore an explicit, supported close path — not an exception that licenses hand-assembly. `automated-closeout.sh` is idempotent per phase, so re-entry after a merge-ahead is safe and converges on the complete output set. The Step 4 completion-verification (below) proves all outputs landed regardless of whether the merge went through the Stage 12 gate or ahead of it.

**Cutover discipline:** Applies to all releases going forward.

**Steps:**
1. Verify every sub-task is closed with output
2. Verify every issue in the Milestone has completed all applicable stages
3. Report final status to operator
3a. **Report decision-discipline metrics for the release:** M2 Opposing-View adoption rate, M3 Pattern Cache Scan applicability rate, count of observations logged this release, count of emergence-confirmations (candidate patterns promoted to permanent entries). Operator reviews for theater signals per `decision-discipline.md` § 6 Metrics.
4. **Completion verification:** Before the hub declares "release complete" / "🎉 RELEASE COMPLETE", the hub MUST independently verify each Stage 13 spec'd output exists on main. This applies the governance-theater discipline — "claim only what is observable on disk or in GitHub state" — to release-close declarations. Empirical motivation: a Stage 13 Close declared "🎉 RELEASE COMPLETE" before verifying the user-facing release note existed on main; the retroactive PR authored the missing artifact. Hub completion-verification closes the loop that the Stage 13 chip pattern (Procedure 3 §Stage 13 Chip Pattern — Release-Notes Authoring Discipline) opens — chip mandates spoke authors the artifact; Hub verifies it landed.

   **Enumerated verification commands** (run each; if any fails, BLOCK closure and route to remediation per [`release-process.md § Inter-Stage Feedback Protocol`](../../governance/release-process.md) Tier 3 Plan Rejection):

   **Audit-class detection — run BEFORE the 5 universal verification commands:** Determines whether the audit-class synthesis verification rows (rows 6-7 below) fire as PASS/FAIL or resolve to N/A. The detection result MUST be reported on its own line BEFORE the verification table is rendered (e.g., *"Audit-class detection: 1 new `<OPERATOR_INSTANCE_ANALYSIS_PATH>/<name>-YYYY-MM-DD/SUMMARY.md` file in this release → release IS audit-class. Audit-synthesis rows below run live."* OR *"Audit-class detection: 0 new `<OPERATOR_INSTANCE_ANALYSIS_PATH>/<name>/SUMMARY.md` files in this release → release is NOT audit-class. Audit-synthesis rows below resolve to N/A."*). This makes the N/A pathway load-bearing rather than silent.

   ```bash
   # Audit-class detection before completion-verification rows 6-7
   # Folder convention per CLAUDE.md governance file map: <OPERATOR_INSTANCE_ANALYSIS_PATH>/<audit-name>-YYYY-MM-DD/SUMMARY.md
   AUDIT_FOLDERS=$(git diff --name-only main...origin/release/<milestone-slug> \
     -- <OPERATOR_INSTANCE_ANALYSIS_PATH>/ \
     | grep -E 'SUMMARY\.md$' \
     | xargs -n1 dirname 2>/dev/null \
     | sort -u)
   if [ -z "$AUDIT_FOLDERS" ]; then
     echo "Audit-class detection: 0 new SUMMARY.md files — release is NOT audit-class; rows 6-7 resolve to N/A"
   else
     echo "Audit-class detection: $(echo "$AUDIT_FOLDERS" | wc -l) new SUMMARY.md file(s) — release IS audit-class:"
     echo "$AUDIT_FOLDERS"
   fi
   ```

   ```bash
   # Hub completion-verification before declaring release closure
   # Run each, verify success; if any fails, BLOCK closure and route to remediation.

   # 1. User-facing release note presence (per the Stage 13 chip pattern)
   # Canonical file-presence instrument: git show origin/main:<path> — shell-glob-immune
   # (no `?` metacharacter risk; safe under any shell + quoting context) and API-independent
   # (no contents-endpoint dependency, no rate-limit budget). Exit 0 = present; non-zero = missing.
   git show origin/main:release/releases/notes/v<X.Y>_RELEASE_NOTES.md >/dev/null 2>&1 \
     || echo "MISSING release notes — block closure"

   # 1b. §3.2 note-content CONFORMANCE (release-notes-standard.md §3.2 — the §3.2 lint
   # runs on EVERY Stage-13 close path, not only release-executor Mode E). Presupposes #1
   # (note present). This is the runbook gate for the pure-hub-direct / Phase-B chore-PR
   # close that does NOT run automated-closeout.sh (the script path is gated in-script by
   # its phase_lint_release_notes phase). Inherited exit contract: 0 clean / 1 finding /
   # 3 path-unresolved — BOTH non-zero outcomes BLOCK. Version-scoped: a finding BLOCKS only
   # when it names THIS version's note (a pre-existing legacy finding for another version is
   # out of scope — audit-baseline discipline). It is a conformance assertion on the already-
   # listed note output, NOT a new output row in the canonical Step 4 table.
   note_lint_out=$(/usr/bin/python3 core/deploy/tools/lint_release_corpus.py --check note-content 2>&1); note_lint_rc=$?
   if [ $note_lint_rc -eq 3 ]; then
     echo "§3.2 lint path-unresolved (exit 3) — corpus unverifiable; BLOCK closure (fail-loud)"
   elif [ $note_lint_rc -ne 0 ] && echo "$note_lint_out" | grep -qF "release/releases/notes/v<X.Y>_RELEASE_NOTES.md"; then
     echo "§3.2 note-content finding for v<X.Y> — BLOCK closure (release-notes-standard.md §3.2 'Lint failures block Milestone close')"
   else
     echo "§3.2 note-content conformant for v<X.Y> (clean, or only legacy other-version findings — out of scope)"
   fi

   # 2. Version tag exists on origin
   gh api repos/{REPO}/git/refs/tags/v<X.Y> \
     --jq '.ref' || echo "MISSING tag — block closure"

   # 3. Milestone state closed
   gh api repos/{REPO}/milestones/<N> \
     --jq '.state' | grep -q "^closed$" || echo "Milestone NOT closed — block closure"

   # 4. RELEASE_LOG entry present (assert the CONTENT on main, not a commit-message
   # grep). The Stage-12/13 chore PRs land the LOG content as a pipe-row in the
   # `## Releases` table PLUS a visible-H4 `#### Deployment Log v<X.Y>` block; a
   # `git log --grep` on commit messages is the wrong instrument (it asserts a
   # commit subject, not that the row + block actually exist on main, and a
   # squash/edit-titled merge would evade it). Assert BOTH the row and the block.
   # (a) table row — the live form is bare-version-first `| v<X.Y> | <milestone> | …`
   git show origin/main:release/releases/RELEASE_LOG.md \
     | grep -qE "^\| v<X.Y> " \
     || echo "RELEASE_LOG row for v<X.Y> MISSING from main — block closure"
   # (b) visible-H4 Deployment Log block
   git show origin/main:release/releases/RELEASE_LOG.md \
     | grep -qE "^#### Deployment Log v<X.Y>" \
     || echo "RELEASE_LOG visible-H4 'Deployment Log v<X.Y>' block MISSING from main — block closure"

   # 5. Every release sub-issue closed
   gh issue list --milestone "v<X.Y>-<slug>" --state open --json number \
     --jq 'if length == 0 then "all closed" else "BLOCK — open issues remain" end'

   # 6. (Layer-1 dual-write) GitHub Release published (Surface 1)
   # Verifies Stage 12 Phase B5.5 emit landed; if missing, operator may invoke release-executor Mode F standalone
   gh release view v<X.Y> --repo {REPO} >/dev/null 2>&1 \
     || echo "MISSING GitHub Release v<X.Y> — operator decision required (invoke Mode F to publish, OR accept residual)"

   # 6b. (Layer-1 dual-write) Surface 1 body == frontmatter-stripped in-repo note (release-notes-standard.md §5.1)
   # Asserts the published Release body is the deterministic transform of the source-of-record note — not an ad-hoc
   # draft and not stale after a note correction. Single source of the equality logic (shared with deploy.sh Check 47);
   # detective-only (it never re-emits). Exit 0 = match; 1 = DRIFT (re-emit per §5.6 / Mode F); 2 = N/A (gh offline); 3 = Surface 1 / note absent.
   REPO={REPO} ./release/tools/check-release-body-drift.sh v<X.Y> \
     || echo "DRIFT — published Release body diverged from the in-repo note (§5.1); re-emit the body via the §5.6 deterministic transform OR release-executor Mode F"

   # 7. (Layer-1 dual-write) CHANGELOG.md entry present (Surface 2)
   # SKIP semantics: if CHANGELOG.md does not exist at repo root (pre-CHANGELOG state), the check resolves to N/A
   if git show origin/main:CHANGELOG.md >/dev/null 2>&1; then
     git show origin/main:CHANGELOG.md \
       | grep -qE "^## \[?v<X.Y>\]?[[:space:]]" \
       || echo "MISSING CHANGELOG entry for v<X.Y> — block closure"
   else
     echo "CHANGELOG.md not present at repo root (pre-CHANGELOG state) — Surface 2 check resolves to N/A"
   fi

   # 8. .version stamped (release-cut-owned version source-of-truth, per pipeline/stage-13-close.md Phase B5.7)
   # N/A semantics: for a version-less release there is no vX.Y to stamp (Phase B5.7 SKIPs with PASS) — the check resolves to N/A
   git show origin/main:.version | grep -qx "v<X.Y>" \
     || echo "MISSING .version stamp for v<X.Y> on main — block closure (N/A for version-less release)"
   ```

   **Hub Decision Briefing addition:** The hub's final-summary Decision Briefing at release close MUST include a structured **"Verification"** subsection (table format) listing each spec'd output alongside its verification command result (PASS/FAIL). This is the Procedure-7-specific instantiation of the [Operating Principle: Decision Briefing](#operating-principle-decision-briefing) §"Status summary" requirement — at release-close briefing, "status summary" includes explicit per-output verification evidence. Minimal table template:

   **This table is the canonical Stage 13 output set; close-mandate prose references it by name and never re-enumerates it.** Every row is a required output of a complete close (the two audit-class rows resolve to N/A on a non-audit-class release — N/A is a satisfied state, not a missing one). Prose elsewhere that names the close outputs cites "the canonical Stage 13 output set (this table)" rather than re-listing the rows; a hand-written enumeration drifts from the table and miscounts it.

   ```markdown
   ### Verification
   | Output | Verification | Result |
   |---|---|---|
   | User-facing release note | `git show origin/main:.../v<X.Y>_RELEASE_NOTES.md` (presence, cmd #1) **+ §3.2 note-content conformance (cmd #1b: `lint_release_corpus.py --check note-content`, version-scoped — a finding for v<X.Y> BLOCKS)** | PASS/FAIL |
   | Version tag | `gh api .../git/refs/tags/v<X.Y>` | PASS/FAIL |
   | Milestone closed | `gh api .../milestones/<N>` | PASS/FAIL |
   | RELEASE_LOG entry | `git log --grep ...` | PASS/FAIL |
   | Sub-issues closed | `gh issue list --state open` | PASS/FAIL |
   | GitHub Release (Surface 1, Layer-1 dual-write) | `gh release view v<X.Y> --repo {REPO}` exit 0 | PASS/FAIL |
   | Surface 1 body matches in-repo note (§5.1 enforced transform) | `./release/tools/check-release-body-drift.sh v<X.Y>` exit 0 (published body == frontmatter-stripped note); detective-only, shares logic with deploy.sh Check 47; N/A if gh offline | PASS/FAIL/N/A |
   | CHANGELOG.md entry (Surface 2, Layer-1 dual-write) | `git show origin/main:CHANGELOG.md \| grep -qE "^## \[?v<X.Y>\]?[[:space:]]"` exit 0; N/A if CHANGELOG.md absent (pre-CHANGELOG state) | PASS/FAIL/N/A |
   | .version stamped (release-cut-owned) | `git show origin/main:.version \| grep -qx v<X.Y>` exit 0; N/A for version-less release (Phase B5.7 SKIP) | PASS/FAIL/N/A |
   | Posted Release TITLE versioned (Surface 1, posted-surface) | `gh release view v<X.Y> --repo {REPO} --json name --jq '.name' \| grep -qE '^v[0-9]+\.[0-9]+([a-z]\|-[0-9a-z][-0-9a-z]*)? — .'` exit 0 — the posted title reads `vX.Y — <headline>`, not the bare H1 headline; N/A for a version-less release | PASS/FAIL/N/A |
   | Posted Release BODY link-resolvable (Surface 1, posted-surface) | `gh release view v<X.Y> --repo {REPO} --json body --jq '.body' \| grep -nE '\]\((\.\.?/\|release/\|core/\|docs/)'` returns NO match — the published body carries no repo-relative link (a repo-relative link 404s on the Release page) | PASS/FAIL |
   | Audit-class synthesis (audit-class only) | `gh issue list --milestone <target-milestone> --search "in:body \"<audit-folder-name>\""` returns N where N = recommendations count per Stage 4 D-decision granularity rule | PASS/FAIL/N/A |
   | Audit retro Milestone tags (audit-class only) | For each filed Issue: `gh issue view <N> --json milestone --jq '.milestone.title'` returns non-null = `<target-milestone>` | PASS/FAIL/N/A |
   ```

   **Posted-surface verify (Surface 1, posted-surface rows):** The two posted-surface rows above read the LIVE GitHub Release via `gh release view` — distinct from the structural Check 20 lint (which lints the committed in-repo note file and cannot see the posted page). They catch the title-composition and link-resolvability defects that are invisible to Check 20: a bare-H1 (un-versioned) posted title, and a repo-relative body link that resolves in the file tree but 404s on `releases/tag/vX.Y`. Both run read-only (no git mutation), compose with the existing read-only Step-4 block, and BLOCK closure on failure under the same severity as the other Surface-1 checks. The body-link check is the posted-surface companion to the in-repo whole-body link-purity lint (release-notes-standard.md §3.2 check 13). Cutover: applies to releases entering Stage 13 going forward; the introducing release closes under the pre-merge runbook (reflexive-pipeline-loop discipline).

   **Sequencing note:** The Milestone-closed check (#3) is the only verification that depends on Step 5's PATCH having fired (it asserts `state == closed`). Hub runs verification commands #1, #2, #4, #5 first (which gate the Step 5 hub PATCH), proceeds to Step 5 (PATCH), then re-runs check #3 to confirm `state=closed`. Final "🎉 RELEASE COMPLETE" declaration awaits all 5 universal checks PASSing AND (audit-class only) checks 6-7 PASSing.

   **Stage 13 chore PR landing:** Verification commands #1 (release-notes presence) AND #4 (RELEASE_LOG entry on main) BOTH verify the Stage 13 chore PR has landed. If either command fails, the Stage 13 chore PR is missing OR has not yet merged to main — BLOCK closure pending chore PR landing. The hub MAY run commands #1 + #4 immediately after `gh pr merge` of the Stage 13 chore PR (before operator's Milestone close action) as a chore-PR-landing confirmation, then run command #3 (Milestone state) after operator closes. Per the milestone-close-is-hub-Tier-1 discipline, Milestone close itself runs as hub Tier-1 mechanical post-chore-PR-merge — Hub closes Milestone, does not impose a manual operator step.

   **Cutover discipline:** Applies to all releases going forward.

   **Cutover discipline:** Applies to all releases going forward.

   **Gate-passage proof recording:** After computing the Verification table (above per the completion-verification step), the hub MUST post the table as a comment on the Stage 13 Close sub-task BEFORE the operator's Milestone close action (current Step 5). This comment becomes the durable gate-passage proof — single-glance auditability via the Stage 13 sub-task comment thread, queryable via `gh issue view <stage-13-subtask> --comments`, timestamped at moment-of-closure. The comment MUST include: (a) the Verification table contents (per output: verification command + PASS/FAIL/PENDING result), (b) UTC timestamp captured via `$(date -u +%Y-%m-%dT%H:%M:%SZ)`, (c) the merge commit SHA captured at Stage 12 (per Procedure 3 §Stage 12 Chip Pattern — Tag-SHA-Direct Discipline). Empirical motivation: a release closed its Milestone at 2026-05-11T01:50:37Z, but the release note was authored retroactively via a follow-up PR — close metadata gave no signal that the gate criterion was unsatisfied at moment-of-closure. Per the gate-passage proof recording protocol, recording the gate-passage proof on the Stage 13 sub-task at moment-of-closure closes this auditability gap and PROVES the triad worked (FOUNDATION → VERIFIES → PROVES).

   **Verification proof comment template** (this heredoc *renders* the canonical Stage 13 output set defined above with per-row results filled in — it is a worked example of the proof artifact, not a second definition of the set):

   ```bash
   # record gate-passage proof on Stage 13 sub-task before Milestone close
   gh issue comment <stage-13-subtask-number> --repo {REPO} --body "$(cat <<EOF
   ## Gate-Passage Proof — v<X.Y> Stage 13 Close

   **Recorded at:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
   **Merge commit SHA:** <captured at Stage 12 via gh pr view <PR> --json mergeCommit --jq '.mergeCommit.oid'>

   ### Verification
   | Output | Verification | Result |
   |---|---|---|
   | User-facing release note | \`git show origin/main:.../v<X.Y>_RELEASE_NOTES.md\` | PASS |
   | Version tag | \`gh api .../git/refs/tags/v<X.Y>\` | PASS |
   | Milestone closed | \`gh api .../milestones/<N>\` | PENDING (about to close) |
   | RELEASE_LOG entry | \`git log --grep ...\` | PASS |
   | Sub-issues closed | \`gh issue list --state open\` | PASS |
   | GitHub Release (Surface 1, Layer-1 dual-write) | \`gh release view v<X.Y> --repo {REPO}\` | PASS |
   | CHANGELOG.md entry (Surface 2, Layer-1 dual-write) | \`git show origin/main:CHANGELOG.md | grep -qE "^## \[?v<X.Y>\]?[[:space:]]"\` | PASS / N/A (pre-CHANGELOG state) |
   | .version stamped (release-cut-owned) | \`git show origin/main:.version | grep -qx v<X.Y>\` | PASS / N/A (version-less release) |
   | Posted Release TITLE versioned (Surface 1, posted-surface) | \`gh release view v<X.Y> --repo {REPO} --json name --jq '.name' | grep -qE '^v[0-9]+\.[0-9]+( |-)\` | PASS / N/A (version-less release) |
   | Posted Release BODY link-resolvable (Surface 1, posted-surface) | \`gh release view v<X.Y> --repo {REPO} --json body --jq '.body' | grep -nE '\]\((\.\.?/|release/|core/|docs/)'\` no match | PASS |
   | Audit-class synthesis (audit-class only) | \`gh issue list --milestone <target> --search "in:body \"<audit-folder>\""\` | N/A (non-audit-class release) |
   | Audit retro Milestone tags (audit-class only) | For each filed Issue: \`gh issue view <N> --json milestone\` | N/A (non-audit-class release) |

   All Stage 13 gated outputs verified present on main. Authorizing Milestone close.
   EOF
   )"
   ```

   The comment must land BEFORE the operator's Milestone close action (`gh api repos/.../milestones/<N> -X PATCH -F state=closed` or operator-clicked close) — this preserves the gate-passage proof in the Stage 13 sub-task comment thread (durable, queryable, timestamped) regardless of later Milestone metadata mutations. Future auditors reading the Stage 13 sub-task `--comments` see the single-glance verification evidence at moment-of-closure; no cross-referencing of release notes commit history, RELEASE_LOG entries, and Milestone close timestamps required.

   **Cutover discipline:** Applies to all releases going forward.
5. **Hub closes the Milestone (Tier-1 mechanical, per Standing-GO Authorization Model above):** `gh api repos/{REPO}/milestones/<N> -X PATCH -f state=closed`. After the PATCH succeeds, the hub re-runs Verification command #3 (Milestone state) and updates the gate-passage proof comment row from `PENDING` to `PASS`. The operator MAY perform this action manually via the GitHub UI if preferred — hub does not request or block on operator action.
6. **Orphan state cleanup chip:** After Step 5 Milestone close (and after the Stage 13 chore PR has merged), the hub spawns a Stage 13 cleanup chip directing the spoke to:
   1. Invoke [`./release/tools/cleanup-orphan-state.sh`](../../tools/cleanup-orphan-state.sh) `--release-close <milestone-slug> --dry-run --markdown` (safe default).
   2. Post the markdown report as a comment on the Stage 13 sub-task.
   3. Await operator approval (Tier 1 Recommend gate per [CLAUDE.md Autonomy Tier table](<OPERATOR_INSTANCE_CLAUDE_MD>)).
   4. Re-invoke with `--apply --markdown` (and `--force` ONLY if operator explicitly approves `-D` / `--force` removals) and post the post-removal PASS/SKIPPED/FAIL report as a second sub-task comment (durable record).

   **Sequencing requirement:** Cleanup chip MUST be spawned AFTER (a) the Stage 13 chore PR has merged on `origin/main` AND (b) the Milestone has closed at Step 5. Otherwise the release branch is not yet fully-merged on `origin/main` (zero unique commits) and the script will classify it as SKIP — defeating the purpose. The chore-PR landing is verified by Step 4's enumerated verification commands #1 + #4 (release-notes presence + RELEASE_LOG entry on main).

   **Out-of-scope: spawn-task lifecycle sweep.** Procedure 7 cleanup chip targets release-close orphans (Outcome 1). For the workspace-wide claude/* spawn-task sweep (Outcome 2) and historical sweep (Outcome 3), the operator invokes the script directly per [`core/rules/git-workflow.md` § PR Process Step 10](../../../core/rules/git-workflow.md) — NOT as part of Procedure 7.

   **Cutover discipline:** Applies to all releases going forward.

### Procedure 7a — Action-Item Resolution Gate at Close (cross-reference, HARD GATE)

**Trigger:** Stage 13 Milestone close — fires as part of Procedure 7 Release Close, BEFORE the Milestone-close PATCH (current Procedure 7 Step 5).

**Cross-reference:** Canonical specification lives at [`hub-action-tracking.md` § 4 routing point 5](../../../core/standards/hub-action-tracking.md). The standard specifies: scan `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md` for ALL `status:open` AND `status:in-flight` rows; HARD GATE — operator MUST resolve each remaining row (transition to `done`, `cancelled`, or `superseded`) BEFORE Milestone close; carry-forward to the next release is via `superseded` with explicit successor AI-NNN in the next release's `action-items.md` (implicit carry-forward prohibited). Hub does NOT duplicate that content here — read the canonical source.

**Composition with Procedure 7 Step 4 completion-verification table:** When `action-items.md` exists for the release, Procedure 7 Step 4's Verification table per the gate-passage proof recording SHALL include an additional row covering the action-item resolution gate:

```markdown
| Action items resolved | `grep -E '^\| AI-[0-9]+ \|.*\| (open|in-flight) \|' <OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md \| wc -l` returns 0 | PASS/FAIL |
```

When the row returns non-zero, BLOCK closure pending operator disposition of the remaining open/in-flight rows — same severity tier as the other Procedure 7 Step 4 verification commands (missing release notes, open release issues). When `action-items.md` does NOT exist for the release (no action items were ever emitted), the row resolves to N/A and the gate is vacuously satisfied.

**Why this section exists at this surface:** Procedure 7a binds the hub-consumer entry point to the standard so the action-item HARD GATE fires at the right moment in hub workflow — pattern parallel to Procedure 0a's binding of audit-snapshot reconciliation and Procedure 0b's binding of session-resume. The HARD GATE enforces CLAUDE.md "Push-to-resolve" universal preference at release-close boundary: open action items at close are by definition a "to-do list without resolution," which the workspace-global preference prohibits.

**Transitional posture (hub → skill):** This binding survives the eventual hub-to-skill replacement. When `release-planner`, `principal-engineer`, or any future decision-producing skill assumes hub responsibilities, the skill imports `hub-action-tracking.md` directly per the standard's `consumers` field. The cross-reference paragraph above remains as archival evidence of where the binding fired during the hub era.

**Cutover discipline:** Applies to all releases going forward.

---

## Spoke Launch Mechanisms

The hub launches spokes via one of two mechanisms. The default
is the Anthropic **Agent tool** (6-parameter in-session
invocation); manual copy/paste is the fallback. The Agent tool
replaces the prior `spawn_task` chip-launch convention.

### Default: Agent tool

Tool: Anthropic `Agent` (in-session orchestration primitive;
6-parameter signature per the Anthropic Claude Code harness
upstream tool definition).
Signature: `{subagent_type, prompt, description, model, isolation, run_in_background}`

| Parameter | Type | Required | Hub-side semantic |
|---|---|---|---|
| `subagent_type` | string | YES | Persona/agent definition name; resolves to a [Stage-to-Persona Mapping](#stage-to-persona-mapping) row (the persona card from `release/references/specs/release-personas.md` that spoke embodies). |
| `prompt` | string | YES | Full spoke prompt per the applicable Spoke Template (Procedure 0 for Stage 4; Procedure 3 for Stages 5-13). Self-contained per existing convention. |
| `description` | string (3-5 words) | YES | Short label `"Stage {N} {ShortName} — #{ISSUE}"` (per-issue) or `"Stage {N} {ShortName} — {MILESTONE}"` (release-scoped). Replaces the prior `title` chip-label field. |
| `model` | enum: `sonnet`\|`opus`\|`haiku` | REQUIRED-EXPLICIT (PMO-side composition layer over upstream-OPTIONAL semantics; see § Model Parameter Required-Explicit subsection below) | Designated model per the workspace model-preference rule (default `opus`); explicit per-invocation pin guards against silent model degradation. Anthropic upstream Agent tool surface treats this parameter as OPTIONAL with cascade tier 2 fallback to the agent-definition default at `.claude/agents/<name>.md` frontmatter; PMO surface makes it REQUIRED-EXPLICIT as belt-and-suspenders defense. |
| `isolation` | enum: `"worktree"` | OPTIONAL | Creates an isolated git worktree as the spoke's working directory. Semantics IDENTICAL to the prior chip-launched-worktree convention (Procedure 3 § Worktree discipline). Engineering + content-modifying spokes (Stage 6 / 12 / 13) MUST pin `isolation: "worktree"`; read-only stages (5 / 7 / 8) MAY pin defensively. |
| `run_in_background` | boolean | OPTIONAL (default `false`) | Sync default — Agent blocks the hub session until the spoke completes and returns its result inline. Background mode (`true`) enables async-class invocation; the harness notifies the hub on completion. Composes with  main-thread-only narrowing's queued-resumption path. |

Short stage names (for the `description` parameter): Planning,
Solutioning, Engineering, Dev Testing, QA Testing, Execute, Close.

**Canonical invocation pattern (hub-side syntax):**

```
Agent({
  subagent_type: "<persona-key-per-release-personas-md>",
  description: "Stage {N} {ShortName} — #{ISSUE}",
  model: "opus",
  prompt: "{full-spoke-prompt-per-Procedure-3-Spoke-Template}",
  isolation: "worktree",
  run_in_background: false
})
```

The hub invokes the Agent tool directly within its own session
turn — no operator chip click required. The hub prints a brief
acknowledgement: *"Hub auto-launches the spoke within authorized
scope; awaits result inline (Stage {N} {Name} — #{ISSUE})."*
When `run_in_background: false` (the default), the hub session
blocks on the spoke's completion and consumes the returned
message inline. When `run_in_background: true`, the harness
notifies the hub on completion and the hub reads the durable
record from the sub-task comment per Procedure 4.

When Procedure 2 routing identifies multiple actionable
sub-tasks in parallel (e.g., Stage 5 across several issues),
the hub issues one Agent invocation per actionable sub-task in
the same response, subject to the parallelism rules in
Procedure 2 Step 5 (Stage 5/7/8 parallel-safe; Stage 6/13
write-serialized). For the per-account 5-hour usage-window
constraint on these parallel launches and the quota-budgeting /
window-aware-timing / serialize-on-failure mitigations, see
§ Per-Account Usage Window Constraint below. Before issuing the
batch, the hub runs Checkpoint B of the quota-budget gate
(Procedure 2 Step 5.5 / [`../standards/quota-budget-protocol.md`](../standards/quota-budget-protocol.md))
and acts on its verdict — PROCEED launches all N; SERIALIZE
launches one at a time; DEFER holds the batch for the next
window (with an operator override-to-PROCEED exit); REDUCE-scope
launches with a smaller per-wave footprint. STAGGER is a
secondary rate-limit-only defense, not a usage-window mitigation.

**Composition with  Agent Handoff Framework:** 's
9-field handoff manifest defines the contract layer; the Agent
tool's 6-parameter invocation surface carries that contract.
The manifest's `source_agent` / `target_agent` / `intent` /
`payload` / `confirmation_requirement` / `error_handling` /
`cascade_depth` / `evidence_quality` / `scope` fields embed in
the `prompt` body OR resolve to a specific parameter
(`target_agent` → `subagent_type`; `confirmation_requirement`
→ `run_in_background`). See the Stage 5 Solutioning spec
for the full manifest-to-invocation-site mapping.

**Tracking open spokes:**

| Mode | Tracking mechanism |
|---|---|
| Sync (`run_in_background: false`) | Agent tool blocks the hub turn; "open" state is transient (within a single hub message); no external tracking required. |
| Background (`run_in_background: true`) | Per the Agent tool spec, the harness automatically notifies on completion. The hub does NOT poll. Hub MAY enumerate active background agents via the in-session task list when one becomes available. |

**Cutover discipline:** Applies to all releases going forward.

### Stage-Conditional Launch Policy

Per Stage 5 ADR (a): CHEAP-tier triage / review spokes auto-launch
via Agent tool under Autonomy Tier 2 (Bounded Auto) /
Tier 3 (Autonomous, post-authorization) authorization;
EXPENSIVE-tier gate decisions preserve operator gate at
Autonomy Tier 0 (Manual). Decision tree binds to the Autonomy
Tier classification per [`autonomy-tiers.md`](../../../core/specs/autonomy-tiers.md).

**Decision tree:**

```
Per-stage spoke launch decision:

1. CONSULT Stage-to-Autonomy-Tier mapping (table below).

2. IF stage's Autonomy Tier ∈ {Tier 2 Bounded Auto, Tier 3 Autonomous} AND
   the spoke's scope is within the stage's pre-authorized cascade scope:
   → AUTO-LAUNCH via Agent tool (no per-instance operator approval)
   → Surface "Spoke launched: Stage {N} #{ISSUE}" notification in main-thread chat
   → Read spoke output from sub-task comment upon completion notification

3. ELSE IF stage's Autonomy Tier == Tier 0 Manual (operator-only):
   → SURFACE Decision Briefing to operator in main-thread chat
   → AWAIT operator verdict (rendered in chat)
   → After verdict, record per [`hub-session-continuity.md` § Decision Log Mechanism](../../../core/standards/hub-session-continuity.md)
       (dual-surface: sub-task comment + pipeline-event-log row)
   → Do NOT invoke Agent tool for the gate decision itself; Agent tool may
     fire for post-gate downstream work AFTER verdict renders

4. ELSE IF stage's Autonomy Tier == Tier 1 Recommend (draft awaiting review):
   → AUTO-LAUNCH spoke to produce draft via Agent tool
   → After spoke completes, SURFACE draft to operator via Decision Briefing
   → AWAIT operator approval before any downstream cascade

5. CHECK reversibility tier per [`reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md):
   → IRREVERSIBLE actions cannot be auto-launched regardless of stage's
     Autonomy Tier (per autonomy-tiers.md Boundary Test 3)
   → EXPENSIVE actions require explicit standing authorization citation
```

**Stage-to-Autonomy-Tier mapping (canonical table; consumed by Step 1 of decision tree):**

| Stage | Autonomy Tier (pre-gate / post-gate) | Auto-launch via Agent tool? |
|---|---|---|
| Stage 2 Triage | Tier 2 | YES |
| Stage 3 Bundle | Tier 2 | YES |
| Stage 4 Planning | Tier 2 | YES |
| Stage 5 Solutioning | Tier 2 | YES |
| Stage 6 Engineering | Tier 0 (pre-scope-lock) → Tier 3 (post-scope-lock) | NO before Collective Review approval; YES after |
| Stage 7 Dev Testing | Tier 2 | YES |
| Stage 8 QA Testing | Tier 2 | YES |
| **Stage 9 Plan Review** | **Tier 0 (Manual; permanent — Irreducible Human Task #4)** | **NEVER** |
| Stage 10 Dry Run (compressed) | (N/A — git-native) | N/A |
| Stage 11 Snapshot (compressed) | (N/A — git-native) | N/A |
| **Stage 12 Execute** | **Tier 0 (gate; Irreducible Human Task #5) → Tier 3 (post-authorization)** | **NEVER at gate; YES for post-authorization deploy steps** |
| Stage 13 Close | Tier 3 (post Stage 12) | YES |

**Composition with [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md):**
This decision tree IS the per-stage "WHO acts under what
authorization" surface that `autonomous-execution-model.md`
frames at the agent action level. The Agent-tool invocation is
the executable form of "agent acts within scope"; this policy
binds the executable form to the stage-level Autonomy Tier
classification.

**Composition with [`engagement-charter.md`](../../../core/specs/engagement-charter.md):**
The Decision Briefing surface (per the Operating Principle
above) remains the engagement vehicle when Tier 0 paths fire.
No new engagement surface introduced; existing chat-based
Decision Briefing convention preserves continuity with operator
workflow.

**Reversibility / Confidence:** EXPENSIVE / HIGH. The
classification table pins per-stage automation policy across
the platform's release pipeline; changing it after consumers
(release-executor Modes, future skills replacing hub) bind
against it requires coordinated update. Confidence HIGH per
parent-issue explicit framing + autonomy-tiers.md operational
precedent.

**Cutover discipline:** Applies to all releases going forward.

### Device-Portable Engagement Mandate

Per Stage 5 ADR (b): device-portable / async-tolerant is a HARD
CONSTRAINT, not a preference, for operator-engagement events
surfaced by hub orchestration. The constraint applies to
engagement surfaces; agent-internal orchestration primitives
(Agent tool invocation from a hub session) are NOT engagement
surfaces.

**Mandate (canonical form):**

> Every operator-engagement event surfaced by hub orchestration
> (Decision Briefings, gate authorization requests, scope-lock
> decisions, escalations) MUST be reachable from a
> device-portable client surface. The canonical surface is the
> Claude Code main-thread chat session, which IS device-portable
> when consumed through any of the following Claude Code client
> surfaces:
>
> - Desktop application (Mac / Windows)
> - Web application (claude.ai/code)
> - IDE extensions (VS Code, JetBrains)
> - Mobile (any device with browser access to claude.ai/code)
>
> Any new automation path that adds a non-device-portable
> operator touchpoint (e.g., terminal-bound `spawn_task` chip
> click, file-system-dependent operator action, OS-specific UI
> invocation) is structurally rejected unless paired with an
> explicit mitigation registered as a future-state extension.

**Composition with  main-thread-only narrowing:**
narrows the device-portable mandate's surface enumeration to a
SINGLE specific channel — main-thread Claude Code chat. The
narrowing is COMPATIBLE with this mandate because main-thread
chat satisfies the device-portable axiom when consumed through
any client surface (desktop/web/mobile per the canonical-form
bullet above). The narrowing trades surface breadth (GitHub
Issues, Obsidian, repo edits — all listed in
[`automation.md`](<OPERATOR_INSTANCE_ROADMAPS_PATH>/automation.md) §2
as candidate surfaces) for engagement simplicity (single
channel; no surface fragmentation).

**Boundary clarification — engagement vs orchestration:**
The mandate applies to OPERATOR ENGAGEMENT surfaces, not to
AGENT ORCHESTRATION primitives. The Agent tool invocation from
a hub session is an orchestration primitive — it executes the
work the operator engaged with on the main-thread surface.
Whether the Agent tool itself runs in a desktop, web, or future
surface is irrelevant to the mandate; what matters is that
EVERY OPERATOR DECISION POINT is reachable on a device-portable
surface.

**spawn_task as the explicit anti-pattern (at the hub-side
spoke-launch surface):** Per
[`automation.md`](<OPERATOR_INSTANCE_ROADMAPS_PATH>/automation.md) §2
Boundary: *"Existing terminal-bound surfaces (e.g., `spawn_task`
chips per `hub-spoke-bridge.md`) are constraints to be removed
or contained, not extended."* This mandate removes the
operator-side `spawn_task` engagement requirement entirely. The
hub no longer surfaces chip-click engagement to the operator
for routine work; Agent-tool invocation happens internally
without per-spoke operator action. Operator engagement
compresses to: (1) main-thread Decision Briefings for Tier 0
gates, (2) main-thread approval of bundled spoke outputs at
framework gates (scope-lock, Stage 9 GO, Stage 12 authorization).
The `spawn_task` tool retains its operator-facing
out-of-scope-flagging role per its own tool description — the
mandate scope-clarifies, it does not deprecate `spawn_task`
across all uses.

**Future-state extensions (deliberately deferred):**

Three candidate engagement surfaces from
[`automation.md`](<OPERATOR_INSTANCE_ROADMAPS_PATH>/automation.md) §2
remain available for future extension WITHOUT contradicting
's narrowing:

| Future surface | Status | Path to activation |
|---|---|---|
| GitHub Issue comment as engagement surface | Deferred (main-thread-only is the immediate state) | Future intake ticket if operator preferences evolve |
| Obsidian edit as async engagement | Deferred (same) | Future intake ticket; would require sync-back mechanism |
| Mobile-optimized Decision Briefing format | Deferred (no current evidence operator engages from mobile) | Future intake ticket triggered by operator preference signal |

**Reversibility / Confidence:** EXPENSIVE / HIGH. The
hard-constraint posture is structurally binding for all future
automation work; relaxing it would require explicit
re-authorization per a stabilization-class ticket. Confidence HIGH per
[`automation.md`](<OPERATOR_INSTANCE_ROADMAPS_PATH>/automation.md) §2
Boundary axiom (operator-stated; 2026-04-24).

**Cutover discipline:** Applies to all releases going forward.

### Model Parameter Required-Explicit

Per the Stage 5 ADR, Dimension 4: every `Agent` tool invocation issued by the hub MUST include the `model` parameter explicitly. This is a PMO-side composition layer over the Anthropic upstream-OPTIONAL semantics — defense-in-depth against silent model degradation when an agent-definition file is missing, malformed, or its frontmatter accidentally edited.

**Anthropic upstream cascade (background):** The Agent tool's `model` parameter description (verbatim from the system-prompt-resident tool definition): *"Optional model override for this agent. Takes precedence over the agent definition's model frontmatter. If omitted, uses the agent definition's model, or inherits from the parent."* Three-tier cascade — tier 1 (per-invocation `model` parameter) > tier 2 (agent-definition `model:` frontmatter at `.claude/agents/<name>.md`) > tier 3 (parent-session model). PMO surface pins tier 1 + tier 2 with structurally identical values; tier 3 inheritance alone is rejected per the detection mechanism.

**Required-explicit rule (canonical form):**

> Every `Agent({...})` invocation issued by the hub MUST include the `model` parameter explicitly, matching the agent definition's frontmatter `model:` field at `.claude/agents/<subagent_type>.md`. Omission is a structural defect detected by the composite mechanism per § Detection Mechanism subsection below (spoke output `### Model Provenance` block + `deploy.sh --check` Check 27 + Stage 8 QA LLM-graded review).

**Updated canonical invocation pattern (formalizes  Dimension 1's "explicitly pinned per invocation" phrase into a hard rule):**

```
Agent({
  subagent_type: "pmo-<spoke-type>",       // matches .claude/agents/pmo-<spoke-type>.md
  description: "Stage {N} {ShortName} — #{ISSUE}",
  model: "opus",                            // REQUIRED-EXPLICIT (belt-and-suspenders)
  prompt: "{full-spoke-prompt-per-Procedure-3-Spoke-Template}",
  isolation: "worktree",                    // engineering + content-modifying spokes
  run_in_background: false                  // sync default
})
```

**Composition with the Dimension 1 canonical 6-parameter signature:** Dimension 1 settled the SHAPE of the invocation surface (6 parameters). Dimension 6 settles the SEMANTICS of the `model` parameter within that shape — pinning the value-discipline (REQUIRED-EXPLICIT at PMO surface) plus the file-system anchor for defaults (`.claude/agents/<name>.md` frontmatter per Dimension 2 (c)). Recorded as `pmo_extensions[].field = "model-required-explicit-rule"` in the future R2 catalog entry for `agent-tool-invocation-surface` (per the Discovery-A finding; catalog entry creation routed to a follow-up).

**Detection of violation:** A hub-emitted Agent call that omits the `model` parameter is a structural defect per the required-explicit rule. Detection composite per § Detection Mechanism catches the violation at three surfaces (spoke output `### Model Provenance` block / `deploy.sh --check` Check 27 / Stage 8 LLM-graded review).

**Reversibility / Confidence:** CHEAP / HIGH. Reversible via `hub-spoke-bridge.md` edit; relaxing the rule allows Anthropic cascade tier 2/3 to fire — exactly the silent-degradation class  was triaged to prevent.

**Cutover discipline:** Applies to all releases going forward.

### Per-Stage Override

Per the Stage 5 ADR, Dimension 5: per-stage override is declared by editing the agent-definition file's frontmatter `model:` field at `.claude/agents/<name>.md`. The per-file surface IS the override surface — no separate override-config file required.

**Per-stage override semantics (canonical form):**

> Per-stage override is declared in the agent definition file's frontmatter `model:` field at `.claude/agents/<name>.md`. Default across all spoke types is `opus` per the workspace model-preference rule.
>
> Operator declares a per-stage override by editing the relevant agent definition file:
>
> - To override Stage 13 Close to sonnet:
>   Edit `.claude/agents/pmo-close.md` frontmatter from `model: opus` to `model: sonnet`. Commit via standard governance path (Issue + plan + PR per "No ungoverned changes" — agent definition files are Layer 1 workspace config governed by the same rules as `<OPERATOR_INSTANCE_CLAUDE_SETTINGS>` and `core/rules/`).
>
> When the hub invokes the spoke, the explicit `model` parameter at the Agent call site (per § Model Parameter Required-Explicit) is passed matching the agent definition's current value. If operator-override intent differs from the agent definition (one-off per-invocation override), see § Operator Override subsection below.
>
> Workspace-wide global override: edit ALL `.claude/agents/pmo-*.md` files together in one PR. There is no single global-override surface — by design, per-spoke explicitness is the override-discipline mechanism (forces operator to consider each spoke type's choice independently).

**Composition with the model-preference rule:** The workspace model-preference rule establishes the default (`opus` with Max Effort posture) for the workspace owner across all spoke work. The agent-definition file inherits the default; the per-stage override allows operator to deviate for specific spoke types (e.g., cost-sensitive operator may choose `haiku` for Stage 7 Dev Testing where token volume dominates).

**Governance discipline:** Agent-definition file edits are Layer 1 governance changes per CLAUDE.md § Universal Preferences "No ungoverned changes" rule — require GitHub Issue (improvement.yml template) + implementation plan + PR review. Per-invocation operator overrides (next subsection) are CHEAP-tier ephemeral state and do NOT require the ceremony.

**Reversibility / Confidence:** CHEAP / HIGH — per-stage override is reversible via `git revert` of the agent-definition file edit.

**Cutover discipline:** Applies to all releases going forward.

### Operator Override

Per the Stage 5 ADR, Dimension 7: per-invocation operator override is **always available** via the Agent tool's explicit `model` parameter (Anthropic upstream cascade tier 1). Config sets the default at agent-definition file (tier 2); per-invocation override at hub takes precedence (tier 1).

**Override-vs-default contract (canonical form):**

> The Agent tool's `model` parameter at the invocation site is the per-invocation override surface (Anthropic upstream cascade tier 1). Operator MAY direct the hub to pass a non-default value for a single spoke invocation without editing the agent definition file:
>
> ```
> Example operator directive:
>   "For this Stage 5 Solutioning spoke specifically, use sonnet
>    instead of the default opus — I want a faster turnaround on
>    this particular spec."
>
> Hub response: Agent({
>   subagent_type: "pmo-solutioning",
>   model: "sonnet",   // operator override per directive; logged
>   ...
> })
> ```
>
> **Audit trail:** the per-invocation override value is logged via the spoke's `### Model Provenance` block (per Procedure 3 Spoke Template addition). The `Invocation model parameter` field captures the override value; the `Agent-definition default` field captures the non-overridden default. Mismatch between the two indicates a per-invocation override fired — this is detectable without re-reading the operator directive log.
>
> For repeating overrides (e.g., operator wants ALL Stage 5 Solutioning spokes to run sonnet), edit the agent definition file per § Per-Stage Override above — that promotes the override from per-invocation to per-stage default. One-off per-invocation overrides do NOT propagate.
>
> **Approval discipline:** per-invocation overrides do not require "No ungoverned changes" plan-approval ceremony (they are ephemeral state, not durable config). Per-stage overrides (agent definition edits) DO require the ceremony per § Per-Stage Override.

**Composition with the execute-on-approval discipline:** Per-invocation override is a CHEAP-tier decision (operator-driven; no durable state). Doesn't trigger Tier 0 gate; hub executes per operator directive at invocation time.

**Reversibility / Confidence:** CHEAP / HIGH — per-invocation override is by-definition one-off.

**Cutover discipline:** Applies to all releases going forward.

### Not used for (excluded by design)

- Procedure 5 gates (Stage 9 Plan Review, Stage 12 Execute) —
  gates are operator decisions; no spoke is launched.
- Procedure 1 Scaffolding — sub-task creation via `gh issue
  create`, not spoke launch.
- Procedure 6 Early Merge — direct `gh pr merge` action.

### Fallback: manual copy/paste

The operator should prefer manual copy/paste when any of these
conditions applies:

| # | Condition |
|---|---|
| F1 | Agent tool is unavailable in the hub session (tool not present, harness limitation, or invocation returns an error) |
| F2 | Operator wants to edit the prompt before launch |
| F3 | Mid-flight context must reach the spoke that isn't captured in the sub-task body |
| F4 | Gates (excluded by design; restated for clarity) |
| F5 | Debug / iteration on a spoke prompt schema |
| F6 | Cross-session context carry-over required |

Under fallback, the hub prints the full prompt and the operator
copies it into a new session.

### Recursion prohibited

A spawned spoke MUST NOT invoke the Agent tool (or recursive
sub-agent invocation via `subagent_type`) — and MUST NOT call
`spawn_task`. The Spoke Template preamble carries this
constraint. The hub is the only caller of spoke-launch
primitives in the release bridge.

The full subagent-security posture (frontmatter `tools:`
allowlist with `Agent`/`spawn_task` exclusion as the
structural defense, PreToolUse hook surface inheritance,
audit-trail contract, and Return-Value escape-path
semantics) is codified at
[`core/standards/subagent-security-posture.md`](../../../core/standards/subagent-security-posture.md).

### Counter-example matrix — surface roles

Spoke-launch primitives (Agent tool, `spawn_task`) are ONE of three distinct surfaces the hub touches. Confusing the roles produces surface overload — chip-for-engagement, comment-for-engagement, etc. — the very fragmentation the main-thread-only narrowing was designed to prevent. The 3-surface classification:

| Surface | Used for | NOT used for | Authority |
|---|---|---|---|
| `Agent` tool invocation OR `mcp__ccd_session__spawn_task` chip | **Spoke launch (work execution)** — Procedure 0 Stage 4 release-planning spoke; Procedure 3 Stages 5-13 per-issue spokes; Procedure 7 Step 6 orphan-cleanup chip (`--dry-run` invocation only) | Operator engagement for ANY decision class | § Default + § Stage-Conditional Launch Policy (above) |
| GitHub Issue / sub-task comment OR `pipeline-event-log.md` row | **Decision RECORDING (post-decision audit trail)** — dual-surface convention per [`hub-session-continuity.md § Decision Log Mechanism`](../../../core/standards/hub-session-continuity.md); spoke output posting per Procedure 3; release plan deviation log entries | Operator engagement for routine work | Procedure 3, Procedure 4; [`hub-session-continuity.md`](../../../core/standards/hub-session-continuity.md) |
| Main-thread Claude Code chat session (`AskUserQuestion` or equivalent in-chat mechanism) | **Operator ENGAGEMENT (decision rendering)** — every Decision Briefing, gate decision, scope-lock, escalation, D-class decision per the routine-engagement classification table in the Operating Principle | Persistent state OR audit trail (those are file-based) | [Operating Principle § Channel subsection](#channel-main-thread-chat-canonical-per-2534) |

**Discipline:** Chip / Agent-tool is for **work execution after decision**; GH comment / event-log row is for **decision recording after decision**; main-thread chat is for **rendering the decision itself**. Three distinct surfaces, three distinct roles — never overload.

**Cutover discipline:** Applies to all releases going forward.

### Per-Account Usage Window Constraint

Stage 5/7/8 are marked parallel-safe in the Procedure 2 Step 5 Parallelism
Rules table because their output channel (a GitHub sub-task comment) has no
file-contention surface. Parallel-safe is a *coordination* property, not a
*usage-window* property: concurrent Agent-tool spokes still draw against a
shared resource the parallelism table does not model — the per-account
5-hour usage window.

**The window.** Each operator account has a rolling ~5-hour Opus usage window
that meters *cumulative total token consumption* within the window (sliding;
it resets five hours after window-start). This is a usage-window constraint,
**not a rate limit** — the two are different constraint classes with different
mitigations:

| Constraint | Mechanism | Reset | Correct mitigation |
|---|---|---|---|
| **5-hour usage window** | cumulative total tokens consumed within the sliding window | resets 5h after window-start | quota-budgeting per release; window-aware launch timing; reduce per-spoke consumption; serialize-on-failure; defer batch to next window |
| **Rate limit** (separate) | momentary peak — tokens/sec or concurrent in-flight reservations | seconds-to-minutes | stagger launches; cap concurrent count; backoff |

**Cumulative-draw failure mode.** When the hub launches N parallel spokes
(Procedure 3 / § Spoke Launch Mechanisms — Default), the binding question is
not momentary peak — it is whether the *cumulative* work of the batch fits the
*remaining* window envelope. If
`(usage already spent this window) + Σ(tokens_per_spoke over the N spokes)`
exceeds the window allotment, the batch fails when cumulative usage crosses the
limit, leaving OPEN sub-tasks and possibly orphan worktrees to recover. How the
launches are spread in time does not change cumulative consumption — so a
sleep-stagger (a rate-limit remedy) does not address this failure mode.

**Canonical empirical reference.** v11.27 first-failure (2026-05-24): the hub
launched 9 Stage 5 spokes near the *tail* of the operator's 5-hour window after
substantial prior usage. The 9 spokes' cumulative work exceeded the *remaining*
envelope; all returned `session-limit`, and recovery required reopening the
sub-tasks and pruning one orphan worktree. The binding factor was the tail-of-
window remaining envelope, not a momentary concurrent peak. This is the
canonical anchor for the cumulative-draw failure mode.

**Load-bearing mitigations** (the hub applies these against the usage window):

1. **Pre-flight quota check.** Before launching N parallel spokes, the hub
   checks the remaining-window quota and defers the batch if it would be
   insufficient for the estimated cumulative consumption. *(Note: remaining-
   window quota is not queryable from within a session today; this is the check
   the state-aware usage-window gate — sister work that references this
   constraint — is designed to provide. Until it is queryable, the hub relies on
   the budgeting and timing mitigations below plus serialize-on-failure.)*
2. **Quota-budgeting per release.** Estimate `tokens_per_spoke × N` against the
   typical 5-hour-window allotment. If that estimate exceeds a fresh window's
   allotment, split the batch across multiple windows rather than launching all
   N at once.
3. **Window-aware launch timing.** Launch parallel batches *early* in a usage
   window (full quota available), not at the tail (when most quota is already
   spent by other work) — the tail-of-window condition is the one the v11.27
   first-failure hit.
4. **Serialize-on-failure.** If any spoke in a batch hits the usage limit, hold
   the remaining work for the next window rather than burning more quota on
   doomed re-launches.
5. **Reduce per-spoke consumption.** Lower `tokens_per_spoke` with more compact
   prompts, fewer canonical reads, and narrower analysis scope, so a given
   window absorbs more spokes.

**Secondary note — in-prompt `sleep` stagger (rate-limit only, not load-bearing
here).** A hub may add an in-prompt `sleep <position × delay>` stagger to spread
*momentary peak* draw — a defense against the *rate-limit* constraint in the
table above. It is harmless, but it is **not load-bearing for the 5-hour usage
window**: spreading N spokes across a few minutes changes nothing about
cumulative token consumption within the window. Do not treat stagger as the
mitigation for a usage-window overrun; use the load-bearing mitigations above.

**Batch size as a budget-check trigger.** A batch-size heuristic (e.g., a
batch of several parallel spokes) is a useful *floor for running a quota-budget
check* (mitigation 2) — but a fixed concurrent-count alone is not the binding
predictor: a small batch on a near-tail window can overrun while a large batch
on a fresh window succeeds. The binding variable is *remaining* window envelope,
which the count does not read. The state-aware usage-window gate (sister work
that references this subsection) is the check that factors known window state at
all batch sizes. The cumulative-draw budget threshold (the per-spoke cost
estimate and the batch-vs-remaining-window budget at which the hub defers or
splits) is provisional — `[CALIBRATE-AFTER-3]` (MEDIUM confidence): calibrate it
after this constraint's introducing release plus two further post-cutover
releases supply an outcome distribution; the calibration trigger is registered
on the release log.

**Autonomy-Tier note.** The usage-window mitigations are decisions about
*whether and when* to launch a batch; they do not reclassify the parallel-safe
stages' Autonomy Tier (Stage 5/7/8 remain auto-launch). They do not apply to the
write-serialized stages (6/13), which launch one spoke at a time by design.

**Cutover.** Applies to releases entering the pipeline on or after this
constraint's introducing-release merge SHA recorded in
`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`; the introducing release itself is exempt
(the gate cannot fire on the release that introduces it — its own Stage 5 ran a
small batch and would not have self-triggered a deferral regardless).

---

## Stage-to-Persona Mapping

Hub reads persona cards from `release/references/specs/release-personas.md`.

| Stage | Persona Card | Spoke or Gate? | Scope |
|---|---|---|---|
| 4 Release Planning | Release Manager — Release Planning | Spoke (Procedure 0) | Release — runs once before scaffolding |
| 5 Solutioning | Principal Engineer — Architecture Assessment | Spoke | Per-issue |
| 6 Engineering | Software Engineer — Implementation | Spoke | Per-issue |
| 7 Dev Testing | QA Lead — Dev Testing | Spoke | Per-issue |
| 8 QA Testing | QA Lead — Acceptance Review | Spoke | Per-issue |
| 9 Plan Review | Portfolio Manager — Portfolio Review | Gate (hub) | Release |
| 12 Execute | Release Manager — Execution | Spoke | Release |
| 13 Close | Release Manager — Close | Spoke | Release |

---

## Tracking

[Sub-tasks](../../../core/specs/terminology-glossary.md#term-sub-task) are the single [Task](../../../core/specs/terminology-glossary.md#term-task) per [Stage](../../../core/specs/terminology-glossary.md#term-stage) per Issue. They carry:
- **Instructions** (body) — created by hub at scaffolding
- **Output** (spoke comment) — posted by spoke during execution
- **Status** (open/closed) — closed by spoke on completion, or closed by hub with skip closure comment per Procedure 1 Step 5 if stage doesn't apply

Full tracking convention (scaffolding rules, closure criteria, audit trail) is defined in . Glossary-canonical term definitions in [terminology-glossary.md](../../../core/specs/terminology-glossary.md).

---

## Scope Control

Once a Milestone is approved and the bridge is invoked:
- No new issues added without operator approval
- Discoveries during stage execution are logged as new issues (not added to current Milestone)
- Scope changes require explicit operator decision at a gate (Stage 9 is the natural gate)
