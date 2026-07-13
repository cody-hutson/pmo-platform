#!/usr/bin/env bash
# extract-roster-needles.sh — generate PII needles from the operator-instance
# people-roster, feeding them into the localized-context needle file that
# core/hooks/git-pre-commit-pii.sh (Tier-1b) scans on every commit.
#
# Why: the people-roster (operator-instance, never committed) holds real names.
# This extractor appends those names/spellings to the gitignored needle file so a
# commit that accidentally contains a roster name is BLOCKED by the PII pre-commit
# hook. This is the "auto-generated needle list" the roster AC names — the
# extractor GENERATES needles from the roster; the hook is unchanged.
#
# Precondition (the block is conditional): a roster name is only blocked when the
# PII pre-commit hook is INSTALLED and in ENFORCE mode. Installing the hook and the
# warn->enforce flip are the operator's existing hook-deployment posture — out of
# this script's scope. This script only keeps the needle list current.
#
# Staleness window: this is OPERATOR-RUN. A roster name added since the last run is
# NOT yet a needle and would not be blocked until this is re-run. Re-run after any
# roster edit. The leg-C ambient-maintenance path auto-invokes this on roster-touch
# so the manual step disappears once that ships.
#
# Idempotent (append-only, deduped; never deletes). Read-only against the roster.
# Bash 3.2-safe (no associative arrays, no bash-5 tricks).

set -euo pipefail

# Resolve the roster + needle paths via the single resolver — never inline the
# instance-path-plus-leaf composition (lib-instance-path.sh is the one resolution
# site). Use the `pmo_people_roster()` accessor (v2.26/#2040) so this extractor
# honors the same overrides the seed sites do — including the `PMO_PEOPLE_ROSTER`
# override that a bare instance-path composition would have silently missed (#2074).
_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-instance-path.sh"
# shellcheck source=/dev/null
. "$_lib"

ROSTER="$(pmo_people_roster)"
NEEDLES="$(pmo_localized_needles)"

if [ ! -f "$ROSTER" ]; then
  echo "extract-roster-needles: no roster at $ROSTER — nothing to extract." >&2
  exit 0
fi
mkdir -p "$(dirname "$NEEDLES")"
touch "$NEEDLES"

# Pull the value of the two name-bearing fields (preferred_name, name_spelling)
# from the inline `{ value: "...", ... }` form. Skip unfilled placeholders
# ([UPPER_TOKENS]) and the `unknown` sentinel — those are not real names.
extract_names() {
  grep -E '^[[:space:]]*(preferred_name|name_spelling):' "$ROSTER" \
    | sed -E 's/.*value:[[:space:]]*"?([^"}]*)"?.*/\1/' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | grep -vE '^(unknown|\[[A-Z0-9_]+\])$' \
    | grep -vE '^[[:space:]]*$' || true
}

added=0
while IFS= read -r needle; do
  [ -n "$needle" ] || continue
  # whole-line, fixed-string dedup against the existing needle file
  if ! grep -qxF "$needle" "$NEEDLES"; then
    printf '%s\n' "$needle" >> "$NEEDLES"
    added=$((added + 1))
  fi
done <<EOF
$(extract_names)
EOF

echo "extract-roster-needles: ${added} new needle(s) appended to ${NEEDLES}" >&2
