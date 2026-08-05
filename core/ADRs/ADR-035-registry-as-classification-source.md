<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-035 — Registry as classification source — the core/ logical skill registry is a single central markdown index, registration is a central-index row (never a SKILL.md frontmatter field), and only role-Specialists register
status: Proposed
date: 2026-06-20
release: 05-ROLE-sustain-coverage-router (v2.15)
deciders: "operator + Stage 5 Solutioning spoke"
tags: [architecture, skills, registry, classification-source, role-specialist, router, central-index, core-module, parameterization, carry-forward, reversibility]
source_observations:
  - "The role-Specialist suite (ADR-019) needs an addressable entry point: a router that classifies a role-shaped request to the correct role-Specialist without enumerating a hardcoded skill list. Every role-Specialist's acceptance criteria say it 'registers into the core/ logical skill registry', and that registry did not exist at v2.11 (verified: core/skills/ held only eval-writer/, pmo-qa-auditor/, prompt-builder/, README.md). The Stage 4 plan flagged the registry schema as novel with no precedent file to copy (Risk R6) and recommended a thin ADR to make the schema and the registration contract durable."
  - "Backfilling the registry for the existing role-Specialists must not edit their SKILL.md files — editing them would trip the skill-edit hook and balloon the change's blast radius. The platform already has a central per-skill index that catalogs skills without editing any SKILL.md (core/schemas/per-skill-output-contracts.md), establishing the central-index pattern this decision adopts and extends to the role-routing surface."
---

# ADR-035 — Registry as classification source

## Status

**Proposed.** Drafted at Stage 5 Solutioning for the registry-foundation work item of the `05-ROLE-sustain-coverage-router` (v2.15) release and materialized at Stage 6 alongside the registry it governs. Flips to **Accepted** at the v2.15 Collective Review scope-lock — the release activates Stage 5 with two or more Solutioning issues, so Collective Review is the ratification gate, consistent with how ADR-019 set its own status. The decision is recorded as Proposed (not Accepted) at authoring time precisely because that ratification gate has not yet run.

> **Superseded-in-part by [ADR-038](ADR-038-registry-as-cmdb.md).** §Decision **part 4** (only role-Specialists register) is **superseded** — ADR-038 evolves this registry into the single skill CMDB whose CI population is all deployed skills. The router's clean classification (part 4's protected property) is preserved by ADR-038's `kind == role-Specialist` filtered routing view, not by table membership. §Decision **parts 1/2/3/5** (single central markdown index, extensible four-field schema, no-`SKILL.md`-frontmatter registration, `core/` placement + `allow-link`) remain **load-bearing and unchanged**.

## Context

The platform delivers PMO roles as **role-Specialists** — thin, role-named skills (Portfolio Manager, QA Lead, Software Engineer, …) that *compose* shared function-skills rather than re-implementing them (the compose-not-absorb decision, ADR-019). To make the suite addressable, a capstone **role-router** must take a role-shaped request and classify it to the correct role-Specialist. The router cannot carry a hardcoded list of skills: a list embedded in the router's logic would have to be edited every time a role is added or removed, which defeats the point of a parameterized routing surface.

The acceptance criteria for every role-Specialist therefore say it "registers into the `core/` logical skill registry," and the router's acceptance criteria say it reads that registry to classify. But at v2.11 the registry **did not exist** — `core/skills/` held only the three core function-skill directories and a README. Two coupled questions had no precedent:

1. **What is the registry, physically, and what does a registry entry contain?** The "logical skill registry" was described only functionally (the fields `name · module · trigger surface · modes`); no schema document or example file existed in the repository to copy.
2. **How does a skill "register"?** Two registration models are possible: (a) a **central index** the router reads, with every entry authored in one registry file; or (b) a per-skill **frontmatter field** on each `SKILL.md`, aggregated by a build step. Option (b) would require editing every already-built role-Specialist's `SKILL.md` to backfill it — which trips the skill-edit hook and expands the change's blast radius, exactly what the backfill must avoid.

The platform already answers the central-index question elsewhere. `core/schemas/per-skill-output-contracts.md` is a central index that catalogs every skill's output contract in one file, keyed by skill, **without any of those skills carrying an "output-contract" frontmatter field** — and it is consumed by path (the QA auditor reads it as its per-skill structural-review source). That file is the proven precedent the registry mirrors.

## Decision

Adopt the **registry-as-classification-source** model, with five coupled parts:

1. **The registry is a single standalone central markdown index** at `core/skills/registry.md`, structured like `core/schemas/per-skill-output-contracts.md`: a human-readable document with one canonical table, keyed by the skill `name`. Markdown (not a `.toml` or other parsed format) is chosen because the consumer is a classification-driven skill that reads the file as context, not a machine parser — the router classifies on the `trigger surface` prose directly, so no parse step exists to justify a structured data format, and mirroring the precedent inherits a proven, reviewed structure rather than inventing one.

2. **The entry schema is the four fields `name · module · trigger surface · modes`** (one table row per role-Specialist). `name` is the canonical `name:` frontmatter value and the routing referent; `module` is the module the skill lives under (drives the doc-link); `trigger surface` is the router-classifiable description condensed from the skill's `description:`; `modes` is the skill's mode set lifted from its `description:` `Modes:` clause. This is the minimal first cut — additional columns (for example a sourcing-coupling column tracking the ADR-023 posture) are deliberately deferred as a cheap, additive future extension rather than shipped now.

3. **Registration is a central-index row, never a `SKILL.md` frontmatter field.** Every role-Specialist is represented by exactly one row in `core/skills/registry.md`, authored centrally in that file. A skill does NOT add a registry/role field to its own `SKILL.md`. A new role-Specialist is added to the routing surface by appending one row; an existing one is updated by editing its row. Backfill for the already-built role-Specialists is therefore purely additive — it creates the registry file and reads each skill's existing `description:` and module membership into rows, editing no `SKILL.md`. This honors the no-SKILL.md-edit constraint and matches the precedent (the output-contracts index carries no corresponding per-skill frontmatter field).

4. **Only role-Specialists register; the registry is the router's sole classification source.** A skill registers iff it is a Role-Specialist (role-named, composing function-skills per ADR-019). Function-skills — including the three core shared function-skills and the Organizer/Orchestrator skills — do NOT register: they are the machinery roles compose, not routing targets. The router itself does not register (a router does not route to itself). The router enumerates no skill list of its own — the registry table is the only source — so routing changes by editing the registry, never the router. This is the parameterization the router's "a skill is added by appending an entry, not editing the router" criterion requires.

5. **Physical placement is `core/`, and the `core/`→module references are accepted documentary cohesion under ADR-007.** The registry lives in `core/` because it is the shared kernel both the `operations/` and `release/` modules consume, and the router that reads it also lives in `core/`. The registry's links to `operations/` and `release/` `SKILL.md` files are markdown doc-links, not code-imports — the same cross-module cohesion ADR-007's carry-forward extension already permits and that `per-skill-output-contracts.md` already relies on. The registry carries the `reference-durability: allow-link` marker for those cross-module links, exactly as the precedent file does.

## Consequences

- **Every role-Specialist's "register into the registry" acceptance criterion becomes satisfiable**, because there is now a registry to register into; the capstone router's criterion narrows from authoring to consume-and-verify (does the registry exist, does it contain the full role-Specialist roster, does the router reference it).
- **The suite gains one durable home for its routing surface.** A new role-Specialist's authoring discipline gains a single "append your registry row" step; the row's `name` must equal the skill's `name:` frontmatter and directory name (the `deploy.sh` array membership is the existence proof).
- **The backfill is additive and edits no existing `SKILL.md`** — the foundation change creates the registry file and this ADR only; no skill body is touched. Blast radius is a new file plus this record, with no inbound references to break at creation time.
- **The deploy roster check is unaffected.** The registry is a markdown *file* under `core/skills/`, not a skill *directory*; the skill-roster-drift check iterates directories per the per-module arrays and never reads a file as a skill, so it stays green with no array edit for the registry. Existing doc-link maintenance validates the registry's outbound links (every `name` resolves to a live `SKILL.md`), and the `allow-link` marker satisfies the reference-durability gate for the cross-module links.
- **An optional registry-to-roster reconciliation check is reserved, not shipped.** A future deploy check could assert that every registry row is a role-Specialist present in a `deploy.sh` array and that every role-Specialist has a row. At the current roster size this would be enforcement-theater — manual review at the foundation step and at each role-Specialist's definition-of-done covers drift — so it is reserved against a later need rather than built now, mirroring the platform's existing "reserved future check; manual review suffices at current volume" posture for skill-pipeline alignment.

## Alternatives Considered

- **Per-`SKILL.md` frontmatter field aggregated at build.** Rejected: backfilling it for the already-built role-Specialists requires editing every one of their `SKILL.md` files — which trips the skill-edit hook and balloons the change's blast radius, the exact outcome the no-SKILL.md-edit constraint exists to prevent. The central-index model puts every entry in one new file and touches no skill body.
- **A structured `registry.toml` (or other parsed format).** Rejected: the consumer is a classification-driven skill that reads the file as context, not a machine parser, so there is no parse step to justify a data format; a `.toml` would also break parity with the `per-skill-output-contracts.md` precedent and add a dependency the router does not need.
- **Registering all skills (function-skills included).** Rejected: the router routes role-shaped requests to roles; function-skills are composition machinery, not routing targets. Indexing them would make the registry a deploy-roster duplicate and blur what the router classifies against.
- **Placing the registry outside `core/` (or per-module copies).** Rejected: the registry is the shared kernel both modules consume and the router that reads it lives in `core/`; a single `core/` home with accepted `core/`→module doc-links (ADR-007) is the cohesive placement, and per-module copies would fork the routing surface.

## Reversibility

**EXPENSIVE / Confidence HIGH — once role-Specialists register.** Relocating the registry's home after entries exist is a multi-file cascade: every registered row, this ADR, and the router that reads the file all bind to the `core/skills/registry.md` location, and role-Specialist bodies that describe their composition as brokered "through the core/-registry skill-chain" point at it. **CHEAP pre-build** — before any row is authored, the home is a free choice. This mirrors the ADR-019 pattern (cheap pre-build, crossing to higher tiers at the first dependent); here it crosses to EXPENSIVE rather than MODERATE because the full role-Specialist roster plus the router plus the forward-referencing skill bodies all bind to the chosen home.

## Related ADRs

- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — Specialists compose, not absorb; defines the role-Specialist-versus-function-skill distinction that determines what registers (role-Specialists) and what does not (function-skills and the Organizer/Orchestrator machinery).
- [ADR-007](ADR-007-core-module-boundary.md) — Core module boundary and carry-forward; the legal basis for a `core/` index that names `operations/` and `release/` skills via markdown doc-links (accepted documentary cohesion, not a code-import edge). `core/schemas/per-skill-output-contracts.md` is its canonical carry-forward example and this registry's structural precedent.
- [ADR-006](ADR-006-skill-to-module-map.md) — Skill-to-module map; the partition the registry's `module` column reflects.
- [ADR-023](ADR-023-skill-sourcing-coupling-posture.md) — Skill sourcing-coupling posture; the source of the deferred sourcing column (all role-Specialists are own-only judgment skills) noted as a future additive extension to the schema.
- [ADR-033](ADR-033-methodology-conditional-skill-activation.md) — Methodology-conditional skill activation; governs the dormant-under-non-matching-config behavior of the SAFe-conditional `pmo-release-train-engineer` row in this registry.

### Source(s)

- The registry-foundation work item of the `05-ROLE-sustain-coverage-router` (v2.15) release — establish the `core/` logical skill registry; references the foundation work item (#1564) and the capstone router story (#181) that consumes the registry. The Stage 4 release plan (`release/releases/plans/v2/v2.15_RELEASE_PLAN.md`) carries the dependency graph, contention map, and the Risk R6 (novel registry schema) that recommended this ADR.
- The central-index precedent: `core/schemas/per-skill-output-contracts.md` — a central per-skill index keyed by skill, consumed by path, carrying no per-skill frontmatter field; the proven pattern this decision adopts for the role-routing surface.
