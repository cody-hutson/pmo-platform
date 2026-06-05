#!/usr/bin/env bash
# notify-version-skew.sh — SessionStart hook
#
# Purpose:
#   Passively notify the operator when the local pmo-platform clone is behind
#   the latest published release. Never auto-applies; operator runs ./update.sh
#   when ready.
#
# Spec:
#   - Composition-surface durability layer: core/standards/composition-surface-spec.md §6
#   - Operator-facing update path:           docs/UPDATE.md
#
# Behavior:
#   1. Read local .version file at repo root.
#   2. Check cache at ~/.cache/pmo-platform/latest-release.json (TTL 24h).
#   3. If cache stale: query gh api repos/<owner>/<repo>/releases/latest.
#   4. If local < latest: print single-line notice to stderr.
#   5. Never block; on any error, fail silently (notification is advisory).
#
# Industry precedent: npm outdated-notice, gh CLI version notice, brew update-notice.

set -u
# Errors do not block session start. Trap and exit 0 on any failure.
trap 'exit 0' ERR

# Locate the .version file this install should compare against. The same hook
# file runs from two layouts, so try the candidates in order (first readable
# wins):
#   1. Deployed hook — <ws>/.claude/hooks/ → snapshot at <ws>/.claude/.version
#      (shipped by setup-workspace.sh install_hooks; refreshed by update.sh).
#   2. Source clone  — <repo>/core/hooks/  → repo-root <repo>/.version
#      (also the layout the regression test and local dev runs exercise).
# The deployed snapshot is preferred because it is the artifact this hook owns;
# the two layouts are disjoint in practice (only one candidate exists per
# context), so the ordering only matters defensively. A SCRIPT_DIR/.. resolve
# (the previous logic) found neither — it pointed at core/ in the clone and at
# <ws>/.claude in a deployed workspace, where no .version exists.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION_FILE=""
for _candidate in "${SCRIPT_DIR}/../.version" "${SCRIPT_DIR}/../../.version"; do
  if [ -r "${_candidate}" ]; then
    VERSION_FILE="${_candidate}"
    break
  fi
done
readonly VERSION_FILE
readonly CACHE_DIR="${HOME}/.cache/pmo-platform"
readonly CACHE_FILE="${CACHE_DIR}/latest-release.json"
readonly CACHE_TTL_SECONDS=86400  # 24h
readonly OPERATOR_TOML="${HOME}/.config/pmo-platform/operator.toml"

# Defensive: required artifacts present?
[ -r "${VERSION_FILE}" ] || exit 0
command -v gh >/dev/null 2>&1 || exit 0

local_version=$(head -1 "${VERSION_FILE}" | tr -d '[:space:]')
[ -n "${local_version}" ] || exit 0

# Resolve operator's GitHub handle + repo name from operator.toml
operator_github=""
repo_name="pmo-platform"
if [ -r "${OPERATOR_TOML}" ]; then
  operator_github=$(grep -E '^operator_github' "${OPERATOR_TOML}" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  parsed_repo=$(grep -E '^pmo_platform_repo_name' "${OPERATOR_TOML}" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  [ -n "${parsed_repo}" ] && repo_name="${parsed_repo}"
fi
[ -n "${operator_github}" ] || exit 0

# Check cache TTL
fetch_latest=0
if [ -r "${CACHE_FILE}" ]; then
  if command -v stat >/dev/null 2>&1; then
    cache_mtime=$(stat -f %m "${CACHE_FILE}" 2>/dev/null || stat -c %Y "${CACHE_FILE}" 2>/dev/null || echo 0)
    now_epoch=$(date -u +%s)
    age=$((now_epoch - cache_mtime))
    if [ "${age}" -gt "${CACHE_TTL_SECONDS}" ]; then
      fetch_latest=1
    fi
  else
    fetch_latest=1
  fi
else
  fetch_latest=1
fi

# Fetch latest if cache stale
if [ "${fetch_latest}" -eq 1 ]; then
  mkdir -p "${CACHE_DIR}"
  if ! gh api "repos/${operator_github}/${repo_name}/releases/latest" \
       --jq '{tag_name: .tag_name, name: .name, published_at: .published_at}' \
       > "${CACHE_FILE}.tmp" 2>/dev/null; then
    rm -f "${CACHE_FILE}.tmp"
    exit 0
  fi
  mv "${CACHE_FILE}.tmp" "${CACHE_FILE}"
fi

# Parse cached tag_name
latest_version=$(grep -E '"tag_name"' "${CACHE_FILE}" 2>/dev/null | head -1 | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
[ -n "${latest_version}" ] || exit 0

# Compare versions (string equality is sufficient for the equal-case; for
# inequality, we only notify — operator decides actual action).
if [ "${local_version}" != "${latest_version}" ]; then
  printf '→ pmo-platform %s → %s available. Run ./update.sh to apply.\n' \
    "${local_version}" "${latest_version}" >&2
fi

exit 0
