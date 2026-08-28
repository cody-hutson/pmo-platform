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
#   3. the operator's .mode is preserved (install-if-missing) -- asserted with a seed
#      DERIVED to differ from the shipped template default, so "preserved" and
#      "overwritten from the template" leave observably different state. Do not
#      re-hardcode this seed: a literal equal to the template default makes the
#      assertion pass in both directions, which is how it shipped uncovered.
#   4. an operator-EDITED hook (diverged from its recorded baseline) is preserved, not clobbered
#   5. a true no-op (all hooks match source) emits ZERO "REFRESHED" (so update.sh's EX_NOCHANGE
#      contract is not broken by the hook phase)
#   6. --dry-run mutates nothing
#   7. a non-existent workspace fails closed (exit non-zero) rather than scaffolding
#   8. every deployed hook ENTRYPOINT carries +x, while a co-deployed SOURCED lib needs
#      only to be readable — the #4449 acceptance criterion as reframed and ratified
#      (entrypoint implies executable; sourced library implies readable)
#   9. a missing shared-library SOURCE ABORTS the refresh and ROLLS BACK, rather than
#      warning and completing — the abort is attributed to the co-deploy guard ITSELF
#      rather than to a bare non-zero exit (9a), and the rollback RESTORES overwritten
#      bytes instead of deleting them (9b, 9c) while REMOVING what the refresh newly
#      created (9d) (Cases 9a-9d)
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

# CONFIG_ROOT ISOLATION (#5662). --refresh-hooks now captures a DURABLE snapshot, which by
# design lives outside the workspace and outlives the run — so unless this suite pins
# --config-root into its own sandbox, every refresh below would deposit generations into the
# operator's real ${HOME}/.config/pmo-platform. Observed doing exactly that before this line
# existed. Every invocation of ${SETUP} in this file MUST carry --config-root.
CFGROOT="${SBX}/config"
mkdir -p "${CFGROOT}"

PASS=0
FAIL=0
report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '         %s\n' "${detail}"; FAIL=$((FAIL + 1)); fi
}
sha() { shasum -a 256 "$1" | awk '{print $1}'; }

# Operator .mode seed. The preserve contract is only OBSERVABLE when the seeded value
# differs from what the refresh would install from the template: if they are equal,
# "preserved" and "overwritten from the template" leave byte-equivalent state and the
# Case 1-3 assertion passes either way. Derive the seed from the shipped template at run
# time rather than hardcoding it, so a future change to the template default cannot
# silently re-create that collapse. Legal mode values are the closed set
# {warn, enforce, off}; prefer the fail-closed member unless it IS the default.
MODE_TEMPLATE="${REPO_ROOT}/core/hooks/.mode.template"
MODE_DEFAULT="$(tr -d '[:space:]' < "${MODE_TEMPLATE}" 2>/dev/null || true)"
if [ "${MODE_DEFAULT}" = "enforce" ]; then MODE_SEED="off"; else MODE_SEED="enforce"; fi
readonly MODE_TEMPLATE MODE_DEFAULT MODE_SEED

# deploy_ws <dir> — materialize a workspace with the CURRENT hook bundle + a baseline state.
deploy_ws() {
  local ws="$1" h
  mkdir -p "${ws}/.claude/hooks/lib"
  for h in "${REPO_ROOT}/core/hooks/"*.sh; do cp "${h}" "${ws}/.claude/hooks/"; done
  cp "${REPO_ROOT}/core/hooks/lib/positional-issueref.awk" "${REPO_ROOT}/core/hooks/lib/dep-resolve.sh" "${REPO_ROOT}/core/hooks/lib/fragile-ref-patterns.sh" "${ws}/.claude/hooks/lib/"
  cp "${REPO_ROOT}/core/deploy/tools/path-leak-patterns.sh" "${ws}/.claude/hooks/" 2>/dev/null || true
  printf '%s\n' "${MODE_SEED}" > "${ws}/.claude/hooks/.mode"
  # record baselines = current source SHAs
  python3 - "${REPO_ROOT}" "${ws}/.claude/.workspace-setup.state" <<'PY'
import hashlib, json, glob, os, sys
repo, out = sys.argv[1], sys.argv[2]
cs = {os.path.basename(h): hashlib.sha256(open(h, "rb").read()).hexdigest()
      for h in glob.glob(os.path.join(repo, "core/hooks/*.sh"))}
json.dump({"hook_checksums": cs}, open(out, "w"))
PY
}
refresh() { bash "${SETUP}" --refresh-hooks --workspace-root "$1" --source-repo "${REPO_ROOT}" --config-root "${CFGROOT}" "${@:2}" 2>&1; }
# restore <ws> [args...] — the #5662 recovery path, same CONFIG_ROOT so it sees the snapshots
# the refreshes above deposited.
restore() { bash "${SETUP}" --restore-hooks --workspace-root "$1" --source-repo "${REPO_ROOT}" --config-root "${CFGROOT}" "${@:2}" 2>&1; }
# n_bundle_files <dir> — regular files in a deployed bundle, dotfiles included. The file
# COUNT is the unit every #5662 recovery arm reports in, so it is derived once here.
n_bundle_files() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' '; }

printf '\nCase 1-3: stale hook refreshed · missing hook libs co-deployed (awk + constants) · .mode preserved\n'
# Fixture precondition. install_mode_template_if_missing returns early when its SOURCE is
# absent, so a deleted or renamed template would leave .mode untouched and make the
# preserve assertion below pass VACUOUSLY. Assert the template exists so that vacancy is
# reported rather than mistaken for a pass.
#
# FALSIFIED BY MUTATION, NOT ARGUED. Rename ${MODE_TEMPLATE} away and re-run: THIS
# assertion fails ALONE — 44 passed / 1 failed — while `.mode preserved (operator
# choice)` immediately below still reports PASS, because the seed the refresh never
# touched still equals MODE_SEED. That surviving PASS is precisely the vacuous pass
# this precondition exists to report, so the mutation demonstrates both arms at once.
# Unmutated on the same tree: 45 passed / 0 failed.
[ -f "${MODE_TEMPLATE}" ] \
  && report "mode template present (fixture precondition)" 1 \
  || report "mode template present (fixture precondition)" 0 "absent: ${MODE_TEMPLATE}"
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
# Mode-file preserve cohort -- the enumeration this assertion's siblings owe.
# setup-workspace.sh installs FOUR mode defaults install-if-missing (.mode,
# deploy-check.mode, .gh-path-leak-mode, .autonomy-mode) and --refresh-hooks routes
# through that same install path, so all four carry the identical preserve-vs-overwrite
# contract. Only .mode is asserted -- here. The other three have NO preserve assertion in
# any suite: that is a RECORDED gap, not an assumed-absent one, and the durable remedy is
# a single assertion driven from the tracked mode-template set rather than a per-file
# enumeration -- tracked separately, in the same shape as the co-deploy list limitation
# noted at the top of this file. A fifth tracked template, .verify-session-config-mode,
# has no install call site at all, so it carries no preserve contract to assert; that is
# a different defect and is likewise tracked separately.
[ "$(cat "${WS}/.claude/hooks/.mode")" = "${MODE_SEED}" ] \
  && report ".mode preserved (operator choice)" 1 \
  || report ".mode preserved (operator choice)" 0 \
       "seeded ${MODE_SEED}, found $(cat "${WS}/.claude/hooks/.mode"); template default is ${MODE_DEFAULT}"

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
rc=0; bash "${SETUP}" --refresh-hooks --workspace-root "${SBX}/nonexistent" --source-repo "${REPO_ROOT}" --config-root "${CFGROOT}" >/dev/null 2>&1 || rc=$?
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
OUT="$(bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${SRC_GOOD}" --config-root "${CFGROOT}" 2>&1)" || rc=$?
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
OUT="$(bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${SRC_BROKEN}" --config-root "${CFGROOT}" 2>&1)" || rc=$?

# 9a — the abort fires, AND it is THIS guard that fired.
#
# The old shape asserted only `rc != 0`, which attributes a failure to nothing. `exit 74`
# appears 11 times in setup-workspace.sh, so the exit CODE alone names no guard, and a bare
# non-zero is satisfied equally by three different states this arm must tell apart: the
# deliberate co-deploy abort, the Case-10 closure post-condition catching the SAME condition
# one step later, and an unrelated incidental failure.
#
# Measured, not reasoned about (#5663): with the co-deploy abort removed ENTIRELY — the exact
# regression this case exists to catch — the suite still reported 22 passed / 0 failed,
# because assert_hook_lib_closure independently exits 74 on the same input and held this arm
# green. Under a different mutation the arm passed on an incidental `cp` failure that exited 1.
#
# So the arm pins the two properties that are true ONLY of the co-deploy abort:
#   - its own refusal line. The closure backstop rolls back too, but says something else
#     ("Hook-library closure FAILED … rolling back to the pre-refresh bundle"), so this
#     string separates the guard from its backstop.
#   - exit 74 specifically, not merely non-zero. cleanup() skips rollback for 64/66/69/78,
#     so an abort that exited one of those would leave the half-refreshed bundle in place.
abort_sig='Refusing to leave the hook bundle in that state; rolling back.'
sig_seen=no; grep -qF "${abort_sig}" <<<"${OUT}" && sig_seen=yes
if [ "${rc}" -eq 74 ] && [ "${sig_seen}" = "yes" ]; then
  report "9a: the co-deploy guard ITSELF aborts the refresh (exit 74 + its own refusal)" 1
else
  report "9a: the co-deploy guard ITSELF aborts the refresh (exit 74 + its own refusal)" 0 \
    "exit ${rc}, co-deploy refusal seen=${sig_seen} — a bare non-zero is also produced by the closure backstop and by incidental failures, so it cannot attribute this abort"
fi

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

# 9d — the rollback REMOVES a library this refresh created (the `rm-file` limb).
#
# The old shape asserted the ABSENCE of command-position.awk in ws6 above, and was vacuous
# (#5663): deploy_ws never seeds that file and the plant deletes its only source, so the
# co-deploy aborts BEFORE the file is ever written and the postcondition is already true
# before the code under test runs. It passed in all five guard configurations measured —
# including one where rollback deleted files outright, and one where no rollback op was
# recorded at all. An assertion that holds equally under "rollback works", "rollback deletes
# everything" and "no rollback at all" is not measuring rollback.
#
# Seeding the file into ws6 does NOT repair it. Measured: with command-position.awk seeded
# into ws6, it is present before the refresh and still present after, because the abort fires
# before the co-deploy touches it. That is CORRECT — deleting an operator's healthy copy is
# the denial storm 9c exists to catch — so asserting its absence there would pin the
# regression as the expected result.
#
# The limb 9d was reaching for ("no partial library left behind") is record_write_rollback's
# rm-file branch: a target that did NOT exist pre-refresh is created, and the EXIT trap must
# undo the creation. Nothing else in this file covers it — 9b and 9c both cover restore-file.
# Observing it requires the file to actually BE created and then removed, so this arm uses its
# own workspace and a HEALTHY source (command-position.awk co-deploys normally) and triggers
# the abort one step later, with a deployed hook whose library nothing can satisfy.
#
# ANTI-VACUITY: the arm asserts the file WAS created, from the co-deploy's own INSTALLED line,
# BEFORE reading its absence. Without that the postcondition is satisfied equally by "never
# written at all" — which is precisely how the old arm passed.
WS="${SBX}/ws6d"; deploy_ws "${WS}"
printf '%s\n' '#!/bin/bash' 'readonly FAKE_LIB="${HOOK_DIR}/lib/no-such-lib.sh"' 'exit 0' \
  > "${WS}/.claude/hooks/zz-rollback-fixture.sh"
chmod +x "${WS}/.claude/hooks/zz-rollback-fixture.sh"
rc=0; OUT="$(refresh "${WS}")" || rc=$?
created=no; grep -qF 'INSTALLED: command-position.awk' <<<"${OUT}" && created=yes
left=no; [ -f "${WS}/.claude/hooks/lib/command-position.awk" ] && left=yes
if [ "${created}" = "yes" ] && [ "${rc}" -eq 74 ] && [ "${left}" = "no" ]; then
  report "9d: rollback REMOVES a library this refresh created (rm-file limb)" 1
else
  report "9d: rollback REMOVES a library this refresh created (rm-file limb)" 0 \
    "created=${created} exit=${rc} still-present=${left} — created=no would make the absence vacuous; still-present=yes means the creation was never undone"
fi

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

printf '\nCase 11: DURABLE rollback substrate — survives success AND untrapped kill (#5662)\n'
# The in-run ledger (Cases 9a-9d) lives in SESSION_TMPDIR and dies with the run, so it covers
# in-run failure ONLY. Case 11 exercises the substrate that outlives the run, and every arm
# below is written so that it is FALSE before the code under test runs and TRUE after — the
# vacuity defect #5663 found in the old 9d.

gens_in() { ls -1 "$1/hook-bundle-backups" 2>/dev/null | grep -E '^[0-9]{8}T[0-9]{6}Z-[0-9]+$' | sort; }
latest_gen_in() { gens_in "$1" | tail -n 1; }

# --- 11-control: a refresh CREATES a durable generation, and the store was empty first.
# Without the emptiness pre-check, "a generation exists" is satisfied by one left behind by
# an earlier case in this file, and the arm would measure nothing.
CFG11="${SBX}/cfg11"; mkdir -p "${CFG11}"
pre_gens="$(gens_in "${CFG11}" | wc -l | tr -d ' ')"
WS="${SBX}/ws11"; deploy_ws "${WS}"
printf '#!/bin/bash\n# STALE-11\nexit 0\n' > "${WS}/.claude/hooks/block-egress.sh"
python3 - "${WS}/.claude/.workspace-setup.state" <<'PY'
import hashlib, json, os, sys
st = sys.argv[1]
d = json.load(open(st)); cs = d.get("hook_checksums", {})
p = os.path.join(os.path.dirname(st), "hooks", "block-egress.sh")
cs["block-egress.sh"] = hashlib.sha256(open(p, "rb").read()).hexdigest()
d["hook_checksums"] = cs; json.dump(d, open(st, "w"))
PY
pre_sha11="$(sha "${WS}/.claude/hooks/block-egress.sh")"
pre_n11="$(n_bundle_files "${WS}/.claude/hooks")"
rc=0; OUT="$(bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11}" 2>&1)" || rc=$?
post_gens="$(gens_in "${CFG11}" | wc -l | tr -d ' ')"
gen11="$(latest_gen_in "${CFG11}")"
if [ "${pre_gens}" = "0" ] && [ "${rc}" -eq 0 ] && [ "${post_gens}" = "1" ]; then
  report "11-control: a successful refresh creates exactly 1 durable generation (0 -> 1)" 1
else
  report "11-control: a successful refresh creates exactly 1 durable generation (0 -> 1)" 0 \
    "pre=${pre_gens} exit=${rc} post=${post_gens} — pre must be 0 or the arm is vacuous"
fi
printf '    [counts] pre-refresh bundle=%s file(s); durable generation=%s\n' "${pre_n11}" "${gen11:-none}"

# --- 11-order: the capture PRECEDES the first write. This is the property that makes an
# untrapped kill survivable at all: if the snapshot were taken after the hooks were copied,
# a kill inside the window would still have nothing to restore from.
first_snap="$(grep -n -m1 'DURABLE SNAPSHOT:' <<<"${OUT}" | cut -d: -f1)"
first_write="$(grep -nE -m1 'REFRESHED:|INSTALLED:' <<<"${OUT}" | cut -d: -f1)"
if [ -n "${first_snap}" ] && [ -n "${first_write}" ] && [ "${first_snap}" -lt "${first_write}" ]; then
  report "11-order: the durable capture is emitted BEFORE the first bundle write" 1
else
  report "11-order: the durable capture is emitted BEFORE the first bundle write" 0 \
    "snapshot-line=${first_snap:-none} first-write-line=${first_write:-none}"
fi

# --- 11a (AC-1): roll back AFTER a refresh that already SUCCEEDED.
# cleanup() has run with INSTALL_COMPLETE=1, so every in-run pre-write backup is gone. This
# is the shape the ledger structurally cannot cover.
post_sha11="$(sha "${WS}/.claude/hooks/block-egress.sh")"
if [ "${post_sha11}" != "${pre_sha11}" ]; then
  report "11a-pre: the refresh actually CHANGED the hook (so the rollback has work to do)" 1
else
  report "11a-pre: the refresh actually CHANGED the hook (so the rollback has work to do)" 0 \
    "hook unchanged — the restore arm below would be vacuous"
fi
rc=0; ROUT="$(bash "${SETUP}" --restore-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11}" 2>&1)" || rc=$?
back_sha11="$(sha "${WS}/.claude/hooks/block-egress.sh")"
post_n11="$(n_bundle_files "${WS}/.claude/hooks")"
if [ "${rc}" -eq 0 ] && [ "${back_sha11}" = "${pre_sha11}" ]; then
  report "11a (AC-1): a SUCCEEDED refresh is rolled back from the durable snapshot" 1
else
  report "11a (AC-1): a SUCCEEDED refresh is rolled back from the durable snapshot" 0 \
    "exit=${rc}; hook did not return to its pre-refresh bytes"
fi
printf '    [counts] %s\n' "$(printf '%s\n' "${ROUT}" | grep -E 'RESTORED:|REMOVED \(' | tr '\n' ' ')"

# --- 11b (AC-2): an UNTRAPPED KILL leaves a recoverable state.
# Two properties, measured separately.
#   11b-1: the store SURVIVES SIGKILL. The refresh is backgrounded and killed with -9 once its
#          generation is on disk; -9 runs no EXIT trap, so nothing cleans up after it.
#   11b-2: recovery from the exact damaged state that window leaves (hooks new, library
#          absent) succeeds, with counts.
CFG11B="${SBX}/cfg11b"; mkdir -p "${CFG11B}"
WS="${SBX}/ws11b"; deploy_ws "${WS}"
bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11B}" >/dev/null 2>&1 &
bg_pid=$!
i=0; gen11b=""
while [ "${i}" -lt 4000 ]; do
  gen11b="$(latest_gen_in "${CFG11B}")"
  [ -n "${gen11b}" ] && break
  i=$((i + 1))
done
kill -9 "${bg_pid}" 2>/dev/null
wait "${bg_pid}" 2>/dev/null
# The generation must be on disk AND complete after a kill that ran no trap.
man11b="${CFG11B}/hook-bundle-backups/${gen11b}/MANIFEST.tsv"
if [ -n "${gen11b}" ] && [ -s "${man11b}" ]; then
  n_man11b="$(wc -l < "${man11b}" | tr -d ' ')"
  report "11b-1 (AC-2): the durable generation survives SIGKILL (no EXIT trap ran)" 1
else
  n_man11b=0
  report "11b-1 (AC-2): the durable generation survives SIGKILL (no EXIT trap ran)" 0 \
    "generation=${gen11b:-none} manifest=${man11b}"
fi
printf '    [counts] generation %s carries %s manifested file(s) after SIGKILL\n' "${gen11b:-none}" "${n_man11b}"

# 11b-2 — reproduce the hooks-copied / library-absent state the window leaves, then recover.
# This is the state Stage 10 measured at 412/871 assertions flipping to deny, in which an
# agent's own shell calls are denied and nothing can self-repair.
rm -rf "${WS}/.claude/hooks/lib"
damaged_n="$(n_bundle_files "${WS}/.claude/hooks")"
lib_before="$([ -d "${WS}/.claude/hooks/lib" ] && echo present || echo absent)"
rc=0; ROUT="$(bash "${SETUP}" --restore-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11B}" 2>&1)" || rc=$?
recovered_n="$(n_bundle_files "${WS}/.claude/hooks")"
lib_after="$([ -d "${WS}/.claude/hooks/lib" ] && echo present || echo absent)"
if [ "${lib_before}" = "absent" ] && [ "${rc}" -eq 0 ] && [ "${lib_after}" = "present" ] && [ "${recovered_n}" = "${n_man11b}" ]; then
  report "11b-2 (AC-2): the hooks-new/library-absent state is recovered from the durable snapshot" 1
else
  report "11b-2 (AC-2): the hooks-new/library-absent state is recovered from the durable snapshot" 0 \
    "lib before=${lib_before} after=${lib_after} exit=${rc} recovered=${recovered_n} expected=${n_man11b}"
fi
printf '    [counts] damaged=%s file(s) -> recovered=%s file(s) (manifest=%s)\n' "${damaged_n}" "${recovered_n}" "${n_man11b}"

# --- 11c (AC-3): the restore REMOVES a file the restored generation does not carry.
# ANTI-VACUITY is the whole point here: the arm asserts the file is PRESENT before the
# restore. Asserting only its absence afterwards passes equally when it was never created.
CFG11C="${SBX}/cfg11c"; mkdir -p "${CFG11C}"
WS="${SBX}/ws11c"; deploy_ws "${WS}"
rc=0; bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11C}" >/dev/null 2>&1 || rc=$?
# A file introduced AFTER the snapshot — the "release-added file" `cp -R` would leave behind.
printf '# added by a later release\n' > "${WS}/.claude/hooks/lib/zz-release-added.sh"
added_before="$([ -f "${WS}/.claude/hooks/lib/zz-release-added.sh" ] && echo present || echo absent)"
keeper_sha="$(sha "${WS}/.claude/hooks/lib/dep-resolve.sh")"
rc=0; ROUT="$(bash "${SETUP}" --restore-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11C}" 2>&1)" || rc=$?
added_after="$([ -f "${WS}/.claude/hooks/lib/zz-release-added.sh" ] && echo present || echo absent)"
if [ "${added_before}" = "present" ] && [ "${rc}" -eq 0 ] && [ "${added_after}" = "absent" ]; then
  report "11c (AC-3): the restore REMOVES a release-added file (present before, absent after)" 1
else
  report "11c (AC-3): the restore REMOVES a release-added file (present before, absent after)" 0 \
    "before=${added_before} exit=${rc} after=${added_after} — before=absent makes this vacuous"
fi
# SPECIFICITY — removal is targeted, not a wipe: a file the manifest DOES carry survives, byte-identical.
if [ -f "${WS}/.claude/hooks/lib/dep-resolve.sh" ] && [ "$(sha "${WS}/.claude/hooks/lib/dep-resolve.sh")" = "${keeper_sha}" ]; then
  report "11c-specificity: a manifested file SURVIVES the same restore, byte-identical" 1
else
  report "11c-specificity: a manifested file SURVIVES the same restore, byte-identical" 0 \
    "the removal pass is deleting manifested files — that is a wipe, not a restore"
fi
printf '    [counts] %s\n' "$(printf '%s\n' "${ROUT}" | grep -E 'RESTORED:|REMOVED \(' | tr '\n' ' ')"

# --- 11d: MUTATION — the capture's zero-file FAILED-PROBE guard.
# A guard that has not been watched firing is not accepted as working. `exit 74` appears many
# times in setup-workspace.sh, so the arm pins the guard's OWN message, not the exit code.
CFG11D="${SBX}/cfg11d"; mkdir -p "${CFG11D}"
WS="${SBX}/ws11d"; mkdir -p "${WS}/.claude/hooks"          # an EMPTY bundle — the plant
rc=0; OUT="$(bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11D}" 2>&1)" || rc=$?
if grep -qF 'manifested ZERO files' <<<"${OUT}" && [ "${rc}" -eq 74 ]; then
  report "11d MUTATION: the zero-file capture guard FIRES on an empty bundle (own message + 74)" 1
else
  report "11d MUTATION: the zero-file capture guard FIRES on an empty bundle (own message + 74)" 0 \
    "exit=${rc}; guard message not seen — a bare non-zero here is also produced by other guards"
fi
# and it leaves NO half-written generation behind.
n_d="$(gens_in "${CFG11D}" | wc -l | tr -d ' ')"
[ "${n_d}" = "0" ] \
  && report "11d: the failed capture records no generation (no half-written snapshot)" 1 \
  || report "11d: the failed capture records no generation (no half-written snapshot)" 0 "found ${n_d}"

# --- 11e: MUTATION — the restore's N/N verification guard.
# Corrupt one file INSIDE a captured generation so the bytes the restore lays down no longer
# match the manifest sha. The restore must refuse rather than report a green recovery.
CFG11E="${SBX}/cfg11e"; mkdir -p "${CFG11E}"
WS="${SBX}/ws11e"; deploy_ws "${WS}"
bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11E}" >/dev/null 2>&1
gen11e="$(latest_gen_in "${CFG11E}")"
# CONTROL ARM FIRST — the untouched generation restores cleanly. Without it, the failure
# below could be attributable to the generation being unusable rather than to the corruption.
# The generation is named EXPLICITLY: a restore takes its own snapshot first, so "newest"
# after the control run is the control's own snapshot, not gen11e — naming it is what keeps
# the plant and the control pointed at the same bytes.
rc=0; bash "${SETUP}" --restore-hooks "${gen11e}" --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11E}" >/dev/null 2>&1 || rc=$?
[ "${rc}" -eq 0 ] \
  && report "11e-control: the UNCORRUPTED generation restores cleanly (exit 0)" 1 \
  || report "11e-control: the UNCORRUPTED generation restores cleanly (exit 0)" 0 "exit ${rc}"
# THE PLANT — same generation, one file's bytes changed, manifest left alone.
printf 'corrupted\n' > "${CFG11E}/hook-bundle-backups/${gen11e}/bundle/lib/dep-resolve.sh"
rc=0; OUT="$(bash "${SETUP}" --restore-hooks "${gen11e}" --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11E}" 2>&1)" || rc=$?
if grep -qF 'RESTORE INCOMPLETE' <<<"${OUT}" && [ "${rc}" -eq 74 ]; then
  report "11e MUTATION: the restore's N/N verification FIRES on a corrupted generation" 1
else
  report "11e MUTATION: the restore's N/N verification FIRES on a corrupted generation" 0 \
    "exit=${rc}; 'RESTORE INCOMPLETE' not seen — the restore reported success over bytes that do not match"
fi

# --- 11g: MUTATION — the workspace-binding guard.
# Found by this suite (#5662): before the guard, a restore run against a config root holding
# ANOTHER workspace's generations laid that foreign bundle down and reported "27/27 verified
# identical", because the manifest verification is self-consistent and cannot notice the
# snapshot belongs elsewhere. CONTROL first, then the plant.
CFG11G="${SBX}/cfg11g"; mkdir -p "${CFG11G}"
WS_A="${SBX}/ws11g-a"; deploy_ws "${WS_A}"
WS_B="${SBX}/ws11g-b"; deploy_ws "${WS_B}"
bash "${SETUP}" --refresh-hooks --workspace-root "${WS_A}" --source-repo "${REPO_ROOT}" --config-root "${CFG11G}" >/dev/null 2>&1
gen11g="$(latest_gen_in "${CFG11G}")"
# CONTROL — restoring that generation into its OWN workspace succeeds.
rc=0; bash "${SETUP}" --restore-hooks "${gen11g}" --workspace-root "${WS_A}" --source-repo "${REPO_ROOT}" --config-root "${CFG11G}" >/dev/null 2>&1 || rc=$?
[ "${rc}" -eq 0 ] \
  && report "11g-control: a generation restores into the workspace it came FROM" 1 \
  || report "11g-control: a generation restores into the workspace it came FROM" 0 "exit ${rc}"
# THE PLANT — same generation, different workspace.
rc=0; OUT="$(bash "${SETUP}" --restore-hooks "${gen11g}" --workspace-root "${WS_B}" --source-repo "${REPO_ROOT}" --config-root "${CFG11G}" 2>&1)" || rc=$?
if grep -qF 'captured from a DIFFERENT workspace' <<<"${OUT}" && [ "${rc}" -eq 66 ]; then
  report "11g MUTATION: a FOREIGN generation is refused (own message + 66)" 1
else
  report "11g MUTATION: a FOREIGN generation is refused (own message + 66)" 0 \
    "exit=${rc}; guard message not seen — a foreign hook bundle would be importable"
fi

# --- 11h: a half-written capture is INVISIBLE to the selector.
# The SIGKILL arm (11b-1) originally failed because a directory-first scheme published the
# generation name before the manifest existed, so the selector picked an empty shell. The
# staging name must not be selectable.
CFG11H="${SBX}/cfg11h"; mkdir -p "${CFG11H}/hook-bundle-backups"
mkdir -p "${CFG11H}/hook-bundle-backups/20260101T000000Z-999.partial/bundle"
sel11h="$(latest_gen_in "${CFG11H}")"
[ -z "${sel11h}" ] \
  && report "11h: a .partial staging dir is NOT selectable as a generation" 1 \
  || report "11h: a .partial staging dir is NOT selectable as a generation" 0 "selector returned ${sel11h}"

# --- 11f: retention is BOUNDED, and bounded selectively.
# HOOK_BACKUP_RETAIN generations are kept; the oldest is evicted, and a directory that is not
# a generation is left alone (the store is never blind-rm'd).
CFG11F="${SBX}/cfg11f"; mkdir -p "${CFG11F}"
WS="${SBX}/ws11f"; deploy_ws "${WS}"
mkdir -p "${CFG11F}/hook-bundle-backups"
printf 'operator parked this here\n' > "${CFG11F}/hook-bundle-backups/NOTES.txt"
i=0
while [ "${i}" -lt 7 ]; do
  bash "${SETUP}" --refresh-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG11F}" >/dev/null 2>&1
  i=$((i + 1))
done
n_f="$(gens_in "${CFG11F}" | wc -l | tr -d ' ')"
if [ "${n_f}" = "5" ]; then
  report "11f: retention BOUNDS the store at 5 generations after 7 refreshes" 1
else
  report "11f: retention BOUNDS the store at 5 generations after 7 refreshes" 0 "found ${n_f}"
fi
[ -f "${CFG11F}/hook-bundle-backups/NOTES.txt" ] \
  && report "11f-specificity: pruning leaves a NON-generation entry untouched (no blind rm)" 1 \
  || report "11f-specificity: pruning leaves a NON-generation entry untouched (no blind rm)" 0 \
     "the prune deleted an entry it did not create"
printf '    [counts] 7 refreshes -> %s generation(s) retained (bound = 5)\n' "${n_f}"


printf '\nCase 12: rebootstrap captures a durable snapshot BEFORE rewriting the bundle (#5669)\n'
# refresh_hooks_flow was the only capture-bearing write path #5662 covered. rebootstrap also
# calls install_hooks, and it is the flow a plain re-run over a HEALTHY workspace routes to --
# so it is the path most likely to overwrite a live bundle, and it had no capture at all.
# Nothing in this file exercised rebootstrap before this case, which is why that survived.
CFG12="${SBX}/cfg12"; mkdir -p "${CFG12}"
pre_gens12="$(gens_in "${CFG12}" | wc -l | tr -d ' ')"
WS="${SBX}/ws12"; deploy_ws "${WS}"
# Unlike --refresh-hooks, rebootstrap resolves the full operator token set and PROMPTS for any
# it cannot find. With no operator.toml under CFG12 the run dies on "Prompt input failed
# (stdin closed?)" before install_hooks is ever reached -- observed, and the reason this arm
# needs a fixture identity where the refresh arms do not. Values are deliberately synthetic:
# this file ships in a public repository.
{
  printf '[meta]\nschema_version = 1\n\n[identity]\n'
  printf 'operator_name = "Test Operator"\n'
  printf 'operator_email = "operator@example.invalid"\n'
  printf 'operator_git_email = "operator@example.invalid"\n'
  printf 'operator_github = "example-operator"\n'
  printf 'operator_phone = ""\n'
  printf 'operator_role_title = "Test Role"\n'
  printf 'operator_organization = "Example Org"\n\n[paths]\n'
  printf 'claude_workspace_root = "%s"\n' "${WS}"
  printf 'operator_homedir_path = "%s"\n' "${SBX}/home12"
  printf 'cowork_install_path = "%s"\n' "${SBX}/cowork12"
} > "${CFG12}/operator.toml"
# Route the dispatcher to rebootstrap. It picks that branch only for a state file whose schema
# matches AND whose verification_passed is true -- i.e. what an already-installed, healthy
# workspace looks like. Anything else lands on fresh-install or guided recovery, and this arm
# would then be measuring a different flow entirely.
python3 - "${WS}/.claude/.workspace-setup.state" <<'PY'
import json, sys
st = sys.argv[1]
d = json.load(open(st))
d["schema_version"] = "1.0"
d["verification_passed"] = True
json.dump(d, open(st, "w"))
PY
pre_n12="$(n_bundle_files "${WS}/.claude/hooks")"
# Bytes of a hook as they stand BEFORE rebootstrap runs. This -- not the post-rebootstrap
# value -- is what a restore must return, because the capture is taken before the first write.
pre_sha_egress12="$(sha "${WS}/.claude/hooks/block-egress.sh")"
rc12=0
# --non-interactive resolves every token from its declared default instead of prompting.
# Required here: [OPERATOR_PROJECT_NAME] is not an operator.toml field at all, and an
# operator_phone set to "" is read as unset, so even a complete fixture still blocks on a
# prompt. No flag is passed to the refresh arms because that path resolves no tokens.
OUT12="$(bash "${SETUP}" --non-interactive --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG12}" 2>&1)" || rc12=$?
post_gens12="$(gens_in "${CFG12}" | wc -l | tr -d ' ')"
post_n12="$(n_bundle_files "${WS}/.claude/hooks")"
mode12="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("install_mode",""))' "${WS}/.claude/.workspace-setup.state" 2>/dev/null || true)"

# --- 12-mode: the anti-vacuity control. If the dispatcher did not actually route to
# rebootstrap, every arm below is measuring some other flow and proves nothing about #5669.
if [ "${mode12}" = "rebootstrapped" ]; then
  report "12-mode: the run actually routed to rebootstrap (not fresh-install or recovery)" 1
else
  report "12-mode: the run actually routed to rebootstrap (not fresh-install or recovery)" 0 \
    "install_mode=${mode12:-unset} exit=${rc12} -- the arms below are vacuous unless this is rebootstrapped"
  # A failing anti-vacuity control has to say WHY, or the next reader re-derives it from
  # scratch. Print the run's own tail rather than making them reproduce the invocation.
  printf '         --- rebootstrap run tail ---\n'
  printf '%s\n' "${OUT12}" | tail -n 12 | sed 's/^/         | /'
fi

# --- 12-control: a rebootstrap over a healthy workspace deposits exactly one generation.
# pre must be 0 or the count proves nothing about THIS run.
if [ "${pre_gens12}" = "0" ] && [ "${post_gens12}" = "1" ]; then
  report "12-control: rebootstrap creates exactly 1 durable generation (0 -> 1)" 1
else
  report "12-control: rebootstrap creates exactly 1 durable generation (0 -> 1)" 0 \
    "pre=${pre_gens12} post=${post_gens12} exit=${rc12} -- pre must be 0 or the arm is vacuous"
fi

# --- 12-order: the capture PRECEDES the first bundle write, the same property Case 11 pins
# for the refresh flow. A capture taken after install_hooks would leave an untrapped kill
# inside the write window with nothing to restore from, which is the whole point of #5669.
snap12="$(grep -n -m1 'DURABLE SNAPSHOT:' <<<"${OUT12}" | cut -d: -f1)"
write12="$(grep -nE -m1 'REFRESHED:|INSTALLED:' <<<"${OUT12}" | cut -d: -f1)"
if [ -n "${snap12}" ] && [ -n "${write12}" ] && [ "${snap12}" -lt "${write12}" ]; then
  report "12-order: rebootstrap emits the durable capture BEFORE its first bundle write" 1
else
  report "12-order: rebootstrap emits the durable capture BEFORE its first bundle write" 0 \
    "snapshot-line=${snap12:-none} first-write-line=${write12:-none} exit=${rc12}"
fi
printf '    [counts] pre-rebootstrap bundle=%s file(s); post=%s; generation=%s\n' \
  "${pre_n12}" "${post_n12}" "$(latest_gen_in "${CFG12}")"

# --- 12a (AC-2): the captured generation is actually RECOVERABLE. Capture plus correct
# ordering still proves nothing if the snapshot cannot be restored from -- that is the
# difference between a backup and a directory of files. Damage the rebootstrapped bundle,
# then recover from the generation rebootstrap itself deposited.
# The generation holds the PRE-rebootstrap bundle, so a correct restore lands on pre_n12
# files and the pre-rebootstrap bytes -- NOT on the post-rebootstrap state. Asserting the
# post-state here would pass only if the capture had been taken AFTER the write, which is
# precisely the defect #5669 exists to prevent. Observed 34 -> 33 -> 27 while getting this
# expectation backwards.
dmg12="${WS}/.claude/hooks/block-egress.sh"
printf '#!/bin/bash\n# DAMAGED-12\nexit 0\n' > "${dmg12}"
rm -f "${WS}/.claude/hooks/lib/positional-issueref.awk"
dmg_n12="$(n_bundle_files "${WS}/.claude/hooks")"
rc12r=0
bash "${SETUP}" --restore-hooks --workspace-root "${WS}" --source-repo "${REPO_ROOT}" --config-root "${CFG12}" >/dev/null 2>&1 || rc12r=$?
rec_n12="$(n_bundle_files "${WS}/.claude/hooks")"
rec_sha12="$(sha "${dmg12}")"
if [ "${dmg_n12}" -lt "${post_n12}" ]; then
  report "12a-pre: the damage actually removed a file (so recovery has work to do)" 1
else
  report "12a-pre: the damage actually removed a file (so recovery has work to do)" 0 \
    "post=${post_n12} damaged=${dmg_n12} -- the recovery arm below would be vacuous"
fi
if [ "${rc12r}" -eq 0 ] && [ "${rec_n12}" = "${pre_n12}" ] && [ "${rec_sha12}" = "${pre_sha_egress12}" ]; then
  report "12a (AC-2): a damaged bundle is recovered to its PRE-rebootstrap state" 1
else
  report "12a (AC-2): a damaged bundle is recovered to its PRE-rebootstrap state" 0 \
    "exit=${rc12r} files ${dmg_n12}->${rec_n12} (expected ${pre_n12}); bytes restored=$([ "${rec_sha12}" = "${pre_sha_egress12}" ] && echo yes || echo no)"
fi
printf '    [counts] rebootstrapped=%s file(s) -> damaged=%s -> recovered=%s\n' \
  "${post_n12}" "${dmg_n12}" "${rec_n12}"
printf '\n======================================================================\n'
printf 'test_refresh_hooks.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
printf '======================================================================\n'
[ "${FAIL}" -eq 0 ]
