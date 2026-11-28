#!/usr/bin/env bash
# lib-instance-path.sh — single resolver for the operator-instance directory, the
# operations-workspace root, the localized-context needle file, the people-roster
# file, the evals-results directory (home of the pipeline event log), the
# three ambient-intake member directories (inbox drop-zone, Path-A intake-sweep
# run-log dir, Path-B external-sync dir), the skill-editor exemption list, the
# set of instance-tier files a deployed security hook reads, the main
# checkout's working-state telemetry folder (home of the per-release cost rows),
# and the main checkout's analysis workspace (home of read-once analysis reports);
# and, beside them, the three CLASS RESOLVERS the instance-data placement standard
# defines — working state per repository (pmo_working_state_path[_for]), working
# state install-scoped (pmo_install_state_path_for) and leak-risk
# (pmo_leak_risk_path[_for]) — with the per-repository switch they sit behind
# (operator.toml [adapters] governed_homes, which ships off), the run-class argument
# release runs take, and the designated-main-checkout rule. The class-resolver
# contract is recorded in {{ADR:class-homes-switch-and-designation}} and stated in
# full at the head of the class-resolver section at the end of this file.
#
# Design rationale (applies existing ADRs — NO standalone ADR):
#   - The default base CANONICALIZES on the ADR-032 idiom
#     `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}`, NOT on PMO_INSTANCE_PATH (per
#     ADR-032 (Accepted) § "Canonicalization note — CLAUDE_WORKSPACE_ROOT, not
#     PMO_INSTANCE_PATH" + "invent no new variable"). No new variable is invented
#     here; PMO_INSTANCE_PATH, PMO_LOCALIZED_NEEDLES, PMO_PEOPLE_ROSTER, and
#     WORKSPACE_ROOT are honored ONLY as pre-existing / direct-path back-compat
#     overrides. WORKSPACE_ROOT is the fourth and newest member of that list and
#     the only one scoped to a SINGLE function (pmo_evals_results_path): it is a
#     pre-existing release-tools convention, documented as an operator override
#     at release/tools/cleanup-orphan-state.sh and honored by the pipeline-event
#     writer, so the reader honors it for writer-parity — not because a new
#     variable was minted here.
#   - This is the one resolution site for the instance/needle/roster path surface,
#     and for every member the class resolvers serve.
#     deploy.sh, the PII pre-commit hook, lib-composition.sh, the composition
#     manifest, check-canonical-structure.sh, extract-roster-needles.sh, and the
#     install/update/setup scripts source this lib and call the functions instead
#     of inlining `${PMO_INSTANCE_PATH:-.../pmo-instance}` (ADR-017 §
#     operator-instance surface convergence — collapse the inconsistent literals
#     into one resolver).
#
# Resolution (highest precedence first):
#   pmo_instance_path()      → ${PMO_INSTANCE_PATH:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/pmo-instance}
#   pmo_operations_path_for()→ <workspace-root>/projects
#                              (1 tier — no env or config tier; see the function)
#   pmo_localized_needles()  → ${PMO_LOCALIZED_NEEDLES:-$(pmo_instance_path)/localized-context-needles.txt}
#   pmo_people_roster()      → ${PMO_PEOPLE_ROSTER:-$(pmo_instance_path)/people-roster.yaml}
#   pmo_skill_editor_exemption_list()
#                            → $(pmo_instance_path)/skill-editor-exemption-list.txt
#   pmo_skill_editor_exemption_list_for()
#                            → $(pmo_instance_path_for <workspace-root>)/skill-editor-exemption-list.txt
#   pmo_hook_read_instance_files_for()
#                            → the instance-tier files a deployed hook reads, one
#                              absolute path per line (derived; see the function)
#   pmo_evals_results_path() → pmo_working_state_path event-log [<options>] — the
#                              event-log member's public name, kept. With the
#                              switch off its answer is the today arm below
#                              (_pmo_today_event_log), byte-identical to the body
#                              this function had: $EVALS_RESULTS_PATH, else the
#                              operator.toml key
#                              operator_instance_evals_results_path, else
#                              <workspace-root>/pmo-instance/evals/results
#                              where <workspace-root> is itself a four-step
#                              cascade: $WORKSPACE_ROOT, else
#                              $CLAUDE_WORKSPACE_ROOT, else the operator.toml key
#                              claude_workspace_root, else $HOME/Claude
#                              (3 tiers — deliberately NOT expressible as one
#                              ${VAR:-default} expansion like the three above)
#   pmo_telemetry_path_for() → the operator.toml key
#                              operator_instance_working_state_telemetry_path, else
#                              <workspace-root>/pmo-platform/local-state/telemetry
#                              (2 tiers — no env tier; see the function)
#   pmo_analysis_path_for()  → the operator.toml key
#                              operator_instance_analysis_path, else
#                              <workspace-root>/pmo-platform/analysis
#                              (2 tiers — no env tier; see the function)
#   pmo_working_state_path_for <root> <member> [--repo <checkout>]
#                              [--run-class working-state|leak-risk] [--home today|governed]
#   pmo_working_state_path     <member> [the same options]
#                            → working state per repository; with the switch off,
#                              each member's today arm (the member table in the
#                              class-resolver section), else <D>/local-state/<sub>
#   pmo_install_state_path_for <root> <member> [--home today|governed]
#                            → working state install-scoped; else
#                              ${XDG_STATE_HOME:-$HOME/.local/state}/pmo-platform/telemetry
#   pmo_leak_risk_path_for <root> <member> [--home today|governed]
#   pmo_leak_risk_path     <member> [--home today|governed]
#                            → leak-risk; else
#                              ${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private[/<leaf>]
#   pmo_main_checkout_for <root> [<checkout>]
#                            → the designated main checkout (the designation rule)
#   pmo_governed_homes_for <root> [<checkout>]
#                            → on | off for that checkout's repository
#
# Honored-tier contract, per function — stated because "which variables and which
# operator.toml keys does this function honor, and which does it deliberately
# ignore" is the question every converging consumer must answer before it can
# safely stop resolving the path itself:
#   pmo_instance_path()       env: PMO_INSTANCE_PATH, CLAUDE_WORKSPACE_ROOT · toml: none
#   pmo_instance_path_legacy() env: PMO_INSTANCE_PATH, CLAUDE_WORKSPACE_ROOT · toml: none
#                             (migration probe only — see its block below)
#   pmo_instance_path_for()   env: PMO_INSTANCE_PATH                        · toml: none
#   pmo_operations_path_for() env: none                                     · toml: none
#   pmo_localized_needles()   env: PMO_LOCALIZED_NEEDLES (+ pmo_instance_path's)
#   pmo_people_roster*()      env: PMO_PEOPLE_ROSTER     (+ pmo_instance_path's)
#   pmo_skill_editor_exemption_list()
#                             env: PMO_INSTANCE_PATH, CLAUDE_WORKSPACE_ROOT · toml: none
#   pmo_skill_editor_exemption_list_for()
#                             env: PMO_INSTANCE_PATH                        · toml: none
#   pmo_hook_read_instance_files_for()
#                             derived: each member's own resolver (today one member,
#                             the _for form above)
#   pmo_evals_results_path()  env: EVALS_RESULTS_PATH, WORKSPACE_ROOT,
#                                  CLAUDE_WORKSPACE_ROOT
#                             toml: operator_instance_evals_results_path,
#                                   claude_workspace_root
#                             NOT honored: PMO_INSTANCE_PATH (see its block below)
#   pmo_<ambient-member>_path_for() toml: the member's own key (+ pmo_instance_path_for's env)
#   pmo_inbox_path_for()           → operator.toml operator_instance_inbox_path,
#                                    else $(pmo_instance_path_for <root>)/inbox
#   pmo_ambient_intake_path_for()  → dirname of operator.toml
#                                    operator_instance_intake_sweep_runlog_path,
#                                    else $(pmo_instance_path_for <root>)/ambient-intake
#   pmo_external_sync_path_for()   → dirname of operator.toml
#                                    operator_instance_external_sync_snapshot_path
#                                    (else its run-log sibling), else
#                                    $(pmo_instance_path_for <root>)/external-sync
#                              (2 declared tiers each — see the block above them
#                              for why there is no env tier)
#   pmo_telemetry_path_for()  env: none
#                             toml: operator_instance_working_state_telemetry_path
#                             NOT honored: PMO_INSTANCE_PATH (the folder is not under
#                             the instance container) or CLAUDE_WORKSPACE_ROOT (the
#                             workspace root is the argument)
#   pmo_analysis_path_for()   env: none
#                             toml: operator_instance_analysis_path
#                             NOT honored: PMO_INSTANCE_PATH or CLAUDE_WORKSPACE_ROOT,
#                             for the telemetry resolver's two reasons
#   the class resolvers       today arm: exactly the rungs each member's today
#                             expression honors (the member table), read through
#                             $HOME/.config/pmo-platform/operator.toml as today
#                             switch and governed arm: every key read through the
#                             config root, ${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}
#                             designation: PMO_SRC_ROOT, CLAUDE_WORKSPACE_ROOT and the
#                             config root's claude_workspace_root and pmo_platform_repo_name
#                             per-user homes: XDG_DATA_HOME, XDG_STATE_HOME (an empty or
#                             relative value is ignored, as the XDG convention treats one)
#                             REFUSED under the governed arm: the family-wide relocations
#                             a member's today arm honors (PMO_INSTANCE_PATH;
#                             WORKSPACE_ROOT for the no-argument event-log form)
#
# Exemption-surface resolution contract. The skill-editor exemption list is the escape
# half of the Gate 2 skill-edit hook. The composition manifest registers it at the
# `instance` tier, and every consumer resolves it through the pair above, so no
# consumer spells its path. Who resolves it, in which role, from which root:
#
#   Actor                                  Role                    Root
#   setup-workspace.sh (the manifest row,  seed writer             its workspace root, through the
#     lib_compose_resolve_target's                                 instance tier (pmo_instance_path_for)
#     instance arm)
#   update.sh Phase 3, the Phase 5b0       managed-section writer; its workspace root; gate membership
#     completeness gate and the Phase 5c1  completeness; reader    through pmo_hook_read_instance_files_for
#     legacy reconcile                     (legacy reconcile)
#   core/hooks/allowlist-add.sh            operator-additions      $CLAUDE_WORKSPACE_ROOT, else the
#                                          writer                  workspace it is deployed into;
#                                                                  compared physically
#   core/hooks/block-skill-direct-edit.sh  reader (Gate 2)         the same root, resolved in isolation:
#                                                                  a missing or broken resolver grants
#                                                                  no exemption
#   deploy.sh Checks 6 and 10;             readers                 the no-argument form ($CLAUDE_WORKSPACE_ROOT,
#     check-canonical-structure.sh                                 else $HOME/Claude); no fallback path
#     (and its CI mirror)
#   core/hooks/tests/setup-ci-layout.sh;   fixture writers         pmo_hook_read_instance_files_for <layout
#     the Linux install leg                                        root>, PMO_INSTANCE_PATH unset
#
# One resolver is not yet one resolved path everywhere: the deploy-side readers root at
# the ambient default, so on an install whose workspace root is neither $HOME/Claude nor
# exported as CLAUDE_WORKSPACE_ROOT they read another copy than the hook does; and a
# PMO_INSTANCE_PATH exported to the shell that runs install and update but not to the
# Claude Code process splits the writer and the hook the same way. Both residuals are
# recorded with the decision. A consumer added to this surface is added to this table.
#
# All are pure stdout-echoing functions (no side effects, no mutation); safe to
# call under `set -euo pipefail`. Sourceable AND idempotent: re-sourcing is a
# no-op (the function definitions are simply re-declared). The class resolvers
# are pure too, and are the only functions here that can fail: they return 2 for
# a usage error and 3 for a refusal, with stdout empty and one stderr line, so a
# caller captures the value and checks the status at its own outermost assignment
# — never `local x="$(…)"` and never `"$(…)/leaf"`, which swallow the failure.
#
# Bash version: 3.2.57-safe (no associative arrays, no bash-5 substring tricks).

# Echo the operator-instance base directory (no trailing slash).
pmo_instance_path() {
  printf '%s\n' "${PMO_INSTANCE_PATH:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/pmo-instance}"
}

# Echo the LEGACY (pre-relocation) operator-instance base directory — the home
# this family occupied before it became a workspace-root sibling.
#
# WHY THIS EXISTS, AND WHY IT IS HERE RATHER THAN AT ITS ONE CALLER. The PII
# pre-commit guard must be able to tell an un-migrated instance from a fresh
# clone, and those two states differ ONLY by whether the legacy home is still on
# disk. Its caller therefore needs a value the current resolver, by construction,
# no longer returns. Spelling that value at the call site would put a second live
# instance-leaf literal back into core/hooks/ — the exact thing this file exists
# to prevent (AC1 / AC5), and inside the path-leak detector's gating scan corpus
# at that. One named function keeps the leaf single-homed and hands the follow-on
# cleanup a greppable removal target instead of a hunt.
#
# DELIBERATELY THE SAME OVERRIDE SHAPE as pmo_instance_path() above, not a bare
# literal. When PMO_INSTANCE_PATH is set the operator has named their home
# explicitly, both functions return that one path, and the migration-detection
# predicate at the caller collapses to "the home you named is missing" — i.e. the
# legacy branch is unreachable and the pre-existing behaviour stands. That
# inertness under an explicit override is a property worth having rather than an
# accident: this function is a MIGRATION probe, and there is no migration to
# detect on an instance that was never on the default path.
#
# REMOVAL: this function and its single caller retire together once the legacy
# home is no longer expected on any instance.
pmo_instance_path_legacy() {
  printf '%s\n' "${PMO_INSTANCE_PATH:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance}"
}

# Echo the operator-instance base directory relative to an EXPLICIT workspace
# root (no trailing slash). For callers that already hold a workspace root and
# must keep it (e.g. lib-composition.sh, which sandboxes installs/tests via a
# passed --workspace-root and therefore cannot fall back to the $HOME-based
# default). PMO_INSTANCE_PATH still wins when set; otherwise the leaf is appended
# to the given base. Centralizing the `pmo-instance` leaf here keeps it
# out of every other *.sh (AC1 / AC5).
# Usage: pmo_instance_path_for <workspace-root>
pmo_instance_path_for() {
  local _base="$1"
  printf '%s\n' "${PMO_INSTANCE_PATH:-${_base}/pmo-instance}"
}

# Echo the operations-workspace root relative to an EXPLICIT workspace root (no
# trailing slash) — the sibling of pmo_instance_path_for for the OTHER operator
# sibling directory. Callers: lib-composition.sh's `operations-root` tier arm and
# the installer's parent pre-create for it.
#
# WHY THIS EXISTS: the composition resolver's own contract states that an
# operator-directory leaf literal lives only in the resolver (ADR-017 §
# operator-instance surface convergence). Adding an `operations-root` tier that
# spelled `projects` inline would have put a second such literal back into the one
# file that convergence cleaned. Centralizing the leaf here keeps that contract
# true and hands a future relocation of the operations sibling ONE call site to
# re-point instead of a hunt across the installer, the resolver and the validator.
#
# NO env tier and NO operator.toml tier — deliberately, and this is where the
# shape departs from pmo_instance_path_for above. That function honors
# PMO_INSTANCE_PATH only because the variable pre-dates it; ADR-032 § "invent no
# new variable" forbids minting a PMO_OPERATIONS_PATH to fill the symmetry, and no
# operations-workspace path token exists in the closed [OPERATOR_*] vocabulary
# (core/standards/depersonalization-spec.md §1) for a config tier to read. A
# relocation that needs one registers the token first; this function is then the
# single site that grows a tier, and every caller inherits it unchanged.
# Usage: pmo_operations_path_for <workspace-root>
pmo_operations_path_for() {
  local _base="$1"
  printf '%s\n' "${_base}/projects"
}

# Echo the absolute path to the localized-context needle file. The body lives in
# _pmo_today_needles, the leak-risk class resolver's today arm for member
# `needles`, so a later switch-aware accessor can call the class resolver without
# that resolver's today arm calling back into the accessor. Byte-identical today.
_pmo_today_needles() {
  printf '%s\n' "${PMO_LOCALIZED_NEEDLES:-$(pmo_instance_path)/localized-context-needles.txt}"
}
pmo_localized_needles() { _pmo_today_needles; }

# Echo the absolute path to the operator-instance people-roster file. Mirrors
# pmo_localized_needles() exactly: a direct-path override (PMO_PEOPLE_ROSTER)
# wins; otherwise the leaf is appended to the $HOME-based instance default. The
# filled roster is operator-instance, out-of-tree, gitignored, and PII-bearing
# once filled — the install/update/setup seed and extract-roster-needles.sh all
# resolve it through here so the literal lives in exactly one place (ADR-017).
# The body lives in _pmo_today_roster (the leak-risk class resolver's today arm
# for member `roster`), for the reason _pmo_today_needles does.
_pmo_today_roster() {
  printf '%s\n' "${PMO_PEOPLE_ROSTER:-$(pmo_instance_path)/people-roster.yaml}"
}
pmo_people_roster() { _pmo_today_roster; }

# Echo the absolute path to the people-roster file relative to an EXPLICIT
# workspace root. The workspace-root analogue of pmo_people_roster(), for callers
# that already hold a workspace root and must keep it (the sandboxed
# --workspace-root install/update path, which cannot fall back to the $HOME
# default). PMO_PEOPLE_ROSTER still wins when set; otherwise the leaf is appended
# to pmo_instance_path_for <workspace-root>. Mirrors the pmo_instance_path /
# pmo_instance_path_for pairing.
# Usage: pmo_people_roster_for <workspace-root>
_pmo_today_roster_for() {
  local _base="$1"
  printf '%s\n' "${PMO_PEOPLE_ROSTER:-$(pmo_instance_path_for "${_base}")/people-roster.yaml}"
}
pmo_people_roster_for() { _pmo_today_roster_for "$@"; }

# Echo the absolute path to the skill-editor exemption list — the escape half of the
# Gate 2 skill-edit hook (block-skill-direct-edit.sh), registered at the instance tier
# by the composition manifest. This pair is the list's ONE resolution site: the hook,
# the writer (allowlist-add.sh), update.sh and the deploy-time readers call it, and the
# installer's seed lands on the same path through the manifest's instance tier (the
# contract table in the header). No direct-path variable: a second variable would be a
# second answer, which is the divergence this pair exists to close (ADR-032, "invent no
# new variable").
pmo_skill_editor_exemption_list() {
  printf '%s\n' "$(pmo_instance_path)/skill-editor-exemption-list.txt"
}

# The explicit-root form, for callers that hold a workspace root and must keep it: the
# hook and the writer (rooted at the workspace they are deployed into), the update and
# install flows, and the test fixtures. Mirrors the pmo_people_roster pairing.
# Usage: pmo_skill_editor_exemption_list_for <workspace-root>
pmo_skill_editor_exemption_list_for() {
  printf '%s\n' "$(pmo_instance_path_for "$1")/skill-editor-exemption-list.txt"
}

# Echo the instance-tier composition surfaces a deployed security hook reads, one
# absolute path per line. Each is the escape half of a hook control whose enforcement
# half update.sh's hook refresh installs, so the update-time completeness gate covers
# it exactly as it covers a hook-tier allowlist, and the CI hook layout and the Linux
# install leg materialize the same set. The other instance-tier surfaces are escape
# halves of deploy-time checks, with no hook refresh to guard, and stay out.
# A new hook-read instance surface is declared HERE, and only here.
# Usage: pmo_hook_read_instance_files_for <workspace-root>
pmo_hook_read_instance_files_for() {
  pmo_skill_editor_exemption_list_for "$1"
}

# Echo the absolute path to the operator-instance evals-results directory (no
# trailing slash) — the home of the pipeline event log and its write-log.
#
# pmo_evals_results_path is the event-log member's PUBLIC NAME, kept so its writer
# and every reader follow the switch together with no rename and no re-point. The
# resolution site is now the working-state class resolver (member event-log), and
# the switch-off arm is _pmo_today_event_log below — this function's former body,
# moved byte-for-byte. The rest of this block describes that today arm.
#
# Three-tier resolution. The today arm is the SINGLE resolution site for the path
# — release/tools/append-pipeline-event.sh (the WRITER of those files) and
# release/tools/query-pipeline-event.sh (its reader) both call it rather than
# resolving independently, so a reader cannot resolve somewhere the writer does
# not write:
#   1. $EVALS_RESULTS_PATH                                     (env / direct override)
#   2. operator.toml  operator_instance_evals_results_path      (instance override)
#   3. <workspace-root>/pmo-instance/evals/results, where <workspace-root>
#      is a four-step cascade in its own right:
#        3a. $WORKSPACE_ROOT               (pre-existing release-tools convention)
#        3b. $CLAUDE_WORKSPACE_ROOT        (the ADR-032 canonical variable)
#        3c. operator.toml  claude_workspace_root
#        3d. $HOME/Claude                  (canonical default)
#
# HISTORY — why rung 3 is spelled out rather than summarized. This header used to
# assert that the function "mirrors" the writer "so a reader can never resolve
# somewhere the writer does not write." It did not mirror it: rung 3's base was a
# two-step fallback ($CLAUDE_WORKSPACE_ROOT, else $HOME/Claude) against the
# writer's four, so on an instance setting either $WORKSPACE_ROOT or the
# claude_workspace_root key, this reader resolved to a directory the writer never
# wrote to — and deploy.sh Check 19 and the decision-emission gate, the two
# consumers that read through here, looked there and found nothing. The invariant
# is now held by convergence rather than by duplication: there is one resolution
# site, so parity is structural. The enforcement point against a FUTURE narrowing
# of rung 3 is the value-assertion group "evals-results workspace-root cascade" in
# core/deploy/tests/test_instance_path_roundtrip.sh, which pins each rung's
# resolved value against a literal expectation rather than against another
# resolver — a parity assertion between two sites that now share one function
# cannot fail, and would be theater.
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
_pmo_today_event_log() {
  local _erp="${EVALS_RESULTS_PATH:-}"
  local _base=""
  # Rungs 1-2. The toml read goes through _pmo_instance_toml_key rather than an
  # inline `grep | head -1 | awk`: same value, and it drops the SIGPIPE hazard
  # that reader documents in its own header (a successful key read reporting
  # failure to a `set -e` caller).
  [[ -n "$_erp" ]] || _erp="$(_pmo_instance_toml_key "operator_instance_evals_results_path")"
  if [[ -n "$_erp" ]]; then printf '%s\n' "$_erp"; return 0; fi
  # Rung 3 — the four-step workspace-root cascade (3a..3d in the header above).
  _base="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}"
  [[ -n "$_base" ]] || _base="$(_pmo_instance_toml_key "claude_workspace_root")"
  printf '%s\n' "${_base:-$HOME/Claude}/pmo-instance/evals/results"
}

# The event-log member's public name (retained; see the class resolvers below).
# Every option the working-state resolver takes passes through, so the writer and
# its readers adopt --repo by adding the argument.
pmo_evals_results_path() { pmo_working_state_path event-log "$@"; }

# --- Ambient-intake member directories -------------------------------------
#
# The three directories the ambient-intake capability runs on. Each is already
# a registered operator-instance path token with a declared operator.toml
# override field (core/standards/depersonalization-spec.md §4); until now none
# of them had a resolver, so nothing could resolve them programmatically and the
# installer provisioned none of them. These close that gap and are the single
# resolution site for all three — the installer, the update path, the install
# validator, and the end-to-end regression all call them instead of inlining a
# leaf (ADR-017 § operator-instance surface convergence).
#
# Resolving rather than inlining is what makes provisioning survive a relocation
# of the operator-instance family: whichever lands first, the relocation and this
# provisioning agree, because both read the same resolver.
#
# TWO declared tiers, not three — deliberately, and this is the one place the
# shape departs from pmo_evals_results_path() above:
#   1. the operator.toml override key the token declares
#   2. <pmo_instance_path_for "<workspace-root>">/<leaf>
# The evals resolver carries a third, env-variable tier because its WRITER
# already honored $EVALS_RESULTS_PATH — a resolver that ignored it would read
# where the writer does not write. No such variable exists for these three, and
# ADR-032 § "invent no new variable" forbids minting one to fill a symmetry that
# buys nothing. PMO_INSTANCE_PATH still relocates all three, because
# pmo_instance_path_for honors it — so an env-tier relocation is available, one
# level up, through the mechanism that already owns it.
#
# Each returns the DIRECTORY. Two of the four registered tokens name a FILE
# inside one of these directories (the external-sync snapshot and its run-log,
# and the intake-sweep run-log); the file leaf stays the consumer's concern,
# exactly as pmo_evals_results_path() returns the results directory rather than
# the event log inside it.
#
# Usage: pmo_<member>_path_for <workspace-root>

# Private. Read one key from the canonical operator.toml, else empty. This is THE
# operator.toml reader for this file — the three ambient resolvers, the
# telemetry resolver and the analysis resolver below, the event-log today arm
# above, and the class resolvers at the end of the file (the switch and every
# governed-arm key through the optional second argument, the config-root file),
# all call it, so
# there is one canonical XDG
# location, one `|| true` tolerance for an absent key under `set -euo pipefail`,
# and one first-match-wins rule rather than a copy per consumer. A fourth ambient
# member costs one more one-line public function and no new logic.
#
# HISTORY: this header used to describe the relationship to pmo_evals_results_path()
# as "mirrors its read, with ONE deliberate departure" — accurate while that
# function carried its own inline `grep | head -1 | awk`. It no longer does: it
# calls this reader, so the relationship is caller-callee and there is no second
# reader to mirror or depart from. The `-m1` rationale below is retained unchanged
# because it is the reason THIS reader is written the way it is, and it is now the
# only form in the file.
#
# WHY `grep -m1` AND NOT `grep | head -1`: first-match-wins is
# taken with `grep -m1` rather than by piping an unbounded grep into `head -1`.
# The two are equivalent on the value returned and differ on the exit status. In
# the `| head -1` form the reader closes the pipe at its first line while the
# writer still has output to push; the writer's next write then fails on the
# broken pipe, and under `pipefail` that failure becomes the pipeline's status —
# so a SUCCESSFUL key read can report failure to a `set -e` caller. Where SIGPIPE
# is fatal that surfaces as 141; where the shell inherited it as SIG_IGN (what a
# GitHub-hosted runner hands a workflow step) it surfaces as a bare 1,
# indistinguishable from the key legitimately being absent. `-m1` removes the
# short-circuiting reader entirely: grep reads a FILE, stops itself at one match,
# and awk consumes to EOF, so no writer is ever signalled.
_pmo_instance_toml_key() {
  local _toml="${2:-${HOME}/.config/pmo-platform/operator.toml}"
  [[ -r "$_toml" ]] || return 0
  { grep -m1 -E "^$1" "$_toml" 2>/dev/null || true; } \
    | awk -F= '{gsub(/[" ]/,"",$2); print $2}'
}

# Private. Resolve one instance-member directory: operator.toml override key,
# else the leaf appended to the instance base for the given workspace root.
# Usage: _pmo_instance_member_path <workspace-root> <toml-key> <leaf>
_pmo_instance_member_path() {
  local _root="$1" _key="$2" _leaf="$3" _val
  _val="$(_pmo_instance_toml_key "$_key")"
  printf '%s\n' "${_val:-$(pmo_instance_path_for "${_root}")/${_leaf}}"
}

# Echo the ambient inbox drop-zone (no trailing slash) —
# <OPERATOR_INSTANCE_INBOX_PATH>. Transcripts and emails land here for ambient
# ingest; the dedup cursor lives inside it and is still created lazily on first
# ingest, not provisioned.
pmo_inbox_path_for() {
  _pmo_instance_member_path "$1" "operator_instance_inbox_path" "inbox"
}

# Echo the Path-A intake-sweep run-log directory (no trailing slash) — the
# parent of <OPERATOR_INSTANCE_INTAKE_SWEEP_RUNLOG_PATH>. The override key names
# the run-log FILE, so its directory part is what a provisioning caller needs;
# when the key is set, its value is the directory the caller resolved it to.
pmo_ambient_intake_path_for() {
  local _root="$1" _val
  _val="$(_pmo_instance_toml_key "operator_instance_intake_sweep_runlog_path")"
  if [[ -n "$_val" ]]; then printf '%s\n' "$(dirname "$_val")"; return 0; fi
  printf '%s\n' "$(pmo_instance_path_for "${_root}")/ambient-intake"
}

# Echo the Path-B external-sync directory (no trailing slash) — the parent of
# <OPERATOR_INSTANCE_EXTERNAL_SYNC_SNAPSHOT_PATH> and of its sibling run-log.
# Same file-vs-directory reasoning as pmo_ambient_intake_path_for; the snapshot
# key is read first because it is the token C3 §3 declares as the primary
# artifact, with the run-log key as its sibling under the same directory.
pmo_external_sync_path_for() {
  local _root="$1" _val
  _val="$(_pmo_instance_toml_key "operator_instance_external_sync_snapshot_path")"
  if [[ -z "$_val" ]]; then
    _val="$(_pmo_instance_toml_key "operator_instance_external_sync_runlog_path")"
  fi
  if [[ -n "$_val" ]]; then printf '%s\n' "$(dirname "$_val")"; return 0; fi
  printf '%s\n' "$(pmo_instance_path_for "${_root}")/external-sync"
}

# --- Working-state telemetry folder (in-repo, main checkout) ----------------
#
# Echo the folder (no trailing slash) that holds the platform repository's derived
# working-state telemetry — <OPERATOR_INSTANCE_WORKING_STATE_TELEMETRY_PATH>. Its one
# record today is the per-release cost row, release-cost/<slug>.json, which the
# release-velocity tool's cost-row mode writes.
#
# WHY AN IN-REPO HOME AND NOT THE INSTANCE CONTAINER. The instance-data placement
# standard (core/standards/instance-data-placement-standard.md) homes a repository's
# working state in its main checkout's /local-state/, and its admission test admits a
# row derived from install-scoped usage data when the row concerns only that
# repository's own releases. The usage store the rows are computed from is
# install-scoped and stays outside every repository; only the derived rows live here.
#
# WHY THE WORKSPACE ROOT'S CHECKOUT AND NOT THE CALLER'S. A caller in a session
# worktree must not resolve to that worktree: an ignored row there is lost when the
# worktree is removed, or it keeps the worktree in use for good. The default therefore
# anchors on <workspace-root>/pmo-platform, the main checkout, as the analysis and
# roadmaps homes do.
#
# NO WRITER DEFAULTS TO IT. The placement standard admits no session write into the
# main checkout's /local-state/ until /local-state/ joins the main-checkout carve-out
# hook's static set, so the cost-row mode keeps its folder an explicit --out-dir and
# does not call this function. A default wired before that change would make the
# prohibited write the default.
#
# TWO declared tiers and no env tier: the operator.toml override key the token
# declares, else the in-repo default. ADR-032 § "invent no new variable" forbids
# minting a variable for it. PMO_INSTANCE_PATH does not relocate it, because the
# folder is not under the instance container, and CLAUDE_WORKSPACE_ROOT does not
# displace the argument.
#
# A pure function: it creates nothing. A home is provisioned by the installer, never
# by its first writer.
# Usage: pmo_telemetry_path_for <workspace-root>
pmo_telemetry_path_for() {
  local _root="$1" _val
  _val="$(_pmo_instance_toml_key "operator_instance_working_state_telemetry_path")"
  printf '%s\n' "${_val:-${_root}/pmo-platform/local-state/telemetry}"
}

# --- Analysis workspace (in-repo, main checkout) -----------------------------
#
# Echo the analysis workspace (no trailing slash) — <OPERATOR_INSTANCE_ANALYSIS_PATH>,
# the home of read-once analysis reports, each in its own dated subfolder
# (core/standards/analysis-workspace-standard.md). Its first writer is the FinOps
# skill's command-template ranker, which writes one report folder per run.
#
# IN THE REPOSITORY BY DESIGN. The folder and its README are tracked and every
# report under it is git-ignored, so a report never reaches a commit while the home
# stays discoverable. It anchors on <workspace-root>/pmo-platform, the main checkout,
# for the reason the telemetry folder above does: a report written into a session
# worktree dies with that worktree. Unlike /local-state/, a session may write a
# subfolder here — the main-checkout carve-out admits /analysis/<sub>/ today.
#
# TWO declared tiers and no env tier: the operator.toml override key the token
# declares, else the in-repo default. PMO_INSTANCE_PATH does not relocate it and
# CLAUDE_WORKSPACE_ROOT does not displace the argument. A pure function: it creates
# nothing.
# Usage: pmo_analysis_path_for <workspace-root>
pmo_analysis_path_for() {
  local _root="$1" _val
  _val="$(_pmo_instance_toml_key "operator_instance_analysis_path")"
  printf '%s\n' "${_val:-${_root}/pmo-platform/analysis}"
}

# --- Class resolvers (ADR-231 D5) ---------------------------------------------
#
# One resolver per served class, behind one per-repository switch, recorded in
# {{ADR:class-homes-switch-and-designation}}. This block is the contract the
# release tools and the later waves bind to.
#
#   pmo_working_state_path_for <root> <member> [--repo <checkout>] [--run-class working-state|leak-risk] [--home today|governed]
#   pmo_working_state_path     <member>        [--repo <checkout>] [--run-class working-state|leak-risk] [--home today|governed]
#   pmo_install_state_path_for <root> <member> [--home today|governed]
#   pmo_leak_risk_path_for     <root> <member> [--home today|governed]
#   pmo_leak_risk_path         <member>        [--home today|governed]
#   pmo_main_checkout_for      <root> [<checkout>]   the designated main checkout, or the
#                                                    context's own main worktree when off
#   pmo_governed_homes_for     <root> [<checkout>]   prints on | off
#   pmo_evals_results_path     [<options>]           = pmo_working_state_path event-log "$@"
#
# Options follow the positional arguments, in any order.
#
# RESERVED — a contract recorded here and in the decision record, implemented by the
# leak-risk migration card and NOT shipped in this file:
#   pmo_run_class_for <run-key> --repo <checkout>    prints leak-risk | working-state
#     leak-risk iff $LR/embargoed/.runs/<run-key> exists; working-state iff only
#     $(pmo_working_state_path release-runs --repo <checkout>)/<run-key> exists; exit 3
#     when neither record exists or both do. The record is keyed on the run key alone,
#     and the hub's start-of-run step writes exactly one. The D-ConfigRoot refusal
#     (below) applies to its $LR probe.
#
# MEMBERS. "Today" is the switch-off arm; "governed" is the arm the switch selects.
# <D> is the designated main checkout; $LR is the leak-risk home and $XS the XDG
# state base. "toml" reads $HOME/.config/pmo-platform/operator.toml (the today
# arm's reader, unchanged); "cfg" reads the config root's operator.toml (the
# switch's and the governed arm's reader).
#
#   class    member                  register         today, _for <root>                                   today, no-argument            governed                      governed-arm override      refused under governed   run-scoped
#   working  release-runs            S-01             toml operator_instance_hub_state_path › $(pmo_instance_path_for <root>)/hub-state   toml › $(pmo_instance_path)/hub-state   <D>/local-state/release-runs   cfg operator_instance_hub_state_path   PMO_INSTANCE_PATH   yes
#   working  release-runs-templates  S-02             $(pmo_instance_path_for <root>)/hub-state            — (exit 2)                    <D>/local-state/release-runs   none                       PMO_INSTANCE_PATH        no
#   working  event-log               S-03             toml operator_instance_evals_results_path › <root>/pmo-instance/evals/results   _pmo_today_event_log   <D>/local-state/event-log   EVALS_RESULTS_PATH, then cfg operator_instance_evals_results_path   WORKSPACE_ROOT (no-argument form only)   yes
#   working  registers               S-04             $(pmo_instance_path_for <root>)/releases/registers   $(pmo_instance_path)/releases/registers   <D>/local-state/registers   none            PMO_INSTANCE_PATH        yes
#   working  logs                    S-05, S-16       $(pmo_instance_path_for <root>)                      $(pmo_instance_path)          <D>/local-state/logs          none                       PMO_INSTANCE_PATH        no
#   working  allowlists              S-07             $(pmo_instance_path_for <root>)                      $(pmo_instance_path)          <D>/local-state/allowlists    none                       PMO_INSTANCE_PATH        no
#   working  telemetry               S-45             pmo_telemetry_path_for <root>                        — (exit 2)                    <D>/local-state/telemetry     cfg operator_instance_working_state_telemetry_path   none   no
#   working  analysis                S-20             pmo_analysis_path_for <root>                         — (exit 2)                    <D>/analysis                  cfg operator_instance_analysis_path   none   no
#   install  usage-store             S-06, S-38       toml operator_instance_finops_store_path › <root>/pmo-instance/finops   — (no such form)   $XS/pmo-platform/telemetry   cfg operator_instance_finops_store_path   none   —
#   leak     needles                 S-08             ${PMO_LOCALIZED_NEEDLES:-$(pmo_instance_path_for <root>)/localized-context-needles.txt}   _pmo_today_needles   $LR/localized-context-needles.txt   PMO_LOCALIZED_NEEDLES   PMO_INSTANCE_PATH   —
#   leak     roster                  S-09             _pmo_today_roster_for <root>                         _pmo_today_roster             $LR/people-roster.yaml        PMO_PEOPLE_ROSTER          PMO_INSTANCE_PATH        —
#   leak     home                    S-10, S-15, S-33 $(pmo_instance_path_for <root>)                      $(pmo_instance_path)          $LR                           none                       PMO_INSTANCE_PATH        —
#
#   $LR = ${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private
#   $XS = ${XDG_STATE_HOME:-$HOME/.local/state}
#   An XDG value that is empty or not absolute is ignored, as the XDG convention
#   treats one. The embargoed arm (--run-class leak-risk) is
#   $LR/embargoed/<repository>/<release-runs|event-log|registers>.
#   A member not in this table exits 2 and resolves to no home (the U5 near-miss).
#   Not served: S-11 to S-14, S-17, S-18, S-21, S-22, S-23, S-30, S-31, S-32 and
#   S-39, which keep resolving through the functions above, unchanged.
#
# THE SWITCH. operator.toml [adapters] governed_homes, read through the config root.
# Its value is a string of comma-separated repository names; each entry is trimmed,
# empty entries are dropped, and every entry must match ^[A-Za-z0-9][A-Za-z0-9._-]*$
# — any other entry exits 3 for every resolution that reads a non-empty switch, so a
# value can never compose a path outside the workspace root. A TOML array is not
# read: the reader's quote-stripping turns one into a bracketed word, which fails
# the grammar, loudly. An absent, empty or blank value is off for every repository,
# which is the shipped state: each repository's entry is added by that repository's
# cutover change, after its homes exist and its data is copied.
#
# WHICH REPOSITORY A CALL IS ABOUT. Working state follows --repo (an empty value
# exits 2). With no --repo, and always for the per-user classes, the context is the
# platform context, the first that holds of: PMO_SRC_ROOT; the git work tree holding
# this library at core/deploy/lib-instance-path.sh; <root>/<pmo_platform_repo_name,
# default pmo-platform>, the key read through the config root. A run-scoped member
# called with no --repo exits 2 when the switch is non-empty, and also under
# --home governed or --run-class leak-risk in either switch state. The designation's
# workspace root is the _for form's argument; for a no-argument form it is
# CLAUDE_WORKSPACE_ROOT, else the config root's claude_workspace_root, else
# $HOME/Claude — and a governed working-state no-argument resolution refuses
# (exit 3) when PMO_PLATFORM_CONFIG_ROOT is set and that last rung would be used.
#
# THE DESIGNATED-MAIN-CHECKOUT RULE (one rule for every repository):
#   1. M is the context clone's main worktree: the first `worktree` entry of
#      `git -C <ctx> worktree list --porcelain`, made physical. Any git error, a bare
#      first entry or no work tree exits 3. N is the basename of M.
#   2. N listed and physical(<root>/N) == M: D = M, on — the main checkout itself or
#      any worktree of it.
#   3. Otherwise each listed entry L is tried IN LISTED ORDER, with
#      D_L = physical(<root>/L), read only when this step uses it, so a broken entry
#      for another repository never fails an unrelated context:
#        - D_L absent: exit 3 when L == N (a same-name clone whose designated checkout
#          is absent); otherwise skip it;
#        - origin(M) and origin(D_L) both non-empty and equal: D = D_L, on (a second
#          or renamed clone);
#        - L == N and the origins differ or one is missing: compare history. Either
#          side shallow exits 3; any git error exits 3; root-commit sets that
#          intersect give D = D_L, on (a fork-workflow clone); disjoint sets mean a
#          different repository, and the entry does not apply.
#      The first confirmed entry wins, and D_L must be its own clone's main worktree.
#   4. Otherwise the switch is off for this context, and the checkout is M.
#   origin() normalizes remote.origin.url to host/path: it drops the scheme, the
#   userinfo, any :port, a trailing / and a trailing .git; it rewrites user@host:path
#   to host/path; and it lowercases the host. Every git probe runs with GIT_DIR,
#   GIT_WORK_TREE, GIT_COMMON_DIR, GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY,
#   GIT_CEILING_DIRECTORIES and GIT_DISCOVERY_ACROSS_FILESYSTEM unset. With the
#   switch empty, and neither --run-class leak-risk nor --home governed given, no git
#   process runs and no file but the config root's operator.toml is read (plus the
#   today arm's own toml rungs, exactly as before).
#
# WHICH ARM A CALL RETURNS (in this order):
#   1. Parse: an unknown option, a missing value, an empty --repo, an empty or
#      unknown --run-class, an unknown --home, a missing or unknown member, a form the
#      member lacks, or --run-class leak-risk on a member that is not run-scoped: 2.
#   2. --home today: today's arm; the switch is not read.
#   3. Read the switch through the config root and check its grammar: a violation
#      is 3.
#   4. A run-scoped member with no --repo: 2, when the switch is non-empty or
#      --home governed or --run-class leak-risk is given.
#   5. --run-class leak-risk: the embargoed arm, in either switch state. A set
#      PMO_INSTANCE_PATH is 3; a set PMO_PLATFORM_CONFIG_ROOT with XDG_DATA_HOME
#      unusable is 3; <repository> is the designation's name for --repo's context
#      (the matched entry, else N); no override applies; the result passes the
#      work-tree refusal.
#   6. Switch empty and no --home governed: today's arm, with no git call.
#   7. Designate. Off, and no --home governed: today's arm.
#   8. The governed arm. A set family-wide relocation the member's today arm honors
#      (the "refused" column) is 3, naming it. The member's override, if set, wins
#      (one set per member, the union of its forms, read through the config root).
#      Otherwise working state is <D>/local-state/<sub> (or <D>/analysis), and that
#      base folder must exist (3 otherwise: a listed repository with no home fails
#      loud rather than falling back); per-user classes take their class home,
#      refuse (3) when PMO_PLATFORM_CONFIG_ROOT is set and the matching XDG base is
#      unusable (a sandboxed config root must not reach the live per-user homes), and
#      their result, override-derived included, passes the work-tree refusal.
#
# THE WORK-TREE REFUSAL runs no git process: a path is refused (3) when a component
# of it is .git, or when walking from its first existing ancestor, made physical, up
# to / finds a directory holding a .git entry of any type (a dangling link
# included), a directory named .git, or a directory git's own layout calls a
# repository (HEAD, objects/ and refs/). GIT_CEILING_DIRECTORIES, safe.directory and
# GIT_DISCOVERY_ACROSS_FILESYSTEM cannot change the answer, because nothing asks git.
#
# FAILURE CONTRACT. Exit 0: exactly one path and a newline on stdout, with no
# trailing slash (a directory, except needles and roster, which are files). Exit 2
# is usage and exit 3 a refusal; on either, stdout is empty and stderr carries
# exactly one line beginning "lib-instance-path: ". Every function is pure and
# creates nothing. A consumer captures the value and checks the status at the
# assignment its own script makes at top level: `X="$(pmo_… <args>)" || <stop>`. A
# check only inside a function the script calls through $(…) is not enough, because
# `exit` inside $(…) ends only the subshell. `local x="$(pmo_…)"` masks the status and
# `"$(pmo_…)/leaf"` swallows it into a root-anchored path; both are banned at every
# call site.
#
# Bash version: 3.2.57-safe — no arrays, no associative arrays, no ${v,,}.

# The path this library was sourced from, made absolute without a fork; the
# platform-context rung 2 reads it.
_PMO_LIB_SELF="${BASH_SOURCE[0]:-}"
case "$_PMO_LIB_SELF" in
  /*) ;;
  ?*) _PMO_LIB_SELF="${PWD}/${_PMO_LIB_SELF}" ;;
esac

# Private. The failure contract's one stderr line.
_pmo_lib_err() { printf 'lib-instance-path: %s\n' "$*" >&2; }

# Private. The physical form of an existing directory, else empty.
_pmo_phys() {
  if [[ -n "$1" && -d "$1" ]]; then ( cd -P -- "$1" 2>/dev/null && pwd -P ) || true; fi
}

# Private. git with the repository-discovery environment cleared, so a probe is
# judged by the tree's own structure even inside a git hook.
_pmo_git() {
  ( unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM
    git "$@" )
}

# Private. The config root's operator.toml, and one key read through it.
_pmo_cfg_toml() { printf '%s\n' "${PMO_PLATFORM_CONFIG_ROOT:-${HOME:-}/.config/pmo-platform}/operator.toml"; }
_pmo_cfg_key() {
  local _f
  _f="$(_pmo_cfg_toml)"
  _pmo_instance_toml_key "$1" "$_f"
}

# Private. The switch's entries, one per line; nothing when it is off. Returns 3
# when any entry breaks the grammar.
_pmo_governed_entries() {
  local _raw _rest _e _re='^[A-Za-z0-9][A-Za-z0-9._-]*$' _out=""
  _raw="$(_pmo_cfg_key governed_homes)"
  if [[ -z "$_raw" ]]; then return 0; fi
  _rest="${_raw},"
  while [[ -n "$_rest" ]]; do
    _e="${_rest%%,*}"; _rest="${_rest#*,}"
    _e="${_e#"${_e%%[![:space:]]*}"}"; _e="${_e%"${_e##*[![:space:]]}"}"
    if [[ -z "$_e" ]]; then continue; fi
    if [[ ! "$_e" =~ $_re ]]; then
      _pmo_lib_err "governed_homes entry '${_e}' breaks the entry grammar ^[A-Za-z0-9][A-Za-z0-9._-]*\$ (a repository name, never a path; a TOML array is not read)"
      return 3
    fi
    _out="${_out}${_e}
"
  done
  printf '%s' "$_out"
}

# Private. Is $1 one of the newline-separated entries in $2?
_pmo_listed() {
  case "
$2
" in
    *"
$1
"*) return 0 ;;
  esac
  return 1
}

# Private. The designation workspace root of a no-argument call. With $1 = refuse
# and PMO_PLATFORM_CONFIG_ROOT set, the $HOME/Claude rung refuses (3).
_pmo_canonical_ws() {
  local _ws="${CLAUDE_WORKSPACE_ROOT:-}"
  if [[ -z "$_ws" ]]; then _ws="$(_pmo_cfg_key claude_workspace_root)"; fi
  if [[ -z "$_ws" ]]; then
    if [[ "${1:-}" == "refuse" && -n "${PMO_PLATFORM_CONFIG_ROOT:-}" ]]; then
      _pmo_lib_err "refused: a sandboxed config root (PMO_PLATFORM_CONFIG_ROOT) with no workspace root — neither CLAUDE_WORKSPACE_ROOT nor the config root's claude_workspace_root is set, so the \$HOME/Claude fallback would designate the live main checkout"
      return 3
    fi
    _ws="${HOME:-}/Claude"
  fi
  printf '%s\n' "$_ws"
}

# Private. The platform context: PMO_SRC_ROOT; this library's own checkout;
# <root>/<pmo_platform_repo_name>.
_pmo_platform_context() {
  local _d _c _n
  if [[ -n "${PMO_SRC_ROOT:-}" ]]; then printf '%s\n' "$PMO_SRC_ROOT"; return 0; fi
  _d="${_PMO_LIB_SELF%/*}"
  case "$_d" in
    */core/deploy)
      _c="${_d%/core/deploy}"
      if [[ ( -e "$_c/.git" || -L "$_c/.git" ) && -f "$_c/core/deploy/lib-instance-path.sh" ]]; then
        printf '%s\n' "$_c"; return 0
      fi ;;
  esac
  _n="$(_pmo_cfg_key pmo_platform_repo_name)"
  printf '%s\n' "$1/${_n:-pmo-platform}"
}

# Private. The physical main worktree of a checkout's clone; returns 3 on a git
# error, a bare first entry, or no work tree. Silent: the caller reports.
_pmo_main_worktree() {
  local _out _p _phys
  _out="$(_pmo_git -C "$1" worktree list --porcelain 2>/dev/null)" || return 3
  _p="$(awk 'NR==1 && /^worktree /{sub(/^worktree /,""); p=$0} /^$/{d=1} !d && $0=="bare"{b=1} END{if (p!="" && !b) print p}' <<<"$_out")"
  if [[ -z "$_p" ]]; then return 3; fi
  _phys="$(_pmo_phys "$_p")"
  if [[ -z "$_phys" ]]; then return 3; fi
  printf '%s\n' "$_phys"
}

# Private. remote.origin.url normalized to host/path; empty when there is none;
# returns 3 on any other git error. Silent.
_pmo_origin_key() {
  local _u="" _rc=0 _h _r _pre
  _u="$(_pmo_git -C "$1" config --get remote.origin.url 2>/dev/null)" || _rc=$?
  if [[ $_rc -eq 1 ]]; then return 0; fi
  if [[ $_rc -ne 0 ]]; then return 3; fi
  if [[ -z "$_u" ]]; then return 0; fi
  _pre="${_u%%:*}"
  case "$_u" in
    *://*) _u="${_u#*://}"; _h="${_u%%/*}"; _r="${_u#"$_h"}"; _h="${_h##*@}"; _h="${_h%%:*}" ;;
    *:*)
      case "$_pre" in
        */*) _h=""; _r="$_u" ;;
        *)   _h="${_pre##*@}"; _r="/${_u#*:}" ;;
      esac ;;
    *) _h=""; _r="$_u" ;;
  esac
  while [[ "$_r" == */ ]]; do _r="${_r%/}"; done
  _r="${_r%.git}"
  while [[ "$_r" == */ ]]; do _r="${_r%/}"; done
  _h="$(printf '%s' "$_h" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  printf '%s%s\n' "$_h" "$_r"
}

# Private. "true" or "false" for a shallow clone; 3 on a git error. Silent.
_pmo_is_shallow() {
  local _s
  _s="$(_pmo_git -C "$1" rev-parse --is-shallow-repository 2>/dev/null)" || return 3
  printf '%s\n' "$_s"
}

# Private. The root commits of a checkout's HEAD, one per line; 3 on a git error.
_pmo_root_commits() {
  local _s
  _s="$(_pmo_git -C "$1" rev-list --max-parents=0 HEAD 2>/dev/null)" || return 3
  if [[ -z "$_s" ]]; then return 3; fi
  printf '%s\n' "$_s"
}

# Private. Do two newline-separated sets share a line?
_pmo_sets_intersect() {
  local _l
  while IFS= read -r _l; do
    if [[ -n "$_l" ]] && _pmo_listed "$_l" "$2"; then return 0; fi
  done <<EOF
$1
EOF
  return 1
}

# Private. The designation rule. Prints three lines — on|off, the name, the
# checkout — or returns 3 with one stderr line.
# Usage: _pmo_designation <root> <context> <entries>
_pmo_designation() {
  local _ws="$1" _ctx="$2" _entries="$3" _m _n _l _dl _om="" _om_read=0 _ol _sm _sl _rm _rl _chk
  if ! _m="$(_pmo_main_worktree "$_ctx")"; then
    _pmo_lib_err "refused: cannot designate a main checkout for ${_ctx} — no readable git work tree there (a git error, a bare repository or no work tree)"
    return 3
  fi
  _n="${_m##*/}"
  if [[ -z "$_entries" ]]; then printf 'off\n%s\n%s\n' "$_n" "$_m"; return 0; fi
  if _pmo_listed "$_n" "$_entries"; then
    _dl="$(_pmo_phys "${_ws}/${_n}")"
    if [[ -n "$_dl" && "$_dl" == "$_m" ]]; then printf 'on\n%s\n%s\n' "$_n" "$_m"; return 0; fi
  fi
  while IFS= read -r _l; do
    if [[ -z "$_l" ]]; then continue; fi
    _dl="$(_pmo_phys "${_ws}/${_l}")"
    if [[ -z "$_dl" ]]; then
      if [[ "$_l" == "$_n" ]]; then
        _pmo_lib_err "refused: governed_homes lists ${_l}, but its designated checkout ${_ws}/${_l} is absent, so a clone named ${_l} at ${_m} cannot be designated"
        return 3
      fi
      continue
    fi
    if [[ $_om_read -eq 0 ]]; then
      if ! _om="$(_pmo_origin_key "$_m")"; then
        _pmo_lib_err "refused: cannot read the origin of ${_m} (a git error)"
        return 3
      fi
      _om_read=1
    fi
    if ! _ol="$(_pmo_origin_key "$_dl")"; then
      if [[ "$_l" == "$_n" ]]; then
        _pmo_lib_err "refused: cannot read the origin of the designated checkout ${_dl} (a git error)"
        return 3
      fi
      continue
    fi
    if [[ -n "$_om" && -n "$_ol" && "$_om" == "$_ol" ]]; then
      if ! _chk="$(_pmo_main_worktree "$_dl")" || [[ "$_chk" != "$_dl" ]]; then
        _pmo_lib_err "refused: ${_dl} shares ${_m}'s origin but is not its own clone's main worktree, so it cannot be the designated checkout"
        return 3
      fi
      printf 'on\n%s\n%s\n' "$_l" "$_dl"; return 0
    fi
    if [[ "$_l" == "$_n" ]]; then
      if ! _sm="$(_pmo_is_shallow "$_m")" || ! _sl="$(_pmo_is_shallow "$_dl")"; then
        _pmo_lib_err "refused: cannot read whether ${_m} or ${_dl} is shallow (a git error), so identity cannot be confirmed"
        return 3
      fi
      if [[ "$_sm" == "true" || "$_sl" == "true" ]]; then
        _pmo_lib_err "refused: ${_m} and ${_dl} share the name ${_l} with different origins, and a shallow clone cannot confirm identity from history"
        return 3
      fi
      if ! _rm="$(_pmo_root_commits "$_m")" || ! _rl="$(_pmo_root_commits "$_dl")"; then
        _pmo_lib_err "refused: cannot read the root commits of ${_m} or ${_dl} (a git error), so identity cannot be confirmed"
        return 3
      fi
      if _pmo_sets_intersect "$_rm" "$_rl"; then
        if ! _chk="$(_pmo_main_worktree "$_dl")" || [[ "$_chk" != "$_dl" ]]; then
          _pmo_lib_err "refused: ${_dl} shares ${_m}'s history but is not its own clone's main worktree, so it cannot be the designated checkout"
          return 3
        fi
        printf 'on\n%s\n%s\n' "$_l" "$_dl"; return 0
      fi
    fi
  done <<EOF
$_entries
EOF
  printf 'off\n%s\n%s\n' "$_n" "$_m"
}

# Private. The work-tree refusal: prints the path, or returns 3 with one stderr
# line when it lies inside a git work tree or a git directory. Runs no git.
_pmo_refuse_in_tree() {
  local _p="$1" _a _d _hit=""
  case "/${_p}/" in
    */.git/*) _hit="a .git path component" ;;
  esac
  if [[ -z "$_hit" ]]; then
    _a="$_p"
    while [[ -n "$_a" && "$_a" != "/" && ! -e "$_a" && ! -L "$_a" ]]; do
      _a="${_a%/*}"
      if [[ -z "$_a" ]]; then _a="/"; fi
    done
    if [[ -z "$_a" ]]; then _a="/"; fi
    if [[ -d "$_a" ]]; then
      _d="$(_pmo_phys "$_a")"
    else
      _d="${_a%/*}"
      if [[ -z "$_d" ]]; then _d="/"; fi
      _d="$(_pmo_phys "$_d")"
    fi
    if [[ -z "$_d" ]]; then _d="/"; fi
    while :; do
      if [[ -e "${_d%/}/.git" || -L "${_d%/}/.git" ]]; then _hit="${_d%/}/.git"; break; fi
      case "$_d" in */.git) _hit="$_d"; break ;; esac
      if [[ -f "${_d%/}/HEAD" && -d "${_d%/}/objects" && -d "${_d%/}/refs" ]]; then _hit="$_d (a git directory)"; break; fi
      if [[ "$_d" == "/" ]]; then break; fi
      _d="${_d%/*}"
      if [[ -z "$_d" ]]; then _d="/"; fi
    done
  fi
  if [[ -n "$_hit" ]]; then
    _pmo_lib_err "refused: ${_p} is inside a git work tree or git directory (${_hit}); a per-user home never lives in a repository, ignored or not"
    return 3
  fi
  printf '%s\n' "$_p"
}

# Private. XDG bases and the two per-user homes.
_pmo_xdg_base() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *)  printf '%s\n' "${HOME:-}/$2" ;;
  esac
}
_pmo_leak_risk_home() {
  local _b
  _b="$(_pmo_xdg_base "${XDG_DATA_HOME:-}" .local/share)"
  printf '%s\n' "${_b%/}/pmo-platform/pmo-private"
}
_pmo_install_state_home() {
  local _b
  _b="$(_pmo_xdg_base "${XDG_STATE_HOME:-}" .local/state)"
  printf '%s\n' "${_b%/}/pmo-platform/telemetry"
}

# Private. The sandbox-parity refusal: a set config root with the matching XDG base
# unusable. Usage: _pmo_cfgroot_xdg_ok data|state
_pmo_cfgroot_xdg_ok() {
  local _v _n
  if [[ -z "${PMO_PLATFORM_CONFIG_ROOT:-}" ]]; then return 0; fi
  if [[ "$1" == "data" ]]; then _v="${XDG_DATA_HOME:-}"; _n="XDG_DATA_HOME"; else _v="${XDG_STATE_HOME:-}"; _n="XDG_STATE_HOME"; fi
  case "$_v" in /*) return 0 ;; esac
  _pmo_lib_err "refused: sandboxed config root without ${_n} — PMO_PLATFORM_CONFIG_ROOT is set and ${_n} is unset, empty or not absolute, so the per-user home would be the live one"
  return 3
}

# Private. Working-state member table: "<sub> <run-scoped> <forms>", or 2.
_pmo_ws_member_info() {
  case "$1" in
    release-runs)           printf 'release-runs yes both\n' ;;
    release-runs-templates) printf 'release-runs no for\n' ;;
    event-log)              printf 'event-log yes both\n' ;;
    registers)              printf 'registers yes both\n' ;;
    logs)                   printf 'logs no both\n' ;;
    allowlists)             printf 'allowlists no both\n' ;;
    telemetry)              printf 'telemetry no for\n' ;;
    analysis)               printf 'analysis no for\n' ;;
    *) return 2 ;;
  esac
}

# Private. A working-state member's today arm. Usage: _pmo_ws_today for|noarg <root> <member>
_pmo_ws_today() {
  local _form="$1" _root="$2" _v _b
  case "$3" in
    release-runs)
      _v="$(_pmo_instance_toml_key operator_instance_hub_state_path)"
      if [[ -n "$_v" ]]; then printf '%s\n' "$_v"; return 0; fi
      if [[ "$_form" == "for" ]]; then _b="$(pmo_instance_path_for "$_root")"; else _b="$(pmo_instance_path)"; fi
      printf '%s\n' "${_b}/hub-state" ;;
    release-runs-templates)
      _b="$(pmo_instance_path_for "$_root")"
      printf '%s\n' "${_b}/hub-state" ;;
    event-log)
      if [[ "$_form" == "for" ]]; then
        _v="$(_pmo_instance_toml_key operator_instance_evals_results_path)"
        printf '%s\n' "${_v:-${_root}/pmo-instance/evals/results}"
      else
        _pmo_today_event_log
      fi ;;
    registers)
      if [[ "$_form" == "for" ]]; then _b="$(pmo_instance_path_for "$_root")"; else _b="$(pmo_instance_path)"; fi
      printf '%s\n' "${_b}/releases/registers" ;;
    logs|allowlists)
      if [[ "$_form" == "for" ]]; then pmo_instance_path_for "$_root"; else pmo_instance_path; fi ;;
    telemetry) pmo_telemetry_path_for "$_root" ;;
    analysis)  pmo_analysis_path_for "$_root" ;;
  esac
}

# Private. A working-state member's governed-arm override (one set, the union of
# its forms, read through the config root); empty when none is set.
_pmo_ws_override() {
  case "$1" in
    release-runs) _pmo_cfg_key operator_instance_hub_state_path ;;
    event-log)
      if [[ -n "${EVALS_RESULTS_PATH:-}" ]]; then printf '%s\n' "$EVALS_RESULTS_PATH"
      else _pmo_cfg_key operator_instance_evals_results_path; fi ;;
    telemetry) _pmo_cfg_key operator_instance_working_state_telemetry_path ;;
    analysis)  _pmo_cfg_key operator_instance_analysis_path ;;
  esac
}

# Private. The set family-wide relocation a working-state member's today arm
# honors, by name; empty when none is set. Usage: _pmo_ws_refused for|noarg <member>
_pmo_ws_refused() {
  case "$2" in
    release-runs|release-runs-templates|registers|logs|allowlists)
      if [[ -n "${PMO_INSTANCE_PATH:-}" ]]; then printf 'PMO_INSTANCE_PATH\n'; fi ;;
    event-log)
      if [[ "$1" == "noarg" && -n "${WORKSPACE_ROOT:-}" ]]; then printf 'WORKSPACE_ROOT\n'; fi ;;
  esac
}

# Private. The working-state engine. Usage: _pmo_ws_engine for|noarg <root> <member> [options]
_pmo_ws_engine() {
  local _form="$1" _root="$2" _member="" _repo="" _repo_set=0 _class="working-state" _home=""
  local _info _sub _rs _forms _entries _ws="" _ctx _des _st _nm _d _ref _ov _base _lr
  shift 2
  if [[ $# -lt 1 ]]; then _pmo_lib_err "missing member (one of the working-state members in the class-resolver table)"; return 2; fi
  _member="$1"; shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        if [[ $# -lt 2 ]]; then _pmo_lib_err "--repo needs a checkout"; return 2; fi
        if [[ -z "$2" ]]; then _pmo_lib_err "--repo is empty"; return 2; fi
        _repo="$2"; _repo_set=1; shift 2 ;;
      --run-class)
        if [[ $# -lt 2 ]]; then _pmo_lib_err "--run-class needs a class (working-state | leak-risk)"; return 2; fi
        case "$2" in
          working-state|leak-risk) _class="$2" ;;
          *) _pmo_lib_err "unknown run class '$2' (working-state | leak-risk)"; return 2 ;;
        esac
        shift 2 ;;
      --home)
        if [[ $# -lt 2 ]]; then _pmo_lib_err "--home needs an arm (today | governed)"; return 2; fi
        case "$2" in
          today|governed) _home="$2" ;;
          *) _pmo_lib_err "unknown arm '$2' for --home (today | governed)"; return 2 ;;
        esac
        shift 2 ;;
      *) _pmo_lib_err "unknown option or extra argument '$1'"; return 2 ;;
    esac
  done
  if ! _info="$(_pmo_ws_member_info "$_member")"; then
    _pmo_lib_err "unknown working-state member '${_member}' — a member the placement standard does not register resolves to no home"
    return 2
  fi
  IFS=' ' read -r _sub _rs _forms <<<"$_info"
  if [[ "$_forms" == "for" && "$_form" == "noarg" ]]; then
    _pmo_lib_err "member ${_member} has no no-argument form; call pmo_working_state_path_for <workspace-root> ${_member}"
    return 2
  fi
  if [[ "$_class" == "leak-risk" && "$_rs" != "yes" ]]; then
    _pmo_lib_err "--run-class leak-risk applies only to the run-scoped members (release-runs, event-log, registers), not ${_member}"
    return 2
  fi
  if [[ "$_home" == "today" ]]; then _pmo_ws_today "$_form" "$_root" "$_member"; return 0; fi
  _entries="$(_pmo_governed_entries)" || return 3
  if [[ "$_rs" == "yes" && $_repo_set -eq 0 ]]; then
    if [[ -n "$_entries" || "$_home" == "governed" || "$_class" == "leak-risk" ]]; then
      _pmo_lib_err "run-scoped member ${_member} needs --repo once governed_homes is set, and always under --home governed or --run-class leak-risk"
      return 2
    fi
  fi
  if [[ "$_class" == "leak-risk" ]]; then
    if [[ -n "${PMO_INSTANCE_PATH:-}" ]]; then
      _pmo_lib_err "refused: PMO_INSTANCE_PATH is set — a family-wide relocation the embargoed arm does not apply"
      return 3
    fi
    _pmo_cfgroot_xdg_ok data || return 3
    if [[ -n "$_entries" ]]; then
      if [[ "$_form" == "for" ]]; then _ws="$_root"; else _ws="$(_pmo_canonical_ws refuse)" || return 3; fi
    fi
    _des="$(_pmo_designation "$_ws" "$_repo" "$_entries")" || return 3
    { IFS= read -r _st; IFS= read -r _nm; IFS= read -r _d; } <<<"$_des"
    _lr="$(_pmo_leak_risk_home)"
    _pmo_refuse_in_tree "${_lr}/embargoed/${_nm}/${_sub}" || return 3
    return 0
  fi
  if [[ -z "$_entries" && "$_home" != "governed" ]]; then _pmo_ws_today "$_form" "$_root" "$_member"; return 0; fi
  if [[ -n "$_entries" || $_repo_set -eq 0 ]]; then
    if [[ "$_form" == "for" ]]; then _ws="$_root"; else _ws="$(_pmo_canonical_ws refuse)" || return 3; fi
  fi
  if [[ $_repo_set -eq 1 ]]; then _ctx="$_repo"; else _ctx="$(_pmo_platform_context "$_ws")"; fi
  _des="$(_pmo_designation "$_ws" "$_ctx" "$_entries")" || return 3
  { IFS= read -r _st; IFS= read -r _nm; IFS= read -r _d; } <<<"$_des"
  if [[ "$_st" != "on" && "$_home" != "governed" ]]; then _pmo_ws_today "$_form" "$_root" "$_member"; return 0; fi
  _ref="$(_pmo_ws_refused "$_form" "$_member")"
  if [[ -n "$_ref" ]]; then
    _pmo_lib_err "refused: ${_ref} is set — a family-wide relocation the governed arm does not apply to member ${_member}; that class's cutover states how it maps"
    return 3
  fi
  _ov="$(_pmo_ws_override "$_member")"
  if [[ -n "$_ov" ]]; then printf '%s\n' "$_ov"; return 0; fi
  if [[ "$_member" == "analysis" ]]; then _base="${_d}/analysis"; else _base="${_d}/local-state"; fi
  if [[ ! -d "$_base" ]]; then
    _pmo_lib_err "refused: the governed home ${_base} of ${_nm} is absent — the resolver does not fall back to today's path"
    return 3
  fi
  if [[ "$_member" == "analysis" ]]; then printf '%s\n' "$_base"; else printf '%s\n' "${_base}/${_sub}"; fi
}

# Private. The per-user engine (leak-risk and install-scoped).
# Usage: _pmo_pu_engine leak|install for|noarg <root> <member> [--home today|governed]
_pmo_pu_engine() {
  local _cls="$1" _form="$2" _root="$3" _member="" _home="" _entries _ws _ctx _des _st _nm _d _res _v _b
  shift 3
  if [[ $# -lt 1 ]]; then _pmo_lib_err "missing member"; return 2; fi
  _member="$1"; shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --home)
        if [[ $# -lt 2 ]]; then _pmo_lib_err "--home needs an arm (today | governed)"; return 2; fi
        case "$2" in
          today|governed) _home="$2" ;;
          *) _pmo_lib_err "unknown arm '$2' for --home (today | governed)"; return 2 ;;
        esac
        shift 2 ;;
      *) _pmo_lib_err "unknown option or extra argument '$1' (a per-user class takes --home only)"; return 2 ;;
    esac
  done
  case "${_cls}:${_member}" in
    leak:needles|leak:roster|leak:home|install:usage-store) ;;
    *) _pmo_lib_err "unknown ${_cls}-class member '${_member}' — a member the placement standard does not register resolves to no home"; return 2 ;;
  esac
  if [[ "$_home" != "today" ]]; then
    _entries="$(_pmo_governed_entries)" || return 3
    _st="off"
    if [[ "$_home" == "governed" ]]; then
      _st="on"
    elif [[ -n "$_entries" ]]; then
      if [[ "$_form" == "for" ]]; then _ws="$_root"; else _ws="$(_pmo_canonical_ws)" || return 3; fi
      _ctx="$(_pmo_platform_context "$_ws")"
      _des="$(_pmo_designation "$_ws" "$_ctx" "$_entries")" || return 3
      { IFS= read -r _st; IFS= read -r _nm; IFS= read -r _d; } <<<"$_des"
    fi
    if [[ "$_st" == "on" ]]; then
        if [[ "$_cls" == "leak" && -n "${PMO_INSTANCE_PATH:-}" ]]; then
          _pmo_lib_err "refused: PMO_INSTANCE_PATH is set — a family-wide relocation the governed arm does not apply to member ${_member}; that class's cutover states how it maps"
          return 3
        fi
        if [[ "$_cls" == "leak" ]]; then _pmo_cfgroot_xdg_ok data || return 3; else _pmo_cfgroot_xdg_ok state || return 3; fi
        case "$_member" in
          needles)     _res="${PMO_LOCALIZED_NEEDLES:-}"; [[ -n "$_res" ]] || { _b="$(_pmo_leak_risk_home)"; _res="${_b}/localized-context-needles.txt"; } ;;
          roster)      _res="${PMO_PEOPLE_ROSTER:-}"; [[ -n "$_res" ]] || { _b="$(_pmo_leak_risk_home)"; _res="${_b}/people-roster.yaml"; } ;;
          home)        _res="$(_pmo_leak_risk_home)" ;;
          usage-store) _res="$(_pmo_cfg_key operator_instance_finops_store_path)"; [[ -n "$_res" ]] || _res="$(_pmo_install_state_home)" ;;
        esac
        _pmo_refuse_in_tree "$_res" || return 3
        return 0
    fi
  fi
  case "${_form}:${_member}" in
    for:needles)    printf '%s\n' "${PMO_LOCALIZED_NEEDLES:-$(pmo_instance_path_for "$_root")/localized-context-needles.txt}" ;;
    noarg:needles)  _pmo_today_needles ;;
    for:roster)     _pmo_today_roster_for "$_root" ;;
    noarg:roster)   _pmo_today_roster ;;
    for:home)       pmo_instance_path_for "$_root" ;;
    noarg:home)     pmo_instance_path ;;
    for:usage-store)
      _v="$(_pmo_instance_toml_key operator_instance_finops_store_path)"
      printf '%s\n' "${_v:-${_root}/pmo-instance/finops}" ;;
  esac
}

# Public. Working state per repository.
pmo_working_state_path_for() {
  local _r
  if [[ $# -lt 1 || -z "${1:-}" ]]; then _pmo_lib_err "pmo_working_state_path_for: missing workspace root"; return 2; fi
  _r="$1"; shift
  _pmo_ws_engine for "$_r" "$@"
}
pmo_working_state_path() { _pmo_ws_engine noarg "" "$@"; }

# Public. Working state, install-scoped (served on the _for form only).
pmo_install_state_path_for() {
  local _r
  if [[ $# -lt 1 || -z "${1:-}" ]]; then _pmo_lib_err "pmo_install_state_path_for: missing workspace root"; return 2; fi
  _r="$1"; shift
  _pmo_pu_engine install for "$_r" "$@"
}

# Public. Leak-risk.
pmo_leak_risk_path_for() {
  local _r
  if [[ $# -lt 1 || -z "${1:-}" ]]; then _pmo_lib_err "pmo_leak_risk_path_for: missing workspace root"; return 2; fi
  _r="$1"; shift
  _pmo_pu_engine leak for "$_r" "$@"
}
pmo_leak_risk_path() { _pmo_pu_engine leak noarg "" "$@"; }

# Public. The designated main checkout for a checkout (default: the platform
# context): D when its repository is on, else its own main worktree.
pmo_main_checkout_for() {
  local _ws _ctx _entries _des _st _nm _d
  if [[ $# -lt 1 || $# -gt 2 || -z "${1:-}" ]]; then _pmo_lib_err "usage: pmo_main_checkout_for <workspace-root> [<checkout>]"; return 2; fi
  _ws="$1"
  _ctx="${2:-}"
  if [[ -z "$_ctx" ]]; then _ctx="$(_pmo_platform_context "$_ws")"; fi
  _entries="$(_pmo_governed_entries)" || return 3
  _des="$(_pmo_designation "$_ws" "$_ctx" "$_entries")" || return 3
  { IFS= read -r _st; IFS= read -r _nm; IFS= read -r _d; } <<<"$_des"
  printf '%s\n' "$_d"
}

# Public. on | off for a checkout's repository (default: the platform context). With
# the switch empty it prints off without running git.
pmo_governed_homes_for() {
  local _ws _ctx _entries _des _st _nm _d
  if [[ $# -lt 1 || $# -gt 2 || -z "${1:-}" ]]; then _pmo_lib_err "usage: pmo_governed_homes_for <workspace-root> [<checkout>]"; return 2; fi
  _ws="$1"
  _entries="$(_pmo_governed_entries)" || return 3
  if [[ -z "$_entries" ]]; then printf 'off\n'; return 0; fi
  _ctx="${2:-}"
  if [[ -z "$_ctx" ]]; then _ctx="$(_pmo_platform_context "$_ws")"; fi
  _des="$(_pmo_designation "$_ws" "$_ctx" "$_entries")" || return 3
  { IFS= read -r _st; IFS= read -r _nm; IFS= read -r _d; } <<<"$_des"
  printf '%s\n' "$_st"
}
