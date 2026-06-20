<!-- reference-durability: allow-link -->
## `block-mcp-writes.sh` (BLOCK-MCP-001)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-mcp-writes.sh` |
| Matcher | `mcp__*` |
| Scope | MCP tools matching write-verb pattern, gated by allowlist |
| Mode | Warn-mode initial (shared `.claude/hooks/.mode`); flip-to-enforce per the [`§ Shakedown → Enforce Transition Checklist`](core/rules/bypass-mode-readiness.md) |

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-MCP-001 | MCP write-verb tool not in `.claude/mcp-write-allowlist.txt` |

This hook is tool-name-matched (`mcp__*`), not Bash-verb-anchored — the absolute-path-prefix bypass is structurally irrelevant to it. See [`§ Known Limitations`](core/rules/bypass-mode-readiness.md) for the MCP-tool-UUID-churn caveat (allowlist entries tied to specific server UUIDs need re-add after reinstall/reauth).
