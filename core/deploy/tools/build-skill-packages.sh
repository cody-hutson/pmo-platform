#!/bin/bash
# Build .skill packages from source with canonical template injection.
#
# Single-source-of-truth architecture: source tree carries no per-skill
# mirror copies of template-{protocol,storage,taxonomy}.md or templates/*.
# The canonicals live at core/standards/template-*.md and
# operations/templates/*.{md,csv}. This script stages each skill
# into a temp directory, injects the canonical templates per
# TEMPLATE_SYNC_MAP (extracted at runtime from deploy.sh), then invokes
# the existing per-skill packager
# (release/skills/pmo-skill-refiner/scripts/package_skill.py) to produce
# the .skill zip archive at packages/.
#
# Usage:
#   bash core/deploy/tools/build-skill-packages.sh                 # all skills
#   bash core/deploy/tools/build-skill-packages.sh <skill> [<skill> …]
#
# Exit codes:
#   0 — all requested packages built
#   1 — canonical missing, source skill missing, or packager failure

set -euo pipefail

# Run from repo root regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

# Extract TEMPLATE_SYNC_MAP from deploy.sh at runtime — single source of
# truth for which canonicals inject into which skill.
declare -a TEMPLATE_SYNC_MAP=()
while IFS= read -r line; do
  TEMPLATE_SYNC_MAP+=("$line")
done < <(awk '/^TEMPLATE_SYNC_MAP=\(/,/^\)/' core/deploy/deploy.sh | \
         grep -E '^[[:space:]]*"[^"]+:[^"]+:[^"]+"' | \
         sed 's/^[[:space:]]*"//; s/"$//; s/[[:space:]]*#.*//')

if [[ ${#TEMPLATE_SYNC_MAP[@]} -eq 0 ]]; then
  echo "ERROR: Could not extract TEMPLATE_SYNC_MAP from core/deploy/deploy.sh" >&2
  exit 1
fi

# extract_roster_array — pull a named bash array literal out of deploy.sh at
# runtime and print one element per line (same awk-window + sed-clean idiom used
# for TEMPLATE_SYNC_MAP above, generalized to take the array name). Single source
# of truth for the per-module roster: deploy.sh Check 5 asserts these arrays match
# the on-disk skill dirs, so resolving + listing from them here keeps this builder
# in lockstep with the deploy.sh authority instead of a hand-synced name list.
#   $1 — array name (e.g. OPERATIONS_SKILLS); $2 — path to deploy.sh
extract_roster_array() {
  local array_name="$1" deploy_sh="$2"
  awk -v name="$array_name" '
    $0 ~ ("^" name "=\\(") { capture=1; next }
    capture && /^\)/        { capture=0 }
    capture {
      line=$0
      sub(/#.*/, "", line)
      gsub(/[[:space:]]/, "", line)
      if (line != "") print line
    }
  ' "$deploy_sh"
}

# Per-module skill arrays, single-sourced from deploy.sh — replaces BOTH the
# hardcoded case map in resolve_skill_module() and the hardcoded ALL_SKILLS list
# below, so neither can drift from the deploy.sh roster authority. (Append is
# unconditional: extract_roster_array emits only non-empty lines, matching the
# TEMPLATE_SYNC_MAP loop's style.)
OPERATIONS_SKILLS=(); RELEASE_SKILLS=(); CORE_SKILLS=(); CANARY_SKILLS=()
while IFS= read -r line; do OPERATIONS_SKILLS+=("$line"); done < <(extract_roster_array OPERATIONS_SKILLS core/deploy/deploy.sh)
while IFS= read -r line; do RELEASE_SKILLS+=("$line");    done < <(extract_roster_array RELEASE_SKILLS    core/deploy/deploy.sh)
while IFS= read -r line; do CORE_SKILLS+=("$line");       done < <(extract_roster_array CORE_SKILLS       core/deploy/deploy.sh)
while IFS= read -r line; do CANARY_SKILLS+=("$line");     done < <(extract_roster_array CANARY_SKILLS     core/deploy/deploy.sh)

if [[ ${#OPERATIONS_SKILLS[@]} -eq 0 || ${#RELEASE_SKILLS[@]} -eq 0 || ${#CORE_SKILLS[@]} -eq 0 ]]; then
  echo "ERROR: Could not extract per-module skill arrays from core/deploy/deploy.sh" >&2
  exit 1
fi

# Canonical-source resolver — single-sourced from the shared lib fragment
# (core/deploy/lib-template-sync-source.sh), the SAME definition deploy.sh
# sources. #2158 eliminated the former hand-synced resolve_canonical_source()
# copy here (the drift class that broke the #94 pmo-skill-editor rebuild when the
# two copies diverged). This builder already single-sources TEMPLATE_SYNC_MAP +
# the per-module skill arrays from deploy.sh; the resolver was the last
# hand-synced duplicate. Presence-guarded like the TEMPLATE_SYNC_MAP extraction.
LIB_TEMPLATE_SYNC_SOURCE="${SCRIPT_DIR}/../lib-template-sync-source.sh"
if [[ ! -f "$LIB_TEMPLATE_SYNC_SOURCE" ]]; then
  echo "ERROR: missing shared resolver lib: $LIB_TEMPLATE_SYNC_SOURCE" >&2
  exit 1
fi
# shellcheck source=../lib-template-sync-source.sh disable=SC1091
source "$LIB_TEMPLATE_SYNC_SOURCE"

# Skill → module resolver — iterates the per-module arrays extracted from deploy.sh
# above (mirrors deploy.sh resolve_skill_module). CANARY_SKILLS classifies to
# release/. Bash 3.2 portable: explicit per-array loops + `${#ARR[@]} -gt 0`
# empty-guards; no `local -n` nameref (4.3+). Returns non-zero on miss — the
# build_one call site handles that as a per-skill failure (this script runs
# `set -e`, so the call is guarded to avoid a silent whole-script abort per
# ADR-008 Rule 3; deploy.sh die()s there, but this tool has no die()).
resolve_skill_module() {
  local skill="$1" s
  if [[ ${#OPERATIONS_SKILLS[@]} -gt 0 ]]; then for s in "${OPERATIONS_SKILLS[@]}"; do [[ "$s" == "$skill" ]] && { echo "operations"; return 0; }; done; fi
  if [[ ${#RELEASE_SKILLS[@]}    -gt 0 ]]; then for s in "${RELEASE_SKILLS[@]}";    do [[ "$s" == "$skill" ]] && { echo "release";    return 0; }; done; fi
  if [[ ${#CORE_SKILLS[@]}       -gt 0 ]]; then for s in "${CORE_SKILLS[@]}";       do [[ "$s" == "$skill" ]] && { echo "core";       return 0; }; done; fi
  if [[ ${#CANARY_SKILLS[@]}     -gt 0 ]]; then for s in "${CANARY_SKILLS[@]}";     do [[ "$s" == "$skill" ]] && { echo "release";    return 0; }; done; fi
  return 1
}

# Rebuild-stable content-manifest hash of a .skill archive (BYTE-ALIGNED with
# deploy.sh skill_content_hash). Per the gate-efficacy standard Requirement (a):
# the .skill envelope embeds per-entry mtimes + member ordering, so a raw archive
# hash is NOT rebuild-stable. Hash a canonical manifest of the CONTENT instead:
# per member "<sha256-of-bytes>  <arcname>", sorted by arcname under LC_ALL=C,
# then SHA-256 of that blob. This is the baseline Check 7 compares a staged
# rebuild against. Portable primitives only (shasum -a 256, unzip, find, sort).
skill_content_hash() {
  local pkg="$1" tmp rc=0
  [[ -f "$pkg" ]] || { echo ""; return 1; }
  tmp="$(mktemp -d)" || { echo ""; return 1; }
  if ! unzip -q -o "$pkg" -d "$tmp" >/dev/null 2>&1; then
    rm -rf "$tmp"; echo ""; return 1
  fi
  (
    cd "$tmp" || exit 1
    find . -type f | LC_ALL=C sort | while IFS= read -r f; do
      printf '%s  %s\n' "$(shasum -a 256 "$f" | cut -d' ' -f1)" "${f#./}"
    done
  ) | shasum -a 256 | cut -d' ' -f1 || rc=1
  rm -rf "$tmp"
  return $rc
}

# Build a single skill's .skill package
build_one() {
  local skill="$1"
  local module
  # Guarded so a resolver miss (skill not in any deploy.sh array) is a per-skill
  # failure collected in FAILED, not a silent set -e abort of the whole build.
  if ! module=$(resolve_skill_module "$skill"); then
    echo "ERROR: cannot resolve module for '$skill' (not in deploy.sh OPERATIONS/RELEASE/CORE/CANARY arrays)" >&2
    return 1
  fi
  local source_dir="$module/skills/$skill"

  if [[ ! -d "$source_dir" ]]; then
    echo "ERROR: source dir missing: $source_dir" >&2
    return 1
  fi

  # Stage in a temp dir so we can inject canonicals without polluting source.
  local tmp_dir
  tmp_dir=$(mktemp -d)
  # Best-effort cleanup
  trap "rm -rf '$tmp_dir'" RETURN

  cp -R "$source_dir" "$tmp_dir/$skill"

  # Inject canonicals per TEMPLATE_SYNC_MAP entries that target this skill.
  local entry m_skill m_rest m_canonical m_target_rel canonical_source
  for entry in "${TEMPLATE_SYNC_MAP[@]}"; do
    m_skill="${entry%%:*}"
    m_rest="${entry#*:}"
    m_canonical="${m_rest%%:*}"
    m_target_rel="${m_rest#*:}"

    [[ "$m_skill" != "$skill" ]] && continue

    canonical_source=$(resolve_template_sync_source "$m_canonical")

    if [[ ! -f "$canonical_source" ]]; then
      echo "ERROR: canonical missing for $skill: $canonical_source" >&2
      return 1
    fi

    mkdir -p "$(dirname "$tmp_dir/$skill/$m_target_rel")"
    cp "$canonical_source" "$tmp_dir/$skill/$m_target_rel"
  done

  # Invoke the per-skill packager. Run from the pmo-skill-refiner module so
  # its `from scripts.quick_validate` import resolves.
  (
    cd release/skills/pmo-skill-refiner
    python3 -m scripts.package_skill "$tmp_dir/$skill" "$REPO_ROOT/packages/"
  ) || return 1

  # Emit the committed content baseline sidecar (gate-efficacy Requirement (a)):
  # the rebuild-stable content-manifest hash of the just-built package. Check 7
  # compares a staged rebuild's content hash against this committed value, so the
  # sidecar MUST be committed alongside the .skill. A bare hash (no filename) so
  # it is path-portable.
  local built_pkg="$REPO_ROOT/packages/${skill}.skill"
  local content_hash
  content_hash=$(skill_content_hash "$built_pkg")
  if [[ -z "$content_hash" ]]; then
    echo "ERROR: could not compute content hash for $built_pkg (sidecar not written)" >&2
    return 1
  fi
  printf '%s\n' "$content_hash" > "$REPO_ROOT/packages/${skill}.skill.sha256"
}

# Default skill list — the full deployed roster (canary excluded from packaging),
# DERIVED from the per-module arrays extracted from deploy.sh above. No hardcoded
# name list, so it cannot drift from deploy.sh: every package Check 7 iterates gets
# a rebuilt package AND a regenerated content-baseline sidecar. Check 5 asserts the
# deploy.sh arrays match the on-disk skill dirs; this list is the package-build
# projection of that same roster (deployed three; canary is source-only per ADR-04).
ALL_SKILLS=()
if [[ ${#OPERATIONS_SKILLS[@]} -gt 0 ]]; then for s in "${OPERATIONS_SKILLS[@]}"; do ALL_SKILLS+=("$s"); done; fi
if [[ ${#RELEASE_SKILLS[@]}    -gt 0 ]]; then for s in "${RELEASE_SKILLS[@]}";    do ALL_SKILLS+=("$s"); done; fi
if [[ ${#CORE_SKILLS[@]}       -gt 0 ]]; then for s in "${CORE_SKILLS[@]}";       do ALL_SKILLS+=("$s"); done; fi

if [[ $# -gt 0 ]]; then
  SKILLS_TO_BUILD=("$@")
else
  SKILLS_TO_BUILD=("${ALL_SKILLS[@]}")
fi

FAILED=()
for skill in "${SKILLS_TO_BUILD[@]}"; do
  echo "==> Building $skill"
  if ! build_one "$skill"; then
    FAILED+=("$skill")
  fi
done

echo ""
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "FAILED to build: ${FAILED[*]}"
  exit 1
fi

echo "Built ${#SKILLS_TO_BUILD[@]} package(s) into packages/"
