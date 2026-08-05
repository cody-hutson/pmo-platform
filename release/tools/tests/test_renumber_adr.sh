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

# The tools this suite exercises, AND their import closure. `generate-adr-index.py`
# imports the ADR filename contract from `check-adr-numbers.py` and the shared
# frontmatter bound from `check-adr-durability.py`; a staged copy that cannot resolve
# an import fails at module load, so the closure is part of the fixture's contract.
# `check-adr-durability.py` is additionally invoked directly (A3c) against a worktree.
for t in check-adr-numbers.py renumber-adr.py generate-adr-index.py check-adr-durability.py; do
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
  # The staged set is the import CLOSURE, not just the entry points: the projector
  # loads `check-adr-numbers.py` (filename contract) and `check-adr-durability.py`
  # (shared frontmatter bound) by path from its own directory.
  cp "${TOOLS}/check-adr-numbers.py" "${TOOLS}/renumber-adr.py" \
     "${TOOLS}/generate-adr-index.py" "${TOOLS}/check-adr-durability.py" \
     "$s/release/tools/"
  # Records carry FRONTMATTER, because the release index is projected from it.
  # A frontmatter-less stub would make the projector refuse and the fixture would
  # be testing a shape the corpus does not have.
  for n in 001 002 003; do
    printf -- '---\ntitle: "ADR-%s — Seed %s"\nstatus: Accepted\ndate: 2026-01-01\nrelease: seed-release\n---\n\n# ADR-%s — Seed %s\n\n## Status\n\nAccepted.\n\n## Context\n\nseed.\n' \
      "$n" "$n" "$n" "$n" > "$s/core/ADRs/ADR-$n-seed$n.md"
  done
  printf -- '---\ntitle: "ADR-002 — Seed two"\nstatus: Accepted\ndate: 2026-01-02\nrelease: seed-release\n---\n\n# ADR-002 — Seed two\n\n## Status\n\nAccepted.\n' \
    > "$s/release/ADRs/ADR-002-seed002.md"
  rm -f "$s/core/ADRs/ADR-002-seed002.md"
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
  # release README — the POST-COLLAPSE shape the corpus now has: one PROJECTED
  # index region, and no hand-maintained enumeration of the record set. The three
  # hand-maintained surfaces this fixture used to carry were collapsed when the
  # index became a derived surface; a fixture still asserting against them would
  # keep passing green against a shape the corpus no longer has, which is the
  # defect this update exists to prevent.
  cat > "$s/release/ADRs/README.md" <<'EOF'
<!-- derived-surface: source=release/ADRs/ADR-*.md (filename + frontmatter) · projector=release/tools/generate-adr-index.py -->
# Release ADRs

## Naming convention

`ADR-NNN-kebab-case-title.md`, one global sequence across both directories. Which
numbers are release-scoped is derivable from the directory, not enumerated here.

## Release-scoped ADRs

<!-- ADR-INDEX:BEGIN -->
<!-- ADR-INDEX:END -->
EOF
  ( cd "$s" && python3 release/tools/generate-adr-index.py --write >/dev/null )
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
    { printf -- '---\ntitle: "ADR-%03d — Bravo record"\nstatus: Proposed\ndate: 2026-02-02\nrelease: bravo-release\n---\n\n# ADR-%03d — bravo\n\n## Status\n\nProposed.\n\n## Context\n\n' "$n" "$n"
      for i in 1 2 3 4 5 6 7 8 9 10; do
        printf 'Context paragraph %d for the bravo record, carrying enough prose that a rename stays detectable.\n\n' "$i"
      done
      printf '## Decision\n\nBravo decides.\n\n## Consequences\n\nBravo consequences.\n'
    } > "release/ADRs/ADR-$(printf '%03d' "$n")-bravo.md"
    # 4 citations across 2 files — the branch's own citation set.
    printf 'Design cites ADR-%03d twice: ADR-%03d.\n' "$n" "$n" > design-note.md
    printf 'Plan cites ADR-%03d and again ADR-%03d.\n' "$n" "$n" > plan-note.md
    # A BINARY deliverable inside the branch diff. Not decoration: every real
    # release branch rebuilds `packages/*.skill`, a compiled archive, and the
    # R3 scope walk reads every in-scope file as UTF-8. Before the guard this
    # raised UnicodeDecodeError *outside* the revert path — under --apply,
    # after R2 had already renamed the record. Seeding it here means the whole
    # A1-A6 block is the regression guard: a tool that crashes on it fails
    # `--renumber 4 5 --apply exits 0` and every assertion beneath.
    mkdir -p packages
    printf 'PK\003\004\353\277\376binary-skill-package-fixture\n' > packages/fixture-bravo.skill
    # B registers itself the way an author now does: it RUNS THE PROJECTOR. It does
    # not hand-add a row — that is exactly what --verify fails. It still hand-edits
    # the CORE README, which remains a curated, hand-maintained document.
    python3 release/tools/generate-adr-index.py --write >/dev/null
    awk -v n="$(printf '%03d' "$n")" '
      /^\| ADR-002 \| core \| seeded \|$/ && !d { print; print "| ADR-" n " | release | authored |"; d=1; next } { print }' \
      core/ADRs/README.md > core/ADRs/README.new && mv core/ADRs/README.new core/ADRs/README.md
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

# --- A11 --exclude-path narrows R3 scope (dry-run; zero mutation) ------------
# The counterpart to --extra-path. It exists because the R3 completeness
# argument runs ONE way: "an unmerged record cannot be cited from a
# mainline-unchanged file" is true, but its converse is false — once the
# mainline is merged INTO the release branch, a file the branch also edited
# carries the MAINLINE's citations to whichever record holds <old>, and R3
# rewrites them. Sensitivity first: the un-excluded run must SEE the file, or
# the exclusion arm proves nothing.
EXC_BASE="$(python3 release/tools/renumber-adr.py --renumber 4 5 2>&1)"
assert_eq "A11 SENSITIVITY — design-note.md is in R3 scope without the exclusion" \
  "$(printf '%s\n' "$EXC_BASE" | grep -c 'would rewrite.*design-note.md')" "1"
EXC_OUT="$(python3 release/tools/renumber-adr.py --renumber 4 5 \
             --exclude-path design-note.md 2>&1)"
assert_eq "A11 --exclude-path drops the file from R3 scope" \
  "$(printf '%s\n' "$EXC_OUT" | grep -c 'would rewrite.*design-note.md')" "0"
assert_eq "A11 the exclusion is REPORTED, not silent" \
  "$(printf '%s\n' "$EXC_OUT" | grep -c 'EXCLUDED by --exclude-path')" "1"
assert_eq "A11 SPECIFICITY — the other cited file is still swept" \
  "$(printf '%s\n' "$EXC_OUT" | grep -c 'would rewrite.*plan-note.md')" "1"
EXC_TYPO="$(python3 release/tools/renumber-adr.py --renumber 4 5 \
              --exclude-path no-such-file.md 2>&1)"
assert_eq "A11 a pattern matching nothing is CALLED OUT (a typo re-widens silently)" \
  "$(printf '%s\n' "$EXC_TYPO" | grep -c 'matched NO in-scope file')" "1"
assert_eq "A11 zero mutation across all three dry runs" \
  "$(G status --porcelain | wc -l | tr -d ' ')" "0"

APPLY="$(python3 release/tools/renumber-adr.py --renumber 4 5 --apply 2>&1)"; AP_RC=$?
assert_eq "--renumber 4 5 --apply exits 0" "$AP_RC" "0"

# --- A1 rename ---------------------------------------------------------------
assert_file  "A1 ADR-005-bravo.md exists"       "release/ADRs/ADR-005-bravo.md"
assert_nofile "A1 ADR-004-bravo.md is gone"     "release/ADRs/ADR-004-bravo.md"
assert_eq "A1 git records a rename (R)" \
  "$(G diff --cached --name-status -M | grep -c '^R.*ADR-004-bravo.md')" "1"

# --- A1b binary in the branch diff: dropped from R3 scope, and SAID SO --------
# The A1-A6 block above is the crash guard (a raise makes AP_RC non-zero). This
# asserts the second half of the contract: the scope shrank VISIBLY. A silent
# drop is the answer-over-the-wrong-population defect wearing a clean exit code.
assert_eq "A1b R3 reports the non-UTF-8 file it dropped from scope" \
  "$(printf '%s\n' "$APPLY" | grep -c 'non-UTF-8 file(s) dropped')" "1"
assert_eq "A1b the dropped file is named, not merely counted" \
  "$(printf '%s\n' "$APPLY" | grep -c 'packages/fixture-bravo.skill')" "1"

# --- A2 zero dangling --------------------------------------------------------
assert_eq "A2 design-note.md: 0 stale ADR-004"  "$(cite_count design-note.md 4)" "0"
assert_eq "A2 design-note.md: 2 rewritten ADR-005" "$(cite_count design-note.md 5)" "2"
assert_eq "A2 plan-note.md:   0 stale ADR-004"  "$(cite_count plan-note.md 4)" "0"
assert_eq "A2 plan-note.md:   2 rewritten ADR-005" "$(cite_count plan-note.md 5)" "2"
# The surviving ADR-004 in the tree must be A's record, in a mainline-unchanged file.
SURV="$(grep -rl 'ADR-004' --include='*.md' . 2>/dev/null | grep -v '^./release/ADRs/ADR-005' | sort)"
assert_eq "A2 no in-scope file still cites ADR-004" \
  "$(echo "$SURV" | grep -c -E 'design-note|plan-note|release/ADRs/README')" "0"

# --- A3 index surfaces --------------------------------------------------------
# The release index is now a PROJECTED surface, so A3's subject changed with it.
# The old arm asserted that R4 had hand-rewritten three enumerations in this file.
# Two of those enumerations no longer exist, and hand-rewriting the third is now the
# defect: a rewritten row fails the projection check the same renumber triggers. So
# A3 asserts the *projection is faithful after the move*, which is the property that
# actually has to hold — and A3d is the negative control proving that assertion can
# fail. Without A3d, A3c passing would be evidence of nothing.
assert_eq "A3a projected index row rewritten (link text + href)" \
  "$(grep -c '\[ADR-005\](ADR-005-bravo.md)' release/ADRs/README.md)" "1"
assert_eq "A3a the moved number leaves NO row behind" \
  "$(grep -c '\[ADR-004\]' release/ADRs/README.md)" "0"
assert_eq "A3b projected row carries the DERIVED columns, not hand-typed ones" \
  "$(grep -cE '^\| \[ADR-005\]\(ADR-005-bravo\.md\) \| Bravo record \| Proposed \| 2026-02-02 \| bravo-release \|$' release/ADRs/README.md)" "1"
assert_eq "A3b the collapsed prose roster is GONE (not merely stale)" \
  "$(grep -c 'This module holds' release/ADRs/README.md)" "0"
python3 release/tools/generate-adr-index.py --verify >/dev/null 2>&1
assert_eq "A3c the renumbered tree PASSES the projection check" "$?" "0"
# A3c is an OUTCOME assertion and a path-exact hand-rewrite could satisfy it by
# coincidence, so the MECHANISM is asserted directly: R4 must report that it reached
# this surface through the projector. This is the arm that fails if the amendment is
# reverted, and outcome-only assertions would not have caught that.
assert_eq "A3c MECHANISM — R4 reached the release index THROUGH the projector" \
  "$(echo "$APPLY" | grep -c 'R4 index: release/ADRs/README.md regenerated by generate-adr-index.py')" "1"
assert_eq "A3c the core README took the HAND-MAINTAINED path in the same run" \
  "$(echo "$APPLY" | grep -c 'R4 index: updated core/ADRs/README.md')" "1"
# A3d NEGATIVE CONTROL — hand-edit one derived cell; --verify must now FAIL. This is
# what makes A3c a measurement rather than a tautology, and it is the same
# hand-edit-a-generated-region failure R4 would have committed before the amendment.
cp release/ADRs/README.md /tmp/.a3d.$$
sed -i.bak 's/| Bravo record | Proposed |/| Bravo record | Accepted |/' release/ADRs/README.md
python3 release/tools/generate-adr-index.py --verify >/dev/null 2>&1
assert_eq "A3d NEGATIVE CONTROL — a hand-edited derived cell FAILS the projection check" \
  "$?" "1"
mv /tmp/.a3d.$$ release/ADRs/README.md; rm -f release/ADRs/README.md.bak
assert_eq "A3 cross-numbering row rewritten in the HAND-MAINTAINED core README" \
  "$(grep -cE '^\| ADR-005 \| release \|' core/ADRs/README.md)" "1"
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

echo "=== A12 — the MULTI-CLAIM reconciliation (N>=2; the deadlock shape) ==="
# WHY THIS FIXTURE EXISTS. Every case above holds ONE outstanding claim, and at
# N=1 "does this move introduce a problem?" and "is the post-move union clean?"
# are the same question. They diverge at N>=2, and the suite could not see it:
# it reported 53/53 green while the tool refused every move of a real
# three-claim reconciliation, in BOTH orderings. That gap shipped twice and was
# worked around by hand (`57a53a69`). This is the live release's shape in
# miniature — two true duplicates plus one branch claim already sitting on a
# mainline-free number, which is also the minimal-assignment case (ADR-115).
seed_origin origin12
G clone -q "$ROOT/origin12" "$ROOT/wt-A12"
( cd "$ROOT/wt-A12" && G checkout -q -b feat/a
  for n in 004 005; do
    printf '# ADR-%s — alpha\n\n## Status\n\nProposed.\n' "$n" > "core/ADRs/ADR-$n-alpha.md"
  done
  G add -A >/dev/null && G commit -qm a && G push -q origin feat/a && \
  G checkout -q main && G merge -q --no-edit feat/a && G push -q origin main )
# B authors THREE records: 004 and 005 collide with A's, 006 does not.
author_B origin12 wt-B12 4
( cd "$ROOT/wt-B12"
  for n in 005 006; do
    { printf -- '---\ntitle: "ADR-%s — Bravo record"\nstatus: Proposed\ndate: 2026-02-02\nrelease: bravo-release\n---\n\n# ADR-%s — bravo\n\n## Status\n\nProposed.\n\n## Context\n\n' "$n" "$n"
      for i in 1 2 3 4 5 6 7 8 9 10; do
        printf 'Context paragraph %d carrying enough prose that a rename stays detectable.\n\n' "$i"
      done
      printf '## Decision\n\nBravo decides.\n' ; } > "release/ADRs/ADR-$n-bravo$n.md"
  done
  printf 'Notes cite ADR-004, ADR-005 and ADR-006.\n' > multi-note.md
  python3 release/tools/generate-adr-index.py --write >/dev/null
  G add -A >/dev/null && G commit -qm "author 005 + 006" )
cd "$ROOT/wt-B12" && G fetch -q origin
D12="$(python3 release/tools/renumber-adr.py --detect 2>&1)"

# --- the assignment is MINIMAL and self-consistent ---------------------------
assert_eq "A12 --detect holds the mainline-free claim FIXED (BINDS, not moved)" \
  "$(printf '%s\n' "$D12" | grep -c '^CLAIM	ADR-006	.*	BINDS')" "1"
assert_eq "A12 --detect moves exactly the two true duplicates" \
  "$(printf '%s\n' "$D12" | grep -c 'DUPLICATE')" "2"
assert_eq "A12 --detect targets 007 and 008, never the occupied 006" \
  "$(printf '%s\n' "$D12" | grep -cE 'next=(7|8)$')" "2"
assert_eq "A12 MINIMALITY CONTROL — no row targets a number another claim holds" \
  "$(printf '%s\n' "$D12" | grep -c 'next=6')" "0"

# --- the deadlock arm: both moves execute, unaided ---------------------------
M1="$(python3 release/tools/renumber-adr.py --renumber 4 7 --apply 2>&1)"; M1_RC=$?
assert_eq "A12 DEADLOCK ARM — the FIRST move of a multi-claim plan exits 0" "$M1_RC" "0"
# The disagreeing control that makes the arm above a measurement. After move 1
# the union is STILL illegal — ADR-005 is still duplicated — which is precisely
# the state the old whole-union predicate refused to pass through. A tool that
# only proceeds from a clean union cannot reach this line.
python3 release/tools/check-adr-numbers.py >/dev/null 2>&1
assert_eq "A12 CONTROL — the union is still ILLEGAL after move 1 (the old predicate's refusal condition)" \
  "$?" "1"
assert_eq "A12 the move SAYS it is one step of a plan, not the whole of it" \
  "$(printf '%s\n' "$M1" | grep -c 'R1 outstanding: .* violation(s) stand before this move')" "1"
# ONE COMMIT PER MOVE, and the suite asserts the constraint rather than tiptoeing
# around it. R1's dirty-tree refusal is load-bearing — `<ref>...HEAD` is only the
# complete branch diff against a clean tree — so a multi-claim plan is a sequence
# of commits, not a batch. Sensitivity first: without the commit, move 2 refuses.
python3 release/tools/renumber-adr.py --renumber 5 8 --apply >/dev/null 2>&1
assert_eq "A12 SENSITIVITY — a second move on an uncommitted tree is refused (dirty-tree guard intact)" \
  "$?" "2"
G commit -qm "renumber ADR-004 -> ADR-007" >/dev/null
M2="$(python3 release/tools/renumber-adr.py --renumber 5 8 --apply 2>&1)"; M2_RC=$?
assert_eq "A12 DEADLOCK ARM — the SECOND move exits 0" "$M2_RC" "0"

# --- the end state -----------------------------------------------------------
C12="$(python3 release/tools/check-adr-numbers.py 2>&1)"; C12_RC=$?
assert_eq "A12 the reconciled tree PASSES check-adr-numbers" "$C12_RC" "0"
printf '%s\n' "$C12" | grep -q 'contiguous 001..008' \
  && ok "A12 contiguous 001..008, no duplicates" \
  || bad "A12 contiguous 001..008, no duplicates" "$C12"
assert_file "A12 the held record was NOT renumbered" "release/ADRs/ADR-006-bravo006.md"
assert_eq "A12 the held record carries NO provenance note (it never moved)" \
  "$(grep -cE '\*\*Numbering provenance' release/ADRs/ADR-006-bravo006.md)" "0"
assert_eq "A12 the first moved record carries its provenance note" \
  "$(grep -cE '\*\*Numbering provenance — `004 → 007`\.\*\*' release/ADRs/ADR-007-bravo.md)" "1"
assert_eq "A12 the second moved record carries its provenance note" \
  "$(grep -cE '\*\*Numbering provenance — `005 → 008`\.\*\*' release/ADRs/ADR-008-bravo005.md)" "1"
assert_eq "A12 zero dangling ADR-004/ADR-005 in the branch's own citation set" \
  "$(( $(cite_count multi-note.md 4) + $(cite_count multi-note.md 5) ))" "0"
assert_eq "A12 SPECIFICITY — the held claim's citation was NOT swept" \
  "$(cite_count multi-note.md 6)" "1"

# --- SPECIFICITY: the delta predicate still refuses a genuinely illegal move --
G commit -qm "renumber ADR-005 -> ADR-008" >/dev/null
BEFORE12="$(G rev-parse HEAD):$(G status --porcelain | wc -l | tr -d ' ')"
python3 release/tools/renumber-adr.py --renumber 7 12 --apply >/dev/null 2>&1
assert_eq "A12 SPECIFICITY — a move that would LAND a gap is still refused" "$?" "2"
assert_eq "A12 zero mutation after the refusal" \
  "$(G rev-parse HEAD):$(G status --porcelain | wc -l | tr -d ' ')" "$BEFORE12"

echo
echo "renumber-adr fixture: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
