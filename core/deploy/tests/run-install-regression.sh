#!/usr/bin/env bash
# run-install-regression.sh — the STANDING install/onboarding/update regression suite.
#
# This is the named, standing regression entrypoint for the install/onboarding/
# update family (#706, epic #325 ticket C8). It is what turns the latent
# core/deploy/tests/ + core/hooks/tests/ corpus into a *named regression suite*
# with a single aggregating verdict, rather than N loose acceptance scripts.
#
# WHAT IT RUNS
#   1. REGRESSION_MEMBERS — the install/onboarding/update deploy-test subset
#      (the single source of truth for membership; see "Extending" below). Each
#      member is a standalone core/deploy/tests/*.sh / *.py that prints
#      "<name>: N passed, M failed" (optionally ", K skipped") and exits
#      non-zero on any FAIL.
#   2. The HOOK-TEST FLOOR (#319) — every core/hooks/tests/*.test.sh hook suite.
#      These are NOT directly runnable as `bash *.test.sh`: the hooks
#      resolve their allowlist + .mode from a DEPLOYED layout, so the floor runs
#      via the two-step contract setup-ci-layout.sh (materialize) → test-runner.sh
#      (aggregate), materializing into a fresh per-run sandbox this runner passes
#      explicitly (the helper's default is the checkout root, the agent-facing
#      site). Included per the v1.12 Collective-Review scope-lock: the hook
#      tests are part of this suite's regression floor.
#
# VERDICT (deterministic, ALL-MUST-PASS — no pass-rate threshold; this family is
# deterministic, so any single failure is a real break, not judge non-determinism):
#   Prints exactly one machine-greppable line:
#     INSTALL-REGRESSION: <P> passed, <F> failed — VERDICT <PASS|FAIL> [env: <E>; skipped: <S>]
#   and exits 1 if ANY member (or the hook floor) fails, 0 otherwise. The
#   bracketed stamp never changes the verdict. <E> names the environment:
#   home-account (HOME is the account's home in the user database), home-override
#   (a caller redirected HOME), or home-unresolved (the user database could not be
#   read) — so two runs of one tree can be told apart. <S> sums the arms members
#   report as SKIP: arms that produced no evidence, which the PASS does not cover.
#   When the caller set PMO_REGRESSION_LIVE_HOME to anything but the account
#   home, a second bracket follows, [r8: caller]: the members' live-install
#   proofs then watched the caller's subject, not the live install.
#
# SANDBOX (R-8, HARD): each member redirects every install/update/deploy
# invocation into a `mktemp -d` sandbox by passing redirected roots
# (--workspace-root, --config-root; update.sh derives PMO_PLATFORM_DEPLOY_ROOT
# from the former). That is the PREVENTIVE half, and it is a member-authoring
# contract, not an interlock. The DETECTIVE half is a member's own before/after
# manifest of the live install's .claude/skills. This runner exports
# PMO_REGRESSION_LIVE_HOME — the account home, unless the caller already set it.
# A member that pins its proof to that subject (test_upgrade_config_durability.sh's
# R-8) keeps asserting under a caller-applied HOME override; a member whose proof
# still derives its subject from $HOME compares an empty subject with itself
# under such an override. This runner stays ONE self-contained file (it sources
# nothing): the CI precision probe copies it alone into a stripped tree.
#
# test-run EVENT EMISSION (composition with #430): after the verdict, the runner
# makes a BEST-EFFORT emission of one `test-run` pipeline event (suite-pass /
# suite-fail) via release/tools/append-pipeline-event.sh, per the runtime-suite
# selection map. It is a SUBPROCESS invocation (not a `source`), guarded on the
# tool being resolvable, and its failure NEVER changes the suite verdict — so:
#   (a) core/ carries no hard runtime dependency on release/ (the core-boundary
#       invariant holds; a `bash <path>` call is not a code-import), and
#   (b) the CI job-exit remains the authoritative gate (the event is audit
#       enrichment, not the gate), per the Stage 5 D-430Seam fallback.
#   Suppress emission with PMO_REGRESSION_EMIT=0 (e.g. hermetic CI without an
#   operator-instance event log).
#
# ── Extending ──────────────────────────────────────────────────────────────
#   To add a test to the STANDING install/onboarding/update regression set, add
#   its core/deploy/tests/ filename to the REGRESSION_MEMBERS array below — that
#   array is the single source of truth for membership, so the suite cannot
#   silently drop a test. Hook-floor membership is the whole core/hooks/tests/
#   set via the runner contract (no per-file enumeration here, by design — the
#   hook runner discovers its own *.test.sh files).
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/run-install-regression.sh
#
# Platform: Darwin-only members self-SKIP on Linux/WSL (they exit 0 with a SKIP
# line), so the runner is safe to invoke on any platform; the hook floor uses
# macOS/BSD assumptions consistent with the hook layer.
#
# Returns non-zero if any member or the hook floor fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
HOOK_TESTS_DIR="${REPO_ROOT}/core/hooks/tests"
APPEND_EVENT="${REPO_ROOT}/release/tools/append-pipeline-event.sh"

# ── Environment + live-install subject (verdict honesty) ──
# The account home is read from the user database, never from $HOME: a caller may
# have redirected HOME, and the verdict-line stamp exists to say whether they did.
# A missing interpreter or database entry degrades to home-unresolved. The
# durability member resolves the account home with this same expression, and its
# R-8r arm asserts the two stay identical.
ACCOUNT_HOME=$(python3 -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)' 2>/dev/null || true)
_acct_phys=""
_home_phys=""
if [ -n "${ACCOUNT_HOME}" ]; then
  _acct_phys=$(cd "${ACCOUNT_HOME}" 2>/dev/null && pwd -P)
fi
if [ -n "${HOME:-}" ]; then
  _home_phys=$(cd "${HOME}" 2>/dev/null && pwd -P)
fi
if [ -z "${_acct_phys}" ]; then
  ENV_TOKEN="home-unresolved"
elif [ "${_acct_phys}" = "${_home_phys}" ]; then
  ENV_TOKEN="home-account"
else
  ENV_TOKEN="home-override"
fi
# Members pin their R-8 live-install proof to this subject. A caller-set value
# wins, so a verifier can point the proof at a fixture home, and the stamp then
# says so: a fixture proof must never read like a live one.
R8_STAMP=""
if [ -n "${PMO_REGRESSION_LIVE_HOME:-}" ]; then
  _live_phys=$(cd "${PMO_REGRESSION_LIVE_HOME}" 2>/dev/null && pwd -P)
  if [ -z "${_acct_phys}" ] || [ "${_live_phys}" != "${_acct_phys}" ]; then
    R8_STAMP=" [r8: caller]"
  fi
elif [ -n "${_acct_phys}" ]; then
  export PMO_REGRESSION_LIVE_HOME="${ACCOUNT_HOME}"
fi

# ── REGRESSION_MEMBERS — single source of truth for the deploy-test subset ──
# The install/onboarding/update family. Mirrors the HARNESS_LIST / *_SKILLS
# array-as-single-source convention. Add a member here to enroll it.
REGRESSION_MEMBERS=(
  "test_sandbox_roots.sh"                  # --dry-run plumbing: CLI/env-var root precedence
  "test_install_end_to_end.sh"             # full real install + dry-run update no-op
  "test_deploy_sandbox.sh"                 # PMO_PLATFORM_DEPLOY_ROOT sandbox-safety proof
  "test_upgrade_config_durability.sh"      # NON-dry-run real-content-delta upgrade durability (#706)
  "test_install_exit_propagation.sh"       # install.sh propagates setup-workspace.sh exit codes
  "test_detect_install_path_spaces.sh"     # cowork_install_path with internal spaces resolves
  "test_lib_composition.sh"                # bash-3.2 array-scope contract + manifest count
  "test_update_nonrepo_root_cwd.sh"        # #382 non-repo-root cwd -> Phase 5 completes; guard intact
  "test_ps1_dryrun_contract.sh"            # #303 Windows install/update -DryRun proxy contract + gate relaxation
  "test_qa_module.py"                      # QA-as-code registry: import smoke + finding->check 1:1 coverage
  "test_doctor.sh"                         # #302 doctor.sh: two-layer install self-diagnosis + read-only + fault-injection
  "test_refresh_surfaces.sh"               # update.sh --surfaces-only targeted composition-surface refresh + leakage backstop
  "test_validate_install.sh"               # validate-install.sh A9 platform-roster predicate + anti-vacuity control
  "test_deploy_detection_honesty.sh"       # --deploy selects against ground truth, not the tag-diff proxy; residual drift exits non-zero
  "test_lib_instance_path.sh"              # lib-instance-path.sh resolver contract — the install/update/setup scripts source it; previously enrolled nowhere
)

SUITE_PASS=0
SUITE_FAIL=0
SUITE_SKIP=0
FAILED_MEMBERS=()

printf '======================================================================\n'
printf 'INSTALL/ONBOARDING/UPDATE REGRESSION SUITE (standing; #706 / epic #325 C8)\n'
printf '======================================================================\n'

# Parse a member's "N passed, M failed" summary line into the aggregate.
# Members print "<name>: N passed, M failed"; we sum N and M and also honor the
# member's exit code (a member that crashed before printing a summary is a FAIL).
run_member() {
  local member="$1"
  local path="${SCRIPT_DIR}/${member}"
  printf '\n----- member: %s -----\n' "${member}"
  if [ ! -f "${path}" ]; then
    printf '  ERROR: member not found: %s\n' "${path}"
    SUITE_FAIL=$((SUITE_FAIL + 1))
    FAILED_MEMBERS+=("${member} (missing)")
    return
  fi

  local out rc
  # .py members run as standalone self-reporting scripts (python3 <path>), NOT via
  # pytest: this bash suite (and the CI runner) may not have pytest installed, and
  # the member contract above is "prints N passed, M failed; exits non-zero on FAIL".
  case "${member}" in
    *.py)  out="$(python3 "${path}" 2>&1)"; rc=$? ;;
    *)     out="$(bash "${path}" 2>&1)"; rc=$? ;;
  esac
  printf '%s\n' "${out}"

  # A self-SKIP member (Darwin-only test on Linux) prints "SKIP:" and exits 0 —
  # count it as a non-failing pass-through (0 assertions), never a FAIL.
  if grep -q '^SKIP:' <<<"${out}"; then
    printf '  (skipped on this platform — counted as pass-through)\n'
    return
  fi

  # Pull the member's own "N passed, M failed" tallies when present (for the
  # aggregate count); the gate decision is driven by the exit code regardless.
  local p f s
  p="$(printf '%s\n' "${out}" | grep -oE '[0-9]+ passed' | tail -1 | grep -oE '[0-9]+')"
  f="$(printf '%s\n' "${out}" | grep -oE '[0-9]+ failed' | tail -1 | grep -oE '[0-9]+')"
  # Arms a member reports as SKIP produced no evidence; surface them on the stamp.
  s="$(printf '%s\n' "${out}" | grep -oE '[0-9]+ skipped' | tail -1 | grep -oE '[0-9]+')"
  [ -n "${p}" ] && SUITE_PASS=$((SUITE_PASS + p))
  [ -n "${f}" ] && SUITE_FAIL=$((SUITE_FAIL + f))
  [ -n "${s}" ] && SUITE_SKIP=$((SUITE_SKIP + s))

  if [ "${rc}" -ne 0 ]; then
    # Exit non-zero but no parsed failures (e.g. crash before summary) → record 1.
    if [ -z "${f}" ] || [ "${f}" = "0" ]; then
      SUITE_FAIL=$((SUITE_FAIL + 1))
    fi
    FAILED_MEMBERS+=("${member}")
  fi
}

for member in "${REGRESSION_MEMBERS[@]}"; do
  run_member "${member}"
done

# ── Hook-test floor (#319) — materialize the deployed layout, then run ──
printf '\n----- member: hook-test floor (core/hooks/tests via setup-ci-layout.sh) -----\n'
if [ -f "${HOOK_TESTS_DIR}/setup-ci-layout.sh" ] && [ -f "${HOOK_TESTS_DIR}/test-runner.sh" ]; then
  # A fresh sandbox of this run's own, passed explicitly and never empty: the
  # helper's default is the checkout root (the agent-facing site), which a
  # programmatic run must not reuse. The helper's stdout stays the contract.
  hook_sandbox="$(mktemp -d -t hook-ci-layout.XXXXXX 2>/dev/null)" || hook_sandbox=""
  hook_layout=""
  if [ -n "${hook_sandbox}" ]; then
    hook_layout="$(bash "${HOOK_TESTS_DIR}/setup-ci-layout.sh" --sandbox "${hook_sandbox}" 2>/dev/null)"
  fi
  if [ -n "${hook_layout}" ] && [ -d "${hook_layout}" ]; then
    hook_out="$(bash "${hook_layout}/test-runner.sh" 2>&1)"
    hook_rc=$?
    printf '%s\n' "${hook_out}"
    # The hook runner prints "AGGREGATE: PASS=<P>  FAIL=<F>".
    hp="$(printf '%s\n' "${hook_out}" | grep -oE 'PASS=[0-9]+' | tail -1 | grep -oE '[0-9]+')"
    hf="$(printf '%s\n' "${hook_out}" | grep -oE 'FAIL=[0-9]+' | tail -1 | grep -oE '[0-9]+')"
    [ -n "${hp}" ] && SUITE_PASS=$((SUITE_PASS + hp))
    [ -n "${hf}" ] && SUITE_FAIL=$((SUITE_FAIL + hf))
    if [ "${hook_rc}" -ne 0 ]; then
      if [ -z "${hf}" ] || [ "${hf}" = "0" ]; then SUITE_FAIL=$((SUITE_FAIL + 1)); fi
      FAILED_MEMBERS+=("hook-test floor")
    fi
  else
    printf '  ERROR: setup-ci-layout.sh produced no usable layout dir\n'
    SUITE_FAIL=$((SUITE_FAIL + 1))
    FAILED_MEMBERS+=("hook-test floor (no layout)")
  fi
else
  printf '  ERROR: hook-test floor harness missing under %s\n' "${HOOK_TESTS_DIR}"
  SUITE_FAIL=$((SUITE_FAIL + 1))
  FAILED_MEMBERS+=("hook-test floor (missing)")
fi

# ── Aggregate verdict ──
if [ "${SUITE_FAIL}" -eq 0 ]; then
  VERDICT="PASS"
else
  VERDICT="FAIL"
fi

printf '\n======================================================================\n'
printf 'INSTALL-REGRESSION: %d passed, %d failed — VERDICT %s [env: %s; skipped: %d]%s\n' \
  "${SUITE_PASS}" "${SUITE_FAIL}" "${VERDICT}" "${ENV_TOKEN}" "${SUITE_SKIP}" "${R8_STAMP}"
if [ "${#FAILED_MEMBERS[@]}" -gt 0 ]; then
  printf 'Failed members:\n'
  for m in "${FAILED_MEMBERS[@]}"; do printf '  - %s\n' "${m}"; done
fi
printf '======================================================================\n'

# ── test-run event emission (best-effort; composition with #430) ──
# Subprocess call (not a `source`) → no core→release code-import dependency.
# Guarded on the tool being resolvable; failure NEVER changes the verdict.
if [ "${PMO_REGRESSION_EMIT:-1}" != "0" ] && [ -f "${APPEND_EVENT}" ]; then
  if [ "${VERDICT}" = "PASS" ]; then
    _subtype="suite-pass"; _outcome="resolved"
  else
    _subtype="suite-fail"; _outcome="escalated"
  fi
  # The release JOIN KEY is the milestone slug, not a version
  # (pipeline-event-log-schema.md § 2a), and the writer REJECTS a version-shaped
  # value. This previously emitted the contents of .version — the repo's shipped
  # version — with a `v0.0` fallback; both are version-shaped, so both would now
  # be rejected, and because this emission is best-effort the rejection would be
  # swallowed into "emission skipped" and the suite would silently stop emitting
  # forever. This is a regression suite with no release context of its own, which
  # is exactly what the reserved `(none)` sentinel is for.
  _version="(none)"
  # Payload kept < 300 chars and pipe-free (the writer rejects '|').
  _payload="suite:install-onboarding-update; passed:${SUITE_PASS}; failed:${SUITE_FAIL}; skipped:${SUITE_SKIP}; env:${ENV_TOKEN}; runner:run-install-regression.sh"
  [ -n "${R8_STAMP}" ] && _payload="${_payload}; r8:caller"
  bash "${APPEND_EVENT}" \
    --version "${_version}" \
    --stage 6 \
    --event-type test-run \
    --event-subtype "${_subtype}" \
    --actor "spoke:#706" \
    --subject "suite:install-onboarding-update" \
    --reversibility CHEAP \
    --outcome "${_outcome}" \
    --payload "${_payload}" >/dev/null 2>&1 \
    && printf 'test-run event emitted (%s).\n' "${_subtype}" \
    || printf 'test-run event emission skipped (writer unavailable or no operator-instance log) — CI job-exit is the gate.\n'
fi

if [ "${SUITE_FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
