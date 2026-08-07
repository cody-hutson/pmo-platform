#!/usr/bin/env bash
# audit-epic-rollup-close.sh — Epic rollup-close detective audit (report-only)
#
# Surfaces open `type:epic` issues whose entire child set has reached a COMPLETED
# terminal state, so an operator can decide whether the epic should close. GitHub
# does not close a parent when its last child closes, and no close-out step revisits
# a closed issue's parent — so a delivered epic stays open indefinitely.
#
# WHY AN AUDIT AND NOT A GATE. `core/specs/label-taxonomy.md` exempts `type:epic`
# from the status-label invariant: an epic is a container / grouping tier, not a
# lifecycle work item, so it has no lifecycle position of its own and its children
# carry the state. That exemption is the root cause of the gap — an epic is
# structurally invisible to every lifecycle mechanism that would otherwise surface
# it — and it also settles the authority question. A gate cannot assert on a field
# governance explicitly exempts, so this surface reports and never blocks.
#
# THE THREE GATES, SPLIT BY DECIDABILITY. The manual rubric is a 3-gate check:
# children Done, AND the issue is a true epic (not an initiative container), AND
# the parent's own body scope actually shipped. Only the first is mechanically
# decidable. Gate 2 was probed twice against label topology and both predicates
# over-matched (14 of 15), the narrower one also returning a false negative,
# because `project:*` sits on the container AND on every child — container and
# thrust are label-identical by construction. So:
#
#   G1a  all children closed (native sub-issues UNION `epic:<slug>` labels)  FILTER
#   G1b  any child closed NOT_PLANNED ("closed" != "Done")            FLAG, retain
#   G1c  child set is entirely `type:spike` (research answered !=
#        capability shipped)                                          FLAG, retain
#   G1d  zero children — rollup signal UNDEFINED, not satisfied              EXCLUDE
#   G2   true epic, or initiative mislabelled as one?             ANNOTATE, never decide
#   G3   has the parent's own body scope shipped?                 ANNOTATE, never decide
#
# G2/G3 evidence is rendered BEFORE the G1 verdict so the reader meets the tier
# question first. The audit renders NO close verdict on any gate; the output is a
# ranked candidate list and the operator dispositions it.
#
# DUAL-MECHANISM READ IS MANDATORY. The `epic:<slug>` label and the native
# sub-issue graph are not kept in sync, so a native-only read closes epics that
# still have open label-linked work. Both are read and unioned. The carrier epic
# self-labels (the taxonomy applies `epic:<slug>` to the umbrella ticket AND its
# children), so the carrier is excluded from its own child set — without that
# guard an epic is its own perpetually-open child and can never satisfy G1a.
#
# Usage:
#   ./release/tools/audit-epic-rollup-close.sh                    # safe default: --dry-run --markdown
#   ./release/tools/audit-epic-rollup-close.sh --json
#   ./release/tools/audit-epic-rollup-close.sh --apply --authorize 1234 --authorize 5678
#   ./release/tools/audit-epic-rollup-close.sh --self-test
#
# Flags:
#   MODE (one of, default --dry-run):
#     --dry-run                Enumerate + report; no mutation (default)
#     --apply                  Close the AUTHORIZED candidates (opt-in). Requires at
#                              least one --authorize; closes ONLY issues this run
#                              classified CANDIDATE. A G2/G3 annotation NEVER
#                              authorizes a close, and --apply without --authorize
#                              is a validation failure, not a close-everything.
#     --authorize <N>          Per-issue operator authorization (repeatable). The
#                              second half of the double opt-in.
#   OUTPUT (one of, default --markdown):
#     --markdown               Human-readable report (default)
#     --json                   Machine-readable (same fields)
#   SCOPE:
#     --limit <N>              Population ceiling for the epic query (default 500)
#     --repo <owner/name>      Override the resolved repo slug
#   META:
#     --self-test              Validate the classifier against committed fixtures
#                              (OFFLINE — no gh, no network); exit 0 on success
#     --help, -h               Usage
#
# ARCHITECTURE — fetch is separated from classify ON PURPOSE. `fetch` performs
# every network read and emits a tagged JSONL stream; `classify` is a pure
# function from that stream to gate verdicts, with no network and no file I/O.
# The separation is what makes `--self-test` runnable offline in CI, which the
# selftest-discovery gate requires on both runner partitions.
#
# TRANSPORT — REST ONLY, no GraphQL. Sub-issues, labels, issue search and comments
# are all reachable over REST, and REST stays healthy when the GraphQL quota is
# exhausted. A detective tool that cannot run during a quota outage is a tool that
# is unavailable exactly when a release is closing.
#
# SUPPRESSION — zero new labels. An operator declines a candidate by leaving a
# comment on the epic carrying:
#   <!-- rollup-close-disposition: declined | date: YYYY-MM-DD | reason: <text> -->
# Only comments authored by OWNER / MEMBER / COLLABORATOR are honoured. Suppressed
# epics are counted and listed separately so suppression is never silent. A label
# would be the wrong instrument twice over: a new trigger for an existing state
# does not earn a parallel label, and `type:epic` is status-label-exempt anyway.
#
# Hook compatibility:
#   - No rm/rmdir/unlink anywhere; no temp files (the fetch stream is assembled in
#     a shell variable and piped to the classifier)
#   - Read-only against GitHub in the default mode; the only mutation is the
#     --apply close, gated behind explicit per-issue --authorize
#   - gh resolved by ABSOLUTE path and LAZILY (inside fetch, never at load) so the
#     script stays loadable — and therefore self-testable — on a runner with no gh
#
# Exit codes: 0 = success, 1 = validation failure, 2 = workspace-boundary check failed
#   FINDINGS NEVER PRODUCE A NON-ZERO EXIT. A run that surfaces 40 candidates and a
#   run that surfaces none both exit 0; only a malformed invocation or an
#   unreachable API is an error. This tool is not a gate.

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# WORKSPACE_ROOT resolution (env-override → operator.toml → default), mirroring
# cleanup-orphan-state.sh. The boundary check below keys on this value.
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}"
if [[ -z "$WORKSPACE_ROOT" ]]; then
  _operator_toml="${HOME}/.config/pmo-platform/operator.toml"
  if [[ -r "$_operator_toml" ]]; then
    _wr=$(grep -E '^claude_workspace_root' "$_operator_toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    [[ -n "$_wr" ]] && WORKSPACE_ROOT="$_wr"
  fi
fi
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${HOME}/Claude}"

# Repo slug resolution (env-override → git remote → operator.toml). Never
# hardcoded: an owner literal in a tracked file is both a portability defect and
# a depersonalization-gate failure.
REPO_SLUG="${REPO_SLUG:-}"

# Pure, offline-testable: remote URL -> owner/name. Strips the optional `.git`
# suffix FIRST, then takes the trailing two path segments. Deliberately POSIX ERE
# with no lazy quantifier — BSD/macOS `sed -E` rejects `+?` outright, and the
# failure mode is silent: the substitution errors to stderr, REPO_SLUG stays
# empty, and resolution slides to the operator.toml fallback while looking fine.
parse_slug_from_url() {
  local url="${1:-}"
  [[ -z "$url" ]] && return 0
  url="${url%.git}"
  printf '%s\n' "$url" | sed -E 's#^.*[:/]([^/]+/[^/]+)$#\1#'
}

resolve_repo_slug() {
  [[ -n "$REPO_SLUG" ]] && return 0
  local url
  url=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)
  # git@host:owner/name.git  |  https://host/owner/name.git
  [[ -n "$url" ]] && REPO_SLUG=$(parse_slug_from_url "$url")
  if [[ -z "$REPO_SLUG" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
    local _gh _repo
    _gh=$(grep -E '^operator_github' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    _repo=$(grep -E '^pmo_platform_repo_name' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    [[ -z "$_repo" ]] && _repo="pmo-platform"
    [[ -n "$_gh" ]] && REPO_SLUG="${_gh}/${_repo}"
  fi
  [[ -z "$REPO_SLUG" ]] && die "cannot resolve repo slug — set REPO_SLUG or pass --repo <owner/name>"
  return 0
}

# ─── Defaults ────────────────────────────────────────────────────────────────

MODE="dry-run"
OUTPUT="markdown"
LIMIT=500
SELF_TEST=0
AUTHORIZED=()

EPIC_LABEL="type:epic"
SPIKE_LABEL="type:spike"
SUPPRESSION_TOKEN="rollup-close-disposition"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '2,101p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

ts_now() { /bin/date -u +%Y-%m-%dT%H:%M:%SZ; }

# ─── Defense-in-depth workspace boundary ─────────────────────────────────────
# Mirrors cleanup-orphan-state.sh: refuse to run from outside the operator
# workspace. Skipped for --self-test, which is hermetic and must run on a CI
# runner that has no workspace at all.
check_workspace_boundary() {
  local cwd
  cwd="$(pwd -P)"
  case "$cwd" in
    "$WORKSPACE_ROOT"*) return 0 ;;
    *) echo "ERROR: invoked from $cwd — outside workspace $WORKSPACE_ROOT (defense-in-depth boundary)" >&2; exit 2 ;;
  esac
}

# ─── gh resolution — ABSOLUTE path, LAZY ─────────────────────────────────────
# The pinned PATH cannot see the Homebrew prefixes, so a bare `gh` would fail
# command-not-found. Resolution is deliberately lazy — it happens inside fetch,
# never at load — so the script loads (and therefore --self-tests) on a runner
# with no gh installed. Declaring a `# selftest-runner:` pin instead would push
# this tool onto the macOS partition for no reason.
GH_BIN=""
resolve_gh_bin() {
  [[ -n "$GH_BIN" ]] && return 0
  local c
  for c in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh; do
    if [[ -x "$c" ]]; then GH_BIN="$c"; return 0; fi
  done
  die "gh CLI not found at /opt/homebrew/bin/gh, /usr/local/bin/gh, or /usr/bin/gh under the pinned PATH"
}

# ─── Phase 1: fetch (network) ────────────────────────────────────────────────
# Emits a tagged JSONL stream on stdout. Every line is one of:
#   {"kind":"meta",     ...}
#   {"kind":"epic",     "number":N, "title":..., "labels":[...]}
#   {"kind":"native",   "epic":N, "number":M, "state":..., "state_reason":..., "labels":[...]}
#   {"kind":"label",    "epic":N, "number":M, "state":..., "state_reason":..., "labels":[...]}
#   {"kind":"suppress", "epic":N, "assoc":..., "body":...}
#
# `label` rows are emitted RAW — including the carrier itself and rows already
# present in the native set. De-duplication is the classifier's job so that the
# carrier-self-label guard is exercised by the offline self-test rather than
# living in an un-testable network path.
fetch_population() {
  resolve_gh_bin
  resolve_repo_slug

  local anchor
  anchor=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")

  local epics_jsonl
  if ! epics_jsonl=$("$GH_BIN" api \
        "repos/${REPO_SLUG}/issues?labels=${EPIC_LABEL}&state=open&per_page=100" \
        --paginate \
        --jq '.[] | select(.pull_request == null) | {kind:"epic", number, title, labels:[.labels[].name]}' 2>&1); then
    die "epic population query failed — refusing to report an empty population as a finding: ${epics_jsonl}"
  fi

  local count
  count=$(printf '%s\n' "$epics_jsonl" | grep -c '"kind":"epic"' || true)
  [[ -z "$count" ]] && count=0
  if [[ "$count" -eq 0 ]]; then
    die "epic population query returned ZERO open ${EPIC_LABEL} issues — a broken probe, not an empty population"
  fi
  if [[ "$count" -gt "$LIMIT" ]]; then
    die "epic population ($count) exceeds --limit ($LIMIT) — raise the limit rather than silently truncating"
  fi

  printf '{"kind":"meta","generated_at":"%s","commit_anchor":"%s","repo":"%s","denominator":%s}\n' \
    "$(ts_now)" "$anchor" "$REPO_SLUG" "$count"
  printf '%s\n' "$epics_jsonl"

  local n labels lbl
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    n=$(printf '%s\n' "$line" | /usr/bin/python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["number"])')

    # Native sub-issues.
    "$GH_BIN" api "repos/${REPO_SLUG}/issues/${n}/sub_issues?per_page=100" --paginate \
      --jq ".[] | {kind:\"native\", epic:${n}, number, state, state_reason, labels:[.labels[].name]}" 2>/dev/null || true

    # Label-linked children, one query per `epic:` label the epic carries.
    labels=$(printf '%s\n' "$line" | /usr/bin/python3 -c \
      'import json,sys; print("\n".join(l for l in json.loads(sys.stdin.read())["labels"] if l.startswith("epic:")))')
    while IFS= read -r lbl; do
      [[ -z "$lbl" ]] && continue
      "$GH_BIN" api "repos/${REPO_SLUG}/issues?labels=${lbl}&state=all&per_page=100" --paginate \
        --jq ".[] | select(.pull_request == null) | {kind:\"label\", epic:${n}, number, state, state_reason, labels:[.labels[].name]}" 2>/dev/null || true
    done <<< "$labels"

    # Suppression markers — trusted authors only, filtered at the source so no
    # unrelated comment body is ever carried into the classifier.
    "$GH_BIN" api "repos/${REPO_SLUG}/issues/${n}/comments?per_page=100" --paginate \
      --jq ".[] | select(.body != null) | select(.body | contains(\"${SUPPRESSION_TOKEN}\")) | {kind:\"suppress\", epic:${n}, assoc:.author_association, body:.body}" 2>/dev/null || true
  done <<< "$epics_jsonl"
}

# ─── Phase 2: classify (PURE — no network, no file I/O) ──────────────────────
classify() {
  /usr/bin/python3 -c '
import json, re, sys

TRUSTED = {"OWNER", "MEMBER", "COLLABORATOR"}
SPIKE = "type:spike"
MARKER = re.compile(
    r"<!--\s*rollup-close-disposition:\s*declined\b([^>]*)-->", re.IGNORECASE)

meta = {}
epics = {}
order = []

for raw in sys.stdin:
    raw = raw.strip()
    if not raw:
        continue
    try:
        row = json.loads(raw)
    except ValueError:
        continue
    kind = row.get("kind")
    if kind == "meta":
        meta = row
    elif kind == "epic":
        n = row["number"]
        if n not in epics:
            epics[n] = {"number": n, "title": row.get("title", ""),
                        "labels": row.get("labels", []),
                        "native": [], "label": [], "suppress": []}
            order.append(n)
    elif kind in ("native", "label"):
        e = epics.get(row["epic"])
        if e is not None:
            e[kind].append(row)
    elif kind == "suppress":
        e = epics.get(row["epic"])
        if e is not None:
            e["suppress"].append(row)

# G2 support: index every open epic by its project:* labels, from the population
# itself. A "sibling epic" is another OPEN type:epic sharing a project:* label.
proj_index = {}
for n in order:
    for lb in epics[n]["labels"]:
        if lb.startswith("project:"):
            proj_index.setdefault(lb, set()).add(n)

def norm_state(c):
    return (c.get("state") or "").upper()

def norm_reason(c):
    return (c.get("state_reason") or "").upper()

results = []
for n in order:
    e = epics[n]

    # ── Suppression (checked first; never silent) ──
    supp = None
    for s in e["suppress"]:
        if (s.get("assoc") or "").upper() not in TRUSTED:
            continue
        m = MARKER.search(s.get("body") or "")
        if m:
            supp = m.group(1).strip(" |")
            break

    # ── Child-set union ──
    # The carrier self-labels, so it must be excluded from its own child set:
    # left in, the epic is its own perpetually-open child and can NEVER satisfy
    # G1a. Silent, off-by-one, fatal.
    native = {c["number"]: c for c in e["native"] if c["number"] != n}
    label = {}
    for c in e["label"]:
        m = c["number"]
        if m == n or m in native:
            continue
        label[m] = c
    union = dict(native)
    union.update(label)

    open_children = sorted(m for m, c in union.items() if norm_state(c) == "OPEN")
    not_planned = sorted(m for m, c in union.items() if norm_reason(c) == "NOT_PLANNED")
    spikes = [m for m, c in union.items() if SPIKE in (c.get("labels") or [])]

    # ── G2 / G3 annotations — computed for EVERY epic, verdict-free ──
    siblings = set()
    proj_labels = [lb for lb in e["labels"] if lb.startswith("project:")]
    for lb in proj_labels:
        siblings |= proj_index.get(lb, set())
    siblings.discard(n)
    siblings -= set(union)
    g2 = {"sibling_epics": sorted(siblings),
          "project_singleton": bool(proj_labels) and not siblings,
          "project_labels": proj_labels}
    g3 = {"epic_labels": [lb for lb in e["labels"] if lb.startswith("epic:")],
          "scope_evidence": "read the epic body against release/releases/RELEASE_LOG.md"}

    # ── G1 ladder ──
    flags = []
    if supp is not None:
        verdict, reason = "SUPPRESSED", supp or "declined"
    elif not union:
        verdict, reason = "EXCLUDED", "no-children-rollup-undefined"
    elif open_children:
        verdict = "EXCLUDED"
        reason = "open-children: " + ", ".join("#%d" % m for m in open_children)
    else:
        verdict, reason = "CANDIDATE", ""
        if not_planned:
            flags.append("abandoned-children: %d/%d" % (len(not_planned), len(union)))
        if spikes and len(spikes) == len(union):
            flags.append("research-only-child-set")

    results.append({
        "number": n, "title": e["title"], "verdict": verdict, "reason": reason,
        "flags": flags,
        "children_native": len(native), "children_label": len(label),
        "children_total": len(union),
        "g2": g2, "g3": g3,
        "disposition_hint": ("declined — suppressed" if verdict == "SUPPRESSED"
                             else "not a candidate" if verdict == "EXCLUDED"
                             else "review (flagged)" if flags
                             else "review (clean rollup)"),
    })

counts = {
    "denominator": meta.get("denominator", len(order)),
    "candidates_clean": sum(1 for r in results if r["verdict"] == "CANDIDATE" and not r["flags"]),
    "candidates_flagged": sum(1 for r in results if r["verdict"] == "CANDIDATE" and r["flags"]),
    "excluded": sum(1 for r in results if r["verdict"] == "EXCLUDED"),
    "suppressed": sum(1 for r in results if r["verdict"] == "SUPPRESSED"),
}
json.dump({"meta": meta, "counts": counts, "results": results}, sys.stdout, indent=2)
sys.stdout.write("\n")
'
}

# ─── Phase 3: render ─────────────────────────────────────────────────────────
render_markdown() {
  /usr/bin/python3 -c '
import json, sys
d = json.load(sys.stdin)
m, c = d["meta"], d["counts"]
out = sys.stdout.write

out("# Epic Rollup-Close Audit\n\n")
out("**Generated:** %s  \n" % m.get("generated_at", "?"))
out("**Commit anchor:** `%s`  \n" % m.get("commit_anchor", "?"))
out("**Repo:** %s  \n" % m.get("repo", "?"))
out("**Denominator:** %s open `type:epic` issues\n\n" % c["denominator"])
out("> **This audit gates nothing.** It renders no close verdict. G2 (true epic vs.\n")
out("> mislabelled initiative) and G3 (body scope shipped) are **annotations for\n")
out("> operator judgment**, never decisions — G2 is not mechanically decidable from\n")
out("> label topology, so it is surfaced as evidence and never acted on.\n\n")
out("| Bucket | Count |\n|---|---|\n")
out("| Clean candidates | %d |\n" % c["candidates_clean"])
out("| Flagged candidates | %d |\n" % c["candidates_flagged"])
out("| Excluded | %d |\n" % c["excluded"])
out("| Suppressed (operator-declined) | %d |\n\n" % c["suppressed"])

def table(rows, show_reason=False):
    out("| Epic | Title | Children (native/label) | Sibling epics | Singleton | Gate flags |")
    out(" Reason |" if show_reason else " Disposition hint |")
    out("\n|---|---|---|---|---|---|---|\n")
    for r in rows:
        sib = ", ".join("#%d" % s for s in r["g2"]["sibling_epics"]) or "—"
        if len(sib) > 40:
            sib = sib[:37] + "..."
        title = r["title"] if len(r["title"]) <= 60 else r["title"][:57] + "..."
        out("| #%d | %s | %d (%d/%d) | %s | %s | %s | %s |\n" % (
            r["number"], title.replace("|", "\\|"),
            r["children_total"], r["children_native"], r["children_label"],
            sib, "yes" if r["g2"]["project_singleton"] else "no",
            ", ".join(r["flags"]) or "—",
            (r["reason"] or "—") if show_reason else r["disposition_hint"]))
    out("\n")

clean = [r for r in d["results"] if r["verdict"] == "CANDIDATE" and not r["flags"]]
flagged = [r for r in d["results"] if r["verdict"] == "CANDIDATE" and r["flags"]]
excluded = [r for r in d["results"] if r["verdict"] == "EXCLUDED"]
suppressed = [r for r in d["results"] if r["verdict"] == "SUPPRESSED"]

out("## Candidates — clean rollup\n\n")
out("All children reached a COMPLETED terminal state. Sibling-epic and singleton\n")
out("columns are the G2 evidence: a candidate sharing a `project:*` label with other\n")
out("open epics may be a thrust epic OR an initiative container — the columns do not\n")
out("distinguish them, and are not meant to.\n\n")
table(clean) if clean else out("_None._\n\n")

out("## Candidates — flagged\n\n")
out("Children are all closed, but not all closed *Done*. `abandoned-children` counts\n")
out("children closed NOT_PLANNED; `research-only-child-set` means every child is a\n")
out("spike, so research was answered but no capability necessarily shipped.\n\n")
table(flagged) if flagged else out("_None._\n\n")

out("## Excluded\n\n")
table(excluded, show_reason=True) if excluded else out("_None._\n\n")

out("## Suppressed\n\n")
if suppressed:
    out("Previously declined by an operator. Suppression is reported, never silent.\n\n")
    table(suppressed, show_reason=True)
else:
    out("_None._\n\n")

out("## Operator disposition\n\n")
out("Close an epic you judge complete, or decline it by commenting on the epic with:\n\n")
out("```\n<!-- rollup-close-disposition: declined | date: YYYY-MM-DD | reason: <text> -->\n```\n\n")
out("A declined epic is skipped by later runs and reported in the Suppressed bucket.\n")
out("Zero new labels are involved. To close authorized candidates from this tool:\n\n")
out("```\naudit-epic-rollup-close.sh --apply --authorize <N> [--authorize <M> ...]\n```\n")
'
}

# ─── Phase 4: apply (narrow, double opt-in) ──────────────────────────────────
# Closes ONLY issues this run classified CANDIDATE **and** that the operator named
# with --authorize. A G2/G3 annotation never authorizes anything. Reversibility is
# CHEAP: an over-eager close is undone by reopening.
apply_closures() {
  local verdicts="$1"
  resolve_gh_bin
  resolve_repo_slug

  local n verdict
  for n in "${AUTHORIZED[@]}"; do
    verdict=$(printf '%s' "$verdicts" | /usr/bin/python3 -c "
import json, sys
d = json.load(sys.stdin)
print(next((r['verdict'] for r in d['results'] if r['number'] == ${n}), 'ABSENT'))
")
    if [[ "$verdict" != "CANDIDATE" ]]; then
      echo "SKIP #${n} — classified ${verdict} this run, not CANDIDATE; refusing to close" >&2
      continue
    fi
    if "$GH_BIN" api -X PATCH "repos/${REPO_SLUG}/issues/${n}" \
         -f state=closed -f state_reason=completed --silent 2>/dev/null; then
      echo "CLOSED #${n} (state_reason=completed)" >&2
    else
      echo "FAIL   #${n} — close request rejected" >&2
    fi
  done
}

# ─── Self-test (OFFLINE — exercises `classify`, never the network) ───────────
run_self_test() {
  local failures=0

  _assert() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
      echo "  ok   ${label}"
    else
      echo "  FAIL ${label} — expected '${expected}', got '${actual}'" >&2
      failures=$((failures + 1))
    fi
  }

  _verdict() { printf '%s' "$1" | classify | /usr/bin/python3 -c "
import json, sys
d = json.load(sys.stdin)
r = next(r for r in d['results'] if r['number'] == int(sys.argv[1]))
print(r['verdict'])
" "$2"; }

  _field() { printf '%s' "$1" | classify | /usr/bin/python3 -c "
import json, sys
d = json.load(sys.stdin)
r = next(r for r in d['results'] if r['number'] == int(sys.argv[1]))
v = r
for k in sys.argv[2].split('.'):
    v = v[k]
# JSON-encode everything except plain strings, so a bool reads as the JSON
# literal the fixture asserts (`true`) rather than the Python repr (`True`).
print(v if isinstance(v, str) else json.dumps(v))
" "$2" "$3"; }

  local META='{"kind":"meta","generated_at":"T","commit_anchor":"abc","repo":"o/r","denominator":1}'

  echo "audit-epic-rollup-close.sh --self-test (offline; classifier fixtures)" >&2

  # 1. All children closed COMPLETED → CANDIDATE, no flags.
  local f1="${META}
{\"kind\":\"epic\",\"number\":1,\"title\":\"all done\",\"labels\":[\"type:epic\"]}
{\"kind\":\"native\",\"epic\":1,\"number\":11,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}
{\"kind\":\"native\",\"epic\":1,\"number\":12,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}"
  _assert "all-children-completed -> CANDIDATE" "CANDIDATE" "$(_verdict "$f1" 1)"
  _assert "all-children-completed -> no flags" "[]" "$(_field "$f1" 1 flags)"

  # 2. One open child → EXCLUDED, and the reason NAMES the open child.
  local f2="${META}
{\"kind\":\"epic\",\"number\":2,\"title\":\"one open\",\"labels\":[\"type:epic\"]}
{\"kind\":\"native\",\"epic\":2,\"number\":21,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}
{\"kind\":\"native\",\"epic\":2,\"number\":22,\"state\":\"open\",\"state_reason\":null,\"labels\":[]}"
  _assert "one-open-child -> EXCLUDED" "EXCLUDED" "$(_verdict "$f2" 2)"
  _assert "one-open-child -> reason names it" "open-children: #22" "$(_field "$f2" 2 reason)"

  # 3. Zero children → EXCLUDED with a DISTINCT reason (undefined, not satisfied).
  local f3="${META}
{\"kind\":\"epic\",\"number\":3,\"title\":\"childless\",\"labels\":[\"type:epic\"]}"
  _assert "zero-children -> EXCLUDED" "EXCLUDED" "$(_verdict "$f3" 3)"
  _assert "zero-children -> distinct reason" "no-children-rollup-undefined" "$(_field "$f3" 3 reason)"

  # 4. Mixed NOT_PLANNED → still a CANDIDATE, but FLAGGED. "Closed" != "Done".
  local f4="${META}
{\"kind\":\"epic\",\"number\":4,\"title\":\"partly abandoned\",\"labels\":[\"type:epic\"]}
{\"kind\":\"native\",\"epic\":4,\"number\":41,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}
{\"kind\":\"native\",\"epic\":4,\"number\":42,\"state\":\"closed\",\"state_reason\":\"not_planned\",\"labels\":[]}"
  _assert "not-planned child -> CANDIDATE" "CANDIDATE" "$(_verdict "$f4" 4)"
  _assert "not-planned child -> flagged" '["abandoned-children: 1/2"]' "$(_field "$f4" 4 flags)"

  # 5. All-spike child set → CANDIDATE + research-only flag.
  local f5="${META}
{\"kind\":\"epic\",\"number\":5,\"title\":\"research only\",\"labels\":[\"type:epic\"]}
{\"kind\":\"native\",\"epic\":5,\"number\":51,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[\"type:spike\"]}"
  _assert "all-spike -> CANDIDATE" "CANDIDATE" "$(_verdict "$f5" 5)"
  _assert "all-spike -> flagged" '["research-only-child-set"]' "$(_field "$f5" 5 flags)"

  # 6. CARRIER SELF-LABEL — the epic carries its own epic: label, so the label
  #    query returns the epic itself, OPEN. Without the guard the epic is its own
  #    open child and can NEVER close. This is the silent, fatal off-by-one.
  local f6="${META}
{\"kind\":\"epic\",\"number\":6,\"title\":\"carrier\",\"labels\":[\"type:epic\",\"epic:thing\"]}
{\"kind\":\"native\",\"epic\":6,\"number\":61,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[\"epic:thing\"]}
{\"kind\":\"label\",\"epic\":6,\"number\":6,\"state\":\"open\",\"state_reason\":null,\"labels\":[\"type:epic\",\"epic:thing\"]}
{\"kind\":\"label\",\"epic\":6,\"number\":61,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[\"epic:thing\"]}"
  _assert "carrier-self-label -> CANDIDATE (not its own child)" "CANDIDATE" "$(_verdict "$f6" 6)"
  _assert "carrier-self-label -> child counted once" "1" "$(_field "$f6" 6 children_total)"
  _assert "carrier-self-label -> zero label-only children" "0" "$(_field "$f6" 6 children_label)"

  # 7. DUAL-MECHANISM — an OPEN child linked by LABEL ONLY (absent from the native
  #    graph) must exclude the epic. A native-only read would call this Done.
  local f7="${META}
{\"kind\":\"epic\",\"number\":7,\"title\":\"label-linked open child\",\"labels\":[\"type:epic\",\"epic:thing\"]}
{\"kind\":\"native\",\"epic\":7,\"number\":71,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}
{\"kind\":\"label\",\"epic\":7,\"number\":72,\"state\":\"open\",\"state_reason\":null,\"labels\":[\"epic:thing\"]}"
  _assert "label-only open child -> EXCLUDED" "EXCLUDED" "$(_verdict "$f7" 7)"
  _assert "label-only open child -> union picked it up" "2" "$(_field "$f7" 7 children_total)"
  _assert "label-only open child -> counted as label" "1" "$(_field "$f7" 7 children_label)"

  # 8. SUPPRESSION — a trusted-authored declined marker suppresses; an untrusted
  #    one does NOT. The specificity arm keeps suppression from being forgeable.
  local f8="${META}
{\"kind\":\"epic\",\"number\":8,\"title\":\"declined\",\"labels\":[\"type:epic\"]}
{\"kind\":\"native\",\"epic\":8,\"number\":81,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}
{\"kind\":\"suppress\",\"epic\":8,\"assoc\":\"OWNER\",\"body\":\"<!-- rollup-close-disposition: declined | date: 2026-08-07 | reason: more scope planned -->\"}"
  _assert "trusted declined marker -> SUPPRESSED" "SUPPRESSED" "$(_verdict "$f8" 8)"

  local f8b="${META}
{\"kind\":\"epic\",\"number\":8,\"title\":\"forged\",\"labels\":[\"type:epic\"]}
{\"kind\":\"native\",\"epic\":8,\"number\":81,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}
{\"kind\":\"suppress\",\"epic\":8,\"assoc\":\"NONE\",\"body\":\"<!-- rollup-close-disposition: declined | date: 2026-08-07 | reason: forged -->\"}"
  _assert "untrusted declined marker -> NOT suppressed" "CANDIDATE" "$(_verdict "$f8b" 8)"

  # 9. G2/G3 ARE ANNOTATIONS, NEVER VERDICTS (AC-4). Two epics share a project:*
  #    label. Both must keep their G1-derived verdict; the sibling list is
  #    evidence only. The singleton arm is the discriminating control.
  local f9="${META}
{\"kind\":\"epic\",\"number\":91,\"title\":\"thrust a\",\"labels\":[\"type:epic\",\"project:p\"]}
{\"kind\":\"epic\",\"number\":92,\"title\":\"thrust b\",\"labels\":[\"type:epic\",\"project:p\"]}
{\"kind\":\"epic\",\"number\":93,\"title\":\"lone\",\"labels\":[\"type:epic\",\"project:q\"]}
{\"kind\":\"native\",\"epic\":91,\"number\":911,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}
{\"kind\":\"native\",\"epic\":92,\"number\":921,\"state\":\"open\",\"state_reason\":null,\"labels\":[]}
{\"kind\":\"native\",\"epic\":93,\"number\":931,\"state\":\"closed\",\"state_reason\":\"completed\",\"labels\":[]}"
  _assert "G2 sibling present -> verdict still CANDIDATE" "CANDIDATE" "$(_verdict "$f9" 91)"
  _assert "G2 sibling list is evidence" "[92]" "$(_field "$f9" 91 g2.sibling_epics)"
  _assert "G2 does not rescue an open-child epic" "EXCLUDED" "$(_verdict "$f9" 92)"
  _assert "G2 singleton detected" "true" "$(_field "$f9" 93 g2.project_singleton)"
  _assert "G2 singleton is NOT a verdict" "CANDIDATE" "$(_verdict "$f9" 93)"

  # 10. AC-5 — a run WITH findings still exits 0. Findings are not failures.
  local rc=0
  printf '%s' "$f1" | classify >/dev/null 2>&1 || rc=$?
  _assert "findings present -> classify exits 0" "0" "$rc"
  rc=0
  printf '%s' "$f1" | classify | render_markdown >/dev/null 2>&1 || rc=$?
  _assert "findings present -> render exits 0" "0" "$rc"

  # 11. Repo-slug parsing across both remote URL forms. This arm exists because
  #     the first implementation used a lazy quantifier that BSD `sed -E` rejects:
  #     the parse errored, REPO_SLUG fell through to the operator.toml fallback,
  #     and the run still LOOKED correct. A silent degradation to a fallback is
  #     exactly the class a report-only tool cannot self-detect at runtime.
  _assert "slug from https URL" "o/r" "$(parse_slug_from_url 'https://github.com/o/r.git')"
  _assert "slug from https URL, no .git" "o/r" "$(parse_slug_from_url 'https://github.com/o/r')"
  _assert "slug from ssh URL" "o/r" "$(parse_slug_from_url 'git@github.com:o/r.git')"
  _assert "slug parse emits no stderr" "" "$(parse_slug_from_url 'https://github.com/o/r.git' 2>&1 >/dev/null)"

  # 12. Report carries the audit-baseline triple (denominator/anchor/timestamp).
  local report
  report=$(printf '%s' "$f1" | classify | render_markdown)
  _assert "report carries commit anchor" "1" "$(printf '%s' "$report" | grep -c 'Commit anchor' || true)"
  _assert "report carries denominator" "1" "$(printf '%s' "$report" | grep -c 'Denominator' || true)"
  _assert "report states it gates nothing" "1" "$(printf '%s' "$report" | grep -c 'audit gates nothing' || true)"

  if [[ "$failures" -eq 0 ]]; then
    echo "audit-epic-rollup-close.sh --self-test: PASS (all classifier fixtures)" >&2
    return 0
  fi
  echo "audit-epic-rollup-close.sh --self-test: FAIL (${failures} assertion(s))" >&2
  return 1
}

# ─── Argument parsing ────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --authorize) [[ -n "${2:-}" ]] || die "--authorize requires an issue number"
                 [[ "$2" =~ ^[0-9]+$ ]] || die "--authorize expects an issue number, got '$2'"
                 AUTHORIZED+=("$2"); shift 2 ;;
    --markdown) OUTPUT="markdown"; shift ;;
    --json) OUTPUT="json"; shift ;;
    --limit) [[ -n "${2:-}" ]] || die "--limit requires a value"
             [[ "$2" =~ ^[0-9]+$ ]] || die "--limit expects an integer, got '$2'"
             LIMIT="$2"; shift 2 ;;
    --repo) [[ -n "${2:-}" ]] || die "--repo requires <owner/name>"
            REPO_SLUG="$2"; shift 2 ;;
    --self-test) SELF_TEST=1; shift ;;
    --help|-h) usage ;;
    *) die "unknown flag: $1" ;;
  esac
done

# --self-test is hermetic: no network, no workspace, no gh. It runs before every
# other check so a CI runner with none of those can still exercise the classifier.
if [[ "$SELF_TEST" -eq 1 ]]; then
  run_self_test
  exit $?
fi

check_workspace_boundary

if [[ "$MODE" == "apply" && "${#AUTHORIZED[@]}" -eq 0 ]]; then
  die "--apply requires at least one --authorize <N>; it is never a close-everything"
fi
if [[ "$MODE" == "dry-run" && "${#AUTHORIZED[@]}" -gt 0 ]]; then
  echo "NOTE: --authorize is inert without --apply; reporting only" >&2
fi

VERDICTS="$(fetch_population | classify)"

if [[ "$OUTPUT" == "json" ]]; then
  printf '%s\n' "$VERDICTS"
else
  printf '%s\n' "$VERDICTS" | render_markdown
fi

[[ "$MODE" == "apply" ]] && apply_closures "$VERDICTS"

exit 0
