#!/usr/bin/env bash
# test_version_freeness.sh — standalone Dev-Testing harness for the pre-merge
# version-freeness gate (#1677). Sibling of core/deploy/tests/test_version_stamping.sh;
# runs DIRECTLY in CI (bash release/tools/test_version_freeness.sh), NOT through any
# deploy.sh sub-command. deploy.sh exposes no `--self-test` surface (its arg parser
# is --deploy/--all/--check/--check-lifecycle/--report), so the Stage-5 spec's
# "deploy.sh --self-test" acceptance gate is unrunnable as written; per the Stage-5
# adversarial review FM-1, the fixtures live here and CI invokes this file directly,
# exactly as install-tests.yml runs test_version_stamping.sh.
#
# What it guards (the executable surface of #1677):
#   1. The FREENESS verdict contract — the pure decision the deploy.sh Check 41 body
#      and the --check-version-freeness probe both compute. A candidate version is
#      FREE iff no canonical member of the claimed_set tuple-equals it; a collision
#      is NOT_FREE; a non-canonical tag in the set or a malformed candidate is
#      UNDECIDABLE (fail-closed — DD4 / FM-3), NOT silently skipped.
#   2. The verdict->exit contract (Stage-5 adversarial review FM-2) — the contract
#      the CI merge gate depends on: the probe's exit code reflects the VERDICT
#      (0 only on FREE, 1 on NOT_FREE/UNDECIDABLE), decoupled from the lifecycle
#      surface's warn-mode emit. A gate that greens on "cannot decide" is the exact
#      reactive-failure this slice removes; this harness asserts it red-exits.
#
# The freeness CORE is sourced from version-grammar.sh's comparator (#1676 SSOT) —
# this harness adds NO version parser of its own (DD2 / FM-1 "no 4th parser"). The
# verdict function _vf_freeness_core() below is the SAME contract the deploy.sh
# Check 41 body implements; keeping it here (sourcing the SSOT comparator) lets CI
# falsify the decision logic credential-free and offline.
#
# Hermetic + offline: pure functions + literal candidate/tag fixtures; no network,
# no gh, no tag read, no operator state. Portable bash; runs on macOS CI and Linux.
#
# Run from repo root:
#   bash release/tools/test_version_freeness.sh
#
# Returns non-zero on any failing fixture.

set -uo pipefail

# SCRIPT_DIR = release/tools; the SSOT comparator is a sibling in the same dir, so
# resolve it directly off SCRIPT_DIR (no repo-root round-trip — robust to the
# checkout path / clone-dir name).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GRAMMAR_SRC="${SCRIPT_DIR}/version-grammar.sh"

PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); }
bad()  { FAIL=$((FAIL + 1)); printf 'FAIL [%s]: %s\n' "$1" "$2"; }

# --- Source the SSOT comparator (no 4th parser; DD2). Pass an empty positional so
#     version-grammar.sh's --self-test branch does not fire on our $1. ---
if [[ ! -f "$GRAMMAR_SRC" ]]; then
  echo "test_version_freeness.sh: FAIL — version-grammar.sh (#1676 SSOT) not found at $GRAMMAR_SRC" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$GRAMMAR_SRC" ""

# ===========================================================================
# _vf_freeness_core <candidate> <claimed_tag>...
#
# THE VERDICT CONTRACT (mirrored byte-for-decision in deploy.sh Check 41). Pure:
# no host I/O — the candidate and the claimed_set are passed in. Echoes EXACTLY one
# verdict token on stdout; the caller maps the token to an exit code / a warn-emit.
#
#   FREE        — candidate is canonical and tuple-collides with no claimed member.
#   NOT_FREE    — candidate tuple-equals a claimed member (collision). The matched
#                 tag is echoed after the token (FREE/NOT_FREE <tag>).
#   UNDECIDABLE — candidate is non-canonical (malformed), OR a member of the
#                 claimed_set is non-canonical (a tag this grammar cannot order, so
#                 the freeness guarantee cannot be made). Fail-closed (DD4/FM-3):
#                 the reason is echoed after the token.
#
# Comparison is version_cmp (the #1676 SSOT integer-triple comparator), so the
# hotfix-vs-minor case (v2.06.1 vs v2.07) is decided correctly — a vX.Y-only
# comparator misses it. This function adds no parser of its own.
# ===========================================================================
_vf_freeness_core() {
  local candidate="$1"; shift
  if ! version_canonical "$candidate"; then
    printf 'UNDECIDABLE malformed-candidate:%s\n' "$candidate"
    return 0
  fi
  local t
  for t in "$@"; do
    [[ -n "$t" ]] || continue
    if ! version_canonical "$t"; then
      # Fail-closed: a non-canonical tag may occupy the candidate's slot but this
      # grammar cannot order it. DD4 converts #1676's dead `continue` into a pinned
      # UNDECIDABLE so the operator resolves the untaggable state before merge.
      printf 'UNDECIDABLE non-canonical-tag:%s\n' "$t"
      return 0
    fi
    if [[ "$(version_cmp "$candidate" "$t")" == "0" ]]; then
      printf 'NOT_FREE %s\n' "$t"
      return 0
    fi
  done
  printf 'FREE\n'
}

# _vf_verdict_token <core-output>  — the bare verdict (first word).
_vf_verdict_token() { printf '%s' "${1%% *}"; }

# _vf_exit_for_verdict <verdict>  — THE VERDICT->EXIT CONTRACT (FM-2). The probe's
#   exit is verdict-driven, NOT warn-mode-driven: 0 ONLY on FREE; 1 on NOT_FREE or
#   UNDECIDABLE (fail-closed). This is the mapping --check-version-freeness applies
#   so the CI merge gate blocks on exactly the undecidable cases DD4 must block.
_vf_exit_for_verdict() {
  case "$1" in
    FREE) return 0 ;;
    NOT_FREE|UNDECIDABLE) return 1 ;;
    *) return 1 ;;   # any unknown verdict is fail-closed
  esac
}

# ===========================================================================
# VF-1..VF-N — FREENESS verdict fixtures (candidate vs a fixed sandbox claimed_set).
# Sandbox mirrors the shipped lineage shape (a minor run plus a real hotfix), so
# the hotfix-vs-minor decidability is exercised against the SSOT comparator.
# ===========================================================================
SANDBOX=(v2.06 v2.06.1 v2.07 v2.08)

_t_verdict() {  # <expected-token> <label> <candidate> <tag>...
  local exp="$1" label="$2"; shift 2
  local out tok
  out="$(_vf_freeness_core "$@")"
  tok="$(_vf_verdict_token "$out")"
  if [[ "$tok" == "$exp" ]]; then ok; else bad "$label" "_vf_freeness_core '$*' expected $exp got '$out'"; fi
}

echo "=== VF: FREENESS verdict fixtures ==="
# VF-1 — above the set, no collision -> FREE.
_t_verdict FREE     "VF-1 above-set free"          v2.09   "${SANDBOX[@]}"
# VF-2 — exact collision with a claimed minor -> NOT_FREE.
_t_verdict NOT_FREE "VF-2 minor collision"         v2.07   "${SANDBOX[@]}"
# VF-3 — collision with a HOTFIX (v2.06.1) — the case a vX.Y-only check misses;
#        only the SSOT integer-triple comparator catches it.
_t_verdict NOT_FREE "VF-3 hotfix collision"        v2.06.1 "${SANDBOX[@]}"
# VF-4 — a new hotfix slot above the existing hotfix -> decidably FREE.
_t_verdict FREE     "VF-4 new hotfix slot free"    v2.06.2 "${SANDBOX[@]}"
# VF-5 — FAIL-CLOSED on a non-canonical tag in the set (DD4 / FM-3): not a silent
#        `continue`; the gate must refuse to certify freeness over an unorderable tag.
_t_verdict UNDECIDABLE "VF-5 non-canonical tag fail-closed" v2.07 v2.06 "v2.99-foo" v2.07
# VF-6 — FAIL-CLOSED on a malformed candidate (DD4): a suffix candidate is not in
#        the grammar; freeness is undecidable at the merge gate.
_t_verdict UNDECIDABLE "VF-6 malformed candidate fail-closed" "v2.07b" "${SANDBOX[@]}"
# VF-7 — leading-zero equivalence: v2.6 (candidate) collides with v2.06 (claimed)
#        because version_cmp treats them as the same (2,6,0) tuple.
_t_verdict NOT_FREE "VF-7 leading-zero equivalence" v2.6 "${SANDBOX[@]}"

# ===========================================================================
# VE-1..VE-N — the VERDICT->EXIT contract (FM-2). The CI merge gate's fail-closed
# behavior depends ENTIRELY on this mapping: the probe exits per the verdict,
# regardless of any warn-mode emit on the lifecycle surface.
# ===========================================================================
echo "=== VE: verdict->exit contract (FM-2) ==="
_t_exit() {  # <verdict> <expected-rc> <label>
  local v="$1" exp="$2" label="$3"
  set +e; _vf_exit_for_verdict "$v"; local rc=$?; set -e 2>/dev/null || true
  if [[ "$rc" -eq "$exp" ]]; then ok; else bad "$label" "_vf_exit_for_verdict $v expected rc=$exp got rc=$rc"; fi
}
_t_exit FREE        0 "VE-1 FREE -> exit 0"
_t_exit NOT_FREE    1 "VE-2 NOT_FREE -> exit 1 (fail-closed)"
_t_exit UNDECIDABLE 1 "VE-3 UNDECIDABLE -> exit 1 (fail-closed; the case DD4 must block)"

# End-to-end exit assertions: drive the core through the exit mapping, proving a
# collision and an undecidable both red-exit and a free candidate greens — the
# property QA-1's precision probe and DT-2 assert against deploy.sh.
echo "=== VX: end-to-end core->exit (the gate's real decision path) ==="
_t_e2e() {  # <expected-rc> <label> <candidate> <tag>...
  local exp="$1" label="$2"; shift 2
  local out tok
  out="$(_vf_freeness_core "$@")"
  tok="$(_vf_verdict_token "$out")"
  set +e; _vf_exit_for_verdict "$tok"; local rc=$?; set -e 2>/dev/null || true
  if [[ "$rc" -eq "$exp" ]]; then ok; else bad "$label" "core('$*')=$out -> tok=$tok -> rc=$rc, expected $exp"; fi
}
_t_e2e 0 "VX-1 free candidate -> gate exits 0"          v2.09   "${SANDBOX[@]}"
_t_e2e 1 "VX-2 claimed candidate -> gate exits 1"       v2.07   "${SANDBOX[@]}"
_t_e2e 1 "VX-3 hotfix-collision candidate -> exits 1"   v2.06.1 "${SANDBOX[@]}"
_t_e2e 1 "VX-4 undecidable (bad tag) -> gate exits 1"   v2.07 v2.06 "v2.99-foo"
_t_e2e 1 "VX-5 undecidable (bad candidate) -> exits 1"  "v2.07b" "${SANDBOX[@]}"

# ===========================================================================
# Summary
# ===========================================================================
echo ""
echo "----------------------------------------------------------------------"
if [[ "$FAIL" -eq 0 ]]; then
  echo "test_version_freeness.sh: PASS ($PASS fixtures green; verdict contract + verdict->exit (FM-2) + fail-closed (DD4/FM-3) + hotfix decidability via SSOT comparator)"
  exit 0
else
  echo "test_version_freeness.sh: FAIL ($FAIL failing / $PASS passing)"
  exit 1
fi
