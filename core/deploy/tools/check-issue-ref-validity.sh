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

OVERRIDE='<!--[[:space:]]*repo-integrity:[[:space:]]*allow-issue-ref[[:space:]]*-->'
# Designated reference-block headers (reuse the parser-clean anchor family).
# The `Source(s)` arm is explicit: `[Ss]ources?` matches `Source` and
# `Sources` but NOT `Source(s)`, whose parenthetical then hit the `$` anchor
# and failed — while this gate's own failure message, core/ADRs/README.md,
# and reference-durability-standard.md all NAME `### Source(s)` as
# recognized. That was a specification-versus-implementation defect, not a
# policy choice, so the implementation is corrected to the stated set.
#
# `Related ADRs` is deliberately NOT recognized. It is a cross-ADR-link
# section, where core/standards/adr-authoring-guide.md § Issue references in
# ADRs forbids a bare #N outright (zone 1) — recognizing it would move the
# placement cut point ABOVE that section and make this gate accept exactly
# the placement the authoring guide prohibits.
REFBLOCK_RE='^#{1,6}[[:space:]]+([Ii]ssue [Rr]eferences|[Rr]eferences|[Rr]elated|[Pp]rovenance|[Ss]ources?|[Ss]ource\(s\))[[:space:]]*:?[[:space:]]*$'

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
    # SCOPE: every changed .md MINUS the self-doc files that necessarily
    # quote worked-example #N (they carry a file-top allow-issue-ref).
    case "$f" in
      core/rules/git-workflow.md|.github/PULL_REQUEST_TEMPLATE.md) continue ;;  # self-doc (file-top allow-issue-ref)
      release/releases/*) continue ;;  # tracking surface (RELEASE_LOG/INDEX/DIGEST/NOTES/plans) — #N + PR-refs are native provenance; exempt, mirroring the reference-durability gate
    esac
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

  if diff -u "$o_out" "$c_out" > "$td/report.diff" 2>&1; then
    echo "PASS  report text byte-identical across the whole corpus"
  else
    echo "FAIL  report text differs:"
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

run_scan
emit_verdict
