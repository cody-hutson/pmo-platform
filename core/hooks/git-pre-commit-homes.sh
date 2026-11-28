#!/bin/bash -p
# git-pre-commit-homes.sh — the commit guard over the registered in-repo git-ignored homes.
#
# WHAT IT GUARDS. The instance-data placement standard registers in-repo git-ignored homes
# at the repository root (§ Registered in-repo git-ignored homes). Each tracks its own
# README.md and nothing else. An ignore rule does not stop `git add -f`, and on a
# case-insensitive filesystem the README negation also un-ignores `readme.md`, so this
# guard refuses any tracked path under a home other than that home's README.md.
#
# THE ONE LIST. The homes are a static set in this file, never read from an editable
# surface. --check-parity holds it equal to the Home column of the standard's table (the
# In-repo home content gate runs it on every pull request; tests/git-pre-commit-homes.test.sh
# runs it against mutated copies), and --print-homes is how any other check reads it.
#
# THE PREDICATE. A path is under a home when its first segment, folded to lower case, names
# a home. The one admitted path under a home is `<home>/README.md`, spelled exactly; a root
# entry named like a home is refused. It reads paths only, never a file's contents.
#
# INPUTS.  (none) the index git is about to commit, every path in it (GIT_INDEX_FILE is
#          honoured, so a partial commit is judged on the index it records) · --commits
#          commit and tag ids on stdin: every path each commit adds or changes against each
#          parent; a tag is skipped (the commit it names is in the list); any other object,
#          or an id that does not resolve, is refused · --tree <rev> every path in <rev>'s
#          tree · --redact report the home and the commit, never the rest of the path ·
#          --print-homes · --check-parity <standard.md> · --self-test
# EXIT.    0 clean / AGREE / every arm passed · 1 a home path is tracked / DISAGREE / an arm
#          failed · 2 a usage error, or the instrument cannot assert · 3 NOT-EVALUATED: git
#          could not read the index, the tree or the commits, or an id is not a commit or tag.
# POSTURE. Fails closed. It reads no mode dial: git-pre-commit-pii.mode never reaches it.
#          CLAUDE_HOOK_BYPASS is read by its callers, never here, and they treat its two
#          inputs differently (decision record ADR-242,
#          commit-time-home-guard-runs-under-hook-bypass). git-pre-commit-pii.sh runs the
#          STAGED read before its own bypass exit, so the commit-time check runs whether or
#          not the bypass is set: an exception to the uniform bypass convention, and the only
#          check in either PII git hook the bypass does not skip. The push-time read
#          (--commits) sits after that exit, and git-pre-push-pii.sh exits on the bypass
#          before it runs the PII guard at all, so the push-time check honours the bypass. A
#          person's last resort at commit time is git commit --no-verify, which
#          BLOCK-DESTRUCTIVE-024 refuses to agents.
# LAYERS.  The local hook layers (this guard at pre-commit and at pre-push) are the only
#          layer before publication. The In-repo home content gate reads a pull request's
#          merge tree, so it keeps home content off main, but it runs after the branch is
#          already on the remote and does not stop a branch being published.
# Run by:  git-pre-commit-pii.sh (staged at pre-commit; --commits when git-pre-push-pii.sh
#          runs it) and the In-repo home content gate in .github/workflows/repo-integrity.yml.
# Debt.    Two parity arms now read the one registered-homes table (this guard's and the
#          main-checkout carve-out hook's), and the three PII suites copy this file into
#          their geometries beside the PII guard.
# Environment inputs: as in git-pre-commit-pii.sh — bash -p; POSIXLY_CORRECT, CDPATH and
#          GREP_OPTIONS neutralised; LC_ALL=C. PATH is not covered.
set +o posix
unset POSIXLY_CORRECT CDPATH GREP_OPTIONS
export LC_ALL=C
set -uo pipefail

readonly PMO_HOMES="local-state analysis roadmaps"   # table order; --check-parity holds it to the standard

# The predicate. One path per input line; in --commits mode (C=1) a bare commit id line
# names the commit the following paths belong to. R=1 redacts each finding to its home.
# POSIX awk only, and `exit` appears only in END.
readonly HOMES_AWK='
BEGIN { n = split(H, h, " "); for (i = 1; i <= n; i++) home[h[i]] = 1 }
{
  if (C == 1 && $0 ~ /^[0-9a-f]+$/ && (length($0) == 40 || length($0) == 64)) { id = substr($0, 1, 12); next }
  p = $0; if (p == "") next
  rows++
  s = index(p, "/"); top = (s > 0) ? substr(p, 1, s - 1) : p; lt = tolower(top)
  if (!(lt in home)) next
  if (s > 0 && top == lt && p == top "/README.md") { ok++; next }
  bad++
  if (bad <= 25) print "   " (R == 1 ? lt "/..." : p) (id != "" ? "  (commit " id ")" : "")
}
END { print "in-repo homes: examined " rows + 0 " path row(s); README admitted " ok + 0 "; refused " bad + 0; exit (bad > 0 ? 1 : 0) }'

hg_usage() { echo "[git-pre-commit-homes] $1" >&2; exit 2; }

hg_mode="staged"; hg_redact=0; hg_rev=""; hg_std=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --commits) hg_mode="commits" ;;
    --tree)
      [[ $# -ge 2 && -n "$2" ]] || hg_usage "--tree needs a revision"
      hg_mode="tree"; hg_rev="$2"; shift ;;
    --redact) hg_redact=1 ;;
    --print-homes) hg_mode="print-homes" ;;
    --check-parity)
      [[ $# -ge 2 && -n "$2" ]] || hg_usage "--check-parity needs the standard's path"
      hg_mode="parity"; hg_std="$2"; shift ;;
    --self-test) hg_mode="self-test" ;;
    *) hg_usage "unknown argument: $1" ;;
  esac
  shift
done
if [[ "$hg_redact" == "1" && "$hg_mode" != "commits" && "$hg_mode" != "tree" ]]; then
  hg_usage "--redact combines with --commits or --tree only"
fi

# --- --print-homes: how any other check reads the set ------------------------
if [[ "$hg_mode" == "print-homes" ]]; then
  # shellcheck disable=SC2086  # unquoted on purpose: the words are fixed
  printf '%s\n' $PMO_HOMES
  exit 0
fi

# --- --check-parity: the static set against the standard's Home column -------
if [[ "$hg_mode" == "parity" ]]; then
  if [[ ! -r "$hg_std" ]]; then
    echo "TABLE-MISSING: [git-pre-commit-homes] the standard is not readable: $hg_std" >&2
    exit 2
  fi
  awk -v G="$PMO_HOMES" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function srt(a, n,   i, j, t) { for (i = 2; i <= n; i++) { t = a[i]; j = i - 1; while (j > 0 && a[j] > t) { a[j + 1] = a[j]; j-- } a[j + 1] = t } }
    function join(a, n,   i, s) { s = ""; for (i = 1; i <= n; i++) s = s (i > 1 ? "," : "") a[i]; return s }
    BEGIN { state = 0; hdr = 0; nt = 0; verdict = "" }
    verdict != "" { next }
    state == 0 { if (index($0, "### Registered in-repo git-ignored homes") == 1) state = 1; next }
    state == 1 && /^#/ { state = 2; next }
    state == 1 && /^\|/ {
      if ($0 ~ /^\|[ \t:|-]+$/) next
      n = split($0, c, "|")
      cell = trim(c[2])
      if (!hdr) { hdr = 1; if (cell != "Home") verdict = "COLUMN-MISSING: the first column of the table is \"" cell "\", not Home"; next }
      if (cell !~ /^`\/[A-Za-z0-9._-]+\/`$/) { verdict = "UNREAD:" cell; next }
      gsub(/[`\/]/, "", cell); t[++nt] = cell
      next
    }
    END {
      if (verdict == "" && state == 0) verdict = "TABLE-MISSING: no \"### Registered in-repo git-ignored homes\" heading"
      if (verdict == "" && nt == 0) verdict = "TABLE-EMPTY: the registered-homes table holds no row"
      if (verdict != "") { print verdict; exit 2 }
      ng = split(G, g, " ")
      srt(t, nt); srt(g, ng)
      ts = join(t, nt); gs = join(g, ng)
      if (ts == gs) { print "AGREE homes=" ts; exit 0 }
      print "DISAGREE table=" ts " guard=" gs; exit 1
    }' "$hg_std"
  exit $?
fi

# --- --self-test: the predicate, each input mode and the parity check --------
if [[ "$hg_mode" == "self-test" ]]; then
  hg_self="${BASH_SOURCE[0]:-$0}"
  hg_tmp="$(mktemp -d 2>/dev/null || true)"
  if [[ -z "$hg_tmp" || ! -d "$hg_tmp" ]]; then
    echo "self-test: could not create a scratch directory (cannot assert)" >&2; exit 2
  fi
  trap 'rm -rf "$hg_tmp"' EXIT
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR
  st="$hg_tmp/st"
  stg() { GIT_CONFIG_NOSYSTEM=1 HOME="$hg_tmp" git -C "$st" -c user.name=selftest \
            -c user.email=selftest@example.invalid -c commit.gpgsign=false "$@"; }
  # sti <index-file> <git args...> : the same, against a fixture index.
  sti() { local f="$1"; shift; GIT_INDEX_FILE="$f" GIT_CONFIG_NOSYSTEM=1 HOME="$hg_tmp" git -C "$st" \
            -c user.name=selftest -c user.email=selftest@example.invalid -c commit.gpgsign=false "$@"; }
  mkdir -p "$st" && stg init -q 2>/dev/null || { echo "self-test: could not build a scratch repository (cannot assert)" >&2; exit 2; }
  blob="$(printf 'fixture\n' | stg hash-object -w --stdin 2>/dev/null)"
  [[ -n "$blob" ]] || { echo "self-test: could not write a fixture blob (cannot assert)" >&2; exit 2; }
  # mkidx <name> <path>... : a fixture index holding exactly the given paths.
  mkidx() {
    local f="$hg_tmp/idx-$1" p; shift
    sti "$f" read-tree --empty || return 1
    for p in "$@"; do sti "$f" update-index --add --cacheinfo "100644,${blob},${p}" || return 1; done
    printf '%s\n' "$f"
  }
  # mkcommit <parent-or-empty> <path>... : a commit whose tree holds exactly the paths.
  mkcommit() {
    local par="$1" f t; shift
    f="$(mkidx "c$RANDOM$RANDOM" "$@")" || return 1
    t="$(sti "$f" write-tree)" || return 1
    if [[ -n "$par" ]]; then stg commit-tree "$t" -p "$par" -m fixture; else stg commit-tree "$t" -m fixture; fi
  }
  st_pass=0; st_total=0
  arm() { # arm <id> <desc> <want-exit> <got-exit> [<output> <must-contain> [<must-not-contain>]]
    local ok=1
    st_total=$((st_total + 1))
    [[ "$4" == "$3" ]] || ok=0
    if [[ "$ok" == 1 && -n "${6:-}" ]]; then case "$5" in *"$6"*) ;; *) ok=0 ;; esac; fi
    if [[ "$ok" == 1 && -n "${7:-}" ]]; then case "$5" in *"$7"*) ok=0 ;; esac; fi
    if [[ "$ok" == 1 ]]; then st_pass=$((st_pass + 1)); echo "PASS: $1 $2"; else echo "FAIL: $1 $2 (exit $4, want $3)"; fi
  }
  # run_idx <index> <args...> : the guard in staged mode on a fixture index; sets o, rc.
  run_idx() {
    local f="$1"; shift
    if [[ ! -s "$f" ]]; then o="fixture index is empty"; rc=99; return; fi
    o="$(cd "$st" && GIT_INDEX_FILE="$f" GIT_CONFIG_NOSYSTEM=1 HOME="$hg_tmp" /bin/bash -p "$hg_self" "$@" 2>&1)"; rc=$?
  }
  run_in() { o="$(cd "$st" && GIT_CONFIG_NOSYSTEM=1 HOME="$hg_tmp" /bin/bash -p "$hg_self" "$@" 2>&1)"; rc=$?; }
  run_ids() { # run_ids <stdin-text> <args...>
    local in="$1"; shift
    o="$(cd "$st" && printf '%s\n' "$in" | GIT_CONFIG_NOSYSTEM=1 HOME="$hg_tmp" /bin/bash -p "$hg_self" "$@" 2>&1)"; rc=$?
  }

  run_idx "$(mkidx c1 local-state/x.md)";             arm T8022-C1 "a file under /local-state/ is refused" 1 "$rc" "$o" "local-state/x.md"
  run_idx "$(mkidx c2 analysis/a/b.md)";              arm T8022-C2 "a file under /analysis/ is refused" 1 "$rc" "$o" "analysis/a/b.md"
  run_idx "$(mkidx c3 roadmaps/r.md)";                arm T8022-C3 "a file under /roadmaps/ is refused" 1 "$rc" "$o" "roadmaps/r.md"
  run_idx "$(mkidx c4 local-state/readme.md)";        arm T8022-C4 "a README in another case is refused" 1 "$rc" "$o" "local-state/readme.md"
  run_idx "$(mkidx c5 local-state/sub/README.md)";    arm T8022-C5 "a README below the home's top is refused" 1 "$rc" "$o" "local-state/sub/README.md"
  run_idx "$(mkidx c6 Local-State/x)";                arm T8022-C6 "a home named in another case is refused" 1 "$rc" "$o" "Local-State/x"
  run_idx "$(mkidx c7 roadmaps)";                     arm T8022-C7 "a root file named like a home is refused" 1 "$rc" "$o" "   roadmaps"
  # C8: the staged read passes the exact READMEs and the near-miss names, and the same
  # set read as a tree reports the three READMEs admitted.
  run_idx "$(mkidx c8 local-state/README.md analysis/README.md roadmaps/README.md docs/local-state-notes.md local-statements/x analysisx/y)"
  c8_rc="$rc"; c8_t="$(sti "$hg_tmp/idx-c8" write-tree)"
  run_in --tree "$c8_t";                              arm T8022-C8 "the exact READMEs and similarly named paths pass" 00 "${c8_rc}${rc}" "$o" "README admitted 3"
  c_bad="$(mkcommit "" analysis/x)"; c_ok="$(mkcommit "" roadmaps/README.md)"
  run_in --tree "$c_bad";                             arm T8022-C9 "--tree of a commit holding analysis/x is refused" 1 "$rc" "$o" "analysis/x"
  run_in --tree "$c_ok";                              arm T8022-C10 "--tree of a README-only commit passes" 0 "$rc" "$o" "README admitted 1"
  c_add="$(mkcommit "$c_ok" roadmaps/README.md roadmaps/x)"
  run_ids "$(printf '%s\n%s' "$c_ok" "$c_add")" --commits
  arm T8022-C11 "--commits refuses the commit that adds roadmaps/x, naming it" 1 "$rc" "$o" "(commit ${c_add:0:12})"
  run_ids "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" --commits
  arm T8022-C12 "--commits refuses an id that does not resolve as NOT-EVALUATED" 3 "$rc"
  run_ids "$(printf '%s\n%s' "$c_ok" "$c_add")" --commits --redact
  arm T8022-C13 "--redact names the home and the commit, never the rest of the path" 1 "$rc" "$o" "roadmaps/...  (commit ${c_add:0:12})" "roadmaps/x"
  tbl="$hg_tmp/std.md"
  {
    printf '# Fixture\n\n### Registered in-repo git-ignored homes\n\n'
    printf '| Home | Admits |\n|---|---|\n'
    printf '| `/local-state/` | state |\n| `/analysis/` | analysis |\n| `/roadmaps/` | roadmaps |\n'
    printf '\nProse after the table.\n\n## Next section\n'
  } > "$tbl"
  run_in --check-parity "$tbl";                       arm T8022-C14 "--check-parity agrees with a table of the three homes" 0 "$rc" "$o" "AGREE"
  grep -v '`/roadmaps/`' "$tbl" > "$tbl.drop"
  run_in --check-parity "$tbl.drop";                  arm T8022-C15 "--check-parity disagrees when a home's row is removed" 1 "$rc" "$o" "DISAGREE"
  awk '/`\/local-state\/`/ { held = "| `/local-state/` | edited |"; next } { print } /`\/roadmaps\/`/ { print held }' "$tbl" > "$tbl.reorder"
  run_in --check-parity "$tbl.reorder";               arm T8022-C16 "--check-parity is order-blind and reads the Home column only" 0 "$rc" "$o" "AGREE"
  sed 's/### Registered in-repo git-ignored homes/### Registered homes/' "$tbl" > "$tbl.head"
  run_in --check-parity "$tbl.head";                  arm T8022-C17 "--check-parity cannot assert when the heading is renamed" 2 "$rc" "$o" "TABLE-MISSING"
  echo "self-test: ${st_pass}/${st_total} arms passed"
  [[ "$st_pass" -eq 17 && "$st_total" -eq 17 ]] && exit 0
  exit 1
fi

# --- Collect the paths for the input mode ------------------------------------
hg_tmp="$(mktemp -d 2>/dev/null || true)"
if [[ -z "$hg_tmp" || ! -d "$hg_tmp" ]]; then
  echo "BLOCKED: [git-pre-commit-homes] could not create a scratch directory; nothing was scanned, so this is refused." >&2
  exit 3
fi
trap 'rm -rf "$hg_tmp"' EXIT
hg_not_evaluated() {
  echo "BLOCKED: [git-pre-commit-homes] $1; nothing was scanned, so this is refused (NOT-EVALUATED)." >&2
  exit 3
}

hg_c=0
case "$hg_mode" in
  staged)
    # --full-name with the top-of-tree pathspec reads every path in the index, named from
    # the top, from whichever directory the guard runs in.
    git ls-files -z --cached --full-name -- ':/' > "$hg_tmp/paths" 2>/dev/null || hg_not_evaluated "git could not read the index"
    ;;
  commits)
    hg_c=1
    cat > "$hg_tmp/ids" || hg_not_evaluated "could not read the commit ids on stdin"
    [[ -s "$hg_tmp/ids" ]] || exit 0
    git cat-file --batch-check < "$hg_tmp/ids" > "$hg_tmp/kinds" 2>/dev/null \
      || hg_not_evaluated "git could not look up the objects to scan"
    : > "$hg_tmp/commits"; : > "$hg_tmp/other"
    awk -v C="$hg_tmp/commits" -v B="$hg_tmp/other" '
      $2 == "commit" { print $1 >> C; next }
      $2 == "tag"    { next }
      NF > 0         { print >> B }' "$hg_tmp/kinds" || hg_not_evaluated "could not classify the objects"
    if [[ -s "$hg_tmp/other" ]]; then
      hg_not_evaluated "an id is not a commit or annotated tag: $(sed -n 1p "$hg_tmp/other" | tr -d '\001-\037\177')"
    fi
    [[ -s "$hg_tmp/commits" ]] || exit 0
    git diff-tree --stdin -r -m --root --no-renames --diff-filter=d --name-only -z \
      < "$hg_tmp/commits" > "$hg_tmp/paths" 2>/dev/null || hg_not_evaluated "git could not list the paths the commits change"
    ;;
  tree)
    git rev-parse -q --verify "${hg_rev}^{tree}" >/dev/null 2>&1 || hg_not_evaluated "the revision ${hg_rev} does not name a tree"
    git ls-tree -r -z --name-only --full-tree "$hg_rev" > "$hg_tmp/paths" 2>/dev/null \
      || hg_not_evaluated "git could not read the tree of ${hg_rev}"
    ;;
esac

# --- Scan ----------------------------------------------------------------------
# A filename that holds a newline is split here; a fragment whose first segment names a
# home is then refused. That over-refusal is accepted.
tr '\000' '\n' < "$hg_tmp/paths" | awk -v H="$PMO_HOMES" -v C="$hg_c" -v R="$hg_redact" "$HOMES_AWK" > "$hg_tmp/out"
hg_rc=$?
hg_summary="$(sed -n '$p' "$hg_tmp/out")"
if [[ "$hg_rc" -eq 0 ]]; then
  [[ "$hg_mode" == "staged" ]] || printf '%s\n' "$hg_summary"
  exit 0
fi
if [[ "$hg_rc" -ne 1 ]]; then
  hg_not_evaluated "the scan exited ${hg_rc}"
fi
{
  echo "──────────────────────────────────────────────────────────────"
  echo "BLOCKED: [git-pre-commit-homes] tracked path(s) under a registered in-repo git-ignored home;"
  echo "nothing there is ever committed, and each home tracks its README.md alone:"
  sed '$d' "$hg_tmp/out" | LC_ALL=C tr -d '\001-\010\013-\037\177'
  printf '%s\n' "$hg_summary"
  echo ""
  case "$hg_mode" in
    staged)
      echo "Unstage each one: git rm --cached -- <path> (the file stays on disk, still git-ignored)." ;;
    commits)
      echo "A pushed commit stays readable after a later commit removes the path, so drop or rewrite"
      echo "each commit named above before pushing (nothing has been published yet). If these commits"
      echo "are already on the remote, run: git fetch <remote>." ;;
    tree)
      echo "Remove each path from the pull request with git rm --cached -- <path>, commit and push."
      echo "The commit that added it stays in this branch's history, so squash-merge this pull request"
      echo "(or drop that commit before merging): a merge commit would carry it onto main." ;;
  esac
  echo "──────────────────────────────────────────────────────────────"
} >&2
exit 1
