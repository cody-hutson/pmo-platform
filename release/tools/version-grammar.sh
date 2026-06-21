#!/usr/bin/env bash
# version-grammar.sh — Canonical version-grammar SSOT (validate / parse / compare).
#
# This is the SINGLE SOURCE OF TRUTH for the platform's version grammar and the
# total order over versions. Freeness checks, deploy-path version comparisons, and
# the Stage-12 claim mechanism MUST `source` this library and call its functions —
# they MUST NOT re-encode the regex or the comparison inline. A copied-inline
# "fallback" regex is a divergence defect: it re-creates the exact grammar drift
# this library exists to eliminate. (Sourcing contract — see "Consumer contract".)
#
# Canonical grammar (the ONE regex): ^v[0-9]+\.[0-9]+(\.[0-9]+)?$
#   - `v` prefix, then two-or-three dot-separated runs of decimal digits.
#   - Two-component `vMAJOR.MINOR` and three-component `vMAJOR.MINOR.PATCH` are
#     canonical; an absent PATCH is semantically 0.
#   - Components are `[0-9]+` (one-or-more digits), NOT strict-SemVer
#     `(0|[1-9][0-9]*)`. The shipped tag set contains leading-zero-padded minors
#     (`v2.06`, `v1.05`); a strict-SemVer component would reject those shipped
#     tags. Parsing coerces each component to base-10 (`10#`) so `06` -> integer 6
#     and a zero-padded component is never misread as octal.
#   - Suffix forms (`v2.07b`, `v2.04b-1`) are REJECTED — they are not in the
#     grammar (they contain non-digits). Suffix never shipped on the reachable
#     lineage; the canonical hotfix form is `vMAJOR.MINOR.PATCH`.
#
# Comparison: parse each version to an integer triple (MAJOR, MINOR, PATCH) and
# compare tuple-wise. This is a TOTAL ORDER over the canonical set. It makes the
# hotfix-vs-minor case decidable: v2.06.1 -> (2,6,1) and v2.07 -> (2,7,0), so
# (2,6,1) < (2,7,0) — the hotfix and the next minor occupy distinct, ordered slots
# and never collide. A two-component (vX.Y) string comparator cannot see the patch
# field and mis-decides this case — the defect this library closes.
#
# Consumer contract (load-bearing):
#   1. SOURCE, do not copy. Consumers `source` this file and call the functions.
#      Resolve the path relative to the repo root (e.g. via
#      `"$(git rev-parse --show-toplevel)/release/tools/version-grammar.sh"`) or
#      relative to the consumer's own `${BASH_SOURCE[0]%/*}`. A copied-inline regex
#      is a divergence defect.
#   2. CANONICAL-FIRST CALL ORDER. `version_canonical` is the SOLE input gate.
#      `version_parse` and `version_cmp` call `version_canonical` first and return
#      exit 1 (no stdout) on a non-canonical argument. Their behavior on input that
#      bypassed the gate is undefined — always let the gate run (do not hand
#      `version_parse`/`version_cmp` a value you have not allowed to fail the gate).
#
# Boundary (not this library's job):
#   - This library defines WHAT a valid version is and HOW two versions order. It
#     does NOT assert tags were created in ascending order (creation is
#     non-monotonic and operator-accepted) and it does NOT decide "what is the next
#     free version" — that is the version-allocation rule's job, which consumes
#     this comparator. The orphan v3.20 lineage is grammar-valid (`(3,20,0)`);
#     whether it occupies an allocatable slot is the allocation rule's call, not
#     the grammar's.
#
# Hermetic: pure functions, no side effects, no network. Sourceable by deploy.sh,
# CI, the Stage-12 executor, and the self-tests below.

# version_canonical <string>
#   Exit 0 if <string> is a canonical version, 1 otherwise. No stdout.
#   Canonical iff it matches ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ — the SOLE input gate.
version_canonical() {
  local v="$1"
  [[ "$v" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]
}

# version_parse <string>
#   Echo "MAJOR MINOR PATCH" — three space-separated base-10 integers; an absent
#   PATCH is 0. Leading zeros are stripped via base-10 coercion (10#). Returns
#   exit 1 (no stdout) if <string> is not canonical (the canonical-first gate).
version_parse() {
  local v="$1"
  version_canonical "$v" || return 1
  local body="${v#v}"                 # strip the leading 'v'
  local major="${body%%.*}"           # up to the first '.'
  body="${body#*.}"                   # remainder after MAJOR.
  local minor="${body%%.*}"           # up to the next '.' (or the whole rest)
  local patch=0
  if [[ "$body" == *.* ]]; then
    patch="${body#*.}"                # remainder after MINOR.
  fi
  printf '%s %s %s' "$((10#$major))" "$((10#$minor))" "$((10#$patch))"
}

# version_cmp <a> <b>
#   Echo -1 if a<b, 0 if a==b, 1 if a>b — on the (MAJOR,MINOR,PATCH) total order.
#   Returns exit 1 if EITHER argument is non-canonical (canonical-first gate, via
#   version_parse). Equality is triple-equality, not string-equality: v2.6 and
#   v2.06 both parse to (2,6,0) and compare equal (same slot).
version_cmp() {
  local pa pb
  pa="$(version_parse "$1")" || return 1
  pb="$(version_parse "$2")" || return 1
  local a1 a2 a3 b1 b2 b3
  read -r a1 a2 a3 <<<"$pa"
  read -r b1 b2 b3 <<<"$pb"
  if   (( a1 != b1 )); then (( a1 < b1 )) && echo -1 || echo 1
  elif (( a2 != b2 )); then (( a2 < b2 )) && echo -1 || echo 1
  elif (( a3 != b3 )); then (( a3 < b3 )) && echo -1 || echo 1
  else echo 0; fi
}

# ---------------------------------------------------------------------------
# Self-test — run `bash release/tools/version-grammar.sh --self-test`.
# Hermetic; no network, no tags read; exits 0 iff every fixture is green.
# Fixtures cover the parent #1676 ACs and the Stage-5 adversarial corrections:
#   - validate: X.Y / X.Y.Z / leading-zero (shipped) / suffix-reject / malformed
#   - compare:  hotfix-vs-minor collision, numeric-not-lexical, leading-zero equiv
#   - exit-contract: version_parse / version_cmp exit 1 (no stdout) on non-canonical
#   - freeness: a reference FREENESS over a fixed sandbox tag set, incl. the
#     non-canonical-existing-tag path (the policy the consumer must decide).
# ---------------------------------------------------------------------------

# Reference FREENESS used by the self-test ONLY (the executable freeness GATE in
# deploy.sh / CI / Stage-12 is a downstream slice — #1677 / #769 — that implements
# this same contract against the live tag set; it is NOT shipped here).
#   _vg_freeness <candidate> <tag>...
#   Echo FREE if no canonical tag shares the candidate's triple; NOT_FREE on a
#   collision. NON_CANONICAL_TAG if a non-canonical tag is present (fail-closed:
#   the freeness guarantee cannot be made over a tag this grammar cannot order —
#   the consumer (#1677) decides the production policy; the self-test pins the
#   fail-closed default so the path is exercised, not left dead-and-unspecified).
_vg_freeness() {
  local candidate="$1"; shift
  version_canonical "$candidate" || { echo "BAD_CANDIDATE"; return 0; }
  local t
  for t in "$@"; do
    if ! version_canonical "$t"; then
      echo "NON_CANONICAL_TAG"; return 0
    fi
    if [[ "$(version_cmp "$candidate" "$t")" == "0" ]]; then
      echo "NOT_FREE"; return 0
    fi
  done
  echo "FREE"
}

_vg_self_test() {
  local failures=0

  # --- version_canonical fixtures (input, expected: PASS|REJECT) ---
  # F1 X.Y two-component | F2 X.Y.Z (real hotfix) | F3/F4 leading-zero shipped
  # F5/F6 suffix REJECT (the tighten) | F7 no-v | F8 empty | F9 one-component
  # F10 four-component
  _vg_t_canon() {  # <input> <PASS|REJECT> <label>
    local got="REJECT"
    version_canonical "$1" && got="PASS"
    if [[ "$got" != "$2" ]]; then
      echo "FAIL [$3]: version_canonical '$1' expected $2 got $got"
      failures=$((failures+1))
    fi
  }
  _vg_t_canon "v2.12"      PASS   "F1 X.Y"
  _vg_t_canon "v2.06.1"    PASS   "F2 X.Y.Z hotfix"
  _vg_t_canon "v2.06"      PASS   "F3 leading-zero minor"
  _vg_t_canon "v1.05"      PASS   "F4 leading-zero minor major1"
  _vg_t_canon "v2.07b"     REJECT "F5 suffix"
  _vg_t_canon "v2.04b-1"   REJECT "F6 suffix+counter"
  _vg_t_canon "2.12"       REJECT "F7 no v prefix"
  _vg_t_canon ""           REJECT "F8 empty"
  _vg_t_canon "v2"         REJECT "F9 one-component"
  _vg_t_canon "v2.07.1.3"  REJECT "F10 four-component"

  # --- version_parse fixtures (input -> expected "M m p") ---
  _vg_t_parse() {  # <input> <expected-triple> <label>
    local got; got="$(version_parse "$1")"
    if [[ "$got" != "$2" ]]; then
      echo "FAIL [$3]: version_parse '$1' expected '$2' got '$got'"
      failures=$((failures+1))
    fi
  }
  _vg_t_parse "v2.12"   "2 12 0" "P1 X.Y -> patch 0"
  _vg_t_parse "v2.06.1" "2 6 1"  "P2 X.Y.Z"
  _vg_t_parse "v2.06"   "2 6 0"  "P3 leading-zero minor -> 6"
  _vg_t_parse "v1.05"   "1 5 0"  "P4 leading-zero minor -> 5"

  # --- version_cmp fixtures (a, b, expected) ---
  _vg_t_cmp() {  # <a> <b> <expected> <label>
    local got; got="$(version_cmp "$1" "$2")"
    if [[ "$got" != "$3" ]]; then
      echo "FAIL [$4]: version_cmp '$1' '$2' expected $3 got '$got'"
      failures=$((failures+1))
    fi
  }
  _vg_t_cmp "v2.06.1" "v2.07"   -1 "C-1 hotfix < next minor"      # the #1676 case
  _vg_t_cmp "v2.07"   "v2.06.1"  1 "C-2 next minor > hotfix"
  _vg_t_cmp "v2.06"   "v2.06.1" -1 "C-3 minor < its own hotfix"
  _vg_t_cmp "v2.06.1" "v2.06.1"  0 "C-4 identical triple"
  _vg_t_cmp "v2.6"    "v2.06"    0 "C-5 leading-zero equivalence"
  _vg_t_cmp "v2.10"   "v2.9"     1 "C-6 numeric not lexical"      # 10 > 9
  _vg_t_cmp "v2.15"   "v3.20"   -1 "C-7 cross-major ordering"

  # --- exit-contract fixtures (CD-3): parse/cmp exit 1, no stdout, on non-canonical ---
  local out rc
  out="$(version_parse "v2.07b" 2>/dev/null)"; rc=$?
  if [[ $rc -ne 1 || -n "$out" ]]; then
    echo "FAIL [X-1]: version_parse non-canonical expected exit 1 + no stdout, got rc=$rc out='$out'"
    failures=$((failures+1))
  fi
  out="$(version_cmp "v2.07b" "v2.07" 2>/dev/null)"; rc=$?
  if [[ $rc -ne 1 || -n "$out" ]]; then
    echo "FAIL [X-2]: version_cmp non-canonical expected exit 1 + no stdout, got rc=$rc out='$out'"
    failures=$((failures+1))
  fi

  # --- reference-FREENESS fixtures (candidate vs sandbox tag set) ---
  _vg_t_free() {  # <expected> <label> <candidate> <tag>...
    local exp="$1" label="$2"; shift 2
    local got; got="$(_vg_freeness "$@")"
    if [[ "$got" != "$exp" ]]; then
      echo "FAIL [$label]: _vg_freeness '$*' expected $exp got $got"
      failures=$((failures+1))
    fi
  }
  local SANDBOX=(v2.06 v2.06.1 v2.07 v2.08)
  _vg_t_free FREE     "FR-1 above set"            v2.09   "${SANDBOX[@]}"
  _vg_t_free NOT_FREE "FR-2 minor collision"      v2.07   "${SANDBOX[@]}"
  _vg_t_free NOT_FREE "FR-3 hotfix collision"     v2.06.1 "${SANDBOX[@]}"   # vX.Y-only check misses
  _vg_t_free FREE     "FR-4 new hotfix slot"      v2.06.2 "${SANDBOX[@]}"
  # FR-5: a non-canonical existing tag triggers the fail-closed path (CD-3 / FM-3).
  _vg_t_free NON_CANONICAL_TAG "FR-5 non-canonical tag" v2.99 v2.98 "v2.99-foo"

  if [[ $failures -eq 0 ]]; then
    echo "version-grammar.sh --self-test: PASS (all fixtures green)"
    return 0
  else
    echo "version-grammar.sh --self-test: FAIL ($failures failing fixture(s))"
    return 1
  fi
}

# Only act on --self-test when executed directly; sourcing defines functions only.
if [[ "${1:-}" == "--self-test" ]]; then
  _vg_self_test
  exit $?
fi
