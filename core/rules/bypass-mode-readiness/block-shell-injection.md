<!-- reference-durability: allow-link -->
## `block-shell-injection.sh` (BLOCK-SHELL-INJECTION-001..002)

| Field | Value |
|---|---|
| Hook | `.claude/hooks/block-shell-injection.sh` |
| Matcher | Bash |
| Scope | Slash-command argument shell-injection vectors: script-execution followed by chain metachar leading into command verb, or script-execution with command substitution `$(...)` / backtick in argv |
| Mode | Warn-mode initial (shared `.claude/hooks/.mode`); flip-to-enforce per the [`§ Shakedown → Enforce Transition Checklist`](../bypass-mode-readiness.md) |

Added in the shell-injection shakedown release. Initial deploy state: warn-mode per `.claude/hooks/.mode`; flip-to-enforce after 2-3 release shakedown per the Shakedown → Enforce Transition Checklist.

### Rule registry

| Rule ID | Description |
|---|---|
| BLOCK-SHELL-INJECTION-001 | Script-execution token (`*.sh`, `bash <path>`, `sh <path>`, `~/.claude/*`, `/Users/<user>/.claude/*`) followed by command-chain metachar (`;`, `\|`, `&&`, `\|\|`) leading into a command verb (`curl`, `wget`, `nc`, `ncat`, `scp`, `ssh`, `sh`, `bash`, `eval`, `python`, `python3`, `node`, `ruby`, `perl`). Allowlist at `.claude/shell-injection-allowlist.txt`. |
| BLOCK-SHELL-INJECTION-002 | Script-execution with command substitution in argv (`$(...)` or backtick). Allowlist at `.claude/shell-injection-allowlist.txt`. |

**Coverage rationale:** The slash command surface (`~/.claude/commands/*.md` + upstream-vendored plugin commands under `~/.claude/plugins/marketplaces/*/plugins/*/commands/*.md`) renders into Bash commands at execute time. This hook scans the rendered command string, so it protects both pmo-deployed slash commands AND upstream-vendored plugin slash commands (which the operator cannot edit). It complements the source-level `$ARGUMENTS` quoting convention which only pmo-authored slash commands honor (verified at `deploy.sh --check` Check 30). Origin: the account-switcher Stage 7.5 audit M-1 finding flagged the slash-command surface as structurally injection-vulnerable; the in-release Tier 1 fix only patched the single account-switcher command, leaving the systemic gap closed by this hook.
