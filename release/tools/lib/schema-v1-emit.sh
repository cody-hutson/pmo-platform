#!/usr/bin/env bash
# schema-v1-emit.sh — Shared schema-v1 emitter for the blast-radius tool family.
#
# The SINGLE home of the schema-v1 output contract. Both fan-out tracers source
# this library so the `{path, reference_count, matches, is_mirror}` object and the
# top-level envelope (schema_version / cli_version / stats{…} / first_order[] /
# second_order[] / filtered_mirrors_detail[]) are emitted from ONE place:
#   - release/tools/blast-radius.sh          (doc-corpus markdown-tree tracer, DEFAULT)
#   - release/tools/domain-blast-radius.sh   (domain-keyed fan-out; software import-graph)
#
# Contract consumers that pin schema v1 (design-review-checklist.md §1/§3,
# blast-radius-protocol.md §12 opt-out, mixed-release-solutioning-routing.md §6 C1)
# read output from EITHER tracer identically. A schema v1→v2 bump edits this file
# ONCE, not two divergent emitters (the two-emitter-drift risk this extraction closes;
# see ADR-068). See release/references/protocols/blast-radius-protocol.md for the field
# semantics this library realizes.
#
# Design note (F3 — real function signatures): every function here takes EXPLICIT
# parameters. It reads NO caller globals. The caller maps its own state onto the
# parameter list; the library owns only the jq assembly. This is what makes the
# contract a shared library rather than a verbatim block that silently depends on
# a dozen ambient variables at the extraction site.
#
# This file is sourced, never executed. It defines functions and returns; it has
# no main and no side effects at source time.

# ---------------------------------------------------------------------------
# Schema version this library emits. The contract is the schema, not the caller.
# A tracer MUST assert its own SCHEMA_VERSION matches this before emitting, so a
# version skew between a tracer and this library fails loudly rather than shipping
# a mislabeled envelope.
# ---------------------------------------------------------------------------
readonly SCHEMA_V1_EMIT_VERSION="1"

# ---------------------------------------------------------------------------
# aggregate_matches_v1 — roll a first-order match TSV up into the schema-v1
# first_order[] array, splitting out mirror-partner entries.
#
# This is the emitter half of the doc tracer's aggregate_first_order (the awk
# roll-up + the per-file {path, reference_count, matches, is_mirror} object at the
# extraction site). A CALLER that has already produced the pre-aggregated TSV
# (one row per (file,line): "<path>\t<line>\t<snippet>") passes it in; this fn
# owns the count roll-up, the 5-match cap, the 200-char snippet truncation, and
# the JSON assembly. Domain tracers reuse it verbatim so `reference_count`,
# `matches[]`, and `is_mirror` mean the same thing across the tool family.
#
# Field semantics (identical for every caller):
#   path            — repo-relative path of the referrer/importer
#   reference_count — count of distinct (file,line) match rows for that file
#                     (doc: mention lines; software: import/require statement lines)
#   matches[]       — up to 5 {line, snippet}, snippet stripped + 200-char truncated
#   is_mirror       — true ONLY when path == the caller-supplied mirror partner
#                     (software callers pass an empty partner => always false)
#
# Args (explicit — F3):
#   $1 tsv_file        path to the pre-aggregated match TSV ("<path>\t<line>\t<snippet>")
#   $2 mirror_partner  repo-relative mirror partner of the target ("" if none)
#   $3 include_mirrors "1" to keep mirror entries in first_order[]; "0" to split
#                      them into filtered_mirrors_detail[]
#
# Emits (stdout): a single JSON object
#   { "first_order": [...], "first_order_count": N,
#     "filtered_mirrors_detail": [...], "filtered_mirrors_count": M }
# ---------------------------------------------------------------------------
aggregate_matches_v1() {
  local tsv_file="$1"
  local mirror_partner="$2"
  local include_mirrors="$3"

  local fo_entries fm_entries fo_count fm_count
  fo_entries="$(jq -n '[]')"
  fm_entries="$(jq -n '[]')"
  fo_count=0
  fm_count=0

  if [ ! -s "$tsv_file" ]; then
    jq -n \
      --argjson fo "$fo_entries" \
      --argjson fm "$fm_entries" \
      '{first_order: $fo, first_order_count: 0, filtered_mirrors_detail: $fm, filtered_mirrors_count: 0}'
    return
  fi

  # Roll up per file: reference_count + up to 5 (line, snippet) matches.
  local agg
  agg=$(awk -F '\t' '
    {
      file = $1
      line = $2
      text = $3
      sub(/^[ \t]+/, "", text)
      if (length(text) > 200) {
        text = substr(text, 1, 200) "…"
      }
      key = file
      count[key]++
      if (matches_count[key] < 5) {
        matches_count[key]++
        idx = matches_count[key]
        m_line[key SUBSEP idx] = line
        m_text[key SUBSEP idx] = text
      }
    }
    END {
      for (file in count) {
        printf "%s\t%d", file, count[file]
        for (i = 1; i <= matches_count[file]; i++) {
          printf "\t%d\t%s", m_line[file SUBSEP i], m_text[file SUBSEP i]
        }
        printf "\n"
      }
    }
  ' "$tsv_file")

  [ -z "$agg" ] && {
    jq -n \
      --argjson fo "$fo_entries" \
      --argjson fm "$fm_entries" \
      '{first_order: $fo, first_order_count: 0, filtered_mirrors_detail: $fm, filtered_mirrors_count: 0}'
    return
  }

  # Sort: reference_count DESC, path ASC (stable, deterministic output order).
  local sorted
  sorted=$(printf '%s\n' "$agg" | LC_ALL=C sort -t $'\t' -k2,2nr -k1,1)

  local row file count is_mirror match_pairs matches_json entry
  while IFS= read -r row; do
    [ -z "$row" ] && continue
    file="$(printf '%s' "$row" | awk -F '\t' '{print $1}')"
    count="$(printf '%s' "$row" | awk -F '\t' '{print $2}')"

    is_mirror=false
    if [ -n "$mirror_partner" ] && [ "$file" = "$mirror_partner" ]; then
      is_mirror=true
    fi

    match_pairs="$(printf '%s' "$row" | awk -F '\t' '{
      for (i = 3; i <= NF; i += 2) {
        if (i+1 <= NF) {
          print $i "\t" $(i+1)
        }
      }
    }')"

    matches_json=$(
      printf '%s\n' "$match_pairs" \
        | jq -R -s '
            split("\n")
            | map(select(length > 0))
            | map(split("\t"))
            | map({line: (.[0] | tonumber), snippet: .[1]})
          '
    )

    entry=$(jq -n \
      --arg path "$file" \
      --argjson ref_count "$count" \
      --argjson matches "$matches_json" \
      --argjson is_mirror "$is_mirror" \
      '{path: $path, reference_count: $ref_count, matches: $matches, is_mirror: $is_mirror}')

    if [ "$is_mirror" = "true" ] && [ "$include_mirrors" = "0" ]; then
      fm_entries=$(printf '%s\n%s\n' "$fm_entries" "$entry" | jq -s '.[0] + [.[1]]')
      fm_count=$((fm_count + 1))
    else
      fo_entries=$(printf '%s\n%s\n' "$fo_entries" "$entry" | jq -s '.[0] + [.[1]]')
      fo_count=$((fo_count + 1))
    fi
  done <<EOF
$sorted
EOF

  jq -n \
    --argjson fo "$fo_entries" \
    --argjson foc "$fo_count" \
    --argjson fm "$fm_entries" \
    --argjson fmc "$fm_count" \
    '{first_order: $fo, first_order_count: $foc, filtered_mirrors_detail: $fm, filtered_mirrors_count: $fmc}'
}

# ---------------------------------------------------------------------------
# build_json_v1 — assemble the full schema-v1 output document.
#
# The single home of the top-level envelope. Every field is an explicit parameter
# (F3) — the function reads NO caller globals. `second_order` is passed in as a
# ready JSON array so each tracer can compute it its own way (the doc tracer's
# depth-2 doc-reference traversal, or a domain tracer's import-graph depth-2), while
# the ENVELOPE that carries it is emitted from one place.
#
# `second_order[].via` and `second_order[].depth`: this library does NOT synthesize
# them — a caller that populates second_order[] is responsible for including `via`
# and `depth` on each element (the doc tracer does). A caller that scopes second
# order OUT passes an empty array `[]` and second_order_count 0 (the software
# domain does this deliberately; see ADR-068 and the domain-blast-radius.sh header).
#
# Args (explicit — F3), in envelope order:
#   $1  cli_version           emitting tool's version string
#   $2  target                repo-relative target path
#   $3  scanned_at            ISO-8601 UTC timestamp (non-deterministic field)
#   $4  scan_root             absolute scan root (non-deterministic field)
#   $5  depth                 integer traversal depth
#   $6  include_mirrors       "true"|"false" JSON literal
#   $7  total_files_scanned   integer (a domain tracer that does not size the whole
#                             corpus passes the count of files it actually scanned;
#                             see ADR-068 for the software-domain semantics)
#   $8  first_order_count     integer
#   $9  second_order_count    integer
#   $10 filtered_mirrors      integer
#   $11 elapsed_seconds       string, numeric (non-deterministic field)
#   $12 first_order_json      JSON array
#   $13 second_order_json     JSON array (each element carries via + depth, or [])
#   $14 filtered_mirrors_json JSON array
#   $15 schema_version        schema version to stamp (defaults to SCHEMA_V1_EMIT_VERSION
#                             when omitted); a caller passes its own SCHEMA_VERSION so a
#                             skew is caught by its pre-emit assertion, not here
#
# Emits (stdout): the complete schema-v1 JSON document.
# ---------------------------------------------------------------------------
build_json_v1() {
  local cli_version="$1"
  local target="$2"
  local scanned_at="$3"
  local scan_root="$4"
  local depth="$5"
  local include_mirrors="$6"
  local total_files_scanned="$7"
  local first_order_count="$8"
  local second_order_count="$9"
  local filtered_mirrors="${10}"
  local elapsed_seconds="${11}"
  local first_order_json="${12}"
  local second_order_json="${13}"
  local filtered_mirrors_json="${14}"
  local schema_version="${15:-$SCHEMA_V1_EMIT_VERSION}"

  jq -n \
    --arg schema_version "$schema_version" \
    --arg cli_version "$cli_version" \
    --arg target "$target" \
    --arg scanned_at "$scanned_at" \
    --arg scan_root "$scan_root" \
    --argjson depth "$depth" \
    --argjson include_mirrors "$include_mirrors" \
    --argjson total_files_scanned "$total_files_scanned" \
    --argjson first_order_count "$first_order_count" \
    --argjson second_order_count "$second_order_count" \
    --argjson filtered_mirrors "$filtered_mirrors" \
    --arg elapsed_seconds "$elapsed_seconds" \
    --argjson first_order "$first_order_json" \
    --argjson second_order "$second_order_json" \
    --argjson filtered_mirrors_detail "$filtered_mirrors_json" \
    '{
      schema_version: $schema_version,
      cli_version: $cli_version,
      target: $target,
      scanned_at: $scanned_at,
      scan_root: $scan_root,
      depth: $depth,
      include_mirrors: $include_mirrors,
      stats: {
        total_files_scanned: $total_files_scanned,
        first_order_count: $first_order_count,
        second_order_count: $second_order_count,
        filtered_mirrors: $filtered_mirrors,
        elapsed_seconds: ($elapsed_seconds | tonumber)
      },
      first_order: $first_order,
      second_order: $second_order,
      filtered_mirrors_detail: $filtered_mirrors_detail
    }'
}
