#!/bin/bash
# run-theme-token-fixtures.sh — the TH-3 undeclared-consumer check, and its fixture self-test.
#
# TH-3 asserts: every CSS custom property CONSUMED by a themed artifact — after resolving
# the artifact's documented substitution placeholders — is DECLARED in every theme block of
# that artifact. It is the invariant that catches a `var(--x)` with no matching `--x:`.
#
# WHY IT EXISTS. A theme-aware SVG template emitted status colours through a substitution:
# `var(--{{S}}bg)`, `var(--{{S}}ln)`, `var(--{{S}})`, where `{{S}}` resolved to ok / warn /
# neut. For neut only `--neutbg` was declared, so stroke fell back to `none` and fill to
# initial black in BOTH themes — on the graceful-degradation path, where the row renders
# precisely when a composed surface is absent. A literal grep finds nothing, because the
# broken token names are produced by substitution rather than written. Declaration-parity
# checking cannot catch it either: a token absent from BOTH theme blocks passes parity
# trivially.
#
# THE PLACEHOLDER PROBLEM, AND WHY THE DOMAIN IS DECLARED RATHER THAN INFERRED. Resolving
# `var(--{{S}}ln)` to `--neutln` requires knowing {{S}}'s value set. Inferring it from the
# prose comment that documents it does not work: the live comments read `ok on GO, bad on
# NO-GO` and `ok when class is C1 or C2; warn when C3`, and a lowercase-word extractor
# returns {ok, on, bad} and {ok, when, class, is, or, warn}. That instrument cannot separate
# a token value from an English word, so it over-matches — and an over-matching probe is
# unusable, not lenient. The domain is therefore DECLARED, at the usage site, in a manifest
# comment the check parses:
#
#     <!-- subst: {{NAME}} = v1|v2|… ; <free prose explaining the rule> -->
#
# The human prose is retained on the same line, after the `;`, so the machine domain and the
# human explanation cannot drift into two sources. A genuinely unbounded domain declares
# `= *`; its consumers land in a printed UNBOUNDED / declared-uncoverable bucket so the
# coverage boundary is visible on every run. An UNMANIFESTED placeholder is never skipped —
# it is an UNRESOLVABLE row and the verdict is INDETERMINATE, exit 2. Skipping it is
# precisely the miss that produced the original defect: the denominator would be incomplete
# and the zero untrustworthy.
#
# THE CHECK CARRIES ITS OWN RECORD. Per the probe-validity discipline's INSTRUMENT FORM
# obligation (core/disciplines/review-discipline-principles.md § 8.1, PV-6): where the probe
# is a mechanized reusable check rather than an agent's one-shot invocation, the check ITSELF
# emits its denominator and its control-arm results as fields of its own output. A check whose
# runtime output states only a finding count has not discharged the denominator obligation
# (PV-1) or the control obligation (PV-2) — a reader cannot distinguish "zero found" from
# "nothing examined." Every scan below therefore prints its invocation, its subject and
# declaration-scope extraction sizes, its theme-block and declared-token counts, its manifest
# resolution counts, and its DENOMINATOR before it prints any result; and the fixture self-test
# prints both control arms with their extraction sizes on every invocation.
#
# SCOPE GATE — what the check reads, and why each boundary is where it is.
#   Subject region.       For a markdown file, the FENCED CODE BLOCKS only; for any other
#                         file, the whole file. Markdown prose ABOUT the mechanism
#                         (`var(--token)` in a sentence, `--token:` in a table cell) must
#                         never pair with itself and pass coincidentally. Excluding prose by
#                         construction is stronger than testing for it.
#   Declaration scope.    The `<style>`…`</style>` elements inside the subject region, with
#                         `<script>` bodies blanked FIRST so a `<style>` mentioned inside
#                         script text cannot open a bogus region. That case is live: an HTML
#                         surface in this corpus carries the string `<style>` inside a
#                         JavaScript comment describing a sanitizer.
#   Theme block.          A ROOT-SCOPE selector block (`:root` / `svg` / `html` / `*`, alone
#                         or in a comma list) that declares at least one custom property,
#                         keyed by its media context. Blocks under
#                         `@media (prefers-color-scheme: <v>)` key as `<v>`; blocks outside
#                         any media query key as `default`. A component-local declaration
#                         (`.card{--pad:4px}`) must NOT register as a theme block, or every
#                         global token would read as missing from it — such declarations are
#                         COUNTED and PRINTED as OUT-OF-ROOT rather than silently dropped.
#   Consumers.            Every `var(--…)` in the subject region, inside or outside `<style>`.
#                         The consumers live in element attributes, not in the style element.
#                         ASYMMETRY, stated because it is easy to assume otherwise: consumer
#                         collection reads the subject region RAW. Unlike the declaration
#                         scope above, it does NOT blank `<script>` bodies and does not skip
#                         CSS or HTML comments. A `var(--x)` written inside an inline
#                         `<script>` therefore COUNTS as a consumer and enters the
#                         denominator. On this corpus that is the wanted answer — 3 of
#                         `viewer.html`'s 88 resolutions are `var(--…)` inside JS strings
#                         that emit CSS at run time, and those really do consume the token —
#                         but it also means a `var(--…)` appearing only in a comment is
#                         counted, which would be a false finding. Consumer collection is
#                         context-blind by construction; that is a known boundary, not an
#                         inference from the declaration-scope rules.
#
# WHAT IS NOT COVERED — stated, not implied. A consumer produced by a substitution the source
# text does not document AT ALL (no `{{…}}` marker — a token name assembled at render time by
# string concatenation) is outside reach: TH-3 resolves documented placeholders, and an
# undocumented MECHANISM is not the same as an undocumented VALUE SET (which is caught, as
# INDETERMINATE). The full CSS cascade is not modelled — TH-3 models root-scope theming, this
# corpus's documented convention. Whether a declared token's VALUE is legible (contrast, tone
# — the property that made the original defect visible) is a distinct invariant and not this
# check's scope.
#
# MODES
#   (no args)          Run the committed fixture set. Both control arms are emitted.
#   --scan <file>      Run the TH-3 check against one file; emit its record.
#   --scan-corpus      Run the TH-3 check against every tracked file carrying BOTH a `<style>`
#                      element and at least one `var(--` consumer.
#
# EXIT CODES
#   0  clean / all fixture cases passed
#   1  findings (an undeclared consumer), or a fixture regression
#   2  INDETERMINATE — the check could not establish a trustworthy denominator: no subject
#      region, no theme block, no consumer, an unresolvable placeholder, a malformed domain
#      value, or a duplicate manifest entry. Never reported as clean.
#
# Shared by manual verification, core/deploy/deploy.sh Check 64, and any CI surface, so all
# three measure the same thing rather than three drifting copies.

set -euo pipefail
export PATH="/usr/bin:/bin"

readonly PRINTF="/usr/bin/printf"
readonly AWK="/usr/bin/awk"
readonly WC="/usr/bin/wc"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly FIXTURE_DIR_DEFAULT="${SCRIPT_DIR}/testdata/theme-token-fixtures"

# ─────────────────────────────────────────────────────────────────────────────
# The TH-3 predicate. One awk program, so the check and the fixture self-test can
# never measure two different things.
# ─────────────────────────────────────────────────────────────────────────────
read -r -d '' TH3_AWK <<'AWK_PROGRAM' || true
function trim(s) { gsub(/^[ \t\r\n]+/, "", s); gsub(/[ \t\r\n]+$/, "", s); return s }

function is_root_selector(sel,   parts, np, k, p) {
  sel = trim(sel)
  if (sel == "") return 0
  np = split(sel, parts, ",")
  for (k = 1; k <= np; k++) {
    p = trim(parts[k])
    if (p != ":root" && p != "svg" && p != "html" && p != "*") return 0
  }
  return 1
}

# Current block label from the selector stack: the media context, or "default".
# Returns "" when the innermost selector is not root-scope, or when a non-@media
# wrapper encloses it (a token declared inside .card > svg is not a theme block).
function block_label(   k, s, media, v, m) {
  if (depth < 1) return ""
  if (!is_root_selector(stack[depth])) return ""
  media = ""
  for (k = 1; k < depth; k++) {
    s = trim(stack[k])
    if (s ~ /^@media/) { media = s } else { return "" }
  }
  if (media == "") return "default"
  m = media
  if (match(m, /prefers-color-scheme[ \t]*:[ \t]*[A-Za-z-]+/)) {
    v = substr(m, RSTART, RLENGTH)
    sub(/^prefers-color-scheme[ \t]*:[ \t]*/, "", v)
    return v
  }
  gsub(/[ \t]+/, " ", m)
  return "media:" trim(m)
}

function handle_decl(txt,   name, lbl, e) {
  txt = trim(txt)
  if (txt !~ /^--[A-Za-z0-9_-]+[ \t]*:/) return
  e = index(txt, ":")
  name = trim(substr(txt, 1, e - 1))
  # NORMALISE OFF the leading `--`. Declarations are written `--bg:` and consumers
  # `var(--bg)`; the extractor for a consumer strips `var(--` and so yields `bg`. Holding
  # the two in different shapes makes every single token read as undeclared — a total
  # false alarm that still prints a healthy-looking denominator. Both sides are keyed on
  # the bare name from here down.
  name = substr(name, 3)
  lbl = block_label()
  if (lbl == "") { outofroot++; outofroot_names[name] = 1; return }
  if (!((lbl SUBSEP name) in decl)) {
    decl[lbl, name] = 1
    blocktokens[lbl]++
  }
  if (!(lbl in blocks)) { blocks[lbl] = 1; blockorder[++nblocks] = lbl }
}

{ line[NR] = $0 }

END {
  n = NR

  # ── Step 1 — subject region ────────────────────────────────────────────────
  is_md = (FNAME ~ /\.md$/ || FNAME ~ /\.markdown$/)
  infence = 0
  subj_lines = 0; subj_bytes = 0; file_bytes = 0
  for (i = 1; i <= n; i++) {
    file_bytes += length(line[i]) + 1
    if (is_md) {
      if (line[i] ~ /^[ \t]*(```|~~~)/) { infence = !infence; continue }
      if (!infence) continue
    }
    subj[i] = 1; subj_order[++subj_n] = i
    subj_lines++; subj_bytes += length(line[i]) + 1
  }

  # ── Step 2 — declaration scope: <style>…</style>, with <script> bodies blanked ──
  styletext = ""; style_bytes = 0; nregions = 0
  inscript = 0; instyle = 0
  for (oi = 1; oi <= subj_n; oi++) {
    L = line[subj_order[oi]]
    pos = 1; len = length(L)
    while (pos <= len + 1) {
      rest = substr(L, pos)
      if (inscript) {
        p = index(rest, "</script")
        if (p == 0) { pos = len + 2 } else { pos = pos + p + 7; inscript = 0 }
        continue
      }
      if (incomment) {
        p = index(rest, "-->")
        if (p == 0) { pos = len + 2 } else { pos = pos + p + 2; incomment = 0 }
        continue
      }
      if (instyle) {
        # The opening tag's own `>` (and any attributes) must NOT leak into the region:
        # a leading ">" would fuse onto the first selector and make `svg` read as `>svg`,
        # which is not a root selector — every light-theme declaration would then be
        # misfiled as OUT-OF-ROOT and the block would vanish from the denominator.
        if (awaiting_gt) {
          g = index(rest, ">")
          if (g == 0) { pos = len + 2; continue }
          pos = pos + g; awaiting_gt = 0; continue
        }
        p = index(rest, "</style")
        if (p == 0) {
          styletext = styletext rest "\n"; style_bytes += length(rest) + 1
          pos = len + 2
        } else {
          seg = substr(rest, 1, p - 1)
          styletext = styletext seg "\n"; style_bytes += length(seg) + 1
          pos = pos + p + 6; instyle = 0
        }
        continue
      }
      if (pos > len) break
      ps = index(rest, "<script")
      pt = index(rest, "<style")
      # An HTML COMMENT is the third thing that can carry the literal text `<style>` without
      # being a style element. It is entered ONLY from outside a region, so the legacy
      # `<style><!-- css --></style>` masking pattern still has its CSS read.
      pc = index(rest, "<!--")
      first = 0
      if (ps != 0) first = ps
      if (pt != 0 && (first == 0 || pt < first)) first = pt
      if (pc != 0 && (first == 0 || pc < first)) first = pc
      if (first == 0) break
      if (first == pc) { pos = pos + pc + 3; incomment = 1; continue }
      if (first == ps) { pos = pos + ps + 6; inscript = 1; continue }
      pos = pos + pt + 5; instyle = 1; awaiting_gt = 1; nregions++
    }
  }
  if (instyle) unterminated = 1
  if (inscript) unterminated_script = 1

  # ── Step 3 — theme blocks (char walk: comment-, quote- and brace-aware) ─────
  depth = 0; acc = ""; nblocks = 0; outofroot = 0
  slen = length(styletext); i = 1
  while (i <= slen) {
    c = substr(styletext, i, 1)
    if (c == "/" && substr(styletext, i + 1, 1) == "*") {
      e = index(substr(styletext, i + 2), "*/")
      if (e == 0) { i = slen + 1 } else { i = i + 2 + e + 1 }
      continue
    }
    if (c == "\"" || c == "'") {
      q = c; i++
      while (i <= slen && substr(styletext, i, 1) != q) i++
      i++
      continue
    }
    if (c == "{") { depth++; stack[depth] = acc; acc = ""; i++; continue }
    if (c == "}") {
      if (acc != "") handle_decl(acc)
      if (depth > 0) { delete stack[depth]; depth-- }
      acc = ""; i++; continue
    }
    if (c == ";") { handle_decl(acc); acc = ""; i++; continue }
    acc = acc c; i++
  }

  # ── Step 4 — substitution manifest ─────────────────────────────────────────
  nman = 0; dupman = 0; malformed = 0
  for (oi = 1; oi <= subj_n; oi++) {
    L = line[subj_order[oi]]
    if (index(L, "subst:") == 0) continue
    if (index(L, "<!--") == 0) continue
    p = index(L, "subst:"); rest = substr(L, p + 6)
    q = index(rest, "{{"); if (q == 0) { malformed++; malf[++nmalf] = trim(L); continue }
    r = index(rest, "}}"); if (r == 0 || r < q) { malformed++; malf[++nmalf] = trim(L); continue }
    name = substr(rest, q + 2, r - q - 2)
    after = substr(rest, r + 2)
    e = index(after, "="); if (e == 0) { malformed++; malf[++nmalf] = trim(L); continue }
    after = substr(after, e + 1)
    t1 = index(after, ";"); t2 = index(after, "-->")
    if (t1 > 0 && (t2 == 0 || t1 < t2)) dom = substr(after, 1, t1 - 1)
    else if (t2 > 0) dom = substr(after, 1, t2 - 1)
    else dom = after
    dom = trim(dom)
    if (name in manifest) {
      if (manifest[name] != dom) { dupman++; dupname[name] = manifest[name] " / " dom }
      continue
    }
    manifest[name] = dom; nman++
    if (dom == "*") { manunbounded[name] = 1; continue }
    nv = split(dom, vals, "|")
    if (nv == 0) { malformed++; malf[++nmalf] = trim(L); continue }
    for (k = 1; k <= nv; k++) {
      v = trim(vals[k])
      # Value regex. This is where the declared-manifest strategy refuses to inherit the
      # prose-inference failure: a leaked English word from the explanation side of the
      # comment fails here loudly instead of silently becoming a demanded token.
      if (v !~ /^[a-z][a-z0-9-]*$/) { malformed++; malf[++nmalf] = "{{" name "}} value [" v "]"; continue }
      mvals[name, ++mcount[name]] = v
    }
  }

  # ── Step 5 — consumers over the subject region ─────────────────────────────
  ncons = 0
  for (oi = 1; oi <= subj_n; oi++) {
    s = line[subj_order[oi]]
    while ((p = index(s, "var(--")) > 0) {
      rest = substr(s, p + 6)
      match(rest, /^[^),; \t]*/)
      tok = substr(rest, 1, RLENGTH)
      if (tok != "") { cons[++ncons] = tok; cons_line[ncons] = subj_order[oi] }
      s = substr(rest, RLENGTH + 1)
    }
  }

  # ── Step 6 — resolve ───────────────────────────────────────────────────────
  lit_occ = 0; subst_res = 0; unbounded_occ = 0; nunres = 0; nres = 0
  for (ci = 1; ci <= ncons; ci++) {
    tok = cons[ci]
    if (index(tok, "{{") == 0) {
      lit_occ++
      if (!(tok in resolved)) { resolved[tok] = 1; reslist[++nres] = tok; res_first[tok] = cons_line[ci] }
      continue
    }
    # Collect the placeholder names appearing in this token.
    nph = 0; work = tok; delete phn
    while ((a = index(work, "{{")) > 0) {
      b = index(work, "}}"); if (b == 0 || b < a) break
      phn[++nph] = substr(work, a + 2, b - a - 2)
      work = substr(work, b + 2)
    }
    bad = 0; unb = 0
    for (k = 1; k <= nph; k++) {
      if (!(phn[k] in manifest)) {
        bad = 1
        if (!(phn[k] in unres_seen)) { unres_seen[phn[k]] = 1; unreslist[++nunres] = phn[k] }
        unres_tok[tok] = cons_line[ci]
      } else if (phn[k] in manunbounded) { unb = 1 }
    }
    if (bad) { continue }
    if (unb) { unbounded_occ++; unbounded_tok[tok] = 1; continue }
    # Cartesian expansion over the declared domains.
    delete cur; ncur = 1; cur[1] = tok
    for (k = 1; k <= nph; k++) {
      delete nxt; nnxt = 0
      for (j = 1; j <= ncur; j++) {
        for (m = 1; m <= mcount[phn[k]]; m++) {
          t = cur[j]; sub(/\{\{[A-Za-z0-9_]+\}\}/, mvals[phn[k], m], t)
          nxt[++nnxt] = t
        }
      }
      delete cur; ncur = nnxt
      for (j = 1; j <= nnxt; j++) cur[j] = nxt[j]
    }
    for (j = 1; j <= ncur; j++) {
      subst_res++
      if (!(cur[j] in resolved)) { resolved[cur[j]] = 1; reslist[++nres] = cur[j]; res_first[cur[j]] = cons_line[ci] }
    }
  }
  denom = lit_occ + subst_res

  # ── Step 7 — assert: every resolution declared in every theme block ────────
  nfind = 0
  for (ri = 1; ri <= nres; ri++) {
    tok = reslist[ri]
    for (bi = 1; bi <= nblocks; bi++) {
      lbl = blockorder[bi]
      # EXACT array lookup, never a substring or prefix test: --neutlnx must not
      # satisfy a --neutln consumer, and `--neut:#5b6169` (no space after the colon)
      # must parse identically to `--neut: #5b6169`. Both are normalised before this
      # point, so the comparison here is byte-exact on the token name alone.
      if (!((lbl SUBSEP tok) in decl)) {
        nfind++
        find[nfind] = sprintf("MISSING --%s  in theme block [%s]  (first consumed at line %d)", tok, lbl, res_first[tok])
      }
    }
  }

  # ── Step 8 — emit the record, then the verdict ─────────────────────────────
  blist = ""
  for (bi = 1; bi <= nblocks; bi++) blist = blist (bi > 1 ? "," : "") blockorder[bi]
  printf("TH-3 undeclared-consumer check — %s\n", FNAME)
  printf("  [PV-0] invocation      : run-theme-token-fixtures.sh --scan %s\n", FNAME)
  printf("  [PV-3] subject region  : %d lines, %d bytes (of %d file bytes)%s\n",
         subj_lines, subj_bytes, file_bytes, (is_md ? "  [markdown: fenced blocks only]" : ""))
  printf("  [PV-3] declaration scope: %d <style> region(s), %d bytes\n", nregions, style_bytes)
  printf("  [PV-1] theme blocks    : %d (%s)\n", nblocks, (blist == "" ? "none" : blist))
  for (bi = 1; bi <= nblocks; bi++)
    printf("                           block [%s] declares %d token(s)\n", blockorder[bi], blocktokens[blockorder[bi]])
  if (outofroot > 0) {
    oon = ""
    for (nm in outofroot_names) oon = oon (oon == "" ? "" : ",") "--" nm
    printf("  [PV-1] OUT-OF-ROOT     : %d non-root custom-property declaration(s) counted, not treated as a theme block: %s\n", outofroot, oon)
  } else {
    printf("  [PV-1] OUT-OF-ROOT     : 0 non-root custom-property declarations\n")
  }
  printf("  [PV-1] placeholders    : %d manifest entr(ies); unresolvable %d; unbounded(*) %d occurrence(s)\n",
         nman, nunres, unbounded_occ)
  printf("  [PV-1] DENOMINATOR     : %d consumer resolutions (%d literal + %d substituted) x %d theme block(s) = %d assertions\n",
         denom, lit_occ, subst_res, nblocks, denom * nblocks)

  if (dupman > 0) for (nm in dupname) printf("  [!] duplicate manifest entries for {{%s}}: %s\n", nm, dupname[nm])
  for (k = 1; k <= nmalf; k++) printf("  [!] malformed manifest: %s\n", malf[k])
  for (k = 1; k <= nunres; k++) printf("  UNRESOLVABLE           : {{%s}} consumed but carries no `subst:` manifest entry\n", unreslist[k])
  if (unbounded_occ > 0) for (t in unbounded_tok) printf("  UNBOUNDED              : var(--%s) — domain declared `*`; declared-uncoverable\n", t)

  # Fail-loud arms. A resolver that finds no declarations flags everything; one that
  # finds no consumers reports a vacuous CLEAN. Neither is allowed to pass silently.
  reason = ""
  if (subj_bytes == 0) reason = "subject region is empty (no fenced code block / no file content)"
  else if (unterminated) reason = "unterminated <style> element (no closing tag before EOF)"
  else if (unterminated_script) reason = "unterminated <script> element (no closing tag before EOF)"
  else if (nregions == 0) reason = "no <style> region in the subject"
  else if (nblocks == 0) reason = "no theme block (no root-scope selector declaring a custom property)"
  else if (ncons == 0) reason = "no var(--) consumer in the subject region"
  else if (nunres > 0) reason = sprintf("%d unresolvable placeholder(s) — the denominator is incomplete", nunres)
  else if (dupman > 0) reason = "duplicate manifest entries with conflicting domains"
  else if (malformed > 0) reason = sprintf("%d malformed manifest declaration(s)", malformed)

  if (reason != "") {
    printf("  RESULT                 : not established\n")
    printf("  VERDICT                : INDETERMINATE (PV-1) — %s. NOT clean.\n", reason)
    exit 2
  }
  if (nfind > 0) {
    for (k = 1; k <= nfind; k++) printf("  %s\n", find[k])
    printf("  RESULT                 : %d undeclared consumer(s)\n", nfind)
    printf("  VERDICT                : FINDINGS\n")
    exit 1
  }
  printf("  RESULT                 : 0 undeclared consumer(s)\n")
  if (unbounded_occ > 0)
    printf("  VERDICT                : CLEAN (with %d declared-uncoverable unbounded consumer(s))\n", unbounded_occ)
  else
    printf("  VERDICT                : CLEAN\n")
  exit 0
}
AWK_PROGRAM

th3_scan() {
  local f="$1" rc=0
  if [ ! -f "$f" ]; then
    "$PRINTF" 'FAIL: file not found: %s\n' "$f" >&2
    return 2
  fi
  "$AWK" -v FNAME="$f" "$TH3_AWK" "$f" || rc=$?
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────
# Mode dispatch
# ─────────────────────────────────────────────────────────────────────────────
MODE="fixtures"
TARGET=""
FIXTURE_DIR="$FIXTURE_DIR_DEFAULT"
while [ $# -gt 0 ]; do
  case "$1" in
    --scan)         MODE="scan"; TARGET="${2:-}"; shift 2 ;;
    --scan-corpus)  MODE="corpus"; shift ;;
    --fixtures)     FIXTURE_DIR="${2:-}"; shift 2 ;;
    *)              "$PRINTF" 'FAIL: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ "$MODE" = "scan" ]; then
  [ -n "$TARGET" ] || { "$PRINTF" 'FAIL: --scan requires a file argument\n' >&2; exit 2; }
  rc=0; th3_scan "$TARGET" || rc=$?
  exit "$rc"
fi

if [ "$MODE" = "corpus" ]; then
  # Scope gate: a tracked DOCUMENT (.md / .html / .htm / .svg / .xhtml) carrying BOTH a
  # <style> element and >=1 var(-- consumer. A content predicate, not an enumerated path
  # list — a new themed artifact is covered on creation rather than on someone remembering
  # to register it.
  #
  # TWO EXCLUSIONS, both load-bearing, both stated rather than implied.
  #   core/hooks/testdata/**  — fixture trees carry deliberate defects as their whole
  #                             purpose. Scanning them makes the gate red by construction
  #                             and says nothing about the corpus. Same exemption Check 63
  #                             carries, for the same reason.
  #   non-document files      — a shell script or a generator that merely MENTIONS `var(--`
  #                             in a comment is not a themed artifact. Without this, THIS
  #                             FILE scans itself: its own documentation quotes the manifest
  #                             grammar and the `<style>` tag, and the scan returns
  #                             INDETERMINATE on the checker rather than on the corpus.
  #
  # DECLARED COVERAGE BOUNDARY. A SEPARATE generator file that emits themed CSS at run time
  # (markup built inside a standalone .py or .js) is not covered: it is not a document, the
  # extension gate above excludes it, and a generated document is not one until it is written.
  # This boundary is about the STANDALONE generator only. An INLINE `<script>` inside a gated
  # document is a different case and IS read — consumer collection is context-blind, so a
  # `var(--…)` in an inline script counts (see the Consumers bullet in the header). Do not
  # read this paragraph as saying run-time-emitted consumers are excluded across the board;
  # 3 of the live population's resolutions are exactly that. Stated, not implied.
  worst=0; scanned=0
  files="$(/usr/bin/git grep -l -- "var(--" -- '*.md' '*.html' '*.htm' '*.svg' '*.xhtml' 2>/dev/null || true)"
  "$PRINTF" 'TH-3 corpus scan — scope gate: tracked documents with a <style> element AND >=1 var(--) consumer (fixture trees exempt)\n'
  for f in $files; do
    case "$f" in core/hooks/testdata/*) continue ;; esac
    /usr/bin/grep -q -- "<style" "$f" || continue
    scanned=$((scanned + 1))
    rc=0; th3_scan "$f" || rc=$?
    [ "$rc" -gt "$worst" ] && worst="$rc"
  done
  "$PRINTF" 'TH-3 corpus scan: %d file(s) in the gated population; worst verdict exit %d\n' "$scanned" "$worst"
  if [ "$scanned" -eq 0 ]; then
    "$PRINTF" 'FAIL: the gated population is EMPTY. A clean zero over an empty population is exactly what this check must never report.\n' >&2
    exit 2
  fi
  exit "$worst"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Fixture self-test (default mode) — the two-armed control, emitted every run.
#
# MANIFEST format:  <EXPECT>\t<fixture-filename>\t<what the case varies>
#   EXPECT = CLEAN         must-not-flag  (specificity arm; PASS condition is ZERO findings)
#          = FINDINGS      must-flag      (sensitivity arm; PASS condition is NON-ZERO)
#          = INDETERMINATE fail-loud      (verdict arm; the check must refuse to report clean)
#
# HARD FAIL — not a pass — when either arm is EMPTY, or when any case's own extraction is
# 0 bytes. A specificity arm whose input was empty returns zero, which is that arm's PASS
# condition, and therefore reads as a passing control while proving nothing. It is vacuous,
# not passing (PV-5).
# ─────────────────────────────────────────────────────────────────────────────
MANIFEST="${FIXTURE_DIR}/MANIFEST"
if [ ! -f "$MANIFEST" ]; then
  "$PRINTF" 'FAIL: fixture manifest not found: %s\n' "$MANIFEST" >&2
  exit 1
fi

pass=0; fail=0; fail_lines=""
sens_total=0; sens_flagged=0; sens_bytes=0
spec_total=0; spec_flagged=0; spec_bytes=0
indet_total=0; indet_ok=0; indet_bytes=0
vacuous=""

while IFS= read -r raw || [ -n "$raw" ]; do
  case "$raw" in ''|'#'*) continue ;; esac
  expect="$(printf '%s' "$raw" | cut -f1)"
  fname="$(printf '%s' "$raw" | cut -f2)"
  [ -z "$expect" ] && continue
  fpath="${FIXTURE_DIR}/${fname}"
  if [ ! -f "$fpath" ]; then
    fail=$((fail + 1)); fail_lines="${fail_lines}  fixture missing: ${fname}"$'\n'; continue
  fi
  fbytes="$("$WC" -c < "$fpath" | tr -d ' ')"
  if [ "$fbytes" -eq 0 ]; then
    vacuous="${vacuous}${fname} "
  fi

  rc=0; out="$(th3_scan "$fpath" 2>&1)" || rc=$?
  case "$rc" in
    0) got="CLEAN" ;;
    1) got="FINDINGS" ;;
    *) got="INDETERMINATE" ;;
  esac

  case "$expect" in
    FINDINGS)      sens_total=$((sens_total + 1)); sens_bytes=$((sens_bytes + fbytes))
                   [ "$got" = "FINDINGS" ] && sens_flagged=$((sens_flagged + 1)) ;;
    CLEAN)         spec_total=$((spec_total + 1)); spec_bytes=$((spec_bytes + fbytes))
                   [ "$got" != "CLEAN" ] && spec_flagged=$((spec_flagged + 1)) ;;
    INDETERMINATE) indet_total=$((indet_total + 1)); indet_bytes=$((indet_bytes + fbytes))
                   [ "$got" = "INDETERMINATE" ] && indet_ok=$((indet_ok + 1)) ;;
  esac

  if [ "$got" = "$expect" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    fail_lines="${fail_lines}  expected ${expect} got ${got}: ${fname}"$'\n'
    fail_lines="${fail_lines}$(printf '%s' "$out" | sed 's/^/      /')"$'\n'
  fi
done < "$MANIFEST"

"$PRINTF" 'TH-3 fixture self-test: %d must-flag case(s) -> %d flagged (sensitivity arm: %s)\n' \
  "$sens_total" "$sens_flagged" \
  "$( [ "$sens_total" -gt 0 ] && [ "$sens_flagged" -eq "$sens_total" ] && echo "NON-ZERO, PASS" || echo "FAIL" )"
"$PRINTF" '                       %d must-not-flag case(s) -> %d flagged (specificity arm: %s)\n' \
  "$spec_total" "$spec_flagged" \
  "$( [ "$spec_total" -gt 0 ] && [ "$spec_flagged" -eq 0 ] && echo "ZERO, PASS" || echo "FAIL" )"
"$PRINTF" '                       %d fail-loud case(s) -> %d refused to report clean (verdict arm)\n' \
  "$indet_total" "$indet_ok"
"$PRINTF" '                       extraction: %d bytes sensitivity / %d bytes specificity / %d bytes fail-loud, all non-empty required\n' \
  "$sens_bytes" "$spec_bytes" "$indet_bytes"
"$PRINTF" 'TH-3 fixture self-test: %d passed, %d failed (fixtures: %s)\n' "$pass" "$fail" "$FIXTURE_DIR"

# Arm-emptiness and vacuity are hard failures, never a green run.
if [ "$sens_total" -eq 0 ]; then
  "$PRINTF" 'FAIL: the sensitivity arm is EMPTY (0 must-flag cases). A probe that was never shown to detect proves nothing by returning zero.\n' >&2
  exit 1
fi
if [ "$spec_total" -eq 0 ]; then
  "$PRINTF" 'FAIL: the specificity arm is EMPTY (0 must-not-flag cases). A probe that was never shown to discriminate cannot be trusted when it flags.\n' >&2
  exit 1
fi
if [ -n "$vacuous" ]; then
  "$PRINTF" 'FAIL: zero-byte fixture input(s): %s— that arm is VACUOUS, not passing.\n' "$vacuous" >&2
  exit 1
fi
if [ "$fail" -gt 0 ]; then
  "$PRINTF" '%s' "$fail_lines" >&2
  exit 1
fi
exit 0
