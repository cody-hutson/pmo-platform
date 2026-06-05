---
title: Secrets-Handling Policy
purpose: Single design surface for how the workspace handles credentials, API keys, tokens, and personal data — categorization, storage matrix, gitignore policy, onboarding flow, rotation, failure modes, audit surface, and public-flip implications. Composes with (does NOT restate) bypass-mode-readiness.md (runtime enforcement), depersonalization-spec.md (PII token vocabulary), and public-repo-gitignore-template.md (gitignore baseline).
type: standards
composes_with: [bypass-mode-readiness.md, depersonalization-spec.md, public-repo-gitignore-template.md]
reversibility: CHEAP / Confidence HIGH
---

# Secrets-Handling Policy

## Purpose

This standard is the **policy substrate** for everything credential-shaped in the workspace. It answers the four questions every operator (and every audit) has to answer:

1. **What categories of secrets exist** in this workspace?
2. **Where does each category live** — env var, settings.local.json, OS keychain, `.env` file, or encrypted-at-rest?
3. **How does onboarding set each one up**, and how does an operator rotate it later?
4. **How do we audit** that no secret has accidentally escaped its category — into git history, public docs, or the wrong storage tier?

The policy is the **declaration**. The enforcement layers exist elsewhere:

| Layer | Owner | Role |
|---|---|---|
| **L4 — Policy substrate** | This document | What categories exist; where each lives; how rotation works |
| **L3 — Vulnerability reporting** | Root `SECURITY.md` | External vuln intake, response targets, scope |
| **L2 — Runtime enforcement** | `core/hooks/block-credential-reads.sh` + `core/rules/bypass-mode-readiness.md` | Hooks that block tool access to credential files |
| **L1 — Gitignore baseline** | `core/standards/public-repo-gitignore-template.md` + `.gitignore` | What stays out of git |

Each layer references this one. This one references none of them by their enforcement mechanics — only by their existence.

---

## §1 Categorization

The workspace handles seven categories of secrets. Every credential-shaped value an operator stores must map to exactly one.

| # | Category | Examples | Sensitivity |
|---|---|---|---|
| C1 | **AI provider credentials** | Anthropic API key, OpenAI key (if used), provider-specific tokens | High — revocable; rotating mid-session breaks running agents |
| C2 | **VCS / code-hosting credentials** | GitHub PAT, `gh` CLI auth, SSH private keys (`~/.ssh/id_*`) | High — grants push/admin access to repos |
| C3 | **MCP server tokens** | Atlassian API tokens, Smartsheet tokens, integration-specific OAuth tokens | Medium — scope-limited per integration |
| C4 | **Cloud provider credentials** | AWS access keys (`~/.aws/credentials`), GCP service account JSON, Azure SP secrets | Critical — typically grants billable resource control |
| C5 | **Org / project-specific data** | NDA-covered context, client material, project-specific tokens | Varies — controlled by source agreement |
| C6 | **Personal data** | Operator name/email outside `[OPERATOR_NAME]`-tokened files, contact info, PII | Per the depersonalization spec — never in `core/`, `release/`, `operations/`, `packages/` source |
| C7 | **Tooling tokens** | Notion, Slack, Linear, custom-CLI tokens for non-MCP tooling | Medium — scope-limited per tool |

Anything that doesn't fit one of these seven is a **categorization gap** — the policy must be amended before the value is stored. Storing an uncategorized secret bypasses every downstream control (no defined gitignore, no defined audit pattern, no defined rotation procedure).

---

## §2 Storage Matrix

Five storage locations, with declared "right home" per category:

| Storage | Description | Right home for |
|---|---|---|
| **Env var** | Process-local environment, exported via shell rc or per-launch | C1 (Anthropic API key in `ANTHROPIC_API_KEY`); C3 transient values |
| **`~/.claude/settings.local.json`** | Local Claude Code overrides — git-ignored | C3 (per-MCP token blocks); C7 (tool-specific permissions) |
| **OS keychain** | macOS Keychain / Linux secret-service / Windows Credential Manager | C2 (`gh` CLI uses macOS Keychain by default); C4 (AWS CLI `keyring` integration if configured) |
| **`.env` file (gitignored)** | Per-project `.env` at the project root | C3 batch values; C5 ephemeral project tokens. Never C1/C2/C4. |
| **Encrypted-at-rest** | `age`, `gpg`, or platform-native encrypted store | C5 long-lived NDA material; C6 archival personal data |

**Mapping rule:** Every category MUST have at least one declared storage location. If a category appears in two locations (e.g., C3 in both `settings.local.json` and `.env`), the policy MUST declare which is canonical and why.

| Category | Canonical storage | Acceptable alternative | Forbidden |
|---|---|---|---|
| C1 AI provider | Env var | Encrypted-at-rest (per-launch sourced) | Settings JSON, `.env` committed |
| C2 VCS / code-hosting | OS keychain (`gh`) + `~/.ssh/` (SSH) | None — `gh auth login` is the entry point | `.env`, settings JSON, repo files |
| C3 MCP server tokens | `~/.claude/settings.local.json` (Claude-managed MCP block) | Env var for transient testing | Repo files, public gists |
| C4 Cloud provider | OS keychain or `~/.aws/credentials` | Vendor SDK default | `.env`, settings JSON, repo files |
| C5 Org / project data | Encrypted-at-rest | `.env` (gitignored) for transient project tokens only | Repo files, screenshots, public chat |
| C6 Personal data | Outside the workspace OR encrypted-at-rest | None — never inline in tracked files | Any tracked file in `core/`, `release/`, `operations/`, `packages/` |
| C7 Tooling tokens | `~/.claude/settings.local.json` or per-tool config dir | Env var | Repo files |

---

## §3 Gitignore Policy

Every gitignored path must trace to a category. Conversely, every category that COULD leak to git MUST have explicit gitignore coverage.

**Current `.gitignore` coverage (verified):**

| Category | `.gitignore` entry | Status |
|---|---|---|
| C2 VCS / SSH | (implicit — `~/.ssh/` is outside the repo) | n/a in-repo |
| C3 MCP tokens | `.claude/settings.local.json` | Covered |
| C4 Cloud | (implicit — `~/.aws/` is outside the repo) | n/a in-repo |
| C5 Project data | `projects/`, `portfolio/`, `steering-committee/` | Covered |
| C6 Personal data | `personal/`, `pmo-instance/` | Covered |
| C7 Tooling | `.claude/settings.local.json` | Covered |

**Gap closed by this PR:**

| Category | New `.gitignore` entry | Allowed exceptions |
|---|---|---|
| C3, C5 | `.env`, `.env.*` | `.env.example`, `.env.template`, `.env.sample` (kept tracked — they're public-facing schemas) |

**Maintenance rule:** Any new category added to §1 MUST be evaluated against `.gitignore` in the same change. Any new `.gitignore` entry MUST cite the category it covers in a same-line or above-line comment.

---

## §4 Onboarding Flow

`docs/scripts/setup-workspace.sh` is the operator's first contact with credential setup. The onboarding flow MUST:

1. **Prompt per category** — Detect which categories the operator needs (e.g., "Will you use the Anthropic API directly, or only via the Claude desktop app?") and prompt only for the ones in scope.
2. **Store per the matrix** — Each prompted value goes into its canonical storage location (§2), not "wherever is convenient at install time."
3. **Verify after store** — Each stored value is verified by a category-appropriate health check (e.g., `gh auth status` for C2, `anthropic --version` returning 0 with the key for C1).
4. **Never echo** — Captured values are passed via stdin or env, never echoed to the terminal or written to a log.
5. **Idempotent** — Re-running the script detects already-populated values and skips re-prompt (with an opt-in `--reset-secrets` flag for explicit rotation).

The setup-workspace.sh implementation of this flow is **owned by a follow-up ticket** (see Notes); this section is the policy declaration the script implements against.

---

## §5 Rotation

| Category | Rotation trigger | Procedure |
|---|---|---|
| C1 AI provider | Quarterly OR suspected leak | Revoke at provider console; `unset` env var; re-source from new value; restart agent sessions |
| C2 VCS | Quarterly OR suspected leak | Rotate at provider (GitHub PAT page); `gh auth refresh`; SSH key regenerated + re-added to provider |
| C3 MCP | Per-integration cadence (varies); on suspected leak | Revoke at integration; update `~/.claude/settings.local.json`; restart MCP-using sessions |
| C4 Cloud | Per provider policy (often 90 days); on suspected leak | Rotate at provider (IAM); update keychain or `~/.aws/credentials`; verify with provider CLI |
| C5 Project | Per source agreement; on project close | Revoke at source; purge `.env`/encrypted-at-rest entries; verify against §7 audit |
| C6 Personal | n/a — personal data is not "rotated"; it's owned | Inventory periodically; ensure no drift into tracked files |
| C7 Tooling | Per-tool cadence; on suspected leak | Revoke at tool; update storage; restart tool-using sessions |

**General rule:** Rotation procedures MUST be **runnable from documentation alone**. If a procedure requires tribal knowledge ("ask the operator"), it's a documentation gap, not an operational reality.

---

## §6 Failure Modes

| Failure mode | Symptom | Recovery |
|---|---|---|
| **Missing credential** | Tool fails with "unauthorized" or "no key" | Re-run setup-workspace.sh with `--reset-secrets <category>`; verify per §4.3 |
| **Expired credential** | Provider returns 401 / "token expired" | Rotate per §5; treat as scheduled rotation cadence event |
| **Leaked credential** (suspected) | Anomaly in provider usage logs; credential found in unexpected location | **Rotate immediately** per §5; run §7 audit greps over full history; if leak landed in git, see §6.1 |
| **Leaked credential to git** | `git log` audit finds matching pattern | Rotate immediately; if repo is private, force-push history rewrite is OPTIONAL (the secret is already revoked); if repo is public, history rewrite is REQUIRED + provider notification |
| **Wrong-tier storage** | Audit finds a C4 cred in `.env` instead of OS keychain | Move to canonical tier (§2); rotate (the on-disk copy may have been backed up) |
| **Categorization gap** | An operator stores a value that doesn't fit C1–C7 | Stop; amend §1 to add the category OR re-classify into an existing one; only then store |

### §6.1 Leaked-to-git recovery

If a leak landed in git history on a **public** repo:

1. **Rotate first** — the credential is already public; minutes matter
2. **Notify provider** if their policy requires it (e.g., GitHub PAT auto-revocation on push)
3. **History rewrite** (`git filter-repo` or `git filter-branch`) is REQUIRED to remove the value from clones — but accept that any clone made between leak and rewrite still contains the value
4. **Document** in the release log as a lessons-learned entry

---

## §7 Audit Surface

The policy MUST be auditable from the command line. The audit greps below are RUN AS-IS — if they produce non-empty output, investigation is required.

### §7.1 Tracked-file audit

Each audit below: **non-empty output = investigate**; empty output = PASS.

```bash
# Any tracked .env-shaped file (excluding allowed templates)
git ls-files | grep -E '(^|/)\.env($|\.[^/]+$)' | grep -vE '\.(example|template|sample)$'

# Any tracked file containing an SSH private-key header
git grep -l -E 'BEGIN (OPENSSH |RSA |EC |DSA )?PRIVATE KEY' -- ':!core/standards/secrets-handling-policy.md'

# Any AWS-shaped key in tracked content
git grep -E 'AKIA[0-9A-Z]{16}' -- ':!core/standards/secrets-handling-policy.md'
```

### §7.2 Full-history audit

```bash
# Pattern sweep across all branches and all history.
# Capture-then-check pattern to avoid the head/pipe exit-code trap.
result=$(git log --all -p -G '(api[_-]?key|password|secret|token|bearer)[\"'"'"']?\s*[:=]\s*[\"'"'"'][^\"'"'"']+' \
  -- ':!core/standards/secrets-handling-policy.md')
if [ -z "$result" ]; then
  echo "PASS: no credential-shaped strings in history"
else
  printf '%s\n' "$result" | head -200
  echo "INVESTIGATE: matches above; full output suppressed at 200 lines"
fi
```

### §7.3 Local-file audit (outside git)

```bash
# Verify gitignored secret files are NOT staged
git status --ignored | grep -E '^\?\? .*\.env($|\.)' && echo "WARN: .env present but untracked — confirm intentional" || true

# Verify settings.local.json is git-ignored (not just untracked)
git check-ignore .claude/settings.local.json && echo "PASS: settings.local.json properly ignored" || echo "FAIL: settings.local.json NOT ignored"
```

These audits are intentionally textual — no external services, no API calls. The audit surface MUST remain runnable from any clone without network or provider auth.

---

## §8 Public-Flip Implications

When this repo (or any sibling) flips from private to public, the public-facing artifact MUST satisfy:

1. **Zero tracked secrets** — §7.1 returns PASS for every category
2. **Zero history-resident secrets** — §7.2 returns PASS (or, if any pattern matches, the secret has been rotated AND a documented decision exists to accept the history-resident copy as defanged)
3. **Templates ship; values stay local** — `.env.example`, `.env.template`, `.env.sample`, `core/config/operator.toml.template`, and `~/.claude/settings.local.json` ARE NOT in the public artifact's tracked content (settings.local.json) or ARE present as schema-only templates (the `.template` and `.example` variants)
4. **No category leaks via comments** — Documentation comments and PR bodies in the public artifact contain no actual credentials, no operator-instance paths, no operator name (per the depersonalization spec)
5. **Audit greps survive the flip** — The audits in §7 MUST be runnable on the public artifact too; they MAY produce different output (no operator-instance content to audit) but the commands themselves stay green

The pre-flip security audit (the per-repo ticket pattern) is the gate that verifies (1)–(5). This policy is what that audit audits against.

---

## Related

- [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) — Runtime hooks that enforce L2 (block credential reads/writes via Claude tools)
- [`depersonalization-spec.md`](depersonalization-spec.md) — Token vocabulary for `[OPERATOR_NAME]`, `[COMPANY_X]`, `[OPERATOR_EMAIL]` substitution in tracked files
- [`public-repo-gitignore-template.md`](public-repo-gitignore-template.md) — Gitignore baseline for public-facing artifacts
- Root [`SECURITY.md`](../../SECURITY.md) — Vulnerability reporting protocol (L3)
- `core/ADRs/ADR-010-secrets-handling-policy-substrate.md` — Architectural decision record for this policy's location and scope

## Notes

This policy is the **substrate**. Integration into `docs/scripts/setup-workspace.sh` (the onboarding implementation of §4) lands in a follow-up ticket — separated to keep the substrate landable independently and to let the pre-flip audit consume the declarations without waiting on the script-level implementation.
