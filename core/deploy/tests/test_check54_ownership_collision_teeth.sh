#!/usr/bin/env bash
# test_check54_ownership_collision_teeth.sh — corpus-level negative controls proving
# deploy.sh Check 54's ADR-044 I3 and I1 invariants can actually fire.
#
# Cite the code under test by its INLINE MARKER, never by line number:
#   core/deploy/tools/check-ownership-collision.py, `I3 contract<->matrix:`
#   core/deploy/tools/check-ownership-collision.py, `I1 second-maintainer:`
# Resolver: grep -n 'I3 contract<->matrix' core/deploy/tools/check-ownership-collision.py
#
# WHY THIS EXISTS RATHER THAN THE PRIMITIVE'S OWN --self-test.
# `check-ownership-collision.py --self-test` already passes, and already asserts
# `I3-fires` / `I1-fires` against 3-row fixtures written inline in its own source.
# That proves the predicate compiles against a toy matrix. It cannot prove the
# predicate fires against the REAL section-6 owning-agent matrix and the REAL
# per-skill output contracts — and that is the only population that matters, because
# until this suite's companion change the contracts file carried ZERO
# `Maintains-entity:` markers and both I3 and I4 key on exactly that marker. A check
# whose escalate predicate has an empty population is zero-ESCALATE by construction:
# it reads as coverage and enforces nothing. Every arm below therefore runs against a
# COPY of the live corpus, not a hand-built miniature.
#
# WHAT EACH ARM IS FOR, and why the specificity arms are not decoration.
# A1/A6 assert ZEROS — the live corpus is clean. A zero whose control arm also
# returns zero is a broken probe, so A3/A5/A7 drive the SAME instrument over the
# SAME corpus with one mutation each and require a non-zero. A4 then pins the
# mutation to the live section-6 matrix: if `RAID Item` ever stops being maintained
# by a skill OTHER than the one whose section carries the injected marker, A3 would
# stop reproducing an I3 collision and would pass vacuously. A4 fails first instead.
#
# A7 IS THE ARM THAT GUARDS A TRAP. The contracts file's marker convention carries a
# worked example, and that example is inert ONLY because it sits above the first
# skill header — the parser discards every line before that point. The identical text
# inside a skill section is a live declaration. A7 relocates the file's own example
# into a skill section and requires a collision, which proves two things at once: the
# example text really is matchable (so its inertness is placement-derived, not a typo)
# and the current placement is load-bearing. A future editor who "tidies" that section
# into the skill catalogue fails this test instead of silently arming a false I3.
#
# A8 IS NOT CEREMONY. Every fixture is built by a text transform over the live corpus.
# A transform that silently matched nothing would produce a byte-identical copy, and
# the specificity arms would then pass for the wrong reason. A8 asserts each fixture
# actually differs from its source — the post-state, not the attempt.
#
# HERMETIC by construction: every fixture is built under mktemp -d from a COPY. The
# live durable corpus is READ and never written. No `gh`, no network.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PRIMITIVE="${SRC_ROOT}/core/deploy/tools/check-ownership-collision.py"
LIVE_CONTRACTS="${SRC_ROOT}/core/schemas/per-skill-output-contracts.md"
LIVE_MODEL="${SRC_ROOT}/core/disciplines/project-entity-model.md"
LIVE_INVENTORY="${SRC_ROOT}/core/specs/operational-artifact-inventory.md"

# The adopted declaration under test, and the entity used to manufacture a collision.
# ADOPTED_* is what the corpus declares; COLLIDE_ENTITY is an entity the adopting
# skill does NOT maintain, so injecting it into that skill's section contradicts §6.
ADOPTED_SKILL="delivery-engine"
ADOPTED_ENTITY="Milestone"
COLLIDE_ENTITY="RAID Item"
COLLIDE_OWNER="tracker-manager"
I1_SECOND="release-planner"

PASS_COUNT=0
FAIL_COUNT=0
report() { # report <name> <ok:1|0> [detail]
  if [[ "$2" == "1" ]]; then
    echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $1${3:+ — $3}"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}
note() { printf '        %s\n' "$1"; }

for f in "$PRIMITIVE" "$LIVE_CONTRACTS" "$LIVE_MODEL" "$LIVE_INVENTORY"; do
  if [[ ! -f "$f" ]]; then
    echo "  FAIL: corpus surface missing: $f"
    echo "passed=0 failed=1"
    exit 1
  fi
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# run_check <contracts> <model> -> stdout+stderr on stdout; EXIT STATUS is the
# primitive's own. The status is deliberately propagated as the function's return
# rather than stashed in a global: every call site captures output with `$( )`, and
# an assignment made inside that subshell never reaches the caller — a global would
# read 0 on every arm and the sensitivity arms would fail for a reason that has
# nothing to do with the check.
run_check() {
  /usr/bin/python3 "$PRIMITIVE" \
    --entity-model "$2" \
    --output-contracts "$1" \
    --artifact-inventory "$LIVE_INVENTORY" \
    --output-format text 2>&1
}

echo "test_check54_ownership_collision_teeth.sh"
echo "─────────────────────────────────────────────────────────────────────────"
echo

# ── Fixtures ────────────────────────────────────────────────────────────────
# F_I3 — the live contracts file with one maintainer-grade marker injected into the
# adopting skill's section for an entity that skill does NOT maintain.
F_I3="$TMP/contracts-i3.md"
awk -v ins="- Maintains-entity: ${COLLIDE_ENTITY}" '
  { print }
  !seen && /^## Skill 2:/ { print ""; print ins; seen = 1 }
' "$LIVE_CONTRACTS" > "$F_I3"

# F_PLACE — the live contracts file with its OWN convention worked example relocated
# from above the first skill header into the first skill section. The example line is
# extracted from the file rather than retyped, so a reworded example cannot make this
# arm stale: it would simply carry the new wording.
EXAMPLE_LINE="$(awk '/^## Skill [0-9]+:/ { exit } /Maintains-entity:[[:space:]]*[A-Za-z]/ { print; exit }' "$LIVE_CONTRACTS")"
F_PLACE="$TMP/contracts-placement.md"
if [[ -n "$EXAMPLE_LINE" ]]; then
  awk -v ins="$EXAMPLE_LINE" '
    { print }
    !seen && /^## Skill 1:/ { print ""; print ins; seen = 1 }
  ' "$LIVE_CONTRACTS" > "$F_PLACE"
else
  : > "$F_PLACE"
fi

# F_I1 — the live entity model with one §6 Maintains cell widened to two skills.
# Gated to the §6 region so a same-named first cell in another table cannot be hit.
F_I1="$TMP/model-i1.md"
awk -v ent="$ADOPTED_ENTITY" -v second="$I1_SECOND" '
  BEGIN { FS = "|"; OFS = "|" }
  /^## 6\./                 { in6 = 1 }
  in6 && /^## / && !/^## 6\./ { in6 = 0 }
  {
    if (in6 && NF >= 5) {
      cell = $2; gsub(/^[ \t]+|[ \t]+$/, "", cell)
      if (cell == ent) { $4 = $4 "/ " second " " }
    }
    print
  }
' "$LIVE_MODEL" > "$F_I1"

# ── A8 — mutation guard: every fixture differs from its source ───────────────
# Runs FIRST because every arm below is meaningless if a transform silently no-opped.
a8_ok=1; a8_detail=""
cmp -s "$F_I3" "$LIVE_CONTRACTS"    && { a8_ok=0; a8_detail="I3 fixture byte-identical to source"; }
cmp -s "$F_I1" "$LIVE_MODEL"        && { a8_ok=0; a8_detail="${a8_detail:+$a8_detail; }I1 fixture byte-identical to source"; }
cmp -s "$F_PLACE" "$LIVE_CONTRACTS" && { a8_ok=0; a8_detail="${a8_detail:+$a8_detail; }placement fixture byte-identical to source"; }
[[ -s "$F_PLACE" ]] || { a8_ok=0; a8_detail="${a8_detail:+$a8_detail; }no marker example found above the first skill header"; }
report "A8 every fixture differs from the corpus it was built from" "$a8_ok" "$a8_detail"

# ── A4 — anti-vacuity: the collision entity is really owned by a DIFFERENT skill ──
# Read from the live §6 matrix, not asserted from memory. If ownership ever changes,
# this fails before A3 can pass vacuously.
owner_line="$(awk -v ent="$COLLIDE_ENTITY" '
  BEGIN { FS = "|" }
  /^## 6\./                 { in6 = 1 }
  in6 && /^## / && !/^## 6\./ { in6 = 0 }
  in6 && NF >= 5 {
    cell = $2; gsub(/^[ \t]+|[ \t]+$/, "", cell)
    if (cell == ent) { m = $4; gsub(/^[ \t]+|[ \t]+$/, "", m); print m; exit }
  }
' "$LIVE_MODEL")"
if [[ "$owner_line" == "$COLLIDE_OWNER" && "$owner_line" != "$ADOPTED_SKILL" ]]; then
  report "A4 §6 still maintains '$COLLIDE_ENTITY' by '$COLLIDE_OWNER', not '$ADOPTED_SKILL' (A3 can reproduce a real collision)" 1
else
  report "A4 §6 still maintains '$COLLIDE_ENTITY' by '$COLLIDE_OWNER', not '$ADOPTED_SKILL'" 0 \
    "§6 Maintains cell reads '${owner_line:-<entity row not found>}' — A3's injected marker would no longer contradict §6, so it would pass vacuously"
fi

# ── A1 — SPECIFICITY: the live corpus, adopted marker and all, is clean ─────
a1_out="$(run_check "$LIVE_CONTRACTS" "$LIVE_MODEL")"; a1_rc=$?
[[ "$a1_rc" -eq 0 ]] \
  && report "A1 live corpus reconciles clean (exit 0) with the adopted marker in place" 1 \
  || report "A1 live corpus reconciles clean (exit 0)" 0 "exit=$a1_rc — $a1_out"
note "$a1_out"

# ── A2 — the adoption itself: exactly ONE live declaration, correctly attributed ──
# Uses the primitive's OWN parser rather than a re-encoded regex, so the assertion
# cannot drift away from the code it stands in for.
a2_out="$(/usr/bin/python3 - "$PRIMITIVE" "$LIVE_CONTRACTS" 2>&1 <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("coc", sys.argv[1])
coc = importlib.util.module_from_spec(spec); spec.loader.exec_module(coc)
decls, _ = coc.parse_output_contracts(open(sys.argv[2], encoding="utf-8").read())
raw = coc._MAINTAIN_MARKER_RE.findall(open(sys.argv[2], encoding="utf-8").read())
print("%d|%d|%s" % (len(decls), len(raw), ",".join("%s->%s" % d for d in decls)))
PYEOF
)"; a2_rc=$?
a2_decl_n="${a2_out%%|*}"
a2_rest="${a2_out#*|}"
a2_raw_n="${a2_rest%%|*}"
a2_pairs="${a2_rest#*|}"
if [[ "$a2_rc" -eq 0 && "$a2_decl_n" == "1" && "$a2_pairs" == "${ADOPTED_SKILL}->${ADOPTED_ENTITY}" ]]; then
  report "A2 the contracts file declares exactly one maintainer-write: ${ADOPTED_SKILL} -> ${ADOPTED_ENTITY}" 1
else
  report "A2 the contracts file declares exactly one maintainer-write" 0 \
    "parser returned n=${a2_decl_n} pairs='${a2_pairs}' (rc=$a2_rc), want n=1 '${ADOPTED_SKILL}->${ADOPTED_ENTITY}'"
fi
# Paired half: the convention section carries matchable text that is inert BY
# PLACEMENT. If raw hits ever equal parsed declarations, the convention section lost
# its worked example and A7 is asserting nothing.
if [[ "$a2_rc" -eq 0 ]] && [[ "$a2_raw_n" -gt "$a2_decl_n" ]]; then
  report "A2b the convention section contributes matchable-but-inert text ($a2_raw_n raw vs $a2_decl_n live)" 1
else
  report "A2b the convention section contributes matchable-but-inert text" 0 \
    "raw=$a2_raw_n live=$a2_decl_n — nothing is inert-by-placement, so A7 proves nothing"
fi

# ── A3 — SENSITIVITY (I3): a marker contradicting §6 escalates ──────────────
a3_out="$(run_check "$F_I3" "$LIVE_MODEL")"; a3_rc=$?
a3_ok=1; a3_missing=""
[[ "$a3_rc" -eq 1 ]] || { a3_ok=0; a3_missing="exit=$a3_rc (want 1)"; }
for frag in "I3 contract<->matrix" "$ADOPTED_SKILL" "$COLLIDE_ENTITY" "$COLLIDE_OWNER"; do
  case "$a3_out" in
    *"$frag"*) : ;;
    *) a3_ok=0; a3_missing="${a3_missing:+$a3_missing; }output does not name '$frag'" ;;
  esac
done
report "A3 I3 fires on the live corpus plus one contradicting marker, and names the collision" "$a3_ok" "$a3_missing"
note "$a3_out"

# ── A5 — SENSITIVITY (I1): a §6 cell resolving to two maintainers escalates ──
a5_out="$(run_check "$LIVE_CONTRACTS" "$F_I1")"; a5_rc=$?
a5_ok=1; a5_missing=""
[[ "$a5_rc" -eq 1 ]] || { a5_ok=0; a5_missing="exit=$a5_rc (want 1)"; }
for frag in "I1 second-maintainer" "$ADOPTED_ENTITY" "$ADOPTED_SKILL" "$I1_SECOND"; do
  case "$a5_out" in
    *"$frag"*) : ;;
    *) a5_ok=0; a5_missing="${a5_missing:+$a5_missing; }output does not name '$frag'" ;;
  esac
done
report "A5 I1 fires on a §6 cell widened to two maintainers, and names both" "$a5_ok" "$a5_missing"
note "$a5_out"

# ── A6 — SPECIFICITY (I1): the unmutated §6 matrix on the same instrument ───
a6_out="$(run_check "$LIVE_CONTRACTS" "$LIVE_MODEL")"; a6_rc=$?
[[ "$a6_rc" -eq 0 ]] \
  && report "A6 the unmutated §6 matrix exits 0 on the same instrument (A5's 1 is the mutation, not the tool)" 1 \
  || report "A6 the unmutated §6 matrix exits 0 on the same instrument" 0 "exit=$a6_rc — $a6_out"

# ── A7 — PLACEMENT: the convention's own example fires once relocated ───────
a7_out="$(run_check "$F_PLACE" "$LIVE_MODEL")"; a7_rc=$?
if [[ "$a7_rc" -eq 1 && "$a7_out" == *"I3 contract<->matrix"* ]]; then
  report "A7 the convention's worked example becomes a LIVE declaration inside a skill section (its inertness is placement-derived)" 1
  note "relocated line: $EXAMPLE_LINE"
  note "$a7_out"
else
  report "A7 the convention's worked example becomes a LIVE declaration inside a skill section" 0 \
    "exit=$a7_rc (want 1) — either the example is no longer matchable, or the parser stopped discarding pre-skill text; A1's zero is then unexplained"
fi

# ── A9 — drift guard: the primitive still emits the invariants this file pins ──
a9_ok=1; a9_missing=""
for lit in "I3 contract<->matrix" "I1 second-maintainer" "_MAINTAIN_MARKER_RE"; do
  grep -qF -- "$lit" "$PRIMITIVE" || { a9_ok=0; a9_missing="${a9_missing:+$a9_missing; }'$lit' absent from the primitive"; }
done
report "A9 the primitive still carries the I3/I1 emit strings and the marker pattern this file pins" "$a9_ok" "$a9_missing"

echo
echo "passed=$PASS_COUNT failed=$FAIL_COUNT"
[[ "$FAIL_COUNT" -eq 0 ]] || exit 1
