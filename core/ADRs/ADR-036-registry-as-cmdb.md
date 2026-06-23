<!-- reference-durability: allow-link -->
---
title: ADR-036 — Registry as CMDB / single skill catalog — core/skills/registry.md is evolved into the platform's single Configuration-Management catalog (all deployed skills are CIs carrying lifecycle-state, dependency, and owner axes; version and roster-existence are CITED from SKILL.md and deploy.sh, never stored); the pmo-skill-router classifies against a kind==role-Specialist filtered VIEW, so routing is unblurred; this SUPERSEDES ADR-035 §Decision part 4 (role-Specialists-only population) and PRESERVES ADR-035's central-index and no-SKILL.md-frontmatter decisions
status: Proposed
date: 2026-06-23
release: 13-field-lifecycle-and-cmdb-automation (v2.20)
deciders: "operator + Stage 5 Solutioning spoke"
tags: [architecture, skills, cmdb, configuration-management, registry, single-catalog, routing-view, kind-discriminator, lifecycle-state, supersedes-adr-035, duplicate-source-discipline, core-module, reversibility]
source_observations:
  - "#202 (operator ruling on the approved Stage 4 plan) restored full scope — Artifact Register AND skill-CMDB — under the HARD CONSTRAINT 'a SINGLE skill registry/catalog; no second registry.' A prior Stage-5 spoke recommended Option B (CMDB as a separate core/schemas/ reference-schema). The operator OVERRODE that and selected Option A — evolve the single registry.md INTO the CMDB — on the rationale 'I don't want two skill registries': Option A yields ONE catalog (registry.md), Option B leaves two (registry.md + the new schema)."
  - "Live survey: the CMDB CI population is the 43 deployed skills (deploy.sh: 27 operations + 12 release + 4 core); registry.md holds 19 role-Specialist routing rows with 4 fields and no kind/lifecycle/deps/owner column; SKILL.md version: exists on 44 files; the 3 contract indexes exist; the System entity carries a frozen active→deprecated→retired Axis-1 machine (V-SYS-04); NO CMDB or skill-lifecycle artifact exists. Roster/version/contract already have authoritative homes (deploy.sh / SKILL.md / the 3 indexes), so the only net-new CMDB content is {kind, lifecycle-state, dependency-edges, owner}."
---

# ADR-036 — Registry as CMDB / single skill catalog

## Status

Proposed. Drafted at Stage 5 Solutioning for the skill-CMDB work item of the
`13-field-lifecycle-and-cmdb-automation` (v2.20) release; materialized at Stage 6
alongside the registry.md evolution it governs. Flips to Accepted at this release's
Collective Review scope-lock — the release activates Stage 5 with two or more Solutioning
issues, so Collective Review is the ratification gate, consistent with ADR-035 and ADR-019.
Recorded as Proposed (not Accepted) at authoring because that gate has not yet run. On
acceptance, ADR-035 receives an in-place "Superseded-in-part by ADR-036" note scoping the
supersede to its §Decision part 4.

## Context

The skill-CMDB work item asks the platform to "formalize the skill registry as a CMDB." The
operator restored the full scope (Artifact Register AND skill-CMDB) under one hard constraint:
**a single skill registry/catalog — there must not be two skill registries.** A prior Stage-5
spoke recommended realizing the CMDB as a *separate* `core/schemas/skill-cmdb-schema.md`
(Option B). The operator **overrode** that and selected **Option A — evolve the single
`core/skills/registry.md` into the CMDB** — because Option B would leave two skill catalogs
(the registry plus the new schema), whereas Option A yields exactly one: the registry becomes
the CMDB, and routing becomes a view of it.

A CMDB is a catalog of Configuration Items (CIs) with their attributes and inter-CI
relationships. For skills-as-CIs the CI population is **all deployed skills** — the members of
the `core/deploy/deploy.sh` per-module arrays (`OPERATIONS_SKILLS` + `RELEASE_SKILLS` +
`CORE_SKILLS`), `deploy.sh` being the single roster source of truth per ADR-008. A live survey
established the decisive fact: the axes a skill-CMDB needs split into two classes. **Roster,
version, and I/O-contract already have authoritative homes** — the `deploy.sh` arrays (roster +
count), each `SKILL.md` `version:` frontmatter (version), and the three federated contract
indexes (`per-skill-output-contracts.md`, `agent-processing-contracts.md`,
`stage-io-contracts.md`). **Only four axes exist nowhere today:** a CI `kind` discriminator, an
operational `lifecycle-state`, `CI-to-CI dependency edges`, and an `owner`. No CMDB artifact and
no per-skill `lifecycle_state` exists.

`core/skills/registry.md` today is, per ADR-035, a role-Specialist-**only**, routing-**only**
central index (19 rows, four routing fields). ADR-035 §Decision part 4 **explicitly excluded
registering all skills**, on the reasoning that doing so "would make the registry a deploy-roster
duplicate and blur what the router classifies against." Option A must therefore supersede that one
clause **and rebut both concerns directly** — which it does (see Decision parts 2 and 4). The
decision clears the ADR threshold: it is non-obvious (it reverses a frozen ADR clause and must
rebut the router-blur risk that clause protected) and cross-cutting (it governs the catalog that
the router, the deploy roster check, and every role-Specialist composition reference touch).

## Decision

**`core/skills/registry.md` is evolved into the platform's single skill Configuration-Management
catalog (CMDB). There is exactly one skill catalog; routing is a typed view of it.**

1. **The catalog's CI population is all deployed skills** — the members of the `deploy.sh`
   per-module arrays. Each CI is one row. The source-only canary
   (`pmo-skill-refiner-selftest-canary`, ADR-04, no package) is NOT a CI (the population is the
   *deployed* roster).

2. **The catalog CITES, never stores, the axes that already have homes.** Roster existence + count
   are proved against the `deploy.sh` arrays (Check 5/5(c) keep owning the count); `version` is read
   per row from each `SKILL.md` `version:`; the I/O contract is the three contract indexes. A new
   "Sources of truth (do not duplicate)" section names them. The catalog stores **no** version column
   and **no** standalone count — a stored version would drift on every skill bump (a Check-5(c) risk),
   and a stored roster would duplicate `deploy.sh`. This cite-don't-store split is what keeps the
   single catalog from being a `deploy.sh` duplicate: it catalogs the externally-sourced roster with
   net-new CI attributes, it does not re-originate it. This **directly rebuts ADR-035's "deploy-roster
   duplicate" concern.**

3. **The catalog stores the four net-new axes:** `kind` (`role-Specialist | function-skill | core |
   router`); `lifecycle-state` (REUSING the frozen `System` entity Axis-1 machine `active →
   deprecated → retired`, `project-entity-model.md` §4 #11 / `entity-field-schemas.md` §3.11 V-SYS-04
   — a skill-as-CI is the technical-system analogue and inherits that 3-state machine rather than
   originating a fourth vocabulary; default `active`); `dependencies` (CI-to-CI edges typed from the
   seven MVP relationship types in `frontmatter-schema.md` §Cat-4 — encoding the ADR-019
   compose-not-absorb graph and the cascade-allowlist edges as data); and `owner`. The existing
   routing fields `trigger surface` and `modes` are **preserved but become role-Specialist-only**
   (`—` for non-routing CIs).

4. **The `pmo-skill-router` classifies against a `kind == role-Specialist` filtered VIEW of the
   catalog** — the 19-row projection that is byte-for-byte the surface it classifies against today.
   The non-role CIs (function-skills, core, the router itself) are present in the catalog but
   **excluded from the routing view** by the `kind` filter, and carry `—` in `trigger surface`/`modes`
   regardless, so they add **zero** strings to the router's classification input. The router's
   classification logic, hints, tie-break ladder, and failure modes are unchanged; only its read
   target changes from "the table" to "the `kind == role-Specialist` view of the table." **This
   directly rebuts ADR-035's "blur what the router classifies against" concern: the router's input is
   unchanged; the table it is a view of grew, the view did not.** Every routing-registry row is a CI;
   not every CI is a routing target (the router and function-skills are CIs but not routes).

5. **Physical placement stays `core/`** (ADR-035 part 5 preserved); the cross-module `SKILL.md` /
   `deploy.sh` references remain accepted documentary cohesion under ADR-007's v2 carry-forward
   (`reference-durability: allow-link` marker retained). **No `SKILL.md` is edited to add a CMDB
   field** — registration stays a central-index row, never a frontmatter field (ADR-035 part 3
   preserved). The only skill body touched is the `pmo-skill-router`'s, for the view-read (a consumer
   edit, not a registration-field edit), applied via pmo-skill-editor discipline.

## Consequences

- **The single-catalog constraint is satisfied structurally.** Exactly one skill catalog exists
  (`registry.md`, now the CMDB). Routing is a typed projection of it, not a second artifact. The
  operator's "I don't want two skill registries" is met by construction.
- **ADR-035 is superseded in part, preserved in whole otherwise.** Only §Decision part 4
  (role-Specialists-only population) is superseded; parts 1/2/3/5 (single central index, extensible
  schema, no-SKILL.md-frontmatter registration, `core/` placement + allow-link) are preserved and
  remain load-bearing. ADR-035's protected property (clean role-Specialist classification) is kept,
  now enforced by the `kind` filter instead of by table membership. ADR-035 receives an in-place
  "Superseded-in-part by ADR-036" note.
- **The router's classification is unchanged in substance.** A surgical, behavior-preserving edit to
  the router's read target; no change to classification logic, hints, ladder, or FMs. The router-itself
  and all function-skills become structurally unroutable via the `kind` filter (FM2 strengthened).
- **Net-new originated vocabulary is zero.** `lifecycle-state` reuses the `System` machine; dependency
  edges reuse the seven MVP types; `kind` encodes the ADR-019 role/function distinction. The catalog
  composes frozen machinery.
- **Duplicate-source-discipline is satisfied by the cite-don't-store split.** Version + roster + contract
  are cited (not stored); only the net-new axes + the pre-existing condensed routing fields are stored.
  The "Sources of truth (do not duplicate)" section is the register-or-remove enforcement surface.
- **Blast radius is bounded.** The registry.md population expands (43 CIs) and gains columns; the
  `pmo-skill-router` body gets one surgical view-read edit; ADR-035 gets a status note. Every
  role-Specialist body's "through the core/-registry skill-chain" phrasing still resolves (the registry
  is still at `core/skills/registry.md`, still a central index) — no role-Specialist body is edited.
  This is heavier than Option B (which touched no skill body) by exactly one surgical router edit + the
  catalog expansion — the cost of one catalog instead of two.
- **A CI↔deploy.sh reconciliation check moves from reserved toward recommended.** ADR-035 reserved an
  optional registry-to-roster check as enforcement-theater at 19 rows; at 43 CIs the consistency between
  CI rows and `deploy.sh` members is more load-bearing, so a check asserting "every CI row ↔ a `deploy.sh`
  member and vice versa, and every CI row's `name` resolves to a live `SKILL.md`" is **recommended** (not
  yet required — manual review at backfill + each skill's definition-of-done still covers drift at this
  roster size). This is the consistency guard that keeps the single catalog and `deploy.sh` from drifting.

## Alternatives rejected

- **(B) CMDB as a separate `core/schemas/skill-cmdb-schema.md` reference-schema** (the prior spoke's
  recommendation). Rejected by operator override: it leaves **two** skill catalogs — `registry.md` (19
  role-Specialists) plus the new schema (43 CIs) — which is the "second registry" the single-catalog
  constraint forbids under the operator's reading. Its lower blast radius (no skill-body edit) does not
  outweigh the constraint: the operator chose one catalog over the smaller diff.
- **A new hand-maintained all-43 table that re-lists the `deploy.sh` roster** (the prior spec's "Option
  C"). Rejected: it would duplicate the `deploy.sh` roster (parameterize-over-hardcode / Check-5(c)
  violation). Option A does NOT do this — it cites `deploy.sh` for existence/count and stores only the
  net-new axes (Decision part 2); the catalog is the one list, validated against `deploy.sh`, not a
  parallel re-listing.
- **A `lifecycle_state`/`owner`/`kind` frontmatter field on each `SKILL.md`, aggregated at build.**
  Rejected for the same reason ADR-035 rejected per-`SKILL.md` registration: backfilling every `SKILL.md`
  file trips the skill-edit hook and balloons blast radius; the central-catalog model touches no skill
  body for registration (ADR-035 part 3, preserved).
- **Removing the routing fields from the catalog and giving the router a private list.** Rejected: it
  would re-introduce a hardcoded router list (the exact coupling ADR-035 + the router's FM1 exist to
  prevent). The `kind`-filtered view keeps the router list-free — it reads the catalog by path and
  filters, enumerating nothing.

## Reversibility

**EXPENSIVE / Confidence HIGH — once the CIs are populated** (same tier ADR-035 declares for the
registry once role-Specialists register). The catalog at `core/skills/registry.md` is bound to by the
`pmo-skill-router` (now via the routing-view read), ADR-035 (the status note), ADR-036 (this record), and
every role-Specialist body that describes composition "through the core/-registry skill-chain." Backing
the population out — collapsing the CIs back to the 19 role-Specialists and reverting the router's
view-read — is a multi-surface cascade. **CHEAP pre-build** — before the rows are authored and the router
edit lands, the population scope is a free choice. This matches ADR-035's own EXPENSIVE-once-populated
posture; Option A inherits that tier (it shares the registry's home + the router binding), and adds the
router view-read as one more bound surface. (Option B was CHEAP→MODERATE — strictly cheaper — but leaves
two catalogs; the operator accepted the higher reversibility tier for the single catalog.)

## Related ADRs

- [ADR-035](ADR-035-registry-as-classification-source.md) — Registry as classification source.
  **Superseded in part (§Decision part 4 only) and preserved otherwise** by this ADR. Parts 1/2/3/5
  (single central index, extensible schema, no-SKILL.md-frontmatter registration, `core/` placement +
  allow-link) remain load-bearing; the `kind`-filtered routing view preserves part 4's protected property
  (clean role-Specialist classification) while reversing its population scope. ADR-035 receives an in-place
  "Superseded-in-part by ADR-036" note.
- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — Specialists compose, not absorb. The
  role-vs-function distinction the `kind` column encodes, and the compose-not-absorb graph the
  `dependencies` axis stores as CI-to-CI edges.
- [ADR-007](ADR-007-core-module-boundary.md) — Core module boundary + carry-forward. The legal basis for
  a `core/` catalog that doc-links `operations/`/`release/` `SKILL.md` and cites `deploy.sh` (accepted
  documentary cohesion; the same posture `per-skill-output-contracts.md` relies on).
- [ADR-008](ADR-008-deploy-sh-per-module-array-design.md) — deploy.sh per-module array design. The single
  roster source-of-truth the CMDB CITES for its CI population (existence + count) rather than duplicating.
- [ADR-006](ADR-006-skill-to-module-map.md) — Skill-to-module map. The partition the CMDB's `module` axis
  reflects.

### Source(s)

- The skill-CMDB work item and its approved Stage 4 plan — the operator ruling that restored full scope
  under the single-catalog hard constraint; and the operator override selecting Option A over the prior
  spoke's Option B recommendation, on the "one catalog" rationale.
- The live survey: `deploy.sh` arrays (43 deployed skills), `registry.md` (19 rows, 4 fields, no CI
  columns), `SKILL.md version:` (44), the 3 contract indexes, the System `active→deprecated→retired`
  machine (V-SYS-04), and the zero-CMDB / zero-skill-lifecycle finding.
- The reuse sources: `project-entity-model.md` §4 #11 (System Axis-1 machine) and `frontmatter-schema.md`
  §Cat-4 (the 7 MVP relationship types).
