#!/bin/bash
# check-convention.sh — platform-convention linter engine (#228).
#
# The convention-linter for the FIVE residual platform-convention dimensions that
# no existing gate covers. Invoked by deploy.sh Check 49 (deploy-time, warn-mode-
# initial). NOT a pre-commit hook — CLAUDE.md forbids normalizing `--no-verify`,
# so platform-convention enforcement lives on the deploy.sh check family + an
# optional PR-time job, never a hook that an author is tempted to bypass.
#
# ── OWNED DIMENSIONS (this tool enforces these five) ────────────────────────────
#   (1) [topic]-[type].md FILE-NAMING — authored reference/standard/spec/discipline
#       *.md basenames must be lowercase-kebab (`[a-z0-9]+(-[a-z0-9]+)*.md`). The
#       convention governs AUTHORED docs in the standards/specs/disciplines/schemas
#       + release/references surfaces, NOT fixed-name structural files and NOT the
#       release corpus (release/releases/ has its own governed `<topic>_RELEASE_*`
#       convention per CLAUDE.md). Exempt: any ALL-CAPS basename (the all-caps
#       governance/doc convention — SKILL.md, OPERATIONS.md, README.md, INSTALL.md,
#       AUDIT_FRAMEWORK.md, …), the ADR-NNN- prefix, underscore-prefixed shard
#       files (`_*.md`), *.md.template, fixture/eval/testdata/_examples paths, and
#       dotfiles. Scope is the authored-doc dirs only (not whole-tree) so the
#       check is green on the conforming corpus and fires only on real new drift.
#   (2) LAYER-2 PATH IN A TRACKED FILE — a git-tracked file whose PATH is under
#       `projects/` is a Platform-vs-Working-Content boundary violation (the
#       `projects/` tree is Layer-2 / git-ignored per CLAUDE.md § Platform vs.
#       Working Content Boundary). A tracked path there leaks operational content
#       into the platform layer.
#   (3) EVIDENCE-QUALITY-LABEL PRESENCE — a governance file (core/governance/,
#       release/governance/) that makes a DATED factual assertion (a literal
#       YYYY-MM-DD — the strong claim signal) but carries ZERO evidence-quality
#       labels ([SOURCE] / [INFERRED] / [ASSUMPTION – CONFIRM] / [CONTEXT] /
#       [RECOMMENDED]) anywhere is flagged (a coarse completeness nudge —
#       CLAUDE.md requires evidence labels on factual claims). Intentionally
#       conservative: file-level (not per-claim) + a DATE signal (not a version/
#       count mention, which are common in process specs) + the process-spec
#       governance files (OPERATIONS / RELEASE_PROTOCOL / release-process /
#       README — process/reference docs whose dates are changelog/example dates,
#       not claims) are exempt. The check's real target is a tracked claims/
#       status governance artifact; none exist in-tree today (that tier is the
#       git-ignored operational layer), so it is green now and stands ready.
#   (4) PLACEHOLDER LEAKAGE — an unfilled `[TBD]` / `[INSERT]` / `[TODO]`
#       placeholder OUTSIDE backticks (a backticked `[TBD]` is documentation OF
#       the token, per the CLAUDE.md guardrail, and is exempt). Bare bracketed
#       placeholder text in authored corpus is a guardrail violation.
#   (5) EVENT-LOG-KEY — a READ site that binds the pipeline event log's `version`
#       column to the RELEASE-VERSION form instead of the milestone-slug join key
#       that pipeline-event-log-schema.md § 2a makes canonical. The column is
#       polymorphic (slugs, legacy `vX.Y`, a `{{RELEASE_VERSION}}` literal, a
#       `v0.0.0` sentinel), and one legacy value has been measured spanning four
#       releases — so a version-keyed read is not uniquely resolvable. The scan
#       is an ENUMERATION with a stated boundary, not an open pattern:
#         E1  a `query-pipeline-event.sh` invocation carrying `--version` with NO
#             `--release` on the same statement;
#         E2  a documented read recipe over the event log "filtered by" a
#             backticked `version` column;
#         E3  the rendered/spec § 11.3 contract string `(filter: version=…)`;
#         E4  a `--mode per-release --version <vX.Y>` synthesis invocation.
#       SUPPRESSOR — the line-scoped marker `event-log-key: allow — <reason>`,
#       transcribed from the shipped `sigpipe-idiom: allow — <reason>` form (the
#       one in-repo convention that is both per-LINE and reason-BEARING). The
#       reason is MANDATORY: a bare `event-log-key: allow` does NOT suppress and
#       remains a finding, so a merely-unconverted site can never read as
#       deliberate. There is deliberately NO file-scoped tier — a whole-file
#       suppressor would let one intentional site silence an unconverted sibling.
#       A `--release` on the same statement is a STRUCTURAL exemption, not a
#       marker (E1's own predicate), so a marker here always means "deliberate"
#       and never "false positive suppressed".
#       OUT OF CLASS — a fixture event-log DATA ROW (`| <ISO-ts> | <vX.Y> | …`) is
#       the INPUT a read site consumes, not a read site. Such rows are counted and
#       reported on the `OK:` denominator line, never silently dropped.
#
# ── DELEGATED DIMENSIONS (documented here; this tool does NOT duplicate-enforce) ─
#   Per the #228 own/delegate split — duplicate enforcement is governance debt
#   (one source per rule). These are caught elsewhere:
#     - dead-file-reference  -> .github/workflows/repo-integrity.yml (dead-file-ref gate)
#     - depersonalization    -> .github/workflows/repo-integrity.yml (depersonalization gate)
#     - issue-reference       -> .github/workflows/repo-integrity.yml (issue-ref gate)
#     - localized-context     -> core/deploy/deploy.sh Check 25
#     - internal-link integrity -> .github/workflows/link-check.yml
#   This tool deliberately leaves those unenforced to avoid a second source of truth.
#
# ── CONTRACT ────────────────────────────────────────────────────────────────────
#   Output: one finding per line, prefixed `FAIL:` (a convention violation) or
#           `OK:` (informational). A trailing `SUMMARY: N finding(s)` line.
#           deploy.sh Check 49 routes each FAIL through flag_warn_or_issue (warn-
#           mode-initial), so a finding annotates but does not block during the
#           shakedown window.
#   Exit:   0 = no findings; 1 = one or more findings; 3 = scan-surface error
#           (a declared scan root unreadable — a fail-loud condition).
#   The tool is read-only. POSIX-portable (BSD + GNU grep/awk); no `\b`, no GNU-only flags.
#
# Usage:
#   bash core/deploy/tools/check-convention.sh            # scan the tracked corpus
#   bash core/deploy/tools/check-convention.sh --self-test  # hermetic regression

set -euo pipefail
export LC_ALL=C

SELF_TEST=0
[ "${1:-}" = "--self-test" ] && SELF_TEST=1

# ── shared predicates ───────────────────────────────────────────────────────────

# is_naming_exempt — file allowed NOT to be lowercase-kebab. Arg is the FULL
# tracked path (so path-class exemptions — fixtures/evals/testdata — can apply).
is_naming_exempt() {
  local path="$1" base
  base="$(basename "$path")"
  # path-class: fixture / eval / testdata / illustrative-example corpora carry
  # deliberately-odd names.
  case "$path" in
    */fixtures/*|*/evals/*|*/testdata/*|*/tests/*|*/_examples/*) return 0 ;;
  esac
  case "$base" in
    ADR-[0-9]*) return 0 ;;        # ADR-NNN-<kebab>.md — sanctioned ADR naming
    *.md.template) return 0 ;;     # template variants
    _*) return 0 ;;                # underscore-prefixed shard files (_header.md, …)
    .*) return 0 ;;                # dotfiles
  esac
  # all-caps basename (letters/digits/underscore, no lowercase) — the all-caps
  # governance/doc convention (SKILL.md, OPERATIONS.md, README.md, INSTALL.md,
  # AUDIT_FRAMEWORK.md, GETTING_STARTED.md, PULL_REQUEST_TEMPLATE.md, …).
  if grep -qE '^[A-Z0-9_]+\.md$' <<<"$base"; then return 0; fi
  return 1
}

# naming_conformant — true iff basename is lowercase-kebab + .md.
naming_conformant() {
  grep -qE '^[a-z0-9]+(-[a-z0-9]+)*\.md$' <<<"$1"
}

# has_evidence_label — true iff the file contains any closed-set evidence label.
has_evidence_label() {
  grep -qE '\[(SOURCE|INFERRED|ASSUMPTION (–|-) CONFIRM|CONTEXT|RECOMMENDED)\]' "$1"
}

# makes_factual_assertion — strong signal that a governance file states a DATED
# fact (a literal YYYY-MM-DD). A date is a far better "factual claim" signal than
# a version/count mention (those are ubiquitous in process specs and would false-
# positive). The dim-3 scan additionally exempts the process-spec governance files.
makes_factual_assertion() {
  grep -qE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$1"
}

# is_process_spec_governance — process/reference governance docs whose dates are
# changelog/example dates, not factual claims; exempt from dim 3.
is_process_spec_governance() {
  case "$(basename "$1")" in
    OPERATIONS.md|RELEASE_PROTOCOL.md|release-process.md|README.md) return 0 ;;
  esac
  return 1
}

# placeholder_findings — emit "<file>:<lineno>: <line>" for each [TBD]/[INSERT]/
# [TODO] OUTSIDE backticks that is an ACTUAL unfilled placeholder. Exempt:
#   - a placeholder inside a backtick span (documentation OF the token);
#   - a line that DESCRIBES the placeholder convention rather than leaking one —
#     signalled by "placeholder" / "marker" / "incorrect:" / "todos" on the line
#     (these are the corpus's documentation-of-the-guardrail mentions, e.g.
#     "no [TBD] placeholders", "[TODO] markers", an "Incorrect:" example).
# A real leak — e.g. `owner: [TBD]` used as a value — carries none of these and is
# still flagged.
placeholder_findings() {
  local file="$1"
  awk '
    {
      line = $0
      lc = tolower(line)
      # describing-the-token lines are documentation, not leaks
      if (lc ~ /placeholder|marker|incorrect:|todos/) next
      # strip backtick spans so a `[TBD]` inside code/quotes is ignored
      stripped = line
      while (match(stripped, /`[^`]*`/)) {
        stripped = substr(stripped, 1, RSTART - 1) substr(stripped, RSTART + RLENGTH)
      }
      if (stripped ~ /\[(TBD|INSERT|TODO)\]/) {
        printf "%s:%d: %s\n", FILENAME, NR, line
      }
    }
  ' "$file"
}

# ── event-log-key predicates (dim 5) ────────────────────────────────────────────

# EL_AWK — the dim-5 classifier, defined ONCE and shared by the live scan and the
# self-test so the arms below exercise the SAME body that ships. A second copy is
# a second thing that can drift.
#
# Emits one `<file>:<line>: [<arm>]` row per finding, and a trailing
# `@@ <files> <lines> <suppressed> <out-of-class>` denominator record. Reporting the
# denominator beside the count is what keeps "zero found" distinguishable from
# "nothing examined".
#
# POSIX-portable by construction: awk ERE only — no PCRE lookahead, no `\b`. E1's
# "no --release on the same statement" is expressed as a NEGATED match, which is
# what a lookahead would otherwise be needed for.
EL_AWK='
FNR == 1 { files++ }
{
  line = $0

  # X1 — a fixture event-log DATA ROW. The input a read site consumes, not a read
  # site. Declared out of class, counted, and reported; never silently dropped.
  if (line ~ /^[ \t]*\|[ \t]*20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[^|]*\|[ \t]*v[0-9]+\.[0-9][0-9]?[0-9]?[a-z]?[ \t]*\|/) { X++; next }

  arm = ""
  # E1 — version-keyed query invocation. A --release on the same statement is a
  #      STRUCTURAL exemption: the conforming flag proves conformance by itself.
  if (line ~ /query-pipeline-event\.sh/ && line ~ /--version/ && line !~ /--release/) arm = "E1"
  # E2 — a documented read recipe keyed on the version column.
  else if ((line ~ /pipeline-event-log/ || line ~ /event log/) && line ~ /filtered by/ && line ~ /`version[:`]/) arm = "E2"
  # E3 — the rendered/spec section 11.3 contract string.
  else if (line ~ /\(filter:[ \t]*version=/) arm = "E3"
  # E4 — a per-release synthesis invocation keyed on the version grammar.
  else if (line ~ /--mode per-release --version[ \t]+v[0-9]+\.[0-9][0-9]?[0-9]?[a-z]?/) arm = "E4"
  if (arm == "") next

  # SUPPRESSOR — reason MANDATORY. The trailing [^ \t] is the whole point: a bare
  # `event-log-key: allow` (or one with a whitespace-only reason) does not suppress.
  #
  # The separator is an ALTERNATION, never a bracket class. The script exports
  # LC_ALL=C, under which the em-dash is three bytes and `[-—]` degrades to the byte
  # set {-, 0xE2, 0x80, 0x94}: it matches ONE byte of the em-dash, leaving the next
  # byte to satisfy [^ \t], so a whitespace-only reason would suppress. An
  # alternation branch matches the whole byte sequence and the tooth holds. Measured,
  # not reasoned: the bracket form passed the positive arm and failed the EL-6
  # whitespace-only arm.
  #
  # NOTE: this string is single-quoted shell. Do not write an apostrophe anywhere in
  # it — it terminates the quote and breaks the parse.
  if (line ~ /event-log-key:[ \t]*allow[ \t]*(-|—)[ \t]*[^ \t]/) { S++; next }

  printf "%s:%d: [%s]\n", FILENAME, FNR, arm
}
END { printf "@@ %d %d %d %d\n", files+0, NR+0, S+0, X+0 }
'

# el_scan — run the dim-5 classifier over the given files.
el_scan() {
  awk "$EL_AWK" "$@"
}

# el_scope_files — the dim-5 scan scope: tracked files that mention the event-log
# apparatus, MINUS two declared exclusions.
#
#   FROZEN RECORDS — the append-only release corpus and the ADR sets. Their
#   historical rows are preserved by governance and must never be rewritten to
#   satisfy a linter.
#
#   THIS FILE — the linter does not lint itself. The dimension's own arm
#   definitions spell out the four shapes literally, and the EL-1/EL-6 self-test
#   fixtures are BY CONSTRUCTION unmarked positive samples: marking them would
#   destroy the very arms that prove the detector discriminates. This file is the
#   DEFINITION of the convention, never a read site subject to it, so excluding it
#   removes zero genuine class members — verified by measurement, not assumed.
el_scope_files() {
  local f
  git ls-files 2>/dev/null | while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      release/releases/*|core/ADRs/*|*/ADRs/*) continue ;;
      */check-convention.sh|check-convention.sh) continue ;;
    esac
    [ -f "$f" ] || continue
    grep -qE 'pipeline-event-log|append-pipeline-event|query-pipeline-event' "$f" 2>/dev/null || continue
    printf '%s\n' "$f"
  done
}

# el_scope_ok — 0 when the scope resolved to at least one file, 3 when it is empty.
# An empty scope is a SCAN-SURFACE error, not a clean run: a probe that cannot
# establish its denominator must fail loudly rather than report zero findings.
el_scope_ok() {
  [ -n "$1" ] && return 0
  return 3
}

# ── self-test (hermetic; labeled expected-match) ────────────────────────────────
if [ "$SELF_TEST" -eq 1 ]; then
  fails=0
  check() { # check <label> <expect 0|1> <actual-rc>
    if [ "$2" -eq "$3" ]; then printf 'self-test OK: %s\n' "$1"
    else printf 'self-test FAIL: %s (expected rc=%s got rc=%s)\n' "$1" "$2" "$3"; fails=$((fails+1)); fi
  }

  # (1) naming
  is_naming_exempt "README.md"; check "naming-exempt README.md (all-caps)" 0 $?
  is_naming_exempt "core/skills/foo/SKILL.md"; check "naming-exempt SKILL.md (all-caps)" 0 $?
  is_naming_exempt "core/standards/AUDIT_FRAMEWORK.md"; check "naming-exempt AUDIT_FRAMEWORK.md (all-caps)" 0 $?
  is_naming_exempt "core/ADRs/ADR-041-foo.md"; check "naming-exempt ADR-NNN" 0 $?
  is_naming_exempt "core/rules/x/_header.md"; check "naming-exempt _shard.md" 0 $?
  is_naming_exempt "core/skills/eval-writer/evals/fixtures/bad-vX.Y.md"; check "naming-exempt fixture path" 0 $?
  set +e; is_naming_exempt "core/standards/MixedCase-Thing.md"; check "naming NOT exempt MixedCase" 1 $?; set -e
  naming_conformant "good-name.md"; check "naming conformant lowercase-kebab" 0 $?
  set +e; naming_conformant "Bad_Name.md"; check "naming NOT conformant underscore/caps" 1 $?; set -e

  # (4) placeholder — backticked is exempt; bare is flagged.
  td="$(mktemp -d)"
  printf 'documenting the `[TBD]` token here\n' > "$td/doc.md"
  printf 'owner: [TBD]\n' > "$td/bare.md"
  [ -z "$(placeholder_findings "$td/doc.md")" ]; check "placeholder backticked-exempt" 0 $?
  [ -n "$(placeholder_findings "$td/bare.md")" ]; check "placeholder bare-flagged" 0 $?

  # (3) evidence-label predicates
  printf 'On 2026-06-29 we shipped 12 checks.\n' > "$td/facts-nolabel.md"
  printf 'On 2026-06-29 we shipped 12 checks. [SOURCE]\n' > "$td/facts-label.md"
  makes_factual_assertion "$td/facts-nolabel.md"; check "factual-assertion detected" 0 $?
  set +e; has_evidence_label "$td/facts-nolabel.md"; check "no-label file lacks label" 1 $?; set -e
  has_evidence_label "$td/facts-label.md"; check "labeled file has label" 0 $?

  # (5) event-log-key — EL-1..EL-7. Every arm runs the SHIPPING classifier ($EL_AWK
  # via el_scan) over a hermetic fixture, so an arm cannot pass against a copy that
  # has drifted from the live body.
  eld="$td/el"; mkdir -p "$eld"

  # el_hits / el_field — findings count, and a field of the @@ denominator record.
  el_hits()  { el_scan "$@" | grep -cE '^[^@].*: \[E[1-4]\]$' || true; }
  el_field() { # el_field <n> <file...>  — 1=files 2=lines 3=suppressed 4=out-of-class
    local n="$1"; shift
    el_scan "$@" | awk -v n="$n" '/^@@ /{print $(n+1)}'
  }

  # EL-1 SENSITIVITY — each of the four E arms fires on its shipped positive shape.
  # Mutation that must turn this red: delete any E arm from $EL_AWK.
  printf '%s\n' \
    '#   ./query-pipeline-event.sh --version v2.07a   # raw column filter' \
    'grep the pipeline-event-log then filtered by `version:` column' \
    '**Source events:** N row(s) (filter: version=`vX.Y`)' \
    '#   ./synthesize-release-learnings.sh --mode per-release --version v2.10' \
    > "$eld/pos.md"
  [ "$(el_hits "$eld/pos.md")" = "4" ]; check "EL-1 sensitivity: all four E arms fire" 0 $?

  # EL-2 SENSITIVITY — X1 fires on a fixture event-log data row (out-of-class, counted).
  printf '%s\n' \
    '| 2026-01-01T00:00:00Z | v1.00 | 12 | decision | payload |' \
    '| 2026-01-02T00:00:00Z | v2.00 | 12 | decision | payload |' \
    > "$eld/rows.md"
  [ "$(el_field 4 "$eld/rows.md")" = "2" ]; check "EL-2 sensitivity: X1 counts fixture data rows" 0 $?
  [ "$(el_hits "$eld/rows.md")" = "0" ]; check "EL-2b: a fixture data row is not a finding" 0 $?

  # EL-3 SPECIFICITY — an invocation carrying BOTH flags is exempted by --release.
  # Mutation that must turn this red: drop E1's negated --release match.
  # The fixture must carry --version for that mutation to be able to fire at all:
  # E1 is tool AND --version AND NOT --release, so a fixture without --version
  # fails the second conjunct and stays green under the mutation regardless —
  # the arm would pass vacuously with respect to the guard it names. EL-4 covers
  # the same exemption for the PROSE shape; this arm covers a real invocation.
  printf '%s\n' './query-pipeline-event.sh --release <milestone-slug> --version v4.07 --stage 12' > "$eld/rel.md"
  [ "$(el_hits "$eld/rel.md")" = "0" ]; check "EL-3 specificity: --release invocation not flagged" 0 $?

  # EL-4 SPECIFICITY — the shipped prose shape that NAMES --version to warn against
  # it while invoking --release on the same line stays unflagged.
  printf '%s\n' \
    'use `query-pipeline-event.sh --release <slug>`, NOT --version: the join key is the milestone slug per § 2a' \
    > "$eld/prose.md"
  [ "$(el_hits "$eld/prose.md")" = "0" ]; check "EL-4 specificity: converted prose site not flagged" 0 $?

  # EL-5 SPECIFICITY — a conforming slug-keyed read site is not flagged (AC4's
  # named subject). Mutation that must turn this red: widen any arm to a bare
  # version-token match.
  printf '%s\n' \
    'de_rows=$(awk -v s="$_slug" '"'"'$2==s'"'"' "$de_log")' \
    '"$QUERY_TOOL" --release "$VERSION" --event-type decision' \
    > "$eld/conform.md"
  [ "$(el_hits "$eld/conform.md")" = "0" ]; check "EL-5 specificity: slug-keyed read sites not flagged" 0 $?

  # EL-6 MARKER — the reason is mandatory. A reasoned marker suppresses; a bare
  # `allow` and a whitespace-only reason do NOT. This is the direct teeth for
  # "a site that is merely unconverted must not read as deliberate".
  # Mutation that must turn this red: drop the trailing [^ \t] from the suppressor.
  printf '%s\n' '#   ./query-pipeline-event.sh --version v2.07a   # event-log-key: allow — raw column filter, retained by § 2a' > "$eld/m-ok.md"
  printf '%s\n' '#   ./query-pipeline-event.sh --version v2.07a   # event-log-key: allow' > "$eld/m-bare.md"
  printf '%s\n' '#   ./query-pipeline-event.sh --version v2.07a   # event-log-key: allow —   ' > "$eld/m-blank.md"
  [ "$(el_hits "$eld/m-ok.md")" = "0" ];    check "EL-6 marker: reasoned allow suppresses" 0 $?
  [ "$(el_field 3 "$eld/m-ok.md")" = "1" ]; check "EL-6 marker: suppressed site is COUNTED, not silent" 0 $?
  [ "$(el_hits "$eld/m-bare.md")" = "1" ];  check "EL-6 marker: bare allow does NOT suppress" 0 $?
  [ "$(el_hits "$eld/m-blank.md")" = "1" ]; check "EL-6 marker: whitespace-only reason does NOT suppress" 0 $?
  # Locale regression arm. Under the exported LC_ALL=C a BRACKET-class separator
  # matches a single byte of the multibyte em-dash and the whitespace-only arm above
  # silently goes green; the alternation form is what keeps it red. Both separators
  # must work, so both are asserted.
  printf '%s\n' '#   ./query-pipeline-event.sh --version v2.07a   # event-log-key: allow - ascii hyphen reason' > "$eld/m-hyphen.md"
  [ "$(el_hits "$eld/m-hyphen.md")" = "0" ]; check "EL-6 marker: ASCII-hyphen separator also suppresses" 0 $?

  # EL-7 BROKEN-PROBE — an empty scan scope exits 3 (scan-surface error), never 0.
  # Mutation that must turn this red: replace the guard with a clean-zero return.
  set +e; el_scope_ok ""; check "EL-7 broken-probe: empty scope -> rc 3" 3 $?; set -e
  el_scope_ok "release/tools/query-pipeline-event.sh"; check "EL-7 control: non-empty scope -> rc 0" 0 $?

  rm -rf "$td"
  if [ "$fails" -gt 0 ]; then printf 'self-test: %d failure(s)\n' "$fails"; exit 1; fi
  printf 'self-test OK (all convention predicates passed)\n'
  exit 0
fi

# ── live scan over the tracked corpus ───────────────────────────────────────────
# Resolve the tracked file set via git (the authoritative corpus). If git is
# unavailable or the worktree is detached oddly, fail loud (exit 3) rather than
# scanning nothing.
if ! command -v git >/dev/null 2>&1; then
  echo "FAIL: check-convention scan-surface error — git not available"
  echo "SUMMARY: 1 finding(s)"
  exit 3
fi

FINDINGS=0

# Tracked markdown across the platform corpus — the scope for the PLACEHOLDER scan
# (dim 4), which applies everywhere authored content lives.
TRACKED_MD="$(git ls-files 'core/*.md' 'release/*.md' 'operations/*.md' 'docs/*.md' '*.md' 2>/dev/null || true)"

# Authored-doc surfaces — the scope for the FILE-NAMING scan (dim 1). The
# `[topic]-[type].md` kebab convention governs these dirs; the release corpus
# (release/releases/) and fixed-name structural files follow other governed
# conventions and are out of this scan's scope by construction.
NAMING_SCOPE_MD="$(git ls-files 'core/standards/*.md' 'core/specs/*.md' 'core/disciplines/*.md' 'core/schemas/*.md' 'release/references/*.md' 2>/dev/null || true)"

# (1) FILE-NAMING — lowercase-kebab basenames (exemptions applied).
while IFS= read -r f; do
  [ -z "$f" ] && continue
  is_naming_exempt "$f" && continue
  b="$(basename "$f")"
  if ! naming_conformant "$b"; then
    echo "FAIL: [naming] $f — basename is not lowercase-kebab '[topic]-[type].md' (rename or add to the exemption set)"
    FINDINGS=$((FINDINGS + 1))
  fi
done <<EOF
$NAMING_SCOPE_MD
EOF

# (2) LAYER-2 PATH IN A TRACKED FILE — any tracked path under projects/.
TRACKED_LAYER2="$(git ls-files 'projects/*' 2>/dev/null || true)"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  echo "FAIL: [layer-2] $f — a git-tracked file under projects/ (Layer-2 / git-ignored per CLAUDE.md § Platform vs. Working Content Boundary); operational content must not be tracked in the platform layer"
  FINDINGS=$((FINDINGS + 1))
done <<EOF
$TRACKED_LAYER2
EOF

# (3) EVIDENCE-QUALITY-LABEL — governance files asserting facts with zero labels.
GOV_FILES="$(git ls-files 'core/governance/*.md' 'release/governance/*.md' 2>/dev/null || true)"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue
  is_process_spec_governance "$f" && continue   # process/reference doc — dates are not claims
  if makes_factual_assertion "$f" && ! has_evidence_label "$f"; then
    echo "FAIL: [evidence-label] $f — governance file states a dated factual claim but carries no evidence-quality label ([SOURCE]/[INFERRED]/[ASSUMPTION – CONFIRM]/[CONTEXT]/[RECOMMENDED])"
    FINDINGS=$((FINDINGS + 1))
  fi
done <<EOF
$GOV_FILES
EOF

# (4) PLACEHOLDER LEAKAGE — bare [TBD]/[INSERT]/[TODO] outside backticks.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue
  pf="$(placeholder_findings "$f" || true)"
  [ -z "$pf" ] && continue
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    echo "FAIL: [placeholder] $hit"
    FINDINGS=$((FINDINGS + 1))
  done <<INNER
$pf
INNER
done <<EOF
$TRACKED_MD
EOF

# (5) EVENT-LOG-KEY — read sites binding the event log's version column to the
# release-version form instead of the § 2a milestone-slug join key.
EL_SCOPE="$(el_scope_files || true)"
if ! el_scope_ok "$EL_SCOPE"; then
  # Fail loud. A probe that cannot establish its denominator must never report a
  # clean zero — deploy.sh Check 49 escalates exit 3 independent of warn-mode.
  echo "FAIL: check-convention scan-surface error — event-log-key scope resolved to zero files"
  echo "SUMMARY: $((FINDINGS + 1)) finding(s)"
  exit 3
fi
EL_FILES=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  EL_FILES+=("$f")
done <<EOF
$EL_SCOPE
EOF
EL_OUT="$(el_scan "${EL_FILES[@]}" || true)"
EL_DENOM="$(printf '%s\n' "$EL_OUT" | awk '/^@@ /{print $2" "$3" "$4" "$5}')"
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  case "$hit" in @@*) continue ;; esac
  echo "FAIL: [event-log-key] ${hit% \[*} — binds the event-log version column to the release-version form; use the § 2a ladder (--release / the milestone slug), or mark the line \`event-log-key: allow — <reason>\` if the version form is deliberate"
  FINDINGS=$((FINDINGS + 1))
done <<EOF
$EL_OUT
EOF
# The denominator rides the OK: channel deliberately: deploy.sh Check 49's case
# ladder has no default arm, so a novel prefix would be silently discarded.
set -- $EL_DENOM
echo "OK: [event-log-key] DENOM — ${1:-0} file(s) / ${2:-0} line(s) scanned; ${3:-0} marked site(s) suppressed; ${4:-0} fixture data row(s) declared out of class"

if [ "$FINDINGS" -eq 0 ]; then
  echo "OK: no platform-convention findings (naming / layer-2 / evidence-label / placeholder / event-log-key)"
fi
echo "SUMMARY: $FINDINGS finding(s)"
[ "$FINDINGS" -eq 0 ] && exit 0
exit 1
