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
# SECTION-BLIND-GREP ASSUMPTION (pinned, same as the PreToolUse hook): greps
# `^automation_level` line-anchored WITHOUT parsing the `[automation]` TOML
# section, because the key is unique repo-wide (C0 #322 / #1429 survey: 0 prior
# occurrences) — exactly as notify-version-skew.sh greps `^operator_github`
# without parsing `[identity]`. A second `automation_level` under a different
# section would need section-awareness.
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
level="recommend"
if [ -r "${OPERATOR_TOML}" ]; then
  parsed=$(grep -E '^automation_level' "${OPERATOR_TOML}" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  case "${parsed}" in off|recommend|bounded_auto) level="${parsed}" ;; esac
fi

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
