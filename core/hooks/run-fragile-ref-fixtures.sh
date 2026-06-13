#!/bin/bash
# run-fragile-ref-fixtures.sh — fixture self-test for the reference-durability detectors
#
# Per the adversarial-review amendment (FMF-2 + CDF-2): a warn-log is blind to false
# negatives, so the version-cutover detector's precision is gated on a checked-in
# corpus fixture with a labeled expected-match set. This runner asserts every FLAG
# line in core/hooks/testdata/cutover-fixtures.txt matches its class detector and
# every CLEAN line does not. Shared by manual verification, deploy.sh Check 31, and
# the reference-durability CI workflow so all three measure precision identically.
#
# Exit 0 = all fixture cases pass; exit 1 = at least one mismatch (precision regression).

set -euo pipefail
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly AWK="/usr/bin/awk"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
FIXTURE="${1:-${SCRIPT_DIR}/testdata/cutover-fixtures.txt}"

if [ ! -f "$FIXTURE" ]; then
  "$PRINTF" 'FAIL: fixture not found: %s\n' "$FIXTURE" >&2
  exit 1
fi

# Detectors — byte-identical to block-fragile-refs.sh.
LINK_RE='\]\('
CUTOVER_RE='v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?[^.\n]{0,40}merge SHA|v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?([[:space:]]+(release|itself|is))*[[:space:]]+(is[[:space:]]+)?exempt|([Aa]pplies to releases|[Cc]utover[[:space:]]+(applies|discipline|per))[^.\n]{0,80}v[0-9]+\.[0-9]+|reflexive-pipeline-loop'
URL_RE='github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/(issues|pull|milestone)s?([/#?]|$)'
REFBLOCK_RE='^#{1,6}[[:space:]]+([Ii]ssue [Rr]eferences|[Rr]eferences|[Pp]rovenance|[Ss]ources?)[[:space:]]*:?[[:space:]]*$'
ISSUEREF_RE='#\[?[0-9]+\]?'
MIN_SELFDESCRIBE_WORDS=3

# matches_class — returns 0 (match) / 1 (no match) for a given class + content line.
# For the ISSUEREF-IN / ISSUEREF-OUT classes, the fixture line is evaluated against the
# positional rule directly (block context is encoded by the class label: -OUT means "no
# block present"; -IN means "inside a block").
matches_class() {
  local class="$1" content="$2"
  case "$class" in
    LINK)
      "$PRINTF" '%s\n' "$content" | "$GREP" -qE "$LINK_RE"
      ;;
    VERSION)
      "$PRINTF" '%s\n' "$content" | "$GREP" -qE "$CUTOVER_RE"
      ;;
    URL)
      # Class U: a raw github.com/<owner>/<repo>/{issues,pull,milestone} URL.
      # Ledger-surface exemption is a path property evaluated by the hook/CI scope gate,
      # not by this content-level regex — the fixture's CLEAN-URL cases that depend on the
      # allow-url marker or ledger exemption are exercised at the hook/CI integration test,
      # not here. This case asserts the regex's content-match precision only.
      "$PRINTF" '%s\n' "$content" | "$GREP" -qE "$URL_RE"
      ;;
    ISSUEREF-OUT)
      # outside a block: a bare issue ref present is a flag
      "$PRINTF" '%s\n' "$content" | "$GREP" -qE "$ISSUEREF_RE"
      ;;
    ISSUEREF-IN)
      # inside a block: flag only when content-free (too few non-ref words)
      "$PRINTF" '%s\n' "$content" | "$AWK" -v issuere="$ISSUEREF_RE" -v minwords="$MIN_SELFDESCRIBE_WORDS" '
        {
          if ($0 !~ issuere) { found=1; exit }   # no issue ref -> no flag
          tmp = $0
          gsub(issuere, " ", tmp)
          gsub(/^[#>*[:space:]-]+/, "", tmp)
          n = split(tmp, parts, /[[:space:]]+/)
          words = 0
          for (i = 1; i <= n; i++) { if (parts[i] ~ /[A-Za-z]/) words++ }
          if (words < minwords) { flag=1 }
        }
        END { exit (flag ? 0 : 1) }
      '
      ;;
    *)
      return 1
      ;;
  esac
}

pass=0
fail=0
fail_lines=""

while IFS= read -r raw || [ -n "$raw" ]; do
  # skip comments + blank lines
  case "$raw" in
    ''|'#'*) continue ;;
  esac
  expect="$(printf '%s' "$raw" | cut -f1)"
  class="$(printf '%s' "$raw" | cut -f2)"
  content="$(printf '%s' "$raw" | cut -f3-)"
  [ -z "$expect" ] && continue

  if matches_class "$class" "$content"; then
    got="FLAG"
  else
    got="CLEAN"
  fi

  if [ "$got" = "$expect" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    fail_lines="${fail_lines}  expected ${expect} got ${got} [${class}]: ${content}"$'\n'
  fi
done < "$FIXTURE"

"$PRINTF" 'reference-durability fixture: %d passed, %d failed (fixture: %s)\n' "$pass" "$fail" "$FIXTURE"
if [ "$fail" -gt 0 ]; then
  "$PRINTF" '%s' "$fail_lines" >&2
  exit 1
fi
exit 0
