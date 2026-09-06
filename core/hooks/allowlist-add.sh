#!/bin/bash
# allowlist-add.sh — atomic marker-aware add helper for .claude/*-allowlist.txt files
#
# Part of: the bypass-permissions-readiness hardening.
#
# Usage:
#   ./.claude/hooks/allowlist-add.sh <allowlist-file> <entry> [--reason "why"]
#
# Validation:
#   - Allowlist file must be one of the known, hook-managed allowlists
#   - Entry must not be blank, must not already be present
#   - The write is atomic (mv-based)
#   - All additions are logged to .claude/hooks/allowlist-additions.log
#
# Placement:
#   - Where the target carries an OPERATOR ADDITIONS region, the entry is
#     inserted immediately BEFORE the END marker, inside the span
#     compose.py::extract_operator_additions() preserves — so the entry survives
#     the next update-path regeneration.
#   - Where the target has no such region, the entry is appended at end of file
#     (the historical behavior). A target that carries marker text but no region
#     compose.py will honour gets the append AND a warning on stderr.
#   - The helper never synthesizes a marker fence; compose.py owns the fence.

set -euo pipefail

export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly AWK="/usr/bin/awk"
readonly DATE="/bin/date"
readonly PRINTF="/usr/bin/printf"
readonly MKTEMP="/usr/bin/mktemp"
readonly CAT="/bin/cat"
readonly MV="/bin/mv"

readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly CLAUDE_DIR="$(cd "${HOOK_DIR}/.." && pwd -P)"
readonly ADDITIONS_LOG="${HOOK_DIR}/allowlist-additions.log"

# Known allowlists (relative to $CLAUDE_DIR). Prevents appending to arbitrary files.
readonly KNOWN_ALLOWLISTS=(
  "${CLAUDE_DIR}/mcp-write-allowlist.txt"
  "${CLAUDE_DIR}/egress-allowlist.txt"
  "${CLAUDE_DIR}/webfetch-allowlist.txt"
  "${CLAUDE_DIR}/ssh-allowlist.txt"
  "${CLAUDE_DIR}/script-execution-allowlist.txt"
  "${CLAUDE_DIR}/skill-editor-exemption-list.txt"
  "${CLAUDE_DIR}/shell-injection-allowlist.txt"
  "${CLAUDE_DIR}/fs-boundary-allowlist.txt"
  "${CLAUDE_DIR}/scope-segregation-allowlist.txt"
)

usage() {
  "$PRINTF" 'Usage: %s <allowlist-file> <entry> [--reason "why"]\n' "$0"
  "$PRINTF" '\nKnown allowlists:\n'
  for a in "${KNOWN_ALLOWLISTS[@]}"; do
    "$PRINTF" '  - %s\n' "$a"
  done
  exit 1
}

[ $# -ge 2 ] || usage

ALLOWLIST_FILE="$1"
ENTRY="$2"
REASON="${4:-(no reason given)}"

# Resolve allowlist file to absolute path
if [ -f "$ALLOWLIST_FILE" ]; then
  ALLOWLIST_ABS="$(cd "$(dirname "$ALLOWLIST_FILE")" && pwd -P)/$(basename "$ALLOWLIST_FILE")"
else
  # File doesn't exist — resolve what the path would be
  parent_dir="$(dirname "$ALLOWLIST_FILE")"
  if [ -d "$parent_dir" ]; then
    ALLOWLIST_ABS="$(cd "$parent_dir" && pwd -P)/$(basename "$ALLOWLIST_FILE")"
  else
    "$PRINTF" 'ERROR: parent directory does not exist: %s\n' "$parent_dir" >&2
    exit 1
  fi
fi

# Validate: target must be in the known-allowlist set
is_known=0
for a in "${KNOWN_ALLOWLISTS[@]}"; do
  if [ "$ALLOWLIST_ABS" = "$a" ]; then
    is_known=1
    break
  fi
done

if [ "$is_known" != 1 ]; then
  "$PRINTF" 'ERROR: %s is not a known allowlist file.\n' "$ALLOWLIST_ABS" >&2
  usage
fi

# Validate entry
if [ -z "$ENTRY" ]; then
  "$PRINTF" 'ERROR: empty entry\n' >&2
  exit 1
fi

# Reject entries with newlines / carriage returns (null bytes can't appear in bash vars)
case "$ENTRY" in
  *$'\n'*|*$'\r'*)
    "$PRINTF" 'ERROR: entry contains control characters\n' >&2
    exit 1
    ;;
esac

# Check if entry already present (comment-aware)
if [ -f "$ALLOWLIST_ABS" ] && "$GREP" -Fxq "$ENTRY" "$ALLOWLIST_ABS"; then
  "$PRINTF" 'Entry already present in %s:\n  %s\n' "$ALLOWLIST_ABS" "$ENTRY" >&2
  exit 0  # idempotent — not an error
fi

# Locate the OPERATOR ADDITIONS region, in ONE awk pass, emitting three fields:
#   <begin-line> <end-line> <carries-marker-text>
#
# Two readers with two different jobs, and the split is the whole point:
#
#   begin/end  — a LINE-ANCHORED TRANSLITERATION of compose.py's _fence_re
#                (core/deploy/compose.py), dialect-agnostic and
#                parenthetical-tolerant per ADR-122, binding the FIRST BEGIN and
#                the FIRST END after it exactly as that extractor's non-greedy
#                capture does. It is deliberately a STRICT SUBSET of _fence_re:
#                every spelling it accepts, extract_operator_additions() also
#                accepts. A looser reader would find a "region" the authoritative
#                reader will not honour, insert into it, report success, and
#                SUPPRESS the warning below — dropping the entry at the next
#                regeneration. It decides only WHERE to insert.
#
#   carries-marker-text — a deliberately LOOSE substring test. It decides only
#                whether this file was ever MEANT to have an operator region, and
#                it can therefore only ever ADD a warning, never suppress one. A
#                file that carries the marker text but whose fence the strict
#                grammar rejects is a composition target with a broken fence: it
#                gets the EOF append AND the warning, because the entry will not
#                survive.
#
# The subset relation and the warn coverage are ASSERTED, not asserted about, by
# core/hooks/tests/allowlist-add.test.sh — they were a claim in the design and
# the claim was false.
find_operator_region() {
  "$AWK" '
    function fence(label,   sp) {
      sp = "[ \t]*"
      return "^(#|<!--)" sp "===" sp label "(" sp "\\([^)]*\\))?" sp "===" sp "(-->)?" sp "$"
    }
    BEGIN { b = 0; e = 0; looks = 0
            rb = fence("BEGIN OPERATOR ADDITIONS"); re = fence("END OPERATOR ADDITIONS") }
    index($0, "OPERATOR ADDITIONS") { looks = 1 }
    b == 0 && match($0, rb) { b = NR; next }
    b > 0 && e == 0 && match($0, re) { e = NR }
    END { print b + 0, e + 0, looks + 0 }
  ' "$1"
}

# Atomic append via temp-file rename
TMP="$("$MKTEMP" "${ALLOWLIST_ABS}.XXXXXX")"

begin_ln=0
end_ln=0
has_markers=0
if [ -f "$ALLOWLIST_ABS" ]; then
  read -r begin_ln end_ln has_markers <<EOF
$(find_operator_region "$ALLOWLIST_ABS")
EOF
fi

if [ "$end_ln" -gt 0 ]; then
  # Insert immediately before the END marker — inside the region compose.py's
  # extract_operator_additions() preserves across a regeneration, and at the
  # BOTTOM of it so region order equals addition chronology (the property that
  # lets the region be reconciled against allowlist-additions.log).
  #
  # Rule order is load-bearing: the entry prints first, then the unconditional
  # print emits the END line, so the entry lands BEFORE the marker. Reversing
  # them puts it after and silently reintroduces the EOF-append defect in a form
  # that still looks marker-aware.
  #
  # ENVIRON, never `awk -v`: -v interprets escape sequences in the assigned
  # value, so a backslash-bearing entry (a glob in shell-injection-allowlist.txt,
  # a path in fs-boundary-allowlist.txt) would be silently mangled. ENVIRON is
  # byte-faithful.
  ENTRY="$ENTRY" "$AWK" -v at="$end_ln" \
    'NR == at { print ENVIRON["ENTRY"] } { print }' "$ALLOWLIST_ABS" > "$TMP"
else
  # No usable region. Degrade to the historical EOF append — never synthesize a
  # marker fence: compose.py owns that fence AND its dialect (ADR-122, chosen per
  # the composition-surface manifest), so a helper guessing one could write a
  # plain fence into a file the manifest will regenerate as markdown, and could
  # manufacture an operator region in a file that has no managed section at all.
  if [ "$has_markers" = 1 ]; then
    "$PRINTF" 'WARNING: %s carries OPERATOR ADDITIONS marker text, but no marker region that\n' \
      "$ALLOWLIST_ABS" >&2
    "$PRINTF" '         compose.py will honour (its fence is malformed, or unpaired).\n' >&2
    "$PRINTF" '         Appending at end of file; this entry will NOT survive the next update.\n' >&2
  fi
  if [ -f "$ALLOWLIST_ABS" ]; then
    "$CAT" "$ALLOWLIST_ABS" > "$TMP"
  fi
  # Ensure trailing newline before appending
  if [ -s "$TMP" ] && [ "$(/usr/bin/tail -c 1 "$TMP")" != "" ]; then
    "$PRINTF" '\n' >> "$TMP"
  fi
  "$PRINTF" '%s\n' "$ENTRY" >> "$TMP"
fi
"$MV" "$TMP" "$ALLOWLIST_ABS"

# Log the addition
ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ)"
"$PRINTF" '%s\t%s\t%s\t%s\n' "$ts" "$ALLOWLIST_ABS" "$ENTRY" "$REASON" >> "$ADDITIONS_LOG" 2>/dev/null || true

"$PRINTF" 'Added to %s:\n  %s\n' "$ALLOWLIST_ABS" "$ENTRY"
