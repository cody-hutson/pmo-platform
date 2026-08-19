# command-position.awk — shared command-start canonicalizer for the regex-anchored
# PreToolUse security hooks.
#
# READ, never executed as a script. Invoked as `awk -f command-position.awk`, exactly
# like the co-shipped positional-issueref.awk classifier. Consumers guard it with
# deny_missing_primitive (lib/dep-resolve.sh) so a missing or corrupt copy fails CLOSED.
#
# WHY THIS EXISTS
# ---------------
# Four PreToolUse hooks (block-destructive, block-egress, block-fs-boundary,
# block-rm-prefer-trash) share one byte-identical anchor:
#
#   ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'
#
# That anchor recognises a command-start position ONLY at start-of-line or immediately
# after `;`, `&`, `|`. Every other position at which a shell actually starts a command is
# invisible to it: grouping (`{ … }`, `( … )`), compound-command keywords (`then`, `do`),
# command-prefix words (`sudo`, `time`, `env`, `xargs`, `VAR=…`), and an escaped verb
# (`\rm`). The verdict therefore tracked LEXICAL POSITION rather than the action, and the
# identical command changed verdict depending on where it sat.
#
# THE ARCHITECTURE (the part that makes widening safe)
# ---------------------------------------------------
# The anchor is NOT widened. Instead this canonicalizer runs first and rewrites the
# command so that positions which ARE genuine command starts become positions the
# existing anchor already recognises — by inserting `; ` in front of them. The regexes,
# the rule IDs, the block messages and the per-hook token extractors are untouched.
#
# Two properties make that FP-safe rather than merely broader:
#
#   1. INSERTION-ONLY on the syntactic axis. The canonicalizer never deletes, reorders or
#      rewrites command text (the one exception is documented at (b) below). Anything the
#      anchor matched before it still matches; the widening is purely additive.
#   2. QUOTE-NEUTRALISED command-start detection. Structural characters inside a quoted
#      span cannot open a segment, so shell text carried AS CONTENT — `echo "cleanup() {
#      rm -rf /tmp/x; }" > s.sh`, `sed 's/(rm foo)/X/'`, `grep -E '(rm |mv)' f` — is not a
#      command start and gets no insertion. That is load-bearing, not cosmetic: writing a
#      shell script as content is ordinary work, and a guard that fires on it gets
#      disabled by the operator, which is a worse security outcome than the gap it closed.
#
# The prefix-word set is a BOUNDED ENUMERATION, never a wildcard — an unknown leading word
# is treated as the command, exactly as today.
#
# TRANSFORMATIONS (the complete list)
#   (a) `; ` inserted before each resolved command-start token (never at offset 1).
#   (b) a single leading backslash dropped from a resolved command-start token, so `\rm`
#       reads as the verb `rm` for both the regex and the per-hook token extractor. This
#       is the sole non-insertion edit and it applies only to the verb position.
#   (c) ` $XARGS-STDIN` appended to a segment whose prefix-skip consumed `xargs`. The
#       token is deliberately variable-shaped: it resolves to the EXISTING unresolvable
#       branch of each token extractor, so `… | xargs rm -rf` denies through the rule that
#       already exists rather than through a new one. No new rule ID is introduced.
#   (d) command-structural characters INSIDE a quoted span replaced by \001. Quote marks
#       themselves are PRESERVED, and no other content is altered, so every downstream
#       consumer (resolve_and_classify, the -022 segment loop, the osascript extractor)
#       sees the token text it saw before.
#
# WHAT IT DELIBERATELY DOES NOT CLOSE (residual, by construction)
#   - Nested / deferred program strings: `bash -c '…'`, `sh -c '…'`, `eval '…'`,
#     `alias x='…'`, and `$( … )` / backtick substitution bodies. Delimiter recognition is
#     suppressed inside `$( … )` for the same reason: the inner text is a program for
#     another shell, not this one. This is the `nested-shell` residual already recorded in
#     core/rules/bypass-mode-readiness.md with an explicit deferral decision.
#   - Other deletion mechanisms (`find … -exec`, `find … -delete`) — a different residual.
#   - Heredoc bodies. `grep` is line-oriented, so the `^` half of the anchor already
#     matches at every line start; this file neither improves nor worsens that.
#   A lexical canonicalizer has a coverage boundary BY CONSTRUCTION: it approximates a
#   grammar it does not parse. Completeness needs a real parser across all four hooks.
#
# FAIL DIRECTION
#   Unbalanced quotes make the mask unreliable, so the input is echoed back UNCHANGED —
#   the consuming hook then behaves exactly as it does today rather than on a mask that
#   might be inverted. Never worse than the status quo. Consumers additionally canary this
#   file before trusting its output, because a truncated or corrupt copy would emit an
#   empty string and take the hook's whole matcher with it.

BEGIN {
  SENT = sprintf("%c", 1)

  # Bounded prefix-word enumeration. An unlisted leading word is the command.
  PREFIX["then"]=1;  PREFIX["do"]=1;      PREFIX["else"]=1;    PREFIX["elif"]=1
  PREFIX["in"]=1;    PREFIX["!"]=1;       PREFIX["sudo"]=1;    PREFIX["time"]=1
  PREFIX["env"]=1;   PREFIX["nohup"]=1;   PREFIX["command"]=1; PREFIX["builtin"]=1
  PREFIX["exec"]=1;  PREFIX["xargs"]=1
  MAX_PREFIX_SKIP = 10
}

# Accumulate the whole command; a Bash tool call may legitimately span lines and a quoted
# span may cross a newline, so command-start detection cannot be per-line.
{ buf = (NR > 1 ? buf "\n" : "") $0 }

# ---------------------------------------------------------------------------
# Pass A — build `out` (emitted text) and `mask` (per-position syntactic state).
#   mask "N" = unquoted, unescaped, outside command substitution — syntactically active
#   mask "X" = quoted content, escaped char, or inside $( … ) — inert for segmentation
# Returns 0 on unbalanced quotes.
# ---------------------------------------------------------------------------
function scan(   i, n, c, d, prev, state, depth, ok) {
  n = length(buf); out = ""; mask = ""; state = 0; depth = 0; i = 1
  while (i <= n) {
    c = substr(buf, i, 1)

    if (state == 0) {
      # --- command substitution: `$(` opens an inner shell; suppress all structure ---
      if (c == "$" && substr(buf, i + 1, 1) == "(") {
        out = out "$("; mask = mask "XX"; depth = 1; i += 2
        while (i <= n && depth > 0) {
          d = substr(buf, i, 1)
          if (d == "(") depth++
          else if (d == ")") depth--
          out = out d; mask = mask "X"; i++
        }
        continue
      }
      if (c == "\\") {                       # escape — both chars inert
        out = out c; mask = mask "X"; i++
        if (i <= n) { out = out substr(buf, i, 1); mask = mask "X"; i++ }
        continue
      }
      if (c == "#" && at_word_start(i)) {    # comment: neutralise ONLY its quote marks,
        while (i <= n) {                     # so quote parity cannot desynchronise. The
          d = substr(buf, i, 1)              # body is NOT stripped — a `;` in a comment
          if (d == "\n") break               # already opens a segment today and must keep
          out = out ((d == "\"" || d == "'") ? SENT : d)
          mask = mask "N"                    # doing so (block-egress.sh precedent).
          i++
        }
        continue
      }
      if (c == "'" || c == "\"") {
        state = (c == "'") ? 1 : 2
        out = out c; mask = mask "X"; i++    # quote mark preserved
        continue
      }
      out = out c; mask = mask "N"; i++
      continue
    }

    # --- inside a quoted span ---
    if (state == 2 && c == "\\") {           # double quotes have an escape mechanism
      out = out c; mask = mask "X"; i++
      if (i <= n) { out = out substr(buf, i, 1); mask = mask "X"; i++ }
      continue
    }
    if ((state == 1 && c == "'") || (state == 2 && c == "\"")) {
      state = 0; out = out c; mask = mask "X"; i++
      continue
    }
    out = out (is_structural(c) ? SENT : c)  # (d) — structure inside quotes is inert
    mask = mask "X"; i++
  }
  return (state == 0)
}

function is_structural(c) {
  return (c == ";" || c == "&" || c == "|" || c == "(" || c == ")" \
       || c == "{" || c == "}" || c == "\n" || c == "`")
}

# A `#` opens a comment only at the start of a word.
function at_word_start(i,   p) {
  if (i == 1) return 1
  p = substr(buf, i - 1, 1)
  return (p == " " || p == "\t" || p == "\n" || p == ";" || p == "&" || p == "|")
}

# Delimiter test — evaluated ONLY at mask "N" positions.
#   `{` and `}` need their shell-required whitespace, so brace EXPANSION (`{a,b}.env`)
#   is not mistaken for a group command and its argument is not split.
function is_delim(i,   c, nx, pv) {
  c = substr(out, i, 1)
  if (c == ";" || c == "&" || c == "|" || c == "\n") return 1
  if (c == "(" || c == ")") return 1
  if (c == "{") { nx = substr(out, i + 1, 1); return (nx == " " || nx == "\t" || nx == "\n") }
  if (c == "}") {
    if (i == 1) return 0
    pv = substr(out, i - 1, 1)
    return (pv == " " || pv == "\t" || pv == "\n" || pv == ";")
  }
  return 0
}

function is_blank(c) { return (c == " " || c == "\t" || c == "\n") }

# ---------------------------------------------------------------------------
# Pass B — walk segments, resolve each command-start token, record the edits.
# ---------------------------------------------------------------------------
function locate(   i, n, segstart, ins_n) {
  n = length(out); segstart = 1
  for (i = 1; i <= n; i++) {
    if (substr(mask, i, 1) == "N" && is_delim(i)) {
      resolve_segment(segstart, i - 1)
      segstart = i + 1
    }
  }
  resolve_segment(segstart, n)
}

# Find the first token of [lo,hi], skip the bounded prefix set, and record the edits.
function resolve_segment(lo, hi,   i, t_start, t_end, tok, skips, xflag) {
  if (lo > hi) return
  i = lo; skips = 0; xflag = 0
  while (skips <= MAX_PREFIX_SKIP) {
    while (i <= hi && is_blank(substr(out, i, 1)) && substr(mask, i, 1) == "N") i++
    if (i > hi) return
    t_start = i
    t_end = i
    while (t_end <= hi && !(is_blank(substr(out, t_end, 1)) && substr(mask, t_end, 1) == "N")) t_end++
    t_end--
    tok = substr(out, t_start, t_end - t_start + 1)

    if (tok in PREFIX) {
      if (tok == "xargs") xflag = 1
      i = t_end + 1; skips++
      continue
    }
    if (tok ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i = t_end + 1; skips++; continue }   # VAR=value
    if (tok ~ /^[0-9]*(>>|>|<)/) {                                               # redirect
      i = t_end + 1; skips++
      if (tok ~ /(>>|>|<)$/) {                        # operand is a separate token
        while (i <= hi && is_blank(substr(out, i, 1))) i++
        while (i <= hi && !is_blank(substr(out, i, 1))) i++
      }
      continue
    }
    break
  }
  if (t_start > hi) return

  # (b) drop one leading backslash on the verb position only
  if (substr(out, t_start, 1) == "\\") drop[t_start] = 1

  # (a) `; ` before the command start — never at the very start of the command
  if (t_start > 1) ins[t_start] = "; "

  # (c) xargs feeds the verb from stdin: no argv target exists, so emit the sentinel that
  #     routes to each extractor's EXISTING unresolvable branch.
  if (xflag) tail[hi + 1] = " $XARGS-STDIN"
}

function emit(   i, n, res) {
  n = length(out); res = ""
  for (i = 1; i <= n; i++) {
    if (i in ins)  res = res ins[i]
    if (i in tail) res = res tail[i]
    if (i in drop) continue
    res = res substr(out, i, 1)
  }
  if ((n + 1) in tail) res = res tail[n + 1]
  return res
}

END {
  if (!scan()) { printf "%s", buf; exit 0 }   # unbalanced quotes — status quo, unchanged
  locate()
  printf "%s", emit()
}
