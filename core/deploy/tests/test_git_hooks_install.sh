#!/usr/bin/env bash
# test_git_hooks_install.sh — the installer wires the commit-time PII guard (GHSA-c748).
#
# The hook-class registry classes git-pre-commit-pii.sh as security/floor: always
# enforce, never silently disabled. A guard that nothing installs as a git hook is
# fully off, however correct its own logic is. This suite pins the install, not the
# guard's patterns (core/hooks/tests/git-pre-commit-pii.test.sh owns those).
#
# The sandbox source repo is a COPY of this checkout's tracked and untracked
# (non-ignored) files, given its own `git init`. It is never a clone and never a
# worktree: a worktree shares the operator's hooks directory, so running the
# installer against one would write the operator's live hooks. The copy sits INSIDE
# the sandbox workspace root, which is the documented layout and the only one the
# installer wires git hooks for without PMO_INSTALL_GIT_HOOKS.
#
#   Arm 1 — a fresh install links <hooks>/pre-commit to an executable
#           git-pre-commit-pii.sh in the main worktree. post-merge stays wired.
#   Arm 2 — the wired guard REFUSES a commit whose added line carries a home path,
#           and ACCEPTS a benign commit (the control: it does not refuse everything).
#   Arm 3 — the update path (--refresh-hooks, which update.sh Phase 5c runs) re-wires
#           a guard that went missing.
#   Arm 4 — a stale link of our own (pointing at a git-pre-commit-pii.sh that no
#           longer exists, e.g. inside a swept worktree) is re-pointed, never left
#           dangling: git ignores a dangling hook without a word.
#   Arm 5 — a DIFFERENT pre-commit hook the operator installed is left untouched,
#           and the run warns that the PII guard is not active. A3d FAILs it, never
#           PASSes a hook that only names the guard, and FAILs a byte copy of it.
#   Arm 6 — a source repo outside the workspace root is not wired (the test suites
#           pass the real checkout that way) and the run prints the manual step.
#   Arm 7 — with a few hundred linked worktrees (the operator's real shape), re-bootstrap
#           and validate-install still run: no early-exit reader in a pipefail pipeline.
#   Arm 8 — the remediation users are told to run, a real update.sh, re-wires an unwired
#           guard and does not exit EX_NOCHANGE; a second run leaves it alone. (Runs
#           before Arm 7 in the file, so it is not slowed by Arm 7's worktrees.)
#   Arm 9 — A3d judges the hook at one hop, as the guard resolves itself: a chain of links
#           and a link to another copy of the guard FAIL (refresh re-points the copy), and
#           a global core.hooksPath is neither wired nor FAILed, with the reason printed.
#
# Arms 1-2 are RED on an installer that wires only post-merge — measured, which is
# how this suite was written. Darwin-only (setup-workspace.sh's check_platform).
set -uo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'SKIP: test_git_hooks_install.sh — setup-workspace.sh is Darwin-only\n'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# GIT_HOOKS_TEST_REPO_ROOT lets the suite run from stdin (`bash -s`), where $0 names
# the shell rather than this file; unset, the repo root is derived from this file's path.
REPO_ROOT="${GIT_HOOKS_TEST_REPO_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
unset PMO_INSTANCE_PATH PMO_INSTALL_GIT_HOOKS CLAUDE_HOOK_BYPASS
export GIT_CONFIG_NOSYSTEM=1

PASS=0
FAIL=0
SBX=""
cleanup() { if [ -n "${SBX}" ] && [ -d "${SBX}" ]; then /bin/rm -rf "${SBX}"; fi; }
trap cleanup EXIT

report() {
  if [ "$2" = "1" ]; then printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else printf '  FAIL: %s\n' "$1"; [ -n "${3:-}" ] && printf '         %s\n' "$3"; FAIL=$((FAIL + 1)); fi
}

# Resolve a path through every symlink level to its physical location ("" if it does
# not resolve to an existing file). bash 3.2-portable: no realpath, no readlink -f.
resolve_path() {
  local p="$1" link n=0
  while [ -L "${p}" ] && [ "${n}" -lt 16 ]; do
    link="$(readlink "${p}")"
    case "${link}" in /*) p="${link}" ;; *) p="$(dirname "${p}")/${link}" ;; esac
    n=$((n + 1))
  done
  [ -e "${p}" ] || { printf ''; return; }
  printf '%s/%s' "$(cd "$(dirname "${p}")" && pwd -P)" "$(basename "${p}")"
}

SBX="$(mktemp -d -t git-hooks-install.XXXXXX)"
SBX="$(cd "${SBX}" && pwd -P)"
WS="${SBX}/ws"
SRC="${WS}/pmo-platform"
CFG="${SBX}/config"
export HOME="${SBX}/home"
mkdir -p "${SRC}" "${CFG}" "${HOME}" "${SBX}/cowork"

# --- Build the sandbox source repo from this checkout's working tree ---
( cd "${REPO_ROOT}" && git ls-files -z --cached --others --exclude-standard \
    | while IFS= read -r -d '' f; do [ -e "${f}" ] && printf '%s\0' "${f}"; done \
    | tar --null -T - -cf - ) | ( cd "${SRC}" && tar -xf - )
git -C "${SRC}" init -q
git -C "${SRC}" config user.name "Hooks Test"
git -C "${SRC}" config user.email "hooks-test@example.com"
git -C "${SRC}" config commit.gpgsign false
git -C "${SRC}" add -A
git -C "${SRC}" commit -q -m "sandbox snapshot" || { echo "FAIL: sandbox snapshot commit"; exit 1; }

cat > "${CFG}/operator.toml" <<TOML
[meta]
schema_version = 1
managed_by = "pmo-platform"

[identity]
operator_name = "Test Operator"
operator_email = "test@example.com"
operator_git_email = "test@example.com"
operator_github = "test-handle"
operator_phone = ""
operator_role_title = "Test Role"
operator_organization = "Test Org"

[paths]
claude_workspace_root = "${WS}"
operator_homedir_path = "${HOME}"
cowork_install_path = "${SBX}/cowork"
pmo_platform_repo_name = "pmo-platform"

[platform]
work_board = "github"
comms_platform = ""
TOML
chmod 600 "${CFG}/operator.toml"

SETUP="${SRC}/docs/scripts/setup-workspace.sh"
HD="$(git -C "${SRC}" rev-parse --path-format=absolute --git-path hooks)"
GUARD="${SRC}/core/hooks/git-pre-commit-pii.sh"

# --- Arm 1: fresh install wires the guard ---
printf '\nArm 1. Fresh install links pre-commit to the PII guard\n'
out="$("${SETUP}" --source-repo "${SRC}" --workspace-root "${WS}" --config-root "${CFG}" < <(yes "") 2>&1)"
rc=$?
report "fresh install exits 0" "$([ "${rc}" -eq 0 ] && echo 1 || echo 0)" "exit ${rc}; tail: $(printf '%s' "${out}" | tail -3 | tr '\n' '|')"
got="$(resolve_path "${HD}/pre-commit")"
report "pre-commit resolves to the main worktree's git-pre-commit-pii.sh" \
  "$([ -n "${got}" ] && [ "${got}" = "$(resolve_path "${GUARD}")" ] && echo 1 || echo 0)" \
  "pre-commit resolves to '${got:-<nothing>}'"
report "the resolved guard is executable" "$([ -n "${got}" ] && [ -x "${got}" ] && echo 1 || echo 0)"
report "post-merge is still wired" "$([ -n "$(resolve_path "${HD}/post-merge")" ] && echo 1 || echo 0)"

validate() {
  HOME="${HOME}" PMO_USER_SETTINGS_FILE="${SBX}/no-such-user-settings.json" \
    bash "${SRC}/docs/scripts/validate-install.sh" --mode install \
      --source-repo "${SRC}" --workspace-root "${WS}" \
      --validation-dir "${WS}/.workspace-validation/run-$1" 2>&1
}
out="$(validate wired)"
report "validate-install A3d PASSes on the wired guard" \
  "$(grep -q '^\[A3d\] PASS' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"

# --- Arm 2: the wired guard actually refuses a home path, and only that ---
printf '\nArm 2. The wired guard refuses a home-path commit and accepts a benign one\n'
# Built at runtime so this file's own added lines never carry the pattern.
home_line="see $(printf '/%s/%s/%s' Users jdoe notes.txt) for the notes"
printf '%s\n' "${home_line}" > "${SRC}/hooks-test-pii.txt"
git -C "${SRC}" add hooks-test-pii.txt
if git -C "${SRC}" commit -q -m "add a home path" >/dev/null 2>&1; then
  report "a home-path commit is refused" 0 "the commit was ACCEPTED"
  git -C "${SRC}" reset -q --hard HEAD~1
else
  report "a home-path commit is refused" 1
  git -C "${SRC}" reset -q
  /bin/rm -f "${SRC}/hooks-test-pii.txt"
fi
printf 'a benign line\n' > "${SRC}/hooks-test-benign.txt"
git -C "${SRC}" add hooks-test-benign.txt
if git -C "${SRC}" commit -q -m "add a benign line" >/dev/null 2>&1; then
  report "control: a benign commit is accepted" 1
else
  report "control: a benign commit is accepted" 0 "the guard refused a benign commit"
fi

refresh() {
  "${SETUP}" --refresh-hooks --source-repo "${SRC}" --workspace-root "${WS}" --config-root "${CFG}" 2>&1
}

# --- Arm 3: the update path re-wires a missing guard ---
printf '\nArm 3. --refresh-hooks (the update path) re-wires a missing guard\n'
/bin/rm -f "${HD}/pre-commit"
out="$(refresh)"; rc=$?
report "refresh exits 0" "$([ "${rc}" -eq 0 ] && echo 1 || echo 0)" "exit ${rc}; tail: $(printf '%s' "${out}" | tail -3 | tr '\n' '|')"
report "refresh re-wires pre-commit to the guard" \
  "$([ "$(resolve_path "${HD}/pre-commit")" = "$(resolve_path "${GUARD}")" ] && echo 1 || echo 0)"
# update.sh decides "changed anything?" from REFRESHED/MODE-REPAIRED/RECONCILED/WIRED; an
# INSTALLED line would let an update that wired the guard exit EX_NOCHANGE.
report "the wiring is logged WIRED:, a token update.sh counts as a change" \
  "$(grep -q 'WIRED: PII pre-commit guard' <<<"${out}" && echo 1 || echo 0)"
report "update.sh counts WIRED: as a change" \
  "$(grep -qF "RECONCILED:|WIRED:'" "${SRC}/update.sh" && echo 1 || echo 0)"

# --- Arm 4: a dangling link of our own is re-pointed ---
printf '\nArm 4. A stale link to a vanished guard is re-pointed\n'
/bin/rm -f "${HD}/pre-commit"
ln -s "${SBX}/swept-worktree/core/hooks/git-pre-commit-pii.sh" "${HD}/pre-commit"
out="$(validate dangling)"
report "validate-install A3d FAILs on a dangling guard link" \
  "$(grep -q '^\[A3d\] FAIL.*dangling' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"
out="$(refresh)"
report "the dangling link is re-pointed at the live guard" \
  "$([ "$(resolve_path "${HD}/pre-commit")" = "$(resolve_path "${GUARD}")" ] && echo 1 || echo 0)" \
  "pre-commit -> $(readlink "${HD}/pre-commit" 2>/dev/null)"

# --- Arm 5: a foreign pre-commit hook is preserved, and the run says so ---
printf '\nArm 5. A different pre-commit hook is left in place, with a warning\n'
/bin/rm -f "${HD}/pre-commit"
printf '#!/bin/sh\n# operator-owned hook\nexit 0\n' > "${HD}/pre-commit"
chmod +x "${HD}/pre-commit"
before="$(cksum < "${HD}/pre-commit")"
out="$(refresh)"
report "the foreign hook's content is unchanged" "$([ "$(cksum < "${HD}/pre-commit")" = "${before}" ] && [ ! -L "${HD}/pre-commit" ] && echo 1 || echo 0)"
report "the run warns that the PII guard is not active" \
  "$(grep -q 'WARN.*PII pre-commit guard NOT active' <<<"${out}" && echo 1 || echo 0)" \
  "no 'PII pre-commit guard NOT active' warning in the refresh output"
out="$(validate foreign)"
report "validate-install A3d FAILs on a foreign hook" \
  "$(grep -q '^\[A3d\] FAIL.*different hook' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"
# Naming the guard is not running it: a comment is enough to mention it.
printf '#!/bin/sh\n# git-pre-commit-pii.sh is off for now\nexit 0\n' > "${HD}/pre-commit"
out="$(validate mention)"
report "A3d never PASSes a hook that only names the guard (SKIP, not PASS)" \
  "$(grep -q '^\[A3d\] SKIP' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"
# A byte copy resolves its library and needle list from the hooks dir, so it runs degraded.
/bin/cp "${GUARD}" "${HD}/pre-commit"; chmod +x "${HD}/pre-commit"
out="$(validate copy)"
report "A3d FAILs on a copy of the guard (not a link)" \
  "$(grep -q '^\[A3d\] FAIL.*copy of the guard' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"

# --- Arm 6: a source repo outside the workspace root is not wired ---
printf '\nArm 6. A source repo outside the workspace root is told, not wired\n'
/bin/rm -f "${HD}/pre-commit"
WS2="${SBX}/ws-elsewhere"; mkdir -p "${WS2}"
out="$("${SETUP}" --dry-run --source-repo "${SRC}" --workspace-root "${WS2}" --config-root "${CFG}" < <(yes "") 2>&1)"
report "the run prints the manual pre-commit step" \
  "$(grep -q 'git-pre-commit-pii.sh.*/pre-commit' <<<"${out}" && echo 1 || echo 0)"
report "no pre-commit link is created" "$([ ! -e "${HD}/pre-commit" ] && [ ! -L "${HD}/pre-commit" ] && echo 1 || echo 0)"

# --- Arm 8: the remediation users are told to run — a real update.sh — re-wires ---
# Arm 3 drives the delegate directly; this runs the entrypoint the advisory names, end to
# end, and pins its exit: an update that wired the guard must not report EX_NOCHANGE (64).
printf '\nArm 8. A real update.sh re-wires an unwired guard, and says it changed something\n'
[ -L "${HD}/pre-commit" ] || [ -e "${HD}/pre-commit" ] && /bin/rm -f "${HD}/pre-commit"
out="$("${SRC}/update.sh" --config-root "${CFG}" --workspace-root "${WS}" 2>&1)"
rc=$?
report "update.sh re-wires pre-commit to the guard" \
  "$([ "$(resolve_path "${HD}/pre-commit")" = "$(resolve_path "${GUARD}")" ] && echo 1 || echo 0)" \
  "exit ${rc}; tail: $(tail -3 <<<"${out}" | tr '\n' '|')"
report "update.sh does not exit EX_NOCHANGE after wiring (exit ${rc})" "$([ "${rc}" -ne 64 ] && echo 1 || echo 0)"
out="$("${SRC}/update.sh" --config-root "${CFG}" --workspace-root "${WS}" 2>&1)"
report "a second update.sh leaves the wired guard alone (logs OK, not WIRED)" \
  "$(grep -q 'OK: PII pre-commit guard already wired' <<<"${out}" && ! grep -q 'WIRED: PII pre-commit guard' <<<"${out}" && echo 1 || echo 0)"

# --- Arm 9: states where A3d and the guard must agree ---
# The guard follows ONE link to find its library and needle list, so A3d judges one hop:
# a chain of links runs the guard degraded; a link to another copy (a worktree's, which a
# branch can disable) is not the guard the main worktree carries. And a core.hooksPath set
# outside the repository's own config names a hooks dir other repositories share.
printf '\nArm 9. A chain of links, another copy of the guard, a shared core.hooksPath\n'
/bin/rm -f "${HD}/pre-commit"
mkdir -p "${SBX}/share"; ln -s "${GUARD}" "${SBX}/share/pii"; ln -s "${SBX}/share/pii" "${HD}/pre-commit"
out="$(validate chain)"
report "A3d FAILs a chain of links (the guard follows one hop)" \
  "$(grep -q '^\[A3d\] FAIL.*chain of links' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"
/bin/rm -f "${HD}/pre-commit"
mkdir -p "${SBX}/other-worktree/core/hooks"
printf '#!/usr/bin/env bash\n# git-pre-commit-pii.sh, disabled on a branch\nexit 0\n' > "${SBX}/other-worktree/core/hooks/git-pre-commit-pii.sh"
chmod +x "${SBX}/other-worktree/core/hooks/git-pre-commit-pii.sh"
ln -s "${SBX}/other-worktree/core/hooks/git-pre-commit-pii.sh" "${HD}/pre-commit"
out="$(validate othercopy)"
report "A3d FAILs a link to another copy of the guard (never SKIP or PASS)" \
  "$(grep -q '^\[A3d\] FAIL.*another copy of the guard' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"
out="$(refresh)"
report "refresh re-points a link to another copy at the main worktree's guard" \
  "$([ "$(resolve_path "${HD}/pre-commit")" = "$(resolve_path "${GUARD}")" ] && echo 1 || echo 0)"
/bin/rm -f "${HD}/pre-commit"
mkdir -p "${SBX}/global-hooks"
git config --global core.hooksPath "${SBX}/global-hooks"
out="$(refresh)"
report "a global core.hooksPath is not wired, and the run says why" \
  "$([ ! -e "${SBX}/global-hooks/pre-commit" ] && [ ! -L "${SBX}/global-hooks/pre-commit" ] && grep -q 'NOTE: PII pre-commit guard not auto-wired: core.hooksPath' <<<"${out}" && echo 1 || echo 0)"
out="$(validate globalhooks)"
report "A3d SKIPs a global core.hooksPath rather than FAILing with a remedy that cannot work" \
  "$(grep -q '^\[A3d\] SKIP.*outside this repository' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: $(grep -m1 '^\[A3d\]' <<<"${out}")"
git config --global --unset core.hooksPath

# --- Arm 7: a repo with many linked worktrees still installs and validates ---
# Reading `git worktree list` through a reader that exits early (awk … exit) under
# `set -Eeuo pipefail` turns git's EPIPE into the pipeline's status once the list outgrows
# one write. The operator's repo carries a few hundred worktrees; a one-worktree sandbox
# cannot see the abort, so this arm adds enough --no-checkout worktrees to make it certain.
printf '\nArm 7. Many linked worktrees: re-bootstrap and validate-install still run\n'
/bin/rm -f "${HD}/pre-commit"
i=0
while [ "${i}" -lt 200 ]; do
  git -C "${SRC}" worktree add -q --no-checkout --detach \
    "${SBX}/many-worktrees/a-linked-worktree-with-a-deliberately-long-name-to-fill-the-list-${i}" 2>/dev/null
  i=$((i + 1))
done
wl_bytes="$(git -C "${SRC}" worktree list --porcelain | wc -c | tr -d ' ')"
report "precondition: the worktree list outgrows one pipe write (${wl_bytes} bytes)" \
  "$([ "${wl_bytes}" -gt 32768 ] && echo 1 || echo 0)"
out="$("${SETUP}" --source-repo "${SRC}" --workspace-root "${WS}" --config-root "${CFG}" < <(yes "") 2>&1)"
rc=$?
report "re-bootstrap exits 0 with many worktrees" "$([ "${rc}" -eq 0 ] && echo 1 || echo 0)" \
  "exit ${rc}; tail: $(printf '%s' "${out}" | tail -3 | tr '\n' '|')"
report "re-bootstrap wires the guard with many worktrees" \
  "$([ "$(resolve_path "${HD}/pre-commit")" = "$(resolve_path "${GUARD}")" ] && echo 1 || echo 0)"
out="$(validate many)"
report "validate-install reaches an A3d verdict with many worktrees" \
  "$(grep -q '^\[A3d\] PASS' <<<"${out}" && echo 1 || echo 0)" \
  "A3d line: '$(grep -m1 '^\[A3d\]' <<<"${out}")'; tail: $(tail -2 <<<"${out}" | tr '\n' '|')"

# The member contract of run-install-regression.sh: "<name>: N passed, M failed".
printf '\ntest_git_hooks_install.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
[ "${FAIL}" -eq 0 ]
