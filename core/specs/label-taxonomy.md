---
title: Label Taxonomy
purpose: Defines every GitHub Issue label — its purpose and when it is applied — as the state-anchor layer for issues, including the one-category-label-at-intake rule.
type: spec
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: intake-desk and triage (one category label at intake); every gh issue label operation; ticket-information-architecture.md; the improvement/bug/observation templates
---
<!-- reference-durability: allow-link -->
# Label Taxonomy

Labels are the state anchor layer for GitHub Issues (per ticket-information-architecture.md). This document defines every label, its purpose, and when it is applied.

## Label Groups

### Category Labels

Classify what an issue **is**. Every issue gets exactly one category label at intake. Category labels reflect a two-tier intake model: full Proposals carry a content-classification label (`improvement`, `protocol`, `skill-update`, `structure`, `documentation`, `enhancement`, `routing-rules`, `tracker-schema`, `bug`); the `observation` label marks lightweight placeholder tickets in the Observation tier that Triage either promotes to a full Proposal label or closes.

| Label | Color | Description | Applied At |
|---|---|---|---|
| `improvement` | `0E8A16` (green) | General/umbrella for platform improvement when no specific category fits. Applied by Triage (Stage 2) as a fallback when no other dropdown selection from `improvement.yml` matches. **Not auto-applied by templates.** | Triage (Stage 2) — fallback only |
| `protocol` | `1D76DB` (blue) | Protocol change | Intake (Stage 1) |
| `skill-update` | `FBCA04` (yellow) | Skill modification | Intake (Stage 1) |
| `structure` | `D93F0B` (red-orange) | Structural change | Intake (Stage 1) |
| `documentation` | `0075ca` (dark blue) | Documentation improvements | Intake (Stage 1) |
| `enhancement` | `a2eeef` (teal) | New feature or request | Intake (Stage 1) |
| `routing-rules` | `BFD4F2` (light blue) | Routing rules change | Intake (Stage 1) |
| `tracker-schema` | `C5DEF5` (periwinkle) | Tracker schema change | Intake (Stage 1) |
| `sub-task` | `C2E0C6` (light green) | Engineering sub-task for release implementation | Engineering (Stage 6) |
| `bug` | `d73a4a` (red) | Something isn't working. Auto-applied by `bug.yml` at intake; mutually exclusive with `improvement` and other category labels. | Intake (Stage 1) — via `bug.yml` |
| `observation` | `D4C5F9` (light lavender) | Lightweight gap-capture placeholder ticket. Created via `observation.yml` during agent auto-logging when a full Proposal is not yet authorable. Triage promotes to `improvement` + removes `observation` on promotion, or closes if the observation is no longer relevant. | Intake (Stage 1) — via `observation.yml` |

### Status Labels

Track where an issue is in the pipeline lifecycle. Exactly one status label per issue. Updated as the issue progresses through stages.

| Label | Color | Description | Applied At | Removed At |
|---|---|---|---|---|
| `status: proposed` | `E6E6E6` (light gray) | Awaiting triage | Intake (Stage 1) | Triage decision |
| `status: approved` | `C2E0C6` (light green) | Triaged and approved for work | Triage (Stage 2) | Bundled into release |
| `status: bundled` | `BFD4F2` (light blue) | Assigned to a release Milestone | Bundle (Stage 3) | Engineering starts |
| `status: in-progress` | `FEF2C0` (light yellow) | Active engineering work | Engineering (Stage 6) | Work complete |
| `status: done` | `0E8A16` (green) | Work complete, awaiting verification/close | QA/Close (Stage 8-13) | Issue closed |
| `status: deferred` | `FBCA04` (amber) | Triaged, deferred to backlog — re-triage required for milestone bundling | Triage (Stage 2) | Re-triage (returns to `status: proposed` or `status: approved`) |
| `status: rejected` | `D93F0B` (red) | Triaged, rejected — premise stale or out of scope | Triage (Stage 2) | Issue closed (terminal) |

### Cluster Labels

Classify issues by capability cluster for triage. Applied during Run 1 of backlog triage. An issue may have one cluster label.

| Label | Color | Description |
|---|---|---|
| `cluster: pipeline-definitions` | `aaaaaa` (gray) | Stage definition issues (living docs) |
| `cluster: gate-handoff` | `aaaaaa` (gray) | Inter-stage contracts, gate manager, handoff coordinator |
| `cluster: eval-quality` | `aaaaaa` (gray) | QA framework, eval runner, assertion framework, escape tracking |
| `cluster: skill-modes` | `aaaaaa` (gray) | New or updated skill modes for pipeline stages |
| `cluster: templates-schemas` | `aaaaaa` (gray) | Report templates, plan templates, schema definitions |
| `cluster: system-config` | `aaaaaa` (gray) | GitHub Projects, statuses, labels, automation, environment |
| `cluster: documentation` | `aaaaaa` (gray) | Reference docs, KB, process docs |
| `cluster: process-protocol` | `aaaaaa` (gray) | Pipeline process rules, conventions, standards |
| `cluster: architecture` | `aaaaaa` (gray) | Operating model, platform structure, folder architecture |
| `cluster: automation` | `aaaaaa` (gray) | Linting, verification scripts, auto-mode |
| `cluster: cross-cutting` | `aaaaaa` (gray) | Items spanning multiple clusters |

### Initiative Labels

Group issues by a long-running, multi-milestone initiative. **An initiative label is a *grouping mechanism*, not a hierarchy level** (canonical [term: Initiative](terminology-glossary.md#term-initiative); decision record ADR-049). The work-item hierarchy is methodology-invariant and single-sourced in [`work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md): its levels — Portfolio → Program → Project → Milestone/Workstream → Work Item — are fixed; methodologies and users vary the level *names* and the *work-item kinds* that land on Work Item, never the levels themselves. An "initiative" is therefore a cross-milestone grouping theme that labels related issues — never a container tier or a `parent_ref` target. An issue may carry one initiative label, binding the umbrella ticket, its child tickets, and the corresponding operator-local roadmap doc (authored at `<OPERATOR_INSTANCE_ROADMAPS_PATH>` per ADR-012). Applied at intake (when an issue is part of a known initiative) or via comment/relabel when an existing issue is absorbed under an initiative umbrella.

**Namespace history:** the original `initiative:*` namespace is **retired** (0 live labels); cross-milestone grouping now rides two live namespaces — **`epic:*`** (skill-suite thrusts) and **`project:*`** (cross-cutting initiatives). The grouping concept is canonical [term: Initiative](terminology-glossary.md#term-initiative); the namespaces below are the live mechanism.

| Namespace | Color | Role | Examples (live) |
|---|---|---|---|
| `project:*` | `0052CC` (blue) / per-label | Cross-cutting, multi-milestone initiative grouping | `project:skill-suite`, `project:pipeline`, `project:methodology-packs`, `project:knowledge-corpus`, `project:governance-hygiene` |
| `epic:*` | `5319e7` (purple) | Skill-suite thrust grouping (the epics under `project:skill-suite`) | `epic:skill-architecture-spine`, `epic:skill-role-build`, `epic:skill-function-hardening`, `epic:skill-infra-measurement` |

**Usage pattern:** Apply to the umbrella ticket, all child tickets (new), and any existing tickets absorbed under the initiative scope. Query `gh issue list --label "project:skill-suite"` (or the relevant `epic:*` label) returns the complete landscape of work tied to that initiative. The operator-local roadmap doc § 3 Now/Next/Later sequences all labeled issues into the architected path-to-done.

### Triage Flag Labels

Temporary labels applied during triage runs. Removed after triage decisions are executed.

| Label | Color | Description | Applied At | Removed At |
|---|---|---|---|---|
| `triage: stale` | `FFFFFF` (white) | Flagged as potentially addressed by later work | Run 1 | Run 4 (decision) |
| `triage: duplicate` | `FFFFFF` (white) | Flagged as potential duplicate/subsumption candidate | Run 1 | Run 4 (decision) |
| `triage: quick-win` | `FFFFFF` (white) | Low-effort, high-value — candidate for early bundling | Run 2 | Run 5 (bundled) |

### Disposition Labels

Final triage decisions. Applied when the decision is rendered. Persist until issue is closed.

| Label | Color | Description |
|---|---|---|
| `duplicate` | `cfd3d7` (light gray) | This issue is a duplicate (subsumed per subsumption convention) |
| `wontfix` | `ffffff` (white) | This will not be worked on |

## Removed Labels

The following default GitHub labels were removed as not applicable to a single-operator PMO:

| Label | Reason |
|---|---|
| `good first issue` | Single-operator platform — no external contributors |
| `help wanted` | Single-operator platform — no external contributors |
| `invalid` | Superseded by triage process — issues are either approved or rejected with rationale |
| `question` | Not a valid issue category — questions are resolved in conversation, not tracked as issues |

## Rules

1. **One category label** per issue. Templates auto-apply category + `status: proposed` at submission:
   - `bug.yml` → `bug` + `status: proposed`
   - `improvement.yml` → `status: proposed` only at template submission (no category at submission); operator picks category via required Category dropdown; Triage (Stage 2) applies the matching category label at CER Resolve
   - `observation.yml` → `observation` + `status: proposed`
   - `adr.yml` → `adr` + `status: proposed`
2. **One status label** per issue (updated as issue progresses; mutually exclusive). `status: proposed` is auto-applied at intake by every template's top-level `labels:` field — the mechanism is structural, not convention-only.
3. **One cluster label** per issue (assigned during triage Run 1)
4. **Triage flags** are temporary — removed after triage decisions are executed
5. **Status labels track lifecycle, not priority.** Priority is tracked in the issue body per intake schema.
6. **`sub-task` is both category and lifecycle marker.** Sub-tasks are created during Engineering (Stage 6) and inherit the parent issue's status: at creation, the Stage-6 scaffolding stamps the parent's current `status:` label onto the new sub-task (mirroring the parent's lifecycle position for board/query hygiene). Sub-tasks are **out of scope for the Check 16 status-label invariant** (`deploy.sh` Check 16 scans `--label improvement` issues only); the mirrored sub-task label is a hygiene convenience, not an invariant-enforced field. A sub-task's label is a point-in-time mirror taken at creation and is not auto-resynced on later parent transitions.

## Methodology Variation

Label taxonomy is methodology-agnostic — the category/status/cluster/lifecycle label sets are identical across all 8 archetypes from the `delivery_approach` enum (`Scrum | Kanban | XP | Waterfall | PRINCE2 | SAFe | Hybrid | Custom`). Semantic interpretation of priority/status labels SHALL be derived from PROJECT.md's `delivery_approach` per [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md). When `delivery_approach: Custom`, priority/status semantics follow the `custom_methodology_definition` block — consult `lifecycle`, `ceremonies`, and `artifacts` fields for semantic guidance.
