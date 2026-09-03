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

# Detectors — SOURCED from lib/fragile-ref-patterns.sh, the CANONICAL declaration of the
# seven constants. Every surface named in that file's `Sourced by:` block reads it, so those
# surfaces evaluate one set of bytes; the identity arm at the bottom of this runner is what
# keeps that claim honest as surfaces come and go, by discovering declaration sites rather
# than trusting a list. Each constant's rationale lives beside its declaration in that file.
# Fail LOUD rather than run on unset patterns: an unset pattern is an EMPTY ERE
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

# --- REFBLOCK_RE IDENTITY ARM (DISCOVERED population) -------------------------------------
# The scan arm above proves the three surfaces it NAMES carry no literal redeclaration. It
# can prove nothing about a fourth, because SCAN_TARGETS is a hand-maintained list — and a
# divergent REFBLOCK_RE did survive in a consuming surface that list never named. This arm
# replaces the hand-maintained population for ONE constant with a DISCOVERED one: every
# tracked shell / YAML / Python / awk file, so the next copy is caught wherever it lands
# rather than only where someone remembered to look.
#
# Scoped to REFBLOCK_RE deliberately, NOT widened to all seven constants at once. Other
# constants are re-declared today under local names for reasons their own surfaces record,
# and sweeping them in here would fail the run on day one for files no current change owns.
# The all-constant arm above therefore stays exactly as it is; this is purely additive.
#
# TWO SUB-ARMS, DELIBERATELY DIFFERENT AUTHORITY, because they have different precision:
#   name-anchored  a site that DECLARES REFBLOCK_RE. A value byte-identical to the
#                  canonical one is ACCOUNTED FOR, not reported — byte-identity is one of
#                  the two states the contract allows (the other being sourcing), so
#                  reporting it would fire on a state the contract permits. A DIVERGENT
#                  value is a finding and FAILS the run. Precise enough to block.
#   value-shape    the reference-block anchor shape under ANY variable name. This is the
#                  arm that sees what a name-anchored probe structurally CANNOT: a copy
#                  renamed on the way in returns zero for a probe searching the canonical
#                  name. It over-includes by construction — an independent surface may
#                  legitimately carry an ancestor of this shape while answering a different
#                  question — so it REPORTS and never fails.
#
# The lib itself and this directory's fixture data are excluded BY CONSTRUCTION: a path
# guard inside the scan loop, never an exemption list a later edit could widen.
REFBLOCK_DECL_RE='^[[:space:]]*(readonly[[:space:]]+)?REFBLOCK_RE='
# The value-shape probe is a CONJUNCTION of two fixed strings, not one, and the pairing is
# what makes it self-non-matching — the same property PATTERNDECL_RE gets from its anchor.
# A genuine copy of the reference-block pattern carries BOTH the heading-level anchor and
# the bracketed spelling; each declaration line below carries only ONE, so this detector
# cannot report itself. Fixed strings rather than an ERE because the thing being searched
# for IS regex source: escaping it as a pattern would be unreadable and easy to get wrong.
# Prose naming the recognized headings carries neither bracketed form, so the gate's own
# user-facing failure message and its heading-matrix generator are not swept in.
REFBLOCK_SHAPE_ANCHOR='#{1,6}'
REFBLOCK_SHAPE_SPELLING='[Ii]ssue [Rr]eferences'
REFBLOCK_FIXTURE="${SCRIPT_DIR}/testdata/refblock-identity-fixtures.txt"

# refblock_decl_value — the quoted value carried by a REFBLOCK_RE declaration line. Pure
# TEXT extraction: the candidate file is never sourced, so a scan cannot execute what it
# is scanning. Prints nothing for a line that is not a declaration.
refblock_decl_value() {
  "$PRINTF" '%s\n' "$1" | "$AWK" -v sq="'" '
    {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      sub(/^readonly[[:space:]]+/, "", line)
      if (line !~ /^REFBLOCK_RE=/) { exit }
      sub(/^REFBLOCK_RE=/, "", line)
      q = substr(line, 1, 1)
      if (q == sq || q == "\"") {
        line = substr(line, 2)
        p = 0
        for (i = length(line); i >= 1; i--) { if (substr(line, i, 1) == q) { p = i; break } }
        if (p > 0) { line = substr(line, 1, p - 1) }
      }
      print line
    }'
}

# refblock_scan_root — run both sub-arms over one root and one newline-separated list of
# root-relative paths. Emits TAB-separated verdict rows: <KIND>\t<relpath>\t<lineno>, where
# KIND is NAME-DIVERGENT | NAME-IDENTICAL | SHAPE. Same function for the fixture root and
# for the real tree, so the committed arms exercise the code that actually gates.
refblock_scan_root() {
  local _root="$1" _paths="$2"
  local _p _dhits _shits _h _ln _txt _val
  while IFS= read -r _p; do
    [ -z "$_p" ] && continue
    case "$_p" in
      core/hooks/lib/fragile-ref-patterns.sh) continue ;;  # IS the canonical declaration
      core/hooks/testdata/*) continue ;;                   # fixture data, not a consumer
    esac
    [ -r "${_root}/${_p}" ] || continue

    _dhits="$("$GREP" -nE "$REFBLOCK_DECL_RE" "${_root}/${_p}" 2>/dev/null || true)"
    if [ -n "$_dhits" ]; then
      while IFS= read -r _h; do
        [ -z "$_h" ] && continue
        _ln="${_h%%:*}"
        _txt="${_h#*:}"
        _val="$(refblock_decl_value "$_txt")"
        if [ "$_val" = "$REFBLOCK_RE" ]; then
          "$PRINTF" 'NAME-IDENTICAL\t%s\t%s\n' "$_p" "$_ln"
        else
          "$PRINTF" 'NAME-DIVERGENT\t%s\t%s\n' "$_p" "$_ln"
        fi
      done <<INNER_DECL
$_dhits
INNER_DECL
    fi

    _shits="$("$GREP" -nF "$REFBLOCK_SHAPE_SPELLING" "${_root}/${_p}" 2>/dev/null || true)"
    if [ -n "$_shits" ]; then
      while IFS= read -r _h; do
        [ -z "$_h" ] && continue
        # Conjunction: the spelling alone is a detector's search literal, not a copy of the
        # pattern. A copy also carries the heading-level anchor.
        # HERE-STRING, not a pipe. `grep -q` exits at its first match, so a writer upstream
        # takes a broken pipe and returns 141; under `pipefail` that inverts this test to
        # its `continue` branch — a silently MISSED finding, non-deterministically. Removing
        # the writer removes the hazard rather than relocating it.
        "$GREP" -qF "$REFBLOCK_SHAPE_ANCHOR" <<<"${_h#*:}" || continue
        "$PRINTF" 'SHAPE\t%s\t%s\n' "$_p" "${_h%%:*}"
      done <<INNER_SHAPE
$_shits
INNER_SHAPE
    fi
  done <<OUTER_PATHS
$_paths
OUTER_PATHS
  return 0
}

# --- committed arms for the identity scan -------------------------------------------------
# The fixture resolves from a DEFAULT path, never from $1: both gating callers pass
# cutover-fixtures.txt as $1, and they stay byte-unchanged. A missing fixture is a hard
# failure, not a skip — running an assertion whose arms were never demonstrated is exactly
# the untrusted state the arms exist to rule out.
if [ ! -r "$REFBLOCK_FIXTURE" ]; then
  "$PRINTF" 'FAIL: refblock identity fixture not found: %s\n' "$REFBLOCK_FIXTURE" >&2
  exit 1
fi

rb_td="$(mktemp -d)"
rb_rows=0
rb_flag=0
rb_clean=0
rb_fail=0
rb_fail_lines=""
rb_cases=""
while IFS= read -r raw || [ -n "$raw" ]; do
  case "$raw" in
    ''|'#'*) continue ;;
  esac
  rb_expect="$("$PRINTF" '%s' "$raw" | cut -f1)"
  rb_class="$("$PRINTF" '%s' "$raw" | cut -f2)"
  rb_content="$("$PRINTF" '%s' "$raw" | cut -f3-)"
  [ -z "$rb_expect" ] && continue
  rb_path="${rb_content%%|*}"
  rb_line="${rb_content#*|}"
  # @@CANONICAL@@ is a SENTINEL, not a literal: writing the canonical bytes into a fixture
  # would create a third copy of the value, which is the defect class this arm prevents.
  rb_line="${rb_line//@@CANONICAL@@/$REFBLOCK_RE}"
  mkdir -p "${rb_td}/$(dirname "$rb_path")"
  "$PRINTF" '%s\n' "$rb_line" > "${rb_td}/${rb_path}"
  rb_rows=$((rb_rows + 1))
  case "$rb_expect" in
    FLAG)  rb_flag=$((rb_flag + 1)) ;;
    CLEAN) rb_clean=$((rb_clean + 1)) ;;
  esac
  rb_cases="${rb_cases}${rb_expect}	${rb_class}	${rb_path}"$'\n'
done < "$REFBLOCK_FIXTURE"

# ENUMERATE the materialised tree from the filesystem rather than replaying the list just
# written, so the fixture exercises discovery and the path guard, not only the detectors.
rb_pop="$(cd "$rb_td" && find . -type f | "$AWK" '{ sub(/^\.\//, "", $0); print }' | LC_ALL=C sort)"
rb_verdicts="$(refblock_scan_root "$rb_td" "$rb_pop")"
rb_pop_n="$("$PRINTF" '%s\n' "$rb_pop" | "$GREP" -c '' || true)"
# REACHABILITY ARM for the identical-value rows. Their expectation is CLEAN, and CLEAN is
# also what an unreached file produces — so on its own a passing identical row cannot
# distinguish "scanned, extracted, compared, found identical" from "never scanned at all".
# Counting the NAME-IDENTICAL verdicts closes that: a non-zero count is only reachable
# through the extraction and the comparison, so it is the positive evidence those rows'
# zeros are load-bearing rather than vacuous.
rb_fx_identical="$("$PRINTF" '%s\n' "$rb_verdicts" | "$GREP" -c '^NAME-IDENTICAL	' || true)"
rm -rf "$rb_td"

while IFS= read -r rb_case; do
  [ -z "$rb_case" ] && continue
  rb_expect="$("$PRINTF" '%s' "$rb_case" | cut -f1)"
  rb_class="$("$PRINTF" '%s' "$rb_case" | cut -f2)"
  rb_path="$("$PRINTF" '%s' "$rb_case" | cut -f3)"
  case "$rb_class" in
    REFBLOCK-DECL)  rb_kind="NAME-DIVERGENT" ;;
    REFBLOCK-SHAPE) rb_kind="SHAPE" ;;
    *)              rb_kind="" ;;
  esac
  # HERE-STRING for the same reason as the scan's conjunction test: a `grep -q` reader with
  # a writer upstream can invert this `if` to CLEAN on a broken pipe, which would silently
  # turn a FLAG row's failure into a pass — the fixture would report green while blind.
  if [ -n "$rb_kind" ] && "$GREP" -qF "${rb_kind}	${rb_path}	" <<<"$rb_verdicts"; then
    rb_got="FLAG"
  else
    rb_got="CLEAN"
  fi
  if [ "$rb_got" != "$rb_expect" ]; then
    rb_fail=$((rb_fail + 1))
    rb_fail_lines="${rb_fail_lines}  expected ${rb_expect} got ${rb_got} [${rb_class}]: ${rb_path}"$'\n'
  fi
done <<REFBLOCK_CASES
$rb_cases
REFBLOCK_CASES

# --- the identity scan over the real tree -------------------------------------------------
# Population is DISCOVERED. When discovery is unavailable (a deployed or sandbox layout, or
# any tree that is not a git checkout) the arm falls back to the three known targets and
# says PARTIAL out loud: a scan over a population that is not fully present is VACUOUS, not
# clean, and a bare zero would let a reader mistake "nothing examined" for "nothing wrong".
rb_pop_source="discovered"
rb_real_pop=""
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  rb_real_pop="$(git -C "$REPO_ROOT" ls-files -- '*.sh' '*.yml' '*.yaml' '*.bash' '*.py' '*.awk' 2>/dev/null || true)"
fi
if [ -z "$rb_real_pop" ]; then
  rb_pop_source="fallback"
  rb_real_pop="core/hooks/block-fragile-refs.sh
core/hooks/run-fragile-ref-fixtures.sh
.github/workflows/reference-durability.yml"
fi
rb_real_total="$("$PRINTF" '%s\n' "$rb_real_pop" | "$GREP" -c '' || true)"
rb_real_present=0
while IFS= read -r rb_p; do
  [ -z "$rb_p" ] && continue
  [ -r "${REPO_ROOT}/${rb_p}" ] && rb_real_present=$((rb_real_present + 1))
done <<REFBLOCK_REAL_POP
$rb_real_pop
REFBLOCK_REAL_POP

rb_real_verdicts="$(refblock_scan_root "$REPO_ROOT" "$rb_real_pop")"
rb_divergent="$("$PRINTF" '%s\n' "$rb_real_verdicts" | "$GREP" -c '^NAME-DIVERGENT	' || true)"
rb_identical="$("$PRINTF" '%s\n' "$rb_real_verdicts" | "$GREP" -c '^NAME-IDENTICAL	' || true)"
rb_shape="$("$PRINTF" '%s\n' "$rb_real_verdicts" | "$GREP" -c '^SHAPE	' || true)"

# The advisory sites are named ON the summary line, not in a block beneath it: deploy.sh
# Check 31 folds this runner's whole stdout into one log line, so a multi-line block would
# reach the operator as an unreadable run-on. Update-or-accept needs the site names, and a
# count with no names is not actionable.
rb_shape_sites=""
if [ "$rb_shape" -gt 0 ]; then
  while IFS= read -r rb_v; do
    [ -z "$rb_v" ] && continue
    case "$rb_v" in
      SHAPE*) rb_shape_sites="${rb_shape_sites} $("$PRINTF" '%s' "$rb_v" | cut -f2):$("$PRINTF" '%s' "$rb_v" | cut -f3)" ;;
    esac
  done <<REFBLOCK_SHAPE_SITES
$rb_real_verdicts
REFBLOCK_SHAPE_SITES
  rb_shape_sites=" [advisory, update-or-accept:${rb_shape_sites} ]"
fi

if [ "$rb_real_present" -eq 0 ]; then
  rb_summary="refblock identity scan: SKIPPED-VACUOUS (0 of ${rb_real_total} paths present)"
elif [ "$rb_pop_source" = "fallback" ] || [ "$rb_real_present" -lt "$rb_real_total" ]; then
  rb_summary="refblock identity scan: PARTIAL — ${rb_divergent} divergent / ${rb_identical} identical-accounted / ${rb_shape} value-shape across ${rb_real_present} of ${rb_real_total} paths (NOT a full-coverage result)${rb_shape_sites}"
else
  rb_summary="refblock identity scan: ${rb_divergent} divergent / ${rb_identical} identical-accounted / ${rb_shape} value-shape across ${rb_real_present} of ${rb_real_total} paths${rb_shape_sites}"
fi

# --- PER-FILE OVERRIDE-MARKER RESOLUTION ARM (BEHAVIOURAL — runs the REAL hook) -----------
# Every arm above this one is STATIC: it applies a detector to a line, or a scan to a file.
# None of them reaches the step that runs BEFORE any detector — reading a file's per-file
# override marker out of the fence-stripped content and deciding whether the file has exempted
# itself from a class. That step had zero behavioural coverage and was broken size-dependently:
# both marker-resolving surfaces piped a file-sized variable into `grep -q` under `pipefail`,
# `grep -q` exited at its first match, the writer took SIGPIPE and returned 141, and the
# override was silently discarded on any file past the ~64 KB pipe buffer. The fixture rows and
# their rationale live in testdata/marker-resolution-fixtures.txt.
#
# WHY THIS ARM INVOKES THE HOOK INSTEAD OF RE-IMPLEMENTING THE READ. A copy of the marker
# resolution inside this runner would be a THIRD site of the same construct, and — decisively —
# it could never fail: fixing the two real surfaces would not touch the copy, so the arm would
# report green against a broken gate. An assertion that cannot fail for the reason it exists is
# not a test. So the row is fed to the real block-fragile-refs.sh and its EXIT CODE is the
# verdict. That also makes the arm answer the question a reviewer actually has — "does a large
# file's marker still exempt it?" — rather than a proxy for it.
#
# THE THROWAWAY HOOK ROOT, and why each property is deliberate. The hook resolves its mode, its
# allowlist and its logs from ${HOOK_DIR}, so running it in place would read operator config and
# write JSONL logs into the source tree. It is copied into a temp root instead — the same
# materialise-then-run shape the refblock arm uses — where:
#   .mode = enforce   so the verdict is an EXIT CODE (2 = reported, 0 = clean) rather than a
#                     stderr string. In warn-mode the hook exits 0 on a finding and the arm
#                     would be blind to every failure it exists to catch.
#   allowlist         a synthetic file with one inert entry. The REAL allowlist is deliberately
#                     NOT used: a future path exemption covering the fixture's durable path
#                     would make every CLEAN row pass vacuously, which is the precise silent
#                     pass this arm exists to rule out. It must exist and be non-empty, because
#                     an absent allowlist is fail-closed in enforce.
#   libs              exactly the three the hook REQUIRES in enforce (dep-resolve,
#                     fragile-ref-patterns, positional-issueref). master-enable.sh and
#                     scope-guard.sh are omitted ON PURPOSE: each is skipped when absent, and
#                     copying them would couple this arm to operator config and to $CWD. If a
#                     future edit makes another lib required, this arm fails LOUD — a fail-closed
#                     hook returns 2 for every row and the CLEAN rows report FLAG.
MARKER_FIXTURE="${SCRIPT_DIR}/testdata/marker-resolution-fixtures.txt"
# SIZED INTO A TWO-SIDED WINDOW, both bounds MEASURED against the real hook rather than
# reasoned about. This constant is the arm's whole sensitivity, so it is stated here with the
# numbers that chose it.
#
#   LOWER BOUND — the defect must actually fire. The writer has to still be pushing when
#   `grep -q` matches the marker on line 1. Swept against the pre-fix hook: 700 lines
#   (57,537 B) still resolves the marker; 800 lines (65,737 B) discards it, and every larger
#   size discards it too. So the floor is the ~64 KB pipe buffer, and anything at or under it
#   makes this arm SILENTLY VACUOUS — it would pass against the broken gate.
#
#   UPPER BOUND — the row must not collide with an unrelated limit. Linux caps a single argv
#   string at MAX_ARG_STRLEN (131,072 B); the hook passes its whole stdin JSON to an external
#   printf when validating it, so a row whose JSON exceeds that cap makes the hook exit on
#   "malformed hook input JSON" instead of adjudicating the marker. That is a real and
#   separate hook defect (it is NOT this issue's six sites, and is reported rather than fixed
#   here), but an arm that tripped it would fail for a reason other than the one it names —
#   the opposite of the isolation the small/large row pair exists to provide.
#
# 1200 lines puts the body at 98,537 B and its JSON at 99,867 B: ~33 KB clear of the firing
# floor and ~31 KB clear of the argv ceiling. Verified in both directions at exactly this
# size — pre-fix hook exits 2 (marker discarded), post-fix hook exits 0 (marker honoured).
MARKER_BULK_LINES=1200
# Inert by construction: no `](`, no bare issue reference, no raw ledger URL, no version-cutover
# idiom. The large row must differ from the small row in SIZE ALONE, or a failure would not
# isolate the size dependence.
MARKER_PAD_LINE='Filler prose line carrying no fragile reference construct of any kind whatsoever.'

if [ ! -r "$MARKER_FIXTURE" ]; then
  "$PRINTF" 'FAIL: marker-resolution fixture not found: %s\n' "$MARKER_FIXTURE" >&2
  exit 1
fi

# jq builds the hook's stdin payload. Resolved through the shared helper's resolve_jq rather
# than a literal path, so this runner obeys the same fixed-allowlist resolution posture as the
# hooks (GHSA-9cjm-v22x-4x33) and check-hook-dep-hardening.sh CHECK-3 stays satisfied.
mk_jq=""
mk_dep_lib="${SCRIPT_DIR}/lib/dep-resolve.sh"
if [ -r "$mk_dep_lib" ] && "${BASH:-/bin/bash}" -n "$mk_dep_lib" 2>/dev/null && . "$mk_dep_lib" 2>/dev/null \
   && command -v resolve_jq >/dev/null 2>&1; then
  mk_jq="$(resolve_jq)"
fi

mk_hook_src="${SCRIPT_DIR}/block-fragile-refs.sh"
mk_rows=0
mk_flag=0
mk_clean=0
mk_fail=0
mk_observed_flag=0
mk_fail_lines=""
mk_skip=""
mk_bulk_kb=0

# An environment that cannot run the hook is labelled SKIPPED-VACUOUS rather than reported as
# clean — the distinction this runner already draws for its other populations. A missing
# FIXTURE is still a hard failure above; a missing ENVIRONMENT is a skip. The two gating
# callers (deploy.sh Check 31, the reference-durability CI) both run from a full checkout with
# jq present, so the skip is a smoke-run affordance and never their result.
if [ -z "$mk_jq" ]; then
  mk_skip="jq unresolvable"
elif [ ! -x "$mk_hook_src" ]; then
  mk_skip="block-fragile-refs.sh not present beside the runner"
elif [ ! -r "${SCRIPT_DIR}/lib/fragile-ref-patterns.sh" ] || [ ! -r "${SCRIPT_DIR}/lib/positional-issueref.awk" ]; then
  mk_skip="co-shipped hook libs not present beside the runner"
fi

if [ -z "$mk_skip" ]; then
  mk_td="$(mktemp -d)"
  mkdir -p "${mk_td}/hooks/lib"
  cp "$mk_hook_src" "${mk_td}/hooks/block-fragile-refs.sh"
  cp "$mk_dep_lib" "${mk_td}/hooks/lib/dep-resolve.sh"
  cp "${SCRIPT_DIR}/lib/fragile-ref-patterns.sh" "${mk_td}/hooks/lib/fragile-ref-patterns.sh"
  cp "${SCRIPT_DIR}/lib/positional-issueref.awk" "${mk_td}/hooks/lib/positional-issueref.awk"
  chmod +x "${mk_td}/hooks/block-fragile-refs.sh"
  "$PRINTF" 'enforce\n' > "${mk_td}/hooks/.mode"
  "$PRINTF" '# synthetic allowlist for the marker-resolution arm — one inert entry so the\n# surface is reachable (absent is fail-closed) while no fixture path can match it.\nnever-matches-any-fixture-path.md\n' \
    > "${mk_td}/reference-durability-allowlist.txt"

  # THE BULK PAYLOAD NEVER TRAVELS AS AN ARGUMENT. Linux caps a SINGLE argv string at
  # MAX_ARG_STRLEN (128 KiB, 32 pages) independently of the much larger total ARG_MAX, so
  # handing a >64 KB payload to any EXTERNAL command as an argument fails with E2BIG
  # ("Argument list too long"). macOS has no equivalent per-string cap, so this arm passed
  # locally and died on the CI runner — the same class of platform-dependent break as the
  # defect it pins. Everything large therefore moves by FILE or STDIN: awk writes the filler
  # by redirection, `wc -c <file>` measures it, and jq reads the row body with --rawfile.
  # The only printf that touches a large value below is the shell BUILTIN, which never
  # execs and so has no argv limit at all.
  "$AWK" -v n="$MARKER_BULK_LINES" -v p="$MARKER_PAD_LINE" \
    'BEGIN { for (i = 1; i <= n; i++) print p }' > "${mk_td}/bulk-filler.txt"
  mk_padding="$(cat "${mk_td}/bulk-filler.txt")"
  # MEASURED, never computed from the line count. The summary states this arm's sensitivity —
  # whether the bulk row actually clears the pipe buffer — so an arithmetic estimate of it
  # would be a number the run never checked, in the one field a reader consults to decide
  # whether the arm could have fired at all.
  mk_bulk_kb=$(( $(wc -c < "${mk_td}/bulk-filler.txt") / 1024 ))

  while IFS= read -r raw || [ -n "$raw" ]; do
    case "$raw" in
      ''|'#'*) continue ;;
    esac
    mk_expect="$("$PRINTF" '%s' "$raw" | cut -f1)"
    mk_class="$("$PRINTF" '%s' "$raw" | cut -f2)"
    mk_content="$("$PRINTF" '%s' "$raw" | cut -f3-)"
    [ -z "$mk_expect" ] && continue
    mk_path="${mk_content%%|*}"
    mk_raw="${mk_content#*|}"
    # `\n` -> newline FIRST, then the sentinel, so %b never walks the filler block. $mk_raw is
    # one fixture line, so the pinned printf is safe here; the EXPANDED body is not, and from
    # this point on it moves only by file (see the MAX_ARG_STRLEN note above).
    mk_body="$("$PRINTF" '%b' "$mk_raw")"
    mk_body="${mk_body//@@BULK@@/$mk_padding}"
    # BUILTIN printf, deliberately not "$PRINTF": a builtin never execs, so it has no argv
    # limit, and this is the one write that must carry the full expanded body.
    printf '%s' "$mk_body" > "${mk_td}/row-body.txt"
    mk_bytes="$(wc -c < "${mk_td}/row-body.txt" | tr -d ' ')"

    mk_rows=$((mk_rows + 1))
    case "$mk_expect" in
      FLAG)  mk_flag=$((mk_flag + 1)) ;;
      CLEAN) mk_clean=$((mk_clean + 1)) ;;
    esac

    # --rawfile, not --arg: the body reaches jq as a FILE it opens, so a row of any size is
    # encoded without the payload ever becoming an argument.
    mk_json="$("$mk_jq" -n --arg fp "$mk_path" --rawfile c "${mk_td}/row-body.txt" \
      '{tool_name:"Write", cwd:"/", tool_input:{file_path:$fp, content:$c}}')"
    # HERE-STRING, not a pipe — the same repair this arm exists to pin. A writer feeding a
    # process that may exit before draining stdin can take SIGPIPE and return 141, and under
    # `pipefail` that would report FLAG for a hook that in fact exited 0. Using the construct
    # under test to test itself would make every verdict here unreadable.
    if "${mk_td}/hooks/block-fragile-refs.sh" >/dev/null 2>&1 <<<"$mk_json"; then
      mk_got="CLEAN"
    else
      mk_got="FLAG"
      mk_observed_flag=$((mk_observed_flag + 1))
    fi

    if [ "$mk_got" != "$mk_expect" ]; then
      mk_fail=$((mk_fail + 1))
      mk_fail_lines="${mk_fail_lines}  expected ${mk_expect} got ${mk_got} [${mk_class}]: ${mk_path} (${mk_bytes} bytes)"$'\n'
    fi
  done < "$MARKER_FIXTURE"

  rm -rf "$mk_td"
fi

if [ -n "$mk_skip" ]; then
  mk_summary="marker-resolution arm: SKIPPED-VACUOUS (${mk_skip}) — NOT a clean result"
else
  mk_summary="marker-resolution arm: ${mk_flag} FLAG / ${mk_clean} CLEAN, ${mk_rows} rows, ${mk_fail} failed (bulk filler ${mk_bulk_kb} KB measured, pipe buffer ~64 KB)"
fi

# PV-6 instrument form: a finding count is only readable next to its denominator and its arm
# results. "46 passed, 0 failed" alone cannot distinguish a healthy run from one that examined
# nothing.
"$PRINTF" 'reference-durability fixture: %d FLAG / %d CLEAN, %d passed, %d failed (fixture: %s) · %s\n' \
  "$n_flag" "$n_clean" "$pass" "$fail" "$FIXTURE" "$scan_summary"
"$PRINTF" 'refblock identity fixture: %d FLAG / %d CLEAN, %d cases, %d failed over %d materialised paths · %s\n' \
  "$rb_flag" "$rb_clean" "$rb_rows" "$rb_fail" "$rb_pop_n" "$rb_summary"
"$PRINTF" '%s\n' "$mk_summary"

if [ "$fail" -gt 0 ]; then
  "$PRINTF" '%s' "$fail_lines" >&2
  exit 1
fi
if [ "$scan_findings" -gt 0 ]; then
  "$PRINTF" 'FAIL: detector constants re-declared outside lib/fragile-ref-patterns.sh:\n%s' "$scan_report" >&2
  exit 1
fi
# A committed arm that never fires proves nothing, so an empty arm is itself a failure.
if [ "$rb_flag" -eq 0 ] || [ "$rb_clean" -eq 0 ]; then
  "$PRINTF" 'FAIL: refblock identity fixture is one-armed (%d FLAG / %d CLEAN) — a zero from it would be unreadable\n' \
    "$rb_flag" "$rb_clean" >&2
  exit 1
fi
if [ "$rb_fx_identical" -eq 0 ]; then
  "$PRINTF" 'FAIL: refblock identity fixture reached NO byte-identical declaration — the identical-value rows pass CLEAN whether they were judged identical or never scanned at all, so their zeros cannot be read\n' >&2
  exit 1
fi
if [ "$rb_fail" -gt 0 ]; then
  "$PRINTF" 'FAIL: refblock identity arms did not behave as committed:\n%s' "$rb_fail_lines" >&2
  exit 1
fi
if [ "$rb_divergent" -gt 0 ]; then
  "$PRINTF" 'FAIL: REFBLOCK_RE declared outside lib/fragile-ref-patterns.sh with a DIVERGENT value.\nEither source the library or make the value byte-identical to it:\n%s\n' \
    "$("$PRINTF" '%s\n' "$rb_real_verdicts" | "$GREP" '^NAME-DIVERGENT	' || true)" >&2
  exit 1
fi
# --- marker-resolution arm verdicts -------------------------------------------------------
# Ordered so the arm's own readability is asserted BEFORE its results are believed, matching
# the refblock arm's one-armed and reachability guards above.
if [ -z "$mk_skip" ]; then
  if [ "$mk_flag" -eq 0 ] || [ "$mk_clean" -eq 0 ]; then
    "$PRINTF" 'FAIL: marker-resolution fixture is one-armed (%d FLAG / %d CLEAN) — a zero from it would be unreadable\n' \
      "$mk_flag" "$mk_clean" >&2
    exit 1
  fi
  # REACHABILITY. CLEAN is also what a hook that exited early produces — at its scope gate, its
  # allowlist, or a lib guard — so a row full of passing CLEANs cannot on its own distinguish
  # "adjudicated and found exempt" from "never adjudicated". A non-zero exit is reachable ONLY
  # through the scope gate, the marker read and the Class L detector in order, so one observed
  # FLAG is the positive evidence that the CLEAN rows' zeros are load-bearing.
  if [ "$mk_observed_flag" -eq 0 ]; then
    "$PRINTF" 'FAIL: marker-resolution arm observed NO flagged row — every row reported CLEAN, which is also what a hook that exited before adjudicating would report, so none of these results can be read\n' >&2
    exit 1
  fi
  if [ "$mk_fail" -gt 0 ]; then
    "$PRINTF" 'FAIL: per-file override markers did not resolve as committed:\n%s' "$mk_fail_lines" >&2
    exit 1
  fi
fi
exit 0
