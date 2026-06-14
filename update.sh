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

# --- Phase 5 result (read by main to select the exit code; see EX_NOCHANGE) ---
# Set to 1 by redeploy_skills ONLY when Phase 5 actually deployed >=1 new/changed
# SKILL (#331 F1) — keyed off the N (skills) field of deploy.sh's own
# "Deployed: N skills, M packages, K harness artifacts" summary, NOT off
# phase_deploy_skills merely returning 0 (a true no-op also exits 0 via
# deploy.sh's E-02 short-circuit). The skills field — not the N+M+K total — is
# the signal because deploy.sh's tag-diff change detection re-copies every
# artifact changed since the last RELEASE TAG on every run (stateless, no
# content-hash skip), so a package-only tag delta re-deploys packages on an
# otherwise-no-op run; only the CHANGED-SKILLS count reflects the "new skill
# versions" F1 names. A skills-only update that ships new skill versions
# regenerates 0 managed sections yet deploys >=1 skill, so it sets this to 1 and
# main returns EX_OK; a genuine no-op deploys 0 skills, leaves this at 0, and
# main returns EX_NOCHANGE. (See redeploy_skills for the full rationale.)
PHASE5_DEPLOYED=0

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
  0    Update applied successfully (managed sections regenerated and/or skills redeployed)
  64   No update needed (no managed-section regeneration AND no skill redeploy)
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
  # Decide PHASE5_DEPLOYED from what deploy.sh ACTUALLY (re)deployed, not merely
  # from phase_deploy_skills returning 0 (#331 F1, corrected).
  #
  # Why F1's original "success ⇒ deployed" was wrong: deploy.sh --deploy exits 0
  # in BOTH a real deploy AND a no-op. So `phase_deploy_skills || rc=$?; flag=1
  # on rc==0` set the flag to 1 even when nothing changed, making EX_NOCHANGE
  # unreachable — a true no-op wrongly exited 0 (Suite F of
  # test_upgrade_config_durability.sh).
  #
  # The signal we key off is deploy.sh's own end-of-run summary, emitted on stdout
  # (its log() stream) ONLY on the deploy path (its E-02 "Nothing to deploy"
  # no-op branch exits before printing it):
  #   "Deployed: <N> skills, <M> packages, <K> harness artifacts"
  # We set PHASE5_DEPLOYED=1 only when N (CHANGED SKILLS) >= 1 — the precise
  # "new skill versions" signal #331 F1 names ("a skills-only update [with] new
  # skill versions … should not exit 64").
  #
  # Why the SKILLS count, not the N+M+K total: deploy.sh's change detection is
  # tag-diff based (detect_changed_skills diffs the last tag..HEAD) and STATELESS
  # across consecutive runs — it re-reports, and unconditionally re-copies (no
  # content-hash skip), every artifact that changed since the last RELEASE TAG on
  # EVERY invocation, regardless of whether the immediately-prior run already
  # deployed it. In a release that shipped package-only deltas since the tag
  # (e.g. v1.20..HEAD here changed 3 .skill packages but 0 skill SOURCES), a
  # second, genuinely-no-op update still re-copies those 3 packages and prints
  # "Deployed: 0 skills, 3 packages, …". Counting packages/harness in the signal
  # would make that re-copy flip the flag → the "no managed-section delta since
  # the last run ⇒ EX_NOCHANGE" contract (Suite F; and test_install_end_to_end
  # Stage 3's post-install no-op) would be unsatisfiable. The CHANGED-SKILLS
  # count is the field that (a) matches F1's stated "new skill versions" intent
  # and (b) is 0 on a true no-op in this scenario. A package is rebuilt from its
  # skill source at release-cut, so a real skill-version change lands in N>=1.
  #
  # orchestrate.sh's own INFO/WARN/ERR lines go to stderr (>&2) and flow to the
  # operator live; we capture only deploy.sh's stdout to a temp file, parse it,
  # then re-emit it so nothing is swallowed.
  local deploy_out; deploy_out="$(mktemp -t update-phase5.XXXXXX)"
  local rc=0
  phase_deploy_skills >"${deploy_out}" || rc=$?
  # Re-emit the captured deploy log so the operator still sees it (stdout).
  cat "${deploy_out}"
  if [ "${rc}" -ne 0 ]; then
    # Deploy failure: surfaced by phase_deploy_skills' own logging. Do NOT flip
    # the flag; propagate the failure so the operator sees a non-OK exit.
    rm -f "${deploy_out}"
    return "${rc}"
  fi
  # Parse the CHANGED-SKILLS count (N) from the deploy summary. `grep || true`
  # guards the no-summary (E-02 no-op) case under set -e; N>=1 means >=1 skill
  # was actually (re)deployed. Default to 0 and require a pure-integer match
  # before the arithmetic test so a missing/malformed summary can never abort
  # under set -e.
  local skills_deployed=0
  skills_deployed="$(grep -E 'Deployed: [0-9]+ skills, [0-9]+ packages, [0-9]+ harness artifacts' "${deploy_out}" \
    | tail -1 \
    | sed -E 's/.*Deployed: ([0-9]+) skills,.*/\1/' || true)"
  rm -f "${deploy_out}"
  case "${skills_deployed}" in
    ''|*[!0-9]*) skills_deployed=0 ;;
  esac
  if [ "${skills_deployed}" -ge 1 ]; then
    PHASE5_DEPLOYED=1
  fi
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

# Exit code (#613): a no-op run returns EX_NOCHANGE so callers can distinguish
# "nothing to do" from a successful update that applied changes. A tamper-
# triggered regeneration (#612) counts as a regeneration, so it returns EX_OK.
# EX_NOCHANGE requires BOTH no Phase-3 regeneration AND no Phase-5 deploy (#331
# F1): a skills-only update regenerates 0 managed sections but, if it ships new
# skill versions, DOES deploy >=1 skill (PHASE5_DEPLOYED=1), so it is a real
# change and must return EX_OK, not 64. A genuine no-op deploys nothing
# (PHASE5_DEPLOYED stays 0) and correctly returns EX_NOCHANGE.
if [ "${REGENERATED_COUNT}" -eq 0 ] && [ "${PHASE5_DEPLOYED}" -eq 0 ]; then
  info "Update complete (no changes — composition surface already current)."
  exit "${EX_NOCHANGE}"
fi

info "Update complete."
exit "${EX_OK}"
