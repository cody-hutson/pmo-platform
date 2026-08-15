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
#   5. This file MUST stay side-effect-free at its top level. It is evaluated TWICE per
#      hook invocation — once out of process for attestation, once in process for real
#      (see the CONTRACT TOKEN block below). A top-level side effect would run twice,
#      and a top-level `exit` is precisely the corruption the attestation exists to
#      detect. Definitions and the contract assignment only.

# CONTRACT TOKEN (#5071 / ADR-135). Every carrier captures this value `readonly` BEFORE
# sourcing this file and requires it back afterwards, so a truncated, empty, stale or
# self-exiting copy cannot pass. Bump `vN` ONLY on a breaking contract change (a resolve_*
# / deny_* signature or semantic change) and edit every carrier in the SAME commit —
# check-hook-dep-hardening.sh CHECK-6 fails the build if they disagree. A non-breaking
# edit does NOT bump it.
DEP_RESOLVE_CONTRACT="dep-resolve/v1"

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

# deny_missing_primitive PRIMITIVE HOOK_NAME [PRINTF_BIN] — the internal-dependency
# twin of deny_missing_dep (GHSA-g9g6-28c9-vrx5). Where deny_missing_dep covers an
# EXTERNAL tool (jq/python3) resolved from $PATH, this covers a co-shipped INTERNAL
# primitive (path-leak-patterns.sh, positional-issueref.awk) that ships beside the hook
# and is placed there by docs/scripts/setup-workspace.sh. A missing primitive in a
# correct install cannot happen; when it does, the install is tampered or partial, and a
# security control that cannot run its check must DENY in enforce, never fall through to
# exit 0. Remediation is a REINSTALL of the hook bundle — not `brew install` — so the
# message differs from deny_missing_dep. Callers gate this on .mode = enforce; warn/off
# degrade to a note + exit 0, mirroring the jq posture.
deny_missing_primitive() {
  _dr_prim="$1"; _dr_hook="$2"; _dr_printf="${3:-/usr/bin/printf}"
  "$_dr_printf" '[CLAUDE-HOOK:%s:PRIMITIVE-MISSING] BLOCKED (fail-closed): co-shipped primitive %s is absent from this hook'"'"'s directory. Reinstall the hook bundle (re-run docs/scripts/setup-workspace.sh) to restore it. To stand this hook down, set its .mode to off or export CLAUDE_HOOK_BYPASS=1.\n' "$_dr_hook" "$_dr_prim" >&2
  exit 2
}
