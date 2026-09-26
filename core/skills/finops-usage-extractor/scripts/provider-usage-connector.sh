#!/bin/bash
# finops-usage-extractor — provider usage/cost connector (OPTIONAL, OFF by default).
#
# Plan-gated enrichment ONLY. On a flat-rate Max plan the local session store
# (extract-usage.sh) is the AUTHORITATIVE source; this connector is never a hard
# dependency and is never on the critical path. Extraction completes fully from
# local data alone with this connector absent or disabled (AC #4 / #3909).
#
# Enablement gate (BOTH required): the --enable flag AND an admin API key in the
# environment (${ANTHROPIC_ADMIN_KEY}). Absent either → a one-line notice + exit 0
# (never fail the pipeline).
#
# Security (secrets-handling-policy.md): the connector performs READ-ONLY GETs
# against Anthropic Admin usage/cost endpoints and NEVER enters, writes, echoes, or
# commits the key. The operator provisions the key (env or operator config); the
# agent does not. When enabled it emits `record:"provider"` enrichment lines
# (a reserved-optional record kind declared at store schema v1.0.0).
#
# Usage:
#   bash provider-usage-connector.sh [--enable] [--help] [--self-test]
#
# Exit codes: 0 ok (incl. disabled no-op, and a passing --self-test) · 1 a --self-test
# assertion failed · 2 usage error.

set -uo pipefail

# --self-test: asserts the whole contract this script implements, offline and with no
# credential: the disabled default, --enable with no admin key, --help, an unknown
# argument, and that a key present in the environment is never printed. Each case
# re-invokes this file in a child shell with stdin on the null device and the key
# blanked or replaced by a sentinel, so a real key in the caller's environment is never
# used. Output is matched with [[ ]], never piped into a short-circuiting reader.
self_test() {
  local self="${BASH_SOURCE[0]}" out rc pass=0
  local sentinel="selftest-sentinel-not-a-credential"
  out="$(ANTHROPIC_ADMIN_KEY='' bash "$self" </dev/null 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && [[ "$out" == *'disabled (no --enable)'* ]]; then pass=$((pass+1))
  else echo "self-test FAIL: default path (rc=$rc)" >&2; return 1; fi
  out="$(ANTHROPIC_ADMIN_KEY='' bash "$self" --enable </dev/null 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && [[ "$out" == *'disabled (no ANTHROPIC_ADMIN_KEY in env)'* ]]; then pass=$((pass+1))
  else echo "self-test FAIL: --enable without a key (rc=$rc)" >&2; return 1; fi
  out="$(ANTHROPIC_ADMIN_KEY='' bash "$self" --help </dev/null 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && [[ "$out" == *'provider usage/cost connector'* ]]; then pass=$((pass+1))
  else echo "self-test FAIL: --help (rc=$rc)" >&2; return 1; fi
  out="$(ANTHROPIC_ADMIN_KEY='' bash "$self" --no-such-flag </dev/null 2>&1)"; rc=$?
  if [ "$rc" -eq 2 ] && [[ "$out" == *'unknown argument'* ]]; then pass=$((pass+1))
  else echo "self-test FAIL: an unknown argument must exit 2 (rc=$rc)" >&2; return 1; fi
  out="$(ANTHROPIC_ADMIN_KEY="$sentinel" bash "$self" --enable </dev/null 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ] && [[ "$out" != *"$sentinel"* ]] && [[ "$out" == *'connector enabled'* ]]; then pass=$((pass+1))
  else echo "self-test FAIL: the enabled path must exit 0 and never print the key (rc=$rc)" >&2; return 1; fi
  echo "self-test OK ($pass assertions passed)"
}

ENABLE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --self-test) self_test; exit $? ;;
    --enable) ENABLE=1 ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//' | head -30
      exit 0 ;;
    *)
      printf 'FATAL (exit 2): unknown argument: %s\n' "$1" >&2
      exit 2 ;;
  esac
  shift
done

# Disabled path — the DEFAULT. No flag, or no admin key present → clean no-op.
if [ "$ENABLE" -ne 1 ]; then
  printf 'provider connector disabled (no --enable); local extraction is authoritative.\n' >&2
  exit 0
fi
if [ -z "${ANTHROPIC_ADMIN_KEY:-}" ]; then
  printf 'provider connector disabled (no ANTHROPIC_ADMIN_KEY in env); local extraction is authoritative.\n' >&2
  exit 0
fi

# Enabled path — read-only enrichment. The key is used only as a bearer header on a
# read-only GET; it is never printed, written, or committed. This slice (C1) ships
# the connector OFF by default and reserves the `provider` record kind; formalizing
# the live Admin usage/cost GET + response normalization is a plan-gated follow-up
# and intentionally NOT wired to a live endpoint here (no network dependency in the
# data-foundation slice). When implemented it MUST:
#   - issue read-only GETs against the Admin usage/cost endpoints only;
#   - emit one `{"record":"provider", ...}` line per usage/cost window;
#   - never write the store directly (hand records to extract-usage.sh's writer);
#   - never log, echo, or persist ${ANTHROPIC_ADMIN_KEY};
#   - keep --self-test offline: its enabled case runs through a stubbed request, never
#     the live endpoint, and asserts the key is absent from both success and error output.
printf 'provider connector enabled — reserved (record:"provider"); no live endpoint wired in the C1 data-foundation slice.\n' >&2
printf 'Local session extraction remains authoritative; this connector never gates it.\n' >&2
exit 0
