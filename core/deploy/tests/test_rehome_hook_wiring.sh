#!/usr/bin/env bash
# test_rehome_hook_wiring.sh — regression for #4436 (setup-workspace.sh --rehome-hook-wiring).
#
# The PreToolUse hook wiring lives only in the workspace-PROJECT settings file, which
# Claude Code loads only when the session's project root resolves to the workspace root.
# Sessions rooted in the repo or in a worktree — and every subagent they spawn — load no
# hooks at all, which is why the script allowlist has never governed the path release
# close-out actually runs on. `--rehome-hook-wiring` merges the PreToolUse object into the
# USER-scope settings surface, which every session resolves regardless of project root.
#
# Asserts the merge contract, which is where the blast radius lives:
#   1. PreToolUse is written, with the workspace-root token resolved
#   2. SessionStart and Stop are NOT written — installing the template wholesale would
#      register a per-assistant-turn Stop hook the operator never opted into
#   3. unrelated top-level keys in the target are preserved (the real
#      ~/.claude/settings.json carries operator keys a clobbering write would destroy)
#   4. a pre-existing UNRELATED hook event in the target is preserved
#   5. idempotent — a second run reports unchanged and leaves the file byte-equal
#   6. an absent target is created; a backup is taken only when one already existed
#   7. --dry-run mutates nothing
#   8. an invalid existing target fails closed rather than silently replacing it
#   9. no OTHER flow performs the re-home (it writes outside the workspace root and
#      turns enforcement on, so it must stay an explicit operator act) — while still
#      SURFACING the command, or the enforcement point is undiscoverable
#
# Self-contained: every write lands under an mktemp sandbox, including the user-scope
# target (via --user-settings). Never touches the operator's live ~/.claude. bash 3.2-safe.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
SBX="$(mktemp -d -t rehome-wiring.XXXXXX)"
trap 'rm -rf "${SBX}"' EXIT

PASS=0
FAIL=0
report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '         %s\n' "${detail}"; FAIL=$((FAIL + 1)); fi
}

# q FILE MODE [ARG] — small explicit-mode JSON reader (no eval; each mode is a named,
# auditable query rather than an arbitrary expression).
#   valid                -> "yes" | "no"
#   groups               -> number of PreToolUse matcher groups
#   registrations        -> total wired commands across all PreToolUse groups
#   has-event EVENT      -> "yes" | "no"
#   has-matcher M        -> "yes" | "no" (a PreToolUse matcher string)
#   top KEY              -> the top-level scalar at KEY (empty when absent)
#   env KEY              -> the scalar at .env.KEY (empty when absent)
#   first-command        -> the first wired PreToolUse command string
q() {
  python3 - "$@" <<'PY'
import json, sys
path, mode = sys.argv[1], sys.argv[2]
arg = sys.argv[3] if len(sys.argv) > 3 else ""
try:
    with open(path) as f:
        d = json.load(f)
except Exception:
    print("no" if mode == "valid" else "")
    sys.exit(0)
hooks = d.get("hooks", {}) if isinstance(d, dict) else {}
pre = hooks.get("PreToolUse", [])
if mode == "valid":
    print("yes")
elif mode == "groups":
    print(len(pre))
elif mode == "registrations":
    print(sum(len(g.get("hooks", [])) for g in pre))
elif mode == "has-event":
    print("yes" if arg in hooks else "no")
elif mode == "has-matcher":
    print("yes" if any(g.get("matcher") == arg for g in pre) else "no")
elif mode == "top":
    v = d.get(arg, "")
    print(v if isinstance(v, str) else json.dumps(v))
elif mode == "env":
    print(d.get("env", {}).get(arg, ""))
elif mode == "first-command":
    print(pre[0]["hooks"][0]["command"] if pre and pre[0].get("hooks") else "")
else:
    print("")
PY
}

# Minimal workspace: the mode only requires a deployed .claude/hooks directory.
make_ws() {
  local ws="$1" h
  mkdir -p "${ws}/.claude/hooks/lib"
  for h in "${REPO_ROOT}/core/hooks/"*.sh; do cp "${h}" "${ws}/.claude/hooks/"; done
  chmod +x "${ws}/.claude/hooks/"*.sh
}

rehome() {
  local ws="$1" target="$2"; shift 2
  bash "${SETUP}" --rehome-hook-wiring \
    --workspace-root "${ws}" --source-repo "${REPO_ROOT}" --user-settings "${target}" "$@" 2>&1
}

printf '\nCase 1-4: PreToolUse merged · SessionStart/Stop excluded · unrelated keys and events preserved\n'
WS="${SBX}/ws1"; make_ws "${WS}"
TGT="${SBX}/home1/.claude/settings.json"
mkdir -p "$(dirname "${TGT}")"
cat > "${TGT}" <<'JSON'
{
  "model": "opus",
  "env": {"FOO": "bar"},
  "hooks": {
    "SessionEnd": [{"matcher": "*", "hooks": [{"type": "command", "command": "/bin/true"}]}]
  }
}
JSON
RC=0
OUT="$(rehome "${WS}" "${TGT}")" || RC=$?
[ "${RC}" -eq 0 ] && report "exit 0" 1 || report "exit 0" 0 "rc=${RC} out=${OUT}"
[ "$(q "${TGT}" valid)" = "yes" ] && report "target is valid JSON" 1 || report "target is valid JSON" 0 "${OUT}"

# NOTE: deliberately NOT named GROUPS. `GROUPS` is a bash-maintained special variable
# (the invoking user's group IDs); assigning to it is silently ignored, so the assertion
# would have compared the user's GID — a number that happens to be >= 1 on every macOS
# account — and passed regardless of what the merge produced. That is a false-green of
# exactly the shape this release exists to eliminate, caught here by cross-checking the
# count against an independent read of the same file.
PRE_GROUPS="$(q "${TGT}" groups)"
[ "${PRE_GROUPS:-0}" -eq 6 ] 2>/dev/null && report "PreToolUse present with all 6 matcher groups" 1 \
  || report "PreToolUse present with all 6 matcher groups" 0 "groups=${PRE_GROUPS}"

PRE_REGS="$(q "${TGT}" registrations)"
[ "${PRE_REGS:-0}" -eq 22 ] 2>/dev/null && report "all 22 PreToolUse registrations merged" 1 \
  || report "all 22 PreToolUse registrations merged" 0 "registrations=${PRE_REGS}"

# Control arm: a matcher the template does NOT declare must be absent. Without a
# known-negative the two counts above only prove the object is non-empty.
[ "$(q "${TGT}" has-matcher NotebookEdit)" = "no" ] && report "control: undeclared matcher absent" 1 \
  || report "control: undeclared matcher absent" 0 "NotebookEdit present"

# The excluded events are the whole point of the PreToolUse-only scoping.
[ "$(q "${TGT}" has-event Stop)" = "no" ] && report "Stop event NOT registered (no per-turn hook added)" 1 \
  || report "Stop event NOT registered" 0 "Stop present"
[ "$(q "${TGT}" has-event SessionStart)" = "no" ] && report "SessionStart event NOT registered" 1 \
  || report "SessionStart event NOT registered" 0 "SessionStart present"

# Preservation.
[ "$(q "${TGT}" top model)" = "opus" ] && report "unrelated top-level key preserved (model)" 1 || report "unrelated top-level key preserved (model)" 0 "lost"
[ "$(q "${TGT}" env FOO)" = "bar" ] && report "unrelated nested key preserved (env.FOO)" 1 || report "unrelated nested key preserved (env.FOO)" 0 "lost"
[ "$(q "${TGT}" has-event SessionEnd)" = "yes" ] && report "pre-existing unrelated hook event preserved (SessionEnd)" 1 || report "pre-existing unrelated hook event preserved" 0 "SessionEnd lost"

# Token resolution: an unresolved command path would be a wired hook that can never fire.
UNRES="$(grep -c 'CLAUDE_WORKSPACE_ROOT' "${TGT}" 2>/dev/null || true)"
[ "${UNRES:-0}" -eq 0 ] && report "workspace-root token resolved (0 residual)" 1 || report "workspace-root token resolved" 0 "${UNRES} residual"
CMD="$(q "${TGT}" first-command)"
case "${CMD}" in
  "${WS}"/*) report "commands point at the deployed workspace hooks" 1 ;;
  *) report "commands point at the deployed workspace hooks" 0 "got ${CMD}" ;;
esac

# Backup of a pre-existing target.
[ -f "${TGT}.pmo-bak" ] && report "pre-existing target backed up" 1 || report "pre-existing target backed up" 0 "no .pmo-bak"

printf '\nCase 5: idempotent — a second run leaves the file equal and says so\n'
BEFORE="$(shasum -a 256 "${TGT}" | awk '{print $1}')"
OUT2="$(rehome "${WS}" "${TGT}")"
AFTER="$(shasum -a 256 "${TGT}" | awk '{print $1}')"
[ "${BEFORE}" = "${AFTER}" ] && report "second run leaves the target byte-identical" 1 || report "second run leaves the target byte-identical" 0 "sha changed"
printf '%s' "${OUT2}" | grep -q 'unchanged (idempotent re-run)' \
  && report "second run reports unchanged" 1 || report "second run reports unchanged" 0 "${OUT2}"

printf '\nCase 6: absent target is created\n'
WS2="${SBX}/ws2"; make_ws "${WS2}"
TGT2="${SBX}/home2/.claude/settings.json"
OUT3="$(rehome "${WS2}" "${TGT2}")"
if [ -f "${TGT2}" ] && [ "$(q "${TGT2}" groups)" -eq 6 ] 2>/dev/null; then
  report "absent target created with PreToolUse" 1
else
  report "absent target created with PreToolUse" 0 "${OUT3}"
fi
[ -f "${TGT2}.pmo-bak" ] && report "no backup written when no target existed" 0 "stray .pmo-bak" \
  || report "no backup written when no target existed" 1

printf '\nCase 7: --dry-run mutates nothing\n'
WS3="${SBX}/ws3"; make_ws "${WS3}"
TGT3="${SBX}/home3/.claude/settings.json"
OUT4="$(rehome "${WS3}" "${TGT3}" --dry-run)"
[ ! -e "${TGT3}" ] && report "--dry-run created no target" 1 || report "--dry-run created no target" 0 "file exists"
printf '%s' "${OUT4}" | grep -q 'dry-run' && report "--dry-run announced the planned merge" 1 || report "--dry-run announced the planned merge" 0 "${OUT4}"

printf '\nCase 8: an invalid existing target fails closed\n'
WS4="${SBX}/ws4"; make_ws "${WS4}"
TGT4="${SBX}/home4/.claude/settings.json"
mkdir -p "$(dirname "${TGT4}")"
printf 'this is not json' > "${TGT4}"
RC4=0
OUT5="$(rehome "${WS4}" "${TGT4}")" || RC4=$?
[ "${RC4}" -ne 0 ] && report "invalid target exits non-zero" 1 || report "invalid target exits non-zero" 0 "rc=0 out=${OUT5}"
[ "$(cat "${TGT4}")" = "this is not json" ] && report "invalid target left untouched" 1 || report "invalid target left untouched" 0 "target was rewritten"

printf '\nCase 9: no other flow performs the re-home (it must stay an explicit operator act)\n'
WS5="${SBX}/ws5"; make_ws "${WS5}"
TGT5="${SBX}/home5/.claude/settings.json"
NOTE="$(bash "${SETUP}" --refresh-hooks --workspace-root "${WS5}" --source-repo "${REPO_ROOT}" \
  --user-settings "${TGT5}" 2>&1 || true)"
[ ! -e "${TGT5}" ] && report "--refresh-hooks does NOT write the user-scope surface" 1 \
  || report "--refresh-hooks does NOT write the user-scope surface" 0 "target was written"
printf '%s' "${NOTE}" | grep -q -- '--rehome-hook-wiring' \
  && report "hook install surfaces the re-home command" 1 \
  || report "hook install surfaces the re-home command" 0 "notice absent"

printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "${PASS}" "${FAIL}"
[ "${FAIL}" -eq 0 ] || exit 1
exit 0
