#!/usr/bin/env bash
# prime-autonomy-ceiling-cache.sh — SessionStart hook that resolves the
# session-stable automation_level dial ONCE and caches the numeric ceiling.
#
# WHY (FMF-1): the autonomy_level dial is session-stable (the operator does not
# change operator.toml mid-session). block-autonomy-ceiling.sh fires on EVERY
# mutation tool call; grep+awk-ing operator.toml on every call would be wasteful.
# This SessionStart hook resolves the dial once and writes the numeric ceiling to
# ${HOME}/.cache/pmo-platform/autonomy-ceiling. The PreToolUse hook reads that
# cache (a single file read). If this hook did not run (or a tool call lands
# before it), the PreToolUse hook falls back to a direct resolve, so the cache is
# a performance optimization, never a correctness dependency.
#
# SECTION-AWARE CEILING READ (supersedes the pinned SECTION-BLIND-GREP assumption,
# same as the PreToolUse hook). The ceiling is resolved by parsing the [automation]
# TOML section and matching `automation_level` with an `=` terminator, so (a) a
# same-named key under any other section and (b) any same-PREFIX key (e.g.
# automation_level_ci_autoresolve) are both unreachable. The prior reader was
# `grep -E '^automation_level'` with NO terminator, which matched the whole prefix
# class. Idiom lifted verbatim from lib/master-enable.sh _me_read_field.
# STRICT PARITY: the column-0 key anchor and the value extraction are byte-equivalent
# to the prior reader, so the ONLY changed inputs are the out-of-section ones, which
# previously resolved fail-OPEN and now resolve fail-restrictive.
#
# THIS HOOK IS THE ALWAYS-LIVE PATH, and that inverts the intuitive risk ordering.
# The PreToolUse sibling declares MASTER_ENABLE_CLASS="workflow", so its ceiling check
# is inert on the shipped master-OFF default; this SessionStart primer carries NO master
# gate and runs on every session regardless. Hardening only the sibling would therefore
# have left the live path unfixed AND created a cache-vs-live divergence, which is why
# the two are hardened identically rather than in priority order.
#
# TWIN COPY: block-autonomy-ceiling.sh carries resolve_level_direct() BYTE-IDENTICALLY —
# edit both or neither. tests/prime-autonomy-ceiling-cache.test.sh asserts the two
# resolve identically on every fixture, so copy drift is caught by behaviour, not by
# convention alone.
#
# Numeric ceiling map: off=0, recommend=1, bounded_auto=2.
# Defensive default: a missing/unreadable/unrecognized config → recommend (1) —
# a missing config never opens the gate to bounded_auto.
#
# Never blocks; SessionStart advisory only — on any error, fail silently (the
# PreToolUse hook's direct-resolve fallback covers a missing cache).
#
# Release: v2.07 (ambient-intake-automation)

set -u
# Errors must not block session start. Trap and exit 0 on any failure.
trap 'exit 0' ERR

readonly OPERATOR_TOML="${HOME}/.config/pmo-platform/operator.toml"
readonly CACHE_DIR="${HOME}/.cache/pmo-platform"
readonly CACHE_FILE="${CACHE_DIR}/autonomy-ceiling"

# Resolve the dial (default-on: recommend). A missing/unreadable config keeps the
# default; an unrecognized value also keeps the default.
#
# TWIN COPY — byte-identical to block-autonomy-ceiling.sh resolve_level_direct().
# Edit both or neither; this hook's test suite asserts they agree on every fixture.
# BEGIN TWIN: resolve_level_direct
resolve_level_direct() {
  # Fail-restrictive on EVERY failure path: unreadable config, absent awk, malformed
  # TOML, absent [automation], absent key, unrecognized value all keep this default.
  # The target is `recommend`, not `off` — this hook gates every mutation and carries the
  # highest false-positive risk in the suite, so the codebase's documented safe direction
  # is "never resolve HIGHER than configured", not "resolve as low as possible".
  local level="recommend"
  local parsed
  if [ -r "$OPERATOR_TOML" ] && [ -x /usr/bin/awk ]; then
    # shellcheck disable=SC2016  # awk field refs ($0) — single quotes intentional
    parsed="$(/usr/bin/awk -v sect='[automation]' '
      # Section header: string-compare (trimmed) against the target header, so a "[" in
      # a value can never be misread as a section and a dotted subtable header such as
      # [automation.experimental] is NOT the target section.
      /^[[:space:]]*\[/ {
        line = $0
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        insect = (line == sect) ? 1 : 0
        next
      }
      # Column-0 anchor (parity with the prior reader) + an "=" terminator (which the
      # prior reader lacked, and whose absence is what admitted the whole prefix class).
      insect == 1 && /^automation_level[[:space:]]*=/ {
        split($0, a, "=")
        v = a[2]
        gsub(/[" ]/, "", v)
        print v
        exit
      }
    ' "$OPERATOR_TOML" 2>/dev/null || true)"
    case "$parsed" in off|recommend|bounded_auto) level="$parsed" ;; esac
  fi
  /usr/bin/printf '%s' "$level"
}
# END TWIN: resolve_level_direct

level="$(resolve_level_direct)"

# Map to numeric ceiling.
case "${level}" in
  off) num=0 ;;
  recommend) num=1 ;;
  bounded_auto) num=2 ;;
  *) num=1 ;;
esac

# Write the cache atomically (tmp → mv). Best-effort; failure is non-fatal.
mkdir -p "${CACHE_DIR}" 2>/dev/null || exit 0
printf '%s\n' "${num}" > "${CACHE_FILE}.tmp" 2>/dev/null || exit 0
mv "${CACHE_FILE}.tmp" "${CACHE_FILE}" 2>/dev/null || { rm -f "${CACHE_FILE}.tmp" 2>/dev/null; exit 0; }

exit 0
