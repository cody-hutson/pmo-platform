#!/usr/bin/env bash
# test_package_freshness_exit_codes.sh — verdict -> exit-code contract for the
# `deploy.sh --check-package-freshness` probe (Check 7's CI-facing surface).
#
# WHY THIS TEST EXISTS
# The probe used to map a STALE verdict to exit 0 whenever the enforcement
# sentinel held a non-enforce token. Its prose said STALE and its exit status
# said OK, so any caller that read the exit code to answer "is the package
# fresh?" got the opposite of the truth. A verification tool whose success and
# failure are indistinguishable in the signal callers actually read is worse than
# one that only prints the verdict. This test asserts the exit status DIRECTLY,
# in a subprocess, because the exit status is where the defect lived.
#
# THE CONTRACT UNDER TEST (authoring home: the cmd_check_package_freshness
# header table in core/deploy/deploy.sh — this test is the executable mirror):
#
#   verdict         sentinel token   exit
#   -------------   --------------   ----
#   FRESH           any              0
#   STALE           != enforce       2     advisory: not fresh, not blocking
#   STALE           enforce          1     blocking
#   NOT-EVALUATED   != enforce       3     advisory OUTAGE: the content arm did not run
#                                          for part of the roster. Distinct from 2 so
#                                          "stale" and "unmeasured" cannot be conflated.
#   NOT-EVALUATED   enforce          1     blocking OUTAGE — a green gate must mean the
#                                          content arm actually ran
#   <other>         any              1     fail-closed, sentinel-agnostic
#
# EVERY MODE-DEPENDENT ARM PINS ITS OWN SYNTHETIC SENTINEL, AND THAT IS A CONTRACT
# TEST'S JOB RATHER THAN A CONVENIENCE. PF-2, PF-6, PF-9a, PF-9d and PF-10 assert a
# `!= enforce` row; PF-3 asserts the `enforce` row. Read from the sandbox's COMMITTED
# sentinel, those first four assert whatever posture the repository happens to hold
# today, so the moment that token is flipped to `enforce` a correct probe returns 1,
# the arms expecting 2 or 3 fail, and the suite reports a regression that is really a
# stale test expectation. A committed posture is a deployment decision; the verdict ->
# exit contract is an invariant. Each arm therefore hands probe_rc an explicit token
# and the suite stays green across the flip in either direction. PF-1 / PF-4 / PF-5 /
# PF-7 / PF-9c / PF-11 need no pin: they assert FRESH -> 0, which the `any` row makes
# sentinel-independent by construction.
#
# THE ASSERTIONS
#   PF-1  fresh sandbox, committed sentinel default    -> exit 0   (clean control)
#   PF-2  one stale package, SYNTHETIC `warn` sentinel  -> exit 2  (the regression)
#   PF-2b that exit 2 was reached BY THE CONTENT VERDICT — the probe's own output
#         carries the `source content changed since build (rebuilt hash ... !=
#         committed baseline ...)` line naming the staled skill
#   PF-2c no rostered skill fell back to the degraded path — zero `staged rebuild
#         failed to run` lines in that same output
#   PF-3  same stale tree, sentinel token `enforce`    -> exit 1   (blocking arm)
#   PF-4  injected staleness removed                   -> exit 0   (anti-vacuity)
#   PF-5  staleness cleared by the DOCUMENTED REMEDY (a build-skill-packages.sh
#         rebuild) -> exit 0. Conditional: reported as a NAMED SKIP with its
#         reason, and counted in the summary, on a runner whose python3 cannot
#         run the packager. Never silently absent, never counted as a pass, and
#         never green: a skip fails the suite (see WHY A SKIP FAILS THE SUITE).
#   PF-6  a TEMPLATE_SYNC_MAP canonical OUTSIDE every skills tree staled with no
#         rebuild, SYNTHETIC `warn` sentinel -> exit 2 (the injected-canonical
#         vector)
#   PF-7  that same canonical restored from its pristine snapshot -> exit 0
#         (PF-6's anti-vacuity control; restores, never rebuilds)
#   PF-8  the skill-package-freshness workflow declares NO `paths:` key
#         (the anti-narrowing floor; carries its own sensitivity arm)
#   PF-9a the packager's module chain cannot import on an otherwise FRESH tree,
#         SYNTHETIC `warn` sentinel -> exit 3. The content arm ran for no skill, so
#         the verdict is WITHHELD rather than clean
#   PF-9b that exit 3 names the outage, its cause, and its denominator — read from
#         the same probe invocation, with the roster total READ rather than pinned
#   PF-9c the shim removed and nothing else changed -> exit 0 (PF-9a's anti-vacuity
#         control, in the PF-4 / PF-7 pattern)
#   PF-9d a tree that is BOTH stale and unmeasured -> exit 2, not 3: STALE dominates,
#         so a measurement outage can never suppress a real finding. The staleness is
#         seeded in the SIDECAR, the one finding class that survives a packager
#         outage on a fresh checkout
#   PF-10 an AUTOMATED-DEPENDENCY ingress: a dependency manifest inside a rostered
#         skill's content set edited with no rebuild, mtime RESTORED, SYNTHETIC
#         `warn` sentinel -> exit 2, and the verdict came from the content arm.
#         The manifest is DERIVED through the real resolver, never hardcoded
#   PF-11 that same manifest restored from its pristine snapshot -> exit 0
#         (PF-10's anti-vacuity control; restores, never rebuilds)
#
# THE AUTOMATED-DEPENDENCY INGRESS (PF-10 / PF-11)
# A Dependabot SECURITY update reaches a manifest whether or not its ecosystem carries
# an `updates:` entry, and it is not a release — so the Stage-12 rebuild beat never
# fires for it. Two npm manifests sit inside one rostered skill's package content set,
# and one such PR merged: at that merge the committed .skill carried undici 7.28.0
# while the source held 7.29.0, at the SAME 19531 bytes on both sides. A length or
# mtime signal could not have seen it; only the content-manifest hash can. The package
# then sat stale on `main` for 8 days and was cleared by a hand rebuild, not a control.
#
# PF-10 RESTORES THE mtime AFTER STALING, AND THAT LINE IS THE ARM. Appending to the
# manifest bumps the source mtime, and a bumped mtime gives the DEGRADED branches their
# own road to exit 2 (see THE PF-2 DISCRIMINATOR) — so an arm that left it bumped would
# also pass on a runner where the content verdict never ran, which is the direction that
# matters. `touch -r` from the pristine snapshot removes that road. It cannot suppress
# the real one: the mtime compare is a non-verdict PRE-FILTER that only sets a flag, and
# the content verdict runs whenever a rebuild is available and its result decides. With
# the mtime restored, exit 2 is reachable ONLY through the content arm.
#
# The target is DERIVED, not named: every candidate is confirmed through the real
# resolver (`build-skill-packages.sh --skills-for-paths`, which reads repo-relative
# paths on STDIN and returns empty for an argv invocation). A hardcoded path would stop
# asserting the day the manifests move, and would do so silently. If no manifest inside
# any skills tree resolves to a rostered skill, the vector no longer exists and this
# suite ANNOUNCES that rather than swallowing it — PF-6's posture.
#
# THE UNMEASURED STATE (PF-9a..d)
# The probe's third verdict is the one that was missing when a CI dependency stopped
# resolving: the staged-rebuild content arm ran for zero of 55 skills, both degraded
# branches fell through to the mtime pre-filter, and that pre-filter is FALSE for
# every skill on a fresh checkout by construction — so the gate reported FRESH and
# exit 0 over an arm that had measured nothing. PF-9a asserts that those exact
# conditions now produce a withheld verdict on its own exit code.
#
# The degradation is injected the way the real one arrived, and that choice is the
# arm. A `sys.path` entry holding a `yaml` module that raises makes the packager's
# real import chain fail while the interpreter stays healthy — the shape a guard that
# tests the interpreter cannot see. Disabling python3 outright would prove something
# weaker and already covered; the point is that the capability the probe asserts and
# the capability the packager needs are different things.
#
# THE SHIM IS PREPENDED TO PYTHONPATH, NEVER SUBSTITUTED FOR IT. install-tests.yml
# exports PYTHONPATH as the user-site pin that survives this suite's HOME redirect.
# Replacing it would degrade the run by LOSING the user-site rather than by shadowing
# the module, and PF-9c would then be asserting PYTHONPATH restoration — a different
# claim that happens to produce the same exit code.
#
# PF-1 and PF-4 are not optional garnish. Without them PF-2 and PF-3 would pass
# against a probe that returned non-zero unconditionally, which is the vacuity
# this pair exists to defeat. PF-4 removes the staleness by restoring the file
# rather than by rebuilding, so the anti-vacuity control never depends on the
# packager; PF-5 is the packager-dependent remedy proof, kept separate for
# exactly that reason.
#
# THE PF-2 DISCRIMINATOR (PF-2b / PF-2c)
# PF-2's exit code is reachable by two different roads and the exit code cannot
# say which one was taken. _c7_compute_verdict decides staleness by staging a
# rebuild and comparing its content hash to the committed baseline; when that
# staged rebuild cannot RUN it warns and falls back to a cheap mtime pre-filter.
# PF-2 stales its target by appending a byte, which bumps the source mtime, so
# the mtime fallback ALONE reaches exit 2 — identically to a healthy run. Proven,
# not theorised: a degraded-packager control emitted 54 `staged rebuild failed`
# lines and still exited 2. PF-2 on its own therefore passes on a runner where
# the content verdict never executed, which is an assertion that cannot fail in
# the direction that matters.
#
# So the exit code is asserted with two companions read from that SAME probe
# invocation's output, one positive and one negative, because either alone is
# weak:
#   PF-2b is the POSITIVE limb — the content path leaves a distinctive line
#     naming the staled skill and quoting the rebuilt-vs-baseline hashes. Only a
#     rebuild that actually ran can emit it. This is the limb that goes red under
#     a degraded packager.
#   PF-2c is the NEGATIVE limb — zero degraded-path warnings across the whole
#     roster, so a run in which some OTHER skill silently fell back is not
#     reported as a clean content verdict on the strength of the probe skill's.
# An absence-only assertion would be satisfied by an empty extraction, so both
# limbs FIRST require the captured output to be non-empty and fail loudly when it
# is not: a zero counted over nothing is a broken probe, not a clean population.
#
# WHY A SKIP FAILS THE SUITE
# The suite used to exit non-zero only when FAIL was non-zero, so a skipped
# assertion was invisible to every caller that reads the exit status — which is
# all of them, CI included. That let a run report green while carrying an
# assertion that never executed, the same "passes without running" defect the
# PF-2 discriminator closes one assertion further up. SKIP now gates the exit
# alongside FAIL. The skip itself is still a distinct, NAMED state rather than
# being relabelled a failure: the reason line is the diagnostic that says a host
# capability is missing rather than a contract being violated, and collapsing the
# two would throw that away. What changed is only that the exit status stops
# calling it success.
#
# THE SECOND INPUT VECTOR (PF-6 / PF-7)
# A skill's package is built from two kinds of source: the skill's own files
# under a skills tree (PF-2's vector) and the TEMPLATE_SYNC_MAP canonicals
# injected into it from core/standards/, operations/templates/ and core/schemas/.
# The second vector is the one that shipped a real defect: a pull request whose
# only changes were to an injected canonical staled three committed .skill
# packages and merged green, because the CI gate's path filter did not name those
# trees and a non-matching path filter produces no check run at all. PF-6
# reproduces that edit shape and asserts the same verdict->exit contract PF-2
# asserts on the other vector. PF-7 clears it by RESTORING the canonical rather
# than rebuilding, for the same reason PF-4 restores: an anti-vacuity control
# that depends on the packager is not a control.
#
# PF-6 NEVER HARDCODES ITS TARGET. It extracts TEMPLATE_SYNC_MAP with the same
# production extractor build-skill-packages.sh uses, resolves each canonical
# through resolve_template_sync_source() SOURCED from
# core/deploy/lib-template-sync-source.sh, and takes the first resolved source
# that is markdown and lives outside every skills tree. Re-implementing the
# resolver here would assert against a copy of the rule instead of the rule --
# the exact divergence that lib exists to make impossible -- and a hardcoded
# filename would silently stop exercising this vector the day the map is
# re-homed. An empty selection is a LOUD FAILURE, never a skip: it would mean the
# map no longer injects anything from outside the skills trees, which is a fact
# this suite must announce rather than swallow.
#
# THE ANTI-NARROWING FLOOR (PF-8)
# PF-6 proves the gate DETECTS this vector; PF-8 proves CI still RUNS on it. The
# gate's verdict is the whole-roster content hash -- a global property -- so its
# only sound trigger is "always", and the failure above was a trigger filter, not
# a detector bug. PF-8 asserts that no `paths:` key has been reintroduced. The
# predicate is LINE-ANCHORED: a substring test for `paths` would match the word
# in the workflow's own prose and pass vacuously. And it carries its own
# sensitivity arm, because a probe that cannot see a paths: key would report the
# population clean while asserting nothing.
#
# PF-8 NEVER HARDCODES ITS SENSITIVITY FIXTURE. It scans .github/workflows/ and
# takes the first workflow that CURRENTLY carries a paths:/paths-ignore: key,
# excluding the gate itself so the control can never be satisfied by the very
# defect it guards. Naming one exemplar instead silently invalidates the control
# the day that workflow is legitimately converted -- which is exactly how this
# arm broke once: it pinned release-link-check.yml, that workflow's two filters
# were correctly removed, and the arm went red for naming a stale fixture rather
# than for anything true about the gate. Converting path-filtered workflows is
# ongoing governed work, so the fixture is derived from live state.
#
# The discrimination is established BY THE SCAN: a predicate that matches nothing
# anywhere yields an empty selection, which is a LOUD FAILURE, never a skip --
# the same doctrine PF-6 applies to its own derived target. The report arm then
# re-runs the predicate against the selected path, which guards the selection
# step itself (a clobbered or mis-quoted candidate) rather than the regex.
#
# WHY IT NORMALIZES THE SANDBOX FIRST
# The contract under test is the verdict->exit MAPPING, not the freshness of the
# committed tree. Tree freshness is already asserted by the always-enforce
# lifecycle Check 7 and by the skill-package-freshness CI gate; asserting it a
# third time here would double-gate it and would turn this suite red during the
# legitimate mid-release window in which a release stales a package before its
# terminal rebuild beat. So the sandbox is normalized to FRESH first (rebuilding
# every package only when the as-archived tree is not already fresh), and the
# staleness this test reasons about is the staleness this test itself injects.
# A sandbox that can be neither confirmed fresh nor rebuilt is a loud
# environmental failure, never a skip.
#
# HERMETICITY
# The fixture is a throwaway `git archive HEAD` export of the tracked tree; every
# probe invocation runs with HOME redirected into a sandbox, so neither the
# operator's ~/.claude nor the real working tree is read for install resolution
# or written at all. The real working tree is NEVER staled. The interpreter's
# user-site base is carried across the redirect via PYTHONUSERBASE so the
# redirect does not, by itself, hide packages an unsandboxed run would import —
# a sandbox that silently disables the content verdict would make PF-2 assert
# something weaker than it claims.
#
# Run from anywhere (resolves the repo root from its own location):
#   bash core/deploy/tests/test_package_freshness_exit_codes.sh
#
# Returns 0 only when every assertion RAN and held. A failure or a skip both
# return non-zero — an assertion that did not execute has established nothing,
# and reporting that as success is the defect class this suite exists to catch.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# The skill whose package this test stales and rebuilds. It must be rostered,
# packaged, and carry a references/ tree (the surface the original defect was
# reported against). pmo-qa-auditor is the same probe skill test_deploy_sandbox.sh
# uses, so the two tests share one assumption rather than two.
PROBE_SKILL="pmo-qa-auditor"
PROBE_SKILL_DIR="core/skills/${PROBE_SKILL}"

PASS=0
FAIL=0
SKIP=0
SBX=""           # git-archive export of the tracked tree
SBX_HOME=""      # redirected HOME for every probe invocation
ENFORCE_FILE=""  # synthetic sentinel holding the `enforce` token
WARN_FILE=""     # synthetic sentinel holding the `warn` token
PROBE_LOG=""     # combined output of the MOST RECENT probe_rc invocation
PF9_SHIM=""         # sys.path dir holding a `yaml` module that refuses to import
PF9_SHIM_ACTIVE=""  # non-empty => probe_rc prepends PF9_SHIM to the probe's PYTHONPATH

cleanup() {
  local d
  for d in "${SBX}" "${SBX_HOME}"; do
    [ -n "${d}" ] && [ -d "${d}" ] && rm -rf "${d}"
  done
  [ -n "${ENFORCE_FILE}" ] && [ -f "${ENFORCE_FILE}" ] && rm -f "${ENFORCE_FILE}"
  [ -n "${WARN_FILE}" ] && [ -f "${WARN_FILE}" ] && rm -f "${WARN_FILE}"
  return 0
}
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"
    [ -n "${detail}" ] && printf '         %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

report_skip() {
  printf '  SKIP: %s\n' "$1"
  printf '         reason: %s\n' "$2"
  SKIP=$((SKIP + 1))
}

die_loud() {
  printf '\nENVIRONMENTAL FAILURE: %s\n' "$1" >&2
  printf 'This test fails loudly rather than passing: an unrunnable contract test\n' >&2
  printf 'that reports success is the same defect class it exists to catch.\n' >&2
  exit 1
}

# Carry the interpreter's user-site base across the HOME redirect. Without it the
# redirect alone can hide user-installed modules the packager imports, silently
# demoting the probe's content verdict to its mtime fallback.
PY_USER_BASE="$(python3 -c 'import site; print(site.getuserbase())' 2>/dev/null || true)"

# Run the probe inside the sandbox with a redirected HOME. Echoes the exit code.
# $1 (optional) — absolute path to a sentinel file handed to the probe via
#                 SKILL_PACKAGE_FRESHNESS_ENFORCE_FILE. Omitted => the sandbox's
#                 own committed .github/skill-package-freshness.enforce is used.
#
# The probe's combined output is KEPT, at ${PROBE_LOG}, not discarded. The exit
# code alone cannot say WHICH path produced a verdict, and PF-2 asserts on that
# distinction (see THE PF-2 DISCRIMINATOR in the header). It is written to a FILE
# rather than assigned to a variable on purpose: probe_rc is always called in a
# command substitution, so any variable it assigned would die with that subshell
# and the caller would read an empty string that looks exactly like a clean
# result. A file survives the subshell; ${PROBE_LOG} holds the MOST RECENT
# invocation's output and every reader consumes it before the next probe runs.
probe_rc() {
  local sentinel="${1:-}" rc=0
  (
    cd "${SBX}" || exit 127
    export HOME="${SBX_HOME}"
    [ -n "${PY_USER_BASE}" ] && export PYTHONUSERBASE="${PY_USER_BASE}"
    [ -n "${sentinel}" ] && export SKILL_PACKAGE_FRESHNESS_ENFORCE_FILE="${sentinel}"
    # PF-9's synthetic degradation. PREPEND, never replace: install-tests.yml exports
    # PYTHONPATH (the user-site pin that survives the HOME redirect), so clobbering it
    # would degrade the run by LOSING the user-site rather than by shadowing the
    # module. PF-9c would then be asserting PYTHONPATH restoration — a different claim
    # that happens to produce the same exit code, which is the worst kind of control.
    # An active shim with no directory behind it would probe UNDEGRADED and let PF-9a
    # fail for a reason it could not name, so that state exits loudly instead.
    if [ -n "${PF9_SHIM_ACTIVE:-}" ]; then
      [ -n "${PF9_SHIM:-}" ] || exit 126
      export PYTHONPATH="${PF9_SHIM}${PYTHONPATH:+:${PYTHONPATH}}"
    fi
    bash core/deploy/deploy.sh --check-package-freshness
  ) >"${PROBE_LOG:-/dev/null}" 2>&1
  rc=$?
  printf '%s' "${rc}"
}

# Count the lines of ${2} containing the fixed substring ${1}. Echoes 0 when the
# file is absent or holds no match.
#
# Deliberately implemented WITHOUT grep. A load-bearing detector routed through a
# host `grep` that turns out to be a shim can return a plausible zero for a
# pattern it declined to run, and a zero from a detector that never ran is
# indistinguishable from a clean population — which is the exact defect shape
# this suite exists to refuse. Shell substring matching has no pattern dialect to
# get wrong, and the probe log is a few hundred lines, so the loop is free.
count_fixed() {
  local pat="$1" file="$2" n=0 line
  [ -f "${file}" ] || { printf '0'; return 0; }
  while IFS= read -r line || [ -n "${line}" ]; do
    case "${line}" in *"${pat}"*) n=$((n + 1)) ;; esac
  done < "${file}"
  printf '%s' "${n}"
}

# Rebuild package(s) inside the sandbox. No args => every rostered skill.
# Echoes the builder's exit code; its output is KEPT, at ${BUILD_LOG}.
#
# A FILE, for exactly the reason stated for ${PROBE_LOG} above: every call site is
# a command substitution (`[ "$(sandbox_build)" != "0" ]`), so a variable assigned
# in here dies with that subshell and the caller reads an empty string that looks
# exactly like a builder that printed nothing. That is what the readers observed —
# `(last line: )` — and this card made the diagnostic load-bearing by reddening CI
# on SKIP, where that reason line is the operator's only pointer to the cause.
BUILD_LOG=""
sandbox_build() {
  local rc=0
  (
    cd "${SBX}" || exit 127
    export HOME="${SBX_HOME}"
    [ -n "${PY_USER_BASE}" ] && export PYTHONUSERBASE="${PY_USER_BASE}"
    bash core/deploy/tools/build-skill-packages.sh "$@" 2>&1
  ) >"${BUILD_LOG:-/dev/null}" 2>&1
  rc=$?
  printf '%s' "${rc}"
}

# --- Preflight: fail loud, never skip ---
printf 'test_package_freshness_exit_codes.sh — verdict -> exit-code contract\n'
printf 'repo root: %s\n' "${REPO_ROOT}"

[ -f "${REPO_ROOT}/core/deploy/deploy.sh" ] \
  || die_loud "deploy.sh not found at ${REPO_ROOT}/core/deploy/deploy.sh"
[ -f "${REPO_ROOT}/core/deploy/tools/build-skill-packages.sh" ] \
  || die_loud "build-skill-packages.sh not found — the remedy assertion cannot run"
[ -d "${REPO_ROOT}/${PROBE_SKILL_DIR}/references" ] \
  || die_loud "probe skill references/ missing: ${PROBE_SKILL_DIR}/references"
[ -f "${REPO_ROOT}/packages/${PROBE_SKILL}.skill" ] \
  || die_loud "probe skill package missing: packages/${PROBE_SKILL}.skill"
command -v python3 >/dev/null 2>&1 \
  || die_loud "python3 absent — the staged-rebuild content verdict cannot run"
command -v unzip >/dev/null 2>&1 \
  || die_loud "unzip absent — the package content hash cannot be computed"
command -v git >/dev/null 2>&1 \
  || die_loud "git absent — the sandbox fixture cannot be exported"

# --- Fixture: throwaway export of the tracked tree ---
SBX=$(mktemp -d -t pkgfresh-sbx.XXXXXX) || die_loud "mktemp failed (sandbox)"
SBX_HOME=$(mktemp -d -t pkgfresh-home.XXXXXX) || die_loud "mktemp failed (home)"

# Must be set before the first probe_rc / sandbox_build call below; both live under
# SBX_HOME so cleanup() carries them away with the rest of the fixture.
PROBE_LOG="${SBX_HOME}/probe.log"
BUILD_LOG="${SBX_HOME}/build.log"

if ! (cd "${REPO_ROOT}" && git archive HEAD) | tar -x -C "${SBX}" 2>/dev/null; then
  die_loud "git archive HEAD | tar -x failed — could not build the sandbox fixture"
fi
[ -f "${SBX}/core/deploy/deploy.sh" ] \
  || die_loud "sandbox fixture incomplete (no core/deploy/deploy.sh)"

# Deterministic stale target: the alphabetically-first markdown file under the
# probe skill's references/. Named by rule rather than by literal filename so a
# rename in the corpus does not silently un-test the assertion.
STALE_REL=$(cd "${SBX}/${PROBE_SKILL_DIR}/references" \
  && ls -1 ./*.md 2>/dev/null | LC_ALL=C sort | head -1)
[ -n "${STALE_REL}" ] \
  || die_loud "no markdown file under ${PROBE_SKILL_DIR}/references to stale"
STALE_TARGET="${SBX}/${PROBE_SKILL_DIR}/references/${STALE_REL#./}"
PRISTINE_COPY="${SBX_HOME}/pristine-stale-target.bak"
cp "${STALE_TARGET}" "${PRISTINE_COPY}" || die_loud "could not snapshot the stale target"

# --- Normalize the sandbox to FRESH (see the header rationale) ---
printf '\nNormalizing the sandbox fixture to FRESH\n'
RC_ARCHIVED=$(probe_rc)
if [ "${RC_ARCHIVED}" = "0" ]; then
  printf '  as-archived tree is already package-fresh (rc=0) — no rebuild needed\n'
else
  printf '  as-archived tree is not fresh (rc=%s) — rebuilding every package in the sandbox\n' "${RC_ARCHIVED}"
  if [ "$(sandbox_build)" != "0" ]; then
    [ -s "${BUILD_LOG}" ] && tail -20 "${BUILD_LOG}" >&2
    die_loud "sandbox package rebuild failed — cannot establish the FRESH baseline"
  fi
  RC_ARCHIVED=$(probe_rc)
  [ "${RC_ARCHIVED}" = "0" ] \
    || die_loud "sandbox still not fresh after a full rebuild (rc=${RC_ARCHIVED}) — fixture unusable"
  cp "${STALE_TARGET}" "${PRISTINE_COPY}" || die_loud "could not re-snapshot the stale target"
fi

# --- PF-1: fresh sandbox, committed sentinel default -> exit 0 ---
printf '\nPF-1: FRESH tree, committed sentinel default -> expect exit 0\n'
RC1=$(probe_rc)
if [ "${RC1}" = "0" ]; then
  report "PF-1 FRESH -> exit 0 (clean control)" 1
else
  report "PF-1 FRESH -> exit 0 (clean control)" 0 "expected 0, observed ${RC1}"
fi

# --- Stale exactly one package: append a byte to a references/ file, no rebuild ---
printf '\nStaling %s via %s (no rebuild)\n' "${PROBE_SKILL}" "${STALE_REL#./}"
printf '\n<!-- package-freshness exit-code regression fixture -->\n' >> "${STALE_TARGET}" \
  || die_loud "could not append to the stale target"

# --- PF-2: STALE + non-enforce sentinel -> exit 2 (THE regression assertion) ---
# Pins a SYNTHETIC `warn` sentinel rather than inheriting the sandbox's committed
# one, mirroring PF-3's synthetic-`enforce` pattern. See EVERY MODE-DEPENDENT ARM
# PINS ITS OWN SYNTHETIC SENTINEL in the header: this arm asserts the contract's
# `!= enforce` row, not the repository's current posture, so it must not change
# meaning when the committed token is flipped.
WARN_FILE=$(mktemp -t pkgfresh-warn.XXXXXX) || die_loud "mktemp failed (warn sentinel)"
printf '# synthetic sentinel for PF-2 / PF-6\nwarn\n' > "${WARN_FILE}"
printf '\nPF-2: STALE tree, synthetic warn sentinel -> expect exit 2\n'
RC2=$(probe_rc "${WARN_FILE}")
if [ "${RC2}" = "2" ]; then
  report "PF-2 STALE + warn -> exit 2 (advisory, non-zero, distinguishable)" 1
elif [ "${RC2}" = "0" ]; then
  report "PF-2 STALE + warn -> exit 2 (advisory, non-zero, distinguishable)" 0 \
    "observed 0 — THE REGRESSION: a stale package reports success in the exit status"
else
  report "PF-2 STALE + warn -> exit 2 (advisory, non-zero, distinguishable)" 0 \
    "expected 2, observed ${RC2}"
fi

# --- PF-2b / PF-2c: the exit code alone does not say WHICH path produced it ---
# Read from the SAME probe invocation PF-2 just scored, before any later probe
# overwrites ${PROBE_LOG}. See THE PF-2 DISCRIMINATOR in the header.
PF2_CONTENT=$(count_fixed "${PROBE_SKILL} — source content changed since build" "${PROBE_LOG}")
PF2_DEGRADED=$(count_fixed 'staged rebuild failed to run' "${PROBE_LOG}")

if [ ! -s "${PROBE_LOG}" ]; then
  report "PF-2b the STALE verdict came from the CONTENT path (rebuilt hash != baseline)" 0 \
    "the probe emitted NO output — the discriminator read an empty extraction, which is a broken probe, not a clean result"
elif [ "${PF2_CONTENT}" -ge 1 ]; then
  report "PF-2b the STALE verdict came from the CONTENT path (rebuilt hash != baseline)" 1
else
  report "PF-2b the STALE verdict came from the CONTENT path (rebuilt hash != baseline)" 0 \
    "no 'source content changed since build' line names ${PROBE_SKILL}, so exit ${RC2} was reached WITHOUT a content verdict — the mtime pre-filter alone reaches the same exit code, and PF-2 cannot tell the two apart on its own"
fi

if [ ! -s "${PROBE_LOG}" ]; then
  report "PF-2c no degraded fallback: zero 'staged rebuild failed' lines across the roster" 0 \
    "the probe emitted NO output — a zero count over an empty extraction asserts nothing"
elif [ "${PF2_DEGRADED}" -eq 0 ]; then
  report "PF-2c no degraded fallback: zero 'staged rebuild failed' lines across the roster" 1
else
  report "PF-2c no degraded fallback: zero 'staged rebuild failed' lines across the roster" 0 \
    "${PF2_DEGRADED} rostered skill(s) fell back to the mtime pre-filter because the staged rebuild could not run — this run's verdict is partly mtime-derived, so it does not establish the content contract this suite claims to assert"
fi

# --- PF-3: same stale tree + `enforce` sentinel -> exit 1 (blocking) ---
printf '\nPF-3: same STALE tree, sentinel token enforce -> expect exit 1\n'
ENFORCE_FILE=$(mktemp -t pkgfresh-enforce.XXXXXX) || die_loud "mktemp failed (sentinel)"
printf '# synthetic sentinel for PF-3\nenforce\n' > "${ENFORCE_FILE}"
RC3=$(probe_rc "${ENFORCE_FILE}")
if [ "${RC3}" = "1" ]; then
  report "PF-3 STALE + enforce -> exit 1 (blocking)" 1
else
  report "PF-3 STALE + enforce -> exit 1 (blocking)" 0 "expected 1, observed ${RC3}"
fi

# --- PF-4: remove the injected staleness -> exit 0 (anti-vacuity, packager-free) ---
printf '\nPF-4: injected staleness removed (file restored) -> expect exit 0\n'
cp "${PRISTINE_COPY}" "${STALE_TARGET}" || die_loud "could not restore the stale target"
RC4=$(probe_rc)
if [ "${RC4}" = "0" ]; then
  report "PF-4 staleness removed -> exit 0 (probe is not unconditionally non-zero)" 1
else
  report "PF-4 staleness removed -> exit 0 (probe is not unconditionally non-zero)" 0 \
    "expected 0, observed ${RC4}"
fi

# --- PF-5: the DOCUMENTED REMEDY clears the gate (packager-dependent) ---
printf '\nPF-5: staleness cleared by a build-skill-packages.sh rebuild -> expect exit 0\n'
printf '\n<!-- package-freshness exit-code regression fixture (remedy arm) -->\n' >> "${STALE_TARGET}" \
  || die_loud "could not re-append to the stale target"
if [ "$(sandbox_build "${PROBE_SKILL}")" != "0" ]; then
  report_skip "PF-5 rebuild -> exit 0 (documented remedy clears the gate)" \
    "build-skill-packages.sh could not run on this host (last line: $(tail -1 "${BUILD_LOG}" 2>/dev/null)). \
The packager is a host capability, not a property of the contract under test; PF-1..PF-4 above still ran."
else
  RC5=$(probe_rc)
  if [ "${RC5}" = "0" ]; then
    report "PF-5 rebuild -> exit 0 (documented remedy clears the gate)" 1
  else
    report "PF-5 rebuild -> exit 0 (documented remedy clears the gate)" 0 \
      "expected 0, observed ${RC5}"
  fi
fi

# --- Re-normalize before the injected-canonical arm ---
# PF-5 either rebuilt the probe skill's package against an appended source, or was
# skipped with that append still in place. Either way the sandbox's freshness is
# whatever PF-5 left behind, and PF-6 asserts a STALE verdict -- so without a
# CONFIRMED-fresh baseline PF-6 could report exit 2 for the previous arm's reason
# and PF-7 would then fail for a reason that has nothing to do with its subject.
printf '\nRe-normalizing the sandbox to FRESH before the injected-canonical arm\n'
cp "${PRISTINE_COPY}" "${STALE_TARGET}" || die_loud "could not restore the stale target before PF-6"
RC_RENORM=$(probe_rc)
if [ "${RC_RENORM}" != "0" ]; then
  if [ "$(sandbox_build)" != "0" ]; then
    [ -s "${BUILD_LOG}" ] && tail -20 "${BUILD_LOG}" >&2
    die_loud "sandbox rebuild failed before PF-6 — cannot establish the FRESH baseline"
  fi
  RC_RENORM=$(probe_rc)
  [ "${RC_RENORM}" = "0" ] \
    || die_loud "sandbox still not fresh before PF-6 (rc=${RC_RENORM}) — the injected-canonical arm would assert nothing"
fi
printf '  baseline confirmed FRESH (rc=0)\n'

# --- Derive PF-6's target: DERIVED, never hardcoded (see the header rationale) ---
# The resolver is SOURCED, not replicated: replicating it here would assert
# against a copy of the rule rather than the rule itself.
# shellcheck source=core/deploy/lib-template-sync-source.sh
. "${SBX}/core/deploy/lib-template-sync-source.sh" 2>/dev/null \
  || die_loud "could not source core/deploy/lib-template-sync-source.sh — PF-6 must resolve through the real resolver, never a copy of it"
command -v resolve_template_sync_source >/dev/null 2>&1 \
  || die_loud "resolve_template_sync_source undefined after sourcing the resolver lib — the map cannot be resolved"

# Same awk-window + grep + sed extractor build-skill-packages.sh uses. The grep is
# deliberately the three-field form: a looser quoted-string match also captures a
# quoted phrase inside the map's own comment block and yields a phantom entry.
CANONICAL_REL=""
while IFS= read -r map_entry; do
  [ -n "${map_entry}" ] || continue
  cand_name="$(printf '%s' "${map_entry}" | cut -d: -f2)"
  [ -n "${cand_name}" ] || continue
  cand_src="$(resolve_template_sync_source "${cand_name}")"
  case "${cand_src}" in
    core/skills/*|operations/skills/*|release/skills/*) continue ;;
    *.md)                                              ;;
    *)                                                 continue ;;
  esac
  [ -f "${SBX}/${cand_src}" ] || continue
  CANONICAL_REL="${cand_src}"
  break
done < <(awk '/^TEMPLATE_SYNC_MAP=\(/,/^\)/' "${SBX}/core/deploy/deploy.sh" \
         | grep -E '^[[:space:]]*"[^"]+:[^"]+:[^"]+"' \
         | sed 's/^[[:space:]]*"//; s/"$//; s/[[:space:]]*#.*//')

[ -n "${CANONICAL_REL}" ] \
  || die_loud "no TEMPLATE_SYNC_MAP canonical resolves to a markdown source outside every skills tree — the injected-canonical vector appears not to exist, which this suite announces rather than swallows"

CANONICAL_TARGET="${SBX}/${CANONICAL_REL}"
CANONICAL_PRISTINE="${SBX_HOME}/pristine-canonical.bak"
cp "${CANONICAL_TARGET}" "${CANONICAL_PRISTINE}" \
  || die_loud "could not snapshot the injected canonical ${CANONICAL_REL}"

# --- PF-6: injected canonical staled, no rebuild -> exit 2 (the v4.06 shape) ---
printf '\nPF-6: injected canonical %s staled (no rebuild), synthetic warn sentinel -> expect exit 2\n' "${CANONICAL_REL}"
printf '\n<!-- package-freshness injected-canonical regression fixture -->\n' >> "${CANONICAL_TARGET}" \
  || die_loud "could not append to the injected canonical ${CANONICAL_REL}"
# Same synthetic-`warn` pin as PF-2, and for the same reason.
RC6=$(probe_rc "${WARN_FILE}")
if [ "${RC6}" = "2" ]; then
  report "PF-6 injected canonical STALE + warn -> exit 2 (the injected-canonical vector)" 1
elif [ "${RC6}" = "0" ]; then
  report "PF-6 injected canonical STALE + warn -> exit 2 (the injected-canonical vector)" 0 \
    "observed 0 — a canonical outside every skills tree (${CANONICAL_REL}) staled a package and the probe reported success. This is the shape that merged green while staling three packages."
else
  report "PF-6 injected canonical STALE + warn -> exit 2 (the injected-canonical vector)" 0 \
    "expected 2, observed ${RC6} (target: ${CANONICAL_REL})"
fi

# --- PF-7: restore the canonical -> exit 0 (PF-6's anti-vacuity control) ---
printf '\nPF-7: injected canonical restored (restore, not rebuild) -> expect exit 0\n'
cp "${CANONICAL_PRISTINE}" "${CANONICAL_TARGET}" \
  || die_loud "could not restore the injected canonical ${CANONICAL_REL}"
RC7=$(probe_rc)
if [ "${RC7}" = "0" ]; then
  report "PF-7 injected canonical restored -> exit 0 (PF-6 is not unconditionally non-zero)" 1
else
  report "PF-7 injected canonical restored -> exit 0 (PF-6 is not unconditionally non-zero)" 0 \
    "expected 0, observed ${RC7} (target: ${CANONICAL_REL})"
fi

# --- PF-8: anti-narrowing floor — the gate workflow declares no `paths:` key ---
printf '\nPF-8: skill-package-freshness declares no paths: key -> expect ABSENT\n'
PF8_WF_DIR="${REPO_ROOT}/.github/workflows"
PF8_GATE_WF="${PF8_WF_DIR}/skill-package-freshness.yml"
PF8_PATHS_RE='^[[:space:]]+paths(-ignore)?:'

[ -f "${PF8_GATE_WF}" ] \
  || die_loud "gate workflow missing: .github/workflows/skill-package-freshness.yml"

# Derive the sensitivity fixture from live state rather than naming an exemplar:
# any workflow that currently carries a paths:/paths-ignore: key proves the
# predicate discriminates. The gate is excluded so that a paths: key reintroduced
# ON THE GATE can never supply the control that is meant to validate the probe
# used against it. Deterministic first-match keeps the failure text reproducible.
PF8_SENSITIVITY_WF=""
for PF8_CANDIDATE in "${PF8_WF_DIR}"/*.yml "${PF8_WF_DIR}"/*.yaml; do
  [ -f "${PF8_CANDIDATE}" ] || continue
  [ "${PF8_CANDIDATE}" = "${PF8_GATE_WF}" ] && continue
  if grep -qE "${PF8_PATHS_RE}" "${PF8_CANDIDATE}"; then
    PF8_SENSITIVITY_WF="${PF8_CANDIDATE}"
    break
  fi
done

[ -n "${PF8_SENSITIVITY_WF}" ] \
  || die_loud "PF-8 sensitivity arm has no fixture: no workflow under .github/workflows/ other than the gate itself carries a paths:/paths-ignore: key — without one the predicate cannot be shown to discriminate, so a clean result on the gate would be unfalsifiable. If every path filter has been legitimately removed, this arm needs a purpose-built fixture, not a weakened assertion."

PF8_SENSITIVITY_REL="${PF8_SENSITIVITY_WF#${REPO_ROOT}/}"
if grep -qE "${PF8_PATHS_RE}" "${PF8_SENSITIVITY_WF}"; then
  report "PF-8 sensitivity: the anchored paths: predicate sees a key where one exists (fixture: ${PF8_SENSITIVITY_REL})" 1
else
  report "PF-8 sensitivity: the anchored paths: predicate sees a key where one exists (fixture: ${PF8_SENSITIVITY_REL})" 0 \
    "${PF8_SENSITIVITY_REL} was selected BY the paths: predicate and then did not satisfy it — the selection step is broken, so PF-8 is a BROKEN PROBE, not a clean population"
fi

if grep -qE "${PF8_PATHS_RE}" "${PF8_GATE_WF}"; then
  report "PF-8 anti-narrowing: no paths: key on the package-freshness gate" 0 \
    "a \`paths:\` filter was reintroduced — this gate's verdict is whole-roster; re-read the always-reports rationale in the workflow header before re-adding one"
else
  report "PF-8 anti-narrowing: no paths: key on the package-freshness gate" 1
fi

# --- PF-9a..d: the UNMEASURED state has its own verdict and its own exit code ---
# The degradation is injected the way the real one arrived: a module the packager
# imports stops resolving while the interpreter stays healthy. A sys.path entry
# holding a `yaml` that raises makes the packager's real import chain
# (package_skill.py -> quick_validate.py -> yaml) fail without touching python3
# itself, which is the shape the CI defect had — the guard tested the interpreter,
# the packager needed the module, and 55 of 55 skills fell through to a fallback
# that reports FRESH on a fresh checkout by construction.
#
# The tree is NOT staled for PF-9a..c. That is the whole point: with no staleness
# anywhere, the pre-change probe returns FRESH 55 and exit 0 — a green gate over an
# arm that ran for zero skills. PF-9a asserts that the same conditions now produce a
# withheld verdict and its own exit code instead.
#
# The sandbox's freshness at entry is established by PF-7 (rc 0, asserted) and is not
# re-probed here: a dirty baseline cannot pass silently, because it would drive PF-9a
# to 2 rather than 3 and PF-9c to 2 rather than 0 — both loud.
PF9_SHIM="${SBX_HOME}/pf9-shim"
mkdir -p "${PF9_SHIM}" || die_loud "could not create the PF-9 shim dir"
printf 'raise ImportError("PF-9 synthetic degradation: PyYAML unavailable")\n' \
  > "${PF9_SHIM}/yaml.py" || die_loud "could not write the PF-9 shim"

printf '\nPF-9a: packager module unimportable, tree FRESH, synthetic warn sentinel -> expect exit 3\n'
PF9_SHIM_ACTIVE=1
RC9A=$(probe_rc "${WARN_FILE}")
PF9_SHIM_ACTIVE=""
if [ "${RC9A}" = "3" ]; then
  report "PF-9a content arm unmeasurable -> exit 3 (withheld verdict, own code)" 1
elif [ "${RC9A}" = "0" ]; then
  report "PF-9a content arm unmeasurable -> exit 3 (withheld verdict, own code)" 0 \
    "observed 0 — THE REGRESSION: the content arm ran for zero skills and the probe reported success. This is the state that let a dependency outage read as 55 of 55 packages verified."
elif [ "${RC9A}" = "2" ]; then
  report "PF-9a content arm unmeasurable -> exit 3 (withheld verdict, own code)" 0 \
    "observed 2 — the sandbox was not FRESH at PF-9 entry, so this arm scored a staleness finding rather than the outage it exists to assert"
else
  report "PF-9a content arm unmeasurable -> exit 3 (withheld verdict, own code)" 0 \
    "expected 3, observed ${RC9A}"
fi

# --- PF-9b: attribute that exit 3 to the degradation this arm injected ---
# Read from the SAME probe invocation PF-9a just scored, before any later probe
# overwrites ${PROBE_LOG} — the PF-2b pattern.
#
# The discriminator is the REASON STRING, not the per-skill `staged rebuild failed to
# run` line, and the difference is not cosmetic. That line belongs to the OTHER
# degradation shape: a capability probe that passed and a per-skill build that then
# failed anyway. Here the capability probe catches the missing module up front, so the
# loop never attempts a rebuild and emits no such line — measured, 0 occurrences. An
# arm asserting it would fail against correct behaviour. What the probe does emit is
# the aggregate outage line with its cause and its denominator, so that is what is
# asserted, together with the stated denominator CIAC-4 requires.
PF9_TOKEN=$(count_fixed 'NOT-EVALUATED' "${PROBE_LOG}")
PF9_CAUSE=$(count_fixed 'packager-import-failed' "${PROBE_LOG}")
PF9_DENOM=$(count_fixed 'content arm did not conclude for' "${PROBE_LOG}")

# The denominator is READ, never hardcoded. A literal roster size would stop asserting
# the day a skill is added or retired, and would do so by going red for a reason that
# has nothing to do with the contract — the failure mode PF-6 and PF-8 both take pains
# to avoid. The outage line reads "... did not conclude for <unmeasured> of <total>
# rostered skill(s) ...": extracting BOTH and requiring them equal asserts the
# stated-denominator property itself rather than today's value of it. Under a
# module-level outage the packager resolves for no skill, so the whole roster is
# unmeasured; an unmeasured count short of the total would mean the outage was
# partial and this arm's premise did not hold.
PF9_PAIR=""
if [ -f "${PROBE_LOG}" ]; then
  while IFS= read -r line || [ -n "${line}" ]; do
    case "${line}" in
      *"content arm did not conclude for "*)
        PF9_PAIR="${line#*content arm did not conclude for }"; break ;;
    esac
  done < "${PROBE_LOG}"
fi
PF9_UNMEASURED="${PF9_PAIR%% *}"
PF9_REST="${PF9_PAIR#* of }"
PF9_TOTAL="${PF9_REST%% *}"

if [ ! -s "${PROBE_LOG}" ]; then
  report "PF-9b exit 3 is attributable to the injected module outage, with its denominator stated" 0 \
    "the probe emitted NO output — the discriminator read an empty extraction, which is a broken probe, not a clean result"
elif [ "${PF9_TOKEN}" -lt 1 ] || [ "${PF9_CAUSE}" -lt 1 ] || [ "${PF9_DENOM}" -lt 1 ]; then
  report "PF-9b exit 3 is attributable to the injected module outage, with its denominator stated" 0 \
    "expected each limb >= 1, observed NOT-EVALUATED=${PF9_TOKEN} packager-import-failed=${PF9_CAUSE} outage-line=${PF9_DENOM}. Exit ${RC9A} was reached without naming the outage, its cause, or the share of the roster it covered — so the verdict states less than the contract claims it states."
elif [ -n "${PF9_UNMEASURED}" ] && [ "${PF9_UNMEASURED}" = "${PF9_TOTAL}" ]; then
  report "PF-9b exit 3 is attributable to the injected module outage, with its denominator stated (${PF9_UNMEASURED} of ${PF9_TOTAL})" 1
else
  report "PF-9b exit 3 is attributable to the injected module outage, with its denominator stated" 0 \
    "the outage line reported ${PF9_UNMEASURED:-<none>} of ${PF9_TOTAL:-<none>} — a module-level outage leaves NO skill measurable, so an unmeasured count short of the roster total means the injected degradation was partial and this arm asserted something weaker than it claims"
fi

# --- PF-9c: shim removed, nothing else changed -> exit 0 (anti-vacuity control) ---
# Without this arm PF-9a would pass against a probe that returned 3 unconditionally.
# No sentinel pin: this arm asserts FRESH -> 0, the `any` row, which is
# sentinel-independent by construction — the same reason PF-1 / PF-4 / PF-7 take none.
printf '\nPF-9c: shim removed, nothing else changed -> expect exit 0\n'
RC9C=$(probe_rc)
if [ "${RC9C}" = "0" ]; then
  report "PF-9c shim removed -> exit 0 (PF-9a is not unconditionally non-zero)" 1
else
  report "PF-9c shim removed -> exit 0 (PF-9a is not unconditionally non-zero)" 0 \
    "expected 0, observed ${RC9C} — PF-9a's exit 3 cannot be attributed to the shim if the probe does not return to 0 without it"
fi

# --- PF-9d: precedence — STALE dominates the outage -> exit 2, not 3 ---
# A measurement outage must never SUPPRESS a real finding. The loop runs to completion
# and the stale counter is tested first, so a tree that is both stale and partly
# unmeasured reports the staleness. Asserting 2 here also proves the outage does not
# short-circuit the roster loop, which an early return on a failed capability probe
# would do — and which would silently convert today's blocking behaviour into an
# advisory one.
#
# THE STALENESS IS SEEDED IN THE SIDECAR, NOT IN THE SOURCE, AND THAT IS THE ARM.
# Appending to a source file is PF-2's vector, and with the packager disabled it is
# detectable only by the mtime pre-filter — which is FALSE for every skill on a fresh
# checkout by construction (see THE mtime FALLBACK IS INERT in deploy.sh). An arm
# resting on it would assert precedence over a finding CI can never produce, and would
# pass while establishing nothing about the case that matters. The baseline-vs-live
# package hash compare needs only unzip + shasum, so it is the finding class that
# actually SURVIVES a packager outage on a fresh checkout — precedence has to be
# asserted over that one to mean anything. A sidecar that disagrees with its package
# is also a real staleness class in its own right: it is what a rebuild committed
# without its regenerated sidecar leaves behind.
printf '\nPF-9d: STALE tree AND packager unimportable, synthetic warn sentinel -> expect exit 2 (STALE wins)\n'
PF9D_SIDECAR="${SBX}/packages/${PROBE_SKILL}.skill.sha256"
PF9D_SIDECAR_PRISTINE="${SBX_HOME}/pristine-pf9d-sidecar.bak"
[ -f "${PF9D_SIDECAR}" ] \
  || die_loud "content baseline sidecar missing: packages/${PROBE_SKILL}.skill.sha256 — PF-9d cannot seed a packager-independent finding"
cp "${PF9D_SIDECAR}" "${PF9D_SIDECAR_PRISTINE}" \
  || die_loud "could not snapshot the PF-9d sidecar"
printf '0000000000000000000000000000000000000000000000000000000000000000\n' > "${PF9D_SIDECAR}" \
  || die_loud "could not seed the PF-9d sidecar mismatch"
PF9_SHIM_ACTIVE=1
RC9D=$(probe_rc "${WARN_FILE}")
PF9_SHIM_ACTIVE=""
cp "${PF9D_SIDECAR_PRISTINE}" "${PF9D_SIDECAR}" \
  || die_loud "could not restore the PF-9d sidecar"
if [ "${RC9D}" = "2" ]; then
  report "PF-9d STALE > NOT-EVALUATED (a measurement outage cannot suppress a finding)" 1
elif [ "${RC9D}" = "3" ]; then
  report "PF-9d STALE > NOT-EVALUATED (a measurement outage cannot suppress a finding)" 0 \
    "observed 3 — the outage SUPPRESSED a real staleness finding. Either the precedence is inverted, or the capability probe returns before the roster loop runs."
else
  report "PF-9d STALE > NOT-EVALUATED (a measurement outage cannot suppress a finding)" 0 \
    "expected 2, observed ${RC9D}"
fi

# --- PF-10 / PF-11: the automated-dependency ingress ---
# See THE AUTOMATED-DEPENDENCY INGRESS in the header for why this vector needs its own
# arm and why the mtime is restored.

# Derive the target through the REAL resolver rather than naming one. Basenames are the
# dependency-manifest classes a package manager would open; membership in a skill's
# content set is decided by the resolver, not by the path looking plausible.
PF10_MANIFEST_NAMES="package.json package-lock.json yarn.lock pnpm-lock.yaml requirements.txt Pipfile.lock poetry.lock go.sum Gemfile.lock Cargo.lock composer.lock"
PF10_TARGET=""
PF10_TARGET_REL=""
PF10_SKILL=""

for pf10_tree in core operations release; do
  [ -d "${SBX}/${pf10_tree}/skills" ] || continue
  while IFS= read -r pf10_cand; do
    [ -n "${pf10_cand}" ] || continue
    case " ${PF10_MANIFEST_NAMES} " in
      *" ${pf10_cand##*/} "*) ;;
      *) continue ;;
    esac
    pf10_rel="${pf10_cand#${SBX}/}"
    # The resolver reads repo-relative paths on STDIN. An argv invocation returns empty
    # for every input INCLUDING one that genuinely cascades, which would read here as
    # "not in any content set" while having measured nothing.
    pf10_resolved="$(
      cd "${SBX}" || exit 127
      printf '%s\n' "${pf10_rel}" \
        | bash core/deploy/tools/build-skill-packages.sh --skills-for-paths 2>/dev/null \
        | head -1
    )"
    if [ -n "${pf10_resolved}" ]; then
      PF10_TARGET="${pf10_cand}"
      PF10_TARGET_REL="${pf10_rel}"
      PF10_SKILL="${pf10_resolved}"
      break
    fi
  done < <(find "${SBX}/${pf10_tree}/skills" -type f -not -path '*/.*' 2>/dev/null | LC_ALL=C sort)
  [ -n "${PF10_TARGET}" ] && break
done

[ -n "${PF10_TARGET}" ] \
  || die_loud "no dependency manifest inside any skills tree resolves to a rostered skill — the automated-dependency vector appears not to exist. If the manifests were deliberately relocated or excluded from the package content set, retire PF-10/PF-11 in that same change rather than leaving an arm that asserts nothing."

# Re-normalize to FRESH before staling. PF-9d restored its sidecar, but a baseline that
# is merely ASSUMED fresh would let PF-10 score a leftover finding and would then send
# PF-11 red for an unrelated reason.
PF10_RC_BASE=$(probe_rc)
if [ "${PF10_RC_BASE}" != "0" ]; then
  if [ "$(sandbox_build)" != "0" ]; then
    [ -s "${BUILD_LOG}" ] && tail -20 "${BUILD_LOG}" >&2
    die_loud "sandbox rebuild failed while re-establishing the FRESH baseline for PF-10"
  fi
  PF10_RC_BASE=$(probe_rc)
  [ "${PF10_RC_BASE}" = "0" ] \
    || die_loud "sandbox not FRESH at PF-10 entry (rc=${PF10_RC_BASE}) — PF-10 cannot attribute a finding to its own edit"
fi
printf '\nPF-10 baseline confirmed FRESH (rc=0); derived target %s -> skill %s\n' \
  "${PF10_TARGET_REL}" "${PF10_SKILL}"

# Snapshot WITH mtime preserved — `touch -r` below reads it back.
PF10_PRISTINE="${SBX_HOME}/pristine-dep-manifest.bak"
cp -p "${PF10_TARGET}" "${PF10_PRISTINE}" \
  || die_loud "could not snapshot the dependency manifest ${PF10_TARGET_REL}"

printf '\nPF-10: dependency manifest %s staled (mtime restored), synthetic warn sentinel -> expect exit 2\n' \
  "${PF10_TARGET_REL}"
# A single trailing space. The file is JSON and trailing whitespace keeps it parseable
# for the package manager, while skill_content_hash hashes BYTES and does not parse — so
# the edit is content-changing and semantically inert, which is the bot-PR shape in
# miniature (a real dependency bump is also semantically inert to the packager).
printf ' ' >> "${PF10_TARGET}" \
  || die_loud "could not append to the dependency manifest ${PF10_TARGET_REL}"
# THE LOAD-BEARING LINE. See the header.
touch -r "${PF10_PRISTINE}" "${PF10_TARGET}" \
  || die_loud "could not restore the mtime on ${PF10_TARGET_REL} — without it PF-10 could reach exit 2 through the mtime pre-filter alone and would assert nothing about the content arm"

RC10=$(probe_rc "${WARN_FILE}")
PF10_CONTENT=$(count_fixed "${PF10_SKILL} — source content changed since build" "${PROBE_LOG}")
PF10_DEGRADED=$(count_fixed 'staged rebuild failed to run' "${PROBE_LOG}")

if [ "${RC10}" = "3" ]; then
  # #5242's unmeasured token. Never a PASS and never silent: the content arm did not run,
  # so this run establishes nothing about the ingress. The fail-on-SKIP rule reddens it.
  report_skip "PF-10 automated-dependency ingress STALE + warn -> exit 2" \
    "content arm not evaluated in this environment (probe returned 3, NOT-EVALUATED) — the ingress assertion did not run"
elif [ "${RC10}" = "0" ]; then
  report "PF-10 automated-dependency ingress STALE + warn -> exit 2 (content arm)" 0 \
    "observed 0 — an automated dependency PR staled a package and the probe reported success. This is the merged-bot-PR shape the arm exists to catch, reproduced in the sandbox."
elif [ "${RC10}" != "2" ]; then
  report "PF-10 automated-dependency ingress STALE + warn -> exit 2 (content arm)" 0 \
    "expected 2, observed ${RC10} (target: ${PF10_TARGET_REL}, skill: ${PF10_SKILL})"
elif [ ! -s "${PROBE_LOG}" ]; then
  report "PF-10 automated-dependency ingress STALE + warn -> exit 2 (content arm)" 0 \
    "the probe emitted NO output — both limbs read an empty extraction, which is a broken probe, not a clean result"
elif [ "${PF10_CONTENT}" -lt 1 ]; then
  report "PF-10 automated-dependency ingress STALE + warn -> exit 2 (content arm)" 0 \
    "exit 2 was reached, but no 'source content changed since build' line names ${PF10_SKILL} — so the verdict did not come from the content arm. With the mtime restored this should be unreachable; it means the staleness was found by some other road and the arm has not asserted the ingress."
elif [ "${PF10_DEGRADED}" -ne 0 ]; then
  report "PF-10 automated-dependency ingress STALE + warn -> exit 2 (content arm)" 0 \
    "${PF10_DEGRADED} rostered skill(s) fell back because the staged rebuild could not run — this run's verdict is partly degraded, so it does not establish the content contract this arm claims"
else
  report "PF-10 automated-dependency ingress (${PF10_TARGET_REL}) STALE + warn -> exit 2 via the content arm" 1
fi

# --- PF-11: restore the manifest -> exit 0 (PF-10's anti-vacuity control) ---
# Restores, never rebuilds (the PF-4 / PF-7 discipline): a control that depended on the
# packager could not distinguish "PF-10's edit was the cause" from "the packager works".
printf '\nPF-11: dependency manifest restored (restore, not rebuild) -> expect exit 0\n'
cp -p "${PF10_PRISTINE}" "${PF10_TARGET}" \
  || die_loud "could not restore the dependency manifest ${PF10_TARGET_REL}"
RC11=$(probe_rc)
if [ "${RC11}" = "0" ]; then
  report "PF-11 dependency manifest restored -> exit 0 (PF-10 is not unconditionally non-zero)" 1
else
  report "PF-11 dependency manifest restored -> exit 0 (PF-10 is not unconditionally non-zero)" 0 \
    "expected 0, observed ${RC11} — PF-10's exit 2 cannot be attributed to its own edit if the probe does not return to 0 once that edit is reverted (target: ${PF10_TARGET_REL})"
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_package_freshness_exit_codes.sh: %d passed, %d failed, %d skipped (bash %s)\n' \
  "${PASS}" "${FAIL}" "${SKIP}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

# A SKIP is not a pass. An assertion that did not run has established nothing,
# and a suite that exits 0 while carrying one reports coverage it did not
# provide. Gating on SKIP is what makes a silently-degraded runner visible to
# CI, which reads the exit status and nothing else.
if [ "${SKIP}" -ne 0 ] && [ "${FAIL}" -eq 0 ]; then
  printf '\nFAILING ON SKIP: %d assertion(s) were skipped and none failed.\n' "${SKIP}"
  printf 'A skipped assertion did not run, so this run does not establish the\n'
  printf 'contract. Resolve the host capability named in the SKIP reason above;\n'
  printf 'the exit status reports the gap rather than reporting green.\n'
fi

if [ "${FAIL}" -ne 0 ] || [ "${SKIP}" -ne 0 ]; then
  exit 1
fi
exit 0
