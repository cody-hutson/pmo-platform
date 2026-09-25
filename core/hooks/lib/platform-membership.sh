# shellcheck shell=bash
# platform-membership.sh — the shared REPOSITORY-MEMBERSHIP helper for pmo-platform PreToolUse
# hooks (#6200).
#
# SOURCED, never executed. No shebang: this file defines two constants and some functions.
#
# ONE QUESTION. Does a directory sit inside a working tree of THE platform repository, wherever on
# disk that tree lives? That is membership, not location. A linked worktree's `.git` is a one-line
# pointer at an administrative directory inside the platform's own git directory, and a primary
# checkout's `.git` IS that directory, so a bounded upward walk plus one small read answers the
# question for a tree created anywhere. No path prefix can, because the whole content of the
# question is that the location is arbitrary.
#
# TWO CONSUMERS, ONE IMPLEMENTATION.
#   block-autonomy-ceiling.sh — BLOCK-AUTONOMY-001 stage 2 (Tier-0), and the domain
#       classification behind BLOCK-AUTONOMY-002 (Tier-0) and BLOCK-AUTONOMY-004 (mode-gated).
#   block-draft-files.sh — the layer-4 repo-identity gate of BLOCK-DRAFT-001.
# Neither keeps a membership implementation of its own.
#
# THIS LIB OWNS NO FAIL BRANCH. It returns the membership answer and nothing else: no process
# termination, no block, no log line. Its consumers fail in OPPOSITE directions — the Tier-0 floor
# fails closed, the draft-file identity axis goes inert, and that hook's anchor axis abstains — and
# two guards whose "I could not decide" branches point opposite ways must not share one. That is
# the same reason lib/scope-guard.sh is not a function in lib/master-enable.sh. Each caller maps
# every return code below to its own direction.
#
# THE CONTRACT
#   platform_membership_anchor
#     Print the physical path of the platform repository's git directory — the reference every
#     answer is compared against — or print NOTHING when it cannot be resolved. Returns 0 always.
#   platform_membership_of START_DIR ANCHOR
#     0  member          the nearest working tree at or above START_DIR belongs to the repository
#                        whose git directory is ANCHOR
#     1  not a member    provably: the nearest tree is another repository, or there is no tree
#                        up to the filesystem root
#     2  undeterminable  START_DIR or ANCHOR is empty or not absolute, the walk exhausted its
#                        bound, or the nearest tree's pointer file carries no pointer line
#     These are RETURN codes of a function, never a process status.
#     START_DIR is a DIRECTORY and is tested first — the directory-entry form a working directory
#     needs. A caller holding a FILE path passes its parent directory.
#     START_DIR must already be PHYSICAL (symlinks and `..` resolved). The walk is lexical, and it
#     canonicalizes only the `.git` entries it meets. Both consumers hold resolved paths.
#     Call it in a status-capturing form — `rc=0; platform_membership_of … || rc=$?` — or as an
#     `if` condition, never as a bare statement. Both consumers run `set -e` with an ERR trap, and
#     a bare non-zero return would be read as a rule-evaluation error.
#
# ONE ANCHOR, RESOLVED. The platform checkout is <workspace-root>/pmo-platform. The workspace root
# is, in order: $CLAUDE_WORKSPACE_ROOT when set and non-empty; else the parent of the .claude
# directory the calling hook was deployed into (${HOOK_DIR}/../..); else $HOME/Claude.
# That is lib/scope-guard.sh's root order WITHOUT its sandbox override PMO_SCOPE_GUARD_ROOT, and
# the omission is deliberate. That override exists to neutralize SCOPE for the rule suites, and a
# scope knob must never steer which repository the Tier-0 floor protects.
# The checkout's own `.git` is then resolved to a physical git directory: a directory is taken
# as-is, a pointer file is followed, and a pointer into a linked worktree's administrative directory
# is followed on to its common directory through `commondir`. A symlinked checkout, a
# --separate-git-dir checkout, and a checkout that is itself a linked worktree are each therefore
# recognized, instead of reading as not-a-member.
#
# THE WALK — moved from block-autonomy-ceiling.sh, not rewritten. A bounded upward loop in which
# the nearest tree wins, plus the relative-pointer join that git 2.48+ `--relative-paths` worktrees
# need. Suite W of block-autonomy-ceiling.test.sh arms every shape. Its W-7 differential deletes the
# join line marked below from a sandbox copy of THIS file. A pointer file this process cannot read
# is treated as absent and the walk climbs past it, exactly as the inline walk did.
#
# COST. Builtins only (test, cd, pwd, read, printf), so the hooks' PATH pin is neither widened nor
# depended upon, and neither python3 nor git is needed: the answer survives an unusable python3.
# A call is a bounded loop of `[ -d ]` / `[ -f ]` tests with no subprocess per level, plus at most
# one pointer read and one canonicalizing subshell where a `.git` entry is met. The anchor costs
# one or two further subshells and is resolved once per hook run.

WORKTREE_WALK_MAX=64
PLATFORM_CHECKOUT_DIRNAME='pmo-platform'

# _pm_canonical_dir PATH — print the physical form of PATH: the path itself when it is an existing
# directory; otherwise the physical form of its longest existing ancestor with the rest re-appended
# (realpath -m semantics). A relative PATH is taken against $PWD. Empty in, empty out. Never fails.
_pm_canonical_dir() {
  local p="${1:-}" head rest="" next base
  [ -n "$p" ] || { printf '%s' ''; return 0; }
  case "$p" in /*) ;; *) p="${PWD:-}/${p}" ;; esac
  while [ "${#p}" -gt 1 ] && [ "${p%/}" != "$p" ]; do p="${p%/}"; done
  if [ -d "$p" ]; then
    ( cd -P -- "$p" 2>/dev/null && pwd -P ) 2>/dev/null || printf '%s' "$p"
    return 0
  fi
  head="$p"
  while [ "$head" != "/" ] && [ ! -d "$head" ]; do
    rest="${head##*/}${rest:+/}${rest}"
    next="${head%/*}"
    if [ -z "$next" ] || [ "$next" = "$head" ]; then head="/"; break; fi
    head="$next"
  done
  base="$( ( cd -P -- "$head" 2>/dev/null && pwd -P ) 2>/dev/null )" || base="$head"
  [ -n "$base" ] || base="$head"
  case "$base" in
    /) printf '%s' "/${rest}" ;;
    *) printf '%s' "${base}${rest:+/}${rest}" ;;
  esac
  return 0
}

# _pm_pointer_gitdir DIR — DIR/.git is a readable pointer file. Print the physical directory its
# pointer line names (a relative pointer is joined to DIR first), or print NOTHING when the file
# carries no pointer line. Never fails.
_pm_pointer_gitdir() {
  local dir="${1:-}" line gitdir=""
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "gitdir: "*) gitdir="${line#gitdir: }"; break ;;
    esac
  done < "${dir}/.git" 2>/dev/null || gitdir=""
  [ -n "$gitdir" ] || { printf '%s' ''; return 0; }
  case "$gitdir" in
    /*) ;;
    *)  gitdir="${dir}/${gitdir}" ;;   # W7: relative-pointer join
  esac
  _pm_canonical_dir "$gitdir"
  return 0
}

# platform_membership_anchor — see THE CONTRACT above.
platform_membership_anchor() {
  local root checkout ptr common=""
  if [ -n "${CLAUDE_WORKSPACE_ROOT:-}" ]; then
    root="$CLAUDE_WORKSPACE_ROOT"
  elif [ -n "${HOOK_DIR:-}" ] && [ -d "${HOOK_DIR}/../.." ]; then
    root="${HOOK_DIR}/../.."
  else
    root="${HOME:-}/Claude"
  fi
  root="$(_pm_canonical_dir "$root")" || root=""
  case "$root" in /*) ;; *) printf '%s' ''; return 0 ;; esac
  checkout="${root%/}/${PLATFORM_CHECKOUT_DIRNAME}"
  if [ -d "${checkout}/.git" ]; then
    _pm_canonical_dir "${checkout}/.git"
    return 0
  fi
  if [ -f "${checkout}/.git" ] && [ -r "${checkout}/.git" ]; then
    ptr="$(_pm_pointer_gitdir "$checkout")" || ptr=""
    if [ -z "$ptr" ] || [ ! -d "$ptr" ]; then printf '%s' ''; return 0; fi
    if [ -f "${ptr}/commondir" ] && [ -r "${ptr}/commondir" ]; then
      IFS= read -r common < "${ptr}/commondir" 2>/dev/null || [ -n "$common" ] || common=""
      if [ -n "$common" ]; then
        case "$common" in /*) ;; *) common="${ptr}/${common}" ;; esac
        common="$(_pm_canonical_dir "$common")" || common=""
        if [ -d "$common" ]; then printf '%s' "$common"; else printf '%s' ''; fi
        return 0
      fi
    fi
    printf '%s' "$ptr"
    return 0
  fi
  printf '%s' ''
  return 0
}

# platform_membership_of START_DIR ANCHOR — see THE CONTRACT above.
platform_membership_of() {
  local dir="${1:-}" anchor="${2:-}" depth=0 gitdir
  # Membership is decidable only for an absolute directory against an absolute anchor. A relative
  # value means resolution failed upstream. This is stated as a guard rather than left to the bound,
  # which would otherwise strip nothing from a slash-free string and spin to the limit.
  case "$anchor" in /*) ;; *) return 2 ;; esac
  case "$dir" in /*) ;; *) return 2 ;; esac
  while [ -n "$dir" ] && [ "$depth" -lt "$WORKTREE_WALK_MAX" ]; do
    if [ -d "${dir}/.git" ]; then
      # A primary checkout. Nearest tree wins: a foreign repository met first is a REJECTION,
      # never a "keep looking further up". Compared physically, so a `.git` that is itself a
      # symlink still meets the anchor; the plain compare first spares the subshell.
      if [ "${dir}/.git" = "$anchor" ]; then return 0; fi
      gitdir="$(_pm_canonical_dir "${dir}/.git")" || gitdir=""
      if [ "$gitdir" = "$anchor" ]; then return 0; fi
      return 1
    fi
    if [ -f "${dir}/.git" ] && [ -r "${dir}/.git" ]; then
      gitdir="$(_pm_pointer_gitdir "$dir")" || gitdir=""
      if [ -z "$gitdir" ]; then return 2; fi
      case "$gitdir" in
        "$anchor"|"${anchor}/"*) return 0 ;;
      esac
      return 1
    fi
    dir="${dir%/*}"
    depth=$((depth + 1))
  done
  # Left the loop with a directory still in hand: the bound stopped it, not the filesystem root.
  if [ -n "$dir" ]; then return 2; fi
  return 1
}
