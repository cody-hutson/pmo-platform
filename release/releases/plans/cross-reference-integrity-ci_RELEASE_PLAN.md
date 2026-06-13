<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
---
version: cross-reference-integrity-ci
date: 2026-06-12
type: plan
issues: ["#314", "#169", "#130"]
pr: null
---

# Release Plan — cross-reference-integrity-ci

Version-less release. Milestone `cross-reference-integrity-ci`. Release Class `novel`. Branch topology D-C SINGLE.
This file is the Engineering Commit 0 transcription of the approved Stage 4 plan plus the Collective Review
scope-lock decision; the issue and sub-task numbers it cites are listed inline below and resolve in this repo.

## Stage 4 Planning record

## Stage 4 Release Planning — cross-reference-integrity-ci

> Milestone #112 · 3 issues (#314, #169, #130) · planning spoke output. READ-ONLY pass — no code changed. All file:line claims verified against the worktree @ `origin/main` 51794f2.

### Summary (30 seconds)

Three file-disjoint CI workflows that all enforce reference-integrity at PR-time. Two are clean builds; **#130 requires a re-scope** because its load-bearing input artifact (`imp-references.tsv`) is absent from the repo and its entire git history. Recommended posture:

- **Release Class: `novel`** — ≥1 new file/workflow per issue + ≥3 D-class decisions in this plan. (Not `cross-cutting`: zero `pipeline/stage-*.md` edits, zero governance-surface edits — the File Change Matrix is all `.github/workflows/` + tooling.)
- **Branch topology: D-C SINGLE** — one `release/cross-reference-integrity-ci` branch, sequential Engineering. Plan file **slug-named** (`cross-reference-integrity-ci_RELEASE_PLAN.md`), **no `v1.12` assignment** (modern convention is slug-named milestones + slug-named plans; defer version-tag to operator).
- **#130 disposition: Option C+D** — re-scope to forward-looking CI (flag live IMP-XXX in skill specs + skill-count drift), needing NO historical TSV; split the routing-conflict-detection portion into its own issue (the `run_eval_audit.py` harness already exists and is out of scope for a CI release).
- **Implementation sequence: #314 → #169 → #130** (ascending build-risk; #314 hardens an existing surface, #169/#130 stand up new ones).
- **Top risks:** (R1) #314 shared-snippet refactor touches the Check-31/hook/CI tri-surface; (R2) #169 baseline is stale AND the naive primitive over-reports `<OPERATOR_INSTANCE_*>` tokens; (R3) #130 scope is partly dead-on-arrival.

---

### Dependency Graph

```
#314 ──(none)──>     standalone   (hardens reference-durability.yml — existing surface)
#169 ──(none)──>     standalone   (new link-check.yml — new surface)
#130 ──(none)──>     standalone   (new skill-count/IMP CI — new surface)

Outbound (NOT in this milestone):
#130 ──Blocks──> #235  (native GitHub dep; #235 is OPEN in milestone #197
                        field-first-intake-enforcement, R10/Later horizon)
```

**Directional deps among the three: NONE.** [SOURCE] Verified the three target workflow files are file-disjoint: `reference-durability.yml` (exists, #314 edits it), `link-check.yml` (absent, #169 creates it — `ls` confirmed No such file), and a skill-count workflow (absent, #130 creates it — 0 grep hits for `skill.count|IMP-[0-9]` across `.github/workflows/`). No issue's AC requires another's output.

**Shared-tooling caveat (not a hard dep, a contention edge — see Contention Map):** #314's PREFERRED fix factors a shared positional-`#N` snippet invoked by hook + Check 31 + CI. That snippet lives in/near `core/hooks/` + `core/deploy/deploy.sh`. #130's forward CI, if it reuses the same fixture-runner harness pattern, could touch adjacent `core/hooks/` tooling. This is a **soft edge** resolved by sequencing, not a blocking dependency. [INFERRED from reading block-fragile-refs.sh + deploy.sh Check 31.]

**Outbound dep `#130 Blocks #235`:** [SOURCE] #130 body carries `**Blocks:** #235` under a `roadmap-deps` marker. #235 verified OPEN, milestone #197 (a different, Later-horizon milestone). This is an outbound roadmap edge — it does NOT gate this release's execution, but it is a reason #130 should remain a tracked issue (not silently dropped) even if re-scoped. Note: GitHub **milestone #130** (`immutable-adr-system`) is a *different object* from **issue #130** — independent namespaces; do not conflate.

---

### Implementation Sequence

**Recommended order: #314 → #169 → #130** (under D-C SINGLE; one Engineering chip at a time per hub Procedure 2 parallelism rules — Stage 6 is write-serialized on the release branch).

| # | Issue | Why this position |
|---|---|---|
| 1 | **#314** | Lowest risk: hardens an EXISTING, already-green surface (`reference-durability.yml` + 23/23 fixtures). If the PREFERRED shared-snippet refactor is chosen, doing it first means #130's forward-CI work (which may reuse the fixture-runner pattern) builds on the consolidated snippet rather than racing it. |
| 2 | **#169** | Medium: new workflow, but the engine (`check-doc-links.py`) already exists and is battle-tested via Check 14. The real work is the Stage 5 mechanism decision + baseline re-establishment, not net-new tooling. |
| 3 | **#130** | Highest: requires re-scope adjudication (D-130-Rescope) BEFORE Engineering can start. Sequencing it last lets the operator's re-scope decision settle while #314/#169 ship. |

[INFERRED] Sequence is by ascending build-risk + the shared-snippet ordering benefit; the three are dependency-independent so any order is *correct*, but this order minimizes rework.

---

### Stage Applicability Matrix

Default = all stages 5–13 apply. Per the persona spec: skip Solutioning (5) only if trivial; skip Dev/QA (7–8) only if no functional impact. **All three ship CI logic with real functional impact → Stages 7–8 apply to all three.** No skips recommended for 7–8.

| Stage | #314 | #169 | #130 | Rationale |
|---|---|---|---|---|
| **5 Solutioning** | ✅ APPLY | ✅ APPLY (**key**) | ✅ APPLY (**key**) | #314: the (a) standalone-position-aware vs (b) PREFERRED shared-snippet choice is a real design fork → Solutioning. #169: mechanism (reuse `check-doc-links.py` vs lychee vs link-check-action) is **explicitly deferred to Stage 5 by the issue** (Req 6 / AC #6) AND the `<OPERATOR_INSTANCE_*>` token-handling problem must be designed → Solutioning is load-bearing. #130: the re-scope itself (post D-130-Rescope) needs a Stage 5 design for the forward-CI rule set. |
| **6 Engineering** | ✅ APPLY | ✅ APPLY | ✅ APPLY | All three write files. |
| **7 Dev Testing** | ✅ APPLY | ✅ APPLY | ✅ APPLY | CI logic = functional. #314 must add a divergence fixture (24th case) + prove hook/CI agree on it. #169 must test against current main (broken-ref detection actually fires + excludes tokens). #130 must test the IMP-XXX/skill-count detector fires + does not over-fire on closed-issue historical refs. |
| **8 QA Testing** | ✅ APPLY | ✅ APPLY | ✅ APPLY | Independent verification of the DT evidence; warn-mode-initial posture must be confirmed per `bypass-mode-readiness.md`. |
| **9 Plan Review** | ✅ (release-level gate) | — | — | One gate for the release. `novel` class → **Deep** review depth. |
| **10–11** | ✅ APPLY | ✅ APPLY | ✅ APPLY | Compressed for git-native CI changes per harness-deployment.md (Stages 10–11 compress). |
| **12 Execute** | ✅ (release-level) | — | — | One Execute gate; RELEASE_LOG row + visible-H4 Deployment Log chore PR. |
| **13 Close** | ✅ (release-level) | — | — | One Close chip; INDEX + DIGEST + RELEASE_NOTES + Check 14 flip-to-enforce assessment line item (per doc-link-maintenance.md). |

**No stage is skipped for any issue.** Justification for not skipping 7–8 (the spec's caution): all three deliverables are enforcement logic whose false-positive/false-negative behavior is the entire point — untested CI gates that under- or over-fire are worse than none.

---

### Contention Map

The three **workflow files** are disjoint. The contention surface is the **shared tooling** under `core/hooks/` and `core/deploy/`, gated by which #314 fix path is chosen and how #130 is re-scoped.

| Shared surface | #314 | #169 | #130 (re-scoped C+D) | Contention verdict |
|---|---|---|---|---|
| `.github/workflows/reference-durability.yml` | **EDIT** (lines 126–139: the `hasblock`-existence awk → position-aware) | — | — | No contention (sole owner). [SOURCE: lines 127–138, `else if (hasblock == 0)` confirmed position-blind.] |
| `.github/workflows/link-check.yml` | — | **ADD** (new) | — | No contention (new file). [SOURCE: `ls` → absent.] |
| `.github/workflows/<skill-count>.yml` | — | — | **ADD** (new) | No contention (new file). [SOURCE: 0 grep hits.] |
| `core/hooks/block-fragile-refs.sh` | **EDIT if PREFERRED** (extract positional logic ~209–238 to shared snippet) | — | — | Sole owner *within this release*. But it is a durable-corpus-adjacent hook — Engineering must keep the byte-identical-regex invariant intact. |
| `core/deploy/deploy.sh` Check 31 (lines 3275–3368) | **EDIT if PREFERRED** (re-point Check 31 positional logic at shared snippet) | — | possibly EDIT (if #130 adds a Check for skill-count, it may extend Check 5 area lines 1320–1397) | **POTENTIAL CONTENTION** if both #314 (PREFERRED) and #130 edit `deploy.sh`. Mitigation: sequence #314 before #130 (already the recommended order); Stage 6 is write-serialized so they cannot race on branch HEAD anyway. |
| `core/hooks/run-fragile-ref-fixtures.sh` + `core/hooks/testdata/cutover-fixtures.txt` | **EDIT** (add 24th divergence fixture) | — | possibly reuse harness pattern | Low: #314 owns the fixture file; #130 (if it builds a skill-count fixture) would create a *separate* fixture file, not edit this one. |

**Resolution:** D-C SINGLE topology + the #314→#169→#130 sequence makes all `deploy.sh` edits land sequentially on `release/cross-reference-integrity-ci`. The hub's Procedure-2 file-contention boundary (FILE-level under SINGLE) already refuses concurrent Engineering chips touching `deploy.sh`. **No parallel Engineering.** [SOURCE: hub-spoke-bridge.md Procedure 2 File-contention boundary table — D-C SINGLE blocker boundary = FILE.]

---

### File Change Matrix

Machine-readable (one repo-relative path per line; `intent` = add/edit; owning issue in brackets). Paths under the PREFERRED #314 path and the recommended #130 re-scope (C+D). Exact contents are Stage 5/6 outputs — this is the change-surface envelope.

```
.github/workflows/reference-durability.yml        edit   [#314]
core/hooks/block-fragile-refs.sh                  edit   [#314 — PREFERRED shared-snippet path only]
core/deploy/deploy.sh                             edit   [#314 — PREFERRED shared-snippet path; #130 — if skill-count check extends Check 5/31 area]
core/hooks/run-fragile-ref-fixtures.sh            edit   [#314 — divergence fixture wiring]
core/hooks/testdata/cutover-fixtures.txt          edit   [#314 — add refblock-below-body divergence case]
core/hooks/lib/positional-issueref.sh             add    [#314 — PREFERRED: extracted shared positional-#N snippet; exact path Stage 5]
.github/workflows/link-check.yml                  add    [#169]
core/rules/doc-link-maintenance.md                edit   [#169 — document the PR-time workflow as standing protection; or a new protocol doc]
.claude/skip-doc-link-check.txt                   edit   [#169 — repo-resident allowlist for <OPERATOR_INSTANCE_*> token class; Stage 5 decides mechanism]
.github/workflows/skill-count-imp-check.yml       add    [#130 — re-scoped forward CI; exact name Stage 5]
core/deploy/tools/check-skill-count-imp.py        add    [#130 — re-scoped forward CI detector; Stage 5 decides reuse-vs-new]
release/releases/plans/cross-reference-integrity-ci_RELEASE_PLAN.md   add   [release — Stage 4 plan, Engineering Commit 0]
```

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-06-12, domain: software }` — the File Change Matrix is entirely internal pmo-platform artifacts (CI workflows + Python/bash tooling). Sourcing-exempt (pipeline-internal); domain-classified `software` (the deliverables are scripts/CI code, not governance prose). [SOURCE: stage-04-planning.md § A1.5 + A3-time deliverable-domain classification — "a release adding application source/tests is `domain: software`".]

---

### Risk Register

**Per-issue:**

| ID | Issue | Risk | Likelihood/Impact | Mitigation | Reversibility |
|---|---|---|---|---|---|
| R-314a | #314 | PREFERRED shared-snippet refactor touches the hook + Check 31 + CI tri-surface; a bug in the extracted snippet regresses ALL THREE enforcement points at once. | MED / HIGH | Land the divergence fixture FIRST (red), then refactor to green; keep the byte-identical-regex invariant; DT must prove hook + CI agree on the new fixture. Fallback: ship the (a) standalone-CI-position-aware fix, which is lower-blast-radius (CI-only). | CHEAP (`git revert`; additive) |
| R-314b | #314 | The divergence case (self-describing `#N` with refblock BELOW it) is currently a **false-negative in CI only** (hook already catches it). Shipping the fix flips previously-passing PRs to failing if any open PR carries that shape. | LOW / LOW | warn-mode-initial (per the issue: "only bites at flip-to-enforce"). CI scans added-lines delta only; pre-existing corpus unaffected. | CHEAP |
| R-169a | #169 | **Baseline AC #6 ("~50 broken refs") is STALE.** [SOURCE] Running `check-doc-links.py` over #169's governance+skill scope returns **210 rows** — but they are dominated by `<OPERATOR_INSTANCE_*>` localization tokens (intentional placeholders), not real broken links. The naive primitive over-reports massively. | HIGH / HIGH | **Stage 5 must (a) re-establish the baseline against current main, and (b) design token-class exclusion** — Check 14 only reads GREEN because it relies on an operator-instance `skip-doc-link-check.txt` allowlist (deploy.sh line 1888) that CI will NOT have. A PR-time CI workflow needs a repo-resident allowlist OR a primitive change to skip angle-bracket placeholder paths. | CHEAP (workflow is one file) |
| R-169b | #169 | Mechanism choice (reuse `check-doc-links.py` vs lychee vs link-check-action) is genuinely deferred. Reusing the primitive is lowest-risk (already validated) but inherits the token-handling gap; an external action (lychee) handles links well but does not know the platform's reference conventions. | MED / MED | **Stage 5 decision — do NOT pre-decide.** Recommend reuse of `check-doc-links.py` as the strong default (it is the same engine Check 14 already trusts), with the token-exclusion work as the scoped delta. | CHEAP |
| R-130a | #130 | **Scope partly dead-on-arrival.** [SOURCE] `imp-references.tsv` absent from working tree AND full git history (0 commits for `**/imp-references.tsv` and `*legacy-imp-audit*`). The literal "consume the TSV via positional awk" AC cannot execute. ~half of #130's body (5 refinement recs, 12 LOW-IMP dispositions, F4 range-syntax, csv-quoting) are disposition decisions about the absent dataset → VESTIGIAL. | CERTAIN / HIGH | **D-130-Rescope** (below). Re-scope to forward CI (no TSV needed). Salvageable ACs: skill-count-drift fires; IMP-XXX-in-skill-specs detection. Dead ACs: the 4 TSV-consumer/refinement/disposition ACs. | n/a (re-scope, not rollback) |
| R-130b | #130 | The routing-conflict-detection portion (sub-item 3, "extends `run_eval_audit.py`") is a different capability class (cross-skill trigger analysis) from a CI reference-integrity check. [SOURCE] `run_eval_audit.py` EXISTS (240 lines, pairwise-Jaccard cross-skill harness) — it already partially fulfills sub-item 3 and is NOT a TSV consumer. | MED / MED | **Split** sub-item 3 to its own issue (Option D). It is not reference-integrity CI; bundling it bloats this milestone and couples two unrelated capabilities. | CHEAP (split = new issue, no code) |

**Release-level:**

| ID | Risk | Mitigation |
|---|---|---|
| RL-1 | **All three are warn-mode-initial CI.** A warn-log is blind to false negatives. Shipping three new/changed enforcement surfaces simultaneously risks a coordinated calibration gap. | Each issue's DT must include a positive-detection test (the gate actually fires on a known-bad input), not just "workflow runs". #314 already has the fixture discipline (extend it); #169/#130 must add equivalent fixture/positive-case tests. [SOURCE: reference-durability.yml fixture self-test precedent, lines 29–39.] |
| RL-2 | **Stale-input class across the milestone.** #169 (~50 baseline) and #130 (TSV) both rest on point-in-time artifacts that have since diverged. Pattern Cache Scan (M3) flags this as the `audit-baseline-when-target-population-is-empty` / stale-snapshot class. | Re-baseline #169 at the release-branch SHA + document in the plan; re-scope #130 off the dead artifact. Cite the v11.01b Hybrid-baseline precedent. [SOURCE: confirmed pattern `feedback_release_ops_audit_baseline_when_target_population_is_empty`.] |
| RL-3 | Rollback complexity: LOW across the board. All deliverables are additive CI/tooling; `git revert` restores prior state; warn-mode means no PR is hard-blocked during shakedown. | Standard `git revert` per file; no data migration, no governance-file mutation. |

---

### Recommendations

**Merge/split:**

1. **#130 — SPLIT (recommended).** Carve the routing-conflict-detection portion (sub-item 3, `run_eval_audit.py` extension) into its own issue. Rationale: it is a cross-skill-trigger-analysis capability, not a reference-integrity CI check; the harness already exists; bundling couples unrelated work and inflates an already-re-scope-heavy issue. The new issue is NOT added to this milestone — it routes to backlog for independent triage. [This is a Recommendations-section note per scope guardrails; no issue is created by this spoke.]
2. **#314 / #169 — keep separate.** File-disjoint, different surfaces, different personas of work (harden-existing vs stand-up-new). No merge benefit.
3. **No merges recommended.** The three are independent; the milestone's coherence is thematic (reference-integrity CI), not file-level.

**#130 re-scope options (full enumeration — operator chooses at D-130-Rescope):**

- **(A) Recover the TSV** from archived `cody-hutson/pmo-platform-original` (verified: EXISTS, PRIVATE, ARCHIVED, reachable read-only via `gh`). Cost: clone/fetch the artifact, re-home it, consume as-written. **Reversibility MODERATE, confidence MEDIUM.** Downside: re-imports a stale 2026-05-02 dataset describing a corpus that no longer exists post-re-versioning — it would re-baseline against fiction. Not recommended.
- **(B) Regenerate** the dataset by scanning the *current* corpus for IMP-XXX occurrences. **Reversibility CHEAP, confidence MEDIUM.** Produces a live dataset but adds a scan-and-curate sub-project; the dataset is an intermediate artifact (governance-debt risk per "intermediate-artifact discipline") unless absorbed into the CI rule directly.
- **(C) Re-scope to forward-looking CI** — a PR-time check that flags (a) live IMP-XXX references in skill specs and (b) skill-count drift in issue/file bodies. Needs NO historical TSV. [SOURCE] This is exactly the gap: Check 5(c) (deploy.sh lines 1366–1386) only blocks hardcoded counts in 3 specific governance docs at *deploy-time*; nothing checks skill-count/IMP-XXX at *PR-time* across issue bodies or skill specs. **Reversibility CHEAP, confidence HIGH.** **Recommended.**
- **(D) Split** the routing-conflict portion to its own issue (as above). **Reversibility CHEAP, confidence HIGH.** **Recommended, combined with C.**

**Recommended #130 disposition: C + D.** Re-scope the issue body to the forward-CI deliverable named in the milestone #112 description ("when a legacy IMP-XXX/skill-count drift reference appears"), mark the 4 TSV-consumer/refinement/disposition ACs as superseded, and split sub-item 3. This requires a `gh issue edit --body` at Stage 5 (Tier 1 [ADJUST] / crisping pre-gate per stage-04-planning.md Phase A0.5/A0.6) — flagged here, executed under operator approval, not by this planning spoke.

**Out-of-scope discoveries (noted, not actioned):**

- **Issue-vs-milestone number collision risk:** GitHub milestone #130 = `immutable-adr-system`; issue #130 = the TSV-consumer task. Independent namespaces. Hub should reference "issue #130" explicitly in chips to avoid mis-routing.
- **#169 AC #6 phrasing** ("expected ~50 per X1") references the consumed-and-absent 2026-04-18 tree-audit. Recommend the Stage 5 spoke replace it with a freshly-measured baseline + the token-exclusion note, per Tier 1 [ADJUST].
- **Check 14 ↔ #169 overlap:** Check 14 already runs `check-doc-links.py` over #169's exact target scope at deploy-time. #169 is the *PR-time mirror* of an existing deploy-time check — Stage 5 should frame it as "promote Check 14's primitive to a PR gate," which de-risks the mechanism choice substantially (reuse the trusted engine).

---

### Operator Decisions

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke-proposed class + trigger-condition evidence per `release/references/specs/release-class-taxonomy.md` Class Enum.
**Gate decision:** Choose between (A) routine, (B) **novel**, (C) cross-cutting, (D) hotfix.
**Blocks:** Stage 3 Phase B3 milestone-description `## Release Class` section; downstream per-class differentiation posture (engagement density, Stage 9 depth).
**Upstream compatibility:** N/A — Release Class is PMO-platform-internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Trigger evidence:**
- `novel` trigger (a) **FIRES** — ≥1 issue introduces a new file: #169 adds `link-check.yml`, #130 adds a skill-count workflow, #314 (PREFERRED) adds a shared snippet lib. [SOURCE: File Change Matrix `add` rows.]
- `novel` trigger (b) **FIRES** — ≥3 D-class decisions in this plan (D-ReleaseClass, D-C, D-130-Rescope). [SOURCE: this Operator Decisions block.]
- `cross-cutting` trigger (a) does NOT fire — **0** `pipeline/stage-*.md` files in the matrix. [SOURCE: matrix is all `.github/` + `core/hooks/` + `core/deploy/` tooling.]
- `cross-cutting` trigger (b) does NOT fire — **0** of {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, RELEASE_LOG.md, hub-spoke-bridge.md, gate-criteria-spec.md, release-process.md} edited.
- `cross-cutting` trigger (c) does NOT fire — 0 in-bundle compositional edges (the DAG is fully disconnected).
- `routine` does NOT fit — new files added (violates routine trigger (c)) and D-class decisions present (violates routine trigger (d)).
**Differentiation posture (novel):** Engagement density **Standard**; Stage 9 review depth **Deep**; Stage 5 activation bias **ALL** (cross-issue compositional surface + the #169/#130 design forks); Stage 13 outcome-window **30-day**.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable per Re-Classification Protocol; cheaper-to-stricter is CHEAP).
**Recommendation:** **(B) novel.** Aggregate shape is new-enforcement-surface work with genuine Stage 5 design questions, but the blast radius is confined to CI/tooling (no governance, no pipeline-spec edits) — which is precisely what separates `novel` from `cross-cutting` here.

#### D-C Branch Topology: SINGLE branch or per-issue branches?
**Gate input:** Three file-disjoint workflow deliverables; one shared-`deploy.sh` contention edge (#314 PREFERRED + #130).
**Gate decision:** (A) **SINGLE** — one `release/cross-reference-integrity-ci` branch, sequential Engineering commits, plan as Engineering Commit 0. (B) OPTION-A — per-issue branches + per-issue PRs.
**Blocks:** Procedure 1 scaffolding (sub-task creation); Engineering chip routing model; plan-file commit mechanism.
**Upstream compatibility:** N/A — branch topology is release-mechanics, does not touch skill-authoring surface. Upstream compatibility check does not apply.
**Analysis:**
- Weighing OPTION-A: the three workflows are file-disjoint, which *superficially* favors parallel per-issue PRs. BUT — (1) the shared `deploy.sh` edge between #314-PREFERRED and #130 means two PRs could touch the same file → contention shifts to PR-merge order (OPTION-A's failure mode), erasing the parallelism benefit. (2) Only 3 issues, one of which (#130) blocks on a re-scope decision — parallelism has little to bite on. (3) OPTION-A adds 3 chore-PR ceremonies (plan PR + per-issue PRs); for a 3-issue CI release that is overhead.
- Weighing SINGLE: sequential Engineering is exactly what the contention map wants (deploy.sh edits serialize); the hub's Procedure-2 FILE-level blocker already enforces it; one PR diff is one Stage 9 review surface.
**Naming proposal:**
- Branch: `release/cross-reference-integrity-ci` [SOURCE: modern slug-milestone convention — milestones #112–143 are all slug-named, no version numbers.]
- Plan file: `release/releases/plans/cross-reference-integrity-ci_RELEASE_PLAN.md` [SOURCE: 3 most-recent plans are slug-named — `domain-aware-stage5-design`, `intake-elicitation-skill`, `memory-to-corpus-codification`.]
- **Version tag: DEFER to operator. Recommend NOT assigning `v1.12`.** The `v1.NN` line tops at v1.11 but the milestone is slug-named per the newer initiative-roadmap convention; assigning a `v1.12` would mix conventions. If the operator wants a semver tag at Stage 12, that is a Stage-12 decision — Stage 4 recommends the slug as the canonical release identifier.
**Reversibility / Confidence:** MODERATE / HIGH (topology is set at scaffolding; switching mid-release re-scaffolds sub-tasks).
**Recommendation:** **(A) SINGLE** with slug-named branch + plan file, no version tag.

#### D-130-Rescope: How is #130 re-scoped against the absent imp-references.tsv?
**Gate input:** [SOURCE] `imp-references.tsv` absent from working tree AND full git history (0 commits, verified via `git log --all --oneline -- '**/imp-references.tsv'` and `-- '*legacy-imp-audit*'`). Archived `pmo-platform-original` (PRIVATE/ARCHIVED) holds the only copy. Check 5(c) enforces hardcoded-count-in-3-docs at deploy-time; NO PR-time skill-count/IMP-XXX check exists (0 grep hits in `.github/workflows/`). `run_eval_audit.py` exists (240 lines, cross-skill Jaccard harness) — already partially does sub-item 3.
**Gate decision:** (A) recover TSV from archive; (B) regenerate from current corpus; (C) re-scope to forward CI needing no TSV; (D) split routing-conflict portion to its own issue. [Options combinable.]
**Blocks:** #130 Stage 5 Solutioning + Engineering cannot start until the operator picks a scope; the issue body's 6 ACs cannot all be satisfied (4 are dead-on-arrival).
**Upstream compatibility:** REQUIRED-assessment — does this touch skill-authoring surface? **Partially.** A forward CI check that flags "live IMP-XXX in skill specs" READS `{core,operations,release}/skills/*/SKILL.md` but does NOT change what a skill must contain. It is a *detector over* the skill-authoring surface, not a *rule that modifies* it. Verdict: **aligned / no upstream conflict** — the Anthropic skill-creator schema (`name:` + `description:` frontmatter) is untouched; the check adds no required field. The PMO `version:` extension and existing skill structure are unaffected. [SOURCE: skill-deployment.md § Version Field + upstream-reference-catalog `skill-md-frontmatter` entry referenced in decision-discipline.md § 7.4.]
**Per-option reversibility / confidence:**
- (A) recover: MODERATE / MEDIUM — re-imports a stale dataset describing a pre-re-versioning corpus; risks baselining against fiction.
- (B) regenerate: CHEAP / MEDIUM — live data but adds an intermediate-artifact sub-project (governance-debt risk).
- (C) forward CI: CHEAP / HIGH — directly fills the verified PR-time gap; no dependency on any historical artifact.
- (D) split: CHEAP / HIGH — decouples an unrelated capability; the harness already exists.
**Reversibility / Confidence (overall):** CHEAP / HIGH for the recommended combination.
**Recommendation:** **(C) + (D).** Re-scope #130's body to the forward-CI deliverable (flag live IMP-XXX in skill specs + skill-count drift in bodies), mark the 4 TSV-dependent ACs superseded-with-rationale, and split sub-item 3 (routing-conflict detection) to a new backlog issue. Salvageable ACs from the current body: "skill-count-drift CI fires when count diverges" + "flags live IMP-XXX in skill-spec paths at PR-time". Dead ACs: "consumes imp-references.tsv as input", "schema 9-column positional ordering preserved/used as query interface", the 5-refinement-recommendation adjudication, the 12-LOW-IMP disposition, the F4 range-syntax decision, the csv-quoting requirement — all are about the absent dataset. The body edit is a Tier-1 [ADJUST] / crisping action executed under operator approval at Stage 5, NOT by this planning spoke.

---

*Decision discipline (per `core/disciplines/decision-discipline.md` § 3): all three D-decisions are D-class → M1 Localization applied (each cites file:line platform context, not generic heuristics). M3 Pattern Cache Scan — domain `release-ops` — cited the confirmed `audit-baseline-when-target-population-is-empty` pattern against RL-2 (#169 stale baseline + #130 absent artifact are the same stale-snapshot class; v11.01b Hybrid-baseline precedent applies). No new observation to log — no operator correction occurred in this planning pass. Evidence quality labels applied throughout: [SOURCE] = verified against worktree files/git/gh; [INFERRED] = analytical conclusion from verified inputs.*

---

## Collective Review — Scope-Lock Decision (Stage 5 → Stage 6)

**Decision:** LOCK + fold the 13 pre-existing broken refs into issue #169 scope. (Operator-rendered 2026-06-12.)
**Authority:** Collective Review scope-lock gate; novel-class → Deep review. Engineering becomes Tier-3 (post-scope-lock).

### Locked scope
- **issue #314** — extract a shared `positional-issueref.awk` classifier + a diff-hunk→file-line mapper; rewire {hook, fixture-runner, CI}; new `ISSUEREF-POS` fixture (24th case, RED-first). Does NOT touch `deploy.sh`. (Spec: sub-task #688)
- **issue #169** — promote `core/deploy/tools/check-doc-links.py` to a PR gate (`link-check.yml`) + angle-bracket token exclusion in `is_internal()` + thin **tracked** CI allowlist + doc update. **EXPANDED per scope-lock:** also drain the 13 pre-existing broken refs — 11 legacy `pmo-platform/*` path-drift in `core/CLAUDE.md.template`, 2 illustrative version refs in `release-notes-standard.md` — to a 0 real-residual baseline at ship. (Spec: sub-task #689)
- **issue #130** — new `core/deploy/tools/check-skill-count-imp.py` + `.github/workflows/skill-count-imp-check.yml` (live IMP-XXX in skill specs + drift-aware skill-count vs runtime authority = 23); ships green / warn-mode-initial. Body re-scoped; routing-conflict portion split to issue #704 (off-milestone). (Spec: sub-task #690)

### Stage 5 refinements to the Stage 4 plan (verified by hub)
1. **Contention DISSOLVED** — the release is fully file-disjoint. Check 31 carries no positional issue-ref logic (0 `ISSUEREF_RE` hits in `deploy.sh`), and #130 is new-files-only — the plan's #314↔#130 `deploy.sh` edge does not exist.
2. **#314 deepened** to a diff-hunk→file-line mapper — the accurate fix. The current CI compares an added-delta-line index against a head-file line number (two coordinate spaces); a true positional check needs the mapper. Cost is identical for fix-paths (a) and (b), so the anti-drift shared-snippet path is chosen.
3. **#130 fully re-scoped** off the absent `imp-references.tsv` (absent from tree + entire git history); split issue #704 filed.

### Routing
Engineering (Stage 6) runs sequentially **#314 → #169 → #130** on `release/cross-reference-integrity-ci` (D-C SINGLE, write-serialized). First Engineering commit lands the release-plan file as Engineering Commit 0.
