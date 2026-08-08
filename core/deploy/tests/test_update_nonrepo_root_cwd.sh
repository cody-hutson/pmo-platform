#!/usr/bin/env bash
# test_update_nonrepo_root_cwd.sh — #382 regression: a non-repo-root cwd must not
# cause a partial-update failure in update.sh Phase 5 (or install.sh Phase 2).
#
# Defect (#382): deploy.sh validate_workspace() checks its repo-root markers
# CWD-RELATIVE (deploy.sh:1096-1110 — "Must run from pmo-platform repo root.").
# core/deploy/orchestrate.sh phase_deploy_skills invokes deploy.sh by ABSOLUTE
# path but never sets cwd, so a non-repo-root caller (update.sh Phase 5,
# install.sh Phase 2) inherits the wrong cwd and deploy.sh dies at the guard ->
# partial update + a misleading exit.
#
# Fix (option a, at the orchestrator — NOT deploy.sh): phase_deploy_skills cd's
# (in a subshell) to its BASH_SOURCE-derived repo root before invoking deploy.sh,
# so deploy.sh's cwd-relative guard passes regardless of the caller's cwd.
# deploy.sh's guard and its deliberate cwd-relative source-reading contract are
# UNCHANGED (that is why T2 must still see the guard fire).
#
# Assertions (map to #382 ACs; 4 assertions T1-T4):
#   T1 (AC-1) non-repo-root cwd -> update.sh Phase 5 completes (exit in {0,64})
#             AND no "Must run from pmo-platform repo root" in the log. RED -> GREEN
#   T2 (AC-2) a wrong (marker-less) cwd still trips deploy.sh's guard and dies
#             (the fix does not neuter the safety).                     GREEN -> GREEN
#   T3 (AC-4) repo-root invocation of update.sh remains green (control). GREEN -> GREEN
#   T4        R-8 sandbox safety: the operator's real ~/.claude/skills is
#             byte-identical before/after every invocation.             GREEN
#
# R-8 (HARD sandbox invariant): every install/update invocation is redirected via
# --workspace-root + --config-root into a `mktemp -d` sandbox; the operator's live
# ~/.claude is NEVER written. update.sh bridges --workspace-root to the Phase-5
# deploy root (PMO_PLATFORM_DEPLOY_ROOT, #611 R-A); T2's direct deploy.sh call is
# additionally sandboxed via PMO_PLATFORM_DEPLOY_ROOT belt-and-suspenders (it dies
# at the guard before any deploy regardless). A sorted per-file-hash manifest of
# the real $HOME/.claude/skills is captured BEFORE and AFTER and asserted
# byte-identical (mirrors test_upgrade_config_durability.sh / test_deploy_sandbox.sh).
#
# Platform: Darwin-only (setup-workspace.sh's check_platform hard-fails elsewhere).
# On Linux/WSL this prints SKIP and exits 0 — the cross-OS path is #304's matrix.
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/test_update_nonrepo_root_cwd.sh
#
# Returns non-zero on any failure.

set -uo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'SKIP: test_update_nonrepo_root_cwd.sh — setup-workspace.sh is Darwin-only\n'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
UPDATE="${REPO_ROOT}/update.sh"
DEPLOY="${REPO_ROOT}/core/deploy/deploy.sh"
GUARD_MSG="Must run from pmo-platform repo root"

PASS=0
FAIL=0
SBX=""

cleanup() {
  if [ -n "${SBX}" ] && [ -d "${SBX}" ]; then
    rm -rf "${SBX}"
  fi
}
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"
    [ -n "${detail}" ] && printf '         %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

# Portable per-file hash (macOS `md5 -q`, Linux `md5sum`). Mirrors the model
# tests' hash_file so the safety proof is identical.
hash_file() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$1" 2>/dev/null
  else
    md5sum "$1" 2>/dev/null | awk '{print $1}'
  fi
}

# Manifest of a directory: sorted "relpath  hash" lines. Empty (exit 0) if the
# directory does not exist, so a machine with no live ~/.claude/skills still gets
# a stable before/after comparison.
manifest_dir() {
  local root="$1"
  [ -d "${root}" ] || return 0
  local f
  while IFS= read -r f; do
    printf '%s  %s\n' "${f#"${root}"/}" "$(hash_file "${f}")"
  done < <(find "${root}" -type f 2>/dev/null | LC_ALL=C sort)
}

# --- Preflight ---
if [ ! -f "${SETUP}" ]; then
  printf 'FAIL: setup-workspace.sh not found at %s\n' "${SETUP}"
  exit 1
fi
if [ ! -f "${UPDATE}" ]; then
  printf 'FAIL: update.sh not found at %s\n' "${UPDATE}"
  exit 1
fi
if [ ! -f "${DEPLOY}" ]; then
  printf 'FAIL: deploy.sh not found at %s\n' "${DEPLOY}"
  exit 1
fi

SBX=$(mktemp -d -t nonrepo-root-cwd.XXXXXX)
mkdir -p "${SBX}/config" "${SBX}/ws" "${SBX}/home" "${SBX}/nonrepo" "${SBX}/wrongtree"

# R-8 guard: capture the live-~ skills manifest BEFORE any invocation.
LIVE_SKILLS="${HOME}/.claude/skills"
LIVE_BEFORE=$(manifest_dir "${LIVE_SKILLS}")

# --- Pre-seed operator.toml so setup-workspace.sh prompts skip (identical to
#     test_upgrade_config_durability.sh). ---
cat > "${SBX}/config/operator.toml" <<TOML
[meta]
schema_version = 1
managed_by = "pmo-platform"

[identity]
operator_name = "Test Operator"
operator_email = "test@example.com"
operator_git_email = "test@example.com"
operator_github = "test-handle"
operator_phone = ""
operator_role_title = "Test Role"
operator_organization = "Test Org"

[paths]
claude_workspace_root = "${SBX}/ws"
operator_homedir_path = "${SBX}/home"
cowork_install_path = "/tmp/test-cowork"
pmo_platform_repo_name = "pmo-platform"

[platform]
work_board = "github"
comms_platform = ""
TOML
chmod 600 "${SBX}/config/operator.toml"

# --- Setup: fresh sandbox install so update.sh reaches Phase 5 with real targets ---
printf '\nSetup: fresh sandbox install (setup-workspace.sh, real)\n'
install_log=$("${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/ws" \
  --config-root "${SBX}/config" \
  < <(yes "") 2>&1)
install_exit=$?
if [ "${install_exit}" -ne 0 ]; then
  tail_log=$(printf '%s' "${install_log}" | tail -5 | tr '\n' '|')
  report "setup: fresh sandbox install exits 0" 0 "exit ${install_exit}; ${tail_log}"
  printf '\ntest_update_nonrepo_root_cwd.sh: %d passed, %d failed (bash %s)\n' \
    "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
  exit 1
fi
report "setup: fresh sandbox install exits 0" 1

# --- T1 (AC-1): non-repo-root cwd -> update.sh Phase 5 completes, no guard death ---
# THE #382 regression. Pre-fix: deploy.sh (invoked by phase_deploy_skills with the
# caller's non-repo-root cwd) dies at the guard -> update.sh propagates a non-zero
# exit AND prints the guard message. Post-fix: orchestrate.sh cd's to the repo root
# first -> guard passes -> Phase 5 completes -> EX_OK (0) with --force-regen.
printf '\nT1 (AC-1): update.sh from a NON-repo-root cwd completes Phase 5\n'
t1_out=$( cd "${SBX}/nonrepo" && bash "${UPDATE}" --force-regen \
  --workspace-root "${SBX}/ws" --config-root "${SBX}/config" 2>&1 )
t1_exit=$?
t1_ok=1
t1_detail=""
if [ "${t1_exit}" -ne 0 ] && [ "${t1_exit}" -ne 64 ]; then
  t1_ok=0
  t1_detail="exit ${t1_exit} (expected EX_OK 0 or EX_NOCHANGE 64)"
fi
if grep -qF "${GUARD_MSG}" <<<"${t1_out}"; then
  t1_ok=0
  t1_detail="${t1_detail}; repo-root guard fired -> #382 defect (Phase 5 partial-update failure)"
fi
if [ "${t1_ok}" -eq 1 ]; then
  report "T1 (AC-1): non-repo-root cwd completes Phase 5 (exit 0/64, guard silent)" 1
else
  tail_out=$(printf '%s' "${t1_out}" | tail -4 | tr '\n' '|')
  report "T1 (AC-1): non-repo-root cwd completes Phase 5 (exit 0/64, guard silent)" 0 \
    "${t1_detail}; last: ${tail_out}"
fi

# --- T2 (AC-2): a genuinely wrong (marker-less) cwd still trips deploy.sh's guard ---
# Invoke the REAL deploy.sh (so its BASH_SOURCE-relative libs load) from a
# marker-less directory. The guard is cwd-relative, so it MUST still fire — the
# orchestrator fix only changes the orchestrate.sh -> deploy.sh path, not deploy.sh
# itself. Belt-and-suspenders sandbox: PMO_PLATFORM_DEPLOY_ROOT redirect in case
# the guard were ever to (wrongly) pass -> a deploy lands in the sandbox, never ~.
printf '\nT2 (AC-2): deploy.sh from a marker-less cwd still DIES with the guard\n'
t2_out=$( cd "${SBX}/wrongtree" && PMO_PLATFORM_DEPLOY_ROOT="${SBX}/ws" \
  bash "${DEPLOY}" --deploy 2>&1 )
t2_exit=$?
t2_ok=1
t2_detail=""
if [ "${t2_exit}" -eq 0 ]; then
  t2_ok=0
  t2_detail="deploy.sh exited 0 from a marker-less cwd (guard did NOT fire — safety regressed)"
fi
if ! grep -qF "${GUARD_MSG}" <<<"${t2_out}"; then
  t2_ok=0
  t2_detail="${t2_detail}; '${GUARD_MSG}' not in output"
fi
if [ "${t2_ok}" -eq 1 ]; then
  report "T2 (AC-2): wrong-cwd deploy.sh dies with the repo-root guard (safety intact)" 1
else
  tail_out=$(printf '%s' "${t2_out}" | tail -4 | tr '\n' '|')
  report "T2 (AC-2): wrong-cwd deploy.sh dies with the repo-root guard (safety intact)" 0 \
    "${t2_detail}; last: ${tail_out}"
fi

# --- T3 (AC-4): update.sh from the repo root stays green (control) ---
printf '\nT3 (AC-4): update.sh from the repo root completes Phase 5 (control)\n'
t3_out=$( cd "${REPO_ROOT}" && bash "${UPDATE}" --force-regen \
  --workspace-root "${SBX}/ws" --config-root "${SBX}/config" 2>&1 )
t3_exit=$?
if [ "${t3_exit}" -eq 0 ] || [ "${t3_exit}" -eq 64 ]; then
  report "T3 (AC-4): repo-root update exits EX_OK/EX_NOCHANGE (0/64)" 1
else
  tail_out=$(printf '%s' "${t3_out}" | tail -4 | tr '\n' '|')
  report "T3 (AC-4): repo-root update exits EX_OK/EX_NOCHANGE (0/64)" 0 "exit ${t3_exit}; last: ${tail_out}"
fi

# --- T4: R-8 sandbox safety — live ~/.claude/skills untouched across all invocations ---
printf '\nT4: R-8 safety — live ~/.claude/skills byte-identical before/after\n'
LIVE_AFTER=$(manifest_dir "${LIVE_SKILLS}")
if [ "${LIVE_BEFORE}" = "${LIVE_AFTER}" ]; then
  report "T4: live ~/.claude/skills byte-identical before/after (R-8 proof)" 1
else
  report "T4: live ~/.claude/skills byte-identical before/after (R-8 proof)" 0 \
    "manifest drift detected under ${LIVE_SKILLS}"
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_update_nonrepo_root_cwd.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
