#!/bin/bash
# check-convention.sh — platform-convention linter engine (#228).
#
# The convention-linter for the FOUR residual platform-convention dimensions that
# no existing gate covers. Invoked by deploy.sh Check 49 (deploy-time, warn-mode-
# initial). NOT a pre-commit hook — CLAUDE.md forbids normalizing `--no-verify`,
# so platform-convention enforcement lives on the deploy.sh check family + an
# optional PR-time job, never a hook that an author is tempted to bypass.
#
# ── OWNED DIMENSIONS (this tool enforces these four) ────────────────────────────
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
  if printf '%s' "$base" | grep -qE '^[A-Z0-9_]+\.md$'; then return 0; fi
  return 1
}

# naming_conformant — true iff basename is lowercase-kebab + .md.
naming_conformant() {
  printf '%s' "$1" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*\.md$'
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

if [ "$FINDINGS" -eq 0 ]; then
  echo "OK: no platform-convention findings (naming / layer-2 / evidence-label / placeholder)"
fi
echo "SUMMARY: $FINDINGS finding(s)"
[ "$FINDINGS" -eq 0 ] && exit 0
exit 1
