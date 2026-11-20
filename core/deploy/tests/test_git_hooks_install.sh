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
#           and the run warns that the PII guard is not active.
#   Arm 6 — a source repo outside the workspace root is not wired (the test suites
#           pass the real checkout that way) and the run prints the manual step.
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
  "$(printf '%s\n' "${out}" | grep -q '^\[A3d\] PASS' && echo 1 || echo 0)" \
  "A3d line: $(printf '%s\n' "${out}" | grep '^\[A3d\]' | head -1)"

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

# --- Arm 4: a dangling link of our own is re-pointed ---
printf '\nArm 4. A stale link to a vanished guard is re-pointed\n'
/bin/rm -f "${HD}/pre-commit"
ln -s "${SBX}/swept-worktree/core/hooks/git-pre-commit-pii.sh" "${HD}/pre-commit"
out="$(validate dangling)"
report "validate-install A3d FAILs on a dangling guard link" \
  "$(printf '%s\n' "${out}" | grep -q '^\[A3d\] FAIL.*dangling' && echo 1 || echo 0)" \
  "A3d line: $(printf '%s\n' "${out}" | grep '^\[A3d\]' | head -1)"
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
  "$(printf '%s' "${out}" | grep -q 'WARN.*PII pre-commit guard NOT active' && echo 1 || echo 0)" \
  "no 'PII pre-commit guard NOT active' warning in the refresh output"

# --- Arm 6: a source repo outside the workspace root is not wired ---
printf '\nArm 6. A source repo outside the workspace root is told, not wired\n'
/bin/rm -f "${HD}/pre-commit"
WS2="${SBX}/ws-elsewhere"; mkdir -p "${WS2}"
out="$("${SETUP}" --dry-run --source-repo "${SRC}" --workspace-root "${WS2}" --config-root "${CFG}" < <(yes "") 2>&1)"
report "the run prints the manual pre-commit step" \
  "$(printf '%s' "${out}" | grep -q 'git-pre-commit-pii.sh.*/pre-commit' && echo 1 || echo 0)"
report "no pre-commit link is created" "$([ ! -e "${HD}/pre-commit" ] && [ ! -L "${HD}/pre-commit" ] && echo 1 || echo 0)"

printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "${PASS}" "${FAIL}"
[ "${FAIL}" -eq 0 ]
