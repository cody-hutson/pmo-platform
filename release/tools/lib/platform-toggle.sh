#!/usr/bin/env bash
# platform-toggle.sh — resolve a boolean platform-behavior toggle to on|off, with
# the no-op default carried by a TERMINAL IN-CODE CONSTANT rather than by a config read.
#
# SOURCED, never executed. It defines functions and returns; no main, no side effects
# at source time.
#
# WHY THIS EXISTS — the defect it closes, stated first because it is the whole point.
# The obvious design is "ship the default in the template and let the resolver read it."
# That design does not work here, for a measured reason: the runtime platform-config.toml
# does NOT exist on a stock instance, and the update path does not create it. A template
# default therefore never reaches a consumer on such an install. Worse, the repo's shared
# 5-rung reader (deploy.sh resolve_platform_config) echoes the EMPTY STRING when a field
# is absent at every rung — by contract, so the caller can apply its own documented
# fallback. Empty is not false. A consumer that treated "" as its answer would branch on
# an unset value. So the default lives HERE, in the `case` arm below, and every failure
# path funnels into it.
#
# THE PROPERTY THIS GUARANTEES, and the one worth testing:
#   an install that NEVER receives a platform-config.toml,
#   a fresh install,
#   and an install whose file sets every key explicitly false
# are BEHAVIOURALLY INDISTINGUISHABLE. All three resolve off.
#
# RESOLUTION IS 2-RUNG, NOT 5 — a deliberate narrowing, recorded because a reader who
# knows the platform's 5-rung cascade would otherwise correctly assume it applies:
#   rung 1  global default — the in-repo core/config/platform-config.toml.template
#   rung 5  individual     — ${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/platform-config.toml
# Rungs 2-4 (portfolio / program / project) are semantically inapplicable: the facts
# configured through this resolver are PLATFORM-scoped (one release pipeline per install),
# not per-portfolio or per-project. Re-implementing them here would additionally shadow
# resolve_platform_config, the single 5-rung implementation in the repo. The narrowing
# follows the in-file precedent of core/hooks/lib/master-enable.sh, which narrows to the
# individual rung alone for the same reason. Individual WINS over global (most-specific).
#
# THE READER IS SECTION-AWARE, and that is not decoration. A section-blind reader keyed
# on a bare key name matches the same key under ANY section, and — without an `=`
# terminator — matches every key that merely shares the name as a PREFIX. Both are silent
# mis-resolutions. The awk below is lifted VERBATIM from core/hooks/lib/master-enable.sh
# _me_read_field and parameterized on the FILE, so the two readers cannot diverge in
# semantics; it is deliberately not "improved" in transit.
#
# ENVIRONMENT INPUTS (both optional; both exist so a test can drive this hermetically):
#   PMO_SRC_ROOT              repo root for rung 1. Default: derived from this file's path.
#   PMO_PLATFORM_CONFIG_ROOT  XDG config dir for rung 5. Default: $HOME/.config/pmo-platform.
#
# PORTABILITY: jq-free, bash-3.2 portable, /usr/bin/awk by absolute path (POSIX; present
# on macOS + Linux; a pinned PATH cannot hide it). Never exits — callers control flow.

# _pt_src_root — echo the repo root used for the rung-1 template read.
# Honors PMO_SRC_ROOT, else derives from this file's location (release/tools/lib → repo root).
_pt_src_root() {
  if [ -n "${PMO_SRC_ROOT:-}" ]; then
    printf '%s' "$PMO_SRC_ROOT"
    return 0
  fi
  printf '%s' "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
}

# _pt_config_file — echo the absolute path to the durable XDG platform-config.toml (rung 5).
_pt_config_file() {
  printf '%s/platform-config.toml' "${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"
}

# _pt_read_field FILE SECTION KEY — echo the raw value of KEY within [SECTION] of FILE,
# or empty. Section-aware, jq-free, bash-3.2 portable. Never exits.
#
# Returns EMPTY — never a default, never an error — on every one of:
#   absent FILE · unreadable FILE · absent /usr/bin/awk · absent SECTION · absent KEY ·
#   read error. Each of those lands on the caller's terminal `*)` arm, which is what makes
#   the in-code constant the single home of the default.
#
# The awk body is the core/hooks/lib/master-enable.sh _me_read_field body VERBATIM, with
# the file taken as a parameter instead of resolved internally. Keeping it byte-equivalent
# is the point: two readers of the same TOML dialect that were "cleaned up" independently
# are two dialects.
_pt_read_field() {
  local _pt_file="$1"; local _pt_sect="$2"; local _pt_key="$3"
  [ -n "$_pt_file" ] && [ -r "$_pt_file" ] || return 0
  [ -x /usr/bin/awk ] || return 0
  /usr/bin/awk -v sect="[${_pt_sect}]" -v key="$_pt_key" '
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
  ' "$_pt_file" 2>/dev/null || true
}

# platform_toggle_state SECTION KEY — echo "on" iff [SECTION].KEY resolves to the literal
# true (any case) on the highest-precedence rung that carries a value; "off" otherwise.
#
# "off" is the shipped no-op default and comes from the `*)` arm below — an IN-CODE
# CONSTANT, not a value read from any file. Every one of these resolves off:
#   absent config file (both rungs) · absent section · absent key · empty value ·
#   malformed / non-boolean value ("yes", 1, "true-ish") · same-named key under another
#   section · same-PREFIX key under any section.
#
# Always returns 0 — the echoed token carries the state, so callers must not read $?.
platform_toggle_state() {
  local _pt_section="$1"; local _pt_keyname="$2"
  local _pt_val=""
  local _pt_hit=""

  # rung 1 — global default (in-repo template).
  _pt_hit="$(_pt_read_field "$(_pt_src_root)/core/config/platform-config.toml.template" "$_pt_section" "$_pt_keyname")"
  [ -n "$_pt_hit" ] && _pt_val="$_pt_hit"

  # rung 5 — individual (XDG). Most-specific wins, so a value here overrides rung 1.
  _pt_hit="$(_pt_read_field "$(_pt_config_file)" "$_pt_section" "$_pt_keyname")"
  [ -n "$_pt_hit" ] && _pt_val="$_pt_hit"

  # TERMINAL IN-CODE CONSTANT. Only the literal true enables; everything else is off.
  case "$_pt_val" in
    true|True|TRUE) printf 'on' ;;
    *)              printf 'off' ;;
  esac
  return 0
}
