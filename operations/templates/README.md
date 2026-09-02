# operations/templates/ — Canonical Templates Registry

**Purpose:** Canonical home for stakeholder-facing template files (typed-format specifications — column headers, section structure, placeholder semantics) used across the PMO platform.
**Organization:** One file per template; the registry table below groups by domain (Project-domain PMBOK-7-anchored / Software-domain canon-anchored / Platform-internal / Project-data architecture). Canonical → mirror propagation is `deploy.sh` `TEMPLATE_SYNC_MAP`.
**Governance:** [core/governance/OPERATIONS.md](../../core/governance/OPERATIONS.md) § README-Per-Folder Convention; template-storage protocol in [core/standards/template-storage.md](../../core/standards/template-storage.md).
**Layer:** 1 (Engineering, git-tracked)

This folder is the canonical home for stakeholder-facing template files used across the PMO platform. Each file is a typed-format specification (column headers, section structure, placeholder semantics) — not entity instance data. For the Schema/Storage/Presentation distinction and the boundary with Project Data Architecture, see [`../standards/template-storage.md` §5](../../core/standards/template-storage.md).

The per-folder-README convention is now shipped — see [core/governance/OPERATIONS.md](../../core/governance/OPERATIONS.md) § README-Per-Folder Convention (and the sibling § File Format Conventions). This file follows that convention as an **index-style** README: the 4-line header above plus the registered-template registry below for at-a-glance discovery.

## Authoritative References

- [`../standards/template-taxonomy.md` §6](../../core/standards/template-taxonomy.md) — canon-per-artifact-family mapping (which external best-practice convention each template anchors to)
- [`../standards/template-storage.md` §7](../../core/standards/template-storage.md) — registered mirrors (which skill consumes which canonical file via deploy-sync)
- [`../standards/operational-artifact-template-standard.md`](../../core/standards/operational-artifact-template-standard.md) — PDA-side template contract overlay: entity-derivation rule + machine-schema-companion convention + FINDING-3 known-exception path
- `TEMPLATE_SYNC_MAP` in [`core/deploy/deploy.sh`](../../core/deploy/deploy.sh) — authoritative source of canonical → mirror propagation entries

## Registered Templates

### Project-domain (PMBOK 7 Performance Domain anchored)

| Template | Performance Domain | Canon source |
|---|---|---|
| `project-charter-template.md` | Planning | PMBOK 7 |
| `communications-tracker-template.md` | Stakeholder | PMBOK 7 |
| `open-meetings-tracker-template.md` | Stakeholder | PMBOK 7 |
| `stakeholder-register-template.csv` | Stakeholder | PMBOK 7 |
| `raci-template.md` | Stakeholder | PMBOK 7 (RAEW / RAS variants referenced) |
| `key-terms-glossary-template.csv` | Stakeholder | PMBOK 7 |
| `change-impact-matrix-template.md` | Stakeholder | PMBOK 7 |
| `training-plan-template.md` | Stakeholder | PMBOK 7 |
| `people-graph-clarification-queue-template.md` | Stakeholder | PMBOK 7 (de-identified queue of unresolved person-graph candidates; the filled queue is operator-instance and out-of-tree) |
| `change-log-template.md` | Project Work | PMBOK 7 (Waterfall change-control log) |
| `lessons-learned-template.md` | Project Work | PMBOK 7 (PRINCE2 lessons log) |
| `daily-status-log-template.md` | Measurement | PMBOK 7 |
| `daily-status-update-framework-template.md` | Measurement | PMBOK 7 |
| `executive-status-report-prompt-template.md` | Measurement | PMBOK 7 |
| `milestone-tracker-template.md` | Planning | PMBOK 7 |
| `raid-log-template.csv` | Uncertainty | PMBOK 7 |
| `transcript-register-template.md` | Project Work | PMBOK 7 |
| `artifact-register-template.md` | Project Work | PMBOK 7 (PRINCE2 configuration management — per-project artifact CI catalog) |
| `dual-framing-bridge-template.md` | Development Approach + Lifecycle | PMBOK 7 (hybrid Agile↔Waterfall) |
| `sprint-tracker-template.md` | Delivery | PMBOK 7 (Agile track) |
| `project-md-template.md` (promoted from skill via D-CanonicalPromote) | Project Work | PMBOK 7 (PROJECT.md scaffolding) |
| `requirements-template.md` (promoted from skill via D-CanonicalPromote) | Planning | PMBOK 7 (requirements decomposition) |

### Software-domain (engineering best-practice canon anchored)

Canon-per-family binding per [`../standards/template-taxonomy.md` §6](../../core/standards/template-taxonomy.md) rows 1–6 + rows 9 and 12. Canonical-only — no `TEMPLATE_SYNC_MAP` mirrors registered; sync-map registration follows the first consumer skill with a runtime read-path per [`../standards/template-storage.md` §3.1](../../core/standards/template-storage.md).

The **Artifact family** column below is a *discovery annotation*, not the typed binding. Several cells carry the form `<family> (<annotation>)` — the parenthetical is reader guidance and is not part of the value. The load-bearing, enum-bound `template_family` value is the one in each template's own provenance header, sourced from [`../standards/template-taxonomy.md` §3–§5](../../core/standards/template-taxonomy.md) per [`../standards/template-protocol.md` §4.2](../../core/standards/template-protocol.md). Where the two differ in spelling, the header is authoritative.

| Template | Artifact family | Canon source |
|---|---|---|
| `adr-template.md` | ADR (Architecture Decision Record) | Nygard, "Documenting Architecture Decisions" (2011) |
| `runbook-template.md` | Runbook | Google SRE Workbook §Runbook Design |
| `design-doc-template.md` | Design doc (FDD / TDD / HLD / LLD variants) | Google design-doc convention |
| `rfc-template.md` | RFC (Specification / Protocol) | IETF RFC 7322 + Rust RFC template |
| `prd-template.md` | PRD / Feature spec | Anthropic `product-management:write-spec` plugin convention (secondary: Aha! / Lenny Rachitsky) |
| `postmortem-template.md` | Postmortem | Google SRE Workbook §Postmortem Culture |
| `test-plan-template.md` | Test plan / Test case | PMBOK 7 §Quality + `engineering:testing-strategy` plugin convention |
| `qa-acceptance-report-template.md` | Acceptance report / Stage verdict report | PMBOK 7 §Quality + ISO/IEC/IEEE 29119-3 §Test Completion Report |

### Platform-internal (skill-embedded — deliberately not registered here)

**This section carries no rows, by construction.** Platform-internal templates are skill-runtime authoring guidance rather than stakeholder-facing artifacts; per [`../standards/template-taxonomy.md` §2 and §5](../../core/standards/template-taxonomy.md) they remain inside their owning skill's `references/` directory and are **not promoted to this canonical registry**. Taxonomy §5 enumerates them, with the owning skill and the reason each is platform-internal.

The group is retained here so a reader scanning the four domains sees where the fourth one lives instead of concluding it was omitted. A template registered in this folder is `project`, `software`, or project-data architecture — never platform-internal.

### Project-data architecture (shared-entity SSOT + typed plans + composed index, v3.37)

The entity-page and typed-plan templates from the project-data-architecture initiative. Entity pages carry the frozen `entity-field-schemas.md` field schemas (§3.x); the `_pmo/` entity pages are the cross-project SSOT (ADR-058); plans carry the OPEN `plan_type` discriminator (ADR-059); PROJECT.md is the composed wiki-link index (ADR-060).

| Template | Kind | Schema / ADR |
|---|---|---|
| `project-md-composed-index-template.md` | Composed-index PROJECT.md (≤50 lines; Methodology/Status inline, entities as `[[wiki-links]]`) | ADR-060 / project-schema.md §7 |
| `person-entity-template.md` | `_pmo/people/` Person entity (SSOT on `person_id`) | §3.10 / §6.2 / ADR-058 |
| `system-entity-template.md` | `_pmo/systems/` System entity | §3.11 / ADR-058 |
| `vendor-entity-template.md` | `_pmo/vendors/` Vendor entity | §3.12 / ADR-058 |
| `workstream-entity-template.md` | `_pmo/workstreams/` Workstream entity | §3.3 / ADR-058 |
| `decision-entity-template.md` | `_pmo/decisions/` Decision entity | §3.5 / ADR-058 |
| `dependency-entity-template.md` | `_pmo/dependencies/` Cross-Project Dependency (`storage_tier: portfolio-level` view) | §3.15 / §6.3 / ADR-058 |
| `project-rollup-template.md` | `[Project]/` **composed** per-project portfolio rollup (`entity_type: Project Rollup (composed)`; 7-field write-back contract; reads 6 source entities, owns none — NOT a roster entity) | portfolio-writeback-contract.md / ADR-019 |
| `plan-templates/comms.md` | Plan — `plan_type: comms` | §3.4a / ADR-059 |
| `plan-templates/training.md` | Plan — `plan_type: training` (terminal `delivered`) | §3.4a / ADR-059 |
| `plan-templates/hypercare.md` | Plan — `plan_type: hypercare` (terminal `closed`) | §3.4a / ADR-059 |
| `plan-templates/cutover.md` | Plan — `plan_type: cutover` (terminal `executed`) | §3.4a / ADR-059 |
| `plan-templates/change-management.md` | Plan — `plan_type: change-management` (the OCM umbrella) | §3.4a / ADR-059 |
| `plan-templates/raid.md` | Plan — `plan_type: raid` (the RAID **Log**; ≠ RAID-Item §3.6) | §3.4a / ADR-059 |

### Portfolio-framework (framework-keyed subtree — selected, not neutral-core)

Framework-specific portfolio- and program-tier artifact shapes, selected by `operator.toml [methodology].portfolio_framework` and keyed by `framework_id` in the path (per [ADR-170](../../core/ADRs/ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md)). **These are framework-selected delta content, not neutral-core registry entries** — a shape here ships only to a deployment that selected its framework, which is what keeps the unselected registry root methodology-neutral. Framework-invariant content stays at the root (ADR-170 D4 thin delta). Canon-per-family binding per [`../standards/template-taxonomy.md` §3A and §6](../../core/standards/template-taxonomy.md) rows 13–14. Canonical-only — no `TEMPLATE_SYNC_MAP` mirrors registered; sync-map registration follows the first consumer skill with a runtime read-path per [`../standards/template-storage.md` §3.1](../../core/standards/template-storage.md).

Consumer branch: [`methodology-parameterization-v1.md` §5B](../../release/references/specs/methodology-parameterization-v1.md). A deployment that selects no framework reads none of these files.

| Template | Artifact family | Tier | Canon source |
|---|---|---|---|
| `portfolio-frameworks/pmi/portfolio-charter-template.md` | Portfolio Charter | portfolio | The Standard for Portfolio Management (PMI) |
| `portfolio-frameworks/pmi/strategic-alignment-matrix-template.md` | Strategic Alignment Matrix | portfolio | The Standard for Portfolio Management (PMI) |
| `portfolio-frameworks/pmi/portfolio-roadmap-template.md` | Portfolio Roadmap | portfolio | The Standard for Portfolio Management (PMI) |
| `portfolio-frameworks/pmi/risk-profile-template.md` | Portfolio Risk Profile | portfolio | The Standard for Portfolio Management (PMI) |
| `portfolio-frameworks/pmi/program-charter-template.md` | Program Charter | program | The Standard for Program Management (PMI) |
| `portfolio-frameworks/pmi/benefits-realization-template.md` | Benefits Realization Plan | program | The Standard for Program Management (PMI) |
| `portfolio-frameworks/pmi/program-md-template.md` | PROGRAM.md scaffolding | program | The Standard for Program Management (PMI) |

## Related Canonical Output-Format Specs (cited, not mirrored)

These are **output-format specifications** for finished communications — not fill-in
templates — so they live in `core/standards/`, not this folder, and consumers cite them
**by path** (no `TEMPLATE_SYNC_MAP` mirror row). Registered here for discovery so the
canonical home of each meeting-format spec is findable from the templates registry.

| Spec | Canonical home | Defines |
|---|---|---|
| Meeting agenda output format | [`core/standards/meeting-agenda-format.md`](../../core/standards/meeting-agenda-format.md) | The six required agenda elements + formality-calibration rule. Consumed by comms-writer (Meeting agenda type), comms-writer's `references/channel-formats.md`, and tracker-manager's Open Meetings Tracker `MTG-###` `Agenda` field. |
| Meeting recap output format | [`core/standards/meeting-recap-format.md`](../../core/standards/meeting-recap-format.md) | The `[RECAP]` subject convention + Decisions → Action Items → Notes → Key Roadblocks body order + timeliness/distribution rules. Consumed by comms-writer (Meeting recap type) and `references/channel-formats.md`. |

## Adding a New Template

See [`../standards/template-storage.md` §6 Sync-Map Registration Protocol](../../core/standards/template-storage.md). **Two placements** — pick by whether the template ships to everyone or only to a deployment that selected it.

**Flat (default).** A neutral-core template every deployment receives. (1) place the file in this folder; (2) add a `TEMPLATE_SYNC_MAP` entry to `deploy.sh`; (3) document it in [`template-storage.md` §7](../../core/standards/template-storage.md); (4) `./deploy.sh --deploy <skill>` for initial sync; (5) `./deploy.sh --check` to confirm Check 13 passes; (6) commit canonical + `deploy.sh` + storage doc together.

**Keyed subdirectory.** A template selected by a config key rather than shipped to everyone — `portfolio-frameworks/<framework_id>/`, `plan-templates/`, `project-bins/<bin>/`. (1) place the file under its key directory, named per [`template-storage.md` §2.2](../../core/standards/template-storage.md) `<artifact-family>-template.<ext>`; (2) register its family in [`template-taxonomy.md`](../../core/standards/template-taxonomy.md) and add a §6 canon row where §2.1 F4 applies; (3) add a row to the matching section above; (4) **defer** `TEMPLATE_SYNC_MAP` registration until a consumer skill declares a runtime read-path — registering a mirror with no consumer creates drift surface with no reader, per [`template-storage.md` §3.1](../../core/standards/template-storage.md); (5) when that consumer arrives, register field 2 as the **repo-relative subpath**, per §6 step 2 and the §7.4 subpath-keyed precedent; (6) `./deploy.sh --check` to confirm Check 13 reports no new finding.

The branch point is **selection, not location**: a template under a key directory that every deployment nonetheless receives belongs on the flat path, and a flat-root template gated by a config key is misplaced rather than merely unregistered.
