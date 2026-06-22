#!/usr/bin/env bash
# install.sh — pmo-platform install entry
#
# Public-facing install command for first-touch onboarding. Thin entry over
# docs/scripts/setup-workspace.sh (workspace bootstrap + composition-surface
# install + token resolution) plus the skill-deployment phase from
# core/deploy/orchestrate.sh.
#
# Closes QA findings F3 ($PWD-detection at preflight so the README's
# three-command flow works from any clone location), F5 (skills actually
# deploy at the end of install), and the asymmetric-placement issue
# (install.sh now lives at repo root next to update.sh).
#
# Usage:
#   ./install.sh [--dry-run] [--init-only-state] [<options-forwarded-to-setup>]
#
# Bash version: 3.2.57-safe.

set -Eeuo pipefail

# --- Resolve repo root ---
# install.sh sits at the repo root; we use its own location as the source-repo
# anchor (closes F3: works regardless of which directory the operator ran
# `git clone` from, as long as they `cd` into the clone before running ./install.sh).
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
readonly REPO_ROOT

readonly SETUP_WORKSPACE_SCRIPT="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
readonly ORCHESTRATE_LIB="${REPO_ROOT}/core/deploy/orchestrate.sh"
readonly VERSION_FILE="${REPO_ROOT}/.version"
readonly MANIFEST_FILE="${REPO_ROOT}/core/deploy/composition-surface-manifest.sh"

# --- Logging ---
err()  { printf 'ERROR: %s\n' "$*" >&2; }
info() { printf 'INFO: %s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
Usage: ./install.sh [OPTIONS]

Public install entry for pmo-platform. Runs in two phases:

  Phase 1 — workspace bootstrap (docs/scripts/setup-workspace.sh)
  Phase 2 — skill deployment    (core/deploy/orchestrate.sh phase_deploy_skills)

Options:
  --dry-run             Preview planned actions in the bootstrap phase;
                        skill deployment is skipped under dry-run.
  --init-only-state     Verify artifacts empirically without performing
                        install operations (forwarded to setup-workspace.sh).
  --workspace-root PATH Workspace destination (default: ${HOME}/Claude).
                        Forwarded to setup-workspace.sh, AND used as the
                        deploy-target root for Phase 2 (skills land under
                        PATH/.claude/skills instead of the live ~), so a
                        sandboxed install redirects every write.
  --config-root PATH    Root for operator config writes (default:
                        ${HOME}/.config/pmo-platform; or PMO_PLATFORM_CONFIG_ROOT
                        env var). Used by integration tests + sandboxed dry-runs
                        to isolate from operator state. Forwarded to
                        setup-workspace.sh.
  --help                Show this help and exit.

Any other options are forwarded to docs/scripts/setup-workspace.sh.

For the canonical install procedure including prerequisites and troubleshooting,
see docs/INSTALL.md.
USAGE
}

# --- Preflight: confirm this directory looks like a valid pmo-platform clone ---
preflight() {
  local missing=0
  for required in "${VERSION_FILE}" "${MANIFEST_FILE}" "${SETUP_WORKSPACE_SCRIPT}" "${ORCHESTRATE_LIB}"; do
    if [ ! -f "${required}" ]; then
      err "Required file missing: ${required}"
      missing=1
    fi
  done
  if [ "${missing}" -ne 0 ]; then
    err
    err "install.sh must be run from the root of a pmo-platform clone."
    err "Detected repo root: ${REPO_ROOT}"
    err "If you just cloned, ensure you ran: cd \$(basename pmo-platform)"
    exit 65
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    err "python3 not found on PATH."
    err "On macOS, install via Xcode Command Line Tools: xcode-select --install"
    exit 69
  fi
}

# --- Phase 1: workspace bootstrap (delegates to setup-workspace.sh) ---
phase_workspace_bootstrap() {
  info "Phase 1: workspace bootstrap (docs/scripts/setup-workspace.sh)"
  # Forward operator args; force --source-repo to this clone so the README's
  # `git clone … && cd … && ./install.sh` flow works without operator-side
  # path math.
  #
  # Exit-code capture pattern: `cmd || rc=$?` — capture BEFORE testing. The
  # natural-looking alternative `if ! cmd; then rc=$?; fi` is broken in every
  # bash, including bash 3.2: the `!` operator resets `$?` to 0 before the
  # `then` block runs. CI systems checking $? would see exit 0 even on a
  # hard failure. This is the canonical bash idiom for "run command, capture
  # exit code, decide based on it."
  local rc=0
  "${SETUP_WORKSPACE_SCRIPT}" --source-repo "${REPO_ROOT}" "$@" || rc=$?
  if [ "${rc}" -ne 0 ]; then
    err "Workspace bootstrap (setup-workspace.sh) failed with exit code ${rc}."
    err "Skill deployment NOT attempted. Re-run with --dry-run to inspect."
    exit "${rc}"
  fi
}

# --- Phase 2: skill deployment (closes QA F5) ---
phase_skill_deploy() {
  info "Phase 2: skill deployment (core/deploy/deploy.sh --deploy)"
  # shellcheck disable=SC1090
  source "${ORCHESTRATE_LIB}"
  phase_deploy_skills
}

# --- localized-context needle scaffold (#1830 Part 2) ---
# Create-once: copy the tracked .example to the operator's needle file ONLY IF
# absent. Phase 1 (setup-workspace.sh) already does this on a normal install;
# this is an idempotent belt-and-suspenders guard keyed on the same resolver, so
# it is a no-op when the file already exists. <ws_root> empty → resolver default.
scaffold_needles() {
  local ws_root="$1"
  local lib="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
  local example="${REPO_ROOT}/core/config/localized-context-needles.txt.example"
  [ -f "${lib}" ] || { info "Resolver lib absent; needle scaffold handled by Phase 1."; return 0; }
  [ -f "${example}" ] || { info "Needle template absent; skipping scaffold."; return 0; }
  # shellcheck disable=SC1090
  source "${lib}"
  local base
  if [ -n "${ws_root}" ]; then
    base="$(pmo_instance_path_for "${ws_root}")"
  else
    base="$(pmo_instance_path)"
  fi
  local needle_file="${PMO_LOCALIZED_NEEDLES:-${base}/localized-context-needles.txt}"
  if [ -f "${needle_file}" ]; then
    return 0
  fi
  mkdir -p "$(dirname "${needle_file}")"
  cp "${example}" "${needle_file}"
  info "Scaffolded localized-context needle file → ${needle_file}"
}

# --- Main ---
main() {
  # Short-circuit on --help so we don't run skill deployment after a usage print.
  for arg in "$@"; do
    case "${arg}" in
      --help|-h) usage; exit 0 ;;
    esac
  done

  preflight
  phase_workspace_bootstrap "$@"

  # Under --dry-run, skill deployment would be a no-op preview; skip cleanly.
  for arg in "$@"; do
    if [ "${arg}" = "--dry-run" ]; then
      info "Skipping skill deployment phase under --dry-run."
      return 0
    fi
  done

  # --- Bridge --workspace-root to the Phase 2 deploy root (#611, R-A) ---
  # Phase 1 forwards --workspace-root to setup-workspace.sh; Phase 2 invokes
  # deploy.sh as a subprocess (via orchestrate.sh), which derives its targets
  # from PMO_PLATFORM_DEPLOY_ROOT (env-inherited). So when the operator sandboxes
  # the workspace, export the same root for deploy → skills land under
  # <PATH>/.claude/skills, never the live ~. Exported ONLY when the flag is
  # present; absent it, deploy.sh's $HOME default applies (byte-identical to the
  # normal install). Last occurrence wins (matches getopt-style override).
  local ws_root="" prev=""
  for arg in "$@"; do
    if [ "${prev}" = "--workspace-root" ]; then
      ws_root="${arg}"
    fi
    prev="${arg}"
  done
  if [ -n "${ws_root}" ]; then
    export PMO_PLATFORM_DEPLOY_ROOT="${ws_root}"
    info "Phase 2 deploy root set from --workspace-root: ${ws_root}"
  fi

  # Idempotent needle scaffold (no-op if Phase 1 already created it).
  scaffold_needles "${ws_root}"

  phase_skill_deploy

  printf '\n' >&2
  printf '======================================================================\n' >&2
  printf 'pmo-platform install complete.\n' >&2
  printf '  Next: read docs/GETTING_STARTED.md for the first-task walkthrough.\n' >&2
  printf '======================================================================\n' >&2
}

main "$@"
