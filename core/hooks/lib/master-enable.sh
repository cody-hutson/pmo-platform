# shellcheck shell=bash
# master-enable.sh — shared master-activation gate for pmo-platform PreToolUse hooks (#310).
#
# SOURCED, never executed. No shebang: this file only defines functions.
#
# WHY THIS EXISTS (#310)
# ---------------------
# A fresh public clone should impose NO workflow guards until the operator opts in,
# and that choice must survive `update.sh`. This lib is the ONE place the durable
# "master activation" state is read and the per-hook gate decision is made, so the
# per-hook edit collapses to a guarded source + a single gate call (mirroring the
# lib/dep-resolve.sh idiom). Homing the gate logic here — not inline in 13 hooks —
# means the class semantics cannot drift hook-to-hook.
#
# DURABLE CARRIER
# ---------------
# The operator VALUE lives in the XDG individual surface
#   ${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/platform-config.toml
# under [security_hooks].master_enabled (+ security_class_master_optout). That file
# is an Operator-instance-category surface `update.sh` never overwrites, so the
# choice is update-durable. Absent file / absent field → the shipped default OFF
# (opt-in). The in-repo template core/config/platform-config.toml.template ships the
# OFF schema default; this lib reads ONLY the XDG value, single-scope by design (NOT
# the 5-rung cascade — no portfolio/program/project rung can create a double-fire).
#
# PRECEDENCE (inside each hook): CLAUDE_HOOK_BYPASS → master-enable (here) → .mode → rule.
#
# SECURITY CONTRACT (D-R9 — ratified SECURITY-EXCLUDED; public-surface security paramount)
# ---------------------------------------------------------------------------------------
#   1. master_enable_gate has TWO classes, declared by the CALLER at the call site:
#        workflow  — master-OFF makes the hook inert (exit 0). Used by the warn-class
#                    workflow hooks whose loss is recoverable.
#        security  — master-OFF NEVER makes the hook inert. The security/floor-class
#                    hooks (credential-reads, destructive, rm-prefer-trash, egress,
#                    gh-path-leak, scope-segregation, shell-injection) + the
#                    block-autonomy-ceiling Tier-0 floor ALWAYS enforce, because a
#                    silently-disabled egress/PII hook → a leaked commit/PR on a
#                    PUBLIC repo is IRREVERSIBLE. The only way a security-class hook
#                    goes inert under master-OFF is the operator's EXPLICIT, logged
#                    security_class_master_optout=true (a public-surface-safety
#                    downgrade the operator consciously accepts) — never a silent default.
#   2. FAIL-TOWARD-CURRENT-BEHAVIOR: the CALLER guards the source so a MISSING lib does
#      NOT gate at all (the hook keeps its existing .mode path — i.e. keeps enforcing).
#      This is the OPPOSITE of dep-resolve's fail-closed: here "cannot read master
#      state" must never equal "master off / guard disabled". Within this lib, an
#      unreadable config or a read error resolves to the documented OFF default for
#      the WORKFLOW class only; the SECURITY class is never disabled by a read failure
#      (it is disabled only by an affirmative optout=true read).
#   3. The reader is jq-free and PATH-independent: absolute-path /usr/bin tools only,
#      bash-3.2 portable. It never widens $PATH and never exits — callers control flow.

# _me_config_file — echo the absolute path to the durable XDG platform-config.toml.
# Honors PMO_PLATFORM_CONFIG_ROOT (integration tests / sandboxed runs), else XDG default.
_me_config_file() {
  printf '%s/platform-config.toml' "${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"
}

# _me_read_field SECTION KEY — echo the raw value of KEY within [SECTION] of the XDG
# platform-config.toml, or empty. Section-aware, jq-free, bash-3.2 portable. Uses
# /usr/bin/awk by absolute path (POSIX; present on macOS + Linux; a pinned PATH cannot
# hide it). Never exits; empty on miss / unreadable file / read error.
_me_read_field() {
  _me_sect="$1"; _me_key="$2"
  _me_file="$(_me_config_file)"
  [ -n "$_me_file" ] && [ -r "$_me_file" ] || return 0
  [ -x /usr/bin/awk ] || return 0
  /usr/bin/awk -v sect="[${_me_sect}]" -v key="$_me_key" '
    # Section header line: string-compare (trimmed) against the target header so a
    # "[" in a value can never be misread as a section, and so no regex-in-brackets
    # ambiguity arises from the section name.
    /^[[:space:]]*\[/ {
      line = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      insect = (line == sect) ? 1 : 0
      next
    }
    insect == 1 && $0 ~ ("^[[:space:]]*" key "[[:space:]]*=") {
      line = $0
      sub(/^[^=]*=[[:space:]]*/, "", line)   # strip "key ="
      sub(/[[:space:]]*#.*$/, "", line)        # strip inline comment
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)  # trim
      gsub(/^"|"$/, "", line)                  # strip surrounding double-quotes
      print line
      exit
    }
  ' "$_me_file" 2>/dev/null || true
}

# master_enable_state — echo "on" iff [security_hooks].master_enabled resolves to the
# literal true; "off" otherwise (false / absent field / absent file / read error).
# "off" is the shipped opt-in default — a fresh clone with no XDG value reads "off".
# Always returns 0 (the echoed token carries the state; callers must not rely on $?).
master_enable_state() {
  _me_val="$(_me_read_field security_hooks master_enabled)"
  case "$_me_val" in
    true|True|TRUE) printf 'on' ;;
    *)              printf 'off' ;;
  esac
  return 0
}

# master_enable_security_optout — echo "on" iff [security_hooks].security_class_master_optout
# resolves to the literal true; "off" otherwise. "on" means the operator has explicitly,
# consciously accepted that security/floor-class hooks may ALSO go inert under master-OFF.
# Never silently defaulted on. Always returns 0.
master_enable_security_optout() {
  _me_opt="$(_me_read_field security_hooks security_class_master_optout)"
  case "$_me_opt" in
    true|True|TRUE) printf 'on' ;;
    *)              printf 'off' ;;
  esac
  return 0
}

# master_enable_gate CLASS — the per-hook decision point. CLASS is one of:
#   workflow  → exit 0 (hook inert) when master state is off; otherwise return 0 (proceed).
#   security  → NEVER inert on master-OFF alone; exit 0 ONLY when master is off AND the
#               operator has set security_class_master_optout=true; otherwise return 0.
# Any unrecognized CLASS is treated as security (fail-toward-enforcement — the safe side).
# Returns 0 to let the hook continue to its existing .mode / rule-eval path.
master_enable_gate() {
  _me_class="${1:-security}"
  _me_state="$(master_enable_state)"
  case "$_me_class" in
    workflow)
      if [ "$_me_state" = "off" ]; then
        exit 0
      fi
      return 0
      ;;
    security|*)
      if [ "$_me_state" = "off" ] && [ "$(master_enable_security_optout)" = "on" ]; then
        exit 0
      fi
      return 0
      ;;
  esac
}
