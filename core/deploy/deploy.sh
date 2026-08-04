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
  pmo-wms-specialist
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
  adr-helper
  context-budget-auditor
  eval-writer
  finops-usage-extractor
  pmo-qa-auditor
  pmo-skill-router
  prompt-builder
  session-retro
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

# ─── Template-sync canonical-source resolver ────────────────────────────────
# Single source for resolve_template_sync_source() — the TEMPLATE_SYNC_MAP
# canonical-source resolution rule. Sourced (not inlined) so build-skill-
# packages.sh shares the SAME definition and the two can never diverge (#2158 —
# the drift class that broke the #94 pmo-skill-editor rebuild). Sourced from this
# script's own dir so it resolves regardless of the caller's cwd.
# shellcheck source=lib-template-sync-source.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib-template-sync-source.sh"

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
  # ── Registered complementary pair: tracker-manager (#4178 — 1 entry) ──
  # NOT a template mirror. tracker-manager's SKILL.md cites
  # core/schemas/tracker-schemas.md four times for the Tracker 5-10 field sets,
  # and the shipped package carried only the skill-local half — so from the
  # package root those citations resolved to nothing and the skill's own
  # "if neither copy defines it, BLOCK" rule had to fire on 6 of 10 trackers.
  #
  # The target is the canonical's REPO-RELATIVE path, not a references/ path, so
  # the existing citations resolve verbatim with no SKILL.md edit. Check 13 then
  # asserts the injected copy is byte-identical to the canonical at both runtime
  # targets — byte-identity between the canonical and ITS OWN injected copy,
  # which is exactly right; it asserts nothing between the two halves of the
  # complementary pair, whose relationship Check 13b owns.
  #
  # WHY A MAP ENTRY AND NOT A HAND-CODED INJECTION. Two builders stage a skill:
  # build-skill-packages.sh build_one() writes the committed .skill, and
  # deploy.sh build_skill_to_dir() stages the rebuild Check 7 hashes against the
  # committed sidecar. Their agreement is declared in a comment and enforced by
  # nothing. Injecting in one alone makes the two hashes disagree BY
  # CONSTRUCTION — a permanent STALE that no rebuild can clear, on an
  # always-enforce check. Both builders consume THIS array from this one
  # declaration (build-skill-packages.sh extracts it at runtime), so a map entry
  # keeps them aligned by construction instead of by hope.
  #
  # The resolver arm for this basename is load-bearing: see
  # core/deploy/lib-template-sync-source.sh. Without it the basename falls to
  # the default arm and resolves to a path that does not exist.
  "tracker-manager:tracker-schemas.md:core/schemas/tracker-schemas.md"
)

# ─── Shared Functions ────────────────────────────────────────────────────────

die() {
  echo "ERROR: $1" >&2
  exit 1
}

# Timestamp carries its UTC offset (%z) so a log line can be resolved to an
# instant after the fact (#3718). A bare local wall-clock cannot: read back a day
# later, or by anyone at a different offset, "[14:03:22]" names no moment. Per
# core/standards/date-variable-convention.md § Emission-Time Anchors — an
# emission instant MUST be resolvable to one.
log() {
  echo "[$(date +%H:%M:%S%z)] $1"
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

# _vf_deployed_rows_from_log — echo the Version cell of every DEPLOYED-state row in a
#   RELEASE_LOG, one per line. Returns 3 (with a stderr diagnostic) when the schema header
#   cannot be resolved. Split out of _vf_build_claimed_set for ONE reason: as an inline arm
#   of that function's `{ … } | sed | sort -u` pipeline its rc was structurally unobservable,
#   so the exit 3 below could never reach any caller (DT-2). A standalone function has an rc
#   the caller can read.
_vf_deployed_rows_from_log() {
  local _log="$1"
  # (3) RELEASE_LOG rows in DEPLOYED (tag-pushed-but-Release-unpublished) state.
  #
  # COLUMNS ARE PINNED BY HEADER NAME, NEVER BY ORDINAL. This arm previously read
  # `st=$7` and called it State. It is not: under `awk -F'|'` the leading table pipe
  # makes $1 empty, so the 8-column schema
  #   | Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
  # maps Version=$2, Tag=$7, State=$8. A Tag cell holds a backticked version, never
  # the literal DEPLOYED, so `st == "DEPLOYED"` could never be true for a well-formed
  # row and this whole arm was structurally dead — deploy.sh could not see an
  # in-flight claim at all. claim-version.sh::_host_release_log_deployed fixed the
  # identical off-by-one and the correction never reached this parallel copy.
  # Resolving by NAME removes the failure mode rather than correcting one instance
  # of it: a future column insertion shifts the ordinals and this arm keeps working.
    awk -F'|' '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      /^\|/ {
        if (!have) {
          # Header row = the first pipe-row carrying BOTH column names. Prose pipes
          # and stray tables above the schema are skipped rather than misread.
          v = 0; s = 0
          for (i = 1; i <= NF; i++) {
            c = trim($i)
            if (c == "Version") v = i
            if (c == "State")   s = i
          }
          if (v && s) { vcol = v; scol = s; have = 1 }
          next
        }
        ver = trim($vcol); st = trim($scol)
        if (st == "DEPLOYED" && ver ~ /^v[0-9]/) print ver
      }
      END {
        # Fail LOUD, not silently-empty: an unreadable schema is the condition that
        # produced this defect, so it is reported rather than inferred from emptiness.
        if (!have) { print "deploy.sh: _vf_build_claimed_set — RELEASE_LOG header row has no Version+State columns; the DEPLOYED arm was not evaluated" > "/dev/stderr"; exit 3 }
      }
    ' "$_log"
    # NB: awk stderr is deliberately NOT sent to /dev/null here. The END-block
    # diagnostic above is the whole point — an unreadable schema must be visible,
    # not inferred from an empty arm. The program is fixed and the file existence
    # is guarded, so there is no other stderr this could surface.
}

# _vf_published_tags_from_api  — echo the published Release tag_names, one per line.
#   Split out of _vf_build_claimed_set for the SAME reason _vf_deployed_rows_from_log
#   was (#4339, residual A): as an inline arm of that function's `{ … } | sed | sort -u`
#   pipeline under a trailing `|| true`, a failing `gh api` was structurally
#   indistinguishable from "this repo has published no Releases". The DT-2 pass
#   repaired only arm (3), leaving an authenticated-but-erroring `gh` still degrading
#   to a silently-partial set — and a partial claimed_set silently certifies a
#   COLLIDING candidate FREE, which is the fail-open this whole check exists to close.
#
#   APPLICABILITY vs. FAILURE (the distinction that keeps the offline path working).
#   No repo identity / no `gh` / `gh` unauthenticated => the arm is N/A: rc 0, no
#   output. That is not a failure, it is "this arm does not apply here", and the
#   offline SURFACE-SPLIT is the caller's decision (_vf_compute_verdict gates on
#   anchor_offline and short-circuits to NA/UNDECIDABLE before ever reaching here).
#   Once those preconditions HOLD the arm is expected to answer, so a failure of the
#   call itself is re-raised rather than swallowed.
_vf_published_tags_from_api() {
  local _repo="$1"
  [[ -n "$_repo" ]] || return 0
  command -v gh >/dev/null 2>&1 || return 0
  gh auth status >/dev/null 2>&1 || return 0
  local _raw _rc=0
  # stderr deliberately NOT redirected — gh's own diagnostic is the operator's
  # only clue why the arm went unevaluable (same posture as the awk END-block above).
  _raw="$(gh api "repos/${_repo}/releases" --paginate --jq '.[].tag_name')" || _rc=$?
  if [[ "$_rc" -ne 0 ]]; then
    printf 'deploy.sh: _vf_build_claimed_set — published-Releases arm read FAILED (gh api rc=%s); the arm was not evaluated\n' "$_rc" >&2
    return "$_rc"
  fi
  [[ -n "$_raw" ]] || return 0
  printf '%s\n' "$_raw"
}

# _vf_origin_tags_from_remote  — echo origin's tag refs, one bare tag name per line.
#   Same split, same reason (#4339, residual A — and the direct sibling of the
#   claim-version.sh::_host_origin_tags defect this release closes). Inline, the read
#   sat at the head of a `| sed` pipeline under `|| true`, so its status was never
#   observable and a failed remote read presented as a tagless repository.
#
#   APPLICABILITY vs. FAILURE, as above: a source root that is not a git checkout, or
#   one with no `origin` remote, means the arm is N/A (rc 0, no output) — this is the
#   git-side twin of the `gh auth status` precondition. When origin IS configured the
#   read is expected to answer, so its failure is re-raised.
_vf_origin_tags_from_remote() {
  local _root="$1"
  git -C "$_root" rev-parse --git-dir >/dev/null 2>&1 || return 0
  git -C "$_root" remote get-url origin >/dev/null 2>&1 || return 0
  local _raw _rc=0
  _raw="$(git -C "$_root" ls-remote --tags origin)" || _rc=$?
  if [[ "$_rc" -ne 0 ]]; then
    printf 'deploy.sh: _vf_build_claimed_set — origin-tags arm read FAILED (git ls-remote rc=%s); the arm was not evaluated\n' "$_rc" >&2
    return "$_rc"
  fi
  [[ -n "$_raw" ]] || return 0
  printf '%s\n' "$_raw" | sed -e 's#.*refs/tags/##' -e 's/\^{}$//'
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
#   RC CONTRACT (load-bearing — DT-2). The DEPLOYED arm's `exit 3` on an unreadable
#   RELEASE_LOG schema is the whole point of the END-block diagnostic, and it MUST
#   reach the caller. It previously could not: the arm ran INSIDE the `{ … } | sed |
#   sort -u` pipeline under a trailing `|| true`, so the function's rc was `sort`'s
#   (always 0) and the arm degraded to a silently-empty one. From the caller's
#   position an unreadable schema was then indistinguishable from "nothing is
#   DEPLOYED" — the exact fail-open shape this function exists to close, recreated
#   inside its own fix. The arm is therefore evaluated BEFORE the pipeline, its rc
#   captured, and re-raised as the function's rc after the pipeline has emitted. The
#   caller (_vf_compute_verdict) rc-checks and fails closed to UNDECIDABLE.
_vf_build_claimed_set() {
  local repo="$1"
  local _root="${_audit_src_root:-.}"
  # ALL THREE arms are evaluated FIRST, outside the pipeline, so their rc survives
  # (#4339 residual A generalises the DT-2 rc-contract from arm (3) to arms (1) and
  # (2) — the defect class is "an arm that fails silently", not one instance of it).
  local _published="" _published_rc=0
  _published="$(_vf_published_tags_from_api "$repo")" || _published_rc=$?
  local _origin="" _origin_rc=0
  _origin="$(_vf_origin_tags_from_remote "$_root")" || _origin_rc=$?
  # stderr is deliberately NOT redirected — the END-block diagnostic must stay visible.
  local _deployed="" _deployed_rc=0
  local _log="${_root}/release/releases/RELEASE_LOG.md"
  if [[ -f "$_log" ]]; then
    _deployed="$(_vf_deployed_rows_from_log "$_log")" || _deployed_rc=$?
  fi
  {
    # (1) published Release tags (the authoritative anchor, same as Check 39).
    [[ -n "$_published" ]] && printf '%s\n' "$_published"
    # (2) origin signed tags.
    [[ -n "$_origin" ]] && printf '%s\n' "$_origin"
    # (3) RELEASE_LOG DEPLOYED rows. All computed ABOVE, outside this pipeline, so an
    #     arm failure survives to the caller (see the RC CONTRACT). Emitted here so the
    #     union's shape and the shared grammar filter are unchanged.
    [[ -n "$_deployed" ]] && printf '%s\n' "$_deployed"
  } | sed '/^$/d' | sort -u
  # Re-raise the FIRST failing arm's rc AFTER the pipeline has emitted: a partial
  # claimed_set is still worth returning, but the caller must be told it is
  # partial-BY-FAILURE, not empty. Arm order here is the union order, not a priority.
  if   [[ "$_published_rc" -ne 0 ]]; then return "$_published_rc"
  elif [[ "$_origin_rc"    -ne 0 ]]; then return "$_origin_rc"
  else                                   return "$_deployed_rc"
  fi
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
  #
  # RC-CHECKED, on BOTH surfaces (DT-2; widened to every arm by #4339). A non-zero rc
  # here means SOME arm was never evaluated — an unreadable RELEASE_LOG schema, a
  # failing `gh api`, or a failing `git ls-remote` — so the claimed
  # set is partial BY FAILURE. Branching on `[[ -n "$claimed" ]]` alone made that
  # state indistinguishable from "nothing is DEPLOYED" — a partial set silently
  # certifies a colliding candidate FREE, which is the fail-open shape this whole
  # check exists to close. UNDECIDABLE on the lifecycle surface too (not NA): unlike
  # an offline anchor, an unreadable corpus schema is a repo defect the operator can
  # and must fix, not an environment condition to degrade around.
  local claimed claimed_arr=() _cs_rc=0
  claimed="$(_vf_build_claimed_set "${AUDIT_REPO:-}")" || _cs_rc=$?
  if [[ "$_cs_rc" -ne 0 ]]; then
    printf 'UNDECIDABLE %s claimed-set-partial-by-failure (rc=%s; an arm was not evaluated — unreadable RELEASE_LOG schema, failing gh api, or failing git ls-remote; see stderr) — fail-closed\n' \
      "$candidate" "$_cs_rc"
    return 0
  fi
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
# CUTOVER (mirrors Check 32/47): the full assertion runs only for rows at/after
# $cc_cutoff (CLOSE_COMPLETENESS_CHECK_CUTOFF), which ships as a COMMITTED DEFAULT —
# so the gate is ARMED by default and dormancy is an explicit opt-out (__none__), NOT
# the resting state (#4176). The cutoff VALUE is what prevents a historical
# false-positive storm and honors the reflexive-pipeline-loop exemption (the
# introducing release v2.37 closed under the pre-merge runbook; the cutover is anchored
# strictly AFTER its merge). The network sub-checks (Surface-1 Release + body-drift)
# need `gh`; offline ⇒ N/A on the lifecycle surface, fail-closed on the gate surface
# (the merge gate must not certify completeness blind, per the version-freeness FM-2
# precedent). NOTE: the SEPARATE network cutover CLOSE_COMPLETENESS_RELEASE_CUTOFF
# below is still __none__-defaulted, so those two sub-checks remain dormant — "armed"
# refers to the ROW cutover only.
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
          2) # N/A at tool layer. gh is confirmed up above (the _gh_ok pre-check),
             # so exit 2 here is a git capability absence (origin/main unresolvable
             # / corrupt object), NOT gh. At the "gate" surface an unverifiable
             # canonical must fail-closed (the merge gate cannot certify blind);
             # at "lifecycle" it is a no-finding N/A.
             if [[ "$surface" == "gate" ]]; then
               printf '%s: §5.1 body-drift unverifiable (git/origin-main unreadable at gate surface — fail-closed)\n' "$_ver"
             fi
             ;;
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
  # ARMED BY COMMITTED DEFAULT (#4176). The cutover ships with its value rather than
  # awaiting a later stamping step — the Check 61 convention (see the SELF-ARMING
  # CUTOVER note below): "A version literal would have needed stamping by a later
  # spoke — a step that can be forgotten, leaving the gate permanently dormant."
  # Check 48 is the proof: it shipped at v2.37 expecting a stamp and gated nothing
  # for 62 releases.
  #   Why v3.89: the OLDEST cutoff with zero standing findings, so the gate asserts the
  #   maximum row set against a CLEAN warn-log baseline — the precondition that makes
  #   the ">=3-day review with zero false positives" flip threshold in
  #   .github/close-completeness.enforce evaluable at all. v3.88 arms with a permanent
  #   resident finding, which would make "zero false positives" structurally
  #   unobservable. (Posture is unchanged by arming: warn on both surfaces.)
  #   Arming baseline: cutoff resolves to LOG row `v3.89`, 14 VERIFIED rows in scope,
  #   0 findings. A different in-scope count means a different arm row — the runtime
  #   assertion after the row loop names the row that actually armed.
  # Setting CLOSE_COMPLETENESS_CHECK_CUTOFF=__none__ still re-dormants the gate.
  local cc_cutoff="${CLOSE_COMPLETENESS_CHECK_CUTOFF:-v3.89}"

  # Dormancy is now an EXPLICIT opt-out, not the default: the __none__ sentinel is the
  # escape hatch by which an operator or a CI job can re-dormant the gate (e.g. to honor
  # a reflexive-pipeline-loop exemption), and the cutoff VALUE — not the dormancy — is
  # what keeps the gate from retroactively flagging historical VERIFIED rows.
  if [[ "$cc_cutoff" == "__none__" ]]; then
    printf 'SKIP close-completeness gate re-dormanted explicitly (CLOSE_COMPLETENESS_CHECK_CUTOFF=__none__) — unset it to restore the committed armed default\n'
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

  local cc_past_cutoff=false cc_targets=0 cc_findings=0 cc_detail="" _last_verified="" _cc_arm_row=""
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
      _cc_arm_row="$_ver"          # #4176: record WHICH row armed, for the R8 assertion
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

  # R8 mis-arm assertion (#4176). The cutover arm above is a string PREFIX match, not a
  # version comparison: `v3.9` silently arms at `v3.90` and still verdicts clean, because
  # the shortened prefix lands on a clean sub-range. Name the row that actually armed on
  # every armed run, and WARN when it is not the literal.
  # Non-fatal by design — a mis-typed cutoff is a CONFIG error, not a completeness
  # finding, and must not become an INCOMPLETE verdict under a future enforce posture
  # (that would block a PR on a configuration error rather than a completeness defect).
  # STDERR ONLY: the stdout protocol line (CLEAN/INCOMPLETE/SKIP) is parsed by string
  # surgery at all three call sites (Check 48, the probe, the self-test) — do not touch it.
  if [[ -n "$_cc_arm_row" ]]; then
    if [[ "$_cc_arm_row" != "$cc_cutoff" ]]; then
      printf 'close-completeness: WARNING — cutoff %s armed at LOG row %s (prefix match, not an exact row). Scope is %s VERIFIED row(s); verify this is intended.\n' \
        "$cc_cutoff" "$_cc_arm_row" "$cc_targets" >&2
    else
      printf 'close-completeness: armed at LOG row %s; %s VERIFIED row(s) in scope\n' \
        "$_cc_arm_row" "$cc_targets" >&2
    fi
  else
    # A cutoff matching NO row yields CLEAN 0 — a vacuous pass that READS as success.
    # Anti-vacuity: say so out loud rather than letting zero assertions report OK.
    printf 'close-completeness: WARNING — cutoff %s matched NO LOG row; zero rows asserted (the gate is vacuously clean).\n' \
      "$cc_cutoff" >&2
  fi

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

# ─── Register runner-resolution (Check 62) — #4208 ────────────────────────────────
# Check 62 — register-runner-resolution (advisory; deploy-time-only)
# gate-efficacy: posture=advisory  enforcement-surface=deploy-time-only
#   invariant: every gate-coverage register row declaring a `runner-def:` resolution
#              pointer RESOLVES — the named runner-definition file exists AND still
#              contains the declared anchor (condition R1 of the standard's § Resolution).
#   falsification: delete the `RCP-01` anchor from core/standards/regression-checks.md and
#                  leave the row naming it -> UNRESOLVED (deploy.sh --self-test group RR-2).
#
# WHY THIS EXISTS. The release that introduced the class-3 obligation shipped three
# register rows naming `pmo-skill-editor` Mode C as their runner while Mode C's encoded
# check set carried ZERO of their predicates. The rows satisfied the convention's letter
# and asserted nothing. The remedy attempted at the time was a REVIEWER INSTRUCTION
# ("verify the named runner actually carries the check") and it failed on its own FIRST
# application. This check is that instruction turned into a computation — which is the
# whole difference between an obligation that fires and one that must be remembered.
#
# WHAT IT ASSERTS, AND WHAT IT DOES NOT. It asserts R1 — CARRIED: the named
# runner-definition file exists and contains the declared anchor. It does NOT assert R2
# (reached), does NOT read the anchor's body, and cannot distinguish a well-written
# predicate from a stub carrying the right heading. Naming that bound is the difference
# between a gate and gate theatre — a control that reads as enforcement while functioning
# as a no-op is worse than no control, which is this milestone's whole thesis.
#
# ANTI-VACUITY. A register carrying zero resolution pointers verdicts NOSET, never CLEAN,
# and an unreadable standard verdicts NOSET too: a check whose input set is empty must SAY
# so (the Check 61 DE-9 / Check 13b CP-4 precedent). The CLEAN verdict carries the live
# pointer COUNT, so a parser that silently stopped matching surfaces as a count change
# rather than as a quiet pass.
#
# PARSING. Pointers are read as `runner-def: <path>::<anchor>` with path and anchor
# restricted to a conservative character class, so the standard's own PROSE mentions of
# the bare token (e.g. "declaring a `runner-def:` resolution pointer") cannot parse as
# declarations — a backtick is outside the class, so the match fails rather than
# half-succeeding.
_rr_compute_verdict() {
  local std="${RR_STANDARD:-core/standards/gate-efficacy-standard.md}"
  local root="${RR_ROOT:-.}"

  if [[ ! -f "$std" ]]; then
    printf 'NOSET|gate-efficacy standard not readable at %s — no register to resolve\n' "$std"
    return 0
  fi

  local decls
  decls="$(/usr/bin/grep -o 'runner-def:[[:space:]]*[A-Za-z0-9._/-]\{1,\}::[A-Za-z0-9._-]\{1,\}' "$std" 2>/dev/null || true)"

  if [[ -z "$decls" ]]; then
    printf 'NOSET|register at %s declares zero runner-def resolution pointers — the check would assert nothing\n' "$std"
    return 0
  fi

  local total=0 bad=0 detail=""
  local d body p a
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    total=$((total + 1))
    body="${d#*runner-def:}"
    body="${body#"${body%%[![:space:]]*}"}"   # strip leading whitespace
    p="${body%%::*}"
    a="${body#*::}"
    if [[ ! -f "$root/$p" ]]; then
      bad=$((bad + 1))
      detail="${detail}    runner-def ${p}::${a} — runner-definition file not found"$'\n'
      continue
    fi
    if ! /usr/bin/grep -qF -- "$a" "$root/$p"; then
      bad=$((bad + 1))
      detail="${detail}    runner-def ${p}::${a} — file exists but does NOT carry anchor '${a}' (R1 fails: named runner cannot surface this predicate)"$'\n'
    fi
  done <<< "$decls"

  if [[ $bad -eq 0 ]]; then
    printf 'CLEAN|%s\n' "$total"
  else
    printf '%s' "$detail" | /usr/bin/sed '/^$/d' >&2
    printf 'UNRESOLVED|%s|%s\n' "$bad" "$total"
  fi
  return 0
}

# ─── Decision-emission minimum set (Check 61 / --check-decision-emission) — #4026 ──
# Check 61 — decision-emission-minimum-set (advisory; deploy-time-only)
# gate-efficacy: posture=advisory  enforcement=deploy-time-only  skip-semantics=pre-cutover-is-skip
#   invariant: every VERIFIED RELEASE_LOG row at/after the emission cutover has >=1 event row
#              for each MUST class in the playbook's EMISSION-CONTRACT block, resolved via the
#              schema § 2a release join key.
#   falsification: seed a VERIFIED post-cutover release whose event log carries zero rows for it
#                  -> verdict INCOMPLETE (deploy.sh --self-test assertion group DE).
#
# The shared predicate, factored to TOP LEVEL so it is served by ONE body across two
# surfaces (the DD1 pattern of _vf_/_cc_/_c38_/_c32_compute_verdict): the lifecycle
# Check 61 inside cmd_check (routing the verdict through its own decision-emission.mode
# with a COMMITTED warn default) and the --check-decision-emission probe
# (cmd_check_decision_emission, mapping the verdict to an exit code). No predicate is
# re-encoded on either surface.
#
# WHAT IT ASSERTS, AND WHAT IT DOES NOT. It asserts EXISTENCE: >=1 event row per asserted
# class per in-scope release. It cannot detect a wrong payload, a mis-keyed subject, or an
# event emitted for a decision never actually rendered. Naming that bound is the difference
# between a gate and gate theatre — a control that reads as enforcement while functioning as
# a no-op is worse than no control at all, which is this release's whole thesis.
#
# POSTURE, STATED HONESTLY. advisory / deploy-time-only / warn. There is NO pre-merge
# surface, so a release can close with zero decision events and a green pipeline. The flip
# to `enforce` is an OPERATOR DECISION recorded in gate-efficacy-standard.md's flip ledger —
# NEVER auto-promoted by hit count (progressive-rollout-convention.md, which owns the
# shadow -> warn -> enforce ladder). The `shadow` rung is NOT reachable here:
# resolve_check_mode() accepts enforce|warn|off only, so the gate enters at the lowest
# IMPLEMENTABLE rung and walks warn -> enforce -> removed. Recorded, not silently skipped.
#
# SELF-ARMING CUTOVER. The anchor is a milestone SLUG (DECISION_EMISSION_CUTOVER_SLUG,
# committed default `decision-telemetry-emission`), resolved to a RELEASE_LOG position;
# in-scope releases are the VERIFIED rows STRICTLY AFTER it. A version literal would have
# needed stamping by a later spoke — a step that can be forgotten, leaving the gate
# permanently dormant (the exact vacuity this gate exists to eliminate). The slug is known
# at authoring time, so the gate ships armed and begins asserting at the next release's
# close with no second operator action. At merge it verdicts SKIP (zero in-scope releases),
# and it CANNOT fire on its own introducing release — orchestration-playbook.md § 4a.4
# exempts it, so #4026's release has no emission obligation to assert.

# _de_release_rows <data-rows> <slug>
#   Resolves one release's event rows through the schema § 2a READ ladder:
#     rung 1 — `version` cell == the milestone slug                       [canonical]
#     rung 2 — `subject` == `milestone:#N`, where N is discovered from the rung-1
#              rows' `ms:#N` payload token (the log is self-describing per § 2a;
#              RELEASE_LOG carries the slug, never the number). Rung 2 is therefore
#              reachable only when at least one rung-1 row carries the token —
#              a documented bound, not a silent partial.
#     rung 3 — DELIBERATELY EXCLUDED. A legacy `vX.Y` match can span four releases
#              (measured), and an ambiguous match must never count as satisfying an
#              emission obligation.
#   Echoes the matched rows (possibly empty) on stdout.
_de_release_rows() {
  local _rows="$1" _slug="$2"
  local _r1 _r2="" _msnum
  _r1="$(printf '%s\n' "$_rows" | /usr/bin/awk -F ' \\| ' -v s="$_slug" '$2==s' 2>/dev/null)"
  _msnum="$(printf '%s\n' "$_r1" | /usr/bin/grep -oE 'ms:#[0-9]+' 2>/dev/null | /usr/bin/head -1 | /usr/bin/sed 's/.*ms:#//')"
  if [[ -n "$_msnum" ]]; then
    _r2="$(printf '%s\n' "$_rows" | /usr/bin/awk -F ' \\| ' -v m="milestone:#${_msnum}" '$7==m' 2>/dev/null)"
  fi
  printf '%s\n%s\n' "$_r1" "$_r2" | /usr/bin/sed '/^$/d' | /usr/bin/sort -u
}

# _de_compute_verdict <surface>
#   THE SHARED ORCHESTRATOR. Echoes ONE protocol line on stdout (the CALLER maps it to a
#   warn-emit OR an exit code); per-release detail goes to stderr:
#     SKIP <reason>            dormant / corpus absent / ZERO in-scope releases (the
#                              state at ship) — nothing to assert
#     NOSET <reason>           the asserted-set file is absent or empty. Distinct from
#                              SKIP on purpose: this is a REPO defect (the gate asserts
#                              nothing), not a benign absence, so the caller flags it.
#     CLEAN <n>                n in-scope release(s), every asserted class present
#     INCOMPLETE <f> <n>       f finding(s) across n checked release(s)
#   $1 = surface: accepted for signature parity with the other _cNN_compute_verdict
#   bodies. There is no network anchor here (the whole predicate is corpus + operator-
#   instance file reads), so the verdict is surface-invariant.
#   Fixture overrides mirror the CC_* convention: DE_LOG / DE_RELEASE_LOG / DE_ASSERTED /
#   DECISION_EMISSION_CUTOVER_SLUG. --self-test drives them at a sandbox; the live
#   operator log is NEVER written by this gate (it is read-only).
_de_compute_verdict() {
  local surface="${1:-lifecycle}"   # signature parity; verdict is surface-invariant
  local de_rlog="${DE_RELEASE_LOG:-release/releases/RELEASE_LOG.md}"
  local de_asserted="${DE_ASSERTED:-core/deploy/allowlists/decision-emission-asserted-set.txt}"
  local de_cutover="${DECISION_EMISSION_CUTOVER_SLUG:-decision-telemetry-emission}"
  local de_log="${DE_LOG:-}"
  [[ -n "$de_log" ]] || de_log="$(pmo_evals_results_path)/pipeline-event-log.md"

  # Dormant sentinel — asserted FIRST (the safe default), mirroring _cc_compute_verdict.
  if [[ "$de_cutover" == "__none__" ]]; then
    printf 'SKIP decision-emission gate dormant (DECISION_EMISSION_CUTOVER_SLUG=__none__)\n'
    return 0
  fi

  # Asserted-set absence is a REPO defect, not benign absence: a minimum-emission gate
  # with no asserted set is a control that cannot fail. Reported as its own token so the
  # caller flags it rather than silently reading it as "nothing to check".
  if [[ ! -f "$de_asserted" ]]; then
    printf 'NOSET asserted-set file not found at %s — the gate would assert nothing (repo defect)\n' "$de_asserted"
    return 0
  fi
  local de_classes
  de_classes="$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$de_asserted" 2>/dev/null \
    | /usr/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | /usr/bin/sort -u)"
  if [[ -z "$de_classes" ]]; then
    printf 'NOSET asserted-set file %s declares zero classes — the gate would assert nothing (repo defect)\n' "$de_asserted"
    return 0
  fi

  # Corpus / operator-instance absences are benign SKIPs. The RESOLVED path is printed on
  # every SKIP so a mis-resolution is visible — the Check 19a lesson (a stale literal read
  # as a benign warning for 175 runs).
  if [[ ! -f "$de_rlog" ]]; then
    printf 'SKIP %s not found; cannot enumerate releases\n' "$de_rlog"
    return 0
  fi
  if [[ ! -f "$de_log" ]]; then
    printf 'SKIP no event log at %s (operator-instance state — fresh install / CI; nothing to assert)\n' "$de_log"
    return 0
  fi

  # Event-log data rows only (header + separator excluded). Field map under FS=" | " with
  # the row's leading "| " retained in $1: $2=version $3=stage $4=event_type
  # $5=event_subtype $6=actor $7=subject $8=reversibility $9=outcome $10=payload.
  local de_data
  de_data="$(/usr/bin/grep -E '^\| [0-9]{4}-[0-9]{2}-' "$de_log" 2>/dev/null || true)"

  # RELEASE_LOG rows in file order → "version|milestone|state" (8-col schema:
  # Version(1) Milestone(2) Issues(3) ReleasePR(4) MergeSHA(5) Tag(6) State(7) Date(8)).
  local de_rows
  de_rows=$(/usr/bin/grep -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$de_rlog" 2>/dev/null \
    | /usr/bin/awk -F ' \\| ' '{
        v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v);
        ms=$2; gsub(/`/,"",ms); sub(/^[[:space:]]*/,"",ms); sub(/[[:space:]]*$/,"",ms);
        st=$7; gsub(/`/,"",st); sub(/^[[:space:]]*/,"",st); sub(/[[:space:]]*$/,"",st);
        print v "|" ms "|" st
      }') || de_rows=""

  local de_past=false de_targets=0 de_findings=0 de_detail=""
  local _row _ver _ms _state _rrows _cls _t _s _n
  while IFS= read -r _row; do
    [[ -n "$_row" ]] || continue
    _ver="${_row%%|*}"
    _ms="${_row#*|}"; _ms="${_ms%%|*}"
    _state="${_row##*|}"

    # Cutover: arm ON the anchor row, then `continue` so the anchor itself is EXCLUDED —
    # in scope means STRICTLY AFTER (the introducing release never gates its own close).
    if [[ "$de_past" == "false" ]]; then
      [[ "$_ms" == "$de_cutover" ]] && de_past=true
      continue
    fi

    # VERIFIED-only: a DEPLOYED-not-VERIFIED row is mid-close and emission is not complete
    # until close. Same state scoping as Check 48.
    [[ "$_state" == "VERIFIED" ]] || continue

    # No resolvable Milestone slug ⇒ the § 2a rung-1 key does not exist for this row.
    # Recorded (never silently dropped) and not counted as a target.
    if [[ -z "$_ms" || "$_ms" == "—" || "$_ms" == "-" ]]; then
      printf 'decision-emission: %s SKIPPED — no resolvable Milestone slug in RELEASE_LOG (no § 2a rung-1 key)\n' "$_ver" >&2
      continue
    fi

    de_targets=$((de_targets + 1))
    _rrows="$(_de_release_rows "$de_data" "$_ms")"

    while IFS= read -r _cls; do
      [[ -n "$_cls" ]] || continue
      _t="${_cls%%/*}"; _s="${_cls#*/}"
      _n=$(printf '%s\n' "$_rrows" | /usr/bin/awk -F ' \\| ' -v t="$_t" -v s="$_s" '$4==t && $5==s' 2>/dev/null | /usr/bin/grep -c . || true)
      _n=${_n:-0}
      if [[ "$_n" -eq 0 ]]; then
        de_detail+="${_ver} (${_ms}): no event row for asserted class ${_cls}"$'\n'
        de_findings=$((de_findings + 1))
      fi
    done <<<"$de_classes"
  done <<<"$de_rows"

  if [[ $de_targets -eq 0 ]]; then
    printf 'SKIP no VERIFIED RELEASE_LOG row strictly after the cutover anchor %s — nothing to assert yet (the gate arms at the next post-cutover close)\n' "$de_cutover"
    return 0
  fi
  if [[ $de_findings -eq 0 ]]; then
    printf 'CLEAN %s\n' "$de_targets"
  else
    printf '%s' "$de_detail" | /usr/bin/sed '/^$/d' >&2
    printf 'INCOMPLETE %s %s\n' "$de_findings" "$de_targets"
  fi
  return 0
}

# ─── Hook-registry index freshness (Check 38 / --check-required-subset) — #1485 ──
# The regenerate-and-diff freshness predicate, factored to TOP LEVEL so it is
# shared by two surfaces with ONE body (mirroring the version-freeness DD1 and
# close-completeness DD1 patterns above): the lifecycle Check 38 (inside cmd_check,
# mapping the verdict to a deploy-time always-enforce FAIL) and the
# --check-required-subset runner (cmd_check_required_subset, mapping the verdict to
# an exit code for the CI gate). No predicate is re-encoded on either surface
# (single-engine, CIAC-2).
#
# Check 38 is always-enforce/deterministic — a non-empty regenerate-and-diff is
# unambiguous drift, not a calibration signal. There is no offline/network anchor,
# so the surface argument does not change the verdict; it is accepted for signature
# parity with the other _cNN_compute_verdict bodies (and so the runner can call
# every member the same way). The generator resolves its own sources via
# Path(__file__).parents[3], so an absolute script path works from any cwd.
#
# Echoes ONE protocol line on stdout (the CALLER maps it to a FAIL or an exit
# code); any generator diff detail goes to stderr:
#   FRESH                  committed core/rules/bypass-mode-readiness.md == regenerated
#   STALE                  committed index drifts from its sources (generator rc 1)
#   ERROR <reason>         generator/python3 absent, or generator exit >=2 (fail-closed)
_c38_compute_verdict() {
  local surface="${1:-lifecycle}"   # accepted for signature parity; verdict is surface-invariant
  local gen="${_audit_src_root:-.}/core/deploy/tools/build-hook-registry.py"
  if [[ ! -f "$gen" ]]; then
    printf 'ERROR generator-missing:%s\n' "$gen"
    return 0
  fi
  if [[ ! -x "/usr/bin/python3" ]]; then
    printf 'ERROR python3-not-executable (cannot verify index freshness)\n'
    return 0
  fi
  local out rc=0
  out=$(/usr/bin/python3 "$gen" --check 2>&1) || rc=$?
  case "$rc" in
    0) printf 'FRESH\n' ;;
    1) printf '%s\n' "$out" | /usr/bin/head -20 | /usr/bin/sed 's/^/         /' >&2 || true
       printf 'STALE\n' ;;
    *) printf '%s\n' "$out" | /usr/bin/head -10 | /usr/bin/sed 's/^/         /' >&2 || true
       printf 'ERROR generator-exit-%s (source-resolution failure or error)\n' "$rc" ;;
  esac
}

# ─── Release-corpus completeness (Check 32 / --check-release-corpus) — #1484 ─────
# The LOG-row-driven completeness predicate, factored to TOP LEVEL so it is shared
# by two surfaces with ONE body (DD1, like _vf_/_cc_/_c38_compute_verdict): the
# lifecycle Check 32 (inside cmd_check, routing the verdict through
# flag_warn_or_issue / DEPLOY_CHECK_MODE — deploy-time warn-mode unchanged) and the
# --check-release-corpus probe (cmd_check_release_corpus, mapping the verdict to an
# exit code for the CI gate). No predicate is re-encoded on either surface
# (single-engine, CIAC-2). This is the same LOG-row → INDEX+DIGEST+NOTES resolution
# _cc_compute_verdict delegates to (close-completeness reuses "the SAME path
# resolution Check 32 uses"); factoring it here makes that reuse literal.
#
# For every RELEASE_LOG row at/after $c32_cutoff (default v1.01), asserts the
# matching INDEX row + DIGEST entry + NOTES file; for rows at/after the SEPARATE,
# dormant-by-default (__none__) $c32_release_cutoff, also asserts the LOG Tag column
# + a published GitHub Release. LOG-row-driven (INDEX/DIGEST-only rows not flagged).
# Corpus paths read from C32_* (fixture-overridable). Offline gh at the network
# sub-check ⇒ N/A (no finding) on the "lifecycle" surface, finding/fail-closed on
# the "gate" surface (the merge gate must not certify completeness blind — the
# version-freeness FM-2 precedent).
#
# Echoes ONE protocol line on stdout (the CALLER maps it to a warn-emit OR exit
# code); per-row detail goes to stderr:
#   SKIP <reason>            LOG absent — nothing to enumerate
#   CLEAN <n>                n logged release(s) on/after the cutover are complete
#   INCOMPLETE <f> <n>       f finding(s) across n checked row(s) — detail to stderr
_c32_compute_verdict() {
  local surface="${1:-lifecycle}"
  local c32_log="${C32_LOG:-release/releases/RELEASE_LOG.md}"
  local c32_index="${C32_INDEX:-release/releases/RELEASE_INDEX.md}"
  local c32_digest="${C32_DIGEST:-release/releases/RELEASE_DIGEST.md}"
  local c32_notes_dir="${C32_NOTES_DIR:-release/releases/notes}"
  local c32_allowlist="${C32_ALLOWLIST:-.claude/skip-release-corpus-check.txt}"
  local c32_cutoff="${RELEASE_CORPUS_CHECK_CUTOFF:-v1.01}"
  local c32_release_cutoff="${RELEASE_CORPUS_RELEASE_CUTOFF:-__none__}"

  if [[ ! -f "$c32_log" ]]; then
    printf 'SKIP %s not found; cannot enumerate logged releases\n' "$c32_log"
    return 0
  fi

  # Allowlist filter (exact version match; trailing # comment supported).
  _c32_is_allowlisted() {
    local _v="$1"
    [[ -f "$c32_allowlist" ]] || return 1
    /usr/bin/grep -qE "^[[:space:]]*${_v//./\\.}[[:space:]]*(#.*)?\$" "$c32_allowlist"
  }

  # Enumerate logged releases in LOG file order: emit "version|milestone|tag".
  local c32_rows
  c32_rows=$(/usr/bin/grep -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$c32_log" 2>/dev/null \
    | /usr/bin/awk -F ' \\| ' '{
        v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v);
        ms=$2; sub(/^[[:space:]]*/,"",ms); sub(/[[:space:]]*$/,"",ms);
        tg=$6; gsub(/`/,"",tg); sub(/^[[:space:]]*/,"",tg); sub(/[[:space:]]*$/,"",tg);
        print v "|" ms "|" tg
      }') || c32_rows=""

  local c32_past_cutoff=false c32_past_release_cutoff=false
  local c32_targets=0 c32_findings=0 c32_output=""
  local _row _ver _ms _tag _notes_ok _release_eligible
  while IFS= read -r _row; do
    [[ -n "$_row" ]] || continue
    _ver="${_row%%|*}"
    _ms="${_row#*|}"; _ms="${_ms%%|*}"
    _tag="${_row##*|}"

    if [[ "$c32_past_cutoff" == "false" && "$_ver" == "$c32_cutoff"* ]]; then
      c32_past_cutoff=true
    fi
    [[ "$c32_past_cutoff" == "true" ]] || continue
    _c32_is_allowlisted "$_ver" && continue
    c32_targets=$((c32_targets + 1))

    # (a) INDEX row present (version is the first table cell)
    if ! /usr/bin/grep -qE "^\|[[:space:]]*${_ver//./\\.}[[:space:]]*\|" "$c32_index" 2>/dev/null; then
      c32_output+="${_ver}: missing RELEASE_INDEX.md row"$'\n'
      c32_findings=$((c32_findings + 1))
    fi
    # (b) DIGEST entry present (### vX.YZ H3 heading)
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

    # Stricter post-Release-cutover assertions (tag + published Release). Dormant
    # when c32_release_cutoff is the __none__ sentinel.
    _release_eligible=0
    if [[ "$c32_release_cutoff" != "__none__" ]]; then
      if [[ "$c32_past_release_cutoff" == "false" && "$_ver" == "$c32_release_cutoff"* ]]; then
        c32_past_release_cutoff=true
      fi
      [[ "$c32_past_release_cutoff" == "true" ]] && _release_eligible=1
    fi
    if [[ $_release_eligible -eq 1 ]]; then
      # (d) signed-tag presence — read from the LOG Tag column (in-corpus; no network).
      if [[ -z "$_tag" || "$_tag" == "—" || "$_tag" == "-" ]]; then
        c32_output+="${_ver}: post-Release-cutover row has no tag recorded in RELEASE_LOG Tag column"$'\n'
        c32_findings=$((c32_findings + 1))
      fi
      # (e) published GitHub Release — network-dependent. gh authed + missing ⇒
      # finding; gh offline/unauth ⇒ N/A (no finding) on lifecycle, finding
      # (fail-closed) on the gate surface.
      if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        if ! gh release view "$_ver" >/dev/null 2>&1; then
          c32_output+="${_ver}: post-Release-cutover row has no published GitHub Release (gh release view returned non-zero)"$'\n'
          c32_findings=$((c32_findings + 1))
        fi
      elif [[ "$surface" == "gate" ]]; then
        c32_output+="${_ver}: post-Release-cutover published-Release unverifiable (gh offline/unauth at gate surface — fail-closed)"$'\n'
        c32_findings=$((c32_findings + 1))
      else
        printf 'release-corpus: %s published-Release sub-check N/A (gh offline/unauth) — reuses pre-Release SKIP semantics\n' "$_ver" >&2
      fi
    fi
  done <<<"$c32_rows"

  if [[ $c32_findings -eq 0 ]]; then
    printf 'CLEAN %s\n' "$c32_targets"
  else
    printf '%s' "$c32_output" | /usr/bin/sed '/^$/d' >&2
    printf 'INCOMPLETE %s %s\n' "$c32_findings" "$c32_targets"
  fi
  return 0
}

# ─── Skill package content-freshness (Check 7 / --check-package-freshness) — #2656 ──
# The content-manifest freshness predicate, factored to TOP LEVEL so it is shared by
# two surfaces with ONE body (DD1, like _vf_/_cc_/_c38_/_c32_compute_verdict): the
# lifecycle Check 7 (inside cmd_check, always-enforce → ++ISSUES per stale skill) and
# the --check-package-freshness probe (cmd_check_package_freshness, mapping the verdict
# to an exit code for the CI gate). No predicate is re-encoded on either surface
# (single-engine, CIAC-2).
#
# ASSERT-BY-CONTENT, NOT BY PROXY (gate-efficacy Req (a)): the verdict rests on the
# rebuild-stable content-manifest hash of a STAGED REBUILD of source vs the committed
# baseline sidecar (packages/<skill>.skill.sha256) — mtime-independent, so a
# committed-stale package is caught even on a fresh checkout. mtime is a cheap
# non-verdict pre-filter only. python3/unzip absent → degrades to the
# baseline-vs-live-package content compare + the mtime signal (logged), matching the
# graceful-skip posture of the deploy-time Check 7.
#
# Check 7 has no network anchor, so the surface argument does not change the verdict;
# it is accepted for signature parity with the other _cNN_compute_verdict bodies.
#
# Echoes ONE protocol line on stdout (the CALLER maps it to ++ISSUES or an exit code);
# per-skill detail goes to stderr:
#   FRESH <n>                all n rostered skill package(s) content-fresh
#   STALE <count> <csv>      count stale skill(s), comma-separated — detail to stderr
_c7_compute_verdict() {
  local surface="${1:-lifecycle}"   # accepted for signature parity; verdict is surface-invariant
  local c7_can_rebuild=true
  [[ -x "/usr/bin/python3" ]] || c7_can_rebuild=false
  command -v unzip >/dev/null 2>&1 || c7_can_rebuild=false

  local c7_total=0 c7_stale=0 c7_stale_list=""
  local skill c7_module c7_src_dir c7_pkg c7_sidecar c7_live_hash c7_baseline
  local c7_newest_src c7_pkg_mtime c7_src_newer
  local c7_tmp_pkgdir c7_rebuilt_pkg c7_rebuilt_hash
  for skill in "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" "${CORE_SKILLS[@]}"; do
    c7_total=$((c7_total + 1))
    c7_module=$(resolve_skill_module "$skill")
    c7_src_dir="$c7_module/skills/$skill"
    c7_pkg="packages/${skill}.skill"
    c7_sidecar="packages/${skill}.skill.sha256"

    if [[ ! -f "$c7_pkg" ]]; then
      printf '  FAIL:  %s — .skill package missing\n' "$skill" >&2
      c7_stale=$((c7_stale + 1)); c7_stale_list+="${skill},"; continue
    fi
    c7_live_hash=$(skill_content_hash "$c7_pkg")
    if [[ -z "$c7_live_hash" ]]; then
      printf '  FAIL:  %s — could not compute package content hash (corrupt archive or missing unzip/shasum)\n' "$skill" >&2
      c7_stale=$((c7_stale + 1)); c7_stale_list+="${skill},"; continue
    fi
    if [[ ! -f "$c7_sidecar" ]]; then
      printf '  FAIL:  %s — content baseline sidecar missing (%s); rebuild via core/deploy/tools/build-skill-packages.sh %s\n' "$skill" "$c7_sidecar" "$skill" >&2
      c7_stale=$((c7_stale + 1)); c7_stale_list+="${skill},"; continue
    fi
    c7_baseline=$(tr -d '[:space:]' < "$c7_sidecar" 2>/dev/null)
    if [[ "$c7_live_hash" != "$c7_baseline" ]]; then
      printf '  FAIL:  %s — package content hash (%s) != committed baseline (%s); package tampered or sidecar stale — rebuild via core/deploy/tools/build-skill-packages.sh %s\n' "$skill" "$c7_live_hash" "$c7_baseline" "$skill" >&2
      c7_stale=$((c7_stale + 1)); c7_stale_list+="${skill},"; continue
    fi

    # mtime PRE-FILTER (cheap, non-verdict source-change signal).
    c7_src_newer=false
    c7_newest_src=$(find "$c7_src_dir" -type f -not -path '*/.*' -exec stat -f '%m' {} \; 2>/dev/null | sort -n | tail -1)
    c7_pkg_mtime=$(stat -f '%m' "$c7_pkg" 2>/dev/null)
    if [[ -n "$c7_newest_src" && -n "$c7_pkg_mtime" && "$c7_newest_src" -gt "$c7_pkg_mtime" ]]; then
      c7_src_newer=true
    fi

    # CONTENT VERDICT: stage a rebuild of source and compare its content hash to the
    # committed baseline (mtime-independent — catches a committed-stale package on a
    # fresh checkout). Run whenever a rebuild is available; the result decides.
    if [[ "$c7_can_rebuild" == "true" ]]; then
      c7_tmp_pkgdir="$(mktemp -d)"
      if build_skill_to_dir "$skill" "$c7_module" "$c7_tmp_pkgdir" >/dev/null 2>&1; then
        c7_rebuilt_pkg="$c7_tmp_pkgdir/${skill}.skill"
        c7_rebuilt_hash=$(skill_content_hash "$c7_rebuilt_pkg")
        if [[ -z "$c7_rebuilt_hash" ]]; then
          printf '  WARN:  %s — rebuild produced no hashable package; baseline matched (PASS, staged-rebuild inconclusive)\n' "$skill" >&2
        elif [[ "$c7_rebuilt_hash" != "$c7_baseline" ]]; then
          printf '  FAIL:  %s — source content changed since build (rebuilt hash %s != committed baseline %s); rebuild via core/deploy/tools/build-skill-packages.sh %s\n' "$skill" "$c7_rebuilt_hash" "$c7_baseline" "$skill" >&2
          c7_stale=$((c7_stale + 1)); c7_stale_list+="${skill},"
        fi
      else
        printf '  WARN:  %s — staged rebuild failed to run; falling back to baseline-vs-package content compare\n' "$skill" >&2
        if [[ "$c7_src_newer" == "true" ]]; then
          printf '  FAIL:  %s — source mtime newer than package and rebuild unavailable to confirm content; rebuild via core/deploy/tools/build-skill-packages.sh %s\n' "$skill" "$skill" >&2
          c7_stale=$((c7_stale + 1)); c7_stale_list+="${skill},"
        fi
      fi
      rm -rf "$c7_tmp_pkgdir"
    else
      # Degraded: no rebuild available; the baseline-vs-live-package compare already
      # passed, so the mtime pre-filter is the only remaining source-change signal.
      if [[ "$c7_src_newer" == "true" ]]; then
        printf '  FAIL:  %s — source mtime newer than package; python3/unzip unavailable to confirm by content — rebuild via core/deploy/tools/build-skill-packages.sh %s\n' "$skill" "$skill" >&2
        c7_stale=$((c7_stale + 1)); c7_stale_list+="${skill},"
      fi
    fi
  done

  if [[ $c7_stale -eq 0 ]]; then
    printf 'FRESH %s\n' "$c7_total"
  else
    printf 'STALE %s %s\n' "$c7_stale" "${c7_stale_list%,}"
  fi
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

# ─── Complementary-pair ownership (Check 13b passes 2/3/4) — #4178 ───────────
# The registered-complementary-pair predicate, factored to TOP LEVEL so the
# lifecycle Check 13b (inside cmd_check, routing each finding through
# flag_warn_or_issue) and `--self-test` group CP drive ONE body (the DD1 pattern
# of _vf_/_cc_/_de_/_c32_/_c7_compute_verdict). No predicate is re-encoded on
# either surface.
#
# The registry it reads is core/deploy/allowlists/complementary-reference-pairs.txt,
# whose header carries the record schema and the asserted predicates. It is read
# DIRECTLY here and DIRECTLY by core/deploy/tools/build-skill-packages.sh — never
# awk-extracted out of this script, which is the drift class recorded in
# core/deploy/lib-template-sync-source.sh.
#
# THREE PASSES, one body:
#   pass 2  ownership — P1/P2/P3/P4 per record (exclusive sections present in
#           their owner and ABSENT from the peer; shared sections present in
#           BOTH), plus P5, the shared-section CONTENT comparison. P1-P4 breaches
#           are ownership drift (a declaration the files contradict); a P5 breach
#           is content divergence inside a correct declaration. They are
#           deliberately distinct signals, not one blended verdict.
#   pass 3  discovery — a same-basename file present BOTH under a skill
#           references/ tree AND in core|release|operations outside */skills/*,
#           with no registry record, is a possible ACCIDENTAL fork. This is what
#           makes a deliberate split and an accidental fork distinguishable.
#   pass 4  packaging — for each record, if the owning skill's SKILL.md cites the
#           canonical path, that path must resolve from the built package root
#           and from the deployed skill root. This is the assertion whose absence
#           IS the shipped-package defect.
#
# FAIL-CLOSED ON ABSENCE. A missing or unreadable registry verdicts NOSET, never
# a silent pass (the Check 61 DE-9 precedent) — and the packager mirrors that
# posture, so one deleted file cannot disable the fix and its detector together.
#
# CIAC-3: every predicate reads a file directly (`grep -qxF … "$file"`) or uses a
# here-string (`awk … <<< "$rec"`). No writer is piped into a quiet grep.
#
# Env overrides (the self-test seam; committed defaults are the live paths):
#   CP_PAIRS_FILE   registry path
#   CP_ROOT         directory the relative paths resolve against
#   CP_PACKAGES     built-package directory
#   CP_USER_SKILLS  deployed skill root
#
# Echoes ONE LINE PER FINDING on stdout, each `<TOKEN>|<detail>`, in a
# deterministic token order so the first line is a stable assertion target:
#   NOSET|<path>                    registry absent/unreadable  (terminal, alone)
#   MALFORMED|<detail>              a record without exactly 5 '|||' fields
#   OWNERSHIP-DRIFT|<detail>        P1/P2/P3/P4 breach
#   SHARED-DIVERGENCE|<detail>      P5 breach (ownership correct, content drifted)
#   UNREGISTERED-PAIR|<detail>      pass-3 discovery
#   CITATION-UNRESOLVABLE|<detail>  pass-4 breach
#   PASS|<n>                        zero findings across n record(s)
#
# Index-convention exclusion for pass 3 — NAMED, never a silent skip. README.md
# is a per-directory index carried by dozens of directories by convention; it is
# not a canonical/skill-local pair and would flood the pass.
C13B_INDEX_BASENAMES=(README.md)

_cp_compute_verdict() {
  (
    cd "${CP_ROOT:-.}" 2>/dev/null || { echo "NOSET|CP_ROOT unreadable: ${CP_ROOT:-.}"; exit 0; }

    _cp_reg="${CP_PAIRS_FILE:-core/deploy/allowlists/complementary-reference-pairs.txt}"
    if [[ ! -r "$_cp_reg" ]]; then
      echo "NOSET|complementary-pair registry absent or unreadable: $_cp_reg"
      exit 0
    fi

    # Record set: comment + blank lines are tolerated (both consumers agree).
    _cp_records="$(grep -v '^[[:space:]]*#' "$_cp_reg" 2>/dev/null | grep -v '^[[:space:]]*$' || true)"

    _cp_malformed=""
    _cp_ownership=""
    _cp_divergence=""
    _cp_citation=""
    _cp_count=0
    # Registered (canonical, skill-local) path pairs, newline-delimited, for pass 3.
    _cp_registered=""

    while IFS= read -r _cp_rec; do
      [[ -z "$_cp_rec" ]] && continue
      _cp_count=$((_cp_count + 1))

      _cp_nf="$(awk -F'\\|\\|\\|' '{print NF}' <<< "$_cp_rec")"
      if [[ "$_cp_nf" != "5" ]]; then
        _cp_malformed="${_cp_malformed}MALFORMED|record ${_cp_count} has ${_cp_nf} '|||'-delimited field(s), expected 5 (canonical|||skill-local|||canonical-owned|||skill-local-owned|||shared) — see the registry header
"
        continue
      fi

      _cp_canon="$(awk -F'\\|\\|\\|' '{print $1}' <<< "$_cp_rec")"
      _cp_mirror="$(awk -F'\\|\\|\\|' '{print $2}' <<< "$_cp_rec")"
      _cp_own_c="$(awk -F'\\|\\|\\|' '{print $3}' <<< "$_cp_rec")"
      _cp_own_m="$(awk -F'\\|\\|\\|' '{print $4}' <<< "$_cp_rec")"
      _cp_shared="$(awk -F'\\|\\|\\|' '{print $5}' <<< "$_cp_rec")"
      _cp_registered="${_cp_registered}${_cp_canon}|${_cp_mirror}
"

      # ── P3: both halves exist ────────────────────────────────────────────────
      if [[ ! -f "$_cp_canon" || ! -f "$_cp_mirror" ]]; then
        _cp_ownership="${_cp_ownership}OWNERSHIP-DRIFT|registered pair is not resolvable on disk: canonical '$_cp_canon' $([[ -f "$_cp_canon" ]] && echo present || echo MISSING), skill-local '$_cp_mirror' $([[ -f "$_cp_mirror" ]] && echo present || echo MISSING)
"
        continue
      fi

      # ── P1: canonical-owned sections — in the canonical, ABSENT from the mirror ─
      IFS='|' read -r -a _cp_secs <<< "$_cp_own_c"
      for _cp_s in "${_cp_secs[@]}"; do
        [[ -z "$_cp_s" ]] && continue
        if ! grep -qxF "## $_cp_s" "$_cp_canon"; then
          _cp_ownership="${_cp_ownership}OWNERSHIP-DRIFT|'## $_cp_s' is declared canonical-owned but is NOT an H2 in $_cp_canon
"
        fi
        if grep -qxF "## $_cp_s" "$_cp_mirror"; then
          _cp_ownership="${_cp_ownership}OWNERSHIP-DRIFT|'## $_cp_s' is declared canonical-owned but ALSO appears in $_cp_mirror — the section moved or was copied across the pair without updating $_cp_reg
"
        fi
      done

      # ── P2: skill-local-owned sections — in the mirror, ABSENT from the canonical ─
      IFS='|' read -r -a _cp_secs <<< "$_cp_own_m"
      for _cp_s in "${_cp_secs[@]}"; do
        [[ -z "$_cp_s" ]] && continue
        if ! grep -qxF "## $_cp_s" "$_cp_mirror"; then
          _cp_ownership="${_cp_ownership}OWNERSHIP-DRIFT|'## $_cp_s' is declared skill-local-owned but is NOT an H2 in $_cp_mirror
"
        fi
        if grep -qxF "## $_cp_s" "$_cp_canon"; then
          _cp_ownership="${_cp_ownership}OWNERSHIP-DRIFT|'## $_cp_s' is declared skill-local-owned but ALSO appears in $_cp_canon — the section moved or was copied across the pair without updating $_cp_reg
"
        fi
      done

      # ── P4 + P5: shared sections — in BOTH, and their blocks compared ─────────
      IFS='|' read -r -a _cp_secs <<< "$_cp_shared"
      for _cp_s in "${_cp_secs[@]}"; do
        [[ -z "$_cp_s" ]] && continue
        _cp_in_c=false; _cp_in_m=false
        grep -qxF "## $_cp_s" "$_cp_canon" && _cp_in_c=true
        grep -qxF "## $_cp_s" "$_cp_mirror" && _cp_in_m=true
        if [[ "$_cp_in_c" != "true" || "$_cp_in_m" != "true" ]]; then
          _cp_ownership="${_cp_ownership}OWNERSHIP-DRIFT|'## $_cp_s' is declared SHARED but is missing from $([[ "$_cp_in_c" == "true" ]] || printf '%s ' "$_cp_canon")$([[ "$_cp_in_m" == "true" ]] || printf '%s' "$_cp_mirror")
"
          continue
        fi
        # P5 — the content comparison. Block = lines from "## <section>" to the
        # next "## " (or EOF), the same extractor Check 34 uses.
        if ! diff -q \
             <(awk -v anchor="## $_cp_s" '$0 == anchor {g=1; next} g && /^## / {exit} g {print}' "$_cp_canon") \
             <(awk -v anchor="## $_cp_s" '$0 == anchor {g=1; next} g && /^## / {exit} g {print}' "$_cp_mirror") \
             >/dev/null 2>&1; then
          _cp_divergence="${_cp_divergence}SHARED-DIVERGENCE|'## $_cp_s' is declared SHARED by $_cp_reg but its content differs between $_cp_canon and $_cp_mirror — reconcile the two, or move the section into an exclusive-ownership field if the difference is deliberate
"
        fi
      done

      # ── pass 4: the canonical resolves where the SKILL.md cites it ───────────
      # Owning skill = the path segment after 'skills/' in the skill-local path.
      _cp_skill="${_cp_mirror#*/skills/}"; _cp_skill="${_cp_skill%%/*}"
      _cp_skillmd="${_cp_mirror%%/skills/*}/skills/${_cp_skill}/SKILL.md"
      if [[ -n "$_cp_skill" && -f "$_cp_skillmd" ]] && grep -qF "$_cp_canon" "$_cp_skillmd"; then
        # Built package: the archive root is the skill dir, so the cited
        # repo-relative path must appear as <skill>/<canonical-path>.
        _cp_pkg="${CP_PACKAGES:-packages}/${_cp_skill}.skill"
        if [[ -f "$_cp_pkg" ]]; then
          # Listing captured to a variable, then matched with a HERE-STRING —
          # never `unzip … | grep -q`, whose early exit SIGPIPEs the writer under
          # `set -o pipefail` (the #3833 EPIPE class).
          _cp_pkglist="$(unzip -l "$_cp_pkg" 2>/dev/null || true)"
          if ! grep -qF " ${_cp_skill}/${_cp_canon}" <<< "$_cp_pkglist"; then
            _cp_citation="${_cp_citation}CITATION-UNRESOLVABLE|${_cp_skill}/SKILL.md cites '$_cp_canon' but $_cp_pkg does not carry it — a deployed $_cp_skill cannot resolve that citation
"
          fi
        fi
        # Deployed skill root.
        _cp_deployed="${CP_USER_SKILLS:-${USER_LOCAL_SKILLS_PATH:-}}"
        if [[ -n "$_cp_deployed" && -d "$_cp_deployed/$_cp_skill" && ! -f "$_cp_deployed/$_cp_skill/$_cp_canon" ]]; then
          _cp_citation="${_cp_citation}CITATION-UNRESOLVABLE|${_cp_skill}/SKILL.md cites '$_cp_canon' but it is absent from the deployed skill root $_cp_deployed/$_cp_skill — run ./deploy.sh --deploy $_cp_skill
"
        fi
      fi
    done <<< "$_cp_records"

    # ── pass 3: unregistered canonical<->skill-local discovery ────────────────
    # Intersect the skill-references basename set with the canonical-tree basename
    # set (two finds, not one per basename), then subtract the named index
    # convention and every registered pair.
    _cp_unregistered=""
    if [[ -d core || -d release || -d operations ]]; then
      _cp_skill_names="$(find core release operations -path '*/skills/*/references/*' -type f -name '*.md' 2>/dev/null | sed 's|.*/||' | sort -u || true)"
      _cp_canon_names="$(find core release operations -type f -name '*.md' -not -path '*/skills/*' -not -path 'release/releases/*' 2>/dev/null | sed 's|.*/||' | sort -u || true)"
      _cp_both="$(comm -12 <(printf '%s\n' "$_cp_canon_names") <(printf '%s\n' "$_cp_skill_names") 2>/dev/null || true)"
      while IFS= read -r _cp_b; do
        [[ -z "$_cp_b" ]] && continue
        _cp_skip=false
        for _cp_idx in "${C13B_INDEX_BASENAMES[@]}"; do
          [[ "$_cp_b" == "$_cp_idx" ]] && _cp_skip=true
        done
        [[ "$_cp_skip" == "true" ]] && continue
        while IFS= read -r _cp_cp; do
          [[ -z "$_cp_cp" ]] && continue
          while IFS= read -r _cp_mp; do
            [[ -z "$_cp_mp" ]] && continue
            if ! grep -qxF "${_cp_cp}|${_cp_mp}" <<< "$_cp_registered"; then
              _cp_unregistered="${_cp_unregistered}UNREGISTERED-PAIR|'$_cp_cp' and '$_cp_mp' share a basename across the canonical corpus and a skill references/ tree but are NOT registered in $_cp_reg — register them as complementary (declaring what each owns) or consolidate them; an unregistered same-basename pair is indistinguishable from an accidental fork
"
            fi
          done <<< "$(find core release operations -path '*/skills/*/references/*' -type f -name "$_cp_b" 2>/dev/null | sort || true)"
        done <<< "$(find core release operations -type f -name "$_cp_b" -not -path '*/skills/*' -not -path 'release/releases/*' 2>/dev/null | sort || true)"
      done <<< "$_cp_both"
    fi

    _cp_all="${_cp_malformed}${_cp_ownership}${_cp_divergence}${_cp_unregistered}${_cp_citation}"
    if [[ -z "$_cp_all" ]]; then
      echo "PASS|${_cp_count} registered complementary pair(s), ownership and packaging intact"
    else
      printf '%s' "$_cp_all"
    fi
  )
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
  # Emit (one per line, de-duplicated) the diff --exclude tokens for $1's
  # TEMPLATE_SYNC_MAP targets — the runtime references/ entries injected by
  # sync_canonical_templates_to_runtime() that do NOT exist in the source tree by
  # single-source-of-truth design. Check 1's source-vs-installed diff EXCLUDES
  # these so the injected copies do not read as "Only in installed" drift; their
  # byte-identity-vs-canonical is Check 13's job. Reuses the same entry parse as
  # sync_canonical_templates_to_runtime (:407-411).
  #
  # For each target the FIRST path segment under references/ is emitted — exactly
  # the token `diff -rq --exclude=` needs (it matches whole path components):
  #   - top-level  references/<file>          -> "<file>"    (excludes that file)
  #   - nested     references/<subdir>/<file>  -> "<subdir>"  (excludes the whole
  #     injected subdir, e.g. project-initiator's references/templates/). Excluding
  #     only the leaf basenames would still leave the injected SUBDIR reported as
  #     "Only in installed" -> the false reference-drift this case otherwise
  #     produces; the subdir token is what suppresses it. A skill's injected subdir
  #     is runtime-only
  #     (single-source design — project-initiator carries no source
  #     references/templates/), so excluding it masks no genuine source reference;
  #     Check 13 still verifies each nested injected file byte-identical against its
  #     canonical, at the full references/<subdir>/<file> target path.
  local skill="$1"
  local entry e_skill rest target_rel sub
  {
    for entry in "${TEMPLATE_SYNC_MAP[@]}"; do
      e_skill="${entry%%:*}"
      [[ "$e_skill" == "$skill" ]] || continue
      rest="${entry#*:}"
      target_rel="${rest#*:}"
      case "$target_rel" in
        references/*)
          sub="${target_rel#references/}"   # "<file>" or "<subdir>/<file>"
          printf '%s\n' "${sub%%/*}"         # first path segment under references/
          ;;
      esac
    done
  } | sort -u
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

# resolve_template_sync_source() is single-sourced in
# core/deploy/lib-template-sync-source.sh (sourced near the top of this script,
# beside lib-instance-path.sh) — #2158. Do not re-inline the resolver here; add a
# new shared-standards basename to arm 1 of that fragment instead.

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

deployed_skill_footprint() {
  # Content manifest ("<sha256>  <abs-path>" lines, LC_ALL=C-sorted) of a skill's
  # DEPLOYED footprint across both possible targets: the unconditional user-local
  # mirror ($USER_LOCAL_SKILLS_PATH/<skill>) and — when a Cowork session resolved
  # — the session copy ($INSTALL_PATH/<skill>). Empty when nothing is deployed
  # yet. Hashes CONTENT, not mtime, so a byte-identical re-copy yields an
  # identical manifest.
  #
  # WHY (idempotency; #384 v3.91 regression fix): detect_changed_skills is a
  # STATELESS git tag-diff (last-tag..HEAD), so on a release branch (pre-tag) it
  # re-lists EVERY skill whose source changed since the last tag on EVERY run —
  # including a genuine no-op re-run where the deployed mirror is already current.
  # Reporting that raw list verbatim as "Deployed: N skills" made update.sh flip
  # EX_NOCHANGE(64) → EX_OK(0) on a no-op (redeploy_skills keys off the skills
  # field), breaking the #613/#331 contract that a second update.sh reports
  # "nothing to do". cmd_deploy compares this footprint before/after each skill's
  # deploy and counts only skills whose on-disk content ACTUALLY changed — the
  # same actually-changed-not-re-copied principle update.sh Phase 5c already
  # applies to hooks ("REFRESHED:" vs re-copied-every-run "INSTALLED:").
  local skill="$1" root
  local -a roots=("$USER_LOCAL_SKILLS_PATH/$skill")
  if [[ "${COWORK_AVAILABLE:-false}" == "true" && -n "${INSTALL_PATH:-}" ]]; then
    roots+=("$INSTALL_PATH/$skill")
  fi
  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    find "$root" -type f -exec shasum -a 256 {} + 2>/dev/null
  done | LC_ALL=C sort
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

  # Deploy skills (source module resolved per skill via resolve_skill_module).
  # skills_changed counts skills whose DEPLOYED content actually changed on disk
  # (see deployed_skill_footprint) — the honest "Deployed: N skills" the summary
  # reports, so a no-op re-run of a stateless-tag-diff-listed skill does not
  # falsely flip update.sh off EX_NOCHANGE (#384 v3.91 regression fix).
  local skills_changed=0
  for skill in ${CHANGED_SKILLS[@]+"${CHANGED_SKILLS[@]}"}; do
    local module __before_fp __after_fp
    __before_fp=$(deployed_skill_footprint "$skill")
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

    # Idempotency accounting: count this skill only if its deployed footprint
    # actually changed (a fresh/updated deploy), not when a stateless-tag-diff
    # re-mirror re-copied byte-identical content (a no-op re-run). See
    # deployed_skill_footprint for the #613/#331 EX_NOCHANGE rationale.
    __after_fp=$(deployed_skill_footprint "$skill")
    if [[ "$__before_fp" != "$__after_fp" ]]; then
      skills_changed=$((skills_changed + 1))
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

  # Summary. The skills field is skills_changed (actually-changed on disk), NOT
  # ${#CHANGED_SKILLS[@]} (the stateless git tag-diff list) — update.sh keys off
  # this field for the EX_NOCHANGE contract, so a no-op re-run that re-mirrors an
  # already-current skill must report 0 skills, not 1 (#384 v3.91 regression fix).
  local pkg_count=${#CHANGED_PACKAGES[@]:-0}
  local harness_count=${#CHANGED_HARNESS[@]:-0}
  log "Deployed: ${skills_changed} skills, $pkg_count packages, $harness_count harness artifacts"
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
Live check sequence: 1-14, 16-23, 25-53   (gaps: 15, 24 — both reserved)
Next NEW top-level check number: 54
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
      # sibling role skills, not a deployable skill (no SKILL.md the deployer
      # ships, no package, no deploy.sh array entry). It carries no roster
      # membership and must be skipped before the roster lookup. EXACT-MATCH
      # allowlist (fail-CLOSED): only the two explicitly-named dirs below are
      # exempt — a stray underscore-prefixed directory still FAILs roster-drift.
      #   "_shared"    — shared reference content consumed by sibling role skills.
      #   "_templates" — parameterized, NON-DEPLOYED skill templates (e.g.
      #                  system-specialist/): each holds a placeholder-bearing
      #                  SKILL.md that is instantiated per system into a real,
      #                  roster+registry-registered skill. The template itself is
      #                  never deployed (never added to a roster array, no package,
      #                  no registry CI row), so it must be exempt from roster-drift
      #                  exactly like _shared. An INSTANCE is a normal roster member.
      # To add another non-skill shared-resource dir, extend this allowlist
      # explicitly here.
      [[ "$skill_name" == "_shared" || "$skill_name" == "_templates" ]] && continue
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
  #              frontmatter fields present AND the version: value matching the
  #              canonical format regex ^v[0-9]+\.[0-9]+(-[a-z]+)?$ per
  #              core/standards/version-field-semantics.md § Format; references/
  #              subdir present once the D-Refs threshold is crossed; ≥3
  #              domain-specific failure modes).
  #   falsification: remove a required frontmatter field, malform a version: value
  #                  (3.99 / latest / v3.9.9.9 / empty-after-the-colon), or drop a
  #                  skill below the 3-failure-mode floor -> this check FAILS for
  #                  that skill.
  #
  # SINGLE SOURCE (per gate-efficacy-standard.md Req (b′) + the #1101 "assert
  # content, not a re-implemented proxy" doctrine): the predicate — required
  # frontmatter fields (name/description/version) and the version-field format
  # regex, the D-Refs threshold (>400 lines OR >25600 bytes -> references/
  # required), and the failure-mode floor
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
  # Verdict computed by the shared _c7_compute_verdict body (DD1) so the CI probe
  # (--check-package-freshness) and this lifecycle check cannot diverge. The body
  # emits per-skill detail to stderr; this block maps the verdict to the deploy-time
  # emit. Always-enforce: each stale skill increments ISSUES (byte-identical accounting).
  local c7_verdict c7_tok c7_rest c7_count
  c7_verdict="$(_c7_compute_verdict "lifecycle")"
  c7_tok="${c7_verdict%% *}"
  case "$c7_tok" in
    FRESH)
      log "  OK:    all ${c7_verdict#FRESH } rostered skill package(s) content-fresh"
      ;;
    STALE)
      # "STALE <count> <csv>" — per-skill detail already on stderr.
      c7_rest="${c7_verdict#STALE }"
      c7_count="${c7_rest%% *}"
      log "  FAIL:  ${c7_count} stale skill package(s): ${c7_rest#* } — rebuild via core/deploy/tools/build-skill-packages.sh (per-skill detail above)"
      ISSUES=$((ISSUES + c7_count))
      ;;
    *)
      log "  FAIL:  Check 7 — unexpected verdict: $c7_verdict"
      ISSUES=$((ISSUES + 1))
      ;;
  esac

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

  # flag_advisory_only — the ADVISORY class emitter: a standing drift SIGNAL that is
  # STRUCTURALLY INCAPABLE of enforcement. Note what is absent: there is no `case` on
  # any mode, no enforce branch, and no ISSUES increment anywhere in the body. That is
  # the whole point — the constraint is expressed in the code's shape, not in a default
  # value some future edit could flip. It is deliberately NOT flag_warn_or_issue: that
  # helper escalates to FAIL the moment the shared cohort graduates to enforce, which
  # for this class would be a defect.
  #
  # WHEN A CHECK BELONGS TO THIS CLASS: its predicate cannot distinguish a violation
  # from a correct record. Check 58 (ADR ratification-flip) is the founding member —
  # it can see that an ADR promises a flip while still Proposed, but the ratifying
  # reference is free text, so it cannot see whether that review has CLOSED. A
  # genuinely-pending ADR is correct and reports on every run; failing on it would
  # punish correctness. Enforcement for that invariant lives at the release-close gate
  # (G-CL9), which has the release context this surface structurally lacks.
  #
  # Consequence for callers: an advisory finding NEVER contributes to the exit code.
  # Rows are logged to the same warn jsonl so the signal is reviewable over time.
  flag_advisory_only() {
    local check_id="$1"
    local detail="$2"
    log "  ADVISORY: $check_id — $detail (advisory-only; this check is never enforce-capable — see G-CL9 for the authoritative gate)"
    local _ts
    _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local _detail_escaped="${detail//\\/\\\\}"
    _detail_escaped="${_detail_escaped//\"/\\\"}"
    printf '{"ts":"%s","check":"%s","advisory":true,"detail":"%s"}\n' "$_ts" "$check_id" "$_detail_escaped" >> "$WARN_LOG" 2>/dev/null || true
  }

  # resolve_check_mode — per-check mode resolver (decouples a single check from
  # the shared deploy-check.mode cohort). Reads a CHECK-SPECIFIC mode file
  # "<check_id>.mode" from the same operator-instance base (and legacy
  # .claude/hooks/ fallback) as the shared MODE_FILE; if that file is absent or
  # carries an invalid value, FALLS BACK to the caller-supplied default (2nd arg,
  # itself defaulting to the shared $DEPLOY_CHECK_MODE). Echoes the resolved mode
  # (enforce|warn|off). This lets one check graduate warn→enforce independently
  # of the ~12-check shared-mode cohort without touching any other check's
  # behavior — every other check keeps reading $DEPLOY_CHECK_MODE directly and is
  # byte-for-byte unchanged.
  #
  #   resolve_check_mode "<check_id>"              # fallback = shared mode
  #   resolve_check_mode "<check_id>" "<default>"  # fallback = caller's default
  #
  # The OPTIONAL second argument exists so a check can ship a COMMITTED posture
  # (e.g. release-body-drift ships `enforce`) without cloning a bespoke default
  # block per check — a mode file cannot carry a shipped posture, because mode
  # files are operator-instance runtime state and are NOT committed (see the
  # decoupling contract below). Omitting the argument reproduces the pre-existing
  # behavior exactly, so every single-argument call site is unchanged.
  #
  # Decoupling contract (per the g1-enforcement mode-decoupling scope): the
  # g1-enforcement check (Check 22) resolves its mode via this helper from a
  # dedicated `g1-enforcement.mode` file; with no such file present it falls back
  # to the shared mode → warn (the current default). The warn→enforce flip is
  # DEFERRED to a follow-on after the ≥3-day shakedown; this release ships warn.
  # Mode files are operator-instance runtime state and are NOT committed.
  resolve_check_mode() {
    local _check_id="$1"
    local _default="${2:-$DEPLOY_CHECK_MODE}"
    local _check_mode_file="$(pmo_instance_path)/${_check_id}.mode"
    [[ -f "$_check_mode_file" ]] || _check_mode_file=".claude/hooks/${_check_id}.mode"
    if [[ -f "$_check_mode_file" ]]; then
      local _cm
      _cm=$(cat "$_check_mode_file" 2>/dev/null | tr -d '[:space:]')
      case "$_cm" in
        enforce|warn|off) printf '%s' "$_cm"; return 0 ;;
      esac
    fi
    # No check-specific file (or invalid value) → fall back to the caller default
    # (which is the shared mode unless the caller supplied its own).
    printf '%s' "$_default"
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

  # flag_release_body_drift — Check 47 (release-body drift) gating emit. Identical
  # semantics to flag_warn_or_issue, EXCEPT it switches on the check-specific
  # $RELEASE_BODY_DRIFT_MODE (resolved at Check 47 start via resolve_check_mode
  # "release-body-drift" with an ENFORCE default) rather than the shared
  # $DEPLOY_CHECK_MODE. In enforce-mode → FAIL (increments ISSUES); in warn-mode →
  # WARN + jsonl, no ISSUES increment; in off-mode → silent.
  #
  # Unlike flag_g1_enforcement (whose warn branch advertises a pending graduation),
  # this check ships ENFORCE. A warn here therefore means an operator deliberately
  # dialed it DOWN with a local release-body-drift.mode, or the shared cohort is
  # off — the message says so rather than pointing at a shakedown that is over.
  flag_release_body_drift() {
    local check_id="$1"
    local detail="$2"
    case "$RELEASE_BODY_DRIFT_MODE" in
      enforce)
        log "  FAIL:  $check_id — $detail"
        ISSUES=$((ISSUES + 1))
        ;;
      warn)
        log "  WARN:  $check_id — $detail (warn-mode; this check ships ENFORCE — a local release-body-drift.mode dialed it down)"
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
  #              byte-identical to its in-repo source — asserted by diff -q.
  #   NOTE (#2213): the former core/governance/OPERATIONS.md ↔ operations/OPERATIONS.md
  #              byte-identical mirror-pair entry was RETIRED here — that dual-home
  #              full copy silently drifted (#1346/#2213). It is replaced by the
  #              SSOT + pointer duplicate-home check appended after this loop.
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
  # restore". The pair set covers all 11 files under .claude/rules/ (including
  # git-workflow.md and governance-files.md surfaced by the Stage 5 spec).
  # This array and detect_mirror_pairs() in release/tools/blast-radius.sh must
  # hold IDENTICAL path sets — adding a rule to one and not the other silently
  # desynchronises the blast-radius mirror topology from the enforced pair set.
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
      "core/rules/decision-time-adherence.md:$DEPLOY_ROOT/.claude/rules/decision-time-adherence.md"
      "core/rules/rename-reference-cascade.md:$DEPLOY_ROOT/.claude/rules/rename-reference-cascade.md"
      "core/rules/analysis-mandate.md:$DEPLOY_ROOT/.claude/rules/analysis-mandate.md"
      "release/governance/release-process.md:$DEPLOY_ROOT/.claude/rules/release-process.md"
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

    # OPERATIONS.md SSOT + pointer duplicate-home check (per #2213 — replaces the
    # retired byte-identical mirror-pair enrollment above).
    #   core/governance/OPERATIONS.md is the SINGLE SOURCE OF TRUTH (SSOT) for
    #   program-level operations context — program-scoped governance is homed
    #   under core/governance/ per the CLAUDE.md governance file map.
    #   operations/OPERATIONS.md is retained ONLY as a path-stable POINTER STUB
    #   (several archival release docs link to it) and MUST NOT carry a divergent
    #   full copy. The former "keep both byte-identical" model (#183 A1) let the
    #   two homes silently drift (~31.6 KB apart by #2213), so we assert
    #   pointer-SHAPE (small + references the SSOT) instead of mirror-IDENTITY.
    #   Falsification: re-fork operations/OPERATIONS.md as a full copy — it grows
    #   past the stub ceiling and/or drops the SSOT reference -> WARN (advisory) /
    #   FAIL (post-flip). Same warn-mode posture as the mirror loop above.
    local c9_ssot="core/governance/OPERATIONS.md"
    local c9_ptr="operations/OPERATIONS.md"
    local c9_ptr_ceiling=8192  # a pointer stub is < 8 KB; the SSOT is > 100 KB
    if [[ ! -f "$c9_ptr" ]]; then
      log "  SKIP:  $c9_ptr (pointer absent)"
    elif [[ ! -f "$c9_ssot" ]]; then
      flag_warn_or_issue "operations-ssot" "$c9_ssot: SSOT missing — the $c9_ptr pointer resolves to nothing"
    else
      local c9_ptr_bytes
      c9_ptr_bytes=$(wc -c < "$c9_ptr" | tr -d ' ')
      if [[ "$c9_ptr_bytes" -gt "$c9_ptr_ceiling" ]]; then
        flag_warn_or_issue "operations-ssot" "$c9_ptr is ${c9_ptr_bytes} B (> ${c9_ptr_ceiling} B pointer ceiling) — it looks like a divergent full copy, not a pointer to the SSOT ($c9_ssot). Reduce it to a pointer stub (#2213 SSOT model)."
      elif ! grep -q 'core/governance/OPERATIONS.md' "$c9_ptr"; then
        flag_warn_or_issue "operations-ssot" "$c9_ptr (${c9_ptr_bytes} B) does not reference the SSOT ($c9_ssot) — a pointer stub must link to the single source of truth."
      else
        log "  OK:    $c9_ptr is a pointer stub (${c9_ptr_bytes} B) referencing the SSOT $c9_ssot"
      fi
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

  # ─── Check 13b passes 2/3/4: registered complementary pairs ───────────────
  # Pass 1 above sees only same-basename copies that BOTH live under a skill
  # references/ tree. A canonical<->skill-local pair — the canonical in the shared
  # corpus, the mirror beside its skill — is structurally OUTSIDE that population,
  # so `uniq -d` can never emit it and the pair is invisible to every check. These
  # passes close that gap without widening pass 1 (which would drag in dozens of
  # per-directory README.md copies and false-positive on a pair the corpus declares
  # deliberate).
  #
  #   pass 2  ownership assertion over the registry's declared sections
  #   pass 3  discovery of an UNREGISTERED cross-tree same-basename pair
  #   pass 4  the cited canonical resolves in the built package + deployed root
  #
  # The predicate body is _cp_compute_verdict() at top level — ONE engine shared
  # with `--self-test` group CP (DD1), reading
  # core/deploy/allowlists/complementary-reference-pairs.txt directly. It is the
  # SAME file core/deploy/tools/build-skill-packages.sh reads; neither consumer
  # holds a second copy.
  #
  # Posture: warn-mode, via the same flag_warn_or_issue emitter pass 1 uses —
  # Check 13b is a named member of the shared warn-mode cohort
  # (gate-efficacy-standard.md), so an enforce-mode prong here would make shipped
  # behavior diverge from declared posture.
  #
  # A missing registry verdicts NOSET and is FLAGGED, never a silent pass (the
  # Check 61 DE-9 precedent); build-skill-packages.sh mirrors that posture by
  # failing the build, so one deleted file cannot disable the fix and its
  # detector together.
  local c13b_cp_line c13b_cp_tok c13b_cp_detail
  while IFS= read -r c13b_cp_line; do
    [[ -z "$c13b_cp_line" ]] && continue
    c13b_cp_tok="${c13b_cp_line%%|*}"
    c13b_cp_detail="${c13b_cp_line#*|}"
    case "$c13b_cp_tok" in
      PASS)
        log "  OK:    complementary-pair registry — $c13b_cp_detail"
        ;;
      NOSET)
        flag_warn_or_issue "complementary-pair-registry-missing" "$c13b_cp_detail"
        ;;
      MALFORMED)
        flag_warn_or_issue "complementary-pair-registry-malformed" "$c13b_cp_detail"
        ;;
      OWNERSHIP-DRIFT)
        flag_warn_or_issue "complementary-pair-ownership-drift" "$c13b_cp_detail"
        ;;
      SHARED-DIVERGENCE)
        flag_warn_or_issue "complementary-pair-shared-section-divergence" "$c13b_cp_detail"
        ;;
      UNREGISTERED-PAIR)
        flag_warn_or_issue "unregistered-canonical-skill-local-pair" "$c13b_cp_detail"
        ;;
      CITATION-UNRESOLVABLE)
        flag_warn_or_issue "canonical-citation-unresolvable-in-package" "$c13b_cp_detail"
        ;;
      *)
        flag_warn_or_issue "complementary-pair-unknown-verdict" \
          "unrecognised verdict token '$c13b_cp_tok' from _cp_compute_verdict — fail-closed: an unreadable verdict is never a pass"
        ;;
    esac
  done <<< "$(_cp_compute_verdict)"

  # ─── Check 14: Doc-link maintenance — governance + skill SKILL.md scope ───
  # Per Collective Review CR-D1 / CR-D2.
  # Invokes the shared primitive at core/deploy/tools/check-doc-links.py over
  # the governance + reference + rules + skill SKILL.md surface. Warn-mode initial
  # per core/rules/bypass-mode-readiness.md shakedown precedent; flip-to-enforce
  # timeline codified in core/standards/doc-link-maintenance-protocol.md.
  # Scan scope is read from the SHARED --target-paths-file
  # (core/deploy/allowlists/doc-link-target-paths.txt) that .github/workflows/
  # link-check.yml also reads — one list, two callers, so the deploy-time and
  # PR-time scan scope can never drift (they formerly carried a byte-identical
  # inline string in two places). The list also covers the residual dead-ref
  # trees core/ADRs/, core/deploy/, repo-root *.md, and .github/; per-tree
  # rationale + the release/releases/ exclusion live in that file's header.
  # Link resolution is the one canonical rule (ADR-085): relative to the source
  # file's directory, a leading `/` denotes the repo root, and there is NO bare
  # module-prefix fallback. The tool also has a --from-path/--to-path EMIT-ONLY
  # rewrite-map mode for per-edit discipline workflows. Check 15 (release-corpus)
  # RETIRED in v2 per FX-Check15 — see citation block below Check 14.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 14: Doc-link maintenance (governance + skill SKILL.md scope)"
    local c14_script="core/deploy/tools/check-doc-links.py"
    local c14_target_paths_file="core/deploy/allowlists/doc-link-target-paths.txt"
    # TWO allowlists, UNIONed by the primitive (--allowlist is repeatable and
    # additive — a later file adds to the earlier, never replaces it):
    #   1. c14_allowlist_base — the TRACKED corpus-level skip class, the SAME
    #      file link-check.yml passes. Scan scope has been single-sourced via
    #      --target-paths-file; this single-sources the IGNORE list on the same
    #      principle. While it was dual-sourced, the two callers scanned
    #      byte-identical files and reached different verdicts (0 at PR time vs
    #      84 at deploy time), so "one list, two callers, cannot drift" held for
    #      scope but not for outcome.
    #   2. c14_allowlist_instance — operator-local additions layered on top.
    #      Stays operator-instance (with the legacy .claude/ fallback) so an
    #      operator can suppress paths that exist only in their workspace,
    #      WITHOUT re-declaring the tracked entries locally.
    local c14_allowlist_base="core/deploy/allowlists/skip-doc-link-check-ci.txt"
    local c14_allowlist_instance="$(pmo_instance_path)/skip-doc-link-check.txt"
    [[ -f "$c14_allowlist_instance" ]] || c14_allowlist_instance=".claude/skip-doc-link-check.txt"
    if [[ ! -f "$c14_script" ]]; then
      flag_warn_or_issue "doc-link-maintenance" "primitive script missing: $c14_script"
    elif [[ ! -f "$c14_target_paths_file" ]]; then
      # Fail-loud: the shared scan-scope list is the single source of truth; a
      # missing list must never read GREEN (the tool would refuse to scan
      # nothing, but flag the missing surface here with a clear message).
      flag_warn_or_issue "doc-link-maintenance" "shared target-paths file missing: $c14_target_paths_file (scan scope undefined; check is unverifiable)"
    elif [[ ! -f "$c14_allowlist_base" ]]; then
      # Name the asymmetry rather than letting the operator rediscover it as a
      # wall of findings. A missing allowlist can only OVER-report (it never
      # manufactures a false green), so this is diagnosability, not safety —
      # but "tracked base missing" is the actionable message, not "84 broken
      # cross-refs" from a baseline that silently diverged from CI's.
      flag_warn_or_issue "doc-link-maintenance" "tracked base allowlist missing: $c14_allowlist_base (deploy-time baseline would diverge from the PR-time gate)"
    elif [[ ! -x "/usr/bin/python3" ]]; then
      flag_warn_or_issue "doc-link-maintenance" "/usr/bin/python3 not executable; cannot run primitive"
    else
      local c14_output c14_exit=0
      # Scan scope comes from the SHARED --target-paths-file (single source of
      # truth with link-check.yml — see the file's header for per-tree rationale).
      # --require-targets (per #459): a declared glob resolving to zero files is a
      # path-resolution failure (exit 3), not a clean pass — so a relocated/typo'd
      # scan surface can never read GREEN. Every entry in the shared list must
      # yield >= 1 .md (verified when the list is edited).
      c14_output=$(/usr/bin/python3 "$c14_script" \
        --target-paths-file "$c14_target_paths_file" \
        --allowlist "$c14_allowlist_base" \
        --allowlist "$c14_allowlist_instance" \
        --output-format tsv \
        --require-targets \
        --exclude-code-blocks 2>&1) || c14_exit=$?
      if [[ $c14_exit -eq 3 ]]; then
        # Path-resolution failure — never a silent PASS (per #459 fail-loud).
        flag_warn_or_issue "doc-link-maintenance" "path-resolution failure (exit 3): $(echo "$c14_output" | head -1) — a declared glob in $c14_target_paths_file resolved to zero files (relocated/typo'd scan surface); fix the shared list"
      elif [[ $c14_exit -eq 2 ]]; then
        # Config error (exit 2) — e.g. the shared target-paths file is empty, or
        # an invalid flag combination. Fail-loud rather than treat as findings.
        flag_warn_or_issue "doc-link-maintenance" "primitive config error (exit 2): $(echo "$c14_output" | head -1)"
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
  # Asserts the 4 atomic invariants on ALL open intake issues:
  #   I1 mutex          — any open issue with >1 status:* label          (all types)
  #   I2 presence       — any open issue with 0 status:* labels          (all types
  #                       EXCEPT type:epic + sub-task — see the I2 exemption below)
  #   I3 contradiction-A — status: proposed + milestone set               (all types)
  #   I4 contradiction-B — status: bundled + no milestone                 (all types)
  # SCOPE [#2682, 2026-07-19]: previously scanned `--label improvement` only; the
  # fetch is now unscoped so bug/observation/sub-task/type:task intake is covered.
  # Status-label vocabulary-agnostic via startswith("status: ") — accepts any
  # current or future status value (status: deferred / status: rejected land cleanly).
  # MODE DECOUPLED [#2682]: resolves its mode via resolve_check_mode
  # "status-label-invariant" (a dedicated `status-label-invariant.mode` file), NOT
  # the shared $DEPLOY_CHECK_MODE cohort — so the newly-broadened scope can graduate
  # warn→enforce independently and a shared flip elsewhere cannot enforce the
  # untested wider net (Check 22's g1-enforcement decoupling precedent). Absent a
  # dedicated file it falls back to the shared mode (→ warn default), byte-identical
  # to the prior behavior. Ships warn-mode for ≥3-day shakedown per
  # bypass-mode-readiness.md §Shakedown; the introducing release is itself exempt
  # (reflexive-pipeline loop — the broadened net does not gate its own release).
  # Exemption: .claude/status-label-invariant-exemption-list.txt — lines of
  # `<issue-number> <invariant-id>` skip the matching violation.
  # NOTE: the c14_ / C14_ variable prefix below is stale copy-paste naming WITHIN
  # Check 16 (not a numbering error) — flagged for a cosmetic follow-up rename;
  # deliberately NOT renamed here to keep this in-place scope-widen a single
  # focused, minimal, independently-revertible diff.
  local STATUS_LABEL_MODE
  STATUS_LABEL_MODE=$(resolve_check_mode "status-label-invariant")
  if [[ "$STATUS_LABEL_MODE" != "off" ]]; then
    log "Check 16: Status-label invariant (I1/I2/I3/I4; all-intake scope; warn-mode initial; enforce-flip deferred)"
    local C14_EXEMPT_FILE=".claude/status-label-invariant-exemption-list.txt"
    local c14_violations=0

    # exempt_pair issue_num invariant_id — returns 0 if exempt
    exempt_pair() {
      local _num="$1" _inv="$2"
      [[ -f "$C14_EXEMPT_FILE" ]] || return 1
      grep -qE "^[[:space:]]*${_num}[[:space:]]+${_inv}([[:space:]]|$)" "$C14_EXEMPT_FILE"
    }

    # flag_status_label — Check 16 decoupled emit. Mirrors flag_warn_or_issue but
    # switches on $STATUS_LABEL_MODE (resolved above), not the shared mode — the
    # flag_g1_enforcement precedent. enforce → FAIL (increments ISSUES); warn →
    # WARN + jsonl, no increment.
    flag_status_label() {
      local check_id="$1" detail="$2"
      case "$STATUS_LABEL_MODE" in
        enforce)
          log "  FAIL:  $check_id — $detail"
          ISSUES=$((ISSUES + 1))
          ;;
        warn)
          log "  WARN:  $check_id — $detail (warn-mode; flip status-label-invariant.mode to 'enforce' after shakedown)"
          local _ts
          _ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
          local _detail_escaped="${detail//\\/\\\\}"
          _detail_escaped="${_detail_escaped//\"/\\\"}"
          printf '{"ts":"%s","check":"%s","detail":"%s"}\n' "$_ts" "$check_id" "$_detail_escaped" >> "$WARN_LOG" 2>/dev/null || true
          ;;
      esac
    }

    # Single fetch — feeds all 4 invariant queries via local jq filters.
    # SCOPE WIDENED [#2682, 2026-07-19]: the `--label improvement` filter was
    # dropped so the invariants cover ALL open intake (bug / observation / sub-task
    # / type:task) — not just improvement. The prior scope let non-improvement
    # intake drift half-labeled indefinitely (facet 2), and left the already-present
    # I4 orphaned-bundle detector blind to non-improvement bundles. Per-invariant
    # type applicability is enforced BELOW (I2 exempts type:epic + sub-task); I1/I3/I4
    # remain all-types. --limit 5000 has ample headroom for the ~300 open population.
    local c14_issues_json
    c14_issues_json=$(gh issue list --repo "$AUDIT_REPO" --state open \
      --limit 5000 --json number,labels,milestone 2>/dev/null || echo "[]")

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
      flag_status_label "status-label-I1-mutex" "issue #$_num has >1 status:* label"
      c14_violations=$((c14_violations + 1))
    done <<< "$c14_i1_violators"

    # I2 — presence: 0 status:* labels.
    # TYPE EXEMPTION [#2682, 2026-07-19]: skip `type:epic` and `sub-task`.
    #   - type:epic: operator decision — epics are CONTAINERS, not lifecycle work
    #     items, so "exactly one status label" does not apply (label-taxonomy.md
    #     Rule 2). Without this, the widened scope would false-FAIL on the 38
    #     statusless epics (load-bearing, not cosmetic).
    #   - sub-task: the pre-existing carve-out (label-taxonomy.md Rule 6) — a
    #     sub-task's status label is a point-in-time hygiene mirror, not an
    #     invariant-enforced field. Previously implicit (sub-tasks lacked the
    #     `improvement` label); now explicit since the fetch is unscoped.
    # This exemption applies to I2 ONLY. I1 (mutex) / I3 / I4 stay all-types: an
    # epic that never carries a status label simply never trips them.
    local c14_i2_violators
    c14_i2_violators=$(printf '%s' "$c14_issues_json" | jq -r '
      .[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) == 0)
      | select((.labels | map(.name) | index("type:epic")) | not)
      | select((.labels | map(.name) | index("sub-task")) | not)
      | .number')
    while IFS= read -r _num; do
      [[ -n "$_num" ]] || continue
      if exempt_pair "$_num" "I2"; then
        log "  EXEMPT: I2 presence on issue #$_num (exemption-list)"
        continue
      fi
      flag_status_label "status-label-I2-presence" "issue #$_num missing all status:* labels"
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
      flag_status_label "status-label-I3-contradiction-A" "issue #$_num is status: proposed but milestone is set"
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
      flag_status_label "status-label-I4-contradiction-B" "issue #$_num is status: bundled but no milestone"
      c14_violations=$((c14_violations + 1))
    done <<< "$c14_i4_violators"

    if [[ "$c14_violations" -eq 0 ]]; then
      log "  OK:    0 violations across I1/I2/I3/I4 (all open intake; type:epic + sub-task exempt from I2)"
    else
      log "  ${c14_violations} violation(s) emitted (mode=${STATUS_LABEL_MODE})"
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
  # 19a presence — THREE distinct outcomes, split by ownership class (#4051):
  #     · tracked schema doc unresolvable → fail-loud as a PATH-RESOLUTION
  #       FAILURE (asserted first + unconditionally; deterministic in CI)
  #     · operator-instance log/write-log absent → SKIP, no flag, no drift claim
  #       (legitimately absent on a fresh install and in CI)
  #     · all three present → 19b + 19c assert
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
    # Class A — operator-instance runtime state. Resolved through the SHARED
    # resolver in lib-instance-path.sh (sourced above), which is the same surface
    # append-pipeline-event.sh writes through, so the reader and the writer of
    # these two files can never disagree about where they live (#4051).
    local c19_evals_dir="$(pmo_evals_results_path)"
    local c19_log="$c19_evals_dir/pipeline-event-log.md"
    local c19_write_log="$c19_evals_dir/pipeline-event-log-write.log"
    # Class B — tracked repo doc. Committed, so it resolves in every checkout.
    local c19_schema="release/references/standards/pipeline-event-log-schema.md"

    # 19a — presence, split by OWNERSHIP CLASS into three distinct outcomes.
    #
    # Class B is asserted FIRST and UNCONDITIONALLY. The schema is a tracked
    # file, so its absence is a repo defect or a stale literal — never a benign
    # state — and it is deterministic in CI. Nesting it behind the Class A branch
    # (as the pre-#4051 flat if/elif chain did) makes it unreachable wherever the
    # operator instance is absent, which is exactly how a dead literal survived
    # 175 runs while the check read as a benign warning.
    if [[ ! -f "$c19_schema" ]]; then
      flag_warn_or_issue "pipeline-event-log-integrity" \
        "path-resolution failure: event-log schema did not resolve at $c19_schema — this is a BROKEN CONTROL (stale literal or relocated doc), not a missing artifact; 19c cannot be validated against its source (per #459 fail-loud, as at Checks 18/20)"
    fi

    # Class A absence is a SKIP with NO flag_* call and no drift claim: the event
    # log is operator-instance state, legitimately absent on a fresh install and
    # in CI, so hard-failing would break both. The emission is deliberately
    # DISTINCT from the fail-loud above — collapsing the two into one warn is what
    # made "this control is disabled" typographically identical to "there is
    # nothing to check yet". The resolved path is printed so a mis-resolution is
    # visible even on the SKIP path.
    if [[ ! -f "$c19_log" ]]; then
      log "  SKIP:  no event log at $c19_log (operator-instance state — fresh install / CI; nothing to assert)"
    elif [[ ! -f "$c19_write_log" ]]; then
      log "  SKIP:  no write-log at $c19_write_log (operator-instance state — fresh install / CI; nothing to assert)"
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
  #
  # FLIP STATUS: STAGED, NOT TAKEN. The release-corpus normalization removed the
  # false-positive class that warn-mode was justifying — the INDEX Date is now
  # relayed from the LOG row by one projector rather than sampled from a second
  # clock — but the flip's own precondition is an OBSERVATION WINDOW (≥3 days of
  # warn-log review with zero false positives), and no release can satisfy a
  # post-merge observation condition inside its own merge. Flipping here would
  # bypass the shakedown convention that ten prior checks observed, to satisfy a
  # criterion. The flip is an operator decision on the condition stated above.
  #
  # Interim posture, deliberate and not an inconsistency: Check 23 stays WARN
  # while the derived-surface PRESENCE limbs in Checks 32 and 48 stay ENFORCED.
  # They assert different propositions — presence of an entry vs. agreement of
  # its fields — and only the second one's false-positive class was removed.
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
        # REMEDIATION IS APPEND-ONLY, NEVER A BARE REGENERATE. This string used
        # to say "re-run 'python3 <script>' to regenerate" — and a BARE
        # invocation of that script is the documented DESTRUCTIVE full
        # regenerate: it rewrites every row, restamps the grandfathered Date
        # cells the INDEX header declares must not be rewritten, and (until this
        # release) deleted the header paragraph declaring the anchor. Three
        # commits rewrote that guidance in the generator, the tools README,
        # release-process.md and plans/README.md, and none of them reached this
        # file — so the one gate that renders the instruction at merge time kept
        # telling the operator to run the one action the design forbids.
        flag_warn_or_issue "release-log-index-consistency" \
          "$c23_findings LOG↔INDEX drift finding(s) — reconcile the named field IN PLACE (the LOG row is canonical for milestone/date/release-pr; the INDEX Theme cell has no LOG source and is never drift-checked), then confirm with the read-only 'python3 $c23_script --verify'. Do NOT run a bare 'python3 $c23_script' — that is a destructive full regenerate"
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
    # Fallback to workspace .claude/agents/ for backwards-compatibility during
    # transition window if the operator workspace has not yet been updated.
    [[ -d "$c26_agents_dir" ]] || c26_agents_dir=".claude/agents"
    # Companion per-stage-override allowlist (#340): canonical read location is the
    # DEPLOYED instance surface — composition-surface-manifest.sh installs the source
    # core/config/allowlists/agents-model-overrides.txt to the instance base as an
    # `instance`-tier file. The prior release/.claude and .claude paths are retained
    # as back-compat fallbacks for a workspace not yet re-deployed. This reconciles the
    # read-path-vs-deploy-path seam so operator per-stage overrides placed in the
    # deployed file are visible to this check.
    local c26_overrides="$(pmo_instance_path)/agents-model-overrides.txt"
    [[ -f "$c26_overrides" ]] || c26_overrides="release/.claude/agents-model-overrides.txt"
    [[ -f "$c26_overrides" ]] || c26_overrides=".claude/agents-model-overrides.txt"
    # Default spoke model: read the canonical platform-config [spoke_runtime] surface
    # (#340) via the rung-reader; fall back to the documented "opus" literal when the
    # field is unresolved at every rung (resolver Rule-2 consumer-default). This
    # de-hardcodes the prior literal so the default and the Model Provenance block read
    # ONE source (both prior detection anchors converge, neither eliminated).
    local c26_default_model="$(resolve_platform_config default_spoke_model)"
    [ -n "$c26_default_model" ] || c26_default_model="opus"
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
        #
        # PLUMBING (#3833 — same defect class as #4224, fixed the same way): each probe
        # reads its subject from a HERESTRING, never by piping the stripped body into a
        # quiet grep. (This note deliberately avoids spelling that pipeline literally, so
        # the negative assertion that bounds this defect — zero such pipelines in this
        # file — cannot match its own explanatory text and pass vacuously.)
        # Under this script's `set -euo pipefail` (line 2) a `grep -q` that matches EARLY
        # exits before echo has finished writing; echo then takes SIGPIPE and pipefail
        # promotes its 141 to the pipeline's status — so a SUCCESSFUL match reported
        # FAILURE, the `&&` never fired, and the file's override marker was silently
        # ignored. Every in-scope file whose fence-stripped body exceeds the 64 KB pipe
        # capacity lost its marker deterministically (7 of 164 for Class L, 3 of 26 for
        # Class V); files near that boundary lost it as a race, which is what made the
        # reported Class-L count vary run-to-run on a byte-identical corpus. A herestring
        # gives grep a pre-filled input, so there is no writer left to signal.
        #
        # BOTH probes are converted. Class V was asymptomatic at the headline COUNT only
        # because its 3 dropped files carry no Class-V matches — its skip tally was wrong
        # on every run just the same. Converting one and not the other leaves the identical
        # defect armed behind a number that happens not to move yet.
        local _allow_link=0 _allow_version=0
        grep -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-link[[:space:]]*-->' <<< "$_stripped" && _allow_link=1
        grep -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-version-ref[[:space:]]*-->' <<< "$_stripped" && _allow_version=1
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
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (a)+(b)/(b')):
  #   posture: required   enforcement-surface: release-corpus-completeness CI gate
  #            (.github/workflows/release-corpus-completeness.yml, warn-mode-initial —
  #             the deploy-time inline check below stays warn via DEPLOY_CHECK_MODE; the
  #             REQUIRED posture is realized at the pre-merge CI mirror per Req b', which
  #             mandates a required gate be CI-enforced, not deploy-time-only. The
  #             deploy-time enforce-flip is a separate concern owned elsewhere.)
  #   invariant: every RELEASE_LOG row at/after the cutover implies its INDEX row +
  #              DIGEST entry + NOTES file (+ tag + published Release post-cutover).
  #   falsification: a RELEASE_LOG row present with its INDEX/DIGEST/NOTES absent -> the
  #                  gate reports INCOMPLETE (warn: summary + exit 0; enforce: red + exit 1).
  #                  A complete output-set for every in-scope row -> CLEAN/green.
  #
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
    # Verdict computed by the shared _c32_compute_verdict body (DD1) so the CI probe
    # (--check-release-corpus) and this lifecycle check cannot diverge. The body emits
    # per-row detail to stderr; this block maps the verdict to the deploy-time emit
    # (warn-mode via flag_warn_or_issue / DEPLOY_CHECK_MODE — behavior unchanged).
    local c32_verdict c32_tok c32_rest c32_f c32_n
    c32_verdict="$(_c32_compute_verdict "lifecycle")"
    c32_tok="${c32_verdict%% *}"
    case "$c32_tok" in
      SKIP)
        flag_warn_or_issue "release-corpus-completeness" "${c32_verdict#SKIP }"
        ;;
      CLEAN)
        log "  OK:    all ${c32_verdict#CLEAN } logged release(s) on/after the corpus cutover have INDEX + DIGEST + NOTES"
        ;;
      INCOMPLETE)
        # "INCOMPLETE <findings> <targets>" — per-row detail already on stderr.
        c32_rest="${c32_verdict#INCOMPLETE }"
        c32_f="${c32_rest%% *}"; c32_n="${c32_rest##* }"
        flag_warn_or_issue "release-corpus-completeness" \
          "$c32_f corpus-completeness finding(s) across $c32_n logged release(s) — a close dropped an output; see release/references/pipeline/stage-13-close.md Phase B (per-row detail above)"
        ;;
      *)
        flag_warn_or_issue "release-corpus-completeness" "unexpected verdict: $c32_verdict"
        ;;
    esac
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
  # CUTOVER-SCOPED, ARMED BY DEFAULT: like Check 32's published-Release sub-check,
  # the drift assertion runs only for LOG rows at/after a SEPARATE, later
  # $c47_cutoff (RELEASE_BODY_DRIFT_CHECK_CUTOFF). That cutoff now carries a
  # COMMITTED default instead of the __none__ sentinel, so the check runs on a
  # clean checkout with no operator opt-in. The cutoff still scopes the assertion
  # FORWARD — historical rows whose Release bodies predate the §5.1 transform are
  # never retroactively flagged. __none__ remains an ACCEPTED value: an operator
  # who exports it explicitly disables the assertion. The escape hatch is retained;
  # it is simply no longer the default.
  #
  # WHY THE CUTOFF MUST BE A COMPLETE VERSION TOKEN: the cutover test below is a
  # positional PREFIX GLOB, not a semantic version compare. It LATCHES on the first
  # prefix-matching row and then takes the contiguous file-order suffix — and LOG
  # file order is date-ascending, NOT version-ordered. A partial token (say "v3.8")
  # would silently match every sibling sharing that prefix and widen scope by an
  # order of magnitude. The committed default is therefore a complete token.
  #
  # HOW THE VALUE WAS CHOSEN: it names the EARLIEST already-merged release whose
  # published body this very tool verified equal to its note — found by walking the
  # LOG backward from the tail until the first drifted row, and anchoring one row
  # later. Anchoring instead at the §5.1 transform's own introducing release was
  # REJECTED: that range contains known-drifted historical bodies, so the armed gate
  # would red-fail on day one, and the only way to keep it green would be a
  # permanent exempt list naming the exact defect class the gate exists to catch.
  # Those historical rows are tracked as a separate carry-forward instead. The
  # consequence to state plainly: this gate's coverage of history is nil and grows
  # only as releases accrue.
  #
  # SHIPPED ENFORCE (not warn-mode-initial): findings route through
  # flag_release_body_drift, which switches on $RELEASE_BODY_DRIFT_MODE — resolved
  # via resolve_check_mode "release-body-drift" with an ENFORCE default. A mode file
  # CANNOT carry this posture: mode files are operator-instance runtime state and
  # are NOT committed (see resolve_check_mode's contract), so a mode-file flip would
  # leave a clean checkout resolving to the shared warn. An operator can still dial
  # DOWN locally with a release-body-drift.mode of warn|off, and a shared
  # deploy-check.mode of `off` remains the global kill-switch.
  #
  # REFLEXIVE-PIPELINE-LOOP — why an armed cutoff does not gate its own introducing
  # release, even though that release IS in scope. "Anchor the cutoff after this
  # release's merge SHA" is structurally unreachable for a gate that scans anything:
  # the latch takes the contiguous file-order suffix, so ANY cutoff naming an
  # existing row also covers every future row, and the only cutoffs that exempt the
  # introducing release name a version that does not exist yet — and therefore scan
  # zero rows. The obligation is discharged by the EXIT-CODE CONTRACT below instead:
  # the mid-close states (Surface 1 not yet published; note not yet on origin/main)
  # both return tool exit 3, which maps to N/A and NEVER to a finding. A release can
  # fail its own close here only by publishing a genuinely drifted body — which is
  # the gate working, not a loop. Both shipped emit paths derive the body from the
  # note by the same §5.1 transform, so that path is closed by construction.
  # Recorded here because this is where a future maintainer looks; do not re-derive.
  #
  # FRESHNESS PRESUMPTION (accepted residual, sharper under enforce): the tool reads
  # the canonical note from the LOCAL origin/main remote-tracking ref, and this check
  # performs NO fetch — a self-fetch would violate the tool's detective-only posture.
  # A content-stale origin/main can therefore yield a false finding, which under
  # enforce is a FAIL rather than a harmless WARN. Run `git fetch origin` immediately
  # before an enforcing `deploy.sh --check`.
  #
  # Ship ENFORCE by default; a shared-cohort `off` still suppresses this check.
  local _c47_default="enforce"
  if [[ "$DEPLOY_CHECK_MODE" == "off" ]]; then _c47_default="off"; fi
  RELEASE_BODY_DRIFT_MODE="$(resolve_check_mode "release-body-drift" "$_c47_default")"
  if [[ "$RELEASE_BODY_DRIFT_MODE" != "off" ]]; then
    log "Check 47: Release-body drift (published Release body == frontmatter-stripped in-repo note)"
    local c47_log="release/releases/RELEASE_LOG.md"
    local c47_tool="release/tools/check-release-body-drift.sh"
    # Separate, later cutover for this network-dependent assertion. The default is
    # a COMMITTED, complete version token (see the block comment above); exporting
    # the __none__ sentinel is the operator's explicit opt-OUT.
    local c47_cutoff="${RELEASE_BODY_DRIFT_CHECK_CUTOFF:-v3.78}"

    if [[ "$c47_cutoff" == "__none__" ]]; then
      log "  N/A:   release-body drift check explicitly disabled by an operator override (RELEASE_BODY_DRIFT_CHECK_CUTOFF=__none__) — unset it to restore the committed cutoff"
    elif [[ ! -x "$c47_tool" ]]; then
      flag_release_body_drift "release-body-drift" \
        "drift tool not executable: $c47_tool — cannot assert the §5.1 published-body invariant"
    elif ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
      # gh-guard: offline/unauth => N/A (never FAIL), mirroring Check 32/39.
      log "  N/A:   release-body drift check skipped (gh offline/unauthenticated) — reuses Check 32/39 gh-guard SKIP semantics"
    elif [[ ! -f "$c47_log" ]]; then
      flag_release_body_drift "release-body-drift" \
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
          1)       # DRIFT — a genuine finding; gated by $RELEASE_BODY_DRIFT_MODE
            c47_output+="${_v47}: published Release body != frontmatter-stripped in-repo note (§5.1 drift)"$'\n'
            c47_findings=$((c47_findings + 1))
            ;;
          2) # gh is confirmed up before this loop (gh-guard above), so exit 2 here
             # is a git capability absence (origin/main unresolvable / corrupt
             # object), NOT gh. Name it from the tool's stderr; never FAIL.
             log "  N/A:   ${_v47} drift sub-check N/A at tool layer — required capability unavailable (git/origin-main; gh already confirmed up). $(/usr/bin/printf '%s' "$_d47_out" | /usr/bin/head -1)" ;;
          3) log "  N/A:   ${_v47} has no published Release or note to compare (Surface 1 absent — Check 32 owns existence)" ;;
          *) c47_output+="${_v47}: drift tool returned unexpected exit ${_d47_exit}"$'\n'; c47_findings=$((c47_findings + 1)) ;;
        esac
      done <<<"$c47_rows"

      if [[ $c47_findings -eq 0 ]]; then
        log "  OK:    all $c47_targets logged release(s) on/after $c47_cutoff have a published Release body matching their in-repo note (§5.1 invariant holds)"
      else
        flag_release_body_drift "release-body-drift" \
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
  # ARMED + warn-mode-initial: gated on a per-check mode via resolve_check_mode
  # "close-completeness" (independent graduation from the shared cohort). The assertion
  # itself is ARMED by the committed CLOSE_COMPLETENESS_CHECK_CUTOFF default (#4176) —
  # only the warn/enforce mode remains a graduation dial; setting the cutoff to __none__
  # re-dormants it explicitly. The cutover is anchored strictly AFTER the introducing
  # release's (v2.37) merge — the reflexive-pipeline-loop discipline: a release never
  # gates its own close. The CI-blocking switch is the committed
  # .github/close-completeness.enforce sentinel (read by the workflow, mirroring
  # version-freeness).
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
  # Fields are split with `awk -F'\\|\\|\\|'` — the separator needs DOUBLE backslashes.
  # A single-backslash `-F'\|\|\|'` yields an empty field count inside a command
  # substitution under BSD awk, producing a FALSE MALFORMED verdict. Not `IFS='|||' read`
  # either, which bash collapses to single-'|' separators and silently empties fields 2/3.
  #
  # Warn-mode initial via flag_warn_or_issue / deploy-check.mode (the Checks 8-10 /
  # 13b / 14 / 33 precedent): in warn-mode a breach logs WARN: + appends
  # deploy-check-warn-log.jsonl WITHOUT incrementing ISSUES; in enforce-mode it
  # increments ISSUES so `--check` (STRICT) exits non-zero on a real divergence.
  # Flip-to-enforce path: template-storage.md §3.5b + bypass-mode-readiness.md
  # Shakedown→Enforce checklist + the runtime deploy-check.mode file.
  local -a TEMPLATE_SCHEMA_MAP=(
    "operations/templates/open-meetings-tracker-template.md|||core/schemas/tracker-schemas.md|||Tracker 3: Open Meetings Tracker|||Upcoming Meetings|Recently Completed|Recurring Cadences"
    "operations/templates/sprint-tracker-template.md|||core/schemas/tracker-schemas.md|||Tracker 10: Sprint Tracker|||Current Sprint|Sprint History|Estimate-Actual Pairs|Capture Exceptions"
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
  #   invariant: every core/hooks/block-*.sh DECLARES its owning doc in its own
  #              `# hook-owner: <repo-relative-path>` header line, that owner
  #              resolves on disk, and every bypass-mode per-hook source maps back
  #              to a script that declares it AND a row in the generated index — a
  #              bijection scoped by ownership, NOT a forced single-file bijection
  #              (per ADR-030). Ownership is DERIVED by enumeration from the
  #              per-hook declaration (#1476 closed the ADR-030 residual: no
  #              central ownership array). Bypass-mode membership is itself
  #              derived — a hook is bypass iff its declared owner is its per-hook
  #              readiness fragment under core/rules/bypass-mode-readiness/.
  #   falsification: add a new core/hooks/block-foo.sh with no `# hook-owner:`
  #                  line (or a declared owner missing on disk) -> Check 37 WARNs
  #                  (advisory) / FAILS (post-flip). Delete a per-hook source
  #                  whose script still declares it -> Check 37 WARNs / FAILS.
  #
  # This is the drift-resistance teeth ADR-030 adds: it makes the live 5/7/9
  # registry drift (doc said "7 hooks"; subagent-security-posture said "5"; the
  # machine registry had all 9; no check reconciled them) structurally
  # impossible. It asserts CONTENT (the on-disk script set + each script's
  # declared owner vs the on-disk source set vs the generated-index rows), not a
  # proxy — and adding a hook needs ZERO edit to this file (#1476 AC).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 37: Hook-registry completeness (ownership by per-hook declaration)"
    local c37_index="core/rules/bypass-mode-readiness.md"
    local c37_src_dir="core/rules/bypass-mode-readiness"
    # Ownership is DERIVED by enumeration from each hook's own
    # `# hook-owner: <repo-relative-path>` header line — there is NO central
    # ownership array (#1476 closed the ADR-030 residual). A hook is a bypass-mode
    # hook iff its declared owner is its per-hook readiness fragment under
    # $c37_src_dir/ (which also carries a row in $c37_index); any other resolvable
    # owner marks a standalone hook owned by its own discipline doc. Adding a hook
    # therefore edits ZERO shared file here: the declaration ships inside the new
    # hook's own .sh (plus a new fragment for a bypass-mode hook).
    if [[ ! -d core/hooks ]] || [[ ! -f "$c37_index" ]] || [[ ! -d "$c37_src_dir" ]]; then
      log "  SKIP:  hook scripts dir, index, or source dir absent (greenfield/partial checkout)"
    else
      local c37_violations=0
      local c37_bypass_count=0
      local c37_other_count=0
      # (a) Forward: every script declares an owner that resolves on disk; a
      #     bypass owner (a fragment under $c37_src_dir/) also requires an index row.
      local c37_script
      for c37_script in core/hooks/block-*.sh; do
        [[ -e "$c37_script" ]] || continue
        local c37_base; c37_base="$(basename "$c37_script" .sh)"
        local c37_owner
        c37_owner="$(sed -n -E 's/^# hook-owner:[[:space:]]+//p' "$c37_script" | head -1)"
        if [[ -z "$c37_owner" ]]; then
          # Script with NO ownership declaration — the 5/7/9 failure mode.
          flag_warn_or_issue "hook-registry-completeness" "$c37_base has no '# hook-owner:' declaration — add one to the hook source core/hooks/$c37_base.sh"
          c37_violations=$((c37_violations + 1))
          continue
        fi
        if [[ ! -f "$c37_owner" ]]; then
          flag_warn_or_issue "hook-registry-completeness" "$c37_base declares owner '$c37_owner', but that owner doc is missing on disk"
          c37_violations=$((c37_violations + 1))
          continue
        fi
        case "$c37_owner" in
          "$c37_src_dir"/*)
            # Bypass-mode hook: declared owner must be ITS OWN per-hook source,
            # and that source must have a row in the generated index.
            c37_bypass_count=$((c37_bypass_count + 1))
            if [[ "$c37_owner" != "$c37_src_dir/$c37_base.md" ]]; then
              flag_warn_or_issue "hook-registry-completeness" "bypass-mode hook $c37_base declares owner '$c37_owner' but its per-hook source must be $c37_src_dir/$c37_base.md"
              c37_violations=$((c37_violations + 1))
            # The generated "## The Hooks" table emits one anchor-linked row per
            # per-hook source: `[\`block-<hook>.sh\` (…)](#…)`. Assert that row exists.
            elif ! grep -qE "\[\`?$c37_base\.sh\`? .*\]\(#" "$c37_index" 2>/dev/null; then
              flag_warn_or_issue "hook-registry-completeness" "bypass-mode hook $c37_base has a source but no row in the generated index $c37_index (regenerate via build-hook-registry.py)"
              c37_violations=$((c37_violations + 1))
            fi
            ;;
          *)
            # Standalone hook: owner doc existence already verified above. OK.
            c37_other_count=$((c37_other_count + 1))
            ;;
        esac
      done
      # (a2) Opt-in arm: a NON-`block-*` hook (a trigger/notifier rather than a
      #      guard) is scanned IFF it declares an owner. Declaring is the opt-in —
      #      a hook with no `# hook-owner:` line is skipped here rather than
      #      flagged, because the forward invariant in (a) is scoped to the
      #      guard set and widening it would retro-fail the pre-existing
      #      notifier/helper scripts that never declared one. What this arm DOES
      #      assert: once a hook declares an owner, that owner must resolve on
      #      disk — so a declaration cannot rot into decoration.
      local c37_any
      for c37_any in core/hooks/*.sh; do
        [[ -e "$c37_any" ]] || continue
        case "$c37_any" in core/hooks/block-*.sh) continue ;; esac   # covered by (a)
        local c37_abase; c37_abase="$(basename "$c37_any" .sh)"
        local c37_aowner
        c37_aowner="$(sed -n -E 's/^# hook-owner:[[:space:]]+//p' "$c37_any" | head -1)"
        [[ -n "$c37_aowner" ]] || continue                            # not opted in
        if [[ ! -f "$c37_aowner" ]]; then
          flag_warn_or_issue "hook-registry-completeness" "$c37_abase declares owner '$c37_aowner', but that owner doc is missing on disk"
          c37_violations=$((c37_violations + 1))
        else
          c37_other_count=$((c37_other_count + 1))
        fi
      done
      # (b) Reverse: every bypass-mode per-hook source maps back to a script that
      #     declares it as its owner (preserves the source⇄script bijection).
      local c37_src
      for c37_src in "$c37_src_dir"/block-*.md; do
        [[ -e "$c37_src" ]] || continue
        local c37_sbase; c37_sbase="$(basename "$c37_src" .md)"
        if [[ ! -f "core/hooks/$c37_sbase.sh" ]]; then
          flag_warn_or_issue "hook-registry-completeness" "per-hook source $c37_src has no backing script core/hooks/$c37_sbase.sh"
          c37_violations=$((c37_violations + 1))
        else
          local c37_back_owner
          c37_back_owner="$(sed -n -E 's/^# hook-owner:[[:space:]]+//p' "core/hooks/$c37_sbase.sh" | head -1)"
          if [[ "$c37_back_owner" != "$c37_src" ]]; then
            flag_warn_or_issue "hook-registry-completeness" "per-hook source $c37_src exists but backing script core/hooks/$c37_sbase.sh does not declare it as owner (declares '$c37_back_owner')"
            c37_violations=$((c37_violations + 1))
          fi
        fi
      done
      if [[ $c37_violations -eq 0 ]]; then
        log "  OK:    $c37_bypass_count bypass-mode hooks ⇄ sources ⇄ index rows; $c37_other_count standalone hooks own-doc resolved"
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
  # Verdict computed by the shared _c38_compute_verdict body (DD1) so the CI probe
  # (--check-required-subset) and this lifecycle check cannot diverge. The body
  # emits any regenerate-and-diff detail to stderr; this block maps the verdict
  # token to the deploy-time emit. Always-enforce (deterministic generator): a
  # STALE/ERROR verdict fails loud (++ISSUES), never silently passing a stale index.
  local c38_verdict c38_tok
  c38_verdict="$(_c38_compute_verdict "lifecycle")"
  c38_tok="${c38_verdict%% *}"
  case "$c38_tok" in
    FRESH)
      log "  OK:    core/rules/bypass-mode-readiness.md is in sync with its sources"
      ;;
    STALE)
      log "  FAIL:  core/rules/bypass-mode-readiness.md is STALE vs its sources — regenerate via 'python3 core/deploy/tools/build-hook-registry.py' and commit"
      ISSUES=$((ISSUES + 1))
      ;;
    *)
      # ERROR <reason> — generator/python3 absent or generator exit >=2; fail loud.
      log "  FAIL:  Check 38 — ${c38_verdict#ERROR }"
      ISSUES=$((ISSUES + 1))
      ;;
  esac

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
        # Parse + compare via the version-grammar SSOT (#1676) rather than a local
        # sed parser (#1800 — retire the last duplicate parser). Source set-e-safe
        # with an empty positional so the lib's --self-test never fires (mirrors
        # Check 41 / _vf_compute_verdict); guard on the lib's presence.
        local c39_lib="$_audit_src_root/release/tools/version-grammar.sh"
        if [[ ! -f "$c39_lib" ]]; then
          log "  N/A:   Check 39 version-grammar.sh (#1676 SSOT comparator) not present — cannot assert version-stamp invariant"
        else
          # shellcheck source=/dev/null
          source "$c39_lib" ""
          if ! version_canonical "$c39_local" || ! version_canonical "$c39_anchor"; then
            flag_warn_or_issue "version-stamp-skew" ".version ('$c39_local') or latest-Release ('$c39_anchor') is not canonical (vMAJOR.MINOR[.PATCH]) — cannot assert version-stamp invariant"
          elif [[ "$(version_cmp "$c39_local" "$c39_anchor")" == "0" ]]; then
            log "  OK:    .version ($c39_local) == latest published Release ($c39_anchor) — version-skew banner clears"
          else
            local c39_l_maj c39_l_min c39_a_maj c39_a_min _c39_patch
            read -r c39_l_maj c39_l_min _c39_patch <<<"$(version_parse "$c39_local")"
            read -r c39_a_maj c39_a_min _c39_patch <<<"$(version_parse "$c39_anchor")"
            if [[ "$c39_l_maj" != "$c39_a_maj" ]]; then
              # Different major-lineage — always FAIL (e.g. .version=v3.x vs published v2.x).
              flag_warn_or_issue "version-stamp-skew" ".version ($c39_local) is a different major-lineage than the latest published Release ($c39_anchor) — wrong version source-of-truth; bump at release cut per stage-13-close.md Phase B5.7"
            else
              # Same lineage — signed minor distance. version_parse already base-10
              # coerces each component, so a zero-padded minor (08/09) is never octal.
              local c39_dist=$(( c39_l_min - c39_a_min ))
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

  # Check 41 — Pre-merge version-freeness (advisory; ratified 2026-08-04; #1677)
  #
  # Gate-efficacy posture (per core/standards/gate-efficacy-standard.md Req (a)+(b)):
  #   posture: advisory (RATIFIED ADVISORY, 2026-08-04 — by design, not warn-mode-initial
  #            awaiting graduation; the durable decision record is the version-freeness row
  #            in gate-efficacy-standard.md § Flip-decision status). The detection posture
  #            was evaluated for enforce-graduation and DECLINED on architectural grounds:
  #            a release's version binds only at the Stage-12 Phase B3 atomic ref-CAS, so a
  #            pre-claim layer cannot be authoritative over it, and no volume of drain
  #            evidence changes that.
  #   enforcement-surface: version-freeness.mode warn-window
  #            (this per-check lifecycle mode is a SEPARATE, still-independently-flippable
  #             knob — the ratification above governs the DETECTION POSTURE and the CI
  #             sentinel, NOT this mode file, and the two are decoupled by design;
  #             the Stage-12 CI gate version-freeness.yml is the merge-blocking surface,
  #             and its .github/version-freeness.enforce sentinel is deliberately absent)
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
  # Candidate-derivation INPUT (slug-primary, founding ADR #1697): _vf_resolve_candidate()
  # reads the ENVIRONMENT ONLY — PMO_VERSION_FREENESS_CANDIDATE (branch 1, the exact
  # always-correct surface), else PMO_VERSION_FREENESS_BUMP routed through the
  # claim-version.sh allocator (branch 2). There is NO plan-file branch: the resolver does
  # not read a release plan, so a carried provisional-display version never reaches this
  # predicate unless it is passed in explicitly via branch 1. Absent BOTH env inputs,
  # SKIP cleanly (absence is not drift) — same posture as Check 40's operator-local SKIP.
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

  # Check 45 — Design-principle conformance integrity (advisory; warn-mode initial; enforcement-surface: deploy-time-only — no CI mirror, Requirement (b′)) [#320]
  #
  # Three single-responsibility assertions:
  #  (a) Conformance-mechanism presence — the **Design-Principle Conformance:**
  #      D-Gate subsection MUST exist in hub-spoke-bridge.md (its absence means the
  #      per-option conformance mechanism, sibling of Upstream compatibility, regressed).
  #  (b) Register governing_doc drift guard (FMF-1, entry-row-scoped) — every
  #      design-principle-register.md ENTRY ROW's governing_doc (path:line) MUST
  #      resolve to a real, non-empty line AND that line MUST contain the entry's
  #      `name` (an existence-only assertion passes a drifted pin silently).
  #      Extraction is scoped to entry rows (^| DP-N ...) so schema/prose path:line
  #      mentions are not self-matched. EVERY extracted row is examined: an empty
  #      cell in either operand column is an incomplete-register-entry FINDING,
  #      never a skip — see the b0 note below for why a skip is the one shape this
  #      sub-check must not have.
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
      local c45_id c45_name c45_target _c45_lead _c45_stmt _c45_rest
      # (b) FMF-1 — entry-row-scoped governing_doc resolution + name-match
      #   Three DISTINCT failure branches, deliberately separate so the mis-pin class
      #   is greppable apart from the unresolvable class:
      #     b0 WELL-FORMED — the entry carries BOTH assertion operands: a non-empty
      #                      `governing_doc` to resolve and a non-empty `name` to
      #                      assert against
      #     b1 RESOLVE     — path exists, line numeric, target line non-empty
      #     b2 NAME-MATCH  — the target line CONTAINS the entry's `name`
      #   b2 is the content assertion. Without it a line-shift silently re-points an
      #   entry at the WRONG principle and still PASSES: measured at c4dde614, a
      #   uniform +1 shift clears 8 of 9 pins under b1 alone and 0 of 9 with b2.
      #   b0 exists because b2's containment is VACUOUSLY TRUE on an empty needle —
      #   a blank `name` cell would invert "must contain" into "always passes", the
      #   precise false-confidence shape b2 was added to remove. b0 covers the
      #   `governing_doc` operand on the SAME grounds and by the SAME guard rather
      #   than a parallel mechanism: an empty cell in EITHER column leaves the entry
      #   unassertable, and an unassertable entry is an INCOMPLETE REGISTER ENTRY
      #   (a finding), never a skip. That widening is the fix for a false-OK defect
      #   this guard's own shape invited: a bare `[[ -z "$c45_gd" ]] && continue`
      #   used to sit ABOVE b0, so a blanked `governing_doc` returned the row to the
      #   loop unexamined AND uncounted — Check 45 emitted zero findings and still
      #   printed its `OK: … all register governing_doc targets resolve …` line,
      #   certifying an entry it never looked at. The declaration is universally
      #   quantified over the entry rows, so the only honest implementation examines
      #   all of them.
      #   STRUCTURAL INVARIANT (the reason this is an if/elif/else and not a tally):
      #   the loop body contains NO `continue`. Every row traverses exactly one arm
      #   of a total decision tree, and every non-terminal arm sets c45_ok=0, so
      #   c45_ok can survive as 1 only when every row was fully asserted. The
      #   unexamined-exit shape is DELETED rather than detected — a skipped-entry
      #   counter would merely notice the skip, and would itself be a second thing
      #   to keep in sync. The fixture self-test asserts this shape directly
      #   (`core/deploy/tests/test_check45_governing_doc_name_match.sh`, the
      #   zero-`continue` structural assertion), so a future edit that reintroduces
      #   an early exit fails that test instead of silently restoring the defect.
      #   Iteration is ROW-scoped (not the former de-duplicated path:line list) —
      #   name-match needs the (name, governing_doc) pair from the SAME row. Fields
      #   split on the markdown pipe: $2=principle_id, $3=name, $5=governing_doc; an
      #   unescaped '|' cannot appear in a markdown cell, so the split is well-defined
      #   (and an escaped one shifts columns → governing_doc resolves to non-path text
      #   → b1 fires loudly; the degenerate case fails closed, never silent).
      #   Containment is the pure-bash `== *"$var"*` form: fixed-string by construction
      #   (a free-text `name` may carry regex metacharacters) and subprocess-free, so
      #   it cannot reintroduce the `… | grep -q` EPIPE class.
      #   Register-side contract: an entry's `name` MUST appear verbatim on its
      #   governing_doc line — the checkable projection of the register's Index-only
      #   discipline, documented at core/standards/design-principle-register.md.
      _c45_trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
      while IFS='|' read -r _c45_lead c45_id c45_name _c45_stmt c45_gd _c45_rest; do
        c45_id="$(_c45_trim "$c45_id")"
        c45_name="$(_c45_trim "$c45_name")"
        c45_gd="$(_c45_trim "$c45_gd")"
        if [[ -z "$c45_gd" ]]; then
          flag_warn_or_issue "design-principle-conformance" "register entry has no governing_doc: '$c45_id' ('$c45_name') has an empty governing_doc cell — there is no pin to resolve, so the entry cannot be asserted at all; fill the governing_doc cell"
          c45_ok=0
        elif [[ -z "$c45_name" ]]; then
          flag_warn_or_issue "design-principle-conformance" "register entry has no name: '$c45_id' pins '$c45_gd' but its name cell is empty — the name-match assertion would pass vacuously; fill the name cell"
          c45_ok=0
        else
          c45_path="${c45_gd%%:*}"
          c45_line="${c45_gd##*:}"
          c45_target=""
          if [[ -f "$c45_path" ]] && [[ "$c45_line" =~ ^[0-9]+$ ]]; then
            c45_target="$(sed -n "${c45_line}p" "$c45_path" 2>/dev/null)"
          fi
          if [[ ! -f "$c45_path" ]] || ! [[ "$c45_line" =~ ^[0-9]+$ ]] || [[ -z "$c45_target" ]]; then
            flag_warn_or_issue "design-principle-conformance" "register governing_doc does not resolve to a real path:line: '$c45_gd' ($c45_id) (drift — repoint to the principle's current normative line)"
            c45_ok=0
          elif [[ "$c45_target" != *"$c45_name"* ]]; then
            flag_warn_or_issue "design-principle-conformance" "register governing_doc MIS-PIN (name-match): $c45_id '$c45_name' pins '$c45_gd', but that line does not contain the entry name — the pin resolves to a DIFFERENT principle (repoint it to the principle's current normative line)"
            c45_ok=0
          fi
        fi
      done < <(grep -E '^\| DP-[0-9]' "$c45_reg")
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
    [[ "$c45_ok" -eq 1 ]] && log "  OK:    conformance subsection present; all register governing_doc targets resolve AND name their own principle; all DP-id references defined"
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


  # Check 50 — Platform-doc frontmatter standard (global committed-default enforce) [#2220 gate; #2221 flip]
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
  # SHIP POSTURE — GLOBAL COMMITTED-DEFAULT ENFORCE (#2221 scope-lock, Approach D):
  # #2220 shipped warn-mode across core/ with a split partition (Tier-A enforce leg
  # dormant, tier-other warn-only) and the enforce-flip deferred to #2221. #2221
  # backfilled the remaining non-ADR core/ docs to 0 findings and flips this gate
  # ON: the tier partition COLLAPSES — every finding (Tier A and other alike)
  # routes to a hard FAIL in enforce. Activation is the COMMITTED DEFAULT (c50_mode
  # is hardcoded "enforce" below, NOT resolved from an un-committed
  # doc-frontmatter.mode file), so any clone enforces — a fresh non-conformant
  # core/ doc FAILs deploy.sh --check. The global DEPLOY_CHECK_MODE=off kill-switch
  # (the outer guard on this block) is deliberately RETAINED so the gate stays
  # disable-able in an emergency, not un-disableable.
  # SCAN SURFACE — the precise authored-doc subtree globs (c50_targets below):
  # core/ADRs/ (disjoint ADR schema, routed to #1488) and **/tests/fixtures/** are
  # excluded BY CONSTRUCTION (the tool has no glob-exclude, so we enumerate authored
  # subtrees rather than recursive core/**, which would drag in ~17 fixtures).
  # enforce-graduation per bypass-mode-readiness.md §Shakedown (the 14/18/42/43
  # precedent); the introducing release is itself exempt (reflexive-pipeline loop).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 50: Platform-doc frontmatter standard (global enforce; committed-default per #2221, DEPLOY_CHECK_MODE=off kill-switch retained)"
    local c50_script="core/deploy/tools/check-doc-frontmatter.py"
    local c50_allowlist="core/deploy/allowlists/skip-doc-frontmatter-check.txt"
    if [[ ! -f "$c50_script" ]]; then
      flag_warn_or_issue "doc-frontmatter" "primitive script missing: $c50_script"
    else
      # APPROACH D (#2221 scope-lock): committed-default enforce. c50_mode is
      # hardcoded "enforce" — the gate does NOT depend on an un-committable
      # doc-frontmatter.mode file to activate, so any clone enforces the flipped
      # gate. The global DEPLOY_CHECK_MODE=off kill-switch (the outer guard on this
      # whole block) is deliberately RETAINED so the gate is not un-disableable;
      # setting DEPLOY_CHECK_MODE=off skips Check 50 entirely.
      local c50_mode="enforce"
      # Scan surface = the precise authored-doc subtree globs (#2221 Edit 1): the
      # six Tier-A governance-class dirs + core/skills/**/references + the added
      # non-Tier-A authored subtrees (core/*.md, core/deploy/tools/*.md,
      # core/diagrams/*.md, core/packs/*.md, core/references/**/*.md). NOT added:
      # core/ADRs/ (disjoint ADR schema, routed to #1488) or any recursive core/**
      # glob — the tool has NO glob-exclude, so a recursive glob would drag in ~17
      # test-fixture .md under **/tests/fixtures/** that all flag against the
      # standard. Enumerate authored subtrees, not core/** (validated: 0 fixtures).
      local c50_targets="core/standards/**/*.md,core/schemas/**/*.md,core/specs/**/*.md,core/disciplines/**/*.md,core/rules/**/*.md,core/governance/**/*.md,core/*.md,core/deploy/tools/*.md,core/diagrams/*.md,core/packs/*.md,core/references/**/*.md,core/skills/**/references/*.md"
      local c50_out c50_exit=0
      c50_out=$(/usr/bin/python3 "$c50_script" --target-paths "$c50_targets" --allowlist "$c50_allowlist" --output-format tsv 2>&1) || c50_exit=$?
      if [[ $c50_exit -eq 3 ]]; then
        flag_warn_or_issue "doc-frontmatter" "path-resolution failure (exit 3): $(echo "$c50_out" | head -1) — a --target-paths glob or --catalog-path resolved to zero files; fix the glob list in this check"
      elif [[ $c50_exit -eq 0 || $c50_exit -eq 1 ]]; then
        # Partition findings on the tier column (TSV row 2 is the header;
        # data rows: file<TAB>tier<TAB>field<TAB>violation<TAB>severity).
        local c50_a c50_o c50_total
        c50_a=$(echo "$c50_out" | awk -F'\t' 'NR>2 && $2=="A"'     | grep -c . || true)
        c50_o=$(echo "$c50_out" | awk -F'\t' 'NR>2 && $2=="other"' | grep -c . || true)
        c50_a=${c50_a:-0}; c50_o=${c50_o:-0}
        c50_total=$((c50_a + c50_o))
        if [[ "$c50_total" -eq 0 ]]; then
          log "  OK:    all scanned core/ docs carry conformant frontmatter"
        elif [[ "$c50_mode" == "enforce" ]]; then
          # #2221 PARTITION COLLAPSE: in enforce mode BOTH tiers (A and other)
          # route to one hard FAIL. The split Tier-A-enforce / tier-other-warn
          # partition #2220 shipped has collapsed to a single global-enforce verdict.
          log "  FAIL:  doc-frontmatter — $c50_total frontmatter violation(s) (global enforce, #2221). Fix per core/standards/platform-doc-frontmatter-standard.md."
          echo "$c50_out" | awk -F'\t' 'NR>2' | head -20 | sed 's/^/         /'
          ISSUES=$((ISSUES + 1))
        else
          # Retained warn dispatcher (the #2220 shakedown shape). Unreached while
          # c50_mode is the committed-default "enforce" above; preserved so a future
          # soften-to-warn is a one-line mode change, not a structural re-add.
          (( c50_a > 0 )) && flag_warn_or_issue "doc-frontmatter" "$c50_a Tier-A frontmatter violation(s) (warn-mode)"
          (( c50_o > 0 )) && flag_warn_or_issue "doc-frontmatter" "$c50_o non-Tier-A frontmatter violation(s) (warn-mode)"
          echo "$c50_out" | awk -F'\t' 'NR>2' | head -20 | sed 's/^/         /'
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


  # Check 52 — Milestone-position drift (warn-mode initial)
  #
  # Re-derives every open milestone's `position:` from the live dependency graph
  # (the same Kahn's-BFS derivation the producer tool applies) and WARNs for each
  # milestone whose current `position:` line differs from the re-derived value —
  # the drift the live G3-07 "Milestone-Position Resolution" gate would otherwise
  # silently resolve via its fallback tier. Read-only: the drift probe mutates
  # nothing (the fix is an operator-run `compute-milestone-positions.py --apply`);
  # reversibility CHEAP. The derivation DEFINITION is not redefined here — it lives
  # in the tool and is REFERENCED via `--check-drift`, per the card's AC scope.
  # Warn-mode initial per core/rules/bypass-mode-readiness.md §Shakedown (the
  # 14/18/42/43/50/51/53 precedent): drift is emitted as a non-blocking WARN during
  # calibration. Reflexive cutover clause (AC10): the drift check applies to
  # milestones entering Stage 3 strictly AFTER this tool's introducing-release
  # merge SHA (recorded in the release log); the introducing release is itself
  # exempt (reflexive-pipeline loop — the check does not fire on its own
  # introducing release's positions). Flip to enforce via a `milestone-position.mode`
  # file after the >=3-day warn-log review — "enforce" there means the drift finding
  # increments ISSUES (dep-order drift becomes a gating signal); it does NOT change
  # what is derived. gh-unavailable → SKIP (the derivation needs the live milestone
  # + issue set; mirrors Check 39/40/51/53 offline SKIP). Primitive:
  # release/tools/compute-milestone-positions.py --check-drift.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 52: Milestone-position drift (warn-mode initial; enforce-flip deferred)"
    local c52_script="release/tools/compute-milestone-positions.py"
    if [[ ! -f "$c52_script" ]]; then
      flag_warn_or_issue "milestone-position" "primitive script missing: $c52_script"
    elif ! command -v gh >/dev/null 2>&1; then
      log "  SKIP:  gh unavailable — milestone-position drift needs the live milestone + issue set (offline/unauth; mirrors Check 39/40/51/53)"
    else
      local c52_mode
      c52_mode=$(resolve_check_mode "milestone-position")
      local c52_out c52_exit=0
      c52_out=$(/usr/bin/python3 "$c52_script" --check-drift --output-format tsv 2>&1) || c52_exit=$?
      if [[ $c52_exit -eq 3 ]]; then
        flag_warn_or_issue "milestone-position" "input failure (exit 3): $(echo "$c52_out" | head -1) — the live milestone/issue set was unreadable; fix gh auth/connectivity"
      elif [[ $c52_exit -eq 0 ]]; then
        log "  OK:    all open milestone positions match the re-derived dep-graph order — no drift"
      elif [[ $c52_exit -eq 1 ]]; then
        local c52_count c52_drift
        c52_count=$(echo "$c52_out" | awk -F'\t' '$1=="COUNT"{print $2}')
        c52_drift=$(echo "$c52_out" | awk -F'\t' '$1=="DRIFT"{print $2}' | paste -sd, -)
        if [[ "$c52_mode" == "enforce" ]]; then
          log "  FAIL:  milestone-position — ${c52_count} milestone(s) drift from the re-derived dep-graph order:"
          log "           ${c52_drift:-(none)}"
          ISSUES=$((ISSUES + 1))
        else
          flag_warn_or_issue "milestone-position" "${c52_count} milestone(s) drift from the re-derived dep-graph order — run compute-milestone-positions.py --apply (warn-mode; flip milestone-position.mode to enforce after shakedown). drift: ${c52_drift:-(none)}"
        fi
      else
        flag_warn_or_issue "milestone-position" "check errored (exit $c52_exit): $(echo "$c52_out" | head -1)"
      fi
    fi
  fi


  # Check 53 — Approved-queue-depth monitor (warn-mode initial)
  #
  # The active DETECTOR behind the Stage-3 Bundle A7 "T1 Approved-queue depth"
  # refresh trigger. Counts the open approved-but-unbundled queue (issues with
  # `status: approved` AND no milestone) and, at/above the bundling threshold
  # (default 5), emits an ACTIONABLE bundle-candidate summary — count + themes
  # (from cluster:/project: labels) + priorities — so the operator sees a
  # ready-to-triage bundle candidate at the moment they act on the platform,
  # not just a raw number. The threshold DEFINITION lives in the Stage-3 Bundle
  # definition (Phase B4: "threshold-triggered (5+ Approved)") and is REFERENCED
  # via --threshold, not redefined here (per the card's AC scope).
  # Read-only: counts issue state, mutates nothing (no issue-state or corpus
  # write). Reversibility CHEAP — additive; `git revert`.
  # Warn-mode initial per core/rules/bypass-mode-readiness.md §Shakedown (the
  # 14/18/42/43/50/51 precedent): the exit-1 "bundle candidate" finding is
  # emitted as a non-blocking WARN during calibration. The queue is ~29 today
  # (>=5) → this check FIRES on first run; warn-mode is exactly what keeps that
  # non-blocking. Flip to enforce via an `approved-queue-depth.mode` file after
  # the >=3-day warn-log review — BUT note "enforce" here means the finding
  # increments ISSUES (a full/over-threshold queue becomes a gating signal that
  # a bundle is overdue); it does NOT change what is counted. The introducing
  # release is itself exempt (reflexive-pipeline loop — the monitor does not
  # fire on its own introducing release's approved-queue state).
  # gh-unavailable → SKIP (the count needs the live issue set; mirrors Check
  # 39/40/51 offline SKIP). Primitive: core/deploy/tools/check-approved-queue-depth.py.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 53: Approved-queue-depth monitor (warn-mode initial; enforce-flip deferred)"
    local c53_script="core/deploy/tools/check-approved-queue-depth.py"
    local c53_threshold=5
    if [[ ! -f "$c53_script" ]]; then
      flag_warn_or_issue "approved-queue-depth" "primitive script missing: $c53_script"
    elif ! command -v gh >/dev/null 2>&1; then
      log "  SKIP:  gh unavailable — approved-queue-depth needs the live issue set (offline/unauth; mirrors Check 39/40/51)"
    else
      local c53_mode
      c53_mode=$(resolve_check_mode "approved-queue-depth")
      local c53_out c53_exit=0
      c53_out=$(/usr/bin/python3 "$c53_script" --threshold "$c53_threshold" --output-format tsv 2>&1) || c53_exit=$?
      if [[ $c53_exit -eq 3 ]]; then
        flag_warn_or_issue "approved-queue-depth" "input failure (exit 3): $(echo "$c53_out" | head -1) — the live approved-unbundled queue was unreadable; fix gh auth/connectivity"
      elif [[ $c53_exit -eq 0 ]]; then
        local c53_count
        c53_count=$(echo "$c53_out" | awk -F'\t' '$1=="COUNT"{print $2}')
        log "  OK:    approved-unbundled queue depth ${c53_count:-0} < threshold $c53_threshold — not a bundle candidate"
      elif [[ $c53_exit -eq 1 ]]; then
        local c53_count c53_themes c53_prios
        c53_count=$(echo "$c53_out"  | awk -F'\t' '$1=="COUNT"{print $2}')
        c53_themes=$(echo "$c53_out" | awk -F'\t' '$1=="THEMES"{print $2}')
        c53_prios=$(echo "$c53_out"  | awk -F'\t' '$1=="PRIORITIES"{print $2}')
        if [[ "$c53_mode" == "enforce" ]]; then
          log "  FAIL:  approved-queue-depth — $c53_count approved-unbundled issue(s) >= threshold $c53_threshold; a bundle is overdue:"
          log "           themes:     ${c53_themes:-(none)}"
          log "           priorities: ${c53_prios:-(none)}"
          ISSUES=$((ISSUES + 1))
        else
          flag_warn_or_issue "approved-queue-depth" "$c53_count approved-unbundled issue(s) >= threshold $c53_threshold — BUNDLE CANDIDATE (warn-mode; flip approved-queue-depth.mode to enforce after shakedown). themes: ${c53_themes:-(none)}; priorities: ${c53_prios:-(none)}"
        fi
      else
        flag_warn_or_issue "approved-queue-depth" "check errored (exit $c53_exit): $(echo "$c53_out" | head -1)"
      fi
    fi
  fi

  # Check 54 — Ownership-collision reconciliation (ADR-044 I1+I3+I4; warn-mode initial)
  #
  # Reconciles the §6 owning-agent matrix (project-entity-model.md) against the
  # per-skill output declarations (per-skill-output-contracts.md) + the rendering
  # set (operational-artifact-inventory.md), and ESCALATES a would-be SECOND
  # maintainer — never a producer (ADR-044's "many producers, one maintainer" is
  # the governed pattern). Creates no ownership store; reconciles existing SSOTs.
  # Offline-safe: pure local corpus parse — no `gh`, so no SKIP leg (unlike Check
  # 53). Read-only; reversibility CHEAP (new primitive + revertible block;
  # `ownership-collision.mode`=off disables). Sibling deploy-primitive per ADR-068
  # (run_eval_audit.py untouched). Warn-mode initial per
  # core/rules/bypass-mode-readiness.md (the 14/18/42/43/50/51/53 precedent): the
  # exit-1 "collision" finding is a non-blocking WARN during calibration. The
  # current suite has zero duplicate maintainers -> 0 collisions by construction,
  # so this check is silent-PASS on first run; warn-mode keeps a future finding
  # non-blocking until the >=3-day review flips ownership-collision.mode to
  # enforce (enforce = the finding increments ISSUES; the count of what is checked
  # is unchanged). Primitive: core/deploy/tools/check-ownership-collision.py.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 54: Ownership-collision reconciliation (ADR-044 I1+I3+I4; warn-mode initial; enforce-flip deferred)"
    local c54_script="core/deploy/tools/check-ownership-collision.py"
    if [[ ! -f "$c54_script" ]]; then
      flag_warn_or_issue "ownership-collision" "primitive script missing: $c54_script"
    else
      local c54_mode
      c54_mode=$(resolve_check_mode "ownership-collision")
      local c54_out c54_exit=0
      c54_out=$(/usr/bin/python3 "$c54_script" --output-format tsv 2>&1) || c54_exit=$?
      if [[ $c54_exit -eq 3 ]]; then
        flag_warn_or_issue "ownership-collision" "input failure (exit 3): $(echo "$c54_out" | head -1) — a required corpus surface (§6 matrix / output-contracts / inventory) was missing or unparseable; fix the surface/parser"
      elif [[ $c54_exit -eq 0 ]]; then
        local c54_ent
        c54_ent=$(echo "$c54_out" | awk -F'\t' '$1=="ENTITIES_CHECKED"{print $2}')
        log "  OK:    ownership-collision — 0 collisions across ${c54_ent:-0} entities (producers reconciled as producers vs single maintainers)"
      elif [[ $c54_exit -eq 1 ]]; then
        local c54_count c54_detail
        c54_count=$(echo "$c54_out"  | awk -F'\t' '$1=="COLLISIONS"{print $2}')
        c54_detail=$(echo "$c54_out" | awk -F'\t' '$1=="DETAIL"{print $2}' | paste -sd';' - | sed 's/;/; /g')
        if [[ "$c54_mode" == "enforce" ]]; then
          log "  FAIL:  ownership-collision — $c54_count second-maintainer/contradiction collision(s): ${c54_detail:-(see detail)}"
          ISSUES=$((ISSUES + 1))
        else
          flag_warn_or_issue "ownership-collision" "$c54_count ownership collision(s) (warn-mode; flip ownership-collision.mode to enforce after shakedown): ${c54_detail:-(see detail)}"
        fi
      else
        flag_warn_or_issue "ownership-collision" "check errored (exit $c54_exit): $(echo "$c54_out" | head -1)"
      fi
    fi
  fi


  # Check 55 — Work-hierarchy drift gate (warn-mode initial) [#1039]
  #
  # Two independent invariants, one check (the Check-16 multi-invariant shape):
  #   H1 DOC     — no normative governance doc ASSERTS a banned parent tier
  #                (`Initiative` / `Roadmap`, per ADR-049 §Decision 1/2) above a
  #                licensed work-item kind. The licensed kind vocabulary is DERIVED
  #                from the SSOT (core/packs/*/pack.toml `kind_id`), never hardcoded.
  #   H2 BACKLOG — no open `type:epic` issue has a `type:epic` parent, resolved via
  #                ONE batched+paginated GraphQL query over the native sub-issue
  #                `parent` edge (never an N+1 per-epic loop — with ~39 open epics
  #                an N+1 shape would materially slow --check).
  # Predicate shape: closed-vocabulary membership inside a STRUCTURAL arrow-chain,
  # not prose similarity — falsifiable, no paraphrase false-positive tail. A
  # citation guard suppresses chains inside quotes/backticks (a CITED or NEGATED
  # ladder is not an assertion; the live corpus contains exactly this case at
  # architecture-evaluative-lens.md:45). Matching is case-sensitive: Title-Case =
  # hierarchy tier, lowercase = label namespace (ADR-049's own `initiative->epic`
  # label-mapping title must not read as a hierarchy violation).
  # Exemption: .claude/work-hierarchy-exemption-list.txt — lines of `<path> <token>`
  # (H1) or `#<issue> type:epic` (H2), mirroring Check 16's exempt_pair shape; this
  # is #1039's "allowlist-able during cutover" requirement. The H2 form is parsed
  # as an ENTRY, not a comment (`#` + digits + whitespace); the bare `<issue>
  # <token>` form is accepted too, since both normalize to one lookup key. The
  # primitive's self-test round-trips a real exemption file through the loader, so
  # neither leg of that parse can silently regress.
  # Fail-loud: an unreadable SSOT vocabulary (zero kinds) exits 3 rather than
  # reading green — a zero-vocabulary scan would find nothing by construction.
  # gh-unavailable → H2 SKIPs with a logged reason (mirrors Check 39/40/51/52/53
  # offline SKIP); H1 still runs (it is offline-capable). A backlog invariant must
  # never read green offline.
  # Warn-mode initial per core/rules/bypass-mode-readiness.md §Shakedown (the
  # 14/18/42/43/50/51/52/53/54 precedent); flip via a `work-hierarchy-drift.mode`
  # file after the >=3-day warn-log review. The introducing release is itself
  # exempt (reflexive-pipeline loop). Read-only: mutates nothing; reversibility
  # CHEAP (additive; `git revert`).
  # Primitive: core/deploy/tools/check-work-hierarchy.py (carries --self-test).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 55: Work-hierarchy drift (H1 doc + H2 backlog; warn-mode initial; enforce-flip deferred)"
    local c55_script="core/deploy/tools/check-work-hierarchy.py"
    if [[ ! -f "$c55_script" ]]; then
      flag_warn_or_issue "work-hierarchy-drift" "primitive script missing: $c55_script"
    else
      local c55_mode c55_args
      c55_mode=$(resolve_check_mode "work-hierarchy-drift")
      c55_args=(--root . --repo "$AUDIT_REPO" --output-format tsv)
      if ! command -v gh >/dev/null 2>&1; then
        log "  SKIP:  H2 backlog leg — gh unavailable (offline/unauth; mirrors Check 39/40/51/52/53). H1 doc leg still runs."
        c55_args+=(--skip-backlog)
      fi
      local c55_out c55_exit=0
      c55_out=$(/usr/bin/python3 "$c55_script" "${c55_args[@]}" 2>&1) || c55_exit=$?
      if [[ $c55_exit -eq 3 ]]; then
        flag_warn_or_issue "work-hierarchy-drift" "input failure (exit 3): $(echo "$c55_out" | head -1) — the SSOT kind vocabulary was unreadable or the GraphQL parent scan failed; fix the pack corpus / gh auth"
      elif [[ $c55_exit -eq 0 ]]; then
        local c55_scanned
        c55_scanned=$(echo "$c55_out" | awk -F'\t' '$1=="SCANNED"{print $2}')
        log "  OK:    work-hierarchy — 0 drift findings (${c55_scanned:-0} normative docs scanned; no banned parent tier, no epic-under-epic edge)"
      elif [[ $c55_exit -eq 1 ]]; then
        local c55_h1 c55_h2
        c55_h1=$(echo "$c55_out" | awk -F'\t' '$1=="H1"{print $2}' | paste -sd, -)
        c55_h2=$(echo "$c55_out" | awk -F'\t' '$1=="H2"{print "#"$2"->#"$3}' | paste -sd, -)
        if [[ "$c55_mode" == "enforce" ]]; then
          [[ -n "$c55_h1" ]] && { log "  FAIL:  work-hierarchy H1 — doc(s) asserting a banned parent tier: $c55_h1"; ISSUES=$((ISSUES + 1)); }
          [[ -n "$c55_h2" ]] && { log "  FAIL:  work-hierarchy H2 — epic-under-epic edge(s): $c55_h2"; ISSUES=$((ISSUES + 1)); }
        else
          [[ -n "$c55_h1" ]] && flag_warn_or_issue "work-hierarchy-drift" "H1 doc invariant — banned parent tier asserted at: $c55_h1 (warn-mode; flip work-hierarchy-drift.mode to enforce after shakedown)"
          [[ -n "$c55_h2" ]] && flag_warn_or_issue "work-hierarchy-drift" "H2 backlog invariant — epic-under-epic edge(s): $c55_h2 (warn-mode; re-parent or exempt)"
        fi
      else
        flag_warn_or_issue "work-hierarchy-drift" "check errored (exit $c55_exit): $(echo "$c55_out" | head -1)"
      fi
    fi
  fi


  # Check 56 — Milestone↔epic membership (warn-mode initial) [#2219]
  #
  # Two legs, DIFFERENT severities (the #749 asymmetric-severity precedent):
  #   M1 membership     — for each open milestone that DECLARES an epic
  #                       (`<!-- milestone-epic: #N -->` or `**Epic:** #N`), every
  #                       open non-sub-task child's parent-epic must equal it, unless
  #                       the child body carries `<!-- milestone-epic: allow -->`.
  #                       A milestone with NO declared epic is SKIPPED, never failed.
  #                       ENFORCE-capable leg (resolve_check_mode).
  #   M2 reconciliation — the description's `### Scope` card list vs live membership;
  #                       WARN-ONLY, never enforce-capable. A description legitimately
  #                       lags membership mid-release; gating it would make it
  #                       chronically non-green. Emitted as its own sub-invariant.
  # The two legs read DIFFERENT membership sets, deliberately. M1 is OPEN-scoped: it
  # asks a live-drift question, and a completed card's parent-epic is history. M2's
  # set spans ALL issue states, because an OPEN-only set cannot tell "the Scope names
  # a card that is DONE" (benign) from "the Scope names a card that is NOT in this
  # milestone" (the divergence M2 exists to report) — it renders both as
  # named-not-member and puts a false positive on an already-advisory leg.
  # Sub-tasks are excluded from both legs (pipeline scaffolding, no parent-epic by
  # design; counting them would make M2 permanently non-green).
  # Placement: deploy.sh --check per D-A (sibling to Check 16's gh+jq invariant
  # pattern; repo-integrity.yml rejected as altitude mismatch — membership is
  # repo-state, not a PR-diff property). ONE batched+paginated GraphQL issue query
  # + one milestones REST call + ONE batched membership query scoped THROUGH the
  # open milestones — not an N+1 per-milestone loop. Scoping the all-states
  # membership fetch through the milestones (rather than scanning every issue in
  # the repository) is what keeps it cheap: measured 1.3s vs 16.5s, with zero
  # membership divergence between the two over the open-milestone population.
  # ADOPTION NOTE: 0 of 46 open milestones declare an epic today, so M1 SKIPs
  # universally and is INERT until descriptions adopt the marker (reported as
  # DECLARED 0, not a silent green). M2 fires on the ~16 milestones whose
  # description lags membership — warn-mode is exactly what keeps that non-blocking.
  # gh-unavailable → SKIP (needs the live milestone + issue set; mirrors Check
  # 39/40/51/52/53). Warn-mode initial per bypass-mode-readiness.md §Shakedown;
  # flip via `milestone-epic-membership.mode` after the >=3-day review. The
  # introducing release is itself exempt (reflexive-pipeline loop). Read-only;
  # reversibility CHEAP. Primitive: core/deploy/tools/check-milestone-epic-membership.py
  # (carries --self-test).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 56: Milestone↔issue-population invariants (M1 membership + M2 reconciliation + M3 scaffold-completeness (advisory); warn-mode initial; enforce-flip deferred)"
    local c56_script="core/deploy/tools/check-milestone-epic-membership.py"
    if [[ ! -f "$c56_script" ]]; then
      flag_warn_or_issue "milestone-epic-membership" "primitive script missing: $c56_script"
    elif ! command -v gh >/dev/null 2>&1; then
      log "  SKIP:  gh unavailable — milestone↔epic membership needs the live milestone + issue set (offline/unauth; mirrors Check 39/40/51/52/53)"
    else
      local c56_mode c56_out c56_exit=0
      c56_mode=$(resolve_check_mode "milestone-epic-membership")
      c56_out=$(/usr/bin/python3 "$c56_script" --repo "$AUDIT_REPO" --output-format tsv 2>&1) || c56_exit=$?
      if [[ $c56_exit -eq 3 ]]; then
        flag_warn_or_issue "milestone-epic-membership" "input failure (exit 3): $(echo "$c56_out" | head -1) — the live milestone/issue set was unreadable; fix gh auth/connectivity"
      elif [[ $c56_exit -eq 0 || $c56_exit -eq 1 ]]; then
        local c56_declared c56_m1 c56_m2
        c56_declared=$(echo "$c56_out" | awk -F'\t' '$1=="DECLARED"{print $2}')
        c56_m1=$(echo "$c56_out" | awk -F'\t' '$1=="M1"{print "ms#"$2":#"$3"(parent #"$4"!=epic #"$5")"}' | paste -sd'; ' -)
        c56_m2=$(echo "$c56_out" | awk -F'\t' '$1=="M2"{print "ms#"$2}' | paste -sd, -)
        if [[ -z "$c56_m1" && -z "$c56_m2" ]]; then
          log "  OK:    milestone↔epic membership — no drift (${c56_declared:-0} milestone(s) declare an epic; M2 reconciliation clean)"
        else
          # M1 — enforce-capable
          if [[ -n "$c56_m1" ]]; then
            if [[ "$c56_mode" == "enforce" ]]; then
              log "  FAIL:  milestone-epic M1 — cross-epic child(ren): $c56_m1"
              ISSUES=$((ISSUES + 1))
            else
              flag_warn_or_issue "milestone-epic-membership" "M1 membership — cross-epic child(ren) (warn-mode; flip milestone-epic-membership.mode to enforce after shakedown): $c56_m1"
            fi
          fi
          # M2 — warn-only ALWAYS (never gates, independent of mode)
          if [[ -n "$c56_m2" ]]; then
            flag_warn_or_issue "milestone-epic-membership" "M2 reconciliation (warn-only; advisory) — description↔membership divergence on: $c56_m2"
          fi
        fi
        # M3 — scaffold completeness. Routed through flag_advisory_only, NOT
        # flag_warn_or_issue: this leg's predicate cannot distinguish a genuine
        # scaffold gap from a milestone that legitimately gained a card after
        # scaffolding, so it belongs to the class that reports and never gates.
        # flag_advisory_only has no mode case and no ISSUES increment, so M3
        # cannot be flipped to FAIL when the shared cohort graduates — the
        # constraint is a property of the emitter, not a default someone can flip.
        # No new check number and no new mode dial: M3 is a leg of Check 56.
        local c56_m3 c56_m3_adv c56_marker
        c56_m3=$(echo "$c56_out" | awk -F'\t' '$1=="M3"{print "ms#"$2":"$3" "$4}' | paste -sd'; ' -)
        c56_m3_adv=$(echo "$c56_out" | awk -F'\t' '$1=="COUNT_M3_ADV"{print $2}')
        c56_marker=$(echo "$c56_out" | awk -F'\t' '$1=="SCAFFOLD_MARKER"{print "ms#"$2" "$3}' | paste -sd', ' -)
        if [[ -n "$c56_m3" ]]; then
          flag_advisory_only "milestone-scaffold-completeness" "M3 scaffold completeness — load-bearing finding(s): $c56_m3 [advisory ${c56_m3_adv:-0}; marker adoption ${c56_marker:-none}]"
        else
          log "  OK:    milestone scaffold completeness (M3) — 0 load-bearing finding(s) (${c56_m3_adv:-0} advisory; marker adoption ${c56_marker:-none})"
        fi
      else
        flag_warn_or_issue "milestone-epic-membership" "check errored (exit $c56_exit): $(echo "$c56_out" | head -1)"
      fi
    fi
  fi


  # Check 57 — deploy.sh check-roster extraction-contract (warn-mode initial) [#2106]
  #
  # skill-deployment.md publishes ONE derive-from-source command for the live check
  # set (grep -oE 'log "Check [0-9]+...' core/deploy/deploy.sh) INSTEAD of a
  # hand-maintained enumeration — that enumeration was REMOVED by f0a0516 (#2095), so
  # re-adding a doc-side marker would re-create the exact duplicate surface the removal
  # eliminated (a register-or-remove violation, hence #2106's D-C re-scope). The
  # command is only correct while two deploy.sh conventions hold for EVERY check:
  #   (1) a runtime `log "Check N:"` EMITTER line, and
  #   (2) a `# Check N` DEFINITION-BLOCK comment header.
  # A check that follows one convention but not the other makes the documented command
  # under- or over-report, silently falsifying the doc's single-source-of-truth claim
  # with no enumeration anywhere to visibly drift. This check asserts the contract —
  # E == (D \ R), where D = def-blocks, R = RETIRED-reserved numbers, E = emitters.
  # SELF-REFERENTIAL: this very check carries both a `# Check 57` block and a
  # `log "Check 57:"` emitter, so it satisfies its own contract. Offline-capable
  # (reads deploy.sh itself; no gh). Fail-loud: a zero-check parse exits 3 rather than
  # reading green (the conventions moved). Warn-mode initial per bypass-mode-readiness.md
  # §Shakedown (the 14/18/42/.../55/56 precedent); flip via an `extraction-contract.mode`
  # file after the >=3-day warn-log review. The introducing release is itself exempt
  # (reflexive-pipeline loop). Read-only; reversibility CHEAP (additive; git revert).
  # Primitive: core/deploy/tools/check-extraction-contract.py (carries --self-test).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 57: Check-roster extraction-contract (emitters vs def-blocks minus retired; warn-mode initial; enforce-flip deferred)"
    local c57_script="core/deploy/tools/check-extraction-contract.py"
    if [[ ! -f "$c57_script" ]]; then
      flag_warn_or_issue "extraction-contract" "primitive script missing: $c57_script"
    else
      local c57_mode c57_out c57_exit=0
      c57_mode=$(resolve_check_mode "extraction-contract")
      c57_out=$(/usr/bin/python3 "$c57_script" --root . --output-format tsv 2>&1) || c57_exit=$?
      if [[ $c57_exit -eq 3 ]]; then
        flag_warn_or_issue "extraction-contract" "input failure (exit 3): $(echo "$c57_out" | head -1) — zero checks parsed; the '# Check N' / 'log \"Check N:\"' conventions may have moved, leaving the documented derive command unverifiable"
      elif [[ $c57_exit -eq 0 ]]; then
        local c57_def c57_emit
        c57_def=$(echo "$c57_out" | awk -F'\t' '$1=="DEFBLOCKS"{print $2}')
        c57_emit=$(echo "$c57_out" | awk -F'\t' '$1=="EMITTERS"{print $2}')
        log "  OK:    extraction-contract — emitters match def-blocks (${c57_emit:-?} emitters, ${c57_def:-?} def-blocks; the documented derive-from-source command is complete)"
      elif [[ $c57_exit -eq 1 ]]; then
        local c57_me c57_md c57_re
        c57_me=$(echo "$c57_out" | awk -F'\t' '$1=="MISSING_EMITTER"{print $2}' | paste -sd, -)
        c57_md=$(echo "$c57_out" | awk -F'\t' '$1=="MISSING_DEFBLOCK"{print $2}' | paste -sd, -)
        c57_re=$(echo "$c57_out" | awk -F'\t' '$1=="RETIRED_EMITTING"{print $2}' | paste -sd, -)
        if [[ "$c57_mode" == "enforce" ]]; then
          [[ -n "$c57_me" ]] && { log "  FAIL:  extraction-contract — check(s) with a def-block but NO log emitter (invisible to the documented command): $c57_me"; ISSUES=$((ISSUES + 1)); }
          [[ -n "$c57_md" ]] && { log "  FAIL:  extraction-contract — check(s) that log but carry NO def-block: $c57_md"; ISSUES=$((ISSUES + 1)); }
          [[ -n "$c57_re" ]] && { log "  FAIL:  extraction-contract — RETIRED number(s) still emitting: $c57_re"; ISSUES=$((ISSUES + 1)); }
        else
          [[ -n "$c57_me" ]] && flag_warn_or_issue "extraction-contract" "def-block without emitter (invisible to the documented derive command): Check(s) $c57_me (warn-mode; add a 'log \"Check N:\"' line or flip extraction-contract.mode)"
          [[ -n "$c57_md" ]] && flag_warn_or_issue "extraction-contract" "emitter without def-block: Check(s) $c57_md (warn-mode; add a '# Check N' block)"
          [[ -n "$c57_re" ]] && flag_warn_or_issue "extraction-contract" "RETIRED number still emitting: Check(s) $c57_re (warn-mode; retire the emitter or un-reserve the number)"
        fi
      else
        flag_warn_or_issue "extraction-contract" "check errored (exit $c57_exit): $(echo "$c57_out" | head -1)"
      fi
    fi
  fi

  # Check 58 — ADR ratification-flip backstop (ADVISORY ONLY) [#3009]
  #
  # An ADR may record a CONDITIONAL ratification — `status: Proposed … flips to Accepted
  # at <review>`. When that review closes, the flip is a manual close-out step with
  # nothing confirming it landed, so a record can sit Proposed on the mainline long after
  # its ratifying review shipped, silently failing any downstream gate that asks "is this
  # ADR Accepted?".
  #
  # *** THIS CHECK IS NEVER ENFORCE-CAPABLE — STRUCTURALLY, NOT BY DEFAULT ***
  # Two mechanisms close the defect, mirroring the live G-CL8 + Check-28 pairing, and
  # THIS IS THE NON-AUTHORITATIVE HALF:
  #   * G-CL9 (gate-criteria-spec.md, Gate 13 Close) is THE AUTHORITY. It is release-
  #     scoped because the operator closing a release KNOWS which review just closed.
  #   * Check 58 is a standing drift SIGNAL only.
  # The ratifying reference is FREE TEXT (live wordings vary per record, and one lives
  # inside the `status:` line itself), so this surface can answer only "does a flip
  # PROMISE exist while the record is still Proposed?" — never "is the flip OVERDUE?".
  # A genuinely-pending ADR is CORRECT and reports here on every run; failing on it would
  # punish correctness. Hence every row routes through flag_advisory_only, which has NO
  # enforce branch and NEVER increments ISSUES, and this check deliberately does NOT call
  # resolve_check_mode — there is no mode file that could graduate it, because there is
  # no enforce state to graduate TO. Do not "fix" that by wiring it to
  # flag_warn_or_issue: that helper escalates with the shared cohort, which for this
  # class is the defect, not the feature.
  #
  # Age is the actionable axis (the Check 17 aging posture): a flip promised long ago is
  # far more likely stuck than one made this week. Offline-capable (reads the ADR tree;
  # no gh). Fail-loud: a zero-ADR parse exits 3 rather than reading green. Read-only;
  # reversibility CHEAP (additive; git revert).
  # Primitive: core/deploy/tools/check-adr-flip.py (carries --self-test).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 58: ADR ratification-flip backstop (Proposed + flip-promise; ADVISORY — never enforce-capable; G-CL9 is the authority)"
    local c58_script="core/deploy/tools/check-adr-flip.py"
    if [[ ! -f "$c58_script" ]]; then
      flag_advisory_only "adr-flip-verify" "primitive script missing: $c58_script"
    else
      local c58_out c58_exit=0
      c58_out=$(/usr/bin/python3 "$c58_script" --root . --output-format tsv 2>&1) || c58_exit=$?
      if [[ $c58_exit -eq 3 ]]; then
        flag_advisory_only "adr-flip-verify" "input failure (exit 3): $(echo "$c58_out" | head -1) — zero ADRs parsed; the ADR tree may have moved"
      elif [[ $c58_exit -ne 0 ]]; then
        flag_advisory_only "adr-flip-verify" "check errored (exit $c58_exit): $(echo "$c58_out" | head -1)"
      else
        local c58_proposed c58_count c58_oldest
        c58_proposed=$(echo "$c58_out" | awk -F'\t' '$1=="PROPOSED"{print $2}')
        c58_count=$(echo "$c58_out" | awk -F'\t' '$1=="COUNT"{print $2}')
        if [[ "${c58_count:-0}" -eq 0 ]]; then
          log "  OK:    adr-flip-verify — no Proposed ADR carries unresolved flip-promise wording (${c58_proposed:-0} Proposed)"
        else
          # Oldest promise first — the aging signal, not an alphabetical dump.
          c58_oldest=$(echo "$c58_out" | awk -F'\t' '$1=="PROMISED" && $3 != "?" {print $3"\t"$2}' | sort -rn | head -3 | awk -F'\t' '{printf "%s (%sd) ", $2, $1}')
          flag_advisory_only "adr-flip-verify" "${c58_count} of ${c58_proposed:-?} Proposed ADR(s) carry flip-promise wording; oldest: ${c58_oldest:-n/a}— confirm at release close whether each ratifying review has CLOSED (G-CL9); a still-pending review means Proposed is CORRECT"
        fi
      fi
    fi
  fi

  # Check 59 — Slug-primary release-identity conformance (pre-claim window; warn-mode initial) [#3107]
  #
  # Rejects a concrete vX.Y bound into the in-flight release/* branch name or the
  # new-on-branch plan filename BEFORE the Stage-12 claim (the slug-primary mandate;
  # #2548 + ADR-092). It is the pre-CLAIM naming-conformance twin of the pre-MERGE
  # version-freeness gate (Check 41): same window, same claim-oracle family. WINDOW-
  # GATED — in scope only on a release/* branch whose in-flight plan still carries the
  # unresolved {{RELEASE_VERSION}} token (pre-claim); it SKIPs cleanly off a release
  # branch or once the release is claimed (post-claim vX.Y is legitimate). The single
  # discriminator between a version-primary IN-FLIGHT plan (FAIL) and a post-claim
  # RENAMED vX.Y plan (no-fire) is that claim-state oracle — both are new-on-branch
  # vX.Y files; only the token tells them apart. Offline-safe off a release branch (no
  # gh, no origin/main needed to SKIP); on a release branch it diffs origin/main.
  # Fail-loud: a git/context failure exits 3 rather than reading green. Warn-mode
  # initial per bypass-mode-readiness.md §Shakedown (defaults to the shared
  # DEPLOY_CHECK_MODE=warn; flip via an identity-conformance.mode file after the
  # >=3-day warn-log review). The introducing release is itself exempt (reflexive-
  # pipeline loop) — and its own identity is slug-primary, so it PASSES regardless.
  # Concrete Check number (NOT a {{CHECK_NUM}} token): Check 57's roster contract
  # requires a concrete integer in the def-block + emitter (AC5 is carved to #3713).
  # Read-only; reversibility CHEAP (additive; git revert).
  # Primitive: core/deploy/tools/check-identity-conformance.py (carries --self-test).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 59: Slug-primary release-identity conformance (pre-claim window; warn-mode initial; enforce-flip deferred)"
    local c59_script="core/deploy/tools/check-identity-conformance.py"
    if [[ ! -f "$c59_script" ]]; then
      flag_warn_or_issue "identity-conformance" "primitive script missing: $c59_script"
    else
      local c59_mode c59_out c59_exit=0
      c59_mode=$(resolve_check_mode "identity-conformance")
      c59_out=$(/usr/bin/python3 "$c59_script" --root . 2>&1) || c59_exit=$?
      if [[ $c59_exit -eq 3 ]]; then
        flag_warn_or_issue "identity-conformance" "input failure (exit 3): $(echo "$c59_out" | head -1) — release-identity conformance is unverifiable (fetch origin/main)"
      elif [[ $c59_exit -eq 0 ]]; then
        log "  OK:    identity-conformance — $(echo "$c59_out" | head -1)"
      elif [[ $c59_exit -eq 1 ]]; then
        if [[ "$c59_mode" == "enforce" ]]; then
          log "  FAIL:  identity-conformance — $(echo "$c59_out" | head -1)"; ISSUES=$((ISSUES + 1))
        else
          flag_warn_or_issue "identity-conformance" "$(echo "$c59_out" | head -1) (warn-mode; flip identity-conformance.mode to 'enforce' after the >=3-day warn-log review)"
        fi
      else
        flag_warn_or_issue "identity-conformance" "check errored (exit $c59_exit): $(echo "$c59_out" | head -1)"
      fi
    fi
  fi


  # Check 60 — Master-enable hook-class ↔ D-R9 security-registry reconcile [#310]
  #
  # #310 gives every core/hooks/block-*.sh a `readonly MASTER_ENABLE_CLASS=<workflow|security>`
  # declaration at its master-activation gate call site, and core/hooks/lib/master-enable.sh
  # honors it: a `workflow` hook goes inert under master-OFF; a `security` hook NEVER does
  # (D-R9, ratified SECURITY-EXCLUDED — the security/floor class is public-surface-safety
  # paramount; a silently-disabled egress/PII/credential guard → an IRREVERSIBLE leaked
  # commit/PR on a public repo). This check reconciles each hook's DECLARED class against the
  # ratified D-R9 security/floor registry below, so a future edit cannot silently reclassify a
  # security hook as workflow (the one error this slice cannot ship). It also asserts every
  # block-*.sh declares a valid class (no missing / typo'd tag). The registry here IS the
  # machine-readable D-R9 contract; its human-readable home is
  # core/rules/bypass-mode-readiness/_cross-cutting.md § Master Activation Layer.
  # git-pre-commit-pii.sh is out of scope by construction (not a block-* name; own mode, no
  # master gate). Read-only; reversibility CHEAP. Warn-mode initial per the
  # bypass-mode-readiness.md §Shakedown precedent (flip the shared deploy-check.mode to
  # 'enforce' after the shakedown window).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 60: Master-enable hook-class ↔ D-R9 security-registry reconcile (#310) (warn-mode initial; enforce-flip deferred)"
    # The ratified D-R9 security/floor set — these hooks MUST declare `security` so master-OFF
    # can never make them inert. Space-padded for whole-word membership test; bash-3.2 portable.
    local c60_secset=" block-credential-reads block-destructive block-rm-prefer-trash block-egress block-gh-path-leak block-scope-segregation block-shell-injection "
    local c60_findings=0 c60_seen=0 c60_script
    if [[ ! -d core/hooks ]]; then
      log "  SKIP:  core/hooks absent (greenfield/partial checkout)"
    else
      for c60_script in core/hooks/block-*.sh; do
        [[ -e "$c60_script" ]] || continue
        c60_seen=$((c60_seen + 1))
        local c60_base; c60_base="$(basename "$c60_script" .sh)"
        local c60_class; c60_class="$(sed -n -E 's/^[[:space:]]*readonly[[:space:]]+MASTER_ENABLE_CLASS="?([a-z]+)"?.*/\1/p' "$c60_script" | head -1)"
        if [[ -z "$c60_class" ]]; then
          flag_warn_or_issue "master-enable-class" "$c60_base declares no MASTER_ENABLE_CLASS — every block-*.sh must declare its master-activation class (workflow|security) at the gate call site (#310)"
          c60_findings=$((c60_findings + 1)); continue
        fi
        case "$c60_class" in
          workflow|security) ;;
          *) flag_warn_or_issue "master-enable-class" "$c60_base declares MASTER_ENABLE_CLASS='$c60_class' — must be 'workflow' or 'security'"
             c60_findings=$((c60_findings + 1)); continue ;;
        esac
        # The load-bearing D-R9 assertion: a security/floor hook must declare `security`.
        case "$c60_secset" in
          *" $c60_base "*)
            if [[ "$c60_class" != "security" ]]; then
              flag_warn_or_issue "master-enable-class" "D-R9 VIOLATION: security/floor hook $c60_base declares '$c60_class' but MUST declare 'security' — master-OFF must NEVER silently disable it (public-surface security is paramount)"
              c60_findings=$((c60_findings + 1))
            fi
            ;;
        esac
      done
      if [[ $c60_findings -eq 0 ]]; then
        log "  OK:    master-enable-class — $c60_seen block-*.sh hooks declare a valid class; all 7 D-R9 security/floor hooks declare 'security'"
      fi
    fi
  fi

  # Check 61 — decision-emission minimum set (advisory; deploy-time-only) [#4026]
  #
  # The lifecycle surface of the shared _de_compute_verdict body factored to top level
  # above (DD1 — one engine, two call sites; the --check-decision-emission probe is the
  # other). Asserts that every VERIFIED RELEASE_LOG row STRICTLY AFTER the emission
  # cutover carries >=1 event row for each MUST class in the orchestration playbook's
  # EMISSION-CONTRACT block, resolved through pipeline-event-log-schema.md § 2a rung 1
  # (slug) then rung 2 (milestone subject). Rung 3 (legacy version match) is excluded:
  # an ambiguous match must never count as satisfying an obligation.
  #
  # COMMITTED warn DEFAULT — the second argument to resolve_check_mode, the Check 47
  # `release-body-drift` precedent. It ships `warn` regardless of the shared cohort's
  # deploy-check.mode, so the shipped posture is a property of the code, not of an
  # operator-instance runtime file. The graduation to `enforce` is an OPERATOR DECISION
  # recorded in gate-efficacy-standard.md's flip ledger, never auto-promoted by hit count
  # (progressive-rollout-convention.md owns the ladder). `shadow` is unreachable —
  # resolve_check_mode() takes enforce|warn|off — so the walked ladder is warn -> enforce.
  #
  # HONEST GUARANTEE: existence, not fidelity; deploy-time only, with NO pre-merge surface;
  # SKIP at ship (zero in-scope releases) and structurally unable to fire on its own
  # introducing release (playbook § 4a.4). Falsification is therefore fixture-only —
  # `deploy.sh --self-test` assertion group DE.
  DECISION_EMISSION_MODE="$(resolve_check_mode "decision-emission" "warn")"
  if [[ "$DECISION_EMISSION_MODE" != "off" ]]; then
    log "Check 61: Decision-emission minimum set (every VERIFIED post-cutover release emitted each MUST class; advisory / deploy-time-only; warn-mode initial)"
    local c61_verdict c61_tok
    c61_verdict="$(_de_compute_verdict "lifecycle")"
    c61_tok="${c61_verdict%% *}"
    case "$c61_tok" in
      SKIP)
        log "  N/A:   ${c61_verdict#SKIP }"
        ;;
      NOSET)
        # A repo defect, NOT a benign absence: the gate would assert nothing. Flagged on
        # every mode (this is the vacuous-control class the release exists to eliminate).
        flag_warn_or_issue "decision-emission" "${c61_verdict#NOSET }"
        ;;
      CLEAN)
        log "  OK:    all ${c61_verdict#CLEAN } post-cutover VERIFIED release(s) emitted every asserted MUST class"
        ;;
      INCOMPLETE)
        local _c61_rest="${c61_verdict#INCOMPLETE }"
        local _c61_n="${_c61_rest%% *}" _c61_m="${_c61_rest##* }"
        case "$DECISION_EMISSION_MODE" in
          enforce)
            log "  FAIL:  decision-emission — $_c61_n missing class(es) across $_c61_m post-cutover VERIFIED release(s) (see stderr detail); the remedy is to emit the missing rows per orchestration-playbook.md Procedure 4a, never to waive the finding"
            ISSUES=$((ISSUES + 1))
            ;;
          warn)
            log "  WARN:  decision-emission — $_c61_n missing class(es) across $_c61_m post-cutover VERIFIED release(s) (warn-mode; the flip to enforce is an operator decision recorded in gate-efficacy-standard.md, never auto-promoted by hit count)"
            local _c61_ts
            _c61_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf '{"ts":"%s","check":"%s","detail":"%s missing class(es) across %s post-cutover VERIFIED release(s)"}\n' \
              "$_c61_ts" "decision-emission" "$_c61_n" "$_c61_m" >> "$WARN_LOG" 2>/dev/null || true
            ;;
        esac
        ;;
      *)
        log "  WARN:  decision-emission — unexpected verdict '$c61_verdict'"
        ;;
    esac
  fi

  # Check 62 — register runner-resolution (advisory; deploy-time-only) [#4208]
  #
  # Recomputes condition R1 (CARRIED) for every gate-coverage register row that declares
  # a `runner-def:` pointer: the named runner-definition file must exist and must still
  # contain the declared anchor. This is the standard's § Resolution rule executed rather
  # than reviewed — the reviewer-instruction form of this same obligation failed on its
  # own first application, which is why it is a computation here.
  #
  # HONEST GUARANTEE: R1 only. It does not assert R2 (reached), does not read the
  # anchor's body, and is deploy-time-only with NO pre-merge surface — so a PR can merge
  # with an unresolvable row and this check catches it at the next deploy-time run. The
  # flip to `enforce` is an OPERATOR DECISION recorded in gate-efficacy-standard.md's
  # flip ledger, and Requirement (b′) blocks `required` until a CI mirror exists.
  REGISTER_RUNNER_MODE="$(resolve_check_mode "register-runner-resolution" "warn")"
  if [[ "$REGISTER_RUNNER_MODE" != "off" ]]; then
    log "Check 62: Register runner-resolution (every runner-def pointer resolves to a runner that carries the predicate; advisory / deploy-time-only; warn-mode initial)"
    local c62_verdict c62_tok
    c62_verdict="$(_rr_compute_verdict)"
    c62_tok="${c62_verdict%%|*}"
    case "$c62_tok" in
      NOSET)
        # A repo defect, NOT a benign absence: the gate would assert nothing. Flagged on
        # every mode — this is the vacuous-control class the milestone exists to close.
        flag_warn_or_issue "register-runner-resolution" "${c62_verdict#NOSET|}"
        ;;
      CLEAN)
        log "  OK:    all ${c62_verdict#CLEAN|} gate-coverage register runner-def pointer(s) resolve (R1: named runner carries the predicate)"
        ;;
      UNRESOLVED)
        local _c62_rest="${c62_verdict#UNRESOLVED|}"
        local _c62_bad="${_c62_rest%%|*}" _c62_tot="${_c62_rest##*|}"
        case "$REGISTER_RUNNER_MODE" in
          enforce)
            log "  FAIL:  register-runner-resolution — $_c62_bad of $_c62_tot register runner-def pointer(s) do not resolve (see stderr detail); the remedy is to encode the predicate in the named runner or re-point the row, never to delete the pointer"
            ISSUES=$((ISSUES + 1))
            ;;
          warn)
            log "  WARN:  register-runner-resolution — $_c62_bad of $_c62_tot register runner-def pointer(s) do not resolve — a row naming a runner that does not carry its predicate asserts nothing (warn-mode; the flip to enforce is an operator decision recorded in gate-efficacy-standard.md, never auto-promoted by hit count)"
            local _c62_ts
            _c62_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf '{"ts":"%s","check":"%s","detail":"%s of %s runner-def pointer(s) unresolved"}\n' \
              "$_c62_ts" "register-runner-resolution" "$_c62_bad" "$_c62_tot" >> "$WARN_LOG" 2>/dev/null || true
            ;;
        esac
        ;;
      *)
        log "  WARN:  register-runner-resolution — unexpected verdict '$c62_verdict'"
        ;;
    esac
  fi


  # Check 63 — count-vs-structure lint (ENFORCING, narrowly scoped) [#4196]
  #
  # WHAT IT ASSERTS. A stated cardinality that sits immediately above an enumerable
  # structure must reconcile with that structure under at least ONE reading. A pair is
  # EXAMINED only when a colon-TERMINATED line carries >=1 cardinal bound to a plural
  # head noun AND the next non-blank line opens a markdown list or table. It FLAGs only
  # when NO reading reconciles: identity (a stated cardinal equals the item count),
  # partition (the stated cardinals sum to it), or sub-count (a stated cardinal equals
  # the sum of per-item parenthetical cardinals). Four suppressors strip identifier
  # numerals (`Stage 6`), unit numerals (`2 hours`), inexact bounds (`>=4 files`), and
  # conditional clauses.
  #
  # SCOPE — FROZEN-ARTIFACT EXEMPTION (stated here because the scope IS the contract).
  # The predicate reads tracked `*.md` only, and EXCLUDES release/releases/**,
  # core/hooks/testdata/**, core/deploy/tests/fixtures/**, packages/**, and .github/**.
  # A shipped release plan or note describes the corpus AS IT WAS; "fixing" a count
  # inside one would rewrite a historical record. Fixture trees are excluded because
  # they carry deliberate defects as their whole purpose. Lifting the exemption at this
  # pin adds 17 findings, and all 17 resolve under release/releases/plans/ — the
  # exemption is load-bearing, not decorative. (Re-measured at Stage 7: --no-exempt
  # takes the population from 701 files / 414 pairs / 73 findings to 1031 / 471 / 90.
  # The scope claim held; the magnitude was a prototype-era figure, the same lineage
  # as the 51-vs-73 baseline count, and had never been true on this branch.)
  #
  # ENFORCING BY THE CODE'S SHAPE, NOT BY A DEFAULT. Note what is absent from the FAIL
  # arm below: there is no `case` on any mode and no mode gate of any kind. A new
  # non-reconciling pair increments ISSUES on every run. That is the inverse of the
  # flag_advisory_only idiom — the posture is a property of the code, not a default
  # value some later edit could quietly flip.
  #
  # WHY A COMMITTED BASELINE RATHER THAN WARN-MODE. The live corpus already carried 73
  # non-reconciling pairs at this check's introducing commit. Enforcing against all 73
  # on day one would red-wall the deploy gate for work unrelated to this check, and
  # warn-mode was rejected upstream. Both are avoided by accepting the pre-existing
  # population in core/deploy/allowlists/count-structure-baseline.txt and reporting it
  # as KNOWN. The baseline is keyed by sha1 of the whitespace-normalized preamble, NOT
  # by line number, so an edit elsewhere in a file cannot invalidate an entry — but
  # editing a baselined preamble ITSELF re-keys it and the pair FAILs, which is correct:
  # editing a count preamble is exactly the moment to re-verify its count.
  #
  # THE STALE ARM IS COMMITTED-WARN, DELIBERATELY. A sibling release that FIXES a
  # baselined count would otherwise turn this check red for work outside its scope.
  # That is the one red-wall vector an always-enforce hygiene arm would open, and it is
  # closed here via resolve_check_mode with a committed `warn` default (the Check 47 /
  # Check 61 precedent). Stale rows are reported so the debt register can be pruned.
  #
  # DECLARED COVERAGE BOUNDARY — state this, do not imply more. The predicate covers a
  # colon-terminated preamble over an adjacent list or table, WITHIN one file. It does
  # NOT cover: a count stated inside a table CELL; a count whose structure lives in a
  # DIFFERENT file (a cross-file claim has no adjacent structure to read); a
  # hard-wrapped preamble that does not end in a colon; or an inline semicolon-delimited
  # enumeration. Those forms have not had their false-positive surface measured, and
  # shipping them unmeasured is the defect this check exists to prevent.
  #
  # DECLARED BLIND SPOTS *INSIDE* THE COVERED SHAPE (added at Stage-7 adversarial
  # defeat-testing). The boundary above describes which PAIR SHAPES are read. It is not
  # sufficient on its own: a pair can sit squarely inside the covered shape and still be
  # declined or silently passed, by the suppressors or by the reconciliation rule. A
  # reader must not infer "colon + adjacent list + same file" => "covered". Measured over
  # the 872 in-scope candidate preambles (colon-terminated, above a real structure,
  # carrying >= 1 numeral) of which 414 are examined:
  #   (a) SUPPRESSOR DECLINE. 458 candidates are never examined. Most are correct refusals
  #       (S1 identifier numerals, S2 units, S3 bounds), but the refusal is by keyword and
  #       WILL decline genuine counts. Isolated single-variable controls: "The platform has
  #       four gates:" is BLIND while "The platform four gates:" FLAGs -- the word `has`
  #       alone (S5, matching declaratives as well as conditionals) disables the pair;
  #       87 candidates are declined this way. "The four are:" is BLIND while "The four
  #       gates:" FLAGs -- a copula/modal after the cardinal drops it (NP_STOP).
  #   (b) HYPHENATED COMPOUND CARDINAL. "The five-type mapping:" is not read at all --
  #       neither arm fires, so the form is invisible rather than merely unflagged. This
  #       form occurs in the live corpus.
  #   (c) MULTI-CARDINAL DISJUNCTION MASKS A DRIFTED CO-CARDINAL. R-a reconciles when ANY
  #       stated cardinal equals the item count, so a preamble carrying several counts
  #       passes on the one that happens to match. 52 of the 414 examined pairs are in
  #       this state. Demonstrated by mutation on live content: at
  #       core/disciplines/knowledge-architecture.md:207, corrupting a NON-matching
  #       cardinal (`four` -> `forty`) yields FAIL=0, while corrupting the matching one
  #       (`seven` -> `eight`) yields FAIL=1 reporting `stated=[8, 40, 2] items=7` -- the
  #       bad 40 was in hand and drew no objection. These pairs count toward the examined
  #       denominator, so they inflate apparent coverage.
  #   (d) SINGLE-ITEM STRUCTURE. `items < 2` is never examined (7 candidates).
  #   (e) UNBALANCED CODE FENCE. An odd number of fence markers flips the in-fence toggle
  #       and blinds the check for the REST OF THE FILE -- a file-scope failure, not a
  #       pair-scope one. 1 in-scope file is currently in this state.
  # None of (a)-(e) is fixed here: this release ships the check enforcing and narrowly
  # scoped, and widening the predicate without measuring each form's false-positive
  # surface is the defect this check exists to prevent. They are DECLARED so the check's
  # coverage claim can never be read as larger than its delivery.
  #
  # NOT ON THE REQUIRED-SUBSET ROSTER. Check 63 is deliberately absent from
  # --check-required-subset. That roster is seeded with Check 38 alone; joining it is a
  # separate, later, evidence-gated decision, and staying off it is what makes shipping
  # enforcing safe today (no CI workflow runs the full --check suite).
  #
  # Primitive: core/deploy/tools/check-count-structure.py (carries --self-test).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 63: Count-vs-structure lint (a stated cardinality must reconcile with the structure beneath it; enforcing, narrowly scoped; frozen artifacts exempt)"
    local c63_script="core/deploy/tools/check-count-structure.py"
    if [[ ! -f "$c63_script" ]]; then
      log "  FAIL:  count-structure — primitive script missing: $c63_script (the gate cannot assert anything without it; this is a repo defect, not a benign absence)"
      ISSUES=$((ISSUES + 1))
    else
      local c63_out c63_exit=0
      c63_out=$(/usr/bin/python3 "$c63_script" --root . --output-format tsv 2>&1) || c63_exit=$?
      if [[ $c63_exit -eq 3 ]]; then
        log "  FAIL:  count-structure — input failure (exit 3): $(echo "$c63_out" | head -1). A clean zero over an empty population is exactly what this check must never report."
        ISSUES=$((ISSUES + 1))
      else
        # PV-1 / PV-5: report the denominator and BOTH control arms as fields, so a
        # reader can always distinguish "zero found" from "nothing examined".
        local c63_denom c63_control c63_ctl_verdict
        c63_denom=$(echo "$c63_out" | awk -F'\t' '$1=="DENOM"{print $2" "$3" "$4}')
        c63_control=$(echo "$c63_out" | awk -F'\t' '$1=="CONTROL"{print $3}')
        c63_ctl_verdict=$(echo "$c63_out" | awk -F'\t' '$1=="CONTROL"{print $2}')
        log "  DENOM: count-structure — ${c63_denom:-unreported}"
        log "  CTRL:  count-structure — ${c63_ctl_verdict:-UNREPORTED}: ${c63_control:-unreported}"

        # A broken or over-matching control arm invalidates the whole result. Hard FAIL
        # on every mode — the Check 31 fixture-regression precedent. A probe that cannot
        # be shown to detect and to discriminate proves nothing by returning zero.
        if [[ "$c63_ctl_verdict" != "PASS" ]]; then
          log "  FAIL:  count-structure — control arms did not pass; the result is INDETERMINATE, not clean. Fix the predicate before trusting any zero it reports."
          ISSUES=$((ISSUES + 1))
        fi

        # The committed labeled expected-match set, run through the SAME predicate the
        # corpus scan just used, so the gate and manual verification measure the same
        # thing rather than two drifting copies. A fixture regression is a hard FAIL on
        # every mode: if the predicate has stopped discriminating on the pair that
        # falsified two earlier candidates, no verdict it reports is trustworthy.
        local c63_fx="core/deploy/tools/run-count-structure-fixtures.sh"
        if [[ -x "$c63_fx" ]]; then
          local c63_fx_out c63_fx_exit=0
          c63_fx_out=$(bash "$c63_fx" 2>&1) || c63_fx_exit=$?
          if [[ $c63_fx_exit -ne 0 ]]; then
            log "  FAIL:  count-structure-fixtures — $(echo "$c63_fx_out" | tail -1) (fixture regression; hard-fail on every mode)"
            ISSUES=$((ISSUES + 1))
          else
            log "  OK:    count-structure-fixtures — $(echo "$c63_fx_out" | tail -1 | sed 's|  (.*||')"
          fi
        else
          log "  FAIL:  count-structure-fixtures — harness missing or not executable: $c63_fx (the gate would assert nothing about the predicate's discrimination)"
          ISSUES=$((ISSUES + 1))
        fi

        local c63_new c63_known c63_stale
        c63_new=$(echo "$c63_out" | awk -F'\t' '$1=="FAIL"{print $2":"$3}' | paste -sd, -)
        c63_known=$(echo "$c63_out" | awk -F'\t' '$1=="KNOWN"' | wc -l | tr -d ' ')
        c63_stale=$(echo "$c63_out" | awk -F'\t' '$1=="STALE"{print $2}' | paste -sd, -)

        # ── The enforcing arm. No mode gate, by design. ──────────────────────────
        if [[ -n "$c63_new" ]]; then
          log "  FAIL:  count-structure — stated count does not reconcile with the adjacent structure at: $c63_new. The remedy is to correct the count or the structure, never to add a baseline row for new drift."
          ISSUES=$((ISSUES + 1))
        else
          log "  OK:    count-structure — no unbaselined non-reconciling pair (${c63_known:-0} pre-existing pair(s) accepted via core/deploy/allowlists/count-structure-baseline.txt)"
        fi

        # ── The ratchet. Committed warn: a sibling release FIXING a baselined count
        #    must never turn this check red for work outside its scope. ────────────
        if [[ -n "$c63_stale" ]]; then
          local c63_stale_mode
          c63_stale_mode="$(resolve_check_mode "count-structure-baseline" "warn")"
          case "$c63_stale_mode" in
            enforce)
              log "  FAIL:  count-structure-baseline — stale entr(ies) whose pair no longer exists or now reconciles: $c63_stale"
              ISSUES=$((ISSUES + 1))
              ;;
            *)
              log "  WARN:  count-structure-baseline — stale entr(ies) whose pair no longer exists or now reconciles: $c63_stale (committed warn-mode: prune the row(s); a sibling release fixing a baselined count must not red-wall this check)"
              ;;
          esac
        fi
      fi
    fi
  fi


  # Check 64 — theme-token undeclared-consumer lint, TH-3 (ENFORCING) [#4197]
  #
  # WHAT IT ASSERTS. Every CSS custom property CONSUMED by a themed document — after
  # resolving that document's DOCUMENTED substitution placeholders — is DECLARED in every
  # theme block of that document. It catches a `var(--x)` with no matching `--x:`.
  #
  # WHY A LITERAL GREP CANNOT DO THIS. The defect that motivated the check was invisible to
  # one. A themed SVG emitted status colours through `var(--{{S}}bg)` / `var(--{{S}}ln)` /
  # `var(--{{S}})` where {{S}} resolved to ok / warn / neut; for neut only `--neutbg` was
  # declared, so stroke fell back to `none` and fill to initial black in BOTH themes. The
  # broken token names `--neutln` and `--neut` are PRODUCED by substitution, never written,
  # so nothing to grep for exists in the source. It was found by reading the mechanism.
  #
  # WHY THE NEIGHBOURING INVARIANTS MISS IT. The template's own TH-1 (no hardcoded hex
  # outside the style block) and TH-2 (declaration parity between the two theme blocks) both
  # PASS on the defect: a token absent from BOTH blocks satisfies parity trivially. That is
  # the gap, and the fixture set proves the three invariants are independent in both
  # directions rather than asserting it.
  #
  # THE DOMAIN IS DECLARED, NOT INFERRED — and that choice is what makes the check usable.
  # Inferring {{S}}'s value set from the prose comment documenting it does not work: the live
  # comments read "ok on GO, bad on NO-GO" and "ok when class is C1 or C2; warn when C3",
  # and a lowercase-word extractor returns {ok, on, bad} and {ok, when, class, is, or, warn}.
  # An instrument that cannot separate a token value from an English word OVER-MATCHES, and
  # an over-matching probe is unusable rather than lenient. The domain is therefore stated at
  # the usage site as `<!-- subst: {{NAME}} = v1|v2|… ; <prose> -->`, with the prose retained
  # on the same line so the machine domain and the human explanation cannot drift apart.
  #
  # NEVER A SILENT SKIP. An unmanifested placeholder is UNRESOLVABLE and the runner exits 2,
  # which this block treats as a FAIL. Skipping it would print a clean zero over a partial
  # population — precisely the miss that produced the original defect. A domain genuinely
  # unbounded at authoring time declares `*` and its consumers are counted into a printed
  # declared-uncoverable bucket named in the verdict line, so the coverage boundary is on the
  # face of every run and cannot be quietly widened.
  #
  # SCOPE — tracked DOCUMENTS (.md / .html / .htm / .svg / .xhtml) carrying BOTH a `<style>`
  # element and >=1 `var(--` consumer, with core/hooks/testdata/** exempt. Fixture trees
  # carry deliberate defects as their whole purpose, so counting them would make the gate red
  # by construction — the same exemption Check 63 carries, for the same reason. The gate is a
  # CONTENT predicate rather than an enumerated path list, so a new themed artifact is covered
  # on creation rather than on someone remembering to register it. Live population: 2.
  #
  # DECLARED COVERAGE BOUNDARY — state this, do not imply more. NOT covered: a consumer
  # produced by a substitution the source text does not document AT ALL (a token name
  # assembled at run time by string concatenation) — an undocumented MECHANISM, as distinct
  # from an undocumented VALUE SET, which IS caught as INDETERMINATE; a generator that emits
  # themed CSS at run time, since the check reads documents on disk; the full CSS cascade,
  # since TH-3 models root-scope theming, this corpus's documented convention, and counts
  # non-root declarations as OUT-OF-ROOT rather than absorbing them; and whether a declared
  # token's VALUE is legible, which is the property that made the original defect visible and
  # is a different invariant.
  #
  # ENFORCING BY THE CODE'S SHAPE, NOT BY A DEFAULT. Note what is absent from the FAIL arms
  # below: no `case` on any mode, no mode gate of any kind. The live population is clean at
  # this pin, so there is no pre-existing debt to baseline and no red-wall vector to hedge
  # against — the conditions that forced Check 63 to ship a committed baseline do not hold
  # here. A new undeclared consumer increments ISSUES on every run.
  #
  # THE CHECK CARRIES ITS OWN RECORD (PV-6, core/disciplines/review-discipline-principles.md
  # § 8.1). Its denominator and BOTH control arms are fields of its own emitted output, not of
  # any prose report about it, so a reader can distinguish "zero found" from "nothing
  # examined". A fixture regression is a hard FAIL: a probe that can no longer be shown to
  # detect AND to discriminate proves nothing by returning zero.
  #
  # Primitive: core/hooks/run-theme-token-fixtures.sh (bare invocation runs the fixture set).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 64: Theme-token undeclared-consumer lint (every var(--x) consumer is declared in every theme block; enforcing; fixture trees exempt)"
    local c64_runner="core/hooks/run-theme-token-fixtures.sh"
    if [[ ! -f "$c64_runner" ]]; then
      log "  FAIL:  theme-token — runner missing: $c64_runner (the gate cannot assert anything without it; this is a repo defect, not a benign absence)"
      ISSUES=$((ISSUES + 1))
    else
      # ── The precision probe: the committed two-armed fixture set. ──────────────
      local c64_fx_out c64_fx_rc=0
      c64_fx_out=$(bash "$c64_runner" 2>&1) || c64_fx_rc=$?
      log "  CTRL:  theme-token — $(echo "$c64_fx_out" | sed -n '1s/^TH-3 fixture self-test: //p')"
      log "  CTRL:  theme-token — $(echo "$c64_fx_out" | sed -n '2s/^ *//p')"
      if [[ $c64_fx_rc -ne 0 ]]; then
        log "  FAIL:  theme-token-fixtures — fixture regression (hard-fail on every mode). A probe that can no longer be shown to detect AND to discriminate proves nothing by returning zero."
        echo "$c64_fx_out" | sed 's/^/         /'
        ISSUES=$((ISSUES + 1))
      else
        log "  OK:    theme-token-fixtures — $(echo "$c64_fx_out" | tail -1 | sed 's/^TH-3 fixture self-test: //; s|  *(fixtures:.*||')"
      fi

      # ── The enforcing arm: scan the gated corpus population. ───────────────────
      local c64_out c64_rc=0
      c64_out=$(bash "$c64_runner" --scan-corpus 2>&1) || c64_rc=$?
      local c64_pop c64_res
      c64_pop=$(echo "$c64_out" | sed -n 's/^TH-3 corpus scan: //p' | tail -1)
      c64_res=$(echo "$c64_out" | awk -F'DENOMINATOR *: ' '/DENOMINATOR/{split($2,a," "); s+=a[1]} END{print s+0}')
      log "  DENOM: theme-token — ${c64_pop:-unreported}; ${c64_res} consumer resolution(s) examined across the population"

      case "$c64_rc" in
        0)
          log "  OK:    theme-token — no undeclared consumer in any gated document"
          ;;
        1)
          log "  FAIL:  theme-token — a consumed custom property is not declared in every theme block at: $(echo "$c64_out" | awk '/^  MISSING /{print $2}' | sort -u | paste -sd, -). The remedy is to declare the token (or correct the consumer), never to widen the manifest to hide it."
          ISSUES=$((ISSUES + 1))
          ;;
        *)
          log "  FAIL:  theme-token — INDETERMINATE: $(echo "$c64_out" | sed -n 's/^  VERDICT  *: INDETERMINATE (PV-1) — //p' | sort -u | paste -sd'; ' -). The denominator was not established, so a zero here would be untrustworthy — this is not a clean result."
          ISSUES=$((ISSUES + 1))
          ;;
      esac
    fi
  fi


  # ─── Check 65: RELEASE_LOG hot working-set budget (warn-mode) ──────────────
  # The archival chore's TRIGGER. The authoritative release record grows without
  # bound by construction — one Deployment-Log block per release, and the recent
  # blocks are materially larger than the old ones — so the hot file needs a
  # budget and something that notices when it is crossed. This is that something.
  #
  # It reports a MEASUREMENT, not a diff, so it cannot false-positive on content:
  # the budget is either crossed or it is not. What it can do is go stale, which
  # is why the size is logged on every run whether or not it warns — a probe that
  # only speaks when it fails cannot be shown to be alive.
  #
  # Warn-mode, and this one stays warn-mode on its own merits rather than pending
  # a shakedown: crossing the budget is a signal to schedule a chore, never a
  # reason to block a merge. The remedy is a separate, revertible sweep commit.
  #
  # The budget is stated in ONE place — BUDGET_BYTES in the sweep tool — and read
  # from there, so the gate and the sweep can never disagree about the figure.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 65: RELEASE_LOG hot working-set budget (warn-mode; the archival chore's trigger)"
    local c65_log="release/releases/RELEASE_LOG.md"
    local c65_tool="release/tools/sweep-release-corpus.py"
    if [[ ! -f "$c65_log" ]]; then
      flag_warn_or_issue "release-log-budget" "the release log is not at $c65_log — the probe has nothing to measure, which is a repo defect rather than a clean result"
    elif [[ ! -f "$c65_tool" ]]; then
      flag_warn_or_issue "release-log-budget" "the sweep tool is missing at $c65_tool, so the budget figure has no single source and the remedy has no mechanism"
    else
      local c65_bytes c65_budget
      c65_bytes=$(/usr/bin/wc -c < "$c65_log" | /usr/bin/tr -d ' ')
      c65_budget=$(/usr/bin/sed -n 's/^BUDGET_BYTES = \([0-9_]*\)$/\1/p' "$c65_tool" | /usr/bin/head -1 | /usr/bin/tr -d '_')
      if [[ -z "$c65_budget" ]]; then
        flag_warn_or_issue "release-log-budget" "could not read BUDGET_BYTES from $c65_tool — the probe would otherwise compare against an invented figure"
      else
        log "  DENOM: release-log-budget — hot ledger ${c65_bytes} B against a ${c65_budget} B budget ($(( c65_bytes * 100 / c65_budget ))% used)"
        if [[ "$c65_bytes" -gt "$c65_budget" ]]; then
          flag_warn_or_issue "release-log-budget" "the hot release log is ${c65_bytes} B, over its ${c65_budget} B budget. Run 'python3 ${c65_tool} --plan' to see what would move, then '--apply' and '--verify' in a separate commit. This is a MOVE: every relocated byte lands in a same-directory archive segment and every heading stays put"
        else
          log "  OK:    release-log-budget — $(( c65_budget - c65_bytes )) B of headroom; no archival chore due"
        fi
      fi
    fi
  fi


  # ─── Check 66: Cross-skill citation-anchor drift (warn-mode initial) ────────
  #
  # WHAT IT ASSERTS. No tracked *.md under core/skills/, release/skills/ or
  # operations/skills/ locates a cross-skill referent by LINE NUMBER. The canonical
  # form is a section-name anchor — a `§` segment carrying the target heading's text
  # verbatim, over a plain link to the target file with no `#fragment`. This block is
  # the convention's normative home: it is stated where it is enforced, so the rule and
  # the gate cannot drift apart.
  #
  # WHY THE LINE-NUMBER FORM IS THE DEFECT — it fails OPEN. Every line number in a long
  # file "resolves", so a citation that has drifted onto the wrong content is
  # indistinguishable from a correct one by any mechanical means. Measured at the
  # introducing pin: 5 of 6 release-planner citations in pmo-release-manager pointed at
  # the wrong content, and 7 of 7 change-management citations in pmo-ocm-lead were off
  # by exactly one line — a single inserted line upstream broke seven at once. A section
  # name that no longer exists returns zero from a grep. The point is not accuracy; it
  # is converting a silent failure mode into a detectable one.
  #
  # TWO LEXICAL FORMS, because narrowing to one was MEASURED to miss real carriers:
  # F1 `SKILL.md:NNN` and F2 a backticked bare `` `:NNN` ``. An F1-only predicate misses
  # 3 live anchors inside a file it already flags, and misses an entire third carrier
  # whose 9 anchors are all F2.
  #
  # SCOPE — a TREE + FILE-TYPE predicate, not a filename glob and not the whole corpus.
  # A filename glob (SKILL.md + composition-contract-*.md) is precisely what hid a
  # composition contract that is not named composition-contract-*.md; scoping by tree
  # covers a new one on creation rather than on someone remembering to register it. The
  # whole corpus was measured too: it adds 38 out-of-scope lines, EVERY one a legitimate
  # use — frozen release plans, an immutable ADR, [SOURCE]-labelled evidence pins, and
  # upstream-reference-catalog.md's `upstream_citation` field, which DEFINES itself as
  # an exact file:line pin into an external repo we neither control nor can add anchors
  # to. Flagging those would require an exemption list — a second source of truth for
  # what counts as a citation — to buy zero additional true positives. Fixture / eval /
  # testdata trees are exempt: they carry deliberate defects as their purpose (the same
  # exemption Checks 63 and 64 carry, for the same reason).
  #
  # DECLARED COVERAGE BOUNDARY — state it; do not imply more. NOT covered: whether a
  # section-name anchor's cited heading actually EXISTS in its target (a different
  # invariant, checked by the resolution predicate rather than here); whether a
  # nearest-enclosing-heading citation's PROSE SUB-REFERENT still exists — those
  # citations carry a verified enclosing heading and an UNVERIFIED sub-locator that this
  # predicate is lexically incapable of seeing, so a renumbered step still fails open;
  # non-.md files, where a tool legitimately prints file:line; and citations to
  # non-SKILL.md targets.
  #
  # WARN-MODE INITIAL via resolve_check_mode "citation-anchor" — the Check 51-65
  # deploy-check precedent, NOT the PreToolUse-hook .mode surface. Flip to enforce with
  # a `citation-anchor.mode` file after the >=3-day warn-log review. The reintroduction
  # of a line anchor is a signal to correct a citation, never a reason to block a
  # deploy, so the first posture is a report.
  #
  # THE CHECK CARRIES ITS OWN RECORD (PV-6). Its denominator and BOTH control arms are
  # fields of its own emitted output, so a reader can distinguish "zero found" from
  # "nothing examined". A self-test regression is a hard FAIL on EVERY mode: a probe
  # that can no longer be shown to detect AND to discriminate proves nothing by
  # returning zero.
  #
  # Primitive: core/deploy/tools/check-citation-anchors.sh (carries --self-test).
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 66: Cross-skill citation-anchor drift (line-number locators in the skill self-description tree; warn-mode initial; enforce-flip deferred)"
    local c66_script="core/deploy/tools/check-citation-anchors.sh"
    if [[ ! -f "$c66_script" ]]; then
      flag_warn_or_issue "citation-anchor" "primitive script missing: $c66_script (the gate cannot assert anything without it; a repo defect, not a benign absence)"
    else
      local c66_mode
      c66_mode=$(resolve_check_mode "citation-anchor")
      # ── control arms: the committed two-armed fixture set ────────────────────
      local c66_fx_out c66_fx_rc=0
      c66_fx_out=$(bash "$c66_script" --self-test 2>&1) || c66_fx_rc=$?
      log "  CTRL:  citation-anchor — $(echo "$c66_fx_out" | tail -1)"
      if [[ $c66_fx_rc -ne 0 ]]; then
        log "  FAIL:  citation-anchor-fixtures — fixture regression (hard-fail on every mode). A probe that can no longer be shown to detect AND to discriminate proves nothing by returning zero."
        echo "$c66_fx_out" | sed 's/^/         /'
        ISSUES=$((ISSUES + 1))
      else
        # ── the scan: denominator first, then findings ─────────────────────────
        local c66_out c66_rc=0
        c66_out=$(bash "$c66_script" 2>&1) || c66_rc=$?
        log "  DENOM: citation-anchor — $(echo "$c66_out" | sed -n 's/^DENOM: //p' | tail -1)"
        if [[ $c66_rc -eq 3 ]]; then
          flag_warn_or_issue "citation-anchor" "scan-surface error — $(echo "$c66_out" | sed -n 's/^SCAN-ERROR: //p' | tail -1). The denominator was not established, so a zero here would be untrustworthy; this is not a clean result"
        elif [[ $c66_rc -ne 0 ]]; then
          local _c66_hit
          while IFS= read -r _c66_hit; do
            [[ -z "$_c66_hit" ]] && continue
            if [[ "$c66_mode" == "enforce" ]]; then
              log "  FAIL:  citation-anchor — ${_c66_hit#FAIL: } — cite the composed section by name (a \`§ <verbatim heading>\` segment over a plain link), not by line number"
              ISSUES=$((ISSUES + 1))
            else
              flag_warn_or_issue "citation-anchor" "${_c66_hit#FAIL: } — cite the composed section by name (a \`§ <verbatim heading>\` segment over a plain link), not by line number: a line anchor still resolves after the target is edited while pointing at the wrong content, so the drift is undetectable"
            fi
          done < <(echo "$c66_out" | grep '^FAIL: ' || true)
        else
          log "  OK:    citation-anchor — no line-number locator in any examined skill self-description file"
        fi
      fi
    fi
  fi

  # ─── Check 67: Composition-aware cross-skill trigger collision (warn-mode initial) ───
  #
  # WHAT IT ASSERTS. No two skills in the audit population compete for the same request.
  # The harness scores each pair's `Triggers:` vocabulary (content-token Jaccard) and
  # bands the result: at or above threshold = ESCALATE, two-thirds of threshold = WATCH.
  #
  # THE COMPOSITION RULE (CR-1, ADR-114) — WHY A PLAIN SKIP WOULD BE WRONG. A
  # role-Specialist COMPOSES the function-skill it invokes (ADR-019), so the two
  # legitimately share subject-matter vocabulary and a naive gate re-flags them forever.
  # But the composition edge CO-VARIES WITH THE DEFECT on this corpus: when the audit was
  # first run suite-wide, all 4 ESCALATE pairs carried a DEPENDS_ON edge. A gate that
  # skipped composition-linked pairs would therefore have suppressed 100% of its own
  # findings and printed PASS over a corpus carrying a 0.733 collision — a dormant
  # capability wearing a verdict line. So linkage suppresses the WATCH band ONLY; the
  # ESCALATE band applies to every pair unchanged. Do NOT "simplify" this to a skip.
  #
  # WHY THE EXEMPT LINE IS MANDATORY, NOT DECORATION. The rule opens a blind interval
  # between the WATCH floor and the ESCALATE threshold for exactly the pair class the
  # trigger convention reshapes. The entire argument for exempting is that the suppressed
  # set is benign — a claim nobody can re-check if it is never printed. The EXEMPT line is
  # emitted on every run, pass or fail, for the same reason DENOM is.
  #
  # POPULATION — AUDIT_POPULATION, NOT CI_ROSTER. This unions CANARY_SKILLS in (55),
  # whereas Check 5(d) / check-registry-currency.sh deliberately exclude it (54): a
  # canary's description is still loaded by the harness, so it can still mis-route a live
  # request. Trigger collision is a property of the description surface, not of packaging.
  # The two populations are documented in canonical-skill-structure.md § 2. Do NOT
  # "reconcile" them to a single number.
  #
  # WARN-MODE INITIAL via resolve_check_mode "trigger-collision", per the Check 51-66
  # precedent; enforce-flip deferred to bypass-mode-readiness.md § Warn-Mode Initial.
  if [[ "$DEPLOY_CHECK_MODE" != "off" ]]; then
    log "Check 67: Composition-aware cross-skill trigger collision (registry-linked pairs exempt from WATCH, never from ESCALATE; warn-mode initial; enforce-flip deferred)"
    local c67_script="release/skills/pmo-skill-refiner/scripts/run_eval_audit.py"
    local c67_registry="core/skills/registry.md"
    if [[ ! -f "$c67_script" ]]; then
      flag_warn_or_issue "trigger-collision" "primitive script missing: $c67_script (the gate cannot assert anything without it; a repo defect, not a benign absence)"
    elif [[ ! -f "$c67_registry" ]]; then
      flag_warn_or_issue "trigger-collision" "composition source missing: $c67_registry — without it the gate would silently degrade to a non-composition-aware run"
    else
      local c67_mode c67_names
      c67_mode=$(resolve_check_mode "trigger-collision")
      c67_names=$(printf '%s\n' "${OPERATIONS_SKILLS[@]}" "${RELEASE_SKILLS[@]}" \
                                "${CORE_SKILLS[@]}" "${CANARY_SKILLS[@]}" | paste -sd, -)
      # PYTHONPATH here is belt-and-braces BY DESIGN, not by confusion: run_eval_audit.py
      # self-bootstraps sys.path (so it runs from any cwd), and this prefix — the qa.sh
      # idiom — guarantees the gate survives a future refactor of that bootstrap.
      # Removing either one alone is safe; removing both is not.
      # ── control arms FIRST: a probe that cannot be shown to detect proves nothing ──
      local c67_fx_out c67_fx_rc=0
      c67_fx_out=$(PYTHONPATH="release/skills/pmo-skill-refiner${PYTHONPATH:+:${PYTHONPATH}}" \
                   /usr/bin/python3 "$c67_script" --self-test 2>&1) || c67_fx_rc=$?
      log "  CTRL:  trigger-collision — $(echo "$c67_fx_out" | tail -1)"
      if [[ $c67_fx_rc -ne 0 ]]; then
        log "  FAIL:  trigger-collision-fixtures — fixture regression (hard-fail on every mode). A probe that can no longer be shown to detect AND to discriminate proves nothing by returning zero."
        echo "$c67_fx_out" | sed 's/^/         /'
        ISSUES=$((ISSUES + 1))
      else
        # ── the scan: denominator first, then the exemption ledger, then findings ──
        local c67_out c67_rc=0
        c67_out=$(PYTHONPATH="release/skills/pmo-skill-refiner${PYTHONPATH:+:${PYTHONPATH}}" \
                  /usr/bin/python3 "$c67_script" \
                    --skills-dir core/skills --skills-dir operations/skills --skills-dir release/skills \
                    --skills "$c67_names" --registry "$c67_registry" --composition-aware \
                    --verbose 2>&1) || c67_rc=$?
        # The denominator AND the auditable population are logged on EVERY run, pass or
        # fail. "Skills audited" alone would let "nothing found" read identically to
        # "nothing examined": a skill whose description yields no trigger phrases scores
        # zero against everything, so its pairs cannot return non-zero.
        log "  DENOM: trigger-collision — $(echo "$c67_out" | sed -n 's/^Skills audited: \([0-9]*\).*Pairs: \([0-9]*\).*/\1 skill(s), \2 pair(s) examined/p' | tail -1); auditable: $(echo "$c67_out" | sed -n 's/^Auditable: //p' | tr -s ' ' | tail -1)"
        log "  EXEMPT: trigger-collision — $(echo "$c67_out" | sed -n 's/^Exempt (composition-linked, WATCH band suppressed; ESCALATE never suppressed): //p' | tail -1)"
        if [[ $c67_rc -eq 3 ]]; then
          flag_warn_or_issue "trigger-collision" "resolution failure — $(echo "$c67_out" | sed -n 's/^Error: //p' | tail -1). The population was not established, so a zero here would be untrustworthy; this is not a clean result"
        elif [[ $c67_rc -eq 1 ]]; then
          local _c67_hit
          while IFS= read -r _c67_hit; do
            [[ -z "$_c67_hit" ]] && continue
            if [[ "$c67_mode" == "enforce" ]]; then
              log "  FAIL:  trigger-collision — ${_c67_hit# } — narrow the triggers (function-skills take mechanic phrasing, role-Specialists take domain-anchored ownership phrasing per canonical-skill-structure.md § 3); do NOT widen the exemption to hide it"
              ISSUES=$((ISSUES + 1))
            else
              flag_warn_or_issue "trigger-collision" "${_c67_hit# } — narrow the triggers (function-skills take mechanic phrasing, role-Specialists take domain-anchored ownership phrasing per canonical-skill-structure.md § 3); do NOT widen the exemption to hide it: two skills competing for one request means the operator gets whichever the harness happens to pick"
            fi
          done < <(echo "$c67_out" | grep -E '^\s+\[(ESCALATE|WATCH)\]' || true)
        elif [[ $c67_rc -ne 0 ]]; then
          flag_warn_or_issue "trigger-collision" "check errored (exit $c67_rc): $(echo "$c67_out" | tail -1)"
        else
          log "  OK:    trigger-collision — no pair at or above threshold after the composition-aware WATCH exemption"
        fi
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

  # STDERR-capturing sibling (#4176). The arm-row diagnostic is emitted on stderr, so it
  # is the thing under test in assertions (5)-(7) and must NOT be discarded. Note that
  # `_cc_selftest_verdict ... 2>&1 >/dev/null` captures NOTHING — the helper above
  # hard-codes `2>/dev/null` inside its own body, so stderr is already gone by the time
  # the caller's redirect applies. Hence a sibling rather than a redirect at the call.
  _cc_selftest_stderr() {
    CC_LOG="$_log" CC_INDEX="$_index" CC_DIGEST="$_digest" CC_CHANGELOG="$_changelog" \
    CC_VERSIONFILE="$_version" CC_NOTES_DIR="$_notes" CC_LINT="$_lint" CC_DRIFT="$_drift" \
    CC_ALLOWLIST="$_t/none.txt" \
    CLOSE_COMPLETENESS_CHECK_CUTOFF="$1" CLOSE_COMPLETENESS_RELEASE_CUTOFF="__none__" \
    _cc_compute_verdict "lifecycle" 2>&1 >/dev/null
  }

  local _v _tok _e

  # (3) explicit re-dormant — cutover __none__ ⇒ SKIP (assert FIRST: the escape hatch
  #     the committed armed default must never take away).
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

  # ─── R8 mis-arm assertions (#4176) — the ANTI-VACUITY group for the arming change ──
  # The cutover arm is a string PREFIX match, not a version comparison. A shortened
  # prefix landing on a clean sub-range verdicts CLEAN and exits 0 — a silent mis-arm
  # that reads as success. These three assertions prove the mis-arm is now VISIBLE.
  # (Fixture state after (4): both v9.98 and v9.99 are VERIFIED; v9.98's output-set is
  # absent, so a v9.9-prefixed cutoff arms at v9.98 and pulls both rows into scope.)

  # (5) a prefix-SHORTENED cutoff must still verdict, AND must WARN naming the row that
  #     actually armed — the silent-mis-arm case this mitigation exists for.
  _v="$(_cc_selftest_verdict "v9.9")"; _tok="${_v%% *}"
  [[ "$_tok" == "INCOMPLETE" || "$_tok" == "CLEAN" ]] || { echo "FAIL: a prefix-shortened cutoff must still verdict, got '$_v'"; failures=$((failures+1)); }
  _e="$(_cc_selftest_stderr "v9.9")"
  printf '%s' "$_e" | /usr/bin/grep -q 'WARNING — cutoff v9.9 armed at LOG row v9.98' \
    || { echo "FAIL: a prefix-shortened cutoff must WARN naming the armed row, got '$_e'"; failures=$((failures+1)); }

  # (6) an EXACT-row cutoff must NOT emit the mis-arm WARNING (no false-positive noise;
  #     without this, (5) could pass on a warning that fires unconditionally).
  _e="$(_cc_selftest_stderr "v9.98")"
  if printf '%s' "$_e" | /usr/bin/grep -q 'WARNING — cutoff'; then
    echo "FAIL: an exact-row cutoff must not emit the mis-arm WARNING, got '$_e'"; failures=$((failures+1))
  fi
  printf '%s' "$_e" | /usr/bin/grep -q 'armed at LOG row v9.98' \
    || { echo "FAIL: an exact-row cutoff must still name the armed row, got '$_e'"; failures=$((failures+1)); }

  # (7) a cutoff matching NO row asserts nothing and would report CLEAN 0 — vacuously
  #     clean. It must say so out loud. (Anti-vacuity: a gate that passes on zero
  #     assertions is indistinguishable from a gate that passes.)
  _e="$(_cc_selftest_stderr "v0.01")"
  printf '%s' "$_e" | /usr/bin/grep -q 'matched NO LOG row' \
    || { echo "FAIL: a no-match cutoff must WARN that zero rows were asserted, got '$_e'"; failures=$((failures+1)); }

  /bin/rm -rf "$_t" 2>/dev/null || true

  # ─── Assertion group DE — decision-emission minimum set (Check 61) [#4026] ────
  #
  # Offline, hermetic, sandbox-only. NEVER touches the operator's live event log:
  # every path is re-pointed through DE_* overrides at a mktemp tree, and the gate
  # itself is read-only in all modes. Extends this ONE self-test entry rather than
  # adding a second, so the CI invocation stays single.
  #
  # DE-4 and DE-5 are the ANTI-VACUITY assertions. Without DE-4 the predicate could
  # degenerate to "the release emitted something"; without DE-5 it could accept any
  # key, including the legacy `vX.Y` value measured to span four releases. A gate that
  # passes without them proves almost nothing — which is the failure class this whole
  # release exists to close.
  echo "self-test: starting assertion group DE (decision-emission minimum set, #4026)" >&2
  local _d; _d="$(/usr/bin/mktemp -d -t decisionemission-selftest.XXXXXX)"
  local _dlog="$_d/pipeline-event-log.md"
  local _drlog="$_d/RELEASE_LOG.md"
  local _dset="$_d/asserted-set.txt"
  local _dmissing="$_d/no-such-asserted-set.txt"

  /bin/cat > "$_dset" <<'EOF'
# fixture asserted set (mirrors the committed one)
decision/scope-lock
decision/d-class
gate-outcome/plan-review-go
EOF

  # RELEASE_LOG fixture: one PRE-cutover VERIFIED row, the cutover anchor itself, one
  # POST-cutover VERIFIED row (the release under test), and one POST-cutover DEPLOYED
  # (mid-close) row. 8-col schema matching the live RELEASE_LOG.
  /bin/cat > "$_drlog" <<'EOF'
# RELEASE_LOG (DE self-test fixture)
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.90 | de-precutover | #1 | #2 | `aaa` | `v9.90` | VERIFIED | 2026-06-28 |
| v9.95 | de-cutover-anchor | #1 | #2 | `bbb` | `v9.95` | VERIFIED | 2026-06-28 |
| v9.96 | de-postcutover | #1 | #2 | `ccc` | `v9.96` | VERIFIED | 2026-06-28 |
| v9.97 | de-midclose | #1 | #2 | `ddd` | `v9.97` | DEPLOYED | 2026-06-28 |
EOF

  # _de_seed_log <version-cell> <subject-cell> <class...> — writes a fresh fixture event
  # log whose rows carry the given version key + subject for each `type/subtype` class.
  _de_seed_log() {
    local _vcell="$1" _subj="$2"; shift 2
    /usr/bin/printf '| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |\n' > "$_dlog"
    /usr/bin/printf -- '|---|---|---|---|---|---|---|---|---|---|\n' >> "$_dlog"
    local _c _t _s
    for _c in "$@"; do
      _t="${_c%%/*}"; _s="${_c#*/}"
      /usr/bin/printf '| 2026-07-28T10:00:00Z | %s | 5 | %s | %s | operator | %s | MODERATE | resolved | ms:#900; d:de-selftest |\n' \
        "$_vcell" "$_t" "$_s" "$_subj" >> "$_dlog"
    done
  }

  _de_selftest_verdict() {
    DE_LOG="$_dlog" DE_RELEASE_LOG="$_drlog" DE_ASSERTED="${1:-$_dset}" \
    DECISION_EMISSION_CUTOVER_SLUG="${2:-de-cutover-anchor}" \
    _de_compute_verdict "lifecycle" 2>/dev/null
  }

  # DE-1 — dormant sentinel ⇒ SKIP. Asserted FIRST: the safe default.
  _de_seed_log "de-postcutover" "milestone:#900" decision/scope-lock decision/d-class gate-outcome/plan-review-go
  _v="$(_de_selftest_verdict "$_dset" "__none__")"; _tok="${_v%% *}"
  [[ "$_tok" == "SKIP" ]] || { echo "FAIL: DE-1 dormant cutover (__none__) must SKIP, got '$_v'"; failures=$((failures+1)); }

  # DE-3 — all 3 MUST classes keyed on the slug ⇒ CLEAN 1.
  # Doubles as DE-6 (the pre-cutover VERIFIED row v9.90 emits nothing and is NOT counted)
  # and DE-7 (the post-cutover DEPLOYED row v9.97 emits nothing and is NOT counted):
  # both are proved by the target count being exactly 1, not merely by the absence of a
  # finding — a zero-finding CLEAN with the wrong target count would hide both.
  _v="$(_de_selftest_verdict)"
  [[ "$_v" == "CLEAN 1" ]] || { echo "FAIL: DE-3/DE-6/DE-7 complete emission set must verify 'CLEAN 1' (pre-cutover + DEPLOYED rows excluded), got '$_v'"; failures=$((failures+1)); }

  # DE-2 — THE falsification test (AC-2): a VERIFIED post-cutover release whose event log
  # carries ZERO rows for it ⇒ INCOMPLETE.
  _de_seed_log "de-precutover" "milestone:#800" decision/scope-lock decision/d-class gate-outcome/plan-review-go
  _v="$(_de_selftest_verdict)"; _tok="${_v%% *}"
  [[ "$_tok" == "INCOMPLETE" ]] || { echo "FAIL: DE-2 seeded zero-emission post-cutover release must be caught (INCOMPLETE), got '$_v'"; failures=$((failures+1)); }
  [[ "$_v" == "INCOMPLETE 3 1" ]] || { echo "FAIL: DE-2 must report all 3 asserted classes missing across 1 release ('INCOMPLETE 3 1'), got '$_v'"; failures=$((failures+1)); }

  # DE-4 — ANTI-VACUITY: 2 of 3 MUST classes present ⇒ INCOMPLETE. Defeats a predicate
  # that degenerates into "the release emitted something".
  _de_seed_log "de-postcutover" "milestone:#900" decision/scope-lock decision/d-class
  _v="$(_de_selftest_verdict)"
  [[ "$_v" == "INCOMPLETE 1 1" ]] || { echo "FAIL: DE-4 partial set (2 of 3 classes) must report exactly 1 missing class ('INCOMPLETE 1 1'), got '$_v'"; failures=$((failures+1)); }

  # DE-5 — ANTI-VACUITY: rows keyed on the LEGACY version form with the slug absent ⇒
  # INCOMPLETE. The gate asserts the § 2a canonical key (rung 1/2), never an ambiguous
  # rung-3 legacy match. Subject is deliberately non-milestone so rung 2 cannot rescue it.
  _de_seed_log "v9.96" "issue:#4026" decision/scope-lock decision/d-class gate-outcome/plan-review-go
  _v="$(_de_selftest_verdict)"; _tok="${_v%% *}"
  [[ "$_tok" == "INCOMPLETE" ]] || { echo "FAIL: DE-5 legacy-version-keyed rows must NOT satisfy the canonical key (expected INCOMPLETE), got '$_v'"; failures=$((failures+1)); }

  # DE-7b — state-scoping proved POSITIVELY: flip the DEPLOYED row to VERIFIED and it
  # becomes an in-scope target. Without this, DE-7's exclusion could be an artifact of
  # the row never being seen at all.
  _de_seed_log "de-postcutover" "milestone:#900" decision/scope-lock decision/d-class gate-outcome/plan-review-go
  /usr/bin/sed 's/| `v9.97` | DEPLOYED |/| `v9.97` | VERIFIED |/' "$_drlog" > "$_d/rlog2.md" && /bin/mv "$_d/rlog2.md" "$_drlog"
  # The target count rises 1 -> 2 (v9.96 complete + v9.97 empty) and all 3 of v9.97's
  # classes are findings, so the exact expectation is 'INCOMPLETE 3 2'. Asserting the
  # exact pair — not just the token — is what proves the row was newly INCLUDED rather
  # than merely that something was flagged.
  _v="$(_de_selftest_verdict)"
  [[ "$_v" == "INCOMPLETE 3 2" ]] || { echo "FAIL: DE-7b a now-VERIFIED post-cutover row with zero rows must be counted and flagged ('INCOMPLETE 3 2'), got '$_v'"; failures=$((failures+1)); }
  /usr/bin/sed 's/| `v9.97` | VERIFIED |/| `v9.97` | DEPLOYED |/' "$_drlog" > "$_d/rlog2.md" && /bin/mv "$_d/rlog2.md" "$_drlog"

  # DE-8 (added at Stage 6) — § 2a RUNG 2 is reachable and load-bearing. Two of the three
  # classes are keyed on the slug (rung 1, and they carry the `ms:#900` token that makes
  # the milestone NUMBER discoverable); the third is keyed on the legacy version but
  # carries `subject: milestone:#900`. Rung 2 must pick it up ⇒ CLEAN 1. Added because an
  # implemented branch with no falsification is exactly the vacuity this release closes.
  _de_seed_log "de-postcutover" "milestone:#900" decision/scope-lock decision/d-class
  /usr/bin/printf '| 2026-07-28T10:05:00Z | v9.96 | 5 | gate-outcome | plan-review-go | operator | milestone:#900 | MODERATE | resolved | d:rung2 |\n' >> "$_dlog"
  _v="$(_de_selftest_verdict)"
  [[ "$_v" == "CLEAN 1" ]] || { echo "FAIL: DE-8 rung-2 (milestone-subject) resolution must complete the set ('CLEAN 1'), got '$_v'"; failures=$((failures+1)); }

  # DE-9 (added at Stage 6) — a missing asserted set is NOSET, never a silent pass. This
  # is the CIAC-3 vacuity guard at the gate's own surface: an emission gate with nothing
  # to assert must SAY so, distinctly from "there is nothing to check yet" (SKIP).
  _de_seed_log "de-postcutover" "milestone:#900" decision/scope-lock decision/d-class gate-outcome/plan-review-go
  _v="$(_de_selftest_verdict "$_dmissing")"; _tok="${_v%% *}"
  [[ "$_tok" == "NOSET" ]] || { echo "FAIL: DE-9 absent asserted-set file must verdict NOSET (not SKIP, not CLEAN), got '$_v'"; failures=$((failures+1)); }

  /bin/rm -rf "$_d" 2>/dev/null || true

  # ─── Assertion group VF — version-freeness claimed-set column pinning [#3724] ──
  #
  # Offline, hermetic, sandbox-only. Guards the DEPLOYED arm of _vf_build_claimed_set
  # against the ordinal off-by-one that made it structurally dead (it read $7, the Tag
  # column, while treating it as State — State is $8).
  #
  # VF-3 and VF-4 are the ANTI-VACUITY assertions. VF-1 alone would pass on a Tag cell
  # that happens to read DEPLOYED, and VF-1+VF-2 alone would pass on a hardcoded $8.
  # VF-3 pins that the value read is the STATE cell and not the tag; VF-4 shifts the
  # column order and asserts the arm still works, which only a NAME-pinned parser can
  # do. Without VF-4 this group would re-admit the exact defect one column insertion
  # later — the failure mode being closed is the ordinal, not this one instance of it.
  echo "self-test: starting assertion group VF (version-freeness claimed-set column pinning, #3724)" >&2
  local _vft; _vft="$(/usr/bin/mktemp -d -t vfclaimedset-selftest.XXXXXX)"
  /bin/mkdir -p "$_vft/release/releases"
  local _vflog="$_vft/release/releases/RELEASE_LOG.md"
  local _vfout _vferr

  # Canonical 8-column schema, matching the live RELEASE_LOG in shape. Synthetic v9.x
  # versions carry no real-lineage semantics. The `repo` arg is passed EMPTY so the
  # published-Releases arm is skipped — this group isolates arm (3).
  /bin/cat > "$_vflog" <<'EOF'
# RELEASE_LOG (self-test fixture)

Prose that | contains | pipes | before the table, proving the header scan skips
non-schema pipe rows rather than misreading the first one it meets.

| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.90 | m-verified | #1 | #2 | `aaa` | `v9.90` | VERIFIED | 2026-07-30 |
| v9.91 | m-deployed | #3 | #4 | `bbb` | `v9.91` | DEPLOYED | 2026-07-30 |
EOF

  # VF-1 / VF-2: the DEPLOYED row is extracted; the VERIFIED row is not.
  _vfout="$(_audit_src_root="$_vft" _vf_build_claimed_set "" 2>/dev/null || true)"
  /usr/bin/grep -qx 'v9.91' <<< "$_vfout" || { echo "FAIL: VF-1 the DEPLOYED row v9.91 must be extracted (State column)"; failures=$((failures+1)); }
  /usr/bin/grep -qx 'v9.90' <<< "$_vfout" && { echo "FAIL: VF-2 the VERIFIED row v9.90 must NOT be extracted"; failures=$((failures+1)); }

  # VF-3 anti-vacuity: the parser must read the STATE cell, not the Tag cell. The
  # literal DEPLOYED sits in the Tag column of an otherwise-VERIFIED row — an ordinal
  # $7 read matches it and wrongly claims v9.92; a name-pinned read does not.
  /bin/cat > "$_vflog" <<'EOF'
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.92 | m-tagtrap | #5 | #6 | `ccc` | DEPLOYED | VERIFIED | 2026-07-30 |
EOF
  _vfout="$(_audit_src_root="$_vft" _vf_build_claimed_set "" 2>/dev/null || true)"
  /usr/bin/grep -qx 'v9.92' <<< "$_vfout" && { echo "FAIL: VF-3 a DEPLOYED-valued TAG cell on a VERIFIED row must not be read as State (ordinal \$7 regression)"; failures=$((failures+1)); }

  # VF-4 anti-vacuity: shift the column order. A parser pinned to ANY ordinal breaks
  # here; a header-name-pinned parser keeps working. This is what makes the fix durable
  # rather than a one-time correction of one instance.
  /bin/cat > "$_vflog" <<'EOF'
| Version | State | Milestone | Issues | Release PR | Merge SHA | Tag | Date |
|---|---|---|---|---|---|---|---|
| v9.93 | DEPLOYED | m-shifted | #7 | #8 | `ddd` | `v9.93` | 2026-07-30 |
| v9.94 | VERIFIED | m-shifted | #9 | #10 | `eee` | `v9.94` | 2026-07-30 |
EOF
  _vfout="$(_audit_src_root="$_vft" _vf_build_claimed_set "" 2>/dev/null || true)"
  /usr/bin/grep -qx 'v9.93' <<< "$_vfout" || { echo "FAIL: VF-4 a re-ordered header must still resolve State by NAME (v9.93 DEPLOYED missing)"; failures=$((failures+1)); }
  /usr/bin/grep -qx 'v9.94' <<< "$_vfout" && { echo "FAIL: VF-4 a re-ordered header must still exclude VERIFIED (v9.94 wrongly included)"; failures=$((failures+1)); }

  # VF-5: a table with no resolvable Version+State header is REPORTED, not silently
  # treated as an empty arm — an unreadable schema is the condition that produced the
  # defect, so it must not present as "nothing is DEPLOYED".
  /bin/cat > "$_vflog" <<'EOF'
| Release | Milestone | Status |
|---|---|---|
| v9.95 | m-noheader | DEPLOYED |
EOF
  _vferr="$(_audit_src_root="$_vft" _vf_build_claimed_set "" 2>&1 1>/dev/null || true)"
  /usr/bin/grep -q 'Version+State' <<< "$_vferr" || { echo "FAIL: VF-5 an unresolvable header must be reported on stderr, not read as an empty arm"; failures=$((failures+1)); }

  # VF-6 / VF-7 — DT-2: the loud failure must be OBSERVABLE, not merely EMITTED.
  # VF-5 above proves the diagnostic is written to stderr. It does not prove anyone
  # can act on it: the arm's `exit 3` used to die inside a `{ … } | sed | sort -u`
  # pipeline under `|| true`, so the function's rc was `sort`'s and the sole caller
  # branched on output-emptiness alone. Measured pre-fix: rc=0, stdout=[]. From the
  # caller's position an unreadable schema was indistinguishable from "nothing is
  # DEPLOYED" — a partial claimed_set silently certifying a colliding candidate FREE.
  # VF-6 pins the rc; VF-7 pins the caller's VERDICT, which is the property that
  # actually matters. Each carries a negative control (VF-6b / VF-7b) so neither can
  # pass by the harness being uniformly broken.
  local _vfrc

  # VF-6: unreadable header -> the FUNCTION returns non-zero (the header is still the
  # malformed one written for VF-5).
  _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "" >/dev/null 2>&1 || _vfrc=$?
  [[ "$_vfrc" -ne 0 ]] || { echo "FAIL: VF-6 an unreadable RELEASE_LOG schema must return non-zero to the caller (got rc=0 — the exit 3 is being swallowed again)"; failures=$((failures+1)); }

  # VF-6b negative control: a WELL-FORMED log returns ZERO. Without this leg VF-6
  # would also pass on a function hardwired to fail.
  /bin/cat > "$_vflog" <<'EOF'
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.96 | m-ok | #11 | #12 | `fff` | `v9.96` | DEPLOYED | 2026-07-30 |
EOF
  _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "" >/dev/null 2>&1 || _vfrc=$?
  [[ "$_vfrc" -eq 0 ]] || { echo "FAIL: VF-6b a well-formed RELEASE_LOG must return rc 0 (got $_vfrc — VF-6 would be vacuous)"; failures=$((failures+1)); }

  # VF-7 / VF-7b exercise the REAL caller, _vf_compute_verdict, end-to-end. Hermetic:
  # `gh` is shadowed by a shell function (satisfying the `command -v` + `auth status`
  # probes without a network call and returning an empty releases list), the sandbox
  # is not a git repo so the origin-tags arm is a silent no-op, and the candidate is
  # injected. Only the RELEASE_LOG differs between the two legs.
  /bin/mkdir -p "$_vft/release/tools"
  /bin/cp "${_audit_src_root:-.}/release/tools/version-grammar.sh" "$_vft/release/tools/" 2>/dev/null || true
  if [[ -f "$_vft/release/tools/version-grammar.sh" ]]; then
    gh() { case "$1" in auth) return 0 ;; api) return 0 ;; *) return 0 ;; esac; }
    local _vfv

    # VF-7b (control, runs FIRST): well-formed log, non-colliding candidate -> FREE.
    # Establishes that this harness CAN reach a decided verdict at all.
    _vfv="$(_audit_src_root="$_vft" AUDIT_REPO="acme/widget" PMO_VERSION_FREENESS_CANDIDATE="v9.99" \
            _vf_compute_verdict lifecycle 2>/dev/null)"
    [[ "${_vfv%% *}" == "FREE" ]] || { echo "FAIL: VF-7b control — a well-formed corpus must reach a decided verdict (expected FREE, got '$_vfv'); VF-7 would be vacuous"; failures=$((failures+1)); }

    # VF-7: same candidate, UNREADABLE schema -> the caller must fail closed to
    # UNDECIDABLE. Pre-fix this returned FREE: the arm was silently empty, so the
    # candidate collided with nothing. This is the assertion the fix exists for.
    /bin/cat > "$_vflog" <<'EOF'
| Release | Milestone | Status |
|---|---|---|
| v9.99 | m-noheader | DEPLOYED |
EOF
    _vfv="$(_audit_src_root="$_vft" AUDIT_REPO="acme/widget" PMO_VERSION_FREENESS_CANDIDATE="v9.99" \
            _vf_compute_verdict lifecycle 2>/dev/null)"
    [[ "${_vfv%% *}" == "UNDECIDABLE" ]] || { echo "FAIL: VF-7 an unreadable RELEASE_LOG schema must fail the CALLER closed to UNDECIDABLE, got '$_vfv' (FREE here is the DT-2 fail-open)"; failures=$((failures+1)); }
    /usr/bin/grep -q 'partial-by-failure' <<< "$_vfv" || { echo "FAIL: VF-7 the UNDECIDABLE reason must name the partial-by-failure cause, got '$_vfv'"; failures=$((failures+1)); }

    # VF-7c: the gate surface must not be MORE permissive than lifecycle.
    _vfv="$(_audit_src_root="$_vft" AUDIT_REPO="acme/widget" PMO_VERSION_FREENESS_CANDIDATE="v9.99" \
            _vf_compute_verdict gate 2>/dev/null)"
    [[ "${_vfv%% *}" == "UNDECIDABLE" ]] || { echo "FAIL: VF-7c the merge gate must also fail closed on an unreadable schema, got '$_vfv'"; failures=$((failures+1)); }

    unset -f gh

    # VF-8 / VF-9 — #4339 residual A: arms (1) and (2) must fail closed too.
    # DT-2 repaired only arm (3). Arms (1) and (2) still ran INSIDE the union
    # pipeline under `|| true`, so an authenticated-but-erroring `gh` or a failing
    # `git ls-remote` degraded to a silently-PARTIAL set — and a partial set
    # certifies a colliding candidate FREE, the same fail-open one arm over.
    # Every leg carries its own negative control, because the property being closed
    # ("empty because it failed" vs. "empty because there is nothing") is invisible
    # unless the harness can produce BOTH answers.
    /bin/cat > "$_vflog" <<'EOF'
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.97 | m-ok | #13 | #14 | `ggg` | `v9.97` | DEPLOYED | 2026-07-30 |
EOF

    # VF-8: arm (1) AUTHENTICATED but the API call FAILS -> non-zero rc.
    gh() { case "$1" in auth) return 0 ;; api) echo "gh: simulated API failure" >&2; return 1 ;; *) return 0 ;; esac; }
    _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "acme/widget" >/dev/null 2>&1 || _vfrc=$?
    [[ "$_vfrc" -ne 0 ]] || { echo "FAIL: VF-8 an authenticated-but-erroring gh api must return non-zero (got rc=0 — arm (1) is still swallowing failures)"; failures=$((failures+1)); }
    # VF-8b: and the CALLER must fail closed, which is the property that matters.
    _vfv="$(_audit_src_root="$_vft" AUDIT_REPO="acme/widget" PMO_VERSION_FREENESS_CANDIDATE="v9.99" \
            _vf_compute_verdict lifecycle 2>/dev/null)"
    [[ "${_vfv%% *}" == "UNDECIDABLE" ]] || { echo "FAIL: VF-8b a failing published-Releases arm must fail the caller closed to UNDECIDABLE, got '$_vfv' (FREE here is the residual-A fail-open)"; failures=$((failures+1)); }
    unset -f gh

    # VF-8c NEGATIVE CONTROL: gh authenticated and SUCCEEDING with an empty list ->
    # rc 0 and a decided verdict. Without this, VF-8 would pass on an arm hardwired
    # to fail, and the "guard" would be an outage.
    gh() { case "$1" in auth) return 0 ;; api) return 0 ;; *) return 0 ;; esac; }
    _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "acme/widget" >/dev/null 2>&1 || _vfrc=$?
    [[ "$_vfrc" -eq 0 ]] || { echo "FAIL: VF-8c control — a SUCCEEDING gh api with no releases must be rc 0 (got $_vfrc; empty is a valid answer, VF-8 would be vacuous)"; failures=$((failures+1)); }
    # VF-8d NEGATIVE CONTROL: gh entirely ABSENT/unauthenticated -> the arm is N/A,
    # not failed. This is the offline-path regression guard.
    unset -f gh
    gh() { return 1; }   # `command -v` finds it; `auth status` fails -> arm N/A
    _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "acme/widget" >/dev/null 2>&1 || _vfrc=$?
    [[ "$_vfrc" -eq 0 ]] || { echo "FAIL: VF-8d control — an UNAUTHENTICATED gh means the arm is N/A (rc 0), not failed (got $_vfrc); this is the offline path"; failures=$((failures+1)); }
    unset -f gh

    # VF-9: arm (2) — the sandbox is not a git checkout, so the origin arm is N/A
    # (rc 0). Then give it a REAL git repo with an origin pointing at a path that
    # does not exist, so `git ls-remote` genuinely fails (hermetic — a local path,
    # no network), and assert the failure is re-raised rather than swallowed.
    gh() { case "$1" in auth) return 0 ;; api) return 0 ;; *) return 0 ;; esac; }
    # VF-9a control: NOT a git repo -> arm N/A, rc 0.
    _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "acme/widget" >/dev/null 2>&1 || _vfrc=$?
    [[ "$_vfrc" -eq 0 ]] || { echo "FAIL: VF-9a control — a non-git source root means the origin arm is N/A (rc 0), not failed (got $_vfrc)"; failures=$((failures+1)); }
    /usr/bin/git -C "$_vft" init -q >/dev/null 2>&1 || true
    # VF-9b control: a git repo with NO origin remote -> still N/A, rc 0.
    _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "acme/widget" >/dev/null 2>&1 || _vfrc=$?
    [[ "$_vfrc" -eq 0 ]] || { echo "FAIL: VF-9b control — a git repo with no 'origin' remote means the arm is N/A (rc 0), not failed (got $_vfrc)"; failures=$((failures+1)); }
    # VF-9: origin configured but UNREACHABLE -> the read genuinely fails.
    /usr/bin/git -C "$_vft" remote add origin "$_vft/does-not-exist.git" >/dev/null 2>&1 || true
    _vfrc=0; ( cd "$_vft" && /usr/bin/git ls-remote --tags origin ) >/dev/null 2>&1 || _vfrc=$?
    [[ "$_vfrc" -ne 0 ]] || { echo "FAIL: VF-9 probe control — raw git ls-remote must FAIL against a non-existent remote (the fixture is not driving a real failure)"; failures=$((failures+1)); }
    _vfrc=0; _audit_src_root="$_vft" _vf_build_claimed_set "acme/widget" >/dev/null 2>&1 || _vfrc=$?
    [[ "$_vfrc" -ne 0 ]] || { echo "FAIL: VF-9 a FAILING git ls-remote must return non-zero (got rc=0 — arm (2) is still swallowing failures)"; failures=$((failures+1)); }
    # VF-9c: and the CALLER fails closed.
    _vfv="$(_audit_src_root="$_vft" AUDIT_REPO="acme/widget" PMO_VERSION_FREENESS_CANDIDATE="v9.99" \
            _vf_compute_verdict lifecycle 2>/dev/null)"
    [[ "${_vfv%% *}" == "UNDECIDABLE" ]] || { echo "FAIL: VF-9c a failing origin-tags arm must fail the caller closed to UNDECIDABLE, got '$_vfv'"; failures=$((failures+1)); }
    unset -f gh
  else
    echo "FAIL: VF-7 could not stage version-grammar.sh into the sandbox — the caller-verdict assertions would be vacuous"; failures=$((failures+1))
  fi

  /bin/rm -rf "$_vft" 2>/dev/null || true

  # ─── Assertion group CP — complementary-pair ownership (Check 13b) [#4178] ────
  #
  # Offline, hermetic, sandbox-only. Every path is re-pointed through CP_* overrides
  # at a mktemp tree, so this never reads the live corpus, the live registry, the
  # built packages, or the operator's deployed skills. Extends this ONE self-test
  # entry rather than adding a second, so the CI invocation stays single.
  #
  # CP-1 vs CP-2/CP-3 IS the parent's opposite-verdict requirement: a DELIBERATE
  # complementary pair must PASS while an ACCIDENTAL fork must be flagged. A check
  # that passed both, or flagged both, would not satisfy it — this one does neither.
  # CP-4 is the anti-vacuity assertion: a check whose own config is missing must SAY
  # so. A registry-driven check that silently passes with no registry is the exact
  # "instrument that cannot fire" class this release exists to close.
  # CP-5/CP-6 are the shared-field assertions: a declared-shared section MISSING from
  # one copy is an ownership breach, while one whose CONTENT differs is a distinct
  # divergence signal — collapsing the two would make the live pair unrepresentable.
  echo "self-test: starting assertion group CP (complementary-pair ownership, #4178)" >&2
  local _p; _p="$(/usr/bin/mktemp -d -t complementarypair-selftest.XXXXXX)"
  /bin/mkdir -p "$_p/core/schemas" "$_p/operations/skills/fixture-skill/references" "$_p/packages"
  local _preg="$_p/pairs.txt"
  local _pmissing="$_p/no-such-registry.txt"
  local _pcanon="$_p/core/schemas/fixture-schema.md"
  local _pmirror="$_p/operations/skills/fixture-skill/references/fixture-schema.md"

  # _cp_seed <canonical-extra-h2...> — rewrite both fixture halves from scratch.
  # Base shape: canonical owns "Owned By Canonical", mirror owns "Owned By Mirror",
  # and "Shared Section" is carried by BOTH with identical bodies.
  _cp_seed_base() {
    /bin/cat > "$_pcanon" <<'EOF'
# Fixture Schema (canonical half)

## Shared Section
shared body line one
shared body line two

## Owned By Canonical
canonical-only body
EOF
    /bin/cat > "$_pmirror" <<'EOF'
# Fixture Schema (skill-local half)

## Shared Section
shared body line one
shared body line two

## Owned By Mirror
mirror-only body
EOF
  }
  _cp_seed_registry() {
    /usr/bin/printf '# fixture registry\ncore/schemas/fixture-schema.md|||operations/skills/fixture-skill/references/fixture-schema.md|||Owned By Canonical|||Owned By Mirror|||Shared Section\n' > "$_preg"
  }
  _cp_selftest_verdict() {
    CP_ROOT="$_p" CP_PAIRS_FILE="${1:-$_preg}" CP_PACKAGES="$_p/packages" CP_USER_SKILLS="$_p/nonexistent-skills" \
      _cp_compute_verdict 2>/dev/null
  }

  # CP-4 — registry ABSENT ⇒ NOSET. Asserted FIRST: the anti-vacuity default.
  _cp_seed_base; _cp_seed_registry
  _v="$(_cp_selftest_verdict "$_pmissing")"; _tok="${_v%%|*}"
  [[ "$_tok" == "NOSET" ]] || { echo "FAIL: CP-4 absent complementary-pair registry must verdict NOSET (not PASS), got '$_v'"; failures=$((failures+1)); }

  # CP-1 — registered pair, ownership intact ⇒ PASS.
  _v="$(_cp_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "PASS" ]] || { echo "FAIL: CP-1 an intact registered complementary pair must PASS, got '$_v'"; failures=$((failures+1)); }

  # CP-2 — a canonical-owned section LEAKED into the skill-local copy ⇒ OWNERSHIP-DRIFT.
  # This is the falsification test: move a declared-owned section across the pair
  # without updating the registry and the gate MUST flip.
  /usr/bin/printf '\n## Owned By Canonical\nleaked copy\n' >> "$_pmirror"
  _v="$(_cp_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "OWNERSHIP-DRIFT" ]] || { echo "FAIL: CP-2 a canonical-owned section leaked into the skill-local copy must verdict OWNERSHIP-DRIFT, got '$_v'"; failures=$((failures+1)); }

  # CP-5 — a declared-SHARED section MISSING from one copy ⇒ OWNERSHIP-DRIFT.
  # Proves the shared field is asserted, not decorative.
  _cp_seed_base
  /usr/bin/sed 's|^## Shared Section$|## Renamed Away|' "$_pmirror" > "$_p/m2" && /bin/mv "$_p/m2" "$_pmirror"
  _v="$(_cp_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "OWNERSHIP-DRIFT" ]] || { echo "FAIL: CP-5 a declared-shared section missing from one copy must verdict OWNERSHIP-DRIFT, got '$_v'"; failures=$((failures+1)); }

  # CP-6 — a declared-SHARED section present in BOTH but with DIFFERENT content ⇒
  # SHARED-DIVERGENCE, distinctly from OWNERSHIP-DRIFT. Without this assertion the
  # shared field could declare a region and assert nothing about it — which is the
  # live pair's only real drift surface.
  _cp_seed_base
  /usr/bin/sed 's|^shared body line two$|shared body line two (mirror variant)|' "$_pmirror" > "$_p/m3" && /bin/mv "$_p/m3" "$_pmirror"
  _v="$(_cp_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "SHARED-DIVERGENCE" ]] || { echo "FAIL: CP-6 a declared-shared section whose content differs must verdict SHARED-DIVERGENCE (not OWNERSHIP-DRIFT, not PASS), got '$_v'"; failures=$((failures+1)); }
  # …and the divergence must NOT be reported as an ownership breach: the ownership
  # declaration is correct, only the content drifted. Collapsing the two signals is
  # what would make the live pair's shared-but-drifted region unrepresentable.
  grep -qF 'OWNERSHIP-DRIFT|' <<< "$(_cp_selftest_verdict)" && { echo "FAIL: CP-6 content divergence in a shared section must NOT also emit OWNERSHIP-DRIFT"; failures=$((failures+1)); } || true

  # CP-3 — a DIVERGENT same-basename canonical<->skill-local pair that is NOT
  # registered ⇒ UNREGISTERED-PAIR. Seeded as a SECOND basename so the registered
  # pair stays intact: the assertion is that registration is what distinguishes the
  # two, not the mere existence of a cross-tree duplicate.
  _cp_seed_base
  /usr/bin/printf '# Forked doc (canonical side)\n\n## Some Section\nalpha\n' > "$_p/core/schemas/forked-doc.md"
  /usr/bin/printf '# Forked doc (skill side)\n\n## Some Section\nbeta\n' > "$_p/operations/skills/fixture-skill/references/forked-doc.md"
  _v="$(_cp_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "UNREGISTERED-PAIR" ]] || { echo "FAIL: CP-3 an unregistered cross-tree same-basename pair must verdict UNREGISTERED-PAIR, got '$_v'"; failures=$((failures+1)); }

  # CP-3b — the NAMED index-convention exclusion holds: README.md is a
  # per-directory index carried across dozens of directories, and excluding it is a
  # named decision (C13B_INDEX_BASENAMES), never a silent skip. Same shape as CP-3,
  # different basename ⇒ back to PASS.
  /bin/rm -f "$_p/core/schemas/forked-doc.md" "$_p/operations/skills/fixture-skill/references/forked-doc.md"
  /usr/bin/printf '# index (canonical side)\n' > "$_p/core/schemas/README.md"
  /usr/bin/printf '# index (skill side)\n' > "$_p/operations/skills/fixture-skill/references/README.md"
  _v="$(_cp_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "PASS" ]] || { echo "FAIL: CP-3b the named README.md index-convention exclusion must keep an intact registry at PASS, got '$_v'"; failures=$((failures+1)); }

  # CP-7 — a MALFORMED record (wrong field count) ⇒ MALFORMED, never a silent pass.
  # Guards the second half of the fail-closed posture: absence is CP-4, corruption
  # is this.
  /usr/bin/printf '# fixture registry\ncore/schemas/fixture-schema.md|||operations/skills/fixture-skill/references/fixture-schema.md|||Owned By Canonical\n' > "$_preg"
  _v="$(_cp_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "MALFORMED" ]] || { echo "FAIL: CP-7 a registry record without 5 fields must verdict MALFORMED, got '$_v'"; failures=$((failures+1)); }

  /bin/rm -rf "$_p" 2>/dev/null || true

  # ─── Assertion group RR — register runner-resolution (Check 62) [#4208] ───────
  #
  # Offline, hermetic, sandbox-only: every path is re-pointed through RR_STANDARD /
  # RR_ROOT at a mktemp tree, so this never reads the live standard or the live check
  # bank. Extends this ONE self-test entry rather than adding a second, so the CI
  # invocation stays single.
  #
  # RR-1 vs RR-2 IS the discrimination claim. A register whose pointers resolve must
  # verdict CLEAN while one whose named runner has stopped carrying the predicate must
  # verdict UNRESOLVED. A check that reported the same for both would be exactly the
  # vacuous control this milestone exists to eliminate — and RR-2 reproduces, in fixture
  # form, the defect the introducing release actually shipped.
  # RR-4/RR-5 are the anti-vacuity assertions: a check whose input set is EMPTY must SAY
  # so rather than pass. A resolution check that silently passes with zero pointers is
  # the "instrument that cannot fire" class one level up.
  # RR-6 is the PARSER control: the standard legitimately mentions the bare token in
  # prose, so a parser that matched prose would inflate the pointer count and could
  # report failures against sentences. It must parse to zero here.
  echo "self-test: starting assertion group RR (register runner-resolution, #4208)" >&2
  local _r; _r="$(/usr/bin/mktemp -d -t registerrunner-selftest.XXXXXX)"
  /bin/mkdir -p "$_r/core/standards"
  local _rstd="$_r/core/standards/fixture-standard.md"
  local _rdef="$_r/core/standards/fixture-runner-def.md"

  _rr_seed_standard() {
    /bin/cat > "$_rstd" <<'EOF'
# Fixture standard

A row declaring a `runner-def:` resolution pointer must resolve. This sentence is the
PARSER CONTROL: it mentions the bare token and declares nothing.

| Invariant | Enforcing gate |
|---|---|
| first invariant | **Runner:** fixture, `runner-def: core/standards/fixture-runner-def.md::FIX-01` |
| second invariant | **Runner:** fixture, `runner-def: core/standards/fixture-runner-def.md::FIX-02` |
EOF
  }
  _rr_seed_def() {
    /bin/cat > "$_rdef" <<'EOF'
# Fixture runner definition

**FIX-01 (first):** the first encoded predicate.
**FIX-02 (second):** the second encoded predicate.
EOF
  }
  _rr_selftest_verdict() {
    RR_STANDARD="${1:-$_rstd}" RR_ROOT="$_r" _rr_compute_verdict 2>/dev/null
  }

  # RR-5 — standard ABSENT ⇒ NOSET. Asserted FIRST: the anti-vacuity default.
  _rr_seed_standard; _rr_seed_def
  _v="$(_rr_selftest_verdict "$_r/core/standards/no-such-standard.md")"; _tok="${_v%%|*}"
  [[ "$_tok" == "NOSET" ]] || { echo "FAIL: RR-5 an absent gate-efficacy standard must verdict NOSET (not CLEAN), got '$_v'"; failures=$((failures+1)); }

  # RR-1 — every pointer resolves ⇒ CLEAN, and the COUNT is reported (2, not 3 — the
  # prose control must not have been counted).
  _v="$(_rr_selftest_verdict)"
  [[ "$_v" == "CLEAN|2" ]] || { echo "FAIL: RR-1 a register whose pointers all resolve must verdict CLEAN|2, got '$_v'"; failures=$((failures+1)); }

  # RR-2 — the named runner no longer CARRIES the predicate ⇒ UNRESOLVED. This is the
  # falsification test, and it reproduces the defect the introducing release shipped:
  # the row is untouched and still names its runner; only the runner's check set changed.
  /usr/bin/sed 's/FIX-01/FIXX01/g' "$_rdef" > "$_rdef.tmp" && /bin/mv "$_rdef.tmp" "$_rdef"
  _v="$(_rr_selftest_verdict)"
  [[ "$_v" == "UNRESOLVED|1|2" ]] || { echo "FAIL: RR-2 a runner that no longer carries its declared anchor must verdict UNRESOLVED|1|2, got '$_v'"; failures=$((failures+1)); }

  # RR-3 — the runner-definition FILE is gone ⇒ UNRESOLVED for every pointer.
  /bin/rm -f "$_rdef"
  _v="$(_rr_selftest_verdict)"
  [[ "$_v" == "UNRESOLVED|2|2" ]] || { echo "FAIL: RR-3 an absent runner-definition file must verdict UNRESOLVED|2|2, got '$_v'"; failures=$((failures+1)); }

  # RR-4 — a register declaring ZERO pointers ⇒ NOSET, never CLEAN.
  _rr_seed_def
  /usr/bin/sed 's/runner-def: /runnerdef /g' "$_rstd" > "$_rstd.tmp" && /bin/mv "$_rstd.tmp" "$_rstd"
  _v="$(_rr_selftest_verdict)"; _tok="${_v%%|*}"
  [[ "$_tok" == "NOSET" ]] || { echo "FAIL: RR-4 a register declaring zero runner-def pointers must verdict NOSET (not CLEAN), got '$_v'"; failures=$((failures+1)); }

  # RR-6 — PARSER control: a file carrying ONLY prose mentions of the bare token parses
  # to zero declarations. Without this, RR-1's CLEAN|2 could be CLEAN|3 with one
  # nonsense pointer that happens to resolve, and the count assertion would be the only
  # thing standing between the check and matching sentences.
  /bin/cat > "$_r/core/standards/prose-only.md" <<'EOF'
A row declaring a `runner-def:` resolution pointer must resolve.
Another sentence mentioning runner-def: with no pointer form at all.
EOF
  _v="$(_rr_selftest_verdict "$_r/core/standards/prose-only.md")"; _tok="${_v%%|*}"
  [[ "$_tok" == "NOSET" ]] || { echo "FAIL: RR-6 prose-only mentions of the runner-def token must parse to zero declarations (NOSET), got '$_v'"; failures=$((failures+1)); }

  /bin/rm -rf "$_r" 2>/dev/null || true

  if [[ "$failures" -gt 0 ]]; then
    echo "self-test: FAIL ($failures failure(s))" >&2
    return 1
  fi
  echo "self-test: PASS" >&2
  echo "  version-freeness claimed-set column pinning validated (#3724 AC-N, group VF):" >&2
  echo "    VF-1 DEPLOYED row extracted / VF-2 VERIFIED row excluded / VF-3 State is NOT the Tag column / VF-4 column-order shift survived (name-pinned, not ordinal) / VF-5 malformed header reported on stderr / VF-6 malformed header returns non-zero + VF-6b well-formed returns 0 (control) / VF-7 the CALLER fails closed to UNDECIDABLE(partial-by-failure) + VF-7b FREE control + VF-7c gate surface (DT-2: loud failure is observable, not merely emitted)" >&2
  echo "  close-completeness invariant validated (#1290 AC5; mis-arm group #4176):" >&2
  echo "    explicit-__none__ cutover SKIPs / abbreviated scaffold caught (INCOMPLETE) / complete set CLEAN / VERIFIED-scoped (DEPLOYED excluded, VERIFIED included)" >&2
  echo "    mis-arm (5) prefix-shortened cutoff WARNs naming the armed row / (6) exact-row cutoff does NOT warn but still names it / (7) no-match cutoff WARNs vacuous (zero rows asserted)" >&2
  echo "  decision-emission minimum set validated (#4026, group DE):" >&2
  echo "    DE-1 dormant SKIP / DE-2 seeded zero-emission INCOMPLETE / DE-3 complete CLEAN 1 / DE-4 partial-set INCOMPLETE / DE-5 legacy-key-only INCOMPLETE / DE-6+DE-7 pre-cutover + DEPLOYED rows excluded / DE-7b VERIFIED flip counted / DE-8 rung-2 resolution / DE-9 absent asserted-set NOSET" >&2
  echo "  complementary-pair ownership validated (#4178, group CP):" >&2
  echo "    CP-4 absent registry NOSET / CP-1 intact pair PASS / CP-2 leaked owned-section OWNERSHIP-DRIFT / CP-5 missing shared-section OWNERSHIP-DRIFT / CP-6 divergent shared-section SHARED-DIVERGENCE / CP-3 unregistered cross-tree pair UNREGISTERED-PAIR / CP-3b named README.md exclusion holds / CP-7 malformed record MALFORMED" >&2
  echo "  register runner-resolution validated (#4208, group RR):" >&2
  echo "    RR-5 absent standard NOSET / RR-1 all pointers resolve CLEAN|2 / RR-2 runner no longer carries its anchor UNRESOLVED|1|2 (the shipped defect, in fixture form) / RR-3 absent runner-definition file UNRESOLVED|2|2 / RR-4 zero pointers NOSET / RR-6 prose-only token mentions parse to zero (parser control)" >&2
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

# ─── Mode: --check-decision-emission (the Stage-13 decision-emission probe) — #4026 ─
#
# Runs ONLY the decision-emission verdict (not the full --check suite) and maps the verdict
# to an EXIT CODE. Invoked from stage-13-close.md Phase A8.2 at close-out; there is
# deliberately NO CI caller, which is exactly why the gate declares
# `posture: advisory` / `enforcement-surface: deploy-time-only` per gate-efficacy-standard.md
# Requirement (b′) — a check with no pre-merge surface cannot honestly declare `required`.
#
# Sentinel-aware, mirroring cmd_check_close_completeness: the committed
# .github/decision-emission.enforce marker's first non-comment token decides whether an
# INCOMPLETE (or NOSET) verdict BLOCKS (enforce => exit 1) or is reported non-blocking
# (warn / absent => exit 0, true verdict still printed). It ships `warn`.
#
# NOSET is treated like INCOMPLETE rather than like SKIP on purpose: an emission gate with
# no asserted set is a control that cannot fail, which is the defect class this release
# exists to close — surfacing it as a benign skip would reproduce it.
#
#   exit 0  — CLEAN, SKIP (dormant / no in-scope release / corpus absent), or a
#             non-blocking INCOMPLETE/NOSET while the sentinel token is not `enforce`.
#   exit 1  — INCOMPLETE / NOSET under `enforce`, or an unexpected verdict (fail-closed).
cmd_check_decision_emission() {
  validate_workspace
  detect_install_path || true

  local de_enforce_file="${DECISION_EMISSION_ENFORCE_FILE:-.github/decision-emission.enforce}"
  local de_enforce="warn" _de_tok_line
  if [[ -f "$de_enforce_file" ]]; then
    _de_tok_line="$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$de_enforce_file" 2>/dev/null | /usr/bin/head -1 | /usr/bin/tr -d '[:space:]')"
    [[ "$_de_tok_line" == "enforce" ]] && de_enforce="enforce"
  fi

  local verdict tok
  verdict="$(_de_compute_verdict "gate")"
  tok="${verdict%% *}"
  case "$tok" in
    CLEAN)
      log "decision-emission: ${verdict#CLEAN } post-cutover VERIFIED release(s) emitted every asserted MUST class — OK"
      log "  Scope note: this asserts EXISTENCE (>=1 row per asserted class), not fidelity. It cannot detect a wrong payload, a mis-keyed subject, or a row emitted for a decision never rendered."
      exit 0
      ;;
    SKIP)
      log "decision-emission: SKIP — ${verdict#SKIP }"
      exit 0
      ;;
    NOSET)
      log "decision-emission: NOSET — ${verdict#NOSET }"
      log "  A minimum-emission gate with no asserted set asserts nothing. Restore core/deploy/allowlists/decision-emission-asserted-set.txt (its classes MUST be MUST rows of the playbook's EMISSION-CONTRACT block; release/tools/check-emission-contract-subset.sh enforces that relation in CI)."
      [[ "$de_enforce" == "enforce" ]] && exit 1
      log "  WARN-MODE (sentinel '$de_enforce_file' token != enforce): reporting the true verdict but NOT blocking."
      exit 0
      ;;
    INCOMPLETE)
      log "decision-emission: INCOMPLETE — ${verdict#INCOMPLETE } (missing-class count / checked-release count; see detail above)"
      log "  A post-cutover release closed without emitting a MUST class. The remedy is to emit the missing row(s) per orchestration-playbook.md Procedure 4a — never to waive the finding."
      if [[ "$de_enforce" == "enforce" ]]; then
        exit 1
      fi
      log "  WARN-MODE (sentinel '$de_enforce_file' token != enforce): reporting the true verdict but NOT blocking — the flip to 'enforce' is an operator decision recorded in core/standards/gate-efficacy-standard.md, never auto-promoted by hit count."
      exit 0
      ;;
    *)
      log "decision-emission: unexpected verdict '$verdict' — fail-closed"
      exit 1
      ;;
  esac
}

# ─── Mode: --check-required-subset (the CI load-bearing-check subset runner) — #1485 ─
#
# Runs the network-free, install-independent, load-bearing subset of the
# deploy.sh --check battery pre-merge in CI and maps the AGGREGATE verdict to an
# EXIT CODE (the verdict->exit contract the CI gate depends on). The subset is an
# ENUMERATED ALLOWLIST of check-ids — NOT "all ~38 checks" — selected by the
# predicate { network-free AND install-independent AND posture:required AND NOT
# already covered by a dedicated CI mirror }. It is a real allowlist (not a runtime
# grep) so it is auditable and slots into the #45 per-check registry; each member
# runs its shared _cNN_compute_verdict "gate" body (single-engine, no re-encoded
# predicate — CIAC-2). Checks with a DEDICATED CI mirror are EXCLUDED so an
# invariant is never double-gated (R6): Check 6 (skill-canonical-structure-check.yml),
# Check 7 (skill-package-freshness.yml #2656), Check 32 (release-corpus-completeness.yml
# #1484), Check 41 (version-freeness.yml), Check 48 (close-completeness.yml).
#
# TODAY the predicate resolves to exactly ONE member — Check 38
# (hook-registry-index-freshness), the only explicit posture:required check lacking
# a dedicated mirror. New members are appended here as future posture:required
# checks are back-filled (#1036 / #313).
#
# Surface = "gate": fail-closed. Warn-vs-enforce at the CI surface is decided by the
# committed .github/deploy-check-ci.enforce sentinel — during the warn-mode window an
# in-scope FAIL is reported but swallowed (exit 0); flip the token to 'enforce' after
# shakedown to block. Mirrors cmd_check_close_completeness's sentinel-aware contract.
#
#   exit 0  — every subset member passed, OR a member FAILed but the sentinel is warn
#             (true verdict reported, not blocking).
#   exit 1  — a subset member FAILed AND the sentinel is enforce, OR any member
#             returned an unexpected/ERROR verdict (fail-closed regardless of sentinel).
cmd_check_required_subset() {
  validate_workspace
  detect_install_path || true

  # Sentinel-aware enforcement (committed .github/deploy-check-ci.enforce). The
  # first non-comment token decides whether an in-scope FAIL BLOCKS (enforce) or is
  # SWALLOWED non-blocking (warn / absent). The probe reads the sentinel directly,
  # so it is load-bearing without a CI workflow wired first (a thin CI caller still
  # consumes this exit code once added).
  local rs_enforce_file="${DEPLOY_CHECK_CI_ENFORCE_FILE:-.github/deploy-check-ci.enforce}"
  local rs_enforce="warn" _rs_tok_line
  if [[ -f "$rs_enforce_file" ]]; then
    _rs_tok_line="$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$rs_enforce_file" 2>/dev/null | /usr/bin/head -1 | /usr/bin/tr -d '[:space:]')"
    [[ "$_rs_tok_line" == "enforce" ]] && rs_enforce="enforce"
  fi

  # Enumerated allowlist: "check-id:verdict-body". TODAY: Check 38 only. Append a
  # row per future posture:required check that lacks a dedicated CI mirror.
  local -a rs_checks=(
    "hook-registry-index-freshness:_c38_compute_verdict"
  )

  local rs_fail=0 rs_err=0 rs_pass=0 _entry _id _fn _verdict _tok
  for _entry in "${rs_checks[@]}"; do
    _id="${_entry%%:*}"
    _fn="${_entry##*:}"
    _verdict="$("$_fn" "gate")"
    _tok="${_verdict%% *}"
    case "$_tok" in
      FRESH|CLEAN|PASS|FREE|SKIP|NA)
        log "required-subset: $_id — OK ($_tok)"
        rs_pass=$((rs_pass + 1))
        ;;
      STALE|NOT_FREE|INCOMPLETE|FAIL)
        log "required-subset: $_id — FAIL ($_verdict)"
        rs_fail=$((rs_fail + 1))
        ;;
      *)
        log "required-subset: $_id — ERROR/unexpected verdict ($_verdict) — fail-closed"
        rs_err=$((rs_err + 1))
        ;;
    esac
  done

  # An unexpected/ERROR verdict is a tooling failure, not a calibration finding —
  # always fail-closed regardless of the warn/enforce sentinel (mirrors
  # cmd_check_close_completeness).
  if [[ $rs_err -gt 0 ]]; then
    log "required-subset: $rs_err check(s) returned an unexpected/ERROR verdict — fail-closed exit 1"
    exit 1
  fi
  if [[ $rs_fail -gt 0 ]]; then
    if [[ "$rs_enforce" == "enforce" ]]; then
      log "required-subset: $rs_fail load-bearing check(s) FAILed (sentinel enforce) — blocking exit 1"
      exit 1
    fi
    log "required-subset: $rs_fail load-bearing check(s) FAILed but sentinel '$rs_enforce_file' token != enforce — WARN-MODE, reporting not blocking (flip the token to 'enforce' after shakedown)"
    exit 0
  fi
  log "required-subset: all $rs_pass load-bearing check(s) passed"
  exit 0
}

# ─── Mode: --check-release-corpus (the CI release-corpus-completeness probe) — #1484 ─
#
# Runs ONLY Check 32's release-corpus completeness verdict (not the full --check
# suite) and maps the verdict to an EXIT CODE for the CI gate. Warn-vs-enforce at the
# CI surface is decided by the committed .github/release-corpus-completeness.enforce
# sentinel — during the warn-mode window an INCOMPLETE verdict is reported but
# swallowed (exit 0); flip the token to 'enforce' after shakedown to block. Mirrors
# cmd_check_close_completeness's sentinel-aware contract. Surface = "gate": fail-closed
# (an offline anchor for the post-cutover published-Release sub-check is a finding, not
# degraded to N/A). This gate is the SINGLE canonical required-context for Check 32
# (the --check-required-subset runner EXCLUDES Check 32, so it is never double-gated).
#
#   exit 0  — CLEAN (every in-scope row complete) / SKIP (LOG absent — nothing to
#             assert), OR INCOMPLETE but the sentinel is warn (true verdict reported).
#   exit 1  — INCOMPLETE AND the sentinel is enforce, OR an unexpected verdict
#             (fail-closed regardless of the sentinel).
cmd_check_release_corpus() {
  validate_workspace
  detect_install_path || true

  local rc_enforce_file="${RELEASE_CORPUS_ENFORCE_FILE:-.github/release-corpus-completeness.enforce}"
  local rc_enforce="warn" _rc_tok_line
  if [[ -f "$rc_enforce_file" ]]; then
    _rc_tok_line="$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$rc_enforce_file" 2>/dev/null | /usr/bin/head -1 | /usr/bin/tr -d '[:space:]')"
    [[ "$_rc_tok_line" == "enforce" ]] && rc_enforce="enforce"
  fi

  local verdict tok
  verdict="$(_c32_compute_verdict "gate")"
  tok="${verdict%% *}"
  case "$tok" in
    CLEAN)
      log "release-corpus: ${verdict#CLEAN } logged release(s) on/after the cutover carry the full corpus set — OK"
      exit 0
      ;;
    SKIP)
      log "release-corpus: SKIP — ${verdict#SKIP } (nothing to assert)"
      exit 0
      ;;
    INCOMPLETE)
      log "release-corpus: INCOMPLETE — ${verdict#INCOMPLETE } (findings count / checked-row count; see detail above)"
      log "  A close dropped a Stage-13 release-corpus output (INDEX row / DIGEST entry / NOTES file [+ tag / Release])."
      log "  Backfill per release/references/pipeline/stage-13-close.md Phase B."
      if [[ "$rc_enforce" == "enforce" ]]; then
        exit 1
      fi
      log "  WARN-MODE (sentinel '$rc_enforce_file' token != enforce): reporting the true verdict but NOT blocking — flip the token to 'enforce' after shakedown."
      exit 0
      ;;
    *)
      log "release-corpus: unexpected verdict '$verdict' — fail-closed"
      exit 1
      ;;
  esac
}

# ─── Mode: --check-package-freshness (the CI .skill content-freshness probe) — #2656 ─
#
# Runs ONLY Check 7's package content-freshness verdict — the FULL rostered-skill
# content-hash comparison, no per-skill diff-scoping (the WORKFLOW path-filters the
# TRIGGER, so no parallel scoping logic lives here; a stale package for ANY skill
# correctly blocks) — and maps the verdict to an EXIT CODE for the CI gate.
# Warn-vs-enforce at the CI surface is decided by the committed
# .github/skill-package-freshness.enforce sentinel. Mirrors cmd_check_close_completeness.
#
# VERDICT -> EXIT CONTRACT (the authoring home; every other surface CITES this table).
# A STALE verdict NEVER maps to exit 0 — a probe that says STALE in prose and OK in $?
# invites a caller to conclude the opposite of the truth.
#
#   verdict   sentinel token   exit   caller reads it as
#   -------   --------------   ----   ----------------------------------------------
#   FRESH     any              0      pass — every rostered package is content-current
#   STALE     != enforce       2      ADVISORY finding: not fresh, not blocking. Non-
#                                     zero (so `-eq 0` cannot mis-read it) and not 1
#                                     (so a caller can still tell advisory from block).
#   STALE     enforce          1      BLOCKING finding — the gate must fail closed
#   <other>   any              1      unexpected verdict — fail-closed, sentinel-agnostic
#
# The advisory value 2 follows the in-tree precedent of core/deploy/tools/cross-module-audit.sh
# (2 = "violations detected (advisory)" vs 1 = BLOCKER). Enforcement POLICY stays in the
# sentinel, which this probe remains the single reader of; the CI caller dispatches on the
# integer and never re-parses the sentinel file.
cmd_check_package_freshness() {
  validate_workspace
  detect_install_path || true

  local pf_enforce_file="${SKILL_PACKAGE_FRESHNESS_ENFORCE_FILE:-.github/skill-package-freshness.enforce}"
  local pf_enforce="warn" _pf_tok_line
  if [[ -f "$pf_enforce_file" ]]; then
    _pf_tok_line="$(/usr/bin/grep -vE '^[[:space:]]*(#|$)' "$pf_enforce_file" 2>/dev/null | /usr/bin/head -1 | /usr/bin/tr -d '[:space:]')"
    [[ "$_pf_tok_line" == "enforce" ]] && pf_enforce="enforce"
  fi

  local verdict tok
  verdict="$(_c7_compute_verdict "gate")"
  tok="${verdict%% *}"
  case "$tok" in
    FRESH)
      log "package-freshness: ${verdict#FRESH } rostered skill package(s) content-fresh — OK"
      exit 0
      ;;
    STALE)
      log "package-freshness: STALE — ${verdict#STALE } (count + stale skill(s); see detail above)"
      log "  A skill's SKILL.md or references/ changed without rebuilding its .skill package."
      log "  Rebuild via core/deploy/tools/build-skill-packages.sh <skill> and commit the package + its .sha256 sidecar."
      if [[ "$pf_enforce" == "enforce" ]]; then
        exit 1
      fi
      log "  WARN-MODE (sentinel '$pf_enforce_file' token != enforce): reporting the true verdict as ADVISORY — exit 2, so no caller can read a STALE package as fresh, and distinct from the blocking exit 1. Flip the token to 'enforce' after shakedown."
      exit 2
      ;;
    *)
      log "package-freshness: unexpected verdict '$verdict' — fail-closed"
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
  # Offset-bearing (%z) — --report output is Stage-13 evidence, and an evidence
  # artifact stamped with an unresolvable instant is the defect (#3718).
  echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S%z')"
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
      # Parse via the version-grammar SSOT (#1676) rather than a local sed parser
      # (#1800 zero-drift — this is the report-mode mirror of Check 39, the SAME
      # duplicate parser as cmd_check's c39_ block). Source set-e-safe (empty
      # positional; --self-test inert). Lib absent => N/A PASS (never-FAIL idiom).
      local c39r_lib="$_audit_src_root/release/tools/version-grammar.sh"
      if [[ ! -f "$c39r_lib" ]]; then
        echo "[PASS] version-stamp-skew — N/A: version-grammar.sh (#1676 SSOT comparator) not present"
        PASS=$((PASS + 1))
      else
        # shellcheck source=/dev/null
        source "$c39r_lib" ""
        if ! version_canonical "$c39r_local" || ! version_canonical "$c39r_anchor"; then
          echo "[FAIL] version-stamp-skew — .version ('$c39r_local') or latest-Release ('$c39r_anchor') not canonical (vMAJOR.MINOR[.PATCH])"
          FAIL=$((FAIL + 1))
        else
          local c39r_l_maj c39r_l_min c39r_a_maj c39r_a_min _c39r_patch
          read -r c39r_l_maj c39r_l_min _c39r_patch <<<"$(version_parse "$c39r_local")"
          read -r c39r_a_maj c39r_a_min _c39r_patch <<<"$(version_parse "$c39r_anchor")"
          if [[ "$c39r_l_maj" != "$c39r_a_maj" ]]; then
            echo "[FAIL] version-stamp-skew — .version ($c39r_local) different major-lineage than latest published Release ($c39r_anchor)"
            FAIL=$((FAIL + 1))
          else
            local c39r_dist=$(( c39r_l_min - c39r_a_min )); local c39r_abs=${c39r_dist#-}
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
    --check-decision-emission)
      # Stage-13 decision-emission probe (#4026): runs ONLY Check 61's verdict and exits
      # per the verdict (0 CLEAN/SKIP, 1 INCOMPLETE/NOSET when the committed
      # .github/decision-emission.enforce sentinel is `enforce`; fail-closed on an
      # unexpected verdict). The same logic ALSO fires inside the full --check suite
      # (Check 61, committed warn default) — one shared body (_de_compute_verdict), no
      # copy. Invoked from stage-13-close.md Phase A8.2; NO CI caller by design, which is
      # why the gate declares advisory / deploy-time-only.
      cmd_check_decision_emission
      ;;
    --check-required-subset)
      # CI runner (#1485): runs the enumerated load-bearing subset (network-free AND
      # install-independent AND posture:required AND no dedicated CI mirror) and exits
      # per the AGGREGATE verdict, honoring the committed .github/deploy-check-ci.enforce
      # sentinel (warn swallows a FAIL, enforce blocks). Each member runs its shared
      # _cNN_compute_verdict "gate" body — no re-encoded predicate. Today seeded with
      # Check 38 (hook-registry-index-freshness). Used by .github/workflows/deploy-check-ci.yml.
      cmd_check_required_subset
      ;;
    --check-release-corpus)
      # Single-check CI release-corpus-completeness probe (#1484): runs ONLY Check 32's
      # verdict and exits per the verdict (0 CLEAN/SKIP, 1 INCOMPLETE — sentinel-gated
      # at .github/release-corpus-completeness.enforce; fail-closed at the gate surface).
      # The Check 32 logic ALSO fires inside the full --check suite — one shared body
      # (_c32_compute_verdict), no copy. Used by .github/workflows/release-corpus-completeness.yml.
      cmd_check_release_corpus
      ;;
    --check-package-freshness)
      # Single-check CI .skill package content-freshness probe (#2656): runs ONLY
      # Check 7's full content-hash verdict and exits per the verdict (0 FRESH; 2 STALE
      # advisory when the .github/skill-package-freshness.enforce sentinel is not enforce;
      # 1 STALE when it IS enforce; 1 fail-closed on an unexpected verdict — never 0 on
      # STALE, see the contract table on cmd_check_package_freshness). The Check 7 logic
      # ALSO fires inside the full --check
      # suite — one shared body (_c7_compute_verdict), no copy. Used by
      # .github/workflows/skill-package-freshness.yml.
      cmd_check_package_freshness
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
      echo "Usage: ./deploy.sh [--deploy [skill...] | --all | --check [--warn] | --check-lifecycle | --check-version-freeness | --check-close-completeness | --check-required-subset | --self-test | --report]"
      echo ""
      echo "Modes:"
      echo "  --deploy [skill...]          Deploy changed skills to Cowork install path (auto-detect or manual)"
      echo "  --all                        Deploy the full skill roster + all packages (explicit bootstrap / redeploy-everything)"
      echo "  --check [--warn]             Validate platform health (--warn exits 0 even with issues)"
      echo "  --check-lifecycle            List retired/dormant checks + dispositions + reactivation anchors"
      echo "  --check-version-freeness     Pre-merge version-freeness probe (Check 41 only; exits 1 on a claimed/undecidable candidate) (#1677)"
      echo "  --check-close-completeness   Close-completeness probe (Check 48 only; exits 1 on a VERIFIED row missing a Stage-13 output) (#1290)"
      echo "  --check-required-subset      CI subset runner — enumerated load-bearing checks (seeded: Check 38); honors .github/deploy-check-ci.enforce (#1485)"
      echo "  --check-release-corpus       Release-corpus completeness probe (Check 32 only; exits 1 on an INCOMPLETE row set when enforce) (#1484)"
      echo "  --check-decision-emission    Decision-emission minimum-set probe (Check 61 only; advisory/deploy-time-only; exits 1 on INCOMPLETE/NOSET when enforce) (#4026)"
      echo "  --check-package-freshness    .skill package content-freshness probe (Check 7 only; FRESH=0, STALE=2 advisory / 1 when enforce, unexpected=1) (#2656)"
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
