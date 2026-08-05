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
adr_deciders_carveout_suppresses() {
  _dc_path="${1?adr_deciders_carveout_suppresses: path required}"
  _dc_content="${2-}"
  _dc_not_carved="${3-}"

  case "$_dc_path" in
    core/ADRs/*.md|release/ADRs/*.md) : ;;
    *) return 1 ;;
  esac

  printf '%s' "$_dc_content" | grep -qE '^deciders:' || return 1

  if [ -n "$_dc_not_carved" ] && [ -s "$_dc_not_carved" ] \
     && printf '%s' "$_dc_content" | grep -qE -f "$_dc_not_carved"; then
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

  if [ ! -s "$_dv_patterns" ] \
     || ! printf '%s' "$_dv_content" | grep -qE -f "$_dv_patterns"; then
    printf 'CLEAN\n'
    return 0
  fi
  if [ -n "$_dv_override" ] && printf '%s' "$_dv_content" | grep -qE "$_dv_override"; then
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
