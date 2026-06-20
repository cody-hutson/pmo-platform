#!/usr/bin/env bash
set -euo pipefail

# deploy.sh — PMO Platform deployment and validation tool
# Usage: ./deploy.sh [--init | --deploy [skill...] | --check [--warn] | --report]
# Exit codes: 0 = success/clean, 1 = issues found or failure

# ─── Constants ───────────────────────────────────────────────────────────────

# Per-module skill arrays (per ADR-006 canonical skill-to-module map +
# core/ADRs/ADR-008-deploy-sh-per-module-array-design.md Rule 1). Each array
# enumerates the skill names that live under <module>/skills/. Module resolution
# at call sites uses resolve_skill_module() helper. These arrays replace the
# former single SKILL_LIST; references elsewhere should name the per-module
# arrays, not SKILL_LIST.
#
# Count convention (single source of truth — Check 5 / Check 5(c) enforce it;
# core/rules/skill-deployment.md documents it; never hardcode a skill count):
#   * Deployed roster  = OPERATIONS_SKILLS + RELEASE_SKILLS + CORE_SKILLS.
#                        Each member has a packages/<name>.skill (Check 7), so the
#                        package count equals the deployed-roster size.
#   * Directory listing = deployed roster + CANARY_SKILLS (source-only, ADR-04;
#                        no package). One directory more than the package total.
#   * SUPPLEMENTARY_SKILLS is a SUBSET annotation of the arrays (full-tree-copy
#                        flag), NOT an independent registry — never summed into a
#                        count. (prompt-builder lives in CORE_SKILLS *and*
#                        SUPPLEMENTARY_SKILLS; that overlap was the old
#                        deployed-vs-"custom" off-by-one.)
OPERATIONS_SKILLS=(
  artifact-generator
  change-management
  comms-writer
  daily-status
  delivery-engine
  file-router
  intake-desk
  pmo-process-designer
  pmo-portfolio-manager
  pmo-program-coordinator
  pmo-program-manager
  pmo-project-manager
  pmo-release-train-engineer
  pmo-technical-analyst
  pmo-technical-program-manager
  ppm-agent
  project-initiator
  tracker-manager
  weekly-status-rollup
)

RELEASE_SKILLS=(
  build-reviewer
  implementation-planner
  pmo-architect
  pmo-devops-sre
  pmo-principal-engineer
  pmo-qa-lead
  pmo-skill-editor
  pmo-skill-refiner
  pmo-software-engineer
  release-executor
  release-planner
)

CORE_SKILLS=(
  eval-writer
  pmo-qa-auditor
  prompt-builder
)

# Canary skills (source-only per ADR-04; not in SUPPLEMENTARY). Lives with
# parent module (release/) per release-skills classification — pmo-skill-refiner-
# selftest-canary is the canary for the release-side pmo-skill-refiner.
CANARY_SKILLS=(
  pmo-skill-refiner-selftest-canary
)

# Deploy-target root. Every $HOME-derived deploy/validation target below
# is rebased on $DEPLOY_ROOT so a sandboxed install/test can redirect ALL writes
# (user-local skills mirror, the Cowork SEARCH_ROOT/INSTALL_PATH base, harness
# artifacts, the Check-9/11 compare targets) under one override — never the live
# ~. Modeled on the PMO_PLATFORM_CONFIG_ROOT precedent (_audit_cfg_root below).
# Precedence: --workspace-root flag (entry scripts export this var) > env >
# $HOME default. The operator.toml rung is deferred (YAGNI — no persisted
# deploy-root consumer). With the var unset, $DEPLOY_ROOT == $HOME and every
# target is byte-identical to the prior behavior. The ${VAR:-default} form
# fires for BOTH an unset var AND an exported-but-EMPTY one (#331 F4 — the
# prior comment claimed unset-only): so an empty override also collapses to
# $HOME right here at assignment, never producing an empty $DEPLOY_ROOT. The
# rm -rf bounded-target guards in deploy_skill_user_local / the Cowork path
# are therefore belt-and-suspenders against an empty root, not the primary
# mechanism (proven by test_deploy_sandbox.sh Test D).
DEPLOY_ROOT="${PMO_PLATFORM_DEPLOY_ROOT:-$HOME}"
SEARCH_ROOT="$DEPLOY_ROOT/Library/Application Support/Claude/local-agent-mode-sessions"
INSTALL_PATH=""
# Set true by cmd_deploy when detect_install_path resolves a usable Cowork skills
# path; gates the Cowork-target write blocks so a session-less machine still gets
# its user-local ~/.claude/skills mirror. Initialized here (before first read) so
# it is always defined under set -u. See ADR-013.
COWORK_AVAILABLE=false
STRICT=true
# Set true by the --all dispatch branch to force a full-roster deploy regardless
# of mirror state (explicit bootstrap / redeploy-everything). Read by
# should_full_roster(). Initialized here so it is always defined under set -u.
FORCE_ALL=false

# ─── Governance-audit tracker repo ──────────────────────────────────────────
# Checks 14/15/21/22 (+ their --report reruns) query the issue tracker for
# pipeline invariants. The repo is resolved per-clone, never hardcoded:
#   1. PMO_AUDIT_REPO environment override
#   2. audit_repo = "owner/repo" in operator.toml
#   3. this clone's own origin remote (your repo, or a downstream user's)
# If none resolve, those checks see an empty issue set and no-op cleanly, so a
# user without a pipeline tracker is unaffected. Every probe ends in `|| true`
# so a resolution failure can never abort deploy under `set -e`.
_audit_cfg_root="${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}"
_audit_src_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd || true)"
AUDIT_REPO="${PMO_AUDIT_REPO:-}"
if [ -z "$AUDIT_REPO" ] && [ -r "${_audit_cfg_root}/operator.toml" ]; then
  AUDIT_REPO="$(grep -E '^[[:space:]]*audit_repo[[:space:]]*=' "${_audit_cfg_root}/operator.toml" 2>/dev/null \
    | head -1 | sed -E -e 's/.*=[[:space:]]*"([^"]*)".*/\1/' -e t -e 's/.*=[[:space:]]*([^#]*).*/\1/' | tr -d '[:space:]' || true)"
fi
if [ -z "$AUDIT_REPO" ]; then
  AUDIT_REPO="$(git -C "${_audit_src_root:-.}" remote get-url origin 2>/dev/null \
    | sed -E 's#\.git$##; s#^.*[:/]([^/]+/[^/]+)$#\1#' || true)"
fi

# User-local skills mirror — exposes every PMO skill as a plain /skill-name
# slash command in Claude Code (matching prompt-builder's pre-existing presence).
# See core/rules/skill-deployment.md. Per Phase 0.5 Q2 default
# (D-UserLocalMirror = UNCHANGED-FLAT): mirror remains flat — no
# module-prefix in target path — preserving the operator's `/<skill-name>`
# slash-command interface.
USER_LOCAL_SKILLS_PATH="$DEPLOY_ROOT/.claude/skills"

# Cowork-provided skills used as session fingerprint (presence = active session)
FINGERPRINT_SKILLS=(docx pdf xlsx pptx schedule)

# Skills with supplementary content beyond SKILL.md (full tree copy required).
# Bare names — module resolved via resolve_skill_module() helper. This array is
# a subset annotation of (OPERATIONS|RELEASE|CORE|CANARY)_SKILLS, not an
# independent registry. Per the module placements: pmo-skill-refiner
# classifies to release/, prompt-builder classifies to core/.
SUPPLEMENTARY_SKILLS=(pmo-skill-refiner prompt-builder)

# Harness artifacts (workspace-global runtime tools, not skills).
# Currently empty — account-switcher extracts to its own repo at Phase 3.
# Source convention (when future harness artifacts ship): harness/<name>/
# at repo root. Target: ~/.claude/<name>/.
# See core/rules/harness-deployment.md for the operator-state preservation
# policy when future harness artifacts ship.
HARNESS_LIST=()

# Operator-state files within each runtime harness dir that MUST never be
# overwritten by deploy. Currently empty — no in-scope harness artifacts.
# Append harness-specific entries here as new harness artifacts ship.
HARNESS_OPERATOR_STATE=()

# Canonical template + standards-doc sync map. Each entry declares one
# canonical → mirror relationship: <skill>:<canonical-filename>:<target-rel>
# Source path is derived by file pattern (see resolve_template_sync_source):
#   *-template.{md,csv}        → operations/templates/<canonical>
#   template-*.md (taxonomy/   → core/standards/<canonical>
#                  storage/
#                  protocol)
# Per the module placements (templates → operations; template-* standards →
# core). See core/standards/template-storage.md for the full protocol. Per the
# template-architecture L3 Storage work + Collective Review R-NEW1 Option A
# (standards-doc sync).
#
# NOTE: L4 Stage 6 (2026-05-10) landed the 6 template-protocol.md
# entries below. The canonical file now exists at core/standards/template-
# protocol.md. #316 (single-source shared refs) added 8 further entries —
# output-format.md (×6 consumers) + operational-artifacts.md (×2) — homed at
# core/standards/ via the explicit-basename resolver rule. Check 13 verifies
# all 39 entries (was 31 after L4 Stage 6; 25 at L3 Stage 6).
TEMPLATE_SYNC_MAP=(
  # ── Templates: project-initiator (12 entries — 11 mirror + 1 promotion AC6) ──
  "project-initiator:communications-tracker-template.md:references/templates/communications-tracker-template.md"
  "project-initiator:daily-status-log-template.md:references/templates/daily-status-log-template.md"
  "project-initiator:daily-status-update-framework-template.md:references/templates/daily-status-update-framework-template.md"
  "project-initiator:executive-status-report-prompt-template.md:references/templates/executive-status-report-prompt-template.md"
  "project-initiator:key-terms-glossary-template.csv:references/templates/key-terms-glossary-template.csv"
  "project-initiator:milestone-tracker-template.md:references/templates/milestone-tracker-template.md"
  "project-initiator:open-meetings-tracker-template.md:references/templates/open-meetings-tracker-template.md"
  "project-initiator:raid-log-template.csv:references/templates/raid-log-template.csv"
  "project-initiator:spm-bridge-template.md:references/templates/spm-bridge-template.md"
  "project-initiator:sprint-tracker-template.md:references/templates/sprint-tracker-template.md"
  "project-initiator:transcript-register-template.md:references/templates/transcript-register-template.md"
  "project-initiator:project-md-template.md:references/project-md-template.md"
  # ── Templates: pmo-process-designer (1 entry — AC7 promotion) ──
  "pmo-process-designer:requirements-template.md:references/requirements-template.md"
  # ── Standards docs: 6 consumer skills × 3 docs = 18 entries (R-NEW1 Option A)
  # taxonomy + storage landed at L3 Stage 6; protocol landed at L4 Stage 6
  "pmo-skill-refiner:template-taxonomy.md:references/template-taxonomy.md"
  "pmo-skill-refiner:template-storage.md:references/template-storage.md"
  "pmo-process-designer:template-taxonomy.md:references/template-taxonomy.md"
  "pmo-process-designer:template-storage.md:references/template-storage.md"
  "project-initiator:template-taxonomy.md:references/template-taxonomy.md"
  "project-initiator:template-storage.md:references/template-storage.md"
  "delivery-engine:template-taxonomy.md:references/template-taxonomy.md"
  "delivery-engine:template-storage.md:references/template-storage.md"
  "eval-writer:template-taxonomy.md:references/template-taxonomy.md"
  "eval-writer:template-storage.md:references/template-storage.md"
  "release-planner:template-taxonomy.md:references/template-taxonomy.md"
  "release-planner:template-storage.md:references/template-storage.md"
  # template-protocol.md mirrors (L4 Stage 6) — 6 consumer skills
  "pmo-skill-refiner:template-protocol.md:references/template-protocol.md"
  "pmo-process-designer:template-protocol.md:references/template-protocol.md"
  "project-initiator:template-protocol.md:references/template-protocol.md"
  "delivery-engine:template-protocol.md:references/template-protocol.md"
  "eval-writer:template-protocol.md:references/template-protocol.md"
  "release-planner:template-protocol.md:references/template-protocol.md"
  # ── Shared standards docs: output-format.md (6 consumers) + operational-
  #    artifacts.md (2 consumers) = 8 entries (#316 single-source shared refs).
  #    Canonical home core/standards/ (explicit-basename resolver rule). Single
  #    path segment (references/<file>) so Check 1 exclusion + injected_ref_
  #    basenames handle them; Check 13 enforces byte-identity vs canonical.
  "comms-writer:output-format.md:references/output-format.md"
  "change-management:output-format.md:references/output-format.md"
  "delivery-engine:output-format.md:references/output-format.md"
  "pmo-process-designer:output-format.md:references/output-format.md"
  "pmo-technical-analyst:output-format.md:references/output-format.md"
  "ppm-agent:output-format.md:references/output-format.md"
  "comms-writer:operational-artifacts.md:references/operational-artifacts.md"
  "ppm-agent:operational-artifacts.md:references/operational-artifacts.md"
)

# ─── Shared Functions ────────────────────────────────────────────────────────

die() {
  echo "ERROR: $1" >&2
  exit 1
}

log() {
  echo "[$(date +%H:%M:%S)] $1"
}

# Remove a derived-mirror subtree, self-healing read-only orphans and
# failing loud (never silently) when removal is impossible. Returns 0 if the
# path is gone after the call, non-zero (with an actionable error logged) if not.
# Rationale: under `set -euo pipefail`, a bare `rm -rf` that returns non-zero
# aborts the whole deploy; the prior `2>/dev/null || true` prevented that abort
# but SWALLOWED the root cause. This keeps the non-abort property AND surfaces
# the cause. `label` is the caller's context string for the log line.
remove_mirror_subtree() {
  local target="$1" label="$2"
  [[ -e "$target" ]] || return 0                 # nothing to remove — success
  # Self-heal the common case: a read-only orphan left by Cowork session churn
  # (dr-x------ dir + r-------- files). The target is a pure derived mirror, not
  # operator state, so making it writable before removal is in-contract.
  chmod -R u+w "$target" 2>/dev/null || true     # best-effort; rm result is authoritative
  local rm_err rm_rc
  rm_err=$(rm -rf "$target" 2>&1) && rm_rc=0 || rm_rc=$?   # guarded: no set -e abort
  if [[ $rm_rc -ne 0 || -e "$target" ]]; then
    log "  FAILED:   $label — cannot refresh references/ mirror: target is read-only or undeletable"
    log "            path: $target"
    log "            cause: ${rm_err:-rm returned $rm_rc}"
    log "            remediation: chmod -R u+w \"$target\" && ./deploy.sh --deploy <skill>  (derived mirror; safe to chmod — git source untouched)"
    return 1
  fi
  return 0
}

validate_workspace() {
  # E-05: Confirm script is running from pmo-platform-v2 repo root.
  # Checks for the 3-module skeleton (operations/, release/, core/) plus
  # CLAUDE.md OR core/CLAUDE.md.template.
  # The template variant accommodates both contexts:
  #   - v2 source repo (CLAUDE.md.template exists; runtime CLAUDE.md is at
  #     operator's workspace root, depersonalized at install-time)
  #   - operator workspace (CLAUDE.md present at workspace root)
  if [[ ! -f CLAUDE.md ]] && [[ ! -f core/CLAUDE.md.template ]]; then
    die "Must run from pmo-platform-v2 repo root. CLAUDE.md (or core/CLAUDE.md.template) not found."
  fi
  if [[ ! -d core ]] || [[ ! -d release ]] || [[ ! -d operations ]]; then
    die "Must run from pmo-platform-v2 repo root. 3-module skeleton (core/, release/, operations/) not found."
  fi
}

is_supplementary() {
  # Check if a skill has supplementary content beyond SKILL.md
  local skill="$1"
  if [[ ${#SUPPLEMENTARY_SKILLS[@]} -eq 0 ]]; then
    return 1
  fi
  for supp in "${SUPPLEMENTARY_SKILLS[@]}"; do
    [[ "$skill" == "$supp" ]] && return 0
  done
  return 1
}

injected_ref_basenames() {
  # Emit (one per line) the basenames of TEMPLATE_SYNC_MAP targets for $1 that
  # land directly under the skill's runtime references/ dir. These files are
  # injected by sync_canonical_templates_to_runtime() and do NOT exist in the
  # source tree by single-source-of-truth design, so Check 1's source-vs-installed
  # diff must EXCLUDE them (their canonical comparison is Check 13's job). Reuses
  # the same entry parse as sync_canonical_templates_to_runtime (:407-411).
  # Only references/<file> (one path segment) is emitted; nested targets such as
  # project-initiator's references/templates/<file> are not — that skill carries
  # no source references/ dir, so Check 1's per-skill block never runs for it.
  local skill="$1"
  local entry e_skill rest target_rel
  for entry in "${TEMPLATE_SYNC_MAP[@]}"; do
    e_skill="${entry%%:*}"
    [[ "$e_skill" == "$skill" ]] || continue
    rest="${entry#*:}"
    target_rel="${rest#*:}"
    case "$target_rel" in
      references/*/*) continue ;;        # nested (e.g. references/templates/x) — skip
      references/*) printf '%s\n' "${target_rel#references/}" ;;
    esac
  done
}

is_harness() {
  # Check if a name is a registered harness artifact.
  # Per ADR-008 Rule 2: empty-array guard required under set -euo pipefail.
  local name="$1"
  if [[ ${#HARNESS_LIST[@]} -eq 0 ]]; then
    return 1
  fi
  for h in "${HARNESS_LIST[@]}"; do
    [[ "$name" == "$h" ]] && return 0
  done
  return 1
}

is_operator_state_file() {
  # Check if a relative-path filename is an operator-state file that must
  # never be overwritten by harness deploy.
  # Per ADR-008 Rule 2: empty-array guard required under set -euo pipefail.
  local name="$1"
  if [[ ${#HARNESS_OPERATOR_STATE[@]} -eq 0 ]]; then
    return 1
  fi
  for o in "${HARNESS_OPERATOR_STATE[@]}"; do
    [[ "$name" == "$o" ]] && return 0
  done
  return 1
}

resolve_skill_module() {
  # Resolve a skill name to its module (operations/release/core).
  # Per ADR-006 (skill-to-module map) + core/ADRs/ADR-008-deploy-sh-
  # per-module-array-design.md Rule 3 (die-on-miss under set -e).
  #
  # Each per-module array is iterated explicitly (bash 3.2 portable; nameref
  # `local -n` is bash 4.3+ which is NOT available on default macOS bash).
  # CANARY_SKILLS classifies to release/ — pmo-skill-refiner-selftest-canary
  # is the canary for the release-side pmo-skill-refiner skill.
  #
  # Returns:
  #   echoes one of: "operations" | "release" | "core"
  #   exits non-zero (via die) on miss — no silent abort under set -e
  local skill="$1"
  local s

  if [[ ${#OPERATIONS_SKILLS[@]} -gt 0 ]]; then
    for s in "${OPERATIONS_SKILLS[@]}"; do
      [[ "$s" == "$skill" ]] && { echo "operations"; return 0; }
    done
  fi
  if [[ ${#RELEASE_SKILLS[@]} -gt 0 ]]; then
    for s in "${RELEASE_SKILLS[@]}"; do
      [[ "$s" == "$skill" ]] && { echo "release"; return 0; }
    done
  fi
  if [[ ${#CORE_SKILLS[@]} -gt 0 ]]; then
    for s in "${CORE_SKILLS[@]}"; do
      [[ "$s" == "$skill" ]] && { echo "core"; return 0; }
    done
  fi
  if [[ ${#CANARY_SKILLS[@]} -gt 0 ]]; then
    for s in "${CANARY_SKILLS[@]}"; do
      [[ "$s" == "$skill" ]] && { echo "release"; return 0; }
    done
  fi
  die "resolve_skill_module: skill '${skill}' not in any per-module array (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS/CANARY_SKILLS) — add to deploy.sh or fix invocation"
}

# ─── Platform-config rung-reader (adapter-config-foundation, #22) ─────────────
# resolve_platform_config <field> [<project-path>]
#
# Resolves the effective value of a platform-config field per the 5-rung cascade
# defined in core/governance/OPERATIONS.md § Platform-Config Resolution Protocol
# (global default -> portfolio -> program -> project -> individual; most-specific
# wins). Mirrors the existing operator.toml rung-reader idiom (the audit-repo /
# cowork_install_path readers near the top of this script + detect_install_path):
# a grep-rung TOML extractor, no YAML/JSON parser, no new dependency.
#
# Rungs read (lowest -> highest precedence; first hit at the highest rung wins):
#   1. global default   <- core/config/platform-config.toml.template (this repo) OR
#                          ~/.config/pmo-platform/platform-config.toml managed body
#   2. portfolio        <- $CLAUDE_WORKSPACE_ROOT/projects/_config/PORTFOLIO.md frontmatter (optional)
#   3. program          <- $CLAUDE_WORKSPACE_ROOT/projects/<Program>/_config/program-config.toml (optional)
#   4. project          <- <project-path>/PROJECT.md frontmatter (optional; arg 2)
#   5. individual       <- ~/.config/pmo-platform/platform-config.toml [overrides] (optional)
#
# Layer-2 rungs (2-5) are operator-instance + git-ignored; on a bare repo clone
# they are absent and the reader falls through to rung 1. The global rung-1
# in-repo template is located robustly: prefer the BASH_SOURCE-derived source
# root, then fall back to the cwd-relative path (how every cmd_check check reads
# repo files), so the reader works whether deploy.sh was invoked by a relative
# or an absolute path. Echoes the resolved value (empty if the field is absent at
# every rung — the caller applies its own documented hardcoded fallback per the
# 3-level default-fallback, Rule 2).
resolve_platform_config() {
  local field="$1"
  local project_path="${2:-}"
  local cfg_root="${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}"
  local ws_root="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"

  # Locate the in-repo template robustly: BASH_SOURCE-derived root first, then
  # cwd-relative (cmd_check runs from repo root and reads files cwd-relative).
  local src_root tmpl=""
  src_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd || echo "")"
  if [ -n "$src_root" ] && [ -r "${src_root}/core/config/platform-config.toml.template" ]; then
    tmpl="${src_root}/core/config/platform-config.toml.template"
  elif [ -r "core/config/platform-config.toml.template" ]; then
    tmpl="core/config/platform-config.toml.template"
  fi

  # _toml_field <file> <field> — extract the first `field = value` (strip quotes,
  # inline comments, surrounding whitespace). Same sed shape as the operator.toml
  # readers above. Returns empty on miss / unreadable file.
  _toml_field() {
    local _f="$1" _k="$2"
    [ -n "$_f" ] && [ -r "$_f" ] || return 0
    /usr/bin/grep -E "^[[:space:]]*${_k}[[:space:]]*=" "$_f" 2>/dev/null \
      | /usr/bin/head -1 \
      | /usr/bin/sed -E -e 's/.*=[[:space:]]*"([^"]*)".*/\1/' -e t -e 's/.*=[[:space:]]*([^#]*).*/\1/' \
      | /usr/bin/sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true
  }

  local val="" hit=""

  # Rung 1 — global default (in-repo template, or installed managed body).
  hit="$(_toml_field "$tmpl" "$field")"
  [ -n "$hit" ] && val="$hit"
  hit="$(_toml_field "${cfg_root}/platform-config.toml" "$field")"
  [ -n "$hit" ] && val="$hit"   # installed instance overrides the repo template at the global rung

  # Rung 2 — portfolio (PORTFOLIO.md frontmatter platform_config block; flat key match).
  hit="$(_toml_field "${ws_root}/projects/_config/PORTFOLIO.md" "$field")"
  [ -n "$hit" ] && val="$hit"

  # Rung 3 — program (program-config.toml under the project's program dir, if derivable).
  if [ -n "$project_path" ]; then
    local prog_cfg
    prog_cfg="$(/usr/bin/find "$(dirname "$project_path")" -maxdepth 3 -name program-config.toml 2>/dev/null | /usr/bin/head -1 || true)"
    if [ -n "$prog_cfg" ]; then
      hit="$(_toml_field "$prog_cfg" "$field")"
      [ -n "$hit" ] && val="$hit"
    fi
  fi

  # Rung 4 — project (PROJECT.md frontmatter platform_config block).
  if [ -n "$project_path" ] && [ -r "${project_path}/PROJECT.md" ]; then
    hit="$(_toml_field "${project_path}/PROJECT.md" "$field")"
    [ -n "$hit" ] && val="$hit"
  fi

  # Rung 5 — individual (highest precedence). The installed instance's value was
  # already folded at rung 1; a dedicated [overrides] section read-by-section is a
  # future hardening — the global rung-1 read of the installed instance is the
  # operative individual value today.

  printf '%s' "$val"
}

build_full_roster_skills() {
  # Build the full deployable skill roster from the per-module arrays into
  # FULL_ROSTER_SKILLS. Single source of truth: the same OPERATIONS/RELEASE/CORE
  # arrays resolve_skill_module() and Check-1 already iterate — NO hardcoded name
  # list (that would drift, the very class of count-drift the roster-drift check
  # guards against). CANARY_SKILLS is EXCLUDED (source-only per ADR-04; it has no
  # package and is not a deploy target). bash 3.2 portable: explicit iteration,
  # empty-array `+` guards per ADR-008 Rule 2 (set -euo pipefail).
  FULL_ROSTER_SKILLS=()
  local s
  for s in ${OPERATIONS_SKILLS[@]+"${OPERATIONS_SKILLS[@]}"} \
           ${RELEASE_SKILLS[@]+"${RELEASE_SKILLS[@]}"} \
           ${CORE_SKILLS[@]+"${CORE_SKILLS[@]}"}; do
    FULL_ROSTER_SKILLS+=("$s")
  done
}

populate_full_roster_packages() {
  # Populate CHANGED_PACKAGES from built `.skill` packages, guarded by package
  # existence. SHARED by every package-population caller so the logic — including
  # the mandatory canary guard — lives in exactly one place (no forked package
  # logic in any caller):
  #   • No args  → the FULL package set (every packages/*.skill). Used by the
  #     fresh-install full-roster path and the --all override.
  #   • Names    → only the named skills whose package exists (manual-mode
  #     `deploy.sh --deploy <names>`), so a partial deploy lands exactly that
  #     skill's package and nothing else.
  # The `-f "packages/<name>.skill"` guard is the canary guard:
  # pmo-skill-refiner-selftest-canary is a valid skill name with NO package
  # (source-only per ADR-04); it is never appended (it has no package file), so
  # the package-deploy loop can never record a phantom FAILURE → die. In the
  # no-arg case the canary is excluded for the same reason — iterating
  # packages/ never yields it (the package set is 1:1 with the non-canary
  # roster). Harness-only names append nothing (no packages/<name>.skill). The
  # glob `-f` test also tolerates an empty packages/ dir (nullglob unassumed).
  # bash 3.2 portable.
  CHANGED_PACKAGES=()
  local pkg_name
  if [[ $# -gt 0 ]]; then
    # Scoped to the named skills.
    for pkg_name in "$@"; do
      [[ -f "packages/${pkg_name}.skill" ]] && CHANGED_PACKAGES+=("$pkg_name")
    done
  else
    # Full package set.
    local pkg_file
    for pkg_file in packages/*.skill; do
      [[ -f "$pkg_file" ]] || continue
      pkg_name="$(basename "$pkg_file" .skill)"
      CHANGED_PACKAGES+=("$pkg_name")
    done
  fi
}

should_full_roster() {
  # True (return 0) when the user-local skills mirror has NO PMO-roster skill
  # installed — i.e. a fresh clone whose install deployed nothing
  # (core/rules/skill-deployment.md §Initial bootstrap; the user-visible symptom
  # is an empty ~/.claude/skills). Cowork-provided skills (docx, pdf, …) do NOT
  # count — only PMO-roster presence, so a workspace carrying only Anthropic
  # built-ins still bootstraps. Also true when FORCE_ALL is set (the --all
  # explicit override). False (return 1) the moment any one roster skill is
  # already present, so a populated mirror reverts to incremental tag-diff
  # deployment (empty-gated, NOT first-run-gated). bash 3.2 portable.
  [[ "${FORCE_ALL:-false}" == "true" ]] && return 0
  build_full_roster_skills
  local s
  for s in ${FULL_ROSTER_SKILLS[@]+"${FULL_ROSTER_SKILLS[@]}"}; do
    [[ -d "$USER_LOCAL_SKILLS_PATH/$s" ]] && return 1   # at least one present → not empty
  done
  return 0   # zero roster skills present → empty target
}

resolve_template_sync_source() {
  # Resolve the source path for a TEMPLATE_SYNC_MAP canonical filename.
  # Convention:
  #   output-format.md          → core/standards/<name>   (explicit; #316)
  #   operational-artifacts.md  → core/standards/<name>   (explicit; #316)
  #   template-*.md             → core/standards/<name>
  #   *-template.{md,csv}       → operations/templates/<name>
  # (templates → operations, template-* standards → core. The modular
  # canonical is operations/templates/ — the public-API surface per
  # docs/module-apis.md § Operations module § Public templates.)
  #
  # The two explicit shared-standards-doc basenames (output-format.md,
  # operational-artifacts.md) are single-sourced shared references homed in
  # core/standards/ per template-storage.md §3 / §7.2. They match neither the
  # template-*.md nor the *-template.{md,csv} pattern, so they are mapped by an
  # explicit narrow basename rule rather than a broad "non-template →
  # core/standards/" catch-all — a catch-all would silently re-home any future
  # non-template basename and is deliberately avoided. Add a new explicit
  # basename here when a further shared standards doc is single-sourced.
  #
  # Args:
  #   $1 — canonical filename (e.g., raid-log-template.csv, template-storage.md,
  #        output-format.md)
  #
  # Echoes the resolved source path. Caller checks file existence.
  local name="$1"
  case "$name" in
    output-format.md|operational-artifacts.md) echo "core/standards/$name" ;;
    template-*.md)                             echo "core/standards/$name" ;;
    *)                                         echo "operations/templates/$name" ;;
  esac
}

sync_canonical_templates_to_runtime() {
  # Inject canonical templates and standards docs from operations/templates/
  # <canon> + core/standards/<canon> directly into the RUNTIME
  # skill references/ subtree at both Cowork-install and user-local-mirror
  # paths, per TEMPLATE_SYNC_MAP.
  #
  # Single-source-of-truth architecture: canonicals live ONCE in
  # core/standards/ and operations/templates/. They are injected
  # at deploy time (here) AND at package build time
  # (see core/deploy/tools/build-skill-packages.sh). The source tree does
  # NOT carry per-skill mirror copies.
  #
  # MUST be called AFTER deploy_skill + deploy_skill_user_local for the
  # given skill, because those steps overwrite the per-skill references/
  # subtree from source. This function injects on top of that copy.
  #
  # Args:
  #   $1 — skill name (optional filter; if non-empty, only entries matching
  #        this skill are synced. If empty, all map entries processed.)
  #
  # Returns:
  #   0 on success
  #   non-zero on failure (caller appends to FAILURES array)
  #
  # Contract:
  #   - Source canonical: per resolve_template_sync_source() (must exist;
  #     ENOENT → failure)
  #   - Runtime targets (both written per entry):
  #       Cowork install: $INSTALL_PATH/$skill/$target_rel
  #       User-local:     $USER_LOCAL_SKILLS_PATH/$skill/$target_rel
  #   - Parent dir created if missing; cp overwrites if present.
  #   - Verification: post-copy `diff -q` against canonical for both targets.
  local filter="${1:-}"
  local entry skill rest canonical_name target_rel source hash
  local target_install target_user
  local synced_count=0

  for entry in "${TEMPLATE_SYNC_MAP[@]}"; do
    skill="${entry%%:*}"
    rest="${entry#*:}"
    canonical_name="${rest%%:*}"
    target_rel="${rest#*:}"

    # Filter
    [[ -n "$filter" && "$skill" != "$filter" ]] && continue

    source=$(resolve_template_sync_source "$canonical_name")
    target_install="$INSTALL_PATH/$skill/$target_rel"
    target_user="$USER_LOCAL_SKILLS_PATH/$skill/$target_rel"

    if [[ ! -f "$source" ]]; then
      log "  FAILED:  template-inject — canonical missing: $source"
      return 1
    fi

    # Cowork install target — gated on COWORK_AVAILABLE (ADR-013). With no Cowork
    # session, skip the install-target write (and do NOT return 1) so the user-local
    # injection below still runs and the function returns 0; INSTALL_PATH is empty.
    if [[ "$COWORK_AVAILABLE" == "true" ]]; then
      mkdir -p "$(dirname "$target_install")"
      if ! cp -p "$source" "$target_install" 2>/dev/null; then
        log "  FAILED:  template-inject — copy failed (install): $canonical_name → $skill/$target_rel"
        return 1
      fi
      if ! diff -q "$source" "$target_install" >/dev/null 2>&1; then
        log "  FAILED:  template-inject — verification failed (install): $skill/$target_rel"
        return 1
      fi
    fi

    # User-local target — always written (Cowork-independent).
    mkdir -p "$(dirname "$target_user")"
    if ! cp -p "$source" "$target_user" 2>/dev/null; then
      log "  FAILED:  template-inject — copy failed (user-local): $canonical_name → $skill/$target_rel"
      return 1
    fi
    if ! diff -q "$source" "$target_user" >/dev/null 2>&1; then
      log "  FAILED:  template-inject — verification failed (user-local): $skill/$target_rel"
      return 1
    fi

    hash=$(md5 -q "$source" 2>/dev/null | cut -c1-8) || hash="n/a"
    log "  Injected: $canonical_name → $skill ($hash)"
    synced_count=$((synced_count + 1))
  done

  # Report no-op cleanly when filtered to a skill with no map entries
  if [[ -n "$filter" && $synced_count -eq 0 ]]; then
    log "  (no canonical templates registered for $filter)"
  fi

  return 0
}

deploy_skill_user_local() {
  # Mirror a single skill's full source tree from <module>/skills/<name>/ to
  # USER_LOCAL_SKILLS_PATH/<name>/, so it appears in Claude Code's slash-
  # command menu as plain /<name>. Per the user-local-mirror rule.
  #
  # Source module resolved via resolve_skill_module(). Target preserved FLAT
  # per Phase 0.5 Q2 default (D-UserLocalMirror = UNCHANGED-FLAT) — operator
  # slash-command interface stays plain /<skill-name>; module-aware
  # namespacing is deferred to P2.5+.
  #
  # Args:
  #   $1 — skill name (must exist in <module>/skills/<name>/)
  #
  # Returns:
  #   0 on success
  #   non-zero on failure (caller appends to FAILURES array)
  #
  # Contract:
  #   - Source: <module>/skills/$1/  (full directory, including SKILL.md
  #     and any references/, evals/, scripts/, etc.)
  #   - Target: $USER_LOCAL_SKILLS_PATH/$1/ (FLAT — no module prefix)
  #   - Pre-existing target dir is replaced (no operator-state preservation
  #     applies here — these dirs are pure deploy artifacts, not runtime state)
  #   - Verify success by diffing SKILL.md after copy
  #   - Log success: "  Mirrored: <name> ($hash)"
  #   - Log failure: "  FAILED:   <name> — user-local mirror — <reason>"
  local skill="$1"
  local module
  module=$(resolve_skill_module "$skill")
  local source_dir="$module/skills/$skill"
  local target_dir="$USER_LOCAL_SKILLS_PATH/$skill"

  [[ -d "$source_dir" ]] || { log "  FAILED:   $skill — user-local mirror — source dir missing"; return 1; }

  # Pristine clean: pure deploy artifact, no operator-state to preserve.
  # Matches the Cowork-target precedent (rm -rf of references/, below).
  #
  # Bounded-target guard (D5): before the destructive rm -rf, assert the
  # target is well-formed and lies under the resolved skills root. This keeps the
  # rm -rf inside the sandbox under a $DEPLOY_ROOT override AND hardens the
  # live-~ path: it refuses an empty $DEPLOY_ROOT (which would collapse the
  # target to "/.claude/skills/<skill>"), a $skill containing ".." (path-escape),
  # or any future refactor that decouples $target_dir from $USER_LOCAL_SKILLS_PATH.
  if [[ -z "$target_dir" || "$target_dir" != "$USER_LOCAL_SKILLS_PATH/"* || "$skill" == *..* ]]; then
    log "  FAILED:   $skill — user-local mirror — refusing rm -rf of unexpected target ($target_dir)"
    return 1
  fi
  if ! remove_mirror_subtree "$target_dir" "$skill — user-local mirror"; then
    return 1   # caller (deploy_skill_user_local invocation) converts to FAILURES+=("$skill (user-local)")
  fi
  mkdir -p "$target_dir"

  if ! cp -R "$source_dir/." "$target_dir/" 2>/dev/null; then
    log "  FAILED:   $skill — user-local mirror — copy failed"
    return 1
  fi

  if ! diff -q "$source_dir/SKILL.md" "$target_dir/SKILL.md" >/dev/null 2>&1; then
    log "  FAILED:   $skill — user-local mirror — SKILL.md verification failed"
    return 1
  fi

  local hash
  hash=$(md5 -q "$source_dir/SKILL.md" 2>/dev/null | cut -c1-8) || hash="n/a"
  log "  Mirrored: $skill ($hash)"
  return 0
}

detect_install_path() {
  # R-08, E-10: Resolve the Cowork skills-plugin install path without hardcoded
  # UUIDs, via a deterministic resolution ladder (ADR-013). A Cowork session UUID
  # is per-install runtime state, never a repo constant, so resolution is driven
  # by configuration and live-session signal — mtime is demoted to a logged last
  # resort because it is not a correctness signal (an orphaned session left by a
  # plugin reinstall / app update / re-auth keeps its Cowork-provided skills and
  # can out-rank the live session on mtime).
  #
  # Ladder:
  #   1. Config base (authoritative): operator.toml [paths].cowork_install_path,
  #      captured at clean install before any orphan exists; scopes enumeration.
  #   2. Single candidate: if exactly one session resolves, use it.
  #   3. Fingerprint + skill-count: among fingerprinted candidates prefer the one
  #      with the most deployed skill dirs (the live session carries the full
  #      roster; a stale one lags) — a better signal than mtime.
  #   4. Logged mtime (last resort): if still ambiguous, fall back to mtime BUT
  #      log explicitly that the non-authoritative heuristic was used.
  #   5. Structured terminal: if nothing resolves, set INSTALL_PATH="" and
  #      return 2 (NOT a bare die) so the caller decides warn+continue vs abort.
  #
  # Return contract: 0 = INSTALL_PATH resolved to an existing dir; 2 = no usable
  # Cowork session resolved (INSTALL_PATH left empty). Never exits the process.
  local -a matches
  matches=()

  # Rung 1 — config base. Reuse the operator.toml reader idiom (see the audit-repo
  # block near the top of this script). When [paths].cowork_install_path is set,
  # enumerate sessions under that base (orphan-immune); otherwise fall back to the
  # default SEARCH_ROOT. Every probe ends in `|| true` so a resolution failure
  # cannot abort under `set -e`.
  local _di_cfg_root="${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}"
  local cowork_base=""
  if [ -r "${_di_cfg_root}/operator.toml" ]; then
    cowork_base="$(grep -E '^[[:space:]]*cowork_install_path[[:space:]]*=' "${_di_cfg_root}/operator.toml" 2>/dev/null \
      | head -1 | sed -E -e 's/.*=[[:space:]]*"([^"]*)".*/\1/' -e t -e 's/.*=[[:space:]]*([^#]*).*/\1/' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)"
  fi
  local search_base="$SEARCH_ROOT"
  if [[ -n "$cowork_base" ]]; then
    search_base="$cowork_base"
  fi

  # Collect matching directories (maxdepth 3 to reach UUID1/UUID2/skills/)
  while IFS= read -r -d '' dir; do
    matches+=("$dir")
  done < <(find "$search_base/skills-plugin" -maxdepth 3 -name "skills" -type d -print0 2>/dev/null)

  local count=${#matches[@]}

  if [[ $count -eq 0 ]]; then
    # No Cowork session present. There is no repo-canonical session path to fall
    # back to — a Cowork session UUID is per-install runtime state, not a repo
    # constant — so leave INSTALL_PATH empty and let the structured terminal
    # (rung 5) return 2, rather than fabricating a path that fails an opaque
    # existence check downstream. A session-less machine is a SUPPORTED install
    # case for the user-local ~/.claude/skills mirror, which needs no session.
    INSTALL_PATH=""
    log "Warning: No Cowork skills-plugin session found under: $search_base/skills-plugin"
    log "         This is expected on a Claude-Code-CLI-only machine with no Cowork app session."
    log "         Cowork-target skill deployment requires an active session; the user-local"
    log "         ~/.claude/skills mirror does not. Verify Cowork is installed and has run at least once."
  elif [[ $count -eq 1 ]]; then
    # Rung 2 — single candidate.
    INSTALL_PATH="${matches[0]}"
  else
    # Multiple matches — filter by fingerprint (Cowork-provided skills present)
    local -a fingerprinted=()
    for candidate in "${matches[@]}"; do
      for fp_skill in "${FINGERPRINT_SKILLS[@]}"; do
        if [[ -d "$candidate/$fp_skill" ]]; then
          fingerprinted+=("$candidate")
          break
        fi
      done
    done

    # Choose the candidate pool: fingerprinted sessions when any exist, else all.
    local -a pool=()
    local pool_desc=""
    if [[ ${#fingerprinted[@]} -gt 0 ]]; then
      pool=("${fingerprinted[@]}")
      pool_desc="active (fingerprinted)"
    else
      pool=("${matches[@]}")
      pool_desc="all (no Cowork-provided skills present in any)"
    fi

    if [[ ${#pool[@]} -eq 1 ]]; then
      INSTALL_PATH="${pool[0]}"
    else
      # Rung 3 — prefer the candidate with the MOST deployed skill dirs. The live
      # session accumulates the full PMO roster; a stale one lags. Deterministic
      # when the live session is fuller than the orphans.
      local best="" best_count=-1 tie=false
      local cand cand_count
      for cand in "${pool[@]}"; do
        cand_count="$(find "$cand" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]' || true)"
        [[ -z "$cand_count" ]] && cand_count=0
        if [[ "$cand_count" -gt "$best_count" ]]; then
          best="$cand"; best_count="$cand_count"; tie=false
        elif [[ "$cand_count" -eq "$best_count" ]]; then
          tie=true
        fi
      done

      if [[ -n "$best" && "$tie" == "false" ]]; then
        INSTALL_PATH="$best"
        log "Warning: Multiple $pool_desc sessions found (${#pool[@]}). Using fullest skill roster: $INSTALL_PATH"
      else
        # Rung 4 — logged mtime (non-authoritative last resort) on a skill-count tie.
        INSTALL_PATH="$(ls -dt "${pool[@]}" 2>/dev/null | head -1 || true)"
        log "Warning: tiebreaker fell through to mtime (non-authoritative) among ${#pool[@]} $pool_desc sessions: $INSTALL_PATH"
      fi
    fi
  fi

  # Rung 5 — structured terminal. A resolved, existing path returns success; no
  # usable session yields an empty INSTALL_PATH and return 2 (NOT a bare die), so
  # callers can warn+continue to the user-local mirror instead of aborting.
  if [[ -n "$INSTALL_PATH" && -d "$INSTALL_PATH" ]]; then
    return 0
  fi
  INSTALL_PATH=""
  return 2
}

detect_changed_skills() {
  # R-05, E-01: Merge-aware skill change detection
  local diff_base

  # PRIMARY: tag-based diff (handles all merge strategies)
  local tag
  tag=$(git describe --tags --abbrev=0 2>/dev/null) || true
  if [[ -n "${tag:-}" ]]; then
    # When the most-recent tag points AT HEAD (tag-then-deploy ordering — the
    # standard Stage 12 Chip Pattern per hub-spoke-bridge.md), `tag..HEAD`
    # collapses to empty. Detect via --exact-match and fall back to the
    # second-most-recent tag (HEAD^) so cross-release changes since the
    # prior tag still surface.
    if git describe --tags --exact-match HEAD >/dev/null 2>&1; then
      local prev_tag
      prev_tag=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null) || true
      if [[ -n "${prev_tag:-}" ]]; then
        diff_base="$prev_tag"
      else
        # Edge case: HEAD is the FIRST tagged commit. Fall back to HEAD~1.
        diff_base="HEAD~1"
      fi
    else
      diff_base="$tag"
    fi
  else
    # FALLBACK: HEAD~1
    diff_base="HEAD~1"
  fi

  # Changed skills (unique directory names; module-aware iteration over the
  # 3 per-module skill subtrees).
  CHANGED_SKILLS=()
  while IFS= read -r skill; do
    [[ -n "$skill" ]] && CHANGED_SKILLS+=("$skill")
  done < <(git diff --name-only "$diff_base"..HEAD -- 'operations/skills/' 'release/skills/' 'core/skills/' 2>/dev/null | \
    sed -n 's|\(operations\|release\|core\)/skills/\([^/]*\)/.*|\2|p' | sort -u)

  # Changed packages — `packages/` at v2 root (no module nesting per the v2 root layout).
  CHANGED_PACKAGES=()
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && CHANGED_PACKAGES+=("$pkg")
  done < <(git diff --name-only "$diff_base"..HEAD -- 'packages/' 2>/dev/null | \
    sed -n 's|packages/\(.*\)\.skill|\1|p' | sort -u)

  # E-03: Deleted skills (module-aware capture across the 3 subtrees).
  DELETED_SKILLS=()
  while IFS= read -r skill; do
    [[ -n "$skill" ]] && DELETED_SKILLS+=("$skill")
  done < <(git diff --diff-filter=D --name-only "$diff_base"..HEAD -- 'operations/skills/' 'release/skills/' 'core/skills/' 2>/dev/null | \
    sed -n 's|\(operations\|release\|core\)/skills/\([^/]*\)/.*|\2|p' | sort -u)

  # Changed harness artifacts (harness/ does NOT exist at v2 root —
  # account-switcher extracts to its own repo at Phase 3). The diff
  # against the absent path yields empty; future harness artifacts at v2 root
  # are picked up by the same pattern.
  CHANGED_HARNESS=()
  while IFS= read -r h; do
    [[ -n "$h" ]] && CHANGED_HARNESS+=("$h")
  done < <(git diff --name-only "$diff_base"..HEAD -- 'harness/' 2>/dev/null | \
    sed -n 's|harness/\([^/]*\)/.*|\1|p' | sort -u)
}

# ─── Mode: --deploy ──────────────────────────────────────────────────────────
#
# Note: --init mode (a one-time legacy cutover migration) has been REMOVED per
# the Stage 5 spec §1.7 + Phase 0.5 Q9 (operator-confirmed at Collective
# Review). v2 ships with the target layout; no Cowork-governance migration
# cutover is needed. Operators upgrading from older layouts run the legacy
# script from the predecessor repository as a one-time step.

deploy_harness_artifact() {
  # Deploy a single harness artifact from harness/<name>/ to ~/.claude/<name>/,
  # applying operator-state preservation policy. HARNESS_LIST is currently empty
  # so this function is unreached today; future-proof — if a new harness
  # artifact ships at harness/<name>/ at v2 repo root, this function deploys it.
  # See core/rules/harness-deployment.md for the contract.
  #
  # File rules:
  #   - *.sh, *.md (excluding commands/*) → overwrite
  #   - config.toml → only if target doesn't exist (operator customizations preserved)
  #   - HARNESS_OPERATOR_STATE files → never touched
  #   - commands/*.md → ~/.claude/commands/ (overwrite)
  local name="$1"
  local source_dir="harness/$name"
  local target_dir="$DEPLOY_ROOT/.claude/$name"
  local commands_target="$DEPLOY_ROOT/.claude/commands"

  [[ -d "$source_dir" ]] || { log "  FAILED:   harness/$name — source dir missing"; FAILURES+=("harness/$name"); return; }

  mkdir -p "$target_dir" "$commands_target"

  local copy_failures=false
  local skipped_state=()

  # Top-level files (no recursion into commands/)
  local item base
  for item in "$source_dir"/*; do
    [[ -e "$item" ]] || continue
    base=$(basename "$item")

    if [[ -d "$item" ]]; then
      # Skip commands/ here — handled separately below
      [[ "$base" == "commands" ]] && continue
      log "  WARNING:  harness/$name/$base — unexpected subdir (not handled by deploy)"
      continue
    fi

    # Skip operator-state files (defensive; these only ever exist in target)
    if is_operator_state_file "$base"; then
      skipped_state+=("$base")
      continue
    fi

    # config.toml — only-if-not-exists (operator-state preservation)
    if [[ "$base" == "config.toml" ]]; then
      if [[ -e "$target_dir/$base" ]]; then
        log "  PRESERVED: harness/$name/$base (target exists; operator customization preserved)"
        continue
      fi
      cp "$item" "$target_dir/$base" 2>/dev/null || copy_failures=true
      chmod 600 "$target_dir/$base" 2>/dev/null || true
      log "  Deployed: harness/$name/$base (initial deploy)"
      continue
    fi

    # *.sh, *.md → overwrite
    if cp "$item" "$target_dir/$base" 2>/dev/null; then
      # Preserve executable bit on .sh
      [[ "$base" == *.sh ]] && chmod +x "$target_dir/$base" 2>/dev/null || true
      if diff -q "$item" "$target_dir/$base" >/dev/null 2>&1; then
        log "  Deployed: harness/$name/$base"
      else
        log "  FAILED:   harness/$name/$base — verification failed"
        copy_failures=true
      fi
    else
      log "  FAILED:   harness/$name/$base — copy failed"
      copy_failures=true
    fi
  done

  # commands/*.md → ~/.claude/commands/
  if [[ -d "$source_dir/commands" ]]; then
    for cmd_item in "$source_dir/commands"/*.md; do
      [[ -f "$cmd_item" ]] || continue
      local cmd_base
      cmd_base=$(basename "$cmd_item")
      if cp "$cmd_item" "$commands_target/$cmd_base" 2>/dev/null; then
        if diff -q "$cmd_item" "$commands_target/$cmd_base" >/dev/null 2>&1; then
          log "  Deployed: commands/$cmd_base"
        else
          log "  FAILED:   commands/$cmd_base — verification failed"
          copy_failures=true
        fi
      else
        log "  FAILED:   commands/$cmd_base — copy failed"
        copy_failures=true
      fi
    done
  fi

  if [[ "$copy_failures" == "true" ]]; then
    FAILURES+=("harness/$name")
  fi

  if [[ ${#skipped_state[@]} -gt 0 ]]; then
    log "  PRESERVED: harness/$name operator-state files: ${skipped_state[*]}"
  fi
}

cmd_deploy() {
  # Deploy changed skills/packages/harness artifacts to Cowork install path.
  # E-02, E-03, E-08, E-11: Handles no-changes, deleted skills, invalid names, permissions.
  # Skill source paths resolve via resolve_skill_module(); packages live at
  # packages/ root; harness/ at v2 root (currently empty per the Phase 3
  # account-switcher extraction).
  validate_workspace
  # Resolve the Cowork install path non-fatally (detect_install_path returns 2 and
  # leaves INSTALL_PATH empty when no session resolves). A session-less machine is
  # a supported install case: the user-local ~/.claude/skills mirror still deploys.
  # See ADR-013.
  COWORK_AVAILABLE=false
  if detect_install_path && [[ -n "$INSTALL_PATH" ]]; then
    COWORK_AVAILABLE=true
  else
    log "Deploy mode: user-local only (no Cowork session) — Cowork-target writes and packages skipped."
  fi

  local -a FAILURES=()

  # Argument handling: manual vs auto-detect
  if [[ $# -gt 0 ]]; then
    # E-08: Validate manual artifact names; route each into skills or harness.
    # Module-aware lookup: iterate 3 module subtrees for skills; check harness/
    # at v2 repo root.
    local -a manual_skills=()
    local -a manual_harness=()
    for arg in "$@"; do
      local in_skills=false
      local in_harness=false
      local module_check
      for module_check in operations release core; do
        if [[ -d "$module_check/skills/$arg" ]]; then
          in_skills=true
          break
        fi
      done
      [[ -d "harness/$arg" ]] && in_harness=true
      if [[ "$in_skills" == "true" && "$in_harness" == "true" ]]; then
        die "Ambiguous artifact name: $arg (exists in both <module>/skills/ and harness/)"
      elif [[ "$in_skills" == "true" ]]; then
        manual_skills+=("$arg")
      elif [[ "$in_harness" == "true" ]]; then
        manual_harness+=("$arg")
      else
        die "Unknown artifact: $arg (not found in operations/skills/, release/skills/, core/skills/, or harness/)"
      fi
    done
    CHANGED_SKILLS=(${manual_skills[@]+"${manual_skills[@]}"})
    CHANGED_HARNESS=(${manual_harness[@]+"${manual_harness[@]}"})
    # Manual-mode deploy installs each named skill's same-named .skill package
    # alongside its source dir, so the documented §Initial-bootstrap command
    # satisfies the package-sync check (it previously hard-reset
    # CHANGED_PACKAGES=() and installed 0 packages). Reuse the shared
    # populate_full_roster_packages() helper, scoped to the named skills: it
    # appends each only when its package exists — the mandatory canary guard,
    # since the source-only pmo-skill-refiner-selftest-canary has no package, and
    # harness-only args append nothing. A partial `--deploy <one-skill>` thus
    # lands exactly that skill's package, not the whole roster. Guard the call on
    # a non-empty manual_skills: the helper treats zero args as "full package
    # set" (deliberately, for the fresh-install path below), so a manual deploy
    # of only harness-only artifacts (empty manual_skills) must NOT fall into
    # that no-arg full-roster branch — it gets exactly zero packages instead.
    if [[ ${#manual_skills[@]} -gt 0 ]]; then
      populate_full_roster_packages "${manual_skills[@]}"
    else
      CHANGED_PACKAGES=()
    fi
    DELETED_SKILLS=()
  else
    # A fresh clone whose install deployed nothing leaves the user-local skills
    # mirror empty. install.sh Phase 2 reaches here (orchestrate.sh runs
    # `deploy.sh --deploy` with NO args), and the tag-diff window is empty on a
    # clone sitting at the latest tag — so the incremental path would deploy 0
    # skills. When the mirror has no PMO-roster skill (or --all forced it),
    # deploy the FULL roster built from the per-module arrays + all packages
    # instead, so the documented `git clone && ./install.sh` path works
    # unattended. A populated mirror falls through to incremental tag-diff.
    if should_full_roster; then
      if [[ "${FORCE_ALL:-false}" == "true" ]]; then
        log "Full-roster deploy requested (--all) — deploying every skill + package."
      else
        log "Fresh install detected (user-local skills mirror empty) — deploying full roster."
      fi
      build_full_roster_skills
      CHANGED_SKILLS=(${FULL_ROSTER_SKILLS[@]+"${FULL_ROSTER_SKILLS[@]}"})
      CHANGED_HARNESS=()
      populate_full_roster_packages
      DELETED_SKILLS=()
    else
      detect_changed_skills
    fi
  fi

  # E-02: No changes case
  if [[ ${#CHANGED_SKILLS[@]} -eq 0 ]] && [[ ${#CHANGED_PACKAGES[@]} -eq 0 ]] && \
     [[ ${#CHANGED_HARNESS[@]} -eq 0 ]]; then
    log "No skill, package, or harness changes detected. Nothing to deploy."
    exit 0
  fi

  # Single-source-of-truth template handling: canonical templates are NOT
  # mirrored into source-tree. Instead they are injected directly into the
  # runtime skill references/ subtree AFTER the per-skill deploy
  # (deploy_skill + deploy_skill_user_local). See
  # sync_canonical_templates_to_runtime() docstring. Per-skill injection
  # runs inside the deploy loop below.

  # Deploy skills (source module resolved per skill via resolve_skill_module)
  for skill in ${CHANGED_SKILLS[@]+"${CHANGED_SKILLS[@]}"}; do
    local module
    module=$(resolve_skill_module "$skill")
    local source_dir="$module/skills/$skill"
    local source="$source_dir/SKILL.md"

    # Cowork-target writes (skill copy + verify, supplementary content, references
    # mirror) run only when a Cowork session resolved. Guarded behind
    # COWORK_AVAILABLE so a session-less machine skips them and still reaches the
    # unconditional user-local mirror below. See ADR-013.
    if [[ "$COWORK_AVAILABLE" == "true" ]]; then
      local target="$INSTALL_PATH/$skill/SKILL.md"

      # Create target directory if needed (new skill)
      mkdir -p "$INSTALL_PATH/$skill"

      if cp "$source" "$target" 2>/dev/null; then
        # Verify copy
        if diff -q "$source" "$target" >/dev/null 2>&1; then
          local hash
          hash=$(md5 -q "$source" 2>/dev/null | cut -c1-8) || hash="n/a"
          log "  Deployed: $skill ($hash)"
        else
          log "  FAILED:   $skill — verification failed after copy"
          FAILURES+=("$skill")
        fi
      else
        # E-11: Permission denied or other copy failure
        log "  FAILED:   $skill — copy failed (check permissions)"
        FAILURES+=("$skill")
      fi

      # Supplementary content (pmo-skill-refiner has agents/, scripts/, eval-viewer/, assets/, references/; prompt-builder has references/)
      if is_supplementary "$skill"; then
        local supp_failures=false
        for item in "$source_dir"/*; do
          local item_name
          item_name=$(basename "$item")
          [[ "$item_name" == "SKILL.md" ]] && continue  # Already deployed above
          if [[ -d "$item" ]]; then
            cp -R "$item" "$INSTALL_PATH/$skill/" 2>/dev/null || supp_failures=true
          elif [[ -f "$item" ]]; then
            cp "$item" "$INSTALL_PATH/$skill/" 2>/dev/null || supp_failures=true
          fi
        done
        if [[ "$supp_failures" == "true" ]]; then
          log "  WARNING:  $skill — some supplementary files failed to copy"
        else
          log "  Deployed: $skill supplementary content ($(ls -d "$source_dir"/*/ 2>/dev/null | wc -l | tr -d ' ') dirs)"
        fi
      fi

      # Mirror references/ from source tree to install path (non-supplementary
      # skills). Source tree is the canonical truth for references/
      # in both supplementary and non-supplementary deploys; the .skill package
      # is a distribution-only artifact. Matches supplementary-path semantics
      # (above) — single source-of-truth model.
      if ! is_supplementary "$skill"; then
        local source_refs="$source_dir/references"
        if [[ -d "$source_refs" ]]; then
          # Bounded-target guard (D5): refuse the rm -rf if the Cowork
          # base is empty or $skill contains ".." (path-escape). INSTALL_PATH is
          # the detect_install_path-resolved base (rebased on $DEPLOY_ROOT under
          # an override); this hardens both the sandboxed and live paths.
          if [[ -z "$INSTALL_PATH" || "$skill" == *..* ]]; then
            log "  FAILED:   $skill references/ — refusing rm -rf of unexpected target ($INSTALL_PATH/$skill/references)"
            FAILURES+=("$skill (references)")
          else
            if ! remove_mirror_subtree "$INSTALL_PATH/$skill/references" "$skill references/"; then
              FAILURES+=("$skill (references)")
            elif cp -R "$source_refs" "$INSTALL_PATH/$skill/" 2>/dev/null; then
              local ref_count
              ref_count=$(find "$INSTALL_PATH/$skill/references" -type f 2>/dev/null | wc -l | tr -d ' ')
              log "  Deployed: $skill references/ ($ref_count files from source)"
            else
              log "  FAILED:   $skill references/ — cp -R failed (target writable but copy failed; check disk/space/path)"
              FAILURES+=("$skill (references)")
            fi
          fi
        fi
      fi
    fi

    # User-local mirror: also expose this skill as plain /<name>. UNCONDITIONAL —
    # reads no session path; correct with or without a Cowork session.
    if ! deploy_skill_user_local "$skill"; then
      FAILURES+=("$skill (user-local)")
    fi

    # Inject canonical templates into runtime references/ at both
    # INSTALL_PATH and USER_LOCAL_SKILLS_PATH. Must run AFTER both
    # deploy_skill (above) and deploy_skill_user_local — those steps
    # cp -R source-tree references/ which now lacks per-skill template
    # mirrors (single-source-of-truth architecture). The injection
    # populates the runtime references/template-*.md per TEMPLATE_SYNC_MAP.
    if ! sync_canonical_templates_to_runtime "$skill"; then
      FAILURES+=("$skill (template-inject)")
    fi
  done

  # Deploy packages (packages/ at v2 root; no module nesting per the v2 root
  # layout). Packages install alongside the Cowork session (pkg_dir derives from
  # INSTALL_PATH), so this is a Cowork-target artifact — guarded behind
  # COWORK_AVAILABLE. Skipping packages with no Cowork session is correct.
  if [[ "$COWORK_AVAILABLE" == "true" ]]; then
    local pkg_dir
    pkg_dir="$(dirname "$INSTALL_PATH")/packages"
    for pkg in ${CHANGED_PACKAGES[@]+"${CHANGED_PACKAGES[@]}"}; do
      local source="packages/$pkg.skill"
      local target="$pkg_dir/$pkg.skill"

      mkdir -p "$pkg_dir"

      if cp "$source" "$target" 2>/dev/null; then
        if diff -q "$source" "$target" >/dev/null 2>&1; then
          log "  Deployed: $pkg.skill (package)"
        else
          log "  FAILED:   $pkg.skill — verification failed"
          FAILURES+=("$pkg.skill")
        fi
      else
        log "  FAILED:   $pkg.skill — copy failed"
        FAILURES+=("$pkg.skill")
      fi
    done
  fi

  # Deploy harness artifacts (HARNESS_LIST currently empty — Phase 3 account-
  # switcher extraction; this loop is a no-op until v2 ships new harness
  # artifacts at harness/<name>/). Harness targets ~/.claude/<name>/, not the
  # Cowork session path, so it stays unconditional.
  for harness_name in ${CHANGED_HARNESS[@]+"${CHANGED_HARNESS[@]}"}; do
    deploy_harness_artifact "$harness_name"
  done

  # E-03: Deleted skills warning (Cowork-target — the stale copy lives under the
  # session install path, so only warn when a Cowork session resolved).
  if [[ "$COWORK_AVAILABLE" == "true" ]]; then
    for skill in ${DELETED_SKILLS[@]+"${DELETED_SKILLS[@]}"}; do
      log "Warning: $skill was deleted from repo. Installed copy at $INSTALL_PATH/$skill/ remains. Manual cleanup recommended."
    done
  fi

  # Summary
  local pkg_count=${#CHANGED_PACKAGES[@]:-0}
  local harness_count=${#CHANGED_HARNESS[@]:-0}
  log "Deployed: ${#CHANGED_SKILLS[@]} skills, $pkg_count packages, $harness_count harness artifacts"
  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    die "Deployment failures: ${FAILURES[*]}"
  fi
}

# ─── Mode: --check ───────────────────────────────────────────────────────────

cmd_check() {
  # Validate platform health. Read-only.
  # R-07, R-11, E-06, E-12: Case-sensitive checks, mirror sync, strict/warn modes.
  validate_workspace
  # Non-fatal resolution (ADR-013): detect_install_path returns 2 on a session-less
  # machine; tolerate it so --check degrades gracefully. INSTALL_PATH-dependent
  # checks (8/12/13) already guard on its presence.
  detect_install_path || true

  # cmd_check is a read-only diagnostic: every failure path increments ISSUES or
  # calls flag_warn_or_issue, and the single intended exit point is the summary
  # gate below (STRICT → exit 1 on ISSUES>0; warn → exit 0). Disable errexit for
  # the check body so a benign non-zero from a command-substitution/pipeline whose
  # command legitimately no-matches or whose diff legitimately differs (e.g. the
  # Check-9 mirror-divergence preview, Check-26 model grep, Check-32 log grep)
  # cannot abort the run before that gate is reached. The preceding
  # validate_workspace/detect_install_path retain their own die/errexit semantics
  # (they ran above this point). Per-site `|| …` guards below add defense-in-depth.
  set +e

  local ISSUES=0

  # Check 1 — Skill sync (module-aware iteration over 4 per-module arrays).
  log "Check 1: Skill sync"
  for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}" "${CANARY_SKILLS[@]}"; do
    local module
    module=$(resolve_skill_module "$skill")
    local source="$module/skills/$skill/SKILL.md"
    local target="$INSTALL_PATH/$skill/SKILL.md"
    if [[ ! -f "$target" ]]; then
      log "  DRIFT: $skill — not installed"
      ISSUES=$((ISSUES + 1))
    elif ! diff -q "$source" "$target" >/dev/null 2>&1; then
      log "  DRIFT: $skill — installed copy differs from repo"
      ISSUES=$((ISSUES + 1))
    else
      log "  OK:    $skill"
    fi

    # Check references/ deployment (non-supplementary skills).
    # Compares source tree to install copy — source is canonical.
    # Excludes TEMPLATE_SYNC_MAP-injected files (template-*.md, requirements-
    # template.md, …): they are runtime-only artifacts injected by
    # sync_canonical_templates_to_runtime() and absent from source by single-
    # source-of-truth design, so an unfiltered diff -rq would report them as
    # "Only in installed" → a false DRIFT on every clean deploy. Their canonical
    # comparison is Check 13's job; Check 1 still fully diffs genuine source refs.
    if ! is_supplementary "$skill"; then
      local source_refs="$module/skills/$skill/references"
      if [[ -d "$source_refs" ]]; then
        local installed_refs_dir="$INSTALL_PATH/$skill/references"
        local -a c1_ref_excludes=()
        local _inj_base
        while IFS= read -r _inj_base; do
          [[ -n "$_inj_base" ]] && c1_ref_excludes+=("--exclude=$_inj_base")
        done < <(injected_ref_basenames "$skill")
        # AC-3 cause-classification: if the target exists but is read-only
        # (the Cowork session-churn orphan class), annotate the DRIFT line so
        # the cause is actionable (RO-perms vs. missing vs. differs).
        # Diagnostic-only — does not change ISSUES counts or exit codes.
        local _ro_annot=""
        [[ -e "$installed_refs_dir" && ! -w "$installed_refs_dir" ]] && _ro_annot=" (read-only — chmod -R u+w then redeploy)"
        if [[ ! -d "$installed_refs_dir" ]]; then
          log "  DRIFT: $skill — references/ not deployed (source has files)$_ro_annot"
          ISSUES=$((ISSUES + 1))
        elif ! diff -rq ${c1_ref_excludes[@]+"${c1_ref_excludes[@]}"} "$source_refs" "$installed_refs_dir" >/dev/null 2>&1; then
          log "  DRIFT: $skill — references/ installed copy differs from source$_ro_annot"
          ISSUES=$((ISSUES + 1))
        else
          local installed_refs
          installed_refs=$(find "$installed_refs_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
          log "  OK:    $skill references/ ($installed_refs files)"
        fi
      fi
    fi

    # Check supplementary content for skills that have it
    if is_supplementary "$skill" && [[ -d "$INSTALL_PATH/$skill" ]]; then
      local supp_drift=false
      local source_dir="$module/skills/$skill"
      for item in "$source_dir"/*; do
        local item_name
        item_name=$(basename "$item")
        [[ "$item_name" == "SKILL.md" ]] && continue
        if [[ -d "$item" ]]; then
          # Same TEMPLATE_SYNC_MAP exclusion as the non-supplementary branch, but
          # only for the references/ subdir — that is the one a supplementary skill
          # (e.g. pmo-skill-refiner) receives injected template-*.md into. Other
          # supplementary dirs (agents/, scripts/) take no injection, so no exclude.
          local -a c1_supp_excludes=()
          if [[ "$item_name" == "references" ]]; then
            local _supp_inj_base
            while IFS= read -r _supp_inj_base; do
              [[ -n "$_supp_inj_base" ]] && c1_supp_excludes+=("--exclude=$_supp_inj_base")
            done < <(injected_ref_basenames "$skill")
          fi
          if [[ ! -d "$INSTALL_PATH/$skill/$item_name" ]]; then
            log "  DRIFT: $skill/$item_name/ — not installed"
            ISSUES=$((ISSUES + 1))
            supp_drift=true
          elif ! diff -rq ${c1_supp_excludes[@]+"${c1_supp_excludes[@]}"} "$item" "$INSTALL_PATH/$skill/$item_name" >/dev/null 2>&1; then
            log "  DRIFT: $skill/$item_name/ — installed copy differs"
            ISSUES=$((ISSUES + 1))
            supp_drift=true
          fi
        elif [[ -f "$item" ]] && [[ ! -f "$INSTALL_PATH/$skill/$item_name" ]]; then
          log "  DRIFT: $skill/$item_name — not installed"
          ISSUES=$((ISSUES + 1))
          supp_drift=true
        fi
      done
      if [[ "$supp_drift" == "false" ]]; then
        log "  OK:    $skill supplementary content"
      fi
    fi
  done

  # Check 2 — Package sync (packages/ at v2 root; no module nesting)
  log "Check 2: Package sync"
  local pkg_dir
  pkg_dir="$(dirname "$INSTALL_PATH")/packages"
  for pkg_file in packages/*.skill; do
    [[ -f "$pkg_file" ]] || continue
    local pkg_name
    pkg_name=$(basename "$pkg_file")
    local target="$pkg_dir/$pkg_name"
    if [[ ! -f "$target" ]]; then
      log "  DRIFT: $pkg_name — not installed"
      ISSUES=$((ISSUES + 1))
    elif ! diff -q "$pkg_file" "$target" >/dev/null 2>&1; then
      log "  DRIFT: $pkg_name — installed copy differs"
      ISSUES=$((ISSUES + 1))
    else
      log "  OK:    $pkg_name"
    fi
  done

  # Check 3 — Duplicate detection (E-06: case-sensitive on APFS)
  # Legacy duplicate paths — operator-instance state, not v2 source.
  # Retained for operators upgrading workspaces from older layouts.
  log "Check 3: Duplicate detection"
  if find . -maxdepth 1 -name "Projects" -type d 2>/dev/null | grep -q .; then
    log "  DUPLICATE: Projects/ (uppercase) still exists alongside projects/"
    ISSUES=$((ISSUES + 1))
  else
    log "  OK:    No uppercase Projects/ directory"
  fi

  for f in PMO.md RELEASE_PROTOCOL.md; do
    if [[ -f "projects/_config/$f" ]]; then
      log "  DUPLICATE: projects/_config/$f (legacy operator-instance duplicate; canonical at release/governance/RELEASE_PROTOCOL.md)"
      ISSUES=$((ISSUES + 1))
    fi
  done

  if [[ -d "projects/Reference" ]]; then
    log "  DUPLICATE: projects/Reference/ still exists"
    ISSUES=$((ISSUES + 1))
  fi
  if [[ -d "projects/_Skill-Packages" ]]; then
    log "  DUPLICATE: projects/_Skill-Packages/ still exists"
    ISSUES=$((ISSUES + 1))
  fi

  # Check 4 — Governance presence.
  # RELEASE_LOG.md DROPPED — per Q1 + Spec Surface 5.2 it is operator-instance,
  # NOT in-repo governance (lives at $PMO_INSTANCE_PATH/RELEASE_LOG.md).
  log "Check 4: Governance presence"
  local -a EXPECTED_ENGINEERING=(
    core/governance/OPERATIONS.md
    release/governance/RELEASE_PROTOCOL.md
  )
  local -a EXPECTED_OPS=(
    projects/_config/PORTFOLIO.md
    projects/_config/SESSION_STATE.md
    projects/_config/CORRECTIONS.md
  )
  for f in "${EXPECTED_ENGINEERING[@]}" "${EXPECTED_OPS[@]}"; do
    if [[ -f "$f" ]]; then
      log "  OK:    $f"
    else
      log "  MISSING: $f"
      ISSUES=$((ISSUES + 1))
    fi
  done

  # Check 5 — Skill-roster drift detection (per the skill-roster discipline §1.2)
  # Asserts (a) every directory under <module>/skills/ is registered in one
  # of the per-module arrays, (b) every registered skill has a directory,
  # and (c) governance docs delegate to deploy.sh rather than embed hardcoded
  # counts. Iterates the 3 module skill subtrees plus per-module arrays.
  log "Check 5: Skill-roster drift"
  # Build expected roster from the 4 per-module arrays (deduped union;
  # bash 3.2 portable — no mapfile).
  local -a EXPECTED_ROSTER=()
  local _line
  while IFS= read -r _line; do
    EXPECTED_ROSTER+=("$_line")
  done < <(printf '%s\n' \
    "${OPERATIONS_SKILLS[@]}" \
    "${RELEASE_SKILLS[@]}" \
    "${CORE_SKILLS[@]}" \
    "${CANARY_SKILLS[@]}" | sort -u)

  # (a) Every directory must be in the roster (iterate all 3 module subtrees)
  local _module_dir
  for _module_dir in operations release core; do
    for skill_dir in "$_module_dir"/skills/*/; do
      [[ -d "$skill_dir" ]] || continue
      local skill_name
      skill_name=$(basename "$skill_dir")
      # Non-skill shared-resource directories under skills/ are not roster
      # members. Convention: an underscore-prefixed directory under
      # <module>/skills/ holds shared reference content consumed by the
      # sibling role skills, not a deployable skill (no SKILL.md, no package,
      # no deploy.sh array entry). It carries no roster membership and must be
      # skipped before the roster lookup. EXACT-MATCH allowlist (fail-CLOSED):
      # only the explicitly-named "_shared" dir is exempt — a stray
      # underscore-prefixed directory still FAILs roster-drift. To add another
      # non-skill shared-resource dir, extend this allowlist explicitly here.
      [[ "$skill_name" == "_shared" ]] && continue
      local found=false
      for s in "${EXPECTED_ROSTER[@]}"; do
        [[ "$skill_name" == "$s" ]] && found=true && break
      done
      if [[ "$found" == "false" ]]; then
        log "  FAIL:  skill-roster drift detected — $_module_dir/skills/$skill_name/ exists but not in any per-module array. Add to OPERATIONS_SKILLS / RELEASE_SKILLS / CORE_SKILLS / CANARY_SKILLS in deploy.sh, or remove the directory."
        ISSUES=$((ISSUES + 1))
      fi
    done
  done

  # (b) Every registered skill must have a directory (module resolved via helper)
  for s in "${EXPECTED_ROSTER[@]}"; do
    local _exp_module
    _exp_module=$(resolve_skill_module "$s")
    if [[ ! -d "$_exp_module/skills/$s" ]]; then
      log "  FAIL:  skill-roster drift detected — '$s' is in per-module array but $_exp_module/skills/$s/ does not exist. Create the directory or remove from deploy.sh."
      ISSUES=$((ISSUES + 1))
    fi
  done

  # (c) Governance docs must not embed hardcoded skill counts.
  # The engineering/rules mirror was DROPPED per the layout §8.3 (workspace
  # `.claude/rules/` is the only mirror now).
  local -a COUNT_TARGETS=(
    core/rules/skill-deployment.md
    core/disciplines/architecture-overview.md
    core/CLAUDE.md.template
  )
  for target in "${COUNT_TARGETS[@]}"; do
    [[ -f "$target" ]] || continue
    # Pattern: digit-pair (19|20|21|22) followed by space + (custom|skills|dirs)
    local matches
    matches=$(grep -nE '\b(19|20|21|22) (custom|skills|dirs)\b' "$target" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      log "  FAIL:  hardcoded skill count detected in $target — delegate to deploy.sh per-module arrays (OPERATIONS_SKILLS / RELEASE_SKILLS / CORE_SKILLS) per the Single Source rule. Matches:"
      while IFS= read -r m; do
        [[ -n "$m" ]] && log "         $m"
      done <<< "$matches"
      ISSUES=$((ISSUES + 1))
    fi
  done

  # If all sub-assertions clean, log a single OK
  local roster_ok=true
  for s in "${EXPECTED_ROSTER[@]}"; do
    local _ok_module
    _ok_module=$(resolve_skill_module "$s")
    [[ -d "$_ok_module/skills/$s" ]] || roster_ok=false
  done
  if [[ "$roster_ok" == "true" ]]; then
    log "  OK:    skill roster matches per-module arrays (${#EXPECTED_ROSTER[@]} skills across operations/release/core/canary)"
  fi

  # ─── Checks 6-10: Skill Discipline enforcement ─────────
  #
  # Numbering note: Check 5 (skill-roster drift) added earlier. To avoid
  # collision, the five skill-discipline checks are numbered 6-10 per
  # the renumber-cleanly decision (rather than collide with merged work).
  #
  # Warn-mode split (per the shakedown decision S5):
  #   - Checks 6-7: always-enforce (structural; zero-FP profile)
  #   - Checks 8-10: warn/enforce/off via core/hooks/deploy-check.mode
  #     (default "warn" for initial shakedown per core/rules/bypass-mode-
  #     readiness.md)
  # EXEMPTION_LIST adapts to an operator-instance path-via-env-var per
  # Spec Surface 5.2 (C) — defaults to operator-instance path; falls back to
  # legacy .claude/ location for compatibility.
  local EXEMPTION_LIST="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/skill-editor-exemption-list.txt"
  [[ -f "$EXEMPTION_LIST" ]] || EXEMPTION_LIST=".claude/skill-editor-exemption-list.txt"

  # Check 6 — Canonical-structure compliance (always-enforce; per skill-discipline §2)
  # D-Refs threshold (per the D-Refs Option B decision): references/ required when
  #   SKILL.md > 400 lines OR > 25 KB.
  # Also enforces required frontmatter fields + failure-mode floor (≥3).
  # Module-aware iteration via per-module arrays + resolve_skill_module().
  log "Check 6: Canonical-structure compliance"
  for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}"; do
    local c6_module
    c6_module=$(resolve_skill_module "$skill")
    local c6_src="$c6_module/skills/$skill/SKILL.md"
    if [[ ! -f "$c6_src" ]]; then
      log "  FAIL:  $skill — SKILL.md missing"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    local c6_skill_ok=true

    # Required frontmatter fields (presence)
    for field in name description version; do
      if ! grep -qE "^${field}:" "$c6_src"; then
        log "  FAIL:  $skill — missing required frontmatter field '$field'"
        ISSUES=$((ISSUES + 1))
        c6_skill_ok=false
      fi
    done

    # Exemption pass-through (canary-by-design)
    if [[ -f "$EXEMPTION_LIST" ]] && grep -Fxq "$skill" "$EXEMPTION_LIST" 2>/dev/null; then
      [[ "$c6_skill_ok" == "true" ]] && log "  OK:    $skill (exempted from threshold)"
      continue
    fi

    # D-Refs threshold evaluation
    local c6_lines c6_bytes c6_fm_count
    c6_lines=$(wc -l < "$c6_src" | tr -d ' ')
    c6_bytes=$(wc -c < "$c6_src" | tr -d ' ')
    c6_fm_count=$(grep -cE '^### .+ — (TRIG|INPUT|PROC|OUT|HAND)[[:space:]]*$' "$c6_src" || true)

    local c6_refs_required=false
    [[ $c6_lines -gt 400 ]] && c6_refs_required=true
    [[ $c6_bytes -gt 25600 ]] && c6_refs_required=true

    if [[ "$c6_refs_required" == "true" ]]; then
      local c6_ref_dir="$c6_module/skills/$skill/references"
      if [[ ! -d "$c6_ref_dir" ]] || [[ -z "$(find "$c6_ref_dir" -name '*.md' -type f 2>/dev/null | head -1)" ]]; then
        log "  FAIL:  $skill — D-Refs threshold crossed (lines=$c6_lines bytes=$c6_bytes fm=$c6_fm_count); references/ subdir missing or empty"
        ISSUES=$((ISSUES + 1))
        c6_skill_ok=false
      fi
    fi

    # Failure-mode floor (per core/standards/failure-mode-standard.md + pmo-qa-auditor G7)
    if [[ $c6_fm_count -lt 3 ]]; then
      log "  FAIL:  $skill — ## Domain-Specific Failure Modes has $c6_fm_count entries (< 3 floor per failure-mode-standard.md)"
      ISSUES=$((ISSUES + 1))
      c6_skill_ok=false
    fi

    [[ "$c6_skill_ok" == "true" ]] && log "  OK:    $skill"
  done

  # Check 7 — Package-freshness (always-enforce; per the package-freshness spec Part A)
  # Asserts every per-module skill has a .skill package at packages/ root and
  # the package is not older than any source file under the skill directory.
  log "Check 7: Package freshness"
  for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}"; do
    local c7_module
    c7_module=$(resolve_skill_module "$skill")
    local c7_src_dir="$c7_module/skills/$skill"
    local c7_pkg="packages/${skill}.skill"

    if [[ ! -f "$c7_pkg" ]]; then
      log "  FAIL:  $skill — .skill package missing"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    # BSD stat -f '%m' (macOS native)
    local c7_newest_src c7_pkg_mtime
    c7_newest_src=$(find "$c7_src_dir" -type f -not -path '*/.*' -exec stat -f '%m' {} \; 2>/dev/null | sort -n | tail -1)
    c7_pkg_mtime=$(stat -f '%m' "$c7_pkg" 2>/dev/null)

    if [[ -n "$c7_newest_src" && -n "$c7_pkg_mtime" && "$c7_newest_src" -gt "$c7_pkg_mtime" ]]; then
      log "  FAIL:  $skill — source newer than package (rebuild via python3 -m scripts.package_skill)"
      ISSUES=$((ISSUES + 1))
    else
      log "  OK:    $skill"
    fi
  done

  # Warn-mode gate for Checks 8-10 (and downstream warn-mode checks).
  # MODE_FILE adapts to an operator-instance path-via-env-var per Spec
  # Surface 5.2 (C); falls back to legacy .claude/ location for compatibility.
  local DEPLOY_CHECK_MODE="warn"
  local MODE_FILE="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/deploy-check.mode"
  [[ -f "$MODE_FILE" ]] || MODE_FILE=".claude/hooks/deploy-check.mode"
  if [[ -f "$MODE_FILE" ]]; then
    local _mode
    _mode=$(cat "$MODE_FILE" 2>/dev/null | tr -d '[:space:]')
    case "$_mode" in
      enforce|warn|off) DEPLOY_CHECK_MODE="$_mode" ;;
    esac
  fi
  local WARN_LOG="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/deploy-check-warn-log.jsonl"

  # flag_warn_or_issue — Checks 8-10 helper. In enforce-mode, acts like a normal
  # FAIL (increments ISSUES). In warn-mode, logs a WARN + appends to jsonl but
  # does NOT increment ISSUES (enabling shakedown without false-positive breaks).
  flag_warn_or_issue() {
    local check_id="$1"
    local detail="$2"
    case "$DEPLOY_CHECK_MODE" in
      enforce)
        log "  FAIL:  $check_id — $detail"
        ISSUES=$((ISSUES + 1))
        ;;
      warn)
        log "  WARN:  $check_id — $detail (warn-mode; flip .claude/hooks/deploy-check.mode to 'enforce' after shakedown)"
        local _ts
        _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        local _detail_escaped="${detail//\\/\\\\}"
        _detail_escaped="${_detail_escaped//\"/\\\"}"
        printf '{"ts":"%s","check":"%s","detail":"%s"}\n' "$_ts" "$check_id" "$_detail_escaped" >> "$WARN_LOG" 2>/dev/null || true
        ;;
    esac
  }

  # Check 8 — Canonical-session-path freshness (warn-mode initial)
  # Rules file at core/rules/skill-deployment.md (no engineering/rules
  # mirror — collapsed per the layout §8.3).
  #
  # Source of truth re-pointed (ADR-013): validate the detected INSTALL_PATH
  # against the operator.toml [paths].cowork_install_path base — the authoritative
  # session base captured at clean install — NOT a literal UUID grepped from
  # skill-deployment.md. The doc is fully tokenized ([SESSION_UUID]), so the prior
  # doc-grep was permanently inert (and its bare command-substitution assignment
  # tripped `set -e`); the config base is the real canonical source. Config absent
  # → SKIP (absence of an optional override is not drift, so it does not WARN).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 8: Canonical-session-path freshness"
    if [[ -n "$INSTALL_PATH" ]]; then
      local c8_cfg_root="${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}"
      local c8_cowork_base=""
      if [[ -r "${c8_cfg_root}/operator.toml" ]]; then
        c8_cowork_base="$(grep -E '^[[:space:]]*cowork_install_path[[:space:]]*=' "${c8_cfg_root}/operator.toml" 2>/dev/null \
          | head -1 | sed -E -e 's/.*=[[:space:]]*"([^"]*)".*/\1/' -e t -e 's/.*=[[:space:]]*([^#]*).*/\1/' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)"
      fi
      if [[ -z "$c8_cowork_base" ]]; then
        log "  SKIP:  cowork_install_path not configured (operator.toml [paths]) — no canonical base to validate against"
      elif [[ "$INSTALL_PATH" == "$c8_cowork_base"/* ]]; then
        log "  OK:    detected session path is under the configured cowork_install_path base"
      else
        flag_warn_or_issue "canonical-session-path" \
          "detected ($INSTALL_PATH) is not under the configured cowork_install_path base ($c8_cowork_base)"
      fi
    else
      log "  SKIP:  INSTALL_PATH not available (no Cowork session resolved)"
    fi
  fi

  # Check 9 — Mirror-pair sync (warn-mode initial)
  #
  # Semantics per Spec Surface 5.4 + ADR-008 Consequence 2:
  #   in-repo source `core/rules/<file>.md` OR `release/rules/release-process.md`
  #   ↔ workspace mirror `~/.claude/rules/<file>.md`
  #   (source-mirrors-to-workspace; uni-directional)
  #
  # The engineering/rules mirror was DROPPED per the layout §8.3. Drift means
  # "workspace mirror diverged from v2 source; re-run ./deploy.sh --deploy to
  # restore". The pair set covers all 8 files under .claude/rules/ (including
  # git-workflow.md and governance-files.md surfaced by the Stage 5 spec).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 9: Mirror-pair sync (source-to-workspace)"
    local -a MIRROR_PAIRS=(
      "core/rules/skill-deployment.md:$DEPLOY_ROOT/.claude/rules/skill-deployment.md"
      "core/rules/bypass-mode-readiness.md:$DEPLOY_ROOT/.claude/rules/bypass-mode-readiness.md"
      "core/rules/harness-deployment.md:$DEPLOY_ROOT/.claude/rules/harness-deployment.md"
      "core/rules/doc-link-maintenance.md:$DEPLOY_ROOT/.claude/rules/doc-link-maintenance.md"
      "core/rules/operations-bridge.md:$DEPLOY_ROOT/.claude/rules/operations-bridge.md"
      "core/rules/git-workflow.md:$DEPLOY_ROOT/.claude/rules/git-workflow.md"
      "core/rules/governance-files.md:$DEPLOY_ROOT/.claude/rules/governance-files.md"
      "release/rules/release-process.md:$DEPLOY_ROOT/.claude/rules/release-process.md"
      "core/governance/OPERATIONS.md:operations/OPERATIONS.md"
    )
    for pair in "${MIRROR_PAIRS[@]}"; do
      local c9_left="${pair%%:*}"
      local c9_right="${pair##*:}"
      if [[ ! -f "$c9_left" ]] || [[ ! -f "$c9_right" ]]; then
        log "  SKIP:  $c9_left ↔ $c9_right (one or both missing)"
        continue
      fi
      # The OPERATIONS.md dual-write pair lives at two repo depths
      # (core/governance/ vs operations/), so its markdown link targets carry
      # depth-adjusted relative prefixes that resolve correctly from each
      # location. Compare that pair MODULO link-target paths — real content
      # drift still flags; benign per-depth prefixes do not. All other
      # (workspace-deployed) mirrors are copied verbatim and stay byte-for-byte.
      if [[ "$c9_left" == *OPERATIONS.md ]]; then
        local c9_norm='s#(\]\()[^)]*(\))#\1LINK\2#g'
        if diff -q <(sed -E "$c9_norm" "$c9_left") <(sed -E "$c9_norm" "$c9_right") >/dev/null 2>&1; then
          log "  OK:    $c9_left ↔ $c9_right (content-identical; links depth-adjusted per location)"
        else
          flag_warn_or_issue "mirror-sync" "$c9_left ↔ $c9_right content divergence (beyond link depth)"
          diff -u <(sed -E "$c9_norm" "$c9_left") <(sed -E "$c9_norm" "$c9_right") 2>/dev/null | head -20 | sed 's/^/         /' || true
        fi
        continue
      fi
      if diff -q "$c9_left" "$c9_right" >/dev/null 2>&1; then
        log "  OK:    $c9_left ↔ $c9_right (byte-identical)"
      else
        flag_warn_or_issue "mirror-sync" "$c9_left ↔ $c9_right divergence"
        # `diff` exits 1 on divergence (the path we are in); guard the preview
        # pipeline so it cannot abort the check sweep under set -e + pipefail.
        diff -u "$c9_left" "$c9_right" 2>/dev/null | head -20 | sed 's/^/         /' || true
      fi
    done
  fi

  # Check 10 — Editor audit-trail (per the D-Editor dual-gate; warn-mode initial)
  # For migrated skills only: last non-merge commit touching SKILL.md must
  # carry a 'Skill-Editor-Audit-Trail:' trailer. Pre-migration skills and
  # exempted skills pass through cleanly (non-breaking on legacy).
  # Module-aware iteration via per-module arrays + resolve_skill_module().
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 10: Editor audit-trail (migrated skills only)"
    local c10_any_checked=false
    for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}"; do
      local c10_module
      c10_module=$(resolve_skill_module "$skill")
      local c10_src="$c10_module/skills/$skill/SKILL.md"
      [[ -f "$c10_src" ]] || continue

      # Gate activates only post-migration
      if ! grep -qE '^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$' "$c10_src" 2>/dev/null; then
        continue
      fi

      # Exemption pass-through
      if [[ -f "$EXEMPTION_LIST" ]] && grep -Fxq "$skill" "$EXEMPTION_LIST" 2>/dev/null; then
        continue
      fi

      c10_any_checked=true

      local c10_last_commit
      c10_last_commit=$(git log -1 --no-merges --format='%H' -- "$c10_src" 2>/dev/null)
      [[ -z "$c10_last_commit" ]] && continue

      local c10_trailer
      c10_trailer=$(git log -1 --format='%B' "$c10_last_commit" -- "$c10_src" 2>/dev/null \
        | grep -E '^Skill-Editor-Audit-Trail:' || true)

      if [[ -z "$c10_trailer" ]]; then
        flag_warn_or_issue "editor-audit-trail" "$skill — last commit ${c10_last_commit:0:12} missing 'Skill-Editor-Audit-Trail:' trailer"
      else
        log "  OK:    $skill (${c10_last_commit:0:12})"
      fi
    done
    if [[ "$c10_any_checked" == "false" ]]; then
      log "  SKIP:  no migrated skills yet (gate activates per-skill via migration commits)"
    fi
  fi

  # Check 11 — Harness sync (always-enforce; per the D-1.B migration)
  # For each artifact in HARNESS_LIST: source files (excluding config.toml
  # template + HARNESS_OPERATOR_STATE allowlist) match runtime byte-identically.
  # Slash commands at source/commands/*.md must match ~/.claude/commands/*.md.
  # HARNESS_LIST is currently empty (account-switcher extracts at Phase 3);
  # explicit empty-array guard per ADR-008 Rule 2 + Spec Surface 3 SKIP logging.
  log "Check 11: Harness sync"
  if [[ ${#HARNESS_LIST[@]} -eq 0 ]]; then
    log "  SKIP:  no harness artifacts in scope (HARNESS_LIST empty per Phase 3 account-switcher extraction)"
  else
    for harness_name in "${HARNESS_LIST[@]}"; do
      local c11_src_dir="harness/$harness_name"
      local c11_tgt_dir="$DEPLOY_ROOT/.claude/$harness_name"
      local c11_cmds_dir="$DEPLOY_ROOT/.claude/commands"

      if [[ ! -d "$c11_src_dir" ]]; then
        log "  FAIL:  harness/$harness_name — source directory missing in repo"
        ISSUES=$((ISSUES + 1))
        continue
      fi

      if [[ ! -d "$c11_tgt_dir" ]]; then
        log "  DRIFT: harness/$harness_name — runtime directory missing (run ./deploy.sh --deploy $harness_name)"
        ISSUES=$((ISSUES + 1))
        continue
      fi

      local c11_drift=false
      local c11_item c11_base
      for c11_item in "$c11_src_dir"/*; do
        [[ -e "$c11_item" ]] || continue
        c11_base=$(basename "$c11_item")

        # Skip subdirs (commands/ handled separately)
        if [[ -d "$c11_item" ]]; then
          [[ "$c11_base" == "commands" ]] && continue
          # Other unexpected subdirs surface as drift
          log "  WARN:  harness/$harness_name/$c11_base — unexpected subdir in source (not validated)"
          continue
        fi

        # config.toml is a template; runtime instance is operator-customized.
        # Skip byte-comparison; presence-only check.
        if [[ "$c11_base" == "config.toml" ]]; then
          if [[ ! -f "$c11_tgt_dir/$c11_base" ]]; then
            log "  DRIFT: harness/$harness_name/$c11_base — runtime missing (initial deploy needed)"
            ISSUES=$((ISSUES + 1))
            c11_drift=true
          fi
          continue
        fi

        # Operator-state files live only at runtime; source has none.
        is_operator_state_file "$c11_base" && continue

        # Byte-identical comparison for *.sh, *.md, etc.
        if [[ ! -f "$c11_tgt_dir/$c11_base" ]]; then
          log "  DRIFT: harness/$harness_name/$c11_base — runtime missing"
          ISSUES=$((ISSUES + 1))
          c11_drift=true
        elif ! diff -q "$c11_item" "$c11_tgt_dir/$c11_base" >/dev/null 2>&1; then
          log "  DRIFT: harness/$harness_name/$c11_base — runtime differs from source"
          ISSUES=$((ISSUES + 1))
          c11_drift=true
        fi
      done

      # Slash commands
      if [[ -d "$c11_src_dir/commands" ]]; then
        for c11_cmd in "$c11_src_dir/commands"/*.md; do
          [[ -f "$c11_cmd" ]] || continue
          local c11_cmd_base
          c11_cmd_base=$(basename "$c11_cmd")
          if [[ ! -f "$c11_cmds_dir/$c11_cmd_base" ]]; then
            log "  DRIFT: commands/$c11_cmd_base — runtime missing (source: harness/$harness_name)"
            ISSUES=$((ISSUES + 1))
            c11_drift=true
          elif ! diff -q "$c11_cmd" "$c11_cmds_dir/$c11_cmd_base" >/dev/null 2>&1; then
            log "  DRIFT: commands/$c11_cmd_base — runtime differs from source (harness/$harness_name)"
            ISSUES=$((ISSUES + 1))
            c11_drift=true
          fi
        done
      fi

      [[ "$c11_drift" == "false" ]] && log "  OK:    harness/$harness_name"
    done
  fi

  # ─── Check 12: User-local skills mirror sync ───────────────────────
  # Asserts every entry in the per-module skill arrays has a runtime mirror at
  # $USER_LOCAL_SKILLS_PATH/<name>/SKILL.md that matches the in-module source.
  # Always-enforce (matches Check 1 posture for the Cowork target). Target
  # path stays FLAT per Phase 0.5 Q2 default — module-aware source via
  # resolve_skill_module().
  log "Check 12: User-local skills mirror sync"
  local -a c12_roster
  c12_roster=()
  while IFS= read -r entry; do
    c12_roster+=("$entry")
  done < <(printf '%s\n' \
    "${OPERATIONS_SKILLS[@]}" \
    "${RELEASE_SKILLS[@]}" \
    "${CORE_SKILLS[@]}" | sort -u)

  for c12_skill in "${c12_roster[@]}"; do
    local c12_module
    c12_module=$(resolve_skill_module "$c12_skill")
    local c12_src="$c12_module/skills/$c12_skill/SKILL.md"
    local c12_tgt="$USER_LOCAL_SKILLS_PATH/$c12_skill/SKILL.md"

    if [[ ! -f "$c12_src" ]]; then
      log "  FAIL:  $c12_skill — source SKILL.md missing"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    if [[ ! -f "$c12_tgt" ]]; then
      log "  DRIFT: $c12_skill — user-local mirror missing (run ./deploy.sh --deploy $c12_skill)"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    if diff -q "$c12_src" "$c12_tgt" >/dev/null 2>&1; then
      log "  OK:    $c12_skill"
    else
      log "  DRIFT: $c12_skill — user-local mirror differs from source"
      ISSUES=$((ISSUES + 1))
    fi
  done

  # ─── Check 13: Template-injection drift detection ─────────────────────────
  # Asserts every entry in TEMPLATE_SYNC_MAP has a source canonical AND a
  # byte-identical injected copy at the RUNTIME target paths (Cowork install
  # AND user-local mirror). Single-source-of-truth architecture: source tree
  # does NOT carry per-skill mirrors; canonicals are injected at deploy time
  # by sync_canonical_templates_to_runtime() and at package build time by
  # core/deploy/tools/build-skill-packages.sh.
  #
  # Verification posture: if the skill's runtime install directory doesn't
  # exist yet (deploy never run for that skill at this path), skip the
  # verification for that target — Check 12 separately verifies skill
  # presence. We don't double-fail on "deploy not yet run". Always-enforce
  # otherwise; failure remediation: ./deploy.sh --deploy <skill>.
  log "Check 13: Template-injection drift detection"
  local c13_drift=false
  for entry in "${TEMPLATE_SYNC_MAP[@]}"; do
    local c13_skill="${entry%%:*}"
    local c13_rest="${entry#*:}"
    local c13_canonical_name="${c13_rest%%:*}"
    local c13_target_rel="${c13_rest#*:}"
    local c13_source
    c13_source=$(resolve_template_sync_source "$c13_canonical_name")
    local c13_install="$INSTALL_PATH/$c13_skill/$c13_target_rel"
    local c13_user="$USER_LOCAL_SKILLS_PATH/$c13_skill/$c13_target_rel"

    if [[ ! -f "$c13_source" ]]; then
      log "  FAIL:  $c13_canonical_name — canonical missing from registry"
      ISSUES=$((ISSUES + 1))
      c13_drift=true
      continue
    fi

    # Cowork install verification
    if [[ -d "$INSTALL_PATH/$c13_skill" ]]; then
      if [[ ! -f "$c13_install" ]]; then
        log "  DRIFT: $c13_skill/$c13_target_rel missing at INSTALL_PATH — run ./deploy.sh --deploy $c13_skill"
        ISSUES=$((ISSUES + 1))
        c13_drift=true
      elif ! diff -q "$c13_source" "$c13_install" >/dev/null 2>&1; then
        log "  DRIFT: $c13_skill/$c13_target_rel differs from canonical at INSTALL_PATH — run ./deploy.sh --deploy $c13_skill"
        ISSUES=$((ISSUES + 1))
        c13_drift=true
      fi
    fi

    # User-local mirror verification
    if [[ -d "$USER_LOCAL_SKILLS_PATH/$c13_skill" ]]; then
      if [[ ! -f "$c13_user" ]]; then
        log "  DRIFT: $c13_skill/$c13_target_rel missing at USER_LOCAL — run ./deploy.sh --deploy $c13_skill"
        ISSUES=$((ISSUES + 1))
        c13_drift=true
      elif ! diff -q "$c13_source" "$c13_user" >/dev/null 2>&1; then
        log "  DRIFT: $c13_skill/$c13_target_rel differs from canonical at USER_LOCAL — run ./deploy.sh --deploy $c13_skill"
        ISSUES=$((ISSUES + 1))
        c13_drift=true
      fi
    fi
  done
  [[ "$c13_drift" == "false" ]] && log "  OK:    all ${#TEMPLATE_SYNC_MAP[@]} template-injection entries match canonical (at deployed targets)"

  # ─── Check 13b: Shared-reference collision detector (warn-mode initial) ───
  # Closes the "unregistered shared reference" failure mode at its root (#316):
  # Check 13 only sees REGISTERED files; an unregistered reference basename
  # carried by 2+ skills (the original output-format.md gap) is invisible to it.
  # Check 13b enumerates every reference basename under {operations,release,
  # core}/skills/*/references/ and, for any basename carried by 2+ skills that
  # does NOT resolve to a registered TEMPLATE_SYNC_MAP canonical, flags BOTH
  # prongs:
  #   (a) byte-IDENTICAL across the copies   → unregistered duplicated source;
  #       should be single-sourced + registered (the output-format.md pattern).
  #   (b) DIVERGENT (same basename, content differs) → silent content drift
  #       between copies that share a name; either intentionally per-skill
  #       (e.g. README.md — 4 distinct copies) or an unnoticed divergence.
  # Registered basenames are exempt: their mirrors are runtime-injected (deleted
  # from source by single-source design) and their byte-identity-vs-canonical is
  # Check 13's job. Warn-mode initial via flag_warn_or_issue / deploy-check.mode
  # (per bypass-mode-readiness.md shakedown precedent); the divergent prong has a
  # known per-skill README.md signal during shakedown — review the warn-log and
  # add an allowlist entry (or single-source) before flip-to-enforce. Flip path:
  # template-storage.md §3.5 + core/rules/skill-deployment.md.
  log "Check 13b: Shared-reference collision detection"

  # Registered-basename predicate: is this basename the canonical-filename of
  # any TEMPLATE_SYNC_MAP entry? (Reuses the entry parse from Check 13.)
  c13b_is_registered() {
    local want="$1" entry e_rest e_canon
    for entry in "${TEMPLATE_SYNC_MAP[@]}"; do
      e_rest="${entry#*:}"
      e_canon="${e_rest%%:*}"
      [[ "$e_canon" == "$want" ]] && return 0
    done
    return 1
  }

  local c13b_collision=false
  local c13b_basenames
  # Distinct basenames carried by 2+ skill references/ trees (source only).
  c13b_basenames=$(find operations release core -path '*/skills/*/references/*' -type f 2>/dev/null \
    | xargs -n1 basename 2>/dev/null | sort | uniq -d)

  local c13b_b
  while IFS= read -r c13b_b; do
    [[ -z "$c13b_b" ]] && continue
    # Registered shared files are single-sourced — Check 13 owns them; skip.
    if c13b_is_registered "$c13b_b"; then
      continue
    fi
    # Collect every source copy of this basename + its md5.
    local c13b_paths c13b_distinct_md5 c13b_copies
    c13b_paths=$(find operations release core -path '*/skills/*/references/*' -type f -name "$c13b_b" 2>/dev/null | sort)
    c13b_copies=$(printf '%s\n' "$c13b_paths" | grep -c .)
    [[ "$c13b_copies" -lt 2 ]] && continue
    c13b_distinct_md5=$(printf '%s\n' "$c13b_paths" | xargs md5 2>/dev/null | awk '{print $NF}' | sort -u | grep -c .)
    c13b_collision=true
    if [[ "$c13b_distinct_md5" -eq 1 ]]; then
      # Prong (a): byte-identical unregistered duplicate.
      flag_warn_or_issue "shared-reference-collision" \
        "basename '$c13b_b' is carried byte-identical by $c13b_copies skills but is NOT registered in TEMPLATE_SYNC_MAP — single-source it to core/standards/ (or operations/templates/) + register (see template-storage.md §6). Copies: $(printf '%s ' $c13b_paths)"
    else
      # Prong (b): divergent same-basename across skills.
      flag_warn_or_issue "shared-reference-divergence" \
        "basename '$c13b_b' is carried by $c13b_copies skills with $c13b_distinct_md5 distinct contents (divergent same-basename) — either intentionally per-skill (allowlist) or an unnoticed drift; reconcile + single-source, or document as per-skill. Copies: $(printf '%s ' $c13b_paths)"
    fi
  done <<< "$c13b_basenames"

  [[ "$c13b_collision" == "false" ]] && log "  OK:    no unregistered shared-reference collisions (all multi-skill basenames are registered or single-copy)"

  # ─── Check 14: Doc-link maintenance — governance + skill SKILL.md scope ───
  # Per Collective Review CR-D1 / CR-D2.
  # Invokes the shared primitive at core/deploy/tools/check-doc-links.py over
  # the disjoint governance + skill SKILL.md surface. Warn-mode initial per
  # core/rules/bypass-mode-readiness.md shakedown precedent; flip-to-enforce
  # timeline codified in core/standards/doc-link-maintenance-protocol.md.
  # Target-paths are a module-prefixed comma-joined string covering all 3
  # modules + cross-cutting surfaces per Spec Surface 5.2.
  # The tool carries a module-aware prefix table (V1_PREFIXES + V2_PREFIXES) —
  # bare v2 module refs (e.g., release/ from core/) resolve via workspace-root
  # fallback instead of false-positive relative resolution. The tool also has a
  # --from-path/--to-path EMIT-ONLY rewrite-map mode for per-edit discipline
  # workflows. Check 15 (release-corpus) RETIRED in v2 per FX-Check15 — see
  # citation block below Check 14.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 14: Doc-link maintenance (governance + skill SKILL.md scope)"
    local c14_script="core/deploy/tools/check-doc-links.py"
    local c14_allowlist="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/skip-doc-link-check.txt"
    [[ -f "$c14_allowlist" ]] || c14_allowlist=".claude/skip-doc-link-check.txt"
    if [[ ! -f "$c14_script" ]]; then
      flag_warn_or_issue "doc-link-maintenance" "primitive script missing: $c14_script"
    elif [[ ! -x "/usr/bin/python3" ]]; then
      flag_warn_or_issue "doc-link-maintenance" "/usr/bin/python3 not executable; cannot run primitive"
    else
      local c14_output c14_exit=0
      # --require-targets (per #459): a declared --target-paths glob resolving to
      # zero files is a path-resolution failure (exit 3), not a clean pass — so a
      # relocated/typo'd scan surface can never read GREEN.
      # Target globs match the post-restructure live layout (per #459 follow-up):
      # release specs/standards live under release/references/ (recursively
      # covered by the release/references/ entry, which also covers the release
      # schema files under references/standards/); release has no rules surface
      # (rules are core-only via core/rules/); operations has no references/ or
      # schemas/ dirs (OPERATIONS.md + operations/skills/*/SKILL.md are the
      # operations governance + skill scope). The earlier release/{schemas,specs,
      # standards,rules}/ and operations/{references,schemas}/ globs never matched
      # this layout and were dropped to keep every glob zero-yield-free.
      c14_output=$(/usr/bin/python3 "$c14_script" \
        --target-paths "core/governance/,core/disciplines/,core/schemas/,core/standards/,core/specs/,core/rules/,core/CLAUDE.md.template,release/governance/,release/references/,operations/OPERATIONS.md,operations/skills/*/SKILL.md,release/skills/*/SKILL.md,core/skills/*/SKILL.md" \
        --allowlist "$c14_allowlist" \
        --output-format tsv \
        --require-targets \
        --exclude-code-blocks 2>&1) || c14_exit=$?
      if [[ $c14_exit -eq 3 ]]; then
        # Path-resolution failure — never a silent PASS (per #459 fail-loud).
        flag_warn_or_issue "doc-link-maintenance" "path-resolution failure (exit 3): $(echo "$c14_output" | head -1) — a declared --target-paths glob resolved to zero files (relocated/typo'd scan surface); fix the glob list in this check"
      elif [[ $c14_exit -eq 0 ]]; then
        log "  OK:    no broken cross-refs in scope"
      else
        local c14_findings
        c14_findings=$(echo "$c14_output" | tail -n +2 | wc -l | tr -d ' ')
        flag_warn_or_issue "doc-link-maintenance" "$c14_findings broken cross-ref(s) — see protocol at core/standards/doc-link-maintenance-protocol.md"
        echo "$c14_output" | head -10 | sed 's/^/         /' || true
        if [[ $c14_findings -gt 10 ]]; then
          log "         ... ($((c14_findings - 10)) more; rerun primitive directly for full output)"
        fi
      fi
    fi
  fi

  # ─── Check 15: Release-corpus cross-link integrity — RETIRED in v2 ──────────
  # Per Stage 5 spec Surface 4 + operator FX-Check15 (2026-05-27):
  # release-corpus (RELEASE_LOG.md, releases/plans/, releases/notes/) is
  # operator-instance per harness plan § 2.4. v2 deploy.sh ships Check 14 only.
  #
  # Architectural pattern (3 layers):
  #   Layer 1 (primary): operator's external release-notes tool (GitHub Releases
  #     per the dual-write Surface 1 + native validation; OR Azure DevOps;
  #     OR JIRA; OR Confluence; OR other). Provides release-time integrity via
  #     the chosen tool's native validation surface.
  #   Layer 2 (fallback): ~/Claude/personal/pmo-instance/tools/check-release-corpus.sh
  #     wrapper invoking core/deploy/tools/check-doc-links.py against
  #     operator-instance release corpus paths. Authoring deferred to the
  #     P2.5-T1 (onboarding) milestone per FX-Check15 disposition.
  #   Layer 3 (release-pipeline gates): Stage 12 + Stage 13 chip prompts +
  #     Procedure 7 Step 4 completion-verification fire
  #     regardless of operator's Layer 1/2 choice (release-notes presence +
  #     CHANGELOG + GitHub Release Surface 1 emit).
  #
  # Evolution: an earlier Check 15 scanned the in-repo release corpus; a
  # subsequent wave gated it on the PMO_INSTANCE_PATH env var; this retirement
  # replaces the gated block with this citation comment per the operator's full
  # architectural disposition.
  #
  # Check numbering: gap (15 retired) preserved for citation continuity of
  # Checks 16-30 across governance + the codebase. Operator may re-introduce
  # an in-tree Check 15 in a future release if architectural posture changes.

  # ─── Check 16: Status-label invariant (I1/I2/I3/I4) ────────
  # Asserts the 4 atomic invariants on open improvement issues:
  #   I1 mutex          — any open improvement with >1 status:* label
  #   I2 presence       — any open improvement with 0 status:* labels
  #   I3 contradiction-A — status: proposed + milestone set
  #   I4 contradiction-B — status: bundled + no milestone
  # Status-label vocabulary-agnostic via startswith("status: ") — accepts
  # any current or future status value (status: deferred / status: rejected
  # land cleanly).
  # Mode-gated via $DEPLOY_CHECK_MODE (warn / enforce / off) per Checks 8-10
  # precedent. Ships in warn-mode for ≥3-day shakedown per
  # bypass-mode-readiness.md §Shakedown.
  # Exemption: .claude/status-label-invariant-exemption-list.txt — lines of
  # `<issue-number> <invariant-id>` skip the matching violation.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 16: Status-label invariant (I1/I2/I3/I4)"
    local C14_EXEMPT_FILE=".claude/status-label-invariant-exemption-list.txt"
    local c14_violations=0

    # exempt_pair issue_num invariant_id — returns 0 if exempt
    exempt_pair() {
      local _num="$1" _inv="$2"
      [[ -f "$C14_EXEMPT_FILE" ]] || return 1
      grep -qE "^[[:space:]]*${_num}[[:space:]]+${_inv}([[:space:]]|$)" "$C14_EXEMPT_FILE"
    }

    # Single fetch — feeds all 4 invariant queries via local jq filters.
    local c14_issues_json
    c14_issues_json=$(gh issue list --repo "$AUDIT_REPO" --state open \
      --label improvement --limit 5000 --json number,labels,milestone 2>/dev/null || echo "[]")

    # I1 — mutex: >1 status:* label
    local c14_i1_violators
    c14_i1_violators=$(printf '%s' "$c14_issues_json" | jq -r '
      .[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) > 1)
      | .number')
    while IFS= read -r _num; do
      [[ -n "$_num" ]] || continue
      if exempt_pair "$_num" "I1"; then
        log "  EXEMPT: I1 mutex on issue #$_num (exemption-list)"
        continue
      fi
      flag_warn_or_issue "status-label-I1-mutex" "issue #$_num has >1 status:* label"
      c14_violations=$((c14_violations + 1))
    done <<< "$c14_i1_violators"

    # I2 — presence: 0 status:* labels
    local c14_i2_violators
    c14_i2_violators=$(printf '%s' "$c14_issues_json" | jq -r '
      .[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) == 0)
      | .number')
    while IFS= read -r _num; do
      [[ -n "$_num" ]] || continue
      if exempt_pair "$_num" "I2"; then
        log "  EXEMPT: I2 presence on issue #$_num (exemption-list)"
        continue
      fi
      flag_warn_or_issue "status-label-I2-presence" "issue #$_num missing all status:* labels"
      c14_violations=$((c14_violations + 1))
    done <<< "$c14_i2_violators"

    # I3 — contradiction-A: status: proposed + milestone set
    local c14_i3_violators
    c14_i3_violators=$(printf '%s' "$c14_issues_json" | jq -r '
      .[] | select(.milestone != null)
      | select((.labels | map(.name) | map(select(. == "status: proposed"))) | length > 0)
      | .number')
    while IFS= read -r _num; do
      [[ -n "$_num" ]] || continue
      if exempt_pair "$_num" "I3"; then
        log "  EXEMPT: I3 contradiction-A on issue #$_num (exemption-list)"
        continue
      fi
      flag_warn_or_issue "status-label-I3-contradiction-A" "issue #$_num is status: proposed but milestone is set"
      c14_violations=$((c14_violations + 1))
    done <<< "$c14_i3_violators"

    # I4 — contradiction-B: status: bundled + no milestone
    local c14_i4_violators
    c14_i4_violators=$(printf '%s' "$c14_issues_json" | jq -r '
      .[] | select(.milestone == null)
      | select((.labels | map(.name) | map(select(. == "status: bundled"))) | length > 0)
      | .number')
    while IFS= read -r _num; do
      [[ -n "$_num" ]] || continue
      if exempt_pair "$_num" "I4"; then
        log "  EXEMPT: I4 contradiction-B on issue #$_num (exemption-list)"
        continue
      fi
      flag_warn_or_issue "status-label-I4-contradiction-B" "issue #$_num is status: bundled but no milestone"
      c14_violations=$((c14_violations + 1))
    done <<< "$c14_i4_violators"

    if [[ "$c14_violations" -eq 0 ]]; then
      log "  OK:    0 violations across I1/I2/I3/I4 (open improvements)"
    else
      log "  ${c14_violations} violation(s) emitted (mode=${DEPLOY_CHECK_MODE})"
    fi
  fi

  # ─── Check 17: Aging signal (status: proposed) ─────────────────────
  # Tiered thresholds per locked D-Aging-SLA-Threshold Option D:
  #   warn      ≥14d  — 2-week sprint cadence (forward-looking ops alignment)
  #   escalate  ≥30d  — 2026-05-11 audit cluster threshold (historical observation)
  #   critical  ≥45d  — historical incident anchor (worst-case)
  # Mode-gated via $DEPLOY_CHECK_MODE per Checks 8-10/14 precedent. Ships in
  # warn-mode for ≥3-day shakedown per bypass-mode-readiness.md §Shakedown.
  # Per-issue age computed via jq's `now - (.createdAt | fromdate)` builtin —
  # avoids BSD-vs-GNU date arithmetic divergence on macOS.
  # Override hooks (testing-only): C17_THRESHOLD_OVERRIDE_FILE points at a
  # space-separated single-line "WARN ESCALATE CRITICAL" file (e.g. "0 0 0" to force all
  # extant proposed issues into critical band for synthetic threshold testing).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 17: Aging signal (status: proposed)"
    local THRESHOLD_WARN_DAYS=14
    local THRESHOLD_ESCALATE_DAYS=30
    local THRESHOLD_CRITICAL_DAYS=45
    if [[ -n "${C17_THRESHOLD_OVERRIDE_FILE:-}" ]] && [[ -f "$C17_THRESHOLD_OVERRIDE_FILE" ]]; then
      read -r THRESHOLD_WARN_DAYS THRESHOLD_ESCALATE_DAYS THRESHOLD_CRITICAL_DAYS < "$C17_THRESHOLD_OVERRIDE_FILE"
      log "  TEST:  threshold override active (warn=${THRESHOLD_WARN_DAYS} escalate=${THRESHOLD_ESCALATE_DAYS} critical=${THRESHOLD_CRITICAL_DAYS})"
    fi

    local c15_proposed_json
    c15_proposed_json=$(gh issue list --repo "$AUDIT_REPO" \
      --label "status: proposed" --state open --limit 1000 \
      --json number,title,createdAt 2>/dev/null) || c15_proposed_json="[]"

    # Partition issues into bands by age. Band assignment is exclusive — each
    # issue lands in exactly one band (highest applicable severity). Within
    # each band, sort descending by age so the operator's first-line scan
    # surfaces the oldest issue per band.
    local c15_partition
    c15_partition=$(printf '%s' "$c15_proposed_json" | jq \
      --argjson w "$THRESHOLD_WARN_DAYS" \
      --argjson e "$THRESHOLD_ESCALATE_DAYS" \
      --argjson c "$THRESHOLD_CRITICAL_DAYS" '
      [.[] | {number, title, age_days: ((now - (.createdAt | fromdate)) / 86400 | floor)}]
      | (map(select(.age_days >= $c)) | sort_by(-.age_days)) as $crit
      | (map(select(.age_days >= $e and .age_days < $c)) | sort_by(-.age_days)) as $esc
      | (map(select(.age_days >= $w and .age_days < $e)) | sort_by(-.age_days)) as $warn
      | {
        critical_count: ($crit | length),
        escalate_count: ($esc | length),
        warn_count:     ($warn | length),
        critical: $crit,
        escalate: $esc,
        warn: $warn
      }
    ' 2>/dev/null) || {
      log "  ERROR: Check 17 unable to parse status:proposed issue ages"
      c15_partition='{"critical_count":0,"escalate_count":0,"warn_count":0,"critical":[],"escalate":[],"warn":[]}'
    }

    local c15_critical_count c15_escalate_count c15_warn_count c15_total
    c15_critical_count=$(printf '%s' "$c15_partition" | jq -r '.critical_count')
    c15_escalate_count=$(printf '%s' "$c15_partition" | jq -r '.escalate_count')
    c15_warn_count=$(printf '%s' "$c15_partition" | jq -r '.warn_count')
    c15_total=$((c15_warn_count + c15_escalate_count + c15_critical_count))

    # Emit overdue issues in severity order (critical → escalate → warn) so the
    # most severe surfaces first when the operator scans top-down.
    while IFS= read -r _line; do
      [[ -n "$_line" ]] || continue
      local _num _age _title
      _num=$(printf '%s' "$_line" | jq -r '.number')
      _age=$(printf '%s' "$_line" | jq -r '.age_days')
      _title=$(printf '%s' "$_line" | jq -r '.title')
      flag_warn_or_issue "aging-critical-${THRESHOLD_CRITICAL_DAYS}d" \
        "issue #${_num} status:proposed for ${_age}d (≥${THRESHOLD_CRITICAL_DAYS}d critical) — ${_title}"
    done < <(printf '%s' "$c15_partition" | jq -c '.critical[]')

    while IFS= read -r _line; do
      [[ -n "$_line" ]] || continue
      local _num _age _title
      _num=$(printf '%s' "$_line" | jq -r '.number')
      _age=$(printf '%s' "$_line" | jq -r '.age_days')
      _title=$(printf '%s' "$_line" | jq -r '.title')
      flag_warn_or_issue "aging-escalate-${THRESHOLD_ESCALATE_DAYS}d" \
        "issue #${_num} status:proposed for ${_age}d (≥${THRESHOLD_ESCALATE_DAYS}d escalate) — ${_title}"
    done < <(printf '%s' "$c15_partition" | jq -c '.escalate[]')

    while IFS= read -r _line; do
      [[ -n "$_line" ]] || continue
      local _num _age _title
      _num=$(printf '%s' "$_line" | jq -r '.number')
      _age=$(printf '%s' "$_line" | jq -r '.age_days')
      _title=$(printf '%s' "$_line" | jq -r '.title')
      flag_warn_or_issue "aging-warn-${THRESHOLD_WARN_DAYS}d" \
        "issue #${_num} status:proposed for ${_age}d (≥${THRESHOLD_WARN_DAYS}d warn) — ${_title}"
    done < <(printf '%s' "$c15_partition" | jq -c '.warn[]')

    if [[ "$c15_total" -eq 0 ]]; then
      log "  OK:    0 status:proposed issues at ≥${THRESHOLD_WARN_DAYS}d (warn=${c15_warn_count} escalate=${c15_escalate_count} critical=${c15_critical_count})"
    else
      log "  ${c15_total} aging signal(s) emitted (warn=${c15_warn_count} escalate=${c15_escalate_count} critical=${c15_critical_count}; mode=${DEPLOY_CHECK_MODE})"
    fi
  fi

  # ─── Check 18: Framework-corpus version-anchor drift detection ──────
  # Catalog-registry-driven (NOT prose corpus-scan) per
  # ADR-framework-catalog — parallels Check 13's TEMPLATE_SYNC_MAP registry,
  # not Check 14's corpus glob. Invokes the primitive at
  # core/deploy/tools/check-version-anchors.py over the governed
  # registry core/specs/framework-catalog.md. Sub-checks:
  # 18a catalog completeness / 18b catalog↔doc anchor consistency / 18c cadence
  # aging. Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks
  # 8/9/10/14/15 precedent); flip-to-enforce timeline + explicit reflexive
  # self-exemption cutover codified in
  # core/standards/framework-corpus-discipline.md §8/§9.
  # Error-isolation idiom mirrors Check 14 (primitive/python/catalog missing →
  # flag_warn_or_issue, not crash; output=$(... 2>&1) || exit=$?).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 18: Framework-corpus version-anchor drift detection"
    local c18_script="core/deploy/tools/check-version-anchors.py"
    # Live catalog is core/specs/framework-catalog.md (was the dead
    # release/specs/ path → Check 18 emitted a false "catalog registry missing"
    # every run, the loud-but-wrong inverse of silent-pass). Fixed per #459.
    local c18_catalog="core/specs/framework-catalog.md"
    if [[ ! -f "$c18_script" ]]; then
      flag_warn_or_issue "framework-anchor-drift" "primitive script missing: $c18_script"
    elif [[ ! -x "/usr/bin/python3" ]]; then
      flag_warn_or_issue "framework-anchor-drift" "/usr/bin/python3 not executable; cannot run primitive"
    elif [[ ! -f "$c18_catalog" ]]; then
      flag_warn_or_issue "framework-anchor-drift" "catalog registry missing: $c18_catalog"
    else
      local c18_output c18_exit=0
      c18_output=$(/usr/bin/python3 "$c18_script" \
        --catalog-path "$c18_catalog" \
        --output-format tsv 2>&1) || c18_exit=$?
      if [[ $c18_exit -eq 3 ]]; then
        # Path-resolution failure — the tool could not resolve its catalog
        # target. Never a silent PASS (per #459 fail-loud).
        flag_warn_or_issue "framework-anchor-drift" "path-resolution failure (exit 3): $(echo "$c18_output" | head -1) — catalog target did not resolve"
      elif [[ $c18_exit -eq 0 ]]; then
        log "  OK:    catalog complete, anchors consistent, no overdue reviews"
      else
        local c18_findings
        c18_findings=$(echo "$c18_output" | tail -n +2 | wc -l | tr -d ' ')
        flag_warn_or_issue "framework-anchor-drift" "$c18_findings framework-anchor finding(s) — see protocol at core/standards/framework-corpus-discipline.md"
        echo "$c18_output" | head -10 | sed 's/^/         /' || true
        if [[ $c18_findings -gt 10 ]]; then
          log "         ... ($((c18_findings - 10)) more; rerun primitive directly for full output)"
        fi
      fi
    fi
  fi

  # ─── Check 19: Pipeline-event-log integrity ─────────────────────────
  # Validates that the unified audit-trail capture surface
  # (pipeline-event-log.md) is only written through the helper
  # (append-pipeline-event.sh) — drift indicates a direct edit that bypassed
  # schema validation.
  # Sub-checks:
  # 19a presence — log file + write-log file + schema doc all exist
  # 19b row-count parity — data-row count in log file == data-line count in
  #     write-log (one write-log line per appended row; both grow together)
  # 19c header preserved — log file header row matches the schema header
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks 8/9/10
  # /14/15/18 precedent); flip-to-enforce after ≥3-day warn-log review with
  # zero false positives. The introducing release itself is exempt from capture
  # (cutover begins the following release) — an empty body during shakedown is
  # the EXPECTED state, NOT drift.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 19: Pipeline-event-log integrity"
    local c19_log="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/pipeline-event-log.md"
    local c19_write_log="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/pipeline-event-log-write.log"
    local c19_schema="release/standards/pipeline-event-log-schema.md"

    # 19a — presence
    if [[ ! -f "$c19_log" ]]; then
      flag_warn_or_issue "pipeline-event-log-integrity" "log file missing: $c19_log"
    elif [[ ! -f "$c19_write_log" ]]; then
      flag_warn_or_issue "pipeline-event-log-integrity" "write-log missing: $c19_write_log"
    elif [[ ! -f "$c19_schema" ]]; then
      flag_warn_or_issue "pipeline-event-log-integrity" "schema doc missing: $c19_schema"
    else
      # 19b — row-count parity
      # Data rows start with '| YYYY-' (ISO timestamp begins with a digit).
      # Header + separator do NOT match this pattern; only data rows do.
      local c19_log_rows c19_write_lines
      c19_log_rows=$(/usr/bin/grep -cE '^\| [0-9]{4}-' "$c19_log" 2>/dev/null || true); c19_log_rows=${c19_log_rows:-0}
      # Write-log: non-blank, non-comment lines.
      c19_write_lines=$(/usr/bin/grep -cE '^[^#[:space:]]' "$c19_write_log" 2>/dev/null || true); c19_write_lines=${c19_write_lines:-0}

      if [[ "$c19_log_rows" -ne "$c19_write_lines" ]]; then
        flag_warn_or_issue "pipeline-event-log-integrity" \
          "row-count parity drift: $c19_log rows=$c19_log_rows, $c19_write_log lines=$c19_write_lines (direct edit suspected — use append-pipeline-event.sh)"
      fi

      # 19c — header preserved (1st column header must be 'ts_iso')
      local c19_header_ok
      c19_header_ok=$(/usr/bin/grep -c '^| ts_iso |' "$c19_log" 2>/dev/null || true); c19_header_ok=${c19_header_ok:-0}
      if [[ "$c19_header_ok" -lt 1 ]]; then
        flag_warn_or_issue "pipeline-event-log-integrity" \
          "header row missing or malformed in $c19_log (expected '| ts_iso | …')"
      fi

      if [[ "$c19_log_rows" -eq "$c19_write_lines" && "$c19_header_ok" -ge 1 ]]; then
        log "  OK:    log rows=$c19_log_rows, write-log lines=$c19_write_lines, header preserved"
      fi
    fi
  fi

  # ─── Check 20: Note-content lint (release-notes-standard.md §3.2) ──
  # Lints user-facing release notes against the new-standard Section 6a rules:
  #   9  — Section 6a present (>=1 bullet OR 'No user-visible behavior changes' placeholder)
  #   10 — §2.4 banned-jargon scan (14 literal + 4 regex deny-list patterns)
  #   11 — 'Why it matters:' beat per bullet OR <!-- impact:foundational --> marker
  #   12 — No raw 'pmo-platform/' or '.claude/' paths in bullet bodies (inline markdown links OK)
  # Forward-only from the lint cutover — pre-cutover notes exempt via
  # PRE_CUTOVER_EXEMPT_VERSIONS in lint_release_corpus.py (handles
  # version-tuple/chronology mismatches).
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks 8/9/10/14/15/18/19
  # precedent); flip-to-enforce after ≥3-day warn-log review with zero false positives.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 20: Note-content lint (release-notes-standard.md §3.2)"
    local c20_lint_script="core/deploy/tools/lint_release_corpus.py"
    if [[ ! -f "$c20_lint_script" ]]; then
      flag_warn_or_issue "note-content-lint" "tooling missing: $c20_lint_script"
    elif [[ ! -x "/usr/bin/python3" ]]; then
      flag_warn_or_issue "note-content-lint" "/usr/bin/python3 not executable; cannot run validator"
    else
      local c20_output c20_exit=0
      c20_output=$(/usr/bin/python3 "$c20_lint_script" --check note-content 2>&1) || c20_exit=$?
      if [[ $c20_exit -eq 3 ]]; then
        # Path-resolution failure (exit 3 / CORPUS-PATH-UNRESOLVED) — a required
        # corpus dir did not resolve, so the lint is unverifiable, NOT clean. This
        # is the exact vacuous-pass #83 fixes; surface it as FAIL/DRIFT, never an
        # OK (per #459 fail-loud).
        flag_warn_or_issue "note-content-lint" \
          "path-resolution failure (exit 3): $(echo "$c20_output" | head -1) — corpus path misconfigured; Check 20 cannot lint"
        echo "$c20_output" | head -10 | sed 's/^/         [6a]     /' || true
      else
        local c20_findings=0
        if [[ $c20_exit -ne 0 ]]; then
          c20_findings=$(echo "$c20_output" | wc -l | tr -d ' ')
        fi
        if [[ $c20_findings -eq 0 ]]; then
          log "  OK:    Section 6a content clean (forward-only from the lint cutover)"
        else
          flag_warn_or_issue "note-content-lint" \
            "$c20_findings finding(s) in Section 6a content — see release-notes-standard.md §3.2"
          echo "$c20_output" | head -10 | sed 's/^/         [6a]     /' || true
        fi
      fi
    fi
  fi

  # ─── Check 21: Native-dep body↔native drift detection ────────
  # Detects drift between body Dependencies field (authoritative) and native
  # GitHub issue dependencies (`blocks`/`blocked-by`) per the one-way mirror
  # model (see ticket-information-architecture.md § Native
  # Dependencies). Body `FS+0d #N` deps should mirror to native `blocked-by`;
  # native deps not in body surface as drift findings for operator review.
  #
  # Sub-checks:
  #   21a token scope — verifies `gh auth status` reports `repo` scope; if
  #       missing, the check warns once and exits cleanly (does not iterate
  #       issues; mirror is non-gate-blocking and degrades gracefully)
  #   21b per-issue drift — iterates open improvement issues; parses body
  #       Dependencies field for FS+0d edges; queries native blocked-by via
  #       GraphQL; reports per-issue drift via flag_warn_or_issue
  #
  # The check runs whenever AUDIT_REPO resolves to a tracker that uses the
  # native-dependency mirror; with no tracker configured the issue query
  # returns an empty set and the check no-ops cleanly.
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks
  # 8/9/10/14/15/18/19/20 precedent); flip-to-enforce after ≥3-day warn-log
  # review with zero false positives.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 21: Native-dep body↔native drift detection"

    # 21a — token scope check (non-fatal; mirror is non-gate-blocking)
    local c21_scope_ok=true
    if ! gh auth status --hostname github.com 2>&1 | /usr/bin/grep -qE '\brepo\b'; then
      flag_warn_or_issue "native-dep-drift" "gh auth scope missing 'repo' — cannot query native deps; native mirror degrades to body-only (run 'gh auth refresh -s repo')"
      c21_scope_ok=false
    fi

    if [[ "$c21_scope_ok" == "true" ]]; then
      # 21b — per-issue drift detection
      # Iterate open improvement issues with non-empty Dependencies fields.
      # For each FS+0d body dep, check native blocked-by; flag drift via
      # flag_warn_or_issue. Drift type 1: body cites #X, native lacks #X
      # (auto-resolvable at next Stage 2 trigger). Drift type 2: native
      # has #Y, body lacks #Y (operator-mediated reconciliation).
      local c21_issues_json
      c21_issues_json=$(gh issue list --repo "$AUDIT_REPO" --state open \
        --label improvement --limit 5000 --json number,body 2>/dev/null || echo "[]")

      local c21_drift_count=0
      local c21_issue_count=0
      c21_issue_count=$(printf '%s' "$c21_issues_json" | jq 'length' 2>/dev/null || echo 0)

      # Per-issue iteration. Parse body Dependencies field; extract FS+0d
      # references (untyped #N defaults to FS+0d; explicit `FS #N` or
      # `FS+0d #N` also match). Skip non-FS-zero-lag edges (SS / FF / SF /
      # FS±Nd remain body-only by design per ticket-information-architecture.md).
      local _issue_num _issue_body _body_deps _native_deps _drift_to_add _drift_drift
      while IFS= read -r _issue_line; do
        [[ -n "$_issue_line" ]] || continue
        _issue_num=$(printf '%s' "$_issue_line" | jq -r '.number')
        _issue_body=$(printf '%s' "$_issue_line" | jq -r '.body // ""')

        # Extract Dependencies section (between `### Dependencies` and
        # next `### ` heading or end-of-body). FS+0d match patterns:
        #   bare `- #N`                       → FS+0d (untyped)
        #   `- FS #N` / `- FS+0d #N`          → explicit FS+0d
        # Non-FS-zero-lag patterns (excluded):
        #   `- SS #N`, `- FF #N`, `- SF #N`, `- FS+Nd #N`, `- FS-Nd #N`
        _body_deps=$(printf '%s' "$_issue_body" \
          | /usr/bin/awk 'BEGIN{p=0} /^### Dependencies/{p=1; next} p && /^### /{p=0} p' \
          | /usr/bin/grep -oE '^[[:space:]]*-[[:space:]]*(FS([[:space:]]|\+0d[[:space:]]))?#[0-9]+' \
          | /usr/bin/grep -oE '#[0-9]+' \
          | /usr/bin/sort -u | /usr/bin/tr '\n' ' ' || true)

        # Skip issues with no FS+0d body deps
        [[ -z "${_body_deps// }" ]] && continue

        # Query native blocked-by via GraphQL. Issue dependency GraphQL
        # surfaced via repository.issue.trackedInIssues / trackedIssues
        # (the GA Aug 2025 schema). Implementation tolerates missing
        # field set if upstream schema names diverge — degrades to empty
        # native set rather than crashing.
        _native_deps=$(gh api graphql -f query="
          query(\$num: Int!) {
            repository(owner: \"${AUDIT_REPO%%/*}\", name: \"${AUDIT_REPO##*/}\") {
              issue(number: \$num) {
                trackedInIssues(first: 50) { nodes { number } }
              }
            }
          }" -F num="$_issue_num" 2>/dev/null \
          | jq -r '.data.repository.issue.trackedInIssues.nodes[]?.number // empty' 2>/dev/null \
          | /usr/bin/sed 's/^/#/' \
          | /usr/bin/sort -u | /usr/bin/tr '\n' ' ' || true)

        # Diff body→native: entries in body but missing from native
        # (auto-resolvable at next Stage 2 mirror invocation)
        _drift_to_add=$(/usr/bin/comm -23 \
          <(printf '%s\n' $_body_deps | /usr/bin/sort -u) \
          <(printf '%s\n' $_native_deps | /usr/bin/sort -u) \
          2>/dev/null | /usr/bin/tr '\n' ' ' || true)

        # Diff native→body: entries in native but missing from body
        # (operator-mediated reconciliation — body remains authoritative)
        _drift_drift=$(/usr/bin/comm -13 \
          <(printf '%s\n' $_body_deps | /usr/bin/sort -u) \
          <(printf '%s\n' $_native_deps | /usr/bin/sort -u) \
          2>/dev/null | /usr/bin/tr '\n' ' ' || true)

        if [[ -n "${_drift_to_add// }" ]]; then
          flag_warn_or_issue "native-dep-drift-to-add" \
            "issue #${_issue_num} — body cites FS+0d deps not in native: ${_drift_to_add} (auto-resolves at next Stage 2 A3.5 trigger)"
          c21_drift_count=$((c21_drift_count + 1))
        fi
        if [[ -n "${_drift_drift// }" ]]; then
          flag_warn_or_issue "native-dep-drift-orphan" \
            "issue #${_issue_num} — native has blocked-by deps not in body: ${_drift_drift} (operator-mediated reconciliation per ticket-information-architecture.md § Native Dependencies)"
          c21_drift_count=$((c21_drift_count + 1))
        fi
      done < <(printf '%s' "$c21_issues_json" | jq -c '.[]')

      if [[ "$c21_drift_count" -eq 0 ]]; then
        log "  OK:    0 drift findings across ${c21_issue_count} open improvement issue(s)"
      else
        log "  ${c21_drift_count} drift finding(s) emitted (mode=${DEPLOY_CHECK_MODE})"
      fi
    fi
  fi

  # ─── Check 22: G1 enforcement on bundled issues ─────────────
  # Detects retrospective G1 (Triage Readiness) compliance gaps on issues
  # already bundled (status: bundled label). Surfaced by a /release-planner
  # Mode A audit which found latent G1 defects across newly-bundled issues —
  # Stage 2 Triage was the only early stage with zero tooling enforcement.
  #
  # Scope decision rendered Option 3 (check-only): ship Layer (b) detection-
  # only enforcement. Layers (a) intake-time hook and (c) scheduled cadence
  # are deferred as calibrated follow-ons IF Layer (b) shakedown surfaces
  # need. Lowest blast radius; mirrors deploy.sh --check warn-mode shakedown
  # precedent (Checks 8/9/10/14/15/18/19/20/21).
  #
  # Structural-auto criteria evaluated (per gate-criteria-spec.md § Gate 1):
  #   G1-01  title prefix `[Category]:` (improvement) / `[Bug]:` (bug per
  #          Adapter G1-01-Bug) / `[Observation]:` (observation per Adapter
  #          G1-01-Obs)
  #   G1-03  evidence-quality labels present in body — at least one
  #          [SOURCE]/[INFERRED]/[CONTEXT]/[ASSUMPTION ...]/[RECOMMENDED];
  #          n/a for observation
  #   G1-06  Priority `P1`-`P4` in improvement body OR Severity `P1`-`P4` in
  #          bug body per Adapter G1-06-Bug; n/a for observation
  #   G1-09  label-body template match — label_template (Step 1) must agree
  #          with inferred_template (Step 2) per Template Detection Logic at
  #          gate-criteria-spec.md:71
  #
  # Judgment criteria (G1-02 / G1-04 / G1-05 / G1-08) are deliberately
  # excluded — they are recommend-tier per gate-criteria-spec.md, not
  # suitable for structural-auto enforcement.
  #
  # Template Detection Logic — pragmatic body-marker variant:
  #   gate-criteria-spec.md:81 cites `### Priority` AND `### Category` AND
  #   `### Description` for improvement, but the actual rendered improvement
  #   issue bodies use `**Priority:**` and `**Category:**` (dropdown bold)
  #   rather than `### Priority` and `### Category` (section headers). This
  #   check uses the unique textarea section headers that DO appear in
  #   rendered bodies:
  #     bug         → `### Reproduction Steps`
  #     observation → `### What is missing?`
  #     improvement → `### Proposed Change`
  #   The pragmatic markers are unique to each template per body-marker-
  #   uniqueness verification at gate-criteria-spec.md:90.
  #
  # Sub-checks:
  #   22a token   — verifies `gh auth status` reports `repo` scope; if
  #       missing, the check warns once and exits cleanly
  #   22b per-issue — iterates open `status: bundled` issues; applies
  #       Template Detection Logic; evaluates G1-01/G1-03/G1-06/G1-09 per
  #       applies-to triple using Adapter Blocks G1-01-Bug / G1-01-Obs /
  #       G1-06-Bug
  #
  # The check runs whenever AUDIT_REPO resolves to a tracker; with no tracker
  # configured the bundled-issue query returns an empty set and it no-ops.
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks
  # 8/9/10/14/15/18/19/20/21 precedent); flip-to-enforce after ≥3-day
  # warn-log review with zero false positives. Operator may consider adding
  # Layers (a) intake-time hook and (c) scheduled cadence after a 2-3 release
  # calibration window: "keep in mind the right time to perform this work
  # and the tools/processes available currently."
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 22: G1 enforcement on bundled issues"

    # 22a — gh auth scope check (issue list read requires `repo` for
    # private repos; this is non-fatal — check warns once and exits if
    # scope missing, since the check is non-gate-blocking detection)
    local c22_scope_ok=true
    if ! gh auth status --hostname github.com 2>&1 | /usr/bin/grep -qE '\brepo\b'; then
      flag_warn_or_issue "g1-enforcement" "gh auth scope missing 'repo' — cannot iterate bundled issues (run 'gh auth refresh -s repo')"
      c22_scope_ok=false
    fi

    if [[ "$c22_scope_ok" == "true" ]]; then
      # 22b — per-issue G1 evaluation
      # Single bulk query: all open status:bundled issues with body+labels.
      local c22_issues_json
      c22_issues_json=$(gh issue list --repo "$AUDIT_REPO" --state open \
        --label "status: bundled" --limit 5000 \
        --json number,title,body,labels 2>/dev/null || echo "[]")

      local c22_issue_count c22_finding_count=0
      c22_issue_count=$(printf '%s' "$c22_issues_json" | jq 'length' 2>/dev/null || echo 0)

      # Per-issue iteration. For each issue:
      #  1. Determine intake-tier label count + label_template (Step 1)
      #  2. Infer template from unique body markers (Step 2; pragmatic
      #     variant per leading comment)
      #  3. Reconcile (Step 3) — emit G1-09 FAIL on mismatch
      #  4. Apply G1-01 / G1-03 / G1-06 per applies-to triple
      local _num _title _body _labels _label_template _inferred _template
      local _has_imp _has_bug _has_obs _label_total
      local _bm_repro _bm_obswhat _bm_propchange _title_ok
      while IFS= read -r _issue_line; do
        [[ -n "$_issue_line" ]] || continue
        _num=$(printf '%s' "$_issue_line" | jq -r '.number')
        _title=$(printf '%s' "$_issue_line" | jq -r '.title // ""')
        _body=$(printf '%s' "$_issue_line" | jq -r '.body // ""')
        _labels=$(printf '%s' "$_issue_line" | jq -r '.labels[].name' 2>/dev/null | /usr/bin/tr '\n' ',')

        # Step 1 — count intake-tier labels
        _has_imp=0; _has_bug=0; _has_obs=0
        [[ ",${_labels}" == *",improvement,"* ]] && _has_imp=1
        [[ ",${_labels}" == *",bug,"* ]] && _has_bug=1
        [[ ",${_labels}" == *",observation,"* ]] && _has_obs=1
        _label_total=$((_has_imp + _has_bug + _has_obs))

        if [[ "$_label_total" -ne 1 ]]; then
          flag_warn_or_issue "g1-enforcement" \
            "issue #${_num} — G1-09 FAIL: ${_label_total} intake-tier label(s) (expected exactly 1 of improvement/bug/observation; apply correct single label per pipeline/stage-01-intake.md § Routing)"
          c22_finding_count=$((c22_finding_count + 1))
          continue
        fi

        _label_template=""
        [[ "$_has_imp" -eq 1 ]] && _label_template="improvement"
        [[ "$_has_bug" -eq 1 ]] && _label_template="bug"
        [[ "$_has_obs" -eq 1 ]] && _label_template="observation"

        # Step 2 — infer template from unique body markers (pragmatic
        # variant; see leading comment for rationale)
        _bm_repro=0; _bm_obswhat=0; _bm_propchange=0
        printf '%s' "$_body" | /usr/bin/grep -qE '^### Reproduction Steps[[:space:]]*$' && _bm_repro=1
        printf '%s' "$_body" | /usr/bin/grep -qE '^### What is missing\?[[:space:]]*$' && _bm_obswhat=1
        printf '%s' "$_body" | /usr/bin/grep -qE '^### Proposed Change[[:space:]]*$' && _bm_propchange=1

        _inferred="ambiguous"
        if [[ "$_bm_repro" -eq 1 ]]; then
          _inferred="bug"
        elif [[ "$_bm_obswhat" -eq 1 ]]; then
          _inferred="observation"
        elif [[ "$_bm_propchange" -eq 1 ]]; then
          _inferred="improvement"
        fi

        # Step 3 — reconcile
        _template="$_label_template"
        if [[ "$_inferred" != "ambiguous" && "$_label_template" != "$_inferred" ]]; then
          flag_warn_or_issue "g1-enforcement" \
            "issue #${_num} — G1-09 FAIL: label=${_label_template}, body=${_inferred} (label-body template mismatch — relabel or rewrite body per gate-criteria-spec.md self-repair)"
          c22_finding_count=$((c22_finding_count + 1))
          continue
        fi

        # G1-01 — title prefix per applies-to triple + Adapter Blocks
        _title_ok=true
        case "$_template" in
          improvement)
            # Generic [Category]: prefix — accept any [<word(s)>]: prefix
            if ! printf '%s' "$_title" | /usr/bin/grep -qE '^\[[A-Za-z][A-Za-z /-]*\]:[[:space:]]'; then
              _title_ok=false
            fi
            ;;
          bug)
            # Adapter G1-01-Bug — literal [Bug]: prefix
            if ! printf '%s' "$_title" | /usr/bin/grep -qE '^\[Bug\]:[[:space:]]'; then
              _title_ok=false
            fi
            ;;
          observation)
            # Adapter G1-01-Obs — literal [Observation]: prefix
            if ! printf '%s' "$_title" | /usr/bin/grep -qE '^\[Observation\]:[[:space:]]'; then
              _title_ok=false
            fi
            ;;
        esac
        if [[ "$_title_ok" != "true" ]]; then
          flag_warn_or_issue "g1-enforcement" \
            "issue #${_num} — G1-01 FAIL: title prefix mismatch for template '${_template}' (expected '[Category]:' / '[Bug]:' / '[Observation]:' per Adapter Blocks)"
          c22_finding_count=$((c22_finding_count + 1))
        fi

        # G1-03 — evidence-quality labels in body (improvement + bug,
        # NOT observation per applies-to triple)
        if [[ "$_template" == "improvement" || "$_template" == "bug" ]]; then
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '\[(SOURCE|INFERRED|CONTEXT|RECOMMENDED|ASSUMPTION)' ; then
            flag_warn_or_issue "g1-enforcement" \
              "issue #${_num} — G1-03 FAIL: no evidence-quality labels found in body ([SOURCE]/[INFERRED]/[CONTEXT]/[ASSUMPTION – CONFIRM]/[RECOMMENDED])"
            c22_finding_count=$((c22_finding_count + 1))
          fi
        fi

        # G1-06 — Priority (improvement) OR Severity P-level (bug per
        # Adapter G1-06-Bug); n/a observation
        if [[ "$_template" == "improvement" ]]; then
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '\*\*Priority:\*\*[[:space:]]*P[1-4]'; then
            flag_warn_or_issue "g1-enforcement" \
              "issue #${_num} — G1-06 FAIL: Priority field missing or no P1-P4 value (improvement.yml expects '**Priority:** P1-Urgent'-style anchor)"
            c22_finding_count=$((c22_finding_count + 1))
          fi
        elif [[ "$_template" == "bug" ]]; then
          # Adapter G1-06-Bug — Severity P-level digit canonical
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '\*\*Severity:\*\*[[:space:]]*P[1-4]'; then
            flag_warn_or_issue "g1-enforcement" \
              "issue #${_num} — G1-06 FAIL: Severity field missing or no P1-P4 value (Adapter G1-06-Bug — bug.yml expects '**Severity:** P1-Blocker'-style anchor)"
            c22_finding_count=$((c22_finding_count + 1))
          fi
        fi

      done < <(printf '%s' "$c22_issues_json" | jq -c '.[]')

      if [[ "$c22_finding_count" -eq 0 ]]; then
        log "  OK:    0 G1 findings across ${c22_issue_count} bundled issue(s)"
      else
        log "  ${c22_finding_count} G1 finding(s) emitted across ${c22_issue_count} bundled issue(s) (mode=${DEPLOY_CHECK_MODE})"
      fi
    fi
  fi

  # ─── Check 23: RELEASE_LOG ↔ RELEASE_INDEX consistency ─────────────
  # Catches forward drift between RELEASE_LOG row state and RELEASE_INDEX entry
  # state (originating evidence: a VERIFIED→DEPLOYED state drift surfaced by a
  # later Stage-13 INDEX regen, already resolved). Invokes
  # generate_release_index.py --verify which re-generates INDEX to memory and
  # diffs against on-disk INDEX row-by-row.
  #
  # Reconciled from the Stage 5 spec's "Check 22" to Check 23 at Stage 6 — the
  # G1-enforcement check landed between spec authoring and engineering. Same
  # Stage 6 reconciliation pattern recorded in the Stage 5 spec (which itself
  # cites a prior deploy.sh precedent where a spec "Check 19" landed as a later
  # check number).
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks
  # 8/9/10/14/15/18/19/20/21/22 precedent); flip-to-enforce after ≥3-day
  # warn-log review with zero false positives.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 23: RELEASE_LOG ↔ RELEASE_INDEX consistency"
    local c23_script="core/deploy/tools/generate_release_index.py"
    if [[ ! -f "$c23_script" ]]; then
      flag_warn_or_issue "release-log-index-consistency" "generator missing: $c23_script"
    elif [[ ! -x "/usr/bin/python3" ]]; then
      flag_warn_or_issue "release-log-index-consistency" "/usr/bin/python3 not executable"
    else
      local c23_output c23_exit=0
      c23_output=$(/usr/bin/python3 "$c23_script" --verify 2>&1) || c23_exit=$?
      if [[ $c23_exit -eq 3 ]]; then
        # Path-resolution / parse failure (exit 3) — the generator could not
        # resolve LOG/INDEX or parsed zero rows, so --verify is unverifiable, NOT
        # clean. Was the silent-pass that let Check 23 read OK on a path error
        # (#85/#459); surface as FAIL/DRIFT, never an OK.
        flag_warn_or_issue "release-log-index-consistency" \
          "path-resolution failure (exit 3): $(echo "$c23_output" | head -1) — LOG/INDEX did not resolve or parsed zero rows"
        echo "$c23_output" | head -10 | sed 's/^/         /' || true
      elif [[ $c23_exit -eq 0 ]]; then
        log "  OK:    LOG ↔ INDEX rows aligned (version/milestone/date/release-pr/notes-link)"
      else
        local c23_findings
        c23_findings=$(echo "$c23_output" | wc -l | tr -d ' ')
        flag_warn_or_issue "release-log-index-consistency" \
          "$c23_findings LOG↔INDEX drift finding(s) — re-run 'python3 $c23_script' to regenerate"
        echo "$c23_output" | head -10 | sed 's/^/         /' || true
      fi
    fi
  fi

  # ─── Check 25: Universal-vs-localized-context authoring guardrail ──
  # Reconciled from a Stage 6 "Check 23" to Check 25 at Stage 9 — it collided
  # with the existing Check 23 (RELEASE_LOG ↔ RELEASE_INDEX; main merge-base
  # ahead). Operator-approved pre-merge rename per Stage 9 Plan Review DT-DA-2
  # path (a). Implements the spec at
  # core/standards/universal-vs-localized-context.md §7. DC1-DC4 + DC6
  # signature scan over Layer-1 corpus (governance + reference + .claude/rules/ +
  # skills/*/SKILL.md + skills/*/references/). Signal-not-verdict contract:
  # emits candidate signatures only; embedded-vs-teaching adjudication is the §5
  # review act (DC5 = the verdict dimension, applied by humans/skills to DC1-DC4
  # hits; NOT a 5th regex family per standard §3 verbatim — "n/a — it is the
  # verdict dimension and the guardrail's hook"). DC6 (reference-durability)
  # uses the §10.2 decision tree as its review act; carve-outs §10.4.
  #
  # 5 POSIX-ERE regex families:
  #   DC1 — Organizational identity (person/org names, phone/email PII)
  #   DC2 — Vendors/systems (named tools at parameter-seam positions)
  #   DC3 — Project identifiers (project keys + path embeddings + filename prefixes)
  #   DC4 — OOM literals (cadence, sign-off, compliance-framework)
  #   DC6 — Reference-durability (bare-#N + URL-form external GitHub
  #         Issue / Milestone / PR citations as candidate load-bearing content-locus)
  #
  # Empirically validated against the universal-vs-localized-context audit
  # (TRUE-LEAK + ILLUSTRATIVE rows for DC1-DC4) and the self-containment audit
  # under ${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/analysis/
  # (VIOLATION + REVIEW rows for DC6).
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks 8/9/10/14/
  # 15/18/19/20/21/22 precedent); flip-to-enforce after ≥3-day warn-log review.
  # The introducing release is itself exempt (DC1-DC4 and DC6) per
  # reflexive-pipeline-loop discipline — a rule shipping in a release cannot fire
  # on its own deploy; warn-mode means zero behavioral impact at ship.
  #
  # Allowlist: .claude/skip-localized-context-check.txt (empty-initial per
  # D-ALLOWLIST-SEED; operator adds per-file entries with rationale during
  # shakedown). Format mirrors .claude/skip-doc-link-check.txt (Check 14/15
  # sister-allowlist). The DC6 carve-out classes (Anthropic-owned URLs,
  # forward-binding provenance, authoritative-standard provenance) are seeded.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 25: Universal-vs-localized-context authoring guardrail (DC1-DC4 + DC6)"
    local c23_allowlist=".claude/skip-localized-context-check.txt"
    # DC1 — Organizational identity (person/org names, phone/email PII)
    # DC1 generic PII patterns only (phone, personal-email domains). Operator/
    # coworker-specific needles (names, org, org-domain) load at runtime from the
    # gitignored localized-context needle file via a fixed-string pass below, so
    # the tracked detector carries NO operator identity (self-containment — fixes
    # the prior defect where the detector embedded the very name/org it detects).
    local c23_dc1='[0-9]{3}-[0-9]{3}-[0-9]{4}|@(ymail|gmail|yahoo|outlook|hotmail|icloud)\.com'
    local c23_needles="${PMO_LOCALIZED_NEEDLES:-${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/localized-context-needles.txt}"
    # Operator project keys (e.g. tracker/Jira keys) load at runtime from the
    # gitignored project-keys file via the DC3 key pass below. The tracked DC3
    # detector therefore carries NO real project keys — baking literal keys into
    # the detector would make it a leak of the very identifiers it hunts (same
    # self-containment rationale as the DC1 needle file). One key per line; blank
    # lines and `#` comments ignored. Absent file → DC3 matches structural shapes
    # only (no-op for key-derived patterns).
    local c23_project_keys="${PMO_PROJECT_KEYS:-${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/project-keys.txt}"
    # DC2 — Vendors/systems (named tools at parameter-seam positions)
    local c23_dc2='\b(Smartsheet|Confluence|Jira|Teams|atlassian\.net|smartsheet\.com)\b'
    # DC3 — Project identifiers. Tracked pattern is STRUCTURAL ONLY (a
    # `projects/<Name>/` path embedding — a generic shape carrying no operator
    # keys). Operator-specific project keys + their `<KEY>_FDD` / `R-<KEY>-N`
    # derivations are matched by the runtime DC3 key pass below (built from the
    # gitignored project-keys file), so this shipped detector embeds no real keys.
    local c23_dc3='projects/[A-Z][A-Za-z[:space:]]+/'
    # DC4 — OOM literals (cadence, sign-off, compliance)
    local c23_dc4='\b(daily[[:space:]]+status|Monday[[:space:]]+steerco|weekly[[:space:]]+steerco)\b|"This is always yes for pmo-platform"|\b(SOX|HIPAA|GDPR)\b'
    # DC6 — Reference-durability (external GitHub Issue/Milestone/PR
    # citations as candidate load-bearing content-locus signatures).
    # Two patterns per the Stage 5 spec
    # D-EnforcementMechanism: Pattern A bare-#N in prose; Pattern B URL-form.
    # Signal-not-verdict contract: emits candidate signatures only;
    # §10.2 decision tree adjudication (provenance vs load-bearing; carve-outs
    # per §10.4) remains the review act. See protocol at
    # core/standards/universal-vs-localized-context.md §10.
    # Warn-mode initial; the introducing release is itself exempt per
    # reflexive-pipeline-loop discipline (a rule cannot fire on its own deploy).
    local c23_dc6='(^|[^A-Za-z0-9])#[0-9]+|github\.com/[^/]+/[^/]+/(issues|milestone|pull)/[0-9]+'

    # Allowlist filter — returns 0 (true) if file path matches an allowlist
    # pattern. Trailing slash → directory prefix; otherwise → bash glob.
    c23_is_allowlisted() {
      local _file="$1"
      [[ -f "$c23_allowlist" ]] || return 1
      local _pat
      while IFS= read -r _pat; do
        [[ -z "$_pat" || "$_pat" =~ ^[[:space:]]*# ]] && continue
        if [[ "$_pat" == */ ]]; then
          [[ "$_file" == "${_pat}"* ]] && return 0
        else
          case "$_file" in $_pat) return 0 ;; esac
        fi
      done < "$c23_allowlist"
      return 1
    }

    # Enumerate Layer-1 target files (5-surface set per D-TARGET-PATHS).
    # 2>/dev/null tolerates missing skill subdirs (skill without references/).
    local c23_files=()
    local _f
    while IFS= read -r -d '' _f; do
      c23_is_allowlisted "$_f" || c23_files+=("$_f")
    done < <(
      /usr/bin/find \
        core/governance \
        release/governance \
        core/disciplines \
        core/schemas \
        core/standards \
        core/specs \
        release/references \
        release/schemas \
        release/specs \
        release/standards \
        .claude/rules \
        -type f -name '*.md' -print0 2>/dev/null
      /usr/bin/find operations/skills release/skills core/skills \
        -type f \( -name 'SKILL.md' -o -path '*/references/*.md' \) -print0 2>/dev/null
    )

    # Per-file × per-DC grep — output rows in `<file>:<line>:<DC>:<text>` form.
    local c23_dc_specs=(
      "DC1:$c23_dc1"
      "DC2:$c23_dc2"
      "DC3:$c23_dc3"
      "DC4:$c23_dc4"
      "DC6:$c23_dc6"
    )
    local c23_findings=0
    local c23_dc1_findings=0
    local c23_output=""
    local _file _spec _dc _pat _hits _line _lineno _text _nf_clean _pk_clean _pk_alt _pk_pat
    for _file in "${c23_files[@]}"; do
      for _spec in "${c23_dc_specs[@]}"; do
        _dc="${_spec%%:*}"
        _pat="${_spec#*:}"
        _hits=$(/usr/bin/grep -nE "$_pat" "$_file" 2>/dev/null) || _hits=""
        if [[ -n "$_hits" ]]; then
          while IFS= read -r _line; do
            _lineno="${_line%%:*}"
            _text="${_line#*:}"
            c23_output+="${_file}:${_lineno}:${_dc}:${_text}"$'\n'
            c23_findings=$((c23_findings + 1))
            [[ "$_dc" == DC1 ]] && c23_dc1_findings=$((c23_dc1_findings + 1))
          done <<< "$_hits"
        fi
      done
    done

    # DC1 needle pass — gitignored operator/coworker needles (names, org,
    # org-domain) via fixed-string match (no metachar escaping). Counts as DC1.
    _nf_clean=$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$c23_needles" 2>/dev/null) || _nf_clean=""
    if [[ -n "$_nf_clean" ]]; then
      for _file in "${c23_files[@]}"; do
        _hits=$(/usr/bin/grep -nFf <(printf '%s\n' "$_nf_clean") "$_file" 2>/dev/null) || _hits=""
        if [[ -n "$_hits" ]]; then
          while IFS= read -r _line; do
            _lineno="${_line%%:*}"; _text="${_line#*:}"
            c23_output+="${_file}:${_lineno}:DC1:${_text}"$'\n'
            c23_findings=$((c23_findings + 1)); c23_dc1_findings=$((c23_dc1_findings + 1))
          done <<< "$_hits"
        fi
      done
    fi

    # DC3 key pass — gitignored operator project keys (one per line). Builds a
    # `KEY1|KEY2|…` alternation, then reconstructs the three key-derived DC3
    # shapes the tracked detector deliberately omits: a key at a parameter seam
    # (`\b(KEYS)([-_/]| )`), a `<KEY>_FDD` filename prefix, and an `R-<KEY>-N`
    # requirement id. Counts as DC3 (signal-not-verdict). Absent/empty file →
    # skipped (no key-derived matching), so the shipped detector — and any
    # operator without this config — sees only the structural `projects/<Name>/`
    # pattern. Per line: strip a trailing inline `# comment`, trim surrounding
    # whitespace, then keep only lines matching the key-charset ([A-Za-z0-9_-]) —
    # so a line with internal whitespace or any regex metacharacter is dropped
    # and the file can never inject metacharacters into the ERE built below.
    _pk_clean=$(/usr/bin/sed -E 's/[[:space:]]*#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$c23_project_keys" 2>/dev/null \
      | /usr/bin/grep -E '^[A-Za-z0-9_-]+$' || true)
    if [[ -n "$_pk_clean" ]]; then
      _pk_alt=$(printf '%s' "$_pk_clean" | /usr/bin/paste -sd '|' - 2>/dev/null || true)
      if [[ -n "$_pk_alt" ]]; then
        _pk_pat="\\b(${_pk_alt})([-_/]|[[:space:]])|(${_pk_alt})_FDD|R-(${_pk_alt})-[0-9]+"
        for _file in "${c23_files[@]}"; do
          _hits=$(/usr/bin/grep -nE "$_pk_pat" "$_file" 2>/dev/null) || _hits=""
          if [[ -n "$_hits" ]]; then
            while IFS= read -r _line; do
              _lineno="${_line%%:*}"; _text="${_line#*:}"
              c23_output+="${_file}:${_lineno}:DC3:${_text}"$'\n'
              c23_findings=$((c23_findings + 1))
            done <<< "$_hits"
          fi
        done
      fi
    fi

    if [[ $c23_findings -eq 0 ]]; then
      log "  OK:    no DC1-DC4 + DC6 candidate signatures in scope (${#c23_files[@]} file(s) scanned; signal-not-verdict)"
    else
      # DC1 (organizational identity / PII) hard-enforces regardless of
      # deploy-check mode; DC2-DC6 stay signal-not-verdict (mode-driven warn)
      # because they legitimately over-flag (vendor names, project-key teaching
      # examples, accepted #N provenance refs per universal-vs-localized-context
      # §10.5.3). This is the DC1-only-enforce posture.
      if [[ ${c23_dc1_findings:-0} -gt 0 ]]; then
        log "  FAIL:  universal-vs-localized-context — ${c23_dc1_findings} DC1 PII signature(s) (ENFORCED — organizational identity / PII must not enter the corpus)"
        ISSUES=$((ISSUES + 1))
      fi
      local _c23_other=$((c23_findings - ${c23_dc1_findings:-0}))
      if [[ $_c23_other -gt 0 ]]; then
        flag_warn_or_issue "universal-vs-localized-context" \
          "$_c23_other DC2-DC6 candidate signature(s) across ${#c23_files[@]} file(s) — signal-not-verdict; see core/standards/universal-vs-localized-context.md §7 + §10"
      fi
      { printf '%s' "$c23_output" | head -10 | sed 's/^/         /' ; } || true
      if [[ $c23_findings -gt 10 ]]; then
        log "         ... ($((c23_findings - 10)) more; rerun directly for full output)"
      fi
    fi
  fi

  # ─── Check 26: Release-note presence (release-notes-standard.md AC#3) ──
  # Verifies every released version on or after the configurable cutoff
  # (default v1.00 — the first released version; override via
  # RELEASE_NOTE_CHECK_CUTOFF to scope to a later baseline) has
  # a corresponding ${PMO_INSTANCE_PATH}/releases/notes/vX.Y_RELEASE_NOTES.md file.
  #
  # Composes with — does NOT replace — Check 20 (note-content lint).
  # Check 20 lints CONTENT of notes that exist; Check 26 detects PRESENCE drift.
  #
  # Allowlist: .claude/skip-release-note-check.txt (one version per line; #
  # introduces comments). Operator adds in-progress backport versions
  # OR documented-deferred exceptions with inline rationale.
  #
  # Warn-mode initial per .claude/hooks/deploy-check.mode (Checks 8/9/10/
  # 14/15/18/19/20/21/22/25 precedent); flip-to-enforce after ≥3-day warn-log
  # review with zero false positives.
  #
  # Cutover: applies to releases entering Stage 13 strictly AFTER the
  # introducing release's merge SHA. That release is itself exempt
  # (reflexive-pipeline-loop discipline — the check shipping in a release cannot
  # fire on its own deploy without a loop; warn-mode means zero behavioral
  # impact at ship).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 26: Release-note presence (release-notes-standard.md AC#3)"
    local c26_log="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/RELEASE_LOG.md"
    local c26_allowlist=".claude/skip-release-note-check.txt"
    local c26_cutoff="${RELEASE_NOTE_CHECK_CUTOFF:-v1.00}"
    local c26_notes_dir="${PMO_INSTANCE_PATH:-$HOME/Claude/personal/pmo-instance}/releases/notes"

    if [[ ! -f "$c26_log" ]]; then
      flag_warn_or_issue "release-note-presence" \
        "RELEASE_LOG.md not found at $c26_log; cannot enumerate target releases"
    else
      # Enumerate DEPLOYED/VERIFIED versions from RELEASE_LOG.md
      # (one row per release; version in column 1; state in trailing pipe-separated column)
      local c26_versions
      c26_versions=$(/usr/bin/grep -oE '^\|[[:space:]]*v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?[[:space:]]*\|.*\b(DEPLOYED|VERIFIED)\b' "$c26_log" 2>/dev/null \
        | /usr/bin/sed -E 's/^\|[[:space:]]*//; s/[[:space:]]*\|.*$//' \
        | /usr/bin/sort -u || true)

      # Allowlist filter (exact version match; supports trailing # comment in allowlist file)
      c26_is_allowlisted() {
        local _v="$1"
        [[ -f "$c26_allowlist" ]] || return 1
        /usr/bin/grep -qE "^[[:space:]]*${_v//./\\.}[[:space:]]*(#.*)?\$" "$c26_allowlist"
      }

      # Cutoff filter (RELEASE_LOG order — chronological deploy order).
      # Implementation: walk versions; mark past_cutoff true on first match
      # of cutoff prefix; collect targets from then forward. Pre-cutoff
      # versions are excluded by definition.
      local c26_past_cutoff=false
      local c26_missing=()
      local c26_targets=0
      local _ver
      while IFS= read -r _ver; do
        [[ -n "$_ver" ]] || continue
        if [[ "$c26_past_cutoff" == "false" && "$_ver" == "$c26_cutoff"* ]]; then
          c26_past_cutoff=true
        fi
        [[ "$c26_past_cutoff" == "true" ]] || continue
        c26_is_allowlisted "$_ver" && continue
        c26_targets=$((c26_targets + 1))
        if [[ ! -f "${c26_notes_dir}/${_ver}_RELEASE_NOTES.md" ]]; then
          c26_missing+=("$_ver")
        fi
      done <<<"$c26_versions"

      if [[ "${#c26_missing[@]}" -eq 0 ]]; then
        log "  OK:    All $c26_targets released versions on/after $c26_cutoff have user-facing notes"
      else
        flag_warn_or_issue "release-note-presence" \
          "${#c26_missing[@]} missing user-facing note(s) for released versions: ${c26_missing[*]}"
      fi
    fi
  fi

  # ─── Check 27: Designated-model config for hub-spawned spokes ──
  # Per the Stage 5 ADR Dimension 6 (B): asserts every .claude/agents/pmo-*.md
  # file carries frontmatter `model: <expected-default>` where the default is
  # `opus`. Per-stage overrides are
  # declared in .claude/agents-model-overrides.txt (one `<agent-name> <model>`
  # entry per line; comments start with `#`); when present, the override value
  # is used as the expected per-agent default. File absence is tolerated
  # (defaults apply to all agents).
  #
  # Composition with the composite detection mechanism per Dimension 6:
  #   (A) spoke output `### Model Provenance` block — catches runtime drift
  #       (per hub-spoke-bridge.md Procedure 3 Spoke Template)
  #   (B) THIS CHECK — catches config drift (frontmatter wrong / missing)
  #   (C) Stage 8 QA Auditor LLM-graded review — catches hub-emit drift
  #       (per Stage 8 spoke-prompt instructions)
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks 8/9/10/14/
  # 15/18/19/20/21/22/25 precedent); flip-to-enforce after ≥2-3-release warn-log
  # review threshold.
  #
  # Cutover: applies to ./deploy.sh --check invocations occurring on or after
  # the introducing release's merge SHA recorded in RELEASE_LOG.md.
  # That release itself is exempt — reflexive-pipeline-loop discipline
  # (the check shipping in a release cannot fire on that release's own Stage 12
  # deploy-check without creating a loop; the .claude/agents/pmo-*.md
  # files are CREATED by that release, so the check cannot assert against
  # state that does not yet exist at Stage 12).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 27: Designated-model config for hub-spawned spokes (release/.claude/agents/pmo-*.md)"
    # Per the layout §1.4 agent definitions live under release/.claude/agents/.
    local c26_agents_dir="release/.claude/agents"
    local c26_overrides="release/.claude/agents-model-overrides.txt"
    # Fallback to workspace .claude/agents/ for backwards-compatibility during
    # transition window if the operator workspace has not yet been updated.
    [[ -d "$c26_agents_dir" ]] || c26_agents_dir=".claude/agents"
    [[ -f "$c26_overrides" ]] || c26_overrides=".claude/agents-model-overrides.txt"
    local c26_default_model="opus"
    local c26_findings=0
    local c26_output=""
    local c26_files_scanned=0

    # Helper: read override for a given agent name; emit override-model or default
    c26_expected_model() {
      local _agent_name="$1"
      local _override=""
      if [[ -f "$c26_overrides" ]]; then
        # Format: one `<agent-name> <model>` entry per line; `#` introduces comments
        # grep exits 1 when the agent has no override line; guard so the empty
        # result is tolerated rather than aborting under set -e + pipefail.
        _override=$(/usr/bin/grep -E "^[[:space:]]*${_agent_name}[[:space:]]+(sonnet|opus|haiku)" "$c26_overrides" 2>/dev/null | /usr/bin/awk '{print $2}' | /usr/bin/head -1) || _override=""
      fi
      if [[ -n "$_override" ]]; then
        printf '%s' "$_override"
      else
        printf '%s' "$c26_default_model"
      fi
    }

    if [[ ! -d "$c26_agents_dir" ]]; then
      flag_warn_or_issue "designated-model-config" \
        "$c26_agents_dir directory does not exist — expected per the Stage 5 ADR Dimension 2 (c)"
    else
      local _agent_file _agent_name _actual_model _expected_model
      for _agent_file in "$c26_agents_dir"/pmo-*.md; do
        [[ -f "$_agent_file" ]] || continue
        c26_files_scanned=$((c26_files_scanned + 1))
        _agent_name=$(/usr/bin/basename "$_agent_file" .md)
        # grep exits 1 when the agent file carries no `model:` line; guard so the
        # empty result flows to the missing-field branch below instead of aborting
        # under set -e + pipefail.
        _actual_model=$(/usr/bin/grep -E '^model:' "$_agent_file" 2>/dev/null | /usr/bin/head -1 | /usr/bin/awk '{print $2}') || _actual_model=""
        _expected_model=$(c26_expected_model "$_agent_name")
        if [[ -z "$_actual_model" ]]; then
          c26_output+="${_agent_file}: missing frontmatter \`model:\` field (expected: \`${_expected_model}\`)"$'\n'
          c26_findings=$((c26_findings + 1))
        elif [[ "$_actual_model" != "$_expected_model" ]]; then
          c26_output+="${_agent_file}: declares \`model: ${_actual_model}\`, expected \`${_expected_model}\`"$'\n'
          c26_findings=$((c26_findings + 1))
        fi
      done

      if [[ $c26_files_scanned -eq 0 ]]; then
        flag_warn_or_issue "designated-model-config" \
          "$c26_agents_dir/ contains zero pmo-*.md files — expected per the Stage 5 ADR Dimension 3 (7 spoke-type agent definitions)"
      elif [[ $c26_findings -eq 0 ]]; then
        log "  OK:    all $c26_files_scanned agent definition file(s) carry expected model field"
      else
        flag_warn_or_issue "designated-model-config" \
          "$c26_findings agent definition file(s) of $c26_files_scanned have model field drift — see protocol at release/references/how-to/hub-spoke-bridge.md § Spoke Launch Mechanisms — Model Parameter Required-Explicit"
        printf '%s' "$c26_output" | sed 's/^/         /'
      fi
    fi
  fi


  # ─── Check 28: Doc-impact resolution at Stage 13 close ──
  # Per the Stage 5 ADR D-EnforcementMechanism (A) — structural-only check that asserts
  # the per-issue Documentation Impact declaration (made at Stage 1 Intake via improvement.yml /
  # bug.yml) is resolved at Stage 13 Close. Companion to gate-criteria-spec.md Gate 13 G-CL8.
  #
  # Mechanism (full enforcement at Stage 13 close — release-context-specific):
  #   1. Read the release PR body's `### Documentation Impact` H3 section.
  #   2. For each in-PR issue row: parse declared docs + status.
  #   3. For each non-None declared doc: verify file exists AND was modified in
  #      `git log --follow <docs> origin/main..HEAD` (release branch commit range).
  #   4. NONE status rows: verify the corresponding issue body Documentation Impact field
  #      reads exactly `None — no documentation impact (rationale: <phrase>)`.
  #
  # Mechanism (deploy-time warn-mode shakedown — what this check fires on every ./deploy.sh --check):
  #   - Verify .github/PULL_REQUEST_TEMPLATE.md carries the `### Documentation Impact` H3 subsection.
  #   - Verify .github/ISSUE_TEMPLATE/{improvement.yml,bug.yml} carry the `Documentation Impact` field.
  #     This is the lightweight template-presence check (the leading indicator). Full per-PR
  #     per-issue verification (scanning recent release PRs + per-row declared-doc resolution)
  #     fires at Stage 13 release-context, invoked by the Stage 13 spoke at Phase A entry.
  #
  # The check is non-blocking pre-Stage-13: deploy.sh --check is invoked at many lifecycle
  # points (post-merge sync, session-start hygiene, mid-release drift detection). The
  # release-context-specific full check is invoked by the Stage 13 spoke at Phase A entry.
  # This deploy-time check enforces the PR-template adherence as the leading indicator.
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks 8/9/10/14/15/18/19/
  # 20/21/22/25/27/29 precedent); flip-to-enforce after ≥2-3-release warn-log review threshold
  # OR warn-log drained to < 10 entries (whichever first), per the Stage 5 D-Decision.
  #
  # Cutover: applies to ./deploy.sh --check invocations occurring on or after the
  # introducing release's merge SHA recorded in RELEASE_LOG.md. That
  # release itself is exempt — reflexive-pipeline-loop discipline (its bundled issues
  # were authored under pre-cutover improvement.yml without the Documentation Impact field;
  # retroactive Check 28 evaluation on its own PRs would fail by construction).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 28: Doc-impact resolution at Stage 13 close (scans recent release PRs for template adherence)"
    local c28_findings=0
    local c28_output=""
    local c28_prs_scanned=0
    local c28_pr_template=".github/PULL_REQUEST_TEMPLATE.md"

    # Lightweight deploy-time check: verify the PR template carries the Documentation Impact subsection.
    # The full per-PR per-issue verification fires at Stage 13 release-context (operator-invoked).
    if [[ ! -f "$c28_pr_template" ]]; then
      flag_warn_or_issue "doc-impact-resolution" \
        "$c28_pr_template does not exist — expected per the Stage 5 spec"
    else
      local _has_section
      _has_section=$(/usr/bin/grep -cE '^### Documentation Impact' "$c28_pr_template" 2>/dev/null || true); _has_section=${_has_section:-0}
      if [[ "$_has_section" -eq 0 ]]; then
        c28_output+="${c28_pr_template}: missing \`### Documentation Impact\` H3 subsection — required per the Stage 5 spec for Beat 2 surface"$'\n'
        c28_findings=$((c28_findings + 1))
      fi
    fi

    # Verify the issue templates carry the Documentation Impact field
    local _tmpl
    for _tmpl in ".github/ISSUE_TEMPLATE/improvement.yml" ".github/ISSUE_TEMPLATE/bug.yml"; do
      [[ -f "$_tmpl" ]] || continue
      local _has_field
      _has_field=$(/usr/bin/grep -cE 'label: Documentation Impact' "$_tmpl" 2>/dev/null || true); _has_field=${_has_field:-0}
      if [[ "$_has_field" -eq 0 ]]; then
        c28_output+="${_tmpl}: missing \`Documentation Impact\` field — required per the Stage 5 spec for Beat 1 declaration"$'\n'
        c28_findings=$((c28_findings + 1))
      fi
    done

    if [[ $c28_findings -eq 0 ]]; then
      log "  OK:    PR template + issue templates carry Documentation Impact surfaces per the spec"
    else
      flag_warn_or_issue "doc-impact-resolution" \
        "$c28_findings doc-impact surface drift finding(s) — see protocol at core/schemas/gate-criteria-spec.md Gate 13 G-CL8"
      printf '%s' "$c28_output" | sed 's/^/         /'
    fi
  fi


  # ─── Check 29: Return-value-conformance lint for hub-spawned spokes ──
  # Per the Stage 5 ADR Canonicalization 4 — asserts that every .claude/agents/pmo-*.md
  # body cross-references the canonical Return Value to Hub schema at
  # release/references/how-to/hub-spoke-bridge.md § Procedure 3 § Return Value to Hub.
  # The check is the deploy-time roster gate (companion to the routing-time hub-side
  # smoke-test at Procedure 4 entry + the review-time Stage 7 DT LLM-graded check).
  #
  # Mechanism: scan each .claude/agents/pmo-*.md for the H2 heading "## Return Value to Hub"
  # AND the literal cross-reference token "hub-spoke-bridge.md" within the same file.
  # Both signals together confirm the agent definition references the canonical schema
  # location. File absence is tolerated (defaults apply to all agents).
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks 8/9/10/14/15/18/23/
  # 25/27 precedent); flip-to-enforce after ≥2-3-release warn-log review threshold
  # per the Stage 5 D-Decision (warn-mode → enforce thresholds).
  #
  # Cutover: applies to ./deploy.sh --check invocations occurring on or after
  # the introducing release's merge SHA recorded in RELEASE_LOG.md.
  # That release itself is exempt — reflexive-pipeline-loop discipline
  # (the check shipping in a release cannot fire on that release's own Stage 12
  # deploy-check without creating a loop; the .claude/agents/pmo-*.md
  # files receive their Return Value to Hub H2 sections AS PART OF that release).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 29: Return-value-conformance for hub-spawned spokes (release/.claude/agents/pmo-*.md)"
    # Per the layout §1.4 agent definitions live under release/.claude/agents/.
    local c29_agents_dir="release/.claude/agents"
    # Fallback to workspace .claude/agents/ for backwards-compatibility.
    [[ -d "$c29_agents_dir" ]] || c29_agents_dir=".claude/agents"
    local c29_findings=0
    local c29_output=""
    local c29_files_scanned=0

    if [[ ! -d "$c29_agents_dir" ]]; then
      flag_warn_or_issue "return-value-conformance" \
        "$c29_agents_dir directory does not exist — expected per the Stage 5 spec"
    else
      local _agent_file _agent_name _has_h2 _has_xref
      for _agent_file in "$c29_agents_dir"/pmo-*.md; do
        [[ -f "$_agent_file" ]] || continue
        c29_files_scanned=$((c29_files_scanned + 1))
        _agent_name=$(/usr/bin/basename "$_agent_file" .md)
        _has_h2=$(/usr/bin/grep -cE '^## Return Value to Hub' "$_agent_file" 2>/dev/null || true); _has_h2=${_has_h2:-0}
        _has_xref=$(/usr/bin/grep -cE 'hub-spoke-bridge\.md' "$_agent_file" 2>/dev/null || true); _has_xref=${_has_xref:-0}
        if [[ "$_has_h2" -eq 0 ]]; then
          c29_output+="${_agent_file}: missing \`## Return Value to Hub\` H2 — see schema at release/references/how-to/hub-spoke-bridge.md § Procedure 3"$'\n'
          c29_findings=$((c29_findings + 1))
        elif [[ "$_has_xref" -eq 0 ]]; then
          c29_output+="${_agent_file}: has \`## Return Value to Hub\` H2 but no \`hub-spoke-bridge.md\` cross-reference — schema must cite canonical location"$'\n'
          c29_findings=$((c29_findings + 1))
        fi
      done

      if [[ $c29_files_scanned -eq 0 ]]; then
        flag_warn_or_issue "return-value-conformance" \
          "$c29_agents_dir/ contains zero pmo-*.md files — expected per the Stage 5 spec (7 spoke-type agent definitions)"
      elif [[ $c29_findings -eq 0 ]]; then
        log "  OK:    all $c29_files_scanned agent definition file(s) reference the Return Value to Hub schema"
      else
        flag_warn_or_issue "return-value-conformance" \
          "$c29_findings agent definition file(s) of $c29_files_scanned have return-value-schema drift — see schema at release/references/how-to/hub-spoke-bridge.md § Procedure 3 § Return Value to Hub"
        printf '%s' "$c29_output" | sed 's/^/         /'
      fi
    fi
  fi


  # ─── Check 30: Slash-command quoting lint ───────────────────
  # Per the Stage 5 spec D-Lint — scans pmo-authored slash command source
  # files under harness/*/commands/*.md for unquoted `$ARGUMENTS` references in
  # Bash-execution context (a `!` exec-line per slash-command convention). The
  # check structure is RETAINED for future-proofing (when v2 ships
  # new harness artifacts with slash commands); harness/ at v2 root does not
  # exist yet (account-switcher extracted at Phase 3), so the find
  # yields zero files and the check no-ops cleanly with the "lint skipped"
  # message.
  #
  # Source-level quoting is the pmo-author-time prevention layer; the execute-
  # time defense is the core/hooks/block-shell-injection.sh PreToolUse hook
  # (BLOCK-SHELL-INJECTION-001..002) per the HYBRID mitigation per Stage 5 R1.
  #
  # Mechanism: iterate over `find harness -path "*/commands/*.md"` at v2 root;
  # for each file scan for lines matching `^!.*\$ARGUMENTS` (slash-command
  # exec-line shape) where `$ARGUMENTS` is NOT surrounded by double quotes.
  # File absence is tolerated (no slash commands authored at v2 ship).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 30: Slash-command quoting lint (pmo-authored *.md under harness/*/commands/)"
    local c30_findings=0
    local c30_output=""
    local c30_files_scanned=0
    local _cmd_file _violations

    # Collect candidate files via find (NUL-delimited for safe iteration).
    # harness/ does not exist at v2 root; find yields no files cleanly.
    local c30_tmp
    c30_tmp="$(/usr/bin/mktemp)"
    /usr/bin/find harness -type f -name "*.md" -path "*/commands/*" -print0 > "$c30_tmp" 2>/dev/null || true

    while IFS= read -r -d '' _cmd_file; do
      c30_files_scanned=$((c30_files_scanned + 1))
      _violations="$(/usr/bin/grep -nE '^!.*\$ARGUMENTS' "$_cmd_file" 2>/dev/null | \
        /usr/bin/grep -vE '"\$ARGUMENTS"' || true)"
      if [[ -n "$_violations" ]]; then
        while IFS= read -r _v_line; do
          [[ -z "$_v_line" ]] && continue
          local _v_num
          _v_num="$(printf '%s' "$_v_line" | /usr/bin/cut -d: -f1)"
          c30_output+="${_cmd_file}:${_v_num}: unquoted \$ARGUMENTS in Bash-exec line — wrap with double quotes (\"\$ARGUMENTS\")"$'\n'
          c30_findings=$((c30_findings + 1))
        done <<< "$_violations"
      fi
    done < "$c30_tmp"
    /bin/rm -f "$c30_tmp"

    if [[ $c30_files_scanned -eq 0 ]]; then
      log "  SKIP:  harness/*/commands/ — no slash command files in scope (account-switcher extracted at Phase 3)"
    elif [[ $c30_findings -eq 0 ]]; then
      log "  OK:    all $c30_files_scanned pmo-authored slash command file(s) have properly-quoted \$ARGUMENTS in Bash-exec context"
    else
      flag_warn_or_issue "slash-command-quoting" \
        "$c30_findings unquoted \$ARGUMENTS occurrence(s) across $c30_files_scanned scanned file(s) — see the § Coverage rationale"
      printf '%s' "$c30_output" | sed 's/^/         /'
    fi
  fi

  # ─── Check 31: Reference-durability saturation (reference-durability issue) ──
  # Sibling to Check 14 (doc-link maintenance). Scans the durable-corpus globs for
  # fragile-reference saturation per core/standards/reference-durability-standard.md:
  # Class L (markdown links), Class V (version-cutover apparatus), and the positional
  # issue-reference rule. The check reports the current saturation SNAPSHOT; the
  # reference-durability CI workflow enforces the DELTA (no new violations vs base).
  #
  # Precision probe (per the adversarial-review CDF-2 amendment): the check first runs
  # the checked-in fixture self-test (core/hooks/testdata/cutover-fixtures.txt via
  # core/hooks/run-fragile-ref-fixtures.sh). A warn-log is blind to false negatives,
  # so the fixture is the only measurable precision gate; a fixture regression is a
  # hard FAIL regardless of warn-mode (the detector itself is broken).
  #
  # Mode-gated via $DEPLOY_CHECK_MODE (warn/enforce/off); saturation findings route
  # through flag_warn_or_issue. Net-new saturation semantics: the snapshot count is
  # informational in warn-mode; CI gates added-line deltas. Honors the same path
  # allowlist + per-file override markers as the hook.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 31: Reference-durability saturation (durable-corpus fragile refs)"
    local c31_fixture="core/hooks/testdata/cutover-fixtures.txt"
    local c31_runner="core/hooks/run-fragile-ref-fixtures.sh"
    local c31_allowlist="core/hooks/reference-durability-allowlist.txt"

    # --- precision probe: fixture self-test (hard FAIL on regression) ---
    if [[ -x "$c31_runner" && -f "$c31_fixture" ]]; then
      local c31_probe_out c31_probe_rc=0
      c31_probe_out=$("$c31_runner" "$c31_fixture" 2>&1) || c31_probe_rc=$?
      if [[ $c31_probe_rc -ne 0 ]]; then
        log "  FAIL:  reference-durability detector precision regression — fixture self-test failed"
        echo "$c31_probe_out" | sed 's/^/         /'
        ISSUES=$((ISSUES + 1))
      else
        log "  OK:    detector precision probe — $(echo "$c31_probe_out" | tr -d '\n')"
      fi
    else
      flag_warn_or_issue "reference-durability" "fixture probe unavailable (missing $c31_runner or $c31_fixture)"
    fi

    # --- saturation scan over durable-corpus globs ---
    # Class L + Class V regexes — byte-identical to core/hooks/block-fragile-refs.sh.
    local c31_link_re='\]\('
    local c31_cutover_re='v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?[^.\n]{0,40}merge SHA|v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?([[:space:]]+(release|itself|is))*[[:space:]]+(is[[:space:]]+)?exempt|([Aa]pplies to releases|[Cc]utover[[:space:]]+(applies|discipline|per))[^.\n]{0,80}v[0-9]+\.[0-9]+|reflexive-pipeline-loop'
    local -a c31_globs=(
      "core/rules" "core/standards" "core/specs" "core/disciplines" "core/schemas"
      "release/references" "release/governance" "release/standards" "release/specs" "release/schemas"
    )
    local c31_link_count=0 c31_version_count=0 c31_files_scanned=0
    local _d _f
    for _d in "${c31_globs[@]}"; do
      [[ -d "$_d" ]] || continue
      while IFS= read -r -d '' _f; do
        # skip allowlisted directories (prefix match)
        local _skip=0
        if [[ -f "$c31_allowlist" ]]; then
          local _g
          while IFS= read -r _g || [[ -n "$_g" ]]; do
            _g="${_g%%#*}"; _g="$(echo "$_g" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
            [[ -z "$_g" ]] && continue
            case "$_g" in
              */) [[ "$_f" == *"$_g"* ]] && _skip=1 ;;
              *)  [[ "$_f" == *"/$_g" || "$_f" == "$_g" ]] && _skip=1 ;;
            esac
          done < "$c31_allowlist"
        fi
        [[ $_skip -eq 1 ]] && continue
        c31_files_scanned=$((c31_files_scanned + 1))
        # strip fenced code blocks before counting
        local _stripped
        _stripped=$(awk '/^[[:space:]]*```/ { f=!f; next } !f { print }' "$_f" 2>/dev/null)
        # per-file override markers
        local _allow_link=0 _allow_version=0
        echo "$_stripped" | grep -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-link[[:space:]]*-->' && _allow_link=1
        echo "$_stripped" | grep -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-version-ref[[:space:]]*-->' && _allow_version=1
        if [[ $_allow_link -eq 0 ]]; then
          local _lc
          _lc=$(echo "$_stripped" | grep -cE "$c31_link_re" || true)
          c31_link_count=$((c31_link_count + _lc))
        fi
        if [[ $_allow_version -eq 0 ]]; then
          local _vc
          _vc=$(echo "$_stripped" | grep -cE "$c31_cutover_re" || true)
          c31_version_count=$((c31_version_count + _vc))
        fi
      done < <(find "$_d" -type f -name '*.md' -print0 2>/dev/null)
    done

    local c31_total=$((c31_link_count + c31_version_count))
    if [[ $c31_total -eq 0 ]]; then
      log "  OK:    no fragile-reference saturation across $c31_files_scanned durable-corpus file(s)"
    else
      flag_warn_or_issue "reference-durability" \
        "$c31_total fragile-reference saturation marker(s) across $c31_files_scanned durable-corpus file(s) (Class L: $c31_link_count, Class V: $c31_version_count) — pre-existing rot drains via the backfill counterpart; the CI delta gates net-new. See core/standards/reference-durability-standard.md"
    fi
  fi


  # ─── Check 32: Release-corpus completeness (every RELEASE_LOG row implies its corpus) ──
  # Per the release-corpus completeness forcing-function. Stage 13 Close produces four
  # release-corpus artifacts — RELEASE_LOG row, RELEASE_INDEX row, RELEASE_DIGEST entry,
  # and a notes/<slug>_RELEASE_NOTES.md file — plus (for post-cutover rows) a signed
  # tag and a published GitHub Release. Nothing previously asserted all were produced;
  # the canonical incident closed a release with only the RELEASE_LOG row, the
  # INDEX/DIGEST/NOTES silently missing until manual review. This check is the
  # mechanical backstop that converts the documented-but-skippable "Appended at
  # Stage 13" convention into a guard.
  #
  # Direction (LOG is authoritative): the check is LOG-row-driven. For every release
  # row in the IN-REPO ledger (release/releases/RELEASE_LOG.md) at/after the cutover,
  # it asserts the matching INDEX row + DIGEST entry + NOTES file exist. Rows present
  # in INDEX/DIGEST but absent from the LOG are NOT flagged (the LOG is the closed
  # set of releases; Check 23 separately reconciles LOG<->INDEX drift on the instance
  # corpus). This in-repo target differs deliberately from Check 23/26 (which read the
  # operator-instance ${PMO_INSTANCE_PATH} corpus) — the tracked release/releases/
  # ledger is the surface where the incident occurred and the one shipped in this repo.
  #
  # NOTES filename resolution (historical-tolerant): the notes file is accepted under
  # EITHER notes/<version>_RELEASE_NOTES.md OR notes/<milestone-slug>_RELEASE_NOTES.md.
  # Early rows named the file by version stem (v1.01_RELEASE_NOTES.md); later rows name
  # it by milestone slug (<slug>_RELEASE_NOTES.md). Accepting both prevents a
  # false-positive on the legitimate historical naming.
  #
  # Allowlist: .claude/skip-release-corpus-check.txt (one version per line; # comments).
  # Operator adds documented-deferred exceptions with inline rationale. File absence is
  # tolerated.
  #
  # Warn-mode initial per .claude/hooks/deploy-check.mode (Checks 8/9/10/14/15/18/19/
  # 20/21/22/23/25/26/27/28/29/31 precedent); flip-to-enforce after >=3-day warn-log
  # review with zero false positives.
  #
  # CUTOVER-SCOPED (the top risk): the 3-artifact assertion runs only for LOG rows
  # at/after $c32_cutoff (default v1.01 — the first corpus-era release; rows below it
  # are pre-corpus and exempt by definition, walked in LOG file order like Check 26).
  # The stricter signed-tag + published-Release assertions run only for rows at/after
  # the SEPARATE, later $c32_release_cutoff. That cutoff defaults to a sentinel
  # (__none__) so the network-dependent published-Release sub-check is DORMANT until an
  # operator opts in — this reuses the pre-Release SKIP / N-A semantics of
  # stage-13-close.md Phase B5.5 + automated-closeout.sh phase 9.5: a row that predates
  # the artifact it checks resolves to N/A, never FAIL. A gate that retroactively failed
  # legitimate historical rows (early v1.0x lacking a published Release) would be worse
  # than no gate. The signed-tag presence sub-check reads the LOG row's own Tag column
  # (in-corpus; no network) and is therefore safe to run from $c32_release_cutoff
  # offline; the published-Release sub-check requires `gh` + network and resolves to N/A
  # when either is unavailable.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 32: Release-corpus completeness (RELEASE_LOG row -> INDEX + DIGEST + NOTES [+ tag + Release post-cutover])"
    local c32_log="release/releases/RELEASE_LOG.md"
    local c32_index="release/releases/RELEASE_INDEX.md"
    local c32_digest="release/releases/RELEASE_DIGEST.md"
    local c32_notes_dir="release/releases/notes"
    local c32_allowlist=".claude/skip-release-corpus-check.txt"
    local c32_cutoff="${RELEASE_CORPUS_CHECK_CUTOFF:-v1.01}"
    # Separate, later cutover for the network/tag stricter assertions. Sentinel
    # __none__ => no row is post-Release-cutover (published-Release sub-check dormant).
    local c32_release_cutoff="${RELEASE_CORPUS_RELEASE_CUTOFF:-__none__}"

    if [[ ! -f "$c32_log" ]]; then
      flag_warn_or_issue "release-corpus-completeness" \
        "$c32_log not found; cannot enumerate logged releases"
    else
      # Allowlist filter (exact version match; trailing # comment supported)
      c32_is_allowlisted() {
        local _v="$1"
        [[ -f "$c32_allowlist" ]] || return 1
        /usr/bin/grep -qE "^[[:space:]]*${_v//./\\.}[[:space:]]*(#.*)?\$" "$c32_allowlist"
      }

      # Enumerate logged releases in LOG file order: emit "version|milestone|tag"
      # for each `| vX.Y[...] | <milestone> | ... | <tag> | <state> | <date> |` row.
      # Field 2 (awk -F ' | ') = version, field 3 = milestone, field 7 = tag column.
      # The Tag column may carry a backtick-wrapped value (`v1.01`) or an em-dash.
      # grep exits 1 when the log carries no matching version rows; guard so the
      # empty enumeration is tolerated rather than aborting under set -e + pipefail.
      local c32_rows
      c32_rows=$(/usr/bin/grep -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$c32_log" 2>/dev/null \
        | /usr/bin/awk -F ' \\| ' '{
            v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v);
            ms=$2; sub(/^[[:space:]]*/,"",ms); sub(/[[:space:]]*$/,"",ms);
            tg=$6; gsub(/`/,"",tg); sub(/^[[:space:]]*/,"",tg); sub(/[[:space:]]*$/,"",tg);
            print v "|" ms "|" tg
          }') || c32_rows=""

      local c32_past_cutoff=false
      local c32_past_release_cutoff=false
      local c32_targets=0
      local c32_findings=0
      local c32_output=""
      local _row _ver _ms _tag _notes_ok _release_eligible
      while IFS= read -r _row; do
        [[ -n "$_row" ]] || continue
        _ver="${_row%%|*}"
        _ms="${_row#*|}"; _ms="${_ms%%|*}"
        _tag="${_row##*|}"

        # 3-artifact cutover gate (walk LOG order; arm on first cutoff-prefix match)
        if [[ "$c32_past_cutoff" == "false" && "$_ver" == "$c32_cutoff"* ]]; then
          c32_past_cutoff=true
        fi
        [[ "$c32_past_cutoff" == "true" ]] || continue
        c32_is_allowlisted "$_ver" && continue
        c32_targets=$((c32_targets + 1))

        # (a) INDEX row present (version is the first table cell)
        if ! /usr/bin/grep -qE "^\|[[:space:]]*${_ver//./\\.}[[:space:]]*\|" "$c32_index" 2>/dev/null; then
          c32_output+="${_ver}: missing RELEASE_INDEX.md row"$'\n'
          c32_findings=$((c32_findings + 1))
        fi

        # (b) DIGEST entry present (### vX.YZ <space> H3 heading)
        if ! /usr/bin/grep -qE "^### ${_ver//./\\.}[[:space:](]" "$c32_digest" 2>/dev/null; then
          c32_output+="${_ver}: missing RELEASE_DIGEST.md entry (### ${_ver} ...)"$'\n'
          c32_findings=$((c32_findings + 1))
        fi

        # (c) NOTES file present under EITHER version stem OR milestone slug
        _notes_ok=0
        [[ -f "${c32_notes_dir}/${_ver}_RELEASE_NOTES.md" ]] && _notes_ok=1
        [[ -n "$_ms" && -f "${c32_notes_dir}/${_ms}_RELEASE_NOTES.md" ]] && _notes_ok=1
        if [[ $_notes_ok -eq 0 ]]; then
          c32_output+="${_ver}: missing notes file (${_ver}_RELEASE_NOTES.md or ${_ms}_RELEASE_NOTES.md)"$'\n'
          c32_findings=$((c32_findings + 1))
        fi

        # Stricter post-Release-cutover assertions (tag + published Release).
        # Dormant when c32_release_cutoff is the __none__ sentinel.
        _release_eligible=0
        if [[ "$c32_release_cutoff" != "__none__" ]]; then
          if [[ "$c32_past_release_cutoff" == "false" && "$_ver" == "$c32_release_cutoff"* ]]; then
            c32_past_release_cutoff=true
          fi
          [[ "$c32_past_release_cutoff" == "true" ]] && _release_eligible=1
        fi

        if [[ $_release_eligible -eq 1 ]]; then
          # (d) signed-tag presence — read from the LOG Tag column (in-corpus; no network).
          # Empty / em-dash Tag column => missing tag for a post-cutover row.
          if [[ -z "$_tag" || "$_tag" == "—" || "$_tag" == "-" ]]; then
            c32_output+="${_ver}: post-Release-cutover row has no tag recorded in RELEASE_LOG Tag column"$'\n'
            c32_findings=$((c32_findings + 1))
          fi
          # (e) published GitHub Release — network-dependent; N/A (never FAIL) when
          # gh/network unavailable, reusing pre-Release SKIP semantics.
          if command -v gh >/dev/null 2>&1; then
            if ! gh release view "$_ver" >/dev/null 2>&1; then
              # Distinguish "absent" from "unreachable": a generic gh failure (auth/
              # network) must NOT be treated as a missing Release (N/A, not FAIL).
              if gh auth status >/dev/null 2>&1; then
                c32_output+="${_ver}: post-Release-cutover row has no published GitHub Release (gh release view returned non-zero)"$'\n'
                c32_findings=$((c32_findings + 1))
              else
                log "  N/A:   ${_ver} published-Release sub-check skipped (gh unauthenticated/offline) — reuses pre-Release SKIP semantics"
              fi
            fi
          else
            log "  N/A:   ${_ver} published-Release sub-check skipped (gh not on PATH) — reuses pre-Release SKIP semantics"
          fi
        fi
      done <<<"$c32_rows"

      if [[ $c32_findings -eq 0 ]]; then
        log "  OK:    all $c32_targets logged release(s) on/after $c32_cutoff have INDEX + DIGEST + NOTES (Release-cutover: $c32_release_cutoff)"
      else
        flag_warn_or_issue "release-corpus-completeness" \
          "$c32_findings corpus-completeness finding(s) across $c32_targets logged release(s) — a close dropped an output; see release/references/pipeline/stage-13-close.md Phase B"
        printf '%s' "$c32_output" | head -10 | sed 's/^/         /'
        if [[ $c32_findings -gt 10 ]]; then
          log "         ... ($((c32_findings - 10)) more)"
        fi
      fi
    fi
  fi

  # Check 33 — Platform-config surface integrity (adapter-config-foundation, #22).
  # Asserts: (a) core/config/platform-config.toml.template exists + parses as TOML
  # (every non-comment, non-blank, non-section line is a `key = value` assignment);
  # (b) every field documented in the schema's [meta]/[bundling]/[release_class]/
  # [relationship_mapping]/[calibration] categories ships a default value in the
  # template (the resolver's "common case" rung-1 contract) — the allowlist below
  # is the explicit field set gated for default-presence (a field absent from it
  # is unchecked, NOT validated; release_class_capacity_weights is included so the
  # risk-weighted-capacity field is gated, not merely parse-clean; mode_a_parse_rate_floor
  # is included so the G3-14 parse-rate floor field ships a default); (c) the legacy
  # operator.toml [platform].work_board alias is preserved (NOT removed) alongside
  # the new [adapters].ticketing. Warn-mode initial (flag_warn_or_issue) per the
  # shakedown posture for new checks.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 33: Platform-config surface integrity (#22)"
    local c33_tmpl="core/config/platform-config.toml.template"
    local c33_op="core/config/operator.toml.template"
    local c33_findings=0

    if [[ ! -f "$c33_tmpl" ]]; then
      flag_warn_or_issue "platform-config-surface" \
        "$c33_tmpl not found — the platform-config surface is missing"
    else
      # (a) TOML parse: strip comments + blanks + section headers, then assert
      # every remaining line is `key = value`.
      local c33_bad_lines
      c33_bad_lines=$(/usr/bin/grep -vE '^[[:space:]]*(#|$|\[)' "$c33_tmpl" 2>/dev/null \
        | /usr/bin/grep -vE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=' 2>/dev/null \
        | /usr/bin/wc -l | /usr/bin/tr -d ' ') || c33_bad_lines=0
      if [[ "$c33_bad_lines" -ne 0 ]]; then
        c33_findings=$((c33_findings + 1))
        log "  detail: $c33_bad_lines non-assignment line(s) in $c33_tmpl (TOML parse)"
      fi

      # (b) every required field ships a default (a `field = <non-empty>` line).
      # type_mapping_overrides legitimately defaults to an empty table `{}`, which
      # is non-empty after the `=`, so the same \S assertion covers it.
      local _f
      for _f in schema_version managed_by bundle_doctrine_frame release_size_target_pts \
                release_class_capacity_weights mode_a_parse_rate_floor \
                default_release_class source_systems maintenance_posture \
                type_mapping_overrides releases_since_calibration; do
        if ! /usr/bin/grep -qE "^[[:space:]]*${_f}[[:space:]]*=[[:space:]]*\S" "$c33_tmpl" 2>/dev/null; then
          c33_findings=$((c33_findings + 1))
          log "  detail: field '$_f' has no default value in $c33_tmpl"
        fi
      done

      # cross-check: resolve_platform_config returns the documented default from
      # the in-repo template (exercises the rung-reader on the global rung).
      local _bdf
      _bdf="$(resolve_platform_config bundle_doctrine_frame)"
      if [[ "$_bdf" != "F1" ]]; then
        c33_findings=$((c33_findings + 1))
        log "  detail: resolve_platform_config bundle_doctrine_frame returned '$_bdf' (expected F1)"
      fi
    fi

    # (c) operator.toml [adapters] table + preserved legacy work_board alias.
    if [[ -f "$c33_op" ]]; then
      if ! /usr/bin/grep -qE '^\[adapters\]' "$c33_op" 2>/dev/null; then
        c33_findings=$((c33_findings + 1))
        log "  detail: operator.toml.template missing [adapters] table (#703 seam)"
      fi
      local _ad
      for _ad in repo_host ticketing kb ai_tool; do
        if ! /usr/bin/grep -qE "^[[:space:]]*${_ad}[[:space:]]*=[[:space:]]*\S" "$c33_op" 2>/dev/null; then
          c33_findings=$((c33_findings + 1))
          log "  detail: operator.toml.template [adapters].$_ad has no default"
        fi
      done
      # work_board alias preserved (reconciled by deprecation, NOT removed)
      if ! /usr/bin/grep -qE '^[[:space:]]*work_board[[:space:]]*=' "$c33_op" 2>/dev/null; then
        c33_findings=$((c33_findings + 1))
        log "  detail: operator.toml.template [platform].work_board alias was removed (must be preserved as a deprecation alias superseded by [adapters].ticketing (see ADR-022))"
      fi
    else
      flag_warn_or_issue "platform-config-surface" "$c33_op not found"
    fi

    if [[ $c33_findings -eq 0 ]]; then
      log "  OK:    platform-config.toml.template parses + all fields have defaults; operator.toml [adapters] present; work_board alias preserved"
    else
      flag_warn_or_issue "platform-config-surface" \
        "$c33_findings platform-config surface finding(s) — see core/schemas/platform-config-schema.md + core/config/*.template"
    fi
  fi

  # ─── Check 34: Template↔schema conformance (contract-fidelity; warn-mode initial) ───
  # A THIRD fidelity axis, distinct from Check 13 (canonical↔mirror COPY-fidelity,
  # byte-identity) and Check 13b (unregistered shared-reference collision): Check 34
  # asserts a schema-BEARING canonical template carries every section its governing
  # schema mandates. A canonical template can otherwise drift from the schema that
  # governs its instances and no gate catches it (#318).
  #
  # Schema-bearing set = TEMPLATE_SCHEMA_MAP membership (opt-in by manifest presence).
  # A template with NO entry here is NEVER inspected — structural skip, zero false
  # positives by construction (parent AC#4). Extend coverage by ADDING a manifest
  # line (register-or-extend per template-storage.md §3.5b).
  #
  # Manifest tuple (4 fields, '|||'-delimited — the field separator is '|||' rather
  # than ':' because the schema-anchor field legitimately contains a ': ', e.g.
  # "Tracker 3: Open Meetings Tracker"; the section list inside field 4 stays
  # pipe-delimited):
  #   field 1  <template-path>
  #   field 2  <governing-schema-path>
  #   field 3  <schema H2 anchor>  (the "## <anchor>" heading bounding the schema block)
  #   field 4  <pipe-delimited expected H2 sections the template MUST carry>
  # Fields are split with `awk -F'\|\|\|'` (NOT `IFS='|||' read`, which bash collapses
  # to single-'|' separators and silently empties fields 2/3).
  #
  # Warn-mode initial via flag_warn_or_issue / deploy-check.mode (the Checks 8-10 /
  # 13b / 14 / 33 precedent): in warn-mode a breach logs WARN: + appends
  # deploy-check-warn-log.jsonl WITHOUT incrementing ISSUES; in enforce-mode it
  # increments ISSUES so `--check` (STRICT) exits non-zero on a real divergence.
  # Flip-to-enforce path: template-storage.md §3.5b + bypass-mode-readiness.md
  # Shakedown→Enforce checklist + the runtime deploy-check.mode file.
  local -a TEMPLATE_SCHEMA_MAP=(
    "operations/templates/open-meetings-tracker-template.md|||core/schemas/tracker-schemas.md|||Tracker 3: Open Meetings Tracker|||Upcoming Meetings|Recently Completed|Recurring Cadences"
  )

  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 34: Template↔schema conformance (contract-fidelity)"
    local c34_any_finding=false
    local c34_entry
    for c34_entry in "${TEMPLATE_SCHEMA_MAP[@]}"; do
      # Field split on the literal '|||' (CD-1: awk, not IFS-read).
      local c34_tmpl c34_schema c34_anchor c34_expect
      c34_tmpl=$(awk -F'\\|\\|\\|'   '{print $1}' <<< "$c34_entry")
      c34_schema=$(awk -F'\\|\\|\\|' '{print $2}' <<< "$c34_entry")
      c34_anchor=$(awk -F'\\|\\|\\|' '{print $3}' <<< "$c34_entry")
      c34_expect=$(awk -F'\\|\\|\\|' '{print $4}' <<< "$c34_entry")

      # Presence guards (no false-fail on environmental gaps).
      # Template absent → SKIP (Check 12/13 own presence; do not double-fail).
      if [[ ! -f "$c34_tmpl" ]]; then
        log "  SKIP:  $c34_tmpl absent (Check 12/13 own presence)"
        continue
      fi
      # Governing schema absent → that IS a contract breach (the schema vanished).
      if [[ ! -f "$c34_schema" ]]; then
        flag_warn_or_issue "template-schema-conformance" \
          "$c34_tmpl: governing schema $c34_schema not found"
        c34_any_finding=true
        continue
      fi

      # Schema block = lines from "## <anchor>" up to the next "## " (or EOF).
      local c34_schema_block
      c34_schema_block=$(awk -v anchor="## ${c34_anchor}" '
        $0 == anchor { grab=1; next }
        grab && /^## / { exit }
        grab { print }
      ' "$c34_schema")
      if [[ -z "$c34_schema_block" ]]; then
        # Anchor not found in the schema → the manifest points at a section that
        # no longer exists. Treat as a contract breach (manifest↔schema drift).
        flag_warn_or_issue "template-schema-conformance" \
          "$c34_tmpl: schema anchor '## $c34_anchor' not found in $c34_schema (manifest↔schema drift)"
        c34_any_finding=true
        continue
      fi

      # Split the expected-sections pipe-list into an array.
      local -a c34_sections
      IFS='|' read -r -a c34_sections <<< "$c34_expect"

      # MISSING = expected sections not present as a "## <section>" heading in the
      # template (the load-bearing contract assertion). The Header (a '#'-level
      # title + metadata) and any extra '## CHANGE SUMMARY' log section are NOT in
      # the expected list, so an extra template section is allowed — only a MISSING
      # mandated section breaches the contract.
      local c34_missing=""
      # A-318-1: manifest↔schema cross-check elevated MAY→SHOULD — each expected
      # section name SHOULD also appear in the schema block; a mismatch warns
      # (guards the field-4-hardcodes-schema-sections coupling against drift).
      local c34_schema_drift=""
      local c34_sec
      for c34_sec in "${c34_sections[@]}"; do
        if ! grep -qxF "## ${c34_sec}" "$c34_tmpl"; then
          c34_missing="${c34_missing:+$c34_missing, }${c34_sec}"
        fi
        if ! printf '%s\n' "$c34_schema_block" | grep -qF "$c34_sec"; then
          c34_schema_drift="${c34_schema_drift:+$c34_schema_drift, }${c34_sec}"
        fi
      done

      # A-318-1 (SHOULD): manifest field-4 vs schema block. A drift here means the
      # manifest's expected-sections no longer match the schema it cites — warn so
      # the coupling is re-reconciled (separate from the template breach below).
      if [[ -n "$c34_schema_drift" ]]; then
        flag_warn_or_issue "template-schema-conformance" \
          "$c34_schema §$c34_anchor: manifest expected-section(s) not found in schema block: $c34_schema_drift (manifest↔schema drift — reconcile TEMPLATE_SCHEMA_MAP field 4)"
        c34_any_finding=true
      fi

      # Conformance assertion (load-bearing for AC#1): a MISSING mandated section
      # is the contract breach.
      if [[ -n "$c34_missing" ]]; then
        flag_warn_or_issue "template-schema-conformance" \
          "$c34_tmpl missing schema-mandated section(s): $c34_missing (per $c34_schema §$c34_anchor)"
        c34_any_finding=true
      else
        log "  OK:    $c34_tmpl conforms to $c34_schema §$c34_anchor"
      fi
    done
    [[ "$c34_any_finding" == "false" ]] && \
      log "  OK:    all ${#TEMPLATE_SCHEMA_MAP[@]} schema-bearing template(s) conform to their governing schema"
  fi


  # Check 35 — Mode-invocation drift (warn-mode initial, #26). Config-drift
  # surface of the mode-invocation composite detection mechanism — companion to
  # the Procedure 3 Spoke Template `### Mode Provenance` block (runtime-drift
  # surface) and the Stage 8 QA LLM-graded review (hub-emit surface). Where Check
  # 27 + the `### Model Provenance` block catch model drift, this check + the
  # `### Mode Provenance` block catch mode drift (a spoke silently skipping or
  # mis-selecting a required mode).
  #
  # Scans the multi-mode SKILL.md population across all three module skill dirs
  # and asserts each multi-mode skill carries a MACHINE-RECOGNIZABLE mode-enum,
  # so the runtime block's "Invoked mode" can be validated against a real enum
  # rather than free prose. It does NOT demand a new frontmatter field — it
  # asserts the EXISTING prose is parseable by a documented rule.
  #
  # Mode declaration is non-uniform across the corpus (the AC3 audit finding), so
  # the recognizer handles BOTH conventions:
  #   (1) body-heading enum — DISTINCT mode letters from `### Mode X:` / `### Mode
  #       X —` section headings, anchored to a `:`/`—`/`-` delimiter immediately
  #       after the letter so failure-mode anti-pattern headings
  #       (`### Mode A execution without a Dry-Run Record — PROC`) do NOT match.
  #   (2) description-list fallback — the `·`-separated list after the `Modes:`
  #       token inside the frontmatter `description`. NOTE: the `Modes:` token in
  #       the two desc-only skills (release/skills/pmo-skill-editor,
  #       operations/skills/project-initiator) is INLINE mid-line in a folded-YAML
  #       `description: >` block, NOT at line-start — so the match is NOT
  #       line-start-anchored (a `^[[:space:]]*Modes:` anchor would silently
  #       false-negative those two multi-mode skills, treating them as
  #       single-mode). The `·` count is taken on the substring AFTER `Modes:`
  #       so `·` separators elsewhere in the description (e.g. a Triggers list)
  #       cannot inflate the arity.
  # body-heading is authoritative when present (the description list can be a
  # stale subset, F-AC3-3); the check PASSes a skill recognizable by EITHER
  # convention and warns only on a skill that advertises modes (a `Modes:` token,
  # or ≥2 body headings) yet exposes no machine-recognizable enum by either path.
  # Cutover comment family-standard: applies to ./deploy.sh --check invocations
  # on/after the introducing release's merge SHA in RELEASE_LOG.md; that release
  # itself exempt — reflexive-pipeline-loop discipline.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 35: Mode-invocation drift (multi-mode SKILL.md mode-enum recognizability) (#26)"
    local c35_findings=0
    local c35_scanned=0
    local c35_output=""
    local c35_skill_md c35_body_enum c35_desc_line c35_desc_after c35_desc_dots c35_desc_arity
    for c35_skill_md in operations/skills/*/SKILL.md release/skills/*/SKILL.md core/skills/*/SKILL.md; do
      [[ -f "$c35_skill_md" ]] || continue
      # (1) body-heading enum — distinct, delimiter-anchored mode letters.
      c35_body_enum=$(/usr/bin/grep -oE '^### Mode [A-Z][[:space:]]*[:—-]' "$c35_skill_md" 2>/dev/null \
                      | /usr/bin/grep -oE 'Mode [A-Z]' | /usr/bin/sort -u | /usr/bin/wc -l | /usr/bin/tr -d ' ') || c35_body_enum=0
      # (2) description-list arity — `Modes:` matched ANYWHERE on the line (folded
      #     YAML puts it mid-line); `·` counted on the substring after `Modes:`.
      c35_desc_line=$(/usr/bin/grep -E 'Modes:' "$c35_skill_md" 2>/dev/null | /usr/bin/head -1) || c35_desc_line=""
      c35_desc_arity=0
      if [[ -n "$c35_desc_line" ]]; then
        c35_desc_after=$(printf '%s' "$c35_desc_line" | /usr/bin/sed -E 's/.*Modes:(.*)/\1/')
        c35_desc_dots=$(printf '%s' "$c35_desc_after" | /usr/bin/grep -oE '·' | /usr/bin/wc -l | /usr/bin/tr -d ' ')
        c35_desc_arity=$(( c35_desc_dots + 1 ))
      fi
      # In scope iff the skill advertises modes: a `Modes:` token is present OR it
      # carries ≥2 delimited body headings.
      if [[ -n "$c35_desc_line" || "$c35_body_enum" -ge 2 ]]; then
        c35_scanned=$((c35_scanned + 1))
        # Recognizable iff a clean body-heading enum (≥2) OR a parseable desc list (≥2).
        if [[ "$c35_body_enum" -ge 2 || "$c35_desc_arity" -ge 2 ]]; then
          : # PASS — mode-enum machine-recognizable by at least one convention
        else
          c35_output+="${c35_skill_md}: advertises modes but exposes no machine-recognizable mode-enum (neither ≥2 delimited \`### Mode X\` headings nor a parseable (≥2 \`·\`-separated) \`Modes:\` list)"$'\n'
          c35_findings=$((c35_findings + 1))
        fi
      fi
    done
    if [[ "$c35_scanned" -eq 0 ]]; then
      # Audit-baseline guard: the multi-mode population could be transiently empty
      # if a refactor moves skills. Baseline = ≥9 multi-mode skills (7 body-heading
      # + 2 desc-only) at the introducing release; an empty scan is itself suspect.
      flag_warn_or_issue "mode-invocation-drift" \
        "no multi-mode SKILL.md files found — expected ≥9 per the mode-enum audit (7 body-heading + 2 desc-only)"
    elif [[ "$c35_findings" -eq 0 ]]; then
      log "  OK:    all $c35_scanned multi-mode skill(s) expose a machine-recognizable mode-enum"
    else
      flag_warn_or_issue "mode-invocation-drift" \
        "$c35_findings of $c35_scanned multi-mode skill(s) lack a recognizable mode-enum — see release/references/how-to/hub-spoke-bridge.md § Procedure 3 Spoke Template \`### Mode Provenance\`"
      printf '%s' "$c35_output" | /usr/bin/sed 's/^/         /'
    fi
  fi


  # Summary
  if [[ $ISSUES -eq 0 ]]; then
    log "All checks passed."
    exit 0
  else
    log "$ISSUES issue(s) found."
    if [[ "$STRICT" == "true" ]]; then
      exit 1
    else
      exit 0
    fi
  fi
}

# ─── Mode: --report ──────────────────────────────────────────────────────────

cmd_report() {
  # Structured output for Stage 13 evidence. Same checks as --check, different format.
  # E-09: Plain text, human-readable.
  validate_workspace
  # Non-fatal resolution (ADR-013): tolerate the session-less return so --report
  # degrades gracefully on a machine with no Cowork session.
  detect_install_path || true

  local PASS=0
  local FAIL=0

  echo "=== deploy.sh Platform Report ==="
  echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Git Commit: $(git rev-parse --short HEAD)"
  echo "Git Tag: $(git describe --tags --abbrev=0 2>/dev/null || echo 'none')"
  echo ""

  # --- Skill Sync ---
  echo "--- Skill Sync ---"
  for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}" "${CANARY_SKILLS[@]}"; do
    local module
    module=$(resolve_skill_module "$skill")
    local source="$module/skills/$skill/SKILL.md"
    local target="$INSTALL_PATH/$skill/SKILL.md"
    if [[ ! -f "$target" ]]; then
      echo "[FAIL] $skill — not installed"
      FAIL=$((FAIL + 1))
    elif ! diff -q "$source" "$target" >/dev/null 2>&1; then
      echo "[FAIL] $skill — installed copy differs"
      FAIL=$((FAIL + 1))
    else
      local hash
      hash=$(md5 -q "$source" 2>/dev/null | cut -c1-8) || hash="n/a"
      echo "[PASS] $skill ($hash)"
      PASS=$((PASS + 1))
    fi

    # References check (from .skill package)
    if ! is_supplementary "$skill"; then
      local pkg="packages/${skill}.skill"
      if [[ -f "$pkg" ]]; then
        local pkg_has_refs
        pkg_has_refs=$(unzip -l "$pkg" "references/*" 2>/dev/null | grep -c "  references/" || true)
        if [[ $pkg_has_refs -gt 1 ]]; then
          local installed_refs
          installed_refs=$(find "$INSTALL_PATH/$skill/references" -type f 2>/dev/null | wc -l | tr -d ' ')
          if [[ $installed_refs -eq 0 ]]; then
            # AC-3 cause-classification (Stage-13 evidence parity with Check 1/12):
            # annotate the FAIL when the target exists but is read-only — the
            # Cowork session-churn orphan class. Diagnostic-only; no FAIL/exit change.
            local _ro_annot=""
            [[ -e "$INSTALL_PATH/$skill/references" && ! -w "$INSTALL_PATH/$skill/references" ]] && _ro_annot=" (read-only — chmod -R u+w then redeploy)"
            echo "[FAIL] $skill references/ — not deployed$_ro_annot"
            FAIL=$((FAIL + 1))
          else
            echo "[PASS] $skill references/ ($installed_refs files)"
            PASS=$((PASS + 1))
          fi
        fi
      fi
    fi

    # Supplementary content check
    if is_supplementary "$skill" && [[ -d "$INSTALL_PATH/$skill" ]]; then
      local source_dir="$module/skills/$skill"
      local supp_ok=true
      for item in "$source_dir"/*; do
        local item_name
        item_name=$(basename "$item")
        [[ "$item_name" == "SKILL.md" ]] && continue
        if [[ -d "$item" ]]; then
          # Same TEMPLATE_SYNC_MAP exclusion as cmd_check's supplementary branch,
          # but only for the references/ subdir — that is the one a
          # supplementary skill (e.g. pmo-skill-refiner) receives injected
          # template-*.md into. Without it, diff -rq reports those runtime-only
          # files as "Only in installed" → a false [FAIL] on every clean deploy.
          # Other supplementary dirs (agents/, scripts/) take no injection.
          local -a r_supp_excludes=()
          if [[ "$item_name" == "references" ]]; then
            local _r_supp_inj_base
            while IFS= read -r _r_supp_inj_base; do
              [[ -n "$_r_supp_inj_base" ]] && r_supp_excludes+=("--exclude=$_r_supp_inj_base")
            done < <(injected_ref_basenames "$skill")
          fi
          if [[ ! -d "$INSTALL_PATH/$skill/$item_name" ]]; then
            echo "[FAIL] $skill/$item_name/ — not installed"
            FAIL=$((FAIL + 1))
            supp_ok=false
          elif ! diff -rq ${r_supp_excludes[@]+"${r_supp_excludes[@]}"} "$item" "$INSTALL_PATH/$skill/$item_name" >/dev/null 2>&1; then
            echo "[FAIL] $skill/$item_name/ — differs"
            FAIL=$((FAIL + 1))
            supp_ok=false
          fi
        elif [[ -f "$item" ]] && [[ ! -f "$INSTALL_PATH/$skill/$item_name" ]]; then
          echo "[FAIL] $skill/$item_name — not installed"
          FAIL=$((FAIL + 1))
          supp_ok=false
        fi
      done
      if [[ "$supp_ok" == "true" ]]; then
        echo "[PASS] $skill supplementary content"
        PASS=$((PASS + 1))
      fi
    fi
  done
  echo ""

  # --- Package Sync ---
  echo "--- Package Sync ---"
  local pkg_dir
  pkg_dir="$(dirname "$INSTALL_PATH")/packages"
  for pkg_file in packages/*.skill; do
    [[ -f "$pkg_file" ]] || continue
    local pkg_name
    pkg_name=$(basename "$pkg_file")
    local target="$pkg_dir/$pkg_name"
    if [[ ! -f "$target" ]]; then
      echo "[FAIL] $pkg_name — not installed"
      FAIL=$((FAIL + 1))
    elif ! diff -q "$pkg_file" "$target" >/dev/null 2>&1; then
      echo "[FAIL] $pkg_name — installed copy differs"
      FAIL=$((FAIL + 1))
    else
      echo "[PASS] $pkg_name"
      PASS=$((PASS + 1))
    fi
  done
  echo ""

  # --- Duplicate Detection ---
  echo "--- Duplicate Detection ---"
  if find . -maxdepth 1 -name "Projects" -type d 2>/dev/null | grep -q .; then
    echo "[FAIL] Projects/ (uppercase) still exists"
    FAIL=$((FAIL + 1))
  else
    echo "[PASS] No uppercase Projects/ directory"
    PASS=$((PASS + 1))
  fi

  for f in PMO.md RELEASE_PROTOCOL.md; do
    if [[ -f "projects/_config/$f" ]]; then
      echo "[FAIL] projects/_config/$f exists (duplicate)"
      FAIL=$((FAIL + 1))
    else
      echo "[PASS] No projects/_config/$f"
      PASS=$((PASS + 1))
    fi
  done

  if [[ -d "projects/Reference" ]]; then
    echo "[FAIL] projects/Reference/ still exists"
    FAIL=$((FAIL + 1))
  else
    echo "[PASS] No projects/Reference/"
    PASS=$((PASS + 1))
  fi

  if [[ -d "projects/_Skill-Packages" ]]; then
    echo "[FAIL] projects/_Skill-Packages/ still exists"
    FAIL=$((FAIL + 1))
  else
    echo "[PASS] No projects/_Skill-Packages/"
    PASS=$((PASS + 1))
  fi
  echo ""

  # --- Governance Presence ---
  echo "--- Governance Presence ---"
  local -a EXPECTED_ENGINEERING=(
    core/governance/OPERATIONS.md
    release/governance/RELEASE_PROTOCOL.md
  )
  local -a EXPECTED_OPS=(
    projects/_config/PORTFOLIO.md
    projects/_config/SESSION_STATE.md
    projects/_config/CORRECTIONS.md
  )
  for f in "${EXPECTED_ENGINEERING[@]}" "${EXPECTED_OPS[@]}"; do
    if [[ -f "$f" ]]; then
      echo "[PASS] $f"
      PASS=$((PASS + 1))
    else
      echo "[FAIL] $f — missing"
      FAIL=$((FAIL + 1))
    fi
  done
  echo ""

  # --- Status-Label Invariant (Check 16) ---
  echo "--- Status-Label Invariant (Check 16) ---"
  local c14r_json
  c14r_json=$(gh issue list --repo "$AUDIT_REPO" --state open \
    --label improvement --limit 5000 --json number,labels,milestone 2>/dev/null || echo "[]")
  local c14r_i1 c14r_i2 c14r_i3 c14r_i4
  c14r_i1=$(printf '%s' "$c14r_json" | jq '[.[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) > 1)] | length')
  c14r_i2=$(printf '%s' "$c14r_json" | jq '[.[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) == 0)] | length')
  c14r_i3=$(printf '%s' "$c14r_json" | jq '[.[] | select(.milestone != null) | select((.labels | map(.name) | map(select(. == "status: proposed"))) | length > 0)] | length')
  c14r_i4=$(printf '%s' "$c14r_json" | jq '[.[] | select(.milestone == null) | select((.labels | map(.name) | map(select(. == "status: bundled"))) | length > 0)] | length')
  for entry in "I1 mutex:$c14r_i1" "I2 presence:$c14r_i2" "I3 contradiction-A:$c14r_i3" "I4 contradiction-B:$c14r_i4"; do
    local _name="${entry%%:*}"
    local _count="${entry##*:}"
    if [[ "$_count" -eq 0 ]]; then
      echo "[PASS] $_name — 0 violations"
      PASS=$((PASS + 1))
    else
      echo "[FAIL] $_name — $_count violation(s)"
      FAIL=$((FAIL + 1))
    fi
  done
  echo ""

  # --- Aging Signal — status:proposed (Check 17) ---
  # Tiered thresholds locked at D-Aging-SLA-Threshold Option D. Report uses
  # PASS/FAIL semantics regardless of cmd_check warn-mode (matches Check 16
  # report behavior — the report is the unvarnished "what would happen in
  # enforce-mode" view, suitable for Stage 13 evidence).
  echo "--- Aging Signal — status:proposed (Check 17) ---"
  echo "Thresholds: warn=14d, escalate=30d, critical=45d (locked D-Aging-SLA-Threshold Option D)"
  local c15r_proposed_json c15r_partition
  c15r_proposed_json=$(gh issue list --repo "$AUDIT_REPO" \
    --label "status: proposed" --state open --limit 1000 \
    --json number,title,createdAt 2>/dev/null) || c15r_proposed_json="[]"
  c15r_partition=$(printf '%s' "$c15r_proposed_json" | jq --argjson w 14 --argjson e 30 --argjson c 45 '
    [.[] | {number, title, age_days: ((now - (.createdAt | fromdate)) / 86400 | floor)}]
    | (map(select(.age_days >= $c)) | sort_by(-.age_days)) as $crit
    | (map(select(.age_days >= $e and .age_days < $c)) | sort_by(-.age_days)) as $esc
    | (map(select(.age_days >= $w and .age_days < $e)) | sort_by(-.age_days)) as $warn
    | {critical_count: ($crit|length), escalate_count: ($esc|length), warn_count: ($warn|length), critical: $crit, escalate: $esc, warn: $warn}
  ' 2>/dev/null) || c15r_partition='{"critical_count":0,"escalate_count":0,"warn_count":0,"critical":[],"escalate":[],"warn":[]}'
  local c15r_warn c15r_esc c15r_crit
  c15r_warn=$(printf '%s' "$c15r_partition" | jq -r '.warn_count')
  c15r_esc=$(printf '%s' "$c15r_partition" | jq -r '.escalate_count')
  c15r_crit=$(printf '%s' "$c15r_partition" | jq -r '.critical_count')
  for entry in "warn-14d:$c15r_warn" "escalate-30d:$c15r_esc" "critical-45d:$c15r_crit"; do
    local _band="${entry%%:*}"
    local _count="${entry##*:}"
    if [[ "$_count" -eq 0 ]]; then
      echo "[PASS] aging-${_band} — 0 overdue"
      PASS=$((PASS + 1))
    else
      echo "[FAIL] aging-${_band} — ${_count} overdue"
      FAIL=$((FAIL + 1))
    fi
  done
  if [[ "$c15r_crit" -gt 0 ]]; then
    printf '%s' "$c15r_partition" | jq -r '.critical[] | "  #\(.number) \(.age_days)d critical — \(.title)"'
  fi
  if [[ "$c15r_esc" -gt 0 ]]; then
    printf '%s' "$c15r_partition" | jq -r '.escalate[] | "  #\(.number) \(.age_days)d escalate — \(.title)"'
  fi
  if [[ "$c15r_warn" -gt 0 ]]; then
    printf '%s' "$c15r_partition" | jq -r '.warn[] | "  #\(.number) \(.age_days)d warn — \(.title)"'
  fi
  echo ""

  # --- Framework-corpus version-anchor drift (Check 18) ---
  # Catalog-registry-driven; mirrors cmd_check's Check 18 assertion
  # (18a catalog completeness / 18b catalog↔doc anchor consistency / 18c
  # cadence aging) into report PASS/FAIL form. As with Checks 16/17, the report
  # uses unvarnished enforce-mode semantics regardless of cmd_check warn-mode —
  # the "what would happen in enforce-mode" view, suitable for Stage 13
  # evidence. Guard failures (primitive/python/catalog missing, or
  # path-resolution exit 3) report FAIL because the assertion could not be
  # evaluated; exit 0 reports PASS; finding rows report FAIL.
  echo "--- Framework-corpus version-anchor drift (Check 18) ---"
  local c18r_script="core/deploy/tools/check-version-anchors.py"
  local c18r_catalog="core/specs/framework-catalog.md"
  if [[ ! -f "$c18r_script" ]]; then
    echo "[FAIL] framework-anchor-drift — primitive script missing: $c18r_script"
    FAIL=$((FAIL + 1))
  elif [[ ! -x "/usr/bin/python3" ]]; then
    echo "[FAIL] framework-anchor-drift — /usr/bin/python3 not executable; cannot run primitive"
    FAIL=$((FAIL + 1))
  elif [[ ! -f "$c18r_catalog" ]]; then
    echo "[FAIL] framework-anchor-drift — catalog registry missing: $c18r_catalog"
    FAIL=$((FAIL + 1))
  else
    local c18r_output c18r_exit=0
    c18r_output=$(/usr/bin/python3 "$c18r_script" \
      --catalog-path "$c18r_catalog" \
      --output-format tsv 2>&1) || c18r_exit=$?
    if [[ $c18r_exit -eq 3 ]]; then
      echo "[FAIL] framework-anchor-drift — path-resolution failure (exit 3): $(echo "$c18r_output" | head -1)"
      FAIL=$((FAIL + 1))
    elif [[ $c18r_exit -eq 0 ]]; then
      echo "[PASS] framework-anchor-drift — catalog complete, anchors consistent, no overdue reviews"
      PASS=$((PASS + 1))
    else
      local c18r_findings
      c18r_findings=$(echo "$c18r_output" | tail -n +2 | wc -l | tr -d ' ')
      echo "[FAIL] framework-anchor-drift — ${c18r_findings} finding(s) — see core/standards/framework-corpus-discipline.md"
      FAIL=$((FAIL + 1))
      echo "$c18r_output" | head -10 | sed 's/^/  /' || true
      if [[ $c18r_findings -gt 10 ]]; then
        echo "  ... ($((c18r_findings - 10)) more; rerun primitive directly for full output)"
      fi
    fi
  fi
  echo ""

  # --- Mode-invocation drift (Check 35) ---
  # Mirrors cmd_check's Check 35 (multi-mode SKILL.md mode-enum recognizability,
  # #26) into report PASS/FAIL form. As with Check 18, the report uses unvarnished
  # enforce-mode semantics regardless of cmd_check warn-mode — the "what would
  # happen in enforce-mode" view, suitable for Stage 13 evidence. Dual-convention
  # recognizer: delimiter-anchored distinct body-heading enum, with a non-line-
  # start-anchored `Modes:` description-list fallback (the desc-only skills carry
  # `Modes:` inline mid-line in folded YAML; `·` counted after `Modes:`). An empty
  # population reports FAIL (audit-baseline guard — the scan could not be
  # evaluated); recognizable-everywhere reports PASS; finding rows report FAIL.
  echo "--- Mode-invocation drift (Check 35) ---"
  local c35r_findings=0 c35r_scanned=0 c35r_output=""
  local c35r_skill_md c35r_body_enum c35r_desc_line c35r_desc_after c35r_desc_dots c35r_desc_arity
  for c35r_skill_md in operations/skills/*/SKILL.md release/skills/*/SKILL.md core/skills/*/SKILL.md; do
    [[ -f "$c35r_skill_md" ]] || continue
    c35r_body_enum=$(/usr/bin/grep -oE '^### Mode [A-Z][[:space:]]*[:—-]' "$c35r_skill_md" 2>/dev/null \
                     | /usr/bin/grep -oE 'Mode [A-Z]' | /usr/bin/sort -u | /usr/bin/wc -l | /usr/bin/tr -d ' ') || c35r_body_enum=0
    c35r_desc_line=$(/usr/bin/grep -E 'Modes:' "$c35r_skill_md" 2>/dev/null | /usr/bin/head -1) || c35r_desc_line=""
    c35r_desc_arity=0
    if [[ -n "$c35r_desc_line" ]]; then
      c35r_desc_after=$(printf '%s' "$c35r_desc_line" | /usr/bin/sed -E 's/.*Modes:(.*)/\1/')
      c35r_desc_dots=$(printf '%s' "$c35r_desc_after" | /usr/bin/grep -oE '·' | /usr/bin/wc -l | /usr/bin/tr -d ' ')
      c35r_desc_arity=$(( c35r_desc_dots + 1 ))
    fi
    if [[ -n "$c35r_desc_line" || "$c35r_body_enum" -ge 2 ]]; then
      c35r_scanned=$((c35r_scanned + 1))
      if [[ "$c35r_body_enum" -ge 2 || "$c35r_desc_arity" -ge 2 ]]; then
        :
      else
        c35r_output+="${c35r_skill_md}: advertises modes but exposes no machine-recognizable mode-enum"$'\n'
        c35r_findings=$((c35r_findings + 1))
      fi
    fi
  done
  if [[ "$c35r_scanned" -eq 0 ]]; then
    echo "[FAIL] mode-invocation-drift — no multi-mode SKILL.md files found — expected ≥9 (audit-baseline guard)"
    FAIL=$((FAIL + 1))
  elif [[ "$c35r_findings" -eq 0 ]]; then
    echo "[PASS] mode-invocation-drift — all $c35r_scanned multi-mode skill(s) expose a machine-recognizable mode-enum"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] mode-invocation-drift — ${c35r_findings} of ${c35r_scanned} multi-mode skill(s) lack a recognizable mode-enum — see release/references/how-to/hub-spoke-bridge.md § Procedure 3 Spoke Template \`### Mode Provenance\`"
    FAIL=$((FAIL + 1))
    printf '%s' "$c35r_output" | /usr/bin/sed 's/^/  /' || true
  fi
  echo ""

  local total=$((PASS + FAIL))
  echo "=== Summary: $total checks, $PASS passed, $FAIL failed ==="

  # Exit code same as --check
  if [[ $FAIL -gt 0 ]]; then
    exit 1
  fi
}

# ─── Argument Parsing ────────────────────────────────────────────────────────

main() {
  case "${1:-}" in
    --deploy)
      shift
      cmd_deploy "$@"
      ;;
    --all)
      # Explicit full-roster bootstrap / redeploy-everything: force should_full_roster
      # true, then run the no-args deploy path (which deploys the full roster + all
      # packages). The unattended path (install.sh / fresh clone) does NOT need this
      # flag — should_full_roster fires automatically on an empty mirror; --all is
      # the deterministic CI invocation and the manual "redeploy everything" lever.
      FORCE_ALL=true
      cmd_deploy
      ;;
    --check)
      if [[ "${2:-}" == "--warn" ]]; then
        STRICT=false
      fi
      cmd_check
      ;;
    --report)
      cmd_report
      ;;
    *)
      echo "Usage: ./deploy.sh [--deploy [skill...] | --all | --check [--warn] | --report]"
      echo ""
      echo "Modes:"
      echo "  --deploy [skill...] Deploy changed skills to Cowork install path (auto-detect or manual)"
      echo "  --all               Deploy the full skill roster + all packages (explicit bootstrap / redeploy-everything)"
      echo "  --check [--warn]    Validate platform health (--warn exits 0 even with issues)"
      echo "  --report            Structured report for Stage 13 verification evidence"
      echo ""
      echo "Note: --init mode (a legacy cutover migration) was REMOVED per the"
      echo "      Stage 5 spec §1.7. v2 ships with the target layout; no migration needed."
      exit 1
      ;;
  esac
}

main "$@"
