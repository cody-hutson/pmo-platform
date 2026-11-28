#!/bin/bash
# tests/git-pre-commit-pii-env-inputs.test.sh — the commit-time PII guard
# (core/hooks/git-pre-commit-pii.sh) against its environment and attribute inputs.
#
# WHAT THIS EXISTS TO CATCH. Git runs the guard in the committer's environment, so a
# one-word prefix on `git commit` reaches every input the guard reads from it. Before
# this suite's fix, each of these let a staged coworker/org needle hit through:
#   PMO_LOCALIZED_NEEDLES, PMO_INSTANCE_PATH, CLAUDE_WORKSPACE_ROOT, HOME
# and each of these let EVERY hit through, home paths and phone numbers included:
#   GIT_EXTERNAL_DIFF, `git -c diff.external=`, a textconv driver, a function exported
#   through the environment (BASH_FUNC_<name>%%), BASH_ENV, and an attribute marking
#   paths binary (`-diff`, staged or reached through GIT_CONFIG_GLOBAL).
#
# WHY EVERY ARM COMMITS THROUGH A REAL `git commit`. Part of the fix is the guard's
# shebang (`bash -p`), which only applies when git executes the hook. An arm that ran
# `/bin/bash "$HOOK"` would skip the shebang and could not fail. So each arm builds the
# installer's geometry — <ws>/pmo-platform/core/hooks/ holding the guard, core/deploy/
# holding the resolver, .git/hooks/pre-commit a relative symlink to the guard — and
# commits. The one exception is S1, which pins the direct-run spelling sandboxed test
# runs use, and is run that way on purpose.
#
# BASELINE ENVIRONMENT. Each commit runs with the inputs under test cleared and HOME set
# so that $HOME/Claude IS the arm's workspace root: the environment and the guard's own
# install then resolve to the same instance home, which is the live install's shape.
# Each arm then adds its one prefix. GIT_CONFIG_NOSYSTEM and a sandbox HOME keep a host
# core.hooksPath from silently skipping the hook; K1 is the arm that would show it.
#
# The positive arms FAIL against the guard as it was before this fix (measured), and the
# controls pass against both. That is the evidence this suite can fail.

set -u

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK_SRC="${SRC_DIR}/git-pre-commit-pii.sh"
[ -r "$HOOK_SRC" ] || { echo "FAIL: hook not readable at $HOOK_SRC" >&2; exit 1; }

PASS=0; FAIL=0
report() { # report <name> <ok:1|0> [detail]
  if [ "$2" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s\n  %s\n' "$1" "${3:-}"; FAIL=$((FAIL+1)); fi
}
oneline() { /usr/bin/printf '%s' "$1" | /usr/bin/tr '\n' '|' | /usr/bin/cut -c1-400; }

SBX="$(mktemp -d 2>/dev/null)"; SBX="$(cd "$SBX" && pwd -P)"
cleanup() { [ -n "${SBX:-}" ] && /bin/rm -rf "$SBX"; }
trap cleanup EXIT

# The resolver sits at ../deploy/ in the source tree and beside the hook in the
# materialized CI layout; either is the file under test.
LIB_SRC=""
for _cand in "${SRC_DIR}/../deploy/lib-instance-path.sh" "${SRC_DIR}/lib-instance-path.sh"; do
  [ -r "$_cand" ] && { LIB_SRC="$_cand"; break; }
done
if [ -z "$LIB_SRC" ]; then
  report "precondition: the resolver lib is findable in this layout" 0 "no lib-instance-path.sh near ${SRC_DIR}"
  /usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"; exit 1
fi
report "precondition: the resolver lib is findable in this layout" 1

# Fixture strings. The home path is assembled at run time so this file's own added lines
# never carry the pattern the guard refuses.
NEEDLE="acme-widgets-internal"
NEEDLE_B="orbital-pancake-ledger"
HP="$(/usr/bin/printf '/%s/%s/%s' Users jdoe notes.txt)"
NEEDLE_LINE="contact ${NEEDLE} for details"
HOME_LINE="see ${HP} for the notes"
BENIGN_LINE="a benign line"

# arm_setup <name> — fresh workspace + repo in the installer's geometry. Sets WS, HOMEDIR,
# REPO, INST (the instance home both sides resolve to by default; not created here).
WS=""; HOMEDIR=""; REPO=""; INST=""
arm_setup() {
  HOMEDIR="${SBX}/$1/home"; WS="${HOMEDIR}/Claude"; REPO="${WS}/pmo-platform"; INST="${WS}/pmo-instance"
  /bin/mkdir -p "${REPO}/core/hooks" "${REPO}/core/deploy"
  /bin/cp "$HOOK_SRC" "${REPO}/core/hooks/git-pre-commit-pii.sh"
  /bin/cp "$(dirname "$HOOK_SRC")/git-pre-commit-homes.sh" "${REPO}/core/hooks/git-pre-commit-homes.sh"
  /bin/chmod +x "${REPO}/core/hooks/git-pre-commit-pii.sh"
  /bin/cp "$LIB_SRC" "${REPO}/core/deploy/lib-instance-path.sh"
  /usr/bin/git -C "$REPO" init -q 2>/dev/null
  /usr/bin/git -C "$REPO" config user.name "PII Env Test"
  /usr/bin/git -C "$REPO" config user.email "pii-env-test@example.com"
  /usr/bin/git -C "$REPO" config commit.gpgsign false
  /bin/ln -s ../../core/hooks/git-pre-commit-pii.sh "${REPO}/.git/hooks/pre-commit"
}
# mk_inst <dir> <mode-or-empty> <needle-or-empty>
mk_inst() {
  /bin/mkdir -p "$1"
  [ -n "${2:-}" ] && /usr/bin/printf '%s' "$2" > "$1/git-pre-commit-pii.mode"
  [ -n "${3:-}" ] && /usr/bin/printf '%s\n' "$3" > "$1/localized-context-needles.txt"
  return 0
}
stage_line() { # stage_line <line> [file]
  /usr/bin/printf '%s\n' "$1" > "${REPO}/${2:-staged.txt}"
  /usr/bin/git -C "$REPO" add -- "${2:-staged.txt}"
}

# do_commit [NAME=VALUE ...] -> RC, ERR. GITARGS (global) goes before `commit`.
# UNSET_HOME=1 runs the commit with HOME removed instead of set.
RC=0; ERR=""; GITARGS=""; UNSET_HOME=0
do_commit() {
  local tmp; tmp="$(/usr/bin/mktemp)"
  local homearg="HOME=${HOMEDIR}" unsets="-u CLAUDE_HOOK_BYPASS"
  if [ "$UNSET_HOME" = 1 ]; then homearg="GIT_CONFIG_NOSYSTEM=1"; unsets="-u CLAUDE_HOOK_BYPASS -u HOME"; fi
  RC=0
  # shellcheck disable=SC2086  # GITARGS / unsets are deliberately word-split
  /usr/bin/env -u CLAUDE_WORKSPACE_ROOT -u PMO_INSTANCE_PATH -u PMO_LOCALIZED_NEEDLES \
    -u PMO_PEOPLE_ROSTER -u GIT_CONFIG_GLOBAL -u XDG_CONFIG_HOME -u GIT_CONFIG_COUNT \
    -u GIT_CONFIG_PARAMETERS -u GIT_EXTERNAL_DIFF -u BASH_ENV $unsets \
    "$homearg" GIT_CONFIG_NOSYSTEM=1 "$@" \
    /usr/bin/git -C "$REPO" $GITARGS commit -q -m probe >/dev/null 2>"$tmp" || RC="$?"
  ERR="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
}
expect_refused() { # expect_refused <name>
  if [ "$RC" != 0 ]; then report "$1" 1; else report "$1" 0 "commit was ACCEPTED. stderr: $(oneline "$ERR")"; fi
}
expect_accepted() { # expect_accepted <name>
  if [ "$RC" = 0 ]; then report "$1" 1; else report "$1" 0 "commit was REFUSED (rc=$RC). stderr: $(oneline "$ERR")"; fi
}

# --- PRECONDITION: the resolver loaded and the anchor resolved. With neither home on
#     disk, a loaded resolver names <ws>/pmo-instance in its NOTE; the lib-unreachable
#     stubs name the empty string, and then no arm below would be evidence.
arm_setup p0; stage_line "$BENIGN_LINE"; do_commit
if /usr/bin/grep -qF "${INST}" <<<"$ERR"; then
  report "precondition: the resolver LOADED (the hook names ${INST})" 1
else
  report "precondition: the resolver LOADED (the hook names ${INST})" 0 "stderr: $(oneline "$ERR")"
fi

# =============================================================================
# K — CONTROLS. The harness can refuse, and does not refuse everything.
# =============================================================================
arm_setup k1; mk_inst "$INST" "" "$NEEDLE"; stage_line "$NEEDLE_LINE"; do_commit
expect_refused "K1 SENSITIVITY: needle hit, no prefix -> refused"
arm_setup k2; mk_inst "$INST" "" "$NEEDLE"; stage_line "$BENIGN_LINE"; do_commit
expect_accepted "K2 control: benign line, no prefix -> accepted"
arm_setup k3; mk_inst "$INST" "" "$NEEDLE"; stage_line "$HOME_LINE"; do_commit
expect_refused "K3 SENSITIVITY: home path, no prefix -> refused"

# =============================================================================
# N — THE NEEDLE TIER UNDER ONE PREFIX. Live shape: needle file filled, no .mode.
# =============================================================================
/bin/mkdir -p "${SBX}/decoy"
/usr/bin/printf 'harmless-token\n' > "${SBX}/decoy/localized-context-needles.txt"
n_arm() { # n_arm <name> NAME=VALUE...
  local name="$1"; shift
  arm_setup "n$((PASS + FAIL))"; mk_inst "$INST" "" "$NEEDLE"; stage_line "$NEEDLE_LINE"; do_commit "$@"
  expect_refused "$name"
}
n_arm "N1 PMO_LOCALIZED_NEEDLES=/dev/null -> still refused"            PMO_LOCALIZED_NEEDLES=/dev/null
n_arm "N2 PMO_LOCALIZED_NEEDLES=<harmless one-line file> -> refused"   PMO_LOCALIZED_NEEDLES="${SBX}/decoy/localized-context-needles.txt"
n_arm "N3 PMO_LOCALIZED_NEEDLES=<missing file> -> refused"             PMO_LOCALIZED_NEEDLES="${SBX}/no-such-file"
n_arm "N4 PMO_INSTANCE_PATH=<missing dir> -> refused"                  PMO_INSTANCE_PATH="${SBX}/no-such-dir"
n_arm "N5 PMO_INSTANCE_PATH=<decoy instance> -> refused"               PMO_INSTANCE_PATH="${SBX}/decoy"
n_arm "N6 CLAUDE_WORKSPACE_ROOT=<missing dir> -> refused"              CLAUDE_WORKSPACE_ROOT="${SBX}/no-such-ws"
n_arm "N7 HOME=<missing dir> -> refused"                               HOME="${SBX}/no-such-home"
n_arm "N8 HOME= (empty) -> refused"                                    HOME=
UNSET_HOME=1; n_arm "N9 HOME unset -> refused"; UNSET_HOME=0

# =============================================================================
# M — THE SEVERITY DIAL. A prefix can tighten it, never loosen it below what the
#     anchored home states; a side with no .mode states nothing.
# =============================================================================
mk_inst "${SBX}/decoy-off" "off" ""
mk_inst "${SBX}/decoy-enforce" "enforce" ""
arm_setup m1; mk_inst "$INST" "enforce" ""; stage_line "$BENIGN_LINE"
do_commit PMO_INSTANCE_PATH="${SBX}/decoy-off"
expect_refused "M1 anchored .mode=enforce + needles missing + env decoy .mode=off -> refused"
arm_setup m2; mk_inst "$INST" "enforce" ""; stage_line "$BENIGN_LINE"; do_commit
expect_refused "M2 control: anchored .mode=enforce + needles missing, no prefix -> refused"
arm_setup m3; mk_inst "$INST" "off" ""; stage_line "$BENIGN_LINE"
do_commit PMO_INSTANCE_PATH="${SBX}/decoy-enforce"
expect_refused "M3 anchored .mode=off + env decoy .mode=enforce -> refused (a prefix tightens)"
arm_setup m4; mk_inst "$INST" "" ""; stage_line "$BENIGN_LINE"; do_commit
if [ "$RC" = 0 ] && /usr/bin/grep -q 'BLOCKED' <<<"$ERR"; then
  report "M4 control: no .mode anywhere + needles missing -> loud but accepted (warn default)" 1
else
  report "M4 control: no .mode anywhere + needles missing -> loud but accepted (warn default)" 0 "rc=$RC stderr: $(oneline "$ERR")"
fi

# =============================================================================
# S — THE ENVIRONMENT STILL WORKS FOR WHAT IT IS FOR: sandboxed runs, relocated
#     instances, and adding a list.
# =============================================================================
# S1: the direct-run spelling sandboxed test runs use (`PMO_INSTANCE_PATH=… bash <hook>`).
arm_setup s1; mk_inst "${SBX}/s1-inst" "" "$NEEDLE"
for _s1 in "$NEEDLE_LINE:refused" "$BENIGN_LINE:accepted"; do
  _line="${_s1%:*}"; _want="${_s1##*:}"
  /usr/bin/printf '%s\n' "$_line" > "${REPO}/staged.txt"; /usr/bin/git -C "$REPO" add staged.txt
  _tmp="$(/usr/bin/mktemp)"; RC=0
  ( cd "$REPO" && /usr/bin/env -u CLAUDE_WORKSPACE_ROOT -u PMO_LOCALIZED_NEEDLES -u CLAUDE_HOOK_BYPASS \
      HOME="${SBX}/s1-home" PMO_INSTANCE_PATH="${SBX}/s1-inst" /bin/bash "${REPO}/core/hooks/git-pre-commit-pii.sh" ) \
    >/dev/null 2>"$_tmp" || RC="$?"
  ERR="$(/bin/cat "$_tmp")"; /bin/rm -f "$_tmp"
  if [ "$_want" = refused ]; then expect_refused "S1 direct run, PMO_INSTANCE_PATH=<sandbox>: needle hit -> refused"
  else expect_accepted "S1 direct run, PMO_INSTANCE_PATH=<sandbox>: benign -> accepted"; fi
done
# S2: a relocated instance (anchored home absent) keeps its list and its dial.
arm_setup s2; mk_inst "${SBX}/s2-inst" "" "$NEEDLE"; stage_line "$NEEDLE_LINE"
do_commit PMO_INSTANCE_PATH="${SBX}/s2-inst"
expect_refused "S2 relocated instance via PMO_INSTANCE_PATH: its needle hit -> refused"
arm_setup s2b; mk_inst "${SBX}/s2b-inst" "off" ""; stage_line "$BENIGN_LINE"
do_commit PMO_INSTANCE_PATH="${SBX}/s2b-inst"
if [ "$RC" = 0 ] && ! /usr/bin/grep -q 'BLOCKED' <<<"$ERR"; then
  report "S2b relocated instance's own .mode=off (anchor states nothing) -> honoured, silent" 1
else
  report "S2b relocated instance's own .mode=off (anchor states nothing) -> honoured, silent" 0 "rc=$RC stderr: $(oneline "$ERR")"
fi
# S3: the environment ADDS a list; the anchored list stays in force beside it.
/usr/bin/printf '%s\n' "$NEEDLE_B" > "${SBX}/extra-needles.txt"
arm_setup s3; mk_inst "$INST" "" "$NEEDLE"; stage_line "uses ${NEEDLE_B} internally"
do_commit PMO_LOCALIZED_NEEDLES="${SBX}/extra-needles.txt"
expect_refused "S3a env-added list: its hit -> refused"
arm_setup s3b; mk_inst "$INST" "" "$NEEDLE"; stage_line "$NEEDLE_LINE"
do_commit PMO_LOCALIZED_NEEDLES="${SBX}/extra-needles.txt"
expect_refused "S3b env-added list: the anchored list's hit -> still refused"

# =============================================================================
# W — PREFIXES THAT SKIPPED THE WHOLE GUARD (home-path line; needles filled).
# =============================================================================
/usr/bin/printf 'exit 0\n' > "${SBX}/exit0.sh"
w_arm() { # w_arm <name> NAME=VALUE...   (GITARGS honoured)
  local name="$1"; shift
  arm_setup "w$((PASS + FAIL))"; mk_inst "$INST" "" "$NEEDLE"; stage_line "$HOME_LINE"; do_commit "$@"
  expect_refused "$name"
}
w_arm "W1 GIT_EXTERNAL_DIFF=/usr/bin/true -> refused"                  GIT_EXTERNAL_DIFF=/usr/bin/true
w_arm "W2 exported function replacing grep (BASH_FUNC_grep%%) -> refused" 'BASH_FUNC_grep%%=() { return 1; }'
w_arm "W3 BASH_ENV=<file holding exit 0> -> refused"                   BASH_ENV="${SBX}/exit0.sh"
GITARGS="-c diff.external=/usr/bin/true"
w_arm "W4 git -c diff.external=/usr/bin/true commit -> refused"
GITARGS=""
# W5: a textconv driver that prints nothing, selected by a staged attribute.
arm_setup w5; mk_inst "$INST" "" "$NEEDLE"
/usr/bin/printf '*.txt diff=scrub\n' > "${REPO}/.gitattributes"; /usr/bin/git -C "$REPO" add .gitattributes
stage_line "$HOME_LINE"
GITARGS="-c diff.scrub.textconv=/usr/bin/true"; do_commit; GITARGS=""
expect_refused "W5 textconv driver that prints nothing (attribute + -c) -> refused"

# =============================================================================
# E — INPUTS bash -p LEAVES ALONE, neutralised by the guard itself.
# =============================================================================
# E1: BSD grep reads GREP_OPTIONS; -q emptied every scan.
w_arm "E1 GREP_OPTIONS=-q -> refused"                                  GREP_OPTIONS=-q
# E2: POSIX mode made the needle scan's process substitution a syntax error.
arm_setup e2; mk_inst "$INST" "" "$NEEDLE"; stage_line "$NEEDLE_LINE"; do_commit POSIXLY_CORRECT=1
expect_refused "E2 POSIXLY_CORRECT=1, needle hit -> refused"
# E3: CDPATH redirected the guard's own relative `cd`, dropping it onto the stubs
#     (needle tier off). Needs a planted <dir>/.git/hooks to take effect.
/bin/mkdir -p "${SBX}/cdpath-decoy/.git/hooks" "${SBX}/cdpath-decoy/core/hooks" "${SBX}/cdpath-decoy/core/deploy"
arm_setup e3; mk_inst "$INST" "" "$NEEDLE"; stage_line "$NEEDLE_LINE"; do_commit CDPATH="${SBX}/cdpath-decoy"
expect_refused "E3 CDPATH=<planted dir>, needle hit -> refused"
# E4: under a UTF-8 locale macOS tr stops at an invalid byte sequence and passes
#     nothing on, so a binary staged BEFORE a text file hid the text file. (Where the
#     locale is not installed it falls back to C and this arm cannot fail.)
arm_setup e4; mk_inst "$INST" "" "$NEEDLE"
/usr/bin/printf '\377\376\200\201bin\000\377junk\n\376\375' > "${REPO}/aaa.bin"
/usr/bin/printf '%s\n' "$HOME_LINE" > "${REPO}/zzz.txt"; /usr/bin/git -C "$REPO" add aaa.bin zzz.txt
do_commit LC_ALL=en_US.UTF-8
expect_refused "E4 LC_ALL=en_US.UTF-8, invalid-UTF-8 binary staged before a home path -> refused"

# =============================================================================
# B — BINARY CONTENT IS READ AS TEXT.
# =============================================================================
# B1: a real binary file (NUL bytes) carrying an embedded home path.
arm_setup b1; mk_inst "$INST" "" "$NEEDLE"
/usr/bin/printf '\000\001PK%s\000\002' "$HP" > "${REPO}/blob.bin"; /usr/bin/git -C "$REPO" add blob.bin
do_commit; expect_refused "B1 binary file with an embedded home path -> refused"
# B2: a staged attribute marking every path binary.
arm_setup b2; mk_inst "$INST" "" "$NEEDLE"
/usr/bin/printf '* -diff\n' > "${REPO}/.gitattributes"; /usr/bin/git -C "$REPO" add .gitattributes
stage_line "$HOME_LINE"; do_commit
expect_refused "B2 staged .gitattributes '* -diff' + home path -> refused"
# B3: the same attribute reached through GIT_CONFIG_GLOBAL.
/usr/bin/printf '* -diff\n' > "${SBX}/attrs-all-binary"
/usr/bin/printf '[core]\n\tattributesFile = %s\n' "${SBX}/attrs-all-binary" > "${SBX}/gitconfig-attrs"
arm_setup b3; mk_inst "$INST" "" "$NEEDLE"; stage_line "$HOME_LINE"
do_commit GIT_CONFIG_GLOBAL="${SBX}/gitconfig-attrs"
expect_refused "B3 GIT_CONFIG_GLOBAL=<core.attributesFile '* -diff'> + home path -> refused"
# B4: the repo's real binaries (the packages/*.skill zips) do not trip the scan.
# The packages sit beside core/ in a source checkout. Under the deployed-layout sandbox the
# hook-test floor builds (setup-ci-layout.sh --sandbox, as run-install-regression.sh runs
# it), nothing near this file carries them, so the .source-repo-root pointer that helper
# writes beside the materialized tests is the rung that resolves there. No rung resolving
# is a FAIL, never a skip: the control would otherwise grade nothing while reading green.
PKG_DIR=""
_pkg_src_root=""
if [ -r "$(dirname "$0")/.source-repo-root" ]; then
  IFS= read -r _pkg_src_root < "$(dirname "$0")/.source-repo-root" || true
fi
for _cand in "${SRC_DIR}/../../packages" "${SRC_DIR}/../../../packages" "${_pkg_src_root:+${_pkg_src_root}/packages}"; do
  [ -n "$_cand" ] || continue
  if [ -d "$_cand" ] && /bin/ls "$_cand"/*.skill >/dev/null 2>&1; then PKG_DIR="$(cd "$_cand" && pwd -P)"; break; fi
done
if [ -z "$PKG_DIR" ]; then
  report "B4 control: the repo's packages/*.skill zips -> accepted" 0 "no packages/*.skill found near ${SRC_DIR} or under the .source-repo-root pointer (${_pkg_src_root:-<none>})"
else
  arm_setup b4; mk_inst "$INST" "" "$NEEDLE"
  /bin/mkdir -p "${REPO}/packages"; /bin/cp "$PKG_DIR"/*.skill "${REPO}/packages/"
  /usr/bin/git -C "$REPO" add packages
  do_commit
  _npkg="$(/bin/ls "${REPO}/packages" | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
  expect_accepted "B4 control: the repo's ${_npkg} packages/*.skill zips -> accepted"
fi
# B5: a hit from binary content is shown without its control characters.
arm_setup b5; mk_inst "$INST" "" "$NEEDLE"
/usr/bin/printf '\000\033[2J\033]0;title\007%s\000' "$HP" > "${REPO}/esc.bin"; /usr/bin/git -C "$REPO" add esc.bin
do_commit
_esc="$(/usr/bin/printf '\033')"
case "$ERR" in
  *"$_esc"*) report "B5 binary hit is shown without escape sequences" 0 "stderr carried an ESC byte" ;;
  *) if [ "$RC" != 0 ]; then report "B5 binary hit is shown without escape sequences" 1
     else report "B5 binary hit is shown without escape sequences" 0 "commit was ACCEPTED"; fi ;;
esac

/usr/bin/printf '\nRESIDUAL: PATH / GIT_EXEC_PATH naming a planted executable is NOT covered (see the guard header).\n'
/usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
