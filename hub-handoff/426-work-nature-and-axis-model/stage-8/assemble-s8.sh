#!/usr/bin/env bash
# Render the Stage-8 hub brief (two files) from this package's parts.
# usage: assemble-s8.sh <out-dir> <head-sha> "<Stage-7 comment ids, e.g. 5862203943 and the pass-2 comment>"
# The out-dir should be the hub's scratch dir for this launch; the spoke reads both files from there.
set -euo pipefail
P="$(cd "$(dirname "$0")" && pwd)"; OUT="$1"; HEAD_SHA="$2"; S7="$3"; mkdir -p "$OUT"
{ cat "$P/brief-s8-head.md"; cat "$P/persona-s8.md"; cat "$P/brief-s8-task1.md"; echo; cat "$P/s8-ro.md"; echo;
cat <<'EOF'
Worktree: you are launched in an isolated session worktree. Detect first with
`git rev-parse --show-toplevel`. Operate in it directly; never create a nested worktree,
never `cd` to another checkout, and never touch the primary checkout (the first entry of
`git worktree list`). The detached checkout described in Part 2 is the only change you make
to your worktree: write no repository files and commit nothing.

EOF
cat "$P/s8-disc.md"; echo; cat "$P/brief-s8-tail.md"; cat "$P/s8-scope2.md";
cat <<'EOF'
## Session Start Checklist
Before executing the task, verify:
1. Parent issue #7959 is OPEN.
2. Sub-task #7974 is OPEN and does not carry a
   prior blocker comment.
3. `spawn_task` is NOT called from within this spoke (no
   recursive spawning).
EOF
} > "$OUT/brief-s8.tmp"
python3 - "$P" "$OUT" "$HEAD_SHA" "$S7" <<'EOF'
import sys
P,OUT,h,s7=sys.argv[1:5]
dev10='\n'.join(open(f'{P}/dev10-s8.md').read().rstrip('\n').split('\n')[2:])
dev10=dev10.replace('- (d) Count a criterion that fits no nature under the candidate it matches. An item whose majority is a candidate fits no nature.\n','')
for src,dst in ((f'{OUT}/brief-s8.tmp',f'{OUT}/brief-s8.md'),(f'{P}/brief-s8-part2.src.md',f'{OUT}/brief-s8-part2.md')):
    t=open(src).read()
    t=t.replace('{{CODEBOOK}}',open(f'{P}/codebook-s8.md').read().rstrip('\n')).replace('{{DEV10}}',dev10)
    t=t.replace('{{HEAD}}',h).replace('{{S7_COMMENTS}}',s7).replace('{{PART2_PATH}}',f'{OUT}/brief-s8-part2.md')
    assert '{{' not in t, ('unfilled placeholder in',src)
    open(dst,'w').write(t)
EOF
rm -f "$OUT/brief-s8.tmp"; wc -c "$OUT/brief-s8.md" "$OUT/brief-s8-part2.md"
