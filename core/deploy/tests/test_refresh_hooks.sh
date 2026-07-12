#!/usr/bin/env bash
# test_refresh_hooks.sh — regression for #3430 (update.sh / setup-workspace.sh --refresh-hooks).
#
# deploy.sh deploys skills + packages but NOT hooks, so a hook/helper security fix reaches
# an already-installed workspace only through the new `setup-workspace.sh --refresh-hooks`
# path (which update.sh's Phase 5c delegates to). This test drives that path directly.
#
# Asserts the checksum-aware, non-interactive refresh contract:
#   1. a STALE deployed hook is refreshed to source
#   2. a never-deployed co-shipped primitive (positional-issueref.awk) is co-deployed
#   3. the operator's .mode is preserved (install-if-missing)
#   4. an operator-EDITED hook (diverged from its recorded baseline) is preserved, not clobbered
#   5. a true no-op (all hooks match source) emits ZERO "REFRESHED" (so update.sh's EX_NOCHANGE
#      contract is not broken by the hook phase)
#   6. --dry-run mutates nothing
#   7. a non-existent workspace fails closed (exit non-zero) rather than scaffolding
#
# Self-contained: builds throwaway workspaces under an mktemp sandbox; never touches the
# operator's live ~/.claude. bash 3.2-safe.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
SBX="$(mktemp -d -t refresh-hooks.XXXXXX)"
trap 'rm -rf "${SBX}"' EXIT

PASS=0
FAIL=0
report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '         %s\n' "${detail}"; FAIL=$((FAIL + 1)); fi
}
sha() { shasum -a 256 "$1" | awk '{print $1}'; }

# deploy_ws <dir> — materialize a workspace with the CURRENT hook bundle + a baseline state.
deploy_ws() {
  local ws="$1" h
  mkdir -p "${ws}/.claude/hooks/lib"
  for h in "${REPO_ROOT}/core/hooks/"*.sh; do cp "${h}" "${ws}/.claude/hooks/"; done
  cp "${REPO_ROOT}/core/hooks/lib/positional-issueref.awk" "${REPO_ROOT}/core/hooks/lib/dep-resolve.sh" "${ws}/.claude/hooks/lib/"
  cp "${REPO_ROOT}/core/deploy/tools/path-leak-patterns.sh" "${ws}/.claude/hooks/" 2>/dev/null || true
  printf 'warn\n' > "${ws}/.claude/hooks/.mode"
  # record baselines = current source SHAs
  python3 - "${REPO_ROOT}" "${ws}/.claude/.workspace-setup.state" <<'PY'
import hashlib, json, glob, os, sys
repo, out = sys.argv[1], sys.argv[2]
cs = {os.path.basename(h): hashlib.sha256(open(h, "rb").read()).hexdigest()
      for h in glob.glob(os.path.join(repo, "core/hooks/*.sh"))}
json.dump({"hook_checksums": cs}, open(out, "w"))
PY
}
refresh() { bash "${SETUP}" --refresh-hooks --workspace-root "$1" --source-repo "${REPO_ROOT}" "${@:2}" 2>&1; }

printf '\nCase 1-3: stale hook refreshed · missing awk co-deployed · .mode preserved\n'
WS="${SBX}/ws1"; deploy_ws "${WS}"
printf '#!/bin/bash\n# STALE\nexit 0\n' > "${WS}/.claude/hooks/block-gh-path-leak.sh"   # stale
rm -f "${WS}/.claude/hooks/lib/positional-issueref.awk"                                 # never-deployed
# make the stale hook look edited-from-baseline? No — record its baseline as the source SHA so
# it is treated as an unedited (old) platform copy and gets refreshed:
python3 - "${REPO_ROOT}" "${WS}/.claude/.workspace-setup.state" <<'PY'
import hashlib, json, glob, os, sys
repo, st = sys.argv[1], sys.argv[2]
d = json.load(open(st)); cs = d.get("hook_checksums", {})
# baseline for the stale hook == its (empty/absent) recorded value; leaving it as the source
# SHA makes target(stale) != baseline -> would PRESERVE. We want the "unedited old version"
# path, so record the STALE hook's baseline as the stale content's SHA:
p = os.path.join(os.path.dirname(st), "hooks", "block-gh-path-leak.sh")
cs["block-gh-path-leak.sh"] = hashlib.sha256(open(p, "rb").read()).hexdigest()
d["hook_checksums"] = cs; json.dump(d, open(st, "w"))
PY
OUT="$(refresh "${WS}")"
grep -q 'path_leak_scan_line' "${WS}/.claude/hooks/block-gh-path-leak.sh" && report "stale hook refreshed to source" 1 || report "stale hook refreshed to source" 0 "still stale"
[ -f "${WS}/.claude/hooks/lib/positional-issueref.awk" ] && report "never-deployed awk co-deployed" 1 || report "never-deployed awk co-deployed" 0
[ "$(cat "${WS}/.claude/hooks/.mode")" = "warn" ] && report ".mode preserved (operator choice)" 1 || report ".mode preserved (operator choice)" 0

printf '\nCase 4: operator-edited hook preserved (not clobbered)\n'
WS="${SBX}/ws2"; deploy_ws "${WS}"
printf '\n# OPERATOR EDIT\n' >> "${WS}/.claude/hooks/block-egress.sh"   # diverge from recorded baseline
OUT="$(refresh "${WS}")"
if grep -q 'OPERATOR EDIT' "${WS}/.claude/hooks/block-egress.sh" && printf '%s' "${OUT}" | grep -q 'PRESERVED (operator-edited): block-egress.sh'; then
  report "operator-edited hook preserved + warned" 1
else report "operator-edited hook preserved + warned" 0 "edit was clobbered or not warned"; fi

printf '\nCase 5: true no-op emits ZERO REFRESHED (EX_NOCHANGE contract intact)\n'
WS="${SBX}/ws3"; deploy_ws "${WS}"
OUT="$(refresh "${WS}")"
n_ref="$(printf '%s' "${OUT}" | grep -c 'REFRESHED:')"
[ "${n_ref}" = "0" ] && report "no-op refresh emits 0 REFRESHED" 1 || report "no-op refresh emits 0 REFRESHED" 0 "got ${n_ref}"

printf '\nCase 6: --dry-run mutates nothing\n'
WS="${SBX}/ws4"; deploy_ws "${WS}"
printf '#!/bin/bash\n# STALE\nexit 0\n' > "${WS}/.claude/hooks/block-egress.sh"
before="$(sha "${WS}/.claude/hooks/block-egress.sh")"
OUT="$(refresh "${WS}" --dry-run)"
after="$(sha "${WS}/.claude/hooks/block-egress.sh")"
[ "${before}" = "${after}" ] && report "--dry-run performs no mutation" 1 || report "--dry-run performs no mutation" 0

printf '\nCase 7: non-existent workspace fails closed\n'
rc=0; bash "${SETUP}" --refresh-hooks --workspace-root "${SBX}/nonexistent" --source-repo "${REPO_ROOT}" >/dev/null 2>&1 || rc=$?
[ "${rc}" -ne 0 ] && report "missing workspace exits non-zero" 1 || report "missing workspace exits non-zero" 0 "exit ${rc}"

printf '\n======================================================================\n'
printf 'test_refresh_hooks.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
printf '======================================================================\n'
[ "${FAIL}" -eq 0 ]
