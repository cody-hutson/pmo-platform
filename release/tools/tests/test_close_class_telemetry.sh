#!/usr/bin/env bash
set -uo pipefail
# test_close_class_telemetry.sh — regression suite for compute-close-class-telemetry.sh.
#
# WHY THIS EXISTS
#   The tool's own --self-test reported PASS for a long stretch during which the tool
#   could not run on ANY live milestone. count_subtask_evidence() passed the whole
#   `gh issue list --json number,title,state,comments` payload as one argv operand; for a
#   real release that payload carries every sub-task's full comment bodies and exceeds the
#   platform argument limit, so the interpreter never started and the script died with
#   "Argument list too long". Every self-test arm fed a payload of a few hundred bytes, so
#   the suite was STRUCTURALLY INCAPABLE of reaching the defect. A green signal that cannot
#   go red is the failure this suite exists to make impossible.
#
# WHAT THIS SUITE GRADES — and what it deliberately does NOT
#   It does not re-assert that the tool's own arms pass; that would only restate --self-test.
#   It grades whether those arms DISCRIMINATE. Every group carries a mutation arm: the
#   shipped script is mechanically reverted to the pre-fix shape and MUST fail. An arm that
#   still passes against the mutant is decorative, and this suite treats that as its own
#   failure rather than reporting a clean run.
#
#   Every mutation is guarded by an EXTRACTION CONTROL — the anchor must be found exactly
#   once before the mutant is trusted. A mutation that silently no-ops would produce a
#   "sensitivity arm failed to fail" verdict that is really a broken instrument, and the
#   suite refuses to report either verdict without proving the edit landed.
#
# GROUPS
#   (A) PAYLOAD TRANSPORT — the over-argv defect. Independent over-bound control on this
#       host, specificity against the shipped script, sensitivity against a true pre-fix
#       mutant, and a structural guard against reintroduction.
#   (B) INDICATOR 5 HONESTY — rollup-presence must be BIVALENT. Sensitivity against a
#       mutant whose predicate is pinned to one answer (the tautology shape the flag had),
#       plus the denominator-isolation guard on the marker arrays.
#   (C) INTERFACE CONTRACT — the clauses a downstream caller is entitled to rely on:
#       no new required flag, single-line stdout, and an un-truncated --help.
#   (D) DENOMINATOR INTEGRITY — Indicator 6 must not fail open. Arm presence for the
#       denominator-integrity fixtures, and sensitivity against a mutant that collapses the
#       unmeasurable-denominator limb back into the clean-absence limb — the verbatim pre-fix
#       behaviour, in which a true zero and a total label gap emitted the identical 21 bytes.
#
# Offline + deterministic: no network, no gh, no writes to any operator-instance path, no
# writes into the repo. All fixtures live under one mktemp dir.
#
# Run:  bash release/tools/tests/test_close_class_telemetry.sh
# Exit: 0 = all assertions pass, 1 = one or more failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$HERE/../.." && pwd -P)"
TOOL="$REPO_ROOT/tools/compute-close-class-telemetry.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0; FAILURES=()
ok()  { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }

echo "compute-close-class-telemetry.sh — regression suite"
echo

if [ ! -f "$TOOL" ]; then
  echo "  FAIL — cannot locate compute-close-class-telemetry.sh at $TOOL"
  exit 1
fi

# ---------------------------------------------------------------------------
# mutate <src> <dst> <anchor-set>
#   Rewrites <src> into <dst>, replacing each anchor of the named set exactly once.
#   Prints "OK <n>" when every anchor was found exactly once, or "BROKEN <detail>"
#   otherwise. The caller MUST treat BROKEN as an instrument failure, never as a verdict.
# ---------------------------------------------------------------------------
mutate() {
  /usr/bin/python3 - "$1" "$2" "$3" <<'PY'
import sys
src, dst, which = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(src, encoding="utf-8").read()

SETS = {
    # Revert BOTH halves of the payload transport to the verbatim pre-fix form. Reverting
    # only one half produces a hybrid that fails for the wrong reason, which would let a
    # broken instrument masquerade as a working sensitivity arm.
    "argv-transport": [
        ("""/usr/bin/python3 - <(printf '%s' "$json") <<'PY' || _rc=$?""",
         """/usr/bin/python3 - "$json" <<'PY' || _rc=$?"""),
        ("""    with open(sys.argv[1], encoding="utf-8") as _fh:
        items = json.load(_fh)
except (ValueError, TypeError, OSError, UnicodeDecodeError) as e:""",
         """    items = json.loads(sys.argv[1])
except (ValueError, TypeError) as e:"""),
    ],
    # Pin the roll-up predicate to a single answer — the exact shape the retired
    # --outcome-present flag had, where no reading could ever differ.
    "pinned-rollup": [
        ("""  local file="$1" m
  for m in "${ROLLUP_MARKERS[@]}"; do
    if /usr/bin/grep -Fxq "$m" "$file" 2>/dev/null; then
      return 0
    fi
  done
  return 1""",
         """  local file="$1" m
  return 0"""),
    ],
    # Collapse the unmeasurable-denominator limb back into the clean-absence limb. This is
    # the verbatim pre-fix behaviour: a true zero and a milestone whose stage sub-tasks are
    # unlabelled both render `N/A - no stage sub-tasks scaffolded`, and a reader has no
    # signal that anything is wrong. The guard's own DZ/DU inequality MUST catch it.
    "collapsed-denominator": [
        ("""    elif [[ "$u" -gt 0 ]]; then
      ra="truncated"; rb="NOT-EVALUATED\"""",
         """    elif [[ "$u" -gt 999999 ]]; then
      ra="truncated"; rb="NOT-EVALUATED\""""),
    ],
}

pairs = SETS.get(which)
if pairs is None:
    print("BROKEN unknown anchor set %s" % which)
    sys.exit(0)

for old, new in pairs:
    n = s.count(old)
    if n != 1:
        print("BROKEN anchor found %d times (expected 1) in set %s" % (n, which))
        sys.exit(0)
    s = s.replace(old, new)

open(dst, "w", encoding="utf-8").write(s)
print("OK %d" % len(pairs))
PY
}

# ---------------------------------------------------------------------------
# GROUP A — payload transport
# ---------------------------------------------------------------------------
echo "GROUP A — payload transport (the over-argv defect)"

# A0 — extraction control. Read the shipped file before asserting anything about it, and
#      prove the read was non-empty. A zero-byte read would make every grep below return
#      a clean-looking zero.
TOOL_BYTES="$(/usr/bin/wc -c < "$TOOL" | /usr/bin/tr -d ' ')"
if [ "${TOOL_BYTES:-0}" -gt 1000 ]; then
  ok "A0 extraction control — shipped tool read, $TOOL_BYTES bytes (non-empty)"
else
  bad "A0 extraction control — shipped tool read as ${TOOL_BYTES:-0} bytes; every arm below would be vacuous"
fi

# A1 — independent over-bound control ON THIS HOST. The argv ceiling is platform-dependent
#      (a total-argv cap on one platform, a per-argument cap on another), so the suite
#      proves the bound is real here rather than trusting a number measured elsewhere. If
#      exec accepts the payload, the whole group is vacuous and says so.
# Built by DOUBLING, not by pattern substitution: bash 3.2's ${var// /X} is quadratic and
# takes minutes on a payload this size, which would look like a hung suite rather than a
# slow one.
BIGARG="XXXXXXXXXXXXXXXX"
while [ "${#BIGARG}" -lt 262144 ]; do BIGARG="${BIGARG}${BIGARG}"; done
OVERBOUND=0
for _ in 1 2 3 4 5 6 7; do
  if ! /usr/bin/true "$BIGARG" 2>/dev/null; then OVERBOUND=1; break; fi
  BIGARG="${BIGARG}${BIGARG}"
done
if [ "$OVERBOUND" -eq 1 ]; then
  ok "A1 over-bound control — exec refuses a ${#BIGARG}-byte argv operand on this host"
else
  bad "A1 over-bound control — exec accepted a ${#BIGARG}-byte argv operand; GROUP A cannot discriminate on this host"
fi

# A2 — SPECIFICITY. The shipped script passes its own suite, whose over-argv arm builds a
#      payload sized adaptively until exec actually refuses it. Observed: zero failures.
SELFTEST_OUT="$WORK/selftest.txt"
if "$TOOL" --self-test >"$SELFTEST_OUT" 2>&1; then
  ok "A2 specificity — shipped --self-test exits 0 (sensitivity arm observed zero)"
else
  bad "A2 specificity — shipped --self-test FAILED: $(/usr/bin/tail -1 "$SELFTEST_OUT")"
fi

# A3 — the shipped suite actually REACHES the over-argv arm. A2 alone would still pass if
#      the arm were deleted, so assert the arm reported, and reported a computed rate.
if /usr/bin/grep -q 'OVER-ARGV transport validated' "$SELFTEST_OUT"; then
  ok "A3 arm presence — $(/usr/bin/grep 'OVER-ARGV transport validated' "$SELFTEST_OUT" | /usr/bin/sed 's/^ *//')"
else
  bad "A3 arm presence — shipped --self-test passed WITHOUT reporting the over-argv arm; it is green on a path it never exercised"
fi

# A4 — SENSITIVITY. Revert the transport to the verbatim pre-fix form. The suite MUST go
#      red, and it must go red for the right reason: the interpreter refusing to start.
MUT_ARGV="$WORK/mutant-argv.sh"
MUT_ARGV_RESULT="$(mutate "$TOOL" "$MUT_ARGV" argv-transport)"
case "$MUT_ARGV_RESULT" in
  "OK 2")
    ok "A4a mutation-extraction control — both transport anchors replaced exactly once"
    chmod +x "$MUT_ARGV"
    MUT_OUT="$WORK/mutant-argv-out.txt"
    if "$MUT_ARGV" --self-test >"$MUT_OUT" 2>&1; then
      bad "A4b sensitivity — the pre-fix mutant PASSED its own suite; the over-argv arm is decorative"
    else
      if /usr/bin/grep -qi 'argument list too long' "$MUT_OUT"; then
        ok "A4b sensitivity — pre-fix mutant fails on 'Argument list too long' (observed non-zero, and for the right reason)"
      else
        bad "A4b sensitivity — pre-fix mutant failed, but not on the argv bound: $(/usr/bin/tail -1 "$MUT_OUT")"
      fi
    fi
    ;;
  *)
    bad "A4a mutation-extraction control — $MUT_ARGV_RESULT (instrument broken; no sensitivity verdict is reportable)"
    ;;
esac

# A5 — structural guard against reintroduction. Even if a future payload happened to fit,
#      the transport itself must never put the payload back on an argv.
ARGV_FORM="$(/usr/bin/grep -c 'python3 - "\$json"' "$TOOL" || true)"
if [ "${ARGV_FORM:-0}" -eq 0 ]; then
  ok "A5 reintroduction guard — the payload appears as an argv operand 0 times"
else
  bad "A5 reintroduction guard — the payload travels as an argv operand at $ARGV_FORM site(s); the ARG_MAX defect is back"
fi

echo

# ---------------------------------------------------------------------------
# GROUP B — Indicator 5 honesty
# ---------------------------------------------------------------------------
echo "GROUP B — Indicator 5 rollup-presence must be bivalent"

# B1 — denominator isolation. The roll-up marker must live in its OWN array. Appending it
#      to CANONICAL_MARKERS moves Indicator 1's denominator from 10 to 11 and retroactively
#      depresses retro-conformance on every register already written.
if /usr/bin/grep -q '^ROLLUP_MARKERS=(' "$TOOL"; then
  ok "B1a denominator isolation — ROLLUP_MARKERS is declared as its own array"
else
  bad "B1a denominator isolation — no separate ROLLUP_MARKERS array found"
fi
# Structure-shaped, with a control: count the DENOMINATOR ASSERTION specifically, and
# separately count all EXPECTED_MARKERS mentions. A zero on the first with a zero on the
# second means the probe is broken (or the file was read empty); a zero on the first with a
# non-zero second is a real removal. Reported separately so the two are never conflated.
DENOM_PIN="$(/usr/bin/grep -cE '\[\[ "\$EXPECTED_MARKERS" -eq 10 \]\]' "$TOOL" || true)"
DENOM_REFS="$(/usr/bin/grep -c 'EXPECTED_MARKERS' "$TOOL" || true)"
if [ "${DENOM_PIN:-0}" -ge 1 ]; then
  ok "B1b denominator pin — Indicator 1's denominator is still asserted at 10 ($DENOM_REFS EXPECTED_MARKERS references in file)"
elif [ "${DENOM_REFS:-0}" -eq 0 ]; then
  bad "B1b denominator pin — BROKEN PROBE: zero EXPECTED_MARKERS references at all, so the zero above is not a finding"
else
  bad "B1b denominator pin — the 10-marker denominator assertion is gone ($DENOM_REFS references remain); a silent /11 move would go unnoticed"
fi

# B2 — the shipped suite reports the trivalent arm. Presence of the arm is the thing A2
#      cannot see on its own.
if /usr/bin/grep -q 'rollup-presence validated' "$SELFTEST_OUT"; then
  ok "B2 arm presence — the bivalence arm reported in the shipped self-test"
else
  bad "B2 arm presence — shipped --self-test does not report a rollup-presence arm"
fi

# B3 — SENSITIVITY against the tautology shape. Pin the predicate to one answer, which is
#      exactly what the retired caller-supplied flag did, and the suite MUST go red.
MUT_PIN="$WORK/mutant-pinned.sh"
MUT_PIN_RESULT="$(mutate "$TOOL" "$MUT_PIN" pinned-rollup)"
case "$MUT_PIN_RESULT" in
  "OK 1")
    ok "B3a mutation-extraction control — the roll-up predicate anchor was replaced exactly once"
    chmod +x "$MUT_PIN"
    if "$MUT_PIN" --self-test >"$WORK/mutant-pinned-out.txt" 2>&1; then
      bad "B3b sensitivity — a predicate pinned to one answer PASSED the suite; rollup-presence is back to being unfalsifiable"
    else
      ok "B3b sensitivity — a predicate pinned to one answer fails the suite (the metric has a falsifier)"
    fi
    ;;
  *)
    bad "B3a mutation-extraction control — $MUT_PIN_RESULT (instrument broken; no sensitivity verdict is reportable)"
    ;;
esac

# B4 — the retired flag must not be domain-checked any more. A `die` on its value would
#      keep asserting a contract the tool no longer honours, and would hard-fail a caller
#      the deprecation window exists to protect.
if /usr/bin/grep -q 'outcome-present must be 0 or 1' "$TOOL"; then
  bad "B4 deprecation shape — --outcome-present is still domain-checked with a fatal error"
else
  ok "B4 deprecation shape — --outcome-present is accepted-and-ignored, not domain-checked"
fi

echo

# ---------------------------------------------------------------------------
# GROUP C — interface contract
# ---------------------------------------------------------------------------
echo "GROUP C — the interface contract a downstream caller relies on"

# C1 — no new REQUIRED flag. The transport fix must be invisible at the CLI: the required
#      set is still <version> plus --milestone, and nothing else. The probe counts guards
#      that DIE — an emptiness test that merely defaults a value (LESSONS_PATH falling back
#      to RETRO_PATH) is the same syntactic shape but is not a required-input guard, and
#      counting it would report a phantom third requirement.
REQUIRED_DIE="$(/usr/bin/grep -cE '^\[\[ -z .*\]\] && die ' "$TOOL" || true)"
EMPTY_TESTS="$(/usr/bin/grep -c '^\[\[ -z ' "$TOOL" || true)"
if [ "${REQUIRED_DIE:-0}" -eq 2 ]; then
  ok "C1 no new required flag — exactly 2 required-input guards that die (<version>, --milestone); $EMPTY_TESTS emptiness tests in total, the remainder being value defaulting"
elif [ "${EMPTY_TESTS:-0}" -eq 0 ]; then
  bad "C1 no new required flag — BROKEN PROBE: zero emptiness tests found at all, so the count above is not a finding"
else
  bad "C1 no new required flag — $REQUIRED_DIE required-input guard(s) found, expected 2 (of $EMPTY_TESTS emptiness tests)"
fi

# C2 — stdout stays a single field-value line. Asserted structurally against the emitter:
#      one unconditional `echo` of the composed field, and it is the last statement.
EMIT_COUNT="$(/usr/bin/grep -c '^echo "retro-conformance ' "$TOOL" || true)"
if [ "${EMIT_COUNT:-0}" -eq 1 ]; then
  ok "C2 single-line stdout — exactly one field emitter"
else
  bad "C2 single-line stdout — $EMIT_COUNT field emitters found, expected 1"
fi

# C3 — the deprecation notice goes to STDERR, so a caller piping stdout into the release
#      log never captures it as part of the field value.
if /usr/bin/grep -q 'outcome-present is DEPRECATED.*>&2' "$TOOL"; then
  ok "C3 diagnostics routing — the deprecation notice is written to stderr"
else
  bad "C3 diagnostics routing — the deprecation notice is not demonstrably stderr-routed"
fi

# C4 — --help must not be truncated. usage() prints a hardcoded line range, so a header
#      that grows past the upper bound silently loses its tail. Assert the last header line
#      actually reaches the output.
HELP_OUT="$WORK/help.txt"
"$TOOL" --help >"$HELP_OUT" 2>&1
if /usr/bin/grep -q 'Diagnostics go to stderr' "$HELP_OUT"; then
  ok "C4 help completeness — --help renders through the final header line"
else
  bad "C4 help completeness — --help is truncated before the final header line; usage()'s line range is stale"
fi

echo

# ---------------------------------------------------------------------------
# GROUP D — denominator integrity
# ---------------------------------------------------------------------------
echo "GROUP D — Indicator 6's denominator must not fail open"

# D1 — arm presence. A2 alone would still pass if the denominator-integrity fixtures were
#      deleted, so assert the shipped self-test REPORTED them. This is the arm that catches
#      a suite that is green on a path it never exercised.
if /usr/bin/grep -q 'denominator-integrity validated' "$SELFTEST_OUT"; then
  ok "D1 arm presence — $(/usr/bin/grep 'denominator-integrity validated' "$SELFTEST_OUT" | /usr/bin/sed 's/^ *//')"
else
  bad "D1 arm presence — shipped --self-test passed WITHOUT reporting the denominator-integrity arm; it is green on a path it never exercised"
fi

# D2 — SENSITIVITY. Collapse the unmeasurable-denominator limb into the clean-absence limb,
#      which is exactly what the tool did before this guard: a true zero and a total label
#      gap emitted the identical 21 bytes. The suite MUST go red, and for that reason.
MUT_DEN="$WORK/mutant-denominator.sh"
MUT_DEN_RESULT="$(mutate "$TOOL" "$MUT_DEN" collapsed-denominator)"
case "$MUT_DEN_RESULT" in
  "OK 1")
    ok "D2a mutation-extraction control — the unmeasurable-denominator limb was replaced exactly once"
    chmod +x "$MUT_DEN"
    MUT_DEN_OUT="$WORK/mutant-denominator-out.txt"
    if "$MUT_DEN" --self-test >"$MUT_DEN_OUT" 2>&1; then
      bad "D2b sensitivity — the collapsed-denominator mutant PASSED its own suite; the guard is decorative and an unmeasurable denominator still reads as a clean zero"
    else
      # "For the right reason" means the DU arm — the unlabelled-sub-task fixture — is what
      # went red. The collapse is observable at two assertions (DU's own state shape, then
      # the DZ/DU string inequality) and the mutant trips whichever comes first; pinning the
      # predicate to only the second would report a working sensitivity arm as broken.
      if /usr/bin/grep -qE 'denominator-integrity\(DU\)|IDENTICAL state' "$MUT_DEN_OUT"; then
        ok "D2b sensitivity — collapsed-denominator mutant fails on the DU arm, which is where a true zero and an unmeasurable denominator become indistinguishable: $(/usr/bin/tail -1 "$MUT_DEN_OUT" | /usr/bin/sed 's/^ERROR: self-test: //')"
      else
        bad "D2b sensitivity — mutant failed, but not on the denominator-integrity arms: $(/usr/bin/tail -1 "$MUT_DEN_OUT")"
      fi
    fi
    ;;
  *)
    bad "D2a mutation-extraction control — $MUT_DEN_RESULT (instrument broken; no sensitivity verdict is reportable)"
    ;;
esac

echo
echo "----------------------------------------------------------------------"
printf 'PASS %d   FAIL %d\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Failures:"
  for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
exit 0
