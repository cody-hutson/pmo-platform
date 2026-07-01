# operations/templates/ — Canonical Templates Registry

**Purpose:** Canonical home for stakeholder-facing template files (typed-format specifications — column headers, section structure, placeholder semantics) used across the PMO platform.
**Organization:** One file per template; the registry table below groups by domain (Project-domain PMBOK-7-anchored / Platform-internal). Canonical → mirror propagation is `deploy.sh` `TEMPLATE_SYNC_MAP`.
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
| `project-charter-template.md` | Initiating | PMBOK 7 |
| `communications-tracker-template.md` | Stakeholder | PMBOK 7 |
| `open-meetings-tracker-template.md` | Stakeholder | PMBOK 7 |
| `stakeholder-register-template.csv` | Stakeholder | PMBOK 7 |
| `raci-template.md` | Stakeholder | PMBOK 7 (RAEW / RAS variants referenced) |
| `key-terms-glossary-template.csv` | Stakeholder | PMBOK 7 |
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

### Platform-internal (operational instance, not stakeholder-facing)

| Template | Purpose |
|---|---|
| `PMO_Platform_Template.md` | Knowledge-transfer reference for the PMO platform itself |

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
| `plan-templates/comms.md` | Plan — `plan_type: comms` | §3.4a / ADR-059 |
| `plan-templates/training.md` | Plan — `plan_type: training` (terminal `delivered`) | §3.4a / ADR-059 |
| `plan-templates/hypercare.md` | Plan — `plan_type: hypercare` (terminal `closed`) | §3.4a / ADR-059 |
| `plan-templates/cutover.md` | Plan — `plan_type: cutover` (terminal `executed`) | §3.4a / ADR-059 |
| `plan-templates/change-management.md` | Plan — `plan_type: change-management` (the OCM umbrella) | §3.4a / ADR-059 |
| `plan-templates/raid.md` | Plan — `plan_type: raid` (the RAID **Log**; ≠ RAID-Item §3.6) | §3.4a / ADR-059 |

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

See [`../standards/template-storage.md` §6 Sync-Map Registration Protocol](../../core/standards/template-storage.md). Summary: (1) place file in this folder, (2) add `TEMPLATE_SYNC_MAP` entry to `deploy.sh`, (3) document in `template-storage.md` §7, (4) `./deploy.sh --deploy <skill>` for initial sync, (5) `./deploy.sh --check` to confirm Check 13 passes, (6) commit canonical + deploy.sh + storage doc together.
