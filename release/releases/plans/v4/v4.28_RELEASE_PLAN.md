<!-- reference-durability: allow-link -->
# Release Plan — skill-suite-conformance

> **Milestone:** `skill-suite-conformance` · **Release Class:** `novel` · **Version:** slug-identified; the concrete number is **bound at the Stage-12 atomic claim** *(bump-class `minor`)* · **Scope:** 4 issues, 12 effective pts (inside the 10–15 band; G3-15 bound 25) · One release branch, one PR, one merge gate · **Branch:** `release/skill-suite-conformance` (slug-only, no version prefix).

This plan is the Stage-4 release plan (rendered 2026-08-14 Friday) written to disk as **Engineering Commit 0** by the first Stage-6 spoke, reconciled with the four Stage-5 Solutioning outputs, the hub's adversarial evaluation, and the **Collective Review scope-lock** (LOCKED, 2026-08-14, with three reconcile-while-touching additions folded in). Deltas discovered after Stage 4 are folded into the Deviation Log rather than silently applied.

**Reference discipline for this file.** Cards are named by their sequence position and their capability, not by bare ticket number, so this plan stays readable when the numbers age out of anyone's head. Every bare ticket reference is confined to the designated block at the end, each with a summary noun phrase, per the reference-durability standard.

| Card | Short name | Capability |
|---|---|---|
| **Card 1** | **detection-scope** | The package-rebuild query stops emitting path segments no consumer can build, and the close-out names the skill that actually failed |
| **Card 2** | **check-49-identifier** | One mode identifier per check, across all four sites, with a bindable mode path |
| **Card 3** | **citation-widening** | The citation-anchor predicate sees every fragile line anchor, not only the ones in one filename |
| **Card 4** | **material-edit** | The version-bump rule fires on effect rather than field, and the skills it should have bumped get bumped |

## Version identity — NOT bound in this plan

The release runs **slug-identified**. No version literal appears in this file, in the branch name, or in any commit subject on this branch; the concrete number is recomputed next-free and claimed atomically at the Stage-12 merge tag (defer-to-claim). The durable declaration here is the **bump-class (`minor`)**, not a number.

**Commit-0 version re-verify — executed, verdict PROCEED.** Run by the first Engineering spoke immediately before this file was written, per the codified single detect-and-HALT procedure:

| Step | Result |
|---|---|
| Refresh authoritative host state | `git fetch --tags origin` + `git fetch origin main` — both clean; `origin/main` at `8f48357f` |
| Recompute next-free for bump-class `minor` | The version-claim adapter's dry-run resolved next-free against its `anchor()` + `claimed_set()` operations and returned the slot the Stage-4 D-Version determination had recorded |
| Planned slot in the claimed set? | **No.** Tag-arm and ledger-arm specificity probes both returned zero against observed non-zero controls; the ledger arm read the origin ref, never a worktree copy |
| Verdict | **PROCEED** — planned slot equals recomputed next-free and is unclaimed |

The re-verify is a **single** detect-and-HALT: it does not auto-recompute-and-retry. Three concurrent hubs recorded the same provisional slot on 2026-08-14 and a fourth release is in flight, so a re-anchor at the Stage-12 claim is **expected, not exceptional** — that is the atomic-claim rung's job, not this one's.

## Summary (30 seconds)

Four cards, one theme: **a gate or check that names a thing must name it consistently, scope it correctly, and be provably able to fail.** Zero hard dependency edges; one dominant planning axis — `core/deploy/deploy.sh` contention.

- **Card 1 (detection-scope, Severity Major) leads.** It repairs the Stage-13 close path *this very release will use at its own close*, and every card after it enlarges the package-rebuild candidate set that path resolves. Landing the repair before the exposure grows is the whole sequencing argument. Two fixes: the builder's `--skills-for-paths` query mode stops emitting path segments no consumer can build, and the close-out's batch rebuild becomes a per-skill loop that names the skill that actually failed instead of indicting twenty-one innocents.
- **Card 2 (check-49-identifier)** unifies the Check 49 mode identifier across **four** sites — not the three the ticket records — on `check-convention`, and repairs an operator-facing guidance line that names a directory the mode resolver can never read.
- **Card 3 (citation-widening)** widens Check 66's first citation arm from a single filename to any `<basename>.md:NNN` and ships **no exemption surface**: the class the ticket worried about has zero observed members, and use-vs-mention is already handled structurally by requiring a literal digit run.
- **Card 4 (material-edit)** takes **Option C**: both repairs in one commit. The 12 stale `version:` fields are a real defect via the *behavior* bullet, and the *frontmatter* bullet is separately over-broad because it names a **field** where every sibling names an **effect**.

**Release Class `novel`** — Stage-5 activation bias ALL (which is why Card 2 got a Stage 5 at all), Stage-9 review depth **Deep**, Stage-13 standard outcome window. **Concurrency posture P0 fully-serial** — forced by the contention map, not chosen. **One commit per issue**, which is the rollback granularity, not a style preference.

## Change Description

*Phase C1 (G6-05). This section is authored by the FINAL Stage-6 Engineering spoke, after every per-issue commit has landed, so that it describes what shipped rather than what was planned — per RELEASE_PROTOCOL § Change Description Protocol. It is committed on the release branch BEFORE the PR is transitioned draft→ready at the Stage-9 gate, so it is visible in the PR diff at Plan Review. The section anchor is established here at Commit 0; its six sub-sections (Outcome / Issues resolved / Key decisions / Reversibility / Downstream impact / Cross-references) are filled at Phase C1.*

## Dependency Graph

**Hard dependency edges within the release: 0.** All six ordered pairs were examined individually — this is not an unevidenced "these are independent." Three pairs returned a *non-null* result (two coordination edges, one risk-ordering preference), which is the sensitivity evidence that the pairwise probe discriminates.

| Ordered pair | Edge? | Evidence |
|---|---|---|
| citation-widening → check-49-identifier | **No** | Different `deploy.sh` check blocks (Check 66 vs Check 49). Neither's acceptance criteria reference the other's surface. |
| check-49-identifier → citation-widening | **Coordination only** | Card 2 establishes the one-identifier-per-check invariant for Check 49. Check 66 **already** satisfies it, so Card 3 has nothing to wait for; it must only *preserve* the invariant. Carried as **CIAC-1**, not an edge. |
| material-edit → detection-scope | **Risk-ordering only** | Card 4's skill edits stale packages and enlarge *this release's own* Stage-13 rebuild candidate set. But all of them resolve cleanly under the current unfiltered rule (a), so Card 4 does not require Card 1's fix to succeed. A sequencing preference, not a dependency. See R3. |
| detection-scope → material-edit | **No** | Card 1's first acceptance criterion is measured against the v4.10 diff, not this release's diff. |
| material-edit → citation-widening | **Coordination only** | Both perform `SKILL.md` edits requiring sanctioned skill-editor sessions. **Skill sets are disjoint** — Card 3's anchor-conversion surface is `pmo-release-manager`, already correctly bumped and explicitly not in Card 4's set. |
| citation-widening → material-edit | **No** | Same reasoning, reversed. |

**Cross-milestone edges (outbound, not blocking this release's build):**

- **Card 3 versus the sibling card in the warn-mode-gate-graduation milestone** — block-level contention on `deploy.sh` Check 66's definition block. A merge-order serialization point, not a dependency. See R1.
- **Cards 2 and 3 versus the in-flight corpus-tolerance draft PR** — an open sibling editing `deploy.sh`, insertion-dominant (**+163 lines**, corrected from the planning spoke's 180) above both edit ranges. Offset shift only; no semantic conflict. See R2.

## Implementation Sequence

**Approved (operator, Stage-4 D-4):** `detection-scope → check-49-identifier → citation-widening → material-edit` — superseding the Stage-3 bundling order.

| # | Card | Why here |
|---|---|---|
| 1 | **detection-scope** | The only Severity-Major card, and the only one touching **zero** contended surfaces. It repairs the Stage-13 close path this release itself will use, and steps 2–4 all enlarge that path's candidate set. |
| 2 | **check-49-identifier** | The smaller of the two `deploy.sh` edits. Establishes the one-identifier-per-check invariant **before** the larger block edit lands, so Card 3 is authored against a settled convention rather than racing it. |
| 3 | **citation-widening** | The larger `deploy.sh` edit (Check 66 block) plus the predicate script. Placed after Card 2 so its block edit is checked against the fresh invariant, and after Card 1 so its skill edit meets a repaired rebuild phase. |
| 4 | **material-edit** | Last. Its Option-C matrix is the largest (13 authored files plus an ADR plus regenerated packages), so sequencing it last means all skill-version work sits adjacent and the Stage-13 rebuild runs once against a settled corpus. |

**Commit discipline:** **one commit per issue** on the release branch, plus **Commit 0** — this plan file and the two script-execution allowlist entries — which carries no issue work. This is load-bearing for rollback: Cards 2 and 3 share `deploy.sh`, so a per-issue revert is only clean if their changes are in separate commits.

## Stage Applicability Matrix

| Card | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9–S13 |
|---|---|---|---|---|---|
| **detection-scope** | APPLY (complete) | APPLY | **APPLY** | APPLY | APPLY |
| **check-49-identifier** | APPLY (complete) | APPLY | **APPLY** | APPLY | APPLY |
| **citation-widening** | APPLY (complete) | APPLY | **APPLY** | APPLY | APPLY |
| **material-edit** | APPLY (complete) | APPLY | **APPLY** | APPLY | APPLY |

**Stage 7 is not skippable on any card.** The milestone's own Success Indicator states the release-level bar as *the gate or check each card names must demonstrate a real failure on a fixture before it is trusted* — and every card carries a fixture-or-demonstration obligation that nothing else discharges:

| Card | Demonstration obligation | Why Stage 7 only |
|---|---|---|
| citation-widening | Pre-change predicate returns zero **and** post-change returns non-zero — *both arms run and recorded* | A single-arm result is exactly the broken probe Check 66's own control block warns about |
| check-49-identifier | A per-check override binds on **both** the enforce ladder **and** the predicate-script-missing error path | The whole defect is that one arm worked and the other did not; a one-arm test reproduces the bug as a pass |
| detection-scope | 21 candidates not 22 on the v4.10 diff, **and** a regression fixture proving a genuinely unbuildable skill still fails the phase | See R4 — the release's sharpest anti-regression constraint |
| material-edit | The cross-tabulation conformance probe executed and recorded, all four cells reported | A zero cell that is never reported cannot be distinguished from a cell that was never run |

## Contention Map

**Baseline pin (audit-baseline discipline):** `origin/main` @ `8f48357f`, measured 2026-08-14 (Friday); re-confirmed at Commit 0 by the version re-verify fetch.

| File | citation-widening | material-edit | check-49-identifier | detection-scope | Class |
|---|---|---|---|---|---|
| `core/deploy/deploy.sh` | **W** Check 66 block | — | **W** Check 49 block | **R** roster arrays + sync map, awk-extracted at runtime | same-file, **disjoint blocks** (~1,430 lines apart) |
| `core/deploy/tools/check-citation-anchors.sh` | **W** | — | — | — | single-card |
| `core/deploy/tools/README.md` | **W** | — | — | — | single-card |
| `core/deploy/tools/build-skill-packages.sh` | — | — | — | **W** | single-card |
| `release/tools/automated-closeout.sh` | — | — | — | **W** | single-card |
| `release/references/pipeline/stage-13-close.md` | — | — | — | **W** | single-card |
| `core/deploy/tests/test_check49_mode_identifier_unification.sh` | — | — | **W** (NEW) | — | single-card |
| `core/standards/version-field-semantics.md` | — | **W** | — | — | single-card |
| 12 × `{operations,release}/skills/*/SKILL.md` | — | **W** | — | — | single-card |
| `core/config/allowlists/script-execution-allowlist.txt` | — | — | — | — | **Commit 0** (release infrastructure) |

**Within-release verdict:** the only shared file is `core/deploy/deploy.sh`, and the two writers occupy disjoint check-definition blocks. Overlap class is single-PR — no shared line ranges. Under SINGLE topology these serialize at commit level regardless, so no scope split is needed.

**Address every `deploy.sh` surface by CHECK NUMBER and marker comment, never by line number.** The in-flight sibling PR inserts 163 lines above both edit ranges; every line anchor in the Stage-4 and Stage-5 artifacts is orientation only.

## Risk Register

| ID | Risk | Sev | Reversibility | Mitigation |
|---|---|---|---|---|
| **R1** | **Card 3 and the sibling card in the warn-mode-gate-graduation milestone edit the same `deploy.sh` Check 66 definition block.** The Parallelization Map originally recorded a file-level soft coupling; the real class is a block-level overlap. | **HIGH** | MODERATE | Recorded as a **Tier-S block-level serialization edge** (operator, Stage-4 D-3). Whichever merges second re-baselines by hand. The conflict is semantic, not merely textual — both cards edit the same block's prose. Fix merge order at Stage 12. |
| **R2** | **The in-flight corpus-tolerance PR inserts 163 lines into `deploy.sh` above both edit ranges.** Every line number in the planning artifacts shifts if it merges first. | MED | CHEAP | Address blocks by check number and marker comment, never by line number. Re-measure at Stage 9 Phase A6.6. |
| **R3** | **Card 4's Option-C matrix stales 12 `.skill` packages**, enlarging this release's own Stage-13 rebuild candidate set — the very surface Card 1 repairs. | MED | MODERATE | Card 1 sequences first, so the repaired rebuild phase is in place before the exposure grows. Graded by **CIAC-2**. |
| **R4** | **Card 1's fix could convert a loud stop into a silent pass** — strictly worse than today, and invisible until a real build failure is swallowed at a future close. | MED | **EXPENSIVE** (a swallowed failure surfaces only at the next broken close) | The anti-regression fixture is a **hard Stage 7 requirement**. Arms `d1` (a genuinely unbuildable but roster-resolvable skill still FAILs) and `d2` (its converse) are the anti-regression pair; they share one sandbox and one mode and differ **only** in the candidate's resolvability, so resolvability is provably the variable under test. Stage 8 grades this criterion explicitly. |
| **R5** | **Card 3 widens a predicate on a gate a sibling milestone may flip to enforce.** | MED | MODERATE | Mitigating evidence on record: the enforce branch is precondition-blocked — both gates are deploy-time-only, and the gate-efficacy standard bars a required posture for a deploy-time-only check. Stage 5 additionally measured the post-widening in-scope finding count at **0**, so the widening is enforce-compatible immediately. **Re-verify at Stage 9** — the precondition claim is about the sibling milestone's state, not ours. |
| **R6** | **The package builder awk-parses `deploy.sh` at runtime** for four roster arrays and the template sync map. Two cards write to that file. A structural change to an array literal returns **empty**. | MED | MODERATE | Read-ranges are disjoint from all planned write-ranges — safe today. The builder's roster guard exists but **omits `CANARY_SKILLS`** (a guard with a canary-shaped hole, not an absent guard). Carried as **CIAC-3** so the invariant is graded on the merged PR rather than assumed. **Do NOT add a `CANARY_SKILLS` emptiness precondition in this release** — it would break the version-claim tool's package self-test sandbox, whose stubbed `deploy.sh` declares only three arrays. |
| **R7** | **Card 2's rename silently un-binds an operator-instance mode file under the retired identifier.** Mode files are never committed, so a clean clone is unaffected and CI cannot catch it. | LOW | CHEAP | The card's third criterion requires naming the retired identifier in the definition block. The surviving identifier is **`check-convention`** — the only mode filename ever surfaced to an operator — which minimizes the set of operators whose existing file breaks. |
| **R8** | **Rollback granularity.** Two cards share `deploy.sh`; a single squashed commit makes per-issue revert impossible. | MED | — | **One commit per issue** on the release branch. |

## Rollback Strategy

Single release branch, one PR, one merge. **Release-level rollback** is a single revert of the merge commit — **CHEAP**, no data loss, no external state. **Per-issue rollback** is CHEAP *only if* the one-commit-per-issue discipline holds (R8). One asymmetry: reverting Card 4 restores 12 stale `version:` fields *and* re-stales 12 `.skill` packages, so a package rebuild must follow any such revert — **MODERATE** for that card alone. Commit 0 is separately revertible and carries no issue work; reverting it would remove this plan file and the two script-execution allowlist entries, which would re-block the Stage-7 primitives.

## Release Class Declaration

**`novel`** (operator, Stage-4 D-2; re-classified from the declared `routine`). The `routine` trigger *"zero new decision-class items in the release plan"* fails on the same evidence that fires the `novel` trigger *"at least one decision-class item in the release plan"* — Card 4's material-edit determination is one by construction. `class_weight` 1.0 → 1.15; `effective_pts` 10 → 12, inside the 10–15 band and under the G3-15 bound of 25.

**Differentiation posture:** engagement density Full/Standard · Stage-9 review depth **Deep** (blast-radius assessment plus design-spec conformance plus Empirical Verification) · Stage-5 activation bias **ALL** · Stage-13 outcome window standard.

### Domain Practice Provenance

Stage-4 Phase A1.5 label, recorded here rather than in frontmatter because this plan carries none. Single-line and machine-readable, per the Stage-4 placement convention.

domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-14, domain: software }

**Sourcing exemption.** The entire File Change Matrix is internal pmo-platform artifacts — shell tooling, pipeline specs, a governance standard, skill definitions and their packages. No external best-practice is consulted, so the external-sourcing step is exempt and `source` carries the pipeline-internal token. Sourcing-exempt does **not** make the release domain-less, which is why the `domain` field below is still populated.

**Classification rationale (from the File Change Matrix, per the A3-time rule).** Dominant domain **`software`**. Three of the four cards change executable shell logic and nothing else: `core/deploy/tools/build-skill-packages.sh` and `release/tools/automated-closeout.sh` (Card 1), `core/deploy/deploy.sh` Check 49 plus a new `core/deploy/tests/test_check49_mode_identifier_unification.sh` harness (Card 2), and `core/deploy/tools/check-citation-anchors.sh` with the Check 66 block (Card 3). The release's whole theme is the behaviour of check and gate *code* — whether it can name a thing consistently, scope it correctly, and be provably able to fail. Secondary domain **`governance`**, carried by Card 4's `core/standards/version-field-semantics.md` bump rule, the twelve `SKILL.md` frontmatter edits, the `stage-13-close.md` reconciliation and the ADR. The secondary is recorded in this rationale rather than inside the label, so the `domain` value stays a bare class name that resolves in one lookup to `core/standards/domain-best-practices/software.md`.

## Operator Decisions (D-Gate Block)

| ID | Decision | Verdict | Reversibility / confidence |
|---|---|---|---|
| **D-4** | Plan approval + Release Outcome Statement | **APPROVED as re-sequenced** — `detection-scope → check-49-identifier → citation-widening → material-edit` | MODERATE / HIGH |
| **D-2** | Release Class | **`routine` → `novel`** | CHEAP / HIGH |
| **D-3** | Cross-milestone overlap disposition | **Upgraded to a Tier-S block-level serialization edge.** Coordination note only — no card moves, no composition change | CHEAP / HIGH |
| **D-1** (material-edit) | Material-edit determination | **Option C — both repairs, one commit, 13 files.** The card's "one of the two is true" framing was falsified: the 12 files are stale via the **behavior** bullet, while the **frontmatter** bullet is separately over-broad because it names a *field* where every sibling names an *effect*. Both are defective; both are repaired | MODERATE / HIGH |
| **D-5299-A** (citation-widening) | Exemption surface | **Ship none.** 0 of 6 distinct targets in the measured population are intra-skill, and use-vs-mention is handled structurally by requiring a literal digit run | CHEAP / HIGH |
| **Allowlist** | Stage-7 execution blocker | **Add both primitives to the script-execution allowlist as part of this release** — landed in Commit 0 | MODERATE / HIGH |
| **Collective Review** | Scope-lock | **LOCKED** with three reconcile-while-touching additions included | MODERATE / HIGH |
| **D-C Branch Topology** | — | **SINGLE** — one release branch, one PR, one merge | CHEAP |
| **D-Concurrency Posture** | — | **P0 fully-serial** — forced by the contention map. Force-push (including `--force-with-lease`) is prohibited on the shared release branch | CHEAP |
| **D-Version** | — | Recorded determination, not a click-gate. Bump-class `minor`; the number binds at the Stage-12 atomic claim | — |

**Scope additions folded in (all three selected at Collective Review):**

1. **check-49-identifier** — fix the unbindable `core/hooks/` mode path in the Check 49 guidance comment. The mode resolver reads the operator-instance path form and then `.claude/hooks/<id>.mode`; `core/hooks/` is in neither tier, so an operator following shipped guidance creates a file that silently does nothing — the card's own defect class, inside the very line its third criterion must edit.
2. **detection-scope** — pass the repo-root flag on the ***build*** invocation, not only the detection call. The detection call passes it and a structural self-test arm asserts it; the build call does not, and building into the wrong tree *writes* there.
3. **detection-scope** — reconcile rule (b)'s stale prefix enumeration in `stage-13-close.md`, which still names the two prefixes the delegated-detection release removed.

## Cross-Issue Acceptance Criteria

Three cohesion constraints span two or more cards. Graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR.

- [ ] **CIAC-1 (check-49-identifier × citation-widening — `deploy.sh` check-definition blocks).** After both land, **every** check whose definition block this release touches resolves its mode and emits its findings under **one identifier**, and its operator-facing guidance message names that same identifier. *Method:* pair every `resolve_check_mode "<id>"` with each `flag_warn_or_issue "<id>"` **within a narrow same-block window** and assert the identifier set per touched block has cardinality 1. **A 120-line window produces 11 false splits from cross-block bleed — use a narrow window and report the MATCH count alongside the SPLIT count, so a zero cannot come from a dead probe.**

- [ ] **CIAC-2 (material-edit × detection-scope — the Stage-13 package-rebuild candidate set).** Run against **this release's own diff**, `build-skill-packages.sh --skills-for-paths` yields a candidate set in which **every** element resolves to a packageable skill via the builder's own module resolver, and `phase_rebuild_skill_packages` returns PASS, not FAIL with exit 3. This is the release proving its own close path against the enlarged candidate set its skill edits create. *Method:* feed the release diff's changed-path list into the query mode; assert each candidate resolves and that no candidate triggers a `cannot resolve module for` error.

- [ ] **CIAC-3 (citation-widening × check-49-identifier × detection-scope — `deploy.sh`'s runtime-extracted array literals).** After all `deploy.sh` edits land, the builder's runtime awk extraction still returns **non-empty** for `OPERATIONS_SKILLS`, `RELEASE_SKILLS`, `CORE_SKILLS`, `CANARY_SKILLS` **and** the template sync map. Two cards write to a file a third card's fix reads by structural parse; an empty extraction is a **silent** failure for the rosters — only the map has a guard, and that guard omits the canary array. *Method:* invoke the query mode on a known skill path; assert non-empty output and absence of the map-extraction error.

## File Change Matrix

Machine-readable — one path per line, `INTENT  path  — note`. Stage 7/8/9 chip prompts extract this list deterministically.

```
# ── Commit 0 — release infrastructure (no issue work) ──
ADD   release/releases/plans/skill-suite-conformance_RELEASE_PLAN.md  — written after the Commit-0 version re-verify returned PROCEED
EDIT  core/config/allowlists/script-execution-allowlist.txt  — register check-citation-anchors.sh + build-skill-packages.sh (four invocation forms each); operator-approved, unblocks Stage 7
# ── Card 1 · detection-scope (#4755) ──
EDIT  core/deploy/tools/build-skill-packages.sh  — relocate the module resolver above the query dispatch; gate query rule (a) on roster resolvability; leave rule (b) unfiltered with an inline rationale
EDIT  release/tools/automated-closeout.sh  — per-skill build loop naming only the failed skills; pass --root on the BUILD call; reconcile the now-false coupling comment; six new Test 11 fixture arms
EDIT  release/references/pipeline/stage-13-close.md  — Phase B5.9 rule (a) resolvability precision + delegation statement; rule (b) stale prefix enumeration reconciled
# ── Card 2 · check-49-identifier (#4753) ──
EDIT  core/deploy/deploy.sh  — unify the Check 49 identifier at all FOUR sites on check-convention; retirement note; correct the unbindable core/hooks/ mode path (scope addition 1). Locate by the block's opening marker, NEVER by line number
ADD   core/deploy/tests/test_check49_mode_identifier_unification.sh  — two-arm binding proof + pre-fix discriminator + drift guard + CIAC-1 structural assertion
# ── Card 3 · citation-widening (#4750) ──
EDIT  core/deploy/tools/check-citation-anchors.sh  — widen the first arm from one filename to any <basename>.md:NNN; extend the inline fixture set (FLAG-3 sensitivity / CLEAN-3 specificity)
EDIT  core/deploy/deploy.sh  — Check 66 definition block prose. Locate by check number and marker comment, NEVER by line number
EDIT  core/deploy/tools/README.md  — the missed Affected File surfaced at Stage 5
# ── Card 4 · material-edit (#4752), Option C — both repairs, one commit ──
EDIT  core/standards/version-field-semantics.md  — Bump Rules frontmatter bullet reframed field->effect; cosmetic list addition; NEW Conformance Probe section; Version History row
EDIT  operations/skills/delivery-engine/SKILL.md
EDIT  operations/skills/pmo-business-analyst/SKILL.md
EDIT  operations/skills/pmo-portfolio-manager/SKILL.md
EDIT  operations/skills/pmo-process-designer/SKILL.md
EDIT  operations/skills/pmo-program-manager/SKILL.md
EDIT  operations/skills/pmo-project-manager/SKILL.md
EDIT  operations/skills/pmo-technical-analyst/SKILL.md
EDIT  operations/skills/pmo-technical-program-manager/SKILL.md
EDIT  operations/skills/weekly-status-rollup/SKILL.md
EDIT  release/skills/release-executor/SKILL.md
EDIT  release/skills/release-hub/SKILL.md
EDIT  release/skills/release-planner/SKILL.md
ADD   release/ADRs/ADR-<next-free>-<kebab-title>.md  — number allocated next-free across BOTH ADR directories at authoring time, never reserved above a sibling's unmerged claim
REBUILD packages/<skill>.skill  — one per edited rostered skill, with its .sha256 content-baseline sidecar, in the SAME commit (CI-gated pre-merge)
#     release/skills/pmo-release-manager/SKILL.md  — NOT in Card 4's set: already correctly bumped at v4.10
# ── DELETE (none) ── MOVER-SET (empty) ──
```

Paths marked with a leading `#` and no INTENT verb are review-only or deliberately-not-edited. The `<next-free>` and `<skill>` tokens are resolved by the owning card's Engineering spoke at authoring time — they are deliberately not frozen here, because an ADR number reserved above a sibling's unmerged claim blocks the repo, and a package set frozen before Card 4's commit would go stale.

## Verification Plan

| # | Command | Expected |
|---|---|---|
| V1 | `bash core/deploy/deploy.sh --check` | Zero genuine `FAIL:` lines. Operator-instance drift in the instance-path checks is not a release failure — grep for the literal two-space `  FAIL:` prefix rather than reading the issue count |
| V2 | `bash core/deploy/deploy.sh --check` → Check 7 | OK (package content-hash freshness; the authoritative staleness signal after Card 4's rebuilds) |
| V3 | `bash core/deploy/deploy.sh --check` → Check 14 | OK across every modified markdown file (doc-link integrity) |
| V4 | `bash release/tools/automated-closeout.sh --self-test` | All Test 11 arms pass, including the six new ones (a5, a6, a7, d1, d2, c5) and the pre-existing control arm a3 |
| V5 | `bash core/deploy/tools/build-skill-packages.sh --root <repo> --skills-for-paths` on the v4.10 first-parent diff | **21** candidates, not 22; `_shared` absent; the 21 all roster-resolvable. This is the definitive measurement, owed at Stage 7 because a security control blocked it at Stages 4 and 5 |
| V6 | The same query with `operations/skills/_templates/system-specialist/SKILL.md` on stdin | Empty — `_templates` is a **live second** non-skill directory on `main`, so a hardcoded `_shared` exclusion would ship already broken |
| V7 | `bash core/deploy/tests/test_check49_mode_identifier_unification.sh` | All arms pass; the pre-fix discriminator fails on unmodified `deploy.sh` |
| V8 | `bash core/deploy/tools/check-citation-anchors.sh` pre- and post-change over the FLAG-3 fixture | Pre-change **0** findings, post-change **2** — both arms run and recorded; a single-arm result does not satisfy the criterion |
| V9 | `bash core/deploy/tools/check-citation-anchors.sh` over the in-scope corpus | In-scope finding count **0** post-widening, so the widening is enforce-compatible. Apply the gate's own path-class scope predicate — a raw grep and a gate predicate are different instruments, and the naive form returns 7 false hits under the exempt evals path class |
| V10 | The material-edit conformance probe, both units of analysis | All **four** cells of the 2×2 reported, including any zero. A zero cell that is never reported cannot be distinguished from a cell that was never run |
| V11 | `python3 release/tools/check-adr-numbers.py` | PASS — contiguous, no duplicates, no gaps, with the new ADR present |
| V12 | `bash core/deploy/deploy.sh --check` → Check 27 | OK (spoke-runtime posture surface undrifted) |
| V13 | CIAC-3 probe: the builder's runtime awk extraction after all `deploy.sh` edits | Non-empty for all four roster arrays **and** the template sync map; no map-extraction error |

**Probe-validity discipline applies to every row above.** Any claim of the form "0 occurrences" / "no findings" / "CLEAN" / "N of M" carries its invocation, its denominator, a sensitivity arm with an observed non-zero, a specificity arm with an observed zero, and evidence the extraction was non-empty for the subject and each arm. **A zero whose control arm also returned zero is a BROKEN PROBE** — report the probe unusable, never the population empty. This release has already produced three substring-collision false positives and one false non-zero from a probe that failed to apply its target's own scope predicate.

## Deviation Log

Deltas discovered after the Stage-4 plan, folded in here rather than silently applied.

| ID | Stage | Delta | Disposition |
|---|---|---|---|
| **DEV-1** | 5 | `operations/skills/_templates/` is a **live second** non-skill directory on `main` — the census is 58 skill-root directories, 56 in-roster, 2 out (`_shared`, `_templates`). The "a second non-skill directory added later" premise is not hypothetical | **Absorbed** — a hardcoded `_shared` exclusion would ship already broken. Becomes fixture arm `a6`. Ticket body left unamended as historical record |
| **DEV-2** | 5 | The version-claim tool is a **second live consumer** of the builder's query mode; the same latent defect exists there | **Absorbed, no scope change** — the filter fixes it for free. Recorded so Stage 8 credits the fix rather than reading it as scope creep |
| **DEV-3** | 5 | check-49-identifier has **four** identifier sites, not the three the ticket records — the exit-3 scan-surface log line is a fourth | **Absorbed** into Card 2's edit set |
| **DEV-4** | 5 | citation-widening's Affected Files omitted `core/deploy/tools/README.md` | **Absorbed** into Card 3's matrix |
| **DEV-5** | 5 | The hub's own widened-predicate probe measured 7 hits against the Card 3 spoke's claimed 0. All 7 are under an evals path class the gate exempts | **Spoke was right; the hub's probe was broken.** Recorded so the false non-zero does not propagate into Engineering |
| **DEV-6** | 5 | "The correction set is 17, not 12" (material-edit) | **REFUTED.** The 5 additional skills are absent from the v4.10 changed-`SKILL.md` set (0 of 5; control arm 3 of 3). They carry older values because v4.10 never touched them. Scope held at 12 |
| **DEV-7** | 5 | The in-flight sibling PR's `deploy.sh` delta | **CORRECTED** 180 → **163** additions |
| **DEV-8** | 5 | Caller count for the shared warn-emitter's hardcoded mode-path text | **CORRECTED** 59 → **62** distinct call-site identifiers |
| **DEV-9** | 5 | "material-edit's body carries a wrong path for `pmo-architect`" | **REFUTED.** All twelve correction-set paths exist exactly as written; `pmo-architect` appears only as a bare name in prose, never with a path |
| **DEV-10** | 6 | The reference-durability control refused the first rendering of this plan file: bare ticket references sat outside a designated reference block | **Rewritten to the standard's own remedy** — card-name prose in the body, every bare reference confined to the block below with a summary noun phrase. Meaning and effect unchanged; no reference was altered to dodge a matcher |

## Engineering Constraints (carried forward)

1. **One commit per issue** — the release rollback granularity, not a style preference. Commit 0 is the sole exception and carries no issue work.
2. **Card 4's commit MUST carry the skill-editor audit-trail trailer** — all 12 files carry the skill-discipline migration flag, so the corresponding deploy check is history-level and a deploy run will not repair it.
3. **Card 4 writes the version of the material edit (`v4.10`)**, never the in-flight version. `pmo-release-manager` stays out of the set.
4. **The Tier-S edge is safe as designed** — Card 3's `deploy.sh` edits are comment-lines only and the sibling card touches the mode-resolution call site; disjoint, clean merge either order, **provided the boundary block is not reflowed or renumbered**.
5. **Address deploy checks by number, never by line** — the in-flight sibling PR adds 163 lines above these ranges.
6. **Do NOT add a `CANARY_SKILLS` emptiness precondition** to the builder (R6) — it would break the version-claim tool's package self-test sandbox.
7. **Do NOT filter the builder's query rule (b)** — its input is curated map data, and silently dropping a curated-but-unresolvable entry is the same prohibited transformation in the other limb. A map entry naming a retired skill is a genuine inconsistency whose loud build failure is the correct signal.
8. **Rejected-candidate notices go to stderr only** — stdout is the machine contract for both live consumers.
9. **PR body parser-clean** — where prose describes per-issue closure, write `mark #N as closed at Stage 13`; never a close-family verb adjacent to a ticket reference, in any section.

## Issue References

Bare ticket references are confined to this block, each with a summary noun phrase, per the reference-durability standard.

Card 1 is issue #4755 — the package-rebuild detection-scope and per-skill build-failure attribution card, Severity Major, first in the approved sequence.

Card 2 is issue #4753 — the Check 49 mode-identifier unification across four sites, with the unbindable mode-path repair folded in.

Card 3 is issue #4750 — the citation-anchor predicate widening that ships no exemption surface.

Card 4 is issue #4752 — the material-edit determination resolved as Option C, both repairs in one commit.

The planning sub-task is issue #5294; the four Solutioning sub-tasks are issues #5299, #5300, #5301 and #5302 for Cards 3, 4, 2 and 1 respectively.

The Stage-6 Engineering sub-task for Card 1 is issue #5306.

The cross-milestone serialization partner is issue #4751, rehomed to the warn-mode-gate-graduation milestone, which edits the same Check 66 definition block Card 3 touches.

The in-flight sibling is pull request #5269 on the corpus-tolerance-and-hygiene branch, which inserts 163 lines into the deploy script above both edit ranges.

The delegated-detection antecedent is issue #4722 — the release that moved package-staleness detection into the builder's query mode and carried rule (a) across unfiltered, which is the defect Card 1 closes.

The dry-run-must-not-abort convention is issue #4765, and the complementary-pair registry the builder fails closed on is issue #4178.

The originating card for the close-out package-rebuild phase is issue #3322.
