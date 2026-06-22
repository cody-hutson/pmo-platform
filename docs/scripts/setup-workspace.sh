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
#                        [--init-only-state] [--dry-run] [--help]
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

# --- Section 2: Mutable state (scalars only; bash-3.2-compatible) ---
WORKSPACE_ROOT=""
SOURCE_REPO=""
INIT_ONLY_STATE=0
DRY_RUN=0
INSTALL_COMPLETE=0
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
check_platform() {
  if [ "$(uname -s)" != "Darwin" ]; then
    err "setup-workspace.sh is Darwin-only on current release."
    err "Cross-platform support deferred per Stage 5 Recommendation #3."
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
  readonly OPERATOR_TOML CONFIG_ROOT
}

# --- Section 8: Prerequisite checks ---
check_prereqs() {
  local missing=""
  command -v python3 >/dev/null 2>&1 || missing="${missing} python3"
  command -v shasum  >/dev/null 2>&1 || missing="${missing} shasum"
  command -v git     >/dev/null 2>&1 || missing="${missing} git"
  command -v jq      >/dev/null 2>&1 || missing="${missing} jq"
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
compute_active_tokens() {
  ACTIVE_TOKENS=$(
    grep -hoE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' \
      "${SOURCE_REPO}/core/CLAUDE.md.template" \
      "${SOURCE_REPO}/core/settings.json.template" \
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
# added sections/keys outside the managed schema (e.g. [adapters], [automation],
# [methodology], [paths] override keys) survive a rewrite/re-bootstrap verbatim.
# Managed keys are re-emitted from tokens; the three operator-or-default fields
# below (pmo_platform_repo_name, work_board, comms_platform) keep the operator
# value when set. NOTE: value + section preservation is the load-bearing
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
}
MANAGED_SECTIONS = {"meta", "identity", "paths", "platform"}

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
# pass-through ALL operator-added sections verbatim (adapters, automation,
# methodology, projects, and any unknown section) in original file order
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
      if ! printf '%s' "${value}" | grep -qE "${validator_regex}"; then
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
              "" "^[A-Za-z][A-Za-z .-]+$" "true"
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
          "" "^[A-Za-z][A-Za-z .-]+$" "true"
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
          "" "^[A-Za-z ].+$" "true"
        ;;
      "[OPERATOR_ORGANIZATION]")
        resolve_token "${tok}" "Operator organization (e.g., Acme Corp)" \
          "" "^[A-Za-z0-9 &.,'-]+$" "true"
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
      "[COWORK_INSTALL_PATH]")
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
create_dir_layout() {
  local dirs
  dirs="${WORKSPACE_ROOT}/.claude
${WORKSPACE_ROOT}/.claude/hooks
${WORKSPACE_ROOT}/projects
${WORKSPACE_ROOT}/knowledge
${WORKSPACE_ROOT}/personal/pmo-instance"

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
  substitute_template \
    "${SOURCE_REPO}/core/CLAUDE.md.template" \
    "${WORKSPACE_ROOT}/CLAUDE.md" \
    "no"
  substitute_template \
    "${SOURCE_REPO}/core/settings.json.template" \
    "${WORKSPACE_ROOT}/.claude/settings.json" \
    "yes"
  json_set_bool "${ARTIFACTS_FILE}" "templates_substituted" "true"
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
    json_set "${CHECKSUMS_FILE}" "${basename}" "${source_sha}"
    info "SYNC: ${basename} (unchanged)"
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
    cp "${primitive_src}" "${primitive_dst}"
    info "INSTALLED: path-leak primitive (block-gh-path-leak dependency)"
    printf 'rm-file:%s\n' "${primitive_dst}" >> "${ROLLBACK_OPS_FILE}"
  fi

  install_mode_template_if_missing ".mode.template" ".mode"
  install_mode_template_if_missing "deploy-check.mode.template" "deploy-check.mode"

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
  fi

  local override_toml="${WORKSPACE_ROOT}/${OPERATOR_LOCAL_TOML_BASENAME}"
  local entry installed_count=0 preserved_count=0
  for entry in "${COMPOSITION_SURFACE_FILES[@]}"; do
    lib_compose_parse_entry "${entry}"
    local src="${LIB_COMPOSE_ENTRY_SRC}"
    local tier="${LIB_COMPOSE_ENTRY_TIER}"
    local tokens_flag="${LIB_COMPOSE_ENTRY_TOKENS_FLAG}"

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

    if [ -e "${target}" ]; then
      preserved_count=$((preserved_count + 1))
      info "PRESERVED (operator-state): ${basename}"
      continue
    fi

    if [ "${DRY_RUN}" -eq 1 ]; then
      info "[dry-run] would install: ${basename} (tier=${tier}, tokens=${tokens_flag})"
      installed_count=$((installed_count + 1))
      continue
    fi

    if lib_compose_write "${source_file}" "${target}" "${tokens_flag}" "${OPERATOR_TOML}" "${override_toml}"; then
      installed_count=$((installed_count + 1))
      info "INSTALLED: ${basename}"
      printf 'rm-file:%s\n' "${target}" >> "${ROLLBACK_OPS_FILE}"
    else
      err "Install failed: ${basename}"
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

# --- Section 19: Re-bootstrap (branch b) — populate maps from existing state ---
read_existing_state() {
  if [ ! -f "${STATE_FILE}" ]; then
    return 0
  fi
  S_STATE="${STATE_FILE}" \
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
'
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
  install_hooks
  install_composition_surface_files
  scaffold_localized_needles
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
  substitute_templates
  install_hooks
  install_composition_surface_files
  scaffold_localized_needles
  if run_verification_gate; then
    write_state_file "true"
    INSTALL_COMPLETE=1
  else
    write_state_file "false"
    err "Re-bootstrap completed phases but verification gate FAILED."
    exit 1
  fi
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
  local op kind target
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
