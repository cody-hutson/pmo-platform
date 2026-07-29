#!/usr/bin/env bash
# lib-instance-path.sh — single resolver for the operator-instance directory, the
# localized-context needle file, the people-roster file, and the evals-results
# directory (home of the pipeline event log).
#
# Design rationale (applies existing ADRs — NO standalone ADR):
#   - The default base CANONICALIZES on the ADR-032 idiom
#     `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}`, NOT on PMO_INSTANCE_PATH (per
#     ADR-032 (Accepted) § "Canonicalization note — CLAUDE_WORKSPACE_ROOT, not
#     PMO_INSTANCE_PATH" + "invent no new variable"). No new variable is invented
#     here; PMO_INSTANCE_PATH, PMO_LOCALIZED_NEEDLES, and PMO_PEOPLE_ROSTER are
#     honored ONLY as pre-existing / direct-path back-compat overrides.
#   - This is the one resolution site for the instance/needle/roster path surface.
#     deploy.sh, the PII pre-commit hook, lib-composition.sh, the composition
#     manifest, check-canonical-structure.sh, extract-roster-needles.sh, and the
#     install/update/setup scripts source this lib and call the functions instead
#     of inlining `${PMO_INSTANCE_PATH:-...personal/pmo-instance}` (ADR-017 §
#     operator-instance surface convergence — collapse the inconsistent literals
#     into one resolver).
#
# Resolution (highest precedence first):
#   pmo_instance_path()      → ${PMO_INSTANCE_PATH:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance}
#   pmo_localized_needles()  → ${PMO_LOCALIZED_NEEDLES:-$(pmo_instance_path)/localized-context-needles.txt}
#   pmo_people_roster()      → ${PMO_PEOPLE_ROSTER:-$(pmo_instance_path)/people-roster.yaml}
#   pmo_evals_results_path() → $EVALS_RESULTS_PATH, else the operator.toml key
#                              operator_instance_evals_results_path, else
#                              ${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/evals/results
#                              (3 tiers — deliberately NOT expressible as one
#                              ${VAR:-default} expansion like the three above)
#
# All are pure stdout-echoing functions (no side effects, no mutation); safe to
# call under `set -euo pipefail`. Sourceable AND idempotent: re-sourcing is a
# no-op (the function definitions are simply re-declared).
#
# Bash version: 3.2.57-safe (no associative arrays, no bash-5 substring tricks).

# Echo the operator-instance base directory (no trailing slash).
pmo_instance_path() {
  printf '%s\n' "${PMO_INSTANCE_PATH:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance}"
}

# Echo the operator-instance base directory relative to an EXPLICIT workspace
# root (no trailing slash). For callers that already hold a workspace root and
# must keep it (e.g. lib-composition.sh, which sandboxes installs/tests via a
# passed --workspace-root and therefore cannot fall back to the $HOME-based
# default). PMO_INSTANCE_PATH still wins when set; otherwise the leaf is appended
# to the given base. Centralizing the `personal/pmo-instance` leaf here keeps it
# out of every other *.sh (AC1 / AC5).
# Usage: pmo_instance_path_for <workspace-root>
pmo_instance_path_for() {
  local _base="$1"
  printf '%s\n' "${PMO_INSTANCE_PATH:-${_base}/personal/pmo-instance}"
}

# Echo the absolute path to the localized-context needle file.
pmo_localized_needles() {
  printf '%s\n' "${PMO_LOCALIZED_NEEDLES:-$(pmo_instance_path)/localized-context-needles.txt}"
}

# Echo the absolute path to the operator-instance people-roster file. Mirrors
# pmo_localized_needles() exactly: a direct-path override (PMO_PEOPLE_ROSTER)
# wins; otherwise the leaf is appended to the $HOME-based instance default. The
# filled roster is operator-instance, out-of-tree, gitignored, and PII-bearing
# once filled — the install/update/setup seed and extract-roster-needles.sh all
# resolve it through here so the literal lives in exactly one place (ADR-017).
pmo_people_roster() {
  printf '%s\n' "${PMO_PEOPLE_ROSTER:-$(pmo_instance_path)/people-roster.yaml}"
}

# Echo the absolute path to the people-roster file relative to an EXPLICIT
# workspace root. The workspace-root analogue of pmo_people_roster(), for callers
# that already hold a workspace root and must keep it (the sandboxed
# --workspace-root install/update path, which cannot fall back to the $HOME
# default). PMO_PEOPLE_ROSTER still wins when set; otherwise the leaf is appended
# to pmo_instance_path_for <workspace-root>. Mirrors the pmo_instance_path /
# pmo_instance_path_for pairing.
# Usage: pmo_people_roster_for <workspace-root>
pmo_people_roster_for() {
  local _base="$1"
  printf '%s\n' "${PMO_PEOPLE_ROSTER:-$(pmo_instance_path_for "${_base}")/people-roster.yaml}"
}

# Echo the absolute path to the operator-instance evals-results directory (no
# trailing slash) — the home of the pipeline event log and its write-log.
#
# Three-tier resolution, mirroring release/tools/append-pipeline-event.sh — the
# WRITER of those files — so a reader can never resolve somewhere the writer does
# not write:
#   1. $EVALS_RESULTS_PATH                                     (env / direct override)
#   2. operator.toml  operator_instance_evals_results_path      (instance override)
#   3. ${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/evals/results
#
# The default, the override key, and the two-segment `evals/results` stem are all
# already registered under <OPERATOR_INSTANCE_EVALS_RESULTS_PATH> in
# core/standards/depersonalization-spec.md — this resolver adds no new surface, it
# collapses an inconsistent literal onto the governed one (ADR-017 § operator-
# instance surface convergence; ADR-032 canonicalization, no new variable).
#
# DELIBERATELY NOT composed on pmo_instance_path(). append-pipeline-event.sh does
# not honor PMO_INSTANCE_PATH when it writes, so composing on it would make a
# PMO_INSTANCE_PATH-relocated instance READ from a directory the writer never
# writes to — reintroducing, one tier down, the exact reader/writer path
# divergence this resolver exists to close (#4051).
#
# Tier 2 is intentionally built even though the key is absent on the canonical
# instance today: "not load-bearing today" is precisely the reasoning that
# produced #4051.
pmo_evals_results_path() {
  local _erp="${EVALS_RESULTS_PATH:-}"
  local _toml _val
  if [[ -z "$_erp" ]]; then
    _toml="${HOME}/.config/pmo-platform/operator.toml"
    if [[ -r "$_toml" ]]; then
      # `|| true`: the key is absent on instances using the canonical default;
      # tolerate grep's non-zero exit under `set -euo pipefail`.
      _val=$( { grep -E '^operator_instance_evals_results_path' "$_toml" 2>/dev/null || true; } \
                | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
      if [[ -n "$_val" ]]; then _erp="$_val"; fi
    fi
  fi
  printf '%s\n' "${_erp:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/evals/results}"
}
