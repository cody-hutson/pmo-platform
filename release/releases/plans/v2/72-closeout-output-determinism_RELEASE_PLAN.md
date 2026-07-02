# Release Plan — 72-closeout-output-determinism (v2.38)

> **Plan-of-record** for the v2.38 close-out-output-determinism release. Nine open issues harden the Stage-13 close-out engine (`release/tools/automated-closeout.sh`) plus two doc-conformance fixes. Hub-finalized after Decision-Briefing R1 adversarial verification of the planning spoke (working tree clean, verified). Stage 5 Collective design implementation-ready and operator-scope-locked.

## Summary

Nine issues harden `release/tools/automated-closeout.sh` (Stage-13 close-out engine) plus two doc-conformance fixes. **Seven of nine edit one file** → a single-file, function-level-contention release: the script fixes are co-implemented in one Engineering pass on one branch, committed in dependency order, merged as one PR (platform norm: milestone = one PR / one merge). Release Class **cross-cutting** (triggers b + c fire). The 35-raw-point (≈46 effective ×1.3) bundle is an operator-approved size override on record — coordination risk is real but concentrated in one file under one merge, which *lowers* cross-file rollback complexity.

## Dependency graph

```
#667 (slug + corpus-emit substrate) ──┬─> #37  (Outcome field — same Deployment-Log block)
                                       ├─> #38  (per-issue close/exclude — rides detection correctness)
                                       ├─> #1705 (zero-commit guard — depends #667 per body)
                                       ├─> #1681 (false-PASS re-derive — "under/alongside #667")
                                       ├─> #1680 (ledger concurrency guard — guards #667's append phases)
                                       └─> #1682 (Release↔SHA bind — relates #667)
#1705 (un-strands terminal phases) ───> #1681, #1680, #1682  (operate in/after terminal phases)
#82  (doc verifier ↔ table-row form) ... independent doc fix
#84  (references-only propagate-or-defer) ... independent doc/policy fix
```

**#667 is the keystone** (slug underlies Phase-4 detection feeding #38/#1681; corpus-emit structure is the substrate #1680 guards). **#1705 is a 2nd-order gate** (un-strands the 4 terminal phases #1681/#1680/#1682 live in/after).

Satisfied / non-blocking edges (verified at Stage 4 R1): `#37→#218` NON-BLOCKING (the `**Outcome:**` enum ships in `decision-outcome-tracking.md`, which already names `automated-closeout.sh` as a consumer); `#1680→#1092` (CLOSED); `#38→#1470` (CLOSED).

## Implementation sequence (commit order on ONE branch)

| # | Issue | Size | Why here |
|---|---|---|---|
| 1 | #667 | L (8) | Keystone — slug/corpus-emit substrate |
| 2 | #82 | XS (1) | Doc-only; align verifier to the corrected table-row + visible-H4 form; no code coupling |
| 3 | #37 | M (4) | Outcome field; enum available now (#218 non-blocking) |
| 4 | #38 | L (8) | `--exclude-issue` + per-issue comment; rides #667 detection |
| 5 | #1705 | M (4) | Zero-commit guard + CI-realistic merge budget — un-strands terminal phases |
| 6 | #1681 | S (2) | Re-derive VERIFIED; shares preflight/transition fns with #1705 — adjacency load-bearing |
| 7 | #1680 | M (4) | Ledger concurrency guard + post-merge re-parse |
| 8 | #1682 | S (2) | Bind Release to MERGE_SHA |
| 9 | #84 | S (2) | Policy/doc layer; independent; safe last |

## `automated-closeout.sh` function-level contention (Stage-6 serialization map)

| Function | #667 | #37 | #38 | #1705 | #1681 | #1680 | #1682 | Class |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| extract_milestone_slug | F2 | | | | | | | single |
| phase_detect_open_issues | F2 | | edit | | edit | | | HOT (3) |
| phase_transition_release_log | | edit | | | edit | edit | | HOT (3) |
| (new) phase_inject_outcome_field | | add | | | | | | single |
| phase_append_release_index | F6 | | | | | edit | | HOT (2) |
| phase_append_release_digest | F3 | | | | | edit | | HOT (2) |
| phase_create_chore_pr | F(seam) | | | edit | | | | HOT (2) |
| phase_await_merge_chore_pr | | | | edit | | | add | single |
| phase_manual_close_release_issues | | | edit | | | | | single |
| phase_publish_github_release | | | | | | | edit | single |
| MERGE_SHA capture (new, at read-state) | | | | | | | add | single |
| self_test() | edit | edit | edit | edit | edit | edit | edit | ALL 7 |

**Implication:** ≥2-writer functions would merge-conflict if parallelized → one branch, dep-ordered commits. Build #667 (slug + append structure) first, then layer transition-log edits #1681 → #1680 so each writer sees the prior's version. #37's Outcome injection is extracted to a SEPARATE `phase_inject_outcome_field` (post-transition) to take the third writer out of `phase_transition_release_log`.

## Locked design decisions (operator-rendered 2026-06-28 at Collective Review scope-lock)

- **#37 Outcome:** default `**Outcome:** SUCCESS` when QC4 clean (per `decision-outcome-tracking.md` §4 autonomous path); `--outcome <ENUM>` + `--outcome-rationale` override. Injected as a SEPARATE `phase_inject_outcome_field` (post-transition), not inside `phase_transition_release_log`. Enum closed: SUCCESS / PARTIAL / ROLLBACK / DEFERRED. Placement: immediately after `**Result:**`. Rationale REQUIRED for non-SUCCESS, OPTIONAL for SUCCESS.
- **#1705 await_merge:** default budget **300s**, `--merge-timeout <N>` flag to tune, `--no-merge` mode (exit cleanly leaving the chore PR). Plus the zero-commit guard in `phase_create_chore_pr` (`git rev-list --count origin/main..$CHORE_BRANCH` -eq 0 → SKIP create + skip await, terminal phases proceed).
- **#38 auto-exclude:** explicit `--exclude-issue <N>` (repeatable, primary) + title-regex `(?i)stage.?13.*close` (fallback); per-issue close comment must not be the single hardcoded anomaly template for excluded/Tier-0 issues.
- **#84 target = `core/rules/skill-deployment.md`** (the live skill-deployment doc; `release/references/standards/skill-deployment.md` does not exist — File Change Matrix Tier-1 [ADJUST]).
- **#667 Finding 2 (slug) already resolved** on HEAD by the position-independent `extract_milestone_slug` rewrite — F2 gets a `--self-test` case + a code comment only; F3 (DIGEST H3 under `## Knowledge Corpus` per deploy.sh Check 32), F4 (Phase 9→10 seam), F6 (INDEX 6-col single-row insert) build fully.

## Build-order constraints (from the Consistency Matrix — load-bearing)

1. **#667 BEFORE #1680** — #1680's read-modify-write guard + post-merge re-parse must validate against #667's CORRECTED INDEX (6-col) / DIGEST (H3) structure, not the broken one. This is the single most load-bearing ordering constraint.
2. **`phase_transition_release_log` order:** #1681's VERIFIED-re-derivation guard goes at the TOP, BEFORE the `if VERIFIED → SKIPPED` early-return; #1680's concurrency wrapper wraps the write. #37 is NOT in this function (separate phase).
3. **MERGE_SHA captured ONCE** at read-state from the RELEASE PR; #1705 + #1682 both read the global.
4. **#1680 §237 boundary:** its post-merge re-parse treats the `**Outcome:**`/Deployment-Log block as I1 (take-both / presence + dedup), NEVER I2 (state-lattice max).
5. Each script fix ADDS its own hermetic `--self-test` block (append-only, save/restore globals per the existing idiom); the test lands in that fix's commit.

## File Change Matrix — changed paths

```
release/tools/automated-closeout.sh
release/references/how-to/hub-spoke-bridge.md
core/rules/skill-deployment.md
release/references/pipeline/stage-12-execute.md
release/skills/release-executor/SKILL.md
release/releases/plans/72-closeout-output-determinism_RELEASE_PLAN.md
```

(#84 target corrected to `core/rules/skill-deployment.md`. #38 edits `release-executor/SKILL.md` ⇒ pmo-skill-editor discipline applies — impact + coherence + regression-aware edit before commit.)

## Stage Applicability

All 9: S5 APPLY (doc-only #82/#84 APPLY-light), S6/S9 APPLY (Deep at S9 per cross-cutting). **S7 SKIP for #82, #84** (no executable surface); **S8 REDUCE for #82, #84** (doc-conformance grep, no test authoring). All 7 script fixes: full S7/S8 via `--self-test` cases. Stage 9 depth = **Deep** (cross-cutting mandate).

## Risk Register

- **R1 single-file 7-issue contention** — HIGH if parallelized → one-branch discipline (function table = commit guide). Reversibility CHEAP.
- **R2 over-band 35pt bundle** — operator-approved; one-file / one-merge concentration *reduces* rollback complexity (`git revert -m 1 <SHA>` reverts the whole bundle).
- **R4 self-repair masks regression** in the (formerly) 3-writer `phase_transition_release_log` — resolved by extracting #37 to its own phase (2 writers); each fix adds `--self-test`; CI smoke gate; Deep S9 diff review.
- **R5 #38 wrong-comment hazard** — if auto-exclude misses the Stage-13 sub-task it self-closes mid-run, erasing Tier-0 evidence. Mitigated by explicit-`--exclude-issue` primary + title-regex fallback + a mixed-fixture self-test (only the anomaly issue closes; the sub-task survives).
- **R9 reflexive-loop** — v2.38 hardens the close-out path that closes v2.38; the 4 terminal-phase fixes will NOT be on main at v2.38's own close → close v2.38 via operator-agency + the deploy.sh Check 48 backstop. The introducing-release-exempt cutover discipline applies.

## D-decisions

- **D-Version = v2.38** — rule-determined (next-free after v2.37). Recorded determination, not a gate; the concrete number binds at the Stage 12 atomic claim.
- **D-Release-Class = cross-cutting** — CONFIRMED (trigger b: ≥3 governance/corpus surfaces; trigger c: ≥6 in-bundle edges). Deep S9; Stage-5 ALL; 30-day outcome window.
- **D-C Branch Topology = SINGLE** — `release/v2.38-closeout-output-determinism`, 9 commits + a Stage-4 plan commit, one merge; standard `chore/vX.Y-stage-<N>-<purpose>` PRs for Stage 12 / Stage 13.
- **Merge/split = ONE PR / 9 commits** in dep order (not per-issue PRs).
- **No ADRs** — every design decision has a single forced approach dictated by an existing enforcement contract (deploy.sh Check 32 regex, the §220 concurrent-conflict doctrine, the `decision-outcome-tracking.md` §2 enum). Two one-line commit design-notes named instead: #1682's release-PR-vs-chore-PR MERGE_SHA choice, and #38's explicit-number-primary / regex-fallback auto-exclude.

## Verification plan

Each of the 7 script fixes adds a hermetic `--self-test` block. After every commit, `bash release/tools/automated-closeout.sh --self-test` must exit 0 before the next commit (or fix forward). #82/#84 are doc-only (no executable surface) — verified by the corpus-conformance greps named in their issue ACs.

## Rollback strategy

Whole-release rollback = `git revert -m 1 <release-PR-merge-SHA>` (one file, one merge — restores the prior `automated-closeout.sh` + the two doc edits atomically). Per-issue rollback is the per-commit revert on the branch pre-merge.
