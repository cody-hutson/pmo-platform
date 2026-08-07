---
title: Label Taxonomy
purpose: Defines the label GRAMMAR — the label groups + the composition rules that govern them — as the state-anchor layer for issues, including the one-category-label-at-intake rule. Concrete label rows are contributed per-pack (core/packs/*) and reconciled to the live GitHub set by the label-parity gate.
type: spec
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: intake-desk and triage (one category label at intake); every gh issue label operation; ticket-information-architecture.md; the improvement/bug/observation templates; the methodology packs (core/packs/*) that contribute concrete label rows into the groups this grammar defines
---
<!-- reference-durability: allow-link -->
# Label Taxonomy

Labels are the state anchor layer for GitHub Issues (per ticket-information-architecture.md). This document defines the label **grammar**: the label **groups**, each group's purpose and cardinality rule, and the composition **rules** that constrain any live label set.

**Grammar vs. instance (the parameterization seam).** A label *group* answers a universal question ("what does a Status label track?"); a concrete label *row* answers an instance question ("does this board have `status: in-progress`?"). This document owns the former — the group definitions and the rules — and is methodology-agnostic across all `delivery_approach` archetypes. The concrete rows are the latter: they are **contributed per methodology pack** in `core/packs/<archetype>/pack.toml` (the `[[labels]]` facet, per [`work-item-type-schema.md §1.1.1`](../schemas/work-item-type-schema.md) and ADR-070 D2), with the archetype-invariant rows carried by `core/packs/_common/pack.toml`. The live GitHub label set is the union of the selected packs' contributions + `_common` + operator-local overrides; the label-parity gate (`check-label-parity.py`) reconciles that union against the doc grammar. See § Instance Model. This split realizes the CLAUDE.md "Parameterize over hardcode" rule and the K1↔K4 parameterization seam in `knowledge-architecture.md §3` — the *shape* of a label group is K1 universal; *which labels exist* is K4 selection-plus-override.

## Label Groups

The taxonomy has seven label **groups**. Each group definition below states the group's *purpose*, its *cardinality rule*, and its *lifecycle role* — the universal grammar. The concrete label *rows* in each group are contributed by the methodology packs (`core/packs/*` `[[labels]]`) and reconciled to the live set by the parity gate (§ Instance Model); illustrative examples are named inline for orientation but are **not** the registry.

### Category Labels

Classify what an issue **is**. Every issue gets exactly one category label at intake (§ Rules 1). Category labels reflect a two-tier intake model: full Proposals carry a content-classification label; the `observation` label marks lightweight placeholder tickets in the Observation tier that Triage either promotes to a full Proposal label or closes. On promotion, Triage removes `observation`, applies the matching category, **and strips the `[Observation]:` title prefix** (§ Rules 7).

**Concrete rows:** the archetype-invariant content-classification labels (illustratively `improvement`, `protocol`, `skill-update`, `structure`, `documentation`, `enhancement`, `routing-rules`, `tracker-schema`, `bug`, `sub-task`, `observation`) are contributed by `core/packs/_common/pack.toml` (`group = "category"`). The live set is the packs' union — see § Instance Model.

#### Work-Item-Kind Labels (the `type:*` namespace)

`type:<kind_id>` is the **work-item-kind category label** — the label-surface projection of the `work_item_type` discriminator (`work-item-type-schema.md §1.2`; ADR-018 D1/D2). It names the *kind* an issue **is** (e.g. `type:epic`, `type:story`, `type:task`, `type:card`), and is a member of the Category group: **one `type:*` label per issue**, composing with the one-category-label rule (§ Rules 1).

`type:*` is documented here **as a namespace PATTERN**, exactly as `project:*` / `epic:*` are (§ Initiative Labels) — the concrete kinds are **not enumerated in this grammar**. They are declared in each selected pack's `kinds[]` and contributed as `[[labels]]` rows keyed by `projects_kind` (the join that keeps the `type:*` family in lockstep with the pack's declared kinds — no independent drift). Enumerating the kinds here would re-instance-code the grammar and duplicate the pack (`duplicate-source-discipline`). A deployment's live `type:*` set is therefore whichever kinds its selected packs declare: the Scrum pack contributes `type:{epic,story,task}`; the Kanban pack contributes `type:card`; a deployment that brings its own kinds contributes their `type:*` rows.

### Status Labels

Track where an issue is in the pipeline lifecycle. Exactly one status label per issue (§ Rules 2), updated as the issue progresses through stages; status tracks lifecycle, **not** priority (§ Rules 5). The lifecycle machine a status label projects is the generic Axis-1 base machine owned by the entity layer (`work-item-type-schema.md §1.2`), which packs project sub-states over — never re-found.

**Concrete rows:** the `status:*` set (illustratively `status: proposed → approved → bundled → in-progress → done`, plus the terminal `status: deferred` and `status: rejected`) is archetype-invariant and contributed by `core/packs/_common/pack.toml` (`group = "status"`). The live set is the packs' union — see § Instance Model.

### Work-Status Labels

Track where a **work item** sits in its **delivery** lifecycle — the generic Axis-1 state machine owned by the entity layer ([`entity-field-schemas.md`](../schemas/entity-field-schemas.md) §3.18 V-WI-04), projected onto the label surface. Exactly one work-status label per work item (§ Rules 8).

**Distinct from Status Labels — the two axes compose, and conflating them is the failure this group exists to prevent.** A Status label answers *where is this issue in the release pipeline?*; a Work-Status label answers *where is this work in its delivery lifecycle?* An item may carry one of each, and neither constrains the other. The two value domains share the tokens for active work and for completion, and the GitHub label namespace is **flat**, so the distinct `work-status: ` name prefix is **load-bearing, not cosmetic**: the status-label invariant check discriminates by the `status: ` **name prefix**, not by the grammar `group` a row declares, so a work-status row named under the `status: ` prefix would trip the one-status-label mutex on every issue that also carries a pipeline Status label.

Values are the Axis-1 enum verbatim. A pack **contributes rows** into this group; it never re-founds the machine ([`work-item-type-schema.md`](../schemas/work-item-type-schema.md) §1.1). An archetype pack MAY later contribute methodology-specific **sub-state deltas** over the base; the shipped packs declare none, because the base enum is archetype-invariant.

**No `blocked` row.** Blocked-ness is a *derived condition* of an unsatisfied `BLOCKS` / `DEPENDS_ON` relationship, not an Axis-1 state — a blocked item still occupies a lifecycle position, so representing it as a value in a one-per-item group would force a choice between the two facts. This is the same shape the RAID crosswalk already ruled on, where a legacy escalated value resolved to a lifecycle state plus an orthogonal condition rather than to a state of its own.

**Concrete rows:** the archetype-invariant Axis-1 rows are contributed by `core/packs/_common/pack.toml` (`group = "work-status"`) as the shared base projection — one row per state in the entity-layer enum, so the row set tracks that enum without a second count to maintain here. The live set is the packs' union — see § Instance Model.

### Cluster Labels

Classify issues by capability cluster for triage. Applied during Run 1 of backlog triage.

**Cluster orthogonality protocol.** Cluster labels split into two axes. The **domain clusters** (illustratively `architecture`, `automation`, `documentation`, `eval-quality`, `gate-handoff`, `pipeline-definitions`, `process-protocol`, `security`, `skill-modes`, `system-config`, `templates-schemas`) classify an issue by its capability area — an issue carries **exactly one** domain cluster (§ Rules 3). `cluster: cross-cutting` is **not** a domain; it is an **orthogonal span-marker** indicating the issue's scope crosses multiple domains. It composes *with* a domain cluster rather than replacing it: an issue may carry **one domain cluster + optionally `cluster: cross-cutting`**. The two never conflict because they answer different questions (which domain? vs. does it span domains?).

**Concrete rows:** the domain-cluster set + the `cluster: cross-cutting` span-marker are archetype-invariant and contributed by `core/packs/_common/pack.toml` (`group = "cluster"`). The live set is the packs' union — see § Instance Model.

### Initiative Labels

Group issues by a long-running, multi-milestone initiative. **An initiative label is a *grouping mechanism*, not a hierarchy level** (canonical [term: Initiative](terminology-glossary.md#term-initiative); decision record ADR-049). The work-item hierarchy is methodology-invariant and single-sourced in [`work-organization-mapping-framework.md`](../disciplines/work-organization-mapping-framework.md): its levels — Portfolio → Program → Project → Milestone/Workstream → Work Item — are fixed; methodologies and users vary the level *names* and the *work-item kinds* that land on Work Item, never the levels themselves. An "initiative" is therefore a cross-milestone grouping theme that labels related issues — never a container tier or a `parent_ref` target. An issue may carry one initiative label, binding the umbrella ticket, its child tickets, and the corresponding operator-local roadmap doc (authored at `<OPERATOR_INSTANCE_ROADMAPS_PATH>` per ADR-012). Applied at intake (when an issue is part of a known initiative) or via comment/relabel when an existing issue is absorbed under an initiative umbrella.

**Namespace history:** the original `initiative:*` namespace is **retired** (0 live labels); cross-milestone grouping now rides two live namespaces — **`epic:*`** (skill-suite thrusts) and **`project:*`** (cross-cutting initiatives). The grouping concept is canonical [term: Initiative](terminology-glossary.md#term-initiative); the namespaces below are the live mechanism.

| Namespace | Color | Role | Examples (live) |
|---|---|---|---|
| `project:*` | `0052CC` (blue) / per-label | Cross-cutting, multi-milestone initiative grouping | `project:skill-suite`, `project:pipeline`, `project:methodology-packs`, `project:knowledge-corpus`, `project:governance-hygiene` |
| `epic:*` | `5319e7` (purple) | Skill-suite thrust grouping (the epics under `project:skill-suite`) | `epic:skill-architecture-spine`, `epic:skill-role-build`, `epic:skill-function-hardening`, `epic:skill-infra-measurement` |

**Usage pattern:** Apply to the umbrella ticket, all child tickets (new), and any existing tickets absorbed under the initiative scope. Query `gh issue list --label "project:skill-suite"` (or the relevant `epic:*` label) returns the complete landscape of work tied to that initiative. The operator-local roadmap doc § 3 Now/Next/Later sequences all labeled issues into the architected path-to-done.

### Triage Flag Labels

Temporary labels applied during triage runs, removed after triage decisions are executed (§ Rules 4). Each carries an *applied-at* run and a *removed-at* run.

**Concrete rows:** the triage-flag set (illustratively `triage: stale`, `triage: duplicate`, `triage: quick-win`) is archetype-invariant and contributed by `core/packs/_common/pack.toml` (`group = "triage-flag"`). The live set is the packs' union — see § Instance Model.

### Disposition Labels

Final triage decisions. Applied when the decision is rendered; persist until the issue is closed.

**Concrete rows:** the disposition set (illustratively `duplicate`, `wontfix`) is archetype-invariant and contributed by `core/packs/_common/pack.toml` (`group = "disposition"`). The live set is the packs' union — see § Instance Model.

## Removed Labels

The following default GitHub labels were removed as not applicable to a single-operator PMO:

| Label | Reason |
|---|---|
| `good first issue` | Single-operator platform — no external contributors |
| `help wanted` | Single-operator platform — no external contributors |
| `invalid` | Superseded by triage process — issues are either approved or rejected with rationale |
| `question` | Not a valid issue category — questions are resolved in conversation, not tracked as issues |

## Rules

These composition rules are the grammar's operative clauses — they constrain *any* live label set, regardless of which concrete rows the selected packs contribute.

1. **One category label** per issue. Templates auto-apply category + `status: proposed` at submission:
   - `bug.yml` → `bug` + `status: proposed`
   - `improvement.yml` → `status: proposed` only at template submission (no category at submission); operator picks category via required Category dropdown; Triage (Stage 2) applies the matching category label at CER Resolve
   - `observation.yml` → `observation` + `status: proposed`
   - `adr.yml` → `adr` + `status: proposed`
   - Pack-projected kind forms (dedicated kind templates a deployment ships; basename = `kind_id`) → `type:<kind_id>` + `status: proposed`. The concrete `type:*` rows live in the selected packs' `[[labels]]` facets (§ Instance Model), never in this grammar; the form's `labels:` array realizes the pack's `applied_at: Intake (Stage 1)` declaration structurally.
2. **One status label** per issue (updated as issue progresses; mutually exclusive), **subject to the per-type applicability table below**. `status: proposed` is auto-applied at intake by every template's top-level `labels:` field — the mechanism is structural, not convention-only.

   **Per-type status-label applicability** (which `deploy.sh` Check 16 invariant I2 — *presence* — enforces). "Required" means the type must carry exactly one status label; "exempt" means I2 does not flag its absence:

   | Work-item type | Status label required? | Rationale |
   |---|---|---|
   | `improvement`, `bug`, `observation`, `adr`, `type:task` / `type:story` / `type:card` (any lifecycle kind) | **Required** | These are lifecycle work items — a status label is their board/query position. |
   | `type:epic` | **Exempt** | An epic is a **container / grouping tier**, not a lifecycle work item (operator decision 2026-07-19). It has no single lifecycle position of its own; its children carry the lifecycle. Enforcing "exactly one status label" on epics would be a category error. |
   | `sub-task` | **Exempt** | A sub-task's status label is a point-in-time **hygiene mirror** of its parent's status at creation, not an invariant-enforced field (see Rule 6). |

   I2 (presence) is the only invariant with a type exemption. **I1** (mutex — no >1 status), **I3** (no `proposed` + milestone), and **I4** (no `bundled` without milestone) apply to **all types**: an exempt type that never carries a status label simply never trips them.
3. **One domain cluster label** per issue, **plus optionally `cluster: cross-cutting`** (the orthogonal span-marker — see the Cluster orthogonality protocol under § Cluster Labels). Assigned during triage Run 1.
4. **Triage flags** are temporary — removed after triage decisions are executed
5. **Status labels track lifecycle, not priority.** Priority is tracked in the issue body per intake schema.
6. **`sub-task` is both category and lifecycle marker.** Sub-tasks are created during Engineering (Stage 6) and inherit the parent issue's status: at creation, the Stage-6 scaffolding stamps the parent's current `status:` label onto the new sub-task (mirroring the parent's lifecycle position for board/query hygiene). Sub-tasks are **exempt from the Check 16 status-label *presence* invariant (I2)** — a **type exemption** (see the applicability table in Rule 2), not a side effect of the check's fetch scope. *(Check 16 scans all open intake and exempts `type:epic` and `sub-task` from the I2 presence invariant as a stated type exemption — not a side-effect of the fetch scope.)* The mirrored sub-task label is a hygiene convenience, not an invariant-enforced field; it is a point-in-time mirror taken at creation and is not auto-resynced on later parent transitions.
7. **Title↔category parity on promotion.** When an `observation` is promoted, the `[Observation]:` title prefix is stripped together with the `observation` label (per the `observation` row in § Category Labels and the **Stage 3 Template-Conversion Rule** in [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md#template-conversion-rule)). Deterministic invariant: **no OPEN issue carries both an `[Observation]:` title and a non-`observation` category label.** Closed issues are terminal records — exempt.
8. **One work-status label** per work item, mutually exclusive **within the group** — and **orthogonal to Rule 2**. The work-status group and the status group are never mutually exclusive with *each other*: an item may carry one label from each, because they answer different questions on different axes (§ Work-Status Labels). Rule 2's mutex binds the status group alone, and this rule's mutex binds the work-status group alone.

   **Applicability.** The group applies to work items on a delivery board. An issue that exists only as release-pipeline intake carries a Status label and **no** Work-Status label, and **that absence is not a violation** — this rule asserts mutual exclusivity, not presence.

   **Who advances it, and on what trigger, is not this grammar's concern.** The actor and the qualifying evidence for every Axis-1 transition are already stated per-transition in [`entity-lifecycle-protocol.md`](../standards/entity-lifecycle-protocol.md) §3.10; the status-maintenance contract in [`work-item-type-schema.md`](../schemas/work-item-type-schema.md) governs resolution when no platform adapter is configured. This rule cites both and restates neither — a second copy of an advance obligation is the drift surface, not a convenience.

## Methodology Variation

The label **grammar** — the seven group definitions, their cardinality rules, and the composition rules — is methodology-agnostic and identical across all 8 archetypes from the `delivery_approach` enum (`Scrum | Kanban | XP | Waterfall | PRINCE2 | SAFe | Hybrid | Custom`). What varies per methodology is the **concrete label set**, which is *realized* by the selected packs' `core/packs/<archetype>/` contributions: the archetype-invariant rows (Category / Status / Work-Status / Cluster / Triage-Flag / Disposition) come from `_common`, and each archetype pack adds only its deltas — chiefly the `type:*` kind labels projecting its declared `kinds[]` (`work-item-type-schema.md §1.1.1`; the methodology-pack composing-unit and composition-grammar decisions ADR-069 / ADR-070 D2, the grammar-altitude siblings of ADR-018). The live set is the union of the selected packs + `_common` + operator overrides, reconciled to this grammar by the label-parity gate (§ Instance Model). Semantic interpretation of priority/status labels SHALL be derived from PROJECT.md's `delivery_approach` per [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md). When `delivery_approach: Custom`, priority/status semantics follow the `custom_methodology_definition` block — consult `lifecycle`, `ceremonies`, and `artifacts` fields for semantic guidance.

## Instance Model

This document is the label **grammar authority**; the concrete label rows are the **instance**, contributed by the methodology packs and reconciled to the live GitHub set by the label-parity gate. The live-label formula:

```
LIVE GitHub label set  ≡  _common.[[labels]]                    # archetype-invariant rows (core/packs/_common/pack.toml)
                        ∪  ( selected packs' [[labels]] )         # per-archetype deltas; selection by delivery_approach
                        ∪  ( operator-local overrides )           # K4 — operator.toml / operator-local, never corpus
                        −  ( operator-local removals )
```

- **Selection** is by `delivery_approach` in operator config (e.g. a Hybrid `[Scrum, Kanban]` deployment ⇒ `_common ∪ scrum ∪ kanban`).
- **Contribution** is the `[[labels]]` facet in `core/packs/<archetype>/pack.toml` — each row names its grammar `group` (one of the seven this doc defines) and, for `type:*` rows, its `projects_kind` join into the pack's `kinds[]`. The grammar defines the groups; a pack only populates them and may never define a new group or rule. The archetype-invariant rows — including the Axis-1 work-status base projection — are carried by `_common`; an archetype pack contributes only what genuinely differs from that base.
- **Overrides / removals** are K4 operator-local (color/description tweaks, extra project-local families like `size:*` / `layer:*` if the operator runs them) — never committed to this K1 corpus.
- **Reconciliation** is the label-parity gate ([`core/deploy/tools/check-label-parity.py`](../deploy/tools/check-label-parity.py), `deploy.sh` Check 51). It reads the canonical set as the **union of this grammar doc + every pack `[[labels]]` facet** and diffs against the live set: a canonical label absent from GitHub is **MISSING** (enforce-capable), a live label registered by neither a concrete row nor a namespace pattern (`project:*` / `epic:*` / `type:*`) is **ORPHAN** (warn-only). The grammar doc retains the namespace patterns; the packs carry the concrete rows.
