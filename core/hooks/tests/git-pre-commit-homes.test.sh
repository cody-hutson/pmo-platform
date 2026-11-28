#!/bin/bash
# tests/git-pre-commit-homes.test.sh — the commit guard over the registered in-repo
# git-ignored homes (core/hooks/git-pre-commit-homes.sh), as git runs it through the PII
# guard at pre-commit and at pre-push, and as the In-repo home content gate runs it.
#
# WHAT THIS EXISTS TO CATCH. An ignore rule does not stop `git add -f`, so a file under
# /local-state/, /analysis/ or /roadmaps/ can be committed and published. Each home tracks
# its README.md alone. These arms commit through the installer's geometry — the guard,
# the PII guard and the pre-push hook under <ws>/pmo-platform/core/hooks/, the resolver
# under core/deploy/, .git/hooks/pre-commit and pre-push relative links to them — and push
# to a local bare remote, so the verdicts are git's, not a direct run's.
#
# CLASSES. W wiring and fail-closed · G a forced add, per home, per dial setting, under the
# bypass, and on a partial commit · N near-misses (what must pass, and the case and depth
# variants that must not) · P the push arm, over commits pre-commit never reads · C the
# guard's own --self-test, which the CI job runs first · L the one list and its parity with
# the placement standard's table, against mutated copies · X the exit contract · Z this
# suite leaves the source checkout as it found it.
#
# THE BYPASS (decision record commit-time-home-guard-runs-under-hook-bypass). The commit-time
# check runs whether or not CLAUDE_HOOK_BYPASS is set: the PII guard runs the staged read
# before its own bypass exit (G6a, W3). The push-time check honours the bypass: the pre-push
# hook exits on it before anything runs (G6c, a recorded residual). The CI layer reads a
# pull request's merge tree (G6b), after the branch is already on the remote.
#
# RED, MEASURED. Against the tree with no detector and the PII guard as it was, the arms
# that need the guard fail and the controls pass; the spoke's output records the counts.
# Fixture paths are made up and carry nothing the PII guard refuses.

set -u

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
DET_SRC="${SRC_DIR}/git-pre-commit-homes.sh"
GUARD_SRC="${SRC_DIR}/git-pre-commit-pii.sh"
PUSH_SRC="${SRC_DIR}/git-pre-push-pii.sh"

PASS=0; FAIL=0
report() { # report <name> <ok:1|0> [detail]
  if [ "$2" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s\n  %s\n' "$1" "${3:-}"; FAIL=$((FAIL+1)); fi
}
flat() { /usr/bin/tr '\n' '|' <<<"$1" | /usr/bin/cut -c1-600; }

SBX="$(mktemp -d 2>/dev/null)"; SBX="$(cd "$SBX" && pwd -P)"
cleanup() { [ -n "${SBX:-}" ] && /bin/rm -rf "$SBX"; }
trap cleanup EXIT

# The resolver sits at ../deploy/ in the source tree and beside the hooks in the
# materialized CI layout; either is the file under test.
LIB_SRC=""
for _cand in "${SRC_DIR}/../deploy/lib-instance-path.sh" "${SRC_DIR}/lib-instance-path.sh"; do
  [ -r "$_cand" ] && { LIB_SRC="$_cand"; break; }
done

# The source checkout: the pointer the CI layout helper writes beside the tests, else
# three levels up (the source tree's own geometry).
SRC_ROOT=""
if [ -r "$(dirname "$0")/.source-repo-root" ]; then
  IFS= read -r SRC_ROOT < "$(dirname "$0")/.source-repo-root" || true
fi
[ -n "$SRC_ROOT" ] && [ -d "$SRC_ROOT" ] || SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd -P)"
STD="${SRC_ROOT}/core/standards/instance-data-placement-standard.md"
SRC_STATUS_BEFORE="$(git -C "$SRC_ROOT" status --porcelain 2>&1)"

# Pinned environment: nothing of the operator's is resolved.
unset PMO_INSTANCE_PATH PMO_LOCALIZED_NEEDLES PMO_PEOPLE_ROSTER CLAUDE_HOOK_BYPASS
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR
unset GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL GIT_AUTHOR_NAME GIT_COMMITTER_NAME GIT_CONFIG_GLOBAL GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
export GIT_CONFIG_NOSYSTEM=1
ZEROS="0000000000000000000000000000000000000000"

# --- The geometry ------------------------------------------------------------
# mk_repo <name> [no-detector] : a workspace and repo in the installer's geometry, with
# the three homes' ignore pairs, a base commit (the three READMEs and docs/ok.md), both
# hooks linked, and a local bare remote holding main. Sets WS, HOMEDIR, REPO, REMOTE.
WS=""; HOMEDIR=""; REPO=""; REMOTE=""
mk_repo() {
  HOMEDIR="${SBX}/$1/home"; WS="${HOMEDIR}/Claude"; REPO="${WS}/pmo-platform"; REMOTE="${SBX}/$1/remote.git"
  /bin/mkdir -p "${REPO}/core/hooks" "${REPO}/core/deploy" "$HOMEDIR"
  [ -r "$GUARD_SRC" ] && /bin/cp "$GUARD_SRC" "${REPO}/core/hooks/git-pre-commit-pii.sh"
  [ -r "$PUSH_SRC" ] && /bin/cp "$PUSH_SRC" "${REPO}/core/hooks/git-pre-push-pii.sh"
  if [ "${2:-}" != "no-detector" ] && [ -r "$DET_SRC" ]; then
    /bin/cp "$DET_SRC" "${REPO}/core/hooks/git-pre-commit-homes.sh"
  fi
  /bin/chmod +x "${REPO}/core/hooks/"*.sh 2>/dev/null
  [ -n "$LIB_SRC" ] && /bin/cp "$LIB_SRC" "${REPO}/core/deploy/lib-instance-path.sh"
  /usr/bin/env HOME="$HOMEDIR" git init -q "$REPO"
  g symbolic-ref HEAD refs/heads/main
  g config user.name "Homes Test"; g config user.email "homes-test@example.invalid"
  g config commit.gpgsign false; g config tag.gpgsign false
  /usr/bin/printf '/local-state/*\n!/local-state/README.md\n/analysis/*\n!/analysis/README.md\n/roadmaps/*\n!/roadmaps/README.md\n/core/\n' > "${REPO}/.gitignore"
  /bin/mkdir -p "${REPO}/local-state" "${REPO}/analysis" "${REPO}/roadmaps" "${REPO}/docs"
  for _h in local-state analysis roadmaps; do /usr/bin/printf '# %s\n' "$_h" > "${REPO}/${_h}/README.md"; done
  /usr/bin/printf 'ok\n' > "${REPO}/docs/ok.md"
  g add .gitignore docs/ok.md local-state/README.md analysis/README.md roadmaps/README.md
  g commit -q -m base
  /bin/ln -s ../../core/hooks/git-pre-commit-pii.sh "${REPO}/.git/hooks/pre-commit"
  /bin/ln -s ../../core/hooks/git-pre-push-pii.sh "${REPO}/.git/hooks/pre-push"
  /usr/bin/env HOME="$HOMEDIR" git init -q --bare "$REMOTE"
  g remote add origin "$REMOTE"
  g push -q --no-verify origin main 2>/dev/null
}
# g <git args...> : git in the arm's repo, in the arm's pinned environment.
g() { /usr/bin/env HOME="$HOMEDIR" CLAUDE_WORKSPACE_ROOT="$WS" git -C "$REPO" "$@"; }
# put <path> [content] : write a file in the arm's repo.
put() { /bin/mkdir -p "$(dirname "${REPO}/$1")"; /usr/bin/printf '%s\n' "${2:-fixture}" > "${REPO}/$1"; }
# plumb <path> <parent> : a commit made with plumbing (no hook runs): the parent's tree
# with <path> added.
plumb() {
  local idx="${SBX}/plumb.idx" blob tree
  /bin/rm -f "$idx"
  GIT_INDEX_FILE="$idx" g read-tree "$2"
  blob="$(/usr/bin/printf 'fixture\n' | g hash-object -w --stdin)"
  GIT_INDEX_FILE="$idx" g update-index --add --cacheinfo "100644,${blob},$1"
  tree="$(GIT_INDEX_FILE="$idx" g write-tree)"
  g commit-tree "$tree" -p "$2" -m "plumbed $1"
  /bin/rm -f "$idx"
}
# cacheinfo <path> : record <path> in the index directly (a case or shape a filesystem add
# cannot make).
cacheinfo() {
  local blob; blob="$(/usr/bin/printf 'fixture\n' | g hash-object -w --stdin)"
  g update-index --add --cacheinfo "100644,${blob},$1"
}
RC=0; ERR=""
commit() { # commit [NAME=VALUE ...] -- <commit args...> ; sets RC, ERR
  local t; t="$(mktemp)"; RC=0
  local envs=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  [ "${1:-}" = "--" ] && shift
  /usr/bin/env HOME="$HOMEDIR" CLAUDE_WORKSPACE_ROOT="$WS" ${envs[@]+"${envs[@]}"} \
    git -C "$REPO" commit -q "$@" >/dev/null 2>"$t" || RC=$?
  ERR="$(/bin/cat "$t")"; /bin/rm -f "$t"
}
push() { # push [NAME=VALUE ...] -- <refspec...> ; sets RC, ERR
  local t; t="$(mktemp)"; RC=0
  local envs=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  [ "${1:-}" = "--" ] && shift
  ( cd "$REPO" && /usr/bin/env HOME="$HOMEDIR" CLAUDE_WORKSPACE_ROOT="$WS" ${envs[@]+"${envs[@]}"} \
      git push -q origin "$@" ) >/dev/null 2>"$t" || RC=$?
  ERR="$(/bin/cat "$t")"; /bin/rm -f "$t"
}
remote_sha() { git --git-dir="$REMOTE" rev-parse -q --verify "$1" 2>/dev/null || true; }
head_sha() { g rev-parse -q --verify HEAD 2>/dev/null || true; }
has() { /usr/bin/grep -qF -- "$2" <<<"$1"; }

# expect_commit_refused <name> <head-before> : refused, HEAD unchanged, and the home guard
# named itself (so the refusal is not the PII guard's for another reason).
expect_commit_refused() {
  local now; now="$(head_sha)"
  if [ "$RC" -ne 0 ] && [ "$now" = "$2" ] && has "$ERR" '[git-pre-commit-homes]'; then report "$1" 1
  else report "$1" 0 "commit exit=${RC}; HEAD moved=$([ "$now" = "$2" ] && echo no || echo yes); stderr: $(flat "$ERR")"; fi
}
expect_commit_accepted() {
  local now; now="$(head_sha)"
  if [ "$RC" -eq 0 ] && [ "$now" != "$2" ]; then report "$1" 1
  else report "$1" 0 "commit exit=${RC}; stderr: $(flat "$ERR")"; fi
}
expect_push_refused() { # <name> <ref> <sha-that-must-not-land>
  local got; got="$(remote_sha "$2")"
  if [ "$RC" -ne 0 ] && [ "$got" != "$3" ] && has "$ERR" '[git-pre-push-pii]'; then report "$1" 1
  else report "$1" 0 "push exit=${RC}; remote $2=${got:-<absent>}; stderr: $(flat "$ERR")"; fi
}
expect_push_accepted() { # <name> <ref> <sha-that-must-land>
  local got; got="$(remote_sha "$2")"
  if [ "$RC" -eq 0 ] && [ "$got" = "$3" ]; then report "$1" 1
  else report "$1" 0 "push exit=${RC}; remote $2=${got:-<absent>} (want $3); stderr: $(flat "$ERR")"; fi
}

# A geometry for running the detector directly (L, X and C arms).
GEOM="${SBX}/geom"; /bin/mkdir -p "$GEOM"
DET=""
if [ -r "$DET_SRC" ]; then /bin/cp "$DET_SRC" "${GEOM}/git-pre-commit-homes.sh"; DET="${GEOM}/git-pre-commit-homes.sh"; fi
OUT=""; DRC=0
det() { # det <args...> ; runs the detector in the current repo ($REPO); sets OUT, DRC
  if [ -z "$DET" ]; then OUT="the detector is absent"; DRC=127; return; fi
  OUT="$(cd "$REPO" && /usr/bin/env HOME="$HOMEDIR" /bin/bash -p "$DET" "$@" 2>&1)"; DRC=$?
}

# =============================================================================
# W. Wiring and fail-closed
# =============================================================================
report "T8022-W0 the detector is readable beside the suite's source (${DET_SRC})" "$([ -r "$DET_SRC" ] && echo 1 || echo 0)"
report "precondition: the resolver lib is findable in this layout" "$([ -n "$LIB_SRC" ] && echo 1 || echo 0)"

mk_repo w1 no-detector; h="$(head_sha)"; put docs/more.md; g add docs/more.md
commit -- -m benign
if [ "$RC" -ne 0 ] && [ "$(head_sha)" = "$h" ] && has "$ERR" 'in-repo home guard was not found'; then
  report "T8022-W1 with no detector beside the PII guard, a benign commit is refused" 1
else
  report "T8022-W1 with no detector beside the PII guard, a benign commit is refused" 0 "exit=${RC}; stderr: $(flat "$ERR")"
fi
c="$(plumb docs/plumbed.md main)"; g update-ref refs/heads/w2 "$c"
push -- w2
if [ "$RC" -ne 0 ] && [ "$(remote_sha refs/heads/w2)" != "$c" ] && has "$ERR" 'in-repo home guard was not found'; then
  report "T8022-W2 with no detector beside the PII guard, a push is refused and the ref does not land" 1
else
  report "T8022-W2 with no detector beside the PII guard, a push is refused and the ref does not land" 0 "exit=${RC}; stderr: $(flat "$ERR")"
fi
h="$(head_sha)"; put docs/bypass.md; g add docs/bypass.md
commit CLAUDE_HOOK_BYPASS=1 -- -m benign-bypass
if [ "$RC" -ne 0 ] && [ "$(head_sha)" = "$h" ] && has "$ERR" 'in-repo home guard was not found'; then
  report "T8022-W3 with no detector, a benign commit under CLAUDE_HOOK_BYPASS is refused (the commit-time check cannot be skipped by the bypass, so it fails closed)" 1
else
  report "T8022-W3 with no detector, a benign commit under CLAUDE_HOOK_BYPASS is refused (the commit-time check cannot be skipped by the bypass, so it fails closed)" 0 "exit=${RC}; stderr: $(flat "$ERR")"
fi

# =============================================================================
# G. A forced add under a guarded home is refused
# =============================================================================
mk_repo g1; h="$(head_sha)"; put local-state/run.md; g add -f local-state/run.md
commit -- -m g1; expect_commit_refused "T8022-G1 a forced add under /local-state/ is refused" "$h"
mk_repo g2; h="$(head_sha)"; put analysis/x/SUMMARY.md; g add -f analysis/x/SUMMARY.md
commit -- -m g2; expect_commit_refused "T8022-G2 a forced add under /analysis/ is refused" "$h"
mk_repo g3; h="$(head_sha)"; put roadmaps/plan.md; g add -f roadmaps/plan.md
commit -- -m g3; expect_commit_refused "T8022-G3 a forced add under /roadmaps/ is refused" "$h"

# G4 — the PII guard's mode dial never reaches the home guard. The instance home exists
# with no needle file, so the PII guard takes its configured-but-unfilled branch; the dial
# sits at the instance rung the field case uses.
for _m in off warn enforce; do
  case "$_m" in off) _id=G4a ;; warn) _id=G4b ;; enforce) _id=G4c ;; esac
  mk_repo "g4-${_m}"; /bin/mkdir -p "${WS}/pmo-instance"; /usr/bin/printf '%s' "$_m" > "${WS}/pmo-instance/git-pre-commit-pii.mode"
  h="$(head_sha)"; put local-state/run/x.json; g add -f local-state/run/x.json
  commit -- -m "g4-${_m}"
  expect_commit_refused "T8022-${_id} with git-pre-commit-pii.mode=${_m}, a forced add under /local-state/ is refused" "$h"
done
mk_repo g4d; /bin/mkdir -p "${WS}/pmo-instance"; /usr/bin/printf 'off' > "${WS}/pmo-instance/git-pre-commit-pii.mode"
h="$(head_sha)"; put docs/ok2.md; g add docs/ok2.md
commit -- -m g4d; expect_commit_accepted "T8022-G4d control: with the dial at off, a benign commit is accepted (the PII guard alone passes)" "$h"

mk_repo g5; h="$(head_sha)"; cacheinfo Local-State/x.md
commit -- -m g5; expect_commit_refused "T8022-G5 a home named in another case (Local-State/x.md) is refused" "$h"

# G6 — the bypass. The commit-time check runs under it; the push-time check honours it.
mk_repo g6; h="$(head_sha)"; put local-state/x; g add -f local-state/x
commit CLAUDE_HOOK_BYPASS=1 -- -m g6a
expect_commit_refused "T8022-G6a under CLAUDE_HOOK_BYPASS=1, a forced add under /local-state/ is still refused at commit time" "$h"
c6="$(plumb local-state/x main)"; g update-ref refs/heads/g6 "$c6"
det --tree "$c6"
report "T8022-G6b the CI layer's read (--tree) of a bypass-made commit holding local-state/x exits 1" \
  "$([ "$DRC" -eq 1 ] && has "$OUT" 'local-state/x' && echo 1 || echo 0)" "exit=${DRC}; output: $(flat "$OUT")"
push CLAUDE_HOOK_BYPASS=1 -- g6
expect_push_accepted "T8022-G6c residual, recorded: under CLAUDE_HOOK_BYPASS=1 the push-time check honours the bypass, so a plumbed commit holding local-state/x is pushed" refs/heads/g6 "$c6"

# G7 — a partial commit is judged on the index it records (git hands pre-commit a
# temporary index for --only / a pathspec).
mk_repo g7a; h="$(head_sha)"; put docs/ok.md "changed"; put local-state/x; g add -f local-state/x
commit -- -m g7a --only -- docs/ok.md
if [ "$RC" -eq 0 ] && [ "$(head_sha)" != "$h" ] && [ "$(g diff-tree --no-commit-id --name-only -r HEAD)" = "docs/ok.md" ]; then
  report "T8022-G7a a partial commit naming docs/ok.md is accepted while local-state/x sits in the real index, and records docs/ok.md alone" 1
else
  report "T8022-G7a a partial commit naming docs/ok.md is accepted while local-state/x sits in the real index, and records docs/ok.md alone" 0 \
    "exit=${RC}; HEAD changes: $(flat "$(g diff-tree --no-commit-id --name-only -r HEAD 2>&1)"); stderr: $(flat "$ERR")"
fi
mk_repo g7b; h="$(head_sha)"; put local-state/x; g add -f local-state/x
commit -- -m g7b --only -- local-state/x
expect_commit_refused "T8022-G7b a partial commit naming local-state/x is refused on the temporary index" "$h"

# =============================================================================
# N. Near-misses
# =============================================================================
mk_repo n1; h="$(head_sha)"
for _h in local-state analysis roadmaps; do put "${_h}/README.md" "# ${_h}, edited"; done
g add local-state/README.md analysis/README.md roadmaps/README.md
commit -- -m n1; expect_commit_accepted "T8022-N1 a commit that edits only the three READMEs is accepted" "$h"
mk_repo n2; h="$(head_sha)"; cacheinfo local-state/readme.md
commit -- -m n2; expect_commit_refused "T8022-N2 local-state/readme.md (the README in another case) is refused" "$h"
mk_repo n3; h="$(head_sha)"; put local-state/sub/README.md; g add -f local-state/sub/README.md
commit -- -m n3; expect_commit_refused "T8022-N3 local-state/sub/README.md (a README below the home's top) is refused" "$h"
mk_repo n4; h="$(head_sha)"; put docs/local-state-notes.md; put local-statements/x.md; put analysisx/y.md
g add docs/local-state-notes.md local-statements/x.md analysisx/y.md
commit -- -m n4; expect_commit_accepted "T8022-N4 similarly named paths (docs/local-state-notes.md, local-statements/x.md, analysisx/y.md) are accepted" "$h"
mk_repo n5; h="$(head_sha)"; g rm -q --cached local-state/README.md; cacheinfo local-state/README.md/x
commit -- -m n5; expect_commit_refused "T8022-N5 local-state/README.md/x (a path through the README's name) is refused" "$h"
# N6 — an inherited tracked home path: removing it passes (the remedy works), keeping it does not.
mk_repo n6; c="$(plumb analysis/x main)"; g update-ref refs/heads/main "$c"; g read-tree HEAD
h="$(head_sha)"; g rm -q --cached analysis/x
commit -- -m n6a; expect_commit_accepted "T8022-N6a git rm --cached of an inherited analysis/x is accepted (the remedy works)" "$h"
mk_repo n6b; c="$(plumb analysis/x main)"; g update-ref refs/heads/main "$c"; g read-tree HEAD
h="$(head_sha)"; put docs/ok.md "changed"; g add docs/ok.md
commit -- -m n6b; expect_commit_refused "T8022-N6b a commit that leaves an inherited analysis/x in the index is refused" "$h"
# N7 — the guard's own read over the source checkout's real tree.
N7_ROWS="$(git -C "$SRC_ROOT" ls-tree -r --name-only HEAD 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
if [ -n "$DET" ]; then
  OUT="$(cd "$SRC_ROOT" && /bin/bash -p "$DET" --tree HEAD 2>&1)"; DRC=$?
else
  OUT="the detector is absent"; DRC=127
fi
_adm="$(/usr/bin/sed -n 's/.*README admitted \([0-9][0-9]*\);.*/\1/p' <<<"$OUT")"
if [ "$DRC" -eq 0 ] && has "$OUT" "examined ${N7_ROWS} path row(s)" && [ -n "$_adm" ] && [ "$_adm" -ge 2 ]; then
  report "T8022-N7 --tree HEAD over the source checkout: exit 0, every path examined (${N7_ROWS}), at least two READMEs admitted" 1
else
  report "T8022-N7 --tree HEAD over the source checkout: exit 0, every path examined (${N7_ROWS}), at least two READMEs admitted" 0 "exit=${DRC}; output: $(flat "$OUT")"
fi

# =============================================================================
# P. The push arm reads every commit pre-commit never reads
# =============================================================================
mk_repo p1; c="$(plumb analysis/x main)"; g update-ref refs/heads/p1 "$c"
push -- p1; expect_push_refused "T8022-P1 a plumbed commit adding analysis/x is refused at push" refs/heads/p1 "$c"
mk_repo p2; c="$(plumb roadmaps/x main)"; g update-ref refs/heads/side "$c"
g merge -q --no-ff --no-edit side >/dev/null 2>&1; m="$(head_sha)"
push -- main; expect_push_refused "T8022-P2 a --no-ff merge bringing in a plumbed roadmaps/x commit is refused at push" refs/heads/main "$m"
mk_repo p3; c="$(plumb local-state/y main)"; g update-ref refs/heads/side "$c"
g cherry-pick side >/dev/null 2>&1; m="$(head_sha)"
if [ "$m" != "$(remote_sha refs/heads/main)" ]; then
  push -- main; expect_push_refused "T8022-P3 a cherry-pick of a plumbed local-state/y commit is refused at push" refs/heads/main "$m"
else
  report "T8022-P3 a cherry-pick of a plumbed local-state/y commit is refused at push" 0 "the cherry-pick made no commit"
fi
mk_repo p4; put roadmaps/README.md "# roadmaps, edited"; g add roadmaps/README.md; commit -- -m p4
m="$(head_sha)"; push -- main
expect_push_accepted "T8022-P4 README-only commits are pushed" refs/heads/main "$m"
mk_repo p5; c="$(plumb analysis/zq-planted-name.md main)"
OUT="$(cd "$REPO" && /usr/bin/printf 'refs/heads/x %s refs/heads/x %s\n' "$c" "$ZEROS" \
        | /usr/bin/env HOME="$HOMEDIR" CLAUDE_WORKSPACE_ROOT="$WS" /bin/bash -p "${REPO}/core/hooks/git-pre-push-pii.sh" origin origin --redact 2>&1)"; DRC=$?
if [ "$DRC" -ne 0 ] && has "$OUT" 'analysis/...' && has "$OUT" "${c:0:12}" && ! has "$OUT" 'zq-planted-name'; then
  report "T8022-P5 the pre-push hook run with --redact (as the push-time CI scan runs it) names the home and the commit, never the planted file name" 1
else
  report "T8022-P5 the pre-push hook run with --redact (as the push-time CI scan runs it) names the home and the commit, never the planted file name" 0 "exit=${DRC}; output: $(flat "$OUT")"
fi

# =============================================================================
# C. The guard's own fixture arms, as the In-repo home content gate runs them first
# =============================================================================
# Run the way the CI job runs it: by its repository-relative path from the repository
# root, so a self-test that loses its own path once it changes directory fails here.
mk_repo c1
if [ -r "${REPO}/core/hooks/git-pre-commit-homes.sh" ]; then
  OUT="$(cd "$REPO" && /usr/bin/env HOME="$HOMEDIR" /bin/bash -p core/hooks/git-pre-commit-homes.sh --self-test 2>&1)"; DRC=$?
else
  OUT="the detector is absent"; DRC=127
fi
report "T8022-C1 --self-test, run by its relative path from the repository root as CI runs it, exits 0 with 17/17 arms passed" \
  "$([ "$DRC" -eq 0 ] && has "$OUT" 'self-test: 17/17 arms passed' && echo 1 || echo 0)" "exit=${DRC}; output: $(flat "$OUT")"

# =============================================================================
# L. The one list, and its parity with the placement standard's table
# =============================================================================
mk_repo l0
det --print-homes
report "T8022-L1 --print-homes prints exactly local-state, analysis and roadmaps, one per line" \
  "$([ "$DRC" -eq 0 ] && [ "$OUT" = "$(/usr/bin/printf 'local-state\nanalysis\nroadmaps')" ] && echo 1 || echo 0)" "exit=${DRC}; output: $(flat "$OUT")"
if [ -r "$STD" ]; then
  det --check-parity "$STD"
  report "T8022-L2 --check-parity against the real placement standard reads AGREE" \
    "$([ "$DRC" -eq 0 ] && has "$OUT" 'AGREE homes=analysis,local-state,roadmaps' && echo 1 || echo 0)" "exit=${DRC}; output: $(flat "$OUT")"
  # mutant <id> <file> <want-exit> <want-token> <desc> : a mutated copy must differ from
  # the source, or the arm is INERT and fails.
  mutant() {
    if /usr/bin/cmp -s "$2" "$STD"; then report "T8022-$1 $5" 0 "INERT: the mutated copy is identical to the standard"; return; fi
    det --check-parity "$2"
    report "T8022-$1 $5" "$([ "$DRC" -eq "$3" ] && has "$OUT" "$4" && echo 1 || echo 0)" "exit=${DRC} (want $3); output: $(flat "$OUT")"
  }
  /usr/bin/awk 'index($0, "| `/roadmaps/` |") != 1' "$STD" > "${SBX}/std-L3.md"
  mutant L3 "${SBX}/std-L3.md" 1 "DISAGREE" "with the /roadmaps/ row deleted from a copy of the standard, parity reads DISAGREE"
  /usr/bin/awk '{ print } index($0, "| `/roadmaps/` |") == 1 { print "| `/scratch/` | Scratch | none | This standard | none |" }' "$STD" > "${SBX}/std-L4.md"
  mutant L4 "${SBX}/std-L4.md" 1 "DISAGREE" "with an extra /scratch/ row in a copy of the standard, parity reads DISAGREE"
  /usr/bin/awk '
    index($0, "| `/local-state/` |") == 1 { held = $0; sub(/\| The repository[^|]*\|/, "| Edited admits cell |", held); next }
    { print }
    index($0, "| `/roadmaps/` |") == 1 { print held }' "$STD" > "${SBX}/std-L5.md"
  mutant L5 "${SBX}/std-L5.md" 0 "AGREE" "with the rows reordered and an Admits cell edited in a copy, parity still reads AGREE"
  /usr/bin/sed 's/^### Registered in-repo git-ignored homes/### Registered homes, renamed/' "$STD" > "${SBX}/std-L6.md"
  mutant L6 "${SBX}/std-L6.md" 2 "TABLE-MISSING" "with the table's heading renamed in a copy, parity exits 2 (TABLE-MISSING)"
else
  for _a in L2 L3 L4 L5 L6; do report "T8022-${_a} parity arm" 0 "the placement standard is not readable at ${STD}"; done
fi

# =============================================================================
# X. The exit contract
# =============================================================================
mk_repo x1
det --tree no-such-rev; _x1="$DRC"
OUT="$(cd "$REPO" && /usr/bin/printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' | /usr/bin/env HOME="$HOMEDIR" /bin/bash -p "${DET:-/nonexistent}" --commits 2>&1)"; _x2=$?
det --no-such-flag; _x3="$DRC"
report "T8022-X1 exit contract: --tree of a missing revision 3, --commits with an absent id 3, an unknown argument 2" \
  "$([ "$_x1" -eq 3 ] && [ "$_x2" -eq 3 ] && [ "$_x3" -eq 2 ] && echo 1 || echo 0)" "exits ${_x1} ${_x2} ${_x3}"

# =============================================================================
# Z. The suite leaves the source checkout as it found it
# =============================================================================
SRC_STATUS_AFTER="$(git -C "$SRC_ROOT" status --porcelain 2>&1)"
report "T8022-Z1 the source checkout's git status is unchanged by this suite" \
  "$([ "$SRC_STATUS_BEFORE" = "$SRC_STATUS_AFTER" ] && echo 1 || echo 0)" "before: $(flat "$SRC_STATUS_BEFORE"); after: $(flat "$SRC_STATUS_AFTER")"

/usr/bin/printf '\nRESIDUAL: these arms run in scratch repositories against local bare remotes. They do not prove\n'
/usr/bin/printf 'RESIDUAL: the hooks are wired in a real checkout (validate-install A3d/A3e do), and a push made\n'
/usr/bin/printf 'RESIDUAL: under CLAUDE_HOOK_BYPASS, with --no-verify, or through the hosting API reaches no local layer.\n'
/usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
