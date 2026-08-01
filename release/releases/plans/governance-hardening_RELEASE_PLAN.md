---
title: Release Plan — governance-hardening (records retention, memory↔corpus boundary, template-system governance, and the domain-token registry)
type: release-plan
plan_type: release
status: ACTIVE
release: "{{RELEASE_VERSION}}"
milestone: governance-hardening
release_class: routine
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `governance-hardening`

**Milestone:** `governance-hardening` (#290) · Stage 4 plan source = hub sub-task #4336 · Stage 5 Solutioning sources = #4381 (#3825) and its siblings · Stage 5 adversarial reviews = the 8-of-8 Phase A6.5 wave (#4418 for #3825) · Stage 6 Engineering sub-task for #3825 = #4382
**Version identity:** **slug-primary** per ADR-092 — branch `release/governance-hardening`, plan file `governance-hardening_RELEASE_PLAN.md`, and the literal token `{{RELEASE_VERSION}}` wherever a version would appear. The version number binds at the **Stage-12 atomic claim**, at which point this file is renamed to the `vX.Y_RELEASE_PLAN.md` form. **No version number is hardcoded anywhere in this plan.** The Engineering-Commit-0 version re-verify is satisfied **by construction**: there is no version claimed, so there is no version to collide.
**Topology:** D-C SINGLE — one release branch (`release/governance-hardening`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (operator-ratified at the Stage-4 D-Gate) — Stage-6 chips route one at a time in Implementation-Sequence order on the single shared branch. Force-push (including `--force-with-lease`) is prohibited on the shared release branch under any multi-chip activity.
**Release class:** `routine`, with an operator-approved **Deep Stage-9 depth** override (two `novel` triggers fire; re-classification declined at the Stage-4 D-Gate, recorded as G-2).
**Baseline:** `origin/main` @ `f97c5ff2` — re-verified as tip at Engineering Commit 0 on 2026-08-01 (Saturday). The Stage-4 plan pinned `c4dde614`; main advanced four times during Stage 5. Every anchor in this plan's change matrix was re-verified live at `f97c5ff2`.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #4336, reconciled to the approved **Stage-5 Solutioning** designs, the **Phase A6.5 adversarial review** findings, and the **Collective Review scope-lock** dispositions of 2026-08-01. Where a later disposition superseded a Stage-4 or Stage-5 statement, the transcribed section carries the **later** value and the § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the Stage-6 Engineering spoke for #3825 (#4382), which is Engineering chip 1 of 8.

---

## Header

| Field | Value |
|---|---|
| **Version** | `{{RELEASE_VERSION}}` |
| **Date Created** | 2026-08-01 (Saturday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing |
| **Branch** | `release/governance-hardening` |
| **PR** | populated at Stage 6 PR creation |
| **Milestone** | `governance-hardening` (#290) |
| **Release Class** | `routine` + Deep Stage-9 depth override |
| **Concurrency Posture** | P0 fully-serial |
| **Baseline** | `origin/main` @ `f97c5ff2` |

---

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Size · Pts | Category |
|---|---|---|---|---|
| 1 | #3825 | Disambiguate the overloaded `domain` token across its distinct concepts | M · 4 | project-data-architecture |
| 2 | #3816 | Intake DoR / AC guidance — intent over mechanism | M · 4 | governance-hygiene |
| 3 | #3715 | Release-corpus retention + archive segmentation | L · 8 | governance-hygiene |
| 4 | #3387 | Generated-artifact purge terminal — evaluate and decide | M · 4 | governance-hygiene |
| 5 | #3413 | External-target knowledge: where tier-1/tier-2 facts live | L · 8 | governance-hygiene |
| 6 | #3556 | Encode-then-evict the platform/product-vision memories | M · 4 | governance-hygiene |
| 7 | #3196 | `pipeline-output` template family + L3 governed home | S · 2 | template-system-governance |
| 8 | #3290 | Template-system governance wave — provenance retro-fit + registry rows | L · 8 | template-system-governance |

**Total:** 8 issues · 42 pts. The 42-pt total is **68% over the 25-pt bundle ceiling**; the split was identified at readiness and **declined by the operator** (standing override, recorded at Stage 4 R-5). Not re-litigated here.

### Dependency Graph

**Native dependency edges:** all 8 members carry `blocked_by: 0`, `blocking: 0`, `sub_issues: 0`. **Zero in-bundle dependency edges.** Ordering is driven entirely by shared-file serialization, doctrine-settles-first, and one **data-population** edge (#3290 → #3825).

**Prose-referenced dependencies, live state at plan time:** #351, #877, #2222, #2282, #3385, #3386, #3408, #3434, #1611, #1612, #2376, #217 are all **CLOSED** and supply precedent only. Two remain open and both are **non-blocking by their own cards' text**: **#4213** (named by #3816 under "Relates to" — a coordination edge on shared sizing vocabulary, explicitly not an ownership edge) and **#3402** (the Template-System Governance epic — a parent, retained by the recorded G8 operator override, not a dependency).

**Audit-baseline note.** The "zero open cross-milestone dependencies" finding is **not** a default-to-zero over an empty population: two open cross-milestone *references* exist and are each classified soft on the cards' own text. The claim is "zero open **hard** edges over a **non-empty** reference population," pinned at `c4dde614` and re-checkable at Stage 9. Three concurrent in-flight releases can introduce new hard edges mid-pipeline (R-1), which is the standing reason to re-check.

### Exclusions

- **The `domain` rename branch is out of scope** for #3825. `core/ADRs/ADR-050-deliverable-domain-axis.md` settled the direction — it rejected reusing/renaming the bare name and prescribed a disambiguation note instead. This release delivers that note as a registry. A rename would require superseding ADR-050, not a scope note. The live radius is *worse* than the card filed: 44 markdown declarations across 39 files, plus 3 `.meta.yml` sidecars, plus the SQLite `file_domain` / `idx_files_domain` projections, plus an unfinished `A|B|C` → `source|managed|generated` deprecation migration on the same field that a second rename would collide with mid-window.
- **The registry drift-check is specified but not built** in this release (D-3825-5). See § Deferred Items.

---

## Implementation Sequence

Nine steps. All 8 issues land on **one release branch** and merge as **one PR**, so this is a *commit-order* constraint within the branch, not a cross-release problem.

| # | Issue | Rationale |
|---|---|---|
| 1 | **#3825** | Schema/spec layer; sole in-release writer of `core/schemas/gate-criteria-spec.md`; first toucher of the two contended template files |
| 2 | #3816 | Originally serialized after #3825 on `gate-criteria-spec.md`; that serialization **dissolved** (see below) but the position is retained on other grounds |
| 3 | #3715 | `RECORDS_POLICY.md` amendment must land before any archive sweep moves bytes |
| 4 | #3387 | Reads the same never-delete doctrine #3715 amends; on the build-purge branch it *amends the same file* — a hard write-collision, not just a read-ordering preference |
| 5 | #3413 | Records where external-target tier-1/tier-2 knowledge lives |
| 6 | #3556 | Eviction is terminal; lands after the memory↔corpus contract decision (encode-then-evict) |
| 7 | #3196 | First toucher of `operations/templates/README.md` and the L1/L3 taxonomy pair |
| 8 | #3290 | Serialized after #3196 on `README.md`; shared `qa-acceptance-report` row |
| **9** | **#3825 (registry reconciliation)** | **Terminal.** After #3290's D3 lands, re-run the `domain:` sweep and reconcile the registry to the merged population. A separate, final commit — not part of Step 1. |

### Step 9 — the terminal reconciliation, restated to the decided population

The L4 provenance-header schema (`core/standards/template-protocol.md` §4.1) declares a `domain:` field with the enum `project | software | platform-internal` — this is **concept 5** in the registry (template-provenance). #3290's D3 retro-fits that header onto templates that lack it, so D3 changes the population #3825's registry maps.

**Restated at scope-lock (supersedes the Stage-4 and Stage-5 figures).** #3290's own Stage-5 decision **D-3290-5** chose option (r) — *"19 now + 7 recorded-blocked, routed."* D3 therefore adds **19** declarations, not 26: seven target files are hard-blocked by a silent PyYAML duplicate-key collision (PyYAML resolves a duplicate key last-wins with no error, so a naive insert would quietly delete an existing `domain: managed` line from templates that ship inside a skill package). Consequently:

- **Post-D3 population is 63 declarations across 58 files** — not the 70/58 recorded at Stage 5, and not the "~70 across ~65 files" estimated at Stage 4. `44 + 19 = 63`. The **58** file count is unchanged, because the 19 land on files already inside the 39.
- **The seven blocked files are mapped by concept pattern, not enumerated.** They keep exactly one declaration each (a body-level `domain: managed`, concept 2), which concept 2's `Declaration pattern` already matches. The registry records **no per-file list** for them; enumerating seven file paths in a registry designed to avoid frozen enumerations would reintroduce the drift target the design exists to remove.
- **Step 9 is a verification, not a re-authoring.** All 19 of D3's declarations are concept-5 instances already matched by concept 5's `Declaration pattern`. The only conditions that force a row edit are a **new concept** or a **new owning file**, and D3 introduces neither. Expect **zero row edits**; record the coverage verdict. If a row edit *is* required, surface it rather than silently amending — it means D3 introduced something the design did not anticipate.

---

## File Change Matrix

Deduplicated path list for deterministic downstream extraction (Stages 7/8/9):

```
CHANGELOG.md
core/ADRs/
core/artifact-workflow-protocol.md
core/deploy/deploy.sh
core/deploy/lib-template-sync-source.sh
core/deploy/tests/test_resolve_canonical_source.sh
core/deploy/tools/build-skill-packages.sh
core/disciplines/architecture-overview.md
core/disciplines/knowledge-architecture.md
core/disciplines/memory-architecture.md
core/disciplines/operating-model.md
core/disciplines/project-entity-model.md
core/governance/RECORDS_ARCHIVE_LOG.md
core/governance/RECORDS_POLICY.md
core/schemas/frontmatter-schema.md
core/schemas/gate-criteria-spec.md
core/schemas/project-schema.md
core/specs/domain-token-registry.md
core/standards/km-governance-framework.md
core/standards/platform-doc-frontmatter-standard.md
core/standards/template-protocol.md
core/standards/template-storage.md
core/standards/template-taxonomy.md
docs/module-apis.md
operations/README.md
operations/skills/delivery-engine/references/gate-checklists.md
operations/skills/generated-cleanup/SKILL.md
operations/skills/project-initiator/SKILL.md
operations/templates/README.md
packages/delivery-engine.skill
packages/delivery-engine.skill.sha256
release/references/how-to/intake-style-guide.md
release/references/pipeline/stage-04-planning.md
release/references/standards/bundle-composition-doctrine.md
release/references/standards/release-corpus-schema.md
release/releases/RELEASE_DIGEST.md
release/releases/RELEASE_INDEX.md
release/releases/RELEASE_LOG.md
release/releases/plans/governance-hardening_RELEASE_PLAN.md
```

Plus two path *classes* enumerated at Engineering: `operations/templates/*.md` and `release/releases/RELEASE_LOG_ARCHIVE-<segment>.md`.

**Two Stage-6 corrections to the Stage-4 matrix, both authority-carrying:**

1. **`core/specs/domain-token-registry.md`** replaces the Stage-4 placeholder *"(new) `core/schemas/` — `domain` disambiguation registry."* Placement resolved at Stage 5 (D-3825-2) and ratified at Collective Review. The card's `[ASSUMPTION – CONFIRM]` rationale — *"beside the schemas it indexes"* — is **falsified**: the six owning files span **four** folders, so no "beside" exists. `core/specs/README.md` declares its class as *"registries, catalogs, taxonomies, matrices, glossaries"*; `core/schemas/README.md` scopes that folder to *"the typed-format definitions agents and gates validate documents and handoffs against,"* which a cross-reference index is not.
2. **`core/standards/platform-doc-frontmatter-standard.md`** is **added** to the matrix — a Tier-1 `[ADJUST]` expansion. It governs a **sixth** `domain` concept the card did not enumerate. This is #3825's own recorded **R-3 undercount risk** firing exactly as predicted, surfaced only because R-3's prescribed mitigation (derive from a sweep, never transcribe an enumeration) was actually followed.

### Per-issue intent — #3825 (this chip)

| Path | Intent | Region (verified live at `f97c5ff2`) |
|---|---|---|
| `core/specs/domain-token-registry.md` | **add** | new file |
| `core/schemas/frontmatter-schema.md` | edit | Category 6 `domain` row (`:194`) + Tag Taxonomy `delivery/{domain}` row (`:212`) |
| `core/schemas/project-schema.md` | edit | §Disambiguation (`:248`) — cross-link only |
| `core/schemas/gate-criteria-spec.md` | edit | G1-05a criterion row (`:77`) |
| `core/disciplines/project-entity-model.md` | edit | Artifact `domain` enum{A,B,C} field line (`:193`) |
| `release/references/pipeline/stage-04-planning.md` | edit | the `domain:` class-field definition (`:114`) |
| `core/standards/template-protocol.md` | edit | §4.2 field-table `domain` row (`:148`) |
| `core/standards/template-taxonomy.md` | edit | §2 ecosystem-design cross-reference paragraph (`:33`) |
| `core/standards/platform-doc-frontmatter-standard.md` | edit | §6 RECOMMENDED `domain` row (`:86`) |

**Anchor currency.** Five of the six anchors the *card* cites had drifted by Stage 5 (`:167`→`:194`, `:185`→`:212`, `:184`→`:193`, `:69`→`:114`, `:65,:347`→`:77,:369`; only `template-protocol.md:148` was exact). All nine anchors above were **re-verified live at `f97c5ff2`** at Engineering Commit 0 and are unchanged from the Stage-5 verification — **zero anchor drift** across the intervening commits. Edits are specified by section identifier **plus** verified line, never by line alone.

**Correction to a Stage-4 correction.** Stage-4 Rec 5 recorded that *"the `template-protocol.md` `domain:` enum anchor is live line 126, not `:148`."* Both are live and both are real: `:126` is the §4.1 copy-pasteable YAML block, `:148` is the §4.2 normative field-definition table row, and `:254` is the §7.2 rendered exemplar. `:148` is the **correct pointer site** (the normative definition). A pointer at `:126` would be pasted into every template that copies the block. Only `:126` and `:254` match `^\s*domain:`, which is why a declaration-only probe reported `:148` as absent.

---

## File Contention Map

### Milestone-named pairs

| Shared file | Issues | Status |
|---|---|---|
| `core/schemas/gate-criteria-spec.md` | #3825 → #3816 | **SERIALIZATION DISSOLVED.** #3816's touch on this file was conditional in its own body and resolved **ABSENT** at Stage 5. **#3825 is the sole in-release writer.** The Implementation Sequence retains #3825 @1 / #3816 @2 on other grounds, but **not** for this file — recorded so a future re-order is not blocked by a dependency that no longer exists. |
| `operations/templates/README.md` | #3196 → #3290 | **CONFIRMED, and harder than described** — not merely a shared file but a shared **row**. Both cards intend to author the `qa-acceptance-report` row. Bound by CIAC-2. |

### Pairs the milestone did not contemplate — all four documented so the ordering is not later broken on a false independence assumption

| Shared file | Issues | Region-disjointness (verified live) |
|---|---|---|
| `core/standards/template-taxonomy.md` | **#3825 × #3196 × #3290** | **Three-way, disjoint.** #3196 → `:28` §2 Software table row + new §4.8 + new §6 row + §7. #3290 → `:55` §3.2 Team cell. **#3825 → `:33`** §2 ecosystem-design cross-reference paragraph, below the table and below the boundary rule. Three distinct line regions; **no cell is co-written.** |
| `core/standards/template-protocol.md` | **#3825 × #3290** | **Two-way, disjoint, and it stays two-way.** #3290 → `:19` §1 field count + `:254` §7.2 exemplar. **#3825 → `:148`** §4.2 field row. #3196 confirmed it adds **no** edit to this file (it chose `domain: software`, an existing enum value), so the enum stays closed at three values and this surface did not become three-way. |
| `core/governance/RECORDS_POLICY.md` | #3715 × #3387 | Modeled by the milestone as a *read-ordering* preference; it is potentially a **hard write-collision** if #3387 resolves to build the purge terminal. Bound by CIAC-3. |
| `operations/templates/*.md` → the `domain:` population | **#3290 → #3825** | Not a file overlap — a **data-population edge** running backwards through the sequence. This is what Step 9 and CIAC-1 exist to close. |

### Cross-PR contention (in-flight releases)

Re-checked at Engineering Commit 0 against `f97c5ff2`. Of the three in-flight releases the Stage-4 plan named, **PRs #4330 and #4333 have merged** — G-3's precondition for #3715 is therefore satisfied at this baseline and should be re-confirmed at #3715's own chip. **PR #4334** (`release/check-enforcement-fidelity`) remains open and is the only open PR touching this release's change matrix: it touches `core/schemas/gate-criteria-spec.md` at a **single hunk at `@@ -506,7 +506,7 @@`** (the G6-03/G6-04 region). #3825's edit is at `:77`. **Region-disjoint; no reconciliation required.** Re-check divergence before each subsequent chip's write.

**The append-pattern exemption does not apply to #3715.** Under ADR-005, release-corpus log writes normally classify `append-pattern` — structurally HIGH, operationally LOW, because close-outs only append rows at a stable head. #3715 is **not** an append; it is a restructure that moves bytes out of those files. A restructure against a concurrent append is a genuine conflict, so #3715's four files carry the full sequencing mitigation, not the informational append-pattern treatment.

---

## Hub-Rendered D-Decisions

### Release-level

| ID | Decision | Verdict | Reversibility / Confidence |
|---|---|---|---|
| **D-Version** | Version identity | **Slug-primary** per ADR-092. Bump class = patch within the current major track; the concrete number is indeterminate until in-flight merge order settles, and binds at the **Stage-12 atomic claim**. Nothing downstream hardcodes a version. | CHEAP / HIGH |
| **D-Concurrency Posture** | Stage-6 chip routing | **P0 fully-serial** (D-C SINGLE topology — one branch, one PR, one merge). Selected from the contention map and the 9-step sequence. Non-serial postures prohibit force-push on the shared branch; P0 avoids the question. | CHEAP / HIGH |
| **G-2** | Release Class | **Hold `routine` + Deep Stage-9 depth override.** Two `novel` triggers fire (#3825 adds a new reference doc; #3715 adds archive-segment files); re-classification was declined and the review depth raised instead. Documented per-release exception. | CHEAP / HIGH |
| **G-3** | #3715 sequencing vs in-flight releases | **WAIT** for PRs #4330 and #4333 to merge, then re-baseline before #3715's byte-moving sweep. Both have now merged at `f97c5ff2`; re-confirm at #3715's chip. | MODERATE / MEDIUM |

### Issue-level — #3825

| ID | Decision | Chosen | Reversibility / Confidence |
|---|---|---|---|
| **D-3825-1** | Registry keying | **Concept × owning file**, with a `Declaration pattern` matcher column — over per-declaration rows with a frozen count, and over a hybrid concept-rows-plus-appendix form. Forced, not preferred: two concepts have **zero** `^\s*domain:` declarations, so a declaration-keyed registry cannot represent them at all. | CHEAP / HIGH |
| **D-3825-2** | Placement | **`core/specs/domain-token-registry.md`** — over `core/schemas/`, `core/standards/`, `core/disciplines/`, and in-place in `project-schema.md`. Decided on folder-declared artifact class. In-place was rejected as a **shadow SSOT**: it would make the PROJECT.md schema authoritative over concepts owned by three other files. | CHEAP / HIGH |
| **D-3825-3** | Concept census method | **Derive from a full sweep plus a bounding token probe** — over transcribing the card's enumeration. Yield: **six** concepts, not five. | CHEAP / HIGH |
| **D-3825-4** | Extend vs. create | **Net-new index; both existing local notes retained and extended as pointers.** Recorded in the required form — `net-new because in-place is infeasible:` no existing surface is a corpus-wide concept index; the two candidates are each scoped to one field or one doc. | CHEAP / HIGH |
| **D-3825-5** | Drift check | **Specified and DEFERRED.** Resolves as `extend {core/deploy/tools/check-convention.sh} because {it is the declared engine for residual platform-convention dimensions no existing gate covers}` — dimension (5) REGISTRY COVERAGE. **Not built here.** See § Deferred Items. | CHEAP / MEDIUM |
| **D-3825-6** | The registry's own frontmatter `domain:` | **Omit.** `domain` is not typical for the `spec` class, and omitting it keeps the registry from adding a concept-6 declaration to the very population it maps — the reconciliation stays unperturbed by the artifact performing it. | CHEAP / HIGH |
| **D-3825-7** | Scope of the `project-schema.md` edit | **Cross-link only — no three-row concept backfill.** Superseding the Stage-5 File Change Matrix item 3, on the re-repaired AC-5 and the adversarial review's coupled disposition. See § Deviation Log DEV-1. | CHEAP / HIGH |
| **D-3825-8** | The registry's completeness claim | **Scope the claim to declared-field senses and record the adjacent prose senses as an explicit out-of-scope boundary** — rather than shipping an unqualified *"every concept the bare token `domain` names."* See § Deviation Log DEV-2. | CHEAP / HIGH |

---

## Risk Register

| ID | Risk | Sev | Reversibility / Conf | Mitigation |
|---|---|---|---|---|
| **R-1** | Concurrent in-flight releases write #3715's four release-corpus files. The append-pattern exemption does not apply, because #3715 restructures rather than appends. | HIGH | MODERATE / MEDIUM | Sequence #3715's byte-moving sweep as the **last** Engineering commit before the PR opens; re-run the Stage-9 divergence checkpoint immediately before it; re-baseline if any in-flight PR merged. Two of the three named PRs have now merged. |
| **R-2** | **#3556 encode-then-evict ordering.** The corpus write must merge **before** the memory eviction. Eviction is terminal and **not git-revertable**. | HIGH | MODERATE / HIGH | Hard-gate the eviction on merge-to-`main`, not on branch-commit. Treat both residuals as ONE atomic corpus change. Eviction is a **Stage-13 step, never a Stage-6 one.** |
| **R-3** | **#3825 registry stale-at-merge.** D3's provenance headers add `domain:` declarations after the registry is authored. | HIGH | CHEAP / HIGH | **Substantially retired by design.** The registry is keyed by concept × owning file with a `Declaration pattern` matcher and states **no count anywhere**, so a population change is a zero-row-edit event. Step 9 + CIAC-1 carry the residual as a verification. **R-3 also fired on its own terms during Stage 5** — the sweep it mandated found a sixth concept the card had not enumerated. |
| **R-4** | **#3196 currency mismatch.** The card cites a resolver anchor that has moved; the live definition sits in a shared library with two consumers plus a guard test, so the conditional branch's blast radius is understated. | MED | CHEAP / HIGH | Tier-1 `[ADJUST]` applied before Stage 5. If the release-side branch is chosen, assert every existing template's resolved sync path is unchanged across **both** consumers and run the guard test. |
| **R-5** | 42-pt over-band coordination load. | MED | *(accepted)* / HIGH | Operational consequence only, per the standing override. Drives the WARN quota verdict and the 4+4 wave-split. **Not re-litigated.** |
| **R-6** | #3387 × #3715 potential hard write-collision on the disposition table. | MED | CHEAP / MEDIUM | Sequencing (#3715 @3 → #3387 @4) covers it; bind consistency with CIAC-3; surface #3387's branch choice before #3715's amendment text freezes. |
| **R-7** | #3290 D1 reference cascade — the canonical template has **7** referrers plus a taxonomy family row asserting it present. A non-atomic repoint leaves dangling refs. | MED | CHEAP / HIGH | Rename/move/delete is a **graph** operation: enumerate all 7 first, fix in one change, assert zero dangling refs after. |
| **R-8** | #3290 D3 template sweep — a pattern-scripted header insert is not context-aware and can corrupt frontmatter. | MED | CHEAP / HIGH | Read → classify → edit **per file**; never delete-on-match. **Sharpened at Stage 5:** seven templates already carry a body-level `domain: managed` that is *not* a provenance header, and PyYAML resolves a duplicate key **last-wins with no error** — a naive insert silently deletes the existing line. Those seven are recorded-blocked and routed rather than edited. |
| **R-9** | #3715 machine-contract regression — six named contracts must survive the sweep. | HIGH | CHEAP / MEDIUM | Full green run of all six post-sweep as a Stage-7 gate. Corpus tables move in lockstep or not at all. |
| **R-10** | #3715 corpus magnitude drift (upward) — the defect is growing per release. | LOW | — | Verdict `admit-still-valid`: the defect reproduces and the magnitude grew. Strengthens the card; no re-scope. |
| **R-11** | #3816 package drift — editing a reference file inside a deployed skill tree without rebuilding its `.skill` + `.sha256` trips the package-freshness check. | MED | CHEAP / HIGH | Add both package artifacts to the change set and rebuild at Engineering. Same applies to #3413 **if** it touches a deployed `SKILL.md`. |
| **R-12** | **Rollback complexity is asymmetric.** Seven of eight members are `git revert`-clean; **#3556's eviction is not** — it mutates a store outside the repo. | MED | MODERATE / HIGH | Do **not** treat "revert the PR" as full rollback while #3556 is in scope. |
| **R-13** | **Registry drift after ship** (the card's own recorded risk: *"a registry that silently goes stale is worse than none"*). | MED | CHEAP / MEDIUM | Interim, in-scope: the registry carries its **update trigger** and its **reconciliation command inline**, plus a **known-non-declarations** exclusion list so the pass condition is adjudicable from the registry's own columns. Durable: the deferred `check-convention.sh` dimension (5). |

### Rollback strategy (release-level)

Single PR, single merge → `git revert` of the merge commit restores every in-repo change atomically. Two carve-outs: **(1)** #3556's memory eviction is outside git — sequence it last and gate it on merge; **(2)** #3715's archive segments are new files, so a revert restores byte content by construction but leaves orphaned archive files to delete.

**#3825-specific rollback:** one added file plus eight additive doc clauses on one release branch. **CHEAP / HIGH** — `git revert` restores prior state with no runtime, package, or deploy consequence. No field is renamed, so there is no migration to unwind.

---

## Delivery Strategy

- **Branch:** `release/governance-hardening`, cut from `origin/main` @ `f97c5ff2`.
- **Commit 0:** this plan file.
- **Chip routing:** P0 fully-serial. One Engineering chip at a time in Implementation-Sequence order; the next chip waits until the prior commit lands on the release branch. Each chip re-checks divergence against open in-flight PRs before its first write.
- **Commit messages:** reference the source issue number. No personal email addresses and no user-home paths — CI hard-fails commit messages containing them.
- **PR:** created in **draft** at Stage 6 and transitioned to ready-for-review at the **Stage 9** gate. The `## Change Description` section is committed to this file **before** that transition, so it is visible in the PR diff at Plan Review.
- **Force-push:** prohibited on the shared release branch, including `--force-with-lease`.
- **Closure phrasing:** prose describing per-issue closure uses `mark #N as closed at Stage 13`. Close-family verbs adjacent to an issue number are avoided everywhere in PR and plan text, because GitHub's auto-close parser fires on them regardless of section context.

---

## Verification Plan

### Per-issue verification — #3825

| AC | Method | Polarity check |
|---|---|---|
| **AC-1** — the registry enumerates every `domain` usage, each row naming the concept and the owning file | Run the registry's own § Reconciliation command. Every returned declaration either matches exactly one row's `Declaration pattern` or is listed in the registry's known-non-declarations section; every row's `Owning file` resolves on disk. **Verdict is coverage (zero unmapped, zero dangling), not count equality.** No count is hardcoded in the registry or in this criterion. | — |
| **AC-2** — all **six** concepts represented, including template-provenance and the platform-doc frontmatter `domain` | Read the registry — six distinct concept rows present. | — |
| **AC-3** — each declaration site carries a pointer | `grep` each owning file for the registry reference — one hit per site. | — |
| **AC-4** — no `domain` field was renamed | `git diff --stat` shows no field-name migration; the pre-existing declarations remain. | — |
| **AC-5** — the registry is the single enumerating source; every other surface points to it rather than duplicating it | **(a) greppable:** `grep -rl "domain-token-registry" core/ release/ --include='*.md'` returns the registry itself plus one hit per declaration site. **(b) read-verified:** the registry enumerates all six concepts and no other file attempts a competing enumeration; `core/schemas/project-schema.md` §Disambiguation and `core/standards/template-taxonomy.md` §2's ecosystem-design cross-reference are **retained and extended as pointers**, which satisfies the criterion rather than violating it. | **Clause (a) returns `0` at baseline** — the correct polarity for a criterion that must be false before implementation and true after — against a control (`design-principle-register` → **12** files) proving the probe form resolves. |

### Release-level verification

- Doc-link integrity across all modified `.md` files (`core/deploy/deploy.sh --check` Check 14).
- Reference-durability conformance on every durable-corpus file edited.
- Convention-linter naming dimension on the new lowercase-kebab filename.
- Skill-package freshness for any chip that edits a rostered skill's `SKILL.md` or `references/` tree (#3816 and, conditionally, #3413).
- The five Cross-Issue Acceptance Criteria, graded at Stage 9 on the merged branch state.

---

## Cross-Issue Acceptance Criteria

Five release-scoped cohesion constraints, each spanning ≥2 issues. Graded at **Stage 9** on the merged PR.

- [ ] **CIAC-1 (#3825 × #3290 — the corpus `domain:` declaration population).** The registry maps **every** `domain:` declaration present in the **merged** release state, including the provenance-header declarations #3290's D3 adds. No declaration is unmapped-and-unexcluded, and no registry row points at a path that does not exist. **Method:** run the registry's § Reconciliation command over the merged state; every returned line resolves to exactly one concept row's `Declaration pattern` or to a listed known non-declaration; every row's `Owning file` resolves. **Expected post-D3 population: 63 declarations across 58 files.**
- [ ] **CIAC-2 (#3196 × #3290 — `operations/templates/README.md`).** `qa-acceptance-report-template.md` has **exactly one** registry row — not zero (neither issue authored it) and not two (both did). Same for `people-graph-clarification-queue-template.md`. **Method:** `grep -cF "qa-acceptance-report-template" operations/templates/README.md` returns `1`; same for the other row.
- [ ] **CIAC-3 (#3715 × #3387 — `core/governance/RECORDS_POLICY.md` disposition vocabulary).** The records-disposition vocabulary is internally consistent after both land. No artifact class reads as both never-deleted and purgeable without an explicit stated carve. **Method:** read the amended disposition table against #3387's recorded decision; assert no class carries both dispositions absent a carve sentence.
- [ ] **CIAC-4 (#3413 × #3556 — the memory↔corpus boundary).** The memory↔corpus contract as amended by #3413 **admits** #3556's encode-then-evict execution — the external-target axis does not re-authorize a memory-resident copy of content #3556 has just codified. Each of #3556's two residuals has exactly one home. **Method:** read both amended surfaces; `grep` confirms neither residual exists in both.
- [ ] **CIAC-5 (#3825 × #3196 × #3290 — `core/standards/template-taxonomy.md`).** All three edits to the family table coexist, and **no** canonical-template path cited in §3–§5 is dangling. **Method:** read the family table; for every canonical-template path cited in §3–§5, assert the path resolves on disk; `grep` for the registry pointer, the new family row, and the corrected cell. **#3825 adds zero canonical-template paths**, so it contributes zero dangling paths to this predicate.

---

## Deferred Items

| ID | Item | Target | Rationale |
|---|---|---|---|
| **DEF-1** | **`check-convention.sh` dimension (5) — REGISTRY COVERAGE.** Flag any `^\s*domain:` declaration not matched by a registry row's `Declaration pattern` and not listed as a known non-declaration, and any registry row whose `Owning file` does not resolve. | Follow-up card | It is a genuine *extend* of the declared engine for residual platform-convention dimensions — but building it converts #3825 from a doc card with **no executable surface** (the stated basis of its Stage-7 SKIP) into one with a script, a test, and a CI surface. That is a scope change on an M·4 doc card. **If this is ever pulled forward, the Stage-7 SKIP is void and must be re-decided.** |
| **DEF-2** | An ADR binding the registry's **update trigger** on future work (*"any new `domain:` concept MUST register a row"*). | Filed with DEF-1 | That is a governance convention with teeth and warrants its own ADR. Recording the trigger in-document (as this release does) is the interim; binding it on future authors is a separate decision. |
| **DEF-3** | Six out-of-scope drifts surfaced during Stage-5 survey, routed to next-release observation intake, **none executed here**: the entity model sitting on the deprecated side of a live vocabulary migration it does not reference; a governance standard whose §2 and §6 contradict each other on this exact field (materially, the *cause* of the sixth concept going unnoticed by four prior surveys); a folder README index five files behind its directory; an ADR ratification-flip inconsistency; a shipped deliverable-domain guide absent from ADR-050's recognized set; and the registry's own scope-boundary case, which is **handled in-design** rather than routed. | Next-release intake | Scope is hard-locked through Stage 9. A discovery outside scope is recorded, never implemented. |

---

## Verification Evidence

*(Populated at Stage 6 C4 and refreshed as chips land.)*

---

## Deployment Execution Log

*(Populated at Stage 12.)*

---

## Deviation Log

| ID | Deviation | Authority | Tier |
|---|---|---|---|
| **DEV-1** | **`core/schemas/project-schema.md` receives a cross-link only — the Stage-5 spec's "add three rows" is not executed.** The Stage-5 File Change Matrix item 3 directed adding rows for the behavioral/domain predicate, template-provenance, and K1 platform-doc frontmatter to that file's §Disambiguation table. Executing it would give that file a **complete six-concept enumeration** — a second corpus-wide index maintained in parallel with the registry, differing only in that it does not call itself authoritative. That is precisely what the re-repaired **AC-5 clause (b)** forbids (*"no other file attempts a competing enumeration"*) and what **D-3825-2** rejected in-place placement for (shadow SSOT). The table stays at five rows, scoped to what its own final column declares — *"Relation to `deliverable_type`"* — and gains a lead cross-link naming the registry as the corpus-wide index. | Re-repaired AC-5 in the #3825 issue body (2026-08-01, operator) + adversarial review CD-2, dispositioned fix-in-place at Collective Review. **Amendments win over the spec where they disagree.** | Tier 1 `[ADJUST]` |
| **DEV-2** | **The registry's `purpose` is scoped to declared-field senses, and three adjacent prose senses of the bare word are recorded as an explicit out-of-scope boundary** rather than shipped under an unqualified *"index of every concept the bare token `domain` names."* The adversarial review found at least three further live senses (the PMBOK 7 Performance-Domain axis — 17 corpus occurrences, and sitting **two lines below** the `template-taxonomy.md` paragraph this card edits; the decision-owner / authority sense; and the observation-log partition sense). An unqualified completeness claim would be false on delivery and would re-open the exact defect this card exists to close. | Adversarial review PR-2, advisory disposition (a) or (b); (b) chosen because adding them as rows would change the six-concept count that **AC-2** grades. | Tier 1 `[ADJUST]` |
| **DEV-3** | **Post-D3 population restated from 70/58 to 63/58**, and the seven schema-blocked files are **mapped by concept pattern, not enumerated individually**. | Adversarial review PR-5 (cross-spoke drift), reconciled against #3290's own Stage-5 decision D-3290-5. | Tier 1 `[ADJUST]` |
| **DEV-4** | **Four `[SOURCE]`-labelled enumerations in the Stage-5 spec were re-derived at Engineering and three did not reproduce as written.** All are evidence-record corrections with no change to the deliverable's architecture. Recorded for the Stage-13 learnings line. Detail in § Evidence Re-Derivation below. | Adversarial review PR-3 / PR-4 + the Tier-1 `[ADJUST]` instruction *"re-derive every count from its command before committing."* | Tier 1 `[ADJUST]` |

### Evidence Re-Derivation (Engineering Commit 0, baseline `f97c5ff2`)

Every count below was re-run from its own command at Engineering time. **No number in this plan or in the registry was transcribed from an upstream artifact.**

| Claim as written upstream | Re-derived at `f97c5ff2` | Verdict |
|---|---|---|
| Population: 44 declarations / 39 files | **44 / 39** | **Reproduces exactly** |
| Census identity `1 + 26 + 0 + 0 + 11 + 9 = 44` | Sums to **47**, not 44. Hand-classifying all 44 hits: concept 2's in-scope count is **23**, not 26 — the printed 26 is sidecar-inclusive, and the sweep's `--include="*.md"` structurally cannot return the three `.meta.yml` sidecars. | **Does not reproduce** — corrected |
| Concept 1 has 1 declaration | **0 true declarations.** Its single regex hit is the wrapped tail of an inline `domain_practice: { … }` label — a token the same spec classifies as a *deliberately non-colliding compound that is not an overload*. Counting it as concept 1 would contradict that classification. | **Does not reproduce** — recorded as a known non-declaration |
| Four registry/catalog/map precedents in `core/specs/` | **3.** One cited file resolves to `core/disciplines/`. The placement conclusion is unaffected — it rests on the folder-README declared class, which reproduces exactly. | **Does not reproduce** — corrected |
| Placeholder probe returns 7 | Returns **20** (7 curly-brace + 13 angle-bracket forms). The under-reported set is where two of the three adjacent prose senses live. | **Does not reproduce** — corrected, and it is the evidence behind DEV-2 |
| Concept 4 has zero declarations, with a control | Target **0**; control **2**. | **Reproduces exactly** |
| Concept 3 has zero declarations; 8 tag-pattern occurrences | **8** occurrences, **0** matching the declaration regex. | **Reproduces exactly** |
| AC-5 clause (a) polarity at baseline, with a control | Target **0**; control **12**. | **Reproduces exactly** |
| Zero anchor drift across all nine matrix files | All nine anchors live at their Stage-5-verified lines. | **Reproduces exactly** |

**Final census at `f97c5ff2`** — concept 1: **0** · concept 2: **22** · concept 3: **0** · concept 4: **0** · concept 5: **10** · concept 6: **9** · known non-declarations: **3**. Identity: `0 + 22 + 0 + 0 + 10 + 9 + 3 = 44`, reconciling exactly against the live sweep. **This identity is recorded here, in the plan, and deliberately *not* in the registry** — the registry states no count anywhere, which is what makes a population change a zero-row-edit event.

---

## Change Description

> **Refresh discipline.** This section is authored at Stage 6 PR creation by Engineering chip 1 of 8 and is **refreshed as each subsequent chip lands**, per the Change Description Protocol. Per-issue status below reflects the branch state at authoring time; a `PENDING` row means the chip has not yet been routed under the P0 fully-serial posture, not that it was cut. Every row resolves to `DONE` / `PARTIAL` / `DEFERRED` before the Stage-9 gate.

### Outcome

This release hardens four governance surfaces that had drifted apart from what the corpus actually does: records retention and archive segmentation, the memory-versus-corpus knowledge boundary, template-system provenance, and the overloaded `domain` token. The first surface to land is the `domain` disambiguation — the bare word named six distinct concepts across four folders with no index anywhere, so a reader who learned it in one file carried the wrong meaning into the next. `core/specs/domain-token-registry.md` is now the single enumerating source for all six, and every site that declares or defines the token points at it. No field was renamed; the ambiguity is resolved by indexing, which is the direction ADR-050 settled and the note it recorded as a residual and never got.

### Issues resolved

| Issue | Outcome | Status |
|---|---|---|
| #3825 | Six-concept `domain` registry at `core/specs/domain-token-registry.md`, plus a pointer at each of eight declaration sites. Concept-keyed with a three-factor declaration matcher and a known-non-declarations exclusion channel, so the coverage check is deterministic and a population change edits zero rows. | **DONE** (terminal Step-9 reconciliation pending, by design) |
| #3816 | Intake DoR / AC guidance restated around intent rather than mechanism. | PENDING |
| #3715 | Release-corpus retention amendment plus archive segmentation of the four unbounded logs. | PENDING |
| #3387 | Recorded decision on whether a generated-artifact purge terminal is built. | PENDING |
| #3413 | External-target knowledge axis recorded on the memory and knowledge architecture surfaces. | PENDING |
| #3556 | Platform and product vision codified to the corpus, then the tied memories evicted — in that order. | PENDING |
| #3196 | `pipeline-output` template family plus its governed L3 home. | PENDING |
| #3290 | Template-system governance wave — provenance retro-fit and the missing registry rows. | PENDING |

All eight are marked as closed at Stage 13 via the close-out output set; none is closed at Engineering or Execute.

### Key decisions

- **Registry keying — concept × owning file, not per-declaration.** Forced rather than preferred: two of the six concepts have zero `domain:` declarations (one is a tag path segment, one is adjectival prose), so a declaration-keyed registry cannot represent them at all. The same choice makes a growing declaration population a zero-row-edit event.
- **Placement — `core/specs/`, not `core/schemas/`.** Decided on folder-declared artifact class. The card's "beside the schemas it indexes" premise was falsified: the six owning files span four folders, so no "beside" exists.
- **`project-schema.md` receives a cross-link only.** The Stage-5 spec directed backfilling three concept rows there; that would have produced a second complete corpus-wide index maintained in parallel with the registry — the duplicate-source defect this card exists to close. Superseded by the re-repaired acceptance criterion and the adversarial review's coupled disposition.
- **The registry's completeness claim is scoped to declared-field senses.** Three further live prose senses of the bare word exist, including a PMBOK Performance-Domain axis sitting two lines from a paragraph this change edits. They are recorded as explicitly excluded adjacent senses rather than shipped under an unqualified "every concept the token names."
- **Drift check specified, not built.** A convention-linter coverage dimension is the right durable answer, but building it would add an executable surface to a doc card whose Stage-7 skip rests on having none. The registry carries its update trigger and reconciliation command inline as the interim.

### Reversibility

**CHEAP / Confidence HIGH** for the landed work — one added file plus additive prose clauses in eight existing files; `git revert` of the merge commit restores prior state with no runtime, package, or deploy consequence, and no field was renamed so there is no migration to unwind. **The release as a whole is MODERATE / Confidence HIGH**, and the reason is one carve-out: #3556's memory eviction mutates a store outside the repository, so reverting the merge does not restore it. Do not treat "revert the PR" as full rollback while #3556 is in scope.

### Downstream impact

- **A terminal reconciliation step is owed** after #3290's template provenance retro-fit lands: re-run the registry's reconciliation command over the merged state and record the coverage verdict. Expect zero row edits — the added declarations are all instances of a concept the registry already maps. A required row edit means the retro-fit introduced a new concept or owning file and should be surfaced, not silently absorbed.
- **Expected post-retro-fit population: 63 declarations across 58 files.** Seven target files are hard-blocked by a silent duplicate-key collision and keep a single declaration each; they are covered by concept pattern and are deliberately not enumerated.
- **Two follow-up cards are named and routed:** the convention-linter registry-coverage dimension, and an ADR binding the registry's update trigger on future authors.
- **Six out-of-scope drifts** surfaced during design and are routed to next-release intake, none executed here. One of them — a governance standard whose own two sections contradict each other on this exact field — is materially why the sixth concept went unnoticed by several prior surveys.

### Cross-references

- Release plan: this file, `release/releases/plans/governance-hardening_RELEASE_PLAN.md` (top).
- Milestone: `governance-hardening` — https://github.com/cody-hutson/pmo-platform/milestone/290
- User-facing release notes: authored at Stage 13 to `release/releases/notes/` under the version claimed at Stage 12.
