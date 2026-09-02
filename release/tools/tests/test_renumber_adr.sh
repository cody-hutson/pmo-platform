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
# Assertions A1-A15 map to the cards' acceptance criteria. A7 is the negative
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

# A13's closure. R7 does not re-implement the path -> skill reverse resolution; it
# INVOKES the package builder's `--skills-for-paths` query, so the query and its own
# read closure are part of what A13 exercises. `deploy.sh` is in the list because the
# query extracts TEMPLATE_SYNC_MAP and the per-module rosters from it at runtime, and
# `lib-template-sync-source.sh` because it is sourced for the canonical resolver.
# Named EXPLICITLY, and staged per-worktree by stage_builder below, so A13 never
# resolves to the ambient checkout — the suite's contract is that every tool under
# test is COPIED FROM THE TREE UNDER TEST.
BUILDER_CLOSURE="core/deploy/tools/build-skill-packages.sh core/deploy/lib-template-sync-source.sh core/deploy/deploy.sh"
for t in $BUILDER_CLOSURE; do
  [ -f "${REPO_UNDER_TEST}/${t}" ] || { echo "FATAL: ${REPO_UNDER_TEST}/${t} missing — A13 cannot verify R7's disclosure without the resolver R7 invokes" >&2; exit 1; }
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

# plan_section <file> <H2 title> — the lines of one `## <title>` section, up to and
# INCLUDING its terminating heading. ACT 15 uses it to scope a "no stale token
# survives" assertion to one section rather than to a whole file, which is what
# makes that zero a statement about the region rule instead of about the document.
# The terminating line is included on purpose: it is the boundary the extent rule
# is being graded on, so the fixture's closing heading deliberately carries no ADR
# token.
plan_section() { sed -n "/^## $2\$/,/^## /p" "$1"; }

# ------------------------------------------- stage the R7 resolver into a worktree
# The copy is COMMITTED, and that is not incidental: R1 refuses a dirty tree, so an
# untracked staging would make every A13 arm refuse at R1 and never reach R7 — the
# arm would go green having tested nothing. A worktree that never calls this keeps
# the resolver absent, which is exactly the state A13c asserts against.
stage_builder() {
  local w="$ROOT/$1" t
  mkdir -p "$w/core/deploy/tools"
  for t in $BUILDER_CLOSURE; do
    cp "${REPO_UNDER_TEST}/${t}" "$w/${t}"
  done
  ( cd "$w" && G add -A >/dev/null && G commit -qm "stage the package-builder closure" )
}

# roster_add <worktree> <skill> — register a fixture skill in the STAGED deploy.sh's
# CORE_SKILLS array.
#
# Required because the builder's --skills-for-paths query resolves a candidate against
# the real roster arrays before emitting it: a directory that looks like a skill but is
# absent from every roster is correctly rejected as "not a packageable skill". That is
# deliberate product behaviour — an unrostered directory has no package, so there is no
# staleness for R7 to disclose — and it is what makes the A13a scenario constructible
# only for a skill the roster actually knows.
#
# The edit is confined to the staged copy inside the fixture's throwaway worktree. The
# real roster is never touched, so this registers a test double rather than widening the
# platform's own skill set.
roster_add() {
  local w="$ROOT/$1" skill="$2"
  python3 - "$w/core/deploy/deploy.sh" "$skill" <<'PY'
import re, sys
path, skill = sys.argv[1], sys.argv[2]
s = open(path).read()
m = re.search(r"^CORE_SKILLS=\(\n", s, re.M)
if not m:
    sys.exit("FATAL: CORE_SKILLS array not found in the staged deploy.sh")
open(path, "w").write(s[:m.end()] + f"  {skill}\n" + s[m.end():])
PY
  ( cd "$w" && G add -A >/dev/null && G commit -qm "register ${skill} in the staged roster" )
}

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
grep -q "DUPLICATE" <<<"$DET" && ok "--detect reports DUPLICATE at 004" \
  || bad "--detect reports DUPLICATE at 004" "$DET"
grep -q "next=5" <<<"$DET" && ok "--detect computes next-free 005" \
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
grep -q 'contiguous 001..005' <<<"$A5_OUT" \
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
grep -q "COMPLETION MODE" <<<"$IDEM" \
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
grep -q "WOULD-GAP" <<<"$D10" && ok "A10 --detect reports WOULD-GAP at 006" \
  || bad "A10 --detect reports WOULD-GAP at 006" "$D10"
grep -q "next=5" <<<"$D10" && ok "A10 --detect computes the DOWNWARD target 005" \
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
grep -q 'contiguous 001..008' <<<"$C12" \
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

echo "=== A13 — R7 package-staleness disclosure ==="
# WHY THIS ARM EXISTS. `packages/*.skill` is dropped from the R3 scope as a
# rebuild-derived artifact, and that is correct. But R3 rewrites the SOURCES those
# archives are built from, so a renumber that touches a packaged skill's source
# leaves the package stale — and the tool used to say nothing at all. The staleness
# then surfaced at the next `deploy.sh --check` (Check 7): a drift detector absorbing
# drift a sibling tool knowingly created, reported to the operator at the next gate
# rather than at the cause. R7 discloses it at the cause. It NAMES; it never rebuilds.
seed_origin origin13
G clone -q "$ROOT/origin13" "$ROOT/wt-A13"
( cd "$ROOT/wt-A13" && G checkout -q -b feat/a
  printf '# ADR-004 — alpha\n\n## Status\n\nProposed.\n' > core/ADRs/ADR-004-alpha.md
  G add -A >/dev/null && G commit -qm a && G push -q origin feat/a && \
  G checkout -q main && G merge -q --no-edit feat/a && G push -q origin main )

# --- A13a the packaged skill's source is swept, and the package is NAMED ------
author_B origin13 wt-B13a 4
stage_builder wt-B13a
roster_add wt-B13a fixture-skill
( cd "$ROOT/wt-B13a"
  mkdir -p core/skills/fixture-skill
  printf -- '---\nname: fixture-skill\n---\n\n# fixture-skill\n\nThe body cites ADR-004.\n' \
    > core/skills/fixture-skill/SKILL.md
  G add -A >/dev/null && G commit -qm "author fixture-skill citing ADR-004" )
cd "$ROOT/wt-B13a" && G fetch -q origin
R7A="$(python3 release/tools/renumber-adr.py --renumber 4 5 --apply 2>&1)"; R7A_RC=$?
assert_eq "A13a the renumber still exits 0 with R7 in the path" "$R7A_RC" "0"
# Sensitivity first: if the sweep never reached the skill source there is no
# staleness to disclose, and the assertion below would be measuring nothing.
assert_eq "A13a SENSITIVITY — the packaged skill's source was actually swept" \
  "$(cite_count core/skills/fixture-skill/SKILL.md 5)" "1"
assert_eq "A13a R7 NAMES the staled package" \
  "$(printf '%s\n' "$R7A" | grep -c 'R7 packages: .*packages/fixture-skill\.skill')" "1"
assert_eq "A13a R7 emits the exact rebuild command, not a vague instruction" \
  "$(printf '%s\n' "$R7A" | grep -c 'rebuild via core/deploy/tools/build-skill-packages\.sh fixture-skill')" "1"

# --- A13b NEGATIVE CONTROL — nothing staled, so nothing is named --------------
# Without this arm A13a is evidence of nothing: a step that named a package
# unconditionally would satisfy A13a and be worthless. Same discipline as A7 and
# A3d. The assertion is scoped to the R7 line on purpose — R3's own non-UTF-8 drop
# line legitimately names `packages/fixture-bravo.skill`, so an unscoped match here
# would fail against correct behaviour.
author_B origin13 wt-B13b 4
stage_builder wt-B13b
cd "$ROOT/wt-B13b" && G fetch -q origin
R7B="$(python3 release/tools/renumber-adr.py --renumber 4 5 --apply 2>&1)"; R7B_RC=$?
assert_eq "A13b the renumber exits 0 with no packaged source in the sweep" "$R7B_RC" "0"
assert_eq "A13b R7 reports 'none affected' rather than staying silent" \
  "$(printf '%s\n' "$R7B" | grep -c 'R7 packages: none affected')" "1"
assert_eq "A13b R7 names NO package when the sweep staled none" \
  "$(printf '%s\n' "$R7B" | grep -c 'R7 packages: .*\.skill')" "0"

# --- A13d UNROSTERED — a skill-shaped directory the roster does not know -------
# The arm that keeps A13a's roster_add honest. A13a registers its fixture skill so the
# scenario is constructible at all; without this arm, a reader could reasonably suspect
# the registration was papering over a product regression rather than modelling reality.
#
# It does not. An unrostered directory has no package, so there is no staleness to
# disclose, and R7 must stay silent about it — the same behaviour that made A13a fail
# before the registration was added. Here the skill source IS swept (sensitivity below),
# so silence cannot be explained away as the sweep never reaching it.
#
# This arm fails if the resolvability filter is ever removed: R7 would name a package
# that does not exist and cannot be built, sending a reader to a rebuild command that
# errors.
author_B origin13 wt-B13d 4
stage_builder wt-B13d
( cd "$ROOT/wt-B13d"
  mkdir -p core/skills/unrostered-skill
  printf -- '---\nname: unrostered-skill\n---\n\n# unrostered-skill\n\nThe body cites ADR-004.\n' \
    > core/skills/unrostered-skill/SKILL.md
  G add -A >/dev/null && G commit -qm "author unrostered-skill citing ADR-004" )
cd "$ROOT/wt-B13d" && G fetch -q origin
R7C="$(python3 release/tools/renumber-adr.py --renumber 4 5 --apply 2>&1)"; R7C_RC=$?
assert_eq "A13d the renumber exits 0 with an unrostered skill in the sweep" "$R7C_RC" "0"
assert_eq "A13d SENSITIVITY — the unrostered skill's source WAS swept" \
  "$(cite_count core/skills/unrostered-skill/SKILL.md 5)" "1"
assert_eq "A13d R7 does NOT name a package for an unrostered skill" \
  "$(printf '%s\n' "$R7C" | grep -c 'R7 packages: .*unrostered-skill\.skill')" "0"

# --- A13c DEGRADATION — the resolver is unreachable; the run STILL succeeds ---
# The highest-value arm. R7 runs AFTER R6 verified and `git add -A` staged, so a
# naive `check=True` would fail a fully-verified renumber — turning the defect this
# card fixes into a strictly worse one. The resolver is absent here NATURALLY: a
# worktree that never calls stage_builder carries only the ADR-tool closure, so this
# asserts the fixture's own default state rather than simulating an outage.
author_B origin13 wt-B13c 4
cd "$ROOT/wt-B13c" && G fetch -q origin
assert_nofile "A13c PRECONDITION — the resolver really is absent from this tree" \
  "core/deploy/tools/build-skill-packages.sh"
R7C="$(python3 release/tools/renumber-adr.py --renumber 4 5 --apply 2>&1)"; R7C_RC=$?
assert_eq "A13c an unreachable resolver does NOT fail the renumber (exit 0)" "$R7C_RC" "0"
assert_eq "A13c R6 still reports success" \
  "$(printf '%s\n' "$R7C" | grep -c 'R6 verify: zero dangling in-scope citations')" "1"
assert_eq "A13c R7 says UNDETERMINED rather than falsely claiming 'none affected'" \
  "$(printf '%s\n' "$R7C" | grep -c 'R7 packages: UNDETERMINED')" "1"
assert_eq "A13c the degraded notice still names what the run wrote" \
  "$(printf '%s\n' "$R7C" | grep -c 'This run wrote: .*release/ADRs/ADR-005-bravo\.md')" "1"

echo "=== A14 — DRY-RUN / APPLY PARITY on a record with >=2 prior hops ==="
# WHY THIS ACT EXISTS. The dry run used to count raw `ADR-<old>` matches while the
# apply path consulted an exemption, so it PREDICTED rewriting the two line classes
# a line-identity check cannot tell from a citation: this record's own earlier hop,
# and a SIBLING release's claim history. Read literally it predicted falsifying two
# audit records. The write was correct; the PREDICTION was the defect — on the one
# edit class a reviewer is most likely to approve on the strength of a dry run.
#
# WHY >=2 PRIOR HOPS, AND WHY THIS CANNOT LIVE IN `--self-test`. The exemption
# cannot fire on a FIRST move: there is no prior hop to spare, so a parity arm
# pinned there is vacuously green and its control returns zero. "Two prior hops" is
# a TOPOLOGY property — the record moved, the tree was committed, the mainline
# advanced, it moved again — and `self_test()` is documented pure-function (no git,
# no filesystem), so a hop count cannot be expressed there. A14e is the first-move
# NEGATIVE CONTROL that makes every arm below a measurement rather than a tautology.
# Measured margin, recorded so nobody optimizes it away: ONE prior hop already
# reproduces the divergence; two is a deliberate margin that additionally exercises
# the lineage case (the exemption firing on a non-adjacent earlier move while the
# adjacent one is also present). Do not reduce it.
#
# ONE COMMIT PER HOP, asserted rather than tiptoed around: R1 refuses a dirty tree,
# exactly as A12 already establishes for a multi-claim plan.

# Declared here because ACT A14 is the FIRST act to parse the dry-run report. ACT 15
# below is the second and reads the same output shape, so `dr_lines` is shared by the
# two rather than duplicated into each — a second copy of an output reader is the
# dry-run/apply divergence class in miniature. Kept beside its first caller rather
# than hoisted to the top of the suite: it is a reader for ONE output shape, not a
# suite-wide contract.
#
# The dry-run per-file line is
#   `    would rewrite   1 × ADR-006 in core/ADRs/README.md  ·  exempt (record) 2  ·  REVIEW 0`
# so awk's whitespace split gives $3=would, $11=exempt, $14=REVIEW. Keyed on the
# " in <path>  " substring (two trailing spaces before the separator), which cannot
# collide across the fixture's paths: " in release/ADRs/README.md  " does not
# contain " in core/ADRs/README.md  ".
dr_field() {   # $1 dry-run text · $2 path · $3 would|exempt|review
  printf '%s\n' "$1" | awk -v p=" in ${2}  " -v w="$3" '
    index($0, p) && $1 == "would" {
      if (w == "would") print $3; else if (w == "exempt") print $11; else print $14; exit }'
}
dr_lines() { printf '%s\n' "$1" | grep -cF " in ${2}  "; }

# A authors the next mainline record and pushes it, so B's held number becomes a
# genuine DUPLICATE at every hop. A synthetic re-run against a static mainline
# would measure the fixture's artificiality, not the tool.
alpha14() {   # $1 worktree · $2 zero-padded number · $3 slug
  ( cd "$ROOT/$1" && printf -- '---\ntitle: "ADR-%s — Alpha"\nstatus: Accepted\ndate: 2026-03-01\nrelease: alpha-release\n---\n\n# ADR-%s — alpha\n\n## Status\n\nAccepted.\n\n## Context\n\nAlpha.\n' "$2" "$2" > "core/ADRs/ADR-$2-$3.md"
    G add -A >/dev/null && G commit -qm "author ADR-$2 $3" && G push -q origin main )
}

seed_origin origin14
G clone -q "$ROOT/origin14" "$ROOT/wt-A14"
author_B origin14 wt-B14 4

# --- THE ONE HAND-SEED: a SIBLING release's renumber-log entry ----------------
# This is the only hand-authored line in the whole act, and every constraint on it
# is structural rather than stylistic:
#   * it goes in `core/ADRs/README.md`, the HAND-MAINTAINED index — never inside a
#     projected region, because a hand-edited derived cell correctly FAILS the
#     projection check (A3d already asserts that failure);
#   * it goes on its OWN line below the `**Renumber log.**` bold-run heading,
#     because `append_renumber_log` writes only to the heading line itself
#     (`lines[idx] = lines[idx].rstrip() + sentence`), so a following line is never
#     disturbed by the tool's own appends;
#   * it carries no comma-run of three or more `ADR-NNN`, so `resort_inline_list`'s
#     `ADR-\d+(?:,\s*ADR-\d+){2,}` cannot match and silently reorder it;
#   * it names ADR-006 as a number a DIFFERENT record once held, which is precisely
#     the "another release's claim history" exclusion class the card names — and it
#     only becomes load-bearing at hop 3, when this record's own number is 006.
# Written through python3 so the apostrophe and the backticks need no shell
# quoting gymnastics, the same idiom `roster_add` already uses.
python3 - "$ROOT/wt-B14/core/ADRs/README.md" <<'PY'
import sys
path = sys.argv[1]
sentence = ("ADR-006 (`sibling-record`) → **ADR-011** by "
            "`release/tools/renumber-adr.py` at merge time, because the mainline "
            "already claimed 006; the record's Status section carries the "
            "provenance note.")
lines = open(path, encoding="utf-8").read().split("\n")
for i, line in enumerate(lines):
    if line.startswith("**Renumber log.**"):
        lines.insert(i + 1, sentence)
        break
else:
    sys.exit("FATAL: the fixture core README carries no ** Renumber log.** heading")
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
( cd "$ROOT/wt-B14" && G add -A >/dev/null && \
  G commit -qm "seed a sibling release's renumber-log entry" )

# --- the three-hop chain: 4 -> 5 -> 6 -> 7, mainline advancing between hops ---
( cd "$ROOT/wt-A14" && G checkout -q -b feat/a
  printf -- '---\ntitle: "ADR-004 — Alpha"\nstatus: Accepted\ndate: 2026-03-01\nrelease: alpha-release\n---\n\n# ADR-004 — alpha\n\n## Status\n\nAccepted.\n\n## Context\n\nAlpha.\n' > core/ADRs/ADR-004-alpha.md
  G add -A >/dev/null && G commit -qm "author ADR-004 alpha" && G push -q origin feat/a && \
  G checkout -q main && G merge -q --no-edit feat/a && G push -q origin main )

cd "$ROOT/wt-B14" && G fetch -q origin
python3 release/tools/renumber-adr.py --renumber 4 5 --apply >/dev/null 2>&1
assert_eq "A14 HOP 1 (004 → 005) exits 0" "$?" "0"
G commit -qm "hop 1" >/dev/null

alpha14 wt-A14 005 alpha2
cd "$ROOT/wt-B14" && G fetch -q origin
python3 release/tools/renumber-adr.py --renumber 5 6 --apply >/dev/null 2>&1
assert_eq "A14 HOP 2 (005 → 006) exits 0 — two prior hops now complete" "$?" "0"
G commit -qm "hop 2" >/dev/null

alpha14 wt-A14 006 alpha3
cd "$ROOT/wt-B14" && G fetch -q origin

# --- PRE-STATE, captured before the measured move ----------------------------
PRE_CORE="$(cite_count core/ADRs/README.md 6)"
PRE_REC="$(cite_count release/ADRs/ADR-006-bravo.md 6)"
PRE_DESIGN="$(cite_count design-note.md 6)"
PRE_PLAN="$(cite_count plan-note.md 6)"
PRE_PROJ="$(cite_count release/ADRs/README.md 6)"

DRY14="$(python3 release/tools/renumber-adr.py --renumber 6 7 2>&1)"

# --- A14 PRECONDITION — SCOPE MEMBERSHIP, asserted before any "unchanged" claim
# `_in_scope_files` silently drops non-UTF-8 files, and this fixture seeds one
# (`packages/fixture-bravo.skill`). A fixture file that fell out of R3 scope for
# ANY reason would make every parity arm below pass for the wrong reason — the
# vacuous pass. So membership is measured first, on the same instrument.
assert_eq "A14 PRECONDITION — the curated index is in R3 scope" \
  "$(dr_lines "$DRY14" 'core/ADRs/README.md')" "1"
assert_eq "A14 PRECONDITION — the record file is in R3 scope" \
  "$(dr_lines "$DRY14" 'release/ADRs/ADR-006-bravo.md')" "1"
assert_eq "A14 PRECONDITION — both live-citation files are in R3 scope" \
  "$(( $(dr_lines "$DRY14" 'design-note.md') + $(dr_lines "$DRY14" 'plan-note.md') ))" "2"
assert_eq "A14 PRECONDITION — the projected index is in the branch diff (so its absence below is the REGION, not the scope)" \
  "$(G diff --name-only origin/main...HEAD | grep -cx 'release/ADRs/README\.md')" "1"

# --- A14g ZERO MUTATION — the dry run predicted and wrote nothing -------------
assert_eq "A14g the dry run mutates nothing (A11's idiom, re-asserted on a 2-hop record)" \
  "$(G status --porcelain | wc -l | tr -d ' ')" "0"

WOULD_CORE="$(dr_field "$DRY14" 'core/ADRs/README.md' would)"
EXEMPT_CORE="$(dr_field "$DRY14" 'core/ADRs/README.md' exempt)"
REVIEW_CORE="$(dr_field "$DRY14" 'core/ADRs/README.md' review)"
WOULD_REC="$(dr_field "$DRY14" 'release/ADRs/ADR-006-bravo.md' would)"
EXEMPT_REC="$(dr_field "$DRY14" 'release/ADRs/ADR-006-bravo.md' exempt)"

# --- A14b NAMED (AC-2) — the exemption is PRINTED, not subtracted -------------
# AC-2 is discharged by the exempt column EXISTING with a non-zero value. A file
# reported `would rewrite 0` is indistinguishable from a file with no citations at
# all; `would rewrite 1 · exempt (record) 2` names the exemption instead of
# silently over-predicting it.
assert_eq "A14b AC2 the curated index's dry-run line carries a NON-ZERO exempt (record) column" \
  "$( [ "${EXEMPT_CORE:-0}" -gt 0 ] && echo yes || echo no )" "yes"
assert_eq "A14b AC2 the exempt count is the two exclusion classes the card names (own prior hop + sibling claim)" \
  "$EXEMPT_CORE" "2"

python3 release/tools/renumber-adr.py --renumber 6 7 --apply >/dev/null 2>&1
assert_eq "A14 HOP 3 (006 → 007) — THE MEASURED MOVE — exits 0" "$?" "0"

POST_CORE="$(cite_count core/ADRs/README.md 6)"
POST_REC="$(cite_count release/ADRs/ADR-007-bravo.md 6)"
POST_DESIGN="$(cite_count design-note.md 6)"
POST_PLAN="$(cite_count plan-note.md 6)"

# APPENDED — the `ADR-<old>` tokens the apply path CREATES, measured from the
# post-state rather than assumed. R4's § Renumber-log append and R5's provenance
# note both name the OLD number on purpose: they ARE the audit trail this move
# writes. So a naive `PRE - POST == would` identity is arithmetically FALSE against
# correct behaviour, and stating it that way would encode the apply path's own
# audit record as a defect. The parity that actually closes V1 is a PARTITION of
# the tokens PRESENT AT PRE — `would` moved, `exempt` stayed — plus the survivor
# identity once the created tokens are subtracted back out.
APPENDED_CORE="$(grep -o 'ADR-006 (`bravo`) → \*\*ADR-007\*\* by `release/tools/renumber-adr\.py`' core/ADRs/README.md | grep -o 'ADR-006' | wc -l | tr -d ' ')"
APPENDED_REC="$(grep -o '\*\*Numbering provenance — `006 → 007`\.\*\*.*' release/ADRs/ADR-007-bravo.md | grep -o 'ADR-006' | wc -l | tr -d ' ')"
assert_eq "A14 the apply path's own audit record is MEASURED, not assumed (§ Renumber log)" \
  "$( [ "${APPENDED_CORE:-0}" -gt 0 ] && echo yes || echo no )" "yes"
assert_eq "A14 the apply path's own audit record is MEASURED, not assumed (provenance note)" \
  "$( [ "${APPENDED_REC:-0}" -gt 0 ] && echo yes || echo no )" "yes"

# --- A14a PARITY — the curated index (AC-1 · V1 · THE OBSERVED DEFECT) --------
assert_eq "A14a AC1 PARTITION — would + exempt + review accounts for every ADR-006 token present at PRE (curated index)" \
  "$(( WOULD_CORE + EXEMPT_CORE ))" "$PRE_CORE"
assert_eq "A14a AC1 PARITY — the tokens that SURVIVED the sweep are exactly the ones the dry run called exempt (curated index)" \
  "$(( POST_CORE - APPENDED_CORE ))" "$EXEMPT_CORE"
assert_eq "A14a AC1 PARITY — the tokens the sweep actually MOVED are exactly the ones it predicted (curated index)" \
  "$(( PRE_CORE - (POST_CORE - APPENDED_CORE) ))" "$WOULD_CORE"
assert_eq "A14a the sibling release's claim history was NOT falsified" \
  "$(grep -c 'ADR-006 (`sibling-record`) → \*\*ADR-011\*\*' core/ADRs/README.md)" "1"
assert_eq "A14a this record's OWN prior hop was NOT falsified" \
  "$(grep -o 'ADR-005 (`bravo`) → \*\*ADR-006\*\*' core/ADRs/README.md | wc -l | tr -d ' ')" "1"
assert_eq "A14a SPECIFICITY — the LIVE cross-numbering row was still swept" \
  "$(grep -cE '^\| ADR-007 \| release \|' core/ADRs/README.md)" "1"
assert_eq "A14a no ambiguous site was silently folded into either column" \
  "$REVIEW_CORE" "0"

# --- A14c PARITY — the record file (AC-1 · lineage) ---------------------------
assert_eq "A14c AC1 PARTITION — the record file's tokens are fully accounted for" \
  "$(( WOULD_REC + EXEMPT_REC ))" "$PRE_REC"
assert_eq "A14c AC1 PARITY — the record file's surviving tokens are exactly the exempt ones" \
  "$(( POST_REC - APPENDED_REC ))" "$EXEMPT_REC"
assert_eq "A14c the hop-2 provenance note survives byte-identical (the non-adjacent lineage case)" \
  "$(grep -c 'renumbered to \*\*ADR-006\*\* at merge time' release/ADRs/ADR-007-bravo.md)" "1"

# --- A14d SPECIFICITY (null arm) — live citations are fully predicted and swept
# Without this arm the exemption could be a blanket suppressor and every arm above
# would still pass. These two files carry no record-class line at all.
assert_eq "A14d design-note.md: exempt 0 — nothing to spare in a pure citation file" \
  "$(dr_field "$DRY14" 'design-note.md' exempt)" "0"
assert_eq "A14d design-note.md: the dry run predicted EVERY token present" \
  "$(dr_field "$DRY14" 'design-note.md' would)" "$PRE_DESIGN"
assert_eq "A14d design-note.md: and the apply path swept every one" "$POST_DESIGN" "0"
assert_eq "A14d plan-note.md: exempt 0" \
  "$(dr_field "$DRY14" 'plan-note.md' exempt)" "0"
assert_eq "A14d plan-note.md: the dry run predicted EVERY token present" \
  "$(dr_field "$DRY14" 'plan-note.md' would)" "$PRE_PLAN"
assert_eq "A14d plan-note.md: and the apply path swept every one" "$POST_PLAN" "0"

# --- A14f LINEAGE — append-only, nothing overwritten --------------------------
# COUNTED AS TOKENS, NEVER AS LINES. `append_renumber_log` writes every entry onto
# the SAME line (`lines[idx] = lines[idx].rstrip() + sentence`), so the § Renumber
# log is ONE accumulating line and a `grep -c` here would report 1 no matter how
# many hops landed — a counter that cannot fail.
assert_eq "A14f the § Renumber log carries all THREE tool entries plus the sibling's, on one accumulating line" \
  "$(grep -o 'by `release/tools/renumber-adr\.py` at merge time' core/ADRs/README.md | wc -l | tr -d ' ')" "4"
assert_eq "A14f the record's ## Status reads as a THREE-hop lineage, nothing overwritten" \
  "$(grep -o '\*\*Numbering provenance — `[0-9][0-9][0-9] → [0-9][0-9][0-9]`\.\*\*' release/ADRs/ADR-007-bravo.md | wc -l | tr -d ' ')" "3"
assert_eq "A14f the lineage is chronological (the first hop is still first)" \
  "$(grep -n '\*\*Numbering provenance — `004 → 005`\.\*\*' release/ADRs/ADR-007-bravo.md | head -1 | cut -d: -f1)" \
  "$(grep -n '\*\*Numbering provenance' release/ADRs/ADR-007-bravo.md | head -1 | cut -d: -f1)"

# --- A14h DISCLOSURE — the six divergences that remain OPEN are NAMED ---------
# This card's AC-1 closes ONE of eight divergence classes. The rest are converted
# from silent to disclosed, and the wording matters: the R2 rename IS disclosed
# (by `R1 PROCEED`, which executes before the dry-run block), so a line claiming
# otherwise would be a new false statement in place of an old one.
assert_eq "A14h the dry run discloses that it enumerates R3 and nothing else" \
  "$(printf '%s\n' "$DRY14" | grep -c 'DRY-RUN enumerates R3 only')" "1"
assert_eq "A14h the disclosure names the R2 rename as DISCLOSED, not omitted" \
  "$(printf '%s\n' "$DRY14" | grep -c 'The R2 rename is named above by R1 PROCEED')" "1"
# The disclosure above is only honest if the line it points at actually carries the
# paths. `R1 PROCEED` renders `old_path`/`new_path`, which are ABSOLUTE (`root / …`),
# so the arm matches the basenames rather than a repo-relative form that never
# appears in the output — asserting the shape the tool really emits, not the shape
# the design assumed.
assert_eq "A14h SENSITIVITY — R1 PROCEED really does print the rename paths the disclosure points at" \
  "$(printf '%s\n' "$DRY14" | grep -c 'R1 PROCEED: ADR-006 → ADR-007 (.*ADR-006-bravo\.md → .*ADR-007-bravo\.md)')" "1"
assert_eq "A14h the ambiguous-site review block is emitted even at zero sites" \
  "$(printf '%s\n' "$DRY14" | grep -c 'R3 REVIEW: 0 ambiguous site(s)')" "1"

# --- A14i PROJECTED MECHANISM (V2) — reported by mechanism, not by count ------
# The projector-owned region is DERIVED: a row reading `ADR-<old>` belongs to
# whichever record still legally holds <old>, and R4 regenerates the region from
# the post-rename file set rather than sweeping it. Counting those rows is the same
# over-prediction class as counting an exempt record — an edit the tool would
# itself undo. SENSITIVITY FIRST: the file must actually carry the old number on
# disk, or "predicted zero" would be a statement about an empty file.
assert_eq "A14i SENSITIVITY — the projected index really does carry ADR-006 on disk (there IS something to over-predict)" \
  "$( [ "${PRE_PROJ:-0}" -gt 0 ] && echo yes || echo no )" "yes"
assert_eq "A14i V2 — and the dry run predicts rewriting NONE of it" \
  "$(dr_lines "$DRY14" 'release/ADRs/README.md')" "0"
assert_eq "A14i the projected surface is REPORTED BY MECHANISM rather than left silent" \
  "$(printf '%s\n' "$DRY14" | grep -c 'release/ADRs/README.md is regenerated by generate-adr-index.py')" "1"
assert_eq "A14i SPECIFICITY — the same run still reports the hand-maintained index by count" \
  "$(dr_lines "$DRY14" 'core/ADRs/README.md')" "1"

# --- A14e NEGATIVE CONTROL — the FIRST move (the probe-validity arm) ----------
# THE ARM THAT MAKES EVERY ARM ABOVE A MEASUREMENT. The exemption cannot fire on a
# first move: there is no prior hop and no sibling entry to spare. If A14a's
# identity also held here with a non-zero exempt column, the fixture would be
# measuring the arithmetic and not the exemption. Run LAST so its failure cannot be
# mistaken for a setup problem in the chain above, and so a reader sees the
# positive arms and their control adjacent in the output.
seed_origin origin14e
G clone -q "$ROOT/origin14e" "$ROOT/wt-A14e"
( cd "$ROOT/wt-A14e" && G checkout -q -b feat/a
  printf '# ADR-004 — alpha\n\n## Status\n\nProposed.\n' > core/ADRs/ADR-004-alpha.md
  G add -A >/dev/null && G commit -qm a && G push -q origin feat/a && \
  G checkout -q main && G merge -q --no-edit feat/a && G push -q origin main )
author_B origin14e wt-B14e 4
cd "$ROOT/wt-B14e" && G fetch -q origin
DRY14E="$(python3 release/tools/renumber-adr.py --renumber 4 5 2>&1)"
assert_eq "A14e CONTROL SENSITIVITY — the first-move dry run is doing real work (non-zero would-rewrite on the curated index)" \
  "$(dr_field "$DRY14E" 'core/ADRs/README.md' would)" "1"
assert_eq "A14e NEGATIVE CONTROL — at a FIRST move the curated index reports exempt 0" \
  "$(dr_field "$DRY14E" 'core/ADRs/README.md' exempt)" "0"
assert_eq "A14e NEGATIVE CONTROL — at a FIRST move the record file reports exempt 0" \
  "$(dr_field "$DRY14E" 'release/ADRs/ADR-004-bravo.md' exempt)" "0"
assert_eq "A14e NEGATIVE CONTROL — the whole first-move run reports ZERO exempt tokens" \
  "$(printf '%s\n' "$DRY14E" | grep -cE 'DRY-RUN: [0-9]+ citation\(s\) would move; 0 exempt \(record\);')" "1"
assert_eq "A14e the mechanism line is emitted on a first move too (it is unconditional, not token-gated)" \
  "$(printf '%s\n' "$DRY14E" | grep -c 'release/ADRs/README.md is regenerated by generate-adr-index.py')" "1"

echo "=== ACT 15 — the release-plan DEVIATION LOG (record vs citation, decided by POSITION) ==="
# WHY THIS ACT EXISTS. The historical exemption is a POSITIVE population: a line
# matches a RECORD_OPENERS shape or it does not. A release-plan Deviation Log row
# defeats that shape test by construction —
#   `| DEV-41 | ADR-004 was renumbered after the sibling merge |`   (a RECORD)
#   `| DEV-44 | blocked on ADR-004 landing |`                       (a CITATION)
# differ in prose and not in shape, so a boolean predicate is forced to guess. The
# observed production instance produced the incoherent range `ADR-157–154`, and
# that signature is why it was caught. THE DANGEROUS CASE HAS NO SIGNATURE: a row
# citing a single historical number is rewritten into prose that is syntactically
# valid, internally consistent, and FALSE — it asserts the record held a number it
# never held. No gate reads a bare `ADR-NNN` out of prose, so nothing catches it.
# The three-valued classifier answers by REGION instead: inside an
# AMBIGUOUS_SECTIONS region a token-bearing line is NAMED and never rewritten.
#
# WHY THE SEEDING ARITHMETIC IS LOAD-BEARING. A merges TWO records (004 and 005),
# so the anchor is 5 and the tool targets 006. That gap is what makes the range arm
# constructible at all: renumbering 4 → 6 moves a range's low end PAST an in-range
# high end, which is exactly the observed signature. An adjacent 4 → 5 cannot
# produce it, and an arm seeded that way would be measuring nothing.
#
# WHY TWO HOPS, AND WHY A15e IS A RUN AND NOT A STRING. The Deviation-Log surface
# only populates after a SECOND renumber: the row recording hop 1 carries the
# record's CURRENT number, and that token — not the historical one — is the live
# hazard. Hop 2 is the only moment it exists.
#
# ONE COMMIT PER HOP, as A12 and A14 already establish: R1 refuses a dirty tree.
seed_origin origin15
G clone -q "$ROOT/origin15" "$ROOT/wt-A15"
( cd "$ROOT/wt-A15" && G checkout -q -b feat/a
  for n in 004 005; do
    printf '# ADR-%s — alpha\n\n## Status\n\nProposed.\n' "$n" > "core/ADRs/ADR-$n-alpha.md"
  done
  G add -A >/dev/null && G commit -qm a && G push -q origin feat/a && \
  G checkout -q main && G merge -q --no-edit feat/a && G push -q origin main )
author_B origin15 wt-B15 4

# --- THE FIXTURE PLAN --------------------------------------------------------
# Authored on feat/b so it enters the branch diff: `_in_scope_files` walks
# `origin/main...HEAD` with NO path filter, so a release plan is in R3 scope like
# any other markdown the branch touched. Synthetic and hermetic — it exists only
# inside $(mktemp -d), so no file under the real `release/releases/plans/` is read
# or written by this suite.
#
# Five seeded sites, each individually addressable, each grading one AC:
#   HIST-1      DEV-41   § Deviation Log          AMBIGUOUS  AC1 — the silent case
#   RANGE-IN    DEV-43   § Deviation Log          AMBIGUOUS  AC3 — the range control
#   LIVE-IN     DEV-44   § Deviation Log          AMBIGUOUS  accepted cost, pinned by AC4
#   LIVE-OUT    Step 1   § Implementation Seq.    CITE       AC2 — discrimination
#   LIVE-AFTER  Closing  § Notes (after the close) CITE      AC2 — the CLOSE boundary
#
# LIVE-AFTER is not decoration. It is the ONLY site that distinguishes "the section
# opened" from "the section closed at the next same-or-higher heading". Without it
# R-5 could be implemented as open-and-never-close and every other arm here would
# still pass — the fixture would be measuring nothing about the region's extent.
# The `## Notes` heading deliberately carries no ADR token, because `plan_section`
# includes the terminating heading in its extract.
#
# LIVE-IN is the ACCEPTED COST, seeded so it is pinned rather than discovered: a
# genuine live citation inside the section stops being swept, and the R3 REVIEW
# line naming it is its only detector. A15d asserts that naming.
PLAN15='release/releases/plans/fixture-milestone_RELEASE_PLAN.md'
( cd "$ROOT/wt-B15" && mkdir -p release/releases/plans
  cat > "$PLAN15" <<'EOF'
# Fixture milestone — release plan

## Implementation Sequence

Step 1 blocks on ADR-004 landing before the sweep runs.

## Deviation Log

| # | Deviation | Note |
|---|---|---|
| DEV-41 | prior hop | ADR-004 was renumbered after the sibling merge |
| DEV-43 | range | the block ADR-004–005 moved as a unit |
| DEV-44 | live | blocked on ADR-004 landing |

## Notes

Closing prose cites ADR-004 once more.
EOF
  G add -A >/dev/null && G commit -qm "author the fixture release plan" )

cd "$ROOT/wt-B15" && G fetch -q origin
DRY15="$(python3 release/tools/renumber-adr.py --renumber 4 6 2>&1)"

# --- A15-P1 / A15-P2 PRECONDITIONS -------------------------------------------
# WITHOUT THESE TWO, EVERY ARM BELOW CAN PASS VACUOUSLY, and each names its own
# cause so a failure reads as itself rather than as a cascade.
#
# P1: `_in_scope_files` silently drops non-UTF-8 files (this fixture seeds one via
# author_B) and only ever sees the branch diff. A fixture plan that fell out of R3
# scope for ANY reason would satisfy every "unchanged" assertion below for entirely
# the wrong reason. Measured on the same instrument, BEFORE any such claim — the
# A11/A14 idiom. `dr_lines` keys on the per-file count line, not on the basename:
# the R3 REVIEW block names the same path once per site, so a bare basename grep
# here would conflate "in scope" with "how many rows were named".
assert_eq "A15-P1 SENSITIVITY — the fixture release plan IS in R3 scope" \
  "$(dr_lines "$DRY15" "$PLAN15")" "1"

APPLY15="$(python3 release/tools/renumber-adr.py --renumber 4 6 --apply 2>&1)"; AP15_RC=$?

# P2: R6 rescans every in-scope file for a surviving `ADR-<old>`. If it did not
# consume the three-valued verdict and exclude AMBIGUOUS, the rows R3 deliberately
# left alone would make `dangling` non-empty and revert() would take the WHOLE
# staged move to exit 3 — every arm beneath would fail for a reason that reads as
# unrelated. The cause is named in the label on purpose.
assert_eq "A15-P2 PRECONDITION — the move exits 0 (R6 must exempt AMBIGUOUS, or a spared row reverts the whole staged move)" \
  "$AP15_RC" "0"

# --- A15a AC1 — THE SILENT CASE (load-bearing) --------------------------------
# Asserted as a ROW LITERAL under `grep -cF`, so the arm names ONE site rather than
# reporting a whole-file count. This is the primary arm and the range arm below is
# the control, not the reverse: this row has no incoherent-range signature and
# passes every check the corpus already runs, which is precisely why the corruption
# it models is invisible.
assert_eq "A15a AC1 SILENT CASE — the single-number historical row is NOT rewritten" \
  "$(grep -cF '| DEV-41 | prior hop | ADR-004 was renumbered after the sibling merge |' "$PLAN15")" "1"
assert_eq "A15a AC1 SILENT CASE — and it did not acquire the new number" \
  "$(grep -c 'DEV-41.*ADR-006' "$PLAN15")" "0"
# The zero above is only evidence if the same instrument can return non-zero. The
# local grep is ugrep and a rejected pattern yields a plausible zero, so this arm
# fires positive on the number the row really carries.
assert_eq "A15a AC1 SENSITIVITY — the same instrument returns NON-ZERO for the number that row really carries" \
  "$(grep -c 'DEV-41.*ADR-004' "$PLAN15")" "1"

# --- A15b AC2 — DISCRIMINATION (expected NON-ZERO) ----------------------------
# THE ARM THAT SEPARATES THE FIX FROM DISABLING THE SWEEP ON RELEASE PLANS. Widening
# an exemption by file class would satisfy every A15a arm and be worthless; these
# limbs require a live citation in the same file to still move.
assert_eq "A15b AC2 DISCRIMINATION — a live citation OUTSIDE the section IS swept" \
  "$(grep -cF 'Step 1 blocks on ADR-006 landing before the sweep runs.' "$PLAN15")" "1"
assert_eq "A15b AC2 DISCRIMINATION — and no stale ADR-004 survives outside the Deviation Log" \
  "$(plan_section "$PLAN15" 'Implementation Sequence' | grep -c 'ADR-004')" "0"
assert_eq "A15b AC2 SENSITIVITY — that section extract is non-empty and carries the swept number" \
  "$(plan_section "$PLAN15" 'Implementation Sequence' | grep -c 'ADR-006')" "1"
assert_eq "A15b AC2 CLOSE BOUNDARY — a citation AFTER the section closes is also swept" \
  "$(grep -cF 'Closing prose cites ADR-006 once more.' "$PLAN15")" "1"

# --- A15c AC3 — the RANGE control (not the primary evidence) ------------------
# The observed instance. Its value here is as a CONTROL on a case that was already
# visible: a repair whose only detector is an incoherent range can catch nothing
# but the case that was caught before.
assert_eq "A15c AC3 the straddling range is unchanged, so ADR-006–005 never forms" \
  "$(grep -cF '| DEV-43 | range | the block ADR-004–005 moved as a unit |' "$PLAN15")" "1"
# The GENERAL property, not the specific string — this limb still fires if a future
# change produces a DIFFERENT incoherent range. Two deliberate choices: `python3`,
# because the local grep is ugrep and a rejected back-reference yields a plausible
# zero; and the plain `-` inside the character class, which is safe ONLY because
# this runs over the fixture plan alone — over the real corpus it would match
# `ADR-NNN-<slug>` filenames.
INCOH15="$(python3 - "$PLAN15" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
print(sum(1 for a, b in re.findall(r"ADR-(\d{1,3})[–—-](\d{1,3})", t) if int(a) > int(b)))
PY
)"
assert_eq "A15c AC3 COHERENCE — zero ranges whose low end exceeds their high end" "$INCOH15" "0"
# SENSITIVITY for that zero, on the SAME detector: a genuinely incoherent range must
# make it return 1. A coherence probe whose control also returns zero is broken.
INCOH15_CTL="$(python3 - <<'PY'
import re
t = "the block ADR-006–005 moved as a unit"
print(sum(1 for a, b in re.findall(r"ADR-(\d{1,3})[–—-](\d{1,3})", t) if int(a) > int(b)))
PY
)"
assert_eq "A15c AC3 SENSITIVITY — the SAME detector returns 1 on a genuinely incoherent range" \
  "$INCOH15_CTL" "1"

# --- A15d AC4 — the site is NAMED, and the block is UNCONDITIONAL -------------
# One `R3 REVIEW:` line per ambiguous site, so the count is the site count: three
# rows carry a token inside the region (DEV-41, DEV-43, DEV-44).
assert_eq "A15d AC4 the ambiguous sites are NAMED in the run output (one R3 REVIEW line per site)" \
  "$(printf '%s\n' "$APPLY15" | grep -c 'R3 REVIEW:.*fixture-milestone_RELEASE_PLAN.md')" "3"
# DEV-44 is asserted deliberately. Under the region rule a genuine LIVE citation
# inside the section stops being swept, and no gate reads a bare ADR-NNN out of
# prose — so this review line is that citation's ONLY detector. Pinning it stops a
# later change from quietly dropping the naming and leaving the un-swept row silent.
assert_eq "A15d AC4 the un-swept LIVE row is named too (that line is its only detector)" \
  "$(printf '%s\n' "$APPLY15" | grep -c 'R3 REVIEW:.*DEV-44')" "1"
assert_eq "A15d AC4 a named site is left UNMODIFIED on disk, not merely reported" \
  "$(grep -cF '| DEV-44 | live | blocked on ADR-004 landing |' "$PLAN15")" "1"
# ZERO-SITE CONTROL, and it is what makes the three arms above a measurement. A step
# that is silent when it finds nothing is indistinguishable from a step that did not
# run. Reuses ACT 3's apply output — a worktree with no Deviation Log at all — so the
# control is a different RUN of the same emitter rather than a re-read of this one.
assert_eq "A15d AC4 CONTROL — the REVIEW block is emitted on a run with ZERO ambiguous sites" \
  "$(printf '%s\n' "$APPLY" | grep -c 'R3 REVIEW: 0 ambiguous site(s)')" "1"

# --- A15e AC5 — HOP 2: the row recording hop 1 is the live hazard -------------
G commit -qm "hop 1 (004 -> 006)" >/dev/null
# The hop-1 record is authored the way a real release authors it: BY HAND, and
# INSIDE the Deviation Log table. Appending to the end of the file would land it
# under `## Notes`, where it is correctly a CITE — the arm would then measure the
# section boundary a second time instead of the two-hop case. Written through
# python3 so the pipes need no shell quoting, the idiom `roster_add` and A14's seed
# already use.
python3 - "$PLAN15" <<'PY'
import sys
path = sys.argv[1]
row = "| DEV-45 | hop 1 recorded | ADR-004 was renumbered to ADR-006 |"
lines = open(path, encoding="utf-8").read().split("\n")
for i, line in enumerate(lines):
    if line.startswith("| DEV-44 "):
        lines.insert(i + 1, row)
        break
else:
    sys.exit("FATAL: the fixture plan carries no DEV-44 row to seat the hop-1 record beneath")
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
G add -A >/dev/null && G commit -qm "record hop 1 in the fixture plan's Deviation Log" >/dev/null
# A authors the next mainline record and pushes it, so B's held 006 is a GENUINE
# duplicate at hop 2 rather than a re-run against a static ref. Inlined rather than
# factored out: this act needs it exactly once.
( cd "$ROOT/wt-A15" && printf '# ADR-006 — alpha\n\n## Status\n\nProposed.\n' > core/ADRs/ADR-006-alpha6.md
  G add -A >/dev/null && G commit -qm "author ADR-006 alpha6" >/dev/null && G push -q origin main )
cd "$ROOT/wt-B15" && G fetch -q origin
APPLY15B="$(python3 release/tools/renumber-adr.py --renumber 6 7 --apply 2>&1)"; AP15B_RC=$?
assert_eq "A15e AC5 the SECOND hop exits 0" "$AP15B_RC" "0"
# DEV-45's `ADR-004` is inert at hop 2 (the sweep is keyed on old=6). `ADR-006` is
# the hazard: it is the record's CURRENT number at the moment of hop 2, so a naive
# sweep advances it and the row becomes "ADR-004 was renumbered to ADR-007" —
# syntactically valid, internally consistent, and false. That is #6244's defect at
# its exact trigger, and it exists only at hop 2.
assert_eq "A15e AC5 >=2-PRIOR-HOP — the row recording hop 1 survives hop 2 verbatim" \
  "$(grep -cF '| DEV-45 | hop 1 recorded | ADR-004 was renumbered to ADR-006 |' "$PLAN15")" "1"
assert_eq "A15e AC5 …the record's CURRENT number was not silently advanced to 007" \
  "$(grep -c 'DEV-45.*ADR-007' "$PLAN15")" "0"
assert_eq "A15e AC5 SENSITIVITY — the same instrument returns NON-ZERO for the number that row really carries" \
  "$(grep -c 'DEV-45.*ADR-006' "$PLAN15")" "1"
assert_eq "A15e AC5 DISCRIMINATION — the live citation outside the section still moved at hop 2" \
  "$(grep -cF 'Step 1 blocks on ADR-007 landing before the sweep runs.' "$PLAN15")" "1"
# And the naming is keyed on the number this hop is MOVING, not on the region: the
# three historical rows are inert at hop 2 (they carry 004, not 006), so exactly one
# site is named. An arm expecting the whole region here would be asserting that the
# review block reports rows the sweep never looked at.
assert_eq "A15e AC5 the hop-2 run names EXACTLY the row carrying the number this hop moves" \
  "$(printf '%s\n' "$APPLY15B" | grep -c 'R3 REVIEW:.*fixture-milestone_RELEASE_PLAN.md')" "1"

echo
echo "renumber-adr fixture: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
