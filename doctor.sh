#!/usr/bin/env bash
# doctor.sh — pmo-platform operator install self-diagnosis (#302)
#
# A STRICT READ-ONLY, two-layer diagnostic an operator runs when an install
# looks broken. It reports an actionable, single-screen health picture and a
# copy-pasteable failure-mode signal (`--format md`) to attach to a bug report.
#
# Two layers, by design (so it still diagnoses when python3 is the fault):
#   Layer 1 — pure bash host pre-flight (NO python3 dependency): bash version,
#             python3 presence/version/path, $HOME writability, operator.toml
#             existence/readability, deployed-hook runnable-bit, deployed-skill
#             presence. Layer 1 runs even when python3 is broken/absent.
#   Layer 2 — python-gated deep checks (degrade to SKIP-with-remedy if python3
#             is broken): operator.toml parse + schema validity (reuses the
#             compose.parse_toml primitive) and the #299 QA-as-code read-only
#             @check registry (invoked as `./qa.sh --read-only`).
#
# Registry reuse (CIAC-1): Layer 2 REUSES #299's registry by invoking qa.sh as a
# subprocess; doctor declares ZERO @check bodies and re-implements ZERO check
# functions. The #299 registry inspects the SHIPPING SOURCE TREE (its own
# docstring: reading the operator's live ~/.claude is "a downstream doctor's
# job") — so the operator-runtime checks AC-2 asks for (deployed hook +x bit,
# deployed skill presence) are doctor-owned Layer-1 checks, NOT a fork of the
# source-tree F5/F7. The two are distinct predicates.
#
# READ-ONLY guarantee (AC-1): the report is written to STDOUT only; the failure
# signal is `--format md` on stdout, never a written file. Every probe uses the
# `[ -r ]` / `[ -w ]` / `[ -x ]` test operators — no writes, no `>`/`>>` into
# any tracked path, no git/chmod/mkdir/touch. `git status --porcelain` is
# byte-identical before and after a run (proven by core/deploy/tests/test_doctor.sh).
#
# Runtime roots honor the platform sandbox-root env precedence (env var >
# $HOME-based default), matching setup-workspace.sh / update.sh / deploy.sh, so
# a sandboxed run (and the hermetic test) can redirect every read:
#   operator.toml  ${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/operator.toml
#   deployed hooks ${PMO_PLATFORM_WORKSPACE_ROOT:-$HOME/Claude}/.claude/hooks
#   deployed skills${PMO_PLATFORM_DEPLOY_ROOT:-$HOME}/.claude/skills
#
# Exit codes (aligned with #299 qa.sh so the two share a contract):
#   0  all checks PASS (SKIP is never a failure)
#   1  at least one check FAIL
#   2  internal error
#   64 EX_USAGE — bad argv
#
# Bash version: 3.2.57-safe (scalar + indexed arrays only; no declare -A).

set -Eeuo pipefail

# doctor.sh sits at the repo root; anchor on its own location so it runs from any cwd.
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
readonly REPO_ROOT
readonly QA_SCRIPT="${REPO_ROOT}/qa.sh"

# Read-only hardening: doctor's python children must never write .pyc bytecode
# into the source tree (belt-and-suspenders beyond .gitignore's __pycache__/ rule),
# so a run leaves `git status --porcelain` byte-identical.
export PYTHONDONTWRITEBYTECODE=1

# --- Runtime roots (sandbox-root precedence: env var > $HOME-based default) ---
readonly CONFIG_ROOT="${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"
readonly WORKSPACE_ROOT="${PMO_PLATFORM_WORKSPACE_ROOT:-${HOME}/Claude}"
readonly DEPLOY_ROOT="${PMO_PLATFORM_DEPLOY_ROOT:-${HOME}}"
readonly OPERATOR_TOML="${CONFIG_ROOT}/operator.toml"
readonly HOOKS_DIR="${WORKSPACE_ROOT}/.claude/hooks"
readonly SKILLS_DIR="${DEPLOY_ROOT}/.claude/skills"

# Exit codes
readonly EX_OK=0
readonly EX_FAIL=1
readonly EX_ERROR=2
readonly EX_USAGE=64

# --- Result accumulator (bash-3.2-safe parallel indexed arrays) ---
RES_STATUS=(); RES_ID=(); RES_TITLE=(); RES_EVIDENCE=(); RES_REMEDY=(); RES_LAYER=()
N_PASS=0; N_FAIL=0; N_SKIP=0
PYTHON3_OK=0            # set by check_python3; gates Layer 2
QA_OUTPUT=""            # folded qa.sh sub-report (rendered under the L2 registry row)
QA_RENDERED=0           # 1 when a folded qa.sh report is available to print

err() { printf 'ERROR: %s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
Usage: ./doctor.sh [--format text|md] [-h|--help]

Strict read-only install self-diagnosis for pmo-platform. Prints an actionable
two-layer health report to STDOUT and exits non-zero if any check FAILs.

Options:
  --format text   Human-readable single-screen report (default).
  --format md     Markdown report — the copy-pasteable failure-mode signal to
                  attach to a bug report.
  -h, --help      Show this help and exit.

Exit: 0 all-pass . 1 any FAIL . 2 internal error . 64 bad usage.
USAGE
}

# add_result STATUS ID TITLE EVIDENCE REMEDY LAYER
add_result() {
  RES_STATUS+=("$1"); RES_ID+=("$2"); RES_TITLE+=("$3")
  RES_EVIDENCE+=("$4"); RES_REMEDY+=("$5"); RES_LAYER+=("$6")
  case "$1" in
    PASS) N_PASS=$((N_PASS + 1)) ;;
    FAIL) N_FAIL=$((N_FAIL + 1)) ;;
    SKIP) N_SKIP=$((N_SKIP + 1)) ;;
  esac
}

# =========================================================================== #
# Layer 1 — pure-bash host pre-flight (no python3 dependency)                  #
# =========================================================================== #

check_bash_version() {
  local major="${BASH_VERSINFO[0]:-0}" minor="${BASH_VERSINFO[1]:-0}"
  local bpath="${BASH:-$(command -v bash 2>/dev/null || printf 'unknown')}"
  local ev="bash ${major}.${minor} at ${bpath}"
  # 3.2 is fully supported (the platform is 3.2-safe); on macOS note the modern
  # option so the line stays actionable without failing.
  if [ "${major}" -lt 4 ] && [ "$(uname -s 2>/dev/null || true)" = "Darwin" ]; then
    ev="${ev} (macOS system bash; a modern bash is available via 'brew install bash' if a tool needs 4+ features)"
  fi
  add_result "PASS" "bash" "bash version" "${ev}" "" "1"
}

check_python3() {
  local title="python3 presence + version + path"
  if ! command -v python3 >/dev/null 2>&1; then
    add_result "FAIL" "python3" "${title}" \
      "python3 not found on PATH" \
      "install python3 (macOS: 'brew install python3'; see docs/INSTALL.md) — Layer 2 checks are skipped until this is fixed" "1"
    return
  fi
  local p3 ver rc
  p3="$(command -v python3 2>/dev/null || printf '')"
  # errexit-safe capture: a broken python3 exits non-zero, and a bare
  # `ver=$(...)` assignment would trip `set -e` before rc is read.
  if ver="$(python3 --version 2>&1)"; then rc=0; else rc=$?; fi
  if [ "${rc}" -ne 0 ]; then
    add_result "FAIL" "python3" "${title}" \
      "python3 at ${p3} is present but not runnable (\`python3 --version\` exited ${rc}: ${ver})" \
      "repair or reinstall python3 (macOS: 'brew reinstall python3') — Layer 2 checks are skipped until this is fixed" "1"
    return
  fi
  PYTHON3_OK=1
  add_result "PASS" "python3" "${title}" "${ver} at ${p3}" "" "1"
}

check_home_writable() {
  local title="\$HOME exists and is writable"
  local perms
  perms="$(ls -ld "${HOME}" 2>/dev/null | awk '{print $1}' || true)"
  if [ -d "${HOME}" ] && [ -w "${HOME}" ]; then
    add_result "PASS" "home" "${title}" "\$HOME=${HOME} writable (perms ${perms:-?})" "" "1"
  else
    add_result "FAIL" "home" "${title}" \
      "\$HOME=${HOME} is not a writable directory (perms ${perms:-?})" \
      "restore write permission on your home directory (chmod u+rwx \"\$HOME\") — install/update write there" "1"
  fi
}

check_operator_toml_present() {
  local title="operator.toml present + readable"
  if [ -f "${OPERATOR_TOML}" ] && [ -r "${OPERATOR_TOML}" ]; then
    add_result "PASS" "toml" "${title}" "found readable ${OPERATOR_TOML}" "" "1"
  else
    add_result "FAIL" "toml" "${title}" \
      "operator.toml missing or unreadable at ${OPERATOR_TOML}" \
      "run ./update.sh to create/repair operator.toml (or 'chmod 600' it if unreadable)" "1"
  fi
}

check_hooks_runnable() {
  local title="deployed security hooks carry the +x bit"
  if [ ! -d "${HOOKS_DIR}" ]; then
    add_result "FAIL" "hooks" "${title}" \
      "no deployed-hooks directory at ${HOOKS_DIR}" \
      "run ./install.sh to deploy the security hooks under \$WORKSPACE_ROOT/.claude/hooks" "1"
    return
  fi
  local count=0 missing="" h base
  for h in "${HOOKS_DIR}"/*.sh; do
    [ -e "${h}" ] || continue
    base="$(basename "${h}")"
    # Skip co-deployed SOURCED libraries. setup-workspace.sh install_hooks (#1850)
    # co-deploys shared primitives NEXT TO the hooks — path-leak-patterns.sh
    # (block-gh-path-leak dependency) and lib-instance-path.sh (block-scope-
    # segregation needle resolver). They are SOURCED by hooks at runtime, never
    # invoked directly, so they carry no +x requirement: path-leak-patterns.sh
    # ships mode -rw-r--r-- by design. The hook-registry convention ("not a
    # registered hook — no block-* name") already ignores them; without this skip
    # doctor's naive *.sh glob FAILs a HEALTHY install with a misleading chmod
    # remedy (#302). Every real entrypoint (block-* security hooks AND the
    # notify-/audit-/session-/… lifecycle hooks) is still checked. Shebang is NOT
    # a discriminator — sourced libs carry one too — so match the sourced-lib
    # naming patterns, mirroring the install_hooks co-deploy set.
    case "${base}" in
      lib-*.sh|*-patterns.sh) continue ;;
    esac
    count=$((count + 1))
    if [ ! -x "${h}" ]; then
      missing="${missing:+${missing}, }${base}"
    fi
  done
  if [ "${count}" -eq 0 ]; then
    add_result "FAIL" "hooks" "${title}" \
      "no *.sh hooks under ${HOOKS_DIR}" \
      "run ./install.sh to deploy the security hooks" "1"
  elif [ -n "${missing}" ]; then
    add_result "FAIL" "hooks" "${title}" \
      "${count} hook(s) present but missing the +x bit: ${missing}" \
      "chmod +x \"${HOOKS_DIR}\"/*.sh (a hook without the +x bit silently fails to run), or re-run ./install.sh" "1"
  else
    add_result "PASS" "hooks" "${title}" "${count} deployed hook(s) under ${HOOKS_DIR}, all carry +x" "" "1"
  fi
}

check_skills_present() {
  local title="platform skills are deployed"
  if [ ! -d "${SKILLS_DIR}" ]; then
    add_result "FAIL" "skills" "${title}" \
      "no deployed-skills directory at ${SKILLS_DIR}" \
      "run ./install.sh (skills deploy via deploy.sh --deploy under \$DEPLOY_ROOT/.claude/skills)" "1"
    return
  fi
  local count=0 d
  for d in "${SKILLS_DIR}"/*/; do
    [ -d "${d}" ] || continue
    count=$((count + 1))
  done
  if [ "${count}" -eq 0 ]; then
    add_result "FAIL" "skills" "${title}" \
      "deployed-skills directory ${SKILLS_DIR} is empty" \
      "run ./install.sh to deploy the platform skills" "1"
  else
    add_result "PASS" "skills" "${title}" "${count} skill(s) deployed under ${SKILLS_DIR}" "" "1"
  fi
}

# =========================================================================== #
# Layer 2 — python-gated deep checks (SKIP-with-remedy if python3 is broken)   #
# =========================================================================== #

check_operator_toml_valid() {
  local title="operator.toml parses + carries the required schema keys"
  if [ "${PYTHON3_OK}" -ne 1 ]; then
    add_result "SKIP" "toml-valid" "${title}" \
      "skipped — python3 is unavailable (Layer 1 'python3' check FAILed)" \
      "fix python3, then re-run ./doctor.sh to validate operator.toml" "2"
    return
  fi
  if [ ! -r "${OPERATOR_TOML}" ]; then
    add_result "SKIP" "toml-valid" "${title}" \
      "skipped — operator.toml is not readable (Layer 1 'toml' check FAILed)" \
      "create/repair operator.toml (./update.sh), then re-run ./doctor.sh" "2"
    return
  fi
  # Reuse the compose.parse_toml PRIMITIVE (not a #299 @check body — CIAC-1
  # unaffected). parse_toml is lenient (skips malformed lines, returns {} when
  # absent), so "valid" = a non-empty parse that carries the required keys.
  local out rc
  out="$(PYTHONPATH="${REPO_ROOT}/core/deploy${PYTHONPATH:+:${PYTHONPATH}}" python3 - "${OPERATOR_TOML}" <<'PYEOF' 2>/dev/null || true
import sys
from pathlib import Path
try:
    import compose
except Exception as e:  # compose.py absent (partial checkout) — signal degrade
    print("NOCOMPOSE:%r" % (e,)); sys.exit(0)
d = compose.parse_toml(Path(sys.argv[1]))
if not d:
    print("EMPTY"); sys.exit(0)
required = [("meta", "schema_version"), ("identity", "operator_name")]
missing = ["[%s].%s" % (s, k) for (s, k) in required if (s, k) not in d]
if missing:
    print("MISSING:" + ",".join(missing)); sys.exit(0)
print("OK:%d" % len(d)); sys.exit(0)
PYEOF
)"
  rc=$?
  case "${out}" in
    OK:*)
      add_result "PASS" "toml-valid" "${title}" \
        "parsed ${out#OK:} key(s); required schema keys [meta].schema_version + [identity].operator_name present" "" "2" ;;
    EMPTY)
      add_result "FAIL" "toml-valid" "${title}" \
        "operator.toml parsed to zero keys (empty or not TOML-shaped)" \
        "restore operator.toml from the template (./update.sh) — it needs [meta] and [identity] sections" "2" ;;
    MISSING:*)
      add_result "FAIL" "toml-valid" "${title}" \
        "operator.toml is missing required schema key(s): ${out#MISSING:}" \
        "run ./update.sh to populate the required [meta].schema_version and [identity].operator_name keys" "2" ;;
    NOCOMPOSE:*)
      add_result "SKIP" "toml-valid" "${title}" \
        "skipped — could not import core/deploy/compose.py (${out#NOCOMPOSE:})" \
        "restore core/deploy/compose.py (partial checkout?) then re-run ./doctor.sh" "2" ;;
    *)
      add_result "SKIP" "toml-valid" "${title}" \
        "skipped — the operator.toml validity probe produced no result (python rc=${rc})" \
        "re-run ./doctor.sh; if it persists, inspect python3 + core/deploy/compose.py" "2" ;;
  esac
}

check_qa_registry() {
  local fmt="$1"          # text|md — folded qa.sh report format
  local title="QA-as-code read-only registry (#299 F1-F10 + R1/R2)"
  if [ "${PYTHON3_OK}" -ne 1 ]; then
    add_result "SKIP" "qa-registry" "${title}" \
      "skipped — python3 is unavailable (Layer 1 'python3' check FAILed)" \
      "fix python3, then re-run ./doctor.sh to run the QA registry" "2"
    return
  fi
  if [ ! -f "${QA_SCRIPT}" ]; then
    add_result "SKIP" "qa-registry" "${title}" \
      "skipped — qa.sh not found at ${QA_SCRIPT} (partial checkout?)" \
      "restore qa.sh + core/deploy/qa/ (from #299) then re-run ./doctor.sh" "2"
    return
  fi
  # REUSE (CIAC-1): run #299's registry read-only as a subprocess; fold its
  # stdout + exit code. doctor declares zero @check bodies of its own.
  # errexit-safe capture: qa.sh exits 1 when a registry check FAILs, and a bare
  # `QA_OUTPUT=$(...)` assignment would trip `set -e` before rc is read.
  local rc
  if QA_OUTPUT="$(bash "${QA_SCRIPT}" --read-only --format "${fmt}" 2>&1)"; then rc=0; else rc=$?; fi
  QA_RENDERED=1
  case "${rc}" in
    0) add_result "PASS" "qa-registry" "${title}" \
         "qa.sh --read-only reports all registry checks PASS (see folded report)" "" "2" ;;
    1) add_result "FAIL" "qa-registry" "${title}" \
         "qa.sh --read-only reports at least one FAIL (see folded report for the finding + remedy)" \
         "act on the failing finding's Remedy in the folded QA report below" "2" ;;
    *) add_result "FAIL" "qa-registry" "${title}" \
         "qa.sh --read-only exited ${rc} (internal error running the registry)" \
         "inspect core/deploy/qa/ and re-run ./qa.sh --read-only directly" "2" ;;
  esac
}

# =========================================================================== #
# Report rendering                                                             #
# =========================================================================== #

_utc_now() { date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'unknown'; }

_repo_sha() { git -C "${REPO_ROOT}" rev-parse --short HEAD 2>/dev/null || printf 'unknown'; }

_repo_version() {
  if [ -r "${REPO_ROOT}/.version" ]; then
    head -1 "${REPO_ROOT}/.version" 2>/dev/null | tr -d ' \n' || printf 'unknown'
  else
    printf 'unknown'
  fi
}

# Make a string safe inside a Markdown table cell (no pipe/newline breaks).
_md_cell() { printf '%s' "$1" | tr '\n' ' ' | sed 's/|/\\|/g'; }

render_text() {
  local verdict; [ "${N_FAIL}" -eq 0 ] && verdict="PASS" || verdict="FAIL"
  local i
  printf 'pmo-platform doctor — install self-diagnosis\n'
  printf 'Date: %s\n' "$(_utc_now)"
  printf 'Repo: %s  SHA: %s  Version: %s\n' "${REPO_ROOT}" "$(_repo_sha)" "$(_repo_version)"
  printf 'Roots: config=%s  workspace=%s  deploy=%s\n' "${CONFIG_ROOT}" "${WORKSPACE_ROOT}" "${DEPLOY_ROOT}"
  local layer=""
  for i in "${!RES_ID[@]}"; do
    if [ "${RES_LAYER[$i]}" != "${layer}" ]; then
      layer="${RES_LAYER[$i]}"
      printf -- '----------------------------------------------------------------------\n'
      if [ "${layer}" = "1" ]; then
        printf 'Layer 1 — host pre-flight (pure bash)\n'
      else
        printf 'Layer 2 — deep checks (python-gated; SKIP if python3 broken)\n'
      fi
    fi
    printf '[%-4s] %-11s %s\n' "${RES_STATUS[$i]}" "${RES_ID[$i]}" "${RES_TITLE[$i]}"
    printf '        evidence: %s\n' "${RES_EVIDENCE[$i]}"
    if [ "${RES_STATUS[$i]}" != "PASS" ] && [ -n "${RES_REMEDY[$i]}" ]; then
      printf '        remedy:   %s\n' "${RES_REMEDY[$i]}"
    fi
    # Fold the qa.sh sub-report directly under the registry row.
    if [ "${RES_ID[$i]}" = "qa-registry" ] && [ "${QA_RENDERED}" -eq 1 ]; then
      printf '        --- folded qa.sh --read-only report ---\n'
      printf '%s\n' "${QA_OUTPUT}" | sed 's/^/        | /'
    fi
  done
  printf -- '----------------------------------------------------------------------\n'
  printf 'Total: %d  PASS: %d  FAIL: %d  SKIP: %d  — VERDICT %s\n' \
    "${#RES_ID[@]}" "${N_PASS}" "${N_FAIL}" "${N_SKIP}" "${verdict}"
}

render_md() {
  local verdict; [ "${N_FAIL}" -eq 0 ] && verdict="PASS" || verdict="FAIL"
  local i layer=""
  printf '## pmo-platform doctor — install self-diagnosis\n\n'
  printf '**Date:** %s  \n' "$(_utc_now)"
  printf '**Repo SHA:** %s . **Version:** %s  \n' "$(_repo_sha)" "$(_repo_version)"
  printf '**Roots:** config=`%s` . workspace=`%s` . deploy=`%s`\n\n' "${CONFIG_ROOT}" "${WORKSPACE_ROOT}" "${DEPLOY_ROOT}"
  for i in "${!RES_ID[@]}"; do
    if [ "${RES_LAYER[$i]}" != "${layer}" ]; then
      layer="${RES_LAYER[$i]}"
      if [ "${layer}" = "1" ]; then
        printf '### Layer 1 — host pre-flight (pure bash)\n\n'
      else
        printf '### Layer 2 — deep checks (python-gated; SKIP if python3 broken)\n\n'
      fi
      printf '| Check | Status | Evidence | Remedy |\n|---|---|---|---|\n'
    fi
    local remedy="—"
    if [ "${RES_STATUS[$i]}" != "PASS" ] && [ -n "${RES_REMEDY[$i]}" ]; then
      remedy="$(_md_cell "${RES_REMEDY[$i]}")"
    fi
    printf '| %s | %s | %s | %s |\n' \
      "$(_md_cell "${RES_TITLE[$i]}")" "${RES_STATUS[$i]}" "$(_md_cell "${RES_EVIDENCE[$i]}")" "${remedy}"
  done
  if [ "${QA_RENDERED}" -eq 1 ]; then
    printf '\n<details><summary>Folded qa.sh --read-only report</summary>\n\n'
    printf '%s\n' "${QA_OUTPUT}"
    printf '\n</details>\n'
  fi
  printf '\n### Summary\n'
  printf -- '- Total: %d\n- PASS: %d\n- FAIL: %d\n- SKIP: %d\n\n' \
    "${#RES_ID[@]}" "${N_PASS}" "${N_FAIL}" "${N_SKIP}"
  printf '**Verdict:** %s\n' "${verdict}"
}

# =========================================================================== #
# Main                                                                         #
# =========================================================================== #

main() {
  local format="text"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --format)
        [ "$#" -ge 2 ] || { err "--format requires an argument (text|md)"; usage >&2; exit "${EX_USAGE}"; }
        case "$2" in
          text|md) format="$2" ;;
          *) err "unknown --format value: $2 (expected text|md)"; usage >&2; exit "${EX_USAGE}" ;;
        esac
        shift 2 ;;
      --format=*)
        case "${1#--format=}" in
          text|md) format="${1#--format=}" ;;
          *) err "unknown --format value: ${1#--format=} (expected text|md)"; usage >&2; exit "${EX_USAGE}" ;;
        esac
        shift ;;
      -h|--help) usage; exit "${EX_OK}" ;;
      *) err "unknown argument: $1"; usage >&2; exit "${EX_USAGE}" ;;
    esac
  done

  # Layer 1 (always runs — pure bash, no python3 dependency).
  check_bash_version
  check_python3
  check_home_writable
  check_operator_toml_present
  check_hooks_runnable
  check_skills_present

  # Layer 2 (python-gated; each check SKIPs-with-remedy when python3 is broken).
  check_operator_toml_valid
  check_qa_registry "${format}"

  if [ "${format}" = "md" ]; then
    render_md
  else
    render_text
  fi

  [ "${N_FAIL}" -eq 0 ] && exit "${EX_OK}" || exit "${EX_FAIL}"
}

main "$@"
