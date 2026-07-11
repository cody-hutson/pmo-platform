# shellcheck shell=bash
# dep-resolve.sh — shared dependency resolution for pmo-platform PreToolUse security hooks.
#
# SOURCED, never executed. No shebang: this file only defines functions.
#
# WHY THIS EXISTS (GHSA-9cjm-v22x-4x33)
# ------------------------------------
# Every security hook needs `jq` to parse its tool-call JSON. Hooks pin
# PATH=/usr/bin:/bin for tamper resistance, but jq is NOT a macOS system binary —
# a documented `brew install jq` lands it at /opt/homebrew/bin/jq (Apple Silicon)
# or /usr/local/bin/jq (Intel), never /usr/bin/jq. The historical hooks hard-coded
# JQ=/usr/bin/jq and `exit 0` (FAIL-OPEN) when it was absent, silently disabling
# the whole PreToolUse perimeter. The resolution logic lived inline in every hook,
# so the class could (and did) drift. This helper is the ONE place absolute-path
# dependencies are resolved, so that can never happen again.
#
# SECURITY CONTRACT
# -----------------
#   1. Resolve from a FIXED absolute-path allowlist only. NEVER widen $PATH — doing
#      so would re-introduce the very PATH-hijack the pin exists to prevent.
#   2. PREFER a root-owned (uid 0) binary. Homebrew bin dirs are group-writable, so a
#      user-owned jq is a weaker trust oracle; fall back to it only when no root-owned
#      candidate exists (otherwise brew-only hosts could never run the hooks at all).
#   3. resolve_* NEVER exits — it returns a path or empty string, so the caller can
#      let `.mode=off` and CLAUDE_HOOK_BYPASS short-circuit FIRST, then fail CLOSED.
#   4. deny_missing_dep is the single fail-closed exit (exit 2) with an actionable
#      message. Callers MUST invoke it (or an equivalent exit 2) when resolution fails
#      — never fall through to `exit 0`.

# _dr_resolve_tool CANDIDATE...  — echo the best candidate path (root-owned first,
# else first executable of any owner), or nothing. Never exits.
_dr_resolve_tool() {
  _dr_fallback=""
  for _dr_cand in "$@"; do
    if [ -x "$_dr_cand" ]; then
      [ -z "$_dr_fallback" ] && _dr_fallback="$_dr_cand"
      # stat -f %u is BSD/macOS; stat -c %u is GNU/Linux. Try BSD first (pinned PATH
      # resolves /usr/bin/stat = BSD on macOS), then GNU, then give up on ownership.
      _dr_owner="$(/usr/bin/stat -f '%u' "$_dr_cand" 2>/dev/null || /usr/bin/stat -c '%u' "$_dr_cand" 2>/dev/null || echo -1)"
      if [ "$_dr_owner" = "0" ]; then
        printf '%s' "$_dr_cand"
        return 0
      fi
    fi
  done
  [ -n "$_dr_fallback" ] && printf '%s' "$_dr_fallback"
  return 0
}

# resolve_jq — echo the path to the best jq, or nothing. Never exits.
resolve_jq() {
  _dr_resolve_tool /usr/bin/jq /opt/homebrew/bin/jq /usr/local/bin/jq
}

# resolve_python3 — echo the path to the best python3, or nothing. Never exits.
resolve_python3() {
  _dr_resolve_tool /usr/bin/python3 /opt/homebrew/bin/python3 /usr/local/bin/python3
}

# deny_missing_dep DEP HOOK_NAME [PRINTF_BIN] — emit a fail-closed BLOCKED message
# naming the missing dependency, then exit 2. A security control that cannot evaluate
# its input must DENY, never allow (GHSA-9cjm-v22x-4x33).
deny_missing_dep() {
  _dr_dep="$1"; _dr_hook="$2"; _dr_printf="${3:-/usr/bin/printf}"
  "$_dr_printf" '[CLAUDE-HOOK:%s:DEPENDENCY-MISSING] BLOCKED (fail-closed): %s not found on the pinned tool path. Install it in your terminal (brew install %s), then retry. To stand this hook down, set its .mode to off (mode-gated hooks) or export CLAUDE_HOOK_BYPASS=1.\n' "$_dr_hook" "$_dr_dep" "$_dr_dep" >&2
  exit 2
}
