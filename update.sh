#!/usr/bin/env bash
# update.sh — pmo-platform composition-surface regeneration + schema migration
#
# Purpose:
#   Re-applies token substitution from operator.toml to managed-section content
#   in installed runtime files, preserving operator-additions sections verbatim.
#   Handles schema migration when current operator.toml lacks fields the current
#   template requires.
#
# Spec:
#   - Per-category update-time contract:   core/standards/composition-surface-spec.md §1
#   - Marker syntax + regeneration semantics: core/standards/composition-surface-spec.md §2-§3
#   - Token vocabulary:                       core/standards/depersonalization-spec.md §1
#   - User-facing procedure:                  docs/UPDATE.md
#
# Industry precedent:
#   - Helm `helm upgrade --reuse-values --reset-then-reuse-values` (regeneration)
#   - chezmoi managed-section markers (verbatim preservation)
#   - Debian dpkg `.dpkg-dist` backup-on-tamper

set -Eeuo pipefail

# --- Constants ---
readonly SCRIPT_VERSION="v1.04"
readonly OPERATOR_LOCAL_TOML_BASENAME="operator.local.toml"
readonly REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
readonly MANIFEST_FILE="${REPO_ROOT}/core/deploy/composition-surface-manifest.sh"
readonly LIB_COMPOSITION="${REPO_ROOT}/core/deploy/lib-composition.sh"

# Sandbox roots for test isolation (closes QA F9). Same precedence as
# setup-workspace.sh: CLI flag > env var > $HOME-based default.
readonly DEFAULT_CONFIG_ROOT="${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"
readonly DEFAULT_WORKSPACE_ROOT="${PMO_PLATFORM_WORKSPACE_ROOT:-${HOME}/Claude}"
CONFIG_ROOT=""              # resolved in arg parse → finalize_paths
WORKSPACE_ROOT=""           # resolved in arg parse → finalize_paths
OPERATOR_TOML=""            # derived from CONFIG_ROOT
LAST_UPDATE_FILE=""         # derived from CONFIG_ROOT
BACKUP_DIR_ROOT=""          # derived from WORKSPACE_ROOT

# Exit codes
readonly EX_OK=0
readonly EX_NOCHANGE=64
readonly EX_NOCONFIG=65
readonly EX_USERABORT=66
readonly EX_REGENFAIL=73
readonly EX_INTERRUPT=130

# --- Flags ---
DRY_RUN=0
FORCE_REGEN=0
# Set to 1 only when --workspace-root is passed explicitly (#611, R-A). The
# default WORKSPACE_ROOT (~/Claude) is the workspace tree, a DIFFERENT root than
# the deploy targets (~/.claude); so the Phase-5 deploy root is bridged from
# --workspace-root only when the operator explicitly sandboxes — never from the
# default — keeping a no-flag update byte-identical to pre-#611 behavior.
WORKSPACE_ROOT_EXPLICIT=0

# --- Phase 3 result (read by main to select the exit code; see EX_NOCHANGE) ---
REGENERATED_COUNT=0

# --- Logging ---
log()  { printf '%s\n' "$*" >&2; }
info() { printf 'INFO: %s\n' "$*" >&2; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err()  { printf 'ERROR: %s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
Usage: ./update.sh [OPTIONS]

Re-apply pmo-platform package updates: regenerate managed sections of
composition-surface files from current templates + current operator.toml,
preserving operator-additions sections verbatim.

Options:
  --dry-run             Preview planned regenerations; perform no writes
  --force-regen         Regenerate all composition-surface files unconditionally
                        (default: only regenerate files whose source SHA changed)
  --config-root PATH    Root for operator config reads/writes (default:
                        ${HOME}/.config/pmo-platform; or PMO_PLATFORM_CONFIG_ROOT env var)
  --workspace-root PATH Workspace root for managed-section regen targets +
                        backup directory (default: ${HOME}/Claude; or
                        PMO_PLATFORM_WORKSPACE_ROOT env var). When passed
                        explicitly, also used as the Phase 5 deploy-target root
                        (skills land under PATH/.claude/skills) so a sandboxed
                        update redirects skill redeploy too.
  --help                Show this help

Exit codes:
  0    Update applied successfully
  64   No update needed (source unchanged since last invocation)
  65   operator.toml missing or malformed
  66   Schema migration aborted (operator dismissed prompt)
  73   Regeneration failure (file write or verification error)
  130  Interrupted (rollback applied)

Prerequisites:
  - pmo-platform clone at $HOME/Claude/pmo-platform (or current cwd)
  - operator.toml at ~/.config/pmo-platform/operator.toml
  - Workspace previously initialized via docs/scripts/setup-workspace.sh
USAGE
}

# --- Arg parse ---
CONFIG_ROOT="$DEFAULT_CONFIG_ROOT"
WORKSPACE_ROOT="$DEFAULT_WORKSPACE_ROOT"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)       DRY_RUN=1; shift ;;
    --force-regen)   FORCE_REGEN=1; shift ;;
    --config-root)
      if [ -z "${2:-}" ]; then err "--config-root requires PATH"; exit 1; fi
      CONFIG_ROOT="$2"; shift 2 ;;
    --workspace-root)
      if [ -z "${2:-}" ]; then err "--workspace-root requires PATH"; exit 1; fi
      WORKSPACE_ROOT="$2"; WORKSPACE_ROOT_EXPLICIT=1; shift 2 ;;
    --help|-h)       usage; exit 0 ;;
    *)               err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Resolve derived paths now that flags have been parsed.
OPERATOR_TOML="${CONFIG_ROOT}/operator.toml"
LAST_UPDATE_FILE="${CONFIG_ROOT}/.last-update"
BACKUP_DIR_ROOT="${WORKSPACE_ROOT}/.backup-pre-update"
readonly OPERATOR_TOML LAST_UPDATE_FILE BACKUP_DIR_ROOT
readonly CONFIG_ROOT WORKSPACE_ROOT

# --- Phase 1: Pre-flight ---
preflight() {
  info "Phase 1: Pre-flight checks"

  # operator.toml present?
  if [ ! -f "${OPERATOR_TOML}" ]; then
    err "operator.toml not found at ${OPERATOR_TOML}"
    err "Run docs/scripts/setup-workspace.sh first."
    exit "${EX_NOCONFIG}"
  fi

  # Composition library present?
  if [ ! -f "${LIB_COMPOSITION}" ]; then
    err "Composition library not found at ${LIB_COMPOSITION}"
    err "Source repo may be incomplete; re-clone pmo-platform."
    exit "${EX_NOCONFIG}"
  fi

  # Source the composition library (provides lib_compose_* helpers + manifest sourcing)
  # shellcheck disable=SC1090
  source "${LIB_COMPOSITION}"

  if ! lib_compose_source_manifest "${REPO_ROOT}"; then
    exit "${EX_NOCONFIG}"
  fi
  # Caller-scope assert catches the bash-3.2 `declare -a` regression
  # in the manifest (the lib cannot detect it from its own scope).
  if ! lib_compose_assert_manifest_loaded; then
    exit "${EX_NOCONFIG}"
  fi

  info "Pre-flight passed (operator.toml + composition library + manifest present)."
}

# --- Phase 2: Schema migration ---
# Compare current operator.toml schema_version to template schema_version.
# If template has new fields, prompt for them and append to operator.toml.
schema_migrate() {
  info "Phase 2: Schema diff vs template"

  local template_path; template_path="$(dirname "$0")/core/config/operator.toml.template"
  if [ ! -f "${template_path}" ]; then
    warn "Template not found at ${template_path}; skipping schema diff"
    return 0
  fi

  local current_schema; current_schema=$(grep -E '^schema_version' "${OPERATOR_TOML}" | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  local template_schema; template_schema=$(grep -E '^schema_version' "${template_path}" | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')

  if [ "${current_schema}" = "${template_schema}" ]; then
    info "Schema versions match (${current_schema}); no migration needed."
    return 0
  fi

  warn "Schema version drift: current=${current_schema} template=${template_schema}"
  warn "Manual review recommended. Open operator.toml and template side-by-side."
  warn "Auto-migration of schema differences is a separate maintenance step;"
  warn "update.sh continues with current operator.toml values."
}

# --- Phase 3: Composition-surface regeneration ---
# Iterates the manifest and regenerates each entry via lib_compose_regen,
# which delegates the marker-fenced write to core/deploy/compose.py.
# SHA-skip: entries whose source SHA matches the installed managed_sha are
# left untouched unless --force-regen is set.
# Tamper detection (ADR-014): independently of the SHA-skip, each entry's live
# managed body is hashed and compared to the stored installed_sha; a mismatch
# (operator hand-edited inside the MANAGED fence) backs the file up to
# ${WORKSPACE_ROOT}/.backup-tampered-<ts>/ and force-regenerates it.
regenerate_managed_sections() {
  info "Phase 3: Regenerate composition-surface managed sections"

  local count=0 regenerated=0 unchanged=0
  local override_toml="${WORKSPACE_ROOT}/${OPERATOR_LOCAL_TOML_BASENAME}"

  for entry in "${COMPOSITION_SURFACE_FILES[@]}"; do
    lib_compose_parse_entry "${entry}"
    local src="${LIB_COMPOSE_ENTRY_SRC}"
    local tier="${LIB_COMPOSE_ENTRY_TIER}"
    local tokens_flag="${LIB_COMPOSE_ENTRY_TOKENS_FLAG}"

    local source_file="${REPO_ROOT}/${src}"
    local basename; basename="$(basename "${src}")"

    local target
    if ! target=$(lib_compose_resolve_target "${basename}" "${tier}" "${WORKSPACE_ROOT}"); then
      continue
    fi

    count=$((count + 1))

    if [ ! -f "${source_file}" ]; then
      warn "Source missing: ${source_file}; skipping"
      continue
    fi

    if [ ! -f "${target}" ]; then
      info "Target absent (${basename}); fresh install needed via setup-workspace.sh"
      continue
    fi

    local source_sha; source_sha=$(lib_compose_sha_compute "${source_file}")
    # managed_sha = source-template hash (the regeneration trigger).
    # installed_sha = SHA of the post-substitution installed managed body (the
    # tamper anchor, ADR-014). They are TWO different hashes: for token-bearing
    # files the installed body legitimately differs from the source template, so
    # tamper must compare the live body against installed_sha, never against the
    # source-template hash. `|| true` guards the no-match case under set -e
    # (pre-ADR-014 installs carry no installed_sha line).
    local stored_managed_sha; stored_managed_sha=$(grep -E '^# managed_sha:' "${target}" | head -1 | awk '{print $3}' || true)
    local stored_installed_sha; stored_installed_sha=$(grep -E '^# installed_sha:' "${target}" | head -1 | awk '{print $3}' || true)
    local live_body_sha; live_body_sha=$(lib_compose_installed_body_sha "${target}" || true)

    # --- Tamper detection (runs REGARDLESS of the source-SHA skip) ---
    # Fires precisely in the case the source-SHA skip would otherwise swallow:
    # source template unchanged, but the installed managed body was hand-edited.
    # Missing installed_sha ⇒ "unknown, not tampered" (self-healing back-compat:
    # the anchor is back-filled on the next legitimate regen / --force-regen).
    if [ -n "${stored_installed_sha}" ] && [ "${live_body_sha}" != "${stored_installed_sha}" ]; then
      if [ "${DRY_RUN}" -eq 1 ]; then
        info "[dry-run] tampered → would back up + regenerate: ${basename}"
        regenerated=$((regenerated + 1))
        continue
      fi
      local tamper_backup="${WORKSPACE_ROOT}/.backup-tampered-$(date -u +%Y%m%dT%H%M%SZ)"
      mkdir -p "${tamper_backup}"
      cp "${target}" "${tamper_backup}/${basename}"
      warn "tamper detected in managed section of ${basename}; backed up to ${tamper_backup}/${basename}; regenerating from template."
      if lib_compose_regen "${source_file}" "${target}" "${tokens_flag}" "${OPERATOR_TOML}" "${override_toml}"; then
        regenerated=$((regenerated + 1))
        info "Regenerated (tamper): ${basename}"
      else
        err "Regeneration failed for ${basename}; restoring from tamper backup"
        cp "${tamper_backup}/${basename}" "${target}"
        exit "${EX_REGENFAIL}"
      fi
      continue
    fi

    if [ "${FORCE_REGEN}" -eq 0 ] && [ "${source_sha}" = "${stored_managed_sha}" ]; then
      unchanged=$((unchanged + 1))
      continue
    fi

    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] would regenerate: ${basename} (source ${source_sha:0:12} ≠ installed ${stored_managed_sha:0:12})"
      regenerated=$((regenerated + 1))
      continue
    fi

    local backup_dir="${BACKUP_DIR_ROOT}-$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "${backup_dir}"
    cp "${target}" "${backup_dir}/${basename}"

    if lib_compose_regen "${source_file}" "${target}" "${tokens_flag}" "${OPERATOR_TOML}" "${override_toml}"; then
      regenerated=$((regenerated + 1))
      info "Regenerated: ${basename} (backup: ${backup_dir}/${basename})"
    else
      err "Regeneration failed for ${basename}; restoring from backup"
      cp "${backup_dir}/${basename}" "${target}"
      exit "${EX_REGENFAIL}"
    fi
  done

  info "Phase 3 complete: ${count} files surveyed, ${regenerated} regenerated, ${unchanged} unchanged."

  # Surface the regenerated count to main for the exit-code decision (#613).
  # A tamper-triggered regeneration (#612) increments ${regenerated}, so a
  # tamper run is correctly NOT classed as "no change".
  REGENERATED_COUNT="${regenerated}"
}

# --- Phase 4: State update ---
write_last_update() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would update ${LAST_UPDATE_FILE}"
    return 0
  fi
  mkdir -p "$(dirname "${LAST_UPDATE_FILE}")"
  printf '%s\n%s\n' \
    "last_update=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "script_version=${SCRIPT_VERSION}" \
    > "${LAST_UPDATE_FILE}"
}

# --- Phase 5: Skill redeploy ---
# After managed sections are refreshed, redeploy skills so any newly-shipped
# skills land without a separate operator step. Closes QA F10.
redeploy_skills() {
  info "Phase 5: Skill redeploy via core/deploy/orchestrate.sh"
  local orchestrate_lib="${REPO_ROOT}/core/deploy/orchestrate.sh"
  if [ ! -f "${orchestrate_lib}" ]; then
    warn "Orchestrate library not found at ${orchestrate_lib}; skipping skill redeploy"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would invoke phase_deploy_skills"
    return 0
  fi
  # Bridge --workspace-root to the deploy root (#611, R-A). phase_deploy_skills
  # invokes deploy.sh as a subprocess, which derives its targets from
  # PMO_PLATFORM_DEPLOY_ROOT (env-inherited). Export it ONLY when the operator
  # passed --workspace-root explicitly: the default WORKSPACE_ROOT is the
  # ~/Claude workspace tree (a different root than the ~/.claude deploy targets),
  # so a no-flag update must NOT redirect deploy — that keeps it byte-identical
  # to pre-#611 behavior.
  if [ "${WORKSPACE_ROOT_EXPLICIT}" -eq 1 ]; then
    export PMO_PLATFORM_DEPLOY_ROOT="${WORKSPACE_ROOT}"
    info "Phase 5 deploy root set from --workspace-root: ${WORKSPACE_ROOT}"
  fi
  # shellcheck disable=SC1090
  source "${orchestrate_lib}"
  phase_deploy_skills
}

# --- Phase 5b: Refresh .version snapshot ---
# Keep <ws>/.claude/.version in sync with the clone so the SessionStart
# version-skew hook (core/hooks/notify-version-skew.sh) compares against the
# just-deployed version — it reads this snapshot as its sibling. Advisory: a
# missing source .version warns but never fails the update.
refresh_version_snapshot() {
  info "Phase 5b: Refresh .version snapshot"
  local version_src="${REPO_ROOT}/.version"
  local version_dst="${WORKSPACE_ROOT}/.claude/.version"
  if [ ! -r "${version_src}" ]; then
    warn ".version not found at ${version_src}; skipping snapshot refresh"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would refresh .version snapshot → ${version_dst}"
    return 0
  fi
  mkdir -p "$(dirname "${version_dst}")"
  cp "${version_src}" "${version_dst}"
  info "Refreshed .version snapshot ($(head -1 "${version_dst}" | tr -d '[:space:]'))"
}

# --- Main ---
trap 'err "Interrupted"; exit '"${EX_INTERRUPT}" INT TERM

preflight
schema_migrate
regenerate_managed_sections
redeploy_skills
refresh_version_snapshot
write_last_update

# Exit code (#613): a no-op run (0 composition-surface files regenerated) returns
# EX_NOCHANGE so callers can distinguish "nothing to do" from a successful update
# that applied changes. A tamper-triggered regeneration (#612) counts as a
# regeneration, so it returns EX_OK (it is not "no change").
if [ "${REGENERATED_COUNT}" -eq 0 ]; then
  info "Update complete (no changes — composition surface already current)."
  exit "${EX_NOCHANGE}"
fi

info "Update complete."
exit "${EX_OK}"
