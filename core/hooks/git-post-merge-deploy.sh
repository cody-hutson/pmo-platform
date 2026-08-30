#!/usr/bin/env bash
# git-post-merge-deploy.sh — redeploy changed skills after a merge lands on main.
#
# A skill's git source and its installed copy drift apart whenever a merge lands
# and nobody runs the deploy. This hook closes that window for the merges it
# observes: it derives the skills THIS merge brought in and hands them to the
# already-supported named-deploy form of core/deploy/deploy.sh.
#
# It is deliberately narrow. It deploys, it never rebuilds: a stale .skill
# package is NOT refreshed here, because the package rebuild is a source-edit
# obligation that belongs to the release, not to the merge. See the deployment
# rule named under hook-owner below.
#
# Install:  ln -sf ../../core/hooks/git-post-merge-deploy.sh .git/hooks/post-merge
#           (performed for you by docs/scripts/setup-workspace.sh, and re-run by
#            ./update.sh via its --refresh-hooks delegation)
# Skip once: PMO_SKIP_POST_MERGE_DEPLOY=1 git merge ...
#
# hook-owner: core/rules/skill-deployment.md
#
# GUARDS, and why each exists.
#
#   A. PRIMARY CHECKOUT ONLY. A linked worktree does not have its own hooks
#      directory — git reads hooks from the primary checkout's, and this repo
#      additionally sets core.hooksPath there explicitly. So this hook FIRES on a
#      merge performed inside a release worktree, where HEAD is a release branch
#      carrying unmerged work. Ungated, that would push unmerged skills over the
#      operator's live install. The discriminator is git-dir vs git-common-dir,
#      which differ in a worktree and agree in the primary checkout.
#
#      Both are normalized through `pwd -P` rather than string-compared raw. This
#      is not defensive padding: from a SUBDIRECTORY of the primary checkout git
#      reports --git-dir as an absolute path and --git-common-dir as a relative
#      one, so a raw comparison reports "worktree" for the primary and the hook
#      silently never deploys. Git invokes post-merge at the worktree top level
#      today, but a guard that is correct only at one cwd is a guard that fails
#      quietly when that changes.
#
#   B. MAIN ONLY. Deploying from any other branch installs work that is not yet
#      the mainline.
#
#   C. OPT-OUT. One environment variable, for the merge where the operator does
#      not want their install touched.
#
# The hook deliberately does NOT adjust the command search path. Pinning one here
# would be a hardcoded guess at the operator's layout, and the search path is
# exactly the surface a hook must not rewrite. Instead every external tool it
# needs is probed for up front, and an environment missing one is a clean no-op.
#
# POSTURE: this hook must never fail a merge. The merge has already happened by
# the time post-merge runs, so a non-zero exit reports a failure the operator
# cannot act on and cannot undo. Every path exits 0.

set -u
trap 'exit 0' ERR

note() { printf '[post-merge-deploy] %s\n' "$1" >&2; }

# ---- Guard C: explicit opt-out -------------------------------------------
[ "${PMO_SKIP_POST_MERGE_DEPLOY:-0}" = "1" ] && exit 0

# ---- Environment probe: a minimal environment is a no-op, never an error ---
for _tool in git sed sort bash; do
  command -v "${_tool}" >/dev/null 2>&1 || exit 0
done

# ---- Guard A: primary checkout only --------------------------------------
_gd_raw="$(git rev-parse --git-dir 2>/dev/null || true)"
_gc_raw="$(git rev-parse --git-common-dir 2>/dev/null || true)"
[ -n "${_gd_raw}" ] && [ -n "${_gc_raw}" ] || exit 0
_gd="$(cd "${_gd_raw}" 2>/dev/null && pwd -P || true)"
_gc="$(cd "${_gc_raw}" 2>/dev/null && pwd -P || true)"
[ -n "${_gd}" ] && [ -n "${_gc}" ] || exit 0
if [ "${_gd}" != "${_gc}" ]; then
  note "linked worktree detected; skipping deploy (primary checkout only)"
  exit 0
fi

# ---- Guard B: main only ---------------------------------------------------
_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ "${_branch}" = "main" ] || exit 0

_top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "${_top}" ] || exit 0
_deploy="${_top}/core/deploy/deploy.sh"
[ -r "${_deploy}" ] || { note "deploy.sh not readable; skipping"; exit 0; }

# ---- Diff base: what did THIS merge bring in? -----------------------------
# deploy.sh's own detector is a stateless last-tag..HEAD diff. That is right for a
# manual release-time deploy and wrong here, where the question is scoped to this
# merge. ORIG_HEAD is git's own answer; the reflog is the fallback; and the final
# fallback is the no-args form, which degrades to today's behaviour rather than
# to silence.
_base="$(git rev-parse --verify -q ORIG_HEAD 2>/dev/null || true)"
[ -n "${_base}" ] || _base="$(git rev-parse --verify -q 'HEAD@{1}' 2>/dev/null || true)"

_run_full() {
  note "deploying all changed skills (tag-diff fallback)"
  bash "${_deploy}" --deploy >&2 2>&1 || note "deploy reported a non-zero exit; merge is unaffected"
  exit 0
}

[ -n "${_base}" ] || _run_full

# Every diff below runs with `git -C "${_top}"`. A git PATHSPEC resolves relative
# to the CURRENT DIRECTORY, not the repository root, so from any subdirectory the
# three paths below would match nothing and the hook would report "no skill
# changed" on a merge that changed several. Anchoring at the top level is what
# makes the derivation cwd-independent; it is not stylistic.
_skill_paths="core/skills/ operations/skills/ release/skills/"

# A deleted skill cannot be cleaned up by the named form: manual mode sets the
# deleted-skill set empty and only the no-args form prunes. Detect first.
# shellcheck disable=SC2086
_deleted="$(git -C "${_top}" diff --diff-filter=D --name-only "${_base}..HEAD" -- ${_skill_paths} 2>/dev/null || true)"
[ -z "${_deleted}" ] || _run_full

# shellcheck disable=SC2086
_names="$(git -C "${_top}" diff --name-only "${_base}..HEAD" -- ${_skill_paths} 2>/dev/null \
  | sed -n 's|[^/]*/skills/\([^/]*\)/.*|\1|p' | sort -u)"

[ -n "${_names}" ] || exit 0

# cmd_deploy calls die() on a name that resolves to no source directory, which
# would turn a partly-renamed roster into a hard failure. Filter to what exists.
_present=""
for _n in ${_names}; do
  for _p in ${_skill_paths}; do
    if [ -d "${_top}/${_p}${_n}" ]; then
      _present="${_present} ${_n}"
      break
    fi
  done
done

# shellcheck disable=SC2086
set -- ${_present}
[ "$#" -gt 0 ] || exit 0

note "deploying changed skills: $*"
bash "${_deploy}" --deploy "$@" >&2 2>&1 || note "deploy reported a non-zero exit; merge is unaffected"
exit 0
