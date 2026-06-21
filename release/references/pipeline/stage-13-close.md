<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
# Stage 13: Close

> **Source:** Stage 13 design + operational-deployment compression
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Finalize the release — verify issue closure, execute operational deployment to Layer 2, close the Milestone, update RELEASE_LOG.md, persist verification evidence, and clean up the release branch. Milestone close gates on ALL deployment (git-native + operational) being verified.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation | Compression Note |
|---|---|---|---|
| Purpose | Verify deployment, update records, close | Same — plus Layer 2 operational deployment | — |
| Governance Focus | Change record closure, lessons learned | Issue/milestone/log finalization + operational deployment verification | — |
| Artifact Inputs | Deployed release, verification results | Stage 12 outputs + deployment manifest from release plan | — |
| Artifact Outputs | Updated records, closed change records | RELEASE_LOG.md VERIFIED, Milestone closed, Layer 2 targets deployed | — |

Key compression: Ref Model Part 6 Stages 13-15 (Verify, Clean, Close) compressed into single Stage 13. Operational deployment added — generalizes the S-2 skill pattern to all Layer 2 targets.

## 3. Persona

| Role | Skills-Map Ref | Autonomy |
|---|---|---|
| Release finalization: Release Manager Skill 13 | Mode 4 | Tier 1 (Auto-execute) |
| Verification: DevOps/SRE Skill 11 | Mode 3 | Tier 1 (Auto-confirm) |
| Decision maker: Human operator | — | Tier 3 (status approval if needed) |

## 4. Inputs
From Stage 12: merged PR, version tag, deployment log, post-deploy verification results, deferred items list.
From release plan: Operational Deployment Manifest (Layer 2 targets, mechanisms, verification methods), issue list, Milestone number, release branch name.
From platform rules: RELEASE_LOG.md format, git branch cleanup, verification evidence requirements.

For the structured boundary contract, see [schemas/stage-io-contracts.md](../../../core/schemas/stage-io-contracts.md#boundary-stage-12--stage-13).

Set at Stage 13: issue closure confirmation, Milestone state, RELEASE_LOG.md status (VERIFIED), verification evidence, branch cleanup, deferred item disposition, operational deployment results.

## 5. Process

**Phase A — Verification Confirmation (Tier 1):**
A1 Issue closure audit (auto-close via PR `Closes #N`, verify each issue CLOSED). A2 Deferred item disposition (enumerated procedure per [`../standards/deferred-item-tracking.md`](../standards/deferred-item-tracking.md) — enumerate bundled-but-not-closed → apply `status: deferred` label per [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md) line 36 → remove milestone → post canonical comment trail → summarize in Stage 13 chore PR body; non-blocking for close). A3 Verification evidence compilation (Stage 12 results, all PASS or documented exceptions). A4 Release-plan invariant re-verification (QC4-05): for each AV-N declared in the release plan, re-execute its assertion against post-deploy main. Surface per-AV verdict (PASS/FAIL) with affected files. FAIL is non-blocking for milestone close — route per QC4-05 disposition criteria in [`release/governance/release-process.md` § Checkpoint 4](../../governance/release-process.md). A4.5 Native-dep drift-check parity (per [ticket-information-architecture.md § Native Dependencies — Mirror Trigger Points](../specs/ticket-information-architecture.md#native-dependencies)): re-run the A3.5 mirror algorithm as a parity-check across release-scoped issues; report any drift findings in Verification Evidence. Non-blocking — drift is informational at Stage 13 (operator-mediated reconciliation belongs at Stage 2 of the next release cycle). Cutover: applies to all releases going forward.

*A4 cutover: QC4-05 invariant re-verification applies to all releases going forward.*

**Phase A5 — Design-artifact refresh-gate verification (G-CL6):** For each Tier-A activated artifact declared in the release plan's "Tier-A activated design artifacts" section, verify the artifact's last commit SHA is within the release branch commit range AND the diff is non-trivial (>3 line delta, excludes frontmatter-only). Per-artifact PASS/FAIL recorded in the release plan's Verification Evidence section. Canonical criterion in [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) Gate 13 row G-CL6. **Initial warn-mode posture** per [`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent — per-artifact FAIL logs to `core/hooks/design-artifact-warn-log.jsonl` and Milestone close proceeds; flip to enforce (per-artifact FAIL blocks close, operator override per CHEAP reversibility tier) is operator-driven after 2-3 release shakedown.

*A5 cutover: The G-CL6 design-artifact refresh-gate applies to all releases going forward.*

**Phase A6 — Cycle-time baseline maintenance:** When the closing release pushes the count of non-N/A cycle-time values to N ≥ 3 for the first time, the Stage 13 spoke initializes `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/cycle-time-baseline.md` (created lazily at the N=3 crossover; not present pre-baseline) with median + median absolute deviation (MAD) over the 3 most recent non-N/A values per [`release/references/standards/deployment-cycle-time.md § 5`](../standards/deployment-cycle-time.md). On subsequent closes, the spoke appends the new release's value and recomputes the rolling-3 median. Cycle-time is one of the metrics surfaced for the release-learnings synthesizer composition and `pmo-qa-auditor` decision-outcome review per the standard's § 8 Consumers table. Baseline-trigger predicate evaluated against `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md` via [`release/tools/compute-cycle-time.sh`](../../tools/compute-cycle-time.sh) per-release; pre-baseline releases (N < 3) emit cycle-time only.

*A6 cutover: Cycle-time baseline maintenance applies to all releases going forward.*

**Phase A7 — Release-learnings synthesis:** After the Stage 13 spoke has emitted the `release-synthesis/learnings-triple` row via `append-pipeline-event.sh` (the capture protocol), the spoke invokes [`synthesize-release-learnings.sh --mode per-release --version v<X.Y>`](../../tools/synthesize-release-learnings.sh) and appends the rendered `#### Release Learnings v<X.Y>` sibling H4 block to `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` (placement: immediately after `#### Deployment Log v<X.Y>`) via the Stage 13 chore PR. When `(release_count % N) == 0` (default N=5) OR the operator requests it, the spoke ALSO runs `--mode pattern-detect --window N` and posts the cross-release pattern report; clusters meeting ≥3 events across ≥2 versions auto-promote to GitHub Issues with `auto-promoted-pattern` + `improvement` labels when `--apply` is set (default is dry-run preview). Full synthesizer contract: [`pipeline-event-log-schema.md § 11`](../standards/pipeline-event-log-schema.md). The rendered triple block is also the **seed input** to the per-release close-out learnings register (full Kerth + PMBOK 7) produced at close per § 6 — register and triple COEXIST (directional: triple → register).

*A7 cutover: Release-learnings synthesis applies to all releases going forward.*

**Phase A8 — Close-out completeness (outcome-bound):** A release MUST close with its complete enumerated output set produced and verified on main — the canonical Stage 13 output set defined once by the Step 4 Verification table in `hub-spoke-bridge.md` Procedure 7 (the binding is on that output set, not on which mechanism produced it). The **mandated mechanism** — the default and expected path — is the automated close-out: the Stage 13 spoke invokes `automated-closeout.sh --pr <N> --version v<X.Y> --milestone <N> --dry-run --markdown` to enumerate the full Phase B + Phase C close-out plan (RELEASE_LOG `DEPLOYED → VERIFIED` transition + RELEASE_INDEX append + RELEASE_DIGEST append + RELEASE_NOTES scaffold-only + Stage 13 chore PR creation + Milestone close + auto-close-anomaly D-1 manual close + orphan-cleanup invocation). On operator approval at the dry-run review gate, re-invoke with `--apply` to execute the sequence per the script. release-executor Mode D wraps the script with input-collection + dry-run-review + AskUserQuestion approval gate + apply + report sequencing per `release/skills/release-executor/SKILL.md` Mode D. The script is idempotent per phase; the chore PR body uses safe phrasing throughout (lexical parser-clean discipline enforced by a pre-submit grep self-check inside the script per the PR-body close-keyword discipline, N=2 confirmed pattern). **Fallback:** the automated close-out's Phase 2 preflight hard-exits (exit 2) on exactly the merge-ahead conditions a close can legitimately hit — `gh auth` unavailable, tree not clean, the RELEASE_LOG row not yet landed, the tag absent. When preflight cannot pass, the operator MAY produce the same output set by hand via the Phase B chore-PR mechanism (below); the close is satisfied iff `deploy.sh --check` Check 32 and the Step 4 completion-verification table both pass. Binding the outcome rather than the tool keeps the close satisfiable even when the tool's preflight blocks.

**Scope of the mandate — outcome, not agency.** The mandate binds the **output set** (the canonical Stage 13 output set, defined once by the Step 4 Verification table in `hub-spoke-bridge.md` Procedure 7 — never re-enumerated here), NOT a single mechanism and NOT a human keystroke. Hand-assembling the corpus row-by-row is the prohibited path because it silently drops outputs: the canonical incident landed only the RELEASE_LOG row of the corpus surfaces (RELEASE_LOG + INDEX + DIGEST + NOTES) and left the INDEX row, the DIGEST entry, and the RELEASE_NOTES file unwritten until manual review. The mandate does NOT prohibit operator action: per the operator-agency carve-out in `hub-spoke-bridge.md` Procedure 7, the operator MAY perform any individual mechanical state-flip manually (merge a chore PR via the UI, close the Milestone via the UI). What is mandated is the outcome — the complete output set, verified on main — however it was produced; never that a human is barred from a keystroke.

**Two gates enforce completeness at different moments.** (1) **Close-time, on-main, full set:** the Step 4 completion-verification table (in `hub-spoke-bridge.md` Procedure 7) runs before milestone-close and asserts every canonical output is present on main — including the RELEASE_LOG row itself. This gate blocks an incomplete close. (2) **CI regression catch:** `deploy.sh --check` Check 32 is LOG-row-driven and asserts, for each already-landed RELEASE_LOG row, that its INDEX / DIGEST / NOTES (plus post-cutover tag / Release) companions exist. Check 32 cannot flag a release whose LOG row was never written — it iterates LOG rows; LOG-row presence is the Step 4 table's responsibility, not Check 32's.

*A8 cutover: The outcome-bound close-out completeness mandate applies to all releases going forward.*

**Phase A9 - Initiative-roadmap review-trigger checklist: RETIRED (ADR-012, 2026-06-02).** Roadmap instances are operator-local, so there is no in-repo roadmap set to grep for milestone references at close. The review-trigger forcing-function is removed; roadmap freshness is now an operator-local discipline per [initiative-roadmap-framework.md](../../../core/standards/initiative-roadmap-framework.md).

*(Phase A9 retired per ADR-012: roadmap instances de-scoped to operator-local; the review-trigger no longer applies.)*

**Phase A10 — Goal-attainment verification (QC4-06):** Stage 13 spoke reads the `### Release Outcome Statement` H3 block from the GitHub Milestone description (`gh api repos/{REPO}/milestones/<N> --jq .description`) AND reads post-deploy state evidence (Change Description `## Change Description` section in release plan + QC4-01..04 results + Success Indicator field when present). Produces a 1-paragraph attainment narrative answering "does post-deploy main exhibit the AFTER state?" Verdict: **ATTAINED** / **PARTIALLY-ATTAINED** / **NOT-ATTAINED**.

- **ATTAINED** → narrative cites Change Description + Success Indicator (when present) + ≥1 verifiable evidence anchor (`gh issue list`, `grep`, `gh pr view`, `core/deploy/deploy.sh --check`, etc.). Composes with decision-outcome capture per [`decision-outcome-tracking.md`](../standards/decision-outcome-tracking.md): ATTAINED → SUCCESS.
- **PARTIALLY-ATTAINED** → surface diagnostic for operator routing. Composes with decision-outcome capture: PARTIALLY-ATTAINED → PARTIAL.
- **NOT-ATTAINED** → surface diagnostic. Composes with decision-outcome capture: NOT-ATTAINED → SUCCESS-document-divergence OR ROLLBACK per operator.

Verdict + 1-paragraph narrative recorded in release plan Verification Evidence section. Non-blocking for milestone close — routing options per QC4-06 in [`release/governance/release-process.md` § Checkpoint 4](../../governance/release-process.md): (A) immediate-hotfix Issue / (B) carry-forward Issue / (C) accept-as-residual. Composes with G-CL7 (verdict-presence gate per [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-13-close-readiness) — initial warn-mode). See [release-outcome-statement-template.md § 7.3-7.4](../specs/release-outcome-statement-template.md) for the canonical narrative template.

*A10 cutover: QC4-06 goal-attainment verification applies to all releases going forward.*

**Phase A11 — Documentation-impact resolution gate (G-CL8 + deploy.sh Check 28):** Stage 13 spoke verifies the `Documentation Impact` declaration on every closed issue in the release. For each issue closed by the release PR (`gh pr view <PR> --json closingIssuesReferences`), reads the issue body's Documentation Impact field. For each non-None declared doc: verifies the file exists AND was modified within the release branch's commit range via `git log --follow <docs> origin/main..HEAD`. For each row declared `None — no documentation impact (rationale: <phrase>)`: verifies the explicit-none form (em-dash separator + rationale phrase present); bare `None` fails. The criterion asserts presence + resolution; absence of any Documentation Impact value is the gate-failing state. Per-issue PASS/FAIL recorded in the release plan's Verification Evidence section. Backed by `deploy.sh` Check 28 (`doc-impact-resolution-presence`). **Initial warn-mode posture** per [`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent — per-issue FAIL logs to `core/hooks/doc-impact-warn-log.jsonl` and Milestone close proceeds; flip to enforce (per-issue FAIL blocks close, operator override per CHEAP reversibility tier) is operator-driven after 2-3 release shakedown OR warn-log drained to < 10 entries (whichever first). Scope boundary: K1 codified corpus only — `core/rules/`, `core/`, `core/governance/`, `release/skills/*/SKILL.md` + `references/`, `CLAUDE.md`. Self-repair per Gate 13 G-CL8 row in [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md).

*A11 cutover: The documentation-impact resolution gate (G-CL8 / Check 28) applies to all releases going forward.*

**Phase B — Release Finalization, Git-Native (Tier 1):**
B1 Update `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` status `DEPLOYED` → `VERIFIED` (via Stage 13 chore PR — see Phase B commit mechanism below). B2 Persist verification evidence in release plan (via the Stage 13 chore PR when the plan-amendment commit is in scope; otherwise commit on the release branch pre-merge). B3 Delete merged release branch (local + remote) — runs in primary post-Milestone-close. B4 Compile stage definitions into pipeline-stages.md (when applicable — via the Stage 13 chore PR or a follow-up chore PR depending on diff scope).

**Phase B-OPS — Operational Deployment (Tier 1/2):**
B-OPS1 Manifest validation: read manifest from release plan, validate source paths exist, target paths accessible, mechanisms feasible. Empty manifest = skip to C1.
B-OPS2 File propagation: execute per mechanism (S-2-copy: `cp source target`; cowork-task: Cowork edit). Record file, mechanism, timestamp, result.
B-OPS3 Schema migration: execute per manifest specification (add fields, update templates in Layer 2 artifacts). Record changes.
B-OPS4 Deployment verification: diff-based for file propagation (zero diff = PASS), content assertion for schema migration (target contains expected elements). Append results to release plan Verification Evidence.

Memory-eviction manifest entries are VERIFY-CORPUS-gated per [`knowledge-architecture.md` §6 Memory↔corpus boundary](../../../core/disciplines/knowledge-architecture.md#memory-corpus-boundary): eviction (ARCHIVE → VERIFY-CORPUS → EVICT) does NOT proceed until the corpus encoding is confirmed present on `main`, so a memory is never evicted before its content lands (encode-then-evict).

Concurrency: Cowork opens for B-OPS2/B-OPS3, closes before C1. Per operations-bridge.md.

**Phase B commit mechanism — chore PR:** Phase B + B-OPS state-mutations to main-tracked release-corpus governance files (`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` `DEPLOYED` → `VERIFIED` transition; `release/releases/RELEASE_INDEX.md` new row; `release/releases/RELEASE_DIGEST.md` new entry; `release/releases/notes/vX.Y_RELEASE_NOTES.md` new file; `CHANGELOG.md` at repo root — Surface 2 of Layer-1 dual-write; `.version` at repo root — the version source-of-truth read by the SessionStart version-skew hook, stamped to the shipped `vX.Y` for *versioned* releases and SKIP-with-PASS for version-less releases; `release/releases/RELEASE_REVERSIONS.md` — the machine-readable re-version ledger, append one row per abandoned version ONLY when the release re-versioned mid-pipeline via `automated-closeout.sh` phase `append_reversions`, N/A on the common no-collision path) ship via a single Stage 13 chore PR — never via direct-to-main commit. The chore-PR mechanism honors [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do" AND bundles the Stage 13 release-corpus updates into one atomic main-landing.

Canonical chore-PR shape (Stage 13 spoke executes after Phase A verification clears + Phase B-OPS verification clears, BEFORE Phase C C1 Milestone close):

```bash
# Phase B chore-PR pattern — runs in session worktree (no main checkout)
git checkout -b chore/v<X.Y>-stage-13-corpus-update

# Edit <OPERATOR_INSTANCE_RELEASE_LOG_PATH>:
#   - Transition v<X.Y> row state DEPLOYED → VERIFIED (Surface 3 of Layer-1 dual-write)
#   - Append the **Velocity:** field to the v<X.Y> visible-H4 Deployment Log block
#     (sibling immediately AFTER **Cycle-Time:**) per Phase B-velocity below
# Edit release/releases/RELEASE_INDEX.md:
#   - Append v<X.Y> row at chronological-recent-first position
# Edit release/releases/RELEASE_DIGEST.md:
#   - Append v<X.Y> entry under version-family H2 section (or create new H2 if major-prefix is novel)
# Author release/releases/notes/v<X.Y>_RELEASE_NOTES.md
#   - Per release/references/standards/release-notes-standard.md 9-section format
# Edit CHANGELOG.md at repo root (Surface 2 of Layer-1 dual-write):
#   - Prepend ## [v<X.Y>] - YYYY-MM-DD H2 section under "Unreleased" per Keep-a-Changelog 1.1.0
#   - Content extracted from RELEASE_NOTES.md Section 6a per release-notes-standard.md § 5.3 transform
#   - Conditional: only fires if CHANGELOG.md exists at repo root;
#     under pre-CHANGELOG state, Phase B5.5 below SKIPs CHANGELOG emit with PASS
# Edit .version at repo root (release-cut-owned version source-of-truth):
#   - Write the shipped version: .version = v<X.Y> (Phase B5.7 below)
#   - Read by the SessionStart version-skew hook (core/hooks/notify-version-skew.sh)
#   - Conditional: only fires for *versioned* releases; SKIP-with-PASS for version-less

git add <OPERATOR_INSTANCE_RELEASE_LOG_PATH> \
        release/releases/RELEASE_INDEX.md \
        release/releases/RELEASE_DIGEST.md \
        release/releases/notes/v<X.Y>_RELEASE_NOTES.md \
        CHANGELOG.md \
        .version
git commit -m "chore(v<X.Y>): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG"
git push -u origin chore/v<X.Y>-stage-13-corpus-update

gh pr create \
  --title "chore(v<X.Y>): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG" \
  --body "<parser-clean body per core/rules/git-workflow.md § PR Process>" \
  --milestone "v<X.Y>-<slug>" \
  --assignee "@me" \
  --reviewer "<operator GitHub handle>"

gh pr merge <PR> --merge
# Verify per Phase B merge verification protocol (see pipeline/stage-12-execute.md):
gh pr view <PR> --json state,mergeCommit
```

**Sequencing:** Stage 13 chore PR MUST land on main BEFORE Phase C C1 Milestone close. Procedure 7 Step 4 completion-verification (per the completion-verification spec) reads release-notes presence + RELEASE_LOG `VERIFIED` state + INDEX/DIGEST entries + CHANGELOG.md entry + GitHub Release existence from main; all of these are populated by this chore PR landing (Surfaces 2+3) plus Stage 12 Phase B5.5 emit (Surface 1). Milestone close runs as hub Tier-1 mechanical post-merge per the milestone-close-is-hub-Tier-1 discipline (the Stage 13 chore PR merge is the deterministic precondition; Hub closes Milestone immediately after).

**Phase B-velocity — `**Velocity:**` field append (visible-H4 Deployment Log):** In the SAME Stage 13 chore PR commit that transitions the RELEASE_LOG row `DEPLOYED → VERIFIED` (Phase B1) and adds `**Outcome:**`, the Stage 13 spoke appends the `**Velocity:**` field to the v<X.Y> visible-H4 `#### Deployment Log v<X.Y>` block — sibling immediately AFTER `**Cycle-Time:**`. The field is computed by [`release/tools/compute-release-velocity.sh <version> --milestone <N> --merge-sha <MERGE_SHA>`](../../tools/compute-release-velocity.sh) (the `MERGE_SHA` captured at Stage 12 Phase B1; the milestone number is the release's bundle milestone) and embeds the returned value; if the tool cannot run in the close worktree (e.g. `gh` unavailable), the spoke manually computes the three signals from the membership and embeds them. The field schema, the label→work-class map, the N/A semantics (a release with no `size:*`-labelled membership records `Velocity: N/A`), and the N=3 recalibration linkage are codified at [`release/references/standards/release-velocity-tracking.md`](../standards/release-velocity-tracking.md). **Why Stage 13, not Stage 12:** the *delivered* points and *allocation actuals* are authoritative only once Stage 13 marks the membership closed (the same "not knowable until close" property as the outcome field). Direct-to-main is prohibited — this lands via the Stage 13 chore PR. **Cutover / grandfather:** applies to releases entering Stage 13 strictly AFTER this field's introducing-release merge SHA; **the introducing release itself is exempt** (reflexive-pipeline-loop discipline), and pre-cutover rows carry no `**Velocity:**` field (no backfill).

**Phase B5.5 — CHANGELOG.md append (Surface 2 of Layer-1 dual-write):** The Stage 13 chore PR commit includes a CHANGELOG.md append at repo root — Surface 2 of the Layer-1 dual-write mechanism per [`release-notes-standard.md § Part 5`](../standards/release-notes-standard.md). The content is extracted from `release/releases/notes/v<X.Y>_RELEASE_NOTES.md` Section 6a per the §5.3 transform rule (5–15 lines, Keep-a-Changelog 1.1.0 format with `## [v<X.Y>] - YYYY-MM-DD` H2 + `### Added/Changed/...` H3 categories present). Surface 1 (GitHub Releases) was already emitted at Stage 12 Phase B5.5 per [`stage-12-execute.md § Phase B5.5`](stage-12-execute.md); Surface 3 (RELEASE_LOG VERIFIED transition) is in the same Stage 13 chore PR diff per Phase B1.

**Tier-A design artifact — Layer-1 dual-write emit sequence (ASCII flow-block per [`design-artifact-standard.md § 6`](../../../core/standards/design-artifact-standard.md)):**

```
Stage 12 — Execute (per pipeline/stage-12-execute.md)
├── Phase B1 — Merge release PR + capture MERGE_SHA
├── Phase B3 — claim-version.sh --sha "$MERGE_SHA" --bump <bump-class> (atomic version claim + ref-CAS retry; pushes the signed tag, version computed at claim time)
├── Phase B5 — Stage 12 chore PR: RELEASE_LOG row at DEPLOYED state
│   └── chore PR merged + Phase B merge verification PASS
└── Phase B5.5 — SURFACE 1 EMIT (NEW per Layer-1 dual-write)
       Mechanism: gh release view → create-or-edit per release-notes-standard.md § 5.5
       Preflight: git ls-remote --tags origin v<X.Y> (single source of truth)
       Idempotency: view-then-create-or-edit state machine
       Output: canonical public release at https://github.com/{REPO}/releases/tag/v<X.Y>

Stage 13 — Close (per pipeline/stage-13-close.md — THIS FILE)
├── Phase A — Verification (QC4-01..06; G-CL6; G-CL7; G-CL8)
├── Phase B — Stage 13 chore PR (atomic landing)
│   ├── Phase B1   — Edit RELEASE_LOG.md: v<X.Y> row DEPLOYED → VERIFIED (Surface 3)
│   ├── (existing) — Edit RELEASE_INDEX.md (chronological-recent-first row)
│   ├── (existing) — Edit RELEASE_DIGEST.md (version-family H2 entry)
│   ├── (existing) — Author RELEASE_NOTES.md per release-notes-standard.md 9-section format
│   ├── Phase B5.5 — Edit CHANGELOG.md: prepend ## [v<X.Y>] H2 per K-a-C 1.1.0 (Surface 2 NEW per Layer-1 dual-write)
│   │                Idempotency: grep -qE "^## \[?v<X.Y>\]?[[:space:]]" (exact-version-match)
│   │                Pre-CHANGELOG SKIP: if CHANGELOG.md absent at repo root, SKIP with PASS
│   ├── Phase B5.6 — Verify Surface 1 exists: gh release view v<X.Y> exit 0
│   │                Missing Surface 1 → operator routing (Mode F publish OR accept residual)
│   ├── Phase B5.7 — Edit .version: write .version = v<X.Y> (release-cut-owned version source-of-truth)
│   │                Read by the SessionStart version-skew hook (notify-version-skew.sh)
│   │                Idempotency: no-op if .version already == v<X.Y>
│   │                Version-less SKIP: non-vX.Y / version-less release → SKIP with PASS (.version untouched)
│   ├── Phase B5.8 — Append RELEASE_REVERSIONS.md: one row per abandoned version (the re-version ledger)
│   │                ONLY when the release re-versioned mid-pipeline; N/A on the common no-collision path
│   │                Idempotency: skip an already-present (slug, abandoned_version) row
│   ├── Commit: chore(v<X.Y>): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG
│   └── chore PR merged + Phase B merge verification PASS
└── Phase C — Milestone close (hub Tier-1 mechanical post-chore-PR-merge)
    └── Procedure 7 Step 4 completion-verification:
        ✓ User-facing release note on main          (release-notes path)
        ✓ Version tag on origin                     (Stage 12 Phase B3)
        ✓ Milestone state closed                    (Phase C this stage)
        ✓ RELEASE_LOG row at VERIFIED               (Phase B1 this stage — Surface 3)
        ✓ All release sub-issues closed             (auto-close from release PR)
        ✓ GitHub Release published                  (Phase B5.6 — Surface 1 NEW)
        ✓ CHANGELOG.md entry present                (Phase B5.5 — Surface 2 NEW; N/A pre-CHANGELOG-init)
        ✓ .version stamped to vX.Y                  (Phase B5.7 — release-cut-owned; N/A for version-less)
```

The flow-block stays embedded here (NOT centralized at `core/standards/_examples/`) because it is referenced only from this file's Phase B5.5 subsection and cross-link to `stage-12-execute.md § Phase B5.5` — below the ≥3-doc threshold for centralization per `design-artifact-standard.md § 6`.

**CHANGELOG insertion-position invariant:** prepend (newest at TOP) per Keep-a-Changelog 1.1.0 reverse-chronological convention. Insertion point: immediately under the `## [Unreleased]` H2 section (if present) OR immediately under the K-a-C header block (when no `[Unreleased]` section exists). Matches sibling release-corpus surfaces (RELEASE_INDEX.md, RELEASE_DIGEST.md, RELEASE_LOG.md all use reverse-chronological).

**CHANGELOG idempotency guard (per adversarial FM-2):** the existence check for an already-present version block uses an exact-version-match regex with whitespace terminator: `grep -qE "^## \[?<VERSION>\]?[[:space:]]" CHANGELOG.md`. Prefix-only match is insufficient — `v1.04` would match `v1.04b-1`, `v1.04b-3`, etc., producing false-positive SKIPs for distinct releases. The terminator-aware regex enforces exact-token match. Better form (when re-implementing): `grep -qE "^## \[?$(echo "$VERSION" | sed 's/\./\\./g')\]? - " CHANGELOG.md` (escape periods + require ` - YYYY-MM-DD` K-a-C format).

**Pre-CHANGELOG SKIP semantics:** If CHANGELOG.md does NOT exist at repo root (pre-CHANGELOG state — the file-initialization ticket establishes the file with the initial Keep-a-Changelog header), Phase B5.5 SKIPs the CHANGELOG portion of the commit with PASS and logs the SKIP to the chore-PR body. The Stage 13 chore PR commits and merges normally with the other 4 release-corpus surfaces (RELEASE_LOG / INDEX / DIGEST / NOTES); CHANGELOG join fires automatically on the FIRST release post-init. No operator intervention required.

**Concurrent Stage-13 corpus conflict resolution.** When two releases' Stage-13 chore PRs are open at the same time, the **second-to-merge** hits a git merge conflict on all four append-only release-corpus ledgers — `CHANGELOG.md`, `release/releases/RELEASE_INDEX.md`, `release/releases/RELEASE_DIGEST.md`, and `release/releases/RELEASE_LOG.md` — because both PRs write into the same prepend/transition region. Resolve deterministically by classifying every conflicting region into one of **two invariants**; **never** resolve the whole merge with a blanket `-X ours` / `-X theirs`, which silently drops or regresses one release's record. (Framed for two concurrent PRs; ≥3 concurrent closes conflict pairwise and both invariants below compose — each is associative/commutative — so "the second-to-merge" generalizes to "each later-merging PR".)

The two invariants the resolution must preserve:

- **I1 — Additive region (union + preserve order + never re-sort).** Both sides prepend a *distinct* new entry/row for their own release into a reverse-chronological region. **Keep BOTH** entries; place each incoming entry at the **same top/most-recent position the normal (non-conflicting) Stage-13 append would have used**, preserving the existing entries' order. Do **NOT** re-sort the region — these ledgers are ordered by **landing/insertion time** (reverse-chronological), which is *not* the same key as version-descending: the live corpus routinely lands a lower version after a higher one (re-versions, hotfixes, version-less releases all interleave), so a "sort by version" resolution would reorder existing entries that are already correct. The only failure mode in an additive region is dropping one side's entry.
- **I2 — State-bearing column (per-key max over the state lattice + never regress).** A column whose value is a state-machine token, where each concurrent PR advances a *different* key's (row's) value. Resolve **per row independently**: take the **most-advanced** state regardless of which side it came from — `merged = max(ours, theirs)` over the column's ordered lattice. The merge never moves a value backward. A blind side-pick here is a **correctness defect, not a cosmetic one**: it regresses one release's state and writes a false audit record.

Classification of the four ledgers (and the two regions *within* `RELEASE_LOG.md`) into I1 / I2:

| Ledger / region | Region shape | Invariant | Resolution rule | Side-pick (`-X ours` / `-X theirs`) safe? |
|---|---|---|---|---|
| `CHANGELOG.md` (repo root) | Prepend `## [vX.Y]` H2 block, newest-landing at top (Keep-a-Changelog 1.1.0) | **I1 additive** | Keep BOTH blocks; insert each at the top position; preserve existing order; do not re-sort | NO — drops one release's entry |
| `release/releases/RELEASE_INDEX.md` | Prepend row, chronological-recent-first (file header: "Chronological-recent-first row order") | **I1 additive** | Keep BOTH rows; insert each at the top position; preserve existing order; do not re-sort | NO — drops one row |
| `release/releases/RELEASE_DIGEST.md` | Prepend `### vX.Y (date)` entry under the **topmost working H2** (today `## Knowledge Corpus`), intra-section date/insertion-ordered | **I1 additive** | Keep BOTH entries; place each under the H2 the normal Stage-13 append targets (the topmost working H2 — *not* re-homed to a `## vN.*` family section), preserving the existing intra-section order; do not re-sort | NO — drops one entry |
| `release/releases/RELEASE_LOG.md` — **row + `#### Deployment Log vX.Y` block** (incl. `**Outcome:**` / `**Velocity:**` / `**Cycle-Time:**`) | Append a per-version row + its sibling visible-H4 block; each version owns exactly one | **I1 additive** | Keep BOTH versions' rows and BOTH versions' Deployment-Log blocks; preserve order; do not re-sort. (The Deployment-Log-dedup post-resolution check below is a *consequence* of this rule, not a separate concern.) | NO — drops one version's row/block |
| `release/releases/RELEASE_LOG.md` — **status column** (`DEPLOYED → VERIFIED`) | Per-row state transition; each concurrent PR transitions a *different* row | **I2 state-bearing** | Per-row `merged = max(ours, theirs)` over `DEPLOYED < VERIFIED`; take the most-advanced state per row regardless of side | **NO — and this is the dangerous one**: a blind side-pick regresses one release's status to `DEPLOYED`, a false audit record |

**Why `RELEASE_LOG.md` carries both invariants.** Most of the file is I1 — the per-version row plus its `#### Deployment Log vX.Y` block are pure additions, each version owning its own block, so they reduce to take-both like the other three ledgers. The *only* I2 surface is the **status column**: the second-to-merge PR forked while its own release's row read `DEPLOYED`, and `main` has since advanced a *different* release's row to `VERIFIED`. A blind `-X theirs` reverts `main`'s already-`VERIFIED` row back to `DEPLOYED`; a blind `-X ours` discards the PR's own `DEPLOYED → VERIFIED` transition. Neither whole side is correct — the correct merged state is the per-row maximum over the status lattice, composed across both rows. The status lattice is declared at the head of `RELEASE_LOG.md` ("State transitions: `DEPLOYED` (Stage 12 Phase B5) → `VERIFIED` (Stage 13 chore PR)") — a monotonic, forward-only, total order over exactly `{DEPLOYED < VERIFIED}`, so per-row `max` is provably complete and order-independent (the second-to-merge reaches the same answer regardless of which release merged first). Do NOT apply the per-row `max` rule to the I1 Deployment-Log/`**Outcome:**` prose block — that block is free text, take-both, not a state column.

**Future-generalization note (not built):** today there are four ledgers with a single I2 column over a 2-state lattice. The I1/I2 invariants above already generalize — if a future ledger adds a second state-bearing column or a longer status lattice, it slots into I2 (per-key max over *that* column's lattice) with no new doctrine. No speculative N-column machinery is added now.

**Deterministic merge procedure (second-to-merge chore branch):**

1. On the second-to-merge chore branch, sync `main`: `git fetch origin main && git merge origin/main` (the standard Session-Start sync per [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) Session Start Checklist). The four ledgers conflict.
2. **I1 additive regions** (CHANGELOG, INDEX, DIGEST, and the RELEASE_LOG row + Deployment-Log block): in each conflict hunk, **keep both sides' new entries**, place each at the top/most-recent position the normal append would use, preserve the existing order, delete the conflict markers. Discard nothing; re-sort nothing.
3. **`RELEASE_LOG.md` status column** (I2): for **each** conflicting row, set the status to `max(ours, theirs)` over `DEPLOYED < VERIFIED` — `VERIFIED` if either side has `VERIFIED`, else `DEPLOYED`. In the canonical two-release case both rows end at `VERIFIED` (each side advanced its own row). Delete the conflict markers.
4. Run the two **post-resolution checks** below.
5. Stage the conflicted files explicitly (never `git add -A` per [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) § What NOT To Do), commit the merge with a message recording the per-ledger reconciliation (the worked-example merge below is the canonical message template), and proceed to the standard Phase B merge verification.

**Post-resolution checks (run before merging the resolved chore PR):**

- **Uniform CHANGELOG footer.** Verify every CHANGELOG entry the resolution touched carries the uniform `[Full notes] · [Release]` footer that every sibling entry carries. A concurrent resolution once surfaced an entry missing this footer (added by hand in the same merge); the additive merge does not synthesize it. Per-entry footer parity is a manual post-resolution check.
- **No duplicated `#### Deployment Log` block.** Verify the auto-merge did not duplicate a `#### Deployment Log vX.Y` H4 block in `RELEASE_LOG.md`. The status-row transition and the H4 Deployment-Log block are co-located, so a region-level conflict resolution can duplicate the block if both sides are taken wholesale. Confirm each version's Deployment-Log block appears exactly once. (This is a direct consequence of applying I1 to the row+block region — take-*both-versions*, not take-both-*sides*-of-the-same-version.)

**Worked example (real, on `main` — merge `35364dd`).** v1.23's Stage-13 chore PR (branch `chore/v1.23-stage-13-corpus`, parent `31ace16`) forked while its own `RELEASE_LOG` row read `DEPLOYED`; before it merged, v1.22's Stage-13 chore PR landed on `main` (parent `6cb889e`) and advanced the v1.22 row to `VERIFIED`. All four ledgers conflicted additively. Resolution: `CHANGELOG` / `INDEX` / `DIGEST` kept **both** the v1.23 and v1.22 entries at their landing positions (here v1.23 also happens to be the newer version *and* the later landing — in this adjacent-version case the two keys coincide, which is *why* the rule must be stated as preserve-landing-order, not sort-by-version, so it still holds when they diverge); `RELEASE_LOG` reconciled per-row — **the v1.22 row → `VERIFIED`** (from `main`'s side, its own close-out promoted it) **and the v1.23 row → `VERIFIED`** (from the PR's side, this PR is v1.23's close-out). The `35364dd` commit message records this per-ledger reconciliation verbatim and is the canonical template. Both rows read `VERIFIED` on `main` afterward — neither was regressed. (The same merge also added the v1.23 CHANGELOG `[Full notes] · [Release]` footer — the uniform-footer post-resolution check in action.)

**Reversibility (concurrent resolution):** CHEAP / HIGH — the resolved merge lands via the same Stage 13 chore PR; `git revert <Stage-13-chore-PR-SHA>` reverts the whole reconciliation atomically alongside the rest of the chore PR.

**Out of scope (recorded deferral):** automating the post-resolution checks — e.g. extending `deploy.sh --check` Check 32 to assert every `VERIFIED` `RELEASE_LOG` row has its INDEX / DIGEST / CHANGELOG companions present — is a CI-detection enhancement orthogonal to documenting the resolution doctrine, and is NOT built here (this is a doc-only doctrine). Check 32 today is LOG-row-driven (see Phase A8 above); a companion-presence extension would be a separate slice.

**Reversibility (Surface 2):** CHEAP / HIGH confidence — `git revert <Stage-13-chore-PR-SHA>` reverts the CHANGELOG.md prepend atomically alongside INDEX/DIGEST/NOTES + the RELEASE_LOG VERIFIED transition. The atomic landing matches the existing chore-PR rollback semantics; no special revert path needed.

**Phase B5.6 — Surface 1 verification (cross-stage check):** Phase B5.5 (CHANGELOG append, Surface 2) commits in the chore PR. Before the chore PR merge step, Stage 13 spoke verifies Surface 1 (GitHub Release for v<X.Y>) exists per the Stage 12 Phase B5.5 emit:

```bash
# Verify Surface 1 (GitHub Release) exists per Stage 12 Phase B5.5
if ! gh release view "v<X.Y>" --repo {REPO} >/dev/null 2>&1; then
  echo "WARN — Surface 1 (GitHub Release v<X.Y>) not present; Stage 12 Phase B5.5 may not have completed"
  echo "Routing options: (A) invoke release-executor Mode F to publish Surface 1 standalone; (B) Tier 2 [SCOPE CHANGE] per release-process.md § Inter-Stage Feedback Protocol"
  # Operator decision required before proceeding
fi
```

Surface 1 verification at Stage 13 catches partial-deploy scenarios where Stage 12 Phase B5.5 failed silently or was skipped. The check is non-blocking by default — operator decides routing (publish via Mode F, or accept residual + bundle into next release). When Surface 1 is missing, Stage 13 chore PR still proceeds with Surfaces 2+3; Surface 1 backfill is a separate operator action via Mode F.

**Phase B5.7 — `.version` stamp (release-cut-owned version source-of-truth):** The Stage 13 chore PR commit includes a write to the repo-root `.version` file, stamping it to the shipped version (`.version = v<X.Y>`). `.version` is the platform's version source-of-truth: the SessionStart version-skew hook ([`core/hooks/notify-version-skew.sh`](../../../core/hooks/notify-version-skew.sh)) reads it and compares against the latest published GitHub Release; `update.sh` Phase 5b and `setup-workspace.sh` install_hooks propagate it to the deployed `<ws>/.claude/.version` snapshot. The bump has no other owner in the pipeline — Stage 12 Phase B3 owns the git *tag*, not the `.version` *file* — so absent this phase the file freezes at a stale value and the version-skew banner reports a perpetual "update available" no `update.sh` can clear. Owned by `automated-closeout.sh` `phase_bump_version`: it writes atomically (temp + `mv`), is **idempotent** (no-op when `.version` already equals `v<X.Y>`), and **SKIPs with PASS** for a *version-less* / non-`vX.Y` release — there is nothing to stamp, so the file is intentionally left untouched and the SKIP is recorded in the close-out report (auditable, not silent). **Cutover / grandfather:** applies to releases entering Stage 13 strictly AFTER this phase's introducing-release merge SHA; the introducing release itself is exempt (reflexive-pipeline-loop discipline — it is version-less), and `.version` inside historical tags is immutable accepted-residual (only HEAD/`main` is correctable). **Reversibility:** CHEAP / HIGH — the `.version` write reverts atomically with the rest of the Stage 13 chore PR via `git revert <Stage-13-chore-PR-SHA>`. Drift backstop: `deploy.sh --check` Check 39 anchors `.version` against the latest published GitHub Release (warn-mode-initial).

**Cutover discipline:** Applies to all releases going forward.

Parser-clean PR body discipline applies. The Stage 13 chore PR does NOT auto-close any release issues — release-issue auto-close uses the release PR's standard auto-close keywords at Stage 12 Phase B1. Stage 13 chore PR bodies use safe phrasing throughout.

**Phase B merge verification protocol applies symmetrically:** The Stage 13 chore PR merge is a `gh pr merge` invocation and is therefore subject to the Phase B merge verification protocol codified at [`pipeline/stage-12-execute.md`](stage-12-execute.md) (Phase B merge verification protocol subsection). Assert `state == "MERGED"` AND `.mergeCommit.oid != null` immediately after `gh pr merge`; failure routes per the Phase B merge verification failure-routing table. The verify gates Phase C C1 Milestone close — Milestone close does not fire until Stage 13 chore PR merge is verified.

**Cutover:** Stage 13 chore PR merge verification applies to all Stage 13 chore PRs going forward.

Empirical motivation: a Stage 13 chore PR (2026-05-16) is the canonical worked example of the Stage 13 chore PR shape codified here; an earlier release PR (2026-05-15) is the historical operator-precedent that the chore-PR pattern emerged from.

**REST-preference annotation applies symmetrically:** The Stage 13 chore PR `gh pr create` invocation (canonical bash example above) is a GraphQL operation. When the Stage 12 chore-PRs (Phase B5 + Phase J.5 when applicable) and this Stage 13 chore PR all fire within the per-hour GraphQL budget window, the Stage 13 spoke SHOULD prefer REST endpoints (`gh api -X POST /repos/{REPO}/pulls --field title=... --field head=... --field base=main --field body=@/tmp/body.md`) over `gh pr create`. See the Phase B5 chore-PR creation — REST-preference annotation at [`pipeline/stage-12-execute.md`](stage-12-execute.md) for full evidence (a Stage 12+13 GraphQL exhaustion — 5026 units across 3 chore-PRs in single release) and cutover semantics. **Cutover:** The REST-preference annotation applies to all releases going forward.

**Cutover discipline:** Applies to all releases going forward.

**Phase C — Release Close-Out (Tier 1):**
C1 Close Milestone — gates on Phase A + B + B-OPS all verified. C2 Post close-out summary (issues closed, milestone closed, log updated, branch cleaned, Layer 2 deployed). C3 Flag carry-forward items for next cycle. C4 Orphan state cleanup (runs post-chore-PR, post-Milestone-close — see Phase C4 below).

**Phase C4 — Orphan state cleanup:** After C1 Milestone close, Stage 13 spoke invokes [`release/tools/cleanup-orphan-state.sh`](../../tools/cleanup-orphan-state.sh) with `--release-close <milestone-slug> --dry-run --markdown` to enumerate release-bound orphan branches (local + remote) and worktrees. Spoke posts the markdown report as a comment on the Stage 13 sub-task and awaits operator approval (Tier 1 Recommend gate per [CLAUDE.md Autonomy Tier table](<OPERATOR_INSTANCE_CLAUDE_MD>)). After approval, spoke re-invokes with `--apply --markdown` and posts the post-removal report as a second sub-task comment (durable PASS/SKIPPED/FAIL record). Removal scope per the orphan-cleanup spec Outcome 1: release branch (local + remote) and any worktrees whose branch is fully merged and clean. The script honors workspace-boundary discipline (operates only on paths under `${HOME}/Claude/`), defers to git porcelain safety (`git branch -d` refuses unsafe; `git worktree remove` refuses uncommitted), and consults `core/config/allowlists/cleanup-protect-list.txt` for operator-defined exclusions. Sequencing: C4 runs AFTER the Phase B Stage 13 chore PR has merged AND C1 Milestone close has fired — the release branch must be fully merged (zero unique commits vs `origin/main`) for the script to classify it as removable. The spoke's own worktree is protected in-script: the `SELF` action class marks the script's runtime worktree and is never removed (regardless of `--force`), and worktrees held by other live sessions are skipped with the distinct `live session` reason (fail-closed when the liveness check is unavailable). Detaching the spoke's worktree HEAD before `--apply` remains useful for a different reason — it releases the RELEASE BRANCH so it can drain in the same run (a SELF-protected worktree keeps its checked-out branch attached-and-skipped); branches freed by same-run worktree removals are then removed by the apply phase's resolve pass without a second invocation.

*C4 cutover: Orphan-state cleanup applies to all releases going forward.*

**Ticket lifecycle:** Claim: set Stage→13-Close. Execute: A1-A3 + B1-B4 + B-OPS1-4 + C1-C3. Resolve: post close-out summary, update state anchors. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** State Persistence (RELEASE_LOG.md, Milestone close); Tracking (auto-close via `closes #N`). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
All issues CLOSED (or documented-deferred), Milestone CLOSED, RELEASE_LOG.md status VERIFIED, user-facing release note at `release/releases/notes/vX.Y_RELEASE_NOTES.md` per [release-notes-standard.md](../standards/release-notes-standard.md), per-release close-out learnings register produced from [`release/references/templates/release-learnings-register-template.md`](../templates/release-learnings-register-template.md) and written to the operator-instance register path (full Kerth retrospective + full PMBOK 7 lessons-learned), verification evidence persisted, release branch deleted, pipeline-stages.md updated (when applicable), operational deployment manifest executed and verified, close-out evidence posted, carry-forward items tracked, G-CL6 design-artifact refresh verification (when Tier-A activation fired during this release, per [design-artifact-standard.md](../../../core/standards/design-artifact-standard.md) § 8).

*The release-note-at-Stage-13 output requirement applies to all releases going forward.*

**Close-out learnings register ↔ learnings-triple relationship (COEXIST):** The per-release close-out learnings register ([`release/references/templates/release-learnings-register-template.md`](../templates/release-learnings-register-template.md), filled to the operator-instance register path — the `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/` corpus root per [ADR-032](../../../core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md)) **coexists** with the machine-generated `#### Release Learnings v<X.Y>` triple H4 block emitted at Phase A7 — it does NOT replace or extend it. The relationship is directional: the triple's three fields (`Surprise` / `Would-change` / `Watch-for`) are **seed inputs** the operator transcribes and expands into the register's Kerth 3-question and PMBOK 7 Lessons / Next-cycle sections; the register cites the triple's source-row anchors. The triple remains machine-generated, unchanged, and authoritative for the cross-release pattern-detector (`synthesize-release-learnings.sh --mode pattern-detect`) and the `pipeline-event-log-schema.md` § 11.7 consumers — the register is a human reflection layered on top, not a second home for the same data.

*The close-out learnings register output requirement applies to all releases going forward.*

Stage 13 does NOT produce: design decisions (Stage 5), deployment execution (Stage 12), quality assessments (Stages 7-8).

**Canonical-form applicability (per the canonical-form-application discipline under the core disciplines set):** Stage 13 produces a canonical-form-framed artifact — the release close-out / lessons-learned surface (the per-release retro + lessons-learned register). When this stage produces that surface, produce it in its canonical form (the retro + lessons-learned register template) OR document partial-form conformance with explicit rationale per the application protocol; do not silently leave the canonical form partial-or-absent. The frame registry and the produce-OR-document-partial protocol live in the canonical-form-application discipline.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics (canonical IDs per [`schemas/gate-criteria-spec.md` Gate 13](../../../core/schemas/gate-criteria-spec.md#gate-13-close-readiness)): all issues CLOSED or documented-deferred (G-CL1), Milestone CLOSED (G-CL2), RELEASE_LOG.md VERIFIED (G-CL3), verification evidence persisted (G-CL4), operational deployment manifest fully executed (G-CL5), release branch deleted (structural — inherited from field-lifecycle-matrix Gate 13 Exit), carry-forward items tracked (structural — inherited).
Judgment (1-5): closure completeness, audit trail quality, carry-forward accuracy, operational deployment thoroughness.
Gate output: RELEASE COMPLETE / RELEASE INCOMPLETE (specify what is missing). Terminal stage — no Stage 14.

## 8. Automation Level
Overall Tier 1 (Auto-execute). Most automatable stage — all activities deterministic and API-driven. Only variable: schema migration execution (Tier 2).

## 9. Gap Summary
4 gaps. Key: no pipeline-stages.md compilation process (P2), no deferred item tracking protocol (P2). Expected additional gaps: automated manifest validation, deployment script generalization, schema migration framework.

## 10. Retro
To be populated after execution. Key design decisions: Milestone close gates on operational deployment. Deployment manifest section in release plan avoids artifact proliferation. Phase B-OPS respects concurrency rule (Cowork block between git operations).

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `release-synthesis` | `learnings-triple` | Per-release surprise / would-change / watch-for synthesis row emitted at Phase C (Release Close-Out); the Stage 13 synthesizer reads this row at Phase A7 to compose the per-release `#### Release Learnings v<X.Y>` sibling H4 block in `RELEASE_LOG.md` per [`pipeline-event-log-schema.md § 11`](../standards/pipeline-event-log-schema.md) | `hub` |
| `release-synthesis` | `qc4-05-result` | QC4-05 invariant re-verification outcome per Phase A4; one row per AV-N invariant with `payload` carrying invariant ID + verdict (PASS/FAIL) + affected files | `spoke:#N` |
| `release-synthesis` | `qc4-06-result` | QC4-06 goal-attainment verdict per Phase A10; one row per release with `payload` carrying `verdict` (ATTAINED / PARTIALLY-ATTAINED / NOT-ATTAINED) + `outcome_excerpt` (Outcome AFTER paragraph quote) + `evidence_anchor` (Change Description URL or Success Indicator output) | `spoke:#N` |

Cutover: audit-trail capture applies to all releases going forward, including the `qc4-06-result` sub-type.
