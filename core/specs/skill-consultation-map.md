---
title: Skill Consultation Map
purpose: Prescriptive capability-dimension → in-house-first support-skill + governance map for run-time capability consultation (module-agnostic)
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
framework_version_anchor: v3.94
consumers: "release/governance/release-process.md § Capability-Consultation Self-Check (release is the first wired consumer; the map itself is module-agnostic)"
composes_with: anthropic-base-vs-build-registry.md, framework-catalog.md
adr: core/ADRs/ADR-023-skill-sourcing-coupling-posture.md
tags: [skill, consultation, capability, sourcing, routing, governance]
---
<!-- reference-durability: allow-link -->

# Skill Consultation Map

A prescriptive routing map from a **capability dimension** a run touches — architecture, systems / integration design, triage, production-readiness review, risk, and any dimension added under the extension rule below — to the **in-house support skill(s) to consult first**, the **Anthropic-backup** permitted only when no in-house cover exists, and the **governance** the dimension answers to. This map is the home of the *in-house-first* prescription for capability consultation; it **applies** the sourcing rule rather than restating it, and it **references** the skill roster rather than copying it.

> **Provenance — extend-vs-build determination (CIAC-4).** This is a **net-new** artifact rather than an extension of an existing one, because in-place extension is infeasible on every candidate host: the observational [anthropic-base-vs-build-registry.md](anthropic-base-vs-build-registry.md) forbids prescriptive verbs by its own §Observational discipline, so a prescriptive "consult skill Y for need X" map cannot live there without breaking the registry's charter; the skill CMDB [registry.md](../skills/registry.md) is keyed one row per *skill* (descriptive configuration management), whereas this map is keyed one row per *capability dimension* (prescriptive, many skills per row); and [framework-catalog.md](framework-catalog.md) catalogs frameworks / methodologies / standards under a version-anchor schema, not a skill-routing table. A prescriptive capability→skill map has no conformant host, so it is authored net-new and *registered* (not hosted) as a framework-catalog row.

## §Purpose

At run time a module's work touches supporting capabilities beyond its primary task — a release plan may need an architecture read, a blast-radius assessment, a triage judgment, a production-readiness review, or a risk framing. This map is the forcing surface that turns "which capability does this work need, and what covers it?" into a lookup: name the dimension, resolve the **in-house** skill(s) that cover it, and pull in the governance that dimension answers to.

The map is **prescriptive** (it tells a run *what to consult*), which is precisely what its source artifacts are not:

- The **rule** it applies — in-house-first, with a guarded Anthropic-backup exception only where no in-house cover exists — is decided once in [ADR-023](../ADRs/ADR-023-skill-sourcing-coupling-posture.md) (own-with-harvested-learnings default; runtime Anthropic dependency permitted only under the guarded-exception test). This map **cites** ADR-023 and does not restate the rule (single-source discipline).
- The **in-house roster** it routes into is the skill CMDB [registry.md](../skills/registry.md). This map **references** the CMDB for skill identities and does not copy its rows.
- The **Anthropic-overlap posture** (whether a dimension even has an Anthropic counterpart to back up to) is the observational [anthropic-base-vs-build-registry.md](anthropic-base-vs-build-registry.md). This map **reads** that ledger for posture and does not copy it — and never pushes prescription back into it.

## Consultation map (seed dimensions)

Every named skill is verified present in the live `{core,release,operations}/skills/` roster. The **Anthropic-backup column is empty for every dimension below** — each has in-house cover — so the column exists structurally for the extension case, not for the current set. This directly closes the over-listing risk of naming an Anthropic backup where thin-but-real in-house cover already exists: systems / integration design, historically the thinnest cover, is covered in-house by `pmo-architect`. *(The count of dimensions is deliberately not stated in prose — the table below is the count, and a stated number goes stale the moment a dimension is added.)*

| Capability dimension | In-house support (consult FIRST) | Anthropic-backup (only when NO in-house cover — ADR-023 guarded exception) | Relevant governance |
|---|---|---|---|
| **Architecture** — structure, NFRs, design decisions | `pmo-architect` (System-Design — at enterprise or system altitude, and for the data domain; Security-Architecture when the question is the security properties of the design), `pmo-principal-engineer` (within-component depth), `pmo-technical-analyst` (Architecture assessment) | — none *(in-house cover exists)* | ADR-023 (precedence); [ADR-019](../ADRs/ADR-019-specialists-compose-not-absorb.md) (compose-not-absorb); [ADR-121](../ADRs/ADR-121-domain-is-a-parameter-of-the-architect-role.md) (domain and altitude are parameters of the architect role); [architecture-overview.md](../disciplines/architecture-overview.md) |
| **Systems / integration design** — cross-component, middleware, data, blast-radius | `pmo-architect` (Integration-Review), `pmo-technical-analyst` (Integration risk) | — none *(in-house cover exists — reconciles the historical "thinnest cover" premise)* | ADR-023; [blast-radius-protocol.md](../../release/references/protocols/blast-radius-protocol.md) |
| **Security architecture** — threat modeling, trust-boundary decomposition, security-control selection, security-NFRs | `pmo-architect` (Security-Architecture — owns the design *decision*: where the boundaries fall, which controls the architecture owes, the residual risk), `pmo-technical-analyst` (Architecture assessment — the security *review* substrate the decision consumes; it renders no design decision) | — none *(in-house cover exists)* | ADR-023; [ADR-121](../ADRs/ADR-121-domain-is-a-parameter-of-the-architect-role.md) (security is a mode on the architect, not a separate Specialist — its method differs, its write-scope does not); [ADR-019](../ADRs/ADR-019-specialists-compose-not-absorb.md) (the decision composes the review, never re-implements it); [software.md](../standards/domain-best-practices/software.md) § Security (control-selection anchor; architecture-level threat modeling is `UNSOURCED-DOMAIN`) |
| **Security review (review-time)** — control efficacy on a surface that already exists, secret and dependency posture, security-enforcer coverage | `build-reviewer` invoked as `--pack=security` (owns the review-time pass over a **surface** — the controls, hooks, CI security jobs, dependency manifests and scanner config in the tree — and grades whether each control does its job on the branch where it *cannot*), `pmo-technical-analyst` (**Mode C** — Architecture / Infrastructure Review, which carries security posture among its standard architecture concerns and reviews an **artifact** rather than a surface) | — none *(in-house cover exists)* | ADR-023; [review-discipline-principles.md](../disciplines/review-discipline-principles.md) (the shared review discipline every pack answers to); [software.md](../standards/domain-best-practices/software.md) § Security (the codified control-hygiene concepts the pack's Area A operationalizes, one review dimension per concept). **Seam vs Mode C — the cut is the object, not the moment:** both are review-time and their security vocabulary overlaps, so the discriminator is what is handed to the reviewer. A **document** (FDD, integration spec, architecture or infrastructure doc) routes to Mode C, which asks whether the design it describes is sound; a **tree** routes to the pack, which asks whether the shipped enforcers hold. Needing both is a two-pass, two-verdict run — the pack never grades a design, and Mode C never grades an enforcer's fail-branch. Design-time control *selection* is neither of these: it is the **Security architecture** row above |
| **Data engineering** — ingestion / ETL pipelines, data quality, transformation, analytics enablement | `pmo-data-engineer` (Pipeline-Build, Data-Quality, Analytics-Enablement — owns the hands-on *build* and the standing correctness assertions), `pmo-technical-analyst` (Integration risk — the upstream-source read the build consumes) | — none *(in-house cover exists)* | ADR-023; [ADR-019](../ADRs/ADR-019-specialists-compose-not-absorb.md) (the build composes the review and the planner, never re-implements them); [ADR-044](../ADRs/ADR-044-skill-output-ownership-model.md) (a data-quality breach routes through an existing `Finding` Creator — the engineer declares no findings register). No data-engineering practice guide exists in `domain-best-practices/`, so the method is `UNSOURCED-DOMAIN` — strictly less sourced than security architecture, which at least has a control-selection anchor |
| **Triage** — intake readiness, duplicate / subsumption, dependency-state | `pipeline-triage` (Stage-2), `intake-desk` (front door), `ppm-agent` (triage) | — none *(in-house cover exists)* | ADR-023; [stage-02-triage.md](../../release/references/pipeline/stage-02-triage.md) |
| **Production-readiness review** — findings register, QA, acceptance | `build-reviewer`, `pmo-qa-auditor`, `pmo-qa-lead` | — none *(in-house cover exists)* | ADR-023; [review-discipline-principles.md](../disciplines/review-discipline-principles.md) |
| **Risk** — RAID, reversibility, failure modes | `pmo-technical-analyst` (Integration risk), `delivery-engine` (RAID), `ppm-agent` (risk assessment) | — none *(in-house cover exists)* | ADR-023; [reversibility-protocol.md](reversibility-protocol.md); [failure-mode-standard.md](../standards/failure-mode-standard.md) |

## §How this map relates to the registries

This map is one prescriptive layer sitting on top of two observational / descriptive sources and one decided rule. The three stay in their own lanes:

| Concern | Owned by | This map's relationship |
|---|---|---|
| **The rule** — in-house-first; guarded Anthropic-backup exception | [ADR-023](../ADRs/ADR-023-skill-sourcing-coupling-posture.md) | **Cites** it for the precedence; restates nothing. |
| **The in-house roster** — skill identities, kinds, trigger surfaces, modes | skill CMDB [registry.md](../skills/registry.md) | **References** it for who covers a dimension; copies no rows. Roster changes flow from the CMDB, not from edits here. |
| **The Anthropic-overlap posture** — whether a dimension has an Anthropic counterpart at all | [anthropic-base-vs-build-registry.md](anthropic-base-vs-build-registry.md) | **Reads** it to decide whether a backup even exists; copies no rows; never writes prescription back into it. |

The map stays thin by construction: it holds the dimension→skill *routing* and the governance pointer, and defers the rule, the roster, and the overlap posture to their single sources.

## §Extension rule (the seed set is open)

The dimensions above are not a closed set — they are the dimensions a run commonly touches, and the table is their only count. To add a dimension:

1. **Name the capability** — a support need a module's run may touch, stated as a dimension (not a task).
2. **Resolve in-house support FIRST** from the CMDB routing / trigger surface ([registry.md](../skills/registry.md)). If any in-house skill covers the dimension, the Anthropic-backup cell stays empty.
3. **Name an Anthropic-backup ONLY when the dimension has genuinely no in-house cover**, and only after the **ADR-023 three-condition guarded-exception test** passes (commodity-stable contract × low blast-radius × drift-canary-guarded — see [ADR-023](../ADRs/ADR-023-skill-sourcing-coupling-posture.md) §Decision; do not restate the test here). Draw the concrete Anthropic skill from the base-vs-build registry's Hybrid-baseline catalog.
4. **Cite the governance** the dimension answers to (the standard / protocol / discipline that governs how the dimension's work is judged).
5. **Never add prescriptive content** (`recommend` / `should` / `migrate`) to [anthropic-base-vs-build-registry.md](anthropic-base-vs-build-registry.md) — its §Observational discipline forbids it, and ADR-023 keeps that registry the *ledger*, not the rule. All prescription lives here.

## §Module-agnostic scope

The dimensions in this map are capability needs *any module's run* may have — they are not release-specific. **Release is the first wired consumer**: `release/governance/release-process.md` § Capability-Consultation Self-Check fires the consultation once per run at Stage 4 Planning and records the result on the release plan. Another module wiring in a self-check step consults the same map without a release-specific fork; new dimensions its runs touch extend the table under the rule above.
