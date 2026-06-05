#!/usr/bin/env bash
# git-pre-commit-pii.sh — PII prevention guard for git commits.
#
# Blocks a commit whose STAGED ADDITIONS introduce private PII into the tracked
# corpus. Two tiers:
#
#   ALWAYS-BLOCK (every file): literal home-directory paths, phone numbers, and
#   any coworker name OR employer/org domain listed in the gitignored localized-
#   context needle file. None of these are ever legitimately tracked. The org
#   domain is intentionally NOT hardcoded here — a literal employer domain baked
#   into this tracked regex is itself a published leak (it names the operator's
#   employer to anyone who reads the hook), so it lives in the needle file.
#
#   PERSONAL-EMAIL (every file EXCEPT the accepted-home set): generic personal
#   email domains. The accepted homes — LICENSE, SECURITY.md, .github/CODEOWNERS,
#   .github/FUNDING.yml, core/ADRs/, release/ADRs/ — intentionally retain the
#   operator's contact addresses, so they are exempted here.
#
# Only ADDED lines are scanned, so scrubbing existing PII never trips the guard.
# The operator's public handle / legal name are intentionally NOT patterns here
# (kept in accepted homes; governed by deploy.sh Check 25 path-aware logic).
#
# Install:  ln -sf ../../core/hooks/git-pre-commit-pii.sh .git/hooks/pre-commit
# Bypass:   CLAUDE_HOOK_BYPASS=1 git commit ...
# Needles:  ${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/localized-context-needles.txt
set -uo pipefail

[[ "${CLAUDE_HOOK_BYPASS:-0}" == "1" ]] && exit 0

# Tier 1 — always-block patterns (every staged file).
always='/Users/[a-z][a-z0-9._-]+/|[0-9]{3}-[0-9]{3}-[0-9]{4}'
added_all="$(git diff --cached --no-color -U0 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
hits="$(printf '%s\n' "$added_all" | grep -inE "$always" || true)"

# Tier 1b — coworker / org needles (gitignored instance file), every file.
needles="${PMO_LOCALIZED_NEEDLES:-${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/localized-context-needles.txt}"
if [[ -r "$needles" ]]; then
  cleaned="$(grep -vE '^[[:space:]]*(#|$)' "$needles" || true)"
  if [[ -n "$cleaned" ]]; then
    nhits="$(printf '%s\n' "$added_all" | grep -inFf <(printf '%s\n' "$cleaned") || true)"
    [[ -n "$nhits" ]] && hits="$(printf '%s\n%s\n' "$hits" "$nhits" || true)"
  fi
fi

# Tier 2 — personal-email patterns, EXCLUDING accepted-home files.
pmail='@(gmail|ymail|yahoo|outlook|hotmail|icloud|proton(mail)?)\.com'
added_nonhome="$(git diff --cached --no-color -U0 -- . \
  ':(exclude)LICENSE' ':(exclude)SECURITY.md' ':(exclude).github/CODEOWNERS' \
  ':(exclude).github/FUNDING.yml' ':(exclude)core/ADRs/*' ':(exclude)release/ADRs/*' \
  2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
ehits="$(printf '%s\n' "$added_nonhome" | grep -inE "$pmail" || true)"
[[ -n "$ehits" ]] && hits="$(printf '%s\n%s\n' "$hits" "$ehits" || true)"

hits="$(printf '%s\n' "$hits" | grep -vE '^[[:space:]]*$' || true)"
if [[ -n "$hits" ]]; then
  {
    echo "──────────────────────────────────────────────────────────────"
    echo "BLOCKED: PII pre-commit guard found private data in staged additions:"
    printf '%s\n' "$hits" | sed 's/^/   /' | head -25
    echo ""
    echo "Replace with a token ([OPERATOR_*]) or \$HOME / config resolution,"
    echo "or set CLAUDE_HOOK_BYPASS=1 to bypass for an intentional case."
    echo "──────────────────────────────────────────────────────────────"
  } >&2
  exit 1
fi
exit 0
