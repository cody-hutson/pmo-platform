#!/usr/bin/env bash
# test_lint_release_corpus_versionless.sh — negative control for the note-content
# lint's version-less (slug-keyed) discovery path.
#
# ─── What is under test ──────────────────────────────────────────────────────
#
# release-notes-standard.md §3.2 states that version-less / slug-keyed release
# notes ARE in scope for the Section 6a content checks (9-12). Two independent
# mechanisms inside lint_release_corpus.py used to skip them:
#
#   1. DISCOVERY — check_note_content() globbed a version-keyed filename pattern,
#      so a slug-keyed name never entered the loop at all.
#   2. THE CUTOVER FLOOR — even once discovered, version_tuple() returns the
#      VERSIONLESS_KEY sentinel for a slug-keyed name, which sorts below
#      NOTE_CONTENT_CUTOVER, so the very next statement dropped it.
#
# The two are in SERIES, not peers. Fixing discovery alone changes nothing
# observable: every newly-discovered note is immediately dropped by the floor.
# This suite therefore asserts the END-TO-END property — a version-less note is
# actually LINTED — rather than either mechanism in isolation.
#
# ─── The vacuity trap this suite exists to avoid ─────────────────────────────
#
# The obvious test is "run the lint against a corpus containing a violating
# version-less note and assert a non-zero exit". THAT TEST IS VACUOUS. The live
# release corpus already exits 1 from unrelated legacy findings, so an
# exit-code-only assertion passes against a completely unfixed lint — it is
# indistinguishable from `return 1`.
#
# The distinguishing observable is narrower and is the whole point of this file:
#
#     THE MUST-FLAG FIXTURE'S PATH MUST APPEAR VERBATIM IN STDOUT.
#
# A lint that cannot see the file cannot name it. Exit code is asserted too, but
# only as a secondary consistency check — it is never the verdict-bearing signal.
#
# ─── Why both arms are required ──────────────────────────────────────────────
#
# Measured against the PRE-FIX code, both arms return zero findings. A control
# whose specificity arm and sensitivity arm both read zero is a BROKEN PROBE:
# the zero is vacuous, not passing. The two fixtures differ ONLY in whether the
# single Section 6a bullet carries its impact beat, so under the fixed code the
# sensitivity arm must go non-zero while the specificity arm stays zero. That
# divergence — not either number alone — is what makes the probe discriminating.
#
# ─── Mechanism ───────────────────────────────────────────────────────────────
#
# lint_release_corpus.py resolves its corpus from its own location
# (WORKSPACE_ROOT = Path(__file__).resolve().parents[3]). Copying the script
# into a scratch tree at the same relative depth therefore re-homes NOTES_DIR
# onto the scratch corpus with NO code change and NO environment variable. The
# suite exercises the REAL script, unmodified.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LINT_SRC="${REPO_ROOT}/core/deploy/tools/lint_release_corpus.py"
FIXTURE_DIR="${SCRIPT_DIR}/fixtures/versionless-notes"

MUST_FLAG="nc-must-flag_RELEASE_NOTES.md"
MUST_NOT_FLAG="nc-must-not-flag_RELEASE_NOTES.md"

PASS=0
FAIL=0

ok()   { printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

TMP_ROOT=""
cleanup() { [[ -n "${TMP_ROOT}" && -d "${TMP_ROOT}" ]] && rm -rf "${TMP_ROOT}"; }
trap cleanup EXIT

printf 'test_lint_release_corpus_versionless.sh — version-less discovery negative control\n\n'

# ─── Preconditions — assert the inputs are real before grading anything ──────
printf 'Preconditions\n'
if [[ -f "${LINT_SRC}" ]]; then
  ok "lint under test resolves at core/deploy/tools/lint_release_corpus.py"
else
  bad "lint under test NOT FOUND at ${LINT_SRC}"
  printf '\nRESULT: FAIL (%d pass / %d fail)\n' "${PASS}" "${FAIL}"
  exit 1
fi

for f in "${MUST_FLAG}" "${MUST_NOT_FLAG}"; do
  if [[ -s "${FIXTURE_DIR}/${f}" ]]; then
    ok "fixture present and NON-EMPTY: ${f} ($(wc -c < "${FIXTURE_DIR}/${f}" | tr -d ' ') B)"
  else
    bad "fixture missing or empty: ${FIXTURE_DIR}/${f}"
  fi
done

# The fixtures must differ ONLY in the property under test. If the must-not-flag
# fixture lost its beat, the specificity arm would go non-zero for the wrong
# reason and the suite would report a false failure.
if grep -qF 'Why it matters' "${FIXTURE_DIR}/${MUST_NOT_FLAG}"; then
  ok "must-not-flag fixture carries the impact beat (the sole differing property)"
else
  bad "must-not-flag fixture LOST its impact beat — specificity arm would be invalid"
fi
if grep -qF 'Why it matters' "${FIXTURE_DIR}/${MUST_FLAG}"; then
  bad "must-flag fixture CARRIES an impact beat — sensitivity arm would be invalid"
else
  ok "must-flag fixture omits the impact beat (the sole differing property)"
fi

if [[ "${FAIL}" -ne 0 ]]; then
  printf '\nRESULT: FAIL (%d pass / %d fail) — preconditions unmet, grading skipped\n' "${PASS}" "${FAIL}"
  exit 1
fi

# ─── Build the scratch corpus ────────────────────────────────────────────────
TMP_ROOT="$(mktemp -d)"
mkdir -p "${TMP_ROOT}/core/deploy/tools"
mkdir -p "${TMP_ROOT}/release/releases/notes/_unversioned"
mkdir -p "${TMP_ROOT}/release/releases/plans"
cp "${LINT_SRC}" "${TMP_ROOT}/core/deploy/tools/"
cp "${FIXTURE_DIR}/${MUST_FLAG}" "${TMP_ROOT}/release/releases/notes/_unversioned/"
cp "${FIXTURE_DIR}/${MUST_NOT_FLAG}" "${TMP_ROOT}/release/releases/notes/_unversioned/"

printf '\nScratch corpus\n'
printf '  root: %s\n' "${TMP_ROOT}"
SEEDED="$(find "${TMP_ROOT}/release/releases/notes" -name '*_RELEASE_NOTES.md' | wc -l | tr -d ' ')"
if [[ "${SEEDED}" -eq 2 ]]; then
  ok "scratch corpus seeded with 2 version-less notes (denominator = 2)"
else
  bad "scratch corpus holds ${SEEDED} notes, expected 2"
fi

# ─── Run the real lint against the scratch corpus ────────────────────────────
OUT="${TMP_ROOT}/lint.out"
python3 "${TMP_ROOT}/core/deploy/tools/lint_release_corpus.py" --check note-content > "${OUT}" 2>&1
LINT_EXIT=$?

printf '\nLint invocation\n'
printf '  python3 <scratch>/core/deploy/tools/lint_release_corpus.py --check note-content\n'
printf '  exit=%d, stdout lines=%d\n' "${LINT_EXIT}" "$(wc -l < "${OUT}" | tr -d ' ')"

# The corpus-path sentinel would make every downstream zero meaningless.
if grep -q 'CORPUS-PATH-UNRESOLVED' "${OUT}"; then
  bad "lint reported CORPUS-PATH-UNRESOLVED — NOTES_DIR did not re-home; every count below would be vacuous"
else
  ok "no CORPUS-PATH-UNRESOLVED sentinel — the scratch corpus resolved"
fi

# ─── ARM 1 · SENSITIVITY — the must-flag path must be NAMED in stdout ────────
#
# This is the verdict-bearing assertion. A lint that cannot discover or cannot
# lint the file cannot print its path, so a match here cannot be produced by a
# lint that is still blind.
printf '\nArm 1 — SENSITIVITY (must-flag)\n'
FLAG_HITS="$(grep -cF "${MUST_FLAG}" "${OUT}")"
if [[ "${FLAG_HITS}" -ge 1 ]]; then
  ok "must-flag path named verbatim in stdout (${FLAG_HITS} finding line(s)) — the lint SEES the version-less note"
else
  bad "must-flag path ABSENT from stdout (0 of 2 fixtures) — the lint is still blind to version-less notes"
fi

WHY_HITS="$(grep -cF 'NOTE-NO-WHY-IT-MATTERS' "${OUT}")"
if [[ "${WHY_HITS}" -ge 1 ]]; then
  ok "expected finding code NOTE-NO-WHY-IT-MATTERS present (${WHY_HITS})"
else
  bad "expected finding code NOTE-NO-WHY-IT-MATTERS absent — a match on the path alone would not prove check 11 ran"
fi

# ─── ARM 2 · SPECIFICITY — the must-not-flag path must NOT appear ────────────
#
# Informative only because Arm 1 went non-zero on an input that differs from
# this one in exactly one property. Read alone, this zero proves nothing.
printf '\nArm 2 — SPECIFICITY (must-not-flag)\n'
NOFLAG_HITS="$(grep -cF "${MUST_NOT_FLAG}" "${OUT}")"
if [[ "${NOFLAG_HITS}" -eq 0 ]]; then
  ok "must-not-flag path absent from stdout (0 hits) — the lint DISCRIMINATES, it does not flag everything"
else
  bad "must-not-flag path appeared ${NOFLAG_HITS} time(s) — the lint flags a conformant note (false positive)"
fi

# ─── ARM 3 · exit code — secondary consistency only, never the verdict ───────
printf '\nArm 3 — exit code (secondary; NEVER the verdict-bearing signal)\n'
if [[ "${LINT_EXIT}" -eq 1 ]]; then
  ok "lint exited 1 as expected with findings present"
else
  bad "lint exited ${LINT_EXIT}, expected 1"
fi

# ─── Broken-probe detector ───────────────────────────────────────────────────
#
# Both arms reading zero is the PRE-FIX shape. Name it explicitly so a future
# regression reports "broken probe" rather than a quiet, plausible-looking pass.
printf '\nProbe validity\n'
if [[ "${FLAG_HITS}" -eq 0 && "${NOFLAG_HITS}" -eq 0 ]]; then
  bad "BROKEN PROBE — both arms returned zero. The specificity zero is VACUOUS, not passing: the lint read neither fixture."
else
  ok "probe is DISCRIMINATING — sensitivity arm non-zero (${FLAG_HITS}), specificity arm zero (${NOFLAG_HITS}), denominator 2"
fi

printf '\nRESULT: %s (%d pass / %d fail)\n' "$([[ ${FAIL} -eq 0 ]] && echo PASS || echo FAIL)" "${PASS}" "${FAIL}"
[[ "${FAIL}" -eq 0 ]]
