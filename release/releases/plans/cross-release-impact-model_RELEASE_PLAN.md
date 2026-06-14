<!-- repo-integrity: allow-issue-ref -->
<!-- repo-integrity: allow-memory-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-issue-ref -->
<!-- reference-durability: allow-version-ref -->
# Release Plan — cross-release-impact-model

> Stage 4 release plan of record. Authored at Stage 4 Planning; copied to this committed plan file at Stage 6 Engineering Commit 0 (SINGLE-branch topology). Source: parent #87, Milestone cross-release-impact-model. Operator B1 planning-gate decision record + Stage 5 scope-lock are recorded on the parent/sub-task issues; this file is the durable plan-of-record.

---

## Stage 4 Release Planning — cross-release-impact-model

### Summary (30 seconds)

This Milestone contains exactly one in-scope issue, **#87** ("Add a cross-release impact model for planning and gating concurrent releases") — a `type:story` carrying `epic:pipeline-definition-fitness`, `layer:foundation`, `cluster: cross-cutting`, `protocol`, `status: bundled`. [SOURCE: `gh issue list --milestone cross-release-impact-model`]

#87 is a **cross-cutting Protocol spec** that adds one durable, repo-agnostic capability — a model of the concurrent + planned release set and its mutual impact — consulted at five pipeline surfaces: Stage 3 Bundle (parallelization decision), Stage 4 A4/Phase A0 (mover blast-radius + stale-pin revalidation), Stage 5 Collective Review (cross-*release* coherence), Stage 9 GO (baseline-SHA currency gate criterion), Stage 12 Phase A.5 (semantic GO-invalidation check). The issue body **states the outcome, not the mechanism — mechanism is explicitly deferred to Stage 5 Solutioning.** [SOURCE: #87 body § Proposed Change]

Because #87 is a single issue, the dependency graph is **internal** (ordering among the five surfaces and six files it edits), not inter-issue. There is **no external prerequisite** — the body says "No hard prerequisite," and its one declared "Blocks #114" edge is **rotten** (see Risk R-6 / Recommendations). [SOURCE: `gh issue view 114` → #114 resolves to an unrelated issue in a different milestone.]

**Headline recommendations:** Proposed Release Class **`cross-cutting`** (three independent triggers fire). Merge/split verdict: **keep as a single `type:story` release — do NOT treat as an epic/umbrella, and do NOT split.** Stage 5 Solutioning is **MANDATORY** (mechanism is deferred to it by the issue itself). All of Stages 5–13 apply.

**Baseline pin (audit-baseline discipline):** This plan's cross-release contention scan and currency claims are pinned at **origin/main `dfb3836`** (worktree HEAD `4a6b7aa` is 9 commits behind origin/main from the v1.15 merge, but **none of the six affected files diverge** between the two — verified `git diff --stat 4a6b7aa origin/main -- <6 files>` returns empty). Re-check the sibling-milestone population (≈28 open milestones) before relying on the contention findings at Stage 9. [SOURCE: `git rev-parse`, `git diff --stat`]

---

### Dependency Graph

**External (inter-issue) edges: NONE that are load-bearing.**

- The issue body declares **"Blocks #114"** and calls #114 "the bundling-layer instantiation (durable Parallelization Map)." **This edge is rotten.** `#114` currently resolves to *"Reconcile stale reorg-era metadata in Milestone v11.06 (#39) description"* in milestone `governance-cross-reference-currency` — an unrelated issue. The adjacent body references (`#1151`, `#1852`, `#49`, `#979`) are likewise pre-re-versioning numbers. **Exclude the #114 edge from sequencing.** [SOURCE: `gh issue view 114 --json title,milestone`] The capability #87 describes as "the bundling-layer Parallelization Map" already ships in the corpus today — the standing `## Parallelization Map (recorded YYYY-MM-DD)` milestone-description convention is live in `stage-03-bundle.md` § A9.6 and the Stage 4 Phase A0 currency check. So the "child" #87 names is already in the codebase; #87's job is to extend that classifier to the path-invalidation axis and to add the four uncovered surfaces. [SOURCE: `stage-03-bundle.md` lines 50-89; `stage-04-planning.md` lines 46-52]

**Internal dependency order (the load-bearing graph for a single-issue release)** — among the five surfaces, the model must be *defined* before it can be *consumed*:

```
[N1] Contention-axis definition (the path-invalidation / structural-blast-radius axis
      + reproducible signal-set)  —  defined in stage-03-bundle.md (A9.6 classifier extension)
      AND stage-04-planning.md (A4 audit)
        │  (every other surface consumes the axis definition)
        ▼
[N2] Stage 4 A4 / Phase A0 consumption   ──┐  (mover blast-radius detection;
      stage-04-planning.md                  │   sibling-merge stale-pin revalidation trigger)
        │                                    │
        ▼                                    │
[N3] Stage 5 Collective Review consumption   │  (cross-release coherence over the
      stage-05-solutioning.md                │   concurrent release set)
        │                                    │
        ▼                                    │
[N4] Stage 9 GO-currency gate criterion  ◄──┘  (GO records baseline SHA + revalidation
      gate-criteria-spec.md Gate 9 (G-PR*)      predicate)
        │
        ▼
[N5] Stage 12 Phase A.5 semantic GO-check
      release-process.md (§ Stage 12 Main-divergence pre-check)
```

**Why this order:** N1 is the keystone — the *contention axis + its detection signal-set* is the new primitive every other surface reads. N4 (the Gate 9 baseline-SHA criterion) consumes the axis but is *itself* consumed by N5 (Stage 12 Phase A.5 reads "the GO's recorded baseline SHA" to do the semantic check), so N4 precedes N5. N2 and N3 are parallel consumers of N1 (no edge between them). `release-planner/SKILL.md` (N6, not drawn) is the **candidate maintainer** of the model — it is a downstream-of-N1 authoring surface, edited last to wire the skill to whatever persistence shape Stage 5 lands. [SOURCE: #87 body § Affected Files; cross-checked against the live spec surfaces.]

**Cross-release (concurrent-release) edges — the axis #87 itself introduces.** This is a release whose own subject matter is cross-release contention, and the live milestone population makes that contention *real*, not hypothetical. A body-grep across the ≈28 open sibling milestones for the six affected paths surfaces direct same-file contenders (see Contention Map § Cross-release). This does not create a *blocking* dependency on #87 (no hard "blocked by" edge), but it is the dominant **risk** input and is captured in R-2. [SOURCE: `gh issue list --state open --jq 'select(.body | test(...))'` at `dfb3836`]

---

### Implementation Sequence

Dependency-ordered execution across the six files (consume-after-define). This is the **engineering sequence**, authored here for the Stage 6 spoke; it is not an approval-gate sequence.

| Seq | File | Surface (#87 node) | Add/Edit/Delete intent |
|---|---|---|---|
| 1 | `release/references/pipeline/stage-03-bundle.md` | N1 — define the axis | **EDIT** — extend the A9.6 Hard-vs-soft edge classifier (lines 71-79) with the **path-invalidation / structural-blast-radius axis** (rename / relocate / delete-and-recreate / directory-restructure) as a third contention class alongside ticket-dependency and same-path; add the reproducible detection signal-set. Compose with the existing `## Parallelization Map` convention (do not restate it — AC-6). |
| 2 | `release/references/pipeline/stage-04-planning.md` | N2 — consume at A4 / Phase A0 | **EDIT** — extend the A4 Cross-PR Overlap Audit (lines 85-87) to model mover/rename/delete blast radius; add the **sibling-merge stale-pin revalidation trigger** (a pinned audit at SHA X self-invalidates when a sibling parallel release merges after X). Extend the Phase A0 currency check (lines 46-52). |
| 3 | `release/references/pipeline/stage-05-solutioning.md` | N3 — consume at Collective Review | **EDIT** — extend the Collective Review checkpoint (lines 282-319) so it covers cross-***release*** coherence (the concurrent release set), not only cross-***issue*** coherence within one release. |
| 4 | `core/schemas/gate-criteria-spec.md` | N4 — Gate 9 criterion | **EDIT** — add a Gate 9 criterion (next-free `G-PR*` slot; current max is **G-PR7**, so **G-PR8** unless a sibling claims it first — see R-4) requiring a GO to **record its baseline SHA** and defining the **sibling-merge revalidation predicate**. Add the matching Self-Repair row. |
| 5 | `release/governance/release-process.md` | N4/N5 — Stage 9 GO + Stage 12 Phase A.5 | **EDIT** — Stage 9 section (line 396+): GO baseline-currency condition. Stage 12 § Main-divergence pre-check (line 439): add the **semantic GO-invalidation check** distinct from the existing blind `git merge` at Phase A.5. (`.claude/rules/release-process.md` is a deployed mirror of this canonical body — the deploy step syncs it; do not hand-edit the mirror.) |
| 6 | `release/skills/release-planner/SKILL.md` | N6 — model maintainer | **EDIT** — wire the skill (candidate maintainer of the cross-release model; it already maps deps + emits the Parallelization Map auto-populator at Mode B, lines 172/205-207) to whatever persistence + reconfirm shape Stage 5 finalizes. **Sequenced last** — it consumes the spec decisions from seq 1-5. |

**No file is added or deleted** — #87 is purely additive-to-existing-specs ("additive spec + gate criteria" per the issue's own reversibility note). [SOURCE: #87 body § Risks — "Reversibility CHEAP (additive spec + gate criteria; `git revert`)"]

**Sequencing note for the operator:** the six edits are tightly coupled by a single shared concept (the cross-release model), so the realistic Engineering shape is **one PR, internally ordered 1→6**, not six PRs. Splitting would manufacture the very cross-PR contention #87 is about (R-2). This is a recommendation, not a Stage-4 decision (branch topology = D-C, rendered at scaffolding).

---

### Stage Applicability Matrix

Default per `hub-spoke-bridge.md` Procedure 0: all stages apply; justify any skip. For the single issue #87:

| Stage | Applies? | Rationale (one line) |
|---|---|---|
| **5 — Solutioning** | **YES (MANDATORY)** | The issue body **explicitly defers the mechanism to Solutioning** ("The fix (mechanism deferred to Solutioning)"). Phase 0 activation fires on ≥4 independent triggers: new structural design decision, cross-cutting 3+ governance files, multiple valid approaches (where to persist the model; how to detect structural blast radius), blast-radius uncertainty. A skip here is impossible without inventing the mechanism at Engineering — a guardrail violation. [SOURCE: #87 body; `stage-05-solutioning.md` Phase 0, line 38-39] |
| **6 — Engineering** | YES | Six spec/governance files require the additive edits in the Implementation Sequence. |
| **7 — Dev Testing** | YES | The issue ships **verifiable AC with grep-based methods** (e.g., "grep each pipeline/stage-0{3,4,5}.md … returns ≥1 match per stage"; "grep 'baseline SHA' in Gate-9 section"). Stage 7 runs those AC checks + the `domain_practice` provenance-label presence check. A spec change has *testable* impact via its own AC; do not skip. [SOURCE: #87 body § Acceptance Criteria] |
| **8 — QA Testing** | YES | The **worked-example AC is QA-class, not unit-class**: "v11.08↔v11.11 would be caught (serialize on structural blast radius) and v16.02↔v11.11 correctly *not* over-serialized." Validating that the new axis neither under-fires (misses a real collision) nor over-fires (needlessly serializes a safe release) is exactly the QA acceptance question. Skipping Stage 8 would leave the over-serialization risk (R-3) unverified. [SOURCE: #87 body § AC final bullet + § Risks] |
| **9 — Plan Review** | YES | Tier 3 human GO gate; non-skippable. Depth = **Deep** per `cross-cutting` class (see Release Class). |
| **10 — Dry Run** | YES (compressed) | Git-native: PR diff IS the dry run, satisfied during Stage 9. No separate step. [SOURCE: `release-process.md` Stage Compression, lines 19-24] |
| **11 — Snapshot** | YES (compressed) | Git history IS the snapshot; `git revert` is the rollback. No manual step. [SOURCE: `release-process.md` line 417-424] |
| **12 — Execute** | YES | Merge + tag + deploy-sync (`.claude/rules/release-process.md` mirror sync via `deploy.sh`). This release **dogfoods its own new Stage 12 Phase A.5 semantic check is NOT yet active** — see R-5 reflexive-cutover note. |
| **13 — Close** | YES | #87 is marked as closed via the PR's dedicated Issue References block at Stage 13 (auto-close keyword lives only there); milestone marked closed; RELEASE_LOG VERIFIED; INDEX + DIGEST + RELEASE_NOTES. |

**Skips: NONE.** Every stage applies. The only "skips" are the git-native **compressions** of Stages 10 + 11, which are not true skips (they are satisfied by git-native mechanisms per the standing Stage Compression rule).

**Decision-discipline classification of this matrix:** Stage applicability **derived from the pre-approved matrix is EXEMPT** from M1/M2/M3 per the decision-discipline triage table ("Exempt: Stage-gate applicability from pre-approved matrix → plan-driven application"). The one applicability call that is *not* mechanical — **whether Stage 5 is mandatory** — is treated as a substantive judgment and is justified above with cited triggers rather than asserted. [SOURCE: `decision-discipline.md` § 3 triage table, line 288]

---

### Contention Map

**Within-release (same-PR) contention — the six affected files.**

Because this is a single issue, all six files are touched by the same change-spec. The contention question is therefore **internal ordering**, resolved by the Implementation Sequence (consume-after-define), not cross-PR collision. There is **no append-vs-line-range overlap risk *within* the release** — one author, one logical change, sequenced edits. [SOURCE: #87 § Affected Files]

| File | Edited by #87 at | Append vs line-range | Within-release serialization |
|---|---|---|---|
| `stage-03-bundle.md` | A9.6 classifier (lines 71-89) | line-range (insert axis row + signal-set) | seq 1 |
| `stage-04-planning.md` | A4 audit (85-87) + Phase A0 (46-52) | line-range (two distinct regions) | seq 2 |
| `stage-05-solutioning.md` | Collective Review (282-319) | line-range | seq 3 |
| `gate-criteria-spec.md` | Gate 9 table + Self-Repair (373-393) | **append-pattern** (new G-PR8 row appended to an existing table) | seq 4 |
| `release-process.md` | Stage 9 (396+) + Stage 12 Phase A.5 (439) | line-range (two distinct regions) | seq 5 |
| `release-planner/SKILL.md` | Mode B persistence wiring (172, 205-207) | line-range | seq 6 |

**Cross-release (concurrent-milestone) contention — ELEVATED, and material.**

This is the load-bearing contention finding. A body-grep across the ≈28 open sibling milestones for the six affected paths, pinned at `dfb3836`, surfaces **direct same-file contenders** that are themselves in flight: [SOURCE: `gh issue list --state open --jq 'select(.body|test(...))'`]

| Sibling issue | Sibling milestone | Same-file contention with #87 | Class |
|---|---|---|---|
| **#353** | `release-identity-and-spec-hardening` | "Encode 5 pipeline-stage discipline memories into **release-process.md** and …" — edits the SAME file (seq 5) | **structural-blast-radius / same-path** |
| **#354** | `stage-gate-criteria-completeness` | "Encode 2 gate-criteria semantic memories into **gate-criteria-spec.md**" — SAME file (seq 4) | same-path |
| **#118 / #119** | `stage-gate-criteria-completeness` | Refactor `gate-criteria-spec.md` schema / add judgment dims — SAME file (seq 4) | same-path (#119 is a *schema refactor* = structural blast radius) |
| **#381** | `hub-autonomy-conformance` | "Codify hub pipeline-operation disciplines into **the stage specs**" — overlaps seq 1-3 | same-path (stage-0X) |
| **#306** | `pipeline-skill-doc-reconciliation` | "Extract G-PR8 mid-pipeline-divergence prose to **stage-09-plan-review.md**" — adjacent to #87's Stage 9 GO surface AND **may also claim the `G-PR8` ID** | ID-collision + adjacent |
| **#278 / #246 / #290 / #294 / #293** | `solutioning-and-engineering-skill-modes`, `bundling-capacity-and-sizing-gates`, … | release-planner SKILL.md / capacity model — overlaps seq 6 | same-path / adjacent |

**Append-vs-line-range overlap risk for Engineering serialization (the operator-requested flag):** the highest-risk concrete collision is **`gate-criteria-spec.md`** — #87 appends a Gate 9 row (append-pattern, structurally HIGH / operationally LOW on its own), but **#119 is a schema *refactor* of the same file** (structural blast radius, not append). An append-pattern + a concurrent structural-refactor on the same file is precisely the `line-range-overlap` × structural case that the existing ADR-005 append-pattern classifier rates as a real sequencing hazard — and exactly the unmodeled coupling #87 is trying to fix. **Mitigation:** if #87 and the `stage-gate-criteria-completeness` milestone are ever in flight concurrently, **serialize** (one merges, the other re-baselines) — do not parallelize. This is captured as R-2 and is itself a worked instance of #87's thesis.

**Reflexive note:** these cross-release collisions are detectable *today* only by this manual grep — there is no standing gate that catches them, which is the gap #87 closes. The plan documents them; #87 (once shipped) would make this detection systemic. [CONTEXT: #87 body root-cause statement]

---

### Risk Register

| ID | Risk | Type | Severity | Owner | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|---|---|
| **R-1** | **Stage 5 mechanism scope-creep.** Mechanism is deferred to Solutioning; an unbounded "model the whole concurrent release set" design could balloon into a multi-release initiative. | Scope | **HIGH** | Operator (Stage 5 scope-lock) | Bind the Stage 5 design to the issue's 6 stated outcomes + AC; the persistence surface is constrained by AC-5 ("systems already in place" — milestone descriptions / release plans / Projects, the A6 precedent), not a new datastore. Collective Review enforces scope. | MODERATE / MED — design choices made at Stage 5 are harder to unwind once engineered. |
| **R-2** | **Cross-release / structural-blast-radius contention with in-flight siblings** editing the same six files (#353 release-process.md; #354/#118/#119 gate-criteria-spec.md; #381 stage specs; #306 stage-09; #278/#246/#290 release-planner). #119 in particular is a *schema refactor* of gate-criteria-spec.md. | Contention (the exact class #87 names) | **HIGH** | Operator (sequencing) | **Serialize** #87 against any concurrently-active `stage-gate-criteria-completeness` / `release-identity-and-spec-hardening` / `hub-autonomy-conformance` release — do NOT parallelize. Pin this contention scan at `dfb3836` and **re-check the sibling population at Stage 9** (audit-baseline discipline — the population is non-empty now and will shift). | CHEAP / HIGH — sequencing is a scheduling choice, fully reversible. |
| **R-3** | **Over-serialization (issue's own stated risk).** A too-broad structural-blast-radius definition needlessly serializes safe concurrent releases. | Design correctness | MEDIUM | Stage 5 designer + Stage 8 QA | Blast radius = the moved/deleted/renamed path-set, NOT the whole repo. AC requires a worked example showing a safe concurrent release (v16.02↔v11.11) *not* serialized. **Stage 8 QA verifies both directions.** [SOURCE: #87 § Risks (INFERRED) + final AC] | CHEAP / HIGH — definition is tunable in a follow-up. |
| **R-4** | **Gate-ID collision.** #87 needs a new Gate 9 criterion; current max is **G-PR7**. **#306 may extract G-PR8** prose and a prior Stage-5 spec already hit the `G3-10/G3-11` collision pattern (resolved to G3-12). The "next-free slot" is contended. | Dependency / mechanical | MEDIUM | Engineering (Stage 6) | At Commit 0, re-query the live max `G-PR*` ID in `gate-criteria-spec.md` and claim **next-free** (likely G-PR8, but verify against #306's state); record a Tier-1 [ADJUST] deviation if the proposed ID is taken — exactly as the v1.7 G3-12 note did. [SOURCE: `gate-criteria-spec.md` v1.7 renumber note, line 494] | CHEAP / HIGH. |
| **R-5** | **Reflexive cutover — the release cannot gate itself.** #87 adds a Stage 9 GO-currency criterion + a Stage 12 Phase A.5 semantic check, but per the platform's standing reflexive-pipeline-loop discipline the **introducing release is exempt** from its own new gate. #87's own Stage 9/12 run AS-IS (pre-rule). | Process / correctness | MEDIUM | Hub + Operator | Author the new criteria with an explicit **introducing-release-exempt cutover clause** (the pattern used by every cutover in stage-04/05 and release-process). #87's own GO uses the *existing* G-PR8/Phase-A6.5 divergence checks (which DO apply — they predate #87). [SOURCE: reflexive-exempt pattern, `stage-04-planning.md` lines 75/87; `release-process.md` line 406] | CHEAP / HIGH — clause is standard boilerplate. |
| **R-6** | **Reference rot — restating the wrong "#114" (issue's own restating-#114 risk, sharpened).** #87's body + native "Blocks #114" edge cite #114 as the bundling-layer child; **#114 is actually an unrelated metadata-reconciliation issue.** Acting on the body's number would mis-coordinate. | Reference integrity | MEDIUM | Stage 5 + Engineering | **Do NOT sequence against #114.** For **AC-6** (disambiguation recorded), use **number-free / current-canonical phrasing** per the reference-durability standard — name the *concept* ("the standing Parallelization Map milestone-description convention in the Stage 3 Bundle spec"), not the rotted number. The "child" capability already ships in the corpus (A9.6); #87's real job is the path-invalidation axis + the 4 uncovered surfaces. [SOURCE: `gh issue view 114`; `stage-03-bundle.md` A9.6] | CHEAP / HIGH — phrasing choice. |
| **R-7** | **Ceremony risk (issue's own stated risk).** Cross-release checks at five stages could become form-filling. | Process efficacy | LOW | Stage 5 designer | Bind to existing A6/A7/A0/GO/Phase-A.5 surfaces rather than new free-floating steps; reuse the Stage-13 self-learnings channel as the efficacy feedback loop (the body's #979 reference — treat as the *concept*, the number is pre-re-versioning). [SOURCE: #87 § Risks (INFERRED)] | CHEAP / HIGH. |
| **R-8** | **Rollback complexity: LOW.** Purely additive spec + gate criteria; `git revert` of the single PR restores prior state with zero data migration. | Rollback | LOW | release-executor | Standard `git revert`. No deployed-state mutation beyond the `.claude/rules/release-process.md` mirror, which the deploy re-syncs from canonical. | CHEAP / HIGH — matches the issue's own CHEAP/HIGH self-assessment. |

---

### Recommendations

Each recommendation below is Stage-6+ chip-prompt-input-shaped (actionable), per Mode B output discipline.

1. **Approve the plan as a single-issue `cross-cutting` release; authorize Stage 5 Solutioning as the next gate.** The mechanism is deferred to Stage 5 by the issue itself — Engineering cannot start until Stage 5 lands the design + Collective Review locks scope. (Single-issue release ⇒ Collective Review's ≥2-Solutioning-issue trigger does **not** fire; per-spoke Procedure 4 handling is sufficient — confirm at Stage 5 exit. [SOURCE: `stage-05-solutioning.md` line 288])
2. **Pin and re-check the cross-release contention.** Treat R-2 as the dominant operator risk: before any concurrent scheduling, serialize #87 against the same-file sibling milestones (`stage-gate-criteria-completeness`, `release-identity-and-spec-hardening`, `hub-autonomy-conformance`, `pipeline-skill-doc-reconciliation`). Re-run the body-grep at Stage 9 (the population is live and will move).
3. **Carry R-4 (Gate-ID) and R-5 (reflexive cutover) into the Stage 5 design spec as explicit design constraints**, not Engineering surprises.
4. **Out-of-scope discoveries (note-only, per scope rule):**
   - The native **"Blocks #114"** dependency edge on #87 is rotten and should be corrected or removed by the operator (the platform's issue-body-renumber reconciliation surface owns this; not a Stage-4 action). Flagging here per the "do not silently leave a contradiction" discipline.
   - The `governance-cross-reference-currency` milestone (#114's actual home) and #121 in it are *themselves* reference-rot cleanup — orthogonal to #87 but the same root theme.

#### File Change Matrix

Machine-readable (one path per line; Stage 7/8/9 chip prompts extract this block deterministically). All six are **EDIT** (no add/delete). Paths are repo-root-relative at baseline `dfb3836`; all six verified PRESENT.

```
release/references/pipeline/stage-03-bundle.md
release/references/pipeline/stage-04-planning.md
release/references/pipeline/stage-05-solutioning.md
core/schemas/gate-criteria-spec.md
release/governance/release-process.md
release/skills/release-planner/SKILL.md
```

(Note: `.claude/rules/release-process.md` is the **deployed mirror** of `release/governance/release-process.md`; it is synced by the deploy step at Stage 12, not edited directly — it is intentionally excluded from the source-edit matrix above.)

#### Merge / Split Verdict

**Verdict: KEEP AS A SINGLE `type:story` RELEASE. Do NOT promote to epic/umbrella. Do NOT split.** Reversibility **CHEAP**, Confidence **HIGH**.

This is a decision-class call (scope-change / merge-split) and receives full decision-discipline treatment:

- **Localization Check (M1).** *Platform context:* the issue **body** repeatedly calls #87 "an umbrella" and frames #114 as its "child," but the **current canonical label set is `type:story` in its own single-issue milestone** with `epic:pipeline-definition-fitness` as the *parent epic pointer* — i.e., #87 is already correctly modeled as a story UNDER an epic, not as the epic. The platform's own discipline (`feedback_umbrellas_not_milestoned`) holds that **umbrellas must NOT sit in a milestone** — a milestone holding only an umbrella is the documented failure pattern. #87 sits in a milestone; therefore by the platform's own rule it must be treated as a *story*, not an umbrella. *Generic heuristic I'd otherwise default to:* "a body that says 'umbrella' five times is an umbrella." *What would invalidate the heuristic here:* the live label + milestone placement. *Reconciliation:* the localized signal (label `type:story` + milestone-resident + epic-pointer present) **overrides** the body's self-description. The body's "umbrella" language is **pre-re-versioning narrative** from when #114/#1151/etc. were live siblings; those numbers are now rotten (R-6), so the "umbrella over those children" framing no longer has live referents. Recommend: single story.
- **Opposing View (M2).** *Strongest case against single-issue:* "#87 touches FIVE pipeline surfaces across six files — that is epic-sized blast radius; split it into one issue per surface so each can be tested independently." *Mechanism by which single-issue could fail:* if the five surfaces had **independent mechanisms**, a single issue would bundle five unrelated designs. *Resolution — DISMISSED with evidence:* the five surfaces share **ONE mechanism** (a single durable model consulted at five consult-points). Splitting per-surface would (a) fragment one coherent design across five Stage-5 sub-tasks, (b) **manufacture the exact cross-PR same-file contention #87 exists to prevent** (five PRs all editing the overlapping spec set), and (c) force five partial models that only make sense together. The issue's AC are written as **one acceptance set across all five** ("≥1 match per stage"), confirming single-deliverable intent. The blast radius is real but is the *`cross-cutting` Release Class signal* (ceremony density), not a *split signal*.
- **Pattern Cache Scan (M3).** *Domain:* release-ops. *Confirmed patterns checked:* `issue-creation-duplicate-discipline` (enrich existing owner, don't restate milestoned scope) — **applies**: do not spin #87's surfaces into new child issues; the four uncovered surfaces are #87's own scope, not new tickets. `umbrellas-not-milestoned` — **applies** (above). `reconcile-dont-annotate` — **applies**: the rotten #114 edge should be reconciled (R-6), not annotated-and-deferred. `verify-before-recommend` — **applied**: I verified #114's true identity and the six files' presence before recommending. *Emergence candidates:* none new. *New observation to log:* none (no operator correction occurred in this spoke).

**Net:** one story, one release, one PR (internally sequenced 1→6). The cross-cutting blast radius is handled by the Release Class, not by splitting.

#### Release Class Proposal

**Proposed Class: `cross-cutting`.** Operator renders at the D-ReleaseClass gate per `release-class-taxonomy.md` Classification Procedure. [SOURCE: `release-class-taxonomy.md` § Class Enum + Classification Procedure]

**Trigger-condition evidence (three of the `cross-cutting` triggers fire independently; multi-trigger resolution → `cross-cutting` wins):**

- **Trigger (a) — File Change Matrix touches ≥3 `pipeline/stage-*.md` files:** ✅ FIRES. #87 edits `stage-03-bundle.md`, `stage-04-planning.md`, `stage-05-solutioning.md` = **3** pipeline stage files. [SOURCE: File Change Matrix above]
- **Trigger (b) — File Change Matrix touches ≥3 of {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, RELEASE_LOG.md, hub-spoke-bridge.md, gate-criteria-spec.md, release-process.md}:** ⚠️ PARTIAL — fires on **2** of that set (`gate-criteria-spec.md` + `release-process.md`). Two, not three — so (b) alone does not fire, but it reinforces the cross-cutting character.
- **Trigger (c) — ≥3 in-bundle compositional edges per Stage 4 A2 DAG:** ✅ FIRES (substantively). The internal DAG (N1→N2/N3→N4→N5, plus N6) has ≥3 compositional edges among the consult-points. The body itself self-labels `cluster: cross-cutting` and "spans Stage 3/4/5/9/12." [SOURCE: #87 labels + body § Notes]

**`novel` also has a partial claim** (trigger (b): "≥1 D-class decision in release plan" — Stage 5 WILL produce ≥1 ADR for the mechanism). Per **multi-trigger resolution** (`cross-cutting` > `novel` > `routine`), **`cross-cutting` is the dominant class.** [SOURCE: `release-class-taxonomy.md` § Multi-trigger resolution, line 106]

**`hotfix` is excluded** — no P1/P2 defect against a deployed release; this is a forward-looking protocol addition. [SOURCE: hotfix anti-pattern, line 43]

**Differentiation posture (per the milestone-description template):**

```
## Release Class

Class: cross-cutting
Rationale (max 2 sentences): File Change Matrix edits 3 pipeline/stage-*.md files
  (stage-03/04/05) AND adds a cross-stage compositional model with ≥3 internal
  consult-point edges spanning Stage 3/4/5/9/12; novel's ADR trigger also fires
  but cross-cutting dominates per multi-trigger resolution.
Differentiation posture:
  - Engagement density: Tight        (per-spoke completion → consolidated Decision
                                       Briefing; cross-D upstream-compat scan explicit
                                       at every D-decision — load-bearing here because
                                       the Stage 5 mechanism is a skill-authoring-surface
                                       decision touching release-planner/SKILL.md)
  - Stage 9 review depth: Deep        (Collective-Review N-way consistency [N/A here —
                                       single issue, no ≥2-Solutioning trigger] +
                                       cross-D upstream-compat scan + blast-radius
                                       assessment + design-spec conformance)
  - Stage 5 activation bias: ALL      (cross-cutting biases toward activating Stage 5 —
                                       and here Stage 5 is independently MANDATORY)
  - Stage 13 outcome-window: 30-day   (standard window; not a hotfix)
```

**Upstream-compatibility note (per the spoke anti-pattern "do not render D-decisions touching skill-authoring surface without verifying upstream compatibility"):** the only skill-authoring surface in scope is `release-planner/SKILL.md`. Per the D-ReleaseClass D-Gate block, **Release Class itself is PMO-internal taxonomy with no Anthropic upstream surface** — upstream-compat check does not apply to the *class* decision. The Stage-5 mechanism decision that *does* touch the skill will carry its own upstream-compat scan at its D-Gate (release-planner is a PMO skill, not an Anthropic scaffolding skill — no upstream frontmatter/structure contract is at stake; this is the expected `N/A — no upstream surface` verdict). [SOURCE: `hub-spoke-bridge.md` D-ReleaseClass block, lines 350-352]

---

#### D-decisions / open questions for the operator at the planning gate

1. **D-ReleaseClass:** confirm **`cross-cutting`** (recommended) vs override. CHEAP / HIGH.
2. **D-MergeSplit (resolved-recommendation):** confirm **single `type:story` release, no split** (recommended). CHEAP / HIGH.
3. **Open question — #114 edge:** authorize correction/removal of the rotten "Blocks #114" native edge on #87? (Out-of-Stage-4 scope to *execute*, but needs an operator call — R-6.)
4. **Open question — sibling sequencing:** is any same-file sibling milestone (`stage-gate-criteria-completeness` / `release-identity-and-spec-hardening` / `hub-autonomy-conformance`) intended to run concurrently with this one? If yes, **serialize** per R-2 before scaffolding.

---
*Stage 4 Release Planning spoke — baseline pinned at origin/main `dfb3836` (2026-06-13). Evidence labels applied per CLAUDE.md. Verification trailers: [VERIFIED 2026-06-13: `gh issue view 114` → unrelated metadata issue in governance-cross-reference-currency, #114 edge confirmed rotten]; [VERIFIED 2026-06-13: `git diff --stat 4a6b7aa origin/main -- <6 files>` → empty, no affected-file divergence between worktree HEAD and origin/main]; [VERIFIED 2026-06-13: all 6 affected paths PRESENT at baseline]; [VERIFIED 2026-06-13: `gh issue list --state all --jq length` → 812, --limit 5000 safe, no truncation].*

