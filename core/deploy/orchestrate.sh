#!/usr/bin/env bash
# orchestrate.sh — install / update phase orchestration
#
# Provides phase functions shared between the install.sh and update.sh
# entry scripts. The intent of this file is to be the single home for
# multi-phase workflow logic; today it owns the skill-deployment phase
# (called at the end of both install and update), with additional phases
# expected to migrate here from docs/scripts/setup-workspace.sh and
# update.sh over subsequent releases.
#
# Sourced by:
#   - install.sh   (calls phase_deploy_skills after workspace bootstrap)
#   - update.sh    (calls phase_deploy_skills after composition-surface regen)
#
# Spec:
#   - Composition-surface contract: core/standards/composition-surface-spec.md
#
# Bash version: 3.2.57-safe.

# Resolve the directory this file lives in so callers can rely on it locating
# sibling helpers under core/deploy/ without re-resolving paths.
ORCHESTRATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ORCHESTRATE_DIR
readonly ORCHESTRATE_DEPLOY_SCRIPT="${ORCHESTRATE_DIR}/deploy.sh"

# --- Shared logging ---
orchestrate_log_info() { printf 'INFO: %s\n' "$*" >&2; }
orchestrate_log_warn() { printf 'WARN: %s\n' "$*" >&2; }
orchestrate_log_err()  { printf 'ERROR: %s\n' "$*" >&2; }

# --- Phase: deploy skills ---
# Invokes core/deploy/deploy.sh --deploy to install / refresh all skills under
# ~/.claude/skills/. Called at the end of install (so the post-install sanity
# check `ls ~/.claude/skills/prompt-builder` actually succeeds) and at the end
# of update (so newly-shipped skills land without a separate operator step).
#
# Closes QA findings F5 (install-time skill deployment missing) and F10
# (update-time skill redeploy missing).
#
# Usage: phase_deploy_skills [--quiet]
#   --quiet  Suppress per-step info logging; only print on warn/err.
#
# Exit semantics: returns the underlying deploy.sh exit code on failure.
# Caller decides whether to propagate or downgrade the failure.
phase_deploy_skills() {
  local quiet=0
  if [ "${1:-}" = "--quiet" ]; then
    quiet=1
  fi

  if [ ! -f "${ORCHESTRATE_DEPLOY_SCRIPT}" ]; then
    orchestrate_log_warn "deploy.sh not found at ${ORCHESTRATE_DEPLOY_SCRIPT}; skipping skill deployment"
    return 0
  fi

  if [ "${quiet}" -eq 0 ]; then
    orchestrate_log_info "Deploying skills via core/deploy/deploy.sh --deploy"
  fi

  if bash "${ORCHESTRATE_DEPLOY_SCRIPT}" --deploy; then
    if [ "${quiet}" -eq 0 ]; then
      orchestrate_log_info "Skill deployment complete."
    fi
    return 0
  else
    local rc=$?
    orchestrate_log_err "Skill deployment failed (exit ${rc})."
    orchestrate_log_err "Re-run manually with: bash ${ORCHESTRATE_DEPLOY_SCRIPT} --deploy"
    return "${rc}"
  fi
}
