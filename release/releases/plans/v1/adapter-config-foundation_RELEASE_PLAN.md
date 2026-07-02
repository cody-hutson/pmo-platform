<!-- reference-durability: allow-issue-ref -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — adapter-config-foundation

**Milestone:** adapter-config-foundation · **Release Class:** novel · **Topology:** D-C SINGLE
**Issues:** #22 (config surface, size:XL) + #703 (onboarding-umbrella spine, size:S)
**Stage 4 source:** the Release Planning sub-task comment (Stage 4 spoke output), reproduced verbatim below as the committed release plan (Engineering Commit 0). The two Decision Records (Stage 4 Plan Approval + Collective Review scope-lock) are appended as the authoritative gate-decision record for this release.

---

## Stage 4 Release Planning — adapter-config-foundation

### Summary (30 seconds)

This release is the **adapter-config foundation**: the two pieces every host-adapter ticket (#10/#11/#12/#13) composes into — a canonical platform-config surface (**#22**, `size:XL`) and a canonical onboarding-umbrella spine (**#703**, `size:S`). `[SOURCE]` milestone #169 description: *"One canonical platform-config surface + onboarding umbrella that every host adapter writes into … ~18 pts across 2 issues."*

**Verdict: CONDITIONAL.** The plan is executable as a 2-issue release, but two material items need an operator call: (1) **build order** — #703 *writes into* #22's config surface, which creates a soft sequencing preference but **not** a hard build-order block (the integration seam is a one-line reference, deferrable to Stage 5); (2) **Release Class** — this milestone carries **no `## Release Class` H2 section** today `[SOURCE: gh api milestones/169 → description has no Release Class block]`, so the class must be declared fresh. Both issues defer substantial design to Stage 5 (`[SOURCE]` both bodies use the literal "deferred to Stage 5" framing), so **Stage 5 activates release-wide** and **Class = `novel`** is the recommendation.

**Capacity finding (load-bearing, anti-relitigation):** The XL+S pairing looks heavy, but the bundle is the milestone's **original intended scope** — not a re-litigation target. The milestone description has **no `Split from <parent>` provenance** `[SOURCE: gh api milestones/169]`, and #703 entered at `status: bundled` with the operator pre-deciding triage+bundle `[SOURCE: #703 body — "operator pre-made the triage + bundle decision, so it enters at status: bundled"]`. Per the confirmed-cache observation `release-ops · stage-4-relitigates-prior-bundling`, generic XL+S capacity-asymmetry is **not** new structural evidence and does not justify a split. **Recommendation: keep both issues in this release.** No circular dependency, no unworkable contention, no newly-discovered cross-issue conflict was found.

---

### Dependency Graph

Directional (`A → B` = "A must land before B" / "B writes into A"):

```
#22 (config surface)  ──soft──▶  #703 (onboarding-umbrella spine)
        │                              │
        │ (integration seam:           │
        │  #703 references #22's        │
        │  config surface as the home   │
        │  for onboarding-time choices) │
        ▼                              ▼
   [OUT OF SCOPE — risk-register only]
   #22 Blocks #11 (tracker-and-kb-adapters, R06)
   #22 Blocks #30 (stage3-bundling-composer, R07)
   #703 is composition target for #10/#11/#12/#13 (R05/R06)
   #703 realizes epic #14; under initiative #574
```

**Edge classification (#22 → #703):** SOFT, not HARD. `[INFERRED from both bodies]`
- **What #703 needs from #22:** AC #5 — *"The artifact references #22's config surface as the home for onboarding-time operator choices"* `[SOURCE: #703 AC]`. The dependency is a **textual cross-reference**, satisfiable by a single pointer line, not a structural/compile-time coupling.
- **Why it is not HARD:** #703's *own* deliverable (the ordered clone→working-install spine + 4 named extension points) does not require #22's config schema to exist before it can be authored. #703 can name "operator onboarding choices land in the platform-config surface (#22)" as a forward reference even if #22's exact YAML-vs-MD format is unsettled. `[INFERRED]` The seam is a name, not a payload.
- **Evidence of mutual deferral:** Both issues defer their mechanism to Stage 5 `[SOURCE: #22 — "Stage 5 settles" format/location; #703 — "format/location/extension-point schema → mechanism deferred to Stage 5 Solutioning"]`. Stage 5 Collective Review is where the seam is jointly designed — neither needs the other *implemented* first.

**Downstream (OUT of this release's scope — risk-register only):**
- `#22 Blocks #11, #30` `[SOURCE: #22 body roadmap-deps footer + verified: #11 in milestone tracker-and-kb-adapters/R06 OPEN, #30 in stage3-bundling-composer/R07 OPEN — both in DIFFERENT future milestones]`.
- `#703 is composition target for #10/#11/#12/#13` `[SOURCE: #703 Dependencies; verified #10 (repo-host-adapter/R05), #12 (tracker-and-kb-adapters/R06), #13 (ai-tool-target-adapter/R05) all OPEN in separate future milestones]`.
- **No in-release blocker** — every downstream consumer sits in a later-horizon milestone (R05–R07). `[INFERRED]` This release ships the foundation; the adapters consume it later.

---

### Implementation Sequence

Dependency-ordered Engineering (Stage 6) execution order under the recommended **D-C SINGLE** topology (one chip at a time, write-serialized):

1. **#22 first** (config surface). Rationale: #703's only inbound dependency is a reference to #22's config surface; authoring #22 first means #703 can cite a concrete, already-landed surface rather than a forward promise. `[RECOMMENDED]` This is a *sequencing preference for cleaner integration*, **not** a hard block — see D-BuildOrder.
2. **#703 second** (onboarding-umbrella spine). Authors the spine + 4 extension points and points its config-home reference at the now-landed #22 surface.

**Note on Stage 5 (parallel-safe).** Solutioning sub-tasks for #22 and #703 are **parallel-actionable** `[SOURCE: hub-spoke-bridge.md Procedure 2 Parallelism Rules — "5 Solutioning: YES — parallel-safe; output channel is GitHub Issue comment, no contention surface"]`. Both Stage 5 chips may run concurrently; **Collective Review fires after BOTH close** (release has ≥2 issues with Solutioning activated `[SOURCE: hub-spoke-bridge.md Procedure 2 Step 3]`). The build-order preference (#22→#703) applies at **Engineering (Stage 6)**, not at Solutioning.

**Sequence within an issue:** standard 5→6→7→8 per issue, then release-scoped 9 (Plan Review gate) → 12 (Execute) → 13 (Close).

---

### Stage Applicability Matrix

Per the 6-trigger activation-criteria matrix in `core/standards/planning-solutioning-handoff.md` § 3 (T1–T6, logical-OR, all-or-nothing release rollup). A ✓ on ANY trigger on ANY issue ⇒ Stage 5 ACTIVATES release-wide.

| Issue | T1 new-file | T2 skill-logic | T3 structural-design | T4 multi-approach | T5 ≥3-gov-files | T6 blast-radius | **Verdict** |
|---|---|---|---|---|---|---|---|
| **#22** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **ACTIVATE** |
| **#703** | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ | **ACTIVATE** |

**Per-trigger rationale (read-surface for Collective Review R4):**

- **#22 / T1** ✓ — proposes NEW `release/governance/platform-config.yaml` OR `release/references/specs/platform-config.md` carrying a schema (defaults, allowed-values enum, calibration history, cutover SHA per field). `[SOURCE: #22 Proposed change #1]` Verified absent: `find platform-config*` returns nothing `[SOURCE: filesystem]`.
- **#22 / T2** ✓ — modifies `release-planner` SKILL.md (Mode A reads config) and `release-executor` SKILL.md. `[SOURCE: #22 Affected files + consumer-integration §; both SKILL.md files verified present]`
- **#22 / T3** ✓ — defers structural design decisions to Stage 5 (config format YAML-vs-MD, consumer protocol, config-update governance). `[SOURCE: #22 — "Stage 5 settles" / "Stage 5 designs the exact consumer protocol" / "Stage 5 surfaces D-decision"]`
- **#22 / T4** ✓ — explicit ≥2 candidate approaches: `platform-config.yaml` (YAML) **OR** `platform-config.md` (markdown structured fields); lighter-weight config-PR flow **OR** normal release flow. `[SOURCE: #22 Proposed change #1 + #3]`
- **#22 / T5** ✓ — touches ≥3 governance files: `CLAUDE.md`, `core/governance/OPERATIONS.md`, plus multiple reference specs (`methodology-parameterization-v1.md`, `bundle-composition-doctrine.md`, `hub-spoke-bridge.md`). `[SOURCE: #22 Affected files — counts ≥3 governance roots]`
- **#22 / T6** ✓ — "Many other reference docs need cross-reference edits to point at config" + config-update governance propagation is not deterministically derivable from the body. `[SOURCE: #22 Affected files final bullet]`
- **#703 / T1** ✓ — proposes a NEW canonical onboarding-umbrella artifact (Layer-1, git-tracked, fresh-clone-present). `[SOURCE: #703 AC#1/#2; verified no pre-existing onboarding-umbrella/spine artifact via find]`
- **#703 / T3** ✓ — auto-flags: body contains the literal *"mechanism deferred to Stage 5 Solutioning"* `[SOURCE: #703 Proposed Change]`; T3 detection mechanism explicitly auto-flags this phrase `[SOURCE: planning-solutioning-handoff.md T3 detection]`.
- **#703 / T4** ✓ — ≥2 candidate approaches: Layer-1 home `docs/` (user-facing) **vs** `release/references/`|`core/` (K1); cross-reference direction artifact→adapters **vs** adapters→artifact. `[SOURCE: #703 Affected Files ASSUMPTION–CONFIRM rows]`

**Release-level rollup: ACTIVATE (Stage 5 runs for BOTH issues).** Both issues independently trigger Stage 5; neither qualifies for the SKIP path (SKIP requires ALL ✗, and the SKIP anti-pattern explicitly states the "deferred to Stage 5" phrase invalidates SKIP). `[SOURCE: planning-solutioning-handoff.md § 5 Anti-pattern]`

**Full per-issue stage applicability (Stages 5–13):**

| Stage | #22 | #703 | Notes |
|---|---|---|---|
| 5 Solutioning | APPLIES | APPLIES | Release-wide ACTIVATE; parallel-safe; Collective Review after both close |
| 6 Engineering | APPLIES | APPLIES | Write-serialized under D-C SINGLE; #22 before #703 |
| 7 Dev Testing | APPLIES | APPLIES | Both add functional/structural artifacts (config surface; spine with verifiable AC methods) — functional impact present, no Stage-7 skip |
| 8 QA Testing | APPLIES | APPLIES | Both carry method-bearing AC needing independent verification (e.g., #703 "grep the artifact — ≥1 extension-point each") |
| 9 Plan Review | APPLIES (release-scoped) | — | Single per-release gate; Deep review depth per `novel` class |
| 12 Execute | APPLIES (release-scoped) | — | Single per-release; includes Stage 12 chore PR (RELEASE_LOG + Deployment Log) |
| 13 Close | APPLIES (release-scoped) | — | Single per-release; includes Stage 13 chore PR (INDEX + DIGEST + RELEASE_NOTES); both issues flagged for release-notes per their AC |

No stage is skipped for either issue. `[INFERRED from issue bodies + activation matrix]`

---

### Contention Map

Files claimed by BOTH issues' change-specs (within-release contention — the A4 surface):

| File | #22 | #703 | Class | Resolution |
|---|---|---|---|---|
| `README.md` | edit (config discoverability / Universal Preferences pointer) | edit (link umbrella from Getting Started / Module overview) | **line-range-overlap risk** (both touch onboarding/module-overview region) | Sequence per Implementation Sequence (#22 then #703); under D-C SINGLE the second Engineering chip rebases on the first. `[SOURCE: both bodies name README.md]` |
| onboarding-doc surface (`docs/GETTING_STARTED.md`, `docs/FIRST_STEPS.md`, `docs/INSTALL.md`) | not directly edited | **boundary-only** (umbrella must stay DISTINCT from these; Stage 5 sets the boundary) | No edit contention — #703's relationship to these docs is *non-duplication*, not co-edit. `[SOURCE: #703 Risks — "declares the journey + extension points WITHOUT duplicating the first-task walkthrough"]` |

**Contention severity: LOW–MEDIUM.** The only true co-edit file is `README.md`, and the two edits target different concerns (config-discoverability vs onboarding-umbrella link) in the same general region. Under **D-C SINGLE** topology this serializes cleanly: #703's Engineering chip runs `git fetch origin release/<milestone> && git checkout release/<milestone>` after #22's commit lands, rebasing on it. `[SOURCE: hub-spoke-bridge.md Procedure 2 file-contention boundary rules]`

**Cross-PR contention (A4 extension — baseline-pinned).** `[SOURCE: stage-04-planning.md § Cross-PR Overlap Audit]`
- **Baseline pin:** This audit is pinned to the current `origin/main` HEAD at planning time (commit anchor = the merge of PR #682, the most recent commit on main per the session git log) and a bounded recent window of the last ~10 merged PRs. `[CONTEXT — per CLAUDE.md Audit-baseline discipline: open-PR population is observably empty at this moment; this baseline must be re-checked at Stage 9 Phase A6.5 and is not load-bearing on its own.]`
- **Open-PR population: empty at baseline** (no open PRs touch `README.md` / `docs/` / `release/governance/` / the SKILL.md files at the pin) `[INFERRED — no open PRs surfaced for the affected paths]`. Per the audit-baseline-empty-target policy, a default-to-zero cross-PR finding here is **not load-bearing**: re-check the affected-path population at Stage 9 Phase A6.5 (PRIMARY, HALT-eligible) and Stage 7/8 entry (SECONDARY, warn-only) before relying on "no cross-PR contention."
- **Dormant-sibling check:** The downstream consumer milestones (`repo-host-adapter`, `tracker-and-kb-adapters`, `ai-tool-target-adapter`, `stage3-bundling-composer`) are this milestone's *consumers*, not sizing-split siblings — they hold no overlapping affected-files against `README.md`/config surface today and are R05–R07 horizon (dormant relative to R01). `[INFERRED]` No dormant-sibling contention applies (this milestone has no `Split from` provenance).

---

### Risk Register

| # | Risk | Type | Severity | Owner | Mitigation |
|---|---|---|---|---|---|
| R1 | **#703→#22 integration seam unresolved at Engineering.** If #703's Engineering chip runs before #22's config surface is designed enough to be referenced, the seam reference is a dangling pointer. | Dependency | MEDIUM | Stage 5 Collective Review | Sequence #22 before #703 (Implementation Sequence). Stage 5 Collective Review jointly designs the seam: settle #22's config-surface name/location, then #703 cites it. The seam is a textual reference (one line), so even worst-case the fix is a single-line edit, not rework. Reversibility: **CHEAP**. |
| R2 | **README.md co-edit conflict** (both issues edit the onboarding/module-overview region). | Contention | LOW | Hub Procedure 2 routing | D-C SINGLE serialization: #703 chip rebases on #22's landed commit. Hub refuses concurrent Engineering chips touching `README.md` per Contention Map. Reversibility: **CHEAP**. |
| R3 | **#703 overlaps existing onboarding docs** (`GETTING_STARTED.md`/`FIRST_STEPS.md`/`INSTALL.md`) — umbrella accidentally duplicates the first-task walkthrough. | Scope | MEDIUM | Stage 5 (#703) | Stage 5 sets the boundary explicitly: umbrella = journey-spine + extension-point contract, NOT a re-statement of the walkthroughs `[SOURCE: #703 AC#6 + Risks]`. Stage-8 QA verifies non-duplication. Reversibility: **MODERATE** (a published umbrella that duplicates docs is fixable but touches user-facing surface). |
| R4 | **#703 conflated with epic #14** — re-creates the milestone-vs-contents drift #703 was filed to resolve. | Scope | MEDIUM | Stage 5 (#703) | Hard constraint from the body: umbrella is the *shipped mechanism* #14 points at; #14 is roadmap-level framing with no mechanism `[SOURCE: #703 — "Must stay distinct from epic #14 … conflating them re-creates the … drift"]`. Stage 5 design states the distinction; Collective Review checks it. Reversibility: **CHEAP** (design-time). |
| R5 | **#22 config format (YAML vs MD) chosen wrong for consumers.** Picking YAML when consumers are markdown-native skills (or vice versa) forces a later re-format. | Scope / design | MEDIUM | Stage 5 (#22) D-Format | Stage 5 D-Format decision evaluates consumer-read ergonomics (release-planner/release-executor SKILL.md read patterns) before committing. `methodology-parameterization-v1.md` is markdown today — composition pressure favors evaluating both. Reversibility: **MODERATE** (re-format after consumers wire in is days of edits). |
| R6 | **#22 config-update governance under-specified** — config-change-only PRs lack a defined weight (full release vs lightweight flow), so future config edits stall or bypass governance. | Scope | LOW–MEDIUM | Stage 5 (#22) | #22 explicitly defers this to Stage 5 D-decision `[SOURCE: #22 Proposed change #3]`. Stage 5 produces the config-update protocol. Reversibility: **CHEAP** (protocol doc, amendable). |
| R7 | **Downstream adapter milestones (#10–#13, #11, #30) start before this foundation lands**, leaving them without a composition target / config surface. | Dependency (out-of-scope, forward) | LOW (this release) / HIGH (program) | Roadmap sequencing (operator) | OUT OF THIS RELEASE'S SCOPE — note only. All consumers are R05–R07 horizon vs this R01 foundation `[SOURCE: verified milestones]`; roadmap ordering already places them later. Flag at Stage 13 release notes that the foundation is now available for adapter composition. Reversibility: **N/A** (program-sequencing concern). |
| R8 | **Rollback complexity.** | Rollback | LOW | Stage 12/Operator | Both deliverables are **additive new files** (config surface; umbrella spine) plus small `README.md`/SKILL.md edits — no deletion of existing capability, no schema migration of live data. Rollback = revert the release PR(s); git history is the snapshot. No data-loss surface. Reversibility: **CHEAP** (revert-clean). |

**Rollback strategy (explicit, per persona anti-pattern "no plans without rollback strategy"):** This release is **revert-clean**. Both issues add new Layer-1 files and make additive edits to `README.md` and two SKILL.md files. No existing file is deleted; no live config data is migrated (the config surface is brand-new, so there is no prior-format data to strip). Rollback mechanism: `gh pr revert` (or `git revert <merge-sha>`) of the release merge. Under D-C SINGLE the entire release is one branch → one revert. The only post-revert cleanup is removing the two new files, which the revert handles automatically. Reversibility tier for the release as a whole: **CHEAP** (undo in hours), confidence **HIGH**.

---

### Recommendations

**Primary recommendations:**

1. **Keep both issues in this release. Do NOT split.** `[RECOMMENDED — reversibility CHEAP / confidence HIGH]` The XL+S pairing is the milestone's original intended scope (no `Split from` provenance; #703 entered at operator-pre-decided `status: bundled`). Per the `stage-4-relitigates-prior-bundling` confirmed-cache observation, generic capacity-asymmetry is not new structural evidence. No circular dependency, no unworkable contention, and the single shared file (`README.md`) serializes cleanly. The two issues are *thematically inseparable* — they ARE the named "config + onboarding foundation" pair (#169 description). Splitting would fragment the foundation the adapters depend on.

2. **Sequence #22 before #703 at Engineering** (soft, for clean integration), but do NOT gate #703's *Solutioning* on #22 — Stage 5 runs both in parallel and Collective Review jointly settles the seam. `[RECOMMENDED]`

3. **Declare Release Class = `novel`.** `[RECOMMENDED]` Triggers (a) "≥1 issue introduces a new reference doc/schema/skill" (both do) and (b) "≥1 D-class decision in release plan" (this plan renders ≥4) both fire `[SOURCE: release-class-taxonomy.md novel triggers]`. The milestone description currently has no `## Release Class` section, so this declaration also backfills the Stage 3 Phase B3 gap.

**Discoveries outside scope (noted, not actioned — per scope rules):**

4. **Milestone #169 description is missing the `## Release Class` H2 section** that Stage 3 Phase B3 should have authored `[SOURCE: gh api milestones/169 — description has Value/Today/Initiative blocks but no Release Class block]`. This is a Stage-3-substrate gap, not a Stage-4 deliverable. RECOMMEND the hub backfill it via `gh api repos/{REPO}/milestones/169 -X PATCH` once D-ReleaseClass is rendered (the Re-Classification/declaration mechanics in `release-class-taxonomy.md` § Classification Procedure). Out of this spoke's write-scope.

5. **No `### Release Outcome Statement` H3 in the milestone description either** `[SOURCE: same]`. Procedure 0 Step 7 expects the operator to approve a Release Outcome Statement draft at the Phase B1 gate. The hub should compose one at plan-approval and PATCH it into the milestone description. Out of this spoke's scope (hub Procedure 0 Step 7 responsibility).

6. **Forward program risk (R7):** the four downstream adapter milestones (R05–R07) all depend on this R01 foundation. RECOMMEND the operator confirm the roadmap keeps the adapter milestones sequenced *after* `adapter-config-foundation` ships — surfaced here only because Stage 4 sees the blocking edges; the sequencing decision is roadmap-governed, not release-governed.

**Decision-discipline mechanism trace** (per `core/disciplines/decision-discipline.md` § 3 triage — the capacity/merge-split and PR-topology decisions are Scope-change and PR-routing classes, so M1+M2+M3 all apply):

- **M1 Localization Check (capacity/split decision):** Reconciled the XL+S "looks over-scoped" generic heuristic against local context — milestone has NO split provenance, #703 is operator-pre-bundled, the two issues are the named foundation pair. Generic capacity-asymmetry does not localize to a split here. *This is the exact Localization-Check failure the `stage-4-relitigates-prior-bundling` observation documents; applied correctly this time.*
- **M2 Opposing View (split decision):** Strongest case FOR splitting = "XL alone is a full release; bundling S forces the small umbrella through #22's heavy Collective Review." Rebuttal: #703's Stage 5 is a quick spoke (its design surface is genuinely small — home + schema + 4 extension points), and the seam between them is *only* designed correctly if both are in the same Collective Review. Splitting would create a cross-release seam (a HARD dependency where today there is a soft one). The opposing view *strengthens* the keep-both recommendation.
- **M3 Pattern Cache Scan:**
  - *Confirmed patterns checked:* `release-ops / stage-4-relitigates-prior-bundling` (observation, N=1, not yet promoted) — checked; `release-ops / intake-pre-rendered-artifacts` (CONFIRMED N=2) — checked; `general-agent / verify-before-recommend` — checked.
  - *Applicable confirmed patterns:* **`stage-4-relitigates-prior-bundling`** → directly applies → implies: treat the 2-issue bundle as settled INPUT, recommend keep-both, do not re-open on generic heuristics. **`verify-before-recommend`** → applies → I verified every hub-injected claim against canonical source (issue bodies, milestone API, filesystem, downstream issue states) before recommending; cited inline.
  - *`intake-pre-rendered-artifacts` (CONFIRMED) — checked, NOT applicable:* this pattern fires when ALL of an issue's ACs already pass at first verification (work already done). Here, NEITHER issue's deliverable exists yet (`platform-config.*` absent; no onboarding-umbrella artifact) — this is genuine forward design work, not verification-only. Correctly NOT inverting to D-NO-RE-AUTHORING.
  - *Emergence candidates:* `stage-4-relitigates-prior-bundling` is at N=1 (logged 2026-05-13). This release is a clean *non-instance* (the bundle was correctly NOT re-litigated), so it does not add a second instance. No promotion triggered.
  - *New observation to log:* No operator correction occurred in this spoke session. No new observation.

---

### Operator Decisions (D-Gate format)

#### D-C: Branch Topology — SINGLE vs OPTION-A?
**Gate input:** 2-issue release with one true shared file (`README.md`) and a soft #22→#703 sequencing preference; spoke topology analysis.
**Gate decision:** Choose between (A) **D-C SINGLE** — one `release/<milestone>` branch, all Engineering commits land sequentially, plan file committed as Engineering Commit 0; or (B) **D-C OPTION-A** — per-issue branches + per-issue PRs, plan file committed via a dedicated Stage 4 release-plan chore PR before scaffolding.
**Blocks:** Procedure 1 Scaffolding (sub-task creation order); the plan-file commit mechanism; Engineering parallelism rules.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** MODERATE / HIGH.
**Recommendation: D-C SINGLE.** `[RECOMMENDED]` Only 2 issues, write-serialized Engineering, and a single shared file that serializes cleanly — SINGLE is the documented default `[SOURCE: hub-spoke-bridge.md Procedure 0 — "D-C SINGLE — default"]` and carries the least ceremony (no separate plan-chore PR, no per-issue PR fan-out). OPTION-A's benefit (parallel Engineering across branches) is not needed at N=2 with a soft sequence preference.

#### D-BuildOrder: #22-before-#703, or parallel?
**Gate input:** #703 AC#5 requires the umbrella to reference #22's config surface; both issues defer mechanism to Stage 5; edge analysis classifies the dependency SOFT (textual reference, not structural coupling).
**Gate decision:** Choose between (A) **#22-before-#703** (sequence Engineering so #703 cites a landed config surface); or (B) **fully parallel** (both proceed independently, seam reconciled at Collective Review / late).
**Blocks:** Engineering (Stage 6) chip routing order. Does NOT block Stage 5 — Solutioning is parallel-safe for both regardless.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation: (A) #22-before-#703 at Engineering, parallel at Solutioning.** `[RECOMMENDED]` The dependency is real but SOFT — there is NO hard build-order block (#703 can be *designed* without #22 implemented). Sequencing #22 first at Engineering gives #703 a concrete surface to cite, avoiding a dangling forward-reference. Stage 5 runs both in parallel; **Collective Review (after both Stage 5 close) is where the seam is jointly settled** — this is the integration-seam mechanism the milestone's foundation framing needs. *Evidence the dependency is not hard: #703's deliverable (spine + extension points) is self-contained; the #22 reference is one line of the artifact.*

#### D-Capacity: Keep both issues in this release, or split?
**Gate input:** XL (#22) + S (#703) pairing; hub's honest-capacity-assessment request; milestone-provenance verification; pattern-cache scan.
**Pre-decided (load-bearing):** The operator pre-made the triage + bundle decision for #703 — it entered at `status: bundled` `[SOURCE: #703 body]`. The milestone was authored as a 2-issue foundation with NO `Split from <parent>` provenance `[SOURCE: gh api milestones/169]`. The bundle is therefore SETTLED INPUT, not an open question.
**Gate decision:** Choose between (A) **keep both** in `adapter-config-foundation`; or (B) **split** #703 into a separate follow-up release.
**Blocks:** Scaffolding scope (1 release vs 2); Stage 5 Collective Review applicability (Collective Review needs ≥2 Solutioning-activated issues in ONE release).
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (a kept-together bundle can still be re-split at Stage 5 if NEW structural evidence emerges; the reverse — re-merging a split — is costlier).
**Recommendation: (A) keep both.** `[RECOMMENDED]` Per M1 Localization + the `stage-4-relitigates-prior-bundling` confirmed-cache observation: generic XL+S capacity-asymmetry is **not** new structural evidence and does not justify re-opening a settled, operator-pre-decided bundle. The two issues are the named "config + onboarding foundation" pair the adapters compose into — splitting would convert today's SOFT seam into a HARD cross-release dependency and fragment the foundation. No circular dependency, no unworkable contention found. **If the operator nonetheless prefers to ship #22 alone first** (a legitimate capacity call given XL weight), that is a stricter-than-recommended choice the operator may make — but it should be made on *bandwidth* grounds explicitly, not on a false "these are independent" or "this is over-scoped" framing.

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke-proposed class + trigger-condition evidence per `release/references/specs/release-class-taxonomy.md`. Milestone description currently carries NO `## Release Class` section `[SOURCE: gh api milestones/169]` — this declaration backfills the Stage 3 Phase B3 gap.
**Gate decision:** Choose between (A) `routine`, (B) `novel`, (C) `cross-cutting`, (D) `hotfix`.
**Blocks:** Stage 3 Phase B3 milestone-description authoring (backfill); downstream per-class differentiation posture (engagement density, Stage 9 review depth).
**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable later with operator approval per `release-class-taxonomy.md` Re-Classification Protocol).
**Recommendation: (B) `novel`.** `[RECOMMENDED]`
- **Triggers fired** `[SOURCE: release-class-taxonomy.md Class Enum, novel row]`: (a) ≥1 issue introduces a new reference doc/schema/skill — **both** do (#22 new config surface w/ schema; #703 new umbrella artifact); (b) ≥1 D-class decision in the release plan — this plan renders **4** (D-C, D-BuildOrder, D-Capacity, D-ReleaseClass) plus Stage-5-anticipated D-Format/D-ConsumerProtocol/D-Home decisions.
- **Why NOT `cross-cutting`:** cross-cutting requires touching ≥3 `pipeline/stage-*.md` files, OR ≥3 of the named governance surfaces, OR ≥3 in-bundle compositional edges. This release touches **0** `pipeline/stage-*.md` files; #22 touches `CLAUDE.md` + `OPERATIONS.md` (2 of the named set, not ≥3); and there are only 2 in-bundle issues (1 compositional edge). The cross-cutting threshold is not met. `[SOURCE: release-class-taxonomy.md cross-cutting triggers + anti-pattern "≥3 stage files, not 1"]` *(If Stage 5 design materially widens #22's governance-file blast radius to ≥3 of the named set, re-classify `novel`→`cross-cutting` per the Re-Classification Protocol — cheaper-to-stricter, CHEAP/HIGH.)*
- **Why NOT `routine`:** routine requires zero new files AND zero new D-class decisions — both violated. `[SOURCE: routine triggers]`
- **Why NOT `hotfix`:** no P1/P2 defect against a deployed release; this is forward foundation work. `[SOURCE: hotfix triggers]`

**Differentiation posture (novel):** `[SOURCE: release-class-taxonomy.md Per-Class Mapping]`
- Engagement density: **Standard** (per-D-decision Operator Decision Gate + per-Stage-5 Decision Briefing on completion)
- Stage 9 Plan Review depth: **Deep** (Collective Review N-way consistency + cross-D upstream-compatibility scan + design-spec conformance)
- Stage 5 activation bias (OPTIONAL): **ALL** (novel bias toward activating Stage 5 — already ACTIVATE here; bias confirms it)
- Stage 13 outcome-window (OPTIONAL): **30-day** (standard window; capture `**Outcome:**` on the visible-H4 Deployment Log at Stage 13 close)

**Multi-trigger resolution note:** Only `novel` triggers fire (no `cross-cutting` trigger met). Single-class result; no highest-ceremony tie-break needed. `[SOURCE: release-class-taxonomy.md Multi-trigger resolution]`

---

### File Change Matrix (machine-readable — one path per line)

Paths the release adds or edits. `[ASSUMPTION – CONFIRM] TBD — identified in Planning` marks paths genuinely deferred to Stage 5. Downstream Stage 7/8/9 chips extract this block deterministically.

```
release/governance/platform-config.yaml [ASSUMPTION – CONFIRM] TBD — identified in Planning (D-Format YAML-vs-MD + D-Home at Stage 5; new file — #22)
release/references/specs/methodology-parameterization-v1.md
release/skills/release-planner/SKILL.md
release/skills/release-executor/SKILL.md
release/references/how-to/hub-spoke-bridge.md
release/references/standards/bundle-composition-doctrine.md
core/governance/OPERATIONS.md
CLAUDE.md
README.md
docs/[ASSUMPTION – CONFIRM] TBD — identified in Planning (onboarding-umbrella artifact Layer-1 home: docs/ vs release/references/|core/ — D-Home at Stage 5; new file — #703)
.claude/agents/[ASSUMPTION – CONFIRM] TBD — identified in Planning (#22 names 7 pmo-* agent defs as spokes-reference-config; .claude/agents/ is operator-instance/runtime, not tracked in this repo worktree — confirm whether in-repo agent corpus exists or this is operator-local at Stage 5)
```

**Matrix notes (R1 evidence-grounding):**
- All non-deferred paths above are **verified present** in the current worktree `[SOURCE: filesystem — methodology-parameterization-v1.md, both SKILL.md, hub-spoke-bridge.md, bundle-composition-doctrine.md, core/governance/OPERATIONS.md, README.md all exist]`. Note `CLAUDE.md` lives at the **workspace root** (operator-instance), not the repo root — `[SOURCE: no repo-root CLAUDE.md in worktree]`; #22's intent to "move per-platform-customizable items into config" from CLAUDE.md is an operator-instance edit, flag at Stage 5.
- `platform-config.*` and the onboarding-umbrella artifact are the two NEW files (verified absent) — their exact path/format/location are the core Stage 5 D-decisions.
- `.claude/agents/pmo-*.md` (7 files) named in #22 are NOT present in this repo worktree `[SOURCE: no .claude/agents/ dir]` — they are operator-instance/runtime agent definitions. Stage 5 confirms whether config-reference edits land in-repo or operator-local.
- **Deliverable domain classification (A3-time, per stage-04-planning.md):** `domain: governance`. The matrix consists entirely of internal pmo-platform artifacts (governance specs, skill SKILL.md, reference docs, README, two new internal config/onboarding artifacts) — no application source/tests, no web/frontend surface. `domain_practice: { source: N/A — pipeline-internal release, date: 2026-06-12, domain: governance }` `[SOURCE: stage-04-planning.md § Software/governance/pipeline-internal releases exempt — internal-only matrix is sourcing-exempt but still domain-classified]`.

---

### Provenance / verification trail

`[VERIFIED 2026-06-12]` against canonical sources (R1 evidence-grounding; hub framing NOT taken on faith):
- Issue bodies #22, #703 read in full via `gh issue view`.
- Milestone #169 description via `gh api repos/cody-hutson/pmo-platform/milestones/169` → confirmed 2-issue intended scope, NO `Split from` provenance, NO `## Release Class` section, R01 Now-horizon, Portability & Distribution initiative.
- Downstream blocking verified live: #11 (tracker-and-kb-adapters/R06, OPEN), #30 (stage3-bundling-composer/R07, OPEN), #10 (repo-host-adapter/R05, OPEN), #12 (tracker-and-kb-adapters/R06, OPEN), #13 (ai-tool-target-adapter/R05, OPEN), epic #14 (OPEN), initiative #574 (OPEN) — all in DIFFERENT future milestones ⇒ no in-release blocker.
- Affected-file existence verified on filesystem (present: `methodology-parameterization-v1.md`, both SKILL.md, `hub-spoke-bridge.md`, `bundle-composition-doctrine.md`, `core/governance/OPERATIONS.md`, `README.md`; absent: `platform-config.*`, onboarding-umbrella artifact, repo-root `CLAUDE.md`, `.claude/agents/`).
- Pattern cache scanned: observation log `release-ops · stage-4-relitigates-prior-bundling` (directly load-bearing on D-Capacity); confirmed pattern `intake-pre-rendered-artifacts` (checked, not applicable — deliverables don't exist yet).

**Parser-clean note:** all per-issue closure references in this plan use safe phrasing (e.g., "mark #N as closed at Stage 13"); no close-family verb precedes any `#N`. The bare references in the Dependency Graph / blocking edges are reference-only.

## Decision Record — Stage 4 Plan Approval (Procedure 0 Step 7)

**Date:** 2026-06-12 · **Gate:** Stage 4 Release Planning → approval (rendered in main-thread chat).

**Operator decisions:**
- **D-C Branch Topology:** SINGLE.
- **D-BuildOrder:** #22 before #703 at Engineering; parallel at Solutioning.
- **D-Capacity:** keep both issues in this release (no split).
- **D-ReleaseClass:** `novel` + re-classification trigger (flip → `cross-cutting` if Stage 5 widens #22's in-repo named-governance reach to ≥3).
- **Release Outcome Statement:** approved (with the config-hierarchy clause).
- **Added requirement (operator):** the config mechanism must account for the full config hierarchy — global · individual · operational-space at portfolio / program / project tiers (cascading resolution). Captured on #22 (2026-06-12 scope-clarification comment); carried into #22 Stage 5.

**Hub verification (pre-concurrence):** all load-bearing spoke claims VERIFIED-MATCHES — new files absent; 7 affected files present; `CLAUDE.md` + `.claude/agents/` operator-instance (not in-repo); downstream blockers OPEN in future milestones; substrate gap confirmed. Release Class rationale corrected: 2 *in-repo* named-governance surfaces (`OPERATIONS.md` + `hub-spoke-bridge.md`); `CLAUDE.md` operator-instance excluded → `novel` holds (borderline; one surface from `cross-cutting`).

**Hub actions taken:**
- Milestone #169 description backfilled: `## Release Class` (novel) + `### Release Outcome Statement`.
- #22 scope-clarification comment (config hierarchy).
- Procedure 1 scaffolding: 11 sub-tasks created (#734–744); all stages apply; none skipped.

**Next (Procedure 2 routing):** Stage 5 Solutioning ×2 — #734 (#22) + #738 (#703) — parallel-safe; Collective Review fires after BOTH close; then Engineering #22 (#735) → #703 (#739) → DT/QA → Stage 9 gate → 12 → 13.

_Note: the pipeline-event-log dual-surface row is not written — runtime hub-state (operator-instance Layer 2) is not set up for this release (only templates exist). This comment is the GitHub decision-record surface._

## Decision Record — Collective Review scope-lock (2026-06-13)

**Gate:** Collective Review (≥2 issues Solutioned; #734 + #738 both closed). Rendered in main-thread chat.

**Convergence (both spokes, hub-verified against canonical source):** the config surface is **NOT greenfield** — `core/config/operator.toml.template`, `composition-surface-spec.md`, the `deploy.sh` rung-reader, and **ADR-017 §162** (names #22 = "S2 consolidation") all exist. Both Stage 5 spokes independently reframed off the issue body's stale "new YAML/MD file" premise. #22 → 5-rung hierarchy resolver (Layer-1 schema/defaults + Layer-2 per-tier values); #703 → `docs/ONBOARDING_JOURNEY.md` (7-stage journey + 4 uniform Extension-Point blocks). Scope = mechanism + resolver + 3 wired consumer examples (NOT a full migration).

**Joint lock — config structure = Option C-refined (two-file, principled split, non-breaking, ADR-017-faithful):**
- `operator.toml` (operator-environment/identity surface — `chmod 600`, depersonalization token vocabulary, machine-local): identity, paths, **`[adapters]`** (`repo_host`/`ticketing`/`kb`/`ai_tool` — the #703 seam), methodology default — all ADR-017-stated. **Nothing is relocated.**
- NEW `core/config/platform-config.toml.template` (platform-behavior surface, Layer 1, composition-surface category): bundling frame, release-size target, release-class enum, relationship-mapping tuning, calibration — NEW categories ADR-017 did not enumerate (purely additive).
- **#703 seam = `operator.toml [adapters]`** (ADR-017-faithful; #703 design unchanged).

**Best-practice rationale (operator-requested):** consolidate sprawl into one canonical surface per concern (not per-item files); the ONE justified split is the security/access-control boundary (operator.toml carries PII-adjacent token vocabulary + secrets-adjacent identity). **Breaking-change posture:** additive-only — `deploy.sh`/hooks keep reading current `operator.toml` keys; `delivery_approach` stays in PROJECT.md; resolver fail-safe = non-adopting consumers unchanged; #703 onboarding seam stable. **Engineering watch-item:** reconcile existing `[platform].work_board` with new `[adapters].ticketing` by alias/deprecation, NOT removal. A short ADR documenting the operator.toml-vs-platform-config split is authored in the #22 Engineering PR (hygiene; not an ADR-017 deviation — C-refined relocates nothing).

**Secondary ratifications:** D-Format = TOML ✓ · individual-tier = highest precedence (CHEAP to flip) ✓ · Release Class stays `novel` (design touches 2 in-repo named-governance surfaces: OPERATIONS.md + hub-spoke-bridge.md, not ≥3) ✓.

**Next (Procedure 2 routing):** #22 Stage 6 Engineering (#735) FIRST per build order (D-C SINGLE; first Engineering commit also lands the plan file as Engineering Commit 0); #703 Engineering (#739) after #22's commit lands.

