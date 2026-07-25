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
#   bash provider-usage-connector.sh [--enable] [--help]
#
# Exit codes: 0 ok (incl. disabled no-op) · 2 usage error.

set -uo pipefail

ENABLE=0
while [ $# -gt 0 ]; do
  case "$1" in
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
#   - never log, echo, or persist ${ANTHROPIC_ADMIN_KEY}.
printf 'provider connector enabled — reserved (record:"provider"); no live endpoint wired in the C1 data-foundation slice.\n' >&2
printf 'Local session extraction remains authoritative; this connector never gates it.\n' >&2
exit 0
