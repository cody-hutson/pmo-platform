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
| `communications-tracker-template.md` | Stakeholder | PMBOK 7 |
| `open-meetings-tracker-template.md` | Stakeholder | PMBOK 7 |
| `key-terms-glossary-template.csv` | Stakeholder | PMBOK 7 |
| `daily-status-log-template.md` | Measurement | PMBOK 7 |
| `daily-status-update-framework-template.md` | Measurement | PMBOK 7 |
| `executive-status-report-prompt-template.md` | Measurement | PMBOK 7 |
| `milestone-tracker-template.md` | Planning | PMBOK 7 |
| `raid-log-template.csv` | Uncertainty | PMBOK 7 |
| `transcript-register-template.md` | Project Work | PMBOK 7 |
| `spm-bridge-template.md` | Development Approach + Lifecycle | PMBOK 7 (hybrid Agile↔Waterfall) |
| `sprint-tracker-template.md` | Delivery | PMBOK 7 (Agile track) |
| `project-md-template.md` (promoted from skill via D-CanonicalPromote) | Project Work | PMBOK 7 (PROJECT.md scaffolding) |
| `requirements-template.md` (promoted from skill via D-CanonicalPromote) | Planning | PMBOK 7 (requirements decomposition) |

### Platform-internal (operational instance, not stakeholder-facing)

| Template | Purpose |
|---|---|
| `PMO_Platform_Template.md` | Knowledge-transfer reference for the PMO platform itself |

## Adding a New Template

See [`../standards/template-storage.md` §6 Sync-Map Registration Protocol](../../core/standards/template-storage.md). Summary: (1) place file in this folder, (2) add `TEMPLATE_SYNC_MAP` entry to `deploy.sh`, (3) document in `template-storage.md` §7, (4) `./deploy.sh --deploy <skill>` for initial sync, (5) `./deploy.sh --check` to confirm Check 13 passes, (6) commit canonical + deploy.sh + storage doc together.
