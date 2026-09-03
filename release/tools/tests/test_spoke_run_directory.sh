#!/usr/bin/env bash
set -uo pipefail
# test_spoke_run_directory.sh — NC-NS-1, the negative control for spoke
# output-path namespacing (hub-spoke-bridge.md § Run-Directory Discipline).
#
# WHY THIS EXISTS
#   A spawned Stage-6 Engineering spoke once picked up a PRIOR spoke's leftover
#   stage-comment file from a shared temp parent and nearly posted it to the
#   wrong sub-task. The failure was a READ, not a write: the spoke read a path
#   it had never written. The prompt contract mandated a local temp file and
#   said nothing about where it goes, so the collision surface was a MANDATED
#   write with an unspecified target.
#
# WHAT THIS SUITE GRADES — and what it deliberately does NOT
#   An earlier draft of this control asserted that N parallel `mktemp -d` calls
#   return N distinct directories. That grades a POSIX guarantee, not this
#   design: it would still pass with the entire contract clause deleted from
#   the corpus. Every arm here is chosen so that removing the clause FAILS it.
#
#   Group A grades the CLAUSE and proves its own deletion-sensitivity by
#   re-running each assertion against a mutated copy of the doc with the
#   section excised — the mutated copy MUST fail every arm that the live copy
#   passes. That inversion is the instrument-validation arm; without it, Group A
#   would only be asserting that a file is non-empty.
#
#   Group B grades the BEHAVIOUR the clause prescribes, in both the serial
#   (re-run) and the concurrent case, and carries the arm the original design
#   was missing: a deliberately NON-CONFORMING reader that globs the shared
#   parent DOES find the prior run's leftover. That arm is what makes the
#   conforming arm's zero a real negative — it proves the leftover is reachable
#   when the read clause is violated, so conformance is what prevents the
#   collision, not the absence of a file to collide with.
#
# GROUPS
#   (A1-A6) SPOKE CLAUSE ARMS — the run-directory section exists in the Spoke
#           Template, binds the WRITE side, binds the READ side, requires the
#           resolved path be echoed, the read-only GitHub-write bound no longer
#           reads as covering the filesystem, and the temp-file mandate names
#           the run directory.
#   (A7-A9) HUB CLAUSE ARMS — the hub-side counterpart subsection exists, binds
#           the hub's write side to ONE staging location, and states an end
#           anchor tied to a named release event. The posting mandate is
#           universal; before these arms only the spoke's target was bounded.
#   (A-NEG) DELETION SENSITIVITY — the same nine assertions against a copy with
#           BOTH sections removed must ALL fail. An arm that still passes there
#           is not grading the clause.
#   (C1-C4) PACKAGED-SURFACE ARMS — the staging path literal and the Step-6 end
#           anchor are DUPLICATED from the bridge into release-hub/SKILL.md, the
#           packaged and deployed surface. A1-A9 grade only the bridge, so the
#           copy that actually ships was ungraded and free to drift. These arms
#           grade it: the Mode O section exists, carries A8's path literal byte
#           for byte, states the same named end anchor, and cites the canonical
#           clause instead of standing as a second authority.
#           They live in their OWN function, NOT in clause_arms(): that function
#           is parameterised over one document and A-NEG mutates the BRIDGE, so
#           an arm there reading a different file would pass on the A-NEG copy,
#           count as a survivor, and disable the deletion-sensitivity control.
#   (C-NEG) PACKAGED DELETION SENSITIVITY — C2-C4 against a copy of the SKILL.md
#           with the staging paragraph excised must ALL fail, with a retention
#           control proving the cut was targeted. C1 is excluded from the
#           survivor count for the same reason A4b is excluded from A-NEG.
#   (B1-B5) BEHAVIOURAL ARMS — serial re-run isolation, the non-conforming
#           reader (sensitivity), concurrent distinctness with disjoint
#           contents, conforming-read specificity on a known-absent target, and
#           a read-mechanism sensitivity arm proving the zeros are real.
#
# Offline + deterministic: all fixtures under one mktemp dir. No network, no
# gh, no writes to any operator-instance path, no writes into the repo.
#
# Run:  bash release/tools/tests/test_spoke_run_directory.sh
# Exit: 0 = all assertions pass, 1 = one or more failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd -P)"
BRIDGE="$REPO_ROOT/release/references/how-to/hub-spoke-bridge.md"
HUB_SKILL="$REPO_ROOT/release/skills/release-hub/SKILL.md"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0; FAILURES=()
ok()  { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }

echo "NC-NS-1 — spoke run-directory discipline"
echo

if [ ! -f "$BRIDGE" ]; then
  echo "  FAIL — cannot locate hub-spoke-bridge.md at $BRIDGE"
  exit 1
fi

if [ ! -f "$HUB_SKILL" ]; then
  echo "  FAIL — cannot locate release-hub SKILL.md at $HUB_SKILL"
  exit 1
fi

# ---------------------------------------------------------------------------
# Extract the run-directory section from a given copy of the bridge doc.
# Prints the section body; prints nothing when the section is absent.
# ---------------------------------------------------------------------------
extract_section() {
  awk '
    /^## Run-Directory Discipline \(all spokes\)$/ { inside = 1; next }
    inside && /^## / { inside = 0 }
    inside { print }
  ' "$1"
}

# ---------------------------------------------------------------------------
# Extract the HUB-side staging section. The spoke section above is inside the
# Spoke Template fence; this one is hub-facing prose in `## For the Hub Agent`,
# so it needs its own extractor rather than a widened one — widening would
# rename the heading the extractor above matches as an exact string, which is
# the change that empties it.
#
# Terminates on the next heading of level 2 OR 3, whichever comes first. That
# is deliberately stricter than mirroring the extractor above: the end-anchor
# literal A9 greps for occurs several times ELSEWHERE in this document, so an
# extractor that over-ran its subsection would let A9 pass on text outside the
# clause — and would then survive the A-NEG excision, registering as a survivor.
# Bounding the extraction is what keeps A9 a statement about the clause.
# ---------------------------------------------------------------------------
extract_hub_section() {
  awk '
    /^### Hub Staging Discipline$/ { inside = 1; next }
    inside && (/^## / || /^### /) { inside = 0 }
    inside { print }
  ' "$1"
}

# Nine clause assertions, evaluated against an arbitrary copy of the doc.
# Emits one line per arm: "<arm-id> PASS" or "<arm-id> FAIL".
clause_arms() {
  local doc="$1" section hub_section
  section="$(extract_section "$doc")"
  hub_section="$(extract_hub_section "$doc")"

  # A1 — the section exists at all, inside the Spoke Template.
  if [ -n "$section" ]; then echo "A1 PASS"; else echo "A1 FAIL"; fi

  # A2 — it binds the WRITE side to the run directory.
  #      Here-string for the same pipefail reason as A8.
  if grep -qF -- 'inside `$SPOKE_OUT` and nowhere else' <<<"$section"
  then echo "A2 PASS"; else echo "A2 FAIL"; fi

  # A3 — it binds the READ side. #3211 was a READ; a write-only clause lets
  #      the AC pass with the observed defect fully reachable.
  #      Here-string for the same pipefail reason as A8.
  if grep -qF -- 'Read** scratch input only from `$SPOKE_OUT`' <<<"$section"
  then echo "A3 PASS"; else echo "A3 FAIL"; fi

  # A4 — it requires the run directory be echoed into the durable artifact,
  #      which is the only compensating control the unenforceable read side has.
  #      Relative form only: the output comment is a public surface, and the
  #      resolved absolute path embeds the operator's OS username on a default
  #      install.
  #      Here-string for the same pipefail reason as A8.
  if grep -qF -- 'Echo the run directory in `${SCRATCH_BASE}`-relative form' <<<"$section"
  then echo "A4 PASS"; else echo "A4 FAIL"; fi

  # A4b — negative arm: the mandate must NOT ask for the resolved absolute path.
  #       Without this, re-adding the absolute form later passes a green build.
  #       Here-string for the same pipefail reason as A8.
  if grep -qF -- 'Echo the resolved `$SPOKE_OUT`' <<<"$section"
  then echo "A4b FAIL"; else echo "A4b PASS"; fi

  # A5 — the read-only spoke's GitHub-write bound is scoped to GitHub, so it no
  #      longer reads as a claim about the filesystem surface as well.
  if grep -qF 'On the GitHub surface** you may WRITE in exactly one place' "$doc"
  then echo "A5 PASS"; else echo "A5 FAIL"; fi

  # A6 — the temp-file posting mandate, which is what CREATES the local write,
  #      names the path discipline that bounds it.
  if grep -qF 'That temp file goes in the spoke'\''s run directory' "$doc"
  then echo "A6 PASS"; else echo "A6 FAIL"; fi

  # A7 — the HUB-side counterpart clause exists at all. Its absence is what
  #      produced this rule: the posting mandate is universal while only the
  #      spoke's target was bounded, so hub-staged bodies had no governed home.
  if [ -n "$hub_section" ]; then echo "A7 PASS"; else echo "A7 FAIL"; fi

  # A8 — it binds the hub's WRITE side to ONE location. Fixed-string match:
  #      the path carries `<`, `>` and `/`, which are regex-live under -E and
  #      would silently mis-match.
  #      Here-string, not `printf | grep -q`: this file runs under `pipefail`,
  #      where a short-circuiting reader breaks the writer's pipe and the
  #      writer's non-zero status becomes the pipeline's — so a MATCH can
  #      report failure. A here-string has no writer to signal. The needle is
  #      a non-empty fixed string, so the `<<<""` empty-line case cannot match
  #      it and an absent section still reads FAIL, as A-NEG requires.
  if grep -qF -- '<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/staging/' <<<"$hub_section"
  then echo "A8 PASS"; else echo "A8 FAIL"; fi

  # A9 — it states an end anchor tied to a NAMED release event, not a duration.
  #      Scoped to $hub_section, never the whole doc: this literal occurs
  #      several times elsewhere in the bridge, so a whole-doc grep would pass
  #      with the clause deleted and then survive the A-NEG excision.
  #      Here-string for the same pipefail reason as A8.
  if grep -qF -- 'Procedure 7 Step 6' <<<"$hub_section"
  then echo "A9 PASS"; else echo "A9 FAIL"; fi
}

# ---------------------------------------------------------------------------
echo "(A) Clause arms — the live corpus"
# ---------------------------------------------------------------------------
LIVE_RESULTS="$(clause_arms "$BRIDGE")"
# A4b is harvested HERE but deliberately NOT in the A-NEG loop below: it is a
# negative arm (it passes when the absolute-path form is ABSENT), so it passes
# legitimately against an excised section and would corrupt the deletion-
# sensitivity count if included there.
for arm in A1 A2 A3 A4 A4b A5 A6 A7 A8 A9; do
  # Here-string for the same pipefail reason as A8.
  if grep -qx -- "$arm PASS" <<<"$LIVE_RESULTS"; then
    ok "$arm — clause assertion holds in hub-spoke-bridge.md"
  else
    bad "$arm — clause assertion does NOT hold in hub-spoke-bridge.md"
  fi
done
echo

# ---------------------------------------------------------------------------
echo "(A-NEG) Deletion sensitivity — the same arms against an excised copy"
# ---------------------------------------------------------------------------
# Build a mutated copy with the run-directory section, the hub-side staging
# subsection, and the two pointer edits that depend on them removed. Every arm
# above must FAIL here. An arm that survives the deletion is grading something
# other than the contract clause.
#
# The two excisions are independent flags because the sections nest at
# different heading levels in different regions of the document: the spoke
# section is level-2 payload inside the Spoke Template fence, the hub
# subsection is level-3 prose in `## For the Hub Agent`. A level-2 terminator
# does not close a level-3 section and vice versa, so one flag cannot serve
# both without silently under- or over-excising.
MUTATED="$WORK/bridge-clause-deleted.md"
awk '
  /^## Run-Directory Discipline \(all spokes\)$/ { skipping = 1; next }
  skipping && /^## / { skipping = 0 }
  /^### Hub Staging Discipline$/ { hub_skipping = 1; next }
  hub_skipping && (/^## / || /^### /) { hub_skipping = 0 }
  skipping || hub_skipping { next }
  { print }
' "$BRIDGE" \
  | sed -e 's/\*\*On the GitHub surface\*\* you may WRITE in exactly one place/You may WRITE in exactly one place/' \
        -e 's/\*\*That temp file goes in the spoke'\''s run directory\*\*.*$//' \
  > "$MUTATED"

if [ ! -s "$MUTATED" ]; then
  bad "A-NEG — mutated fixture is empty; the excision step is broken"
else
  MUT_RESULTS="$(clause_arms "$MUTATED")"
  SURVIVORS=0
  for arm in A1 A2 A3 A4 A5 A6 A7 A8 A9; do
    # Here-string for the same pipefail reason as A8.
    if grep -qx -- "$arm PASS" <<<"$MUT_RESULTS"; then
      SURVIVORS=$((SURVIVORS+1))
      printf '         survivor: %s still passes with the clause deleted\n' "$arm"
    fi
  done
  if [ "$SURVIVORS" -eq 0 ]; then
    ok "A-NEG — all 9 clause arms fail when the sections are excised (deletion-sensitive)"
  else
    bad "A-NEG — $SURVIVORS of 9 clause arms survive deletion; they do not grade the clause"
  fi
  # Instrument validation for the excision itself: the mutated copy must still
  # be a substantial document, or "everything failed" would be trivially true.
  MUT_LINES="$(wc -l < "$MUTATED" | tr -d ' ')"
  LIVE_LINES="$(wc -l < "$BRIDGE" | tr -d ' ')"
  if [ "$MUT_LINES" -gt $(( LIVE_LINES * 9 / 10 )) ]; then
    ok "A-NEG control — excised copy retains $MUT_LINES of $LIVE_LINES lines (targeted, not wholesale)"
  else
    bad "A-NEG control — excised copy dropped to $MUT_LINES of $LIVE_LINES lines; the mutation is too broad to attribute"
  fi
fi
echo

# ---------------------------------------------------------------------------
# Extract the Mode O section from a given copy of the release-hub SKILL.md.
#
# Terminates on the next heading of level 2 OR 3, matching extract_hub_section's
# strictness for the same reason: the clause being graded is one paragraph inside
# a long section, and an extractor that over-ran it would grade text outside the
# clause.
# ---------------------------------------------------------------------------
extract_mode_o_section() {
  awk '
    /^### Mode O — Orchestrate Release$/ { inside = 1; next }
    inside && (/^## / || /^### /) { inside = 0 }
    inside { print }
  ' "$1"
}

# ---------------------------------------------------------------------------
# Packaged-surface arms (#5833 F-03), evaluated against an arbitrary copy of the
# release-hub SKILL.md.
#
# WHY THESE ARE A SEPARATE FUNCTION AND NOT ARMS INSIDE clause_arms():
# clause_arms() is parameterised over ONE document, and A-NEG feeds it a mutated
# copy of the BRIDGE. An arm placed in clause_arms() that reads a DIFFERENT file
# would read the real, unexcised SKILL.md on the A-NEG pass, pass there, and be
# counted as a survivor — which would redden A-NEG and thereby DISABLE the
# deletion-sensitivity control that proves the other nine arms grade their
# clause. Covering the packaged copy therefore requires its own function, its own
# fixture, and its own negative control. clause_arms() and the A-NEG loop are
# left byte-untouched by this addition, which is the point.
#
# WHY IT IS GRADED AT ALL: the staging path literal and the Step-6 end anchor are
# duplicated from hub-spoke-bridge.md into this SKILL.md — the packaged, deployed
# surface. Arms A7-A9 grade only the bridge, so before these arms the copy that
# actually ships was ungraded and free to drift.
# ---------------------------------------------------------------------------
packaged_arms() {
  local doc="$1" mode_o
  mode_o="$(extract_mode_o_section "$doc")"

  # C1 — the Mode O section exists at all. Section-level arm: it is what makes a
  #      wholesale removal of the section detectable rather than silent.
  if [ -n "$mode_o" ]; then echo "C1 PASS"; else echo "C1 FAIL"; fi

  # C2 — the staging path literal, in registered-token form, matching A8's needle
  #      byte for byte. Sharing the needle with A8 is what makes agreement between
  #      the two surfaces assertable: both arms green means both copies carry the
  #      same literal, and a drift in either reddens one of them.
  #      Fixed-string match: the path carries `<`, `>` and `/`, regex-live under -E.
  #      Here-string, not a piped writer: this file runs under `pipefail`, where a
  #      short-circuiting reader breaks the writer's pipe and a MATCH can report
  #      failure.
  if grep -qF -- '<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/staging/' <<<"$mode_o"
  then echo "C2 PASS"; else echo "C2 FAIL"; fi

  # C3 — the end anchor, tied to the same NAMED release event A9 grades on the
  #      bridge, not a duration. Scoped to $mode_o for the same reason A9 is
  #      scoped to $hub_section.
  if grep -qF -- 'Procedure 7 Step 6' <<<"$mode_o"
  then echo "C3 PASS"; else echo "C3 FAIL"; fi

  # C4 — the duplicate cites the canonical clause rather than standing alone. A
  #      copy that names its source is a pointer a reader can reconcile; one that
  #      does not is a second authority.
  if grep -qF -- '§ Hub Staging Discipline' <<<"$mode_o"
  then echo "C4 PASS"; else echo "C4 FAIL"; fi
}

# ---------------------------------------------------------------------------
echo "(C) Packaged-surface arms — the deployed release-hub SKILL.md copy"
# ---------------------------------------------------------------------------
PKG_RESULTS="$(packaged_arms "$HUB_SKILL")"
for arm in C1 C2 C3 C4; do
  # Here-string for the same pipefail reason as A8.
  if grep -qx -- "$arm PASS" <<<"$PKG_RESULTS"; then
    ok "$arm — clause assertion holds in release-hub/SKILL.md"
  else
    bad "$arm — clause assertion does NOT hold in release-hub/SKILL.md"
  fi
done
echo

# ---------------------------------------------------------------------------
echo "(C-NEG) Deletion sensitivity — the packaged arms against an excised copy"
# ---------------------------------------------------------------------------
# Excise the staging paragraph ONLY, not the whole Mode O section. A whole-section
# excision would drop ~10% of the file and collide with the retention control
# below, making "everything failed" trivially true. Deleting the one paragraph
# that carries all three needles is the targeted mutation.
#
# The mutation keys on the paragraph's bolded opening. If that opening is
# reworded the delete no-ops, C2-C4 survive, and this arm turns RED — a loud
# failure that names the coupling, never a silent pass.
#
# C1 is harvested above but deliberately NOT in the survivor loop below: it is a
# section-existence arm, so it passes legitimately against a copy whose section
# is intact and only the paragraph removed. Including it would corrupt the
# deletion-sensitivity count — the same reason A4b is excluded from A-NEG.
PKG_MUTATED="$WORK/skill-clause-deleted.md"
sed -e '/^\*\*Staging — one location, one end\.\*\*/d' "$HUB_SKILL" > "$PKG_MUTATED"

if [ ! -s "$PKG_MUTATED" ]; then
  bad "C-NEG — mutated fixture is empty; the excision step is broken"
else
  PKG_MUT_RESULTS="$(packaged_arms "$PKG_MUTATED")"
  PKG_SURVIVORS=0
  for arm in C2 C3 C4; do
    # Here-string for the same pipefail reason as A8.
    if grep -qx -- "$arm PASS" <<<"$PKG_MUT_RESULTS"; then
      PKG_SURVIVORS=$((PKG_SURVIVORS+1))
      printf '         survivor: %s still passes with the clause deleted\n' "$arm"
    fi
  done
  if [ "$PKG_SURVIVORS" -eq 0 ]; then
    ok "C-NEG — all 3 packaged clause arms fail when the paragraph is excised (deletion-sensitive)"
  else
    bad "C-NEG — $PKG_SURVIVORS of 3 packaged clause arms survive deletion; they do not grade the clause"
  fi
  # Instrument validation for the excision itself: a targeted one-paragraph cut,
  # not a wholesale truncation that would make the failures unattributable.
  PKG_MUT_LINES="$(wc -l < "$PKG_MUTATED" | tr -d ' ')"
  PKG_LIVE_LINES="$(wc -l < "$HUB_SKILL" | tr -d ' ')"
  if [ "$PKG_MUT_LINES" -gt $(( PKG_LIVE_LINES * 9 / 10 )) ]; then
    ok "C-NEG control — excised copy retains $PKG_MUT_LINES of $PKG_LIVE_LINES lines (targeted, not wholesale)"
  else
    bad "C-NEG control — excised copy dropped to $PKG_MUT_LINES of $PKG_LIVE_LINES lines; the mutation is too broad to attribute"
  fi
fi
echo

# ---------------------------------------------------------------------------
echo "(B) Behavioural arms — resolution, isolation, and the non-conforming read"
# ---------------------------------------------------------------------------
SCRATCH_BASE="$WORK/scratch"
mkdir -p "$SCRATCH_BASE"

# The resolution the clause prescribes, verbatim in shape.
resolve_spoke_out() {  # $1 = stage, $2 = sub-task number
  mktemp -d "${SCRATCH_BASE}/spoke-$1-$2-XXXXXX"
}

STAGE=6
SUBTASK=4804
SENTINEL_NAME="stage-comment.md"

# --- B1: serial re-run of the SAME stage + SAME sub-task ---
RUN1="$(resolve_spoke_out "$STAGE" "$SUBTASK")"
printf 'run-1 output body — must never reach run 2\n' > "$RUN1/$SENTINEL_NAME"
RUN2="$(resolve_spoke_out "$STAGE" "$SUBTASK")"

if [ "$RUN1" != "$RUN2" ]; then
  ok "B1 — a re-run of stage $STAGE / sub-task $SUBTASK resolves a DIFFERENT run directory"
else
  bad "B1 — the re-run resolved run 1's directory ($RUN1); the leftover is in scope"
fi

RUN2_COUNT="$(find "$RUN2" -type f | wc -l | tr -d ' ')"
if [ "$RUN2_COUNT" -eq 0 ]; then
  ok "B1b — run 2's directory is empty (0 files) at resolution"
else
  bad "B1b — run 2's directory already holds $RUN2_COUNT file(s)"
fi

# --- B2: SENSITIVITY. A non-conforming reader — one that globs the shared
#         parent instead of reading only $SPOKE_OUT — DOES reach run 1's file.
#         This is the #3211 shape reproduced on purpose. It must be NON-ZERO,
#         or B1/B4's zeros are a broken probe rather than a real negative.
NONCONFORMING_HITS="$(find "$SCRATCH_BASE" -path "*/spoke-${STAGE}-${SUBTASK}-*" \
                        -name "$SENTINEL_NAME" -type f | wc -l | tr -d ' ')"
if [ "$NONCONFORMING_HITS" -ge 1 ]; then
  ok "B2 sensitivity — a shared-parent glob DOES find $NONCONFORMING_HITS leftover(s); the hazard is reachable when the read clause is violated"
else
  bad "B2 sensitivity — the glob found 0 leftovers; the probe cannot observe the defect it exists to detect (BROKEN PROBE)"
fi

# --- B4: SPECIFICITY on a KNOWN-ABSENT target. The conforming read scope is
#         run 2's $SPOKE_OUT only. The sentinel is known to EXIST (B2 proved
#         it) and known to be ABSENT from this directory. Zero here is the arm's
#         pass condition precisely because the population is non-empty elsewhere.
CONFORMING_HITS="$(find "$RUN2" -name "$SENTINEL_NAME" -type f | wc -l | tr -d ' ')"
if [ "$CONFORMING_HITS" -eq 0 ]; then
  ok "B4 specificity — a read scoped to run 2's \$SPOKE_OUT finds 0 of the $NONCONFORMING_HITS existing leftover(s)"
else
  bad "B4 specificity — the conforming read reached $CONFORMING_HITS leftover(s)"
fi

# --- B5: SENSITIVITY for the read mechanism itself. Without this, B4's zero is
#         consistent with a reader that can never find anything.
printf 'own artifact\n' > "$RUN2/own-evidence.txt"
OWN_HITS="$(find "$RUN2" -name 'own-evidence.txt' -type f | wc -l | tr -d ' ')"
if [ "$OWN_HITS" -eq 1 ]; then
  ok "B5 sensitivity — the same reader DOES find run 2's own artifact (1); B4's zero is a real negative"
else
  bad "B5 sensitivity — the reader found $OWN_HITS of its own artifact; the instrument is broken"
fi

# --- B3: concurrent resolution for the same stage + sub-task ---
CONC_LIST="$WORK/concurrent-dirs.txt"
: > "$CONC_LIST"
N=6
i=0
while [ "$i" -lt "$N" ]; do
  ( d="$(resolve_spoke_out "$STAGE" "$SUBTASK")"; printf '%s\n' "$d" >> "$CONC_LIST" ) &
  i=$((i+1))
done
wait

CONC_TOTAL="$(wc -l < "$CONC_LIST" | tr -d ' ')"
CONC_DISTINCT="$(sort -u "$CONC_LIST" | wc -l | tr -d ' ')"
if [ "$CONC_TOTAL" -eq "$N" ] && [ "$CONC_DISTINCT" -eq "$N" ]; then
  ok "B3 — $N concurrent resolutions produced $CONC_DISTINCT distinct directories"
else
  bad "B3 — $CONC_TOTAL resolutions produced $CONC_DISTINCT distinct directories (expected $N/$N)"
fi

# Pairwise-disjoint contents: each concurrent run writes a same-named file;
# no run may observe another's. Denominator = the N directories just resolved.
while IFS= read -r d; do
  printf '%s\n' "$d" > "$d/$SENTINEL_NAME"
done < "$CONC_LIST"

CROSS=0
while IFS= read -r d; do
  body="$(cat "$d/$SENTINEL_NAME")"
  [ "$body" = "$d" ] || CROSS=$((CROSS+1))
done < "$CONC_LIST"
if [ "$CROSS" -eq 0 ]; then
  ok "B3b — 0 of $CONC_TOTAL concurrent runs read a sibling's same-named artifact"
else
  bad "B3b — $CROSS of $CONC_TOTAL concurrent runs read a sibling's artifact"
fi

echo
echo "-----------------------------------------------------------------"
printf 'NC-NS-1: %d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '\nFailures:\n'
  for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
exit 0
