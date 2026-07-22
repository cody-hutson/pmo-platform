#!/usr/bin/env bash
# claim-version.sh — the GitHub/git reference adapter's version-claim implementation.
#
# This script IS the GitHub/git `repo_host` adapter's versioning surface. It
# implements, against GitHub + git mechanism, the four host-agnostic operations
# the deterministic-version-claiming capability binds to (defined abstractly in
# core/standards/repo-host-adapter-versioning.md §2):
#
#     anchor()                     — highest claimed version in the mainline lineage
#     claimed_set()                — all versions currently claimed or in-flight
#     atomic_claim(version, ref)   — compare-and-swap claim; OK | COLLISION
#     lineage(version)             — MAINLINE | ORPHAN classifier
#
# The executable heart is atomic_claim()'s caller loop (the four-step fetch ->
# compute-next-free -> push-signed-tag -> discriminate-failure retry). The other
# three operations are exposed as sourceable functions so the allocation rule,
# the freeness detection layer (the pre-merge/CI checks), and a future
# release-executor claim-mode consume ONE GitHub-adapter implementation — there is
# never a second parser or a second anchor definition to drift (the divergence
# class the whole capability exists to kill).
#
# PARSER SSOT: all version validation / parsing / comparison comes from the
# version-grammar SSOT (release/tools/version-grammar.sh). This script SOURCES it
# and calls version_canonical / version_parse / version_cmp. It NEVER re-encodes
# the grammar regex or the comparator inline — a copied-inline parser is a
# divergence defect (version-grammar.sh "Consumer contract").
#
# SIGNING: atomic_claim() pushes a SIGNED-ANNOTATED tag. The repo enforces
# tag.gpgsign=true with gpg.format=ssh, so `git tag -a -m <msg>` auto-signs. This
# script NEVER passes a signing-bypass flag (-s is unnecessary; --no-gpg-sign /
# -c tag.gpgsign=false / GIT_CONFIG_PARAMETERS overrides are FORBIDDEN). It NEVER
# `git push --force` / `--delete` (the claim is create-only; a colliding tag is
# server-rejected, never overwritten).
#
# FAILURE DISCRIMINATION (the load-bearing correctness property): a non-zero
# `git push` exit is NOT, by itself, a lost compare-and-swap. ONLY a git
# ref-rejection signature ("[rejected] ... already exists" / "cannot lock ref")
# means a concurrent writer claimed the slot -> recompute + retry. EVERY other
# non-zero exit (network, authentication, permission, AND signing) is a hard HALT
# that surfaces the raw git error and does NOT recompute or re-push. Retrying a
# signing failure would silently defeat the never-bypass-signing guarantee; this
# script must not. (repo-host-adapter-versioning.md §2.3 "Failure discrimination".)
#
# Usage:
#   claim-version.sh --sha <merge_sha> --bump <major|minor|patch> \
#       [--patch-base <vX.Y>] [--message <m>] [--max-attempts N] [--dry-run]
#   claim-version.sh --self-test          # hermetic; no network, no real push
#
# On success: the claimed tag is printed to stdout (e.g. "v2.17"); exit 0.
# On HALT (contention exhausted, fetch failure, or a non-collision push failure):
# a diagnostic is printed to stderr; exit non-zero. The caller (Stage 12 Phase B3)
# escalates Tier 2 [SCOPE CHANGE] on a non-zero exit.

set -euo pipefail

# --- Source the version-grammar SSOT (parser/comparator). Sourcing defines
#     functions only; version-grammar.sh acts on --self-test only when executed
#     directly, so this source has no side effects. ---
CLAIM_REPO_ROOT="$(git rev-parse --show-toplevel)"
# Source the SSOT with an explicit empty positional arg so OUR $1 (which may be
# "--self-test") does NOT leak into the sourced file: version-grammar.sh acts on
# --self-test when $1 == "--self-test", and a sourced script inherits the caller's
# positionals unless overridden. Passing a single empty arg overrides $1 to "" so
# only its function definitions load (no nested self-test, no early exit).
# shellcheck source=/dev/null
source "${CLAIM_REPO_ROOT}/release/tools/version-grammar.sh" ""

# OWNER/repo for the GitHub adapter calls. Resolved upstream from `gh repo view`
# (never hardcoded) and passed in via CLAIM_REPO. In --self-test the host calls
# are stubbed, so CLAIM_REPO is not required there.
CLAIM_REPO="${CLAIM_REPO:-}"
MAX_ATTEMPTS_DEFAULT=5

# ---------------------------------------------------------------------------
# Host I/O seams (the ONLY place GitHub/git mechanism lives).
#
# These four wrappers issue the actual `gh` / `git` calls. The adapter operations
# below call ONLY these seams for host I/O, so the self-test can override the
# seams (stub the host) and exercise the full adapter + retry logic hermetically,
# with no network and no real tag push. This is what makes the discriminated-
# failure path (network -> HALT, signing -> HALT, rejection -> retry) testable
# without a live remote — the defect the Stage-5 adversarial review flagged as
# "every fixture mocks a clean rejection" is closed by injecting non-collision
# failures here.
# ---------------------------------------------------------------------------

# _host_published_tags  — echo the published-Release tag_names, one per line.
#   GitHub impl: the published Releases set (the mainline-published sequence).
_host_published_tags() {
  : "${CLAIM_REPO:?set CLAIM_REPO=owner/repo}"
  gh api "repos/${CLAIM_REPO}/releases" --paginate --jq '.[].tag_name'
}

# _host_latest_release  — echo the single "latest published release" tag_name.
#   GitHub impl of anchor(): repos/{REPO}/releases/latest. GitHub orders this by
#   created_at and returns the top of the mainline-published line; it self-excludes
#   an orphan version lineage that is not the newest published release.
_host_latest_release() {
  : "${CLAIM_REPO:?set CLAIM_REPO=owner/repo}"
  gh api "repos/${CLAIM_REPO}/releases/latest" --jq '.tag_name'
}

# _host_origin_tags  — echo origin's tag refs, one bare tag name per line.
_host_origin_tags() {
  git ls-remote --tags origin 2>/dev/null \
    | sed -e 's#.*refs/tags/##' -e 's/\^{}$//' \
    | sort -u
}

# _host_release_log_deployed  — echo the Version column of every RELEASE_LOG row
#   whose State column is exactly DEPLOYED (the in-flight, tag-pushed-but-Release-
#   unpublished claims). Schema: | Version | Milestone | Issues | Release PR |
#   Merge SHA | Tag | State | Date |  — under `awk -F'|'` the leading pipe makes
#   $1 empty, so Version = $2 and State = $8 (NOT $7, which is the Tag column).
_host_release_log_deployed() {
  local log="${CLAIM_REPO_ROOT}/release/releases/RELEASE_LOG.md"
  [[ -f "$log" ]] || return 0
  awk -F'|' '
    /^\|/ {
      ver=$2; st=$8
      gsub(/^[ \t]+|[ \t]+$/, "", ver)
      gsub(/^[ \t]+|[ \t]+$/, "", st)
      if (st == "DEPLOYED" && ver ~ /^v[0-9]/) print ver
    }
  ' "$log"
}

# _host_fetch_refs  — refresh origin tags (correctness precondition of a retry).
#   Returns the underlying git rc so the caller can HALT on a failed refresh
#   (FMF-3: a silently-failed fetch recomputes against a stale tip and never makes
#   progress). Output is suppressed; only the rc matters.
_host_fetch_refs() {
  git fetch --tags --force origin >/dev/null 2>&1
}

# _host_push_tag <tag> <merge_sha> <message>
#   Create the SIGNED-ANNOTATED tag at <merge_sha> and push it to origin (the
#   compare-and-swap). Echoes combined git stdout+stderr (so the caller can read
#   the rejection signature); returns the push rc.
#   NEVER --force, NEVER a signing-bypass flag. `-a` auto-signs under tag.gpgsign.
_host_push_tag() {
  local tag="$1" merge_sha="$2" message="$3"
  # Create the local signed-annotated tag (auto-signs: tag.gpgsign=true / ssh).
  # If signing fails here (agent unloaded / key missing), this returns non-zero
  # and the combined output carries "gpg failed to sign" / "error: ... signing" —
  # which _push_failure_is_collision() classifies as NON-collision -> hard HALT.
  if ! git tag -a -m "$message" "$tag" "$merge_sha" 2>&1; then
    return 1
  fi
  # Push the tag (create-only). A colliding tag is server-rejected; we do NOT
  # --force. Combined stdout+stderr is echoed for signature inspection.
  git push origin "refs/tags/${tag}:refs/tags/${tag}" 2>&1
}

# _host_delete_local_tag <tag>  — drop a local tag after a lost CAS (never the
#   remote; the remote tag belongs to the writer who won). Best-effort.
_host_delete_local_tag() {
  git tag -d "$1" >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# Push-failure classifier — the discrimination at the heart of FMF-1.
#
# _push_failure_is_collision <combined_output>
#   Exit 0 (true)  iff the output carries a git REF-REJECTION signature, meaning a
#                  concurrent writer already claimed this exact ref -> the ONLY
#                  case that recomputes + retries.
#   Exit 1 (false) for EVERY other failure (network, auth, permission, signing,
#                  unrelated non-fast-forward) -> the caller HARD-HALTs and
#                  surfaces the raw error. A signing failure is deliberately
#                  classified NON-collision so the never-bypass guarantee holds
#                  (we never recompute past a signing failure and re-push).
#
# The signatures are the literal git/remote rejection phrasings for a tag that
# already exists on the remote (ref-create CAS loss):
#   "! [rejected]" + "already exists"
#   "[rejected]"   + "(already exists)"
#   "cannot lock ref"            (the server could not fast-forward/create the ref)
#   "Updates were rejected because the tag already exists"
# ---------------------------------------------------------------------------
_push_failure_is_collision() {
  local out="$1"
  # A real ref-create rejection always pairs "[rejected]"/"cannot lock ref" with
  # an "already exists" / locked-ref phrasing. We require the rejection token AND
  # an existence/lock token so a generic "rejected" in an unrelated transport
  # message cannot masquerade as a CAS loss.
  if printf '%s' "$out" | grep -qiE '\[rejected\]' \
     && printf '%s' "$out" | grep -qiE 'already exists'; then
    return 0
  fi
  if printf '%s' "$out" | grep -qiE 'cannot lock ref|failed to update ref'; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Adapter operation: lineage(version) -> MAINLINE | ORPHAN
#
# Classifies a version by membership in the MAINLINE TAG FRONTIER — NOT by
# Release-publication state. The authoritative claim instant is the signed tag
# push (Stage 12 Phase B3), which PRECEDES the GitHub Release publish (Stage 13);
# keying on published Releases therefore lags the real frontier. A version is
# MAINLINE iff one of:
#   (a) its major == the frontier major M* (= the max major over the published-
#       Release set — the major line a release currently extends); OR
#   (b) it is the canonical first release of the NEXT major (vM*+1.00) — the sole
#       legal major-bump target, so a freshly-pushed next-major claim is mainline
#       before its Release publishes; OR
#   (c) its tuple is explicitly present in the published-Release set (historical
#       or other-major published releases — e.g. v1.x once the frontier is v2.x).
# An empty frontier major (greenfield: no published releases yet) -> MAINLINE
# (cannot determine the line; over-include — the safe posture, matching the
# deploy.sh pre-merge gate, which does not orphan-filter origin tags).
#
# This is the lineage-correct predicate the adversarial review (PRF-2/FMF-2)
# required IN PLACE OF a hardcoded `^v3\.` grep, RE-KEYED off the tag
# frontier rather than Release publication: it stays correct after a legitimate
# v3.0 ships (a real v3.0 is mainline via (a)/(b)/(c)), and it keeps the genuine
# stray v3.20 ORPHAN (major 3, minor 20, unpublished — fails (a), (b), and (c)).
# The bug it fixes: a freshly-pushed mainline tag (e.g. v2.39) whose Release has
# not yet published was wrongly ORPHAN under the old published-membership test, so
# a concurrent claimer re-computed an already-claimed slot and HALTed at local
# `git tag` ("already exists") — not a CAS collision, so it never retried.
#
# Callers pass the frontier major as $2 and the published-set as $3.. (computed
# once by claimed_set() to avoid re-fetching per call).
#
#   lineage <version> <frontier_major> <published_tag>...
# ---------------------------------------------------------------------------
lineage() {
  local v="$1" fmaj="$2"; shift 2
  version_canonical "$v" || { echo "ORPHAN"; return 0; }
  local vM vN vP
  read -r vM vN vP <<<"$(version_parse "$v")"
  # Greenfield (no published frontier major) -> cannot classify the line; over-include.
  if [[ -z "$fmaj" ]]; then echo "MAINLINE"; return 0; fi
  # (a) same mainline major-line as the published frontier.
  if [[ "$vM" -eq "$fmaj" ]]; then echo "MAINLINE"; return 0; fi
  # (b) the canonical first release of the next major (vM*+1.00).
  if [[ "$vM" -eq $((fmaj + 1)) && "$vN" -eq 0 && "$vP" -eq 0 ]]; then
    echo "MAINLINE"; return 0
  fi
  # (c) explicitly present in the published-Release set (historical/other major).
  local t pt
  for t in "$@"; do
    version_canonical "$t" || continue
    pt="$(version_parse "$t")"
    if [[ "$pt" == "$vM $vN $vP" ]]; then echo "MAINLINE"; return 0; fi
  done
  echo "ORPHAN"
}

# ---------------------------------------------------------------------------
# Adapter operation: anchor() -> version
#
# The highest claimed version in the mainline lineage = max(claimed_set()).
# claimed_set() unions published Releases U origin tags U DEPLOYED rows and keeps
# only MAINLINE members (re-keyed on the mainline TAG FRONTIER, not Release
# publication), so its maximum IS the true mainline frontier — and it CANNOT sit
# below a freshly-pushed-but-unpublished mainline tag, because that tag is itself a
# claimed_set member. This refines the GitHub anchor "how" (an adapter-internal
# detail per repo-host-adapter-versioning.md §2.1) away from the old `releases/
# latest` pointer, which lagged the tag frontier across the held-but-unclaimed gap
# and was the second half of the publication-gap collision. Greenfield (empty claimed_set —
# no tags/releases yet) falls back to the latest-published-release pointer. Reuses
# claimed_set() so there is no second mainline definition to drift. Still a pure
# read of authoritative host state at call time (never cached across the gap).
# ---------------------------------------------------------------------------
anchor() {
  local cs best="" v
  cs="$(claimed_set)"
  while IFS= read -r v; do
    [[ -n "$v" ]] || continue
    if [[ -z "$best" || "$(version_cmp "$v" "$best")" == "1" ]]; then best="$v"; fi
  done <<<"$cs"
  if [[ -n "$best" ]]; then printf '%s\n' "$best"; return 0; fi
  # Greenfield: no claimed mainline version yet -> the latest published release.
  local tip
  tip="$(_host_latest_release)"
  version_canonical "$tip" || {
    printf 'claim-version: anchor() — no claimed mainline version and latest release %q is not canonical\n' \
      "$tip" >&2
    return 1
  }
  printf '%s\n' "$tip"
}

# ---------------------------------------------------------------------------
# Adapter operation: claimed_set() -> set<version>
#
# All versions currently claimed or in-flight: the UNION of
#   (1) published Releases,
#   (2) origin git tags,
#   (3) RELEASE_LOG rows in DEPLOYED (tag-pushed-but-Release-unpublished) state,
# with the orphan-lineage exclusion (lineage()==MAINLINE) applied symmetrically to
# every member — RE-KEYED on the mainline TAG FRONTIER, not on Release
# publication — and every member gated by version_canonical (grammar SSOT). Echoes
# one canonical version per line, de-duplicated by tuple.
#
# The frontier major M* (max major over the published-Release set) is computed once
# here and passed to lineage() for every member, so a freshly-pushed-but-Release-
# unpublished mainline tag (member (2), e.g. v2.39) is correctly RETAINED as a claim
# while the genuine stray (v3.20) stays excluded (FMF-2 symmetry preserved, just no
# longer keyed on publication). (3) catches the same window from the RELEASE_LOG
# side; (1)/(2) are the steady-state catchers. Before this fix the exclusion keyed on
# published-Release membership, which dropped member (2)'s pushed tag and let a
# concurrent claimer re-compute an already-claimed slot.
# ---------------------------------------------------------------------------
claimed_set() {
  local published
  published="$(_host_published_tags)"
  # Build the raw candidate union (published U origin-tags U DEPLOYED-log-rows).
  local raw
  raw="$(
    { printf '%s\n' "$published"
      _host_origin_tags
      _host_release_log_deployed
    } | sed '/^$/d'
  )"
  # Split the published newline-list into positional args for lineage(). Disable
  # globbing for the split so a tag never expands as a glob (word-splitting on
  # whitespace is intended; glob expansion is not).
  local published_arr=()
  local _p
  set -f
  for _p in $published; do [[ -n "$_p" ]] && published_arr+=("$_p"); done
  set +f
  # Frontier major M* = max major over the published-Release set — the major line a
  # release currently extends. lineage() keys mainline-membership on M* (NOT on
  # Release publication), so a pushed-but-unpublished mainline tag is kept.
  local fmaj="" _pM
  for _p in "${published_arr[@]+"${published_arr[@]}"}"; do
    version_canonical "$_p" || continue
    read -r _pM _ _ <<<"$(version_parse "$_p")"
    if [[ -z "$fmaj" || "$_pM" -gt "$fmaj" ]]; then fmaj="$_pM"; fi
  done
  # Filter every member through version_canonical + lineage(==MAINLINE) against the
  # frontier major + published set, then de-dup by canonical tuple. The genuine
  # orphan (e.g. v3.20) is excluded; a pushed mainline tag (e.g. v2.39) is kept.
  local v seen=""
  while IFS= read -r v; do
    [[ -n "$v" ]] || continue
    version_canonical "$v" || continue
    [[ "$(lineage "$v" "$fmaj" "${published_arr[@]+"${published_arr[@]}"}")" == "MAINLINE" ]] || continue
    local tup; tup="$(version_parse "$v")"
    case " $seen " in *" $tup "*) continue;; esac
    seen="$seen $tup"
    printf '%s\n' "$v"
  done <<<"$raw"
}

# ---------------------------------------------------------------------------
# compute_next_free <bump> <patch_base> <claimed_tag>...
#
# Pure (no host I/O): given the bump-class, an optional patch base, and the
# already-computed claimed_set members, returns the lowest version at/above the
# floor that is NOT in the claimed set, walking by the bump-class's own increment
# and comparing via version_cmp (the grammar SSOT comparator). The floor:
#   major -> (anchor.M + 1, 0, 0)   walk minor
#   minor -> (anchor.M, anchor.N+1, 0)   walk minor
#   patch -> (base.M, base.N, base.P? .. ) walk PATCH on the shipped base (CDF-1):
#            floor = (Bmaj, Bmin, 1); never derived from the anchor.
# anchor() is read here (host I/O) for major/minor; patch reads only patch_base.
# ---------------------------------------------------------------------------
compute_next_free() {
  local bump="$1" patch_base="$2"; shift 2
  local claimed=("$@")
  local fM fN fP

  case "$bump" in
    major|minor)
      local a aM aN _aP
      a="$(anchor)"            # host read; returns the canonical latest-release tip
      read -r aM aN _aP <<<"$(version_parse "$a")"
      if [[ "$bump" == "major" ]]; then
        fM=$((aM + 1)); fN=0; fP=0
      else
        fM=$aM; fN=$((aN + 1)); fP=0
      fi
      ;;
    patch)
      [[ -n "$patch_base" ]] || {
        printf 'claim-version: compute_next_free — patch bump requires --patch-base\n' >&2
        return 2
      }
      version_canonical "$patch_base" || {
        printf 'claim-version: compute_next_free — patch-base %q not canonical\n' "$patch_base" >&2
        return 2
      }
      local bM bN _bP
      read -r bM bN _bP <<<"$(version_parse "$patch_base")"
      fM=$bM; fN=$bN; fP=1     # .1 hotfix on the shipped base (CDF-1: walk PATCH)
      ;;
    *)
      printf 'claim-version: compute_next_free — unknown bump-class %q\n' "$bump" >&2
      return 2
      ;;
  esac

  # Walk upward from the floor by the bump-class increment until a free slot.
  local cM=$fM cN=$fN cP=$fP
  local guard=0
  while _tuple_in_claimed "$cM" "$cN" "$cP" "${claimed[@]+"${claimed[@]}"}"; do
    if [[ "$bump" == "patch" ]]; then
      cP=$((cP + 1))                  # (M,N,P) -> (M,N,P+1)
    else
      cN=$((cN + 1)); cP=0            # (M,N,_) -> (M,N+1,0)
    fi
    guard=$((guard + 1))
    [[ $guard -lt 10000 ]] || { printf 'claim-version: compute_next_free — walk guard tripped\n' >&2; return 2; }
  done

  _format_version "$cM" "$cN" "$cP"
}

# _tuple_in_claimed <M> <N> <P> <claimed_tag>...
#   True iff (M,N,P) tuple-equals any claimed member (tuple equality, not string).
_tuple_in_claimed() {
  local cM="$1" cN="$2" cP="$3"; shift 3
  local want="$cM $cN $cP"
  local t tp
  for t in "$@"; do
    version_canonical "$t" || continue
    tp="$(version_parse "$t")"
    [[ "$tp" == "$want" ]] && return 0
  done
  return 1
}

# _format_version <M> <N> <P>  — the platform's canonical claim/display form.
#   Minor is zero-padded to 2 digits to match the shipped lineage (v1.01..v1.24,
#   v2.00..; never v2.9). Major is emitted as-is (single-digit lines). Patch is
#   appended only when non-zero (vM.NN.P, e.g. v2.06.1 — patch not zero-padded,
#   matching the shipped hotfix form). The padding is cosmetic for ordering
#   (version_cmp treats v2.9 and v2.09 as the same tuple) but it keeps the claimed
#   tag byte-identical to the shipped convention.
_format_version() {
  local minor; printf -v minor '%02d' "$2"
  if [[ "$3" -eq 0 ]]; then printf 'v%s.%s' "$1" "$minor"; else printf 'v%s.%s.%s' "$1" "$minor" "$3"; fi
}

# ---------------------------------------------------------------------------
# Adapter operation: atomic_claim(version, release_ref) + the caller loop.
#
# claim_version <merge_sha> <bump_class> [<patch_base>] [<message>]
#   The four-step CAS-retry (the executable heart):
#     STEP 1  fetch authoritative refs            (rc-checked; HALT on failure)
#     STEP 2  compute next-free >= floor          (anchor + claimed_set + version_cmp)
#     STEP 3  push the signed tag                 (the compare-and-swap)
#     STEP 4  discriminate the push outcome:
#               OK                       -> won the slot; print tag; return 0
#               ref-rejection (COLLISION)-> drop local tag; recompute; retry
#               any other failure        -> HARD HALT; surface raw error; return 1
#   Bounded MAX_ATTEMPTS; on exhaustion -> deterministic HALT (return 1).
# ---------------------------------------------------------------------------
claim_version() {
  local merge_sha="$1" bump="$2" patch_base="${3:-}" message="${4:-}"
  local max="${MAX_ATTEMPTS:-$MAX_ATTEMPTS_DEFAULT}"
  local attempt tag push_out push_rc

  for (( attempt=1; attempt<=max; attempt++ )); do
    # --- STEP 1: fetch authoritative refs (correctness precondition) ---
    if ! _host_fetch_refs; then
      printf 'claim-version: HALT — git fetch failed (cannot establish authoritative refs); not recomputing against a stale tip\n' >&2
      return 1
    fi

    # --- STEP 2: compute next-free >= floor (fresh anchor + claimed_set) ---
    local claimed
    claimed="$(claimed_set)" || {
      printf 'claim-version: HALT — claimed_set() failed (cannot read authoritative claimed state)\n' >&2
      return 1
    }
    local claimed_arr=()
    if [[ -n "$claimed" ]]; then
      while IFS= read -r _l; do [[ -n "$_l" ]] && claimed_arr+=("$_l"); done <<<"$claimed"
    fi
    tag="$(compute_next_free "$bump" "$patch_base" "${claimed_arr[@]+"${claimed_arr[@]}"}")" || {
      printf 'claim-version: HALT — next-free computation failed (bump=%s)\n' "$bump" >&2
      return 1
    }

    local msg="$message"
    [[ -n "$msg" ]] || msg="${tag} — release SHA = merge ${merge_sha:0:12}"

    # --- STEP 3: push the signed tag (the atomic compare-and-swap) ---
    push_out="$(_host_push_tag "$tag" "$merge_sha" "$msg")"; push_rc=$?

    # --- STEP 4: discriminate the outcome ---
    if [[ $push_rc -eq 0 ]]; then
      printf '%s\n' "$tag"                       # WON the compare-and-swap
      return 0
    fi

    if _push_failure_is_collision "$push_out"; then
      # COLLISION: a concurrent writer claimed this slot. Drop OUR local tag
      # (never the remote — it belongs to the winner; never --force) and retry
      # against the now-newer tip.
      _host_delete_local_tag "$tag"
      printf 'claim-version: attempt %d/%d lost ref-CAS on %s — recomputing against newer tip\n' \
        "$attempt" "$max" "$tag" >&2
      continue
    fi

    # NON-collision failure (network / auth / permission / SIGNING): HARD HALT.
    # Do NOT recompute, do NOT re-push — recomputing past a signing failure would
    # silently defeat the never-bypass-signing guarantee. Surface the raw error.
    _host_delete_local_tag "$tag"   # clean up any local tag we created pre-push
    printf 'claim-version: HALT — push of %s failed and is NOT a CAS collision (no recompute). Raw host error:\n%s\n' \
      "$tag" "$push_out" >&2
    return 1
  done

  # Loop exhausted: MAX_ATTEMPTS distinct contended losses — pathological.
  printf 'claim-version: HALT — %d contended ref-CAS losses; escalate Tier 2 [SCOPE CHANGE]\n' \
    "$max" >&2
  return 1
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
_usage() {
  cat >&2 <<'EOF'
Usage:
  claim-version.sh --sha <merge_sha> --bump <major|minor|patch> \
      [--patch-base <vX.Y>] [--message <m>] [--max-attempts N] [--dry-run]
  claim-version.sh --self-test

On success prints the claimed tag to stdout; non-zero exit on HALT.
EOF
}

_main() {
  local sha="" bump="" patch_base="" message="" dry_run=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --sha)          sha="$2"; shift 2;;
      --bump)         bump="$2"; shift 2;;
      --patch-base)   patch_base="$2"; shift 2;;
      --message)      message="$2"; shift 2;;
      --max-attempts) MAX_ATTEMPTS="$2"; shift 2;;
      --dry-run)      dry_run=1; shift;;
      -h|--help)      _usage; exit 0;;
      *) printf 'claim-version: unknown arg %q\n' "$1" >&2; _usage; exit 2;;
    esac
  done

  [[ -n "$sha"  ]] || { printf 'claim-version: --sha is required\n' >&2; _usage; exit 2; }
  [[ -n "$bump" ]] || { printf 'claim-version: --bump is required\n' >&2; _usage; exit 2; }

  if [[ "$dry_run" -eq 1 ]]; then
    # Dry-run: compute + report the next-free version WITHOUT pushing (no CAS).
    # Used by the Stage-12 Phase B3 integration check (DT-2) to confirm the
    # invocation wiring and the computed value without mutating the remote.
    if ! _host_fetch_refs; then
      printf 'claim-version: dry-run HALT — git fetch failed\n' >&2; exit 1
    fi
    local claimed claimed_arr=() tag
    claimed="$(claimed_set)"
    if [[ -n "$claimed" ]]; then
      while IFS= read -r _l; do [[ -n "$_l" ]] && claimed_arr+=("$_l"); done <<<"$claimed"
    fi
    tag="$(compute_next_free "$bump" "$patch_base" "${claimed_arr[@]+"${claimed_arr[@]}"}")" || exit 1
    printf '%s\n' "$tag"
    printf 'claim-version: dry-run — would claim %s (no tag pushed)\n' "$tag" >&2
    exit 0
  fi

  claim_version "$sha" "$bump" "$patch_base" "$message"
}

# ===========================================================================
# SELF-TEST — `bash release/tools/claim-version.sh --self-test`
#
# Hermetic: no network, no real push. The host I/O seams are OVERRIDDEN with
# in-memory stubs driven by fixture variables, so the FULL adapter + four-step
# CAS-retry logic runs against a sandbox claimed-set and a programmable push
# outcome. The load-bearing fixtures are the DISCRIMINATED-FAILURE ones the
# Stage-5 adversarial review demanded (network -> HALT, signing -> HALT) and the
# CAS-rejection -> recompute -> win path — none of which a "mock a clean
# rejection" suite would catch.
#
# STUB-SEAM SCOPING (the correctness property this placement guarantees): the
# stub seams + fixture helpers are defined INSIDE _claim_self_test() — NOT at
# top level — so they come into existence ONLY when --self-test runs. On a
# sourced / normal load (allocation rule, freeness layer, release-executor
# claim-mode) _claim_self_test() never runs, so the REAL _host_* seams (above)
# stay authoritative and a production anchor()/claimed_set()/atomic_claim()/
# --dry-run call hits real `gh`/`git`, never the empty self-test fixtures.
# (A bash function defined inside another function is created only when the
# enclosing function executes; the inner defs still propagate into the
# command-substitution SUBSHELLS the fixtures use, so self-test behavior is
# unchanged.)
# ===========================================================================

_claim_self_test() {
  local failures=0
  local _t_label

  # ----- Fixture seams + helpers (function-local: exist only while this runs) --
  # Fixture state is FILE-BACKED under $_ST_DIR so that observations made inside a
  # `$(claim_version ...)` command-substitution SUBSHELL survive into the parent
  # (a subshell cannot mutate parent variables, but it CAN append to shared files).
  # This is what lets the parent assert "how many push attempts happened" and "were
  # any orphan local tags left" after running claim_version in command substitution.
  #
  # Fixture-input files (the parent writes; stubs read):
  #   published / origin_tags / log_deployed / latest / fetch_rc / push_plan / advance
  # Observation files (stubs append; parent reads):
  #   push_idx / pushed_tags / local_tags
  _ST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/claim-version-selftest.XXXXXX")"
  trap 'rm -rf "$_ST_DIR"' RETURN

  _st_f() { printf '%s/%s' "$_ST_DIR" "$1"; }   # path to a state file

  # ----- U-0: REAL RELEASE_LOG parser regression (#2075 defect #2) --------------
  # Runs BEFORE the stub seam below shadows _host_release_log_deployed, so it
  # exercises the ACTUAL awk field-indexing against a real 8-column RELEASE_LOG
  # table. Guards State=$8: a DEPLOYED row MUST be extracted; a VERIFIED row must
  # NOT. The prior st=$7 read the Tag column, so category-3 was silently dead — the
  # hermetic fixture stub (next block) reads a pre-parsed list and could never catch
  # it. Synthetic v9.0x versions avoid any real-lineage semantics.
  _t_label="U-0 real RELEASE_LOG parser (State=\$8)"
  {
    local _u0d; _u0d="$(mktemp -d "${TMPDIR:-/tmp}/claim-version-u0.XXXXXX")"
    mkdir -p "$_u0d/release/releases"
    printf '%s\n' \
      '| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |' \
      '|---|---|---|---|---|---|---|---|' \
      '| v9.01 | m-verified | #1 | #2 | aaa | v9.01 | VERIFIED | 2026-07-18 |' \
      '| v9.02 | m-deployed | #3 | #4 | bbb | v9.02 | DEPLOYED | 2026-07-19 |' \
      > "$_u0d/release/releases/RELEASE_LOG.md"
    local _u0out; _u0out="$(CLAIM_REPO_ROOT="$_u0d" _host_release_log_deployed 2>/dev/null)"
    printf '%s\n' "$_u0out" | grep -qx 'v9.02' || { echo "FAIL [$_t_label]: must extract the DEPLOYED row v9.02 (State=\$8)"; failures=$((failures+1)); }
    printf '%s\n' "$_u0out" | grep -qx 'v9.01' && { echo "FAIL [$_t_label]: must NOT extract the VERIFIED row v9.01"; failures=$((failures+1)); }
    rm -rf "$_u0d"
  }

  # --- stub seams (override the real host I/O; all state via $_ST_DIR files) ---
  _host_published_tags()       { cat "$(_st_f published)"    2>/dev/null || true; }
  _host_latest_release()       { cat "$(_st_f latest)"       2>/dev/null || true; }
  _host_origin_tags()          { cat "$(_st_f origin_tags)"  2>/dev/null || true; }
  _host_release_log_deployed() { cat "$(_st_f log_deployed)" 2>/dev/null || true; }

  # fetch stub: returns the configured rc; ALSO applies a programmed "tip advance"
  # the first time the attempt-count crosses the advance threshold (simulates a
  # concurrent winner publishing the next number between our lost attempt and our
  # recompute). The advance file format: "<after_attempts>|<new_latest>|<new_set...>"
  _host_fetch_refs() {
    local rc; rc="$(cat "$(_st_f fetch_rc)" 2>/dev/null || echo 0)"
    local adv; adv="$(cat "$(_st_f advance)" 2>/dev/null || true)"
    if [[ -n "$adv" ]]; then
      local threshold="${adv%%|*}" rest="${adv#*|}"
      local new_latest="${rest%%|*}" new_set="${rest#*|}"
      local idx; idx="$(cat "$(_st_f push_idx)" 2>/dev/null || echo 0)"
      if [[ "$idx" -ge "$threshold" ]]; then
        printf '%s\n' "$new_latest" > "$(_st_f latest)"
        printf '%s\n' "$new_set" | tr ' ' '\n' > "$(_st_f published)"
        printf '%s\n' "$new_set" | tr ' ' '\n' > "$(_st_f origin_tags)"
        : > "$(_st_f advance)"      # one-shot
      fi
    fi
    return "$rc"
  }

  _host_delete_local_tag() {
    local tag="$1" lf; lf="$(_st_f local_tags)"
    [[ -f "$lf" ]] || return 0
    grep -vxF "$tag" "$lf" > "${lf}.tmp" 2>/dev/null || true
    mv -f "${lf}.tmp" "$lf"
  }

  # Programmable push stub: consumes the next push_plan line (one outcome per line).
  #   "ok"        -> tag reaches origin (rc 0, success output)
  #   "collision" -> emit the real ref-rejection signature (rc 1)
  #   anything else -> emit that text as a raw NON-collision failure (rc 1)
  # A literal "\n" in a plan line is expanded to a real newline (multi-line errors).
  _host_push_tag() {
    local tag="$1" _sha="$2" _msg="$3"
    printf '%s\n' "$tag" >> "$(_st_f local_tags)"     # "git tag -a" created a local tag
    local idx; idx="$(cat "$(_st_f push_idx)" 2>/dev/null || echo 0)"
    local plan; plan="$(sed -n "$((idx + 1))p" "$(_st_f push_plan)" 2>/dev/null)"
    [[ -n "$plan" ]] || plan="ok"
    printf '%s\n' "$((idx + 1))" > "$(_st_f push_idx)"
    case "$plan" in
      ok)
        printf '%s\n' "$tag" >> "$(_st_f pushed_tags)"
        printf 'To origin\n * [new tag]  %s -> %s\n' "$tag" "$tag"
        return 0
        ;;
      collision)
        printf 'To origin\n ! [rejected]  %s -> %s (already exists)\nerror: failed to push some refs\n' "$tag" "$tag"
        return 1
        ;;
      *)
        printf '%b\n' "$plan"                          # raw non-collision error (\n expanded)
        return 1
        ;;
    esac
  }

  # _ct_setup writes the fixture-input files and zeroes the observation files.
  #   _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
  #             deployed="" fetch_rc=0 plan=$'ok' advance="2|v2.16|v2.14 v2.15 v2.16"
  _ct_setup() {
    rm -rf "$_ST_DIR"; mkdir -p "$_ST_DIR"
    : > "$(_st_f push_idx)"; printf '0\n' > "$(_st_f push_idx)"
    : > "$(_st_f pushed_tags)"; : > "$(_st_f local_tags)"
    : > "$(_st_f published)"; : > "$(_st_f origin_tags)"; : > "$(_st_f log_deployed)"
    : > "$(_st_f latest)"; printf '0\n' > "$(_st_f fetch_rc)"; : > "$(_st_f push_plan)"; : > "$(_st_f advance)"
    local kv k v
    for kv in "$@"; do
      k="${kv%%=*}"; v="${kv#*=}"
      case "$k" in
        latest)    printf '%s\n' "$v" > "$(_st_f latest)";;
        published) printf '%s\n' "$v" | tr ' ' '\n' | sed '/^$/d' > "$(_st_f published)";;
        origin)    printf '%s\n' "$v" | tr ' ' '\n' | sed '/^$/d' > "$(_st_f origin_tags)";;
        deployed)  printf '%s\n' "$v" | tr ' ' '\n' | sed '/^$/d' > "$(_st_f log_deployed)";;
        fetch_rc)  printf '%s\n' "$v" > "$(_st_f fetch_rc)";;
        plan)      printf '%s\n' "$v" > "$(_st_f push_plan)";;       # NB: pass via $'...\n...'
        advance)   printf '%s\n' "$v" > "$(_st_f advance)";;
      esac
    done
  }

  # Counters emit exactly one integer and always exit 0 (so they are safe in
  # command substitution under set -e). Count non-blank lines via awk (no grep -c
  # double-output / non-zero-on-empty pitfalls).
  _ct_push_idx()    { cat "$(_st_f push_idx)" 2>/dev/null || echo 0; }
  _ct_pushed_n()    { awk 'NF{n++} END{print n+0}' "$(_st_f pushed_tags)" 2>/dev/null || echo 0; }
  _ct_local_n()     { awk 'NF{n++} END{print n+0}' "$(_st_f local_tags)"  2>/dev/null || echo 0; }
  _ct_has_local()   { grep -qxF "$1" "$(_st_f local_tags)" 2>/dev/null; }

  _ct_fail() { echo "FAIL [$_t_label]: $*"; failures=$((failures+1)); }
  _ct_eq()   { [[ "$1" == "$2" ]] || _ct_fail "expected '$2' got '$1' ($3)"; }
  # _ct_run captures stdout into REPLY and the rc into REPLY_RC without letting a
  # non-zero exit trip `set -e` (a failing $(...) in an assignment aborts under
  # set -e — many fixtures EXPECT non-zero, so this guard is required).
  _ct_run()    { REPLY_RC=0; REPLY="$("$@" 2>/dev/null)" || REPLY_RC=$?; }
  _ct_run_err(){ REPLY_RC=0; REPLY="$("$@" 2>&1 1>/dev/null)" || REPLY_RC=$?; }

  local out rc err

  # ---- U-1: next-free, no contention ----
  _t_label="U-1 next-free no contention"
  _ct_setup latest="v2.08" published="v2.06 v2.06.1 v2.07 v2.08" \
            origin="v2.06 v2.06.1 v2.07 v2.08" plan="ok"
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-1 exit 0"
  _ct_eq "$out" "v2.09" "U-1 returns v2.09"
  _ct_eq "$(_ct_push_idx)" "1" "U-1 exactly 1 push attempt"

  # ---- U-2: CAS rejection -> recompute -> win (the load-bearing case) ----
  # Attempt 1 computes v2.16 and is REJECTED; the tip then advances (a concurrent
  # winner published v2.16); attempt 2 recomputes against the new tip to v2.17 and
  # wins. advance="1|..." fires once push_idx >= 1 (i.e. after the lost attempt).
  _t_label="U-2 CAS rejection -> recompute -> win"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="$(printf 'collision\nok')" advance="1|v2.16|v2.14 v2.15 v2.16"
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-2 exit 0"
  _ct_eq "$out" "v2.17" "U-2 returns v2.17 (recomputed against advanced tip)"
  _ct_eq "$(_ct_push_idx)" "2" "U-2 exactly 2 push attempts"
  # no-overwrite invariant: the rejected local tag v2.16 was deleted, not orphaned
  _ct_has_local "v2.16" && _ct_fail "U-2 rejected local tag v2.16 must be deleted (no overwrite/orphan)"

  # ---- U-3: patch increment on rejection (CDF-1 — walk PATCH not minor) ----
  # patch-base v2.06 -> floor v2.06.1 (claimed) -> next-free v2.06.2; attempt 1 on
  # v2.06.2 REJECTED, tip advances (v2.06.2 published), attempt 2 -> v2.06.3.
  _t_label="U-3 patch increment on rejection"
  _ct_setup latest="v2.08" published="v2.06 v2.06.1 v2.07 v2.08" \
            origin="v2.06 v2.06.1 v2.07 v2.08" \
            plan="$(printf 'collision\nok')" advance="1|v2.08|v2.06 v2.06.1 v2.06.2 v2.07 v2.08"
  _ct_run claim_version "deadbeefcafe" "patch" "v2.06" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-3 exit 0"
  _ct_eq "$out" "v2.06.3" "U-3 returns v2.06.3 (patch walk, not minor)"

  # ---- U-4: bounded HALT — ALL attempts rejected, no --force, no orphan tag ----
  _t_label="U-4 bounded HALT (all rejected)"
  _ct_setup latest="v2.15" published="v2.15" origin="v2.15" \
            plan="$(printf 'collision\ncollision\ncollision\ncollision\ncollision')"
  MAX_ATTEMPTS=5
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  MAX_ATTEMPTS=""
  [[ "$rc" -ne 0 ]] || _ct_fail "U-4 expected non-zero exit, got 0"
  _ct_eq "$(_ct_push_idx)" "5" "U-4 exactly 5 attempts (bounded)"
  printf '%s' "$err" | grep -qiE 'contended.*loss|HALT' || _ct_fail "U-4 stderr should name contended-loss HALT"
  _ct_eq "$(_ct_pushed_n)" "0" "U-4 no tag pushed to origin"
  _ct_eq "$(_ct_local_n)" "0" "U-4 no orphan local tags"

  # ---- U-5: anchor + claimed_set exclude orphan v3.20 (lineage, not ^v3.) ----
  _t_label="U-5 orphan v3.20 excluded (both sides)"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15 v3.20" plan="ok"
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-5 exit 0"
  _ct_eq "$out" "v2.16" "U-5 returns v2.16 (orphan v3.20 not the anchor)"
  # prove claimed_set() itself drops the orphan tag (FMF-2 symmetric exclusion):
  local cs; cs="$(claimed_set)"
  printf '%s' "$cs" | grep -qx 'v3.20' && _ct_fail "U-5 claimed_set must EXCLUDE orphan v3.20"
  printf '%s' "$cs" | grep -qx 'v2.15' || _ct_fail "U-5 claimed_set must INCLUDE mainline v2.15"

  # ---- U-6: never-bypass signing — push uses -a, no bypass flag, no --force ----
  _t_label="U-6 never-bypass signing (no -s/-c bypass/--force)"
  # Assert against the REAL _host_push_tag (the production seam), not the stub:
  # extract its definition from the source between its def and the next function.
  local real_push
  real_push="$(awk '/^_host_push_tag\(\) \{/{f=1} f{print} f&&/^}/{exit}' "${BASH_SOURCE[0]}" | head -40)"
  printf '%s' "$real_push" | grep -qE 'git tag -a -m' || _ct_fail "U-6 real push must use 'git tag -a -m' (signed-annotated)"
  printf '%s' "$real_push" | grep -qE -- '--no-gpg-sign|tag\.gpgsign=false|GIT_CONFIG_PARAMETERS|git tag -s' \
    && _ct_fail "U-6 real push must NOT contain a signing-bypass flag"
  # No EXECUTABLE (non-comment) line may invoke `git push` with --force/-f. Strip
  # comment lines first so the prose ("never git push --force") and this check's
  # own pattern text are not counted — only real invocations are asserted.
  # (Failure messages below deliberately avoid the literal forbidden token so the
  # grep over this very file cannot match its own assertion text.)
  local exec_lines force_re
  exec_lines="$(sed -E 's/[[:space:]]*#.*$//' "${BASH_SOURCE[0]}" | sed -E '/^[[:space:]]*$/d')"
  force_re='git push[^|]*(--'"force"'|[[:space:]]-f([[:space:]]|$))'
  printf '%s\n' "$exec_lines" | grep -qE "$force_re" \
    && _ct_fail "U-6 no executable line may force-push the tag"
  # And the one real push must be the create-only refspec form (no --delete).
  printf '%s\n' "$exec_lines" | grep -qE 'git push origin "refs/tags/' \
    || _ct_fail "U-6 the real push must be the create-only refspec form"

  # ---- U-7: NON-collision push failure (network) -> immediate HARD HALT ----
  _t_label="U-7 network failure -> immediate HALT (no recompute)"
  _ct_setup latest="v2.15" published="v2.15" origin="v2.15" \
            plan="fatal: unable to access 'https://github.example/...': Could not resolve host: github.example"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-7 expected non-zero exit"
  _ct_eq "$(_ct_push_idx)" "1" "U-7 exactly 1 attempt (NOT retried as contention)"
  printf '%s' "$err" | grep -qi 'Could not resolve host' || _ct_fail "U-7 must surface the raw host error"
  printf '%s' "$err" | grep -qiE 'not a CAS collision|no recompute' || _ct_fail "U-7 must say it is not a collision"
  printf '%s' "$err" | grep -qiE 'contended.*loss' && _ct_fail "U-7 must NOT report contended-loss (false diagnosis)"
  _ct_eq "$(_ct_local_n)" "0" "U-7 no orphan local tag after HALT"

  # ---- U-8: SIGNING failure -> immediate HALT, no recompute, no orphan tags ----
  _t_label="U-8 signing failure -> immediate HALT (never-bypass preserved)"
  _ct_setup latest="v2.15" published="v2.15" origin="v2.15" \
            plan="error: gpg failed to sign the data\nfatal: failed to write commit object"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-8 expected non-zero exit"
  _ct_eq "$(_ct_push_idx)" "1" "U-8 exactly 1 attempt (signing failure NOT retried)"
  printf '%s' "$err" | grep -qi 'gpg failed to sign' || _ct_fail "U-8 must surface the raw signing error"
  printf '%s' "$err" | grep -qiE 'contended.*loss' && _ct_fail "U-8 must NOT report contended-loss"
  _ct_eq "$(_ct_pushed_n)" "0" "U-8 nothing pushed to origin"
  _ct_eq "$(_ct_local_n)" "0" "U-8 no orphan local tags (cleaned up)"

  # ---- U-9: fetch failure -> HALT (no stale-tip recompute) ----
  _t_label="U-9 fetch failure -> HALT (FMF-3)"
  _ct_setup latest="v2.15" published="v2.15" origin="v2.15" fetch_rc=7 plan="ok"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-9 expected non-zero exit on fetch failure"
  _ct_eq "$(_ct_push_idx)" "0" "U-9 zero push attempts (HALT before push)"
  printf '%s' "$err" | grep -qi 'fetch failed' || _ct_fail "U-9 must name the fetch failure"

  # ---- U-10: pushed-but-unpublished MAINLINE tag is a claim (publication-gap regression) ----
  # The v2.40-release collision: origin carries v2.39 (signed tag pushed at Stage 12
  # Phase B3) but releases/latest is still v2.38 (its Stage 13 Release not yet
  # published). A --bump minor MUST yield v2.40 — it must NOT re-compute the already-
  # claimed v2.39. Before this fix the orphan filter dropped v2.39 (no Release yet) and the
  # anchor lagged at v2.38, so the script returned v2.39 and HALTed at local
  # `git tag` ("already exists") — not a CAS collision, so it never retried.
  _t_label="U-10 pushed-unpublished mainline tag is a claim"
  _ct_setup latest="v2.38" published="v2.37 v2.38" origin="v2.37 v2.38 v2.39" plan="ok"
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-10 exit 0"
  _ct_eq "$out" "v2.40" "U-10 returns v2.40 (NOT v2.39 — the pushed tag is a definitive claim)"
  _ct_eq "$(_ct_push_idx)" "1" "U-10 exactly 1 push attempt (no false-collision HALT, no retry)"
  # claimed_set() must INCLUDE the pushed-but-unpublished mainline tag v2.39 ...
  local cs10; cs10="$(claimed_set)"
  printf '%s' "$cs10" | grep -qx 'v2.39' || _ct_fail "U-10 claimed_set must INCLUDE pushed mainline tag v2.39"
  # ... and anchor() must report the pushed frontier v2.39, not the lagging
  # published-latest v2.38 (the contract: highest CLAIMED version in the lineage).
  _ct_eq "$(anchor)" "v2.39" "U-10 anchor() = pushed frontier v2.39, not published-latest v2.38"
  # The genuine stray stays excluded even alongside the pushed mainline tag (so the
  # fix is a RE-KEY of the orphan filter, not its removal — v3.20 must not return):
  _ct_setup latest="v2.38" published="v2.37 v2.38" origin="v2.37 v2.38 v2.39 v3.20" plan="ok"
  local cs10b; cs10b="$(claimed_set)"
  printf '%s' "$cs10b" | grep -qx 'v2.39' || _ct_fail "U-10 claimed_set must INCLUDE v2.39 (stray present)"
  printf '%s' "$cs10b" | grep -qx 'v3.20' && _ct_fail "U-10 claimed_set must EXCLUDE genuine stray v3.20"

  if [[ $failures -eq 0 ]]; then
    echo "claim-version.sh --self-test: PASS (all fixtures green: U-0..U-10 incl. real-RELEASE_LOG-parser(State=\$8), net->HALT, signing->HALT, CAS-recompute-win, orphan-excluded both sides, pushed-unpublished-mainline-claimed, fetch-fail->HALT, bounded-HALT-no-force)"
    return 0
  else
    echo "claim-version.sh --self-test: FAIL ($failures failing fixture(s))"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Entry point — act only when executed directly; sourcing defines functions only
# (so the allocation rule / freeness layer / release-executor can source the
# adapter operations without triggering a claim).
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ "${1:-}" == "--self-test" ]]; then
    _claim_self_test
    exit $?
  fi
  _main "$@"
fi
