# positional-issueref.awk — shared positional issue-reference classifier
#
# Reference-durability issue (cross-reference-integrity-ci, issue #314):
# Single source of the positional-#N decision so it cannot drift across the three
# enforcement surfaces. At the time, the POSITIONAL logic was hand-reimplemented per surface
# and one copy (the CI) diverged (position-blind existence check vs the hook's line-position
# check), so this file made that decision single-sourced: each caller derives the three inputs
# its own way (its input shapes differ) and calls this one classifier for the decision.
#
# The detector CONSTANTS were a separate copy set, held together only by a comment asserting
# byte-identity. They are now single-sourced in their own right — declared once in
# lib/fragile-ref-patterns.sh and sourced by all three callers — so byte-identity across the
# regexes is no longer a property that can hold or fail either.
#
# Consumed via `awk -f` (NOT sourced as shell) by:
#   - core/hooks/block-fragile-refs.sh        (PreToolUse hook; lines over the stdin payload)
#   - core/hooks/run-fragile-ref-fixtures.sh  (fixture self-test; ISSUEREF-POS class)
#   - .github/workflows/reference-durability.yml (PR-time CI; added lines mapped to file lines)
# `awk -f` is outside the BLOCK-DESTRUCTIVE-022 interpreter set (bash|sh|zsh + source|.),
# so this include needs no script-execution-allowlist entry.
#
# INPUT CONTRACT
#   -v issuere=<ISSUEREF_RE>    the bare-issue-ref regex, passed in by the calling surface,
#                              which sources it from lib/fragile-ref-patterns.sh — this file
#                              does NOT own the regex and declares nothing.
#   -v hexcolor=<HEXCOLOR_RE>  companion hex-color mask regex, passed in from the same sourced
#                              lib by the same callers — this file does not own it either. Three
#                              ERE branches (no lookbehind available): (a) a # + a run of
#                              hex-legal chars containing >=1 hex letter [A-Fa-f] (e.g. #28A745,
#                              #FFF); (b) a colon-prefixed hex run `:#<3-8 hex digits>` — the
#                              CSS/Mermaid color-value form (e.g. color:#155724), which catches
#                              PURE-DIGIT hex colors that branch (a) cannot see; (c) the regex
#                              CHARACTER-CLASS hex form `#[<hex ranges>]` + optional {n}/{n,m}
#                              quantifier (e.g. #[0-9a-fA-F]{6}) — the char after # is `[`, so
#                              neither (a) nor (b) fires and the leading `#[0` would otherwise
#                              read as a bracketed ref (issue #4182). Masked to spaces
#                              BEFORE the issue-ref test so a hex color's numeric prefix (#28) is
#                              never mis-read as a bare issue ref (#314-companion fix, issue #2068).
#                              A prose issue ref (#NN / `#NN` / "See #NN") never carries a hex
#                              letter, is never colon-abutted, and carries no X-Y range inside
#                              brackets (branch (c) requires one), so it is never masked.
#   -v refline=<N>             reference-block header file-line number (0 = no block in file).
#   -v minwords=<MIN>          minimum non-reference words for an in-block ref to count as
#                              self-describing (= MIN_SELFDESCRIBE_WORDS, whose value is
#                              declared in lib/fragile-ref-patterns.sh — not restated here).
#   stdin: one record per scanned line, formatted "<FILE_LINE_NUMBER>\t<CONTENT>".
#          The FILE_LINE_NUMBER is the line's position in the FILE (not a delta index) —
#          each caller is responsible for supplying a true file line (the CI uses a
#          diff-hunk → file-line mapper to do so).
#
# OUTPUT (one line per FLAGGED record; clean records produce nothing):
#   "<FILE_LINE_NUMBER>:OUTSIDE-BLOCK:<CONTENT>"        ref before the block, or no block in file
#   "<FILE_LINE_NUMBER>:CONTENT-FREE-IN-BLOCK:<CONTENT>" ref in the block but < minwords self-describing words
#
# The verdict tokens (OUTSIDE-BLOCK / CONTENT-FREE-IN-BLOCK) and the "<lineno>:<verdict>:<line>"
# shape match what the hook's Pass-2 awk already emitted, so the hook's downstream report
# wiring is unchanged.

{
  # Split each record into its file-line-number column and its content column.
  tab = index($0, "\t")
  if (tab == 0) { lineno = NR; line = $0 }      # defensive: no tab => treat whole record as content
  else          { lineno = substr($0, 1, tab - 1) + 0; line = substr($0, tab + 1) }

  # Skip blank content lines.
  if (line ~ /^[[:space:]]*$/) next
  # Mask hex-color spans (#28A745 etc.) to spaces BEFORE the issue-ref test so a hex
  # color's numeric prefix (#28) is never mis-classified as a bare issue ref (#2068).
  # gsub-to-space ADDS a separator and consumes no issue-ref boundary char, so it is
  # dual-use-safe: the same `masked` copy feeds both the membership test (below) and the
  # in-block word count (further down), and adjacent-ref counting is unharmed. A pure-digit
  # #NN issue ref carries no hex letter, so it is never masked.
  masked = line
  gsub(hexcolor, " ", masked)
  # Only lines carrying a bare issue reference are in scope.
  if (masked !~ issuere) next

  in_block = (refline > 0 && lineno >= refline)
  if (!in_block) {
    printf "%d:OUTSIDE-BLOCK:%s\n", lineno, line
    next
  }

  # In-block self-describing check: count words that are NOT the issue-reference token.
  # Seed from `masked` (hex spans already blanked) so a hex color present on the line is
  # never counted toward the self-describe word threshold (#2068).
  tmp = masked
  gsub(issuere, " ", tmp)               # remove the issue ref(s)
  gsub(/^[#>*[:space:]-]+/, "", tmp)    # strip leading markdown/list punctuation
  n = split(tmp, parts, /[[:space:]]+/)
  words = 0
  for (i = 1; i <= n; i++) { if (parts[i] ~ /[A-Za-z]/) words++ }
  if (words < minwords) {
    printf "%d:CONTENT-FREE-IN-BLOCK:%s\n", lineno, line
  }
}
