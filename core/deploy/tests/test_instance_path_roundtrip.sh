#!/usr/bin/env bash
# test_instance_path_roundtrip.sh — needle-file persistence across update (#1830 Part 3).
#
# Proves the localized-context needle file is pure operator data that update.sh
# NEVER regenerates: fill it, run update.sh, hash it; run update.sh again, hash
# it; assert byte-identical (sha256 stable). This is the executable form of the
# issue AC "running update.sh twice against a filled needle file leaves it
# byte-identical."
#
# Method (modeled on test_upgrade_config_durability.sh):
#   1. Pre-seed operator.toml under a sandbox config-root.
#   2. Fresh sandbox install (setup-workspace.sh) with --workspace-root → the
#      install scaffolds the needle file from the .example into the sandbox
#      instance dir.
#   3. Overwrite the scaffolded needle file with a FILLED operator payload
#      (a real-needle stand-in) + record its sha256.
#   4. Run update.sh (non-dry-run) → re-hash → assert == pre-update hash.
#   5. Run update.sh AGAIN → re-hash → assert == original hash (idempotent).
#   6. Assert the resolver also locates the same file (pmo_localized_needles under
#      the sandbox roots) — proves the resolver and the scaffolder agree on the path.
#
# R-8 sandbox invariant: every install/update runs under redirected --config-root
# + --workspace-root into a mktemp -d sandbox; the live ~/.claude is never written.
# A before/after manifest of the real ~/.claude/skills is asserted byte-identical.
#
# Run from repo root:
#   bash core/deploy/tests/test_instance_path_roundtrip.sh
#
# Platform: Darwin-only (setup-workspace.sh is Darwin-only). On Linux/WSL prints
# SKIP and exits 0. Returns non-zero on any failure.

set -uo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'SKIP: test_instance_path_roundtrip.sh — setup-workspace.sh is Darwin-only\n'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
RESOLVER="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
EXAMPLE="${REPO_ROOT}/core/config/localized-context-needles.txt.example"

PASS=0
FAIL=0
SBX=""

cleanup() { [ -n "${SBX}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"; }
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '         %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

sha_file() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# Portable per-file hash + dir manifest for the R-8 proof (mirrors the sibling tests).
hash_file() {
  if command -v md5 >/dev/null 2>&1; then md5 -q "$1" 2>/dev/null
  else md5sum "$1" 2>/dev/null | awk '{print $1}'; fi
}
manifest_dir() {
  local root="$1"; [ -d "${root}" ] || return 0
  local f
  while IFS= read -r f; do printf '%s  %s\n' "${f#"${root}"/}" "$(hash_file "${f}")"; done \
    < <(find "${root}" -type f 2>/dev/null | LC_ALL=C sort)
}

# --- Preflight ---
for f in "${SETUP}" "${RESOLVER}" "${EXAMPLE}"; do
  if [ ! -f "${f}" ]; then printf 'FAIL: required file missing: %s\n' "${f}"; exit 1; fi
done

SBX=$(mktemp -d -t instance-roundtrip.XXXXXX)
mkdir -p "${SBX}/config" "${SBX}/ws" "${SBX}/home"

LIVE_SKILLS="${HOME}/.claude/skills"
LIVE_BEFORE=$(manifest_dir "${LIVE_SKILLS}")

cat > "${SBX}/config/operator.toml" <<TOML
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
claude_workspace_root = "${SBX}/ws"
operator_homedir_path = "${SBX}/home"
cowork_install_path = "/tmp/test-cowork"
pmo_platform_repo_name = "pmo-platform"

[platform]
work_board = "github"
comms_platform = ""
TOML
chmod 600 "${SBX}/config/operator.toml"

# --- Stage 1: fresh sandbox install (scaffolds the needle file) ---
printf '\nStage 1: fresh sandbox install (setup-workspace.sh)\n'
install_log=$("${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/ws" \
  --config-root "${SBX}/config" \
  < <(yes "") 2>&1)
install_exit=$?
if [ "${install_exit}" -eq 0 ]; then
  report "fresh install exits 0" 1
else
  report "fresh install exits 0" 0 "exit ${install_exit}; $(printf '%s' "${install_log}" | tail -4 | tr '\n' '|')"
fi

# Resolve the needle path the SAME way the code does (via the resolver), keyed on
# the sandbox workspace root. PMO_INSTANCE_PATH is unset, so this yields
# <sbx>/ws/personal/<instance-leaf>/localized-context-needles.txt.
# shellcheck source=/dev/null
source "${RESOLVER}"
NEEDLE_FILE="$(pmo_instance_path_for "${SBX}/ws")/localized-context-needles.txt"

if [ -f "${NEEDLE_FILE}" ]; then
  report "install scaffolded the needle file" 1
else
  report "install scaffolded the needle file" 0 "expected at ${NEEDLE_FILE}"
  printf '\ntest_instance_path_roundtrip.sh: %d passed, %d failed\n' "${PASS}" "${FAIL}"
  exit 1
fi

# The scaffolded file should be byte-identical to the tracked template.
if [ "$(sha_file "${NEEDLE_FILE}")" = "$(sha_file "${EXAMPLE}")" ]; then
  report "scaffolded needle file matches the .example template" 1
else
  report "scaffolded needle file matches the .example template" 0
fi

# --- Stage 2: fill the needle file with an operator payload ---
printf '\nStage 2: fill the needle file (operator data)\n'
cat > "${NEEDLE_FILE}" <<'NEEDLES'
# Operator-filled needles (roundtrip probe)
Example Coworker Name
Example Org Inc
exampleorg.test
NEEDLES
HASH_FILLED="$(sha_file "${NEEDLE_FILE}")"
if [ -n "${HASH_FILLED}" ]; then
  report "needle file filled + hashed" 1
else
  report "needle file filled + hashed" 0
fi

# --- Stage 3: first update → needle file unchanged ---
printf '\nStage 3: update.sh run #1 (needle file must not change)\n'
upd1_out=$(bash "${REPO_ROOT}/update.sh" \
  --config-root "${SBX}/config" \
  --workspace-root "${SBX}/ws" 2>&1)
upd1_exit=$?
HASH_AFTER_1="$(sha_file "${NEEDLE_FILE}")"
# Exit code is irrelevant to persistence (a managed-section regen or a no-op both
# must leave the needle file alone); we only assert byte-identity.
if [ "${HASH_AFTER_1}" = "${HASH_FILLED}" ]; then
  report "needle file byte-identical after update #1" 1
else
  report "needle file byte-identical after update #1" 0 \
    "before=${HASH_FILLED} after=${HASH_AFTER_1} (update exit ${upd1_exit})"
fi

# update.sh should explicitly report it PRESERVED the operator needle file.
if grep -q "PRESERVED (operator data, never regenerated)" <<<"${upd1_out}"; then
  report "update reports needle file PRESERVED (never regenerated)" 1
else
  report "update reports needle file PRESERVED (never regenerated)" 0 \
    "$(grep -m2 -i needle <<<"${upd1_out}" | tr '\n' '|')"
fi

# --- Stage 4: second update → still byte-identical (idempotent) ---
printf '\nStage 4: update.sh run #2 (idempotent persistence)\n'
upd2_out=$(bash "${REPO_ROOT}/update.sh" \
  --config-root "${SBX}/config" \
  --workspace-root "${SBX}/ws" 2>&1)
HASH_AFTER_2="$(sha_file "${NEEDLE_FILE}")"
if [ "${HASH_AFTER_2}" = "${HASH_FILLED}" ]; then
  report "needle file byte-identical after update #2 (sha256 stable across both runs)" 1
else
  report "needle file byte-identical after update #2" 0 \
    "original=${HASH_FILLED} after2=${HASH_AFTER_2}"
fi

# --- Stage 5: a pre-update instance backup was taken (#1830 Part 3) ---
printf '\nStage 5: pre-update instance backup\n'
# `-print -quit` rather than `| grep -q .`: the pipe form lets grep close find's
# output on the first path, and find inherits the broken pipe.
if [ -n "$(find "${SBX}/ws" -maxdepth 1 -type d -name '.backup-pre-update-instance-*' -print -quit 2>/dev/null)" ]; then
  report "update took a pre-update instance backup" 1
else
  report "update took a pre-update instance backup" 0 \
    "no .backup-pre-update-instance-* dir under ${SBX}/ws"
fi
# And the backup actually captured the needle file content.
backup_needle="$(find "${SBX}/ws" -path '*.backup-pre-update-instance-*/localized-context-needles.txt' 2>/dev/null | head -1)"  # sigpipe-idiom: allow — pre-existing at the pin, out of sweep scope; no `set -e` in this suite, and the value is consumed, not the status
if [ -n "${backup_needle}" ] && [ "$(sha_file "${backup_needle}")" = "${HASH_FILLED}" ]; then
  report "instance backup captured the filled needle file" 1
else
  report "instance backup captured the filled needle file" 0 "backup copy: ${backup_needle:-none}"
fi

# --- Stage 6: evals-results workspace-root cascade (value-pinned) ---
#
# Guards pmo_evals_results_path()'s rung-3 base against a future narrowing. Until
# #5634 that base was two steps ($CLAUDE_WORKSPACE_ROOT, else $HOME/Claude) while
# the pipeline-event WRITER's was four, so deploy.sh Check 19 and the
# decision-emission gate read a directory the writer never wrote to on any
# instance setting $WORKSPACE_ROOT or the claude_workspace_root key.
#
# WHY VALUE ASSERTIONS AND NOT A WRITER-vs-READER PARITY ASSERTION. The same
# change that closed the divergence made both pipeline-event tools CALL this
# function. Asserting "the resolver agrees with the tool" is therefore f(x)==f(x)
# — it passes on the correct implementation AND on a narrowed one, because a
# narrowing moves both arms together. Each limb below pins the resolved path to a
# LITERAL expectation instead. Those literals are not asserted from the resolver:
# they were measured from the writer's own filesystem behaviour (where
# append-pipeline-event.sh actually created the log under each configuration)
# before the convergence landed.
#
# ENVIRONMENT IS STATED PER LIMB, NOT DELEGATED TO AN IDIOM. Every limb needs
# EVALS_RESULTS_PATH and PMO_INSTANCE_PATH unset — rung 1 would otherwise force
# every arm to the same answer and the group would pass while asserting nothing.
# Limbs (i)/(iii) additionally need BOTH workspace-root env variables unset, or
# rung 3a/3b short-circuits before the toml tier is ever consulted.
printf '\nStage 6: evals-results workspace-root cascade (value-pinned)\n'

# Expectations below are written in ROOTED form (a workspace root immediately
# followed by the governed stem). The bare stem is deliberately NOT hoisted into a
# variable of its own: an unrooted operator-instance leaf in a tracked file is what
# the path-portability detector exists to catch, and the rooted spelling is both
# governed and what these assertions actually mean.
CAS_HOME="${SBX}/cashome"
mkdir -p "${CAS_HOME}/.config/pmo-platform"

cas_toml_root() {   # seed operator.toml carrying ONLY claude_workspace_root
  printf '[paths]\nclaude_workspace_root = "%s"\n' "$1" > "${CAS_HOME}/.config/pmo-platform/operator.toml"
}
cas_toml_norootkey() {  # a present-but-rootless operator.toml — limb (iii) is DEFINED by this
  printf '[paths]\noperator_homedir_path = ""\n' > "${CAS_HOME}/.config/pmo-platform/operator.toml"
}
cas_resolve() {     # resolve with every rung-1/2 and env-root lever explicitly cleared
  ( unset EVALS_RESULTS_PATH PMO_INSTANCE_PATH WORKSPACE_ROOT CLAUDE_WORKSPACE_ROOT
    HOME="${CAS_HOME}"; pmo_evals_results_path )
}

# (i) rung 3c — operator.toml claude_workspace_root. Run with TWO distinct values
#     so a stuck probe returning one constant cannot pass.
cas_toml_root "${SBX}/wsA"
got="$(cas_resolve)"; want="${SBX}/wsA/personal/pmo-instance/evals/results"
if [ "${got}" = "${want}" ]; then
  report "cascade 3c: operator.toml claude_workspace_root honored (value A)" 1
else
  report "cascade 3c: operator.toml claude_workspace_root honored (value A)" 0 "want=${want} got=${got}"
fi

cas_toml_root "${SBX}/wsB"
got="$(cas_resolve)"; want="${SBX}/wsB/personal/pmo-instance/evals/results"
if [ "${got}" = "${want}" ]; then
  report "cascade 3c: tracks a SECOND distinct value (value B — stuck-probe guard)" 1
else
  report "cascade 3c: tracks a SECOND distinct value (value B — stuck-probe guard)" 0 "want=${want} got=${got}"
fi

# (ii) rung 3a — $WORKSPACE_ROOT, the pre-existing release-tools override. No toml
#      root key present, so this limb cannot pass by falling through to 3c.
cas_toml_norootkey
got="$( unset EVALS_RESULTS_PATH PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT
        HOME="${CAS_HOME}"; WORKSPACE_ROOT="${SBX}/wsC"; pmo_evals_results_path )"
want="${SBX}/wsC/personal/pmo-instance/evals/results"
if [ "${got}" = "${want}" ]; then
  report "cascade 3a: env WORKSPACE_ROOT honored" 1
else
  report "cascade 3a: env WORKSPACE_ROOT honored" 0 "want=${want} got=${got}"
fi

# (iii) SPECIFICITY ARM — rung 3d. Nothing set anywhere and no root key in the
#       toml, so the $HOME-rooted canonical default must stand. This arm passes
#       before AND after any cascade change; it is what discriminates "the
#       cascade resolves correctly" from "every limb returns the same string".
got="$(cas_resolve)"; want="${CAS_HOME}/Claude/personal/pmo-instance/evals/results"
if [ "${got}" = "${want}" ]; then
  report "cascade 3d SPECIFICITY: no override anywhere -> HOME-rooted default" 1
else
  report "cascade 3d SPECIFICITY: no override anywhere -> HOME-rooted default" 0 "want=${want} got=${got}"
fi

# (iv) SOURCE-LIVENESS — not a parity assertion. query-pipeline-event.sh no longer
#      resolves this path itself; it sources the resolver. If that source ever
#      breaks, the tool dies before it can report a path, so this limb turns a
#      silent tool-side regression into a failure here. The expectation is still
#      pinned to the literal, not read back off the resolver.
cas_toml_root "${SBX}/wsA"
q_out="$( unset EVALS_RESULTS_PATH PMO_INSTANCE_PATH WORKSPACE_ROOT CLAUDE_WORKSPACE_ROOT
          HOME="${CAS_HOME}"
          "${REPO_ROOT}/release/tools/query-pipeline-event.sh" --count 2>&1 )"
# Here-string, not `printf | grep -q`: grep -q exits at its first match while the
# writer still has output to push, and under pipefail that broken pipe becomes the
# pipeline's status — a SUCCESSFUL match reporting failure. A here-string has no
# writer to signal. The needle is a non-empty absolute path, so the here-string's
# one-empty-line-for-empty-input behaviour cannot produce a false match.
if grep -qF -- "${SBX}/wsA/personal/pmo-instance/evals/results/pipeline-event-log.md" <<<"${q_out}"; then
  report "cascade: query-pipeline-event.sh sources the resolver and reports the same literal" 1
else
  report "cascade: query-pipeline-event.sh sources the resolver and reports the same literal" 0 \
    "expected the tool to name ${SBX}/wsA/personal/pmo-instance/evals/results/pipeline-event-log.md; got: $(printf '%s' "${q_out}" | tr '\n' '|')"
fi

# --- R-8 safety proof: live ~/.claude/skills untouched ---
printf '\nR-8 safety proof: live ~/.claude/skills untouched\n'
LIVE_AFTER=$(manifest_dir "${LIVE_SKILLS}")
if [ "${LIVE_BEFORE}" = "${LIVE_AFTER}" ]; then
  report "live ~/.claude/skills byte-identical before/after (R-8 proof)" 1
else
  report "live ~/.claude/skills byte-identical before/after (R-8 proof)" 0
fi

printf '\n======================================================================\n'
printf 'test_instance_path_roundtrip.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

[ "${FAIL}" -ne 0 ] && exit 1
exit 0
