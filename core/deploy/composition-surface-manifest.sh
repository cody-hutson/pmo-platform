#!/usr/bin/env bash
# composition-surface-manifest.sh — shared manifest of composition-surface files
#
# Sourced by:
#   - docs/scripts/setup-workspace.sh (install)
#   - update.sh                       (regenerate)
#
# Spec:
#   - Category definition + per-category contract: core/standards/composition-surface-spec.md §1
#   - Marker syntax:                                core/standards/composition-surface-spec.md §2
#
# Format per entry (delimiter: pipe):
#   "<source-relative-path>|<runtime-tier>|<tokens-flag>"
#
#   <source-relative-path>  Path relative to repo root (where the package source lives)
#   <runtime-tier>          "hook"      → ~/Claude/.claude/<basename>
#                           "instance"  → ~/Claude/personal/pmo-instance/<basename>
#                           "hub-state" → ~/Claude/personal/pmo-instance/hub-state/<basename>
#                                         (per core/standards/depersonalization-spec.md §4
#                                          <OPERATOR_INSTANCE_HUB_STATE_PATH> token resolution
#                                          — schema templates for hub-state Surfaces A/C +
#                                          action-items per hub-session-continuity.md §2 +
#                                          hub-action-tracking.md §2; runtime per-release
#                                          subdirectories (vX.Y/) created lazily by hub
#                                          on first surface emit)
#   <tokens-flag>           "tokens"    → substitute [OPERATOR_*] / [CLAUDE_*] tokens at write
#                           "raw"       → install verbatim (no substitution)
#
# Adding a new composition-surface file: append one row. No other code change needed.
#
# IMPORTANT — bash 3.2 array scope:
# This file uses PLAIN ASSIGNMENT (no `declare -a`) on purpose. Under bash 3.2
# (the macOS system bash), `declare -a` inside a function — or inside a script
# sourced from a function — makes the array function-local; the caller never
# sees it. The lib_compose_source_manifest helper IS a function, so any
# `declare -a` here would silently break all 18 composition-surface installs.
# Plain assignment is global by default in bash 3.2, which is what we need.
# (Verified: bash 3.2.57(1)-release on Darwin 25.x.)

COMPOSITION_SURFACE_FILES=(
  # Hook-tier (workspace-scoped, ~/Claude/.claude/<basename>)
  # Token-bearing — substituted at install + regenerated at update
  "core/config/allowlists/egress-allowlist.txt|hook|tokens"
  "core/config/allowlists/fs-boundary-allowlist.txt|hook|tokens"
  "core/config/allowlists/script-execution-allowlist.txt|hook|tokens"
  # Token-free — verbatim install + verbatim regeneration of managed section
  "core/config/allowlists/cleanup-protect-list.txt|hook|raw"
  "core/config/allowlists/webfetch-allowlist.txt|hook|raw"
  "core/config/allowlists/ssh-allowlist.txt|hook|raw"
  "core/config/allowlists/mcp-write-allowlist.txt|hook|raw"
  "core/config/allowlists/shell-injection-allowlist.txt|hook|raw"
  "core/config/allowlists/skip-localized-context-check.txt|hook|raw"
  "core/config/allowlists/skip-release-note-check.txt|hook|raw"

  # Instance-tier (operator-scoped, ~/Claude/personal/pmo-instance/<basename>)
  # Token-free — operator extends per-instance over time
  "core/config/allowlists/skill-editor-exemption-list.txt|instance|raw"
  "core/config/allowlists/skip-doc-link-check.txt|instance|raw"
  "core/config/allowlists/agents-model-overrides.txt|instance|raw"
  "core/config/allowlists/status-label-invariant-exemption-list.txt|instance|raw"
  # Platform-behavior config surface (adapter-config-foundation, #22). Ships
  # Layer-1 global DEFAULTS + the managed-section fence; the operator extends
  # the Layer-1 surface in the OPERATOR ADDITIONS section. Per-tier VALUE
  # overrides live in separate Layer-2 surfaces (XDG config / PORTFOLIO.md /
  # program-config.toml / PROJECT.md) — NOT this seed. Token-free.
  "core/config/platform-config.toml.template|instance|raw"

  # Hub-state-tier (operator-scoped, ~/Claude/personal/pmo-instance/hub-state/<basename>)
  # Schema templates for hub-state Surfaces A, C + action-items ledger. Hub
  # copies these to <OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/<basename-stripped>
  # on first surface emit per release (lazy per-release directory creation
  # per hub-session-continuity.md §2 directory creation discipline).
  # Token-free — templates are placeholders; hub does milestone-slug
  # substitution at first emit, not setup-workspace-time substitution.
  "release/releases/hub-state/pending-approvals.md.template|hub-state|raw"
  "release/releases/hub-state/action-items.md.template|hub-state|raw"
  "release/releases/hub-state/sessions.md.template|hub-state|raw"
)
