#!/bin/bash
# fragile-ref-patterns.sh — the reference-durability detector constants
#
# This file is the CANONICAL declaration of the seven constants the reference-durability
# detectors evaluate. Every surface named under `Sourced by:` reads it (sourced, never
# executed) at run time, so those surfaces cannot differ: there is one set of bytes, read
# by all of them.
#
# THAT CLAIM IS ABOUT AN ENUMERATED SET, NOT ABOUT THE WHOLE REPOSITORY. A surface that
# declares its own copy sits outside the sourcing set by construction, so "canonical" is
# only as true as the two lists below are complete. For REFBLOCK_RE that completeness is
# asserted mechanically rather than promised here: the identity scan in
# core/hooks/run-fragile-ref-fixtures.sh DISCOVERS declaration sites across the tracked tree
# instead of reading a list of them, and fails the run on any whose value has drifted from
# these bytes; a companion advisory arm reports the same pattern shape carried under a
# different variable name, which is the class a name-anchored probe structurally cannot see.
# The other six constants are covered only by that runner's three-file redeclaration scan,
# so for those the lists below remain a hand-maintained claim. A header asserting sole
# declaration while an unlisted divergent copy existed is exactly the state the identity
# scan now prevents, and it is why the exclusion set below is written down rather than left
# implied.
#
# Sourced by:
#   - core/hooks/block-fragile-refs.sh          (PreToolUse hook)
#   - core/hooks/run-fragile-ref-fixtures.sh    (fixture self-test; deploy.sh Check 31)
#   - .github/workflows/reference-durability.yml (PR-time CI)
#   - core/deploy/tools/check-issue-ref-validity.sh (Issue-reference validity gate, a
#     REQUIRED status check; sources REFBLOCK_RE and fails closed when it is unset)
#
# Deliberately NOT sourced:
#   A surface belongs here only when it answers a DIFFERENT question than the constant it
#   resembles — never because sourcing was merely inconvenient. Each row carries its own
#   reason; a row without one is a defect, not an exemption. Rows are appended below, one
#   per surface, in the form:
#       - <path>:<line>  <local name> — <the different question this surface answers>
#
# core/hooks/lib/positional-issueref.awk is NOT a consumer of this file — it declares
# nothing and receives ISSUEREF_RE / HEXCOLOR_RE / MIN_SELFDESCRIBE_WORDS as `awk -v`
# parameters from whichever surface invokes it. Because every invoker sources this file,
# the awk's parameters are these bytes on every path, by construction.
#
# DECLARATION FORM
#   Plain assignment, NOT `readonly`. A sourced `readonly` cannot be re-sourced and
#   cannot be overridden by a consumer that legitimately needs to (a test harness
#   building a mutant layout). A consumer wanting immutability re-asserts it by bare
#   name after sourcing — block-fragile-refs.sh does exactly that.
#
# INCLUDE GUARD
#   A double-source (directly and transitively) is a no-op rather than an error. This
#   matters under `set -e`: a consumer that re-asserted `readonly` and then re-sourced
#   would abort on the reassignment.
#
# CO-DEPLOYMENT (HARD dependency)
#   Deployed hooks resolve this file at ${HOOK_DIR}/lib/fragile-ref-patterns.sh, which
#   is outside the source tree, so it must be co-deployed beside dep-resolve.sh and
#   positional-issueref.awk. Its absence is fail-closed in enforce per ADR-078 D6 — a
#   detector with empty patterns is not a degraded detector, it is a broken one
#   (an empty ERE matches every line). Every install and sandbox path that materializes
#   a hook layout must copy this file.

if [ -n "${FRAGILE_REF_PATTERNS_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
FRAGILE_REF_PATTERNS_LOADED=1

# Class L — markdown link sequence (fenced code blocks are stripped before scanning).
LINK_RE='\]\('

# Class V — version-cutover apparatus. Keyed on the cutover IDIOM proximate to a version
# token, with bounded windows so a benign sentence naming a version does not match:
#   (a) version token within 40 non-period chars of "merge SHA"
#   (b) version token immediately governing "exempt" (optional release/itself/is)
#   (c) "applies to releases" / "Cutover applies|discipline|per" within 80 chars of a version token
#   (d) the "reflexive-pipeline-loop" cutover idiom
# A bare version label naming the current line ("v2.1 is now current") does NOT match.
CUTOVER_RE='v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?[^.\n]{0,40}merge SHA|v[0-9]+\.[0-9]+[a-z]?(-[a-z0-9-]+)?([[:space:]]+(release|itself|is))*[[:space:]]+(is[[:space:]]+)?exempt|([Aa]pplies to releases|[Cc]utover[[:space:]]+(applies|discipline|per))[^.\n]{0,80}v[0-9]+\.[0-9]+|reflexive-pipeline-loop'

# Class U — raw github.com/<owner>/<repo>/{issues,pull,milestone} URL. A rung-6 reference
# that rots on any repository move/migration. Owner/repo-agnostic so it survives the repo's
# own rename. The terminal anchor ([/#?]|$) is the over-match guard: it matches .../issues/333,
# .../pull/682, .../milestone/3, and the bare .../issues index, but NOT the bare repo URL
# github.com/<owner>/<repo> (no 3rd path segment) and NOT a word like "pullrequest".
URL_RE='github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/(issues|pull|milestone)s?([/#?]|$)'

# Reference-block header (reuses the parser-clean anchor-regex shape; H1-H6, lenient colon).
# Seven recognized spellings: Issue References / References / Related / Provenance /
# Source / Sources / Source(s).
#
# The `Source(s)` arm is spelled out because `[Ss]ources?` matches `Source` and `Sources`
# but NOT `Source(s)`, whose parenthetical then hit the `$` anchor and failed — while the
# issue-ref gate's own failure message, core/ADRs/README.md, and
# core/standards/reference-durability-standard.md all NAME `### Source(s)` as recognized.
# That was a specification-versus-implementation defect, not a policy choice, so the
# implementation is corrected to the stated set.
#
# `Related` is recognized; `Related ADRs` is NOT, and the exclusion is structural rather
# than a promise. `Related ADRs` is a cross-ADR-link section where
# core/standards/adr-authoring-guide.md § Issue references in ADRs forbids a bare issue
# number outright (zone 1); recognizing it would move the placement cut point ABOVE that
# section and make the gates accept exactly the placement the authoring guide prohibits.
# The terminating `$` anchor is what excludes it — the pattern ends immediately after the
# heading word, so `### Related ADRs` cannot match however `Related` is spelled.
REFBLOCK_RE='^#{1,6}[[:space:]]+([Ii]ssue [Rr]eferences|[Rr]eferences|[Rr]elated|[Pp]rovenance|[Ss]ources?|[Ss]ource\(s\))[[:space:]]*:?[[:space:]]*$'

# A bare issue reference: a # followed by digits, optionally bracketed (matches #42, #[42]).
ISSUEREF_RE='#\[?[0-9]+\]?'

# Companion hex-color mask (three ERE branches, no lookbehind): (a) a # + a hex-legal run with
# >=1 hex letter [A-Fa-f] (matches #28A745, #FFF, #0A0); (b) a colon-prefixed hex run
# `:#<3-8 hex digits>` — the CSS/Mermaid color-value form (color:#155724) that catches
# PURE-DIGIT hex colors branch (a) cannot see; (c) the regex CHARACTER-CLASS hex form
# `#[<hex ranges>]` plus an optional {n}/{n,m} quantifier (matches #[0-9a-fA-F]{6}) — the shape
# a documented hex-scan command carries. In (c) the char after # is `[`, so neither (a) nor (b)
# fires and ISSUEREF_RE reads the leading `#[0` as a bracketed ref (issue #4182). Branch (c)
# REQUIRES a well-formed hex range (X-Y) between the brackets — that requirement is what stops
# it swallowing a genuine bracketed ref (#[42] carries no range and still flags). No branch
# matches a prose issue ref (#42 / `#42` / "See #42") — refs carry no hex letter, are never
# colon-abutted, and carry no range. (c) spells its literal brackets/braces as bracket
# expressions ([[] []] [{] [}]) rather than backslash escapes: `awk -v` strips backslashes, so
# a `\[` would not survive assignment as written. Masked to spaces in the shared classifier
# BEFORE the ISSUEREF_RE test so hex-color prefixes (#28) are not read as issue refs (#2068).
HEXCOLOR_RE='(:#[0-9A-Fa-f]{3,8}|#[0-9A-Fa-f]*[A-Fa-f][0-9A-Fa-f]*|#[[][0-9A-Fa-f-]*[0-9A-Fa-f]-[0-9A-Fa-f][0-9A-Fa-f-]*[]]([{][0-9]+(,[0-9]+)?[}])?)'

# Minimum non-reference word count required on an in-block issue-reference line for it to
# count as self-describing (operationalizes the durability-ladder rung-5 "summarize inline").
MIN_SELFDESCRIBE_WORDS=3
