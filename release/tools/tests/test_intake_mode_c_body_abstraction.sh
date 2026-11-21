#!/usr/bin/env bash
# test_intake_mode_c_body_abstraction.sh — intake-desk Mode C abstracts every item it
# could file before render, and never auto-files one that still names an operational
# identifier.
#
# WHAT IT ASSERTS. Mode C (Ambient Auto-Log) files to the work tracker with no per-item
# confirm at `automation_level = bounded_auto`, and the default tracker is a public
# repository. Its callers process the operator's own files, so the signal they hand in
# can name an operator file, a project, a client or a person. The governing text is the
# § Body abstraction subsection of operations/skills/intake-desk/SKILL.md § Mode C, plus
# the matching output-contract bullet, failure mode and gate-coverage register row. That
# text is prose, so nothing else executes it. This suite reads each named section and
# fails when:
#   - the subsection is missing, or sits anywhere but ahead of the filing threshold,
#     which itself precedes the automation_level clamp (the threshold renders the body
#     it holds for a release sweep, so the rule must bind before it, at every dial);
#   - it no longer applies to the input before render, or no longer covers the title,
#     the enrich comment and the duplicate guard's search terms;
#   - its allow-list (platform paths it tracks, document type, signal class, confidence,
#     folder tier) or its never-list (operator file names, project / client / person
#     names, operator path segments, quoted operator content) loses a member;
#   - the affected-file test, the private-destination carve, the two-scan self-check
#     with its strip step and not-clean results, or the surface-only outcome (no create
#     command, held-for-sweep bodies marked too) is removed;
#   - the Honest safety read stops naming the rule's missing hook backstop;
#   - output-contract.md § Mode C loses its body-abstraction bullet;
#   - the failure mode is removed or loses one of its five fields, or the skill's
#     domain-specific failure modes drop below three;
#   - the gate-coverage register loses the rule's class 3-O named-gap row.
# A section that cannot be found fails loud, never passes vacuously.
#
# WHAT IT DOES NOT ASSERT. It reads governing prose, not agent behaviour: it proves the
# instructions carry the rule, not that an agent following them will. It is a
# structural regression check on the instruction surface. The fixed-string anchors are
# deliberately literal: a reword of the rule text has to update this suite in the same
# change, which is the point.
#
# CONTROL ARMS. Six mutations of a sandbox copy, each removing or moving one part of the
# rule, must each fail the named assertion. Each is gated by a check that the mutation
# landed (the mutated file differs from the original), so a mutation that silently did
# nothing cannot read as a passing control. An unmutated sandbox copy must pass, which
# proves the sandbox override reaches the suite.
#
# NO EARLY-EXIT READERS. Every awk here reads its whole input from a file argument;
# nothing pipes into a reader that stops early. The repository's SIGPIPE-idiom gate
# scans this whole file.
#
# Portable: bash 3.2 (stock macOS), POSIX awk, no associative arrays. Offline: no gh,
# no network, no writes outside a temp directory it removes.
set -u

# MODE_C_BODY_ROOT lets a caller point the suite at a sandbox copy of the corpus.
ROOT="${MODE_C_BODY_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd -P)}"

SKILL_REL="operations/skills/intake-desk/SKILL.md"
CONTRACT_REL="operations/skills/intake-desk/references/output-contract.md"
REGISTER_REL="core/standards/gate-efficacy-standard.md"

SECTION_RE='^### Body abstraction'
THRESHOLD_RE='^### The filing threshold'
CLAMP_RE='^### The `automation_level` clamp'
SAFETY_RE='^### Honest safety read'
FM_RE='^### Naming an operational identifier in an item bound for a public tracker \(Mode C\) — OUT$'
FM_PARENT_RE='^## Domain-Specific Failure Modes'
FM_HEADING_RE='^### .* — (PROC|OUT|TRIG|HAND|INPUT)$'
CONTRACT_SECTION_RE='^## Mode C — non-interactive emit'
H23_RE='^##{1,2} '
H2_RE='^## '

# extract_section FILE START_RE STOP_RE -> the lines from the first START_RE match up to,
# not including, the next STOP_RE match. Regexes reach awk through ENVIRON, never `-v`:
# `-v` processes backslash escapes and would change what a pattern matches.
extract_section() {
  MCB_START="$2" MCB_STOP="$3" LC_ALL=C awk '
    BEGIN { s = ENVIRON["MCB_START"]; e = ENVIRON["MCB_STOP"]; st = 0 }
    st == 0 && $0 ~ s { st = 1; print; next }
    st == 1 && $0 ~ e { st = 2 }
    st == 1 { print }
  ' "$1"
}

# heading_line FILE RE -> line number of the first match, 0 when none.
heading_line() {
  MCB_RE="$2" LC_ALL=C awk '
    BEGIN { re = ENVIRON["MCB_RE"]; n = 0 }
    n == 0 && $0 ~ re { n = NR }
    END { print n }
  ' "$1"
}

# count_after FILE PARENT_RE RE -> lines matching RE after the first PARENT_RE match.
count_after() {
  MCB_P="$2" MCB_RE="$3" LC_ALL=C awk '
    BEGIN { p = ENVIRON["MCB_P"]; re = ENVIRON["MCB_RE"]; on = 0; n = 0 }
    on == 0 && $0 ~ p { on = 1; next }
    on == 1 && $0 ~ re { n++ }
    END { print n }
  ' "$1"
}

# contains TEXT NEEDLE -> 0 when TEXT holds NEEDLE as a fixed string.
contains() {
  case "$1" in *"$2"*) return 0 ;; esac
  return 1
}

# missing_from TEXT NEEDLE... -> prints each needle TEXT does not hold, one per line.
missing_from() {
  local text="$1"; shift
  local n
  for n in "$@"; do
    contains "$text" "$n" || printf '%s\n' "$n"
  done
}

# run_suite ROOT -> prints one "PASS <id>" or "FAIL <id> — <why>" line per assertion.
run_suite() {
  local root="$1"
  local skill="$root/$SKILL_REL" contract="$root/$CONTRACT_REL" register="$root/$REGISTER_REL"
  local sec miss l_sec l_thr l_clamp safety fm fmcount csec reg_row f

  for f in "$skill" "$contract" "$register"; do
    if [ ! -r "$f" ]; then
      printf 'FAIL files — cannot read %s\n' "$f"
      return 0
    fi
  done

  # A1 — the subsection exists.
  sec="$(extract_section "$skill" "$SECTION_RE" "$H23_RE")"
  if [ -z "$sec" ]; then
    printf 'FAIL section-present — no "### Body abstraction" subsection in %s\n' "$SKILL_REL"
  else
    printf 'PASS section-present\n'
  fi

  # A2 — it binds before the threshold, and so before the clamp.
  l_sec="$(heading_line "$skill" "$SECTION_RE")"
  l_thr="$(heading_line "$skill" "$THRESHOLD_RE")"
  l_clamp="$(heading_line "$skill" "$CLAMP_RE")"
  if [ "$l_sec" -gt 0 ] && [ "$l_thr" -gt 0 ] && [ "$l_clamp" -gt 0 ] \
     && [ "$l_sec" -lt "$l_thr" ] && [ "$l_thr" -lt "$l_clamp" ]; then
    printf 'PASS placement\n'
  else
    printf 'FAIL placement — section line %s, filing threshold %s, clamp %s (want section < threshold < clamp)\n' "$l_sec" "$l_thr" "$l_clamp"
  fi

  # A3 — it applies to the input before render, on every surface that leaves the session.
  miss="$(missing_from "$sec" 'before the render step' 'title' 'enrich comment' 'search terms' 'analysis-workspace-standard.md')"
  if [ -z "$miss" ]; then printf 'PASS reach\n'; else printf 'FAIL reach — missing: %s\n' "$(printf '%s' "$miss" | tr '\n' '|')"; fi

  # A4 — the allow-list.
  miss="$(missing_from "$sec" 'a path it tracks' 'document type' 'signal class' 'confidence' 'folder tier')"
  if [ -z "$miss" ]; then printf 'PASS allow-list\n'; else printf 'FAIL allow-list — missing: %s\n' "$(printf '%s' "$miss" | tr '\n' '|')"; fi

  # A5 — the never-list.
  # Whole phrases, not single words: "client" or "person name" alone also occur in the
  # section's own prose, so a dropped list member would still match a single word.
  miss="$(missing_from "$sec" "the name of a file from the operator's tree" 'a project, client, engagement, program or person name' "a path segment from the operator's tree" 'quoted or paraphrased from operator content')"
  if [ -z "$miss" ]; then printf 'PASS never-list\n'; else printf 'FAIL never-list — missing: %s\n' "$(printf '%s' "$miss" | tr '\n' '|')"; fi

  # A6 — the affected-file test and the destination rule.
  miss="$(missing_from "$sec" 'The affected-file test' 'tracks that path' 'scope: private' 'declares no `[trackers.*]`')"
  if [ -z "$miss" ]; then printf 'PASS affected-file-and-destination\n'; else printf 'FAIL affected-file-and-destination — missing: %s\n' "$(printf '%s' "$miss" | tr '\n' '|')"; fi

  # A7 — the self-scan: both scans, the needle file's strip step (a blank pattern line
  # matches every body), and the results that are not clean.
  miss="$(missing_from "$sec" '--scan-file' 'Exit 2 means the file could not be read' 'is not clean' 'needle file' 'Strip its comment and blank lines first' 'nothing is left after stripping' 'grep -iF -f')"
  if [ -z "$miss" ]; then printf 'PASS self-scan\n'; else printf 'FAIL self-scan — missing: %s\n' "$(printf '%s' "$miss" | tr '\n' '|')"; fi

  # A8 — the outcome: surface-only at every dial with no create command, never
  # auto-filed, a held-for-sweep body marked too, runner named.
  miss="$(missing_from "$sec" 'surface-only at every dial' 'without** the create command' 'never auto-filed' 'held with the same mark' 'Runner: NONE')"
  if [ -z "$miss" ]; then printf 'PASS outcome\n'; else printf 'FAIL outcome — missing: %s\n' "$(printf '%s' "$miss" | tr '\n' '|')"; fi

  # A9 — the Honest safety read names the rule's missing hook backstop.
  safety="$(extract_section "$skill" "$SAFETY_RE" "$H23_RE")"
  miss="$(missing_from "$safety" 'Body abstraction' 'block-scope-segregation.sh' 'no `[trackers.*]`')"
  if [ -n "$safety" ] && [ -z "$miss" ]; then printf 'PASS safety-read\n'; else printf 'FAIL safety-read — missing: %s\n' "$(printf '%s' "${miss:-<section not found>}" | tr '\n' '|')"; fi

  # A10 — output-contract.md § Mode C carries the bullet.
  csec="$(extract_section "$contract" "$CONTRACT_SECTION_RE" "$H2_RE")"
  miss="$(missing_from "$csec" '**Body abstraction' 'every dial' 'surface-only')"
  if [ -n "$csec" ] && [ -z "$miss" ]; then printf 'PASS output-contract\n'; else printf 'FAIL output-contract — missing: %s\n' "$(printf '%s' "${miss:-<section not found>}" | tr '\n' '|')"; fi

  # A11 — the failure mode, with all five fields.
  fm="$(extract_section "$skill" "$FM_RE" "$H23_RE")"
  miss="$(missing_from "$fm" '**Signature (observable signal):**' '**Conditional:**' '**Root cause:**' '**Mitigation:**' '**Principal response vs. junior response:**')"
  if [ -n "$fm" ] && [ -z "$miss" ]; then printf 'PASS failure-mode\n'; else printf 'FAIL failure-mode — missing: %s\n' "$(printf '%s' "${miss:-<failure mode not found>}" | tr '\n' '|')"; fi

  # A12 — the domain-specific failure-mode floor (three or more).
  fmcount="$(count_after "$skill" "$FM_PARENT_RE" "$FM_HEADING_RE")"
  if [ "$fmcount" -ge 3 ]; then printf 'PASS failure-mode-floor\n'; else printf 'FAIL failure-mode-floor — %s domain-specific failure modes (want >= 3)\n' "$fmcount"; fi

  # A13 — the gate-coverage register row: class 3-O, named gap, citing the subsection.
  reg_row="$(LC_ALL=C awk 'index($0, "§ Mode C — Body abstraction") > 0 { print }' "$register")"
  miss="$(missing_from "$reg_row" 'class 3-O' 'NAMED GAP')"
  if [ -n "$reg_row" ] && [ -z "$miss" ]; then printf 'PASS register-row\n'; else printf 'FAIL register-row — missing: %s\n' "$(printf '%s' "${miss:-<row not found>}" | tr '\n' '|')"; fi
}

PASS=0; FAIL=0
pass() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

# --- Main arm: the corpus under ROOT ---
printf 'Main arm — %s\n' "$ROOT"
MAIN_OUT="$(run_suite "$ROOT")"
while IFS= read -r line; do
  case "$line" in
    PASS\ *) pass "${line#PASS }" ;;
    FAIL\ *) fail "${line#FAIL }" ;;
  esac
done <<EOF
$MAIN_OUT
EOF

# --- Control arms: a sandbox copy, mutated one part at a time ---
# Controls run only when the main arm is green: a mutation of text that is already
# missing proves nothing, and a red main arm is the verdict either way.
if [ "$FAIL" -eq 0 ]; then
  printf 'Control arms\n'
  TMP="$(mktemp -d "${TMPDIR:-/tmp}/mcb-test.XXXXXX")" || { fail 'control — cannot create a temp directory'; TMP=""; }
  if [ -n "$TMP" ]; then
    trap 'rm -rf "$TMP"' EXIT

    # make_sandbox NAME -> a fresh sandbox root carrying the three files.
    make_sandbox() {
      local sb="$TMP/$1" rel
      for rel in "$SKILL_REL" "$CONTRACT_REL" "$REGISTER_REL"; do
        mkdir -p "$sb/$(dirname "$rel")"
        cp "$ROOT/$rel" "$sb/$rel"
      done
      printf '%s' "$sb"
    }

    # mutate FILE MODE ARG... -> rewrites FILE in place (python3, isolated mode).
    #   drop-section START_RE    remove from START_RE through the line before the next ## or ### heading
    #   replace OLD NEW          replace the first occurrence of OLD with NEW
    #   move-after START_RE ANCHOR_RE  move the START_RE section to just before the heading after ANCHOR_RE's section
    #   drop-line SUBSTRING      remove every line holding SUBSTRING
    mutate() {
      python3 -I - "$@" <<'PY'
import re, sys
path, mode, args = sys.argv[1], sys.argv[2], sys.argv[3:]
with open(path, encoding="utf-8") as fh:
    lines = fh.read().split("\n")
head = re.compile(r"^##{1,2} ")
def span(start_re):
    rx = re.compile(start_re)
    for i, l in enumerate(lines):
        if rx.search(l):
            j = i + 1
            while j < len(lines) and not head.search(lines[j]):
                j += 1
            return i, j
    return None
if mode == "drop-section":
    s = span(args[0])
    if s:
        del lines[s[0]:s[1]]
elif mode == "replace":
    text = "\n".join(lines).replace(args[0], args[1], 1)
    lines = text.split("\n")
elif mode == "move-after":
    s = span(args[0])
    if s:
        block = lines[s[0]:s[1]]
        del lines[s[0]:s[1]]
        a = span(args[1])
        if a:
            lines[a[1]:a[1]] = block
elif mode == "drop-line":
    lines = [l for l in lines if args[0] not in l]
with open(path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines))
PY
    }

    # control NAME REL EXPECT_ID MODE ARG... -> the mutation must land and EXPECT_ID must FAIL.
    control() {
      local name="$1" rel="$2" expect="$3"; shift 3
      local sb out
      sb="$(make_sandbox "$name")"
      mutate "$sb/$rel" "$@"
      if cmp -s "$ROOT/$rel" "$sb/$rel"; then
        fail "control $name — the mutation did not land (file unchanged)"
        return
      fi
      out="$(run_suite "$sb")"
      case "$out" in
        *"FAIL $expect "*) pass "control $name — $expect fails as it must" ;;
        *) fail "control $name — $expect did not fail on the mutated copy" ;;
      esac
    }

    # Positive control: an unmutated sandbox must pass, or the override is not reaching the suite.
    SB_OK="$(make_sandbox unmutated)"
    OK_OUT="$(run_suite "$SB_OK")"
    case "$OK_OUT" in
      *FAIL*) fail 'control unmutated — an unmutated sandbox copy failed' ;;
      *) pass 'control unmutated — an unmutated sandbox copy passes' ;;
    esac

    control drop-section "$SKILL_REL" section-present drop-section "$SECTION_RE"
    control drop-person "$SKILL_REL" never-list replace 'a project, client, engagement, program or person name' 'a project name'
    control move-after-clamp "$SKILL_REL" placement move-after "$SECTION_RE" "$CLAMP_RE"
    control drop-outcome "$SKILL_REL" outcome replace 'surface-only at every dial' 'surfaced'
    control drop-contract-bullet "$CONTRACT_REL" output-contract drop-line '**Body abstraction'
    control drop-failure-mode "$SKILL_REL" failure-mode drop-section "$FM_RE"
  fi
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
