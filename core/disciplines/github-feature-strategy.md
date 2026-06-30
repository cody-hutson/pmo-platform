---
title: GitHub Feature Utilization Strategy
purpose: Defines which GitHub features beyond basic Issues the single-operator platform adopts, which it defers, and how the adopted ones map onto the 13-stage improvement pipeline.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# GitHub Feature Utilization Strategy

**Milestone:** v-pretriage

## Context

Single-operator PMO platform with Claude Code as primary contributor. The 13-stage improvement pipeline manages all platform changes through GitHub Issues, branches, and PRs. This document defines which GitHub features beyond basic Issues to adopt, which to defer, and how to enforce usage — balancing traceability against overhead for a single-operator workflow.

## Feature Decision Matrix

| # | Feature | Decision | Enforcement | Rationale |
|---|---------|----------|-------------|-----------|
| 1 | Branch-to-Issue Naming | **Adopt** | Convention (`git-workflow.md`) | Readability and traceability. `feature/#N-description` when a tracked issue exists. Does NOT create GitHub Development sidebar link — that requires `closes #N` in PR body. |
| 2 | PR Auto-Close Keywords | **Adopt** | Convention (`release-process.md`) | `closes #N` in PR body auto-closes issues on merge and creates the Development sidebar link. Standardize on `closes` (not `fixes` or `resolves`) for consistency. |
| 3 | Sub-Issues | **Adopt (acknowledge)** | Convention | Already active — Stage 6 creates sub-tasks as sub-issues. No new work needed; documenting existing pattern. |
| 4 | Milestones | **Adopt (acknowledge)** | Convention | Already active. Milestones = release bundles (Stage 3). Milestone name = release version. |
| 5 | Task Lists (markdown) | **Adopt (lightweight)** | Convention | `- [ ] ` in PR bodies for advisory tracking. Optional enhancement, not mandatory. |
| 6 | Development Links (clarification) | **Adopt (clarify)** | Convention (`git-workflow.md`) | Branch names do NOT auto-link in GitHub's Development sidebar. The `closes #N` keyword in PR body is the actual linking mechanism. |
| 7 | Issue Dependencies (native) | **Adopt per Model A (body→native one-way mirror)** | Convention (ticket-information-architecture.md § Native Dependencies) + `deploy.sh --check` Check 21 (warn-mode initial) | Body Dependencies field remains authoritative (per `ticket-information-architecture.md § Conflict Resolution` "Body fields are authoritative"); native `blocks`/`blocked-by` is a one-way projected display surface mirroring the `FS+0d` subset of typed body deps. AC4 reframed at Collective Review (operator-rendered ACCEPT): "intent stays observable" via drift-detection, not literal bidirectional auto-sync. See ADR-3 revision below. |
| 8 | GitHub Projects | **Defer** | — | High setup overhead. A follow-up PR adds boards, automations, views, and agent integration. |
| 9 | PR Metadata Protocol | **Defer** | — | Setting milestone/labels/assignees/reviewers on PRs via `gh pr create` flags. A follow-up PR defines the exact protocol and flag set. |
| 10 | PR Title Convention | **Adopt** | Convention (`git-workflow.md` § PR Title Convention) + CI (`pr-title-convention.yml`, warn-mode initial) | A PR title should decode its type, milestone, work item, and description on its own. Ratifies the de-facto conventional-commits pattern (`type(scope): summary`); the CI gate mirrors the `pr-body-parser-clean.yml` body check. |

## Architecture Decision Records

### ADR-1: Branch Naming — Mandate vs. Optional

**Decision:** Mandate `feature/#N-description` when a tracked issue exists. Allow `feature/description` (no issue number) for cross-cutting work spanning multiple issues or with no single parent.

**Context:** Prior convention documented both `feature/imp-XXX-description` and `feature/description`. Existing branches show all three variations: `feature/176-label-taxonomy`, `feature/hub-spoke-release-planning`, `feature/imp-216-stage-compression`.

**Rationale:** Consistency for traceability + flexibility for cross-cutting work. The `imp-XXX` prefix is a legacy artifact from the IMPROVEMENTS.md bridge era; standardize on `#N` (GitHub issue number). Branch name does NOT create GitHub's Development sidebar link — that requires `closes #N` in PR body.

**Consequences:** Branching Convention section in `git-workflow.md` rewritten. Old `imp-XXX` pattern deprecated with note.

### ADR-2: Scope Boundary Between this PR and a follow-up PR

**Decision:** This PR updates branching convention and auto-close convention. A follow-up PR adds PR metadata protocol (milestone, labels, assignees, reviewers).

**Context:** Both work items touch the same files (`git-workflow.md`, `release-process.md`). Risk of file contention.

**Rationale:** Clean section separation — this PR edits Branching Convention and PR Process sections. A follow-up PR adds a new PR Metadata section. No overlap.

**Consequences:** In releases containing both, merge this PR first (edits existing sections), then the follow-up PR (adds new sections).

### ADR-3: Issue Dependencies — Defer to a follow-on PR (SUPERSEDED — see ADR-3-rev below)

**Original decision:** Defer to a follow-on PR (GitHub Projects strategy).

**Status: SUPERSEDED** — see ADR-3-rev below.

**Context:** Native deps provide bidirectional blocks/blocked-by with visual indicators on boards. Platform currently tracks deps in issue body (Dependencies field) and release plans.

**Rationale:** Dependencies have maximum value paired with board views. Without Projects boards, they're redundant with body-level tracking. The follow-on PR adopts dependencies + boards together as a coherent system.

**Consequences:** No change to current dependency tracking. Strategy document notes as "Adopt with Projects."

### ADR-3-rev: Issue Dependencies — Adopt per Model A (body→native one-way mirror)

**Decision:** Adopt native issue dependencies under Model A (body→native one-way mirror with typed-dep schema extension). Body Dependencies field remains authoritative; native is a one-way projected display surface mirroring the `FS+0d` subset.

**Source:** Stage 5 design; operator-rendered ACCEPT at Collective Review 2026-05-22 per the release plan AC4. Reverses two prior defers: ADR-2 (v-pretriage, 2026-03-30) and ADR-4 (2026-05-15).

**Context:** Native GitHub Issue Dependencies reached GA in August 2025 (50-per-issue cap; GraphQL mutations `addIssueDependency` / `removeIssueDependency`). The prior-defer rationale named three prerequisites — agent capability for sync, write-permission expansion, conflict-resolution rules — all three of which this release lands as substrate work paired with the CPM consumer (critical-path analysis).

**Rationale:** Three architectural concerns drive Model A:
1. **Body-as-authority invariant** (per `ticket-information-architecture.md § Conflict Resolution`): bidirectional auto-sync would invert or make ambiguous the body's authoritative status. One-way mirror preserves the invariant.
2. **Typed-schema expressivity gap:** PMBOK typed-dep schema (FS/SS/FF/SF + lead/lag) is richer than native `blocks`/`blocked-by` (single semantic). Only the `FS+0d` subset mirrors faithfully; other types stay body-only by design.
3. **Substrate-and-consumer co-location:** This release explicitly bundles the substrate work item with the CPM consumer work item. Adopting at this milestone amortizes the design + engineering cost across both.

**AC4 reframe (operator-rendered ACCEPT at Collective Review):** Original AC4 "intent stays in sync regardless of which surface is edited first" reframed to "intent stays **observable**" — body edits propagate to native within the mirror's expressive subset; native UI edits surface as drift findings for operator-mediated reconciliation. Preserves body-as-authority; satisfies AC4 spirit via drift-detection rather than literal bidirectional auto-sync.

**Consequences:**
- Native dependencies appear on the PMO Pipeline project board as visual indicators for `FS+0d` edges
- Body Dependencies field remains the authoritative source for all agent consumption (Stage 2 G2-04, Stage 3 G3-04/G3-07/G3-08, release-planner Bundle, CPM consumer)
- New Stage 2 substep A3.5 native-mirror fires after G2-04 passes; `deploy.sh --check` Check 21 detects body↔native drift workspace-wide (warn-mode initial)
- New `upstream-reference-catalog.md` entry `github-issue-dependencies` codifies the upstream API pattern
- Reversibility: CHEAP-to-MODERATE / HIGH confidence (per Stage 5 § 9 — git revert restores prior state; accumulated native-deps state rebuildable from body via reverse-mirror)

**Cutover discipline:** Applies to all releases going forward.

### ADR-4: Enforcement Level — Convention-First

**Decision:** Convention-first. No hooks, no CI checks, no GitHub Actions for convention enforcement.

**Context:** Agent reads `core/rules/` files at session start. Convention compliance is structural — the agent follows what it reads.

**Rationale:** Hooks add failure modes (hook blocks agent, operator intervenes) with low marginal benefit over convention for a single-operator + agent workflow. Stage 7 (Dev Testing) and Stage 9 (Plan Review) catch deviations.

**Escalation path:** Convention → Template (PR template with required sections) → Hook (pre-commit validation) → Automation (GitHub Actions). Escalate if violations appear in 3+ consecutive releases.

## Enforcement Philosophy

Convention is the primary enforcement mechanism for a single-operator + AI agent workflow. The agent reads rules files at session start and follows what it reads. Pipeline stages (Stage 7 Dev Testing, Stage 9 Plan Review) serve as secondary enforcement checkpoints.

**Escalation ladder:**

| Level | Mechanism | Trigger |
|-------|-----------|---------|
| 1 (current) | Convention in rules files | Default — agent reads and follows |
| 2 | PR template with required sections | If conventions are missed despite documentation |
| 3 | Pre-commit hook validation | If templates don't catch deviations |
| 4 | GitHub Actions automation | If hooks are insufficient |

**Escalation trigger:** 3+ consecutive releases with convention violations at the same level.

## Scope Boundaries

| Scope | Status |
|-------|--------|
| Branch naming convention | Implemented |
| PR auto-close keywords | Implemented |
| Sub-issue pattern | Documented (existing) |
| Milestone pattern | Documented (existing) |
| Development link clarification | Implemented |
| PR metadata protocol (`--milestone`, `--label`, etc.) | Separate branch |
| GitHub Projects boards and automations | Backlog |
| Native issue dependencies | Adopted per Model A (one-way body→native mirror); see ADR-3-rev |
