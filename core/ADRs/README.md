# Core Module Architecture Decision Records (ADRs)

Architecture Decision Records for the `core/` module of pmo-platform-v2. Each ADR captures a structurally-load-bearing decision with status, context, decision rationale, consequences, reversibility, and cross-ADR composition.

## Format

ADRs follow the format established by ADR-005 (see [`../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md`](../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md)) — frontmatter with `title / status / date / release / deciders / tags / source_observations`, body with `Status / Context / Decision / Consequences / Reversibility / Related ADRs` sections.

## Naming convention

`ADR-NNN-kebab-case-title.md` where NNN is monotonically increasing across the platform (NOT per-module). ADR-003 + ADR-004 are foundational core-scope decisions migrated from an earlier governance location. ADR-001 + ADR-002 + ADR-005 (release-scope) live in [`../../release/ADRs/`](../../release/ADRs/). ADR-006..009 are module-restructure decisions.

**Enforcement.** The platform-wide-unique + gap-free numbering rule is enforced in CI by `release/tools/check-adr-numbers.py` (the `adr-number-integrity` job in `.github/workflows/repo-integrity.yml`), which fails any PR that introduces a duplicate ADR number or a gap in the global sequence.

**Renumber log.** Core ADR-024 (`operations-consume-core-safety-controls-via-public-api`) → **ADR-028** on 2026-06-18, resolving a platform-wide collision with the earlier `release/ADRs/ADR-024-cross-release-impact-model.md` (which had correctly claimed 024). The renumbered ADR's Status section carries the full provenance.

## Cross-numbering across the ADR migration + module-restructure ADR materialization

| ADR | Module | Source | Owner | Date |
|---|---|---|---|---|
| ADR-001 | release | pmo-platform | migrated | 2026-05-01 |
| ADR-002 | release | pmo-platform | migrated | 2026-05-10 |
| ADR-003 | **core** | pmo-platform | migrated | 2026-05-10 |
| ADR-004 | **core** | pmo-platform | migrated | 2026-05-10 |
| ADR-005 | release | pmo-platform | migrated | 2026-05-17 |
| ADR-006 | **core** | module-restructure | module-restructure | 2026-05-27 |
| ADR-007 | **core** | module-restructure | module-restructure | 2026-05-27 |
| ADR-008 | **core** | module-restructure | architectural intent; later implementation | 2026-05-27 |
| ADR-009 | **core** | module-restructure | architectural intent; later implementation | 2026-05-27 |
| ADR-018 | **core** | declarative-workitem-type-model | data-architecture (WITL) | 2026-06-07 |

## Module-restructure ADR composition graph

```
ADR-006 (skill-to-module map)        ┐
        │                            │
        └──→ ADR-007 (core boundary) ┤
                │                    │
                ├──→ ADR-008 (deploy.sh array design)
                └──→ ADR-009 (rewrite-map CLI design)
```

ADR-006 establishes the 22-skill 3-module partition; ADR-007 extends to the non-skill content boundary (hooks, disciplines, schemas, standards, specs, tools, rules, governance, agents); ADR-008 + ADR-009 codify the architectural intent for the two tooling adaptations that consume the ADR-006 + ADR-007 decisions. ADR-003 + ADR-004 (foundational governance — see § Foundational ADRs in core below) predate the module split and are platform-wide cross-cutting decisions consumed by both the modular-monolith partition (ADR-006/007) and the cross-stage execution model.

## Module-restructure ADRs

### ADR-006 — Skill-to-module map

**Status:** Accepted (operator standing-GO 2026-05-27).
**Decision:** 22 skills partition as operations=12, release=6+1 canary, core=3.
**Reversibility:** MODERATE (re-classification involves cross-wave migration redo).
**File:** [ADR-006-skill-to-module-map.md](ADR-006-skill-to-module-map.md)

### ADR-007 — Core module boundary lock-in

**Status:** Accepted.
**Decision:** File-placement boundary locked for hooks (10), allowlists (14), disciplines (21), schemas (15 + 1 to operations), standards (34 core / 11 release), specs (12 core / 9 release), tools (4 core / 9 release), roadmaps (6/1/1), rules (7/1), governance (OPERATIONS + README to core; RELEASE_PROTOCOL to release; RELEASE_LOG to operator-instance), and agent definitions (8 to release).
**Reversibility:** MODERATE.
**Amended in part:** the "roadmaps (6/1/1)" clause is superseded by ADR-012 — roadmap instances de-scoped to operator-local authoring.
**File:** [ADR-007-core-module-boundary.md](ADR-007-core-module-boundary.md)

### ADR-008 — deploy.sh per-module array design

**Status:** Accepted as architectural intent; implementation followed.
**Decision:** Per-module arrays (OPERATIONS_SKILLS / RELEASE_SKILLS / CORE_SKILLS / CANARY_SKILLS / HARNESS_LIST); empty-array guard at every iteration site under `set -euo pipefail`; `resolve_skill_module()` helper with `die`-on-miss.
**Reversibility:** CHEAP.
**File:** [ADR-008-deploy-sh-per-module-array-design.md](ADR-008-deploy-sh-per-module-array-design.md)

### ADR-009 — Rewrite-map CLI design

**Status:** Accepted as architectural intent; implementation followed.
**Decision:** `check-doc-links.py` extended with `--from-path X --to-path Y` two-flag CLI; V1/V2 prefix split; EMIT-ONLY enforced via Fixture 6 mtime/content-hash assertion; asymmetric-flag error emits dual stderr/stdout; asymmetry warning when from/to segment counts differ.
**Reversibility:** CHEAP.
**File:** [ADR-009-rewrite-map-cli-design.md](ADR-009-rewrite-map-cli-design.md)

### ADR-012 — Roadmap-instance de-scope (amends ADR-006 + ADR-007)

**Status:** Accepted (operator directive 2026-06-02). **Location clause superseded-in-part by ADR-046 (2026-06-27, below)** — the "not tracked" decision stands; the per-instance *location* is now the shipped `/roadmaps/` folder.
**Decision:** Initiative-roadmap *instances* de-scoped from the tracked tree to operator-local authoring (`<OPERATOR_INSTANCE_ROADMAPS_PATH>`); the roadmap *framework* is retained as the reusable convention; the 4 in-repo enforcement surfaces (deploy.sh Check 24, gate-criteria-spec G3-13, Stage 13 forcing-function, Stage 5 cohesion-check) are dropped. Amends the roadmap-placement clauses of ADR-006/007 — all non-roadmap decisions stand.
**Reversibility:** MODERATE.
**File:** [ADR-012-roadmap-instance-descope.md](ADR-012-roadmap-instance-descope.md)

### ADR-046 — Roadmap-instance in-repo home — shipped /roadmaps/ folder + token-as-override

**Status:** Proposed (supersedes-in-part ADR-012's location clause; flips to Accepted at the Stage 9 review).
**Decision:** Roadmap instances get a single canonical in-repo home at repo-root `/roadmaps/` (folder + `README` tracked, instances git-ignored — the `analysis/` workspace pattern); the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token is redefined to default-resolve to `/roadmaps/` and remains as the per-deployment override. Preserves ADR-012's "instances not tracked" decision; corrects only its location indirection.
**Reversibility:** MODERATE.
**File:** [ADR-046-roadmap-instance-in-repo-home.md](ADR-046-roadmap-instance-in-repo-home.md)

### ADR-013 — detect_install_path session-resolution policy + COWORK_AVAILABLE seam

**Status:** Accepted (Stage 5 Collective Review scope-lock 2026-06-03).
**Decision:** Resolve the Cowork install path via a deterministic ladder (operator.toml `[paths].cowork_install_path` base → single candidate → fingerprint + skill-count → logged mtime last resort → structured terminal), demoting mtime from primary signal to logged last resort; remove the hardcoded fallback session UUID (the last literal UUID in the tree) in favor of the structured terminal; re-point Check 8 to validate the detected path against the configured base (config-absent → SKIP); and introduce a module-level `COWORK_AVAILABLE` flag so `cmd_deploy` warns and continues to the unconditional user-local `~/.claude/skills` mirror when no Cowork session resolves, instead of hard-failing. Separates *resolution* (which path, or none) from *the deploy command's response to none*.
**Reversibility:** CHEAP.
**File:** [ADR-013-detect-install-path-session-resolution.md](ADR-013-detect-install-path-session-resolution.md)

### ADR-014 — Two-hash separation for managed-section tamper detection

**Status:** Accepted (Stage 5 Collective Review scope-lock 2026-06-03).
**Decision:** Add a second MANAGED-fence marker `installed_sha` = SHA-256 of the post-substitution installed managed body — the tamper anchor — alongside the existing `managed_sha` (source-template hash, the regeneration trigger). `update.sh` re-hashes the live managed body each run and compares to the stored `installed_sha`; on mismatch it backs the file up to `~/Claude/.backup-tampered-<ts>/` and force-regenerates (independently of the source-SHA skip). The hash byte-domain is single-sourced via `compose.py`'s `_extract_managed_body` (shared by the writer and a new `compose.py installed-sha` subcommand) so writer/reader cannot drift. Comparing the post-substitution anchor (not the source-template hash) is what prevents a false-positive storm on every token-bearing allowlist. Missing `installed_sha` ⇒ "unknown, not tampered" (self-healing back-compat; back-filled on next regen / `--force-regen`). Reconciles the prior §2.4 ⇄ §2.5/§3.2 spec contradiction. Closes the release's R-SEC managed-section tamper gap.
**Reversibility:** CHEAP.
**File:** [ADR-014-managed-section-two-hash-tamper-detection.md](ADR-014-managed-section-two-hash-tamper-detection.md)

### ADR-016 — intake front door as a distinct architectural component (boundary + downstream handoff contract)

**Status:** Accepted (intake-elicitation-skill Stage 5 Collective Review scope-lock + operator PR review 2026-06-06).
**Decision:** Introducing the conversational intake front door (`intake-desk`) establishes a distinct architectural component at the head of the work-item lifecycle. The ADR records (1) intake/elicitation as that component; (2) the component boundary, stated as disjoint verbs — `intake-desk` authors a typed work item, `ppm-agent` processes existing artifacts, `project-initiator` scaffolds/closes projects, architecture authors ADRs (so intake does not author ADRs); and (3) the handoff contract to triage/downstream — a typed item plus stage-owned `[ASSUMPTION – CONFIRM]` items for progressive closure plus a body decomposition callout (one item per request, never auto-decomposed). The work-item type system, when it lands, extends the type set the front door binds to; the component boundary and handoff contract are unaffected.
**Reversibility:** MODERATE.
**File:** [ADR-016-intake-front-door-architectural-boundary.md](ADR-016-intake-front-door-architectural-boundary.md)

## Data-architecture ADRs

### ADR-018 — Work-Item Type Layer (WITL): thin generic Work Item entity + declarative type layer

**Status:** Proposed (flips to Accepted at the declarative-workitem-type-model Stage 9 GO — that GO renders the Tier-2 SCOPE CHANGE).
**Decision:** Resolve the work-item modeling tension as a HYBRID (D1): add ONE thin generic `Work Item` entity (roster no. 18) carrying Entity Core 7 + a `work_item_type` discriminator + a polymorphic `parent_ref` (Milestone or Workstream) + the built 7 MVP relationships by reference; externalize ALL type variability to a separate declarative type-pack layer (the C2 type meta-schema). Vocabulary is methodology-projected (D2 — canonical kind `Work Item`; Story/Bug/Test/Task are projections; no glossary amendment). Now-scope (D4) = this ADR + the C2 type meta-schema + the C1 authorization; roster RE-FROZEN at 18 via a scoped Tier-2 (RAID-2026-05-16-precedented).
**Reversibility:** EXPENSIVE (once the C2 type layer + downstream consume the entity it is a contract; pre-consumption MODERATE).
**File:** [ADR-018-work-item-type-layer.md](ADR-018-work-item-type-layer.md)

## Automation-governance ADRs

### ADR-020 — Agent-script promotion ladder: form-anchored five-rung enum (AS0–AS4)

**Status:** Accepted (operator-ratified at the v1.09 Stage 5 scope-lock 2026-06-10 — single-issue-release equivalent gate per § Status enum).
**Decision:** Adopt the form-anchored five-rung enum AS0 (agent procedure) / AS1 (documented command) / AS2 (tracked tool, agent-invoked) / AS3 (checkpoint-wired) / AS4 (autonomous guard) as the promotion-ladder vocabulary for the agent-to-script promotion framework, with the split-promotion rule (judgment-class steps promote only their evidence-gathering substrate) and the caller-type AS2/AS3 boundary test (AS3 iff the invoker is another governed executable). Rejected: reusing the gate-criteria Check enum (parallel-vocabulary leak), a 4-rung collapse (erases the documented-command rung where most promotions begin), and a continuous readiness score (not schema-validatable). Canonical definition: [core/standards/agent-script-promotion-framework.md](../standards/agent-script-promotion-framework.md).
**Reversibility:** CHEAP at ship, trending MODERATE as downstream artifacts accumulate rung citations.
**File:** [ADR-020-agent-script-promotion-ladder.md](ADR-020-agent-script-promotion-ladder.md)

## Config-architecture ADRs

### ADR-022 — platform-config.toml vs operator.toml split: environment/identity vs platform-behavior

**Status:** Accepted (operator-ratified at the adapter-config-foundation Collective Review scope-lock 2026-06-13).
**Decision:** Adopt Option C-refined — a two-file config split along the security/access-control boundary, relocating nothing. `operator.toml` is the operator-ENVIRONMENT / IDENTITY surface (identity, paths, methodology default, host-adapter selectors consolidated into a new `[adapters]` table — the onboarding seam; retains `chmod 600` security posture). `platform-config.toml` (NEW) is the platform-BEHAVIOR surface, holding only the new behavior categories ADR-017 did not enumerate (`[bundling]`, `[release_class]`, `[relationship_mapping]`, `[calibration]`). The legacy `[platform].work_board` field is reconciled by deprecation alias, not removal. Refines and extends ADR-017 §S2; relocates nothing, so it is not an ADR-017 deviation.
**Reversibility:** CHEAP at ship (additive — revert the release PR; the alias keeps existing readers working), trending MODERATE as downstream adapter tickets and consumers wire into the new seams.
**File:** [ADR-022-platform-config-vs-operator-toml-split.md](ADR-022-platform-config-vs-operator-toml-split.md)

## Skill-architecture ADRs

### ADR-023 — Skill sourcing-coupling posture: own-with-harvest default; guarded-wrap exception

**Status:** Proposed (flips to Accepted at the comms-writer/artifact-generator-anthropic-offload-refactor Collective Review scope-lock — the Stage 5 N-way-consistency gate per § Status enum).
**Decision:** A PMO skill is `independent` (own) by default — authored first-party and *harvesting* upstream Anthropic structure/patterns at design time via the upstream-reference catalog, not at runtime. A runtime dependency (`extends` / `pass-through`) is the exception, permitted only when all three hold: the upstream contract is commodity-stable, a silent upstream change has low blast radius, and the coupling is guarded by a drift canary. Stakeholder-facing generation and any PMO-judgment or governance-binding skill never take a runtime Anthropic dependency. Maps onto the registry's existing four-value enum (no new vocabulary); the registry update trigger and the Stage-4 D-Gate cite this ADR rather than restating it.
**Reversibility:** MODERATE (CHEAP pre-application; crosses to MODERATE once skills are re-classified or re-pointed under the rule).
**File:** [ADR-023-skill-sourcing-coupling-posture.md](ADR-023-skill-sourcing-coupling-posture.md)

### ADR-028 — Operations skills consume core safety-control references via-public-api, not by fork

**Status:** Accepted (operator-adopted at the v2.01 / `02-FNH-est-lifecycle-status-hardening` Collective Review scope-lock 2026-06-15; convention-consistent with ADR-023's operator-adopted → ratified-at-gate pattern; authored at Stage 6 per the ADR-007 Stage-6 ADR-authoring precedent).
**Decision:** An operations-module skill that needs a core safety-control reference consumes it **via-public-api by role-name** — it does NOT fork (copy) the control into a module-local file. The motivating case is `weekly-status-rollup` (operations) needing the 8-signal watermelon set (W1–W8) owned by `pmo-qa-auditor` (core): the roll-up names the set by role and consumes the verdict rule by reference rather than restating it. This reverses the Stage-4 plan's local-copy "for module independence" recommendation in favor of the Stage-5 design — the `operations → core` direction is pre-authorized accepted cohesion (a markdown-doc-link, not a code-import cycle, so it creates no new edge type per ADR-007), the two docs are already bidirectionally coupled through `metric-registry.md`, and a forked green-masking control diverges the moment the owner refines a signal (and would trip the shared-reference collision check). The cross-module-consumption analogue of ADR-023 (skill ↔ Anthropic sourcing): both express one-owner-of-truth on different axes.
**Reversibility:** MODERATE (CHEAP pre-application — it documents the posture the build already follows; crosses to MODERATE once additional operations skills cite it for their own core-control consumption; reversal is a superseding ADR plus, if a fork were ever chosen, materializing the copy and resolving the collision).
**File:** [ADR-028-operations-consume-core-safety-controls-via-public-api.md](ADR-028-operations-consume-core-safety-controls-via-public-api.md)

### ADR-029 — Memory SSOT model (corpus-SSOT for codified Knowledge within the four-type memory architecture)

**Status:** **Superseded by ADR-045** (the cross-surface memory contract reconciles this Knowledge cut into it; this record remains for audit trail). Originally Accepted (interim — resolved the Knowledge↔corpus cut of a larger memory architecture; refined + ratified by the workspace owner at the v2.05 / `35-agent-discipline-codification` Stage 9 review; authored at Stage 5/6 per the ADR-007 Stage-6 ADR-authoring precedent). Renumbered from a branch-local ADR-028 — the keystone ADR collided with the operations-consume ADR that claimed 028 on main during this release's engineering window.
**Decision:** Memory is organized by four types (Work / Knowledge / People / Learning), each with one SSOT surface under a no-shadow-SSOT invariant. This ADR resolves the Knowledge cut: codified Knowledge is corpus-SSOT; the Learning type (tacit/situated K5) is memory-store-SSOT; a Learning that generalizes into reusable Knowledge graduates into the corpus, after which its memory copy evicts to a pointer (VERIFY-CORPUS-gated, encode-then-evict). Trigger = Option C (Stage-13 Phase B-OPS executor + warn-mode deploy Check 36 backstop). The Work / People / operational SSOTs are named and deferred to the cross-surface memory-architecture cluster.
**Reversibility:** CHEAP for the Layer-1 contract (additive doc/governance + a warn-mode check); MODERATE for the operator-side Layer-2 memory eviction.
**File:** [ADR-029-memory-corpus-ssot-boundary.md](ADR-029-memory-corpus-ssot-boundary.md)

### ADR-033 — Methodology-conditional skill activation: dormant-under-non-matching-delivery-approach + release-side methodology-row sourcing

**Status:** Accepted (operator-adopted at the v2.11 / `04-ROLE-delivery-coverage` Collective Review scope-lock; authored at Stage 6 per the ADR-007 / ADR-028 / ADR-029 precedent). Consolidates CR-3 (parameterization sourcing) + CR-4 (activation convention) — two facets of one decision. Renumbered from a branch-local ADR-031 — main's autonomy-ceiling ADR claimed 031 during this release's engineering window; `check-adr-numbers.py` confirms 033 as the next gap-free number after 032.
**Decision:** A methodology-conditional role-Specialist gates on `delivery_approach` — ACTIVE when the configured approach matches its methodology, DORMANT with a non-fire notice otherwise, dormant-with-`[ASSUMPTION – CONFIRM]` when the field is absent (never a silent default-fire); dormant-under-non-match is correct behavior. The active skill sources its archetype parameterization from the canonical `methodology-archetype-matrix.md` row (release-side), NOT by adding a column to the high-blast-radius `_shared/five-model-variations.md`. First consumer: `pmo-release-train-engineer` (SAFe).
**Reversibility:** CHEAP at ship, trending MODERATE as future methodology-conditional skills adopt it.
**File:** [ADR-033-methodology-conditional-skill-activation.md](ADR-033-methodology-conditional-skill-activation.md)

## Distribution-architecture ADRs

### ADR-032 — Release-corpus public-vs-instance split: ship the capability, keep per-release content operator-instance

**Status:** Accepted (design rendered at the 62-close-out-registers Stage 5; operator-authorized design-only scope via D-1412-Scope 2026-06-19; authored at Stage 6 per the ADR-007 / ADR-017 / ADR-028 Stage-6 ADR-authoring precedent). Renumbered from a Stage-5 ADR-029 — the contiguous global sequence advanced (ADR-029/030/031 landed) during this release's engineering window; `check-adr-numbers.py` confirmed 032 as the next gap-free number.
**Decision:** Apply ADR-017's S1-Package-vs-S3-State cut to the release corpus — the maintainer's per-release content (RELEASE_LOG body, INDEX/DIGEST, notes/, plans/) is S3 operator-instance; the mechanism (templates, schema, pipeline, tools, deploy checks) plus a thin public surface (CHANGELOG + an empty RELEASE_INDEX seed) is S1 public. The operator-instance corpus root resolves via the ADR-017 canonical `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}` resolver, NOT the ADR-017-named orphan `PMO_INSTANCE_PATH`. Removal is HEAD-only (`.gitignore` + move); git-history scrub rejected (IRREVERSIBLE, force-push denied, content non-PII). Register template public / filled content instance (the close-out-register placement rule). Migration EXECUTION deferred to a follow-up issue per D-1412-Scope.
**Reversibility:** CHEAP (this ADR is design-only; the deferred migration is MODERATE — HEAD-only, `git revert`-reversible).
**File:** [ADR-032-release-corpus-public-vs-instance-split.md](ADR-032-release-corpus-public-vs-instance-split.md)

## Release-ops / capacity ADRs

### ADR-027 — Release-bundle risk-weighting keys on Release Class, not a new per-issue Tier field

**Status:** Accepted (operator-adopted at the v2.02 / `61-bundling-capacity-and-sizing-gates` Collective Review scope-lock 2026-06-17; authored at Stage 6 per the ADR-007 / ADR-028 Stage-6 ADR-authoring precedent).
**Decision:** Release-bundle risk-weighting keys on the already-shipped **Release Class** (`routine`/`novel`/`cross-cutting`/`hotfix`), NOT a new per-issue Tier field (the Autonomy Tier is per-action; `size:*` is complexity). Applied as a **multiplier** — `effective_pts = round_half_up(sum(member_pts) * class_weight)` — evaluated against the existing `§ 3 Step 5` target band with zero new disposition rows. Multiplier is chosen over an additive ceremony budget (not scale-invariant) and a per-issue ceremony-tag sum (requires a net-new backlog field). Weights live as the single numeric home in `[bundling].release_class_capacity_weights`; the doctrine cites them by role (parameterize-over-hardcode). Seeds `routine 1.0 / novel 1.15 / cross-cutting 1.3 / hotfix 0.9` are MEDIUM-confidence and `[CALIBRATE-AFTER-3]`; the mechanism is HIGH-confidence.
**Reversibility:** CHEAP at ship (additive — revert the release PR; every addition ships a default and no existing field/row/enum is mutated), trending MODERATE once a downstream size-bound enforcement gate + `release-planner` wire into `effective_pts` and the weights are recalibrated.
**File:** [ADR-027-release-bundle-risk-weight-keys-on-release-class.md](ADR-027-release-bundle-risk-weight-keys-on-release-class.md)

## Foundational ADRs in core (migrated from pmo-platform/governance/adr/)

### ADR-003 — Operating Model Composition

**Status:** Accepted (operator decision; migrated to core/ADRs/ on 2026-05-27).
**Decision:** Three foundational design choices for `operating-model.md` — (1) declared-primary-with-secondaries cardinality model for stage-to-skill mapping; (2) cite-not-duplicate citation discipline; (3) cross-reference pattern with the function-spine companion document (ADR-004). Cross-cutting governance — consumed platform-wide by the skill-build wave.
**Reversibility:** MODERATE.
**File:** [ADR-003-operating-model-composition.md](ADR-003-operating-model-composition.md)

### ADR-004 — Five-Function Spine and Cross-Cutting Process Flows

**Status:** Accepted (operator decision; migrated to core/ADRs/ on 2026-05-27).
**Decision:** Universal PMBOK Process Groups (Initiating / Planning / Executing / Monitoring & Controlling / Closing) decomposition; 13×3 archetype × stage variants matrix (applies to ALL delivery approaches, not release-only); 10-flow cross-cutting taxonomy. Cross-cutting methodology + execution-framework — consumed platform-wide.
**Reversibility:** MODERATE.
**File:** [ADR-004-five-function-spine.md](ADR-004-five-function-spine.md)

**Note:** ADR-001 / ADR-002 / ADR-005 are release-scope decisions migrated to [`../../release/ADRs/`](../../release/ADRs/) — release-pipeline-specific (Cross-PR Overlap Audit baseline policy, Modular Pipeline Stages Split, Append-pattern aware contention scoring).

## Authoring new ADRs

New ADRs go to the ADRs/ subdirectory of the module that authored the decision:

- Cross-module / platform-architecture decision → `core/ADRs/`
- Operations-specific decision (PMO workflow, project artifact) → `operations/ADRs/`
- Release-specific decision (pipeline mechanic, release-process discipline) → `release/ADRs/`

Decisions affecting multiple modules but rooted in core go to `core/ADRs/` with cross-references from the consumer modules.

### Repo-integrity authoring discipline

ADR files cross-reference issues constantly — `source_observations:` frontmatter,
`## Status` / `## Context` provenance lines, `## Related ADRs` — and two PR-time
`repo-integrity.yml` gates (defined in [`core/rules/git-workflow.md` §
Repository-Integrity Gates](../rules/git-workflow.md)) scan every changed markdown
file. Author every ADR to satisfy them up front, not by red CI:

1. **Reference issues as bare `#N`, never a full GitHub URL.** A
   `github.com/<owner>/pmo-platform/issues/N` URL embeds the operator handle and
   trips the **Depersonalization** gate; a bare `#N` carries no handle. Bare `#N`
   also keeps the reference resolvable-in-repo, which the **Issue-reference
   validity** gate requires (it rejects redirects, PR numbers, and 404s). One rule —
   bare `#N` — clears both gates.
2. **Declare the file-level marker once, near the top of the file.** Because ADRs
   place `#N` in frontmatter and body prose — locations the issue-ref gate does NOT
   treat as reference blocks (it recognizes only `### Issue References` /
   `### References` / `## Related` / `## Provenance` / `### Source(s)`) — add the
   marker as an HTML comment after the frontmatter and before the title:
   `repo-integrity: allow-issue-ref` (wrapped in an HTML comment). Note `## Related
   ADRs` is NOT the recognized `## Related` slug, so do not rely on heading
   placement — the file-level marker is the reliable mechanism.
3. **This composes with reference-durability** (same file, § Reference Durability):
   lead with self-describing prose and demote a bare `#N` to a provenance footnote,
   so the ADR still reads correctly after issues renumber or the repo moves. The
   `## Repository-Integrity Gates` section of `git-workflow.md` is the canonical
   worked example — it stacks all three markers at the top of the file.

The same discipline applies to skill `SKILL.md` and skill `references/*.md` files,
which are equally durable-corpus and equally scanned by both gates.

## Status enum

ADR `status:` follows the [Nygard convention](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

| Status | Meaning |
|---|---|
| Proposed | Decision drafted, not yet operator-ratified |
| Accepted | Operator-ratified at Collective Review or equivalent gate |
| Deprecated | Superseded by a later ADR; remains for audit trail |
| Superseded | Replaced; cite the superseding ADR in `## Status` block |

## Reversibility tier

ADR `Reversibility:` follows [reversibility-protocol.md](../specs/reversibility-protocol.md):

| Tier | Meaning |
|---|---|
| CHEAP | Undo in hours (e.g., CLI flag addition) |
| MODERATE | Undo in days, minor data loss (e.g., file re-classification) |
| EXPENSIVE | Undo in weeks, stakeholder impact (e.g., module renaming post-public-flip) |
| IRREVERSIBLE | Cannot undo (e.g., GitHub-published release with breaking semantics) |
