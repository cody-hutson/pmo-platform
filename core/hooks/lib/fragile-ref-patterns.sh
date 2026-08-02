#!/bin/bash
# fragile-ref-patterns.sh — the reference-durability detector constants
#
# This file is the SOLE declaration of the seven constants the reference-durability
# detectors evaluate. It is sourced (not executed) by every surface that runs them, so
# the values cannot differ between surfaces: there is one set of bytes, read by all.
#
# Sourced by:
#   - core/hooks/block-fragile-refs.sh          (PreToolUse hook)
#   - core/hooks/run-fragile-ref-fixtures.sh    (fixture self-test; deploy.sh Check 31)
#   - .github/workflows/reference-durability.yml (PR-time CI)
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
REFBLOCK_RE='^#{1,6}[[:space:]]+([Ii]ssue [Rr]eferences|[Rr]eferences|[Pp]rovenance|[Ss]ources?)[[:space:]]*:?[[:space:]]*$'

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
