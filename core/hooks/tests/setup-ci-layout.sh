#!/usr/bin/env bash
# setup-ci-layout.sh — materialize a deployed hook runtime layout in a sandbox
# so the hook test harness can run against the co-located, token-resolved
# allowlists the hooks resolve from ${HOOK_DIR}/.. at runtime.
#
# WHY THIS EXISTS
#   The hooks resolve their allowlist + .mode from ${HOOK_DIR}/.. — i.e.
#   ~/Claude/.claude/<name>.txt after install, where install.sh has written
#   token-resolved allowlists. In a source/CI checkout HOOK_DIR=core/hooks →
#   CLAUDE_DIR=core/ → core/<name>.txt is ABSENT (the source allowlists live
#   token-unresolved at core/config/allowlists/). With the allowlist absent the
#   hooks correctly block, so the tests' "allow" assertions fail. The fix is to
#   materialize the deployed posture — hooks + token-resolved allowlists +
#   .mode + the test files, all co-located under a sandbox .claude/hooks/ — and
#   run the harness from there. (Per the Stage 5 spec on issue #718, Option A.)
#
# WHAT IT DOES (for a given --sandbox; each run replaces this helper's own
# earlier layout there)
#   0. Guard the sandbox (R-8) before anything is written, then clear this
#      helper's earlier layout: refuse (exit 65) when <sandbox>/.claude is, or sits
#      inside, a live Claude configuration directory, when a file step 3b writes
#      would land outside the sandbox, or when the sandbox already holds layout
#      files this helper has no record of writing. A layout it did record is
#      removed first — exactly its recorded files, nothing else.
#   1. Create <sandbox>/.claude/hooks/tests/ and write the ownership marker
#      before anything is copied, so an interrupted build is still recognized as
#      owned and still names everything it wrote. Then copy every core/hooks/*.sh
#      (the hooks) into <sandbox>/.claude/hooks/, and co-locate the libraries a
#      deployed install carries beside them (1b to 1g in the body below).
#   2. Copy every core/hooks/tests/*.sh (the tests + runner) into
#      <sandbox>/.claude/hooks/tests/ — EXCEPT this script itself.
#   3. Materialize the token-resolved allowlists at <sandbox>/.claude/ for the
#      "hook"-tier composition-surface files, resolving:
#        [CLAUDE_WORKSPACE_ROOT] -> ${HOME}/Claude   (the boundary the
#                                                     fs-boundary "allow"
#                                                     assertions assume)
#        [OPERATOR_HOMEDIR_PATH] -> ${HOME}
#        [OPERATOR_GITHUB]       -> ${PMO_TEST_GITHUB_HANDLE:-pmo-test-handle}
#   3b. Materialize, verbatim from its own manifest row, each instance-tier file a
#      deployed security hook reads: the set lib-instance-path.sh declares, resolved
#      for the sandbox with PMO_INSTANCE_PATH unset. Today that is the skill-editor
#      exemption list, which the Gate 2 hook reads and allowlist-add.sh writes, at the
#      path the layout's own hook resolves.
#   4. Write <sandbox>/.claude/hooks/.mode = enforce (the tests set their own
#      per-case mode against the SANDBOX .mode; the live ~/Claude/.claude/
#      hooks/.mode is NEVER touched — R-8 sandbox invariant).
#   5. Record the build digest beside the tests.
#
# SANDBOX INVARIANT (R-8) — ENFORCED, NOT ASSUMED
#   Everything is materialized under the sandbox, and step 0 enforces that before
#   the first write — for the default site (the checkout root, including a checkout
#   that is itself a workspace root) and for any --sandbox. A sandbox whose .claude/
#   is, or sits inside, a live Claude configuration directory is refused, except
#   inside that directory's worktrees/<name>/, where a linked checkout legitimately
#   lives. The live directories come from the declared workspace root and from the
#   ACCOUNT home, read from the user database and never from ${HOME}: a caller that
#   overrides HOME for a sandboxed run must not move what counts as live. They are
#   compared by filesystem identity, not by path strings. This script writes
#   nothing to ~/Claude/.claude/. It resolves the instance-tier files a hook reads
#   with PMO_INSTANCE_PATH unset, so an exported value cannot aim a write at a real
#   instance. The fs-boundary test's .mode mutation targets the sandbox copy.
#   Resolving [CLAUDE_WORKSPACE_ROOT] to ${HOME}/Claude only sets the allowlist's
#   prefix-match ROOT (a read-only boundary reference, realpath does not require it
#   to exist); the tests never write under ${HOME}/Claude.
#
# USAGE
#   setup-ci-layout.sh [--repo-root <dir>] [--sandbox <dir>]
#     --repo-root  Source repo root (default: three levels above this script).
#     --sandbox    Sandbox root. Default: the checkout this script runs from, so the
#                  layout lands at <checkout>/.claude/hooks/ — the one site an agent
#                  tool call may execute the runner from. A programmatic caller that
#                  needs a hermetic per-run layout passes a fresh directory explicitly.
#   Prints the materialized tests directory (canonical absolute path) on stdout —
#   the only stdout line. Diagnostics go to stderr. Exit 64: bad arguments,
#   including an explicitly EMPTY --sandbox (never read as "use the default").
#   Exit 65: refused by the guard (step 0) — nothing was written. Exit 1: a
#   required source is missing, or a copy failed part-way; a part-built layout is
#   still owned and recorded, so the next run replaces it.
#
# AGENT INVOCATION — the supported form for a Claude Code session. Run from the
# checkout root (a worktree session's working directory), BOTH commands, IN THIS
# ORDER, EVERY TIME. The layout is a snapshot: the runner grades what the last build
# copied, not your working tree, so the runner line on its own after a source edit
# grades old code (the suite's LAYOUT-FRESH-01 arm fails when the two have drifted).
# Each line is a literal command BLOCK-DESTRUCTIVE-022 admits as written; never put
# the runner path in a variable — the hook cannot resolve one and refuses it wherever
# the layout sits. The full harness takes several minutes (five to eight on CI), so
# give the runner a tool budget of at least ten minutes.
# >>> AGENT-INVOCATION-BEGIN — core/hooks/tests/setup-ci-layout.test.sh
#   bash core/hooks/tests/setup-ci-layout.sh
#   bash .claude/hooks/tests/test-runner.sh
# >>> AGENT-INVOCATION-END
#
# PROGRAMMATIC INVOCATION — scripts and CI, which no PreToolUse hook gates:
#   sandbox="$(mktemp -d -t hook-ci-layout.XXXXXX)"
#   tests_dir="$(bash core/hooks/tests/setup-ci-layout.sh --sandbox "${sandbox}")"
#   bash "${tests_dir}/test-runner.sh"
#
# RECORDED FOOTPRINT — the one write path
#   Every file this helper writes goes through layout_put, and every directory it
#   creates through layout_mkdir. Each appends a record to the footprint BEFORE it
#   writes, so an interrupted build still names everything it wrote. The purge
#   (step 0) reads the same footprint and removes exactly the recorded files, then
#   the recorded directories that are left empty — never a path it did not record,
#   and never anything outside the sandbox. The digest (step 5) and the suite's
#   ignore-coverage arm read the same list. A later step that adds a file to the
#   layout writes through layout_put too, and so joins all three automatically.
#
#     layout_mkdir <rel-dir>                  create <sandbox>/<rel-dir>, recording
#                                             each component this call creates
#     layout_put copy  <rel-dst> <rel-src>    copy <repo>/<rel-src> to <sandbox>/<rel-dst>
#     layout_put stdin <rel-dst> [<rel-src>]  write stdin to <sandbox>/<rel-dst>;
#                                             <rel-src> names the tracked input the
#                                             content derives from ('-' or omitted: none)
#
#   <rel-dst> is relative to the sandbox root, <rel-src> to the repo root. Both are
#   plain relative paths: no leading '/', no empty, '.' or '..' segment. A write
#   that would land outside the sandbox, or on a link or a directory, is refused.
#   The bookkeeping files sit beside the tests: .layout-owner (the ownership
#   marker, written first), .layout-footprint (one record per write: "f", or "d"
#   for a directory, then <rel-dst>, then <rel-src> or '-', tab-separated) and
#   .layout-digest (written last).
#
# Platform: macOS / Linux. bash 3.2-safe (no associative arrays).

set -euo pipefail

log() { printf '%s\n' "$*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
# Default repo root: core/hooks/tests -> core/hooks -> core -> repo root.
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd -P)"
SANDBOX=""
SANDBOX_GIVEN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-root|--sandbox)
      if [ "$#" -lt 2 ]; then
        log "setup-ci-layout.sh: $1 needs a value"
        exit 64
      fi
      if [ "$1" = "--repo-root" ]; then
        REPO_ROOT="$2"
      else
        SANDBOX="$2"
        SANDBOX_GIVEN=1
      fi
      shift 2 ;;
    *) log "setup-ci-layout.sh: unknown argument: $1"; exit 64 ;;
  esac
done

if [ "${SANDBOX_GIVEN}" -eq 1 ] && [ -z "${SANDBOX}" ]; then
  log "setup-ci-layout.sh: --sandbox was given an empty value; refusing rather than falling back to the default"
  exit 64
fi
if [ ! -d "${REPO_ROOT}" ]; then
  log "setup-ci-layout.sh: --repo-root is not a directory: ${REPO_ROOT}"
  exit 64
fi
REPO_ROOT="$(cd "${REPO_ROOT}" && pwd -P)"

# DEFAULT SANDBOX = this checkout. Its .claude/hooks/tests/test-runner.sh is the path
# the allowlist's bare-relative runner row admits, so the documented agent invocation
# works as written; a programmatic caller keeps a hermetic per-run layout via --sandbox.
if [ -z "${SANDBOX}" ]; then SANDBOX="${REPO_ROOT}"; fi
if [ -d "${SANDBOX}" ]; then
  SANDBOX="$(cd "${SANDBOX}" && pwd -P)"
elif [ -e "${SANDBOX}" ] || [ -L "${SANDBOX}" ]; then
  log "setup-ci-layout.sh: --sandbox exists and is not a directory: ${SANDBOX}"
  exit 64
else
  _parent="$(dirname "${SANDBOX}")"
  if [ ! -d "${_parent}" ]; then
    log "setup-ci-layout.sh: the parent of --sandbox does not exist: ${_parent}"
    exit 64
  fi
  _parent="$(cd "${_parent}" && pwd -P)"
  if [ "${_parent}" = "/" ]; then _parent=""; fi
  SANDBOX="${_parent}/$(basename "${SANDBOX}")"
fi
if [ "${SANDBOX}" = "/" ]; then
  log "setup-ci-layout.sh: the filesystem root is not a usable sandbox"
  exit 64
fi
# Whether the sandbox is the source checkout itself (the default site), decided by
# filesystem identity once, and read by every step that behaves differently there.
SANDBOX_IS_CHECKOUT=0
if [ -d "${SANDBOX}" ] && [ "${SANDBOX}" -ef "${REPO_ROOT}" ]; then SANDBOX_IS_CHECKOUT=1; fi

CLAUDE_DIR="${SANDBOX}/.claude"
HOOKS_DST="${CLAUDE_DIR}/hooks"
TESTS_DST="${HOOKS_DST}/tests"
OWNER_MARK="${TESTS_DST}/.layout-owner"
FOOTPRINT="${TESTS_DST}/.layout-footprint"
DIGEST="${TESTS_DST}/.layout-digest"

# ── Layout primitives: path checks, the recorded write path, the purge, the digest ──

# 0 when $1 is a plain relative path: no leading '/', no empty, '.' or '..' segment,
# and no tab or newline (the footprint is tab-separated, one record per line).
layout_rel_ok() {
  case "$1" in
    ''|*$'\t'*|*$'\n'*) return 1 ;;
  esac
  case "/$1/" in
    *//*|*/./*|*/../*) return 1 ;;
  esac
  return 0
}

# 0 when the existing directory $1 resolves inside the sandbox.
layout_inside() {
  local phys
  phys="$(cd "$1" 2>/dev/null && pwd -P)" || return 1
  case "${phys}" in
    "${SANDBOX}"|"${SANDBOX}/"*) return 0 ;;
  esac
  return 1
}

# Existing directories already confirmed to resolve inside the sandbox, space-framed.
LAYOUT_DIRS_OK=" "

layout_refuse() {
  log "setup-ci-layout.sh: REFUSED — $*"
  exit 65
}

layout_mkdir() {   # $1 = relative directory
  local rel="$1" acc="" seg rest
  layout_rel_ok "${rel}" || layout_refuse "not a plain layout path: ${rel}"
  rest="${rel}"
  while [ -n "${rest}" ]; do
    seg="${rest%%/*}"
    if [ "${seg}" = "${rest}" ]; then rest=""; else rest="${rest#*/}"; fi
    acc="${acc:+${acc}/}${seg}"
    case "${LAYOUT_DIRS_OK}" in
      *" ${acc} "*) continue ;;
    esac
    if [ -e "${SANDBOX}/${acc}" ] || [ -L "${SANDBOX}/${acc}" ]; then
      if [ ! -d "${SANDBOX}/${acc}" ]; then
        layout_refuse "${SANDBOX}/${acc} exists and is not a directory"
      fi
      if ! layout_inside "${SANDBOX}/${acc}"; then
        layout_refuse "${SANDBOX}/${acc} leads out of the sandbox"
      fi
    else
      printf 'd\t%s\t-\n' "${acc}" >> "${FOOTPRINT}"
      mkdir "${SANDBOX}/${acc}"
    fi
    LAYOUT_DIRS_OK="${LAYOUT_DIRS_OK}${acc} "
  done
}

layout_put() {   # $1 = copy|stdin  $2 = rel-dst  $3 = rel-src ('-' or omitted: none)
  local kind="$1" dst="$2" src="${3:--}" abs dir
  layout_rel_ok "${dst}" || layout_refuse "not a plain layout path: ${dst}"
  if [ "${src}" != "-" ]; then
    layout_rel_ok "${src}" || layout_refuse "not a plain source path: ${src}"
  fi
  if [ "${kind}" = "copy" ] && [ "${src}" = "-" ]; then
    log "setup-ci-layout.sh: layout_put copy needs a source path (${dst})"
    exit 64
  fi
  abs="${SANDBOX}/${dst}"
  dir="${dst%/*}"
  if [ "${dir}" != "${dst}" ]; then layout_mkdir "${dir}"; fi
  if [ -L "${abs}" ] || [ -d "${abs}" ]; then
    layout_refuse "${abs} is a link or a directory; this helper writes only regular files"
  fi
  # Record first, then write: an interrupted write is still in the footprint.
  printf 'f\t%s\t%s\n' "${dst}" "${src}" >> "${FOOTPRINT}"
  case "${kind}" in
    copy)  cp "${REPO_ROOT}/${src}" "${abs}" ;;
    stdin) cat > "${abs}" ;;
    *) log "setup-ci-layout.sh: layout_put: unknown kind: ${kind}"; exit 64 ;;
  esac
}

# Remove exactly this helper's recorded footprint. Every record is validated before
# anything is removed; files are removed one at a time, never recursively; recorded
# directories are removed deepest-first and only when empty. A recorded path that
# has become a directory is left in place, and the rebuild then refuses to write it.
layout_purge() {
  local kind rel src abs dirs=""
  if [ -f "${FOOTPRINT}" ]; then
    while IFS=$'\t' read -r kind rel src || [ -n "${kind}" ]; do
      case "${kind}" in
        f|d) ;;
        *) layout_refuse "the recorded footprint ${FOOTPRINT} carries an unreadable record; nothing was removed. Move ${HOOKS_DST} to the Trash, then re-run this helper." ;;
      esac
      layout_rel_ok "${rel}" || layout_refuse "the recorded footprint names a path outside the layout (${rel}); nothing was removed. Move ${HOOKS_DST} to the Trash, then re-run this helper."
      abs="${SANDBOX}/${rel}"
      if [ -d "${abs%/*}" ] && ! layout_inside "${abs%/*}"; then
        layout_refuse "the recorded path ${rel} resolves outside the sandbox; nothing was removed. Move ${HOOKS_DST} to the Trash, then re-run this helper."
      fi
    done < "${FOOTPRINT}"
    while IFS=$'\t' read -r kind rel src || [ -n "${kind}" ]; do
      abs="${SANDBOX}/${rel}"
      if [ "${kind}" = "d" ]; then
        dirs="${rel}"$'\n'"${dirs}"
        continue
      fi
      if [ -L "${abs}" ] || [ -f "${abs}" ]; then rm -f "${abs}"; fi
    done < "${FOOTPRINT}"
  fi
  rm -f "${DIGEST}" "${FOOTPRINT}" "${OWNER_MARK}"
  while IFS= read -r rel; do
    if [ -n "${rel}" ]; then rmdir "${SANDBOX}/${rel}" 2>/dev/null || true; fi
  done <<< "${dirs}"
}

# "<sha256>  <path>" for each relative path, in order, hashed from $1.
layout_hash_many() {
  local base="$1"
  shift
  if command -v shasum >/dev/null 2>&1; then
    (cd "${base}" && shasum -a 256 -- "$@")
  else
    (cd "${base}" && sha256sum -- "$@")
  fi
}

# The build digest: one line per recorded file — its layout path and hash, then the
# tracked source it came from and that source's hash ('-' when it has none) — plus
# this helper and the manifest as build inputs (layout path '-'). Tab-separated.
layout_write_digest() {
  local kind rel src tmp_dst tmp_src inputs="" input
  local -a dsts=() srcs=()
  while IFS=$'\t' read -r kind rel src || [ -n "${kind}" ]; do
    if [ "${kind}" != "f" ]; then continue; fi
    dsts+=("${rel}")
    if [ "${src}" != "-" ]; then srcs+=("${src}"); fi
  done < "${FOOTPRINT}"
  for input in core/hooks/tests/setup-ci-layout.sh core/deploy/composition-surface-manifest.sh; do
    if [ -f "${REPO_ROOT}/${input}" ]; then
      srcs+=("${input}")
      inputs="${inputs}${input} "
    fi
  done
  tmp_dst="$(mktemp)"
  tmp_src="$(mktemp)"
  layout_hash_many "${SANDBOX}" "${dsts[@]}" > "${tmp_dst}"
  layout_hash_many "${REPO_ROOT}" "${srcs[@]}" > "${tmp_src}"
  awk -v dsum="${tmp_dst}" -v ssum="${tmp_src}" -v inputs="${inputs}" '
    FILENAME == dsum { h = $1; sub(/^[^ ]+ +\*?/, ""); dh[$0] = h; next }
    FILENAME == ssum { h = $1; sub(/^[^ ]+ +\*?/, ""); sh[$0] = h; next }
    {
      split($0, r, "\t")
      if (r[1] != "f") next
      printf "%s\t%s\t%s\t%s\n", r[2], dh[r[2]], r[3], (r[3] == "-" ? "-" : sh[r[3]])
    }
    END {
      n = split(inputs, in_list, " ")
      for (i = 1; i <= n; i++) printf "-\t-\t%s\t%s\n", in_list[i], sh[in_list[i]]
    }' "${tmp_dst}" "${tmp_src}" "${FOOTPRINT}" > "${DIGEST}.tmp"
  rm -f "${tmp_dst}" "${tmp_src}"
  mv -f "${DIGEST}.tmp" "${DIGEST}"
}

# 0a) R-8 identity guard — before any source check and before any write, so a refused
#     sandbox is never touched. The live Claude configuration directories are the
#     declared workspace root's, the account home's workspace's and the account home's
#     own. The account home comes from the user database, never from ${HOME}.
ACCOUNT_HOME="$(python3 -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)' 2>/dev/null || true)"
if [ -z "${ACCOUNT_HOME}" ] || [ ! -d "${ACCOUNT_HOME}" ]; then
  log "setup-ci-layout.sh: REFUSED — the account home could not be read from the user database, so the live Claude configuration directories cannot be checked (R-8). Nothing was written."
  exit 65
fi

# $1 = a root whose .claude/ is a live Claude configuration directory. Refuses when the
# sandbox IS that root (its .claude/ would be the live directory, whether or not it
# exists yet), or when <sandbox>/.claude is, or sits inside, the live directory —
# except inside its worktrees/<name>/, where a linked checkout legitimately lives.
# Every comparison is filesystem identity (test -ef), never a path string.
refuse_live_root() {
  local root="$1" live p rel=""
  if [ -z "${root}" ] || [ ! -d "${root}" ]; then return 0; fi
  if [ -d "${SANDBOX}" ] && [ "${SANDBOX}" -ef "${root}" ]; then
    log "setup-ci-layout.sh: REFUSED — the sandbox ${SANDBOX} is the live root ${root}, so its .claude/ is a live Claude configuration directory (R-8). Nothing was written. Pass --sandbox <a directory of its own>."
    exit 65
  fi
  live="${root}/.claude"
  if [ ! -d "${live}" ]; then return 0; fi
  p="${CLAUDE_DIR}"
  while :; do
    if [ -e "${p}" ] && [ "${p}" -ef "${live}" ]; then
      case "${rel}" in
        worktrees/*/*) return 0 ;;
      esac
      log "setup-ci-layout.sh: REFUSED — ${CLAUDE_DIR} is, or sits inside, the live Claude configuration directory ${live} (R-8). Nothing was written. Only a linked checkout under its worktrees/ directory may hold a layout there."
      exit 65
    fi
    if [ -z "${p}" ] || [ "${p}" = "/" ]; then return 0; fi
    rel="${p##*/}${rel:+/${rel}}"
    p="${p%/*}"
    if [ -z "${p}" ]; then p="/"; fi
  done
}
if [ -n "${CLAUDE_WORKSPACE_ROOT:-}" ]; then refuse_live_root "${CLAUDE_WORKSPACE_ROOT}"; fi
refuse_live_root "${ACCOUNT_HOME}/Claude"
refuse_live_root "${ACCOUNT_HOME}"

HOOKS_SRC="${REPO_ROOT}/core/hooks"
TESTS_SRC="${REPO_ROOT}/core/hooks/tests"
ALLOWLIST_SRC="${REPO_ROOT}/core/config/allowlists"
MANIFEST="${REPO_ROOT}/core/deploy/composition-surface-manifest.sh"

for required in "${HOOKS_SRC}" "${TESTS_SRC}" "${ALLOWLIST_SRC}" "${MANIFEST}"; do
  if [ ! -e "${required}" ]; then
    log "setup-ci-layout.sh: required source missing: ${required}"
    exit 1
  fi
done

if [ "${SANDBOX_IS_CHECKOUT}" -eq 1 ] && [ -d "${REPO_ROOT}/.git" ]; then
  log "setup-ci-layout: NOTE — the default site is a primary checkout (its .git is a directory, not a linked worktree's pointer file), so the layout lands in that checkout's own .claude/, beside any project settings kept there. A linked worktree is the intended site."
fi

# 0b) The layout's own directories, where they already exist, must be real directories
#     that resolve inside the sandbox.
for _d in "${CLAUDE_DIR}" "${HOOKS_DST}" "${TESTS_DST}"; do
  if [ -e "${_d}" ] || [ -L "${_d}" ]; then
    if [ ! -d "${_d}" ] || ! layout_inside "${_d}"; then
      layout_refuse "${_d} is not a directory inside the sandbox (a file, or a link that leads out of it). Nothing was written."
    fi
  fi
done

# The hook-tier basenames the manifest materializes at <sandbox>/.claude/ (step 3),
# parsed in one pass.
HOOK_TIER_BASENAMES="$(awk '
  /^[[:space:]]*"[^"]+\|[^"]+\|[^"]+"/ {
    row = $0; sub(/^[[:space:]]*"/, "", row); sub(/".*$/, "", row)
    split(row, f, "|")
    if (f[2] == "hook") { k = split(f[1], p, "/"); print p[k] }
  }' "${MANIFEST}")"

# The instance-tier files a deployed security hook reads (step 3b), as sandbox-relative
# paths. The set is declared once, in lib-instance-path.sh, and resolved here for this
# sandbox by the resolver the hooks source, with PMO_INSTANCE_PATH unset so an exported
# value cannot aim a write at a real instance. Each destination must be a plain path that
# stays inside the sandbox, checked now so that a violation writes nothing (R-8).
HOOK_READ_RELS=""
INSTANCE_LIB="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
if [ -f "${INSTANCE_LIB}" ]; then
  _hook_read="$(
    unset PMO_INSTANCE_PATH
    # shellcheck source=/dev/null
    . "${INSTANCE_LIB}" >/dev/null 2>&1 || exit 0
    command -v pmo_hook_read_instance_files_for >/dev/null 2>&1 || exit 0
    pmo_hook_read_instance_files_for "${SANDBOX}"
  )" || _hook_read=""
  while IFS= read -r _p; do
    [ -n "${_p}" ] || continue
    _rel="${_p#"${SANDBOX}/"}"
    if [ "${_rel}" = "${_p}" ] || ! layout_rel_ok "${_rel}"; then
      layout_refuse "a file a security hook reads resolves outside the sandbox (${_p}). Nothing was written."
    fi
    if [ "${_rel%/*}" != "${_rel}" ]; then
      _d="${SANDBOX}/${_rel%/*}"
      if [ -e "${_d}" ] || [ -L "${_d}" ]; then
        if [ ! -d "${_d}" ] || ! layout_inside "${_d}"; then
          layout_refuse "${_d} is not a directory inside the sandbox (a file, or a link that leads out of it). Nothing was written."
        fi
      fi
    fi
    HOOK_READ_RELS="${HOOK_READ_RELS}${_rel}"$'\n'
  done <<< "${_hook_read}"
else
  log "setup-ci-layout: WARNING resolver missing at ${INSTANCE_LIB}; no instance-tier file a hook reads can be materialized"
fi

# 0c) Ownership. The marker (step 1) is written before anything is copied; its
#     presence is the proof of ownership, and the recorded footprint is what the purge
#     removes. Without it, any layout file already in the sandbox belongs to someone
#     else — another tool, or a layout an earlier version of this helper built without
#     a footprint — and this helper will not overwrite or delete what it did not record.
if [ -f "${OWNER_MARK}" ] && [ ! -L "${OWNER_MARK}" ]; then
  layout_purge
  log "setup-ci-layout: replaced this helper's earlier layout at ${CLAUDE_DIR} (exactly its recorded files)"
else
  _found=""
  if [ -e "${HOOKS_DST}" ]; then _found="${_found} .claude/hooks"; fi
  for _b in ${HOOK_TIER_BASENAMES}; do
    if [ -e "${CLAUDE_DIR}/${_b}" ]; then _found="${_found} .claude/${_b}"; fi
  done
  while IFS= read -r _rel; do
    if [ -n "${_rel}" ] && { [ -e "${SANDBOX}/${_rel}" ] || [ -L "${SANDBOX}/${_rel}" ]; }; then _found="${_found} ${_rel}"; fi
  done <<< "${HOOK_READ_RELS}"
  if [ -e "${CLAUDE_DIR}/rules/bypass-mode-readiness.md" ]; then _found="${_found} .claude/rules/bypass-mode-readiness.md"; fi
  if [ -e "${CLAUDE_DIR}/rules/bypass-mode-readiness" ]; then _found="${_found} .claude/rules/bypass-mode-readiness"; fi
  if [ -n "${_found}" ]; then
    log "setup-ci-layout.sh: REFUSED — ${SANDBOX} already holds layout files this helper has no record of writing (no ${OWNER_MARK##*/}):${_found}. Nothing was written. They belong to another tool, or to a layout an earlier version of this helper built without a recorded footprint. Move them to the Trash, then re-run this helper — from ${SANDBOX}: trash${_found}"
    exit 65
  fi
fi

# At the default site the readiness corpus is never mirrored (step 1g), so a mirror
# still present here is a leftover this helper did not record, and the doc-tie arms
# would read it ahead of the corpus in place.
if [ "${SANDBOX_IS_CHECKOUT}" -eq 1 ]; then
  _found=""
  if [ -e "${CLAUDE_DIR}/rules/bypass-mode-readiness.md" ]; then _found="${_found} .claude/rules/bypass-mode-readiness.md"; fi
  if [ -e "${CLAUDE_DIR}/rules/bypass-mode-readiness" ]; then _found="${_found} .claude/rules/bypass-mode-readiness"; fi
  if [ -n "${_found}" ]; then
    log "setup-ci-layout.sh: REFUSED — ${SANDBOX} carries a readiness-corpus mirror this helper has no record of writing:${_found}. Nothing was written. Move it to the Trash, then re-run this helper — from ${SANDBOX}: trash${_found}"
    exit 65
  fi
fi

# 1) Create <sandbox>/.claude/hooks/tests/ and take ownership BEFORE anything is
#    copied: the marker goes first, then the footprint, opened with a record for each
#    directory this step created.
_created=""
for _rel in .claude .claude/hooks .claude/hooks/tests; do
  if [ ! -d "${SANDBOX}/${_rel}" ]; then _created="${_created} ${_rel}"; fi
done
mkdir -p "${TESTS_DST}"
if ! layout_inside "${TESTS_DST}"; then
  layout_refuse "${TESTS_DST} resolves outside the sandbox. Nothing was copied."
fi
printf '%s\n' "This layout was written by core/hooks/tests/setup-ci-layout.sh. Its files are listed in .layout-footprint beside this marker, and the next run removes exactly those." > "${OWNER_MARK}"
: > "${FOOTPRINT}"
for _rel in ${_created}; do printf 'd\t%s\t-\n' "${_rel}" >> "${FOOTPRINT}"; done
LAYOUT_DIRS_OK=" .claude .claude/hooks .claude/hooks/tests "

# Token substitution values.
WS_ROOT="${HOME}/Claude"
HOMEDIR="${HOME}"
GH_HANDLE="${PMO_TEST_GITHUB_HANDLE:-pmo-test-handle}"

# 1) Copy hooks.
log "setup-ci-layout: copying hooks -> ${HOOKS_DST}"
for hook in "${HOOKS_SRC}"/*.sh; do
  [ -f "${hook}" ] || continue
  layout_put copy ".claude/hooks/${hook##*/}" "core/hooks/${hook##*/}"
done
chmod +x "${HOOKS_DST}"/*.sh

# 1b) Co-locate the shared path-leak primitive next to the hooks, mirroring the
#     deployed posture (setup-workspace.sh co-deploys it to .claude/hooks/).
#     block-gh-path-leak.sh resolves it from ${HOOK_DIR}/path-leak-patterns.sh; the
#     source lives at core/deploy/tools/, outside the hooks dir the loop above copies.
PRIMITIVE_SRC="${REPO_ROOT}/core/deploy/tools/path-leak-patterns.sh"
if [ -f "${PRIMITIVE_SRC}" ]; then
  layout_put copy ".claude/hooks/path-leak-patterns.sh" "core/deploy/tools/path-leak-patterns.sh"
  log "setup-ci-layout: co-located path-leak primitive -> ${HOOKS_DST}/path-leak-patterns.sh"
else
  log "setup-ci-layout: WARNING path-leak primitive missing at ${PRIMITIVE_SRC}"
fi

# 1b') Co-locate the shared operator-instance / needle resolver next to the hooks,
#      mirroring the deployed posture (setup-workspace.sh co-deploys it to .claude/hooks/).
#      block-scope-segregation.sh (#384) resolves it from ${HOOK_DIR}/lib-instance-path.sh
#      for its CD-4 localized-needle scan. The Gate 2 hook (block-skill-direct-edit.sh)
#      resolves the skill-editor exemption list through it, and allowlist-add.sh resolves
#      the same list to admit it as a target; without it the hook grants no exemption and
#      the writer refuses the list. The source lives at core/deploy/, outside the hooks
#      dir the loop above copies.
NEEDLELIB_SRC="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
if [ -f "${NEEDLELIB_SRC}" ]; then
  layout_put copy ".claude/hooks/lib-instance-path.sh" "core/deploy/lib-instance-path.sh"
  log "setup-ci-layout: co-located needle resolver -> ${HOOKS_DST}/lib-instance-path.sh"
else
  log "setup-ci-layout: WARNING needle resolver missing at ${NEEDLELIB_SRC}"
fi

# 1c) Co-locate the shared jq/dependency resolver at .claude/hooks/lib/, mirroring the
#     deployed posture (setup-workspace.sh co-deploys it there). Every security hook
#     sources it from ${HOOK_DIR}/lib/dep-resolve.sh and fails CLOSED without it
#     (GHSA-9cjm-v22x-4x33); the source lives at core/hooks/lib/, a subdir the *.sh
#     loop above does not copy.
DEPRESOLVE_SRC="${HOOKS_SRC}/lib/dep-resolve.sh"
if [ -f "${DEPRESOLVE_SRC}" ]; then
  layout_put copy ".claude/hooks/lib/dep-resolve.sh" "core/hooks/lib/dep-resolve.sh"
  log "setup-ci-layout: co-located dep-resolve resolver -> ${HOOKS_DST}/lib/dep-resolve.sh"
else
  log "setup-ci-layout: WARNING dep-resolve resolver missing at ${DEPRESOLVE_SRC}"
fi

# 1d) Co-locate the positional-issue-ref classifier at .claude/hooks/lib/, mirroring the
#     deployed posture (setup-workspace.sh co-deploys it there). block-fragile-refs.sh
#     sources it from ${HOOK_DIR}/lib/positional-issueref.awk and — post
#     GHSA-g9g6-28c9-vrx5 — fails CLOSED in enforce without it; the source lives at
#     core/hooks/lib/, a subdir the *.sh loop above does not copy. Without this the CI
#     deployed-layout would diverge from a correct install and read the positional
#     detector as absent.
POSAWK_SRC="${HOOKS_SRC}/lib/positional-issueref.awk"
if [ -f "${POSAWK_SRC}" ]; then
  layout_put copy ".claude/hooks/lib/positional-issueref.awk" "core/hooks/lib/positional-issueref.awk"
  log "setup-ci-layout: co-located positional classifier -> ${HOOKS_DST}/lib/positional-issueref.awk"
else
  log "setup-ci-layout: WARNING positional classifier missing at ${POSAWK_SRC}"
fi

# 1d') Co-locate the shared command-start canonicalizer at .claude/hooks/lib/, mirroring the
#      deployed posture (setup-workspace.sh co-deploys it there). ALL FOUR anchor-carrying
#      hooks (block-destructive, block-egress, block-fs-boundary, block-rm-prefer-trash) read
#      it from ${HOOK_DIR}/lib/command-position.awk to decide where a command actually starts,
#      canary it before trusting its output, and fail CLOSED in enforce without it; the source
#      lives at core/hooks/lib/, a subdir the *.sh loop above does not copy. WITHOUT this the
#      sandbox hooks would deny EVERY payload and four whole suites would fail on nearly every
#      assertion — the same CI-fidelity class as the dep-resolve / positional co-locations.
CMDPOSAWK_SRC="${HOOKS_SRC}/lib/command-position.awk"
if [ -f "${CMDPOSAWK_SRC}" ]; then
  layout_put copy ".claude/hooks/lib/command-position.awk" "core/hooks/lib/command-position.awk"
  log "setup-ci-layout: co-located command-position canonicalizer -> ${HOOKS_DST}/lib/command-position.awk"
else
  log "setup-ci-layout: WARNING command-position canonicalizer missing at ${CMDPOSAWK_SRC}"
fi

# 1e') Co-locate the reference-durability detector constants at .claude/hooks/lib/, mirroring
#      the deployed posture (setup-workspace.sh co-deploys it there). block-fragile-refs.sh
#      sources it from ${HOOK_DIR}/lib/fragile-ref-patterns.sh for EVERY pattern it evaluates;
#      the source lives at core/hooks/lib/, a subdir the *.sh loop above does not copy. WITHOUT
#      this the sandbox hook has no detectors and fails CLOSED in enforce — which blocks even
#      the clean-prose ALLOW cases, so block-fragile-refs.test.sh would fail on nearly every
#      assertion. Same CI-fidelity class as the dep-resolve / positional co-locations above.
PATTERNSLIB_SRC="${HOOKS_SRC}/lib/fragile-ref-patterns.sh"
if [ -f "${PATTERNSLIB_SRC}" ]; then
  layout_put copy ".claude/hooks/lib/fragile-ref-patterns.sh" "core/hooks/lib/fragile-ref-patterns.sh"
  log "setup-ci-layout: co-located detector constants -> ${HOOKS_DST}/lib/fragile-ref-patterns.sh"
else
  log "setup-ci-layout: WARNING detector constants missing at ${PATTERNSLIB_SRC}"
fi

# 1e) Co-locate the master-activation gate lib at .claude/hooks/lib/, mirroring the deployed
#     posture (setup-workspace.sh co-deploys it there, #310). Every block-*.sh sources it from
#     ${HOOK_DIR}/lib/master-enable.sh to resolve the durable opt-in master-enable state. WITHOUT
#     this the CI sandbox would diverge from a correct install (the hooks would fall back to
#     fail-toward-current-behavior and CI would never exercise the real gate) — the same
#     CI-fidelity class the dep-resolve / positional co-locations above exist to prevent. The
#     test-runner establishes master ON so the rule-tests run against active hooks.
MASTERLIB_SRC="${HOOKS_SRC}/lib/master-enable.sh"
if [ -f "${MASTERLIB_SRC}" ]; then
  layout_put copy ".claude/hooks/lib/master-enable.sh" "core/hooks/lib/master-enable.sh"
  log "setup-ci-layout: co-located master-activation gate -> ${HOOKS_DST}/lib/master-enable.sh"
else
  log "setup-ci-layout: WARNING master-activation gate missing at ${MASTERLIB_SRC}"
fi

# 1f) Co-locate the workspace-scope gate lib at .claude/hooks/lib/, mirroring the deployed
#     posture (setup-workspace.sh co-deploys it there, #4436). Every block-*.sh sources it from
#     ${HOOK_DIR}/lib/scope-guard.sh as precedence layer 3. WITHOUT this the CI sandbox would
#     diverge from a correct install: the hooks would take the lib-missing branch (which does
#     NOT gate, so every rule assertion would still pass) and CI would never exercise the real
#     layer — a silently vacuous pass, the same CI-fidelity class the co-locations above exist
#     to prevent. The test-runner neutralizes the layer for the RULE suites by exporting
#     PMO_SCOPE_GUARD_ROOT=/ ; scope-guard.test.sh owns the layer and sets its own root per case.
SCOPEGUARD_SRC="${HOOKS_SRC}/lib/scope-guard.sh"
if [ -f "${SCOPEGUARD_SRC}" ]; then
  layout_put copy ".claude/hooks/lib/scope-guard.sh" "core/hooks/lib/scope-guard.sh"
  log "setup-ci-layout: co-located workspace-scope gate -> ${HOOKS_DST}/lib/scope-guard.sh"
else
  log "setup-ci-layout: WARNING workspace-scope gate missing at ${SCOPEGUARD_SRC}"
fi

# 1f') Co-locate the shared repository-membership helper at .claude/hooks/lib/, mirroring the
#      deployed posture (setup-workspace.sh co-deploys it there, #6200). block-autonomy-ceiling.sh
#      and block-draft-files.sh source it for every membership question. WITHOUT this the CI sandbox
#      would diverge from a correct install. block-autonomy-ceiling would take its
#      helper-unavailable branch (the -001 second stage fails closed; the cross-domain target reads
#      undeterminable), and block-draft-files would abstain at its identity gate. CI would then test
#      the absence posture instead of the rule. Same CI-fidelity class as the co-locations above.
MEMBERSHIPLIB_SRC="${HOOKS_SRC}/lib/platform-membership.sh"
if [ -f "${MEMBERSHIPLIB_SRC}" ]; then
  layout_put copy ".claude/hooks/lib/platform-membership.sh" "core/hooks/lib/platform-membership.sh"
  log "setup-ci-layout: co-located repository-membership helper -> ${HOOKS_DST}/lib/platform-membership.sh"
else
  log "setup-ci-layout: WARNING repository-membership helper missing at ${MEMBERSHIPLIB_SRC}"
fi

# 1g) Mirror the bypass-mode readiness rules corpus at .claude/rules/ — in an explicit
#     sandbox only. NO HOOK READS EITHER PATH AT RUNTIME, so this cannot move a single
#     verdict. The copy exists for the doc-tie arms (NOEXEC-DOC-* in
#     block-destructive.test.sh, MODEOFF-* in block-fs-boundary.test.sh), which hold a
#     DOCUMENTED CLAIM against the hook's ACTUAL verdict in the same run: they read
#     <layout>/.claude/rules/... first and fall back to the corpus in place under
#     core/rules/. It is not a copy of a deployed file — the deployed rules mirror does
#     not carry this corpus. At the default site the sandbox IS the source checkout, so
#     that fallback finds the corpus in place and the copy is skipped, which also keeps
#     the corpus out of <checkout>/.claude/rules/, a project rules directory that a
#     session started in that checkout may load.
RULES_INDEX_SRC="${REPO_ROOT}/core/rules/bypass-mode-readiness.md"
RULES_FRAG_SRC="${REPO_ROOT}/core/rules/bypass-mode-readiness"
if [ "${SANDBOX_IS_CHECKOUT}" -eq 1 ]; then
  log "setup-ci-layout: sandbox is the source checkout — the readiness corpus stays in place at core/rules/ (not mirrored into .claude/rules/)"
elif [ -f "${RULES_INDEX_SRC}" ] && [ -d "${RULES_FRAG_SRC}" ]; then
  layout_put copy ".claude/rules/bypass-mode-readiness.md" "core/rules/bypass-mode-readiness.md"
  for rules_frag in "${RULES_FRAG_SRC}"/*.md; do
    [ -f "${rules_frag}" ] || continue
    layout_put copy ".claude/rules/bypass-mode-readiness/${rules_frag##*/}" "core/rules/bypass-mode-readiness/${rules_frag##*/}"
  done
  log "setup-ci-layout: mirrored readiness rules -> ${CLAUDE_DIR}/rules/"
else
  log "setup-ci-layout: WARNING readiness rules corpus missing at ${RULES_INDEX_SRC}"
fi

# 2) Copy tests + runner (skip this setup script — it is not a test file).
log "setup-ci-layout: copying tests -> ${TESTS_DST}"
for tf in "${TESTS_SRC}"/*.sh; do
  [ -f "${tf}" ] || continue
  case "${tf##*/}" in
    setup-ci-layout.sh) continue ;;
  esac
  layout_put copy ".claude/hooks/tests/${tf##*/}" "core/hooks/tests/${tf##*/}"
done
chmod +x "${TESTS_DST}"/*.sh

# 2b) Record the SOURCE repo root beside the tests.
#
#     A test that grades a CORPUS document cannot derive the corpus location from
#     its own path here. In a source checkout a test at core/hooks/tests/ walks up
#     two levels to the repo root and finds core/disciplines/; materialized into
#     this sandbox the identical walk lands on <sandbox>/, where no corpus exists.
#     block-external-seam-shape.test.sh's AC-2 arms did exactly that and reported
#     an unreadable file (-1 hits) as a BROKEN PROBE — the fail-loud branch working
#     correctly on a resolution defect.
#
#     The sandbox deliberately does NOT copy the corpus: it materializes a hook
#     RUNTIME, and core/disciplines/ is not part of one. So the layout carries a
#     pointer back to the source instead. Not a *.sh file, so step 2 above never
#     re-copies it into a nested sandbox.
layout_put stdin ".claude/hooks/tests/.source-repo-root" - <<< "${REPO_ROOT}"

# 3) Materialize token-resolved allowlists for the "hook"-tier composition
#    surface, reading the manifest as the source of truth for which files are
#    hook-tier and which carry the "tokens" flag.
#    Manifest entry format: "<src-relpath>|<tier>|<tokens-flag>".
log "setup-ci-layout: materializing hook-tier allowlists -> ${CLAUDE_DIR}"
materialized=0
# shellcheck disable=SC2013  # field-split read of the manifest entry rows
while IFS= read -r row; do
  src="$(printf '%s' "${row}" | awk -F'|' '{print $1}')"
  tier="$(printf '%s' "${row}" | awk -F'|' '{print $2}')"
  flag="$(printf '%s' "${row}" | awk -F'|' '{print $3}')"
  [ "${tier}" = "hook" ] || continue
  src_path="${REPO_ROOT}/${src}"
  base="$(basename "${src}")"
  if [ ! -f "${src_path}" ]; then
    log "setup-ci-layout: WARNING hook-tier source missing, skipping: ${src_path}"
    continue
  fi
  if [ "${flag}" = "tokens" ]; then
    sed -e "s#\[CLAUDE_WORKSPACE_ROOT\]#${WS_ROOT}#g" \
        -e "s#\[OPERATOR_HOMEDIR_PATH\]#${HOMEDIR}#g" \
        -e "s#\[OPERATOR_GITHUB\]#${GH_HANDLE}#g" \
        "${src_path}" | layout_put stdin ".claude/${base}" "${src}"
  else
    # raw-flag files (webfetch/ssh/mcp-write/shell-injection/...) may still
    # carry [OPERATOR_GITHUB] occurrences the deployed allowlist resolves;
    # resolve that token too so allow-cases match. Path tokens are not present
    # in raw files by contract, but resolving them is harmless (no-op).
    sed -e "s#\[OPERATOR_GITHUB\]#${GH_HANDLE}#g" \
        "${src_path}" | layout_put stdin ".claude/${base}" "${src}"
  fi
  materialized=$((materialized + 1))
done < <(grep -E '^[[:space:]]*"[^"]+\|[^"]+\|[^"]+"' "${MANIFEST}" \
           | sed -E 's/^[[:space:]]*"//; s/".*$//')

if [ "${materialized}" -lt 1 ]; then
  log "setup-ci-layout: ERROR no hook-tier allowlists materialized"
  exit 1
fi
log "setup-ci-layout: materialized ${materialized} hook-tier allowlist(s)"

# 3b) Materialize the instance-tier files a deployed security hook reads — the set
#     resolved and checked in step 0 — each copied verbatim from its own manifest row
#     (the instance rows are raw) through the recorded write path, so the purge removes
#     it on the next build. The Gate 2 hook reads the skill-editor exemption list here,
#     at the path the layout's own hook resolves, and the hook suite's end-to-end arm
#     grades that read. The row is found by tier and basename in one awk pass.
hook_read_total=0
hook_read_copied=0
while IFS= read -r _rel; do
  [ -n "${_rel}" ] || continue
  hook_read_total=$((hook_read_total + 1))
  _src="$(awk -v b="${_rel##*/}" '
    /^[[:space:]]*"[^"]+\|[^"]+\|[^"]+"/ {
      row = $0; sub(/^[[:space:]]*"/, "", row); sub(/".*$/, "", row)
      split(row, f, "|"); k = split(f[1], p, "/")
      if (f[2] == "instance" && p[k] == b) { print f[1]; exit }
    }' "${MANIFEST}")"
  if [ -z "${_src}" ] || [ ! -f "${REPO_ROOT}/${_src}" ]; then
    log "setup-ci-layout: WARNING no instance-tier manifest source for ${_rel}; not materialized"
    continue
  fi
  layout_put copy "${_rel}" "${_src}"
  hook_read_copied=$((hook_read_copied + 1))
done <<< "${HOOK_READ_RELS}"
if [ "${hook_read_total}" -gt 0 ] && [ "${hook_read_copied}" -eq 0 ]; then
  log "setup-ci-layout: ERROR none of the ${hook_read_total} instance-tier file(s) a security hook reads was materialized"
  exit 1
fi
log "setup-ci-layout: materialized ${hook_read_copied} of ${hook_read_total} instance-tier file(s) a security hook reads"

# 4) Sandbox .mode (enforce). The tests mutate THIS file per-case and restore
#    it; the live ~/Claude/.claude/hooks/.mode is never touched (R-8).
printf 'enforce' | layout_put stdin ".claude/hooks/.mode" -

# 4b) Sandbox .gh-path-leak-mode (enforce), so the layout mirrors the deployed shape
#     for the one hook that reads its own mode file rather than the shared one. The
#     seed is enforce for the same reason .mode is — the per-case tests set their own
#     value — and it is deliberately NOT the hook's shipped default. The shipped
#     default is exercised by REMOVING this file: with the shared .mode seeded at
#     enforce and this file absent, an exclusive build resolves the in-script default
#     and a build that had re-acquired a fallback would be promoted to enforce by the
#     shared file. Seeding both at the shipped default would make that case agree with
#     itself and prove nothing.
printf 'enforce' | layout_put stdin ".claude/hooks/.gh-path-leak-mode" -

# 4c) Sandbox .autonomy-mode (enforce), for the same reason and by the same rule as
#     4b: block-autonomy-ceiling.sh reads its own mode file, so the layout must carry
#     one or the sandbox silently exercises the hook's in-script default instead of a
#     seeded value. Leaving it absent is what let a real packaging defect hide — the
#     template was tracked but had no install call site, so a fresh install never
#     received it, and CI could not see the difference because CI reproduced the
#     unseeded condition. A test layout that omits a file the deployed layout carries
#     is not a smaller sandbox, it is a different one.
printf 'enforce' | layout_put stdin ".claude/hooks/.autonomy-mode" -

# 5) Record the build digest, last. The layout is a snapshot of the source it was
#    copied from, and the runner grades the snapshot, so the suite's LAYOUT-FRESH-01
#    arm re-hashes both sides of every record and fails a layout that is stale against
#    its source, or was changed after the build, instead of grading it as current.
layout_write_digest

log "setup-ci-layout: layout ready"
log "  sandbox       : ${SANDBOX}"
log "  hooks         : ${HOOKS_DST}"
log "  tests         : ${TESTS_DST}"
log "  workspace root: ${WS_ROOT}"
log "  github handle : ${GH_HANDLE}"
if [ "${SANDBOX_IS_CHECKOUT}" -eq 1 ]; then
  log "  next          : bash .claude/hooks/tests/test-runner.sh  (from ${SANDBOX})"
fi

# The ONLY stdout line: the tests directory (for the caller to run the runner).
printf '%s\n' "${TESTS_DST}"
