#!/usr/bin/env bash
# deciders-carveout.sh — Shared decisions for the depersonalization gate.
#
# The SINGLE home of the gate's decisions: the configuration preflights, the
# operator-literal resolution, the empty-literal-set verdict, and the per-line ADR
# `deciders:` carve-out predicate. Both callers source this library, so each
# decision is made in ONE place:
#   - .github/workflows/repo-integrity.yml           job `depersonalization` (the live gate)
#   - release/tools/tests/test_deciders_carveout.sh  the committed fixture suite
#
# WHY A LIBRARY AND NOT A COPY. The gate's decision was inline in the workflow,
# reachable only by a remote CI trigger, so the only way to exercise it locally was
# to re-implement it — and a re-implemented copy passes while the real gate
# diverges. That is the shadow-source failure this carve-out's own reconciliation
# exists to end, so the extraction is part of the fix rather than an exemption from
# it (review-discipline-principles.md § 8, PV-2d).
#
# THE RULE THIS REALIZES lives at core/standards/depersonalization-spec.md §1.2:
# the carve-out permits the operator's literal NAME on a frontmatter `deciders:`
# line inside an ADR, and nothing more. The GitHub handle is never sanctioned, on
# any line, `deciders:` included. This file CITES that rule; it does not restate it.
#
# Design note (mirrors release/tools/lib/schema-v1-emit.sh): every function takes
# EXPLICIT parameters and reads NO caller globals. The caller maps its own state
# onto the parameter list. That is what makes this a shared contract rather than a
# verbatim block silently depending on a dozen ambient variables at the extraction
# site.
#
# Trust boundary, stated because it is a fair question to ask of a workflow that
# sources a repository file: a `pull_request` run already executes the workflow
# file from the PR's own ref, so the gate has always been PR-modifiable. Sourcing
# this library moves a decision the PR could already edit into a file the PR could
# already edit; it does not widen the boundary, and it buys an entry point that is
# invocable locally AND by CI.
#
# This file is sourced, never executed. It defines functions and returns; it has no
# main and no side effects at source time.

# esc_lines <literal-block>
#   Read a newline-separated block of literal values; drop blank lines, trim
#   surrounding whitespace, regex-escape each value, and emit one \b-anchored ERE
#   per line on stdout. Every pattern file the gate matches against is built ONLY
#   through this helper, so no caller can accidentally assemble a looser or more
#   permissive pattern set than the gate itself uses.
#
#   Moved here VERBATIM from the workflow's inline definition — deliberately not
#   "improved" in transit, so the extraction is provably behaviour-preserving.
esc_lines() {
  printf '%s\n' "$1" | while IFS= read -r ln || [ -n "$ln" ]; do
    ln="$(printf '%s' "$ln" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -z "$ln" ] && continue
    esc="$(printf '%s' "$ln" | sed 's/[][\\.^$*+?(){}|/]/\\&/g')"
    printf '\\b%s\\b\n' "$esc"
  done
}

# THE RUN-LEVEL DECISIONS BELOW are the gate's resolution of WHAT it matches,
# made before any file is read. They were inline in the workflow, so the only proof
# of them was a live remote run; the decision record
# {{ADR:depersonalization-gate-scans-bot-runs}} moves them here for the same reason
# the per-line verdict lives here. None of them takes the run's actor as a parameter,
# and that is the decision rather than an omission: who triggered the run must not
# change what the run scans.

# identity_preflight <is_canonical> <identity>
#   Echoes exactly one token on stdout and returns 0:
#     OK    — the gate is configured to scan the operator's name and email
#     FAIL  — canonical repository with OPERATOR_IDENTITY unset: the designed loud
#             failure, because a personal-data control that scans nothing cannot be
#             told apart from one that passed
#
#   This is a CONFIGURATION check and is independent of content: the gate runs it
#   before the scope filter, so a misconfigured secret is reported on every pull
#   request, including one that changes no scanned file. The test is the same on
#   every run. A run Dependabot starts reads the Dependabot secret store, so a FAIL
#   there means the mirrored copy is missing (secrets-handling-policy.md §5). A fork
#   never fails here: its identity dimension is governed by its opt-out instead.
#
#   A whitespace-only identity counts as UNSET. esc_lines drops blank lines, so such
#   a value would pass a bare -z test and then scan no name or email at all; the
#   hand-set Dependabot mirror is exactly where such a value can slip in.
identity_preflight() {
  _ip_canonical="${1?identity_preflight: is_canonical required}"
  _ip_identity="${2-}"
  _ip_has_value=0
  case "$_ip_identity" in *[![:space:]]*) _ip_has_value=1 ;; esac
  if [ "$_ip_canonical" = "1" ] && [ "$_ip_has_value" -eq 0 ]; then
    printf 'FAIL\n'
  else
    printf 'OK\n'
  fi
  return 0
}

# handle_preflight <is_canonical> <owner> <repository>
#   Echoes exactly one token on stdout and returns 0:
#     OK    — the handle the gate will scan is the canonical repository's owner
#     FAIL  — canonical repository, and the owner handle is empty or is not the
#             owner segment of <repository> (the run's owner/name)
#
#   The handle is bound from github.repository_owner, which on the canonical
#   repository IS the owner segment of the repository name, so FAIL cannot be reached
#   by configuration. It is reached by an edit that re-binds the handle to something
#   else — the run's actor, say, at step level where it would shadow the job env —
#   or by an empty expression. Without this check either one leaves the identity
#   lines in the set, the verdict reads SCAN, and the handle is silently unscanned.
#   On a fork the owner is whatever the fork's owner is, so there is nothing to check.
handle_preflight() {
  _hp_canonical="${1?handle_preflight: is_canonical required}"
  _hp_owner="${2-}"
  _hp_repository="${3-}"
  if [ "$_hp_canonical" = "1" ] \
     && { [ -z "$_hp_owner" ] || [ "$_hp_owner" != "${_hp_repository%%/*}" ]; }; then
    printf 'FAIL\n'
  else
    printf 'OK\n'
  fi
  return 0
}

# resolve_operator_literals <is_canonical> <fork_opted_out> <owner> <identity>
#   Prints the operator-literal set on stdout, one literal per line, and returns 0:
#   the owner handle first, then each line of the identity block. Prints nothing on
#   a fork that opted the operator dimension out.
#
#   The handle is the repository OWNER, on every run, never the run's actor. That is
#   the resolution the ADR durability gate in the same workflow already uses: it is
#   the same whoever triggered the run, and correct on a fork. Resolving it from the
#   actor made the handle vary with the actor, which is why a bot's run used to be
#   exempted from the operator dimension altogether — and why, with no collaborator
#   list set, such a run scanned nothing and passed.
#
#   For a canonical run with an owner, the output equals the pre-change inline
#   construction byte for byte once captured by $(...): printf '%s\n%s\n' then
#   trailing-newline stripping. The fixture suite asserts that equality (arm e).
resolve_operator_literals() {
  _rl_canonical="${1?resolve_operator_literals: is_canonical required}"
  _rl_opted_out="${2?resolve_operator_literals: fork_opted_out required}"
  _rl_owner="${3-}"
  _rl_identity="${4-}"
  if [ "$_rl_canonical" != "1" ] && [ "$_rl_opted_out" = "1" ]; then
    return 0
  fi
  if [ -n "$_rl_owner" ]; then
    printf '%s\n' "$_rl_owner"
  fi
  if [ -n "$_rl_identity" ]; then
    printf '%s\n' "$_rl_identity"
  fi
  return 0
}

# literal_set_verdict <is_canonical> <pattern-file>
#   Echoes exactly one token on stdout and returns 0:
#     SCAN        — the pattern file holds at least one pattern; scan the files
#     FAIL-EMPTY  — canonical repository and nothing resolved: fail loud
#     PASS-EMPTY  — a fork and nothing resolved: report it and pass
#
#   On canonical, identity_preflight has already required the identity,
#   handle_preflight has required the owner, and resolve_operator_literals emits both,
#   so FAIL-EMPTY cannot be reached today. It is a guard, not dead code: the branch used to exit 0 with "nothing to
#   match", and an edit that re-opened a path to it would have re-armed a silent pass
#   in a branch-protection required check.
literal_set_verdict() {
  _ls_canonical="${1?literal_set_verdict: is_canonical required}"
  _ls_patterns="${2?literal_set_verdict: pattern file required}"
  if [ -s "$_ls_patterns" ]; then
    printf 'SCAN\n'
  elif [ "$_ls_canonical" = "1" ]; then
    printf 'FAIL-EMPTY\n'
  else
    printf 'PASS-EMPTY\n'
  fi
  return 0
}

# adr_deciders_carveout_suppresses <path> <line-content> <not-carved-pattern-file>
#   Exit 0 — the ADR `deciders:` carve-out SUPPRESSES this line.
#   Exit 1 — it does not; the line stays subject to the gate.
#
#   NAME-SCOPED, not line-scoped. The carve-out covers the operator's literal name.
#   A literal it does NOT cover — enumerated in the not-carved pattern file — keeps
#   the line blocked on a `deciders:` line exactly as on any other line. That is the
#   whole behavioural difference this predicate exists to make.
#
#   An EMPTY (or absent) not-carved file means "no un-carved literal resolved for
#   this run". The handle is resolved from the repository owner on every run (see
#   resolve_operator_literals above), so in the live gate that happens only on a fork
#   that opted the operator dimension out — never because of who triggered the run.
#   Falling back to suppression there reproduces the shipped whole-line behaviour
#   rather than inventing a new verdict for a dimension that is already dark. It is
#   also why the -s test is explicit and comes FIRST: `grep -f`
#   against an empty file, or one carrying a blank line, matches EVERY line on some
#   implementations, which would silently invert the carve-out into a blanket block.
#
#   EMPTY-HAYSTACK GUARD (the `[ -n "$_dc_content" ]` tests below). These greps read
#   their haystack from a here-string rather than a `printf | grep` pipe, so that a
#   short-circuiting reader can never leave the writer holding an unwritten residual
#   (the SIGPIPE class fixed in test_sandbox_roots.sh and in deploy.sh Check 31). The
#   two forms are NOT interchangeable on an empty haystack: `printf '%s' ""` emits
#   ZERO lines, while `<<<""` emits ONE empty line — so a pattern able to match an
#   empty line flips `no match` to `match` on the swap. On this code path that
#   inverts a depersonalization CLEAN verdict into BLOCKED, in a branch-protection
#   required gate, on any blank added line. The explicit -n test restores the
#   printf semantics exactly; it is load-bearing, not defensive decoration.
adr_deciders_carveout_suppresses() {
  _dc_path="${1?adr_deciders_carveout_suppresses: path required}"
  _dc_content="${2-}"
  _dc_not_carved="${3-}"

  case "$_dc_path" in
    core/ADRs/*.md|release/ADRs/*.md) : ;;
    *) return 1 ;;
  esac

  if [ -z "$_dc_content" ] || ! grep -qE '^deciders:' <<<"$_dc_content"; then
    return 1
  fi

  if [ -n "$_dc_not_carved" ] && [ -s "$_dc_not_carved" ] \
     && [ -n "$_dc_content" ] && grep -qE -f "$_dc_not_carved" <<<"$_dc_content"; then
    return 1
  fi
  return 0
}

# depersonalization_line_verdict <path> <content> <pattern-file> <not-carved-file> <override-ere>
#   Echoes exactly one verdict token on stdout and returns 0:
#     CLEAN                — no operator/collaborator literal on the line
#     SUPPRESSED-OVERRIDE  — literal present, line-scoped override marker
#     SUPPRESSED-CARVEOUT  — literal present, ADR `deciders:` name-scoped carve-out
#     BLOCKED              — literal present, no exemption applies
#
#   This is the gate's whole per-line decision. The workflow keeps the file walk,
#   the added-line delta, the redaction and the reporting; it delegates the verdict
#   here so the fixture suite asserts against the same code path rather than a
#   look-alike.
depersonalization_line_verdict() {
  _dv_path="${1?depersonalization_line_verdict: path required}"
  _dv_content="${2-}"
  _dv_patterns="${3?depersonalization_line_verdict: pattern file required}"
  _dv_not_carved="${4-}"
  _dv_override="${5-}"

  # Here-string form + explicit empty-haystack guard — see the note on
  # adr_deciders_carveout_suppresses above. `[ -z "$_dv_content" ]` is what keeps a
  # blank added line CLEAN; without it `<<<""` supplies the one empty line an
  # empty-matching pattern needs, and the gate blocks the PR.
  if [ ! -s "$_dv_patterns" ] || [ -z "$_dv_content" ] \
     || ! grep -qE -f "$_dv_patterns" <<<"$_dv_content"; then
    printf 'CLEAN\n'
    return 0
  fi
  if [ -n "$_dv_override" ] && [ -n "$_dv_content" ] \
     && grep -qE "$_dv_override" <<<"$_dv_content"; then
    printf 'SUPPRESSED-OVERRIDE\n'
    return 0
  fi
  if adr_deciders_carveout_suppresses "$_dv_path" "$_dv_content" "$_dv_not_carved"; then
    printf 'SUPPRESSED-CARVEOUT\n'
    return 0
  fi
  printf 'BLOCKED\n'
  return 0
}
