# shellcheck shell=bash
# scope-guard.sh — shared WORKSPACE-SCOPE gate for pmo-platform PreToolUse hooks (#4436).
#
# SOURCED, never executed. No shebang: this file only defines functions.
#
# WHY THIS EXISTS (#4436)
# ----------------------
# The PreToolUse wiring is re-homed out of workspace-project scope so that sessions
# rooted in the repo, in a worktree, or in any repo subdirectory resolve it at all —
# that is the enforcement point for the spawned-session path. A wiring that every
# session resolves is by construction also resolved by sessions that have nothing to
# do with the governed workspace. This lib is the ONE place that bound is expressed:
# a hook early-exits 0 when the tool call's working directory is not under the
# governed workspace root.
#
# PRECEDENCE (inside each hook):
#   CLAUDE_HOOK_BYPASS  ->  master-enable  ->  SCOPE (here)  ->  .mode  ->  rule
#
# Scope is a NAMED FOURTH LAYER, not a sub-clause of activation. Activation asks
# "is this hook class turned on for this operator"; scope asks "is this tool call
# inside the tree this operator governs". They are different questions with
# different failure directions (below), which is why they are different files.
#
# THE FAIL DIRECTION IS DELIBERATELY INVERTED — ON ONE AXIS ONLY
# --------------------------------------------------------------
# lib/master-enable.sh states the governing principle: FAIL TOWARD CURRENT BEHAVIOR.
# This lib applies the SAME principle to a DIFFERENT axis, which is why the resulting
# direction is opposite. Read both clauses; only the first is inverted.
#
#   1. CWD axis (INVERTED vs master-enable).
#      A working directory that is UNDETERMINABLE -- absent from the payload AND
#      unreadable from the hook process -- resolves to DO NOT ENFORCE (exit 0). On the
#      activation axis, current behavior is "the hook enforces", so a read failure must
#      not disable it. On the SCOPE axis, current behavior for a session that cannot be
#      shown to be inside the governed root is "no hooks fire at all" -- so a read
#      failure must not START firing them in a repository the operator never asked this
#      platform to govern. Same principle, opposite direction. This is not an
#      inconsistency with master-enable.sh; it is that lib's own rule on a different axis.
#
#      "Undeterminable" is narrower than "absent from the payload", deliberately. The
#      harness runs a PreToolUse hook with the session's working directory as the hook
#      PROCESS's cwd, so $PWD is a second, independent reading of the same fact. This
#      lib falls back to it when the payload field is empty -- the idiom
#      block-draft-files.sh already ships at its own `[ -z "$CWD" ] && CWD="$PWD"` line,
#      single-sourced here so all 13 hooks share one resolution. Only when BOTH readings
#      are empty is the value genuinely undeterminable, and only then does the inverted
#      direction fire. Without this fallback, a payload that merely omitted an optional
#      field would silently disable every hook -- the exact kill-switch shape clause 2
#      exists to forbid, arriving through the other axis.
#
#   2. LIB-PRESENCE axis (NOT inverted -- identical to master-enable.sh).
#      A MISSING or unsourceable scope-guard.sh does NOT gate at all: the caller
#      guards the source, and a hook that cannot find this lib keeps its existing
#      .mode/rule path -- i.e. keeps enforcing. Inverting THIS axis would make a
#      single `rm core/hooks/lib/scope-guard.sh` a silent, total kill switch for
#      every security-class hook on the machine, which is the exact failure
#      lib/master-enable.sh's SECURITY CONTRACT exists to forbid (a silently
#      disabled egress/PII hook -> a leaked commit/PR on a PUBLIC repo is
#      IRREVERSIBLE) and which lib/dep-resolve.sh answers by failing CLOSED.
#      Over-enforcement is recoverable; silent non-enforcement on a public surface
#      is not. The guard bounds where enforcement applies; it is never a mechanism
#      for turning enforcement off.
#
# WHY THIS IS NOT A FUNCTION IN lib/master-enable.sh
# --------------------------------------------------
# Three independent reasons, any one of which is sufficient:
#   - Opposite fail directions on the CWD axis (above). Two guards whose "I could not
#     read my input" branches point in opposite directions must not share a function;
#     the next reader would harmonize them and silently break one.
#   - master_enable_gate receives only a CLASS argument and is invoked BEFORE the
#     payload is parsed, so it has no working directory to read at its insertion point.
#   - master-enable.sh is jq-free BY CONTRACT (its clause 3). The scope decision needs
#     a value that only exists after the payload is parsed. This lib sidesteps that
#     entirely: the CALLER passes an already-extracted string, so this lib parses no
#     JSON and inherits no jq constraint.
#
# WHAT THIS LIB IS NOT
# --------------------
# It is not an escape hatch. A model cannot set the working directory: it is a field
# of the harness-constructed payload envelope, not of the model-controlled command
# string. An omitted field yields not-enforce, which is the same posture as running
# outside the workspace -- a posture that is already permitted and was the ONLY
# posture before this release. The operator escape hatch remains CLAUDE_HOOK_BYPASS
# at layer 1, with its existing BLOCK-DESTRUCTIVE-023 mid-session anti-injection denial.
#
# NO NEW CONFIGURATION SURFACE
# ----------------------------
# The governed root is resolved from what already exists, in this order:
#   1. $PMO_SCOPE_GUARD_ROOT -- the integration-test / sandbox override, the exact
#      analogue of the $PMO_PLATFORM_CONFIG_ROOT override lib/master-enable.sh already
#      ships for the same reason ("integration tests / sandboxed runs"). The hook test
#      harness sets it so the rule suites exercise RULES rather than scope; a dedicated
#      suite sets it per-case to exercise this layer. It cannot widen an attacker's
#      reach: setting it mid-session is denied by BLOCK-DESTRUCTIVE-023 alongside
#      CLAUDE_HOOK_BYPASS, and an attacker who can set it pre-launch can already set
#      CLAUDE_HOOK_BYPASS=1, which is strictly more powerful.
#   2. $CLAUDE_WORKSPACE_ROOT, when set and non-empty -- the same env override the
#      hooks already read as PRIMARY_ROOT.
#   3. The caller's own deployed location: <HOOK_DIR>/../.. , i.e. the parent of the
#      .claude directory the hook was deployed into. Self-locating, exactly as each
#      hook resolves its allowlists and logs, so it cannot drift from the install.
#   4. $HOME/Claude -- the shipped default, identical to the hooks' PRIMARY_ROOT default.
# No file is read. No config KEY is introduced on any durable surface. Portable to
# bash 3.2 (macOS system bash) and uses shell builtins only, so the hooks' PATH pin
# (/usr/bin:/bin) is neither widened nor depended upon.
#
# COVERAGE CONSEQUENCE WORTH STATING
# ----------------------------------
# A git worktree created OUTSIDE the governed workspace root (e.g. under /tmp) is out
# of scope and its sessions are not covered, even though it is a checkout of a governed
# repository. Scope is decided by the session's working directory, not by repository
# identity. Operators who place worktrees outside the workspace root must either keep
# them inside it or accept that coverage does not follow the clone.
#
# THE CONVERSE, AND WHERE IT IS ANSWERED (#6115)
# ----------------------------------------------
# The same sentence cuts the other way: a SECOND repository checked out BENEATH the
# governed root is a strict descendant, so it is in scope here — and should be. That is
# correct for 12 of the 13 consumers; block-egress.sh and block-gh-path-leak.sh MUST keep
# firing in a nested repository, which may be public, and silencing them there would trade
# a false positive for lost protection on a public surface.
#
# But a hook whose RULE is written against THIS repository's directory layout needs a
# second, different question — "is this repository the platform?" — and asking it HERE
# would change the bound for all 13 consumers in order to fix one. So it is asked
# DOWNSTREAM, local to the hook that needs it: core/hooks/block-draft-files.sh carries a
# repo-identity gate as its layer 4, immediately after this gate returns. Identity is
# deliberately outside THIS lib's contract, and the header sentence above is the statement
# of that boundary, not an omission from it.
#
# Read the two together as: this lib decides WHERE enforcement applies (workspace scope);
# a layout-specific rule decides separately WHETHER ITS OWN repository is the one it
# describes. Neither answers the other's question.

# _sg_canonicalize PATH — echo the physical (symlink-resolved) absolute form of PATH
# when it names an existing directory; otherwise echo PATH unchanged with trailing
# slashes stripped. Builtins only (cd/pwd -P in a subshell), so no external tool and
# no PATH dependency. Never exits; empty input echoes empty.
#
# Canonicalizing BOTH sides matters on macOS, where /tmp is a symlink to /private/tmp:
# a lexical-only compare would classify two spellings of the same directory
# differently, and the guard must not be spoofable by an alternate spelling.
_sg_canonicalize() {
  _sg_p="${1:-}"
  [ -n "$_sg_p" ] || { printf '%s' ''; return 0; }
  # Strip trailing slashes first (keep a lone "/") so "/a/b/" and "/a/b" agree.
  while [ "${#_sg_p}" -gt 1 ] && [ "${_sg_p%/}" != "$_sg_p" ]; do _sg_p="${_sg_p%/}"; done
  if [ -d "$_sg_p" ]; then
    ( cd -- "$_sg_p" 2>/dev/null && pwd -P ) 2>/dev/null || printf '%s' "$_sg_p"
    return 0
  fi
  # Not an existing directory (a deleted cwd, or a path not yet created). Canonicalize
  # the longest EXISTING ancestor and re-append the remainder, i.e. `realpath -m`
  # semantics without depending on a non-POSIX flag.
  #
  # This is load-bearing, not tidiness. Canonicalizing only one side is a silent
  # UNDER-ENFORCEMENT bug: on macOS the root "$TMPDIR/Claude" resolves through the
  # /var -> /private/var symlink while a non-existent path beneath it would not, so a
  # session in a just-deleted directory under the governed root would compare OUT of
  # scope and every hook would go inert. Both sides must be spelled the same way.
  _sg_rest=""
  _sg_head="$_sg_p"
  while [ "$_sg_head" != "/" ] && [ ! -d "$_sg_head" ]; do
    _sg_rest="${_sg_head##*/}${_sg_rest:+/}${_sg_rest}"
    _sg_next="${_sg_head%/*}"
    if [ -z "$_sg_next" ] || [ "$_sg_next" = "$_sg_head" ]; then _sg_head="/"; break; fi
    _sg_head="$_sg_next"
  done
  if [ -d "$_sg_head" ]; then
    _sg_base="$( ( cd -- "$_sg_head" 2>/dev/null && pwd -P ) 2>/dev/null || printf '%s' "$_sg_head" )"
    case "$_sg_base" in
      /) printf '%s' "/${_sg_rest}" ;;
      *) printf '%s' "${_sg_base}${_sg_rest:+/}${_sg_rest}" ;;
    esac
  else
    printf '%s' "$_sg_p"
  fi
  return 0
}

# scope_guard_root — echo the absolute governed workspace root, per the 3-step
# resolution documented above. Never exits. Always returns 0.
#
# HOOK_DIR is the hook's own deployed directory (<root>/.claude/hooks), which every
# hook already computes as `readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"`.
# Its grandparent is the workspace root the install deployed into.
scope_guard_root() {
  if [ -n "${PMO_SCOPE_GUARD_ROOT:-}" ]; then
    _sg_canonicalize "${PMO_SCOPE_GUARD_ROOT}"
    return 0
  fi
  if [ -n "${CLAUDE_WORKSPACE_ROOT:-}" ]; then
    _sg_canonicalize "${CLAUDE_WORKSPACE_ROOT}"
    return 0
  fi
  if [ -n "${HOOK_DIR:-}" ] && [ -d "${HOOK_DIR}/../.." ]; then
    _sg_canonicalize "${HOOK_DIR}/../.."
    return 0
  fi
  _sg_canonicalize "${HOME:-}/Claude"
  return 0
}

# scope_guard_resolve_cwd [CWD] — echo the working directory to decide against:
# the caller-passed payload value when non-empty, else the hook process's own $PWD
# (the harness runs the hook with the session's cwd), else empty. Never exits.
scope_guard_resolve_cwd() {
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
  else
    printf '%s' "${PWD:-}"
  fi
  return 0
}

# scope_guard_in_scope CWD [ROOT] — return 0 when the resolved CWD is the governed
# root or lies beneath it; return 1 otherwise. Returns 1 only when the working
# directory is UNDETERMINABLE (payload value empty AND $PWD empty), which the gate
# below maps to DO NOT ENFORCE per the CWD-axis fail direction.
#
# Boundary correctness: the compare is on canonicalized paths with an explicit "/"
# separator appended to the root, so a sibling directory whose name merely EXTENDS
# the root (e.g. root "/u/Claude" vs cwd "/u/ClaudeSandbox") is correctly OUT of
# scope. A naive prefix test would call it in-scope.
scope_guard_in_scope() {
  _sg_cwd="$(_sg_canonicalize "$(scope_guard_resolve_cwd "${1:-}")")"
  _sg_root="${2:-}"
  [ -n "$_sg_root" ] || _sg_root="$(scope_guard_root)"
  _sg_root="$(_sg_canonicalize "$_sg_root")"

  # Cannot determine either side -> not provably in scope.
  [ -n "$_sg_cwd" ] || return 1
  [ -n "$_sg_root" ] || return 1

  # Exact match.
  [ "$_sg_cwd" = "$_sg_root" ] && return 0

  # Strict descendant: require the separator so a name-extending sibling cannot pass.
  case "$_sg_root" in
    */) _sg_pfx="$_sg_root" ;;   # root is "/" (or already separator-terminated)
    *)  _sg_pfx="${_sg_root}/" ;;
  esac
  case "$_sg_cwd" in
    "${_sg_pfx}"*) return 0 ;;
    *)             return 1 ;;
  esac
}

# scope_guard_gate CWD — the per-hook decision point, called from each PreToolUse
# hook AFTER the payload is parsed and BEFORE any rule is evaluated.
#
#   in scope             -> return 0 (the hook continues to its .mode / rule path)
#   out of scope         -> exit 0  (the hook is inert for this tool call)
#   CWD undeterminable   -> exit 0  (INVERTED fail direction; see the header. Reached
#                                    only when the payload field AND $PWD are both
#                                    empty, not merely when the payload omits it.)
#
# Exiting rather than returning mirrors master_enable_gate, so the caller idiom stays
# a single unconditional call with no branch to get wrong. Emits nothing: an inert
# hook must be silent, and logging every out-of-scope tool call would write an
# unbounded log in every unrelated repository on the machine.
scope_guard_gate() {
  if scope_guard_in_scope "${1:-}"; then
    return 0
  fi
  exit 0
}
