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

# OWNER/repo for the GitHub adapter calls. NEVER hardcoded. Resolved lazily by
# _host_resolve_repo() (the fifth host seam) through a three-tier chain:
#   1. CLAIM_REPO env, when non-empty  — wins, so every existing caller that sets
#      it keeps working byte-identically and the caller cascade stays at zero.
#   2. `gh repo view --json nameWithOwner` — the idiom the governed pipeline
#      surfaces already canonicalize, now internalized into the adapter that owns
#      host mechanism (repo-host-adapter-versioning.md §4).
#   3. Hard fail (return 1) naming every attempted source.
# Deliberately NOT derived from the git remote URL: a fork, mirror, or multi-
# remote checkout resolves a DIFFERENT repo, whose Releases form a plausible-
# looking WRONG claimed set — the same fail-open class this resolver closes,
# re-introduced by the fix.
# In --self-test the host calls are stubbed, so no resolution is required there.
CLAIM_REPO="${CLAIM_REPO:-}"
# Resolver memo (success AND failure), so the ≤10 seam calls per claim (2 per
# attempt x up to 5 attempts) issue at most ONE `gh repo view` and the failure
# diagnostic prints once rather than once per call. Initialized at top level so a
# first read under `set -u` cannot trip.
_CLAIM_REPO_RESOLVED=""
_CLAIM_REPO_RESOLVE_TRIED=0
MAX_ATTEMPTS_DEFAULT=5

# Claim-time plan-file stamping (post-CAS; ADR-092). When --stamp-slug is passed,
# the CAS-win path resolves {{RELEASE_VERSION}} in the pre-claim plan (+ any
# --stamp-file artifacts) and git-mv's the slug-named plan to its versioned home
# plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md. Absent --stamp-slug the stamping pass is
# skipped ENTIRELY — behavior is byte-identical to the pre-stamp script for every
# existing caller (backward-compatible; the CAS arithmetic/retry is untouched).
STAMP_SLUG="${STAMP_SLUG:-}"
STAMP_FILES=()

# ---------------------------------------------------------------------------
# Host I/O seams (the ONLY place GitHub/git mechanism lives).
#
# These five wrappers issue the actual `gh` / `git` calls. The adapter operations
# below call ONLY these seams for host I/O, so the self-test can override the
# seams (stub the host) and exercise the full adapter + retry logic hermetically,
# with no network and no real tag push. This is what makes the discriminated-
# failure path (network -> HALT, signing -> HALT, rejection -> retry) testable
# without a live remote — the defect the Stage-5 adversarial review flagged as
# "every fixture mocks a clean rejection" is closed by injecting non-collision
# failures here.
#
# RC CONTRACT (load-bearing — do NOT weaken to a `: "${VAR:?msg}"` assertion).
# Every seam that can fail returns NON-ZERO and its callers rc-check it. The
# `:?` idiom CANNOT be used here: these seams are only ever reached through
# command substitution, so a tripped `:?` aborts the substitution SUBSHELL and
# nothing else — the enclosing function still returns its own rc (0, from a
# trailing `while`), and the caller sees an EMPTY arm with a SUCCESS signal.
# `set -e` is structurally incapable of catching that shape. An unavailable arm
# and a legitimately-empty (greenfield) arm are both "empty string"; only the rc
# distinguishes them, which is why arm availability must travel as an rc and
# never as an output-emptiness inference.
# ---------------------------------------------------------------------------

# _host_resolve_repo  — echo `owner/repo` for the GitHub adapter calls, or return 1.
#   The chain is documented at CLAIM_REPO above. Lazy (never at load: a load-time
#   `gh repo view` would make `source` do network I/O and break the freeness layer
#   and the release-executor claim-mode) and memoized on BOTH outcomes.
_host_resolve_repo() {
  # Env tier — wins, and is re-read every call so a caller (or a fixture) that
  # sets CLAIM_REPO after a failed resolution is honored rather than memo-locked.
  if [[ -n "${CLAIM_REPO:-}" ]]; then
    printf '%s\n' "$CLAIM_REPO"
    return 0
  fi
  # Memoized success.
  if [[ -n "$_CLAIM_REPO_RESOLVED" ]]; then
    printf '%s\n' "$_CLAIM_REPO_RESOLVED"
    return 0
  fi
  # Memoized failure — stay silent on repeat so the diagnostic prints once.
  if [[ "$_CLAIM_REPO_RESOLVE_TRIED" -eq 1 ]]; then
    return 1
  fi
  _CLAIM_REPO_RESOLVE_TRIED=1
  local out rc=0
  out="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" || rc=$?
  if [[ "$rc" -eq 0 && -n "$out" && "$out" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    _CLAIM_REPO_RESOLVED="$out"
    printf '%s\n' "$out"
    return 0
  fi
  printf 'claim-version: HALT — cannot resolve the repo host identity for the published-Releases arm. CLAIM_REPO is unset and `gh repo view` did not yield owner/repo (rc=%s). Set CLAIM_REPO=owner/repo.\n' \
    "$rc" >&2
  return 1
}

# _host_published_tags  — echo the published-Release tag_names, one per line.
#   GitHub impl: the published Releases set (the mainline-published sequence).
#   Returns non-zero when the repo identity cannot be resolved OR when the API
#   call itself fails. The second limb is not redundant: an auth expiry, a rate
#   limit, or a network fault with CLAIM_REPO perfectly set produces the SAME
#   empty-arm outcome, and it is the more probable trigger of the two.
_host_published_tags() {
  local _repo
  _repo="$(_host_resolve_repo)" || return 1
  gh api "repos/${_repo}/releases" --paginate --jq '.[].tag_name' || return 1
}

# _host_latest_release  — echo the single "latest published release" tag_name.
#   GitHub impl of anchor(): repos/{REPO}/releases/latest. GitHub orders this by
#   created_at and returns the top of the mainline-published line; it self-excludes
#   an orphan version lineage that is not the newest published release.
#   Same rc contract as _host_published_tags.
_host_latest_release() {
  local _repo
  _repo="$(_host_resolve_repo)" || return 1
  gh api "repos/${_repo}/releases/latest" --jq '.tag_name' || return 1
}

# _host_origin_tags  — echo origin's tag refs, one bare tag name per line.
#   RC CONTRACT (load-bearing — #4339). This is the SAME defect class #3724 closed
#   on the published-Releases arm and DT-2 closed on deploy.sh's DEPLOYED arm, one
#   seam over: in the script that PUSHES tags rather than the one that gates merges.
#   Previously the body was a single `git ls-remote | sed | sort -u` pipeline, so the
#   function's exit status was `sort`'s — always 0 — and `2>/dev/null` discarded the
#   diagnostic as well. Measured against a genuinely-failing remote (`git ls-remote`
#   rc=128) the seam returned rc=0 with empty stdout: byte-identical to a healthy
#   read of a TAGLESS repository.
#   Why that is a collision and not merely under-reporting: this arm is the one that
#   catches a concurrent claimer's PUSHED-but-Release-unpublished tag (claimed_set()
#   member (2), e.g. v2.39). An arm that silently empties makes that in-flight claim
#   invisible, and the allocator hands out a version another writer already took —
#   precisely what the atomic claim exists to prevent.
#   The repair mirrors DT-2: the READ is its own command (so `$?` is git's, not the
#   pipeline's) and is separated from the TRANSFORM. The two states are separated by
#   the RC, never by output-emptiness.
_host_origin_tags() {
  local _raw _rc=0
  # stderr is deliberately NOT redirected — git's own diagnostic is half the point of
  # making the failure observable, and `2>/dev/null` discarding it was part of the
  # defect. (Same posture as deploy.sh::_vf_deployed_rows_from_log's awk stderr.)
  _raw="$(git ls-remote --tags origin)" || _rc=$?
  if [[ "$_rc" -ne 0 ]]; then
    printf 'claim-version: HALT — _host_origin_tags cannot read origin tags (git ls-remote rc=%s); an unevaluable tag set is NOT an empty one\n' \
      "$_rc" >&2
    return 1
  fi
  # A genuinely TAGLESS repo answers rc 0 with no output. Guarded explicitly so the
  # transform never turns "no tags" into a spurious blank line.
  [[ -n "$_raw" ]] || return 0
  printf '%s\n' "$_raw" \
    | sed -e 's#.*refs/tags/##' -e 's/\^{}$//' \
    | sort -u
}

# _host_release_log_deployed  — echo the Version column of every RELEASE_LOG row
#   whose State column is exactly DEPLOYED (the in-flight, tag-pushed-but-Release-
#   unpublished claims). Schema: | Version | Milestone | Issues | Release PR |
#   Merge SHA | Tag | State | Date |.
#
#   COLUMNS ARE PINNED BY HEADER NAME, NEVER BY ORDINAL (#4339 R2 — convergence
#   with deploy.sh::_vf_deployed_rows_from_log, which was pinned by name during the
#   v4.02 DT-fix while this parallel copy still read ordinal `$8`). The ordinal read
#   was CORRECT for today's schema, but it is the same latent mechanism DT-2 closed:
#   one column insertion shifts `$8` off State onto Tag, a Tag cell never holds the
#   literal DEPLOYED, and the arm goes structurally dead — a silently-empty arm in
#   the claim path, which is exactly the fail-open class this release is closing.
#   Resolving by NAME removes the failure mode rather than correcting one instance.
#
#   RC CONTRACT: an unreadable schema is REPORTED (rc 3 + stderr), never inferred
#   from emptiness — the same posture as the origin-tags arm above. A MISSING file
#   stays rc 0 (absence is not drift; a greenfield repo has no RELEASE_LOG).
_host_release_log_deployed() {
  local log="${CLAIM_REPO_ROOT}/release/releases/RELEASE_LOG.md"
  [[ -f "$log" ]] || return 0
  # awk stderr is deliberately NOT sent to /dev/null: the END-block diagnostic is
  # the whole point — an unreadable schema must be visible, not inferred.
  awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    /^\|/ {
      if (!have) {
        # Header row = the first pipe-row carrying BOTH column names. Prose pipes
        # and stray tables above the schema are skipped rather than misread.
        v = 0; s = 0
        for (i = 1; i <= NF; i++) {
          c = trim($i)
          if (c == "Version") v = i
          if (c == "State")   s = i
        }
        if (v && s) { vcol = v; scol = s; have = 1 }
        next
      }
      ver = trim($vcol); st = trim($scol)
      if (st == "DEPLOYED" && ver ~ /^v[0-9]/) print ver
    }
    END {
      if (!have) { print "claim-version: HALT — RELEASE_LOG header row has no Version+State columns; the DEPLOYED arm was not evaluated" > "/dev/stderr"; exit 3 }
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

# _host_commit_push <commit_msg> <repo_rel_path>...  — stage the given repo-relative
#   paths, commit the follow-on claim-time STAMP commit, and push it to the current
#   branch. The ONLY git-mutating seam of the stamp pass (ADR-092); the self-test
#   overrides it so the substitution + rename are exercised with no real remote.
#   NEVER --force (the stamp is a create/forward commit, never a history rewrite).
_host_commit_push() {
  local msg="$1"; shift
  git -C "$CLAIM_REPO_ROOT" add -- "$@" || return 1
  git -C "$CLAIM_REPO_ROOT" commit -m "$msg" >/dev/null 2>&1 || return 1
  git -C "$CLAIM_REPO_ROOT" push origin HEAD >/dev/null 2>&1 || return 1
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
  if grep -qiE '\[rejected\]' <<< "$out" \
     && grep -qiE 'already exists' <<< "$out"; then
    return 0
  fi
  if grep -qiE 'cannot lock ref|failed to update ref' <<< "$out"; then
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
  # rc-check, same contract as claim_version()/the --dry-run path: a FAILED
  # claimed_set() must not be read as a greenfield EMPTY one, which would send us
  # down the latest-release fallback and answer with a partial-view anchor.
  cs="$(claimed_set)" || {
    printf 'claim-version: HALT — anchor() cannot read the claimed set (partial view); not answering with a stale frontier\n' >&2
    return 1
  }
  while IFS= read -r v; do
    [[ -n "$v" ]] || continue
    if [[ -z "$best" || "$(version_cmp "$v" "$best")" == "1" ]]; then best="$v"; fi
  done <<<"$cs"
  if [[ -n "$best" ]]; then printf '%s\n' "$best"; return 0; fi
  # Greenfield: no claimed mainline version yet -> the latest published release.
  local tip
  tip="$(_host_latest_release)" || {
    printf 'claim-version: HALT — anchor() greenfield fallback cannot read the latest published release\n' >&2
    return 1
  }
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
  # FAIL CLOSED. An unavailable published arm is NOT an empty published arm: with
  # `published` empty the frontier major fmaj is empty too, lineage() takes its
  # greenfield over-include branch, and EVERY origin tag — including a genuine
  # orphan — reads as MAINLINE. So a silently-unavailable arm does not merely
  # under-report claims, it also disables the orphan filter for the other two
  # arms. Refusing to claim against a partial view is the only safe response.
  published="$(_host_published_tags)" || {
    printf 'claim-version: HALT — claimed_set() cannot evaluate the published-Releases arm; refusing to claim against a partial view\n' >&2
    return 1
  }
  # Arms (2) and (3) are evaluated OUTSIDE the union pipeline so their rc survives
  # to be checked (#4339; mirrors the DT-2 rc-contract on deploy.sh). Called from
  # INSIDE the `{ … } | sed` group their exit status was structurally unobservable —
  # the group's rc is the pipeline's, i.e. `sed`'s — so a failed read degraded to a
  # silently-empty arm and this function reported a partial view as authoritative.
  #
  # Both fail CLOSED, on the same reasoning that governs the published arm above and
  # with the SAME refusal vocabulary (one contract, not a second convention):
  #   (2) origin tags is the arm that catches a concurrent claimer's pushed-but-
  #       unpublished tag; losing it silently is the collision itself.
  #   (3) DEPLOYED rows catch that same window from the RELEASE_LOG side; an
  #       unreadable schema is a repo defect to fix, not a state to degrade around.
  local origin_tags
  origin_tags="$(_host_origin_tags)" || {
    printf 'claim-version: HALT — claimed_set() cannot evaluate the origin-tags arm; refusing to claim against a partial view\n' >&2
    return 1
  }
  local deployed_rows
  deployed_rows="$(_host_release_log_deployed)" || {
    printf 'claim-version: HALT — claimed_set() cannot evaluate the RELEASE_LOG DEPLOYED arm; refusing to claim against a partial view\n' >&2
    return 1
  }
  # Build the raw candidate union (published U origin-tags U DEPLOYED-log-rows).
  local raw
  raw="$(
    { printf '%s\n' "$published"
      printf '%s\n' "$origin_tags"
      printf '%s\n' "$deployed_rows"
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
# Claim-time plan-file stamping (post-CAS) — ADR-092.
#
# The plan-file/branch identity is SLUG-primary until the version is won; the
# concrete number binds only on the CAS-win path. This is the plan-file analogue of
# the tag's defer-to-claim (ADR-036): filesystem identity (filename, branch) stays
# slug-keyed and only file CONTENT carries the {{RELEASE_VERSION}} placeholder,
# resolved to the WON tag here. The pass runs ONLY when --stamp-slug was supplied
# AND ONLY after atomic_claim() returns OK, so the free recompute-retry loop never
# re-stamps — a lost candidate is never written to any filename or file body.
# ---------------------------------------------------------------------------

# _resolve_preclaim_plan <slug>  — echo the path to the pre-claim plan file, or fail.
#   Searches the two canonical pre-claim homes: the plans/ top level and _unversioned/.
_resolve_preclaim_plan() {
  local slug="$1"
  local plans_dir="${CLAIM_REPO_ROOT}/release/releases/plans"
  local c
  for c in "${plans_dir}/${slug}_RELEASE_PLAN.md" "${plans_dir}/_unversioned/${slug}_RELEASE_PLAN.md"; do
    [[ -f "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

# _preflight_stamp <slug>  — read-only PRE-CAS validation (the "before the CAS"
#   checkable half). Mutates NOTHING. Fails — so the caller HALTs BEFORE claiming a
#   number it cannot stamp — when the stamp manifest is broken: the pre-claim plan
#   must resolve, carry >=1 {{RELEASE_VERSION}} token, and plans/ must be writable.
_preflight_stamp() {
  local slug="$1" plan
  plan="$(_resolve_preclaim_plan "$slug")" || {
    printf 'claim-version: stamp pre-flight — no pre-claim plan %s_RELEASE_PLAN.md under release/releases/plans/\n' "$slug" >&2
    return 1
  }
  grep -q '{{RELEASE_VERSION}}' "$plan" || {
    printf 'claim-version: stamp pre-flight — plan %s carries no {{RELEASE_VERSION}} token to resolve\n' "$plan" >&2
    return 1
  }
  local plans_dir="${CLAIM_REPO_ROOT}/release/releases/plans"
  [[ -d "$plans_dir" && -w "$plans_dir" ]] || {
    printf 'claim-version: stamp pre-flight — plans dir %s missing or not writable\n' "$plans_dir" >&2
    return 1
  }

  # A plan-only manifest cannot stale a package and cannot cross a version
  # grammar: the plan lives under release/releases/plans/, which is neither a
  # skills/ source path nor a TEMPLATE_SYNC_MAP canonical, and its own frontmatter
  # version IS the release version. Returning here keeps every existing plan-only
  # caller byte-unaffected by the checks below — which is the whole invocation
  # population in the release log to date.
  [[ ${#STAMP_FILES[@]} -eq 0 ]] && return 0

  # --- Everything below extends this function's stated doctrine from "can I
  #     substitute?" to "can I complete the stamp INCLUDING its package
  #     consequence?". All of it is decidable BEFORE the CAS, which is exactly
  #     where it must run: post-CAS, _stamp_release_identity NEVER un-claims the
  #     tag, so the same failure discovered late strands a half-applied stamp AND
  #     a stale package instead of simply declining to claim.
  local f abs
  for f in "${STAMP_FILES[@]}"; do
    abs="${CLAIM_REPO_ROOT}/${f}"
    [[ -f "$abs" ]] || {
      printf 'claim-version: stamp pre-flight — --stamp-file %s not found under repo root %s\n' "$f" "$CLAIM_REPO_ROOT" >&2
      return 1
    }

    # CROSS-GRAMMAR GUARD. {{RELEASE_VERSION}} resolves to the WON RELEASE TAG
    # verbatim, and the release-tag grammar and the skill version:-field grammar
    # are deliberately different objects governing different things. A release tag
    # may carry a three-component patch form (v2.06.1 — five such tags have
    # shipped); the skill grammar forbids a patch level outright, because skills
    # sync to platform MINOR versions. So a token sitting on a SKILL.md version:
    # line stamps a value that fails deploy.sh Check 6 on any patch release — and
    # even on a minor release it overwrites the pmo-skill-editor-managed skill
    # version with a release tag, which is not what that field means
    # (core/standards/version-field-semantics.md § Definition).
    #
    # Rejected here, pre-CAS, rather than discovered as a red Check 6 after the
    # tag is irreversibly claimed. Scoped to the version: line of a SKILL.md
    # specifically: a token anywhere else in that file (release-note prose, a
    # "shipped in" line) is a legitimate stamp target and is left alone.
    case "$f" in
      SKILL.md|*/SKILL.md)
        if grep -qE '^version:[[:space:]]*\{\{RELEASE_VERSION\}\}[[:space:]]*$' "$abs"; then
          printf 'claim-version: stamp pre-flight — %s carries {{RELEASE_VERSION}} on its version: frontmatter line. That field is the skill version (vMAJOR.MINOR, editor-managed per core/standards/version-field-semantics.md), not the release tag; a patch-form tag would also fail deploy.sh Check 6. Remove the token from the version: line (elsewhere in the file is fine).\n' "$f" >&2
          return 1
        fi
        ;;
    esac
  done

  # Package consequence: which .skill packages would this stamp stale? Resolved
  # through the builder's query mode so the answer comes from the same rules that
  # decide what a package contains.
  local plan_rel="${plan#"${CLAIM_REPO_ROOT}/"}"
  local affected rc_aff=0
  affected="$(_resolve_affected_skills "$plan_rel" "${STAMP_FILES[@]}")" || rc_aff=$?
  if [[ $rc_aff -ne 0 ]]; then
    printf 'claim-version: stamp pre-flight — cannot determine the package consequence of this manifest: core/deploy/tools/build-skill-packages.sh is missing or failed under %s. Not claiming a number whose stamp could silently stale a package.\n' "$CLAIM_REPO_ROOT" >&2
    return 1
  fi
  if [[ -n "$affected" ]]; then
    printf 'claim-version: stamp pre-flight — manifest stales %s package(s): %s (they will be rebuilt into the stamp commit)\n' \
      "$(grep -c . <<<"$affected")" "$(tr '\n' ' ' <<<"$affected")" >&2
  fi
  return 0
}

# _resolve_affected_skills <repo-rel-path>...  — echo the deduped set of skills
#   whose .skill package the given paths feed (one per line; empty output = the
#   manifest stales no package). PURE QUERY: reads only, never builds, never
#   writes. Returns 2 when the package builder is not resolvable under
#   CLAIM_REPO_ROOT, so a caller can tell "no packages affected" apart from
#   "could not determine".
#
#   The resolution RULES live ONCE, in the builder's --skills-for-paths mode. A
#   second copy here would be a shadow SSOT: the rules depend on TEMPLATE_SYNC_MAP
#   and on the canonical-source resolver, both of which this file has no other
#   reason to know about, and a copy would drift the moment either changes.
_resolve_affected_skills() {
  local builder="${CLAIM_REPO_ROOT}/core/deploy/tools/build-skill-packages.sh"
  [[ -f "$builder" ]] || return 2
  printf '%s\n' "$@" | bash "$builder" --root "$CLAIM_REPO_ROOT" --skills-for-paths
}

# _host_rebuild_packages <skill>...  — HOST SEAM. The sole package-mutating call
#   in this file: rebuilds each named skill's .skill package and its .sha256
#   content-baseline sidecar in place under CLAIM_REPO_ROOT.
#
#   It is a _host_* seam for the same reason every other host operation here is
#   one: the self-test OVERRIDES it, so no fixture run can reach a real packages/
#   directory. That matters more than usual here — build-skill-packages.sh derives
#   its own repo root from its own location, so a sandboxed invocation of the real
#   builder would otherwise resolve back to the live tree and write real packages.
#   --root pins it to the same tree the stamp is mutating.
_host_rebuild_packages() {
  bash "${CLAIM_REPO_ROOT}/core/deploy/tools/build-skill-packages.sh" \
    --root "$CLAIM_REPO_ROOT" "$@"
}

# _stamp_release_identity <tag> <slug> <merge_sha>  — POST-CAS claim-time stamp.
#   Runs ONLY on the CAS-win path, with the WON <tag>. Resolves {{RELEASE_VERSION}}
#   -> <tag> in the pre-claim plan's CONTENT (+ any --stamp-file artifacts, repo-
#   relative), git-mv's the slug-named plan to plans/v<MAJOR>/<tag>_RELEASE_PLAN.md,
#   and commits+pushes the follow-on stamp via _host_commit_push (the same post-
#   merge-commit pattern Stage 13 uses for RELEASE_LOG/INDEX rows). A stamp failure
#   HALTs and surfaces "tag claimed, stamp manually" — it NEVER un-claims the tag.
_stamp_release_identity() {
  local tag="$1" slug="$2" merge_sha="$3"
  local plan
  plan="$(_resolve_preclaim_plan "$slug")" || {
    printf 'claim-version: stamp — pre-claim plan for slug %q vanished post-claim\n' "$slug" >&2
    return 1
  }
  local vM _vN _vP
  read -r vM _vN _vP <<<"$(version_parse "$tag")" || {
    printf 'claim-version: stamp — cannot parse won tag %q\n' "$tag" >&2
    return 1
  }
  local dest_dir="${CLAIM_REPO_ROOT}/release/releases/plans/v${vM}"
  local dest="${dest_dir}/${tag}_RELEASE_PLAN.md"
  mkdir -p "$dest_dir" || return 1
  # Resolve {{RELEASE_VERSION}} in CONTENT — extra --stamp-file artifacts first
  # (repo-relative to CLAIM_REPO_ROOT), then the plan itself.
  local f abs tmp
  local extra_rel=()
  for f in "${STAMP_FILES[@]+"${STAMP_FILES[@]}"}"; do
    abs="${CLAIM_REPO_ROOT}/${f}"
    [[ -f "$abs" ]] || { printf 'claim-version: stamp — --stamp-file %q not found under repo root\n' "$f" >&2; return 1; }
    tmp="$(mktemp)"
    sed "s/{{RELEASE_VERSION}}/${tag}/g" "$abs" > "$tmp" && cat "$tmp" > "$abs" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    extra_rel+=("$f")
  done
  tmp="$(mktemp)"
  sed "s/{{RELEASE_VERSION}}/${tag}/g" "$plan" > "$tmp" && cat "$tmp" > "$plan" || { rm -f "$tmp"; return 1; }
  rm -f "$tmp"
  # Bind the FILENAME identity: git mv the slug-named plan to its versioned path.
  git -C "$CLAIM_REPO_ROOT" mv -- "$plan" "$dest" || return 1
  # Follow-on stamp commit (+push) of the renamed plan and any stamped extras.
  local commit_paths=("release/releases/plans/v${vM}/${tag}_RELEASE_PLAN.md")
  commit_paths+=("${extra_rel[@]+"${extra_rel[@]}"}")

  # --- PACKAGE CONSEQUENCE, riding the SAME commit ---------------------------
  # A skill's version: line and every canonical injected into its package sit
  # INSIDE the .skill content hash, so a stamp that rewrote packaged source has
  # ALREADY staled that package by the time we get here. Rebuilding in a follow-on
  # commit would leave one revision on the mainline carrying stamped source with a
  # stale package — stale by construction for Check 7, which evaluates content
  # freshness per revision. So the rebuilt package and its .sha256 sidecar are
  # appended to THIS commit's path list.
  #
  # Resolved from the paths ACTUALLY stamped, not from the pre-flight's earlier
  # guess: the pre-flight decides whether to claim at all, this decides what to
  # commit, and only the second is allowed to be authoritative about what changed.
  #
  # Fail-loud is RETAINED as the error path, not discarded: a rebuild failure
  # returns 1 and the caller's existing HALT surfaces "tag claimed, stamp
  # manually" with the builder command and the affected skills named. Fail-loud as
  # the PRIMARY behaviour was rejected because this function never un-claims the
  # tag, so aborting here leaves a claimed tag, a half-applied stamp AND a stale
  # package — strictly worse than the status quo it was meant to improve on.
  #
  # Skipped entirely when no --stamp-file artifacts were stamped: the renamed plan
  # alone can never stale a package (release/releases/plans/ is neither a skills/
  # source path nor a TEMPLATE_SYNC_MAP canonical), so the existing plan-only
  # stamp path runs byte-identically to before.
  if [[ ${#extra_rel[@]} -gt 0 ]]; then
    local affected_out rc_aff=0 sk
    affected_out="$(_resolve_affected_skills "${extra_rel[@]}")" || rc_aff=$?
    if [[ $rc_aff -ne 0 ]]; then
      printf 'claim-version: stamp — cannot resolve the package consequence of the stamped files (core/deploy/tools/build-skill-packages.sh missing or failed). Rebuild affected packages manually and commit packages/<skill>.skill + packages/<skill>.skill.sha256 (tag %s claimed; stamp half-applied)\n' "$tag" >&2
      return 1
    fi
    if [[ -n "$affected_out" ]]; then
      local affected_arr=()
      while IFS= read -r sk; do [[ -n "$sk" ]] && affected_arr+=("$sk"); done <<<"$affected_out"
      _host_rebuild_packages "${affected_arr[@]}" || {
        printf 'claim-version: stamp — package rebuild FAILED for: %s. Run: bash core/deploy/tools/build-skill-packages.sh %s — then commit packages/<skill>.skill and packages/<skill>.skill.sha256 for each (tag %s claimed; stamp half-applied)\n' \
          "${affected_arr[*]}" "${affected_arr[*]}" "$tag" >&2
        return 1
      }
      for sk in "${affected_arr[@]}"; do
        commit_paths+=("packages/${sk}.skill" "packages/${sk}.skill.sha256")
      done
    fi
  fi

  _host_commit_push "stamp: bind ${tag} release identity (plan rename + {{RELEASE_VERSION}} resolve) [SHA ${merge_sha:0:12}]" "${commit_paths[@]}" || return 1
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

    # --- STEP 2.7: stamp pre-flight (read-only; only when --stamp-slug given) ---
    # Validate the stamp manifest BEFORE the CAS so we never claim a number we
    # cannot stamp. Mutates nothing (the recompute-retry loop stays free).
    [[ -n "${STAMP_SLUG:-}" ]] && { _preflight_stamp "$STAMP_SLUG" || {
      printf 'claim-version: HALT — stamp pre-flight failed (broken manifest); not claiming\n' >&2
      return 1
    }; }

    local msg="$message"
    [[ -n "$msg" ]] || msg="${tag} — release SHA = merge ${merge_sha:0:12}"

    # --- STEP 3: push the signed tag (the atomic compare-and-swap) ---
    push_out="$(_host_push_tag "$tag" "$merge_sha" "$msg")"; push_rc=$?

    # --- STEP 4: discriminate the outcome ---
    if [[ $push_rc -eq 0 ]]; then
      # WON the compare-and-swap. Post-CAS: stamp the claim-time identity with the
      # WON tag (only when --stamp-slug given). A stamp failure HALTs — the tag is
      # authoritative and is NEVER un-claimed; stamp manually on failure.
      [[ -n "${STAMP_SLUG:-}" ]] && { _stamp_release_identity "$tag" "$STAMP_SLUG" "$merge_sha" || {
        printf 'claim-version: HALT — %s claimed but stamp failed; stamp manually (tag authoritative)\n' "$tag" >&2
        return 1
      }; }
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
      [--patch-base <vX.Y>] [--message <m>] [--max-attempts N] \
      [--stamp-slug <slug>] [--stamp-file <repo-rel-path>]... [--dry-run]
  claim-version.sh --self-test

On success prints the claimed tag to stdout; non-zero exit on HALT.

--stamp-slug <slug>  When set, on the CAS-win path resolve {{RELEASE_VERSION}} in
    the pre-claim plan release/releases/plans/<slug>_RELEASE_PLAN.md (post-CAS,
    with the WON tag) and git-mv it to plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md
    (ADR-092). Absent this flag the stamping pass is skipped entirely.
--stamp-file <path>  Optional, repeatable. Additional repo-relative token-bearing
    file(s) whose {{RELEASE_VERSION}} is resolved in the same stamp commit.
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
      --stamp-slug)   STAMP_SLUG="$2"; shift 2;;
      --stamp-file)   STAMP_FILES+=("$2"); shift 2;;
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
    # FAIL CLOSED here too. The dry-run is the DETECTOR rung (Stage-12 A.5.6a /
    # Stage-9 A6.5 / deploy.sh Check 41) for the very collision the real claim
    # prevents; if it fails open it degrades in lockstep with the rung it is
    # supposed to be checking, and reports a confident number computed from a
    # partial view.
    claimed="$(claimed_set)" || {
      printf 'claim-version: dry-run HALT — claimed_set() failed (cannot read authoritative claimed state); no candidate reported\n' >&2
      exit 1
    }
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
  # The REAL repo root, captured before any fixture reassigns CLAIM_REPO_ROOT.
  # The package fixtures copy the actual builder + resolver out of it so they
  # exercise the REAL --skills-for-paths query rather than a restatement of it.
  local _ST_REAL_ROOT="$CLAIM_REPO_ROOT"

  # Assertion helpers are defined FIRST (ahead of the fixture seams) because the
  # pre-stub fixtures — U-0 and U-14a, which must run against the REAL host seams
  # before the stubs shadow them — need them too.
  _ct_fail() { echo "FAIL [$_t_label]: $*"; failures=$((failures+1)); }
  _ct_eq()   { [[ "$1" == "$2" ]] || _ct_fail "expected '$2' got '$1' ($3)"; }

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
  # Columns are pinned by HEADER NAME (#4339 R2 — convergence with deploy.sh). The
  # anti-vacuity legs are the point: (a) alone would pass on a Tag cell that happens
  # to read DEPLOYED, and (a)+(b) alone would pass on a hardcoded ordinal $8. Leg (c)
  # pins that the value read is the STATE cell, not the Tag; leg (d) SHIFTS the column
  # order, which only a name-pinned parser survives; leg (e) pins that an unreadable
  # schema is reported rather than presenting as an empty arm.
  _t_label="U-0 real RELEASE_LOG parser (columns pinned by header NAME)"
  {
    local _u0d; _u0d="$(mktemp -d "${TMPDIR:-/tmp}/claim-version-u0.XXXXXX")"
    mkdir -p "$_u0d/release/releases"
    local _u0log="$_u0d/release/releases/RELEASE_LOG.md"
    local _u0out _u0err _u0rc

    # (a)/(b) canonical schema: the DEPLOYED row is extracted, the VERIFIED row is not.
    # Prose pipes above the table prove the header scan skips non-schema pipe rows.
    printf '%s\n' \
      'Prose that | contains | pipes | before the table.' \
      '| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |' \
      '|---|---|---|---|---|---|---|---|' \
      '| v9.01 | m-verified | #1 | #2 | aaa | v9.01 | VERIFIED | 2026-07-18 |' \
      '| v9.02 | m-deployed | #3 | #4 | bbb | v9.02 | DEPLOYED | 2026-07-19 |' \
      > "$_u0log"
    _u0out="$(CLAIM_REPO_ROOT="$_u0d" _host_release_log_deployed 2>/dev/null)"
    grep -qx 'v9.02' <<< "$_u0out" || _ct_fail "U-0(a) must extract the DEPLOYED row v9.02 (State by name)"
    grep -qx 'v9.01' <<< "$_u0out" && _ct_fail "U-0(b) must NOT extract the VERIFIED row v9.01"

    # (c) anti-vacuity: the literal DEPLOYED sits in the TAG column of an otherwise-
    #     VERIFIED row. A name-pinned read ignores it; an ordinal read is fooled.
    printf '%s\n' \
      '| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |' \
      '|---|---|---|---|---|---|---|---|' \
      '| v9.03 | m-tagtrap | #5 | #6 | ccc | DEPLOYED | VERIFIED | 2026-07-19 |' \
      > "$_u0log"
    _u0out="$(CLAIM_REPO_ROOT="$_u0d" _host_release_log_deployed 2>/dev/null)"
    grep -qx 'v9.03' <<< "$_u0out" && _ct_fail "U-0(c) a DEPLOYED-valued TAG cell on a VERIFIED row must not be read as State"

    # (d) anti-vacuity: SHIFTED column order. Any ordinal pin breaks here; a
    #     name-pinned parser keeps working. This is what makes the fix durable
    #     rather than a one-time correction of one instance.
    printf '%s\n' \
      '| Version | State | Milestone | Issues | Release PR | Merge SHA | Tag | Date |' \
      '|---|---|---|---|---|---|---|---|' \
      '| v9.04 | DEPLOYED | m-shifted | #7 | #8 | ddd | v9.04 | 2026-07-19 |' \
      '| v9.05 | VERIFIED | m-shifted | #9 | #10 | eee | v9.05 | 2026-07-19 |' \
      > "$_u0log"
    _u0out="$(CLAIM_REPO_ROOT="$_u0d" _host_release_log_deployed 2>/dev/null)"
    grep -qx 'v9.04' <<< "$_u0out" || _ct_fail "U-0(d) a re-ordered header must still resolve State by NAME (v9.04 missing)"
    grep -qx 'v9.05' <<< "$_u0out" && _ct_fail "U-0(d) a re-ordered header must still exclude VERIFIED (v9.05 wrongly included)"

    # (e) unreadable schema -> REPORTED (non-zero rc + stderr), never a silent empty arm.
    printf '%s\n' \
      '| Release | Milestone | Status |' \
      '|---|---|---|' \
      '| v9.06 | m-noheader | DEPLOYED |' \
      > "$_u0log"
    _u0rc=0; _u0out="$(CLAIM_REPO_ROOT="$_u0d" _host_release_log_deployed 2>/dev/null)" || _u0rc=$?
    [[ "$_u0rc" -ne 0 ]] || _ct_fail "U-0(e) an unresolvable Version+State header must return non-zero, not a silently-empty arm"
    _u0rc=0; _u0err="$(CLAIM_REPO_ROOT="$_u0d" _host_release_log_deployed 2>&1 1>/dev/null)" || _u0rc=$?
    grep -q 'Version+State' <<< "$_u0err" || _ct_fail "U-0(e) an unresolvable header must be named on stderr"

    # (f) negative control for (e): a MISSING RELEASE_LOG is rc 0 (absence is not
    #     drift — greenfield has no log). Without this, (e) would also pass on a
    #     parser hardwired to fail.
    rm -f "$_u0log"
    _u0rc=0; _u0out="$(CLAIM_REPO_ROOT="$_u0d" _host_release_log_deployed 2>/dev/null)" || _u0rc=$?
    _ct_eq "$_u0rc" "0" "U-0(f) control: a MISSING RELEASE_LOG is rc 0 (absence is not drift)"
    _ct_eq "$_u0out" "" "U-0(f) control: a missing RELEASE_LOG emits no rows"
    rm -rf "$_u0d"
  }

  # ----- U-0b: REAL _host_origin_tags rc contract (#4339) -----------------------
  # Runs BEFORE the stub seams below shadow _host_origin_tags, so it exercises the
  # ACTUAL production body. Hermetic by construction: both remotes are LOCAL paths
  # on disk, so no network call occurs in either leg.
  #
  # The two legs ARE the fixture. A failed read and a tagless repo both present as
  # empty stdout; only the rc separates them — and before this fix BOTH answered
  # rc 0, so the probe could not produce two different answers at all. That is
  # precisely why the pre-existing suite could not have caught this defect: there
  # was no observable on which a test could discriminate.
  _t_label="U-0b real _host_origin_tags rc contract (failed read vs. tagless repo)"
  {
    local _u0bd; _u0bd="$(mktemp -d "${TMPDIR:-/tmp}/claim-version-u0b.XXXXXX")"
    local _rc _out _err

    # (a) GENUINELY-FAILING remote: `origin` points at a path that does not exist,
    #     which is the rc=128 condition #4339 reproduces.
    git -C "$_u0bd" init -q broken >/dev/null 2>&1
    git -C "$_u0bd/broken" remote add origin "$_u0bd/does-not-exist.git"
    # PROBE CONTROL: assert the raw read genuinely fails first. Without this the
    # leg below could go green against a fixture that never drove a real failure —
    # a test that cannot fail is the defect this release is about.
    _rc=0; ( cd "$_u0bd/broken" && git ls-remote --tags origin ) >/dev/null 2>&1 || _rc=$?
    [[ "$_rc" -ne 0 ]] || _ct_fail "U-0b probe control: raw git ls-remote must FAIL against a non-existent remote (the fixture is not driving a real failure)"

    _rc=0; _out="$( cd "$_u0bd/broken" && _host_origin_tags 2>/dev/null )" || _rc=$?
    [[ "$_rc" -ne 0 ]] || _ct_fail "U-0b a FAILED origin read must return non-zero (rc=0 means the seam is still reporting the PIPELINE's status — sort's — instead of git's)"
    _ct_eq "$_out" "" "U-0b a failed origin read emits no tags"
    _rc=0; _err="$( cd "$_u0bd/broken" && _host_origin_tags 2>&1 1>/dev/null )" || _rc=$?
    grep -qi 'HALT' <<< "$_err" || _ct_fail "U-0b the failure must be OBSERVABLE — stderr must name the HALT (2>/dev/null discarding it was half the defect)"

    # (b) NEGATIVE CONTROL — a genuinely TAGLESS repo. Same empty stdout, rc 0. This
    #     leg is what proves the probe can produce BOTH answers, and it is also the
    #     greenfield-regression guard: a guard that also failed a tagless repo would
    #     break every greenfield claim rather than fix anything.
    git init -q --bare "$_u0bd/empty.git" >/dev/null 2>&1
    git -C "$_u0bd" init -q tagless >/dev/null 2>&1
    git -C "$_u0bd/tagless" remote add origin "$_u0bd/empty.git"
    _rc=0; _out="$( cd "$_u0bd/tagless" && _host_origin_tags 2>/dev/null )" || _rc=$?
    _ct_eq "$_rc" "0" "U-0b control: a TAGLESS repo must answer rc 0 (empty is a VALID answer when the read succeeded)"
    _ct_eq "$_out" "" "U-0b control: a tagless repo emits no tags"

    # (c) NEGATIVE CONTROL — a repo WITH tags still parses. Without this leg, (a) and
    #     (b) would both pass on a seam that returns empty unconditionally.
    git -C "$_u0bd/tagless" -c user.email=selftest@example.invalid -c user.name=selftest \
        -c commit.gpgsign=false commit -q --allow-empty -m seed >/dev/null 2>&1
    git -C "$_u0bd/tagless" -c tag.gpgsign=false tag v9.11 >/dev/null 2>&1
    git -C "$_u0bd/tagless" push -q origin v9.11 >/dev/null 2>&1
    _rc=0; _out="$( cd "$_u0bd/tagless" && _host_origin_tags 2>/dev/null )" || _rc=$?
    _ct_eq "$_rc" "0" "U-0b control: a healthy read WITH tags is rc 0"
    grep -qx 'v9.11' <<< "$_out" || _ct_fail "U-0b control: a healthy read must still parse the bare tag name (the seam is not returning empty unconditionally)"

    rm -rf "$_u0bd"
  }

  # ----- U-14a: REAL seam rc contract when repo identity is unresolvable --------
  # Runs BEFORE the stub seams below shadow _host_published_tags/_host_latest_release,
  # so it exercises the ACTUAL production bodies. Hermetic by construction: with
  # resolution failing, `gh api` is NEVER reached, so no network call occurs. The
  # prior `: "${CLAIM_REPO:?…}"` idiom could not be caught here at all — the stub
  # shadowed the assertion, which is exactly why CI stayed green through the defect.
  _t_label="U-14a real seam rc contract (unresolvable repo identity)"
  {
    local _save_repo="${CLAIM_REPO:-}"
    local _rc _out _err

    # (1) Env tier of the REAL resolver wins and short-circuits before any host
    #     call — this is what keeps the caller cascade at zero.
    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    CLAIM_REPO="acme/widget"
    _rc=0; _out="$(_host_resolve_repo 2>/dev/null)" || _rc=$?
    _ct_eq "$_rc" "0" "U-14a env tier resolves rc 0"
    _ct_eq "$_out" "acme/widget" "U-14a env tier echoes CLAIM_REPO verbatim"

    # (2) Hard-fail tier: CLAIM_REPO unset AND `gh repo view` unavailable. `gh` is
    #     shadowed by a local function so no real host call can occur; it is unset
    #     immediately after, leaving the rest of the suite untouched.
    CLAIM_REPO=""
    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    gh() { return 127; }
    _rc=0; _out="$(_host_resolve_repo 2>/dev/null)" || _rc=$?
    [[ "$_rc" -ne 0 ]] || _ct_fail "U-14a unresolvable repo identity must return non-zero"
    _ct_eq "$_out" "" "U-14a unresolvable resolution emits nothing on stdout"

    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    _rc=0; _err="$(_host_resolve_repo 2>&1 1>/dev/null)" || _rc=$?
    grep -q 'CLAIM_REPO' <<< "$_err" || _ct_fail "U-14a diagnostic must name CLAIM_REPO"
    grep -qi 'HALT' <<< "$_err" || _ct_fail "U-14a diagnostic must name the HALT"

    # (3) Failure memo: the diagnostic prints ONCE, not once per seam call. The
    #     original defect surfaced as a DOUBLED message (two seam reaches per attempt).
    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    _rc=0; _err="$( { _host_resolve_repo; _host_resolve_repo; } 2>&1 1>/dev/null )" || _rc=$?
    _ct_eq "$(grep -c 'cannot resolve the repo host identity' <<< "$_err" | tr -d ' ')" "1" \
           "U-14a failure is memoized — diagnostic prints once, not per call"

    # (4) The REAL published-arm seams propagate the failure as an rc. This is the
    #     defect: previously they yielded an EMPTY arm with rc 0.
    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    _rc=0; _out="$(_host_published_tags 2>/dev/null)" || _rc=$?
    [[ "$_rc" -ne 0 ]] || _ct_fail "U-14a REAL _host_published_tags must return non-zero (not empty-with-rc-0)"
    _ct_eq "$_out" "" "U-14a REAL _host_published_tags emits no tags"

    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    _rc=0; _out="$(_host_latest_release 2>/dev/null)" || _rc=$?
    [[ "$_rc" -ne 0 ]] || _ct_fail "U-14a REAL _host_latest_release must return non-zero"

    # (5) claimed_set() rc-checks the arm and refuses to answer on a partial view.
    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    _rc=0; _out="$(claimed_set 2>/dev/null)" || _rc=$?
    [[ "$_rc" -ne 0 ]] || _ct_fail "U-14a claimed_set must return non-zero when the published arm is unavailable"
    _ct_eq "$_out" "" "U-14a claimed_set emits no claimed versions on a partial view"

    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    _rc=0; _err="$(claimed_set 2>&1 1>/dev/null)" || _rc=$?
    grep -qi 'partial view' <<< "$_err" || _ct_fail "U-14a claimed_set must name the partial-view refusal"

    # (6) anchor() must not read a FAILED claimed_set as a greenfield EMPTY one.
    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
    _rc=0; _out="$(anchor 2>/dev/null)" || _rc=$?
    [[ "$_rc" -ne 0 ]] || _ct_fail "U-14a anchor must return non-zero on an unavailable published arm"

    unset -f gh
    CLAIM_REPO="$_save_repo"
    _CLAIM_REPO_RESOLVED=""; _CLAIM_REPO_RESOLVE_TRIED=0
  }

  # --- stub seams (override the real host I/O; all state via $_ST_DIR files) ---
  # The published-arm stubs MIRROR THE PRODUCTION CONTRACT (resolve-then-read, and
  # a programmable arm rc) rather than unconditionally succeeding. That fidelity is
  # what lets U-14/U-14b/U-15 exercise the fail-closed path hermetically; a stub
  # that always returns 0 would make the guard structurally untestable — the exact
  # blind spot that kept this defect green in CI.
  _host_resolve_repo() {
    local rc; rc="$(cat "$(_st_f resolve_rc)" 2>/dev/null || echo 0)"
    if [[ "$rc" -ne 0 ]]; then
      printf 'claim-version: HALT — cannot resolve the repo host identity (CLAIM_REPO unset)\n' >&2
      return "$rc"
    fi
    printf '%s\n' "$(cat "$(_st_f resolve_repo)" 2>/dev/null || echo 'acme/widget')"
  }
  # POST-EMIT rc knobs (published_rc / latest_rc), independent of the shared arm_rc.
  # arm_rc models "the arm is unavailable" — it returns BEFORE emitting and gates BOTH
  # seams together. The post-emit knobs model the other real shape: the host call
  # produced output and THEN failed (a paginated `gh api` that dies mid-walk). That
  # shape is what separates a caller's rc-CHECK from a downstream value guard — with
  # empty-output-on-failure the two are indistinguishable, which is exactly why the
  # anchor() rc-checks were removable with the suite staying green. Both default to 0,
  # so every pre-existing fixture behaves byte-identically.
  _host_published_tags() {
    _host_resolve_repo >/dev/null || return 1
    local rc; rc="$(cat "$(_st_f arm_rc)" 2>/dev/null || echo 0)"
    [[ "$rc" -eq 0 ]] || return "$rc"
    cat "$(_st_f published)" 2>/dev/null || true
    return "$(cat "$(_st_f published_rc)" 2>/dev/null || echo 0)"
  }
  _host_latest_release() {
    _host_resolve_repo >/dev/null || return 1
    local rc; rc="$(cat "$(_st_f arm_rc)" 2>/dev/null || echo 0)"
    [[ "$rc" -eq 0 ]] || return "$rc"
    cat "$(_st_f latest)" 2>/dev/null || true
    return "$(cat "$(_st_f latest_rc)" 2>/dev/null || echo 0)"
  }
  # Arms (2) and (3) MIRROR THE PRODUCTION RC CONTRACT (#4339) rather than
  # unconditionally succeeding. A stub that always returns 0 makes the guard
  # structurally untestable — it is how the sibling defect survived CI for its whole
  # life, and a `|| true` here would silently re-create it. Both knobs default to 0,
  # so every pre-existing fixture behaves byte-identically.
  #   origin_rc  !=0 -> the origin-tags read FAILED (vs. a tagless repo: rc 0, empty)
  #   deployed_rc !=0 -> the RELEASE_LOG schema was unreadable (vs. no DEPLOYED rows)
  _host_origin_tags() {
    local rc; rc="$(cat "$(_st_f origin_rc)" 2>/dev/null || echo 0)"
    [[ "$rc" -eq 0 ]] || {
      printf 'claim-version: HALT — _host_origin_tags cannot read origin tags (git ls-remote rc=%s); an unevaluable tag set is NOT an empty one\n' "$rc" >&2
      return "$rc"
    }
    cat "$(_st_f origin_tags)" 2>/dev/null || true
    return 0
  }
  _host_release_log_deployed() {
    local rc; rc="$(cat "$(_st_f deployed_rc)" 2>/dev/null || echo 0)"
    [[ "$rc" -eq 0 ]] || {
      printf 'claim-version: HALT — RELEASE_LOG header row has no Version+State columns; the DEPLOYED arm was not evaluated\n' >&2
      return "$rc"
    }
    cat "$(_st_f log_deployed)" 2>/dev/null || true
    return 0
  }
  # stamp seam: record the follow-on stamp commit message; never a real add/commit/
  # push. The REAL _stamp_release_identity still runs (git mv + sed on a sandbox
  # tree), so U-11/U-13 exercise the substitution + rename hermetically.
  # Records the commit MESSAGE (as before) and now also the committed PATH list,
  # so a fixture can assert that a rebuilt package + its .sha256 sidecar ride the
  # SAME stamp commit rather than a follow-on one — the atomicity property.
  _host_commit_push()          { printf '%s\n' "$1" >> "$(_st_f stamp_commits)"; shift
                                 [[ $# -gt 0 ]] && printf '%s\n' "$@" >> "$(_st_f commit_paths)"
                                 return 0; }
  # package-rebuild seam: record the skills it was asked to rebuild and return the
  # configured rc. NEVER invokes the real builder, so no fixture run can write into
  # any packages/ directory. rebuild_rc drives the fail-loud error-path fixture.
  _host_rebuild_packages()     { printf '%s\n' "$@" >> "$(_st_f rebuild_calls)"
                                 return "$(cat "$(_st_f rebuild_rc)" 2>/dev/null || echo 0)"; }

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
    # Host-identity + arm-availability fixture state. Default = resolvable arm
    # that succeeds, so every pre-existing fixture behaves byte-identically.
    printf '0\n' > "$(_st_f resolve_rc)"; printf '0\n' > "$(_st_f arm_rc)"
    printf '0\n' > "$(_st_f published_rc)"; printf '0\n' > "$(_st_f latest_rc)"
    # Arm-(2)/(3) availability knobs (#4339). Default 0 = the arm READ SUCCEEDED,
    # so an empty fixture means "genuinely nothing", never "the read failed".
    printf '0\n' > "$(_st_f origin_rc)"; printf '0\n' > "$(_st_f deployed_rc)"
    printf 'acme/widget\n' > "$(_st_f resolve_repo)"
    local kv k v
    for kv in "$@"; do
      k="${kv%%=*}"; v="${kv#*=}"
      case "$k" in
        latest)     printf '%s\n' "$v" > "$(_st_f latest)";;
        published)  printf '%s\n' "$v" | tr ' ' '\n' | sed '/^$/d' > "$(_st_f published)";;
        origin)     printf '%s\n' "$v" | tr ' ' '\n' | sed '/^$/d' > "$(_st_f origin_tags)";;
        deployed)   printf '%s\n' "$v" | tr ' ' '\n' | sed '/^$/d' > "$(_st_f log_deployed)";;
        fetch_rc)   printf '%s\n' "$v" > "$(_st_f fetch_rc)";;
        plan)       printf '%s\n' "$v" > "$(_st_f push_plan)";;      # NB: pass via $'...\n...'
        advance)    printf '%s\n' "$v" > "$(_st_f advance)";;
        resolve_rc) printf '%s\n' "$v" > "$(_st_f resolve_rc)";;     # !=0 -> repo identity unresolvable
        arm_rc)     printf '%s\n' "$v" > "$(_st_f arm_rc)";;         # !=0 -> published arm UNAVAILABLE (vs. empty)
        published_rc) printf '%s\n' "$v" > "$(_st_f published_rc)";; # !=0 -> published arm emits, THEN fails (partial view)
        latest_rc)  printf '%s\n' "$v" > "$(_st_f latest_rc)";;      # !=0 -> latest-release seam emits, THEN fails
        origin_rc)  printf '%s\n' "$v" > "$(_st_f origin_rc)";;      # !=0 -> origin-tags READ failed (vs. tagless repo)
        deployed_rc) printf '%s\n' "$v" > "$(_st_f deployed_rc)";;   # !=0 -> RELEASE_LOG schema unreadable (vs. no DEPLOYED rows)
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

  # (_ct_fail / _ct_eq are defined at the top of this function — the pre-stub
  #  fixtures U-0 and U-14a need them before the fixture seams exist.)
  # _ct_run captures stdout into REPLY and the rc into REPLY_RC without letting a
  # non-zero exit trip `set -e` (a failing $(...) in an assignment aborts under
  # set -e — many fixtures EXPECT non-zero, so this guard is required).
  _ct_run()    { REPLY_RC=0; REPLY="$("$@" 2>/dev/null)" || REPLY_RC=$?; }
  _ct_run_err(){ REPLY_RC=0; REPLY="$("$@" 2>&1 1>/dev/null)" || REPLY_RC=$?; }

  # _st_stamp_sandbox <slug>  — create a fresh temp git repo carrying a pre-claim
  #   plan with the {{RELEASE_VERSION}} token; echo its root. Lets the REAL
  #   _stamp_release_identity git mv/sed run hermetically (the _host_commit_push
  #   stub records instead of pushing). Signing is disabled so the seed commit never
  #   depends on the operator's gpg config, and a fresh init carries no hooks.
  _st_stamp_sandbox() {
    local slug="$1" root
    root="$(mktemp -d "${TMPDIR:-/tmp}/claim-version-stamp.XXXXXX")"
    mkdir -p "$root/release/releases/plans"
    printf '%s\n' '---' 'version: {{RELEASE_VERSION}}' 'type: plan' '---' \
      '# Release Plan {{RELEASE_VERSION}}' 'Body cites {{RELEASE_VERSION}} once more.' \
      > "$root/release/releases/plans/${slug}_RELEASE_PLAN.md"
    git -C "$root" init -q
    git -C "$root" config user.email "selftest@example.invalid"
    git -C "$root" config user.name "claim-version-selftest"
    git -C "$root" config commit.gpgsign false
    git -C "$root" config tag.gpgsign false
    git -C "$root" add -A
    git -C "$root" commit -qm "seed" >/dev/null 2>&1
    printf '%s\n' "$root"
  }
  # _st_stamp_n  — count of recorded stamp commits.
  _st_stamp_n() { awk 'NF{n++} END{print n+0}' "$(_st_f stamp_commits)" 2>/dev/null || echo 0; }

  # _st_pkg_sandbox <slug>  — a stamp sandbox that ALSO carries a packaged-skill
  #   surface, for the U-18 family. On top of _st_stamp_sandbox it installs:
  #     - a REAL copy of core/deploy/tools/build-skill-packages.sh and the REAL
  #       core/deploy/lib-template-sync-source.sh resolver, so the fixtures
  #       exercise the ACTUAL --skills-for-paths rules rather than a restatement
  #       of them (a restated resolver would pass while the shipped one is broken);
  #     - a stub core/deploy/deploy.sh exposing a TEMPLATE_SYNC_MAP and the three
  #       per-module roster arrays the query needs — the same stub-roster idiom
  #       check-canonical-structure.sh's own self-test uses;
  #     - one skill whose SKILL.md carries {{RELEASE_VERSION}} in its BODY and a
  #       conforming literal on its version: line. That pairing is deliberate and
  #       is the correct one: a token ON the version: line is the cross-grammar
  #       hazard the pre-flight rejects, and U-18c asserts that rejection.
  #   Only the build + commit seams are stubbed; the query runs for real.
  _st_pkg_sandbox() {
    local slug="$1" root
    root="$(_st_stamp_sandbox "$slug")"
    mkdir -p "$root/core/deploy/tools" "$root/core/standards" "$root/packages" \
             "$root/operations/skills/fixtureops" "$root/release/skills/fixturerel" \
             "$root/core/skills/fixturecore"
    cp "$_ST_REAL_ROOT/core/deploy/tools/build-skill-packages.sh" "$root/core/deploy/tools/"
    cp "$_ST_REAL_ROOT/core/deploy/lib-template-sync-source.sh"   "$root/core/deploy/"
    cat > "$root/core/deploy/deploy.sh" <<'PKGSTUB'
TEMPLATE_SYNC_MAP=(
  "fixtureops:output-format.md:references/output-format.md"
  "fixturerel:output-format.md:references/output-format.md"
)
OPERATIONS_SKILLS=(
  fixtureops
)
RELEASE_SKILLS=(
  fixturerel
)
CORE_SKILLS=(
  fixturecore
)
PKGSTUB
    printf '%s\n' '# Fixture canonical' > "$root/core/standards/output-format.md"
    printf '%s\n' '---' 'name: fixtureops' 'description: fixture' 'version: v1.00' '---' \
      '# Fixtureops' 'Shipped in {{RELEASE_VERSION}}.' \
      > "$root/operations/skills/fixtureops/SKILL.md"
    git -C "$root" add -A
    git -C "$root" commit -qm "pkg fixture" >/dev/null 2>&1
    printf '%s\n' "$root"
  }

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
  grep -qiE 'contended.*loss|HALT' <<< "$err" || _ct_fail "U-4 stderr should name contended-loss HALT"
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
  grep -qx 'v3.20' <<< "$cs" && _ct_fail "U-5 claimed_set must EXCLUDE orphan v3.20"
  grep -qx 'v2.15' <<< "$cs" || _ct_fail "U-5 claimed_set must INCLUDE mainline v2.15"

  # ---- U-6: never-bypass signing — push uses -a, no bypass flag, no --force ----
  _t_label="U-6 never-bypass signing (no -s/-c bypass/--force)"
  # Assert against the REAL _host_push_tag (the production seam), not the stub:
  # extract its definition from the source between its def and the next function.
  # The awk self-terminates at the seam's closing brace, so no output bound is
  # needed; the `| head -N` this once carried was itself a SIGPIPE hazard under
  # `set -o pipefail` (see the plumbing note below) for no benefit.
  local real_push
  real_push="$(awk '/^_host_push_tag\(\) \{/{f=1} f{print} f&&/^}/{exit}' "${BASH_SOURCE[0]}")"
  local exec_lines force_re
  exec_lines="$(sed -E 's/[[:space:]]*#.*$//' "${BASH_SOURCE[0]}" | sed -E '/^[[:space:]]*$/d')"

  # ANTI-VACUITY: every assertion below is a grep for a REQUIRED or FORBIDDEN
  # string. If a subject were empty — the awk anchor drifts, or BASH_SOURCE does
  # not resolve — the "required" greps would find nothing (fail loudly) but the
  # "forbidden" greps would find nothing too and pass while testing NOTHING. Bind
  # both subjects to non-empty first, so a broken extraction reports itself instead
  # of half-silently disarming the guard.
  [[ -n "$real_push"  ]] || _ct_fail "U-6 could not extract the real _host_push_tag seam — assertions would be vacuous"
  [[ -n "$exec_lines" ]] || _ct_fail "U-6 could not read this script's executable lines — assertions would be vacuous"

  # PLUMBING (#4224): each probe reads its subject from a HERESTRING, never from
  # `printf ... | grep -q`. Under this script's `set -o pipefail` a `grep -q` that
  # matches EARLY exits before printf has finished writing; printf then takes EPIPE
  # and pipefail promotes printf's non-zero status to the pipeline's — so a
  # SUCCESSFUL match reported FAILURE and `|| _ct_fail` fired. exec_lines is ~28 KB,
  # past the pipe capacity, so the write blocks and the race was live: this block
  # was the source of both the intermittent macOS-runner red and the stray
  # `printf: write error: Broken pipe`. A herestring gives grep a pre-filled input,
  # so there is no writer left to signal.
  grep -qE 'git tag -a -m' <<< "$real_push" \
    || _ct_fail "U-6 real push must use 'git tag -a -m' (signed-annotated)"
  grep -qE -- '--no-gpg-sign|tag\.gpgsign=false|GIT_CONFIG_PARAMETERS|git tag -s' <<< "$real_push" \
    && _ct_fail "U-6 real push must NOT contain a signing-bypass flag"
  # No EXECUTABLE (non-comment) line may push with --force/-f or --delete. Strip
  # comment lines first so the header prose and this check's own pattern text are
  # not counted — only real invocations are asserted. The optional `-C <dir>`
  # segment matters: the stamp seam invokes `git -C <root> push`, so a regex
  # anchored on a bare `git push` was BLIND to a forced push introduced in that
  # form. --delete is asserted too — the header states the claim is create-only,
  # and a deleted tag is as destructive as an overwritten one.
  # (Failure messages below deliberately avoid the literal forbidden tokens so the
  # grep over this very file cannot match its own assertion text.)
  force_re='git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push[^|]*(--'"force"'|--'"delete"'|[[:space:]]-f([[:space:]]|$))'
  grep -qE "$force_re" <<< "$exec_lines" \
    && _ct_fail "U-6 no executable line may force-push or remove the tag"
  # And the one real push must be the create-only <src>:<dst> refspec form. This
  # reads the SEAM, not exec_lines: exec_lines is this whole file, which contains
  # this assertion's own pattern text, so the check matched itself and could never
  # fail — a tautology, green even with the real push replaced by an overwrite-
  # capable bare-tag push (mutation M6, #4224). Scoping to $real_push both removes
  # the self-match and states the real contract, and the src:dst pair is asserted
  # rather than just the "refs/tags/" prefix, because it is the fully-qualified
  # destination that makes the push create-only.
  grep -qE 'git push origin "refs/tags/[^"]*:refs/tags/' <<< "$real_push" \
    || _ct_fail "U-6 the real push must be the create-only refspec form"

  # ---- U-6b: detector negative control — U-6's probes must still be able to say NO --
  # A fixture that cannot fail is not a guard. U-6 is four pattern probes over this
  # file's own text; if one silently stopped matching a violation it would read green forever
  # while proving nothing — the same fail-open class release-tooling-smoke.yml
  # already defends its peer gates against with precision probes. Run the SAME
  # patterns against deliberately-violating subjects held in memory (nothing on
  # disk is touched, no git command runs) and assert each reaches the OPPOSITE
  # verdict. Subjects are assembled by CONCATENATION so no forbidden literal ever
  # lands on an executable line of this file — U-6 greps this file, and a literal
  # here would make the guard trip over its own control.
  _t_label="U-6b detector negative control (U-6 can still fail)"
  local _bypass='--no-gpg'"-sign" _forced='--'"force" _removed='--'"delete"
  local bad_seam bad_force bad_force_dashc
  bad_seam="$(printf '%s\n' '_host_push_tag() {' "  git tag -s ${_bypass} -m \"m\" t sha" '}')"
  bad_force="git push origin ${_forced} \"refs/tags/x:refs/tags/x\""
  bad_force_dashc="git -C /some/root push origin ${_removed} \"refs/tags/x\""
  grep -qE 'git tag -a -m' <<< "$bad_seam" \
    && _ct_fail "U-6b signed-annotated probe matched a seam that never annotates — probe is disarmed"
  grep -qE -- '--no-gpg-sign|tag\.gpgsign=false|GIT_CONFIG_PARAMETERS|git tag -s' <<< "$bad_seam" \
    || _ct_fail "U-6b bypass probe failed to flag a signing-bypass seam — probe is disarmed"
  grep -qE "$force_re" <<< "$bad_force" \
    || _ct_fail "U-6b force probe failed to flag a forced tag push — probe is disarmed"
  grep -qE "$force_re" <<< "$bad_force_dashc" \
    || _ct_fail "U-6b force probe failed to flag the 'git -C <dir>' push form — probe is disarmed"
  grep -qE 'git push origin "refs/tags/[^"]*:refs/tags/' <<< "$bad_seam" \
    && _ct_fail "U-6b create-only-refspec probe matched a subject with no tag push — probe is disarmed"
  # The probe must also reject an overwrite-capable bare-tag push (mutation M6):
  # matching only the "refs/tags/" prefix would let that through.
  grep -qE 'git push origin "refs/tags/[^"]*:refs/tags/' <<< 'git push origin "${tag}"' \
    && _ct_fail "U-6b create-only-refspec probe accepted a bare-tag push — probe is disarmed"

  # ---- U-7: NON-collision push failure (network) -> immediate HARD HALT ----
  _t_label="U-7 network failure -> immediate HALT (no recompute)"
  _ct_setup latest="v2.15" published="v2.15" origin="v2.15" \
            plan="fatal: unable to access 'https://github.example/...': Could not resolve host: github.example"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-7 expected non-zero exit"
  _ct_eq "$(_ct_push_idx)" "1" "U-7 exactly 1 attempt (NOT retried as contention)"
  grep -qi 'Could not resolve host' <<< "$err" || _ct_fail "U-7 must surface the raw host error"
  grep -qiE 'not a CAS collision|no recompute' <<< "$err" || _ct_fail "U-7 must say it is not a collision"
  grep -qiE 'contended.*loss' <<< "$err" && _ct_fail "U-7 must NOT report contended-loss (false diagnosis)"
  _ct_eq "$(_ct_local_n)" "0" "U-7 no orphan local tag after HALT"

  # ---- U-8: SIGNING failure -> immediate HALT, no recompute, no orphan tags ----
  _t_label="U-8 signing failure -> immediate HALT (never-bypass preserved)"
  _ct_setup latest="v2.15" published="v2.15" origin="v2.15" \
            plan="error: gpg failed to sign the data\nfatal: failed to write commit object"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-8 expected non-zero exit"
  _ct_eq "$(_ct_push_idx)" "1" "U-8 exactly 1 attempt (signing failure NOT retried)"
  grep -qi 'gpg failed to sign' <<< "$err" || _ct_fail "U-8 must surface the raw signing error"
  grep -qiE 'contended.*loss' <<< "$err" && _ct_fail "U-8 must NOT report contended-loss"
  _ct_eq "$(_ct_pushed_n)" "0" "U-8 nothing pushed to origin"
  _ct_eq "$(_ct_local_n)" "0" "U-8 no orphan local tags (cleaned up)"

  # ---- U-9: fetch failure -> HALT (no stale-tip recompute) ----
  _t_label="U-9 fetch failure -> HALT (FMF-3)"
  _ct_setup latest="v2.15" published="v2.15" origin="v2.15" fetch_rc=7 plan="ok"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-9 expected non-zero exit on fetch failure"
  _ct_eq "$(_ct_push_idx)" "0" "U-9 zero push attempts (HALT before push)"
  grep -qi 'fetch failed' <<< "$err" || _ct_fail "U-9 must name the fetch failure"

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
  grep -qx 'v2.39' <<< "$cs10" || _ct_fail "U-10 claimed_set must INCLUDE pushed mainline tag v2.39"
  # ... and anchor() must report the pushed frontier v2.39, not the lagging
  # published-latest v2.38 (the contract: highest CLAIMED version in the lineage).
  _ct_eq "$(anchor)" "v2.39" "U-10 anchor() = pushed frontier v2.39, not published-latest v2.38"
  # The genuine stray stays excluded even alongside the pushed mainline tag (so the
  # fix is a RE-KEY of the orphan filter, not its removal — v3.20 must not return):
  _ct_setup latest="v2.38" published="v2.37 v2.38" origin="v2.37 v2.38 v2.39 v3.20" plan="ok"
  local cs10b; cs10b="$(claimed_set)"
  grep -qx 'v2.39' <<< "$cs10b" || _ct_fail "U-10 claimed_set must INCLUDE v2.39 (stray present)"
  grep -qx 'v3.20' <<< "$cs10b" && _ct_fail "U-10 claimed_set must EXCLUDE genuine stray v3.20"

  # ---- U-11: claim-time stamp resolves {{RELEASE_VERSION}} + renames the plan ----
  # Unit-exercise the REAL _stamp_release_identity on a sandbox git tree (only the
  # _host_commit_push seam is stubbed): the slug plan is renamed to its versioned
  # home and the token is resolved to the won tag in the body.
  _t_label="U-11 claim-time stamp (substitute + rename)"
  {
    local _sb11; _sb11="$(_st_stamp_sandbox "widget-feature")"
    local _save11="$CLAIM_REPO_ROOT"
    : > "$(_st_f stamp_commits)"
    CLAIM_REPO_ROOT="$_sb11"; STAMP_FILES=()
    _ct_run _stamp_release_identity "v3.99" "widget-feature" "deadbeefcafe1234"
    CLAIM_REPO_ROOT="$_save11"
    _ct_eq "$REPLY_RC" "0" "U-11 stamp returns 0"
    [[ -f "$_sb11/release/releases/plans/v3/v3.99_RELEASE_PLAN.md" ]] || _ct_fail "U-11 plan must be renamed to plans/v3/v3.99_RELEASE_PLAN.md"
    [[ -f "$_sb11/release/releases/plans/widget-feature_RELEASE_PLAN.md" ]] && _ct_fail "U-11 slug-named plan must be gone after the git mv"
    grep -q 'v3\.99' "$_sb11/release/releases/plans/v3/v3.99_RELEASE_PLAN.md" 2>/dev/null || _ct_fail "U-11 body must carry the resolved version v3.99"
    grep -q '{{RELEASE_VERSION}}' "$_sb11/release/releases/plans/v3/v3.99_RELEASE_PLAN.md" 2>/dev/null && _ct_fail "U-11 no {{RELEASE_VERSION}} token may survive"
    _ct_eq "$(_st_stamp_n)" "1" "U-11 exactly one stamp commit"
    rm -rf "$_sb11"
  }

  # ---- U-12: no --stamp-slug -> stamping pass is skipped entirely ----
  # With STAMP_SLUG empty, claim_version behaves byte-identically to U-1 and does
  # NO stamp (backward-compatibility: every existing caller is unaffected).
  _t_label="U-12 no stamp-slug -> pass skipped"
  _ct_setup latest="v2.08" published="v2.06 v2.06.1 v2.07 v2.08" \
            origin="v2.06 v2.06.1 v2.07 v2.08" plan="ok"
  : > "$(_st_f stamp_commits)"
  STAMP_SLUG=""
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-12 exit 0"
  _ct_eq "$out" "v2.09" "U-12 returns v2.09 (unchanged from no-stamp behavior)"
  _ct_eq "$(_st_stamp_n)" "0" "U-12 no stamp commit when --stamp-slug absent"

  # ---- U-13: collision-then-win stamps ONCE with the WON tag (never the lost one) --
  # The collision-safety proof (the crux). Attempt 1 computes v2.16 and is REJECTED;
  # the tip advances; attempt 2 recomputes to v2.17 and wins. The stamp fires exactly
  # ONCE, renaming to plans/v2/v2.17_RELEASE_PLAN.md — NEVER v2.16 (the lost candidate
  # is never written). Runs the REAL _stamp_release_identity on a sandbox tree.
  _t_label="U-13 stamp binds the WON tag, once (collision-safe)"
  {
    local _sb13; _sb13="$(_st_stamp_sandbox "widget-x")"
    local _save13="$CLAIM_REPO_ROOT"
    _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
              plan="$(printf 'collision\nok')" advance="1|v2.16|v2.14 v2.15 v2.16"
    : > "$(_st_f stamp_commits)"
    CLAIM_REPO_ROOT="$_sb13"; STAMP_SLUG="widget-x"; STAMP_FILES=()
    _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
    STAMP_SLUG=""; CLAIM_REPO_ROOT="$_save13"
    _ct_eq "$rc" "0" "U-13 exit 0"
    _ct_eq "$out" "v2.17" "U-13 returns v2.17 (recomputed against advanced tip)"
    [[ -f "$_sb13/release/releases/plans/v2/v2.17_RELEASE_PLAN.md" ]] || _ct_fail "U-13 plan must be stamped to v2/v2.17_RELEASE_PLAN.md (the WON tag)"
    [[ -f "$_sb13/release/releases/plans/v2/v2.16_RELEASE_PLAN.md" ]] && _ct_fail "U-13 the LOST candidate v2.16 must NEVER be stamped"
    [[ -f "$_sb13/release/releases/plans/widget-x_RELEASE_PLAN.md" ]] && _ct_fail "U-13 slug plan must be gone after the win-path stamp"
    grep -q 'v2\.17' "$_sb13/release/releases/plans/v2/v2.17_RELEASE_PLAN.md" 2>/dev/null || _ct_fail "U-13 body must carry the resolved won version v2.17"
    _ct_eq "$(_st_stamp_n)" "1" "U-13 exactly ONE stamp commit (only on the win)"
    rm -rf "$_sb13"
  }

  # ---- U-14: fail-closed on unresolvable repo identity (the whole claim path) ----
  # The full CAS caller loop with the repo identity unresolvable. The claim MUST
  # HALT strictly BEFORE any push — the guard exists to stop a claim computed from
  # a partial collision set, so a HALT that happens after the tag is pushed is no
  # guard at all. Asserts push_idx == 0 (not merely "no successful push").
  _t_label="U-14 fail-closed on unresolvable repo identity"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="ok" resolve_rc=1
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-14 expected non-zero exit when repo identity is unresolvable"
  _ct_eq "$(_ct_push_idx)" "0" "U-14 ZERO push attempts (HALT strictly before the CAS)"
  _ct_eq "$(_ct_pushed_n)" "0" "U-14 nothing pushed to origin"
  _ct_eq "$(_ct_local_n)"  "0" "U-14 no orphan local tag"
  grep -q 'CLAIM_REPO' <<< "$err" || _ct_fail "U-14 stderr must name CLAIM_REPO (the unresolved input)"
  grep -qiE 'partial view|HALT' <<< "$err" || _ct_fail "U-14 stderr must name the HALT"
  # The dry-run DETECTOR rung must fail closed in lockstep with the prevention rung.
  _ct_run_err claimed_set; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-14 claimed_set must fail closed for the --dry-run path too"

  # ---- U-14b: detector negative control (U-14 can still pass) ----
  # Same shape with the identity RESOLVABLE and the arm carrying data: the claim
  # must succeed with exactly one push. Without this, U-14's non-zero assertion
  # could be vacuously green (a guard that fails everything is not a guard).
  _t_label="U-14b detector negative control (U-14 can still pass)"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="ok" resolve_rc=0
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-14b exit 0 when the repo identity resolves"
  _ct_eq "$out" "v2.16" "U-14b returns v2.16 (normal claim proceeds)"
  _ct_eq "$(_ct_push_idx)" "1" "U-14b exactly 1 push attempt"

  # ---- U-15: arm-UNAVAILABLE is not arm-EMPTY (the tri-state distinction) ----
  # This is what makes the wider `gh api`-failure trigger safe to close without
  # breaking greenfield. Both states present as an EMPTY published arm; only the
  # rc separates them, so the rc — never output-emptiness — must drive the verdict.
  #
  # (i) UNAVAILABLE: identity resolves, but the API call itself fails (auth expiry,
  #     rate limit, network). Ordinary operating conditions, and the MORE probable
  #     trigger than an unset env var.
  _t_label="U-15 arm unavailable (gh api failure) -> HALT"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="ok" resolve_rc=0 arm_rc=1
  _ct_run_err claimed_set; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-15 claimed_set must return non-zero when the published arm is UNAVAILABLE"
  grep -qi 'partial view' <<< "$err" || _ct_fail "U-15 claimed_set must name the partial-view refusal"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-15 expected non-zero exit on an unavailable published arm"
  _ct_eq "$(_ct_push_idx)" "0" "U-15 ZERO push attempts on an unavailable arm"
  _ct_eq "$(_ct_pushed_n)" "0" "U-15 nothing pushed to origin"
  _ct_eq "$(_ct_local_n)"  "0" "U-15 no orphan local tag"
  #
  # (ii) EMPTY (true greenfield): the arm is AVAILABLE and correctly reports no
  #      published Releases. The claim MUST proceed — a fail-closed guard that also
  #      blocks greenfield would be a regression, not a fix.
  _t_label="U-15 arm empty (true greenfield) -> claim proceeds"
  _ct_setup latest="v2.15" published="" origin="" plan="ok" resolve_rc=0 arm_rc=0
  _ct_run claimed_set; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-15 claimed_set rc 0 when the arm is available but EMPTY (greenfield)"
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-15 greenfield claim proceeds (exit 0)"
  _ct_eq "$out" "v2.16" "U-15 greenfield claims v2.16 off the latest-release anchor"
  _ct_eq "$(_ct_push_idx)" "1" "U-15 greenfield exactly 1 push attempt"

  # ---- U-16: anchor() rc-checks — a FAILED read is not a greenfield/valid one ----
  # DEV-4 added two rc-checks to anchor(): one on claimed_set(), one on the greenfield
  # _host_latest_release() fallback. Removing EITHER — or BOTH — left this suite fully
  # green (rc=0, 0 failures). What looked like coverage was the pre-existing downstream
  # `version_canonical ""` guard on a THIRD path that neither check owns: with the old
  # fixtures every failing seam also emitted nothing, so a dropped rc-check funnelled
  # into that guard and still exited non-zero. The distinction only becomes observable
  # when a seam emits a plausible value AND fails — hence the post-emit knobs above.
  # Both legs assert the OUTPUT, not just the rc: the harm is anchor() answering with a
  # frontier it could not actually establish, and every consumer of that answer
  # (claim_version's next-free computation) then allocates against a partial view.
  #
  # (a) claimed_set() FAILS having emitted a partial view; the greenfield fallback seam
  #     is healthy and would happily answer. Without the rc-check anchor() silently
  #     takes the fallback and returns a frontier BELOW the true one.
  _t_label="U-16 anchor() rc-checks claimed_set (partial view -> HALT, never the fallback)"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="ok" resolve_rc=0 arm_rc=0 published_rc=1 latest_rc=0
  _ct_run claimed_set; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-16(a) precondition: claimed_set must fail when the published arm fails post-emit"
  _ct_run anchor; out="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-16(a) anchor() must return non-zero when claimed_set() failed (rc=0 means the rc-check is gone and the greenfield fallback answered)"
  _ct_eq "$out" "" "U-16(a) anchor() must emit NO version on a failed claimed_set (a fallback answer here is the stale-frontier defect)"
  _ct_run_err anchor; err="$REPLY"
  grep -qi 'cannot read the claimed set' <<< "$err" || _ct_fail "U-16(a) anchor() must name the claimed-set read failure, not a downstream canonicality complaint"

  # (b) TRUE greenfield (claimed_set available and legitimately empty), but the
  #     latest-release seam emits a canonical-looking value AND fails. Without the
  #     rc-check `version_canonical` passes on that value and anchor() answers rc 0
  #     off a host call that did not succeed.
  _t_label="U-16 anchor() rc-checks the greenfield fallback (emitted-then-failed -> HALT)"
  _ct_setup latest="v2.15" published="" origin="" deployed="" \
            plan="ok" resolve_rc=0 arm_rc=0 published_rc=0 latest_rc=1
  _ct_run claimed_set; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-16(b) precondition: claimed_set is AVAILABLE and empty (true greenfield)"
  _ct_eq "$out" "" "U-16(b) precondition: the greenfield claimed_set is empty"
  _ct_run anchor; out="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-16(b) anchor() must return non-zero when the greenfield fallback seam failed (rc=0 means the rc-check is gone and a failed read was answered as authoritative)"
  _ct_eq "$out" "" "U-16(b) anchor() must emit NO version when the fallback seam failed"
  _ct_run_err anchor; err="$REPLY"
  grep -qi 'greenfield fallback' <<< "$err" || _ct_fail "U-16(b) anchor() must name the greenfield-fallback read failure"

  # (c) + (d) NEGATIVE CONTROLS. Without these, (a) and (b) would both pass on an
  #     anchor() hardwired to fail — the same vacuity this fixture exists to close.
  _t_label="U-16 control — healthy claimed_set answers the true frontier"
  _ct_setup latest="v2.10" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="ok" resolve_rc=0 arm_rc=0 published_rc=0 latest_rc=0
  _ct_run anchor; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-16(c) control: a healthy claimed_set must answer rc 0"
  _ct_eq "$out" "v2.15" "U-16(c) control: anchor() returns max(claimed_set), not the latest-release pointer"

  _t_label="U-16 control — healthy greenfield answers off the latest-release pointer"
  _ct_setup latest="v2.15" published="" origin="" deployed="" \
            plan="ok" resolve_rc=0 arm_rc=0 published_rc=0 latest_rc=0
  _ct_run anchor; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-16(d) control: healthy greenfield must answer rc 0"
  _ct_eq "$out" "v2.15" "U-16(d) control: greenfield anchor() falls back to the latest published release"

  # ---- U-17: arms (2)/(3) UNAVAILABLE is not arms (2)/(3) EMPTY (#4339) --------
  # U-15 established this tri-state distinction for the published arm. U-17 extends
  # the SAME contract to the other two arms of claimed_set() — it does not fork a
  # second convention. The claim path must refuse on a partial view no matter WHICH
  # arm went unevaluable, because the harm is identical: an origin-tags arm that is
  # empty-because-the-read-failed hides a concurrent claimer's pushed tag, and the
  # allocator then hands out a version that is already taken.
  #
  # Each leg asserts the PUSH COUNT, not merely the rc. That is the property that
  # actually matters: a guard that returns non-zero after already pushing a tag has
  # not prevented the collision, it has only reported it.
  _t_label="U-17 origin-tags arm UNAVAILABLE -> HALT (never a claim)"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="ok" resolve_rc=0 arm_rc=0 origin_rc=128
  _ct_run_err claimed_set; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-17 claimed_set must return non-zero when the origin-tags arm is UNAVAILABLE"
  grep -qi 'partial view' <<< "$err" || _ct_fail "U-17 claimed_set must name the partial-view refusal (same vocabulary as the published arm — one contract)"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-17 expected non-zero exit on an unavailable origin-tags arm"
  _ct_eq "$(_ct_push_idx)" "0" "U-17 ZERO push attempts on an unavailable origin-tags arm"
  _ct_eq "$(_ct_pushed_n)" "0" "U-17 nothing pushed to origin"
  _ct_eq "$(_ct_local_n)"  "0" "U-17 no orphan local tag"

  _t_label="U-17 RELEASE_LOG DEPLOYED arm UNAVAILABLE -> HALT (never a claim)"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15" \
            plan="ok" resolve_rc=0 arm_rc=0 deployed_rc=3
  _ct_run_err claimed_set; err="$REPLY"; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-17 claimed_set must return non-zero when the DEPLOYED arm is UNAVAILABLE"
  grep -qi 'partial view' <<< "$err" || _ct_fail "U-17 claimed_set must name the partial-view refusal for the DEPLOYED arm"
  _ct_run_err claim_version "deadbeefcafe" "minor" "" ""; rc="$REPLY_RC"
  [[ "$rc" -ne 0 ]] || _ct_fail "U-17 expected non-zero exit on an unavailable DEPLOYED arm"
  _ct_eq "$(_ct_push_idx)" "0" "U-17 ZERO push attempts on an unavailable DEPLOYED arm"

  # (c) DETECTOR NEGATIVE CONTROL — arms AVAILABLE and legitimately EMPTY. The claim
  #     must proceed. Without this leg the two above would pass on a claimed_set()
  #     hardwired to refuse, and the "guard" would be an outage.
  _t_label="U-17 control — arms available but EMPTY -> claim proceeds"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="" deployed="" \
            plan="ok" resolve_rc=0 arm_rc=0 origin_rc=0 deployed_rc=0
  _ct_run claimed_set; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-17(c) control: empty-but-AVAILABLE arms are rc 0 (empty is a valid answer)"
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-17(c) control: the claim proceeds when the arms merely have nothing to report"
  _ct_eq "$out" "v2.16" "U-17(c) control: claims v2.16"
  _ct_eq "$(_ct_push_idx)" "1" "U-17(c) control: exactly 1 push attempt"

  # (d) DETECTOR NEGATIVE CONTROL — the origin-tags arm CONTRIBUTES. This is the leg
  #     that proves the arm is actually read rather than merely rc-checked: v2.39 is
  #     a pushed-but-unpublished mainline tag present ONLY in the origin arm, and it
  #     must be claimed so the next-free lands at v2.40, not v2.16.
  _t_label="U-17 control — the origin-tags arm materially contributes to the claim"
  _ct_setup latest="v2.15" published="v2.14 v2.15" origin="v2.14 v2.15 v2.39" \
            plan="ok" resolve_rc=0 arm_rc=0 origin_rc=0
  _ct_run claimed_set; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$rc" "0" "U-17(d) control: healthy arms answer rc 0"
  grep -qx 'v2.39' <<< "$out" || _ct_fail "U-17(d) control: the origin-only tag v2.39 must be IN the claimed set (else the arm is not being read at all)"
  _ct_run claim_version "deadbeefcafe" "minor" "" ""; out="$REPLY"; rc="$REPLY_RC"
  _ct_eq "$out" "v2.40" "U-17(d) control: next-free must clear the origin-only claim v2.39 (this is the collision the fail-open would have caused)"

  # ---- U-18: a stamp that rewrites packaged source rebuilds that package, in the
  #      SAME commit. The gap this closes: the stamp resolves file CONTENT and had
  #      no package-rebuild step at all, so a stamped SKILL.md left Check 7 red on
  #      the mainline until someone remembered a hand-written per-release chore.
  _t_label="U-18 stamp rebuilds the package it staled (direct SKILL.md source)"
  {
    local _sb18; _sb18="$(_st_pkg_sandbox "widget-pkg")"
    local _save18="$CLAIM_REPO_ROOT"
    : > "$(_st_f stamp_commits)"; : > "$(_st_f rebuild_calls)"; : > "$(_st_f commit_paths)"
    printf '0\n' > "$(_st_f rebuild_rc)"
    CLAIM_REPO_ROOT="$_sb18"; STAMP_FILES=("operations/skills/fixtureops/SKILL.md")
    _ct_run _stamp_release_identity "v3.99" "widget-pkg" "deadbeefcafe1234"
    CLAIM_REPO_ROOT="$_save18"; STAMP_FILES=()
    _ct_eq "$REPLY_RC" "0" "U-18 stamp returns 0"
    _ct_eq "$(tr '\n' ' ' < "$(_st_f rebuild_calls)" | sed 's/ *$//')" "fixtureops" \
           "U-18 the rebuild seam is invoked with exactly the staled skill"
    grep -qx 'packages/fixtureops.skill' "$(_st_f commit_paths)" \
      || _ct_fail "U-18 the stamp commit must carry packages/fixtureops.skill"
    grep -qx 'packages/fixtureops.skill.sha256' "$(_st_f commit_paths)" \
      || _ct_fail "U-18 the stamp commit must carry the .sha256 content-baseline sidecar"
    _ct_eq "$(_st_stamp_n)" "1" "U-18 exactly ONE stamp commit — the rebuild rides it, never a follow-on"
    grep -q '{{RELEASE_VERSION}}' "$_sb18/operations/skills/fixtureops/SKILL.md" 2>/dev/null \
      && _ct_fail "U-18 the SKILL.md body token must be resolved by the stamp"
    rm -rf "$_sb18"
  }

  # ---- U-18b: THE v4.06 VECTOR. A TEMPLATE_SYNC_MAP canonical has no skills/
  #      path of its own, so stamping one stales every package it is injected into
  #      while touching zero skill paths. A resolver keyed only on skills/ paths
  #      returns empty here and the packages go stale silently — which is exactly
  #      what happened at v4.06, where the identity stamp staled three packages via
  #      canonicals. This fixture fails if rule (b) is missing or narrowed.
  _t_label="U-18b injected canonical stales EVERY mapped skill (the v4.06 vector)"
  {
    local _sb18b; _sb18b="$(_st_pkg_sandbox "widget-canon")"
    local _save18b="$CLAIM_REPO_ROOT"
    : > "$(_st_f stamp_commits)"; : > "$(_st_f rebuild_calls)"; : > "$(_st_f commit_paths)"
    printf '0\n' > "$(_st_f rebuild_rc)"
    CLAIM_REPO_ROOT="$_sb18b"; STAMP_FILES=("core/standards/output-format.md")
    _ct_run _stamp_release_identity "v3.99" "widget-canon" "deadbeefcafe1234"
    CLAIM_REPO_ROOT="$_save18b"; STAMP_FILES=()
    _ct_eq "$REPLY_RC" "0" "U-18b stamp returns 0"
    _ct_eq "$(tr '\n' ' ' < "$(_st_f rebuild_calls)" | sed 's/ *$//')" "fixtureops fixturerel" \
           "U-18b BOTH skills the canonical injects into must be rebuilt (a skills/-path-only resolver returns none)"
    grep -qx 'packages/fixturerel.skill.sha256' "$(_st_f commit_paths)" \
      || _ct_fail "U-18b the second injected skill's sidecar must also ride the stamp commit"
    _ct_eq "$(_st_stamp_n)" "1" "U-18b exactly ONE stamp commit"
    rm -rf "$_sb18b"
  }

  # ---- U-18c: CROSS-GRAMMAR GUARD + its discriminating control. {{RELEASE_VERSION}}
  #      resolves to the won RELEASE TAG, which may be three-component on a patch
  #      release; the skill version: grammar forbids a patch level. A token on a
  #      SKILL.md version: line is therefore rejected PRE-CAS — before the tag is
  #      irreversibly claimed — rather than surfacing as a red Check 6 afterwards.
  #      The control leg is what makes this a real test: a token elsewhere in the
  #      same file is a legitimate stamp target and must still pass.
  _t_label="U-18c cross-grammar guard rejects {{RELEASE_VERSION}} on a SKILL.md version: line"
  {
    local _sb18c; _sb18c="$(_st_pkg_sandbox "widget-grammar")"
    local _save18c="$CLAIM_REPO_ROOT"
    CLAIM_REPO_ROOT="$_sb18c"; STAMP_FILES=("operations/skills/fixtureops/SKILL.md")

    # CONTROL leg first: the shipped pairing (literal version:, token in the body)
    # must PASS. Without this leg the guard could reject every SKILL.md and still
    # look correct.
    _ct_run _preflight_stamp "widget-grammar"
    _ct_eq "$REPLY_RC" "0" "U-18c control: token in the BODY with a conforming version: line passes pre-flight"

    # Guard leg: move the token onto the version: line.
    printf '%s\n' '---' 'name: fixtureops' 'description: fixture' \
      'version: {{RELEASE_VERSION}}' '---' '# Fixtureops' \
      > "$_sb18c/operations/skills/fixtureops/SKILL.md"
    _ct_run_err _preflight_stamp "widget-grammar"; err="$REPLY"
    CLAIM_REPO_ROOT="$_save18c"; STAMP_FILES=()
    _ct_eq "$REPLY_RC" "1" "U-18c a token on the version: line HALTs pre-flight (before the CAS)"
    grep -q 'version:' <<< "$err" \
      || _ct_fail "U-18c the pre-flight message must name the version: field so the operator can act on it"
    rm -rf "$_sb18c"
  }

  # ---- U-18e: a --stamp-file that does not exist HALTs PRE-CAS. The existence of
  #      every stamp target was previously checked only inside the post-CAS stamp,
  #      so a typo'd path HALTed AFTER the tag was irreversibly claimed despite
  #      being trivially checkable beforehand — the same "checkable early, enforced
  #      late" defect class as the missing rebuild. Both halves now run pre-flight.
  _t_label="U-18e a missing --stamp-file HALTs pre-flight, before the CAS"
  {
    local _sb18e; _sb18e="$(_st_pkg_sandbox "widget-missing")"
    local _save18e="$CLAIM_REPO_ROOT"
    CLAIM_REPO_ROOT="$_sb18e"

    # Control leg: an existing stamp target passes, so the guard below is
    # discriminating rather than a blanket rejection of every manifest.
    STAMP_FILES=("operations/skills/fixtureops/SKILL.md")
    _ct_run _preflight_stamp "widget-missing"
    _ct_eq "$REPLY_RC" "0" "U-18e control: an existing --stamp-file passes pre-flight"

    STAMP_FILES=("operations/skills/fixtureops/NOPE.md")
    _ct_run_err _preflight_stamp "widget-missing"; err="$REPLY"
    CLAIM_REPO_ROOT="$_save18e"; STAMP_FILES=()
    _ct_eq "$REPLY_RC" "1" "U-18e a nonexistent --stamp-file HALTs pre-flight (never post-CAS)"
    grep -q 'NOPE.md' <<< "$err" \
      || _ct_fail "U-18e the pre-flight message must name the missing path"
    rm -rf "$_sb18e"
  }

  # ---- U-18d: the FAIL-LOUD error path. Auto-rebuild is the primary behaviour,
  #      but fail-loud is retained rather than discarded: when the rebuild itself
  #      fails there is nothing to commit, so the stamp HALTs and the message must
  #      name the builder command AND the affected skill. Asserting the message
  #      content matters — a bare non-zero exit here leaves the operator with a
  #      claimed tag and no instruction.
  _t_label="U-18d rebuild failure HALTs the stamp and names the builder + skill"
  {
    local _sb18d; _sb18d="$(_st_pkg_sandbox "widget-fail")"
    local _save18d="$CLAIM_REPO_ROOT"
    : > "$(_st_f stamp_commits)"; : > "$(_st_f rebuild_calls)"; : > "$(_st_f commit_paths)"
    printf '1\n' > "$(_st_f rebuild_rc)"          # force the rebuild seam to fail
    CLAIM_REPO_ROOT="$_sb18d"; STAMP_FILES=("operations/skills/fixtureops/SKILL.md")
    _ct_run_err _stamp_release_identity "v3.99" "widget-fail" "deadbeefcafe1234"; err="$REPLY"
    CLAIM_REPO_ROOT="$_save18d"; STAMP_FILES=()
    printf '0\n' > "$(_st_f rebuild_rc)"
    _ct_eq "$REPLY_RC" "1" "U-18d a failed rebuild makes the stamp return non-zero"
    grep -q 'build-skill-packages.sh' <<< "$err" \
      || _ct_fail "U-18d the HALT message must name build-skill-packages.sh (the command to run)"
    grep -q 'fixtureops' <<< "$err" \
      || _ct_fail "U-18d the HALT message must name the affected skill"
    _ct_eq "$(_st_stamp_n)" "0" "U-18d no stamp commit is recorded when the rebuild fails"
    rm -rf "$_sb18d"
  }

  if [[ $failures -eq 0 ]]; then
    echo "claim-version.sh --self-test: PASS (all fixtures green: U-0..U-18d incl. real-RELEASE_LOG-parser(header-name-pinned + shifted-column control), real-origin-tags-rc-contract(U-0b: failed-read vs tagless-repo + probe/healthy controls), real-seam-rc-contract-on-unresolvable-identity(U-14a), all-three-claimed_set-arms-fail-closed + their controls(U-17), net->HALT, signing->HALT, CAS-recompute-win, orphan-excluded both sides, pushed-unpublished-mainline-claimed, fetch-fail->HALT, bounded-HALT-no-force, never-bypass-signing + its detector-negative-control(U-6/U-6b), fail-closed-on-unresolvable-repo-identity + its detector-negative-control(U-14/U-14b), arm-unavailable-is-not-arm-empty(U-15), anchor-rc-checks-claimed-set-and-greenfield-fallback + their controls(U-16), claim-time-stamp(substitute+rename), no-stamp-slug-skips, collision-safe-stamp-binds-won-tag-once, post-CAS-package-rebuild-rides-the-same-commit(U-18) + injected-canonical-vector(U-18b) + cross-grammar-guard-with-control(U-18c) + missing-stamp-file-halts-pre-CAS-with-control(U-18e) + fail-loud-rebuild-error-path(U-18d))"
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
