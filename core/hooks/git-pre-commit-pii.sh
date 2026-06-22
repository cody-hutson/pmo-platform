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
# Needles:  resolved by core/deploy/lib-instance-path.sh (pmo_localized_needles);
#           default <instance-dir>/localized-context-needles.txt, override via
#           PMO_LOCALIZED_NEEDLES / PMO_INSTANCE_PATH.
#
# Fail-closed posture (#1830 Part 4): when the resolved needle path sits inside
# an EXISTING operator-instance dir but the needle file itself is missing/unfilled,
# the guard FAILS CLOSED (the operator HAS an instance but left the needle surface
# empty — the silent-fail-open case this story closes). A genuinely-unconfigured
# checkout (no instance dir at all — a fresh clone) only WARNs, so onboarding is
# not blocked. The fail-closed flip is gated by a `.mode` file (warn|enforce|off)
# mirroring the bypass-mode-readiness shakedown convention: warn-mode-initial,
# flip to enforce after warn-log review.
set -uo pipefail

[[ "${CLAUDE_HOOK_BYPASS:-0}" == "1" ]] && exit 0

# --- Resolve the operator-instance / needle path via the single resolver ---
# The hook is symlinked into .git/hooks/pre-commit, so $0 points at the symlink;
# resolve it to the real core/hooks/ location, then source the sibling resolver
# in core/deploy/. If sourcing fails for any reason, fall back to inline default
# functions so a missing lib can never hard-break commits.
_pii_self="${BASH_SOURCE[0]:-$0}"
# Follow one symlink level (the canonical install is a single symlink).
if [[ -L "$_pii_self" ]]; then
  _pii_link="$(readlink "$_pii_self" 2>/dev/null || true)"
  if [[ -n "$_pii_link" ]]; then
    case "$_pii_link" in
      /*) _pii_self="$_pii_link" ;;
      *)  _pii_self="$(cd "$(dirname "$_pii_self")" 2>/dev/null && cd "$(dirname "$_pii_link")" 2>/dev/null && pwd)/$(basename "$_pii_link")" ;;
    esac
  fi
fi
_pii_hook_dir="$(cd "$(dirname "$_pii_self")" 2>/dev/null && pwd -P || true)"
_pii_lib="${_pii_hook_dir}/../deploy/lib-instance-path.sh"
if [[ -r "$_pii_lib" ]]; then
  # shellcheck source=../deploy/lib-instance-path.sh disable=SC1090,SC1091
  source "$_pii_lib"
fi
if ! command -v pmo_localized_needles >/dev/null 2>&1; then
  # Lib unreachable: the single resolver is the ONLY home for the path default
  # (AC1 / AC5) — this hook never re-derives it inline. Degrade to empty
  # resolution; downstream this resolves to the "unconfigured" branch (warn, do
  # not block) rather than fabricating a path or silently scanning nothing.
  pmo_instance_path() { printf '%s\n' "${PMO_INSTANCE_PATH:-}"; }
  pmo_localized_needles() { printf '%s\n' "${PMO_LOCALIZED_NEEDLES:-}"; }
fi

# Tier 1 — always-block patterns (every staged file).
always='/Users/[a-z][a-z0-9._-]+/|[0-9]{3}-[0-9]{3}-[0-9]{4}'
added_all="$(git diff --cached --no-color -U0 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
hits="$(printf '%s\n' "$added_all" | grep -inE "$always" || true)"

# Tier 1b — coworker / org needles (gitignored instance file), every file.
needles="$(pmo_localized_needles)"
instance_dir="$(pmo_instance_path)"

# Resolve the fail-closed mode (warn|enforce|off). Operator-instance file first
# (consistent with deploy.sh's per-check .mode resolution), then a .claude/hooks/
# fallback, defaulting to warn-mode-initial per the shakedown convention.
needle_mode="warn"
for _mode_file in "${instance_dir}/git-pre-commit-pii.mode" "$_pii_hook_dir/git-pre-commit-pii.mode"; do
  if [[ -f "$_mode_file" ]]; then
    _m="$(tr -d '[:space:]' < "$_mode_file" 2>/dev/null || true)"
    case "$_m" in enforce|warn|off) needle_mode="$_m"; break ;; esac
  fi
done

# Determine whether the needle file carries any active (non-comment) entry.
needle_filled=0
needle_cleaned=""
if [[ -r "$needles" ]]; then
  needle_cleaned="$(grep -vE '^[[:space:]]*(#|$)' "$needles" 2>/dev/null || true)"
  [[ -n "$needle_cleaned" ]] && needle_filled=1
fi

if [[ "$needle_filled" == "1" ]]; then
  # Configured + filled → scan staged additions against the needles.
  nhits="$(printf '%s\n' "$added_all" | grep -inFf <(printf '%s\n' "$needle_cleaned") || true)"
  [[ -n "$nhits" ]] && hits="$(printf '%s\n%s\n' "$hits" "$nhits" || true)"
elif [[ "$needle_mode" != "off" ]]; then
  # Two distinct unconfigured states, distinct messages (#1830 Part 4).
  if [[ -d "$instance_dir" ]]; then
    # CONFIGURED-BUT-MISSING: the operator HAS an instance dir but the needle
    # surface is missing or holds only comments — fail closed (this is the
    # silent-degrade case the story closes).
    {
      echo "──────────────────────────────────────────────────────────────"
      if [[ -e "$needles" ]]; then
        echo "BLOCKED: localized-context needle file is present but UNFILLED:"
      else
        echo "BLOCKED: localized-context needle file is MISSING:"
      fi
      echo "   $needles"
      echo ""
      echo "The operator-instance dir exists ($instance_dir) but the coworker/org"
      echo "needle surface is empty, so the PII guard's organizational-identity tier"
      echo "is silently disabled. Fill it (one needle per line) from the template:"
      echo "   core/config/localized-context-needles.txt.example"
      echo "or run install.sh / update.sh to scaffold it."
      echo ""
      echo "Bypass for an intentional commit: CLAUDE_HOOK_BYPASS=1 git commit ..."
      echo "Suppress during shakedown: set git-pre-commit-pii.mode to 'warn' or 'off'."
      echo "──────────────────────────────────────────────────────────────"
    } >&2
    if [[ "$needle_mode" == "enforce" ]]; then
      exit 1
    fi
    # warn-mode-initial: surface loudly but do not block.
    echo "[git-pre-commit-pii] WARN (.mode=warn): proceeding despite unfilled needle file." >&2
  else
    # UNCONFIGURED: no instance dir at all (fresh clone) — graceful warn only.
    {
      echo "[git-pre-commit-pii] NOTE: no operator-instance dir at $instance_dir;"
      echo "  organizational-identity (coworker/org) PII scanning is inactive."
      echo "  Generic PII patterns (home paths, phone, personal email) still enforced."
      echo "  Run install.sh / update.sh to scaffold the localized-context needle file."
    } >&2
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
