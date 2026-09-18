#!/usr/bin/env bash
# start-skill-editor-session.sh — mint (or end) the pmo-skill-editor session sentinel.
#
# WHY THIS EXISTS (#5515).
# `block-skill-direct-edit.sh` (Gate 2, BLOCK-SKILL-EDIT-002) denies a direct edit to a
# migrated skill unless `<skill-dir>/.editor-session` is present and valid, and its own
# deny message instructs the reader to "invoke pmo-skill-editor Mode A to start an editing
# session". No such minter existed. The gate advertised a path nothing could satisfy, so
# the only way through was CLAUDE_HOOK_BYPASS=1 — a global kill switch across 15 hooks.
# That is the defect this tool closes: it makes the sanctioned path real, so the blunt one
# stops being the only one.
#
# WHAT IT IS NOT.
# This is not a bypass and must never become one. It records that a genuine editing session
# started, against ONE named skill, at a known time. Gate 2 still enforces every other
# condition: the skill's migration marker, that the sentinel names THIS skill, that its
# timestamp is not in the future, and that it is younger than the 30-minute TTL. An agent
# calling this to clear a gate for work that is not a real editing session is fabricating a
# sentinel by another route — pmo-skill-editor's own guardrail names that as a bypass, and
# that judgement is unchanged by this tool existing.
#
# The sentinel is runtime state: `.gitignore` already excludes `*/skills/*/.editor-session`
# under all three roots. It is never committed.
#
# Usage:
#   start-skill-editor-session.sh <skill-name>          # mint
#   start-skill-editor-session.sh --end <skill-name>    # end early (TTL also expires it)
#   start-skill-editor-session.sh --self-test
#
# Exit: 0 ok · 1 skill not resolvable · 2 usage · 3 could not write the sentinel

set -euo pipefail

# SELF — this file's own absolute path, resolved ONCE here, before anything in this
# script changes directory.
#
# The self-test re-invokes this file from inside a scratch corpus it `cd`s into. `$0`
# holds whatever was typed on the command line, so a relative `$0` stops resolving the
# moment that `cd` happens: invoked as `./core/deploy/tools/start-skill-editor-session.sh`
# the arms failed with "no such file", while the same file invoked by absolute path
# passed — a verdict that tracked how the tool was addressed rather than how it behaves.
# The negative arms failed more quietly than the positive ones: they PASSED, because the
# mint they require to fail failed for the wrong reason (the interpreter could not find
# this file, not because the skill was unresolvable), and a same-named script sitting at
# the post-`cd` path would have been executed in this one's place.
#
# `BASH_SOURCE[0]` holds the path this file was invoked BY. The two lines below make it
# absolute. What that buys is stated as narrowly as it was measured:
#
#   - It holds for an invocation path that names this file from the invoking directory —
#     absolute, `./`-prefixed, or bare relative — including with a hostile `CDPATH`
#     exported. Self-test arm C1 runs this file as a child in exactly that environment.
#   - It does NOT hold for `bash <bare-name>` resolved through bash's own PATH search for
#     the script: that word carries no slash, `dirname` of a slash-less operand is `.`
#     (observed on this host), so the result is `$PWD/<basename>`, correct only when the
#     file happens to sit in the caller's directory. Measured on the expression, not on
#     the running tool: the PATH manipulation that arm needs is denied by
#     BLOCK-DESTRUCTIVE-020, and that denial was not routed around.
#
# Two properties of the shape below, and what each rests on:
#
#   - `CDPATH=''` on the `cd`. A bare relative dirname (`core/deploy/tools`) is a CDPATH
#     search operand, so with an entry that resolves it, POSIX has `cd` print the directory
#     it picked — and that directory need not be the invoking one. The print lands inside
#     the capture, and `SELF` becomes a two-line value that is not a path. Reproduced at
#     `CDPATH=.:~:/usr` (bash(1)'s own sample value): the bare-relative form returned
#     FAIL/1 there while `./` and absolute returned PASS/0 — the addressing dependence
#     this file exists to remove, returning by another door. Arm C1 is the regression
#     guard: it goes red when this `CDPATH=''` is removed, and red again when the `cd`'s
#     print is merely silenced rather than disabled.
#   - The split into two assignments. Under `set -e` an assignment's status is that of its
#     LAST command substitution, so concatenating `/$(basename …)` onto the same line
#     discards a failing `cd` and freezes `SELF` at `/start-skill-editor-session.sh`.
#     Measured on the two expressions here (the combined form survives `set -e` at rc 0;
#     the split form aborts at rc 1), and it is the shape the in-repo precedent
#     `core/deploy/tools/check-issue-ref-validity.sh` already uses. NO ARM COVERS THIS
#     ONE: arm C1 stays green if the two lines are recombined, because CDPATH-safety and
#     `set -e` coverage are different properties.
#
# `$0` is still correct in the usage strings at the bottom — those echo back what the
# caller typed, which is what a usage line shows.
SELF_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SELF="${SELF_DIR}/$(basename -- "${BASH_SOURCE[0]}")"
readonly SELF_DIR SELF

# Arm C1's child marker (see self_test). It is honoured ONLY when the variable names a
# file that exists and carries this exact line, so a marker leaked into a real run — an
# exported variable, a stale environment — is ignored and that run still executes C1.
# Recursion is bounded at one level either way, because the child the arm spawns always
# carries a marker it can verify.
readonly C1_CHILD_TOKEN='start-skill-editor-session.sh --self-test: arm C1 child'

readonly TTL_SECONDS=1800  # MUST match SENTINEL_TTL_SECONDS in block-skill-direct-edit.sh
readonly ROOTS="core operations release"

repo_root() { git rev-parse --show-toplevel 2>/dev/null || pwd; }

# resolve_skill_dir <skill> — echo the skill directory, or empty if it does not resolve.
# Searched across all three module roots; the first hit wins. A skill that exists in two
# roots is a corpus defect this tool does not paper over — it reports the ambiguity.
resolve_skill_dir() {
  local skill="$1" root base hits="" dir=""
  base="$(repo_root)"
  for root in $ROOTS; do
    if [ -f "${base}/${root}/skills/${skill}/SKILL.md" ]; then
      hits="${hits}${root} "
      dir="${base}/${root}/skills/${skill}"
    fi
  done
  case "$(printf '%s' "$hits" | wc -w | tr -d ' ')" in
    0) return 1 ;;
    1) printf '%s' "$dir" ;;
    *) printf 'AMBIGUOUS:%s' "$hits"; return 1 ;;
  esac
}

mint() {
  local skill="$1" dir sentinel now sid
  if ! dir="$(resolve_skill_dir "$skill")"; then
    if [ "${dir#AMBIGUOUS:}" != "$dir" ]; then
      echo "ERROR: '${skill}' resolves under more than one module root (${dir#AMBIGUOUS:}) — corpus defect, not a session problem" >&2
    else
      echo "ERROR: no skill named '${skill}' with a SKILL.md under core/, operations/ or release/" >&2
    fi
    return 1
  fi

  sentinel="${dir}/.editor-session"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  sid="$(printf '%s-%s' "$(date -u +%Y%m%dT%H%M%SZ)" "$$")"

  # Written with jq when available so the JSON is well-formed by construction; the printf
  # fallback keeps this usable on a host without jq, since Gate 2 rejects malformed JSON
  # and a hand-built string is the likeliest way to produce some.
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg s "$skill" --arg id "$sid" --arg t "$now" \
      '{target_skill:$s, session_id:$id, started_at:$t, mode:"A"}' > "$sentinel" || return 3
  else
    printf '{"target_skill":"%s","session_id":"%s","started_at":"%s","mode":"A"}\n' \
      "$skill" "$sid" "$now" > "$sentinel" || return 3
  fi

  [ -s "$sentinel" ] || { echo "ERROR: sentinel written but empty: $sentinel" >&2; return 3; }

  echo "editor session STARTED for '${skill}'"
  echo "  sentinel : \$(skill-dir)/.editor-session"
  echo "  started  : ${now}"
  echo "  expires  : ${TTL_SECONDS}s from start (Gate 2 enforces the TTL, not this tool)"
  echo "  scope    : this skill only — a sentinel naming another skill does not clear the gate"
}

end_session() {
  local skill="$1" dir
  if ! dir="$(resolve_skill_dir "$skill")"; then
    echo "ERROR: no skill named '${skill}'" >&2; return 1
  fi
  if [ -f "${dir}/.editor-session" ]; then
    rm -f "${dir}/.editor-session"
    echo "editor session ENDED for '${skill}'"
  else
    echo "no active editor session for '${skill}' (nothing to end)"
  fi
}

# --- self-test: exercises the round trip AND the negative arms, on a scratch corpus ------
self_test() {
  local tmp rc=0 fails=0 child=0
  # Am I the child arm C1 spawned? Only a marker that proves it came from a C1 arm counts;
  # anything else is treated as absent, so an unverifiable marker cannot skip C1.
  if [ -n "${SSE_SELFTEST_C1_CHILD:-}" ] && [ -f "${SSE_SELFTEST_C1_CHILD}" ] &&
     [ "$(cat "${SSE_SELFTEST_C1_CHILD}")" = "$C1_CHILD_TOKEN" ]; then
    child=1
  fi

  # A0 — SELF names THIS file. Every arm below re-invokes "$SELF" from inside a directory
  # it has `cd`'d into, so all of them go dark in the same way when the resolution above
  # returns something that is not this file: they fail with "no such file", which reads as
  # a broken fixture rather than as a broken resolution. This arm names the cause instead.
  # It runs before any `cd`, so `${BASH_SOURCE[0]}` still resolves from the invoking
  # directory and `-ef` compares the two by inode.
  if [ ! "$SELF" -ef "${BASH_SOURCE[0]}" ]; then
    printf 'FAIL A0: SELF does not name this file: [%s]\n' "$SELF"; fails=$((fails+1))
  fi

  tmp="$(mktemp -d)"
  # Double-quoted so $tmp expands NOW, at trap-set time. With single quotes the
  # expansion is deferred to trap-fire time, by which point this function has
  # returned and its `local tmp` is out of scope — which under `set -u` aborts the
  # script with "tmp: unbound variable" instead of cleaning up.
  trap "rm -rf '${tmp}'" EXIT
  mkdir -p "${tmp}/operations/skills/fixture-skill"
  printf -- '---\nname: fixture-skill\n---\n' > "${tmp}/operations/skills/fixture-skill/SKILL.md"
  ( cd "$tmp" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm i ) >/dev/null 2>&1

  # A1 — mint creates a sentinel that parses and names the right skill
  ( cd "$tmp" && bash "$SELF" fixture-skill ) >/dev/null 2>&1 || rc=$?
  if [ ! -f "${tmp}/operations/skills/fixture-skill/.editor-session" ]; then
    echo "FAIL A1: sentinel not created"; fails=$((fails+1))
  elif command -v jq >/dev/null 2>&1 && ! jq -e . "${tmp}/operations/skills/fixture-skill/.editor-session" >/dev/null 2>&1; then
    echo "FAIL A1: sentinel is not valid JSON"; fails=$((fails+1))
  elif command -v jq >/dev/null 2>&1 && [ "$(jq -r .target_skill "${tmp}/operations/skills/fixture-skill/.editor-session")" != "fixture-skill" ]; then
    echo "FAIL A1: target_skill does not name the minted skill"; fails=$((fails+1))
  fi

  # A2 — started_at is present and parseable as the hook expects
  if command -v jq >/dev/null 2>&1; then
    if [ -z "$(jq -r '.started_at // empty' "${tmp}/operations/skills/fixture-skill/.editor-session")" ]; then
      echo "FAIL A2: started_at absent — Gate 2 denies on this"; fails=$((fails+1))
    fi
  fi

  # A3 — end removes it
  ( cd "$tmp" && bash "$SELF" --end fixture-skill ) >/dev/null 2>&1 || true
  if [ -f "${tmp}/operations/skills/fixture-skill/.editor-session" ]; then
    echo "FAIL A3: --end did not remove the sentinel"; fails=$((fails+1))
  fi

  # B1 — NEGATIVE: an unresolvable skill must fail, not silently mint somewhere
  if ( cd "$tmp" && bash "$SELF" no-such-skill ) >/dev/null 2>&1; then
    echo "FAIL B1: minted a session for a skill that does not exist"; fails=$((fails+1))
  fi

  # B2 — NEGATIVE: no stray sentinel anywhere after the failed mint (control for B1)
  if [ -n "$(find "$tmp" -name '.editor-session' 2>/dev/null)" ]; then
    echo "FAIL B2: a sentinel exists after a failed mint"; fails=$((fails+1))
  fi

  # C1 — the SELF resolution stays independent of how this file was addressed AND of
  # CDPATH. The arms above cannot see either property: the discovery runner, and every
  # other automated caller, invoke this file by ABSOLUTE path, which is the one form in
  # which both the original `$0` defect and the CDPATH defect are invisible. So this arm
  # builds the environment that exposes them and runs this same file in it as a child:
  #
  #   - addressed by a BARE RELATIVE path (`tools/<this file>`), from this file's
  #     grandparent directory;
  #   - with a `CDPATH` exported whose FIRST entry resolves that bare `tools` — to a
  #     decoy directory holding a same-named no-op. A resolution that consults CDPATH
  #     therefore either captures `cd`'s echo of the directory (a two-line, non-path
  #     SELF) or silently points at the decoy. The decoy records that it ran, so
  #     silencing the echo — `cd … >/dev/null`, the obvious way to "fix" the two-line
  #     value — is caught too, rather than reading green.
  #
  # The child runs the same arms and must pass. Its own C1 is skipped via the verified
  # marker, so the recursion is one level deep.
  if [ "$child" -eq 0 ]; then
    local c1_sub c1_dir c1_rel c1_decoy c1_token c1_ran c1_out c1_rc=0
    c1_sub="$(basename "$(dirname "$SELF")")"
    c1_dir="$(dirname "$(dirname "$SELF")")"
    c1_rel="${c1_sub}/$(basename "$SELF")"
    c1_decoy="${tmp}/cdpath-decoy"
    c1_token="${tmp}/c1-child-token"
    c1_ran="${tmp}/cdpath-decoy-ran"
    mkdir -p "${c1_decoy}/${c1_sub}"
    cat > "${c1_decoy}/${c1_rel}" <<EOF
#!/usr/bin/env bash
# Decoy: stands where a CDPATH entry would land \`cd ${c1_sub}\`. It must never run.
printf 'ran\n' >> "${c1_ran}"
exit 0
EOF
    printf '%s\n' "$C1_CHILD_TOKEN" > "$c1_token"
    if [ ! -f "${c1_dir}/${c1_rel}" ]; then
      echo "FAIL C1: cannot address this file as '${c1_rel}' from '${c1_dir}'"; fails=$((fails+1))
    else
      c1_out="$( cd "$c1_dir" && SSE_SELFTEST_C1_CHILD="$c1_token" CDPATH="${c1_decoy}:." \
                 bash "$c1_rel" --self-test 2>&1 )" || c1_rc=$?
      if [ "$c1_rc" -ne 0 ]; then
        echo "FAIL C1: relative invocation under an exported CDPATH exited ${c1_rc}, want 0"
        echo "  C1 child output follows:"
        printf '%s\n' "$c1_out"
        fails=$((fails+1))
      fi
      if [ -f "$c1_ran" ]; then
        echo "FAIL C1: a CDPATH entry decided where SELF points — the decoy ran"; fails=$((fails+1))
      fi
    fi
  fi

  if [ "$fails" -eq 0 ]; then
    # No arm count here: the count that used to be printed was not measured, and it was
    # wrong on a host without jq, where A2 does not run at all.
    if [ "$child" -eq 1 ]; then
      echo "self-test: PASS — 0 failures (arm C1 child; C1 itself not run here)"
    else
      echo "self-test: PASS — 0 failures"
    fi
    return 0
  fi
  echo "self-test: FAIL — ${fails} failure(s)"
  return 1
}

case "${1:-}" in
  --self-test) self_test ;;
  --end) [ $# -eq 2 ] || { echo "usage: $0 --end <skill-name>" >&2; exit 2; }; end_session "$2" ;;
  ""|-h|--help) echo "usage: $0 <skill-name> | --end <skill-name> | --self-test" >&2; exit 2 ;;
  -*) echo "unknown flag: $1" >&2; exit 2 ;;
  *) [ $# -eq 1 ] || { echo "usage: $0 <skill-name>" >&2; exit 2; }; mint "$1" ;;
esac
