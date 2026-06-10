---
version: memory-to-corpus-codification
date: 2026-06-09
type: plan
issues: ["#356", "#357"]
pr: null
links:
  note: null
  log_anchor: "#memory-to-corpus-codification"
reversibility-tier: CHEAP
themes: ["epic:knowledge-corpus", "cluster:process-protocol", "cluster:documentation"]
---

# memory-to-corpus-codification Release Plan

**Milestone:** `memory-to-corpus-codification`
**Release identifier:** Version-less, milestone-title-keyed (D-Identifier A, operator-rendered 2026-06-09). The deliverable repo diff is empty, so there is no platform increment for a version number to mark: no version tag at Stage 12, and the platform `.version` is unchanged. RELEASE_INDEX Version cell reads "memory-to-corpus-codification (version-less)". Precedent: the shipped version-less releases keyed to their milestone titles (public-flip-install-blockers, intake-elicitation-skill, domain-aware-stage5-design).
**Release Class:** `routine` (D-ReleaseClass A, operator-rendered 2026-06-09). Basis: all issues P3 + size:M (trigger a); verification-dominant zero-deliverable-diff scope; the by-letter `novel` trigger (D-decision count) is administrative-gate dispositions only, per the taxonomy anti-pattern discipline.
**Branch Topology:** `D-C SINGLE`, standard two-PR shape (D-Topology A) — one release branch `release/memory-to-corpus-codification`; release PR = this plan file only (Engineering Commit 0); post-merge Stage 13 chore PR = LOG/INDEX/DIGEST/NOTES/CHANGELOG rows. Preserves Stage 9 diff-review and merge-SHA-bearing corpus rows.
**Differentiation posture (per `routine`):** Engagement density Light; Stage 9 review depth Standard; Stage 5 activation bias SKIP-where-trivial; Stage 13 outcome-window 30-day.

**Stage 4 plan content of record:** the Stage 4 Release Planning comment on sub-task #578 (operator-reviewed at the Stage 4 Decision Briefing; plan approved 2026-06-09). This file transcribes that comment verbatim as Engineering Commit 0, followed by the Decision Log recording the rendered gate verdicts from the Decision Record comment on the same sub-task.

---

## Stage 4 Release Planning — memory-to-corpus-codification

### Phase A0 Triage→Design Re-Review + Currency Gates (G-PL1 / G-PL2)

Per `release/references/standards/triage-design-rereview.md` §1 (artifact at sub-task output head). Release entered Stage 4 on 2026-06-09 (post-2026-04-25 cutover → SUBJECT). All hub-orientation leads were independently re-verified against canonical sources; verification commands and results are cited inline.

**Header (#356):** issue #356 · milestone memory-to-corpus-codification · stage 4 · spoke: Stage 4 Release Planning spoke (Fable 5) · re-review 2026-06-09 · body revision 2026-06-08T23:55:52Z · triage decision 2026-05-13 (APPROVED, batch B2) · effort tier: standard (size:M, governance scope).

| Requirement (#356) | D1 best-practices | D2 platform-localized | D3 learnings | Cls | Delta |
|---|---|---|---|---|---|
| AC1: CLAUDE.md contains substantive rule per each of 5 patterns | decision-discipline.md §2.1.1 audit-snapshot reconciliation applied (issue filed 2026-05-11 ≫ 24h old) | **ALREADY-SATISFIED.** `grep -niE "(authorizes the whole plan\|authorization-scope enumeration\|skill-boundary transparency\|surgical edits\|runtime harness)" core/CLAUDE.md.template` → lines 202/203/204/205/236 — all 5 patterns present as named guardrails. Deployed instance `~/Claude/CLAUDE.md`: 1 grep match per pattern (5/5) | (release-ops, intake-pre-rendered-artifacts) observation 2026-05-23, sub-case (b) "capability already ships" — spec collapses to verify + evidence + closure | C2 | Path currency: AC's "CLAUDE.md" → tracked `core/CLAUDE.md.template` + deployed `~/Claude/CLAUDE.md` (`git ls-files \| grep -i CLAUDE` → single tracked file). Record satisfaction evidence; no edit |
| AC2: 5 memory files removed | verify-before-recommend (CLAUDE.md Universal Preferences) | **ALREADY-SATISFIED.** `ls ~/.claude/memory/ \| grep -E "(governance_theater\|name_skill_boundary\|batch_authorization\|surgical_edits\|harness_changes)"` → 0 matches | memory↔corpus boundary contract (#530 family): encode-and-evict already executed for these 5 | C2 | Path currency: issue's "(local path removed)" → `~/.claude/memory/` (operator instance) |
| AC3: MEMORY.md has no index entries for the 5 | same | **ALREADY-SATISFIED.** `grep -nE "(governance_theater\|name_skill_boundary\|batch_authorization\|surgical_edits\|harness_changes)" ~/.claude/memory/MEMORY.md` → exit 1 (0 matches) | same | C2 | Record evidence; no edit |
| AC4: CLAUDE.md growth ≤ 500 chars vs pre-PR state | review-discipline Rule 1 (concrete verification, not surface pass) | Premise assumes a PR edit exists; no edit is needed → growth = 0, trivially within bound | governance-theater rule (CLAUDE.md): do not stage a no-op edit to satisfy an AC's letter | C2 | AC moot-by-no-op; record as satisfied-by-zero-diff |
| Proposed Change: per-memory absorb-vs-new decision "deferred to Stage 5 Solutioning" | planning-solutioning-handoff.md §3 T3 auto-flag fires on this literal phrase; §5 anti-pattern says SKIP invalid while phrase stands | The deferred decision is already rendered in shipped corpus: each memory landed as a named guardrail (4 new named bullets + 1 extension of "No ungoverned changes"). Design question consumed | intake-pre-rendered-artifacts precedent: D-NO-RE-AUTHORING disposition, operator-approved 2026-05-23 | C2 | Tier 1 [ADJUST]: hub neutralizes the stale deferral sentence in #356 Notes via `gh issue edit --body` at gate execution, making the Stage 5 SKIP verdict rule-clean (see D-Disposition) |
| Risk: "[ASSUMPTION] all 5 collapse cleanly; batch-authorization template may not survive condensation" | evidence-quality protocol — assumption requires confirmation | Confirmed resolved: the "Authorization-scope enumeration" bullet carries the granularity guidance ("name the class and the count"), i.e. the template's substance survived condensation (template line 203) | — | C2 | Risk retired with positive evidence |

**Header (#357):** issue #357 · milestone memory-to-corpus-codification · stage 4 · spoke: same · re-review 2026-06-09 · body revision 2026-06-08T23:55:54Z · triage decision 2026-05-13 (APPROVED, batch B2) · effort tier: standard (size:M, governance scope).

| Requirement (#357) | D1 best-practices | D2 platform-localized | D3 learnings | Cls | Delta |
|---|---|---|---|---|---|
| AC1: §Post-merge primary sync states fast-forward-by-default | §2.1.1 reconciliation applied | **ALREADY-SATISFIED.** `core/rules/git-workflow.md:46` "**Fast-forward by default.**" + line 44 standing-invariant text ("MUST always sit at origin/main… regardless of who merged") | encoding present at current-history seed commit 64c9c7e (2026-06-05); only later touch is c865e7c (#521 PR-title convention, 2026-06-07) | C2 | Path currency: AC's `.claude/rules/git-workflow.md` → tracked `core/rules/git-workflow.md` (`git ls-files \| grep "^\.claude/"` → 0 tracked files) |
| AC2: §Primary Checkout Discipline — never restore uncommitted deletions without asking | same | **ALREADY-SATISFIED.** Line 34 "Never restore a user's uncommitted change without asking" + line 35 "Diagnose by content before any irreversible discard" | seed-commit provenance as AC1 | C2 | Same path currency |
| AC3: §PR Process — never "does not close #N"; use References for partial work | same | **ALREADY-SATISFIED.** Line 76 ("never omit-and-hope and never negate… `References #N`") + line 78 Negation trap + line 79 verb-noun leak + lines 80–84 pre-submit spot-check; now also CI-enforced (`pr-body-parser-clean.yml`, cited at line 124) | confirmed-permanent pattern feedback_pr_body_close_keyword (promoted 2026-05-12, N=2) — eviction per decision-discipline §4.6 "subsumed into governance → evict (promote to governance)" | C2 | Same path currency |
| AC4: §PR Process — self-review no-ops; reviewer field expected empty | same | **ALREADY-SATISFIED.** Line 71 "Single-collaborator deployment — reviewer field expected empty… GitHub silently no-ops a self-review request" | the 2026-05-16 enrichment comment on #357 confirmed the locus this AC remediates; encoded at seed | C2 | Same path currency |
| AC5: mirror byte-identical; deploy Check 9 passes | duplicate-source-discipline (register-or-remove) | Premise drifted: no tracked `.claude/rules/` exists. Live Check 9 semantics (deploy.sh lines 1577–1597): in-repo source `core/rules/git-workflow.md` ↔ deploy-managed workspace mirror `$DEPLOY_ROOT/.claude/rules/git-workflow.md` (DEPLOY_ROOT default `$HOME`), uni-directional. Mirror currently ABSENT at operator instance (`ls ~/.claude/rules/` → no such dir) → Check 9 logs SKIP (non-failing) | layout §8.3: engineering/rules mirror DROPPED; workspace `.claude/rules/` is the only mirror | C2 | AC reconciles to: single tracked source carries the rules; Check 9 non-failing. Mirror-absence flagged as out-of-scope deploy-state observation (Recommendations R-1) |
| AC6: 4 memory files removed | intermediate-artifact discipline (CLAUDE.md) | **PARTIAL → RESIDUAL-GAP.** `feedback_empty_pr_reviewer.md` gone; 3 survive: `ls ~/.claude/memory/ \| grep -E "(primary_auto_sync\|primary_working_tree\|pr_body_close_keyword)"` → 3 files | `temp_pointer_codification_in_flight.md` ledger row "#357" ties exactly these 3 and prescribes "Evict each memory (and its MEMORY.md line) when its issue ships" — the operator memory system already encodes this release's deploy step | C2 | RESIDUAL WORK (the release's only substantive change): delete 3 files + evict the ledger's #357 row, at Stage 12 operational deploy (see Delivery Strategy) |
| AC7: MEMORY.md index entries removed | same | **PARTIAL → RESIDUAL-GAP.** `grep -nE "(primary_auto_sync\|primary_working_tree\|pr_body_close_keyword)" ~/.claude/memory/MEMORY.md` → lines 57, 58, 67 live | same ledger row | C2 | RESIDUAL WORK: remove 3 index lines at Stage 12 operational deploy |
| Risk: tension — current "Default: tell user" text vs newer May-11 memory prescription | — | **RESOLVED in live corpus**: lines 46–53 adopt the newer prescription ("Fast-forward by default… do not default to telling the user to run it themselves; hedging is the error") | — | C2 | Risk retired with positive evidence |

**Content-richness diff (load-bearing-nuance check, all 3 surviving memories read end-to-end 2026-06-09):**
- `feedback_primary_auto_sync.md` vs §Post-merge primary sync: every prescription encoded — standing invariant incl. operator-merged PRs (line 44), `git -C` no-cd commands (48–49), don't gate on uncommitted state / don't delegate to user (53), 3 real-conflict stop conditions (55–58), report-briefly form (51), diagnose-by-content / redundant-duplicate / explicit-confirm-discard / never-frame-as-losing-work (35). Memory's residue is incident narrative + a scope note ("unattended external merges = hook territory"), not prescription. **No residual corpus gap.**
- `feedback_primary_working_tree.md` vs line 34: investigate context (`git status` + `git log --oneline -n N -- <path>`), ask when non-obvious, preserve-intent default — all encoded. **No residual corpus gap.**
- `feedback_pr_body_close_keyword.md` vs lines 72–84 + 122: one-place rule, all 9 verbs, lexical-parser rationale (negation + section context), both surface variants' prescriptions, identical spot-check regex (the `\[?` also covers the memory's `[#N](...)` link form), plus title-scan coverage (line 122) the memory lacks — corpus is a superset. **No residual corpus gap.**

**G-PL1 (AC/substrate currency):** FAIL-as-found → reconciled in this plan. Currency mismatches (stale paths `CLAUDE.md` / `.claude/rules/` / "(local path removed)"; AC5 mirror premise; consumed Stage-5 deferral) routed Tier 1 [ADJUST] — carried as input-corrections in this plan's Deviation/Input-Correction Register per the intake-elicitation-skill precedent, with one recommended body edit (#356 deferral sentence). No AC premise is invalidated in the Tier-2-SCOPE-CHANGE sense at the AC level; the release-level scope finding is rendered as D-Scope/D-Disposition below. **Zero C3 / no Tier 0 — Premise Rejection.** The issues' premises (this knowledge belongs in the corpus; memories then evict) are confirmed correct by live state; the work is largely already done, which is a disposition question for the operator gate, not a premise rejection.

**G-PL2 (Gate 1 substantive re-checks, current bodies):** G1-02 actionable: PASS ×2. G1-04 names files/protocols: PASS ×2. G1-05 AC verifiable: PASS ×2 (method-bearing ACs; runnable once the path mapping above is applied). Bodies are crisp enough to plan against.

**Parallelization Map currency:** Milestone description carries no `## Parallelization Map` section. Milestone created 2026-06-07T04:39:54Z (roadmap consolidation), i.e. after the v1.03 convention (2026-06-02) — map absence is a Phase A0 finding routed Tier 1 [ADJUST]: add the map in the same milestone-description PATCH the scope decision already requires (draft in D-Scope). Scan result for the map: 2 release issues, no cross-milestone hard edges; soft edges to #429 (third-item ownership) and dormant siblings #527/#530/#531 (same epic family; no file contention with this release — see Contention Map).

### Summary (30 seconds)

Verification-dominant release. Both issues' corpus encodings are **already complete on main** (verified per-AC above): all 5 #356 guardrails live in `core/CLAUDE.md.template` (+ deployed `~/Claude/CLAUDE.md`), all 4 #357 rules live in `core/rules/git-workflow.md`, and the content-richness diff found **no load-bearing nuance missing** from the corpus. #356 has zero residual work anywhere (its 5 memories + index lines already evicted). #357's residual is operator-instance-only: delete 3 memory files, remove 3 MEMORY.md index lines, evict the `temp_pointer_codification_in_flight.md` #357 ledger row — exactly what the operator memory system's own encode-and-evict protocol prescribes. Deliverable repo diff: **empty**; the release ships a committed plan + release-corpus rows only. Milestone description drift ("~12 pts across 3 issues"; third item = untriaged Observation #429) goes to the operator as D-Scope. Proposed: `routine` class, version-less identifier, SINGLE topology with the standard two-PR shape, Stage 5/7/8 SKIP, operational deploy at Stage 12 with archive-before-delete rollback, both issues marked closed at Stage 13 with the reconciled AC evidence.

### Dependency Graph

- **#356 ⊥ #357** — no directional dependency. No body cross-references between them; GitHub timeline shows no blocked-by relations (only cross-refs from #578 and from sibling codification issues #527/#530/#531 onto #357). Either could close first.
- External: #429 (Observation, no milestone) is referenced by the milestone description's third value item only — not a dependency of either issue. #530 (memory↔corpus boundary contract) is the standing protocol this release's eviction step executes; it is OPEN and unaffected (this release does not deliver #530's contract, it follows it).

### Implementation Sequence

Release-scoped single thread (no per-issue engineering exists):

1. **Gate execution (hub, post-approval):** PATCH milestone description (one edit: Outcome Statement H3 + amended Value/scope line + `## Release Class` H2 + `## Parallelization Map (recorded 2026-06-09)` H2 — drafts in D-Scope/D-ReleaseClass/Outcome below); `gh issue edit 356 --body` to neutralize the consumed Stage-5-deferral sentence (Tier 1 [ADJUST]).
2. **Commit 0 (Stage 6, single spoke):** create `release/memory-to-corpus-codification` branch; commit the approved plan as `release/releases/plans/memory-to-corpus-codification_RELEASE_PLAN.md`; open release PR (body uses `References #356` / `References #357` — both issues are marked closed at Stage 13, not by the PR; parser-clean per `core/rules/git-workflow.md` §PR Process step 5).
3. **Stage 9 Plan Review:** operator GO/NO-GO; re-run the 9 verification one-liners (listed in Verification Plan) as the review's empirical leg.
4. **Stage 12 Execute:** merge release PR; then **operational deploy on the operator instance** — (a) archive: paste full bodies of the 3 memory files + the 3 MEMORY.md lines + the ledger row into the Stage 12 evidence comment; (b) delete the 3 files via `trash` (not `rm`, per hook policy); (c) remove MEMORY.md lines 57/58/67; (d) remove the `#357` row from `temp_pointer_codification_in_flight.md`; (e) post post-state verification output.
5. **Stage 13 Close:** corpus chore PR (RELEASE_LOG + RELEASE_INDEX + RELEASE_DIGEST + RELEASE_NOTES + CHANGELOG); reconciled AC tables posted as closure evidence on #356/#357; both issues marked closed; milestone closed; QC4-06 goal-attainment vs the Outcome Statement.

### Stage Applicability Matrix

Stage 5 activation per `core/standards/planning-solutioning-handoff.md` §3–4 (all-or-nothing rollup):

| Issue | T1 new-file | T2 skill | T3 design-decision | T4 multi-approach | T5 ≥3 gov files | T6 blast-radius | Verdict |
|---|---|---|---|---|---|---|---|
| #356 | ✗ (zero deliverable files) | ✗ | ✗* — literal "deferred to Stage 5 Solutioning" present in body, but the deferred decision is already rendered in shipped corpus (template lines 202–205, 236); G-PL1 Tier 1 [ADJUST] body edit removes the stale phrase at gate execution | ✗ (absorb-vs-new resolved by live state) | ✗ (zero repo files) | ✗ (deterministic: nothing) | SKIP* |
| #357 | ✗ | ✗ | ✗ (no deferral; the body's flagged sync-text tension is resolved in live corpus, lines 46–53) | ✗ | ✗ (zero repo files; operator-instance files are not governance files) | ✗ (deterministic: 3 files + 3 lines + 1 ledger row) | SKIP |

**Release rollup: SKIP** — conditional on the #356 body adjustment (without it, T3 stands by-letter per the handoff standard's anti-pattern clause and the verdict flips to ACTIVATE with nothing to design; the operator's plan approval with this documented rationale is the override authority the standard grants). Stage 5 SKIP also matches the proposed `routine` class bias (SKIP-where-trivial: triggers met by letter only, no design uncertainty, no new deliverable files).

Stages 6–13 per issue:

| Stage | #356 | #357 | Rationale |
|---|---|---|---|
| 5 Solutioning | SKIP | SKIP | Above |
| 6 Engineering | SKIP (per-issue) — release-scoped Commit 0 only | SKIP (per-issue) — same | No deliverable diff; Commit 0 transcribes the plan (Procedure 0 D-C SINGLE) |
| 7 Dev Testing | SKIP | SKIP | No functional impact (skip rule met: zero behavior-bearing changes). Verification one-liners re-run at Stage 9 instead; `domain_practice` label presence is verifiable in the committed plan at Stage 9 review |
| 8 QA | SKIP | SKIP | Same basis |
| 9 Plan Review | APPLIES (release-scoped) | APPLIES | Operator gate; includes empirical re-run of the verification set |
| 10 Dry Run | Satisfied structurally | Satisfied structurally | PR diff IS the dry run (stage-10 shard) — applies to the plan/corpus PRs. The operational deploy's dry-run equivalent is the archive-before-delete preview in the Stage 12 evidence comment |
| 11 Snapshot | Satisfied structurally (git) + MANUAL extension | same | Git history snapshots the repo side; the operator-instance files are outside git → the Stage 12 archive step IS the snapshot (mandated, see Rollback) |
| 12 Execute | APPLIES (merge; no skill redeploy needed) | APPLIES (merge + operational deploy — the release's only substantive mutation) | Operational deploy authorization: Stage 9 GO per the approved plan (Tier 3 standing authorization; CLAUDE.md autonomy-tier model). Evidence posted to the Stage 12 sub-task |
| 13 Close | APPLIES — mark #356 as closed with reconciled AC evidence | APPLIES — mark #357 as closed with evidence incl. post-deploy verification | Corpus rows + notes; QC4-06 |

### Contention Map

- **Within-release repo contention: none.** File Change Matrix is disjoint release-ceremony artifacts touched by a single sequential actor (Commit 0 spoke, then Stage 13 chore spoke).
- **Within-release operator-instance contention: trivial.** `~/.claude/memory/MEMORY.md` receives all 3 line-removals in one edit by one actor at Stage 12. No parallel writers (Stage 5/7/8 skipped; one Engineering surface).
- **Cross-PR baseline (A4, baseline-pinned per the audit-baseline discipline + confirmed pattern `feedback_release_ops_audit_baseline_when_target_population_is_empty`):** open-PR population = **0** at baseline SHA `3f91d05` (2026-06-10T00:03Z) — transiently-empty population, so the baseline is pinned: SHA + last-6 merged-PR window (#576, #570, #543, #539, #528, #526; 2026-06-07→08). None touches a path in this release's matrix beyond the standard release-corpus append files (RELEASE_LOG/INDEX/DIGEST/CHANGELOG — `overlap_class: append-pattern`, structurally HIGH / operationally LOW per ADR-005). The two verified-content files are not in this release's change set at all (last touches: `core/rules/git-workflow.md` ← c865e7c #521 2026-06-07; `core/CLAUDE.md.template` ← seed 64c9c7e 2026-06-05). Re-check at Stage 6 Commit-0 entry; Stage 9 Phase A6.5 divergence checkpoint also fires.
- **Dormant-sibling scan (per the 2026-05-11 cross-release-contention-includes-dormant-siblings observation):** sibling codification issues #527/#530/#531 (no milestones, `status: proposed`-family) will later touch the same operational surfaces (MEMORY.md, the codification ledger) and possibly the same corpus files. No conflict with this release: it only REMOVES the three #357-tied entries; the siblings' rows/memories are untouched. Informational only.

### Risk Register

| # | Risk | Sev | Mitigation / Owner |
|---|---|---|---|
| R1 | Operator-instance deletion is outside git — without archival it is effectively irreversible | MED | MANDATED archive-before-delete: full file bodies + index lines + ledger row pasted into the Stage 12 evidence comment before any deletion; deletion via `trash`. Post-archival reversibility: CHEAP. Owner: Stage 12 spoke/hub |
| R2 | Auto-close parser leak — a close-family verb + #N anywhere in PR bodies would close issues before Stage 13 evidence lands | MED | Parser-clean discipline (corpus lines 76–84): `References #356` / `References #357` only; pre-submit spot-check grep run on every PR body draft; this plan already uses safe phrasing throughout. Owner: Commit 0 + Stage 13 spokes |
| R3 | Stage-5 SKIP invalidity by-letter (#356's stale deferral phrase) | LOW | Tier 1 [ADJUST] body edit at gate execution; operator plan-approval carries the documented override either way. Owner: hub |
| R4 | Version-less tooling edge — Stage 12/13 tooling paths that assume `vX.Y` | LOW | 3 shipped version-less precedents (public-flip-install-blockers, intake-elicitation-skill, domain-aware-stage5-design) exercised the path end-to-end; intake precedent records "no version tag; `.version` stays" semantics. Owner: Stage 12/13 spokes |
| R5 | Scope expansion via #429 (if D-Scope option B chosen) | MED (only under B) | #429 is an untriaged Observation (`status: proposed`, observation-template body, no milestone) — bundling it would reproduce the 2026-05-10 legacy-issue-bypassed-triage anti-pattern and G3-02 would not be satisfiable. Recommendation is A (keep 2). Owner: operator at D-Scope |
| R6 | MEMORY.md concurrent-writer collision at Stage 12 (memory consolidation or another session editing simultaneously) | LOW | Single-session sequential edit; re-read file immediately before edit; post-edit verification grep. Owner: Stage 12 |
| R7 | Mirror-absence confusion — AC5 readers may misread Check 9 SKIP as FAIL | LOW | Reconciled AC5 reading recorded here + closure evidence; out-of-scope observation R-1 routes the deploy-state question to intake. Owner: hub |
| R8 | Commit-signing preflight — commit-producing spokes block on an empty ssh-agent | LOW | Hub runs `ssh-add -l` before spawning Commit 0 and Stage 13 chore spokes (2026-05-22 observation, operator-confirmed N=5). Owner: hub |

**Rollback strategy.** Repo side: `git revert` of the plan/corpus commits (CHEAP; git history is the Stage 11 snapshot). Operator-instance side: restore the 3 files / 3 index lines / ledger row from the Stage 12 archive comment (CHEAP once archived — the archive step is mandatory, not optional). Milestone description: the pre-PATCH description is quoted in D-Scope below; rollback = re-PATCH.

**Capacity assessment.** Nominal scope "~12 pts across 3 issues" vs actual residual: one milestone PATCH, one optional body edit, ~6 operator-instance file operations, two small PRs, verification evidence. Far under capacity for a single-operator release; the points figure is stale (sizing predates the discovery that the corpus work already shipped). The description amendment reconciles it.

### Recommendations

1. **Adopt the verification-only delivery shape** (D-Disposition A): no re-authoring, no invented stage work; evidence + closure routing — the same disposition the operator approved for the identical shape on 2026-05-23 (intake-pre-rendered-artifacts observation, sub-case (b) "capability already ships").
2. **Keep scope at 2 issues; amend the milestone description** (D-Scope A); leave #429 as the owner of the migration-playbook scope through its own Triage (duplicate-discipline: enrich the existing owner, never restate).
3. **Out-of-scope discovery R-1 (route to intake):** the deploy-managed rules mirror `$DEPLOY_ROOT/.claude/rules/` (Check 9's right-hand side, deploy.sh lines 1577–1597) is absent at this operator instance — no deploy step appears to lay it down (no `core/rules → .claude/rules` copy step found in deploy.sh; Check 9 SKIPs all 8 pairs here). Worth an observation/improvement intake: either a deploy step should create the mirror or Check 9's pair set should match the real deployment surface. Not a blocker for this release (tracked corpus is canonical and verified).
4. **Out-of-scope discovery R-2 (note only):** issue bodies carry depersonalization-scrubbed "(local path removed)" placeholders where operator-instance paths once stood; closure evidence comments should carry the reconciled, runnable AC table (as drafted here) so the closed issues remain self-explanatory.
5. **Pattern-cache note for the operator (Mechanism 3):** this release is a candidate **second instance** of (release-ops, intake-pre-rendered-artifacts) — the 2026-05-23 entry's class signal explicitly names sub-case (b) "register existing capability tickets where the capability already ships". Operator confirmation at this gate would satisfy N=2 emergence (within 180 days) and promote the pattern per decision-discipline §4.2/§4.5. Spoke does not self-cache; flagging only.
6. **Instrumentation rows (hub to append** — operator-instance instrumentation file not found locally; first-row creation may be needed): Phase A0 rows: `memory-to-corpus-codification · #356 · stage 4 · 2026-06-09 · standard · 6 reqs · c1=0 c2=6 c3=0 · deltas carried-as-input-corrections (+1 recommended body edit) · PT none` and `… · #357 · … · 8 reqs · c1=0 c2=8 c3=0 · deltas carried-as-input-corrections · PT none`. Pipeline-event-log: one `scope-change`/`tier-2-scope-change` row (D-Scope surfacing) + `decision`/`d-class` rows per D rendered at the gate.

**Deviation/Input-Correction Register (G-PL1 Tier 1 [ADJUST] set, carried to closure evidence):** (1) `CLAUDE.md` → `core/CLAUDE.md.template` + deployed `~/Claude/CLAUDE.md`; (2) `.claude/rules/git-workflow.md` → `core/rules/git-workflow.md` (single tracked source; Check 9 mirror deploy-managed, currently absent → SKIP); (3) "(local path removed)" memory paths → `~/.claude/memory/`; (4) #356 Notes' Stage-5 deferral sentence → consumed by shipped encoding (recommended body edit); (5) #357 ledger-row eviction added to the operational manifest (discovered from the live memory-system protocol, `temp_pointer_codification_in_flight.md`).

**Localization Check (M1) + Opposing View (M2), release-shape recommendation.** *Platform context:* the shipped corpus state (verified above), the intake-pre-rendered-artifacts disposition precedent (operator-approved 2026-05-23), the encode-and-evict ledger row for #357, and the 2026-05-13 stage-4-relitigates-prior-bundling correction ("Stage 4 inherits the bundle as input"). *Generic heuristic I would otherwise apply:* "every release issue gets engineering + testing stages" / "close stale issues at triage, not through a release". *Reconciliation:* localized context overrides both — the bundle stands (2 issues, as assigned), the stages collapse to verification + operational deploy, and closure routes through Stage 13 with evidence. *Opposing view (strongest case I'm wrong):* the corpus text might be missing a load-bearing nuance from the 3 surviving memories, making a corpus edit the real residual and Stage 6/7 applicable. *Evidence that would confirm it:* a prescription present in a memory file but absent from `core/rules/git-workflow.md`. *Resolution:* checked line-by-line (content-richness diff above) — every prescription is encoded; the corpus is a superset on one of the three (title-scan rule). Opposing view dismissed with cited evidence; remaining uncertainty (whether the operator values the incident narratives enough to retain them anywhere) is folded into the archive-before-delete step, which preserves them in the release record regardless.

### Operator Decisions

#### D-Scope: Milestone description claims "~12 pts across 3 issues"; only 2 issues are assigned — amend or expand?
**Gate input:** Milestone 124 description (fetched 2026-06-09: third value item "repo's proven migration patterns… playbook set" maps to #429; `open_issues=3` = 2 release issues + sub-task #578). #429 verified: OPEN Observation, `status: proposed`, observation-template body, **no milestone, not Triage-approved**; carries roadmap dep "Blocks #304".
**Gate decision:** (A) Keep scope at 2 issues (#356, #357) + PATCH the description — amended Value (drop the third item; pointer to #429 as its owner), corrected sizing line (`~8 pts across 2 issues` [INFERRED from M≈4-pt arithmetic — confirm]), + add Outcome Statement H3, Release Class H2, Parallelization Map H2 in the same PATCH. (B) Promote #429 into this release — requires Triage first (it is an untriaged Observation; bundling now reproduces the legacy-issue-bypassed-triage anti-pattern and breaks G3-02) and expands a verification-dominant release with L-shaped authoring work. (C) Other (e.g., defer the PATCH).
**Blocks:** Procedure 1 scaffolding; the milestone PATCH; Stage 5 SKIP cleanliness (via the #356 body edit bundled into gate execution).
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP (description re-editable; pre-PATCH text preserved below) / HIGH.
**Recommendation:** **A.** Reconcile-don't-annotate: fix the description to current reality; #429 remains the playbook scope's owner through its own Triage. Pre-PATCH description preserved for rollback: *"**Durable operator knowledge codified into the tracked corpus** / **Value:** Five cross-cutting behavioral guardrails load from CLAUDE.md at every session start, four git-workflow feedback memories live in .claude/rules/git-workflow.md (and mirror) with the redundant memory files deleted, and the repo's proven migration patterns are captured as a referenceable playbook set. / **Today:** Load-bearing guardrails, git-workflow rules, and migration patterns live only as operator memory/notes… / **Initiative:** Knowledge Corpus · **Release:** R01 (Now horizon) · **~12 pts across 3 issues**"*

#### D-Disposition: How do already-satisfied issues deliver?
**Gate input:** Per-AC reconciliation above — #356 fully satisfied (corpus + memory cleanup both done); #357 satisfied on the corpus side with a 3-file + 3-line + 1-ledger-row operator-instance residual; content-richness diff found no missing nuance.
**Gate decision:** (A) Verification-only release: no per-issue engineering; Tier 1 [ADJUST] input-corrections carried in-plan (+ the one #356 body edit); operational deploy at Stage 12; both issues marked closed at Stage 13 with reconciled AC evidence. (B) Return either issue to Triage (Tier-0-style) — no premise defect exists to reject; pure ceremony. (C) Author corpus enrichments from the surviving memories — verification found nothing load-bearing to add.
**Blocks:** Stage applicability matrix execution; Commit 0 content; Stage 12 manifest.
**Upstream compatibility:** N/A — no skill-authoring surface touched. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP (evidence-and-closure routing; nothing destructive until Stage 12, which carries its own archive step) / HIGH.
**Recommendation:** **A** (precedent: operator-approved D-NO-RE-AUTHORING disposition, 2026-05-23).

#### D-Identifier: Version-less (milestone-title-keyed) or next versioned (v1.09)?
**Gate input:** RELEASE_INDEX precedent read in full. Versioned rows (v1.01–v1.08, v3.18–v3.20) are platform-mainline increments — pipeline-discipline waves, capability spines, reliability hardening — each shipping a substantive deliverable diff, a signed `vX.Y` tag (live tags: v1.05–v1.08, v3.20), and version-train bookkeeping. Version-less rows (`public-flip-install-blockers`, `intake-elicitation-skill`, `domain-aware-stage5-design`) are self-contained bundles keyed to their milestone title, shipping **no version tag and no `.version` bump** (intake plan, verbatim: "Version-less: no version tag; the platform `.version` stays v3.19"). Operating rule inferred: a version identifier marks an installable platform increment on the version train; bundles whose identity is their milestone ship version-less. This release's deliverable diff is empty (verification + operator-instance hygiene + release ceremony) — there is no platform increment for a version number to mark, and nothing meaningful for a `v1.09` tag to point at.
**Gate decision:** (A) Version-less `memory-to-corpus-codification` — plan file `release/releases/plans/memory-to-corpus-codification_RELEASE_PLAN.md`, INDEX Version cell "memory-to-corpus-codification (version-less)", no tag, `.version` unchanged. (B) `v1.09` — versioned train slot, signed tag at Stage 12, version-prefixed artifacts.
**Blocks:** branch name, plan filename, INDEX/LOG/NOTES keys, Stage 12 tag step.
**Upstream compatibility:** N/A — release identifier naming is platform-internal; no skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP pre-Stage-13 (rename surfaces before corpus rows land) → MODERATE after / **MEDIUM** confidence — counter-precedent exists: v1.07/v1.08 were initiative releases (like this one: "Initiative: Knowledge Corpus · Release: R01") and took versions; but both shipped substantive diffs, which this release lacks.
**Recommendation:** **A (version-less).**

#### D-Topology: Branch/PR shape for a zero-deliverable-diff release
**Gate input:** Procedure 0 canonical-location (D-C SINGLE default: plan = Engineering Commit 0 on the release branch); Stage 13 release-corpus completeness gate (v3.19) makes the corpus rows mandatory; RELEASE_LOG convention records the merge SHA, which forces corpus rows to land **after** the release PR merges (a single combined PR cannot record its own merge SHA).
**Gate decision:** (A) Standard SINGLE two-PR shape: release branch `release/memory-to-corpus-codification`; release PR = plan file only (Commit 0); post-merge Stage 13 chore PR = LOG/INDEX/DIGEST/NOTES/CHANGELOG (matches v1.07 #526+#543 and v1.08 #570+#576 cadence). (B) Single close-time chore PR carrying plan + corpus, no release PR — leaner, but Stage 9 then reviews the plan only as a sub-task comment, the INDEX "Release PR" cell points at a chore PR, and the LOG's merge-SHA convention still degrades. (C) No PRs at all — rejected: violates the plan-commit mandate (Procedure 0 / stage-04 §6) and the Stage 13 corpus-completeness gate; not presented as a live option.
**Blocks:** Commit 0 chip; Stage 12/13 chips.
**Upstream compatibility:** N/A — branch topology / merge sequence; no skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **A.** Two small PRs preserve every convention (diff-reviewed plan at Stage 9; SHA-bearing corpus rows; the PR diff serving as Stage 10 dry-run).

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke-proposed class + trigger-condition evidence per release/references/specs/release-class-taxonomy.md. Trigger evidence: `routine` (a) fires — all issues P3 + size:M. `routine` (c)/(d) by-letter complications: the release adds plan/notes files (release-ceremony artifacts, not deliverables) and this plan carries D-decisions — `novel` trigger (b) "≥1 D-class decision" therefore fires **by letter**; honest reading per the taxonomy's own anti-pattern discipline: every D here is a recurring/administrative gate disposition (scope-commit, identifier, topology, class, delivery shape) — no new protocol, schema, skill, reference doc, or ADR; no design uncertainty for Stage 5 to resolve. Aggregate shape is verification-dominant closure work. `cross-cutting`/`hotfix`: no triggers fire.
**Gate decision:** Choose between (A) routine, (B) novel, (C) cross-cutting, (D) hotfix.
**Blocks:** Milestone-description Release Class H2 (PATCHed at gate execution); downstream differentiation posture.
**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable later per the Re-Classification Protocol; cheaper-to-stricter is CHEAP).
**Recommendation:** **A (`routine`)** with differentiation posture — Engagement density: **Light**; Stage 9 review depth: **Standard**; Stage 5 activation bias: **SKIP-where-trivial** (exercised above); Stage 13 outcome-window: **30-day**. Milestone H2 draft: `Class: routine / Rationale: all issues P3+size:M (trigger a); verification-dominant zero-deliverable-diff scope; the by-letter novel trigger (D-decision count) is administrative-gate dispositions only, per the taxonomy anti-pattern discipline. / Differentiation posture: Light / Standard / SKIP-where-trivial / 30-day.`

**Domain-practice provenance (A1.5 / A3, embedded per stage-04 §5.7):** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-06-09, domain: governance }` — File Change Matrix below contains only internal release-plan/release-corpus governance artifacts (zero application/source paths); classification evidence is the matrix itself. Sourcing-exempt, domain-classified.

### Release Outcome Statement (draft)

Per release/references/specs/release-outcome-statement-template.md (routine shape, adjusted for D-Scope A); hub PATCHes into the milestone description top-of-block after Phase B1 acceptance:

> ### Release Outcome Statement
>
> **AFTER** — All nine targeted patterns (5 CLAUDE.md guardrails + 4 git-workflow rules) are verified present in the tracked corpus (`core/CLAUDE.md.template`, `core/rules/git-workflow.md`), and the operator memory store carries none of the nine superseded feedback memories, their MEMORY.md index lines, or the codification-ledger row — the corpus is the single source of truth, with the verification record committed in the release plan.
>
> **BEFORE** — The corpus encodings shipped in prior-lineage releases, but three #357-tied memory files (plus 3 index lines and a ledger row) still duplicate git-workflow rules in the operator memory store, and the milestone description claims a third issue's scope that no assigned issue carries.
>
> **Actor(s):** Stage 4/9 verification (hub + operator); hub at Stage 12 operational deploy (operator-instance eviction).
>
> **Success Indicator:** At Stage 13, `ls ~/.claude/memory/ | grep -E "(primary_auto_sync|primary_working_tree|pr_body_close_keyword)"` returns empty AND each of the nine pattern greps against the tracked corpus returns ≥1 match — both outputs pasted in the Stage 12/13 evidence comments.

### File Change Matrix

Deliverable diff: **EMPTY** — no platform source/content file changes. Release-ceremony artifacts only (machine-readable, one path per line):

```
release/releases/plans/memory-to-corpus-codification_RELEASE_PLAN.md
release/releases/RELEASE_LOG.md
release/releases/RELEASE_INDEX.md
release/releases/RELEASE_DIGEST.md
release/releases/notes/memory-to-corpus-codification_RELEASE_NOTES.md
CHANGELOG.md
```

Operator-instance change set (outside git; Stage 12 operational deploy; not extractable by Stage 7/8/9 path tooling by design):

```
~/.claude/memory/feedback_primary_auto_sync.md          (delete, after archival)
~/.claude/memory/feedback_primary_working_tree.md       (delete, after archival)
~/.claude/memory/feedback_pr_body_close_keyword.md      (delete, after archival)
~/.claude/memory/MEMORY.md                              (edit: remove 3 index lines)
~/.claude/memory/temp_pointer_codification_in_flight.md (edit: remove the #357 ledger row)
```

### Verification Plan

Stage 9 (operator/hub re-run) + Stage 12 post-deploy + Stage 13 QC4-06 use this command set — #356: the 5-pattern grep against `core/CLAUDE.md.template` (expect 5 hits at lines 202–205, 236) and against `~/Claude/CLAUDE.md` (expect 1 per pattern); the 5-file ls-grep against `~/.claude/memory/` (expect empty); the 5-entry MEMORY.md grep (expect exit 1). #357: greps for "Fast-forward by default" / "Never restore a user's uncommitted change" / "Negation trap" / "reviewer field expected empty" in `core/rules/git-workflow.md` (expect 1 each); post-deploy: the 3-file ls-grep (expect empty), the 3-entry MEMORY.md grep (expect exit 1), `grep -c "#357" ~/.claude/memory/temp_pointer_codification_in_flight.md` (expect 0). Closure comments on both issues carry the reconciled AC tables + outputs.

### Model Provenance

- **Invocation model parameter:** `fable` (passed explicitly by hub)
- **Agent-definition default:** N/A — no `.claude/agents/` definitions exist in this deployment (hub launched via general-purpose subagent type with persona card embedded; F1-adjacent fallback)
- **Parent-session model:** runtime reports `claude-fable-5[1m]` (Fable 5, 1M context)
- **Designated-model match:** consistent with the workspace preference (highest-tier model, largest context, deliberately not version-pinned) as verifiable from this session; no contradicting signal observed.

---
*Stage 4 spoke complete. Gate: operator decision at Stage 4 (Procedure 0 Step 7) — D-Scope, D-Disposition, D-Identifier, D-Topology, D-ReleaseClass. Scaffolding (Procedure 1) must not start before the gate renders.*


## Decision Log — Stage 4 Release Planning Gate (Phase B1)

Transcribed from the Decision Record comment on sub-task #578 (rendered 2026-06-09). All five D-gates rendered option A; the pattern-promotion was confirmed; the plan was approved with GO to scaffolding.

**Rendered:** 2026-06-09, main-thread chat (structured Decision Briefing + AskUserQuestion), operator: workspace owner
**Plan:** the Stage 4 plan transcribed above (comment of record on sub-task #578)
**Hub empirical verification:** all load-bearing spoke claims verified pre-briefing (template lines 202–205/236; git-workflow.md rule sections; memory-store state; #429 untriaged/milestone-less; open-PR population 0 @ baseline `3f91d05`; last-touch commits `c865e7c`/`64c9c7e`; runtime rules mirror absent; version-less precedent quote; observation-log entry line 148; live tags v1.05–v1.08, v3.20)

### Decisions

| Gate | Decision | Rationale (compact) |
|---|---|---|
| **D-Disposition** | **A — verification-only release** | Corpus encodings verified complete incl. content-richness diff; no re-authoring; evidence + closure routing; operational deploy at Stage 12. Precedent: D-NO-RE-AUTHORING 2026-05-23. CHEAP/HIGH |
| **D-Scope** | **A — keep 2 issues, amend milestone description** | Third value item belongs to #429 (untriaged Observation — bundling would bypass Triage, G3-02 unsatisfiable). Description PATCH bundles Outcome Statement + Release Class + Parallelization Map. Pre-PATCH text preserved in the plan for rollback. CHEAP/HIGH |
| **D-Identifier** | **A — version-less, milestone-title-keyed** | Zero deliverable diff → no platform increment for a version to mark. Precedent: public-flip-install-blockers, intake-elicitation-skill, domain-aware-stage5-design ("no version tag; `.version` stays"). No tag at Stage 12. CHEAP→MODERATE/MEDIUM |
| **D-Topology** | **A — D-C SINGLE, standard two-PR shape** | Release branch `release/memory-to-corpus-codification`; release PR = plan file (Commit 0); post-merge Stage 13 chore PR = LOG/INDEX/DIGEST/NOTES/CHANGELOG. Preserves Stage 9 diff-review + merge-SHA-bearing corpus rows. CHEAP/HIGH |
| **D-ReleaseClass** | **A — `routine`** | Trigger (a): all issues P3+size:M; verification-dominant. By-letter `novel` trigger (D-count) = administrative-gate dispositions only. Posture: Light engagement / Standard Stage 9 / SKIP-where-trivial Stage 5 / 30-day outcome window. CHEAP/HIGH |
| **Pattern-cache** | **Confirm — promote** | This release confirmed as second instance of (release-ops, intake-pre-rendered-artifacts), sub-case (b). N=2 within 180 days satisfied → promote to permanent feedback pattern per decision-discipline §4.2/§4.5 |
| **Plan approval** | **APPROVED — GO to scaffolding** | Release Outcome Statement (draft) accepted. Stage applicability matrix accepted (Stage 5/7/8 SKIP; release rollup SKIP conditional on the #356 body adjustment, executed below) |

### Authorized gate-execution actions (enumerated at approval)

1. ONE milestone-description PATCH — amended Value/sizing + Outcome Statement H3 + Release Class H2 + Parallelization Map H2
2. ONE #356 body edit neutralizing the consumed Stage-5-deferral phrasing (Tier 1 [ADJUST] per G-PL1; covers both occurrences of the same consumed deferral — Proposed Change + Notes)
3. Procedure 1 scaffolding (~12 sub-tasks: 8 per-issue skip-closed Stages 5/6/7/8 + 4 active release-scoped: Stage 6 Commit-0, Stage 9 gate, Stage 12, Stage 13), presented for review after creation
4. Hub-state runtime instantiation for this release

**Explicitly NOT covered:** repo content edits (Commit 0 routes as its own chip post-scaffolding), Stage 12 operational deploy (gated at Stage 9 GO → Stage 12), #429 in any form, R-1 intake filing (surfaced at close).

### Outstanding items

- R-1 (rules-mirror deploy gap) — out-of-scope discovery, intake filing surfaced at release close
- Instrumentation first-rows — written to the hub-state instance at gate execution

## Change Description

### Outcome

This release closes out the memory-to-corpus codification scope by verification rather than authoring: all nine targeted patterns (the 5 CLAUDE.md behavioral guardrails and the 4 git-workflow rules) are confirmed already present in the tracked corpus (`core/CLAUDE.md.template` lines 202–205/236; `core/rules/git-workflow.md` §Post-merge primary sync, §Primary Checkout Discipline, §PR Process), with the per-AC verification record committed in this plan. The release's only substantive mutation is operator-instance hygiene at Stage 12 — deleting the three superseded #357-tied memory files, their three MEMORY.md index lines, and the codification-ledger row — after which the corpus is the single source of truth. Zero platform source/content files change; this PR ships the committed plan only.

### Issues resolved

| # | One-line outcome | Status |
|---|---|---|
| #356 | All 5 promoted guardrails verified present in the tracked template + deployed instance; the 5 superseded memories and their index lines were already evicted — zero residual anywhere. Marked closed at Stage 13 with the reconciled AC evidence. | DONE (verification-only) |
| #357 | All 4 git-workflow rules verified present with no load-bearing nuance missing (content-richness diff in this plan); operator-instance residual (3 memory files + 3 MEMORY.md index lines + 1 ledger row) is evicted at the Stage 12 operational deploy. Marked closed at Stage 13 with evidence including post-deploy verification. | PARTIAL (operator-instance eviction lands at Stage 12) |

### Key decisions

- **D-Disposition A — verification-only release:** no re-authoring, no invented stage work; evidence + closure routing. Precedent: the operator-approved D-NO-RE-AUTHORING disposition (2026-05-23).
- **D-Scope A — keep 2 issues, amend the milestone description:** the third value item belongs to #429 through its own Triage; the description PATCH (executed at gate) carries the corrected sizing, Outcome Statement, Release Class, and Parallelization Map.
- **D-Identifier A — version-less, milestone-title-keyed:** zero deliverable diff means no platform increment to mark; no tag, `.version` unchanged.
- **D-Topology A — D-C SINGLE, two-PR shape:** this release PR ships the plan; the post-merge Stage 13 chore PR ships the corpus rows, preserving the merge-SHA convention.
- **D-ReleaseClass A — `routine`:** trigger (a) fires; the by-letter `novel` trigger is administrative-gate dispositions only.
- **Pattern-cache — confirmed and promoted:** second instance of (release-ops, intake-pre-rendered-artifacts), sub-case (b); N=2 emergence satisfied.

Full verdicts with rationale: see the Decision Log section above.

### Reversibility

CHEAP / HIGH — the repo side reverses via `git revert` of the plan/corpus commits, and the Stage 12 operator-instance eviction is CHEAP once the mandated archive-before-delete step has pasted the full memory-file bodies, index lines, and ledger row into the Stage 12 evidence comment (restore = re-create from the archive).

### Downstream impact

- The operator memory store drops to zero duplication against the git-workflow rules corpus; the encode-and-evict ledger's #357 row retires at Stage 12.
- The promoted (release-ops, intake-pre-rendered-artifacts) pattern gives future already-satisfied issues a confirmed verification-only delivery route.
- #429 remains the owner of the migration-playbook scope through its own Triage; out-of-scope discovery R-1 (rules-mirror deploy gap) routes to intake at release close.
- Dormant sibling codification issues (#527/#530/#531) later touch the same operational surfaces with no contention — this release only removes the three #357-tied entries.

### Cross-references

- Release plan: this file (`release/releases/plans/memory-to-corpus-codification_RELEASE_PLAN.md`), top.
- Milestone: `memory-to-corpus-codification` (GitHub Milestone, number recorded in the Issue References block below).
- User-facing release note: lands at `release/releases/notes/memory-to-corpus-codification_RELEASE_NOTES.md` at Stage 13.
- Plan + Decision Record comments of record: sub-task #578 (see Issue References).

---

### Issue References

References #356 and #357 — the two milestone work items; both stay open through the release and are marked closed at Stage 13 with the reconciled AC evidence. References #578 — the Stage 4 Release Planning sub-task whose plan comment and Decision Record comment this file transcribes. References #429 — the untriaged Observation that owns the migration-playbook scope named by the milestone description's former third value item (out of this release). References #527, #530, #531 — dormant sibling codification issues in the same epic family (informational; no file contention with this release). Milestone: memory-to-corpus-codification (#124).
