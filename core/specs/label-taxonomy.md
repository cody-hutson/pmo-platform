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

The taxonomy has eight label **groups**. Each group definition below states the group's *purpose*, its *cardinality rule*, and its *lifecycle role* — the universal grammar. The concrete label *rows* in each group are contributed by the methodology packs (`core/packs/*` `[[labels]]`) and reconciled to the live set by the parity gate (§ Instance Model); illustrative examples are named inline for orientation but are **not** the registry.

### Category Labels

Classify what an issue **is**. Every issue gets exactly one category label at intake (§ Rules 1). Category labels reflect a two-tier intake model: full Proposals carry a content-classification label; the `observation` label marks lightweight placeholder tickets in the Observation tier that Triage either promotes to a full Proposal label or closes. On promotion, Triage removes `observation`, applies the matching category, **and strips the `[Observation]:` title prefix** (§ Rules 7).

**Concrete rows:** the archetype-invariant content-classification labels (illustratively `improvement`, `protocol`, `skill-update`, `structure`, `documentation`, `enhancement`, `routing-rules`, `tracker-schema`, `bug`, `sub-task`, `observation`, `adr`) are contributed by `core/packs/_common/pack.toml` (`group = "category"`). The live set is the packs' union — see § Instance Model.

#### Work-Item-Kind Labels (the `type:*` namespace)

`type:<kind_id>` is the **work-item-kind category label** — the label-surface projection of the `work_item_type` discriminator (`work-item-type-schema.md §1.2`; ADR-018 D1/D2). It names the *kind* an issue **is** (e.g. `type:epic`, `type:story`, `type:task`, `type:card`), and is a member of the Category group: **one `type:*` label per issue**, composing with the one-category-label rule (§ Rules 1).

`type:*` is documented here **as a grammar PATTERN**, exactly as `project:*` / `epic:*` are (§ Initiative Labels) — the concrete kinds are **not enumerated in this grammar**. They are declared in each selected pack's `kinds[]` and contributed as `[[labels]]` rows keyed by `projects_kind` (the join that keeps the `type:*` family in lockstep with the pack's declared kinds — no independent drift). Enumerating the kinds here would re-instance-code the grammar and duplicate the pack (`duplicate-source-discipline`). A deployment's live `type:*` set is therefore whichever kinds its selected packs declare: the Scrum pack contributes `type:{epic,story,task}`; the Kanban pack contributes `type:card`; a deployment that brings its own kinds contributes their `type:*` rows.

**Every live `type:X` must resolve to an `X` a selected pack declares — and `type:*` is a grammar pattern but NOT a resolution pattern.** Both halves are load-bearing, and the pair reads as a contradiction only until the two questions are separated. *Grammar:* the kinds stay unenumerated here, because they belong to the packs. *Resolution:* a live `type:X` label is registered only when a **selected** pack declares `X` — either as a `[[labels]]` row named `type:X`, or as a `kind_id: X` entry in that pack's `kinds[]`. The parity gate (§ Instance Model) reports every live `type:X` that resolves to neither.

The two declaration forms are a union, not alternatives, because [`work-item-type-schema.md §1.1.1`](../schemas/work-item-type-schema.md) binds them in one direction only: `projects_kind` is required **on** a `type:*` row, but no clause requires a row **per** declared kind. A pack may therefore declare a kind and ship no label row for it — the ordinary shape of a K4 operator-local pack extending the shared base — and that kind is still declared. Resolving against the rows alone would report a deployment's own legitimately-declared kinds as unregistered.

**This narrowing is what makes the family falsifiable at all.** `type:*` was previously registered with `project:*` / `epic:*` as a resolution prefix, so any live label beginning `type:` passed the gate whether or not any pack declared its kind. The gate was believed to reconcile the whole kind family and verified only the string prefix; five live labels sat undeclared and unreported. `project:*` and `epic:*` keep resolving by prefix, and correctly so — an initiative or epic slug is an open, operator-minted set with no declaration surface to resolve against, whereas a kind has exactly one.

**A `type:<kind_id>` projection and the co-extensive `_common` category row are ONE category assertion, not two.** Where a selected pack declares kind `X` and `X` is also the name of a live `_common` **category** row, the two labels are the same classification stated at two altitudes — the content-class row and its kind projection — bound by the `projects_kind` join that declares them the same thing. An issue carrying both therefore satisfies § Rules 1 rather than breaching it.

The clause is deliberately narrow, and the boundary is the whole of it. It fires **only** where a selected pack declares the kind — on a deployment whose packs do not, the pair is two category labels and Rule 1 binds normally. It does **not** reach a `type:*` label that joins no pack's `kinds[]` (`type:observation`, `type:adr`, `type:subtask`), and it does not reach a kind with no co-extensive `_common` category row (`spike` is a kind a pack may declare; there is no `spike` category row for it to collide with). It licenses exactly one shape — the declared projection of an existing category row — and nothing else. Rule 1's cardinality is untouched in every other case.

#### Tolerated Legacy Alias — `type:subtask`

`type:subtask` is a **tolerated legacy alias of the `sub-task` category row** — *not* a work-item-kind row, despite sitting lexically inside the `type:*` namespace above. It joins no pack's `kinds[]`, projects no `work_item_type`, and predates the canonical `sub-task` row it aliases.

**Do not apply it to new work.** New sub-tasks take the canonical `sub-task` category label (§ Rules 6). The alias is frozen — tolerated where it already sits, never extended.

**Do not remove, replace, or delete it.** `core/deploy/tools/check-milestone-epic-membership.py` reads the alias, and the legs whose subject *is* the sub-task scaffold count the issues carrying only it — the M3 sub-task census, and M4's milestone-less sub-task count, which shares the same wide predicate. Two removal paths break those legs, and both are live:

- **Per-issue relabel** — stripping the alias from an issue drops that issue out of the counted population.
- **Deleting the `type:subtask` label itself** — this removes it from every carrier in a single action. The check evaluates issues irrespective of open/closed state, so the label stays load-bearing even when its carriers are not open work; an audit that reads "unused" off the open-issue view is reading the wrong population.

Either way the failure is **silent**: the legs keep reporting, on a quietly smaller population.

**The two sub-task predicates differ by design; do not collapse them.** That same tool defines `is_sub_task` (narrow — the canonical row only) and `is_sub_task_family` (wide — the canonical row *or* this alias), and states the reason for each inline. The legs that *exclude* scaffolding from a membership population (M1, M2) use the narrow predicate, because a narrow exclusion errs toward flagging, which is the safe direction there; the legs that *count* the scaffold use the wide one, because a sub-task carrying only the alias is still a sub-task. The tool is the authority for that split — read the reasoning there rather than trusting a restatement here.

**Consumer set — what breaks on removal.** Naming a single consumer under-states the blast radius, which is the whole point of this entry:

| Consumer | Dependency on the alias |
|---|---|
| `core/deploy/tools/check-milestone-epic-membership.py` | Declares it as a named constant and admits it in the wide sub-task predicate the counting legs use |
| `release/tools/automated-closeout.sh` | Accepts it as a sub-task-family label in the Stage-13 auto-close exclusion filter, and fixtures that path |
| `release/skills/release-executor/SKILL.md` | Documents that same exclusion filter as accepting it — the contract an operator reads before running close-out |

Re-derive this set by searching the tree for the alias literal rather than trusting the table to stay complete on its own; a consumer added later will not announce itself here.

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

**An initiative is never materialized as a standalone issue.** An initiative is represented by its `project:` label plus the operator-local roadmap doc that sequences it — and by nothing else. It **MUST NOT** be filed as a standalone `type:epic` issue. Read this as a claim about **materialization**, not about what an epic is: an epic remains a container / grouping tier (§ Rules, Rule 2), and that stays true. The assertion is that an *initiative* has no issue of its own to be that container with. The failure mode is concrete rather than theoretical: before a `project:` namespace existed, initiatives were filed as `type:epic` because no other issue type could hold them; once decomposed into genuine epics, the container had no tier to be re-homed to and simply kept its epic type, leaving a family of granular epics sitting under an epic that is really their initiative.

**Detection signal — a three-way conjunction, because the family shape alone is symmetric.** The mis-tiering fingerprint is *not* "an epic sharing a `project:` label with other epics that are not its native children". That shape over-fires across nearly the whole open-epic population, and it does so **by construction rather than by calibration**, because it is **symmetric**: a leaf epic inside a family shares its label with exactly the same non-children its container does, so every leaf matches it too and no threshold separates the two. (ADR-132 records the measurement that established this, taken at a fixed baseline. The ratio drifts with the backlog; the symmetry does not, and it is the symmetry that makes the shape unusable.) The signal is the conjunction of all three of the following, which no leaf epic satisfies together:

1. **Family shape** — the epic carries a `project:` label whose family, excluding its own native sub-issue children, holds at least two other open epics.
2. **Title coextension** — every token of that label's slug appears in the epic's title head (its subject segment). A container names the whole domain; a thrust names its own thrust.
3. **In-family fan-out** — the epic's body references at least two distinct members of that family. A container enumerates its family; a sibling cites a neighbour or two.

**Enforcement surface.** `deploy.sh` Check 55 (`core/deploy/tools/check-work-hierarchy.py`) asserts this rule across three invariants: **H1** — no normative doc asserts `Initiative` or `Roadmap` as a parent tier; **H2** — no open `type:epic` issue has a `type:epic` parent; **H3** — no open `type:epic` issue satisfies the three-way conjunction above. H1 and H2 are warn-capable. **H3 is advisory-only and reports for operator review — it never gates a run and never relabels or re-tiers anything**, because its coextension conjunct is lexical and a legitimately renamed epic changes its verdict. Every H3 finding emits its own evidence — the matched slug tokens and the in-family references — so an operator can falsify it in one read, and a container judged intentional is recorded as `#<issue> initiative-coextension` in the work-hierarchy exemption list. Re-tiering a flagged container means moving it to a `project:` label plus a roadmap entry, which is a single relabel.

**Namespace history:** the original `initiative:*` namespace is **retired** (0 live labels); cross-milestone grouping now rides two live namespaces — **`epic:*`** (skill-suite thrusts) and **`project:*`** (cross-cutting initiatives). The grouping concept is canonical [term: Initiative](terminology-glossary.md#term-initiative); the namespaces below are the live mechanism.

| Namespace | Color | Role | Examples (live) |
|---|---|---|---|
| `project:*` | `0052CC` (blue) / per-label | Cross-cutting, multi-milestone initiative grouping | `project:skill-suite`, `project:pipeline`, `project:methodology-packs`, `project:knowledge-corpus`, `project:governance-hygiene`, `project:platform-quality` |
| `epic:*` | `5319e7` (purple) | Skill-suite thrust grouping (the epics under `project:skill-suite`) | `epic:skill-architecture-spine`, `epic:skill-role-build`, `epic:skill-function-hardening`, `epic:skill-infra-measurement` |

**Finite vs standing initiatives.** An initiative label groups work toward a capability; most do so **finitely** — the roadmap sequences a Now/Next/Later path and archives at sunset. A **standing** initiative is the permitted second shape (`sunset_criteria: permanent`, per [`initiative-roadmap-framework.md`](../standards/initiative-roadmap-framework.md) §6.1(f)): it groups recurring work that never terminates — ongoing defect and hygiene flow — and is therefore governed by **capacity allocation measured against a floor**, never burned down against a scope. `project:platform-quality` is the standing case. The distinction is load-bearing precisely because a standing grouping must not be converted into a container that is expected to close: the prohibition above (an initiative is never materialized as a standalone `type:epic` issue) applies to it with full force, and an epic whose contract is closure cannot hold work whose defining property is that it does not stop.

**Usage pattern:** Apply to the umbrella ticket, all child tickets (new), and any existing tickets absorbed under the initiative scope. Query `gh issue list --label "project:skill-suite"` (or the relevant `epic:*` label) returns the complete landscape of work tied to that initiative. The operator-local roadmap doc § 3 Now/Next/Later sequences all labeled issues into the architected path-to-done.

### Triage Flag Labels

Temporary labels applied during triage runs, removed after triage decisions are executed (§ Rules 4). Each carries an *applied-at* run and a *removed-at* run.

**Concrete rows: `_common` contributes none.** The group is retained as **grammar** — it constrains any triage-flag row a deployment contributes, and Rule 4's removal mandate still governs the group. What is withdrawn is the three concrete rows `_common` used to declare.

**Disposition of the three withdrawn rows — `triage: duplicate`, `triage: quick-win`, `triage: stale`: declaration withdrawn, not materialized.** All three were declared but never created, so the parity gate reported each as `MISSING` with no owner to close it. The withdrawal basis is that **nothing applies them**: a tree-wide search returns only documentary mentions — the three declarations themselves and a handful of prose references — with no application site, and the skill that runs Stage-2 Triage performs no label operation at all. Their `applied_at`/`removed_at` metadata ("Run 1", "Run 4 (decision)") refers to a **backlog-triage-run process the current pipeline does not implement**. Creating them would have added three live labels nothing applies — precisely the unused row a later audit proposes deleting, which is the churn loop this disposition exists to break.

A deployment that *does* run labeled triage contributes its own rows into this group, which is still here waiting for them.

### Disposition Labels

Final triage decisions. Applied when the decision is rendered; persist until the issue is closed.

**Concrete rows:** the disposition set (illustratively `duplicate`, `wontfix`) is archetype-invariant and contributed by `core/packs/_common/pack.toml` (`group = "disposition"`). The live set is the packs' union — see § Instance Model.

### Provenance Labels

Record **how a work item entered the tracker** — not what it is (Category), not where it sits (Status / Work-Status), and not what was decided about it (Disposition / Triage Flag). A provenance label answers a question about the item's *origin*: was it filed by a person, or emitted by a mechanism?

**Cardinality:** zero or one per issue, and **orthogonal to every other group** — a provenance label never competes with a category, status, work-status, cluster, or disposition label, because it answers a different question (§ Rules 9). Most issues carry none: provenance is recorded only when the origin is not the default human-filed path.

**Lifecycle role:** applied **at creation**, by the mechanism that files the item, and **never removed** — not at triage, not at close. This is the group's distinguishing property and the reason it is not a Triage Flag: downstream counting rules read provenance labels on **closed** issues, so a label removed at triage would make those rules structurally unable to fire.

**Concrete rows:** the provenance set (illustratively `auto-promoted-pattern`, applied by the release-learnings synthesizer's cross-release pattern detector) is archetype-invariant and contributed by `core/packs/_common/pack.toml` (`group = "provenance"`). The live set is the packs' union — see § Instance Model.

## Excluded Labels

These default GitHub labels are **excluded from this platform's canonical label set**. A label named here is expected to be **absent**; its presence is a **finding**, reported by the parity gate as `EXCLUDED_LIVE` (§ Instance Model).

**This is standing policy in the present tense, not a record of a past action, and the tense is the point.** The section previously asserted that these labels "were removed" — a past-tense claim about repository state, which rots the moment the state moves. It had already rotted: all four were live while the document said they were gone, and the gate classified them as `ORPHAN` (live-but-unregistered) rather than as the contradiction they were, so nothing could name the disagreement. A policy statement is true before the labels are deleted, true after, and true again if one reappears; a historical claim is true only in the window between the deletion and the next change.

**Reappearance is expected, which is why the exclusion is a standing rule rather than a one-time cleanup.** All four are GitHub's stock defaults, and § Instance Model already documents the ungoverned re-entry path: applying an unrecognized label to an issue brings it into existence with a default colour and no description. A label named here that becomes live again is re-reported on the next run rather than silently tolerated.

`EXCLUDED_LIVE` is a **distinct verdict class from `ORPHAN` because the two remedies are opposite.** An orphan may simply need registering — the taxonomy is the surface that changes. An excluded-but-live row means one of the two surfaces is wrong, and the operator chooses which: delete the label (repository **state**, IRREVERSIBLE — `git revert` cannot undo it and any carrier loses the label permanently), or withdraw the row from the table below (repository **content**, CHEAP and revertible).

| Label | Exclusion basis |
|---|---|
| `good first issue` | Single-operator platform — no external contributors |
| `help wanted` | Single-operator platform — no external contributors |
| `invalid` | Superseded by the triage process — issues are either approved or rejected with rationale |
| `question` | Not a valid issue category — questions are resolved in conversation, not tracked as issues |

**Column 2 is prose and MUST NOT carry a backticked hex colour.** The parity primitive's label-row regex requires a backticked 3/6-hex in column 2, and that requirement is the *only* structural reason this table stays out of the canonical union. Adding a colour column — the intuitive move, since a colour would make the rows reconstructible — would make all four rows canonical, and once the labels are deleted they would flip straight from the warn-only `EXCLUDED_LIVE` arm into the enforce-capable `MISSING` arm. The reconstruction record for a deletion is an operator-captured `gh label list --json name,color,description` taken immediately before the delete, never this table.

## Rules

These composition rules are the grammar's operative clauses — they constrain *any* live label set, regardless of which concrete rows the selected packs contribute.

1. **One category label** per issue. Templates auto-apply category + `status: proposed` at submission:
   - `bug.yml` → `bug` + `status: proposed`
   - `improvement.yml` → `status: proposed` only at template submission (no category at submission); operator picks category via required Category dropdown; Triage (Stage 2) applies the matching category label at CER Resolve
   - `observation.yml` → `observation` + `status: proposed`
   - `adr.yml` → `adr` + `status: proposed`
   - Pack-projected kind forms (dedicated kind templates a deployment ships; basename = `kind_id`) → `type:<kind_id>` + `status: proposed`. The concrete `type:*` rows live in the selected packs' `[[labels]]` facets (§ Instance Model), never in this grammar; the form's `labels:` array realizes the pack's `applied_at: Intake (Stage 1)` declaration structurally.

   **One structural exception, stated in § Work-Item-Kind Labels:** where a selected pack declares kind `X` and `X` is also the name of a live `_common` category row, `type:X` and `X` are one category assertion at two altitudes rather than two competing labels, because `projects_kind` binds them by declaration. The exception fires only under that declaration; read the clause there for its exact boundary. This rule's cardinality is otherwise unchanged.
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
6. **`sub-task` is both category and lifecycle marker.** Sub-tasks are created by the **hub at scaffold time** — the release-scoped Stage-4 planning sub-task at Stage-4-Planning entry, and the remaining per-issue and release-scoped stage sub-tasks (Stages 5–13) in the scaffolding pass — and inherit the parent issue's status: the **same `gh issue create` that stamps the milestone stamps `sub-task` and the parent's current `status:` label**, per `hub-spoke-bridge.md` Procedure 0 Step 5(a) and Procedure 1 Step 4, which is the authoritative application point (mirroring the parent's lifecycle position for board/query hygiene). Sub-tasks are **exempt from the Check 16 status-label *presence* invariant (I2)** — a **type exemption** (see the applicability table in Rule 2), not a side effect of the check's fetch scope. *(Check 16 scans all open intake and exempts `type:epic` and `sub-task` from the I2 presence invariant as a stated type exemption — not a side-effect of the fetch scope.)* The mirrored sub-task label is a hygiene convenience, not an invariant-enforced field; it is a point-in-time mirror taken at creation and is not auto-resynced on later parent transitions.
7. **Title↔category parity on promotion.** When an `observation` is promoted, the `[Observation]:` title prefix is stripped together with the `observation` label **and with any kind label (`type:*`) carrying the superseded classification** (per the `observation` row in § Category Labels and the **Stage 3 Template-Conversion Rule** in [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md#template-conversion-rule)). Deterministic invariant: **no OPEN issue carries both an `[Observation]:` title and a non-`observation` category label.** Closed issues are terminal records — exempt.

   **The kind label is named explicitly because omitting it is what produced the residue.** The transition previously stripped the category label and the title prefix and said nothing about the kind label, so a promoted issue kept a `type:*` label projecting the classification it had just left — carrying a category assertion its category label contradicted, and splitting the corpus for every consumer that enumerates by one label and not the other. A kind label is a Category-group member (§ Work-Item-Kind Labels), so a promotion that re-classifies the issue re-classifies it too; leaving it behind is the same defect as leaving the category label behind. Strip all three, or none.
8. **One work-status label** per work item, mutually exclusive **within the group** — and **orthogonal to Rule 2**. The work-status group and the status group are never mutually exclusive with *each other*: an item may carry one label from each, because they answer different questions on different axes (§ Work-Status Labels). Rule 2's mutex binds the status group alone, and this rule's mutex binds the work-status group alone.

   **Applicability.** The group applies to work items on a delivery board. An issue that exists only as release-pipeline intake carries a Status label and **no** Work-Status label, and **that absence is not a violation** — this rule asserts mutual exclusivity, not presence.

   **Who advances it, and on what trigger, is not this grammar's concern.** The actor and the qualifying evidence for every Axis-1 transition are already stated per-transition in [`entity-lifecycle-protocol.md`](../standards/entity-lifecycle-protocol.md) §3.10; the status-maintenance contract in [`work-item-type-schema.md`](../schemas/work-item-type-schema.md) governs resolution when no platform adapter is configured. This rule cites both and restates neither — a second copy of an advance obligation is the drift surface, not a convenience.
9. **Provenance labels are orthogonal and persistent.** A provenance label records *how* a work item entered the tracker. It is **not mutually exclusive with any other group**, it is **never removed at triage**, and it **survives close** — downstream counting rules read it on closed items. A machine-applied origin marker therefore belongs in the Provenance group and nowhere else: putting it in Category would break Rule 1 (the filing mechanism already applies one), and putting it in Triage Flag would break this rule's persistence clause via Rule 4's removal mandate, silently disabling every rule that counts the label after close.

## Methodology Variation

The label **grammar** — the eight group definitions, their cardinality rules, and the composition rules — is methodology-agnostic and identical across all 8 archetypes from the `delivery_approach` enum (`Scrum | Kanban | XP | Waterfall | PRINCE2 | SAFe | Hybrid | Custom`). What varies per methodology is the **concrete label set**, which is *realized* by the selected packs' `core/packs/<archetype>/` contributions: the archetype-invariant rows — **six of the eight groups** (Category / Status / Work-Status / Cluster / Disposition / **Provenance**) — come from `_common`, and each archetype pack adds only its deltas — chiefly the `type:*` kind labels projecting its declared `kinds[]` (`work-item-type-schema.md §1.1.1`; the methodology-pack composing-unit and composition-grammar decisions ADR-069 / ADR-070 D2, the grammar-altitude siblings of ADR-018). **Two groups contribute no `_common` rows, for two different reasons, and both are deliberate:** **Initiative**, because `project:*` / `epic:*` are registered namespace *patterns* rather than an enumerated set (§ Initiative Labels); and **Triage-Flag**, because this deployment runs no labeled triage-run process, so its three former rows were declared-but-never-applied and their declarations are withdrawn (§ Triage Flag Labels). Six contributing groups against eight defined groups is therefore the correct arithmetic, not two missing rows — a group with no rows is a grammar slot awaiting a deployment that needs it, and each of the two states why it is empty rather than leaving the gap to be read as an omission. The live set is the union of the selected packs + `_common` + operator overrides, reconciled to this grammar by the label-parity gate (§ Instance Model). Semantic interpretation of priority/status labels SHALL be derived from PROJECT.md's `delivery_approach` per [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md). When `delivery_approach: Custom`, priority/status semantics follow the `custom_methodology_definition` block — consult `lifecycle`, `ceremonies`, and `artifacts` fields for semantic guidance.

## Instance Model

This document is the label **grammar authority**; the concrete label rows are the **instance**, contributed by the methodology packs and reconciled to the live GitHub set by the label-parity gate. The live-label formula:

```
LIVE GitHub label set  ≡  _common.[[labels]]                    # archetype-invariant rows (core/packs/_common/pack.toml)
                        ∪  ( selected packs' [[labels]] )         # per-archetype deltas; selection by delivery_approach
                        ∪  ( operator-local overrides )           # K4 — operator.toml / operator-local, never corpus
                        −  ( operator-local removals )
```

- **Selection** is by `delivery_approach` in operator config (e.g. a Hybrid `[Scrum, Kanban]` deployment ⇒ `_common ∪ scrum ∪ kanban`).
- **Contribution** is the `[[labels]]` facet in `core/packs/<archetype>/pack.toml` — each row names its grammar `group` (one of the eight this doc defines) and, for `type:*` rows, its `projects_kind` join into the pack's `kinds[]`. The grammar defines the groups; a pack only populates them and may never define a new group or rule. The archetype-invariant rows — including the Axis-1 work-status base projection — are carried by `_common`; an archetype pack contributes only what genuinely differs from that base.
- **Overrides / removals** are K4 operator-local (color/description tweaks, extra project-local families like `size:*` / `layer:*` if the operator runs them) — never committed to this K1 corpus.
- **Reconciliation** is the label-parity gate ([`core/deploy/tools/check-label-parity.py`](../deploy/tools/check-label-parity.py), `deploy.sh` Check 51). It reads the canonical set as the **union of this grammar doc + every selected pack's `[[labels]]` facet + the `type:<kind_id>` projection of every selected pack's `kinds[]`** and diffs against the live set in **four** directions: a canonical label absent from GitHub is **MISSING** (enforce-capable); a live label registered by neither a concrete row, a declared kind, nor a namespace pattern (`project:*` / `epic:*`) is **ORPHAN**; a live label this grammar declares **excluded** (§ Excluded Labels) is **`EXCLUDED_LIVE`**; and a label that is declared *and* live whose **colour or description** disagrees with its declaration is **`DIVERGED`**. `EXCLUDED_LIVE` is a separate class from `ORPHAN` because the remedies are opposite — an orphan may simply need registering, whereas an excluded-but-live row means one of the two surfaces must change. `ORPHAN` and `EXCLUDED_LIVE` are warn-capable through the check's shared resolved mode. **`DIVERGED` alone is structurally non-escalating**, and that is a property of the emitter rather than of a mode setting: the check's mode dial is keyed per check-id, not per arm, so an escalating emitter would arm this arm on any future enforce flip — for a class whose remedy overwrites live label metadata that is repository state and not git-revertible, and which the gate cannot distinguish from a deliberate operator override. The grammar doc retains the namespace patterns and owns the exclusions; the packs carry the concrete rows and the declared kinds.

  **A per-row disposition is what makes the `DIVERGED` arm drainable.** Every divergent row is recorded once in `core/config/allowlists/label-attribute-dispositions.txt` as `reconcile-live` (the declaration is right), `reconcile-declaration` (live is right — corrected in the owning pack's `[[labels]]` row, never here), or `accept-override` (the divergence is deliberate). Only `accept-override` suppresses, and it is axis-scoped — accepting a colour does not accept a description, so a row registered on one axis still reports on the other. A `reconcile-*` row is owned but still divergent, so it keeps reporting until the operator-run reconciliation closes it. A registry row naming a label that is no longer divergent, or no longer live, reports as **`DIVERGED-STALE`** and should be removed: a suppression that has silently stopped matching is the same defect class this arm exists to close.

  **`type:*` is resolved, not prefix-matched, and the pack selection is what it resolves against.** It is deliberately absent from the namespace-pattern list above (§ Work-Item-Kind Labels states the invariant). Because the canonical set is built from the **selected** packs, the gate's source list must reach a deployment's operator-local (K4) packs as well as the corpus ones — kinds are K4 by grammar, so a gate that read only the corpus would report a deployment's own declared kinds as orphans. `type:subtask` is the one live `type:*` label that resolves to no declared kind and is nonetheless correct; it is a tolerated legacy alias (§ Tolerated Legacy Alias) that the gate filters out of every arm rather than reporting, because reporting it forever would invite the deletion its three consumers cannot survive. Tolerating it is not the same as declaring it: it is filtered from ORPHAN, never added to the canonical set, so it can never enter the enforce-capable MISSING arm.

  **A pack cannot declare an exclusion, and that placement is load-bearing.** The `[[labels]]` facet is a *contribution* surface — unioned across selected packs and overridable by K4 operator-local rows. An exclusion a pack can be added to override is not an exclusion. Exclusions are archetype-invariant, non-overridable grammar, so they live in this document.

  **A renamed § Excluded Labels heading is fail-loud, not silently empty.** The primitive parses that section by its heading; when at least one markdown source is supplied and none carries the header, it exits 3 on the existing "registry moved/renamed" contract rather than reporting an empty excluded set. A silently-empty set would read clean on exactly the condition the class exists to detect.

  **Reconciliation DETECTS; it does not MATERIALIZE — and the two are separate obligations.** A declared row does not become a live GitHub label by being declared. Nothing in the deploy path creates one, and no enforcement mode can: escalating the gate converts a silent warning into a permanent red, because a check that cannot create a label cannot clear a MISSING it reports. The sanctioned emit path is `check-label-parity.py --emit-fix`, which is **read-only** — it renders the `gh label create` / `gh label edit` / `gh label delete` commands and runs none of them, so every repository-state change stays an operator action with an auditable diff. Its blocks are ordered by increasing severity (create, then reconcile, then delete) so an operator pasting from the top never reaches a destructive command by momentum. A label is repository **state**, not repository **content**: a `git revert` of the commit that declared a row does not delete the label it produced, and a `git revert` cannot restore a label a delete removed — deletion is a separate manual step with no rollback inside this repository.

  **Two consequences follow from the NAME-KEYED arms, and both are load-bearing.** First, a row that is live with the wrong **colour or description** satisfies MISSING, ORPHAN and `EXCLUDED_LIVE` alike — all three compare names, so a malformed row reads as reconciled by every one of them. That class is now reported in its own right, as **`DIVERGED`**: advisory-only and structurally non-escalating, because the gate cannot distinguish a deliberate operator override from drift and the remedy overwrites live label metadata that no `git revert` can restore. A green Check 51 is therefore evidence about names, exclusions **and** unaccepted attribute divergence — but not about divergence an operator has deliberately registered as an accepted override in `core/config/allowlists/label-attribute-dispositions.txt`, which is suppressed by design. Second, a row can enter the live set **without ever being declared-then-created**: applying an unrecognized label to an issue brings it into existence with a default colour and no description. That ungoverned path is why a malformed row appears at all, and why an emit path that only creates — never reconciles — would leave the defect it was built to close still standing.

  **Every row therefore carries a colour.** A row declared without one is not emittable: a create with no colour silently takes the default grey, reproducing the malformed shape. `--emit-fix` reports such rows as unresolvable rather than guessing.
