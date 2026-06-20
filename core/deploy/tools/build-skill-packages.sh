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

# Canonical source resolver (mirrors deploy.sh resolve_template_sync_source).
# Modular canonical: templates → operations/templates/, template-* standards →
# core/standards/. See docs/module-apis.md § Public templates.
# The two explicit shared-standards-doc basenames (output-format.md,
# operational-artifacts.md, #316) are single-sourced in core/standards/ and
# match neither the template-*.md nor the *-template.{md,csv} pattern — mapped
# by an explicit narrow basename rule (NOT a broad catch-all). Keep byte-aligned
# with deploy.sh resolve_template_sync_source().
resolve_canonical_source() {
  local name="$1"
  case "$name" in
    output-format.md|operational-artifacts.md) echo "core/standards/$name" ;;
    template-*.md) echo "core/standards/$name" ;;
    *) echo "operations/templates/$name" ;;
  esac
}

# Skill → module resolver (mirrors deploy.sh resolve_skill_module)
resolve_skill_module() {
  local skill="$1"
  case "$skill" in
    eval-writer|pmo-qa-auditor|prompt-builder) echo "core" ;;
    pmo-architect|pmo-devops-sre|pmo-skill-refiner|pmo-skill-refiner-selftest-canary|pmo-skill-editor|pmo-software-engineer|build-reviewer|release-executor|release-planner|implementation-planner|pmo-principal-engineer|pmo-qa-lead) echo "release" ;;
    *) echo "operations" ;;
  esac
}

# Build a single skill's .skill package
build_one() {
  local skill="$1"
  local module
  module=$(resolve_skill_module "$skill")
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

    canonical_source=$(resolve_canonical_source "$m_canonical")

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
}

# Default skill list (every invocation skill; canary excluded from packaging)
ALL_SKILLS=(
  artifact-generator
  build-reviewer
  change-management
  comms-writer
  daily-status
  delivery-engine
  eval-writer
  file-router
  implementation-planner
  pmo-architect
  pmo-business-analyst
  pmo-devops-sre
  pmo-principal-engineer
  pmo-process-designer
  pmo-portfolio-manager
  pmo-product-owner
  pmo-program-manager
  pmo-project-manager
  pmo-qa-auditor
  pmo-qa-lead
  pmo-release-train-engineer
  pmo-skill-editor
  pmo-skill-refiner
  pmo-software-engineer
  pmo-technical-analyst
  ppm-agent
  project-initiator
  prompt-builder
  release-executor
  release-planner
  tracker-manager
  weekly-status-rollup
)

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
