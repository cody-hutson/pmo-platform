<!-- reference-durability: allow-link -->
## `block-egress.sh` (BLOCK-EGRESS-001..013)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-egress.sh` |
| Matcher | Bash, WebFetch |
| Scope | Credential reads via Bash, network upload (curl/wget/gh gist), network tools (nc/scp/ssh), WebFetch domain allowlist |
| Mode | Warn-mode initial (shared `.claude/hooks/.mode`); flip-to-enforce per the [`§ Shakedown → Enforce Transition Checklist`](../bypass-mode-readiness.md) |

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-EGRESS-001 | Subprocess read of credential dirs (`~/.ssh`, `~/.aws`, `~/.config/gh`) |
| BLOCK-EGRESS-002 | Subprocess read of `.env` variants / SSH private keys / `*.pem` / `*.key` (`.env.example` allowed) |
| BLOCK-EGRESS-003 | `base64` encoding of credential dirs |
| BLOCK-EGRESS-004 | `curl -X POST` / `-d` / `-F` / `-T` to non-allowlisted host |
| BLOCK-EGRESS-005 | `wget --post-data` / `--post-file` |
| BLOCK-EGRESS-006 | `gh gist create` (unconditional) |
| BLOCK-EGRESS-007 | `gh api -X POST/PUT/PATCH/DELETE` to non-allowlisted path |
| BLOCK-EGRESS-008 | `nc` / `ncat` |
| BLOCK-EGRESS-009 | `scp` to remote target |
| BLOCK-EGRESS-010 | `rsync` to remote target |
| BLOCK-EGRESS-011 | `ssh` to non-allowlisted host |
| BLOCK-EGRESS-012 | WebFetch to `file://` / `localhost` / `127.0.0.1` |
| BLOCK-EGRESS-013 | WebFetch to non-allowlisted domain |

See [`§ Absolute-Path-Aware Verb Anchor`](../bypass-mode-readiness.md) — the Bash-branch egress verbs compose with the canonical anchor; the WebFetch-branch rules (BLOCK-EGRESS-012 / -013) are tool-name-matched, not verb-anchored.
