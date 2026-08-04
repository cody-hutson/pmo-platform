---
title: "ADR-022 — platform-config.toml vs operator.toml split: environment/identity vs platform-behavior"
status: Accepted
date: 2026-06-13
release: adapter-config-foundation
deciders: "Collective Review scope-lock (Option C-refined) 2026-06-13 + the adapter-config-foundation Stage 5 Solutioning spokes + operator at the Stage 4 plan-approval gate"
tags: [architecture, config, governance, adapters, composition-surface]
source_observations:
  - "ADR-017 §S2 names operator.toml as the home for 'identity, paths, methodology, adapters' (line 62). The adapter selectors (repo_host/ticketing/kb/ai_tool — the #703 onboarding seam) are therefore ADR-017-faithful when added to operator.toml [adapters]."
  - "ADR-017 §162 names #22 (unified config) as the ticket that 'implements S2 consolidation' — #22 is the promotion of an anticipated surface, not a greenfield design."
  - "Multiple corpus files (bundle-composition-doctrine.md, release-process.md, RELEASE_PROTOCOL.md, stage-03-bundle.md, release-planner SKILL.md) forward-reference 'the unified config mechanism / unified config surface' by name — the consumer surface anticipated a single behavior-config home that did not yet exist."
  - "operator.toml is the depersonalization token-vocabulary source (chmod 600, security-sensitive, rarely-changed) per depersonalization-spec.md §1; bundling/release-class/relationship-mapping tuning is frequently-calibrated and PII-free — a different change cadence, audience, and governance weight."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-022 — platform-config.toml vs operator.toml split: environment/identity vs platform-behavior

## Status

Accepted — operator-ratified at the adapter-config-foundation Collective Review scope-lock (2026-06-13), the Stage 5 N-way-consistency gate per the Status enum in `core/ADRs/README.md` ("Operator-ratified at Collective Review or equivalent gate"). The Stage 5 Solutioning spoke (#734) proposed the #703 config seam at a new `platform-config.toml` and rejected extending operator.toml; Collective Review LOCKED a different, non-breaking structure — **Option C-refined** — which this ADR records.

## Context

The adapter-config-foundation milestone (#22 + #703) needs a canonical home for two distinct kinds of config:

1. **Host-adapter selectors** — which repository host, ticketing surface, knowledge base, and AI-tool runtime the platform integrates with. This is the seam #703 (onboarding-umbrella spine) writes operator onboarding-time choices into.
2. **Platform-behavior tuning** — the bundling frame, the release-size target band, the default release-class, and relationship-mapping tuning. These are frequently-calibrated knobs the pipeline tunes over time.

The platform already ships [`operator.toml`](../config/operator.toml.template) — a Layer-1 TOML config template carrying `[meta]`, `[identity]`, `[paths]`, `[platform]` sections. `[platform]` already holds two adapter selectors (`work_board`, `comms_platform`). [ADR-017](ADR-017-distribution-architecture.md) §S2 names operator.toml as the home for "identity, paths, methodology, adapters," and §162 names #22 as implementing "S2 consolidation."

Three structural options were on the table:

- **(A) One file** — extend operator.toml with all new categories. Simplest; one reader idiom. But it forces every frequently-calibrated behavior tweak through the identity file's change surface (`chmod 600`, depersonalization token vocabulary, security-sensitive) — conflating two change cadences and two audiences.
- **(B) Two files, relocating adapters out of operator.toml** — the Stage 5 spec's proposal: put the #703 seam at a new `platform-config.toml` and stop using operator.toml `[platform]` adapter selectors. Clean separation, but it RELOCATES adapter selection out of operator.toml — a deviation from ADR-017 §S2, which names adapters as an operator.toml concern. That §S2 deviation is the disqualifying problem; it also breaks the convention that the `[platform]` selectors ship in the operator.toml template and are generated into operator configs by `setup-workspace.sh`.
- **(C-refined) Two files, principled split, non-breaking, ADR-017-faithful** — adapters stay in operator.toml (ADR-017-faithful); a NEW `platform-config.toml` holds ONLY the NEW platform-behavior categories ADR-017 did not enumerate. Nothing is relocated.

## Decision

Adopt **Option C-refined**: a two-file split along the security/access-control boundary, relocating nothing.

1. **`operator.toml` is the operator-ENVIRONMENT / IDENTITY surface.** It carries identity, paths, the methodology default, and the host-adapter selectors. The adapter selectors are consolidated into a NEW `[adapters]` table (`repo_host` / `ticketing` / `kb` / `ai_tool`) — each with a v1 default — which is the #703 onboarding seam (ADR-017 §S2-faithful: §S2 explicitly names "adapters" as an operator.toml concern). The methodology default lands in a `[methodology]` table (`default_delivery_approach`) — also ADR-017 §S2-named. operator.toml retains its security posture (`chmod 600`, depersonalization token-vocabulary source).

2. **`platform-config.toml` (NEW, [`core/config/platform-config.toml.template`](../config/platform-config.toml.template)) is the platform-BEHAVIOR surface.** Composition-surface category per [`composition-surface-spec.md`](../standards/composition-surface-spec.md). It holds ONLY the NEW behavior categories ADR-017 did not enumerate: `[bundling]` (`bundle_doctrine_frame`, `release_size_target_pts`), `[release_class]` (`default_release_class`, the CLOSED 4-value enum referenced from its canonical home), `[relationship_mapping]` (`source_systems` / `maintenance_posture` / `type_mapping_overrides`), and `[calibration]`. Purely additive — nothing is relocated from operator.toml.

3. **The legacy `[platform].work_board` / `comms_platform` fields are reconciled by ALIAS/deprecation, NOT removal.** `[platform].work_board` is retained as a deprecation alias superseded by `[adapters].ticketing` — NOT removed. It has **no current internal reader**; it ships in the operator.toml template and `setup-workspace.sh` generates it into operator configs, so it is deprecated-not-removed to preserve a clean migration path and avoid breaking any operator/external config that references it. New consumers read `[adapters].ticketing`; when both are set and differ, `[adapters].ticketing` is authoritative. A future Track-A governed change MAY fold the alias once it is confirmed unused everywhere.

4. **The #703 onboarding seam is `operator.toml [adapters]`.** Onboarding-time operator choices about host surfaces are written there (individual-tier `~/.config/pmo-platform/operator.toml`); #703's design is unchanged.

This decision **refines and extends ADR-017 §S2** (it sharpens the operator.toml "adapters/methodology" enumeration into named tables and adds a sibling behavior-config surface). It **relocates nothing** and is therefore **not** an ADR-017 deviation.

## Consequences

**Positive:**

- One canonical surface per concern: identity/environment in operator.toml, behavior in platform-config.toml. The corpus forward-references to "the unified config mechanism / unified config surface" now resolve to a real surface.
- The ONE justified split (security/access-control boundary) is honored: operator.toml carries PII-adjacent token vocabulary + secrets-adjacent identity (`chmod 600`); platform-config.toml carries no PII and is freely tunable.
- **Breaking-change posture: additive-only.** `deploy.sh`/hooks keep reading the current `operator.toml` keys they read today; `[platform].work_board` is retained as a deprecation alias (it has no current internal reader, but it ships in the template and `setup-workspace.sh` generates it into operator configs, so it is preserved to avoid breaking any operator/external config that references it); `delivery_approach` stays in PROJECT.md; the 5-rung resolver's fail-safe default-fallback means non-adopting consumers behave exactly as before; the #703 onboarding seam is stable.

**Negative / costs:**

- Two config files instead of one — two reader sites (the `deploy.sh` `resolve_platform_config` reader mirrors the existing `operator.toml` reader idiom, so the marginal cost is one function).
- A deprecated alias (`[platform].work_board`) persists until a future fold — a small, documented governance-debt item with a clear migration path.

## Reversibility

**CHEAP** at ship (additive — no data migration; the new file + reader can be reverted by reverting the release PR; the alias keeps existing readers working), trending **MODERATE** as downstream adapter tickets (#10/#11/#12/#13) wire into the `[adapters]` seam and consumers wire into platform-config fields. Per [reversibility-protocol.md](../specs/reversibility-protocol.md).

## Related ADRs

- [ADR-017 — Distribution architecture](ADR-017-distribution-architecture.md) — §S2 names operator.toml as the home for identity/paths/methodology/adapters and §162 names #22 as implementing S2 consolidation. This ADR refines/extends S2; it relocates nothing.
- [ADR-014 — Two-hash managed-section tamper detection](ADR-014-managed-section-two-hash-tamper-detection.md) — the composition-surface durability contract platform-config.toml inherits as a composition-surface file.
- [ADR-010 — Secrets / public-safety substrate](ADR-010-secrets-handling-policy-substrate.md) — the reason operator.toml's security posture (the PII-adjacent boundary) is the justified split line.
- [ADR-013 — detect_install_path session-resolution](ADR-013-detect-install-path-session-resolution.md) — the `operator.toml` rung-reader idiom the `resolve_platform_config` reader mirrors.

## References

- #734 — the adapter-config-foundation Stage 5 Solutioning spoke that proposed the config seam at a new `platform-config.toml` and rejected extending `operator.toml`.
- #738 — the sibling adapter-config-foundation Stage 5 Solutioning spoke, named alongside #734 as a decider on this record.
