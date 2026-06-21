<!-- reference-durability: allow-link -->
# Stage 12: Execute

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Deploy the release — merge the approved PR to main, tag the version, deploy changed files to their installed locations, and log deployment evidence — so the platform reflects the approved changes and the audit trail is complete.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation | Compression Note |
|---|---|---|---|
| Purpose | Deploy to production; monitor; execute cutover | Merge PR to main, tag, deploy skill files | Git merge + S-2 direct copy |
| Governance Focus | Deployment monitoring; escalation readiness | Post-deploy verification (skill invocation, diff checks) | Manual verification in current state |
| Artifact Inputs | Deployment runbook, approved release | Stage 9 GO decision, PR, Delivery Strategy, rollback strategy | — |
| Artifact Outputs | Deployment log, production state change | RELEASE_LOG.md entry, merged PR, version tag, deployed files | — |
| Rollback | Rollback plan execution readiness | `git revert` pre-positioned; rollback strategy in release plan | Git-native rollback |

Key compression: Ref Model assumes multi-system coordinated cutover with war room, staged rollout, and monitoring dashboards. PMO platform: git merge is deterministic and atomic. "Deployment" = merge + tag + file copy. No staged rollout. Monitoring = post-deploy verification checks.

## 3. Persona

| Role | Skills-Map Ref | Modes | Autonomy |
|---|---|---|---|
| Authorization gate: Human operator | — | — | Tier 3 (GO decision from Stage 9) |
| Deployment execution (primary): Release Manager Skill 13 | Deployment Execution | Mode 2 | Tier 1 (Auto-execute post-authorization) |
| Deployment mechanics (secondary): DevOps/SRE Skill 11 | Deployment Execution | Mode 2 | Tier 1 (Auto-execute — file copy, verification) |

Compression: Ref Model separates Release Manager (decision/orchestration) from DevOps/SRE (execution/infrastructure). Single-operator platform: agent performs both roles. Tier 3 gate already passed in Stage 9.

## 4. Inputs
From Stage 9: Go/No-Go decision (GO), evidence package, conditions (if any).
From Stage 6 (carried forward): PR number, branch name, Delivery Strategy, verification plan, rollback strategy, changed files list.
From platform rules: skill deployment mechanism (S-2 per `skill-deployment.md`), deployment log format, git workflow.

Set at Stage 12: merge commit SHA, version tag, deployment execution log, post-deploy verification results.

## 5. Process
**Phase A — Pre-Deployment Validation (Tier 1):**
A1 Entry gate: verify Stage 9 GO, PR mergeable, branch up-to-date. A2 Deployment plan confirmation: read Delivery Strategy (merge approach, tag convention, S-2 targets, Layer 2 tasks). A3 Rollback readiness: confirm `git revert` available, previous versions recoverable.

**Phase A.4 — Repo Merge-Strategy Availability Pre-Check (Tier 1, conditional):**
A.4.1 Read the declared merge strategy from the release plan's Delivery Strategy section (one of: `merge` / `squash` / `rebase`). If no merge strategy is explicitly declared in the release plan, skip A.4.2–A.4.5 and proceed to Phase A.5 (default `gh pr merge --merge` semantics apply per existing convention). A.4.2 Query repo-allowed merge strategies: `gh api repos/{REPO} --jq '{squash:.allow_squash_merge, merge:.allow_merge_commit, rebase:.allow_rebase_merge}'`. A.4.3 Assert the declared strategy maps to `true` in the API result (`squash` → `.squash`; `merge` → `.merge`; `rebase` → `.rebase`). A.4.4 On enabled (declared strategy is `true` in the API result): record the allowed-strategies map and the declared strategy in the Stage 12 sub-task output (audit trail); proceed to Phase A.5. A.4.5 On disabled (declared strategy is `false` in the API result): HALT pre-merge and escalate Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol naming (a) the declared strategy, (b) the allowed-strategies map from the API result, (c) the originating declaration source (release plan section, ADR #N if applicable). Operator renders disposition: (i) amend release plan to use an allowed strategy, (ii) enable the declared strategy on the repo via GitHub repo settings, or (iii) accept-as-residual with documented rationale. Do not proceed to Phase A.5 until operator renders resolution. Empirical motivation: a prior release's Stage 9 / Procedure-6 execution (2026-05-16) — a release ADR's Decision #4 mandated `gh pr merge --squash`; repo configuration (`allow_squash_merge: false`) forced mid-execution merge-strategy deviation to `--merge` (an ADR amendment recorded the deviation; intent preserved because the rollback semantics in Decision #7 `git revert -m 1` literally require a non-squash merge — but the contradiction was discovered at execution rather than authoring).

**Phase A.4 transient-API handling:** If `gh api repos/...` returns a non-zero exit code during A.4.2, retry the call up to 2 times per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Per-Stage Application Stage 12 retry posture (production-cap=2). On 2-retry exhaustion: post Tier 2 [SCOPE CHANGE] flagging API unavailability (distinct from semantic HALT class in A.4.5).

**Cutover discipline:** Applies to all releases going forward.

**Phase A.5 — Main-Divergence Pre-Check (Tier 1, conditional):**
A.5.1 Compute divergence count: `git log <release-branch-base>..origin/main --oneline | wc -l`. A.5.2 If 0 commits: skip A.5.3–A.5.5 and proceed to A.5.6. A.5.3 If >0 commits: attempt `git merge origin/main` into release branch within the session worktree. A.5.4 On clean merge: record commits-merged count, merge-commit SHA, and resolution rationale in the Stage 12 sub-task output; proceed to A.5.6. A.5.5 On conflict: STOP and escalate Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol; do not proceed to Phase B merge until operator renders resolution decision.

A.5.6 **Version-freeness pre-merge check (the version dimension of this pre-check — orthogonal to the A.5.1–A.5.5 file dimension; HALT-eligible).** Where A.5.1–A.5.5 ask "did a post-baseline commit touch a release-plan file?", A.5.6 asks the independent question "is this release's resolved version slot already claimed?" The two are sibling sub-steps sharing one fetch; neither subsumes the other (a release can pass the file dimension yet fail the version dimension when a concurrent release claimed the slot while touching different files, and vice-versa). This is the LAST pre-merge *detection* instant before the merge sequence (Phase A.6 mergeability polling → Phase B0 dependent-PR base-shift → Phase B1 merge); the residual A.5.6→B1 window is owned by the Phase B3 atomic ref-CAS prevention rung (the **Phase B3 CAS-retry sub-protocol** block), which is the atomic test-and-set at the tag itself. A.5.6 is the pre-merge detector that prevents the wasted merge; Phase B3 is the prevention backstop. A.5.6a **Resolve + check freeness via the version-claim adapter** (do NOT re-derive the anchor or re-encode the claimed-set union — the host mechanism lives only inside the adapter per [`core/standards/repo-host-adapter-versioning.md`](../../../core/standards/repo-host-adapter-versioning.md) § 4 adapter discipline). Run `CLAIM_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)" release/tools/claim-version.sh --sha "$MERGE_SHA" --bump <bump-class> [--patch-base v<X.Y>] --dry-run` — the `--dry-run` mode fetches fresh authoritative refs and computes the next-free version against the adapter's `anchor()` (highest claimed version in the mainline lineage, orphans excluded) and `claimed_set()` (the union of published Release tags ∪ origin signed tags ∪ in-flight RELEASE_LOG `DEPLOYED`-not-`VERIFIED` rows, every member orphan-filtered via `lineage()` and compared by the version-grammar integer-tuple comparator) WITHOUT pushing any tag. Read the dry-run's computed next-free version off stdout and compare it to the provisional-display version the branch currently carries (the version baked into the branch's commit messages / PR title / plan). A.5.6b **If they match** (the carried version equals the adapter's recomputed next-free — the slot the labels advertise is still the free slot): record `version-freeness = FREE` + the resolved version in the Stage 12 sub-task output; proceed to Phase A.6. A.5.6c **If they differ** (the adapter's next-free has advanced past the carried version — a claimed-set member now occupies the slot the labels advertise): **HALT pre-merge** — do NOT proceed to Phase A.6 or Phase B merge. The adapter's dry-run stdout already carries the recomputed next-free version; escalate Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol naming (a) the stale carried version, (b) that a claimed-set member now occupies it (the adapter's `claimed_set()` union — published Release / origin tag / in-flight DEPLOYED row), (c) the recomputed next-free version from the dry-run, (d) the re-version-before-merge action — refresh the release's version label on the branch to the recomputed version BEFORE the merge so the merge commit carries the correct label. The merge proceeds only after the operator renders the re-version disposition and the corrected label is on the branch. The mechanical re-version doctrine (how the relabel is applied) is the recovery layer's scope, cited via § Inter-Stage Feedback Protocol; A.5.6 routes to it, it does not author it. Empirical motivation: a prior release (re-versioned forward-only after a concurrent-release collision) discovered the taken slot only at the Phase B3 signed-tag push — AFTER the merge had landed carrying the stale version label (immutable post-merge without a force-push); A.5.6 surfaces the collision before the Phase B1 merge so the label is corrected on the branch first. A.5.6d **Transient-API handling (fail-closed):** if the `claim-version.sh --dry-run` invocation exits non-zero for a non-collision reason (the underlying `git fetch` or `gh api` failed — network / auth / rate-limit, distinct from a computed-version result), retry the dry-run up to 2 times per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Per-Stage Application Stage 12 retry posture (production-cap=2). On 2-retry exhaustion: **fail-closed — HALT** and post Tier 2 [SCOPE CHANGE] flagging API unavailability (distinct from the A.5.6c TAKEN HALT class). Fail-closed is load-bearing here: the whole purpose of A.5.6 is to never merge on an unverified slot, so an unresolved freeness check must stop the merge, never fail-open past it.

**Cutover discipline:** Applies to releases entering Stage 12 strictly AFTER this sub-step's introducing-release merge. The introducing release itself is exempt (the freeness check shipping in this release cannot run on its own Stage 12, which precedes the merge that lands it).

**Phase A.6 — mergeStateStatus Polling Protocol (Tier 1, conditional):**
A.6.1 Initial mergeability read per in-scope PR: `gh pr view <PR> --json mergeable,mergeStateStatus --jq '[.mergeable,.mergeStateStatus] | @tsv'`. Record state in Stage 12 sub-task output. A.6.2 If `mergeable == "MERGEABLE"` AND `mergeStateStatus ∈ {CLEAN, UNSTABLE, BLOCKED}`: PASS for this PR; skip A.6.3–A.6.5 for this PR; advance to next in-scope PR. A.6.3 If `mergeable == "CONFLICTING"` OR `mergeStateStatus == "DIRTY"` (definitive conflict): HALT immediately for the WHOLE release (do not poll remaining PRs); post Tier 2 [SCOPE CHANGE] comment per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol naming the affected PR, observed state, and remediation path (resolve conflict on PR branch, then re-attempt Phase A.5 + A.6); do not proceed to Phase B until operator renders resolution decision. A.6.4 If `mergeable == "UNKNOWN"` OR `mergeStateStatus == "UNKNOWN"` (GitHub computation pending): enter polling loop with backoff `3s, 5s, 10s, 12s` (4 attempts; 30s wall-clock cap). After each `sleep` step, re-read state via the A.6.1 command. On `MERGEABLE` resolution: handle per A.6.2 (PASS) OR A.6.3 (CONFLICTING). On persistent `UNKNOWN` after the 4th attempt: HALT for this PR; post Tier 2 [SCOPE CHANGE] comment naming the affected PR, polling attempts table (per-attempt state), and recommended next steps (operator-initiated longer-wait retry, or Tier 3 plan rejection if persistent UNKNOWN suggests scope problem); do not proceed to Phase B until operator renders resolution decision. A.6.5 Record per-PR Phase A.6 outcome (initial state, attempts, final state, decision) in Stage 12 sub-task output before advancing to Phase B.

**Phase A.6 transient-API handling:** If `gh pr view` returns a non-zero exit code during initial read OR any polling attempt, retry the `gh pr view` call up to 2 times per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Per-Stage Application Stage 12 retry posture (production-cap=2). On 2-retry exhaustion: post Tier 2 [SCOPE CHANGE] flagging API unavailability (distinct from semantic HALT classes).

**Cutover discipline:** Applies to all releases going forward.

**Phase B0 — Pre-Merge Dependent-PR Check (Tier 1, per-PR, conditional):**
B0.1 Enumerate dependent open PRs against parent PR's head branch: `gh pr list --repo {REPO} --base <parent-head-branch> --state open --json number,baseRefName,headRefName,mergeable,mergeStateStatus`. B0.2 If empty array (zero dependents): skip B0.3–B0.6; proceed to B1. B0.3 (Option A — default) For each dependent PR `<dep>`: `gh pr edit <dep> --base main`; record base-shift outcome (per-PR command exit status). B0.4 Re-verify dependent mergeability post-shift: `gh pr view <dep> --json mergeable,mergeStateStatus` per dependent. On UNKNOWN: invoke per the A.6 polling protocol on `<dep>` until definitive (bounded backoff; HALT after cap). On CONFLICTING: HALT and escalate Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol; operator decides resolution (in-place / cherry-pick / resequence). B0.5 On MERGEABLE post-shift for all dependents: proceed to B1. B0.6 (Option B — declared in Delivery Strategy) If Delivery Strategy declares "Stacked-base cleanup posture: defer to Phase D0": skip B0.3–B0.5; log dependents to Stage 12 sub-task output for cleanup tracking; B1 merge command drops `--delete-branch` flag; Phase D0 fires after all waves merge (see Phase D0 below). Empirical motivation: a prior release's Stage 12 — the parent-PR merge with `--delete-branch` auto-deleted the parent feature branch `feature/implementation-planner-bundle`; the dependent PR (a later wave, base = that branch) was immediately auto-closed by GitHub; recovery required 7-step branch-recreate + reopen + base-shift + merge + branch-delete. Phase B0 prevents the auto-close by pre-shifting dependents before the parent merge.

**Cutover discipline:** Applies to all releases going forward.

**Phase B — Execution (Tier 1, sequential):**
B1 Merge PR per Delivery Strategy via `gh pr merge`, then **verify and capture merge commit SHA** via `gh pr view <PR> --json state,mergeCommit` per **Phase B merge verification protocol** below (asserts `state == "MERGED"` AND `mergeCommit.oid` non-null; SHA captured from `.mergeCommit.oid`). B2 No-op — merge commit SHA is captured directly from `gh pr view`; no branch checkout in the session worktree is needed. B3 **Atomic version claim (ref-CAS) — the version is computed and claimed HERE, at the merge tag, not carried from the plan** (the plan declares only the bump-class per [`release/governance/RELEASE_PROTOCOL.md § Versioning`](../../governance/RELEASE_PROTOCOL.md)). Invoke the claim mechanism: `CLAIM_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)" release/tools/claim-version.sh --sha "$MERGE_SHA" --bump <bump-class> [--patch-base v<X.Y>]` — it captures the claimed tag on stdout (use it for B5/B5.5). The script performs the four-step atomic claim against fresh authoritative refs (it implements the GitHub/git reference adapter's `anchor()`/`claimed_set()`/`atomic_claim()`/`lineage()` operations — see [`core/standards/repo-host-adapter-versioning.md`](../../../core/standards/repo-host-adapter-versioning.md)): (1) fetch authoritative refs (rc-checked; HALT on failure); (2) compute next-free ≥ floor against the mainline-lineage anchor (orphans excluded) using the version-grammar integer-tuple comparator; (3) push the **signed-annotated** tag at `$MERGE_SHA` (`tag.gpgsign=true`; **never bypass** — see **Phase B signing-policy interaction** block below); (4) **git ref-CAS** rejects a colliding push — see the **Phase B3 CAS-retry sub-protocol** block below. On a successful claim the tag is on origin and captured for B4/B5/B5.5. On a non-collision push failure or 5 contended losses the script HALTs (non-zero exit) and the spoke escalates Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol. B4 Deploy changed files (when applicable): skill files via S-2 copy, `core/rules/` already synced on-branch. Record file, mechanism, timestamp, result per deployment. B5 Write deployment log to RELEASE_LOG.md (table row + Deployment Log section — see Phase B5 emit format below for cutover-specific format).

**Phase B5 emit format:** The Deployment Log content emits as a **visible H4 `#### Deployment Log v<X.Y>` subsection** appended immediately after the LOG row, NOT as an HTML comment block. The visible-section format surfaces deployment evidence (deployed files, mechanism, timestamp, result) to readers in rendered markdown rather than requiring source-view to read HTML comments. Post-cutover, the Stage 12 chip prompt (per `hub-spoke-bridge.md` Procedure 5) MUST instruct the spoke to emit the H4 subsection format. The visible section structure:

```
#### Deployment Log v<X.Y>
**Files deployed:** <list>
**Mechanism:** <e.g., S-2 direct copy / git merge>
**Timestamp:** <YYYY-MM-DD HH:MM>
**Cycle-Time:** <X>m / <H>h<M>m / N/A — (T_GO=<iso>; T_DEPLOY=<iso>; mechanism: compute-cycle-time.sh)
**Result:** SUCCESS / PARTIAL — <detail per file if partial>
```

**Cycle-Time field:** Emit invokes [`release/tools/compute-cycle-time.sh`](../../tools/compute-cycle-time.sh) `<version>` and embeds the returned value (or `N/A` for content-only releases that emit zero `deploy-skill`/`deploy-harness` events). Field schema, format rules (`<X>m` / `<H>h<M>m` / `N/A`), and N=3 baseline-trigger semantics codified at [`release/references/standards/deployment-cycle-time.md`](../standards/deployment-cycle-time.md). Post-baseline (N ≥ 3), the value optionally carries a parenthetical baseline-comparison suffix (e.g., `47m (-12% vs 53m baseline)`) per the standard's § 3.1. Cutover: applies to releases entering Stage 12 strictly AFTER this field's introducing-release merge SHA; **the introducing release itself is exempt** per D-DogfoodPosture (A) — reflexive-pipeline-loop discipline.

**Velocity field — Stage-13 addition (forward-note):** The Stage-12 emit template above stays cycle-time-only. The sibling `**Velocity:**` field (planned-vs-delivered points + ratio, files-changed, allocation actuals, Release Class) is **appended at Stage 13**, not Stage 12 — its *delivered* and *allocation* halves are authoritative only once Stage 13 marks the membership closed. The Stage 13 chore PR adds it in the same commit that transitions the row `DEPLOYED → VERIFIED` and adds `**Outcome:**` (this mirrors how the outcome field is a Stage-13 addition to the same block). Field schema, format, and the producing tool are codified at [`release/references/standards/release-velocity-tracking.md`](../standards/release-velocity-tracking.md); the capture step lives at [`stage-13-close.md § Phase B`](stage-13-close.md).

**Cutover discipline:** Applies to all releases going forward.

**Phase B5 commit mechanism — chore PR:** The Phase B5 RELEASE_LOG row + visible-H4 Deployment Log content emits via a Stage 12 chore PR — never via direct-to-main commit. The chore-PR mechanism honors [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do" (*"Never commit directly to main — always use a branch + PR"*) AND resolves the chicken-and-egg constraint that the LOG row contains the merge commit SHA (must be authored POST-merge per Phase B1).

Canonical chore-PR shape (Stage 12 spoke executes after Phase B3 tag push, before Phase C post-deploy verification):

```bash
# Phase B5 chore-PR pattern — runs in session worktree (no main checkout)
git checkout -b chore/v<X.Y>-stage-12-release-log
# Edit <OPERATOR_INSTANCE_RELEASE_LOG_PATH>:
#   - Append new row with state = "DEPLOYED"
#   - Append visible-H4 "#### Deployment Log v<X.Y>" block per Phase B5 emit format above
git add <OPERATOR_INSTANCE_RELEASE_LOG_PATH>
git commit -m "chore(v<X.Y>): Stage 12 — RELEASE_LOG row + visible-H4 Deployment Log"
git push -u origin chore/v<X.Y>-stage-12-release-log

gh pr create \
  --title "chore(v<X.Y>): Stage 12 — RELEASE_LOG row + visible-H4 Deployment Log" \
  --body "<parser-clean body per core/rules/git-workflow.md § PR Process>" \
  --milestone "v<X.Y>-<slug>" \
  --assignee "@me" \
  --reviewer "<operator GitHub handle>"

gh pr merge <PR> --merge
# Verify per Phase B merge verification protocol below — assert state=MERGED + mergeCommit.oid non-null:
gh pr view <PR> --json state,mergeCommit
```

Parser-clean PR body discipline applies per [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § PR Process. The Stage 12 chore PR does NOT auto-close any release issues — release-issue auto-close uses the release PR's standard auto-close keywords at Stage 12 Phase B1. Stage 12 chore PR bodies use safe phrasing throughout; the dedicated Issue References block is OPTIONAL and used only for cross-link traceability with safe phrasing (e.g., *"Cross-references: the codification ticket; D3 emit-format spec"*) rather than the standard auto-close keywords.

Empirical motivation: a prior release's Stage 12 Finding F-1 (2026-05-15) — the hub-authored chip prompt implied direct-to-main commit; the spoke correctly self-repaired via the chore-PR pattern (precedents in earlier release PRs). A subsequent release PR (2026-05-16) is the canonical worked example of the Stage 12 chore PR shape codified here.

**Cutover discipline:** Applies to all releases going forward.

**Phase B5 chore-PR creation — REST-preference annotation:** When the Stage 12 spoke creates the Phase B5 chore-PR via `gh pr create` (canonical bash example above) AND additional chore-PRs are expected within the same stage (Phase J.5 rebuilt-packages chore-PR when applicable; Stage 13 INDEX + DIGEST + RELEASE_NOTES chore-PR), the spoke SHOULD prefer REST endpoints (`gh api -X POST /repos/{REPO}/pulls --field title=... --field head=... --field base=main --field body=@/tmp/body.md`) for PR creation/merge. `gh pr create` uses GraphQL; `gh api -X POST` uses REST. The GraphQL rate-limit budget (5000 units/hr) can exhaust mid-stage when 3+ chore-PRs are created within the per-hour window; REST endpoints are independent of the GraphQL budget and remain available as a fallback after exhaustion.

**Evidence:** a prior release's Stage 12+13 retrospective — F-2 finding: 5026 GraphQL units consumed across 3 chore-PRs (Phase B5 RELEASE_LOG row + Phase J.5 rebuilt-packages + Stage 13 INDEX/DIGEST/NOTES) in a single release; REST fallbacks (`gh api -X POST /repos/.../pulls`) succeeded cleanly after `gh pr create` blocked on GraphQL exhaustion.

**Cutover discipline:** Applies to all releases going forward.

**Phase B5.5 — Surface 1 emit (Layer-1 dual-write — `gh release create`):** After the Phase B5 RELEASE_LOG row chore-PR has merged AND the v<X.Y> annotated tag has been pushed at Phase B3, Stage 12 emits the canonical public release surface (Surface 1 of the Layer-1 dual-write mechanism per [`release-notes-standard.md § Part 5`](../standards/release-notes-standard.md)) via the GitHub Releases API. Surface 1 is the public-facing release-notes consumer at `https://github.com/{REPO}/releases/tag/v<X.Y>`. Surfaces 2 (CHANGELOG.md) and 3 (RELEASE_LOG VERIFIED transition) emit at Stage 13 chore PR per [`stage-13-close.md § Phase B`](stage-13-close.md).

**Stage-anchor rationale (per the sister spec Part 5 §5.4):** Surface 1 lands at Stage 12, not Stage 13, because the `gh release create` invocation is a GitHub API mutation against an existing tag — the tag exists at Stage 12 Phase B3, so the earliest valid emit point is post-Phase B5 (after RELEASE_LOG row records the DEPLOYED state). Surfaces 2+3 are git commits that land via the Stage 13 chore PR. The N-way consistency principle anchors stage assignment to mechanism execution surface — API mutation at Stage 12, git commits at Stage 13.

**RELEASE_NOTES.md authoring constraint:** Surface 1 emit requires `release/releases/notes/v<X.Y>_RELEASE_NOTES.md` to be resolvable as a `--notes-file` path. The canonical file is authored at Stage 13 per existing convention. Two operational paths satisfy this requirement at Stage 12 emit time: (1) **operator-authored at Stage 6 or pre-Stage 12** — the release plan's Operational Deployment Manifest may include a pre-Stage-12 RELEASE_NOTES draft on the release branch (operator discretion); the Stage 12 chore-PR could carry the notes (out-of-scope for the Surface-1 mechanism — files in this category land via separate operator workflow). (2) **scaffold-emit at Phase B5.5 with post-VERIFIED `gh release edit` refresh** per [`release-notes-standard.md § 5.5`](../standards/release-notes-standard.md) view-then-create-or-edit pattern AND [§ 5.6](../standards/release-notes-standard.md) post-VERIFIED corrections re-emit procedure. In this case, Stage 13 Phase B chore PR's RELEASE_NOTES authoring updates the canonical file, and Mode F re-invocation (`gh release edit`) refreshes Surface 1 from main. The view-then-create-or-edit state machine guarantees Surface 1 reaches steady-state regardless of which path the operator chooses.

**View-then-create-or-edit state machine (per `release-notes-standard.md § 5.5`):** `gh release create` is NOT independently idempotent — re-running with a tag that already has a release returns HTTP 422 (`Validation Failed: already_exists`). The emit follows a 3-state state machine; `gh release view` discriminates between create-vs-edit before mutation:

| State | Pre-condition | Action | Post-condition |
|---|---|---|---|
| **State 0 — no release for tag** | `gh release view v<X.Y>` returns "release not found" (exit code 1) | `gh release create v<X.Y> --notes-file <canonical-note-path> --title "<H1-headline>" --target "$MERGE_SHA"` — on success → State 2; on transient failure (network / 5xx) → retry once (production-cap=2 per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md)) → on second failure → HALT and post Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol | release present at desired content; auditable via `gh release view` |
| **State 1 — release exists; content may differ** | `gh release view v<X.Y> --json body` returns body content (any value) | Compare returned body against canonical note body (excluding frontmatter). If MATCH → State 2 PASS no-op. If DIFFER → `gh release edit v<X.Y> --notes-file <canonical-note-path>` (idempotent) → State 2 | release present at desired content |
| **State 2 — release present with current content** | view + diff verification passes | No mutation needed; PASS; proceed to Phase C post-deploy verification | sequence complete for Surface 1 |

**Canonical command form (Phase B5.5 — Stage 12 spoke executes after Phase B5 chore-PR merged + Phase B3 tag push verified):**

```bash
# Phase B5.5 — Surface 1 emit (view-then-create-or-edit per release-notes-standard.md § 5.5)
NOTES_PATH="$REPO_ROOT/release/releases/notes/v<X.Y>_RELEASE_NOTES.md"

# Preflight 1: tag must exist on remote (Stage 12 Phase B3 already pushed it)
if ! git -C "$REPO_ROOT" ls-remote --tags origin "v<X.Y>" | grep -q "v<X.Y>"; then
  echo "HALT — tag v<X.Y> not present on origin; Phase B3 may not have completed"
  exit 1
fi

# Preflight 2: canonical notes file must be resolvable (operator-authored OR Stage 13 scaffold path)
if [[ ! -f "$NOTES_PATH" ]]; then
  echo "INFO — RELEASE_NOTES file not present at $NOTES_PATH; Surface 1 emit will use scaffold-then-edit path per release-notes-standard.md § 5.5 State 0 (canonical-note-path resolves at Stage 13 chore PR landing; Mode F re-invocation refreshes)"
  # Continue with skeletal --notes for State 0 OR defer Surface 1 emit to post-Stage-13 Mode F invocation
fi

# Surface 1 body = the note with its YAML frontmatter stripped (the committed
# vX.Y_RELEASE_NOTES.md is the source of record; the Release page is the rendered
# copy people read). Publish the body, NOT the file verbatim. Per § 5.1.
CANONICAL_BODY=$(sed '1,/^---$/d; 1,/^---$/d' "$NOTES_PATH" 2>/dev/null)  # strip frontmatter

# View-then-create-or-edit decision (idempotency guard)
if gh release view "v<X.Y>" --repo {REPO} >/dev/null 2>&1; then
  # State 1 or 2 — release exists; compare body
  EXISTING_BODY=$(gh release view "v<X.Y>" --repo {REPO} --json body --jq .body)
  if [[ "$EXISTING_BODY" == "$CANONICAL_BODY" ]]; then
    echo "PASS — Surface 1 already at canonical state for v<X.Y>"
  else
    # State 1 → State 2 transition via idempotent gh release edit
    gh release edit "v<X.Y>" --repo {REPO} --notes "$CANONICAL_BODY"
  fi
else
  # State 0 — release does not exist; create
  HEADLINE=$(grep -m1 '^# ' "$NOTES_PATH" | sed 's/^# //' || echo "v<X.Y> Release")
  gh release create "v<X.Y>" \
    --repo {REPO} \
    --title "v<X.Y> — $HEADLINE" \
    --notes "$CANONICAL_BODY" \
    --target "$MERGE_SHA"
fi

# Verify Surface 1 reached State 2
gh release view "v<X.Y>" --repo {REPO} >/dev/null || { echo "FAIL — Surface 1 verification"; exit 1; }
```

**Tag-existence preflight (single source of truth):** Phase B5.5 uses `git ls-remote --tags origin <tag>` as the tag-existence assertion (clear protocol-layer error message: "tag not on origin"). The `gh release create --verify-tag` flag is REDUNDANT with this preflight — pick one. Phase B5.5 uses `ls-remote --tags`; `--verify-tag` is intentionally omitted from the canonical command to avoid two error paths for the same condition.

**Idempotency mechanism — explicit clarification (per the adversarial-findings PR-2 audit):** `gh release create` is NOT idempotent by itself. The SEQUENCE (view → create-or-edit) IS idempotent because `gh release view` discriminates create-vs-edit before mutation. Re-running Phase B5.5 after any failure mode (transient API, partial chore-PR merge, operator interrupt) is safe — the view step routes correctly to State 0 (create) or State 1 (edit) or State 2 (no-op PASS).

**Reversibility:** CHEAP / HIGH confidence — `gh release delete v<X.Y>` removes the server-side release (tag preserved); re-running Phase B5.5 after delete re-publishes cleanly. The release PR + Stage 12 chore PR remain unaffected by Surface 1 mutations.

**Composition with existing Phase B5 chore-PR:** Phase B5.5 fires AFTER Phase B5 chore-PR has merged AND the `gh pr view --json mergeCommit` verify step has captured `$MERGE_SHA`. Phase B5.5 uses the same `$MERGE_SHA` as the `--target` value, pinning the GitHub Release to the canonical merge commit (matches the sister-spec Part 5 §5.5 State 0 invocation form). Phase B5.5 does NOT require any new git commit — it is a pure GitHub API mutation.

**Composition with `release-executor` Mode F:** Phase B5.5 is invoked autonomously by the Stage 12 spoke during normal release execution; the same logic is also exposed as `release-executor` Mode F (Publish Release) for standalone fix-forward invocation per [`release-executor/SKILL.md`](../../skills/release-executor/SKILL.md) Mode F. Both invocation paths share the view-then-create-or-edit state machine — Mode F's idempotency guard via `gh release view` matches Phase B5.5's, so safe re-invocation is preserved across paths.

**Cutover discipline:** Applies to all releases going forward.

**Phase B tag-SHA-direct rationale:** The B1→B3 sequence avoids `git checkout main` in the session worktree by capturing the merge SHA from `gh pr view --json mergeCommit.oid` and tagging directly via `git tag v<X.Y> "$MERGE_SHA"`. This honors [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § Primary Checkout Discipline, which reserves the `main` branch checkout for the primary at `${HOME}/Claude/` (`git checkout main` from a worktree fails with `'main' is already used by worktree at ...`). Tagging from the captured SHA produces identical functional outcome (tag on the merge commit, pushed to origin). Empirical motivation: a prior release's Stage 12 — the spoke deviated correctly from the chip prompt's `git checkout main` instruction, revealing the chip-side defect now codified here. The claim mechanism (`claim-version.sh`) tags from the captured `$MERGE_SHA` for exactly this reason — it never checks out `main`.

**Cutover discipline:** Applies to all releases going forward.

**Phase B3 CAS-retry sub-protocol (the prevention layer):** The version slot is claimed by the tag push itself — the push is an atomic compare-and-swap. The git server rejects a second writer at the ref-update instant (`! [rejected] <tag> -> <tag> (already exists)`, empirically confirmed), which `claim-version.sh` maps to `atomic_claim() → COLLISION`. This closes the TOCTOU window a pre-push existence check cannot: a check-then-push has a gap between the check and the push during which a concurrent release can claim the slot; ref-CAS has no such gap. On a `COLLISION`, the mechanism drops its local tag, recomputes next-free against the now-newer tip, and retries — **never `git push --force`, never overwrites the existing tag, never re-uses the rejected number without recomputing**. The retry is **bounded at 5 attempts with no backoff** (the contention is a local fetch + in-process compute + one push, not a rate-limited API); five distinct concurrent releases reaching the tag-push instant within one retry span is pathological, so exhaustion is a deterministic HALT, not an infinite loop. **Push-failure discrimination is load-bearing:** only a git ref-rejection signature triggers recompute-and-retry. **Every other non-zero push exit — network, authentication, permission, and signing — is a hard HALT that surfaces the raw error and does NOT recompute or re-push.** Recomputing past a signing failure would silently defeat the never-bypass-signing constraint (the next number would also fail to sign); the mechanism therefore halts on a signing failure exactly as the **Never-bypass-signing constraint** block below requires. A failed `git fetch` is likewise a hard HALT — recomputing against a stale tip cannot make progress. The pre-merge freeness *detection* probe (a separate, complementary layer) narrows the race window; this CAS claim *closes* it.

**Phase B signing-policy interaction (Phase B3 tag command):** The Phase B3 tag command is `git tag -a -m "<message>" v<X.Y> "$MERGE_SHA"` — `-a` requests an annotated tag; `-m` supplies the message inline. The repo enforces `tag.gpgsign=true` (verifiable via `git config --get tag.gpgsign` → `true`), with `gpg.format=ssh` selecting the SSH-key signing path (verifiable via `git config --get gpg.format` → `ssh`). With these settings active, `git tag -a` produces a **signed annotated tag** automatically — no additional `-s` flag needed. When `tag.forceSignAnnotated=true` is also set (operator-instance hardening; not required at the public-repo `~/.gitconfig` level), `-a` is mandatory: a lightweight `git tag <name> <SHA>` fails with `fatal: no tag message?` exit 128 because the policy refuses to elide the annotated form. Conclusion: the canonical Phase B3 command MUST use `-a -m "<message>"`; lightweight `git tag <name> <SHA>` is forbidden.

**Never-bypass-signing constraint:** Per [`core/rules/git-workflow.md § Commit Messages`](../../../core/rules/git-workflow.md) ("Never use --no-verify. Respect pre-commit hooks."), the never-bypass principle extends to tag signing. The Phase B3 chip MUST NOT include flags or environment overrides that disable signing: `--no-gpg-sign`, `-c tag.gpgsign=false`, or `GIT_CONFIG_PARAMETERS="'tag.gpgsign=false'"`. If signing fails at runtime (e.g., SSH agent not loaded, signing key missing), the spoke HALTS and escalates Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol — operator resolves signing-environment issue, then spoke retries. **No bypass under any condition.**

**Message format derivation:** The tag message is computed from already-known Stage 12 inputs — `<X.Y>` from the release version; `<milestone-slug>` from the Milestone title suffix (e.g., for milestone `v1.01-intake`, slug = `intake`); `<N>` from the count of issues in the Milestone; `<n>` from the PR number (the same PR `gh pr view` captured `$MERGE_SHA` from at B1). The chip prompt SHOULD compute these inline and substitute into the command — no operator handoff required. Empirical motivation: a prior release's Stage 12 sub-task Decision D1 — the spoke deviated from the chip's lightweight form to the structured-triplet form, which successfully passed signing policy AND carried sufficient audit-trail content for retrospective reconstruction.

**Cutover discipline:** Applies to all releases going forward.

**Phase B merge verification protocol:** Every `gh pr merge` invocation in Stage 12 — release PR merge at B1 AND chore-PR merge at B5 — is paired with an immediate `gh pr view <PR> --json state,mergeCommit` invocation that asserts post-merge state. The verify call is load-bearing (gates Phase B3 tag push at B1; gates Phase C entry at B5), NOT incidental SHA capture.

**Assertion (PASS criteria):** `state == "MERGED"` AND `.mergeCommit.oid != null` (non-empty SHA string).

**Canonical command form:**

```bash
MERGE_SHA=$(gh pr view <PR> --json state,mergeCommit \
  --jq 'select(.state == "MERGED" and .mergeCommit != null) | .mergeCommit.oid')
if [[ -z "$MERGE_SHA" ]]; then
  # HALT — verify failed; route per failure-routing table below
  exit 1
fi
```

**Failure routing:**

| Observed | Class | Routing |
|---|---|---|
| `gh pr view` non-zero exit before parse | Transient API | Retry up to 2 attempts per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Per-Stage Application Stage 12 retry posture (production-cap=2). On 2-retry exhaustion: HALT and post Tier 2 [SCOPE CHANGE] per [`release/governance/release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol flagging API unavailability |
| `state != "MERGED"` (e.g., `OPEN`, `CLOSED` with `mergeCommit == null`) | Semantic — merge did not occur | HALT; post Tier 2 [SCOPE CHANGE] naming PR, observed state, recommended next steps (operator re-attempts merge OR diagnoses GitHub merge-block) |
| `state == "MERGED"` but `mergeCommit.oid == null` | Semantic — GitHub anomaly | HALT; post Tier 2 [SCOPE CHANGE] flagging GitHub state inconsistency (extremely rare; suggests GitHub API issue) |
| `state == "MERGED"` AND `mergeCommit.oid` non-null | PASS | Capture SHA; advance to next phase step |

**Empirical motivation:** a prior release's Stage 12 Execute — an initial `gh pr merge <PR> --merge` returned no stdout AND no stderr but DID merge the PR. The subsequent `gh pr view <PR> --json mergeCommit` call succeeded as part of the existing B1 SHA-capture step, but the verify was operator-discovered (incidental), not protocol-mandated. Phase B merge verification protocol formalizes the verify into a load-bearing gate.

**Composition with existing phases:**

| Phase | Composition |
|---|---|
| Phase A.6 mergeStateStatus polling | Independent — A.6 fires **pre-merge** asserting mergeability; Phase B merge verification fires **post-merge** asserting state transitioned to `MERGED`. Both compose; neither replaces the other |
| Phase B0 dependent-PR check | Independent — B0 fires pre-merge (base-shift OR Option B defer); Phase B merge verification fires post-each-merge regardless of B0 outcome. Under Option B (stacked-base cleanup deferred), Phase B merge verification fires on parent + each wave merge symmetrically |
| Phase B5 chore-PR mechanism | **Applies** — chore-PR merge at B5 is `gh pr merge`, so the verify pattern fires here. The bash example in Phase B5 chore-PR subsection includes the verify line per Edit 2 above |
| Phase B tag-SHA-direct rationale | **Composes** — Phase B merge verification REPLACES the implicit-verify reading of the SHA capture step with an explicit-verify gate; tag push at B3 still uses the captured `$MERGE_SHA`. The two protocols are sequentially composed: verify → capture SHA → tag from SHA |
| Phase J.5 rebuild-then-commit hygiene | Independent — J.5 fires post-Phase B; J.5's own commits do NOT use `gh pr merge` (direct push to main via `git push origin main` from primary, per Phase J.5 spec). Phase B merge verification does not apply to J.5 commits |

**Mechanism-agnostic w.r.t. merge tool:** The verify uses `gh pr view` (read-only query against PR state), not `gh pr merge` (the merge action). If the REST-preference annotation mandates REST `gh api -X POST /repos/{owner}/{repo}/pulls/<N>/merge` as an alternative merge mechanism, the Phase B merge verification rule continues to apply — the verify reads PR state regardless of how the merge was performed. Phase B merge verification protocol and the REST-preference annotation compose cleanly.

**Cutover discipline:** Applies to all releases going forward.

**Phase J.5 — Rebuild-Then-Commit Hygiene (Tier 1, conditional):**
J.5.1 Compute rebuilt-package diff against primary: `git -C ${HOME}/Claude diff --name-only packages/ | tee /tmp/v<release>_rebuilt_packages.txt`. J.5.2 If empty (zero rebuilt packages): skip J.5.3–J.5.5 and proceed to Phase C. J.5.3 If non-empty: stage the explicit list — `git -C ${HOME}/Claude add $(cat /tmp/v<release>_rebuilt_packages.txt)`. J.5.4 Commit with the canonical message — `git -C ${HOME}/Claude commit -m "chore(<version>): rebuilt skill packages from Phase H deploy"`. J.5.5 Push: `git -C ${HOME}/Claude push origin main`; record committed-packages count + commit SHA in the Stage 12 sub-task output; proceed to Phase C. Empirical motivation: a prior release's Stage 12 Phase H rebuilt 4 cascade-modified packages successfully; chip prompt instructed RELEASE_LOG commit only, leaving 4 orphan-modification packages that never reached origin/main until forensic discovery ~3 days later. Phase J.5 formalizes the missing commit step into a deterministic post-Phase-H sub-phase.

**Cutover discipline:** Applies to all releases going forward.

**Phase J.5 chore-PR creation — REST-preference annotation:** When Phase J.5 fires (non-empty rebuilt-packages diff per J.5.2) AND the operator-precedent chore-PR pattern applies (per prior-release Stage 12 precedent + memory `feedback_stage12_13_release_log_chore_pr.md`'s never-direct-to-main discipline), the REST-preference annotation codified for Phase B5 above applies symmetrically. Prefer REST endpoints (`gh api -X POST /repos/{REPO}/pulls --field title=... --field head=... --field base=main --field body=@/tmp/body.md`) over `gh pr create` to avoid GraphQL rate-limit exhaustion when Phase B5 + Phase J.5 + Stage 13 chore-PRs are all created within the per-hour budget window. See the Phase B5 REST-preference annotation above for full evidence (5026 GraphQL units across 3 chore-PRs in single release) and cutover semantics; the self-exempt cutover anchored in the Phase B5 annotation governs Phase J.5 symmetrically.

**Phase C — Post-Deploy Verification (Tier 1):**
C1 Merge verification (PR MERGED, commit on main, tag on GitHub). C2 Deployed copy verification (diff source vs. installed, zero diff = PASS). C3 Functional verification (when applicable — invoke changed skills, verify rules). C4 Layer boundary verification (`git status` clean). C5 Rollback verification (`git revert` available).

**Phase D — Handoff to Stage 13 (Tier 1):**

**Phase D0 — Stacked-Base Cleanup (Tier 1, conditional on Option B declaration):**
D0.1 Read Delivery Strategy "Stacked-base cleanup posture" row from release plan. If unset or set to "Option A": skip D0.2–D0.3; proceed to D1. D0.2 If set to "Option B — defer cleanup to Phase D0": read the dependents-log accumulated during Phase B0.6 across all wave merges. D0.3 For each logged head branch: `gh api -X DELETE repos/{REPO}/git/refs/heads/<branch>`; record per-branch deletion outcome to Stage 12 sub-task output. Proceed to D1.

**Cutover:** Phase D0 inherits the Phase B0 cutover clause — applies to releases that merge to main strictly AFTER the introducing release. **The introducing release itself is exempt.**

D1 Confirm all deployment evidence persisted. D2 Identify Stage 13 inputs (merged PR, tag, deployment log, verification results, deferred items). D3 Signal Stage 13 ready.

**Ticket lifecycle:** Claim: set Stage→12-Execute + Status→Done + `status: done` label. Execute: A-D. Resolve: deployment evidence persisted, handoff complete. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** State Persistence (merge, tag, deploy); Tracking (Status → Done). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Merged PR (MERGED), version tag on main (vX.Y), deployed files (skill copies if applicable), deployment execution log in RELEASE_LOG.md, post-deploy verification results, Stage 13 handoff package.

For the structured boundary contract, see [schemas/stage-io-contracts.md](../../../core/schemas/stage-io-contracts.md#boundary-stage-12--stage-13).

Stage 12 does NOT produce: quality assessments (Stages 7-8), design decisions (Stage 5), release close-out (Stage 13).

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics (canonical IDs per [`schemas/gate-criteria-spec.md` Gate 12](../../../core/schemas/gate-criteria-spec.md#gate-12-execute-readiness)): PR MERGED (G-EX1), tag exists (G-EX2), all S-2 deployments completed with zero diff (G-EX3), deployment log appended (G-EX4), release row in RELEASE_LOG.md (G-EX5), all verification PASS (G-EX6), no Layer 2 leakage (G-EX7), deferred items documented (G-EX8); incoming deferred items accounted (every mid-pipeline item whose Target stage = this stage — including items passed through the PLATFORM-SATISFIED Stage 10/11 compression — is picked up or re-deferred with rationale per [deferred-item-tracking.md §13](../standards/deferred-item-tracking.md); G-EX8 separately covers the release-boundary "Deferred items list").
Judgment (1-5): execution fidelity, deployment completeness, verification thoroughness, audit trail quality, handoff readiness.
Gate output: PROCEED to Stage 13 / HOLD (investigate before Close).

## 8. Automation Level
Overall Tier 1 (Auto-execute) with Tier 3 pre-authorization from Stage 9. Second-most autonomous stage after Stage 6. Critical Tier 3 decision (GO/NO-GO) already happened in Stage 9 — Stage 12 is pure execution.

## 9. Gap Summary
6 gaps. Key: no Release Manager Mode 2 skill (P3), no automated deploy script (P3), Stage 12→13 handoff contract not formalized (P3). All P3 — stage is fully operable in conversation mode.

## 10. Retro
To be populated after an execution cycle.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `self-repair` | `retry` | Deploy retry (production-cap=2 per [autonomous-execution-model.md](../../../core/disciplines/autonomous-execution-model.md)) — `gh pr merge` / `git tag` / `core/deploy/deploy.sh --deploy` transient | `hub` |
| `self-repair` | `rollback` | Post-merge regression triggers operator-authorized rollback | `operator` |
| `deployment-status` | `deploy-skill` / `deploy-harness` / `deploy-package` / `deploy-rules-mirror` / `deploy-helper` | Per-file deploy outcome from `core/deploy/deploy.sh --deploy` (one row per affected target) | `hub` |
| `scope-change` | `tier-1-adjust` | Phase J.5 rebuilt-packages commit (chore-PR per `feedback_stage12_13_release_log_chore_pr.md`) | `spoke:#N` |

Cutover: events occurring on or after the FIRST release entering this stage strictly AFTER this protocol's introducing-release merge SHA. The introducing release itself: exempt (reflexive-pipeline-loop discipline).
