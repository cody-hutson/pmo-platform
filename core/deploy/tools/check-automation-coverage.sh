#!/bin/bash
# Automation-registry COVERAGE predicate — the admission gate.
#
# Asserts that the set of automations the platform SHIPS and the set of
# routine-spec rows in core/automations/registry.md are the same set, in both
# directions, and that every row's entrypoint declares the row's own id.
#
# COVERAGE IS NOT CONFORMANCE, and the two are deliberately separate scripts.
# check-automation-registry.sh judges the rows that are PRESENT against the
# field contract. This predicate judges which rows EXIST AT ALL. A registry can
# be perfectly conformant and completely empty — that is the exact failure the
# registry was created to prevent: cadences declared in prose, none registered,
# and no signal that they were not. A conformance-only gate is green in that
# state. This one is not.
#
#   ROSTER  the automations the corpus DECLARES
#   ROWS    the routine-spec rows the registry CARRIES
#   SCHED   the scheduled workflows in .github/workflows/
#
# ── The four assertions ───────────────────────────────────────────────────────
#   A-01  every ROSTER id has a ROW            an automation shipping unregistered
#   A-02  every ROW id has a ROSTER declaration an orphan row — a registration
#                                              whose routine does not exist
#   A-03  every ROW's entrypoint DECLARES that row's id
#                                              a copy-pasted row pointing at the
#                                              wrong spec, which a presence-only
#                                              check reads as green
#   A-04  every SCHED workflow has a ROW       a scheduled routine that never
#                                              declared itself
#
# ── How an automation DECLARES itself: two forms, both at the file's head ─────
#   (a) a tracked *.md whose FRONTMATTER (the first ---delimited block, at file
#       position 0) carries `automation_id:`
#   (b) a tracked .github/workflows/*.yml carrying a `# automation_id:` comment
#       at column 0
#
# Position is what makes form (a) precise rather than a substring hunt: a fenced
# example inside the schema document is never at file position 0, so the document
# that DEFINES the field can never be mistaken for one that DECLARES it.
#
# Form (b) exists because a scheduled workflow is fired by its own host rather
# than by the operator's scheduler adapter, and the registry schema already
# names that case: a self-firing entrypoint is identified by its own path and
# needs no field. Without form (b) a workflow could carry a row but never
# round-trip, and A-03 would have to special-case it — which is how a gate grows
# an exception that later swallows a real finding.
#
# `automation_id` IS LIST-VALUED. One document may declare more than one
# routine, and at least one already does: the platform health-audit framework
# declares a quarterly cadence and a reactive cadence as separate registrations.
# A scalar field cannot express that without splitting the document, so the value
# is a list. A bare scalar is accepted as a one-element list, because one routine
# per document is the common case and rejecting the natural spelling buys
# nothing. Both forms get the same per-element shape guard.
#
# ── CIAC-2: the field list is PARSED, never copied ────────────────────────────
# The column names and their order come from the field table in
# core/schemas/automation-registry-schema.md at run time, read through that
# document's own declared machine-parse contract. The registry header must equal
# that list IN ORDER. The two columns this predicate reads — `id` and
# `entrypoint` — are then located BY NAME within the parsed order, never by a
# hardcoded position. If the schema adds, removes or reorders a field, this
# predicate follows it or fails loud; it cannot silently disagree. A private copy
# of the field list would be a second source of truth that drifts the moment the
# schema changes, and the self-test's schema-mutation arm exists to prove this
# predicate does not hold one.
#
# ── Exit codes (identical to the sibling predicates) ──────────────────────────
#   0 — ROSTER and ROWS agree in both directions
#   1 — one or more coverage findings (the count is in the SUMMARY line)
#   2 — usage error
#   3 — scan-surface error: a scan surface is absent, the schema parses no
#       fields, the registry header disagrees with the schema, the roster is
#       empty, or a declared id fails the shape guard. ALWAYS hard-fail — a
#       relocated or reformatted scan surface means the predicate ran against
#       nothing and must not read green.
#
# A malformed declared id is exit 3, NOT a finding: it means the extraction
# broke, and a broken extractor must fail loud rather than emit a finding storm
# that looks like a corpus problem.
#
# Usage (run under the bash interpreter, from the repository root):
#   <no arguments>   assert coverage over the live tree
#   --self-test      run the falsification suite over copies of the LIVE
#                    population (never a synthetic fixture — see self_test)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# The shape every declared automation id must satisfy. Reused verbatim from the
# routine-name shape carried by the conformance predicate, so the two cannot
# disagree about what a valid registry primary key looks like.
AUTOMATION_ID_RE='^[a-z][a-z0-9-]*$'

# ─── Glob-free word splitting — the ONE place an unquoted expansion is allowed ─
# An unquoted `$var` in a for-list or an array assignment is word-split AND THEN
# glob-expanded against the caller's working directory. The sibling conformance
# predicate shipped with exactly that defect: cron `*` fields expanded to a
# directory listing, so every well-formed row was rejected — and the bug was
# invisible in an empty directory, which is why reading the code missed it. Every
# split in this file routes through here, and the prior noglob state is captured
# and restored rather than blindly cleared.
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

# ─── CIAC-2: parse the field list out of the schema ───────────────────────────
# The schema declares its own machine-parse contract: a field row matches
# `^| <n> | \`` and yields the field name from the backticked token in cell 2,
# in declaration order. That contract is implemented here and nowhere else.
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

# ─── ROSTER form (a): frontmatter declarations in tracked markdown ────────────
# Emits `id<TAB>path<TAB>line` per declared id. The frontmatter block is the
# FIRST ---delimited block and only when `---` is line 1, so a horizontal rule
# further down a document can never open a false block.
#
# The value is list-valued: `[a, b]` or a bare scalar. Both are normalised to
# one output line per element here, so no caller re-implements the split.
roster_md_awk() {
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
        if (t != "") print t "\t" FILENAME "\t" FNR
      }
    }
  ' "$@"
}

# ─── ROSTER form (b): comment declarations in workflow files ──────────────────
# A `# automation_id:` comment at column 0. Workflows carry no frontmatter, and
# a `#` at column 0 in YAML is unambiguously a comment, so no position rule is
# needed beyond that.
roster_wf_awk() {
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
        if (t != "") print t "\t" FILENAME "\t" FNR
      }
    }
  ' "$@"
}

# ─── SCHED: scheduled workflows ───────────────────────────────────────────────
# A workflow carrying a non-comment `cron:` key. Comment lines are excluded so a
# workflow that merely DISCUSSES a cron in its header is not swept in.
sched_wf_awk() {
  awk '
    /^[[:space:]]*#/ { next }
    /cron:/ { print FILENAME; nextfile }
  ' "$@"
}

# ─── The registry table ───────────────────────────────────────────────────────
# Emits the `## Routines` table: the header as `HDR<US>...`, each data row as
# `ROW<US>...`, <US> being ASCII 0x1f, which no cell can contain. The table ends
# at the first line not beginning with `|`, so prose after it is never swept in.
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

# ─── The check ────────────────────────────────────────────────────────────────
# Every scan surface is a PARAMETER. That is what lets the self-test point the
# identical code path at a mutated COPY of the live population instead of
# forking a second, fixture-only path that could pass while the real one breaks.
#   $1 — repo root (a git checkout; tracked-ness is resolved with git ls-files)
#   $2 — registry.md under test
#   $3 — automation-registry-schema.md under test
run_check() {
  local repo_root="$1" registry_md="$2" schema_md="$3"
  local US
  US="$(printf '\037')"

  if [[ ! -f "$registry_md" ]]; then
    echo "FAIL:  scan-surface error — automation registry not found: $registry_md (a moved or deleted registry must fail loud, not skip)" >&2
    return 3
  fi
  if [[ ! -f "$schema_md" ]]; then
    echo "FAIL:  scan-surface error — automation registry schema not found: $schema_md (the field list is PARSED from it; without it this predicate has no contract to assert against)" >&2
    return 3
  fi

  # ── CIAC-2 arm 1: the field list, parsed from the schema.
  local -a FIELDS=()
  local _f
  while IFS= read -r _f; do [[ -n "$_f" ]] && FIELDS+=("$_f"); done < <(parse_schema_fields "$schema_md")
  if [[ ${#FIELDS[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — parsed 0 fields from $schema_md. The schema's field table is absent or its declared row form changed; a predicate that resolves its contract there must fail loud rather than fall back to a private copy." >&2
    return 3
  fi

  # ── CIAC-2 arm 2: the registry header must equal that list, IN ORDER. An
  # unordered-but-complete header is still a FAIL: a positional reader fills the
  # wrong column and can still read green.
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

  # ── The two columns this predicate reads, located BY NAME in the parsed order.
  local id_idx=-1 ep_idx=-1 _i
  for ((_i = 0; _i < ${#FIELDS[@]}; _i++)); do
    [[ "${FIELDS[$_i]}" == "id" ]] && id_idx=$_i
    [[ "${FIELDS[$_i]}" == "entrypoint" ]] && ep_idx=$_i
  done
  if [[ $id_idx -lt 0 || $ep_idx -lt 0 ]]; then
    echo "FAIL:  scan-surface error — the schema's field list has no 'id' and/or no 'entrypoint' column (id=$id_idx entrypoint=$ep_idx). This predicate joins the roster to the rows on those two fields; without them it cannot assert anything and must not read green." >&2
    return 3
  fi

  # ── ROWS.
  local -a ROW_IDS=() ROW_EPS=()
  local _line
  for ((_i = 1; _i < ${#RAW[@]}; _i++)); do
    _line="${RAW[$_i]}"
    [[ "$_line" == ROW* ]] || continue
    _line="${_line#ROW${US}}"
    local -a cells=()
    local _c
    # printf with a TRAILING NEWLINE on purpose: without it the final `read`
    # returns non-zero and the loop body never runs, silently dropping the LAST
    # cell — which for a schema whose last field is `reversibility` would go
    # unnoticed until a column was added.
    while IFS= read -r _c; do cells+=("$_c"); done < <(printf '%s\n' "$_line" | tr "$US" '\n')
    ROW_IDS+=("${cells[$id_idx]:-<empty>}")
    ROW_EPS+=("${cells[$ep_idx]:-<empty>}")
  done
  if [[ ${#ROW_IDS[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — parsed 0 routine rows from $registry_md (expected >=1; the registry ships seeded, so an empty parse means the table broke or the rows were removed)." >&2
    return 3
  fi

  # ── ROSTER. Tracked-ness comes from git, so an untracked scratch document in a
  # working tree never manufactures a finding about something that is not shipping.
  if ! git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
    echo "FAIL:  scan-surface error — $repo_root is not a git checkout, so the tracked-file population cannot be resolved. This predicate asserts over what the platform SHIPS; a filesystem walk would sweep untracked scratch files and is not a substitute." >&2
    return 3
  fi

  local -a MD_FILES=() WF_FILES=()
  local _p
  while IFS= read -r _p; do [[ -n "$_p" ]] && MD_FILES+=("$repo_root/$_p"); done < <(git -C "$repo_root" ls-files -- '*.md')
  while IFS= read -r _p; do [[ -n "$_p" ]] && WF_FILES+=("$repo_root/$_p"); done < <(git -C "$repo_root" ls-files -- '.github/workflows/*.yml' '.github/workflows/*.yaml')

  local -a R_IDS=() R_LOCS=()
  local _row _rid _rpath _rline
  if [[ ${#MD_FILES[@]} -gt 0 ]]; then
    while IFS=$'\t' read -r _rid _rpath _rline; do
      [[ -z "$_rid" ]] && continue
      R_IDS+=("$_rid"); R_LOCS+=("${_rpath#$repo_root/}:$_rline")
    done < <(roster_md_awk "${MD_FILES[@]}")
  fi
  if [[ ${#WF_FILES[@]} -gt 0 ]]; then
    while IFS=$'\t' read -r _rid _rpath _rline; do
      [[ -z "$_rid" ]] && continue
      R_IDS+=("$_rid"); R_LOCS+=("${_rpath#$repo_root/}:$_rline")
    done < <(roster_wf_awk "${WF_FILES[@]}")
  fi

  # ── Shape guard on every declared id. A malformed id means the extraction
  # broke; that is exit 3, never a finding storm.
  local _gid
  for _gid in ${R_IDS[@]+"${R_IDS[@]}"}; do
    if [[ ! "$_gid" =~ $AUTOMATION_ID_RE ]]; then
      echo "FAIL:  scan-surface error — declared automation id '$_gid' does not match ${AUTOMATION_ID_RE}. A malformed extracted id means the frontmatter parse broke; a broken extractor must fail loud rather than report findings." >&2
      return 3
    fi
  done

  # ── Anti-vacuity. An empty roster means the marker convention broke, the scan
  # surface moved, or the extraction silently stopped matching. It is NEVER a
  # clean corpus: the platform ships at least one declared automation, so a zero
  # here measures the wiring, not the corpus. This is the assertion that stops
  # this gate from reporting the very state it exists to detect.
  if [[ ${#R_IDS[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — the roster scan found 0 declared automations across ${#MD_FILES[@]} tracked markdown files and ${#WF_FILES[@]} workflow files. The platform ships at least one, so a zero here is a broken extraction, not a clean corpus — a gate that reported green on this would be asserting nothing." >&2
    return 3
  fi

  # ── SCHED.
  local -a SCHED=()
  if [[ ${#WF_FILES[@]} -gt 0 ]]; then
    while IFS= read -r _p; do [[ -n "$_p" ]] && SCHED+=("${_p#$repo_root/}"); done < <(sched_wf_awk "${WF_FILES[@]}")
  fi

  local findings=0
  local a b hit

  # ── A-01 — every declared automation has a row. THE ACCEPTANCE CRITERION.
  for ((_i = 0; _i < ${#R_IDS[@]}; _i++)); do
    a="${R_IDS[$_i]}"; hit=0
    for b in ${ROW_IDS[@]+"${ROW_IDS[@]}"}; do [[ "$a" == "$b" ]] && hit=1 && break; done
    if [[ $hit -eq 0 ]]; then
      echo "FAIL:  A-01 unregistered-automation — automation '$a' declared at ${R_LOCS[$_i]} has no routine-spec row in the registry. Add the row, or remove the automation_id declaration."
      findings=$((findings + 1))
    fi
  done

  # ── A-02 — every row has a declaring automation (the other direction).
  for ((_i = 0; _i < ${#ROW_IDS[@]}; _i++)); do
    a="${ROW_IDS[$_i]}"; hit=0
    for b in ${R_IDS[@]+"${R_IDS[@]}"}; do [[ "$a" == "$b" ]] && hit=1 && break; done
    if [[ $hit -eq 0 ]]; then
      echo "FAIL:  A-02 orphan-row — registry row '$a' has no declaring automation. Add 'automation_id: [$a]' to ${ROW_EPS[$_i]}, or remove the row."
      findings=$((findings + 1))
    fi
  done

  # ── A-03 — the entrypoint round-trip. The arm that separates this gate from a
  # presence-only check: a row can name a real file, and a real automation can be
  # declared, while the row points at the WRONG one.
  local _ep _declared
  for ((_i = 0; _i < ${#ROW_IDS[@]}; _i++)); do
    a="${ROW_IDS[$_i]}"; _ep="${ROW_EPS[$_i]}"
    [[ "$_ep" == "<empty>" ]] && continue
    if [[ ! -f "$repo_root/$_ep" ]]; then
      # The entrypoint resolving to nothing is the CONFORMANCE predicate's
      # finding (R-09), not this one's. Reporting it here too would double-count
      # one defect across two gates and teach a reader to ignore one of them.
      continue
    fi
    _declared=""
    hit=0
    for ((b = 0; b < ${#R_IDS[@]}; b++)); do
      if [[ "${R_LOCS[$b]%%:*}" == "$_ep" ]]; then
        _declared="$_declared ${R_IDS[$b]}"
        [[ "${R_IDS[$b]}" == "$a" ]] && hit=1
      fi
    done
    if [[ $hit -eq 0 ]]; then
      if [[ -z "$_declared" ]]; then
        echo "FAIL:  A-03 entrypoint-undeclared — registry row '$a' entrypoint '$_ep' declares no automation_id. The entrypoint must declare the row's own id, so a row cannot drift onto the wrong document. Add 'automation_id: [$a]' to it."
      else
        echo "FAIL:  A-03 entrypoint-mismatch — registry row '$a' entrypoint '$_ep' declares [${_declared# }], not '$a'. Fix the entrypoint or the id."
      fi
      findings=$((findings + 1))
    fi
  done

  # ── A-04 — every scheduled workflow is registered. ZERO-EXCEPTION BY DECISION:
  # there is no exclusion allowlist, and that is deliberate. An escape hatch
  # shipped alongside a new gate is the hatch the next author reaches for, and a
  # scheduled workflow IS an automation the platform ships on a cadence — which is
  # precisely this registry's subject.
  local _sw
  for _sw in ${SCHED[@]+"${SCHED[@]}"}; do
    hit=0
    for ((b = 0; b < ${#ROW_IDS[@]}; b++)); do
      [[ "${ROW_EPS[$b]}" == "$_sw" ]] && hit=1 && break
    done
    if [[ $hit -eq 0 ]]; then
      echo "FAIL:  A-04 unregistered-schedule — scheduled workflow '$_sw' has no routine-spec row naming it as an entrypoint. It runs on a cadence, so it is a governed automation: add its row to the registry and a '# automation_id:' comment to the workflow."
      findings=$((findings + 1))
    fi
  done

  # The counts are not decoration — they are the anti-vacuity read-out. A
  # reviewer skimming for "exit 0" must be able to see the population was real.
  if [[ $findings -gt 0 ]]; then
    echo "SUMMARY: ${#R_IDS[@]} declared automations, ${#ROW_IDS[@]} registry rows, ${#SCHED[@]} scheduled workflows; $findings FAIL"
    return 1
  fi
  echo "SUMMARY: ${#R_IDS[@]} declared automations, ${#ROW_IDS[@]} registry rows, ${#SCHED[@]} scheduled workflows; 0 FAIL (every declared automation is registered and every row round-trips to its entrypoint)"
  return 0
}

# ─── Self-test ────────────────────────────────────────────────────────────────
# EVERY ARM MUTATES A COPY OF THE LIVE POPULATION. Not a synthetic fixture — the
# registry rows and the corpus markers are created inside this milestone's own
# change, so a fixture-based suite would prove the gate works on a corpus nobody
# ships. Binding the arms to the live population means the gate's first green run
# is over the real migrated set by construction.
#
# The copy is a real git checkout because tracked-ness is part of the predicate:
# a suite that swapped git for a filesystem walk would be testing a code path the
# live scan never takes.
self_test() {
  local tmp pass=0 rc out
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  local REG="core/automations/registry.md"
  local SCH="core/schemas/automation-registry-schema.md"

  # ── Materialise the live population into a scratch checkout: the registry, the
  # schema, and every file that actually declares or schedules an automation.
  _seed() {
    rm -rf "$tmp/tree"
    mkdir -p "$tmp/tree"
    ( cd "$REPO_ROOT" && git ls-files -z -- "$REG" "$SCH" '*.md' '.github/workflows/*.yml' '.github/workflows/*.yaml' ) \
      > "$tmp/all.z" 2>/dev/null
    local p
    while IFS= read -r -d '' p; do
      case "$p" in
        "$REG"|"$SCH") ;;
        *.md)
          # Only markdown that actually DECLARES an automation is materialised.
          # Copying all 1,300+ tracked documents would make every arm slow with
          # no gain: a document with no declaration contributes nothing to either
          # set this predicate compares.
          roster_md_awk "$REPO_ROOT/$p" | grep -q . || continue
          ;;
        *) : ;;
      esac
      mkdir -p "$tmp/tree/$(dirname "$p")"
      cp "$REPO_ROOT/$p" "$tmp/tree/$p"
    done < "$tmp/all.z"
    ( cd "$tmp/tree" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm seed ) >/dev/null 2>&1
  }

  # _set_cell <registry-file> <row-id> <1-based column> <new value>
  # Rewrites one cell of one row. Used instead of a sed with an embedded column
  # pattern: a positional awk edit stays correct when the schema's column order
  # changes, which is exactly the mutation F6 exercises.
  _set_cell() {
    awk -v rid="$2" -v col="$3" -v val="$4" -F'|' '
      BEGIN { OFS = "|" }
      {
        first = $2; gsub(/[` \t]/, "", first)
        if (first == rid && NF > col + 1) { $(col + 1) = " `" val "` " }
        print
      }
    ' "$1" > "$1.new" && mv "$1.new" "$1"
  }

  # ── F7 FIRST: the live population must be non-empty BEFORE any arm runs. A
  # zero here measures the wiring, not the corpus, and every arm below would be
  # vacuously green on an empty population.
  _seed
  out="$(run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" 2>&1)"; rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "self-test FAIL: F7/CONTROL — the UNMUTATED live population must yield exit 0 with zero findings; got exit $rc" >&2
    echo "$out" >&2; return 1
  fi
  local n_auto n_rows
  n_auto="$(printf '%s' "$out" | sed -n 's/^SUMMARY: \([0-9]*\) declared.*/\1/p')"
  n_rows="$(printf '%s' "$out" | sed -n 's/^SUMMARY: [0-9]* declared automations, \([0-9]*\) registry rows.*/\1/p')"
  if [[ "${n_auto:-0}" -lt 1 || "${n_rows:-0}" -lt 1 ]]; then
    echo "self-test FAIL: F7 anti-vacuity — the live population is empty (declared=${n_auto:-?} rows=${n_rows:-?}). Every arm below would pass vacuously, so the suite proves nothing." >&2
    echo "$out" >&2; return 1
  fi
  pass=$((pass + 2))

  # ── The CONTROL arm, made CWD-INDEPENDENT. The sibling predicate shipped a
  # control that silently depended on the invoker's working directory, so it read
  # green in an empty directory whether or not the bug was present. This arm runs
  # the identical unmutated population from a stocked directory, so a
  # glob-expansion regression fails here deterministically.
  mkdir -p "$tmp/decoy"; : > "$tmp/decoy/a.md"; : > "$tmp/decoy/b.md"; : > "$tmp/decoy/c.md"
  ( cd "$tmp/decoy" && run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" >/dev/null 2>&1 )
  rc=$?
  if [[ $rc -eq 0 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: CONTROL is cwd-dependent — the unmutated population returned exit $rc from a NON-EMPTY directory. An unquoted \$var split is glob-expanding; route it through split_noglob." >&2
    return 1; fi

  # ── F1 / AC-1 + AC-3. Delete a live routine's registry row. The gate must fire
  # A-01 and NAME that id and its declaring path:line.
  _seed
  local victim victim_loc
  victim="$(awk -F'|' '/^\|[[:space:]]*`/ { gsub(/[` \t]/,"",$2); print $2; exit }' "$tmp/tree/$REG")"
  if [[ -z "$victim" ]]; then
    echo "self-test FAIL: F1 setup — could not read a routine id out of the live registry copy." >&2; return 1; fi
  grep -v "^| \`${victim}\` " "$tmp/tree/$REG" > "$tmp/reg.tmp" && mv "$tmp/reg.tmp" "$tmp/tree/$REG"
  out="$(run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" 2>&1)"; rc=$?
  if [[ $rc -ne 1 ]]; then
    echo "self-test FAIL: F1 AC-1 — deleting the row for '$victim' must yield exit 1; got $rc" >&2; echo "$out" >&2; return 1; fi
  if ! printf '%s' "$out" | grep -q "A-01 unregistered-automation"; then
    echo "self-test FAIL: F1 AC-1 — expected an A-01 finding; got:" >&2; echo "$out" >&2; return 1; fi
  # AC-3: asserted by EQUALITY ON THE ID TOKEN, not by "a FAIL line appeared".
  if ! printf '%s' "$out" | grep -q "automation '${victim}' declared at "; then
    echo "self-test FAIL: F3 AC-3 — the verdict must name the missing entry '$victim' and its declaring path:line, not fail generically. Got:" >&2
    echo "$out" >&2; return 1; fi
  victim_loc="$(printf '%s' "$out" | sed -n "s/.*declared at \([^ ]*\) has no.*/\1/p" | head -1)"
  if [[ "$victim_loc" != *:* ]]; then
    echo "self-test FAIL: F3 AC-3 — the A-01 verdict must carry a path:line locator; got '$victim_loc'" >&2; return 1; fi
  pass=$((pass + 3))

  # ── F4. An orphan row — a registration whose routine does not exist.
  _seed
  local hdr_line
  hdr_line="$(grep -n '^| \`' "$tmp/tree/$REG" | head -1 | cut -d: -f1)"
  awk -v n="$hdr_line" 'NR==n { print; print "| `qqzz-not-a-routine` | `0 6 * * *` | `time-driven` | `core/automations/registry.md` | `recommend` | `CHEAP` |"; next } { print }' \
    "$tmp/tree/$REG" > "$tmp/reg.tmp" && mv "$tmp/reg.tmp" "$tmp/tree/$REG"
  out="$(run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" 2>&1)"; rc=$?
  if [[ $rc -eq 1 ]] && printf '%s' "$out" | grep -q "A-02 orphan-row.*qqzz-not-a-routine"; then pass=$((pass + 1)); else
    echo "self-test FAIL: F4 — an orphan row must fire A-02 naming it; got exit $rc" >&2; echo "$out" >&2; return 1; fi

  # ── F5. Repoint a row's entrypoint at a real tracked file that declares a
  # DIFFERENT automation_id (or none). This is the arm that separates this gate
  # from a presence-only check — both sets are still symmetric here.
  _seed
  _set_cell "$tmp/tree/$REG" "$victim" 4 "core/schemas/automation-registry-schema.md"
  out="$(run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" 2>&1)"; rc=$?
  if [[ $rc -eq 1 ]] && printf '%s' "$out" | grep -q "A-03 entrypoint-"; then pass=$((pass + 1)); else
    echo "self-test FAIL: F5 — a row repointed at a document declaring a different id must fire A-03; got exit $rc" >&2
    echo "$out" >&2; return 1; fi

  # ── F6 / CIAC-2 PROOF. Delete a field row from the SCHEMA copy. A predicate
  # holding a private copy of the field list is BLIND to this and stays green;
  # one that parses the schema at run time must fail loud on header parity.
  _seed
  grep -v '^| 3 | `trigger`' "$tmp/tree/$SCH" > "$tmp/sch.tmp" && mv "$tmp/sch.tmp" "$tmp/tree/$SCH"
  run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" >/dev/null 2>&1; rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: F6 CIAC-2 — deleting a field from the SCHEMA must hard-fail at exit 3 (header parity). Got $rc, which means the field list is NOT being parsed from the schema." >&2
    return 1; fi

  # ── F6b. The schema parsing to zero fields is a scan-surface error, never a
  # permissive pass.
  _seed
  awk '!/^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*`/' "$tmp/tree/$SCH" > "$tmp/sch.tmp" && mv "$tmp/sch.tmp" "$tmp/tree/$SCH"
  run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" >/dev/null 2>&1; rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: F6b — a schema parsing 0 fields must hard-fail at exit 3; got $rc" >&2; return 1; fi

  # ── F8 / SPECIFICITY. A CONFORMANCE defect — a malformed cadence — must produce
  # NO finding here. The two predicates own disjoint invariants, and a coverage
  # gate that also fired on conformance would double-count one defect across two
  # gates and teach a reviewer to ignore one of them.
  _seed
  _set_cell "$tmp/tree/$REG" "$victim" 2 "every second tuesday"
  out="$(run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" 2>&1)"; rc=$?
  if [[ $rc -eq 0 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: F8 specificity — a malformed CADENCE is the conformance predicate's finding, not this one's; this gate must stay green. Got exit $rc:" >&2
    echo "$out" >&2; return 1; fi

  # ── F9. A scheduled workflow with no row. Built by ADDING a schedule to a copy
  # of a live workflow that has none, so the arm's subject is a real workflow.
  _seed
  local wf_victim
  wf_victim="$(cd "$tmp/tree" && git ls-files -- '.github/workflows/*.yml' | head -20 | while read -r w; do
      if ! awk '/^[[:space:]]*#/ { next } /cron:/ { found=1 } END { exit !found }' "$w"; then echo "$w"; break; fi
    done)"
  if [[ -z "$wf_victim" ]]; then
    echo "self-test FAIL: F9 setup — no schedule-free workflow available to mutate." >&2; return 1; fi
  printf '\non:\n  schedule:\n    - cron: %s0 3 * * *%s\n' "'" "'" >> "$tmp/tree/$wf_victim"
  out="$(run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" 2>&1)"; rc=$?
  if [[ $rc -eq 1 ]] && printf '%s' "$out" | grep -q "A-04 unregistered-schedule.*$wf_victim"; then pass=$((pass + 1)); else
    echo "self-test FAIL: F9 — a newly-scheduled workflow with no row must fire A-04 naming it; got exit $rc" >&2
    echo "$out" >&2; return 1; fi

  # ── Scan-surface arms. Each must hard-fail rather than read green.
  _seed; rm -f "$tmp/tree/$REG"
  run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" >/dev/null 2>&1; rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: absent registry — expected exit 3, got $rc" >&2; return 1; fi

  _seed; rm -f "$tmp/tree/$SCH"
  run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" >/dev/null 2>&1; rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: absent schema — expected exit 3, got $rc" >&2; return 1; fi

  # ── The anti-vacuity arm, proven rather than asserted: strip every declaration
  # from the roster and require exit 3. A gate that reported "0 findings" here
  # would be reporting the exact state it exists to detect.
  _seed
  local _mp
  while IFS= read -r _mp; do
    [[ -z "$_mp" ]] && continue
    sed -i.bak '/^automation_id:/d' "$tmp/tree/$_mp" && rm -f "$tmp/tree/$_mp.bak"
  done < <(cd "$tmp/tree" && git ls-files -- '*.md')
  while IFS= read -r _mp; do
    [[ -z "$_mp" ]] && continue
    sed -i.bak '/^#[[:space:]]*automation_id:/d' "$tmp/tree/$_mp" && rm -f "$tmp/tree/$_mp.bak"
  done < <(cd "$tmp/tree" && git ls-files -- '.github/workflows/*.yml')
  run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" >/dev/null 2>&1; rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: anti-vacuity — an empty roster must hard-fail at exit 3, NEVER read as a clean corpus. Got $rc." >&2; return 1; fi

  # ── The list-valued arm. One document declaring TWO routines must contribute
  # BOTH to the roster; a scalar reader contributes one and silently under-covers.
  _seed
  local twofile
  twofile="$(cd "$tmp/tree" && git ls-files -- '*.md' | while read -r m; do
      if roster_md_awk "$m" | grep -q .; then echo "$m"; break; fi
    done)"
  if [[ -z "$twofile" ]]; then
    echo "self-test FAIL: list-valued setup — no declaring markdown file in the live copy." >&2; return 1; fi
  local before after
  before="$(roster_md_awk "$tmp/tree/$twofile" | wc -l | tr -d ' ')"
  sed -i.bak "s/^automation_id:.*/automation_id: [qqzz-alpha, qqzz-beta]/" "$tmp/tree/$twofile"
  rm -f "$tmp/tree/$twofile.bak"
  after="$(roster_md_awk "$tmp/tree/$twofile" | wc -l | tr -d ' ')"
  if [[ "$after" -eq 2 && "$before" -ge 1 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: list-valued — a two-element automation_id must yield 2 roster entries (before=$before after=$after). A scalar reader silently under-covers a document declaring more than one routine." >&2
    return 1; fi

  # ── Shape guard: a malformed declared id is exit 3, not a finding storm.
  _seed
  sed -i.bak "s/^automation_id:.*/automation_id: [Not_A_Valid_Id]/" "$tmp/tree/$twofile"
  rm -f "$tmp/tree/$twofile.bak"
  run_check "$tmp/tree" "$tmp/tree/$REG" "$tmp/tree/$SCH" >/dev/null 2>&1; rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: shape guard — a malformed declared id must hard-fail at exit 3, not emit findings. Got $rc." >&2; return 1; fi

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
        "$REPO_ROOT/core/schemas/automation-registry-schema.md"
      exit $?
      ;;
    *)
      echo "Usage: check-automation-coverage.sh [--self-test]" >&2
      exit 2
      ;;
  esac
}

main "$@"
