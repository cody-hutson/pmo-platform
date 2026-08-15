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
  local tmp rc=0 fails=0
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  mkdir -p "${tmp}/operations/skills/fixture-skill"
  printf -- '---\nname: fixture-skill\n---\n' > "${tmp}/operations/skills/fixture-skill/SKILL.md"
  ( cd "$tmp" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm i ) >/dev/null 2>&1

  # A1 — mint creates a sentinel that parses and names the right skill
  ( cd "$tmp" && bash "$0" fixture-skill ) >/dev/null 2>&1 || rc=$?
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
  ( cd "$tmp" && bash "$0" --end fixture-skill ) >/dev/null 2>&1 || true
  if [ -f "${tmp}/operations/skills/fixture-skill/.editor-session" ]; then
    echo "FAIL A3: --end did not remove the sentinel"; fails=$((fails+1))
  fi

  # B1 — NEGATIVE: an unresolvable skill must fail, not silently mint somewhere
  if ( cd "$tmp" && bash "$0" no-such-skill ) >/dev/null 2>&1; then
    echo "FAIL B1: minted a session for a skill that does not exist"; fails=$((fails+1))
  fi

  # B2 — NEGATIVE: no stray sentinel anywhere after the failed mint (control for B1)
  if [ -n "$(find "$tmp" -name '.editor-session' 2>/dev/null)" ]; then
    echo "FAIL B2: a sentinel exists after a failed mint"; fails=$((fails+1))
  fi

  if [ "$fails" -eq 0 ]; then
    echo "self-test: PASS — 3 positive arms, 2 negative arms, 0 failures"
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
