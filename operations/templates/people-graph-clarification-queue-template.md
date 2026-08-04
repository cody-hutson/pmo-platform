---
artifact_type: template
template_family: People-Graph Clarification Queue
domain: project
canonical_path: operations/templates/people-graph-clarification-queue-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-06-25
updated: 2026-08-03
generated_by: release-pipeline v4.06
reviewer: N/A
canon: PMBOK 7 §Stakeholder Performance Domain
canon_compat: none
version: "v4.06"
supersedes: N/A
superseded_by: N/A
---
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into a filled operator-instance queue — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5 path c-i): domain:project AND no Anthropic plugin counterpart for the People-Graph Clarification Queue family (template-taxonomy.md §3.1 carries no plugin cross-ref; the family takes no §6 row per §2.1 F4). `none` is the ANTICIPATED resolution at DRAFT — authoritative only at an APPROVED transition. -->

# People-Graph Clarification Queue — de-identified template (CUSTOMIZABLE-PUBLIC, tracked)

> This is the SHIPPED TEMPLATE. The FILLED queue is OPERATOR-INSTANCE and is
> NEVER committed. It lives OUT OF THE REPOSITORY TREE at
> `$(pmo_instance_path)/people-graph-clarification-queue.md`
> (resolved via `core/deploy/lib-instance-path.sh`; default
> `~/Claude/personal/pmo-instance/`), a sibling of the repository — out-of-tree
> placement is the PRIMARY protection, because the queue holds UNRESOLVED REAL
> NAMES awaiting operator confirmation. Only this de-identified template ships.
>
> Fill the placeholders (`[CANDIDATE_NAME]`, `person-id-001`, `[SOURCE_ARTIFACT]`,
> `[PROJECT_ID]`, `[YYYY-MM-DD]`) only in your operator-instance copy — never in
> this committed template.

## Reading contract

This queue holds **unresolved person identities awaiting operator confirmation**. It is
a FUNCTIONAL coordination artifact, not an HR system. An item is a *candidate*, not a
created identity: nothing in this queue is in the capability/coverage graph until the
operator confirms it. A missing value is `unknown` — represent it as `unknown`, never
guess. Do not infer or write any field outside the schema below. The agent enqueues and
recommends; the operator confirms or rejects (Tier 1). Resolution is operator-gated —
the maintenance path never creates a Person, adds a roster entry, or guesses a
`person_id` on its own.

## Queue items

One row per unresolved identity. `status` moves `pending` → (operator) `confirmed` /
`rejected`.

| candidate_name | source_event | disambiguation | proposed_disposition | status | raised |
|---|---|---|---|---|---|
| [CANDIDATE_NAME] | TE-3 (transcript: [SOURCE_ARTIFACT]) | possible match: person-id-001 — confirm or reject | map-to-existing person-id-001 (RECOMMENDED) | pending | [YYYY-MM-DD] |
| [CANDIDATE_NAME] | TE-4 (owner field on [PROJECT_ID] did not resolve) | no candidate match found | add-as-new Person + roster entry (RECOMMENDED) | pending | [YYYY-MM-DD] |

### Field semantics

| Field | Meaning |
|---|---|
| `candidate_name` | the unresolved name or spelling as observed |
| `source_event` | which trigger event surfaced it (`TE-1`..`TE-4`) plus the source artifact (transcript / owner field / roster edit) |
| `disambiguation` | candidate `person_id` match(es) the resolver found, if any — for confirm-or-reject; `no candidate match found` when none |
| `proposed_disposition` | the agent's RECOMMENDED resolution — `map-to-existing <person-id>` / `add-as-new` / `mark-external` — a recommendation, **not** an action |
| `status` | `pending` \| `confirmed` \| `rejected` |
| `raised` | the date the item was enqueued (`YYYY-MM-DD`) |
