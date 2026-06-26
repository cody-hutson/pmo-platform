# People Capability/Coverage Graph

<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- The `§4 #N` forms below are project-entity-model entity-anchor notation (Person #10, Resource #8), NOT GitHub issue references; work-item references are confined to the Provenance block. -->

**Status:** Canonical (K1 codified-knowledge spec)
**Owner:** `core/disciplines/people-coverage-graph.md`
**Composes:** the operator-instance functional people-roster (`people-roster.yaml`) + the FROZEN Person entity (`project-entity-model.md` §4 #10) + the FROZEN Resource entity (`project-entity-model.md` §4 #8), joined on `person_id`.

---

## 1. Purpose & boundary

This document specifies the **capability/coverage graph**: a read-time composed VIEW that lets a PMO agent answer who does what, who covers whom, and who can cover a given capability — without standing up a parallel people store. The graph composes three sources and forks none of them: the operator-instance functional roster supplies functional attributes (preferred name and spelling, roles, capability tags, coverage and escalation edges, status, project linkage); the frozen Person entity supplies the global identity anchor; the frozen Resource entity supplies project-scoped allocation. All three join on `person_id`, the cross-entity deduplication anchor.

The graph is **composed, not absorbed**. There is no materialized graph file, no derived people store, and no committed cache. The graph "exists" as (a) this documented composition contract and (b) the read-time join a consumer performs. This is the compose-not-absorb posture (per ADR-019 — specialists compose, do not absorb): a layer reads its substrate and never forks a parallel copy of it. Materializing a committed graph cache is forbidden — a persisted copy of roster-derived data duplicates the never-committed roster, drifts from it, re-introduces the staleness problem ambient maintenance exists to prevent, and turns an accidental commit of the cache into the same irreversible leak as committing the roster itself.

**Scope boundary.** This spec owns the graph view and its ambient maintenance. **Consumption is owned downstream by leg D** — the consuming skills that read the view and the registration of the clarification-queue template against its actual readers are a separate work item; this spec defines the read contract leg D consumes and wires no consumers itself.

**Frozen-schema boundary.** This spec adds no field to the frozen Person or Resource entities and adds no field to the roster. It specifies only the *view* over them. The frozen entity field lists in `project-entity-model.md` §4 are unchanged; `core/schemas/entity-field-schemas.md` is read (cited for the `person_id` deduplication anchor and the no-silent-default unresolved-reference rule) and not edited.

---

## 2. The view — read-time composition, joined on `person_id`

The view is computed on demand by a consumer from the three sources below. Each source contributes a distinct slice; the join key is `person_id` throughout.

| Source | Role in the view | Join key | Frozen? |
|---|---|---|---|
| `people-roster.yaml` (operator-instance functional roster) | functional attributes — preferred name and spelling, roles, capability **tags**, `backup_coverage`, `escalates_to`, `status`, `linked_project_ids` | `person_id` (top-level entry key) | No — operator-instance declarative config-layer |
| **Person** (`project-entity-model.md` §4 #10) | global identity anchor — `full_name`, `person_id`, `primary_role` | `person_id` (`Person.person_id`) | **FROZEN — read-only, composed not absorbed** |
| **Resource** (`project-entity-model.md` §4 #8) | project-scoped allocation — `project_id`, `allocation_pct`, `role_on_project` | `person_id` (`Resource.person_id` resolves to `Person.person_id`) | **FROZEN — read-only, composed not absorbed** |

### 2.1 The three view queries

1. **who-does-what** — for a `person_id`: the person's `full_name` and `primary_role` (from Person), their functional `roles` and capability `tags` (from the roster), and every `{project_id, role_on_project, allocation_pct}` they are allocated to (from Resource). Composition: Person joined with roster joined with Resource on `person_id`.

2. **who-covers-whom** — the coverage edge set. For each `person_id`, the roster `backup_coverage` (the list of person_ids who cover them) and `escalates_to` (the functional escalation target — a routing hint, **not** an HR reporting line). The reverse direction (whom does X cover?) is the inversion of `backup_coverage`. Composition: roster coverage edges resolved through `person_id` against Person identity.

3. **coverage-by-capability** — the inverted capability index. For a capability tag, every person whose roster `tags` contain it, annotated with `status` (active / on-leave / departed) so the view answers "who can cover capability C *right now*": an on-leave or departed person is visibly unavailable rather than silently surfaced as coverage. Composition: invert the roster `tags` into a capability-to-person_id index, filter by `status`, resolve to Person identity.

### 2.2 `person_id` is the spine

Every edge and every join in the view resolves through `person_id` — the deduplication anchor that the cross-entity consistency rules across the entity model resolve against. This is why a parallel or unwired people overlay is rejected by construction: an overlay that does not dedup against `person_id` re-introduces the misspelling-and-duplicate problem the functional-graph work exists to eliminate. The view leans on the single anchor so one person is never represented twice.

---

## 3. Ambient maintenance — event-driven refresh + clarification queue

Maintenance is **event-driven on a closed set of named trigger events**, not scheduled or polled. Each trigger is a bounded, enumerable surface; there is no cron job and no background scanner. The refresh registers as one ambient surface under the single workspace `automation_level` ceiling — the established platform pattern for governing ambient action through one dial — rather than inventing a parallel scheduler. When `automation_level` permits ambient action, the refresh executes; the clarification-queue enqueue (§3.2) always happens regardless of the dial, because queuing is observation, not a state-mutating auto-action.

### 3.1 The closed trigger set

| # | Trigger event | What fires it | Refresh action |
|---|---|---|---|
| **TE-1** | `people-roster.yaml` is touched (operator hand-edit or agent machine-write) | roster modification-time change / write completion | re-derive the view's indices (coverage edges, capability-to-person index); **auto-invoke `core/deploy/extract-roster-needles.sh`** (see §3.3); resolve any newly-surfaced name against `person_id` |
| **TE-2** | a Resource or owner write references a `person_id` (an allocation write, a RAID-owner reference, an owner-field write) | the referencing write's `person_id` resolution step | confirm the `person_id` resolves in Person and the roster; if it does not, route the unresolved identity to the clarification queue (the TE-4 path) |
| **TE-3** | an external or unrecognized name surfaces during agent work (a transcript names a person not in the roster; an owner free-text value does not resolve to a `person_id`) | a name-resolution miss in any consuming agent | enqueue a clarification item (the candidate name, the surfacing context, the source event) |
| **TE-4** | a `person_id` reference fails to resolve (a ghost reference — the unresolved cross-entity case) | a reference-resolution miss | enqueue a clarification item; the *write* disposition of the ghost reference stays governed by the existing cross-entity unresolved-reference rule — this spec routes the unresolved *identity* to the queue, it does not change the write disposition |

### 3.2 The clarification queue — never silently invent

The clarification queue is the mechanism that makes maintenance safe: an unrecognized or ambiguous person is **queued for operator confirmation, never silently invented**. This is the no-silent-default rule — when a value (here, an identity) cannot be resolved, the system surfaces it for confirmation rather than guessing a default. When a name or reference does not resolve to a `person_id`, the maintenance path writes a queue item and does **not** create a Person, does **not** add a roster entry, and does **not** guess a `person_id`.

**Queue home.** The runtime queue is operator-instance and **never committed** — it holds unresolved real names, which are PII-adjacent, so the never-committed boundary binds it. The runtime file lives at the operator-instance path resolved by `core/deploy/lib-instance-path.sh` (the single resolution site for operator-instance paths — no new path variable is invented). Only a de-identified **schema template** ships, as `operations/templates/people-graph-clarification-queue-template.md`. This is the same split-class shape the platform already uses for hub-state: a customizable-public schema template is tracked, while the runtime instance that mutates frequently and has no cross-operator readership stays operator-local.

**Queue item shape** (one row per unresolved identity):

| Field | Meaning |
|---|---|
| `candidate_name` | the unresolved name or spelling as observed |
| `source_event` | which trigger event surfaced it (TE-1..TE-4) plus the source artifact (transcript / owner field / roster edit) |
| `disambiguation` | candidate `person_id` match(es) the resolver found, if any — for confirm-or-reject |
| `proposed_disposition` | the agent's RECOMMENDED resolution (add as new Person plus roster entry / map to an existing `person_id` / mark external) — a recommendation, not an action |
| `status` | `pending` → (operator) `confirmed` / `rejected` |
| `raised` | the date the item was enqueued |

**Resolution is operator-gated.** The operator reviews the queue and confirms each item. On `confirmed`, the operator (or an agent under explicit per-item approval) applies the resolution to the roster or Person — and only then does the identity exist in the graph. On `rejected`, the item is dropped; if it was a ghost reference, the underlying write stays governed by its existing unresolved-reference rule. Nothing leaves the queue into the authoritative graph without operator confirmation.

### 3.3 Roster-touch auto-invoke of the needle extractor

`core/deploy/extract-roster-needles.sh` reads the operator-instance roster and appends preferred names and spellings to the localized-context needle file that the PII pre-commit hook scans, so a commit accidentally containing a roster name is blocked when that hook is installed in enforce mode. The extractor is append-only, deduplicated, idempotent, and read-only against the roster.

On its own the extractor is operator-run, which leaves a staleness window: a roster name added since the last run is not yet a needle and would not be blocked until the extractor is re-run by hand. **TE-1 (roster touch) auto-invokes the extractor as part of the refresh**, so a newly-added roster name is fed into the needle list without the operator's manual re-run. Because the extractor is idempotent, repeated invocation is safe. This auto-invoke closes the needle-staleness window — that closure is the concrete deliverable of this trigger. The auto-invoke only *calls* the already-built, already-allowlisted extractor; this spec authors no new executable script and changes neither the extractor nor the PII hook.

---

## 4. Provenance & conflict rules — `person_id`-anchored

Every fact the view surfaces carries its origin, read from the source's provenance discriminator.

| Fact class | Provenance source | How it is read |
|---|---|---|
| Identity (`full_name`, `primary_role`) | **Person** (frozen) | authoritative by definition — Person is the identity anchor |
| Allocation (`project_id`, `allocation_pct`, `role_on_project`) | **Resource** (frozen) | authoritative — Resource owns project-scoped allocation |
| Functional attributes (preferred name, roles, tags, coverage, escalation) | **roster**, carried as `{value, source, last_verified}` per fact | `source` ∈ {operator-edit, agent-inference, template-default}; `last_verified` is the recency stamp |

**Conflict resolution — the precedence ladder** (applied in order when two facts disagree):

1. **Operator-edited beats roster value beats agent-inferred.** The roster `source` discriminator decides; an operator edit always wins over an agent inference. A last-write-wins rule is explicitly rejected — a stale agent inference written after an operator edit must never overwrite the operator.
2. **Tie within one source class → the most recent `last_verified` wins.**
3. **Identity collision** (a name maps to two candidate `person_id`s, or two roster entries claim one identity) → resolved by the **`person_id` deduplication anchor**: `person_id` is globally unique within the cross-project-shared tier, so the correct identity is the one whose `person_id` resolves in Person. If the collision genuinely cannot be resolved by `person_id` (two real candidates), it **escalates to the clarification queue** — the system does not auto-pick (the no-silent-default rule).
4. **Frozen-versus-roster disagreement** (e.g., roster `roles` versus `Person.primary_role`) → the view surfaces **both** with their provenance labels and does **not** overwrite the frozen Person value. The roster `roles` is the *functional* multi-role list; `Person.primary_role` is the *identity* role. They are different facts, not a conflict to collapse — composing the two is the point, absorbing one into the other is forbidden.

All identity deduplication and conflict-identity resolution key on `person_id`, the cross-entity-consistency anchor.

---

## 5. Autonomy tier — the identity-creating write is Tier 1

Maintenance actions declare their autonomy tier explicitly. The load-bearing one is the identity-creating write: it is **Tier 1 (Recommend)** — the agent drafts and recommends, the operator approves before the state change. The clarification queue *is* that Tier-1 approval gate.

| Maintenance action | Tier | Why |
|---|---|---|
| Re-derive the view indices (coverage edges, capability index) on a trigger | read-only — no tier gate | the view is read-time; re-derivation produces no durable artifact |
| Auto-invoke `extract-roster-needles.sh` (TE-1) | bounded-auto within the `automation_level` ceiling | feeds an existing gitignored needle file from the existing roster; bounded to the extractor's declared behavior; descends to Tier 1 if it would act outside that scope |
| Enqueue a clarification item (TE-3 / TE-4) | observation — always allowed | queuing is not creating an identity; it is the Tier-1 draft/recommend surface, writing only to the operator-instance queue |
| Create a Person / add a roster entry / map a name to a `person_id` | **Tier 1 — operator approval required** | this is the identity-creating write; the agent never auto-creates one |

An unrecognized or ambiguous person is never silently invented; it waits in the queue for operator confirmation. **Consumption is deferred** to leg D — this spec specifies the graph and its maintenance; no consuming skill reads the view here.

---

## 6. Verification

The view contract, the trigger set, and the clarification-queue mechanics in this document are verified at authoring against the cited sources: the frozen Person and Resource field lists in `project-entity-model.md` §4 #10 and §4 #8 (unchanged by this spec); the `person_id` deduplication anchor and the no-silent-default unresolved-reference rule in `core/schemas/entity-field-schemas.md`; the operator-instance roster contract in `operations/templates/people-roster-template.yaml`; the single operator-instance path resolver in `core/deploy/lib-instance-path.sh`; and the needle extractor in `core/deploy/extract-roster-needles.sh`. No file under `core/schemas/` and no frozen field list is modified by this spec — the design composes, it does not mutate.

---

## Reference

- People capability/coverage graph (leg C) — this spec: defines the read-time composed view, the ambient-maintenance trigger set, the clarification queue, the provenance precedence ladder, and the Tier-1 declaration; the work item is #1166.
- Functional people-roster data surface — the operator-instance roster (`people-roster.yaml`), its `{value, source, last_verified}` provenance, its `status` tombstone enum, and the `backup_coverage` / `escalates_to` / `linked_project_ids` reference fields this graph composes over; the work item is #315.
- Spike (graph-view mechanism + data-handling boundary) — established that leg C composes the frozen Person and Resource over the roster keyed on `person_id` (no parallel store), reads the operator-instance store and never materializes a committed cache, and treats ambient maintenance as Tier 1 (clarification queue, never auto-create); the work item is #1897.
- Consumption (leg D) — inherits the view contract (the three queries, the `person_id` join), registers the clarification-queue template against its actual consuming skills, and owns the clarification-queue resolution experience; the work item is #1899.
