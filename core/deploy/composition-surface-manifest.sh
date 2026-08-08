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
#   "<source-relative-path>|<runtime-tier>|<tokens-flag>[|<marker-dialect>]"
#
#   <source-relative-path>  Path relative to repo root (where the package source lives)
#   <runtime-tier>          "hook"           → <workspace-root>/.claude/<basename>
#                           "instance"       → <instance-base>/<basename>
#                           "hub-state"      → <instance-base>/hub-state/<basename>
#                                              (<instance-base> resolved by
#                                               lib_compose_resolve_target via the
#                                               lib-instance-path.sh resolver — #1830)
#                                              (per core/standards/depersonalization-spec.md §4
#                                               <OPERATOR_INSTANCE_HUB_STATE_PATH> token resolution
#                                               — schema templates for hub-state Surfaces A/C +
#                                               action-items per hub-session-continuity.md §2 +
#                                               hub-action-tracking.md §2; runtime per-release
#                                               subdirectories (vX.Y/) created lazily by hub
#                                               on first surface emit)
#                           "workspace-root" → <workspace-root>/<basename minus trailing .template>
#                                              (ADR-122; the only suffix-stripping tier)
#   <tokens-flag>           "tokens"    → substitute [OPERATOR_*] / [CLAUDE_*] tokens at write
#                           "raw"       → install verbatim (no substitution)
#   <marker-dialect>        OPTIONAL 4th field (ADR-122).
#                           "plain"     → comment-prefixed fence (# === BEGIN … ===)
#                           "markdown"  → HTML-comment fence (<!-- === BEGIN … === -->)
#                           ABSENT      → "plain". awk -F'|' '{print $4}' on a 3-field row
#                                         returns empty, so every pre-ADR-122 row keeps its
#                                         exact prior behavior with no rewrite.
#
# Adding a new composition-surface file: append one row. No other code change needed.
#
# IMPORTANT — bash 3.2 array scope:
# This file uses PLAIN ASSIGNMENT (no `declare -a`) on purpose. Under bash 3.2
# (the macOS system bash), `declare -a` inside a function — or inside a script
# sourced from a function — makes the array function-local; the caller never
# sees it. The lib_compose_source_manifest helper IS a function, so any
# `declare -a` here would silently break all 20 composition-surface installs.
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
  "core/config/allowlists/scope-segregation-allowlist.txt|hook|raw"
  "core/config/allowlists/skip-localized-context-check.txt|hook|raw"
  "core/config/allowlists/skip-release-note-check.txt|hook|raw"

  # Instance-tier (operator-scoped, <instance-base>/<basename>)
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

  # Hub-state-tier (operator-scoped, <instance-base>/hub-state/<basename>)
  # Schema templates for hub-state Surfaces A, C + action-items ledger. Hub
  # copies these to <OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/<basename-stripped>
  # on first surface emit per release (lazy per-release directory creation
  # per hub-session-continuity.md §2 directory creation discipline).
  # Token-free — templates are placeholders; hub does milestone-slug
  # substitution at first emit, not setup-workspace-time substitution.
  "release/releases/hub-state/pending-approvals.md.template|hub-state|raw"
  "release/releases/hub-state/action-items.md.template|hub-state|raw"
  "release/releases/hub-state/sessions.md.template|hub-state|raw"

  # Workspace-root tier (<workspace-root>/CLAUDE.md). The operator's top-level
  # governance file, re-categorized from Customizable to Composition-surface by
  # ADR-122. First and only `markdown`-dialect entry: its fence is the
  # HTML-comment form per composition-surface-spec.md §2.2. The
  # `workspace-root` tier strips the trailing `.template`, so this row targets
  # <workspace-root>/CLAUDE.md — NOT <workspace-root>/CLAUDE.md.template.
  #
  # Token-bearing: the composition writer substitutes the four identity tokens
  # the template body consumes ([OPERATOR_NAME], [OPERATOR_FIRST_NAME],
  # [OPERATOR_ROLE_TITLE], [OPERATOR_ORGANIZATION]). All four are REQUIRED at
  # install, so none can resolve empty and survive unsubstituted into the
  # composed file — which is the invariant that keeps this row safe under the
  # installer's own unresolved-token verification gate.
  "core/CLAUDE.md.template|workspace-root|tokens|markdown"
)

# --- Install-time token vocabulary (ADR-122 §Decision 8) --------------------
# LOAD-BEARING COMMENT — NOT documentation. docs/scripts/setup-workspace.sh
# `compute_active_tokens` greps THIS FILE (alongside core/CLAUDE.md.template and
# core/settings.json.template) for [(OPERATOR|CLAUDE|COWORK)_*] to derive
# ACTIVE_TOKENS — the set it prompts for and writes into operator.toml.
#
# WHY IT LIVES HERE: this declaration used to sit in core/CLAUDE.md.template's
# authoring header. ADR-122 makes that template's whole body the managed section,
# and an OPTIONAL token left empty in operator.toml would then survive
# unsubstituted into the composed CLAUDE.md and fail the installer's
# unresolved-token verification gate. The header had to leave the template; the
# declaration could not simply be deleted with it.
#
# DELETING OR RENAMING A TOKEN BELOW SHRINKS ACTIVE_TOKENS. The installer then
# stops resolving it and write_operator_toml persists it EMPTY — the exact
# silent-blanking failure the [COWORK_INSTALL_PATH_BASE] pairing fix addressed.
# Keep the spelling identical to core/standards/depersonalization-spec.md §1 and
# to compose.py's FIELD_TO_TOKEN. Pinned by test_lib_composition.sh.
#
#   [OPERATOR_NAME]            — Operator's full name (required)
#   [OPERATOR_FIRST_NAME]      — First name; derived as first word of [OPERATOR_NAME]
#   [OPERATOR_ROLE_TITLE]      — Job title (required)
#   [OPERATOR_ORGANIZATION]    — Employer / organization (required)
#   [OPERATOR_EMAIL]           — Workspace owner's email (comms-writer signatures)
#   [OPERATOR_GIT_EMAIL]       — Git commit-attribution email (settings.json.template)
#   [OPERATOR_PHONE]           — Workspace owner's phone (optional)
#   [OPERATOR_GITHUB]          — GitHub handle (optional)
#   [OPERATOR_HOMEDIR_PATH]    — $HOME at workspace-setup time
#   [CLAUDE_WORKSPACE_ROOT]    — Claude workspace root path (settings.json.template)
#   [COWORK_INSTALL_PATH_BASE] — Cowork install dir (depersonalization-spec.md §3.1)
#   [OPERATOR_PROJECT_NAME]    — Active PMO project name. Retained in the active set
#                                deliberately: no template body consumes it since
#                                ADR-122 de-tokenized its one illustrative use, but
#                                dropping it here would change install prompting,
#                                which is a separate decision from this one.
