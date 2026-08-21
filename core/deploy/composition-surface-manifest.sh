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
#                                              (ADR-122; suffix-stripping)
#                           "operations-root" → <operations-base>/<basename minus trailing .template>
#                                              (the operations-workspace context
#                                               anchor; <operations-base> resolved
#                                               by lib_compose_resolve_target via
#                                               the lib-instance-path.sh resolver,
#                                               same as <instance-base>. Suffix-
#                                               stripping, and deliberately does
#                                               NOT consume <instance-base>.)
#   <tokens-flag>           "tokens"    → substitute [OPERATOR_*] / [CLAUDE_*] tokens at write
#                           "raw"       → install verbatim (no substitution)
#   <marker-dialect>        OPTIONAL 4th field (ADR-122).
#                           "plain"     → comment-prefixed fence (# === BEGIN … ===)
#                           "markdown"  → HTML-comment fence (<!-- === BEGIN … === -->)
#                           ABSENT      → "plain". awk -F'|' '{print $4}' on a 3-field row
#                                         returns empty, so every pre-ADR-122 row keeps its
#                                         exact prior behavior with no rewrite.
#
# Adding a new composition-surface file: append one row — AND update the
# self-declared "<N> composition-surface" count below, which an enforcing QA check
# asserts against the actual row count (core/deploy/qa/checks.py R1). A membership
# change that leaves the numeral behind turns that check red.
#
# Adding a new TIER costs more than a row: the resolver needs a `case` arm
# (core/deploy/lib-composition.sh lib_compose_resolve_target), the install
# validator needs a matching arm in check_a3b_composition_surface — whose tier
# `case` falls through `*) continue ;;`, so an unhandled tier is verified by
# nothing — and any tier-literal branch downstream of resolution needs widening
# (update.sh's out-of-fence discard notice is one).
#
# The rule this generalizes: enumerate every reader of a manifest-DERIVED value —
# a row, a tier name, the cardinality — not every reader of the manifest. A
# consumer that regex-parses this file or branches on a tier name never appears in
# a sourcing-graph sweep. See core/standards/composition-surface-spec.md §5.
#
# IMPORTANT — bash 3.2 array scope:
# This file uses PLAIN ASSIGNMENT (no `declare -a`) on purpose. Under bash 3.2
# (the macOS system bash), `declare -a` inside a function — or inside a script
# sourced from a function — makes the array function-local; the caller never
# sees it. The lib_compose_source_manifest helper IS a function, so any
# `declare -a` here would silently break all 21 composition-surface installs.
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
  # hook tier is load-bearing here, not incidental. block-fragile-refs fails CLOSED when
  # this surface is unreachable, so the hook must never be installed ahead of it.
  #
  # On the UPDATE path that is enforced: update.sh orders regenerate -> assert_install_complete
  # -> refresh_hooks, and the assert covers hook-tier rows only, so a missing surface aborts
  # the run before any hook is refreshed. Demoting this row to `instance` would silently
  # re-open that window, because the assert would stop covering it. That is the reason for
  # the tier, and it has been observed working: a run against a workspace missing this
  # surface refused at the assert and left the old hook in place.
  #
  # It is NOT enforced on the INSTALL path. setup-workspace.sh's rebootstrap orders
  # install_hooks BEFORE install_composition_surface_files, with no assert between them, so
  # the fail-closed hook lands first and the surface follows. That window is bounded and
  # low-consequence — both writes happen in one run, PreToolUse hooks gate agent tool calls
  # rather than the installer's own file operations, and a durable hook snapshot is taken
  # immediately before — but it is a window, and the two installers ordering the same pair
  # oppositely is worth knowing before anyone relies on the update-path guarantee generally.
  "core/config/allowlists/reference-durability-allowlist.txt|hook|raw"
  "core/config/allowlists/skip-localized-context-check.txt|hook|raw"
  "core/config/allowlists/skip-release-note-check.txt|hook|raw"

  # Instance-tier (operator-scoped, <instance-base>/<basename>)
  # Token-free — operator extends per-instance over time
  "core/config/allowlists/skill-editor-exemption-list.txt|instance|raw"
  "core/config/allowlists/skip-doc-link-check.txt|instance|raw"
  "core/config/allowlists/agents-model-overrides.txt|instance|raw"
  "core/config/allowlists/status-label-invariant-exemption-list.txt|instance|raw"
  # NOTE — core/config/platform-config.toml.template is deliberately NOT
  # registered here. It is a Universal file: every reader resolves it in place
  # from the clone (repo-relative or ${HOOK_DIR}-relative), so an installed
  # instance-tier copy had zero readers while shipping an empty OPERATOR
  # ADDITIONS fence that invited edits taking no effect. The operator's own
  # values live at the XDG individual rung
  # (${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/platform-config.toml),
  # which is Operator-instance and is never written or regenerated by the
  # package. A row here must name a target some reader resolves; see
  # core/standards/composition-surface-spec.md §1.2.

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

  # Operations-root tier (<operations-base>/CLAUDE.md). The operations-workspace
  # context anchor: a POINTER-ONLY file naming the platform governance an
  # operations-rooted session loads, restating none of it. Like the workspace-root
  # row it strips the trailing `.template`, so this row targets
  # <operations-base>/CLAUDE.md — NOT <operations-base>/CLAUDE.md.template.
  #
  # Token-free (`raw`): the anchor names paths, never operator identity, so there
  # is nothing to substitute and nothing that can survive unresolved into the
  # composed file.
  #
  # `markdown` dialect — the HTML-comment fence per
  # composition-surface-spec.md §2.2, matching the workspace-root row above.
  #
  # The installer is the ONLY writer, and that is a property rather than a
  # constraint: the autonomy-ceiling control blocks Write/Edit to any */CLAUDE.md
  # basename, so no agent can hand-edit the installed anchor. The
  # reference-never-restate invariant is held by a control, not by discipline.
  "operations/CLAUDE.md.template|operations-root|raw|markdown"
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
