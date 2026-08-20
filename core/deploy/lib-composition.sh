#!/usr/bin/env bash
# lib-composition.sh — sourceable bash helpers for composition-surface operations
#
# Provides:
#   - Uniform logging (lib_compose_log_info / _warn / _err)
#   - SHA computation (lib_compose_sha_compute)
#   - Pattern C primitive wrappers (lib_compose_extract / _write / _regen)
#     — invoke core/deploy/compose.py under the hood; the Python file is the
#     single source of truth for the marker-fenced write contract.
#   - Manifest sourcing + per-entry parsing (lib_compose_source_manifest,
#     lib_compose_parse_entry, lib_compose_resolve_target)
#
# Sourced by:
#   - update.sh
#   - docs/scripts/setup-workspace.sh
#   - (future) core/deploy/orchestrate.sh
#
# Spec:
#   - Composition-surface contract: core/standards/composition-surface-spec.md
#   - Token vocabulary:             core/standards/depersonalization-spec.md
#
# Bash version: 3.2.57-safe (no associative arrays, no bash-5 substring tricks).

# Resolve the directory this lib lives in so we can find compose.py beside it.
# Works whether the lib is sourced or executed.
LIB_COMPOSITION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_COMPOSITION_DIR
readonly LIB_COMPOSE_PY="${LIB_COMPOSITION_DIR}/compose.py"

# Single resolver for the operator-instance dir (sibling lib). lib_compose_resolve_target
# uses pmo_instance_path() for the instance / hub-state tiers so PMO_INSTANCE_PATH
# overrides are honored instead of being ignored (#1830).
# shellcheck source=lib-instance-path.sh disable=SC1091
source "${LIB_COMPOSITION_DIR}/lib-instance-path.sh"

# --- Logging ---

lib_compose_log_info() { printf 'INFO: %s\n' "$*" >&2; }
lib_compose_log_warn() { printf 'WARN: %s\n' "$*" >&2; }
lib_compose_log_err()  { printf 'ERROR: %s\n' "$*" >&2; }

# --- SHA computation ---

# Echoes the SHA-256 of a file (just the hex digest, no filename).
# Exit non-zero if the file doesn't exist or shasum fails.
lib_compose_sha_compute() {
  local file="$1"
  if [ ! -f "${file}" ]; then
    lib_compose_log_err "lib_compose_sha_compute: file not found: ${file}"
    return 1
  fi
  shasum -a 256 "${file}" | awk '{print $1}'
}

# Echoes the SHA-256 of the *installed managed-section body* of a composed
# target file — the tamper-detection anchor (ADR-014). Delegates to
# `compose.py installed-sha`, which reuses the SAME body-extraction the writer
# uses, so the reader's hash domain cannot drift from the writer's.
# Echoes empty string (exit 0) if the target is absent / has no MANAGED fence /
# has an empty body — callers treat empty as "unknown, not tampered".
# Usage: lib_compose_installed_body_sha <target-path>
lib_compose_installed_body_sha() {
  local target="$1"
  python3 "${LIB_COMPOSE_PY}" installed-sha --target "${target}"
}

# --- Pattern C primitive wrappers ---

# Extract the OPERATOR ADDITIONS section from a target file, echo to stdout.
# Echoes empty string if target doesn't exist or has no markers.
# Usage: lib_compose_extract <target-path>
lib_compose_extract() {
  local target="$1"
  python3 "${LIB_COMPOSE_PY}" extract --target "${target}"
}

# Write a managed file with provided preserved-additions content.
# Usage: lib_compose_write <source> <target> <tokens-flag> <operator-toml> [<override-toml> [<preserved-file> [<dialect>]]]
#   tokens-flag: "tokens" | "raw"
#   preserved-file: optional path to file containing OPERATOR ADDITIONS content
#                   (if omitted or empty, the primitive uses the default placeholder comment)
#   dialect: optional marker dialect ("plain" | "markdown"); omitted/empty → "plain"
#            (ADR-122). Trailing-optional so existing 4-6 arg callers are unchanged.
lib_compose_write() {
  local source="$1" target="$2" tokens_flag="$3" operator_toml="$4"
  local override_toml="${5:-}" preserved_file="${6:-}" dialect="${7:-}"
  local source_sha; source_sha=$(lib_compose_sha_compute "${source}") || return 1

  local args=(
    write
    --source "${source}"
    --target "${target}"
    --operator-toml "${operator_toml}"
    --tokens-flag "${tokens_flag}"
    --source-sha "${source_sha}"
  )
  if [ -n "${override_toml}" ]; then
    args+=(--override-toml "${override_toml}")
  fi
  if [ -n "${preserved_file}" ]; then
    args+=(--preserved-additions-file "${preserved_file}")
  fi
  if [ -n "${dialect}" ]; then
    args+=(--dialect "${dialect}")
  fi

  python3 "${LIB_COMPOSE_PY}" "${args[@]}"
}

# Regenerate a target file in one shot: extract current OPERATOR ADDITIONS,
# then write the target with managed-section refreshed and additions preserved.
# Usage: lib_compose_regen <source> <target> <tokens-flag> <operator-toml> [<override-toml> [<dialect>]]
#   dialect: optional marker dialect ("plain" | "markdown"); omitted/empty → "plain"
#            (ADR-122). Trailing-optional so existing 4-5 arg callers are unchanged.
lib_compose_regen() {
  local source="$1" target="$2" tokens_flag="$3" operator_toml="$4"
  local override_toml="${5:-}" dialect="${6:-}"
  local source_sha; source_sha=$(lib_compose_sha_compute "${source}") || return 1

  local args=(
    regen
    --source "${source}"
    --target "${target}"
    --operator-toml "${operator_toml}"
    --tokens-flag "${tokens_flag}"
    --source-sha "${source_sha}"
  )
  if [ -n "${override_toml}" ]; then
    args+=(--override-toml "${override_toml}")
  fi
  if [ -n "${dialect}" ]; then
    args+=(--dialect "${dialect}")
  fi

  python3 "${LIB_COMPOSE_PY}" "${args[@]}"
}

# --- Manifest helpers ---

# Source the composition-surface manifest into the calling shell's scope.
# Populates the COMPOSITION_SURFACE_FILES array.
#
# Usage: lib_compose_source_manifest <repo-root>
#
# The manifest MUST use plain assignment (no `declare -a`). Under bash 3.2,
# `declare -a` inside a sourced-from-function context makes the array
# function-local — it never reaches the caller. Callers should pair this
# function with lib_compose_assert_manifest_loaded() to catch that
# regression at the caller's scope (this function cannot detect it because
# the array IS visible to its own local scope).
lib_compose_source_manifest() {
  local repo_root="$1"
  local manifest="${repo_root}/core/deploy/composition-surface-manifest.sh"
  if [ ! -f "${manifest}" ]; then
    lib_compose_log_err "Composition-surface manifest not found at: ${manifest}"
    return 1
  fi
  # shellcheck disable=SC1090
  source "${manifest}"
}

# Assert that COMPOSITION_SURFACE_FILES is defined AND non-empty in the
# caller's scope. Must be invoked from the same scope that called
# lib_compose_source_manifest (not from within lib_compose_source_manifest
# itself), so the check observes the array AFTER any function-local scoping
# from a misbehaving manifest has dropped.
#
# Usage:
#   lib_compose_source_manifest "${REPO_ROOT}" || return 1
#   lib_compose_assert_manifest_loaded         || return 1
#
# Closes a silent-failure path where a manifest that uses `declare -a`
# under bash 3.2 produces a function-local array that the caller never
# sees, resulting in zero composition-surface files installed.
lib_compose_assert_manifest_loaded() {
  if ! declare -p COMPOSITION_SURFACE_FILES >/dev/null 2>&1; then
    lib_compose_log_err "COMPOSITION_SURFACE_FILES not visible in caller scope"
    lib_compose_log_err "Probable cause: manifest uses 'declare -a' (function-local under bash 3.2)"
    return 1
  fi
  if [ "${#COMPOSITION_SURFACE_FILES[@]}" -eq 0 ]; then
    lib_compose_log_err "COMPOSITION_SURFACE_FILES is empty"
    return 1
  fi
}

# Parse a manifest entry into its fields by setting global vars.
# Manifest entry format: "<src-relpath>|<tier>|<tokens-flag>[|<dialect>]"
# Sets: LIB_COMPOSE_ENTRY_SRC, LIB_COMPOSE_ENTRY_TIER, LIB_COMPOSE_ENTRY_TOKENS_FLAG,
#       LIB_COMPOSE_ENTRY_DIALECT
#
# The 4th field (marker dialect, ADR-122) is OPTIONAL and back-compatible:
# `awk -F'|' '{print $4}'` on a 3-field row returns empty, which this function
# normalizes to "plain" — the pre-ADR-122 behavior — so every existing row is
# unchanged and needs no rewrite.
# Usage: lib_compose_parse_entry "<entry>"
lib_compose_parse_entry() {
  local entry="$1"
  LIB_COMPOSE_ENTRY_SRC=$(printf '%s' "${entry}" | awk -F'|' '{print $1}')
  LIB_COMPOSE_ENTRY_TIER=$(printf '%s' "${entry}" | awk -F'|' '{print $2}')
  LIB_COMPOSE_ENTRY_TOKENS_FLAG=$(printf '%s' "${entry}" | awk -F'|' '{print $3}')
  LIB_COMPOSE_ENTRY_DIALECT=$(printf '%s' "${entry}" | awk -F'|' '{print $4}')
  if [ -z "${LIB_COMPOSE_ENTRY_DIALECT}" ]; then
    LIB_COMPOSE_ENTRY_DIALECT="plain"
  fi
}

# Resolve a manifest entry's runtime target path given the workspace root.
# Usage: lib_compose_resolve_target <basename> <tier> <workspace-root>
#   tier: "hook"           → <workspace-root>/.claude/<basename>
#         "instance"       → <instance-base>/<basename>
#         "hub-state"      → <instance-base>/hub-state/<basename>
#                            (resolves <OPERATOR_INSTANCE_HUB_STATE_PATH> per
#                             core/standards/depersonalization-spec.md §4)
#         "workspace-root" → <workspace-root>/<basename minus a trailing .template>
#                            (ADR-122; strips a suffix because the workspace-root
#                             target is the operator-facing file itself —
#                             <ws>/CLAUDE.md, not <ws>/CLAUDE.md.template)
#         "operations-root"→ <operations-base>/<basename minus a trailing .template>
#                            (the operations-workspace context anchor; strips the
#                             suffix for the same reason workspace-root does. It
#                             deliberately does NOT consume <instance-base>, which
#                             is what keeps it independent of any relocation of the
#                             operator-instance family.)
#   <instance-base> = pmo_instance_path_for <workspace-root> — the
#                     PMO_INSTANCE_PATH override when set, else the instance leaf
#                     under <workspace-root> (#1830; resolver-owned leaf).
#   <operations-base> = pmo_operations_path_for <workspace-root> — the operations
#                     sibling leaf, resolver-owned for the same reason.
# Echoes the resolved path; non-zero exit on unknown tier.
lib_compose_resolve_target() {
  local basename="$1" tier="$2" workspace_root="$3"
  # Instance-tier base via the single resolver (the #1830 fix — this site
  # previously ignored PMO_INSTANCE_PATH entirely). pmo_instance_path_for honors
  # the override when set, else appends the instance leaf to the caller-passed
  # workspace_root so sandboxed installs/tests still redirect correctly (the
  # $HOME-based default is intentionally NOT used here — it would escape a passed
  # sandbox root). The instance-leaf literal lives only in the resolver.
  local instance_base; instance_base="$(pmo_instance_path_for "${workspace_root}")"
  case "${tier}" in
    hook)      printf '%s/.claude/%s\n' "${workspace_root}" "${basename}" ;;
    instance)  printf '%s/%s\n' "${instance_base}" "${basename}" ;;
    hub-state) printf '%s/hub-state/%s\n' "${instance_base}" "${basename}" ;;
    workspace-root)
      # Strip a trailing ".template" so core/CLAUDE.md.template targets
      # <ws>/CLAUDE.md. Suffix-strip precedent: the install script's mode-template
      # installer (".mode.template" -> ".mode"). A basename with no .template
      # suffix passes through unchanged.
      printf '%s/%s\n' "${workspace_root}" "${basename%.template}" ;;
    operations-root)
      # Same suffix-strip as workspace-root, one sibling directory over: the
      # target is the operations-workspace context anchor itself. The operations
      # leaf is resolved, never spelled here — the leaf-literal contract stated
      # above governs this arm exactly as it governs the instance ones.
      printf '%s/%s\n' "$(pmo_operations_path_for "${workspace_root}")" "${basename%.template}" ;;
    *)
      lib_compose_log_err "Unknown tier '${tier}' for basename '${basename}'"
      return 1
      ;;
  esac
}
