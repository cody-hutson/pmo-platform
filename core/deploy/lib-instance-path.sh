#!/usr/bin/env bash
# lib-instance-path.sh — single resolver for the operator-instance directory, the
# localized-context needle file, and the people-roster file.
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
