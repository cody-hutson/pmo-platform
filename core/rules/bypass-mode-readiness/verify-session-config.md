<!-- reference-durability: allow-link -->
## `verify-session-config.sh` (VERIFY-SESSION-CONFIG-001..099)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/verify-session-config.sh` |
| Matcher | `SessionStart` |
| Scope | Runtime MODEL + EFFORT posture verification at session launch. Reads the resolved model (`.model`, stdin payload) and effort (`$CLAUDE_EFFORT`, with payload `.effort.level` as the jq-free cross-check), compares them against the canonical `platform-config.toml [spoke_runtime]` model surface and the immutable `max` effort directive, and emits an advisory notice on drift. A **workflow-class** posture verifier — NOT a security/floor hook — that adds the runtime-launch detection surface the model/effort composite lacked (the other three are deploy-time Check 27, invocation-time Model Provenance, and the Stage-8 QA review). |
| Mode | OWN mode file `.verify-session-config-mode` (warn / enforce / off), NOT the shared `.claude/hooks/.mode`, so its shakedown is decoupled from the security cohort (the `block-autonomy-ceiling` `.autonomy-mode` precedent). Ships **warn-mode-initial**; an absent mode file defaults to warn. |

### Rule registry

| Rule ID | Description |
|---|---|
| VERIFY-SESSION-CONFIG-001 | Model mismatch — the resolved runtime model matches NEITHER the `default_spoke_model` NOR the `chip_model` family read from `platform-config.toml [spoke_runtime]` (the accept-set; the hook cannot distinguish a chip session from a subagent at launch). Compared on the family token (`opus` / `sonnet` / `haiku`) so a point-release id never false-flags. |
| VERIFY-SESSION-CONFIG-002 | Effort mismatch — the resolved session effort (`$CLAUDE_EFFORT`, else payload `.effort.level`) is not the immutable directive value `max`. |
| VERIFY-SESSION-CONFIG-003 | Payload-schema-fallback — fires ONLY when the SessionStart payload `.model` is absent (source ∈ `clear` / `compact` / `resume` / `recovery`, where the field is documented-omittable). A DEGRADED-verification notice naming the expected model and the omit source — NEVER a silent pass. |

### Posture — verify-session-config.sh

**Non-blocking by construction.** SessionStart hooks structurally cannot block a session (a non-zero exit renders a non-blocking "hook error" notice; the session proceeds regardless). This hook is a NOTIFIER/VERIFIER: EVERY path exits 0 in warn/off, and enforce-mode emits a non-zero exit (wrapper/CI-detectable) that is still not a hard stop. This satisfies the "must not block legitimate downgrade workflows" constraint by construction — an operator running `--effort low` for a cost-sensitive task is warned, never blocked. All notices go to **stderr**: a SessionStart hook's stdout is injected into Claude's context, so mismatch notices must never pollute it.

**Fail-toward-advisory.** Unlike the `block-*.sh` security hooks (fail-closed exit-2 on missing `jq` / malformed input), a missing dependency or unparseable payload here DEGRADES to an advisory notice and exit 0 — a fail-closed stance is wrong for a workflow notifier, and SessionStart cannot block anyway. Effort stays verifiable jq-free via `$CLAUDE_EFFORT`; a missing payload `.model` becomes the `VERIFY-SESSION-CONFIG-003` degraded notice, never a silent pass.

**Precedence + master-activation.** This hook layers onto the same precedence chain as the `block-*` hooks (highest first): `CLAUDE_HOOK_BYPASS` → **master-enable** → `.verify-session-config-mode` → rule-eval. It is governed as a **workflow-class** hook — it sources `lib/master-enable.sh` and calls `master_enable_gate workflow`, so a master-OFF workspace makes it inert (`exit 0`). A missing lib is fail-toward-current-behavior (the hook keeps its advisory mode path — a read failure never disables the verifier). See [bypass-mode-readiness.md § Master Activation Layer](../bypass-mode-readiness.md) for the durable opt-in switch, the workflow-vs-security/floor class semantics, and the security/floor exclusion this workflow hook honors; and [bypass-mode-readiness.md § CLAUDE_HOOK_BYPASS — Escape Hatch Usage](../bypass-mode-readiness.md) for the per-session operator escape it honors.

**Expected values read canonically (no shadow-SSOT, no hardcode).** The expected model is the accept-set `{ default_spoke_model, chip_model }` read from the canonical [`platform-config.toml`](../../config/platform-config.toml.template) `[spoke_runtime]` surface the SAME way `deploy.sh`'s `resolve_platform_config` reads it — the `opus` used when a field is unresolved at every rung is the resolver Rule-2 consumer-fallback (identical to Check 27's), NOT a transitional inline pin. The expected effort is the immutable, name-agnostic `max` directive: `[spoke_runtime]` deliberately stores no effort field (a stored value would shadow-SSOT the directive and drift), so the expected constant IS the directive. Per [ADR-094](../../ADRs/ADR-094-spoke-model-effort.md), which establishes the `[spoke_runtime]` canonical surface and frames this hook as its runtime-launch verification arm (the third reader of the one model/effort surface).

**Evidence-Grounding — the `VERIFY-*` RULE family.** `VERIFY-SESSION-CONFIG-NNN` is the first non-`BLOCK-` RULE family in the hook layer. The prefix is a deliberate naming-scheme extension: the hook VERIFIES (a non-blocking SessionStart notice) rather than BLOCKS, so a `BLOCK-` prefix would misdescribe its behavior. Authoring-time survey (`grep -rhoE '[A-Z][A-Z-]+-[0-9]{3}' core/hooks` + the fragment set) found only `BLOCK-*` prefixes prior. No separate ADR is warranted for the naming choice — it is a low-consequence, reversible extension of an existing convention, and the model/effort-posture architecture it serves is already recorded in [ADR-094](../../ADRs/ADR-094-spoke-model-effort.md), which names this hook as the runtime reader of that surface.

**Shakedown → enforce.** Ships warn-initial; flip `.verify-session-config-mode` warn → enforce only after a ≥3-day warn-log review (`verify-session-warn-log.jsonl`), per the registry [§ Shakedown → Enforce Transition Checklist](../bypass-mode-readiness.md). Because this hook has its OWN mode file, its flip is independent of the shared `.mode` cohort.
