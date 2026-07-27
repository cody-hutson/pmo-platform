<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — release-hub-response-convention-enforcement

> **Milestone:** `release-hub-response-convention-enforcement` (#294) · **Parent epic:** #4019 (agent-response governance) · **Release Class:** `novel` · **Version:** `{{RELEASE_VERSION}}` (pre-claim — binds atomically at the Stage-12 claim per ADR-092) · **Scope:** 2 issues (#4020 `size:S`, #4021 `size:M`) · One release branch, one PR, one merge gate.

This plan is the Stage-4 release plan (ratified at the Procedure-0 D-Gate on #4049, 2026-07-26) with the hub's three R1 corrections applied (C1 as amended, C2, C3), reconciled with both Stage-5 Solutioning outputs (#4120 for #4020, #4121 for #4021) and carrying the operator-adjudicated premise correction **D-0**.

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` |
| **Date Created** | 2026-07-27 (Monday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing |
| **Branch** | `release/release-hub-response-convention-enforcement` |
| **PR** | (populated at Stage 6 PR creation) |
| **Milestone** | `release-hub-response-convention-enforcement` |
| **Release Class** | `novel` — Standard engagement density · **Deep** Stage 9 review · Stage 5 activation bias ALL · 30-day Stage-13 outcome window |
| **Release-identity mode** | `versioned` · bump-class **minor** |
| **Base commit** | `36c80813` (`origin/main` at branch creation) |

## Summary (30 seconds)

Two audit-derived **conformance** bugs against the `release-hub` skill runtime, both editing **the same two files**. There is no functional dependency between them, but there is a real **authoring-order** edge: #4020 rewrites the Output Contract scope clause that #4021's new requirement attaches to. Single branch, single PR, strict serial authoring **#4020 → #4021**.

- **#4020** — decision-class emissions omit the mandated reversibility tier + confidence label (41/75 = 54.7% conformance). The Output Contract binds the obligation to **Mode R only**; the fix widens the scope clause to bind both modes and supplies an emission-time predicate for what counts as decision-class.
- **#4021** — the render-before-`AskUserQuestion` briefing gate and the `Stage · gate · progress` anchor (89/117 = 76.1% conformance). The fix hardens gate 3 with a self-gate, names **declared deferral** as the legitimate consolidated-briefing form, reconciles `decision-briefing.md`'s declared mode scope, and adds a net-new anchor requirement (requirement 7) plus its matching Domain-Specific Failure Mode entry.
- **Reflexive posture:** this release edits the skill orchestrating it. It is **introducing-release-exempt** from its own new emission rules (see § Reflexive-Release Declaration).

## Scope

### Issues Included

| # | Issue | Title | Size | Category | Labels |
|---|-------|-------|------|----------|--------|
| 1 | #4020 | release-hub omits the mandated reversibility tier + confidence label on decision-class turns | `size:S` | conformance defect | `type:bug`, `project:pipeline`, `size:S`, `status: bundled` |
| 2 | #4021 | release-hub skips the render-before-AskUserQuestion briefing gate and drops the Stage·gate anchor on interrupt turns | `size:M` | conformance defect | `type:bug`, `project:pipeline`, `size:M`, `status: bundled` |

### Dependency Graph

Directional. **No hard functional dependency exists.** The single edge is a **soft authoring-order** edge derived from shared-file structure.

```
#4020 (size:S — reversibility label at the emission boundary)
   │
   │  SOFT EDGE (authoring order, not functional blocking)
   │  reason: #4020 rewrites the Output Contract SCOPE CLAUSE
   │  (SKILL.md:121) that #4021's new requirement 7 attaches to.
   │  Reverse order ⇒ #4021 authors into a Mode-R-scoped frame
   │  that #4020 then rewrites ⇒ guaranteed rework on the same lines.
   ▼
#4021 (size:M — briefing-render gate + Stage·gate anchor legibility)
```

#### Topologically Sorted Sequence

| Position | Issue | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|
| 1 | #4020 | bundled | (none — root) | — |
| 2 | #4021 | bundled | #4020 (soft, authoring-order) | DEPENDS_ON |

#### Artifact Relationship Graph

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #4021 | DEPENDS_ON | #4020 | #4021 → #4020 | Stage-4 authoring-order edge (soft; no native `blocked-by`) |
| release | GENERATES | `release/releases/plans/release-hub-response-convention-enforcement_RELEASE_PLAN.md` | release → file | File Change Matrix (Create) |

- **Hard dependencies:** none. Neither issue blocks the other's functional correctness.
- **Cross-milestone leaks:** none. Both issues are milestone-scoped; the epic siblings (#4022 spike, #4023 blocked story) are epic-scoped, not milestone-scoped, and are excluded.
- **Cycles:** none.
- **In-bundle compositional edges:** 1 — below the `cross-cutting` trigger (c) threshold of ≥3.

### File Change Matrix

Release-PR edit set — one path per line for deterministic downstream extraction:

```
release/skills/release-hub/SKILL.md
release/skills/release-hub/references/decision-briefing.md
packages/release-hub.skill
packages/release-hub.skill.sha256
release/releases/plans/release-hub-response-convention-enforcement_RELEASE_PLAN.md
```

| File Path | Issues | Change Type | Risk |
|-----------|--------|-------------|------|
| `release/skills/release-hub/SKILL.md` | #4020, #4021 | Modify | Low |
| `release/skills/release-hub/references/decision-briefing.md` | #4020, #4021 | Modify | Low |
| `packages/release-hub.skill` | both | Modify (rebuild) | Low |
| `packages/release-hub.skill.sha256` | both | Modify (rebuild) | Low |
| `release/releases/plans/release-hub-response-convention-enforcement_RELEASE_PLAN.md` | release | Create | Low |

**Per-path intent:**

| Path | Intent | Issue |
|---|---|---|
| `release/skills/release-hub/SKILL.md` | **edit** — Output Contract scope widening + requirement-5 retarget + decision-class predicate paragraph + `## Reversibility Discipline` artifact-inventory reconciliation + Guardrail alignment (#4020); requirement-count cascade + net-new requirement 7 + Mode R engagement-contract pointer + new Domain-Specific Failure Mode entry (#4021); `version:` frontmatter bump | both |
| `release/skills/release-hub/references/decision-briefing.md` | **edit** — reversibility + confidence field in the item-1 decision shape (#4020); H1 + intro mode-scope reconciliation and gate-3 self-gate / declared-deferral hardening (#4021) | both |
| `packages/release-hub.skill` | **edit (rebuild)** — regenerate from source | both |
| `packages/release-hub.skill.sha256` | **edit (rebuild)** — content-hash sidecar | both |
| `release/releases/plans/release-hub-response-convention-enforcement_RELEASE_PLAN.md` | **add** — Engineering Commit 0 (this file) | release |

**Mover-set is EMPTY.** Zero renames, zero relocations, zero deletions in the release PR; every source change is an in-place edit. `SURFACE(R)` is therefore empty and no Tier-S serialization edge exists, except the version-slot virtual-path token (see R12).

**Out of the release PR** (Stage 12/13 chore PRs — the release PR ships content only): `release/releases/RELEASE_LOG.md` DEPLOYED row + visible-H4 Deployment Log (Stage 12 Phase B5); `RELEASE_INDEX` + `RELEASE_DIGEST` + `release/releases/notes/{{RELEASE_VERSION}}_RELEASE_NOTES.md` + the RELEASE_LOG VERIFIED transition (Stage 13); the signed version tag + published GitHub Release.

**Deliverable-domain classification:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-07-26, domain: governance }`. The entire matrix consists of internal pmo-platform artifacts (a skill definition, its reference doc, its compiled package, this plan) — sourcing-exempt but domain-classified. Secondary domain `software` (the compiled `.skill` package + builder-script surface). Carried forward **unchanged** from Stage 4 through both Stage-5 spokes; no Mode-B→Mode-A upgrade is possible or appropriate, because the design depends on internal platform conventions rather than external domain practice.

### File Contention Map

**Total overlap — both issues edit both source files.** This is the dominant planning input and the reason for single-branch serial authoring.

| File | Issues | Intent Mix | Severity | Recommendation |
|---|---|---|---|---|
| `release/skills/release-hub/SKILL.md` | #4020, #4021 | edit×2 | **BINARY** | Sequence #4020 → #4021. #4020 authors the scope clause at `:121`; #4021 substitutes its count/enumeration tokens and appends requirement 7. Same branch ⇒ no merge-conflict surface. |
| `release/skills/release-hub/references/decision-briefing.md` | #4020, #4021 | edit×2 | **BINARY** | Disjoint regions — #4020 edits item 1 (`:9`); #4021 edits the H1 (`:2`), the intro (`:4`), and gate 3 (`:23`). Low risk; the file is 34 lines, so relative edit density is high. |
| `packages/release-hub.skill` + `.sha256` | rebuild only | edit×1 | **NONE** | Single claimant; must be the LAST content commit so the hash covers every source edit. |

**Parse-quality:** 2 issues parsed cleanly · 0 deferred · 0 parse-failed.

**Cross-PR Overlap Audit — baseline re-pinned at Stage 6.**

- **Stage-4 baseline:** `d0e06ef6`, **0 open PRs repo-wide**. Recorded per audit-baseline discipline as a **default-to-zero finding on an observably-empty population** — explicitly not load-bearing on its own, and required to be re-checked.
- **Stage-6 re-check (2026-07-27, at `36c80813`): the population is NO LONGER empty.** Three open PRs exist: **#4133** (`release/v3.97-build-philosophy-corpus`, ready-for-review), **#4167** (`release/v3.97-decision-audit-and-learning`, draft), **#4166** (dependabot, non-release).
- **File contention with this release: ZERO.** Neither #4133 nor #4167 touches `release/skills/release-hub/**` or `packages/release-hub.skill*`. Verified by enumerating each PR's changed-file set.
- **Version-slot contention: REAL.** Both #4133 and #4167 display `v3.97` in their branch names, PR titles, and plan-file paths. See **R12** and § Version Determination.
- **Re-check obligation stands:** Stage 9 Phase A6.5 (PRIMARY, HALT-eligible) and Stage 12 Phase A.5 (post-GO ultima ratio) must both re-run this audit. The Stage-6 result is itself a point-in-time reading.

### Cross-Milestone Dependency Validation

#### G3-07 Status

`PASS — 1 dependency edge checked, 0 cross-milestone violations`

Both endpoints of the single edge (#4020 → #4021) sit in this milestone. The epic siblings #4022 and #4023 are epic-scoped, carry no in-bundle edge, and are excluded from the bundle.

#### Violations

None.

#### Resolved Edges

None.

#### Registered Exceptions

None.

### Exclusions

Items explicitly NOT in this release and why:

- **#4022** (spike) and **#4023** (blocked story) — epic-scoped under #4019, not milestone-scoped. Not bundled.
- **`SKILL.md` Guardrail "Every output resolves to a GO/NO-GO with per-finding dispositions"** — Mode-R-true, Mode-O-false. Same defect class as the `:121` scope clause but outside #4020's declared Affected Files. Routed to intake as a next-release issue; **not** widened here.
- **`release/references/how-to/hub-spoke-bridge.md`** near-twin of the `decision-briefing.md` item-1 decision shape — a real latent divergence that will surface after this merge, but it is the *manual* hub process Mode O coexists with, and it is outside both issues' declared Affected Files. Routed to intake; **not** edited here.
- **Audit-harness enum drift** (the operator-local, git-ignored judge instrument writes an abbreviated confidence token) — routed to intake as an operator-local harness fix, **not** a platform-corpus change. Consequential because that harness runs the Round-2 re-audit that grades this release's deferred rate ACs.
- **`version:` frontmatter staleness across five prior material commits on this skill** — a pre-existing conformance gap against `version-field-semantics.md` § Bump Rules. **Accepted residual**: this release's bump closes it going forward; no backfill.
- **P2 signal-tag discipline and P3 evidence-label formalization** — the audit's other two weak conventions. Not in this milestone; P3 is explicitly sequenced after a separate issue by the audit's own remediation priority. Not pulled in.

## Hub-Rendered D-Decisions

Seven decisions were rendered at the Procedure-0 gate on #4049. Three were operator judgment gates; four were recorded determinations (rule-computed, rendered rather than posed — surfacing a rule-determined value as a co-equal click-gate is false-granularity governance theater).

| ID | Verdict | Class | Reversibility · Confidence |
|---|---|---|---|
| **D-ScopeWidening** | **Widen to BOTH modes.** Each rule's scope clause binds decision-class emission obligations across Mode R **and** Mode O. | Operator gate | MODERATE · HIGH |
| **D-ACGradeability** | **Two-part split.** Structural `grep`-checkable predicates graded at Stage 8 in-release; the rate ACs (≥95% / ≥90%) recorded `declared-verification-deferred`, method = Round-2 audit re-run in the Stage-13 30-day outcome window. #4021's anchor AC re-expressed over the existing `stage_gate_legibility` convention. | Operator gate | CHEAP · HIGH |
| **Plan approval** | **APPROVED**, with all three hub corrections applied. | Operator gate | MODERATE · HIGH |
| **D-Version** | Provisional **`{{RELEASE_VERSION}}`**; bump-class **minor**. Binds atomically at the Stage-12 claim, never at plan time (ADR-092). | Recorded determination | CHEAP pre-Engineering; MODERATE after Commit 0 · HIGH |
| **D-ReleaseClass** | **`novel`** — see § Release Class below for the full trigger enumeration. | Recorded determination | CHEAP · HIGH |
| **D-C Branch Topology** | **SINGLE** — one release branch, one PR, one merge. Plan file lands as Engineering Commit 0. | Recorded determination | CHEAP · HIGH |
| **D-Concurrency Posture** | **P0 — fully serial.** Forced by total file overlap on both edit targets. | Recorded determination | CHEAP · HIGH |
| **D-PackageRebuild** | **Rebuild in-PR at Stage 6** (implementation step 5), via `core/deploy/tools/build-skill-packages.sh release-hub`. | Recorded determination | CHEAP · HIGH |

**Explicitly NOT authorized at the Procedure-0 gate:** editing the #4020 / #4021 issue bodies (the AC split lives in this plan, not in ticket rewrites); filing a new intake issue for the ticket-vs-population mis-aiming pattern; anything at Stage 9 or Stage 12.

### D-0 — Premise correction (operator-adjudicated)

Stage-5 / #4121 cross-tabbed #4021's stated mechanism against the audit harness's **recorded** `followed_by_askuserquestion` field. The result **falsifies** the ticket's Actual Behavior (a):

- Every turn that fired an `AskUserQuestion` **rendered its briefing: 31 of 31 conforming** (30 scored 5, 1 scored 4).
- All **28** briefing defects fired **no prompt at all**.

So the ticket's premise — that a material share of gate turns render the `AskUserQuestion` over thin or deferred decision content — does not hold against the audit's own evidence. Gate 3 is at ceiling and needs a **regression guard**, not a fix. The real defect under the 76.1% is the **ungoverned deferral**: a decision surfaced with neither a briefing, nor a prompt, nor a named consolidation touchpoint.

**Adjudication:** ticket-vs-architecture reconciliation type **C2 / PT-1** (premise divergence) → **Tier 1 [ADJUST]**. Design **proceeds** — it is not held. The issue body is **NOT amended**; per ADR-062 the canonical evidence wins over the substrate citation and the ticket body remains historical record. The design consequence is that #4021 makes deferral a **first-class declared form** rather than an unnamed exception — same edit site, materially better rule, with a falsifiable discriminator that turns on structure rather than on judging a decision's importance.

This premise correction rests on a **machine-recorded field**, not on an inferred proxy — which is why it survives the attribution caveat in C1 below.

### Hub correction C1 (as amended) — mode-split magnitude and cap arithmetic

The Stage-4 plan comment transposed its per-mode figures. The hub's first correction fixed the transposition but over-stated the magnitude; the hub then tested its own claim across three proxies and **withdrew the specific figure**. Both corrections are carried here; **the flat "54% of briefing defects are Mode R" is NOT the finding and must not be read as one.**

**The mode split is a proxy-derived `[INFERRED]` attribute, not a sampling stratum.** The audit's frozen methodology flags it inferred explicitly. Measured across three proxies, the Mode-R share of the 28 briefing misses spans:

```
Mode-R share of the 28 briefing misses:
  dir+branch proxy                R = 15/28 = 53.6%
  strict (explicit tokens only)   R = 15/28 = 53.6%   (6 unknown)
  branch-only proxy               R =  8/28 = 28.6%   (3 unknown)
```

**Range: ~29–54%, proxy-dependent.** The *transposition* originally flagged is real (the Stage-4 comment attached its two figures to the wrong modes); the specific magnitude is not established.

**Cap arithmetic under both proxies:**

```
#4020 / reversibility_labeling (41/75 conforming, AC-2 needs >= 72)
  dir+branch    fix Mode R only  68.0%  FAILS | fix Mode O only  86.7%  FAILS
  branch-only   fix Mode R only  57.3%  FAILS | fix Mode O only  86.7%  FAILS
                                                          --> PROXY-ROBUST

#4021 / decision_briefing (89/117 conforming, AC-3 needs >= 106)
  dir+branch    fix Mode R only  88.9%  FAILS | fix Mode O only  87.2%  FAILS
  branch-only   fix Mode R only  82.9%  FAILS | fix Mode O only  90.6%  MEETS
                                                          --> NOT ROBUST
```

**#4020's "neither mode alone suffices" is proxy-robust and is stated as evidence.** Fixing Mode R alone caps at 68.0% / 57.3%; fixing Mode O alone caps at 86.7%; both fail the ≥95% AC under either proxy. Fixing both reaches 100%. The supporting per-mode read is equally blunt: the Output Contract binds **Mode R at 73.0% conformance (27/37)** while leaving **Mode O at 16.7% (2/12)** entirely unbound — #4020 as filed proposed amending the contract that already governs the healthier mode.

**#4021's is NOT proxy-robust** — under a branch-only proxy, fixing Mode O alone reaches 90.6% and **meets** its ≥90% AC. The hub's supporting cap arithmetic for #4021 is therefore **withdrawn**, and #4021's scope-widening rationale rests instead on three **proxy-independent** grounds:

1. **The corpus-outlier finding.** 19 of 20 sibling skills carry the mode-agnostic Output-Contract opener (`…hold on every emission`); `release-hub` alone is mode-scoped. Widening converges it onto the corpus convention rather than inventing a shape.
2. **CIAC-2 scope coherence.** `decision-briefing.md` cannot declare Mode-O-only scope in its title and intro while carrying obligations this release binds to Mode R gate turns.
3. **D-0.** The defect is not mode-shaped — it is deferral-shaped, and that finding rests on a machine-recorded field rather than any proxy.

**The operator's D-ScopeWidening decision is unaffected and stands.** Only the hub's supporting arithmetic for #4021 is withdrawn. Stage 9 should treat every cap figure above as **directional evidence, not as a measured post-fix prediction.**

### Hub correction C2 — Release Class rationale

`novel` is the correct class, but the Stage-4 reasoning ("`routine` fails trigger (b)") was wrong. The taxonomy's trigger column reads **"Trigger (any one fires)"** — the triggers are **disjunctive**, so a class is not eliminated by one trigger failing. `novel` wins by § **Multi-trigger resolution** (`cross-cutting` > `novel` > `routine`; `hotfix` is mutually exclusive with the other three by the hotfix anti-pattern), and the Rationale sub-field must enumerate **every** fired trigger and name the dominant one.

**Every fired trigger, enumerated:**

| Class | Trigger | Fires? | Evidence |
|---|---|---|---|
| `cross-cutting` | (a) ≥3 `pipeline/stage-*.md` files in the matrix | **No** | 0 stage files touched |
| `cross-cutting` | (b) ≥3 of the 7 named governance surfaces | **No** | 0 of the 7 in the edit set |
| `cross-cutting` | (c) ≥3 in-bundle compositional edges | **No** | 1 edge |
| `novel` | (a) ≥1 issue introduces a new reference doc, schema, or skill | **No** | zero new corpus files; every source change is an in-place edit |
| `novel` | **(b) ≥1 D-class decision in the release plan** | **FIRES** | D-ScopeWidening and D-ACGradeability are both genuine release-specific judgment decisions, rendered at the Procedure-0 gate |
| `novel` | (c) ≥1 Stage 5 ADR | **No** | both Stage-5 spokes recorded **no ADR** with skip rationale (N-ADR-3 fires — the decision is already governed by an existing standard) |
| `routine` | (a) all issues P3/P4 + `size:S`/`M` | **Indeterminate** | both are `size:S`/`size:M`, but neither issue carries a priority label — recorded honestly rather than assumed |
| `routine` | (b) all change-spec files have ≥3 prior release touches | **No** | `decision-briefing.md` has 1 prior commit; `SKILL.md` has 11 |
| `routine` | **(c) zero new files added** | **FIRES** | zero new corpus files; the release plan is the release's own artifact, not a change-spec file |
| `routine` | (d) zero new D-class decisions | **No** | two D-class decisions rendered |
| `hotfix` | — | **Mutually exclusive** | Disqualified by the hotfix anti-pattern: a corrective fix that ALSO introduces a new protocol is not a hotfix, and #4021 introduces a first-of-kind `Stage · gate · progress` anchor rule. Independently, the class definition requires a P1/P2 defect against a deployed release; #4020 is Moderate severity and #4021 Low-Moderate. |

**Fired triggers: `novel` (b) and `routine` (c). Dominant: `novel` (b)** — the higher-ceremony class wins per Multi-trigger resolution. Consistent with the platform default `default_release_class = novel`.

**Differentiation posture (the `novel` row):** engagement density **Standard** (REQUIRED) · Stage 9 review depth **Deep** (REQUIRED) · Stage 5 activation bias **ALL** (OPTIONAL) · Stage 13 outcome-window **30-day** (OPTIONAL — this window hosts the deferred rate ACs per D-ACGradeability).

### Hub correction C3 — slug-primary pre-claim naming

The Stage-4 File Change Matrix specified the plan file in its **post-claim** form (a `vX.Y_`-stemmed name). Per `release-corpus-schema.md` § Pre-claim naming lifecycle and `RELEASE_PROTOCOL.md` § Versioning (ADR-092), an in-flight release is authored **slug-primary with no version stem**, and in-file version references are held as the `{{RELEASE_VERSION}}` placeholder. The CAS-win rename to the `vX.Y_RELEASE_PLAN.md` shipped-corpus form fires only at the Stage-12 atomic claim.

**Applied here:**

- Plan file: `release/releases/plans/release-hub-response-convention-enforcement_RELEASE_PLAN.md` (this file — slug-primary, flat).
- Branch: `release/release-hub-response-convention-enforcement` (slug-primary, no version stem).
- In-file version references: `{{RELEASE_VERSION}}`, resolved at the Stage-12 claim by `claim-version.sh --stamp-slug`.

Left uncorrected this would have produced a mis-named Commit-0 artifact and a probable Stage-12 rename collision — a live risk, since two concurrent releases already carry `v3.97`-stemmed plan files (see R12).

### Version Determination

**Bump-class: `minor`.** Protocol-text modification within an existing structure plus reference-document updates — both map to `minor` in the Bump-Class Selection Guide. Under the two-phase allocation rule this declares the **floor**, and binds no concrete number.

**Commit-0 version re-verify (2026-07-27, at `36c80813`) — result: PROCEED.**

| Probe | Result |
|---|---|
| `git fetch --tags origin && git fetch origin main` | clean |
| Highest origin tag | `v3.96` |
| Highest RELEASE_LOG version key | `v3.96` |
| `claim-version.sh --dry-run --bump minor` (authoritative `anchor()` + `claimed_set()` + `compute_next_free`) | **`v3.97`** |
| Planned version = recomputed next-free? | **YES** |
| Planned version already in `claimed_set()`? | **NO** |

Neither HALT condition fires, so Commit 0 proceeded. **But the display slot is contended** — two concurrent in-flight releases (#4133, #4167) already display `v3.97` in their branch names, PR titles, and plan-file paths, and `claimed_set()` by construction reads published Releases ∪ origin tags ∪ RELEASE_LOG DEPLOYED rows, **not** in-flight branches or open PRs. This release's slug-primary identity plus its `{{RELEASE_VERSION}}` placeholders are exactly the ADR-092 protection for this case: whichever release wins the Stage-12 compare-and-swap takes the number, and the losers recompute upward. **Do not hand-write a literal version anywhere in this release's artifacts.** See R12.

## Implementation Sequence

Dependency-ordered, single release branch, one PR, one merge. **Serial order is load-bearing: #4020 lands BEFORE #4021.**

| Seq | Slice | Commit type | Content |
|---|---|---|---|
| 0 | release | `release(<slug>)` | This plan file, with the Commit-0 version re-verify recorded above. |
| 1 | **#4020** | `fix` | `SKILL.md` — widen the Output Contract scope clause (`:121`) to bind both modes with per-requirement mode qualifiers; retarget requirement 5 (`:126`) from "the milestone verdict" to every decision-class emission in either mode; insert the decision-class emission-time predicate paragraph; reconcile the `## Reversibility Discipline` artifact inventory (`:146`); align the `## Guardrails (Platform)` bullet (`:163`) by citing requirement 5 rather than restating scope. **Requirement count held at SIX.** |
| 2 | **#4020** | `fix` | `references/decision-briefing.md` — add the reversibility tier + confidence field to the item-1 decision shape (`:9`), positioned after `final recommendation` and before `routing impact`. |
| 3 | **#4021** | `fix` | `references/decision-briefing.md` — H1 + intro mode-scope reconciliation (CIAC-2); gate-3 render-before-prompt self-gate, declared-deferral form, and the deferral-vs-skip discriminator (`:23`). Gate count stays 5. |
| 4 | **#4021** | `fix` | `SKILL.md` — requirement-count cascade `Six` → `Seven` and the both-mode enumeration `1 and 5` → `1, 5, and 7`; net-new requirement 7 (`Stage · gate · progress` anchor, with the short-mid-stream-turn non-waiver clause); Mode R engagement-contract pointer (`:94`); new Domain-Specific Failure Mode entry (5-field template, category **OUT**). |
| 5 | both | `chore` | Rebuild `packages/release-hub.skill` + `.sha256` via `core/deploy/tools/build-skill-packages.sh release-hub`. **Must be the LAST content commit** so the hash covers steps 1–4. |
| 6 | both | `chore` | `SKILL.md` frontmatter `version:` bump. Per `version-field-semantics.md` § Definition the field is *"the platform release tag at which this skill was last materially edited"* and is explicitly **not** a skill-local semver — so the value is the **platform release tag this release claims**, not a skill increment. This resolves the Stage-4 `[ASSUMPTION – CONFIRM]` proposing a skill-local bump, which the governing standard rejects. Check 6 asserts the regex `^v[0-9]+\.[0-9]+(-[a-z]+)?$` and admits no placeholder, so a literal is written and **Stage 12 re-versions it on slot collision** — the established reconciliation, with two prior precedents on this exact file. Given R12, a collision is likely, not hypothetical. |

**Rationale for #4020-first:** #4020 is `size:S` and owns the *structural frame* (the scope clause). #4021 is `size:M` and *attaches a requirement to that frame*. Smaller-first also minimizes the conflict surface on the shared 34-line reference doc.

**Serialization note:** steps 2 and 3 both touch `decision-briefing.md` but at different regions (item 1 at `:9` vs. the H1/intro/gate-3 block). Steps 1 and 4 both touch `SKILL.md`, with step 4 substituting two tokens inside the sentence step 1 authors. Serial authoring on one branch removes the contention entirely.

**Requirement-count ownership (cross-issue coupling, resolved).** #4020 holds the count at **SIX** and #4021 owns the `Six` → `Seven` cascade plus its Cascade-Sweep row. A Stage-6 authoring that silently bumped the count under #4020's commits would strand #4021's sweep; a Stage-6 authoring that left it at six after #4021's requirement 7 landed would leave the contract internally inconsistent. Both failure modes are avoided by the ownership split recorded here.

### Issue #4020 — reversibility tier + confidence on decision-class emissions

**Change Specification:**

- **Files modified:** `release/skills/release-hub/SKILL.md` (5 in-place edits at `:121`, `:126`, an insert after `:127`, `:146`, `:163`); `release/skills/release-hub/references/decision-briefing.md` (1 in-place edit at `:9`).
- **Change description:** The Output Contract's scope clause binds all six requirements to *"every **Mode R** emission"*, so Mode O emissions carry no labeling obligation at all — which is where 10 of the 12 applicable Mode-O turns miss. The fix widens the opener to *"every emission — Mode R and Mode O alike"* while marking requirements 2, 3, 4, and 6 Mode-R-scoped **inside** the numbered list, so widening does not wrongly bind a Mode O gate presentation to the readiness-check schema or the disposition enum. Requirement 5 is retargeted from "the milestone verdict carries…" to "every decision-class emission — in either mode — carries…", and a new paragraph immediately below the list carries the **emission-time predicate**: one question posed while composing (*does this turn ask the operator to decide, approve, authorize, or act?*), a closed enumeration of the hub's own decision-class emissions keyed to its Procedure vocabulary, an explicit operational residual making the list a floor rather than a ceiling, a ceremony bound naming what does **not** carry a label, the literal label format, and the disqualifier that **prose reasoning about reversibility does not satisfy the requirement**.
- **Why the residual is required, not a hedge:** the audit instrument's applicability predicate for this convention is *decision-class turns (recommendation / verdict / proposed action)*. A closed-enumeration-only rule is strictly narrower than that population, so instrument-applicable turns outside the list would stay unlabeled and the ≥95% rate AC would still fail at Round 2. The residual makes the rule a superset of the instrument's population.
- **Shadow-SSOT split (three surfaces, three jobs, zero overlap):** `reversibility-protocol.md` owns the **vocabulary** (tier definitions, confidence enum, label format, the pmo-qa-auditor G4 test) and is **untouched**; `## Reversibility Discipline` owns the **per-artifact tier assignment** and receives only its artifact-inventory sentence reconciled at `:146` (the two tier bullets are deliberately unchanged — requirement 5 becomes their first real consumer rather than duplicating them); `## Output Contract` requirement 5 owns the **emission-time obligation**, stated once. The Guardrail bullet at `:163` **cites** requirement 5 rather than restating scope, preserving exactly one scope-defining clause for CIAC-1.
- **Acceptance criteria (from the issue, split per D-ACGradeability):**
  - AC-1 — release-hub does not emit a decision-class turn without a reversibility tier + confidence label. *(structural half graded in-release; rate half deferred)*
  - AC-2 — a post-change spot-check of decision-class turns shows **≥95%** labeling conformance. **Declared, verification deferred** — method: Round-2 `agent-response-governance-audit` re-run per its frozen methodology, graded in the Stage-13 30-day outcome window.
  - AC-3 — the enforcement point is documented in the release-hub Output Contract. *(structural, in-release)*
- **Estimated complexity:** Low (six in-place prose edits, all with anchor strings verified unique against the live files).
- **Dependencies:** None — #4020 is the root.

### Issue #4021 — briefing-render gate + `Stage · gate · progress` anchor

**Change Specification:**

- **Files modified:** `release/skills/release-hub/SKILL.md` (4 in-place edits — the `:121` count/enumeration cascade, requirement 7 inserted after `:127`, the Mode R output pointer at `:94`, a new Domain-Specific Failure Mode entry appended); `release/skills/release-hub/references/decision-briefing.md` (3 in-place edits at `:2`, `:4`, `:23`).
- **Change description:** Per D-0 the briefing gate is at ceiling and needs a **regression guard**, not a fix — so gate 3 gains an emission-time self-gate that cites item-1 content by reference (rather than enumerating its fields, which would drift against #4020's new field), plus **declared deferral** named as the legitimate consolidated-briefing form and a falsifiable deferral-vs-skip discriminator. The file's declared Mode-O-only scope is reconciled at the H1 and intro so it stops carrying both-mode obligations under a single-mode title (CIAC-2). Separately, a net-new **requirement 7** adds the one-line `Stage · gate · progress` anchor obligation with an explicit non-waiver clause for short mid-stream turns (outage notes, retries, tool-failure diagnostics, post-write read-backs, terse acknowledgments, intent-to-gather micro-turns) — the exact turn shapes where the anchor is observably dropped — with a matching Domain-Specific Failure Mode entry authored to the 5-field template under category **OUT**.
- **Acceptance criteria (from the issue, split per D-ACGradeability):**
  - AC-1 — the 4-part briefing renders before the structured prompt, with legitimate deferrals preserved. *(structural, in-release)*
  - AC-2 — interrupt / outage / transitional turns carry a `Stage · gate · progress` anchor. *(structural, in-release)*
  - AC-3 — **≥90%** briefing conformance and no anchor-less interrupt turns. **Declared, verification deferred** — method: Round-2 re-run, with the anchor clause **re-expressed over the existing `stage_gate_legibility` convention** and the predicate "zero non-conforming turns whose judge finding names an interrupt / outage / retry / transitional trigger". The instrument produces no `interrupt` turn class, so the AC as originally worded names a population the instrument cannot filter; adding a new class would break Round-1 comparability.
- **Estimated complexity:** Low-Medium (seven in-place prose edits; one net-new numbered requirement and one net-new failure-mode entry).
- **Dependencies:** #4020 (soft authoring-order edge — #4021 substitutes tokens inside the sentence #4020 authors).

## Risk Register

| ID | Class | Risk | Likelihood / Impact | Owner | Mitigation | Reversibility · Confidence |
|---|---|---|---|---|---|---|
| **R1** | Contention | Both issues edit both files; the `SKILL.md` regions genuinely overlap | High / Moderate | Stage 6 | Single branch, single PR, strict serial order #4020 → #4021; the scope clause is authored once, then extended | CHEAP · HIGH |
| **R2** | Scope (confirmed) | #4020's nominated fix cannot meet its own AC-2 — widening only the Mode-R Output Contract caps conformance below the threshold under either proxy | Confirmed / High | Operator (D-ScopeWidening) | Widen the scope clause to all decision-class emissions across both modes | MODERATE · HIGH |
| **R3** | Scope (confirmed, withdrawn arithmetic) | #4021's primary target is Mode-O-scoped while a proxy-dependent share of its defects is Mode R. **The cap arithmetic supporting this is NOT proxy-robust and is withdrawn** (C1 as amended) | Confirmed / Moderate | Operator (D-ScopeWidening) | Reconcile the file's mode scope so the obligation reaches Mode R gate turns; rationale rests on the corpus-outlier finding, CIAC-2, and D-0 — **not** on the cap arithmetic | MODERATE · HIGH |
| **R4** | Scope (AC gradeability) | Both rate ACs measure a population that does not exist until post-deploy; ungradeable in-release | Confirmed / High | Operator (D-ACGradeability) | Two-part AC split: structural predicates at Stage 8; rate ACs `declared-verification-deferred` to the Stage-13 30-day window | CHEAP · HIGH |
| **R5** | Scope (AC targeting) | "Interrupt turns" is not a stratum the audit instrument produces — its turn-class enum has no `interrupt` member | Confirmed / Moderate | Operator (D-ACGradeability) | Re-express the anchor AC over the existing `stage_gate_legibility` convention with an interrupt-trigger predicate, preserving Round-1 comparability | CHEAP · HIGH |
| **R6** | Governance gap | Milestone description carried a Release Outcome Statement but no `## Release Class` H2 | Resolved / Low | Hub | Resolved at D-ReleaseClass; the hub added the H2 with every fired trigger enumerated (C2) | CHEAP · HIGH |
| **R7** | Rollback / CI | A source edit without a package rebuild makes `deploy.sh` Check 7 (package freshness, always-enforce inside `cmd_check`) a hard failure at deploy time. **The CI mirror ships the `warn` token, so CI reports but does NOT block** | Medium / Moderate | Stage 6 | Rebuild in-PR (D-PackageRebuild, step 5). Recurring drift class with prior precedent — a prior release edited 9 skills, rebuilt 0 packages, passed 28/28 CI, and surfaced the staleness only at Stage-13 close-out. **Do not rely on CI to catch this** | CHEAP · HIGH |
| **R8** | Reflexive hazard | This release modifies the skill orchestrating it; the run executes on the **pre-change** package | Confirmed / Moderate | Hub + Stage 9 | Declare introducing-release-exempt in this plan and the PR body; do NOT self-apply the new emission rules mid-run. See § Reflexive-Release Declaration | MODERATE · HIGH |
| **R9** | Dependency (baseline) | Cross-PR zero-contention rested on an observably-empty population at the Stage-4 baseline | **Materialized** / Moderate | Stage 9 / 12 | **Re-checked at Stage 6: the population is no longer empty** — 3 open PRs, 0 file overlap with this release, but a real version-slot contention (R12). Re-check obligation stands at Stage 9 A6.5 and Stage 12 A.5 | CHEAP · HIGH |
| **R10** | Rollback complexity | LOW — all changes are in-place doc edits to one skill plus its compiled package | Low / Low | Stage 12 | `git revert -m 1 <merge-sha>` plus a package rebuild. No data migration, no cross-file cascade, no external consumer | MODERATE pre-Stage-12 · EXPENSIVE at Stage 12 (tag + DEPLOYED row + published Release) · HIGH |
| **R11** | Consistency | Confidence-enum drift: #4020's issue body writes an abbreviated three-letter confidence token; `reversibility-protocol.md` § Confidence Pairing mandates the three-value set `HIGH` / `MEDIUM` / `LOW` | Medium / Low | Stage 6 | Author to the protocol enum, never the ticket's abbreviation. Per ADR-062 the canonical spec wins over the substrate and the issue body is not amended. Graded by CIAC-3 | CHEAP · HIGH |
| **R12** | Version contention (**new at Stage 6**) | **Two concurrent in-flight releases display `v3.97`** — #4133 (ready-for-review) and #4167 (draft) — each carrying a `v3.97`-stemmed plan file. `claimed_set()` reads published Releases ∪ origin tags ∪ RELEASE_LOG DEPLOYED rows and does **not** see in-flight branches, so the next-free computation legitimately returns `v3.97` for all three | **High** / Moderate | Stage 9 / Stage 12 | This release is slug-primary with `{{RELEASE_VERSION}}` placeholders (ADR-092), so it binds nothing until the Stage-12 compare-and-swap arbitrates; the losers recompute upward and the winner keeps the number. **Consequences to carry:** (i) the step-6 frontmatter literal is more likely than not to need a Stage-12 re-version — budget for it rather than treating it as an exception; (ii) Stage 12 must run the pre-merge freeness gate against fresh host state, never against this plan's recorded probe; (iii) merge order, not authoring order, decides the number | CHEAP pre-merge · MODERATE at Stage 12 · HIGH |

**Rollback strategy (release-level):** a single merge commit means `git revert -m 1 <merge-sha>` restores both source files and the package to the base state, followed by a package rebuild. Pre-Stage-12 the release branch is discardable outright. Post-Stage-12 the tag, the DEPLOYED row, and the published GitHub Release are the expensive-to-reverse artifacts — which is why Stage 12 is an operator gate.

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered) — D-Concurrency Posture **P0 fully serial**, forced by total file overlap |
| **Commit strategy** | Grouped commits — one per issue-slice per file, in the implementation sequence order; package rebuild last |
| **Review approach** | Single PR for the entire release (D-C **SINGLE**); created in **draft** at Stage 6, transitioned to ready-for-review at the Stage 9 gate |
| **Deployment mechanism** | Git merge + S-2 skill copy + `.skill` package rebuild; Stage 12 tail routed through `pmo-release-manager` (B1 merge → B3 atomic version claim + signed tag → B5 DEPLOYED-row chore PR) — never a bare `gh pr merge` |
| **Stacked-base cleanup posture** | N/A — no stacked-base waves planned; the release branch bases directly on `origin/main` |
| **Skill-edit discipline** | `pmo-skill-editor` runs over the edited skill **before pushing**, for cross-skill contract regression. Editing `references/*.md` counts. Operator standing rule, added to Stage 6 scope at the Procedure-0 gate |

## Verification Plan

### Per-Issue Verification

| Issue | AC | Verification method class | Method | Expected Result |
|-------|----|--------------------------|--------|-----------------|
| #4020 | AC-1 (structural half) | file-content assertion (in-release) | `grep -nE 'hold on every emission' release/skills/release-hub/SKILL.md` | exactly 1 hit, at the `## Output Contract` opener |
| #4020 | AC-1 (both-mode binding) | file-content assertion (in-release) | `grep -nE 'decision-class emission — in either mode' release/skills/release-hub/SKILL.md` | ≥1 hit, inside `## Output Contract` |
| #4020 | AC-1 (predicate present) | file-content assertion (in-release) | `grep -nE 'decide, approve, authorize, or act' release/skills/release-hub/SKILL.md` | ≥1 hit (the operational residual clause) |
| #4020 | AC-1 (no mode-scoped residue) | file-content assertion (in-release) | `grep -nE 'hold on every Mode [A-Z] emission' release/skills/release-hub/SKILL.md` | **zero** hits |
| #4020 | AC-1 (briefing field) | file-content assertion (in-release) | `grep -nE 'reversibility tier \+ confidence' release/skills/release-hub/references/decision-briefing.md` | 1 hit, in item 1 |
| #4020 | AC-2 (≥95% labeling) | **behavioral — declared, verification deferred** | Round-2 `agent-response-governance-audit` re-run per the frozen methodology | graded in the Stage-13 30-day outcome window |
| #4020 | AC-3 (enforcement point documented) | file-content assertion (in-release) | read the `## Output Contract` block; assert requirement 5 states the obligation and the predicate paragraph states what counts | requirement 5 + predicate paragraph both present under `## Output Contract` |
| #4021 | AC-1 (render-before-prompt) | file-content assertion (in-release) | `grep` gate 3's self-gate + the explicit declared-deferral form in `decision-briefing.md` | self-gate and deferral clauses both present at gate 3 |
| #4021 | AC-2 (anchor rule) | file-content assertion (in-release) | `grep` the named `Stage · gate · progress` requirement in `SKILL.md` | requirement 7 present under `## Output Contract`, with the short-mid-stream non-waiver clause |
| #4021 | AC-3 (≥90% briefing + no anchor-less interrupt turns) | **behavioral — declared, verification deferred** | Round-2 re-run; the anchor clause re-expressed over `stage_gate_legibility` with an interrupt-trigger predicate | graded in the Stage-13 30-day outcome window |

### Cross-Issue Acceptance Criteria

Both issues edit both files, so shared-surface cohesion is a real and gradeable constraint. **Graded at Stage 9 QC3.5 on the merged PR.**

- [ ] **CIAC-1 (#4020 × #4021 on `SKILL.md` `## Output Contract`):** the scope clause governing decision-class emissions is stated **exactly once**, and both issues' rules attach to that single clause — no second, parallel, or contradictory scope sentence is introduced. Every other occurrence of the obligation carries an explicit back-reference to requirement 5. *Method:* `grep -cE 'hold on every emission' release/skills/release-hub/SKILL.md` → 1; `grep -cE 'Six requirements' release/skills/release-hub/SKILL.md` → 0 after #4021 lands; manual read confirms no competing scope statement.
- [ ] **CIAC-2 (#4020 × #4021 on `decision-briefing.md`):** the file's declared mode scope and the obligations it carries are **mutually consistent** — the file does not declare Mode-O-only scope in its title or intro while carrying an obligation this release binds to Mode R. *Method:* `grep -nE 'Mode O|Mode R' release/skills/release-hub/references/decision-briefing.md` + read item 1 and gate 3; assert the scope statement covers every obligation present.
- [ ] **CIAC-3 (#4020 × #4021 on the reversibility vocabulary):** every new rule added by either issue uses the canonical tier enum (`CHEAP` / `MODERATE` / `EXPENSIVE` / `IRREVERSIBLE`) and the canonical three-value confidence enum (`HIGH` / `MEDIUM` / `LOW`) **verbatim** — no new tier values, and no abbreviated three-letter variant of `MEDIUM`. *Method:*
  ```bash
  grep -oE 'confidence: (HIGH|MEDIUM|MED|LOW)|CHEAP|MODERATE|EXPENSIVE|IRREVERSIBLE' \
    release/skills/release-hub/SKILL.md \
    release/skills/release-hub/references/decision-briefing.md
  ```
  Assert zero abbreviated-variant occurrences and zero non-enum tiers.

### Release-Level Verification

Per the verification checklist:

- [ ] File Integrity — both source files parse; frontmatter valid; `deploy.sh --check` Check 6 (version-field format) passes
- [ ] Content Correctness — every Stage-5 change spec applied verbatim; zero improvised edits
- [ ] Cross-Reference Validity — `deploy.sh --check` Check 14 (doc-link integrity) passes on both modified files
- [ ] Skill Invocation — `release-hub` still loads; no frontmatter or structural regression
- [ ] Output Contract Compliance — the numbered requirement list is internally consistent (count matches enumeration matches membership)
- [ ] Package freshness — `deploy.sh --check` Check 7 passes after the step-5 rebuild
- [ ] Skill-edit audit trail — `deploy.sh --check` Check 10 (editor audit-trail trailer) resolved by the `pmo-skill-editor` session commits

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #4020 | `git revert` of its two commits, then a package rebuild | **Low** — isolated in-place prose edits. Caveat: reverting #4020 alone after #4021 lands leaves requirement 7 attached to a Mode-R-scoped opener; prefer whole-release revert |
| #4021 | `git revert` of its two commits, then a package rebuild | **Low** — reverting #4021 alone is clean, since #4020's clause stands on its own at a count of six |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure | Revert that issue's commits per the rollback protocol, then rebuild the package. Honor the #4020/#4021 caveat above |
| **Full Restore** | Systemic failure | `git revert -m 1 <merge-sha>` on the single merge commit, then rebuild the package |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per the rollback protocol; preferred post-Stage-12, when tag + DEPLOYED row + published Release make a revert expensive |

## Operational Deployment Manifest

Layer 2 file propagation targets for Stage 12/13:

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `release/skills/release-hub/SKILL.md` | deployed `release-hub` skill path | S-2 direct copy | `diff` shows no differences |
| 2 | `release/skills/release-hub/references/decision-briefing.md` | deployed `release-hub/references/` | S-2 direct copy | `diff` shows no differences |
| 3 | `packages/release-hub.skill` + `.sha256` | (in-repo artifact — no Layer 2 target) | `build-skill-packages.sh release-hub` | `deploy.sh --check` Check 7 passes |

### Schema Migrations

N/A — no schema migrations in this release. No file in `core/schemas/` is touched.

## Reflexive-Release Declaration

**This release edits the skill orchestrating it.** The run executes on the **pre-change** package; both the deployed artifact and the source predate every edit in this plan.

> **Cutover (introducing-release-exempt):** requirement 5's decision-class emission obligation — and requirement 7's anchor obligation — apply to `release-hub` invocations occurring strictly **after** this release's merge SHA recorded in the release log. **The introducing release itself is exempt** — a release cannot fire its own new emission convention on its own turns without creating a reflexive-pipeline loop. Runs in flight at merge time are also exempt.

Two consequences follow, and both are load-bearing:

1. **Do not self-apply the new emission rules mid-run.** This run's own turns are not gradeable against the conventions it introduces, and no attempt is made to grade them.
2. **The cutover clause is declared here and in the PR body — never pasted into the SKILL.md rule text.** Per reference-durability discipline a durable rule must not carry a version-cutover clause in its own body. The rules as authored are unconditional; the exemption is a property of this release, recorded in this release's artifacts.

This is also the deepest reason the rate ACs are not gradeable in-release (D-ACGradeability): the population they measure — post-change runtime turns — does not exist until a later release runs on the merged package.

## Verification Evidence

(Populated after Stage 12 execution.)

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Change Description

### Outcome

The `release-hub` skill's Output Contract stops being scoped to Mode R alone. After this release the reversibility-tier-plus-confidence obligation binds **every decision-class emission in either mode**, and the contract carries an emission-time predicate that tells the emitter what counts as decision-class while it is composing the turn — a closed enumeration of the hub's own artifacts, an operational residual so the list is a floor rather than a ceiling, and an explicit statement that reasoning about reversibility in prose does not satisfy the requirement. A second rule adds a one-line `Stage · gate · progress` anchor to every emission, with an explicit non-waiver clause for the short mid-stream turns (outage notes, retries, tool-failure diagnostics, terse acknowledgments) where the anchor is observably dropped. For the operator this means a release run that states where it stands on every turn, and never asks for a decision without saying how reversible it is and how confident the hub is.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #4020 | The Output Contract binds the reversibility tier + confidence label to every decision-class emission in both modes, with an emission-time predicate defining what counts and a briefing-item field carrying the label at point of use | DONE |
| #4021 | Gate 3 gains a render-before-prompt self-gate and a governed **declared-deferral** form; the briefing contract's declared mode scope is reconciled; a net-new `Stage · gate · progress` anchor requirement and its matching failure-mode entry land in the Output Contract | DONE |

### Key decisions

- **D-ScopeWidening: widen to BOTH modes.** Each rule's scope clause binds decision-class emission obligations across Mode R and Mode O. For #4020 the supporting cap arithmetic is proxy-robust; for #4021 it is not, so #4021's rationale rests on the corpus-outlier finding, CIAC-2 scope coherence, and D-0 instead. See § Hub-Rendered D-Decisions and § Hub correction C1.
- **D-ACGradeability: two-part AC split.** Structural `grep`-checkable predicates are graded at Stage 8 in-release; the ≥95% / ≥90% rate ACs are recorded `declared-verification-deferred`, with the Round-2 audit re-run in the Stage-13 30-day outcome window as the method. See § Hub-Rendered D-Decisions.
- **D-0: the ticket premise is falsified, and the design proceeds anyway.** Every turn that fired an `AskUserQuestion` rendered its briefing (31/31); all 28 briefing defects fired no prompt at all. The real defect is the **ungoverned deferral**, so deferral becomes a first-class declared form rather than an unnamed exception. Adjudicated Tier 1 [ADJUST]; the issue body is not amended, per ADR-062. See § D-0.
- **D-PackageRebuild: rebuild in-PR at Stage 6.** `deploy.sh` Check 7 is always-enforce at deploy time while the CI mirror only warns, so a deferred rebuild would surface as a hard failure after merge. See § Hub-Rendered D-Decisions and R7.

### Reversibility

**MODERATE — HIGH confidence.** Pre-merge the release branch is discardable outright; post-merge, `git revert -m 1 <merge-sha>` on the single merge commit restores both source files, followed by `core/deploy/tools/build-skill-packages.sh release-hub` to regenerate the package. The tier is MODERATE rather than CHEAP because the widened contract propagates into what Stage 8 grades and into #4021's attachment point, so reversing after Stage 8 means re-grading; at Stage 12 the tag, DEPLOYED row, and published GitHub Release make the posture EXPENSIVE, which is why Stage 12 is an operator gate.

### Downstream impact

- **Enables the Round-2 re-audit** that closes both deferred rate ACs in the Stage-13 30-day outcome window — the Sunset signal for the *Now* slice of epic #4019.
- **Affected surface:** the `release-hub` skill only. Second-order references (the release log, the release digest, archived plans, the skill registry row) are historical or catalog rows and need no update; the orchestration playbook's two references to the briefing contract are pointers, not restatements of the item shape.
- **Carry-forward items** routed to intake, not fixed here: the Mode-R-scoped Guardrail prose that survives a both-mode contract; the manual hub-process doc carrying a near-twin of the pre-change decision shape, which will diverge after this merge; the operator-local audit harness writing an abbreviated confidence token, which is the harness that will grade the deferred rate ACs; and the corpus-wide `version:` bump-rule conformance question.
- **Reflexive constraint:** the new rules take effect for runs strictly after this release's merge SHA. This run is exempt. See § Reflexive-Release Declaration.
- **Version-slot contention:** two concurrent releases display the same provisional version. This release binds nothing until the Stage-12 compare-and-swap, but Stage 12 should expect a re-version of the skill frontmatter. See R12.

### Cross-references

- Release plan: this file, top section
- Milestone: `release-hub-response-convention-enforcement`
- Stage-4 plan comment + Procedure-0 Decision Recorded + C1 amendment: sub-task #4049
- Stage-5 Solutioning designs: #4120 (for #4020), #4121 (for #4021)
- User-facing release notes: `release/releases/notes/{{RELEASE_VERSION}}_RELEASE_NOTES.md` (authored at Stage 13 Close per the release-notes standard)
