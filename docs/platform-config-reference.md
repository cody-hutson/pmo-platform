# Platform Config Reference — pmo-platform

> Human-readable catalog of every platform configuration field: what it does, what values it takes, its default, and where to set it. This is a **derived navigation surface** — the canonical schema is [`core/schemas/platform-config-schema.md`](../core/schemas/platform-config-schema.md). On any field change, update the schema first; this catalog follows.

<!-- platform-config-reference.md is a derived catalog. Canonical detail: core/schemas/platform-config-schema.md + the field comments in core/config/platform-config.toml.template + core/config/operator.toml.template. -->

## 1. About this document

- **Audience:** Operators tuning platform behavior; anyone asking "what config knobs does the platform have, and where do I set them?"
- **Two surfaces, one resolver.** Platform configuration lives in two files split by concern (per [ADR-021](../core/ADRs/ADR-021-platform-config-vs-operator-toml-split.md)):
  - **`operator.toml`** — operator-ENVIRONMENT / IDENTITY: identity, paths, host-adapter selectors, methodology default. Security-sensitive (`chmod 600`).
  - **`platform-config.toml`** — platform-BEHAVIOR: bundling frame, release-size target, release-class default, relationship-mapping tuning. Freely tunable; no PII.
- **How a value is resolved.** Both surfaces feed one **5-rung resolver** (global default → portfolio → program → project → individual; most-specific wins). The full resolver, the 3-level fallback, and the two-track update governance are in [`core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`](../core/governance/OPERATIONS.md).
- **Two ways to change config:**
  - **Track A (default / schema change):** edit a Layer-1 default or the schema → a governed PR (this is a governance file).
  - **Track B (set your own value):** set a value for your own portfolio / program / project / individual scope → an operator-instance write, no PR (like setting `delivery_approach: Kanban` in PROJECT.md).

## 2. Where to set a value (the 5 rungs)

| Rung (lowest → highest precedence) | Surface | Scope |
|---|---|---|
| 1 — global default | `core/config/platform-config.toml.template` + `core/config/operator.toml.template` (Layer 1, ships) | all installs |
| 2 — portfolio | `projects/_config/PORTFOLIO.md` frontmatter `platform_config: {...}` | a portfolio |
| 3 — program | `projects/<Program>/_config/program-config.toml` | a program |
| 4 — project | `projects/<Project>/PROJECT.md` frontmatter `platform_config: {...}` | a project |
| 5 — individual | `~/.config/pmo-platform/platform-config.toml` `[overrides]` (and `operator.toml` for identity/adapters) | one operator (highest precedence) |

A field set at a higher rung overrides the same field set at a lower rung. A field set nowhere falls back to the global default; a field absent even there falls back to the consuming surface's documented hardcoded default (logged).

## 3. operator.toml fields (environment / identity)

> Canonical: the field comments in [`core/config/operator.toml.template`](../core/config/operator.toml.template).

### `[adapters]` — host-adapter selectors (the onboarding seam)

| Field | What it selects | Allowed values | Default |
|---|---|---|---|
| `repo_host` | repository host (git surface + code review) | `github` (GitHub via `gh`) | `github` |
| `ticketing` | work-tracking surface (issues / milestones / board) | `github` (GitHub issues + Projects) · `jira+github` · `gitlab+jira` | `github` |
| `kb` | knowledge-base / documentation surface | `markdown` (generic Markdown KB) | `markdown` |
| `ai_tool` | agent runtime the skills + hub run on | `claude-code` (Claude Code CLI/Desktop) | `claude-code` |

These four are the seam onboarding writes operator choices into. Finer-grained per-project relationship tuning lives in `platform-config.toml [relationship_mapping]` (below) and composes with — does not replace — these install-level selectors.

### `[methodology]` — methodology default

| Field | What it sets | Allowed values | Default |
|---|---|---|---|
| `default_delivery_approach` | the methodology a project starts from when it sets no `delivery_approach` of its own | the 8 archetypes: `Scrum` · `Kanban` · `XP` · `Waterfall` · `PRINCE2` · `SAFe` · `Hybrid` · `Custom` | `Scrum` |

This is only the global default + resolver fallback. The enum, validation, and Custom block are canonical in [`core/schemas/project-schema.md`](../core/schemas/project-schema.md) and [`release/references/specs/methodology-parameterization-v1.md`](../release/references/specs/methodology-parameterization-v1.md). A project's own `delivery_approach` overrides this.

### `[platform]` — legacy adapter selectors (deprecated alias)

| Field | Status | Notes |
|---|---|---|
| `work_board` | **DEPRECATED ALIAS** | Superseded by `[adapters].ticketing`. Kept (not removed) because `deploy.sh`/hooks read it. New consumers should read `[adapters].ticketing`. |
| `comms_platform` | active | Team-comms surface comms-writer defaults to. Values: `""` (none) · `slack` · `teams` · `email`. Default `""`. |

## 4. platform-config.toml fields (platform behavior)

> Canonical: [`core/schemas/platform-config-schema.md`](../core/schemas/platform-config-schema.md) + the field comments in [`core/config/platform-config.toml.template`](../core/config/platform-config.toml.template).

### `[bundling]`

| Field | What it tunes | Allowed values | Default | Calibration |
|---|---|---|---|---|
| `bundle_doctrine_frame` | the bundle-composition frame release-planner applies | frame ids per [`bundle-composition-doctrine.md § 1`](../release/references/standards/bundle-composition-doctrine.md): `F1` (SAFe Feature-Slicing + Vertical Slice) + surveyed alternatives | `F1` | — |
| `release_size_target_pts` | the story-points band the bundle size-check evaluates against | a `"low-high"` range string | `15-25` | CALIBRATE-AFTER-3 |

### `[release_class]`

| Field | What it tunes | Allowed values | Default |
|---|---|---|---|
| `default_release_class` | the class applied when a milestone has no explicit `## Release Class` H2 | the CLOSED 4-value enum per [`release-class-taxonomy.md`](../release/references/specs/release-class-taxonomy.md): `routine` · `novel` · `cross-cutting` · `hotfix` | `novel` |

### `[relationship_mapping]`

| Field | What it tunes | Allowed values | Default |
|---|---|---|---|
| `source_systems` | which external system(s) are active relationship sources | comma-separated system ids (per the active `[adapters]` selectors) | `github` |
| `maintenance_posture` | relationship round-trip posture | `read-only` · `one-way-push` · `two-way-round-trip` | `read-only` |
| `type_mapping_overrides` | canonical→native relationship-type deviations | a TOML table; `{}` = none | `{}` |

### `[calibration]`

| Field | What it tracks | Allowed values | Default |
|---|---|---|---|
| `releases_since_calibration` | releases accrued toward a CALIBRATE-AFTER-3 re-calibration | non-negative integer | `0` |

## 5. Consumer examples (how the platform reads these)

Three wired examples ship with the adapter-config-foundation release:

1. **`bundle_doctrine_frame` → release-planner.** release-planner Mode A resolves `bundle_doctrine_frame` at session start and anchors bundle-composition to that frame; Mode B persists the resolved frame into the release plan's `## Summary`.
2. **`default_release_class` → release hub.** The hub resolves `default_release_class` as the fallback when a milestone description carries no `## Release Class` H2.
3. **`default_delivery_approach` → methodology fallback.** A project with no `delivery_approach` set resolves to the global `default_delivery_approach` (instead of the old implicit "sprint-centric Agile" default).

## 6. See also

- [`core/schemas/platform-config-schema.md`](../core/schemas/platform-config-schema.md) — canonical field schema (type / allowed-values / default / calibration / consuming-surface / cutover-SHA).
- [`core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`](../core/governance/OPERATIONS.md) — the 5-rung resolver, fallback, and Track A/B governance.
- [`core/ADRs/ADR-021-platform-config-vs-operator-toml-split.md`](../core/ADRs/ADR-021-platform-config-vs-operator-toml-split.md) — the operator.toml vs platform-config.toml split decision.
- [`core/config/operator.toml.template`](../core/config/operator.toml.template) · [`core/config/platform-config.toml.template`](../core/config/platform-config.toml.template) — the two surfaces themselves.
