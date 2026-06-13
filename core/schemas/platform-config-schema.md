<!-- reference-durability: allow-link -->
# platform-config.toml Schema

**Status:** Canonical
**Owner:** `core/schemas/platform-config-schema.md`
**Introduced:** adapter-config-foundation
**Surface:** [`core/config/platform-config.toml.template`](../config/platform-config.toml.template) (Layer 1 — global defaults + this schema's fields)
**Consumers:** `release-planner` (Mode A), `release-executor` (Mode A), the release hub (Procedure 0), `core/deploy/deploy.sh` (`resolve_platform_config` rung-reader), `OPERATIONS.md § Platform-Config Resolution Protocol`
**Cross-references:**

- [`composition-surface-spec.md`](../standards/composition-surface-spec.md) — durability contract (managed-section / operator-additions fences, regeneration, tamper detection) the template carries
- [`core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`](../governance/OPERATIONS.md) — the 5-rung resolver, 3-level default-fallback, and Track A/B update governance
- [`core/ADRs/ADR-021-platform-config-vs-operator-toml-split.md`](../ADRs/ADR-021-platform-config-vs-operator-toml-split.md) — the operator.toml (environment/identity) vs platform-config.toml (behavior) split decision
- [`release/references/specs/release-class-taxonomy.md`](../../release/references/specs/release-class-taxonomy.md) — the CLOSED 4-value Release Class enum (referenced, not re-listed, by `[release_class].default_release_class`)
- [`release/references/specs/methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) + [`project-schema.md`](project-schema.md) — the 8-archetype methodology enum (the `default_delivery_approach` DEFAULT lives in `operator.toml [methodology]`, not here, per ADR-017 §S2; this schema references it for resolver completeness)
- [`release/references/standards/bundle-composition-doctrine.md`](../../release/references/standards/bundle-composition-doctrine.md) — the bundle-composition frame catalog (referenced, not re-listed, by `[bundling].bundle_doctrine_frame`)

---

## 1. Purpose

`platform-config.toml` is the platform-BEHAVIOR configuration surface — the parameterized, frequently-calibrated platform-behavior choices the pipeline tunes over time (bundling frame, release-size target, release-class default, relationship-mapping tuning). This schema is the canonical specification of its shape: what fields exist, their types, allowed values, defaults, calibration policy, consuming surfaces, and the cutover SHA recorded when a field's default changes.

It is DISTINCT from [`operator.toml`](../config/operator.toml.template), the operator-ENVIRONMENT / IDENTITY surface (identity, paths, `[adapters]` host-selectors, `[methodology].default_delivery_approach` — all named by ADR-017 §S2 as operator.toml concerns; `chmod 600`; depersonalization token vocabulary). The split rationale is recorded in [ADR-021](../ADRs/ADR-021-platform-config-vs-operator-toml-split.md). This schema relocates nothing from operator.toml — the categories below are NEW platform-behavior categories ADR-017 §S2 did not enumerate.

## 2. Layer model

| Layer | Carries | Storage | Git status |
|---|---|---|---|
| **Layer 1** | Field SCHEMA (this doc) + global DEFAULT values | [`core/config/platform-config.toml.template`](../config/platform-config.toml.template) | tracked (ships) |
| **Layer 2** | Per-tier override VALUES only | individual: `~/.config/pmo-platform/platform-config.toml` `[overrides]` · portfolio: `projects/_config/PORTFOLIO.md` frontmatter `platform_config:` · program: `projects/<Program>/_config/program-config.toml` · project: `projects/<Project>/PROJECT.md` frontmatter `platform_config:` | git-ignored (operator-instance) |

No per-tier operator value ever lands in a tracked file. This mirrors the `delivery_approach` precedent exactly: the enum + validation is Layer 1 ([`project-schema.md`](project-schema.md)); the value (`delivery_approach: Kanban`) is Layer 2 (PROJECT.md frontmatter).

## 3. Field schema

One row per field. **Cutover SHA** records the merge SHA at which the field's current default took effect (blank until the field's default is changed via a Track A governed PR — the introducing release records "introduced" rather than a cutover, anchored at the adapter-config-foundation merge SHA per the resolution-protocol cutover clause).

| Field | TOML path | Type | Allowed values | Default | Calibration policy | Consuming surface | Cutover SHA |
|---|---|---|---|---|---|---|---|
| `schema_version` | `[meta].schema_version` | integer | ≥ 1 | `1` | — | `update.sh` schema migration; `deploy.sh` Check | introduced @ adapter-config-foundation merge SHA |
| `managed_by` | `[meta].managed_by` | string | `"pmo-platform"` | `"pmo-platform"` | — | composition-surface tooling | introduced @ adapter-config-foundation merge SHA |
| `bundle_doctrine_frame` | `[bundling].bundle_doctrine_frame` | string (frame id) | frame ids per [`bundle-composition-doctrine.md § 1`](../../release/references/standards/bundle-composition-doctrine.md) — `"F1"` (default) and surveyed alternatives; **referenced, not re-listed** | `"F1"` | none (operator-set on milestone create/update) | `release-planner` Mode A (composition selection) + Mode B (doctrine-derived-field persistence); `bundle-composition-doctrine.md § 1` frame anchor | introduced @ adapter-config-foundation merge SHA |
| `release_size_target_pts` | `[bundling].release_size_target_pts` | string (`"low-high"` range) | a story-points range string (e.g., `"15-25"`) | `"15-25"` | **CALIBRATE-AFTER-3** — revisit after 3 releases of empirical velocity data | `release-planner` § 3 Step 5 size-check; Mode B size-target-band assessment | introduced @ adapter-config-foundation merge SHA |
| `default_release_class` | `[release_class].default_release_class` | string (enum) | the CLOSED 4-value enum `routine` / `novel` / `cross-cutting` / `hotfix` per [`release-class-taxonomy.md` Class Enum](../../release/references/specs/release-class-taxonomy.md) — **referenced, not re-defined** | `"novel"` | — | release hub (Stage 3 Phase B3 fallback when a milestone has no `## Release Class` H2) | introduced @ adapter-config-foundation merge SHA |
| `source_systems` | `[relationship_mapping].source_systems` | string (comma-separated system ids) | system ids per the active `operator.toml [adapters]` selectors | `"github"` | — | adapter relationship contract over the canonical relationship model | introduced @ adapter-config-foundation merge SHA |
| `maintenance_posture` | `[relationship_mapping].maintenance_posture` | string (enum) | `read-only` / `one-way-push` / `two-way-round-trip` | `"read-only"` | — | adapter relationship contract (per-system, project-resolvable) | introduced @ adapter-config-foundation merge SHA |
| `type_mapping_overrides` | `[relationship_mapping].type_mapping_overrides` | TOML table (canonical→native) | a table mapping canonical-type → native-type strings; `{}` = no deviations | `{}` | — | adapter relationship contract (per-system override table) | introduced @ adapter-config-foundation merge SHA |
| `releases_since_calibration` | `[calibration].releases_since_calibration` | integer | ≥ 0 | `0` | tracks accrual toward CALIBRATE-AFTER-3 fields | release hub / operator (Track B advance) | introduced @ adapter-config-foundation merge SHA |

### 3.1 Fields that live in operator.toml (referenced for resolver completeness)

The 5-rung resolver also resolves these, but their DEFAULT + SCHEMA live in [`operator.toml`](../config/operator.toml.template), not here (ADR-017 §S2):

| Field | operator.toml path | Allowed values | Default | Canonical home |
|---|---|---|---|---|
| `default_delivery_approach` | `[methodology].default_delivery_approach` | the 8 archetypes `Scrum` / `Kanban` / `XP` / `Waterfall` / `PRINCE2` / `SAFe` / `Hybrid` / `Custom` — **referenced, not re-listed** | `"Scrum"` | enum + validation: [`project-schema.md`](project-schema.md) `delivery_approach`; archetype defs: [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) |
| `repo_host` / `ticketing` / `kb` / `ai_tool` | `[adapters].*` | per the `[adapters]` field comments in operator.toml | `github` / `github` / `markdown` / `claude-code` | [`operator.toml.template`](../config/operator.toml.template) `[adapters]`; the #703 onboarding seam |

## 4. Resolution + fallback

The effective value of a field for a given scope is resolved by the 5-rung cascade in [`OPERATIONS.md § Platform-Config Resolution Protocol`](../governance/OPERATIONS.md): global default → portfolio → program → project → individual (most-specific wins; individual is highest precedence). The 3-level default-fallback:

1. Field set at ≥1 rung → resolve per precedence.
2. Field set ONLY at the global rung (this template) → use the default. **Common case.**
3. Field absent even from the global rung → the consumer uses its own documented hardcoded fallback and logs `[platform-config: field <F> unresolved; using consumer default <V>]`. Every consuming surface MUST declare its fallback so an absent/corrupt config never hard-fails a release.

## 5. Update governance (two-track)

Per [`OPERATIONS.md § Platform-Config Resolution Protocol`](../governance/OPERATIONS.md):

- **Track A — schema / default change (Layer 1):** editing a default in the template, adding/removing a field, changing an allowed-values set, or editing this schema = a **full governed PR** (GitHub Issue + plan + PR review per CLAUDE.md "No ungoverned changes"). This is a governance file. When a Track A change re-sets a default, record the merge SHA in the field's **Cutover SHA** column.
- **Track B — per-tier value set (Layer 2):** an operator setting a value for their own portfolio / program / project / individual scope = **no PR** (operator-instance write, like setting `delivery_approach: Kanban` in PROJECT.md). Audited by the operator's own instance history, never the platform repo.

## 6. Acceptance criteria

This schema is satisfied when:

- [ ] Every field in [`platform-config.toml.template`](../config/platform-config.toml.template) `[meta]` / `[bundling]` / `[release_class]` / `[relationship_mapping]` / `[calibration]` has a row above with type / allowed-values / default / consuming-surface.
- [ ] Every field ships a global default in the template (asserted by `deploy.sh` Check).
- [ ] The methodology enum and the release-class enum are REFERENCED from their canonical homes, not re-listed here (duplicate-source-discipline.md register-or-remove).
- [ ] The resolver and fallback match `OPERATIONS.md § Platform-Config Resolution Protocol`.
