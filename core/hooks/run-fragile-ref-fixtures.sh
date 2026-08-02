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
# Shared positional-issue-ref classifier (single source of the positional decision; the
# hook and the reference-durability CI invoke this same file via `awk -f`).
POSITIONAL_LIB="${SCRIPT_DIR}/lib/positional-issueref.awk"

if [ ! -f "$FIXTURE" ]; then
  "$PRINTF" 'FAIL: fixture not found: %s\n' "$FIXTURE" >&2
  exit 1
fi

# Detectors — SOURCED from lib/fragile-ref-patterns.sh, the sole declaration of the seven
# constants. The hook and the reference-durability CI source the same file, so all three
# surfaces evaluate one set of bytes. Each constant's rationale lives beside its declaration
# in that file. Fail LOUD rather than run on unset patterns: an unset pattern is an EMPTY ERE
# that matches every line, so a broken lib would not weaken this fixture run, it would make
# every CLEAN case report FLAG.
PATTERNS_LIB="${SCRIPT_DIR}/lib/fragile-ref-patterns.sh"
if [ ! -r "$PATTERNS_LIB" ] || ! "${BASH:-/bin/bash}" -n "$PATTERNS_LIB" 2>/dev/null; then
  "$PRINTF" 'FAIL: detector constants missing or unparseable: %s\n' "$PATTERNS_LIB" >&2
  exit 1
fi
# shellcheck source=lib/fragile-ref-patterns.sh
. "$PATTERNS_LIB"
for _c in LINK_RE CUTOVER_RE URL_RE REFBLOCK_RE ISSUEREF_RE HEXCOLOR_RE MIN_SELFDESCRIBE_WORDS; do
  eval "_v=\${${_c}:-}"
  if [ -z "$_v" ]; then
    "$PRINTF" 'FAIL: %s unset after sourcing %s\n' "$_c" "$PATTERNS_LIB" >&2
    exit 1
  fi
done

# Re-declaration detector (class PATTERNDECL). Sourcing removes the ability for the seven
# constants to DIVERGE, but not the ability for a future edit to paste a literal back into a
# consuming surface "for local convenience" — which would silently restore a second source of
# truth. This is the detector for that, and it is what the PATTERNDECL fixture cases and the
# scan arm below both exercise, so the scan is a probe with committed arms rather than an
# unverified assertion.
#
# The anchor is the whole property under test: a line that DECLARES one of the seven names
# (optionally `readonly`-prefixed, any leading indentation — the CI's copies were indented
# inside a YAML block scalar). A line that merely NAMES the constants — `-v issuere="$ISSUEREF_RE"`
# — differs from a declaration only in that anchoring, which is exactly why it is the
# must-not-flag case rather than an unrelated line that would pass vacuously.
#
# This declaration does not match itself: the anchor requires one of the seven names at line
# start, and this line starts with PATTERNDECL_RE.
PATTERNDECL_RE='^[[:space:]]*(readonly[[:space:]]+)?(LINK_RE|CUTOVER_RE|URL_RE|REFBLOCK_RE|ISSUEREF_RE|HEXCOLOR_RE|MIN_SELFDESCRIBE_WORDS)='

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
    PATTERNDECL)
      # A re-declaration of one of the seven single-sourced detector constants on a
      # consuming surface. FLAG = a declaration; CLEAN = a line that names them without
      # declaring one. Same detector the scan arm applies to the real files.
      "$PRINTF" '%s\n' "$content" | "$GREP" -qE "$PATTERNDECL_RE"
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
    ISSUEREF-POS)
      # TRUE positional test. The content column is "<refline>|<lineno>|<line text>";
      # split on the first two '|' and feed (lineno, line text) + refline to the SHARED
      # classifier (core/hooks/lib/positional-issueref.awk) — the exact file the hook and
      # CI call. FLAG iff the classifier emits a verdict line for the record.
      local _refline _lineno _linetext _verdict
      _refline="${content%%|*}"                 # before first '|'
      local _rest="${content#*|}"               # after first '|'
      _lineno="${_rest%%|*}"                     # before second '|'
      _linetext="${_rest#*|}"                    # after second '|' (may itself contain '|')
      # NUMERIC-VALIDATE the coords (#757): refline/lineno feed the classifier, which
      # `+0`-coerces them — a malformed coord (typo, missing '|') would SILENTLY become
      # 0 (refline 0 = "no block"; lineno 0 = phantom position), making a broken fixture
      # row read CLEAN. Fail LOUD instead of silent fail-safe coercion. Both must be
      # non-negative integers (refline 0 is the legitimate "no block in file" sentinel).
      if ! printf '%s' "$_refline" | "$GREP" -qE '^[0-9]+$'; then
        "$PRINTF" 'FAIL: ISSUEREF-POS fixture row has a non-numeric refline %s in content: %s\n' "[$_refline]" "$content" >&2
        exit 1
      fi
      if ! printf '%s' "$_lineno" | "$GREP" -qE '^[0-9]+$'; then
        "$PRINTF" 'FAIL: ISSUEREF-POS fixture row has a non-numeric lineno %s in content: %s\n' "[$_lineno]" "$content" >&2
        exit 1
      fi
      _verdict="$("$PRINTF" '%s\t%s\n' "$_lineno" "$_linetext" \
        | "$AWK" -f "$POSITIONAL_LIB" \
            -v issuere="$ISSUEREF_RE" -v hexcolor="$HEXCOLOR_RE" -v refline="$_refline" -v minwords="$MIN_SELFDESCRIBE_WORDS")"
      [ -n "$_verdict" ]   # non-empty verdict => match (FLAG); empty => CLEAN
      ;;
    *)
      return 1
      ;;
  esac
}

pass=0
fail=0
n_flag=0        # must-flag arm size (sensitivity)
n_clean=0       # must-not-flag arm size (specificity)
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
  case "$expect" in
    FLAG)  n_flag=$((n_flag + 1)) ;;
    CLEAN) n_clean=$((n_clean + 1)) ;;
  esac

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

# --- NO-LITERAL-REDECLARATION SCAN ARM ---------------------------------------------------
# The fixture cases above prove the detector works on labeled inputs. This applies that same
# detector to the real consuming surfaces, so a literal pasted back into one of them fails the
# run. The lib itself is out of scope BY CONSTRUCTION — it is not in the target list — rather
# than by an exemption a future edit could widen.
#
# Targets resolve from the SOURCE tree. In a deployed or sandbox layout most do not exist, and
# a scan over a population that is not fully present is VACUOUS, not clean: reporting a bare
# "0 findings" there would let a reader mistake "nothing examined" for "nothing wrong".
#
# Note the denominator never reaches zero in practice — this runner is itself one of the three
# consuming surfaces, so it is always self-reachable and a zero-target run cannot occur while
# the scan is executing. PARTIAL, not zero, is therefore the state that actually needs
# labelling: a deployed-layout run reaches 1 of 3 and must not present that as full coverage.
# The zero branch is kept only as a defensive floor for a caller that relocates the runner.
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null && pwd -P || printf '%s' "$SCRIPT_DIR")"
SCAN_TARGETS="${SCRIPT_DIR}/block-fragile-refs.sh
${SCRIPT_DIR}/run-fragile-ref-fixtures.sh
${REPO_ROOT}/.github/workflows/reference-durability.yml"

scan_present=0
scan_total=0
scan_findings=0
scan_report=""
while IFS= read -r _t; do
  [ -z "$_t" ] && continue
  scan_total=$((scan_total + 1))
  [ -r "$_t" ] || continue
  scan_present=$((scan_present + 1))
  _hits="$("$GREP" -nE "$PATTERNDECL_RE" "$_t" || true)"
  if [ -n "$_hits" ]; then
    _n=$("$PRINTF" '%s\n' "$_hits" | "$GREP" -c '' || true)
    scan_findings=$((scan_findings + _n))
    scan_report="${scan_report}  ${_t}"$'\n'"${_hits}"$'\n'
  fi
done <<EOF
$SCAN_TARGETS
EOF

if [ "$scan_present" -eq 0 ]; then
  scan_summary="redeclaration scan: SKIPPED-VACUOUS (0 of ${scan_total} targets present)"
elif [ "$scan_present" -lt "$scan_total" ]; then
  # Findings still fail below; only the COVERAGE claim is withheld. deploy.sh Check 31 and the
  # reference-durability CI both run from the repo root and reach 3 of 3, so a full-coverage
  # result is what the gating callers get; a deployed-layout smoke run says so out loud
  # instead of borrowing their authority.
  scan_summary="redeclaration scan: PARTIAL — ${scan_findings} findings across ${scan_present} of ${scan_total} targets (NOT a full-coverage result)"
else
  scan_summary="redeclaration scan: ${scan_findings} findings across ${scan_present} of ${scan_total} targets scanned"
fi

# PV-6 instrument form: a finding count is only readable next to its denominator and its arm
# results. "46 passed, 0 failed" alone cannot distinguish a healthy run from one that examined
# nothing.
"$PRINTF" 'reference-durability fixture: %d FLAG / %d CLEAN, %d passed, %d failed (fixture: %s) · %s\n' \
  "$n_flag" "$n_clean" "$pass" "$fail" "$FIXTURE" "$scan_summary"

if [ "$fail" -gt 0 ]; then
  "$PRINTF" '%s' "$fail_lines" >&2
  exit 1
fi
if [ "$scan_findings" -gt 0 ]; then
  "$PRINTF" 'FAIL: detector constants re-declared outside lib/fragile-ref-patterns.sh:\n%s' "$scan_report" >&2
  exit 1
fi
exit 0
