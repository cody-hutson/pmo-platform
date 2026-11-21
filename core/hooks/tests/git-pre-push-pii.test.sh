#!/bin/bash
# tests/git-pre-push-pii.test.sh — the push-time PII backstop (core/hooks/git-pre-push-pii.sh)
# and the commit-range input it runs the commit-time guard with (git-pre-commit-pii.sh
# --commits).
#
# WHAT THIS EXISTS TO CATCH. git runs the commit-time guard only for `git commit`.
# merge, cherry-pick, revert, rebase, stash and commit-tree make commits without it, so
# a push can publish PII that no hook ever read. Section A builds each of those commits
# in a scratch repo with BOTH hooks wired, shows the commit-time guard did not stop it,
# and asserts the push to a local bare remote is refused. Each refusal is checked on
# the remote's side (the ref did not land) and on the hook's (it said why). A control
# with the pre-push hook unwired shows the same push landing, so the refusals are the
# hook's doing and not the test repo's.
#
# Section S covers two reads the commit-time guard itself got wrong before this change:
# a `-diff` attribute (the staged diff showed "Binary files differ" and nothing was
# scanned) and an added line that starts with `++` (dropped as if it were a header).
#
# Section C holds the controls: what must NOT be refused, and the edges of the range.
#
# Section W runs the push-time CI job's own run block, extracted from the workflow file,
# against a scratch server and a full-history runner clone.
#
# RED, MEASURED. Against the guard this change is built on (the environment-input fix
# included), with no pre-push hook, 34 of the 59 arms fail: every refusal in A, S2, the
# hook-presence precondition, the C arms that exercise the new input (C1 liveness, the
# C6 control, C8-C12, C14), and the W arms that need the hook (W1, W2, W4 and its
# control). S1 passes there, because the environment-input fix already reads a
# `-diff` file as text; S2 is this change's. Every control in A and S passes, so those
# refusals fail for the hook's absence and for nothing about the scratch repos. The
# must-not-refuse controls (C1-C7, C13) pass there trivially, with no hook to refuse
# anything. Three arms were measured failing against a mutant instead: C13 against
# this hook before its diff paired renames (-M), the second A14 arm against a report
# that did not strip control bytes, and A15/A16 against a hook that ran without -p and
# ran the guard as `bash "$guard"`. W3 and W5 pass either way: they test the
# workflow's own deletion and not-scanned branches.
#
# PII-shaped fixtures are assembled at run time, so this file's own lines never carry
# the patterns the guard looks for.

set -u

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
GUARD_SRC="${SRC_DIR}/git-pre-commit-pii.sh"
PUSH_SRC="${SRC_DIR}/git-pre-push-pii.sh"

PASS=0; FAIL=0
report() { # report <name> <ok:1|0> [detail]
  if [ "$2" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s\n  %s\n' "$1" "${3:-}"; FAIL=$((FAIL+1)); fi
}
finish() {
  /usr/bin/printf '\nRESIDUAL: these arms run against local bare remotes. They do not prove the hook is\n'
  /usr/bin/printf 'RESIDUAL: wired in any real checkout (validate-install A3e does) or that a push was\n'
  /usr/bin/printf 'RESIDUAL: not made with --no-verify, send-pack or the hosting API (the CI scan covers those).\n'
  /usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ] || exit 1
  exit 0
}

SBX="$(mktemp -d 2>/dev/null)"
SBX="$(cd "$SBX" && pwd -P)"
cleanup() { [ -n "${SBX:-}" ] && /bin/rm -rf "$SBX"; }
trap cleanup EXIT

# --- The hooks' real geometry: core/hooks/ with the resolver at ../deploy/ ---
# Rebuilt from whichever layout this file runs in (source, or the CI layout where the
# resolver sits beside the hooks), as git-pre-commit-pii.test.sh does and for its reason.
GEOM="${SBX}/geom"
/bin/mkdir -p "${GEOM}/core/hooks" "${GEOM}/core/deploy"
LIB_SRC=""
for _cand in "${SRC_DIR}/../deploy/lib-instance-path.sh" "${SRC_DIR}/lib-instance-path.sh"; do
  [ -r "$_cand" ] && { LIB_SRC="$_cand"; break; }
done
report "precondition: the resolver lib is findable in this layout" "$([ -n "$LIB_SRC" ] && echo 1 || echo 0)"
report "precondition: the pre-push hook exists (${PUSH_SRC})" "$([ -r "$PUSH_SRC" ] && echo 1 || echo 0)"
[ -n "$LIB_SRC" ] && /bin/cp "$LIB_SRC" "${GEOM}/core/deploy/lib-instance-path.sh"
/bin/cp "$GUARD_SRC" "${GEOM}/core/hooks/git-pre-commit-pii.sh"
[ -r "$PUSH_SRC" ] && /bin/cp "$PUSH_SRC" "${GEOM}/core/hooks/git-pre-push-pii.sh"
/bin/chmod +x "${GEOM}/core/hooks/"*.sh
GUARD="${GEOM}/core/hooks/git-pre-commit-pii.sh"
PUSHHOOK="${GEOM}/core/hooks/git-pre-push-pii.sh"

HOOKS="${SBX}/hooks"            # both hooks
HOOKS_PC="${SBX}/hooks-pc"      # the commit-time guard only (the state before this change)
/bin/mkdir -p "$HOOKS" "$HOOKS_PC"
/bin/ln -s "$GUARD" "${HOOKS}/pre-commit"
/bin/ln -s "$PUSHHOOK" "${HOOKS}/pre-push"
/bin/ln -s "$GUARD" "${HOOKS_PC}/pre-commit"

export HOME="${SBX}/home"; /bin/mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1
unset PMO_INSTANCE_PATH PMO_LOCALIZED_NEEDLES PMO_PEOPLE_ROSTER CLAUDE_HOOK_BYPASS
unset GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL GIT_AUTHOR_NAME GIT_COMMITTER_NAME
# No operator-instance dir: the needle tier is inactive and the generic patterns enforce.
export CLAUDE_WORKSPACE_ROOT="${SBX}/ws"; /bin/mkdir -p "$CLAUDE_WORKSPACE_ROOT"

# --- Fixtures, assembled so no line of this file matches a pattern ---
HOMEP="$(/usr/bin/printf '/%s/%s/' Users jdoe)notes"
PHONE="$(/usr/bin/printf '%s-%s-%s' 555 867 5309)"
PMAIL="jdoe@$(/usr/bin/printf '%s%s' gma il).com"
NEEDLE="Zorb""lax Industries"
ZEROS="0000000000000000000000000000000000000000"

# --- Scratch repos ---
N=0; R=""; W=""
g() { git -C "$W" "$@"; }
fresh() { # fresh [hooks-dir]: a work repo with origin = a new bare repo, main pushed clean
  N=$((N + 1)); R="${SBX}/r${N}"; W="${R}/work"
  /bin/mkdir -p "$R"
  git init -q --bare "${R}/remote.git"
  git init -q "$W"
  g symbolic-ref HEAD refs/heads/main
  g config user.name "Push Test"; g config user.email "push-test@example.invalid"
  g config commit.gpgsign false; g config tag.gpgsign false
  g config core.hooksPath "${1:-$HOOKS}"
  g remote add origin "${R}/remote.git"
  /usr/bin/printf 'base\n' > "${W}/a.txt"
  g add a.txt; g commit -q -m base
  g push -q origin main 2>/dev/null
}
RC=0; ERR=""
push() { # push <refspec>... ; sets RC and ERR
  local t; t="$(mktemp)"; RC=0
  ( cd "$W" && git push -q origin "$@" ) >/dev/null 2>"$t" || RC=$?
  ERR="$(/bin/cat "$t")"; /bin/rm -f "$t"
}
unhooked_push() { ( cd "$W" && git push -q --no-verify origin "$@" ) >/dev/null 2>&1; }
remote_sha() { git --git-dir="${R}/remote.git" rev-parse -q --verify "$1" 2>/dev/null || true; }
# plumb <path> <content> <message> <parent>... : a commit built with plumbing, so no
# hook runs. The tree is the first parent's with <path> set to <content>.
plumb() {
  local path="$1" content="$2" msg="$3"; shift 3
  local idx="${SBX}/plumb.idx" blob tree p pargs=()
  /bin/rm -f "$idx"
  GIT_INDEX_FILE="$idx" git -C "$W" read-tree "$1"
  blob="$(/usr/bin/printf '%s\n' "$content" | git -C "$W" hash-object -w --stdin)"
  GIT_INDEX_FILE="$idx" git -C "$W" update-index --add --cacheinfo "100644,${blob},${path}"
  tree="$(GIT_INDEX_FILE="$idx" git -C "$W" write-tree)"
  for p in "$@"; do pargs+=(-p "$p"); done
  git -C "$W" commit-tree "$tree" "${pargs[@]}" -m "$msg"
  /bin/rm -f "$idx"
}
nohook_commit() { git -C "$W" -c core.hooksPath=/dev/null commit -q "$@"; }
flat() { /usr/bin/tr '\n' '|' <<<"$1"; }

expect_refused() { # expect_refused <name> <remote-ref> <sha-that-must-not-land>
  local got; got="$(remote_sha "$2")"
  if [ "$RC" -ne 0 ] && [ "$got" != "$3" ] && /usr/bin/grep -qF '[git-pre-push-pii]' <<<"$ERR"; then
    report "$1" 1
  else
    report "$1" 0 "push exit=${RC}; remote $2=${got:-<absent>}; stderr: $(flat "$ERR")"
  fi
}
expect_accepted() { # expect_accepted <name> <remote-ref> <sha-that-must-land>
  local got; got="$(remote_sha "$2")"
  if [ "$RC" -eq 0 ] && [ "$got" = "$3" ]; then
    report "$1" 1
  else
    report "$1" 0 "push exit=${RC}; remote $2=${got:-<absent>} (want $3); stderr: $(flat "$ERR")"
  fi
}

# =============================================================================
# A. Commits the commit-time guard never reads are refused at push time
# =============================================================================

# Control first: without the pre-push hook a commit-tree commit lands. This is the gap.
fresh "$HOOKS_PC"
c="$(plumb pii.txt "call ${PHONE}" "add a note" main)"; g update-ref refs/heads/gap "$c"
push gap
expect_accepted "control: with only the commit-time guard wired, a commit-tree commit carrying a phone number is pushed" refs/heads/gap "$c"

fresh
c="$(plumb pii.txt "call ${PHONE}" "add a note" main)"; g update-ref refs/heads/a1 "$c"
push a1
expect_refused "A1 commit-tree: a phone number in a plumbing-made commit is refused" refs/heads/a1 "$c"

# A2 — revert of a scrub. The home path is already public (pushed before the hook
# existed); a scrub removes it; reverting the scrub puts it back without pre-commit.
fresh
/usr/bin/printf 'see %s\n' "$HOMEP" > "${W}/notes.txt"; g add notes.txt; nohook_commit -m "old note"
unhooked_push main
/usr/bin/printf 'see the notes\n' > "${W}/notes.txt"; g add notes.txt; g commit -q -m scrub
push main
expect_accepted "A2 control: the scrub commit itself is pushed" refs/heads/main "$(g rev-parse HEAD)"
if g revert --no-edit HEAD >/dev/null 2>&1; then
  report "A2 control: git revert made the commit (the commit-time guard did not run)" 1
else
  report "A2 control: git revert made the commit (the commit-time guard did not run)" 0 "revert failed"
fi
c="$(g rev-parse HEAD)"; push main
expect_refused "A2 revert of a scrub: the restored home path is refused" refs/heads/main "$c"

# A3 — cherry-pick of an unpushed commit.
fresh
g checkout -q -b side
/usr/bin/printf 'mail %s\n' "$PMAIL" > "${W}/contact.txt"; g add contact.txt; nohook_commit -m contact
g checkout -q main
if g cherry-pick side >/dev/null 2>&1; then
  report "A3 control: git cherry-pick made the commit (the commit-time guard did not run)" 1
else
  report "A3 control: git cherry-pick made the commit (the commit-time guard did not run)" 0 "cherry-pick failed"
fi
c="$(g rev-parse HEAD)"; push main
expect_refused "A3 cherry-pick: a personal email is refused" refs/heads/main "$c"

# A4 — an evil merge: the merge result carries a line in neither parent.
fresh
g checkout -q -b s; /usr/bin/printf 'side\n' > "${W}/s.txt"; g add s.txt; g commit -q -m side; push s
g checkout -q main
c="$(plumb e.txt "call ${PHONE}" "merge s" main s)"; g update-ref refs/heads/a4 "$c"
push a4
expect_refused "A4 evil merge: a line in neither parent is refused" refs/heads/a4 "$c"

# A5 — git stash makes commits; pushing one publishes the stashed change.
fresh
/usr/bin/printf 'call %s\n' "$PHONE" >> "${W}/a.txt"
if g stash -q 2>/dev/null; then
  report "A5 control: git stash made its commits (the commit-time guard did not run)" 1
else
  report "A5 control: git stash made its commits (the commit-time guard did not run)" 0 "stash failed"
fi
c="$(g rev-parse refs/stash)"; push "refs/stash:refs/heads/a5"
expect_refused "A5 stash: a phone number in a stash commit is refused" refs/heads/a5 "$c"

# A6 — a commit message. The commit-time guard reads content, not messages.
fresh
if g commit -q --allow-empty -m "notes are in ${HOMEP}" 2>/dev/null; then
  report "A6 control: the commit-time guard accepted a message-only home path" 1
else
  report "A6 control: the commit-time guard accepted a message-only home path" 0 "commit refused"
fi
c="$(g rev-parse HEAD)"; push main
expect_refused "A6 commit message: a home path in the message is refused" refs/heads/main "$c"

# A7 — the author identity.
fresh
GIT_AUTHOR_EMAIL="$PMAIL" g commit -q --allow-empty -m "ordinary message" 2>/dev/null
c="$(g rev-parse HEAD)"; push main
expect_refused "A7 author identity: a personal-email author is refused" refs/heads/main "$c"

# A8 — an annotated tag on an already-public commit.
fresh
g tag -a t-call -m "call ${PHONE}"
c="$(g rev-parse t-call)"; push t-call
expect_refused "A8 annotated tag: a phone number in the tag message is refused" refs/tags/t-call "$c"

# A9 — per commit, not net: added in one commit, removed in the next, pushed together.
fresh
c1="$(plumb f.txt "call ${PHONE}" "add" main)"
c2="$(plumb f.txt "call later" "scrub" "$c1")"; g update-ref refs/heads/a9 "$c2"
if /usr/bin/grep -qF "$PHONE" <<<"$(git -C "$W" diff main "$c2")"; then
  report "A9 control: the net diff carries no phone number" 0 "the net diff still carries it"
else
  report "A9 control: the net diff carries no phone number" 1
fi
push a9
expect_refused "A9 per commit: a line added then removed in one push is refused" refs/heads/a9 "$c2"

# A10 — a `-diff` attribute must not hide a file's lines.
fresh
c1="$(plumb .gitattributes '*.md -diff' "attrs" main)"
c2="$(plumb x.md "call ${PHONE}" "md" "$c1")"; g update-ref refs/heads/a10 "$c2"
push a10
expect_refused "A10 -diff attribute: a phone number in a binary-marked file is refused" refs/heads/a10 "$c2"

# A11 — an added line that itself starts with `++`.
fresh
c="$(plumb y.txt "++ see ${HOMEP}" "pp" main)"; g update-ref refs/heads/a11 "$c"
push a11
expect_refused "A11 a '++' line: a home path on an added line starting with ++ is refused" refs/heads/a11 "$c"

# A12 — a ref pointed straight at a tree publishes it unread; refuse.
fresh
t="$(g rev-parse 'HEAD^{tree}')"; push "${t}:refs/tags/a-tree"
expect_refused "A12 a ref at a tree cannot be scanned and is refused" refs/tags/a-tree "$t"

# A13 — a localized-context needle, through the resolver's needle file.
fresh
/bin/mkdir -p "${CLAUDE_WORKSPACE_ROOT}/pmo-instance"
/usr/bin/printf '%s\n' "$NEEDLE" > "${CLAUDE_WORKSPACE_ROOT}/pmo-instance/localized-context-needles.txt"
c="$(plumb org.txt "built for ${NEEDLE}" "org" main)"; g update-ref refs/heads/a13 "$c"
push a13
expect_refused "A13 needle: a coworker/org needle is refused" refs/heads/a13 "$c"
/bin/rm -rf "${CLAUDE_WORKSPACE_ROOT}/pmo-instance"
push a13
expect_accepted "A13 control: without the needle file the same commit is pushed (the needle was the hit)" refs/heads/a13 "$c"

# A14 — binary bytes (NUL, control characters) around the line must not hide it, and
# the report must name it without writing the control bytes through.
fresh
idx="${SBX}/bin.idx"; /bin/rm -f "$idx"
GIT_INDEX_FILE="$idx" git -C "$W" read-tree main
# The control bytes share the hit's line, so the report has to strip them to pass.
blob="$(/usr/bin/printf 'head\000\001\033[2Jcall %s\n' "$PHONE" | git -C "$W" hash-object -w --stdin)"
GIT_INDEX_FILE="$idx" git -C "$W" update-index --add --cacheinfo "100644,${blob},blob.bin"
c="$(git -C "$W" commit-tree "$(GIT_INDEX_FILE="$idx" git -C "$W" write-tree)" -p main -m "binary")"
/bin/rm -f "$idx"; g update-ref refs/heads/a14 "$c"
push a14
expect_refused "A14 binary bytes: a phone number inside a file with NUL and control bytes is refused" refs/heads/a14 "$c"
if /usr/bin/grep -qF 'blob.bin' <<<"$ERR" && ! /usr/bin/grep -q "$(/usr/bin/printf '\033')" <<<"$ERR"; then
  report "A14 the report names the file and writes no escape byte to the terminal" 1
else
  report "A14 the report names the file and writes no escape byte to the terminal" 0 "stderr: $(flat "$ERR")"
fi

# A15/A16 — the pusher's environment cannot replace a command the hook or the guard
# runs. Both are bash -p, so BASH_ENV and exported functions are ignored; a hook that
# ran the guard as `bash "$guard"` would read them again.
fresh
/usr/bin/printf 'grep() { return 1; }\n' > "${SBX}/bash-env.sh"
c="$(plumb pii.txt "call ${PHONE}" "x" main)"; g update-ref refs/heads/a15 "$c"
RC=0; t="$(mktemp)"
( export BASH_ENV="${SBX}/bash-env.sh"; cd "$W" && git push -q origin a15 ) >/dev/null 2>"$t" || RC=$?
ERR="$(/bin/cat "$t")"; /bin/rm -f "$t"
expect_refused "A15 BASH_ENV replacing grep does not silence the push-time scan" refs/heads/a15 "$c"
g update-ref refs/heads/a16 "$c"
RC=0; t="$(mktemp)"
( grep() { return 1; }; export -f grep; cd "$W" && git push -q origin a16 ) >/dev/null 2>"$t" || RC=$?
ERR="$(/bin/cat "$t")"; /bin/rm -f "$t"
expect_refused "A16 an exported grep function does not silence the push-time scan" refs/heads/a16 "$c"

# =============================================================================
# S. The commit-time guard's own read
# =============================================================================
fresh
/usr/bin/printf '*.md -diff\n' > "${W}/.gitattributes"; g add .gitattributes; g commit -q -m attrs
/usr/bin/printf 'call %s\n' "$PHONE" > "${W}/z.md"; g add z.md
if g commit -q -m "md" 2>/dev/null; then
  report "S1 -diff: a staged phone number in a binary-marked file is refused at commit" 0 "the commit was accepted"
  g reset -q --soft HEAD~1
else
  report "S1 -diff: a staged phone number in a binary-marked file is refused at commit" 1
fi
g reset -q
/usr/bin/printf '++ see %s\n' "$HOMEP" > "${W}/w.txt"; g add w.txt
if g commit -q -m "pp" 2>/dev/null; then
  report "S2 '++' line: a staged home path on a line starting with ++ is refused at commit" 0 "the commit was accepted"
  g reset -q --soft HEAD~1
else
  report "S2 '++' line: a staged home path on a line starting with ++ is refused at commit" 1
fi
g reset -q
/usr/bin/printf 'call %s\n' "$PHONE" > "${W}/v.txt"; g add v.txt
if g commit -q -m "v" 2>/dev/null; then
  report "S3 control: an ordinary staged phone number is refused at commit" 0 "the commit was accepted"
  g reset -q --soft HEAD~1
else
  report "S3 control: an ordinary staged phone number is refused at commit" 1
fi
g reset -q
/usr/bin/printf 'an ordinary line\n' > "${W}/u.txt"; g add u.txt
if g commit -q -m "u" 2>/dev/null; then
  report "S4 control: a benign staged change is committed" 1
else
  report "S4 control: a benign staged change is committed" 0 "the commit was refused"
fi

# =============================================================================
# C. Controls: what must not be refused, and the edges of the range
# =============================================================================
fresh
/usr/bin/printf 'more\n' >> "${W}/a.txt"; g add a.txt; g commit -q -m more
c="$(g rev-parse HEAD)"; push main
expect_accepted "C1 a clean commit is pushed" refs/heads/main "$c"
if /usr/bin/grep -qF '[git-pre-push-pii] scanning 1 new commit(s)' <<<"$ERR"; then
  report "C1 liveness: the hook ran and scanned exactly the one new commit" 1
else
  report "C1 liveness: the hook ran and scanned exactly the one new commit" 0 "stderr: $(flat "$ERR")"
fi

# C2 — deleting a branch publishes nothing, even one whose history carries PII.
c="$(plumb pii.txt "call ${PHONE}" "x" main)"; g update-ref refs/heads/old "$c"; unhooked_push old
push ":refs/heads/old"
if [ "$RC" -eq 0 ] && [ -z "$(remote_sha refs/heads/old)" ]; then
  report "C2 a branch deletion is pushed" 1
else
  report "C2 a branch deletion is pushed" 0 "push exit=${RC}; stderr: $(flat "$ERR")"
fi

# C3 — a clean annotated tag.
g tag -a v-clean -m "release notes"
c="$(g rev-parse v-clean)"; push v-clean
expect_accepted "C3 a clean annotated tag is pushed" refs/tags/v-clean "$c"

# C4 — a new branch scans only its own commits, not the public history under it.
fresh
/usr/bin/printf 'call %s\n' "$PHONE" > "${W}/old.txt"; g add old.txt; nohook_commit -m "old"
unhooked_push main
g checkout -q -b nb; /usr/bin/printf 'new work\n' > "${W}/n.txt"; g add n.txt; g commit -q -m "new work"
c="$(g rev-parse HEAD)"; push nb
expect_accepted "C4 a new branch on public history carrying a phone number is pushed (only its own commit is scanned)" refs/heads/nb "$c"

# C5 — a clean merge of a public branch whose own history carries PII is not re-flagged.
fresh
g checkout -q -b s; /usr/bin/printf 'call %s\n' "$PHONE" > "${W}/s.txt"; g add s.txt; nohook_commit -m side
unhooked_push s
g checkout -q main; /usr/bin/printf 'main change\n' > "${W}/m.txt"; g add m.txt; g commit -q -m "main change"
g merge -q --no-edit s >/dev/null 2>&1
c="$(g rev-parse HEAD)"; push main
expect_accepted "C5 a clean merge of a public branch is pushed (main's first-parent diff carries the phone number, the merge adds nothing)" refs/heads/main "$c"

# C6 — the accepted homes keep their personal-email exemption; the same line elsewhere does not.
fresh
c="$(plumb LICENSE "Contact: ${PMAIL}" "license" main)"; g update-ref refs/heads/lic "$c"
push lic
expect_accepted "C6 a personal email in LICENSE (an accepted home) is pushed" refs/heads/lic "$c"
c="$(plumb docs.txt "Contact: ${PMAIL}" "docs" main)"; g update-ref refs/heads/doc "$c"
push doc
expect_refused "C6 control: the same email in an ordinary file is refused" refs/heads/doc "$c"

# C7 — the operator's bypass, set before launch, is honoured.
c="$(plumb pii.txt "call ${PHONE}" "bypassed" main)"; g update-ref refs/heads/byp "$c"
( export CLAUDE_HOOK_BYPASS=1; cd "$W" && git push -q origin byp ) >/dev/null 2>&1
report "C7 CLAUDE_HOOK_BYPASS=1 pushes past the hook" "$([ "$(remote_sha refs/heads/byp)" = "$c" ] && echo 1 || echo 0)"

# C8 — --redact names the commit and the class, never the matched text.
c="$(plumb pii.txt "call ${PHONE}" "x" main)"
out="$(/usr/bin/printf '%s\n' "$c" | (cd "$W" && bash "$GUARD" --commits --redact) 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && /usr/bin/grep -qF "home path or phone number" <<<"$out" && ! /usr/bin/grep -qF "$PHONE" <<<"$out"; then
  report "C8 --redact refuses and prints the class, not the phone number" 1
else
  report "C8 --redact refuses and prints the class, not the phone number" 0 "exit=${rc}; output: $(flat "$out")"
fi
out="$(/usr/bin/printf '%s\n' "$c" | (cd "$W" && bash "$GUARD" --commits) 2>&1)"
report "C8 control: without --redact the report carries the matched line" \
  "$(/usr/bin/grep -qF "$PHONE" <<<"$out" && echo 1 || echo 0)" "output: $(flat "$out")"

# C9 — --needle-file is how CI supplies needles; an unreadable one is refused.
c="$(plumb org.txt "built for ${NEEDLE}" "org" main)"
/usr/bin/printf '%s\n' "$NEEDLE" > "${SBX}/ci-needles.txt"
out="$(/usr/bin/printf '%s\n' "$c" | (cd "$W" && bash "$GUARD" --commits --needle-file "${SBX}/ci-needles.txt") 2>&1)"; rc=$?
report "C9 --needle-file: a needle from the named file is refused" "$([ "$rc" -ne 0 ] && echo 1 || echo 0)" "exit=${rc}; output: $(flat "$out")"
out="$(/usr/bin/printf '%s\n' "$c" | (cd "$W" && bash "$GUARD" --commits) 2>&1)"; rc=$?
report "C9 control: with no needle file the same commit passes (the needle tier was the hit)" "$([ "$rc" -eq 0 ] && echo 1 || echo 0)" "exit=${rc}; output: $(flat "$out")"
out="$(/usr/bin/printf '%s\n' "$c" | (cd "$W" && bash "$GUARD" --commits --needle-file "${SBX}/no-such-file") 2>&1)"; rc=$?
report "C9 an unreadable --needle-file is refused, not downgraded" "$([ "$rc" -ne 0 ] && /usr/bin/grep -qF 'unreadable or holds no entry' <<<"$out" && echo 1 || echo 0)" "exit=${rc}; output: $(flat "$out")"

# C10 — an id that does not resolve is refused, never skipped.
out="$(/usr/bin/printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' | (cd "$W" && bash "$GUARD" --commits) 2>&1)"; rc=$?
report "C10 --commits refuses an id that does not resolve" "$([ "$rc" -ne 0 ] && echo 1 || echo 0)" "exit=${rc}; output: $(flat "$out")"

# C11 — the hook fails closed when the guard is not beside it.
fresh
LONE="${SBX}/lone/core/hooks"; /bin/mkdir -p "$LONE" "${SBX}/hooks-lone"
[ -r "$PUSHHOOK" ] && /bin/cp "$PUSHHOOK" "${LONE}/git-pre-push-pii.sh"
/bin/ln -s "${LONE}/git-pre-push-pii.sh" "${SBX}/hooks-lone/pre-push"
g config core.hooksPath "${SBX}/hooks-lone"
/usr/bin/printf 'more\n' >> "${W}/a.txt"; g add a.txt; g commit -q -m more
c="$(g rev-parse HEAD)"; push main
if [ "$RC" -ne 0 ] && [ "$(remote_sha refs/heads/main)" != "$c" ] && /usr/bin/grep -qF 'guard was not found' <<<"$ERR"; then
  report "C11 a pre-push hook with no guard beside it refuses the push" 1
else
  report "C11 a pre-push hook with no guard beside it refuses the push" 0 "push exit=${RC}; stderr: $(flat "$ERR")"
fi

# C12 — the CI form: the hook run directly, with a public base kept under its own
# remote name and the extra arguments passed through to the guard.
fresh
pub="$(g rev-parse main)"; g update-ref refs/remotes/pii-base/main "$pub"
c="$(plumb pii.txt "call ${PHONE}" "x" main)"
out="$(cd "$W" && /usr/bin/printf 'refs/heads/x %s refs/heads/x %s\n' "$c" "$ZEROS" | bash "$PUSHHOOK" pii-base pii-base --redact 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && /usr/bin/grep -qF 'scanning 1 new commit(s)' <<<"$out" && ! /usr/bin/grep -qF "$PHONE" <<<"$out"; then
  report "C12 CI form: one new commit scanned against the pii-base refs, refused, redacted" 1
else
  report "C12 CI form: one new commit scanned against the pii-base refs, refused, redacted" 0 "exit=${rc}; output: $(flat "$out")"
fi
c2="$(plumb clean.txt "fine" "y" main)"
out="$(cd "$W" && /usr/bin/printf 'refs/heads/y %s refs/heads/y %s\n' "$c2" "$ZEROS" | bash "$PUSHHOOK" pii-base pii-base --redact 2>&1)"; rc=$?
report "C12 control: a clean commit in the CI form passes" "$([ "$rc" -eq 0 ] && echo 1 || echo 0)" "exit=${rc}; output: $(flat "$out")"

# C13 — a pure move of a file whose old line is already public passes, as it does at
# commit time: both reads pair the rename, so the moved line is not "added".
fresh
/usr/bin/printf 'see %s\n' "$HOMEP" > "${W}/keep.txt"; g add keep.txt; nohook_commit -m "old"
unhooked_push main
g mv keep.txt moved.txt
if g commit -q -m "move" 2>/dev/null; then
  report "C13 control: the commit-time guard accepts the pure move" 1
else
  report "C13 control: the commit-time guard accepts the pure move" 0 "commit refused"
fi
c="$(g rev-parse HEAD)"; push main
expect_accepted "C13 a pure move of an already-public line is pushed (rename parity with the staged read)" refs/heads/main "$c"

# C14 — a named remote with no remote-tracking ref scans everything it is sent, and says so.
fresh
git init -q --bare "${R}/empty.git"; g remote add empty "${R}/empty.git"
push_empty() { local t; t="$(mktemp)"; RC=0; ( cd "$W" && git push -q empty "$@" ) >/dev/null 2>"$t" || RC=$?; ERR="$(/bin/cat "$t")"; /bin/rm -f "$t"; }
push_empty main
if [ "$RC" -eq 0 ] && /usr/bin/grep -qF 'no remote-tracking refs for empty' <<<"$ERR" && /usr/bin/grep -qF 'git fetch empty' <<<"$ERR"; then
  report "C14 a push to a remote with no tracking refs is scanned in full and names the fetch that narrows it" 1
else
  report "C14 a push to a remote with no tracking refs is scanned in full and names the fetch that narrows it" 0 "push exit=${RC}; stderr: $(flat "$ERR")"
fi

# =============================================================================
# W. The push-time CI job's own run block, extracted from the workflow file and run
#    against a scratch "server" and a full-history "runner" clone of it
# =============================================================================
WF=""
for _cand in "${SRC_DIR}/../../.github/workflows/pii-push-scan.yml" "${SRC_DIR}/../../../.github/workflows/pii-push-scan.yml"; do
  [ -r "$_cand" ] && { WF="$_cand"; break; }
done
if [ -z "$WF" ]; then
  /usr/bin/printf 'SKIP: W arms: .github/workflows/pii-push-scan.yml is not reachable from this layout\n'
  finish
fi
BLOCK="${SBX}/ci-run-block.sh"
# The step's `run: |` body: every line indented past the key, until the indent drops.
/usr/bin/awk '
  !on && $0 ~ /^[[:space:]]+run: \|[[:space:]]*$/ { on = 1; ind = match($0, /[^ ]/) + 1; next }
  on { if ($0 ~ /^[[:space:]]*$/) { print ""; next }
       if (match($0, /[^ ]/) <= ind) exit
       print substr($0, ind + 1) }' "$WF" > "$BLOCK"
report "W precondition: the run block was extracted from the workflow" \
  "$(/usr/bin/grep -qF 'git-pre-push-pii.sh pii-base pii-base' "$BLOCK" && echo 1 || echo 0)"

SRV="${SBX}/ci/server.git"; SEED="${SBX}/ci/seed"; RUN="${SBX}/ci/runner"
/bin/mkdir -p "${SBX}/ci" "${SEED}/core/hooks" "${SEED}/core/deploy" "${SBX}/ci/tmp"
git init -q --bare "$SRV"
git init -q "$SEED"; git -C "$SEED" symbolic-ref HEAD refs/heads/main
git -C "$SEED" config user.name "Push Test"; git -C "$SEED" config user.email "push-test@example.invalid"
git -C "$SEED" config commit.gpgsign false
/bin/cp "$GUARD" "$PUSHHOOK" "${SEED}/core/hooks/"; /bin/cp "${GEOM}/core/deploy/lib-instance-path.sh" "${SEED}/core/deploy/"
# main's public history carries a phone number already: a branch on it must not be re-read.
/usr/bin/printf 'call %s\n' "$PHONE" > "${SEED}/old.txt"
git -C "$SEED" add -A; git -C "$SEED" commit -q -m base
git -C "$SEED" remote add origin "$SRV"; git -C "$SEED" push -q origin main
ci_run() { # ci_run <pushed-ref> <before> <after> [needles] ; sets RC, OUT, SUM
  # As actions/checkout does on a push: full history, every tag, the pushed commit checked out.
  /bin/rm -rf "$RUN"; git clone -q --no-checkout "$SRV" "$RUN" 2>/dev/null
  git -C "$RUN" fetch -q origin '+refs/tags/*:refs/tags/*' 2>/dev/null
  case "$3" in *[!0]*) git -C "$RUN" checkout -q --detach "$3" 2>/dev/null ;; esac
  : > "${SBX}/ci/tmp/summary"
  RC=0
  OUT="$(cd "$RUN" && env PUSHED_REF="$1" BEFORE_SHA="$2" AFTER_SHA="$3" DEFAULT_BRANCH=main \
         PII_NEEDLES="${4:-}" GITHUB_STEP_SUMMARY="${SBX}/ci/tmp/summary" RUNNER_TEMP="${SBX}/ci/tmp" \
         bash "$BLOCK" 2>&1)" || RC=$?
  SUM="$(/bin/cat "${SBX}/ci/tmp/summary")"
}
git -C "$SEED" checkout -q -b feat
/usr/bin/printf 'call %s\n' "$PHONE" > "${SEED}/n.txt"; git -C "$SEED" add n.txt; git -C "$SEED" commit -q -m note
git -C "$SEED" push -q origin feat
ci_run refs/heads/feat "$ZEROS" "$(git -C "$SEED" rev-parse feat)"
if [ "$RC" -ne 0 ] && /usr/bin/grep -qF 'found private data in this push' <<<"$SUM" \
   && /usr/bin/grep -qF 'n.txt: home path or phone number' <<<"$OUT" \
   && ! /usr/bin/grep -qF "$PHONE" <<<"$OUT" && ! /usr/bin/grep -qF "$PHONE" <<<"$SUM"; then
  report "W1 a pushed branch adding a phone number turns the job red; log and summary stay redacted" 1
else
  report "W1 a pushed branch adding a phone number turns the job red; log and summary stay redacted" 0 "exit=${RC}; log: $(flat "$OUT")"
fi
git -C "$SEED" checkout -q main; git -C "$SEED" checkout -q -b clean
/usr/bin/printf 'fine\n' > "${SEED}/c.txt"; git -C "$SEED" add c.txt; git -C "$SEED" commit -q -m clean
git -C "$SEED" push -q origin clean
ci_run refs/heads/clean "$ZEROS" "$(git -C "$SEED" rev-parse clean)"
report "W2 control: a clean branch on main's history passes (main's own phone number is not re-read)" \
  "$([ "$RC" -eq 0 ] && echo 1 || echo 0)" "exit=${RC}; log: $(flat "$OUT")"
ci_run refs/heads/feat "$(git -C "$SEED" rev-parse feat)" "$ZEROS"
report "W3 control: a branch deletion passes" "$([ "$RC" -eq 0 ] && echo 1 || echo 0)" "exit=${RC}; log: $(flat "$OUT")"
git -C "$SEED" checkout -q main; mbefore="$(git -C "$SEED" rev-parse main)"
/usr/bin/printf 'built for %s\n' "$NEEDLE" > "${SEED}/org.txt"; git -C "$SEED" add org.txt; git -C "$SEED" commit -q -m org
git -C "$SEED" push -q origin main
ci_run refs/heads/main "$mbefore" "$(git -C "$SEED" rev-parse main)" "$NEEDLE"
report "W4 a needle from the PII_NEEDLES secret turns a push to main red (before..after)" \
  "$([ "$RC" -ne 0 ] && /usr/bin/grep -qF 'org.txt: localized-context needle' <<<"$OUT" && ! /usr/bin/grep -qF "$NEEDLE" <<<"$OUT" && echo 1 || echo 0)" \
  "exit=${RC}; log: $(flat "$OUT")"
ci_run refs/heads/main "$mbefore" "$(git -C "$SEED" rev-parse main)"
if [ "$RC" -eq 0 ] && /usr/bin/grep -qF 'PII_NEEDLES secret is unset' <<<"$SUM"; then
  report "W4 control: with the secret unset the same push passes, and the summary says the needle tier is dormant" 1
else
  report "W4 control: with the secret unset the same push passes, and the summary says the needle tier is dormant" 0 "exit=${RC}; summary: $(flat "$SUM")"
fi
# A pushed commit that does not carry the scripts is reported as not scanned, never as a finding.
git -C "$SEED" checkout -q --orphan noscripts; git -C "$SEED" rm -rq --cached . >/dev/null
/usr/bin/printf 'only\n' > "${SEED}/only.txt"; git -C "$SEED" add only.txt; git -C "$SEED" commit -q -m only
git -C "$SEED" push -q origin noscripts
ci_run refs/heads/noscripts "$ZEROS" "$(git -C "$SEED" rev-parse noscripts)"
if [ "$RC" -ne 0 ] && /usr/bin/grep -qF 'not scanned' <<<"$SUM" && ! /usr/bin/grep -qF 'found private data' <<<"$SUM"; then
  report "W5 a pushed commit without the scripts is reported not scanned, not as a finding" 1
else
  report "W5 a pushed commit without the scripts is reported not scanned, not as a finding" 0 "exit=${RC}; summary: $(flat "$SUM")"
fi

finish
