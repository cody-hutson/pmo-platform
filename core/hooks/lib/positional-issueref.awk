# positional-issueref.awk — shared positional issue-reference classifier
#
# Reference-durability issue (cross-reference-integrity-ci, issue #314):
# Single source of the positional-#N decision so it cannot drift across the three
# enforcement surfaces. The bare-issue-ref REGEX was already byte-identical across
# {hook, fixture-runner, CI}; only the POSITIONAL logic was hand-reimplemented per
# surface and one copy (the CI) diverged (position-blind existence check vs the hook's
# line-position check). This file makes the positional logic single-sourced too: each
# caller derives the three inputs its own way (its input shapes differ) and calls this
# one classifier for the decision.
#
# Consumed via `awk -f` (NOT sourced as shell) by:
#   - core/hooks/block-fragile-refs.sh        (PreToolUse hook; lines over the stdin payload)
#   - core/hooks/run-fragile-ref-fixtures.sh  (fixture self-test; ISSUEREF-POS class)
#   - .github/workflows/reference-durability.yml (PR-time CI; added lines mapped to file lines)
# `awk -f` is outside the BLOCK-DESTRUCTIVE-022 interpreter set (bash|sh|zsh + source|.),
# so this include needs no script-execution-allowlist entry.
#
# INPUT CONTRACT
#   -v issuere=<ISSUEREF_RE>    the bare-issue-ref regex, passed in (kept byte-identical
#                              to the three callers — this file does NOT own the regex).
#   -v refline=<N>             reference-block header file-line number (0 = no block in file).
#   -v minwords=<MIN>          minimum non-reference words for an in-block ref to count as
#                              self-describing (= MIN_SELFDESCRIBE_WORDS, currently 3).
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
  # Only lines carrying a bare issue reference are in scope.
  if (line !~ issuere) next

  in_block = (refline > 0 && lineno >= refline)
  if (!in_block) {
    printf "%d:OUTSIDE-BLOCK:%s\n", lineno, line
    next
  }

  # In-block self-describing check: count words that are NOT the issue-reference token.
  tmp = line
  gsub(issuere, " ", tmp)               # remove the issue ref(s)
  gsub(/^[#>*[:space:]-]+/, "", tmp)    # strip leading markdown/list punctuation
  n = split(tmp, parts, /[[:space:]]+/)
  words = 0
  for (i = 1; i <= n; i++) { if (parts[i] ~ /[A-Za-z]/) words++ }
  if (words < minwords) {
    printf "%d:CONTENT-FREE-IN-BLOCK:%s\n", lineno, line
  }
}
