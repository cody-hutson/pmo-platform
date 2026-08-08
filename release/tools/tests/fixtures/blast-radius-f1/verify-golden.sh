#!/usr/bin/env bash
set -uo pipefail
# verify-golden.sh — assert the COMMITTED golden against the SPEC constants.
#
# This is a build-time-once assertion, deliberately NOT a CI gate. CI compares the
# committed golden to LIVE tool output (that is F1's job, in
# test_domain_blast_radius.sh). This compares the committed golden to the SPEC that
# says what it must be. Two different assertions with two different lifetimes; the
# second has no runtime home inside a suite that only knows about the first.
#
# VERIFY-NOT-ADOPT PROTOCOL — the reason this script exists:
#   The spec is the authority. The generated artifact is the claim under test.
#   A mismatch is a FINDING TO REPORT, never a constant to update. Editing the
#   expected values below to match an observed output is a golden re-bless at
#   creation — the exact failure this fixture was designed to prevent.
#
#   Order is load-bearing: the INPUT corpus is verified FIRST, so a mismatch
#   localizes to one named corpus file instead of being blamed on the golden.
#
#   Size alone cannot discriminate. Four distinct constructions of this artifact
#   land on exactly 751 bytes with four different digests (unsorted jq, --depth=1,
#   --depth=3, and the canonical build). Treat SIZE-MATCHES-BUT-DIGEST-DIFFERS as
#   the HIGHEST-suspicion signal, not the lowest: it is the signature of a missing
#   `jq -S`, a wrong --depth, or a polluted scan root.
#
#   Deliberately changing the tool's doc output is a DIFFERENT door: regenerate via
#   the --regenerate-golden protocol in README.md, which requires a written reason
#   and a log row. First-build must not use that door.
#
# Run: bash release/tools/tests/fixtures/blast-radius-f1/verify-golden.sh

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GOLDEN="$HERE/normalized-golden.json"
CORPUS="$HERE/corpus"

# ---- SPEC CONSTANTS. Do NOT edit these to match an observed output. ----
expected_sha=2ae110de972f292bc4ecf3a1c7bfa7e8af11f7feca978edc1cf5c44cc5c769c5
expected_bytes=751
expected_manifest='b.md
docs/a.md
docs/target.md'
# path<TAB>bytes<TAB>sha256
expected_corpus='b.md	32	1167e054779d9b09c1b9f0d0b867866e746a3dca1aaaa4b0353d1eb7cdaaa668
docs/a.md	53	87ddd5d17f24b5990508083e522ef86ac1810fb03122d006fedec0985f9137fc
docs/target.md	27	0ef93b8480f6098b559cc9f7b6c4e8b48b9dc2ec6ddfb16df275497ca1344757'

fail=0

echo "=== 1. INPUT CORPUS (verified BEFORE the golden, so a mismatch localizes) ==="
got_manifest="$(cd "$CORPUS" && find . -type f | sed 's|^\./||' | LC_ALL=C sort)"
if [ "$got_manifest" != "$expected_manifest" ]; then
  echo "FIXTURE TRANSCRIPTION DEFECT — the frozen corpus is not the 3-file tree."
  diff <(printf '%s\n' "$expected_manifest") <(printf '%s\n' "$got_manifest") || true
  echo "Do NOT regenerate the golden against a drifted corpus. Fix the corpus."
  exit 1
fi
while IFS=$'\t' read -r p b s; do
  ab="$(wc -c < "$CORPUS/$p" | tr -d ' ')"
  as="$(shasum -a 256 "$CORPUS/$p" | cut -d' ' -f1)"
  if [ "$ab" = "$b" ] && [ "$as" = "$s" ]; then
    printf '  ok   — %-16s %4s B  %s\n' "$p" "$ab" "${as:0:16}…"
  else
    printf '  FAIL — %-16s expected %sB/%s  actual %sB/%s\n' "$p" "$b" "${s:0:16}…" "$ab" "${as:0:16}…"
    fail=1
  fi
done <<< "$expected_corpus"
[ "$fail" -eq 0 ] || { echo "FIXTURE TRANSCRIPTION DEFECT — a corpus file's bytes drifted. Fix the CORPUS, not the golden."; exit 1; }

echo
echo "=== 2. COMMITTED GOLDEN vs SPEC ==="
[ -s "$GOLDEN" ] || { echo "FAIL — golden missing or empty at $GOLDEN"; exit 1; }
actual_sha="$(shasum -a 256 "$GOLDEN" | cut -d' ' -f1)"
actual_bytes="$(wc -c < "$GOLDEN" | tr -d ' ')"
echo "  bytes : $actual_bytes  (spec $expected_bytes)"
echo "  sha256: $actual_sha"
if [ "$actual_sha" != "$expected_sha" ]; then
  echo
  echo "SPEC MISMATCH — do NOT update the expected constant."
  echo "  expected ${expected_bytes}B / ${expected_sha}"
  echo "  actual   ${actual_bytes}B / ${actual_sha}"
  if [ "$actual_bytes" = "$expected_bytes" ]; then
    echo "  ** size matches but digest differs — the HIGHEST-suspicion signal."
    echo "     Check: jq -S present? --depth=2? scan root clean (no stray files)?"
    echo "     Four distinct constructions hit exactly ${expected_bytes} bytes."
  fi
  echo "  This is a finding to report at Stage 7/8, not a constant to edit."
  exit 1
fi
echo "  ok   — golden matches the spec byte count AND digest"

echo
echo "=== 3. STRUCTURAL EXPECTATIONS ==="
chk() { # $1=jq expr  $2=expected  $3=label
  local a; a="$(jq -r "$1" "$GOLDEN")"
  if [ "$a" = "$2" ]; then printf '  ok   — %s (%s)\n' "$3" "$a"
  else printf '  FAIL — %s: expected %s, got %s\n' "$3" "$2" "$a"; fail=1; fi
}
chk '.stats.total_files_scanned' 3     'total_files_scanned'
chk '.stats.first_order_count'   2     'first_order_count'
chk '.stats.second_order_count'  0     'second_order_count'
chk '.schema_version'            1     'schema_version'
chk 'has("cli_version")'         false 'cli_version deleted by normalize()'
chk 'has("scanned_at")'          false 'scanned_at deleted by normalize()'
chk 'has("partial")'             false 'no partial-result marker (fan-out cap did not fire)'

if [ -e "$CORPUS/normalized-golden.json" ]; then
  echo "  FAIL — the golden is INSIDE corpus/. normalize() does not delete"
  echo "         stats.total_files_scanned, so a golden in the scan root is scanned"
  echo "         by the tool under test and inflates the count."
  fail=1
else
  echo "  ok   — golden lives OUTSIDE the scanned corpus"
fi

echo
[ "$fail" -eq 0 ] && { echo "VERIFY-GOLDEN: PASS"; exit 0; } || { echo "VERIFY-GOLDEN: FAIL"; exit 1; }
