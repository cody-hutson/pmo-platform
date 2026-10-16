#!/usr/bin/env bash
# deciders-carveout.sh — Shared per-line decision for the depersonalization gate.
#
# The SINGLE home of the ADR `deciders:` carve-out predicate. Both callers source
# this library, so the decision is made in ONE place:
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
#   this run" — e.g. a bot-authored PR, where the operator-self dimension is skipped
#   upstream by design. Falling back to suppression there reproduces the shipped
#   whole-line behaviour rather than inventing a new verdict for a dimension that is
#   already dark. It is also why the -s test is explicit and comes FIRST: `grep -f`
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

# ---------------------------------------------------------------------------------
# FAIL-CLOSED EVALUATION — the gate's three reads of the change under review.
#
# The gate reads the change three times before any per-line verdict: it lists the
# changed files, extracts each file's added lines, and scans those lines against the
# literal set. Each read can end in one of three states, and only two of them are
# answers:
#
#   found something       — the read ran and returned content
#   found nothing         — the read ran and returned nothing (git exit 0 with empty
#                           output; grep exit 1)
#   could not evaluate    — the read did not run to completion (any other non-zero
#                           exit, a missing input, a missing revision)
#
# The inline form these replace swallowed every non-zero exit, so "could not
# evaluate" collapsed into "found nothing" and the gate passed: a missing base commit
# read as "no changed files", and a grep exit 2 read as "no match". A control that
# could not run must not look like one that ran clean, so each function below reports
# the third state as its own verdict, UNEVALUABLE, and the gate turns it into a red
# run.
#
# The same conventions as the functions above: explicit parameters, no caller
# globals, one verdict token on stdout, return 0. Two more, specific to these three:
#   - The repository is a PARAMETER, read with `git -C`, so the caller's working
#     directory is not ambient input either.
#   - No pipelines and no `cmd; rc=$?` after a bare command. Each status is read in
#     an `if` condition, so the verdict is the same under the gate's
#     `set -euo pipefail` and under the fixture suite's `set -uo pipefail`.
#     Hiding a status behind a pipe or a process substitution is how the defect
#     shipped, so none is used here.
#
# On every non-success path the out-file is truncated, so a caller that ignores the
# verdict reads nothing rather than a stale partial result.
#
# KNOWN RESIDUAL, stated rather than implied: the per-line greps in
# adr_deciders_carveout_suppresses and depersonalization_line_verdict above still
# read a grep exit 2 as "no match". For a malformed pattern that is covered by
# construction. literal_scan_verdict runs first over the same pattern file, and
# the not-carved file's literal is byte-identical to a line in it, so a malformed
# literal fails the scan before either per-line grep runs. A non-deterministic grep
# failure between the scan and the per-line verdict is not covered.
# ---------------------------------------------------------------------------------

# changed_files_verdict <repo-dir> <base-sha> <head-sha> <out-file>
#   LISTED       — git listed the changed files into <out-file>; empty is a valid
#                  answer (no files changed)
#   UNEVALUABLE  — base or head missing, or git exited non-zero; <out-file> empty
changed_files_verdict() {
  _cf_repo="${1?changed_files_verdict: repo dir required}"
  _cf_base="${2-}"
  _cf_head="${3-}"
  _cf_out="${4?changed_files_verdict: out-file required}"

  # An empty revision is not a missing commit to git: `A...` and `...B` default the
  # missing side to HEAD and diff successfully against the wrong range.
  if [ -z "$_cf_base" ] || [ -z "$_cf_head" ]; then
    : > "$_cf_out"
    printf 'UNEVALUABLE\n'
    return 0
  fi
  if git -C "$_cf_repo" diff --name-only "$_cf_base"..."$_cf_head" > "$_cf_out"; then
    printf 'LISTED\n'
  else
    : > "$_cf_out"
    printf 'UNEVALUABLE\n'
  fi
  return 0
}

# added_lines_verdict <repo-dir> <base-sha> <head-sha> <path> <out-file>
#   LISTED       — <out-file> holds the lines <path> ADDED since the merge base, one
#                  per line as HEAD-LINENO:CONTENT; empty is a valid answer
#   UNEVALUABLE  — base or head missing, the diff failed, or the extraction failed;
#                  <out-file> empty
#
#   The diff and the extraction are two commands with a file between them, not a
#   pipeline, so a failed diff cannot hide behind a successful awk. The awk program
#   is the gate's, moved here unchanged.
added_lines_verdict() {
  _al_repo="${1?added_lines_verdict: repo dir required}"
  _al_base="${2-}"
  _al_head="${3-}"
  _al_path="${4?added_lines_verdict: path required}"
  _al_out="${5?added_lines_verdict: out-file required}"

  : > "$_al_out"
  if [ -z "$_al_base" ] || [ -z "$_al_head" ]; then
    printf 'UNEVALUABLE\n'
    return 0
  fi
  if ! _al_diff="$(mktemp)"; then
    printf 'UNEVALUABLE\n'
    return 0
  fi
  if ! git -C "$_al_repo" diff --unified=0 "$_al_base"..."$_al_head" -- "$_al_path" > "$_al_diff"; then
    rm -f "$_al_diff"
    printf 'UNEVALUABLE\n'
    return 0
  fi
  if ! awk '
      /^@@/ { plus = $3; sub(/^\+/, "", plus); split(plus, pc, ","); newln = pc[1] + 0; next }
      /^\+\+\+/ { next }
      /^\+/ { print newln ":" substr($0, 2); newln++ ; next }
      /^-/ { next }
    ' "$_al_diff" > "$_al_out"; then
    rm -f "$_al_diff"
    : > "$_al_out"
    printf 'UNEVALUABLE\n'
    return 0
  fi
  rm -f "$_al_diff"
  printf 'LISTED\n'
  return 0
}

# literal_scan_verdict <added-lines-file> <pattern-file> <out-file>
#   HITS         — grep exit 0; <out-file> holds the matching LINENO:CONTENT lines
#   NONE         — grep exit 1, or an EMPTY added-lines file (nothing was added)
#   UNEVALUABLE  — any other grep exit (2: a malformed or unreadable pattern), a
#                  MISSING added-lines file, or a missing or EMPTY pattern file;
#                  <out-file> empty
#
#   An empty pattern file is UNEVALUABLE, not NONE. The gate settles the empty
#   literal set before it scans, so reaching the scan with one is an upstream
#   defect. And grep -f against an empty file is not uniform across
#   implementations, which is the hazard the carve-out predicate above guards
#   against with its own -s test.
#
#   The added lines are read from a FILE argument, not a here-string or a pipe, so
#   the empty-haystack hazard documented above does not arise.
literal_scan_verdict() {
  _ls_added="${1?literal_scan_verdict: added-lines file required}"
  _ls_patterns="${2?literal_scan_verdict: pattern file required}"
  _ls_out="${3?literal_scan_verdict: out-file required}"

  : > "$_ls_out"
  if [ ! -f "$_ls_added" ] || [ ! -s "$_ls_patterns" ]; then
    printf 'UNEVALUABLE\n'
    return 0
  fi
  if [ ! -s "$_ls_added" ]; then
    printf 'NONE\n'
    return 0
  fi
  if grep -E -f "$_ls_patterns" "$_ls_added" > "$_ls_out"; then
    printf 'HITS\n'
    return 0
  else
    _ls_rc=$?
  fi
  : > "$_ls_out"
  if [ "$_ls_rc" -eq 1 ]; then
    printf 'NONE\n'
  else
    printf 'UNEVALUABLE\n'
  fi
  return 0
}
