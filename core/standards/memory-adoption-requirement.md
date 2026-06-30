---
title: Memory-Adoption Requirement — the skill-corpus adoption audit + the future-skill rule
purpose: The record of which skills adopt the unified cross-surface memory contract today (the per-skill adoption audit), and the forward-only requirement that future skills cite the contract and name a surface's read/write class + SSOT before touching it. Distinct from the contract itself — this standard measures skills against the contract; it does not restate the per-surface table.
type: reference
tier: K1
reversibility: CHEAP / Confidence HIGH
consumers: "core/disciplines/memory-architecture.md (the contract this standard audits adoption of); operations/skills/daily-status/SKILL.md (the pilot exemplar — first skill to route a read AND a write through the contract); pmo-skill-editor / pmo-skill-refiner (the editors that apply the §3 requirement on a materially-edited or new skill)"
owner: "operator-class: Workspace owner ([OPERATOR_NAME]) — per km-governance-framework §2.4 (forward-only)"
glossary_anchor: "core/disciplines/memory-architecture.md (the cross-surface contract); knowledge-architecture.md §2.1 (the four-memory-type axis the surface column draws on)"
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
<!-- repo-integrity: allow-issue-ref -->

# Memory-Adoption Requirement — the skill-corpus adoption audit + the future-skill rule

## §1 Purpose + position {#purpose}

This standard is the **record of which skills adopt the cross-surface memory contract, and the requirement on future skills**. It answers two questions the contract itself does not:

1. **Which skills read and/or write memory today, and do they route those reads/writes *through* the contract?** (the per-skill adoption audit — §2).
2. **What is required of a *new or materially-edited* skill that touches a memory surface?** (the forward-only adoption rule — §3).

It **composes with — and does not restate —** its neighbors:

- [`memory-architecture.md`](../disciplines/memory-architecture.md) is the cross-surface **contract** — *what each surface is, who reads/writes it, its read/write class + SSOT*. Its [§2 contract table](../disciplines/memory-architecture.md#contract-table) is the single home for the per-**surface** map. This standard cites that table; it never copies it.
- [`knowledge-architecture.md §2.1`](../disciplines/knowledge-architecture.md#four-type-reconciliation) defines the four-memory-type model (Work / Knowledge / People / Learning) that the surface column in §2 draws on.

The two tables are **orthogonal axes over different row-entities**: the contract's table is per-**surface** (one row per memory surface); this standard's audit is per-**skill** (one row per skill). Co-locating them would mix a surface-contract with a skill-audit and break single-home (no-shadow-SSOT, [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md) / [ADR-045](../ADRs/ADR-045-cross-surface-memory-contract.md)). They live in separate docs by design.

---

## §2 The adoption audit table {#audit-table}

This is **the deliverable**. Every tracked SKILL.md across `operations/skills/` (27), `core/skills/` (4), and `release/skills/` (13) — **44 skills** — is one row.

**Method.** Per-SKILL.md grep sweep — read-signal: a memory surface cited as an *input*; write-signal: a write/append/update verb against a memory surface plus a Document-Tier-2 / auto-write declaration — plus a targeted read of the high-signal skills.

**Column legend.**

| Column | Values | Meaning |
|---|---|---|
| **Reads-memory** | `ACTIVE` \| `STATIC` \| `—` | `ACTIVE` = consumes a memory surface as data · `STATIC` = cites a governance doc only · `—` = none |
| **Writes-memory** | `ACTIVE` \| `STATIC` \| `—` | `ACTIVE` = mutates a memory surface as data · `STATIC` = cites a governance doc only · `—` = none |
| **Surface(s) [memory-type]** | — | the concrete surface and its memory-type per `knowledge-architecture.md §2.1` (Work / Knowledge / People / Learning) |
| **Routes through contract** | `yes` \| `no` | does the SKILL.md cite [`memory-architecture.md`](../disciplines/memory-architecture.md) to resolve a surface's read/write class + SSOT before touching it? This is the **gap tracker** — the pilot flips to `yes`; all others are `no` at this standard's first ship (forward-only — §3) |

### operations/skills/ (27)

| Skill | Reads-memory | Writes-memory | Surface(s) [memory-type] | Routes through contract |
|---|---|---|---|---|
| **tracker-manager** | ACTIVE | ACTIVE | Operational trackers — RAID / Comms / Open-Meetings / Transcript-Register / carry-forward [Work]; the canonical tracker **writer** | no |
| **ppm-agent** | ACTIVE | ACTIVE (emits; tracker-manager persists) | PORTFOLIO.md, PROJECT.md, daily status, capacity band [Work]; *emits* tracker rows — tracker-manager writes the field | no |
| **daily-status** *(PILOT)* | ACTIVE | ACTIVE | **Reads:** PROJECT.md, Daily Status Log, Comms Tracker, transcripts, threshold registries, ambient run-logs [Work] · **Writes:** Daily Status Log append (Document-Tier-2 auto-write), 08-Generated output | **yes** |
| **weekly-status-rollup** | ACTIVE | ACTIVE | PORTFOLIO.md (read + health write-back), project status logs [Work] | no |
| **project-initiator** | ACTIVE | ACTIVE | PROJECT.md (create), PORTFOLIO.md (update), folder scaffold [Work] | no |
| **pmo-program-coordinator** | ACTIVE | ACTIVE (via composed tracker-manager) | trackers + daily-status cadence [Work] (composition skill) | no |
| **comms-writer** | ACTIVE | ACTIVE | Comms Tracker (writes the Ask / send-row), PROJECT.md Key People [Work] | no |
| **delivery-engine** | ACTIVE | ACTIVE | RAID Log, backlog / sprint trackers [Work] | no |
| **pmo-portfolio-manager** | ACTIVE | ACTIVE (via composed ppm-agent + rollup) | PORTFOLIO.md [Work] (composition skill) | no |
| **intake-desk** | ACTIVE | ACTIVE | work tracker (logs the work item) [Work] | no |
| **file-router** | ACTIVE | ACTIVE | routes / writes files to governed folders; transcript register [Work] | no |
| **artifact-generator** | ACTIVE | ACTIVE | 08-Generated staging (transient working surface — not a durable memory surface per contract §2.1 / §6) [—] | no |
| **artifact-lint** | ACTIVE | ACTIVE | reads the 08-Generated + promoted-folder artifact surface; writes a recommend-only lint report to 08-Generated (transient working surface — not a durable memory surface; Autonomy Tier 1, no auto-mutation) [—] | no |
| **change-management** | ACTIVE | ACTIVE | change trackers, readiness / adoption logs [Work] | no |
| **pmo-project-manager** | ACTIVE | ACTIVE (via composition) | PROJECT.md, RAID, status [Work] (composition skill) | no |
| **pmo-program-manager** | ACTIVE | ACTIVE (via composition) | program trackers, PORTFOLIO.md [Work] (composition skill) | no |
| **pmo-product-owner** | ACTIVE | ACTIVE (via composed delivery-engine) | backlog substrate [Work] (composition skill) | no |
| **pmo-scrum-master** | ACTIVE | STATIC | reads delivery-engine signals; team-process facilitation framing [Work] (composition skill) | no |
| **pmo-technical-analyst** | ACTIVE | STATIC | reads FDDs / specs (project artifacts) [Work]; outputs analysis, no tracker write | no |
| **pmo-process-designer** | ACTIVE | ACTIVE | requirements / traceability artifacts [Work] | no |
| **pmo-business-analyst** | — | — (via composition) | composes process-designer + delivery-engine; no direct memory surface | no |
| **pmo-knowledge-manager** | ACTIVE | ACTIVE (via composed artifact-gen + file-router) | knowledge assets → governed home [Work / Knowledge] (composition skill) | no |
| **pmo-ocm-lead** | STATIC | STATIC (via composed change-mgmt) | change-management lifecycle [Work] (composition skill) | no |
| **pmo-release-train-engineer** | STATIC | STATIC | PI / ART coordination; no direct memory surface | no |
| **pmo-technical-program-manager** | — | — | role-router persona; no direct memory surface | no |
| **pmo-tier-1-support** | STATIC | STATIC | support triage; no durable memory write | no |
| **pmo-tier-2-support** | STATIC | STATIC | support escalation; no durable memory write | no |

### core/skills/ (4)

| Skill | Reads-memory | Writes-memory | Surface(s) [memory-type] | Routes through contract |
|---|---|---|---|---|
| **pmo-qa-auditor** | ACTIVE | STATIC | reads skill outputs + corpus for audit [Knowledge] | no |
| **pmo-skill-router** | ACTIVE | — | reads `core/skills/registry.md` (routing surface) [Knowledge]; read-only router | no |
| **eval-writer** | STATIC | STATIC | cites corpus / standards [Knowledge]; authors eval suites, no memory write | no |
| **prompt-builder** | — | — | no memory surface (web-research + prompt authoring) | no |

### release/skills/ (13)

| Skill | Reads-memory | Writes-memory | Surface(s) [memory-type] | Routes through contract |
|---|---|---|---|---|
| **release-executor** | ACTIVE | ACTIVE | RELEASE_LOG, release plans, `.version` [Work / Knowledge] | no |
| **release-planner** | ACTIVE | — | reads backlog + RELEASE_LOG (read-only — never modifies governance) [Work] | no |
| **pmo-release-manager** | ACTIVE | ACTIVE (via composition) | RELEASE_LOG, release plans [Work] (composition skill) | no |
| **pmo-skill-editor** | ACTIVE | ACTIVE | SKILL.md + references (the **corpus writer** for skills) [Knowledge] | no |
| **pmo-skill-refiner** | ACTIVE | ACTIVE | SKILL.md (new-skill authoring) [Knowledge] | no |
| **pmo-skill-refiner-selftest-canary** | — | — | self-test fixture; no memory surface | no |
| **pmo-software-engineer** | STATIC | STATIC (via composition) | code / corpus; no direct durable memory write | no |
| **pmo-principal-engineer** | STATIC | STATIC | authors ADRs / design (Knowledge corpus) at Stage 5 [Knowledge] | no |
| **pmo-architect** | STATIC | STATIC | system ADRs [Knowledge] | no |
| **pmo-devops-sre** | STATIC | STATIC (via composed release-executor) | deploy / reliability [Work] (composition skill) | no |
| **pmo-qa-lead** | STATIC | STATIC | QA gates [Knowledge] | no |
| **build-reviewer** | ACTIVE | STATIC | reads doc packs for review [Knowledge]; outputs findings register, no memory write | no |
| **implementation-planner** | ACTIVE | STATIC | reads findings register [Work]; outputs RI records to 08-Generated | no |

### Audit roll-up (the load-bearing counts)

- **Reads memory ACTIVELY:** the large majority of skills — every Work-tier operations skill, the release-ops read paths, and the read-for-review skills. **Reads are active + mandatory across the corpus — confirmed.**
- **Writes memory ACTIVELY:** concentrated in the **tracker-owning + release-ops + corpus-editing** skills (tracker-manager, daily-status, comms-writer, delivery-engine, weekly-status-rollup, project-initiator, file-router, intake-desk, change-management, release-executor, pmo-skill-editor, pmo-skill-refiner, and their composition wrappers). A real write path exists for operational trackers (`class: auto-write`, Document Tier 2); writes to governance / Knowledge surfaces are `operator-write-only` (PR-gated) — STATIC citation, not a programmatic write.
- **Routes a read/write through the contract:** **`daily-status` only** at this standard's first ship — every other row is `no`. This is the exact gap this standard tracks: the corpus reads and writes memory, but those reads/writes are not yet routed *through* the contract (no skill consulting [`memory-architecture.md`](../disciplines/memory-architecture.md) to resolve a surface's read/write class + SSOT before touching it). The pilot closes it for one skill; broader adoption is forward-only (§3).
- **Completeness:** the table is the *full* 44-skill corpus (no sampling) — satisfying the "one row per skill" preferred form. The `08-Generated` staging surface that `artifact-generator` and `artifact-lint` touch is a **transient working surface, not a durable memory surface** (contract §2.1 reading note + §6), so their durable-memory routing is `no` and their surface column is marked `[—]`.

---

## §3 The adoption requirement for future skills {#requirement}

**The rule (forward-only, SHOULD).**

> A **new or materially-edited** skill that reads or writes a memory surface **SHOULD** cite [`core/disciplines/memory-architecture.md`](../disciplines/memory-architecture.md) and name the surface's read/write **class** (`read-only` / `auto-write` / `operator-write-only`) and its **SSOT owner** before touching it. The pilot — [`daily-status`](../../operations/skills/daily-status/SKILL.md) — is the reference exemplar (§4).

**Why SHOULD, not MUST, and why no enforcement gate (load-bearing).** This standard's first version documents the requirement as a **forward-only SHOULD** with the pilot as the worked example. A MUST requirement would retroactively put every existing read/write skill (the `routes through contract: no` rows in §2) out of compliance the moment it ships — opening a corpus-wide remediation backlog this standard's scope explicitly excludes (≥1 pilot only). The requirement therefore binds **going forward** (the next time a skill is created or materially edited), not retroactively, and it ships with **no `deploy.sh --check` enforcement gate**. Promotion to MUST plus an enforcement gate is the named follow-up (§5) — the operator elevates it when corpus-wide adoption is wanted.

**Scope of "materially-edited."** The SHOULD fires when a skill edit *adds or changes* a read or write of a memory surface — not on a cosmetic or unrelated edit to a skill that already touches a surface. A skill that already reads/writes a surface is not retroactively obligated to add the citation on an unrelated edit; the obligation attaches when the read/write surface itself is added or changed.

---

## §4 The pilot exemplar {#pilot}

[`daily-status`](../../operations/skills/daily-status/SKILL.md) is the first skill to route **both a read and a write** through the contract. Its two contract-aware insertions are the worked example for §3:

- **READ surface** — `## Inputs` names its input surfaces (Daily Status Log + Comms Tracker = `class: auto-write` Work-type trackers; PROJECT.md = `class: operator-write-only` Work-type, read-only here) and cites [`memory-architecture.md`](../disciplines/memory-architecture.md) for each surface's class + SSOT.
- **WRITE surface** — `## Post-Generation Actions` names its Daily Status Log append as `class: auto-write` (Document Tier 2, Autonomy Tier 2), authorized post-confirmation, writing only this skill's own surface and never mutating a higher-tier surface inline — citing the same contract.

The edit changes **zero behavior** — `daily-status` already read and wrote these surfaces; the change makes those reads/writes *contract-aware* (it names the class + SSOT and cites the contract). That is the shape the §3 requirement asks of future skills.

---

## §5 Enforcement posture {#enforcement}

**DEFERRED.** This standard ships **audit + SHOULD-requirement only**. A `deploy.sh --check` analog — a "skill-routes-memory-through-contract" detector, sibling to the deferred contract-side enforcement gate ([`memory-architecture.md §6`](../disciplines/memory-architecture.md#composition-boundaries)) — is a **follow-up improvement**, not part of this version. Posture matches the contract's own deferred-gate stance (warn-mode-initial when the gate eventually lands). Until then, the §3 requirement is honored by the editing skills (`pmo-skill-editor` / `pmo-skill-refiner`) and verified by review at the skill-edit surface, not by an automated gate.

---

## Provenance

<!-- repo-integrity: allow-issue-ref -->

> Issue numbers below are **traceability pointers, not load-bearing references** — repository re-versioning renumbers them. Each entry leads with a self-describing name so the reference survives the number; if a number no longer resolves, locate the work by its name. This block is the *only* place in this document where issue numbers appear; the body reads complete without them.

- **This standard** — the skill-corpus memory-adoption audit + the forward-only future-skill requirement. *Sliced from the cross-surface memory-architecture epic (#1071), child 5 — issue #1077.*
- **The contract it audits adoption of** — the unified cross-surface memory read/write SSOT contract. *Issue #1074 (`memory-architecture.md`).*
- **The type axis its surface column draws on** — the four-memory-type taxonomy at `knowledge-architecture.md §2.1`. *Issue #1073.*
- **The pilot exemplar** — `daily-status`, the first skill to route a read AND a write through the contract. *Adopted under this issue (#1077).*
- **Candidate future read/write surface** — cross-session learning look-back, a later adoption-expansion target (recorded as `routes through contract: no` future-work framing, not actioned here). *Relates #46.*
- **Broader epic** — the cohesive cross-surface memory-architecture epic and its cluster. *Epic #1071 + cluster #1073–#1077.*
