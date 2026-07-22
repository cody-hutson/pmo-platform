#!/usr/bin/env bash
# test-status-label-invariant.sh — seed-fixture efficacy test for deploy.sh Check 16
# under the #2682 widened scope.
#
# WHY THIS FIXTURE IS MANDATORY (not optional)
# --------------------------------------------
# The live orphaned-bundle population (status: bundled + no milestone) is 0 as of
# 2026-07-19, so Check 16's I4 invariant cannot demonstrate efficacy against live
# state — a green run proves nothing. Per audit-baseline discipline, the widened
# check must be shown to FIRE against a seeded population. This test seeds exactly
# the states #2682 targets and asserts each invariant's verdict.
#
# FIDELITY NOTE
# -------------
# Check 16's four invariants are inline jq filters inside deploy.sh (not a separately
# invokable primitive). This test embeds the SAME four filters, including the #2682
# I2 type-exemption (type:epic + sub-task), and asserts them against the seed. The
# filters here MUST mirror deploy.sh Check 16 (core/deploy/deploy.sh, "I1 — mutex" …
# "I4 — contradiction-B"). If Check 16's filters change, update this test in lockstep.
#
# Runnable standalone: `bash core/deploy/tools/tests/test-status-label-invariant.sh`
# Exit 0 = all assertions pass; exit 1 = a mismatch (the check would mis-fire).

set -u
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq unavailable"; exit 0; }

# ── Seed fixture — one issue per state the widened Check 16 must classify ──────
read -r -d '' FIXTURE <<'JSON'
[
  { "number": 9001, "labels": [{"name":"improvement"},{"name":"status: bundled"}], "milestone": null },
  { "number": 9002, "labels": [{"name":"bug"}], "milestone": null },
  { "number": 9003, "labels": [{"name":"type:epic"}], "milestone": null },
  { "number": 9004, "labels": [{"name":"sub-task"}], "milestone": null },
  { "number": 9005, "labels": [{"name":"improvement"},{"name":"status: proposed"},{"name":"status: bundled"}], "milestone": null },
  { "number": 9006, "labels": [{"name":"improvement"},{"name":"status: proposed"}], "milestone": {"number": 42} },
  { "number": 9007, "labels": [{"name":"improvement"},{"name":"status: approved"}], "milestone": {"number": 42} }
]
JSON

pass=0; fail=0
assert_set() {
  # assert_set <label> <actual-newline-list> <expected-space-list>
  local label="$1" actual expected
  actual=$(printf '%s' "$2" | grep -v '^$' | sort | paste -sd, -)
  expected=$(printf '%s' "$3" | tr ' ' '\n' | grep -v '^$' | sort | paste -sd, -)
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $label → [{$actual}]"
    pass=$((pass+1))
  else
    echo "  FAIL  $label → got [{$actual}] want [{$expected}]"
    fail=$((fail+1))
  fi
}

# ── I1 — mutex: >1 status:* label (all types) ─────────────────────────────────
i1=$(printf '%s' "$FIXTURE" | jq -r '
  .[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) > 1) | .number')
assert_set "I1 mutex (>1 status)" "$i1" "9005"

# ── I2 — presence: 0 status:* labels, EXEMPT type:epic + sub-task ─────────────
i2=$(printf '%s' "$FIXTURE" | jq -r '
  .[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) == 0)
  | select((.labels | map(.name) | index("type:epic")) | not)
  | select((.labels | map(.name) | index("sub-task")) | not)
  | .number')
# 9002 (bug, 0 status) fires; 9003 (epic) + 9004 (sub-task) EXEMPT — the load-bearing case.
assert_set "I2 presence (0 status; epic+sub-task exempt)" "$i2" "9002"

# ── I3 — contradiction-A: status: proposed + milestone set (all types) ────────
i3=$(printf '%s' "$FIXTURE" | jq -r '
  .[] | select(.milestone != null)
  | select((.labels | map(.name) | map(select(. == "status: proposed"))) | length > 0) | .number')
assert_set "I3 proposed+milestone" "$i3" "9006"

# ── I4 — contradiction-B: status: bundled + no milestone (all types) ──────────
# The MANDATORY seed: live population is 0, so this is the only proof the detector fires.
i4=$(printf '%s' "$FIXTURE" | jq -r '
  .[] | select(.milestone == null)
  | select((.labels | map(.name) | map(select(. == "status: bundled"))) | length > 0) | .number')
# 9001 (bundled+null milestone) AND 9005 (also bundled+null) both fire.
assert_set "I4 bundled+no-milestone (orphaned bundle)" "$i4" "9001 9005"

echo "status-label-invariant fixture: $pass passed, $fail failed"
[[ $fail -eq 0 ]] || exit 1
