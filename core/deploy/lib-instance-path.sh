#!/usr/bin/env bash
# lib-instance-path.sh — single resolver for the operator-instance directory, the
# operations-workspace root, the localized-context needle file, the people-roster
# file, the evals-results directory (home of the pipeline event log), and the
# three ambient-intake member directories (inbox drop-zone, Path-A intake-sweep
# run-log dir, Path-B external-sync dir).
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
#   - This is the one resolution site for the instance/needle/roster path surface.
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
#   pmo_evals_results_path() → $EVALS_RESULTS_PATH, else the operator.toml key
#                              operator_instance_evals_results_path, else
#                              <workspace-root>/pmo-instance/evals/results
#                              where <workspace-root> is itself a four-step
#                              cascade: $WORKSPACE_ROOT, else
#                              $CLAUDE_WORKSPACE_ROOT, else the operator.toml key
#                              claude_workspace_root, else $HOME/Claude
#                              (3 tiers — deliberately NOT expressible as one
#                              ${VAR:-default} expansion like the three above)
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
#
# All are pure stdout-echoing functions (no side effects, no mutation); safe to
# call under `set -euo pipefail`. Sourceable AND idempotent: re-sourcing is a
# no-op (the function definitions are simply re-declared).
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
# Three-tier resolution. This function is the SINGLE resolution site for the path
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
pmo_evals_results_path() {
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
# operator.toml reader for this file — the three ambient resolvers below and
# pmo_evals_results_path() above all call it, so there is one canonical XDG
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
  local _toml="${HOME}/.config/pmo-platform/operator.toml"
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
