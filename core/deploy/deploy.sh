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
  artifact-lint
  change-management
  comms-writer
  daily-status
  delivery-engine
  file-router
  generated-cleanup
  health-check
  intake-desk
  pmo-business-analyst
  pmo-knowledge-manager
  pmo-ocm-lead
  pmo-process-designer
  pmo-portfolio-manager
  pmo-product-owner
  pmo-program-coordinator
  pmo-program-manager
  pmo-project-manager
  pmo-release-train-engineer
  pmo-scrum-master
  pmo-technical-analyst
  pmo-technical-program-manager
  pmo-tier-1-support
  pmo-tier-2-support
  ppm-agent
  project-initiator
  tracker-manager
  weekly-status-rollup
)

RELEASE_SKILLS=(
  build-reviewer
  implementation-planner
  pipeline-triage
  pmo-architect
  pmo-devops-sre
  pmo-principal-engineer
  pmo-qa-lead
  pmo-release-manager
  pmo-skill-editor
  pmo-skill-refiner
  pmo-software-engineer
  release-executor
  release-hub
  release-planner
  roadmap-curator
)

CORE_SKILLS=(
  context-budget-auditor
  eval-writer
  pmo-qa-auditor
  pmo-skill-router
  prompt-builder
  skill-compliance-auditor
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

# ─── Operator-instance / needle path resolver ───────────────────────────────
# Single source for the operator-instance dir + localized-context needle file.
# Every site below calls pmo_instance_path() / pmo_localized_needles() instead of
# inlining the hardcoded instance-dir default literal
# (ADR-032 canonicalization + ADR-017 surface convergence). Sourced from this
# script's own dir so it resolves regardless of the caller's cwd.
# shellcheck source=lib-instance-path.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib-instance-path.sh"

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
# core/standards/ via the explicit-basename resolver rule. #94 added 1 further
# entry — regression-checks.md (same explicit-basename resolver rule). Check 13
# verifies every entry below (40 after #94; 39 after #316; 31 after L4 Stage 6;
# 25 at L3 Stage 6); the live count is reported dynamically via
# ${#TEMPLATE_SYNC_MAP[@]}.
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
  "project-initiator:dual-framing-bridge-template.md:references/templates/dual-framing-bridge-template.md"
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
  # ── Shared standards doc: regression-checks.md (1 consumer) — #94 single-source.
  #    The pmo-skill-editor Mode-C regression bank was a near-duplicate (4-line
  #    [PROJECT_KEY] localization diff) of core/standards/regression-checks.md.
  #    Single-sourced to the core/standards/ canonical (explicit-basename resolver
  #    rule); the source-tree mirror is deleted and injected at deploy/build time.
  #    Check 13 owns byte-identity; Check 13b no longer sees a divergent same-base
  #    pair. Distinct from release/references/specs/skill-suite-regression-checks.md
  #    (35L PMO Skill Suite per-skill baseline — different basename + purpose).
  "pmo-skill-editor:regression-checks.md:references/regression-checks.md"
  # ── Templates: people-graph consumption (leg D / #1899) — R5 (#315) + #1166 deferral ──
  # Roster template (#315, ships standalone) registered against its real readers:
  #   comms-writer (names/tone) + ppm-agent (escalation owner + Person maintainer §6).
  # Clarification-queue template (leg C / #1166, ships standalone) → ppm-agent (Tier-1
  #   resolution surface). tracker-manager + delivery-engine read the COMPOSED VIEW
  #   (people-coverage-graph.md), not these template files — so they are NOT injection
  #   targets (registering a non-reader = orphaned injected reference, the #315 R5 risk).
  "comms-writer:people-roster-template.yaml:references/people-roster-template.yaml"
  "ppm-agent:people-roster-template.yaml:references/people-roster-template.yaml"
  "ppm-agent:people-graph-clarification-queue-template.md:references/people-graph-clarification-queue-template.md"
  # ── Templates: PMBOK coverage (#206 — 5 entries) ──
  # Charter / lessons-learned / change-log / RACI / stakeholder-register, all
  # consumed by project-initiator (scaffolds project artifacts at initiation).
  # All 5 match the *-template.{md,csv} pattern → default resolver routes them
  # to operations/templates/ (no explicit-basename resolver entry needed).
  "project-initiator:project-charter-template.md:references/templates/project-charter-template.md"
  "project-initiator:lessons-learned-template.md:references/templates/lessons-learned-template.md"
  "project-initiator:change-log-template.md:references/templates/change-log-template.md"
  "project-initiator:raci-template.md:references/templates/raci-template.md"
  "project-initiator:stakeholder-register-template.csv:references/templates/stakeholder-register-template.csv"
)

# ─── Shared Functions ────────────────────────────────────────────────────────

die() {
  echo "ERROR: $1" >&2
  exit 1
}

log() {
  echo "[$(date +%H:%M:%S)] $1"
}

# ─── Version-freeness (Check 41 / --check-version-freeness) — #1677 ───────────
# The pre-merge freeness predicate, factored to TOP LEVEL so it is shared by two
# surfaces with ONE body (DD1): the lifecycle Check 41 (inside cmd_check, routing
# the verdict through flag_warn_or_issue / version-freeness.mode) and the
# --check-version-freeness probe (cmd_check_version_freeness, mapping the verdict
# to an exit code for the CI merge gate). Neither re-encodes the grammar — the
# comparator is SOURCED from version-grammar.sh (#1676 SSOT); these helpers add NO
# version parser (DD2 / Stage-5 adversarial review FM-1 "no 4th parser").
#
# NOTE (set -e isolation): claim-version.sh's adapter ops (claimed_set/anchor/
# compute_next_free) are NOT sourced here — sourcing claim-version.sh applies
# `set -euo pipefail` to the caller, which would abort cmd_check (it runs WITHOUT
# set -e so a failing check increments ISSUES instead of aborting). version-grammar.sh
# is pure (defines functions only, no set -e leak — verified) so ONLY it is sourced;
# the claimed_set assembly is deploy-local I/O here (the Stage-5 spec's explicit
# allowance: "the comparator is the part that must be SSOT-shared; the claimed_set
# assembly is deploy-local I/O"). The I/O mirrors Check 39's published-Release anchor.

# _vf_freeness_core <candidate> <claimed_tag>...
#   THE VERDICT CONTRACT (identical decision to release/tools/test_version_freeness.sh
#   and to the founding #1676 reference FREENESS). Pure: no host I/O; the candidate
#   and the claimed_set members are passed in. Requires version_canonical/version_cmp
#   to already be in scope (the caller sources version-grammar.sh). Echoes EXACTLY
#   one verdict token (+ optional detail) on stdout:
#     FREE                          candidate canonical, collides with no member
#     NOT_FREE <tag>                candidate tuple-equals <tag> (collision)
#     UNDECIDABLE <reason>:<value>  malformed candidate OR a non-canonical claimed
#                                   tag the grammar cannot order — FAIL-CLOSED
#                                   (DD4 / FM-3): NOT a silent `continue`.
#   Comparison is version_cmp (the SSOT integer-triple comparator) so the
#   hotfix-vs-minor case (v2.06.1 vs v2.07) is decided correctly.
_vf_freeness_core() {
  local candidate="$1"; shift
  if ! version_canonical "$candidate"; then
    printf 'UNDECIDABLE malformed-candidate:%s\n' "$candidate"
    return 0
  fi
  local t
  for t in "$@"; do
    [[ -n "$t" ]] || continue
    if ! version_canonical "$t"; then
      printf 'UNDECIDABLE non-canonical-tag:%s\n' "$t"
      return 0
    fi
    if [[ "$(version_cmp "$candidate" "$t")" == "0" ]]; then
      printf 'NOT_FREE %s\n' "$t"
      return 0
    fi
  done
  printf 'FREE\n'
}

# _vf_build_claimed_set  — echo the claimed_set, one canonical version per line.
#   The union (DD3): published GitHub Release tags U origin signed tags U RELEASE_LOG
#   rows in DEPLOYED-not-VERIFIED state. This is deploy-local I/O (the SAME sources
#   claim-version.sh::claimed_set reads, re-expressed here without the set -e leak).
#   Reads AUDIT_REPO + _audit_src_root (resolved at deploy.sh load). Network calls
#   are guarded so an offline run yields a partial/empty set (the caller decides the
#   surface-split: offline = N/A on lifecycle, fail-closed at the merge gate).
#   Output is grammar-filtered (canonical only) but NOT orphan-filtered here — the
#   core fail-closes on any non-canonical member, which is the stricter posture the
#   merge gate wants (an orphan v3.x tag that parses canonical is simply a member
#   that will not tuple-collide with a v2.x candidate; a NON-canonical tag triggers
#   the fail-closed path, by design).
_vf_build_claimed_set() {
  local repo="$1"
  {
    # (1) published Release tags (the authoritative anchor, same as Check 39).
    if [[ -n "$repo" ]] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      gh api "repos/${repo}/releases" --paginate --jq '.[].tag_name' 2>/dev/null || true
    fi
    # (2) origin signed tags.
    git -C "${_audit_src_root:-.}" ls-remote --tags origin 2>/dev/null \
      | sed -e 's#.*refs/tags/##' -e 's/\^{}$//' || true
    # (3) RELEASE_LOG rows in DEPLOYED (tag-pushed-but-Release-unpublished) state.
    local _log="${_audit_src_root:-.}/release/releases/RELEASE_LOG.md"
    if [[ -f "$_log" ]]; then
      awk -F'|' '
        /^\|/ {
          ver=$2; st=$7
          gsub(/^[ \t]+|[ \t]+$/, "", ver)
          gsub(/^[ \t]+|[ \t]+$/, "", st)
          if (st == "DEPLOYED" && ver ~ /^v[0-9]/) print ver
        }
      ' "$_log" 2>/dev/null || true
    fi
  } | sed '/^$/d' | sort -u
}

# _vf_resolve_candidate  — echo the claim-time candidate version, or empty if no
#   release-claim context is resolvable (-> the check SKIPs cleanly; absence is not
#   drift, same posture as Check 40's operator-local SKIP). Resolution order:
#     1. PMO_VERSION_FREENESS_CANDIDATE env — explicit injection (CI matrix / a
#        Stage-12 pre-flight that already knows the candidate / the DT harness).
#     2. PMO_VERSION_FREENESS_BUMP env (major|minor|patch) [+ PMO_VERSION_FREENESS_PATCH_BASE]
#        — derive next-free via claim-version.sh --dry-run, run as a SUBPROCESS
#        (a child bash; its `set -euo pipefail` cannot leak into cmd_check) so the
#        allocator is the ONE #1675/#1673 implementation, never re-derived here (CD-3).
#     3. else empty (no claim context — greenfield / a normal lifecycle --check).
#   The allocator is NEVER re-implemented inline (CD-3): when a bump-class is given,
#   the canonical claim-version.sh computes the next-free candidate.
_vf_resolve_candidate() {
  local repo="$1"
  # (1) explicit candidate.
  if [[ -n "${PMO_VERSION_FREENESS_CANDIDATE:-}" ]]; then
    printf '%s' "${PMO_VERSION_FREENESS_CANDIDATE}"
    return 0
  fi
  # (2) bump-class -> claim-version.sh --dry-run (subprocess; no set -e leak).
  #     The allocator is the ONE #1675/#1673 implementation; never re-derived here.
  #     If the dry-run yields a NON-canonical value (e.g. the allocator could not
  #     resolve the anchor), treat it as "no usable candidate" -> empty -> the check
  #     SKIPs rather than asserting on a malformed value. This output validation is
  #     defensive: an earlier stub-seam leak that let the self-test seams override
  #     real host I/O on a normal load (so --dry-run read empty fixtures) has since
  #     been fixed in claim-version.sh; the guard remains as a safety net against any
  #     future allocator regression. The explicit PMO_VERSION_FREENESS_CANDIDATE path
  #     (1) is the exact, always-correct surface the CI gate + the operator use.
  if [[ -n "${PMO_VERSION_FREENESS_BUMP:-}" ]]; then
    local _claim="${_audit_src_root:-.}/release/tools/claim-version.sh"
    if [[ -f "$_claim" ]]; then
      local _args=(--sha HEAD --bump "${PMO_VERSION_FREENESS_BUMP}" --dry-run)
      [[ -n "${PMO_VERSION_FREENESS_PATCH_BASE:-}" ]] && _args+=(--patch-base "${PMO_VERSION_FREENESS_PATCH_BASE}")
      local _derived
      _derived="$(CLAIM_REPO="$repo" bash "$_claim" "${_args[@]}" 2>/dev/null | head -1 | tr -d '[:space:]' || true)"
      # Only return a value that LOOKS like a version (v<digit>...); else empty.
      if [[ "$_derived" =~ ^v[0-9]+\.[0-9]+ ]]; then
        printf '%s' "$_derived"
      fi
      return 0
    fi
  fi
  # (3) no claim context.
  printf ''
}

# _vf_compute_verdict  — the shared orchestrator (DD1: ONE body, two surfaces).
#   Sources the SSOT comparator, resolves the candidate, builds the claimed_set,
#   and echoes one of these protocol lines on stdout (the CALLER maps it to a
#   warn-emit OR an exit code — the verdict is decoupled from the emit, FM-2):
#     SKIP <reason>          no claim context / lib absent on lifecycle surface
#     NA <reason>            anchor merely offline on the lifecycle surface
#     FREE <candidate>       candidate is free
#     NOT_FREE <candidate> <tag>   collision
#     UNDECIDABLE <candidate> <reason>   fail-closed (DD4/FM-3)
#   $1 = surface: "lifecycle" (offline anchor -> NA) or "gate" (offline anchor ->
#   UNDECIDABLE / fail-closed — the merge gate cannot certify freeness blind).
_vf_compute_verdict() {
  local surface="${1:-lifecycle}"
  local lib="${_audit_src_root:-}/release/tools/version-grammar.sh"

  # SSOT comparator must be sourceable. Absent -> SKIP on lifecycle (the lib lands
  # with #1676; pre-#1676 it is absent), fail-closed at the gate (cannot decide).
  if [[ -z "${_audit_src_root:-}" || ! -f "$lib" ]]; then
    if [[ "$surface" == "gate" ]]; then
      printf 'UNDECIDABLE - ssot-comparator-missing:%s\n' "$lib"
    else
      printf 'SKIP version-grammar.sh (#1676 SSOT comparator) not present — freeness undecidable on this surface\n'
    fi
    return 0
  fi
  # Source the SSOT (empty positional so its --self-test does not fire on our $1).
  # shellcheck source=/dev/null
  source "$lib" ""

  # Resolve the candidate. No claim context -> SKIP (absence is not drift).
  local candidate
  candidate="$(_vf_resolve_candidate "${AUDIT_REPO:-}")"
  if [[ -z "$candidate" ]]; then
    printf 'SKIP no release-claim context (set PMO_VERSION_FREENESS_CANDIDATE or _BUMP to assert freeness) — not drift\n'
    return 0
  fi

  # Offline-anchor surface split (DD4). At the GATE surface, a missing published-
  # Release anchor is fail-closed (the merge gate must not certify freeness blind).
  # On the LIFECYCLE surface, a merely-offline anchor degrades to NA (never-FAIL),
  # mirroring Check 39/32 — no merge is imminent. origin tags + RELEASE_LOG still
  # contribute to claimed_set offline; the gate's strictness is about the network
  # anchor it cannot reach.
  local anchor_offline=0
  if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1 || [[ -z "${AUDIT_REPO:-}" ]]; then
    anchor_offline=1
  fi
  if [[ "$anchor_offline" -eq 1 && "$surface" == "gate" ]]; then
    printf 'UNDECIDABLE %s anchor-unreachable-at-merge-gate (gh offline/unauth or AUDIT_REPO empty) — fail-closed\n' "$candidate"
    return 0
  fi
  if [[ "$anchor_offline" -eq 1 && "$surface" == "lifecycle" ]]; then
    printf 'NA %s published-Release anchor unavailable (gh offline/unauth or AUDIT_REPO empty) — reuses Check 39/32 offline SKIP semantics\n' "$candidate"
    return 0
  fi

  # Build claimed_set (deploy-local I/O) and decide freeness via the SSOT core.
  local claimed claimed_arr=()
  claimed="$(_vf_build_claimed_set "${AUDIT_REPO:-}")"
  if [[ -n "$claimed" ]]; then
    local _l
    while IFS= read -r _l; do [[ -n "$_l" ]] && claimed_arr+=("$_l"); done <<<"$claimed"
  fi

  local core
  core="$(_vf_freeness_core "$candidate" "${claimed_arr[@]+"${claimed_arr[@]}"}")"
  local tok="${core%% *}"
  local rest="${core#"$tok"}"; rest="${rest# }"
  case "$tok" in
    FREE)        printf 'FREE %s\n' "$candidate" ;;
    NOT_FREE)    printf 'NOT_FREE %s %s\n' "$candidate" "$rest" ;;
    UNDECIDABLE) printf 'UNDECIDABLE %s %s\n' "$candidate" "$rest" ;;
    *)           printf 'UNDECIDABLE %s unexpected-core-verdict:%s\n' "$candidate" "$core" ;;
  esac
}

# ─── Close-completeness (Check 48 / --check-close-completeness) — #1290 ────────
# The scaffold-independent close-completeness predicate, factored to TOP LEVEL so
# it is shared by two surfaces with ONE body (mirroring the version-freeness DD1
# pattern above): the lifecycle Check 48 (inside cmd_check, routing the verdict
# through flag_warn_or_issue / close-completeness.mode) and the
# --check-close-completeness probe (cmd_check_close_completeness, mapping the
# verdict to an exit code for CI).
#
# THE INVARIANT (founding ADR-048): a work-item scaffold selects WHICH tasks exist;
# it never attenuates the rigor of any task's codified Phase checklist. For every
# `VERIFIED` `RELEASE_LOG` row at/after the cutover, the entire canonical Stage-13
# output-set (the hub-spoke-bridge.md Procedure 7 Step 4 table) is present on main —
# asserted with NO scaffold, NO sub-task body, and NO hub session in the loop. That
# is scaffold-independence by construction: the gate reads main's state, not the
# execution path (spoke / hub-direct / chore-PR fallback) that produced it.
#
# NO LOGIC DUPLICATION (the umbrella contract): this engine DELEGATES every
# sub-assertion it can to an existing tool rather than re-deriving it —
#   • §3.2 note-content  → core/deploy/tools/lint_release_corpus.py --check note-content
#                          (the same engine automated-closeout.sh phase_lint_release_notes runs)
#   • §5.1 body-drift     → release/tools/check-release-body-drift.sh (Check 47's engine)
#   • companion-presence  → the SAME path resolution Check 32 uses (INDEX row / DIGEST
#                          entry / NOTES file under version-stem OR milestone-slug)
# It is an aggregating invariant, NOT a parallel checker.
#
# CUTOVER + DORMANCY (mirrors Check 32/47): the full assertion runs only for rows
# at/after $cc_cutoff (CLOSE_COMPLETENESS_CHECK_CUTOFF), which DEFAULTS to the
# __none__ sentinel — so the gate is DORMANT by default (no historical false-positive
# storm; reflexive-pipeline-loop honored — the introducing release v2.37 closes under
# the pre-merge runbook and the cutover is anchored strictly AFTER its merge). The
# network sub-checks (Surface-1 Release + body-drift) need `gh`; offline ⇒ N/A on the
# lifecycle surface, fail-closed on the gate surface (the merge gate must not certify
# completeness blind, per the version-freeness FM-2 precedent).
#
# LOG-ROW BLIND SPOT (inherited, documented): like Check 32, this gate is LOG-row-
# driven — a close that never wrote its `RELEASE_LOG` row is invisible to it. LOG-row
# presence is the close-time Step 4 table's responsibility, not this gate's.

# _cc_row_findings <surface> <version> <milestone> <tag>
#   THE PER-ROW ASSERTION. Pure-ish: takes the row fields + the surface; reads
#   in-repo corpus files (and, for the network sub-checks, the repo's own published
#   Release via the delegated tools). Echoes ZERO or more finding lines on stdout
#   (one per missing / drifted output, prefixed "<version>: "); echoes nothing when
#   the row's full output-set is present. Network sub-checks resolve to N/A (no
#   finding, a diagnostic to stderr) when gh is unavailable on the "lifecycle"
#   surface; on the "gate" surface an unreadable network anchor is a finding
#   (fail-closed). Corpus paths are read from CC_* (set by the orchestrator).
_cc_row_findings() {
  local surface="$1" _ver="$2" _ms="$3" _tag="$4"
  local _index="${CC_INDEX:-release/releases/RELEASE_INDEX.md}"
  local _digest="${CC_DIGEST:-release/releases/RELEASE_DIGEST.md}"
  local _changelog="${CC_CHANGELOG:-CHANGELOG.md}"
  local _notes_dir="${CC_NOTES_DIR:-release/releases/notes}"
  local _lint="${CC_LINT:-core/deploy/tools/lint_release_corpus.py}"
  local _drift="${CC_DRIFT:-release/tools/check-release-body-drift.sh}"
  # The published-Release sub-check is itself cutover-gated + dormant-by-default,
  # exactly like Check 32's $c32_release_cutoff. __none__ ⇒ the network surface
  # sub-checks (Release existence + body-drift) are skipped (N/A) regardless of gh.
  local _release_cutoff="${CLOSE_COMPLETENESS_RELEASE_CUTOFF:-__none__}"

  # (a) NOTES file present (version stem OR milestone slug — Check 32's resolution)
  local _notes_ok=0
  [[ -f "${_notes_dir}/${_ver}_RELEASE_NOTES.md" ]] && _notes_ok=1
  [[ -n "$_ms" && -f "${_notes_dir}/${_ms}_RELEASE_NOTES.md" ]] && _notes_ok=1
  if [[ $_notes_ok -eq 0 ]]; then
    printf '%s: missing notes file (%s_RELEASE_NOTES.md or %s_RELEASE_NOTES.md)\n' "$_ver" "$_ver" "$_ms"
  fi

  # (b) INDEX row present (version is the first table cell)
  if ! /usr/bin/grep -qE "^\|[[:space:]]*${_ver//./\\.}[[:space:]]*\|" "$_index" 2>/dev/null; then
    printf '%s: missing RELEASE_INDEX.md row\n' "$_ver"
  fi

  # (c) DIGEST entry present (### vX.YZ heading)
  if ! /usr/bin/grep -qE "^### ${_ver//./\\.}[[:space:](]" "$_digest" 2>/dev/null; then
    printf '%s: missing RELEASE_DIGEST.md entry (### %s ...)\n' "$_ver" "$_ver"
  fi

  # (d) CHANGELOG section present — N/A (no finding) pre-CHANGELOG (file absent),
  # mirroring automated-closeout.sh phase_append_changelog pre-CHANGELOG SKIP.
  if [[ -f "$_changelog" ]]; then
    if ! /usr/bin/grep -qE "^## \[?${_ver//./\\.}\]?[[:space:]]" "$_changelog" 2>/dev/null; then
      printf '%s: missing CHANGELOG.md ## [%s] section\n' "$_ver" "$_ver"
    fi
  fi

  # (e) .version is asserted in AGGREGATE by _cc_compute_verdict (the stamp is a
  # single value — it must exist and equal the MOST-RECENT VERIFIED release; an
  # older row's version legitimately differs from the live stamp, so a per-row
  # equality check would false-positive). Not a per-row finding here.

  # (f) signed-tag presence — read from the LOG Tag column (in-corpus; no network).
  # Empty / em-dash / unrecoverable Tag column => missing tag for a VERIFIED row.
  if [[ -z "$_tag" || "$_tag" == "—" || "$_tag" == "-" || "$_tag" == *unrecoverable* ]]; then
    printf '%s: VERIFIED row has no tag recorded in RELEASE_LOG Tag column\n' "$_ver"
  fi

  # (g) §3.2 note-content — DELEGATE to lint_release_corpus.py (version-scoped, the
  # phase_lint_release_notes idiom: grep the finding lines for THIS note's path).
  if [[ -f "$_lint" ]] && [[ -x "/usr/bin/python3" ]]; then
    local _lint_out _lint_exit=0
    _lint_out="$(/usr/bin/python3 "$_lint" --check note-content 2>&1)" || _lint_exit=$?
    if [[ $_lint_exit -eq 3 ]]; then
      printf '%s: §3.2 note-content lint path-unresolved (exit 3; corpus unverifiable)\n' "$_ver"
    elif [[ $_lint_exit -ne 0 ]]; then
      local _note_rel="${_notes_dir}/${_ver}_RELEASE_NOTES.md"
      if printf '%s' "$_lint_out" | /usr/bin/grep -qF "$_note_rel" 2>/dev/null; then
        printf '%s: §3.2 note-content finding for this version (lint_release_corpus.py)\n' "$_ver"
      fi
      # findings only for OTHER versions ⇒ out-of-scope legacy debt (audit-baseline)
    fi
  else
    printf '%s: §3.2 note-content lint tooling unavailable (cannot verify note-content)\n' "$_ver"
  fi

  # Network sub-checks (h Surface-1 Release + i §5.1 body-drift) — cutover-gated +
  # dormant by default (__none__). Run only for rows at/after the SEPARATE network
  # cutover, and only when this row reached it.
  if [[ "$_release_cutoff" != "__none__" && ( "$_ver" == "$_release_cutoff" || "$_ver" > "$_release_cutoff" ) ]]; then
    local _gh_ok=0
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then _gh_ok=1; fi
    if [[ $_gh_ok -eq 0 ]]; then
      if [[ "$surface" == "gate" ]]; then
        # Fail-closed at the gate surface (the merge gate must not certify blind).
        printf '%s: Surface-1 Release + §5.1 body-drift unverifiable (gh offline at gate surface — fail-closed)\n' "$_ver"
      else
        printf 'close-completeness: %s network sub-checks N/A (gh offline) — reuses Check 32/47 gh-guard SKIP\n' "$_ver" >&2
      fi
    else
      # (h) published GitHub Release present
      if ! gh release view "$_ver" >/dev/null 2>&1; then
        printf '%s: no published GitHub Release (Surface 1 absent on main)\n' "$_ver"
      fi
      # (i) §5.1 body-drift — DELEGATE to check-release-body-drift.sh
      if [[ -x "$_drift" ]]; then
        local _d_exit=0
        "$_drift" "$_ver" --quiet >/dev/null 2>&1 || _d_exit=$?
        case "$_d_exit" in
          0) : ;;  # MATCH
          1) printf '%s: published Release body != frontmatter-stripped note (§5.1 drift)\n' "$_ver" ;;
          2) : ;;  # N/A at tool layer (gh offline) — already covered above
          3) : ;;  # no Release/note to compare — Surface-1 existence owns it (h)
          *) printf '%s: body-drift tool returned unexpected exit %s\n' "$_ver" "$_d_exit" ;;
        esac
      fi
    fi
  fi
}

# _cc_compute_verdict <surface>
#   THE SHARED ORCHESTRATOR. Iterates VERIFIED RELEASE_LOG rows at/after the
#   cutover (allowlist-filtered), aggregates _cc_row_findings, and echoes ONE
#   protocol line on stdout (the CALLER maps it to a warn-emit OR an exit code):
#     SKIP <reason>           dormant (cutoff __none__) / LOG absent — nothing to assert
#     CLEAN <n>               n VERIFIED row(s) checked, full output-set present
#     INCOMPLETE <n> <m>      n finding(s) across m checked row(s) — detail to stderr
#   $1 = surface: "lifecycle" (gh-offline network sub-check ⇒ N/A) or "gate"
#   (gh-offline network sub-check ⇒ finding / fail-closed).
_cc_compute_verdict() {
  local surface="${1:-lifecycle}"
  local cc_log="${CC_LOG:-release/releases/RELEASE_LOG.md}"
  local cc_allowlist="${CC_ALLOWLIST:-.claude/skip-close-completeness-check.txt}"
  local cc_cutoff="${CLOSE_COMPLETENESS_CHECK_CUTOFF:-__none__}"

  # Dormant by default — the cutover sentinel keeps the gate from retroactively
  # flagging historical VERIFIED rows (and honors the reflexive-loop exemption).
  if [[ "$cc_cutoff" == "__none__" ]]; then
    printf 'SKIP close-completeness gate dormant (CLOSE_COMPLETENESS_CHECK_CUTOFF unset) — opt in by setting it to the first post-v2.37-merge release\n'
    return 0
  fi
  if [[ ! -f "$cc_log" ]]; then
    printf 'SKIP %s not found; cannot enumerate VERIFIED releases\n' "$cc_log"
    return 0
  fi

  # Export corpus paths for _cc_row_findings (single resolution point).
  export CC_INDEX="${CC_INDEX:-release/releases/RELEASE_INDEX.md}"
  export CC_DIGEST="${CC_DIGEST:-release/releases/RELEASE_DIGEST.md}"
  export CC_CHANGELOG="${CC_CHANGELOG:-CHANGELOG.md}"
  export CC_VERSIONFILE="${CC_VERSIONFILE:-.version}"
  export CC_NOTES_DIR="${CC_NOTES_DIR:-release/releases/notes}"
  export CC_LINT="${CC_LINT:-core/deploy/tools/lint_release_corpus.py}"
  export CC_DRIFT="${CC_DRIFT:-release/tools/check-release-body-drift.sh}"

  # Allowlist filter (exact version match; trailing # comment supported) —
  # mirrors Check 32's c32_is_allowlisted.
  _cc_is_allowlisted() {
    local _v="$1"
    [[ -f "$cc_allowlist" ]] || return 1
    /usr/bin/grep -qE "^[[:space:]]*${_v//./\\.}[[:space:]]*(#.*)?\$" "$cc_allowlist"
  }

  # Enumerate logged releases in LOG file order, emitting "version|milestone|tag|state"
  # for each `| vX.Y | <ms> | ... | <tag> | <state> | <date> |` row. The 8-col schema
  # is Version(1) Milestone(2) Issues(3) ReleasePR(4) MergeSHA(5) Tag(6) State(7)
  # Date(8) — so field 6 = Tag, field 7 = State (the VERIFIED filter).
  local cc_rows
  cc_rows=$(/usr/bin/grep -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$cc_log" 2>/dev/null \
    | /usr/bin/awk -F ' \\| ' '{
        v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v);
        ms=$2; sub(/^[[:space:]]*/,"",ms); sub(/[[:space:]]*$/,"",ms);
        tg=$6; gsub(/`/,"",tg); sub(/^[[:space:]]*/,"",tg); sub(/[[:space:]]*$/,"",tg);
        st=$7; gsub(/`/,"",st); sub(/^[[:space:]]*/,"",st); sub(/[[:space:]]*$/,"",st);
        print v "|" ms "|" tg "|" st
      }') || cc_rows=""

  local cc_past_cutoff=false cc_targets=0 cc_findings=0 cc_detail="" _last_verified=""
  local _row _ver _ms _tag _state _rf
  while IFS= read -r _row; do
    [[ -n "$_row" ]] || continue
    _ver="${_row%%|*}"
    _ms="${_row#*|}"; _ms="${_ms%%|*}"
    _tag="${_row%|*}"; _tag="${_tag##*|}"
    _state="${_row##*|}"

    # Cutover gate (walk LOG order; arm on first cutoff-prefix match).
    if [[ "$cc_past_cutoff" == "false" && "$_ver" == "$cc_cutoff"* ]]; then
      cc_past_cutoff=true
    fi
    [[ "$cc_past_cutoff" == "true" ]] || continue

    # VERIFIED-only (the completeness contract is VERIFIED-scoped; a DEPLOYED-not-
    # VERIFIED row is mid-close and correctly skipped).
    [[ "$_state" == "VERIFIED" ]] || continue
    _cc_is_allowlisted "$_ver" && continue
    cc_targets=$((cc_targets + 1))
    _last_verified="$_ver"   # LOG file order is chronological ⇒ last wins

    _rf="$(_cc_row_findings "$surface" "$_ver" "$_ms" "$_tag")"
    if [[ -n "$_rf" ]]; then
      cc_detail+="$_rf"$'\n'
      cc_findings=$((cc_findings + $(printf '%s\n' "$_rf" | /usr/bin/grep -c . )))
    fi
  done <<<"$cc_rows"

  # (e-aggregate) .version stamp — must exist AND equal the most-recent VERIFIED
  # in-scope release. N/A (no finding) when .version is absent (version-less /
  # pre-stamp state), mirroring phase_bump_version's version-less SKIP.
  local _vf="${CC_VERSIONFILE:-.version}"
  if [[ -n "$_last_verified" && -f "$_vf" ]]; then
    local _stamp
    _stamp="$(/usr/bin/head -1 "$_vf" 2>/dev/null | /usr/bin/tr -d '[:space:]')"
    if [[ -n "$_stamp" && "$_stamp" != "$_last_verified" ]]; then
      cc_detail+="${_last_verified}: .version stamp is '${_stamp}', expected the most-recent VERIFIED release '${_last_verified}'"$'\n'
      cc_findings=$((cc_findings + 1))
    fi
  fi

  if [[ $cc_findings -eq 0 ]]; then
    printf 'CLEAN %s\n' "$cc_targets"
  else
    # Detail to stderr; the verdict line (stdout) carries the counts.
    printf '%s' "$cc_detail" | /usr/bin/sed '/^$/d' >&2
    printf 'INCOMPLETE %s %s\n' "$cc_findings" "$cc_targets"
  fi
  return 0
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
  # E-05: Confirm script is running from pmo-platform repo root.
  # Checks for the 3-module skeleton (operations/, release/, core/) plus
  # CLAUDE.md OR core/CLAUDE.md.template.
  # The template variant accommodates both contexts:
  #   - v2 source repo (CLAUDE.md.template exists; runtime CLAUDE.md is at
  #     operator's workspace root, depersonalized at install-time)
  #   - operator workspace (CLAUDE.md present at workspace root)
  if [[ ! -f CLAUDE.md ]] && [[ ! -f core/CLAUDE.md.template ]]; then
    die "Must run from pmo-platform repo root. CLAUDE.md (or core/CLAUDE.md.template) not found."
  fi
  if [[ ! -d core ]] || [[ ! -d release ]] || [[ ! -d operations ]]; then
    die "Must run from pmo-platform repo root. 3-module skeleton (core/, release/, operations/) not found."
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

skill_content_hash() {
  # Rebuild-stable content-manifest hash of a .skill (or any zip) archive.
  #
  # Per the gate-efficacy standard (core/standards/gate-efficacy-standard.md)
  # Requirement (a) — assert by content, not by proxy. Check 7's prior mtime
  # compare was a proxy: `touch` (or a fresh `git checkout`, which equalizes all
  # timestamps) made a stale package pass a green gate. This helper asserts the
  # CONTENT instead.
  #
  # Why not hash the .skill bytes directly: the archive is ZIP_DEFLATED and its
  # envelope embeds per-entry mtimes + carries rglob member ordering, so a clean
  # rebuild from byte-identical source yields a DIFFERENT raw archive hash — a
  # raw-byte hash would false-FAIL every legitimate rebuild. Instead, hash a
  # canonical manifest of the archive's CONTENT: for each member, the line
  # "<sha256-of-member-bytes>  <arcname>", sorted by arcname under LC_ALL=C, then
  # SHA-256 of that manifest blob. Properties: order-stable (LC_ALL=C sort),
  # envelope-independent (extracts members; ignores zip mtime/ordering),
  # content-addressed (any member-byte change OR member rename ⇒ different hash).
  #
  # Portability: shasum -a 256, unzip, find, sort (LC_ALL=C), mktemp -d are all
  # BSD/macOS-native — no sha256sum (GNU/coreutils, not guaranteed on stock
  # macOS), no GNU `sort -z`.
  #
  # Args:  $1 — path to the .skill (zip) archive.
  # Echoes: the 64-hex content-manifest hash, or nothing on failure (empty
  #         string — caller treats empty as "could not hash").
  local pkg="$1" tmp rc=0
  [[ -f "$pkg" ]] || { echo ""; return 1; }
  tmp="$(mktemp -d)" || { echo ""; return 1; }
  if ! unzip -q -o "$pkg" -d "$tmp" >/dev/null 2>&1; then
    rm -rf "$tmp"
    echo ""
    return 1
  fi
  # Subshell isolates the cd; the manifest pipeline never aborts the caller.
  (
    cd "$tmp" || exit 1
    find . -type f | LC_ALL=C sort | while IFS= read -r f; do
      printf '%s  %s\n' "$(shasum -a 256 "$f" | cut -d' ' -f1)" "${f#./}"
    done
  ) | shasum -a 256 | cut -d' ' -f1 || rc=1
  rm -rf "$tmp"
  return $rc
}

build_skill_to_dir() {
  # Stage a skill + inject canonicals + emit a .skill into an arbitrary output
  # dir WITHOUT touching the committed packages/<skill>.skill. This is the
  # in-process equivalent of build-skill-packages.sh build_one(), reused by
  # Check 7's content verdict (stage a rebuild, hash it, compare to the
  # committed baseline). Kept byte-aligned with build_one(): same staging, same
  # TEMPLATE_SYNC_MAP injection via resolve_template_sync_source(), same packager.
  #
  # Args:
  #   $1 — skill name
  #   $2 — module (operations|release|core) — caller already resolved it
  #   $3 — output dir (the .skill lands at $3/<skill>.skill)
  # Returns: 0 on success; non-zero on any staging/inject/packager failure.
  local skill="$1" module="$2" out_dir="$3"
  local source_dir="$module/skills/$skill"
  [[ -d "$source_dir" ]] || return 1
  [[ -x "/usr/bin/python3" ]] || return 1

  local stage_dir
  stage_dir="$(mktemp -d)" || return 1
  cp -R "$source_dir" "$stage_dir/$skill" || { rm -rf "$stage_dir"; return 1; }

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
      rm -rf "$stage_dir"
      return 1
    fi
    mkdir -p "$(dirname "$stage_dir/$skill/$m_target_rel")"
    cp "$canonical_source" "$stage_dir/$skill/$m_target_rel" || { rm -rf "$stage_dir"; return 1; }
  done

  # Invoke the per-skill packager from the pmo-skill-refiner module so its
  # `from scripts.quick_validate` import resolves. Emit into out_dir.
  local repo_root rc=0
  repo_root="$(pwd)"
  mkdir -p "$out_dir"
  (
    cd release/skills/pmo-skill-refiner || exit 1
    /usr/bin/python3 -m scripts.package_skill "$stage_dir/$skill" "$out_dir"
  ) >/dev/null 2>&1 || rc=1
  rm -rf "$stage_dir"
  return $rc
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
  #   regression-checks.md      → core/standards/<name>   (explicit; #94)
  #   template-*.md             → core/standards/<name>
  #   *-template.{md,csv}       → operations/templates/<name>
  # (templates → operations, template-* standards → core. The modular
  # canonical is operations/templates/ — the public-API surface per
  # docs/module-apis.md § Operations module § Public templates.)
  #
  # The explicit shared-standards-doc basenames (output-format.md,
  # operational-artifacts.md, regression-checks.md) are single-sourced shared
  # references homed in core/standards/ per template-storage.md §3 / §7.2. They
  # match neither the template-*.md nor the *-template.{md,csv} pattern, so they
  # are mapped by an explicit narrow basename rule rather than a broad
  # "non-template → core/standards/" catch-all — a catch-all would silently
  # re-home any future non-template basename and is deliberately avoided. Add a
  # new explicit basename here when a further shared standards doc is
  # single-sourced.
  #
  # Args:
  #   $1 — canonical filename (e.g., raid-log-template.csv, template-storage.md,
  #        output-format.md)
  #
  # Echoes the resolved source path. Caller checks file existence.
  local name="$1"
  case "$name" in
    output-format.md|operational-artifacts.md|regression-checks.md) echo "core/standards/$name" ;;
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
    sed -n 's|[^/]*/skills/\([^/]*\)/.*|\1|p' | sort -u)

  # Changed packages — `packages/` at v2 root (no module nesting per the v2 root layout).
  # The `\.skill$` anchor is load-bearing: it matches `<name>.skill` only at end-of-name,
  # so the content-hash sidecars `<name>.skill.sha256` (Check 7 baselines) are NOT mis-parsed
  # into phantom `<name>.sha256` package names. (Unanchored, `packages/foo.skill.sha256`
  # yielded `foo.sha256` → a copy of the non-existent `foo.sha256.skill` failed the deploy.)
  CHANGED_PACKAGES=()
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && CHANGED_PACKAGES+=("$pkg")
  done < <(git diff --name-only "$diff_base"..HEAD -- 'packages/' 2>/dev/null | \
    sed -n 's|packages/\(.*\)\.skill$|\1|p' | sort -u)

  # E-03: Deleted skills (module-aware capture across the 3 subtrees).
  DELETED_SKILLS=()
  while IFS= read -r skill; do
    [[ -n "$skill" ]] && DELETED_SKILLS+=("$skill")
  done < <(git diff --diff-filter=D --name-only "$diff_base"..HEAD -- 'operations/skills/' 'release/skills/' 'core/skills/' 2>/dev/null | \
    sed -n 's|[^/]*/skills/\([^/]*\)/.*|\1|p' | sort -u)

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

  # Regenerate the committed hook-registry index from its per-hook + cross-cutting
  # sources (per ADR-030 #18). The canonical core/rules/bypass-mode-readiness.md is
  # a GENERATED artifact assembled by build-hook-registry.py; regenerating it at
  # deploy keeps the committed index fresh from sources (Check 38 verifies it
  # stayed fresh). Best-effort — a deploy on a machine without python3 still
  # proceeds; Check 38 surfaces any resulting staleness.
  if [[ -f core/deploy/tools/build-hook-registry.py ]] && [[ -x /usr/bin/python3 ]]; then
    if /usr/bin/python3 core/deploy/tools/build-hook-registry.py >/dev/null 2>&1; then
      log "Hook-registry index regenerated from sources (core/rules/bypass-mode-readiness.md)."
    else
      log "WARN: hook-registry index regeneration failed; Check 38 will flag any staleness."
    fi
  fi
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
        # #984: capture cp stderr and surface the root cause + remediation on a
        # read-only / undeletable install target — the same report-the-cause
        # discipline #88 introduced for the references/ mirror (no opaque
        # "some files failed to copy"). Happy path is byte-identical.
        local supp_failures=false supp_cause="" supp_failed_item=""
        for item in "$source_dir"/*; do
          local item_name cp_err cp_rc=0
          item_name=$(basename "$item")
          [[ "$item_name" == "SKILL.md" ]] && continue  # Already deployed above
          if [[ -d "$item" ]]; then
            cp_err=$(cp -R "$item" "$INSTALL_PATH/$skill/" 2>&1) && cp_rc=0 || cp_rc=$?
          elif [[ -f "$item" ]]; then
            cp_err=$(cp "$item" "$INSTALL_PATH/$skill/" 2>&1) && cp_rc=0 || cp_rc=$?
          fi
          if [[ $cp_rc -ne 0 ]]; then
            supp_failures=true
            [[ -z "$supp_cause" ]] && { supp_cause="${cp_err:-cp returned $cp_rc}"; supp_failed_item="$item_name"; }
          fi
        done
        if [[ "$supp_failures" == "true" ]]; then
          log "  WARNING:  $skill — supplementary content copy failed (first failure: $supp_failed_item)"
          log "            cause: ${supp_cause}"
          log "            remediation: chmod -R u+w \"$INSTALL_PATH/$skill\" && ./deploy.sh --deploy $skill  (read-only install target; derived mirror — safe to chmod)"
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

# ─── Mode: --check-lifecycle ─────────────────────────────────────────────────

cmd_check_lifecycle() {
  # Read-only. Single surface answering "which deploy.sh checks are retired or
  # dormant, why, and what reactivates them." The per-check detail lives in the
  # inline RETIRED / DORMANT comment blocks in cmd_check; this is the INDEX.
  # Maintenance rule: add a row here whenever a check is retired (tombstoned) or
  # parked (dormant). Keep in sync with the inline blocks — they are the SSOT for
  # detail, this table is the SSOT for the lifecycle roster.
  cat <<'LIFECYCLE'
deploy.sh check lifecycle registry
===================================
Live check sequence: 1-14, 16-23, 25-46   (gaps: 15, 24 — both reserved)
Next NEW top-level check number: 47
  (15 and 24 are RETIRED-RESERVED; never reuse. Sub-checks extend an existing
   number, e.g. 18a/18b/18c/18d, and do NOT consume a new top-level number.)

CHECK  STATE     DISPOSITION                         REACTIVATION / AUTHORITY
-----  --------  ----------------------------------  ------------------------------------
15     RETIRED   Release-corpus cross-link integrity Authority: FX-Check15 (operator,
                 -> operator-instance (release       2026-05-27) + harness plan section 2.4.
                 corpus moved out of tracked tree).  Reactivate: operator may re-introduce
                 Number reserved.                    an in-tree Check 15 if posture changes.
                                                     Detail: inline block in cmd_check.
24     RETIRED   Initiative-roadmap staleness scan   Authority: ADR-012 (2026-06-02) +
                 (24a frontmatter lint / 24b 90-day  initiative-roadmap-framework.md s10.
                 staleness) -> DELETED; roadmap      Reactivate: only if roadmap instances
                 instances now operator-local.       return to the tracked tree. Number
                 Number reserved (#318 took 34, not  reserved per the v1.21 release plan.
                 24, for this reason).               Detail: inline block in cmd_check.
11     DORMANT   Harness sync. Code complete;        Anchor: #375 (carry v1 .claude/ harness
                 HARNESS_LIST empty since the        into v2). Auto-reactivates when
                 account-switcher was extracted      HARNESS_LIST is non-empty.
                 ("Phase 3").                        Detail: inline block in cmd_check.
30     DORMANT   Slash-command quoting lint. Code    Anchor: #375 (carry v1 .claude/ harness
                 complete; harness/*/commands/       into v2). Auto-reactivates when find
                 absent since "Phase 3".             harness -path '*/commands/*.md'
                                                     yields >=1 file.
                                                     Detail: inline block in cmd_check.
LIFECYCLE
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
  # NOT in-repo governance (lives at ${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/RELEASE_LOG.md).
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

  # ── Check 5(d) — Registry-currency (rows) ───────────────────────────────
  # Per the skill-registry-identity-and-currency design (milestone 104, #1811):
  # assert the catalog (core/skills/registry.md) is CURRENT against the deployed
  # roster — one surface deeper than Check 5(a)/(b) (catalog-vs-roster, not
  # dir-vs-roster). This is structural and zero-FP, so it is ALWAYS-ENFORCE:
  # findings increment ISSUES directly (same profile as Checks 6/7), no warn
  # window. It reuses Check 5's roster machinery rather than re-resolving — the
  # registry-currency assertion IS a roster-drift assertion (does the catalog
  # match the roster?), conceptually Check 5's own concern.
  #
  # Three row-level assertions (#1811):
  #   (i)   every registry row name ∈ the deployed roster
  #   (ii)  every deployed-roster member ∈ the registry rows   (FAIL on asymmetry, BOTH directions)
  #   (iii) every registry row name resolves to a live SKILL.md
  #
  # Canary exclusion (ADR-04 / source-only canary; registry § Configuration
  # Items states the source-only canary is NOT a CI): the roster for 5(d) is
  # OPERATIONS_SKILLS + RELEASE_SKILLS + CORE_SKILLS ONLY — CANARY_SKILLS is
  # NOT unioned in. This is the deliberate divergence from Check 5's
  # EXPECTED_ROSTER (which DOES include the canary for the *directory*
  # assertion): the canary has a source dir but no registry row, so including
  # it here would false-FAIL "roster member has no registry row". DO NOT "fix"
  # this by adding the canary.
  #
  # set +e / set -u discipline (ADR-008 FM-1): runs inside cmd_check's set +e
  # body; every array expansion is `${ARR[@]+"${ARR[@]}"}`-guarded and every
  # grep/sed parse is `|| true`-guarded so an empty array or a benign no-match
  # cannot abort the run before the summary gate.
  #
  # ── #1658 SEAM (field-currency, warn-mode-initial) ──────────────────────
  # The inner per-row FIELD assertion (#1658) nests INSIDE the row loop (iii)
  # below, at the marked seam. #1658 will:
  #   • resolve REGISTRY_FIELD_MODE=$(resolve_check_mode "registry-field-currency")
  #     (the helper is defined later in cmd_check, ~line 2258; 5(d) row-currency
  #     does NOT depend on it — only the #1658 field layer does);
  #   • parse the row `kind` (table cell 3) and, for kind==role-Specialist rows,
  #     assert modes (set-equality) / dependencies (skill-name-set equality) /
  #     trigger surface (presence-only) against the live SKILL.md, routing
  #     divergence via a flag_registry_field helper (clone of flag_g1_enforcement);
  #   • for non-role-Specialist rows, assert the three field cells == `—`.
  # The seam is a single nesting point; #1811 and #1658 are never two blocks.
  log "Check 5(d): Registry-currency (rows)"
  local REGISTRY_CATALOG="core/skills/registry.md"
  local registry_currency_ok=true
  if [[ ! -f "$REGISTRY_CATALOG" ]]; then
    # Missing-predicate pattern (parity with Check 6): graceful skip + WARN, not FAIL.
    log "  WARN:  registry catalog $REGISTRY_CATALOG absent — skipping registry-currency (Check 5(d))"
  else
    # ── #1658 FIELD-CURRENCY mode + emit helper (warn-mode-initial) ─────────
    # The inner field layer (#1658) ships warn-mode-initial, decoupled from the
    # ~12-check shared deploy-check.mode cohort via a dedicated
    # `registry-field-currency.mode` operator-instance file (the Check-22
    # g1-enforcement graduation precedent). NOTE on ordering: the shared
    # resolve_check_mode / flag_warn_or_issue / $DEPLOY_CHECK_MODE / $WARN_LOG
    # are defined LATER in cmd_check (~lines 2350-2413) — they are NOT yet in
    # scope at this seam. So the field layer resolves its mode and defines its
    # emit helper INLINE here, self-contained, replicating the same warn-mode
    # semantics (warn → WARN + jsonl, no ISSUES increment; enforce → FAIL +
    # ISSUES) without forward-referencing the later cohort. The row layer
    # (#1811) above is always-enforce and depends on NONE of this.
    #
    # Resolution: read `<instance>/registry-field-currency.mode` (operator-
    # instance, NOT committed), legacy `.claude/hooks/` fallback; absent/invalid
    # → fall back to the shared default `warn`. So with no mode file present
    # (the shipped state, and what CI sees) the field layer is WARN-only and
    # cannot push `--check` exit non-zero — satisfying #1658's "exits 0 on the
    # current roster when fields are faithful" regardless of residual divergence.
    local REGISTRY_FIELD_MODE="warn"
    local _rfc_mode_file="$(pmo_instance_path)/registry-field-currency.mode"
    [[ -f "$_rfc_mode_file" ]] || _rfc_mode_file=".claude/hooks/registry-field-currency.mode"
    if [[ -f "$_rfc_mode_file" ]]; then
      local _rfc_mode
      _rfc_mode=$(cat "$_rfc_mode_file" 2>/dev/null | tr -d '[:space:]')
      case "$_rfc_mode" in
        enforce|warn|off) REGISTRY_FIELD_MODE="$_rfc_mode" ;;
      esac
    fi
    local _rfc_warn_log="$(pmo_instance_path)/deploy-check-warn-log.jsonl"
    # flag_registry_field — field-layer gating emit (clone of flag_g1_enforcement
    # semantics). enforce → FAIL + ISSUES; warn → WARN + jsonl, no increment;
    # off → silent (parity with the cohort helpers).
    flag_registry_field() {
      local _frf_detail="$1"
      case "$REGISTRY_FIELD_MODE" in
        enforce)
          log "  FAIL:  registry-field-currency — $_frf_detail"
          ISSUES=$((ISSUES + 1))
          ;;
        warn)
          log "  WARN:  registry-field-currency — $_frf_detail (warn-mode; flip registry-field-currency.mode to 'enforce' after the shakedown window)"
          local _frf_ts
          _frf_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
          local _frf_esc="${_frf_detail//\\/\\\\}"
          _frf_esc="${_frf_esc//\"/\\\"}"
          printf '{"ts":"%s","check":"%s","detail":"%s"}\n' "$_frf_ts" "registry-field-currency" "$_frf_esc" >> "$_rfc_warn_log" 2>/dev/null || true
          ;;
      esac
    }

    # Deployed roster for 5(d): the 3 module arrays, canary EXCLUDED (ADR-04).
    # set -u guard: ${ARR[@]+...} expands to nothing for an unset/empty array.
    local -a DEPLOYED_ROSTER=()
    local _dr_line
    while IFS= read -r _dr_line; do
      [[ -n "$_dr_line" ]] && DEPLOYED_ROSTER+=("$_dr_line")
    done < <(printf '%s\n' \
      ${OPERATIONS_SKILLS[@]+"${OPERATIONS_SKILLS[@]}"} \
      ${RELEASE_SKILLS[@]+"${RELEASE_SKILLS[@]}"} \
      ${CORE_SKILLS[@]+"${CORE_SKILLS[@]}"} | sort -u)

    # Parse registry row names — every CI row, first backtick-wrapped token in
    # cell 1: `| [`<name>`](<relpath>) | ...`. Deterministic; canary returns 0.
    local -a REGISTRY_ROWS=()
    local _rr_line
    while IFS= read -r _rr_line; do
      [[ -n "$_rr_line" ]] && REGISTRY_ROWS+=("$_rr_line")
    done < <(grep -E '^\| \[' "$REGISTRY_CATALOG" 2>/dev/null \
      | sed -E 's/^\| \[`([^`]+)`\].*/\1/' || true)

    # Audit-baseline guard (BR-3, Check-35 precedent): an empty parse is itself
    # suspect — a registry reformat or a moved file would silently break the row
    # parse and produce a false "every roster member has no row" storm. If the
    # parse yields 0 rows, FAIL LOUDLY once and do NOT proceed to the membership
    # diff. (The deployed roster is never empty in practice; the registry having
    # ≥1 CI row is the invariant here.)
    if [[ "${#REGISTRY_ROWS[@]}" -eq 0 ]]; then
      log "  FAIL:  registry-currency — parsed 0 rows from $REGISTRY_CATALOG (expected >=1; parse broke or file moved). Not running the membership diff."
      ISSUES=$((ISSUES + 1))
      registry_currency_ok=false
    else
      # (i) every registry row name must be a deployed-roster member.
      local _row
      for _row in ${REGISTRY_ROWS[@]+"${REGISTRY_ROWS[@]}"}; do
        local _row_found=false
        local _rs
        for _rs in ${DEPLOYED_ROSTER[@]+"${DEPLOYED_ROSTER[@]}"}; do
          [[ "$_row" == "$_rs" ]] && { _row_found=true; break; }
        done
        if [[ "$_row_found" == "false" ]]; then
          log "  FAIL:  registry-currency — registry row '$_row' has no roster member (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS). Add the skill to deploy.sh or remove the registry row."
          ISSUES=$((ISSUES + 1))
          registry_currency_ok=false
        fi
      done

      # (ii) every deployed-roster member must have a registry row (asymmetry FAILs).
      local _member
      for _member in ${DEPLOYED_ROSTER[@]+"${DEPLOYED_ROSTER[@]}"}; do
        local _member_found=false
        local _rw
        for _rw in ${REGISTRY_ROWS[@]+"${REGISTRY_ROWS[@]}"}; do
          [[ "$_member" == "$_rw" ]] && { _member_found=true; break; }
        done
        if [[ "$_member_found" == "false" ]]; then
          log "  FAIL:  registry-currency — roster member '$_member' has no registry row in $REGISTRY_CATALOG. Add a Configuration-Item row or remove the skill from deploy.sh."
          ISSUES=$((ISSUES + 1))
          registry_currency_ok=false
        fi
      done

      # (iii) every registry row name must resolve to a live SKILL.md.
      # Module resolution is done WITHOUT resolve_skill_module (which die()s on a
      # name not in any array — a row that already failed (i) would otherwise
      # abort the run under the inherited set +e via die's exit). Resolve the
      # module by direct existence probe across the 3 module dirs instead, so a
      # stray registry row degrades to a clean FAIL rather than a hard die.
      for _row in ${REGISTRY_ROWS[@]+"${REGISTRY_ROWS[@]}"}; do
        local _row_skill_md=""
        local _mod
        for _mod in operations release core; do
          if [[ -f "$_mod/skills/$_row/SKILL.md" ]]; then
            _row_skill_md="$_mod/skills/$_row/SKILL.md"
            break
          fi
        done
        if [[ -z "$_row_skill_md" ]]; then
          log "  FAIL:  registry-currency — registry row '$_row' resolves to no live SKILL.md under operations/|release/|core/skills/. Fix the row name or create the skill."
          ISSUES=$((ISSUES + 1))
          registry_currency_ok=false
        fi

        # ── #1658 FIELD-CURRENCY (inner field assertion, warn-mode-initial) ──
        # For THIS $_row, assert its declared registry fields against the live
        # SKILL.md. The CI table column order (registry.md § Configuration Items
        # header) is: name|kind|module|lifecycle-state|dependencies|owner|
        # trigger surface|modes — so, splitting the pipe row on '|' (the leading
        # '|' makes `name` field 2): kind=field 3, dependencies=field 6,
        # trigger surface=field 8, modes=field 9.
        #
        # Per-field match strategy (the #2235 design, validated full-roster at
        # this commit):
        #   • modes        → SET-EQUALITY (order-insensitive ` · `-split member
        #                    set) — modes are an exact structural lift of the
        #                    SKILL.md `Modes:`/`Mode:` clause; reuses the Check-35
        #                    `Modes?:` extraction idiom.
        #   • dependencies → skill-name-SET-EQUALITY — the registry re-encodes
        #                    `Composes a + b` as `DEPENDS_ON a · DEPENDS_ON b`
        #                    (different surface form, same edge set); compare the
        #                    SET of skill names (surface-form-independent). Source
        #                    side: harvest roster names appearing in the SKILL.md
        #                    composition region (the `Composes…` clause up to the
        #                    Modes/Use/Triggers boundary) — scoping to that region
        #                    (not the whole description) avoids harvesting an
        #                    incidentally-named skill from an input/consumes clause.
        #   • trigger surface → PRESENCE-ONLY (non-empty AND ≠ `—`) — it is a
        #                    LOSSY hand-paraphrase of `description:`; any content
        #                    match false-FAILs by construction, so it is only
        #                    checked for presence.
        # All three route divergence via flag_registry_field (warn-mode → WARN,
        # exit-code-neutral). Skip if the row had no live SKILL.md (already FAILed
        # by (iii) — nothing to assert against). Every grep/sed is `|| true`-guarded
        # under the inherited set +e (ADR-008 FM-1).
        if [[ "$REGISTRY_FIELD_MODE" != "off" && -n "$_row_skill_md" ]]; then
          # Fetch THIS row's full pipe-delimited line from the registry to read
          # its field cells. The CI rows are uniquely keyed by the backtick-
          # wrapped name in cell 1, so an anchored grep on `| [\`<name>\`]` returns
          # exactly one line (head -1 defensively). The registry is small; this
          # per-row re-read is deterministic and keeps the parse local.
          local _row_line_cache
          _row_line_cache=$(/usr/bin/grep -E "^\| \[\`${_row}\`\]" "$REGISTRY_CATALOG" 2>/dev/null | /usr/bin/head -1) || _row_line_cache=""
          local _row_kind
          _row_kind=$(printf '%s' "$_row_line_cache" | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}') || _row_kind=""
          local _row_trig _row_modes _row_deps
          _row_trig=$(printf  '%s' "$_row_line_cache" | awk -F'|' '{gsub(/^ +| +$/,"",$8); print $8}') || _row_trig=""
          _row_modes=$(printf '%s' "$_row_line_cache" | awk -F'|' '{gsub(/^ +| +$/,"",$9); print $9}') || _row_modes=""
          _row_deps=$(printf  '%s' "$_row_line_cache" | awk -F'|' '{gsub(/^ +| +$/,"",$6); print $6}') || _row_deps=""

          if [[ "$_row_kind" == "role-Specialist" ]]; then
            # --- modes: set-equality (registry cell ↔ SKILL.md Modes?: clause) ---
            # SKILL.md side: text after `Modes:`/`Mode:` on its line, trimmed of
            # the trailing sentence (`. Use…`/`. Triggers…`/etc.) and any final dot.
            local _smd_modes _reg_modes_sorted _smd_modes_sorted
            _smd_modes=$(/usr/bin/grep -oE 'Modes?:[^.]*' "$_row_skill_md" 2>/dev/null | /usr/bin/head -1 | /usr/bin/sed -E 's/^Modes?:[[:space:]]*//') || _smd_modes=""
            _reg_modes_sorted=$(printf '%s' "$_row_modes" | /usr/bin/tr '·' '\n' | /usr/bin/sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | /usr/bin/grep -v '^$' | /usr/bin/sort -u) || _reg_modes_sorted=""
            _smd_modes_sorted=$(printf '%s' "$_smd_modes" | /usr/bin/tr '·' '\n' | /usr/bin/sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | /usr/bin/grep -v '^$' | /usr/bin/sort -u) || _smd_modes_sorted=""
            if [[ "$_reg_modes_sorted" != "$_smd_modes_sorted" ]]; then
              flag_registry_field "row '$_row' modes diverge — registry [$(printf '%s' "$_reg_modes_sorted" | /usr/bin/paste -sd'·' -)] != SKILL.md Modes: [$(printf '%s' "$_smd_modes_sorted" | /usr/bin/paste -sd'·' -)]"
            fi

            # --- dependencies: skill-name-set-equality ---
            # Registry side: strip the edge-type prefix, take the target names.
            local _reg_dep_names _smd_comp_region _smd_dep_names
            _reg_dep_names=$(printf '%s' "$_row_deps" | /usr/bin/grep -oE '(DEPENDS_ON|RELATES_TO) [a-z0-9-]+' | /usr/bin/sed -E 's/^(DEPENDS_ON|RELATES_TO) //' | /usr/bin/sort -u) || _reg_dep_names=""
            # SKILL.md side: isolate the composition region (the `Composes…`
            # clause up to the Modes/Use/Triggers boundary), then which deployed-
            # roster names appear in it (deterministic against the known roster).
            local _smd_desc
            _smd_desc=$(/usr/bin/awk '/description: >/{f=1;next} f&&/^[a-z_0-9]+:/{exit} f{print}' "$_row_skill_md" 2>/dev/null) || _smd_desc=""
            _smd_comp_region=$(printf '%s' "$_smd_desc" | /usr/bin/grep -oiE '[Cc]omposes.*' | /usr/bin/sed -E 's/[[:space:]]*(Modes?:|Use |Triggers:).*//') || _smd_comp_region=""
            _smd_dep_names=""
            if [[ -n "$_smd_comp_region" ]]; then
              local _cand
              for _cand in ${DEPLOYED_ROSTER[@]+"${DEPLOYED_ROSTER[@]}"}; do
                if printf '%s' "$_smd_comp_region" | /usr/bin/grep -qF -- "$_cand"; then
                  _smd_dep_names+="$_cand"$'\n'
                fi
              done
            fi
            _smd_dep_names=$(printf '%s' "$_smd_dep_names" | /usr/bin/grep -v '^$' | /usr/bin/sort -u) || _smd_dep_names=""
            if [[ "$_reg_dep_names" != "$_smd_dep_names" ]]; then
              flag_registry_field "row '$_row' dependencies diverge — registry skill-name set [$(printf '%s' "$_reg_dep_names" | /usr/bin/paste -sd' ' -)] != SKILL.md Composes set [$(printf '%s' "$_smd_dep_names" | /usr/bin/paste -sd' ' -)]"
            fi

            # --- trigger surface: presence-only (non-empty AND ≠ em-dash) ---
            if [[ -z "$_row_trig" || "$_row_trig" == "—" ]]; then
              flag_registry_field "row '$_row' (role-Specialist) has an empty/'—' trigger surface — a routing target must carry a non-empty trigger surface"
            fi
          else
            # --- non-role-Specialist rows: the three routing-view fields must be
            # '—' (function-skill/core/router are not routing targets). A non-'—'
            # value would wrongly surface the row in the routing view — that is
            # the drift, so the inversion is the correct finding. (lifecycle-state
            # / module / owner are NOT asserted here — only the routing-view trio.)
            if [[ "$_row_trig" != "—" ]]; then
              flag_registry_field "row '$_row' (kind=$_row_kind) carries a non-'—' trigger surface — only role-Specialist rows populate the routing view"
            fi
            if [[ "$_row_modes" != "—" ]]; then
              flag_registry_field "row '$_row' (kind=$_row_kind) carries a non-'—' modes cell — only role-Specialist rows populate modes"
            fi
          fi
        fi
      done
    fi

    if [[ "$registry_currency_ok" == "true" ]]; then
      log "  OK:    registry catalog current — ${#REGISTRY_ROWS[@]} rows <-> roster (symmetric; canary excluded), every row resolves to a live SKILL.md; field-currency asserted per role-Specialist row (modes/dependencies set-equality, trigger-surface presence; mode=$REGISTRY_FIELD_MODE)"
    fi
  fi

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
  local EXEMPTION_LIST="$(pmo_instance_path)/skill-editor-exemption-list.txt"
  [[ -f "$EXEMPTION_LIST" ]] || EXEMPTION_LIST=".claude/skill-editor-exemption-list.txt"

  # Check 6 — Canonical-structure compliance (required; always-enforce; enforcement-surface: deploy-time + CI mirror)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (b)):
  #   posture: required   enforcement-surface: always-enforce (deploy-time) +
  #            branch-protection CI mirror (skill-canonical-structure-check.yml)
  #   invariant: every rostered SKILL.md is canonical-structure compliant (required
  #              frontmatter fields present; references/ subdir present once the
  #              D-Refs threshold is crossed; ≥3 domain-specific failure modes).
  #   falsification: remove a required frontmatter field, or drop a skill below the
  #                  3-failure-mode floor -> this check FAILS for that skill.
  #
  # SINGLE SOURCE (per gate-efficacy-standard.md Req (b′) + the #1101 "assert
  # content, not a re-implemented proxy" doctrine): the predicate — required
  # frontmatter fields (name/description/version), the D-Refs threshold (>400
  # lines OR >25600 bytes -> references/ required), and the failure-mode floor
  # (≥3) — lives ONCE in core/deploy/tools/check-canonical-structure.sh. Both this
  # deploy-time check AND the PR-time CI mirror invoke that one script, so the two
  # surfaces cannot drift. The script extracts the same per-module roster arrays
  # from THIS file at runtime (Check 5 reconciles them against disk), so its
  # iteration set is identical to the deploy-time set this check formerly walked
  # inline. The thresholds/fields/iteration are UNCHANGED — only their home moved
  # to the shared invokable that closes the run-context gap (#673).
  #
  # The script honors the same EXEMPTION_LIST (canary-by-design D-Refs exemption,
  # frontmatter still enforced) via the operator-instance path / .claude fallback. We
  # re-emit each per-skill line through log() and fold every FAIL into ISSUES so
  # the STRICT summary gate behaves exactly as before.
  log "Check 6: Canonical-structure compliance"
  local c6_script="core/deploy/tools/check-canonical-structure.sh"
  if [[ ! -f "$c6_script" ]]; then
    log "  FAIL:  Check 6 predicate script missing: $c6_script"
    ISSUES=$((ISSUES + 1))
  else
    local c6_out c6_rc
    c6_out=$(bash "$c6_script" 2>&1)
    c6_rc=$?
    local c6_line
    while IFS= read -r c6_line; do
      [[ -z "$c6_line" ]] && continue
      # Suppress the script's trailing SUMMARY line (deploy.sh prints its own
      # aggregate via the STRICT gate); surface every OK/FAIL verbatim.
      [[ "$c6_line" == SUMMARY:* ]] && continue
      log "  $c6_line"
      [[ "$c6_line" == FAIL:* ]] && ISSUES=$((ISSUES + 1))
    done <<< "$c6_out"
    # Defensive: a non-zero exit with no parsed FAIL line (e.g. exit 3 scan-surface
    # error emitted only to stderr-merged output) still counts as one issue so a
    # broken predicate run never reads green.
    if [[ $c6_rc -ne 0 ]] && ! grep -q '^FAIL:' <<< "$c6_out"; then
      log "  FAIL:  Check 6 predicate run exited $c6_rc with no per-skill FAIL (scan-surface error)"
      ISSUES=$((ISSUES + 1))
    fi
  fi

  # Check 7 — Package-freshness (required; always-enforce; enforcement-surface: deploy-time)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md):
  #   posture: required   enforcement-surface: always-enforce (deploy-time)
  #   invariant: every rostered skill's .skill package reflects current source
  #              content (the committed package == what source would build now).
  #   falsification: mutate one source byte without rebuilding the package → FAIL;
  #                  `touch` the package alone (content unchanged) → stays GREEN.
  #
  # ASSERT-BY-CONTENT, NOT BY PROXY (Requirement (a)). The prior mechanism
  # compared file mtimes — a proxy that diverges from content: `touch
  # packages/<skill>.skill` made a stale package pass, and a fresh `git checkout`
  # (which equalizes all timestamps) passed regardless of content (the originating
  # false-confidence). The verdict now rests on the rebuild-stable
  # content-manifest hash (skill_content_hash) of a STAGED REBUILD of source,
  # compared against the committed content baseline sidecar
  # (packages/<skill>.skill.sha256). Because the comparison is content-based and
  # mtime-independent, a committed-stale package is caught even on a fresh
  # checkout where every mtime is equal.
  #
  # The mtime compare is retained only as a cheap, non-verdict-bearing PRE-FILTER
  # (the standard's escape valve): it can short-circuit to a fast PASS when the
  # baseline already matches AND nothing under source is newer than the package,
  # avoiding the rebuild in the common clean case. It NEVER substitutes for the
  # content verdict — when anything is ambiguous (source newer, baseline mismatch,
  # or the fast-path's preconditions unmet) the staged-rebuild content compare is
  # the deciding step.
  #
  # python3 / packager absent → the staged-rebuild verdict cannot run; the check
  # degrades to the baseline-vs-live-package content compare alone (still content,
  # not mtime) and logs the degraded scope (matches the graceful-skip posture of
  # Checks 14/18/20/23).
  log "Check 7: Package freshness (content-manifest hash)"
  local c7_can_rebuild=true
  [[ -x "/usr/bin/python3" ]] || c7_can_rebuild=false
  command -v unzip >/dev/null 2>&1 || c7_can_rebuild=false
  for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}"; do
    local c7_module
    c7_module=$(resolve_skill_module "$skill")
    local c7_src_dir="$c7_module/skills/$skill"
    local c7_pkg="packages/${skill}.skill"
    local c7_sidecar="packages/${skill}.skill.sha256"

    if [[ ! -f "$c7_pkg" ]]; then
      log "  FAIL:  $skill — .skill package missing"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    # Live package's content-manifest hash (content of what is committed).
    local c7_live_hash
    c7_live_hash=$(skill_content_hash "$c7_pkg")
    if [[ -z "$c7_live_hash" ]]; then
      log "  FAIL:  $skill — could not compute package content hash (corrupt archive or missing unzip/shasum)"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    # Committed content baseline (sidecar). Its absence is a freshness gap — the
    # sidecar must be emitted at build time (build-skill-packages.sh) and
    # committed alongside the package.
    if [[ ! -f "$c7_sidecar" ]]; then
      log "  FAIL:  $skill — content baseline sidecar missing ($c7_sidecar); rebuild via core/deploy/tools/build-skill-packages.sh $skill"
      ISSUES=$((ISSUES + 1))
      continue
    fi
    local c7_baseline
    c7_baseline=$(tr -d '[:space:]' < "$c7_sidecar" 2>/dev/null)

    # Tamper/corruption check: the committed package's content must match its
    # committed baseline. A `touch` leaves content identical, so the live hash
    # still matches the baseline (touch → GREEN). A post-build edit to the
    # package bytes (without re-emitting the sidecar) flips this red.
    if [[ "$c7_live_hash" != "$c7_baseline" ]]; then
      log "  FAIL:  $skill — package content hash ($c7_live_hash) != committed baseline ($c7_baseline); package tampered or sidecar stale — rebuild via core/deploy/tools/build-skill-packages.sh $skill"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    # mtime PRE-FILTER (cheap, non-verdict): is anything under source newer than
    # the committed package? If not, AND the baseline already matched above, the
    # common clean case can fast-PASS without a rebuild.
    local c7_newest_src c7_pkg_mtime c7_src_newer=false
    c7_newest_src=$(find "$c7_src_dir" -type f -not -path '*/.*' -exec stat -f '%m' {} \; 2>/dev/null | sort -n | tail -1)
    c7_pkg_mtime=$(stat -f '%m' "$c7_pkg" 2>/dev/null)
    if [[ -n "$c7_newest_src" && -n "$c7_pkg_mtime" && "$c7_newest_src" -gt "$c7_pkg_mtime" ]]; then
      c7_src_newer=true
    fi

    # CONTENT VERDICT: stage a rebuild of source and compare its content hash to
    # the committed baseline. This is the load-bearing freshness assertion —
    # mtime-independent, so it catches a committed-stale package on a fresh
    # checkout. Run it whenever a rebuild is available; the result decides.
    if [[ "$c7_can_rebuild" == "true" ]]; then
      local c7_tmp_pkgdir c7_rebuilt_pkg c7_rebuilt_hash
      c7_tmp_pkgdir="$(mktemp -d)"
      # build-skill-packages.sh writes packages/<skill>.skill at REPO_ROOT, so
      # redirect its output dir via the packager directly into a temp dir to
      # avoid clobbering the committed package. We stage source + inject
      # canonicals exactly as build_one() does, then emit into the temp dir.
      if build_skill_to_dir "$skill" "$c7_module" "$c7_tmp_pkgdir" >/dev/null 2>&1; then
        c7_rebuilt_pkg="$c7_tmp_pkgdir/${skill}.skill"
        c7_rebuilt_hash=$(skill_content_hash "$c7_rebuilt_pkg")
        if [[ -z "$c7_rebuilt_hash" ]]; then
          log "  WARN:  $skill — rebuild produced no hashable package; falling back to baseline-vs-package content compare (PASS, baseline matched)"
          log "  OK:    $skill (content baseline verified; staged-rebuild inconclusive)"
        elif [[ "$c7_rebuilt_hash" != "$c7_baseline" ]]; then
          log "  FAIL:  $skill — source content changed since build (rebuilt hash $c7_rebuilt_hash != committed baseline $c7_baseline); rebuild via core/deploy/tools/build-skill-packages.sh $skill"
          ISSUES=$((ISSUES + 1))
        else
          log "  OK:    $skill (content current — staged rebuild matches committed baseline)"
        fi
      else
        log "  WARN:  $skill — staged rebuild failed to run; falling back to baseline-vs-package content compare"
        if [[ "$c7_src_newer" == "true" ]]; then
          log "  FAIL:  $skill — source mtime newer than package and rebuild unavailable to confirm content; rebuild via core/deploy/tools/build-skill-packages.sh $skill"
          ISSUES=$((ISSUES + 1))
        else
          log "  OK:    $skill (content baseline verified; rebuild unavailable, mtime shows no source change)"
        fi
      fi
      rm -rf "$c7_tmp_pkgdir"
    else
      # Degraded: no rebuild available. The baseline-vs-live-package content
      # compare already passed; fall back on the mtime pre-filter as the only
      # available source-change signal (still better than nothing; logged).
      if [[ "$c7_src_newer" == "true" ]]; then
        log "  FAIL:  $skill — source mtime newer than package; python3/unzip unavailable to confirm by content — rebuild via core/deploy/tools/build-skill-packages.sh $skill"
        ISSUES=$((ISSUES + 1))
      else
        log "  OK:    $skill (content baseline verified; rebuild unavailable [python3/unzip], mtime shows no source change)"
      fi
    fi
  done

  # Warn-mode gate for Checks 8-10 (and downstream warn-mode checks).
  # MODE_FILE adapts to an operator-instance path-via-env-var per Spec
  # Surface 5.2 (C); falls back to legacy .claude/ location for compatibility.
  local DEPLOY_CHECK_MODE="warn"
  local MODE_FILE="$(pmo_instance_path)/deploy-check.mode"
  [[ -f "$MODE_FILE" ]] || MODE_FILE=".claude/hooks/deploy-check.mode"
  if [[ -f "$MODE_FILE" ]]; then
    local _mode
    _mode=$(cat "$MODE_FILE" 2>/dev/null | tr -d '[:space:]')
    case "$_mode" in
      enforce|warn|off) DEPLOY_CHECK_MODE="$_mode" ;;
    esac
  fi
  local WARN_LOG="$(pmo_instance_path)/deploy-check-warn-log.jsonl"

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

  # resolve_check_mode — per-check mode resolver (decouples a single check from
  # the shared deploy-check.mode cohort). Reads a CHECK-SPECIFIC mode file
  # "<check_id>.mode" from the same operator-instance base (and legacy
  # .claude/hooks/ fallback) as the shared MODE_FILE; if that file is absent or
  # carries an invalid value, FALLS BACK to the shared $DEPLOY_CHECK_MODE. Echoes
  # the resolved mode (enforce|warn|off). This lets one check graduate
  # warn→enforce independently of the ~12-check shared-mode cohort without
  # touching any other check's behavior — every other check keeps reading
  # $DEPLOY_CHECK_MODE directly and is byte-for-byte unchanged.
  #
  # Decoupling contract (per the g1-enforcement mode-decoupling scope): the
  # g1-enforcement check (Check 22) resolves its mode via this helper from a
  # dedicated `g1-enforcement.mode` file; with no such file present it falls back
  # to the shared mode → warn (the current default). The warn→enforce flip is
  # DEFERRED to a follow-on after the ≥3-day shakedown; this release ships warn.
  # Mode files are operator-instance runtime state and are NOT committed.
  resolve_check_mode() {
    local _check_id="$1"
    local _check_mode_file="$(pmo_instance_path)/${_check_id}.mode"
    [[ -f "$_check_mode_file" ]] || _check_mode_file=".claude/hooks/${_check_id}.mode"
    if [[ -f "$_check_mode_file" ]]; then
      local _cm
      _cm=$(cat "$_check_mode_file" 2>/dev/null | tr -d '[:space:]')
      case "$_cm" in
        enforce|warn|off) printf '%s' "$_cm"; return 0 ;;
      esac
    fi
    # No check-specific file (or invalid value) → fall back to the shared mode.
    printf '%s' "$DEPLOY_CHECK_MODE"
  }

  # flag_g1_enforcement — Check 22 (G1 enforcement) gating emit. Identical
  # semantics to flag_warn_or_issue, EXCEPT it switches on the check-specific
  # $G1_ENFORCEMENT_MODE (resolved at Check 22 start via resolve_check_mode
  # "g1-enforcement") rather than the shared $DEPLOY_CHECK_MODE. Structural G1
  # findings (G1-01/03/05a/06/09) route here. In enforce-mode → FAIL (increments
  # ISSUES); in warn-mode → WARN + jsonl, no ISSUES increment.
  flag_g1_enforcement() {
    local check_id="$1"
    local detail="$2"
    case "$G1_ENFORCEMENT_MODE" in
      enforce)
        log "  FAIL:  $check_id — $detail"
        ISSUES=$((ISSUES + 1))
        ;;
      warn)
        log "  WARN:  $check_id — $detail (warn-mode; flip g1-enforcement.mode to 'enforce' after the shakedown window)"
        local _ts
        _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        local _detail_escaped="${detail//\\/\\\\}"
        _detail_escaped="${_detail_escaped//\"/\\\"}"
        printf '{"ts":"%s","check":"%s","detail":"%s"}\n' "$_ts" "$check_id" "$_detail_escaped" >> "$WARN_LOG" 2>/dev/null || true
        ;;
    esac
  }

  # recommend_g1_enforcement — Check 22 NON-GATING advisory emit for the four
  # judgment-class G1 criteria (G1-02/04/05b/08). NEVER increments ISSUES in any
  # mode (not even enforce) — these are recommend-tier per gate-criteria-spec.md
  # § Gate 1 (G1 Enforcement-Layer Split: judgment → recommend-flag, never FAIL).
  # Emits a RECOMMEND line and appends to the warn-log with a "recommend" level
  # so advisory findings are distinguishable from gating WARN/FAIL entries. In
  # off-mode it stays silent (parity with the gating helpers).
  recommend_g1_enforcement() {
    local check_id="$1"
    local detail="$2"
    [[ "$G1_ENFORCEMENT_MODE" == "off" ]] && return 0
    log "  RECOMMEND:  $check_id — $detail (advisory; judgment-tier, never gate-blocking)"
    local _ts
    _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local _detail_escaped="${detail//\\/\\\\}"
    _detail_escaped="${_detail_escaped//\"/\\\"}"
    printf '{"ts":"%s","check":"%s","level":"recommend","detail":"%s"}\n' "$_ts" "$check_id" "$_detail_escaped" >> "$WARN_LOG" 2>/dev/null || true
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

  # Check 9 — Mirror-pair sync (advisory; warn-mode initial; required at flip-to-enforce)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (b)):
  #   posture: advisory   enforcement-surface: deploy-check.mode warn-window
  #            (becomes required when the operator flips deploy-check.mode to enforce)
  #   invariant: every workspace rules-mirror file (~/.claude/rules/<file>.md) is
  #              byte-identical to its in-repo source (modulo the OPERATIONS.md
  #              depth-adjusted-link normalization) — asserted by diff -q.
  #   falsification: edit a workspace mirror so it diverges from its core/rules/
  #                  source -> this check WARNs (advisory) / FAILS (post-flip).
  #
  # Semantics per Spec Surface 5.4 + ADR-008 Consequence 2:
  #   in-repo source `core/rules/<file>.md` OR `release/governance/release-process.md`
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
      "release/governance/release-process.md:$DEPLOY_ROOT/.claude/rules/release-process.md"
      "core/governance/OPERATIONS.md:operations/OPERATIONS.md"
    )
    for pair in "${MIRROR_PAIRS[@]}"; do
      local c9_left="${pair%%:*}"
      local c9_right="${pair##*:}"
      # A declared SOURCE (left, in-repo) that does not exist is a config error:
      # a typo'd or moved path silently disables the pair's enforcement (the
      # #1104 failure class). WARN on it — never silent-SKIP. A missing MIRROR
      # (right, ~/.claude/rules/) is legitimately operator-instance-absent in
      # the public repo / CI / a fresh checkout, so that stays a clean SKIP.
      if [[ ! -f "$c9_left" ]]; then
        flag_warn_or_issue "mirror-sync" "$c9_left: declared MIRROR_PAIRS source does not exist (typo or moved path — pair cannot be enforced)"
        continue
      fi
      if [[ ! -f "$c9_right" ]]; then
        log "  SKIP:  $c9_left ↔ $c9_right (workspace mirror absent — operator-instance)"
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

    # Directory-shaped mirror set (per ADR-030 #18 hook-registry split): the
    # bypass-mode-readiness index above mirrors 1:1 as a single MIRROR_PAIRS
    # entry; its per-hook drop-in SOURCES under core/rules/bypass-mode-readiness/
    # each mirror 1:1 too. Enumerate them and byte-diff each against its
    # ~/.claude/rules/bypass-mode-readiness/<basename> counterpart, preserving the
    # same SKIP-on-missing semantics (so the public repo, where the .claude/rules/
    # mirror is operator-instance and absent, stays a clean SKIP — no false drift)
    # and the same warn-mode posture.
    if [[ -d core/rules/bypass-mode-readiness ]]; then
      local c9_hook_src
      for c9_hook_src in core/rules/bypass-mode-readiness/*.md; do
        [[ -e "$c9_hook_src" ]] || continue
        local c9_hook_mir="$DEPLOY_ROOT/.claude/rules/bypass-mode-readiness/$(basename "$c9_hook_src")"
        if [[ ! -f "$c9_hook_src" ]] || [[ ! -f "$c9_hook_mir" ]]; then
          log "  SKIP:  $c9_hook_src ↔ $c9_hook_mir (one or both missing)"
          continue
        fi
        if diff -q "$c9_hook_src" "$c9_hook_mir" >/dev/null 2>&1; then
          log "  OK:    $c9_hook_src ↔ $c9_hook_mir (byte-identical)"
        else
          flag_warn_or_issue "mirror-sync" "$c9_hook_src ↔ $c9_hook_mir divergence"
          diff -u "$c9_hook_src" "$c9_hook_mir" 2>/dev/null | head -20 | sed 's/^/         /' || true
        fi
      done
    fi
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
  #
  # DORMANT (not retired): HARNESS_LIST is empty because the account-switcher
  # harness was extracted at "Phase 3"; the loop below is complete and correct.
  # REACTIVATION ANCHOR — issue #375 (carry the v1 .claude/ harness into v2).
  #   Condition: reactivates AUTOMATICALLY when HARNESS_LIST is non-empty (a
  #   harness artifact is registered) — no code change required; the empty-array
  #   guard below (ADR-008 Rule 2 + Spec Surface 3 SKIP logging) yields to the
  #   loop the moment an artifact appears. Registry: see cmd_check_lifecycle.
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
    local c14_allowlist="$(pmo_instance_path)/skip-doc-link-check.txt"
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
  #   Layer 2 (fallback): a check-release-corpus.sh wrapper under the
  #     operator-instance tools/ dir (resolved via pmo_instance_path)
  #     invoking core/deploy/tools/check-doc-links.py against
  #     operator-instance release corpus paths. Authoring deferred to the
  #     P2.5-T1 (onboarding) milestone per FX-Check15 disposition.
  #   Layer 3 (release-pipeline gates): Stage 12 + Stage 13 chip prompts +
  #     Procedure 7 Step 4 completion-verification fire
  #     regardless of operator's Layer 1/2 choice (release-notes presence +
  #     CHANGELOG + GitHub Release Surface 1 emit).
  #
  # Evolution: an earlier Check 15 scanned the in-repo release corpus; a
  # subsequent wave gated it on the operator-instance-path env var; this retirement
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
  # aging / 18d canonical_doc path resolution (non-resolving path = finding, the
  # presence complement to 18b's silent skip — #661). Warn-mode initial per
  # bypass-mode-readiness.md §Shakedown (Checks
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
        log "  OK:    catalog complete, paths resolve, anchors consistent, no overdue reviews"
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
    local c19_log="$(pmo_instance_path)/pipeline-event-log.md"
    local c19_write_log="$(pmo_instance_path)/pipeline-event-log-write.log"
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
  # only enforcement. Intake-scope RATIFIED bundled-only: the
  # population stays open `status: bundled` — Check 22 is NOT extended to
  # `status: proposed`. The earlier "intake-time hook (Layer a)" deferral's
  # reopening condition is unmet (warn-log empty), and Layer-A form-required
  # (intake template `validations: required: true`) already delivers the
  # intake-time HARD-STOP that a proposed-status content-sweep would target —
  # earlier and cheaper. Lowest blast radius; mirrors deploy.sh --check
  # warn-mode shakedown precedent (Checks 8/9/10/14/15/18/19/20/21).
  #
  # COVERAGE (per gate-criteria-spec.md § Gate 1 + its G1 Enforcement-Layer
  # Split): Check 22 (Layer-B gate) now EVALUATES ALL 9 G1 criteria —
  # ENFORCES the 5 structural (FAIL-capable) + RECOMMEND-FLAGS the 4 judgment
  # (advisory, never FAIL).
  #
  # Structural criteria ENFORCED (gate-checked; emit via flag_g1_enforcement):
  #   G1-01  title prefix `[Category]:` (improvement) / `[Bug]:` (bug per
  #          Adapter G1-01-Bug) / `[Observation]:` (observation per Adapter
  #          G1-01-Obs)
  #   G1-03  evidence-quality labels present in body — at least one
  #          [SOURCE]/[INFERRED]/[CONTEXT]/[ASSUMPTION ...]/[RECOMMENDED];
  #          n/a for observation
  #   G1-05a AC structural pattern — each AC checkbox bullet must match one of
  #          the three G1-05a patterns: verb-first (verify/check/confirm/
  #          assert/ensure/validate) | backtick-wrapped path + state verb
  #          (contains/includes/has) | `predicate:` prefix. Adapter G1-05-Bug
  #          accepts the bug-narrative AC phrase for bug bodies; n/a for
  #          observation (no AC field). Pattern (d) behavioral/`method:` is a
  #          recommend-only refinement, not gated here (structural detector
  #          stays on the three lexical patterns + the bug adapter).
  #   G1-06  Priority `P1`-`P4` in improvement body OR Severity `P1`-`P4` in
  #          bug body per Adapter G1-06-Bug; n/a for observation
  #   G1-09  label-body template match — label_template (Step 1) must agree
  #          with inferred_template (Step 2) per Template Detection Logic at
  #          gate-criteria-spec.md § Gate 1
  #
  # Judgment criteria RECOMMEND-FLAGGED (advisory; emit via
  # recommend_g1_enforcement — NEVER increments ISSUES, in any mode):
  #   G1-02  description / bug-narrative actionable (presence-proxy: improvement
  #          body has a non-empty Description; bug body has the narrative)
  #   G1-04  Proposed Change names a file or protocol (improvement only)
  #   G1-05b AC verifiable beyond the structural check — no unreplaced `<...>`
  #          placeholder slots, no commented-out bullets
  #   G1-08  implementability proxy — body contains no obvious undefined-term
  #          markers (advisory only; full G1-08 is human-judgment)
  #   These are recommend-tier per gate-criteria-spec.md § Gate 1; surfacing
  #   them as advisory RECOMMENDs (not FAILs) honors the "right tool, right
  #   time" framing — they never gate-block routine intake.
  #
  # MODE DECOUPLING (g1-enforcement mode-decoupling scope): this check's
  # mode is RESOLVED via resolve_check_mode "g1-enforcement" into
  # $G1_ENFORCEMENT_MODE at Check 22 start — reading a dedicated
  # `g1-enforcement.mode` file (operator-instance path, same fallback pattern
  # as deploy-check.mode) and FALLING BACK to the shared $DEPLOY_CHECK_MODE
  # when that file is absent. This lets G1 enforcement graduate warn→enforce
  # INDEPENDENTLY of the ~12-check shared-mode cohort. Every OTHER check still
  # reads $DEPLOY_CHECK_MODE directly and is byte-for-byte unchanged. With no
  # `g1-enforcement.mode` file present, this check falls back to the shared
  # mode → warn (the current default). The warn→enforce flip is DEFERRED to a
  # follow-on (after the ≥3-day shakedown); this release ships WARN. Mode
  # files are operator-instance runtime state and are NOT committed.
  #
  # Template Detection Logic — pragmatic body-marker variant:
  #   gate-criteria-spec.md § Gate 1 (Template Detection Logic, Step 2) cites
  #   `### Priority` AND `### Category` AND `### Description` for improvement,
  #   but the actual rendered improvement issue bodies use `**Priority:**` and
  #   `**Category:**` (dropdown bold) rather than `### Priority` and
  #   `### Category` (section headers). This check uses the unique textarea
  #   section headers that DO appear in rendered bodies:
  #     bug         → `### Reproduction Steps`
  #     observation → `### What is missing?`
  #     improvement → `### Proposed Change`
  #   The pragmatic markers are unique to each template per the body-marker-
  #   uniqueness verification in gate-criteria-spec.md § Gate 1.
  #
  # Sub-checks:
  #   22a token   — verifies `gh auth status` reports `repo` scope; if
  #       missing, the check warns once and exits cleanly
  #   22b per-issue — iterates open `status: bundled` issues; applies
  #       Template Detection Logic; ENFORCES G1-01/G1-03/G1-05a/G1-06/G1-09
  #       (structural) + RECOMMEND-FLAGS G1-02/G1-04/G1-05b/G1-08 (judgment)
  #       per applies-to triple using Adapter Blocks G1-01-Bug / G1-01-Obs /
  #       G1-05-Bug / G1-06-Bug
  #
  # The check runs whenever AUDIT_REPO resolves to a tracker; with no tracker
  # configured the bundled-issue query returns an empty set and it no-ops.
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks
  # 8/9/10/14/15/18/19/20/21 precedent); flip-to-enforce DEFERRED to a follow-on
  # after ≥3-day warn-log review with zero false positives — flipped via
  # the dedicated `g1-enforcement.mode` file (NOT the shared deploy-check.mode),
  # so this check graduates independently of the shared-mode cohort. Operator
  # may consider adding Layers (a) intake-time hook and (c) scheduled cadence
  # after a 2-3 release calibration window: "keep in mind the right time to
  # perform this work and the tools/processes available currently."
  #
  # Mode is resolved per-check (NOT the shared $DEPLOY_CHECK_MODE) — the check
  # runs whenever $G1_ENFORCEMENT_MODE is not "off". Resolved at block start.
  # `local` here matches DEPLOY_CHECK_MODE's scope; bash dynamic scoping makes
  # it visible to flag_g1_enforcement / recommend_g1_enforcement (called below).
  local G1_ENFORCEMENT_MODE
  G1_ENFORCEMENT_MODE="$(resolve_check_mode "g1-enforcement")"
  if [[ "$G1_ENFORCEMENT_MODE" != "off" ]]; then
    log "Check 22: G1 enforcement on bundled issues (mode=${G1_ENFORCEMENT_MODE})"

    # 22a — gh auth scope check (issue list read requires `repo` for
    # private repos; this is non-fatal — check warns once and exits if
    # scope missing, since the check is non-gate-blocking detection)
    local c22_scope_ok=true
    if ! gh auth status --hostname github.com 2>&1 | /usr/bin/grep -qE '\brepo\b'; then
      flag_g1_enforcement "g1-enforcement" "gh auth scope missing 'repo' — cannot iterate bundled issues (run 'gh auth refresh -s repo')"
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
      #  4. ENFORCE G1-01 / G1-03 / G1-05a / G1-06 / G1-09 (structural) +
      #     RECOMMEND-FLAG G1-02 / G1-04 / G1-05b / G1-08 (judgment) per the
      #     applies-to triple
      local _num _title _body _labels _label_template _inferred _template
      local _has_imp _has_bug _has_obs _label_total
      local _bm_repro _bm_obswhat _bm_propchange _title_ok _title_reason
      local _ac_lines _ac_total _ac_bad _ac_line _ac_norm _ac_ok
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
          flag_g1_enforcement "g1-enforcement" \
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
          flag_g1_enforcement "g1-enforcement" \
            "issue #${_num} — G1-09 FAIL: label=${_label_template}, body=${_inferred} (label-body template mismatch — relabel or rewrite body per gate-criteria-spec.md self-repair)"
          c22_finding_count=$((c22_finding_count + 1))
          continue
        fi

        # G1-01 — title informativeness floor (SYNTACTIC floor only; the
        # semantic informativeness BAR lives in the intake-style-guide.md §7
        # rubric + intake-desk elicitation, not here). Template-agnostic — the
        # former per-template prefix adapters (G1-01-Bug/G1-01-Obs) are retired;
        # all three templates share one prefix-less floor. This catches a
        # leftover '[...]:' type prefix (type is on the label, not the title)
        # and a bare area-slug / single-token title; it does NOT and cannot
        # judge whether a well-formed multi-word title is actually informative.
        _title_ok=true
        _title_reason=""
        # F1 — no leading bracket type/category prefix
        if printf '%s' "$_title" | /usr/bin/grep -qE '^[[:space:]]*\[[^]]+\]:[[:space:]]'; then
          _title_ok=false; _title_reason="leftover '[...]:' type prefix (type is on the label — drop it)"
        # F2/F3 — substance floor: bare slug (no internal whitespace) OR too short
        elif ! printf '%s' "$_title" | /usr/bin/grep -qE '[^[:space:]]+[[:space:]]+[^[:space:]]+'; then
          _title_ok=false; _title_reason="bare slug / single token (name the object + the change, >= 2 words)"
        elif [[ "${#_title}" -lt "${G1_TITLE_MIN_CHARS:-12}" ]]; then
          _title_ok=false; _title_reason="too short (${#_title} chars; informative summary expected)"
        fi
        if [[ "$_title_ok" != "true" ]]; then
          flag_g1_enforcement "g1-enforcement" \
            "issue #${_num} — G1-01 FAIL: title not an informative summary — ${_title_reason} (see intake-style-guide.md §7)"
          c22_finding_count=$((c22_finding_count + 1))
        fi

        # G1-03 — evidence-quality labels in body (improvement + bug,
        # NOT observation per applies-to triple)
        if [[ "$_template" == "improvement" || "$_template" == "bug" ]]; then
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '\[(SOURCE|INFERRED|CONTEXT|RECOMMENDED|ASSUMPTION)' ; then
            flag_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-03 FAIL: no evidence-quality labels found in body ([SOURCE]/[INFERRED]/[CONTEXT]/[ASSUMPTION – CONFIRM]/[RECOMMENDED])"
            c22_finding_count=$((c22_finding_count + 1))
          fi
        fi

        # G1-06 — Priority (improvement) OR Severity P-level (bug per
        # Adapter G1-06-Bug); n/a observation
        if [[ "$_template" == "improvement" ]]; then
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '\*\*Priority:\*\*[[:space:]]*P[1-4]'; then
            flag_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-06 FAIL: Priority field missing or no P1-P4 value (improvement.yml expects '**Priority:** P1-Urgent'-style anchor)"
            c22_finding_count=$((c22_finding_count + 1))
          fi
        elif [[ "$_template" == "bug" ]]; then
          # Adapter G1-06-Bug — Severity P-level digit canonical
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '\*\*Severity:\*\*[[:space:]]*P[1-4]'; then
            flag_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-06 FAIL: Severity field missing or no P1-P4 value (Adapter G1-06-Bug — bug.yml expects '**Severity:** P1-Blocker'-style anchor)"
            c22_finding_count=$((c22_finding_count + 1))
          fi
        fi

        # ── G1-05a — AC structural pattern (NEW; structural FAIL) ──────────
        # Applies to improvement + bug (both carry an Acceptance Criteria
        # field); n/a for observation (no AC field per applies-to triple).
        # Extract every AC checkbox bullet (GitHub task-list `- [ ]` / `- [x]`)
        # from the body, then assert each bullet matches ONE of the three
        # G1-05a structural patterns:
        #   (a) verb-first — verify|check|confirm|assert|ensure|validate
        #   (b) backtick-path + state verb — a backtick-wrapped token AND a
        #       contains|includes|has state verb
        #   (c) explicit predicate — `predicate:` prefix
        # Adapter G1-05-Bug (bug bodies): also accept the literal bug-narrative
        # AC phrases. Pattern (d) behavioral/`method:` is a recommend-only
        # refinement (gate-criteria-spec.md § Gate 1) — NOT gated here.
        if [[ "$_template" == "improvement" || "$_template" == "bug" ]]; then
          # Pull AC checkbox bullets. Match leading `- [ ]` / `- [x]` / `- [X]`
          # (any indentation). This is the gateable AC surface; non-checkbox
          # prose in the AC section is not a bullet and is not checked.
          _ac_lines=$(printf '%s' "$_body" | /usr/bin/grep -nE '^[[:space:]]*-[[:space:]]*\[[ xX]?\][[:space:]]+' || true)
          _ac_total=0
          _ac_bad=0
          if [[ -n "$_ac_lines" ]]; then
            while IFS= read -r _ac_line; do
              [[ -n "$_ac_line" ]] || continue
              _ac_total=$((_ac_total + 1))
              # Strip the leading `<n>:- [ ] ` prefix down to the AC content.
              _ac_norm=$(printf '%s' "$_ac_line" | /usr/bin/sed -E 's/^[0-9]+:[[:space:]]*-[[:space:]]*\[[ xX]?\][[:space:]]+//')
              _ac_ok=false
              # (a) verb-first (case-insensitive)
              if printf '%s' "$_ac_norm" | /usr/bin/grep -qiE '^(verify|check|confirm|assert|ensure|validate)\b'; then
                _ac_ok=true
              # (b) backtick-wrapped path/token AND a state verb
              elif printf '%s' "$_ac_norm" | /usr/bin/grep -qE '`[^`]+`' \
                && printf '%s' "$_ac_norm" | /usr/bin/grep -qiE '\b(contains|includes|has)\b'; then
                _ac_ok=true
              # (c) explicit predicate: prefix
              elif printf '%s' "$_ac_norm" | /usr/bin/grep -qiE '^predicate:'; then
                _ac_ok=true
              fi
              # Adapter G1-05-Bug — bug-narrative AC phrase (bug bodies only)
              if [[ "$_ac_ok" != "true" && "$_template" == "bug" ]]; then
                if printf '%s' "$_ac_norm" | /usr/bin/grep -qiE 'reproduction steps no longer trigger actual behavior|running reproduction steps produces expected behavior'; then
                  _ac_ok=true
                fi
              fi
              [[ "$_ac_ok" == "true" ]] || _ac_bad=$((_ac_bad + 1))
            done < <(printf '%s\n' "$_ac_lines")
          fi
          if [[ "$_ac_bad" -gt 0 ]]; then
            flag_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-05a FAIL: ${_ac_bad} of ${_ac_total} AC bullet(s) match no G1-05a structural pattern (verb-first / backtick-path+state-verb / 'predicate:'$([[ "$_template" == "bug" ]] && printf ' / bug-narrative phrase'); see gate-criteria-spec.md § Gate 1 self-repair)"
            c22_finding_count=$((c22_finding_count + 1))
          fi
        fi

        # ── Recommend pass — judgment criteria (advisory; NEVER FAIL) ──────
        # G1-02 / G1-04 / G1-05b / G1-08 are recommend-tier per
        # gate-criteria-spec.md § Gate 1 (G1 Enforcement-Layer Split). Emitted
        # via recommend_g1_enforcement — RECOMMEND lines that never increment
        # ISSUES in any mode and never add to c22_finding_count (which counts
        # only gating findings). Lightweight content proxies, not the full
        # judgment evaluation (that remains a human/LLM gate-assist task).

        # G1-02 — description / bug-narrative actionable (presence proxy).
        if [[ "$_template" == "improvement" ]]; then
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '^### Description[[:space:]]*$'; then
            recommend_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-02 RECOMMEND: no '### Description' section detected — confirm the change is stated as an actionable WHAT (not just an observation)"
          fi
        elif [[ "$_template" == "bug" ]]; then
          if ! printf '%s' "$_body" | /usr/bin/grep -qE '^### (Expected Behavior|Actual Behavior)[[:space:]]*$'; then
            recommend_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-02 RECOMMEND: bug narrative incomplete — confirm Reproduction Steps + Expected + Actual are all present (reproduce-and-observe must be possible)"
          fi
        fi

        # G1-04 — Proposed Change names a file or protocol (improvement only).
        if [[ "$_template" == "improvement" ]]; then
          if printf '%s' "$_body" | /usr/bin/grep -qE '^### Proposed Change[[:space:]]*$' \
            && ! printf '%s' "$_body" | /usr/bin/grep -qE '`[^`]+`|\.(md|sh|ya?ml|py|toml|json)\b|OPERATIONS\.md|CLAUDE\.md|SKILL\.md'; then
            recommend_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-04 RECOMMEND: Proposed Change names no obvious file/protocol — confirm the WHAT identifies the affected file(s) or protocol(s)"
          fi
        fi

        # G1-05b — AC verifiable beyond the structural check (improvement + bug):
        # no unreplaced `<...>` placeholder slots in AC bullets, no commented-out
        # bullets. Scoped to the AC checkbox lines captured for G1-05a.
        if [[ "$_template" == "improvement" || "$_template" == "bug" ]]; then
          if [[ -n "$_ac_lines" ]]; then
            if printf '%s' "$_ac_lines" | /usr/bin/grep -qE '<[A-Za-z][^>]*>'; then
              recommend_g1_enforcement "g1-enforcement" \
                "issue #${_num} — G1-05b RECOMMEND: AC bullet(s) contain unreplaced '<...>' placeholder slot(s) — fill the templated slots before bundling"
            fi
          fi
          if printf '%s' "$_body" | /usr/bin/grep -qE '^[[:space:]]*<!--[[:space:]]*-[[:space:]]*\[[ xX]?\]'; then
            recommend_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-05b RECOMMEND: commented-out AC bullet(s) detected — un-comment or remove them"
          fi
        fi

        # G1-08 — implementability proxy (improvement + bug). Full G1-08 is a
        # fresh-session-pickup human/LLM judgment; the automatable proxy is a
        # body-substance floor: a very short body is unlikely to give a fresh
        # agent enough to implement without clarifying questions. Advisory only.
        if [[ "$_template" == "improvement" || "$_template" == "bug" ]]; then
          if [[ "${#_body}" -lt 200 ]]; then
            recommend_g1_enforcement "g1-enforcement" \
              "issue #${_num} — G1-08 RECOMMEND: body is very short (${#_body} chars) — confirm a fresh Claude Code session could implement it without clarifying questions"
          fi
        fi

      done < <(printf '%s' "$c22_issues_json" | jq -c '.[]')

      if [[ "$c22_finding_count" -eq 0 ]]; then
        log "  OK:    0 gating G1 findings across ${c22_issue_count} bundled issue(s) (structural enforced: G1-01/03/05a/06/09; judgment recommend-flagged: G1-02/04/05b/08)"
      else
        log "  ${c22_finding_count} gating G1 finding(s) emitted across ${c22_issue_count} bundled issue(s) (mode=${G1_ENFORCEMENT_MODE}; judgment criteria recommend-flagged separately, non-gating)"
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

  # ─── Check 24: Initiative-roadmap staleness scan — RETIRED (number reserved) ──
  # Per ADR-012 (Roadmap-instance de-scope, 2026-06-02) + core/standards/
  # initiative-roadmap-framework.md §10. Check 24 was the roadmap-freshness
  # enforcement surface (24a: frontmatter schema lint; 24b: 90-day
  # `last_reviewed:` staleness scan over the roadmap corpus). It was DELETED when
  # initiative-roadmap *instances* moved from the tracked tree to git-ignored
  # authoring (<OPERATOR_INSTANCE_ROADMAPS_PATH>, default the in-repo /roadmaps/
  # home per ADR-046 — folder + README tracked, instances git-ignored). No
  # *tracked* roadmap corpus remains for this check to scan, and roadmap freshness
  # stays an operator-local discipline — the /roadmaps/ home does NOT revive the
  # in-repo enforcement (the framework convention is retained; the check is not).
  #
  # Check numbering: gap (24 retired) is RESERVED for citation continuity — the
  # number is referenced by ADR-012, the roadmap framework, and the v1.21 release
  # plan ("24 is retired-reserved"; #318's check was assigned 34 specifically
  # because 24 was already reserved). It must NOT be reused. The next NEW
  # top-level check number is 39 (see cmd_check_lifecycle). Mirrors the Check 15
  # retirement precedent above.

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
  # under $(pmo_instance_path)/analysis/
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
    local c23_needles; c23_needles="$(pmo_localized_needles)"
    # Visible WARN when the needle file is unresolved (#1830 Part 4): an absent /
    # unreadable needle file silently disables the DC1 coworker/org-tier pass
    # below (the very fail-open the resolver story closes). Surface it instead of
    # no-opping in silence — DC1's generic-PII regexes still run; only the
    # operator-specific needle match is skipped. WARN, not FAIL: a fresh clone
    # legitimately has no needle file yet, and the pre-commit hook is the
    # fail-closed enforcement surface for that gap.
    if [[ ! -r "$c23_needles" ]]; then
      log "  WARN:  Check 25 — localized-context needle file unresolved ($c23_needles); DC1 operator/coworker-needle pass skipped (generic-PII patterns still enforced). Scaffold it via install.sh/update.sh from core/config/localized-context-needles.txt.example"
    fi
    # Operator project keys (e.g. tracker/Jira keys) load at runtime from the
    # gitignored project-keys file via the DC3 key pass below. The tracked DC3
    # detector therefore carries NO real project keys — baking literal keys into
    # the detector would make it a leak of the very identifiers it hunts (same
    # self-containment rationale as the DC1 needle file). One key per line; blank
    # lines and `#` comments ignored. Absent file → DC3 matches structural shapes
    # only (no-op for key-derived patterns).
    local c23_project_keys="${PMO_PROJECT_KEYS:-$(pmo_instance_path)/project-keys.txt}"
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
  # a corresponding ${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/notes/vX.Y_RELEASE_NOTES.md file.
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
    local c26_log="$(pmo_instance_path)/RELEASE_LOG.md"
    local c26_allowlist=".claude/skip-release-note-check.txt"
    local c26_cutoff="${RELEASE_NOTE_CHECK_CUTOFF:-v1.00}"
    local c26_notes_dir="$(pmo_instance_path)/releases/notes"

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
  # DORMANT (not retired): harness/ is absent at v2 root because the
  # account-switcher harness was extracted at "Phase 3"; the find below yields
  # zero files and the check no-ops cleanly via the "lint skipped" message. The
  # scan logic is complete and correct.
  # REACTIVATION ANCHOR — issue #375 (carry the v1 .claude/ harness into v2).
  #   Condition: reactivates AUTOMATICALLY when `find harness -path
  #   '*/commands/*.md'` yields >=1 file — no code change required. Registry: see
  #   cmd_check_lifecycle.
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
  # operator-instance ${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance corpus) — the tracked release/releases/
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

  # ─── Check 47: Release-body drift (published Release body == in-repo note) ──
  # Standing audit gate for the release-notes-standard.md §5.1 invariant: the
  # published GitHub Release body MUST equal the frontmatter-stripped in-repo
  # source-of-record note. Sits BESIDE Check 32 (release-corpus completeness):
  # Check 32 verifies a published Release EXISTS for a post-cutover row; this
  # check verifies its BODY has not drifted from the note. The canonical incident
  # (the v2.26 close) shipped an ad-hoc Release body that diverged from the in-repo
  # note and stayed stale through a note-correction PR — nothing flagged it until
  # the operator caught it. This is the standing detective backstop for that class.
  #
  # DELEGATES to release/tools/check-release-body-drift.sh — the SINGLE source of
  # the body-equality logic (the §5.1 sed-strip + the json-body compare live in
  # exactly one place; this check does not re-derive them). DETECTIVE-ONLY: it
  # flags drift, never re-emits the Release.
  #
  # gh-GUARDED (reuses Check 32's guard verbatim): the compare needs a network
  # read (gh release view). When gh is absent OR unauthenticated the check
  # resolves to N/A (never FAIL), so a disconnected deploy.sh --check run does
  # not red-fail here — the tool itself also returns exit 2 (N/A) in that case.
  #
  # CUTOVER-SCOPED + DORMANT-BY-DEFAULT: like Check 32's published-Release
  # sub-check, the drift assertion runs only for LOG rows at/after a SEPARATE,
  # later $c47_cutoff (RELEASE_BODY_DRIFT_CHECK_CUTOFF), which defaults to the
  # __none__ sentinel — so the network-dependent check is DORMANT until an
  # operator opts in. This (a) avoids retroactively warning on legitimate
  # historical rows whose Release bodies predate the §5.1 transform, and (b)
  # honors the reflexive-pipeline-loop discipline — the introducing release
  # closes under pre-merge rules and is NOT bound by its own check.
  #
  # Warn-mode initial per .claude/hooks/deploy-check.mode (Checks 8/9/10/14/15/18-
  # 23/25-29/31/32 precedent); flip-to-enforce after a >=3-day warn-log review with
  # zero false positives (GitHub body normalization edge cases — CRLF / trailing
  # newline — are the calibration target; the tool already trims a trailing nl).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 47: Release-body drift (published Release body == frontmatter-stripped in-repo note)"
    local c47_log="release/releases/RELEASE_LOG.md"
    local c47_tool="release/tools/check-release-body-drift.sh"
    # Separate, later cutover for this network-dependent assertion. Sentinel
    # __none__ => no row is in scope (the drift check is dormant by default).
    local c47_cutoff="${RELEASE_BODY_DRIFT_CHECK_CUTOFF:-__none__}"

    if [[ "$c47_cutoff" == "__none__" ]]; then
      log "  N/A:   release-body drift check dormant (RELEASE_BODY_DRIFT_CHECK_CUTOFF unset) — opt in by setting it to the first §5.1-transform release"
    elif [[ ! -x "$c47_tool" ]]; then
      flag_warn_or_issue "release-body-drift" \
        "drift tool not executable: $c47_tool — cannot assert the §5.1 published-body invariant"
    elif ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
      # gh-guard: offline/unauth => N/A (never FAIL), mirroring Check 32/39.
      log "  N/A:   release-body drift check skipped (gh offline/unauthenticated) — reuses Check 32/39 gh-guard SKIP semantics"
    elif [[ ! -f "$c47_log" ]]; then
      flag_warn_or_issue "release-body-drift" \
        "$c47_log not found; cannot enumerate logged releases for the §5.1 drift check"
    else
      # Enumerate post-cutover release versions from the LOG (LOG file order).
      local c47_rows
      c47_rows=$(/usr/bin/grep -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$c47_log" 2>/dev/null \
        | /usr/bin/awk -F ' \\| ' '{
            v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v); print v
          }') || c47_rows=""

      local c47_past_cutoff=false
      local c47_targets=0
      local c47_findings=0
      local c47_output=""
      local _v47 _d47_out _d47_exit
      while IFS= read -r _v47; do
        [[ -n "$_v47" ]] || continue
        if [[ "$c47_past_cutoff" == "false" && "$_v47" == "$c47_cutoff"* ]]; then
          c47_past_cutoff=true
        fi
        [[ "$c47_past_cutoff" == "true" ]] || continue
        c47_targets=$((c47_targets + 1))

        _d47_exit=0
        _d47_out=$("$c47_tool" "$_v47" --quiet 2>&1) || _d47_exit=$?
        case "$_d47_exit" in
          0) : ;;  # MATCH — no finding
          1)       # DRIFT — warn (never FAIL)
            c47_output+="${_v47}: published Release body != frontmatter-stripped in-repo note (§5.1 drift)"$'\n'
            c47_findings=$((c47_findings + 1))
            ;;
          2) log "  N/A:   ${_v47} drift sub-check skipped (gh offline/unauth at tool layer)" ;;
          3) log "  N/A:   ${_v47} has no published Release or note to compare (Surface 1 absent — Check 32 owns existence)" ;;
          *) c47_output+="${_v47}: drift tool returned unexpected exit ${_d47_exit}"$'\n'; c47_findings=$((c47_findings + 1)) ;;
        esac
      done <<<"$c47_rows"

      if [[ $c47_findings -eq 0 ]]; then
        log "  OK:    all $c47_targets logged release(s) on/after $c47_cutoff have a published Release body matching their in-repo note (§5.1 invariant holds)"
      else
        flag_warn_or_issue "release-body-drift" \
          "$c47_findings §5.1 body-drift finding(s) across $c47_targets logged release(s) — a published Release body diverged from its source-of-record note; re-emit per release-notes-standard.md §5.6"
        printf '%s' "$c47_output" | head -10 | sed 's/^/         /'
        if [[ $c47_findings -gt 10 ]]; then
          log "         ... ($((c47_findings - 10)) more)"
        fi
      fi
    fi
  fi

  # ─── Check 48: Close-completeness (scaffold-independent Stage-13 output-set) ──
  # The scaffold-independent enforcement of the rigor-invariance principle
  # (hub-spoke-bridge.md Procedure 1 + ADR-048). For every VERIFIED RELEASE_LOG row
  # at/after the cutover, asserts the COMPLETE canonical Stage-13 output-set is
  # present on main — the umbrella over Check 32 (companion-presence): same LOG-row
  # iteration model, but VERIFIED-scoped and asserting the FULL set (NOTES + §3.2
  # note-content + INDEX + DIGEST + CHANGELOG + .version + tag + Surface-1 Release +
  # §5.1 body-drift). It re-implements NONE of those engines — note-content delegates
  # to lint_release_corpus.py, body-drift to check-release-body-drift.sh, and
  # companion-presence to the same path resolution Check 32 uses (the shared
  # _cc_compute_verdict body, factored to top level above — DD1, like version-freeness).
  #
  # WHY scaffold-independent: it fires on a plain `git`-checkout + `deploy.sh --check`
  # with no scaffold, no sub-task body, no hub session — it reads main's state, not
  # the execution path (spoke / hub-direct / chore-PR fallback). That is the machine
  # backstop the Rigor-Invariance Principle names; the Sub-Task Template attestation
  # is the human-readable forcing function.
  #
  # Sits BESIDE Check 32 (not folded into it) so Check 32's in-flight warn-mode
  # shakedown — DEPLOYED-companion-presence — is undisturbed while Check 48 owns the
  # VERIFIED-full-set-completeness contract. Inherits Check 32's LOG-row blind spot
  # (a never-written LOG row is invisible — owned by the close-time Step 4 table).
  #
  # DORMANT-BY-DEFAULT + warn-mode-initial: gated on a per-check mode via
  # resolve_check_mode "close-completeness" (independent graduation from the shared
  # cohort), and the assertion itself is DORMANT until CLOSE_COMPLETENESS_CHECK_CUTOFF
  # is set (the verdict SKIPs). The cutover is anchored strictly AFTER this release's
  # (v2.37) merge — the reflexive-pipeline-loop discipline: a release never gates its
  # own close. The CI-blocking switch is the committed .github/close-completeness.enforce
  # sentinel (read by the workflow, mirroring version-freeness).
  CLOSE_COMPLETENESS_MODE="$(resolve_check_mode "close-completeness")"
  if [[ "$CLOSE_COMPLETENESS_MODE" != "off" ]]; then
    log "Check 48: Close-completeness (every VERIFIED RELEASE_LOG row has the full Stage-13 output-set on main)"
    local cc48_verdict cc48_tok
    # _cc_compute_verdict emits the verdict on stdout and any per-row detail on
    # stderr; capture stdout for the token, let stderr flow to the run log.
    cc48_verdict="$(_cc_compute_verdict "lifecycle")"
    cc48_tok="${cc48_verdict%% *}"
    case "$cc48_tok" in
      SKIP)
        log "  N/A:   ${cc48_verdict#SKIP }"
        ;;
      CLEAN)
        log "  OK:    all ${cc48_verdict#CLEAN } VERIFIED release(s) in scope have the complete Stage-13 output-set on main"
        ;;
      INCOMPLETE)
        # "INCOMPLETE <findings> <targets>"
        local _cc48_rest="${cc48_verdict#INCOMPLETE }"
        local _cc48_n="${_cc48_rest%% *}" _cc48_m="${_cc48_rest##* }"
        # Route through the check-specific mode (close-completeness.mode), NOT the
        # shared flag_warn_or_issue mode — Check 48 graduates independently.
        case "$CLOSE_COMPLETENESS_MODE" in
          enforce)
            log "  FAIL:  close-completeness — $_cc48_n finding(s) across $_cc48_m VERIFIED row(s): a close dropped a Stage-13 output (see stderr detail); a scaffold abbreviation never waives a codified Phase step — hub-spoke-bridge.md Procedure 1 / ADR-048"
            ISSUES=$((ISSUES + 1))
            ;;
          warn)
            log "  WARN:  close-completeness — $_cc48_n finding(s) across $_cc48_m VERIFIED row(s) (warn-mode; flip .claude/hooks/close-completeness.mode to 'enforce' after shakedown)"
            local _cc48_ts
            _cc48_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf '{"ts":"%s","check":"%s","detail":"%s finding(s) across %s VERIFIED row(s)"}\n' \
              "$_cc48_ts" "close-completeness" "$_cc48_n" "$_cc48_m" >> "$WARN_LOG" 2>/dev/null || true
            ;;
        esac
        ;;
      *)
        log "  WARN:  close-completeness — unexpected verdict '$cc48_verdict'"
        ;;
    esac
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


  # Check 36 — Memory↔corpus tie-drift (warn-mode initial, #530). Standing
  # backstop for the memory↔corpus boundary contract (knowledge-architecture.md
  # §7 + ADR-029, superseded-by/generalized-into ADR-045). The PRIMARY eviction
  # executor is the Stage-13 Phase B-OPS operational-deploy step (gate G-CL5);
  # this check is the non-skippable audit that catches what a forgotten Phase
  # B-OPS manifest entry misses.
  #
  # CRITICAL: this check is READ-ONLY. A deploy validator must NEVER mutate the
  # operator memory store (Layer-2 mutation is an over-reach per ADR-029 + the
  # operations-bridge boundary). It enumerates and WARNS; it deletes nothing.
  # The RE-POINT (re-point/drop dangling wikilinks) and close-time absorption
  # reconciliation steps the §7 lifecycle defines are OPERATOR-AUTHORIZED Phase
  # B-OPS executor actions — this check only DETECTS their omission, never enacts
  # them (the new classes 4/5 below are detectors, not mutators).
  #
  # Five drift classes (knowledge-architecture.md §7 The five drift classes):
  #   deployed-but-not-evicted — a memory's #N tie is CLOSED, the corpus encoding
  #     is present, but the memory file still exists.
  #   dead-ref tie — a memory's #N tie no longer RESOLVES (re-versioning renumbered
  #     it). Detected by `gh issue view` RESOLUTION-FAILURE, NEVER by digit-match
  #     (issue-number magnitude is meaningless across a re-version; only a
  #     resolution probe is load-bearing — the issue-body-renumber-rot lesson).
  #   untied-encodeable — a memory matching encodeable signatures with no #N tie
  #     and no corpus pointer (heuristic; routed for operator triage, not action).
  #   dangling-wikilink-to-evicted-memory — a surviving memory body links a
  #     [[target]] whose memory file no longer exists (left dangling by an EVICT
  #     that did not RE-POINT). Local-only (pure filesystem resolution; no gh) —
  #     a routing signal for RE-POINT, never a FAIL in warn-mode (dangling links
  #     are permitted by convention, not an error).
  #   ledger-pointer-to-closed-issue — a ledger "Temporary enhancement pointer"
  #     row ties a #N that is CLOSED yet the memory was not absorbed/evicted (the
  #     partial-absorption residue: a closing issue absorbed a SUBSET of the
  #     memories naming it, stranding the rest). Resolution-probing (requires gh).
  #     Disambiguated from deployed-but-not-evicted by file-section: a ledger row
  #     under MEMORY.md → class 5; a standalone topic memory file → class 1.
  #
  # Degrades gracefully: SKIP when ~/.claude/memory/ is absent (fresh install / CI
  # — mirror the Check 8 SKIP idiom, never FAIL); the resolution-probing classes
  # SKIP when gh is unavailable/unauthenticated (mirror the Check 32 gh-guard).
  # The human-runnable companion is release/references/how-to/memory-corpus-drift-audit.md.
  # The fixture self-test is core/deploy/tests/test_check36_drift_classes.sh.
  # <!-- repo-integrity: allow-memory-ref -->  Check 36 legitimately names the ~/.claude/memory store it audits.
  # Cutover comment family-standard: applies to ./deploy.sh --check invocations
  # on/after the introducing release's merge SHA in RELEASE_LOG.md; that release
  # itself exempt — reflexive-pipeline-loop discipline.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 36: Memory↔corpus tie-drift (memory↔corpus boundary contract backstop) (#530)"
    local c36_mem_dir="${HOME}/.claude/memory"
    if [[ ! -d "$c36_mem_dir" ]]; then
      log "  SKIP:  ~/.claude/memory not present (fresh install / CI) — no memory store to audit"
    else
      local c36_gh_ok="false"
      if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        c36_gh_ok="true"
      else
        log "  N/A:   gh unavailable/unauthenticated — dead-ref + deployed-but-not-evicted classes skipped (untied-encodeable scan still runs)"
      fi
      local c36_findings=0
      local c36_file c36_n c36_state
      # Resolution-probing classes (require gh): dead-ref tie + deployed-but-not-evicted.
      if [[ "$c36_gh_ok" == "true" ]]; then
        while IFS= read -r c36_file; do
          [[ -n "$c36_file" ]] || continue
          # First #N tie per memory file (the eviction-pointer / issue tie).
          c36_n=$(/usr/bin/grep -oE '#[0-9]+' "$c36_file" 2>/dev/null | /usr/bin/head -1 | /usr/bin/tr -d '#') || c36_n=""
          [[ -n "$c36_n" ]] || continue
          # dead-ref tie: probe resolution; NEVER compare magnitude.
          if ! gh issue view "$c36_n" --json number >/dev/null 2>&1; then
            flag_warn_or_issue "memory-corpus-tie-drift" \
              "dead-ref tie: $(basename "$c36_file") cites #${c36_n} which does not resolve (resolution-failure; re-tie or evict per memory-corpus-drift-audit.md §4)"
            c36_findings=$((c36_findings + 1))
            continue
          fi
          # deployed-but-not-evicted: tie CLOSED + file still present. (The corpus-
          # presence leg is per-memory phrase-specific; the human-runnable how-to
          # carries the per-memory ENCODED_PHRASE grep. Here a CLOSED tie with the
          # file still present is the auditable backstop signal.)
          c36_state=$(gh issue view "$c36_n" --json state --jq .state 2>/dev/null) || c36_state=""
          if [[ "$c36_state" == "CLOSED" && -f "$c36_file" ]]; then
            flag_warn_or_issue "memory-corpus-tie-drift" \
              "deployed-but-not-evicted: $(basename "$c36_file") tie #${c36_n} is CLOSED but the memory file still exists (add to next release's Phase B-OPS manifest; verify corpus-presence per the how-to before evicting)"
            c36_findings=$((c36_findings + 1))
          fi
        done < <(/usr/bin/grep -rlE '#[0-9]+' "$c36_mem_dir" 2>/dev/null || true)
        # Class 5 — ledger-pointer-to-closed-issue (resolution-probing; the upstream
        # partial-absorption backstop for the §7 close-time reconciliation). Scans
        # ONLY the MEMORY.md ledger "Temporary enhancement pointers" section: each
        # row that ties a CLOSED issue but was never absorbed/evicted strands the
        # memory (a closing issue absorbed a SUBSET of the memories naming it).
        # Disambiguation from deployed-but-not-evicted is by FILE-SECTION: this
        # class is the MEMORY.md ledger-row scan; class 1 is the per-topic-file
        # scan above. Predicate is mirrored verbatim in
        # core/deploy/tests/test_check36_drift_classes.sh (drift-guarded there).
        local c36_index="${c36_mem_dir}/MEMORY.md"
        if [[ -f "$c36_index" ]]; then
          # Extract the "Temporary enhancement pointers" section body (header line
          # to the next top-level "## " heading), then probe each row's issue ties.
          local c36_ledger c36_row c36_ln
          c36_ledger=$(/usr/bin/awk '
              /^## Temporary enhancement pointers/ { inblk=1; next }
              /^## / { inblk=0 }
              inblk && /^- / { print }
            ' "$c36_index" 2>/dev/null || true)
          while IFS= read -r c36_row; do
            [[ -n "$c36_row" ]] || continue
            # Each ledger row may cite several #N; flag the row on the FIRST CLOSED
            # tie (one finding per stranded row, not per tie).
            for c36_ln in $(printf '%s\n' "$c36_row" | /usr/bin/grep -oE '#[0-9]+' | /usr/bin/tr -d '#' | /usr/bin/sort -u); do
              [[ -n "$c36_ln" ]] || continue
              # Resolution probe first (a non-resolving tie is dead-ref's job, not this class's).
              gh issue view "$c36_ln" --json number >/dev/null 2>&1 || continue
              c36_state=$(gh issue view "$c36_ln" --json state --jq .state 2>/dev/null) || c36_state=""
              if [[ "$c36_state" == "CLOSED" ]]; then
                flag_warn_or_issue "memory-corpus-tie-drift" \
                  "ledger-pointer-to-closed-issue: MEMORY.md ledger row \"$(printf '%s' "$c36_row" | /usr/bin/sed -E 's/^- \[([^]]*)\].*/\1/' | /usr/bin/cut -c1-48)\" ties #${c36_ln} which is CLOSED but the memory was not absorbed/evicted (re-home to a live issue per knowledge-architecture.md §7 / stage-13 Phase B-OPS5)"
                c36_findings=$((c36_findings + 1))
                break
              fi
            done
          done < <(printf '%s\n' "$c36_ledger")
        fi
      fi
      # untied-encodeable (local-only heuristic; routes for operator triage): a
      # memory matching encodeable signatures with NO #N tie and NO corpus pointer.
      while IFS= read -r c36_file; do
        [[ -n "$c36_file" ]] || continue
        if /usr/bin/grep -qiE 'discipline|reference|methodology|gate|protocol|standard' "$c36_file" 2>/dev/null; then
          flag_warn_or_issue "memory-corpus-tie-drift" \
            "untied-encodeable (candidate): $(basename "$c36_file") matches encodeable signatures with no #N tie and no corpus pointer (file an encode issue per memory-corpus-drift-audit.md §4)"
          c36_findings=$((c36_findings + 1))
        fi
      done < <(/usr/bin/grep -rLE '#[0-9]+|core/|release/|CLAUDE\.md' "$c36_mem_dir" 2>/dev/null || true)
      # Class 4 — dangling-wikilink-to-evicted-memory (local-only; the downstream
      # backstop for the §7 RE-POINT step). For each [[target]] wikilink in any
      # memory file, the target resolves to ${c36_mem_dir}/<target>.md; if that
      # file is ABSENT the link dangles (an EVICT that did not RE-POINT). Pure
      # filesystem resolution — no gh — so it runs in the gh-unavailable branch
      # too. Warn-only: dangling links are permitted by convention (not a FAIL),
      # this is a routing signal for RE-POINT. A [[topic]] in a MEMORY.md index
      # row resolves to topic.md the same way (its own entry is a file, so the
      # row is not self-dangling). Predicate mirrored verbatim in the fixture
      # self-test (drift-guarded there).
      local c36_wl c36_target
      while IFS= read -r c36_file; do
        [[ -n "$c36_file" ]] || continue
        while IFS= read -r c36_wl; do
          [[ -n "$c36_wl" ]] || continue
          c36_target=$(printf '%s' "$c36_wl" | /usr/bin/sed -E 's/^\[\[(.+)\]\]$/\1/')
          [[ -n "$c36_target" ]] || continue
          # Resolve [[target]] -> <target>.md under the store. Absent file = dangling.
          if [[ ! -f "${c36_mem_dir}/${c36_target}.md" ]]; then
            flag_warn_or_issue "memory-corpus-tie-drift" \
              "dangling-wikilink-to-evicted-memory: $(basename "$c36_file") links [[${c36_target}]] which no longer exists (re-point to its corpus home or drop per knowledge-architecture.md §7 RE-POINT)"
            c36_findings=$((c36_findings + 1))
          fi
        done < <(/usr/bin/grep -oE '\[\[[a-z0-9_]+\]\]' "$c36_file" 2>/dev/null | /usr/bin/sort -u || true)
      done < <(/usr/bin/grep -rlE '\[\[[a-z0-9_]+\]\]' "$c36_mem_dir" 2>/dev/null || true)
      if [[ "$c36_findings" -eq 0 ]]; then
        log "  OK:    memory store in contract — no tie-drift detected"
      else
        log "  ${c36_findings} memory↔corpus tie-drift signal(s) emitted (mode=${DEPLOY_CHECK_MODE}; deletes nothing — see knowledge-architecture.md §7)"
      fi
    fi
  fi

  # Check 37 — Hook-registry completeness (advisory; warn-mode initial; required at flip-to-enforce)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (b)):
  #   posture: advisory   enforcement-surface: deploy-check.mode warn-window
  #            (becomes required when the operator flips deploy-check.mode to enforce)
  #   invariant: every core/hooks/block-*.sh maps to its CORRECT owning doc, and
  #              every bypass-mode per-hook source maps back to a script AND a row
  #              in the generated index — a bijection scoped by ownership, NOT a
  #              forced single-file bijection (per ADR-030 + the Stage-6 ownership
  #              caveat: block-skill-direct-edit and block-fragile-refs are owned
  #              by their own discipline docs, not the bypass-mode registry).
  #   falsification: add a new core/hooks/block-foo.sh with no owner entry -> Check
  #                  37 WARNs (advisory) / FAILS (post-flip). Delete a per-hook
  #                  source whose script still exists -> Check 37 WARNs / FAILS.
  #
  # This is the drift-resistance teeth ADR-030 adds: it makes the live 5/7/9
  # registry drift (doc said "7 hooks"; subagent-security-posture said "5"; the
  # machine registry had all 9; no check reconciled them) structurally
  # impossible. It asserts CONTENT (the on-disk script set vs the on-disk source
  # set vs the generated-index rows), not a proxy.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 37: Hook-registry completeness (ownership bijection)"
    local c37_index="core/rules/bypass-mode-readiness.md"
    local c37_src_dir="core/rules/bypass-mode-readiness"
    # Ownership manifest: each core/hooks/block-*.sh -> its owning doc. The 8
    # bypass-mode security hooks are owned by the bypass-mode registry (their
    # per-hook source lives under $c37_src_dir + a row in $c37_index); the other
    # 2 are owned by their own discipline docs and are intentionally NOT in this
    # registry. Edit this manifest (and add the per-hook source) when a new
    # bypass-mode hook ships.
    local -a C37_BYPASS_HOOKS=(
      block-autonomy-ceiling
      block-credential-reads
      block-destructive
      block-egress
      block-fs-boundary
      block-mcp-writes
      block-rm-prefer-trash
      block-shell-injection
    )
    # Non-bypass-mode hooks: hook-basename:owning-doc (owner must exist on disk).
    local -a C37_OTHER_OWNERS=(
      "block-skill-direct-edit:core/standards/canonical-skill-structure.md"
      "block-fragile-refs:core/standards/reference-durability-standard.md"
      "block-gh-path-leak:core/rules/git-workflow.md"
      "block-draft-files:core/rules/git-workflow.md"
    )
    if [[ ! -d core/hooks ]] || [[ ! -f "$c37_index" ]] || [[ ! -d "$c37_src_dir" ]]; then
      log "  SKIP:  hook scripts dir, index, or source dir absent (greenfield/partial checkout)"
    else
      local c37_violations=0
      # Build the bypass-mode lookup set + the other-owner lookup set as strings.
      local c37_bypass_set=" ${C37_BYPASS_HOOKS[*]} "
      local c37_other_set=""
      local _pair
      for _pair in "${C37_OTHER_OWNERS[@]}"; do
        c37_other_set+=" ${_pair%%:*} "
      done
      # (a) Every script on disk has an owner (bypass-mode OR an other-owner doc).
      local c37_script
      for c37_script in core/hooks/block-*.sh; do
        [[ -e "$c37_script" ]] || continue
        local c37_base; c37_base="$(basename "$c37_script" .sh)"
        if [[ "$c37_bypass_set" == *" $c37_base "* ]]; then
          # Bypass-mode hook: must have a per-hook source AND an index row.
          if [[ ! -f "$c37_src_dir/$c37_base.md" ]]; then
            flag_warn_or_issue "hook-registry-completeness" "bypass-mode hook $c37_base has no per-hook source at $c37_src_dir/$c37_base.md"
            c37_violations=$((c37_violations + 1))
          # The generated "## The Hooks" table emits one anchor-linked row per
          # per-hook source: `[\`block-<hook>.sh\` (…)](#…)`. Assert that row exists.
          elif ! grep -qE "\[\`?$c37_base\.sh\`? .*\]\(#" "$c37_index" 2>/dev/null; then
            flag_warn_or_issue "hook-registry-completeness" "bypass-mode hook $c37_base has a source but no row in the generated index $c37_index (regenerate via build-hook-registry.py)"
            c37_violations=$((c37_violations + 1))
          fi
        elif [[ "$c37_other_set" == *" $c37_base "* ]]; then
          # Non-bypass-mode hook: its owning doc must exist on disk.
          local c37_owner=""
          for _pair in "${C37_OTHER_OWNERS[@]}"; do
            [[ "${_pair%%:*}" == "$c37_base" ]] && c37_owner="${_pair##*:}"
          done
          if [[ -n "$c37_owner" ]] && [[ ! -f "$c37_owner" ]]; then
            flag_warn_or_issue "hook-registry-completeness" "$c37_base owned by $c37_owner, but that owner doc is missing"
            c37_violations=$((c37_violations + 1))
          fi
        else
          # Script with NO owner manifest entry at all — the 5/7/9 failure mode.
          flag_warn_or_issue "hook-registry-completeness" "$c37_base has no owner: add it to C37_BYPASS_HOOKS (+ a per-hook source) or C37_OTHER_OWNERS in deploy.sh Check 37"
          c37_violations=$((c37_violations + 1))
        fi
      done
      # (b) Reverse: every bypass-mode per-hook source maps back to a script.
      local c37_src
      for c37_src in "$c37_src_dir"/block-*.md; do
        [[ -e "$c37_src" ]] || continue
        local c37_sbase; c37_sbase="$(basename "$c37_src" .md)"
        if [[ "$c37_bypass_set" != *" $c37_sbase "* ]]; then
          flag_warn_or_issue "hook-registry-completeness" "per-hook source $c37_src is not a registered bypass-mode hook (add $c37_sbase to C37_BYPASS_HOOKS, or remove the source)"
          c37_violations=$((c37_violations + 1))
        elif [[ ! -f "core/hooks/$c37_sbase.sh" ]]; then
          flag_warn_or_issue "hook-registry-completeness" "per-hook source $c37_src has no backing script core/hooks/$c37_sbase.sh"
          c37_violations=$((c37_violations + 1))
        fi
      done
      if [[ $c37_violations -eq 0 ]]; then
        log "  OK:    ${#C37_BYPASS_HOOKS[@]} bypass-mode hooks ⇄ sources ⇄ index rows; ${#C37_OTHER_OWNERS[@]} other hooks own-doc resolved"
      fi
    fi
  fi

  # Check 38 — Hook-registry index freshness (required; always-enforce; enforcement-surface: deploy-time)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (a)+(b)):
  #   posture: required   enforcement-surface: always-enforce (deploy-time)
  #   invariant: the committed core/rules/bypass-mode-readiness.md is byte-identical
  #              to what build-hook-registry.py regenerates from its per-hook +
  #              cross-cutting sources (the regenerate-and-diff "verify-ci"
  #              pattern). A stale committed generated artifact must never ship.
  #   falsification: edit a per-hook source (e.g. add a rule row) without
  #                  regenerating -> Check 38 FAILS (committed index drifts from
  #                  sources). Regenerate + commit -> Check 38 GREEN.
  #
  # Always-enforce because the generator is deterministic — a non-empty
  # regenerate-and-diff is unambiguous drift, not a calibration signal. This is
  # the freshness half of ADR-030's drift-resistance (Check 37 is the
  # completeness half). Fails LOUD if the generator can't run (missing python3 /
  # missing generator), never silently passing a potentially-stale index.
  log "Check 38: Hook-registry index freshness (regenerate-and-diff)"
  local c38_gen="core/deploy/tools/build-hook-registry.py"
  if [[ ! -f "$c38_gen" ]]; then
    log "  FAIL:  Check 38 generator missing: $c38_gen"
    ISSUES=$((ISSUES + 1))
  elif [[ ! -x "/usr/bin/python3" ]]; then
    log "  FAIL:  Check 38 — /usr/bin/python3 not executable; cannot verify index freshness"
    ISSUES=$((ISSUES + 1))
  else
    local c38_out c38_rc=0
    c38_out=$(/usr/bin/python3 "$c38_gen" --check 2>&1) || c38_rc=$?
    if [[ $c38_rc -eq 0 ]]; then
      log "  OK:    core/rules/bypass-mode-readiness.md is in sync with its sources"
    elif [[ $c38_rc -eq 1 ]]; then
      log "  FAIL:  core/rules/bypass-mode-readiness.md is STALE vs its sources — regenerate via 'python3 $c38_gen' and commit"
      echo "$c38_out" | head -20 | sed 's/^/         /' || true
      ISSUES=$((ISSUES + 1))
    else
      # exit 3 (source-resolution failure) or any other non-zero — fail loud.
      log "  FAIL:  Check 38 generator exited $c38_rc (source-resolution failure or error)"
      echo "$c38_out" | head -10 | sed 's/^/         /' || true
      ISSUES=$((ISSUES + 1))
    fi
  fi

  # Check 39 — Platform .version drift vs latest published Release (advisory; warn-mode initial; #1643)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (a)+(b)):
  #   posture: advisory   enforcement-surface: deploy-check.mode warn-window
  #            (becomes required when the operator flips deploy-check.mode to enforce)
  #   invariant: the repo-root .version (the platform's version source-of-truth, read
  #              by the SessionStart version-skew hook core/hooks/notify-version-skew.sh)
  #              equals the tag_name of the latest PUBLISHED GitHub Release — the SAME
  #              value the hook compares against — so the "update available" banner is
  #              accurate and clears after update.sh.
  #   falsification: set .version to a value >=2 published-minors behind latest
  #                  (e.g. v2.08 while latest published is v2.11) -> Check 39 FAILS
  #                  (warn-mode: WARN + jsonl). Set .version == latest published -> GREEN.
  #
  # ANCHOR CHOICE (Stage-5 Evidence-Grounding, #1661): anchor on the latest PUBLISHED
  # Release (gh api repos/<o>/<r>/releases/latest --jq .tag_name — the hook's exact
  # query), NOT git-describe/semver-max. Rationale: the hook compares .version to the
  # published Release; for this check to assert the invariant the bug actually binds
  # ("banner clears"), it MUST anchor on the same value the hook does. git describe
  # tracks tags (incl. tagged-but-unpublished tags ahead of the published Release) and
  # `git tag --sort=-version:refname | head -1` returns an orphan v3.x lineage — both
  # would red-CI legitimate v2.x releases. A git-describe sub-signal is used ONLY to
  # classify the legitimate Stage-12->13 tagged-not-yet-published WARN window.
  #
  # Offline/unauth: N/A (never FAIL), mirroring Check 32's gh-guard (absent vs unreachable).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 39: Platform .version drift vs latest published GitHub Release (#1643)"
    local c39_version_file="$_audit_src_root/.version"
    if [[ -z "$_audit_src_root" || ! -f "$c39_version_file" ]]; then
      log "  N/A:   .version not present at repo root — nothing to anchor (re-pathing or non-repo context)"
    elif ! command -v gh >/dev/null 2>&1; then
      log "  N/A:   Check 39 published-release anchor unavailable (gh not on PATH) — reuses Check 32 offline SKIP semantics"
    elif ! gh auth status >/dev/null 2>&1; then
      log "  N/A:   Check 39 published-release anchor unavailable (gh unauthenticated/offline) — reuses Check 32 offline SKIP semantics"
    elif [[ -z "$AUDIT_REPO" ]]; then
      log "  N/A:   Check 39 cannot resolve owner/repo (AUDIT_REPO empty) — published-release anchor unavailable"
    else
      local c39_local c39_anchor c39_nearest
      c39_local="$(/usr/bin/head -1 "$c39_version_file" 2>/dev/null | tr -d '[:space:]')"
      # Anchor (network) — the hook's exact contract: latest PUBLISHED Release tag.
      c39_anchor="$(gh api "repos/${AUDIT_REPO}/releases/latest" --jq '.tag_name' 2>/dev/null | tr -d '[:space:]')"
      # WARN-window sub-signal (offline) — nearest mainline tag, orphan-excluded defensively.
      c39_nearest="$(git -C "$_audit_src_root" describe --tags --abbrev=0 --exclude='v3.*' 2>/dev/null | tr -d '[:space:]' || true)"

      if [[ -z "$c39_anchor" ]]; then
        log "  N/A:   no published GitHub Release found for $AUDIT_REPO (releases/latest empty) — anchor unavailable"
      elif [[ -z "$c39_local" ]]; then
        flag_warn_or_issue "version-stamp-skew" ".version at repo root is empty/unreadable — cannot compare to latest published Release $c39_anchor"
      else
        # Parse vMAJOR.MINOR from local + anchor (tolerate letter/-N qualifiers: vX.Y[...]).
        local c39_l_maj c39_l_min c39_a_maj c39_a_min
        c39_l_maj="$(/usr/bin/printf '%s' "$c39_local"  | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\1/p')"
        c39_l_min="$(/usr/bin/printf '%s' "$c39_local"  | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\2/p')"
        c39_a_maj="$(/usr/bin/printf '%s' "$c39_anchor" | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\1/p')"
        c39_a_min="$(/usr/bin/printf '%s' "$c39_anchor" | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\2/p')"

        if [[ -z "$c39_l_maj" || -z "$c39_a_maj" ]]; then
          flag_warn_or_issue "version-stamp-skew" ".version ('$c39_local') or latest-Release ('$c39_anchor') is not a parseable vMAJOR.MINOR — cannot assert version-stamp invariant"
        elif [[ "$c39_local" == "$c39_anchor" ]]; then
          log "  OK:    .version ($c39_local) == latest published Release ($c39_anchor) — version-skew banner clears"
        elif [[ "$c39_l_maj" != "$c39_a_maj" ]]; then
          # Different major-lineage — always FAIL (e.g. .version=v3.x vs published v2.x).
          flag_warn_or_issue "version-stamp-skew" ".version ($c39_local) is a different major-lineage than the latest published Release ($c39_anchor) — wrong version source-of-truth; bump at release cut per stage-13-close.md Phase B5.7"
        else
          # Same lineage — compute signed minor distance. Force base-10 (10#…) so a
          # zero-padded minor like 08/09 is not mis-parsed as invalid octal.
          local c39_dist=$(( 10#$c39_l_min - 10#$c39_a_min ))
          local c39_abs=${c39_dist#-}
          if [[ "$c39_abs" -le 1 ]]; then
            # Legitimate Stage-12->13 window: exactly one published-minor apart. The
            # nearest-tag sub-signal disambiguates the tag-ahead/not-yet-published case.
            flag_warn_or_issue "version-stamp-skew" ".version ($c39_local) is 1 published-minor from latest published Release ($c39_anchor); nearest mainline tag=${c39_nearest:-unknown} — legitimate Stage-12->13 window OR a pending bump; stamp .version at Stage 13 close per stage-13-close.md Phase B5.7"
          else
            # >=2 minors behind/ahead — the bug state. FAIL.
            flag_warn_or_issue "version-stamp-skew" ".version ($c39_local) is $c39_abs published-minors from the latest published Release ($c39_anchor) — the version source-of-truth is stale; the version-skew banner will not clear. Bump .version at release cut (stage-13-close.md Phase B5.7 / automated-closeout.sh phase_bump_version)"
          fi
        fi
      fi
    fi
  fi

  # Check 40 — Touchpoint-inventory instance structural validation (warn-mode initial)
  #
  # Validates an operator-local touchpoint-inventory + phase-out-plan instance
  # against the schema at core/schemas/touchpoint-phaseout-schema.md (the
  # 71-autonomy-phaseout-foundation deliverable, #165). Structural only —
  # field/section presence + enum shape, NOT the content of the operator's
  # phase-out judgment (advancement stays an operator decision per the
  # progressive-rollout convention).
  #
  # SKIP-WHEN-ABSENT: the instance is operator-local and git-ignored (the
  # *.governance/roadmaps/ + personal/ seam per ADR-012), so it does
  # NOT exist in a fresh clone or in CI. Mirroring Check 13's "deploy never run
  # → skip, don't double-fail" posture, this check SKIPs cleanly when no
  # instance file is present; absence is not drift.
  #
  # Warn-mode initial: routed through flag_warn_or_issue / deploy-check.mode
  # (the Checks 8-10 / 14 / 15 / 18-23 precedent) so it dogfoods the shadow/warn
  # phase of the very convention this release ships. Flip deploy-check.mode to
  # 'enforce' after the shakedown window.
  log "Check 40: Touchpoint-inventory instance structural validation"
  if [[ "$DEPLOY_CHECK_MODE" == "off" ]]; then
    log "  SKIP:  deploy-check.mode = off"
  else
    # Resolve the operator-local instance. Primary: the operator-instance base
    # (env-var-aware, same resolution as the warn-log / mode file above); a
    # roadmaps-tree fallback is also accepted. Filename is stable per the schema.
    local c40_base="$(pmo_instance_path)"
    local c40_file=""
    local c40_candidate
    for c40_candidate in \
      "$c40_base/touchpoint-inventory.md" \
      "$c40_base/governance/roadmaps/touchpoint-inventory.md" \
      "$c40_base/roadmaps/touchpoint-inventory.md"; do
      if [[ -f "$c40_candidate" ]]; then c40_file="$c40_candidate"; break; fi
    done

    if [[ -z "$c40_file" ]]; then
      # Operator-local instance absent (fresh clone / CI / un-populated) — skip
      # cleanly. Schema presence is verified separately (the file is in-repo).
      log "  SKIP:  no operator-local touchpoint-inventory instance present (operator-local / git-ignored — not drift)"
    elif [[ ! -f "core/schemas/touchpoint-phaseout-schema.md" ]]; then
      # Instance present but schema missing — that IS a real structural fault.
      flag_warn_or_issue "touchpoint-schema" \
        "instance present ($c40_file) but schema core/schemas/touchpoint-phaseout-schema.md is missing"
    else
      # Structural validation: required field tokens + enum shape. Greps are
      # tolerant (|| true) so a legitimate no-match cannot abort the run.
      local c40_problems=0

      # P1/P5: required field tokens present somewhere in the instance.
      local c40_tok
      for c40_tok in touchpoint_id stage current_phase reversibility_tier autonomy_tier \
                     irreducible_human automation_candidate success_criteria slo risks rollback_path; do
        if ! grep -q "$c40_tok" "$c40_file" 2>/dev/null; then
          flag_warn_or_issue "touchpoint-schema" "required field '$c40_tok' not found in instance ($c40_file)"
          c40_problems=$((c40_problems + 1))
        fi
      done

      # P2: any current_phase / target_phase value must be in the #164 enum.
      # Flag a line that assigns a phase value outside {shadow,warn,enforce,removed}.
      local c40_badphase
      c40_badphase=$(grep -inE '(current_phase|target_phase)[^A-Za-z0-9]+(dark|canary|ga|retired|sunset|live|active|on)\b' "$c40_file" 2>/dev/null | head -3 || true)
      if [[ -n "$c40_badphase" ]]; then
        flag_warn_or_issue "touchpoint-schema" "current_phase/target_phase value outside the {shadow,warn,enforce,removed} enum in $c40_file"
        c40_problems=$((c40_problems + 1))
      fi

      # P6 (FMEA shape): if risks are present, the FMEA sub-fields should appear.
      local c40_fmea_tok
      for c40_fmea_tok in severity likelihood detectability; do
        if grep -qi 'risks' "$c40_file" 2>/dev/null && ! grep -qi "$c40_fmea_tok" "$c40_file" 2>/dev/null; then
          flag_warn_or_issue "touchpoint-schema" "FMEA sub-field '$c40_fmea_tok' not found despite risks present ($c40_file)"
          c40_problems=$((c40_problems + 1))
        fi
      done

      if [[ $c40_problems -eq 0 ]]; then
        log "  OK:    touchpoint-inventory instance structurally valid ($c40_file)"
      fi
    fi
  fi

  # Check 41 — Pre-merge version-freeness (advisory; warn-mode initial; #1677)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (a)+(b)):
  #   posture: advisory   enforcement-surface: version-freeness.mode warn-window
  #            (becomes required when the operator flips version-freeness.mode -> enforce;
  #             the Stage-12 CI gate version-freeness.yml is the merge-blocking surface)
  #   invariant: the claim-time candidate version (computed from the release plan's
  #              bump-class) is NOT already present in the claimed_set (published
  #              Release tags U signed origin tags U in-flight DEPLOYED-not-VERIFIED
  #              RELEASE_LOG rows) — i.e. the version the merge will claim is still
  #              free, asserted BEFORE merge so a collision never lands with stale
  #              labels (pre-empts the Stage-12 Phase B3 reactive tag-push rejection).
  #   falsification: set PMO_VERSION_FREENESS_CANDIDATE to a published Release tag
  #                  (e.g. candidate v2.15 while v2.15 is published) -> Check 41 FAILS
  #                  (enforce) / WARNs (warn-mode). A free candidate -> GREEN.
  #
  # ANCHOR CHOICE (Stage-5 Evidence-Grounding, #1677): the claimed_set's published-
  # Release members are read from gh api repos/<o>/<r>/releases (the SAME anchor
  # Check 39 + the #1673 allocation rule use), NOT git-describe (returns the merge
  # base on a feature branch) and NOT `git tag --sort=-version:refname` (returns the
  # orphan v3.x lineage). Grammar/comparison is the SSOT version-grammar.sh (#1676)
  # comparator — this check adds NO version parser of its own (avoids the FM-1
  # 4th-parser drift). The candidate is derived by claim-version.sh (#1675/#1673
  # allocator) run as a subprocess, never re-implemented inline (CD-3).
  #
  # FAIL-CLOSED at the merge gate (DD4 / FM-3): a non-canonical existing tag, an
  # unreachable anchor at the CI merge-gate, or a malformed candidate => UNDECIDABLE
  # -> the gate BLOCKS. The lifecycle --check surface (this check) degrades a merely-
  # offline anchor to N/A (never-FAIL), mirroring Check 39/32 (no merge is imminent
  # here). The verdict is computed by the shared _vf_compute_verdict body (DD1) so
  # the CI probe (--check-version-freeness) and this lifecycle check cannot diverge.
  #
  # Candidate-derivation INPUT (slug-primary, founding ADR #1697): absent a resolvable
  # release-claim context (no PMO_VERSION_FREENESS_* and no plan), SKIP cleanly
  # (absence is not drift) — same posture as Check 40's operator-local SKIP.
  local VERSION_FREENESS_MODE; VERSION_FREENESS_MODE="$(resolve_check_mode "version-freeness")"
  if [[ "$VERSION_FREENESS_MODE" != "off" ]]; then
    log "Check 41: Pre-merge version-freeness (claim-time candidate vs claimed_set) (#1677)"
    local c41_verdict c41_tok c41_cand c41_detail
    c41_verdict="$(_vf_compute_verdict "lifecycle")"
    c41_tok="${c41_verdict%% *}"
    case "$c41_tok" in
      SKIP)
        log "  SKIP:  ${c41_verdict#SKIP }"
        ;;
      NA)
        # Offline anchor on the lifecycle surface — never-FAIL (Check 39/32 posture).
        log "  N/A:   ${c41_verdict#NA }"
        ;;
      FREE)
        c41_cand="${c41_verdict#FREE }"
        log "  OK:    candidate $c41_cand is free (not in claimed_set)"
        ;;
      NOT_FREE)
        # "NOT_FREE <candidate> <colliding-tag>"
        c41_detail="${c41_verdict#NOT_FREE }"
        # version-freeness.mode is its OWN per-check mode file (resolve_check_mode),
        # decoupled from the shared cohort; but flag_warn_or_issue switches on the
        # shared $DEPLOY_CHECK_MODE. Honor the per-check resolution: only FAIL (++ISSUES)
        # when THIS check's resolved mode is enforce; otherwise WARN regardless of the
        # shared mode, so version-freeness graduates independently.
        if [[ "$VERSION_FREENESS_MODE" == "enforce" ]]; then
          flag_warn_or_issue "version-freeness" \
            "candidate $c41_detail already claimed — re-version BEFORE merge; a Stage-12 Phase B3 tag push would be rejected after the merge lands with stale labels"
          [[ "$DEPLOY_CHECK_MODE" == "enforce" ]] || { ISSUES=$((ISSUES + 1)); log "  FAIL:  version-freeness — candidate $c41_detail already claimed (per-check enforce)"; }
        else
          flag_warn_or_issue "version-freeness" \
            "candidate $c41_detail already claimed — re-version BEFORE merge; a Stage-12 Phase B3 tag push would be rejected after the merge lands with stale labels"
        fi
        ;;
      UNDECIDABLE)
        # "UNDECIDABLE <candidate> <reason>" — fail-closed semantics bind the merge
        # gate (the probe); on the lifecycle surface this is reported (WARN/enforce
        # per the per-check mode) so the operator sees the untaggable state early.
        c41_detail="${c41_verdict#UNDECIDABLE }"
        if [[ "$VERSION_FREENESS_MODE" == "enforce" ]]; then
          flag_warn_or_issue "version-freeness" \
            "freeness undecidable ($c41_detail) — fail-closed; operator must resolve the untaggable state before merge"
          [[ "$DEPLOY_CHECK_MODE" == "enforce" ]] || { ISSUES=$((ISSUES + 1)); log "  FAIL:  version-freeness — undecidable ($c41_detail) (per-check enforce)"; }
        else
          flag_warn_or_issue "version-freeness" \
            "freeness undecidable ($c41_detail) — fail-closed at the merge gate; operator must resolve the untaggable state before merge"
        fi
        ;;
      *)
        flag_warn_or_issue "version-freeness" "unexpected verdict: $c41_verdict"
        ;;
    esac
  fi

  # Check 42 — Host-binding leak detector (warn-mode initial)
  #
  # Flags a host tool (gh / git / a host API) prescribed as THE canonical
  # mechanism in K1-tier governance, where the operation belongs behind the
  # operator.toml [adapters] seam — the HOST-BINDING-LEAK leakage class registered
  # in core/disciplines/knowledge-architecture.md §4.1 (the host-axis sibling of
  # the path-portability class). Signal-not-verdict: the primitive emits candidate
  # lines (a prescriptive-mechanism marker + a host token in proximity, outside
  # fenced code blocks); the prescription-vs-teaching adjudication (§4.1 exclusions:
  # a reference adapter documenting its binding; an illustrative host command) is
  # the review act. Discipline-defining files that legitimately quote the pattern
  # are allowlisted (tracked: core/deploy/allowlists/skip-host-binding-check.txt).
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (Checks 8/9/10/14/25
  # precedent); the introducing release is itself exempt (reflexive-pipeline-loop —
  # a rule cannot fire on its own deploy). Flip-to-enforce after a ≥3-day warn-log
  # review via .claude/hooks/deploy-check.mode (shared cohort) or a dedicated
  # host-binding-leak.mode file (resolve_check_mode, independent graduation).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 42: Host-binding leak detector (K1-tier gh/git-as-prescribed-mechanism)"
    local c42_script="core/deploy/tools/check-host-binding.py"
    local c42_allowlist="core/deploy/allowlists/skip-host-binding-check.txt"
    if [[ ! -f "$c42_script" ]]; then
      flag_warn_or_issue "host-binding-leak" "primitive script missing: $c42_script"
    else
      local c42_targets="core/governance/**/*.md,release/governance/**/*.md,core/disciplines/**/*.md,core/standards/**/*.md,core/specs/**/*.md,core/schemas/**/*.md,release/references/**/*.md,core/rules/**/*.md,core/skills/**/SKILL.md,operations/skills/**/SKILL.md,release/skills/**/SKILL.md,core/skills/**/references/*.md,operations/skills/**/references/*.md,release/skills/**/references/*.md"
      local c42_output c42_exit=0
      c42_output=$(/usr/bin/python3 "$c42_script" --target-paths "$c42_targets" --allowlist "$c42_allowlist" 2>&1) || c42_exit=$?
      if [[ $c42_exit -eq 3 ]]; then
        flag_warn_or_issue "host-binding-leak" "path-resolution failure (exit 3): $(echo "$c42_output" | head -1) — a --target-paths glob resolved to zero files (relocated/typo'd scan surface); fix the glob list in this check"
      elif [[ $c42_exit -eq 0 ]]; then
        local c42_n
        c42_n=$(echo "$c42_output" | head -1 | awk '{print $2}')
        if [[ "${c42_n:-0}" -gt 0 ]]; then
          flag_warn_or_issue "host-binding-leak" "$c42_n candidate host-binding leak(s) — gh/git prescribed as the canonical mechanism in K1 governance; lift to the [adapters] seam per core/disciplines/knowledge-architecture.md §4.1, or allowlist a legitimate reference-adapter/teaching file"
          echo "$c42_output" | tail -n +2 | head -10 | sed 's/^/         /' || true
        else
          log "  OK:    no host-binding leak candidates in K1-tier governance"
        fi
      else
        flag_warn_or_issue "host-binding-leak" "detector errored (exit $c42_exit): $(echo "$c42_output" | head -1)"
      fi
    fi
  fi

  # Check 43 — Path-portability leak detector (warn-mode initial) [#529]
  #
  # Flags machine-specific path leaks on the EXECUTABLE surface (scripts / hooks /
  # deploy-tools — where path resolution is operationally load-bearing): an absolute
  # machine path (/Users/<u>, /home/<u>) or a BARE relative operator-instance path
  # (personal/pmo-instance/...). The path-portability leakage family — the path-axis
  # sibling of the host-binding-leak class (core/disciplines/knowledge-architecture.md
  # §4.1). The raw $HOME/Claude root is NOT flagged: it is the portable canonical
  # default. Patterns + the exempt predicate are SHARED with the #1137 gh-issue-ops
  # guard via core/deploy/tools/path-leak-patterns.sh.
  #
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown; flip-to-enforce after a
  # >=3-day warn-log review via .claude/hooks/deploy-check.mode (shared cohort) or a
  # dedicated path-portability.mode (resolve_check_mode, independent graduation).
  # Detection-definition files are allowlisted (tracked:
  # core/deploy/allowlists/skip-path-portability-check.txt).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 43: Path-portability leak detector (executable surface)"
    local c43_primitive="core/deploy/tools/path-leak-patterns.sh"
    local c43_allowlist="core/deploy/allowlists/skip-path-portability-check.txt"
    if [[ ! -f "$c43_primitive" ]]; then
      flag_warn_or_issue "path-portability" "primitive missing: $c43_primitive"
    else
      # shellcheck source=/dev/null
      source "$c43_primitive"
      local c43_n=0 c43_findings="" c43_f c43_ln c43_line
      for c43_f in core/deploy/deploy.sh core/deploy/tools/*.sh core/deploy/tools/*.py core/hooks/*.sh docs/scripts/*.sh install.sh update.sh; do
        [[ -f "$c43_f" ]] || continue
        grep -qxF "$c43_f" "$c43_allowlist" 2>/dev/null && continue
        c43_ln=0
        while IFS= read -r c43_line || [[ -n "$c43_line" ]]; do
          c43_ln=$((c43_ln+1))
          if path_leak_scan_line "$c43_line"; then
            c43_findings+="$c43_f:$c43_ln: $(printf '%s' "$c43_line" | sed 's/^[[:space:]]*//' | cut -c1-100)"$'\n'
            c43_n=$((c43_n+1))
          fi
        done < "$c43_f"
      done
      if [[ "$c43_n" -gt 0 ]]; then
        flag_warn_or_issue "path-portability" "$c43_n path-portability leak(s) on the executable surface — an absolute machine path (/Users//home) or a bare personal/pmo-instance path; use \${CLAUDE_WORKSPACE_ROOT:-\$HOME/Claude}/... , mark the line 'path-leak: allow', or allowlist the file"
        printf '%s' "$c43_findings" | head -10 | sed 's/^/         /'
      else
        log "  OK:    no path-portability leaks on the executable surface"
      fi
    fi
  fi


  # Check 44 — Depersonalization-token conformance (warn-mode initial) [#323]
  #
  # Two single-responsibility assertions over the Layer-1 corpus markdown:
  #  (a) PVT*-reintroduction ratchet — flag a literal GitHub Projects ID
  #      (PVT_ / PVTI_ / PVTF_ / PVTSSF_ + >=4 ID chars) reintroduced outside the
  #      guide. Part-a (the cleanup) shipped via #600; this is the forward ratchet.
  #      The {4,} floor exempts the guide's bare PVT_ example shapes; the guide file
  #      is additionally exempt.
  #  (b) bracket-token conformance — flag any [OPERATOR_*] square-bracket token used
  #      in tracked corpus that is NOT registered in depersonalization-spec.md
  #      §1/§1.1. Reads the registry (self-updating). Excludes release/releases/
  #      (release-corpus / ledger surface). A legitimately-illustrative token carries
  #      a 'depersonalization-token: allow' line marker.
  # Companion to #324 (token registration); kept SEPARATE from #529's path-portability
  # check (distinct concern). Warn-mode initial per bypass-mode-readiness.md §Shakedown.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 44: Depersonalization-token conformance (PVT* + [OPERATOR_*] vocabulary)"
    local c44_spec="core/standards/depersonalization-spec.md"
    local c44_pvt c44_unreg=""
    # (a) PVT*-literal reintroduction (exempt the guide + marker lines)
    c44_pvt="$(grep -rEn 'PVT(SSF|F|I)?_[A-Za-z0-9]{4,}' --include='*.md' core release operations 2>/dev/null | grep -vE 'github-projects-guide\.md|depersonalization-token: allow' || true)"
    if [[ -n "$c44_pvt" ]]; then
      flag_warn_or_issue "depersonalization-token" "literal GitHub Projects ID (PVT*) reintroduced outside the guide — tokenize to an [OPERATOR_PROJECT*] token: $(printf '%s' "$c44_pvt" | head -3 | tr '\n' ';')"
    fi
    # (b) [OPERATOR_*] bracket-token conformance against the §1/§1.1 registry
    if [[ -f "$c44_spec" ]]; then
      local c44_reg c44_tok
      c44_reg="$(grep -ohE '\[OPERATOR_[A-Z0-9_]+\]' "$c44_spec" | sort -u)"
      while IFS= read -r c44_tok; do
        [[ -z "$c44_tok" ]] && continue
        printf '%s\n' "$c44_reg" | grep -qxF "$c44_tok" || c44_unreg="${c44_unreg}${c44_tok} "
      done < <(grep -rEn '\[OPERATOR_[A-Z0-9_]+\]' --include='*.md' core release operations 2>/dev/null | grep -vE 'release/releases/' | grep -v 'depersonalization-token: allow' | grep -ohE '\[OPERATOR_[A-Z0-9_]+\]' | sort -u)
      if [[ -n "$c44_unreg" ]]; then
        flag_warn_or_issue "depersonalization-token" "unregistered [OPERATOR_*] token(s) in corpus, absent from depersonalization-spec.md §1: ${c44_unreg}— register them (with a config home) or mark an illustrative use 'depersonalization-token: allow'"
      fi
    else
      flag_warn_or_issue "depersonalization-token" "registry missing: $c44_spec"
    fi
    if [[ -z "$c44_pvt" && -z "$c44_unreg" && -f "$c44_spec" ]]; then
      log "  OK:    no PVT* reintroduction; all [OPERATOR_*] tokens registered"
    fi
  fi

  # Check 45 — Design-principle conformance integrity (warn-mode initial) [#320]
  #
  # Three single-responsibility assertions:
  #  (a) Conformance-mechanism presence — the **Design-Principle Conformance:**
  #      D-Gate subsection MUST exist in hub-spoke-bridge.md (its absence means the
  #      per-option conformance mechanism, sibling of Upstream compatibility, regressed).
  #  (b) Register governing_doc drift guard (FMF-1, entry-row-scoped) — every
  #      design-principle-register.md ENTRY ROW's governing_doc (path:line) MUST
  #      resolve to a real, non-empty line. Extraction is scoped to entry rows
  #      (^| DP-N ...) so schema/prose path:line mentions are not self-matched.
  #  (c) Consumer-id resolution (FMF-2) — every DP-N id referenced in tracked
  #      corpus (outside the register, which defines them) MUST resolve to a
  #      defined register principle_id (catches a dangling principles_emphasis id).
  # Clone of the Check-44 conformance-scan pattern (flag_warn_or_issue + shared
  # deploy-check.mode). Companion to #321 (principles_emphasis references the
  # register). Warn-mode initial per bypass-mode-readiness.md Shakedown.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 45: Design-principle conformance integrity (mechanism presence + register drift + consumer-id resolution)"
    local c45_bridge="release/references/how-to/hub-spoke-bridge.md"
    local c45_reg="core/standards/design-principle-register.md"
    local c45_ok=1
    # (a) Conformance-mechanism presence in the D-Gate Template region
    if [[ -f "$c45_bridge" ]]; then
      if ! grep -qE '^\*\*Design-Principle Conformance:\*\*' "$c45_bridge"; then
        flag_warn_or_issue "design-principle-conformance" "the Design-Principle Conformance D-Gate subsection is absent from $c45_bridge — the per-option conformance mechanism (sibling of Upstream compatibility) regressed; restore it per the D-Gate Template"
        c45_ok=0
      fi
    else
      flag_warn_or_issue "design-principle-conformance" "D-Gate surface missing: $c45_bridge"
      c45_ok=0
    fi
    if [[ -f "$c45_reg" ]]; then
      local c45_gd c45_path c45_line c45_defined c45_ref
      # (b) FMF-1 — entry-row-scoped governing_doc resolution
      while IFS= read -r c45_gd; do
        [[ -z "$c45_gd" ]] && continue
        c45_path="${c45_gd%%:*}"
        c45_line="${c45_gd##*:}"
        if [[ ! -f "$c45_path" ]] || ! [[ "$c45_line" =~ ^[0-9]+$ ]] || [[ -z "$(sed -n "${c45_line}p" "$c45_path" 2>/dev/null)" ]]; then
          flag_warn_or_issue "design-principle-conformance" "register governing_doc does not resolve to a real path:line: '$c45_gd' (drift — repoint to the principle's current normative line)"
          c45_ok=0
        fi
      done < <(grep -E '^\| DP-[0-9]' "$c45_reg" | grep -oE '[A-Za-z0-9_./-]+\.md:[0-9]+' | sort -u)
      # (c) FMF-2 — consumer-id resolution (every referenced DP-N resolves)
      c45_defined="$(grep -E '^\| DP-[0-9]' "$c45_reg" | grep -oE 'DP-[0-9]+' | sort -u)"
      while IFS= read -r c45_ref; do
        [[ -z "$c45_ref" ]] && continue
        if ! printf '%s\n' "$c45_defined" | grep -qxF "$c45_ref"; then
          flag_warn_or_issue "design-principle-conformance" "DP-id '$c45_ref' is referenced in corpus but not defined in $c45_reg (dangling principle reference — define the entry or fix the reference)"
          c45_ok=0
        fi
      done < <(grep -rohE 'DP-[0-9]+' --include='*.md' --exclude='design-principle-register.md' core release operations 2>/dev/null | sort -u)
    else
      flag_warn_or_issue "design-principle-conformance" "register missing: $c45_reg"
      c45_ok=0
    fi
    [[ "$c45_ok" -eq 1 ]] && log "  OK:    conformance subsection present; all register governing_doc targets resolve; all DP-id references defined"
  fi


  # ─── Check 46: agent-tools-list-conformance (recursion-surface ratchet) ──
  # Per the subagent-security-posture.md § 4 counter-design (CDF-2) + #189 AC2:
  # validate every release/.claude/agents/pmo-*.md `tools:` enumeration against the
  # recursion-prohibition surface. Two findings per file:
  #   (a) missing `tools:` field entirely — frontmatter does not enumerate the
  #       authorized tool set (an un-enumerated persona is an unbounded surface);
  #   (b) recursion surface — the `tools:` line lists Agent / spawn_task /
  #       mcp__ccd_session__spawn_task (a spoke that can spawn sub-spokes —
  #       precisely the prompt-only-enforced prohibition #189 hardens).
  # This is the deploy-time structural sibling of the runtime block-autonomy-ceiling
  # hook: regardless of whether the harness STRUCTURALLY refuses out-of-list tool
  # calls (the empirically-undetermined Mechanism-1 question), this check catches
  # authoring-time drift. Same pattern as Check 27 (designated-model) / Check 29
  # (return-value-conformance) — agents-dir scan + flag_warn_or_issue.
  #
  # Dir-absent + zero-files tolerance: agents live under release/.claude/agents/
  # (primary) with a .claude/agents/ fallback; NEITHER directory exists in the
  # tracked source tree, so a fresh clone MUST warn (non-blocking via
  # flag_warn_or_issue), never hard-error. POSIX-ERE only (BSD grep; no `\b`).
  # PMO_AGENTS_DIR_OVERRIDE points the scan at a fixture dir for the regression
  # test (core/deploy/tests/test_agent_tools_conformance.sh).
  #
  # Warn-mode initial per bypass-mode-readiness.md § Shakedown (Checks 8/9/10/14/
  # 18-23/25/27/28/29/43/44/45 precedent); flip-to-enforce after the ≥2-3-release
  # warn-log review threshold.
  #
  # Cutover (reflexive-pipeline-loop discipline): applies to ./deploy.sh --check
  # invocations on or after the introducing release's merge SHA in RELEASE_LOG.md.
  # That release itself is exempt — the introducing release IS orchestrated by the
  # Agent-tool subagent mechanism, and the release/.claude/agents/pmo-*.md files
  # are created/populated by later work, so the check cannot assert against state
  # that does not yet exist at this release's Stage 12 deploy-check.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 46: agent-tools-list-conformance (release/.claude/agents/pmo-*.md recursion surface)"
    # PMO_AGENTS_DIR_OVERRIDE (fixture seam) wins; else release/.claude/agents
    # primary with the .claude/agents fallback (Check 27/29 resolution order).
    local c46_agents_dir="${PMO_AGENTS_DIR_OVERRIDE:-release/.claude/agents}"
    if [[ -z "${PMO_AGENTS_DIR_OVERRIDE:-}" ]]; then
      [[ -d "$c46_agents_dir" ]] || c46_agents_dir=".claude/agents"
    fi
    # Recursion-surface tokens on the tools: line. POSIX-ERE word boundaries via
    # explicit start/separator/end classes (no `\b` — unsupported by BSD grep).
    local c46_recursion_re='(^|[[:space:],])(Agent|spawn_task|mcp__ccd_session__spawn_task)([[:space:],]|$)'
    local c46_findings=0
    local c46_output=""
    local c46_files_scanned=0

    if [[ ! -d "$c46_agents_dir" ]]; then
      flag_warn_or_issue "agent-tools-list-conformance" \
        "$c46_agents_dir directory does not exist — agent definitions expected per subagent-security-posture.md § 3 Mechanism 1 (neither release/.claude/agents/ nor .claude/agents/ present in a fresh clone — warn, non-blocking)"
    else
      local _agent_file _agent_name _tools_line
      for _agent_file in "$c46_agents_dir"/pmo-*.md; do
        [[ -f "$_agent_file" ]] || continue
        c46_files_scanned=$((c46_files_scanned + 1))
        _agent_name=$(/usr/bin/basename "$_agent_file" .md)
        # grep exits 1 when no `tools:` line exists; guard so the empty result
        # flows to finding (a) instead of aborting under set -e + pipefail.
        _tools_line=$(/usr/bin/grep -E '^tools:' "$_agent_file" 2>/dev/null | /usr/bin/head -1) || _tools_line=""
        if [[ -z "$_tools_line" ]]; then
          # Finding (a): missing tools: field
          c46_output+="${_agent_file}: missing frontmatter \`tools:\` field — an un-enumerated persona is an unbounded tool surface (subagent-security-posture.md § 3 Mechanism 1)"$'\n'
          c46_findings=$((c46_findings + 1))
        elif /usr/bin/printf '%s' "$_tools_line" | /usr/bin/grep -qE "$c46_recursion_re"; then
          # Finding (b): recursion surface in tools:
          c46_output+="${_agent_file}: \`tools:\` lists a recursion-surface tool (Agent / spawn_task / mcp__ccd_session__spawn_task) — spokes must NOT spawn sub-spokes (#189; subagent-security-posture.md § 3 Mechanism 1 uniform exclusions)"$'\n'
          c46_findings=$((c46_findings + 1))
        fi
      done

      if [[ $c46_files_scanned -eq 0 ]]; then
        flag_warn_or_issue "agent-tools-list-conformance" \
          "$c46_agents_dir/ contains zero pmo-*.md files — agent definitions expected per subagent-security-posture.md § 3 Mechanism 1 (warn, non-blocking on a fresh clone)"
      elif [[ $c46_findings -eq 0 ]]; then
        log "  OK:    all $c46_files_scanned agent definition file(s) declare \`tools:\` with no recursion surface"
      else
        flag_warn_or_issue "agent-tools-list-conformance" \
          "$c46_findings agent definition file(s) of $c46_files_scanned have tools-list conformance drift — see counter-design at core/standards/subagent-security-posture.md § 4 (CDF-2)"
        printf '%s' "$c46_output" | sed 's/^/         /'
      fi
    fi
  fi


  # ─── Check 49: platform-convention linter (warn-mode initial) [#228] ──────────
  #
  # The convention-linter for the FOUR residual platform-convention dimensions no
  # existing gate covers — (1) [topic]-[type].md file-naming, (2) a Layer-2 path
  # (projects/…) in a git-tracked file, (3) evidence-quality-label presence on a
  # dated factual claim in a (non-process-spec) governance file, (4) [TBD]/[INSERT]/
  # [TODO] placeholder leakage outside backticks. The predicate lives ONCE in the
  # shared invokable core/deploy/tools/check-convention.sh (single source; an
  # optional PR-time job can invoke the same script). This is NOT a pre-commit hook
  # — CLAUDE.md forbids normalizing --no-verify, so platform-convention enforcement
  # rides the deploy.sh check family per the #228 placement decision.
  #
  # DELEGATED (documented in-tool, NOT duplicate-enforced here): dead-file-ref +
  # depersonalization + issue-ref -> repo-integrity.yml; localized-context ->
  # Check 25; internal-link integrity -> link-check.yml.
  #
  # Findings route through flag_warn_or_issue (warn-mode-initial per
  # bypass-mode-readiness.md): in warn-mode they annotate + jsonl-log without
  # incrementing ISSUES; flip core/hooks/check-convention.mode (or the shared
  # deploy-check.mode) to 'enforce' after the shakedown window. A non-zero exit
  # with no parsed FAIL (scan-surface error, exit 3) still flags so a broken
  # predicate run never reads green.
  #
  # Cutover discipline: applies to ./deploy.sh --check on or after this release's
  # merge SHA in RELEASE_LOG.md.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 49: platform-convention linter (naming / layer-2 / evidence-label / placeholder) (#228)"
    local c49_mode
    c49_mode=$(resolve_check_mode "check-convention")
    local c49_script="core/deploy/tools/check-convention.sh"
    if [[ ! -f "$c49_script" ]]; then
      flag_warn_or_issue "convention-linter" "predicate script missing: $c49_script"
    else
      local c49_out c49_rc
      c49_out=$(bash "$c49_script" 2>&1)
      c49_rc=$?
      if [[ $c49_rc -eq 3 ]]; then
        # scan-surface error — fail-loud independent of warn-mode
        log "  FAIL:  Check 49 — convention-linter scan-surface error (exit 3)"
        ISSUES=$((ISSUES + 1))
        printf '%s\n' "$c49_out" | grep -E '^(FAIL|SUMMARY):' | sed 's/^/         /'
      else
        local c49_findings c49_line
        c49_findings=0
        while IFS= read -r c49_line; do
          [[ -z "$c49_line" ]] && continue
          case "$c49_line" in
            FAIL:*)
              # route each convention finding through the warn-mode gate, honoring a
              # check-specific check-convention.mode (falls back to the shared mode).
              if [[ "$c49_mode" == "enforce" ]]; then
                log "  ${c49_line}"
                ISSUES=$((ISSUES + 1))
              elif [[ "$c49_mode" == "warn" ]]; then
                log "  WARN:  ${c49_line#FAIL: } (warn-mode; flip check-convention.mode to 'enforce' after shakedown)"
              fi
              c49_findings=$((c49_findings + 1))
              ;;
            SUMMARY:*) : ;;   # deploy.sh prints its own aggregate
            OK:*) log "  ${c49_line}" ;;
          esac
        done <<< "$c49_out"
        if [[ $c49_findings -eq 0 ]]; then
          log "  OK:    no platform-convention findings"
        fi
      fi
    fi
  fi


  # Check 50 — Platform-doc frontmatter standard (warn-mode across core/) [#2220]
  #
  # Enforces core/standards/platform-doc-frontmatter-standard.md (#295) over the
  # authored K1 core/ corpus: Tier-1 required fields (title/purpose/type/status/
  # reversibility); type in the singular platform-doc enum; framework_version_anchor
  # IFF the doc is cataloged in framework-catalog.md (the PRESENCE complement to
  # Check 18b's anchor VALUE-consistency); consumers for standard/schema/spec;
  # reversibility tier-PREFIX match. The tool reads frontmatter via the shared
  # _frontmatter helper and the cataloged-doc set via check-version-anchors.py's
  # own parse_catalog_table, so Check 50 and Check 18b agree by construction (F1).
  #
  # SHIP POSTURE — WARN-MODE ACROSS ALL OF core/, TIER A INCLUDED (D-4 scope-lock,
  # 2026-06-29 Collective Review on #2220): every finding routes through the warn
  # dispatcher at ship; the gate reports non-compliance but does NOT fail the build
  # red. This de-risks the merge — the gate cannot break CI if #109's Tier-A
  # backfill is incomplete on the branch.
  #
  # ENFORCE-FLIP MECHANISM (built now, graduation DEFERRED to #2221): the tool tags
  # each finding with tier (A|other), and this block resolves a per-check mode via
  # resolve_check_mode "doc-frontmatter" (a dedicated doc-frontmatter.mode file,
  # operator-instance runtime state, NOT committed — absent → falls back to the
  # shared warn). When that mode flips to "enforce", the Tier-A leg graduates to a
  # hard FAIL (the dormant enforce branch below) while the rest of core/ keeps
  # warning. The global flip (route Tier-other to FAIL as well) is the second,
  # final graduation, also #2221's — at which point the tier partition collapses.
  # The two-branch structure here IS the one-edit-graduation the design specified.
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (the 14/18/42/43
  # precedent); the introducing release is itself exempt (reflexive-pipeline loop).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 50: Platform-doc frontmatter standard (warn-mode across core/; enforce-flip deferred to #2221)"
    local c50_script="core/deploy/tools/check-doc-frontmatter.py"
    local c50_allowlist="core/deploy/allowlists/skip-doc-frontmatter-check.txt"
    if [[ ! -f "$c50_script" ]]; then
      flag_warn_or_issue "doc-frontmatter" "primitive script missing: $c50_script"
    else
      local c50_mode
      c50_mode=$(resolve_check_mode "doc-frontmatter")
      # The six Tier-A governance-class dirs (enforce target post-flip) + the
      # warn-only remainder (core/skills/**/references). The tool tags the split;
      # this glob list is just the scan surface.
      local c50_targets="core/standards/**/*.md,core/schemas/**/*.md,core/specs/**/*.md,core/disciplines/**/*.md,core/rules/**/*.md,core/governance/**/*.md,core/skills/**/references/*.md"
      local c50_out c50_exit=0
      c50_out=$(/usr/bin/python3 "$c50_script" --target-paths "$c50_targets" --allowlist "$c50_allowlist" --output-format tsv 2>&1) || c50_exit=$?
      if [[ $c50_exit -eq 3 ]]; then
        flag_warn_or_issue "doc-frontmatter" "path-resolution failure (exit 3): $(echo "$c50_out" | head -1) — a --target-paths glob or --catalog-path resolved to zero files; fix the glob list in this check"
      elif [[ $c50_exit -eq 0 || $c50_exit -eq 1 ]]; then
        # Partition findings on the tier column (TSV row 2 is the header;
        # data rows: file<TAB>tier<TAB>field<TAB>violation<TAB>severity).
        local c50_a c50_o
        c50_a=$(echo "$c50_out" | awk -F'\t' 'NR>2 && $2=="A"'     | grep -c . || true)
        c50_o=$(echo "$c50_out" | awk -F'\t' 'NR>2 && $2=="other"' | grep -c . || true)
        c50_a=${c50_a:-0}; c50_o=${c50_o:-0}
        if [[ "$c50_a" -eq 0 && "$c50_o" -eq 0 ]]; then
          log "  OK:    all scanned core/ docs carry conformant frontmatter"
        else
          if [[ "$c50_a" -gt 0 ]]; then
            if [[ "$c50_mode" == "enforce" ]]; then
              # DORMANT until doc-frontmatter.mode flips to enforce (#2221). The
              # graduated Tier-A leg: a missing/invalid required field on a Tier-A
              # doc fails the build.
              log "  FAIL:  doc-frontmatter — $c50_a Tier-A frontmatter violation(s) (enforce). Fix per core/standards/platform-doc-frontmatter-standard.md."
              echo "$c50_out" | awk -F'\t' 'NR>2 && $2=="A"' | head -15 | sed 's/^/         /'
              ISSUES=$((ISSUES + 1))
            else
              # SHIP DEFAULT (D-4): Tier A warns, same as the rest of core/.
              flag_warn_or_issue "doc-frontmatter" "$c50_a Tier-A frontmatter violation(s) (warn-mode across core/ per D-4; flips to enforce with #2221). Fix per core/standards/platform-doc-frontmatter-standard.md."
              echo "$c50_out" | awk -F'\t' 'NR>2 && $2=="A"' | head -15 | sed 's/^/         /'
            fi
          fi
          if [[ "$c50_o" -gt 0 ]]; then
            flag_warn_or_issue "doc-frontmatter" "$c50_o non-Tier-A frontmatter violation(s) (warn-mode; flips to enforce with #2221 Tier B/C backfill)"
            echo "$c50_out" | awk -F'\t' 'NR>2 && $2=="other"' | head -10 | sed 's/^/         /'
          fi
        fi
      else
        flag_warn_or_issue "doc-frontmatter" "check errored (exit $c50_exit): $(echo "$c50_out" | head -1)"
      fi
    fi
  fi


  # Check 51 — Label-taxonomy ↔ GitHub label-set parity (warn-mode initial) [#749]
  #
  # Asserts core/specs/label-taxonomy.md (the canonical label registry) agrees
  # with the live GitHub label set. Two directions, asymmetric severity per the
  # #749 decision + the warn→enforce rollout:
  #   MISSING (canonical label absent from GitHub) → ENFORCE-capable: the #457
  #     `status: rejected` defect class (a gate referencing a non-existent label
  #     fails silently). Gated via resolve_check_mode "label-parity".
  #   ORPHAN (live GitHub label absent from the taxonomy) → WARN only (some are
  #     legitimately operator-local or pending registration, e.g. the `type:*`
  #     family until #1777 documents it). Never FAILs.
  # Multi-source union (#1970): the primitive reads the canonical set as the UNION
  # across every --source. #1970 relocated the concrete label ROWS out of the doc
  # (which keeps the GRAMMAR: group definitions, rules, namespace patterns) into the
  # per-pack `[[labels]]` facets under core/packs/* — so the source set is the doc
  # PLUS every pack.toml. A relocated-but-still-live label resolves in the pack union
  # and does not false-orphan. Title-prefix parity (the #74 `[Observation]:`
  # invariant) is a SEPARATE concern, not evaluated here.
  # Warn-mode initial per bypass-mode-readiness.md §Shakedown (the 14/18/42/43/50
  # precedent); the introducing release is itself exempt (reflexive-pipeline
  # loop). gh-unavailable → SKIP (parity needs the live set; mirrors Check 39/40
  # offline SKIP). Flip the MISSING leg to enforce via a `label-parity.mode` file
  # after the ≥3-day warn-log review.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 51: Label-taxonomy ↔ GitHub label-set parity (warn-mode initial; MISSING-leg enforce-flip deferred)"
    local c51_script="core/deploy/tools/check-label-parity.py"
    local c51_source="core/specs/label-taxonomy.md"
    # #1970: the canonical set is the UNION of the grammar doc + every pack.toml
    # [[labels]] facet (the relocated concrete rows). Build the repeatable --source
    # arg list: the doc, then each existing core/packs/*/pack.toml.
    local c51_source_args=(--source "$c51_source")
    local c51_pack
    for c51_pack in core/packs/*/pack.toml; do
      [[ -f "$c51_pack" ]] && c51_source_args+=(--source "$c51_pack")
    done
    if [[ ! -f "$c51_script" ]]; then
      flag_warn_or_issue "label-parity" "primitive script missing: $c51_script"
    elif ! command -v gh >/dev/null 2>&1; then
      log "  SKIP:  gh unavailable — label-parity needs the live label set (offline/unauth; mirrors Check 39/40)"
    else
      local c51_mode
      c51_mode=$(resolve_check_mode "label-parity")
      local c51_out c51_exit=0
      c51_out=$(/usr/bin/python3 "$c51_script" "${c51_source_args[@]}" --output-format tsv 2>&1) || c51_exit=$?
      if [[ $c51_exit -eq 3 ]]; then
        flag_warn_or_issue "label-parity" "input failure (exit 3): $(echo "$c51_out" | head -1) — --source parsed to zero labels or the live set was unreadable; fix the source/parser"
      elif [[ $c51_exit -eq 0 || $c51_exit -eq 1 ]]; then
        local c51_missing c51_orphan
        c51_missing=$(echo "$c51_out" | awk -F'\t' '$1=="MISSING"{print $2}')
        c51_orphan=$(echo "$c51_out"  | awk -F'\t' '$1=="ORPHAN"{print $2}')
        if [[ -z "$c51_missing" && -z "$c51_orphan" ]]; then
          log "  OK:    label-taxonomy.md and the GitHub label set are in parity"
        else
          if [[ -n "$c51_missing" ]]; then
            if [[ "$c51_mode" == "enforce" ]]; then
              log "  FAIL:  label-parity — canonical label(s) absent from GitHub:"
              echo "$c51_missing" | sed 's/^/           - /'
              ISSUES=$((ISSUES + 1))
            else
              flag_warn_or_issue "label-parity" "canonical label(s) absent from GitHub (warn-mode; flip label-parity.mode to enforce after shakedown): $(echo "$c51_missing" | paste -sd, -)"
            fi
          fi
          if [[ -n "$c51_orphan" ]]; then
            flag_warn_or_issue "label-parity" "GitHub label(s) not registered in the taxonomy (warn-only — may be operator-local or pending registration): $(echo "$c51_orphan" | paste -sd, -)"
          fi
        fi
      else
        flag_warn_or_issue "label-parity" "check errored (exit $c51_exit): $(echo "$c51_out" | head -1)"
      fi
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

# ─── Mode: --check-version-freeness (the CI merge-gate probe) — #1677 ─────────
#
# Runs ONLY the version-freeness verdict (not the full --check suite) and maps the
# verdict to an EXIT CODE — the verdict->exit contract the CI merge gate depends on
# (Stage-5 adversarial review FM-2). The exit is VERDICT-DRIVEN, decoupled from the
# lifecycle surface's warn-mode emit: a collision or an undecidable result red-exits
# even during the warn-mode calibration window, so the CI gate (version-freeness.yml)
# blocks on exactly the cases DD4 must block. Warn-mode-vs-enforce at the CI surface
# is decided by the workflow's committed `.github/version-freeness.enforce` sentinel
# (it swallows this exit 1 into a non-blocking report during calibration) — this
# probe always reports the TRUE verdict via its exit code.
#
# Surface = "gate": a merely-offline published-Release anchor is FAIL-CLOSED here
# (the merge gate must not certify freeness blind), NOT degraded to N/A (that
# degradation is the lifecycle --check surface's posture only).
#
#   exit 0  — FREE, or SKIP (no claim context — nothing to assert; an unrelated PR).
#   exit 1  — NOT_FREE (collision) OR UNDECIDABLE (fail-closed: non-canonical tag,
#             malformed candidate, or anchor unreachable at the gate).
cmd_check_version_freeness() {
  validate_workspace
  detect_install_path || true

  local verdict tok
  verdict="$(_vf_compute_verdict "gate")"
  tok="${verdict%% *}"
  case "$tok" in
    FREE)
      log "version-freeness: ${verdict#FREE } is free (not in claimed_set) — OK"
      exit 0
      ;;
    SKIP)
      log "version-freeness: SKIP — ${verdict#SKIP } (no version-claim surface to assert; not a collision)"
      exit 0
      ;;
    NOT_FREE)
      log "version-freeness: NOT_FREE — ${verdict#NOT_FREE }"
      log "  Re-version BEFORE merge: a Stage-12 Phase B3 signed-tag push would be rejected AFTER the merge lands with stale labels."
      exit 1
      ;;
    UNDECIDABLE)
      log "version-freeness: UNDECIDABLE (fail-closed) — ${verdict#UNDECIDABLE }"
      log "  The merge gate cannot certify freeness; operator must resolve the untaggable state before merge."
      exit 1
      ;;
    NA)
      # Should not occur at the gate surface (gate fail-closes offline); treat as
      # fail-closed defensively rather than greening on an unexpected N/A.
      log "version-freeness: NA at gate surface (unexpected) — fail-closed: ${verdict#NA }"
      exit 1
      ;;
    *)
      log "version-freeness: unexpected verdict '$verdict' — fail-closed"
      exit 1
      ;;
  esac
}

# ─── Mode: --self-test (close-completeness invariant regression) — #1290 AC5 ───
#
# Offline + hermetic. Proves the load-bearing invariant: a deliberately-abbreviated
# scaffold — a VERIFIED RELEASE_LOG row whose Stage-13 output-set is incomplete (the
# v2.02-class drop) — is STILL CAUGHT by the close-completeness gate (Check 48's
# shared _cc_compute_verdict body) BEFORE the release can be reported "complete". The
# fixture drives _cc_compute_verdict against a sandbox corpus (no network, no live
# RELEASE_LOG, no gh) the same way automated-closeout.sh Test 5.5 stubs the lint —
# CC_* env overrides re-point every corpus path at the sandbox.
#
# Assertions:
#   (1) abbreviated  — a VERIFIED v9.99 row with NOTES/INDEX/DIGEST absent ⇒ verdict
#                      INCOMPLETE (the missing codified step is caught).
#   (2) complete     — the same row with the full output-set present ⇒ verdict CLEAN.
#   (3) dormant      — cutover unset (__none__) ⇒ verdict SKIP (no false-positive on
#                      historical rows; the reflexive-loop exemption holds).
#   (4) state-scoped — a DEPLOYED-not-VERIFIED incomplete row ⇒ NOT counted (CLEAN);
#                      the gate is VERIFIED-scoped (mid-close rows are skipped).
cmd_self_test() {
  echo "self-test: starting (close-completeness invariant, #1290 AC5)" >&2
  local failures=0
  local _t; _t="$(/usr/bin/mktemp -d -t closecomplete-selftest.XXXXXX)"

  # --- sandbox corpus scaffolding ---
  /bin/mkdir -p "$_t/notes" "$_t/tools"
  local _log="$_t/RELEASE_LOG.md"
  local _index="$_t/RELEASE_INDEX.md"
  local _digest="$_t/RELEASE_DIGEST.md"
  local _notes="$_t/notes"
  local _changelog="$_t/CHANGELOG.md"
  local _version="$_t/.version"
  # A note-content lint STUB (mirrors automated-closeout.sh Test 5.5): always exit 0
  # (clean) so §3.2 is not the variable under test — the test isolates the
  # output-set-presence assertion, not the lint's own logic (covered by its own tests).
  local _lint="$_t/tools/lint_release_corpus.py"
  /bin/cat > "$_lint" <<'STUB'
import sys
sys.exit(0)
STUB
  # A body-drift STUB: exit 3 (no Release/note to compare) so the network sub-check
  # never red-fails offline. Irrelevant here anyway — network cutover stays __none__.
  local _drift="$_t/check-release-body-drift.sh"
  /bin/cat > "$_drift" <<'STUB'
#!/usr/bin/env bash
exit 3
STUB
  /bin/chmod +x "$_drift"

  # The LOG: one VERIFIED row (v9.99) — the release under test — plus a DEPLOYED row
  # (v9.98, mid-close) used by assertion (4). 8-col schema matching live RELEASE_LOG.
  /bin/cat > "$_log" <<'EOF'
# RELEASE_LOG (self-test fixture)
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.98 | v9.98-midclose | #1 | #2 | `abc` | `v9.98` | DEPLOYED | 2026-06-28 |
| v9.99 | v9.99-selftest | #1 | #2 | `def` | `v9.99` | VERIFIED | 2026-06-28 |
EOF

  # Common CC_* overrides (re-point every corpus path at the sandbox). Network
  # cutover stays unset (__none__) ⇒ no gh dependency. The ROW cutover arms on v9.98
  # so both fixture rows are in scope (the VERIFIED filter still excludes v9.98).
  _cc_selftest_verdict() {
    CC_LOG="$_log" CC_INDEX="$_index" CC_DIGEST="$_digest" CC_CHANGELOG="$_changelog" \
    CC_VERSIONFILE="$_version" CC_NOTES_DIR="$_notes" CC_LINT="$_lint" CC_DRIFT="$_drift" \
    CC_ALLOWLIST="$_t/none.txt" \
    CLOSE_COMPLETENESS_CHECK_CUTOFF="$1" CLOSE_COMPLETENESS_RELEASE_CUTOFF="__none__" \
    _cc_compute_verdict "lifecycle" 2>/dev/null
  }

  local _v _tok

  # (3) dormant — cutover unset ⇒ SKIP (assert FIRST: the safe default).
  _v="$(_cc_selftest_verdict "__none__")"; _tok="${_v%% *}"
  [[ "$_tok" == "SKIP" ]] || { echo "FAIL: dormant (cutover __none__) must SKIP, got '$_v'"; failures=$((failures+1)); }

  # (1) abbreviated — VERIFIED v9.99 with NOTES/INDEX/DIGEST absent ⇒ INCOMPLETE.
  /usr/bin/printf '# RELEASE_INDEX (empty)\n' > "$_index"
  /usr/bin/printf '# RELEASE_DIGEST (empty)\n' > "$_digest"
  /usr/bin/printf 'v9.99\n' > "$_version"
  _v="$(_cc_selftest_verdict "v9.98")"; _tok="${_v%% *}"
  [[ "$_tok" == "INCOMPLETE" ]] || { echo "FAIL: abbreviated scaffold (missing NOTES/INDEX/DIGEST) must be caught (INCOMPLETE), got '$_v'"; failures=$((failures+1)); }

  # (2) complete — add NOTES + INDEX row + DIGEST entry + CHANGELOG section ⇒ CLEAN.
  /usr/bin/printf '# v9.99 release notes\n' > "$_notes/v9.99_RELEASE_NOTES.md"
  /usr/bin/printf '# RELEASE_INDEX\n| v9.99 | v9.99-selftest | 2026-06-28 |\n' > "$_index"
  /usr/bin/printf '# RELEASE_DIGEST\n### v9.99 (2026-06-28)\nSelf-test entry.\n' > "$_digest"
  /usr/bin/printf '# Changelog\n## [v9.99] - 2026-06-28\nSelf-test.\n' > "$_changelog"
  _v="$(_cc_selftest_verdict "v9.98")"; _tok="${_v%% *}"
  [[ "$_tok" == "CLEAN" ]] || { echo "FAIL: complete output-set must verify CLEAN, got '$_v' (detail: $(_cc_selftest_verdict "v9.98" 2>&1 >/dev/null | /usr/bin/tr '\n' ';'))"; failures=$((failures+1)); }
  # And CLEAN must count exactly 1 VERIFIED row (v9.99) — v9.98 is DEPLOYED (excluded).
  [[ "$_v" == "CLEAN 1" ]] || { echo "FAIL: CLEAN must report exactly 1 VERIFIED in-scope row (v9.98 DEPLOYED excluded), got '$_v'"; failures=$((failures+1)); }

  # (4) state-scoped — flip v9.98 to VERIFIED but leave ITS output-set absent ⇒ now
  # INCOMPLETE (it is in scope as VERIFIED); proves the VERIFIED filter is what gates
  # inclusion, not row presence. (v9.99 stays complete; only v9.98 is the new finding.)
  /usr/bin/sed 's/| `v9.98` | DEPLOYED |/| `v9.98` | VERIFIED |/' "$_log" > "$_t/log2.md" && /bin/mv "$_t/log2.md" "$_log"
  _v="$(CC_LOG="$_log" CC_INDEX="$_index" CC_DIGEST="$_digest" CC_CHANGELOG="$_changelog" \
        CC_VERSIONFILE="$_version" CC_NOTES_DIR="$_notes" CC_LINT="$_lint" CC_DRIFT="$_drift" \
        CC_ALLOWLIST="$_t/none.txt" \
        CLOSE_COMPLETENESS_CHECK_CUTOFF="v9.98" CLOSE_COMPLETENESS_RELEASE_CUTOFF="__none__" \
        _cc_compute_verdict "lifecycle" 2>/dev/null)"; _tok="${_v%% *}"
  [[ "$_tok" == "INCOMPLETE" ]] || { echo "FAIL: a now-VERIFIED incomplete row (v9.98) must be caught once it is VERIFIED-scoped, got '$_v'"; failures=$((failures+1)); }

  /bin/rm -rf "$_t" 2>/dev/null || true

  if [[ "$failures" -gt 0 ]]; then
    echo "self-test: FAIL ($failures failure(s))" >&2
    return 1
  fi
  echo "self-test: PASS" >&2
  echo "  close-completeness invariant validated (#1290 AC5):" >&2
  echo "    dormant cutover SKIPs / abbreviated scaffold caught (INCOMPLETE) / complete set CLEAN / VERIFIED-scoped (DEPLOYED excluded, VERIFIED included)" >&2
  return 0
}

# ─── Mode: --check-close-completeness (the CI close-completeness probe) — #1290 ─
#
# Runs ONLY the close-completeness verdict (not the full --check suite) and maps the
# verdict to an EXIT CODE — the verdict->exit contract a CI gate depends on. The exit
# is VERDICT-DRIVEN, decoupled from the lifecycle Check 48's warn-mode emit: an
# INCOMPLETE result red-exits even during the warn-mode calibration window, so the CI
# gate (close-completeness.yml) reports the TRUE verdict via this exit code. Warn-mode-
# vs-enforce at the CI surface is decided by the workflow's committed
# `.github/close-completeness.enforce` sentinel (it swallows this exit 1 into a
# non-blocking report during calibration) — this probe always reports the true verdict.
#
# Surface = "gate": a merely-offline network anchor (Surface-1 Release / body-drift)
# is FAIL-CLOSED here (the gate must not certify completeness blind), NOT degraded to
# N/A (that degradation is the lifecycle --check surface's posture only). This mirrors
# cmd_check_version_freeness's gate-surface fail-closed contract.
#
#   exit 0  — CLEAN (full output-set present for every in-scope VERIFIED row), OR
#             SKIP (gate dormant — no cutover set / no LOG; nothing to assert).
#   exit 1  — INCOMPLETE (a VERIFIED row is missing a Stage-13 output) OR an
#             unexpected verdict (fail-closed).
cmd_check_close_completeness() {
  validate_workspace
  detect_install_path || true

  # Sentinel-aware enforcement (the dormant-via-sentinel mechanism). The committed
  # .github/close-completeness.enforce marker's first non-comment token decides whether
  # an INCOMPLETE verdict BLOCKS (enforce ⇒ exit 1) or is SWALLOWED non-blocking
  # (warn / absent ⇒ exit 0, true verdict still reported). This mirrors Check 47's
  # dormant-by-default posture and version-freeness's committed-sentinel switch, while
  # keeping the gate self-contained (the probe reads the sentinel directly, so the
  # sentinel is load-bearing without requiring a CI workflow to be wired first; a
  # thin CI caller can still consume this exit code once added).
  local cc_enforce_file="${CLOSE_COMPLETENESS_ENFORCE_FILE:-.github/close-completeness.enforce}"
  local cc_enforce="warn" _cc_tok_line
  if [[ -f "$cc_enforce_file" ]]; then
    _cc_tok_line="$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$cc_enforce_file" 2>/dev/null | /usr/bin/head -1 | /usr/bin/tr -d '[:space:]')"
    [[ "$_cc_tok_line" == "enforce" ]] && cc_enforce="enforce"
  fi

  local verdict tok
  verdict="$(_cc_compute_verdict "gate")"
  tok="${verdict%% *}"
  case "$tok" in
    CLEAN)
      log "close-completeness: ${verdict#CLEAN } VERIFIED release(s) in scope have the complete Stage-13 output-set — OK"
      exit 0
      ;;
    SKIP)
      log "close-completeness: SKIP — ${verdict#SKIP } (gate dormant; nothing to assert)"
      exit 0
      ;;
    INCOMPLETE)
      log "close-completeness: INCOMPLETE — ${verdict#INCOMPLETE } (findings count / checked-row count; see detail above)"
      log "  A close dropped a Stage-13 output. The scaffold-independent gate fired regardless of how the close ran (spoke / hub-direct / chore-PR)."
      log "  Backfill the missing output(s) per release/references/pipeline/stage-13-close.md Phase B; a scaffold abbreviation never waives a codified Phase step (ADR-048)."
      if [[ "$cc_enforce" == "enforce" ]]; then
        exit 1
      fi
      log "  WARN-MODE (sentinel '$cc_enforce_file' token != enforce): reporting the true verdict but NOT blocking — flip the token to 'enforce' after shakedown."
      exit 0
      ;;
    *)
      log "close-completeness: unexpected verdict '$verdict' — fail-closed"
      # An unexpected verdict is a tooling failure, not a calibration finding — always
      # fail-closed regardless of the warn/enforce sentinel.
      exit 1
      ;;
  esac
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

  # --- Platform .version drift vs latest published Release (Check 39) ---
  # Mirrors cmd_check's Check 39 (#1643) into report PASS/FAIL form. As with Checks
  # 16/17/18, the report uses unvarnished enforce-mode semantics regardless of
  # cmd_check warn-mode — the "what would happen in enforce-mode" view, suitable for
  # Stage 13 evidence. Anchor = latest PUBLISHED Release (the version-skew hook's own
  # query). Offline/unauth or no published Release => N/A (counted PASS — not a
  # finding; matches the Check 32 N/A-never-FAIL idiom). >=2 published-minors apart or
  # different major-lineage => FAIL; exactly 1 apart (Stage-12->13 window) => PASS.
  echo "--- Platform .version drift vs latest published Release (Check 39) ---"
  local c39r_version_file="$_audit_src_root/.version"
  if [[ -z "$_audit_src_root" || ! -f "$c39r_version_file" ]]; then
    echo "[PASS] version-stamp-skew — N/A: .version not present at repo root (no anchor)"
    PASS=$((PASS + 1))
  elif ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1 || [[ -z "$AUDIT_REPO" ]]; then
    echo "[PASS] version-stamp-skew — N/A: published-release anchor unavailable (gh offline/unauth or repo unresolved)"
    PASS=$((PASS + 1))
  else
    local c39r_local c39r_anchor
    c39r_local="$(/usr/bin/head -1 "$c39r_version_file" 2>/dev/null | tr -d '[:space:]')"
    c39r_anchor="$(gh api "repos/${AUDIT_REPO}/releases/latest" --jq '.tag_name' 2>/dev/null | tr -d '[:space:]')"
    if [[ -z "$c39r_anchor" ]]; then
      echo "[PASS] version-stamp-skew — N/A: no published GitHub Release for $AUDIT_REPO"
      PASS=$((PASS + 1))
    elif [[ "$c39r_local" == "$c39r_anchor" ]]; then
      echo "[PASS] version-stamp-skew — .version ($c39r_local) == latest published Release ($c39r_anchor)"
      PASS=$((PASS + 1))
    else
      local c39r_l_maj c39r_l_min c39r_a_maj c39r_a_min
      c39r_l_maj="$(/usr/bin/printf '%s' "$c39r_local"  | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\1/p')"
      c39r_l_min="$(/usr/bin/printf '%s' "$c39r_local"  | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\2/p')"
      c39r_a_maj="$(/usr/bin/printf '%s' "$c39r_anchor" | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\1/p')"
      c39r_a_min="$(/usr/bin/printf '%s' "$c39r_anchor" | /usr/bin/sed -nE 's/^v([0-9]+)\.([0-9]+).*/\2/p')"
      if [[ -z "$c39r_l_maj" || -z "$c39r_a_maj" ]]; then
        echo "[FAIL] version-stamp-skew — .version ('$c39r_local') or latest-Release ('$c39r_anchor') not parseable vMAJOR.MINOR"
        FAIL=$((FAIL + 1))
      elif [[ "$c39r_l_maj" != "$c39r_a_maj" ]]; then
        echo "[FAIL] version-stamp-skew — .version ($c39r_local) different major-lineage than latest published Release ($c39r_anchor)"
        FAIL=$((FAIL + 1))
      else
        local c39r_dist=$(( 10#$c39r_l_min - 10#$c39r_a_min )); local c39r_abs=${c39r_dist#-}
        if [[ "$c39r_abs" -le 1 ]]; then
          echo "[PASS] version-stamp-skew — .version ($c39r_local) within 1 published-minor of latest Release ($c39r_anchor) — Stage-12->13 window"
          PASS=$((PASS + 1))
        else
          echo "[FAIL] version-stamp-skew — .version ($c39r_local) is $c39r_abs published-minors from latest published Release ($c39r_anchor) — stale source-of-truth; bump per stage-13-close.md Phase B5.7"
          FAIL=$((FAIL + 1))
        fi
      fi
    fi
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
    --check-lifecycle)
      cmd_check_lifecycle
      exit 0
      ;;
    --check-version-freeness)
      # Single-check CI merge-gate probe (#1677): runs ONLY Check 41's freeness
      # verdict and exits per the verdict (0 FREE/SKIP, 1 NOT_FREE/UNDECIDABLE —
      # fail-closed). The version-freeness logic ALSO fires inside the full --check
      # suite (Check 41, gated on version-freeness.mode) — one shared body
      # (_vf_compute_verdict), no copy. Used by .github/workflows/version-freeness.yml.
      cmd_check_version_freeness
      ;;
    --check-close-completeness)
      # Single-check CI close-completeness probe (#1290): runs ONLY Check 48's
      # verdict and exits per the verdict (0 CLEAN/SKIP, 1 INCOMPLETE — fail-closed
      # at the gate surface). The close-completeness logic ALSO fires inside the full
      # --check suite (Check 48, gated on close-completeness.mode) — one shared body
      # (_cc_compute_verdict), no copy. Used by .github/workflows/close-completeness.yml.
      cmd_check_close_completeness
      ;;
    --self-test)
      # Offline, hermetic regression for the close-completeness invariant (#1290 AC5):
      # a deliberately-abbreviated scaffold (a VERIFIED row missing a Stage-13 output)
      # is still CAUGHT by Check 48 before "complete". Proves the gate is scaffold-
      # independent. Exit 0 on success, 1 on any failure.
      cmd_self_test
      exit 0
      ;;
    --report)
      cmd_report
      ;;
    *)
      echo "Usage: ./deploy.sh [--deploy [skill...] | --all | --check [--warn] | --check-lifecycle | --check-version-freeness | --check-close-completeness | --self-test | --report]"
      echo ""
      echo "Modes:"
      echo "  --deploy [skill...]          Deploy changed skills to Cowork install path (auto-detect or manual)"
      echo "  --all                        Deploy the full skill roster + all packages (explicit bootstrap / redeploy-everything)"
      echo "  --check [--warn]             Validate platform health (--warn exits 0 even with issues)"
      echo "  --check-lifecycle            List retired/dormant checks + dispositions + reactivation anchors"
      echo "  --check-version-freeness     Pre-merge version-freeness probe (Check 41 only; exits 1 on a claimed/undecidable candidate) (#1677)"
      echo "  --check-close-completeness   Close-completeness probe (Check 48 only; exits 1 on a VERIFIED row missing a Stage-13 output) (#1290)"
      echo "  --self-test                  Offline regression for the close-completeness invariant (abbreviated scaffold still caught) (#1290)"
      echo "  --report                     Structured report for Stage 13 verification evidence"
      echo ""
      echo "Note: --init mode (a legacy cutover migration) was REMOVED per the"
      echo "      Stage 5 spec §1.7. v2 ships with the target layout; no migration needed."
      exit 1
      ;;
  esac
}

main "$@"
