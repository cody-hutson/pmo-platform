<!-- reference-durability: allow-link -->
## `block-autonomy-ceiling.sh` (BLOCK-AUTONOMY-001..099)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-autonomy-ceiling.sh` |
| Matcher | Bash, Write, Edit, `mcp__.*` |
| Scope | Autonomy-tier ceiling enforcement: an irreducible Tier-0 always-block floor (governance-file writes + cross-domain bridge writes) plus a ceiling check that blocks an action whose required Autonomy Tier exceeds the resolved `[automation].automation_level`. Composes with (does not duplicate) the destructive / fs-boundary / rm safety hooks — it adds the autonomy-tier dimension they do not gate. |
| Mode | Split posture. The Tier-0 floor (`BLOCK-AUTONOMY-001`/`002`) is **always-block LIVE** — mode- AND level-independent (mirrors `block-destructive` / `block-rm-prefer-trash` permanence) for the payload-detectable classes only. The ceiling check (`BLOCK-AUTONOMY-003`) is gated by this hook's **OWN** mode file `.autonomy-mode` (warn / enforce / off), NOT the shared `.claude/hooks/.mode`; ships **warn-mode-initial** because it gates every mutation (highest false-positive risk in the suite). Permissive default: an unmapped action is treated at-or-below ceiling and ALLOWED. |

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-AUTONOMY-001 | Governance-file modification (Write/Edit) — resolved path matching `CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md`, any `SKILL.md`, `.claude/settings.json`, or any file under `.claude/hooks/` or `.claude/rules/`. Irreducible Tier-0 (operator-only per "No ungoverned changes"); always-blocks regardless of `automation_level` and without the worktree exemption `BLOCK-DESTRUCTIVE-019` carves out (governance edits are operator-irreducible regardless of cwd) |
| BLOCK-AUTONOMY-002 | Cross-domain bridge write (Write/Edit) — Layer separation: a `pmo-platform/` cwd writing into `projects/`, or a `projects/` cwd writing into `pmo-platform/`, detected by cwd-domain ↔ target-domain mismatch against the two domain roots under the workspace. Irreducible Tier-0; always-blocks regardless of `automation_level` |
| BLOCK-AUTONOMY-003 | Ceiling violation — the action's required Autonomy Tier (computed from a conservative declared-mapping table) EXCEEDS the resolved `[automation].automation_level` ceiling (effective = `min(ceiling, required)`). Mode-gated by `.autonomy-mode` (warn-initial); at/below the ceiling → allow |

### Posture & cache — block-autonomy-ceiling.sh

**Ceiling resolution (section-blind grep, pinned).** The ceiling read greps `^automation_level` line-anchored WITHOUT parsing the `[automation]` TOML section, because the key is unique repo-wide (the v2.07 ambient-intake C0 survey found 0 prior occurrences of `automation_level`) — exactly as `notify-version-skew.sh` greps `^operator_github` without parsing `[identity]`. If a second `automation_level` key is ever introduced under a different section, this resolution would need section-awareness.

**Cache (FMF-1).** The session-stable dial is resolved ONCE at SessionStart by the sibling `prime-autonomy-ceiling-cache.sh` hook, which writes the numeric ceiling to `${HOME}/.cache/pmo-platform/autonomy-ceiling`. This PreToolUse hook reads that cache (a single file read) rather than re-resolving `operator.toml` on every tool call. If the cache is absent/unreadable, it falls back to a direct resolve so the ceiling is never silently dropped.

**Enforcement-surface caveat (do NOT read as "now hard-enforced" unqualified).** The Tier-0 floor is LIVE always for the payload-detectable classes ONLY (governance-file + cross-domain bridge writes). Financial / account-creation / security-permission actions and the Stage 9 / Stage 12 gates are NOT mechanically detectable from a tool payload — they remain OPERATOR-IRREDUCIBLE by convention, not by this hook. The ceiling check is hard-enforced only after the operator flips `.autonomy-mode` from warn → enforce post-shakedown.

**Design source.** `core/standards/subagent-security-posture.md § 4 Hook Contract` (RESOLVED in v2.07 — this hook IS that contract's realization); the supersession of the original subagent-session-detection design is recorded in [`ADR-031`](../../ADRs/ADR-031-autonomy-ceiling-unified-payload-triggered-hook.md). See [`§ Warn-Mode Initial`](../bypass-mode-readiness.md) for the shakedown posture and [`§ CLAUDE_HOOK_BYPASS Escape Hatch`](../bypass-mode-readiness.md) for the operator escape semantics this hook honors.
