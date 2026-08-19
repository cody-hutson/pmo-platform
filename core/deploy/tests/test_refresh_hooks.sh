#!/usr/bin/env bash
# test_refresh_hooks.sh — regression for #3430 (update.sh / setup-workspace.sh --refresh-hooks).
#
# deploy.sh deploys skills + packages but NOT hooks, so a hook/helper security fix reaches
# an already-installed workspace only through the new `setup-workspace.sh --refresh-hooks`
# path (which update.sh's Phase 5c delegates to). This test drives that path directly.
#
# Asserts the checksum-aware, non-interactive refresh contract:
#   1. a STALE deployed hook is refreshed to source
#   2. a never-deployed co-shipped primitive is co-deployed — asserted for BOTH hook-lib
#      primitives (positional-issueref.awk and fragile-ref-patterns.sh), because the
#      co-deploy list in setup-workspace.sh is enumerated per named file, so each primitive
#      is a separate way for the list to be incomplete
#   3. the operator's .mode is preserved (install-if-missing)
#   4. an operator-EDITED hook (diverged from its recorded baseline) is preserved, not clobbered
#   5. a true no-op (all hooks match source) emits ZERO "REFRESHED" (so update.sh's EX_NOCHANGE
#      contract is not broken by the hook phase)
#   6. --dry-run mutates nothing
#   7. a non-existent workspace fails closed (exit non-zero) rather than scaffolding
#   8. every deployed hook ENTRYPOINT carries +x, while a co-deployed SOURCED lib needs
#      only to be readable — the #4449 acceptance criterion as reframed and ratified
#      (entrypoint implies executable; sourced library implies readable)
#   9. a missing shared-library SOURCE ABORTS the refresh and ROLLS BACK, rather than
#      warning and completing — and the rollback RESTORES overwritten bytes instead of
#      deleting them (Cases 9a-9d)
#  10. the hook-library closure post-condition FAILS when a deployed hook references a
#      library that is not present, and PASSES on a healthy refresh (Cases 10a-10d)
#
# NOTE ON ASSERTION SHAPE (carried forward, and now the known limitation of this file).
# Contract item 2 asserts co-deployment PER NAMED PRIMITIVE because the co-deploy list in
# setup-workspace.sh is itself enumerated per named file. That shape is why a newly-added
# primitive is invisible here until someone remembers to add its name — which is exactly
# how command-position.awk reached a release with no assertion in this file, in the install
# validator, or in the refresh flow. The per-name assertions below are kept (they pin each
# named entry), and command-position.awk is added to them; the DURABLE fix is the derived
# closure post-condition items 9-10 exercise, which reads the required set out of the
# deployed hooks themselves and therefore covers a library added in a later release with no
# list to update. Rewriting the per-name arms into that derived form is a separate change.
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
  cp "${REPO_ROOT}/core/hooks/lib/positional-issueref.awk" "${REPO_ROOT}/core/hooks/lib/dep-resolve.sh" "${REPO_ROOT}/core/hooks/lib/fragile-ref-patterns.sh" "${ws}/.claude/hooks/lib/"
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

printf '\nCase 1-3: stale hook refreshed · missing hook libs co-deployed (awk + constants) · .mode preserved\n'
WS="${SBX}/ws1"; deploy_ws "${WS}"
printf '#!/bin/bash\n# STALE\nexit 0\n' > "${WS}/.claude/hooks/block-gh-path-leak.sh"   # stale
rm -f "${WS}/.claude/hooks/lib/positional-issueref.awk"                                 # never-deployed
rm -f "${WS}/.claude/hooks/lib/fragile-ref-patterns.sh"                                 # never-deployed
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
# Same assertion for the detector-constant lib. It is a SEPARATE named entry in
# setup-workspace.sh's co-deploy list, so the awk's presence proves nothing about it — and its
# absence is worse than the awk's: block-fragile-refs.sh reads EVERY pattern from this file, so
# a missing copy fails the hook CLOSED in enforce and blocks every durable-corpus write.
[ -f "${WS}/.claude/hooks/lib/fragile-ref-patterns.sh" ] && report "never-deployed detector constants co-deployed" 1 || report "never-deployed detector constants co-deployed" 0
# Third named entry. deploy_ws never seeds this one, so it is "never-deployed" in every
# workspace this file builds — and until now nothing here, in validate-install.sh, or in the
# refresh flow asserted it landed. All FOUR anchor-carrying hooks read it at startup and fail
# CLOSED without it, so its absence is the widest-blast-radius entry in the co-deploy list.
[ -f "${WS}/.claude/hooks/lib/command-position.awk" ] && report "never-deployed command-position.awk co-deployed" 1 || report "never-deployed command-position.awk co-deployed" 0
[ "$(cat "${WS}/.claude/hooks/.mode")" = "warn" ] && report ".mode preserved (operator choice)" 1 || report ".mode preserved (operator choice)" 0

printf '\nCase 4: operator-edited hook preserved (not clobbered)\n'
WS="${SBX}/ws2"; deploy_ws "${WS}"
printf '\n# OPERATOR EDIT\n' >> "${WS}/.claude/hooks/block-egress.sh"   # diverge from recorded baseline
OUT="$(refresh "${WS}")"
if grep -q 'OPERATOR EDIT' "${WS}/.claude/hooks/block-egress.sh" && grep -q 'PRESERVED (operator-edited): block-egress.sh' <<<"${OUT}"; then
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

printf '\nCase 8: entrypoints carry +x; sourced libs need only be readable (#4449 AC-1 reframed)\n'
# The discriminator is doctor.sh check_hooks_runnable's (#302 / #1850): a co-deployed
# sourced lib (lib-*.sh, *-patterns.sh) is consumed with `. "$LIB"` under an
# `[ -r "$LIB" ]` guard — never executed — so it ships mode 644 BY DESIGN, and
# test_doctor.sh pins that mode as correct by seeding its fixture at 644. Asserting
# +x over a naive *.sh glob would FAIL a healthy install; that false positive is the
# defect #4449 actually carries.
WS="${SBX}/ws5"; deploy_ws "${WS}"
refresh "${WS}" >/dev/null 2>&1

# Shared detector: names every deployed hook ENTRYPOINT lacking +x, sourced libs exempt.
nonexec_entrypoints() {
  local d="$1" h out=""
  for h in "${d}"/*.sh; do
    [ -f "${h}" ] || continue
    case "$(basename "${h}")" in lib-*.sh|*-patterns.sh) continue ;; esac
    [ -x "${h}" ] || out="${out} $(basename "${h}")"
  done
  printf '%s' "${out}"
}

# POSITIVE ARM — after a refresh, every entrypoint carries +x.
ne="$(nonexec_entrypoints "${WS}/.claude/hooks")"
[ -z "${ne}" ] \
  && report "every deployed hook ENTRYPOINT carries +x after a refresh" 1 \
  || report "every deployed hook ENTRYPOINT carries +x after a refresh" 0 "non-exec:${ne}"

# SPECIFICITY ARM — a sourced lib really IS deployed at 644 here. Without this the
# positive arm could be passing because nothing is 644 at all, which would prove
# nothing about the exemption; the exemption would be untested, not satisfied.
if [ -f "${WS}/.claude/hooks/path-leak-patterns.sh" ] && [ ! -x "${WS}/.claude/hooks/path-leak-patterns.sh" ]; then
  report "specificity: a co-deployed sourced lib IS present at 644 (exemption is exercised)" 1
else
  report "specificity: a co-deployed sourced lib IS present at 644 (exemption is exercised)" 0 \
    "no non-executable sourced lib deployed — the exemption above is untested, not satisfied"
fi

# ANTI-VACUITY ARM — strip +x from one entrypoint; the detector MUST name it. An
# assertion never shown capable of failing is not evidence of anything.
chmod -x "${WS}/.claude/hooks/block-destructive.sh"
ne="$(nonexec_entrypoints "${WS}/.claude/hooks")"
case " ${ne} " in
  *" block-destructive.sh "*)
    report "anti-vacuity: the +x assertion DETECTS a stripped entrypoint bit" 1 ;;
  *)
    report "anti-vacuity: the +x assertion DETECTS a stripped entrypoint bit" 0 \
      "detector stayed silent on a stripped bit — the assertion above is vacuous" ;;
esac
chmod +x "${WS}/.claude/hooks/block-destructive.sh"

# READABILITY ARM — sourced libs carry no +x requirement, but they DO fail closed when
# unreadable (block-fragile-refs reads every pattern from one of them), so readability
# is the property that actually matters for this class.
unreadable=""
for l in "${WS}/.claude/hooks/lib/"*; do
  [ -f "${l}" ] || continue
  [ -r "${l}" ] || unreadable="${unreadable} $(basename "${l}")"
done
[ -z "${unreadable}" ] \
  && report "every sourced lib under hooks/lib/ is readable" 1 \
  || report "every sourced lib under hooks/lib/ is readable" 0 "unreadable:${unreadable}"

printf '\nCase 9: a missing shared-library SOURCE aborts + rolls back (PLANTED FAILURE)\n'
# The condition being planted is the one Stage 10 measured: hook entrypoints land, the
# shared library they load does not. Before this change the co-deploy WARNED and the
# install completed, leaving a bundle in which all four anchor-carrying hooks fail closed
# (412 of 871 assertions flip to deny, none to allow) with no backup and no rollback op.
#
# An abort that has never been observed aborting is indistinguishable from one that cannot
# abort, so the failure is planted here rather than reasoned about: a mirror of the source
# tree with exactly one file removed.
mk_src_mirror() {
  local dst="$1"
  mkdir -p "${dst}/core/hooks/lib" "${dst}/core/deploy/tools"
  cp "${REPO_ROOT}/core/CLAUDE.md.template" "${REPO_ROOT}/core/settings.json.template" "${dst}/core/"
  cp "${REPO_ROOT}/core/hooks/"*.sh "${dst}/core/hooks/"
  cp "${REPO_ROOT}/core/hooks/lib/"* "${dst}/core/hooks/lib/"
  cp "${REPO_ROOT}/core/hooks/".*.template "${dst}/core/hooks/" 2>/dev/null || true
  cp "${REPO_ROOT}/core/hooks/"*.template "${dst}/core/hooks/" 2>/dev/null || true
  cp "${REPO_ROOT}/core/deploy/tools/path-leak-patterns.sh" "${dst}/core/deploy/tools/" 2>/dev/null || true
  cp "${REPO_ROOT}/core/deploy/lib-instance-path.sh" "${dst}/core/deploy/" 2>/dev/null || true
  cp "${REPO_ROOT}/.version" "${dst}/" 2>/dev/null || true
}
# CONTROL ARM FIRST. Run the UNMODIFIED mirror and require it to succeed. Without this,
# 9a's non-zero exit could be attributable to the mirror being an unusable source repo
# rather than to the missing library, and the whole case would prove nothing.
SRC_GOOD="${SBX}/src-good"; mk_src_mirror "${SRC_GOOD}"
WS="${SBX}/ws6a"; deploy_ws "${WS}"
rc=0
OUT="$(bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${SRC_GOOD}" 2>&1)" || rc=$?
if [ "${rc}" -eq 0 ] && [ -f "${WS}/.claude/hooks/lib/command-position.awk" ]; then
  report "9-control: the same mirror WITH the library refreshes cleanly (exit 0, library lands)" 1
else
  report "9-control: the same mirror WITH the library refreshes cleanly (exit 0, library lands)" 0 \
    "exit ${rc}; the sandbox mirror is not a working source repo, so the plant below proves nothing"
fi

# THE PLANT — the same mirror, one file removed.
SRC_BROKEN="${SBX}/src-broken"; mk_src_mirror "${SRC_BROKEN}"
rm -f "${SRC_BROKEN}/core/hooks/lib/command-position.awk"        # <-- the planted failure

WS="${SBX}/ws6"; deploy_ws "${WS}"
# Plant a STALE hook and record its baseline as the stale content, so the refresh classifies
# it as an unedited old platform copy and OVERWRITES it. Without an overwrite in flight there
# is nothing for the rollback to restore and the restore arm below would be vacuous.
printf '#!/bin/bash\n# STALE-FOR-ROLLBACK\nexit 0\n' > "${WS}/.claude/hooks/block-egress.sh"
python3 - "${WS}/.claude/.workspace-setup.state" <<'PY'
import hashlib, json, os, sys
st = sys.argv[1]
d = json.load(open(st)); cs = d.get("hook_checksums", {})
p = os.path.join(os.path.dirname(st), "hooks", "block-egress.sh")
cs["block-egress.sh"] = hashlib.sha256(open(p, "rb").read()).hexdigest()
d["hook_checksums"] = cs; json.dump(d, open(st, "w"))
PY
stale_sha="$(sha "${WS}/.claude/hooks/block-egress.sh")"
depresolve_sha_before="$(sha "${WS}/.claude/hooks/lib/dep-resolve.sh")"

rc=0
OUT="$(bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${SRC_BROKEN}" 2>&1)" || rc=$?

# 9a — the abort fires at all.
[ "${rc}" -ne 0 ] \
  && report "9a: missing library source ABORTS the refresh (exit ${rc})" 1 \
  || report "9a: missing library source ABORTS the refresh" 0 "exit 0 — the install completed over a fail-closed bundle"

# 9b — the overwritten hook is RESTORED. This is the rollback limb Stage 10 could not
# validate: git revert restores the repo, it does not restore .claude/hooks/.
[ "$(sha "${WS}/.claude/hooks/block-egress.sh")" = "${stale_sha}" ] \
  && report "9b: the OVERWRITTEN hook is restored to its pre-refresh bytes" 1 \
  || report "9b: the OVERWRITTEN hook is restored to its pre-refresh bytes" 0 "hook left half-refreshed"

# 9c — the regression guard on the rollback VERB. Under the old unconditional `rm-file`,
# rolling back a partial refresh DELETED co-deployed libraries that were present and healthy
# beforehand — turning a partial refresh into the very denial storm the rollback exists to
# prevent. A pre-existing library must survive its own rollback.
if [ -r "${WS}/.claude/hooks/lib/dep-resolve.sh" ] && \
   [ "$(sha "${WS}/.claude/hooks/lib/dep-resolve.sh")" = "${depresolve_sha_before}" ]; then
  report "9c: rollback RESTORES a pre-existing shared lib (does not delete it)" 1
else
  report "9c: rollback RESTORES a pre-existing shared lib (does not delete it)" 0 \
    "a healthy pre-existing library did not survive the rollback"
fi

# 9d — the workspace is not left holding a half-deployed library.
[ ! -f "${WS}/.claude/hooks/lib/command-position.awk" ] \
  && report "9d: no partial library left behind" 1 \
  || report "9d: no partial library left behind" 0

printf '\nCase 10: hook-library closure post-condition (PLANTED FAILURE + specificity)\n'
# The refresh flow is the only flow with no verification gate. The closure post-condition is
# the narrow one that matters: every library a DEPLOYED hook loads must be present. It is
# DERIVED from the deployed hooks rather than enumerated, so the plant is a deployed hook
# that declares a dependency nothing can satisfy.
WS="${SBX}/ws7"; deploy_ws "${WS}"
printf '%s\n' '#!/bin/bash' 'readonly FAKE_LIB="${HOOK_DIR}/lib/no-such-lib.sh"' 'exit 0' \
  > "${WS}/.claude/hooks/zz-fixture-dependent.sh"
chmod +x "${WS}/.claude/hooks/zz-fixture-dependent.sh"
rc=0; OUT="$(refresh "${WS}")" || rc=$?

# 10a — the post-condition detects the unsatisfiable dependency.
[ "${rc}" -ne 0 ] \
  && report "10a: closure post-condition FAILS the refresh on a missing library (exit ${rc})" 1 \
  || report "10a: closure post-condition FAILS the refresh on a missing library" 0 \
     "refresh completed with a deployed hook whose library is absent"

# 10b — and NAMES it, so the failure is actionable rather than a bare non-zero.
case "${OUT}" in
  *no-such-lib.sh*) report "10b: the failure NAMES the missing library" 1 ;;
  *) report "10b: the failure NAMES the missing library" 0 "exit was non-zero for some other reason" ;;
esac

# 10c — SPECIFICITY. Remove the planted dependent and the same refresh must PASS. Without
# this arm 10a could be passing because the refresh fails for an unrelated reason, which
# would prove nothing about the post-condition.
rm -f "${WS}/.claude/hooks/zz-fixture-dependent.sh"
rc=0; OUT="$(refresh "${WS}")" || rc=$?
[ "${rc}" -eq 0 ] \
  && report "10c: specificity — the same workspace PASSES once the dependent is removed" 1 \
  || report "10c: specificity — the same workspace PASSES once the dependent is removed" 0 \
     "refresh still fails; 10a is not attributable to the closure check"

# 10d — the check reports itself, and reports a NON-ZERO required set. An empty derived set
# would make the PASS vacuous, so the post-condition treats zero as a failed probe rather
# than a clean result; assert the healthy path really did measure something.
case "${OUT}" in
  *"Hook-library closure: PASS"*)
    case "${OUT}" in
      *"(0 required"*) report "10d: the PASS is measured, not vacuous (non-zero required set)" 0 "derived set was empty" ;;
      *) report "10d: the PASS is measured, not vacuous (non-zero required set)" 1 ;;
    esac ;;
  *) report "10d: the PASS is measured, not vacuous (non-zero required set)" 0 "no closure PASS line emitted" ;;
esac

printf '\n======================================================================\n'
printf 'test_refresh_hooks.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
printf '======================================================================\n'
[ "${FAIL}" -eq 0 ]
