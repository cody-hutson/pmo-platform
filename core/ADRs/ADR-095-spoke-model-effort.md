<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-095 — Canonical spoke model/effort edit surface (platform-config.toml [spoke_runtime]): an additive canonical entry point that supersedes-in-part the prior 'two surfaces by design / no single global-override surface' stance; the two Anthropic-owned runtime carriers (agent-definition frontmatter, settings.json) are preserved as derived/verified representations"
status: Accepted
date: 2026-07-25
release: v3.95-runtime-config-and-posture
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the v3.95 / 56-runtime-config-and-posture Collective Review scope-lock"
tags: [config-architecture, stage-5, stage-6, solutioning, engineering, spoke-runtime, model-config, effort-posture, canonical-surface, platform-config, hub-spoke, no-shadow-ssot, parameterize-over-hardcode, supersedes-in-part, detection-composite, reuse-first]
source_observations:
  - "Model + effort posture for hub-spawned spokes was spread across FOUR edit surfaces with no single discoverable entry point: (1) the immutable, name-agnostic model-preference directive in the operator-memory store (highest-tier model + MAX effort); (2) agent-definition frontmatter `model:`/`effort:` at .claude/agents/pmo-*.md (a subagent-path carrier, undeployed in this instance — spokes run general-purpose; #375 carryover); (3) the per-stage-override allowlist core/config/allowlists/agents-model-overrides.txt, whose header declared 'the per-file surface IS the override surface … two surfaces by design'; (4) the chip-prompt directive in hub-spoke-bridge.md (spawn_task exposes no model parameter, so the directive is prompt-embedded). Effort had NO config field at all."
  - "The default spoke model was HARDCODED in deploy.sh Check 27 (`c26_default_model=\"opus\"`), a silent literal rather than a resolved, parameterized value — the parameterize-over-hardcode seam the canonical surface closes."
  - "The prior model-config decision — carried by the model-REQUIRED-EXPLICIT + dual-anchor discipline PR (a merged pull-request, pre-renumber, NOT resolvable as an issue in the current numbering) — deliberately chose per-file frontmatter explicitness ('there is no single global-override surface — by design') to force per-spoke consideration, optimizing consideration over discoverability. That prior decision has no ADR record; it lives as the merged PR plus the derived corpus text in the allowlist header and hub-spoke-bridge.md § Per-Stage Override. This ADR is the first ADR-tier record of that surface, and it reverses the discoverability half of the prior stance."
  - "The two spawn classes have structurally DIFFERENT propagation: Agent-tool subagents inherit model/effort via .claude/agents/pmo-*.md frontmatter; spawn_task chips do NOT inherit — a fresh chip session reads ~/.claude/settings.json (model + effortLevel) at startup. Collapsing them into one mechanism would misrepresent the runtime; the canonical surface must expose them as independently-tunable knobs."
  - "resolve_platform_config (deploy.sh) is a scalar-only TOML reader; it does NOT parse inline tables, so per-stage overrides cannot fold into a [spoke_runtime] inline table without a new parser — the existing `<agent> <model>` allowlist line-format that Check 27 already parses is retained as the companion (reuse-first)."
---

# ADR-095 — Canonical spoke model/effort edit surface (`platform-config.toml [spoke_runtime]`)

## Status

Accepted — operator-ratified at the v3.95 / `56-runtime-config-and-posture` Collective Review scope-lock (2026-07-25), which locked the integrated `[spoke_runtime]` (#340) + `[security_hooks]` (#310) design and explicitly authorized this ADR to be authored during #340 Engineering with the next-free number, reversing the prior "two surfaces by design" stance. Authored at Stage 6 per the Stage-6 ADR-authoring precedent established by ADR-062 (substrate-vs-canonical), ADR-028 (operations-consume-core), and ADR-090 (structural-path-move mode). Stage 5 (#340's Solutioning output) produced the decision kernel; Engineering authored this record as release-branch content and closes it before Stage-6 exit.

Numbered 095 — the next-free slot in the one global `ADR-NNN` sequence. This record was authored with a provisional slot above the then-concurrent in-flight release-branch claims; as concurrent releases merged ADR-093 and ADR-094 to `main`, the `adr-number-integrity` CI job — the merge-time backstop — forced the reconciliation and the hub re-numbered this record to 095 at the Stage-12 main-merge. This ADR is referenced downstream **by slug**, never by its number — the number is an authoring-time assignment, not a stable cross-reference handle.

This decision is extended or reversed only by a **successor / superseding ADR** (Nygard `Superseded` / `Deprecated`, citing the successor) — never by an in-place edit of this record.

## Context

Changing the default spoke model (or a per-stage override, or the effort posture) required editing across **four** surfaces with no single discoverable entry point, and effort had no config field at all:

1. The immutable, name-agnostic model-preference directive in the operator-memory store ("always highest-tier model + MAX effort") — the behavioral SSOT, not a config knob.
2. Agent-definition frontmatter `model:`/`effort:` at `.claude/agents/pmo-*.md` — the subagent-path runtime carrier (Anthropic-owned; undeployed in this instance, where spokes run general-purpose).
3. The per-stage-override allowlist `core/config/allowlists/agents-model-overrides.txt`, whose header declared "the per-file surface IS the override surface … two surfaces by design."
4. The chip-prompt directive in `hub-spoke-bridge.md` — because `spawn_task` exposes no `model`/`effort` parameter, the directive is prompt-embedded.

On top of that, the default model was a silent hardcoded literal in `deploy.sh` Check 27 (`c26_default_model="opus"`).

The prior model-config decision deliberately chose per-file frontmatter explicitness — "there is no single global-override surface — by design" — to force the operator to consider each spoke type's model choice independently. That stance optimized **consideration** over **discoverability**. It was carried by a merged pull-request (pre-renumber; not resolvable as an issue in the current numbering) and has no ADR record; its derived text lives in the allowlist header and `hub-spoke-bridge.md` § Per-Stage Override. The operator directive that motivates #340 — "one standard place to edit this config moving forward" — reverses the discoverability half of that stance.

Two spawn classes must not be collapsed. Agent-tool subagents inherit model/effort via agent-definition frontmatter; `spawn_task` chips do **not** inherit — a fresh chip session reads `~/.claude/settings.json` (`model` + `effortLevel`) at startup. Their runtime carriers are different files; a canonical surface must expose them as independently-tunable knobs, not one.

A hard constraint from the prior decision must be preserved: the drift-detection composite — `deploy.sh` Check 27 (config drift) + the `### Model Provenance` block (invocation drift) + the Stage 8 QA LLM-graded review (hub-emit drift). The consolidation must transform/augment both anchors, never eliminate either.

## Decision

Establish **`platform-config.toml [spoke_runtime]`** as the single canonical, governance-registered entry point for hub-spawned-spoke model + effort posture:

1. **Two scalar model knobs.** `default_spoke_model` (the subagent-path default) and `chip_model` (the chip-path model the hub injects into `spawn_task` prompts). Both default to `opus`; they are normally equal (both track the current flagship per the model-preference directive), and are separate knobs solely so the two spawn classes stay independently tunable.
2. **Effort as a pointer, not a value.** The section stores **no** effort field. Effort is MAX for all spoke work per the immutable, name-agnostic model-preference directive; a stored `effort` value would be a shadow-SSOT of that directive and would drift (no-shadow-SSOT invariant). A comment block points to the directive; the concrete chip-runtime effort lives in `~/.claude/settings.json` (`effortLevel`), and the #339 SessionStart hook verifies the resolved session effort against the directive.
3. **The allowlist is retained as the per-stage-override companion.** `core/config/allowlists/agents-model-overrides.txt` (`<agent-name> <model>` per line) stays as the per-stage-override sub-surface, cross-referenced both ways, because its line-format is already what Check 27 parses and the scalar `resolve_platform_config` reader cannot parse a TOML inline table.
4. **Both detection anchors read the one surface.** Check 27's expected-default is de-hardcoded to `resolve_platform_config default_spoke_model` (with the documented `opus` consumer-fallback when unresolved; scan/compare logic byte-unchanged), and the `### Model Provenance` block re-points its "Designated-model match" reference to the same surface. The two prior detection anchors (deploy-time Check 27 + invocation-time Model Provenance) now read **one** source and can no longer diverge; #339 adds a third reader (the SessionStart hook) for runtime-launch + effort drift.
5. **The Anthropic-owned runtime carriers are preserved as derived/verified representations, not eliminated.** Agent-definition frontmatter (subagent path) and `settings.json` (chip path) remain the actual runtime carriers; `[spoke_runtime]` holds the canonical *resolution* those carriers are checked against.

The change is **additive**: it introduces a canonical entry point plus a pointer; it deletes no runtime contract. Discoverability is closed via the governance layer atop the surface — a Governance-File-Map row and a Universal-Preferences "where to change spoke model/effort" pointer in `CLAUDE.md.template`.

## Alternatives Considered

- **(A) A new dedicated file (`spoke-model-effort.toml.template`) — REJECTED.** Reuse-first (the bar is *necessary*, not *plausible*): a home exists. A new file needs a new parser, a new composition-surface manifest row, a new governance-map row, and new chip-inject wiring — cost without compensating benefit.
- **(B) `operator.toml [spoke_runtime]` — REJECTED (viable but weaker).** `operator.toml` is the environment/identity surface with a `chmod 600` guard for PII; a model enum carries no PII, and the surface is dominated by its *tunable* dimension (per-stage model selection is exactly the platform-behavior tuning `platform-config.toml` is chartered for, per ADR-022). Behavior-dominated → `platform-config.toml`.
- **(C) A governance-doc registry (markdown table) as the machine carrier — REJECTED as primary.** Not machine-readable for deploy/hook/hub-inject consumption. Retained, though, as the *discoverability layer* (the governance-map + Universal-Prefs pointer) atop the config surface.
- **(D) Auto-sync source → agent frontmatter (a generator that writes the carriers) — DEFERRED.** The frontmatter files are not even deployed in this instance today (#375 carryover); a generator adds drift risk. Check 27 stays a *validate* (consistency) check, not a generator. Revisit if/when the agent-definition files deploy.
- **Fold per-stage overrides into a `[spoke_runtime]` inline table — REJECTED.** The scalar `resolve_platform_config` reader cannot parse inline tables; folding would require a new parser (blast radius + new Check-33 coverage). The existing allowlist line-format is already parsed by Check 27 — reuse-first + Simplicity both say keep it.

## Consequences

**Positive:**
- One discoverable, governance-registered entry point for the spoke-model default (the operator directive's "one standard place").
- The default is de-hardcoded — Check 27 reads a parameterized value, not a silent literal (parameterize-over-hardcode).
- Both drift-detection anchors read one source, so anchor-vs-anchor divergence becomes structurally impossible; the composite is strengthened, not weakened.
- Effort *drift detection* is added (the fourth surface the composite lacked) via the #339 SessionStart hook reading the effort pointer — without a shadow-SSOT copy.
- #310 converges on the same durable file (a sibling `[security_hooks]` section), reusing the composition-surface durability contract rather than standing up a third carrier.

**Negative / costs:**
- Two model knobs (`default_spoke_model` / `chip_model`) that are normally equal — a small comprehension cost, accepted as the price of keeping the two spawn classes independently tunable (documented rationale).
- Per-stage overrides stay in a companion file rather than the TOML section — a two-file surface for the full model picture, accepted because the scalar reader cannot parse an inline table.
- `spawn_task` still exposes no `model`/`effort` parameter, so the chip path cannot be *forced* at the launch call; the interim mechanism is prompt-injection + the `settings.json` pins the fresh session reads + #339 verification, with a Claude Code feature request filed for native passthrough as the durable fix.

## Reversibility

**MODERATE / Confidence HIGH.** The surface is additive; a `git revert` of the release PR restores the prior state with no data migration. The tier is MODERATE (not CHEAP) only because the downstream spokes #310 (sibling `[security_hooks]` section on the same file) and #339 (reads `[spoke_runtime]` + the effort pointer) consume the carrier shape locked here — reversing after they land re-casts their carrier decision. Per reversibility-protocol.md.

## Related ADRs

- **ADR-022** (platform-config.toml vs operator.toml split) — establishes that `platform-config.toml` is the no-PII platform-behavior surface. `[spoke_runtime]` is a new behavior category on that surface; this ADR applies ADR-022's boundary (behavior-dominated, no-PII → platform-config) to the spoke model/effort decision (alternative B rejected on exactly that boundary).
- **The prior "two surfaces by design" model-config decision** (a merged pre-renumber PR, not an ADR; its derived text lives in the `agents-model-overrides.txt` header and `hub-spoke-bridge.md` § Per-Stage Override) — **superseded-in-part**: its discoverability half ("no single global-override surface") is reversed by this canonical entry point; its runtime-carrier explicitness and its detection composite are preserved and strengthened. Because that decision has no ADR record, this ADR is the first ADR-tier record of the surface and records the supersession in prose here rather than via a Nygard `Superseded`-of-an-ADR pointer.

## References
Originating deliverable: #340 (milestone `56-runtime-config-and-posture`, #183) — establish the canonical spoke model/effort edit surface while preserving the detection composite. Downstream consumers of the carrier shape locked here: #339 (the SessionStart model/effort hook reads `[spoke_runtime].default_spoke_model` + the effort pointer; sequence #340 → #339) and #310 (adds a sibling `[security_hooks]` section to the same `platform-config.toml`). Sibling v3.95 config-add: #1212 (`[failure_mode_detectors]` + `[progressive_rollout]`). The platform-config surface + `resolve_platform_config` rung-reader this surface reuses were introduced by #22 (adapter-config-foundation). The prior model-REQUIRED-EXPLICIT + dual-anchor decision this ADR supersedes-in-part was carried by a merged pull-request that does not resolve as an issue in the current numbering (pre-renumber); it is named in prose above, not by number, per the reference-durability discipline.
