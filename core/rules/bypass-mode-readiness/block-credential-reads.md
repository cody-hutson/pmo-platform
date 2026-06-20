<!-- reference-durability: allow-link -->
## `block-credential-reads.sh` (BLOCK-CREDENTIAL-READ-001..006)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-credential-reads.sh` |
| Matcher | Read |
| Scope | Claude Read-tool access to ~/.ssh, ~/.aws, ~/.config/gh, .env variants, id_rsa, *.pem, *.key |
| Mode | Always-enforce (high-confidence, narrow rules, low false-positive risk; not gated by `.claude/hooks/.mode`) |

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-CREDENTIAL-READ-001 | Read of `~/.ssh/*` (allows `.pub` public keys) |
| BLOCK-CREDENTIAL-READ-002 | Read of `~/.aws/*` credentials |
| BLOCK-CREDENTIAL-READ-003 | Read of `~/.config/gh/*` auth config |
| BLOCK-CREDENTIAL-READ-004 | Read of `.env` variants (allows `.env.example` / `.env.sample` / `.env.template`) |
| BLOCK-CREDENTIAL-READ-005 | Read of SSH private keys outside `~/.ssh` |
| BLOCK-CREDENTIAL-READ-006 | Read of `*.pem` / `*.key` / `*.p12` / `*.pfx` / `*.keystore` |

This hook is Read-tool-matched, not Bash-verb-anchored — the absolute-path-prefix bypass is structurally irrelevant to it, and it performs no path normalization (regex/prefix matchers that need no symlink/`..` resolution). See [`§ Known Limitations`](core/rules/bypass-mode-readiness.md) for the ssh-agent-socket side-channel residual (this hook gates *file reads* of credential paths, not *use of a key already loaded into the OS ssh-agent socket*).
