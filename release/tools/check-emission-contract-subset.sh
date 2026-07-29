#!/usr/bin/env bash
# check-emission-contract-subset.sh — CIAC-3 mechanical gate.
#
# INVARIANT
#   The set of event classes a downstream gate ASSERTS on must be a SUBSET of the
#   MUST rows the orchestration playbook INSTRUCTS the hub to emit.
#
#       comm -23 asserted instructed   MUST be empty
#
#   An asserted class the playbook does not instruct is a gate asserting an
#   unemitted class: it can only ever fail, because nothing in the pipeline is
#   told to write it. CIAC-3 forbids exactly that. This script makes the relation
#   CHECKED rather than reviewed — the failure lands in CI, not in a reviewer's
#   attention budget.
#
#   The converse is deliberately NOT an error. An instructed class that no gate
#   asserts on is fine: the playbook may instruct emissions ahead of any gate
#   that consumes them.
#
# CLASS NOTATION
#   A class is `event_type/event_subtype`, e.g. `decision/scope-lock`.
#
# SOURCES
#   INSTRUCTED — the MUST rows inside the <!-- EMISSION-CONTRACT:BEGIN/END -->
#                delimiters of the playbook. This file owns the delimiters;
#                exactly one BEGIN marker may exist.
#   ASSERTED   — a newline-delimited file of classes, supplied by whichever gate
#                enforces a minimum emission set (e.g. a --check-decision-emission
#                implementation). Passed as $1 or via $ASSERTED_SET_FILE.
#
# USAGE
#   check-emission-contract-subset.sh [ASSERTED_SET_FILE]
#   check-emission-contract-subset.sh --self-test
#
# EXIT
#   0  subset holds (or no asserted set is present yet — SKIP)
#   1  an asserted class is not instructed, or the contract block is malformed
#
# Introduced by the decision-telemetry-emission release (#3723).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PLAYBOOK="${PLAYBOOK_OVERRIDE:-${REPO_ROOT}/release/skills/release-hub/references/orchestration-playbook.md}"

die()  { echo "FAIL: $*" >&2; exit 1; }
info() { echo "$*"; }

# ---------------------------------------------------------------------------
# extract_instructed <playbook-path>
#   Emits one `event_type/event_subtype` per MUST row, sorted and de-duplicated.
#   Column addressing, not positional regex: with a leading pipe, awk -F'|' puts
#   gate=$2 procedure=$3 event_type=$4 event_subtype=$5 actor=$6 obligation=$7.
# ---------------------------------------------------------------------------
# Delimiter lines are matched ANCHORED (the whole HTML-comment line), never as a
# bare substring — prose in the playbook may legitimately name the marker, and a
# substring matcher would count that mention as a second block. Learned the hard
# way: an unanchored matcher made this script's own guard fire on its own docs,
# which silently turned the negative self-tests into false passes.
BEGIN_RE='^<!-- EMISSION-CONTRACT:BEGIN -->[[:space:]]*$'
END_RE='^<!-- EMISSION-CONTRACT:END -->[[:space:]]*$'

extract_instructed() {
  awk '/^<!-- EMISSION-CONTRACT:BEGIN -->[[:space:]]*$/,/^<!-- EMISSION-CONTRACT:END -->[[:space:]]*$/' "$1" \
    | awk -F'|' 'NF >= 7 && $7 ~ /MUST/ {
          gsub(/^[ \t]+|[ \t]+$/, "", $4)
          gsub(/^[ \t]+|[ \t]+$/, "", $5)
          if ($4 != "" && $5 != "") print $4"/"$5
        }' \
    | sort -u
}

# Guard: exactly one contract block. A parallel table is prohibited (extension
# seam: downstream slices add rows INSIDE the delimiters, never a second block).
# Returns 1 rather than exiting, so --self-test can call it repeatedly.
check_block_integrity() {
  local begins ends
  begins=$(grep -cE "$BEGIN_RE" "$PLAYBOOK" || true)
  ends=$(grep -cE "$END_RE" "$PLAYBOOK" || true)
  if [ "$begins" -ne 1 ]; then
    echo "FAIL: expected exactly 1 EMISSION-CONTRACT:BEGIN marker in $(basename "$PLAYBOOK"), found ${begins} (a parallel contract table is prohibited)" >&2
    return 1
  fi
  if [ "$ends" -ne 1 ]; then
    echo "FAIL: expected exactly 1 EMISSION-CONTRACT:END marker in $(basename "$PLAYBOOK"), found ${ends}" >&2
    return 1
  fi
  return 0
}

# run_check RETURNS its status (never exits) and cleans up its own scratch dir
# explicitly — no RETURN trap, which would fire in the caller's scope and delete
# the caller's scratch dir. --self-test depends on that property.
run_check() {
  local asserted_file="${1:-}"
  local tmp rc=0

  if [ ! -f "$PLAYBOOK" ]; then
    echo "FAIL: playbook not found: ${PLAYBOOK}" >&2
    return 1
  fi
  check_block_integrity || return 1

  tmp="$(mktemp -d)"

  extract_instructed "$PLAYBOOK" > "${tmp}/instructed"
  if [ ! -s "${tmp}/instructed" ]; then
    echo "FAIL: the EMISSION-CONTRACT block declares no MUST rows — a contract with no total obligations cannot bound any gate" >&2
    rm -rf "$tmp"; return 1
  fi

  if [ -z "$asserted_file" ] || [ ! -f "$asserted_file" ]; then
    info "SKIP: no asserted-set file supplied (pass a path or set ASSERTED_SET_FILE)."
    info "      instructed MUST classes ($(wc -l < "${tmp}/instructed" | tr -d ' ')):"
    sed 's/^/        /' "${tmp}/instructed"
    rm -rf "$tmp"; return 0
  fi

  # Tolerate comments and blank lines in the asserted set.
  grep -vE '^[[:space:]]*(#|$)' "$asserted_file" \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | sort -u > "${tmp}/asserted"

  comm -23 "${tmp}/asserted" "${tmp}/instructed" > "${tmp}/extra"

  if [ -s "${tmp}/extra" ]; then
    echo "FAIL: asserted classes not instructed by the playbook:" >&2
    sed 's/^/  /' "${tmp}/extra" >&2
    echo "" >&2
    echo "  A gate asserting a class the playbook never instructs can only fail." >&2
    echo "  Fix by adding the class as a MUST row inside the EMISSION-CONTRACT" >&2
    echo "  block, or by narrowing the asserted set." >&2
    rc=1
  else
    info "OK: emission-contract subset holds ($(wc -l < "${tmp}/asserted" | tr -d ' ') asserted class(es) subset-of $(wc -l < "${tmp}/instructed" | tr -d ' ') instructed MUST class(es))"
  fi

  rm -rf "$tmp"
  return "$rc"
}

# ---------------------------------------------------------------------------
# --self-test: asserts BOTH directions of the invariant against fixtures, so a
# predicate that drifts into always-passing fails the test rather than shipping.
# ---------------------------------------------------------------------------
self_test() {
  local tmp rc fails=0
  tmp="$(mktemp -d)"

  extract_instructed "$PLAYBOOK" > "${tmp}/instructed"
  if [ ! -s "${tmp}/instructed" ]; then
    echo "self-test FAIL: no MUST rows extracted from the live playbook" >&2
    rm -rf "$tmp"; return 1
  fi
  echo "self-test: extracted $(wc -l < "${tmp}/instructed" | tr -d ' ') MUST class(es) from the live contract block"

  # Positive: a proper subset must pass.
  head -1 "${tmp}/instructed" > "${tmp}/ok.txt"
  if run_check "${tmp}/ok.txt" >/dev/null 2>&1; then
    echo "  PASS  positive — proper subset exits 0"
  else
    echo "  FAIL  positive — proper subset should exit 0" >&2; fails=$((fails+1))
  fi

  # Positive: the full instructed set must pass (subset is non-strict).
  cp "${tmp}/instructed" "${tmp}/full.txt"
  if run_check "${tmp}/full.txt" >/dev/null 2>&1; then
    echo "  PASS  positive — full set exits 0"
  else
    echo "  FAIL  positive — full set should exit 0" >&2; fails=$((fails+1))
  fi

  # Negative: an asserted class the playbook does not instruct must fail.
  { cat "${tmp}/instructed"; echo "decision/never-instructed-class"; } > "${tmp}/bad.txt"
  run_check "${tmp}/bad.txt" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 1 ]; then
    echo "  PASS  negative — uninstructed asserted class exits 1"
  else
    echo "  FAIL  negative — uninstructed asserted class should exit 1 (got ${rc})" >&2; fails=$((fails+1))
  fi

  # Negative: a CONDITIONAL row is not a MUST row, so asserting on one must fail.
  local cond
  cond="$(awk '/^<!-- EMISSION-CONTRACT:BEGIN -->[[:space:]]*$/,/^<!-- EMISSION-CONTRACT:END -->[[:space:]]*$/' "$PLAYBOOK" \
          | awk -F'|' 'NF >= 7 && $7 ~ /CONDITIONAL/ {
                gsub(/^[ \t]+|[ \t]+$/, "", $4); gsub(/^[ \t]+|[ \t]+$/, "", $5)
                print $4"/"$5 }' | sort -u | comm -23 - "${tmp}/instructed" | head -1)"
  if [ -n "$cond" ]; then
    echo "$cond" > "${tmp}/cond.txt"
    run_check "${tmp}/cond.txt" >/dev/null 2>&1; rc=$?
    if [ "$rc" -eq 1 ]; then
      echo "  PASS  negative — CONDITIONAL-only class (${cond}) exits 1"
    else
      echo "  FAIL  negative — CONDITIONAL-only class should exit 1 (got ${rc})" >&2; fails=$((fails+1))
    fi
  else
    echo "  SKIP  negative — no CONDITIONAL class disjoint from the MUST set"
  fi

  rm -rf "$tmp"
  [ "$fails" -eq 0 ] || { echo "self-test: ${fails} failure(s)" >&2; return 1; }
  echo "self-test: all assertions passed"
  return 0
}

case "${1:-}" in
  --self-test) self_test ;;
  -h|--help)   sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
  *)           run_check "${1:-${ASSERTED_SET_FILE:-}}" ;;
esac
