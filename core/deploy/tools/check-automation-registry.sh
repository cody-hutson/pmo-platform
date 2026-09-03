#!/bin/bash
# Automation-registry CONFORMANCE predicate.
#
# Asserts that every routine-spec row present in core/automations/registry.md
# satisfies the contract in core/schemas/automation-registry-schema.md: six
# REQUIRED fields, each within its declared value space, plus the cross-field
# cadence-by-trigger matrix.
#
# CONFORMANCE IS NOT COVERAGE. This predicate judges the rows that are PRESENT
# and is deliberately silent about rows that are ABSENT. "Does every automation
# the platform ships have a row?" is a different invariant over a different
# population, asserted by the registry-currency gate. Keeping the two disjoint
# is what makes a PARTIALLY-POPULATED registry a valid state at every
# intermediate commit — a predicate that also asserted coverage would read red
# from the moment it shipped until the last consumer migrated, which is several
# waves of a red check nobody can fix, and that is how a gate gets muted.
#
# VALUE-SPACE RESOLUTION. A value space is PARSED at run time from its owning
# surface when that surface exposes a machine-extractable declaration; otherwise
# it is LITERAL here, cited to its owner and asserted by the self-test. This is
# the platform's existing rule for predicates: duplicate a PARSE, which fails
# loud, never a POLICY, which drifts silent.
#
#   PARSED  automation_level_default  <- the automation_level key's enum array in
#                                        core/config/operator-toml-schema.json
#                                        (cardinality guard: exactly 3)
#   PARSED  reversibility             <- the four tier headings in
#                                        core/specs/reversibility-protocol.md
#                                        (cardinality guard: exactly 4)
#   LITERAL id                        <- the routine-name shape, reused verbatim
#                                        from the skill-name shape carried by
#                                        check-registry-currency.sh (the
#                                        platform's existing machine-executed
#                                        registry primary-key rule)
#   LITERAL cadence                   <- a 5-field cron expression, or `event`
#   LITERAL trigger                   <- time-driven | event-driven | hybrid,
#                                        the cadence documents' own vocabulary
#   TREE    entrypoint                <- resolved against the checkout
#
# Every PARSE arm is CARDINALITY-GUARDED: an extraction returning an empty set
# or an unexpected size is a scan-surface error, never a finding storm and never
# a silent pass. The guard exists because a reformatted source can make an
# extractor return NON-EMPTY garbage that an emptiness check cannot catch.
#
# Usage (run under the bash interpreter, from the repository root):
#   <no arguments>   validate the live registry
#   --self-test      run the fixture suite (1 well-formed + 13 malformed rows,
#                    one per rejection class, plus both PARSE cardinality arms)
#
# Output: one OK/FAIL line per finding on stdout; a trailing SUMMARY line.
# Exit codes (identical to the sibling registry predicate, so the two cannot
# disagree about what an exit means):
#   0 — every parsed row conforms
#   1 — one or more row-level findings (the count is in the SUMMARY line)
#   2 — usage error
#   3 — scan-surface error: the registry is absent, 0 rows parsed, the
#       `## Routines` header does not match the declared 6-column form, or a
#       PARSE arm returned an empty set or the wrong cardinality.
#       ALWAYS hard-fail regardless of posture — a relocated or reformatted
#       source means the predicate ran against nothing and must not read green.

set -uo pipefail

# Run from the repo root regardless of cwd. This script lives in
# core/deploy/tools/, so the repo root is three levels up — matching its sibling
# predicates in the same directory.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# LITERAL value space — the routine-name shape. Reused VERBATIM from the
# skill-name shape in check-registry-currency.sh so the two registries' primary
# keys cannot drift apart. Deliberately strict: lowercase alphanumeric and
# hyphen, first character a letter.
ROUTINE_ID_RE='^[a-z][a-z0-9-]*$'

# LITERAL value space — the trigger vocabulary, prose-homed on the cadence
# documents. The row carries the TOKEN, never a display label.
TRIGGER_VALUES="time-driven event-driven hybrid"

# LITERAL — cadence words a human writes and no adapter can resolve.
CADENCE_WORDS="daily weekly monthly hourly yearly annually nightly quarterly weekdays weekends continuous on-demand manual none never always"

# The declared column order. The header row must match this exactly, in order.
EXPECTED_COLUMNS="id cadence trigger entrypoint automation_level_default reversibility"

# ─── PARSE arm 1: the automation-level enum ───────────────────────────────────
# Reads the `automation_level` key object in the operator-configuration key
# schema and prints its enum members, one per line. Anchored on the key name and
# stopped at that object's closing brace so a later key's enum cannot be picked
# up by accident.
#   $1 — path to operator-toml-schema.json
parse_automation_levels() {
  awk '
    /"key"[[:space:]]*:[[:space:]]*"automation_level"/ { inkey=1; next }
    inkey && /^[[:space:]]*}/ { inkey=0 }
    inkey && /"enum"[[:space:]]*:/ {
      line=$0
      sub(/.*\[/, "", line)
      sub(/\].*/, "", line)
      n=split(line, parts, ",")
      for (i=1; i<=n; i++) {
        v=parts[i]
        gsub(/[[:space:]"]/, "", v)
        if (v != "") print v
      }
      exit
    }
  ' "$1"
}

# ─── PARSE arm 2: the reversibility tier set ──────────────────────────────────
# Reads the tier H3 headings in the reversibility protocol and prints the tier
# names. The heading form is `### <TIER> (<observable threshold>)`.
#   $1 — path to reversibility-protocol.md
parse_reversibility_tiers() {
  sed -nE 's/^###[[:space:]]+([A-Z]+)[[:space:]]*\(.*$/\1/p' "$1"
}

# ─── Row parser ───────────────────────────────────────────────────────────────
# Emits the `## Routines` table. The header row is emitted first as
# `HDR<US>c1<US>...`, then each data row as `ROW<US>c1<US>...<US>c6`, where <US>
# is the ASCII unit separator (0x1f) — a character no cell can contain, so a
# cell holding punctuation can never be mistaken for a field boundary. An empty
# cell is emitted as the literal sentinel `<empty>` so a trailing empty field
# survives the read.
#
# The table ends at the first line that does not begin with `|`, which is the
# markdown table boundary — not at the next heading, so prose following the
# table cannot be swept in.
#   $1 — path to registry.md
parse_routines_table() {
  awk -F'|' '
    BEGIN { US = sprintf("%c", 31); sec = 0; seen_hdr = 0; in_tbl = 0 }
    /^##[[:space:]]+Routines[[:space:]]*$/ { sec = 1; next }
    sec == 0 { next }
    # A table already begun ends at the first non-pipe line.
    in_tbl == 1 && $0 !~ /^\|/ { exit }
    $0 !~ /^\|/ { next }
    # Separator row (|---|---|...) — consume, do not emit.
    $0 ~ /^\|[[:space:]]*:?-+/ { next }
    {
      in_tbl = 1
      out = ""
      for (i = 2; i <= 7; i++) {
        c = (i <= NF) ? $i : ""
        gsub(/^[ \t]+|[ \t]+$/, "", c)
        gsub(/`/, "", c)
        gsub(/^[ \t]+|[ \t]+$/, "", c)
        if (c == "") c = "<empty>"
        out = (i == 2) ? c : out US c
      }
      if (seen_hdr == 0) { seen_hdr = 1; print "HDR" US out; next }
      print "ROW" US out
    }
  ' "$1"
}

# ─── cadence helpers ──────────────────────────────────────────────────────────
# in_range — is $1 an integer within [$2,$3]?
in_range() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
  esac
  [[ "$1" -ge "$2" && "$1" -le "$3" ]]
}

# cron_field_ok — validate one cron field against its positional range.
# Handles `*`, lists (`a,b`), ranges (`a-b`) and steps (`*/n`, `a-b/n`). The step
# suffix is stripped before range-checking, because a step is a stride and not a
# value in the field's own range.
#   $1 — field text   $2 — range low   $3 — range high
cron_field_ok() {
  local field="$1" lo="$2" hi="$3" item base a b
  [[ "$field" =~ ^[0-9*/,-]+$ ]] || return 1
  local IFS=','
  # shellcheck disable=SC2206  # deliberate word-split on the list separator
  local items=($field)
  IFS=' '
  [[ ${#items[@]} -eq 0 ]] && return 1
  for item in "${items[@]}"; do
    [[ -z "$item" ]] && return 1
    base="${item%%/*}"                     # strip any step suffix
    if [[ "$item" == */* ]]; then
      local step="${item#*/}"
      [[ "$step" =~ ^[0-9]+$ ]] || return 1
      [[ "$step" -ge 1 ]] || return 1
    fi
    [[ "$base" == "*" ]] && continue
    if [[ "$base" == *-* ]]; then
      a="${base%%-*}"; b="${base#*-}"
      in_range "$a" "$lo" "$hi" || return 1
      in_range "$b" "$lo" "$hi" || return 1
    else
      in_range "$base" "$lo" "$hi" || return 1
    fi
  done
  return 0
}

# cron_ok — a 5-field cron expression with every field in its positional range.
cron_ok() {
  local expr="$1"
  local -a f=()
  local tok
  for tok in $expr; do f+=("$tok"); done
  [[ ${#f[@]} -eq 5 ]] || return 1
  cron_field_ok "${f[0]}" 0 59 || return 1
  cron_field_ok "${f[1]}" 0 23 || return 1
  cron_field_ok "${f[2]}" 1 31 || return 1
  cron_field_ok "${f[3]}" 1 12 || return 1
  cron_field_ok "${f[4]}" 0 7  || return 1
  return 0
}

# in_set — is $1 a member of the whitespace-separated set $2?
in_set() {
  local needle="$1" hay="$2" x
  for x in $hay; do [[ "$x" == "$needle" ]] && return 0; done
  return 1
}

# ─── The check ────────────────────────────────────────────────────────────────
# Taking every scan surface as a PARAMETER is what makes the self-test hermetic:
# it points these at a mktemp fixture and never at the live checkout.
#   $1 — repo root (entrypoint resolution base)
#   $2 — registry.md under test
#   $3 — operator-toml-schema.json (PARSE arm 1)
#   $4 — reversibility-protocol.md (PARSE arm 2)
run_check() {
  local repo_root="$1" registry_md="$2" level_src="$3" rev_src="$4"

  if [[ ! -f "$registry_md" ]]; then
    echo "FAIL:  scan-surface error — automation registry not found: $registry_md (a moved or deleted registry must fail loud, not skip)" >&2
    return 3
  fi

  # ── PARSE arm 1 + cardinality guard (exactly 3).
  local -a LEVELS=()
  local _l
  while IFS= read -r _l; do [[ -n "$_l" ]] && LEVELS+=("$_l"); done < <(parse_automation_levels "$level_src")
  if [[ ${#LEVELS[@]} -ne 3 ]]; then
    echo "FAIL:  scan-surface error — the automation-level enum extraction returned ${#LEVELS[@]} members from $level_src (expected exactly 3). A restructured owning surface must fail loud, not degrade this predicate to a permissive pass." >&2
    return 3
  fi

  # ── PARSE arm 2 + cardinality guard (exactly 4).
  local -a TIERS=()
  local _t
  while IFS= read -r _t; do [[ -n "$_t" ]] && TIERS+=("$_t"); done < <(parse_reversibility_tiers "$rev_src")
  if [[ ${#TIERS[@]} -ne 4 ]]; then
    echo "FAIL:  scan-surface error — the reversibility tier extraction returned ${#TIERS[@]} members from $rev_src (expected exactly 4). A restructured owning surface must fail loud, not degrade this predicate to a permissive pass." >&2
    return 3
  fi
  local LEVEL_SET="${LEVELS[*]}" TIER_SET="${TIERS[*]}"

  # ── Parse the table.
  local US
  US="$(printf '\037')"
  local -a RAW=()
  local _r
  while IFS= read -r _r; do [[ -n "$_r" ]] && RAW+=("$_r"); done < <(parse_routines_table "$registry_md")

  if [[ ${#RAW[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — found no '## Routines' table in $registry_md. The section is missing, renamed, or its table shape broke." >&2
    return 3
  fi

  # ── Header shape guard: the declared 6-column form, in the declared order.
  local hdr="${RAW[0]}"
  if [[ "$hdr" != HDR* ]]; then
    echo "FAIL:  scan-surface error — could not read the '## Routines' header row in $registry_md." >&2
    return 3
  fi
  local hdr_cells="${hdr#HDR${US}}"
  local hdr_norm="${hdr_cells//${US}/ }"
  if [[ "$hdr_norm" != "$EXPECTED_COLUMNS" ]]; then
    echo "FAIL:  scan-surface error — the '## Routines' header does not match the declared 6-column form." >&2
    echo "       expected: $EXPECTED_COLUMNS" >&2
    echo "       observed: $hdr_norm" >&2
    return 3
  fi

  # ── Zero rows is a scan-surface error, not a pass. The registry ships seeded,
  # so an empty parse can only mean the file was gutted or the table shape broke.
  local -a ROWS=()
  local _i
  for ((_i = 1; _i < ${#RAW[@]}; _i++)); do
    [[ "${RAW[$_i]}" == ROW* ]] && ROWS+=("${RAW[$_i]#ROW${US}}")
  done
  if [[ ${#ROWS[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — parsed 0 routine rows from $registry_md (expected >=1; the registry ships seeded, so an empty parse means the table broke or the rows were removed)." >&2
    return 3
  fi

  local findings=0
  local -a SEEN_IDS=()
  local row id cadence trigger entrypoint level rev

  for row in "${ROWS[@]}"; do
    IFS="$US" read -r id cadence trigger entrypoint level rev <<<"$row"

    local id_label="$id"
    [[ "$id" == "<empty>" ]] && id_label="(row with no id)"

    # ── R-01 — an empty cell in any field. Reported per field, and it SUPPRESSES
    # that field's other checks (including the cross-field matrix) so one empty
    # cell yields one finding rather than a cascade.
    local f val
    for f in id:"$id" cadence:"$cadence" trigger:"$trigger" entrypoint:"$entrypoint" automation_level_default:"$level" reversibility:"$rev"; do
      val="${f#*:}"
      if [[ "$val" == "<empty>" ]]; then
        echo "FAIL:  R-01 empty-cell — routine '$id_label' field '${f%%:*}' is empty. Every field is REQUIRED; an empty cell is a finding, never a default."
        findings=$((findings + 1))
      fi
    done

    # ── id: R-02 charset (R-03 duplicate is cross-row, checked after the loop).
    if [[ "$id" != "<empty>" ]]; then
      if [[ ! "$id" =~ $ROUTINE_ID_RE ]]; then
        echo "FAIL:  R-02 id-charset — routine id '$id' does not match ${ROUTINE_ID_RE}. A routine id is lowercase alphanumeric and hyphen, first character a letter."
        findings=$((findings + 1))
      else
        SEEN_IDS+=("$id")
      fi
    fi

    # ── cadence: ordered R-05 -> R-06 -> R-04; the literal `event` is accepted.
    local cadence_ok=false
    if [[ "$cadence" == "<empty>" ]]; then
      : # already reported as R-01
    elif [[ "$cadence" == "event" ]]; then
      cadence_ok=true
    elif in_set "$(printf '%s' "$cadence" | tr '[:upper:]' '[:lower:]')" "$CADENCE_WORDS"; then
      echo "FAIL:  R-05 cadence-natural-language — routine '$id_label' cadence '$cadence' is a natural-language word no adapter can resolve. Use a 5-field cron expression, or the literal 'event'."
      findings=$((findings + 1))
    elif [[ "$cadence" == TZ=* || "$cadence" =~ [A-Za-z_]+/[A-Za-z_]+ ]]; then
      echo "FAIL:  R-06 cadence-timezone — routine '$id_label' cadence '$cadence' carries a timezone. The local-versus-UTC split is an adapter property, not a routine-spec one; the row declares the expression only."
      findings=$((findings + 1))
    elif ! cron_ok "$cadence"; then
      echo "FAIL:  R-04 cadence-malformed — routine '$id_label' cadence '$cadence' is not a 5-field cron expression with every field in its positional range (minute 0-59, hour 0-23, day-of-month 1-31, month 1-12, day-of-week 0-7)."
      findings=$((findings + 1))
    else
      cadence_ok=true
    fi

    # ── trigger: R-07 vocabulary.
    local trigger_ok=false
    if [[ "$trigger" == "<empty>" ]]; then
      : # already reported as R-01
    elif ! in_set "$trigger" "$TRIGGER_VALUES"; then
      echo "FAIL:  R-07 trigger-vocabulary — routine '$id_label' trigger '$trigger' is outside the closed set (${TRIGGER_VALUES// /, }). The row carries the token, never a display label or a case variant."
      findings=$((findings + 1))
    else
      trigger_ok=true
    fi

    # ── R-08 cross-field matrix. Skipped when either operand already failed, so
    # a malformed cadence does not also manufacture a matrix finding.
    if [[ "$cadence_ok" == true && "$trigger_ok" == true ]]; then
      local is_event=false
      [[ "$cadence" == "event" ]] && is_event=true
      case "$trigger" in
        time-driven)
          if [[ "$is_event" == true ]]; then
            echo "FAIL:  R-08 cadence-trigger-matrix — routine '$id_label' declares trigger 'time-driven' with cadence 'event'. A time-driven routine requires a cron expression."
            findings=$((findings + 1))
          fi
          ;;
        event-driven)
          if [[ "$is_event" == false ]]; then
            echo "FAIL:  R-08 cadence-trigger-matrix — routine '$id_label' declares trigger 'event-driven' with cadence '$cadence'. An event-driven routine requires the literal cadence 'event'."
            findings=$((findings + 1))
          fi
          ;;
        hybrid)
          if [[ "$is_event" == true ]]; then
            echo "FAIL:  R-08 cadence-trigger-matrix — routine '$id_label' declares trigger 'hybrid' with cadence 'event'. One row registers one routine and what it registers is the AUTOMATED limb, so hybrid requires a cron; a hybrid with nothing automated is just event-driven."
            findings=$((findings + 1))
          fi
          ;;
      esac
    fi

    # ── entrypoint: ordered R-10 -> R-11 -> R-09.
    if [[ "$entrypoint" != "<empty>" ]]; then
      if [[ "$entrypoint" == /* || "$entrypoint" == '~'* || "$entrypoint" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; then
        echo "FAIL:  R-10 entrypoint-not-repo-relative — routine '$id_label' entrypoint '$entrypoint' is an absolute path, a home-relative path, or a URL. Use a repo-relative path; an absolute path is also a depersonalization hazard."
        findings=$((findings + 1))
      elif [[ "$entrypoint" == ../* || "$entrypoint" == */../* ]]; then
        echo "FAIL:  R-10 entrypoint-escapes-repo — routine '$id_label' entrypoint '$entrypoint' walks outside the repository. Use a path stated from the repository root."
        findings=$((findings + 1))
      elif [[ "$entrypoint" =~ [[:space:]] || "$entrypoint" == *'['* || "$entrypoint" == *']'* || "$entrypoint" != *.* ]]; then
        echo "FAIL:  R-11 entrypoint-not-a-path — routine '$id_label' entrypoint '$entrypoint' is prose, a markdown link, or otherwise not a bare file path. The field names the tracked spec so the registration cannot drift from it; inlining the behavior is the anti-pattern it prevents."
        findings=$((findings + 1))
      elif [[ ! -f "$repo_root/$entrypoint" ]]; then
        echo "FAIL:  R-09 entrypoint-unresolved — routine '$id_label' entrypoint '$entrypoint' resolves to no tracked file under the repository root."
        findings=$((findings + 1))
      fi
    fi

    # ── automation_level_default: R-12, against the PARSED enum.
    if [[ "$level" != "<empty>" ]] && ! in_set "$level" "$LEVEL_SET"; then
      echo "FAIL:  R-12 automation-level — routine '$id_label' automation_level_default '$level' is outside the declared enum (${LEVEL_SET// /, }). The row declares a CEILING; the autonomy tier is a different axis this contract cites rather than stores."
      findings=$((findings + 1))
    fi

    # ── reversibility: R-13, against the PARSED tier set. A prose tail is
    # rejected: a table cell is a field, not a prose line.
    if [[ "$rev" != "<empty>" ]] && ! in_set "$rev" "$TIER_SET"; then
      echo "FAIL:  R-13 reversibility — routine '$id_label' reversibility '$rev' is outside the declared tier set (${TIER_SET// /, }). The value is a bare uppercase tier with no prose tail, and it is the tier of the routine's ACTIONS at its declared level — not the ship-time tier in the entrypoint document's own frontmatter."
      findings=$((findings + 1))
    fi
  done

  # ── R-03 duplicate primary key, reported once per duplicated id.
  # Every array expansion below uses the `${arr[@]+"${arr[@]}"}` guard: under
  # `set -u`, bash 3.2 — still the system bash on macOS, where deploy-time checks
  # run — treats "${arr[@]}" on an EMPTY array as an unbound variable and aborts.
  # SEEN_IDS is legitimately empty whenever every row's id was empty or
  # charset-invalid, which is exactly a malformed-registry run, so the crash would
  # land on the input this predicate exists to report on.
  local a b dup_reported
  local -a REPORTED=()
  for a in ${SEEN_IDS[@]+"${SEEN_IDS[@]}"}; do
    local n=0
    for b in ${SEEN_IDS[@]+"${SEEN_IDS[@]}"}; do [[ "$a" == "$b" ]] && n=$((n + 1)); done
    if [[ $n -gt 1 ]]; then
      dup_reported=false
      for b in ${REPORTED[@]+"${REPORTED[@]}"}; do [[ "$a" == "$b" ]] && dup_reported=true; done
      if [[ "$dup_reported" == false ]]; then
        echo "FAIL:  R-03 id-duplicate — routine id '$a' appears on $n rows. The id is the registry's primary key; a duplicate makes the join every consumer resolves against ambiguous."
        findings=$((findings + 1))
        REPORTED+=("$a")
      fi
    fi
  done

  if [[ $findings -gt 0 ]]; then
    echo "SUMMARY: ${#ROWS[@]} routine rows, ${#LEVELS[@]} automation levels, ${#TIERS[@]} reversibility tiers; $findings FAIL"
    return 1
  fi
  echo "SUMMARY: ${#ROWS[@]} routine rows, ${#LEVELS[@]} automation levels, ${#TIERS[@]} reversibility tiers; 0 FAIL (every row conforms to the routine-spec contract)"
  return 0
}

# ─── Self-test ────────────────────────────────────────────────────────────────
# AC-3's discriminating proof. A validator whose malformed arm PASSES fails its
# own job, so this runs as a HARD step ahead of any live scan, independent of
# posture: one well-formed row that MUST return zero findings (the control arm),
# thirteen malformed rows one per rejection class each of which MUST produce
# exactly that finding, and both PARSE cardinality guards. Hermetic — a mktemp
# fixture tree, offline, credential-free, never the live checkout.
self_test() {
  local tmp pass=0
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  mkdir -p "$tmp/core/standards" "$tmp/core/config" "$tmp/core/specs"
  printf '%s\n' "# fixture entrypoint" > "$tmp/core/standards/fixture-routine.md"
  printf '%s\n' "# second fixture entrypoint" > "$tmp/core/standards/fixture-two.md"

  # A well-formed operator-configuration key schema: the automation_level key
  # with its 3-member enum, plus a decoy key carrying a DIFFERENT enum after it,
  # so the anchored extraction is proven to read the right object.
  _write_levels() {
    cat > "$tmp/core/config/schema.json" <<'JSON'
{
  "sections": [
    {
      "keys": [
        {
          "key": "automation_level",
          "type": "string",
          "default": "recommend",
          "enum": ["off", "recommend", "bounded_auto"],
          "required": false
        },
        {
          "key": "some_other_key",
          "enum": ["alpha", "beta", "gamma", "delta", "epsilon"],
          "required": false
        }
      ]
    }
  ]
}
JSON
  }

  _write_tiers() {
    printf '%s\n' \
      "# Reversibility" "" "## The Four Tiers" "" \
      "### CHEAP (undo in hours)" "body" "" \
      "### MODERATE (undo in days, minor data loss acceptable)" "body" "" \
      "### EXPENSIVE (undo in weeks, stakeholder impact)" "body" "" \
      "### IRREVERSIBLE (cannot undo)" "body" > "$tmp/core/specs/rev.md"
  }

  # _write_registry <row-line>...  — a registry fixture with the declared header
  # and the given data rows.
  _write_registry() {
    {
      echo "# Automation Registry"
      echo ""
      echo "## Routines"
      echo ""
      echo "| id | cadence | trigger | entrypoint | automation_level_default | reversibility |"
      echo "|---|---|---|---|---|---|"
      local _r
      for _r in "$@"; do echo "$_r"; done
      echo ""
      echo "## Sources of truth"
      echo ""
      echo "| Fact | Where it lives | Why |"
      echo "|---|---|---|"
      echo "| a decoy table row | that must not be parsed as a routine | because the table ended |"
    } > "$tmp/registry.md"
  }

  local GOOD='| `fixture-routine` | `0 6 * * *` | `time-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |'

  local rc out
  # _expect <expected-exit> <expected-finding-substring|-> <label> -- rows...
  _expect() {
    local want_rc="$1" want_sub="$2" label="$3"; shift 3
    [[ "${1:-}" == "--" ]] && shift
    _write_levels; _write_tiers; _write_registry "$@"
    out="$(run_check "$tmp" "$tmp/registry.md" "$tmp/core/config/schema.json" "$tmp/core/specs/rev.md" 2>&1)"
    rc=$?
    if [[ $rc -ne $want_rc ]]; then
      echo "self-test FAIL: $label — expected exit $want_rc, got $rc" >&2
      echo "$out" >&2
      return 1
    fi
    if [[ "$want_sub" != "-" ]]; then
      if ! printf '%s' "$out" | grep -q "$want_sub"; then
        echo "self-test FAIL: $label — expected a '$want_sub' finding; got:" >&2
        echo "$out" >&2
        return 1
      fi
      # Exactly ONE finding: a fixture that trips two classes proves nothing
      # about the class it names.
      local n
      n="$(printf '%s\n' "$out" | grep -c '^FAIL:  R-')"
      if [[ "$n" -ne 1 ]]; then
        echo "self-test FAIL: $label — expected exactly 1 row-level finding, got $n:" >&2
        echo "$out" >&2
        return 1
      fi
    fi
    pass=$((pass + 1))
  }

  # ── The CONTROL ARM. A well-formed row must return ZERO findings. A validator
  # that always fires fails here, which is the half of AC-3 that makes the
  # rejection half mean anything.
  _expect 0 - "CONTROL: well-formed row returns zero findings" -- "$GOOD" || return 1

  # ── One fixture per rejection class. Each must produce EXACTLY its own finding.
  _expect 1 "R-01 empty-cell" "R-01 empty cell" -- \
    '| `fixture-routine` | `0 6 * * *` | `time-driven` | `core/standards/fixture-routine.md` |  | `CHEAP` |' || return 1

  _expect 1 "R-02 id-charset" "R-02 id charset" -- \
    '| `Fixture_Routine` | `0 6 * * *` | `time-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-03 id-duplicate" "R-03 duplicate primary key" -- \
    "$GOOD" \
    '| `fixture-routine` | `0 7 * * *` | `time-driven` | `core/standards/fixture-two.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-04 cadence-malformed" "R-04 malformed cron" -- \
    '| `fixture-routine` | `0 99 * * *` | `time-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-05 cadence-natural-language" "R-05 natural-language cadence" -- \
    '| `fixture-routine` | `daily` | `time-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-06 cadence-timezone" "R-06 timezone in cadence" -- \
    '| `fixture-routine` | `TZ=America/New_York 0 6 * * *` | `time-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-07 trigger-vocabulary" "R-07 trigger outside the enum" -- \
    '| `fixture-routine` | `0 6 * * *` | `scheduled` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-08 cadence-trigger-matrix" "R-08 hybrid without a cron" -- \
    '| `fixture-routine` | `event` | `hybrid` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-09 entrypoint-unresolved" "R-09 entrypoint resolves to nothing" -- \
    '| `fixture-routine` | `0 6 * * *` | `time-driven` | `core/standards/no-such-file.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-10 entrypoint-not-repo-relative" "R-10 absolute entrypoint" -- \
    '| `fixture-routine` | `0 6 * * *` | `time-driven` | `/etc/some-spec.md` | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-11 entrypoint-not-a-path" "R-11 prose entrypoint" -- \
    '| `fixture-routine` | `0 6 * * *` | `time-driven` | run the sweep per the spec | `recommend` | `CHEAP` |' || return 1

  _expect 1 "R-12 automation-level" "R-12 level outside the parsed enum" -- \
    '| `fixture-routine` | `0 6 * * *` | `time-driven` | `core/standards/fixture-routine.md` | `Tier 3` | `CHEAP` |' || return 1

  _expect 1 "R-13 reversibility" "R-13 reversibility with a prose tail" -- \
    '| `fixture-routine` | `0 6 * * *` | `time-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP / Confidence HIGH` |' || return 1

  # ── The cadence-by-trigger matrix is TOTAL: assert the other two rejections
  # and the two remaining valid pairings, so the matrix is proven rather than
  # sampled at its most interesting cell.
  _expect 1 "R-08 cadence-trigger-matrix" "R-08 time-driven with cadence event" -- \
    '| `fixture-routine` | `event` | `time-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1
  _expect 1 "R-08 cadence-trigger-matrix" "R-08 event-driven with a cron" -- \
    '| `fixture-routine` | `0 6 * * *` | `event-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1
  _expect 0 - "matrix: event-driven with cadence event is valid" -- \
    '| `fixture-routine` | `event` | `event-driven` | `core/standards/fixture-routine.md` | `recommend` | `CHEAP` |' || return 1
  _expect 0 - "matrix: hybrid with a cron is valid" -- \
    '| `fixture-routine` | `0 6 * * *` | `hybrid` | `core/standards/fixture-routine.md` | `bounded_auto` | `MODERATE` |' || return 1

  # ── Scan-surface arms. Each must hard-fail at exit 3 rather than read green.
  _write_levels; _write_tiers
  _write_registry "$GOOD"
  rm -f "$tmp/registry.md"
  run_check "$tmp" "$tmp/registry.md" "$tmp/core/config/schema.json" "$tmp/core/specs/rev.md" >/dev/null 2>&1
  rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: absent registry — expected exit 3, got $rc" >&2; return 1; fi

  _write_levels; _write_tiers; _write_registry
  run_check "$tmp" "$tmp/registry.md" "$tmp/core/config/schema.json" "$tmp/core/specs/rev.md" >/dev/null 2>&1
  rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: zero rows parsed — expected exit 3, got $rc" >&2; return 1; fi

  _write_levels; _write_tiers; _write_registry "$GOOD"
  # A header whose columns were renamed or reordered: the shape guard must catch
  # it, because a silently-misaligned parse assigns every value to the wrong
  # field and can still read green.
  sed -i.bak 's/^| id | cadence | trigger |/| name | schedule | trigger |/' "$tmp/registry.md" && rm -f "$tmp/registry.md.bak"
  run_check "$tmp" "$tmp/registry.md" "$tmp/core/config/schema.json" "$tmp/core/specs/rev.md" >/dev/null 2>&1
  rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: renamed header columns — expected exit 3, got $rc" >&2; return 1; fi

  # ── PARSE cardinality guards. A restructured owning surface must fail loud,
  # not degrade the live scan to a permissive pass.
  _write_tiers; _write_registry "$GOOD"
  cat > "$tmp/core/config/schema.json" <<'JSON'
{ "keys": [ { "key": "automation_level", "enum": ["off", "recommend"] } ] }
JSON
  run_check "$tmp" "$tmp/registry.md" "$tmp/core/config/schema.json" "$tmp/core/specs/rev.md" >/dev/null 2>&1
  rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: automation-level cardinality guard — expected exit 3, got $rc" >&2; return 1; fi

  _write_levels; _write_registry "$GOOD"
  printf '%s\n' "# Reversibility" "" "### CHEAP (undo in hours)" "" "### MODERATE (undo in days)" > "$tmp/core/specs/rev.md"
  run_check "$tmp" "$tmp/registry.md" "$tmp/core/config/schema.json" "$tmp/core/specs/rev.md" >/dev/null 2>&1
  rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: reversibility cardinality guard — expected exit 3, got $rc" >&2; return 1; fi

  # ── The PARSE arms read the RIGHT declaration. The decoy key in the fixture
  # carries a 5-member enum; if the extraction were unanchored it would return 5
  # and the cardinality guard would fire on a well-formed surface.
  _write_levels; _write_tiers; _write_registry "$GOOD"
  local -a _lv=()
  local _x
  while IFS= read -r _x; do [[ -n "$_x" ]] && _lv+=("$_x"); done < <(parse_automation_levels "$tmp/core/config/schema.json")
  if [[ ${#_lv[@]} -eq 3 && "${_lv[*]}" == "off recommend bounded_auto" ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: automation-level extraction read the wrong object — got ${#_lv[@]} members: ${_lv[*]:-none}" >&2; return 1; fi

  echo "self-test OK ($pass assertions passed)"
  return 0
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
main() {
  case "${1:-}" in
    --self-test)
      self_test
      exit $?
      ;;
    "")
      run_check "$REPO_ROOT" \
        "$REPO_ROOT/core/automations/registry.md" \
        "$REPO_ROOT/core/config/operator-toml-schema.json" \
        "$REPO_ROOT/core/specs/reversibility-protocol.md"
      exit $?
      ;;
    *)
      echo "Usage: check-automation-registry.sh [--self-test]" >&2
      exit 2
      ;;
  esac
}

main "$@"
