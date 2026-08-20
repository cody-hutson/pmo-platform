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
# The runtime-native operator settings overlay (ADR-121). Layer 2: operator-owned,
# git-ignored, merged by Claude Code itself. The platform only ever creates it empty,
# once, and migrates operator-added keys into it before regenerating the managed
# settings.json — it is never regenerated.
readonly SETTINGS_LOCAL_BASENAME="settings.local.json"
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
readonly EX_INCOMPLETE=75
readonly EX_INTERRUPT=130

# --- Flags ---
DRY_RUN=0
FORCE_REGEN=0
# Targeted composition-surface refresh. When 1, main dispatches surfaces_only_flow
# (a NAMED flow enumerating its own members) instead of the full top-level sequence.
# Declared as a named flow rather than as negative guards inside the shared sequence
# on purpose: a phase added to the full sequence later cannot silently join this mode,
# because the mode's member list is the function body and nothing else.
SURFACES_ONLY=0
# Set to 1 only when --workspace-root is passed explicitly (#611, R-A). The
# default WORKSPACE_ROOT (~/Claude) is the workspace tree, a DIFFERENT root than
# the deploy targets (~/.claude); so the Phase-5 deploy root is bridged from
# --workspace-root only when the operator explicitly sandboxes — never from the
# default — keeping a no-flag update byte-identical to pre-#611 behavior.
WORKSPACE_ROOT_EXPLICIT=0

# --- Phase 3 result (read by main to select the exit code; see EX_NOCHANGE) ---
REGENERATED_COUNT=0

# --- Phase 3 result: hook-tier composition surfaces found ABSENT (space-separated
# basenames). A hook-tier surface is the "escape half" of a hook control; shipping a
# hook refresh while one is missing puts the workspace in a strictly MORE restrictive
# state than either tool intends. Consumed by assert_install_complete below (#4449).
MISSING_HOOK_TIER_SURFACES=""

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
  --surfaces-only       Regenerate composition-surface managed sections ONLY.
                        Runs preflight, schema migration, the instance backup,
                        and managed-section regeneration — and nothing else.
                        Skips: needle/roster scaffolds, skill redeploy, the
                        security-hook bundle refresh, the .version snapshot, and
                        the .last-update state write. Use this to refresh a single
                        stale allowlist or other composition surface without the
                        blast radius of a full update. Note: core/deploy/deploy.sh
                        --deploy CANNOT refresh a composition surface; this flag
                        (or a full ./update.sh) is the only path that can.
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
  75   Install incomplete — a deployed control is present but not operable.
       Either a hook-tier composition surface is absent (the hook refresh was
       refused before it could ship enforcement with no escape hatch), or a
       deployed hook entrypoint is not executable after the refresh (a hook
       without +x does not run, and does not say so). Both name the offending
       file. Run docs/scripts/setup-workspace.sh, then re-run.
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
    --surfaces-only) SURFACES_ONLY=1; shift ;;
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

  local current_schema; current_schema=$(grep -m1 -E '^schema_version' "${OPERATOR_TOML}" | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  local template_schema; template_schema=$(grep -m1 -E '^schema_version' "${template_path}" | awk -F= '{gsub(/[" ]/,"",$2); print $2}')

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
    local dialect="${LIB_COMPOSE_ENTRY_DIALECT}"

    local source_file="${REPO_ROOT}/${src}"
    local basename; basename="$(basename "${src}")"

    local target
    if ! target=$(lib_compose_resolve_target "${basename}" "${tier}" "${WORKSPACE_ROOT}"); then
      continue
    fi
    # The resolver may strip a suffix (workspace-root tier drops `.template`), so
    # backups and operator-facing messages name the TARGET file, not the source
    # template. Identical to `basename` for every non-stripping tier.
    local target_basename; target_basename="$(basename "${target}")"
    # A basename is NOT unique across the manifest: two tiers may resolve two
    # different targets to the same basename (the workspace-root charter and the
    # operations-root context anchor are both `CLAUDE.md`, in different
    # directories). Every BACKUP filename is therefore keyed on tier+basename,
    # not basename alone — a flat basename backup would let one row's pre-write
    # copy silently overwrite the other's within the same timestamped directory,
    # destroying the ADR-122 §Decision 7 recovery path exactly when
    # `--force-regen` regenerates both. tier+basename IS unique: each tier
    # resolves into its own directory, so a basename can repeat across tiers but
    # never within one.
    local target_key="${tier}-${target_basename}"

    count=$((count + 1))

    if [ ! -f "${source_file}" ]; then
      warn "Source missing: ${source_file}; skipping"
      continue
    fi

    if [ ! -f "${target}" ]; then
      info "Target absent (${target_basename}, ${tier} tier); fresh install needed via setup-workspace.sh"
      if [ "${tier}" = "hook" ]; then
        MISSING_HOOK_TIER_SURFACES="${MISSING_HOOK_TIER_SURFACES:+${MISSING_HOOK_TIER_SURFACES} }${target_basename}"
      fi
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
    # Marker greps are DIALECT-AWARE (ADR-122): a marker line is `# <key>: <hex>`
    # in the plain dialect and `<!-- <key>: <hex> -->` in the markdown dialect.
    # A `#`-pinned grep returns empty against a markdown-fenced target, so
    # stored_managed_sha would never equal source_sha and the file would
    # regenerate on EVERY run forever — EX_NOCHANGE becomes unreachable.
    # `awk '{print $3}'` is field-correct for BOTH forms ($1 is the comment
    # opener, $2 the key, $3 the hex), so only the pattern changes.
    local stored_managed_sha; stored_managed_sha=$(grep -m1 -E '^(# |<!-- )managed_sha:' "${target}" | awk '{print $3}' || true)
    local stored_installed_sha; stored_installed_sha=$(grep -m1 -E '^(# |<!-- )installed_sha:' "${target}" | awk '{print $3}' || true)
    local live_body_sha; live_body_sha=$(lib_compose_installed_body_sha "${target}" || true)

    # --- Tamper detection (runs REGARDLESS of the source-SHA skip) ---
    # Fires precisely in the case the source-SHA skip would otherwise swallow:
    # source template unchanged, but the installed managed body was hand-edited.
    # Missing installed_sha ⇒ "unknown, not tampered" (self-healing back-compat:
    # the anchor is back-filled on the next legitimate regen / --force-regen).
    if [ -n "${stored_installed_sha}" ] && [ "${live_body_sha}" != "${stored_installed_sha}" ]; then
      if [ "${DRY_RUN}" -eq 1 ]; then
        info "[dry-run] tampered → would back up + regenerate: ${target_basename}"
        regenerated=$((regenerated + 1))
        continue
      fi
      local tamper_backup="${WORKSPACE_ROOT}/.backup-tampered-$(date -u +%Y%m%dT%H%M%SZ)"
      mkdir -p "${tamper_backup}"
      cp "${target}" "${tamper_backup}/${target_key}"
      warn "tamper detected in managed section of ${target_basename} (${tier} tier); backed up to ${tamper_backup}/${target_key}; regenerating from template."
      if lib_compose_regen "${source_file}" "${target}" "${tokens_flag}" "${OPERATOR_TOML}" "${override_toml}" "${dialect}"; then
        regenerated=$((regenerated + 1))
        info "Regenerated (tamper): ${target_basename}"
      else
        err "Regeneration failed for ${target_basename} (${tier} tier); restoring from tamper backup"
        cp "${tamper_backup}/${target_key}" "${target}"
        exit "${EX_REGENFAIL}"
      fi
      continue
    fi

    if [ "${FORCE_REGEN}" -eq 0 ] && [ "${source_sha}" = "${stored_managed_sha}" ]; then
      unchanged=$((unchanged + 1))
      continue
    fi

    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] would regenerate: ${target_basename} (source ${source_sha:0:12} ≠ installed ${stored_managed_sha:0:12})"
      regenerated=$((regenerated + 1))
      continue
    fi

    # Unconditional pre-write backup (ADR-122 §Decision 7). This runs on EVERY
    # real regeneration, independent of the tamper anchor — which matters most
    # for a workspace-root target, because no installed CLAUDE.md has ever
    # carried an installed_sha marker, so the tamper-backup path above cannot
    # fire on its first rewrite. This is the recovery path an EXPENSIVE-
    # reversibility write depends on.
    local backup_dir="${BACKUP_DIR_ROOT}-$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "${backup_dir}"
    cp "${target}" "${backup_dir}/${target_key}"

    # Out-of-fence discard notice (composition-surface-spec.md §3.3). A bare
    # warning is proportionate for an allowlist; for a top-level governance-
    # adjacent target — the workspace-root charter, or the operations-workspace
    # context anchor — name the path AND the backup location, so content held
    # outside either fence is recoverable rather than merely reported lost.
    #
    # A tier CLASS test, not a single-value equality: the spec clause is written
    # against the class, so a tier added to the class in the spec and not here
    # would ship a documented behavior no code provides.
    case "${tier}" in
      workspace-root|operations-root)
        info "Regenerating ${tier} target ${target}: content INSIDE the OPERATOR ADDITIONS fence is preserved verbatim; content outside either fence is not carried forward. Pre-write copy: ${backup_dir}/${target_key}"
        ;;
    esac

    if lib_compose_regen "${source_file}" "${target}" "${tokens_flag}" "${OPERATOR_TOML}" "${override_toml}" "${dialect}"; then
      regenerated=$((regenerated + 1))
      info "Regenerated: ${target_basename} (${tier} tier; backup: ${backup_dir}/${target_key})"
    else
      err "Regeneration failed for ${target_basename} (${tier} tier); restoring from backup"
      cp "${backup_dir}/${target_key}" "${target}"
      exit "${EX_REGENFAIL}"
    fi
  done

  info "Phase 3 complete: ${count} files surveyed, ${regenerated} regenerated, ${unchanged} unchanged."

  # Surface the regenerated count to main for the exit-code decision (#613).
  # A tamper-triggered regeneration (#612) increments ${regenerated}, so a
  # tamper run is correctly NOT classed as "no change".
  REGENERATED_COUNT="${regenerated}"
}

# --- Phase 2.5a: Pre-update backup of the operator-instance dir (#1830 Part 3) ---
# Before any regeneration runs, snapshot the operator-instance dir so operator-
# only data (the localized-context needle file, project keys, mode files, hub
# state) is recoverable if a later phase misbehaves. Reuses the BACKUP_DIR_ROOT
# convention Phase 3 uses for per-file managed-section backups. Best-effort: a
# missing instance dir (fresh workspace) or copy hiccup warns but never aborts
# the update. The needle file is operator data and is NEVER regenerated — this
# backup is the safety net for that guarantee.
INSTANCE_DIR=""
resolve_instance_dir() {
  # pmo_instance_path_for is available via lib-composition.sh → lib-instance-path.sh
  # (sourced in preflight). Key on WORKSPACE_ROOT so a sandboxed update resolves
  # inside the sandbox; PMO_INSTANCE_PATH override still wins.
  if command -v pmo_instance_path_for >/dev/null 2>&1; then
    INSTANCE_DIR="$(pmo_instance_path_for "${WORKSPACE_ROOT}")"
  fi
}

backup_instance_dir() {
  info "Phase 2.5a: Pre-update backup of operator-instance dir"
  resolve_instance_dir
  if [ -z "${INSTANCE_DIR}" ] || [ ! -d "${INSTANCE_DIR}" ]; then
    info "No operator-instance dir to back up (${INSTANCE_DIR:-unresolved}); skipping."
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would back up ${INSTANCE_DIR} → ${BACKUP_DIR_ROOT}-instance-<ts>"
    return 0
  fi
  local backup_dir="${BACKUP_DIR_ROOT}-instance-$(date -u +%Y%m%dT%H%M%SZ)"
  if mkdir -p "${backup_dir}" && cp -R "${INSTANCE_DIR}/." "${backup_dir}/" 2>/dev/null; then
    info "Backed up operator-instance dir → ${backup_dir}"
  else
    warn "Pre-update instance backup did not complete cleanly (continuing): ${backup_dir}"
  fi
}

# --- Phase 2.5b: localized-context needle scaffold (#1830 Part 2 + Part 3) ---
# Create-once ONLY: copy the tracked .example to the operator's needle file if and
# only if it does NOT already exist. update.sh must NEVER regenerate this file (it
# is pure operator data, unlike the marker-fenced composition surfaces Phase 3
# regenerates) — the `[ -f ] ||` guard IS that guarantee. A filled needle file is
# therefore byte-identical across repeated updates.
scaffold_needles() {
  info "Phase 2.5b: localized-context needle scaffold (create-once; never regenerated)"
  resolve_instance_dir
  local example="${REPO_ROOT}/core/config/localized-context-needles.txt.example"
  if [ ! -f "${example}" ]; then
    warn "Needle template not found at ${example}; skipping needle scaffold"
    return 0
  fi
  if [ -z "${INSTANCE_DIR}" ]; then
    warn "Instance dir unresolved; skipping needle scaffold"
    return 0
  fi
  local needle_file="${PMO_LOCALIZED_NEEDLES:-${INSTANCE_DIR}/localized-context-needles.txt}"
  if [ -f "${needle_file}" ]; then
    info "PRESERVED (operator data, never regenerated): ${needle_file}"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would scaffold needle file → ${needle_file}"
    return 0
  fi
  mkdir -p "$(dirname "${needle_file}")"
  cp "${example}" "${needle_file}"
  info "Scaffolded localized-context needle file → ${needle_file}"
}

# --- Phase 2.5c: people-roster scaffold (#2040) ---
# Create-once ONLY: copy the tracked de-identified template to the operator's
# people-roster.yaml if and only if it does NOT already exist. update.sh must
# NEVER regenerate this file (it is pure operator PII, unlike the marker-fenced
# composition surfaces Phase 3 regenerates) — the `[ -f ] ||` guard IS that
# guarantee, and a clobber would be IRREVERSIBLE. A filled roster is therefore
# byte-identical across repeated updates. Mirrors scaffold_needles exactly.
scaffold_roster() {
  info "Phase 2.5c: people-roster scaffold (create-once; never regenerated)"
  resolve_instance_dir
  local template="${REPO_ROOT}/operations/templates/people-roster-template.yaml"
  if [ ! -f "${template}" ]; then
    warn "Roster template not found at ${template}; skipping roster scaffold"
    return 0
  fi
  if [ -z "${INSTANCE_DIR}" ]; then
    warn "Instance dir unresolved; skipping roster scaffold"
    return 0
  fi
  local roster_file; roster_file="$(pmo_people_roster_for "${WORKSPACE_ROOT}")"
  if [ -f "${roster_file}" ]; then
    info "PRESERVED (operator data, never regenerated): ${roster_file}"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would scaffold roster → ${roster_file}"
    return 0
  fi
  mkdir -p "$(dirname "${roster_file}")"
  cp "${template}" "${roster_file}"
  info "Scaffolded people-roster → ${roster_file}"
}

# --- Phase 2.5e: ambient-intake directory scaffold (the drop-zone back-fill) ---
# Create-once ONLY: the ambient-intake capability's three operator-instance
# directories. Mirrors scaffold_needles / scaffold_roster exactly — an existing
# directory is PRESERVED and its contents are never regenerated, because these
# hold operator content: dropped transcripts and emails, the dedup cursor, the
# two sweep run-logs, and the external-sync poll snapshot.
#
# Scaffolding them HERE, on the update path, is what delivers the capability to
# workspaces that already exist. Installing them only at fresh install would
# leave every deployed workspace inert — which is the whole defect: the
# capability shipped specification-complete and activation-incomplete, and no
# installer, deploy or update path ever created a single one of its directories.
#
# Resolved through the instance-path resolver, never a literal, so a relocated
# instance base — an operator.toml override, an instance-path environment
# override, or a future relocation of the operator-instance family — provisions
# in the right place by construction rather than by a second list needing the
# same edit.
#
# This phase provisions directories and nothing else. Registering the scheduled
# sweep is an operator step on an agent-runtime surface this script cannot
# reach, documented in docs/INSTALL.md; an empty directory has no behavior, so
# creating one on an existing workspace changes nothing the operator did not ask
# for.
scaffold_ambient_dirs() {
  info "Phase 2.5e: ambient-intake directory scaffold (create-once; never regenerated)"
  resolve_instance_dir
  if [ -z "${INSTANCE_DIR}" ]; then
    warn "Instance dir unresolved; skipping ambient-intake scaffold"
    return 0
  fi
  if ! command -v pmo_inbox_path_for >/dev/null 2>&1; then
    warn "Ambient-intake resolvers unavailable; skipping ambient-intake scaffold"
    return 0
  fi
  local d
  for d in "$(pmo_inbox_path_for "${WORKSPACE_ROOT}")" \
           "$(pmo_ambient_intake_path_for "${WORKSPACE_ROOT}")" \
           "$(pmo_external_sync_path_for "${WORKSPACE_ROOT}")"; do
    if [ -d "${d}" ]; then
      info "PRESERVED (operator data, never regenerated): ${d}"
      continue
    fi
    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] would scaffold ambient-intake dir → ${d}"
      continue
    fi
    if mkdir -p "${d}"; then
      info "Scaffolded ambient-intake dir → ${d}"
    else
      warn "Could not create ambient-intake dir (continuing): ${d}"
    fi
  done
}

# --- Phase 2.5d: operator settings-overlay scaffold (ADR-121 §Decision 7) ---
# Create-once ONLY: write an empty {} to <ws>/.claude/settings.local.json if and only
# if it does NOT already exist. update.sh must NEVER regenerate this file (it is pure
# operator config, unlike the marker-fenced composition surfaces Phase 3 regenerates)
# — the `[ -f ] ||` guard IS that guarantee. Mirrors scaffold_needles / scaffold_roster
# exactly.
#
# Scaffolding it HERE, on the update path, is what delivers the Layer-2 overlay to
# workspaces that already exist. Installing it only at fresh install would leave every
# deployed workspace with no signposted home for operator settings — which is the
# discoverability half of the defect this closes. It also has to exist before Phase 5d
# runs, because it is the destination the guard migrates into.
#
# The body is exactly `{}` and nothing else: any commentary or default value would
# make "has the operator customized this?" undecidable.
scaffold_settings_local() {
  info "Phase 2.5d: operator settings-overlay scaffold (create-once; never regenerated)"
  local overlay="${WORKSPACE_ROOT}/.claude/${SETTINGS_LOCAL_BASENAME}"
  if [ -f "${overlay}" ]; then
    info "PRESERVED (operator config, never regenerated): ${overlay}"
    return 0
  fi
  if [ ! -d "${WORKSPACE_ROOT}/.claude" ]; then
    info "No deployed .claude dir at ${WORKSPACE_ROOT}/.claude; skipping overlay scaffold"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would scaffold operator settings overlay → ${overlay}"
    return 0
  fi
  printf '{}\n' > "${overlay}"
  info "Scaffolded operator settings overlay → ${overlay}"
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

# --- Phase 5b0: Install-completeness gate (#4449) -----------------------------
# Runs immediately BEFORE the hook refresh, and the ordering is the whole point.
# Phase 5c installs hook SCRIPTS (the enforcement half). A hook-tier composition
# surface is its allowlist (the escape half). Refreshing hooks while a hook-tier
# surface is absent leaves the workspace strictly MORE restrictive than either tool
# intends — enforcement with no escape — and the run would otherwise report success
# over it. Gating here (not at end-of-run) means the asymmetric state never lands.
#
# Scope is deliberately hook-tier ONLY: instance-tier surfaces are operator data
# with no paired enforcement half, so their absence is not an asymmetry.
#
# This CANNOT fire on a healthy workspace (every hook-tier surface present), so it
# does not stand between a healthy install and a hook security fix. On an unhealthy
# one, the correct remedy is setup-workspace.sh, which lands BOTH halves.
#
# DRY-RUN IS NOT EXEMPT, and that is deliberate rather than an oversight. Every other
# phase here has a `[ "${DRY_RUN}" -eq 1 ]` branch, so the absence of one is worth
# stating: a preview that reports "no update needed" over a MISSING security-control
# allowlist is exactly the silent-approval failure this gate exists to remove. A
# preview writes nothing, so nothing lands either way — but it must not report a
# clean verdict it has not earned. The cost, named honestly: a --dry-run against an
# incomplete workspace stops here and does not preview Phases 5c through 4.
#
# It also leaves .last-update unwritten, which is correct: the run did not complete.
assert_install_complete() {
  if [ -z "${MISSING_HOOK_TIER_SURFACES}" ]; then
    return 0
  fi
  err "Install incomplete — hook-tier composition surface(s) absent: ${MISSING_HOOK_TIER_SURFACES}"
  err "Refusing to refresh the security-hook bundle: installing an enforcement control"
  err "whose allowlist is absent would leave this workspace MORE restrictive than intended."
  err "Run docs/scripts/setup-workspace.sh to install the missing surface(s), then re-run ./update.sh."
  exit "${EX_INCOMPLETE}"
}

# --- Phase 5c0: Deployed-hook executability assertion (#4449 AC-1 / AC-3) -----
# The SIBLING of assert_install_complete above, and the two together are the whole
# of AC #3: exit non-zero when a deployed control is left "list-less OR
# non-executable". assert_install_complete owns the list-less half and must run
# BEFORE the refresh, because its job is to stop the refresh happening. This half
# is the opposite: it can only be judged AFTER the refresh, because the refresh is
# what installs and (per install_hook_with_checksum's mode repair) restores the bit.
#
# Why an assertion and not a repair. The bit is set in exactly one place —
# install_hook_with_checksum, which owns hook deployment — and this function does
# not duplicate that. It is the self-check AC #5 asks for: something that makes it
# impossible for update.sh to report success over a hook that will not run. If it
# ever fires, the repair path failed and the operator needs to know, not have it
# quietly patched over by a second mechanism whose disagreement with the first
# would be undetectable.
#
# It sits before refresh_settings deliberately, mirroring the ordering argument in
# assert_install_complete's header: Phase 5d wires settings.json registrations that
# NAME these hook scripts. Wiring events to a script that cannot execute is the
# same asymmetry class — an enforcement registration with no enforcement behind it
# — so the run stops before creating it. Exiting here also leaves .last-update
# unwritten, which is correct: the run did not complete.
#
# POPULATION AND DISCRIMINATOR — a registered duplicate, not a second decision.
# The rule is doctor.sh check_hooks_runnable's (#302 / #1850), the same one
# validate-install.sh A3 consumes: a deployed hook ENTRYPOINT must be executable; a
# co-deployed SOURCED primitive need only be readable. Sourced libs are matched by
# the co-deploy naming set (lib-*.sh, *-patterns.sh) plus everything under
# hooks/lib/, which the flat *.sh glob below does not reach. A shebang is NOT a
# discriminator — sourced libs carry one.
#
# EXIT CODE — EX_INCOMPLETE (75), shared with the list-less half rather than a new
# member. Both limbs are one operator-facing condition ("a deployed control is
# present but not operable"), both are named by one sentence of AC #3, and both
# take the same remedy. A second code would split one condition across two values
# for no diagnostic gain. This is why 75's banner text is phrased over both.
#
# DRY-RUN IS EXEMPT HERE, and the asymmetry with assert_install_complete is the
# point rather than an inconsistency. That gate fires under --dry-run because
# update.sh can NEVER repair a missing composition surface, so a clean preview
# would be a verdict no real run could earn. This condition is the opposite: a real
# run DOES repair it. Exiting 75 on a preview of a repair that is about to happen
# would report a blocker that does not exist. So a preview names the condition and
# says what a real run will do about it, and does not stop.
assert_hooks_executable() {
  local hooks_dir="${WORKSPACE_ROOT}/.claude/hooks"
  [ -d "${hooks_dir}" ] || return 0

  local hook basename nonexec=""
  for hook in "${hooks_dir}"/*.sh; do
    [ -f "${hook}" ] || continue
    basename=$(basename "${hook}")
    case "${basename}" in
      lib-*.sh|*-patterns.sh) continue ;;
    esac
    [ -x "${hook}" ] || nonexec="${nonexec:+${nonexec} }${basename}"
  done

  if [ -z "${nonexec}" ]; then
    return 0
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    warn "Deployed hook entrypoint(s) not executable: ${nonexec}"
    warn "[dry-run] a real ./update.sh run restores the executable bit; re-run without --dry-run."
    return 0
  fi

  err "Install incomplete — deployed hook entrypoint(s) not executable: ${nonexec}"
  err "A hook without the executable bit does not run, and does not report that it"
  err "did not run: the control is silently disabled while this run reports success."
  err "The hook refresh did not restore the bit, so this needs a look rather than a re-run."
  err "Run docs/scripts/setup-workspace.sh to reinstall the hook bundle, then re-run ./update.sh."
  exit "${EX_INCOMPLETE}"
}

# --- Phase 5c: Refresh the security-hook bundle (#3430) ---
# deploy.sh (Phase 5) deploys skills + packages but NOT hooks — its harness-artifact path
# reads harness/<name>/, which does not exist at the v2 repo root. So the deployed
# .claude/hooks bundle (hook scripts + co-shipped primitives + lib/dep-resolve.sh) is
# otherwise refreshed only by a full setup-workspace.sh run, and a hook/helper SECURITY fix
# never reaches an already-installed workspace via update.sh. Delegate to
# `setup-workspace.sh --refresh-hooks`, which reuses the SINGLE-SOURCED install_hooks
# co-deploy list (no third copy of the list to drift) with checksum-aware, non-interactive
# drift handling: an unedited platform hook is updated; an operator-edited hook is preserved.
refresh_hooks() {
  info "Phase 5c: Refresh security-hook bundle via setup-workspace.sh --refresh-hooks"
  local setup="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
  if [ ! -f "${setup}" ]; then
    warn "setup-workspace.sh not found at ${setup}; skipping hook refresh"
    return 0
  fi
  if [ ! -d "${WORKSPACE_ROOT}/.claude/hooks" ]; then
    info "No deployed hooks at ${WORKSPACE_ROOT}/.claude/hooks; skipping hook refresh"
    return 0
  fi
  local dry_flag=""
  if [ "${DRY_RUN}" -eq 1 ]; then dry_flag="--dry-run"; fi
  local refresh_out; refresh_out="$(mktemp -t update-phase5c.XXXXXX)"
  local rc=0
  # shellcheck disable=SC2086  # dry_flag is a single controlled token (empty or --dry-run)
  bash "${setup}" --refresh-hooks --workspace-root "${WORKSPACE_ROOT}" --source-repo "${REPO_ROOT}" ${dry_flag} \
    >"${refresh_out}" 2>&1 || rc=$?
  cat "${refresh_out}" >&2
  if [ "${rc}" -ne 0 ]; then
    rm -f "${refresh_out}"
    warn "Hook refresh returned non-zero (${rc}); continuing update."
    return 0
  fi
  # Flip the "did something" flag only on a REFRESHED hook — a hook whose deployed content
  # actually differed from source. The co-shipped primitives are re-copied by install_hooks'
  # plain `cp` on EVERY run (they log INSTALLED even when byte-identical), so keying off their
  # log lines would make every real update non-no-op and break the EX_NOCHANGE contract
  # (test_upgrade_config_durability Suite F). A genuine hook security fix always REFRESHES.
  #
  # MODE-REPAIRED counts for the same reason REFRESHED does: restoring a stripped +x
  # changes the workspace, so a run that did it must not report "no changes". Unlike
  # the primitives' INSTALLED lines this cannot fire on a healthy run — the repair
  # branch is reached only when a deployed hook was actually found non-executable —
  # so it cannot turn every update into a non-no-op.
  if grep -qE 'REFRESHED:|MODE-REPAIRED:' "${refresh_out}"; then
    PHASE5_DEPLOYED=1
  fi
  rm -f "${refresh_out}"
}

# --- Phase 5d: Refresh the managed settings.json (ADR-121) ---
# Phase 5c above refreshes the hook SCRIPTS. Their REGISTRATIONS live in
# <ws>/.claude/settings.json, and until this phase existed nothing refreshed that
# file at all — update.sh referenced it zero times. The observable consequence on a
# deployed workspace was hook scripts present on disk, byte-identical to source, with
# the events that would invoke them unwired and no signal reporting it.
#
# Delegates to `setup-workspace.sh --refresh-settings`, exactly as Phase 5c delegates
# to --refresh-hooks, so the guard, the comparator and the writer are single-sourced
# rather than re-implemented here.
#
# ORDER IS NOT REORDERABLE: this runs AFTER refresh_hooks. A registration must never
# reach a workspace ahead of the script it names, or the wiring points at nothing.
#
# NON-FATAL by construction (the Phase 5c posture): setup-workspace.sh hard-exits on
# unparseable substituted JSON or an unresolved token, and this runs mid-update, so a
# settings failure must not take down skill redeploy or the version snapshot. Warn,
# leave the flag alone, continue.
refresh_settings() {
  info "Phase 5d: Refresh managed settings.json via setup-workspace.sh --refresh-settings"
  local setup="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
  if [ ! -f "${setup}" ]; then
    warn "setup-workspace.sh not found at ${setup}; skipping settings refresh"
    return 0
  fi
  local target="${WORKSPACE_ROOT}/.claude/settings.json"
  if [ ! -f "${target}" ]; then
    info "No deployed settings.json at ${target}; skipping settings refresh"
    return 0
  fi

  # T-1: the EX_NOCHANGE flag flips on a REAL BYTE DELTA, never on "the phase ran"
  # and never on a log line. Phase 5's own history records why — a flag keyed to
  # mere success made EX_NOCHANGE unreachable and a true no-op wrongly exited 0.
  # A content hash cannot be fooled by a phase that runs and changes nothing.
  local before_sha=""
  before_sha=$(shasum -a 256 "${target}" | awk '{print $1}')

  local dry_flag="" force_flag=""
  if [ "${DRY_RUN}" -eq 1 ]; then dry_flag="--dry-run"; fi
  if [ "${FORCE_REGEN}" -eq 1 ]; then force_flag="--force-regen"; fi

  local refresh_out; refresh_out="$(mktemp -t update-phase5d.XXXXXX)"
  local rc=0
  # shellcheck disable=SC2086  # both flags are single controlled tokens (empty or the literal flag)
  bash "${setup}" --refresh-settings --workspace-root "${WORKSPACE_ROOT}" \
    --config-root "${CONFIG_ROOT}" --source-repo "${REPO_ROOT}" ${dry_flag} ${force_flag} \
    >"${refresh_out}" 2>&1 || rc=$?
  cat "${refresh_out}" >&2

  if [ "${rc}" -ne 0 ]; then
    rm -f "${refresh_out}"
    warn "Settings refresh returned non-zero (${rc}); continuing update. The managed settings.json was NOT refreshed — hook registrations may be stale."
    return 0
  fi

  # A guardrail change is not permitted to be silent even when it lands inert: name
  # what became registered, using the guard's own migration + abort lines.
  if grep -qE '^WARN: S-[345]' "${refresh_out}"; then
    grep -E '^WARN: S-[345]' "${refresh_out}" >&2
  fi
  rm -f "${refresh_out}"

  local after_sha=""
  after_sha=$(shasum -a 256 "${target}" | awk '{print $1}')
  if [ "${before_sha}" != "${after_sha}" ]; then
    PHASE5_DEPLOYED=1
    info "Phase 5d: settings.json content changed — platform hook registrations refreshed."
  else
    info "Phase 5d: settings.json byte-identical after the pass; no change."
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

# --- Surfaces-only flow (--surfaces-only) ---
# Regenerate composition-surface managed sections into an EXISTING workspace, and
# nothing else. It reuses regenerate_managed_sections UNCHANGED, so the ADR-014
# dual-hash model, tamper detection with backup, verbatim OPERATOR-ADDITIONS
# preservation, and the EX_REGENFAIL contract stay single-sourced — there is no
# second copy of those semantics to drift. This mirrors setup-workspace.sh's
# refresh_hooks_flow, whose header names this script as the owner of exactly this
# category: the hook-tier allowlists are composition-surface files refreshed by
# update.sh's regenerate_managed_sections, not there.
#
# It does NOT scaffold needles or the roster, redeploy skills, refresh the
# security-hook bundle, restamp the .version snapshot, or write .last-update.
#
# The .last-update omission is deliberate and load-bearing, not an oversight.
# write_last_update is the LAST member of the full sequence, so a .last-update
# timestamp adjacent to a surface's managed_at is positive evidence that the whole
# sequence ran. Writing it from a targeted refresh would destroy that discriminator
# and make the marker lie about which flow touched the instance.
#
# Adding a phase to the full sequence does NOT add it here: this function's body is
# the mode's entire contract, so an unlisted phase cannot join the mode by default.
surfaces_only_flow() {
  info "SURFACES-ONLY flow — regenerate composition-surface managed sections only"
  preflight
  schema_migrate
  backup_instance_dir
  regenerate_managed_sections
}

# --- Main ---
trap 'err "Interrupted"; exit '"${EX_INTERRUPT}" INT TERM

if [ "${SURFACES_ONLY}" -eq 1 ]; then
  surfaces_only_flow
else
  preflight
  schema_migrate
  backup_instance_dir
  scaffold_needles
  scaffold_roster
  # Not a member of surfaces_only_flow — that flow omits scaffold_needles and
  # scaffold_roster for the same reason: --surfaces-only regenerates composition
  # surfaces, it does not scaffold operator-instance state.
  scaffold_ambient_dirs
  scaffold_settings_local
  regenerate_managed_sections
  redeploy_skills
  # MUST precede refresh_hooks — see assert_install_complete's header. Not a member
  # of surfaces_only_flow: that flow installs no hooks, so it creates no asymmetry.
  assert_install_complete
  refresh_hooks
  # MUST follow refresh_hooks and precede refresh_settings — see
  # assert_hooks_executable's header. The refresh is what sets the bit, so the
  # assertion is meaningless before it; Phase 5d wires registrations naming these
  # scripts, so the assertion is too late after it. Not a member of
  # surfaces_only_flow: that flow refreshes no hooks, so it can change no hook mode.
  assert_hooks_executable
  # Phase 5d MUST follow Phase 5c: hook scripts land first, then the registrations that
  # name them. Reordering would wire events to scripts not yet on disk (ADR-121 §8).
  refresh_settings
  refresh_version_snapshot
  write_last_update
fi

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
