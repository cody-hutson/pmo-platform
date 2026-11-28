#!/usr/bin/env bash
# test_tree_walk_skips_homes.sh — the repository's root tree walkers skip the in-repo homes
#
# WHAT IT PROVES. A walker that enumerates the repository tree must never read the
# contents of a registered in-repo git-ignored home (release-run state, analysis
# output, roadmap instances), and must not descend into the linked worktrees under
# .claude/worktrees/ either. This suite runs four walkers on two fixtures built from
# the same git index and requires the same finding lines from both:
#   W1  release/tools/verify-release-plan.sh  — the scope family's glob resolver
#   W2  core/skills/context-budget-auditor/scripts/measure-context-budget.sh — agents row
#   W3  release/tools/domain-blast-radius.sh  — the software import tracer's scan list
#   W4  release/tools/blast-radius.sh         — the doc tracer (the tracked-first reference)
# The durability suite's repository copy (test_upgrade_config_durability.sh) is a fifth
# changed walker; it is not run here (a full non-dry-run upgrade per arm), and is
# graded by its own suite and by the census below.
#
# HOW THE FIXTURE IS BUILT. FX_CLEAN is the source checkout's git index (tracked
# paths, working-tree content) copied into a sandbox, plus four tracked near-miss
# files per home whose names resemble a home without being inside one, plus a scope
# plan for W1; it is committed as its own repository. FX_PLANT is a copy of FX_CLEAN
# with untracked files planted: PLANT_N bulk files and three shaped probe files in
# every registered home, the same probe files in a decoy linked worktree, and one
# non-git copy nested under a home (the empty-index case). A home therefore
# contributes only its tracked README to FX_CLEAN, exactly as on a fresh clone.
# Nothing under the source checkout is written, and no home of the source checkout
# is read: the fixture is built from the index, never from a directory walk.
#
# THE HOME NAMES come from the one home list — the static set inside the commit-time
# home guard, read through its --print-homes flag. This file names no home itself:
# every plant path, near-miss path and plan row is derived from that list.
#
# ARMS.
#   C  the walker is deterministic and non-empty on FX_CLEAN (a silent walker is no pass)
#   S  FX_PLANT findings equal FX_CLEAN findings (the walker does not read a home)
#   M  a mutant that walks the filesystem instead DOES report a difference — the
#      sensitivity half, so S cannot pass while observing nothing
#   N  a tracked near-miss path is still walked (an exclusion that is too broad fails)
#   E  the import tracer, rooted at a non-git copy nested in a work tree (its index
#      lists nothing), still scans that copy; its mutant without the fallback does not
#   A  both tracers, run with no --root from a non-git parent of the fixture, resolve
#      their root from their own checkout and report the clean findings
#   K  a static census of bare repository-root walks over the source checkout's
#      tracked code, with its own sensitivity and specificity inputs
#   R13 the source checkout's git status is unchanged by the run
#
# THE CENSUS (K). A line is a hit when it walks a bare root variable — one of the
# names in the V group below, optionally with a trailing "/" or "/." — in one of
# these shapes, each probed below in at least two spellings:
#   K1 find (with -L/-H/-P allowed, and a "/" after the closing quote)   K2 du
#   K3 a recursive copy (cp -R/-r/-a, rsync, ditto)   K4 a recursive grep
#   K5 cd to the root and walk "."   K6 an array seeded with the root
#   K7 tar -C <root> ... .   K8 python os.walk / rglob / recursive glob / copytree
#      / Path(<root>).rglob over the root names in the PV group
# A hit is exempt only when the same line carries the marker comment
#   tree-walk: allow — <reason>
# and a marker on a line no shape matches is reported stale.
# BOUNDARY, stated, not claimed closed: a root reached through any other variable
# name, through $1 or a function argument, through a command substitution or a
# computed path, through a callee, or through a cd on an earlier line is not matched,
# and neither is a spelling outside the shapes above (grep --recursive, glob.glob of
# a joined path). The Stage-5 walker inventory, not this census, covers those; the
# census is a forward canary for the common spellings.
#
# Run from the repository root:  bash core/deploy/tests/test_tree_walk_skips_homes.sh
# Member contract (run-install-regression.sh): prints
#   test_tree_walk_skips_homes: <P> passed, <F> failed
# and exits non-zero when F > 0.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd -P)"
SELF_REL="core/deploy/tests/test_tree_walk_skips_homes.sh"
HOME_LIST_REL="core/hooks/git-pre-commit-homes.sh"   # the one home list, read only through --print-homes
TARGET="core/deploy/tools/_frontmatter.py"         # a tracked module with tracked importers and path referrers
PLANT_N=1000                                       # planted bulk files per registered home

PASS=0
FAIL=0

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"
    if [ -n "${detail}" ]; then printf '%s\n' "${detail}" | sed 's/^/         /'; fi
    FAIL=$((FAIL + 1))
  fi
}

finish() {
  printf 'test_tree_walk_skips_homes: %d passed, %d failed\n' "${PASS}" "${FAIL}"
  if [ "${FAIL}" -gt 0 ]; then exit 1; fi
  exit 0
}

printf 'test_tree_walk_skips_homes: the root tree walkers skip the in-repo homes\n'

# --- prerequisites (fail closed: a walker that cannot run is not a pass) -------------
missing=""
for tool in jq python3 git tar; do
  if ! command -v "${tool}" >/dev/null 2>&1; then missing="${missing} ${tool}"; fi
done
if [ -n "${missing}" ]; then
  report "T8023-P0 prerequisites" 0 "absent:${missing} — a walker that cannot run is not a pass"
  finish
fi
report "T8023-P0 prerequisites (jq, python3, git, tar)" 1

# --- sandbox and environment --------------------------------------------------------
SBX="$(mktemp -d -t tree-walk-homes.XXXXXX)" || { report "T8023-P0 sandbox" 0 "mktemp failed"; finish; }
SBX="$(cd "${SBX}" && pwd -P)"
cleanup() {
  chmod -R u+rwx "${SBX}" 2>/dev/null
  rm -rf "${SBX}"
}
trap cleanup EXIT
mkdir -p "${SBX}/home" "${SBX}/census"
export HOME="${SBX}/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
fx_git() {
  git -c user.name='tree-walk fixture' -c user.email=fixture@example.invalid \
      -c commit.gpgsign=false -c init.defaultBranch=main "$@"
}
STATUS_BEFORE="$(git -C "${REPO_ROOT}" status --porcelain 2>&1)"

# --- the home list (the only source of a home's name in this file) ------------------
homes_list() {
  local out line res=""
  out="$(bash "${REPO_ROOT}/${HOME_LIST_REL}" --print-homes 2>/dev/null)" || return 1
  [ -n "${out}" ] || return 1
  while IFS= read -r line; do
    [ -n "${line}" ] || continue
    case "${line}" in
      [!a-z0-9]*|*[!a-z0-9._-]*) return 1 ;;
    esac
    res="${res}${line}/
"
  done <<EOF_HOMES
${out}
EOF_HOMES
  [ -n "${res}" ] || return 1
  printf '%s' "${res}"
}

HOMES="$(homes_list)" || HOMES=""
HOME_COUNT=0
if [ -n "${HOMES}" ]; then HOME_COUNT="$(printf '%s' "${HOMES}" | grep -c .)"; fi
if [ "${HOME_COUNT}" -ge 1 ]; then
  report "T8023-F2 the home list reads through --print-homes (homes=${HOME_COUNT})" 1
else
  report "T8023-F2 the home list reads through --print-homes" 0 \
    "home list unreadable at ${HOME_LIST_REL} — the arms below would plant nothing"
  finish
fi
FIRST_HOME="$(printf '%s' "${HOMES}" | sed -n 1p)"

# --- fixture: the git index, never a directory walk ---------------------------------
FX_CLEAN="${SBX}/clean"
FX_PLANT="${SBX}/plant"
mkdir -p "${FX_CLEAN}"
( cd "${REPO_ROOT}" && git ls-files -z \
    | while IFS= read -r -d '' f; do if [ -f "${f}" ]; then printf '%s\0' "${f}"; fi; done \
    | tar --null -T - -cf - ) | ( cd "${FX_CLEAN}" && tar -xf - )
SRC_N="$( cd "${REPO_ROOT}" && git ls-files -z | python3 -c '
import os, sys
print(sum(1 for n in sys.stdin.buffer.read().split(b"\0") if n and os.path.isfile(n)))
' )"

B='`'
Q="'"
mkdir -p "${FX_CLEAN}/core/skills/tree-walk-fixture/agents" "${FX_CLEAN}/plan"
sed -n '1,/^|---|/p' "${FX_CLEAN}/release/tools/tests/fixtures/verify-plan-scope.md" > "${FX_CLEAN}/plan/p.md"
plan_row() {  # plan_row <n> <pathspec> <note>
  printf '| AC-%d | %sgit diff --name-only origin/main...HEAD -- %s%s%s%s expect 0 | %s |\n' \
    "$1" "${B}" "${Q}" "$2" "${Q}" "${B}" "$3" >> "${FX_CLEAN}/plan/p.md"
}
plan_row 1 '*.home-probe' 'a glob only planted files match'
plan_row 2 '*/agents/*.md' 'control: tracked files match'
NEAR_ROWS=""
row=3
while IFS= read -r h; do
  [ -n "${h}" ] || continue
  n="${h%/}"
  mkdir -p "${FX_CLEAN}/docs/${n}"
  printf 'near-miss: a tracked path that resembles a home\n' > "${FX_CLEAN}/docs/${n}-notes.md"
  printf 'near-miss: a tracked path that resembles a home\n' > "${FX_CLEAN}/docs/${n}/notes.md"
  printf 'near-miss agent file\n' > "${FX_CLEAN}/core/skills/tree-walk-fixture/agents/${n}-notes.md"
  printf 'import _frontmatter  # %s\n' "${TARGET}" > "${FX_CLEAN}/docs/${n}-notes.py"
  plan_row "${row}" "docs/${n}-*" 'near-miss: a tracked file beside the home'
  NEAR_ROWS="${NEAR_ROWS} AC-${row}"; row=$((row + 1))
  plan_row "${row}" "*/${n}/*" 'near-miss: a tracked directory of the same name'
  NEAR_ROWS="${NEAR_ROWS} AC-${row}"; row=$((row + 1))
done <<EOF_NEAR
${HOMES}
EOF_NEAR
printf 'M\trelease/tools/verify-release-plan.sh\n' > "${SBX}/seam.tsv"

fx_git -C "${FX_CLEAN}" init -q
FX_OK=1
if [ ! -d "${FX_CLEAN}/.git" ]; then FX_OK=0; fi
fx_git -C "${FX_CLEAN}" add -A -f . >/dev/null 2>&1 || FX_OK=0
fx_git -C "${FX_CLEAN}" commit -q -m 'fixture: the git index under test' >/dev/null 2>&1 || FX_OK=0
FX_N="$(fx_git -C "${FX_CLEAN}" ls-files | grep -c .)"
WANT_N=$((SRC_N + 4 * HOME_COUNT + 1))
home_only_readme=1
home_detail=""
while IFS= read -r h; do
  [ -n "${h}" ] || continue
  listed="$(fx_git -C "${FX_CLEAN}" ls-files -- "${h}")"
  case "${listed}" in
    ''|"${h}README.md") : ;;
    *) home_only_readme=0; home_detail="${home_detail} ${h}: ${listed}" ;;
  esac
done <<EOF_F1
${HOMES}
EOF_F1
if [ "${FX_OK}" = 1 ] && [ "${FX_N}" = "${WANT_N}" ] && [ "${home_only_readme}" = 1 ]; then
  report "T8023-F1 the fixture is the source index plus its near-miss files (tracked=${FX_N})" 1
else
  report "T8023-F1 the fixture is the source index plus its near-miss files" 0 \
    "built=${FX_OK} tracked=${FX_N} want=${WANT_N} (index ${SRC_N} + 4 x ${HOME_COUNT} homes + 1 plan)${home_detail}"
  finish
fi

# --- mutants: sandbox copies beside the originals, never an edit in place -----------
# make_mutant <tool-rel> <mutant-rel> <anchor> <replacement> — the anchor must occur
# exactly once; prints the count it found.
make_mutant() {
  python3 - "${FX_CLEAN}/$1" "${FX_CLEAN}/$2" "$3" "$4" <<'PY'
import os, sys
src, dst, anchor, repl = sys.argv[1:5]
text = open(src, encoding="utf-8").read()
k = text.count(anchor)
print(k)
if k == 1:
    open(dst, "w", encoding="utf-8").write(text.replace(anchor, repl))
    os.chmod(dst, 0o755)
PY
}
ANCHOR_INDEX='if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree'
MUT1_K="$(make_mutant release/tools/verify-release-plan.sh release/tools/verify-release-plan.mutant.sh \
  "${ANCHOR_INDEX}" "if false && ${ANCHOR_INDEX#if }")"
MUT2_K="$(make_mutant core/skills/context-budget-auditor/scripts/measure-context-budget.sh \
  core/skills/context-budget-auditor/scripts/measure-context-budget.mutant.sh \
  "find \"\$repo_root/core\" \"\$repo_root/release\" \"\$repo_root/operations\" -path '*/skills/*/agents/*.md'" \
  "find \"\$repo_root\" -path '*/skills/*/agents/*.md'")"
MUT3_K="$(make_mutant release/tools/domain-blast-radius.sh release/tools/domain-blast-radius.mutant.sh \
  "${ANCHOR_INDEX}" "if false && ${ANCHOR_INDEX#if }")"
MUT4_K="$(make_mutant release/tools/blast-radius.sh release/tools/blast-radius.mutant.sh \
  'if try_git_tracked_candidates "$candidates"; then' 'if false; then')"
MUTE_K="$(make_mutant release/tools/domain-blast-radius.sh release/tools/domain-blast-radius.nofallback.sh \
  '&& [ -s "$raw" ]; then' '; then')"

# --- plant: untracked files in every home, a decoy worktree, a nested non-git copy --
cp -R "${FX_CLEAN}" "${FX_PLANT}"
plant_probes() {  # plant_probes <dir>
  mkdir -p "$1/skills/s/agents"
  printf 'planted probe\n' > "$1/x.home-probe"
  printf 'planted agent file\n' > "$1/skills/s/agents/a.md"
  printf 'import _frontmatter  # %s\n' "${TARGET}" > "$1/importer.py"
}
while IFS= read -r h; do
  [ -n "${h}" ] || continue
  python3 - "${FX_PLANT}/${h}" "${PLANT_N}" <<'PY'
import os, sys
root, n = sys.argv[1], int(sys.argv[2])
for i in range(n):
    d = os.path.join(root, "release-runs", "run-%04d" % i)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "state.md"), "w") as f:
        f.write("planted run state %d\n" % i)
PY
  plant_probes "${FX_PLANT}/${h}probe"
done <<EOF_PLANT
${HOMES}
EOF_PLANT
plant_probes "${FX_PLANT}/.claude/worktrees/wt-decoy/probe"
NEST="${FX_PLANT}/${FIRST_HOME}nested-copy"
mkdir -p "${NEST}/core/deploy/tools" "${NEST}/docs"
cp "${FX_CLEAN}/${TARGET}" "${NEST}/${TARGET}"
printf 'import _frontmatter  # %s\n' "${TARGET}" > "${NEST}/docs/nested-importer.py"

plant_short=""
while IFS= read -r h; do
  [ -n "${h}" ] || continue
  c="$(python3 - "${FX_PLANT}/${h}" <<'PY'
import os, sys
root = sys.argv[1]
n = 0
for d, _, fs in os.walk(root):
    for f in fs:
        if os.path.join(d, f) != os.path.join(root, "README.md"):
            n += 1
print(n)
PY
)"
  if [ "${c}" -lt $((PLANT_N + 3)) ]; then plant_short="${plant_short} ${h}=${c}"; fi
done <<EOF_F3
${HOMES}
EOF_F3
if [ -z "${plant_short}" ]; then
  report "T8023-F3 every home in the planted fixture holds at least $((PLANT_N + 3)) untracked files" 1
else
  report "T8023-F3 every home in the planted fixture holds at least $((PLANT_N + 3)) untracked files" 0 "short:${plant_short}"
fi

# --- walkers: each prints normalised finding lines; fixture paths are root-relative --
norm_checks() {
  python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for c in d.get("checks", []):
    if str(c.get("id", "")).startswith("AC-"):
        print("%s\t%s\t%s\t%s" % (c.get("id"), c.get("family"), c.get("verdict"), c.get("observed", "")))
'
}
norm_tracer() {  # norm_tracer <kind>
  python3 -c '
import json, sys
kind = sys.argv[1]
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print("scanned\t%s" % d.get("stats", {}).get("total_files_scanned"))
for p in sorted(x.get("path") for x in d.get("first_order", [])):
    print("%s\t%s" % (kind, p))
' "$1"
}
walk() {  # walk <W1..W4> <fixture> <tool file name>
  case "$1" in
    W1) bash "$2/release/tools/$3" --format=json --root "$2" --fcm-diff-file "${SBX}/seam.tsv" "$2/plan/p.md" 2>/dev/null | norm_checks ;;
    W2) bash "$2/core/skills/context-budget-auditor/scripts/$3" 2>/dev/null | sed '/^- Survey:/d' ;;
    W3) ( cd "$2" && bash "$2/release/tools/$3" --domain=software --format=json --depth=1 --root="$2" "${TARGET}" 2>/dev/null ) | norm_tracer importer ;;
    W4) ( cd "$2" && bash "$2/release/tools/$3" --format=json --depth=1 --root="$2" "${TARGET}" 2>/dev/null ) | norm_tracer referrer ;;
  esac
}
differing() {  # differing <a> <b> — the lines in one and not the other
  python3 - "$1" "$2" <<'PY'
import sys
a, b = set(sys.argv[1].splitlines()), set(sys.argv[2].splitlines())
for l in sorted(a - b)[:12]:
    print("clean only:   " + l)
for l in sorted(b - a)[:12]:
    print("planted only: " + l)
PY
}

# arm_set <C-id> <S-id> <M-id> <walker> <tool> <mutant> <mutant-anchor-count> <label>
arm_set() {
  local cid="$1" sid="$2" mid="$3" w="$4" tool="$5" mut="$6" mk="$7" label="$8"
  local c1 c2 pl mc mp
  c1="$(walk "${w}" "${FX_CLEAN}" "${tool}")"
  c2="$(walk "${w}" "${FX_CLEAN}" "${tool}")"
  pl="$(walk "${w}" "${FX_PLANT}" "${tool}")"
  if [ -n "${c1}" ] && [ "${c1}" = "${c2}" ]; then
    report "${cid} ${label}: two runs on the clean fixture agree and are non-empty" 1
  else
    report "${cid} ${label}: two runs on the clean fixture agree and are non-empty" 0 \
      "a walker that prints nothing, or differently twice, is a broken walker, not a clean one"
  fi
  if [ -n "${c1}" ] && [ "${c1}" = "${pl}" ]; then
    report "${sid} ${label}: the planted fixture reports the clean findings" 1
  else
    report "${sid} ${label}: the planted fixture reports the clean findings" 0 "$(differing "${c1}" "${pl}")"
  fi
  if [ "${mk}" != "1" ]; then
    report "${mid} ${label}: a mutant that walks the filesystem reports a difference" 0 \
      "broken mutation: anchor found ${mk:-0} times"
  else
    mc="$(walk "${w}" "${FX_CLEAN}" "${mut}")"
    mp="$(walk "${w}" "${FX_PLANT}" "${mut}")"
    if [ -n "${mp}" ] && [ "${mc}" != "${mp}" ]; then
      report "${mid} ${label}: a mutant that walks the filesystem reports a difference" 1
    else
      report "${mid} ${label}: a mutant that walks the filesystem reports a difference" 0 \
        "BROKEN PROBE — a walker that reads the homes reported no difference"
    fi
  fi
  ARM_CLEAN="${c1}"
  ARM_PLANT="${pl}"
}

printf '\n[W1] the plan verifier, scope family\n'
arm_set "T8023-C1" "T8023-S1" "T8023-M1" W1 verify-release-plan.sh verify-release-plan.mutant.sh "${MUT1_K}" "W1 verifier"
W1_CLEAN="${ARM_CLEAN}"; W1_PLANT="${ARM_PLANT}"
printf '\n[W2] the context-budget agents scan\n'
arm_set "T8023-C2" "T8023-S2" "T8023-M2" W2 measure-context-budget.sh measure-context-budget.mutant.sh "${MUT2_K}" "W2 budget scan"
W2_CLEAN="${ARM_CLEAN}"; W2_PLANT="${ARM_PLANT}"
printf '\n[W3] the software import tracer\n'
arm_set "T8023-C3" "T8023-S3" "T8023-M3" W3 domain-blast-radius.sh domain-blast-radius.mutant.sh "${MUT3_K}" "W3 import tracer"
W3_CLEAN="${ARM_CLEAN}"; W3_PLANT="${ARM_PLANT}"
printf '\n[W4] the doc tracer\n'
arm_set "T8023-C4" "T8023-S4" "T8023-M4" W4 blast-radius.sh blast-radius.mutant.sh "${MUT4_K}" "W4 doc tracer"
W4_CLEAN="${ARM_CLEAN}"; W4_PLANT="${ARM_PLANT}"

# --- near-miss arms: a similarly named tracked path is still walked -----------------
printf '\n[N] near-miss paths outside the homes\n'
n1_bad=""
for out in "${W1_CLEAN}" "${W1_PLANT}"; do
  for id in ${NEAR_ROWS}; do
    line="$(printf '%s\n' "${out}" | awk -F'\t' -v id="${id}" '$1 == id')"
    case "${line}" in
      *scope-pathspec-selects-nothing*) n1_bad="${n1_bad} ${id}:selects-nothing" ;;
      "${id}	scope	PASS	"*) : ;;
      *) n1_bad="${n1_bad} ${id}:${line:-absent}" ;;
    esac
  done
done
if [ -z "${n1_bad}" ]; then
  report "T8023-N1 W1: every near-miss pathspec selects a tracked path and grades PASS (clean and planted)" 1
else
  report "T8023-N1 W1: every near-miss pathspec selects a tracked path and grades PASS (clean and planted)" 0 "${n1_bad}"
fi

agents_want="$(fx_git -C "${FX_CLEAN}" ls-files -- '*/skills/*/agents/*.md' | grep -c .)"
n2_bad=""
for pair in "clean:${W2_CLEAN}" "planted:${W2_PLANT}"; do
  which="${pair%%:*}"; out="${pair#*:}"
  got="$(printf '%s\n' "${out}" | awk -F'|' '$2 ~ /^ agents $/ { gsub(/ /, "", $3); print $3 }')"
  if [ "${got}" != "${agents_want}" ]; then n2_bad="${n2_bad} ${which}=${got:-absent}"; fi
done
if [ -z "${n2_bad}" ]; then
  report "T8023-N2 W2: the agents row counts exactly the tracked agent files, near-miss included (${agents_want})" 1
else
  report "T8023-N2 W2: the agents row counts exactly the tracked agent files, near-miss included" 0 \
    "want ${agents_want} (git ls-files on the fixture); got${n2_bad}"
fi

n3_bad=""; n4_bad=""
while IFS= read -r h; do
  [ -n "${h}" ] || continue
  n="${h%/}"
  for out in "${W3_CLEAN}" "${W3_PLANT}"; do
    if [ "$(printf '%s\n' "${out}" | grep -c -x -F "importer	docs/${n}-notes.py")" != 1 ]; then n3_bad="${n3_bad} docs/${n}-notes.py"; fi
  done
  for out in "${W4_CLEAN}" "${W4_PLANT}"; do
    if [ "$(printf '%s\n' "${out}" | grep -c -x -F "referrer	docs/${n}-notes.py")" != 1 ]; then n4_bad="${n4_bad} docs/${n}-notes.py"; fi
  done
done <<EOF_N
${HOMES}
EOF_N
if [ -z "${n3_bad}" ]; then
  report "T8023-N3 W3: each near-miss importer is found (clean and planted)" 1
else
  report "T8023-N3 W3: each near-miss importer is found (clean and planted)" 0 "missing:${n3_bad}"
fi
if [ -z "${n4_bad}" ]; then
  report "T8023-N4 W4: each near-miss path referrer is found (clean and planted)" 1
else
  report "T8023-N4 W4: each near-miss path referrer is found (clean and planted)" 0 "missing:${n4_bad}"
fi

# --- E: the import tracer never reports an empty index as a clean zero --------------
printf '\n[E] a non-git copy nested inside a work tree (the index lists nothing there)\n'
nest_out="$( cd "${NEST}" && bash "${FX_CLEAN}/release/tools/domain-blast-radius.sh" --domain=software --format=json --depth=1 --root="${NEST}" "${TARGET}" 2>/dev/null | norm_tracer importer )"
nest_scanned="$(printf '%s\n' "${nest_out}" | awk -F'\t' '$1 == "scanned" { print $2 }')"
if [ -n "${nest_scanned}" ] && [ "${nest_scanned}" != "0" ] && [ "${nest_scanned}" != "None" ] \
   && [ "$(printf '%s\n' "${nest_out}" | grep -c -x -F "importer	docs/nested-importer.py")" = 1 ]; then
  report "T8023-E3 W3 rooted at the nested copy scans it (scanned=${nest_scanned}) and finds its importer" 1
else
  report "T8023-E3 W3 rooted at the nested copy scans it and finds its importer" 0 \
    "observed: $(printf '%s' "${nest_out}" | tr '\n' ' ') — an empty population read as a clean blast radius"
fi
if [ "${MUTE_K}" != "1" ]; then
  report "T8023-E3M the tracer without its empty-index fallback is caught by T8023-E3" 0 \
    "broken mutation: anchor found ${MUTE_K:-0} times"
else
  nest_mut="$( cd "${NEST}" && bash "${FX_CLEAN}/release/tools/domain-blast-radius.nofallback.sh" --domain=software --format=json --depth=1 --root="${NEST}" "${TARGET}" 2>/dev/null | norm_tracer importer )"
  if [ "${nest_mut}" != "${nest_out}" ]; then
    report "T8023-E3M the tracer without its empty-index fallback is caught by T8023-E3" 1
  else
    report "T8023-E3M the tracer without its empty-index fallback is caught by T8023-E3" 0 \
      "BROKEN PROBE — removing the fallback changed nothing the arm reads"
  fi
fi

# --- A: no --root, run from a non-git parent of the fixture --------------------------
printf '\n[A] both tracers from a non-git parent directory, no --root\n'
if git -C "${SBX}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  report "T8023-A3 W3 from a non-git parent" 0 "precondition: the sandbox ${SBX} sits inside a work tree, so this arm cannot reach the fallback"
  report "T8023-A4 W4 from a non-git parent" 0 "precondition: the sandbox ${SBX} sits inside a work tree, so this arm cannot reach the fallback"
else
  a3="$( cd "${SBX}" && bash "${FX_PLANT}/release/tools/domain-blast-radius.sh" --domain=software --format=json --depth=1 "${FX_PLANT}/${TARGET}" 2>/dev/null | norm_tracer importer )"
  if [ -n "${W3_CLEAN}" ] && [ "${a3}" = "${W3_CLEAN}" ]; then
    report "T8023-A3 W3 from a non-git parent resolves its own checkout and reports the clean findings" 1
  else
    report "T8023-A3 W3 from a non-git parent resolves its own checkout and reports the clean findings" 0 "$(differing "${W3_CLEAN}" "${a3}")"
  fi
  a4="$( cd "${SBX}" && bash "${FX_PLANT}/release/tools/blast-radius.sh" --format=json --depth=1 "${FX_PLANT}/${TARGET}" 2>/dev/null | norm_tracer referrer )"
  if [ -n "${W4_CLEAN}" ] && [ "${a4}" = "${W4_CLEAN}" ]; then
    report "T8023-A4 W4 from a non-git parent resolves its own checkout and reports the clean findings" 1
  else
    report "T8023-A4 W4 from a non-git parent resolves its own checkout and reports the clean findings" 0 "$(differing "${W4_CLEAN}" "${a4}")"
  fi
fi

# --- K: the root-walk census ----------------------------------------------------------
printf '\n[K] the root-walk census\n'
census() {  # census --tracked <root> <self-rel> <list.z> | census --files <file>...
  python3 - "$@" <<'PY'
import os, re, sys
V  = r'(?:REPO_ROOT|repo_root|ROOT|WORKSPACE_ROOT|CLAUDE_WORKSPACE_ROOT|PRIMARY_ROOT|MAIN_WORKTREE|SOURCE_REPO|SRC_ROOT)'
R  = r'"?\$\{?' + V + r'\}?(?:/\.?)?"?'          # a bare root operand, optionally "/" or "/."
E  = r'(?=\s|$|\)|;|\|)'
SH = [("K1-find",    r'(?:^|[\s;&|(`])(?:/usr/bin/)?find\s+(?:-[LHP]\s+)*' + R + r'/?' + E),
      ("K2-du",      r'(?:^|[\s;&|(`])du\s+(?:-\w+\s+)*' + R + E),
      ("K3-copy",    r'(?:^|[\s;&|(`])(?:cp\s+-\w*[RrAa]\w*|rsync\s+-\w+|ditto)\s+' + R + E),
      ("K4-rgrep",   r'(?:^|[\s;&|(`])(?:/usr/bin/)?e?grep\s+(?:[^|;&]*\s)?-[a-zA-Z]*[rR][a-zA-Z]*\s[^|;&]*' + R + E),
      ("K5-cd-walk", r'\bcd\s+' + R + r'\s*&&\s*(?:/usr/bin/)?(?:find|du|grep\s+-\w*[rR])\s+\.(?=\s|$)'),
      ("K6-array",   r'\b\w+=\(\s*' + R + r'(?=\s|\))'),
      ("K7-tar",     r'\btar\s+[^|;&]*-C\s+' + R + r'\s+(?:[^|;&]*\s)?\.(?=\s|$|\))')]
PV = r'(?:REPO_ROOT|repo_root|ROOT|WORKSPACE_ROOT)'
PY = [("K8-pywalk",  r'os\.walk\(\s*(?:str\()?' + PV + r'\)?\s*[,)]'
                     r'|\b' + PV + r'\.rglob\('
                     r'|\b' + PV + r'\.glob\(\s*[rf]?["\']\*\*'
                     r'|\bcopytree\(\s*(?:str\()?' + PV + r'\)?\s*[,)]'
                     r'|\bPath\(\s*' + PV + r'\s*\)\.(?:rglob\(|glob\(\s*[rf]?["\']\*\*)')]
SHC = [(n, re.compile(p)) for n, p in SH]
PYC = [(n, re.compile(p)) for n, p in PY]
MARK = re.compile('#\\s*tree-walk:\\s*allow\\s+—\\s+\\S')
args = sys.argv[1:]
if args[0] == "--tracked":
    root, self_rel, listing = args[1], args[2], args[3]
    pop = []
    for raw in open(listing, "rb").read().split(b"\0"):
        if not raw:
            continue
        rel = raw.decode("utf-8", "replace")
        if rel == self_rel:
            continue
        path = os.path.join(root, rel)
        if not os.path.isfile(path):
            continue
        ext = os.path.splitext(rel)[1]
        keep = ext in (".sh", ".bash", ".py", ".ps1")
        keep = keep or (rel.startswith(".github/workflows/") and ext in (".yml", ".yaml"))
        if not keep and ext == "":
            with open(path, "rb") as fh:
                keep = fh.read(2) == b"#!"
        if keep:
            pop.append((rel, path))
else:
    pop = [(p, p) for p in args[1:]]
for rel, path in pop:
    pats = PYC if rel.endswith(".py") else SHC
    with open(path, encoding="utf-8", errors="replace") as fh:
        for i, line in enumerate(fh, 1):
            marked = MARK.search(line) is not None
            if line.lstrip().startswith("#"):
                if marked:
                    print("STALE-MARKER\t%s:%d" % (rel, i))
                continue
            shape = None
            for n, c in pats:
                if c.search(line):
                    shape = n
                    break
            if shape:
                print("HIT\t%s:%d\t%s\t%s" % (rel, i, shape, "marked" if marked else "unmarked"))
            elif marked:
                print("STALE-MARKER\t%s:%d" % (rel, i))
PY
}

git -C "${REPO_ROOT}" ls-files -z > "${SBX}/census/tracked.z"
K_OUT="$(census --tracked "${REPO_ROOT}" "${SELF_REL}" "${SBX}/census/tracked.z")"
K_UNMARKED="$(printf '%s\n' "${K_OUT}" | awk -F'\t' '$1 == "HIT" && $4 == "unmarked"')"
K_MARKED_N="$(printf '%s\n' "${K_OUT}" | awk -F'\t' '$1 == "HIT" && $4 == "marked"' | grep -c .)"
K_STALE="$(printf '%s\n' "${K_OUT}" | awk -F'\t' '$1 == "STALE-MARKER"')"
if [ -z "${K_UNMARKED}" ]; then
  report "T8023-K1 no unmarked bare repository-root walk in the tracked code" 1
else
  report "T8023-K1 no unmarked bare repository-root walk in the tracked code" 0 "${K_UNMARKED}"
fi
if [ -z "${K_STALE}" ]; then
  report "T8023-K2 no stale tree-walk marker (marked walks: ${K_MARKED_N})" 1
else
  report "T8023-K2 no stale tree-walk marker" 0 "${K_STALE}"
fi

# Sensitivity: two spellings (or more) per shape, each line tagged with the shape it
# must report. The expected count is derived from this list, never typed.
cat > "${SBX}/census/synth.sh" <<'EOF_SYNTH'
find "$REPO_ROOT" -name x
find -L "$REPO_ROOT"/ -type f
du -sk "$REPO_ROOT"
du -sh "${REPO_ROOT}"
cp -R "${REPO_ROOT}" "$d"
cp -r "$REPO_ROOT" "$d"
grep -rn needle "$REPO_ROOT"
grep -Rl needle "${REPO_ROOT}"
( cd "$REPO_ROOT" && find . -name x )
cd "${REPO_ROOT}" && /usr/bin/find . -type f
local walk_args=( "$REPO_ROOT" -type f )
roots=( "${REPO_ROOT}" )
tar -C "$REPO_ROOT" -cf - .
tar -cf - -C "$REPO_ROOT" .
EOF_SYNTH
cat > "${SBX}/census/synth.py" <<'EOF_SYNTHPY'
for d, _, fs in os.walk(REPO_ROOT):
shutil.copytree(REPO_ROOT, dst)
for p in Path(REPO_ROOT).rglob("*"):
for p in REPO_ROOT.rglob("*.md"):
EOF_SYNTHPY
cat > "${SBX}/census/expect.tsv" <<'EOF_EXPECT'
synth.sh:1	K1-find
synth.sh:2	K1-find
synth.sh:3	K2-du
synth.sh:4	K2-du
synth.sh:5	K3-copy
synth.sh:6	K3-copy
synth.sh:7	K4-rgrep
synth.sh:8	K4-rgrep
synth.sh:9	K5-cd-walk
synth.sh:10	K5-cd-walk
synth.sh:11	K6-array
synth.sh:12	K6-array
synth.sh:13	K7-tar
synth.sh:14	K7-tar
synth.py:1	K8-pywalk
synth.py:2	K8-pywalk
synth.py:3	K8-pywalk
synth.py:4	K8-pywalk
EOF_EXPECT
K3_WANT="$(sort "${SBX}/census/expect.tsv")"
K3_GOT="$(census --files "${SBX}/census/synth.sh" "${SBX}/census/synth.py" \
  | awk -F'\t' '$1 == "HIT" && $4 == "unmarked" { n = split($2, p, "/"); print p[n] "\t" $3 }' | sort)"
K3_N="$(printf '%s\n' "${K3_WANT}" | grep -c .)"
if [ "${K3_GOT}" = "${K3_WANT}" ]; then
  report "T8023-K3 census sensitivity: each of ${K3_N} synthetic walks reports its own shape, unmarked" 1
else
  report "T8023-K3 census sensitivity: each of ${K3_N} synthetic walks reports its own shape, unmarked" 0 \
    "$(differing "${K3_WANT}" "${K3_GOT}")"
fi

# Specificity: a subtree twin of each spelling, a non-recursive twin, a comment, and
# one marked line.
cat > "${SBX}/census/nearmiss.sh" <<'EOF_NEARMISS'
find "$REPO_ROOT/core" -name x
find -L "$REPO_ROOT/core"/ -type f
du -sk "$REPO_ROOT/core"
cp -R "${REPO_ROOT}/core" "$d"
cp -r "$REPO_ROOT/core" "$d"
cp -f "$REPO_ROOT" "$d"
grep -rn needle "$REPO_ROOT/core"
grep -n needle "$REPO_ROOT"
( cd "$REPO_ROOT" && find ./core -name x )
cd "${REPO_ROOT}/core" && find . -type f
cmd=( "$REPO_ROOT/x.sh" )
roots=( "${REPO_ROOT}/core" )
tar -C "$REPO_ROOT" -cf - core
tar -cf - -C "$REPO_ROOT/core" .
tool --root "$REPO_ROOT" x
# find "$REPO_ROOT" -name x
find "$REPO_ROOT" -name x  # tree-walk: allow — synthetic marked line
EOF_NEARMISS
cat > "${SBX}/census/nearmiss.py" <<'EOF_NEARMISSPY'
os.walk(os.path.join(REPO_ROOT, "core"))
shutil.copytree(REPO_ROOT / "core", dst)
Path(REPO_ROOT, "core").rglob("*")
for p in (REPO_ROOT / "core").rglob("*.md"):
EOF_NEARMISSPY
K4_OUT="$(census --files "${SBX}/census/nearmiss.sh" "${SBX}/census/nearmiss.py")"
K4_UNMARKED="$(printf '%s\n' "${K4_OUT}" | awk -F'\t' '$1 == "HIT" && $4 == "unmarked"')"
K4_MARKED_N="$(printf '%s\n' "${K4_OUT}" | awk -F'\t' '$1 == "HIT" && $4 == "marked"' | grep -c .)"
if [ -z "${K4_UNMARKED}" ] && [ "${K4_MARKED_N}" = 1 ]; then
  report "T8023-K4 census specificity: no near-miss line hits, and the one marked line reads marked" 1
else
  report "T8023-K4 census specificity: no near-miss line hits, and the one marked line reads marked" 0 \
    "unmarked hits: ${K4_UNMARKED:-none}; marked=${K4_MARKED_N}"
fi

# --- R13: hermeticity -----------------------------------------------------------------
STATUS_AFTER="$(git -C "${REPO_ROOT}" status --porcelain 2>&1)"
if [ "${STATUS_AFTER}" = "${STATUS_BEFORE}" ]; then
  report "T8023-R13 the source checkout's git status is unchanged" 1
else
  report "T8023-R13 the source checkout's git status is unchanged" 0 "$(differing "${STATUS_BEFORE}" "${STATUS_AFTER}")"
fi

finish
