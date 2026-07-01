#!/bin/bash
# skill-compliance-auditor — Measure-mode harness support.
#
# Implements the DETERMINISTIC, script-able parts of the four-stage compliance
# pipeline: the cost-governor scenario planner (--dry-run) and the deterministic-
# first structural trace classifier. Stage 2 (agent execution) is driven by the
# measurement harness at runtime — a shell script cannot invoke the agent
# runtime, so this script owns the parts that CAN be deterministic:
#
#   1. --dry-run <target...> : the COST GOVERNOR. Prints the scenario plan
#      (target skills × the 3 strictness slots) and the estimated call count
#      (generation + agent-execution + bounded competing-scenario judge calls)
#      BEFORE any API spend. Honors the per-run scenario-count cap. This is the
#      mechanism that makes the cost governor concrete: no bare --run, and any
#      invocation without --run defaults here.
#
#   2. --classify <skill> <trace-file> : the DETERMINISTIC-FIRST classifier.
#      Structurally greps a captured tool-call trace for the target skill's
#      Skill-tool invocation and emits one of: fired · not-fired ·
#      sibling-captured. NO LLM judge — that grep answers explicit/neutral
#      scenarios for free; the LLM judge is reserved (by the skill, not this
#      script) only for "was firing appropriate?" on competing scenarios.
#
# Read-only: measures firing behavior, mutates no skill. The one durable write
# (appending a trigger-rate row to the calibration surface) is done by the skill
# against <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md, not here.
#
# Strictness levels (the diagnostic ladder):
#   explicit  — prompt names the skill's trigger phrases verbatim (baseline firing)
#   neutral   — prompt describes the domain task with NO trigger phrase (description: health)
#   competing — prompt where target + >=1 sibling both plausibly apply (trigger collision)
#
# Cost governor:
#   • per-run scenario-count cap, documented default = 30 (--max-scenarios N to override).
#   • --dry-run prints plan + estimated call count before spend; bare call => --dry-run.
#
# Usage:
#   bash .../measure-skill-compliance.sh --dry-run <skill> [<skill>...] [--max-scenarios N]
#   bash .../measure-skill-compliance.sh --classify <skill> <trace-file>
#   bash .../measure-skill-compliance.sh --self-test
#
# Exit codes: 0 ok · 2 usage error · 3 input error (unreadable trace/roster).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# The three strictness slots per target skill — fixed structure (template-first),
# so a scenario-count delta between runs is interpretable as skill-drift.
readonly STRICTNESS_LEVELS="explicit neutral competing"
readonly STRICTNESS_COUNT=3

# Cost governor: documented default per-run scenario-count cap.
readonly DEFAULT_MAX_SCENARIOS=30

# ---------------------------------------------------------------------------
# Cost governor — scenario planner + call-count estimator.
# ---------------------------------------------------------------------------

# plan_scenarios <max> <skill...> : print the scenario plan and the estimated
# call count, honoring the cap. One agent-execution call per scenario; one
# generation call per scenario slot; one judge call per COMPETING scenario only.
plan_scenarios() {
  local max="$1"; shift
  local targets=("$@")
  local n_targets=${#targets[@]}

  local requested=$(( n_targets * STRICTNESS_COUNT ))
  local capped=$requested
  local capped_flag="no"
  if [[ $requested -gt $max ]]; then
    capped=$max
    capped_flag="yes"
  fi

  # Call-count estimate over the CAPPED scenario set:
  #   generation calls   = 1 per scenario (template-seeded slot fill)
  #   execution calls    = 1 per scenario (the primary cost — one agent run each)
  #   judge calls        = 1 per competing scenario (bounded; deterministic grep
  #                        handles explicit/neutral for free). Competing = 1/3 of
  #                        the strictness slots, so ~ capped/3 judge calls.
  local gen_calls=$capped
  local exec_calls=$capped
  local judge_calls=$(( capped / STRICTNESS_COUNT ))
  local total_calls=$(( gen_calls + exec_calls + judge_calls ))

  echo "## Scenario plan (DRY-RUN — no API spend)"
  echo ""
  echo "Target skills (${n_targets}): ${targets[*]}"
  echo "Strictness slots per skill: ${STRICTNESS_LEVELS} (${STRICTNESS_COUNT})"
  echo "Per-run scenario cap: ${max} (default ${DEFAULT_MAX_SCENARIOS})"
  echo "Scenarios requested: ${requested}"
  if [[ "$capped_flag" == "yes" ]]; then
    echo "Scenarios AFTER cap: ${capped}  [CAP APPLIED — override with --max-scenarios]"
  else
    echo "Scenarios after cap: ${capped}  [within cap]"
  fi
  echo ""
  echo "Estimated call count (before any spend):"
  echo "  generation calls (1/scenario):          ${gen_calls}"
  echo "  agent-execution calls (1/scenario):     ${exec_calls}   <- primary cost"
  echo "  competing-scenario judge calls (~1/3):  ${judge_calls}"
  echo "  ------------------------------------------------"
  echo "  ESTIMATED TOTAL API CALLS:              ${total_calls}"
  echo ""
  echo "Authorize the spend by re-invoking with --run (the skill drives Stage 2)."
  # Emit a machine-parseable summary line for the skill to consume.
  echo "PLAN scenarios=${capped} total_calls=${total_calls} capped=${capped_flag}"
  return 0
}

# ---------------------------------------------------------------------------
# Deterministic-first structural trace classifier.
# ---------------------------------------------------------------------------

# A captured trace is a tool-call log; a Skill-tool invocation of skill X appears
# as a line naming the Skill tool with skill "X" (harness-emitted). We match the
# skill name as a Skill-tool argument, tolerant of quoting.

# skill_fired_in_trace <skill> <trace-file> : 0 if the target skill's Skill-tool
# call appears; 1 otherwise.
skill_fired_in_trace() {
  local skill="$1" trace="$2"
  # Match a Skill-tool invocation naming this skill: a line mentioning "Skill"
  # (the tool) AND the skill token as a value. Anchored to the skill token to
  # avoid a substring false-hit on a longer skill name.
  grep -Eiq "Skill[^A-Za-z0-9_-]+.*(^|[^A-Za-z0-9_-])${skill}([^A-Za-z0-9_-]|\$)" "$trace"
}

# any_sibling_fired <skill> <trace-file> : 0 if SOME Skill-tool call appears that
# is NOT the target skill (a sibling captured the request); 1 otherwise.
any_sibling_fired() {
  local skill="$1" trace="$2"
  # Any Skill-tool invocation line, minus lines naming the target skill.
  grep -Ei "Skill[^A-Za-z0-9_-]" "$trace" 2>/dev/null \
    | grep -Eiv "(^|[^A-Za-z0-9_-])${skill}([^A-Za-z0-9_-]|\$)" \
    | grep -Eq "Skill"
}

# classify_trace <skill> <trace-file> : emit fired | sibling-captured | not-fired.
classify_trace() {
  local skill="$1" trace="$2"
  if [[ ! -r "$trace" ]]; then
    echo "capture-failed"
    return 3
  fi
  if skill_fired_in_trace "$skill" "$trace"; then
    echo "fired"
    return 0
  fi
  if any_sibling_fired "$skill" "$trace"; then
    echo "sibling-captured"
    return 0
  fi
  echo "not-fired"
  return 0
}

# ---------------------------------------------------------------------------
# Self-test.
# ---------------------------------------------------------------------------

self_test() {
  local pass=0
  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN

  # --- classifier: fired (target Skill-tool call present) ---
  cat > "$tmp/t_fired.log" <<'TRACE'
[tool] Read core/skills/comms-writer/SKILL.md
[tool] Skill skill="comms-writer" args="draft update"
[assistant] drafted
TRACE
  [[ "$(classify_trace comms-writer "$tmp/t_fired.log")" == "fired" ]] \
    && pass=$((pass+1)) || { echo "self-test FAIL: expected fired" >&2; return 1; }

  # --- classifier: sibling-captured (a DIFFERENT skill fired) ---
  cat > "$tmp/t_sibling.log" <<'TRACE'
[tool] Skill skill="daily-status" args="am update"
[assistant] posted
TRACE
  [[ "$(classify_trace comms-writer "$tmp/t_sibling.log")" == "sibling-captured" ]] \
    && pass=$((pass+1)) || { echo "self-test FAIL: expected sibling-captured" >&2; return 1; }

  # --- classifier: not-fired (no Skill-tool call at all) ---
  cat > "$tmp/t_none.log" <<'TRACE'
[tool] Read some/file.md
[assistant] answered directly, no skill invoked
TRACE
  [[ "$(classify_trace comms-writer "$tmp/t_none.log")" == "not-fired" ]] \
    && pass=$((pass+1)) || { echo "self-test FAIL: expected not-fired" >&2; return 1; }

  # --- classifier: capture-failed (unreadable trace) ---
  [[ "$(classify_trace comms-writer "$tmp/does-not-exist.log")" == "capture-failed" ]] \
    && pass=$((pass+1)) || { echo "self-test FAIL: expected capture-failed" >&2; return 1; }

  # --- classifier: no substring false-hit (comms-writer must NOT match comms-writer-extended) ---
  cat > "$tmp/t_substr.log" <<'TRACE'
[tool] Skill skill="comms-writer-extended" args="x"
TRACE
  [[ "$(classify_trace comms-writer "$tmp/t_substr.log")" == "sibling-captured" ]] \
    && pass=$((pass+1)) || { echo "self-test FAIL: substring boundary — expected sibling-captured, not fired" >&2; return 1; }

  # --- cost governor: cap applied when requested > cap ---
  # 20 targets * 3 = 60 requested; cap 30 -> capped=30, total = 30+30+10 = 70.
  local plan; plan="$(plan_scenarios 30 $(seq -f 's%g' 1 20) | grep '^PLAN ')"
  echo "$plan" | grep -q "scenarios=30" \
    && pass=$((pass+1)) || { echo "self-test FAIL: cap not applied (got: $plan)" >&2; return 1; }
  echo "$plan" | grep -q "capped=yes" \
    && pass=$((pass+1)) || { echo "self-test FAIL: capped flag not set (got: $plan)" >&2; return 1; }
  echo "$plan" | grep -q "total_calls=70" \
    && pass=$((pass+1)) || { echo "self-test FAIL: call estimate wrong (got: $plan)" >&2; return 1; }

  # --- cost governor: within cap (1 target * 3 = 3; total = 3+3+1 = 7) ---
  local plan2; plan2="$(plan_scenarios 30 comms-writer | grep '^PLAN ')"
  echo "$plan2" | grep -q "scenarios=3" \
    && pass=$((pass+1)) || { echo "self-test FAIL: within-cap scenario count wrong (got: $plan2)" >&2; return 1; }
  echo "$plan2" | grep -q "capped=no" \
    && pass=$((pass+1)) || { echo "self-test FAIL: within-cap flag wrong (got: $plan2)" >&2; return 1; }
  echo "$plan2" | grep -q "total_calls=7" \
    && pass=$((pass+1)) || { echo "self-test FAIL: within-cap call estimate wrong (got: $plan2)" >&2; return 1; }

  echo "self-test OK ($pass assertions passed)"
  return 0
}

# ---------------------------------------------------------------------------
# Entry.
# ---------------------------------------------------------------------------

usage() {
  echo "Usage:" >&2
  echo "  bash measure-skill-compliance.sh --dry-run <skill> [<skill>...] [--max-scenarios N]" >&2
  echo "  bash measure-skill-compliance.sh --classify <skill> <trace-file>" >&2
  echo "  bash measure-skill-compliance.sh --self-test" >&2
  exit 2
}

main() {
  local mode="${1:-}"
  case "$mode" in
    --self-test)
      self_test; exit $?
      ;;
    --classify)
      shift
      [[ $# -eq 2 ]] || usage
      classify_trace "$1" "$2"; exit $?
      ;;
    --dry-run|"")
      # Bare invocation defaults to --dry-run (cost-safety default).
      [[ "$mode" == "--dry-run" ]] && shift
      local max=$DEFAULT_MAX_SCENARIOS
      local targets=()
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --max-scenarios) shift; max="${1:-$DEFAULT_MAX_SCENARIOS}"; shift ;;
          *) targets+=("$1"); shift ;;
        esac
      done
      [[ ${#targets[@]} -ge 1 ]] || { echo "error: --dry-run needs >=1 target skill" >&2; usage; }
      plan_scenarios "$max" "${targets[@]}"; exit $?
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
