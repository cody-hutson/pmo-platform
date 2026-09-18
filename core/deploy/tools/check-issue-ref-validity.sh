#!/usr/bin/env bash
# =============================================================================
# check-issue-ref-validity.sh — the Issue-reference validity gate, invocable.
#
# WHAT THIS IS. The detection logic that backs the `Issue-reference validity
# gate` job in .github/workflows/repo-integrity.yml — a REQUIRED status check on
# main. It used to live as inline bash inside that job's `run:` block, where
# nothing outside the workflow could invoke it and no fixture could exercise it.
# This file is that logic lifted out verbatim, with two seams added and the
# workflow rewired to call it. There is exactly ONE implementation.
#
# THE TWO SEAMS, AND WHY NEITHER IS DISCRETIONARY.
#   * INPUT SELECTION (--base/--head | --path). The CI form scans the added-line
#     delta between two commits. That form cannot be invoked without a git
#     history, so "runs outside CI and produces a verdict without a workflow
#     run" needs a whole-file mode. --path is that mode.
#   * RESOLVER (--resolver gh|fixture). Three of the five verdicts this gate can
#     reach — unresolvable / transferred / pr-number — are properties of the
#     LIVE issue graph. A fixture corpus cannot produce them against `gh api`
#     without depending on the state of a real repository's issues. The fixture
#     resolver reads a static verdict map instead, which is what makes the
#     suite hermetic.
#
# WHY THE BODY IS NOT BYTE-IDENTICAL TO THE BLOCK IT REPLACES. Moving this code
# out of a `.yml` and into a `.sh` moves it ACROSS A GATE BOUNDARY: the
# SIGPIPE-idiom gate scans `*.sh` and explicitly excludes
# `.github/workflows/*.yml`, and it scans an added file WHOLE rather than by
# diff. Four sites in the inline block matched that gate (three
# `printf … | grep -q`, one `grep … | head -1`). They are rewritten here into
# their non-piping equivalents rather than exempted — each was a genuine latent
# hazard, not a false alarm: under `pipefail` the reader exits on its first
# match, the writer's next write fails on the broken pipe, and in an `if`
# condition that inverts to the ELSE branch, i.e. a silently MISSED detection.
#
# Because the source is deliberately not byte-identical, equivalence is asserted
# on the REPORT TEXT, not on the bytes: `--equivalence <pre-sha>` materialises
# the pre-extraction inline body straight out of git, runs it and this checker
# over one shared fixture corpus, and asserts identical report text IN BOTH
# DIRECTIONS — flagging fewer is a WEAKENED gate, flagging more is a
# STRENGTHENED one, and both fail. It carries a sensitivity control (some
# fixture must be non-empty in both, or the comparison is vacuous) and a
# mutation arm (a deliberately perturbed copy must make the differ say
# DISAGREE, or the differ cannot report disagreement at all).
#
# THE REPORT-TEXT CLAIM IS BOUNDED, AND THE BOUNDARY IS DECLARED. It covers
# everything ABOVE the `### Categories` heading — the findings, the `::notice::`
# lines, the verdict, every part of the output a scan result can reach. It does
# NOT cover the static advisory block from that heading to EOF, which is literal
# `echo` with no interpolation and no scan result in it. Diffing that block too
# pinned the gate's own prose to a frozen historical copy of itself, so
# CORRECTING A WRONG SENTENCE IN THE MESSAGE FAILED A CORRECTNESS GATE. The full
# decision, the alternatives rejected, and an honest accounting of what the
# narrowing does and does not buy are recorded at normalize_report(). The
# exclusion is asserted in both directions rather than assumed — a narrowing
# control fails the arm if the cut marker is missing from either side, and an
# inertness arm in run_self_test fails if the excluded region's output DIFFERS
# BETWEEN THAT ARM'S TWO FIXED PROBES — two samples of the finding set, not the
# finding set. That difference is the whole of the arm's reach. It is narrower
# than the exclusion's safety condition and narrower than "varies with the
# finding set": below-cut output the two probes cannot tell apart passes it. The
# residual classes are named at normalize_report() rather than implied away.
#
# WHAT THE EQUIVALENCE OBLIGATION COSTS, AND WHERE NEW ASSERTIONS THEREFORE GO.
# The oracle is a differential over a SHARED corpus, so the corpus is frozen at
# the pre-extraction body's verdicts for as long as the obligation stands. Any
# fixture added to fixtures/issue-ref/{cases,manifest.txt} whose verdict differs
# between that body and this checker fails the arm in the WEAKENED/STRENGTHENED
# direction — REGARDLESS OF WHETHER THE CHANGE IS CORRECT. A behaviour fix is
# exactly such a change, which is why widening the override pattern could not be
# fixtured through the corpus: the pre-extraction body carries the narrow
# pattern, so it FLAGS a rationale-carrying fixture this checker SUPPRESSES.
# Nor can the anchor simply be moved forward — extract_oracle materialises the
# workflow's `run:` block at PRE_EXTRACTION_SHA and dies unless it still
# contains REFBLOCK_RE, which a post-extraction thin caller does not.
# THE PATTERN, for anyone adding a behavioural assertion here: site it as a
# CORPUS-FREE block inside run_self_test that writes its own files under
# $HARNESS_TD and never under $FX_REPO. run_self_test's override-form block is
# the worked example, and the scope-predicate block above it is the precedent.
# Corpus growth stays reserved for behaviour the pre-extraction body ALSO has.
# THE SAME COST HAS AN OUTPUT DIMENSION, and it is now bounded there too. The
# obligation froze the gate's own ADVISORY PROSE as well as its behaviour, so a
# correction to the failure message was as unshippable through this arm as a
# behaviour fix was through the corpus — and unlike the corpus case there was no
# corpus-free siting available, because the message is output the shared run
# EMITS rather than input it consumes. The claim is therefore bounded on the
# output dimension by declaration (see normalize_report), which is the same move
# the retired self-doc fixtures made on the input dimension: state the boundary
# of the equivalence claim rather than suppress a disagreement that is real.
# The corollary for a reader of CI logs: --equivalence has NO gate authority
# there. The selftest-discovery job checks out shallow by design, so
# PRE_EXTRACTION_SHA is unreachable and harness_main prints its SKIP line. The
# arm is blocking only on a full clone, and a SKIP in an evidence trail is a
# NOT-MET, never a pass.
#
# INTERFACE
#   --base <sha> --head <sha>   delta mode: scan lines ADDED between the two
#                               commits (CI parity; what the workflow passes)
#   --path <file>...            whole-file mode: scan every line of each file
#   --resolver gh|fixture       default gh; `fixture` reads a static verdict map
#   --fixture-map <path>        the map consumed by --resolver fixture
#   --self-test                 run the S/Z fixture matrix across all 8 cells
#   --equivalence <pre-sha>     differential run against the pre-extraction body
#
#   exit 0 = no findings · 1 = findings · 3 = input/config failure
#
# BASH 3.2. No `mapfile`, no `${var,,}`, no associative arrays: a gate that can
# only be exercised by a remote CI trigger can only be PROVED by re-implementing
# it, which is the shadow-source failure this extraction exists to end. The
# suite runs on a stock macOS shell.
# =============================================================================
set -euo pipefail

TOOL_NAME="check-issue-ref-validity.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ABSOLUTE, deliberately. The harness re-invokes this file from inside the
# fixture repo, so a relative $0 captured from a relative invocation would stop
# resolving the moment the working directory changes — the suite would fail with
# "no such file" only for whoever happened to type a relative path.
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
FIXTURE_DIR="${SCRIPT_DIR}/fixtures/issue-ref"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$SCRIPT_DIR")"

# The commit this extraction was taken FROM — the last state in which the gate
# body lived inline in .github/workflows/repo-integrity.yml. It is the anchor the
# differential oracle materialises from, and it is deliberately a commit on
# `main` (the release branch's merge-base) rather than a release-branch commit,
# so it stays reachable whatever merge strategy the release takes.
#
# --self-test runs the differential arm WHENEVER this commit is readable, and
# prints an explicit SKIP line when it is not. That keeps the self-test hermetic
# — the CI discovery gate runs it under a SHALLOW checkout with no history — and
# still makes a full checkout (an operator, or any deep clone) exercise the arm
# without a second command.
PRE_EXTRACTION_SHA="81e355884054bb3712551fd79d0c5f481f7360e5"

# Local invocability: the CI-only variables the inline block could assume are
# present must not make the tool unrunnable from a clean shell.
: "${GITHUB_STEP_SUMMARY:=/dev/null}"
: "${GITHUB_REPOSITORY:=}"

die() { printf '%s: %s\n' "$TOOL_NAME" "$1" >&2; exit 3; }

usage() {
  sed -n '/^# INTERFACE$/,/^#   exit 0/p' "$SCRIPT_PATH" | sed -e 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
INPUT_MODE=""
BASE_SHA="${BASE_SHA:-}"
HEAD_SHA="${HEAD_SHA:-}"
PATHS=()
RESOLVER="gh"
FIXTURE_MAP=""
DO_SELF_TEST=0
EQUIV_SHA=""

while [ $# -gt 0 ]; do
  case "$1" in
    --base)         [ $# -ge 2 ] || die "--base needs a value"; BASE_SHA="$2"; INPUT_MODE="delta"; shift 2 ;;
    --head)         [ $# -ge 2 ] || die "--head needs a value"; HEAD_SHA="$2"; INPUT_MODE="delta"; shift 2 ;;
    --path)
      shift
      while [ $# -gt 0 ]; do
        case "$1" in --*) break ;; esac
        PATHS[${#PATHS[@]}]="$1"
        shift
      done
      INPUT_MODE="path"
      ;;
    --resolver)     [ $# -ge 2 ] || die "--resolver needs a value"; RESOLVER="$2"; shift 2 ;;
    --fixture-map)  [ $# -ge 2 ] || die "--fixture-map needs a value"; FIXTURE_MAP="$2"; shift 2 ;;
    --self-test)    DO_SELF_TEST=1; shift ;;
    --equivalence)  [ $# -ge 2 ] || die "--equivalence needs a pre-extraction sha"; EQUIV_SHA="$2"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "unknown argument: $1" ;;
  esac
done

case "$RESOLVER" in
  gh|fixture) : ;;
  *) die "--resolver must be gh or fixture (got: $RESOLVER)" ;;
esac

# =============================================================================
# THE GATE — lifted from .github/workflows/repo-integrity.yml, jobs.issue-ref.
# Every comment below is the original's; the seams are marked SEAM and the four
# rewritten pipelines are marked SIGPIPE-REWRITE with their original form.
# =============================================================================

# The whole-file override marker. The optional `([[:space:]][^>]*)?` group is
# what makes this pattern accept the form the gate's OWN failure message
# mandates and core/standards/adr-authoring-guide.md ratifies under
# § Declaration obligation — a marker carrying a trailing rationale on the same
# line, INSIDE the comment, naming which limb applies. Before that group existed
# the pattern required whitespace-only between the token and the comment close,
# so the compliant rationale-carrying form did not match and did not suppress,
# while the bare form the message calls "a silenced warning, not a declaration"
# was the only form that worked. The regex was the outlier, not the message.
#
# `[^>]` rather than `.` is load-bearing, and was chosen by measurement rather
# than by preference. `.*-->` accepts the rationale but destroys the token
# boundary: it also matches `allow-issue-refX -->`, which is a DIFFERENT token,
# and it runs past the comment close. `[^>]` cannot cross `>`, so the match
# stays bounded to this comment and the token boundary survives. Both arms are
# pinned as assertions in run_self_test's override-form block — must-match for
# the rationale-carrying forms, must-NOT-match for the near misses — because a
# widened pattern that nothing exercises is how the next mismatch ships.
# KNOWN LIMIT, accepted: a rationale containing a literal `>` is rejected. The
# remedy is to reword the rationale; a raw `>` inside an HTML comment is hostile.
#
# DECLARED HERE, DELIBERATELY. This constant is NOT promoted into
# core/hooks/lib/fragile-ref-patterns.sh. That library's canonical constants are
# the ones this gate and the reference-durability gate must compute IDENTICALLY;
# `allow-issue-ref` belongs to repo-integrity alone, and the library's consumers
# neither know nor need it. Widening it there would widen a second required
# status check for no defect.
OVERRIDE='<!--[[:space:]]*repo-integrity:[[:space:]]*allow-issue-ref([[:space:]][^>]*)?-->'
# Designated reference-block headers. SOURCED from the canonical declaration
# in core/hooks/lib/fragile-ref-patterns.sh rather than declared here. This
# gate and the reference-durability gate compute the SAME quantity — the file
# line of the first reference-block header, used as the placement cut point —
# so one question must not have two answers. An inline copy here diverged from
# the canonical value once already; sourcing makes identity structural instead
# of asserted. The recognized-spelling rationale (why `Source(s)` is spelled
# out, why `Related` is recognized and `Related ADRs` is not) lives beside the
# declaration in that file, per the library's stated convention that each
# constant's rationale sits with its declaration.
#
# Guarded exactly as .github/workflows/reference-durability.yml guards its own
# source of the same file, and FAIL-CLOSED for the same reason: an unset
# REFBLOCK_RE is an EMPTY ERE that matches every line, so a missing or
# truncated lib would not weaken this gate — it would make the first line of
# every file look like a reference block and pass misplaced references
# silently. Exit 3 is this file's input/config failure code.
PATTERNS_LIB="${REPO_ROOT}/core/hooks/lib/fragile-ref-patterns.sh"
[ -r "$PATTERNS_LIB" ] || die "detector constants missing or unreadable: $PATTERNS_LIB"
"${BASH:-/bin/bash}" -n "$PATTERNS_LIB" 2>/dev/null || die "detector constants unparseable: $PATTERNS_LIB"
# shellcheck source=../../hooks/lib/fragile-ref-patterns.sh
. "$PATTERNS_LIB"
[ -n "${REFBLOCK_RE:-}" ] || die "REFBLOCK_RE unset after sourcing $PATTERNS_LIB"

CACHE_DIR=""

# SEAM (resolver). The fixture resolver reads a static verdict map keyed by
# number. It exists because unresolvable / transferred / pr-number are
# properties of the live issue graph and cannot otherwise be fixtured.
fixture_verdict() {
  local n="$1" line key rest v=""
  [ -n "$FIXTURE_MAP" ] || die "--resolver fixture requires --fixture-map"
  [ -f "$FIXTURE_MAP" ] || die "fixture map not found: $FIXTURE_MAP"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    key="${line%%[[:space:]]*}"
    rest="${line#*[[:space:]]}"
    if [ "$key" = "$n" ]; then
      v="${rest%%[[:space:]]*}"
      break
    fi
  done < "$FIXTURE_MAP"
  # A number the map does not name is treated as not resolving, which is the
  # same posture the live resolver takes on a 404.
  [ -n "$v" ] || v="unresolvable"
  printf '%s' "$v"
}

# resolve_issue: prints "valid" or a reason token. NO -L (a 3xx is
# unresolvable-in-this-repo). The gh exit code is the precise signal:
#   non-zero (404, or a 3xx redirect that gh will NOT follow) -> the
#   number does not resolve to a 200 issue in this repo -> unresolvable.
# On a genuine 200 (exit 0), the payload is then branched:
#   .pull_request != null -> pr-number (the issues endpoint 200s for PRs);
#   .repository_url not ending in this repo -> transferred (a transfer
#   that returns the destination payload — the NF-2 belt-and-suspenders);
#   otherwise -> valid.
# gh prints a JSON error body to STDOUT on 404 (with .status "404"), so
# branching on the exit code — not on body emptiness — is what keeps a
# 404 from being mis-labeled transferred.
resolve_issue() {
  local n="$1" cf="$CACHE_DIR/$1"
  if [ -f "$cf" ]; then cat "$cf"; return; fi
  local body rc verdict repo_url is_pr
  if [ "$RESOLVER" = "fixture" ]; then
    verdict="$(fixture_verdict "$n")"
  else
    set +e
    body="$(gh api "repos/${GITHUB_REPOSITORY}/issues/${n}" 2>/dev/null)"
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
      verdict="unresolvable"   # 404 or un-followed 3xx
    else
      repo_url="$(printf '%s' "$body" | jq -r '.repository_url // ""' 2>/dev/null || true)"
      is_pr="$(printf '%s' "$body" | jq -r 'if .pull_request == null then "issue" else "pr" end' 2>/dev/null || echo "issue")"
      if [ "$is_pr" = "pr" ]; then
        verdict="pr-number"
      # SIGPIPE-REWRITE. Was: `elif ! printf '%s' "$repo_url" | grep -qE …`.
      # The here-string removes the writer, so there is nothing left to take
      # 141/1 from the broken pipe and silently invert this condition. The
      # empty-haystack difference is inert here: `printf '%s' ""` emits zero
      # lines and `<<<""` emits one empty line, and `/repo$` matches neither.
      elif ! grep -qE "/${GITHUB_REPOSITORY}\$" <<<"$repo_url"; then
        verdict="transferred"
      else
        verdict="valid"
      fi
    fi
  fi
  printf '%s' "$verdict" > "$cf"
  printf '%s' "$verdict"
}

# SEAM (input selection). Which files are in scope.
#   delta -> every changed .md between BASE and HEAD (CI parity)
#   path  -> exactly the files named on the command line
# Is this path TEST DATA rather than corpus prose?
#
# A `.md` under `**/tests/fixtures/**` is an INPUT to a test, not a document anyone
# navigates — the same rule, and deliberately the same words, as
# `release/tools/check-release-links.py`'s `is_test_fixture()`. Its `:365` note ("this
# checker simply had not needed it before, because no fixture markdown had carried a
# link") is exactly this checker's situation: event-log fixtures carry `sub-task:#N`,
# `milestone:#N` and `members:[#1\|…\|#7]` because that IS the schema grammar the
# fixture exists to exercise, and one of them is the D-1 escaped-pipe regression guard
# whose entire point is its bare-pipe count. Reading those `#N` as prose references and
# "fixing" them would corrupt the fixtures the tests depend on.
#
# Deliberately NARROW, mirroring the precedent: BOTH a `tests` and a `fixtures` path
# SEGMENT are required, `fixtures` must FOLLOW `tests`, and `fixtures` must be a
# directory rather than the filename. A `fixtures/` directory with no `tests` ancestor
# is still scanned — which is what keeps THIS gate's own corpus at
# `core/deploy/tools/fixtures/issue-ref/` in scope, and so does not realise the hazard
# named in the header: a gate that exempted its own fixtures would return zero
# vacuously. Both directions are pinned in run_self_test()'s over-skip guard.
#
# The `--equivalence` arm is unaffected: every destination in the shared fixture
# manifest sits under `docs/`, `.github/`, `core/rules/` or `release/releases/`, so
# this predicate is a no-op there and the report text is unchanged in both directions.
#
# Bash 3.2: no `[[ =~ ]]`, no arrays — segment matching by `case` and prefix stripping.
is_test_fixture_path() {
  case "$1" in
    */tests/*|tests/*) : ;;
    *) return 1 ;;
  esac
  local _rest="${1#*tests/}"   # everything after the first `tests/` segment
  _rest="${_rest%/*}"          # drop the filename, so `tests/fixtures.md` cannot match
  case "/${_rest}/" in
    */fixtures/*) return 0 ;;
  esac
  return 1
}

collect_files() {
  if [ "$INPUT_MODE" = "path" ]; then
    if [ "${#PATHS[@]}" -gt 0 ]; then printf '%s\n' "${PATHS[@]}"; fi
  else
    git diff --name-only "$BASE_SHA"..."$HEAD_SHA" -- '*.md' 2>/dev/null || true
  fi
}

# SEAM (input selection). Which LINES of an in-scope file are examined.
#   delta -> NET-NEW DELTA: scan only lines ADDED since the base (the same
#            added-lines posture the reference-durability gate uses), so a
#            pre-existing reference in a file the PR touched for unrelated
#            reasons is never re-flagged. The added text is keyed by its
#            head-file line number.
#   path  -> every line, keyed by its line number.
scan_lines_for() {
  local f="$1"
  if [ "$INPUT_MODE" = "path" ]; then
    awk '{ print NR ":" $0 }' "$f" || true
  else
    git diff --unified=0 "$BASE_SHA"..."$HEAD_SHA" -- "$f" \
      | awk '
        /^@@/ {
          # @@ -a,b +c,d @@ -> new-file hunk starts at c
          plus = $3; sub(/^\+/, "", plus); split(plus, pc, ","); newln = pc[1] + 0; next
        }
        /^\+\+\+/ { next }
        /^\+/ { print newln ":" substr($0, 2); newln++ ; next }
        /^-/ { next }
      ' || true
  fi
  return 0
}

FOUND=0
REPORT=""

run_scan() {
  FOUND=0
  REPORT=""
  # Per-run resolution cache for #N (path under /tmp).
  CACHE_DIR="$(mktemp -d)"

  local f REFBLOCK_HIT REFBLOCK_LINE ADDED_LINES IN_FENCE entry LN line
  local IMPS imp HAS_PROVENANCE NUMS n V

  while IFS= read -r f || [ -n "$f" ]; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    # SCOPE: every changed .md MINUS the ONE surviving PATH exemption.
    #
    # The release-tracking surface stays enumerated because its basis is native
    # PROVENANCE, not a marker: issue and pull-request references are what a
    # ledger IS, and only a minority of that surface's files carry an override
    # marker — so there is no marker population to discover the exemption from,
    # and deriving it would pull hundreds of ledger files into scope. Retained
    # deliberately, not by default.
    #
    # The self-documentation files (this gate's own rules page and the PR
    # template) are NOT enumerated here, and their absence is the point. They
    # are exempt because they CARRY the whole-file override marker, which the
    # `grep -qE "$OVERRIDE"` check a few lines below re-establishes on every
    # single run. The enumeration that used to sit here asserted that same
    # precondition in a trailing comment — and nothing ever evaluated it, so a
    # marker-LESS file at either path stayed silently exempt forever. Discovered
    # rather than enumerated, an exemption cannot outlive its own justification.
    # Both directions are pinned corpus-free in run_self_test()'s `self-doc`
    # block: marker present (bare OR rationale-carrying) -> zero, marker absent
    # -> FLAG.
    case "$f" in
      release/releases/*) continue ;;  # tracking surface (RELEASE_LOG/INDEX/DIGEST/NOTES/plans) — #N + PR-refs are native provenance; exempt, mirroring the reference-durability gate
    esac
    # Test data, not corpus prose — see is_test_fixture_path(). Not a `case` arm
    # because the rule is segment-structural rather than a prefix glob.
    if is_test_fixture_path "$f"; then continue; fi
    # whole-file override
    if grep -qE "$OVERRIDE" "$f"; then
      echo "::notice::repo-integrity issue-ref: a changed file carries allow-issue-ref — skipped." | tee -a "$GITHUB_STEP_SUMMARY"
      continue
    fi

    # locate a designated reference block (first occurrence)
    # SIGPIPE-REWRITE. Was: `grep -nE … "$f" | head -1 | cut -d: -f1`. `-m1`
    # stops the same grep at the same first matching line, and the leading
    # line number is then taken by parameter expansion, so the pipeline —
    # and with it the writer that `head` used to sever — is gone entirely.
    # `grep` reads the FILE, not a producer, so the hazard is removed rather
    # than relocated (which is what `-mN` does when a producer stays upstream).
    REFBLOCK_HIT="$(grep -m1 -nE "$REFBLOCK_RE" "$f" 2>/dev/null || true)"
    REFBLOCK_LINE="${REFBLOCK_HIT%%:*}"
    [ -z "$REFBLOCK_LINE" ] && REFBLOCK_LINE=0

    ADDED_LINES="$(scan_lines_for "$f")"
    [ -z "$ADDED_LINES" ] && continue

    IN_FENCE=0
    while IFS= read -r entry || [ -n "$entry" ]; do
      [ -z "$entry" ] && continue
      LN="${entry%%:*}"
      line="${entry#*:}"
      # fenced code: a ``` on an added line toggles fence state.
      case "$line" in
        '```'*) IN_FENCE=$((1 - IN_FENCE)); continue ;;
      esac
      [ "$IN_FENCE" -eq 1 ] && continue

      # IMP-NNN is always invalid in file content (deprecated).
      # SIGPIPE-REWRITE. Was: `printf '%s' "$line" | grep -qE …`. In an `if`
      # condition this is the exact shape whose broken-pipe status inverts to
      # the else branch — a missed detection, non-deterministically.
      if grep -qE '\bIMP-[0-9]+\b' <<<"$line"; then
        IMPS="$(printf '%s' "$line" | grep -oE '\bIMP-[0-9]+\b' || true)"
        for imp in $IMPS; do
          FOUND=1
          REPORT="${REPORT}${f}:${LN}: ${imp} — deprecated IMP-NNN reference (use a GitHub issue number)"$'\n'
        done
      fi

      # A #N rendered as a markdown link (e.g. [#N](...) or any
      # [text](...N...) whose target is an issue URL) carries an INLINE
      # PROVENANCE MARKER and is exempt from the reference-block placement
      # rule (per the placement spec's inline-marker alternative). The
      # link form is still validity-checked below.
      HAS_PROVENANCE=0
      # SIGPIPE-REWRITE. Was: `printf '%s' "$line" | grep -qE … && HAS_PROVENANCE=1`.
      # The AND-list shape is preserved exactly so `set -e` behaves as before.
      grep -qE '\]\([^)]*\)' <<<"$line" && HAS_PROVENANCE=1

      # #NNNN tokens on this line.
      NUMS="$(printf '%s' "$line" | grep -oE '#[0-9]+' | tr -d '#' || true)"
      [ -z "$NUMS" ] && continue
      for n in $NUMS; do
        V="$(resolve_issue "$n")"
        case "$V" in
          valid)
            # placement: a valid #N must sit inside a designated
            # reference block OR carry an inline provenance marker
            # (a markdown link on the same line).
            if [ "$HAS_PROVENANCE" -eq 0 ] && { [ "$REFBLOCK_LINE" -eq 0 ] || [ "$LN" -lt "$REFBLOCK_LINE" ]; }; then
              FOUND=1
              REPORT="${REPORT}${f}:${LN}: #${n} resolves but is placed outside a designated reference block and carries no inline provenance marker"$'\n'
            fi
            ;;
          unresolvable)
            FOUND=1
            REPORT="${REPORT}${f}:${LN}: #${n} does not resolve to an issue in this repo (404 or redirect)"$'\n'
            ;;
          transferred)
            FOUND=1
            REPORT="${REPORT}${f}:${LN}: #${n} resolves to a DIFFERENT repository (transferred issue)"$'\n'
            ;;
          pr-number)
            FOUND=1
            REPORT="${REPORT}${f}:${LN}: #${n} is a pull-request number, not an issue"$'\n'
            ;;
        esac
      done
    done <<< "$ADDED_LINES"
  done <<< "$(collect_files)"
  rm -rf "$CACHE_DIR"
  return 0
}

emit_verdict() {
  if [ "$FOUND" -eq 0 ]; then
    echo ":white_check_mark: Issue-reference validity — all #N in changed markdown resolve in-repo and sit in reference blocks" | tee -a "$GITHUB_STEP_SUMMARY"
    return 0
  fi

  {
    echo "## :x: Issue-reference validity gate FAILED"
    echo ""
    echo "A changed markdown file references an issue that does not resolve to a real"
    echo "issue IN THIS REPO, or a resolving reference sits outside a designated reference block."
    echo ""
    echo "### Findings (file:line):"
    echo '```'
    printf '%s' "$REPORT"
    echo '```'
    echo ""
    echo "### Categories"
    echo ""
    echo "- **does not resolve / redirect** — a 404 or a redirect to another repo (a transferred issue does not resolve here)."
    echo "- **different repository** — the number resolves to a TRANSFERRED issue now living in another repo."
    echo "- **pull-request number** — the number is a PR, not an issue."
    echo "- **deprecated IMP-NNN** — the legacy improvement id; use a GitHub issue \`#N\`."
    echo "- **placed outside a reference block** — a valid \`#N\` must sit under a recognized heading, at any level: \`Issue References\` / \`References\` / \`Related\` / \`Provenance\` / \`Source\` / \`Sources\` / \`Source(s)\`. In an ADR the designated block is \`## References\`; \`## Related ADRs\` is NOT recognized, because a bare \`#N\` is prohibited there outright."
    echo ""
    echo "### The heading must match EXACTLY"
    echo ""
    echo 'The seven spellings above are matched **exactly**, and this is the constraint a misplaced-reference failure usually hits. **The match ends at the heading word**, so a heading that merely CONTAINS a recognized spelling is not a recognized block. Concretely:'
    echo ""
    echo '- Nothing may follow the heading word but an optional `:`. `## Sources:` is recognized; `## References and Provenance` is NOT — it contains two recognized spellings and is still rejected.'
    echo '- Only the FIRST LETTER of each word may vary in case. `## References` and `## references` are recognized; `## REFERENCES` is NOT.'
    echo '- The word itself must be one of the seven. `## Reference` (singular) is NOT recognized, though `## Source` and `## Sources` both are.'
    echo '- A space is required after the `#` characters. `##References` is NOT recognized.'
    echo ""
    echo 'So the headings a reader reaches for next — `## Related ADRs`, `## References and Provenance`, `## Provenance notes`, `## REFERENCES`, `## Reference`, `##References` — all still fail.'
    echo ""
    echo '**The remedy is to RENAME the heading** to one of the seven spellings, or to move the reference under an existing one. Do not reach for the override marker: it is a rare exception (see below), not the fix for a heading that is merely spelled differently.'
    echo ""
    echo "See [\`core/rules/git-workflow.md\` § Repository-Integrity Gates](../blob/main/core/rules/git-workflow.md) and [\`core/standards/adr-authoring-guide.md\` § Issue references in ADRs](../blob/main/core/standards/adr-authoring-guide.md)."
    echo ""
    echo "### Override — a RARE exception, not the default remedy"
    echo ""
    echo 'Adding the marker `repo-integrity: allow-issue-ref` (wrapped in an HTML comment) anywhere in a file skips this gate for the WHOLE file — placement AND validity, so a 404, a redirect, a transferred issue and a PR number all pass unexamined.'
    echo ""
    echo 'It is warranted only when BOTH limbs hold: (1) the file DISPLAYS an issue-reference construct as its subject matter — self-documentation, a template, a worked example, a test fixture — or its numbers are synthetic / out-of-repo and cannot resolve by construction; AND (2) neither remedy is available — the reference cannot be relocated into a designated reference block, and it cannot be replaced by an inline summary without destroying what the file is for.'
    echo ""
    echo 'A marker declared under this criterion carries a trailing rationale INSIDE the comment naming which limb applies. A bare marker is a silenced warning, not a declaration. Carrying provenance is not demonstration: move the reference into a reference block with a summary noun phrase instead.'
  } | tee -a "$GITHUB_STEP_SUMMARY"
  return 1
}

# =============================================================================
# HARNESS — fixture corpus, the 8-cell matrix, and the differential oracle.
# =============================================================================

HARNESS_TD=""
harness_cleanup() { [ -n "$HARNESS_TD" ] && rm -rf "$HARNESS_TD"; return 0; }

# Sentinel expansion. TRACKED fixtures carry no literal issue token at all —
# `@@REF@@1234` and `@@IMP@@-007` rather than the real spellings — because a
# tracked fixture full of literal references would be flagged by the LIVE gate
# on the very PR that adds it. The obvious fix (give every fixture the
# allow-issue-ref override) is WRONG: it would make the checker's own override
# path fire on every fixture and the whole suite would return zero vacuously.
expand_sentinels() {
  sed -e 's/@@REF@@/#/g' -e 's/@@IMP@@/IMP/g' "$1" > "$2"
}

# Build the fixture git repo. BASE holds the pre-existing state; HEAD holds the
# corpus. A fixture with a `base/` counterpart is MODIFIED between the two
# commits (so its pre-existing content is outside the added-line delta); every
# other fixture is ADDED at HEAD.
FX_REPO=""
FX_BASE=""
FX_HEAD=""
FX_MAP=""
FX_MANIFEST=""

generated_heading_cases() {
  # Z-5 / S-5 crossed: all 7 recognized spellings x all 6 heading levels, each
  # in its OWN file — the checker only ever locates the FIRST reference block,
  # so packing the spellings into one file would test the first and nothing
  # else. Each combination gets a zero arm (reference UNDER the heading) and a
  # flag arm (the same reference ABOVE it), so the specificity assertion always
  # ships with the sensitivity twin that proves the harness ran.
  local spelling level hashes i slug
  for spelling in "Issue References" "References" "Related" "Provenance" "Source" "Sources" "Source(s)"; do
    slug="$(printf '%s' "$spelling" | tr 'A-Z ()' 'a-z---' )"
    for level in 1 2 3 4 5 6; do
      hashes=""
      i=0
      while [ "$i" -lt "$level" ]; do hashes="${hashes}#"; i=$((i + 1)); done
      printf '%s\t%s\t%s\t%s\n' "$slug" "$level" "$hashes" "$spelling"
    done
  done
}

build_fixture_repo() {
  local td="$1" line class src dest ed ep body
  FX_REPO="$td/repo"
  mkdir -p "$FX_REPO"
  git -C "$FX_REPO" init -q
  git -C "$FX_REPO" config user.email "fixtures@example.invalid"
  git -C "$FX_REPO" config user.name "issue-ref fixture harness"
  git -C "$FX_REPO" config commit.gpgsign false

  # ---- BASE commit -------------------------------------------------------
  mkdir -p "$FX_REPO/docs"
  printf 'seed\n' > "$FX_REPO/docs/.seed.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    src="$(printf '%s' "$line" | cut -d'|' -f2)"
    dest="$(printf '%s' "$line" | cut -d'|' -f3)"
    if [ -f "${FIXTURE_DIR}/base/${src}" ]; then
      mkdir -p "$FX_REPO/$(dirname "$dest")"
      expand_sentinels "${FIXTURE_DIR}/base/${src}" "$FX_REPO/$dest"
    fi
  done < "$FX_MANIFEST"
  git -C "$FX_REPO" add -A
  git -C "$FX_REPO" commit -q -m "fixture base"
  FX_BASE="$(git -C "$FX_REPO" rev-parse HEAD)"

  # ---- HEAD commit -------------------------------------------------------
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    src="$(printf '%s' "$line" | cut -d'|' -f2)"
    dest="$(printf '%s' "$line" | cut -d'|' -f3)"
    mkdir -p "$FX_REPO/$(dirname "$dest")"
    expand_sentinels "${FIXTURE_DIR}/cases/${src}" "$FX_REPO/$dest"
  done < "$FX_MANIFEST"

  # Generated heading matrix (42 combinations x 2 arms).
  mkdir -p "$FX_REPO/docs/headings"
  local slug level hashes spelling
  while IFS=$'\t' read -r slug level hashes spelling; do
    [ -n "$slug" ] || continue
    body="$FX_REPO/docs/headings/zero-${slug}-${level}.md"
    {
      printf 'Heading matrix fixture — zero arm.\n\n'
      printf '%s %s\n' "$hashes" "$spelling"
      printf '\n- #909100 — the reference sits UNDER the recognized heading.\n'
    } > "$body"
    body="$FX_REPO/docs/headings/flag-${slug}-${level}.md"
    {
      printf 'Heading matrix fixture — sensitivity twin.\n\n'
      printf -- '- #909100 — the reference sits ABOVE the recognized heading.\n\n'
      printf '%s %s\n' "$hashes" "$spelling"
    } > "$body"
  done <<< "$(generated_heading_cases)"

  git -C "$FX_REPO" add -A
  git -C "$FX_REPO" commit -q -m "fixture head"
  FX_HEAD="$(git -C "$FX_REPO" rev-parse HEAD)"
  return 0
}

# A `gh` test double. It is what lets the `--resolver gh` CODE PATH — the one
# CI actually runs — be exercised hermetically, and it is what lets the
# PRE-EXTRACTION ORACLE, which knows only `gh api`, run against the same corpus
# without touching a live issue graph.
write_gh_shim() {
  local dir="$1"
  mkdir -p "$dir"
  {
    echo '#!/usr/bin/env bash'
    echo 'set -eu'
    echo '[ "${1:-}" = "api" ] || exit 1'
    echo 'ep="${2:-}"; n="${ep##*/}"'
    echo 'v="$(awk -v k="$n" '"'"'$1==k {print $2}'"'"' "$FIXTURE_VERDICT_MAP")"'
    echo '[ -n "$v" ] || v="unresolvable"'
    echo 'case "$v" in'
    echo '  unresolvable) printf "{\"message\":\"Not Found\",\"status\":\"404\"}\n"; exit 1 ;;'
    echo '  pr-number)    printf "{\"repository_url\":\"https://api.github.com/repos/%s\",\"pull_request\":{\"url\":\"x\"}}\n" "$GITHUB_REPOSITORY"; exit 0 ;;'
    echo '  transferred)  printf "{\"repository_url\":\"https://api.github.com/repos/other-owner/other-repo\",\"pull_request\":null}\n"; exit 0 ;;'
    echo '  *)            printf "{\"repository_url\":\"https://api.github.com/repos/%s\",\"pull_request\":null}\n" "$GITHUB_REPOSITORY"; exit 0 ;;'
    echo 'esac'
  } > "$dir/gh"
  chmod +x "$dir/gh"
  return 0
}

# bash 3.2 has no `mapfile`; the pre-extraction body uses it. The prelude is a
# SEPARATE file sourced ahead of the oracle so the oracle's own bytes stay
# exactly what `git show` produced — the shim is a host-compatibility layer,
# never an edit to the thing under test. Where `mapfile` is a builtin (any CI
# runner) the prelude is inert.
write_oracle_prelude() {
  {
    echo 'if ! type mapfile >/dev/null 2>&1; then'
    echo '  mapfile() {'
    echo '    local _t=0 _name="" _line'
    echo '    while [ $# -gt 0 ]; do'
    echo '      case "$1" in -t) _t=1; shift ;; -*) shift ;; *) _name="$1"; shift ;; esac'
    echo '    done'
    echo '    eval "$_name=()"'
    echo '    while IFS= read -r _line || [ -n "$_line" ]; do'
    echo '      eval "$_name[\${#$_name[@]}]=\"\$_line\""'
    echo '    done'
    echo '    return 0'
    echo '  }'
    echo 'fi'
  } > "$1"
  return 0
}

# Materialise the pre-extraction inline body straight out of git. It is
# EXTRACTED, never kept as a tracked copy: a tracked copy would owe its own
# allowlist rows, would enter the SIGPIPE gate's scope itself, and would be free
# to drift from the thing it claims to represent. Extraction makes "the oracle
# IS the pre-extraction implementation" a mechanical fact.
extract_oracle() {
  local pre_sha="$1" out="$2" wf="$3"
  # Braced expansion is load-bearing: an unbraced "${rev}:path" is silently
  # mangled by zsh's colon modifier and yields a false MISSING.
  git -C "$REPO_ROOT" show "${pre_sha}:.github/workflows/repo-integrity.yml" > "$wf" \
    || die "cannot read the workflow at ${pre_sha}"
  awk '
    /^  issue-ref:/            { injob = 1; next }
    injob && /^  [a-z]/        { injob = 0 }
    injob && /^        run: \|$/ { inrun = 1; next }
    inrun {
      if ($0 == "") { print ""; next }
      if ($0 ~ /^          /) { sub(/^          /, "", $0); print; next }
      inrun = 0
    }
  ' "$wf" > "$out"
  [ -s "$out" ] || die "oracle extraction produced nothing at ${pre_sha}"
  grep -q 'REFBLOCK_RE' "$out" || die "oracle extraction did not capture the gate body at ${pre_sha}"
  return 0
}

# Findings lines only, sorted — the set the equivalence claim is about.
findings_of() {
  grep -E '^[^[:space:]]+:[0-9]+: ' "$1" 2>/dev/null | LC_ALL=C sort || true
}

# The line the report-text equivalence claim is cut at, and the marker that
# replaces everything below it. Both awk programs below READ this constant rather
# than repeating the literal, so the cut is single-sourced and the two programs
# cannot drift apart from each other; the value is consumed as an awk DYNAMIC
# REGEX (`$0 ~ cut`), so it is an ERE, not a grep BRE.
ADVISORY_CUT_LINE='^### Categories$'
ADVISORY_CUT_MARKER='@@ADVISORY-BLOCK-EXCLUDED-FROM-EQUIVALENCE@@'

# ─── THE EQUIVALENCE CLAIM'S OUTPUT BOUNDARY, AND WHY IT IS DRAWN HERE ────────
# DECISION RECORDED AT THE SITE, deliberately and by ratification: the narrowing
# below was considered for an ADR and judged not to need one, so the reasoning
# lives beside the code it governs rather than in a record a reader has to find.
#
# THE PROBLEM. run_equivalence used to diff the WHOLE output of the two
# implementations. That output is two different kinds of text welded together:
# everything ABOVE `### Categories` is scan-dependent (the findings, the
# `::notice::` lines, the verdict), and everything BELOW it is static advisory
# prose — a literal `echo` per line, no interpolation, no scan result anywhere.
# Diffing the whole thing pinned the prose as tightly as the behaviour, so
# CORRECTING A WRONG SENTENCE IN THE MESSAGE FAILED A CORRECTNESS GATE. That is
# what happened to the exact-match paragraph in emit_verdict: every findings arm
# and the exit-code arm agreed, and only the prose differed.
#
# WHY NOT THE OBVIOUS ALTERNATIVES. Emitting the new text to GITHUB_STEP_SUMMARY
# only would pass the arm by hiding the fix from the local reader (that variable
# defaults to /dev/null outside CI) — green by concealment. Re-pinning
# PRE_EXTRACTION_SHA forward is structurally blocked: extract_oracle dies unless
# the materialised `run:` block still contains REFBLOCK_RE, which a
# post-extraction thin caller does not. Dropping the whole-output diff entirely
# is over-broad — it also pins the `::notice::` lines, which ARE scan-dependent.
#
# WHAT THE NARROWING GIVES UP, STATED PLAINLY RATHER THAN CLAIMED AWAY. The
# byte-diff never proved the advisory prose was CORRECT; it proved the prose
# matched a frozen historical copy of itself. What replaces it for the placement
# bullet is strictly stronger — run_self_test's exact-match block asserts that
# each heading the message calls unrecognized is in fact flagged and each it
# calls recognized is in fact accepted, so message and implementation can no
# longer drift. That replacement is NOT uniform across the region, and the
# honest accounting matters more than a tidy claim: the other four verdict-class
# bullets, the two doc links and the whole Override criterion below the cut keep
# only a PRESENCE assertion (exact-match block, Arm 3), not a behavioural one.
# They are prose whose only previous pin was a frozen copy, so nothing that was
# load-bearing has been dropped — but "re-pinned to behaviour" would overstate
# what this bought, and an overstated record is the artifact most likely to
# mislead the next reader asking whether this was weakened deliberately.
#
# THE EXCLUSION IS ASSERTED, NEVER ASSUMED, IN TWO DIRECTIONS.
#   * That it FIRED — the narrowing control in run_equivalence fails the arm if
#     the cut marker is missing from either side, so a normalizer that silently
#     no-ops cannot read as a pass.
#   * That the excluded region is STILL INERT BETWEEN TWO FIXED FINDING SETS —
#     the inertness arm in run_self_test runs the checker over two inputs with
#     DIFFERENT findings and requires their post-cut regions to be byte-identical
#     while their pre-cut regions differ. Inertness is the property that justifies
#     the cut, and a point-in-time reading of the region is not a guarantee; if
#     that region ever starts emitting output that DIFFERS BETWEEN THOSE TWO
#     PROBES, that arm turns red instead of the exclusion silently widening.
#     Output that varies with the finding set in a way the two probes do not
#     distinguish does not turn it red; the next paragraph names that output.
#
# WHAT THAT ARM DOES NOT REACH, NAMED RATHER THAN LEFT TO BE DISCOVERED. Its
# discriminator is a byte difference between two SAMPLES of the finding set, not
# variation across the finding set. The exclusion's safety condition is the
# stronger property that no below-cut output can DIFFER BETWEEN THE TWO
# IMPLEMENTATIONS, and three classes of below-cut output sit in the gap. Each was
# measured, not reasoned, by one line added directly below the `### Categories`
# emission, after which the arm passed at inertness=1 and the suite reported
# SELF-TEST RESULT: PASS at exit 0:
#   (1) CONSTANT across finding sets. `echo "${REFBLOCK_RE}"` is byte-identical in
#       both of the arm's runs — while the checker emits a below-cut line the
#       oracle does not emit at all, interpolating a live implementation value.
#       Varying the arm's inputs cannot close this: a constant is constant, so no
#       input dimension makes it differ between two runs.
#   (2) VARYING WITH THE FINDING SET BUT EQUAL ON BOTH PROBES. A line printing the
#       count of misplaced-reference findings prints 1 on each probe, since each
#       carries one, and 2 on an input carrying two.
#   (3) KEYED TO A FINDING CLASS NEITHER PROBE CARRIES. A hint printed only when a
#       pull-request-number finding exists prints nothing on either probe, and so
#       does one keyed to a transferred-issue finding.
# The boundary was measured from the inside as well: a line printing the count of
# unresolvable-reference findings — the same shape as (2), on a class probe B
# carries and probe A does not — prints 0 and 1 and turns the arm red, as does
# interpolating the whole findings list. The report-text arm cannot see (1)-(3)
# either, because that region is excluded from the diff by declaration. More
# probes would narrow (2) and (3) but cannot close them, because a below-cut
# emission can be keyed to any property every probe happens to share. The one arm
# that WOULD close all three is a below-cut diff between the oracle and this
# checker — which is the whole-output diff this narrowing exists to remove, and
# reinstating it reinstates the defect above. So the residual is ACCEPTED and
# recorded here, the same accounting this block already makes for Arm 3's
# presence-only pinning: the exclusion is armed against the class the arm
# measures, and rests on review for the classes it does not.
#
# INVOCATION FORM IS LOAD-BEARING, NOT STYLISTIC. awk reads the FILE and no
# producer sits upstream, and the program carries no `exit`. The shape this
# avoids — `… | awk '/marker/{print; exit}'` — is a pipe into a reader that stops
# early, inside a file running under `set -euo pipefail`: the reader exits on the
# marker, the writer's next write fails on the broken pipe, and that non-zero
# status becomes the pipeline's, so a SUCCESSFUL truncation reports failure. It
# is also the exact shape this repository's SIGPIPE-idiom gate scans for on added
# lines in `*.sh`, and this file carries no exemption of either tier. Both the
# single-line and multi-line spellings of that shape are wrong here and
# differently so: one turns an enforcing job red, and the other slips past its
# line-oriented scan while keeping the runtime hazard. Reading the file removes
# the hazard rather than relocating it — the same SIGPIPE-REWRITE reasoning the
# header records for the four pipelines rewritten at extraction.
normalize_report() {
  awk -v marker="$ADVISORY_CUT_MARKER" -v cut="$ADVISORY_CUT_LINE" '
    past      { next }
    $0 ~ cut  { print marker; past = 1; next }
              { print }
  ' "$1" > "$2"
}

# The complement: the excluded region itself, cut line included. Used only by the
# inertness arm, which is the thing that keeps the exclusion honest.
advisory_block_of() {
  awk -v cut="$ADVISORY_CUT_LINE" '
    inblk     { print }
    $0 ~ cut  { if (!inblk) { print; inblk = 1 } }
  ' "$1" > "$2"
}

run_equivalence() {
  local pre_sha="$1"
  local td="$HARNESS_TD"
  local bin="$td/bin" oracle="$td/oracle.body.sh" prelude="$td/oracle.prelude.sh"
  local wf="$td/pre-workflow.yml"
  local mutant="$td/mutant.sh"
  local o_out="$td/oracle.out" c_out="$td/checker.out" m_out="$td/mutant.out"
  local o_set="$td/oracle.set" c_set="$td/checker.set" m_set="$td/mutant.set"
  local only_o only_c rc_o rc_c rc_m status=0

  extract_oracle "$pre_sha" "$oracle" "$wf"
  write_oracle_prelude "$prelude"
  write_gh_shim "$bin"

  export FIXTURE_VERDICT_MAP="$FX_MAP"
  export GITHUB_REPOSITORY="fixture-owner/fixture-repo"
  export GH_TOKEN="fixture-token"
  export PATH="$bin:$PATH"

  echo "--- differential equivalence: oracle @ ${pre_sha}  vs  ${TOOL_NAME} ---"
  echo "    corpus: ${FX_BASE} ... ${FX_HEAD}  (delta mode, gh resolver via test double)"

  set +e
  ( cd "$FX_REPO" && GITHUB_STEP_SUMMARY=/dev/null BASE_SHA="$FX_BASE" HEAD_SHA="$FX_HEAD" \
      bash -c 'set -euo pipefail; . "$1"; . "$2"' _ "$prelude" "$oracle" ) > "$o_out" 2>&1
  rc_o=$?
  ( cd "$FX_REPO" && GITHUB_STEP_SUMMARY=/dev/null \
      bash "$SCRIPT_PATH" --base "$FX_BASE" --head "$FX_HEAD" --resolver gh ) > "$c_out" 2>&1
  rc_c=$?
  set -e

  findings_of "$o_out" > "$o_set"
  findings_of "$c_out" > "$c_set"

  # Sensitivity control. A suite where both sides return empty is byte-identical
  # and proves nothing at all.
  if [ ! -s "$o_set" ]; then
    echo "FAIL  sensitivity control: the oracle produced ZERO findings — the comparison is vacuous"
    return 1
  fi
  echo "PASS  sensitivity control: oracle findings = $(wc -l < "$o_set" | tr -d ' ') (non-empty in both implementations)"

  # Both directions. Fewer = the gate was WEAKENED; more = it was STRENGTHENED.
  only_o="$(LC_ALL=C comm -23 "$o_set" "$c_set")"
  only_c="$(LC_ALL=C comm -13 "$o_set" "$c_set")"
  if [ -n "$only_o" ]; then
    echo "FAIL  direction oracle->checker: the checker flags FEWER (gate WEAKENED):"
    printf '%s\n' "$only_o" | sed 's/^/        /'
    status=1
  else
    echo "PASS  direction oracle->checker: no finding the oracle reports is missing from the checker"
  fi
  if [ -n "$only_c" ]; then
    echo "FAIL  direction checker->oracle: the checker flags MORE (gate STRENGTHENED):"
    printf '%s\n' "$only_c" | sed 's/^/        /'
    status=1
  else
    echo "PASS  direction checker->oracle: the checker reports no finding the oracle does not"
  fi

  if [ "$rc_o" -ne "$rc_c" ]; then
    echo "FAIL  exit codes differ: oracle=${rc_o} checker=${rc_c}"
    status=1
  else
    echo "PASS  exit codes agree: ${rc_o}"
  fi

  # REPORT TEXT, narrowed by declaration to everything ABOVE the static advisory
  # block. The boundary, what it gives up and what re-pins it are recorded at
  # normalize_report(); this is only its application.
  local o_norm="$td/oracle.norm" c_norm="$td/checker.norm"
  normalize_report "$o_out" "$o_norm"
  normalize_report "$c_out" "$c_norm"
  # NARROWING CONTROL, and it is mandatory. A normalizer that silently no-opped —
  # wrong cut line, empty input, a report that never reached the advisory block —
  # would make this arm compare two untruncated reports and call that a narrowed
  # comparison. Requiring the marker on BOTH sides is what makes the exclusion an
  # assertion rather than an assumption. It fails conservatively: the two ways the
  # marker can go missing (oracle emitted nothing, checker emitted nothing) are
  # already caught upstream by the sensitivity control, so a failure here is a
  # normalizer fault and is reported as one.
  if ! grep -q "$ADVISORY_CUT_MARKER" "$o_norm" || ! grep -q "$ADVISORY_CUT_MARKER" "$c_norm"; then
    echo "FAIL  narrowing control: the advisory-block cut marker is absent from one or both sides"
    echo "      the exclusion did not fire, so a PASS here would be an untested claim"
    status=1
  elif diff -u "$o_norm" "$c_norm" > "$td/report.diff" 2>&1; then
    echo "PASS  report text identical OUTSIDE the advisory block (\`### Categories\` -> EOF, excluded by declaration)"
  else
    echo "FAIL  report text differs OUTSIDE the advisory block:"
    sed 's/^/        /' "$td/report.diff"
    status=1
  fi

  # MUTATION ARM — the broken-probe guard. Without it, a differ that silently
  # compares "" to "" (wrong path, empty corpus, oracle failed to materialise)
  # passes green. One regex character is altered; the differ MUST say DISAGREE.
  sed -e "s/'\\\\bIMP-\[0-9\]+\\\\b'/'\\\\bIMPX-[0-9]+\\\\b'/g" "$SCRIPT_PATH" > "$mutant"
  if cmp -s "$SCRIPT_PATH" "$mutant"; then
    echo "FAIL  mutation arm: the perturbation did not change the checker — the arm is inert"
    return 1
  fi
  # The mutant is a byte-derived copy living in $td, so ITS SCRIPT_DIR — and with it the
  # REPO_ROOT fallback — resolves to $td, not to the repo. Materialise the constants lib at
  # the offset the mutant will look for, so the perturbed copy exercises the SAME sourcing
  # path the real script does. Without it the mutant would die at the fail-closed guard and
  # the arm would report DISAGREE for the wrong reason — a dead mutant is not a perturbed
  # one. This is a host-compatibility shim in the write_oracle_prelude sense: it makes the
  # copy runnable where it stands and never edits the thing under test.
  mkdir -p "$td/core/hooks/lib"
  cp "$PATTERNS_LIB" "$td/core/hooks/lib/fragile-ref-patterns.sh"
  set +e
  ( cd "$FX_REPO" && GITHUB_STEP_SUMMARY=/dev/null \
      bash "$mutant" --base "$FX_BASE" --head "$FX_HEAD" --resolver gh ) > "$m_out" 2>&1
  rc_m=$?
  set -e
  findings_of "$m_out" > "$m_set"
  if LC_ALL=C diff -q "$o_set" "$m_set" >/dev/null 2>&1; then
    echo "FAIL  mutation arm: differ reported AGREE against a deliberately perturbed checker"
    echo "      the differ cannot report disagreement, so its AGREE above is worthless"
    status=1
  else
    echo "PASS  mutation arm: differ reports DISAGREE against the perturbed checker"
    echo "      (perturbed regex dropped $(LC_ALL=C comm -23 "$o_set" "$m_set" | wc -l | tr -d ' ') finding(s) the oracle reports; mutant exit=${rc_m})"
  fi

  return "$status"
}

# The 8-cell matrix: 2 invocation forms x 2 input modes x 2 resolvers.
run_cell() {
  local form="$1" input="$2" resolver="$3" out="$4"
  local files=""
  if [ "$input" = "path" ]; then
    files="$(cd "$FX_REPO" && git ls-files '*.md')"
  fi
  set +e
  if [ "$form" = "ci" ]; then
    # The CI invocation form: the workflow's own env binding, the workflow's
    # own argument string.
    if [ "$input" = "delta" ]; then
      ( cd "$FX_REPO" && GH_TOKEN=fixture-token GITHUB_REPOSITORY=fixture-owner/fixture-repo \
          GITHUB_STEP_SUMMARY="$HARNESS_TD/step-summary.md" BASE_SHA="$FX_BASE" HEAD_SHA="$FX_HEAD" \
          bash "$SCRIPT_PATH" --base "$FX_BASE" --head "$FX_HEAD" --resolver "$resolver" --fixture-map "$FX_MAP" ) > "$out" 2>&1
    else
      ( cd "$FX_REPO" && GH_TOKEN=fixture-token GITHUB_REPOSITORY=fixture-owner/fixture-repo \
          GITHUB_STEP_SUMMARY="$HARNESS_TD/step-summary.md" \
          bash "$SCRIPT_PATH" --resolver "$resolver" --fixture-map "$FX_MAP" --path $files ) > "$out" 2>&1
    fi
  else
    # Direct local invocation: no CI environment at all. This is AC-1 — a
    # verdict without a workflow run.
    if [ "$input" = "delta" ]; then
      ( cd "$FX_REPO" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
          GITHUB_REPOSITORY=fixture-owner/fixture-repo \
          bash "$SCRIPT_PATH" --base "$FX_BASE" --head "$FX_HEAD" --resolver "$resolver" --fixture-map "$FX_MAP" ) > "$out" 2>&1
    else
      ( cd "$FX_REPO" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
          GITHUB_REPOSITORY=fixture-owner/fixture-repo \
          bash "$SCRIPT_PATH" --resolver "$resolver" --fixture-map "$FX_MAP" --path $files ) > "$out" 2>&1
    fi
  fi
  local rc=$?
  set -e
  return "$rc"
}

run_self_test() {
  local td="$HARNESS_TD"
  local bin="$td/bin"
  local form input resolver cell out expect line class src dest ed ep want got
  local cells_run=0 assertions=0 failures=0

  write_gh_shim "$bin"
  export FIXTURE_VERDICT_MAP="$FX_MAP"
  export PATH="$bin:$PATH"

  # ── Test-fixture path exclusion, with its own over-skip guard ──────────────
  # A skip that is not itself tested can broaden silently and swallow a real
  # reference, so BOTH directions are pinned: what MUST be excluded, and what must
  # NOT be. Mirrors check-release-links.py's guard, including its own cases.
  local p
  echo "--- scope predicate: is_test_fixture_path, both arms ---"
  for p in \
    release/tools/tests/fixtures/event-record/log-clean.md \
    release/tools/tests/fixtures/event-record/log-escapedpipe-clean.md \
    core/deploy/tests/fixtures/nested/deep/y.md \
    tests/fixtures/top-level.md \
    a/tests/sub/fixtures/deep.md ; do
    assertions=$((assertions + 1))
    if ! is_test_fixture_path "$p"; then
      echo "    FAIL  [scope] expected test-fixture markdown to be excluded: $p"
      failures=$((failures + 1))
    fi
  done
  # Over-skip guard — corpus prose that MUST still be scanned. The last entry is
  # this gate's OWN fixture corpus: it carries a `fixtures` segment but no `tests`
  # ancestor, so it stays in scope. That is the header's "the whole suite would
  # return zero vacuously" hazard, pinned as an assertion rather than reasoned about.
  for p in \
    release/references/pipeline/stage-06-engineering.md \
    core/disciplines/architecture-overview.md \
    release/tools/tests/README.md \
    docs/fixtures/setup.md \
    release/tools/tests/fixtures.md \
    core/deploy/tools/fixtures/issue-ref/cases/z1-override.md ; do
    assertions=$((assertions + 1))
    if is_test_fixture_path "$p"; then
      echo "    FAIL  [scope] corpus markdown wrongly excluded as a fixture (over-skip): $p"
      failures=$((failures + 1))
    fi
  done
  if [ "$failures" -eq 0 ]; then
    echo "    PASS  [scope]  must-exclude=5  must-scan=6"
  fi

  # ── Override-marker FORM: the OVERRIDE predicate, both arms, plus an
  #    end-to-end pair ────────────────────────────────────────────────────────
  # CORPUS-FREE BY CONSTRUCTION, and that siting is load-bearing rather than
  # stylistic. run_equivalence asserts the report text is IDENTICAL ABOVE THE
  # ADVISORY BLOCK (the declared boundary; see normalize_report) between this
  # checker and the pre-extraction inline body over the SHARED fixture corpus —
  # and findings are above that boundary, so the constraint below is unchanged by
  # the narrowing. That body carries the OLD narrow OVERRIDE, so a rationale-carrying
  # fixture added to cases/ + manifest.txt would be FLAGGED by the oracle and
  # SUPPRESSED by the checker — `direction oracle->checker: gate WEAKENED` — and
  # the required status check would fail ON A CORRECT FIX. Re-pinning the oracle
  # forward is not an escape either: extract_oracle materialises the workflow's
  # `run:` block at PRE_EXTRACTION_SHA and dies unless it still contains
  # REFBLOCK_RE, which a post-extraction thin caller does not.
  # Therefore every file written below lives under $td and NEVER under $FX_REPO,
  # and fixtures/issue-ref/cases/z1-override.md deliberately keeps the BARE
  # form. The corpus README states the same rule from the other side: do not add
  # the whole-file override marker to any fixture except z1-override.md.
  local om_dir="$td/override-form"
  local om_f om_out om_rc om_match=0 om_nomatch=0 om_e2e=0 om_fail=0
  mkdir -p "$om_dir"
  echo "--- override-marker form: OVERRIDE predicate (both arms) + end-to-end pair ---"

  # Arm 1 — MUST match. Entry 1 is the bare form (all the shipped narrow pattern
  # ever accepted); entries 3-5 are the rationale-carrying forms that
  # core/standards/adr-authoring-guide.md § Declaration obligation ratifies and
  # this gate's own failure message instructs an author to write. Asserted
  # through the SAME `grep -qE "$OVERRIDE"` call the production override check
  # makes, so the assertion cannot drift from the thing it asserts.
  for om_f in \
    '<!-- repo-integrity: allow-issue-ref -->' \
    '<!--repo-integrity:allow-issue-ref-->' \
    '<!-- repo-integrity: allow-issue-ref — limb 1: synthetic ids, cannot resolve by construction -->' \
    '<!-- repo-integrity: allow-issue-ref - limb 2: worked example, cannot be relocated -->' \
    '<!-- repo-integrity: allow-issue-ref (limb 1: this file displays the construct) -->' ; do
    assertions=$((assertions + 1))
    printf '%s\n' "$om_f" > "$om_dir/probe.md"
    if grep -qE "$OVERRIDE" "$om_dir/probe.md"; then
      om_match=$((om_match + 1))
    else
      echo "    FAIL  [override-form] declared marker form did NOT match OVERRIDE: $om_f"
      om_fail=$((om_fail + 1)); failures=$((failures + 1))
    fi
  done

  # Arm 2 — MUST NOT match. This arm is what keeps the widening honest: it is
  # the card's own "the fixture asserting the narrow case still fires". Entries
  # 1-2 are the token-boundary near misses that a `.*-->` widening would wrongly
  # accept — `allow-issue-refX` is a DIFFERENT token. Entry 3 is the token in
  # prose/backticks with no comment delimiters. Entries 4-5 are the wrong marker
  # and the wrong namespace: `allow-link` belongs to reference-durability, and
  # `reference-durability: allow-issue-ref` is a spelling no gate recognizes.
  for om_f in \
    '<!-- repo-integrity: allow-issue-refX -->' \
    '<!-- repo-integrity: allow-issue-refX: limb 1 -->' \
    '`repo-integrity: allow-issue-ref`' \
    '<!-- repo-integrity: allow-link -->' \
    '<!-- reference-durability: allow-issue-ref -->' ; do
    assertions=$((assertions + 1))
    printf '%s\n' "$om_f" > "$om_dir/probe.md"
    if grep -qE "$OVERRIDE" "$om_dir/probe.md"; then
      echo "    FAIL  [override-form] non-canonical form wrongly matched OVERRIDE (over-wide): $om_f"
      om_fail=$((om_fail + 1)); failures=$((failures + 1))
    else
      om_nomatch=$((om_nomatch + 1))
    fi
  done

  # Arm 3 — END TO END. The predicate arms prove the regex; this proves the
  # GATE. Subject and control are byte-identical but for the marker line.
  {
    printf '%s\n' '<!-- repo-integrity: allow-issue-ref — limb 1: synthetic ids, cannot resolve by construction -->'
    printf 'Override end-to-end fixture — subject arm.\n\n'
    printf -- '- #909501 — does not resolve, and sits above any reference block.\n'
  } > "$om_dir/subject.md"
  {
    printf 'Override end-to-end fixture — control arm.\n\n'
    printf -- '- #909501 — does not resolve, and sits above any reference block.\n'
  } > "$om_dir/control.md"

  assertions=$((assertions + 1))
  set +e
  om_out="$( cd "$om_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
      GITHUB_REPOSITORY=fixture-owner/fixture-repo \
      bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path subject.md 2>&1 )"
  om_rc=$?
  set -e
  if [ "$om_rc" -eq 0 ]; then
    om_e2e=$((om_e2e + 1))
  else
    echo "    FAIL  [override-form] e2e: the rationale-carrying marker did NOT suppress (exit ${om_rc})"
    printf '%s\n' "$om_out" | sed -e 's/^/            /'
    om_fail=$((om_fail + 1)); failures=$((failures + 1))
  fi

  # CONTROL, and it is mandatory. Without it the zero above proves nothing: it
  # would read exactly the same if the gate had simply stopped detecting.
  assertions=$((assertions + 1))
  set +e
  om_out="$( cd "$om_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
      GITHUB_REPOSITORY=fixture-owner/fixture-repo \
      bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path control.md 2>&1 )"
  om_rc=$?
  set -e
  if [ "$om_rc" -ne 0 ]; then
    om_e2e=$((om_e2e + 1))
  else
    echo "    FAIL  [override-form] e2e control: the unmarked twin did NOT fire — the subject arm is vacuous"
    om_fail=$((om_fail + 1)); failures=$((failures + 1))
  fi

  if [ "$om_fail" -eq 0 ]; then
    echo "    PASS  [override-form]  must-match=${om_match}  must-not-match=${om_nomatch}  e2e=${om_e2e}"
  else
    echo "    ---   [override-form]  ${om_fail} failure(s)"
  fi

  # ── Self-doc exemption: DISCOVERED from the marker, never enumerated ───────
  # CORPUS-FREE BY CONSTRUCTION, for the same load-bearing reason the
  # override-form block above is — and one step harder, because this change had
  # to REMOVE two shared inputs rather than merely avoid adding one.
  #
  # run_equivalence asserts the report text is IDENTICAL ABOVE THE ADVISORY BLOCK
  # (the declared boundary; see normalize_report) between this checker and the
  # pre-extraction inline body over the SHARED fixture corpus — findings and
  # `::notice::` lines both sit above that boundary, so neither the constraint
  # below nor the two extra notice lines it names are affected by the narrowing,
  # and that body still carries the path arm deleted from run_scan's SCOPE
  # `case`. Two shared fixtures used to pin this class by LIVING at the two
  # exempt paths carrying no marker. After the deletion the two implementations
  # genuinely DISAGREE on those files — which IS the change — so keeping them
  # fails the equivalence arm in the `gate STRENGTHENED` direction however
  # correct the change is; and merely giving them the marker fails it too, on
  # the two extra `::notice::` lines the oracle never emits because it hits its
  # own path arm first. Re-pinning the oracle forward is not an escape either:
  # extract_oracle materialises the workflow's `run:` block at
  # PRE_EXTRACTION_SHA and dies unless it still contains REFBLOCK_RE, which a
  # post-extraction thin caller does not.
  #
  # So the two fixtures were RETIRED from cases/ + manifest.txt and their class
  # re-sited here, where it gets STRONGER rather than weaker: they asserted one
  # direction only (zero, from an unmarked file at an enumerated path), this
  # asserts BOTH directions and adds a third marker state. Removing the input
  # states the boundary of the equivalence claim; suppressing the output would
  # have asserted an agreement that no longer exists.
  #
  # Every file below is written under $td and NEVER under $FX_REPO.
  #
  # 3 marker states x 2 exempt-looking paths x 2 input modes x 2 resolvers = 24.
  #   marked-bare      -> zero   the form the retired fixtures never carried
  #   marked-rationale -> zero   the declared rationale-carrying form; ALSO the
  #                              live integration assertion against the widened
  #                              OVERRIDE regex — narrow it again and exactly
  #                              these 8 go red while the other 16 stay green
  #   unmarked         -> FLAG   the CONTROL, and the whole point. Without it
  #                              the zeros are indistinguishable from a gate
  #                              that simply stopped detecting — and it is
  #                              precisely the drift the deleted path arm made
  #                              unreachable: a marker-less file at either path
  #                              was silently exempt forever.
  local sd_dir="$td/selfdoc"
  local sd_state sd_input sd_resolver sd_repo sd_base sd_head sd_out sd_want sd_got
  local sd_pair sd_dest sd_num
  local sd_marked_zero=0 sd_unmarked_flag=0 sd_fail=0
  local sd_a='core/rules/git-workflow.md'
  local sd_b='.github/PULL_REQUEST_TEMPLATE.md'
  mkdir -p "$sd_dir"
  echo "--- self-doc exemption: discovered from the marker, all three arms ---"

  for sd_state in marked-bare marked-rationale unmarked; do
    sd_repo="$sd_dir/$sd_state"
    mkdir -p "$sd_repo/docs"
    git -C "$sd_repo" init -q 2>/dev/null
    git -C "$sd_repo" config user.email "fixtures@example.invalid"
    git -C "$sd_repo" config user.name "issue-ref self-doc harness"
    git -C "$sd_repo" config commit.gpgsign false
    printf 'seed\n' > "$sd_repo/docs/.seed.md"
    git -C "$sd_repo" add -A
    git -C "$sd_repo" commit -q -m "self-doc base"
    sd_base="$(git -C "$sd_repo" rev-parse HEAD)"

    # The three bodies are byte-identical but for the marker line, so a verdict
    # difference can only be the marker. The two synthetic numbers are the ones
    # the retired fixtures used — one per path — so neither verdict-map row is
    # orphaned by the retirement. Both resolve `unresolvable`.
    for sd_pair in "${sd_a}|909601" "${sd_b}|909602"; do
      sd_dest="${sd_pair%%|*}"
      sd_num="${sd_pair##*|}"
      mkdir -p "$sd_repo/$(dirname "$sd_dest")"
      {
        case "$sd_state" in
          marked-bare)
            printf '%s\n' '<!-- repo-integrity: allow-issue-ref -->' ;;
          marked-rationale)
            printf '%s\n' '<!-- repo-integrity: allow-issue-ref — limb 1: worked-example ids displayed as subject matter -->' ;;
        esac
        printf 'Self-doc exemption probe — %s.\n\n' "$sd_dest"
        printf -- '- #%s — does not resolve, and sits above any reference block.\n' "$sd_num"
      } > "$sd_repo/$sd_dest"
    done
    git -C "$sd_repo" add -A
    git -C "$sd_repo" commit -q -m "self-doc head"
    sd_head="$(git -C "$sd_repo" rev-parse HEAD)"

    if [ "$sd_state" = "unmarked" ]; then sd_want=flag; else sd_want=zero; fi
    for sd_input in delta path; do
      for sd_resolver in gh fixture; do
        sd_out="$sd_dir/out-${sd_state}-${sd_input}-${sd_resolver}.txt"
        set +e
        if [ "$sd_input" = "delta" ]; then
          ( cd "$sd_repo" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
              GH_TOKEN=fixture-token GITHUB_REPOSITORY=fixture-owner/fixture-repo \
              bash "$SCRIPT_PATH" --base "$sd_base" --head "$sd_head" \
                --resolver "$sd_resolver" --fixture-map "$FX_MAP" ) > "$sd_out" 2>&1
        else
          ( cd "$sd_repo" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
              GH_TOKEN=fixture-token GITHUB_REPOSITORY=fixture-owner/fixture-repo \
              bash "$SCRIPT_PATH" --resolver "$sd_resolver" --fixture-map "$FX_MAP" \
                --path "$sd_a" "$sd_b" ) > "$sd_out" 2>&1
        fi
        set -e
        for sd_dest in "$sd_a" "$sd_b"; do
          assertions=$((assertions + 1))
          if grep -qE "^${sd_dest}:[0-9]+: " "$sd_out" 2>/dev/null; then sd_got=flag; else sd_got=zero; fi
          if [ "$sd_got" != "$sd_want" ]; then
            echo "    FAIL  [self-doc] ${sd_state} ${sd_dest} (${sd_input} x --resolver ${sd_resolver}): expected ${sd_want}, got ${sd_got}"
            sd_fail=$((sd_fail + 1)); failures=$((failures + 1))
          elif [ "$sd_want" = "zero" ]; then
            sd_marked_zero=$((sd_marked_zero + 1))
          else
            sd_unmarked_flag=$((sd_unmarked_flag + 1))
          fi
        done
      done
    done
  done

  # Suite-level control, the same one the fixture matrix carries: a zero is
  # never reported without a non-zero from the SAME block proving the harness
  # actually ran. Not counted as an assertion — it grades the other 24.
  if [ "$sd_unmarked_flag" -eq 0 ]; then
    echo "    FAIL  [self-doc] vacuity control: the unmarked arm produced ZERO findings"
    sd_fail=$((sd_fail + 1)); failures=$((failures + 1))
  fi
  if [ "$sd_fail" -eq 0 ]; then
    echo "    PASS  [self-doc]  marked-must-zero=${sd_marked_zero}  unmarked-must-flag=${sd_unmarked_flag}"
  else
    echo "    ---   [self-doc]  ${sd_fail} failure(s)"
  fi

  # ── Exact-match placement, the failure message, and the limb-(a) guard ──────
  # CORPUS-FREE BY CONSTRUCTION, for the same load-bearing reason as the two
  # blocks above. The pre-extraction body carries the OLD placement message, so a
  # fixture added to cases/ + manifest.txt to exercise any of this would be
  # compared against a body that answers differently, and the equivalence arm
  # would fail ON A CORRECT FIX. Every file below is written under $td and NEVER
  # under $FX_REPO.
  #
  # THIS BLOCK IS THE REPLACEMENT COVERAGE for what the narrowed equivalence claim
  # gives up (see normalize_report). The byte-diff pinned the advisory prose to a
  # frozen historical copy of itself — it could tell you the message had changed,
  # never that the message was TRUE. Arms 1-2 pin the behaviour, Arm 3 pins the
  # text, and together they assert the property that actually matters: every
  # heading the message calls recognized is accepted, every heading it calls
  # unrecognized is flagged, and the message still says so. Arm 3 alone would pass
  # on a message that describes a gate doing something else; Arms 1-2 alone would
  # pass on a message that says nothing at all.
  #
  # The headings are not invented. They are the measured matrix: five that
  # REFBLOCK_RE accepts and six it rejects, and each of the six is a near miss the
  # corrected message names by example — `## References and Provenance` contains
  # TWO recognized spellings and is still rejected, which is the whole cost of the
  # omission in one row.
  local xm_dir="$td/exact-match"
  local xm_h xm_i xm_out xm_rc xm_body xm_phrase
  local xm_accept=0 xm_flagged=0 xm_msg=0 xm_guard=0 xm_inert=0 xm_fail=0
  mkdir -p "$xm_dir"
  echo "--- exact-match placement: message text pinned to the behaviour it describes ---"

  # Arm 1 — MUST ACCEPT. #909100 resolves `valid` in the shared verdict map (the
  # same number the generated heading matrix uses, so no map row is added and
  # none is orphaned), which makes PLACEMENT the only variable under test.
  # Filenames are keyed by INDEX rather than by a slug of the heading: two of
  # these spellings differ only in case and would collide on a case-insensitive
  # filesystem, silently shrinking the matrix.
  xm_i=0
  for xm_h in \
    '## References' \
    '## references' \
    '## Issue References' \
    '## Sources:' \
    '## Source(s)' ; do
    xm_i=$((xm_i + 1))
    assertions=$((assertions + 1))
    xm_body="$xm_dir/accept-${xm_i}.md"
    {
      printf 'Exact-match probe — must ACCEPT.\n\n'
      printf '%s\n' "$xm_h"
      printf -- '\n- #909100 — the reference sits UNDER the heading under test.\n'
    } > "$xm_body"
    set +e
    xm_out="$( cd "$xm_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
        GITHUB_REPOSITORY=fixture-owner/fixture-repo \
        bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path "accept-${xm_i}.md" 2>&1 )"
    xm_rc=$?
    set -e
    if [ "$xm_rc" -eq 0 ]; then
      xm_accept=$((xm_accept + 1))
    else
      echo "    FAIL  [exact-match] a heading the message calls RECOGNIZED was flagged: ${xm_h}"
      printf '%s\n' "$xm_out" | sed -e 's/^/            /'
      xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
    fi
  done

  # Arm 2 — MUST FLAG. Each of these is named in the corrected message as a near
  # miss, so this arm is what stops the message and the regex drifting apart: if
  # REFBLOCK_RE is ever widened to accept one of them, the message becomes wrong
  # and THIS arm goes red, rather than a reader discovering it.
  xm_i=0
  for xm_h in \
    '## REFERENCES' \
    '## References and Provenance' \
    '## Related ADRs' \
    '## Provenance notes' \
    '## Reference' \
    '##References' ; do
    xm_i=$((xm_i + 1))
    assertions=$((assertions + 1))
    xm_body="$xm_dir/flag-${xm_i}.md"
    {
      printf 'Exact-match probe — must FLAG.\n\n'
      printf '%s\n' "$xm_h"
      printf -- '\n- #909100 — the reference sits under an UNRECOGNIZED heading.\n'
    } > "$xm_body"
    set +e
    xm_out="$( cd "$xm_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
        GITHUB_REPOSITORY=fixture-owner/fixture-repo \
        bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path "flag-${xm_i}.md" 2>&1 )"
    xm_rc=$?
    set -e
    if [ "$xm_rc" -ne 0 ]; then
      xm_flagged=$((xm_flagged + 1))
    else
      echo "    FAIL  [exact-match] a heading the message calls UNRECOGNIZED was accepted: ${xm_h}"
      xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
    fi
  done

  # Arm 3 — THE MESSAGE ITSELF. Emit a real failure verdict and assert the
  # advisory block states the constraint and names the near misses Arm 2 just
  # exercised.
  #
  # The second group of phrases is deliberately WIDER than the placement bullet,
  # and the reason is worth stating: the narrowed equivalence claim drops the
  # byte-diff over this entire region, not merely over the sentence that changed.
  # The other four verdict-class bullets and the Override criterion lost their
  # only pin too. A presence assertion is weaker than the behavioural pinning
  # Arms 1-2 give the placement bullet — it catches deletion and truncation, not
  # a wrong sentence — but it is the difference between partial coverage and
  # none, and claiming the whole region is "re-pinned to behaviour" would
  # overstate what this block does.
  assertions=$((assertions + 1))
  xm_body="$xm_dir/message.md"
  {
    printf 'Exact-match probe — message content.\n\n'
    printf -- '- #909100 — a valid reference placed above any reference block.\n'
  } > "$xm_body"
  set +e
  xm_out="$( cd "$xm_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
      GITHUB_REPOSITORY=fixture-owner/fixture-repo \
      bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path message.md 2>&1 )"
  xm_rc=$?
  set -e
  printf '%s\n' "$xm_out" > "$xm_dir/message.out"
  # Precondition: the probe must actually have FAILED, or no advisory block was
  # printed and every phrase assertion below would be checking an empty haystack.
  if [ "$xm_rc" -eq 0 ]; then
    echo "    FAIL  [exact-match] message probe did not produce a verdict — the phrase arms would be vacuous"
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  else
    xm_msg=$((xm_msg + 1))
    for xm_phrase in \
      'The match ends at the heading word' \
      'FIRST LETTER of each word may vary in case' \
      '`## Related ADRs`' \
      '`## References and Provenance`' \
      '`## Provenance notes`' \
      '`## REFERENCES`' \
      'RENAME' \
      'does not resolve / redirect' \
      'different repository' \
      'pull-request number' \
      'deprecated IMP-NNN' \
      'allow-issue-ref' \
      'BOTH limbs hold' ; do
      assertions=$((assertions + 1))
      if grep -qF -- "$xm_phrase" "$xm_dir/message.out"; then
        xm_msg=$((xm_msg + 1))
      else
        echo "    FAIL  [exact-match] the failure message no longer states: ${xm_phrase}"
        xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
      fi
    done
  fi

  # Arm 4 — THE LIMB-(a) GUARD, both directions. Without this pair the guard
  # ships with no regression guard at all, and that is precisely how the defect
  # it fixes escaped in the first place: every other invocation in this harness
  # pins GITHUB_REPOSITORY, so nothing here could ever reach the unset path.
  #   gh      + unset -> REFUSE (exit 3), naming the variable, emitting NO finding
  #   fixture + unset -> proceed normally; the fixture resolver never reads it
  assertions=$((assertions + 1))
  set +e
  xm_out="$( cd "$xm_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA -u GITHUB_REPOSITORY \
      bash "$SCRIPT_PATH" --resolver gh --path accept-1.md 2>&1 )"
  xm_rc=$?
  set -e
  if [ "$xm_rc" -ne 3 ]; then
    echo "    FAIL  [exact-match] guard: --resolver gh with GITHUB_REPOSITORY unset returned ${xm_rc}, expected 3 (config failure)"
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  elif ! grep -qF 'GITHUB_REPOSITORY' <<<"$xm_out"; then
    echo "    FAIL  [exact-match] guard: the refusal does not name GITHUB_REPOSITORY"
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  elif grep -qE '^[^[:space:]]+:[0-9]+: ' <<<"$xm_out"; then
    echo "    FAIL  [exact-match] guard: a CONTENT finding was emitted alongside the refusal"
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  else
    xm_guard=$((xm_guard + 1))
  fi

  # The twin, and it is the specificity arm: a guard that refused here too would
  # have broken the whole offline surface rather than fixed a false red.
  assertions=$((assertions + 1))
  set +e
  xm_out="$( cd "$xm_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA -u GITHUB_REPOSITORY \
      bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path accept-1.md 2>&1 )"
  xm_rc=$?
  set -e
  if [ "$xm_rc" -eq 0 ]; then
    xm_guard=$((xm_guard + 1))
  else
    echo "    FAIL  [exact-match] guard twin: --resolver fixture wrongly refused with GITHUB_REPOSITORY unset (exit ${xm_rc})"
    printf '%s\n' "$xm_out" | sed -e 's/^/            /'
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  fi

  # Arm 5 — INERTNESS OF THE EXCLUDED REGION, which is what keeps the narrowed
  # equivalence claim honest over time.
  #
  # run_equivalence's narrowing control asserts the normalizer RAN. It cannot
  # assert that the region it removed is still inert, and inertness is the entire
  # justification for removing it. That property was established by reading the
  # region once; a reading is not a guarantee, and the failure it leaves open is
  # silent — an `echo` carrying a scan result added below the cut line would
  # simply leave the comparison, with every arm still green.
  #
  # So: run the checker over two inputs that produce DIFFERENT findings, and
  # require their reports to DIFFER above the cut and be BYTE-IDENTICAL below it.
  # The differ-above requirement is the vacuity control — without it two identical
  # reports would satisfy the arm trivially. Probe A carries one misplaced valid
  # reference; probe B carries that same finding plus one unresolvable and one
  # deprecated reference. The day the advisory block emits anything that DIFFERS
  # BETWEEN THESE TWO PROBES, this arm goes red instead of the exclusion quietly
  # widening.
  #
  # ITS REACH STOPS THERE. The discriminator is a byte difference between two
  # SAMPLES of the finding set, not variation across the finding set, so three
  # classes of below-cut output pass: output CONSTANT across finding sets (no
  # input dimension changes that — a constant is constant); output that varies
  # with the finding set but takes the SAME VALUE on both probes (a count of
  # misplaced references is 1 on each); and output keyed to a finding class
  # NEITHER probe carries (pull-request number, transferred issue). Each was
  # measured by one line added below the cut that left this arm at inertness=1
  # and the suite at SELF-TEST RESULT: PASS, while the same-shaped count of
  # unresolvable references — which the two probes DO tell apart — turned it red.
  # normalize_report() records why those residuals are accepted rather than
  # closed, and what closing them costs.
  local xm_a_out="$xm_dir/inert-a.out" xm_b_out="$xm_dir/inert-b.out"
  local xm_a_blk="$xm_dir/inert-a.blk" xm_b_blk="$xm_dir/inert-b.blk"
  local xm_a_norm="$xm_dir/inert-a.norm" xm_b_norm="$xm_dir/inert-b.norm"
  {
    printf 'Inertness probe A.\n\n'
    printf -- '- #909100 — a VALID reference, misplaced above any reference block.\n'
  } > "$xm_dir/inert-a.md"
  {
    printf 'Inertness probe B — a different finding set, deliberately.\n\n'
    printf -- '- #909100 — a VALID reference, misplaced above any reference block.\n'
    printf -- '- #909404 — a number the verdict map does not name, so it does not resolve.\n'
    printf -- '- IMP-007 — the deprecated form, a third verdict class.\n'
  } > "$xm_dir/inert-b.md"
  set +e
  ( cd "$xm_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
      GITHUB_REPOSITORY=fixture-owner/fixture-repo \
      bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path inert-a.md ) > "$xm_a_out" 2>&1
  ( cd "$xm_dir" && env -u GITHUB_STEP_SUMMARY -u BASE_SHA -u HEAD_SHA \
      GITHUB_REPOSITORY=fixture-owner/fixture-repo \
      bash "$SCRIPT_PATH" --resolver fixture --fixture-map "$FX_MAP" --path inert-b.md ) > "$xm_b_out" 2>&1
  set -e
  normalize_report "$xm_a_out" "$xm_a_norm"
  normalize_report "$xm_b_out" "$xm_b_norm"
  advisory_block_of "$xm_a_out" "$xm_a_blk"
  advisory_block_of "$xm_b_out" "$xm_b_blk"

  assertions=$((assertions + 1))
  if [ ! -s "$xm_a_blk" ] || [ ! -s "$xm_b_blk" ]; then
    echo "    FAIL  [exact-match] inertness: one or both runs emitted no advisory block — the arm is vacuous"
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  elif cmp -s "$xm_a_norm" "$xm_b_norm"; then
    echo "    FAIL  [exact-match] inertness vacuity control: the two inputs produced IDENTICAL reports above the cut"
    echo "            they must differ, or 'identical below the cut' proves nothing"
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  elif cmp -s "$xm_a_blk" "$xm_b_blk"; then
    xm_inert=$((xm_inert + 1))
  else
    echo "    FAIL  [exact-match] inertness: the EXCLUDED region differs between two runs with different findings"
    echo "            it has absorbed scan-dependent output, so excluding it from the equivalence"
    echo "            claim now removes real detection coverage. Narrow the cut or drop the exclusion."
    diff -u "$xm_a_blk" "$xm_b_blk" | sed 's/^/            /' || true
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  fi

  # Suite-level vacuity control, the same one every block here carries: a clean
  # must-accept run proves nothing unless the must-flag arm actually fired.
  if [ "$xm_flagged" -eq 0 ]; then
    echo "    FAIL  [exact-match] vacuity control: the must-flag arm produced ZERO findings"
    xm_fail=$((xm_fail + 1)); failures=$((failures + 1))
  fi
  if [ "$xm_fail" -eq 0 ]; then
    echo "    PASS  [exact-match]  must-accept=${xm_accept}  must-flag=${xm_flagged}  message-phrases=${xm_msg}  guard=${xm_guard}  inertness=${xm_inert}"
  else
    echo "    ---   [exact-match]  ${xm_fail} failure(s)"
  fi

  echo "--- fixture matrix: 2 invocation forms x 2 input modes x 2 resolvers = 8 cells ---"
  for form in ci direct; do
    for input in delta path; do
      for resolver in gh fixture; do
        cell="${form} x --$( [ "$input" = "delta" ] && echo 'base/--head' || echo 'path') x --resolver ${resolver}"
        out="$td/cell-${form}-${input}-${resolver}.out"
        run_cell "$form" "$input" "$resolver" "$out" || true
        cells_run=$((cells_run + 1))
        local cell_fail=0 cell_flag=0 cell_zero=0
        while IFS= read -r line || [ -n "$line" ]; do
          case "$line" in ''|'#'*) continue ;; esac
          class="$(printf '%s' "$line" | cut -d'|' -f1)"
          src="$(printf '%s' "$line" | cut -d'|' -f2)"
          dest="$(printf '%s' "$line" | cut -d'|' -f3)"
          ed="$(printf '%s' "$line" | cut -d'|' -f4)"
          ep="$(printf '%s' "$line" | cut -d'|' -f5)"
          if [ "$input" = "delta" ]; then want="$ed"; else want="$ep"; fi
          if grep -qE "^${dest}:[0-9]+: " "$out" 2>/dev/null; then got="flag"; else got="zero"; fi
          assertions=$((assertions + 1))
          if [ "$want" = "flag" ]; then cell_flag=$((cell_flag + 1)); else cell_zero=$((cell_zero + 1)); fi
          if [ "$got" != "$want" ]; then
            echo "    FAIL  [${cell}] ${class} ${dest}: expected ${want}, got ${got}"
            cell_fail=$((cell_fail + 1))
            failures=$((failures + 1))
          fi
        done < "$FX_MANIFEST"

        # Generated heading matrix — 42 zero arms, each with its sensitivity twin.
        local hslug hlevel hhash hspell zf ff
        while IFS=$'\t' read -r hslug hlevel hhash hspell; do
          [ -n "$hslug" ] || continue
          zf="docs/headings/zero-${hslug}-${hlevel}.md"
          ff="docs/headings/flag-${hslug}-${hlevel}.md"
          assertions=$((assertions + 2))
          if grep -qE "^${zf}:[0-9]+: " "$out" 2>/dev/null; then
            echo "    FAIL  [${cell}] Z-5 ${zf}: expected zero, got flag"
            cell_fail=$((cell_fail + 1)); failures=$((failures + 1))
          else
            cell_zero=$((cell_zero + 1))
          fi
          if grep -qE "^${ff}:[0-9]+: " "$out" 2>/dev/null; then
            cell_flag=$((cell_flag + 1))
          else
            echo "    FAIL  [${cell}] S-5(twin) ${ff}: expected flag, got zero"
            cell_fail=$((cell_fail + 1)); failures=$((failures + 1))
          fi
        done <<< "$(generated_heading_cases)"

        # Suite-level control (a): a zero is never reported without a non-zero
        # from the SAME invocation proving the harness actually ran.
        if [ "$cell_flag" -eq 0 ]; then
          echo "    FAIL  [${cell}] vacuity control: the cell produced ZERO must-flag findings"
          cell_fail=$((cell_fail + 1)); failures=$((failures + 1))
        fi
        if [ "$cell_fail" -eq 0 ]; then
          echo "    PASS  [${cell}]  must-flag=${cell_flag}  must-not-flag=${cell_zero}"
        else
          echo "    ---   [${cell}]  ${cell_fail} failure(s)"
        fi
      done
    done
  done

  echo ""
  echo "cells run: ${cells_run}/8   assertions: ${assertions}   failures: ${failures}"
  echo "OMITTED CELL, NAMED: the CI invocation form x --path has no production"
  echo "counterpart — the workflow only ever passes --base/--head. It is exercised"
  echo "here so the mode cannot rot, but nothing in CI runs it."
  [ "$failures" -eq 0 ] || return 1
  return 0
}

harness_main() {
  local rc=0
  [ -d "$FIXTURE_DIR" ] || die "fixture corpus not found: $FIXTURE_DIR"
  FX_MANIFEST="${FIXTURE_DIR}/manifest.txt"
  FX_MAP="${FIXTURE_DIR}/verdict-map.txt"
  [ -f "$FX_MANIFEST" ] || die "fixture manifest not found: $FX_MANIFEST"
  [ -f "$FX_MAP" ] || die "fixture verdict map not found: $FX_MAP"
  HARNESS_TD="$(mktemp -d)"
  trap harness_cleanup EXIT
  build_fixture_repo "$HARNESS_TD"

  if [ "$DO_SELF_TEST" -eq 1 ]; then
    run_self_test || rc=1
  fi
  # An explicit --equivalence always runs. A bare --self-test runs the arm too
  # WHEN the pinned pre-extraction commit is readable, and says so out loud when
  # it is not — a silently-omitted arm and a deliberately-skipped one must not
  # look the same in a log.
  if [ -z "$EQUIV_SHA" ] && [ "$DO_SELF_TEST" -eq 1 ]; then
    if git -C "$REPO_ROOT" cat-file -e "${PRE_EXTRACTION_SHA}^{commit}" 2>/dev/null; then
      EQUIV_SHA="$PRE_EXTRACTION_SHA"
    else
      echo ""
      echo "SKIP  differential equivalence arm: the pinned pre-extraction commit"
      echo "      ${PRE_EXTRACTION_SHA} is not in this checkout (shallow clone)."
      echo "      Run it from a full clone: ${TOOL_NAME} --equivalence ${PRE_EXTRACTION_SHA}"
    fi
  fi
  if [ -n "$EQUIV_SHA" ]; then
    echo ""
    run_equivalence "$EQUIV_SHA" || rc=1
  fi
  echo ""
  if [ "$rc" -eq 0 ]; then echo "SELF-TEST RESULT: PASS"; else echo "SELF-TEST RESULT: FAIL"; fi
  return "$rc"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
if [ "$DO_SELF_TEST" -eq 1 ] || [ -n "$EQUIV_SHA" ]; then
  harness_main
  exit $?
fi

case "$INPUT_MODE" in
  delta)
    [ -n "$BASE_SHA" ] || die "delta mode needs --base"
    [ -n "$HEAD_SHA" ] || die "delta mode needs --head"
    ;;
  path)
    [ "${#PATHS[@]}" -gt 0 ] || die "--path needs at least one file"
    ;;
  *)
    usage >&2
    die "no input mode selected: pass --base/--head, --path, --self-test or --equivalence"
    ;;
esac

if [ "$RESOLVER" = "fixture" ] && [ -z "$FIXTURE_MAP" ]; then
  die "--resolver fixture requires --fixture-map"
fi

# The gh resolver asks "does #N exist in THIS repo", and GITHUB_REPOSITORY is the
# only thing that says which repo that is. Unset, the query degenerates to
# `repos//issues/N`, every number 404s, and the gate emits a CONTENT verdict
# ("#N does not resolve to an issue in this repo") produced entirely by a missing
# variable — a red that does not depend on the file under test and is therefore
# indistinguishable, to the reader, from a real finding.
#
# REFUSE RATHER THAN DERIVE, and the rejected alternative is the instructive one.
# Deriving the repo from `git remote` would trade a loud config fault for a silent
# WRONG one: on a fork or a mirror remote the same #N resolves against a DIFFERENT
# issue graph, so the gate would confidently report a valid reference as invalid
# with no evidence that anything was assumed. A config fault reported as a content
# verdict is the defect this guard removes; a config fault reported as the wrong
# content verdict is the same defect with the diagnosis deleted.
#
# SITED AT THE gh RESOLVER'S PRECONDITION, deliberately, and not at the `:` default
# at the top of the file. `resolve_issue`'s `gh api` call is the single consumer of
# the variable; `fixture_verdict` never reads it. Guarding the default instead would
# break every legitimate `--resolver fixture` invocation, which is the whole offline
# surface. Guarding lazily inside `resolve_issue` would be worse still: it would fire
# only once some `#N` was encountered, so one config fault would produce a refusal or
# a verdict depending on file content.
#
# Exit 3, not 1. `1` means findings; `3` means the tool could not run. That is this
# file's declared interface (see INTERFACE above) and the posture it already takes on
# the structurally identical unset-REFBLOCK_RE fault. Reusing `1` would leave the
# false red in place with better wording.
if [ "$RESOLVER" = "gh" ] && [ -z "${GITHUB_REPOSITORY}" ]; then
  die "GITHUB_REPOSITORY is unset and --resolver gh cannot resolve #N without it.
  This is a CONFIGURATION failure, not a verdict: no file was scanned and no finding is implied.
  Set the repository:  GITHUB_REPOSITORY=owner/name ${TOOL_NAME} ...
  Or resolve offline:  ${TOOL_NAME} --resolver fixture --fixture-map <path> ...
  Inside GitHub Actions the runner supplies this variable; outside it you must."
fi

run_scan
emit_verdict
