#!/usr/bin/env bash
# test_corpus_home_tolerance.sh — corpus-home adapter tolerance conformance suite
#
# ─── Why this exists ─────────────────────────────────────────────────────────
#
# The constraint under test is CH-1..CH-4 of
#   release/references/standards/corpus-home-adapter-constraints.md
# chiefly CH-1: when corpus-path resolution becomes instance-aware and the
# instance-corpus root is ABSENT, `automated-closeout.sh --check-paths` must
# record N/A and exit 0 — never HARD-FAIL. It is a REQUIRED step of the
# closeout-smoke CI job, so a HARD-FAIL-on-absence resolver reddens every PR
# raised from a fresh clone or a CI runner.
#
# ─── The vacuity trap this suite exists to avoid ─────────────────────────────
#
# The obvious test is "set PMO_INSTANCE_PATH to a nonexistent directory and
# assert --check-paths exits 0". That test passes TODAY — not because the
# tolerance property holds, but because NOTHING IN THE SCRIPT READS THE
# INSTANCE PATH AT ALL. It would pass today, pass after a correct seam ships,
# and pass after a VIOLATING seam ships. It is indistinguishable from `return 0`.
#
# This suite instead models the post-adapter world directly: the corpus is moved
# OUT of $REPO_ROOT and into an instance root. Against today's repo-homed
# resolver that genuinely FAILS — which is what makes the assertion real.
#
# ─── Fixture matrix (exit codes measured, not assumed) ───────────────────────
#
#   Fixture | in-tree corpus        | instance root         | asserts | today
#   --------|-----------------------|-----------------------|---------|-------
#      A    | ABSENT                | PRESENT, corpus inside| CH-2    |   1
#      B    | ABSENT                | ABSENT                | CH-1/4  |   1
#      C    | present, LOG omitted  | (pinned absent)       | CH-3    |   1
#      D    | present, all four     | (pinned absent)       | CH-3    |   0
#      A'   | ABSENT                | PRESENT, seeded with  | CH-2    |  n/a
#           |                       | the resolver's OWN    |(coverage|
#           |                       | declared layout       | gap)    |
#
# A-prime is CONDITIONAL. The four fixtures above are built on every run; A' is
# constructed ONLY when the coverage discriminator fires (see below), which
# requires an R5 trigger and therefore never happens on today's posture. It is
# not a fifth channel guess — its layout is read out of the resolver's own
# per-path output, so the suite never has to enumerate layouts to keep up.
#
# ─── How the suite ARMS: a structural detector, not an exit-code proxy ───────
#
# The tolerance rules are conditional — they can only grade a resolver that
# exists. What decides that a resolver exists is the ARMING question, and it is
# the one this suite got wrong first time round.
#
# The original arming antecedent was `a == 0` — fixture A passing. That is a
# BEHAVIOURAL PROXY for the structural fact "corpus-path resolution is now
# instance-aware", and the two diverge in every direction that matters. A seam
# can be fully instance-aware and still leave `a != 0`: it may read a channel
# fixture A does not seed (an `operator.toml [adapters] corpus_home` selector),
# resolve a layout fixture A does not model (Check 26's mixed
# `$(pmo_instance_path)/RELEASE_LOG.md` flat + `.../releases/notes` nested), or
# simply crash. Every one of those shipped GREEN as `PENDING-SEAM`. Conversely a
# resolver that resolves NOTHING can reach `a == 0` by exiting 0 unconditionally.
# gate-efficacy-standard.md Requirement (a) forbids exactly this: a proxy signal
# as the sole, verdict-bearing assertion.
#
# So arming is now decided by CONTENT. `detect_arming()` greps the
# comment-stripped text of the script under test for the vocabulary by which any
# instance-corpus resolution must be expressed (ARMING_NEEDLE below). Its own
# non-vacuity is asserted in-suite by three synthetic controls (P9/P10/P11): a
# planted token MUST arm, a clean file MUST NOT, and a file whose only occurrence
# is inside a comment MUST NOT — the last being today's real shape, since
# check_paths()'s header names the constraint in prose.
#
#   ARMED = detect_arming(script) non-empty  OR  a == 0
#
# The union is deliberate: the structural limb catches the seams the exit-code
# proxy missed, and the behavioural limb is retained so a resolver that reaches
# exit 0 through vocabulary the detector does not carry is still graded.
#
# ─── The teeth are a DIVERGENCE rule, not a pass rule ────────────────────────
#
#   R1  d != 0                                   -> FAIL  in-tree baseline regressed   (CH-3)
#   R2  c == 0                                   -> FAIL  probe blind to a broken path (CH-3)
#   R6  claimed CH-id set is not >=4 DISTINCT,
#       or an id is absent from the standard     -> FAIL  doc<->test binding broken
#   R5  a != 0 && (ARMED || b == 0)              -> run the COVERAGE DISCRIMINATOR
#       over fixture A's own declared per-path records:
#         records incomplete                     -> FAIL  ungradable                    (CH-2)
#         a declared path lies outside fixture
#           A's instance root                    -> FAIL  not routed through the home   (CH-2)
#         seed the declared layout into A' and re-run:
#             a' != 0                            -> FAIL  present corpus does not
#                                                         resolve                       (CH-2)
#             a' == 0                            -> PASS  fixture-coverage gap
#                                                         + non-blocking ACTION notice
#   R3  ARMED && b != 0                          -> FAIL  SEAM LANDED, TOLERANCE VIOLATED (CH-1)
#   R7  ARMED && (a == 0 || R5 passed via A')
#       && the GRADED capture lacks a per-path
#       record for any corpus label, or carries
#       the N/A token                            -> FAIL  CH-2 assumed, not resolved   (CH-2)
#       (the graded capture is fixture A's normally, and fixture A-PRIME's on the
#        coverage-gap path — R5 passing via A' is never sufficient on its own)
#   R4  ARMED && b == 0 && fixture B's capture
#       lacks a per-path N/A record for any
#       corpus label                             -> FAIL  tolerance is silent          (CH-4)
#   R8  declared posture != observed posture,
#       declared in .github/corpus-home-tolerance.arming,
#       observed from ARMED:
#         declared armed,   observed pending     -> FAIL  COVERAGE LOST: the seam was
#                                                         reverted and nothing recorded it
#         declared pending, observed armed       -> FAIL  seam landed; flip the sentinel
#                                                         in that same change
#         absent / empty / unrecognised token    -> FAIL  fail-closed: an undeclared
#                                                         posture is unassertable
#       ARMED  && posture aligned && no failure  -> PASS-SEAM-LANDED  exit 0 + retire-notice
#       !ARMED && posture aligned && no failure  -> PENDING-SEAM      exit 0 + notice
#
# R1/R2/R5/R6 gate from day one. R3/R4/R7 arm on the structural detector, so the
# PR that makes resolution instance-aware is graded on that PR — no cutoff date,
# no flag to flip, no human who must remember the standard exists.
#
# R4 and R7 are CONTENT assertions, not exit-code assertions, and they read the
# SAME per-path record shape — derived at runtime from the in-tree baseline's own
# output (P12), never hardcoded. CH-2 is therefore asserted rather than inferred
# from `a == 0` (a resolver that resolves nothing cannot reach PASS-SEAM-LANDED),
# and CH-4's needle is per-path rather than a bare `N/A` anywhere in the capture
# (all four paths downgraded to OK plus one unrelated N/A banner cannot pass).
#
# ─── A gate's FAILURE must be distinguishable from its BLIND SPOT ────────────
#
# R5's antecedent (`a != 0`) is an observation about THIS FIXTURE; its consequent
# ("a present instance corpus does not resolve") is a claim about THE RESOLVER.
# Nothing bridged the two, so a fully conformant resolver reading a layout
# fixture A does not seed rendered identically to a resolver that genuinely
# violates CH-2 — both as `FAIL R5`. The verdict was about the fixture's
# coverage, not the resolver's conformance: absence of evidence reported as
# evidence of violation.
#
# The COVERAGE DISCRIMINATOR closes that gap using the resolver's OWN output.
# check_paths() prints `<marker> <LABEL> -> <path>` per label, so fixture A's
# capture already states which paths the resolver tried. Inside R5's trigger —
# and nowhere else — three gates run in order: COMPLETENESS (a resolver emitting
# no per-path record is ungradable), CONTAINMENT (a declared path outside fixture
# A's own instance root is not routed through the active corpus home at all), and
# FALSIFICATION (seed exactly the declared paths into a fresh instance root and
# re-ask as fixture A'). Falsification is what makes this a discriminator rather
# than a relaxation: the suite constructs exactly the world the resolver asked
# for and grades it again. Conformant on re-ask -> PASS with a loud ACTION
# notice; still failing -> FAIL. The discriminator's own primitives carry
# non-vacuity controls (P13/P14/P15), on the P9/P10/P11 precedent.
#
# ─── Coverage boundary — stated, because it is real ──────────────────────────
#
# Arming is a token match over the script's text. A seam that expresses instance
# resolution in vocabulary ARMING_NEEDLE does not carry, AND whose fixture-A exit
# code is non-zero, is NOT detected — the suite reports PENDING-SEAM and the PR
# stays green. That residue is bounded by the NEEDLE, and extending the needle is
# a one-line change. The suite does not claim to arm on every conceivable
# resolver; it claims to arm on any resolver that names the platform's
# instance-corpus vocabulary anywhere in its uncommented text.
#
# The sibling residue — a resolver that IS detected but reads a LAYOUT fixture A
# does not seed — is closed, and the two must not be read as one. It is closed by
# the discriminator above, which derives the layout from the resolver's own
# output rather than by enumerating channels in build_instance_corpus(). Widening
# that channel set is still deliberately NOT the remedy for the needle residue: a
# seam can read the right channel at the right layout and still escape by
# crashing, which is why arming stays structural.
#
# TODAY the detector matches nothing outside comments, a=1 and b=1, so the verdict
# is PENDING-SEAM and the suite exits 0. It CANNOT redden a PR before the seam
# lands.
#
# ─── Arming posture: committed, not inferred ─────────────────────────────────
#
# Everything above grades a single run. This block is about the TRANSITION
# between runs, which is a different property and was unobservable by construction.
#
# The suite derives its whole verdict from live state and persists nothing, so it
# has no representation of WHICH POSTURE THE REPOSITORY ASSERTS. Both of its
# terminal states are green: PENDING-SEAM means "not applicable yet",
# PASS-SEAM-LANDED means "applicable and satisfied". A conformant seam therefore
# reaches PASS-SEAM-LANDED exit 0, and reverting that seam returns PENDING-SEAM
# exit 0 — green to green, with R3/R4/R7 quietly dormant again and nothing on any
# surface recording that CH-1/CH-2/CH-4 stopped being graded. The suite is not
# WRONG in either state; its verdict is correct both times. The defect is that
# correctness-per-run is the wrong granularity for a property meant to RATCHET,
# which is why a louder log or a better message could not have closed it.
#
# The discriminator is a committed sentinel: .github/corpus-home-tolerance.arming,
# one token, first non-comment non-blank line, from exactly {pending, armed}.
# The suite DECLARES its posture there and OBSERVES its own from ARMED, and R8
# fails on divergence in BOTH directions:
#
#   declared armed / observed pending    the seam was lost. Restore it, or flip
#                                        the token in the same change. An un-arm
#                                        is permitted; an unrecorded one is not.
#   declared pending / observed armed    the seam landed undeclared. Flip the
#                                        token in THAT change.
#
# The second direction is the forcing function, and it is load-bearing rather
# than tidy: without it the declaration would never advance past `pending`, and
# the coverage-lost branch above would be unreachable forever. Absent, empty, or
# unrecognised declarations FAIL CLOSED — if absence defaulted to `pending`,
# deleting the sentinel would silently restore the defect.
#
# The enum holds exactly the two states the suite can OBSERVE. A third token such
# as `retired` is deliberately absent: retirement deletes the PENDING branch AND
# this sentinel together, so a declared state with no observable counterpart
# would be a control whose silence reads as approval — the vacuity trap at the
# top of this file, re-introduced at the vocabulary layer.
#
# COVERAGE BOUNDARY, stated because it is real: R8 grades declared-versus-observed,
# and `observed` comes from ARMED. It therefore INHERITS the needle residue named
# in the block above and does not widen it. A seam the detector never sees leaves
# observed at `pending`, so a genuinely-landed-but-undetected seam reads as
# aligned-with-`pending` and R8 says nothing. R8 closes the TRANSITION gap, not
# the DETECTION gap; the needle still bounds what can be detected at all.
#
# ─── Hermeticity contract ────────────────────────────────────────────────────
#
# mktemp fixtures only. No network, no `gh`, no git remote, and no write outside
# the temp tree — the real checkout is never mutated. HOME and CLAUDE_WORKSPACE_ROOT
# are PINNED to an empty temp dir for every fixture so an ambient operator instance
# on the runner cannot leak into a fixture and silently defeat it.
#
# ─── Instrument validation ───────────────────────────────────────────────────
#
# CLOSEOUT_SH_UNDER_TEST overrides the script under test. Without it the
# PENDING-SEAM branch would be unfalsifiable — nobody could distinguish this
# suite from a stub. Three named negative controls: the second exists because the
# coverage discriminator must not be able to turn a red into a green, and the
# third because the arming-posture sentinel must not be silently removable.
#
#   (1) patch a throwaway copy of automated-closeout.sh with an instance-aware
#       resolver that HARD-FAILs on absence, then
#         CLOSEOUT_SH_UNDER_TEST=<copy> bash release/tools/tests/test_corpus_home_tolerance.sh
#       MUST exit 1 citing R3 / CH-1.
#
#   (2) patch a copy with an instance-aware resolver that DECLARES its own
#       per-path layout and still fails when those exact paths exist (or that
#       declares paths outside the instance root it was handed), then run it the
#       same way. It MUST exit 1 citing R5 / CH-2 — the discriminator re-asks with
#       the resolver's own declared world present and grades the second answer, so
#       a resolver that cannot resolve what it named is still caught.
#
#   (3) delete or blank the arming-posture sentinel — or point the suite at an
#       empty one — then run it:
#         CORPUS_HOME_ARMING_FILE=/dev/null bash release/tools/tests/test_corpus_home_tolerance.sh
#       It MUST exit 1 citing R8. A suite that stays green with no posture
#       declared has a sentinel that can be deleted to silence the very rule it
#       exists to make unavoidable.
#
# Usage: bash release/tools/tests/test_corpus_home_tolerance.sh [--help]

set -uo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# This file lives at release/tools/tests/, so the repo root is THREE levels up
# (tests -> tools -> release -> root). One level too few or too many silently
# anchors outside the repo and every path below resolves to nothing — the
# mis-anchor defect class. P8 below asserts the anchor rather than trusting it.
REPO_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
CLOSEOUT="${CLOSEOUT_SH_UNDER_TEST:-$REPO_ROOT/release/tools/automated-closeout.sh}"
STANDARD="$REPO_ROOT/release/references/standards/corpus-home-adapter-constraints.md"

# The CH ids this suite claims to assert. R6 binds them to the standard.
CLAIMED_IDS="CH-1 CH-2 CH-3 CH-4"

# The vocabulary by which instance-corpus resolution is expressed in this
# platform. Matched CASE-INSENSITIVELY, so `PMO_INSTANCE_PATH`, `pmo_instance_path`
# and `Pmo-Instance-Path` are one pattern rather than three.
#
# It is deliberately a CONJUNCTION shape — "instance" adjacent to
# path/root/dir/home/corpus/aware vocabulary, or "corpus" adjacent to "home" —
# not a bare `instance`. A bare token would arm on any unrelated future use of the
# word; this shape arms on instance-CORPUS-RESOLUTION and stays quiet otherwise.
# Measured against the shipped script: 5 occurrences, ALL inside comments, 0
# outside them — including `WORKSPACE_ROOT="${CLAUDE_WORKSPACE_ROOT:-}"`, which is
# a workspace root, not an instance-corpus home, and correctly does not match. So
# the detector reads NOT-ARMED today and cannot redden a PR before a seam lands.
#
# Nine resolver idioms were checked against it and all nine match: a
# `$(pmo_instance_path)` call, a `${PMO_INSTANCE_PATH:-}` read, a
# `lib-instance-path.sh` source, the inlined ADR-032
# `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance` idiom, an
# `operator.toml [adapters] corpus_home` selector in either read shape, an
# `instance_root` local, an `INSTANCE_PATH` assignment, and an `OPERATOR_INSTANCE`
# flag. Extending this list widens detection; it is the single knob that bounds
# the coverage residue named in the header.
ARMING_NEEDLE='instance[_-]?(path|root|dir|home|corpus|aware)|(corpus|operator|pmo|active)[_-]?instance|corpus[_-]?home|lib-instance-path'

# The canonical corpus labels, used ONLY as a fallback when the record vocabulary
# cannot be derived from the in-tree baseline's own output (P12).
CANONICAL_LABELS="RELEASE_LOG RELEASE_INDEX RELEASE_DIGEST RELEASE_NOTES_DIR"

# The committed arming-posture sentinel. POSTURE_FILE is where the repository
# DECLARES which posture it asserts; the suite OBSERVES its own posture from
# ARMED further down, and R8 compares the two.
#
# The env override exists so P16/P17 — and an external negative control — can
# point the reader at a synthetic file without touching the real sentinel.
# Nothing in CI sets it: the default IS the committed sentinel, which is the
# whole point of the mechanism.
POSTURE_FILE="${CORPUS_HOME_ARMING_FILE:-$REPO_ROOT/.github/corpus-home-tolerance.arming}"
POSTURE_ENUM="pending armed"

if [[ "${1:-}" == "--help" ]]; then
  # The header block runs from line 3 to the Usage line; keep this range in sync
  # if the block grows (the trailing PENDING-SEAM/boundary paragraphs are the part
  # a seam author most needs).
  #
  # RE-DERIVE the end line rather than adjusting it by eye — a wrong value here
  # truncates --help with NOTHING failing: no check, no test, no CI signal, until
  # a human reads the help text and finds it cut off mid-paragraph. Derive it with:
  #   grep -n '^# Usage: bash release/tools/tests/test_corpus_home_tolerance.sh' <this file>
  # and use that line number as the range end.
  sed -n '3,250p' "${BASH_SOURCE[0]}"
  exit 0
fi

FAILURES=0
fail() { echo "  FAIL  $*" >&2; FAILURES=$((FAILURES + 1)); }
pass() { echo "  PASS  $*"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# An empty directory used as a pinned HOME / CLAUDE_WORKSPACE_ROOT for every
# fixture, so no ambient operator instance is reachable from inside a fixture.
PINNED_HOME="$TMP/pinned-home"
mkdir -p "$PINNED_HOME"

echo "corpus-home tolerance conformance"
echo "  repo root:      $REPO_ROOT"
echo "  script under test: $CLOSEOUT"
echo

# ─── Structural arming detector ──────────────────────────────────────────────
#
# detect_arming <file> — echoes every "<lineno>:<content>" whose content names
# instance-corpus resolution vocabulary OUTSIDE a comment; echoes nothing when the
# file carries none. Comment lines are dropped by filtering the numbered output,
# which preserves the source line numbers a reader needs to diagnose a match.
#
# It reports ONLY. Arming, and every rule that depends on it, is decided by the
# caller — so P9/P10/P11 can exercise this exact code path against synthetic
# controls rather than a parallel re-implementation.
detect_arming() {
  grep -niE "$ARMING_NEEDLE" "$1" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*#' || true
}

# ─── Arming-posture reader and comparator ────────────────────────────────────
#
# Both REPORT ONLY. They echo what they observe and decide nothing; every verdict
# decision stays in the caller (R8, at the bottom of the verdict-rule block).
# That is the same contract detect_arming() carries above, and for the same
# reason: P16/P17/P18 can then exercise THESE EXACT code paths against synthetic
# controls, rather than a parallel re-implementation free to drift from the one
# that actually grades the run.

# read_posture <file> — echoes the declared posture token: the first
# non-comment, non-blank line with all whitespace stripped. Echoes nothing when
# the file is absent, or carries no such line. The caller decides what an empty
# answer means; this function does not.
#
# The first-line selection is parameter expansion rather than a pipe into
# `head -1`, for the reason declared_path() states below: under `pipefail` a
# reader that stops early makes a SUCCESSFUL match report a non-zero pipeline
# status, and the repo's sigpipe-idiom gate flags that shape. Same result, no pipe.
read_posture() {
  local _all _first
  [[ -f "$1" ]] || return 0
  _all="$(grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || true)"
  _first="${_all%%$'\n'*}"
  printf '%s\n' "${_first//[[:space:]]/}"
}

# posture_divergence <declared> <observed> — echoes exactly one status word:
#   aligned        the declaration matches what this run observes
#   un-armed       declared armed, observed pending — coverage was LOST
#   unflipped      declared pending, observed armed — the transition is undeclared
#   undeclared     no declaration at all (absent or empty sentinel)
#   unknown-token  a declaration outside POSTURE_ENUM
# The last three are the fail-closed limbs: an unreadable declaration is never
# resolved by guessing.
posture_divergence() {
  local d="$1" o="$2"
  if [[ -z "$d" ]]; then echo undeclared; return 0; fi
  case " $POSTURE_ENUM " in *" $d "*) : ;; *) echo unknown-token; return 0 ;; esac
  if [[ "$d" == "$o" ]]; then echo aligned; return 0; fi
  if [[ "$d" == "armed" && "$o" == "pending" ]]; then echo un-armed; return 0; fi
  if [[ "$d" == "pending" && "$o" == "armed" ]]; then echo unflipped; return 0; fi
  echo unknown-token
}

# The corpus-path RESOLUTION SURFACE of the script under test: the four corpus
# path assignments plus check_paths()'s own body. A detector hit inside this
# surface is definitive instance-aware resolution; a hit outside it still arms
# (the wider net is deliberate — a missed seam is a false green, a spurious arm
# is a loud, line-numbered red) but is reported separately so a spurious arm is
# diagnosable in one read.
RES_SURFACE="$TMP/res-surface.txt"
{
  grep -nE '^(RELEASE_LOG|RELEASE_INDEX|RELEASE_DIGEST|RELEASE_NOTES_DIR|REPO_ROOT)=' "$CLOSEOUT" || true
  awk '/^[[:space:]]*check_paths\(\)[[:space:]]*\{/{f=1} f{printf "%d:%s\n", NR, $0} f&&/^\}/{exit}' "$CLOSEOUT" || true
} > "$RES_SURFACE" 2>/dev/null

# ─── Per-path record shape ───────────────────────────────────────────────────
#
# record_re <label> — the ERE for one per-path corpus record:
#     <marker> <LABEL> -> <non-blank path>
# This is the shape the script itself emits ("  OK   RELEASE_LOG -> /… (file)").
# It is NOT assumed: P12 derives the live label vocabulary by applying this very
# regex to the in-tree baseline's own capture, so a script that changes its record
# format fails P12 loudly instead of making R4/R7 pass for free.
record_re() { printf '^[[:space:]]*[A-Za-z/]+[[:space:]]+%s[[:space:]]*->[[:space:]]*[^[:space:]]' "$1"; }

# ─── Coverage-discriminator primitives ───────────────────────────────────────
#
# Both REPORT ONLY. They echo (or answer) what they observe and decide nothing;
# every decision stays in the discriminator block below. That is the same
# contract detect_arming() carries, and for the same reason: P13/P14/P15 can
# then exercise these exact code paths against synthetic controls rather than a
# parallel re-implementation that could drift from the real one.

# declared_path <capture> <label> — echoes the path the script under test
# DECLARED it would use for <label>, read out of its own per-path record
# ("  FAIL RELEASE_LOG -> /some/path (expected file, not found)"). Echoes nothing
# when the capture carries no record for that label. The first record wins.
#
# The first-record selection is done by parameter expansion rather than by piping
# into `head -1`: under `pipefail` (set at the top of this file) a reader that
# stops early makes a SUCCESSFUL match report a non-zero pipeline status, which
# is why the repo's sigpipe-idiom gate flags that shape. Same result, no pipe.
declared_path() {
  local _all
  _all="$(sed -nE "s|^[[:space:]]*[A-Za-z/]+[[:space:]]+$2[[:space:]]*->[[:space:]]*([^[:space:]]+).*|\1|p" "$1" 2>/dev/null)"
  printf '%s\n' "${_all%%$'\n'*}"
}

# under_root <path> <root> — true ONLY when <path> lies strictly inside <root>
# and carries no `..` component.
#
# This is the hermeticity guard for the adaptive seed: the discriminator creates
# files ONLY at paths this accepts, rebased under $TMP, so no discriminator write
# can escape the temp tree. The "$2"/* form also rejects the prefix collision a
# bare string-prefix test admits (/planted/rootless is NOT under /planted/root).
under_root() {
  case "$1" in
    *..*)   return 1 ;;
    "$2"/*) return 0 ;;
    *)      return 1 ;;
  esac
}

# ─── Fixture construction ────────────────────────────────────────────────────

# build_repo <root> <corpus-mode>
#   corpus-mode: none    -> no release/releases/ at all (fixtures A/B)
#                partial -> notes/ + INDEX + DIGEST, RELEASE_LOG DELIBERATELY absent (C)
#                full    -> all four corpus paths present (D)
build_repo() {
  local root="$1" mode="$2"
  mkdir -p "$root/release/tools"
  cp "$CLOSEOUT" "$root/release/tools/automated-closeout.sh"
  case "$mode" in
    none) : ;;
    partial)
      mkdir -p "$root/release/releases/notes"
      : > "$root/release/releases/RELEASE_INDEX.md"
      : > "$root/release/releases/RELEASE_DIGEST.md"
      # RELEASE_LOG.md intentionally absent — this is fixture C's deliberate break.
      ;;
    full)
      mkdir -p "$root/release/releases/notes"
      : > "$root/release/releases/RELEASE_LOG.md"
      : > "$root/release/releases/RELEASE_INDEX.md"
      : > "$root/release/releases/RELEASE_DIGEST.md"
      ;;
  esac
}

# build_instance_corpus <instance-root>
#   Seeds the four corpus artifacts under BOTH candidate instance layouts:
#     <instance>/releases/...          the live platform convention
#                                      (produce-learnings-register.sh composes
#                                       $(pmo_instance_path)/releases/registers/)
#     <instance>/release/releases/...  the repo-mirroring layout
#   Seeding only one would make fixture A UNSATISFIABLE for an adapter that chose
#   the other — the gate would look armed while being structurally unable to arm.
#   Widening this set further is NOT how the coverage residue is closed: a seam can
#   read the right channel and still escape by crashing, so arming is decided
#   structurally (detect_arming) rather than by how many channels A seeds.
build_instance_corpus() {
  local inst="$1" sub
  for sub in "releases" "release/releases"; do
    mkdir -p "$inst/$sub/notes"
    : > "$inst/$sub/RELEASE_LOG.md"
    : > "$inst/$sub/RELEASE_INDEX.md"
    : > "$inst/$sub/RELEASE_DIGEST.md"
  done
}

AB_REPO="$TMP/ab"          # shared by A and B: no in-tree corpus
INSTANCE="$TMP/instance"   # fixture A's instance root (exists)
ABSENT_INSTANCE="$TMP/no-such-instance"   # fixture B's instance root (never created)
C_REPO="$TMP/c"
D_REPO="$TMP/d"

build_repo "$AB_REPO" none
build_repo "$C_REPO" partial
build_repo "$D_REPO" full
build_instance_corpus "$INSTANCE"

# ─── Fixture preconditions ───────────────────────────────────────────────────
#
# A fixture can silently fail to be in the state you believe it is, and then
# every assertion downstream passes against nothing. Each precondition asserts
# the fixture BEFORE any verdict rule consumes it.

echo "Fixture preconditions"

# P8 first: a mis-anchored REPO_ROOT makes every other check meaningless.
if [[ -f "$CLOSEOUT" ]]; then
  pass "P8 REPO_ROOT anchor resolves the script under test"
else
  fail "P8 REPO_ROOT mis-anchored: script under test not found at $CLOSEOUT"
fi

if [[ ! -e "$AB_REPO/release/releases" ]]; then
  pass "P1 fixtures A/B have NO in-tree corpus (the post-adapter world)"
else
  fail "P1 fixtures A/B unexpectedly carry an in-tree corpus — A/B would measure the wrong thing"
fi

_p2_missing=""
for _sub in "releases" "release/releases"; do
  for _f in RELEASE_LOG.md RELEASE_INDEX.md RELEASE_DIGEST.md; do
    [[ -f "$INSTANCE/$_sub/$_f" ]] || _p2_missing="$_p2_missing $_sub/$_f"
  done
  [[ -d "$INSTANCE/$_sub/notes" ]] || _p2_missing="$_p2_missing $_sub/notes"
done
if [[ -z "$_p2_missing" ]]; then
  pass "P2 fixture A instance corpus seeded in BOTH candidate layouts (8 artifacts)"
else
  fail "P2 fixture A instance corpus incomplete —$_p2_missing"
fi

if [[ ! -e "$ABSENT_INSTANCE" ]]; then
  pass "P3 fixture B instance root genuinely does not exist"
else
  fail "P3 fixture B instance root exists — B is not testing absence"
fi

if [[ ! -e "$C_REPO/release/releases/RELEASE_LOG.md" ]] \
   && [[ -f "$C_REPO/release/releases/RELEASE_INDEX.md" ]] \
   && [[ -f "$C_REPO/release/releases/RELEASE_DIGEST.md" ]] \
   && [[ -d "$C_REPO/release/releases/notes" ]]; then
  pass "P4 fixture C carries exactly 3 of 4 corpus paths (RELEASE_LOG deliberately absent)"
else
  fail "P4 fixture C is not in the 3-of-4 broken state it must be in"
fi

if [[ -f "$D_REPO/release/releases/RELEASE_LOG.md" ]] \
   && [[ -f "$D_REPO/release/releases/RELEASE_INDEX.md" ]] \
   && [[ -f "$D_REPO/release/releases/RELEASE_DIGEST.md" ]] \
   && [[ -d "$D_REPO/release/releases/notes" ]]; then
  pass "P5 fixture D carries all four corpus paths (the in-tree baseline)"
else
  fail "P5 fixture D is missing a corpus path — the baseline would fail for the wrong reason"
fi

_p6_bad=""
for _r in "$AB_REPO" "$C_REPO" "$D_REPO"; do
  cmp -s "$CLOSEOUT" "$_r/release/tools/automated-closeout.sh" || _p6_bad="$_p6_bad $_r"
done
if [[ -z "$_p6_bad" ]]; then
  pass "P6 every fixture runs a byte-identical copy of the script under test"
else
  fail "P6 fixture script copy differs from the script under test —$_p6_bad"
fi

if [[ -f "$STANDARD" ]]; then
  pass "P7 the constraint standard is present at its canonical path"
else
  fail "P7 constraint standard not found at $STANDARD"
fi

# P9/P10/P11 — the arming detector's own non-vacuity controls.
#
# The detector decides whether R3/R4/R7 grade anything at all. A typo in
# ARMING_NEEDLE would make it match nothing, arm never, and turn the whole
# tolerance limb into a universal acceptor that reports PENDING-SEAM forever —
# the exact false-confidence shape gate-efficacy-standard.md exists to forbid.
# These three synthetic files exercise detect_arming() itself, so the detector is
# asserted against a known-bad and a known-good control on every run, independent
# of whatever state the real script is in.
#
# P9 asserts a COUNT, not mere non-emptiness: the positive control carries the
# lower-case idiom AND the upper-case one, so a detector that lost its
# case-insensitivity would still match the first line and pass an
# is-it-non-empty check while going blind to `PMO_INSTANCE_PATH` — the single
# most likely spelling a seam author uses.
_det_pos="$TMP/det-positive.sh"
printf '%s\n' '#!/usr/bin/env bash' 'check_paths() {' '  local root="$(pmo_instance_path)/releases"' '  local alt="${PMO_INSTANCE_PATH:-}"' '}' > "$_det_pos"
_det_neg="$TMP/det-negative.sh"
printf '%s\n' '#!/usr/bin/env bash' 'check_paths() {' '  local root="$REPO_ROOT/release/releases"' '  WORKSPACE_ROOT="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}"' '}' > "$_det_neg"
_det_cmt="$TMP/det-comment-only.sh"
printf '%s\n' '#!/usr/bin/env bash' '# CH-1: instance-corpus root ABSENT -> record N/A and exit 0' '# see lib-instance-path.sh / PMO_INSTANCE_PATH' 'check_paths() { :; }' > "$_det_cmt"

_p9_hits="$(detect_arming "$_det_pos")"
if [[ -n "$_p9_hits" ]]; then
  _p9_n="$(printf '%s\n' "$_p9_hits" | wc -l | tr -d '[:space:]')"
else
  _p9_n=0
fi
if [[ "$_p9_n" -ge 2 ]]; then
  pass "P9 arming detector fires on both the lower- and upper-case instance-resolution idiom ($_p9_n/2 planted tokens matched)"
else
  fail "P9 arming detector is BLIND or case-sensitive — only $_p9_n of 2 planted instance-resolution idioms matched ARMING_NEEDLE. R3/R4/R7 would never arm for the spelling it misses; the tolerance limb becomes a universal acceptor."
fi

if [[ -z "$(detect_arming "$_det_neg")" ]]; then
  pass "P10 arming detector is quiet on a repo-homed resolver (no always-arm)"
else
  fail "P10 arming detector ARMS on a repo-homed resolver carrying no instance vocabulary — it would redden every PR."
fi

if [[ -z "$(detect_arming "$_det_cmt")" ]]; then
  pass "P11 arming detector ignores comment-only occurrences (today's real shape)"
else
  fail "P11 arming detector arms on a COMMENT — check_paths()'s prose header names the constraint, so this would arm the suite against a repo-homed resolver."
fi

# P13/P14/P15 — the coverage discriminator's own non-vacuity controls.
#
# The discriminator decides whether an R5 trigger is a resolver VIOLATION or a
# fixture COVERAGE GAP, and it decides it with two primitives. A blind
# declared_path() would read every armed resolver as emitting no per-path record
# and fail it — re-introducing the very false red the discriminator exists to
# remove. A permissive under_root() is worse in two directions at once: the
# adaptive seed could write outside the temp tree, and a resolver declaring
# repo-homed or escaping paths would read as a coverage gap instead of the CH-2
# violation it is. Both primitives are therefore asserted against planted
# controls on every run, exactly as P9/P10/P11 assert detect_arming().
_disc_cap="$TMP/disc-planted-capture.txt"
printf '%s\n' \
  'check-paths: resolving corpus paths under /planted/root' \
  '  FAIL RELEASE_LOG -> /planted/root/RELEASE_LOG.md (expected file, not found)' \
  '  OK   RELEASE_NOTES_DIR -> /planted/root/releases/notes (dir)' \
  > "$_disc_cap"

_p13_got="$(declared_path "$_disc_cap" RELEASE_LOG)"
if [[ "$_p13_got" == "/planted/root/RELEASE_LOG.md" ]]; then
  pass "P13 declared-path extractor reads the declared path out of a per-path record ($_p13_got)"
else
  fail "P13 declared-path extractor is BLIND — expected '/planted/root/RELEASE_LOG.md', got '${_p13_got:-<empty>}'. The coverage discriminator would read every armed resolver as record-less and fail it as ungradable, re-introducing the false red it exists to remove."
fi

_p14_got="$(declared_path "$_disc_cap" RELEASE_INDEX)"
if [[ -z "$_p14_got" ]]; then
  pass "P14 declared-path extractor returns empty for a label the capture omits (the completeness gate can fire)"
else
  fail "P14 declared-path extractor invented a path for a label absent from the capture: '$_p14_got'. The discriminator's completeness gate would never fire, so an incomplete record set would be seeded and graded as though it were whole."
fi

_p15_bad=""
under_root "/planted/root/RELEASE_LOG.md" "/planted/root" || _p15_bad="$_p15_bad accept-inside"
under_root "/elsewhere/RELEASE_LOG.md"    "/planted/root" && _p15_bad="$_p15_bad reject-outside"
under_root "/planted/root/../escape"      "/planted/root" && _p15_bad="$_p15_bad reject-dotdot-traversal"
under_root "/planted/rootless/x"          "/planted/root" && _p15_bad="$_p15_bad reject-prefix-collision"
if [[ -z "$_p15_bad" ]]; then
  pass "P15 containment guard accepts an inside path and rejects outside / .. traversal / prefix-collision"
else
  fail "P15 containment guard FAILED case(s):$_p15_bad. Two consequences and both are real: the adaptive seed could write outside the temp tree (hermeticity contract broken), and a resolver declaring repo-homed or escaping paths would read as a fixture coverage gap instead of the CH-2 violation it is."
fi

# P16/P17/P18 — the arming-posture mechanism's own non-vacuity controls.
#
# R8 is the only rule here that grades a TRANSITION rather than a run, and the
# transition it exists to catch — a landed seam being reverted — will not occur
# in real state for months. A control that cannot be exercised until the thing it
# guards against happens is not a control. So the reader and the comparator are
# asserted against planted inputs on EVERY run, exactly as P9/P10/P11 assert
# detect_arming() and P13/P14/P15 assert the discriminator primitives.
#
# P18 is the load-bearing one: it drives the comparator through the
# (armed, pending) cell — the coverage-lost cell — on a run whose own posture is
# aligned and green. A comparator that quietly lost that limb would otherwise be
# discovered only by the regression it was built to catch.
_pos_full="$TMP/posture-full.arming"
printf '%s\n' '# header comment' '#' '' 'armed' 'trailing-junk-ignored' > "$_pos_full"
_pos_empty="$TMP/posture-comment-only.arming"
printf '%s\n' '# nothing but prose' '#' '' > "$_pos_empty"
_pos_absent="$TMP/posture-no-such-file.arming"

_p16_got="$(read_posture "$_pos_full")"
if [[ "$_p16_got" == "armed" ]]; then
  pass "P16 posture reader returns the first non-comment non-blank token, ignoring header prose and trailing lines ($_p16_got)"
else
  fail "P16 posture reader is MISREADING the sentinel — expected 'armed', got '${_p16_got:-<empty>}'. Both failure directions are live: a reader returning the comment or the trailing junk yields an unknown-token FAIL on every run (R8 reddens CI permanently), and a reader returning empty yields undeclared on every run (same). Either way R8 stops grading the posture it exists to grade."
fi

_p17_bad=""
[[ -z "$(read_posture "$_pos_empty")" ]]  || _p17_bad="$_p17_bad comment-only-file"
[[ -z "$(read_posture "$_pos_absent")" ]] || _p17_bad="$_p17_bad nonexistent-path"
if [[ -z "$_p17_bad" ]]; then
  pass "P17 posture reader returns empty for a comment-only sentinel AND for a nonexistent path (the undeclared branch is reachable)"
else
  fail "P17 posture reader invented a token for:$_p17_bad. R8's fail-closed 'undeclared' branch would be UNREACHABLE, so deleting or blanking the sentinel would read as a valid posture — the exact silent-restoration hole the sentinel exists to close."
fi

_p18_bad=""
_p18_check() {
  local _want="$3" _got
  _got="$(posture_divergence "$1" "$2")"
  [[ "$_got" == "$_want" ]] || _p18_bad="$_p18_bad (declared='$1',observed='$2': want $_want got $_got)"
}
_p18_check pending pending aligned
_p18_check armed   armed   aligned
_p18_check armed   pending un-armed
_p18_check pending armed   unflipped
_p18_check ""      pending undeclared
_p18_check retired armed   unknown-token
if [[ -z "$_p18_bad" ]]; then
  pass "P18 posture comparator grades all six divergence cells correctly (including the (armed,pending) coverage-lost cell real state will not reach for months)"
else
  fail "P18 posture comparator MISGRADES:$_p18_bad. A comparator returning 'aligned' for the (armed,pending) cell is a check whose silence reads as approval — the suite would report green while the tolerance coverage it declares is gone, which is precisely the defect R8 was added to make impossible."
fi

echo

# ─── Fixture execution ───────────────────────────────────────────────────────
#
# run_fixture <label> <repo-root> <instance-path-or-empty> <capture-file>
# HOME and CLAUDE_WORKSPACE_ROOT are pinned to an empty dir so that every tier of
# pmo_instance_path()'s resolution cascade lands on absence unless this call
# explicitly provides an instance root. Without the pin, a future instance-aware
# resolver running on the operator's own machine would find the REAL instance and
# fixture B would stop testing absence — passing for the wrong reason.
run_fixture() {
  local label="$1" repo="$2" inst="$3" cap="$4" rc=0
  if [[ -n "$inst" ]]; then
    ( cd "$repo" \
      && HOME="$PINNED_HOME" CLAUDE_WORKSPACE_ROOT="$PINNED_HOME" PMO_INSTANCE_PATH="$inst" \
         bash release/tools/automated-closeout.sh --check-paths ) > "$cap" 2>&1
    rc=$?
  else
    ( cd "$repo" \
      && env -u PMO_INSTANCE_PATH HOME="$PINNED_HOME" CLAUDE_WORKSPACE_ROOT="$PINNED_HOME" \
         bash release/tools/automated-closeout.sh --check-paths ) > "$cap" 2>&1
    rc=$?
  fi
  echo "$rc"
}

CAP_A="$TMP/cap.a"; CAP_B="$TMP/cap.b"; CAP_C="$TMP/cap.c"; CAP_D="$TMP/cap.d"

a="$(run_fixture A "$AB_REPO" "$INSTANCE"        "$CAP_A")"
b="$(run_fixture B "$AB_REPO" "$ABSENT_INSTANCE" "$CAP_B")"
c="$(run_fixture C "$C_REPO"  ""                 "$CAP_C")"
d="$(run_fixture D "$D_REPO"  ""                 "$CAP_D")"

# CH-4's needle, assembled at runtime. A literal in this file would be an
# occurrence of the pattern in this file — harmless here because the grep target
# is a subprocess capture, but assembling it keeps the needle robust if this file
# is ever scanned for its own literals.
NA_NEEDLE='[N]'"/A"

B_HAS_NA=0
grep -qE "$NA_NEEDLE" "$CAP_B" && B_HAS_NA=1
A_HAS_NA=0
grep -qE "$NA_NEEDLE" "$CAP_A" && A_HAS_NA=1

# ─── Arming ──────────────────────────────────────────────────────────────────

ARM_HITS="$(detect_arming "$CLOSEOUT")"
if [[ -n "$ARM_HITS" ]]; then
  ARM_N="$(printf '%s\n' "$ARM_HITS" | wc -l | tr -d '[:space:]')"
else
  ARM_N=0
fi
ARM_SURFACE_HITS="$(detect_arming "$RES_SURFACE")"
if [[ -n "$ARM_SURFACE_HITS" ]]; then
  ARM_SURFACE_N="$(printf '%s\n' "$ARM_SURFACE_HITS" | wc -l | tr -d '[:space:]')"
else
  ARM_SURFACE_N=0
fi

ARMED=0
ARM_WHY=""
if [[ "$ARM_N" -gt 0 ]]; then
  ARMED=1
  ARM_WHY="structural — $ARM_N instance-resolution token(s) outside comments ($ARM_SURFACE_N inside the corpus-path resolution surface)"
fi
if [[ "$a" -eq 0 ]]; then
  ARMED=1
  if [[ -n "$ARM_WHY" ]]; then
    ARM_WHY="$ARM_WHY; behavioural — fixture A exits 0"
  else
    ARM_WHY="behavioural — fixture A exits 0 with no in-tree corpus (something resolved, or the resolver accepts unconditionally)"
  fi
fi

echo "Fixture results"
echo "  FIXTURE A [CH-2]     exit=$a  (instance-homed corpus, instance PRESENT; N/A token: $A_HAS_NA)"
echo "  FIXTURE B [CH-1/4]   exit=$b  (instance-homed corpus, instance ABSENT; N/A token: $B_HAS_NA)"
echo "  FIXTURE C [CH-3]     exit=$c  (repo-homed, RELEASE_LOG omitted)"
echo "  FIXTURE D [CH-3]     exit=$d  (repo-homed, all four present)"
if [[ "$ARMED" -eq 1 ]]; then
  echo "  ARMING: ARMED  ($ARM_WHY)"
  if [[ "$ARM_N" -gt 0 ]]; then
    printf '%s\n' "$ARM_HITS" | sed 's/^/    match /' | head -10
  fi
else
  echo "  ARMING: not armed  (0 instance-resolution tokens outside comments; fixture A exit $a)"
fi

# The posture this run OBSERVES is derived from ARMED and from nothing else —
# there is no second arming derivation in this file, and none outside it. The
# DECLARED posture is read from the committed sentinel. R8 compares them.
OBSERVED_POSTURE="pending"
if [[ "$ARMED" -eq 1 ]]; then
  OBSERVED_POSTURE="armed"
fi
DECLARED_POSTURE="$(read_posture "$POSTURE_FILE")"
POSTURE_STATUS="$(posture_divergence "$DECLARED_POSTURE" "$OBSERVED_POSTURE")"
echo "  POSTURE: declared=${DECLARED_POSTURE:-<none>}  observed=$OBSERVED_POSTURE  -> $POSTURE_STATUS"
echo

# ─── Derived per-path record vocabulary ──────────────────────────────────────
#
# R4 and R7 assert on per-path records, so they need the label vocabulary the
# script actually emits. Deriving it from the in-tree baseline's own capture — the
# one fixture R1 already forces to exit 0 with all four paths resolved — keeps the
# needle calibrated to the live script instead of to a hardcoded guess, and makes
# a format change fail HERE (loudly, once) rather than silently weakening R4/R7.
CORPUS_LABELS="$(sed -nE 's|^[[:space:]]*[A-Za-z/]+[[:space:]]+([A-Za-z0-9_]+)[[:space:]]*->[[:space:]]*[^[:space:]].*|\1|p' "$CAP_D" | sort -u | tr '\n' ' ')"
CORPUS_LABELS="${CORPUS_LABELS% }"
_lab_n=0
for _lab in $CORPUS_LABELS; do _lab_n=$((_lab_n + 1)); done

if [[ "$_lab_n" -ge 4 ]]; then
  pass "P12 per-path record vocabulary derived from the in-tree baseline: $CORPUS_LABELS ($_lab_n labels)"
elif [[ "$d" -eq 0 ]]; then
  fail "P12 the in-tree baseline exits 0 but emits fewer than 4 per-path records matching '<marker> <LABEL> -> <path>' (found $_lab_n: ${CORPUS_LABELS:-none}). R4/R7 would assert against a vocabulary the script no longer emits — update record_re() to the script's current record shape."
  CORPUS_LABELS="$CANONICAL_LABELS"
else
  echo "  NOTE  P12 record vocabulary not derivable (fixture D exit $d — see R1); falling back to the canonical labels: $CANONICAL_LABELS"
  CORPUS_LABELS="$CANONICAL_LABELS"
fi

echo

# ─── Coverage discriminator ──────────────────────────────────────────────────
#
# R5's antecedent (`a != 0`) is a FIXTURE-RELATIVE observation; its consequent
# ("a present instance corpus does not resolve") is a RESOLVER-RELATIVE claim.
# This block is what bridges them, and it runs ONLY inside R5's existing trigger
# condition — the guard below is byte-identical to R5's. Everywhere else the
# suite behaves exactly as before.
#
# Three gates, in order:
#
#   1. COMPLETENESS  — a resolver emitting no per-path record for some corpus
#                      label declared no path to falsify.        -> indeterminate
#   2. CONTAINMENT   — a declared path OUTSIDE fixture A's own instance root is
#                      not routed through the active corpus home at all. That is
#                      a genuine CH-2 violation, not a coverage gap. -> violation
#   3. FALSIFICATION — seed EXACTLY the paths the resolver declared into a fresh
#                      instance root and re-run fixture A as A'. Conformant on
#                      re-ask -> coverage-gap; still failing -> violation.
#
# Gate 3 is why this is a discriminator and not a relaxation: the suite builds
# exactly the world the resolver asked for and grades it again. A mechanism that
# only REPORTS the ambiguity leaves the false red in place; one that trusts the
# declaration WITHOUT re-asking is a false green waiting to happen.
#
# The status vocabulary is deliberately lower-case and hyphenated — outside both
# the PASS/FAIL per-check register and the PENDING-SEAM/PASS-SEAM-LANDED terminal
# register — so a discriminator status can never be misread as a suite verdict.
# The suite still ends in exactly the two documented terminal states.
APRIME="$TMP/instance-adaptive"
CAP_AP="$TMP/cap.a-prime"
aprime=""
A_PRIME_STATUS="n/a"
A_PRIME_WHY=""
A_PRIME_LAYOUT=""

if [[ "$a" -ne 0 ]] && { [[ "$ARMED" -eq 1 ]] || [[ "$b" -eq 0 ]]; }; then
  if [[ "$d" -ne 0 ]]; then
    # The in-tree baseline is broken, so P12 fell back to the canonical labels and
    # the record-KIND derivation below has no filesystem truth to read. R1 already
    # fails the suite for this; a discriminator verdict computed on a degenerate
    # baseline would only add a confidently wrong reason to a run that is already
    # red for the right one.
    A_PRIME_STATUS="indeterminate"
    A_PRIME_WHY="the in-tree baseline itself fails (fixture D exit $d — see R1), so neither the per-path record vocabulary nor the record kinds can be derived; the coverage question cannot be decided until R1 is green"
  else
    _disc_missing=""
    _disc_outside=""
    _disc_seeds=""
    for _lab in $CORPUS_LABELS; do
      _dp="$(declared_path "$CAP_A" "$_lab")"
      if [[ -z "$_dp" ]]; then
        _disc_missing="$_disc_missing $_lab"
      elif ! under_root "$_dp" "$INSTANCE"; then
        _disc_outside="$_disc_outside $_lab=$_dp"
      else
        _disc_seeds="$_disc_seeds $_lab|$_dp"
        A_PRIME_LAYOUT="$A_PRIME_LAYOUT ${_dp#$INSTANCE/}"
      fi
    done
    A_PRIME_LAYOUT="${A_PRIME_LAYOUT# }"

    if [[ -n "$_disc_missing" ]]; then
      A_PRIME_STATUS="indeterminate"
      A_PRIME_WHY="fixture A emits no per-path record for:$_disc_missing — the resolver declared no path there, so there is nothing to falsify and its conformance cannot be decided from its own output"
    elif [[ -n "$_disc_outside" ]]; then
      A_PRIME_STATUS="violation"
      A_PRIME_WHY="the resolver declared path(s) OUTSIDE fixture A's instance corpus home ($INSTANCE):$_disc_outside — a present instance corpus is not being routed through the active corpus home (CH-2)"
    else
      mkdir -p "$APRIME"
      for _seed in $_disc_seeds; do
        _s_lab="${_seed%%|*}"
        _s_path="${_seed#*|}"
        _s_rel="${_s_path#$INSTANCE/}"
        # Derive the record KIND (file vs dir) from fixture D's declared path on
        # the live filesystem — never from a hardcoded label->kind map, and never
        # parsed out of the record's trailing prose. A hardcoded map would
        # re-introduce exactly the vocabulary-drift class P12 exists to catch.
        _d_declared="$(declared_path "$CAP_D" "$_s_lab")"
        if [[ -n "$_d_declared" ]] && [[ -d "$_d_declared" ]]; then
          mkdir -p "$APRIME/$_s_rel"
        else
          mkdir -p "$(dirname "$APRIME/$_s_rel")"
          : > "$APRIME/$_s_rel"
        fi
      done
      aprime="$(run_fixture Aprime "$AB_REPO" "$APRIME" "$CAP_AP")"
      if [[ "$aprime" -eq 0 ]]; then
        A_PRIME_STATUS="coverage-gap"
        A_PRIME_WHY="fixture A does not seed the layout this resolver reads; seeding the resolver's OWN declared layout ($A_PRIME_LAYOUT) into a fresh instance root and re-running exits 0 — the resolver conforms, the fixture never exercised it"
      else
        A_PRIME_STATUS="violation"
        A_PRIME_WHY="the suite seeded the resolver's OWN declared layout ($A_PRIME_LAYOUT) into a fresh instance root and the resolver STILL exits $aprime — a corpus present at the paths it named does not resolve (CH-2)"
      fi
    fi
  fi
  echo "  DISCRIMINATOR: $A_PRIME_STATUS — $A_PRIME_WHY"
  echo
fi

# ─── Verdict rules ───────────────────────────────────────────────────────────

echo "Verdict rules"

# R1 — the in-tree baseline. Gates today.
if [[ "$d" -eq 0 ]]; then
  pass "R1 in-tree baseline resolves (fixture D exit 0)"
else
  fail "R1 in-tree baseline REGRESSED — fixture D exit $d; --check-paths no longer resolves a complete in-tree corpus"
fi

# R2 — probe liveness. Gates today.
if [[ "$c" -ne 0 ]]; then
  pass "R2 probe is live (fixture C: a broken corpus path still fails)"
else
  fail "R2 probe is BLIND — fixture C exit 0 with RELEASE_LOG.md absent; --check-paths no longer detects a broken corpus path"
fi

# R6 — doc<->test binding. Gates today.
if [[ ! -f "$STANDARD" ]]; then
  fail "R6 doc<->test binding BROKEN — the constraint standard is absent: $STANDARD"
else
  # Non-vacuity floor FIRST, and it counts DISTINCT ids. R6 is a loop over
  # CLAIMED_IDS; an empty, truncated, OR DUPLICATED list makes the loop assert
  # less than it claims — "CH-1 CH-1 CH-1 CH-1" has cardinality 4 and asserts one
  # id, leaving CH-2/3/4 unbound. Assert the population's distinctness before
  # trusting the result.
  _r6_total=0
  for _id in $CLAIMED_IDS; do _r6_total=$((_r6_total + 1)); done
  _r6_count="$(printf '%s\n' $CLAIMED_IDS | sort -u | grep -c . || true)"
  _r6_count="${_r6_count:-0}"
  if [[ "$_r6_count" -lt 4 ]]; then
    fail "R6 claimed-id list is DEGENERATE — $_r6_count DISTINCT id(s) among $_r6_total entr(ies) ($CLAIMED_IDS), expected at least 4 distinct (CH-1..CH-4). R6 would grade a PASS having asserted fewer constraints than it claims."
  else
    _r6_missing=""
    for _id in $CLAIMED_IDS; do
      grep -q "\*\*${_id}\*\*" "$STANDARD" || _r6_missing="$_r6_missing $_id"
    done
    if [[ -z "$_r6_missing" ]]; then
      pass "R6 all $_r6_count distinct claimed constraint ids ($CLAIMED_IDS) are present in the standard"
    else
      fail "R6 doc<->test binding BROKEN — constraint id(s) missing from the standard:$_r6_missing"
    fi
  fi
fi

# R5 — CH-2's exit-code limb. Fires unconditionally on the pre-seam degenerate
# shape (b == 0 with a != 0: absence tolerated while presence resolves nothing),
# and additionally whenever the suite is ARMED — because an armed resolver that
# leaves fixture A failing has not demonstrated CH-2 at all.
if [[ "$a" -ne 0 ]] && { [[ "$ARMED" -eq 1 ]] || [[ "$b" -eq 0 ]]; } \
   && [[ "$A_PRIME_STATUS" == "coverage-gap" ]]; then
  pass "R5 CH-2 exit limb (via fixture A-prime) — $A_PRIME_WHY
        ACTION (non-blocking): add this layout to build_instance_corpus() in this file so CH-2 is asserted DIRECTLY on fixture A rather than adaptively on A-prime — seed: $A_PRIME_LAYOUT"
elif [[ "$a" -ne 0 ]] && { [[ "$ARMED" -eq 1 ]] || [[ "$b" -eq 0 ]]; }; then
  fail "R5 CH-2 NOT DEMONSTRATED [$A_PRIME_STATUS] — a PRESENT instance corpus does not resolve (fixture A exit $a) while the suite is armed ($ARM_WHY). Two causes, and they need different fixes: (i) the resolver tolerates absence without resolving presence — the degenerate answer CH-2 forbids; or (ii) the resolver reads a corpus-home channel or layout fixture A does not seed (it seeds PMO_INSTANCE_PATH at <inst>/releases/ and <inst>/release/releases/). The coverage discriminator decided WHICH, and this is what it observed: $A_PRIME_WHY. A 'violation' status means the resolver was re-asked with its own declared layout present and STILL failed — fix the resolver, do NOT relax the rule. An 'indeterminate' status means the resolver's output could not be graded at all — make check_paths() emit a per-path record for every corpus label (or fix R1's baseline), then re-run."
elif [[ "$ARMED" -eq 1 ]]; then
  pass "R5 CH-2 exit limb — a present instance corpus resolves (fixture A exit 0)"
else
  pass "R5 live but not triggered — no resolver tolerates absence without resolving presence (fixture A exit $a, fixture B exit $b)"
fi

# R3 — CH-1. Armed by the STRUCTURAL detector, not by fixture A's exit code, so a
# resolver that is instance-aware but invisible to fixture A is still graded.
if [[ "$ARMED" -eq 1 ]] && [[ "$b" -ne 0 ]]; then
  fail "R3 SEAM LANDED, TOLERANCE VIOLATED (CH-1) — corpus-path resolution is instance-aware ($ARM_WHY) but --check-paths exits $b when the instance-corpus root is absent. Per release/references/standards/corpus-home-adapter-constraints.md CH-1, instance-absence MUST record N/A and exit 0. As written, --check-paths reddens the required closeout-smoke gate on every PR from a fresh clone or CI runner. A non-1 exit (a crash) is the same violation: absence must be TOLERATED, not merely not-hard-failed."
elif [[ "$ARMED" -eq 1 ]]; then
  pass "R3 CH-1 tolerance holds — an absent instance-corpus root exits 0"
fi

# R7 — CH-2's CONTENT limb (the assertion whose absence let a resolver that
# resolves NOTHING reach PASS-SEAM-LANDED). The graded capture is READ here: an
# exit code alone cannot distinguish "resolved four paths through the instance
# corpus" from "printed one N/A and returned 0".
#
# On the coverage-gap path R7 grades fixture A-PRIME's capture rather than
# fixture A's, and THAT is what stops the discriminator converting a false red
# into a false green. R5 passing via A' is never sufficient on its own: the
# resolver must ALSO have emitted a real per-path record for every corpus label,
# with no N/A token, in the very run that produced its exit 0.
R7_CAP="$CAP_A"
R7_NA="$A_HAS_NA"
R7_SRC="fixture A"
if [[ "$A_PRIME_STATUS" == "coverage-gap" ]]; then
  R7_CAP="$CAP_AP"
  R7_SRC="fixture A-prime"
  R7_NA=0
  grep -qE "$NA_NEEDLE" "$CAP_AP" && R7_NA=1
fi
if [[ "$ARMED" -eq 1 ]] && { [[ "$a" -eq 0 ]] || [[ "$A_PRIME_STATUS" == "coverage-gap" ]]; }; then
  _r7_missing=""
  _r7_hits="$TMP/r7-hits.txt"
  for _lab in $CORPUS_LABELS; do
    grep -E "$(record_re "$_lab")" "$R7_CAP" > "$_r7_hits" 2>/dev/null || : > "$_r7_hits"
    [[ -s "$_r7_hits" ]] || _r7_missing="$_r7_missing $_lab"
  done
  if [[ -n "$_r7_missing" ]]; then
    fail "R7 CH-2 ASSUMED, NOT RESOLVED — $R7_SRC exits 0 but its output carries no per-path resolution record for:$_r7_missing. A present instance corpus MUST resolve all four corpus paths through the active corpus home (CH-2); an unconditional exit 0 satisfies the letter of CH-1 while resolving nothing at all, which is exactly the degenerate answer the standard's §3 says CH-2 exists to forbid."
  elif [[ "$R7_NA" -eq 1 ]]; then
    fail "R7 CH-2 VIOLATED — $R7_SRC exits 0 but its output carries the N/A token. That fixture's instance corpus is PRESENT and complete, so nothing in it is legitimately N/A; a resolver reporting N/A here is tolerating absence it should be resolving."
  else
    pass "R7 CH-2 content limb — $R7_SRC resolves a per-path record for every corpus label ($CORPUS_LABELS) and reports no N/A"
  fi
fi

# R4 — CH-4. The needle is PER-PATH, matched against the same record shape R7
# uses. A bare N/A anywhere in the capture is not evidence of a distinguishable
# per-path record: all four paths downgraded to OK plus one unrelated N/A banner
# would satisfy it, which is precisely the hole CH-4 closes.
if [[ "$ARMED" -eq 1 ]] && [[ "$b" -eq 0 ]]; then
  _r4_missing=""
  _r4_hits="$TMP/r4-hits.txt"
  for _lab in $CORPUS_LABELS; do
    grep -E "$(record_re "$_lab")" "$CAP_B" > "$_r4_hits" 2>/dev/null || : > "$_r4_hits"
    if [[ -s "$_r4_hits" ]] && grep -qE "$NA_NEEDLE" "$_r4_hits"; then
      :
    else
      _r4_missing="$_r4_missing $_lab"
    fi
  done
  if [[ -n "$_r4_missing" ]]; then
    fail "R4 TOLERANCE IS SILENT (CH-4) — fixture B exits 0 with an absent instance-corpus root but emits no distinguishable per-path N/A record for:$_r4_missing (whole-capture N/A token present: $B_HAS_NA). CH-4 requires a per-path record, never an undifferentiated OK: an unresolved path that reads as OK defeats CH-3, because a genuine resolution defect becomes indistinguishable from a tolerated absence."
  else
    pass "R4 tolerance is explicit (CH-4) — fixture B emits a per-path N/A record for every corpus label ($CORPUS_LABELS)"
  fi
fi

if [[ "$ARMED" -eq 0 ]]; then
  pass "R3/R4/R7 dormant — no instance-aware resolution detected (0 tokens outside comments, fixture A exit $a)"
fi

# R8 — the arming-posture binding. Every rule above grades THIS RUN; R8 is the
# only one that grades a TRANSITION.
#
# The suite derives its entire verdict from live state and persists nothing, so
# it has no representation of which posture the repository asserts. Its two
# terminal states are both green — PENDING-SEAM ("not applicable yet") and
# PASS-SEAM-LANDED ("applicable and satisfied") — which makes a regression from
# the second back to the first indistinguishable from never having reached it.
# Correctness-per-run is the wrong granularity for a property that is supposed to
# ratchet. The committed sentinel is the discriminator that was missing, and R8
# is what reads it.
case "$POSTURE_STATUS" in
  aligned)
    pass "R8 arming posture binding — the committed sentinel declares '$DECLARED_POSTURE' and this run observes '$OBSERVED_POSTURE'"
    ;;
  un-armed)
    fail "R8 COVERAGE LOST — $POSTURE_FILE declares 'armed', but this run observes 'pending': no instance-aware corpus-path resolution is detected in the script under test. The seam this repository declared has been reverted or lost, and R3/R4/R7 have gone dormant with it — CH-1/CH-2/CH-4 are no longer being graded by anything. Before this rule existed that regression produced a second green and no signal at all. Two lawful remedies, and only two: restore the seam, OR flip the token in $POSTURE_FILE back to 'pending' in the SAME change that removes it. An un-arm is permitted; an UNRECORDED un-arm is not."
    ;;
  unflipped)
    fail "R8 SEAM LANDED, POSTURE UNDECLARED — this run observes instance-aware corpus-path resolution ($ARM_WHY), but $POSTURE_FILE still declares 'pending'. Flip its token to 'armed' in THIS change. This is a one-line edit, not a re-design, and it is what makes the reverse failure reachable: while the declaration stays 'pending', a later revert returns the suite to PENDING-SEAM exit 0 with nothing anywhere recording that the tolerance coverage was lost."
    ;;
  undeclared)
    fail "R8 ARMING POSTURE SENTINEL MISSING OR EMPTY — $POSTURE_FILE carries no posture token. Expected exactly one of: $POSTURE_ENUM, as the first non-comment non-blank line. This fails CLOSED deliberately: if an absent declaration defaulted to 'pending', deleting the sentinel would silently restore the very defect it exists to close — R8 could then never fire, and its silence would read as approval."
    ;;
  *)
    fail "R8 ARMING POSTURE UNRECOGNISED TOKEN '$DECLARED_POSTURE' in $POSTURE_FILE — expected exactly one of: $POSTURE_ENUM. This fails closed rather than guessing. The enum holds only postures this suite can OBSERVE, so it has exactly two members; a declared state with no observable counterpart would be a control whose silence reads as approval, re-introduced at the vocabulary layer."
    ;;
esac

echo

# ─── Terminal verdict ────────────────────────────────────────────────────────

if [[ "$FAILURES" -gt 0 ]]; then
  echo "verdict: FAIL — $FAILURES failing check(s)" >&2
  echo "  See release/references/standards/corpus-home-adapter-constraints.md (CH-1..CH-4)." >&2
  exit 1
fi

if [[ "$ARMED" -eq 0 ]]; then
  echo "verdict: PENDING-SEAM"
  echo "  No instance-aware corpus-path resolution is detected in the script under"
  echo "  test, so the CH-1/CH-2/CH-4 tolerance rules (R3/R4/R7) are dormant."
  echo "  R1/R2/R5/R6 gated and passed. This suite cannot redden a PR until the"
  echo "  corpus-home seam lands — and it grades the PR that lands it, armed by a"
  echo "  structural read of the resolver rather than by a fixture exit code."
  echo "  This posture is DECLARED, not merely observed: .github/corpus-home-tolerance.arming"
  echo "  carries the token 'pending', and the change that lands the seam must flip it to"
  echo "  'armed' in that same change or R8 fails it."
  exit 0
fi

echo "verdict: PASS-SEAM-LANDED"
echo "  The corpus-home seam has landed CONFORMANTLY: a present instance corpus"
echo "  resolves with a per-path record for every corpus label (CH-2), an absent"
echo "  one is tolerated with a per-path N/A record (CH-1, CH-4), and the in-tree"
echo "  baseline still detects a genuine resolution defect (CH-3)."
if [[ "$A_PRIME_STATUS" == "coverage-gap" ]]; then
  echo "  COVERAGE NOTE — CH-2 was demonstrated against fixture A-PRIME, not fixture A."
  echo "  This resolver reads a layout fixture A does not seed, so the suite seeded the"
  echo "  resolver's own declared layout and re-asked: $A_PRIME_LAYOUT"
  echo "  ACTION — add that layout to build_instance_corpus() in this file, so CH-2 is"
  echo "  asserted DIRECTLY on fixture A rather than adaptively on A-prime. Adaptive is"
  echo "  the safety net; direct seeding stays the goal."
fi
echo "  ACTION — retire the PENDING-SEAM branch of this suite. Replace it with a"
echo "  hard 'not ARMED -> FAIL' so the tolerance property gates unconditionally"
echo "  and cannot silently regress to the pre-seam state."
echo "  (See corpus-home-adapter-constraints.md §5 'Retirement condition'.)"
exit 0
