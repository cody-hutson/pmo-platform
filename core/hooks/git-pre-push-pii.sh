#!/bin/bash -p
# git-pre-push-pii.sh — push-time PII backstop: runs the commit-time PII guard over
# every commit and tag a push would publish.
#
# WHY THE COMMIT HOOK IS NOT ENOUGH. git runs pre-commit only for `git commit`.
# merge, cherry-pick, revert, rebase, stash and commit-tree each create a commit
# without it (measured on git 2.54, against a pre-commit hook that always refuses),
# so a revert of a scrub commit puts back the PII the scrub removed, unscanned. On a
# public repository a pushed branch is already public. The push is the last point
# on this machine where the data can still be stopped.
#
# WHAT IT SCANS. git gives this hook one line per ref the push updates:
#   <local-ref> <local-sha> <remote-ref> <remote-sha>
# For each, every commit reachable from <local-sha> that is not already public:
# not on a remote-tracking ref of the remote being pushed to, and not reachable from
# <remote-sha> when that commit is here. A new branch (remote sha all zeros)
# therefore scans only the commits it adds, not the history under it. A tag the push
# sends is scanned as an object (name, tagger, message), each tag in a chain of tags
# too, and its commit starts the range. A ref deletion scans nothing. A pushed object
# that is neither a commit nor a tag (a ref pointed straight at a tree or blob) is
# passed to the guard, which refuses it rather than let it through unread.
#
# PER COMMIT, NOT NET. A line one commit adds and a later commit in the same push
# removes is still published, in the first commit. The guard reads each commit's own
# additions, so that line is refused.
#
# THE DETECTOR IS THE GUARD. This file only works out the range. The patterns, the
# needle list and its resolution, the .mode dial, the accepted homes and the
# fail-closed branches are git-pre-commit-pii.sh's, run with --commits. A change to
# any of them applies to commits and pushes alike.
#
# LIMITS, STATED.
#   - A remote-tracking ref is trusted as public. A stale or hand-written
#     refs/remotes/<remote>/* ref hides the commits under it from this hook. The
#     push-time CI scan (.github/workflows/pii-push-scan.yml) compares against the
#     server's refs instead.
#   - Pushing to a URL rather than a named remote trusts every remote-tracking ref.
#   - A named remote that was added and never fetched has no remote-tracking ref, so its
#     first push scans the whole history it names: slow on a large repo (measured: 3,700
#     commits in 146 s), and it trips on any historical line the patterns match. The hook
#     says so and names the fix, `git fetch <remote>`.
#   - git push --no-verify, a core.hooksPath override and git send-pack all skip
#     this hook (measured). BLOCK-DESTRUCTIVE-024 refuses the hooksPath spellings
#     for every git subcommand; the push flag and send-pack are not refused yet.
#   - Commits created through the hosting API (contents or git-data endpoints) never
#     pass through a local push. The push-time CI scan is their only cover.
#   - Binary content is read as text (--text), so PII inside a compressed file is
#     not seen.
#
# Install:  wired as the repo's pre-push hook by docs/scripts/setup-workspace.sh
#           (install, and update.sh via --refresh-hooks); validate-install.sh A3e
#           reports it missing. Manual form, from the repo root:
#           ln -s ../../core/hooks/git-pre-push-pii.sh "$(git rev-parse --path-format=absolute --git-path hooks)/pre-push"
# Bypass:   CLAUDE_HOOK_BYPASS=1 git push ...  (the operator's, set before launch)
# CI:       arguments after git's two (<remote> <url>) are passed to the guard, so
#           the CI job can add --redact and --needle-file. git never passes more
#           than two, and an environment prefix cannot add an argument.
#
# Environment inputs, as in the guard: git runs this hook in the pusher's environment.
# The shebang's -p ignores BASH_ENV, SHELLOPTS/BASHOPTS and exported functions; the
# lines below neutralise POSIXLY_CORRECT, CDPATH and GREP_OPTIONS and pin LC_ALL=C. The
# guard is run with /bin/bash -p for the same reason: `bash "$guard"` would read BASH_ENV
# and exported functions again. PATH (and GIT_EXEC_PATH) is not covered, as in the guard.
set +o posix
unset POSIXLY_CORRECT CDPATH GREP_OPTIONS
export LC_ALL=C
set -uo pipefail

[[ "${CLAUDE_HOOK_BYPASS:-0}" == "1" ]] && exit 0

pp_remote="${1:-}"
if [[ $# -ge 2 ]]; then shift 2; else shift $#; fi
pp_guard_args=("$@")

pp_refuse() {
  echo "BLOCKED: [git-pre-push-pii] $1; the push is refused." >&2
  exit 1
}

# The guard is this file's sibling. git runs the hook through its .git/hooks link,
# so follow one link level, as the guard itself does, to find the real directory.
pp_self="${BASH_SOURCE[0]:-$0}"
if [[ -L "$pp_self" ]]; then
  pp_link="$(readlink "$pp_self" 2>/dev/null || true)"
  if [[ -n "$pp_link" ]]; then
    case "$pp_link" in
      /*) pp_self="$pp_link" ;;
      *)  pp_self="$(cd "$(dirname "$pp_self")" 2>/dev/null && cd "$(dirname "$pp_link")" 2>/dev/null && pwd)/$(basename "$pp_link")" ;;
    esac
  fi
fi
pp_dir="$(cd "$(dirname "$pp_self")" 2>/dev/null && pwd -P || true)"
pp_guard="${pp_dir}/git-pre-commit-pii.sh"
[[ -n "$pp_dir" && -r "$pp_guard" ]] || pp_refuse "the PII guard was not found beside this hook (${pp_guard})"

# What counts as already public. A named remote contributes its own remote-tracking
# refs; a URL, or a name that is not a plain remote name, contributes all of them.
pp_untracked=0
if [[ "$pp_remote" =~ ^[A-Za-z0-9._-]+$ ]]; then
  pp_public=(--not "--remotes=${pp_remote}")
  # A named remote with no remote-tracking ref yet (added, never fetched) has no public
  # base, so the whole history the push names is scanned. Said once, with the fix.
  [[ -z "$(git for-each-ref --count=1 --format='%(refname)' "refs/remotes/${pp_remote}/" 2>/dev/null)" ]] && pp_untracked=1
else
  pp_public=(--not --remotes)
fi

pp_tmp="$(mktemp -d 2>/dev/null || true)"
[[ -n "$pp_tmp" && -d "$pp_tmp" ]] || pp_refuse "could not create a scratch directory"
trap 'rm -rf "$pp_tmp"' EXIT
: > "$pp_tmp/ids"

while IFS=' ' read -r pp_lref pp_lsha _ pp_rsha || [[ -n "${pp_lref:-}" ]]; do
  [[ -n "${pp_lsha:-}" ]] || continue
  case "$pp_lsha" in *[!0]*) ;; *) continue ;; esac   # a deletion publishes nothing
  # Walk a chain of tags down to what it names; every tag object in it is published.
  pp_obj="$pp_lsha"; pp_depth=0
  pp_kind="$(git cat-file -t "$pp_obj" 2>/dev/null || true)"
  while [[ "$pp_kind" == "tag" && "$pp_depth" -lt 32 ]]; do
    printf '%s\n' "$pp_obj" >> "$pp_tmp/ids"
    pp_obj="$(git cat-file tag "$pp_obj" 2>/dev/null | sed -n '1s/^object //p')"
    pp_kind="$(git cat-file -t "$pp_obj" 2>/dev/null || true)"
    pp_depth=$((pp_depth + 1))
  done
  if [[ "$pp_kind" != "commit" ]]; then
    # A tree, a blob, a tag chain too deep, or an id git cannot read: the guard refuses it.
    printf '%s\n' "${pp_obj:-$pp_lsha}" >> "$pp_tmp/ids"
    continue
  fi
  pp_known=()
  case "${pp_rsha:-}" in
    *[!0]*) git cat-file -e "${pp_rsha}^{commit}" 2>/dev/null && pp_known=("^${pp_rsha}") ;;
  esac
  git rev-list "$pp_obj" ${pp_known[@]+"${pp_known[@]}"} "${pp_public[@]}" >> "$pp_tmp/ids" 2>/dev/null \
    || pp_refuse "git could not list the commits for ${pp_lref:-$pp_lsha}"
done

sort -u "$pp_tmp/ids" > "$pp_tmp/scan" || pp_refuse "could not collect the objects to scan"
[[ -s "$pp_tmp/scan" ]] || exit 0
echo "[git-pre-push-pii] scanning $(wc -l < "$pp_tmp/scan" | tr -d ' ') new commit(s) and tag(s) for ${pp_remote:-the remote}" >&2
if [[ "$pp_untracked" == "1" ]]; then
  echo "[git-pre-push-pii] NOTE: no remote-tracking refs for ${pp_remote}, so every commit this push names is scanned," >&2
  echo "  history the remote may already hold included. To scan only what is new, run: git fetch ${pp_remote}" >&2
fi
/bin/bash -p "$pp_guard" --commits ${pp_guard_args[@]+"${pp_guard_args[@]}"} < "$pp_tmp/scan"
pp_rc=$?
if [[ "$pp_rc" -ne 0 ]]; then
  echo "[git-pre-push-pii] push refused by the PII guard (exit ${pp_rc})." >&2
  exit 1
fi
exit 0
