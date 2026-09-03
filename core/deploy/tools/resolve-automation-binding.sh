#!/bin/bash
# Scheduler ADAPTER — resolves a registered routine to its firing binding.
#
# The executable half of core/standards/scheduler-adapter-routine-firing.md.
# The registry declares WHAT runs (id, cadence, entrypoint); this resolves HOW
# it fires on THIS install, and emits one binding record per routine.
#
# THE DEFECT THIS CLOSES IS A SILENCE. Before this adapter, an install on which
# no scheduler was ever registered produced NO OUTPUT AT ALL — the platform
# asserted a cadence that nothing ran, and nothing said so. Tolerating an absent
# backend is therefore not sufficient: the degraded state must be OBSERVABLE.
# That is what SD-1..SD-4 (spec §4) require and what this script asserts.
#
# ── Resolution is BY REGISTRY `id`, and by nothing else ───────────────────────
# The registry primary key, the `automation_id` marker the entrypoint declares,
# and the name the backend registers are ONE STRING ON THREE SURFACES. Keying on
# the entrypoint path, on file adjacency, or on any alias table would make the
# registry roster VOLUNTARY — and the admission gate's whole forcing function is
# that omitting a row costs the routine its ability to fire. A roster
# declaration with no row, and a row whose entrypoint declares a different id,
# both fail NON-ZERO here.
#
# ── The backend class is DERIVED from `entrypoint`, never stored ──────────────
#   REPO-FIRED     entrypoint is a repository workflow. Its own host fires it on
#                  the cadence written in the workflow, and the operator's
#                  scheduler MUST NOT also register it or it DOUBLE-FIRES. The
#                  selector is not consulted for this class.
#   SESSION-FIRED  any other tracked spec. The routine's work IS an agent session
#                  driving a governed document, so it needs the runtime the
#                  selector names.
# This derivation is what lets the adapter support both real backends while the
# registry names neither (schema §7: the firing backend is CITED, never stored).
#
# ── Value-space resolution: duplicate a PARSE, never a POLICY ─────────────────
#   PARSED  the field list + column order  <- the field table in
#                                             core/schemas/automation-registry-schema.md,
#                                             read through its own declared
#                                             machine-parse contract. The three
#                                             columns used here are located BY
#                                             NAME within that order, never by a
#                                             hardcoded position.
#   PARSED  the scheduler value space      <- the `scheduler` key's enum array in
#                                             core/config/operator-toml-schema.json
#   PARSED  the automation_id marker       <- the entrypoint's own declaration,
#                                             in the two forms the coverage
#                                             predicate defines (frontmatter at
#                                             file position 0, or a `# automation_id:`
#                                             comment in a workflow). List-valued.
#   LITERAL the SESSION-FIRED backend arms <- declared once at SESSION_BACKEND_ARMS
#                                             below, and asserted EQUAL to the
#                                             parsed enum (the AC-3 control).
#
# ── The AC-3 control ships in the artifact, not only in the self-test ─────────
# "The adapter supports the two backends actually in use before any third is
# added — assert NO UNUSED BACKEND ARM SHIPS." A member count cannot assert that:
# it is satisfied by two enum values and one arm. So the control is a SET
# EQUALITY between the enum PARSED from the declaration and the arms this script
# actually implements, checked on EVERY run:
#   an enum value with no arm  -> a backend the config offers and nothing fires
#   an arm with no enum value  -> dead code no operator can select
# Either direction is a scan-surface error. A third backend must land as one
# enum value AND one arm, together, or this fails loud.
#
# Usage (run under the bash interpreter, from the repository root):
#   <no arguments>   resolve EVERY row; one binding record each
#   <id>             resolve one routine by its registry id
#   --self-test      run the F-A..F-J falsification suite
#
# Output: one binding record per routine on stdout; findings as `FAIL:` lines; a
# trailing SUMMARY line. The state token is the FIRST FIELD of every record, so a
# degraded routine and a scheduled routine are distinguishable by READING the
# output rather than by inferring from an exit code (SD-4).
#
# Exit codes (identical to the sibling registry predicates, so the family cannot
# disagree about what an exit means):
#   0 — every resolved routine produced a binding
#   1 — one or more ROUTINE-LEVEL failures (unknown id, unresolvable entrypoint,
#       undeclared/mismatched automation_id, a repo-fired row whose cadence
#       disagrees with the workflow it names)
#   2 — usage error; an ambiguous primary key (two rows sharing an id); a
#       selector value outside the parsed value space. A typo MUST NOT read as
#       "this install has no scheduler" — indistinguishable-from-absent is
#       precisely the failure this adapter exists to make visible.
#   3 — scan-surface error: a scan surface is absent, the schema parses no
#       fields, the registry header disagrees with the schema, 0 rows parsed, the
#       enum parses empty, or the enum and the implemented arms disagree.
#       ALWAYS hard-fail regardless of posture.
#
# SD-3 is why 1 and 2 exist under EVERY selector value: `none` degrades the
# FIRING, never the VALIDATION. A malformed row still fails on a no-scheduler
# install.

set -uo pipefail

# ── Mutation-landed assertion (the class fix) ─────────────────────────────────
# Every arm below mutates a fixture and then grades the gate against the result.
# If a mutation silently fails to land, the gate is graded on an UNMUTATED
# corpus: it correctly reports no finding, and the arm concludes the gate failed
# to fire. That is not hypothetical — an arm on this release did exactly that,
# for a whole release cycle, and the resulting verdict blamed a sound gate.
#
# The assertion is deliberately content-blind. Arms delete rows, inject rows,
# rewrite cells, drop enum values and rename headers; a per-arm check would be
# eight bespoke predicates, each able to be wrong in its own way. Every one of
# those failures presents identically — the fixture comes out byte-for-byte
# unchanged — so one snapshot-and-compare covers the class.
_mut_snap() { _MUT_SNAP="$(cksum < "$1")"; }
_mut_landed() {
  local _f="$1" _arm="$2"
  if [ "$(cksum < "$_f")" = "${_MUT_SNAP:-}" ]; then
    echo "self-test FAIL: ${_arm} — the mutation did not land: ${_f} is byte-identical to its pre-mutation state, so any verdict below would grade an unmutated corpus." >&2
    return 1
  fi
  return 0
}


# Run from the repo root regardless of cwd. This script lives in
# core/deploy/tools/, so the repo root is three levels up — matching its sibling
# predicates in the same directory.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# The operator-instance configuration root. Resolved by the platform's existing
# convention (the same expression check-operator-toml-schema.sh uses), never a
# hardcoded home path: an absolute personal path in a tracked file is a
# portability defect and a depersonalization hazard.
CONFIG_ROOT="${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"

# LITERAL — the SESSION-FIRED backend arms this script implements. Declared once,
# here, and asserted EQUAL to the enum parsed from the declaration on every run
# (the AC-3 control). Adding an arm without its enum value, or an enum value
# without its arm, is a scan-surface error rather than a silent unused branch.
SESSION_BACKEND_ARMS="agent-runtime none"

# The state tokens. Closed set; the FIRST FIELD of every binding record. An
# undifferentiated `OK` is forbidden — it is the exact downgrade that satisfies
# tolerance while asserting nothing (spec §4, SD-4).
TOK_AGENT="AGENT-RUNTIME"
TOK_REPO="GITHUB-ACTIONS"
TOK_MANUAL="MANUAL"

# The spec this script implements. Its SD ids are doc-to-test bound: the
# self-test greps the file for each of them, so a spec that loses a constraint
# reddens the suite instead of silently unbinding it.
REL_SPEC="core/standards/scheduler-adapter-routine-firing.md"

# ─── Glob-free word splitting — the ONE place an unquoted expansion is allowed ─
# Splits $1 into the global array SPLIT_OUT: on the IFS given as $2, or on
# whitespace when $2 is omitted, with pathname expansion DISABLED throughout.
#
# WHY EVERY SPLIT IN THIS FILE ROUTES THROUGH HERE. An unquoted `$var` in a
# for-list OR AN ARRAY ASSIGNMENT is word-split AND THEN pathname-expanded
# against the CALLER'S WORKING DIRECTORY. A cron expression is mostly `*`, so
# `arr=($expr)` turns `0 6 * * *` into 2 + 3N tokens in a directory of N files.
# The sibling conformance predicate SHIPPED with exactly that defect: it rejected
# every well-formed cron row while still printing a healthy-looking SUMMARY, and
# it was INVISIBLE in an empty directory — which is why reading the code passed
# it and only running it caught the always-fires gate.
#
# This file handles cron expressions in EVERY arm, so the exposure is total. Both
# hazardous shapes route here: `for x in $v` and `arr=($v)`. After this file the
# invariant is greppable — exactly one unquoted expansion exists and it is the
# one below.
#
# The prior noglob state is CAPTURED and RESTORED rather than blindly cleared, so
# this cannot silently change a shell mode a caller was relying on.
#
# Callers copy SPLIT_OUT into a local IMMEDIATELY, before any nested call: the
# array is global (bash 3.2, still the system bash on macOS where deploy-time
# checks run, has no namerefs) and the next call overwrites it.
SPLIT_OUT=()
split_noglob() {
  local _text="$1"
  local _had_noglob=0
  case $- in *f*) _had_noglob=1 ;; esac
  set -f
  local IFS
  if [[ $# -ge 2 ]]; then IFS="$2"; else IFS=$' \t\n'; fi
  # shellcheck disable=SC2206  # the deliberate split; pathname expansion is OFF
  SPLIT_OUT=($_text)
  [[ $_had_noglob -eq 1 ]] || set +f
}

# in_set — is $1 a member of the whitespace-separated set $2?
# Routed through split_noglob because the haystacks here are PARSED from owning
# surfaces at run time: "no member will ever contain a glob character" is a
# property of today's data, not of this function.
in_set() {
  local needle="$1" hay="$2" x
  split_noglob "$hay"
  local -a members=(${SPLIT_OUT[@]+"${SPLIT_OUT[@]}"})
  for x in ${members[@]+"${members[@]}"}; do [[ "$x" == "$needle" ]] && return 0; done
  return 1
}

# sorted_set — normalise a whitespace-separated set to sorted, space-joined form
# so two sets can be compared as strings regardless of declaration order.
sorted_set() {
  split_noglob "$1"
  local -a m=(${SPLIT_OUT[@]+"${SPLIT_OUT[@]}"})
  [[ ${#m[@]} -eq 0 ]] && { printf '%s' ""; return 0; }
  printf '%s\n' "${m[@]}" | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'
}

# ─── PARSE: the field list, from the schema's own machine-parse contract ──────
# Rows matching `| <n> | `<field>` |` yield the field name in declaration order.
# Identical to the coverage predicate's reader, so the two cannot disagree about
# what the schema declares.
#   $1 — path to automation-registry-schema.md
parse_schema_fields() {
  awk -F'|' '
    /^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*`/ {
      f = $3
      gsub(/`/, "", f)
      gsub(/^[ \t]+|[ \t]+$/, "", f)
      if (f != "") print f
    }
  ' "$1"
}

# ─── PARSE: the scheduler value space, from the declared key schema ───────────
# Anchored on the `scheduler` key object and stopped at its closing brace, so a
# later key's enum cannot be picked up by accident. Prints one member per line.
#   $1 — path to operator-toml-schema.json
parse_scheduler_enum() {
  awk '
    /"key"[[:space:]]*:[[:space:]]*"scheduler"/ { inkey=1; next }
    inkey && /^[[:space:]]*}/ { inkey=0 }
    inkey && /"enum"[[:space:]]*:/ { inenum=1 }
    inenum {
      line=$0
      if (line ~ /\[/) sub(/.*\[/, "", line)
      done_here = (line ~ /\]/)
      if (done_here) sub(/\].*/, "", line)
      n=split(line, parts, ",")
      for (i=1; i<=n; i++) {
        v=parts[i]
        gsub(/[[:space:]"]/, "", v)
        if (v != "") print v
      }
      if (done_here) { exit }
    }
  ' "$1"
}

# ─── The registry table ───────────────────────────────────────────────────────
# Emits the `## Routines` table: the header as `HDR<US>...`, each data row as
# `ROW<US>...`, <US> being ASCII 0x1f, which no cell can contain. The table ends
# at the first line not beginning with `|`, so prose after it is never swept in.
#   $1 — path to registry.md
parse_routines_table() {
  awk -F'|' '
    BEGIN { US = sprintf("%c", 31); sec = 0; seen_hdr = 0; in_tbl = 0 }
    /^##[[:space:]]+Routines[[:space:]]*$/ { sec = 1; next }
    sec == 0 { next }
    in_tbl == 1 && $0 !~ /^\|/ { exit }
    $0 !~ /^\|/ { next }
    $0 ~ /^\|[[:space:]]*:?-+/ { next }
    {
      in_tbl = 1
      out = ""
      for (i = 2; i < NF; i++) {
        c = $i
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

# ─── PARSE: the automation_id marker declared by an entrypoint ────────────────
# The marker DEFINITION is the coverage predicate's, reproduced as a PARSE and
# never as a second POLICY: form (a) frontmatter at file position 0, form (b) a
# `# automation_id:` comment at column 0 in a workflow. LIST-VALUED in both
# forms, with a bare scalar accepted as a one-element list. Prints one id per
# line.
#   $1 — path to the entrypoint file
entrypoint_declared_ids() {
  local _f="$1"
  case "$_f" in
    *.yml|*.yaml)
      awk '
        /^#[[:space:]]*automation_id:[[:space:]]*/ {
          v = $0
          sub(/^#[[:space:]]*automation_id:[[:space:]]*/, "", v)
          gsub(/^\[|\]$/, "", v)
          n = split(v, parts, ",")
          for (i = 1; i <= n; i++) {
            t = parts[i]
            gsub(/[`"'"'"']/, "", t)
            gsub(/^[ \t]+|[ \t]+$/, "", t)
            if (t != "") print t
          }
        }
      ' "$_f"
      ;;
    *)
      awk '
        FNR == 1 { fm = ($0 == "---") ? 1 : 0; next }
        fm != 1 { next }
        $0 == "---" { fm = 0; next }
        /^automation_id:[[:space:]]*/ {
          v = $0
          sub(/^automation_id:[[:space:]]*/, "", v)
          gsub(/^\[|\]$/, "", v)
          n = split(v, parts, ",")
          for (i = 1; i <= n; i++) {
            t = parts[i]
            gsub(/[`"'"'"']/, "", t)
            gsub(/^[ \t]+|[ \t]+$/, "", t)
            if (t != "") print t
          }
        }
      ' "$_f"
      ;;
  esac
}

# ─── PARSE: a workflow's OWN schedule ─────────────────────────────────────────
# Non-comment `cron:` values only, so a workflow that merely DISCUSSES a cron in
# its header comment is never read as its schedule. Prints one expression per
# line, quotes stripped.
#   $1 — path to the workflow
workflow_cron() {
  awk '
    /^[[:space:]]*#/ { next }
    /cron:/ {
      v = $0
      sub(/^.*cron:[[:space:]]*/, "", v)
      gsub(/[`"'"'"']/, "", v)
      sub(/[[:space:]]*#.*$/, "", v)
      gsub(/^[ \t]+|[ \t]+$/, "", v)
      if (v != "") print v
    }
  ' "$1"
}

# ─── The selector ─────────────────────────────────────────────────────────────
# Reads `[adapters].scheduler` from the operator instance file. READ FRESH at
# every call, never cached: an operator may change runtimes between two firings,
# and a cached selector fires the backend that is no longer there while the
# routine looks healthy.
#
# AN ABSENT FILE, OR AN ABSENT KEY, RESOLVES TO `none` — never to an error. That
# is the pre-existing state of every install that has not yet taken the key, and
# it is a SUPPORTED state (spec §3), not a crash.
#   $1 — path to the operator.toml under test
read_selector() {
  local _op="$1" _v=""
  if [[ -f "$_op" ]]; then
    _v="$(/usr/bin/grep -m1 -E '^[[:space:]]*scheduler[[:space:]]*=' "$_op" 2>/dev/null)"
    _v="${_v#*=}"
    _v="${_v%%#*}"
    # strip surrounding whitespace and quotes without a glob-exposed split
    _v="$(printf '%s' "$_v" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//")"
  fi
  [[ -z "$_v" ]] && _v="none"
  printf '%s' "$_v"
}

# ─── The resolve operation ────────────────────────────────────────────────────
# Taking every scan surface as a PARAMETER is what makes the self-test hermetic
# AND what makes it exercise the same code path as a live run: it points these at
# a mutated COPY of the live population, never at a fixture-only second path that
# could pass while the real one breaks.
#   $1 — repo root (entrypoint resolution base)
#   $2 — registry.md under test
#   $3 — automation-registry-schema.md under test  (PARSE: field list)
#   $4 — operator-toml-schema.json under test      (PARSE: value space)
#   $5 — operator.toml under test                  (the selector)
#   $6 — OPTIONAL: a single routine id to resolve; empty means every row
run_resolve() {
  local repo_root="$1" registry_md="$2" schema_md="$3" decl_json="$4" op_toml="$5"
  local want_id="${6:-}"
  local US
  US="$(printf '\037')"

  # ── Scan surfaces present.
  if [[ ! -f "$registry_md" ]]; then
    echo "FAIL:  scan-surface error — automation registry not found: $registry_md (a moved or deleted registry must fail loud, not skip)" >&2
    return 3
  fi
  if [[ ! -f "$schema_md" ]]; then
    echo "FAIL:  scan-surface error — automation registry schema not found: $schema_md (the field list is PARSED from it; without it this adapter has no column order to resolve against)" >&2
    return 3
  fi
  if [[ ! -f "$decl_json" ]]; then
    echo "FAIL:  scan-surface error — operator key declaration not found: $decl_json (the scheduler value space is PARSED from it; a private copy would be a second source of truth that drifts silently)" >&2
    return 3
  fi

  # ── PARSE the value space, and run the AC-3 control on it.
  local -a ENUM=()
  local _e
  while IFS= read -r _e; do [[ -n "$_e" ]] && ENUM+=("$_e"); done < <(parse_scheduler_enum "$decl_json")
  if [[ ${#ENUM[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — parsed 0 enum members for [adapters].scheduler from $decl_json. The key is absent or its declared shape changed; an adapter that resolves its value space there must fail loud rather than fall back to a private copy." >&2
    return 3
  fi
  local enum_set arms_set
  enum_set="$(sorted_set "${ENUM[*]}")"
  arms_set="$(sorted_set "$SESSION_BACKEND_ARMS")"
  if [[ "$enum_set" != "$arms_set" ]]; then
    echo "FAIL:  scan-surface error — the AC-3 no-unused-arm control fired. The [adapters].scheduler value space declared in $decl_json and the backend arms this adapter implements are not the same set." >&2
    echo "       declared enum:   $enum_set" >&2
    echo "       implemented arms: $arms_set" >&2
    echo "       An enum value with no arm is a backend the config offers and nothing fires; an arm with no enum value is dead code no operator can select. A new backend lands as one enum value AND one arm, together." >&2
    return 3
  fi

  # ── PARSE the field list; the registry header must equal it, IN ORDER. An
  # unordered-but-complete header is still fatal: a positional reader fills the
  # wrong column and can still read green.
  local -a FIELDS=()
  local _f
  while IFS= read -r _f; do [[ -n "$_f" ]] && FIELDS+=("$_f"); done < <(parse_schema_fields "$schema_md")
  if [[ ${#FIELDS[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — parsed 0 fields from $schema_md. The schema's field table is absent or its declared row form changed." >&2
    return 3
  fi

  local -a RAW=()
  local _r
  while IFS= read -r _r; do [[ -n "$_r" ]] && RAW+=("$_r"); done < <(parse_routines_table "$registry_md")
  if [[ ${#RAW[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — found no '## Routines' table in $registry_md. The section is missing, renamed, or its table shape broke." >&2
    return 3
  fi
  local hdr="${RAW[0]}"
  if [[ "$hdr" != HDR* ]]; then
    echo "FAIL:  scan-surface error — could not read the '## Routines' header row in $registry_md." >&2
    return 3
  fi
  local hdr_norm="${hdr#HDR${US}}"
  hdr_norm="${hdr_norm//${US}/ }"
  local want_cols="${FIELDS[*]}"
  if [[ "$hdr_norm" != "$want_cols" ]]; then
    echo "FAIL:  scan-surface error — the '## Routines' header does not equal the field list parsed from $schema_md, in order." >&2
    echo "       schema:   $want_cols" >&2
    echo "       registry: $hdr_norm" >&2
    return 3
  fi

  # ── The three columns this adapter reads, located BY NAME in the parsed order.
  local id_idx=-1 cad_idx=-1 ep_idx=-1 _i
  for ((_i = 0; _i < ${#FIELDS[@]}; _i++)); do
    [[ "${FIELDS[$_i]}" == "id" ]] && id_idx=$_i
    [[ "${FIELDS[$_i]}" == "cadence" ]] && cad_idx=$_i
    [[ "${FIELDS[$_i]}" == "entrypoint" ]] && ep_idx=$_i
  done
  if [[ $id_idx -lt 0 || $cad_idx -lt 0 || $ep_idx -lt 0 ]]; then
    echo "FAIL:  scan-surface error — the schema's field list is missing one of id/cadence/entrypoint (id=$id_idx cadence=$cad_idx entrypoint=$ep_idx). This adapter binds on those three; without them it cannot resolve anything and must not read green." >&2
    return 3
  fi

  # ── ROWS.
  local -a ROW_IDS=() ROW_CADS=() ROW_EPS=()
  local _line _c
  for ((_i = 1; _i < ${#RAW[@]}; _i++)); do
    _line="${RAW[$_i]}"
    [[ "$_line" == ROW* ]] || continue
    _line="${_line#ROW${US}}"
    local -a cells=()
    # printf with a TRAILING NEWLINE on purpose: without it the final `read`
    # returns non-zero and the loop body never runs, silently dropping the LAST
    # cell.
    while IFS= read -r _c; do cells+=("$_c"); done < <(printf '%s\n' "$_line" | tr "$US" '\n')
    ROW_IDS+=("${cells[$id_idx]:-<empty>}")
    ROW_CADS+=("${cells[$cad_idx]:-<empty>}")
    ROW_EPS+=("${cells[$ep_idx]:-<empty>}")
  done
  if [[ ${#ROW_IDS[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — parsed 0 routine rows from $registry_md (expected >=1; the registry ships seeded, so an empty parse means the table broke or the rows were removed)." >&2
    return 3
  fi

  # ── An ambiguous primary key is a broken join, not a routine-level finding.
  # The adapter refuses to guess which row a backend should fire.
  local _a _b _n
  for ((_i = 0; _i < ${#ROW_IDS[@]}; _i++)); do
    _a="${ROW_IDS[$_i]}"
    _n=0
    for _b in ${ROW_IDS[@]+"${ROW_IDS[@]}"}; do [[ "$_a" == "$_b" ]] && _n=$((_n + 1)); done
    if [[ $_n -gt 1 ]]; then
      echo "FAIL:  ambiguous primary key — routine id '$_a' appears on $_n rows of $registry_md. The id is the join every consumer resolves against; the adapter refuses to guess which row a backend should fire." >&2
      return 2
    fi
  done

  # ── The selector. Read fresh; validated against the PARSED value space.
  local selector
  selector="$(read_selector "$op_toml")"
  if ! in_set "$selector" "${ENUM[*]}"; then
    echo "FAIL:  selector out of range — [adapters].scheduler is '$selector', which is outside the declared value space (${enum_set// /, })." >&2
    echo "       This is a HARD ERROR and never a silent fallback to 'none': a typo must not read as 'this install has no scheduler'. Indistinguishable-from-absent is the failure this adapter exists to make visible." >&2
    return 2
  fi

  # ── Resolve.
  local findings=0 emitted=0 matched=0
  local id cadence entrypoint klass declared ok_decl wf_crons_n wf_cron
  for ((_i = 0; _i < ${#ROW_IDS[@]}; _i++)); do
    id="${ROW_IDS[$_i]}"
    cadence="${ROW_CADS[$_i]}"
    entrypoint="${ROW_EPS[$_i]}"

    if [[ -n "$want_id" && "$id" != "$want_id" ]]; then continue; fi
    matched=$((matched + 1))

    # The entrypoint must resolve. Without the spec there is nothing to bind to
    # and nothing to bootstrap a registration from.
    if [[ ! -f "$repo_root/$entrypoint" ]]; then
      echo "FAIL:  unresolvable entrypoint — routine '$id' names '$entrypoint', which resolves to no file under the repository root. A binding would point a backend at nothing."
      findings=$((findings + 1))
      continue
    fi

    # INT-3, both mismatch directions. The join is on the VALUE, never on file
    # adjacency: a row that names the wrong spec would otherwise fire the WRONG
    # ROUTINE while every presence-only check read green.
    ok_decl=false
    declared=""
    while IFS= read -r _c; do
      [[ -z "$_c" ]] && continue
      declared="$declared $_c"
      [[ "$_c" == "$id" ]] && ok_decl=true
    done < <(entrypoint_declared_ids "$repo_root/$entrypoint")
    if [[ "$ok_decl" != true ]]; then
      if [[ -z "${declared// /}" ]]; then
        echo "FAIL:  entrypoint declares no automation_id — routine '$id' names '$entrypoint', which claims no routine identity. The entrypoint must declare the row's own id, so a row cannot drift onto the wrong document."
      else
        echo "FAIL:  automation_id mismatch — routine '$id' names '$entrypoint', which declares '${declared# }' instead. The adapter binds on the VALUE, never on file adjacency; a binding here would fire the wrong routine."
      fi
      findings=$((findings + 1))
      continue
    fi

    # The backend class, DERIVED from the entrypoint. Never stored, never a field.
    case "$entrypoint" in
      .github/workflows/*.yml|.github/workflows/*.yaml) klass="REPO-FIRED" ;;
      *) klass="SESSION-FIRED" ;;
    esac

    if [[ "$klass" == "REPO-FIRED" ]]; then
      # SELF-FIRING. The host runs it on the cadence written in the workflow, so
      # the operator's scheduler must NOT also register it or it double-fires.
      # The row MIRRORS the workflow's value, and the two are ASSERTED EQUAL
      # rather than left to drift — this is the falsifiable conformance
      # assertion: change either side and this reddens.
      local -a WFC=()
      while IFS= read -r _c; do [[ -n "$_c" ]] && WFC+=("$_c"); done < <(workflow_cron "$repo_root/$entrypoint")
      wf_crons_n=${#WFC[@]}
      if [[ $wf_crons_n -eq 0 ]]; then
        echo "FAIL:  repo-fired routine has no schedule — routine '$id' names workflow '$entrypoint', which declares no cron. A repo-fired row asserts the host fires it on a cadence; without one the row claims a schedule that does not exist."
        findings=$((findings + 1))
        continue
      fi
      wf_cron="${WFC[0]}"
      if [[ "$wf_cron" != "$cadence" ]]; then
        echo "FAIL:  cadence disagrees with the firing workflow — routine '$id' declares cadence '$cadence' but '$entrypoint' fires on '$wf_cron'. A repo-fired row MIRRORS the value the host already enforces; the two are asserted equal rather than left to drift."
        findings=$((findings + 1))
        continue
      fi
      printf '%-14s %s  cron=%s  workflow=%s\n' "$TOK_REPO" "$id" "'$wf_cron'" "$entrypoint"
      emitted=$((emitted + 1))
      continue
    fi

    # SESSION-FIRED. Here, and only here, the selector decides.
    case "$selector" in
      none)
        # SD-1 tolerance + SD-4 distinguishability. NOT an error, NOT silence:
        # a per-routine record carrying the literal token and the exact
        # invocation, so degraded-but-working is readable rather than inferred.
        printf '%-14s %s  not scheduled on this install (scheduler="none"); invoke: run the routine declared at %s\n' \
          "$TOK_MANUAL" "$id" "$entrypoint"
        emitted=$((emitted + 1))
        ;;
      agent-runtime)
        # SD-2 non-degeneracy: a FULLY-POPULATED binding. The task name is the
        # registry id (INT-3: one string on three surfaces), the cron is the
        # row's cadence VERBATIM, and the prompt is a thin bootstrap citing the
        # entrypoint rather than a copy of the routine's behaviour.
        #
        # DECLARED, NEVER VERIFIED: this adapter cannot read out-of-tree
        # registration state, so this record means "bound to a backend", never
        # "registered and will fire". Registration liveness is unasserted by any
        # surface today, and saying so is what stops a clean run from being read
        # as a liveness guarantee.
        printf '%-14s %s  cron=%s  task=%s  entrypoint=%s\n' \
          "$TOK_AGENT" "$id" "'$cadence'" "'$id'" "$entrypoint"
        emitted=$((emitted + 1))
        ;;
      *)
        # Unreachable: the selector was validated against the PARSED enum above,
        # and the enum was asserted equal to the implemented arms. Present so a
        # future arm added to only one of the two surfaces cannot fall through
        # silently.
        echo "FAIL:  scan-surface error — selector '$selector' passed value-space validation but has no implemented arm. The AC-3 control should have caught this; both surfaces must move together." >&2
        return 3
        ;;
    esac
  done

  # ── A named id that matched no row. THE INT-3 BOUND MADE EXECUTABLE: omit the
  # row and the routine cannot be bound to any backend, so it cannot be
  # registered, so it cannot fire. The bypass costs the capability at the seam,
  # not merely at the gate.
  if [[ -n "$want_id" && $matched -eq 0 ]]; then
    echo "FAIL:  no registry row for '$want_id' — this routine cannot be bound to any backend. Add its routine-spec row to the registry, or stop declaring it."
    echo "SUMMARY: selector='$selector'; 0 of ${#ROW_IDS[@]} rows matched '$want_id'; 1 FAIL"
    return 1
  fi

  if [[ $findings -gt 0 ]]; then
    echo "SUMMARY: selector='$selector'; $matched routine(s) resolved, $emitted binding(s) emitted; $findings FAIL"
    return 1
  fi
  echo "SUMMARY: selector='$selector'; $matched routine(s) resolved, $emitted binding(s) emitted; 0 FAIL"
  return 0
}

# ─── Self-test ────────────────────────────────────────────────────────────────
# The falsification suite for SD-1..SD-4, AC-1 and the AC-3 control.
#
# WHY EACH ARM MUTATES A COPY OF THE LIVE POPULATION. A fixture-only suite can
# pass while the real scan surface has broken, and the sibling predicates adopted
# the live-copy rule for exactly that reason. The suite REQUIRES the live
# population to be non-empty before any arm runs, so a probe that has stopped
# discriminating fails the job instead of reporting a clean it can no longer tell
# from a real one.
#
# THE GRADING RULE. SD-2 and SD-4 are graded on STDOUT CONTENT, never on an exit
# code. A tolerance rule graded on exit status alone would pass today, pass after
# a correct seam ships, and pass after a VIOLATING seam ships — it is
# indistinguishable from an unconditional zero.
self_test() {
  local tmp pass=0 rc out
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  local LIVE_REG="$REPO_ROOT/core/automations/registry.md"
  local LIVE_SCHEMA="$REPO_ROOT/core/schemas/automation-registry-schema.md"
  local LIVE_DECL="$REPO_ROOT/core/config/operator-toml-schema.json"
  local LIVE_SPEC="$REPO_ROOT/$REL_SPEC"

  # ── Arm F-J: ANTI-VACUITY. Every other arm mutates a copy of this population,
  # so a suite that ran against an empty one would assert nothing while reporting
  # success. This runs FIRST.
  local _p
  for _p in "$LIVE_REG" "$LIVE_SCHEMA" "$LIVE_DECL" "$LIVE_SPEC"; do
    if [[ ! -f "$_p" ]]; then
      echo "self-test FAIL (F-J): live scan surface absent: $_p — every arm mutates a copy of the live population, so an absent surface means the suite asserts nothing." >&2
      return 1
    fi
  done
  local -a LIVE_ROWS=()
  local _l
  while IFS= read -r _l; do [[ "$_l" == ROW* ]] && LIVE_ROWS+=("$_l"); done < <(parse_routines_table "$LIVE_REG")
  if [[ ${#LIVE_ROWS[@]} -lt 2 ]]; then
    echo "self-test FAIL (F-J): the live registry parsed ${#LIVE_ROWS[@]} row(s); the suite needs at least 2 (one repo-fired, one session-fired) to exercise both classes. A population this small means the arms below cannot discriminate." >&2
    return 1
  fi
  pass=$((pass + 1))

  # ── Arm F-I: the doc-to-test binding. The spec's SD ids are load-bearing; a
  # spec that loses one must redden the suite rather than silently unbind it.
  local _sd
  for _sd in SD-1 SD-2 SD-3 SD-4; do
    if ! /usr/bin/grep -q -- "$_sd" "$LIVE_SPEC"; then
      echo "self-test FAIL (F-I): $REL_SPEC does not carry '$_sd'. The constraint ids are doc-to-test bound; renumbering them breaks the binding this arm exists to hold." >&2
      return 1
    fi
  done
  pass=$((pass + 1))

  # ── Working copies. mkdir -p over the live tree's shape so entrypoints resolve.
  mkdir -p "$tmp/tree" "$tmp/cfg"
  cp -R "$REPO_ROOT/core" "$tmp/tree/core" 2>/dev/null || true
  mkdir -p "$tmp/tree/.github/workflows"
  cp -R "$REPO_ROOT/.github/workflows/." "$tmp/tree/.github/workflows/" 2>/dev/null || true
  # Stage every OTHER subtree the live registry's entrypoints actually reference.
  # Deriving the copy set from the population — rather than naming subtrees —
  # is what keeps this fixture correct when a later row points somewhere new.
  # A hardcoded list was complete for the 2-row population this was written
  # against and silently incomplete once 6 rows landed under release/.
  while IFS= read -r _ep; do
    [[ -n "$_ep" ]] || continue
    [[ -f "$REPO_ROOT/$_ep" ]] || continue
    mkdir -p "$tmp/tree/$(dirname "$_ep")"
    cp "$REPO_ROOT/$_ep" "$tmp/tree/$_ep" 2>/dev/null || true
  done < <(awk -F'|' '/^\| `/ {gsub(/^[ \t]*`|`[ \t]*$/,"",$5); print $5}' "$LIVE_REG")
  local REG="$tmp/tree/core/automations/registry.md"
  local SCH="$tmp/tree/core/schemas/automation-registry-schema.md"
  local DEC="$tmp/tree/core/config/operator-toml-schema.json"
  if [[ ! -f "$REG" || ! -f "$SCH" || ! -f "$DEC" ]]; then
    echo "self-test FAIL: could not stage a working copy of the live population under $tmp." >&2
    return 1
  fi

  # Selector fixtures. Three files, so no arm has to edit config mid-run.
  printf '%s\n' "[adapters]" 'scheduler = "agent-runtime"' > "$tmp/cfg/agent.toml"
  printf '%s\n' "[adapters]" 'scheduler = "none"'          > "$tmp/cfg/none.toml"
  printf '%s\n' "[adapters]" 'scheduler = "qqzz-bogus"'    > "$tmp/cfg/bogus.toml"
  printf '%s\n' "[adapters]" 'ai_tool = "claude-code"'     > "$tmp/cfg/absent.toml"

  # Identify one session-fired and one repo-fired live row to assert against.
  local US; US="$(printf '\037')"
  local sess_id="" sess_cad="" sess_ep="" repo_id="" repo_ep=""
  local -a FLD=()
  local _x
  while IFS= read -r _x; do [[ -n "$_x" ]] && FLD+=("$_x"); done < <(parse_schema_fields "$SCH")
  local ii=-1 ic=-1 ie=-1 _k
  for ((_k = 0; _k < ${#FLD[@]}; _k++)); do
    [[ "${FLD[$_k]}" == "id" ]] && ii=$_k
    [[ "${FLD[$_k]}" == "cadence" ]] && ic=$_k
    [[ "${FLD[$_k]}" == "entrypoint" ]] && ie=$_k
  done
  local _row
  for ((_k = 0; _k < ${#LIVE_ROWS[@]}; _k++)); do
    _row="${LIVE_ROWS[$_k]#ROW${US}}"
    local -a cc=()
    local _cv
    while IFS= read -r _cv; do cc+=("$_cv"); done < <(printf '%s\n' "$_row" | tr "$US" '\n')
    case "${cc[$ie]}" in
      .github/workflows/*) [[ -z "$repo_id" ]] && { repo_id="${cc[$ii]}"; repo_ep="${cc[$ie]}"; } ;;
      *) [[ -z "$sess_id" ]] && { sess_id="${cc[$ii]}"; sess_cad="${cc[$ic]}"; sess_ep="${cc[$ie]}"; } ;;
    esac
  done
  if [[ -z "$sess_id" || -z "$repo_id" ]]; then
    echo "self-test FAIL (F-J): the live registry does not carry one row of EACH class (session-fired='$sess_id' repo-fired='$repo_id'). Both arms of the adapter must be reachable on real data, which is the AC-3 'no unused arm' claim asserted against the population rather than the code." >&2
    return 1
  fi
  pass=$((pass + 1))

  # ── Arm F-A — SD-2 NON-DEGENERACY, graded on STDOUT CONTENT.
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/agent.toml" "$sess_id" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "self-test FAIL (F-A/SD-2): agent-runtime resolve of '$sess_id' exited $rc, expected 0. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -q "^${TOK_AGENT}" <<<"$out"; then
    echo "self-test FAIL (F-A/SD-2): no ${TOK_AGENT} record emitted for '$sess_id'. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -qF -- "task='${sess_id}'" <<<"$out"; then
    echo "self-test FAIL (F-A/SD-2): the binding does not carry task='${sess_id}'. The task name IS the registry id — one string on three surfaces. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -qF -- "cron='${sess_cad}'" <<<"$out"; then
    echo "self-test FAIL (F-A/SD-2): the binding does not carry the row's cadence verbatim (expected cron='${sess_cad}'). A populated binding is what forbids the unconditionally-zero resolver SD-1 alone would accept. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -qF -- "entrypoint=${sess_ep}" <<<"$out"; then
    echo "self-test FAIL (F-A/SD-2): the binding does not cite the row's entrypoint (${sess_ep}). Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-A2 — AC-1, the end-to-end repo-fired arm, and its FALSIFICATION.
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/agent.toml" "$repo_id" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "self-test FAIL (F-A2/AC-1): repo-fired resolve of '$repo_id' exited $rc, expected 0. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -q "^${TOK_REPO}" <<<"$out"; then
    echo "self-test FAIL (F-A2/AC-1): no ${TOK_REPO} record for '$repo_id'. A workflow entrypoint is repo-fired and must not consult the selector. Output: $out" >&2; return 1; fi
  local live_wf_cron
  # Capture, then take the first line: no reader closes the pipe on the writer.
  _lwc_all="$(workflow_cron "$tmp/tree/$repo_ep")"
  live_wf_cron="${_lwc_all%%$'\n'*}"
  if [[ -z "$live_wf_cron" ]]; then
    echo "self-test FAIL (F-A2/AC-1): could not read a cron from '$repo_ep'; the equality assertion below would be vacuous." >&2; return 1; fi
  if ! /usr/bin/grep -qF -- "cron='${live_wf_cron}'" <<<"$out"; then
    echo "self-test FAIL (F-A2/AC-1): the emitted cron is not the workflow's own ('${live_wf_cron}'). Output: $out" >&2; return 1; fi
  # FALSIFY: perturb the row's cadence and require the equality assertion to fire.
  # Without this the arm proves only that the two happened to agree today.
  # `index()` rather than a regex: a routine id is matched literally, so no
  # character in it is ever interpreted as a pattern.
  _mut_snap "$REG"
  awk -v id="$repo_id" 'BEGIN{FS=OFS="|"} /^\|/ && index($0, id) { $3=" `9 9 9 9 9` " } { print }' "$REG" > "$tmp/reg-drift.md"
  _mut_landed "$REG" "F-A2 corrupt-a-cron-cell" || return 1
  if ! /usr/bin/grep -q '9 9 9 9 9' "$tmp/reg-drift.md"; then
    echo "self-test FAIL (F-A2): the cadence-drift mutation did not take; the falsification below would be vacuous." >&2; return 1; fi
  out="$(run_resolve "$tmp/tree" "$tmp/reg-drift.md" "$SCH" "$DEC" "$tmp/cfg/agent.toml" "$repo_id" 2>&1)"
  rc=$?
  if [[ $rc -eq 0 ]]; then
    echo "self-test FAIL (F-A2/AC-1 falsification): a row whose cadence DISAGREES with the workflow it names resolved cleanly. The mirror assertion is not discriminating. Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-B — SD-1 TOLERANCE + SD-4 DISTINGUISHABILITY, graded per routine.
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/none.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "self-test FAIL (F-B/SD-1): a no-scheduler install exited $rc, expected 0. An absent backend degrades the FIRING; it is never an error. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -q "^${TOK_MANUAL} .*${sess_id}" <<<"$out"; then
    echo "self-test FAIL (F-B/SD-4): no per-routine ${TOK_MANUAL} record for '$sess_id' under scheduler=none. Silence is the defect this adapter exists to close. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -qF -- "invoke: run the routine declared at ${sess_ep}" <<<"$out"; then
    echo "self-test FAIL (F-B/SD-4): the ${TOK_MANUAL} record does not carry the exact manual invocation. A degraded routine is applicable, unscheduled and INVOCABLE, and the record must say how. Output: $out" >&2; return 1; fi
  # The repo-fired routine must STILL be repo-fired under scheduler=none: it does
  # not consult the selector, so degrading the selector must not degrade it.
  if ! /usr/bin/grep -q "^${TOK_REPO} .*${repo_id}" <<<"$out"; then
    echo "self-test FAIL (F-B): '$repo_id' lost its ${TOK_REPO} binding under scheduler=none. A repo-fired routine does not consult the selector; degrading the selector must not degrade it. Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-B2 — SD-1 with the key ABSENT ENTIRELY. This is the pre-backfill
  # state of every existing install, and it must behave exactly as "none".
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/absent.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "self-test FAIL (F-B2/SD-1): an operator.toml with NO scheduler key exited $rc, expected 0. An absent key resolves to 'none', never to an error. Output: $out" >&2; return 1; fi
  if ! /usr/bin/grep -q "^${TOK_MANUAL}" <<<"$out"; then
    echo "self-test FAIL (F-B2/SD-1): an absent key produced no ${TOK_MANUAL} record. Output: $out" >&2; return 1; fi
  # And with NO operator.toml at all — a fresh clone that has never been installed.
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/does-not-exist.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "self-test FAIL (F-B2/SD-1): a MISSING operator.toml exited $rc, expected 0. Absence of an operator instance is a supported state. Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-C — SD-3, unknown id, run under BOTH selector values.
  local _sel
  for _sel in agent none; do
    out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/${_sel}.toml" "qqzz-no-such-routine" 2>&1)"
    rc=$?
    if [[ $rc -eq 0 ]]; then
      echo "self-test FAIL (F-C/SD-3): an unknown id resolved cleanly under scheduler=${_sel}. 'none' degrades the FIRING, never the VALIDATION — and this exit is the INT-3 bound made executable: omit the row and the routine cannot be bound to any backend. Output: $out" >&2; return 1; fi
  done
  pass=$((pass + 1))

  # ── Arm F-D — SD-3, automation_id mismatch, run under BOTH selector values.
  # Mutate the COPY's entrypoint so it declares a different id, and require the
  # join-on-value to fire. This is the arm that separates a real binding from a
  # row that merely names a real file.
  local mut="$tmp/tree/$sess_ep"
  if [[ ! -f "$mut" ]]; then
    echo "self-test FAIL (F-D): the staged copy has no '$sess_ep' to mutate." >&2; return 1; fi
  /usr/bin/sed -i.bak 's|^automation_id:.*|automation_id: [qqzz-different-routine]|' "$mut" && rm -f "$mut.bak"
  if /usr/bin/grep -q "^automation_id: \[qqzz-different-routine\]" "$mut"; then :; else
    echo "self-test FAIL (F-D): the mutation did not take; the arm below would be vacuous." >&2; return 1; fi
  for _sel in agent none; do
    out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/${_sel}.toml" "$sess_id" 2>&1)"
    rc=$?
    if [[ $rc -eq 0 ]]; then
      echo "self-test FAIL (F-D/SD-3): a row whose entrypoint declares a DIFFERENT automation_id resolved cleanly under scheduler=${_sel}. A binding here would fire the wrong routine. Output: $out" >&2; return 1; fi
  done
  # Restore, and prove the restoration works — otherwise every later arm is
  # asserting against a broken tree and its greens mean nothing.
  cp "$REPO_ROOT/$sess_ep" "$mut"
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/none.toml" "$sess_id" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "self-test FAIL (F-D restore): the restored tree did not resolve cleanly (exit $rc); a red without a restoring green does not show the arm discriminates. Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-E — an out-of-range selector is a HARD ERROR, not a silent 'none'.
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/bogus.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 2 ]]; then
    echo "self-test FAIL (F-E): a selector outside the declared value space exited $rc, expected 2. A typo must not read as 'this install has no scheduler'. Output: $out" >&2; return 1; fi
  if /usr/bin/grep -q "^${TOK_MANUAL}" <<<"$out"; then
    echo "self-test FAIL (F-E): an out-of-range selector emitted a ${TOK_MANUAL} record — it silently degraded to 'none', which is the exact indistinguishability this arm forbids. Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-F — SD-4 NEGATIVE CONTROL. The distinguishability assertion must be
  # able to FAIL. Two limbs: (i) no emitted record may lead with an
  # undifferentiated OK, and (ii) the detector that checks (i) must itself fire
  # on a synthetic OK line — otherwise (i) is a green that means nothing.
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/none.toml" "" 2>&1)"
  if /usr/bin/grep -qE '^OK[[:space:]]' <<<"$out"; then
    echo "self-test FAIL (F-F/SD-4): a binding record led with an undifferentiated 'OK'. The state token is the first field, from a closed set; 'OK' is the downgrade that satisfies tolerance while asserting nothing." >&2; return 1; fi
  if ! /usr/bin/grep -qE '^OK[[:space:]]' <<<"OK             some-routine  resolved"; then
    echo "self-test FAIL (F-F): the SD-4 negative-control DETECTOR did not fire on a synthetic 'OK' line, so the limb above is a zero that proves nothing." >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-G — THE AC-3 CONTROL, falsified. A third enum value with no arm must
  # be caught. This is the arm that makes "no unused backend arm ships" a
  # measurement rather than an assertion: it FIRES when a third arm would ship.
  # awk, not `sed s/.../\n/`: a `\n` in a sed REPLACEMENT is a literal `n` under
  # BSD sed (the system sed on macOS, where deploy-time checks run) and a newline
  # under GNU sed. A fixture that silently corrupts on one platform would make
  # this control vacuous exactly where it is most needed.
  awk '/"agent-runtime",/ { print; print "            \"qqzz-third-backend\","; next } { print }' \
    "$DEC" > "$tmp/decl-third.json"
  if ! /usr/bin/grep -q "qqzz-third-backend" "$tmp/decl-third.json"; then
    echo "self-test FAIL (F-G): could not stage the third-backend declaration; the control below would be vacuous." >&2; return 1; fi
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$tmp/decl-third.json" "$tmp/cfg/none.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 3 ]]; then
    echo "self-test FAIL (F-G/AC-3): a declaration offering a THIRD backend with no implemented arm exited $rc, expected 3. The no-unused-arm control is not discriminating, and a backend the config offers that nothing fires would ship green. Output: $out" >&2; return 1; fi
  # And the converse direction: remove a value the adapter implements.
  _mut_snap "$DEC"
  /usr/bin/sed -e 's|"agent-runtime",||' "$DEC" > "$tmp/decl-short.json"
  _mut_landed "$DEC" "F-decl drop-an-enum-value" || return 1
  out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$tmp/decl-short.json" "$tmp/cfg/none.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 3 ]]; then
    echo "self-test FAIL (F-G/AC-3 converse): a declaration MISSING a value the adapter implements exited $rc, expected 3. An arm no operator can select is dead code and must fail loud. Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-H — scan-surface errors ALWAYS hard-fail regardless of posture.
  _mut_snap "$REG"
  awk 'BEGIN{FS=OFS="|"} /^\| id \| cadence \|/ { $2=" name "; } { print }' "$REG" > "$tmp/reg-renamed.md"
  _mut_landed "$REG" "F-hdr rename-a-header" || return 1
  out="$(run_resolve "$tmp/tree" "$tmp/reg-renamed.md" "$SCH" "$DEC" "$tmp/cfg/none.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 3 ]]; then
    echo "self-test FAIL (F-H): a registry header disagreeing with the schema's field list exited $rc, expected 3. A reformatted scan surface means the adapter resolved against nothing and must not read green. Output: $out" >&2; return 1; fi
  # A schema whose field table is gone: the adapter must NOT fall back to a copy.
  printf '%s\n' "# Schema" "" "no field table here" > "$tmp/schema-gutted.md"
  out="$(run_resolve "$tmp/tree" "$REG" "$tmp/schema-gutted.md" "$DEC" "$tmp/cfg/none.toml" "" 2>&1)"
  rc=$?
  if [[ $rc -ne 3 ]]; then
    echo "self-test FAIL (F-H): a schema parsing 0 fields exited $rc, expected 3. An adapter that resolves its contract from the schema must fail loud rather than fall back to a private copy of the field list. Output: $out" >&2; return 1; fi
  pass=$((pass + 1))

  # ── Arm F-K — the CONTROL ARM. Everything above proves the adapter can FAIL;
  # this proves it can SUCCEED over the whole live population, one record per
  # row, under both selector values. A suite of negatives alone cannot tell a
  # working adapter from one that always fires.
  for _sel in agent none; do
    out="$(run_resolve "$tmp/tree" "$REG" "$SCH" "$DEC" "$tmp/cfg/${_sel}.toml" "" 2>&1)"
    rc=$?
    if [[ $rc -ne 0 ]]; then
      echo "self-test FAIL (F-K control): the unmutated live population did not resolve cleanly under scheduler=${_sel} (exit $rc). Output: $out" >&2; return 1; fi
    local n_rec
    n_rec="$(printf '%s\n' "$out" | /usr/bin/grep -cE "^(${TOK_AGENT}|${TOK_REPO}|${TOK_MANUAL})[[:space:]]")"
    if [[ "$n_rec" -ne "${#LIVE_ROWS[@]}" ]]; then
      echo "self-test FAIL (F-K control): emitted $n_rec binding record(s) for ${#LIVE_ROWS[@]} row(s) under scheduler=${_sel}. Every row must produce exactly one record; a missing record is the silence this adapter exists to close. Output: $out" >&2; return 1; fi
  done
  pass=$((pass + 1))

  echo "self-test OK ($pass assertions passed; ${#LIVE_ROWS[@]} live rows exercised across both backend classes)"
  return 0
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
main() {
  case "${1:-}" in
    --self-test)
      self_test
      exit $?
      ;;
    -h|--help)
      echo "Usage: resolve-automation-binding.sh [<routine-id> | --self-test]" >&2
      exit 2
      ;;
    --*)
      echo "Usage: resolve-automation-binding.sh [<routine-id> | --self-test]" >&2
      exit 2
      ;;
    *)
      run_resolve "$REPO_ROOT" \
        "$REPO_ROOT/core/automations/registry.md" \
        "$REPO_ROOT/core/schemas/automation-registry-schema.md" \
        "$REPO_ROOT/core/config/operator-toml-schema.json" \
        "$CONFIG_ROOT/operator.toml" \
        "${1:-}"
      exit $?
      ;;
  esac
}

main "$@"
