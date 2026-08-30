#!/bin/bash
# tests/git-post-merge-deploy.test.sh — behavioural fixture for
# core/hooks/git-post-merge-deploy.sh.
#
# WHAT THIS EXISTS TO CATCH. The hook redeploys skills after a merge, and the two
# ways it can be wrong are opposites: it can fail to fire when a skill changed
# (drift persists, which is the whole defect the hook exists to close), or it can
# fire when it must not (deploying UNMERGED release-branch skills over the
# operator's live install). Both directions are asserted, and the second is the
# one that matters more, so it carries three separate arms.
#
# HERMETICITY. Every arm builds a throwaway git repository under mktemp and gives
# it a STUB core/deploy/deploy.sh that appends its arguments to a log. The hook
# resolves the deploy script from the repository top level, so the stub is what it
# calls: no arm can reach the real deploy.sh, the real install path, or the
# operator's repository. The log file IS the observation — an arm asserts on what
# the hook asked for, not on what a deploy would have done.
#
# WHY A STUB RATHER THAN A REDIRECTED DEPLOY ROOT. Pointing the real deploy.sh at
# a sandbox root would still execute several thousand lines of unrelated logic to
# observe one decision, and would couple this fixture to that script's internals.
# The hook's contract is "which skill names does it pass, and does it pass any at
# all" — the stub observes exactly that contract and nothing else.

set -u

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK_SRC="${SRC_DIR}/git-post-merge-deploy.sh"

[ -r "$HOOK_SRC" ] || { echo "FAIL: hook not readable at $HOOK_SRC" >&2; exit 1; }

PASS=0; FAIL=0
report() { # report <name> <ok:1|0> [detail]
  if [ "$2" = 1 ]; then printf 'PASS: %s\n' "$1"; PASS=$((PASS+1));
  else printf 'FAIL: %s\n  %s\n' "$1" "${3:-}"; FAIL=$((FAIL+1)); fi
}

SBX="$(mktemp -d 2>/dev/null)"
cleanup() { [ -n "${SBX:-}" ] && /bin/rm -rf "$SBX"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Arm 0 — the file is syntactically valid and carries its declared contract.
#
# This arm exists because the platform's script-execution allowlist admits THIS
# file and not the hook, so a direct `bash -n` on the hook from an agent session
# is refused. Running the check from inside the admitted entry point is the
# sanctioned route to the same assertion.
# ---------------------------------------------------------------------------
if bash -n "$HOOK_SRC" 2>/dev/null; then
  report "0a: hook parses as valid bash" 1
else
  report "0a: hook parses as valid bash" 0 "bash -n reported a syntax error"
fi

if grep -q '^# hook-owner: core/rules/skill-deployment.md' "$HOOK_SRC"; then
  report "0b: hook declares its owner (deploy.sh Check 37 arm a2)" 1
else
  report "0b: hook declares its owner (deploy.sh Check 37 arm a2)" 0 "hook-owner line absent or changed"
fi

if [ -x "$HOOK_SRC" ]; then
  report "0c: hook carries the executable bit (doctor / validate-install / QA)" 1
else
  report "0c: hook carries the executable bit (doctor / validate-install / QA)" 0 "mode is not executable"
fi

# ---------------------------------------------------------------------------
# Sandbox builder.
# ---------------------------------------------------------------------------
LOG=""   # set per-repo by mk_repo

mk_repo() { # mk_repo <dir> ; echoes nothing, sets LOG
  local d="$1"
  /bin/mkdir -p "${d}/core/deploy" "${d}/operations/skills/demo-skill"
  git init -q "$d"
  git -C "$d" symbolic-ref HEAD refs/heads/main
  # Hermetic against a global core.hooksPath: pin this repo's own hooks dir.
  git -C "$d" config --local core.hooksPath "${d}/.git/hooks"
  git -C "$d" config --local user.email "fixture@example.invalid"
  git -C "$d" config --local user.name  "post-merge fixture"
  git -C "$d" config --local commit.gpgsign false

  LOG="${d}/deploy-invocations.log"
  : > "$LOG"
  # Stub deploy.sh — records the argument vector, does nothing else.
  {
    printf '#!/usr/bin/env bash\n'
    printf 'printf "%%s\\n" "$*" >> "%s"\n' "$LOG"
    printf 'exit 0\n'
  } > "${d}/core/deploy/deploy.sh"
  /bin/chmod 755 "${d}/core/deploy/deploy.sh"

  printf 'seed\n' > "${d}/operations/skills/demo-skill/SKILL.md"
  printf 'readme\n' > "${d}/README.md"
  git -C "$d" add -A
  git -C "$d" commit -qm "seed"

  /bin/mkdir -p "${d}/.git/hooks"
  /bin/cp "$HOOK_SRC" "${d}/.git/hooks/post-merge"
  /bin/chmod 755 "${d}/.git/hooks/post-merge"
}

branch_commit() { # branch_commit <dir> <branch> <relpath> <content>
  git -C "$1" checkout -q -b "$2"
  /bin/mkdir -p "$(dirname "$1/$3")"
  printf '%s\n' "$4" > "$1/$3"
  git -C "$1" add -A
  git -C "$1" commit -qm "change $3"
  git -C "$1" checkout -q main
}

# ===========================================================================
# A — SENSITIVITY. A merge carrying a SKILL.md change must deploy that skill.
#     If this arm cannot fail, none of the negative arms below mean anything.
# ===========================================================================
R="${SBX}/a1"; mk_repo "$R"
branch_commit "$R" feat-a "operations/skills/demo-skill/SKILL.md" "edited body"
git -C "$R" merge -q --no-ff -m "merge feat-a" feat-a >/dev/null 2>&1
if grep -q -- '--deploy demo-skill' "$LOG"; then
  report "A1: merge touching a SKILL.md deploys exactly that skill" 1
else
  report "A1: merge touching a SKILL.md deploys exactly that skill" 0 \
    "log: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# A2 — the derivation is a SET: two skills changed, both named, once each.
R="${SBX}/a2"; mk_repo "$R"
/bin/mkdir -p "${R}/release/skills/second-skill"
printf 'seed\n' > "${R}/release/skills/second-skill/SKILL.md"
git -C "$R" add -A; git -C "$R" commit -qm "add second skill"
git -C "$R" checkout -q -b feat-a2
printf 'x\n' > "${R}/operations/skills/demo-skill/SKILL.md"
/bin/mkdir -p "${R}/release/skills/second-skill/references"
printf 'y\n' > "${R}/release/skills/second-skill/references/notes.md"
git -C "$R" add -A; git -C "$R" commit -qm "touch both"
git -C "$R" checkout -q main
git -C "$R" merge -q --no-ff -m "merge feat-a2" feat-a2 >/dev/null 2>&1
_line="$(/usr/bin/tail -n1 "$LOG")"
if [ "$_line" = "--deploy demo-skill second-skill" ]; then
  report "A2: two changed skills are passed as a deduplicated sorted set" 1
else
  report "A2: two changed skills are passed as a deduplicated sorted set" 0 "got: ${_line}"
fi

# ===========================================================================
# B — SPECIFICITY. A merge touching no skill must invoke the deploy ZERO times.
# ===========================================================================
R="${SBX}/b1"; mk_repo "$R"
branch_commit "$R" feat-b "docs/unrelated.md" "nothing to do with skills"
git -C "$R" merge -q --no-ff -m "merge feat-b" feat-b >/dev/null 2>&1
if [ ! -s "$LOG" ]; then
  report "B1: merge touching no skill invokes the deploy zero times" 1
else
  report "B1: merge touching no skill invokes the deploy zero times" 0 \
    "expected empty log, got: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# ===========================================================================
# C — GUARD A (worktree). THE ARM THAT MATTERS MOST. A merge performed inside a
#     linked worktree must no-op, because a worktree reads the PRIMARY
#     checkout's hooks and its HEAD carries unmerged release-branch work.
#
#     ISOLATION MATTERS HERE, AND THE OBVIOUS FIXTURE DOES NOT PROVIDE IT. The
#     natural shape — a worktree on some `wt-main` branch — is a COMPOSITE: the
#     branch guard also rejects it, so the arm stays green even with the worktree
#     guard deleted. That was measured, not theorised: neutralising Guard A left
#     the whole suite passing. The load-bearing guard would have had no arm.
#
#     So the primary checkout is parked on a throwaway branch, which frees `main`
#     to be checked out IN THE WORKTREE. Guard B is then satisfied inside the
#     worktree (HEAD really is main) and only Guard A can prevent the deploy.
# ===========================================================================
R="${SBX}/c1"; mk_repo "$R"
branch_commit "$R" feat-c "operations/skills/demo-skill/SKILL.md" "worktree edit"
# Park the primary off main so the worktree may hold it.
git -C "$R" checkout -q -b parking-branch
WT="${SBX}/c1-wt"
git -C "$R" worktree add -q "$WT" main >/dev/null 2>&1

_wt_hookdir="$(cd "$WT" && git rev-parse --git-path hooks 2>/dev/null)"
if [ -f "${_wt_hookdir}/post-merge" ]; then
  report "C0: precondition — the worktree resolves to a hooks dir holding the hook" 1
else
  report "C0: precondition — the worktree resolves to a hooks dir holding the hook" 0 \
    "resolved: ${_wt_hookdir}"
fi

_wt_branch="$(cd "$WT" && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ "$_wt_branch" = "main" ]; then
  report "C0b: precondition — the worktree really is on main, so Guard B is satisfied" 1
else
  report "C0b: precondition — the worktree really is on main, so Guard B is satisfied" 0 \
    "worktree HEAD is ${_wt_branch}; this arm would test the branch guard instead"
fi

_norm() { ( cd "$1" && cd "$(git rev-parse "$2" 2>/dev/null)" 2>/dev/null && pwd -P ); }
_wt_gd="$(_norm "$WT" --git-dir)"; _wt_gc="$(_norm "$WT" --git-common-dir)"
_pr_gd="$(_norm "$R"  --git-dir)"; _pr_gc="$(_norm "$R"  --git-common-dir)"
if [ -n "$_wt_gd" ] && [ -n "$_pr_gd" ] && [ "$_wt_gd" != "$_wt_gc" ] && [ "$_pr_gd" = "$_pr_gc" ]; then
  report "C0c: Guard A discriminator differs in a worktree and agrees in the primary" 1
else
  report "C0c: Guard A discriminator differs in a worktree and agrees in the primary" 0 \
    "worktree: ${_wt_gd} vs ${_wt_gc} | primary: ${_pr_gd} vs ${_pr_gc}"
fi

( cd "$WT" && git merge -q --no-ff -m "merge feat-c in worktree" feat-c ) >/dev/null 2>&1
if [ ! -s "$LOG" ]; then
  report "C1: merge on main INSIDE a worktree does NOT deploy (Guard A isolated)" 1
else
  report "C1: merge on main INSIDE a worktree does NOT deploy (Guard A isolated)" 0 \
    "UNMERGED WORK WOULD HAVE SHIPPED — log: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# C2 — the same merge in a PRIMARY checkout on main DOES deploy. This is the
#      differential proving C1 is the guard firing and not an unrelated failure
#      (a broken stub, an unfired hook, a bad diff base).
R2="${SBX}/c2"; mk_repo "$R2"
branch_commit "$R2" feat-c2 "operations/skills/demo-skill/SKILL.md" "primary edit"
git -C "$R2" merge -q --no-ff -m "merge feat-c2 in primary" feat-c2 >/dev/null 2>&1
if grep -q -- '--deploy demo-skill' "$LOG"; then
  report "C2: differential — the same merge in a primary checkout on main DOES deploy" 1
else
  report "C2: differential — the same merge in a primary checkout on main DOES deploy" 0 \
    "C1 may be passing for the wrong reason; log: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# C3 — CWD ROBUSTNESS. Guard A must read the same way from anywhere inside the
#      primary checkout. From a SUBDIRECTORY git reports --git-dir absolute and
#      --git-common-dir relative, so a raw string comparison of the two decides
#      "worktree" for the primary and the hook silently never deploys. Git runs
#      post-merge at the top level today, so this arm is the only thing standing
#      between that normalization and a future caller who does not.
R3="${SBX}/c3"; mk_repo "$R3"
branch_commit "$R3" feat-c3 "operations/skills/demo-skill/SKILL.md" "subdir edit"
git -C "$R3" merge -q --no-ff -m "merge feat-c3" feat-c3 >/dev/null 2>&1
: > "$LOG"   # discard the merge-time invocation; re-run the hook from a subdir
( cd "${R3}/core/deploy" && "${R3}/.git/hooks/post-merge" ) >/dev/null 2>&1
if [ -s "$LOG" ]; then
  report "C3: hook invoked from a subdirectory of the primary still deploys" 1
else
  report "C3: hook invoked from a subdirectory of the primary still deploys" 0 \
    "the guard misread the primary checkout as a worktree from a non-top-level cwd"
fi

# ===========================================================================
# D — GUARD B (branch). A merge into a non-main branch must no-op.
# ===========================================================================
R="${SBX}/d1"; mk_repo "$R"
branch_commit "$R" feat-d "operations/skills/demo-skill/SKILL.md" "release edit"
git -C "$R" checkout -q -b release/some-slug
git -C "$R" merge -q --no-ff -m "merge feat-d on release branch" feat-d >/dev/null 2>&1
if [ ! -s "$LOG" ]; then
  report "D1: merge into a non-main branch does NOT deploy" 1
else
  report "D1: merge into a non-main branch does NOT deploy" 0 \
    "log: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# ===========================================================================
# E — GUARD C (opt-out) and the FALLBACK CHAIN.
# ===========================================================================
R="${SBX}/e1"; mk_repo "$R"
branch_commit "$R" feat-e "operations/skills/demo-skill/SKILL.md" "opt-out edit"
( cd "$R" && PMO_SKIP_POST_MERGE_DEPLOY=1 git merge -q --no-ff -m "merge feat-e" feat-e ) >/dev/null 2>&1
if [ ! -s "$LOG" ]; then
  report "E1: PMO_SKIP_POST_MERGE_DEPLOY=1 suppresses the deploy" 1
else
  report "E1: PMO_SKIP_POST_MERGE_DEPLOY=1 suppresses the deploy" 0 \
    "log: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# E2 — with no diff base resolvable, the hook must fall back to the no-args
#      form (today's behaviour) rather than to silence. ORIG_HEAD and the reflog
#      are both removed, then the hook is invoked directly on main.
R="${SBX}/e2"; mk_repo "$R"
/bin/rm -f "${R}/.git/ORIG_HEAD"
/bin/rm -rf "${R}/.git/logs"
( cd "$R" && ./.git/hooks/post-merge ) >/dev/null 2>&1
if [ "$(/usr/bin/tail -n1 "$LOG")" = "--deploy" ]; then
  report "E2: unresolvable diff base falls back to the no-args deploy" 1
else
  report "E2: unresolvable diff base falls back to the no-args deploy" 0 \
    "expected a bare --deploy, got: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# E3 — a merge that DELETES a skill must take the no-args form, because the
#      named form does not prune a removed skill from the install path.
R="${SBX}/e3"; mk_repo "$R"
git -C "$R" checkout -q -b feat-e3
git -C "$R" rm -q -r operations/skills/demo-skill
git -C "$R" commit -qm "remove demo-skill"
git -C "$R" checkout -q main
git -C "$R" merge -q --no-ff -m "merge feat-e3" feat-e3 >/dev/null 2>&1
if [ "$(/usr/bin/tail -n1 "$LOG")" = "--deploy" ]; then
  report "E3: a merge deleting a skill takes the pruning no-args form" 1
else
  report "E3: a merge deleting a skill takes the pruning no-args form" 0 \
    "expected a bare --deploy, got: $(/usr/bin/tr '\n' '|' < "$LOG")"
fi

# E4 — a skill named by the diff whose SOURCE DIRECTORY is not on disk must be
#      filtered out before it reaches the deploy, which calls die() on an
#      unresolvable artifact name and would turn one stale directory into a hard
#      failure for every other skill in the same merge.
#
#      Reaching this filter takes care. The obvious fixture — add a skill and
#      remove it on the same branch — never reaches it, because the net diff
#      names nothing; and removing it in a separate commit routes to the deleted-
#      skill branch instead. Measured: with the filter deleted, that fixture still
#      passed. The state the filter actually guards is a WORKING TREE missing a
#      directory the commit range still names, so that is what is built here: two
#      skills change in the merge, and one's directory is then removed from the
#      working tree only.
R="${SBX}/e4"; mk_repo "$R"
/bin/mkdir -p "${R}/release/skills/ghost-skill"
printf 'seed\n' > "${R}/release/skills/ghost-skill/SKILL.md"
git -C "$R" add -A; git -C "$R" commit -qm "add ghost-skill"
git -C "$R" checkout -q -b feat-e4
printf 'edited\n' > "${R}/operations/skills/demo-skill/SKILL.md"
printf 'edited\n' > "${R}/release/skills/ghost-skill/SKILL.md"
git -C "$R" add -A; git -C "$R" commit -qm "edit both"
git -C "$R" checkout -q main
git -C "$R" merge -q --no-ff -m "merge feat-e4" feat-e4 >/dev/null 2>&1

# Sensitivity precondition: BOTH names reach the deploy while both dirs exist.
if [ "$(/usr/bin/tail -n1 "$LOG")" = "--deploy demo-skill ghost-skill" ]; then
  report "E4a: precondition — both changed skills reach the deploy" 1
else
  report "E4a: precondition — both changed skills reach the deploy" 0 \
    "got: $(/usr/bin/tail -n1 "$LOG")"
fi

# Now remove one directory from the WORKING TREE only and re-run the hook. The
# commit range is unchanged, so the diff still names ghost-skill.
: > "$LOG"
/bin/rm -rf "${R}/release/skills/ghost-skill"
( cd "$R" && ./.git/hooks/post-merge ) >/dev/null 2>&1
_line="$(/usr/bin/tail -n1 "$LOG")"
if [ "$_line" = "--deploy demo-skill" ]; then
  report "E4b: a name whose source dir is absent is filtered, the rest still deploy" 1
else
  report "E4b: a name whose source dir is absent is filtered, the rest still deploy" 0 \
    "expected '--deploy demo-skill', got: ${_line}"
fi

printf '\nRESIDUAL: these arms exercise the hook decision logic against a stub deploy.\n'
printf 'RESIDUAL: they do NOT prove an operator installed the hook — arm C0 proves only\n'
printf 'RESIDUAL: that a worktree resolves to the primary hooks dir, which is the hazard.\n'
printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
