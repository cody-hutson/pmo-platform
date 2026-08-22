#!/usr/bin/env bash
# setup-workspace.sh — Workspace bootstrap for pmo-platform v2
#
# Creates the user-workspace layout, resolves template tokens, installs hooks,
# and configures Claude Code settings on a fresh device.
#
# Idempotent: safe to re-run; reads .workspace-setup.state at entry to determine
# fresh-install vs re-bootstrap vs guided-recovery routing.
#
# Source-of-truth spec: the workspace-bootstrap Stage 5 Solutioning spec.
# Adversarial counter-designs absorbed per the Phase A6.5 review:
#   - PR-1 (Major): hook count corrected to 10 (empirical via
#       `ls core/hooks/*.sh | wc -l` 2026-05-28); install loop is data-driven
#       (whatever .sh files appear in source core/hooks/)
#   - PR-3 + FM-6 (Major): `tests/` subdir declared OUT-OF-SCOPE (source-tree only;
#       NOT installed to workspace `.claude/hooks/` — developer tests stay
#       in the source repo)
#   - FM-1 (BLOCKER): `set -Eeuo pipefail` (note -E for errtrace) + EXIT-trap
#       with explicit INSTALL_COMPLETE flag; per-phase ROLLBACK_OPS sequence
#       iterated in reverse via temp-file-backed list
#   - FM-2 (Major): hook drift decisions cached in state schema
#       (`hook_drift_decisions` map: { basename: { source_sha_seen, operator_decision } })
#   - FM-3 (BLOCKER): `verification_passed` field; state file written AFTER
#       post-install verification gate; branch (c) routes on verification_passed != true
#   - FM-4 (Major): `install_mode` enum ("fresh-install" | "init-only-state" |
#       "rebootstrapped") + `verified_artifacts` flag map
#   - FM-5 (Major): active token set derived from templates via grep, NOT
#       hardcoded 11-token vocabulary; prompts only for tokens actually substituted
#   - CD-2 (Major): inherits checksum-based copy pattern semantics from
#       core/deploy/deploy.sh S-2 mechanism (per `.claude/rules/skill-deployment.md`)
#   - CD-4 (Minor): cross-platform deferral documented inline; script
#       references the Stage 5 spec deferral context (operator records the
#       tracking item at Stage 13 disposition per the spec — keeps the
#       script self-contained without placeholder leak)
#   - CD-5 (Major): hook verification runs a behavioral test (invokes hook
#       with benign JSON payload via stdin; asserts exit 0) NOT just SHA equality
#
# Token substitution: Python `str.replace()` (NOT sed) per the template-
#   substitution Tier 1 contract — sed has metacharacter edge cases (/, &,
#   single-quote, newline) and FM-1 + CD-1 of the adversarial review
#   canonicalized Python `str.replace()` as the choice.
#
# Bash version compatibility: written to run under macOS system bash 3.2.57
# (Darwin 25.x default). NO associative arrays (declare -A), NO parameter
# transformation (${var@Q}). State maps marshalled via JSON files + jq;
# heavy lifting delegated to Python (always-present via /usr/bin/python3
# on Darwin 23+).
#
# Usage:
#   ./setup-workspace.sh [--source-repo PATH] [--workspace-root PATH]
#                        [--init-only-state] [--non-interactive] [--dry-run]
#                        [--help]
#
# Exit codes (sysexits(3)):
#   0   — success
#   1   — generic failure (validation, operator-cancel)
#   64  — EX_USAGE (invalid argv)
#   66  — EX_NOINPUT (source repo missing)
#   69  — EX_UNAVAILABLE (missing prerequisite)
#   73  — EX_CANTCREAT (mkdir/cp failed)
#   74  — EX_IOERR (write failure)
#   78  — EX_CONFIG (non-Darwin platform; cross-platform deferred)
#   130 — SIGINT (operator Ctrl-C)

# FM-1 absorption: -E enables errtrace; -e exits on first unhandled failure;
# -u exits on undefined-var reference; -o pipefail propagates non-rightmost
# pipeline failures. Combined with EXIT trap + INSTALL_COMPLETE flag.
set -Eeuo pipefail

# --- Section 1: Constants + defaults ---
readonly DEFAULT_WORKSPACE_ROOT="${HOME}/Claude"
readonly DEFAULT_SOURCE_REPO="${DEFAULT_WORKSPACE_ROOT}/pmo-platform"
readonly STATE_FILE_NAME=".workspace-setup.state"
readonly STATE_SCHEMA_VERSION="1.0"
readonly SCRIPT_VERSION="v1.04"
# Canonical operator config (per composition-surface-spec.md + depersonalization-spec.md §2).
# XDG-spec location; structured TOML with [meta]/[identity]/[paths]/[platform] sections.
# Per-workspace override (optional). Loaded after operator.toml; fields here win.
readonly OPERATOR_LOCAL_TOML_BASENAME="operator.local.toml"
# Hook count safety floor; current expected count is 10. Loop is data-driven.
readonly EXPECTED_HOOK_COUNT_MIN=8
# Composition-surface install floor (per composition-surface-spec.md §1).
# Empirically 14 files at present; loop is data-driven from manifest.
readonly EXPECTED_SEED_FILE_COUNT_MIN=10
# Declared non-interactive defaults for the two required identity tokens that
# have NO environment source to derive from (unlike NAME/EMAIL/GIT_EMAIL, which
# derive from `git config --global`). Named constants rather than inline
# literals so they are greppable and single-sourced. Reachable ONLY under
# --non-interactive; the interactive path is unchanged and still has no default.
readonly NI_DEFAULT_ROLE_TITLE="Operator"
readonly NI_DEFAULT_ORGANIZATION="Unspecified"
# Composition library — provides Pattern C write primitive + manifest helpers.
# Sourced lazily in install_composition_surface_files (after SOURCE_REPO is set).
LIB_COMPOSITION_SOURCED=0

# Sandbox roots for test isolation (closes QA F9). Defaults match the canonical
# XDG-spec location; env var and CLI flag let integration tests and dry-runs
# isolate cleanly without writing into the operator's real $HOME.
#
#   Precedence: --config-root CLI flag > PMO_PLATFORM_CONFIG_ROOT env var
#               > $HOME-based default
readonly DEFAULT_CONFIG_ROOT="${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"
CONFIG_ROOT=""              # resolved in parse_argv → finalize_paths
OPERATOR_TOML=""            # derived from CONFIG_ROOT

# User-scope settings surface — the re-home target for the PreToolUse hook wiring
# (#4436). Same sandbox-root pattern as CONFIG_ROOT above: a --user-settings flag and
# a PMO_USER_SETTINGS_FILE env var let integration tests point this at a sandbox
# instead of the operator's real ${HOME}/.claude/settings.json.
#
#   Precedence: --user-settings CLI flag > PMO_USER_SETTINGS_FILE env var
#               > $HOME-based default
readonly DEFAULT_USER_SETTINGS="${PMO_USER_SETTINGS_FILE:-${HOME}/.claude/settings.json}"
USER_SETTINGS=""            # resolved in parse_argv

# The runtime-native operator settings overlay (ADR-121 §Decision 7). Layer 2:
# operator-owned, git-ignored, merged by Claude Code itself, and NEVER written by
# the platform beyond a create-once empty scaffold. It is the destination the
# settings guard migrates operator-added keys to before the managed
# .claude/settings.json is regenerated.
readonly SETTINGS_LOCAL_BASENAME="settings.local.json"

# --- Section 2: Mutable state (scalars only; bash-3.2-compatible) ---
WORKSPACE_ROOT=""
SOURCE_REPO=""
INIT_ONLY_STATE=0
REFRESH_HOOKS=0
REHOME_HOOK_WIRING=0
REFRESH_SETTINGS=0
RESTORE_HOOKS=0
RESTORE_GENERATION=""       # empty = newest durable generation (#5662)
LIST_HOOK_SNAPSHOTS=0
FORCE_REGEN=0
NON_INTERACTIVE=0
DRY_RUN=0
INSTALL_COMPLETE=0

# settings.json baseline (ADR-121 §Decision 2). Two hashes with ADR-014's exact
# semantics, relocated from an in-file marker fence — which JSON cannot carry
# (composition-surface-spec.md §2.3) — to the installer's durable state file:
#   SETTINGS_TEMPLATE_SHA  = SHA-256 of core/settings.json.template — the
#                            REGENERATION TRIGGER (managed_sha analogue).
#   SETTINGS_INSTALLED_SHA = SHA-256 of the file as the platform last wrote it —
#                            the TAMPER ANCHOR (installed_sha analogue).
# Empty means "no baseline recorded", which the guard treats as S-2 (classify
# structurally before writing) — never as "unchanged".
SETTINGS_TEMPLATE_SHA=""
SETTINGS_INSTALLED_SHA=""
SETTINGS_GUARD_STATE=""     # S-0..S-5, set by settings_guard_and_regen
SUPPRESS_VALIDATE_HINT=0    # set when guided-recovery exits without doing work
INSTALL_MODE=""             # "fresh-install" | "init-only-state" | "rebootstrapped"
STATE_FILE=""
ACTIVE_TOKENS=""            # space-delimited; computed from templates
SESSION_TMPDIR=""           # scratch dir for temp JSON files

# Per-run scratch JSON files (paths set in init_session_tmpdir; replace
# associative arrays). Each is a small JSON file under SESSION_TMPDIR.
TOKENS_FILE=""              # { "[OPERATOR_NAME]": "value", ... }
CHECKSUMS_FILE=""           # { "block-destructive.sh": "sha256", ... }
DRIFT_DECISIONS_FILE=""     # { "block-destructive.sh": {"operator_decision":"skip","source_sha_seen":"..."} }
ARTIFACTS_FILE=""           # { "templates_substituted": true, ... }
DIRS_CREATED_FILE=""        # newline-separated paths created this run
ROLLBACK_OPS_FILE=""        # newline-separated "kind:target" entries

# --- Section 3: Usage banner ---
usage() {
  cat <<'USAGE'
Usage: setup-workspace.sh [OPTIONS]

Bootstrap a workspace for pmo-platform.

Options:
  --source-repo PATH      Path to cloned pmo-platform (default: ${HOME}/Claude/pmo-platform)
  --workspace-root PATH   Workspace destination (default: ${HOME}/Claude)
  --config-root PATH      Root for operator config writes (default:
                          ${HOME}/.config/pmo-platform; can also be set via
                          PMO_PLATFORM_CONFIG_ROOT env var). Used by integration
                          tests + sandboxed dry-runs to isolate from operator
                          state.
  --init-only-state       Bootstrap only the .workspace-setup.state marker;
                          empirically verify artifacts but perform no install operations
  --refresh-hooks         Re-deploy ONLY the security-hook bundle (hooks +
                          co-shipped primitives + lib/) into an EXISTING workspace,
                          reusing the same drift-preserving install path as a full
                          run. Skips the scaffold/token/skill phases. This is the
                          path update.sh uses so a hook/helper security fix reaches
                          an already-installed workspace (#3430).
  --restore-hooks [GEN]   Put the deployed hook bundle back to a durable snapshot captured
                          by --refresh-hooks. With no GEN, restores the NEWEST generation.
                          Snapshots live under <config-root>/hook-bundle-backups/ and
                          OUTLIVE the run that created them, so this works after a refresh
                          has already succeeded and after a kill that never ran the EXIT
                          trap -- the two shapes the in-run rollback cannot cover (#5662).
                          Files NOT present in the restored generation are REMOVED, so the
                          result is the generation exactly rather than the generation merged
                          with whatever a release added; the count is reported. Every
                          restored file is verified by recomputed SHA-256 before success is
                          claimed. Takes its own snapshot first, so a bad restore is itself
                          recoverable.
  --list-hook-snapshots   List the durable hook-bundle snapshots and their file counts.
  --rehome-hook-wiring    Merge the PreToolUse hook wiring from
                          core/settings.json.template into the USER-scope settings
                          surface, so sessions rooted in the repo, in a worktree, or
                          anywhere outside the workspace project root resolve the
                          hooks at all (#4436). Merges the PreToolUse object ONLY --
                          never SessionStart, never Stop, never any non-hooks key --
                          and preserves every unrelated key already in the target.
                          Idempotent. Deliberately NOT part of any other flow: it
                          writes outside the workspace root and it turns enforcement
                          on for sessions that previously had none, so it is an
                          explicit operator act, ordered AFTER script-allowlist
                          reconciliation. Backs the target up before writing.
  --user-settings PATH    User-scope settings file (default:
                          ${HOME}/.claude/settings.json; can also be set via
                          PMO_USER_SETTINGS_FILE env var). Used by integration tests
                          + sandboxed dry-runs to isolate from operator state.
  --refresh-settings      Re-render ONLY the managed .claude/settings.json into an
                          EXISTING workspace, under the baseline-anchored guard
                          (ADR-121): an untouched platform copy is regenerated, and
                          operator-added keys are migrated to
                          .claude/settings.local.json and backed up BEFORE the
                          rewrite. Skips the scaffold/hook/skill phases. This is the
                          path update.sh uses so a hook REGISTRATION reaches an
                          already-installed workspace, the sibling of --refresh-hooks
                          (which delivers only the hook SCRIPTS).
  --force-regen           Force the settings re-render even when both recorded
                          baselines match (the S-0 no-op skip). The guard still runs
                          first — this never bypasses operator-key migration.
  --non-interactive       Resolve every token from its declared default and never
                          read stdin. A required token with no available default
                          fails with a non-zero exit naming the token; no value is
                          ever silently substituted. Intended for scripted /
                          sandboxed installs. Does not change interactive behavior.
  --dry-run               Preview planned actions; perform no state mutation
  --help                  Show this help

Idempotency:
  The script reads ${CLAUDE_WORKSPACE_ROOT}/.claude/.workspace-setup.state at
  entry to determine routing:
    (a) ABSENT        → fresh-install (creates dirs, resolves tokens, installs hooks)
    (b) VALID         → re-bootstrap (reads cache, reconciles drift)
    (c) CORRUPT       → guided recovery (prompts repair/backup/exit)

  Per-file hook drift decisions cached in state to avoid re-prompting on
  unchanged inputs across re-runs.

Platform:
  Darwin-only on current release. Cross-platform (Linux/WSL) deferred per
  Stage 5 Solutioning Recommendation #3.
USAGE
}

# --- Section 4: Logging helpers ---
log()  { printf '%s\n' "$*" >&2; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err()  { printf 'ERROR: %s\n' "$*" >&2; }
info() { printf 'INFO: %s\n' "$*" >&2; }

# --- Section 5: Session tmpdir for scratch JSON files ---
init_session_tmpdir() {
  SESSION_TMPDIR=$(mktemp -d -t workspace-setup.XXXXXX)
  TOKENS_FILE="${SESSION_TMPDIR}/tokens.json"
  CHECKSUMS_FILE="${SESSION_TMPDIR}/checksums.json"
  DRIFT_DECISIONS_FILE="${SESSION_TMPDIR}/drift_decisions.json"
  ARTIFACTS_FILE="${SESSION_TMPDIR}/artifacts.json"
  DIRS_CREATED_FILE="${SESSION_TMPDIR}/dirs_created.txt"
  ROLLBACK_OPS_FILE="${SESSION_TMPDIR}/rollback_ops.txt"
  printf '{}\n' > "${TOKENS_FILE}"
  printf '{}\n' > "${CHECKSUMS_FILE}"
  printf '{}\n' > "${DRIFT_DECISIONS_FILE}"
  printf '{"templates_substituted":false,"hooks_installed":false,"tokens_resolved":false,"directories_created":false}\n' > "${ARTIFACTS_FILE}"
  : > "${DIRS_CREATED_FILE}"
  : > "${ROLLBACK_OPS_FILE}"
}

cleanup_session_tmpdir() {
  if [ -n "${SESSION_TMPDIR}" ] && [ -d "${SESSION_TMPDIR}" ]; then
    rm -rf "${SESSION_TMPDIR}" 2>/dev/null || true
  fi
}

# JSON map helpers (bash-3.2-compatible alternatives to declare -A)
json_set() {
  # json_set FILE KEY VALUE
  local file="$1" key="$2" value="$3"
  local tmp; tmp=$(mktemp -t json_set.XXXXXX)
  KEY="${key}" VALUE="${value}" python3 -c '
import json
import os
import sys
with open(sys.argv[1], "r") as f:
    data = json.load(f)
data[os.environ["KEY"]] = os.environ["VALUE"]
with open(sys.argv[2], "w") as f:
    json.dump(data, f, indent=2)
' "${file}" "${tmp}"
  mv "${tmp}" "${file}"
}

json_set_bool() {
  # json_set_bool FILE KEY (true|false)
  local file="$1" key="$2" value="$3"
  local tmp; tmp=$(mktemp -t json_set_bool.XXXXXX)
  KEY="${key}" VALUE="${value}" python3 -c '
import json
import os
import sys
with open(sys.argv[1], "r") as f:
    data = json.load(f)
data[os.environ["KEY"]] = (os.environ["VALUE"] == "true")
with open(sys.argv[2], "w") as f:
    json.dump(data, f, indent=2)
' "${file}" "${tmp}"
  mv "${tmp}" "${file}"
}

json_set_obj() {
  # json_set_obj FILE KEY SUBKEY1 VAL1 SUBKEY2 VAL2 ...
  local file="$1" key="$2"; shift 2
  local sub_kvs="" k v
  while [ $# -gt 0 ]; do
    k="$1"; v="$2"; shift 2
    sub_kvs="${sub_kvs}${k}=${v}"$'\n'
  done
  local tmp; tmp=$(mktemp -t json_set_obj.XXXXXX)
  KEY="${key}" SUB_KVS="${sub_kvs}" python3 -c '
import json
import os
import sys
with open(sys.argv[1], "r") as f:
    data = json.load(f)
obj = {}
for line in os.environ["SUB_KVS"].splitlines():
    if "=" in line:
        k, _, v = line.partition("=")
        obj[k] = v
data[os.environ["KEY"]] = obj
with open(sys.argv[2], "w") as f:
    json.dump(data, f, indent=2)
' "${file}" "${tmp}"
  mv "${tmp}" "${file}"
}

json_get() {
  # json_get FILE KEY -- prints value or empty
  local file="$1" key="$2"
  KEY="${key}" python3 -c '
import json
import os
import sys
try:
    with open(sys.argv[1], "r") as f:
        data = json.load(f)
    val = data.get(os.environ["KEY"], "")
    if isinstance(val, bool):
        print("true" if val else "false")
    elif isinstance(val, dict):
        print(json.dumps(val))
    else:
        print(val if val is not None else "")
except Exception:
    print("")
' "${file}" 2>/dev/null
}

json_has_key() {
  # json_has_key FILE KEY -- prints "true" or "false"
  local file="$1" key="$2"
  KEY="${key}" python3 -c '
import json
import os
import sys
try:
    with open(sys.argv[1], "r") as f:
        data = json.load(f)
    print("true" if os.environ["KEY"] in data else "false")
except Exception:
    print("false")
' "${file}" 2>/dev/null
}

json_get_obj_field() {
  # json_get_obj_field FILE KEY SUBKEY
  local file="$1" key="$2" subkey="$3"
  KEY="${key}" SUBKEY="${subkey}" python3 -c '
import json
import os
import sys
try:
    with open(sys.argv[1], "r") as f:
        data = json.load(f)
    obj = data.get(os.environ["KEY"], {})
    if isinstance(obj, dict):
        print(obj.get(os.environ["SUBKEY"], ""))
    else:
        print("")
except Exception:
    print("")
' "${file}" 2>/dev/null
}

json_keys() {
  # json_keys FILE — emits keys one per line
  local file="$1"
  python3 -c '
import json
import sys
with open(sys.argv[1], "r") as f:
    data = json.load(f)
for k in data:
    print(k)
' "${file}" 2>/dev/null
}

# --- Section 6: Platform detection (must run first; no state mutation) ---
# Non-Darwin is a SOFT, opt-in-bypassable gate (v3.91 / #303), not a hard fail.
# CI and #304's cross-platform matrix set PMO_ALLOW_NON_DARWIN=1 so the non-macOS
# legs can run past this point. Default (env unset) preserves the protective
# exit 78: the working bash-free cross-platform install is a later arc (#47/#48),
# so a silent proceed into the bash-only phases (setup + deploy.sh) would
# half-install on an unsupported platform. EX_CONFIG(78) is retained for the
# genuinely-unsupported (un-opted-in) case, per Stage-5 DD-4/REC-3.
check_platform() {
  if [ "$(uname -s)" != "Darwin" ]; then
    if [ -n "${PMO_ALLOW_NON_DARWIN:-}" ]; then
      warn "Non-Darwin platform ($(uname -s)); proceeding under PMO_ALLOW_NON_DARWIN."
      warn "Cross-platform install is in progress (#47/#48); bash-only phases may not complete."
      return 0
    fi
    err "setup-workspace.sh is Darwin-only on current release."
    err "Set PMO_ALLOW_NON_DARWIN=1 to proceed on non-macOS (CI / cross-platform matrix)."
    err "Current platform: $(uname -s)"
    exit 78
  fi
}

# --- Section 7: Argv parsing ---
parse_argv() {
  WORKSPACE_ROOT="$DEFAULT_WORKSPACE_ROOT"
  SOURCE_REPO="$DEFAULT_SOURCE_REPO"
  CONFIG_ROOT="$DEFAULT_CONFIG_ROOT"
  while [ $# -gt 0 ]; do
    case "$1" in
      --source-repo)
        if [ -z "${2:-}" ]; then err "--source-repo requires PATH"; exit 64; fi
        SOURCE_REPO="$2"; shift 2 ;;
      --workspace-root)
        if [ -z "${2:-}" ]; then err "--workspace-root requires PATH"; exit 64; fi
        WORKSPACE_ROOT="$2"; shift 2 ;;
      --config-root)
        if [ -z "${2:-}" ]; then err "--config-root requires PATH"; exit 64; fi
        CONFIG_ROOT="$2"; shift 2 ;;
      --init-only-state)
        INIT_ONLY_STATE=1; shift ;;
      --refresh-hooks)
        REFRESH_HOOKS=1; shift ;;
      --restore-hooks)
        RESTORE_HOOKS=1; shift
        # Optional positional generation. Anything starting with `-` is the NEXT flag, not a
        # generation id, so `--restore-hooks --dry-run` parses the way it reads.
        case "${1:-}" in
          ""|-*) : ;;
          *) RESTORE_GENERATION="$1"; shift ;;
        esac ;;
      --list-hook-snapshots)
        LIST_HOOK_SNAPSHOTS=1; shift ;;
      --rehome-hook-wiring)
        REHOME_HOOK_WIRING=1; shift ;;
      --user-settings)
        if [ -z "${2:-}" ]; then err "--user-settings requires PATH"; exit 64; fi
        USER_SETTINGS="$2"; shift 2 ;;
      --refresh-settings)
        REFRESH_SETTINGS=1; shift ;;
      --force-regen)
        FORCE_REGEN=1; shift ;;
      --non-interactive)
        NON_INTERACTIVE=1; shift ;;
      --dry-run)
        DRY_RUN=1; shift ;;
      --help|-h)
        usage; exit 0 ;;
      *)
        err "Unknown argument: $1"
        usage
        exit 64 ;;
    esac
  done
  finalize_paths
  STATE_FILE="${WORKSPACE_ROOT}/.claude/${STATE_FILE_NAME}"
}

# Derived paths — computed after parse_argv so --config-root overrides take
# effect before any write path is referenced. Made readonly to preserve the
# safety property the previous top-level constants gave.
finalize_paths() {
  OPERATOR_TOML="${CONFIG_ROOT}/operator.toml"
  [ -n "${USER_SETTINGS}" ] || USER_SETTINGS="${DEFAULT_USER_SETTINGS}"
  readonly OPERATOR_TOML CONFIG_ROOT USER_SETTINGS
}

# --- Section 8: Prerequisite checks ---
# jq must be at a hook-reachable ABSOLUTE path, not merely on $PATH: the security
# hooks pin PATH and probe a fixed allowlist, so a jq on $PATH but outside that
# allowlist (e.g. MacPorts) would satisfy `command -v` yet leave the hooks unable
# to find it. Keep this list in sync with the hook resolver (GHSA-9cjm-v22x-4x33).
hook_jq_present() {
  for cand in /usr/bin/jq /opt/homebrew/bin/jq /usr/local/bin/jq; do
    [ -x "$cand" ] && return 0
  done
  return 1
}
check_prereqs() {
  local missing=""
  command -v python3 >/dev/null 2>&1 || missing="${missing} python3"
  command -v shasum  >/dev/null 2>&1 || missing="${missing} shasum"
  command -v git     >/dev/null 2>&1 || missing="${missing} git"
  hook_jq_present || missing="${missing} jq"
  if [ -n "${missing}" ]; then
    err "Missing required tools:${missing}"
    err ""
    err "Hook-Blocked → User-Side Handoff per CLAUDE.md convention:"
    err "Run in your terminal:"
    err "  brew install${missing}"
    err "Then re-invoke this script."
    exit 69
  fi
  # `trash` is RECOMMENDED but not required (block-rm-prefer-trash.sh has
  # 3-tier fallback to osascript).
  if ! command -v trash >/dev/null 2>&1 && \
     [ ! -x "/opt/homebrew/opt/trash/bin/trash" ]; then
    warn "trash binary not found. block-rm-prefer-trash.sh will fall back to"
    warn "osascript (still functional). Recommended: brew install trash"
  fi
}

check_source_repo() {
  if [ ! -d "${SOURCE_REPO}" ]; then
    err "Source repo not found at: ${SOURCE_REPO}"
    err ""
    err "Clone pmo-platform first:"
    err "  git clone https://github.com/cody-hutson/pmo-platform.git ${SOURCE_REPO}"
    err ""
    err "Then re-invoke this script (optionally with --source-repo PATH)."
    exit 66
  fi
  if [ ! -d "${SOURCE_REPO}/core" ]; then
    err "Source repo does not contain core/ subdirectory: ${SOURCE_REPO}/core"
    err "Verify the clone is complete and on the correct branch."
    exit 66
  fi
  if [ ! -f "${SOURCE_REPO}/core/CLAUDE.md.template" ] || \
     [ ! -f "${SOURCE_REPO}/core/settings.json.template" ]; then
    err "Required templates not found:"
    err "  ${SOURCE_REPO}/core/CLAUDE.md.template"
    err "  ${SOURCE_REPO}/core/settings.json.template"
    err "Verify the source repo is on a branch that includes the config templates."
    exit 66
  fi
}

# --- Section 9: Active token set computation (FM-5 absorption) ---
# The manifest is a THIRD grep input, not an accident of file layout (ADR-122
# §Decision 8). ADR-122 makes core/CLAUDE.md.template's whole body a managed
# section, so its authoring header — which declared the reserved token vocabulary
# — had to leave the template: an OPTIONAL token resolving empty would otherwise
# survive unsubstituted into the composed CLAUDE.md and fail run_verification_gate.
# The vocabulary declaration moved to core/deploy/composition-surface-manifest.sh
# and that file is grepped here, so ACTIVE_TOKENS is byte-identical across the
# move. Without this third input the set silently loses [OPERATOR_EMAIL],
# [OPERATOR_PHONE], [OPERATOR_GITHUB], [OPERATOR_HOMEDIR_PATH], and
# [COWORK_INSTALL_PATH_BASE] — the last being the token whose resolver/writer
# pairing was just repaired, so the regression would be a silent re-break.
compute_active_tokens() {
  ACTIVE_TOKENS=$(
    grep -hoE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' \
      "${SOURCE_REPO}/core/CLAUDE.md.template" \
      "${SOURCE_REPO}/core/settings.json.template" \
      "${SOURCE_REPO}/core/deploy/composition-surface-manifest.sh" \
      2>/dev/null \
    | sort -u \
    | tr '\n' ' '
  )
  if [ -z "${ACTIVE_TOKENS// /}" ]; then
    err "No substitution tokens found in templates. Templates may be malformed."
    exit 1
  fi
  info "Active token set: ${ACTIVE_TOKENS}"
}

# --- Section 10: State-marker detection + 3-branch routing ---
detect_state_and_route() {
  if [ ! -e "${STATE_FILE}" ]; then
    echo "fresh"
    return
  fi
  local schema_version
  schema_version=$(jq -r '.schema_version // empty' "${STATE_FILE}" 2>/dev/null || true)
  if [ -z "${schema_version}" ]; then
    echo "recovery"
    return
  fi
  if [ "${schema_version}" != "${STATE_SCHEMA_VERSION}" ]; then
    warn "State file schema version mismatch: found ${schema_version}, expected ${STATE_SCHEMA_VERSION}"
    echo "recovery"
    return
  fi
  # FM-3 absorption: state file lying about completion → guided recovery
  local verification_passed
  verification_passed=$(jq -r '.verification_passed // false' "${STATE_FILE}" 2>/dev/null)
  if [ "${verification_passed}" != "true" ]; then
    warn "State file present but verification_passed != true — routing to guided recovery"
    echo "recovery"
    return
  fi
  echo "rebootstrap"
}

# --- Section 11: operator.toml read/write (canonical per composition-surface-spec.md) ---
# Schema: [meta] schema_version, managed_by | [identity] operator_* | [paths] *_path / *_root | [platform] *
# Token mapping (operator.toml field → bracketed token):
#   [identity].operator_name             → [OPERATOR_NAME]
#   [identity].operator_email            → [OPERATOR_EMAIL]
#   [identity].operator_git_email        → [OPERATOR_GIT_EMAIL]
#   [identity].operator_github           → [OPERATOR_GITHUB]
#   [identity].operator_phone            → [OPERATOR_PHONE]
#   [identity].operator_role_title       → [OPERATOR_ROLE_TITLE]
#   [identity].operator_organization     → [OPERATOR_ORGANIZATION]
#   [paths].claude_workspace_root        → [CLAUDE_WORKSPACE_ROOT]
#   [paths].operator_homedir_path        → [OPERATOR_HOMEDIR_PATH]
#   [paths].cowork_install_path          → [COWORK_INSTALL_PATH_BASE]
# [OPERATOR_FIRST_NAME] is derived from OPERATOR_NAME and not stored.
read_operator_toml() {
  # Read operator.toml (canonical) into TOKENS_FILE. If absent, return 0 (no-op).
  # Per-workspace override at <WORKSPACE_ROOT>/operator.local.toml wins per-field.
  local primary="${OPERATOR_TOML}"
  local override="${WORKSPACE_ROOT:-${DEFAULT_WORKSPACE_ROOT}}/${OPERATOR_LOCAL_TOML_BASENAME}"
  if [ ! -f "${primary}" ] && [ ! -f "${override}" ]; then
    return 0
  fi
  S_TOKENS_FILE="${TOKENS_FILE}" \
  S_PRIMARY="${primary}" \
  S_OVERRIDE="${override}" \
  python3 -c '
import json, os, sys

field_to_token = {
    ("identity", "operator_name"):           "[OPERATOR_NAME]",
    ("identity", "operator_email"):          "[OPERATOR_EMAIL]",
    ("identity", "operator_git_email"):      "[OPERATOR_GIT_EMAIL]",
    ("identity", "operator_github"):         "[OPERATOR_GITHUB]",
    ("identity", "operator_phone"):          "[OPERATOR_PHONE]",
    ("identity", "operator_role_title"):     "[OPERATOR_ROLE_TITLE]",
    ("identity", "operator_organization"):   "[OPERATOR_ORGANIZATION]",
    ("paths",    "claude_workspace_root"):   "[CLAUDE_WORKSPACE_ROOT]",
    ("paths",    "operator_homedir_path"):   "[OPERATOR_HOMEDIR_PATH]",
    ("paths",    "cowork_install_path"):     "[COWORK_INSTALL_PATH_BASE]",
}

def parse_toml(path):
    """Minimal TOML reader: [section] header + key = "value" lines.
    No multiline strings, no nested tables — sufficient for operator.toml schema."""
    result = {}
    section = None
    try:
        with open(path, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("[") and line.endswith("]"):
                    section = line[1:-1].strip()
                    continue
                if "=" in line and section:
                    k, _, v = line.partition("=")
                    k = k.strip()
                    v = v.strip()
                    # Strip surrounding double quotes, unescape \" and \\
                    if v.startswith("\"") and v.endswith("\""):
                        v = v[1:-1].replace("\\\\", "\\").replace("\\\"", "\"")
                    result[(section, k)] = v
    except FileNotFoundError:
        pass
    return result

with open(os.environ["S_TOKENS_FILE"], "r") as f:
    tokens = json.load(f)

# Primary first, then override merges/wins per-field
for path in [os.environ["S_PRIMARY"], os.environ["S_OVERRIDE"]]:
    if not path or not os.path.isfile(path):
        continue
    for (section, key), token in field_to_token.items():
        val = parse_toml(path).get((section, key))
        if val is None or val == "":
            continue
        # Current-run resolutions win (already in tokens); only set if unset
        if token not in tokens:
            tokens[token] = val

with open(os.environ["S_TOKENS_FILE"], "w") as f:
    json.dump(tokens, f, indent=2)
'
}

write_operator_toml() {
  # Write resolved tokens to operator.toml (canonical). Creates parent dir
  # at ~/.config/pmo-platform/ if absent. Sets chmod 600.
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would write operator.toml: ${OPERATOR_TOML}"
    return 0
  fi
  mkdir -p "$(dirname "${OPERATOR_TOML}")"
  local tmp; tmp=$(mktemp -t operator-toml.XXXXXX)
  S_TOKENS_FILE="${TOKENS_FILE}" \
  S_OUT="${tmp}" \
  S_EXISTING="${OPERATOR_TOML}" \
  S_SCRIPT_VERSION="${SCRIPT_VERSION}" \
  python3 -c '
import json, os, sys
from datetime import datetime, timezone

with open(os.environ["S_TOKENS_FILE"], "r") as f:
    tokens = json.load(f)

# --- #383 lossless round-trip: re-parse the EXISTING operator.toml from disk
# BEFORE the mv overwrites it (the mv runs after this writes tmp), so operator-
# added sections/keys outside the managed schema (e.g. [adapters], [methodology],
# [paths] override keys) survive a rewrite/re-bootstrap verbatim. [automation] is
# NOT an example of that class: since v4.23 it is a managed section this generator
# emits itself (through ovd(), below), and only operator-ADDED keys inside it ride
# passthrough("automation").
# Managed keys are re-emitted from tokens; the four operator-or-default fields
# below (pmo_platform_repo_name, work_board, comms_platform, automation_level)
# keep the operator value when set. NOTE: value + section preservation is the load-bearing
# guarantee; inline comments inside operator-added sections are not retained
# (documented residual).
prior = {}        # {section: [(key, raw_quoted_value), ...]} in file order
prior_order = []  # section names in file order
existing = os.environ.get("S_EXISTING", "")
if existing and os.path.isfile(existing):
    section = None
    with open(existing, "r") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            if s.startswith("[") and s.endswith("]"):
                section = s[1:-1].strip()
                if section not in prior:
                    prior[section] = []
                    prior_order.append(section)
                continue
            if "=" in s and section is not None:
                k, _, v = s.partition("=")
                prior[section].append((k.strip(), v.strip()))

def esc(v):
    return str(v).replace("\\", "\\\\").replace("\"", "\\\"")

def get(token, default=""):
    return tokens.get(token, default)

def prior_val(section, key):
    for (k, v) in prior.get(section, []):
        if k == key:
            if v.startswith("\"") and v.endswith("\""):
                return v[1:-1].replace("\\\\", "\\").replace("\\\"", "\"")
            return v
    return None

def ovd(section, key, default):
    # operator-value-or-default: keep the operator value when set, else default
    pv = prior_val(section, key)
    return pv if (pv is not None and pv != "") else default

MANAGED = {
    ("meta", "schema_version"), ("meta", "managed_by"),
    ("identity", "operator_name"), ("identity", "operator_email"),
    ("identity", "operator_git_email"), ("identity", "operator_github"),
    ("identity", "operator_phone"), ("identity", "operator_role_title"),
    ("identity", "operator_organization"),
    ("paths", "claude_workspace_root"), ("paths", "operator_homedir_path"),
    ("paths", "cowork_install_path"), ("paths", "pmo_platform_repo_name"),
    ("platform", "work_board"), ("platform", "comms_platform"),
    ("automation", "automation_level"),
}
MANAGED_SECTIONS = {"meta", "identity", "paths", "platform", "automation"}
# MANAGED is the ALREADY-EMITTED set the passthrough below skips, not an
# overwrite set. Membership does NOT mean "re-emitted from tokens": three of its
# rows (pmo_platform_repo_name, work_board, comms_platform) are emitted through
# ovd() and keep whatever the operator set. automation_level joins them on
# exactly that footing -- listed so passthrough does not echo it a second time
# and produce a duplicate key, emitted through ovd() so a deliberate "off" is
# never reset by a re-bootstrap.

def passthrough(section):
    # operator-added keys in a managed section (not in MANAGED) — preserve verbatim
    for (k, v) in prior.get(section, []):
        if (section, k) not in MANAGED:
            out.append("{} = {}".format(k, v))

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
out = []
out.append("# operator.toml — pmo-platform operator-instance configuration")
out.append("# Canonical location: ~/.config/pmo-platform/operator.toml (XDG)")
out.append("# Schema: core/standards/depersonalization-spec.md §2")
script_version = os.environ["S_SCRIPT_VERSION"]
out.append("# Generated by setup-workspace.sh {} at {}".format(script_version, now))
out.append("# Edit directly or re-run setup-workspace.sh to update (operator additions preserved).")
out.append("")
out.append("[meta]")
out.append("schema_version = 1")
out.append("managed_by = \"pmo-platform\"")
out.append("")
out.append("[identity]")
out.append("operator_name = \"{}\"".format(esc(get("[OPERATOR_NAME]"))))
out.append("operator_email = \"{}\"".format(esc(get("[OPERATOR_EMAIL]"))))
out.append("operator_git_email = \"{}\"".format(esc(get("[OPERATOR_GIT_EMAIL]"))))
out.append("operator_github = \"{}\"".format(esc(get("[OPERATOR_GITHUB]"))))
out.append("operator_phone = \"{}\"".format(esc(get("[OPERATOR_PHONE]"))))
out.append("operator_role_title = \"{}\"".format(esc(get("[OPERATOR_ROLE_TITLE]"))))
out.append("operator_organization = \"{}\"".format(esc(get("[OPERATOR_ORGANIZATION]"))))
passthrough("identity")
out.append("")
out.append("[paths]")
out.append("claude_workspace_root = \"{}\"".format(esc(get("[CLAUDE_WORKSPACE_ROOT]"))))
out.append("operator_homedir_path = \"{}\"".format(esc(get("[OPERATOR_HOMEDIR_PATH]"))))
out.append("cowork_install_path = \"{}\"".format(esc(get("[COWORK_INSTALL_PATH_BASE]"))))
out.append("pmo_platform_repo_name = \"{}\"".format(esc(ovd("paths", "pmo_platform_repo_name", "pmo-platform"))))
passthrough("paths")
out.append("")
out.append("[platform]")
out.append("work_board = \"{}\"".format(esc(ovd("platform", "work_board", "github"))))
out.append("comms_platform = \"{}\"".format(esc(ovd("platform", "comms_platform", ""))))
passthrough("platform")
out.append("")
# The ambient-intake automation ceiling. Seeded so the dial is DISCOVERABLE in
# the generated file rather than findable only by reading operator.toml.template
# -- which this generator never reads, so a template-only default reached nobody.
#
# Seeding it changes discoverability, not behavior: the dial is advisory today
# (skills read it and self-limit), and a skill finding the key absent falls back
# to the same "recommend" documented here. An install with the key and one
# without behave identically. It is emitted through ovd() so re-running setup on
# a workspace whose operator deliberately set "off" preserves that choice.
out.append("[automation]")
out.append("automation_level = \"{}\"".format(esc(ovd("automation", "automation_level", "recommend"))))
passthrough("automation")
out.append("")
# pass-through every NON-MANAGED operator-added section verbatim (adapters,
# methodology, projects, and any unknown section) in original file order. The
# MANAGED_SECTIONS skip immediately below excludes automation: it is emitted
# above, with its own passthrough(), rather than here.
for section in prior_order:
    if section in MANAGED_SECTIONS:
        continue
    out.append("[{}]".format(section))
    for (k, v) in prior[section]:
        out.append("{} = {}".format(k, v))
    out.append("")

with open(os.environ["S_OUT"], "w") as f:
    f.write("\n".join(out))
'
  mv "${tmp}" "${OPERATOR_TOML}"
  chmod 600 "${OPERATOR_TOML}"
  info "Wrote operator.toml: ${OPERATOR_TOML}"
}

# --- Section 12: Token resolution ---
resolve_token() {
  local token="$1"
  local prompt_text="$2"
  local default_value="${3:-}"
  local validator_regex="${4:-}"
  local required="${5:-true}"

  # Cache hit if key is explicitly present in the tokens file (distinguishes
  # "stored empty string from a previous run's optional answer" from "never
  # resolved before"). Without this, optional tokens stored as "" re-prompt
  # forever.
  local has_key; has_key=$(json_has_key "${TOKENS_FILE}" "${token}")
  if [ "${has_key}" = "true" ]; then
    info "Cached: ${token} (no prompt)"
    return 0
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would prompt for: ${token}"
    json_set "${TOKENS_FILE}" "${token}" "<DRY-RUN-PLACEHOLDER>"
    return 0
  fi

  # --non-interactive: resolve from the token's DECLARED default and never read
  # stdin. Placed AFTER the cache check and AFTER the dry-run check so both of
  # those semantics are unchanged. The default is VALIDATED against the same
  # validator_regex the interactive path applies — storing it unvalidated would
  # write a config the interactive path would have rejected (e.g. a
  # `git config user.name` of "x" fails the >=2-char name pattern). A required
  # token with no default HARD-FAILS naming the token rather than silently
  # substituting an empty value.
  if [ "${NON_INTERACTIVE}" -eq 1 ]; then
    if [ -n "${default_value}" ]; then
      if [ -n "${validator_regex}" ] && \
         ! grep -qE "${validator_regex}" <<<"${default_value}"; then
        err "Non-interactive: default for ${token} does not match the required format."
        err "  default: '${default_value}'"
        err "  Set a valid value in <config-root>/operator.toml, then re-run."
        exit 1
      fi
      json_set "${TOKENS_FILE}" "${token}" "${default_value}"
      info "Non-interactive: ${token} = ${default_value} (declared default)"
      return 0
    fi
    if [ "${required}" != "true" ]; then
      json_set "${TOKENS_FILE}" "${token}" ""
      info "Non-interactive: ${token} = (empty; optional)"
      return 0
    fi
    err "Non-interactive: required token ${token} has no default and no cached value."
    err "  Provide it in <config-root>/operator.toml (default ~/.config/pmo-platform/operator.toml),"
    err "  or run without --non-interactive to be prompted."
    exit 1
  fi

  local attempts=0
  local max_attempts=3
  local value=""
  while [ "${attempts}" -lt "${max_attempts}" ]; do
    if [ -n "${default_value}" ]; then
      printf '%s [%s]: ' "${prompt_text}" "${default_value}" >&2
    else
      printf '%s: ' "${prompt_text}" >&2
    fi
    if ! read -r value; then
      err "Prompt input failed (stdin closed?)"
      exit 1
    fi
    if [ -z "${value}" ] && [ -n "${default_value}" ]; then
      value="${default_value}"
    fi
    if [ -z "${value}" ]; then
      if [ "${required}" = "true" ]; then
        warn "${token} is required. Please provide a value."
        attempts=$((attempts + 1))
        continue
      else
        json_set "${TOKENS_FILE}" "${token}" ""
        return 0
      fi
    fi
    if [ -n "${validator_regex}" ]; then
      if ! grep -qE "${validator_regex}" <<<"${value}"; then
        warn "${token} value did not match expected format. Please retry."
        attempts=$((attempts + 1))
        continue
      fi
    fi
    json_set "${TOKENS_FILE}" "${token}" "${value}"
    return 0
  done

  err "Failed to resolve ${token} after ${max_attempts} attempts."
  exit 1
}

resolve_all_tokens() {
  # Read cached tokens from the canonical operator.toml (~/.config/pmo-platform/).
  read_operator_toml

  local git_email_default=""
  local git_username_default=""
  if command -v git >/dev/null 2>&1; then
    git_email_default=$(git config --global user.email 2>/dev/null || true)
    git_username_default=$(git config --global user.name 2>/dev/null || true)
  fi

  # Declared non-interactive defaults for the three required identity tokens the
  # interactive path deliberately offers no default for. These stay EMPTY under
  # the interactive path so its behavior is byte-identical — offering a
  # git-derived name (or a literal role/org) at an interactive prompt would be a
  # behavior change outside this card's scope. [OPERATOR_EMAIL] and
  # [OPERATOR_GIT_EMAIL] already carry a git-derived default on both paths and
  # are therefore untouched.
  local ni_name_default=""
  local ni_role_title_default=""
  local ni_organization_default=""
  if [ "${NON_INTERACTIVE}" -eq 1 ]; then
    ni_name_default="${git_username_default}"
    ni_role_title_default="${NI_DEFAULT_ROLE_TITLE}"
    ni_organization_default="${NI_DEFAULT_ORGANIZATION}"
  fi

  # Resolve dependent-source tokens FIRST (so derived tokens can read from cache).
  # OPERATOR_NAME must precede OPERATOR_FIRST_NAME (derived as `name | head word`).
  # OPERATOR_EMAIL must precede OPERATOR_GIT_EMAIL (default = email value).
  # The alphabetical iteration in the loop below preserves this for already-cached
  # values; here we pre-resolve the source tokens before the loop runs.
  local pre_token
  for pre_token in "[OPERATOR_NAME]" "[OPERATOR_EMAIL]"; do
    case " ${ACTIVE_TOKENS} " in
      *" ${pre_token} "*)
        # resolve_token internally checks cache via json_has_key and skips if
        # already resolved — invoke unconditionally and let the cache check decide.
        case "${pre_token}" in
          "[OPERATOR_NAME]")
            resolve_token "${pre_token}" "Operator full name (e.g., Firstname Lastname)" \
              "${ni_name_default}" "^[A-Za-z][A-Za-z .-]+$" "true"
            ;;
          "[OPERATOR_EMAIL]")
            resolve_token "${pre_token}" "Operator email" \
              "${git_email_default}" "^[^@]+@[^@]+\\.[^@]+$" "true"
            ;;
        esac
        ;;
    esac
  done

  # FM-5 absorption: prompt only for tokens in active set (alphabetical order)
  local tok
  for tok in ${ACTIVE_TOKENS}; do
    case "${tok}" in
      "[OPERATOR_NAME]")
        resolve_token "${tok}" "Operator full name (e.g., Firstname Lastname)" \
          "${ni_name_default}" "^[A-Za-z][A-Za-z .-]+$" "true"
        ;;
      "[OPERATOR_FIRST_NAME]")
        local has_first; has_first=$(json_has_key "${TOKENS_FILE}" "${tok}")
        if [ "${has_first}" != "true" ]; then
          local fullname; fullname=$(json_get "${TOKENS_FILE}" "[OPERATOR_NAME]")
          if [ -n "${fullname}" ]; then
            local first="${fullname%% *}"
            json_set "${TOKENS_FILE}" "${tok}" "${first}"
            info "Derived ${tok}: ${first}"
          else
            resolve_token "${tok}" "Operator first name" "" "^[A-Za-z]+$" "true"
          fi
        else
          info "Cached: ${tok} (no prompt)"
        fi
        ;;
      "[OPERATOR_ROLE_TITLE]")
        resolve_token "${tok}" "Operator role title (e.g., Senior Program Manager)" \
          "${ni_role_title_default}" "^[A-Za-z ].+$" "true"
        ;;
      "[OPERATOR_ORGANIZATION]")
        resolve_token "${tok}" "Operator organization (e.g., Acme Corp)" \
          "${ni_organization_default}" "^[A-Za-z0-9 &.,'-]+$" "true"
        ;;
      "[OPERATOR_PROJECT_NAME]")
        resolve_token "${tok}" "Active PMO project name" \
          "Default Project" "^[A-Za-z0-9 _.,'-]+$" "false"
        ;;
      "[OPERATOR_EMAIL]")
        resolve_token "${tok}" "Operator email" \
          "${git_email_default}" "^[^@]+@[^@]+\\.[^@]+$" "true"
        ;;
      "[OPERATOR_GIT_EMAIL]")
        local default_git_email
        default_git_email=$(json_get "${TOKENS_FILE}" "[OPERATOR_EMAIL]")
        if [ -z "${default_git_email}" ]; then
          default_git_email="${git_email_default}"
        fi
        resolve_token "${tok}" "Operator git commit email (for Co-Authored-By)" \
          "${default_git_email}" "^[^@]+@[^@]+\\.[^@]+$" "true"
        ;;
      "[OPERATOR_HOMEDIR_PATH]")
        json_set "${TOKENS_FILE}" "${tok}" "${HOME}"
        info "Set ${tok}: ${HOME} (from \$HOME)"
        ;;
      "[CLAUDE_WORKSPACE_ROOT]")
        json_set "${TOKENS_FILE}" "${tok}" "${WORKSPACE_ROOT}"
        info "Set ${tok}: ${WORKSPACE_ROOT}"
        ;;
      "[OPERATOR_PHONE]")
        resolve_token "${tok}" "Operator phone (optional; Enter to skip)" \
          "" "" "false"
        ;;
      "[OPERATOR_GITHUB]")
        resolve_token "${tok}" "Operator GitHub handle (optional; Enter to skip)" \
          "${git_username_default}" "" "false"
        ;;
      "[COWORK_INSTALL_PATH_BASE]")
        # Paired with the reserved-token vocabulary line in
        # core/deploy/composition-surface-manifest.sh, which is one of the three
        # files compute_active_tokens greps to derive ACTIVE_TOKENS. ADR-122
        # §Decision 8 moved that declaration OUT of core/CLAUDE.md.template — whose
        # whole body became a managed section — and made the manifest the third
        # grep input; the template carries this token 0 times now, the manifest 2.
        # Both this resolver and the manifest carry the REGISTERED token name
        # (depersonalization-spec.md §1; compose.py maps
        # [paths].cowork_install_path to it). Before this pairing the resolver
        # stored [COWORK_INSTALL_PATH] while write_operator_toml read
        # [COWORK_INSTALL_PATH_BASE], so cowork_install_path was written EMPTY on
        # every first install and the token re-prompted forever (read_operator_toml
        # skips empty values, so the cache never hit). Edit BOTH or neither.
        resolve_token "${tok}" "Cowork install path" \
          "${HOME}/Library/Application Support/Claude/local-agent-mode-sessions" "" "false"
        ;;
      *)
        warn "Token ${tok} appears in templates but has no resolver. Prompting generically."
        resolve_token "${tok}" "Value for ${tok}" "" "" "true"
        ;;
    esac
  done

  json_set_bool "${ARTIFACTS_FILE}" "tokens_resolved" "true"
  # Write the canonical operator.toml (per composition-surface-spec.md).
  write_operator_toml
}

# --- Section 13: Directory layout creation ---
# The last three entries are the ambient-intake capability's member directories.
# They are listed HERE, as ${WORKSPACE_ROOT}-relative literals, rather than
# resolved through lib-instance-path.sh: this function runs before the resolver
# is sourced (the needle and roster scaffolds source it later in the same flow),
# every sibling entry in this list is already a workspace-relative literal, and
# the list-driven loop below is the one creation path that honors all three
# guarantees an operator-data directory needs -- skip-if-exists, dry-run, and a
# rollback op. Consistency inside the function wins here; the resolver is
# authoritative everywhere else this capability touches a path, so a relocation
# of the operator-instance family rewrites this list and nothing more.
#
# Empty directories are the whole of what install provisions for ambient intake.
# Nothing is registered and nothing runs: the scheduled sweep is an operator-
# performed registration on an agent-runtime surface this script cannot reach,
# and it is documented as an activation step in docs/INSTALL.md rather than
# performed here. A directory has no behavior, which is what makes provisioning
# them safe to do unprompted.
create_dir_layout() {
  local dirs
  dirs="${WORKSPACE_ROOT}/.claude
${WORKSPACE_ROOT}/.claude/hooks
${WORKSPACE_ROOT}/projects
${WORKSPACE_ROOT}/knowledge
${WORKSPACE_ROOT}/personal/pmo-instance
${WORKSPACE_ROOT}/personal/pmo-instance/inbox
${WORKSPACE_ROOT}/personal/pmo-instance/ambient-intake
${WORKSPACE_ROOT}/personal/pmo-instance/external-sync"

  local d
  while IFS= read -r d; do
    [ -z "${d}" ] && continue
    if [ -d "${d}" ]; then
      info "SKIPPED (exists): ${d}"
      continue
    fi
    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] would mkdir -p: ${d}"
      continue
    fi
    if ! mkdir -p "${d}"; then
      err "mkdir failed: ${d}"
      exit 73
    fi
    info "CREATED: ${d}"
    printf '%s\n' "${d}" >> "${DIRS_CREATED_FILE}"
    printf 'rmdir-if-empty:%s\n' "${d}" >> "${ROLLBACK_OPS_FILE}"
  done <<EOF
${dirs}
EOF
  json_set_bool "${ARTIFACTS_FILE}" "directories_created" "true"
}

# --- Section 14: Template substitution (Python str.replace per the Tier 1 contract) ---
substitute_template() {
  local src="$1"
  local target="$2"
  local strip_comment="${3:-no}"

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would substitute: ${src} → ${target}"
    return 0
  fi

  python3 -c '
import json
import os
import sys

src_path = sys.argv[1]
target_path = sys.argv[2]
tokens_path = sys.argv[3]
strip_comment = sys.argv[4] == "yes"

with open(tokens_path, "r") as f:
    token_map = json.load(f)

with open(src_path, "r") as f:
    content = f.read()

# Python str.replace() handles all string content literally — no sed
# metacharacter edge cases per the adversarial review FM-1 + CD-1.
for token, value in token_map.items():
    content = content.replace(token, str(value))

if strip_comment:
    # The settings.json template carries a "_comment" key documenting the
    # template; strip it after substitution so the resolved settings.json
    # is a clean JSON document.
    try:
        data = json.loads(content)
        if "_comment" in data:
            data.pop("_comment")
            content = json.dumps(data, indent=2)
    except json.JSONDecodeError as e:
        sys.stderr.write("FATAL: substituted JSON not parseable: {}\n".format(e))
        sys.exit(1)

os.makedirs(os.path.dirname(target_path) or ".", exist_ok=True)
with open(target_path, "w") as f:
    f.write(content)
    if not content.endswith("\n"):
        f.write("\n")
' "${src}" "${target}" "${TOKENS_FILE}" "${strip_comment}" || {
    err "Template substitution failed: ${src} → ${target}"
    exit 74
  }

  if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${target}" 2>/dev/null; then
    err "Substituted file still contains unresolved tokens: ${target}"
    err "Unresolved:"
    grep -oE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${target}" | sort -u >&2
    exit 1
  fi

  info "SUBSTITUTED: ${src} → ${target}"
  printf 'rm-file:%s\n' "${target}" >> "${ROLLBACK_OPS_FILE}"
}

substitute_templates() {
  # CLAUDE.md is NOT written here. ADR-122 re-categorized it from Customizable to
  # Composition-surface: it is a row in core/deploy/composition-surface-manifest.sh
  # and install_composition_surface_files (Section 15b) is its sole writer at
  # install, as ./update.sh is at update. Two writers on one file — a whole-file
  # substitution here plus a marker-fenced write there — is precisely the
  # divergence that produced the false-regeneration-marker defect this supersedes.
  # The settings.json arm is retained: it remains wholly Customizable (§2.3).
  #
  # It is NOT a bare substitute_template. ADR-121 §Decision 4 requires the guard on
  # every re-render of the managed file, and this function is reached by the
  # fresh/rebootstrap/recovery flows as well as by a first install. The dispatcher
  # is defined with the rest of the guard machinery in Section 14b.
  settings_install_or_guarded_rerender
  json_set_bool "${ARTIFACTS_FILE}" "templates_substituted" "true"
}

# --- Section 14b: settings.json operator-key guard + baseline-anchored refresh ---
# ADR-121. The managed .claude/settings.json is the registry binding the platform's
# security hooks to the events they guard. Before this section existed, update.sh
# refreshed the hook SCRIPTS (Phase 5c) and nothing refreshed their REGISTRATIONS,
# so a workspace could hold every current hook on disk with the events that would
# invoke them unwired. This section is the registration half.
#
# It is deliberately NOT a merge. settings.json is 100% platform-owned; the
# operator's surface is the runtime-native settings.local.json overlay, which
# Claude Code merges itself. So the contract is: DETECT -> MIGRATE -> REGENERATE.
#
# ORDERING (ADR-121 §Decision 4 + §Decision 8) — the guard is the refresh's
# precondition and there is no code path around it. settings_regenerate is called
# ONLY from settings_guard_and_regen, after a classification has been rendered.

# SHA-256 of a file; empty string when the file is absent (never an error, so a
# missing baseline reads as "unknown" rather than aborting under set -e).
settings_sha_of() {
  if [ ! -f "$1" ]; then
    printf ''
    return 0
  fi
  shasum -a 256 "$1" | awk '{print $1}'
}

# Record BOTH baselines from the current source template and the file as it now
# stands on disk. Called only by code that has just written settings.json from the
# current template, so "installed" genuinely means "what the platform wrote".
record_settings_baseline() {
  SETTINGS_TEMPLATE_SHA="$(settings_sha_of "${SOURCE_REPO}/core/settings.json.template")"
  SETTINGS_INSTALLED_SHA="$(settings_sha_of "${WORKSPACE_ROOT}/.claude/settings.json")"
}

# ADR-121 §Decision 7: create-once, empty, never regenerated. The `[ -f ]` guard IS
# that guarantee — identical in contract to scaffold_localized_needles /
# scaffold_localized_roster. The body is exactly `{}` and nothing else: any
# commentary or default would make "has the operator customized this?" undecidable
# (Stage-5 trap T-7).
scaffold_settings_local() {
  local overlay="${WORKSPACE_ROOT}/.claude/${SETTINGS_LOCAL_BASENAME}"
  if [ -f "${overlay}" ]; then
    info "PRESERVED (operator data, never regenerated): ${overlay}"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would scaffold operator settings overlay → ${overlay}"
    return 0
  fi
  mkdir -p "$(dirname "${overlay}")"
  printf '{}\n' > "${overlay}"
  info "Scaffolded operator settings overlay → ${overlay}"
  if [ -n "${ROLLBACK_OPS_FILE}" ] && [ -f "${ROLLBACK_OPS_FILE}" ]; then
    printf 'rm-file:%s\n' "${overlay}" >> "${ROLLBACK_OPS_FILE}"
  fi
}

# Structural classifier (ADR-121 §Decision 3 + §Decision 10). Compares the LIVE
# file against the FRESHLY RESOLVED template — never a hardcoded key list, because
# the whole file is template-rendered and any fixed list is stale on its next
# revision.
#
# Registration identity is the (event, matcher, basename(command)) triple:
#   - basename, not full path, because [CLAUDE_WORKSPACE_ROOT] is baked into every
#     command string, so a path-keyed diff false-fires on any workspace move (T-6);
#   - over the RESOLVED file, not the raw template, because the template's _comment
#     key names setup-workspace.sh in prose and substitute_template strips that key
#     by design — a filename-shaped scan of the raw template counts a registration
#     a deployed file can never carry.
#
# Emits a JSON verdict on stdout:
#   {"verdict": "CLEAN"|"OPERATOR"|"CONFLICT"|"MALFORMED",
#    "operator_paths": [...], "platform_overrides": [...],
#    "conflicts": [...], "fragment": {...}}
#
# "operator_only" means: present in live, ABSENT from the resolved template. A
# same-path value difference is platform state and is REPLACED by the refresh (it
# is reported as a platform_override and preserved in the pre-write backup, never
# silently dropped) — promoting it into the overlay would pin a stale platform
# value forever, which is the worse failure.
#
# BOUNDED RESIDUAL (accepted, ADR-121 §Consequences): a key the PLATFORM retired
# since install also reads as absent-from-template. The byte-exact S-1 arm is what
# keeps that from mattering in the ordinary case — an untouched copy regenerates
# with no diff at all, so a retired key simply disappears. The residual is confined
# to "the operator edited the file AND the platform retired a key in the same
# window", where the bias is toward preservation: the key lands in the operator's
# own, editable overlay and is named in the warning.
settings_classify() {
  local resolved="$1" live="$2" overlay="$3"
  S_RESOLVED="${resolved}" S_LIVE="${live}" S_OVERLAY="${overlay}" python3 -c '
import json, os, sys

env = os.environ

def load(path, default=None):
    if not path or not os.path.isfile(path):
        return default
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (ValueError, OSError):
        return "__MALFORMED__"

resolved = load(env["S_RESOLVED"])
live = load(env["S_LIVE"])
overlay = load(env["S_OVERLAY"], {})

if live == "__MALFORMED__" or live is None:
    print(json.dumps({"verdict": "MALFORMED", "operator_paths": [], "platform_overrides": [], "conflicts": [], "fragment": {}}))
    sys.exit(0)
if resolved == "__MALFORMED__" or resolved is None:
    sys.stderr.write("FATAL: resolved settings template is not readable JSON\n")
    sys.exit(1)
if overlay == "__MALFORMED__" or overlay is None:
    overlay = {}

PERM_LISTS = ("deny", "allow", "ask")

operator_paths = []
platform_overrides = []
fragment = {}

def triple(event, matcher, cmd):
    return (event, matcher, os.path.basename(cmd or ""))

def hook_triples(doc):
    """(event, matcher, basename) -> the enclosing (matcher, entry) it came from."""
    out = {}
    for event, blocks in (doc.get("hooks") or {}).items():
        if not isinstance(blocks, list):
            continue
        for block in blocks:
            if not isinstance(block, dict):
                continue
            matcher = block.get("matcher", "")
            for entry in (block.get("hooks") or []):
                if not isinstance(entry, dict):
                    continue
                out[triple(event, matcher, entry.get("command", ""))] = (event, matcher, entry)
    return out

def frag_set(path_keys, value):
    node = fragment
    for k in path_keys[:-1]:
        node = node.setdefault(k, {})
    node[path_keys[-1]] = value

def walk(live_node, tpl_node, path):
    """Object-key set difference, recursing into shared object keys."""
    for key, lval in live_node.items():
        here = path + [key]
        dotted = ".".join(here)
        if key not in tpl_node:
            operator_paths.append(dotted)
            frag_set(here, lval)
            continue
        tval = tpl_node[key]
        if isinstance(lval, dict) and isinstance(tval, dict):
            walk(lval, tval, here)
        elif lval != tval:
            platform_overrides.append(dotted)

# (1)+(4) generic object-key difference, with the two modelled arrays carved out.
live_top = {k: v for k, v in live.items() if k not in ("permissions", "hooks")}
tpl_top = {k: v for k, v in resolved.items() if k not in ("permissions", "hooks")}
walk(live_top, tpl_top, [])

# (2) permissions.{deny,allow,ask} — string-set difference, both ways.
lperm = live.get("permissions") or {}
tperm = resolved.get("permissions") or {}
if isinstance(lperm, dict) and isinstance(tperm, dict):
    extra_perm = {}
    for name in PERM_LISTS:
        lv = lperm.get(name) or []
        tv = tperm.get(name) or []
        if isinstance(lv, list) and isinstance(tv, list):
            extras = [x for x in lv if x not in tv]
            if extras:
                extra_perm[name] = extras
                operator_paths.append("permissions.%s[+%d]" % (name, len(extras)))
    # any non-list / unmodelled key under permissions falls through the generic walk
    lrest = {k: v for k, v in lperm.items() if k not in PERM_LISTS}
    trest = {k: v for k, v in tperm.items() if k not in PERM_LISTS}
    walk(lrest, trest, ["permissions"])
    if extra_perm:
        node = fragment.setdefault("permissions", {})
        for name, extras in extra_perm.items():
            node[name] = extras
elif lperm != tperm:
    platform_overrides.append("permissions")

# (3) hook registrations — set difference over the identity triple.
ltrip = hook_triples(live)
ttrip = hook_triples(resolved)
live_only = [t for t in ltrip if t not in ttrip]
if live_only:
    hooks_frag = fragment.setdefault("hooks", {})
    grouped = {}
    for t in live_only:
        event, matcher, entry = ltrip[t]
        grouped.setdefault((event, matcher), []).append(entry)
        operator_paths.append("hooks.%s[%s]:%s" % (event, matcher, t[2]))
    for (event, matcher), entries in grouped.items():
        block = {"hooks": entries}
        if matcher:
            block["matcher"] = matcher
        hooks_frag.setdefault(event, []).append(block)

# Conflict detection (ADR-121 §Decision 5): a scalar/object leaf the overlay
# already defines with a DIFFERENT value. List merges are set-unions and cannot
# conflict.
conflicts = []

def check_conflicts(frag, ov, path):
    for key, fval in frag.items():
        here = path + [key]
        dotted = ".".join(here)
        if key not in ov:
            continue
        oval = ov[key]
        if isinstance(fval, dict) and isinstance(oval, dict):
            check_conflicts(fval, oval, here)
        elif isinstance(fval, list) and isinstance(oval, list):
            continue
        elif fval != oval:
            conflicts.append(dotted)

if isinstance(overlay, dict):
    check_conflicts(fragment, overlay, [])

if conflicts:
    verdict = "CONFLICT"
elif operator_paths:
    verdict = "OPERATOR"
else:
    verdict = "CLEAN"

print(json.dumps({
    "verdict": verdict,
    "operator_paths": sorted(operator_paths),
    "platform_overrides": sorted(platform_overrides),
    "conflicts": sorted(conflicts),
    "fragment": fragment,
}))
'
}

# Deep-merge the migration fragment into the operator overlay. Objects recurse,
# lists set-union (append only what is absent), and a scalar the overlay already
# defines is NEVER clobbered — the CONFLICT verdict has already aborted that case
# before this runs, so this is belt-and-braces on an already-guarded path.
settings_migrate_to_overlay() {
  local overlay="$1" fragment_json="$2"
  S_OVERLAY="${overlay}" S_FRAGMENT="${fragment_json}" python3 -c '
import json, os

env = os.environ
overlay_path = env["S_OVERLAY"]
fragment = json.loads(env["S_FRAGMENT"])

try:
    with open(overlay_path, "r") as f:
        overlay = json.load(f)
    if not isinstance(overlay, dict):
        overlay = {}
except (OSError, ValueError):
    overlay = {}

def merge(dst, src):
    for key, val in src.items():
        if key not in dst:
            dst[key] = val
        elif isinstance(dst[key], dict) and isinstance(val, dict):
            merge(dst[key], val)
        elif isinstance(dst[key], list) and isinstance(val, list):
            for item in val:
                if item not in dst[key]:
                    dst[key].append(item)
        # else: an existing scalar is left untouched (CONFLICT already aborted)

merge(overlay, fragment)

os.makedirs(os.path.dirname(overlay_path) or ".", exist_ok=True)
with open(overlay_path, "w") as f:
    json.dump(overlay, f, indent=2)
    f.write("\n")
'
}

# Render the template through substitute_template — the SAME writer the install
# path uses, so install-time and update-time bytes are identical by construction and
# the two shipped failure gates (hard-fail on unparseable substituted JSON, hard-fail
# on unresolved tokens) are inherited rather than re-implemented (SR-G3).
#
# The render targets the per-run SCRATCH tmpdir, never the live file, and the refresh
# then installs those verified bytes. That ordering is load-bearing, not stylistic:
# substitute_template writes its target BEFORE the unresolved-token gate runs and
# records an `rm-file:` rollback op against it, so rendering straight onto the live
# path would mean a token-resolution failure first writes a broken settings.json and
# then has the EXIT-trap DELETE it — leaving the workspace with no platform settings
# at all, strictly worse than the stale file this card exists to refresh. Rendering
# to scratch makes every failure mode leave the live file exactly as it was.
#
# Scratch is not operator state, so this runs under --dry-run too; that is what lets
# --dry-run report a real classification instead of guessing at one.
SETTINGS_RESOLVED=""
settings_render_to_scratch() {
  SETTINGS_RESOLVED="${SESSION_TMPDIR}/settings.resolved.json"
  local saved_dry="${DRY_RUN}"
  DRY_RUN=0
  substitute_template \
    "${SOURCE_REPO}/core/settings.json.template" \
    "${SETTINGS_RESOLVED}" \
    "yes"
  DRY_RUN="${saved_dry}"
}

# Install the already-verified scratch render over the live file. Called ONLY from
# settings_guard_and_regen, and only after a classification has been rendered.
settings_regenerate() {
  cp "${SETTINGS_RESOLVED}" "${WORKSPACE_ROOT}/.claude/settings.json"
  record_settings_baseline
}

# The guard. Renders exactly one of S-0..S-5 and is the ONLY caller of
# settings_regenerate.
settings_guard_and_regen() {
  local src="${SOURCE_REPO}/core/settings.json.template"
  local target="${WORKSPACE_ROOT}/.claude/settings.json"
  local overlay="${WORKSPACE_ROOT}/.claude/${SETTINGS_LOCAL_BASENAME}"
  SETTINGS_GUARD_STATE=""

  if [ ! -f "${src}" ]; then
    warn "settings template not found at ${src}; skipping settings refresh"
    SETTINGS_GUARD_STATE="SKIP-NOSRC"
    return 0
  fi
  if [ ! -f "${target}" ]; then
    info "No deployed settings.json at ${target}; a full setup-workspace.sh run installs it. Skipping refresh."
    SETTINGS_GUARD_STATE="SKIP-NOTARGET"
    return 0
  fi

  local src_sha live_sha
  src_sha="$(settings_sha_of "${src}")"
  live_sha="$(settings_sha_of "${target}")"

  # --- S-0: both baselines match and no force → no write, no flag flip. Mirrors
  # Phase 3's managed_sha short-circuit and is what keeps EX_NOCHANGE reachable.
  if [ "${FORCE_REGEN}" -eq 0 ] \
     && [ -n "${SETTINGS_TEMPLATE_SHA}" ] && [ "${src_sha}" = "${SETTINGS_TEMPLATE_SHA}" ] \
     && [ -n "${SETTINGS_INSTALLED_SHA}" ] && [ "${live_sha}" = "${SETTINGS_INSTALLED_SHA}" ]; then
    info "S-0 settings.json already current (template + installed baselines both match); no write."
    SETTINGS_GUARD_STATE="S-0"
    return 0
  fi

  # Render once, to scratch, before any decision. Every write path below installs
  # these already-verified bytes, so a render failure can never damage the live file.
  settings_render_to_scratch

  # --- S-1: live file is byte-identical to what the platform last wrote. That is
  # proof of an untouched platform copy, so no structural diff is needed and a
  # platform-retired key simply disappears with the rewrite.
  if [ -n "${SETTINGS_INSTALLED_SHA}" ] && [ "${live_sha}" = "${SETTINGS_INSTALLED_SHA}" ]; then
    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] S-1 untouched platform copy → would regenerate settings.json"
      SETTINGS_GUARD_STATE="S-1"
      return 0
    fi
    info "S-1 settings.json is an untouched platform copy; regenerating from the current template."
    settings_regenerate
    SETTINGS_GUARD_STATE="S-1"
    return 0
  fi

  # --- S-2..S-5: classify structurally against the freshly rendered template.
  local verdict_json
  verdict_json="$(settings_classify "${SETTINGS_RESOLVED}" "${target}" "${overlay}")"
  local verdict operator_paths platform_overrides conflicts fragment
  verdict="$(printf '%s' "${verdict_json}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["verdict"])')"
  operator_paths="$(printf '%s' "${verdict_json}" | python3 -c 'import json,sys; print(", ".join(json.load(sys.stdin)["operator_paths"]))')"
  platform_overrides="$(printf '%s' "${verdict_json}" | python3 -c 'import json,sys; print(", ".join(json.load(sys.stdin)["platform_overrides"]))')"
  conflicts="$(printf '%s' "${verdict_json}" | python3 -c 'import json,sys; print(", ".join(json.load(sys.stdin)["conflicts"]))')"
  fragment="$(printf '%s' "${verdict_json}" | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["fragment"]))')"

  case "${verdict}" in
    MALFORMED)
      # --- S-5: the runtime is loading NO platform settings at all, which is
      # strictly worse than any customization loss. Preserve the bytes on the
      # tamper convention, then regenerate.
      SETTINGS_GUARD_STATE="S-5"
      if [ "${DRY_RUN}" -eq 1 ]; then
        info "[dry-run] S-5 settings.json is not parseable JSON → would back up + regenerate"
        return 0
      fi
      local tamper_backup="${WORKSPACE_ROOT}/.backup-tampered-$(date -u +%Y%m%dT%H%M%SZ)"
      mkdir -p "${tamper_backup}"
      cp "${target}" "${tamper_backup}/settings.json"
      warn "S-5 settings.json is not parseable JSON; backed up to ${tamper_backup}/settings.json; regenerating from template."
      settings_regenerate
      return 0
      ;;
    CONFLICT)
      # --- S-4: the ONE case where migration would lose data. Write nothing at
      # all, name the conflict, and state plainly that the platform registrations
      # did not land. Non-fatal — the rest of the update continues.
      SETTINGS_GUARD_STATE="S-4"
      local conflict_backup="${WORKSPACE_ROOT}/.backup-pre-update-$(date -u +%Y%m%dT%H%M%SZ)"
      if [ "${DRY_RUN}" -eq 0 ]; then
        mkdir -p "${conflict_backup}"
        cp "${target}" "${conflict_backup}/settings.json"
      fi
      warn "S-4 settings refresh ABORTED — ${SETTINGS_LOCAL_BASENAME} already defines: ${conflicts}"
      warn "S-4 nothing was written. Platform security-hook REGISTRATIONS did NOT land in ${target}."
      warn "S-4 resolve the conflicting key(s) in ${overlay}, then re-run. Pre-abort copy: ${conflict_backup}/settings.json"
      return 0
      ;;
    OPERATOR)
      # --- S-3: migrate → back up → regenerate. Migration FIRST, so "apply the
      # platform version" is never destructive (ADR-121 §Decision 4).
      SETTINGS_GUARD_STATE="S-3"
      if [ "${DRY_RUN}" -eq 1 ]; then
        info "[dry-run] S-3 operator-added content in settings.json: ${operator_paths}"
        info "[dry-run] would migrate it to ${overlay}, back up, then regenerate"
        return 0
      fi
      scaffold_settings_local
      settings_migrate_to_overlay "${overlay}" "${fragment}"
      local backup_dir="${WORKSPACE_ROOT}/.backup-pre-update-$(date -u +%Y%m%dT%H%M%SZ)"
      mkdir -p "${backup_dir}"
      cp "${target}" "${backup_dir}/settings.json"
      warn "S-3 MIGRATED operator-added settings → ${overlay}: ${operator_paths}"
      warn "S-3 pre-migration copy of the managed file: ${backup_dir}/settings.json"
      if [ -n "${platform_overrides}" ]; then
        warn "S-3 platform-owned value(s) REPLACED by the platform version (recoverable from the copy above): ${platform_overrides}"
      fi
      settings_regenerate
      info "S-3 regenerated ${target} from the current template."
      return 0
      ;;
    CLEAN)
      # --- S-2 resolving to the S-1 outcome: the live file differs from the
      # resolved template only at platform-owned paths (or only in formatting), so
      # there is nothing to preserve. AC-3's no-false-fire arm.
      SETTINGS_GUARD_STATE="S-2"
      if [ "${DRY_RUN}" -eq 1 ]; then
        info "[dry-run] S-2 no operator-added content → would regenerate settings.json"
        return 0
      fi
      if [ -n "${platform_overrides}" ]; then
        local pv_backup="${WORKSPACE_ROOT}/.backup-pre-update-$(date -u +%Y%m%dT%H%M%SZ)"
        mkdir -p "${pv_backup}"
        cp "${target}" "${pv_backup}/settings.json"
        warn "S-2 platform-owned value(s) REPLACED by the platform version (pre-write copy: ${pv_backup}/settings.json): ${platform_overrides}"
      fi
      info "S-2 no operator-added content in settings.json; regenerating from the current template."
      settings_regenerate
      return 0
      ;;
    *)
      warn "settings guard returned an unrecognized verdict '${verdict}'; writing nothing."
      SETTINGS_GUARD_STATE="SKIP-UNKNOWN"
      return 0
      ;;
  esac
}

# The install-time entry point to the guard, called from substitute_templates and
# therefore reached by fresh_install, rebootstrap and guided_recovery.
#
# The Stage-5 design record for this card (sub-task #4790) scopes the guard to "the
# new --refresh-settings flow AND the existing fresh/rebootstrap flows". That scope is
# a Stage-5 decision, NOT an ADR clause: ADR-121 §Decision 4 is "Migration precedes
# regeneration; warning alone is not sufficient", which governs the guard's ORDER, not
# the set of flows it covers. The behaviour below conforms to both records.
#
# Only the first half of that scope shipped initially: a plain
# setup-workspace.sh re-run over a healthy workspace routes to rebootstrap, which
# called substitute_template directly and overwrote the managed file with no
# classification at all — measurably dropping operator-added keys with no migration,
# no backup and no warning, on the one path docs/UPDATE.md §6.4 names. This is the
# missing half, and it deliberately REUSES settings_guard_and_regen rather than
# adding a second classifier: one guard, one contract, one set of S-* verdicts.
#
# The two cases are genuinely different and must not be collapsed:
#
#   NO live file (a genuinely fresh workspace) — there is nothing to preserve, and
#   settings_guard_and_regen returns SKIP-NOTARGET without writing precisely because
#   it is a refresh, not an installer. The direct substitute_template IS the install
#   write; routing it through the guard instead would deploy no settings.json at all.
#
#   A live file EXISTS (rebootstrap, guided recovery, or a re-run over a workspace
#   someone hand-edited) — the write is a RE-RENDER and must be classified first,
#   exactly as the update path classifies it.
settings_install_or_guarded_rerender() {
  local target="${WORKSPACE_ROOT}/.claude/settings.json"

  if [ ! -f "${target}" ]; then
    substitute_template \
      "${SOURCE_REPO}/core/settings.json.template" \
      "${target}" \
      "yes"
    # The platform just wrote this file from the current template, so both baselines
    # are recordable. Without it the first update finds no baseline and runs the
    # structural diff on every run.
    record_settings_baseline
    return 0
  fi

  # The overlay is the migration DESTINATION, so it must exist before the guard can
  # migrate into it. scaffold_settings_local is create-once by contract, so calling
  # it here and again later in the flow is idempotent.
  scaffold_settings_local
  settings_guard_and_regen

  # Baseline re-anchoring is ARM-SCOPED, mirroring refresh_settings_flow. Every arm
  # that WROTE re-anchored both baselines inside settings_regenerate already. The
  # arms that wrote nothing (S-0, S-4, SKIP-*) must keep the baselines as read from
  # state: re-anchoring SETTINGS_INSTALLED_SHA to a file the platform did NOT write
  # is exactly what would make the NEXT run read an operator-edited file as an
  # "untouched platform copy" (the S-1 arm) and regenerate over it with no migration
  # — reintroducing the silent-drop this function exists to close, one run later.
  case "${SETTINGS_GUARD_STATE}" in
    S-1|S-2|S-3|S-5)
      : ;;
    *)
      info "Settings guard wrote nothing (${SETTINGS_GUARD_STATE:-none}); baselines left as recorded."
      ;;
  esac
}

# --- Section 14b: Pre-write backup + overwrite-safe rollback op ---
# The rollback ledger carried ONE verb, `rm-file`, and it is correct only for a write that
# CREATES a file that did not exist — undoing a creation is a delete. Every --refresh-hooks
# write OVERWRITES an already-deployed file, and for those `rm-file` is not merely wrong but
# actively harmful: rolling back a partial refresh would DELETE hooks and shared libraries
# that were present and healthy beforehand, converting a partial refresh into exactly the
# fail-closed denial storm the rollback exists to prevent.
#
# `restore-file` is the overwrite-safe verb. The pre-write bytes are copied aside first and
# the EXIT trap copies them back. The backup location is DERIVED from the target path by a
# pure function that both the writer and the trap call, so the ledger line carries a single
# field — no separator that a path character could be confused with, and no second file to
# keep in sync. This mirrors the unconditional pre-write backup update.sh takes before
# regenerating a composition surface (ADR-122 §Decision 7); the hook bundle is the one
# non-git deploy surface that had no equivalent.
prewrite_backup_path() {
  local target="$1" key
  key=$(printf '%s' "${target}" | shasum -a 256 | awk '{print $1}')
  printf '%s/prewrite/%s\n' "${SESSION_TMPDIR}" "${key}"
}

# record_write_rollback <target> — call IMMEDIATELY BEFORE writing <target>.
#   target absent  → ledger `rm-file:`      (undo the creation)
#   target present → copy the bytes aside, ledger `restore-file:` (undo the overwrite)
# A backup that cannot be taken is a hard failure: proceeding would perform an
# irreversible write on the one surface `git revert` cannot restore.
record_write_rollback() {
  local target="$1" backup
  [ "${DRY_RUN}" -eq 0 ] || return 0
  [ -n "${ROLLBACK_OPS_FILE}" ] || return 0
  if [ ! -e "${target}" ]; then
    printf 'rm-file:%s\n' "${target}" >> "${ROLLBACK_OPS_FILE}"
    return 0
  fi
  backup=$(prewrite_backup_path "${target}")
  mkdir -p "$(dirname "${backup}")" || { err "pre-write backup dir failed for ${target}"; exit 74; }
  cp "${target}" "${backup}" || { err "pre-write backup failed for ${target}"; exit 74; }
  printf 'restore-file:%s\n' "${target}" >> "${ROLLBACK_OPS_FILE}"
}

# --- Section 14c: Durable hook-bundle snapshot (#5662) ---
# WHY THIS EXISTS, AND WHY IT IS NOT SESSION_TMPDIR.
#
# Section 14b above is per-file, pre-write, byte-exact and ledger-ordered, and the EXIT trap
# replays it in reverse. It is precise, cheap, and mutation-verified (test_refresh_hooks.sh
# Cases 9a-9d). It is also scoped to SESSION_TMPDIR, which `mktemp -d` creates and
# cleanup_session_tmpdir destroys -- so its coverage is IN-RUN FAILURE ONLY. Two shapes fall
# entirely outside it, and neither is a defect in it:
#
#   1. A process killed without running the EXIT trap (SIGKILL, power loss, terminal
#      teardown) inside the window between the hook entrypoints being copied and the shared
#      libraries being co-deployed ~90 lines later in install_hooks. Ledger and backups both
#      die with the process. The bundle is left hooks-new / library-absent, which is the
#      fail-closed state: measured at 412 of 871 hook assertions flipping to deny and none to
#      allow, in enforce mode. In that state an agent's own shell calls are denied, so nothing
#      can self-repair and recovery is operator-side only.
#   2. A rollback wanted AFTER a refresh already succeeded. INSTALL_COMPLETE=1 means cleanup()
#      deliberately does not roll back -- correct -- and then destroys the backups, so the
#      pre-refresh bytes are gone.
#
# This section SUPPLEMENTS 14b; it replaces nothing. Not one line of the in-run path changes.
# The two mechanisms cover disjoint failure sets at different granularities and costs, and
# weakening the verified in-run guard to simplify this one would trade a guard that has been
# watched working for one that has not.
#
# WHERE IT LIVES. ${CONFIG_ROOT}/hook-bundle-backups/ -- CONFIG_ROOT being the installer's
# existing XDG operator-config root (${HOME}/.config/pmo-platform by default, overridable by
# --config-root and PMO_PLATFORM_CONFIG_ROOT). This root is REUSED rather than invented:
#   - it is a normal directory, not a mktemp dir, so no trap and no process exit removes it;
#   - it is outside the repository tree, so `git clean`, a branch switch, or a re-clone cannot
#     destroy it and it can never be accidentally committed to a public repo;
#   - it is outside <workspace-root>/.claude/hooks/, the surface being repaired -- a store kept
#     INSIDE the bundle would be eaten by the very restore pass that removes non-manifest
#     files (see restore_hooks_flow);
#   - it is ALREADY sandbox-parameterized, so the regression suite isolates with no new
#     plumbing and never touches operator state.
#
# HOW IT IS BOUNDED. One generation per capture, named by UTC timestamp so lexical order IS
# chronological (no ls -t, no mtime dependence). HOOK_BACKUP_RETAIN generations are kept and
# older ones pruned. Pruning runs AFTER the new generation is written and verified, never
# before -- pruning first would open a window in which a crash leaves fewer generations than
# the policy promises. Only directories matching the generation-name pattern are considered,
# so the store is never blind-rm'd. Steady-state bound: HOOK_BACKUP_RETAIN x one bundle.
readonly HOOK_BACKUP_DIRNAME="hook-bundle-backups"
readonly HOOK_BACKUP_RETAIN=5
readonly HOOK_BACKUP_MANIFEST_NAME="MANIFEST.tsv"

hook_backup_root() { printf '%s/%s\n' "${CONFIG_ROOT}" "${HOOK_BACKUP_DIRNAME}"; }

# hook_backup_latest_gen -- newest generation directory name, or empty if the store has none.
# Lexical sort on a UTC-timestamp name; `sort` is deliberately plain (a numeric sort would
# silently mis-order these names, and a wrong set difference is the failure mode).
hook_backup_latest_gen() {
  local root; root="$(hook_backup_root)"
  [ -d "${root}" ] || return 0
  ls -1 "${root}" 2>/dev/null \
    | grep -E '^[0-9]{8}T[0-9]{6}Z-[0-9]+$' \
    | sort \
    | tail -n 1
}

# capture_durable_hook_snapshot -- copy the ENTIRE deployed hook bundle aside, before the
# first byte of a refresh is written, into a generation that outlives this process.
#
# Hard-fails rather than warning. The posture is record_write_rollback's: a backup that cannot
# be taken is a hard failure, because proceeding performs an irreversible write on the one
# deploy surface `git revert` cannot restore.
capture_durable_hook_snapshot() {
  local src="${WORKSPACE_ROOT}/.claude/hooks"
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would capture a durable hook-bundle snapshot under $(hook_backup_root)/"
    return 0
  fi
  if [ ! -d "${src}" ]; then
    err "Durable snapshot: no deployed hook bundle at ${src}"
    exit 74
  fi

  # A symlink cannot be faithfully manifested-and-restored by this format, and a member of
  # the bundle that the restore would not put back is worse than no snapshot: the restore
  # would report N/N while silently dropping it, and its extras pass would then delete the
  # copy. Refuse to take a backup that cannot be honestly restored.
  local link_count
  link_count=$(find "${src}" -type l 2>/dev/null | wc -l | tr -d ' ')
  if [ "${link_count}" != "0" ]; then
    err "Durable snapshot: ${link_count} symlink(s) under ${src}"
    err "  This manifest format restores regular files only, so a snapshot taken here could"
    err "  not be honestly restored. Refusing to record a backup that cannot be replayed."
    exit 74
  fi

  # ATOMIC PUBLISH. The generation is assembled under a `.partial` name and renamed into
  # place only once its manifest and meta are written. This is not decoration: measured
  # (#5662) by SIGKILLing a capture, a directory-first scheme leaves a generation directory
  # that EXISTS but carries no manifest -- and hook_backup_latest_gen would then select that
  # empty shell as the newest generation, so the one interruption shape this substrate exists
  # to survive would hand the restore an empty snapshot. `.partial` does not match the
  # generation-name pattern, so a killed capture is invisible to both the selector and the
  # pruner, and `mv` within one directory is atomic.
  local root gen gen_dir staging
  root="$(hook_backup_root)"
  gen="$(date -u +%Y%m%dT%H%M%SZ)-$$"
  gen_dir="${root}/${gen}"
  staging="${root}/${gen}.partial"
  rm -rf "${staging}" 2>/dev/null || true
  mkdir -p "${staging}/bundle" || { err "mkdir failed: ${staging}/bundle"; exit 73; }

  # `src/.` copies dotfiles too -- .mode above all, which is operator state the refresh
  # preserves and a rollback must therefore put back exactly as it was found.
  cp -R "${src}/." "${staging}/bundle/" || { err "durable snapshot copy failed to ${staging}/bundle"; exit 74; }

  # MANIFEST.tsv -- sha256 <TAB> octal-mode <TAB> path-relative-to-bundle.
  # NOTE: this is deliberately NOT a `shasum -c` checkfile. `shasum -c` expects two fields and
  # misparses a three-field line into a wall of FAILED that is pure parse error, not drift.
  # Verification recomputes in the reader below; do not point `shasum -c` at this file.
  local n_files
  n_files=$(python3 - "${staging}/bundle" "${staging}/${HOOK_BACKUP_MANIFEST_NAME}" <<'PY'
import hashlib, os, sys
root, out = sys.argv[1], sys.argv[2]
rows = []
for dirpath, dirnames, filenames in os.walk(root):
    dirnames.sort()
    for fn in sorted(filenames):
        p = os.path.join(dirpath, fn)
        if os.path.islink(p) or not os.path.isfile(p):
            continue
        with open(p, "rb") as fh:
            h = hashlib.sha256(fh.read()).hexdigest()
        mode = "%03o" % (os.stat(p).st_mode & 0o777)
        rows.append((h, mode, os.path.relpath(p, root)))
with open(out, "w") as f:
    for h, mode, rel in rows:
        f.write("%s\t%s\t%s\n" % (h, mode, rel))
print(len(rows))
PY
  ) || { err "durable snapshot manifest failed for ${staging}"; exit 74; }

  # ASSERT THE INSTRUMENT RAN before reporting a green capture. A healthy bundle is never
  # empty, so zero rows never means "nothing to back up" -- it means the walk measured nothing
  # and this snapshot is a recorded lie that a later restore would replay as success.
  if [ -z "${n_files}" ] || [ "${n_files}" -eq 0 ] 2>/dev/null; then
    err "Durable snapshot: manifested ZERO files from ${src}"
    err "  A healthy hook bundle always contains entrypoints, so this is a FAILED PROBE, not"
    err "  an empty bundle. Refusing to record a snapshot that cannot restore anything."
    rm -rf "${staging}" 2>/dev/null || true
    exit 74
  fi

  {
    printf 'generation\t%s\n' "${gen}"
    printf 'captured_utc\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'workspace_root\t%s\n' "${WORKSPACE_ROOT}"
    printf 'source_repo\t%s\n' "${SOURCE_REPO}"
    printf 'install_mode\t%s\n' "${INSTALL_MODE:-unknown}"
    printf 'file_count\t%s\n' "${n_files}"
  } > "${staging}/meta.tsv" || { err "durable snapshot meta write failed"; exit 74; }

  # PUBLISH. Until this rename lands, nothing selects or prunes this generation.
  mv "${staging}" "${gen_dir}" || { err "durable snapshot publish failed: ${staging}"; exit 74; }

  info "DURABLE SNAPSHOT: ${n_files} file(s) -> $(hook_backup_root)/${gen}/"
  prune_durable_hook_snapshots
}

# prune_durable_hook_snapshots -- retention. Runs only AFTER a verified capture.
prune_durable_hook_snapshots() {
  local root; root="$(hook_backup_root)"
  [ -d "${root}" ] || return 0

  # Sweep ABANDONED staging dirs. A capture killed before its publishing rename leaves a
  # `.partial` behind; those are invisible to the generation selector by design, which means
  # nothing else would ever reclaim them and the store would grow without bound in exactly
  # the interruption case this substrate is for. The 60-minute floor cannot race a live
  # capture (a capture writes a few hundred KB and completes in well under a second).
  find "${root}" -maxdepth 1 -type d -name '*.partial' -mmin +60 -exec rm -rf {} + 2>/dev/null || true

  local gens total drop victim
  gens=$(ls -1 "${root}" 2>/dev/null | grep -E '^[0-9]{8}T[0-9]{6}Z-[0-9]+$' | sort) || true
  [ -n "${gens}" ] || return 0
  total=$(printf '%s\n' "${gens}" | wc -l | tr -d ' ')
  if [ "${total}" -le "${HOOK_BACKUP_RETAIN}" ]; then
    return 0
  fi
  drop=$((total - HOOK_BACKUP_RETAIN))
  # Oldest-first, and only names that matched the generation pattern above -- the store is
  # never blind-rm'd, and anything an operator parked here by hand is left untouched.
  for victim in $(head -n "${drop}" <<<"${gens}"); do
    rm -rf "${root:?}/${victim}" 2>/dev/null \
      && info "PRUNED durable snapshot (retention ${HOOK_BACKUP_RETAIN}): ${victim}" \
      || warn "could not prune durable snapshot ${victim}"
  done
}

# --- Section 15: Hook install with checksum drift detection ---
install_hook_with_checksum() {
  local source_hook="$1"
  local basename target source_sha
  basename=$(basename "${source_hook}")
  target="${WORKSPACE_ROOT}/.claude/hooks/${basename}"
  source_sha=$(shasum -a 256 "${source_hook}" | awk '{print $1}')

  if [ ! -e "${target}" ]; then
    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] would install: ${basename}"
      return 0
    fi
    cp "${source_hook}" "${target}"
    chmod +x "${target}"
    json_set "${CHECKSUMS_FILE}" "${basename}" "${source_sha}"
    info "INSTALLED: ${basename}"
    printf 'rm-file:%s\n' "${target}" >> "${ROLLBACK_OPS_FILE}"
    return 0
  fi

  local target_sha
  target_sha=$(shasum -a 256 "${target}" | awk '{print $1}')
  if [ "${source_sha}" = "${target_sha}" ]; then
    # Content matches — which is NOT the same as the install being correct. The
    # checksum above is a CONTENT sha; a hook stripped of its executable bit is
    # byte-identical to a healthy one and does not run. A hook that does not run
    # enforces nothing and says nothing, so the drift is invisible by construction.
    #
    # Every other branch of this function copies and then chmods. This branch
    # copies nothing, so before this repair it was the ONE path that could observe
    # a deployed hook and leave it non-executable — mode-only drift was repaired by
    # no code path anywhere in the installer, and `update.sh` then reported success
    # over it. Repairing here (rather than in update.sh) keeps hook deployment in
    # the one function that owns it; update.sh asserts the invariant, it does not
    # re-implement the fix.
    #
    # This is the entrypoint population by construction: install_hooks iterates
    # ${SOURCE_REPO}/core/hooks/*.sh, which holds entrypoints only. The sourced
    # primitives (path-leak-patterns.sh, lib-instance-path.sh, lib/dep-resolve.sh)
    # are co-deployed further down by plain `cp` and correctly stay 644 — they are
    # read with `. "$LIB"` under an `[ -r ]` guard and never invoked.
    if [ ! -x "${target}" ]; then
      if [ "${DRY_RUN}" -eq 1 ]; then
        info "[dry-run] would restore +x: ${basename} (content unchanged; executable bit missing)"
      else
        chmod +x "${target}"
        info "MODE-REPAIRED: ${basename} (content unchanged; +x restored)"
      fi
    fi
    json_set "${CHECKSUMS_FILE}" "${basename}" "${source_sha}"
    info "SYNC: ${basename} (unchanged)"
    return 0
  fi

  # --- Refresh-hooks mode (#3430): non-interactive, checksum-aware drift handling.
  # A deployed hook that still matches its recorded baseline (or has no baseline) is an
  # UNEDITED platform copy → overwrite to APPLY the update, so a hook security fix actually
  # reaches an already-installed workspace through update.sh (the whole point of #3430). A
  # hook that DIVERGED from its baseline was operator-edited → preserve + warn (never
  # silently clobber). Confined to refresh mode; the interactive prompt path below (used by
  # the fresh / rebootstrap flows) is unchanged, so a full re-run keeps its exact semantics.
  if [ "${REFRESH_HOOKS}" -eq 1 ]; then
    local recorded_sha
    recorded_sha=$(json_get "${CHECKSUMS_FILE}" "${basename}")
    if [ -z "${recorded_sha}" ] || [ "${recorded_sha}" = "${target_sha}" ]; then
      if [ "${DRY_RUN}" -eq 1 ]; then
        info "[dry-run] would REFRESH: ${basename} (${target_sha:0:8} → ${source_sha:0:8})"
        return 0
      fi
      # Pre-write backup + rollback op. The FIRST-INSTALL branch above has recorded an
      # `rm-file` op since it was written; this branch — the only one that reaches an
      # already-installed workspace, and the whole point of --refresh-hooks — recorded
      # nothing and kept no copy. `git revert` restores the repository; it does not
      # restore .claude/hooks/, so without this the prior deployed bytes were simply
      # gone and a partial refresh had no way back.
      record_write_rollback "${target}"
      cp "${source_hook}" "${target}"
      chmod +x "${target}"
      json_set "${CHECKSUMS_FILE}" "${basename}" "${source_sha}"
      info "REFRESHED: ${basename} (${target_sha:0:8} → ${source_sha:0:8})"
      return 0
    fi
    warn "PRESERVED (operator-edited): ${basename} diverged from its recorded baseline; not overwritten. Re-run docs/scripts/setup-workspace.sh to reconcile."
    json_set "${CHECKSUMS_FILE}" "${basename}" "${target_sha}"
    return 0
  fi

  # Drift — check cached decision first (FM-2 absorption)
  local cached_sha cached_action
  cached_sha=$(json_get_obj_field "${DRIFT_DECISIONS_FILE}" "${basename}" "source_sha_seen")
  cached_action=$(json_get_obj_field "${DRIFT_DECISIONS_FILE}" "${basename}" "operator_decision")
  if [ -n "${cached_sha}" ] && [ "${cached_sha}" = "${source_sha}" ]; then
    case "${cached_action}" in
      skip)
        info "SKIPPED (cached): ${basename}"
        json_set "${CHECKSUMS_FILE}" "${basename}" "${target_sha}"
        return 0
        ;;
      overwrite)
        cp "${source_hook}" "${target}"
        chmod +x "${target}"
        json_set "${CHECKSUMS_FILE}" "${basename}" "${source_sha}"
        info "OVERWROTE (cached): ${basename}"
        return 0
        ;;
    esac
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] DRIFT: ${basename} (source ${source_sha} ≠ target ${target_sha})"
    return 0
  fi

  # Interactive prompt
  warn "DRIFT: ${basename}"
  warn "  Source SHA: ${source_sha}"
  warn "  Target SHA: ${target_sha}"
  local response=""
  while true; do
    printf '  Overwrite? (y/N/diff): ' >&2
    if ! read -r response; then
      response="N"
    fi
    case "${response}" in
      y|Y)
        cp "${source_hook}" "${target}"
        chmod +x "${target}"
        json_set "${CHECKSUMS_FILE}" "${basename}" "${source_sha}"
        json_set_obj "${DRIFT_DECISIONS_FILE}" "${basename}" \
          "operator_decision" "overwrite" "source_sha_seen" "${source_sha}"
        info "OVERWROTE: ${basename}"
        return 0
        ;;
      n|N|"")
        json_set "${CHECKSUMS_FILE}" "${basename}" "${target_sha}"
        json_set_obj "${DRIFT_DECISIONS_FILE}" "${basename}" \
          "operator_decision" "skip" "source_sha_seen" "${source_sha}"
        info "SKIPPED: ${basename} (operator declined overwrite)"
        return 0
        ;;
      diff|d|D)
        diff -u "${target}" "${source_hook}" || true
        ;;
      *)
        warn "Please answer y, N, or diff."
        ;;
    esac
  done
}

install_mode_template_if_missing() {
  local template_name="$1"
  local mode_name="$2"
  local source="${SOURCE_REPO}/core/hooks/${template_name}"
  local target="${WORKSPACE_ROOT}/.claude/hooks/${mode_name}"
  if [ ! -f "${source}" ]; then
    return 0
  fi
  if [ -e "${target}" ]; then
    info "PRESERVED (operator-state): ${mode_name}"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would install mode template: ${mode_name}"
    return 0
  fi
  cp "${source}" "${target}"
  info "INSTALLED mode default: ${mode_name}"
  printf 'rm-file:%s\n' "${target}" >> "${ROLLBACK_OPS_FILE}"
}

install_hooks() {
  if [ "${DRY_RUN}" -eq 0 ]; then
    if ! mkdir -p "${WORKSPACE_ROOT}/.claude/hooks"; then
      err "mkdir failed: ${WORKSPACE_ROOT}/.claude/hooks"
      exit 73
    fi
  fi

  # PR-1 + PR-3 + FM-6 absorption: data-driven; `*.sh` only; tests/ excluded.
  local source_hook installed_count=0
  for source_hook in "${SOURCE_REPO}/core/hooks/"*.sh; do
    [ -f "${source_hook}" ] || continue
    install_hook_with_checksum "${source_hook}"
    installed_count=$((installed_count + 1))
  done

  if [ "${installed_count}" -lt "${EXPECTED_HOOK_COUNT_MIN}" ] && [ "${DRY_RUN}" -eq 0 ]; then
    warn "Only ${installed_count} hooks installed (expected ≥ ${EXPECTED_HOOK_COUNT_MIN})"
  fi
  info "Hook install pass complete (${installed_count} hooks processed)"

  # Co-deploy the shared path-leak primitive NEXT TO the hooks. block-gh-path-leak.sh
  # (#1137) sources it from ${HOOK_DIR}/path-leak-patterns.sh at runtime; the source
  # primitive lives at core/deploy/tools/ (shared with deploy.sh Check 43), which the
  # deployed .claude/hooks/ cannot reach — so without this copy the deployed hook
  # fail-opens. It is a sourced lib, not a registered hook (no block-* name), so the
  # hook-registry checks correctly ignore it. (#1850)
  local primitive_src="${SOURCE_REPO}/core/deploy/tools/path-leak-patterns.sh"
  local primitive_dst="${WORKSPACE_ROOT}/.claude/hooks/path-leak-patterns.sh"
  if [ ! -r "${primitive_src}" ]; then
    warn "path-leak primitive not found at ${primitive_src}; block-gh-path-leak will fail-open"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy path-leak primitive → ${primitive_dst}"
  else
    record_write_rollback "${primitive_dst}"
    cp "${primitive_src}" "${primitive_dst}"
    info "INSTALLED: path-leak primitive (block-gh-path-leak dependency)"
  fi

  # Co-deploy the shared operator-instance / needle resolver NEXT TO the hooks.
  # block-scope-segregation.sh (#384) sources it from ${HOOK_DIR}/lib-instance-path.sh
  # at runtime to resolve the gitignored localized-context needle file (its CD-4
  # coworker/org/client-project needle scan); the source lib lives at core/deploy/
  # (shared with deploy.sh + git-pre-commit-pii.sh), which the deployed .claude/hooks/
  # cannot reach — so without this copy the hook's localized-needle class silently
  # no-ops. It is a sourced lib, not a registered hook (no block-* name), so the
  # hook-registry checks correctly ignore it. Mirrors the path-leak primitive co-deploy.
  local needlelib_src="${SOURCE_REPO}/core/deploy/lib-instance-path.sh"
  local needlelib_dst="${WORKSPACE_ROOT}/.claude/hooks/lib-instance-path.sh"
  if [ ! -r "${needlelib_src}" ]; then
    warn "lib-instance-path.sh not found at ${needlelib_src}; block-scope-segregation localized-needle scan will no-op"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy lib-instance-path.sh → ${needlelib_dst}"
  else
    record_write_rollback "${needlelib_dst}"
    cp "${needlelib_src}" "${needlelib_dst}"
    info "INSTALLED: lib-instance-path.sh (block-scope-segregation needle resolver)"
  fi

  # Co-deploy the shared jq/dependency resolver into .claude/hooks/lib/. Every security
  # hook sources it from ${HOOK_DIR}/lib/dep-resolve.sh at runtime (GHSA-9cjm-v22x-4x33)
  # and fails CLOSED without it — so a missing copy would make the deployed hooks block
  # every tool call (and verify_hooks_invokable would roll back this install). HARD
  # dependency; mirrors the source layout core/hooks/lib/.
  local depresolve_src="${SOURCE_REPO}/core/hooks/lib/dep-resolve.sh"
  local depresolve_dst="${WORKSPACE_ROOT}/.claude/hooks/lib/dep-resolve.sh"
  if [ ! -r "${depresolve_src}" ]; then
    warn "dep-resolve.sh not found at ${depresolve_src}; deployed hooks will fail CLOSED"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy dep-resolve.sh → ${depresolve_dst}"
  else
    mkdir -p "${WORKSPACE_ROOT}/.claude/hooks/lib"
    record_write_rollback "${depresolve_dst}"
    cp "${depresolve_src}" "${depresolve_dst}"
    info "INSTALLED: dep-resolve.sh (shared hook jq/dependency resolver)"
  fi

  # Co-deploy the shared positional-issue-ref classifier into .claude/hooks/lib/.
  # block-fragile-refs.sh sources it from ${HOOK_DIR}/lib/positional-issueref.awk at
  # runtime; the source lib lives at core/hooks/lib/ (shared with the fixture-runner and
  # the reference-durability CI), which the deployed .claude/hooks/ cannot reach. Without
  # this copy the deployed hook cannot run its positional detector (BLOCK-FRAGILE-REF-003)
  # and — post GHSA-g9g6-28c9-vrx5 — fails CLOSED in enforce (or degrades in warn). It is
  # a sourced lib, not a registered hook (no block-* name), so hook-registry checks ignore
  # it. HARD dependency; mirrors the dep-resolve.sh co-deploy above.
  local posawk_src="${SOURCE_REPO}/core/hooks/lib/positional-issueref.awk"
  local posawk_dst="${WORKSPACE_ROOT}/.claude/hooks/lib/positional-issueref.awk"
  if [ ! -r "${posawk_src}" ]; then
    warn "positional-issueref.awk not found at ${posawk_src}; block-fragile-refs positional detector will fail closed in enforce"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy positional-issueref.awk → ${posawk_dst}"
  else
    mkdir -p "${WORKSPACE_ROOT}/.claude/hooks/lib"
    record_write_rollback "${posawk_dst}"
    cp "${posawk_src}" "${posawk_dst}"
    info "INSTALLED: positional-issueref.awk (block-fragile-refs positional classifier)"
  fi

  # Co-deploy the shared command-position canonicalizer into .claude/hooks/lib/.
  # All FOUR anchor-carrying hooks (block-destructive, block-egress, block-fs-boundary,
  # block-rm-prefer-trash) read it from ${HOOK_DIR}/lib/command-position.awk at runtime to
  # decide where a command actually starts; without it their matchers see only start-of-line
  # and `;`/`&`/`|` positions, which is the blind spot this file exists to close. Each hook
  # canaries it and — post GHSA-g9g6-28c9-vrx5 posture — fails CLOSED in enforce (the
  # mode-gated pair degrade to the raw command in warn). HARD dependency; mirrors the
  # positional-issueref.awk co-deploy above. Sourced lib, not a registered hook (no block-*
  # name), so hook-registry checks ignore it.
  local cmdposawk_src="${SOURCE_REPO}/core/hooks/lib/command-position.awk"
  local cmdposawk_dst="${WORKSPACE_ROOT}/.claude/hooks/lib/command-position.awk"
  # ABORT, do not warn-and-continue. Every other co-deploy above warns and proceeds, and
  # for a soft dependency that is right — the workspace degrades but keeps working. This
  # one is different in kind: the four hooks are copied into place BEFORE this point in
  # the same function, so a warn-and-continue here does not degrade the workspace, it
  # CREATES the fail-closed state. Measured: 412 of 871 assertions flip to deny and none
  # to allow, and the two unconditional deniers ignore the .mode escape hatch entirely, so
  # "flip to warn" recovers only half the bundle. A partial hook state without this file
  # is the failure mode, so the install refuses to create it and lets the EXIT trap put
  # the pre-write bundle back.
  #
  # Exit 74 (EX_IOERR) is deliberate: it is NOT one of the no-mutation codes cleanup()
  # skips rollback for (64/66/69/78), so the trap runs and the restore-file ops recorded
  # above are replayed.
  if [ ! -r "${cmdposawk_src}" ]; then
    err "command-position.awk not readable at ${cmdposawk_src}"
    err "  All four anchor-carrying hooks (block-destructive, block-egress, block-fs-boundary,"
    err "  block-rm-prefer-trash) read this file at startup and FAIL CLOSED without it."
    err "  Refusing to leave the hook bundle in that state; rolling back."
    exit 74
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy command-position.awk → ${cmdposawk_dst}"
  else
    mkdir -p "${WORKSPACE_ROOT}/.claude/hooks/lib"
    record_write_rollback "${cmdposawk_dst}"
    cp "${cmdposawk_src}" "${cmdposawk_dst}"
    info "INSTALLED: command-position.awk (shared command-start canonicalizer, 4 hooks)"
  fi

  # Co-deploy the reference-durability detector constants into .claude/hooks/lib/.
  # block-fragile-refs.sh sources it from ${HOOK_DIR}/lib/fragile-ref-patterns.sh at runtime
  # to obtain EVERY detector pattern it evaluates; the source lib lives at core/hooks/lib/
  # (shared with the fixture-runner and the reference-durability CI), which the deployed
  # .claude/hooks/ cannot reach. Without this copy the hook has no patterns at all — and an
  # unset pattern is an EMPTY ERE that matches every line, so a missing copy would INVERT the
  # detector rather than disable it. The hook therefore fails CLOSED in enforce (blocking every
  # durable-corpus write) and stands down entirely in warn/off. Sourced lib, not a registered
  # hook (no block-* name), so hook-registry checks ignore it. HARD dependency; mirrors the
  # positional-issueref.awk co-deploy above.
  local patternslib_src="${SOURCE_REPO}/core/hooks/lib/fragile-ref-patterns.sh"
  local patternslib_dst="${WORKSPACE_ROOT}/.claude/hooks/lib/fragile-ref-patterns.sh"
  if [ ! -r "${patternslib_src}" ]; then
    warn "fragile-ref-patterns.sh not found at ${patternslib_src}; block-fragile-refs will fail CLOSED in enforce (all detectors unavailable)"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy fragile-ref-patterns.sh → ${patternslib_dst}"
  else
    mkdir -p "${WORKSPACE_ROOT}/.claude/hooks/lib"
    record_write_rollback "${patternslib_dst}"
    cp "${patternslib_src}" "${patternslib_dst}"
    info "INSTALLED: fragile-ref-patterns.sh (block-fragile-refs detector constants)"
  fi

  # Co-deploy the master-activation gate lib into .claude/hooks/lib/. Every block-* hook
  # sources it from ${HOOK_DIR}/lib/master-enable.sh at runtime (#310) to resolve the
  # durable opt-in master-enable state (default OFF). A MISSING copy is
  # fail-toward-current-behavior — the hook keeps its existing .mode enforcement, never
  # silently disabled — so this is a SOFT dependency (unlike the HARD dep-resolve.sh);
  # but without it the opt-in default-OFF cannot take effect. Sourced lib, not a registered
  # hook (no block-* name) → the hook-registry checks correctly ignore it. Mirrors the
  # dep-resolve.sh co-deploy above; reached by every flow (fresh / rebootstrap / the
  # refresh-hooks path update.sh delegates to), so a hook update keeps this lib fresh too.
  local masterlib_src="${SOURCE_REPO}/core/hooks/lib/master-enable.sh"
  local masterlib_dst="${WORKSPACE_ROOT}/.claude/hooks/lib/master-enable.sh"
  if [ ! -r "${masterlib_src}" ]; then
    warn "master-enable.sh not found at ${masterlib_src}; block-* master-activation gate will fail-toward-current-behavior (hooks keep enforcing)"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy master-enable.sh → ${masterlib_dst}"
  else
    mkdir -p "${WORKSPACE_ROOT}/.claude/hooks/lib"
    record_write_rollback "${masterlib_dst}"
    cp "${masterlib_src}" "${masterlib_dst}"
    info "INSTALLED: master-enable.sh (block-* master-activation gate)"
  fi

  # Co-deploy the workspace-scope gate lib into .claude/hooks/lib/. Every block-* PreToolUse
  # hook sources it from ${HOOK_DIR}/lib/scope-guard.sh at runtime (#4436) as precedence
  # layer 3, so a hook is inert for a tool call whose working directory is outside the
  # governed workspace root. A MISSING copy is fail-toward-current-behavior on the LIB axis —
  # the hook keeps enforcing rather than going silent — so this is a SOFT dependency, exactly
  # like master-enable.sh; but without it the re-homed PreToolUse wiring is unbounded and
  # hooks fire in unrelated repositories. Sourced lib, not a registered hook (no block-*
  # name) → the hook-registry checks correctly ignore it. Reached by every flow (fresh /
  # rebootstrap / the refresh-hooks path update.sh delegates to).
  local scopelib_src="${SOURCE_REPO}/core/hooks/lib/scope-guard.sh"
  local scopelib_dst="${WORKSPACE_ROOT}/.claude/hooks/lib/scope-guard.sh"
  if [ ! -r "${scopelib_src}" ]; then
    warn "scope-guard.sh not found at ${scopelib_src}; block-* hooks will be UNBOUNDED (they enforce in every session that loads the wiring)"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would co-deploy scope-guard.sh → ${scopelib_dst}"
  else
    mkdir -p "${WORKSPACE_ROOT}/.claude/hooks/lib"
    record_write_rollback "${scopelib_dst}"
    cp "${scopelib_src}" "${scopelib_dst}"
    info "INSTALLED: scope-guard.sh (block-* workspace-scope gate)"
  fi

  # Surface the enforcement point rather than performing it (#4436). The hooks installed
  # above are loaded ONLY by sessions whose project root resolves to the workspace root —
  # a session rooted in the repo or a worktree resolves no settings file with a hooks key
  # and therefore loads no hooks at all, which is why the script allowlist has never
  # governed the spawned-session path. Re-homing the PreToolUse wiring to user scope
  # closes that, but it writes outside the workspace root and must be ordered after
  # script-allowlist reconciliation, so it is a separate, explicit operator act.
  info "NOTE: hooks installed above load only for sessions rooted under ${WORKSPACE_ROOT}."
  info "      Repo- and worktree-rooted sessions (and the subagents they spawn) load NONE."
  info "      To extend coverage to them, after reconciling the script allowlist run:"
  info "        bash ${SOURCE_REPO}/docs/scripts/setup-workspace.sh --rehome-hook-wiring"

  install_mode_template_if_missing ".mode.template" ".mode"
  install_mode_template_if_missing "deploy-check.mode.template" "deploy-check.mode"
  # block-gh-path-leak.sh reads its OWN mode file, not the shared .mode, so that its
  # posture can be promoted without silently promoting the shared cohort. The template
  # matches the hook's in-script default; the in-script default is the operative posture,
  # since a template that is never installed carries no posture at all.
  install_mode_template_if_missing ".gh-path-leak-mode.template" ".gh-path-leak-mode"
  # block-autonomy-ceiling.sh likewise reads its own .autonomy-mode. Its template was
  # tracked but had no install call site, so a fresh install never received it and the
  # hook fell through to its in-script `enforce` default -- contradicting the WARN-MODE-
  # INITIAL posture its own header declares. That gap became load-bearing in this release:
  # mode-coupling the dependency guard makes this hook newly trip on a stale helper, so
  # without the install the version-skew over-block does not clear, it relocates here
  # (Stage 7 F-01, measured before/after). Installing the template is the whole fix.
  # `.verify-session-config-mode` has the same missing-call-site defect and is deliberately
  # NOT fixed here -- it is not on this release's path and stays with #5073, which also
  # carries the durable remedy: an assertion that every tracked mode template has a call site.
  install_mode_template_if_missing ".autonomy-mode.template" ".autonomy-mode"

  # Ship a .version snapshot alongside the deployed hooks so notify-version-
  # skew.sh resolves "the version deployed into this workspace" via its sibling
  # (<ws>/.claude/.version) without guessing the source-clone path. The clone's
  # .version is the source of truth; update.sh refreshes this snapshot on
  # update. Advisory only — a missing source .version warns but never fails.
  local version_src="${SOURCE_REPO}/.version"
  local version_dst="${WORKSPACE_ROOT}/.claude/.version"
  if [ ! -r "${version_src}" ]; then
    warn ".version not found at ${version_src}; version-skew hook will stay inert"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would install .version snapshot → ${version_dst}"
  else
    cp "${version_src}" "${version_dst}"
    info "INSTALLED: .version snapshot ($(head -1 "${version_dst}" | tr -d '[:space:]'))"
    printf 'rm-file:%s\n' "${version_dst}" >> "${ROLLBACK_OPS_FILE}"
  fi

  json_set_bool "${ARTIFACTS_FILE}" "hooks_installed" "true"
}

# --- Section 15b: Security-hook master-activation opt-in (#310) ---
# Install-time opt-in for the core/hooks/block-* PreToolUse hook layer. DEFAULT OFF: a fresh
# public clone imposes no WORKFLOW guards until the operator opts in. The choice is written
# to the durable XDG platform-config.toml [security_hooks].master_enabled — an
# Operator-instance surface update.sh never overwrites, so it survives version upgrades
# (AC-3). Per D-R9 the security/floor-class hooks (credential-read, egress, PII-leak,
# destructive-git, rm-guard, scope-segregation, shell-injection) ALWAYS enforce regardless
# of this toggle; it governs the workflow-class hooks only. Idempotent: an already-set value
# is PRESERVED (never re-prompted or clobbered), so a rebootstrap cannot reset a prior opt-in.
configure_hook_activation() {
  local cfg="${CONFIG_ROOT}/platform-config.toml"

  # Already configured? Preserve the operator's durable choice (AC-3) — never re-prompt or
  # clobber. master_enabled is a unique key across the schema, so a flat grep is sufficient.
  if [ -f "${cfg}" ] && grep -qE '^[[:space:]]*master_enabled[[:space:]]*=' "${cfg}" 2>/dev/null; then
    local cur
    cur="$(grep -m1 -E '^[[:space:]]*master_enabled[[:space:]]*=' "${cfg}" | sed -E 's/.*=[[:space:]]*//; s/[[:space:]]*#.*//; s/[[:space:]]*$//')"
    info "PRESERVED (operator-state): [security_hooks].master_enabled = ${cur} (hook activation unchanged)"
    return 0
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would prompt for: workflow security-hook activation (default OFF), then write [security_hooks].master_enabled to ${cfg}"
    return 0
  fi

  # Prompt — default OFF. Non-interactive / EOF → OFF (the public-safe default).
  local response=""
  printf '\n' >&2
  printf 'Activate the pmo-platform WORKFLOW security hooks now?\n' >&2
  printf '  The always-enforce security/floor hooks (credential-read, egress, PII-leak,\n' >&2
  printf '  destructive-git, rm-guard, scope-segregation, shell-injection) are ALWAYS active\n' >&2
  printf '  and are NOT affected by this choice. This governs only the opt-in WORKFLOW hooks\n' >&2
  printf '  (draft-files, fragile-refs, fs-boundary, mcp-writes, skill-edit, autonomy-ceiling).\n' >&2
  printf '  Default is OFF; you can flip it anytime in\n' >&2
  printf '  %s ([security_hooks].master_enabled).\n' "${cfg}" >&2
  printf '  Activate workflow hooks now? (y/N): ' >&2
  if ! read -r response; then response="N"; fi

  local value="false"
  case "${response}" in
    y|Y|yes|YES|Yes) value="true" ;;
    *)               value="false" ;;
  esac

  write_security_hooks_config "${cfg}" "${value}"
  info "Hook activation set: [security_hooks].master_enabled = ${value} (${cfg})"
}

# write_security_hooks_config FILE VALUE — set [security_hooks].master_enabled = VALUE in the
# durable XDG platform-config.toml, creating the file + section if absent and preserving any
# other content. bash-3.2 portable; no TOML library (the field is a flat scalar).
write_security_hooks_config() {
  local cfg="$1" value="$2"
  local dir
  dir="$(dirname "${cfg}")"
  mkdir -p "${dir}" 2>/dev/null || true
  if [ ! -f "${cfg}" ]; then
    {
      printf '# pmo-platform — platform-config.toml (operator-instance VALUES; XDG individual rung).\n'
      printf '# Written by docs/scripts/setup-workspace.sh; update.sh never overwrites this file\n'
      printf '# (Operator-instance category), so values set here survive version upgrades.\n\n'
      printf '[security_hooks]\n'
      printf 'master_enabled = %s\n' "${value}"
    } > "${cfg}"
    printf 'rm-file:%s\n' "${cfg}" >> "${ROLLBACK_OPS_FILE}"
    return 0
  fi
  if grep -qE '^[[:space:]]*\[security_hooks\][[:space:]]*$' "${cfg}" 2>/dev/null; then
    # Section present, master_enabled absent (guaranteed by the caller's early-return) —
    # insert the key immediately after the section header.
    local tmp
    tmp="$(mktemp)"
    awk -v val="${value}" '
      { print }
      /^[[:space:]]*\[security_hooks\][[:space:]]*$/ && !ins { print "master_enabled = " val; ins=1 }
    ' "${cfg}" > "${tmp}" && mv "${tmp}" "${cfg}"
  else
    { printf '\n[security_hooks]\nmaster_enabled = %s\n' "${value}"; } >> "${cfg}"
  fi
  return 0
}

# --- Section 15b: Composition-surface file install ---
# Installs files declared in core/deploy/composition-surface-manifest.sh
# with managed-section + operator-extension fences per composition-surface-spec.md §2.
# Install-if-missing semantics: never clobbers a target that already exists
# (operator additions preserved); use ./update.sh to refresh managed sections.
#
# Uses lib-composition.sh helpers: lib_compose_source_manifest to load the
# manifest, lib_compose_parse_entry + lib_compose_resolve_target to compute
# target paths, lib_compose_write to do the marker-fenced write via compose.py.
install_composition_surface_files() {
  if [ "${LIB_COMPOSITION_SOURCED}" -eq 0 ]; then
    local lib="${SOURCE_REPO}/core/deploy/lib-composition.sh"
    if [ ! -f "${lib}" ]; then
      warn "Composition library not found at ${lib}; skipping composition-surface install"
      return 0
    fi
    # shellcheck disable=SC1090
    source "${lib}"
    LIB_COMPOSITION_SOURCED=1
  fi

  # Hard-fail (not warn) on manifest-sourcing failure. A successful install
  # with zero composition-surface files would leave runtime hooks reading
  # empty/default allowlists — a security-relevant silent regression.
  if ! lib_compose_source_manifest "${SOURCE_REPO}"; then
    err "Composition-surface manifest sourcing failed; aborting install"
    err "Re-run with --dry-run to inspect; if the issue persists report it."
    exit 73
  fi
  # Caller-scope assert catches the bash-3.2 `declare -a` regression
  # in the manifest (the lib cannot detect it from its own scope).
  if ! lib_compose_assert_manifest_loaded; then
    err "COMPOSITION_SURFACE_FILES not visible after manifest sourcing"
    err "If the manifest was recently edited, ensure plain assignment (no 'declare -a')"
    exit 73
  fi

  if [ "${DRY_RUN}" -eq 0 ]; then
    mkdir -p "${WORKSPACE_ROOT}/.claude" || { err "mkdir failed: ${WORKSPACE_ROOT}/.claude"; exit 73; }
    mkdir -p "${WORKSPACE_ROOT}/personal/pmo-instance" || { err "mkdir failed: ${WORKSPACE_ROOT}/personal/pmo-instance"; exit 73; }
    # hub-state-tier parent for <OPERATOR_INSTANCE_HUB_STATE_PATH> templates
    # per core/deploy/composition-surface-manifest.sh hub-state tier.
    mkdir -p "${WORKSPACE_ROOT}/personal/pmo-instance/hub-state" || { err "mkdir failed: ${WORKSPACE_ROOT}/personal/pmo-instance/hub-state"; exit 73; }
    # operations-root-tier parent for the operations-workspace context anchor.
    # Resolved, not spelled: the operations leaf lives in lib-instance-path.sh so
    # a relocation re-points one function rather than every caller. The resolver
    # is guaranteed loaded here — lib-composition.sh sources it at its own file
    # scope, and this block is unreachable unless that source succeeded (the
    # early return above).
    local operations_root; operations_root="$(pmo_operations_path_for "${WORKSPACE_ROOT}")"
    mkdir -p "${operations_root}" || { err "mkdir failed: ${operations_root}"; exit 73; }
  fi

  local override_toml="${WORKSPACE_ROOT}/${OPERATOR_LOCAL_TOML_BASENAME}"
  local entry installed_count=0 preserved_count=0
  for entry in "${COMPOSITION_SURFACE_FILES[@]}"; do
    lib_compose_parse_entry "${entry}"
    local src="${LIB_COMPOSE_ENTRY_SRC}"
    local tier="${LIB_COMPOSE_ENTRY_TIER}"
    local tokens_flag="${LIB_COMPOSE_ENTRY_TOKENS_FLAG}"
    local dialect="${LIB_COMPOSE_ENTRY_DIALECT}"

    local source_file="${SOURCE_REPO}/${src}"
    if [ ! -f "${source_file}" ]; then
      warn "Source missing in manifest: ${src}"
      continue
    fi

    local basename; basename="$(basename "${src}")"
    local target
    if ! target=$(lib_compose_resolve_target "${basename}" "${tier}" "${WORKSPACE_ROOT}"); then
      continue
    fi
    # The resolver may strip a suffix (workspace-root tier drops `.template`), so
    # operator-facing messages name the TARGET file, not the source template.
    local target_basename; target_basename="$(basename "${target}")"

    if [ -e "${target}" ]; then
      preserved_count=$((preserved_count + 1))
      info "PRESERVED (operator-state): ${target_basename}"
      continue
    fi

    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] would install: ${target_basename} (tier=${tier}, tokens=${tokens_flag}, dialect=${dialect})"
      installed_count=$((installed_count + 1))
      continue
    fi

    if lib_compose_write "${source_file}" "${target}" "${tokens_flag}" "${OPERATOR_TOML}" "${override_toml}" "" "${dialect}"; then
      installed_count=$((installed_count + 1))
      info "INSTALLED: ${target_basename}"
      printf 'rm-file:%s\n' "${target}" >> "${ROLLBACK_OPS_FILE}"
    else
      err "Install failed: ${target_basename}"
      exit 73
    fi
  done

  if [ "${installed_count}" -lt "${EXPECTED_SEED_FILE_COUNT_MIN}" ] \
     && [ "${preserved_count}" -lt "${EXPECTED_SEED_FILE_COUNT_MIN}" ] \
     && [ "${DRY_RUN}" -eq 0 ]; then
    warn "Only ${installed_count} composition-surface files installed (+${preserved_count} preserved); expected ≥ ${EXPECTED_SEED_FILE_COUNT_MIN}"
  fi
  info "Composition-surface install pass complete (${installed_count} installed, ${preserved_count} preserved)"
}

# --- Section 15c: localized-context needle scaffold (#1830 Part 2) ---
# Create the operator's localized-context-needles.txt from the tracked .example
# ONLY IF it does not already exist (create-once — never clobbers operator data).
# Resolves the target via the single resolver (pmo_localized_needles), keyed on
# the passed WORKSPACE_ROOT so a sandboxed install lands inside the sandbox.
scaffold_localized_needles() {
  local lib="${SOURCE_REPO}/core/deploy/lib-instance-path.sh"
  if [ ! -f "${lib}" ]; then
    warn "Instance-path resolver not found at ${lib}; skipping needle scaffold"
    return 0
  fi
  # shellcheck source=/dev/null
  source "${lib}"
  local example="${SOURCE_REPO}/core/config/localized-context-needles.txt.example"
  if [ ! -f "${example}" ]; then
    warn "Needle template not found at ${example}; skipping needle scaffold"
    return 0
  fi
  # Key the instance base on the passed WORKSPACE_ROOT (honors PMO_INSTANCE_PATH
  # override; falls back to <workspace-root>/<instance-leaf>, not the $HOME default
  # — so a sandboxed --workspace-root is respected).
  local instance_base; instance_base="$(pmo_instance_path_for "${WORKSPACE_ROOT}")"
  local needle_file="${PMO_LOCALIZED_NEEDLES:-${instance_base}/localized-context-needles.txt}"
  if [ -f "${needle_file}" ]; then
    info "PRESERVED (operator-state): localized-context-needles.txt"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would scaffold needle file → ${needle_file}"
    return 0
  fi
  mkdir -p "$(dirname "${needle_file}")" || { err "mkdir failed: $(dirname "${needle_file}")"; exit 73; }
  cp "${example}" "${needle_file}" || { err "needle scaffold copy failed → ${needle_file}"; exit 74; }
  info "INSTALLED needle template: ${needle_file}"
  printf 'rm-file:%s\n' "${needle_file}" >> "${ROLLBACK_OPS_FILE}"
}

# --- Section 15d: people-roster scaffold (#2040) ---
# Create the operator's people-roster.yaml from the tracked de-identified template
# ONLY IF it does not already exist (create-once — NEVER clobbers a filled roster,
# which is operator PII; a clobber is IRREVERSIBLE). This is the PRIMARY seed site
# (the install.sh guard is belt-and-suspenders; update.sh preserves). Mirrors
# scaffold_localized_needles() byte-for-byte, substituting the roster source/target
# and resolving the path via pmo_people_roster_for (keyed on WORKSPACE_ROOT so a
# sandboxed install lands inside the sandbox).
scaffold_localized_roster() {
  local lib="${SOURCE_REPO}/core/deploy/lib-instance-path.sh"
  if [ ! -f "${lib}" ]; then
    warn "Instance-path resolver not found at ${lib}; skipping roster scaffold"
    return 0
  fi
  # shellcheck source=/dev/null
  source "${lib}"
  local template="${SOURCE_REPO}/operations/templates/people-roster-template.yaml"
  if [ ! -f "${template}" ]; then
    warn "Roster template not found at ${template}; skipping roster scaffold"
    return 0
  fi
  # Resolve via the single accessor, keyed on WORKSPACE_ROOT (honors
  # PMO_PEOPLE_ROSTER / PMO_INSTANCE_PATH overrides; falls back to
  # <workspace-root>/personal/pmo-instance/people-roster.yaml — never the $HOME
  # default — so a sandboxed --workspace-root is respected).
  local roster_file; roster_file="$(pmo_people_roster_for "${WORKSPACE_ROOT}")"
  if [ -f "${roster_file}" ]; then
    info "PRESERVED (operator-state): people-roster.yaml"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would scaffold roster → ${roster_file}"
    return 0
  fi
  mkdir -p "$(dirname "${roster_file}")" || { err "mkdir failed: $(dirname "${roster_file}")"; exit 73; }
  cp "${template}" "${roster_file}" || { err "roster scaffold copy failed → ${roster_file}"; exit 74; }
  info "INSTALLED roster template: ${roster_file}"
  printf 'rm-file:%s\n' "${roster_file}" >> "${ROLLBACK_OPS_FILE}"
}

# --- Section 16: Hook behavioral verification (CD-5 absorption) ---
verify_hooks_invokable() {
  local sample_hook="${WORKSPACE_ROOT}/.claude/hooks/block-destructive.sh"
  if [ ! -x "${sample_hook}" ]; then
    err "Hook not executable: ${sample_hook}"
    return 1
  fi
  local benign_payload
  benign_payload=$(printf '{"tool_name":"Bash","tool_input":{"command":"echo hello-from-verify"},"cwd":"%s"}' "${WORKSPACE_ROOT}")
  local exit_code=0
  printf '%s' "${benign_payload}" | "${sample_hook}" >/dev/null 2>&1 || exit_code=$?
  if [ "${exit_code}" -ne 0 ]; then
    err "Hook behavioral test failed: ${sample_hook} exited ${exit_code} on benign input"
    err "Check hook prerequisites (jq, python3) and re-run."
    return 1
  fi
  info "VERIFIED: hook behavioral test passed"
  return 0
}

# --- Section 17: Post-install verification gate (FM-3 absorption) ---
run_verification_gate() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] verification gate skipped (no artifacts to verify)"
    return 0
  fi
  local all_pass=true
  local target

  for target in "${WORKSPACE_ROOT}/CLAUDE.md" "${WORKSPACE_ROOT}/.claude/settings.json"; do
    if [ ! -f "${target}" ]; then
      err "Verification failed: missing ${target}"
      all_pass=false
      continue
    fi
    if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${target}" 2>/dev/null; then
      err "Verification failed: unresolved tokens in ${target}"
      all_pass=false
    fi
  done

  if [ -f "${WORKSPACE_ROOT}/.claude/settings.json" ]; then
    if ! jq -e . "${WORKSPACE_ROOT}/.claude/settings.json" >/dev/null 2>&1; then
      err "Verification failed: settings.json not valid JSON"
      all_pass=false
    fi
  fi

  # Hooks present + executable
  local k
  json_keys "${CHECKSUMS_FILE}" | while IFS= read -r k; do
    [ -z "${k}" ] && continue
    local h="${WORKSPACE_ROOT}/.claude/hooks/${k}"
    if [ ! -x "${h}" ]; then
      err "Verification failed: hook missing or not executable: ${h}"
      printf 'fail\n' > "${SESSION_TMPDIR}/.verification_status"
    fi
  done
  if [ -f "${SESSION_TMPDIR}/.verification_status" ]; then
    all_pass=false
  fi

  # Behavioral test (CD-5)
  if ! verify_hooks_invokable; then
    all_pass=false
  fi

  if [ "${all_pass}" = "true" ]; then
    info "Verification gate: PASS"
    return 0
  else
    err "Verification gate: FAIL"
    return 1
  fi
}

# --- Section 18: State file write (FM-3 + FM-4 absorption) ---
write_state_file() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would write state file: ${STATE_FILE}"
    return 0
  fi
  local verification_passed_value="${1:-true}"

  local source_repo_sha=""
  if [ -d "${SOURCE_REPO}/.git" ]; then
    source_repo_sha=$(git -C "${SOURCE_REPO}" rev-parse HEAD 2>/dev/null || true)
  fi

  S_SCHEMA="${STATE_SCHEMA_VERSION}" \
  S_VERSION="${SCRIPT_VERSION}" \
  S_INSTALL_MODE="${INSTALL_MODE}" \
  S_VERIFICATION_PASSED="${verification_passed_value}" \
  S_SOURCE_REPO="${SOURCE_REPO}" \
  S_SOURCE_SHA="${source_repo_sha}" \
  S_TOKENS_FILE="${TOKENS_FILE}" \
  S_CHECKSUMS_FILE="${CHECKSUMS_FILE}" \
  S_DRIFT_FILE="${DRIFT_DECISIONS_FILE}" \
  S_ARTIFACTS_FILE="${ARTIFACTS_FILE}" \
  S_DIRS_FILE="${DIRS_CREATED_FILE}" \
  S_SETTINGS_TEMPLATE_SHA="${SETTINGS_TEMPLATE_SHA}" \
  S_SETTINGS_INSTALLED_SHA="${SETTINGS_INSTALLED_SHA}" \
  S_OUT="${STATE_FILE}" \
  python3 -c '
import json
import os
from datetime import datetime, timezone

env = os.environ

with open(env["S_TOKENS_FILE"], "r") as f:
    tokens = json.load(f)
with open(env["S_CHECKSUMS_FILE"], "r") as f:
    checksums = json.load(f)
with open(env["S_DRIFT_FILE"], "r") as f:
    drift = json.load(f)
with open(env["S_ARTIFACTS_FILE"], "r") as f:
    artifacts = json.load(f)
try:
    with open(env["S_DIRS_FILE"], "r") as f:
        dirs = [line.rstrip("\n") for line in f if line.strip()]
except FileNotFoundError:
    dirs = []

state = {
    "schema_version": env["S_SCHEMA"],
    "script_version": env["S_VERSION"],
    "setup_completed_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "install_mode": env["S_INSTALL_MODE"],
    "verification_passed": (env["S_VERIFICATION_PASSED"] == "true"),
    "source_repo_path": env["S_SOURCE_REPO"],
    "source_repo_sha": env["S_SOURCE_SHA"],
    "resolved_tokens": tokens,
    "hook_checksums": checksums,
    "hook_drift_decisions": drift,
    "verified_artifacts": artifacts,
    "directory_layout_created": dirs,
    # ADR-121 settings baseline. Flat, snake_case, subject-first, forming a
    # subject-prefixed pair — the convention the existing hook_checksums /
    # hook_drift_decisions and source_repo_path / source_repo_sha pairs already
    # set. settings_template_sha is the regeneration trigger; settings_installed_sha
    # is the tamper anchor (ADR-014 semantics, sidecar carrier).
    "settings_template_sha": env.get("S_SETTINGS_TEMPLATE_SHA", ""),
    "settings_installed_sha": env.get("S_SETTINGS_INSTALLED_SHA", ""),
}

out_path = env["S_OUT"]
os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
with open(out_path, "w") as f:
    json.dump(state, f, indent=2)
    f.write("\n")
' || {
    err "State file write failed: ${STATE_FILE}"
    exit 74
  }

  if [ ! -f "${STATE_FILE}" ]; then
    err "State file write failed: ${STATE_FILE}"
    exit 74
  fi
  info "WROTE state file: ${STATE_FILE}"
}

# Surgical, field-scoped persistence of the two ADR-121 settings baselines.
#
# WHY NOT write_state_file: that function REBUILDS the whole state document from
# the per-run scratch JSON files. A refresh flow populates only three of them
# (tokens / checksums / drift, restored by read_existing_state) — verified_artifacts
# and directory_layout_created are still at their init defaults, and install_mode is
# the refresh mode. Calling it from a refresh flow would therefore overwrite a
# fully-verified artifact record with all-false and blank the recorded directory
# layout. That is why refresh_hooks_flow does not call it either.
#
# The invariant the settings baseline actually needs is "persist the two fields
# after a refresh, or the structural diff becomes the every-run path" — which this
# satisfies exactly, by updating those two keys in place and touching nothing else.
persist_settings_baseline_to_state() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would record settings baselines in ${STATE_FILE}"
    return 0
  fi
  if [ ! -f "${STATE_FILE}" ]; then
    warn "No state file at ${STATE_FILE}; settings baseline not recorded (next run classifies structurally)."
    return 0
  fi
  S_STATE="${STATE_FILE}" \
  S_SETTINGS_TEMPLATE_SHA="${SETTINGS_TEMPLATE_SHA}" \
  S_SETTINGS_INSTALLED_SHA="${SETTINGS_INSTALLED_SHA}" \
  python3 -c '
import json
import os

env = os.environ
path = env["S_STATE"]
with open(path, "r") as f:
    state = json.load(f)

state["settings_template_sha"] = env.get("S_SETTINGS_TEMPLATE_SHA", "")
state["settings_installed_sha"] = env.get("S_SETTINGS_INSTALLED_SHA", "")

with open(path, "w") as f:
    json.dump(state, f, indent=2)
    f.write("\n")
' || {
    warn "Could not record settings baseline in ${STATE_FILE}; next run will classify structurally."
    return 0
  }
  info "Recorded settings baselines in ${STATE_FILE}"
}

# --- Section 19: Re-bootstrap (branch b) — populate maps from existing state ---
read_existing_state() {
  if [ ! -f "${STATE_FILE}" ]; then
    return 0
  fi
  # The three map surfaces are restored to their scratch JSON files as before; the
  # two ADR-121 settings baselines are scalars, so they come back on stdout and are
  # assigned to their globals. An absent field restores to "" — which the guard
  # reads as "no baseline recorded" (S-2, classify before writing), never as
  # "unchanged". That is the correct degradation for a pre-ADR-121 state file.
  local restored
  restored=$(S_STATE="${STATE_FILE}" \
  S_TOKENS_FILE="${TOKENS_FILE}" \
  S_CHECKSUMS_FILE="${CHECKSUMS_FILE}" \
  S_DRIFT_FILE="${DRIFT_DECISIONS_FILE}" \
  python3 -c '
import json
import os

env = os.environ
with open(env["S_STATE"], "r") as f:
    state = json.load(f)

with open(env["S_TOKENS_FILE"], "w") as f:
    json.dump(state.get("resolved_tokens", {}), f, indent=2)
with open(env["S_CHECKSUMS_FILE"], "w") as f:
    json.dump(state.get("hook_checksums", {}), f, indent=2)
with open(env["S_DRIFT_FILE"], "w") as f:
    json.dump(state.get("hook_drift_decisions", {}), f, indent=2)

print(state.get("settings_template_sha", "") or "")
print(state.get("settings_installed_sha", "") or "")
') || return 1
  SETTINGS_TEMPLATE_SHA=$(printf '%s\n' "${restored}" | sed -n '1p')
  SETTINGS_INSTALLED_SHA=$(printf '%s\n' "${restored}" | sed -n '2p')
}

# --- Section 20: Guided recovery (branch c) ---
guided_recovery() {
  warn "State file present but invalid/incomplete: ${STATE_FILE}"
  warn ""
  warn "Options:"
  warn "  (R)epair  — backup state file + re-run fresh-install steps"
  warn "  (B)ackup  — rename state file to .bak.<timestamp> and run fresh-install"
  warn "  (E)xit    — exit without modification"
  warn ""

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would prompt for recovery action; default E (exit) to avoid mutation"
    INSTALL_COMPLETE=1   # mark as 'safe' — no mutation; cleanup will skip rollback
    SUPPRESS_VALIDATE_HINT=1
    return 0
  fi

  local response=""
  while true; do
    printf 'Recovery action (R/B/E): ' >&2
    if ! read -r response; then
      response="E"
    fi
    case "${response}" in
      r|R|b|B)
        local ts; ts=$(date +%Y-%m-%d-%H%M%S)
        local bak="${STATE_FILE}.bak.${ts}"
        mv "${STATE_FILE}" "${bak}"
        info "Backed up state to: ${bak}"
        fresh_install
        return 0
        ;;
      e|E|"")
        info "Exiting without modification."
        INSTALL_COMPLETE=1   # mark as 'safe' — no mutation
        SUPPRESS_VALIDATE_HINT=1
        return 0
        ;;
      *)
        warn "Please answer R, B, or E."
        ;;
    esac
  done
}

# --- Section 21: Fresh-install flow (branch a) ---
fresh_install() {
  INSTALL_MODE="fresh-install"
  info "FRESH-INSTALL flow"
  compute_active_tokens
  create_dir_layout
  resolve_all_tokens
  substitute_templates
  # Both ADR-121 baselines are recorded inside settings_install_or_guarded_rerender,
  # arm-scoped: unconditionally re-recording here would anchor the baseline to a file
  # the platform did NOT write on the guard's no-write arms (S-4 / SKIP-*).
  scaffold_settings_local
  install_hooks
  configure_hook_activation
  install_composition_surface_files
  scaffold_localized_needles
  scaffold_localized_roster
  if run_verification_gate; then
    write_state_file "true"
    INSTALL_COMPLETE=1
  else
    write_state_file "false"
    err "Fresh install completed phases but verification gate FAILED."
    err "State file written with verification_passed=false; re-run to enter guided recovery."
    exit 1
  fi
}

# --- Section 22: Re-bootstrap flow (branch b) ---
rebootstrap() {
  INSTALL_MODE="rebootstrapped"
  info "RE-BOOTSTRAP flow"
  read_existing_state
  compute_active_tokens
  create_dir_layout
  resolve_all_tokens
  # substitute_templates routes the settings.json write through the ADR-121 guard
  # (settings_install_or_guarded_rerender): on this flow a live managed file almost
  # always exists, so the write is a RE-RENDER and is classified — and any
  # operator-added key migrated to the overlay — before anything is overwritten.
  # Baselines are recorded there, arm-scoped to the arms that actually wrote.
  substitute_templates
  scaffold_settings_local
  # Durable pre-write snapshot (#5669), the same guarantee refresh_hooks_flow takes and for
  # the same reason: this flow is where a plain re-run over a HEALTHY workspace lands, so a
  # live bundle almost always exists here and install_hooks is about to overwrite it. Taken
  # BEFORE the first byte, so an untrapped kill inside the hooks-copied / library-absent
  # window stays recoverable after SESSION_TMPDIR is gone. fresh_install deliberately takes
  # no snapshot -- it runs only when there is no existing bundle to capture.
  capture_durable_hook_snapshot
  install_hooks
  configure_hook_activation
  install_composition_surface_files
  scaffold_localized_needles
  scaffold_localized_roster
  if run_verification_gate; then
    write_state_file "true"
    INSTALL_COMPLETE=1
  else
    write_state_file "false"
    err "Re-bootstrap completed phases but verification gate FAILED."
    exit 1
  fi
}

# --- Section 22a2: Hook shared-library closure post-condition ---
# The whole partial-refresh hazard reduces to ONE checkable predicate: every shared library
# a DEPLOYED hook loads at startup is present in the deployed hooks/lib/. A mixed hook state
# — some entrypoints refreshed, some not — is harmless provided that holds, because each hook
# either carries a canary and finds its library, or predates the canary and never looks.
#
# DERIVED, not enumerated. The required set is read out of the deployed hooks themselves:
# `${HOOK_DIR}/lib/<name>` is the single reference form every entrypoint uses. An enumerated
# list is exactly what let command-position.awk ship with no assertion anywhere — the
# co-deploy list, the refresh regression test and the install validator each enumerate per
# named file, so a newly-added primitive is invisible to all three at once. Deriving the set
# from the consumers means a library added in a later release is covered the day its first
# consumer ships, with no list to remember to update.
#
# Called BEFORE INSTALL_COMPLETE=1 so a failure leaves the EXIT trap armed: the refresh is
# rolled back to the pre-write bundle rather than left half-applied.
assert_hook_lib_closure() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] hook-library closure not asserted (nothing was deployed)"
    return 0
  fi
  local hooks_dir="${WORKSPACE_ROOT}/.claude/hooks"
  local required="" missing="" present=0 name
  required=$(grep -ho 'HOOK_DIR}/lib/[A-Za-z0-9._-]*' "${hooks_dir}"/*.sh 2>/dev/null \
             | sed 's|^.*/lib/||' | sort -u) || true

  # Assert the INSTRUMENT ran before reading its result. Every deployed entrypoint
  # references at least lib/dep-resolve.sh, so an empty derived set never means "no
  # dependencies" — it means the scan matched nothing and this check is measuring nothing.
  # Reporting a green post-condition off a silent zero is how the gap it closes shipped.
  if [ -z "${required}" ]; then
    err "Hook-library closure: derived ZERO required libraries from ${hooks_dir}/*.sh"
    err "  A healthy bundle always references lib/dep-resolve.sh, so this is a FAILED PROBE,"
    err "  not a clean result. Refusing to report a post-condition that was never tested."
    exit 74
  fi

  # Names are charset-constrained by the grep pattern above (no whitespace, no glob
  # metacharacters), so word-splitting the derived set is safe and bash 3.2-portable.
  for name in ${required}; do
    if [ -r "${hooks_dir}/lib/${name}" ]; then
      present=$((present + 1))
    else
      missing="${missing} ${name}"
    fi
  done

  if [ -n "${missing}" ]; then
    err "Hook-library closure FAILED — deployed hooks load libraries that are not present:"
    err "  missing:${missing}"
    err "  Each of those is read at hook startup and the reader fails CLOSED without it."
    err "  Refusing to complete the refresh; rolling back to the pre-refresh bundle."
    exit 74
  fi
  info "Hook-library closure: PASS (${present} required librar(y/ies) present under ${hooks_dir}/lib/)"
}

# --- Section 22b: Refresh-hooks flow (#3430) ---
# Re-deploy ONLY the security-hook bundle into an EXISTING workspace: the hook scripts
# (via install_hook_with_checksum in checksum-aware REFRESH mode — unedited platform hooks
# are updated, operator edits preserved), the co-shipped primitives (path-leak-patterns.sh,
# positional-issueref.awk, command-position.awk), lib/dep-resolve.sh, and the .version
# snapshot. It reuses
# install_hooks so the co-deploy list stays single-sourced (the drift trap that hid the
# awk in GHSA-g9g6 does not get a third copy). It does NOT scaffold dirs, resolve tokens,
# substitute templates, or redeploy skills. The hook-tier allowlists are composition-surface
# files refreshed by update.sh's regenerate_managed_sections, not here. This is the path
# update.sh delegates to so a hook/helper security fix reaches an already-installed workspace.
refresh_hooks_flow() {
  INSTALL_MODE="refresh-hooks"
  info "REFRESH-HOOKS flow — re-deploy the security-hook bundle only"
  if [ ! -d "${WORKSPACE_ROOT}/.claude/hooks" ]; then
    err "No deployed hooks at ${WORKSPACE_ROOT}/.claude/hooks — run a full setup-workspace.sh first."
    exit 1
  fi
  # Durable pre-refresh snapshot (#5662). Taken BEFORE the first byte is written, and it
  # outlives this process, so the two shapes SESSION_TMPDIR structurally cannot cover become
  # recoverable: an untrapped kill inside the hooks-copied / library-absent window, and a
  # rollback wanted after this refresh has already SUCCEEDED and cleanup() has discarded the
  # in-run backups. Hard-fails if it cannot be taken -- see Section 14c.
  capture_durable_hook_snapshot
  # Load the recorded hook_checksums baseline so REFRESH mode can distinguish an unedited
  # platform hook (safe to update) from an operator edit (preserve). Best-effort: a missing
  # or unreadable state leaves the baseline empty, which REFRESH mode treats as "no baseline
  # -> apply the platform version" (the security-priority default).
  read_existing_state || warn "Could not read existing state; refreshing all hooks from source."
  install_hooks
  # The verification gate fresh_install and rebootstrap both run does not reach this flow
  # (it asserts tokens, settings.json and dir scaffolding this flow deliberately skips), so
  # until now the ONE flow that upgrades an already-installed workspace was the one flow with
  # no post-condition of any kind. This is the narrow post-condition that actually matters
  # for the hook bundle, and it runs BEFORE the success mark below.
  assert_hook_lib_closure
  # Mark success so the EXIT-trap cleanup does NOT roll back the refreshed bundle. If
  # install_hooks or the closure assertion aborts, this is not reached and the pre-write
  # bytes are restored, as intended.
  INSTALL_COMPLETE=1
}

# --- Section 22b-1: List durable hook-bundle snapshots (#5662) ---
# The operator-facing read side of the store: a restore is only usable if the generations
# are discoverable without knowing the naming scheme.
list_hook_snapshots_flow() {
  local root gens gen count
  root="$(hook_backup_root)"
  gens=$(ls -1 "${root}" 2>/dev/null | grep -E '^[0-9]{8}T[0-9]{6}Z-[0-9]+$' | sort) || true
  if [ -z "${gens}" ]; then
    info "No durable hook-bundle snapshots under ${root}/"
    INSTALL_COMPLETE=1
    return 0
  fi
  printf 'Durable hook-bundle snapshots (retention %s, newest last):\n' "${HOOK_BACKUP_RETAIN}" >&2
  for gen in ${gens}; do
    count=$(awk -F'\t' '$1=="file_count"{print $2}' "${root}/${gen}/meta.tsv" 2>/dev/null)
    printf '  %s  (%s file(s))\n' "${gen}" "${count:-unknown}" >&2
  done
  printf 'Restore the newest with:  %s --restore-hooks\n' "$0" >&2
  printf 'Restore a specific one:   %s --restore-hooks <generation>\n' "$0" >&2
  INSTALL_COMPLETE=1
}

# --- Section 22b-2: Restore-hooks flow (#5662) ---
# Put the hook bundle back to a durable generation captured by Section 14c. This is the
# mechanism the deploy path provides in place of a manually-taken, one-off release snapshot.
#
# TREATMENT OF RELEASE-ADDED FILES -- DECIDED, NOT INHERITED (#5662 AC-3).
# The previously documented restore used `cp -R`, which is additive: a file the release
# introduced survives the restore. This flow REMOVES files that are not in the restored
# generation's manifest, and reports how many. The reasoning:
#
#   1. A rollback exists to return the bundle to a KNOWN state. `cp -R` yields "the old state
#      UNION whatever the release added" -- a configuration that has never been shipped, never
#      been tested, and matches no manifest. That is a merge, not a restore, and its result
#      cannot be verified against anything.
#   2. assert_hook_lib_closure derives its required set FROM THE DEPLOYED HOOKS. A leftover
#      library is invisible to it by construction, so under `cp -R` leftovers accumulate
#      silently across refresh/rollback cycles and no platform check can ever see them.
#   3. The leftover was measured INERT for one specific delta (the pre-release hooks reference
#      command-position.awk 0 times, the release hooks 7/6/5/3). That is a property of that
#      delta, not of the procedure. The inverse delta is the live hazard: a release that
#      REMOVES a hook or a library, rolled back with `cp -R`, leaves the removed file in place,
#      and a later partial refresh can read bytes from a release that was rolled back.
#
# The removal is bounded: it is confined to the hook-bundle tree, driven by the manifest of
# the generation being restored (never by a diff against the source repo), and every removed
# path is logged by name. Operator state inside the bundle -- .mode above all -- is IN the
# snapshot, so it is restored, not removed. One consequence is documented rather than
# special-cased: a .mode changed AFTER the snapshot was taken reverts to its snapshot value,
# because "restore to the pre-refresh bundle" means exactly that. Carving out exceptions
# would forfeit the N/N manifest verification that makes the restore checkable at all.
restore_hooks_flow() {
  INSTALL_MODE="restore-hooks"
  local root gen gen_dir dst
  root="$(hook_backup_root)"
  dst="${WORKSPACE_ROOT}/.claude/hooks"

  if [ -n "${RESTORE_GENERATION}" ]; then
    gen="${RESTORE_GENERATION}"
  else
    gen="$(hook_backup_latest_gen)"
  fi
  if [ -z "${gen}" ]; then
    err "No durable hook-bundle snapshot found under ${root}/"
    err "  Nothing to restore. A snapshot is captured automatically by --refresh-hooks."
    exit 66
  fi
  gen_dir="${root}/${gen}"
  if [ ! -f "${gen_dir}/${HOOK_BACKUP_MANIFEST_NAME}" ]; then
    err "Durable snapshot ${gen} has no ${HOOK_BACKUP_MANIFEST_NAME}; refusing to restore from it."
    exit 66
  fi
  if [ ! -d "${dst}" ]; then
    err "No deployed hook bundle at ${dst} -- run a full setup-workspace.sh first."
    exit 66
  fi

  # WORKSPACE BINDING. A generation records the workspace it was taken from, and a restore
  # into a DIFFERENT workspace is refused. Measured (#5662): without this, a restore pointed
  # at a config root holding another workspace's generations happily laid that bundle down
  # and reported "27/27 verified identical" -- the verification is self-consistent, so it
  # cannot notice that the whole snapshot belongs to somewhere else. A restore that can
  # silently import a foreign bundle onto a security surface is worse than no restore.
  local gen_ws
  gen_ws=$(awk -F'\t' '$1=="workspace_root"{print $2}' "${gen_dir}/meta.tsv" 2>/dev/null)
  if [ -n "${gen_ws}" ] && [ "${gen_ws}" != "${WORKSPACE_ROOT}" ]; then
    err "Durable snapshot ${gen} was captured from a DIFFERENT workspace:"
    err "  snapshot workspace: ${gen_ws}"
    err "  this workspace:     ${WORKSPACE_ROOT}"
    err "  Refusing to restore a foreign hook bundle onto this workspace."
    exit 66
  fi

  info "RESTORE-HOOKS flow -- generation ${gen}"
  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would restore ${dst} from ${gen_dir}/bundle and remove non-manifest files"
    INSTALL_COMPLETE=1
    return 0
  fi

  # The restore is itself a write to the one surface git cannot restore, so it gets the same
  # treatment every other write here gets: a durable copy first. This is what makes a BAD
  # restore recoverable, and it is why capture runs before the first byte is replaced.
  capture_durable_hook_snapshot

  local result
  result=$(python3 - "${gen_dir}/bundle" "${gen_dir}/${HOOK_BACKUP_MANIFEST_NAME}" "${dst}" <<'PY'
import hashlib, os, shutil, sys
bundle, manifest, dst = sys.argv[1], sys.argv[2], sys.argv[3]

entries = []
with open(manifest) as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        # Three fields, split on TAB only: a path may legitimately contain spaces, and
        # whitespace-splitting here is how a manifest reader silently drops rows.
        parts = line.split("\t")
        if len(parts) != 3:
            sys.stderr.write("manifest row is not 3 fields: %r\n" % line)
            sys.exit(3)
        entries.append(tuple(parts))

if not entries:
    sys.stderr.write("manifest is empty\n")
    sys.exit(3)

want = set(rel for _, _, rel in entries)

restored = 0
for sha, mode, rel in entries:
    src_p = os.path.join(bundle, rel)
    dst_p = os.path.join(dst, rel)
    parent = os.path.dirname(dst_p)
    if parent and not os.path.isdir(parent):
        os.makedirs(parent)
    shutil.copyfile(src_p, dst_p)
    os.chmod(dst_p, int(mode, 8))
    restored += 1

# AC-3: remove what the manifest does not carry. Confined to the bundle tree, enumerated
# from the live tree, and every removal is named on stderr so the operator sees it.
removed = 0
removed_names = []
for dirpath, dirnames, filenames in os.walk(dst):
    dirnames.sort()
    for fn in sorted(filenames):
        p = os.path.join(dirpath, fn)
        rel = os.path.relpath(p, dst)
        if rel not in want:
            os.remove(p)
            removed += 1
            removed_names.append(rel)
for rel in removed_names:
    sys.stderr.write("removed (not in restored generation): %s\n" % rel)

# Verify by RECOMPUTING, not by shasum -c (this manifest is 3-field and would misparse).
verified = 0
mismatch = []
for sha, mode, rel in entries:
    p = os.path.join(dst, rel)
    if not os.path.isfile(p):
        mismatch.append(rel)
        continue
    with open(p, "rb") as fh:
        if hashlib.sha256(fh.read()).hexdigest() == sha:
            verified += 1
        else:
            mismatch.append(rel)
for rel in mismatch:
    sys.stderr.write("VERIFY MISMATCH: %s\n" % rel)

print("restored=%d removed=%d verified=%d total=%d" % (restored, removed, verified, len(entries)))
PY
  ) || { err "restore failed while replaying generation ${gen}"; exit 74; }

  # Parse the counts and assert N/N before claiming success. A restore that reports itself
  # green without comparing bytes is the class of defect this whole section exists to close.
  local n_restored n_removed n_verified n_total
  n_restored=$(printf '%s' "${result}" | sed -n 's/.*restored=\([0-9]*\).*/\1/p')
  n_removed=$(printf '%s' "${result}" | sed -n 's/.*removed=\([0-9]*\).*/\1/p')
  n_verified=$(printf '%s' "${result}" | sed -n 's/.*verified=\([0-9]*\).*/\1/p')
  n_total=$(printf '%s' "${result}" | sed -n 's/.*total=\([0-9]*\).*/\1/p')

  if [ -z "${n_total}" ] || [ "${n_total}" -eq 0 ] 2>/dev/null; then
    err "Restore: generation ${gen} manifested ZERO files -- FAILED PROBE, not a clean restore."
    exit 74
  fi
  if [ "${n_verified}" != "${n_total}" ]; then
    err "RESTORE INCOMPLETE: ${n_verified}/${n_total} files match generation ${gen}"
    err "  The bundle is NOT at a known state. A snapshot of the pre-restore bundle was taken"
    err "  first (see the DURABLE SNAPSHOT line above); investigate before running hooks."
    exit 74
  fi

  info "RESTORED: ${n_restored} file(s) from generation ${gen}; ${n_verified}/${n_total} verified identical"
  info "REMOVED (not in restored generation): ${n_removed} file(s)"
  INSTALL_COMPLETE=1
}

# --- Section 22c: Re-home the PreToolUse hook wiring to user scope (#4436) ---
# THE ENFORCEMENT POINT FOR THE SPAWNED-SESSION PATH.
#
# The workspace-project settings file (<workspace-root>/.claude/settings.json) is the
# only surface that declares the hook wiring, and Claude Code loads it only when the
# session's project root resolves to the workspace root. A session rooted in the repo,
# in a worktree, or in any repo subdirectory has NO settings file with a hooks key on
# its resolution path, and a subagent it spawns inherits whatever that session loaded --
# which is nothing. Merging the PreToolUse object into the USER-scope surface puts the
# wiring on every session's resolution path regardless of project root.
#
# SCOPE: the PreToolUse object and nothing else from the template.
#   Installing the template wholesale would additionally register a Stop hook
#   (core/hooks/session-retro-trigger.sh) the harness invokes at EVERY assistant-turn
#   boundary, plus a SessionStart addition -- neither of which the operator opted into
#   by asking for a hook-wiring security fix. ADR-087 ships the Stop hook inert, but
#   inertness there is INSTANCE STATE (it depends on [session_retro] being absent from
#   operator.toml), not a property of this change. A fix whose blast radius depends on
#   a config key it never mentions is not bounded, so this refuses it. Measured delta
#   of the PreToolUse-only scoping: ONE additional script (block-scope-segregation.sh,
#   security class) and ZERO new events.
#
# AUTHORITY: core/settings.json.template, NOT the deployed workspace copy. The two have
#   drifted -- update.sh advances the hook SCRIPTS but nothing refreshes the wiring that
#   NAMES them, because settings.json is not a registered composition surface (tracked
#   separately as #4915; this function deliberately does not fix that). Re-homing the
#   deployed copy would perpetuate a stale wiring.
#
# WHY THIS IS ITS OWN MODE AND NOT PART OF ANY OTHER FLOW -- three independent reasons:
#   1. It writes OUTSIDE the workspace root. Every other flow honors the sandbox
#      invariant that a run with --workspace-root <sandbox> touches only that sandbox;
#      an automatic user-scope write would break it for every install and every test.
#   2. It turns enforcement ON for sessions that previously had none. The DEPLOYED
#      allowlist can be stale against exactly the paths release tooling runs even
#      when the in-repo source is complete, because deploy.sh --deploy never sources
#      the composition-surface manifest and so cannot refresh an allowlist -- it
#      exits 0 reporting nothing to deploy and leaves the stale file as it was
#      (#4447, open; refresh with update.sh --surfaces-only, not deploy.sh).
#      So this must be ordered AFTER allowlist reconciliation -- an ordering only
#      an operator can honor.
#   3. It is an operator-executed precondition: merging the repository change must not,
#      by itself, alter live enforcement state. (This previously cited a bare "AI-004".
#      Action-item ids are release-scoped and reused -- AI-001 appears in seven plans --
#      so an unqualified id resolves to several unrelated items, and this one matched
#      none of them. Cite such ids as "<release> AI-NNN" or not at all.)
#
# Idempotent, backup-first, and reversible: delete the PreToolUse key from the target
# (or restore the .bak) and the prior posture returns immediately.
rehome_pretooluse_wiring() {
  local template="${SOURCE_REPO}/core/settings.json.template"
  local target="${USER_SETTINGS}"

  if [ ! -r "${template}" ]; then
    err "settings template not found at ${template}"
    exit 66
  fi

  info "Re-homing PreToolUse hook wiring"
  info "  source: ${template} (PreToolUse object only)"
  info "  target: ${target}"

  if [ "${DRY_RUN}" -eq 1 ]; then
    info "[dry-run] would merge the PreToolUse object into ${target} (all other keys preserved)"
    return 0
  fi

  if [ -f "${target}" ]; then
    cp "${target}" "${target}.pmo-bak"
    info "Backed up existing settings → ${target}.pmo-bak"
  fi

  python3 -c '
import json, os, re, sys

template_path, target_path, ws_root = sys.argv[1], sys.argv[2], sys.argv[3]

with open(template_path, "r") as f:
    raw = f.read()

# The PreToolUse commands carry exactly one token; resolve it the same way
# substitute_template does (literal str.replace, no sed metacharacter hazards).
raw = raw.replace("[CLAUDE_WORKSPACE_ROOT]", ws_root)
tmpl = json.loads(raw)

pre = tmpl.get("hooks", {}).get("PreToolUse")
if not pre:
    sys.stderr.write("FATAL: template has no hooks.PreToolUse object\n")
    sys.exit(1)

# Refuse to install an unresolved token into a live settings surface: an unresolved
# command path is a wired hook that can never execute -- a silent enforcement hole.
unresolved = sorted(set(re.findall(r"\[(?:OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]", json.dumps(pre))))
if unresolved:
    sys.stderr.write("FATAL: unresolved token(s) in PreToolUse object: {}\n".format(", ".join(unresolved)))
    sys.exit(1)

target = {}
if os.path.exists(target_path):
    with open(target_path, "r") as f:
        body = f.read().strip()
    if body:
        try:
            target = json.loads(body)
        except json.JSONDecodeError as e:
            sys.stderr.write("FATAL: existing {} is not valid JSON: {}\n".format(target_path, e))
            sys.exit(1)
    if not isinstance(target, dict):
        sys.stderr.write("FATAL: existing {} is not a JSON object\n".format(target_path))
        sys.exit(1)

before = json.dumps(target, sort_keys=True)

# MERGE, never clobber. Only hooks.PreToolUse is written; every other top-level key
# and every other hook EVENT already present in the target is preserved untouched.
hooks = target.get("hooks")
if not isinstance(hooks, dict):
    hooks = {}
hooks["PreToolUse"] = pre
target["hooks"] = hooks

after = json.dumps(target, sort_keys=True)

os.makedirs(os.path.dirname(target_path) or ".", exist_ok=True)
with open(target_path, "w") as f:
    json.dump(target, f, indent=2)
    f.write("\n")

groups = len(pre)
regs = sum(len(g.get("hooks", [])) for g in pre)
scripts = sorted({h.get("command", "").rsplit("/", 1)[-1] for g in pre for h in g.get("hooks", [])})
sys.stderr.write("INFO: PreToolUse re-homed: {} matcher group(s), {} registration(s), {} distinct script(s)\n".format(groups, regs, len(scripts)))
sys.stderr.write("INFO: preserved top-level keys: {}\n".format(", ".join(sorted(k for k in target if k != "hooks")) or "(none)"))
sys.stderr.write("INFO: preserved hook events: {}\n".format(", ".join(sorted(k for k in hooks if k != "PreToolUse")) or "(none)"))
sys.stderr.write("INFO: result: {}\n".format("unchanged (idempotent re-run)" if before == after else "updated"))
' "${template}" "${target}" "${WORKSPACE_ROOT}" || {
    err "PreToolUse re-home failed: ${template} → ${target}"
    exit 74
  }

  # Verify rather than assert: every wired command must exist and be executable, or the
  # wiring is a claimed control that cannot fire (the #4449 partial-install class, which
  # becomes load-bearing the moment this wiring goes live).
  local unresolvable
  unresolvable="$(python3 -c '
import json, os, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
bad = []
for g in data.get("hooks", {}).get("PreToolUse", []):
    for h in g.get("hooks", []):
        c = h.get("command", "")
        if not (os.path.exists(c) and os.access(c, os.X_OK)):
            bad.append(c)
print("\n".join(sorted(set(bad))))
' "${target}")"
  if [ -n "${unresolvable}" ]; then
    warn "Re-homed wiring references command(s) that do not exist or are not executable:"
    printf '%s\n' "${unresolvable}" | while IFS= read -r line; do
      [ -n "${line}" ] && warn "  ${line}"
    done
    warn "Run setup-workspace.sh --refresh-hooks first; a wired hook that cannot execute is a silent enforcement hole."
  else
    info "VERIFIED: every re-homed command exists and is executable"
  fi

  info ""
  info "Enforcement is now live for sessions rooted anywhere under ${WORKSPACE_ROOT}."
  info "Sessions outside that root remain uncovered (core/hooks/lib/scope-guard.sh, layer 3)."
  info "To revert: remove the PreToolUse key from ${target}, or restore ${target}.pmo-bak"
}

rehome_hook_wiring_flow() {
  INSTALL_MODE="rehome-hook-wiring"
  info "REHOME-HOOK-WIRING flow — merge the PreToolUse object into the user-scope settings surface only"
  if [ ! -d "${WORKSPACE_ROOT}/.claude/hooks" ]; then
    err "No deployed hooks at ${WORKSPACE_ROOT}/.claude/hooks — run a full setup-workspace.sh first."
    exit 1
  fi
  rehome_pretooluse_wiring
  SUPPRESS_VALIDATE_HINT=1
  INSTALL_COMPLETE=1
}

# --- Section 22d: Refresh-settings flow (ADR-121) ---
# Re-render ONLY the managed .claude/settings.json into an EXISTING workspace,
# under the baseline-anchored guard. The key-granular sibling of --refresh-hooks:
# that flow delivers the hook SCRIPTS, this one delivers the REGISTRATIONS that
# make them fire. It does NOT scaffold dirs, install hooks, or redeploy skills.
#
# It DOES call write_state_file, which refresh_hooks_flow does not — and that
# omission is exactly why the hook checksum baseline is frozen at the last full
# setup on a live install. Repeating it here would freeze the settings baseline
# permanently and make the structural diff the every-run path, so the call is a
# hard requirement of this flow rather than a nicety (Stage-5 trap T-2).
refresh_settings_flow() {
  INSTALL_MODE="refresh-settings"
  info "REFRESH-SETTINGS flow — re-render the managed settings.json only"
  if [ ! -f "${WORKSPACE_ROOT}/.claude/settings.json" ]; then
    err "No deployed settings.json at ${WORKSPACE_ROOT}/.claude/settings.json — run a full setup-workspace.sh first."
    exit 1
  fi

  # Restore the recorded token map + both settings baselines. Best-effort: a
  # missing or unreadable state leaves the baselines empty, which the guard treats
  # as S-2 (classify structurally before writing) — the conservative default.
  read_existing_state || warn "Could not read existing state; classifying settings.json structurally."

  compute_active_tokens
  # If the state carried no token map (a pre-state install, or a state written
  # before tokens resolved), fall back to reading operator.toml directly. This is
  # non-interactive by construction — read_operator_toml parses the file and never
  # prompts — so an unattended update never blocks here. If BOTH are empty the
  # substituter's own unresolved-token gate fires loudly, which is the correct
  # outcome: better a named failure than a settings.json carrying raw tokens.
  local token_count
  token_count=$(json_keys "${TOKENS_FILE}" | grep -c . || true)
  if [ "${token_count}" -eq 0 ]; then
    info "No token map in state; reading operator.toml directly for the re-render."
    read_operator_toml
  fi

  # Part (a) before part (b): the overlay must exist as a migration destination
  # before the guard can migrate anything into it.
  scaffold_settings_local
  settings_guard_and_regen
  # Mark success as soon as the guard returns. The guard installs only
  # already-verified bytes and never leaves a partial write, so from here the
  # EXIT-trap rollback has nothing legitimate to undo — and must not be allowed to
  # remove a settings.json this flow just refreshed.
  INSTALL_COMPLETE=1

  # Persist the (possibly updated) baselines. Skipped only when the guard wrote
  # nothing at all, so an aborted S-4 never records a baseline it did not create.
  case "${SETTINGS_GUARD_STATE}" in
    S-1|S-2|S-3|S-5)
      persist_settings_baseline_to_state
      ;;
    *)
      info "Settings guard wrote nothing (${SETTINGS_GUARD_STATE:-none}); state file left unchanged."
      ;;
  esac
}

# --- Section 23: Init-only-state flow (FM-4 absorption) ---
# Empirically verifies each artifact rather than asserting completion.
init_only_state_flow() {
  INSTALL_MODE="init-only-state"
  info "INIT-ONLY-STATE flow"
  compute_active_tokens

  # Templates: present + no unresolved tokens?
  local target templates_ok=true
  for target in "${WORKSPACE_ROOT}/CLAUDE.md" "${WORKSPACE_ROOT}/.claude/settings.json"; do
    if [ ! -f "${target}" ]; then
      templates_ok=false
      continue
    fi
    if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${target}" 2>/dev/null; then
      templates_ok=false
    fi
  done
  if [ "${templates_ok}" = "true" ]; then
    json_set_bool "${ARTIFACTS_FILE}" "templates_substituted" "true"
  fi

  # Tokens: operator.toml present?
  read_operator_toml
  local tokens_count
  tokens_count=$(json_keys "${TOKENS_FILE}" | grep -c . || true)
  if [ "${tokens_count}" -gt 0 ]; then
    json_set_bool "${ARTIFACTS_FILE}" "tokens_resolved" "true"
  fi

  # Hooks: every source hook has matching workspace target with matching SHA
  local source_hook bn target source_sha target_sha mismatches=0
  for source_hook in "${SOURCE_REPO}/core/hooks/"*.sh; do
    [ -f "${source_hook}" ] || continue
    bn=$(basename "${source_hook}")
    target="${WORKSPACE_ROOT}/.claude/hooks/${bn}"
    if [ ! -x "${target}" ]; then
      mismatches=$((mismatches + 1))
      continue
    fi
    source_sha=$(shasum -a 256 "${source_hook}" | awk '{print $1}')
    target_sha=$(shasum -a 256 "${target}" | awk '{print $1}')
    json_set "${CHECKSUMS_FILE}" "${bn}" "${target_sha}"
    if [ "${source_sha}" != "${target_sha}" ]; then
      mismatches=$((mismatches + 1))
    fi
  done
  if [ "${mismatches}" -eq 0 ]; then
    json_set_bool "${ARTIFACTS_FILE}" "hooks_installed" "true"
  else
    warn "${mismatches} hook(s) missing or drifted from source"
  fi

  # Directories
  local all_dirs=true d
  for d in "${WORKSPACE_ROOT}/.claude" "${WORKSPACE_ROOT}/.claude/hooks" \
           "${WORKSPACE_ROOT}/projects" "${WORKSPACE_ROOT}/knowledge" \
           "${WORKSPACE_ROOT}/personal/pmo-instance"; do
    [ -d "${d}" ] || all_dirs=false
  done
  if [ "${all_dirs}" = "true" ]; then
    json_set_bool "${ARTIFACTS_FILE}" "directories_created" "true"
  fi

  # Behavioral test (only if hooks_installed flag is true)
  local hooks_installed
  hooks_installed=$(json_get "${ARTIFACTS_FILE}" "hooks_installed")
  if [ "${hooks_installed}" = "true" ]; then
    if ! verify_hooks_invokable; then
      json_set_bool "${ARTIFACTS_FILE}" "hooks_installed" "false"
    fi
  fi

  # Determine verification_passed for state file: only true if ALL artifacts true
  local any_false=false k v
  for k in templates_substituted hooks_installed tokens_resolved directories_created; do
    v=$(json_get "${ARTIFACTS_FILE}" "${k}")
    [ "${v}" != "true" ] && any_false=true
  done

  if [ "${any_false}" = "false" ]; then
    write_state_file "true"
    INSTALL_COMPLETE=1
    info "Init-only-state complete. All artifacts empirically verified."
  else
    write_state_file "false"
    err "Some artifacts not verified. Run without --init-only-state for a fresh install."
    exit 1
  fi
}

# --- Section 24: Cleanup + rollback (FM-1 absorption — EXIT trap pattern) ---
cleanup() {
  local exit_code=$?

  if [ "${INSTALL_COMPLETE}" -eq 1 ]; then
    if [ "${DRY_RUN}" -eq 0 ] && [ "${exit_code}" -eq 0 ] && [ "${SUPPRESS_VALIDATE_HINT}" -eq 0 ]; then
      emit_validate_install_command
    fi
    cleanup_session_tmpdir
    return "${exit_code}"
  fi

  # No-mutation exit codes — no rollback needed
  case "${exit_code}" in
    64|66|69|78)
      cleanup_session_tmpdir
      return "${exit_code}"
      ;;
  esac

  if [ "${DRY_RUN}" -eq 1 ]; then
    cleanup_session_tmpdir
    return "${exit_code}"
  fi

  if [ ! -f "${ROLLBACK_OPS_FILE:-/dev/null}" ]; then
    cleanup_session_tmpdir
    return "${exit_code}"
  fi

  warn "Rolling back partial state (INSTALL_COMPLETE=0, exit_code=${exit_code})"
  # Reverse the rollback ops
  local op kind target backup
  while IFS= read -r op; do
    [ -z "${op}" ] && continue
    kind="${op%%:*}"
    target="${op#*:}"
    case "${kind}" in
      rmdir-if-empty)
        if [ -d "${target}" ] && [ -z "$(ls -A "${target}" 2>/dev/null)" ]; then
          rmdir "${target}" 2>/dev/null && info "rolled back (rmdir): ${target}" || true
        fi
        ;;
      rm-file)
        if [ -f "${target}" ]; then
          rm "${target}" 2>/dev/null && info "rolled back (rm): ${target}" || true
        fi
        ;;
      restore-file)
        # Undo an OVERWRITE by putting the pre-write bytes back. A failure here is
        # reported loudly rather than swallowed: unlike a failed `rm-file` (which leaves
        # an extra file), a failed restore leaves a deployed hook or shared library in its
        # half-refreshed state, which is the fail-closed condition itself.
        backup=$(prewrite_backup_path "${target}")
        if [ -f "${backup}" ]; then
          if cp "${backup}" "${target}" 2>/dev/null; then
            info "rolled back (restore): ${target}"
          else
            err "ROLLBACK INCOMPLETE: could not restore ${target} from its pre-write backup"
          fi
        else
          err "ROLLBACK INCOMPLETE: no pre-write backup found for ${target}"
        fi
        ;;
    esac
  done < <(tail -r "${ROLLBACK_OPS_FILE}")

  cleanup_session_tmpdir
  return "${exit_code}"
}

# --- Section 25: validate-install.sh invocation hint ---
emit_validate_install_command() {
  printf '\n' >&2
  printf '======================================================================\n' >&2
  printf 'Workspace setup complete.\n' >&2
  printf '\n' >&2
  if [ -x "${SOURCE_REPO}/docs/scripts/validate-install.sh" ]; then
    printf 'Recommended next step (validate install):\n' >&2
    printf '  %s/docs/scripts/validate-install.sh\n' "${SOURCE_REPO}" >&2
  else
    printf 'Next step: run validate-install.sh once the script ships.\n' >&2
    printf '  (validate-install.sh not yet present at %s/docs/scripts/)\n' "${SOURCE_REPO}" >&2
  fi
  printf '======================================================================\n' >&2
}

# --- Section 26: Main entry ---
main() {
  trap cleanup EXIT
  trap 'err "Interrupted by signal"; exit 130' INT TERM

  check_platform
  parse_argv "$@"
  check_prereqs
  check_source_repo

  init_session_tmpdir

  if [ "${INIT_ONLY_STATE}" -eq 1 ]; then
    init_only_state_flow
    return 0
  fi

  if [ "${REHOME_HOOK_WIRING}" -eq 1 ]; then
    rehome_hook_wiring_flow
    return 0
  fi

  if [ "${LIST_HOOK_SNAPSHOTS}" -eq 1 ]; then
    list_hook_snapshots_flow
    return 0
  fi

  if [ "${RESTORE_HOOKS}" -eq 1 ]; then
    restore_hooks_flow
    return 0
  fi

  if [ "${REFRESH_HOOKS}" -eq 1 ]; then
    refresh_hooks_flow
    return 0
  fi

  if [ "${REFRESH_SETTINGS}" -eq 1 ]; then
    refresh_settings_flow
    return 0
  fi

  local route
  route=$(detect_state_and_route)
  case "${route}" in
    fresh)
      fresh_install
      ;;
    rebootstrap)
      rebootstrap
      ;;
    recovery)
      guided_recovery
      ;;
    *)
      err "Unknown routing decision: ${route}"
      exit 1
      ;;
  esac

  return 0
}

main "$@"
