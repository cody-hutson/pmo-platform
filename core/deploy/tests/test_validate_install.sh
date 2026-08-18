#!/usr/bin/env bash
# test_validate_install.sh — positive control for validate-install.sh check A9
#
# A9 (INSTALL-SKILL-ROSTER) asserts the `version:` frontmatter convention over
# the deployed skills mirror. That mirror is a SUPERSET of the platform roster,
# so the assertion is narrowed to skills the source tree declares at
#   <source-repo>/{core,operations,release}/skills/<name>/SKILL.md
# A narrowing predicate can fail in two directions, and this suite pins BOTH.
#
#   Arm 1 — SENSITIVITY. A genuine platform skill missing `version:` is still
#           caught, by name, after the narrowing. This is the per-skill loss
#           mode: the predicate silently excluding something it owns. If the
#           predicate is ever narrowed further — a module path that moves, a
#           glob typo, an over-eager exclusion — this arm goes red.
#
#   Arm 2 — SPECIFICITY. A deployed skill absent from the source tree is
#           reported INFO and excluded, never FAILed, and the exclusion is
#           visible in the output rather than silent. Also carries the
#           cascade limb: A9 must not be the reason Mode B is suppressed.
#
#   Arm 3 — HEALTHY BASELINE. A9 PASSes and its diagnostic states its own
#           denominator — platform count, non-platform count, oracle path.
#           A pass that reports the population it asserted over cannot
#           silently degrade into a zero-denominator pass.
#
#   Arm 4 — ANTI-VACUITY. The population-level loss mode, and the one the
#           card's acceptance criteria do not name. If the roster oracle
#           resolves to NOTHING, every deployed skill reads as non-platform,
#           the assertion runs over an empty set, and a wholly broken install
#           PASSes. Arm 4 repoints --source-repo at a tree with no skills and
#           requires FAIL-on-roster-resolution, never PASS.
#
# Arms 3 and 4 are a matched pair differing in EXACTLY ONE variable: arm 4's
# source tree is a copy of arm 3's with the skills directories removed, and
# the deployed mirror is byte-identical. That is what makes arm 4's FAIL
# attributable to the oracle and to nothing else. Without arm 4, arm 3's PASS
# and a total-oracle-failure PASS are indistinguishable — which is precisely
# the "silence indistinguishable from approval" inversion this suite exists to
# rule out.
#
# HARD SANDBOX. Every arm runs under its own mktemp root with
# PMO_PLATFORM_DEPLOY_ROOT, HOME, --source-repo, --workspace-root and
# --validation-dir all redirected into it. The operator's live ~/.claude/skills
# is never read and never written.
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/test_validate_install.sh
#
# Portable (bash 3.2; Darwin + Linux). Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
VALIDATE="${REPO_ROOT}/docs/scripts/validate-install.sh"

PASS=0
FAIL=0
FIXTURES=()          # every mktemp dir created; cleaned on EXIT

OUT=""               # last validate-install stdout+stderr capture
RC=0                 # last validate-install exit code

cleanup() {
  local d
  for d in "${FIXTURES[@]:-}"; do
    [ -n "${d}" ] && [ -d "${d}" ] && chmod -R u+rwx "${d}" 2>/dev/null
    [ -n "${d}" ] && [ -d "${d}" ] && rm -rf "${d}"
  done
  return 0
}
trap cleanup EXIT

report() {
  local name="$1" ok="$2" detail="${3:-}"
  if [ "${ok}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '        %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

# All three helpers below feed the haystack to grep through a HERE-STRING, never
# through a pipe, and the choice is load-bearing rather than stylistic.
#
# `grep -q` stops reading at its first match. Piped (`printf … | grep -q …`) that
# makes grep a short-circuiting reader: it closes the pipe while printf may still
# have output to push, printf's next write fails on the broken pipe, and under the
# `pipefail` this suite sets (line 51) printf's non-zero status becomes the
# PIPELINE's. The predicate then reads the opposite of the truth — a SUCCESSFUL
# match reports failure. It is a size-dependent latch, not a constant one: it can
# only fire once the haystack exceeds the pipe capacity, so a suite whose fixtures
# stay under it passes for years and then inverts the first time an arm's output
# grows. Where SIGPIPE is fatal it surfaces as 141; where the shell inherited it
# as SIG_IGN — what a GitHub-hosted runner hands a workflow step — it surfaces as
# a bare 1, indistinguishable from grep legitimately finding nothing.
#
# assert_absent is where that would do real damage, and it is worth naming because
# the damage is silent. Its arms are `match -> FAIL / no-match -> PASS`; an
# inverted status sends a genuine match down the no-match arm, so it would report
# PASS while the forbidden pattern sat in the output. That is a vacuous assertion
# inside the four-arm anti-vacuity control this suite exists to be.
#
# A here-string has no writer to signal. grep's own exit status IS the predicate,
# at every haystack size. `<<<"$1"` also reproduces `printf '%s\n'` exactly — it
# appends the same single trailing newline — so the substitution changes the
# failure mode and nothing else.

# assert_line HAYSTACK REGEX NAME — pass when REGEX is present.
assert_line() {
  if grep -qE -- "$2" <<<"$1"; then report "$3" 1; else report "$3" 0 "expected /$2/ in output"; fi
}
# assert_absent HAYSTACK REGEX NAME — pass when REGEX is absent.
assert_absent() {
  if grep -qE -- "$2" <<<"$1"; then report "$3" 0 "unexpected /$2/ in output"; else report "$3" 1; fi
}
# assert_contains HAYSTACK LITERAL NAME — fixed-string form, for asserting on
# sandbox paths whose '.' and '/' would otherwise be read as regex.
assert_contains() {
  if grep -qF -- "$2" <<<"$1"; then report "$3" 1; else report "$3" 0 "expected literal '$2' in output"; fi
}
# assert_eq GOT WANT NAME
assert_eq() {
  if [ "$1" = "$2" ]; then report "$3" 1; else report "$3" 0 "got '$1' want '$2'"; fi
}

# new_fixture / new_arm return through a GLOBAL rather than stdout, deliberately.
# The sibling suites spell this `SBX="$(new_fixture)"`, but a command
# substitution runs in a subshell, so the `FIXTURES+=` inside it is discarded
# and the EXIT trap never learns about the directory — every run leaks its
# sandboxes. These arms each build a skills mirror, so that leak is not
# theoretical. Assigning a global keeps the registration in the parent shell.
#
# The physical-path resolution is also load-bearing: on Darwin mktemp hands back
# a /var/... path whose realpath is /private/var/..., and validate-install.sh
# compares the validation dir against a `pwd`-resolved workspace root. Without
# it the comparison mismatches and every run emits a spurious out-of-workspace
# warning.
NEW_FIXTURE=""
new_fixture() {
  local d; d="$(mktemp -d -t validate-install-fix.XXXXXX)"
  d="$(cd "${d}" && pwd -P)"
  FIXTURES+=("${d}")
  NEW_FIXTURE="${d}"
}

# --- Fixture construction -------------------------------------------------- #
#
# A9 is the subject, but validate-install.sh runs all thirteen Mode A checks and
# gates Mode B on Mode A's aggregate verdict. So the fixture is built HEALTHY
# across every other check. Two reasons, both load-bearing:
#   1. Each arm's A9 verdict is then attributable to the A9 variation alone.
#   2. Arm 2's cascade limb needs a run where Mode B is actually reached, which
#      is only observable when nothing else in Mode A fails.
#
# The A8 deploy-check stub is a fixture, not a shortcut: A8's contract is that
# `deploy.sh --check --warn` exits 0, and a stub satisfies it hermetically
# without invoking the real 11k-line deploy script from inside a unit test.

# write_skill <path-to-SKILL.md> <name> <with-version:0|1>
write_skill() {
  local md="$1" name="$2" with_version="$3"
  mkdir -p "$(dirname "${md}")"
  if [ "${with_version}" = "1" ]; then
    printf -- '---\nname: %s\nversion: v1.00\ndescription: fixture skill\n---\nbody\n' "${name}" > "${md}"
  else
    printf -- '---\nname: %s\ndescription: fixture skill\n---\nbody\n' "${name}" > "${md}"
  fi
}

# build_source_repo <src> — a minimal but structurally valid pmo-platform clone.
build_source_repo() {
  local src="$1"

  # A7 — core/ with at least one subdirectory.
  # A9 roster oracle — the source-tree skill declarations.
  write_skill "${src}/core/skills/demo-platform-skill/SKILL.md" "demo-platform-skill" 1

  # prompt-builder is DEMO_SKILL: its presence in the source tree lets Mode B's
  # B1 prereq check pass, which is what makes the arm-2 cascade limb meaningful.
  # It is deliberately NOT deployed into the mirror — the source roster
  # legitimately carries skills that are not deployed, and A9's predicate must
  # be an intersection filter rather than a completeness assertion. An oracle
  # that also asserted "every roster member is deployed" would fail this
  # healthy fixture, so this omission is itself an assertion.
  write_skill "${src}/core/skills/prompt-builder/SKILL.md" "prompt-builder" 1

  # A8 — deploy.sh present, executable, exits 0 under --check --warn.
  mkdir -p "${src}/core/deploy"
  printf '#!/usr/bin/env bash\nexit 0\n' > "${src}/core/deploy/deploy.sh"
  chmod +x "${src}/core/deploy/deploy.sh"

  # A3b — composition-surface manifest. One hook-tier row; the installed target
  # is seeded by build_workspace below.
  printf '#!/usr/bin/env bash\nCOMPOSITION_SURFACE_FILES=(\n  "core/config/fixture-surface.txt|hook|raw"\n)\n' \
    > "${src}/core/deploy/composition-surface-manifest.sh"

  # A6 registration parity is deliberately left un-exercised: with no
  # core/settings.json.template in the fixture, A6 reports parity SKIPPED and
  # still PASSes. settings.json wiring is test_install_end_to_end.sh's subject,
  # not this suite's.
}

# build_workspace <ws> — a healthy deployed workspace layout.
build_workspace() {
  local ws="$1" d
  for d in pmo-platform projects knowledge personal .claude; do
    mkdir -p "${ws}/${d}"
  done

  # A3 — at least 8 top-level *.sh hook entrypoints, all +x. One co-deployed
  # sourced library at mode 644 is included on purpose: a healthy install ships
  # sourced libs non-executable, and seeding one here keeps the entrypoint /
  # sourced-lib discriminator exercised rather than merely present.
  mkdir -p "${ws}/.claude/hooks"
  local i
  for i in 1 2 3 4 5 6 7 8; do
    printf '#!/usr/bin/env bash\ntrue\n' > "${ws}/.claude/hooks/block-fixture-${i}.sh"
    chmod +x "${ws}/.claude/hooks/block-fixture-${i}.sh"
  done
  printf '#!/usr/bin/env bash\n# sourced primitive; never invoked directly\n' \
    > "${ws}/.claude/hooks/lib-fixture-resolver.sh"
  chmod 644 "${ws}/.claude/hooks/lib-fixture-resolver.sh"

  # A3b — the hook-tier target the fixture manifest declares.
  printf 'fixture composition surface\n' > "${ws}/.claude/fixture-surface.txt"

  # A4 — state marker.
  printf '{"schema_version":"1.0","setup_completed_at":"2026-01-01T00:00Z"}\n' \
    > "${ws}/.claude/.workspace-setup.state"

  # A5 — CLAUDE.md, >= 500 bytes, no unresolved [OPERATOR_*]/[CLAUDE_*] tokens.
  {
    printf '# Fixture CLAUDE.md\n\n'
    for i in 1 2 3 4 5 6 7 8 9 10; do
      printf 'Fixture workspace context line %d. This file exists so check A5 has a\n' "${i}"
      printf 'CLAUDE.md of realistic size with no unresolved operator tokens in it.\n'
    done
  } > "${ws}/CLAUDE.md"

  # A5b — the operations context anchor. This fixture's minimal source repo ships
  # no lib-instance-path.sh, so A5b currently SKIPs (it will not guess where the
  # anchor lives). The anchor is seeded anyway, deliberately: the fixture's
  # contract is a workspace that is HEALTHY on every check but A9, and the moment
  # the resolver appears in build_source_repo for some other check, an unseeded
  # anchor would FAIL A5b and — through the Mode-A -> Mode-B gate — silently
  # break arm 2's cascade limb rather than the check it belongs to.
  #
  # Deliberately NOT adding lib-instance-path.sh to build_source_repo here: that
  # would activate A2's ambient-directory limb, which this workspace does not
  # provision, turning A2 red for an unrelated reason.
  mkdir -p "${ws}/projects"
  {
    printf '# Fixture operations context anchor\n\n'
    for i in 1 2 3 4; do
      printf 'Pointer line %d. This file exists so check A5b has an anchor of\n' "${i}"
      printf 'realistic size with no unresolved operator tokens in it.\n'
    done
  } > "${ws}/projects/CLAUDE.md"

  # A6 — settings.json, valid JSON, no unresolved tokens.
  printf '{"hooks":{}}\n' > "${ws}/.claude/settings.json"

  # Pre-create the validation-dir parent so the subject's inside-the-workspace
  # prefix check resolves cleanly and emits no out-of-bounds warning.
  mkdir -p "${ws}/.workspace-validation"
}

# build_home <sbx> — operator-scope state: operator.toml (A10) + skills mirror.
build_home() {
  local sbx="$1"
  mkdir -p "${sbx}/.config/pmo-platform" "${sbx}/.claude/skills"
  printf '[meta]\nschema_version = 1\nmanaged_by = "pmo-platform"\n\n[identity]\noperator_name = "Fixture Operator"\n' \
    > "${sbx}/.config/pmo-platform/operator.toml"
}

# _run <sbx> <src> <mode> -> sets OUT, RC
#
# PMO_USER_SETTINGS_FILE points at a path that does not exist so A6b reports
# "not re-homed" and PASSes without reading the operator's real user-scope
# settings file. HOME is redirected so A10 reads the fixture operator.toml.
_run() {
  local sbx="$1" src="$2" mode="$3"
  OUT="$(HOME="${sbx}" \
         PMO_PLATFORM_DEPLOY_ROOT="${sbx}" \
         PMO_USER_SETTINGS_FILE="${sbx}/no-such-user-settings.json" \
         bash "${VALIDATE}" \
           --mode "${mode}" \
           --source-repo "${src}" \
           --workspace-root "${sbx}/Claude" \
           --validation-dir "${sbx}/Claude/.workspace-validation/run" 2>&1)"
  RC=$?
}

# new_arm -> sets NEW_ARM to a fresh, fully-healthy sandbox root. The caller
# then varies only the deployed mirror and/or which tree --source-repo names.
NEW_ARM=""
new_arm() {
  new_fixture
  local sbx="${NEW_FIXTURE}"
  build_source_repo "${sbx}/src"
  build_workspace "${sbx}/Claude"
  build_home "${sbx}"
  NEW_ARM="${sbx}"
}

# --- Preflight ------------------------------------------------------------- #
if [ ! -f "${VALIDATE}" ]; then
  printf 'FAIL: validate-install.sh not found at %s\n' "${VALIDATE}"
  printf 'test_validate_install.sh: 0 passed, 1 failed\n'
  exit 1
fi
# The subject hard-exits 69 without jq, so an environment lacking it cannot
# exercise A9 at all. Reported as a FAILURE rather than a skip on purpose: a
# suite whose absent-dependency path returns success is the exact vacuity this
# suite exists to rule out. CI guarantees jq before invoking the runner.
if ! command -v jq > /dev/null 2>&1; then
  printf 'FAIL: jq is required by validate-install.sh (it exits 69 without it); cannot exercise A9\n'
  printf 'test_validate_install.sh: 0 passed, 1 failed\n'
  exit 1
fi
# The subject is Darwin-gated by design; the opt-in bypass is what CI and the
# cross-platform matrix use, so the suite sets it rather than skipping on Linux.
export PMO_ALLOW_NON_DARWIN=1

# =========================================================================== #
# Arm 1 — SENSITIVITY: a genuine platform skill missing version: is caught     #
# =========================================================================== #
printf '\nArm 1. Sensitivity — platform skill missing version: is still caught by name\n'
new_arm; SBX="${NEW_ARM}"
write_skill "${SBX}/.claude/skills/demo-platform-skill/SKILL.md" "demo-platform-skill" 0
_run "${SBX}" "${SBX}/src" "install"

assert_line "${OUT}" '^\[A9\] FAIL'            "arm1: A9 FAILs on a platform skill missing version:"
assert_line "${OUT}" 'demo-platform-skill'     "arm1: the diagnostic names the offending skill"
assert_line "${OUT}" 'missing version field'   "arm1: the diagnostic names the missing field"
assert_line "${OUT}" 'deploy\.sh --deploy'     "arm1: the remediation hint is emitted (and is runnable — the subject is a roster member)"
assert_absent "${OUT}" '^\[A9\] PASS'          "arm1: A9 does not also PASS"
assert_eq "${RC}" "1"                          "arm1: run exits 1"

# =========================================================================== #
# Arm 2 — SPECIFICITY: a non-platform skill is INFO-reported, never FAILed     #
# =========================================================================== #
printf '\nArm 2. Specificity — non-platform skill excluded and reported, not failed\n'
new_arm; SBX="${NEW_ARM}"
write_skill "${SBX}/.claude/skills/demo-platform-skill/SKILL.md" "demo-platform-skill" 0
# Deployed but absent from the fixture source tree — the operator-authored case.
write_skill "${SBX}/.claude/skills/demo-personal-skill/SKILL.md" "demo-personal-skill" 0
_run "${SBX}" "${SBX}/src" "install"

assert_line "${OUT}" '^\[A9\] INFO'                     "arm2: the exclusion is reported as INFO"
assert_line "${OUT}" '^\[A9\] INFO.*demo-personal-skill' "arm2: the INFO record names the excluded skill"
assert_absent "${OUT}" '^\[A9\] FAIL.*demo-personal-skill' "arm2: the FAIL does not name the non-platform skill"
# The FAIL that IS present is arm 1's, still firing with the personal skill in
# the mirror — proving the exclusion narrowed the population without disarming
# the assertion over what remains.
assert_line "${OUT}" '^\[A9\] FAIL.*demo-platform-skill' "arm2: the platform skill is still caught alongside the exclusion"
assert_line "${OUT}" '1 of 1 platform skill'             "arm2: the FAIL diagnostic states its denominator"
assert_line "${OUT}" '1 non-platform excluded'           "arm2: the FAIL diagnostic reports the exclusion count"

# Arm 2b — the cascade limb. With every platform skill healthy, A9 must not be
# the reason Mode B is suppressed. This is the defect the card was filed on:
# two unownable skills suppressing all four first-task validations.
printf '\nArm 2b. Cascade — a non-platform skill no longer suppresses Mode B\n'
new_arm; SBX="${NEW_ARM}"
write_skill "${SBX}/.claude/skills/demo-platform-skill/SKILL.md" "demo-platform-skill" 1
write_skill "${SBX}/.claude/skills/demo-personal-skill/SKILL.md" "demo-personal-skill" 0
_run "${SBX}" "${SBX}/src" "all"

assert_line "${OUT}" '^\[A9\] PASS'                   "arm2b: A9 PASSes with a healthy roster + an excluded personal skill"
assert_line "${OUT}" '^\[A9\] INFO.*demo-personal-skill' "arm2b: the exclusion is still reported on the PASS path"
assert_absent "${OUT}" 'Mode A FAIL prevented Mode B' "arm2b: Mode B is reached — no Mode-A suppression"
assert_line "${OUT}" '^\[B1\] PASS'                   "arm2b: Mode B actually produces a finding"
# The failing-steps roll-up is the machine-checkable form of "A9 is not the
# suppressor": if A9 had failed, its check id would appear in that block.
assert_absent "${OUT}" '^  - \[A9\] INSTALL-SKILL-ROSTER' "arm2b: A9 contributes nothing to the failing-steps roll-up"

# =========================================================================== #
# Arm 3 — HEALTHY BASELINE: PASS that states its own denominator               #
# =========================================================================== #
# Arms 3 and 4 run in the SAME sandbox against the SAME deployed mirror. The
# only thing that changes between them is which tree --source-repo points at.
# That is what makes arm 4's FAIL attributable to the oracle and nothing else.
printf '\nArm 3. Healthy baseline — A9 PASSes and states its denominator\n'
new_arm; SBX="${NEW_ARM}"
write_skill "${SBX}/.claude/skills/demo-platform-skill/SKILL.md" "demo-platform-skill" 1
write_skill "${SBX}/.claude/skills/demo-personal-skill/SKILL.md" "demo-personal-skill" 1
_run "${SBX}" "${SBX}/src" "install"

assert_line "${OUT}" '^\[A9\] PASS'                   "arm3: A9 PASSes on a healthy mirror"
assert_line "${OUT}" '1 platform skill'               "arm3: PASS states the platform count it asserted over"
assert_line "${OUT}" '1 non-platform excluded'        "arm3: PASS states the excluded count"
assert_contains "${OUT}" "roster oracle ${SBX}/src"   "arm3: PASS names the oracle it derived the population from"
assert_absent "${OUT}" '^\[A9\] FAIL'                 "arm3: A9 does not FAIL on a healthy mirror"
assert_eq "${RC}" "0"                                 "arm3: healthy run exits 0 (whole fixture is genuinely healthy)"
# A healthy baseline is arm 4's control, so a broken baseline must be legible
# rather than merely red — dump the roll-up so Stage 7 can see which check drifted.
if [ "${RC}" != "0" ]; then
  printf '        --- arm3 diagnostic: failing steps ---\n'
  printf '%s\n' "${OUT}" | grep -E '^\[[AB][0-9b]*\] (FAIL|SKIP)' | sed 's/^/        /'
fi

# =========================================================================== #
# Arm 4 — ANTI-VACUITY: an unresolvable roster FAILs, it does not PASS         #
# =========================================================================== #
#
# Same sandbox, same mirror, same everything — except the source tree has no
# skill declarations. Arm 3 is arm 4's control: a green arm 3 followed by a red
# arm 4 proves the FAIL came from roster resolution. Without this arm, arm 3's
# PASS and a total-oracle-failure PASS are indistinguishable.
printf '\nArm 4. Anti-vacuity — an unresolvable roster FAILs rather than passing vacuously\n'
cp -R "${SBX}/src" "${SBX}/src-noskills"
rm -rf "${SBX}/src-noskills/core/skills"
_run "${SBX}" "${SBX}/src-noskills" "install"

assert_line "${OUT}" '^\[A9\] FAIL'                       "arm4: A9 FAILs when the roster oracle resolves to nothing"
assert_absent "${OUT}" '^\[A9\] PASS'                     "arm4: A9 does NOT pass vacuously over an empty population"
assert_line "${OUT}" '^\[A9\] FAIL.*roster'               "arm4: the FAIL is attributed to roster resolution"
assert_line "${OUT}" '0 recognized'                       "arm4: the diagnostic states that nothing resolved"
assert_absent "${OUT}" '^\[A9\] FAIL.*missing version'    "arm4: the FAIL is NOT misattributed to skill health"
assert_line "${OUT}" 'complete pmo-platform clone'        "arm4: the hint points at the source repo, not at the skills"

# =========================================================================== #
# Arm 5 — A5b operations-anchor check: BOTH arms, present and absent           #
# =========================================================================== #
#
# A check that has never been observed FAILING is not known to fail. A5b's whole
# reason for existing is to report non-green when the operations anchor is
# absent, so the absent arm is the one that proves the check rather than the
# present one.
#
# This arm needs the real instance-path resolver in the source tree, because A5b
# resolves the anchor's location rather than guessing it — and with the resolver
# present, A2's ambient-directory limb activates too, so the three ambient dirs
# are provisioned here to keep A2's verdict attributable to A2.
printf '\nArm 5. A5b operations anchor — present PASSes, absent FAILs (both arms)\n'
new_arm; SBX="${NEW_ARM}"
write_skill "${SBX}/.claude/skills/demo-platform-skill/SKILL.md" "demo-platform-skill" 1
mkdir -p "${SBX}/src/core/deploy"
cp "${REPO_ROOT}/core/deploy/lib-instance-path.sh" "${SBX}/src/core/deploy/lib-instance-path.sh"
mkdir -p "${SBX}/Claude/personal/pmo-instance/inbox" \
         "${SBX}/Claude/personal/pmo-instance/ambient-intake" \
         "${SBX}/Claude/personal/pmo-instance/external-sync"

# Precondition, asserted BEFORE any A5b verdict is read: the resolver really did
# load, so A5b is exercising its real path and not silently taking the
# resolver-unavailable SKIP. Without this, both arms below could be reporting on
# a check that never ran.
_run "${SBX}" "${SBX}/src" "install"
assert_absent "${OUT}" '^\[A5b\] SKIP'  "arm5 precondition: A5b is NOT taking the resolver-unavailable SKIP (the check actually ran)"
assert_line   "${OUT}" '^\[A5b\] PASS'  "arm5: A5b PASSes when the anchor is present"
assert_line   "${OUT}" '^\[A5b\] PASS.*projects/CLAUDE\.md' "arm5: the PASS names the resolved anchor path"
assert_eq     "${RC}" "0"               "arm5: healthy run with the anchor present exits 0"

# The absent arm — the one AC-6 is actually about.
rm -f "${SBX}/Claude/projects/CLAUDE.md"
_run "${SBX}" "${SBX}/src" "install"
assert_line   "${OUT}" '^\[A5b\] FAIL'   "arm5b: A5b FAILs when the anchor is absent"
assert_absent "${OUT}" '^\[A5b\] PASS'   "arm5b: A5b does not also PASS"
assert_line   "${OUT}" '^\[A5b\] FAIL.*missing' "arm5b: the FAIL names the absent artifact"
assert_eq     "${RC}" "1"                "arm5b: an absent anchor makes the whole run exit 1 (non-green, not a silent skip)"

# The pre-existing sub-mode must NOT fail on the same workspace: that population
# predates the installer that produces the anchor, so a real check there would
# fail workspaces that were healthy before this release.
_run "${SBX}" "${SBX}/src" "operator-pre-existing"
assert_line   "${OUT}" '^\[A5b\] SKIP'   "arm5c: A5b SKIPs in the operator-pre-existing sub-mode"
assert_absent "${OUT}" '^\[A5b\] FAIL'   "arm5c: the absent anchor does NOT fail a pre-installer workspace"

# --- Summary --------------------------------------------------------------- #
printf '\n======================================================================\n'
printf 'test_validate_install.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
