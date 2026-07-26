# Platform Config Reference — pmo-platform

> Human-readable catalog of every platform configuration field: what it does, what values it takes, its default, and where to set it. This is a **derived navigation surface** — the canonical schema is [`core/schemas/platform-config-schema.md`](../core/schemas/platform-config-schema.md). On any field change, update the schema first; this catalog follows.

<!-- platform-config-reference.md is a derived catalog. Canonical detail: core/schemas/platform-config-schema.md + the field comments in core/config/platform-config.toml.template + core/config/operator.toml.template. -->

## 1. About this document

- **Audience:** Operators tuning platform behavior; anyone asking "what config knobs does the platform have, and where do I set them?"
- **Two surfaces, one resolver.** Platform configuration lives in two files split by concern (per [ADR-022](../core/ADRs/ADR-022-platform-config-vs-operator-toml-split.md)):
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

### `[automation]` — ambient-intake automation governor

| Field | What it sets | Allowed values | Default |
|---|---|---|---|
| `automation_level` | the single dial that governs how much the platform does on its own during ambient intake (scheduled transcript / email ingest + external-tracker sync) — a **ceiling**, not a switch: `effective = min(automation_level, per-action max)` | `off` ("Off" — proposes nothing) · `recommend` ("Brief me" — drafts/surfaces, you approve before any write) · `bounded_auto` ("Handle the routine" — auto-handles low-stakes routine within scope) | `recommend` |

A ceiling can only LOWER a per-action autonomy, never raise one. The irreducible Tier-0 set (financial / account-creation / security-permission / governance-file / cross-domain bridge / Stage 9 / Stage 12, plus RAID-Log closes) never unlocks at any level — canonical list in [`core/specs/autonomy-tiers.md`](../core/specs/autonomy-tiers.md) § Irreducible Human Tasks. **Enforcement posture:** advisory/soft today; the C5 PreToolUse hook lands in this release warn-mode-initial (reports, does not block), and the operator flips it warn→enforce after the shakedown window. Once flipped, the hook hard-blocks only the payload-detectable Tier-0 classes (governance-file + cross-domain bridge paths); the remaining irreducible classes stay operator-irreducible by convention. Canonical detail: the field comments in [`core/config/operator.toml.template`](../core/config/operator.toml.template).

### `[platform]` — legacy adapter selectors (deprecated alias)

| Field | Status | Notes |
|---|---|---|
| `work_board` | **DEPRECATED ALIAS** | Kept as a deprecation alias (no current reader); superseded by `[adapters].ticketing`. It ships in the template and `setup-workspace.sh` generates it into operator configs, so it is deprecated-not-removed to preserve a clean migration path. New consumers should read `[adapters].ticketing`. |
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

### `[failure_mode_detectors]`

Operator/portfolio-specific threshold seeds for the `pmo-qa-auditor` Failure-Mode Detector Battery. Only two detectors read a config threshold; the other six carry their thresholds inline. Canonical detector definitions: `core/skills/pmo-qa-auditor/references/failure-mode-detectors.md`.

| Field | What it tunes | Allowed values | Default |
|---|---|---|---|
| `concurrency_ceiling` | the max sustainable count of concurrent active workstreams above which detector **D6** (breadth burnout) fires (in conjunction with a depth-metric decline) | a positive integer | `5` |
| `walk_back_rate_floor` | the walk-back / retraction rate floor above which detector **D8** (trust erosion) fires | a decimal in `[0.0, 1.0]` | `0.15` |

### `[progressive_rollout]`

Persistence surface (LOCATION + FORMAT only) for the `release-executor` progressive-rollout outcome-log. The behavioral contract is canonical in `release/skills/release-executor/references/progressive-rollout.md`.

| Field | What it tunes | Allowed values | Default |
|---|---|---|---|
| `rollout_log_dir` | directory (repo-relative) where per-rule rollout-logs are written | a repo-relative directory path | `core/hooks` |
| `rollout_log_filename_pattern` | per-rule rollout-log filename pattern (the `<rule-id>` placeholder is replaced with the emitting rule/gate id) | a filename pattern with the `<rule-id>` placeholder + `.jsonl` | `<rule-id>-rollout-log.jsonl` |
| `rollout_log_format` | on-disk log format (append-only JSON Lines) | `jsonl` | `jsonl` |

### `[spoke_runtime]`

The **single canonical, operator-discoverable edit surface** for hub-spawned-spoke model + effort posture. Change the default spoke model here (one edit, one place), then run `./deploy.sh --check` to confirm no drift across consumers (Check 27).

| Field | What it tunes | Allowed values | Default |
|---|---|---|---|
| `default_spoke_model` | the default model for **subagent-path** spoke work (Agent-tool subagents; inherited via agent-definition frontmatter). The canonical entry point for the spoke-model default. | `sonnet` · `opus` · `haiku` | `opus` |
| `chip_model` | the model the hub injects into `spawn_task` **chip-path** prompts (chips do not inherit; normally equal to `default_spoke_model`, a separate knob only so the two spawn classes stay independently tunable) | `sonnet` · `opus` · `haiku` | `opus` |

**Effort posture is a pointer, not a field.** Effort is MAX for all spoke work per the immutable model-preference directive; the section stores no `effort` value (a stored value would shadow that directive and drift). To change effort, change the directive. **Per-stage model overrides** live in the companion `core/config/allowlists/agents-model-overrides.txt` (`<agent-name> <model>` per line), read by Check 27 alongside this default.

### `[security_hooks]`

Master activation for the `core/hooks/block-*` PreToolUse hook layer. **Opt-in, default OFF:** a fresh public clone imposes no *workflow* guards until the operator opts in — at install (`docs/scripts/setup-workspace.sh` prompts, default OFF) or by setting `master_enabled` here. The durable value lives in the individual-tier XDG file `~/.config/pmo-platform/platform-config.toml`, which `update.sh` never overwrites, so the choice survives version upgrades. Read by `core/hooks/lib/master-enable.sh`; precedence inside each hook is `CLAUDE_HOOK_BYPASS` → `master_enabled` → per-hook `.mode` → rule.

**Security scope (D-R9).** Master-OFF governs the **workflow-class** hooks only (`block-draft-files`, `block-fragile-refs`, `block-fs-boundary`, `block-mcp-writes`, `block-skill-direct-edit`, and the mode-gated ceiling of `block-autonomy-ceiling`). The **security/floor-class** hooks (`block-credential-reads`, `block-destructive`, `block-rm-prefer-trash`, `block-egress`, `block-gh-path-leak`, `block-scope-segregation`, `block-shell-injection`) plus the `block-autonomy-ceiling` Tier-0 floor and `git-pre-commit-pii` ALWAYS enforce and are never silently disabled by master-OFF — public-surface security is paramount (a silently-disabled egress/PII guard → an irreversible leaked commit/PR). `CLAUDE_HOOK_BYPASS` remains the per-session, audit-logged escape.

| Field | What it tunes | Allowed values | Default |
|---|---|---|---|
| `master_enabled` | whether the **workflow-class** `block-*` hooks are active. `false` = a fresh clone's workflow hooks are inert (opt-in); security/floor-class hooks enforce regardless | `true` · `false` | `false` |
| `security_class_master_optout` | explicit, logged operator acknowledgment that the security/floor-class hooks may ALSO go inert under `master_enabled = false` — a public-surface-safety downgrade. Never silently defaulted true | `true` · `false` | `false` |

## 5. Consumer examples (how the platform reads these)

Three wired examples ship with the adapter-config-foundation release:

1. **`bundle_doctrine_frame` → release-planner.** release-planner Mode A resolves `bundle_doctrine_frame` at session start and anchors bundle-composition to that frame; Mode B persists the resolved frame into the release plan's `## Summary`.
2. **`default_release_class` → release hub.** The hub resolves `default_release_class` as the fallback when a milestone description carries no `## Release Class` H2.
3. **`default_delivery_approach` → methodology fallback.** A project with no `delivery_approach` set resolves to the global `default_delivery_approach` (instead of the old implicit "sprint-centric Agile" default).

## 6. See also

- [`core/schemas/platform-config-schema.md`](../core/schemas/platform-config-schema.md) — canonical field schema (type / allowed-values / default / calibration / consuming-surface / cutover-SHA).
- [`core/governance/OPERATIONS.md § Platform-Config Resolution Protocol`](../core/governance/OPERATIONS.md) — the 5-rung resolver, fallback, and Track A/B governance.
- [`core/ADRs/ADR-022-platform-config-vs-operator-toml-split.md`](../core/ADRs/ADR-022-platform-config-vs-operator-toml-split.md) — the operator.toml vs platform-config.toml split decision.
- [`core/config/operator.toml.template`](../core/config/operator.toml.template) · [`core/config/platform-config.toml.template`](../core/config/platform-config.toml.template) — the two surfaces themselves.
