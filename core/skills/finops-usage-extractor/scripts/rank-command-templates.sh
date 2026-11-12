#!/usr/bin/env bash
# rank-command-templates.sh — the promotion-candidate detector of the FinOps skill.
#
# Reads the local session transcripts directly (the extractor's source root and walk,
# and the store schema's § Counting unit: lines grouped by message.id, each tool_use id
# counted once) and ranks the PROCEDURES agents keep retyping — Bash commands and tool
# inputs reduced to a closed-vocabulary shape — by repetition across sessions and by
# cost in weekly points at both ends of the cache-read-weight bracket. It is the detector
# the agent-to-script promotion framework's §1 names: it suggests a rung and never
# decides one.
#
# THE PRIVACY INVARIANT. No transcript text is ever written. A token reaches the report
# only through the closed vocabulary (operators, listed command and subcommand words,
# listed flags of listed commands, tracked repository paths) or as a typed placeholder:
# <ARG> <PATH> <SLUG> <URL> <N> <SHA> <UUID> <GLOB> <VAR> <SUBST> <CODE> <HEREDOC>
# <CMD> <FLAG> <STR>. The vocabulary block below is privacy-relevant: its text is pinned
# by digest (VOCAB_DIGEST, self-test vocabulary arm), so every addition is a reviewed
# diff. A flag renders verbatim only when it is listed for its own command; any flag
# after an interpreter's script operand renders <FLAG>, because the script defines it.
#
# HOW A COMMAND IS READ. (1) A pre-mask replaces heredoc bodies, $( … ), backticks and
# ${ … } with inert sentinels, strips comments line by line (a # opens a comment only
# at a word start, outside quotes, as the shell reads it) and joins continuations.
# (2) Every command passes once through core/hooks/lib/command-position.awk, the
# governed command-start canonicalizer, in ONE awk process per transcript file: it inserts
# "; " before each genuine command start (after a keyword, a wrapper, an assignment), so
# a command position resets only after an operator. Its two artifacts — \001 inside
# quotes and an appended $XARGS-STDIN — classify as <ARG> and <VAR>. (3) shlex tokenizes;
# each token renders by class, first match wins.
#
# MEMORY FOLLOWS ONE FILE, NOT THE WINDOW. A first pass reads each file only up to its
# first timestamped record, to fix the order. Then one file at a time is parsed, costed,
# keyed and folded into the procedure accumulators, and its records are released before
# the next file is read. Across files only the copied-id set, the procedure accumulators
# and the session metadata survive. The self-test's memory arm measures it: every file's
# record list is weakly referenced, and at most one may be alive at once.
#
# THE RANKING UNIT is the procedure: each segment's command and subcommand words joined
# by their operators; its exact masked forms are listed under it as variants. A
# procedure ranks only when it appears in at least two sessions (MIN_SESSIONS, the
# framework's T-REP), each tool_use id counted once across files.
#
# COST. An occurrence costs its call and its result: the call's characters are output;
# call and result are written to the cache by the next response in the same compaction
# segment, at that response's cache tiers, and re-read by every later response up to the
# next compaction boundary. Characters become tokens at 1.5 per token. Token totals go
# to convert-usage.sh --convert, the ONE conversion; this script holds no weight, bracket
# end or tokens-per-point value. A runtime bound compares the attributed figures with the
# measured usage: tool tokens attributed to a response never exceed its measured context,
# and a segment's predicted re-reads never exceed its measured cache reads. A segment
# over the second bound is clamped to it; violations are counted, and above
# COST_BOUND_THRESHOLD the cost status reads "degraded".
#
# Usage:
#   bash rank-command-templates.sh [--window N[d]] [--top N] [--signals N]
#                                  [--work-item REF] [--out-dir DIR] [--self-test] [--help]
#     --window N[d]   days of transcripts, by file mtime (default 30)
#     --top N         rows in SUMMARY.md (default 25)
#     --signals N     Mode C caller-input records prepared (default 5)
#     --work-item REF the work_item: frontmatter value (default "unlinked")
#     --out-dir DIR   report root (default <OPERATOR_INSTANCE_ANALYSIS_PATH>, resolved by
#                     pmo_analysis_path_for from the workspace root: WORKSPACE_ROOT, else
#                     CLAUDE_WORKSPACE_ROOT, else operator.toml claude_workspace_root,
#                     else $HOME/Claude)
#     --self-test     offline arms over the committed rank fixtures
#
# Source: FINOPS_SOURCE_ROOT, else ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects.
# Checkout: PMO_SRC_ROOT, else the checkout this script sits in, else
# <workspace-root>/pmo-platform. A deployed copy outside any checkout needs one of them.
# Output: one run folder, command-template-ranking-<UTC date>/ (a same-day re-run takes
# command-template-ranking-run<N>-<UTC date>/ and never overwrites), holding SUMMARY.md,
# candidates.json and mode-c-signals.json; one summary line on stdout, path in token form.
#
# Exit codes: 0 written · 2 usage error, or not run from a checkout · 3 nothing written
#   (source unreadable, report home missing, canonicalizer or runtime canary failed,
#   format health over its threshold, path-leak class in the rendered report) OR written
#   with the cost unresolved (the conversion failed; no Mode C records) · 4 run folder
#   inside a repository but not git-ignored · 5 missing dependency (git, jq, python3, awk).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
FIXTURES_DIR="$SCRIPT_DIR/../test-fixtures/rank"
# sha256 of the PRIVACY-RELEVANT VOCABULARY block's text, marker lines included.
VOCAB_DIGEST="bdfd976e84b8f75b5a91a9283bd5ab9de84f06817aeb9431403b88557690d7af"

usage() {
  sed -n '2,/^set -uo pipefail/p' "$SELF" | sed '$d' | sed 's/^# \{0,1\}//'
  exit 0
}
die() { printf '%s\n' "$1" >&2; exit "${2:-2}"; }

preflight_deps() {
  local missing="" t
  for t in git jq python3; do
    command -v "$t" >/dev/null 2>&1 || missing="${missing:+$missing, }$t"
  done
  if [ -x /usr/bin/awk ]; then RANK_AWK=/usr/bin/awk
  elif command -v awk >/dev/null 2>&1; then RANK_AWK="$(command -v awk)"
  else missing="${missing:+$missing, }awk"; fi
  [ -z "$missing" ] || die "FATAL (exit 5): missing dependency: $missing — see SKILL.md ## Dependencies" 5
}

# The workspace root, four steps: WORKSPACE_ROOT, CLAUDE_WORKSPACE_ROOT, the operator.toml
# key claude_workspace_root, $HOME/Claude. The toml read is the extractor's own form.
_rank_workspace_root() {
  local v="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}" toml="${HOME}/.config/pmo-platform/operator.toml"
  if [ -z "$v" ] && [ -r "$toml" ]; then
    v="$( { grep -m1 -E '^claude_workspace_root' "$toml" 2>/dev/null || true; } | awk -F= '{gsub(/[" ]/,"",$2); print $2}')"
  fi
  printf '%s' "${v:-${HOME}/Claude}"
}

_rank_is_checkout() {
  [ -n "$1" ] && [ -r "$1/core/deploy/lib-instance-path.sh" ] \
    && [ -r "$1/core/hooks/lib/command-position.awk" ] \
    && [ -r "$1/core/deploy/tools/path-leak-patterns.sh" ]
}

resolve_checkout() {
  local c here
  here="$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd)" || here=""
  for c in "${PMO_SRC_ROOT:-}" "$here" "$(_rank_workspace_root)/pmo-platform"; do
    if _rank_is_checkout "$c"; then CHECKOUT="$(cd "$c" && pwd)"; break; fi
  done
  [ -n "${CHECKOUT:-}" ] || die "ERROR (exit 2): not run from a checkout — the canonicalizer, the path resolver and the path-leak primitive live in the platform checkout. Run the script from the checkout, set PMO_SRC_ROOT to it, or keep it at <workspace-root>/pmo-platform." 2
  git -C "$CHECKOUT" rev-parse --show-toplevel >/dev/null 2>&1 \
    || die "ERROR (exit 2): $CHECKOUT is not a git work tree, so its tracked set cannot be read." 2
  local common
  common="$(cd "$CHECKOUT" && cd "$(git rev-parse --git-common-dir)" && cd .. && pwd)" \
    || die "ERROR (exit 2): the checkout's common directory is unreadable." 2
  CHECKOUT_NAME="$(basename "$common")"
}

# FM-2-shaped guard: a path inside a repository must be git-ignored there.
guard_ignored() {
  local target="$1" probe="$1" repo
  while [ ! -d "$probe" ] && [ "$probe" != "/" ] && [ -n "$probe" ]; do probe="$(dirname "$probe")"; done
  [ -d "$probe" ] || return 0
  repo="$(git -C "$probe" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$repo" ] || return 0
  git -C "$repo" check-ignore -q -- "$target" 2>/dev/null && return 0
  printf 'FATAL (exit 4): the report path is inside a git repository but is NOT git-ignored there; nothing written.\n' >&2
  printf 'Point --out-dir at an ignored or outside-repo folder, or use the default analysis home.\n' >&2
  exit 4
}

run_main() {
  local window=30 top=25 signals=5 work_item="unlinked" out_dir="" token_form=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --window)    [ $# -ge 2 ] || die "ERROR (exit 2): --window needs a value" 2; window="${2%d}"; shift 2 ;;
      --top)       [ $# -ge 2 ] || die "ERROR (exit 2): --top needs a value" 2; top="$2"; shift 2 ;;
      --signals)   [ $# -ge 2 ] || die "ERROR (exit 2): --signals needs a value" 2; signals="$2"; shift 2 ;;
      --work-item) [ $# -ge 2 ] || die "ERROR (exit 2): --work-item needs a value" 2; work_item="$2"; shift 2 ;;
      --out-dir)   [ $# -ge 2 ] || die "ERROR (exit 2): --out-dir needs a value" 2; out_dir="$2"; shift 2 ;;
      *) die "ERROR (exit 2): unknown argument: $1 (see --help)" 2 ;;
    esac
  done
  case "$window" in ''|*[!0-9]*|0) die "ERROR (exit 2): --window must be a positive whole number of days" 2 ;; esac
  case "$top" in ''|*[!0-9]*|0) die "ERROR (exit 2): --top must be a positive integer" 2 ;; esac
  case "$signals" in ''|*[!0-9]*) die "ERROR (exit 2): --signals must be a whole number" 2 ;; esac
  [[ "$work_item" =~ ^[A-Za-z0-9#._\ -]{1,64}$ ]] || die "ERROR (exit 2): --work-item takes letters, digits, '#', '.', '_', '-' and spaces (at most 64)" 2

  preflight_deps
  resolve_checkout
  # shellcheck source=/dev/null
  . "$CHECKOUT/core/deploy/lib-instance-path.sh"

  local src="${FINOPS_SOURCE_ROOT:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects}"
  [ -d "$src" ] && [ -r "$src" ] || die "FATAL (exit 3): session-data source root unreadable; nothing written" 3

  if [ -z "$out_dir" ]; then
    out_dir="$(pmo_analysis_path_for "$(_rank_workspace_root)")"
    token_form=1
    [ -d "$out_dir" ] || die "FATAL (exit 3): the analysis home does not exist (it ships with the checkout; it is never created by a writer); nothing written" 3
  else
    case "$out_dir" in /*) ;; *) out_dir="$PWD/$out_dir" ;; esac
    guard_ignored "$out_dir/.command-template-ranking.staging-$$"
    mkdir -p "$out_dir" 2>/dev/null || die "FATAL (exit 3): --out-dir could not be created; nothing written" 3
  fi
  out_dir="$(cd "$out_dir" && pwd)"

  local day name n=1 run staging
  day="$(date -u +%Y-%m-%d)"
  staging="$out_dir/.command-template-ranking.staging-$$"
  guard_ignored "$staging"
  while :; do
    if [ "$n" -eq 1 ]; then name="command-template-ranking-$day"; else name="command-template-ranking-run$n-$day"; fi
    [ -e "$out_dir/$name" ] || break
    n=$((n + 1))
    [ "$n" -le 99 ] || die "FATAL (exit 3): 99 runs already exist for $day; nothing written" 3
  done
  guard_ignored "$out_dir/$name"
  run="$out_dir/$name"

  local work
  work="$(mktemp -d "${TMPDIR:-/tmp}/rank-command-templates-XXXXXX")" || die "FATAL (exit 3): mktemp failed" 3
  trap 'rm -rf "$work" "$staging"' EXIT
  mkdir "$staging" || die "FATAL (exit 3): could not create the staging folder; nothing written" 3
  git -C "$CHECKOUT" ls-files > "$work/tracked.txt" 2>/dev/null || die "ERROR (exit 2): the checkout's tracked set is unreadable" 2

  local local_report converter="$SCRIPT_DIR/convert-usage.sh" rc
  if [ "$token_form" -eq 1 ]; then local_report="<OPERATOR_INSTANCE_ANALYSIS_PATH>/$name/"; else local_report="--out-dir:$name/"; fi
  if [ "${RANK_SELFTEST:-}" = "1" ] && [ -n "${RANK_CONVERTER:-}" ]; then converter="$RANK_CONVERTER"; fi

  RANK_SOURCE="$src" RANK_WINDOW_DAYS="$window" RANK_TOP="$top" RANK_SIGNALS="$signals" \
  RANK_WORK_ITEM="$work_item" RANK_STAGING="$staging" RANK_RUN_NAME="$name" RANK_LOCAL_REPORT="$local_report" \
  RANK_TRACKED="$work/tracked.txt" RANK_CHECKOUT_NAME="$CHECKOUT_NAME" RANK_CONVERTER_PATH="$converter" \
  RANK_CANON_AWK="$CHECKOUT/core/hooks/lib/command-position.awk" RANK_AWK_BIN="$RANK_AWK" \
  RANK_WORK="$work" RANK_FIXTURES="$FIXTURES_DIR/sessions" \
  python3 -I - > "$work/core.json" <<'PYEOF'
import bisect, datetime, hashlib, json, os, re, shlex, stat, subprocess, sys, weakref
from fractions import Fraction as F

E = os.environ
SELFTEST = E.get("RANK_SELFTEST") == "1"
CHARS_PER_TOKEN = F(3, 2)
COST_BOUND_THRESHOLD = F(5, 100)   # [RECOMMENDED] share of segments over either bound
FORMAT_WARN = F(1, 100)            # [RECOMMENDED] above the measured parse-loss baseline
FORMAT_FATAL = F(5, 100)           # [RECOMMENDED] the review's starting value
MIN_SESSIONS = 2  # T-REP
STAGE_EXEC_RE = re.compile(r"executing Stage[\s-]*(\d{1,2})\b")
STAGE_ANY_RE = re.compile(r"\bStage[\s-]*(\d{1,2})\b")
HUB_RE = re.compile(r"\bMilestone [a-z0-9]+(?:-[a-z0-9]+)+")
SPAWN_TOOLS = ("Agent", "Task", "mcp__ccd_session__spawn_task")

# >>> PRIVACY-RELEVANT VOCABULARY — begin (the self-test pins this block by digest)
COMMANDS = frozenset("""
cd echo printf export source . set unset test [ [[ true false read local declare eval exec exit return
shift wait trap type command hash pushd popd pwd sleep time timeout nohup env xargs tee yes
ls cat head tail wc sort uniq cut tr paste join comm diff cmp cp mv rm mkdir rmdir touch chmod ln stat du
df find basename dirname realpath readlink mktemp date seq expr od xxd file which uname ps kill pkill pgrep
lsof sed awk grep egrep rg tar gzip gunzip zip unzip shasum sha256sum md5 openssl base64 column nl rev split
iconv cksum trash
git gh jq yq python python3 pip pip3 node npm npx bash sh zsh make curl ssh rsync brew docker open osascript
defaults plutil launchctl sqlite3 perl ruby go cargo claude
""".split())
SUBCOMMANDS = {
    "git": frozenset("""status log diff show add commit push pull fetch merge rebase checkout switch branch
        worktree remote rev-parse ls-files ls-remote ls-tree grep blame tag stash reset restore clean config
        describe cherry-pick revert merge-base for-each-ref cat-file shortlog rev-list name-rev check-ignore
        diff-tree show-ref""".split()),
    "gh": frozenset("""issue pr api run workflow repo release label search project auth ruleset view list
        create edit comment close reopen checks ready review delete download watch rerun item-list item-add
        item-edit field-list""".split()),
}
OTHER_SUBCOMMANDS = frozenset("""install test ci exec build start uninstall freeze compose up down logs stop
    images pull info upgrade load unload bootstrap bootout print kickstart""".split())
for _c in ("npm", "pip", "pip3", "brew", "docker", "launchctl", "cargo", "go"):
    SUBCOMMANDS[_c] = OTHER_SUBCOMMANDS
SUB_DEPTH = {"git": 1, "gh": 2, "docker": 2, "npm": 1, "pip": 1, "pip3": 1, "brew": 1, "launchctl": 1,
             "cargo": 1, "go": 1}
_F = {
    "git": """-C -c -n -m -F -q -s -b -p -u -v -z -w -r -d -D -f -l -U --oneline --format --pretty --name-only
        --name-status --stat --short --porcelain --all --no-merges --graph --decorate --cached --staged
        --abbrev-ref --show-toplevel --git-common-dir --is-ancestor --quiet --verbose --no-pager
        --force-with-lease --set-upstream --detach --since --until --author --grep --reverse --max-count
        --diff-filter --exit-code --no-color --unified --depth --prune --tags --no-edit --ff-only""",
    "gh": """-R -q -L -s -t -b -F -f -X -H --repo --json --jq --limit --state --search --label --milestone
        --title --body --body-file --head --base --web --comments --assignee --reviewer --draft --method
        --input --paginate --field --raw-field --header --template --add-label --remove-label --watch
        --log --log-failed --branch --workflow --status --event --commit --exit-status --fill --squash""",
    "jq": "-r -c -n -s -e -j -S -R --arg --argjson --slurp --raw-output --compact-output --exit-status --null-input --tab --indent --sort-keys --raw-input",
    "grep": "-n -c -i -v -l -L -r -R -E -F -w -x -o -q -s -h -H -A -B -C -e -f -m -z --include --exclude --exclude-dir --color --count --line-number --ignore-case --recursive --files-with-matches",
    "rg": "-n -c -i -v -l -w -F -e -g -t -A -B -C -o --files --glob --type --hidden --no-ignore --count --json",
    "sed": "-n -e -E -i -r -f --quiet --expression --in-place",
    "awk": "-F -v -f",
    "find": "-name -iname -type -path -prune -print -print0 -maxdepth -mindepth -mtime -newer -size -exec -delete -not -o -a -empty -perm -regex",
    "ls": "-l -a -A -1 -R -t -r -h -d -la -lt -ltr -lh -S",
    "head": "-n -c", "tail": "-n -c -f -F", "wc": "-l -c -w -m",
    "sort": "-n -r -u -k -t -h -V -z -f -s -g --numeric-sort --reverse --unique",
    "uniq": "-c -d -u -i", "cut": "-d -f -c -b", "tr": "-d -s -c", "cat": "-n -A -v -e",
    "diff": "-u -r -q -N -w -b --brief --unified --color", "cmp": "-s -l",
    "cp": "-r -R -p -a -f -n -v", "mv": "-f -n -v -i", "rm": "-r -f -rf -R -v -i", "mkdir": "-p -m -v",
    "ln": "-s -f -n -sf -sfn", "chmod": "-R", "touch": "-t -d -m -a",
    "curl": "-s -S -L -o -O -I -f -X -H -d -i -k -sS -sL -fsSL --silent --fail --location --output --header --data --request --max-time",
    "python": "-c -m -u -I -B -V -E -S -W -X --version", "python3": "-c -m -u -I -B -V -E -S -W -X --version",
    "bash": "-c -e -u -x -n -l -s -o --norc --noprofile", "sh": "-c -e -u -x -n -s", "zsh": "-c -e -f -l -x",
    "node": "-e -p -v --version", "perl": "-e -n -p -i -l -w", "ruby": "-e -n -p -w",
    "xargs": "-0 -n -I -P -r -L -t", "tee": "-a", "date": "-u -d -j -f -r -v -I --iso-8601", "printf": "-v",
    "echo": "-n -e -E", "mktemp": "-d -t -u -p", "timeout": "-s -k",
    "test": "-f -d -e -s -r -w -x -n -z -L -h", "[": "-f -d -e -s -r -w -x -n -z -L -h",
    "stat": "-f -c -L --format", "du": "-s -h -k -d -a -sh", "df": "-h -k", "ps": "-e -f -o -p -A -ax -ef",
    "kill": "-9 -s -l", "pkill": "-f -9", "pgrep": "-f -l -a", "tar": "-c -x -t -z -f -v -C -czf -xzf -tzf",
    "zip": "-r -q", "unzip": "-o -q -d -l", "gzip": "-d -c -k", "shasum": "-a -c", "sha256sum": "-c",
    "base64": "-d -D -i -o --decode", "readlink": "-f -n", "realpath": "-m -e", "basename": "-s -a",
    "seq": "-w -s -f", "od": "-c -x -A -t", "xxd": "-p -r", "file": "-b -I", "which": "-a",
    "uname": "-a -s -m -r", "lsof": "-p -i -a -d -n -P", "column": "-t -s", "nl": "-b -n", "split": "-l -b",
    "iconv": "-f -t", "npm": "-g -D --global --save-dev", "pip": "-r -U -q --user --upgrade",
    "pip3": "-r -U -q --user --upgrade", "brew": "--cask", "docker": "-d -p -v -e --rm --name",
    "make": "-C -j -n -f", "ssh": "-i -p -o -T", "rsync": "-a -v -z -n --delete --exclude", "open": "-a -R -n",
    "defaults": "-g", "plutil": "-p -lint", "sqlite3": "-json -header -csv", "cargo": "--release", "go": "-v",
    "claude": "-p --print --model --output-format --verbose", "set": "-e -u -x -o -euo -eu",
    "export": "-n -p", "read": "-r -p -a -d -n -t", "local": "-a -r -i", "declare": "-a -A -i -r -x -f -p",
    "type": "-a -t -p", "command": "-v -V -p", "hash": "-r", "trap": "-l -p", "trash": "-v",
}
FLAGS = {k: frozenset(v.split()) for k, v in _F.items()}
FLAGS["egrep"] = FLAGS["grep"]
VALUE_FLAGS = {"git": frozenset(["-C", "-c"]), "gh": frozenset(["-R", "--repo"])}
INTERPRETERS = frozenset("python python3 bash sh zsh node perl ruby".split())
PROGRAM_FLAGS = {"python": "-c", "python3": "-c", "bash": "-c", "sh": "-c", "zsh": "-c",
                 "node": "-e", "perl": "-e", "ruby": "-e", "sed": "-e"}
FIRST_OPERAND_CODE = frozenset("jq yq awk sed".split())
KEYWORDS = frozenset("if then else elif fi for in do done while until case esac function select { } [[ ]] !".split())
KEY_KEYWORDS = frozenset("for while if case until select".split())
KW_STAY0 = frozenset("if then else elif while until do ! {".split())
HARNESS_TOOLS = frozenset("""Read Write Edit MultiEdit NotebookEdit Grep Glob Agent Task Skill TodoWrite
    WebFetch WebSearch ToolSearch AskUserQuestion Monitor SendMessage""".split())
PATH_KEYS = frozenset(["file_path", "path", "notebook_path"])
PATH_EXTS = frozenset("json jsonl md sh py txt yml yaml toml log csv tsv js html skill".split())
# <<< PRIVACY-RELEVANT VOCABULARY — end

OPS = ("&&", "||", "|&", ";;", "|", ";", "&")
REDIRS = ("&>>", "<<<", "&>", ">>", ">&", "<&", "<>", ">|", "<<", "<", ">")
PUNCT_SPLIT = sorted(OPS + REDIRS + ("(", ")"), key=len, reverse=True)
PUNCT = set("();<>|&")
SUBST, VAR, HEREDOC = "\x02S\x03", "\x02V\x03", "\x02H\x03"
HEREDOC_RE = re.compile(r"<<(-?)[ \t]*(?:'([^'\n]+)'|\"([^\"\n]+)\"|\\?([A-Za-z_][A-Za-z0-9_]*))")
ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*\+?=")
URL_RE = re.compile(r"^[a-z][a-z0-9+.-]*://")
UUID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
NUM_RE = re.compile(r"^#?[0-9]+(\.[0-9]+)?$")
SHA_RE = re.compile(r"^[0-9a-f]{7,40}$")
NUMFLAG_RE = re.compile(r"^-[0-9]+$")
CANARY_KEY = 'cd && gh issue view | head'
NEAR_MISS_KEYS = ('printf', 'sleep && gh run list')


def fatal(cause):
    sys.stderr.write("FATAL (exit 3): %s; nothing written\n" % cause)
    sys.exit(3)


def rhu(x):
    return int((x + F(1, 2)) // 1)


class Tracer:
    """Self-test only: which masking class consumed each listed fixture literal, and the
    procedure it landed in. Keyed by row index, so no literal is ever written."""
    def __init__(self, lits):
        self.lits, self.pending, self.seen = lits, [], {}

    def hit(self, text, cls):
        if self.lits and text:
            for i, lit in enumerate(self.lits):
                if lit in text:
                    self.pending.append((i, cls))

    def commit(self, key):
        for i, cls in self.pending:
            self.seen.setdefault(str(i), set()).add((cls, key))
        self.pending = []

    def out(self):
        return {k: sorted([list(x) for x in v]) for k, v in sorted(self.seen.items())}


class Canon:
    """ONE awk process per batch — a transcript file's commands: command-position.awk plus a
    record driver that calls its own scan / locate / emit per record and resets its state
    between records, so a batch's composition never changes a record's output."""
    DRIVER = ('BEGIN { RS = "\\036" }\n'
              '{\n  if (NR > 1) buf = substr(buf, 2)\n'
              '  if (!scan()) r = buf\n  else { locate(); r = emit() }\n'
              '  printf "%s\\036", r\n'
              '  buf = ""; split("", ins); split("", drop); split("", tail)\n}\n')

    def __init__(self):
        self.awk, self.lib = E["RANK_AWK_BIN"], E["RANK_CANON_AWK"]
        self.driver = os.path.join(E["RANK_WORK"], "canon-driver.awk")
        with open(self.driver, "w") as fh:
            fh.write(self.DRIVER)

    def batch(self, cmds):
        if not cmds:
            return []
        data = "".join(c.replace("\x1e", " ") + "\x1e" for c in cmds)
        p = subprocess.run([self.awk, "-f", self.lib, "-f", self.driver], input=data.encode("utf-8"),
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out = p.stdout.decode("utf-8", "replace").split("\x1e")
        if p.returncode != 0 or len(out) < len(cmds):
            fatal("the command-position canonicalizer failed on the batch")
        return out[:len(cmds)]

    def single(self, cmd):
        p = subprocess.run([self.awk, "-f", self.lib], input=cmd.encode("utf-8"),
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return p.stdout.decode("utf-8", "replace")

    def canary(self):
        # The deployed hooks' own canary inputs, through the batch path.
        a, b = self.batch(["q() { r; }", "Z+=0 nice -n 0 q"])
        if "; r" not in a or "; q" not in b:
            fatal("the command-position canonicalizer failed its canary")


def close_paren(s, i):
    # The end of a $( … ) body. Quote-aware, and heredoc-aware: a heredoc body inside the
    # substitution (the commit-message idiom) is skipped whole, so an apostrophe in it is
    # text, never an opening quote.
    d, q, n, pend = 1, None, len(s), []
    while i < n:
        c = s[i]
        if q:
            if c == q:
                q = None
            elif c == "\\" and q == '"':
                i += 1
        elif c in "'\"":
            q = c
        elif c == "\\":
            i += 1
        elif c == "<" and s.startswith("<<", i) and not s.startswith("<<<", i) and HEREDOC_RE.match(s, i):
            m = HEREDOC_RE.match(s, i)
            pend.append((m.group(2) or m.group(3) or m.group(4), m.group(1) == "-"))
            i = m.end()
            continue
        elif c == "\n" and pend:
            i += 1
            for delim, strip in pend:
                while i < n:
                    j = s.find("\n", i)
                    j = n if j < 0 else j
                    line = s[i:j]
                    i = min(j + 1, n)
                    if (line.lstrip("\t") if strip else line) == delim:
                        break
            pend = []
            continue
        elif c == "(":
            d += 1
        elif c == ")":
            d -= 1
            if d == 0:
                return i + 1
        i += 1
    return len(s)


def premask(cmd, tr, cov):
    out, i, n, q, pend = [], 0, len(cmd), None, []
    while i < n:
        c = cmd[i]
        if q == "'":
            out.append(c)
            q = None if c == "'" else q
            i += 1
            continue
        if c == "\\":
            if i + 1 < n and cmd[i + 1] == "\n":
                out.append(" ")
            else:
                out.append(cmd[i:i + 2])
            i += 2
            continue
        if cmd.startswith("$((", i):
            j = close_paren(cmd, i + 2)
            tr.hit(cmd[i:j], "var")
            out.append(VAR)
            i = j
            continue
        if cmd.startswith("$(", i):
            j = close_paren(cmd, i + 2)
            tr.hit(cmd[i:j], "var")
            out.append(SUBST)
            i = j
            continue
        if cmd.startswith("${", i):
            j = cmd.find("}", i)
            j = n if j < 0 else j + 1
            tr.hit(cmd[i:j], "var")
            out.append(VAR)
            i = j
            continue
        if c == "`":
            j = cmd.find("`", i + 1)
            j = n if j < 0 else j + 1
            tr.hit(cmd[i:j], "var")
            out.append(SUBST)
            i = j
            continue
        if q == '"':
            out.append(c)
            q = None if c == '"' else q
            i += 1
            continue
        if c in "'\"":
            q = c
            out.append(c)
            i += 1
            continue
        if c == "#" and (i == 0 or cmd[i - 1] in " \t\n;&|("):
            j = cmd.find("\n", i)
            j = n if j < 0 else j
            tr.hit(cmd[i:j], "comment")
            cov["comment_lines"] += 1
            i = j
            continue
        if c == "<" and cmd.startswith("<<", i) and not cmd.startswith("<<<", i):
            m = HEREDOC_RE.match(cmd, i)
            if m:
                pend.append((m.group(2) or m.group(3) or m.group(4), m.group(1) == "-"))
                out.append(" " + HEREDOC + " ")
                i = m.end()
                continue
        if c == "\n" and pend:
            out.append("\n")
            i += 1
            for delim, strip in pend:
                start = i
                while i < n:
                    j = cmd.find("\n", i)
                    j = n if j < 0 else j
                    line = cmd[i:j]
                    if (line.lstrip("\t") if strip else line) == delim:
                        tr.hit(cmd[start:i], "heredoc")
                        i = min(j + 1, n)
                        break
                    i = j + 1
                else:
                    tr.hit(cmd[start:n], "heredoc")
            pend = []
            continue
        out.append(c)
        i += 1
    return "".join(out)


def split_punct(tok):
    if not tok or any(ch not in PUNCT for ch in tok):
        return [tok]
    parts, i = [], 0
    while i < len(tok):
        for p in PUNCT_SPLIT:
            if tok.startswith(p, i):
                parts.append(p)
                i += len(p)
                break
        else:
            parts.append(tok[i])
            i += 1
    return parts


class Ctx:
    def __init__(self, tracked, checkout_name):
        self.tracked, self.name = tracked, checkout_name

    def pathclass(self, t, tr):
        p = t[2:] if t.startswith("./") else t
        k = p.rfind("/" + self.name + "/")
        if k >= 0:
            p = p[k + len(self.name) + 2:]
        m = re.match(r"\.claude/worktrees/[^/]+/", p)
        if m:
            p = p[m.end():]
        if p.rstrip("/") in self.tracked:
            return p.rstrip("/")
        base = p.rsplit("/", 1)[-1]
        ext = base.rsplit(".", 1)[-1].lower() if "." in base[1:] else ""
        if re.fullmatch(r"[^/.~][^/]*/[^/]+", p) and ext not in PATH_EXTS:
            tr.hit(t, "slug")
            return "<SLUG>"
        tr.hit(t, "path")
        return "<PATH>" + ("." + ext if ext in PATH_EXTS else "")

    def wordclass(self, t, tr):
        if "\x02" in t:
            if t == HEREDOC:
                return "<HEREDOC>"
            if t == SUBST:
                return "<SUBST>"
            return "<VAR>"
        if "$" in t or "`" in t:
            tr.hit(t, "var")
            return "<VAR>"
        if "\x01" in t:
            tr.hit(t, "default")
            return "<ARG>"
        if URL_RE.match(t):
            tr.hit(t, "url")
            return "<URL>"
        if UUID_RE.match(t):
            return "<UUID>"
        if NUM_RE.match(t):
            return "<N>"
        if SHA_RE.match(t):
            return "<SHA>"
        if "*" in t or "?" in t:
            tr.hit(t, "glob")
            return "<GLOB>"
        if "/" in t or t.startswith("~") or t.startswith("."):
            return self.pathclass(t, tr)
        tr.hit(t, "default")
        return '<ARG>'  # R10 closed-vocabulary default


class Seg:
    def __init__(self):
        self.cw = self.cmd = self.kw = self.script = None
        self.subs, self.sub_left = [], 0
        self.host = self.after_script = self.stdin = self.program = self.heredoc = False
        self.code_first = self.code_done = self.expect_code = self.expect_value = False

    def contribution(self):
        if self.cmd is None:
            return self.kw or ""
        parts = [self.cmd] + self.subs
        if self.host:
            if self.script:
                parts.append(self.script)
            elif self.program:
                parts.append("<CODE>")
            elif self.heredoc:
                parts.append("<HEREDOC>")
        return " ".join(parts)


def render_flag(t, seg, tr):
    dash = "--" if t.startswith("--") else "-"
    if NUMFLAG_RE.match(t):
        return "-<N>"
    if seg.host and seg.after_script:
        tr.hit(t, "interpreter-flag")
        return dash + "<FLAG>"  # CD-1 interpreter-flag class
    name, eq, val = t.partition("=") if t.startswith("--") else (t, "", "")
    if name in FLAGS.get(seg.cw, ()):
        if PROGRAM_FLAGS.get(seg.cw) == name or (seg.cw == "gh" and name in ("--jq", "-q")):
            seg.expect_code = True
            seg.code_done = True
        elif name in VALUE_FLAGS.get(seg.cw, ()) and not eq:
            seg.expect_value = True
        return name + ("=" + CTX.wordclass(val, tr) if eq else "")
    tr.hit(t, "flag")
    return dash + "<FLAG>"  # CD-1 closed flag class


def render_command(text, tr, cov):
    """Returns (variant, key, contributions) for one canonicalized, pre-masked command."""
    s = text.replace("\n", " ; ")
    try:
        lx = shlex.shlex(s, posix=True, punctuation_chars=True)
        lx.whitespace_split = True
        lx.commenters = ""
        raw = list(lx)
    except ValueError:
        cov["unparsed"] += 1
        cov["lost_tokens"] += len(s.split())
        tr.hit(text, "unparsed")
        return "<UNPARSED>", "<UNPARSED>", []
    toks = []
    for t in raw:
        toks.extend(split_punct(t))
    out, segs, seg, pos, redir = [], [], Seg(), 0, False
    pending = []
    for t in toks:
        if t in OPS:
            if t == ";" and (not out or out[-1] in OPS or out[-1] in ("(", ")")):
                continue
            out.append(t)
            segs.append((list(pending), seg))
            pending, seg, pos = [t], Seg(), 0
            continue
        if t in ("(", ")"):
            out.append(t)
            segs.append((list(pending), seg))
            pending, seg, pos = [], Seg(), 0
            continue
        if t in REDIRS:
            out.append(t)
            redir = True
            continue
        if redir:
            out.append(CTX.wordclass(t, tr))
            redir = False
            continue
        if pos == 0:
            if t in KEYWORDS:
                out.append(t)
                if t in KEY_KEYWORDS:
                    seg.kw = t
                if t not in KW_STAY0:
                    pos = 1
                continue
            if ASSIGN_RE.match(t):
                name, _, val = t.partition("=")
                tr.hit(name, "var")
                out.append("<VAR>=" + (CTX.wordclass(val, tr) if val else ""))
                continue
            if t in COMMANDS:
                r = t
            else:
                r = CTX.pathclass(t, tr) if ("/" in t) else None
                if r is None or r.startswith("<"):
                    tr.hit(t, "command")
                    cov["unknown_command_words"] += 1
                    r = "<CMD>"  # CD-1 command-word class
            out.append(r)
            seg.cw, seg.cmd = t, r
            seg.host = t in INTERPRETERS
            seg.code_first = t in FIRST_OPERAND_CODE
            seg.sub_left = SUB_DEPTH.get(t, 0)
            pos = 1
            continue
        if seg.expect_code:
            tr.hit(t, "code")
            out.append("<CODE>")
            seg.expect_code, seg.program = False, True
            continue
        if t == HEREDOC:
            out.append("<HEREDOC>")
            seg.heredoc = True
            continue
        if t.startswith("-") and len(t) > 1 and "\x02" not in t:
            out.append(render_flag(t, seg, tr))
            continue
        if seg.expect_value:
            out.append(CTX.wordclass(t, tr))
            seg.expect_value = False
            continue
        if seg.sub_left > 0 and t in SUBCOMMANDS.get(seg.cw, ()):
            out.append(t)
            seg.subs.append(t)
            seg.sub_left -= 1
            continue
        seg.sub_left = 0
        if seg.host and not seg.after_script and not seg.program and not seg.stdin:
            if t == "-":
                out.append("-")
                seg.stdin = True
                continue
            r = CTX.wordclass(t, tr)
            out.append(r)
            seg.after_script = True
            if not r.startswith("<"):
                seg.script = r
            continue
        if seg.code_first and not seg.code_done:
            tr.hit(t, "code")
            out.append("<CODE>")
            seg.code_done = True
            continue
        out.append(CTX.wordclass(t, tr))
    segs.append((pending, seg))
    while out and out[-1] in (";", "&"):
        out.pop()
    key, contribs, op = "", [], None
    for ops, sg in segs:
        for o in ops:
            if op is None or op == ";":
                op = o
        c = sg.contribution()
        if not c:
            continue
        if key:
            key += " " + (op or ";") + " "
        key += c
        contribs.append(c)
        op = None
    return " ".join(out), key, contribs


def tool_key(name, inp, tr):
    if name.startswith("mcp__"):
        return "mcp", "MCP", "MCP"
    if name == "Write" and isinstance(inp, dict) and str(inp.get("file_path", "")).rsplit(".", 1)[-1] in ("py", "sh", "js"):
        pc = CTX.pathclass(str(inp.get("file_path")), tr)
        tr.hit(str(inp.get("content", "")), "code")
        k = "Write %s <CODE>" % pc
        return "write-script", k, k
    if name not in HARNESS_TOOLS:
        tr.hit(name, "tool-name")
        return "tool", "<TOOL>", "<TOOL>"
    parts = []
    for k in sorted((inp or {}).keys()) if isinstance(inp, dict) else []:
        v = inp[k]
        kk = k if re.fullmatch(r"[a-z_]{1,32}", k) else "<KEY>"
        if k in PATH_KEYS and isinstance(v, str):
            parts.append("%s:%s" % (kk, CTX.pathclass(v, tr)))
        elif isinstance(v, bool):
            parts.append("%s:%s" % (kk, "true" if v else "false"))
        elif isinstance(v, (int, float)):
            parts.append("%s:<N>" % kk)
        else:
            tr.hit(json.dumps(v, ensure_ascii=False), "tool-input")
            parts.append("%s:<STR>" % kk)
    k = "%s{%s}" % (name, ",".join(parts))
    return "tool-input", k, k


def msg(r):
    m = r.get("message")
    return m if isinstance(m, dict) else {}


def msg_text(r):
    c = msg(r).get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        return "\n".join(b.get("text") for b in c
                         if isinstance(b, dict) and b.get("type") == "text" and isinstance(b.get("text"), str))
    return ""


def first_user(recs):
    for r in recs:
        if r.get("type") == "user" and not r.get("isMeta"):
            t = msg_text(r)
            if t.strip():
                return t
    return ""


def ts_key(t):
    if not isinstance(t, str) or len(t) < 19:
        return ("9999-99-99T99:99:99", "")
    return (t[0:19], t[19:])


def walk(root, suffix, days):
    found, now = [], datetime.datetime.now(datetime.timezone.utc).timestamp()
    for dp, dns, fns in os.walk(root, followlinks=False):
        dns[:] = sorted(d for d in dns if not os.path.islink(os.path.join(dp, d)))
        for fn in sorted(fns):
            if not fn.endswith(suffix):
                continue
            fp = os.path.join(dp, fn)
            try:
                st = os.lstat(fp)
            except OSError:
                continue
            if not stat.S_ISREG(st.st_mode):
                continue
            if days is not None and st.st_mtime < now - days * 86400:
                continue
            found.append(fp)
    return found


class Recs(list):
    """One transcript file's parsed records. A list that can be weakly referenced, so
    analyze() can count how many files' records are alive at once (the memory arm)."""


def first_timestamp(fp):
    # The order key only: the first parsed record carrying a string timestamp, read no
    # further. The same predicate the whole-file parse used; bad lines are counted once,
    # by read_file.
    with open(fp, "rb") as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw:
                continue
            try:
                obj = json.loads(raw)
            except ValueError:
                continue
            if isinstance(obj, dict) and isinstance(obj.get("timestamp"), str):
                return obj["timestamp"]
    return None


def read_file(fp, root, cov):
    recs = Recs()
    with open(fp, "rb") as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw:
                continue
            try:
                obj = json.loads(raw)
            except ValueError:
                cov["bad_lines"] += 1
                continue
            if isinstance(obj, dict):
                recs.append(obj)
    rel = os.path.relpath(fp, root)
    stem = os.path.basename(fp).split(".jsonl")[0]
    return {"fp": fp, "rel": rel, "stem": stem, "recs": recs}


def classify_session(f):
    parts = f["rel"].split(os.sep)
    nested = "subagents" in parts[:-1]
    first = first_user(f["recs"])
    if nested:
        role = "workflow-agent" if "workflows" in parts[parts.index("subagents") + 1:-1] else "nested"
    else:
        role = "main"
        for r in f["recs"]:
            if r.get("type") != "assistant" or not isinstance(msg(r).get("content"), list):
                continue
            for b in msg(r)["content"]:
                if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in SPAWN_TOOLS:
                    inp = b.get("input") if isinstance(b.get("input"), dict) else {}
                    if HUB_RE.search(" ".join(str(inp.get(k, "")) for k in ("prompt", "description"))):
                        role = "hub"
    if role == "hub":
        return role, "hub", "hub"
    m = STAGE_EXEC_RE.search(first or "")
    if m and 1 <= int(m.group(1)) <= 13:
        return role, m.group(1), "executing-stage"
    m = STAGE_ANY_RE.search((first or "")[:2000])
    if m and 1 <= int(m.group(1)) <= 13:
        return role, m.group(1), "first-message"
    return role, "unstaged", "none"


def usage_of(r):
    u = msg(r).get("usage")
    return u if isinstance(u, dict) else None


def merged(us):
    def mx(f):
        vals = [f(u) for u in us]
        vals = [v for v in vals if isinstance(v, (int, float)) and not isinstance(v, bool)]
        return max(vals) if vals else 0
    cc = lambda k: (lambda u: (u.get("cache_creation") or {}).get(k) if isinstance(u.get("cache_creation"), dict) else 0)
    return {"input": mx(lambda u: u.get("input_tokens")), "output": mx(lambda u: u.get("output_tokens")),
            "cc": mx(lambda u: u.get("cache_creation_input_tokens")),
            "h": mx(cc("ephemeral_1h_input_tokens")), "m": mx(cc("ephemeral_5m_input_tokens")),
            "cr": mx(lambda u: u.get("cache_read_input_tokens"))}


def zero():
    return {"input": F(0), "output": F(0), "cc": F(0), "h": F(0), "m": F(0), "cr": F(0)}


def analyze(files, root, tr, want_selftest):
    cov = {k: 0 for k in ("files", "responses", "tool_calls", "bash_calls", "bash_no_command", "empty_keys",
                          "unparsed", "lost_tokens", "comment_lines", "unknown_command_words", "bad_lines",
                          "copied_tool_use_ids", "duplicate_blocks_within_response", "compaction_boundaries",
                          "assistant_records")}
    bounds = {"segments_checked": 0, "segments_over": 0, "responses_over": 0, "segments_clamped": 0}
    stage_basis, per_file, sessions_meta = {}, {}, {}
    seen_ids, procs, window_total = set(), {}, zero()
    # One file at a time (F-01). The order is fixed first from each file's first timestamp;
    # then one() parses, costs, keys and folds a file, and its records die when it returns.
    # `live` weakly references every file's record list, so the most alive at once is measured.
    live, live_max = weakref.WeakSet(), [0]
    by_first = sorted((ts_key(first_timestamp(fp)), os.path.relpath(fp, root), fp) for fp in files)

    def one(fp):
        f = read_file(fp, root, cov)
        live.add(f["recs"])
        live_max[0] = max(live_max[0], len(live))
        cov["files"] += 1
        role, stage, basis = classify_session(f)
        stage_basis[basis] = stage_basis.get(basis, 0) + 1
        sessions_meta[f["stem"]] = [role, stage]
        recs, seg_ix, groups, order = f["recs"], 0, {}, []
        results, aix = {}, 0
        for li, r in enumerate(recs):
            if r.get("type") == "system" and r.get("subtype") == "compact_boundary":
                seg_ix += 1
                cov["compaction_boundaries"] += 1
                continue
            if r.get("type") == "user" and isinstance(msg(r).get("content"), list):
                for b in msg(r)["content"]:
                    if isinstance(b, dict) and b.get("type") == "tool_result" and b.get("tool_use_id") not in results:
                        c = b.get("content")
                        if isinstance(c, str):
                            n = len(c)
                        elif isinstance(c, list):
                            n = sum(len(x.get("text", "")) if isinstance(x, dict) and x.get("type") == "text"
                                    else len(json.dumps(x, ensure_ascii=False)) for x in c)
                        else:
                            n = 0
                        results[b.get("tool_use_id")] = (li, n)
                continue
            if r.get("type") != "assistant":
                continue
            cov["assistant_records"] += 1
            mid = msg(r).get("id")
            key = ("id:" + mid) if isinstance(mid, str) and mid else (
                ("uuid:" + r["uuid"]) if isinstance(r.get("uuid"), str) and r.get("uuid") else "ix:%d" % aix)
            aix += 1
            if key not in groups:
                groups[key] = {"first": li, "seg": seg_ix, "lines": [], "blocks": []}
                order.append(key)
            groups[key]["lines"].append(r)
        resp = []
        for key in order:
            g = groups[key]
            blocks, seen_here = [], set()
            for r in g["lines"]:
                c = msg(r).get("content")
                for b in (c if isinstance(c, list) else []):
                    if isinstance(b, dict) and b.get("type") == "tool_use":
                        bid = b.get("id")
                        if isinstance(bid, str) and bid in seen_here:
                            cov["duplicate_blocks_within_response"] += 1
                            continue
                        if isinstance(bid, str):
                            seen_here.add(bid)
                        blocks.append(b)
            g["blocks"] = blocks
            g["usage"] = merged([u for u in (usage_of(r) for r in g["lines"]) if u])
            resp.append(g)
        calls = sum(1 for g in resp for b in g["blocks"] if b.get("name"))
        per_file[f["stem"]] = [len(resp), calls]
        cov["responses"] += len(resp)
        for g in resp:
            for k2, k1 in (("input", "input"), ("output", "output"), ("cc", "cc"), ("h", "h"), ("m", "m"), ("cr", "cr")):
                window_total[k2] += g["usage"][k1]
        occs, members, bash_texts = [], {}, []
        for ri, g in enumerate(resp):
            members.setdefault(g["seg"], []).append(ri)
        for ri, g in enumerate(resp):
            for b in g["blocks"]:
                bid, name = b.get("id"), b.get("name") or ""
                if isinstance(bid, str):
                    if bid in seen_ids:
                        cov["copied_tool_use_ids"] += 1
                        continue
                    seen_ids.add(bid)
                cov["tool_calls"] += 1
                inp = b.get("input") if isinstance(b.get("input"), dict) else {}
                t_c = F(len(json.dumps(inp, ensure_ascii=False)) + len(name)) / CHARS_PER_TOKEN
                res = results.get(bid)
                res_line = res[0] if res else g["first"]
                t_r = F(res[1]) / CHARS_PER_TOKEN if res else F(0)
                # An occurrence keeps the file's stem, role and stage, never the file or the input.
                occ = {"stem": f["stem"], "role": role, "stage": stage, "seg": g["seg"], "name": name,
                       "t_c": t_c, "w": t_c + t_r, "kstar": None, "R": 0, "reread": F(0)}
                for kj in range(ri + 1, len(resp)):
                    if resp[kj]["first"] > res_line and resp[kj]["seg"] == g["seg"]:
                        occ["kstar"] = kj
                        break
                if occ["kstar"] is not None:
                    kj = occ["kstar"]
                    occ["kstar_usage"] = resp[kj]["usage"]
                    lst = members[g["seg"]]
                    occ["R"] = len(lst) - bisect.bisect_right(lst, kj)
                if name == "Bash":
                    cov["bash_calls"] += 1
                    cmd = inp.get("command")
                    if not isinstance(cmd, str):
                        cov["bash_no_command"] += 1
                        continue
                    occ["pre"] = premask(cmd, tr, cov)
                    occ["trace"] = tr.pending
                    tr.pending = []
                    bash_texts.append(occ)
                else:
                    kind, key, variant = tool_key(name, inp, tr)
                    occ["kind"], occ["key"], occ["variant"], occ["contribs"] = kind, key, variant, [key]
                    occ["trace"] = tr.pending
                    tr.pending = []
                occs.append(occ)
        # cost per occurrence, then the measured-usage bound per segment
        segs = sorted(set(g["seg"] for g in resp))
        for s in segs:
            rs = [(i, g) for i, g in enumerate(resp) if g["seg"] == s]
            if not rs:
                continue
            bounds["segments_checked"] += 1
            over = False
            so = [o for o in occs if o["seg"] == s and o["kstar"] is not None]
            for o in so:
                w, R = o["w"], o["R"]
                reread = w * R  # CD-2 re-read term
                o["reread"] = reread
            predicted = sum((o["reread"] for o in so), F(0))
            measured = sum((F(g["usage"]["cr"]) for _, g in rs), F(0))
            by_k, carried, nxt = sorted(so, key=lambda o: o["kstar"]), F(0), 0
            for i, g in rs:
                ctx = F(g["usage"]["input"] + g["usage"]["cc"] + g["usage"]["cr"])
                while nxt < len(by_k) and by_k[nxt]["kstar"] <= i:   # a running sum, not a rescan
                    carried += by_k[nxt]["w"]
                    nxt += 1
                if carried > ctx:
                    bounds["responses_over"] += 1
                    over = True
            factor = F(1)
            if predicted > measured:
                over = True
                bounds["segments_clamped"] += 1
                factor = measured / predicted if predicted else F(0)
            if over:
                bounds["segments_over"] += 1
            for o in so:
                o["reread"] = o["reread"] * factor
        # this file's Bash commands through the canonicalizer, as one batch
        canon = CANON.batch([o["pre"] for o in bash_texts])
        if want_selftest and bash_texts:
            # Compared as a command substitution captures each, trailing newlines dropped: a record
            # keeps the newline that ends its last line, while a whole-input run ends that line.
            CANON_EQ.append(all(CANON.single(o["pre"]).rstrip("\n") == c.rstrip("\n")
                                for o, c in zip(bash_texts, canon)))
        for o, c in zip(bash_texts, canon):
            tr.pending = o["trace"]
            variant, key, contribs = render_command(c, tr, cov)
            o["trace"] = tr.pending
            tr.pending = []
            o["kind"], o["key"], o["variant"], o["contribs"] = "bash", key, variant, contribs
        # fold this file's occurrences into the procedure accumulators
        for o in occs:
            if "key" not in o:
                continue
            tr.pending = o["trace"]
            tr.commit(o["key"])
            if o["key"] in ("", "<UNPARSED>"):
                if o["key"] == "":
                    cov["empty_keys"] += 1
                continue
            p = procs.setdefault(o["key"], {"key": o["key"], "kind": o["kind"], "contribs": o["contribs"],
                                            "variants": {}, "occurrences": 0, "sessions": {}, "tok": zero()})
            p["occurrences"] += 1
            p["variants"][o["variant"]] = p["variants"].get(o["variant"], 0) + 1
            p["sessions"][o["stem"]] = (o["role"], o["stage"])
            t = p["tok"]
            t["output"] += o["t_c"]
            if o["kstar"] is not None:
                u = o["kstar_usage"]
                w = o["w"]
                if u["h"] + u["m"] > 0:
                    t["cc"] += w
                    t["h"] += w * u["h"] / (u["h"] + u["m"])
                    t["m"] += w * u["m"] / (u["h"] + u["m"])
                elif u["cc"] > 0:
                    t["cc"] += w
                else:
                    t["input"] += w
                t["cr"] += o["reread"]

    for _first, _rel, fp in by_first:
        one(fp)
    return {"cov": cov, "bounds": bounds, "stage_basis": stage_basis, "per_file": per_file,
            "sessions": sessions_meta, "procs": procs, "window_total": window_total, "live_max": live_max[0]}


def tokens_obj(t):
    total, h = rhu(t["cc"]), rhu(t["h"])
    h = min(h, total)
    m = min(rhu(t["m"]), total - h)
    return {"input": rhu(t["input"]), "output": rhu(t["output"]),
            "cache_creation": {"total": total, "ephemeral_1h": h, "ephemeral_5m": m}, "cache_read": rhu(t["cr"])}


def tid(key):
    return "TPL-" + hashlib.sha256(key.encode("utf-8")).hexdigest()[:10]


def rung(p):
    if p["kind"] in ("tool-input", "mcp", "tool"):
        return "—", "none — context pattern", False
    if p["kind"] == "write-script":
        return "AS0", "AS2", True
    words = [w for c in p["contribs"] for w in c.split()]
    if any(not w.startswith("<") and w not in COMMANDS and "/" in w for w in words):
        return "AS2+", "none — already a tracked tool", False
    non_cd = [c for c in p["contribs"] if c.split()[0] != "cd"]
    if len(non_cd) >= 2 or any(w in ("<CODE>", "<HEREDOC>") for w in words):
        return "AS0", "AS2", True
    return "AS0", "AS1", True


def family(p):
    for c in p["contribs"]:
        w = c.split()[0]
        if w != "cd":
            return w.split("{")[0]
    return "cd"


def stage_map(p):
    out = {}
    for _role, st in p["sessions"].values():
        out[st] = out.get(st, 0) + 1
    return dict(sorted(out.items()))


def role_map(p):
    out = {}
    for role, _st in p["sessions"].values():
        out[role] = out.get(role, 0) + 1
    return dict(sorted(out.items()))


# ── run ─────────────────────────────────────────────────────────────────────────
with open(E["RANK_TRACKED"], encoding="utf-8", errors="replace") as fh:
    tracked = set()
    for line in fh:
        line = line.rstrip("\n")
        if line:
            tracked.add(line)
            parts = line.split("/")
            for i in range(1, len(parts)):
                tracked.add("/".join(parts[:i]))
CTX = Ctx(tracked, E["RANK_CHECKOUT_NAME"])
CANON = Canon()
CANON_EQ = []
CANON.canary()

# The runtime canary: replay the committed fixtures in isolation before every live run.
can = analyze(walk(E["RANK_FIXTURES"], ".jsonl.fixture", None), E["RANK_FIXTURES"], Tracer([]), False)
cp = can["procs"].get(CANARY_KEY)
if not cp or len(cp["sessions"]) != 3 or any(len(can["procs"].get(k, {"sessions": {}})["sessions"]) >= MIN_SESSIONS
                                              for k in NEAR_MISS_KEYS):
    fatal("the runtime canary failed (the known-repeated control must rank in 3 sessions and neither near-miss may rank)")

# ── the live window ─────────────────────────────────────────────────────────────
SRC = E["RANK_SOURCE"]
TR = Tracer(json.loads(E.get("RANK_TRACE") or "[]") if SELFTEST else [])
res = analyze(walk(SRC, ".jsonl", int(E["RANK_WINDOW_DAYS"])), SRC, TR, SELFTEST)
cov, bounds = res["cov"], res["bounds"]
if cov["assistant_records"] >= 1 and cov["tool_calls"] + cov["copied_tool_use_ids"] == 0:
    fatal("format guard: the window's assistant records yielded no tool call")
unreadable = cov["unparsed"] + cov["empty_keys"] + cov["bash_no_command"]
rate = F(unreadable, cov["bash_calls"]) if cov["bash_calls"] else F(0)
if rate > FORMAT_FATAL:
    fatal("format health: %d of %d Bash calls are unreadable (%.1f %%, above the %.0f %% threshold) — "
          "the transcript format has likely changed" % (unreadable, cov["bash_calls"], float(rate) * 100,
                                                         float(FORMAT_FATAL) * 100))
health = "warn" if rate > FORMAT_WARN else "ok"
if health == "warn":
    sys.stderr.write("WARN: format health: %d of %d Bash calls are unreadable (%.1f %%)\n"
                     % (unreadable, cov["bash_calls"], float(rate) * 100))

procs = res["procs"]
elig = sorted((p for p in procs.values() if len(p["sessions"]) >= MIN_SESSIONS), key=lambda p: p["key"])
for p in elig:
    p["id"], p["tokens"] = tid(p["key"]), tokens_obj(p["tok"])
    p["current"], p["suggested"], p["routable"] = rung(p)
window_tokens = tokens_obj(res["window_total"])
status, label, params_source, pairs = "unresolved", "calibration: unresolved", None, None
conv = subprocess.run(["bash", E["RANK_CONVERTER_PATH"], "--convert"],
                      input=json.dumps([window_tokens] + [p["tokens"] for p in elig]).encode("utf-8"),
                      stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if conv.returncode == 0:
    try:
        cj = json.loads(conv.stdout.decode("utf-8"))
        if len(cj["pairs"]) == len(elig) + 1:
            pairs, label, params_source = cj["pairs"], cj.get("label", label), cj.get("params", {}).get("source")
    except (ValueError, KeyError, TypeError):
        pairs = None
ENDS = ("at_w_low", "at_w_high")
if pairs is not None:
    total = pairs[0]
    status = "ok"
    if bounds["segments_checked"] and F(bounds["segments_over"], bounds["segments_checked"]) > COST_BOUND_THRESHOLD:
        status = "degraded"
    for i, p in enumerate(elig):
        p["cost_wp"] = {e: pairs[i + 1][e] for e in ENDS}
        p["share"] = {e: (pairs[i + 1][e] / total[e] if total[e] else None) for e in ENDS}
    for e in ENDS:
        for r, p in enumerate(sorted(elig, key=lambda q: (-q["cost_wp"][e], q["id"])), 1):
            p.setdefault("rank", {})[e] = r
else:
    sys.stderr.write("WARN: the cost conversion failed (convert-usage.sh exit %d); the report is written with "
                     "its cost unresolved and no Mode C record\n" % conv.returncode)
    for r, p in enumerate(sorted(elig, key=lambda q: (-len(q["sessions"]), -q["occurrences"], q["id"])), 1):
        p["cost_wp"], p["share"], p["rank"] = "unresolved", None, {e: r for e in ENDS}
for p in elig:
    p["bracket_sensitive"] = p["rank"]["at_w_low"] != p["rank"]["at_w_high"]
order = sorted(elig, key=lambda p: (p["rank"]["at_w_low"], p["rank"]["at_w_high"], p["id"]))

N = int(E["RANK_SIGNALS"])
routable = [p for p in order if p["routable"]]
rr = {}
for e in ENDS:
    for r, p in enumerate(sorted(routable, key=lambda q: (q["rank"][e], q["id"])), 1):
        rr.setdefault(p["id"], {})[e] = r
for p in elig:
    p["triggers"] = {"T-REP": "fired (%d sessions)" % len(p["sessions"]),
                     "T-TOK": ("not evaluated (cost unresolved)" if pairs is None else
                               "fired" if p["routable"] and all(rr[p["id"]][e] <= N for e in ENDS) else "not fired"),
                     "T-DET": "not evaluated (judgment — framework §1)",
                     "T-VAR": "not evaluated (judgment — framework §1)",
                     "T-RISK": "not evaluated (judgment — framework §1)"}
chosen = [] if pairs is None else sorted(
    routable, key=lambda p: (max(rr[p["id"]].values()), min(rr[p["id"]].values()), p["id"]))[:N]

now = datetime.datetime.now(datetime.timezone.utc)
created = now.strftime("%Y-%m-%d")
sunset = (now + datetime.timedelta(days=90)).strftime("%Y-%m-%d")
days = int(E["RANK_WINDOW_DAYS"])
stg = E["RANK_STAGING"]
session_count = len(res["sessions"])
cost_unit = "weekly points of one account at both ends of the cache-read-weight bracket (at_w_low, at_w_high)"


def fmt_pair(d):
    if d == "unresolved" or d is None:
        return "unresolved"
    return "%.4g · %.4g" % (d["at_w_low"], d["at_w_high"])


def fmt_share(d):
    if not d:
        return "unresolved"
    return " · ".join("%.2f %%" % (d[e] * 100) if d[e] is not None else "n/a" for e in ENDS)


def cand(p):
    vs = sorted(p["variants"].items(), key=lambda kv: (-kv[1], kv[0]))
    return {"id": p["id"], "kind": p["kind"], "procedure": p["key"], "family": family(p),
            "segments": len(p["contribs"]), "variants": dict(sorted(p["variants"].items())),
            "top_variants": [v for v, _ in vs[:3]], "occurrences": p["occurrences"],
            "sessions": len(p["sessions"]), "example_sessions": sorted(p["sessions"])[:3],
            "stages": stage_map(p), "roles": role_map(p), "tokens": p["tokens"], "cost_wp": p["cost_wp"],
            "share": p["share"], "rank": p["rank"], "bracket_sensitive": p["bracket_sensitive"],
            "current_rung": p["current"], "suggested_rung": p["suggested"], "triggers": p["triggers"],
            "routable": p["routable"]}


coverage = dict(cov)
coverage["format_health"] = {"unreadable_bash_calls": unreadable, "rate": float(rate), "status": health,
                             "warn_above": float(FORMAT_WARN), "fatal_above": float(FORMAT_FATAL)}
coverage["cost_bound_violations"] = dict(bounds, threshold=float(COST_BOUND_THRESHOLD))
coverage["stage_basis"] = dict(sorted(res["stage_basis"].items()))
coverage["residuals"] = ["a tool_use id whose first copy predates the window counts as fresh",
                         "the window selects files by mtime, so a long-lived file contributes older calls"]
if SELFTEST:
    coverage["per_file"] = res["per_file"]
    coverage["selftest"] = {"trace": TR.out(), "canon_equal": bool(CANON_EQ) and all(CANON_EQ),
                            "sessions": res["sessions"], "live_record_files_max": res["live_max"],
                            "vocabulary": {"words": sorted(COMMANDS | KEYWORDS | set().union(*SUBCOMMANDS.values())),
                                           "flags": sorted(set().union(*FLAGS.values()))}}
window_wp = {e: pairs[0][e] for e in ENDS} if pairs is not None else "unresolved"
doc = {"schema": "rank-command-templates.candidates", "schema_version": "1.0.0",
       "run": {"name": E["RANK_RUN_NAME"], "created": created, "window_days": days, "files": cov["files"],
               "sessions": session_count, "work_item": E["RANK_WORK_ITEM"]},
       "cost": {"unit": cost_unit, "status": status, "calibration_label": label, "params_source": params_source,
                "chars_per_token": "1.5", "window_total_wp": window_wp},
       "controls": {"canary": "pass", "format_health": health},
       "coverage": coverage, "candidates": [cand(p) for p in order]}
with open(os.path.join(stg, "candidates.json"), "w", encoding="utf-8") as fh:
    json.dump(doc, fh, ensure_ascii=False, indent=1, sort_keys=True)
    fh.write("\n")

records = []
for p in chosen:
    records.append({
        "schema": "rank-command-templates.mode-c-signal", "schema_version": "1.0.0", "candidate_id": p["id"],
        "implied_type": "improvement",
        "signal": {"what_is_missing": "No tracked script covers a mechanical %s procedure (%d commands, %d variants) "
                                      "retyped in %d sessions (stages %s) over the last %d days; candidate %s."
                                      % (family(p), len(p["contribs"]), len(p["variants"]), len(p["sessions"]),
                                         ", ".join(stage_map(p)), days, p["id"]),
                   "what_good_looks_like": "The procedure is evaluated against the promotion framework's §1 "
                                           "triggers and, if promoted, lands at rung %s with its discovery anchor, "
                                           "so agents invoke it instead of retyping it." % p["suggested"],
                   "affected_file": "core/standards/agent-script-promotion-framework.md"},
        "class": "efficiency — not user-visible (filing threshold §2)", "severity": "Minor",
        "reading_basis": "ranker constant (D-Threshold)", "dedupe_terms": [p["id"], "promotion candidate"],
        "evidence": {"occurrences": p["occurrences"], "sessions": len(p["sessions"]), "stages": stage_map(p),
                     "cost_wp": p["cost_wp"], "share": p["share"], "calibration_label": label,
                     "suggested_rung": p["suggested"], "triggers": p["triggers"]},
        "local_report": E["RANK_LOCAL_REPORT"]})
with open(os.path.join(stg, "mode-c-signals.json"), "w", encoding="utf-8") as fh:
    json.dump(records, fh, ensure_ascii=False, indent=1, sort_keys=True)
    fh.write("\n")


def cell(s):
    return str(s).replace("|", "\\|")


L = ["---", "analysis_type: audit", 'work_item: "%s"' % E["RANK_WORK_ITEM"], "created: %s" % created,
     "sunset: %s" % sunset, "status: active", "---", "",
     "# Command-template ranking — %s" % created, "",
     "- **Run:** a %d-day window · %d transcript files · %d sessions · %d tool calls · %d procedures ranked (at "
     "least %d sessions each) · top %d shown · %d Mode C records prepared" % (
         days, cov["files"], session_count, cov["tool_calls"], len(elig), MIN_SESSIONS, int(E["RANK_TOP"]),
         len(records)),
     "- **Cost:** %s · `%s` · status **%s** · tokens estimated from characters at 1.5 per token" % (
         cost_unit, label, status),
     "- **Controls:** runtime canary pass (the control ranks in 3 sessions; both near-misses stay below the floor) "
     "· format health %s (%.2f %% of Bash calls unreadable)" % (health, float(rate) * 100),
     "- **Coverage:** copied tool_use ids %d · duplicate blocks within a response %d · unparsed %d · lost tokens %d "
     "· comment lines %d · unknown command words %d · cost-bound violations: %d responses, %d of %d segments "
     "(%d clamped) · stage basis %s" % (
         cov["copied_tool_use_ids"], cov["duplicate_blocks_within_response"], cov["unparsed"], cov["lost_tokens"],
         cov["comment_lines"], cov["unknown_command_words"], bounds["responses_over"], bounds["segments_over"],
         bounds["segments_checked"], bounds["segments_clamped"],
         ", ".join("%s %d" % kv for kv in sorted(res["stage_basis"].items()))),
     "- No transcript text is written: a token reaches this report only through the closed vocabulary. The rung "
     "is suggested, never decided; T-DET, T-VAR and T-RISK are not evaluated (framework §1).", "",
     "## Top procedures", "",
     "| id | procedure | sessions | occurrences | variants | stages | roles | share (at_w_low · at_w_high) "
     "| wp (at_w_low · at_w_high) | rung (current → suggested) | bracket |",
     "|---|---|---|---|---|---|---|---|---|---|---|"]
for p in [p for p in order if p["kind"] in ("bash", "write-script")][:int(E["RANK_TOP"])]:
    L.append("| %s | `%s` | %d | %d | %d | %s | %s | %s | %s | %s → %s | %s |" % (
        p["id"], cell(p["key"]), len(p["sessions"]), p["occurrences"], len(p["variants"]),
        " ".join("%s:%d" % kv for kv in stage_map(p).items()),
        " ".join("%s:%d" % kv for kv in role_map(p).items()), fmt_share(p["share"]),
        fmt_pair(p["cost_wp"]), p["current"], p["suggested"],
        "bracket-sensitive" if p["bracket_sensitive"] else "stable"))
L += ["", "## Context patterns", "", "| id | pattern | sessions | occurrences | share (at_w_low · at_w_high) |",
      "|---|---|---|---|---|"]
for p in [p for p in order if p["kind"] not in ("bash", "write-script")][:int(E["RANK_TOP"])]:
    L.append("| %s | `%s` | %d | %d | %s |" % (p["id"], cell(p["key"]), len(p["sessions"]), p["occurrences"],
                                              fmt_share(p["share"])))
L += ["", "## Signals prepared for intake", ""]
L += ["- %s — family `%s`, suggested rung %s" % (p["id"], family(p), p["suggested"]) for p in chosen] or \
     ["- none (the cost is unresolved, or no routable procedure ranked)"]
L += ["", "## Routing outcomes", "",
      "The invoking agent hands each record in `mode-c-signals.json` to `intake-desk` Mode C and records the verdict "
      "Mode C returns in the last column. Every record is expected to be held below the filing threshold; a row "
      "still pending, or a verdict other than the expected one, is a failed hand-off.", "",
      "| id | expected Mode C verdict | returned verdict |", "|---|---|---|"]
L += ["| %s | signal recorded, held — below the filing threshold | pending |" % p["id"] for p in chosen]
with open(os.path.join(stg, "SUMMARY.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(L) + "\n")

print(json.dumps({"eligible": len(elig), "records": len(records), "status": status, "label": label}))
sys.exit(10 if pairs is None else 0)
PYEOF
  rc=$?
  case "$rc" in
    0|10) ;;
    3) exit 3 ;;
    *) die "FATAL (exit 3): the ranking core failed (exit $rc); nothing written" 3 ;;
  esac
  local f out prc hits=0
  for f in "$staging/SUMMARY.md" "$staging/candidates.json" "$staging/mode-c-signals.json"; do
    out="$(bash "$CHECKOUT/core/deploy/tools/path-leak-patterns.sh" --scan-file "$f" 2>/dev/null)"; prc=$?
    if [ "$prc" -eq 1 ]; then
      hits=$((hits + $(printf '%s\n' "$out" | grep -c .)))
    elif [ "$prc" -ne 0 ]; then
      die "FATAL (exit 3): the path-leak scan could not read a rendered file; nothing written" 3
    fi
  done
  [ "$hits" -eq 0 ] || die "FATAL (exit 3): the rendered report carries $hits line(s) of a path-leak class; nothing written" 3
  mkdir "$run" 2>/dev/null || die "FATAL (exit 3): the run folder appeared during the run; nothing written" 3
  for f in SUMMARY.md candidates.json mode-c-signals.json; do mv "$staging/$f" "$run/$f"; done
  printf 'rank-command-templates: %s eligible procedures, %s Mode C records prepared, cost %s (%s) — report %s\n' \
    "$(jq -r '.eligible' "$work/core.json")" "$(jq -r '.records' "$work/core.json")" \
    "$(jq -r '.status' "$work/core.json")" "$(jq -r '.label' "$work/core.json")" "$local_report"
  [ "$rc" -eq 0 ] || exit 3
  exit 0
}

# ─── Self-test (offline: committed fixtures, a sandboxed HOME, temporary roots) ──
# The leak table (FM-1): literal · the masking class that must consume it · the procedure
# it sits in (@control is the control procedure) · whether that procedure ranks. Each row is asserted three ways: the literal is
# in the staged input (sensitivity), the renderer consumed it through the declared class
# inside the declared procedure (the trace), and no written or printed byte carries it.
LEAK_TABLE='fixtureuser	path	@control	yes
otherfixture	path	@control	yes
agent-zz	path	@control	yes
synthetic-owner	slug	@control	yes
synthetic-repo	slug	@control	yes
other-owner	slug	@control	yes
fixtureleakfield	default	@control	yes
fixturejqfield	code	@control	yes
fixture-codename	flag	git status	yes
fixture-interp-flag	interpreter-flag	bash core/skills/finops-usage-extractor/scripts/report-usage.sh	yes
FIXTURE_SECRET_VALUE	heredoc	python3 <HEREDOC>	yes
FIXTURE_HUB_SECRET	heredoc	python3 <HEREDOC>	yes
fixturecommentword	comment	git status	yes
FIXTURE_ARR	var	echo ; git log	yes
fixturecommitword	var	git commit	yes
fixturecmdword	command	curl | <CMD>	yes
fixtureurlhost	url	curl | <CMD>	yes
fixtureglobword	glob	curl | <CMD>	yes
fixturestrword	tool-input	Grep{pattern:<STR>}	yes
Fixture Person	default	printf	no
fixture-once	path	printf	no
fixture-milestone-slug	tool-input	Agent{description:<STR>,prompt:<STR>,subagent_type:<STR>}	no'
# The classes the leak arm requires a ranking literal for: every class that renders a token of a
# Bash command or a harness-tool value. Not required, so not proven by the arm: the whole-shape
# classes (<N>, <SHA>, <UUID>, <UNPARSED>) and the tool-name, MCP and <KEY> classes.
REQUIRED_CLASSES="path slug default code flag interpreter-flag heredoc comment var command url glob tool-input"

RANK_ST_TMP=""
self_test() {
  preflight_deps
  local T fail=0 rc
  RANK_ST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/rank-command-templates-selftest-XXXXXX")" || die "self-test: mktemp failed" 1
  trap 'rm -rf "$RANK_ST_TMP"' EXIT
  T="$RANK_ST_TMP"
  ok()  { printf 'PASS: %s\n' "$1"; }
  bad() { printf 'FAIL: %s\n' "$1"; fail=1; }
  mkdir -p "$T/home" "$T/cfg" "$T/src" "$T/out" "$T/bound" "$T/fmt" "$T/home2/.config/pmo-platform" "$T/ws/pmo-platform/analysis"
  stage_fixtures() {  # stage_fixtures <fixture subdir> <root>: *.jsonl.fixture staged as *.jsonl
    local rel
    while IFS= read -r rel; do
      mkdir -p "$2/$(dirname "$rel")"
      cp "$FIXTURES_DIR/$1/$rel" "$2/${rel%.fixture}"
    done < <(cd "$FIXTURES_DIR/$1" && find . -type f -name '*.jsonl.fixture')
  }
  stage_fixtures sessions "$T/src"
  stage_fixtures bound "$T/bound"
  local trace_json
  trace_json="$(printf '%s\n' "$LEAK_TABLE" | jq -R -s -c 'split("\n") | map(select(length > 0) | split("\t")[0])')"
  child() {  # child <tag> <source-root> [args...]: one hermetic run; stdout, stderr and rc kept
    local tag="$1" src="$2"; shift 2
    env -u WORKSPACE_ROOT -u CLAUDE_WORKSPACE_ROOT RANK_SELFTEST=1 RANK_TRACE="$trace_json" \
      RANK_CONVERTER="${STUB_CONVERTER:-}" \
      HOME="$T/home" PMO_PLATFORM_CONFIG_ROOT="$T/cfg" FINOPS_SOURCE_ROOT="$src" \
      bash "$SELF" "$@" > "$T/$tag.stdout" 2> "$T/$tag.stderr"
    echo $? > "$T/$tag.rc"
  }
  child main "$T/src" --out-dir "$T/out" --signals 2 --work-item "selftest"
  local runs=("$T"/out/command-template-ranking-*)
  local R1="${runs[0]}"
  local CAND="$R1/candidates.json" SIG="$R1/mode-c-signals.json" SUM="$R1/SUMMARY.md"
  if [ "$(cat "$T/main.rc")" != "0" ] || [ ! -s "$CAND" ] || [ ! -s "$SUM" ] || [ ! -f "$SIG" ]; then
    bad "main run: rc $(cat "$T/main.rc"), report incomplete — stderr follows"
    sed -n '1,40p' "$T/main.stderr"
    echo "rank-command-templates --self-test: FAIL"
    return 1
  fi
  local ctl='cd && gh issue view | head'
  q() { jq -r --arg k "$1" "$2" "$CAND"; }  # q <procedure> <jq over the candidate>
  pick='[.candidates[] | select(.procedure == $k)]'

  # 1 — control arm: the known-repeated procedure ranks, with its two masked variants.
  local re='^cd <PATH> && gh issue view <N> (--repo <SLUG> --json <ARG> --jq <CODE>|--json <ARG> --jq <CODE> --repo <SLUG>) [|] head -<N>$'
  if [ "$(q "$ctl" "$pick | .[0] | \"\(.sessions) \(.occurrences) \(.variants | length)\"")" = "3 3 2" ] \
     && [ "$(jq -r --arg k "$ctl" --arg re "$re" "$pick | .[0].variants | keys | map(select(test(\$re) | not)) | length" "$CAND")" = "0" ]; then
    ok "control arm (3 sessions, 3 occurrences, 2 variants of the masked shape)"
  else bad "control arm: got $(q "$ctl" "$pick | .[0] | {sessions, occurrences, variants}" | tr '\n' ' ')"; fi
  # 2, 3 — near-miss arms: a once-only command and a one-session repeat never rank.
  if [ "$(q printf "$pick | length")" = "0" ]; then ok "near-miss arm (once)"; else bad "near-miss arm (once): the once-only printf procedure ranked"; fi
  if [ "$(q 'sleep && gh run list' "$pick | length")" = "0" ]; then ok "near-miss arm (single session)"
  else bad "near-miss arm (single session): a one-session repeat ranked"; fi
  # 4 — copied-history arm.
  if [ "$(jq '.coverage.copied_tool_use_ids' "$CAND")" = "1" ] && [ "$(q printf "$pick | length")" = "0" ]; then
    ok "copied-history arm (one copied id dropped; the once-only command stays below the floor)"
  else bad "copied-history arm: copied_tool_use_ids $(jq '.coverage.copied_tool_use_ids' "$CAND")"; fi
  # 5 — dedupe arm: A holds 8 responses and 7 calls; one block repeated within a response.
  if [ "$(jq -c '[.coverage.duplicate_blocks_within_response, .coverage.per_file["00000000-0000-4000-8000-0000000000a1"]]' "$CAND")" = '[1,[8,7]]' ]; then
    ok "dedupe arm"; else bad "dedupe arm: got $(jq -c '[.coverage.duplicate_blocks_within_response, .coverage.per_file]' "$CAND")"; fi

  # 6 — leak arm (FM-1): sensitivity per literal, the class trace per row, absence in every byte.
  local i=0 lit cls proc el seen leaks=0 vac=0 trace_bad=0 covered=" "
  while IFS="$(printf '\t')" read -r lit cls proc el; do
    [ -n "$lit" ] || continue
    [ "$proc" = "@control" ] && proc="$ctl"
    if [ -z "$(grep -r -F -l -- "$lit" "$T/src")" ]; then vac=$((vac + 1)); printf '  vacuous row %d (%s)\n' "$i" "$cls"; fi
    seen="$(jq -r --arg i "$i" --arg c "$cls" --arg p "$proc" '(.coverage.selftest.trace[$i] // []) | map(select(.[0] == $c and .[1] == $p)) | length' "$CAND")"
    if [ "$seen" = "0" ]; then trace_bad=$((trace_bad + 1)); printf '  row %d: not consumed by the %s class inside its procedure\n' "$i" "$cls"; fi
    if [ "$el" = "yes" ]; then
      if [ "$(q "$proc" "$pick | length")" = "1" ]; then covered="$covered$cls "
      else trace_bad=$((trace_bad + 1)); printf '  row %d: its procedure does not rank\n' "$i"; fi
    fi
    if [ -n "$(grep -r -F -l -- "$lit" "$T/out" "$T/main.stdout" "$T/main.stderr")" ]; then
      leaks=$((leaks + 1)); printf '  row %d (%s class) reached written or printed output\n' "$i" "$cls"
    fi
    i=$((i + 1))
  done <<EOF
$LEAK_TABLE
EOF
  local missing_cls="" c
  for c in $REQUIRED_CLASSES; do case "$covered" in *" $c "*) ;; *) missing_cls="$missing_cls $c" ;; esac; done
  if [ "$vac" -gt 0 ] || [ -n "$missing_cls" ]; then bad "leak arm is vacuous: $vac literal(s) absent from the input; classes without a ranking literal:${missing_cls:- none}"
  elif [ "$leaks" -gt 0 ] || [ "$trace_bad" -gt 0 ]; then bad "leak arm: $leaks literal(s) leaked; $trace_bad row(s) off their declared class or procedure"
  else ok "leak arm ($i literals, each in the input, each consumed by its class, none written; every required class has a ranking literal)"; fi

  # 7 — parity arm: per file, responses and calls equal the extractor's turns and tool calls.
  if STORE="$T/store" FINOPS_SOURCE_ROOT="$T/src" HOME="$T/home" bash "$SCRIPT_DIR/extract-usage.sh" --rebuild > "$T/x.out" 2>&1 \
     && [ "$(jq -s -c --slurpfile c "$CAND" '
          (map(select(.record == "session") | {(.session_id): [.turns, ([.tool_calls[]] | add // 0)]}) | add) as $x
          | ($c[0].coverage.per_file) as $r | ($x == $r) and (($r | length) == 5)' "$T/store/usage.jsonl")" = "true" ]; then
    ok "parity arm (5 files: responses and calls equal the extractor's turns and tool calls)"
  else bad "parity arm: the ranker's per-file counts differ from the extractor's"; fi
  # 8 — conversion arm: the control's pair is convert-usage.sh's own, and its shares lie in (0, 1].
  local tok conv_out
  tok="$(q "$ctl" "$pick | .[0].tokens" | jq -c '[.]')"
  conv_out="$(printf '%s' "$tok" | HOME="$T/home" PMO_PLATFORM_CONFIG_ROOT="$T/cfg" bash "$SCRIPT_DIR/convert-usage.sh" --convert | jq -c '.pairs[0] | {at_w_low, at_w_high}')"
  if [ -n "$conv_out" ] && [ "$(q "$ctl" "$pick | .[0].cost_wp" | jq -c '{at_w_low, at_w_high}')" = "$conv_out" ] \
     && [ "$(q "$ctl" "$pick | .[0].share | [.at_w_low, .at_w_high] | all(. > 0 and . <= 1)")" = "true" ]; then
    ok "conversion arm (the pair is the one conversion's; shares at both ends in (0, 1])"
  else bad "conversion arm: cost_wp $(q "$ctl" "$pick | .[0].cost_wp" | tr '\n' ' ') vs conversion $conv_out"; fi
  # 9 — fail-closed arm: a failing conversion writes the report with its cost unresolved, no records.
  printf '#!/usr/bin/env bash\nexit 3\n' > "$T/stub.sh"
  STUB_CONVERTER="$T/stub.sh"
  child fail "$T/src" --out-dir "$T/out9"
  STUB_CONVERTER=""
  local f9=("$T"/out9/command-template-ranking-*)
  if [ "$(cat "$T/fail.rc")" = "3" ] && [ "$(jq -r '.cost.status' "${f9[0]}/candidates.json")" = "unresolved" ] \
     && [ "$(jq '[.candidates[].cost_wp | select(. != "unresolved")] | length' "${f9[0]}/candidates.json")" = "0" ] \
     && [ "$(jq 'length' "${f9[0]}/mode-c-signals.json")" = "0" ]; then
    ok "fail-closed arm (exit 3, cost unresolved, no numeric figure, no record)"
  else bad "fail-closed arm: rc $(cat "$T/fail.rc")"; fi
  # 10 — guard arm: a run folder inside a repository but not ignored is refused, nothing written.
  git init -q "$T/repo" 2>/dev/null
  child guard "$T/src" --out-dir "$T/repo/out"
  local g10=("$T"/repo/out/*)
  if [ "$(cat "$T/guard.rc")" = "4" ] && [ ! -e "${g10[0]}" ]; then ok "guard arm (exit 4, nothing written)"
  else bad "guard arm: rc $(cat "$T/guard.rc")"; fi
  # 11 — compaction arm: file A's boundary splits its segments.
  if [ "$(jq '.coverage.compaction_boundaries' "$CAND")" = "1" ]; then ok "compaction arm"
  else bad "compaction arm: boundaries $(jq '.coverage.compaction_boundaries' "$CAND")"; fi
  # 12 — stage arm (FM-3): rules 1 and 3, a hub carries no stage, nested and workflow roles.
  if [ "$(jq -c '.coverage.selftest.sessions | [.["00000000-0000-4000-8000-0000000000a1"], .["00000000-0000-4000-8000-0000000000b2"], .["agent-0000000000000a1c3"], .["00000000-0000-4000-8000-0000000000d4"], .["agent-00000000000000d4e5"]]' "$CAND")" \
       = '[["main","6"],["main","unstaged"],["nested","7"],["hub","hub"],["workflow-agent","unstaged"]]' ] \
     && [ "$(q "$ctl" "$pick | .[0] | [.stages, .roles]" | jq -c .)" = '[{"6":1,"7":1,"unstaged":1},{"main":2,"nested":1}]' ]; then
    ok "stage arm (A 6, B unstaged, C 7 nested, the hub D carries no stage, E is a workflow agent)"
  else bad "stage arm: got $(jq -c '.coverage.selftest.sessions' "$CAND")"; fi
  # 13 — rung arm.
  local rungs
  rungs="$(jq -c --arg c "$ctl" '[.candidates[] | select(.procedure == $c or .procedure == "git status" or .procedure == "Write <PATH>.py <CODE>" or .procedure == "bash core/skills/finops-usage-extractor/scripts/report-usage.sh") | [.procedure, .suggested_rung, .routable]] | sort' "$CAND")"
  if [ "$rungs" = '[["Write <PATH>.py <CODE>","AS2",true],["bash core/skills/finops-usage-extractor/scripts/report-usage.sh","none — already a tracked tool",false],["cd && gh issue view | head","AS2",true],["git status","AS1",true]]' ]; then
    ok "rung arm"; else bad "rung arm: got $rungs"; fi
  # 14 — signals arm: exactly --signals records, routable only, abstract only.
  local ids_ok
  ids_ok="$(jq -r --slurpfile c "$CAND" '[.[].candidate_id] as $ids | ($c[0].candidates | map(select(.routable)) | map(.id)) as $r | all($ids[]; . as $x | $r | index($x))' "$SIG")"
  if [ "$(jq 'length' "$SIG")" = "2" ] && [ "$ids_ok" = "true" ] \
     && [ "$(jq '[.[] | select(has("release_context") or (has("candidate_id") and has("signal") and has("class") and has("severity") and has("evidence") and has("local_report") | not))] | length' "$SIG")" = "0" ] \
     && [ "$(grep -c -E '<(PATH|ARG|SLUG|FLAG|CMD)>|<CODE|<HEREDOC|00000000-0000' "$SIG")" = "0" ] \
     && [ "$(jq -r '[.candidates[].procedure] | .[]' "$CAND" | grep -c -F -f - "$SIG")" = "0" ]; then
    ok "signals arm (exactly 2 records with --signals 2; routable; no procedure, variant, path or stem)"
  else bad "signals arm: $(jq 'length' "$SIG") records"; fi
  # 15 — vocabulary arm: the block's text matches its pinned digest; every word is plain.
  local dig
  dig="$(sed -n '/^# >>> PRIVACY-RELEVANT VOCABULARY/,/^# <<< PRIVACY-RELEVANT VOCABULARY/p' "$SELF" | python3 -I -c 'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())')"
  if [ "$dig" = "$VOCAB_DIGEST" ] \
     && [ "$(jq '[.coverage.selftest.vocabulary.words[] | select(test("^[a-z0-9.!{}\\[\\]][a-z0-9._+\\[\\]-]*$") | not)] | length' "$CAND")" = "0" ] \
     && [ "$(jq '[.coverage.selftest.vocabulary.flags[] | select(test("^--?[A-Za-z0-9][A-Za-z0-9-]*$") | not)] | length' "$CAND")" = "0" ]; then
    ok "vocabulary arm (digest pinned; every word and flag plain)"
  else bad "vocabulary arm: the block's digest is $dig, the pinned digest is $VOCAB_DIGEST — an edit to the vocabulary is a privacy change: review it, then repin"; fi
  # 16 — cost arm (CD-2): the control's tokens equal the values hand-computed in test-fixtures/rank/README.md.
  local want='{"cache_creation":{"ephemeral_1h":91,"ephemeral_5m":273,"total":364},"cache_read":1456,"input":0,"output":325}'
  if [ "$(q "$ctl" "$pick | .[0].tokens" | jq -c -S .)" = "$want" ]; then ok "cost arm (output 325, cache write 364 = 91 + 273, cache read 1456)"
  else bad "cost arm: got $(q "$ctl" "$pick | .[0].tokens" | jq -c -S .)"; fi
  # 17 — bound arm (CD-2): attributed figures never exceed measured usage; a violation degrades and clamps.
  child bound "$T/bound" --out-dir "$T/outb"
  local fb=("$T"/outb/command-template-ranking-*)
  if [ "$(jq -c '[.cost.status, .coverage.cost_bound_violations.segments_over, .coverage.cost_bound_violations.segments_clamped, (.coverage.cost_bound_violations.responses_over > 0)]' "${fb[0]}/candidates.json")" = '["degraded",1,1,true]' ] \
     && [ "$(jq -c '[.cost.status, .coverage.cost_bound_violations.segments_over]' "$CAND")" = '["ok",0]' ]; then
    ok "bound arm (the planted segment degrades and clamps; the fixture window stays ok)"
  else bad "bound arm: got $(jq -c '[.cost.status, .coverage.cost_bound_violations]' "${fb[0]}/candidates.json")"; fi
  # 18 — routing arm (CD-3): one Routing-outcomes row per record, each expecting the label Mode C
  #      returns below the filing threshold (intake-desk § The filing threshold), word for word.
  local rows ids
  sed -n '/^## Routing outcomes/,$p' "$SUM" > "$T/routing.md"
  rows="$(grep -c -E '^\| TPL-[0-9a-f]{10} \| signal recorded, held — below the filing threshold \| pending \|$' "$T/routing.md")"
  ids="$(jq -r '.[].candidate_id' "$SIG" | grep -c -F -f - "$T/routing.md")"
  if [ "$rows" = "$(jq 'length' "$SIG")" ] && [ "$rows" -ge 1 ] && [ "$ids" = "$rows" ]; then ok "routing arm ($rows rows, one per record)"
  else bad "routing arm: $rows rows for $(jq 'length' "$SIG") records"; fi
  # 19 — collision arm (CD-3): a same-day re-run takes a new folder and leaves the first untouched.
  local before after
  before="$(python3 -I -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$SUM")"
  child again "$T/src" --out-dir "$T/out" --signals 2
  runs=("$T"/out/command-template-ranking-*)
  after="$(python3 -I -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$SUM")"
  if [ "$(cat "$T/again.rc")" = "0" ] && [ "${#runs[@]}" = "2" ] && [ "$before" = "$after" ]; then ok "collision arm (a second folder; the first SUMMARY.md unchanged)"
  else bad "collision arm: ${#runs[@]} folders, rc $(cat "$T/again.rc")"; fi
  # 20 — canonicalizer arm (CD-4): a batch (one awk process per file) equals one process per command;
  #      a loop keys on its body.
  if [ "$(jq '.coverage.selftest.canon_equal' "$CAND")" = "true" ] && [ "$(q 'for ; wc' "$pick | .[0].sessions")" = "2" ]; then
    ok "canonicalizer arm (batch output equals per-command output; the loop keys on its command)"
  else bad "canonicalizer arm: canon_equal $(jq '.coverage.selftest.canon_equal' "$CAND"), for-loop sessions $(q 'for ; wc' "$pick | .[0].sessions")"; fi
  # 21 — comment arm (FM-2): a comment line and ${#…} lose nothing.
  if [ "$(q 'git status' "$pick | .[0].sessions")" = "2" ] && [ "$(q 'echo ; git log' "$pick | .[0].sessions")" = "2" ] \
     && [ "$(q echo "$pick | length")" = "0" ] && [ "$(jq '.coverage.lost_tokens' "$CAND")" = "0" ] \
     && [ "$(jq '.coverage.comment_lines >= 1' "$CAND")" = "true" ]; then
    ok "comment arm (a comment line and \${#…} keep the commands after them; lost tokens 0)"
  else bad "comment arm: git status $(q 'git status' "$pick | .[0].sessions"), echo-and-log $(q 'echo ; git log' "$pick | .[0].sessions")"; fi
  # 21b — substitution arm: a heredoc inside $( … ), the commit-message idiom, with an apostrophe
  #       in its body, keeps its command and parses (the body is skipped, never read as a quote).
  if [ "$(q 'git commit' "$pick | .[0].sessions")" = "2" ] && [ "$(jq '.coverage.unparsed' "$CAND")" = "0" ]; then
    ok "substitution arm (the commit-message heredoc inside a substitution ranks; unparsed 0)"
  else bad "substitution arm: git commit sessions $(q 'git commit' "$pick | .[0].sessions"), unparsed $(jq '.coverage.unparsed' "$CAND")"; fi
  # 22 — format-health arm (FM-5, a mutation probe): rename the command key; exit 3, nothing written.
  local frel
  while IFS= read -r frel; do
    mkdir -p "$T/fmt/$(dirname "$frel")"
    sed 's/"command":/"cmd":/g' "$T/src/$frel" > "$T/fmt/$frel"
  done < <(cd "$T/src" && find . -type f -name '*.jsonl')
  child fmt "$T/fmt" --out-dir "$T/outf"
  local ff=("$T"/outf/command-template-ranking-*)
  if [ "$(cat "$T/fmt.rc")" = "3" ] && [ "$(grep -c 'format health' "$T/fmt.stderr")" -ge 1 ] && [ ! -e "${ff[0]}" ]; then
    ok "format-health arm (a renamed command key exits 3; nothing written)"
  else bad "format-health arm: rc $(cat "$T/fmt.rc")"; fi
  # 23 — root arm (FM-4): a workspace root set only in operator.toml places the default report under it.
  printf 'claude_workspace_root = "%s"\n' "$T/ws" > "$T/home2/.config/pmo-platform/operator.toml"
  env -u WORKSPACE_ROOT -u CLAUDE_WORKSPACE_ROOT RANK_SELFTEST=1 HOME="$T/home2" PMO_PLATFORM_CONFIG_ROOT="$T/cfg" \
    FINOPS_SOURCE_ROOT="$T/src" bash "$SELF" > "$T/root.stdout" 2> "$T/root.stderr"
  rc=$?
  local fr=("$T"/ws/pmo-platform/analysis/command-template-ranking-*)
  if [ "$rc" = "0" ] && [ -s "${fr[0]}/SUMMARY.md" ] && [ "$(grep -c -F '<OPERATOR_INSTANCE_ANALYSIS_PATH>/command-template-ranking-' "$T/root.stdout")" = "1" ]; then
    ok "root arm (the toml root, env unset: the report lands under its analysis home; the line is in token form)"
  else bad "root arm: rc $rc"; sed -n '1,5p' "$T/root.stderr"; fi

  # 24 — memory arm (F-01): the ranker holds one transcript file's records at a time. Every file's
  #      record list is weakly referenced as it is read, and the most alive at once, over the five
  #      fixture files of the window, must be exactly 1. CI probe P5 keeps each file alive and
  #      turns this arm red.
  if [ "$(jq -c '[.run.files, .coverage.selftest.live_record_files_max]' "$CAND")" = '[5,1]' ]; then
    ok "memory arm (5 files read; at most 1 file's records alive at once)"
  else bad "memory arm: [files, most alive at once] = $(jq -c '[.run.files, .coverage.selftest.live_record_files_max]' "$CAND"), want [5,1]"; fi

  if [ "$fail" -eq 0 ]; then echo "rank-command-templates --self-test: PASS"; return 0; fi
  echo "rank-command-templates --self-test: FAIL"
  return 1
}

case "${1:-}" in
  --self-test) self_test; exit $? ;;
  --help|-h)   usage ;;
  *)           run_main "$@" ;;
esac
