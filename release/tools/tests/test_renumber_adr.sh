#!/bin/bash
# test_renumber_adr.sh — two-branch behavioural fixture for renumber-adr.py.
#
# WHY A REAL GIT TOPOLOGY AND NOT A PURE-FUNCTION TEST
# ----------------------------------------------------
# The defect this tool exists to fix is a RACE, and the root cause is that every
# claimant is individually correct: `check-adr-numbers.py` globs one tree, so two
# branches that both derive the same next-free number both get a confident PASS.
# T0 asserts that root cause DIRECTLY — both trees pass locally before the race
# resolves — because an AC that says "two branches can author concurrently and
# both merge" cannot be graded by a function test. Precedent for owning a real
# git fixture rather than borrowing the ambient checkout:
# core/hooks/tests/block-draft-files.test.sh.
#
# TOPOLOGY (hermetic: $(mktemp -d); no network, no gh, no credentials)
#   origin/   bare repo                  — the arbiter (stands in for the host)
#   wt-A/     clone, branch feat/a        — first to merge; keeps its number
#   wt-B/     clone, branch feat/b        — later claimant; takes the tooled path
#
# The tools under test are COPIED FROM THE TREE UNDER TEST, never re-implemented,
# so a regression in the real file fails this suite.
#
# Assertions A1-A10 map to the card's acceptance criteria. A7 is the negative
# control: a fixture whose failure arm is untested is a broken probe, so A7
# re-runs the same scenario with a bare `git mv` and asserts that A2 and A4 then
# FAIL. Without it, A2/A4 passing would be evidence of nothing.

set -u

REPO_UNDER_TEST="$(cd "$(dirname "$0")/../../.." && pwd -P)"
TOOLS="${REPO_UNDER_TEST}/release/tools"

for t in check-adr-numbers.py renumber-adr.py; do
  [ -f "${TOOLS}/${t}" ] || { echo "FATAL: ${TOOLS}/${t} missing — the suite cannot test a tool that is not there" >&2; exit 1; }
done

PASS=0; FAIL=0
ok()   { printf 'PASS: %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf 'FAIL: %s\n  %s\n' "$1" "${2:-}"; FAIL=$((FAIL+1)); }
assert_eq()   { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]"; fi; }
assert_file() { if [ -f "$2" ]; then ok "$1"; else bad "$1" "missing file $2"; fi; }
assert_nofile(){ if [ ! -e "$2" ]; then ok "$1"; else bad "$1" "file should be gone: $2"; fi; }

ROOT="$(mktemp -d)"; ROOT="$(cd "$ROOT" && pwd -P)"
trap 'rm -rf "$ROOT"' EXIT
G() { git -c user.email=fixture@example.invalid -c user.name=fixture -c commit.gpgsign=false "$@"; }

# ---------------------------------------------------------------- seed origin
seed_origin() {
  local o="$ROOT/$1"
  mkdir -p "$o" && ( cd "$o" && G -c init.defaultBranch=main init -q --bare )
  local s="$ROOT/seed-$1"
  mkdir -p "$s/core/ADRs" "$s/release/ADRs" "$s/release/tools"
  ( cd "$s" && G -c init.defaultBranch=main init -q )
  cp "${TOOLS}/check-adr-numbers.py" "${TOOLS}/renumber-adr.py" "$s/release/tools/"
  for n in 001 002 003; do
    printf '# fixture ADR-%s\n\n## Status\n\nAccepted.\n\n## Context\n\nseed.\n' "$n" \
      > "$s/core/ADRs/ADR-$n-seed$n.md"
  done
  # core README — carries the § Renumber log surface the tool appends to.
  cat > "$s/core/ADRs/README.md" <<'EOF'
# Core ADRs

## Naming convention

**Renumber log.** Seed entry: no renumbers yet.

## Cross-numbering

| ADR | Module | Status |
|---|---|---|
| ADR-001 | core | seeded |
| ADR-002 | core | seeded |
| ADR-003 | core | seeded |
EOF
  # release README — carries ALL THREE index surfaces in one file, the shape
  # `409545d4`'s own commit message proved a renumber has to touch.
  cat > "$s/release/ADRs/README.md" <<'EOF'
# Release ADRs

## Naming convention

`ADR-NNN-kebab-case-title.md`. This module holds ADR-002, ADR-001.

## Release-scoped ADRs

| ADR | Title | Status |
|---|---|---|
| [ADR-002](ADR-002-seed002.md) | Seed two | Accepted |

## Cross-numbering with core/ADRs/

| ADR | Module | Status |
|---|---|---|
| ADR-001 | core | seeded |
| ADR-002 | core | seeded |
EOF
  ( cd "$s" && G add -A >/dev/null && G commit -qm "seed" && \
    G remote add origin "$o" && G push -q origin main )
  rm -rf "$s"
}

# --------------------------------------------- author the later claimant (B)
# $1 origin name, $2 worktree name, $3 the number B claims
author_B() {
  local o="$ROOT/$1" w="$ROOT/$2" n="$3"
  G clone -q "$o" "$w"
  ( cd "$w" && G checkout -q -b feat/b
    # A realistically-sized body. A 7-line stub would drop below git's 50%
    # rename-similarity threshold once R5 adds the provenance note, so A1 would
    # measure the fixture's artificiality rather than the tool's behaviour.
    { printf '# ADR-%03d — bravo\n\n## Status\n\nProposed.\n\n## Context\n\n' "$n"
      for i in 1 2 3 4 5 6 7 8 9 10; do
        printf 'Context paragraph %d for the bravo record, carrying enough prose that a rename stays detectable.\n\n' "$i"
      done
      printf '## Decision\n\nBravo decides.\n\n## Consequences\n\nBravo consequences.\n'
    } > "release/ADRs/ADR-$(printf '%03d' "$n")-bravo.md"
    # 4 citations across 2 files — the branch's own citation set.
    printf 'Design cites ADR-%03d twice: ADR-%03d.\n' "$n" "$n" > design-note.md
    printf 'Plan cites ADR-%03d and again ADR-%03d.\n' "$n" "$n" > plan-note.md
    # B registers itself in all three release-index surfaces (branch-diff scope).
    sed -i.bak "s|This module holds ADR-002, ADR-001.|This module holds ADR-002, ADR-001, ADR-$(printf '%03d' "$n").|" release/ADRs/README.md
    printf '| [ADR-%03d](ADR-%03d-bravo.md) | Bravo | Proposed |\n' "$n" "$n" > /tmp/.row.$$
    awk -v row="$(cat /tmp/.row.$$)" '
      /^\| \[ADR-002\]\(ADR-002-seed002\.md\)/ { print; print row; next } { print }' \
      release/ADRs/README.md > release/ADRs/README.new && mv release/ADRs/README.new release/ADRs/README.md
    awk -v n="$(printf '%03d' "$n")" '
      /^\| ADR-002 \| core \| seeded \|$/ && !d { print; print "| ADR-" n " | release | authored |"; d=1; next } { print }' \
      release/ADRs/README.md > release/ADRs/README.new && mv release/ADRs/README.new release/ADRs/README.md
    rm -f release/ADRs/README.md.bak /tmp/.row.$$
    G add -A >/dev/null && G commit -qm "author ADR-$(printf '%03d' "$n") bravo" )
}

cite_count() { grep -o "ADR-$(printf '%03d' "$2")" "$1" 2>/dev/null | wc -l | tr -d ' '; }

echo "=== ACT 1 — the race (both claimants correct) ==="
seed_origin origin1
G clone -q "$ROOT/origin1" "$ROOT/wt-A"
( cd "$ROOT/wt-A" && G checkout -q -b feat/a
  printf '# ADR-004 — alpha\n\n## Status\n\nProposed.\n\n## Context\n\nAlpha.\n' \
    > core/ADRs/ADR-004-alpha.md
  G add -A >/dev/null && G commit -qm "author ADR-004 alpha" )
author_B origin1 wt-B 4

A_OUT="$(cd "$ROOT/wt-A" && python3 release/tools/check-adr-numbers.py 2>&1)"; A_RC=$?
B_OUT="$(cd "$ROOT/wt-B" && python3 release/tools/check-adr-numbers.py 2>&1)"; B_RC=$?
if [ "$A_RC" = 0 ] && [ "$B_RC" = 0 ]; then
  ok "T0 ROOT CAUSE — both claimants PASS check-adr-numbers.py locally before the race resolves"
else
  bad "T0 ROOT CAUSE" "A_rc=$A_RC B_rc=$B_RC — the fixture failed to reproduce the race"
fi

echo "=== ACT 2 — first merge (A takes 004) ==="
( cd "$ROOT/wt-A" && G push -q origin feat/a && G checkout -q main && \
  G merge -q --no-edit feat/a && G push -q origin main )
( cd "$ROOT/wt-A" && python3 release/tools/check-adr-numbers.py >/dev/null 2>&1 )
assert_eq "ACT2 origin main contiguous 001..004 after A merges" "$?" "0"

echo "=== ACT 3 — the later claimant takes the tooled path ==="
cd "$ROOT/wt-B" && G fetch -q origin
DET="$(python3 release/tools/renumber-adr.py --detect 2>&1)"
echo "$DET" | grep -q "DUPLICATE" && ok "--detect reports DUPLICATE at 004" \
  || bad "--detect reports DUPLICATE at 004" "$DET"
echo "$DET" | grep -q "next=5" && ok "--detect computes next-free 005" \
  || bad "--detect computes next-free 005" "$DET"

APPLY="$(python3 release/tools/renumber-adr.py --renumber 4 5 --apply 2>&1)"; AP_RC=$?
assert_eq "--renumber 4 5 --apply exits 0" "$AP_RC" "0"

# --- A1 rename ---------------------------------------------------------------
assert_file  "A1 ADR-005-bravo.md exists"       "release/ADRs/ADR-005-bravo.md"
assert_nofile "A1 ADR-004-bravo.md is gone"     "release/ADRs/ADR-004-bravo.md"
assert_eq "A1 git records a rename (R)" \
  "$(G diff --cached --name-status -M | grep -c '^R.*ADR-004-bravo.md')" "1"

# --- A2 zero dangling --------------------------------------------------------
assert_eq "A2 design-note.md: 0 stale ADR-004"  "$(cite_count design-note.md 4)" "0"
assert_eq "A2 design-note.md: 2 rewritten ADR-005" "$(cite_count design-note.md 5)" "2"
assert_eq "A2 plan-note.md:   0 stale ADR-004"  "$(cite_count plan-note.md 4)" "0"
assert_eq "A2 plan-note.md:   2 rewritten ADR-005" "$(cite_count plan-note.md 5)" "2"
# The surviving ADR-004 in the tree must be A's record, in a mainline-unchanged file.
SURV="$(grep -rl 'ADR-004' --include='*.md' . 2>/dev/null | grep -v '^./release/ADRs/ADR-005' | sort)"
assert_eq "A2 no in-scope file still cites ADR-004" \
  "$(echo "$SURV" | grep -c -E 'design-note|plan-note|release/ADRs/README')" "0"

# --- A3 index surfaces + re-sort ---------------------------------------------
assert_eq "A3 naming-convention prose list carries ADR-005" \
  "$(grep -c 'This module holds .*ADR-005' release/ADRs/README.md)" "1"
assert_eq "A3 prose list re-sorted ascending" \
  "$(grep -c 'holds ADR-001, ADR-002, ADR-005' release/ADRs/README.md)" "1"
assert_eq "A3 file-linked table row rewritten (text + href)" \
  "$(grep -c '\[ADR-005\](ADR-005-bravo.md)' release/ADRs/README.md)" "1"
assert_eq "A3 cross-numbering table row rewritten" \
  "$(grep -cE '^\| ADR-005 \| release \|' release/ADRs/README.md)" "1"
assert_eq "A3 § Renumber log appended" \
  "$(grep -c 'ADR-004 (`bravo`) → \*\*ADR-005\*\*' core/ADRs/README.md)" "1"

# --- A4 provenance note (THE OBSERVED DEFECT) --------------------------------
assert_eq "A4 ## Status carries the canonical provenance note" \
  "$(grep -cE '\*\*Numbering provenance — `004 → 005`\.\*\*' release/ADRs/ADR-005-bravo.md)" "1"
assert_eq "A4 note carries the mandatory 'at merge time' historical anchor" \
  "$(grep -c 'at merge time' release/ADRs/ADR-005-bravo.md)" "1"

# --- A5 both merge; contiguous, no duplicate (AC-1 + AC-2) -------------------
G commit -qm "renumber ADR-004 -> ADR-005" >/dev/null
G push -q origin feat/b
( cd "$ROOT/wt-A" && G fetch -q origin && G merge -q --no-edit origin/feat/b && G push -q origin main )
A5_OUT="$(cd "$ROOT/wt-A" && python3 release/tools/check-adr-numbers.py 2>&1)"; A5_RC=$?
assert_eq "A5 after BOTH merges check-adr-numbers exits 0" "$A5_RC" "0"
echo "$A5_OUT" | grep -q 'contiguous 001..005' \
  && ok "A5 mainline contiguous 001..005, no duplicate" \
  || bad "A5 mainline contiguous 001..005, no duplicate" "$A5_OUT"

# --- A6 durability lint raises no new finding --------------------------------
D_OUT="$(python3 "${TOOLS}/check-adr-durability.py" --root "$ROOT/wt-B" \
          --files "$ROOT/wt-B/release/ADRs/ADR-005-bravo.md" 2>&1)"
D_COUNT="$(echo "$D_OUT" | awk '/^COUNT/{print $2}')"
assert_eq "A6 durability lint COUNT 0 on the renumbered record" "${D_COUNT:-unset}" "0"

# --- A8 idempotence ----------------------------------------------------------
IDEM="$(python3 release/tools/renumber-adr.py --renumber 4 5 --apply 2>&1)"; ID_RC=$?
assert_eq "A8 re-running the completed move exits 0 (idempotent)" "$ID_RC" "0"
assert_eq "A8 zero diff after the idempotent re-run" \
  "$(G status --porcelain | wc -l | tr -d ' ')" "0"
echo "$IDEM" | grep -q "COMPLETION MODE" \
  && ok "A8 the re-run enters completion mode rather than refusing" \
  || bad "A8 the re-run enters completion mode rather than refusing" "$IDEM"

# --- A9 refusal, zero mutation ----------------------------------------------
BEFORE="$(G rev-parse HEAD):$(G status --porcelain | wc -l | tr -d ' ')"
python3 release/tools/renumber-adr.py --renumber 5 7 --apply >/dev/null 2>&1
assert_eq "A9 --renumber 5 7 (would gap) exits non-zero" "$?" "2"
python3 release/tools/renumber-adr.py --renumber 5 3 --apply >/dev/null 2>&1
assert_eq "A9 --renumber 5 3 (occupied) exits non-zero" "$?" "2"
assert_eq "A9 zero mutation after both refusals" \
  "$(G rev-parse HEAD):$(G status --porcelain | wc -l | tr -d ' ')" "$BEFORE"

echo "=== A7 — NEGATIVE CONTROL (bare git mv must fail A2 and A4) ==="
seed_origin origin7
G clone -q "$ROOT/origin7" "$ROOT/wt-A7"
( cd "$ROOT/wt-A7" && G checkout -q -b feat/a
  printf '# ADR-004 — alpha\n\n## Status\n\nProposed.\n' > core/ADRs/ADR-004-alpha.md
  G add -A >/dev/null && G commit -qm a && G push -q origin feat/a && \
  G checkout -q main && G merge -q --no-edit feat/a && G push -q origin main )
author_B origin7 wt-B7 4
( cd "$ROOT/wt-B7" && G fetch -q origin && \
  G mv release/ADRs/ADR-004-bravo.md release/ADRs/ADR-005-bravo.md )
A7_DANGLING="$(cd "$ROOT/wt-B7" && cite_count design-note.md 4)"
A7_NOTE="$(cd "$ROOT/wt-B7" && grep -cE '\*\*Numbering provenance' release/ADRs/ADR-005-bravo.md)"
if [ "$A7_DANGLING" != "0" ]; then
  ok "A7 negative control — bare git mv FAILS A2 ($A7_DANGLING dangling ADR-004 citations remain)"
else
  bad "A7 negative control — bare git mv FAILS A2" "expected dangling citations, found none: A2 is not measuring anything"
fi
if [ "$A7_NOTE" = "0" ]; then
  ok "A7 negative control — bare git mv FAILS A4 (no provenance note)"
else
  bad "A7 negative control — bare git mv FAILS A4" "unexpected provenance note on a hand-moved record"
fi

# A7b runs only AFTER A7's failure arms are recorded, so the control keeps its
# meaning. This is the ADR-088 shape: a hand-performed renumber that landed the
# rename and skipped the note. Completion mode repairs it rather than refusing.
( cd "$ROOT/wt-B7" && G add -A >/dev/null && G commit -qm "hand renumber" >/dev/null
  python3 release/tools/renumber-adr.py --renumber 4 5 --apply >/dev/null 2>&1 )
A7B_RC=$?
assert_eq "A7b completion mode repairs the hand-moved record (exit 0)" "$A7B_RC" "0"
assert_eq "A7b the skipped provenance note is now written" \
  "$(grep -cE '\*\*Numbering provenance — `004 → 005`\.\*\*' "$ROOT/wt-B7/release/ADRs/ADR-005-bravo.md")" "1"
assert_eq "A7b the dangling citations A7 measured are now swept" \
  "$(cd "$ROOT/wt-B7" && cite_count design-note.md 4)" "0"

echo "=== A10 — the renumber-DOWN case (WOULD-GAP; the ADR-099 shape) ==="
seed_origin origin10
G clone -q "$ROOT/origin10" "$ROOT/wt-A10"
( cd "$ROOT/wt-A10" && G checkout -q -b feat/a
  printf '# ADR-004 — alpha\n\n## Status\n\nProposed.\n' > core/ADRs/ADR-004-alpha.md
  G add -A >/dev/null && G commit -qm a && G push -q origin feat/a && \
  G checkout -q main && G merge -q --no-edit feat/a && G push -q origin main )
author_B origin10 wt-B10 6     # B stepped PAST a visible claim — the gap-landing error
cd "$ROOT/wt-B10" && G fetch -q origin
D10="$(python3 release/tools/renumber-adr.py --detect 2>&1)"
echo "$D10" | grep -q "WOULD-GAP" && ok "A10 --detect reports WOULD-GAP at 006" \
  || bad "A10 --detect reports WOULD-GAP at 006" "$D10"
echo "$D10" | grep -q "next=5" && ok "A10 --detect computes the DOWNWARD target 005" \
  || bad "A10 --detect computes the DOWNWARD target 005" "$D10"
python3 release/tools/renumber-adr.py --renumber 6 5 --apply >/dev/null 2>&1
assert_eq "A10 renumber DOWN 006 → 005 exits 0" "$?" "0"
assert_file "A10 ADR-005-bravo.md exists after the downward move" \
  "$ROOT/wt-B10/release/ADRs/ADR-005-bravo.md"
assert_eq "A10 downward move wrote the provenance note too" \
  "$(grep -cE '\*\*Numbering provenance — `006 → 005`\.\*\*' release/ADRs/ADR-005-bravo.md)" "1"
assert_eq "A10 downward move left zero dangling ADR-006" "$(cite_count design-note.md 6)" "0"

echo
echo "renumber-adr fixture: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
