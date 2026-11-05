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
#      rewrites command text (the one exception is documented at (b) below). A rule
#      anchored on a command position still matches everything it matched before, for
#      the verb it anchors on. Two narrowings of that property are stated rather than
#      left to be discovered. A rule anchored on a WORD BOUNDARY (the git rules of
#      block-destructive) can lose a match when a wrapper's own grammar consumes `git` as
#      an option value or a positional, because the separator then lands between `git`
#      and its subcommand: `sudo -u git push --force` runs `push` as the user git and
#      never runs git, so that move is a declared precision improvement. And an exit that
#      ALLOWS on a match must never read this output: every widening here widens such an
#      exit too, turning a refusal into an allow. Such an exit reads the EXIT VIEW below.
#   2. QUOTE-NEUTRALISED command-start detection. Structural characters inside a quoted
#      span cannot open a segment, so shell text carried AS CONTENT — `echo "cleanup() {
#      rm -rf /tmp/x; }" > s.sh`, `sed 's/(rm foo)/X/'`, `grep -E '(rm |mv)' f` — is not a
#      command start and gets no insertion. That is load-bearing, not cosmetic: writing a
#      shell script as content is ordinary work, and a guard that fires on it gets
#      disabled by the operator, which is a worse security outcome than the gap it closed.
#
# The prefix-word set is a BOUNDED ENUMERATION, never a wildcard — an unknown leading word
# is treated as the command, exactly as before.
#
# THE PREFIX WALK
# ---------------
# A segment's command word is found by stepping over its prefix run: a compound-command
# keyword (then do else elif in ! if while until), a transparent wrapper (sudo env command
# builtin exec nohup time xargs nice stdbuf timeout), an assignment — `NAME=value` or its
# append form `NAME+=value`, which bash and zsh both read as an assignment word — and a
# redirection. A prefix word is matched on its BASENAME (`/usr/bin/env` is env), after one
# leading backslash and full-token quotes are dropped (`\sudo` and `"sudo"` are sudo). That
# lookup comes after the token, as written, is tested as an assignment and as a redirection,
# so an assignment whose value is a path and a redirection whose attached target is one are
# what the shell reads them as, never the wrapper their last path segment names. A
# wrapper is stepped together with its OWN grammar: its option run, then its positional
# operands, read from the rows below — so `nice -n 10 rm …`, `sudo -u root rm …` and
# `timeout 5 rm …` resolve `rm`, as `rm` alone does. The rows are a COPY of the wrapper
# rows of the BLOCK-DESTRUCTIVE-022 walk in block-destructive.sh (script_wrapper_row),
# field for field, and the suite's WRAPROWS-PARITY arms assert the copy equal. The option
# facts are data about a program, so both walks read the same facts; the walk below ports
# that walk's option, long-option and split-string handling.
#
# What the walk does not reach, by construction (stated, not argued away):
#   - an option no row lists that takes a SEPARATE value: the value is read as the
#     command word and nothing is reached — the status quo for every wrapper option
#     before the rows existed, and the direction the -022 walk records for the same rows;
#   - a launcher outside the set (`doas`, `setsid`, `caffeinate`, …): it is the command;
#   - a describe-only option (`command -v`, `sudo -l`) or an attached split string that
#     carries a command word (`env -Srm …`): the walk stops ON that token, which is then
#     the command word, so nothing behind it is promoted;
#   - more than ten prefix-run tokens (MAX_PREFIX_SKIP): a guarded word behind the
#     eleventh is not reached. A wrapper's own options and operands do not count toward
#     the cap.
#
# THE EXIT VIEW
# -------------
# Run with `-v CMDPOS_VIEW=exit`, this file emits the EXIT VIEW: the same quote mask and
# the same command-start insertions ((a) to (c)) as the default output — never (e)'s —
# made by the prefix walk as it stood before the wrapper grammar joined it: the fourteen
# original words, matched as exact tokens, each stepped as one token, and the `NAME=value`
# assignment alone — never its append form. It is read only by
# exits that ALLOW on a match (the deletion hook's git exemption and its no-target exit),
# so those exits keep the verdicts they had while the default output widens. The exit
# view is frozen: a transformation added to the default walk does not reach it.
#
# BOTH VIEWS FROM ONE RUN
# -----------------------
# Run with `-v CMDPOS_VIEW=both`, this file emits the exit view and then the default output,
# each ended by a NUL byte, from one quote mask: the exit view's walk and then the default
# walk run over the same segments, and each view is the one its own mode emits, without its
# trailing newlines, as a command substitution captures it. A consumer that reads both views
# (the deletion hook) pays for one run of this file, not two. When the two walks record the
# same edits the two views are the same text, built once. No input can hold a NUL byte, so
# the two records cannot be confused; a copy without this mode emits no NUL at all.
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
#   (e) `; ` inserted before each assignment the default walk skips (never at offset 1): a
#       `NAME=value` or `NAME+=value` word of the prefix run, and each word of env's
#       assignment run — the words after its options, up to the first that carries no `=` or
#       begins with a dash, which is how env reads them. env assigns such a word literally, so
#       an append-shaped operand sets a variable whose name ends in `+`: marking it is a
#       declared over-block in the safe direction. A rule anchored on an assignment rather than
#       a verb (BLOCK-DESTRUCTIVE-020, -023) then reads one handed to a wrapper, behind another
#       assignment or a redirection, after a keyword or `!`, at a condition position or as
#       the first word of a group, as it reads one at a command start. Insertion-only, and
#       only on tokens the walk already resolved as assignments: the verb keeps its own
#       insertion from (a), and no verb pattern can match an assignment token, so a rule
#       anchored on a verb neither gains nor loses a match. An assignment behind more than
#       ten prefix-run tokens is not marked. The exit view does not carry (e).
#
# WHAT IT DELIBERATELY DOES NOT CLOSE (residual, by construction)
#   - Nested / deferred program strings: `bash -c '…'`, `sh -c '…'`, `eval '…'`,
#     `alias x='…'`, and `$( … )` / backtick substitution bodies. Delimiter recognition is
#     suppressed inside `$( … )` for the same reason: the inner text is a program for
#     another shell, not this one. This is the `nested-shell` residual already recorded in
#     core/rules/bypass-mode-readiness.md with an explicit deferral decision.
#   - Other deletion mechanisms (`find … -exec`, `find … -delete`) — a different residual.
#   - Heredoc bodies. `grep` is line-oriented, so the `^` half of the anchor already
#     matches at every line start; and a body line that begins with a prefix word is
#     walked like any other line, so prose such as `nice rm stale-cache` inside a heredoc
#     reads as a command start — a declared over-block of the same class as `then rm …`.
#   A lexical canonicalizer has a coverage boundary BY CONSTRUCTION: it approximates a
#   grammar it does not parse. Completeness needs a real parser across all four hooks.
#
# FAIL DIRECTION
#   Unbalanced quotes make the mask unreliable, so the input is echoed back UNCHANGED —
#   the consuming hook then behaves exactly as it does today rather than on a mask that
#   might be inverted. Never worse than the status quo. Consumers additionally canary this
#   file before trusting its output, because a truncated or corrupt copy would emit an
#   empty string and take the hook's whole matcher with it; a second canary probe — an
#   append-form assignment ahead of a wrapper carrying a separate-argument option —
#   distinguishes this walk from the one before the wrapper grammar and from the one before
#   the append form, so a stale copy beside a current hook also fails closed.

BEGIN {
  SENT = sprintf("%c", 1)

  # Bounded prefix-word enumeration. An unlisted leading word is the command. The value is
  # the word's view: 1 for the fourteen words both outputs read, 2 for a word only the
  # default output reads (the exit view keeps the walk it had before them).
  PREFIX["then"]=1;  PREFIX["do"]=1;      PREFIX["else"]=1;    PREFIX["elif"]=1
  PREFIX["in"]=1;    PREFIX["!"]=1;       PREFIX["sudo"]=1;    PREFIX["time"]=1
  PREFIX["env"]=1;   PREFIX["nohup"]=1;   PREFIX["command"]=1; PREFIX["builtin"]=1
  PREFIX["exec"]=1;  PREFIX["xargs"]=1
  PREFIX["if"]=2;    PREFIX["while"]=2;   PREFIX["until"]=2
  PREFIX["nice"]=2;  PREFIX["stdbuf"]=2;  PREFIX["timeout"]=2
  MAX_PREFIX_SKIP = 10

  # Wrapper rows, in getopt notation, copied from script_wrapper_row() in
  # block-destructive.sh. A field a row does not set reads the default in WDEF.
  #   opt     short options that take an argument: `x:` attached or as the next token,
  #           `x::` only attached; an unlisted letter or a digit is a flag
  #   larg    long options that take their argument as the next token
  #   nox     short options under which the wrapper executes nothing (describe only)
  #   split   short options whose attached argument is the wrapper's own argv (env -S)
  #   lsplit  the long spellings of the same
  #   long    every long option the program's parser defines (prefix resolution)
  #   pos     what follows the option run: one positional, a run of NAME=value, or none
  WDEF["opt"]="";  WDEF["larg"]=" ";  WDEF["nox"]="";  WDEF["split"]=""
  WDEF["lsplit"]=" ";  WDEF["long"]=" ";  WDEF["pos"]="none"
  WROW["nice"]=1
  WOPT["nice"]="n:"
  WLARG["nice"]=" --adjustment "
  WLONG["nice"]=" --adjustment --help --version "
  WROW["stdbuf"]=1
  WOPT["stdbuf"]="e:i:o:"
  WLARG["stdbuf"]=" --error --input --output "
  WLONG["stdbuf"]=" --error --help --input --output --version "
  WROW["sudo"]=1
  WOPT["sudo"]="a:C:c:D:g:h:p:R:r:T:t:U:u:"
  WLARG["sudo"]=" --auth-type --close-from --login-class --chdir --group --host --prompt --chroot --role --command-timeout --type --other-user --user "
  WNOX["sudo"]="elvVK"
  WLONG["sudo"]=" --askpass --auth-type --background --bell --chdir --chroot --close-from --command-timeout --edit --group --help --host --list --login --login-class --no-update --non-interactive --other-user --preserve-env --preserve-groups --prompt --remove-timestamp --reset-timestamp --role --set-home --shell --stdin --type --user --validate --version "
  WROW["env"]=1
  WOPT["env"]="a:C:P:u:"
  WLARG["env"]=" --argv0 --chdir --unset "
  WSPLIT["env"]="S"
  WLSPLIT["env"]=" --split-string "
  WPOS["env"]="assign"
  WLONG["env"]=" --argv0 --block-signal --chdir --debug --default-signal --help --ignore-environment --ignore-signal --list-signal-handling --null --split-string --unset --version "
  WROW["xargs"]=1
  WOPT["xargs"]="a:d:E:e::I:i::J:L:l::n:P:R:S:s:"
  WLARG["xargs"]=" --arg-file --delimiter --max-args --max-procs --max-chars --process-slot-var "
  WLONG["xargs"]=" --arg-file --delimiter --eof --exit --help --interactive --max-args --max-chars --max-lines --max-procs --no-run-if-empty --null --open-tty --process-slot-var --replace --show-limits --verbose --version "
  WROW["time"]=1
  WOPT["time"]="f:o:"
  WLARG["time"]=" --format --output-file "
  WLONG["time"]=" --append --format --help --output-file --portability --quiet --verbose --version "
  WROW["timeout"]=1
  WOPT["timeout"]="k:s:"
  WLARG["timeout"]=" --kill-after --signal "
  WPOS["timeout"]="one"
  WLONG["timeout"]=" --foreground --help --kill-after --preserve-status --signal --verbose --version "
  WROW["exec"]=1
  WOPT["exec"]="a:"
  WROW["builtin"]=1
  WROW["nohup"]=1
  WLONG["nohup"]=" --help --version "
  WROW["command"]=1
  WNOX["command"]="vV"

  EXIT_VIEW = (CMDPOS_VIEW == "exit")
  BOTH_VIEW = (CMDPOS_VIEW == "both")
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

# The next token of [i,hi]: blanks at mask "N" delimit it, so a quoted span is one token.
# Sets TK_S and TK_E to its first and last offsets; returns 0 when none is left.
function cp_token(i, hi) {
  while (i <= hi && is_blank(substr(out, i, 1)) && substr(mask, i, 1) == "N") i++
  if (i > hi) return 0
  TK_S = i
  TK_E = i
  while (TK_E <= hi && !(is_blank(substr(out, TK_E, 1)) && substr(mask, TK_E, 1) == "N")) TK_E++
  TK_E--
  return 1
}

# The word a prefix token names: one leading backslash dropped, then full-token quotes,
# then the basename. `\sudo`, `"sudo"` and `/usr/bin/sudo` all name sudo.
function cp_lookup(tok,   q, n) {
  if (substr(tok, 1, 1) == "\\") tok = substr(tok, 2)
  n = length(tok)
  if (n >= 2) {
    q = substr(tok, 1, 1)
    if ((q == "'" || q == "\"") && substr(tok, n, 1) == q) tok = substr(tok, 2, n - 2)
  }
  if (index(tok, "/") > 0) sub(/.*\//, "", tok)
  return tok
}

# Load one wrapper's row into R_*, each absent field reading its default.
function cp_row(w) {
  R_OPT    = (w in WOPT)    ? WOPT[w]    : WDEF["opt"]
  R_LARG   = (w in WLARG)   ? WLARG[w]   : WDEF["larg"]
  R_NOX    = (w in WNOX)    ? WNOX[w]    : WDEF["nox"]
  R_SPLIT  = (w in WSPLIT)  ? WSPLIT[w]  : WDEF["split"]
  R_LSPLIT = (w in WLSPLIT) ? WLSPLIT[w] : WDEF["lsplit"]
  R_LONG   = (w in WLONG)   ? WLONG[w]   : WDEF["long"]
  R_POS    = (w in WPOS)    ? WPOS[w]    : WDEF["pos"]
}

# A long-option token resolved the way the wrapper's parser resolves it: an exact name
# wins, otherwise a prefix that names exactly one long option names that option; a name
# that is none, or a prefix of two or more, stays as written (the -022 walk's rule).
function cp_longname(tok,   name, k, n, j, cnt, hit, parts) {
  name = substr(tok, 3)
  k = index(name, "=")
  if (k > 0) name = substr(name, 1, k - 1)
  if (index(R_LONG, " --" name " ") > 0) return "--" name
  n = split(R_LONG, parts, " ")
  cnt = 0; hit = ""
  for (j = 1; j <= n; j++) {
    if (parts[j] != "" && index(parts[j], "--" name) == 1) { cnt++; hit = parts[j] }
  }
  if (cnt == 1) return hit
  return "--" name
}

# Consume the next token of the segment, if there is one (an option's separate argument,
# or a positional operand).
function cp_skip_one(hi) {
  if (cp_token(CP_I, hi)) CP_I = TK_E + 1
}

# An attached split-string value is the wrapper's own argv. Returns 1 when the value is
# itself a command word (the command is inside the string: the walk stops on the split
# token), 0 when it is only options, an assignment or empty (the walk goes on to the
# command that follows; an option in it that takes a separate argument takes the next
# token). A value holding a `/` is read as a command word.
function cp_split_scan(v, hi,   c2, nm, p, n) {
  if (v == "") return 0
  if (index(v, "/") > 0) return 1
  if (substr(v, 1, 1) != "-") {
    if (index(v, "=") > 0) {
      nm = substr(v, 1, index(v, "=") - 1)
      if (nm == "" || nm ~ /[^A-Za-z0-9_]/) return 1
      return 0
    }
    return 1
  }
  n = length(v)
  for (p = 2; p <= n; p++) {
    c2 = substr(v, p, 1)
    if (index(R_OPT, c2 "::") > 0) break
    if (index(R_OPT, c2 ":") > 0) { if (p == n) cp_skip_one(hi); break }
  }
  return 0
}

# Step one wrapper's own option run and positional operands. Entered with CP_I just after
# the wrapper word; leaves CP_I on the first position after the wrapper's grammar. Sets
# CP_STOP=1 and CP_STOP_S to a token's first offset when the walk ends ON that token (a
# describe-only option, or an attached split value carrying a command word): that token
# is then the command word, so nothing behind it is promoted.
function cp_wrapper_walk(w, hi,   tok, ts, c, lname, p, n, e) {
  CP_STOP = 0
  cp_row(w)
  while (cp_token(CP_I, hi)) {
    ts = TK_S
    tok = substr(out, TK_S, TK_E - TK_S + 1)
    if (tok == "--") { CP_I = TK_E + 1; break }
    if (substr(tok, 1, 2) == "--" && index(tok, "=") > 0) {
      lname = cp_longname(tok)
      CP_I = TK_E + 1
      if (index(R_LSPLIT, " " lname " ") > 0) {
        if (cp_split_scan(substr(tok, index(tok, "=") + 1), hi)) { CP_STOP = 1; CP_STOP_S = ts; return }
      }
      continue
    }
    if (substr(tok, 1, 2) == "--") {
      lname = cp_longname(tok)
      CP_I = TK_E + 1
      if (index(R_LARG, " " lname " ") > 0) cp_skip_one(hi)
      continue
    }
    if (substr(tok, 1, 1) == "-" && length(tok) > 1) {
      CP_I = TK_E + 1
      n = length(tok)
      for (p = 2; p <= n; p++) {
        c = substr(tok, p, 1)
        if (c == ":") continue
        if (R_NOX != "" && index(R_NOX, c) > 0) { CP_STOP = 1; CP_STOP_S = ts; return }
        e = (p == n)
        if (R_SPLIT != "" && index(R_SPLIT, c) > 0 && !e) {
          if (cp_split_scan(substr(tok, p + 1), hi)) { CP_STOP = 1; CP_STOP_S = ts; return }
          e = 1; p = n
        }
        if (index(R_OPT, c "::") > 0) p = n
        else if (index(R_OPT, c ":") > 0) { if (e) cp_skip_one(hi); p = n }
      }
      continue
    }
    if (tok == "-") { CP_I = TK_E + 1; continue }
    break
  }
  if (R_POS == "one") cp_skip_one(hi)
  else if (R_POS == "assign") {
    while (cp_token(CP_I, hi)) {
      tok = substr(out, TK_S, TK_E - TK_S + 1)
      if (substr(tok, 1, 1) == "-") break
      if (index(tok, "=") == 0) break
      if (TK_S > 1) ins[TK_S] = "; "   # (e) CMDPOS-E
      CP_I = TK_E + 1
    }
  }
}

# Find the command word of [lo,hi] past the prefix run, and record the edits.
function resolve_segment(lo, hi,   i, t_start, t_end, tok, w, skips, xflag) {
  if (lo > hi) return
  if (EXIT_VIEW) { resolve_segment_exit(lo, hi); return }
  i = lo; skips = 0; xflag = 0
  while (skips <= MAX_PREFIX_SKIP) {
    if (!cp_token(i, hi)) return
    t_start = TK_S
    t_end = TK_E
    tok = substr(out, t_start, t_end - t_start + 1)

    # The token AS WRITTEN is tested as an assignment and as a redirection before it is
    # looked up as a prefix word — the order the -022 walk uses. The shell reads either
    # shape as what it is, never as a command, while the lookup's basename would read an
    # assignment whose value is a path, or a redirection whose attached target is one, as
    # the wrapper its last path segment names (`X=/usr/bin/timeout`, `>/tmp/timeout`), and a
    # wrapper that takes a positional would then consume the command word behind it.
    if (tok ~ /^[A-Za-z_][A-Za-z0-9_]*[+]?=/) {                    # VAR=value or VAR+=value  CMDPOS-APPEND
      if (t_start > 1) ins[t_start] = "; "   # (e) CMDPOS-E
      i = t_end + 1; skips++; continue
    }
    if (tok ~ /^[0-9]*(>>|>|<)/) {                                               # redirect
      i = t_end + 1; skips++
      if (tok ~ /(>>|>|<)$/) {                        # operand is a separate token
        while (i <= hi && is_blank(substr(out, i, 1))) i++
        while (i <= hi && !is_blank(substr(out, i, 1))) i++
      }
      continue
    }
    w = cp_lookup(tok)
    if (w in PREFIX) {
      skips++
      if (w in WROW) {
        if (w == "xargs") xflag = 1
        CP_I = t_end + 1
        cp_wrapper_walk(w, hi)
        if (CP_STOP) { t_start = CP_STOP_S; break }
        i = CP_I
      } else {
        i = t_end + 1
      }
      continue
    }
    break
  }
  if (t_start > hi) return
  record_edits(t_start, hi, xflag)
}

# The exit view's walk: the prefix walk as it stood before the wrapper grammar joined it
# — the fourteen words of view 1, matched as exact tokens, each stepped as one token.
# Frozen on purpose: see THE EXIT VIEW above. Its assignment test reads `NAME=value` only.
# The append form is the default walk's alone: an exit that allows on a match must not
# widen, and this test taking that form would turn a refusal at either exit into an allow.
function resolve_segment_exit(lo, hi,   i, t_start, t_end, tok, skips, xflag) {
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

    if ((tok in PREFIX) && PREFIX[tok] == 1) {
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
  record_edits(t_start, hi, xflag)
}

# (b), (a) and (c) for the command-start token at t_start of a segment ending at hi.
function record_edits(t_start, hi, xflag) {
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

# BOTH VIEWS FROM ONE RUN (see the header): one scan, then the exit view's walk over every
# segment, whose view is emitted first; then its edits are moved aside and the default walk
# records its own. The default output is built again only when its edits differ from the exit
# walk's; otherwise it is the same text. The exit view goes out before the default walk runs,
# so a run that fails in the default walk still leaves the exit view whole, as two runs did.
function both(   x, k) {
  if (!scan()) { x = cp_chomp(buf); printf "%s%c%s%c", x, 0, x, 0; return }   # unbalanced quotes
  EXIT_VIEW = 1
  locate()
  x = cp_chomp(emit())
  printf "%s%c", x, 0
  for (k in ins)  xins[k] = ins[k]
  for (k in drop) xdrop[k] = drop[k]
  for (k in tail) xtail[k] = tail[k]
  split("", ins); split("", drop); split("", tail)
  EXIT_VIEW = 0
  locate()
  if (same_edits()) { printf "%s%c", x, 0; return }
  printf "%s%c", cp_chomp(emit()), 0
}

# 1 when the default walk's edits (ins, drop, tail) equal the exit walk's (xins, xdrop, xtail).
function same_edits(   k) {
  for (k in ins)   if (!(k in xins) || xins[k] != ins[k]) return 0
  for (k in xins)  if (!(k in ins)) return 0
  for (k in drop)  if (!(k in xdrop)) return 0
  for (k in xdrop) if (!(k in drop)) return 0
  for (k in tail)  if (!(k in xtail) || xtail[k] != tail[k]) return 0
  for (k in xtail) if (!(k in tail)) return 0
  return 1
}

# The text without its trailing newlines, as a command substitution captures it.
function cp_chomp(s,   j) {
  j = length(s)
  while (j > 0 && substr(s, j, 1) == "\n") j--
  return substr(s, 1, j)
}

END {
  if (BOTH_VIEW) { both(); exit 0 }
  if (!scan()) { printf "%s", buf; exit 0 }   # unbalanced quotes — status quo, unchanged
  locate()
  printf "%s", emit()
}
