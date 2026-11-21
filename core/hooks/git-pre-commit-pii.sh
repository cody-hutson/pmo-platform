#!/bin/bash -p
# git-pre-commit-pii.sh — PII prevention guard for git commits.
#
# Blocks a commit whose STAGED ADDITIONS introduce private PII into the tracked
# corpus. Two tiers:
#
#   ALWAYS-BLOCK (every file): literal home-directory paths, phone numbers, and
#   any coworker name OR employer/org domain listed in the gitignored localized-
#   context needle file. None of these are ever legitimately tracked. The org
#   domain is intentionally NOT hardcoded here — a literal employer domain baked
#   into this tracked regex is itself a published leak (it names the operator's
#   employer to anyone who reads the hook), so it lives in the needle file.
#
#   PERSONAL-EMAIL (every file EXCEPT the accepted-home set): generic personal
#   email domains. The accepted homes — LICENSE, SECURITY.md, .github/CODEOWNERS,
#   .github/FUNDING.yml, core/ADRs/, release/ADRs/ — intentionally retain the
#   operator's contact addresses, so they are exempted here.
#
# Only ADDED lines are scanned, so scrubbing existing PII never trips the guard.
# The operator's public handle / legal name are intentionally NOT patterns here
# (kept in accepted homes; governed by deploy.sh Check 25 path-aware logic).
#
# Install:  ln -sf ../../core/hooks/git-pre-commit-pii.sh .git/hooks/pre-commit
# Bypass:   CLAUDE_HOOK_BYPASS=1 git commit ...
# Needles:  resolved by core/deploy/lib-instance-path.sh (pmo_localized_needles);
#           default <instance-dir>/localized-context-needles.txt. PMO_LOCALIZED_NEEDLES /
#           PMO_INSTANCE_PATH add a second list; they never replace the first (see
#           "Environment inputs" below).
#
# Fail-closed posture (#1830 Part 4): when the resolved needle path sits inside
# an EXISTING operator-instance dir but the needle file itself is missing/unfilled,
# the guard FAILS CLOSED (the operator HAS an instance but left the needle surface
# empty — the silent-fail-open case this story closes). A genuinely-unconfigured
# checkout (no instance dir at all — a fresh clone) only WARNs, so onboarding is
# not blocked. The fail-closed flip is gated by a `.mode` file (warn|enforce|off)
# mirroring the bypass-mode-readiness shakedown convention: warn-mode-initial,
# flip to enforce after warn-log review.
#
# Migration safety. The operator-instance home relocated to a workspace-root sibling.
# Both the needle file AND the `.mode` dial resolve from that one base, so a flip on
# an instance whose data has not been copied invalidates the guard's data and its
# severity dial together. Two things follow, and both are implemented below: an
# instance presenting with the NEW home absent but the LEGACY home present is an
# un-migrated instance, NOT a fresh clone, so it takes the fail-closed branch; and the
# legacy home is a `.mode` resolution rung, so a deliberate `enforce` survives the
# move. Both retire on their own once the operator deletes the originals.
#
# Environment inputs. Git runs this hook in the committer's environment, so anything the
# hook reads from the environment can be changed by a one-word prefix on `git commit`.
# Four rules follow, and all four are implemented below:
#   - The shebang runs bash with -p, so BASH_ENV, SHELLOPTS/BASHOPTS and functions
#     exported from the environment (which can replace grep, git or any command here)
#     are ignored when git runs the hook.
#   - The inputs -p leaves alone are neutralised before anything reads them:
#     POSIXLY_CORRECT (POSIX mode makes the process substitution below a syntax error,
#     so the coworker/org scan silently matched nothing), CDPATH (it redirects the
#     relative `cd` that finds this guard's own directory, dropping it onto the
#     lib-unreachable stubs), GREP_OPTIONS (BSD grep reads it, so -q emptied every
#     scan), and the locale: LC_ALL=C, because under a UTF-8 locale macOS tr stops
#     with "Illegal byte sequence" on a binary file read as text and passes nothing
#     on, which hid every file staged after it. Grep's -i therefore folds ASCII only.
#   - The staged diff is read with --no-ext-diff --no-textconv --text, so
#     GIT_EXTERNAL_DIFF, diff.external, textconv drivers and an attribute marking paths
#     binary (`-diff`) cannot replace or hide the added lines.
#   - The resolver's variables (PMO_LOCALIZED_NEEDLES, PMO_INSTANCE_PATH,
#     CLAUDE_WORKSPACE_ROOT, and HOME through its default) can ADD to the coworker/org
#     scan but never remove from it: the instance home beside the guard's own install
#     is always read as well. See "The anchored home" below.
# PATH (and GIT_EXEC_PATH, which git puts at the head of PATH) is NOT covered: a
# planted executable named like a command used here still runs. This hook is not the
# only PII boundary (commands that create commits without running pre-commit skip it
# entirely); it is the commit-time layer.
set +o posix
unset POSIXLY_CORRECT CDPATH GREP_OPTIONS
export LC_ALL=C
set -uo pipefail

[[ "${CLAUDE_HOOK_BYPASS:-0}" == "1" ]] && exit 0

# --- Resolve the operator-instance / needle path via the single resolver ---
# The hook is symlinked into .git/hooks/pre-commit, so $0 points at the symlink;
# resolve it to the real core/hooks/ location, then source the sibling resolver
# in core/deploy/. If sourcing fails for any reason, fall back to inline default
# functions so a missing lib can never hard-break commits.
_pii_self="${BASH_SOURCE[0]:-$0}"
# Follow one symlink level (the canonical install is a single symlink).
if [[ -L "$_pii_self" ]]; then
  _pii_link="$(readlink "$_pii_self" 2>/dev/null || true)"
  if [[ -n "$_pii_link" ]]; then
    case "$_pii_link" in
      /*) _pii_self="$_pii_link" ;;
      *)  _pii_self="$(cd "$(dirname "$_pii_self")" 2>/dev/null && cd "$(dirname "$_pii_link")" 2>/dev/null && pwd)/$(basename "$_pii_link")" ;;
    esac
  fi
fi
_pii_hook_dir="$(cd "$(dirname "$_pii_self")" 2>/dev/null && pwd -P || true)"
_pii_lib="${_pii_hook_dir}/../deploy/lib-instance-path.sh"
if [[ -r "$_pii_lib" ]]; then
  # shellcheck source=../deploy/lib-instance-path.sh disable=SC1090,SC1091
  source "$_pii_lib"
fi
_pii_lib_loaded=1
if ! command -v pmo_localized_needles >/dev/null 2>&1; then
  _pii_lib_loaded=0
  # Lib unreachable: the single resolver is the ONLY home for the path default
  # (AC1 / AC5) — this hook never re-derives it inline. Degrade to empty
  # resolution; downstream this resolves to the "unconfigured" branch (warn, do
  # not block) rather than fabricating a path or silently scanning nothing.
  pmo_instance_path() { printf '%s\n' "${PMO_INSTANCE_PATH:-}"; }
  pmo_instance_path_legacy() { printf '%s\n' "${PMO_INSTANCE_PATH:-}"; }
  pmo_localized_needles() { printf '%s\n' "${PMO_LOCALIZED_NEEDLES:-}"; }
fi

# --- The anchored home: the instance beside the guard's own install ---------
# The installer wires this guard as <ws>/pmo-platform/core/hooks/git-pre-commit-pii.sh
# (one symlink, resolved above), so the workspace root is known from the guard's own
# physical path, without consulting the environment. That home is resolved through the
# same lib with every override cleared, and it is read IN ADDITION to whatever the
# environment resolves:
#   - needles:      the union of both lists;
#   - .mode:        the strictest setting either side states (enforce > warn > off). A
#                   side with no .mode file states nothing; warn is the default when
#                   neither does. So a prefix can tighten the dial, never loosen it below
#                   what the anchored home says;
#   - "an instance exists": true when either side's home is on disk.
# A canonical install resolves both sides to the same home, so nothing changes for it.
# An instance relocated with PMO_INSTANCE_PATH still contributes its own list and dial.
# A sandboxed copy of the guard anchors inside its own sandbox, so tests stay hermetic.
#
# The anchor is taken only from the geometry the installer creates (core/hooks/, with
# the resolver found at ../deploy/). A copy anywhere else (the deployed .claude/hooks/,
# or a run on the lib-unreachable stubs) has no anchor and resolves from the
# environment alone, exactly as before.
anchor_ws=""
if [[ "$_pii_lib_loaded" == "1" ]]; then
  case "$_pii_hook_dir" in
    */core/hooks) anchor_ws="$(cd "${_pii_hook_dir}/../../.." 2>/dev/null && pwd -P || true)" ;;
  esac
fi
# Run one resolver function rooted at the anchor, with the env overrides cleared.
# CLAUDE_WORKSPACE_ROOT is set to the anchor, so HOME is never consulted either.
_pii_anchored() {
  ( unset PMO_INSTANCE_PATH PMO_LOCALIZED_NEEDLES; CLAUDE_WORKSPACE_ROOT="$anchor_ws"; "$1" )
}
anchor_needles=""; anchor_instance_dir=""; anchor_legacy_dir=""
if [[ -n "$anchor_ws" ]]; then
  anchor_needles="$(_pii_anchored pmo_localized_needles)"
  anchor_instance_dir="$(_pii_anchored pmo_instance_path)"
  anchor_legacy_dir="$(_pii_anchored pmo_instance_path_legacy)"
fi

# Read the staged additions. --no-ext-diff / --no-textconv: GIT_EXTERNAL_DIFF,
# diff.external and textconv drivers would otherwise replace the text scanned here with
# whatever a program prints. --text: an attribute that marks a path binary (`-diff`,
# from a staged .gitattributes or a core.attributesFile) would otherwise turn every
# added line into "Binary files differ". Binary content is therefore read as text: NUL
# bytes are dropped (a shell variable cannot hold them, and they would make grep treat
# the whole stream as binary), and every grep that reads this text runs with -a.
_pii_added() {
  git diff --cached --no-color --no-ext-diff --no-textconv --text -U0 "$@" 2>/dev/null \
    | tr -d '\000' | grep -aE '^\+' | grep -avE '^\+\+\+' || true
}

# Tier 1 — always-block patterns (every staged file).
always='/Users/[a-z][a-z0-9._-]+/|[0-9]{3}-[0-9]{3}-[0-9]{4}'
added_all="$(_pii_added)"
hits="$(printf '%s\n' "$added_all" | grep -ainE "$always" || true)"

# Tier 1b — coworker / org needles (gitignored instance file), every file.
needles="$(pmo_localized_needles)"
instance_dir="$(pmo_instance_path)"
# The pre-relocation home. Present ONLY to tell an un-migrated instance from a
# genuinely fresh clone — see the branch predicate below. Resolved through the lib
# so the legacy leaf literal stays single-homed (AC1 / AC5).
legacy_instance_dir="$(pmo_instance_path_legacy)"

# Resolve the fail-closed mode (warn|enforce|off). On each side (environment,
# anchored) the operator-instance file comes first (consistent with deploy.sh's
# per-check .mode resolution), then a hooks-directory fallback; the two sides are
# then merged strictest-first, as the anchored-home block above describes,
# defaulting to warn-mode-initial per the shakedown convention.
#
# THE LEGACY RUNG IS LOAD-BEARING, NOT BELT-AND-BRACES. This dial and the needle
# file resolve from the SAME base, so the home relocation invalidates both in one
# instant. The operator's `.mode` is hand-created in their instance dir — the file
# is untracked and nothing writes it — so on an un-migrated instance the only copy
# that exists sits at the legacy home. Without this rung a flip silently downgrades
# a deliberate `enforce` to the `warn` default, and the branch below would print
# BLOCKED and then exit 0: loud, and useless. Current home first, so a migrated
# operator's posture always wins over a stale legacy file.
_pii_mode_of() { # first valid .mode among the given dirs on stdout, else nothing
  local _d _m
  for _d in "$@"; do
    [[ -n "$_d" && -f "${_d}/git-pre-commit-pii.mode" ]] || continue
    _m="$(tr -d '[:space:]' < "${_d}/git-pre-commit-pii.mode" 2>/dev/null || true)"
    case "$_m" in enforce|warn|off) printf '%s\n' "$_m"; return 0 ;; esac
  done
  return 0
}
_m_env="$(_pii_mode_of "$instance_dir" "$legacy_instance_dir" "$_pii_hook_dir")"
_m_anchor=""
if [[ -n "$anchor_ws" ]]; then
  _m_anchor="$(_pii_mode_of "$anchor_instance_dir" "$anchor_legacy_dir" "$_pii_hook_dir")"
fi
case " ${_m_env} ${_m_anchor} " in
  *" enforce "*) needle_mode="enforce" ;;
  *" warn "*)    needle_mode="warn" ;;
  *" off "*)     needle_mode="off" ;;
  *)             needle_mode="warn" ;;
esac

# Determine whether the needle files carry any active (non-comment) entry. Both
# sides are read and joined; the same path named twice is read once.
needle_filled=0
needle_cleaned=""
_pii_nl=$'\n'
_pii_seen=""
for _nf in "$needles" "$anchor_needles"; do
  [[ -n "$_nf" && "$_nf" != "$_pii_seen" && -r "$_nf" ]] || continue
  _pii_seen="$_nf"
  _nc="$(grep -vE '^[[:space:]]*(#|$)' "$_nf" 2>/dev/null || true)"
  [[ -n "$_nc" ]] && needle_cleaned="${needle_cleaned:+${needle_cleaned}${_pii_nl}}${_nc}"
done
[[ -n "$needle_cleaned" ]] && needle_filled=1

if [[ "$needle_filled" == "1" ]]; then
  # Configured + filled → scan staged additions against the needles.
  nhits="$(printf '%s\n' "$added_all" | grep -ainFf <(printf '%s\n' "$needle_cleaned") || true)"
  [[ -n "$nhits" ]] && hits="$(printf '%s\n%s\n' "$hits" "$nhits" || true)"
elif [[ "$needle_mode" != "off" ]]; then
  # Two distinct unconfigured states, distinct messages (#1830 Part 4).
  #
  # AN UN-MIGRATED INSTANCE IS NOT A FRESH CLONE, and the difference is the whole
  # reason this predicate is not just `-d "$instance_dir"`. After the home
  # relocation, an instance whose data has not been copied presents with the new
  # home absent — indistinguishable, on that test alone, from a first-time clone.
  # It is the opposite: the operator HAS an instance, it is simply still at the old
  # address. Classifying it as a fresh clone takes the branch that can never block
  # at any mode, so the relocation would make the guard quieter on exactly the
  # instances it most needs to protect. The legacy home still being on disk is what
  # distinguishes the two, and it fails safe: once the operator deletes the
  # originals (the last step of the migration, after they have confirmed the copy),
  # this test goes false on its own and the fresh-clone semantics return.
  #
  # Either side's home counts (see "The anchored home"), and the messages name the
  # anchored home when it is on disk: that is the one an environment prefix cannot
  # move. Otherwise they name what the environment resolved, as before.
  _shown_needles="$needles"; _shown_instance="$instance_dir"; _shown_legacy="$legacy_instance_dir"
  if [[ -n "$anchor_ws" ]] && [[ -d "$anchor_instance_dir" || -d "$anchor_legacy_dir" ]]; then
    _shown_needles="$anchor_needles"; _shown_instance="$anchor_instance_dir"; _shown_legacy="$anchor_legacy_dir"
  fi
  if [[ -d "$instance_dir" || -d "$legacy_instance_dir" || -d "$anchor_instance_dir" || -d "$anchor_legacy_dir" ]]; then
    # CONFIGURED-BUT-MISSING: the operator HAS an instance dir but the needle
    # surface is missing or holds only comments — fail closed (this is the
    # silent-degrade case the story closes).
    {
      echo "──────────────────────────────────────────────────────────────"
      if [[ -e "$_shown_needles" ]]; then
        echo "BLOCKED: localized-context needle file is present but UNFILLED:"
      else
        echo "BLOCKED: localized-context needle file is MISSING:"
      fi
      echo "   $_shown_needles"
      echo ""
      if [[ ! -d "$_shown_instance" && -d "$_shown_legacy" ]]; then
        echo "The operator-instance home has MOVED and this instance has not been"
        echo "migrated: nothing exists at $_shown_instance,"
        echo "but the previous home is still present at $_shown_legacy."
        echo "Copy the instance contents to the new home (copy, do not move — keep the"
        echo "originals until you have confirmed the new home works), then re-run"
        echo "install.sh / update.sh. Your git-pre-commit-pii.mode setting is being"
        echo "read from the previous home until you do."
      else
        echo "The operator-instance dir exists ($_shown_instance) but the coworker/org"
        echo "needle surface is empty, so the PII guard's organizational-identity tier"
        echo "is silently disabled. Fill it (one needle per line) from the template:"
        echo "   core/config/localized-context-needles.txt.example"
        echo "or run install.sh / update.sh to scaffold it."
      fi
      echo ""
      echo "Bypass for an intentional commit: CLAUDE_HOOK_BYPASS=1 git commit ..."
      echo "Suppress during shakedown: set git-pre-commit-pii.mode to 'warn' or 'off'."
      echo "──────────────────────────────────────────────────────────────"
    } >&2
    if [[ "$needle_mode" == "enforce" ]]; then
      exit 1
    fi
    # warn-mode-initial: surface loudly but do not block.
    echo "[git-pre-commit-pii] WARN (.mode=warn): proceeding despite unfilled needle file." >&2
  else
    # UNCONFIGURED: no instance dir at all (fresh clone) — graceful warn only.
    {
      echo "[git-pre-commit-pii] NOTE: no operator-instance dir at $_shown_instance;"
      echo "  organizational-identity (coworker/org) PII scanning is inactive."
      echo "  Generic PII patterns (home paths, phone, personal email) still enforced."
      echo "  Run install.sh / update.sh to scaffold the localized-context needle file."
    } >&2
  fi
fi

# Tier 2 — personal-email patterns, EXCLUDING accepted-home files.
pmail='@(gmail|ymail|yahoo|outlook|hotmail|icloud|proton(mail)?)\.com'
added_nonhome="$(_pii_added -- . \
  ':(exclude)LICENSE' ':(exclude)SECURITY.md' ':(exclude).github/CODEOWNERS' \
  ':(exclude).github/FUNDING.yml' ':(exclude)core/ADRs/*' ':(exclude)release/ADRs/*')"
ehits="$(printf '%s\n' "$added_nonhome" | grep -ainE "$pmail" || true)"
[[ -n "$ehits" ]] && hits="$(printf '%s\n%s\n' "$hits" "$ehits" || true)"

hits="$(printf '%s\n' "$hits" | grep -avE '^[[:space:]]*$' || true)"
if [[ -n "$hits" ]]; then
  {
    echo "──────────────────────────────────────────────────────────────"
    echo "BLOCKED: PII pre-commit guard found private data in staged additions:"
    # A hit can come from a binary file read as text, so control characters are
    # dropped (a staged file must not write escape sequences to the terminal) and each
    # line is capped at 2000 bytes. awk reads to the end, so no writer is cut short.
    printf '%s\n' "$hits" | LC_ALL=C tr -d '\001-\010\013-\037\177' \
      | LC_ALL=C awk 'NR <= 25 { print "   " substr($0, 1, 2000) }'
    echo ""
    echo "Replace with a token ([OPERATOR_*]) or \$HOME / config resolution,"
    echo "or set CLAUDE_HOOK_BYPASS=1 to bypass for an intentional case."
    echo "──────────────────────────────────────────────────────────────"
  } >&2
  exit 1
fi
exit 0
