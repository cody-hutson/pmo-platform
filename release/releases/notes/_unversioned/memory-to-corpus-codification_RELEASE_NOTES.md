---
version: memory-to-corpus-codification
date: 2026-06-10
type: note
issues: ["#356", "#357"]
pr: "#604"
links:
  plan: release/releases/plans/memory-to-corpus-codification_RELEASE_PLAN.md
  log_anchor: "#deployment-log-memory-to-corpus-codification"
reversibility-tier: CHEAP
themes: ["epic:knowledge-corpus", "cluster:process-protocol", "cluster:documentation"]
summary: "Verification-only close-out: all nine codified behavioral rules confirmed already in the tracked docs with provenance; three redundant operator memories archived and retired. Version-less (no vX.Y, no tag, no GitHub Release)."
requires_action: false
breaking: false
components: ["core/CLAUDE.md.template", "core/rules/git-workflow.md", "operator memory store"]
followups: ["#633", "#429"]
---

# Codified knowledge verified in the tracked docs; duplicate memories retired

2026-06-10 · memory-to-corpus-codification (version-less)

This release closed out knowledge-codification work that earlier workstreams had already completed: it verified that all nine targeted behavioral rules live in the platform's tracked documents (with the who/when provenance recorded), retired the three now-redundant operator memory files after archiving them in the release record, and reconciled the tickets and milestone description to live state. Nothing in the platform's shipped content changed.

> **Skip the rest** unless you audit what shipped in this release or maintain the operator memory store.

## Who this affects

- The workspace operator auditing the knowledge-codification close-out, and the operator's own agent sessions (the memory store no longer duplicates the tracked git-workflow rules). No impact on anyone else using the platform.

## What changed for everyone using the platform

No user-visible behavior changes — see operator detail below.

## Known limits

- **Version-less by design.** No `vX.Y` is assigned and no git tag or GitHub Release is cut; the release ships under the slug `memory-to-corpus-codification`, and the release-tracking corpus carries the slug in place of a version with a `(none)` Tag column.
- **The retired memory bodies survive in the release record only.** The three superseded memory files were archived verbatim in the Stage 12 evidence comment before deletion (and went to the Trash, not a hard delete); they are not restored anywhere in the repository — the tracked rules are the single source of truth.
- **A deploy-state gap was found, not fixed.** Verification surfaced that the deploy-managed rules mirror is absent at this operator instance (no deploy step lays it down, and the corresponding deploy check skips its pairs); that gap is out of scope here and is filed separately as a follow-up.

Report issues at https://github.com/cody-hutson/pmo-platform/issues.

## Reversibility

CHEAP / HIGH confidence. The repository side reverses via `git revert` of the plan and corpus commits (git history is the snapshot). The operator-instance eviction is restorable verbatim from the Stage 12 archive comment — the full file bodies, index lines, and ledger row were posted before any deletion, and deletion used the Trash. Standard rollback window.

---

### Operator and engineering detail

**Verification-only release shape (D-Disposition A)** — Stage 4's G-PL1 currency gate found both tickets' corpus work already complete on main: all five #356 workspace guardrails (whole-plan approval, authorization-scope enumeration, skill-boundary transparency, surgical edits, harness-tooling governance) present in `core/CLAUDE.md.template`, and all four #357 git-workflow rules (fast-forward-by-default primary sync, never-restore-uncommitted-deletions, parser-clean PR-body discipline, reviewer-field-expected-empty) present in `core/rules/git-workflow.md`. A line-by-line content-richness diff of the three surviving memories against the corpus found no load-bearing nuance missing — on one of the three the corpus is a strict superset (it adds title-scan coverage the memory lacked). The operator-rendered disposition: no re-authoring, no invented stage work; evidence plus closure routing, with Stage 5/7/8 SKIP per the approved stage-applicability matrix. The deliverable repo diff is empty; release PR #604 carried the committed plan only (Engineering Commit 0).

**Provenance — why a no-fix diff is the correct release shape** — all nine ticket-described changes pre-date this release. Two landed in the original repository's lineage: the never-restore-uncommitted-deletions rule (2026-04-18 commit) and the PR-body close-keyword discipline (2026-05-12 commit, since CI-enforced). Seven — the five workspace guardrails plus fast-forward-by-default and reviewer-field-expected-empty — were authored in the clean-room public-seed build and are present in this repository's first commit (2026-06-05); the original repository's final corpus greps 0 for them, confirming the seed build as their origin. The tickets migrated to this repository open (archived v1 comments are the migration fingerprint) and were bundled without AC re-verification; the Stage 4 currency gate was the first re-check. The operator challenged the no-fix diff twice at the Stage 9 gate and rendered GO on the provenance-complete briefing.

**Stage 12 operational deploy (the release's only substantive mutation)** — executed on the operator instance, outside git, under the Standing-GO authorization: the verbatim pre-deletion archive (full bodies of the three memory files, the three index lines, the ledger row) was posted to the Stage 12 sub-task first; the three files were then moved to the Trash (recoverable), the three index lines removed from the memory store's index, and the release's codification-ledger row evicted per the store's own encode-and-evict contract. Post-state verification: 3/3 PASS (file-absence scan, index scan, ledger-row count — literal commands and outputs on the Stage 12 sub-task). The primary checkout was fast-forwarded to the merge SHA.

**Reconciliations executed at the gate** — the milestone description was amended (D-Scope A): the third value item belongs to #429 through its own Triage, sizing corrected to ~8 pts across 2 issues, and the Outcome Statement / Release Class / Parallelization Map blocks added. The consumed Stage-5-deferral phrasing in #356's body was neutralized (Tier 1 input-correction). Stale paths in the migrated AC text were reconciled in-plan: the deployed-workspace guardrail file maps to the tracked template, and the legacy runtime-rules path maps to the tracked rules module (the single tracked source).

**Process notes** — version-less identifier (D-Identifier A; zero deliverable diff means no platform increment for a version to mark), standard two-PR shape (D-Topology A; this Stage 13 chore PR carries the LOG row folded from Stage 12 Phase B5 as an approved deviation), `routine` class (D-ReleaseClass A; Light engagement / Standard Stage 9 / SKIP-where-trivial Stage 5 / 30-day outcome window). The automated close-out could not run for this release — its CLI validation rejects a version-less identifier before its preflight, which would in turn exit on the deliberately-folded LOG row and the absent tag — so the documented Phase B chore-PR fallback applied. The 2026-05-23 intake-pre-rendered-artifacts pattern was confirmed as a second instance and promoted (N=2): already-satisfied issues take the verification-only delivery route.

For full implementation detail see the [RELEASE_LOG.md entry](../RELEASE_LOG.md#deployment-log-memory-to-corpus-codification) and [the release plan](../plans/memory-to-corpus-codification_RELEASE_PLAN.md).

### References

- Milestone: memory-to-corpus-codification
- Release PR: [#604](https://github.com/cody-hutson/pmo-platform/pull/604) at `5b8eb2df14eec9edd28b3bbcf9d58cb70281e511`
- Issues: [#356](https://github.com/cody-hutson/pmo-platform/issues/356) · [#357](https://github.com/cody-hutson/pmo-platform/issues/357) — both marked closed at Stage 13 with reconciled per-AC evidence
- Stage 4 plan + Decision Record: [#578](https://github.com/cody-hutson/pmo-platform/issues/578) · Stage 12 evidence + pre-deletion archive: [#602](https://github.com/cody-hutson/pmo-platform/issues/602) · Stage 13 close: [#603](https://github.com/cody-hutson/pmo-platform/issues/603)
- Tag: (none) — version-less release, no git tag and no GitHub Release cut
- Follow-ups (out of scope): [#633](https://github.com/cody-hutson/pmo-platform/issues/633) (deploy-managed rules-mirror gap discovered at verification) · [#429](https://github.com/cody-hutson/pmo-platform/issues/429) (migration-playbook scope owner through its own Triage)
