#!/usr/bin/env bash
# produce-learnings-register.sh — Stage 13 Phase A7.2 close-out learnings-register
# producer.
# Renders the tracked register template — seeded from the release-learnings triple —
# to the operator-instance register path.
#
# Per the Stage 5 design for #1550 (D-G = (C): a standalone tool, NOT a new phase
# inside automated-closeout.sh). Sibling in shape to compute-cycle-time.sh.
#
# THE PRODUCER SEEDS; THE OPERATOR AUTHORS — a correctness constraint, not a style.
#   compute-close-class-telemetry.sh reads this artifact as a LIVE read-model:
#   Indicator 1 greps the template's canonical section markers as exact whole lines,
#   and Indicator 2 counts an `L<n>` / `A<n>` table row as POPULATED iff no content
#   cell still carries the `…` placeholder. This producer therefore:
#     - preserves every canonical marker verbatim  (its job — canonical FORM), and
#     - NEVER writes into an `L<n>` or `A<n>` cell (not its job — human REFLECTION).
#   Machine-filling those rows would make the read-model report a fully-authored
#   lessons register on a release nobody reflected on. Self-test T2 exists to stop
#   that and must never be relaxed.
#
# Usage:
#   ./produce-learnings-register.sh <version> [flags]        # positional form
#   ./produce-learnings-register.sh --version <version> ...  # alias form (both accepted)
#
# Flags:
#   --version <vX.Y>            release version key. Positional equivalent.
#   --milestone <N>             milestone NUMBER            -> Header "Milestone:"
#   --close-date <YYYY-MM-DD>   close date                  -> Header "Close date:"
#                               (optional; default: date -u +%Y-%m-%d)
#   --release-class <c>         routine|novel|cross-cutting|hotfix -> Header
#   --triple-file <path>        file containing the rendered
#                               "#### Release Learnings v<X.Y>" block. THE
#                               HERMETICITY PRIMITIVE — when given, no synthesizer,
#                               no event log, no host call, no network is reached.
#                               An unreadable path is NON-FATAL: the three fields
#                               take the synthesizer's own N/A sentinel. When the
#                               flag is OMITTED, falls back to invoking
#                               synthesize-release-learnings.sh --mode per-release;
#                               if that is unavailable or empty the sentinel is used
#                               and the register still renders.
#   --apply                     write to the resolved path (mkdir -p the register
#                               dir). Default is dry-run: render to stdout, resolved
#                               path to stderr, ZERO filesystem writes.
#   --force                     with --apply, overwrite an existing register.
#   --print-path                echo the resolved target path and exit 0. Resolves
#                               and echoes WITHOUT creating or reading anything
#                               under the instance root.
#   --self-test                 run unit tests; no side effects outside a temp dir,
#                               no network, no host credential.
#   --help, -h                  this help text.
#
# Output contract:
#   dry-run (default)   stdout = the rendered register  ; stderr = "TARGET: <path>"
#   --apply (wrote)     stdout = "written"              ; stderr = "WROTE: <path>"
#   --apply (existing)  stdout = "preserved"            ; stderr = "PRESERVED: <path> …"
#   --print-path        stdout = the resolved target path
#
# Path resolution goes ONLY through the shipped resolver
# core/deploy/lib-instance-path.sh :: pmo_instance_path() (ADR-032 / ADR-017); the
# version-less branch goes ONLY through the version-grammar SSOT. No instance-path
# literal is inlined anywhere in this file — self-test T10 asserts exactly that.
#
# Cutover: Phase A7.2 applies to releases entering Stage 13 strictly AFTER this
# tool's introducing-release merge SHA; the introducing release is exempt. This
# script does not gate by version — the caller (Stage 13 spoke) honors cutover.
#
# Exit codes:
#   0 = success (includes: rendered to stdout; written; PRESERVED-existing;
#       instance absent under a non---apply mode; N/A triple)
#   1 = invalid args / template missing / lib-instance-path.sh missing
#   2 = malformed source (the template is missing a required anchor, or a triple
#       payload cannot be parsed) — source-integrity violation; escalate

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Two levels up — NOT three; the `../../..` form mis-anchors above the repo from a
# worktree AND from the primary checkout (the #430-class bug, live today in
# compute-release-velocity.sh). REPO_ROOT is load-bearing here: it resolves the
# instance-path resolver, the version-grammar SSOT, and the register template.
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

INSTANCE_LIB="$REPO_ROOT/core/deploy/lib-instance-path.sh"
VERSION_LIB="$REPO_ROOT/release/tools/version-grammar.sh"
TEMPLATE="$REPO_ROOT/release/references/templates/release-learnings-register-template.md"
SYNTH_TOOL="$SCRIPT_DIR/synthesize-release-learnings.sh"

# The kind-per-subdir leaf under the instance release-corpus root. Third sibling of
# ADR-032's `{plans,notes}` bootstrap.
REGISTER_SUBDIR="releases/registers"

# The synthesizer's OWN no-learning sentinel (synthesize-release-learnings.sh). Kept
# byte-identical so a reader cannot tell a degraded render from a genuine N/A triple.
NA_SENTINEL="N/A — no novel learning this release"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,72p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# ─── Argument parsing ────────────────────────────────────────────────────────

VERSION=""
MILESTONE=""
CLOSE_DATE=""
RELEASE_CLASS=""
TRIPLE_FILE=""
TRIPLE_FILE_GIVEN=false
APPLY=false
FORCE=false
PRINT_PATH=false
SELF_TEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) [[ $# -ge 2 ]] || die "--version requires a value"; VERSION="$2"; shift 2 ;;
    --milestone) [[ $# -ge 2 ]] || die "--milestone requires a value"; MILESTONE="$2"; shift 2 ;;
    --close-date) [[ $# -ge 2 ]] || die "--close-date requires a value"; CLOSE_DATE="$2"; shift 2 ;;
    --release-class) [[ $# -ge 2 ]] || die "--release-class requires a value"; RELEASE_CLASS="$2"; shift 2 ;;
    --triple-file) [[ $# -ge 2 ]] || die "--triple-file requires a value"; TRIPLE_FILE="$2"; TRIPLE_FILE_GIVEN=true; shift 2 ;;
    --apply) APPLY=true; shift ;;
    --force) FORCE=true; shift ;;
    --print-path) PRINT_PATH=true; shift ;;
    --self-test) SELF_TEST=true; shift ;;
    --help|-h) usage ;;
    -*) die "Unknown flag: $1" ;;
    *)
      # Positional: first non-flag arg is the version
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
      else
        die "Unexpected positional arg: $1 (version already set to '$VERSION')"
      fi
      shift
      ;;
  esac
done

# ─── Library sourcing ────────────────────────────────────────────────────────
#
# Sourced AFTER the arg loop has consumed every positional, AND with an explicit
# empty positional. version-grammar.sh ends with an `if [[ "${1:-}" == "--self-test" ]]`
# direct-execution guard; a sourced file inherits the CALLER's positionals when the
# `source` call passes none, so sourcing it while `$1` is still `--self-test` would
# run the LIBRARY's self-test and `exit`. Both defenses are deliberate — self-test
# T12 asserts the explicit-positional one, which is the order-independent defense.

[[ -r "$INSTANCE_LIB" ]] || die "instance-path resolver missing at $INSTANCE_LIB"
[[ -r "$VERSION_LIB" ]] || die "version-grammar SSOT missing at $VERSION_LIB"
# shellcheck source=/dev/null
source "$INSTANCE_LIB" ""
# shellcheck source=/dev/null
source "$VERSION_LIB" ""

# ─── Path resolution (resolver-only; no inlined literal) ─────────────────────

# A version key outside the canonical grammar routes under `_unversioned/`, exactly
# as automated-closeout.sh's notes_rel_path() branches the release note — so the two
# per-release artifacts of one release never land under inconsistent topologies. The
# predicate is the version-grammar SSOT's gate, sourced not copied (its consumer
# contract names a copied-inline regex a divergence defect).
is_version_less() { ! version_canonical "$VERSION"; }

resolve_target_path() {
  local dir
  dir="$(pmo_instance_path)/$REGISTER_SUBDIR"
  if is_version_less; then dir="$dir/_unversioned"; fi
  printf '%s/%s_RELEASE_LEARNINGS_REGISTER.md\n' "$dir" "$VERSION"
}

# ─── Triple parsing ──────────────────────────────────────────────────────────

# Echo the value of a `**<label>:** <value>` line from a rendered triple block.
# Empty stdout when the label is absent — the caller substitutes the sentinel.
#
# `-m1` takes the FIRST match, which is correct ONLY when this file is a SINGLE
# release's block. Version-scoping is the caller's job (resolve_triple), not this
# function's — see triple_block_for_version below.
triple_field() {
  local file="$1" label="$2"
  [[ -r "$file" ]] || return 0
  /usr/bin/grep -m1 "^\*\*${label}:\*\* " "$file" 2>/dev/null \
    | /usr/bin/sed "s/^\*\*${label}:\*\* //" || true
}

# True when the source carries at least one `#### Release Learnings <key>` header
# — i.e. it is a MULTI-RELEASE-CAPABLE source and MUST be version-scoped before
# any field is read from it.
triple_has_blocks() {
  /usr/bin/grep -qE '^#### Release Learnings[[:space:]]+[^[:space:]]' "$1" 2>/dev/null
}

# Emit the BODY of the `#### Release Learnings <version>` block for the REQUESTED
# version — header line excluded, terminated by the next block header or EOF.
# Empty stdout when no header matches; the caller must NOT then fall back to a
# whole-file parse, because that is exactly the mis-attribution being prevented.
#
# Matched on the header's version token rather than by position, so scoping does
# not depend on block ordering.
triple_block_for_version() {
  local file="$1" want="$2"
  /usr/bin/awk -v want="$want" '
    /^#### Release Learnings[[:space:]]/ {
      hdr = $0
      sub(/^#### Release Learnings[[:space:]]+/, "", hdr)
      sub(/[[:space:]]+$/, "", hdr)
      inblock = (hdr == want)
      next
    }
    inblock { print }
  ' "$file" 2>/dev/null || true
}

# Populate T_ANCHORS / T_SURPRISE / T_WOULD_CHANGE / T_WATCH_FOR from the triple.
# Every failure path is NON-FATAL and lands on the synthesizer's own sentinel.
resolve_triple() {
  local src=""

  if [[ "$TRIPLE_FILE_GIVEN" == "true" ]]; then
    if [[ -r "$TRIPLE_FILE" ]]; then
      src="$TRIPLE_FILE"
    else
      echo "NOTE: --triple-file '$TRIPLE_FILE' unreadable; seeding with the N/A sentinel" >&2
    fi
  elif [[ -x "$SYNTH_TOOL" ]]; then
    # Fallback: ask the synthesizer. Any failure degrades to the sentinel — this
    # path is never reached from --self-test, which always injects --triple-file.
    src="$RENDER_TMP/triple.md"
    if ! "$SYNTH_TOOL" --mode per-release --version "$VERSION" > "$src" 2>/dev/null; then
      echo "NOTE: synthesizer unavailable or failed; seeding with the N/A sentinel" >&2
      src=""
    fi
  else
    echo "NOTE: no --triple-file and no synthesizer; seeding with the N/A sentinel" >&2
  fi

  # VERSION-SCOPE THE PARSE (#1550 QA Q1). triple_field() reads the FIRST matching
  # label line, so a source carrying more than one release's block seeds whichever
  # block appears first — silently, at exit 0, with the REQUESTED version printed in
  # the register header. Asking for an older version against a multi-block source
  # produced a register headed with that version and carrying the newest release's
  # learnings verbatim, and the read-model scored it a perfect 10/10 because the
  # canonical FORM was intact. That is this milestone's own defect class living
  # inside the deliverable.
  #
  # It is a plausible input, not a theoretical one: Phase A7 renders the triple INTO
  # RELEASE_LOG.md immediately before A7.2 consumes it, so "where is the rendered A7
  # block?" has an obvious, wrong answer. Blocks there are newest-first, so pointing
  # at the log happens to work for the release being closed and ONLY by accident of
  # ordering.
  #
  # Note the irony this preserves rather than hides: `--triple-file` exists as the
  # HERMETICITY primitive (no synthesizer, no event log, no host call), yet it was
  # the UNSAFE path, while the omit-the-flag synthesizer fallback is version-scoped
  # by construction (`--version "$VERSION"`).
  #
  # A source with NO block header carries no version to mis-attribute against and is
  # parsed whole — the hand-rendered fields-only case, unchanged. A source WITH block
  # headers but none matching $VERSION degrades to the sentinel and says so LOUDLY;
  # it never falls through to another release's block.
  if [[ -n "$src" ]] && triple_has_blocks "$src"; then
    local scoped="$RENDER_TMP/triple-scoped.md"
    triple_block_for_version "$src" "$VERSION" > "$scoped"
    if [[ -s "$scoped" ]]; then
      src="$scoped"
    else
      echo "NOTE: '$src' carries release-learnings blocks but none for $VERSION; seeding with the N/A sentinel rather than another release's learnings" >&2
      src=""
    fi
  fi

  T_ANCHORS="N/A"
  T_SURPRISE="$NA_SENTINEL"
  T_WOULD_CHANGE="$NA_SENTINEL"
  T_WATCH_FOR="$NA_SENTINEL"

  [[ -n "$src" ]] || return 0

  local v
  v="$(triple_field "$src" 'Source-row anchors')"; [[ -n "$v" ]] && T_ANCHORS="$v"
  v="$(triple_field "$src" 'Surprise')";           [[ -n "$v" ]] && T_SURPRISE="$v"
  v="$(triple_field "$src" 'Would-change')";       [[ -n "$v" ]] && T_WOULD_CHANGE="$v"
  v="$(triple_field "$src" 'Watch-for')";          [[ -n "$v" ]] && T_WATCH_FOR="$v"
  return 0
}

# ─── Template render ─────────────────────────────────────────────────────────
#
# The template is copied line-for-line; only the anchors below are transformed. The
# 10 canonical markers are NEVER re-declared here — they are already declared in the
# template (the source) and in compute-close-class-telemetry.sh (the consumer), and a
# third copy would be a drift seam. Marker survival is asserted in T1 by extracting
# the headings FROM THE TEMPLATE at test time.
#
# Every required anchor is tracked; a missing one is a template-integrity violation
# and exits 2 rather than silently producing a register the read-model cannot score.
render_register() {
  local out_file="$1"
  set +e
  /usr/bin/python3 - "$TEMPLATE" "$VERSION" "$MILESTONE" "$CLOSE_DATE" "$RELEASE_CLASS" \
    "$T_ANCHORS" "$T_SURPRISE" "$T_WOULD_CHANGE" "$T_WATCH_FOR" > "$out_file" <<'PY'
import sys

(tpl, version, milestone, close_date, release_class,
 anchors, surprise, would_change, watch_for) = sys.argv[1:10]


def esc(v):
    """Escape pipes so a triple value cannot break a 3-column table row."""
    return v.replace("|", "\\|")


SEED_BULLET = "- [seed: triple `{label}`] {value}"
SEED_QUOTE = "> [seed: triple `{label}`] {value}"

try:
    with open(tpl, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
except (OSError, UnicodeDecodeError) as exc:
    print(f"template unreadable: {exc}", file=sys.stderr)
    sys.exit(2)

LINK = {
    "`Surprise`": ("link:Surprise", surprise),
    "`Would-change`": ("link:Would-change", would_change),
    "`Watch-for`": ("link:Watch-for", watch_for),
}

out = []
seen = set()
pending = None          # (anchor-key, triple-label, value) awaiting the next bullet
in_next_cycle = False

for line in lines:
    s = line.strip()

    # ── Header fields ────────────────────────────────────────────────────
    if s.startswith("**Release version:**"):
        out.append("**Release version:** " + version)
        seen.add("hdr:version")
        continue
    if s.startswith("**Milestone:**"):
        out.append("**Milestone:** #" + milestone if milestone else line)
        seen.add("hdr:milestone")
        continue
    if s.startswith("**Close date:**"):
        out.append("**Close date:** " + close_date)
        seen.add("hdr:close-date")
        continue
    if s.startswith("**Release class:**"):
        out.append("**Release class:** " + release_class if release_class else line)
        seen.add("hdr:release-class")
        continue
    if s.startswith("**Triple source-row anchors:**"):
        out.append("**Triple source-row anchors:** " + anchors)
        seen.add("hdr:anchors")
        continue

    # ── Seed anchors: arm on the prompt, fire on the prompt's own bullet ──
    # The template's prompt bullet is RETAINED in every case — the operator sees
    # the machine seed and the unfilled prompt side by side, which is what makes
    # "seed, then expand" executable rather than aspirational.
    if s.startswith("**What did we learn?**"):
        out.append(line)
        pending = ("seed:1.2-learn", "Surprise", surprise)
        continue
    if s.startswith("**What would we do differently?**"):
        out.append(line)
        pending = ("seed:1.2-differently", "Would-change", would_change)
        continue
    if s == "### 2.1 Situation":
        out.append(line)
        pending = ("seed:2.1-situation", "Surprise", surprise)
        continue
    if s == "### 2.4 Next-cycle Actions":
        out.append(line)
        in_next_cycle = True
        continue

    if pending is not None and s.startswith("- "):
        key, label, value = pending
        out.append(line)
        out.append(SEED_BULLET.format(label=label, value=value))
        seen.add(key)
        pending = None
        continue

    # ── §2.4 seeds land ABOVE the Actions table, never inside it (DD-4) ───
    if in_next_cycle and s.startswith("| # |"):
        out.append(SEED_QUOTE.format(label="Would-change", value=would_change))
        out.append(SEED_QUOTE.format(label="Watch-for", value=watch_for))
        out.append("")
        out.append(line)
        seen.add("seed:2.4-blockquote")
        in_next_cycle = False
        continue

    # ── §3 Triple Linkage: fill column 2 only; column 3 is template-owned ─
    # An `L<n>` / `A<n>` row can never match this branch, so the Indicator-2
    # population count stays honest by construction.
    if s.startswith("|"):
        cells = s.strip("|").split("|")
        first = cells[0].strip()
        if first in LINK and len(cells) >= 2:
            key, value = LINK[first]
            cells[1] = " " + esc(value) + " "
            out.append("|" + "|".join(cells) + "|")
            seen.add(key)
            continue

    out.append(line)

REQUIRED = [
    "hdr:version", "hdr:milestone", "hdr:close-date", "hdr:release-class", "hdr:anchors",
    "seed:1.2-learn", "seed:1.2-differently", "seed:2.1-situation", "seed:2.4-blockquote",
    "link:Surprise", "link:Would-change", "link:Watch-for",
]
missing = [k for k in REQUIRED if k not in seen]
if missing:
    print("template anchor(s) not found: " + ", ".join(missing), file=sys.stderr)
    sys.exit(2)

# Byte-level write: the template carries U+2026 `…`, em dashes and `≤`, and a
# locale-derived stdout encoding (LC_ALL=C on a runner) would raise on them.
sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
PY
  local rc=$?
  set -e
  return $rc
}

# ─── Self-test mode ──────────────────────────────────────────────────────────

if [[ "$SELF_TEST" == "true" ]]; then
  SELF="${BASH_SOURCE[0]}"
  TMP="$(/usr/bin/mktemp -d)"
  trap '/bin/rm -rf "$TMP"' EXIT

  T_PASS=0
  T_FAIL=0
  _ok()   { T_PASS=$((T_PASS + 1)); echo "  PASS  $1"; }
  _bad()  { T_FAIL=$((T_FAIL + 1)); echo "  FAIL  $1"; }
  _eq()   { if [[ "$2" == "$3" ]]; then _ok "$1"; else _bad "$1 — expected '$3', got '$2'"; fi; }
  _ne()   { if [[ "$2" != "$3" ]]; then _ok "$1"; else _bad "$1 — unexpectedly equal to '$3'"; fi; }
  _ge()   { if [[ -n "$2" ]] && [[ "$2" -ge "$3" ]]; then _ok "$1"; else _bad "$1 — expected >= $3, got '$2'"; fi; }
  # Strictly-between, and FAILS LOUD on any empty operand (an absent anchor must
  # never pass by arithmetic accident).
  _between() {
    if [[ -n "$2" && -n "$3" && -n "$4" && "$2" -gt "$3" && "$2" -lt "$4" ]]; then
      _ok "$1"
    else
      _bad "$1 — line '$2' not strictly within ($3,$4)"
    fi
  }
  _lineno() { /usr/bin/grep -n -F -- "$2" "$1" 2>/dev/null | /usr/bin/sed -n "${3:-1}p" | /usr/bin/cut -d: -f1; }
  _count()  { /usr/bin/grep -c -F -- "$2" "$1" 2>/dev/null || true; }

  # ── Fixtures ───────────────────────────────────────────────────────────
  FX_A="$TMP/triple-alpha.md"      # ordinary triple
  FX_PIPE="$TMP/triple-pipe.md"    # pipe-bearing values (table-integrity fixture)
  FX_NA="$TMP/triple-na.md"        # all-N/A triple

  /bin/cat > "$FX_A" <<'FIXTURE'
#### Release Learnings v0.00

**Synthesized at:** 2026-01-01T00:00:00Z
**Source events:** 2 `release-synthesis/learnings-triple` row(s) from `pipeline-event-log.md` (filter: release=`v0.00`)
**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `2026-01-01T00:00:00Z`, `2026-01-02T00:00:00Z`

**Surprise:** SURPRISE-FIXTURE-ALPHA
**Would-change:** WOULDCHANGE-FIXTURE-BETA
**Watch-for:** WATCHFOR-FIXTURE-GAMMA
FIXTURE

  /bin/cat > "$FX_PIPE" <<'FIXTURE'
#### Release Learnings v0.00

**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `2026-01-03T00:00:00Z`
**Surprise:** pipe|bearing|surprise
**Would-change:** pipe|bearing|would-change
**Watch-for:** pipe|bearing|watch-for
FIXTURE

  /bin/cat > "$FX_NA" <<FIXTURE
#### Release Learnings v0.00

**Source-row anchors:** N/A

**Surprise:** $NA_SENTINEL
**Would-change:** $NA_SENTINEL
**Watch-for:** $NA_SENTINEL
FIXTURE

  # ── T13 fixtures — version-scoping (#1550 QA Q1) ───────────────────────
  # FX_MULTI reproduces the defect ORDER: the wrong release's block sorts FIRST,
  # which is what an unscoped first-match parse would take. Its values are a
  # disjoint token set (OTHERREL-*) so a leak in either direction is countable.
  FX_MULTI="$TMP/triple-multi.md"       # v9.99 block ABOVE the v0.00 block
  FX_OTHERONLY="$TMP/triple-otheronly.md"  # ONLY a v9.99 block
  FX_NOHDR="$TMP/triple-nohdr.md"       # fields only, no block header

  /bin/cat > "$FX_MULTI" <<'FIXTURE'
#### Release Learnings v9.99

**Source-row anchors:** ANCHORS-OTHER-RELEASE
**Surprise:** OTHERREL-SURPRISE
**Would-change:** OTHERREL-WOULDCHANGE
**Watch-for:** OTHERREL-WATCHFOR

#### Release Learnings v0.00

**Source-row anchors:** ANCHORS-WANTED-RELEASE
**Surprise:** SURPRISE-FIXTURE-ALPHA
**Would-change:** WOULDCHANGE-FIXTURE-BETA
**Watch-for:** WATCHFOR-FIXTURE-GAMMA
FIXTURE

  /bin/cat > "$FX_OTHERONLY" <<'FIXTURE'
#### Release Learnings v9.99

**Source-row anchors:** ANCHORS-OTHER-RELEASE
**Surprise:** OTHERREL-SURPRISE
**Would-change:** OTHERREL-WOULDCHANGE
**Watch-for:** OTHERREL-WATCHFOR
FIXTURE

  /bin/cat > "$FX_NOHDR" <<'FIXTURE'
**Source-row anchors:** ANCHORS-NOHDR
**Surprise:** NOHDR-SURPRISE
**Would-change:** NOHDR-WOULDCHANGE
**Watch-for:** NOHDR-WATCHFOR
FIXTURE

  # A header carrying TRAILING WHITESPACE. Built with printf, not a heredoc, so
  # the trailing space is explicit and cannot be stripped by an editor or linter.
  # Without the matcher's right-trim this header silently fails to match and the
  # register degrades to the sentinel — fail-safe, but a claimed tolerance that
  # nothing asserted.
  FX_TRAILWS="$TMP/triple-trailws.md"
  {
    /usr/bin/printf '#### Release Learnings v9.99\n\n'
    /usr/bin/printf '**Source-row anchors:** ANCHORS-OTHER-RELEASE\n'
    /usr/bin/printf '**Surprise:** OTHERREL-SURPRISE\n'
    /usr/bin/printf '**Would-change:** OTHERREL-WOULDCHANGE\n'
    /usr/bin/printf '**Watch-for:** OTHERREL-WATCHFOR\n\n'
    /usr/bin/printf '#### Release Learnings v0.00  \n\n'
    /usr/bin/printf '**Source-row anchors:** ANCHORS-WANTED-RELEASE\n'
    /usr/bin/printf '**Surprise:** SURPRISE-FIXTURE-ALPHA\n'
    /usr/bin/printf '**Would-change:** WOULDCHANGE-FIXTURE-BETA\n'
    /usr/bin/printf '**Watch-for:** WATCHFOR-FIXTURE-GAMMA\n'
  } > "$FX_TRAILWS"

  # A DUPLICATED label in a header-less source — the shape that makes triple_field's
  # `-m1` load-bearing. Without it, grep emits both lines and the field becomes a
  # two-line value that corrupts the §3 Linkage table.
  FX_DUPLABEL="$TMP/triple-duplabel.md"
  /bin/cat > "$FX_DUPLABEL" <<'FIXTURE'
**Source-row anchors:** ANCHORS-DUP
**Surprise:** DUP-FIRST-SURPRISE
**Surprise:** DUP-SECOND-SURPRISE
**Would-change:** DUP-WOULDCHANGE
**Watch-for:** DUP-WATCHFOR
FIXTURE

  # ── Fixture PRECONDITIONS ──────────────────────────────────────────────
  # A fixture that failed to build must FAIL the suite, never quietly satisfy an
  # assertion that then passes against nothing.
  _eq "P1 fixture alpha carries all three triple fields" \
      "$(/usr/bin/grep -cE '^\*\*(Surprise|Would-change|Watch-for):\*\* ' "$FX_A" || true)" "3"
  _eq "P2 pipe fixture values actually contain a literal pipe" \
      "$(/usr/bin/grep -c 'pipe|bearing' "$FX_PIPE" || true)" "3"
  _eq "P3 N/A fixture carries the synthesizer's verbatim sentinel" \
      "$(/usr/bin/grep -cF -- "$NA_SENTINEL" "$FX_NA" || true)" "3"
  if [[ -r "$TEMPLATE" ]]; then _ok "P4 tracked template is readable"; else _bad "P4 tracked template missing at $TEMPLATE"; fi
  _eq "P6 multi-block fixture carries exactly two release-learnings block headers" \
      "$(/usr/bin/grep -cE '^#### Release Learnings ' "$FX_MULTI" || true)" "2"
  _eq "P7 multi-block fixture carries the OTHER release's values (so a leak is countable)" \
      "$(/usr/bin/grep -c 'OTHERREL-' "$FX_MULTI" || true)" "3"
  _eq "P8 the OTHER release's block sorts FIRST (reproducing the first-match defect order)" \
      "$(/usr/bin/grep -E '^#### Release Learnings ' "$FX_MULTI" | /usr/bin/sed -n 1p)" \
      "#### Release Learnings v9.99"
  _eq "P9 header-less fixture carries NO block header (the backward-compat shape)" \
      "$(/usr/bin/grep -cE '^#### Release Learnings ' "$FX_NOHDR" || true)" "0"
  _eq "P10 trailing-whitespace fixture's wanted header really ends in whitespace" \
      "$(/usr/bin/grep -cE '^#### Release Learnings v0\.00[[:space:]]+$' "$FX_TRAILWS" || true)" "1"
  _eq "P11 duplicate-label fixture really carries two Surprise lines" \
      "$(/usr/bin/grep -cE '^\*\*Surprise:\*\* ' "$FX_DUPLABEL" || true)" "2"

  RENDER_A="$TMP/render-alpha.md"
  /bin/bash "$SELF" v0.00 --triple-file "$FX_A" --milestone 304 \
    --close-date 2026-01-15 --release-class novel > "$RENDER_A" 2>/dev/null \
    || _bad "P5 baseline render exited non-zero"
  _ge "P5 baseline render is non-empty" "$(/usr/bin/wc -l < "$RENDER_A" | /usr/bin/tr -d ' ')" "80"

  # ── T1 — every canonical marker survives verbatim ──────────────────────
  HEADINGS="$TMP/headings.txt"
  /usr/bin/grep -E '^#{2,3} ' "$TEMPLATE" > "$HEADINGS" || true
  H_COUNT="$(/usr/bin/wc -l < "$HEADINGS" | /usr/bin/tr -d ' ')"
  # Anti-vacuity floor: the consumer's Indicator-1 contract expects 10 markers. A
  # zero-heading extraction would make the survival loop pass without executing.
  _ge "T1a template yields >= 10 canonical headings (extraction non-vacuous)" "$H_COUNT" "10"
  T1_MISSING=0
  while IFS= read -r _h; do
    [[ -z "$_h" ]] && continue
    /usr/bin/grep -Fxq -- "$_h" "$RENDER_A" || T1_MISSING=$((T1_MISSING + 1))
  done < "$HEADINGS"
  _eq "T1b every template heading survives as an exact line in the render" "$T1_MISSING" "0"

  # ── T2 — the Indicator-2 contract: L*/A* rows stay placeholder-bearing ──
  _eq "T2a L<n>/A<n> rows still carry the … placeholder after seeding" \
      "$(/usr/bin/grep -E '^\| (L|A)[0-9]+ \|' "$RENDER_A" | /usr/bin/grep -c '…' || true)" "2"
  _eq "T2b no triple value leaked into an L<n>/A<n> row" \
      "$(/usr/bin/grep -E '^\| (L|A)[0-9]+ \|' "$RENDER_A" | /usr/bin/grep -cE 'SURPRISE-FIXTURE|WOULDCHANGE-FIXTURE|WATCHFOR-FIXTURE' || true)" "0"

  # ── T3 — each seed lands in its OWN section (positional, not substring) ─
  L_LEARN="$(_lineno "$RENDER_A" '**What did we learn?**')"
  L_DIFF="$(_lineno "$RENDER_A" '**What would we do differently?**')"
  L_RITUAL="$(_lineno "$RENDER_A" '### 1.3 Ritual of closure')"
  L_SIT="$(_lineno "$RENDER_A" '### 2.1 Situation')"
  L_OUT="$(_lineno "$RENDER_A" '### 2.2 Outcome')"
  L_NEXT="$(_lineno "$RENDER_A" '### 2.4 Next-cycle Actions')"
  L_A1="$(_lineno "$RENDER_A" '| A1 |')"
  S_SEED_1="$(_lineno "$RENDER_A" '- [seed: triple `Surprise`] SURPRISE-FIXTURE-ALPHA' 1)"
  S_SEED_2="$(_lineno "$RENDER_A" '- [seed: triple `Surprise`] SURPRISE-FIXTURE-ALPHA' 2)"
  W_SEED="$(_lineno "$RENDER_A" '- [seed: triple `Would-change`] WOULDCHANGE-FIXTURE-BETA')"
  W_QUOTE="$(_lineno "$RENDER_A" '> [seed: triple `Would-change`] WOULDCHANGE-FIXTURE-BETA')"
  H_QUOTE="$(_lineno "$RENDER_A" '> [seed: triple `Watch-for`] WATCHFOR-FIXTURE-GAMMA')"

  _eq "T3a Surprise seeds exactly twice (1.2 learn + 2.1 Situation)" \
      "$(_count "$RENDER_A" '- [seed: triple `Surprise`] SURPRISE-FIXTURE-ALPHA')" "2"
  _between "T3b Surprise seed 1 sits inside 1.2 'what did we learn'" "$S_SEED_1" "$L_LEARN" "$L_DIFF"
  _between "T3c Would-change seed sits inside 1.2 'what would we do differently'" "$W_SEED" "$L_DIFF" "$L_RITUAL"
  _between "T3d Surprise seed 2 sits inside 2.1 Situation" "$S_SEED_2" "$L_SIT" "$L_OUT"
  _between "T3e Would-change blockquote sits between 2.4 and the A<n> table" "$W_QUOTE" "$L_NEXT" "$L_A1"
  _between "T3f Watch-for blockquote sits between 2.4 and the A<n> table" "$H_QUOTE" "$L_NEXT" "$L_A1"
  _eq "T3g the template's own prompt bullets are RETAINED, not replaced" \
      "$(/usr/bin/grep -c '^- <…>$' "$RENDER_A" || true)" \
      "$(/usr/bin/grep -c '^- <…>$' "$TEMPLATE" || true)"

  # ── T4 — §3 Linkage fills, and a pipe-bearing value stays 3 columns ─────
  _eq "T4a linkage rows carry all three verbatim values" \
      "$(/usr/bin/grep -cE '^\| `(Surprise|Would-change|Watch-for)` \| (SURPRISE|WOULDCHANGE|WATCHFOR)-FIXTURE' "$RENDER_A" || true)" "3"
  RENDER_PIPE="$TMP/render-pipe.md"
  /bin/bash "$SELF" v0.00 --triple-file "$FX_PIPE" > "$RENDER_PIPE" 2>/dev/null \
    || _bad "T4 pipe-fixture render exited non-zero"
  _eq "T4b a pipe-bearing value is escaped so linkage rows still parse to 3 columns" \
      "$(/usr/bin/python3 -c '
import sys, re
bad = 0
for line in open(sys.argv[1], encoding="utf-8"):
    s = line.strip()
    if not s.startswith("| `"):
        continue
    if not re.match(r"^\| `(Surprise|Would-change|Watch-for)` \|", s):
        continue
    # split on UNESCAPED pipes only
    cells = re.split(r"(?<!\\)\|", s.strip("|"))
    if len(cells) != 3:
        bad += 1
print(bad)' "$RENDER_PIPE")" "0"
  _eq "T4c the pipe-bearing value survives verbatim (escaped, not truncated)" \
      "$(/usr/bin/grep -c 'pipe\\|bearing\\|surprise' "$RENDER_PIPE" || true)" "1"

  # ── T5 — all-N/A triple still renders a canonical, honest register ──────
  RENDER_NA="$TMP/render-na.md"
  /bin/bash "$SELF" v0.00 --triple-file "$FX_NA" > "$RENDER_NA" 2>/dev/null \
    || _bad "T5 N/A-fixture render exited non-zero"
  T5_MISSING=0
  while IFS= read -r _h; do
    [[ -z "$_h" ]] && continue
    /usr/bin/grep -Fxq -- "$_h" "$RENDER_NA" || T5_MISSING=$((T5_MISSING + 1))
  done < "$HEADINGS"
  _eq "T5a canonical markers survive an all-N/A render" "$T5_MISSING" "0"
  _eq "T5b §3 Linkage records the N/A sentinel on all three rows" \
      "$(/usr/bin/grep -E '^\| `(Surprise|Would-change|Watch-for)` \|' "$RENDER_NA" | /usr/bin/grep -cF -- "$NA_SENTINEL" || true)" "3"
  _eq "T5c L<n>/A<n> rows are still placeholder-bearing under N/A" \
      "$(/usr/bin/grep -E '^\| (L|A)[0-9]+ \|' "$RENDER_NA" | /usr/bin/grep -c '…' || true)" "2"

  # ── T6 — an unreadable --triple-file is NON-FATAL ───────────────────────
  set +e
  /bin/bash "$SELF" v0.00 --triple-file "$TMP/does-not-exist.md" > "$TMP/render-missing.md" 2>/dev/null
  T6_RC=$?
  set -e
  _eq "T6a unreadable --triple-file exits 0 (non-fatal)" "$T6_RC" "0"
  _eq "T6b unreadable --triple-file falls back to the sentinel in §3" \
      "$(/usr/bin/grep -E '^\| `(Surprise|Would-change|Watch-for)` \|' "$TMP/render-missing.md" | /usr/bin/grep -cF -- "$NA_SENTINEL" || true)" "3"

  # ── T7 — --print-path resolves without touching the instance root ───────
  ABSENT="$TMP/absent-instance"
  set +e
  T7_OUT="$(PMO_INSTANCE_PATH="$ABSENT" /bin/bash "$SELF" v0.00 --print-path 2>/dev/null)"
  T7_RC=$?
  set -e
  _eq "T7a --print-path exits 0 against an absent instance" "$T7_RC" "0"
  _eq "T7b --print-path echoes the resolved register path" \
      "$T7_OUT" "$ABSENT/releases/registers/v0.00_RELEASE_LEARNINGS_REGISTER.md"
  if [[ ! -d "$ABSENT" ]]; then _ok "T7c --print-path created nothing under the instance root"; else _bad "T7c --print-path created $ABSENT"; fi

  # ── T8 — a version-less key routes under _unversioned/ ──────────────────
  set +e
  T8_OUT="$(PMO_INSTANCE_PATH="$ABSENT" /bin/bash "$SELF" not-a-version --print-path 2>/dev/null)"
  set -e
  _eq "T8a version-less key routes under _unversioned/" \
      "$T8_OUT" "$ABSENT/releases/registers/_unversioned/not-a-version_RELEASE_LEARNINGS_REGISTER.md"
  set +e
  T8_CANON="$(PMO_INSTANCE_PATH="$ABSENT" /bin/bash "$SELF" v1.02.3 --print-path 2>/dev/null)"
  set -e
  _eq "T8b a canonical three-component key does NOT route under _unversioned/" \
      "$T8_CANON" "$ABSENT/releases/registers/v1.02.3_RELEASE_LEARNINGS_REGISTER.md"

  # ── T9 — --apply writes, PRESERVES on re-run, overwrites only on --force ─
  INST="$TMP/inst"
  set +e
  T9_OUT1="$(PMO_INSTANCE_PATH="$INST" /bin/bash "$SELF" v0.00 --triple-file "$FX_A" --close-date 2026-01-15 --apply 2>/dev/null)"
  T9_RC1=$?
  set -e
  T9_TARGET="$INST/releases/registers/v0.00_RELEASE_LEARNINGS_REGISTER.md"
  _eq "T9a --apply exits 0" "$T9_RC1" "0"
  _eq "T9b --apply emits the 'written' token on stdout" "$T9_OUT1" "written"
  if [[ -f "$T9_TARGET" ]]; then _ok "T9c --apply created the register (mkdir -p on an absent root)"; else _bad "T9c register absent at $T9_TARGET"; fi
  /bin/cp "$T9_TARGET" "$TMP/first-write.md"

  set +e
  T9_OUT2="$(PMO_INSTANCE_PATH="$INST" /bin/bash "$SELF" v0.00 --triple-file "$FX_A" --close-date 2099-12-31 --apply 2>"$TMP/t9.err")"
  T9_RC2=$?
  set -e
  _eq "T9d re-run over an existing register exits 0 (a resumed close stays alive)" "$T9_RC2" "0"
  _eq "T9e re-run emits the 'preserved' token on stdout" "$T9_OUT2" "preserved"
  _eq "T9f re-run announces PRESERVED on stderr (not silent)" \
      "$(/usr/bin/grep -c 'PRESERVED:' "$TMP/t9.err" || true)" "1"
  if /usr/bin/cmp -s "$T9_TARGET" "$TMP/first-write.md"; then _ok "T9g re-run left the authored register byte-identical"; else _bad "T9g re-run clobbered the register"; fi

  set +e
  PMO_INSTANCE_PATH="$INST" /bin/bash "$SELF" v0.00 --triple-file "$FX_A" --close-date 2099-12-31 --apply --force >/dev/null 2>&1
  T9_RC3=$?
  set -e
  _eq "T9h --force exits 0" "$T9_RC3" "0"
  if /usr/bin/cmp -s "$T9_TARGET" "$TMP/first-write.md"; then _bad "T9i --force did not overwrite"; else _ok "T9i --force overwrote the register"; fi

  # ── T10 — the single-resolver assertion (retains withdrawn CIAC-5's predicate)
  # The needle is ASSEMBLED at runtime so this assertion cannot match its own
  # source line — a literal here would make the probe permanently self-failing.
  T10_NEEDLE="$(/usr/bin/printf 'personal/pmo-%s' 'instance')"
  _eq "T10 no instance-path literal is inlined (resolver is the only route)" \
      "$(/usr/bin/grep -c "$T10_NEEDLE" "$SELF" || true)" "0"

  # ── T11 — hermeticity: no host credential, no network, ever ─────────────
  set +e
  PATH="/usr/bin:/bin" /bin/bash "$SELF" v0.00 --triple-file "$FX_A" >/dev/null 2>&1
  T11_RC=$?
  set -e
  _eq "T11a render succeeds with a PATH carrying no host CLI" "$T11_RC" "0"
  # Needles assembled at runtime for the same self-match reason as T10.
  T11_HOST="$(/usr/bin/printf 'g%s (auth|api|issue|release|pr|repo) ' 'h')"
  T11_NET="$(/usr/bin/printf 'cur%s|wge%s|git fetc%s|git pus%s' 'l' 't' 'h' 'h')"
  _eq "T11b no host-CLI invocation is reachable in this file" \
      "$(/usr/bin/grep -cE "$T11_HOST" "$SELF" || true)" "0"
  _eq "T11c no network / remote-git invocation is reachable in this file" \
      "$(/usr/bin/grep -cE "$T11_NET" "$SELF" || true)" "0"

  # ── T12 — sourcing hygiene (hazard found at implementation) ─────────────
  # version-grammar.sh ends in an `if [[ "${1:-}" == "--self-test" ]]` direct-run
  # guard. `source lib` with no arguments inherits the CALLER's positionals, so a
  # future edit that hoists the source above the arg loop — or drops the explicit
  # empty positional — would run the LIBRARY's self-test and exit. Reaching this
  # assertion at all proves the current runtime order is clean; the grep is the
  # order-independent guard on the explicit positional.
  _eq "T12 version-grammar.sh is sourced with an explicit positional (guard cannot inherit --self-test)" \
      "$(/usr/bin/grep -cE 'source "\$VERSION_LIB" ""' "$SELF" || true)" "1"

  # ── T13 — the triple parse is VERSION-SCOPED (#1550 QA Q1) ──────────────
  # A mis-attributed parse is the failure this group exists to catch: a register
  # headed with the requested version but carrying ANOTHER release's learnings,
  # at exit 0, scoring a perfect read-model conformance because the canonical FORM
  # is intact. Every assertion below is stated as a COUNT of the other release's
  # disjoint token set, so "no leak" is measured rather than assumed.
  RENDER_MULTI="$TMP/render-multi.md"
  /bin/bash "$SELF" v0.00 --triple-file "$FX_MULTI" > "$RENDER_MULTI" 2>/dev/null \
    || _bad "T13 multi-block render exited non-zero"
  _eq "T13a asking for v0.00 seeds v0.00's OWN values on all three linkage rows" \
      "$(/usr/bin/grep -cE '^\| `(Surprise|Would-change|Watch-for)` \| (SURPRISE|WOULDCHANGE|WATCHFOR)-FIXTURE' "$RENDER_MULTI" || true)" "3"
  _eq "T13b ZERO of the other release's values appear ANYWHERE in the register" \
      "$(/usr/bin/grep -c 'OTHERREL-' "$RENDER_MULTI" || true)" "0"
  _eq "T13c the other release's source-row anchors do not leak into §3 either" \
      "$(/usr/bin/grep -c 'ANCHORS-OTHER-RELEASE' "$RENDER_MULTI" || true)" "0"
  _eq "T13d the register header names the REQUESTED version (header/content pair)" \
      "$(/usr/bin/grep -c '^\*\*Release version:\*\* v0.00$' "$RENDER_MULTI" || true)" "1"

  # Scoping selects by HEADER, not by position — ask for the block that sorts
  # first and the leak must not run the other way either.
  RENDER_OTHER="$TMP/render-other.md"
  /bin/bash "$SELF" v9.99 --triple-file "$FX_MULTI" > "$RENDER_OTHER" 2>/dev/null \
    || _bad "T13 v9.99 render exited non-zero"
  _eq "T13e asking for v9.99 selects the v9.99 block by header, not by position" \
      "$(/usr/bin/grep -cE '^\| `(Surprise|Would-change|Watch-for)` \| OTHERREL-' "$RENDER_OTHER" || true)" "3"
  _eq "T13f ...and v0.00's values do not leak the other way" \
      "$(/usr/bin/grep -cE '^\| `(Surprise|Would-change|Watch-for)` \| (SURPRISE|WOULDCHANGE|WATCHFOR)-FIXTURE' "$RENDER_OTHER" || true)" "0"

  # A source that carries blocks but NONE for the requested version must degrade
  # to the sentinel LOUDLY — never fall through to whatever block is present.
  RENDER_MISS="$TMP/render-miss.md"
  set +e
  /bin/bash "$SELF" v0.00 --triple-file "$FX_OTHERONLY" > "$RENDER_MISS" 2>"$TMP/t13.err"
  T13_RC=$?
  set -e
  _eq "T13g a source with no block for the requested version exits 0 (non-fatal)" "$T13_RC" "0"
  _eq "T13h ...seeds the N/A sentinel on all three linkage rows" \
      "$(/usr/bin/grep -E '^\| `(Surprise|Would-change|Watch-for)` \|' "$RENDER_MISS" | /usr/bin/grep -cF -- "$NA_SENTINEL" || true)" "3"
  _eq "T13i ...and leaks NONE of the present-but-wrong release's values" \
      "$(/usr/bin/grep -c 'OTHERREL-' "$RENDER_MISS" || true)" "0"
  _eq "T13j ...and announces the degradation on stderr (silent degradation IS the defect class)" \
      "$(/usr/bin/grep -c 'none for v0.00' "$TMP/t13.err" || true)" "1"

  # BACKWARD COMPATIBILITY — a header-less source has no version to mis-attribute
  # against and is still parsed whole. Without this, scoping would silently break
  # every hand-rendered fields-only triple.
  RENDER_NOHDR="$TMP/render-nohdr.md"
  /bin/bash "$SELF" v0.00 --triple-file "$FX_NOHDR" > "$RENDER_NOHDR" 2>/dev/null \
    || _bad "T13 header-less render exited non-zero"
  _eq "T13k a header-less triple source is still parsed whole (no version to mis-attribute)" \
      "$(/usr/bin/grep -cE '^\| `(Surprise|Would-change|Watch-for)` \| NOHDR-' "$RENDER_NOHDR" || true)" "3"

  # The matcher's right-trim is load-bearing, not decorative: a real ledger header
  # with a trailing space must still match rather than degrade to the sentinel.
  RENDER_TWS="$TMP/render-trailws.md"
  /bin/bash "$SELF" v0.00 --triple-file "$FX_TRAILWS" > "$RENDER_TWS" 2>/dev/null \
    || _bad "T13 trailing-whitespace render exited non-zero"
  _eq "T13l a header with trailing whitespace still matches the requested version" \
      "$(/usr/bin/grep -cE '^\| `(Surprise|Would-change|Watch-for)` \| (SURPRISE|WOULDCHANGE|WATCHFOR)-FIXTURE' "$RENDER_TWS" || true)" "3"
  _eq "T13m ...and does not fall through to the other release's block" \
      "$(/usr/bin/grep -c 'OTHERREL-' "$RENDER_TWS" || true)" "0"

  # triple_field's `-m1` is load-bearing on the un-scoped (header-less) path: a
  # duplicated label must yield ONE value, not a two-line value that breaks §3.
  RENDER_DUP="$TMP/render-duplabel.md"
  /bin/bash "$SELF" v0.00 --triple-file "$FX_DUPLABEL" > "$RENDER_DUP" 2>/dev/null \
    || _bad "T13 duplicate-label render exited non-zero"
  _eq "T13n a duplicated label takes the FIRST value only (-m1 is load-bearing)" \
      "$(/usr/bin/grep -c 'DUP-SECOND-SURPRISE' "$RENDER_DUP" || true)" "0"
  _eq "T13o ...and §3 Linkage carries exactly one well-formed Surprise row" \
      "$(/usr/bin/grep -cE '^\| `Surprise` \| DUP-FIRST-SURPRISE \|' "$RENDER_DUP" || true)" "1"

  # ── Summary ────────────────────────────────────────────────────────────
  echo ""
  if [[ "$T_FAIL" -ne 0 ]]; then
    echo "self-test: FAIL ($T_FAIL failing assertion(s), $T_PASS passing)"
    exit 1
  fi
  echo "self-test: PASS"
  echo "  $T_PASS assertions green (11 fixture preconditions + T1..T13)"
  echo "  Indicator-1 contract: every template heading survives verbatim"
  echo "  Indicator-2 contract: L<n>/A<n> rows stay placeholder-bearing (producer seeds, operator authors)"
  echo "  seed placement validated positionally (1.2 learn / 1.2 differently / 2.1 / 2.4 blockquote)"
  echo "  path resolution validated through the shipped resolver only; no inlined literal"
  echo "  absent-instance, version-less, PRESERVE-vs---force and hermeticity paths validated"
  echo "  triple parse is VERSION-SCOPED (#1550 Q1 — a multi-block source seeds only the requested"
  echo "    version's block, selected by header not position, zero cross-release leak either way;"
  echo "    a source with no block for that version degrades to the sentinel LOUDLY; a header-less"
  echo "    source is still parsed whole)"
  exit 0
fi

# ─── Required-field validation ───────────────────────────────────────────────

[[ -z "$VERSION" ]] && die "Required: <version> (positional or --version)"

# --print-path resolves and echoes WITHOUT touching the instance root or the
# template. Deliberately the first exit after validation: a fresh clone or a CI
# runner must be able to ask for the path with zero filesystem effect.
if [[ "$PRINT_PATH" == "true" ]]; then
  resolve_target_path
  exit 0
fi

[[ -r "$TEMPLATE" ]] || die "register template missing at $TEMPLATE"

# ─── Render ──────────────────────────────────────────────────────────────────

RENDER_TMP="$(/usr/bin/mktemp -d)"
trap '/bin/rm -rf "$RENDER_TMP"' EXIT

[[ -n "$CLOSE_DATE" ]] || CLOSE_DATE="$(/bin/date -u +%Y-%m-%d)"

T_ANCHORS=""
T_SURPRISE=""
T_WOULD_CHANGE=""
T_WATCH_FOR=""
resolve_triple

RENDERED="$RENDER_TMP/register.md"
render_register "$RENDERED" || die "template render failed — a required anchor is missing or the template is unreadable" 2

TARGET="$(resolve_target_path)"

# ─── Emit ────────────────────────────────────────────────────────────────────

if [[ "$APPLY" != "true" ]]; then
  # Dry-run: the resolved path goes to stderr, the register to stdout. ZERO writes,
  # so instance absence is structurally irrelevant on this path.
  echo "TARGET: $TARGET" >&2
  /bin/cat "$RENDERED"
  exit 0
fi

if [[ -f "$TARGET" && "$FORCE" != "true" ]]; then
  # The register is human-authored reflection. A resumed Stage-13 close must
  # neither abort (exit 0 keeps the resume alive) nor silently clobber it (the
  # explicit token keeps the preservation from being invisible).
  echo "PRESERVED: $TARGET already exists (use --force to overwrite)" >&2
  echo "preserved"
  exit 0
fi

/bin/mkdir -p "$(/usr/bin/dirname "$TARGET")"
/bin/cat "$RENDERED" > "$TARGET"
echo "WROTE: $TARGET" >&2
echo "written"
exit 0
