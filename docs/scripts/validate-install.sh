#!/usr/bin/env bash
# validate-install.sh — Workspace install + first-task validation for pmo-platform v2
#
# Verifies (Mode A) that setup-workspace.sh succeeded AND (Mode B) that a demo
# skill invocation produces structurally-correct output. Read-mostly on operator
# state with a bounded write surface (.workspace-validation/<timestamp>/).
#
# Source-of-truth spec: the validate-install Stage 5 Solutioning spec.
# Adversarial counter-designs absorbed per the Phase A6.5 review (FAIL
# verdict; 1 Blocker + 2 Majors; 3 FMs; 3 CDs):
#   - PR-1 (Blocker): Mode B file-existence premise was false — prompt-builder
#       is response-text-only (no file-write behavior). Counter-Design CD-1A:
#       hand-off instructs operator to copy response, then pipe via
#       `pbpaste | validate-install.sh --mode first-task --continue`. The script
#       reads stdin (or pbpaste fallback) and writes the artifact itself. Mode
#       B verification no longer depends on the operator using a file-save UI
#       Claude Code does not document.
#   - PR-2 (Major): "both modules" parent-spec amend at Stage 5 was relitigation
#       of operator-pre-decided scope. RESOLVED IN the sibling getting-started
#       work — single demo skill `prompt-builder` adopted per CD-1 + CD-3 hybrid (cross-module
#       composition is module-apis.md's job, not validate-install.sh's).
#       Aligned: this script uses the same single demo skill.
#   - PR-3 (Major): `--skip-checks A4,A10` flag created verifier-identity
#       creep — same PASS verdict carried three different semantic meanings.
#       Counter-Design CD-3A: replace with `--mode operator-pre-existing`.
#       Workspaces predating setup-workspace.sh use the dedicated mode (drops
#       state-marker + workspace-config requirements). Aggregate verdict semantics are
#       per-mode unambiguous. No `--skip-checks` flag exists.
#   - FM-1 (INPUT): Demo-skill version stability assumed but not verified.
#       Mitigation: B4 uses MINIMUM-VIABLE-ARTIFACT signals (non-empty +
#       at least one heading OR fenced code block + no [INSERT]/[TBD]
#       placeholders) rather than version-locked H2-required-plus-6-keywords.
#       Skill frontmatter version captured into run.json
#       (`demo_skill_version` field) so future drift is detectable.
#   - FM-2 (OUT): stdout/stderr channel conflict for machine parseability.
#       Mitigation: contract is explicit — stdout is human-readable; run.json
#       is the machine-parseable surface. Test contract reads run.json, not
#       grep against stdout. Aggregate summary is a human convenience; the
#       JSON sidecar is authoritative.
#   - FM-3 (HAND): Phantom forward-reference to `setup-workspace.sh
#       --init-only-state`. Empirically verified at HEAD — the flag IS
#       implemented in the actual setup-workspace.sh (the adversarial
#       review was based on an earlier spec draft). FM-3 not applicable;
#       hint retained as documented capability.
#   - CD-A (alternative — split into two scripts): NOT ADOPTED. Single
#       entrypoint matches the operator's mental model (one script to verify
#       both layers); composition cost is low because Mode A FAIL skips
#       Mode B cleanly (mode_all routing).
#   - CD-B (deterministic v2 first-task replaces operator hand-off): NOT
#       ADOPTED. Operator-facing skill demonstration IS the value of Mode B
#       for onboarding — replacing it with deploy.sh --check would duplicate
#       A8 and lose the first-look demonstration. Hand-off complexity
#       mitigated by CD-1A (clipboard pipe; one operator action, not five).
#   - CD-C (parallel validate-existing.sh for operator-pre-existing): NOT
#       ADOPTED as separate script; ADOPTED as `--mode operator-pre-existing`
#       per CD-3A reasoning above. Same script, modal sub-mode boundary.
#
# Bash version compatibility: written to run under macOS system bash 3.2.57
# (Darwin 25.x default). NO associative arrays (declare -A), NO parameter
# transformation. Same posture as setup-workspace.sh.
#
# Cross-references:
#   - Author validate-install.sh + first-task validation (parent work item)
#   - Stage 5 Solutioning spec (this script implements)
#   - setup-workspace.sh (this script verifies its output)
#   - GETTING_STARTED.md (cross-references this script as post-walkthrough verify)
#   - INSTALL.md (cross-references this script as post-install verify)
#
# Usage:
#   ./validate-install.sh [--mode {install,first-task,all,operator-pre-existing}]
#                         [--source-repo PATH] [--workspace-root PATH]
#                         [--validation-dir PATH] [--continue] [--dry-run]
#                         [--verbose] [--help]
#
# Safe to run repeatedly; each invocation writes to a fresh timestamped artifact
# dir. Read-only on operator state except the bounded ${VALIDATION_DIR} write
# surface.
#
# Exit codes (sysexits(3)):
#   0   — success (all PASS or all PASS-with-SKIPs)
#   1   — generic failure (one or more FAIL steps; aggregate verdict FAIL)
#   64  — EX_USAGE (invalid argv)
#   66  — EX_NOINPUT (missing source-repo or workspace-root)
#   69  — EX_UNAVAILABLE (missing prerequisite — jq, etc.)
#   78  — EX_CONFIG (non-Darwin platform; cross-platform deferred)
#   130 — SIGINT (operator Ctrl-C)

set -Eeuo pipefail

# --- Section 1: Platform detection (must run first; no state mutation) ---
# Non-Darwin is a SOFT, opt-in-bypassable gate (v3.91 / #303), not a hard fail.
# CI and #304's cross-platform matrix set PMO_ALLOW_NON_DARWIN=1 so the non-macOS
# legs run past this point (relaxing setup-workspace.sh's gate alone is not enough
# — this second, independent gate must relax too, per Stage-5 REC-3). Default
# (unset) preserves the protective exit 78; EX_CONFIG(78) is retained for the
# genuinely-unsupported (un-opted-in) case. Runs before the log helpers are
# defined, so it uses printf directly.
if [ "$(uname -s)" != "Darwin" ]; then
  if [ -n "${PMO_ALLOW_NON_DARWIN:-}" ]; then
    printf 'WARN: non-Darwin platform (%s); proceeding under PMO_ALLOW_NON_DARWIN.\n' "$(uname -s)" >&2
  else
    printf 'ERROR: Darwin-only on current release.\n' >&2
    printf 'Set PMO_ALLOW_NON_DARWIN=1 to proceed on non-macOS (CI / cross-platform matrix).\n' >&2
    exit 78
  fi
fi

# --- Section 2: Constants + defaults ---
readonly SCRIPT_VERSION="v1.04"
readonly DEFAULT_WORKSPACE_ROOT="${HOME}/Claude"
readonly DEFAULT_SOURCE_REPO="${DEFAULT_WORKSPACE_ROOT}/pmo-platform"
readonly DEMO_SKILL="prompt-builder"
readonly DEMO_SKILL_PROMPT='critique and rewrite this prompt: "summarize the document"'
readonly STATE_FILE_NAME=".workspace-setup.state"
readonly STATE_SCHEMA_VERSION="1.0"
readonly OPERATOR_TOML_PATH="${HOME}/.config/pmo-platform/operator.toml"

# Mode A check count (11) is the upper bound; --mode operator-pre-existing
# runs a subset that drops state-marker (A4) and operator.toml (A10). A6b
# (hook-wiring re-home posture, #4436) runs in BOTH sub-modes.
readonly MODE_A_TOTAL=11
readonly MODE_B_TOTAL=4

# --- Section 3: Mutable state (scalars only; bash-3.2-compatible) ---
MODE="all"
WORKSPACE_ROOT=""
SOURCE_REPO=""
VALIDATION_DIR=""
CONTINUE=0
DRY_RUN=0
VERBOSE=0

# Aggregate counters (per-mode + overall)
MODE_A_PASS=0
MODE_A_FAIL=0
MODE_A_SKIP=0
MODE_A_FAIL_FLAG=0
MODE_B_PASS=0
MODE_B_FAIL=0
MODE_B_SKIP=0
MODE_B_FAIL_FLAG=0
AGGREGATE_FAIL=0

# Per-step record file (JSON Lines accumulated then rendered into run.json)
STEP_RECORDS_FILE=""
FAILING_STEPS_FILE=""    # newline-separated "[STEP] CHECK: diagnostic | hint"
TIMESTAMP=""
SESSION_TMPDIR=""
DEMO_SKILL_VERSION=""    # captured from frontmatter at B1 (FM-1 mitigation)

# --- Section 4: Usage banner ---
usage() {
  cat <<'USAGE'
Usage: validate-install.sh [OPTIONS]

Verify pmo-platform install (Mode A) and first-task invocation (Mode B).

Options:
  --mode {install,first-task,all,operator-pre-existing}
                          Select scope (default: all).
                          - install: Mode A only (10 checks).
                          - first-task: Mode B only (4 checks).
                          - all: Mode A followed by Mode B.
                          - operator-pre-existing: subset of Mode A for
                            workspaces that predate setup-workspace.sh
                            — drops A4 state-marker + A10 operator.toml.
  --source-repo PATH      Path to cloned pmo-platform (default: ${HOME}/Claude/pmo-platform).
  --workspace-root PATH   Workspace root (default: ${HOME}/Claude).
  --validation-dir PATH   Artifact directory override (default:
                          ${WORKSPACE_ROOT}/.workspace-validation/<timestamp>/).
  --continue              Mode B: read demo-skill output from stdin (or pbpaste
                          fallback), write to artifact, run B3 + B4 only.
  --dry-run               Preview planned checks; perform no state mutation.
  --verbose               Per-step diagnostic output to stderr.
  --help                  Show this help.

Output channels:
  stdout   — human-readable per-step lines + aggregate summary.
  run.json — machine-parseable record at ${VALIDATION_DIR}/run.json
             (authoritative for CI/tooling consumers — do not grep stdout).

Modes:
  - install                  Verifies setup-workspace.sh succeeded.
                             10 checks, all read-only bash.
  - first-task               Verifies demo skill output parses correctly.
                             4 checks; B2 emits an operator hand-off block;
                             re-run with --continue after capturing the
                             skill output via pbpaste or stdin pipe.
  - all (default)            Mode A then Mode B. If Mode A FAILs, Mode B is
                             skipped (install must verify first).
  - operator-pre-existing    Workspaces created before setup-workspace.sh
                             shipped (no state-marker yet). Runs A1-A3, A5-A9
                             (8 checks); aggregate verdict is per-mode
                             unambiguous.

Demo skill: prompt-builder (core/skills). Aligned with the
GETTING_STARTED.md walkthrough so the operator exercises the same skill
in both surfaces. Minimum-viable-artifact assertions tolerate skill-
iteration drift (no version-locked structure required).

Hand-off pattern (Mode B B2):
  ⛔ Hook-blocked, user-side hand-off — Claude Code skill invocation
     requires an active in-session call; bash cannot invoke skills
     headlessly.

  Run in Claude Code:
    1. Open Claude Code (cd ~/Claude && claude)
    2. Type:  /prompt-builder critique and rewrite this prompt:
              "summarize the document"
    3. Select the agent's full response and copy it (Cmd-C).
  Then in your terminal:
    pbpaste | ./validate-install.sh --mode first-task --continue

  Effect: pbpaste pipes the clipboard into stdin; the script writes the
     artifact itself and runs B3 + B4 structural assertions.
  Reversibility: CHEAP (trash the .workspace-validation/<timestamp>/ dir).

Platform: Darwin-only on current release. Cross-platform deferred.
USAGE
}

# --- Section 5: Logging helpers ---
log()     { printf '%s\n' "$*" >&2; }
warn()    { printf 'WARN: %s\n' "$*" >&2; }
err()     { printf 'ERROR: %s\n' "$*" >&2; }
verbose() { [ "${VERBOSE}" -eq 1 ] && printf 'VERBOSE: %s\n' "$*" >&2 || true; }

# --- Section 6: Argv parsing ---
parse_argv() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --mode)
        if [ $# -lt 2 ]; then err "--mode requires an argument"; exit 64; fi
        MODE="$2"; shift 2 ;;
      --source-repo)
        if [ $# -lt 2 ]; then err "--source-repo requires an argument"; exit 64; fi
        SOURCE_REPO="$2"; shift 2 ;;
      --workspace-root)
        if [ $# -lt 2 ]; then err "--workspace-root requires an argument"; exit 64; fi
        WORKSPACE_ROOT="$2"; shift 2 ;;
      --validation-dir)
        if [ $# -lt 2 ]; then err "--validation-dir requires an argument"; exit 64; fi
        VALIDATION_DIR="$2"; shift 2 ;;
      --continue)  CONTINUE=1; shift ;;
      --dry-run)   DRY_RUN=1; shift ;;
      --verbose)   VERBOSE=1; shift ;;
      --help|-h)   usage; exit 0 ;;
      *)
        err "Unknown argument: $1"
        printf 'Run with --help for usage.\n' >&2
        exit 64 ;;
    esac
  done

  # Validate --mode value
  case "${MODE}" in
    install|first-task|all|operator-pre-existing) ;;
    *)
      err "Invalid --mode: ${MODE}"
      printf 'Valid modes: install, first-task, all, operator-pre-existing\n' >&2
      exit 64 ;;
  esac

  # Apply defaults (use `:` no-op on the "else" branch so the && chain doesn't
  # propagate non-zero exit under `set -e` when the var is already populated).
  if [ -z "${WORKSPACE_ROOT}" ]; then WORKSPACE_ROOT="${DEFAULT_WORKSPACE_ROOT}"; fi
  if [ -z "${SOURCE_REPO}" ]; then SOURCE_REPO="${DEFAULT_SOURCE_REPO}"; fi
}

# --- Section 7: Prerequisite checks ---
check_prereqs() {
  local missing=""
  for tool in jq grep find wc; do
    if ! command -v "${tool}" > /dev/null 2>&1; then
      missing="${missing} ${tool}"
    fi
  done
  if [ -n "${missing}" ]; then
    err "Missing prerequisites:${missing}"
    printf 'Install via: brew install jq (or ensure /usr/bin/jq present)\n' >&2
    exit 69
  fi
  verbose "Prerequisites OK: jq grep find wc"
}

check_source_repo() {
  if [ ! -d "${SOURCE_REPO}" ]; then
    err "Source repo not found: ${SOURCE_REPO}"
    printf 'Pass --source-repo PATH or clone the repo to %s.\n' "${DEFAULT_SOURCE_REPO}" >&2
    exit 66
  fi
  verbose "Source repo: ${SOURCE_REPO}"
}

check_workspace_root() {
  if [ ! -d "${WORKSPACE_ROOT}" ]; then
    err "Workspace root not found: ${WORKSPACE_ROOT}"
    printf 'Pass --workspace-root PATH or create the workspace via setup-workspace.sh.\n' >&2
    exit 66
  fi
  verbose "Workspace root: ${WORKSPACE_ROOT}"
}

# --- Section 8: Validation directory setup ---
setup_validation_dir() {
  TIMESTAMP=$(date -u +%Y-%m-%dT%H%MZ)
  if [ -z "${VALIDATION_DIR}" ]; then
    VALIDATION_DIR="${WORKSPACE_ROOT}/.workspace-validation/${TIMESTAMP}"
  fi

  # Safety: ${VALIDATION_DIR} must resolve INSIDE ${WORKSPACE_ROOT} unless
  # explicitly overridden to an absolute path elsewhere. We use a simple
  # prefix check; bash 3.2 compatible.
  local abs_validation abs_workspace
  abs_validation=$(cd "$(dirname "${VALIDATION_DIR}")" 2>/dev/null && pwd)/$(basename "${VALIDATION_DIR}") || abs_validation="${VALIDATION_DIR}"
  abs_workspace=$(cd "${WORKSPACE_ROOT}" 2>/dev/null && pwd) || abs_workspace="${WORKSPACE_ROOT}"
  case "${abs_validation}" in
    "${abs_workspace}"/*) verbose "Validation dir inside workspace: OK" ;;
    "${abs_workspace}")   verbose "Validation dir == workspace root: OK" ;;
    *)
      # Allow the operator to explicitly override out-of-workspace via flag,
      # but warn loudly.
      warn "Validation dir resolves outside workspace root: ${VALIDATION_DIR}"
      warn "Bounded write surface principle relaxed by operator override; proceeding."
      ;;
  esac

  if [ "${DRY_RUN}" -eq 1 ]; then
    verbose "DRY-RUN: would create ${VALIDATION_DIR}"
    return 0
  fi
  mkdir -p "${VALIDATION_DIR}"
  STEP_RECORDS_FILE="${VALIDATION_DIR}/.step-records.jsonl"
  FAILING_STEPS_FILE="${VALIDATION_DIR}/.failing-steps.txt"
  : > "${STEP_RECORDS_FILE}"
  : > "${FAILING_STEPS_FILE}"
  verbose "Validation dir: ${VALIDATION_DIR}"
}

# --- Section 9: Per-step emit + record helpers ---
# stdout: human-readable per-step line. stderr (--verbose): diagnostic detail.
# JSON record appended to STEP_RECORDS_FILE for aggregation into run.json.

emit_pass() {
  local step="$1" check="$2" diagnostic="$3" mode="$4"
  printf '[%s] PASS — %s: %s\n' "${step}" "${check}" "${diagnostic}"
  record_step "${step}" "${check}" "PASS" "${diagnostic}" "" "${mode}"
  case "${mode}" in
    A) MODE_A_PASS=$((MODE_A_PASS + 1)) ;;
    B) MODE_B_PASS=$((MODE_B_PASS + 1)) ;;
  esac
}

emit_fail() {
  local step="$1" check="$2" diagnostic="$3" hint="$4" mode="$5"
  printf '[%s] FAIL — %s: %s\n' "${step}" "${check}" "${diagnostic}"
  printf '        -> hint: %s\n' "${hint}"
  record_step "${step}" "${check}" "FAIL" "${diagnostic}" "${hint}" "${mode}"
  printf '[%s] %s: %s | %s\n' "${step}" "${check}" "${diagnostic}" "${hint}" >> "${FAILING_STEPS_FILE}"
  case "${mode}" in
    A) MODE_A_FAIL=$((MODE_A_FAIL + 1)); MODE_A_FAIL_FLAG=1 ;;
    B) MODE_B_FAIL=$((MODE_B_FAIL + 1)); MODE_B_FAIL_FLAG=1 ;;
  esac
  AGGREGATE_FAIL=1
}

emit_skip() {
  local step="$1" check="$2" reason="$3" mode="$4"
  printf '[%s] SKIP — %s: %s\n' "${step}" "${check}" "${reason}"
  record_step "${step}" "${check}" "SKIP" "${reason}" "" "${mode}"
  case "${mode}" in
    A) MODE_A_SKIP=$((MODE_A_SKIP + 1)) ;;
    B) MODE_B_SKIP=$((MODE_B_SKIP + 1)) ;;
  esac
}

record_step() {
  # Append one JSONL record per step. Compose into run.json at log_summary.
  local step="$1" check="$2" verdict="$3" diagnostic="$4" hint="$5" mode="$6"
  if [ -z "${STEP_RECORDS_FILE}" ] || [ "${DRY_RUN}" -eq 1 ]; then return 0; fi
  S_STEP="${step}" S_CHECK="${check}" S_VERDICT="${verdict}" \
  S_DIAG="${diagnostic}" S_HINT="${hint}" S_MODE="${mode}" \
  /usr/bin/python3 -c '
import json, os
rec = {
  "step":       os.environ["S_STEP"],
  "check":      os.environ["S_CHECK"],
  "verdict":    os.environ["S_VERDICT"],
  "diagnostic": os.environ["S_DIAG"],
  "hint":       os.environ.get("S_HINT") or None,
  "mode":       os.environ["S_MODE"],
}
print(json.dumps(rec))
' >> "${STEP_RECORDS_FILE}"
}

# --- Section 10: Assertion helpers (T1/T2/T3/T4 taxonomy per spec Output-Tolerance Design) ---
# These return 0 on pass, 1 on fail. Callers wrap with emit_pass / emit_fail.

# T1 — file-system structural
assert_file_exists()    { [ -f "$1" ]; }
assert_dir_exists()     { [ -d "$1" ]; }
assert_file_nonempty()  { [ -s "$1" ]; }
assert_byte_size_min()  { local actual; actual=$(wc -c < "$1" | tr -d ' '); [ "${actual}" -ge "$2" ]; }
assert_executable()     { [ -x "$1" ]; }
assert_mtime_within()   { find "$1" -mmin "-$2" -print -quit 2>/dev/null | grep -q .; }
assert_json_valid()     { jq . "$1" > /dev/null 2>&1; }

# T2 — exit code (caller invokes the command and checks $?)
# Used inline (e.g., if `cmd > /dev/null 2>&1; then ...`).

# T3 — section-marker presence
assert_heading_present()    { grep -qE "^#{1,3} " "$1"; }
assert_fenced_code_pairs()  {
  local count
  count=$(grep -c '^```' "$1" 2>/dev/null || printf '0')
  [ "${count}" -ge 2 ] && [ $((count % 2)) -eq 0 ]
}

# T4 — keyword-set presence (N-of-M lowercased, case-insensitive)
# Currently unused at B4 (FM-1 mitigation loosens to minimum-viable signals);
# retained for forward-compat if assertion-class needs surface in future.
assert_keyword_set() {
  local file="$1" required="$2"; shift 2
  local kw found=0
  for kw in "$@"; do
    if grep -qiE "(^|[^a-z])${kw}([^a-z]|$)" "${file}"; then
      found=$((found + 1))
    fi
  done
  [ "${found}" -ge "${required}" ]
}

# Negative — placeholder detection (drift-tolerant; minimum-viable-artifact signal)
assert_no_placeholders() {
  ! grep -qE '\[(INSERT|TBD|PLACEHOLDER|TODO)\]' "$1"
}

# --- Section 11: Mode A check functions ---
# Each emits one of PASS/FAIL/SKIP via emit_pass/emit_fail/emit_skip with mode=A.

check_a1_platform() {
  # Already gated at top-of-script; kept for record + per-step output. Report the
  # LIVE platform ($(uname -s)) rather than a hardcoded "Darwin" label: under
  # PMO_ALLOW_NON_DARWIN=1 (#303) this script proceeds on Linux/Windows, where a
  # hardcoded "Darwin <kernel>" evidence string would mislabel the platform.
  emit_pass "A1" "INSTALL-PLATFORM" "$(uname -s) $(uname -r)" "A"
}

check_a2_workspace_layout() {
  local missing=""
  local required_dirs="pmo-platform projects knowledge personal .claude"
  for d in ${required_dirs}; do
    if [ ! -d "${WORKSPACE_ROOT}/${d}" ]; then
      missing="${missing} ${d}"
    fi
  done
  if [ -n "${missing}" ]; then
    emit_fail "A2" "INSTALL-WORKSPACE-LAYOUT" "missing dirs:${missing}" \
      "re-run setup-workspace.sh" "A"
  else
    emit_pass "A2" "INSTALL-WORKSPACE-LAYOUT" "5 required dirs present" "A"
  fi
}

check_a3_hooks_layout() {
  local hooks_dir="${WORKSPACE_ROOT}/.claude/hooks"
  if ! assert_dir_exists "${hooks_dir}"; then
    emit_fail "A3" "INSTALL-HOOKS-LAYOUT" "hooks directory missing: ${hooks_dir}" \
      "re-run setup-workspace.sh" "A"
    return
  fi
  local sh_count
  sh_count=$(find "${hooks_dir}" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${sh_count}" -lt 8 ]; then
    emit_fail "A3" "INSTALL-HOOKS-LAYOUT" "found ${sh_count} hook(s); expected >=8" \
      "re-run setup-workspace.sh (hook install incomplete)" "A"
    return
  fi
  # Spot-check executable bit on a representative hook
  local executable_ok=1
  for hook in "${hooks_dir}"/*.sh; do
    [ -f "${hook}" ] || continue
    if ! assert_executable "${hook}"; then
      executable_ok=0
      verbose "A3: non-executable hook: ${hook}"
      break
    fi
  done
  if [ "${executable_ok}" -eq 0 ]; then
    emit_fail "A3" "INSTALL-HOOKS-LAYOUT" "hook(s) missing +x bit" \
      "chmod +x ${hooks_dir}/*.sh OR re-run setup-workspace.sh" "A"
  else
    emit_pass "A3" "INSTALL-HOOKS-LAYOUT" "${sh_count} hook(s) installed +x" "A"
  fi
}

check_a3b_composition_surface() {
  # Verify composition-surface files installed per manifest. Read the manifest
  # from the source repo (where this script lives one level up under docs/scripts).
  local manifest="${SOURCE_REPO}/core/deploy/composition-surface-manifest.sh"
  if [ ! -f "${manifest}" ]; then
    emit_fail "A3b" "INSTALL-COMPOSITION-SURFACE" \
      "manifest missing: ${manifest}" \
      "re-clone pmo-platform (manifest is package-shipped)" "A"
    return
  fi
  # shellcheck disable=SC1090
  source "${manifest}"

  local entry src tier basename target missing=0 present=0
  for entry in "${COMPOSITION_SURFACE_FILES[@]}"; do
    src=$(printf '%s' "${entry}" | awk -F'|' '{print $1}')
    tier=$(printf '%s' "${entry}" | awk -F'|' '{print $2}')
    basename="$(basename "${src}")"
    case "${tier}" in
      hook)     target="${WORKSPACE_ROOT}/.claude/${basename}" ;;
      instance) target="${WORKSPACE_ROOT}/personal/pmo-instance/${basename}" ;;
      *)        continue ;;
    esac
    if [ -f "${target}" ]; then
      present=$((present + 1))
    else
      missing=$((missing + 1))
      verbose "A3b: missing composition-surface file: ${target}"
    fi
  done

  if [ "${missing}" -gt 0 ]; then
    emit_fail "A3b" "INSTALL-COMPOSITION-SURFACE" \
      "${missing} composition-surface file(s) missing; ${present} present" \
      "re-run setup-workspace.sh (install loop may have failed)" "A"
  else
    emit_pass "A3b" "INSTALL-COMPOSITION-SURFACE" \
      "${present} composition-surface file(s) installed" "A"
  fi
}

check_a4_state_marker() {
  local state_file="${WORKSPACE_ROOT}/.claude/${STATE_FILE_NAME}"
  if ! assert_file_exists "${state_file}"; then
    emit_fail "A4" "INSTALL-STATE-MARKER" "state file missing: ${state_file}" \
      "re-run setup-workspace.sh (fresh-install OR --init-only-state for pre-existing workspace)" "A"
    return
  fi
  if ! assert_json_valid "${state_file}"; then
    emit_fail "A4" "INSTALL-STATE-MARKER" "state file is invalid JSON: ${state_file}" \
      "back up the file and re-run setup-workspace.sh (guided recovery)" "A"
    return
  fi
  local schema
  schema=$(jq -r '.schema_version // empty' "${state_file}" 2>/dev/null || true)
  if [ "${schema}" != "${STATE_SCHEMA_VERSION}" ]; then
    emit_fail "A4" "INSTALL-STATE-MARKER" "schema_version mismatch (found '${schema}', expected '${STATE_SCHEMA_VERSION}')" \
      "re-run setup-workspace.sh to upgrade state schema" "A"
    return
  fi
  local completed_at
  completed_at=$(jq -r '.setup_completed_at // empty' "${state_file}" 2>/dev/null || true)
  if [ -z "${completed_at}" ]; then
    emit_fail "A4" "INSTALL-STATE-MARKER" "setup_completed_at missing in state file" \
      "re-run setup-workspace.sh" "A"
    return
  fi
  emit_pass "A4" "INSTALL-STATE-MARKER" "schema 1.0; completed_at ${completed_at}" "A"
}

check_a5_claude_md() {
  local claude_md="${WORKSPACE_ROOT}/CLAUDE.md"
  if ! assert_file_exists "${claude_md}"; then
    emit_fail "A5" "INSTALL-CLAUDE-MD" "CLAUDE.md missing at workspace root" \
      "re-run setup-workspace.sh (CLAUDE.md template not resolved)" "A"
    return
  fi
  if ! assert_byte_size_min "${claude_md}" 500; then
    emit_fail "A5" "INSTALL-CLAUDE-MD" "CLAUDE.md < 500 bytes" \
      "re-run setup-workspace.sh; CLAUDE.md appears truncated" "A"
    return
  fi
  # Check for unresolved operator-token placeholders. The regex is scoped to
  # the canonical token namespace ([OPERATOR_*]/[CLAUDE_*]/[COWORK_*]) so it
  # does NOT false-positive on legitimate CLAUDE.md vocabulary and examples
  # ([SOURCE], [RECOMMENDED], [TBD], [CONTEXT], [INFERRED], [INSERT],
  # [COMPANY_X], [PROJECT_KEY], etc.). Matches the namespace pattern used by
  # core/deploy/tests/test_install_end_to_end.sh so the two tools agree.
  if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${claude_md}"; then
    emit_fail "A5" "INSTALL-CLAUDE-MD" "unresolved token(s) in CLAUDE.md" \
      "re-run setup-workspace.sh; token substitution incomplete" "A"
    return
  fi
  emit_pass "A5" "INSTALL-CLAUDE-MD" "$(wc -c < "${claude_md}" | tr -d ' ') bytes; no unresolved tokens" "A"
}

check_a6_settings_json() {
  local settings="${WORKSPACE_ROOT}/.claude/settings.json"
  if ! assert_file_exists "${settings}"; then
    emit_fail "A6" "INSTALL-SETTINGS-JSON" "settings.json missing" \
      "re-run setup-workspace.sh" "A"
    return
  fi
  if ! assert_json_valid "${settings}"; then
    emit_fail "A6" "INSTALL-SETTINGS-JSON" "settings.json is invalid JSON" \
      "re-run setup-workspace.sh; template token substitution may have corrupted JSON" "A"
    return
  fi
  # Namespace-scoped to canonical operator tokens (same pattern as A5 and
  # core/deploy/tests/test_install_end_to_end.sh) so legitimate bracketed
  # vocabulary in settings.json does not trip a false unresolved-token FAIL.
  if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${settings}"; then
    emit_fail "A6" "INSTALL-SETTINGS-JSON" "unresolved token(s) in settings.json" \
      "re-run setup-workspace.sh; token substitution incomplete" "A"
    return
  fi
  emit_pass "A6" "INSTALL-SETTINGS-JSON" "JSON valid; no unresolved tokens" "A"
}

# A6b — hook-wiring re-home posture (#4436).
#
# The workspace-project settings.json checked above is loaded ONLY by sessions whose
# project root resolves to the workspace root. Sessions rooted in the repo or a worktree
# — and every subagent they spawn — resolve no settings file carrying a hooks key and so
# load NO hooks at all. `setup-workspace.sh --rehome-hook-wiring` merges the PreToolUse
# object into the user-scope surface to close that.
#
# This check is deliberately NOT a FAIL when the re-home is absent. The re-home is an
# operator act ordered after script-allowlist reconciliation, and it writes outside the
# workspace root — an install is legitimately complete without it. What IS a FAIL is a
# re-home that is PRESENT but references commands that do not exist or are not
# executable: that is a wired control which can never fire, i.e. a silent enforcement
# hole, and it is exactly the failure mode a partial install produces once the wiring is
# live. Reporting coverage rather than asserting it is the point of the check.
check_a6b_hook_wiring_rehome() {
  local user_settings="${PMO_USER_SETTINGS_FILE:-${HOME}/.claude/settings.json}"

  if [ ! -f "${user_settings}" ]; then
    emit_pass "A6b" "INSTALL-HOOK-WIRING-REHOME" \
      "not re-homed (no user-scope settings file) — repo/worktree-rooted sessions load NO hooks; run 'setup-workspace.sh --rehome-hook-wiring' after reconciling the script allowlist" "A"
    return
  fi

  local probe
  probe="$(python3 -c '
import json, os, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
except Exception as e:
    print("INVALID|{}".format(e)); sys.exit(0)
pre = data.get("hooks", {}).get("PreToolUse", []) if isinstance(data, dict) else []
if not pre:
    print("ABSENT|0|0"); sys.exit(0)
cmds = [h.get("command", "") for g in pre for h in g.get("hooks", [])]
bad = [c for c in cmds if not (os.path.exists(c) and os.access(c, os.X_OK))]
print("PRESENT|{}|{}|{}".format(len(cmds), len(bad), ",".join(sorted(set(bad))[:3])))
' "${user_settings}" 2>/dev/null)"

  case "${probe}" in
    INVALID*)
      emit_fail "A6b" "INSTALL-HOOK-WIRING-REHOME" \
        "user-scope settings file is not valid JSON: ${user_settings}" \
        "repair or restore ${user_settings}.pmo-bak; a corrupt user-scope settings file can break every session" "A"
      ;;
    ABSENT*)
      emit_pass "A6b" "INSTALL-HOOK-WIRING-REHOME" \
        "not re-homed (user-scope settings file declares no PreToolUse hooks) — repo/worktree-rooted sessions load NO hooks; run 'setup-workspace.sh --rehome-hook-wiring' after reconciling the script allowlist" "A"
      ;;
    PRESENT*)
      local total bad_count bad_sample
      total="$(printf '%s' "${probe}" | cut -d'|' -f2)"
      bad_count="$(printf '%s' "${probe}" | cut -d'|' -f3)"
      bad_sample="$(printf '%s' "${probe}" | cut -d'|' -f4)"
      if [ "${bad_count}" -gt 0 ]; then
        emit_fail "A6b" "INSTALL-HOOK-WIRING-REHOME" \
          "re-homed wiring references ${bad_count} of ${total} command(s) that do not exist or are not executable (e.g. ${bad_sample})" \
          "run 'setup-workspace.sh --refresh-hooks' then re-run '--rehome-hook-wiring'; a wired hook that cannot execute is a silent enforcement hole" "A"
      else
        emit_pass "A6b" "INSTALL-HOOK-WIRING-REHOME" \
          "re-homed; ${total}/${total} wired PreToolUse commands exist and are executable" "A"
      fi
      ;;
    *)
      emit_pass "A6b" "INSTALL-HOOK-WIRING-REHOME" \
        "indeterminate (probe returned no verdict) — treated as not re-homed" "A"
      ;;
  esac
}

check_a7_source_repo() {
  if ! assert_dir_exists "${SOURCE_REPO}/core"; then
    emit_fail "A7" "INSTALL-SOURCE-REPO" "core/ missing in source repo: ${SOURCE_REPO}" \
      "verify --source-repo PATH or re-clone the v2 repo" "A"
    return
  fi
  local core_count
  core_count=$(find "${SOURCE_REPO}/core" -maxdepth 2 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [ "${core_count}" -lt 1 ]; then
    emit_fail "A7" "INSTALL-SOURCE-REPO" "core/ empty in source repo" \
      "re-clone or git-checkout the v2 repo" "A"
    return
  fi
  emit_pass "A7" "INSTALL-SOURCE-REPO" "${core_count} subdir(s) under core/" "A"
}

check_a8_deploy_check() {
  local deploy_sh="${SOURCE_REPO}/core/deploy/deploy.sh"
  if ! assert_file_exists "${deploy_sh}"; then
    emit_fail "A8" "INSTALL-DEPLOY-CHECK" "deploy.sh missing: ${deploy_sh}" \
      "ensure the v2 repo has core/deploy/deploy.sh present" "A"
    return
  fi
  if ! assert_executable "${deploy_sh}"; then
    emit_fail "A8" "INSTALL-DEPLOY-CHECK" "deploy.sh not executable: ${deploy_sh}" \
      "chmod +x ${deploy_sh}" "A"
    return
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    emit_skip "A8" "INSTALL-DEPLOY-CHECK" "--dry-run; deploy.sh --check not invoked" "A"
    return
  fi
  # Invoke deploy.sh --check --warn (warn-mode tolerates non-fatal drift findings).
  # Capture stderr to verbose log; only exit code matters.
  local exit_code=0
  if [ "${VERBOSE}" -eq 1 ]; then
    "${deploy_sh}" --check --warn >&2 || exit_code=$?
  else
    "${deploy_sh}" --check --warn > /dev/null 2>&1 || exit_code=$?
  fi
  if [ "${exit_code}" -eq 0 ]; then
    emit_pass "A8" "INSTALL-DEPLOY-CHECK" "deploy.sh --check --warn exit 0" "A"
  else
    emit_fail "A8" "INSTALL-DEPLOY-CHECK" "deploy.sh --check --warn exit ${exit_code}" \
      "run \`${deploy_sh} --check\` directly for full diagnostic" "A"
  fi
}

check_a9_skill_roster() {
  # The user-local skills mirror is the predictable deploy target. deploy.sh
  # installs it to $DEPLOY_ROOT/.claude/skills (USER_LOCAL_SKILLS_PATH in
  # core/deploy/deploy.sh), which is NOT ${WORKSPACE_ROOT}/.claude/skills
  # (~/Claude/.claude/skills). Check the real mirror so a correct install
  # passes. (deploy.sh's other target, INSTALL_PATH, is a Cowork-internal
  # auto-detected path this validator cannot reliably predict.)
  #
  # Honor the same deploy-root override deploy.sh uses (#331 F2): deploy.sh
  # resolves DEPLOY_ROOT="${PMO_PLATFORM_DEPLOY_ROOT:-$HOME}". In a real
  # operator install the var is unset so DEPLOY_ROOT==$HOME and A9 is unchanged;
  # under sandboxed validation (override set) A9 must follow the redirected
  # mirror or it would check the live ~ and false-fail.
  local deploy_root="${PMO_PLATFORM_DEPLOY_ROOT:-${HOME}}"
  local skills_dir="${deploy_root}/.claude/skills"
  if ! assert_dir_exists "${skills_dir}"; then
    emit_fail "A9" "INSTALL-SKILL-ROSTER" "skills dir missing: ${skills_dir}" \
      "run \`${SOURCE_REPO}/core/deploy/deploy.sh --deploy\` to populate skills mirror" "A"
    return
  fi
  local skill_count missing_skill_md=0 missing_version=0 first_missing=""
  skill_count=$(find "${skills_dir}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [ "${skill_count}" -lt 1 ]; then
    emit_fail "A9" "INSTALL-SKILL-ROSTER" "no skill subdirs under ${skills_dir}" \
      "run \`${SOURCE_REPO}/core/deploy/deploy.sh --deploy\` to populate" "A"
    return
  fi
  # Spot-check: every skill dir has SKILL.md; frontmatter has version field
  for skill_dir in "${skills_dir}"/*/; do
    [ -d "${skill_dir}" ] || continue
    local skill_md="${skill_dir}SKILL.md"
    if [ ! -f "${skill_md}" ]; then
      missing_skill_md=$((missing_skill_md + 1))
      if [ -z "${first_missing}" ]; then first_missing="$(basename "${skill_dir}")/SKILL.md"; fi
      continue
    fi
    # Grep frontmatter for a non-empty version field
    if ! grep -qE '^version:[[:space:]]*[^[:space:]]+' "${skill_md}"; then
      missing_version=$((missing_version + 1))
      if [ -z "${first_missing}" ]; then first_missing="$(basename "${skill_dir}") (missing version field)"; fi
    fi
  done
  if [ "${missing_skill_md}" -gt 0 ]; then
    emit_fail "A9" "INSTALL-SKILL-ROSTER" "${missing_skill_md} skill(s) missing SKILL.md; first: ${first_missing}" \
      "run \`${SOURCE_REPO}/core/deploy/deploy.sh --deploy <skill>\` to re-deploy" "A"
    return
  fi
  if [ "${missing_version}" -gt 0 ]; then
    emit_fail "A9" "INSTALL-SKILL-ROSTER" "${missing_version} skill(s) missing version field; first: ${first_missing}" \
      "re-deploy via deploy.sh --deploy <skill>" "A"
    return
  fi
  emit_pass "A9" "INSTALL-SKILL-ROSTER" "${skill_count} skill(s); all with SKILL.md + version" "A"
}

check_a10_operator_toml() {
  if [ ! -f "${OPERATOR_TOML_PATH}" ]; then
    emit_fail "A10" "INSTALL-OPERATOR-TOML" "operator.toml missing: ${OPERATOR_TOML_PATH}" \
      "re-run setup-workspace.sh; operator.toml should land under ~/.config/pmo-platform/" "A"
    return
  fi
  if ! assert_byte_size_min "${OPERATOR_TOML_PATH}" 50; then
    emit_fail "A10" "INSTALL-OPERATOR-TOML" "operator.toml < 50 bytes" \
      "re-run setup-workspace.sh; config appears truncated" "A"
    return
  fi
  # operator_name lives under [identity] in operator.toml; bare key grep is sufficient.
  if ! grep -qE '^[[:space:]]*operator_name[[:space:]]*=' "${OPERATOR_TOML_PATH}"; then
    emit_fail "A10" "INSTALL-OPERATOR-TOML" "operator_name key missing in operator.toml" \
      "re-run setup-workspace.sh to populate operator identity" "A"
    return
  fi
  emit_pass "A10" "INSTALL-OPERATOR-TOML" "operator_name key present" "A"
}

# --- Section 12: Mode A routing ---

mode_a_install_verify() {
  check_a1_platform
  check_a2_workspace_layout
  check_a3_hooks_layout
  check_a3b_composition_surface
  check_a4_state_marker
  check_a5_claude_md
  check_a6_settings_json
  check_a6b_hook_wiring_rehome
  check_a7_source_repo
  check_a8_deploy_check
  check_a9_skill_roster
  check_a10_operator_toml
}

mode_a_operator_pre_existing() {
  # Subset of Mode A for workspaces created before setup-workspace.sh shipped:
  # drops A4 (state-marker) and A10 (operator.toml) because those workspaces
  # predate both mechanisms. Per CD-3A — modal sub-mode, not flag-skip.
  check_a1_platform
  check_a2_workspace_layout
  check_a3_hooks_layout
  emit_skip "A4" "INSTALL-STATE-MARKER" "operator-pre-existing mode (state marker not expected)" "A"
  check_a5_claude_md
  check_a6_settings_json
  check_a6b_hook_wiring_rehome
  check_a7_source_repo
  check_a8_deploy_check
  check_a9_skill_roster
  emit_skip "A10" "INSTALL-OPERATOR-TOML" "operator-pre-existing mode (operator.toml not expected)" "A"
}

# --- Section 13: Mode B check functions ---

check_b1_prereqs() {
  local skill_md="${SOURCE_REPO}/core/skills/${DEMO_SKILL}/SKILL.md"
  if ! assert_file_exists "${skill_md}"; then
    emit_fail "B1" "FIRSTTASK-PREREQS" "demo skill SKILL.md missing: ${skill_md}" \
      "verify v2 repo has core/skills/${DEMO_SKILL}/SKILL.md (or run deploy.sh --deploy ${DEMO_SKILL})" "B"
    return
  fi
  # Read frontmatter version (FM-1 mitigation: capture for run.json)
  DEMO_SKILL_VERSION=$(awk '/^version:/{print $2; exit}' "${skill_md}" | tr -d '"' | tr -d "'" || true)
  if [ -z "${DEMO_SKILL_VERSION}" ]; then DEMO_SKILL_VERSION="unknown"; fi
  # Sanity-check frontmatter name field
  if ! grep -qE "^name:[[:space:]]+${DEMO_SKILL}" "${skill_md}"; then
    emit_fail "B1" "FIRSTTASK-PREREQS" "demo skill frontmatter 'name:' does not match '${DEMO_SKILL}'" \
      "verify the demo skill identity at ${skill_md}" "B"
    return
  fi
  emit_pass "B1" "FIRSTTASK-PREREQS" "${DEMO_SKILL} present (version ${DEMO_SKILL_VERSION})" "B"
}

check_b2_invoke_instructions() {
  # Emit the operator hand-off block to stdout. The block is the deliverable
  # of B2 — printing it correctly IS the assertion.
  local artifact="${VALIDATION_DIR}/firsttask-output.md"
  cat <<HANDOFF

[B2] HAND-OFF — First-task validation requires running the demo skill.

  Hook-blocked, user-side hand-off — Claude Code skill invocation requires
  an active in-session call; bash cannot invoke skills headlessly.

  Run in Claude Code:
    1. Open Claude Code:  cd ${WORKSPACE_ROOT} && claude
    2. Type:  /${DEMO_SKILL} ${DEMO_SKILL_PROMPT}
    3. When the response is complete, select the agent's full response
       (the critique + rewritten prompt block) and copy it with Cmd-C.

  Then in your terminal:
    pbpaste | ${SOURCE_REPO}/docs/scripts/validate-install.sh --mode first-task --continue

  Effect: pbpaste pipes the clipboard into stdin; this script writes the
  artifact at:
    ${artifact}
  and runs structural assertions (B3 + B4).
  Reversibility: CHEAP (trash the validation directory to reset).

HANDOFF
  # Verify the hand-off block was emitted (self-grep is the only useful T1
  # check here). We re-read by checking the count of lines printed; minimum
  # is non-zero (printf above ran). Tautological pass — but documents the
  # contract that B2 emits exactly one hand-off block per invocation.
  emit_pass "B2" "FIRSTTASK-INVOKE-INSTRUCTIONS" "hand-off block emitted to stdout" "B"
}

check_b3_output_exists() {
  local artifact="${VALIDATION_DIR}/firsttask-output.md"
  if ! assert_file_exists "${artifact}"; then
    emit_fail "B3" "FIRSTTASK-OUTPUT-EXISTS" "artifact missing: ${artifact}" \
      "complete the Claude Code skill-invocation step in [B2] above, then re-run with --continue" "B"
    return
  fi
  if ! assert_byte_size_min "${artifact}" 200; then
    emit_fail "B3" "FIRSTTASK-OUTPUT-EXISTS" "artifact < 200 bytes (likely truncated/empty paste)" \
      "verify Cmd-C captured the full agent response; re-run with --continue" "B"
    return
  fi
  # Mtime window: allow up to 60 min (operator may not be quick at the
  # copy-paste). Strict 10-min original was over-strict per FM ergonomics.
  if ! assert_mtime_within "${artifact}" 60; then
    emit_fail "B3" "FIRSTTASK-OUTPUT-EXISTS" "artifact mtime > 60 min ago (stale capture)" \
      "re-invoke the skill and capture a fresh response" "B"
    return
  fi
  local bytes
  bytes=$(wc -c < "${artifact}" | tr -d ' ')
  emit_pass "B3" "FIRSTTASK-OUTPUT-EXISTS" "${bytes} bytes; mtime within 60 min" "B"
}

check_b4_output_structural() {
  local artifact="${VALIDATION_DIR}/firsttask-output.md"
  # FM-1 mitigation: minimum-viable-artifact signals (drift-tolerant).
  # Original spec required H2 + fenced-code-pairs + 3-of-6 keyword set.
  # That is brittle to skill iterations. We instead require:
  #   (a) at least one heading (#, ##, or ###) OR a fenced code block — the
  #       output is structured;
  #   (b) zero unresolved placeholders [INSERT]/[TBD]/[PLACEHOLDER]/[TODO].
  # These two signals capture "structured output, free of stale scaffolding"
  # without baking in current-version prompt-builder output shape.
  if ! { assert_heading_present "${artifact}" || assert_fenced_code_pairs "${artifact}"; }; then
    emit_fail "B4" "FIRSTTASK-OUTPUT-STRUCTURAL" "no heading or fenced code block found" \
      "verify the full agent response was captured (incl. critique + prompt block)" "B"
    return
  fi
  if ! assert_no_placeholders "${artifact}"; then
    emit_fail "B4" "FIRSTTASK-OUTPUT-STRUCTURAL" "unresolved placeholder(s) found in output" \
      "the agent response contains [INSERT]/[TBD]/[PLACEHOLDER]/[TODO]; re-invoke the skill" "B"
    return
  fi
  emit_pass "B4" "FIRSTTASK-OUTPUT-STRUCTURAL" "structured output; no placeholders" "B"
}

# --- Section 14: --continue mode (read stdin / pbpaste, write artifact) ---

capture_from_stdin_or_pbpaste() {
  local artifact="${VALIDATION_DIR}/firsttask-output.md"
  if [ "${DRY_RUN}" -eq 1 ]; then
    verbose "DRY-RUN: would write artifact at ${artifact}"
    return 0
  fi
  # If stdin is a pipe, prefer it. Otherwise fall back to pbpaste (macOS clipboard).
  if [ ! -t 0 ]; then
    cat > "${artifact}"
    verbose "Captured artifact from stdin: ${artifact}"
    return 0
  fi
  if command -v pbpaste > /dev/null 2>&1; then
    pbpaste > "${artifact}"
    verbose "Captured artifact from pbpaste: ${artifact}"
    return 0
  fi
  err "No stdin pipe and pbpaste not found; cannot capture artifact"
  printf 'Pipe the agent response: pbpaste | %s --mode first-task --continue\n' "$0" >&2
  exit 66
}

# --- Section 15: Mode B routing ---

mode_b_first_task() {
  # B1 always runs (prereq check)
  check_b1_prereqs
  if [ "${MODE_B_FAIL_FLAG}" -eq 1 ]; then
    emit_skip "B2" "FIRSTTASK-INVOKE-INSTRUCTIONS" "B1 FAIL prevented invocation hand-off" "B"
    emit_skip "B3" "FIRSTTASK-OUTPUT-EXISTS" "B1 FAIL prevented output check" "B"
    emit_skip "B4" "FIRSTTASK-OUTPUT-STRUCTURAL" "B1 FAIL prevented structural check" "B"
    return
  fi

  if [ "${CONTINUE}" -eq 1 ]; then
    # Operator already saw B2 hand-off on prior run; now they're piping the response.
    capture_from_stdin_or_pbpaste
    emit_pass "B2" "FIRSTTASK-INVOKE-INSTRUCTIONS" "operator returned with --continue; artifact captured" "B"
    check_b3_output_exists
    if [ "${MODE_B_FAIL_FLAG}" -eq 1 ]; then
      emit_skip "B4" "FIRSTTASK-OUTPUT-STRUCTURAL" "B3 FAIL prevented structural assertions" "B"
      return
    fi
    check_b4_output_structural
  else
    # First invocation — print hand-off block; SKIP B3/B4 (operator pending).
    check_b2_invoke_instructions
    emit_skip "B3" "FIRSTTASK-OUTPUT-EXISTS" "operator hand-off pending; re-run with --continue after capturing response" "B"
    emit_skip "B4" "FIRSTTASK-OUTPUT-STRUCTURAL" "operator hand-off pending; re-run with --continue after capturing response" "B"
  fi
}

# --- Section 16: Aggregate summary + JSON sidecar ---

log_summary() {
  local mode_a_verdict mode_b_verdict overall_verdict
  if [ "${MODE_A_FAIL_FLAG}" -eq 1 ]; then mode_a_verdict="FAIL"; else mode_a_verdict="PASS"; fi
  if [ "${MODE_B_FAIL_FLAG}" -eq 1 ]; then mode_b_verdict="FAIL"; else mode_b_verdict="PASS"; fi
  if [ "${AGGREGATE_FAIL}" -eq 1 ]; then overall_verdict="FAIL"; else overall_verdict="PASS"; fi

  # Conditional Mode A verdict: if Mode A was not invoked at all (e.g.
  # first-task-only mode), report N/A.
  if [ "${MODE_A_PASS}" -eq 0 ] && [ "${MODE_A_FAIL}" -eq 0 ] && [ "${MODE_A_SKIP}" -eq 0 ]; then
    mode_a_verdict="N/A"
  fi

  # Conditional Mode B verdict: if Mode B was not invoked at all (e.g.
  # operator-pre-existing mode, install-only mode), report N/A.
  if [ "${MODE_B_PASS}" -eq 0 ] && [ "${MODE_B_FAIL}" -eq 0 ] && [ "${MODE_B_SKIP}" -eq 0 ]; then
    mode_b_verdict="N/A"
  fi

  # Conditional Mode B verdict: if Mode B was skipped entirely (Mode A FAIL),
  # report SKIP not PASS — overall verdict already conveys the FAIL.
  if [ "${MODE_B_PASS}" -eq 0 ] && [ "${MODE_B_FAIL}" -eq 0 ] && [ "${MODE_B_SKIP}" -gt 0 ]; then
    mode_b_verdict="SKIP"
  fi

  # Conditional Mode B PASS-with-SKIPs vs full PASS
  if [ "${MODE_B_FAIL_FLAG}" -eq 0 ] && [ "${MODE_B_SKIP}" -gt 0 ] && [ "${MODE_B_PASS}" -gt 0 ]; then
    mode_b_verdict="PASS (with pending hand-off)"
  fi

  printf '\n=== validate-install.sh — aggregate summary ===\n'
  printf 'Mode A (install verification):    %d PASS / %d FAIL / %d SKIP   -> %s\n' \
    "${MODE_A_PASS}" "${MODE_A_FAIL}" "${MODE_A_SKIP}" "${mode_a_verdict}"
  printf 'Mode B (first-task validation):   %d PASS / %d FAIL / %d SKIP   -> %s\n' \
    "${MODE_B_PASS}" "${MODE_B_FAIL}" "${MODE_B_SKIP}" "${mode_b_verdict}"
  printf '\nOverall: %s\n' "${overall_verdict}"

  if [ -n "${FAILING_STEPS_FILE}" ] && [ -s "${FAILING_STEPS_FILE}" ]; then
    printf 'Failing steps:\n'
    while IFS= read -r line; do
      printf '  - %s\n' "${line}"
    done < "${FAILING_STEPS_FILE}"
  fi

  printf '\nMode: %s\n' "${MODE}"
  if [ "${VERBOSE}" -eq 0 ]; then
    printf 'Run with --verbose for diagnostic detail.\n'
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    printf 'DRY-RUN mode: no state mutation; no artifacts persisted.\n'
  else
    printf 'Validation artifacts: %s\n' "${VALIDATION_DIR}"
  fi

  # Compose run.json from the JSONL records (FM-2 mitigation: stdout is human;
  # run.json is the machine-parseable surface).
  if [ "${DRY_RUN}" -eq 0 ] && [ -n "${STEP_RECORDS_FILE}" ] && [ -f "${STEP_RECORDS_FILE}" ]; then
    S_VERSION="${SCRIPT_VERSION}" S_STARTED="${TIMESTAMP}" \
    S_MODE="${MODE}" S_WORKSPACE="${WORKSPACE_ROOT}" S_SOURCE="${SOURCE_REPO}" \
    S_DEMO_SKILL="${DEMO_SKILL}" S_DEMO_VERSION="${DEMO_SKILL_VERSION}" \
    S_MODE_A_VERDICT="${mode_a_verdict}" S_MODE_B_VERDICT="${mode_b_verdict}" \
    S_OVERALL="${overall_verdict}" \
    S_MA_P="${MODE_A_PASS}" S_MA_F="${MODE_A_FAIL}" S_MA_S="${MODE_A_SKIP}" \
    S_MB_P="${MODE_B_PASS}" S_MB_F="${MODE_B_FAIL}" S_MB_S="${MODE_B_SKIP}" \
    S_RECORDS="${STEP_RECORDS_FILE}" S_OUT="${VALIDATION_DIR}/run.json" \
    /usr/bin/python3 -c '
import json, os, sys
from datetime import datetime, timezone
checks = []
with open(os.environ["S_RECORDS"]) as f:
  for line in f:
    line = line.strip()
    if line: checks.append(json.loads(line))
doc = {
  "schema_version": "1.0",
  "validate_install_version": os.environ["S_VERSION"],
  "started_at": os.environ["S_STARTED"],
  "completed_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%MZ"),
  "mode": os.environ["S_MODE"],
  "workspace_root": os.environ["S_WORKSPACE"],
  "source_repo": os.environ["S_SOURCE"],
  "demo_skill": os.environ["S_DEMO_SKILL"],
  "demo_skill_version": os.environ["S_DEMO_VERSION"],
  "checks": checks,
  "summary": {
    "mode_a": {"pass": int(os.environ["S_MA_P"]), "fail": int(os.environ["S_MA_F"]),
               "skip": int(os.environ["S_MA_S"]), "verdict": os.environ["S_MODE_A_VERDICT"]},
    "mode_b": {"pass": int(os.environ["S_MB_P"]), "fail": int(os.environ["S_MB_F"]),
               "skip": int(os.environ["S_MB_S"]), "verdict": os.environ["S_MODE_B_VERDICT"]},
    "overall": os.environ["S_OVERALL"],
  },
}
with open(os.environ["S_OUT"], "w") as f:
  json.dump(doc, f, indent=2)
' 2>/dev/null || warn "Failed to write run.json (artifacts still on disk at ${VALIDATION_DIR})"

    # Also emit a human-readable run.log mirroring stdout for offline review.
    {
      printf '=== validate-install.sh run.log %s ===\n' "${TIMESTAMP}"
      printf 'mode: %s\n' "${MODE}"
      printf 'workspace_root: %s\n' "${WORKSPACE_ROOT}"
      printf 'source_repo: %s\n' "${SOURCE_REPO}"
      printf 'demo_skill: %s (version %s)\n' "${DEMO_SKILL}" "${DEMO_SKILL_VERSION}"
      printf -- '---\n'
      printf 'Summary:\n'
      printf '  Mode A: %s (%d PASS / %d FAIL / %d SKIP)\n' \
        "${mode_a_verdict}" "${MODE_A_PASS}" "${MODE_A_FAIL}" "${MODE_A_SKIP}"
      printf '  Mode B: %s (%d PASS / %d FAIL / %d SKIP)\n' \
        "${mode_b_verdict}" "${MODE_B_PASS}" "${MODE_B_FAIL}" "${MODE_B_SKIP}"
      printf '  Overall: %s\n' "${overall_verdict}"
    } > "${VALIDATION_DIR}/run.log"
  fi
}

# --- Section 17: Mode router ---

mode_all() {
  mode_a_install_verify
  if [ "${MODE_A_FAIL_FLAG}" -eq 1 ]; then
    # Mode A FAIL → skip Mode B entirely (install must verify first).
    emit_skip "B1" "FIRSTTASK-PREREQS" "Mode A FAIL prevented Mode B" "B"
    emit_skip "B2" "FIRSTTASK-INVOKE-INSTRUCTIONS" "Mode A FAIL prevented Mode B" "B"
    emit_skip "B3" "FIRSTTASK-OUTPUT-EXISTS" "Mode A FAIL prevented Mode B" "B"
    emit_skip "B4" "FIRSTTASK-OUTPUT-STRUCTURAL" "Mode A FAIL prevented Mode B" "B"
    return
  fi
  mode_b_first_task
}

# --- Section 18: Cleanup / signal trap ---

cleanup() {
  local exit_code=$?
  if [ -n "${SESSION_TMPDIR}" ] && [ -d "${SESSION_TMPDIR}" ]; then
    rm -rf "${SESSION_TMPDIR}" 2>/dev/null || true
  fi
  return ${exit_code}
}

on_interrupt() {
  printf '\nValidation cancelled by signal; partial state at: %s\n' "${VALIDATION_DIR}" >&2
  exit 130
}

# --- Section 19: Main entry ---

main() {
  trap cleanup EXIT
  trap on_interrupt INT TERM

  parse_argv "$@"
  check_prereqs
  check_source_repo
  check_workspace_root
  setup_validation_dir

  case "${MODE}" in
    install)
      mode_a_install_verify ;;
    first-task)
      mode_b_first_task ;;
    all)
      mode_all ;;
    operator-pre-existing)
      mode_a_operator_pre_existing ;;
  esac

  log_summary

  if [ "${AGGREGATE_FAIL}" -eq 1 ]; then
    exit 1
  fi
  exit 0
}

main "$@"
