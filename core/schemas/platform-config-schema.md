---
title: platform-config.toml Schema
purpose: The canonical schema for platform-config.toml — the fields, types, and defaults of the Layer-1 tunable-behavior configuration surface.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the platform-config.toml.template (Layer 1 defaults); the Platform-Config Resolution Protocol; deploy.sh config checks; every skill reading a platform-config field
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# platform-config.toml Schema

**Status:** Canonical
**Owner:** `core/schemas/platform-config-schema.md`
**Introduced:** adapter-config-foundation
**Surface:** [`core/config/platform-config.toml.template`](../config/platform-config.toml.template) (Layer 1 — global defaults + this schema's fields)
**Consumers:** `release-planner` (Mode A), `release-executor` (Mode A), the release hub (Procedure 0), `core/deploy/deploy.sh` (`resolve_platform_config` rung-reader), `OPERATIONS.md § Platform-Config Resolution Protocol`
**Cross-references:**

- [`composition-surface-spec.md`](../standards/composition-surface-spec.md) — durability contract (managed-section / operator-additions fences, regeneration, tamper detection) the template carries
- [`core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`](../governance/OPERATIONS.md) — the 5-rung resolver, 3-level default-fallback, and Track A/B update governance
- [`core/ADRs/ADR-022-platform-config-vs-operator-toml-split.md`](../ADRs/ADR-022-platform-config-vs-operator-toml-split.md) — the operator.toml (environment/identity) vs platform-config.toml (behavior) split decision
- [`release/references/specs/release-class-taxonomy.md`](../../release/references/specs/release-class-taxonomy.md) — the CLOSED 4-value Release Class enum (referenced, not re-listed, by `[release_class].default_release_class`)
- [`release/references/specs/methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) + [`project-schema.md`](project-schema.md) — the 8-archetype methodology enum (the `default_delivery_approach` DEFAULT lives in `operator.toml [methodology]`, not here, per ADR-017 §S2; this schema references it for resolver completeness)
- [`release/references/standards/bundle-composition-doctrine.md`](../../release/references/standards/bundle-composition-doctrine.md) — the bundle-composition frame catalog (referenced, not re-listed, by `[bundling].bundle_doctrine_frame`)

---

## 1. Purpose

`platform-config.toml` is the platform-BEHAVIOR configuration surface — the parameterized, frequently-calibrated platform-behavior choices the pipeline tunes over time (bundling frame, release-size target, release-class default, relationship-mapping tuning). This schema is the canonical specification of its shape: what fields exist, their types, allowed values, defaults, calibration policy, consuming surfaces, and the cutover SHA recorded when a field's default changes.

It is DISTINCT from [`operator.toml`](../config/operator.toml.template), the operator-ENVIRONMENT / IDENTITY surface (identity, paths, `[adapters]` host-selectors, `[methodology].default_delivery_approach` — all named by ADR-017 §S2 as operator.toml concerns; `chmod 600`; depersonalization token vocabulary). The split rationale is recorded in [ADR-022](../ADRs/ADR-022-platform-config-vs-operator-toml-split.md). This schema relocates nothing from operator.toml — the categories below are NEW platform-behavior categories ADR-017 §S2 did not enumerate.

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
| `mode_a_parse_rate_floor` | `[bundling].mode_a_parse_rate_floor` | decimal (fraction) | a decimal in `[0.0, 1.0]` | `0.90` | **CALIBRATE-AFTER-3** — recalibrate from observed Mode A parse-quality after 3 releases | gate **G3-14** (Mode A combined-clean parse-rate floor, [`gate-criteria-spec.md` § Gate 3](gate-criteria-spec.md); read by config-field role over the conformant-bundleable denominator per `release-planner` SKILL.md Step 1.5) | introduced @ the G3-14 introducing-release merge SHA |
| `default_release_class` | `[release_class].default_release_class` | string (enum) | the CLOSED 4-value enum `routine` / `novel` / `cross-cutting` / `hotfix` per [`release-class-taxonomy.md` Class Enum](../../release/references/specs/release-class-taxonomy.md) — **referenced, not re-defined** | `"novel"` | — | release hub (Stage 3 Phase B3 fallback when a milestone has no `## Release Class` H2) | introduced @ adapter-config-foundation merge SHA |
| `source_systems` | `[relationship_mapping].source_systems` | string (comma-separated system ids) | system ids per the active `operator.toml [adapters]` selectors | `"github"` | — | adapter relationship contract over the canonical relationship model | introduced @ adapter-config-foundation merge SHA |
| `maintenance_posture` | `[relationship_mapping].maintenance_posture` | string (enum) | `read-only` / `one-way-push` / `two-way-round-trip` | `"read-only"` | — | adapter relationship contract (per-system, project-resolvable) | introduced @ adapter-config-foundation merge SHA |
| `type_mapping_overrides` | `[relationship_mapping].type_mapping_overrides` | TOML table (canonical→native) | a table mapping canonical-type → native-type strings; `{}` = no deviations | `{}` | — | adapter relationship contract (per-system override table) | introduced @ adapter-config-foundation merge SHA |
| `releases_since_calibration` | `[calibration].releases_since_calibration` | integer | ≥ 0 | `0` | tracks accrual toward CALIBRATE-AFTER-3 fields | release hub / operator (Track B advance) | introduced @ adapter-config-foundation merge SHA |
| `concurrency_ceiling` | `[failure_mode_detectors].concurrency_ceiling` | integer | a positive integer (count of concurrent active workstreams) | `5` | MEDIUM-confidence seed — set a per-portfolio value via a Layer-2 override; NOT tied to `[calibration].releases_since_calibration` (that is the release-velocity loop; this is an audit-window threshold) | `pmo-qa-auditor` Failure-Mode Detector **D6** (breadth burnout) per [`failure-mode-detectors.md`](../skills/pmo-qa-auditor/references/failure-mode-detectors.md) — the single NUMERIC home; the reference cites by key, does not restate | introduced @ 56-runtime-config-and-posture merge SHA |
| `walk_back_rate_floor` | `[failure_mode_detectors].walk_back_rate_floor` | decimal (fraction) | a decimal in `[0.0, 1.0]` | `0.15` | MEDIUM-confidence seed — set a per-portfolio value via a Layer-2 override; NOT tied to `[calibration].releases_since_calibration` | `pmo-qa-auditor` Failure-Mode Detector **D8** (trust erosion) per [`failure-mode-detectors.md`](../skills/pmo-qa-auditor/references/failure-mode-detectors.md) — the single NUMERIC home | introduced @ 56-runtime-config-and-posture merge SHA |
| `rollout_log_dir` | `[progressive_rollout].rollout_log_dir` | string (repo-relative dir path) | a repo-relative directory path string | `"core/hooks"` | — | `release-executor` progressive-rollout outcome-log writer per [`progressive-rollout.md`](../../release/skills/release-executor/references/progressive-rollout.md) — config home for LOCATION only; the reference owns the behavioral contract | introduced @ 56-runtime-config-and-posture merge SHA |
| `rollout_log_filename_pattern` | `[progressive_rollout].rollout_log_filename_pattern` | string (filename pattern) | a filename pattern string containing the `<rule-id>` placeholder and a `.jsonl` extension | `"<rule-id>-rollout-log.jsonl"` | — | `release-executor` progressive-rollout outcome-log writer per [`progressive-rollout.md`](../../release/skills/release-executor/references/progressive-rollout.md) — config home for FORMAT only | introduced @ 56-runtime-config-and-posture merge SHA |
| `rollout_log_format` | `[progressive_rollout].rollout_log_format` | string (enum) | `jsonl` (append-only JSON Lines — the only supported format) | `"jsonl"` | — | `release-executor` progressive-rollout outcome-log writer per [`progressive-rollout.md`](../../release/skills/release-executor/references/progressive-rollout.md) | introduced @ 56-runtime-config-and-posture merge SHA |
| `default_spoke_model` | `[spoke_runtime].default_spoke_model` | string (enum) | `sonnet` / `opus` / `haiku` | `"opus"` | none — the current RESOLUTION of the immutable, name-agnostic `feedback_model_preference` directive ("always highest-tier model"); update ONLY when the flagship model NAME changes (Track A) | subagent-path default: `deploy.sh` **Check 27** (designated-model config — expected-default source) + the `### Model Provenance` block + the #339 SessionStart hook, all reading this ONE surface (#340) | introduced @ 56-runtime-config-and-posture merge SHA |
| `chip_model` | `[spoke_runtime].chip_model` | string (enum) | `sonnet` / `opus` / `haiku` | `"opus"` | none — normally EQUAL to `default_spoke_model`; a separate knob solely so the two spawn classes stay independently tunable (#340) | chip-path default: hub Procedure-0 chip-prompt construction (resolve-once → inject) per [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) | introduced @ 56-runtime-config-and-posture merge SHA |

**`[spoke_runtime]` effort posture — a pointer, NOT a field (by design).** The section carries the two model scalars above and **no** effort field. Effort is MAX for all spoke work per the immutable, name-agnostic model-preference directive (SSOT: the operator-memory store — the "always highest-tier model + MAX effort" directive); a stored `effort` value here would be a **shadow-SSOT** of that directive and would drift (no-shadow-SSOT invariant). The concrete chip-runtime effort lives in `~/.claude/settings.json` (`effortLevel`) as the Anthropic chip contract; the #339 SessionStart hook VERIFIES the resolved session effort against the directive. To change effort, change the directive (governed) — there is no schema row because there is no field. This satisfies the #340 completion-condition "the canonical file … carries a comment block pointing to the immutable behavioral directive."

### 3.1 Fields that live in operator.toml (referenced for resolver completeness)

The 5-rung resolver also resolves these, but their DEFAULT + SCHEMA live in [`operator.toml`](../config/operator.toml.template), not here (ADR-017 §S2):

| Field | operator.toml path | Allowed values | Default | Canonical home |
|---|---|---|---|---|
| `default_delivery_approach` | `[methodology].default_delivery_approach` | the 8 archetypes `Scrum` / `Kanban` / `XP` / `Waterfall` / `PRINCE2` / `SAFe` / `Hybrid` / `Custom` — **referenced, not re-listed** | `"Scrum"` | enum + validation: [`project-schema.md`](project-schema.md) `delivery_approach`; archetype defs: [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md) |
| `repo_host` / `ticketing` / `kb` / `ai_tool` | `[adapters].*` | per the `[adapters]` field comments in operator.toml | `github` / `github` / `markdown` / `claude-code` | [`operator.toml.template`](../config/operator.toml.template) `[adapters]` — the onboarding-umbrella seam (operator host-surface choices are written here at onboarding time) |

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

- [ ] Every field in [`platform-config.toml.template`](../config/platform-config.toml.template) `[meta]` / `[bundling]` / `[release_class]` / `[relationship_mapping]` / `[calibration]` / `[failure_mode_detectors]` / `[progressive_rollout]` / `[spoke_runtime]` has a row above with type / allowed-values / default / consuming-surface (the `[spoke_runtime]` effort posture is a pointer, not a field — noted above the row, no schema row by design).
- [ ] Every field ships a global default in the template (asserted by `deploy.sh` Check).
- [ ] The methodology enum and the release-class enum are REFERENCED from their canonical homes, not re-listed here (duplicate-source-discipline.md register-or-remove).
- [ ] The resolver and fallback match `OPERATIONS.md § Platform-Config Resolution Protocol`.
