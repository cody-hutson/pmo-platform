#!/usr/bin/env bash
set -uo pipefail
# test_plan_status_terminal_transition.sh — regression suite for the release-plan
# `status:` lifecycle: the close-out transition (automated-closeout.sh Phase 6.9)
# and the two lint limbs that police it (lint_release_corpus.py E1/E2).
#
# WHY THIS EXISTS
#   Before this suite the transition had never fired, not once, for any release:
#   every plan carrying the field read ACTIVE, including 19 whose ledger row read
#   VERIFIED. The defect was not a drift FROM a correct state — no plan had ever
#   reached one. That history is the reason a green run over the LIVE corpus is
#   worthless as evidence here: after the sweep that ships with this suite, the
#   live population contains ZERO non-terminal shipped plans, so a check that
#   asserted nothing at all would look exactly as green as a correct one.
#
#   Every arm below therefore SEEDS the positive it asserts on. This is the
#   seeded-fixture requirement the originating card states in its own words: "a
#   green run over the current population proves nothing — there are zero
#   positives in it."
#
# WHAT THIS SUITE GRADES — and what it deliberately does NOT
#   It does not restate the linter's own --self-test arms. It grades whether the
#   shipped behaviour DISCRIMINATES, by mutating the shipped implementation and
#   requiring the arm to go red. Every mutation is guarded by an EXTRACTION
#   CONTROL: the anchor must be found before the mutant is trusted, because a
#   mutation that silently no-ops produces a "sensitivity arm failed to fail"
#   verdict that is really a broken instrument.
#
# GROUPS
#   (A) THE WRITE PRIMITIVE — plan_status_rw(), extracted verbatim from the
#       shipped close-out script and driven directly. Fence-bounded, comment-
#       tolerant, idempotent, write-then-re-read, and refusing any value the
#       enum does not define. Includes the body-row preservation arm: 22 plans
#       in scope carry a body `| **Status** |` row, so an unbounded rewrite
#       would corrupt narrative content that exists nowhere else.
#   (B) THE LINT LIMBS — E1 (enum membership) and E2 (terminal coherence) over a
#       seeded four-case corpus, plus the mutation arm that proves the comment-
#       tolerant reader is ENFORCED rather than merely documented.
#   (C) THE ORDERING INVARIANT — read from the shipped driver's own text. Phase
#       6.9 must sit after 6.8 and BEFORE 9.3; that ordering is what makes 9.3 a
#       completeness backstop against a silent no-op, and reversing it forfeits
#       the interlock.
#
# Offline + deterministic: no network, no gh, no writes to any operator-instance
# path, no writes into the repo. All fixtures live under one mktemp dir.
#
# Run:  bash release/tools/tests/test_plan_status_terminal_transition.sh
# Exit: 0 = all assertions pass, 1 = one or more failed.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CLOSEOUT="${REPO_ROOT}/release/tools/automated-closeout.sh"
LINT="${REPO_ROOT}/core/deploy/tools/lint_release_corpus.py"

PASS=0
FAIL=0

arm() {
  local name="$1" ok="$2" detail="$3"
  if [[ "$ok" == "1" ]]; then
    PASS=$((PASS + 1))
    printf '  [PASS] %s: %s\n' "$name" "$detail"
  else
    FAIL=$((FAIL + 1))
    printf '  [FAIL] %s: %s\n' "$name" "$detail"
  fi
}

echo "test_plan_status_terminal_transition.sh — plan-status lifecycle"

# ── Preconditions ────────────────────────────────────────────────────────────
[[ -f "$CLOSEOUT" ]] || { echo "FATAL: $CLOSEOUT missing"; exit 1; }
[[ -f "$LINT" ]] || { echo "FATAL: $LINT missing"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# GROUP A — the write primitive
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "GROUP A — plan_status_rw() (automated-closeout.sh Phase 6.9 write primitive)"

# EXTRACTION CONTROL. The function is lifted verbatim from the shipped script so
# the suite grades what actually ships, never a restatement of it. If the
# extraction comes back empty the mutation arms below are meaningless, so the
# suite refuses to report any verdict rather than emitting a vacuous green.
FN_SRC="$(/usr/bin/sed -n '/^plan_status_rw() {/,/^}/p' "$CLOSEOUT")"
FN_DEFS="$(/usr/bin/grep -c '^plan_status_rw() {' "$CLOSEOUT")"
if [[ -z "$FN_SRC" || "$FN_DEFS" != "1" ]]; then
  echo "  [FAIL] A-0 extraction control: expected exactly 1 plan_status_rw definition, found ${FN_DEFS}"
  exit 1
fi
arm "A-0 extraction control — the primitive under test was really lifted from the shipped script" \
  "$([[ -n "$FN_SRC" && "$FN_DEFS" == "1" ]] && echo 1 || echo 0)" \
  "exactly one definition found and captured ($(printf '%s' "$FN_SRC" | /usr/bin/wc -l | tr -d ' ') lines)"
eval "$FN_SRC"

mkplan() {
  # $1=path  $2=status-line-or-empty  $3=lead-bytes-above-the-fence
  local p="$1" st="$2" lead="$3"
  mkdir -p "$(dirname "$p")"
  {
    [[ -n "$lead" ]] && printf '%s\n' "$lead"
    printf -- '---\n'
    printf 'type: plan\n'
    printf 'milestone: fixture\n'
    [[ -n "$st" ]] && printf 'status: %s\n' "$st"
    printf -- '---\n'
    printf '\n# Fixture plan\n\n'
    printf '| Field | Value |\n|---|---|\n'
    printf '| **Status** | Executing (Stage 6 Engineering) |\n'
    printf '\nStatus: operator-APPROVED — a body prose line, not the field\n'
  } > "$p"
}

# A-1 read on a plain plan
mkplan "$TMP/a1.md" "ACTIVE" ""
got="$(plan_status_rw "$TMP/a1.md" read)"
arm "A-1 read — the frontmatter value is returned, not a body line" \
  "$([[ "$got" == "ACTIVE" ]] && echo 1 || echo 0)" \
  "got '${got}' (the file also carries a body **Status** row and a body 'Status:' prose line)"

# A-2 the comment-tolerant read — the OSD-4 shape
mkplan "$TMP/a2.md" "ACTIVE" "<!-- reference-durability: allow-link -->"
got="$(plan_status_rw "$TMP/a2.md" read)"
arm "A-2 comment-tolerant read — frontmatter BELOW a marker comment is still seen" \
  "$([[ "$got" == "ACTIVE" ]] && echo 1 || echo 0)" \
  "got '${got}'; a reader keying on 'the file opens with ---' returns empty here and reports a clean no-op"

# A-3 apply transitions and re-reads from disk
mkplan "$TMP/a3.md" "ACTIVE" ""
got="$(plan_status_rw "$TMP/a3.md" apply)"; rc=$?
disk="$(/usr/bin/grep -c '^status: CLOSED$' "$TMP/a3.md")"
arm "A-3 apply — transitions ACTIVE → CLOSED and verifies by re-reading the file" \
  "$([[ $rc -eq 0 && "$got" == "CLOSED" && "$disk" == "1" ]] && echo 1 || echo 0)" \
  "exit=${rc} returned='${got}' on-disk status: CLOSED lines=${disk}"

# A-4 body content is untouched — the fence bound
body_status="$(/usr/bin/grep -c '| \*\*Status\*\* | Executing (Stage 6 Engineering) |' "$TMP/a3.md")"
body_prose="$(/usr/bin/grep -c '^Status: operator-APPROVED' "$TMP/a3.md")"
arm "A-4 fence bound — the body **Status** row and the body 'Status:' prose line survive the write" \
  "$([[ "$body_status" == "1" && "$body_prose" == "1" ]] && echo 1 || echo 0)" \
  "body row present=${body_status}, body prose line present=${body_prose} — an unbounded rewrite scores 0 on one or both"

# A-5 idempotency
got="$(plan_status_rw "$TMP/a3.md" read)"
arm "A-5 idempotency — a re-run reads CLOSED, which the phase maps to SKIPPED" \
  "$([[ "$got" == "CLOSED" ]] && echo 1 || echo 0)" \
  "second read returns '${got}'; the phase's case arm short-circuits rather than rewriting"

# A-6 apply refuses a non-ACTIVE value
mkplan "$TMP/a6.md" "ABANDONED" ""
plan_status_rw "$TMP/a6.md" apply >/dev/null 2>&1; rc=$?
still="$(/usr/bin/grep -c '^status: ABANDONED$' "$TMP/a6.md")"
arm "A-6 refusal — apply will not overwrite a value that is not ACTIVE" \
  "$([[ $rc -ne 0 && "$still" == "1" ]] && echo 1 || echo 0)" \
  "exit=${rc} (non-zero) and the ABANDONED value is intact (${still}) — the phase FAILs rather than resolving a contradiction silently"

# A-7 a plan with no status: field
mkplan "$TMP/a7.md" "" ""
got="$(plan_status_rw "$TMP/a7.md" read)"
arm "A-7 forward-only — a plan carrying no status: reads empty, which the phase maps to SKIPPED" \
  "$([[ -z "$got" ]] && echo 1 || echo 0)" \
  "read returned '${got:-<empty>}'; this is what keeps the historical corpus exempt rather than failing"

# A-8 MUTATION — a strict reader must break A-2 while leaving A-1 alive.
#
# WHICH LINE THE MUTATION TARGETS, and why it is not the fence check. The
# comment tolerance lives in ONE limb: the skip loop's `if s == "" or (...)`
# guard. Neutering that guard yields a reader that requires the file to OPEN
# with `---` — comment-intolerant, and correct on every other shape. Mutating
# the fence check instead (`if i >= len(ls) or ...` -> `if True:`) blinds the
# reader on EVERY shape, so the arm below would go green for a reader that is
# merely broken rather than one that is comment-intolerant. A mutation that is
# not reader-SPECIFIC cannot evidence a reader-specific claim.
#
# WHY THE ANCHOR CARRIES NO GLOB METACHARACTERS. `${v//pat/rep}` glob-matches
# its pattern; it does not substring-match it. A pattern containing `ls[i]`
# therefore matches the literal three characters `lsi` and silently no-ops. The
# guard line above is free of `* ? [ ]`, so it cannot fail that way.
MUT_SRC="${FN_SRC//if s == \"\" or (s.startswith(\"<!--\") and s.endswith(\"-->\")):/if False:}"
if [[ "$MUT_SRC" == "$FN_SRC" ]]; then
  arm "A-8 mutation extraction control" "0" \
    "the comment-skip anchor was not found in the extracted source — the mutation would no-op and the arm below would be meaningless"
else
  mkplan "$TMP/a8_plain.md" "ACTIVE" ""
  mkplan "$TMP/a8_marker.md" "ACTIVE" "<!-- reference-durability: allow-link -->"
  # The mutant is defined and driven inside ONE subshell so it cannot leak into
  # the suite's shell, and both reads are taken from the SAME mutant.
  mut_reads="$(eval "${MUT_SRC/plan_status_rw() {/plan_status_rw_mut() {}" 2>/dev/null
               printf '%s|%s' "$(plan_status_rw_mut "$TMP/a8_plain.md" read 2>/dev/null)" \
                              "$(plan_status_rw_mut "$TMP/a8_marker.md" read 2>/dev/null)")"
  mut_plain="${mut_reads%%|*}"
  mut_marker="${mut_reads##*|}"
  # The plain-file read is the INSTRUMENT CONTROL, and it is why this arm cannot
  # pass vacuously. An empty marker read is ambiguous on its own: it is equally
  # the signature of a mutant that went blind and of a mutant that never ran at
  # all (a substitution that produced unparseable source evals to nothing, and
  # the missing function then returns empty for every input). Requiring ACTIVE
  # on the plain file separates those two: only a live, correctly-defined mutant
  # can produce it.
  arm "A-8 sensitivity — a reader that cannot see past a marker comment goes BLIND on the OSD-4 shape" \
    "$([[ -z "$mut_marker" && "$mut_plain" == "ACTIVE" ]] && echo 1 || echo 0)" \
    "the mutant returns '${mut_marker:-<empty>}' on the marker shape where the shipped primitive returns ACTIVE, while still reading '${mut_plain:-<empty>}' on a plain plan — the blindness is comment-SPECIFIC, and the live plain read proves the mutant really ran"
fi

# ─────────────────────────────────────────────────────────────────────────────
# GROUP B — the lint limbs, over a seeded corpus
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "GROUP B — lint_release_corpus.py E1/E2 over a SEEDED four-case corpus"

B_OUT="$TMP/group_b.txt"
/usr/bin/python3 - "$LINT" > "$B_OUT" 2>&1 <<'PY'
"""Drive check_plan_identity() against a seeded corpus, and against a mutant.

The four cases the originating card names, each SEEDED because the live corpus
carries zero positives after the sweep:
    closed  : status CLOSED  + a VERIFIED ledger row   -> no finding
    active  : status ACTIVE  + a VERIFIED ledger row   -> PLAN-STATUS-NOT-TERMINAL
    flight  : status ACTIVE  + a DEPLOYED ledger row   -> no finding (in-flight)
    bogus   : status SHIPPED + a VERIFIED ledger row   -> PLAN-STATUS-ENUM
plus a fifth, the marker-comment shape, which must behave identically to `active`.
"""
import importlib.util
import sys
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("lrc", sys.argv[1])
L = importlib.util.module_from_spec(spec)
spec.loader.exec_module(L)


def blocking(f):
    return [x for x in f if not x.startswith(L.ADVISORY_PREFIX)]


def fires(f, prefix, needle):
    return sum(1 for x in blocking(f) if x.startswith(prefix) and needle in x)


def build(root):
    plans = root / "plans"
    log = L._write_ledger(root / "RELEASE_LOG.md", [
        ("v9.60", "fx-closed", "VERIFIED"),
        ("v9.61", "fx-active", "VERIFIED"),
        ("v9.62", "fx-flight", "DEPLOYED"),
        ("v9.63", "fx-bogus", "VERIFIED"),
        ("v9.64", "fx-marker", "VERIFIED"),
    ])
    p = {
        "closed": L._write_status_plan(plans, "v9/v9.60-fx-closed_RELEASE_PLAN.md", "fx-closed", "CLOSED"),
        "active": L._write_status_plan(plans, "v9/v9.61-fx-active_RELEASE_PLAN.md", "fx-active", "ACTIVE"),
        "flight": L._write_status_plan(plans, "v9/v9.62-fx-flight_RELEASE_PLAN.md", "fx-flight", "ACTIVE"),
        "bogus": L._write_status_plan(plans, "v9/v9.63-fx-bogus_RELEASE_PLAN.md", "fx-bogus", "SHIPPED"),
        "marker": L._write_status_plan(plans, "v9/v9.64-fx-marker_RELEASE_PLAN.md", "fx-marker", "ACTIVE",
                                       lead="<!-- reference-durability: allow-link -->\n"),
    }
    return plans, log, p


def measure(patch=None):
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        plans, log, p = build(root)
        undo = patch() if patch else (lambda: None)
        try:
            f = L.check_plan_identity(plans_dir=plans, log_path=log,
                                      reversions_path=root / "none.md")
            return {
                "closed": fires(f, "PLAN-STATUS-NOT-TERMINAL", L._rel(p["closed"])),
                "active": fires(f, "PLAN-STATUS-NOT-TERMINAL", L._rel(p["active"])),
                "flight": fires(f, "PLAN-STATUS-NOT-TERMINAL", L._rel(p["flight"])),
                "bogus": fires(f, "PLAN-STATUS-ENUM", L._rel(p["bogus"])),
                "marker": fires(f, "PLAN-STATUS-NOT-TERMINAL", L._rel(p["marker"])),
                "denom": next((x for x in f if "PLAN-STATUS-DENOM" in x), ""),
            }
        finally:
            undo()


base = measure()


def strict_reader():
    orig = L._fm_for_identity
    L._fm_for_identity = lambda t: (L.parse_frontmatter(t) or {})
    return lambda: setattr(L, "_fm_for_identity", orig)


mut = measure(strict_reader)

print(f"B-1|{1 if base['active'] == 1 else 0}|a VERIFIED release whose plan still reads ACTIVE blocks (fired {base['active']}x)")
print(f"B-2|{1 if base['closed'] == 0 else 0}|a VERIFIED release whose plan reads CLOSED fires nothing (fired {base['closed']}x)")
print(f"B-3|{1 if base['flight'] == 0 else 0}|an IN-FLIGHT (DEPLOYED) release's plan may still read ACTIVE (fired {base['flight']}x)")
print(f"B-4|{1 if base['bogus'] == 1 else 0}|a status: outside the enum blocks rather than passing silently (fired {base['bogus']}x)")
print(f"B-5|{1 if base['marker'] == 1 else 0}|the same defect below a marker comment blocks identically (fired {base['marker']}x)")
print(f"B-6|{1 if '5 of 5 plan file(s) carry a frontmatter status:' in base['denom'] else 0}|the DENOM line reports the partition the fixture produced: {base['denom'][:120]}")
ok = mut["marker"] == 0 and mut["active"] == 1
print(f"B-7|{1 if ok else 0}|MUTATION: a strict reader scores {mut['marker']} on the marker file (shipped: {base['marker']}) while the plain file stays at {mut['active']} — the arm is reader-specific, not a coincidence")
PY

if [[ ! -s "$B_OUT" ]]; then
  echo "  [FAIL] B-0 driver control: the lint driver produced no output"
  FAIL=$((FAIL + 1))
else
  while IFS='|' read -r name ok detail; do
    [[ -z "${name:-}" ]] && continue
    case "$name" in
      B-*) arm "$name" "$ok" "$detail" ;;
      *) echo "  [driver] $name${ok:+|$ok}${detail:+|$detail}" ;;
    esac
  done < "$B_OUT"
fi

# B-C0 COMPLETION CONTROL — an instrument must prove it ran.
# The emptiness test above fires only on NO output. A driver that crashes part-way
# writes a traceback, which is non-empty, so the guard passes; no traceback line
# matches the B-* prefix, every line falls to the [driver] echo branch, and that
# branch increments neither counter. The group then contributes zero arms and zero
# failures, which the exit gate accepts. Assert the terminal arm reported instead:
# it is reached only if the driver ran to the end, and unlike a hardcoded total it
# does not go stale when an arm is added.
if ! grep -q '^B-7|' "$B_OUT"; then
  echo "  [FAIL] B-C0 completion control: group B's terminal arm (B-7) is absent — the driver did not run to completion"
  FAIL=$((FAIL + 1))
fi

# ─────────────────────────────────────────────────────────────────────────────
# GROUP C — the ordering invariant
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "GROUP C — Phase 6.9 sits after 6.8 and BEFORE 9.3 (read from the shipped driver)"

C_OUT="$TMP/group_c.txt"
/usr/bin/python3 - "$CLOSEOUT" > "$C_OUT" 2>&1 <<'PY'
import sys

lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
seq = [l.split()[0] for l in lines
       if l.startswith("phase_") and "|| { generate_report" in l]
need = ["phase_inject_close_class_telemetry_field",
        "phase_transition_plan_status",
        "phase_lint_plan_identity",
        "phase_commit_chore_pr"]
missing = [n for n in need if n not in seq]
if missing:
    print(f"C-0|0|driver control: phase(s) absent from the call sequence: {missing}")
    raise SystemExit(0)
print(f"C-0|1|driver control: all 4 anchor phases found in a {len(seq)}-phase call sequence")
i68, i69 = seq.index(need[0]), seq.index(need[1])
i93, i10 = seq.index(need[2]), seq.index(need[3])
print(f"C-1|{1 if i68 < i69 else 0}|Phase 6.9 runs AFTER the 6.5-6.8 Deployment-Log cluster (6.8@{i68} < 6.9@{i69})")
print(f"C-2|{1 if i69 < i93 else 0}|Phase 6.9 runs BEFORE Phase 9.3 (6.9@{i69} < 9.3@{i93}) — this is what makes 9.3 the completeness backstop; reversing it forfeits the interlock")
print(f"C-3|{1 if i69 == i68 + 1 else 0}|Phase 6.9 is IMMEDIATELY after 6.8, no phase interposed (6.8@{i68}, 6.9@{i69})")
print(f"C-4|{1 if i93 < i10 else 0}|specificity control (must hold independently): 9.3 still precedes the chore commit (9.3@{i93} < commit@{i10}), so a 9.3 FAIL halts before anything is committed")
print(f"C-5|{1 if not (i93 < i69) else 0}|the inverse of C-2 does NOT hold — the control arm that would fire on a reordered driver")
hdr = [l for l in lines if l.startswith("#   6.9 ")]
print(f"C-6|{1 if len(hdr) == 1 else 0}|the phase-list header comment carries its 6.9 line too ({len(hdr)} found) — the enumeration appears twice and both must agree")
PY

while IFS='|' read -r name ok detail; do
  [[ -z "${name:-}" ]] && continue
  case "$name" in
    C-*) arm "$name" "$ok" "$detail" ;;
    *) echo "  [driver] $name${ok:+|$ok}${detail:+|$detail}" ;;
  esac
done < "$C_OUT"

# C-C0 COMPLETION CONTROL — group C carried no guard at all, so a crashed driver
# scored zero arms and zero failures silently. C-0 has a legitimate early exit
# (anchor phases absent), which reports C-0 with a 0 and is a real failure rather
# than a broken run — so the control must distinguish the two, or it would double-
# report every genuine C-0 failure as a crash.
if [[ ! -s "$C_OUT" ]]; then
  echo "  [FAIL] C-C0 driver control: the close-out driver produced no output"
  FAIL=$((FAIL + 1))
elif ! grep -q '^C-6|' "$C_OUT" && ! grep -q '^C-0|0|' "$C_OUT"; then
  echo "  [FAIL] C-C0 completion control: group C's terminal arm (C-6) is absent and C-0 reported no controlled early exit — the driver did not run to completion"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "${PASS} passed, ${FAIL} failed"
# The tally alone cannot gate: a run in which every group driver crashed reports
# "0 passed, 0 failed" and satisfies FAIL -eq 0. The per-group completion controls
# above are what make this gate mean something.
[[ $FAIL -eq 0 ]] || exit 1
exit 0
