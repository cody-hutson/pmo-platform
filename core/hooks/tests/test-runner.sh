#!/bin/bash
# test-runner.sh — run all *.test.sh files in this directory and aggregate results.
#
# Part of: the bypass-permissions-readiness hardening.
# Used by Engineering during hook changes; also runnable standalone.
#
# Exit code: 0 if all test files pass, 1 if any fail.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$TESTS_DIR"

# #310: this harness exercises the ACTIVE-hook RULE logic. Post-#310 a workflow-class hook is
# inert under the default master-OFF (opt-in), so every subshell test below must run with the
# master-activation switch ON — otherwise the workflow-hook rule assertions would see an inert
# hook and fail. Establish an isolated master-ON config-root and export it so each
# `/bin/bash "$test_file"` subshell inherits it (PMO_PLATFORM_CONFIG_ROOT takes precedence over
# $HOME/.config in core/hooks/lib/master-enable.sh, so this is hermetic regardless of the
# operator's real config). Safe for the WHOLE suite: the security/floor-class hooks behave
# identically ON or OFF (they never inert on master-OFF per D-R9). The master-OFF inert path is
# verified out-of-band (spoke sandbox proof); a dedicated CI master-OFF-inert test can layer on later.
MASTER_CFG_ROOT="$(mktemp -d 2>/dev/null || echo "")"
if [ -n "$MASTER_CFG_ROOT" ]; then
  export PMO_PLATFORM_CONFIG_ROOT="$MASTER_CFG_ROOT"
  printf '[security_hooks]\nmaster_enabled = true\n' > "${MASTER_CFG_ROOT}/platform-config.toml"
  trap '[ -n "${MASTER_CFG_ROOT:-}" ] && /bin/rm -rf "$MASTER_CFG_ROOT"' EXIT
fi

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_FILES=()

echo "========================================"
echo "hook test harness"
echo "========================================"

for test_file in *.test.sh; do
  [ -f "$test_file" ] || continue

  echo ""
  echo "----- running: $test_file -----"
  output="$(/bin/bash "$test_file" 2>&1)"
  rc=$?

  # Parse the summary line
  summary="$(/usr/bin/printf '%s\n' "$output" | /usr/bin/grep -E '^Total: [0-9]+  PASS: [0-9]+  FAIL: [0-9]+' | /usr/bin/tail -1)"
  if [ -z "$summary" ]; then
    echo "ERROR: $test_file produced no summary line"
    echo "$output"
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_FILES+=("$test_file (no summary)")
    continue
  fi

  pass="$(/usr/bin/printf '%s' "$summary" | /usr/bin/grep -oE 'PASS: [0-9]+' | /usr/bin/grep -oE '[0-9]+')"
  fail="$(/usr/bin/printf '%s' "$summary" | /usr/bin/grep -oE 'FAIL: [0-9]+' | /usr/bin/grep -oE '[0-9]+')"

  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))

  /usr/bin/printf '%s — %s\n' "$test_file" "$summary"

  if [ "$rc" -ne 0 ] || [ "$fail" -gt 0 ]; then
    FAILED_FILES+=("$test_file")
  fi
done

echo ""
echo "========================================"
/usr/bin/printf 'AGGREGATE: PASS=%d  FAIL=%d\n' "$TOTAL_PASS" "$TOTAL_FAIL"
if [ "${#FAILED_FILES[@]}" -gt 0 ]; then
  echo "Failed files:"
  for f in "${FAILED_FILES[@]}"; do
    echo "  - $f"
  done
fi
echo "========================================"

if [ "$TOTAL_FAIL" -gt 0 ] || [ "${#FAILED_FILES[@]}" -gt 0 ]; then
  exit 1
fi
exit 0
