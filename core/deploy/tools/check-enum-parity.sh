#!/bin/bash
# check-enum-parity.sh — Check 68 predicate: a derived surface that RESTATES a
# closed enum declares the identical value set as the standard section that owns it,
# and that section's declared cardinality matches the set it heads.
#
# WHAT IT ASSERTS. For every (derived surface, field) pair registered in
# core/deploy/allowlists/hub-state-enum-parity-map.txt:
#   A1  set equality  — the derived declaration and the standard section enumerate
#                       the same values, order-insensitively.
#   A2  cardinality   — when the standard's heading carries a "(N values)"
#                       parenthetical, N equals the size of the set beneath it.
#
# WHY A2 IS A SEPARATE ARM AND NOT DECORATION. A1 alone is satisfied by a correct
# value set sitting under a stale count: add a 7th value to both sides and the
# heading still reads "(6 values)", every consumer that trusts the count is wrong,
# and A1 is green. The two arms fail independently because they can be wrong
# independently.
#
# WHY THE DERIVED SIDE IS NAMED IN EVERY FINDING. The defect this gate closes sat
# readable in the corpus for months: the template and the standard disagreed on 3 of
# 6 category values, and both were "the" enum to whoever read that file first. A
# finding that says only "mismatch" reproduces the ambiguity that let it persist. The
# message states the symmetric difference in BOTH directions and states which side
# moves — the derived one, always.
#
# TWO DECLARATION FORMS ON THE STANDARD SIDE, because the corpus genuinely carries
# two and narrowing to one was measured to break a live registered row:
#   Form A  an inline field-semantics row —  | `status` | enum: a / b / c | YES | … |
#   Form B  a dedicated enum table, one value per row, the value being the first
#           backticked token in the row (which is column 1 in one live section and
#           column 2 in another — so the extractor keys on the token, not the index).
# Form A wins when a row for the named field exists in the section; otherwise Form B
# reads the FIRST table in the section. "First table" is load-bearing: one live
# section carries a second table (a state-transition table) whose rows would
# otherwise contribute spurious members.
#
# WRAPPED CONTINUATION LINES ARE MANDATORY, NOT AN EDGE CASE. The `category`
# declaration wraps across two lines in the live template today. A line-bounded
# parser reads a TRUNCATED value set from it — which is not a benign miss: it is a
# parser that reports on a set the file does not declare, on the exact surface this
# check was built for. The self-test carries both wrapped arms (WRAP-CLEAN must
# return zero, WRAP-FLAG must name the continuation-line value) so a regression to a
# line-bounded parser cannot pass.
#
# FENCE-AWARE SECTION BOUNDING. Section scans skip fenced code blocks. One live
# standard embeds a `## Pending Approvals` schema example inside a ```markdown
# fence, INSIDE the section being scanned — a fence-blind scan ends the section at
# that line and never reaches the field-semantics table below it, returning an empty
# set that would read as a scan result rather than as the bug it is.
#
# DECLARED COVERAGE BOUNDARY — state it; do not imply more. NOT covered:
#   (a) runtime ledger INSTANCES. They are operator-instance, git-ignored files
#       outside every deploy-check denominator. This gate brings the SEED into
#       conformance, never the instances already seeded from it, and no widening of
#       this check reaches them;
#   (b) surfaces absent from the registry. The registry IS the denominator — an
#       unregistered restatement is invisible here. Mitigated by the registry being
#       small enough to audit by inspection, and by its rows being printed in DENOM;
#   (c) prose paraphrases of an enum that make no `<field> enum:` declaration. A
#       predicate matching free prose against a value set was measured on this
#       corpus and rejected for its false-positive rate;
#   (d) whether the values MEAN the same thing on both sides. This is a lexical set
#       comparison; two surfaces can agree on tokens and disagree on semantics.
#
# POSIX-portable (BSD + GNU): no \b, no GNU-only flags, LC_ALL=C.
#
# CONTRACT
#   Output: one finding per line, `FAIL: <detail>`, plus `DENOM: …` and
#           `SUMMARY: N finding(s)`.
#   Exit:   0 no findings · 1 findings · 3 scan-surface error (fail loud, never green)
#   bash core/deploy/tools/check-enum-parity.sh              # live scan
#   bash core/deploy/tools/check-enum-parity.sh --self-test  # committed fixtures

set -uo pipefail
export LC_ALL=C

REGISTRY_DEFAULT="core/deploy/allowlists/hub-state-enum-parity-map.txt"

# ─── extract_derived <file> <field> ───────────────────────────────────────────
# Emits one value per line from a `^<field> enum: a / b / c` declaration inside an
# HTML comment, CONTINUING across indented wrapped lines. Continuation ends at the
# comment close, a blank line, a non-indented line, or the next `<field> enum:`.
extract_derived() {
  awk -v field="$2" '
    BEGIN { incomment=0; collecting=0; buf=""; decl="^" field " enum:" }
    {
      line = $0
      if (!incomment) { if (line ~ /<!--/) incomment = 1; else next }
      if (collecting) {
        # a continuation is indented, non-blank, not a close, not a new declaration
        if (line ~ /^[ \t]+[^ \t]/ && line !~ /-->/ && line !~ /^[ \t]*[a-z_]+ enum:/) {
          buf = buf " " line
          next
        }
        collecting = 0
      }
      if (line ~ decl) {
        sub(decl, "", line)
        buf = buf " " line
        collecting = 1
        next
      }
      if (line ~ /-->/) { incomment = 0; collecting = 0 }
    }
    END {
      n = split(buf, parts, "/")
      for (i = 1; i <= n; i++) {
        v = parts[i]
        gsub(/`/, "", v)
        gsub(/^[ \t]+|[ \t]+$/, "", v)
        if (v != "") print v
      }
    }
  ' "$1" | sort -u
}

# ─── extract_standard <file> <anchor> <field> ─────────────────────────────────
# Emits `CARD:<n>` (only when the heading declares one) then one `VAL:<value>` per
# member. Fence-aware; section ends at the next heading of same-or-higher level.
extract_standard() {
  awk -v anchor="$2" -v field="$3" '
    function level(s,   n) { n = 0; while (substr(s, n + 1, 1) == "#") n++; return n }
    BEGIN {
      alen = length(anchor); found = 0; lvl = 0; fence = 0; done = 0
      formA = 0; tableseen = 0; intable = 0
      arow = "^[|][ \t]*`" field "`[ \t]*[|][ \t]*enum:"
    }
    {
      line = $0
      if (line ~ /^[ \t]*```/) { fence = !fence; next }
      if (fence) next
      if (!found) {
        if (substr(line, 1, alen) == anchor) {
          found = 1; lvl = level(line)
          if (match(line, /\([0-9]+ values\)/)) {
            c = substr(line, RSTART + 1, RLENGTH - 2); sub(/ values/, "", c)
            print "CARD:" (c + 0)
          }
        }
        next
      }
      if (done) next
      if (line ~ /^#+ / && level(line) <= lvl) { done = 1; next }

      # ── Form A: inline field-semantics declaration for the named field ──
      # Buffered, not printed: Form A OUTRANKS Form B, and the Form A row can appear
      # after other rows of the same table (the field-semantics table lists every
      # field, so `id` precedes `status`). Printing Form B as it is read would emit
      # those earlier field NAMES as if they were enum members — which is exactly
      # what the CLEAN-3 fixture caught. Precedence is resolved at END, once the whole
      # section has been seen, never row-by-row.
      if (line ~ arow && !formA) {
        sub(arow, "", line)
        # cut at the governed " | " cell separator, never a bare "|": a bare-pipe cut
        # truncates on a legitimately escaped pipe inside the cell.
        if ((p = index(line, " | ")) > 0) line = substr(line, 1, p - 1)
        n = split(line, parts, "/")
        for (i = 1; i <= n; i++) {
          v = parts[i]; gsub(/`/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v)
          if (v != "") { formA = 1; avals[++acount] = v }
        }
        next
      }

      # ── Form B: the FIRST table in the section, first backticked token per row ──
      if (line ~ /^[|]/) {
        if (tableseen && !intable) next          # a later table — not ours
        intable = 1; tableseen = 1
        if (line ~ /^[|][ \t]*:?-+/) next        # separator row
        if (match(line, /`[a-z][a-z0-9-]*`/)) {
          v = substr(line, RSTART + 1, RLENGTH - 2)
          bvals[++bcount] = v
        }
        next
      }
      if (intable) intable = 0
    }
    END {
      if (formA) { for (i = 1; i <= acount; i++) print "VAL:" avals[i] }
      else       { for (i = 1; i <= bcount; i++) print "VAL:" bvals[i] }
    }
  ' "$1"
}

# ─── check_pair <derived> <field> <standard> <anchor> ─────────────────────────
# Emits findings on stdout. Returns 0 clean, 1 findings, 3 scan-surface error.
check_pair() {
  local d="$1" field="$2" s="$3" anchor="$4"
  local dvals svals raw card n_s rc=0

  if [ ! -f "$d" ]; then
    echo "SCAN-ERROR: registered derived surface not found: $d"; return 3
  fi
  if [ ! -f "$s" ]; then
    echo "SCAN-ERROR: registered standard not found: $s"; return 3
  fi

  raw=$(extract_standard "$s" "$anchor" "$field")
  card=$(printf '%s\n' "$raw" | sed -n 's/^CARD://p' | head -1)
  svals=$(printf '%s\n' "$raw" | sed -n 's/^VAL://p' | sort -u)
  dvals=$(extract_derived "$d" "$field")

  if [ -z "$svals" ]; then
    echo "SCAN-ERROR: $s section '$anchor' yielded zero values for '$field' — the standard side of the comparison is empty, so a parity verdict here would be vacuous"
    return 3
  fi
  if [ -z "$dvals" ]; then
    echo "SCAN-ERROR: $d declares no '$field enum:' line — the derived side of the comparison is empty, so a parity verdict here would be vacuous"
    return 3
  fi

  # ── A1 set equality ──
  local only_d only_s
  only_d=$(comm -23 <(printf '%s\n' "$dvals") <(printf '%s\n' "$svals") | paste -sd, -)
  only_s=$(comm -13 <(printf '%s\n' "$dvals") <(printf '%s\n' "$svals") | paste -sd, -)
  if [ -n "$only_d" ] || [ -n "$only_s" ]; then
    echo "FAIL: $d field '$field' declares {${only_d:-—}} absent from $s $anchor, and omits {${only_s:-—}} that section declares. The DERIVED side is $d — re-derive it from the standard, never the reverse."
    rc=1
  fi

  # ── A2 declared cardinality ──
  if [ -n "$card" ]; then
    n_s=$(printf '%s\n' "$svals" | wc -l | tr -d ' ')
    if [ "$card" -ne "$n_s" ]; then
      echo "FAIL: $s heading '$anchor' declares ($card values) but the section enumerates $n_s. A correct value set under a stale count is still wrong for every consumer that reads the count."
      rc=1
    fi
  fi
  return $rc
}

# ─── --self-test: SEVEN committed cases, FOUR verdict classes ─────────────────
#
# The two WRAP cases are the reason this harness exists in this shape. WRAP-CLEAN is
# an IN-PARITY declaration that wraps across a continuation line: a line-bounded
# parser reads a truncated set from it and reports a mismatch that is not there, so
# this arm is the one that fails if the wrapped-line handling ever regresses.
# WRAP-FLAG asserts the finding TEXT names the value that lives only on the
# continuation line — a verdict-only assertion would pass on a parser that never read
# that line, because the truncated set mismatches too, just for the wrong reason.
#
# Every case asserts a non-zero body byte-count before its verdict: a 0-byte fixture
# reports "0 findings" and reads as passing while proving nothing. Zero cases parsed
# is exit 3, never a green harness.
self_test() {
  local root rc=0 parsed=0 pass=0
  local flag_pass=0 flag_findings=0 clean_pass=0 wrap_pass=0 err_pass=0
  local -a failures=()

  root=$(mktemp -d 2>/dev/null) || { echo "SELF-TEST: cannot create fixture root"; return 3; }
  trap 'rm -rf "$root"' RETURN
  mkdir -p "$root/std" "$root/drv"

  # ── standards ───────────────────────────────────────────────────────────────
  # S-B: Form B, dedicated enum table, value in column 1, correct cardinality.
  printf '%s\n' \
    '### 9.1 Widget enum (3 values)' '' \
    '| Widget | Definition |' '|---|---|' \
    '| `alpha` | first |' '| `beta` | second |' '| `gamma` | third |' '' \
    '### 9.2 Next section' > "$root/std/formb.md"

  # S-B2: Form B where the value is column 2 and a SECOND table follows in-section,
  # plus a fenced block whose content would end the section if fences were ignored.
  printf '%s\n' \
    '### 9.1 Widget enum (3 values)' '' \
    '```markdown' '### 9.9 Fenced heading that must not end the section' '```' '' \
    '| # | State | Definition |' '|---|---|---|' \
    '| 1 | `alpha` | first |' '| 2 | `beta` | second |' '| 3 | `gamma` | third |' '' \
    '**Transitions:**' '' \
    '| # | From | To |' '|---|---|---|' \
    '| T1 | `zeta` | `omega` |' '' \
    '### 9.2 Next section' > "$root/std/formb2.md"

  # S-A: Form A, inline field-semantics row, no cardinality parenthetical. Carries an
  # ESCAPED pipe in a later cell — the bare-pipe cut would truncate on it.
  printf '%s\n' \
    '### 3.1 Surface A: the queue' '' \
    '| Field | Type | Purpose |' '|---|---|---|' \
    '| `id` | string | identifier |' \
    '| `status` | enum: `alpha` / `beta` / `gamma` | append-only; a \| b |' '' \
    '### 3.2 Next section' > "$root/std/forma.md"

  # S-CARD: correct-looking value set under a STALE declared count.
  printf '%s\n' \
    '### 9.1 Widget enum (2 values)' '' \
    '| Widget | Definition |' '|---|---|' \
    '| `alpha` | first |' '| `beta` | second |' '| `gamma` | third |' '' \
    '### 9.2 Next section' > "$root/std/stalecard.md"

  # ── derived surfaces ────────────────────────────────────────────────────────
  printf '%s\n' '<!--' 'widget enum: alpha / beta / gamma' '-->' > "$root/drv/clean.md"
  printf '%s\n' '<!--' 'widget enum: alpha / delta' '-->'       > "$root/drv/flag.md"
  # WRAP-CLEAN — in parity, wrapped. A line-bounded parser reads {alpha,beta} only.
  printf '%s\n' '<!--' 'widget enum: alpha / beta /' '               gamma' '-->' \
    > "$root/drv/wrapclean.md"
  # WRAP-FLAG — the ONLY divergent value lives on the continuation line.
  printf '%s\n' '<!--' 'widget enum: alpha / beta /' '               zzdelta' '-->' \
    > "$root/drv/wrapflag.md"
  # Form-A counterpart, in parity, with a preceding prose comment line.
  printf '%s\n' '<!-- prose first, then the declaration' 'status enum: alpha / beta / gamma' '-->' \
    > "$root/drv/formaclean.md"

  local rel bytes
  for rel in std/formb.md std/formb2.md std/forma.md std/stalecard.md \
             drv/clean.md drv/flag.md drv/wrapclean.md drv/wrapflag.md drv/formaclean.md; do
    bytes=$(wc -c < "$root/$rel" 2>/dev/null | tr -d ' ')
    [ "${bytes:-0}" -gt 0 ] || failures+=("EMPTY-BODY $rel")
  done

  local out n
  ( cd "$root" || exit 3

    # CLEAN-1 — Form B, exact parity, cardinality correct.
    echo "PARSED"
    out=$(check_pair drv/clean.md widget std/formb.md '### 9.1 Widget enum'); n=$?
    if [ $n -eq 0 ] && [ -z "$out" ]; then echo "PASSCASE CLEAN 0"
    else echo "FAILCASE CLEAN-1 rc=$n out=[$out]"; fi

    # CLEAN-2 — Form B, value in column 2, second in-section table + fenced heading.
    echo "PARSED"
    out=$(check_pair drv/clean.md widget std/formb2.md '### 9.1 Widget enum'); n=$?
    if [ $n -eq 0 ] && [ -z "$out" ]; then echo "PASSCASE CLEAN 0"
    else echo "FAILCASE CLEAN-2 rc=$n out=[$out]"; fi

    # CLEAN-3 — Form A, inline row, escaped pipe in a later cell.
    echo "PARSED"
    out=$(check_pair drv/formaclean.md status std/forma.md '### 3.1 Surface A'); n=$?
    if [ $n -eq 0 ] && [ -z "$out" ]; then echo "PASSCASE CLEAN 0"
    else echo "FAILCASE CLEAN-3 rc=$n out=[$out]"; fi

    # FLAG-1 — symmetric difference in both directions.
    echo "PARSED"
    out=$(check_pair drv/flag.md widget std/formb.md '### 9.1 Widget enum'); n=$?
    if [ $n -eq 1 ] && printf '%s' "$out" | grep -q 'delta' && printf '%s' "$out" | grep -q 'beta,gamma'
    then echo "PASSCASE FLAG 1"
    else echo "FAILCASE FLAG-1 rc=$n out=[$out]"; fi

    # FLAG-2 — A2 cardinality arm: right values, stale declared count.
    echo "PARSED"
    out=$(check_pair drv/clean.md widget std/stalecard.md '### 9.1 Widget enum'); n=$?
    if [ $n -eq 1 ] && printf '%s' "$out" | grep -q '(2 values) but the section enumerates 3'
    then echo "PASSCASE FLAG 1"
    else echo "FAILCASE FLAG-2 rc=$n out=[$out]"; fi

    # WRAP-CLEAN — the arm that fails if the parser goes line-bounded.
    echo "PARSED"
    out=$(check_pair drv/wrapclean.md widget std/formb.md '### 9.1 Widget enum'); n=$?
    if [ $n -eq 0 ] && [ -z "$out" ]; then echo "PASSCASE WRAP 0"
    else echo "FAILCASE WRAP-CLEAN rc=$n out=[$out] (a line-bounded parser reads {alpha,beta} and reports a mismatch that is not there)"; fi

    # WRAP-FLAG — the finding must NAME the continuation-line-only value.
    echo "PARSED"
    out=$(check_pair drv/wrapflag.md widget std/formb.md '### 9.1 Widget enum'); n=$?
    if [ $n -eq 1 ] && printf '%s' "$out" | grep -q 'zzdelta'
    then echo "PASSCASE WRAP 1"
    else echo "FAILCASE WRAP-FLAG rc=$n out=[$out] (the continuation-line value was not read)"; fi

    # ERR-1 — a missing standard must fail LOUD (exit 3), never return a clean zero.
    echo "PARSED"
    out=$(check_pair drv/clean.md widget std/zzq-absent.md '### 9.1 Widget enum'); n=$?
    if [ $n -eq 3 ] && printf '%s' "$out" | grep -q 'SCAN-ERROR'
    then echo "PASSCASE ERR 0"
    else echo "FAILCASE ERR-1 rc=$n out=[$out]"; fi

    # ERR-2 — an anchor that does not resolve must fail LOUD, not report parity.
    echo "PARSED"
    out=$(check_pair drv/clean.md widget std/formb.md '### 9.9 No Such Heading'); n=$?
    if [ $n -eq 3 ] && printf '%s' "$out" | grep -q 'vacuous'
    then echo "PASSCASE ERR 0"
    else echo "FAILCASE ERR-2 rc=$n out=[$out]"; fi
  ) > "$root/.result" 2>&1

  local line
  while IFS= read -r line; do
    case "$line" in
      PARSED) parsed=$((parsed + 1)) ;;
      "PASSCASE CLEAN "*) pass=$((pass + 1)); clean_pass=$((clean_pass + 1)) ;;
      "PASSCASE FLAG "*)  pass=$((pass + 1)); flag_pass=$((flag_pass + 1))
                          flag_findings=$((flag_findings + ${line##* })) ;;
      "PASSCASE WRAP "*)  pass=$((pass + 1)); wrap_pass=$((wrap_pass + 1)) ;;
      "PASSCASE ERR "*)   pass=$((pass + 1)); err_pass=$((err_pass + 1)) ;;
      FAILCASE*|EMPTY-BODY*) failures+=("$line") ;;
    esac
  done < "$root/.result"

  if [ "$parsed" -eq 0 ]; then
    echo "SELF-TEST: 0 cases parsed — the harness examined nothing, which is a defect and not a pass"
    return 3
  fi
  if [ "${#failures[@]}" -gt 0 ]; then
    printf '%s\n' "${failures[@]}"
    rc=1
  fi

  echo "SELF-TEST: ${pass}/${parsed} cases pass — must-flag arm ${flag_pass}/2 observed NON-ZERO (${flag_findings} finding(s)); must-not-flag arm ${clean_pass}/3 observed ZERO; wrapped-continuation arm ${wrap_pass}/2 (clean reads the full set, flag names the continuation-line value); fail-loud arm ${err_pass}/2 returned exit 3 rather than a clean zero"
  return $rc
}

# ─── live scan ────────────────────────────────────────────────────────────────
live_scan() {
  local registry="${1:-$REGISTRY_DEFAULT}"
  local rows=0 findings=0 errs=0 out="" line d field s anchor pair_out pair_rc
  local -a dfiles=() sfiles=()

  if [ ! -f "$registry" ]; then
    echo "SCAN-ERROR: registry not found at $registry — the denominator cannot be established, so a zero here would be untrustworthy"
    return 3
  fi

  while IFS='|' read -r d field s anchor; do
    case "${d:-}" in ''|'#'*) continue ;; esac
    [ -z "${field:-}" ] || [ -z "${s:-}" ] || [ -z "${anchor:-}" ] && {
      echo "SCAN-ERROR: malformed registry row (expected 4 fields): $d|${field:-}|${s:-}|${anchor:-}"
      errs=$((errs + 1)); continue
    }
    rows=$((rows + 1))
    dfiles+=("$d"); sfiles+=("$s")
    pair_out=$(check_pair "$d" "$field" "$s" "$anchor"); pair_rc=$?
    if [ $pair_rc -eq 3 ]; then
      out="${out}${pair_out}"$'\n'; errs=$((errs + 1))
    elif [ $pair_rc -eq 1 ]; then
      out="${out}${pair_out}"$'\n'
      findings=$((findings + $(printf '%s\n' "$pair_out" | wc -l | tr -d ' ')))
    fi
  done < <(sed 's/[[:space:]]*|[[:space:]]*/|/g' "$registry")

  if [ "$rows" -eq 0 ]; then
    echo "SCAN-ERROR: registry $registry declares zero (surface,field) pairs — nothing was examined"
    return 3
  fi

  [ -n "$out" ] && printf '%s' "$out"
  echo "DENOM: ${rows} registered (surface,field) pair(s) across $(printf '%s\n' "${dfiles[@]}" | sort -u | wc -l | tr -d ' ') derived surface(s) / $(printf '%s\n' "${sfiles[@]}" | sort -u | wc -l | tr -d ' ') standard file(s) — registry $registry"
  echo "SUMMARY: ${findings} finding(s)"
  [ "$errs" -gt 0 ] && return 3
  [ "$findings" -eq 0 ] && return 0
  return 1
}

case "${1:-}" in
  --self-test) self_test; exit $? ;;
  "")          live_scan; exit $? ;;
  --registry)  live_scan "${2:-$REGISTRY_DEFAULT}"; exit $? ;;
  *)           echo "usage: $0 [--self-test | --registry <path>]"; exit 3 ;;
esac
