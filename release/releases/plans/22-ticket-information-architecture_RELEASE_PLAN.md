Bump-class: minor · Provisional-display: v2.25 · Concrete version atomic-claimed at Stage 12 · Branch: release/22-ticket-information-architecture (theme-named)

---

## Stage 4 Release Planning — 22-ticket-information-architecture

### Summary (30 seconds)

Milestone **#199** (`22-ticket-information-architecture`) holds **5 issues** + this Stage-4 sub-task (#2018). Recommended posture: **BUILD a 3-issue slice (#211, #436, #545)**, **DEFER #1090** (a deferred non-atomic container with 0 sub-issues — it must be sliced into phase children under epic #409 before any consumer refit lands here), and treat **#229 as CLOSED-RECORD only** (a validation spike already closed; no gap-review needed — the sub-issue capability it validated ships and is in active use today).

The three BUILD issues are **dependency-independent of each other** (no edge among #211 / #436 / #545) but **#545 and #1090 contend** on `release/references/how-to/intake-style-guide.md` and `operations/skills/intake-desk/SKILL.md` — that contention is the load-bearing reason to keep #1090 out of this release rather than sequence it in. All inter-issue blockers cited in bodies resolve (no 404s); the only stale-anchor is in **#211** whose blocker chain (#164/#178/#222) is now mostly CLOSED — only **#222 remains open**, and it does NOT block #211's options-analysis work.

Three governance corrections surface (none block the build): (1) the **milestone description is stale** — it lists "Cards (4): #32 #211 #436 #545" but #32 is CLOSED in a different milestone (`86-hybrid-comanagement-decouple`) and #1090/#229 are unlisted members; (2) the milestone carries **no `## Release Class` and no `## Parallelization Map`** section; (3) **`.version` (v2.19) lags the live tag (v2.22) by 3 releases** — real drift.

**Release Class: `cross-cutting`** (3 BUILD issues touch ≥3 governance surfaces — CLAUDE.md, gate-criteria-spec.md, deploy.sh, plus skill SKILL.md). **Version: bump-class `minor`; provisional-display `v2.23`** — but a genuine **anchor-lineage ambiguity needs an operator call** (v3.20 is reachable from `origin/main`, so the literal `anchor()` rule could pick v3.21; practice has treated v3.20 as an anomaly). **Branch topology: single-branch** (`release/v2.23-ticket-information-architecture`).

---

### Dependency Graph

Directional edges across the in-scope issues and their cited externals. Edge legend: `A → B` = "A blocks B" / "B depends on A". All external references re-verified for existence at Stage 4 (staleness test = existence, not digit-match per the renumber-rot guard).

```
IN-SCOPE (this milestone)
  #211  Align Status field values with pipeline phase granularity   [BUILD]
  #436  Unify staleness-confidence representation                   [BUILD]
  #545  Make work-item titles human-informative                     [BUILD]
  #1090 Methodology plug-and-play (per-methodology kinds + refit)   [DEFER — container]
  #229  Validate sub-issue creation via GitHub API   [CLOSED — record only]

INTER-ISSUE EDGES (within milestone)
  (none among #211, #436, #545 — mutually independent)
  #545  ──file-contention──  #1090   (SOFT edge: shared files, not a dep; see Contention Map)

EXTERNAL EDGES (cited in bodies; verified live)
  #211:
    #164 (CLOSED) ──blocks──▶ #211      ← satisfied (closed)
    #178 (CLOSED) ──blocks──▶ #211      ← satisfied (closed)
    #222 (OPEN)   ──blocks?─▶ #211      ← SOFT: #222 = "Dev Testing mode for QA Auditor";
                                          does NOT gate #211's options-analysis/ADR work
    #211 ──blocks──▶ #181 (CLOSED)      ← downstream already closed; no live gate
  #436:
    #161 (CLOSED) ──blocks?─▶ #436      ← conditional ("IF Check 2 designated canonical");
                                          #161 closed, so health-check Check 2 model is available
                                          to generalize from — no live blocker
    #436 ──relates(boundary)── #413      ← response-posture, explicitly OUT of scope (CODIFIED)
    #436 ──relates── #47 (OPEN)          ← substrate-drift reconciliation; non-blocking
  #545:
    #545 ──interacts── #344 (CLOSED)     ← Category-field-as-work-domain; #344 already shipped,
                                          so the "sequence so both don't collide on improvement.yml"
                                          concern is RESOLVED (no live collision)
  #1090 (deferred):
    #507 (CLOSED) ──builds-on──▶ #1090
    #532 (CLOSED) ──builds-on──▶ #1090
    #409 (CLOSED, epic/parent) ──parent──▶ #1090   ← parent epic CLOSED; activates deferred C3/C5
    #1067 (OPEN)  ──composes── #1090     ← intake-template-by-type fork; #1090 absorbs/supersedes
  #229 (closed):
    relates #149 / #61 / #16 (all historical Stage-6 / sub-task-protocol refs) — record-only
```

**Verification table (every cited external — existence test):**

| Ref | State | Title (truncated) | Edge effect at Stage 4 |
|---|---|---|---|
| #164 | CLOSED | shadow-warn-enforce rollout convention | #211 blocker satisfied |
| #178 | CLOSED | SIOR escalation routing | #211 blocker satisfied |
| #222 | OPEN | Dev Testing mode for QA Auditor | SOFT — does not gate #211 analysis |
| #181 | CLOSED | PMO Skill Router | #211 downstream, already closed |
| #161 | CLOSED | health-check skill (Check 2) | #436 conditional blocker resolved |
| #344 | CLOSED | domain in intake template | #545 collision concern resolved |
| #507 | CLOSED | type-pack meta-schema | #1090 substrate built |
| #532 | CLOSED | work-org mapping framework | #1090 substrate built |
| #409 | CLOSED | epic (parent of #1090) | parent epic closed |
| #1067 | OPEN | intake-template-by-type | #1090 reconcile target |
| #47 | OPEN | Stage 5 substrate-drift reconciliation | #436 relates, non-blocking |
| #413 | n/a | (referenced as codified, out-of-scope boundary) | #436 boundary, OUT of scope |

No 404s. No confirmed digit-mismatch. The #211 blocker chain is the only one with staleness movement — and the movement is favorable (blockers closed since the body was written).

---

### Implementation Sequence

Dependency-ordered. Because the three BUILD issues share no dependency edge, sequence is driven by (a) governance-correction prerequisites and (b) blast-radius (do the surgical-edit-heavy governance item under careful review first). DEFER/CLOSED-RECORD items are sequenced as Stage-13 actions only.

| Order | Issue | Rationale for position |
|---|---|---|
| **0 (pre-build, Stage 4 close-out)** | Governance reconcile | Amend milestone #199 description (fix Cards list, add `## Release Class` + `## Parallelization Map`). This is a Stage-3/4 milestone-description correction, operator-approved, not part of any issue's build. |
| **1** | **#436** | Authors ONE new canonical `core/specs/` spec + a cross-mechanism mapping table, then points 5 existing detectors at it via SURGICAL edits (CLAUDE.md + template = Tier-1 governance). Highest review-care item; do it first so its CLAUDE.md touch lands before #545's CLAUDE-adjacent touches. No dependency on #211/#545. |
| **2** | **#545** | Template + gate-behavior change (`.github/ISSUE_TEMPLATE/*.yml`, `gate-criteria-spec.md` G1-01, `deploy.sh` Check 22, `intake-style-guide.md`, `intake-desk`). Touches `intake-style-guide.md` + `intake-desk/SKILL.md` — the contention surface with the deferred #1090, so landing #545 first cleanly establishes the title-summary rubric section #1090 would later extend. |
| **3** | **#211** | Pure IA decision: options-analysis + ADR (if non-obvious) + conditional spec/taxonomy/board updates. Largest design-judgment surface (size:L), but lowest file-contention. Sequenced last so its (possible) Status-value change to `ticket-information-architecture.md` does not collide with #436's reconcile of the same spec family. Re-verify #164/#178/#222 existence at claim (done here: only #222 open, non-gating). |
| **(Stage 13)** | **#1090** | Not built. Stage-13 action: confirm it stays OPEN; recommend it be sliced into phase children under #409 in a future milestone. |
| **(Stage 13)** | **#229** | Already closed. Stage-13 action: include as closed-record in RELEASE_LOG; no re-open, no gap-review. |

Note on #436 ↔ #211 soft ordering: both touch the `ticket-information-architecture.md` / spec family conceptually, but on **different axes** (#436 = staleness-confidence spec, a NEW file; #211 = Status-field values in the existing spec). They do not edit the same lines. Sequencing #436 → #211 is a contention-avoidance courtesy, not a hard edge — they are parallel-safe at the file level if the operator prefers (#436 adds a new spec; #211 edits Status-value lines). See Contention Map.

---

### Stage Applicability Matrix

Per issue, Stages 5–13. Default: all apply. Skip Solutioning (5) only if trivial; skip Dev Testing/QA (7–8) only if no functional impact. `domain: governance` for the whole release (File-Change Matrix is entirely internal pmo-platform governance/skill/gate artifacts — sourcing-exempt per stage-04-planning.md §5.7, but domain-classified `governance`).

| Stage | #436 | #545 | #211 | Reason |
|---|---|---|---|---|
| **5 Solutioning** | **APPLY** | APPLY | **APPLY** | #436: spec decides score-vs-ordinal-enum-vs-hybrid representation (design uncertainty stated in body) → APPLY. #545: convention + gate-floor design (rubric shape, Check 22 floor) → APPLY (could be light). #211: options-analysis + trade-off matrix + ADR-if-non-obvious is the core deliverable → APPLY (deep). Release-class `cross-cutting` biases Stage-5 activation toward ALL. |
| **6 Engineering** | APPLY | APPLY | APPLY | All three produce file changes. |
| **7 Dev Testing** | APPLY | **APPLY (load-bearing)** | APPLY | #545 ships a `deploy.sh` Check 22 that must be run against 2 crafted fixtures (clean summary passes, bracket-prefix fails) — functional gate logic, must test. #436: grep-based completion conditions verifiable. #211: verify spec/taxonomy/board edits + ADR present. |
| **8 QA** | APPLY | APPLY | APPLY | Governance/skill edits → pmo-qa-auditor + skill-editor discipline (intake-desk touch in #545/#1090-absorbed scope). |
| **9 Plan Review** | APPLY (Deep) | APPLY (Deep) | APPLY (Deep) | `cross-cutting` → Deep Stage-9 per release-class-taxonomy.md (CLAUDE.md + template Tier-1 touches demand blast-radius review). |
| **10 Pkg / 11 Mirror** | APPLY | APPLY | APPLY | #545 + (#436 CLAUDE.md→template mirror) require rules/template mirror sync; #545 intake-desk edit → `.skill` package rebuild + deploy. |
| **12 Execute** | APPLY | APPLY | APPLY | Single release tag + deploy. |
| **13 Close** | APPLY | APPLY | APPLY | Plus closed-record for #229 and defer-confirm for #1090. |

**Skip justifications:** No stage is skipped for any BUILD issue. None of the three is trivial enough to skip Stage 5 (each carries genuine design judgment — representation choice, gate-floor design, or Status-value options analysis), and all three have functional impact (a gate, a spec consumers read, or a deployed board field) so Stages 7–8 all apply.

#### File Change Matrix (machine-readable — one path per line)

Intent tag per path: `[ADD]` new file, `[EDIT]` modify existing, `[DEL]` delete. Issue attribution in trailing comment. Paths confirmed live at Stage 4 unless marked `[ADD]`.

```
core/specs/staleness-confidence-representation.md            [ADD]   #436 — the ONE canonical spec + cross-mechanism mapping table (≥5 rows)
release/governance/release-process.md                        [EDIT]  #436 — AC-Drift + Tier-0 PT-1..PT-4 map to shared scale
operations/skills/delivery-engine/SKILL.md                   [EDIT]  #436 — backlog-aging output references shared scale
core/disciplines/decision-discipline.md                      [EDIT]  #436 — audit-snapshot verdict maps to shared scale
CLAUDE.md                                                    [EDIT]  #436 — context-drift severity aligned to shared scale (SURGICAL)
core/CLAUDE.md.template                                      [EDIT]  #436 — context-drift severity aligned (SURGICAL, mirror of CLAUDE.md)
core/specs/health-check-specification.md                     [EDIT]  #436 — Check 2 graduated model cross-referenced as candidate canonical (verify scope at Stage 5)
.github/ISSUE_TEMPLATE/improvement.yml                       [EDIT]  #545 — drop "[Category]: " prefix; add title-guidance comment
.github/ISSUE_TEMPLATE/bug.yml                               [EDIT]  #545 — drop "[Bug]: " prefix; add title-guidance comment
.github/ISSUE_TEMPLATE/observation.yml                       [EDIT]  #545 — drop "[Observation]: " prefix; add title-guidance comment
core/schemas/gate-criteria-spec.md                           [EDIT]  #545 — repurpose G1-01 into informativeness floor; reconcile adapters L98/L100/L112/L236/L244/L268/L276
core/deploy/deploy.sh                                        [EDIT]  #545 — Check 22 fails bracket-prefix title, passes clean summary
release/references/how-to/intake-style-guide.md              [EDIT]  #545 — add title summary-informativeness rubric section  ⚠ CONTENDED with #1090
operations/skills/intake-desk/SKILL.md                       [EDIT]  #545 — elicit to the rubric  ⚠ CONTENDED with #1090
operations/skills/intake-desk/evals/evals.json              [EDIT]  #545 — expected outputs drop bracketed rendered-title prefix
release/tools/tests/conformant_bundleable_sample.json        [EDIT]  #545 — titles pass new G1-01
release/references/specs/ticket-information-architecture.md  [EDIT]  #211 — Status values updated IFF options-analysis changes them; T3/T4/T5 transition note
core/governance/label-taxonomy.md                            [EDIT]  #211 — Status values reconciled IFF changed
release/references/how-to/github-projects-guide.md           [EDIT]  #211 — board Status field reconfig guidance IFF changed
core/ADRs/ADR-NNN-status-field-granularity.md                [ADD]   #211 — ADR IFF the chosen option is non-obvious (Stage 5 decides)
```

Conditional-edit note: #211's spec/taxonomy/board edits are **gated on the options-analysis outcome** — if the analysis recommends keeping the current 5 Status values, those four paths are no-ops and #211 resolves with the analysis + ADR alone. The matrix lists them as the maximal surface.

---

### Contention Map

Which issues share affected files — load-bearing for parallelism. Within-release contention is near-zero; the material contention is **release-vs-deferred** (#545 vs #1090), which is itself the argument for deferring #1090.

| File | #436 | #545 | #211 | #1090 (deferred) | Class |
|---|:---:|:---:|:---:|:---:|---|
| `CLAUDE.md` + `core/CLAUDE.md.template` | ✎ | (adjacent) | — | — | within-release: #545 is "CLAUDE-adjacent" per its body but does not edit CLAUDE.md itself; #436 edits it. **No hard collision** — sequence #436 before #545 as courtesy. |
| `core/schemas/gate-criteria-spec.md` | — | ✎ | — | — | single-issue (#545) |
| `core/deploy/deploy.sh` | — | ✎ | — | — | single-issue (#545) |
| `release/references/how-to/intake-style-guide.md` | — | ✎ | — | ✎ | **CONTENDED** #545 ↔ #1090 — both add an intake-style-guide section. #545 adds a *title-summary rubric*; #1090 adds *per-kind/per-methodology authoring guide*. Different sections, same file. |
| `operations/skills/intake-desk/SKILL.md` | — | ✎ | — | ✎ | **CONTENDED** #545 ↔ #1090 — #545 makes it elicit to the title rubric; #1090 adds the Domain→Methodology→Kind→Fields reasoning step. Same SKILL.md. |
| `operations/skills/intake-desk/references/*` | — | — | — | ✎ | single-issue (#1090: type-map.md + elicitation-loop.md) — not touched by #545. |
| `release/references/specs/ticket-information-architecture.md` | — | — | ✎ | — | single-issue (#211) — #436 authors a NEW spec, does not edit this one. |
| `core/specs/*` (new) | ✎ (new file) | — | — | — | #436 adds `staleness-confidence-representation.md`; no collision (new path). |

**Within-release parallelism verdict:** #436, #545, #211 are **parallel-safe** — no two edit the same file (the CLAUDE.md proximity of #545 is adjacency, not a shared edit). Stage 7/8 spokes for the three may run concurrently. The sequence above is a review-ordering preference, not a hard serialization.

**Release-vs-deferred contention (the decisive finding):** #545 and #1090 collide on **2 files** (`intake-style-guide.md`, `intake-desk/SKILL.md`). If #1090 were pulled into this release, its intake-desk refit and #545's intake-desk gate-elicitation edit would serialize against each other on the same SKILL.md — and #1090 is a *container that has not been sliced* (0 sub-issues; its own AC-1 forbids consumer refit before slicing). **Confirmed claim:** the hub-briefing contention signal is real. This is the load-bearing reason #1090 is DEFER, not BUILD.

---

### Risk Register

Each risk: named, owner, mitigation. No passive voice.

| # | Risk | Class | Reversibility | Owner | Mitigation |
|---|---|---|---|---|---|
| R1 | **#211 Status-value change cascades to deployed board.** If the options-analysis changes the 5 Status values, the live GitHub Projects Status field, downstream board views, and `label-taxonomy.md` all move — days to undo, board-state impact (the issue body states this explicitly). | scope / rollback-complexity | MODERATE | Operator (decision) + Engineering (board reconfig) | Gate the board reconfig behind the ADR. If the analysis recommends keeping 5 values, the cascade never fires (the analysis/ADR step alone is CHEAP). Surface the cascade at Stage 9 as an explicit go/no-go on the board edit. |
| R2 | **#545 deploy.sh Check 22 false-positives on legacy titles.** Every legacy open issue keeps the old `[Category]:` prefix; an enforce-tier Check 22 would fail `--check` on every legacy title. | dependency / rollback-complexity | CHEAP | Engineering (#545) | Keep G1-01 / Check 22 **warn-tier** (non-blocking) per the issue body's explicit build rule. Test Check 22 against 2 crafted fixtures pre-merge (clean passes / bracket fails). Bulk re-title of existing issues is an OPTIONAL separately-authorized follow-up, NOT in this card. |
| R3 | **#436 CLAUDE.md / template surgical edit over-reaches.** #436 touches CLAUDE.md + `core/CLAUDE.md.template` (Tier-1 governance) — a non-surgical edit risks restructuring unrelated context-drift prose. | contention / scope | CHEAP (revert via git) | Engineering (#436) | SURGICAL edit only (issue body mandates it); diff-before-commit; the completion condition itself asserts "diff shows no unrelated restructure". Mirror CLAUDE.md ↔ template in the same commit (Check 9 rules-mirror / template-mirror). |
| R4 | **#1090 scope-creep if not held out.** #1090 is a deferred non-atomic container; pulling any slice of it into this release risks the "staleness-subsystem rewrite" balloon its own notes warn against, and collides with #545 on intake-desk. | scope | CHEAP (defer is the default) | Operator + Release-planner | DEFER #1090 entirely; recommend slicing into phase children under #409 in a future milestone. Land #545's intake-desk rubric section cleanly first so #1090's later authoring-guide section extends rather than conflicts. |
| R5 | **Version anchor-lineage ambiguity mis-tags the release.** v3.20 is reachable from `origin/main`; the literal `anchor()` rule ("highest claimed in mainline lineage, orphans excluded") could select v3.21, while practice (v2.13–v2.22 all post-date v3.20) has stayed on v2.x. A wrong anchor read mis-numbers the tag and could collide. | dependency / rollback-complexity | MODERATE (tag rename is painful post-claim) | Operator (D-Version) | Operator renders D-Version explicitly (see Operator Decisions). Re-run `git fetch --tags origin` + the authoritative selection at Engineering Commit 0 (the founding defer-to-merge architecture catches a concurrent claim). Recommend confirming whether the v3.x lineage is formally excluded by the adapter's `anchor()` so this ambiguity stops recurring. |
| R6 | **Milestone-description drift mis-scopes the bundle.** #199's description lists #32 (CLOSED, different milestone) and omits #1090/#229; a downstream stage reading the description as authoritative would mis-scope. | dependency | CHEAP | Operator + hub (Stage 4 close) | Amend the milestone description as Order-0 action: correct the Cards list to the live membership, add `## Release Class` + `## Parallelization Map`. Reconcile against the live `gh issue list --milestone` result, not the description. |
| R7 | **.version staleness misleads version tooling.** `.version` = v2.19, three releases behind the live tag v2.22 — real drift, not a separate cadence. | dependency | CHEAP | Operator / release tooling | Flag as drift (Moderate severity — stale version stamp). Recommend bumping `.version` to the claimed version at Stage 12 as part of this release, or filing a separate hygiene issue if out of scope. Not a build blocker. |

---

### Operator Decisions (D-ReleaseClass / D-Version / D-C, D-Gate Template format)

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke-proposed class + trigger-condition evidence per `release/references/specs/release-class-taxonomy.md`. The 3 BUILD issues' File-Change Matrix touches **≥3 governance surfaces** ({CLAUDE.md, gate-criteria-spec.md, deploy.sh, release-process.md, decision-discipline.md}) — `cross-cutting` trigger (b) fires (≥3 of the named governance surfaces). Also #436 + #211 each add a new file (`staleness-confidence-representation.md`; a possible ADR) — `novel` trigger (a) fires. Multi-trigger resolution: `cross-cutting` > `novel`.
**Pre-decided (if applicable):** OMIT — no per-decision operator stance on record; milestone description carries no `## Gate-Class Framing Directives` block (it predates the convention).
**Gate decision:** Choose between (A) routine, (B) novel, (C) cross-cutting, (D) hotfix.
**Blocks:** Stage 3 Phase B3 milestone-description `## Release Class` authoring (deferred to the Order-0 reconcile); downstream per-class differentiation posture (engagement density, Stage-9 depth, Stage-5 bias).
**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable later with operator approval per release-class-taxonomy.md Re-Classification Protocol; cheaper-to-stricter is CHEAP/HIGH).
**Recommendation:** **(C) cross-cutting.** Rationale (≤2 sentences): the 3-issue File-Change Matrix touches ≥3 named governance surfaces (CLAUDE.md + template, gate-criteria-spec.md, deploy.sh, release-process.md, decision-discipline.md), firing cross-cutting trigger (b); it also adds ≥1 new spec/ADR, firing novel trigger (a), and cross-cutting wins multi-trigger resolution. Differentiation posture: Engagement density **Tight**; Stage-9 review depth **Deep**; Stage-5 activation bias **ALL** (the cross-issue surface — three independent governance edits touching CLAUDE.md/templates — warrants design review); Stage-13 outcome-window **30-day**.

#### D-Version: What version does this release claim?
**Gate input:** Spoke-recommended next-free, computed at recommendation time against AUTHORITATIVE host state. `git fetch --tags origin` performed. Latest reachable tag from HEAD = **v2.22** (just shipped, 2026-06-25). Bump-class for this release's content = **minor** (per RELEASE_PROTOCOL.md Bump-Class Selection Guide: "Protocol text addition or modification" = minor; "Reference document addition or update" = minor; "Tracker schema change" = minor — the release is protocol/reference/gate edits, no new skill and no new governance *file-class*; #436's new `core/specs/` spec is a reference/spec doc, not a new governance file-class that would force major). **ANOMALY:** tag `v3.20` exists and **IS reachable from `origin/main`** (landed via PR #496, `release/v3.20-...`, 2026-06-07). By the literal `anchor()` definition ("highest claimed version in the mainline lineage, orphan lineages excluded"), v3.20 would be the anchor → minor floor = v3.21. **However**, practice has treated v3.20 as an anomaly: v2.13 through v2.22 were ALL tagged AFTER 2026-06-07 yet stayed on the v2.x line — the operator's effective anchor is v2.22.
**Pre-decided (if applicable):** OMIT — no per-decision stance on record.
**Gate decision:** Operator renders version identity — (A) accept spoke-recommended next-free **v2.23** (minor above the v2.22 practical anchor; v2.23 confirmed FREE), (B) version-less theme-named milestone (no tag at Stage 12), or (C) operator-specified override (e.g. **v3.21** if the v3.x lineage is formally the mainline anchor, or another slot).
**Blocks:** release branch name (`release/<slug>`), plan-file path, the Stage-12 atomic version claim, and any `version:` frontmatter the release writes (e.g. the intake-desk SKILL.md version bump from #545).
**Upstream compatibility:** N/A — version identity is PMO platform internal; no Anthropic upstream surface. Upstream compatibility check does not apply. (The intake-desk `version:` field that #545 will bump takes its value from this D-Version outcome; its upstream posture is owned by the #545 edit, not by D-Version.)
**Reversibility / Confidence:** CHEAP pre-Engineering (recommendation only); MODERATE after Engineering Commit 0 (identity propagates into branch name, plan-file path, frontmatter) / **MEDIUM** confidence — downgraded from HIGH solely by the v3.x anchor-lineage ambiguity, which only the operator can resolve.
**Recommendation:** **(A) accept v2.23, bump-class minor** — consistent with the operator's established practice (the entire v2.13→v2.22 run post-dates v3.20 and stayed on v2.x, so v3.20 is being treated as an orphan/anomaly in practice regardless of its graph reachability). **Opposing view (load-bearing):** if the adapter's `anchor()` literally consumes graph-reachability and the v3.x line is NOT in its orphan-exclusion set, the deterministic next-free is **v3.21**, and shipping v2.23 would be a rule-violating manual override. **Recommended operator action:** confirm v2.23 AND, separately, decide whether the v3.x lineage should be formally excluded by `anchor()` so this ambiguity stops recurring (a one-line adapter/ledger clarification — out of scope for this release, worth a hygiene issue). Re-run the authoritative selection at Engineering Commit 0 per the standing defer-to-merge discipline.

#### D-C: Branch topology — single release branch vs per-issue branches?
**Gate input:** 3 BUILD issues, mutually dependency-independent, with near-zero within-release file contention (no two edit the same file). Standard pmo-platform release topology is single-branch (`release/vX.Y-<slug>`) with the plan committed as the first file; per-issue branches (Option-A) are reserved for releases where issues are independently shippable or contention forces isolation.
**Pre-decided (if applicable):** OMIT.
**Gate decision:** (A) single release branch `release/v2.23-ticket-information-architecture` (default), or (B) Option-A per-issue branches (`feature/#436-...`, `feature/#545-...`, `feature/#211-...`) merged into the release branch.
**Blocks:** Procedure 1 scaffolding (sub-task branch references); Stage-6 Engineering spoke branch setup; Stage-12 merge sequence.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface (it governs release branch topology / merge sequence). Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (branch topology is trivially re-organizable before Engineering Commit 0).
**Recommendation:** **(A) single release branch.** Rationale: the three issues are not independently shippable (they cohere as one IA milestone), within-release contention is nil so isolation buys nothing, and single-branch keeps the plan-as-first-file discipline and one PR-review (the dry-run gate) intact. If the operator wants #211's board-cascade decision (R1) isolated from the #436/#545 governance edits for a cleaner Stage-9 review, a *single* split (#211 on its own branch, #436+#545 together) is the only split worth considering — but the default single-branch with sequenced commits is sufficient given the Deep Stage-9 review the `cross-cutting` class already mandates.

---

### Recommendations

**Build scope (explicit BUILD / DEFER / CLOSED-RECORD classification of all 5 issues):**

| Issue | Classification | Rationale |
|---|---|---|
| **#436** | **BUILD** | Genuine-open (verified live): no unification spec exists, all 5 cited mechanisms still divergent. Bounded to the confidence-representation axis (boundary with #413 = response posture is codified and held). Authors ONE canonical spec + mapping table + surgical consumer edits. |
| **#545** | **BUILD** | Genuine-open (verified live): all three templates still carry bracket prefixes, gate G1-01 still requires them, no title-summary rubric exists. EXTEND (no new artifact beyond a deploy.sh check). Warn-tier gate protects legacy titles. |
| **#211** | **BUILD** | Genuine-open: spec still defines 5 Status values, no options-analysis/ADR rendered. Correct milestone home (do NOT migrate to spoke-execution-safety #1190). Blocker chain re-verified — only #222 open, non-gating. |
| **#1090** | **DEFER** | Deferred non-atomic container; **0 native sub-issues** (verified via API); its own AC-1 forbids consumer refit before slicing. **Contends with #545** on `intake-style-guide.md` + `intake-desk/SKILL.md` (claim CONFIRMED). Recommend slicing into phase children under epic #409 (CLOSED parent — reopen-or-new-milestone is an operator call) before any build. Not buildable as-is in this release. |
| **#229** | **CLOSED-RECORD** | Already CLOSED (validation spike, type:spike). **No gap-review needed** (Procedure 1 step 3): the sub-issue capability it validated is in active production use today (the hub-spoke pipeline creates sub-task issues routinely; #229's own related-issue #61/#149 protocols shipped). Include as closed-record in RELEASE_LOG at Stage 13; do not re-open. |

**Governance corrections (operator-approved, surfaced — not auto-actioned):**
1. **Reconcile milestone #199 description** (Order-0, before build): correct "Cards (4): #32 #211 #436 #545" to the live membership — #32 is CLOSED and lives in `86-hybrid-comanagement-decouple` (drop it); #1090 and #229 are members and should be represented (with #1090 marked deferred, #229 closed-record). Add the missing `## Release Class` H2 (cross-cutting per D-ReleaseClass) and a `## Parallelization Map (recorded 2026-06-25)` section recording the parallel-safe #436/#545/#211 set and the #545↔#1090 file-contention edge. This is a milestone-description correction within Stage 3/4 scope; it touches no skill or governed file beyond the GitHub milestone body.
2. **`.version` drift (Moderate):** `.version` = v2.19 trails the live tag v2.22 by 3 releases — real drift, not an intentional cadence. Recommend updating `.version` to the claimed version (v2.23 if D-Version (A)) at Stage 12, or filing a separate hygiene issue if the operator prefers to keep it out of this release.

**Out-of-scope discoveries (noted, not acted on per scope discipline):**
- **v3.x anchor-lineage ambiguity** (R5/D-Version): the v3.20 tag is graph-reachable from `origin/main` yet practice treats it as an anomaly. Worth a one-line adapter/ledger clarification (does `anchor()` formally exclude the v3.x lineage?) so D-Version stops carrying this ambiguity every release. Recommend filing an `improvement.yml` against the versioning adapter — NOT part of this release.
- **#1090 epic re-home:** #1090's parent epic #409 is CLOSED. Slicing #1090 into phase children "under #409" needs an operator call on whether to reopen #409, attach the children to a new epic, or land them in a fresh milestone. Flag at the time #1090 is picked up; not actionable in this release.

**Top 3 risks (for the hub):** R1 (#211 Status-value board cascade — MODERATE, gate the board edit behind the ADR), R5 (version anchor-lineage ambiguity — MODERATE, operator must render D-Version explicitly), R2 (#545 Check 22 legacy-title false-positives — CHEAP, hold the gate at warn-tier).

**Items needing operator input:** (a) D-ReleaseClass confirm `cross-cutting`; (b) D-Version confirm v2.23 vs v3.21 vs version-less — the anchor-lineage call is the one genuine ambiguity; (c) D-C confirm single-branch; (d) approve the milestone-description reconcile (Order-0); (e) acknowledge #1090 DEFER + #229 CLOSED-RECORD dispositions.

