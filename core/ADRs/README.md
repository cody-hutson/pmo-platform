# Core Module Architecture Decision Records (ADRs)

Architecture Decision Records for the `core/` module of pmo-platform-v2. Each ADR captures a structurally-load-bearing decision with status, context, decision rationale, consequences, reversibility, and cross-ADR composition.

## Format

ADRs follow the canonical **[ADR schema](../schemas/adr-schema.md)** — the single source for the frontmatter field set and body-section contract. [ADR-005](../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) is the canonical worked exemplar of that schema.

**This file is a curated thematic document, NOT an index — and that is a decision, not an omission.** It groups core-scope records by the theme they belong to and links the ones a reader needs in that context; it has never enumerated the core module's full record set and is not expected to. Do not file "the core ADR README is missing records" as a completeness defect, and do not convert it to a generated index: flattening curation into enumeration would destroy the grouping that is this file's whole value, and would create a second hand-maintained surface of a fact each record already owns. The **release** module's README carries a generated index for exactly the opposite reason — it *was* an index, and it drifted. Both determinations are recorded in [ADR-117](../../release/ADRs/ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) and registered in [`release/references/standards/release-corpus-schema.md`](../../release/references/standards/release-corpus-schema.md) § Derived-Surface Contract. The authoritative, always-complete list of ADR numbers is the file set itself (`ls core/ADRs/ADR-*.md release/ADRs/ADR-*.md`), whose contiguity CI enforces.

## Naming convention

`ADR-NNN-kebab-case-title.md` where NNN is monotonically increasing across the platform (NOT per-module). ADR-003 + ADR-004 are foundational core-scope decisions migrated from an earlier governance location. ADR-001 + ADR-002 + ADR-005 (release-scope) live in [`../../release/ADRs/`](../../release/ADRs/). ADR-006..009 are module-restructure decisions. ADR-087 is the current highest core-scope number (see § Runtime-control / hook-class ADRs).

**Enforcement.** The platform-wide-unique + gap-free numbering rule is enforced in CI by `release/tools/check-adr-numbers.py` (the `adr-number-integrity` job in `.github/workflows/repo-integrity.yml`), which fails any PR that introduces a duplicate ADR number or a gap in the global sequence.

**Renumber log.** Core ADR-024 (`operations-consume-core-safety-controls-via-public-api`) → **ADR-028** on 2026-06-18, resolving a platform-wide collision with the earlier `release/ADRs/ADR-024-cross-release-impact-model.md` (which had correctly claimed 024). Release ADR-100 (`mode-r-disposition-set-fit-test`) → **ADR-099** on 2026-07-28, closing a gap rather than resolving a collision: 099 read as claimed by two sibling release branches when the record was authored, so the author stepped past it to 100 — but an unmerged claim does not bind the sequence. `main` topped out at ADR-098, making 099 the true next-free slot; merging at 100 would have landed the gap on `main`, where the gate would then fail every subsequent PR. First-to-merge takes the number and the other claimants renumber. Release ADR-099 (`event-log-payload-pipe-grammar`) → **ADR-100** on 2026-07-28 is that rule applying in the other direction: the `mode-r-disposition-set-fit-test` record above merged first and took 099, so this claimant — which had itself already moved 098 → 099 for the same reason — moved again to the new next-free slot. Core ADR-098 (`decision-audit-host-qa-auditor-mode-j`) → **ADR-101** on 2026-07-28 is the fourth claimant of that same contended slot resolving the same way: its branch parked awaiting a dependency while `portability-seventh-first-class-value` merged first and kept 098, after which the two records above claimed 099 and 100 — so on rebase `main` topped out at ADR-100 and 101 was the true next-free slot. That same record then moved a second time — Core ADR-101 (`decision-audit-host-qa-auditor-mode-j`) → **ADR-103** on 2026-07-29 — because the `agent-finops-intelligence` release merged during its continued park and its two records took 101 (`core/ADRs/ADR-101-finops-store-frozen-kind-versioning-exemption.md`) and 102 (`release/ADRs/ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md`); merge-first keeps the number, so the still-unmerged branch stepped to the recomputed next-free slot at 103 (`main` contiguous at `001..102`). Its two moves are one mechanism observed twice: a number is **allocated at authorship but claimed at merge**, so a record on a long-lived branch is exposed to every sibling that merges ahead of it, and pre-reserving a higher slot is no remedy because the checker fails a gap as readily as a duplicate. Each renumbered ADR's Status section carries the full provenance. ADR-111 (`adr-number-claim-binds-at-merge`) → **ADR-115** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 111; the record's Status section carries the provenance note. ADR-110 (`adr-section-set-and-durability-hygiene-carve-out`) → **ADR-114** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 110; the record's Status section carries the provenance note. ADR-112 (`adr-deciders-carve-out-is-name-only`) → **ADR-116** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 112; the record's Status section carries the provenance note. ADR-113 (`adr-index-derived-surface-and-scoped-conformance-claim`) → **ADR-117** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 113; the record's Status section carries the provenance note. ADR-114 (`adr-section-set-and-durability-hygiene-carve-out`) → **ADR-118** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 114. This is the **second** move of the record logged above as ADR-110 → ADR-114, so its lineage is `110 → 114 → 118` and its Status section carries one provenance note per hop. The second note was **not** written when this hop ran, and this sentence originally asserted that it was: the tool's idempotence guard keyed on the note's *shape* — any `NNN → NNN` pair — so it found the first hop's note, reported the write already done, and left the record naming a number a different mainline ADR holds; the verify step asked the same shape question and passed over the gap. The guard and the verify now key on **this move's** `old → new` pair, a double-move regression arm pins it, and the record was reconciled at this release's Stage-9 gate. The lesson generalizes past numbering: a predicate that matches the *form* of an audit record is not a check that the record is *there*. ADR-120 (`claude-md-composition-surface-recategorization`) → **ADR-122** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 120; the record's Status section carries the provenance note. ADR-120 (`domain-is-a-parameter-of-the-architect-role`) → **ADR-121** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 120; the record's Status section carries the provenance note. ADR-121 (`domain-is-a-parameter-of-the-architect-role`) → **ADR-123** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 121; the record's Status section carries the provenance note. ADR-121 (`status-fallback-k1-binding-k4`) → **ADR-125** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 121; the record's Status section carries the provenance note. ADR-122 (`sub-task-status-mirror-not-resynced`) → **ADR-126** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 122; the record's Status section carries the provenance note. ADR-123 (`domain-is-a-parameter-of-the-architect-role`) → **ADR-127** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 123; the record's Status section carries the provenance note. ADR-120 (`version-tags-are-retained-not-reaped`) → **ADR-121** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 120; the record's Status section carries the provenance note. ADR-121 (`version-tags-are-retained-not-reaped`) → **ADR-123** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 121. This is the **second** move of that record, so its lineage is `120 → 121 → 123` and its Status section carries one provenance note per hop. The first hop's log sentence had to be restored by hand: the tool's § Renumber log step rewrote the existing entry for this record in place rather than appending a second one, so the log briefly read as though the record had originally claimed 121. That hand-restore left a duplicated, truncated fragment of the sentence in place, which this merge removed — the record's own Status section was unaffected throughout, appending correctly one note per hop, so the file-set-derived surfaces stayed accurate while the prose log did not. ADR-123 (`version-tags-are-retained-not-reaped`) → **ADR-127** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 123; the record's Status section carries the provenance note. ADR-127 (`version-tags-are-retained-not-reaped`) → **ADR-128** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 127; the record's Status section carries the provenance note. ADR-127 (`close-class-is-a-declared-deliverable-value-conditioning-one-gate-spec`) → **ADR-128** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 127; the record's Status section carries the provenance note. ADR-128 (`close-class-is-a-declared-deliverable-value-conditioning-one-gate-spec`) → **ADR-129** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 128; the record's Status section carries the provenance note. ADR-129 (`lib-missing-guard-is-mode-coupled`) → **ADR-130** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 129; the record's Status section carries the provenance note. ADR-133 (`degraded-state-emit-contract`) → **ADR-134** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 133; the record's Status section carries the provenance note. ADR-133 (`a-gate-ships-armed-by-a-committed-default`) → **ADR-134** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 133; the record's Status section carries the provenance note. ADR-134 (`a-gate-ships-armed-by-a-committed-default`) → **ADR-135** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 134; the record's Status section carries the provenance note. ADR-134 (`hook-dependency-integrity-invariant`) → **ADR-135** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 134; the record's Status section carries the provenance note. ADR-135 (`hook-dependency-integrity-invariant`) → **ADR-136** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 135. This is the **third** move of that record, so its lineage is `133 → 134 → 135 → 136` and its Status section carries one provenance note per hop. Each hop was forced by a different sibling release merging ahead of it during a long-running run — the allocation rule behaving correctly under sustained contention, not drift. ADR-135 (`hook-dependency-integrity-invariant`) → **ADR-136** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 135; the record's Status section carries the provenance note. ADR-137 (`project-root-is-a-non-bin-sentinel`) → **ADR-139** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 137; the record's Status section carries the provenance note. ADR-142 (`surface-1-emit-provenance-not-existence`) → **ADR-148** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 142; the record's Status section carries the provenance note. ADR-142 (`block-destructive-022-governs-execution-capability`) → **ADR-144** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 142; the record's Status section carries the provenance note. ADR-143 (`cross-domain-bridge-writes-are-not-symmetric`) → **ADR-149** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 143; the record's Status section carries the provenance note. ADR-144 (`block-destructive-022-governs-execution-capability`) → **ADR-150** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 144; the record's Status section carries the provenance note. ADR-142 (`word-boundary-matching-is-engine-parity-not-syntax`) → **ADR-146** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 142; the record's Status section carries the provenance note. ADR-143 (`measurement-state-is-an-optional-merged-object-not-a-version-bump`) → **ADR-149** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 143; the record's Status section carries the provenance note. ADR-144 (`token-registry-conformance-is-family-aware`) → **ADR-150** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 144; the record's Status section carries the provenance note. ADR-145 (`anchor-resolution-is-a-surfacing-instrument-not-a-gate`) → **ADR-151** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 145; the record's Status section carries the provenance note. ADR-146 (`word-boundary-matching-is-engine-parity-not-syntax`) → **ADR-152** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 146; the record's Status section carries the provenance note. ADR-149 (`measurement-state-is-an-optional-merged-object-not-a-version-bump`) → **ADR-153** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 149; the record's Status section carries the provenance note. ADR-150 (`token-registry-conformance-is-family-aware`) → **ADR-154** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 150; the record's Status section carries the provenance note. ADR-143 (`provenance-is-the-eighth-label-group`) → **ADR-149** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 143; the record's Status section carries the provenance note. ADR-144 (`checkpoint-b-second-axis-is-measured-not-declared`) → **ADR-150** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 144; the record's Status section carries the provenance note. ADR-145 (`wave-width-is-a-second-checkpoint-b-output-not-a-verdict`) → **ADR-151** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 145; the record's Status section carries the provenance note. ADR-146 (`dry-run-predicts-apply-asserts-mode-branch-placement`) → **ADR-152** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 146; the record's Status section carries the provenance note. ADR-147 (`one-frontmatter-strip-bound-to-a-conformance-fixture`) → **ADR-153** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 147; the record's Status section carries the provenance note. ADR-148 (`arm-e-population-is-the-directory-never-the-manifest`) → **ADR-154** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 148; the record's Status section carries the provenance note. ADR-149 (`provenance-is-the-eighth-label-group`) → **ADR-155** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 149; the record's Status section carries the provenance note. ADR-150 (`checkpoint-b-second-axis-is-measured-not-declared`) → **ADR-156** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 150; the record's Status section carries the provenance note. ADR-151 (`wave-width-is-a-second-checkpoint-b-output-not-a-verdict`) → **ADR-157** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 151; the record's Status section carries the provenance note. ADR-152 (`dry-run-predicts-apply-asserts-mode-branch-placement`) → **ADR-158** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 152; the record's Status section carries the provenance note. ADR-153 (`one-frontmatter-strip-bound-to-a-conformance-fixture`) → **ADR-159** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 153; the record's Status section carries the provenance note. ADR-154 (`arm-e-population-is-the-directory-never-the-manifest`) → **ADR-160** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 154; the record's Status section carries the provenance note. ADR-142 (`release-plan-status-lifecycle`) → **ADR-151** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 142; the record's Status section carries the provenance note. ADR-151 (`release-plan-status-lifecycle`) → **ADR-155** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 151; the record's Status section carries the provenance note. ADR-155 (`release-plan-status-lifecycle`) → **ADR-161** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 155; the record's Status section carries the provenance note. ADR-162 (`system-of-record-per-mirrored-element`) → **ADR-164** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 162; the record's Status section carries the provenance note. ADR-163 (`split-predicate-gate-graduation`) → **ADR-166** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 163; the record's Status section carries the provenance note. ADR-164 (`written-is-not-repo-derivable`) → **ADR-167** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 164; the record's Status section carries the provenance note. ADR-165 (`bounded-by-relocation-not-by-discard`) → **ADR-169** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 165; the record's Status section carries the provenance note. ADR-170 (`partial-supersession-is-a-reciprocal-frontmatter-edge`) → **ADR-172** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 170; the record's Status section carries the provenance note. ADR-173 (`lifecycle-audit-trail-carrier-or-retirement`) → **ADR-177** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 173; the record's Status section carries the provenance note. ADR-174 (`instance-conformance-validator-surface`) → **ADR-178** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 174; the record's Status section carries the provenance note. ADR-175 (`cross-boundary-key-form-for-entity-and-tracker-identifiers`) → **ADR-179** by `release/tools/renumber-adr.py` at merge time, because the mainline already claimed 175; the record's Status section carries the provenance note.

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
| ADR-017 | **core** | distribution-architecture | operator directive + distribution analysis | 2026-06-07 |
| ADR-018 | **core** | declarative-workitem-type-model | data-architecture (WITL) | 2026-06-07 |
| ADR-019 | **core** | skill-suite-architecture-spine | operator-adopted + Stage 5 Solutioning | 2026-06-08 |

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
**Superseded in part:** Rule 2 (the V1/V2 workspace-rooted prefix tables → resolver bare-prefix workspace-root fallback) is superseded by ADR-085 — the fallback is retired in favor of one canonical link-resolution rule; the rewrite-map CLI (Rules 1/3/4/5) stands.
**File:** [ADR-009-rewrite-map-cli-design.md](ADR-009-rewrite-map-cli-design.md)

### ADR-012 — Roadmap-instance de-scope (amends ADR-006 + ADR-007)

**Status:** Accepted (operator directive 2026-06-02). **Location clause superseded-in-part by ADR-046 (2026-06-27, below)** — the "not tracked" decision stands; the per-instance *location* is now the shipped `/roadmaps/` folder.
**Decision:** Initiative-roadmap *instances* de-scoped from the tracked tree to operator-local authoring (`<OPERATOR_INSTANCE_ROADMAPS_PATH>`); the roadmap *framework* is retained as the reusable convention; the 4 in-repo enforcement surfaces (deploy.sh Check 24, gate-criteria-spec G3-13, Stage 13 forcing-function, Stage 5 cohesion-check) are dropped. Amends the roadmap-placement clauses of ADR-006/007 — all non-roadmap decisions stand.
**Reversibility:** MODERATE.
**File:** [ADR-012-roadmap-instance-descope.md](ADR-012-roadmap-instance-descope.md)

### ADR-046 — Roadmap-instance in-repo home — shipped /roadmaps/ folder + token-as-override

**Status:** Accepted (supersedes-in-part ADR-012's location clause + ADR-017's roadmaps placement in the operator-instance path family).
**Decision:** Roadmap instances get a single canonical in-repo home at repo-root `/roadmaps/` (folder + `README` tracked, instances git-ignored — the `analysis/` workspace pattern); the `<OPERATOR_INSTANCE_ROADMAPS_PATH>` token default moves to `${CLAUDE_WORKSPACE_ROOT}/pmo-platform/roadmaps` across the SSOT surfaces (depersonalization-spec registry + operator.toml.template) and remains the per-deployment override. Roadmaps leave the `personal/pmo-instance/` family by design (authored content ships in-repo like `analysis/`; runtime state stays operator-local). Preserves ADR-012's "instances not tracked" decision; includes a copy-migration for existing instances.
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

**Status:** Accepted (the declarative-workitem-type-model GO rendered the Tier-2 SCOPE CHANGE).
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

### ADR-019 — Specialists compose (not absorb) shared function-skills

**Status:** Accepted (operator-adopted 2026-06-06; ratified at the skill-suite-architecture-spine Collective Review scope-lock — that release activated Stage 5 with ≥2 Solutioning issues, so Collective Review fired as the ratification gate; milestone closed 2026-06-08. This ADR is the committed record of the adopted decision).
**Decision:** Role-decomposed skills are authored as **thin Specialists that COMPOSE the existing 22 function-decomposed skills** — they do NOT absorb or duplicate them; each function-skill remains the single source of its function ("compose, don't over-absorb"). A role MAY span several Specialists, but only when the **skill-boundary test** holds — all three conjuncts together: distinct trigger surface AND distinct write-scope AND distinct primary role. Composing shared skills via the Skill Chaining Protocol keeps routing depth ≤2 by construction (cascade rule C1); a role that re-implements shared logic violates the decision. Because the four named overlap pairs span all three modules, this is a cross-module platform-architecture decision.
**Reversibility:** MODERATE (Confidence HIGH; CHEAP pre-build, crossing to MODERATE at the first role-skill authored under the rule — from that point a reversal re-casts that skill's composition structure; no data migration, no schema change).
**File:** [ADR-019-specialists-compose-not-absorb.md](ADR-019-specialists-compose-not-absorb.md)

### ADR-023 — Skill sourcing-coupling posture: own-with-harvest default; guarded-wrap exception

**Status:** Accepted (ratified at the comms-writer/artifact-generator-anthropic-offload-refactor Collective Review scope-lock — the Stage 5 N-way-consistency gate per § Status enum).
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

### ADR-017 — Distribution architecture: four lifecycle surfaces, version-posture acquisition, and package multiplicity over shared config/state

**Status:** Accepted (operator distribution-perspective directive 2026-06-07, at the operator's PR review; authored per the core-ADR convention the ADR-013 / ADR-014 / ADR-016 records followed).
**Decision:** Records the distribution decision spine three existing initiative anchors implement but none cite. Four layered decisions: (1) classify every file by the four install/update-lifecycle **surfaces** — S1·Package (versioned repo checkout), S2·Config (`operator.toml` at XDG config), S3·State (operator-instance content, never in the package — ADR-012), S4·Runtime deployment (`~/.claude/` mirror, derived from S1) — an orthogonal cut across the CLAUDE.md Platform/Operations/Bridge layers with the load-bearing invariant *S1 is the only versioned surface; S4 is derived and always regenerable*; (2) clone-path and install-path are both first-class, distinguished only by version-pinning posture; (3) the package surface is multiply-instantiable over a singular shared config + state, with pipeline-mediated promotion between version postures; (4) operator content stays workspace-relative, only derived internals go to XDG state/cache (RECOMMENDED). `operator.toml` (S2) is the single seam telling S1's tools where S3 lives and how to produce S4.
**Reversibility:** MODERATE (Decisions 1/2/4 HIGH-confidence; Decision 3's invariant HIGH, its recommended application MEDIUM — classification/posture decisions, revert = editing this ADR and its citing docs, no data migration).
**File:** [ADR-017-distribution-architecture.md](ADR-017-distribution-architecture.md)

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

## Terminology / vocabulary ADRs

### ADR-049 — Canonical initiative / roadmap / milestone vocabulary + initiative→epic/project label mapping

**Status:** Accepted.
**Decision:** Canonicalize `Initiative` (cross-milestone grouping theme, NOT a hierarchy level) and `Roadmap` (architected path across one-or-more initiatives; one-per-initiative is the default) as glossary terms; correct Appendix B's "Initiative not modeled"; reconcile the framework's "one initiative" scope to the canonical default-not-limit meaning; map the retired `initiative:*` label namespace to the live `epic:*` / `project:*` grouping labels. The glossary is SSOT for the wording; the framework + label-taxonomy cite, never re-define.
**Reversibility:** MODERATE (governance-vocabulary ripple into framework + label-taxonomy; runtime = none — no code consumes the terms).
**File:** [ADR-049-canonical-initiative-roadmap-vocabulary.md](ADR-049-canonical-initiative-roadmap-vocabulary.md)

## Pipeline / solutioning-discipline ADRs

### ADR-062 — Substrate-vs-canonical precedent (canonical-spec edit wins; substrate body preserved)

**Status:** Accepted (operator-ratified at the `67-spoke-execution-safety` Collective Review scope-lock; authored at Stage 6 per the ADR-007 / ADR-028 / ADR-029 Stage-6 ADR-authoring precedent).
**Decision:** For a work item that cites a **substrate-level affected file**, a canonical-spec edit at the file's governed home WINS over mutating the substrate citation or the issue body. A substrate reference — a cross-repo `originally #NNN` public-flip migration marker (whose local number may or may not resolve in this repo) or a body-level raw path — is a pointer to be translated, not a surface to be edited; issue bodies remain historical record (directional, not authoritative). The rule is enforced at Stage-5 A1 scope-assessment by the new **Phase A1.5** (canonical-surface enumeration + cross-repo-citation translation) in `stage-05-solutioning.md`. Reflexive cutover — applies to releases entering Stage 5 after the introducing-release merge SHA; the introducing release is exempt.
**Reversibility:** CHEAP (additive — a new ADR record + one Stage-5 phase block + this index line; `git revert`-able with no data migration).
**File:** [ADR-062-substrate-vs-canonical-precedent.md](ADR-062-substrate-vs-canonical-precedent.md)

### ADR-090 — Structural/path-move blast-radius mode extends blast-radius.sh (qualifies ADR-068); soft gate, shadow → warn → enforce

**Status:** Accepted (operator-ratified at the Stage-5 D-gate for milestone `blast-radius-scan-correctness`; authored at Stage 6 per the ADR-062 / ADR-068 Stage-6 ADR-authoring precedent).
**Decision:** The structural/path-move mode (`blast-radius.sh --mode=structural <old-path>` — "who hard-codes this PATH?", the consumer class both existing tracers are blind to, and the exact miss behind #230 → RCA #3118) is an **additive mode branch that EXTENDS `blast-radius.sh`**, not a new sibling. This **qualifies ADR-068** with the reusable boundary **"same-scanner → extend; different-scanner → sibling"**: ADR-068 shipped the domain fan-out as a sibling because it needs a *different scanner*; the structural query reuses the doc scanner unchanged and needs only a *different query over the same scan list*, so it extends without contradicting ADR-068. The merge-gate (**SR-G5** in `stage-05-solutioning.md` §7.2, Phase A3.3 sweep) is a **soft** update-or-accept-per-consumer criterion (a `grep -F` literal match over-includes reconcilable non-consumers, so a hard block would false-positive-stop a legit merge), rolled out **shadow → warn → enforce** and **shipping in shadow**.
**Reversibility:** CHEAP (mode code — additive) / MODERATE (gate wire-in — a merge-gate criterion; commit-split isolates it, ships inert in shadow).
**File:** [ADR-090-structural-path-move-mode-extend-vs-sibling.md](ADR-090-structural-path-move-mode-extend-vs-sibling.md)

## Runtime-control / hook-class ADRs

### ADR-087 — `Stop`-hook agent-loop re-entry as a hook class (ship-inert activation boundary)

**Status:** Proposed (flips to Accepted at the operator's plan-review / activation gate; verify in-file, never from milestone closure).
**Decision:** Agent-loop re-entry via a `Stop` hook returning `{"decision":"block"}` is adopted as a **second hook shape**, distinct from the `PreToolUse` *gate* shape every prior hook uses — a gate constrains a pending action, a re-entrant hook consumes agent turns. `SessionEnd` is rejected for this purpose (cleanup-only; cannot re-enter the loop). Admitted under four standing obligations: (1) `Stop` + `decision:block` is the sanctioned re-entry mechanism; (2) a once-per-session idempotence sentinel is **mandatory** and MUST be written *before* the block decision, because `Stop` fires per assistant turn and the re-entered work's own final turn would otherwise loop; (3) fail-open on every path — a hook that can restart the agent must never wedge a session; (4) **ship-inert activation boundary (D2(a))** — the script and its settings-template registration ship, the activation does not, and no live settings file is modified by the release. Governs the hook *class*, not what any instance does with the turn it takes.
**Reversibility:** CHEAP as shipped (additive + inert; revert changes no session behaviour because none changed on the way in) / MODERATE at activation (two reversible operator edits, but it registers workspace-wide the first hook able to re-enter the agent loop).
**File:** [ADR-087-stop-hook-agent-loop-re-entry-class.md](ADR-087-stop-hook-agent-loop-re-entry-class.md)

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

## Cross-cutting pattern index

Records in both modules repeatedly answer **the same design question at different triggers**. They do not conflict — they converge — but convergence is invisible from inside any one of them. A reader who arrives at [ADR-127](ADR-127-domain-is-a-parameter-of-the-architect-role.md) has no way to learn that [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) already governs the general case; ADR-127 is in fact the record that says so, calling ADR-094 *"the general form of this record's default, on a different trigger."* This section is that missing edge and nothing more. It adds no decision, supersedes nothing, and no record below was edited to appear here.

**It is curated, not projected — and that is a decision, not an omission.** Cluster membership derives from neither an ADR's filename nor its frontmatter: the field set carries no cluster key, so there is nothing for [`generate-adr-index.py`](../../release/tools/generate-adr-index.py) to project *from*, and sourcing one would mean editing records to add a field. The clusters also span both modules while that projector's population is `release/ADRs/` alone, so a projected pattern index would render **partial clusters** — and a reader who sees a two-member cluster concludes that is the cluster. Omission would become misinformation. This determination is registered under this file's existing row in [`release/references/standards/release-corpus-schema.md`](../../release/references/standards/release-corpus-schema.md) § Derived-Surface Contract, per [ADR-117](../../release/ADRs/ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) Decision (2).

### Membership test (PCM)

A set of records is indexed here only when **all four limbs** hold. The relational vocabulary is not invented for this section: it is [`release/ADRs/README.md`](../../release/ADRs/README.md) § ADR composition's own composition-edge rule — *"only when one record actually extends, supersedes, or is consumed alongside another"* — applied at a new cardinality.

| Limb | Requirement | Why it is there |
|---|---|---|
| **PCM-1 — Question** | The cluster is stated as one interrogative sentence, carried verbatim in the entry. | A noun-phrase label ("extend-not-create") cannot be tested against a candidate record. A question can. |
| **PCM-2 — Answer at a distinct trigger** | Each member's own `## Decision` answers PCM-1 at a named trigger no other member occupies, and the entry quotes **≤15 words** from that section as its answer. | Converts an unverifiable semantic judgment into a checkable one. |
| **PCM-3 — Three or more members** | The cluster holds **at least three** records. | At two, mere tag-similarity — a pair sharing ≥2 tags that are not corpus-generic — admits anywhere from a couple of dozen to well over two hundred candidate pairs, the figure moving entirely with which tags one discounts as generic. No published rule fixes that cut, and none separates a handful of the resulting pairs from the rest, so a two-member floor is unmaintainable by anyone but its author. |
| **PCM-4 — Declared anchor** | At least one member names another **in its own body** under an extends / supersedes / consumed-alongside relation. | Keeps a cluster at least partly self-declared rather than wholly inferred. |

PCM-2 is what makes an entry maintainable without a tool: a reader validates one membership by reading one quoted clause against one question, with no population to re-derive and no second file to consult.

**This test currently carries no demonstrated negative, and that is a recorded limitation of it.** An earlier draft of this section excluded a `canonical-home-placement` cluster of [ADR-010](ADR-010-secrets-handling-policy-substrate.md), [ADR-065](ADR-065-health-rag-band-canonical-home.md) and [ADR-067](ADR-067-stage-gate-eval-set-home.md), and offered that exclusion as proof the test discriminates. **The exclusion was wrong on this section's own criteria.** It rested on PCM-4, but PCM-4 is a *cluster-level* limb: ADR-067 names ADR-065 in its own body, so the set clears PCM-4 whether or not ADR-010 anchors anything. Its only remaining argument was that ADR-010 carries `file-location` where the other two share `canonical-home` + `placement-correctness` — a **tag** argument, which § What this index does not claim expressly forbids as a membership rule. Read as PCM-2 actually requires, against each record's own `## Decision`, ADR-010 passes. The cluster is therefore **indexed below**, and nothing replaces it as a worked negative.

**What follows from that, stated rather than hedged: PCM is demonstrated to be *necessary*, and its sufficiency is asserted rather than shown.** This section publishes no worked negative — no candidate is shown here failing a limb, with its evidence, the way each indexed cluster is shown clearing them — so a reader should treat the four limbs as a floor every indexed cluster clears, not as evidence that some plausible cluster would fail them. Membership decisions did decline candidates, and the declines are real rather than notional. Of the **eight** records tagged `extend-before-create`, **six** are indexed: [ADR-145](../../release/ADRs/ADR-145-subtype-payload-vocabulary-registry-disjoint-from-the-source-enum.md) and [ADR-153](ADR-153-measurement-state-is-an-optional-merged-object-not-a-version-bump.md) were read against this cluster's question and not admitted. PCM-3 excludes a two-member set by construction, and the candidate roster this index was drawn from carried **seven** of them, against indexed cluster sizes of 10 · 6 · 3 · 5 · 3. And citing an anchor is not membership — **8 of the 13** records naming ADR-094, **9 of 13** naming ADR-018, and **3 of 5** naming ADR-117 are not indexed. Those decisions live in the pipeline record rather than in this section, which is exactly what leaves the test without an inspectable negative here. Manufacturing a fresh exclusion to close this gap would reproduce exactly the defect the paragraph above records, so the gap is left open and named instead.

### The indexed clusters

Each entry states its question, its anchor record, and one ≤15-word quote per member taken verbatim from that member's `## Decision`.

#### Extend an existing surface, or build beside it?

> *Existing infrastructure plausibly covers this capability — do we extend it, or place a net-new surface beside it?*

**Anchor:** ADR-094 states the general form and is named as such by ADR-127. ADR-090 supplies the discriminating test the family reuses. **The cluster is the fork being decided explicitly against a stated bar — not a standing preference for extension:** three members resolve to *net-new* or *no new surface*, with the reason recorded.

| Record | Trigger | Decision (verbatim, ≤15 words) |
|---|---|---|
| [ADR-011](../../release/ADRs/ADR-011-analysis-class-methodology-design-treatment.md) | a Stage-5 persona card | *"Extend the Stage 5 (Principal Engineer — Architecture Assessment) persona card in release-personas.md"* |
| [ADR-057](ADR-057-change-domain-best-practice-self-bundled.md) | a shared best-practice guide | *"No shared `domain-best-practices/change.md` is created"* |
| [ADR-090](ADR-090-structural-path-move-mode-extend-vs-sibling.md) | a second query over one scanner | *"Same-scanner → extend; different-scanner → sibling."* |
| [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) | any infrastructure surface (the gate itself) | *"a net-new surface with no recorded determination is not design-complete"* |
| [ADR-103](ADR-103-decision-audit-host-qa-auditor-mode-j.md) | a new skill versus a new mode | *"The decision-audit capability hosts as `Mode J — Decision-Health Audit` in `core/skills/pmo-qa-auditor`, sibling to Mode I"* |
| [ADR-104](ADR-104-complementary-reference-pair-registration.md) | a registration mechanism | *"net-new registry file because in-place registration is infeasible"* |
| [ADR-127](ADR-127-domain-is-a-parameter-of-the-architect-role.md) | an architect-role axis | *"Domain is a parameter of the architect role, exactly as altitude is."* |
| [ADR-132](ADR-132-initiative-coextension-is-an-advisory-conjunct-on-check-55.md) | a CI check | *"Extend Check 55 with a third invariant `H3`; do not create a sibling check"* |
| [ADR-134](ADR-134-degraded-state-emit-contract.md) | an emitter family | *"Extend the existing emitter family; do not parallel it."* |
| [ADR-151](ADR-151-anchor-resolution-is-a-surfacing-instrument-not-a-gate.md) | an issue-reference gate | *"Extend-before-create sets the bar at necessary, not plausible, and it does not reach here"* |

#### Is this second surface derived from the fact's owner?

> *A fact already has an owner — is the second surface carrying it derived from that owner, and where it cannot be derived completely, is it built at all?*

**Anchor:** ADR-105, which ADR-117 names *"the founding record of the Derived-Surface Contract this surface registers under."*

| Record | Trigger | Decision (verbatim, ≤15 words) |
|---|---|---|
| [ADR-071](ADR-071-acceptance-assertion-type.md) | a Stage-8 verdict enum | *"the six-value Stage-8 verdict enum is a deterministic PROJECTION of the two judgments"* |
| [ADR-105](../../release/ADRs/ADR-105-release-corpus-normalization.md) | the release ledgers | *"The projector emits ENTRIES, never FILES"* |
| [ADR-117](../../release/ADRs/ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) | the release ADR index | *"Nothing in the table is hand-typed, and a hand-edited cell fails `--verify`"* |
| [ADR-119](../../release/ADRs/ADR-119-selftest-coverage-is-discovered-with-a-committed-manifest-floor.md) | a CI coverage set | *"The covered set is DISCOVERED from a declared scope, never enumerated."* |
| [ADR-171](ADR-171-status-surface-authority-and-flip-ownership.md) | an ADR's own `## Status` body | *"The `## Status` body is a projection of it."* |
| [ADR-172](ADR-172-partial-supersession-is-a-reciprocal-frontmatter-edge.md) | a candidate new index column | *"Partial-supersession state is NOT projected into the derived index"* |

#### Does this predicate range over the subject it claims to judge?

> *Over what population does this predicate actually range, and does that population match the subject the criterion declares?*

**Anchor:** ADR-154 cites ADR-144. This is the thinnest cluster in the index — it clears PCM-4 on a single edge.

| Record | Trigger | Decision (verbatim, ≤15 words) |
|---|---|---|
| [ADR-072](../../release/ADRs/ADR-072-region-scoped-av-invariant-verification.md) | a code-versus-comment assertion | *"A `region: code` assertion never sees comment bytes"* |
| [ADR-144](../../release/ADRs/ADR-144-g1-03-admits-a-second-evidence-shape.md) | a gate's evidence criterion | *"reads both from the `### Evidence` section only"* |
| [ADR-154](ADR-154-token-registry-conformance-is-family-aware.md) | a token-registry conformance gate | *"Conformance over this vocabulary is family-aware, and any future gate over it must be."* |

#### Extend the Work-Item kernel, or found a new machine?

> *A new capability attaches to the Work-Item kernel — does it extend that kernel additively, or re-found its base machine?*

**Anchor:** ADR-018. Its three grammar-altitude extensions each state the relation in their own bodies — *"ADR-018's kernel disciplines bind it."*

| Record | Trigger | Decision (verbatim, ≤15 words) |
|---|---|---|
| [ADR-018](ADR-018-work-item-type-layer.md) | the kernel itself | *"they do not re-found the base machine"* |
| [ADR-059](ADR-059-plan-type-open-discriminator.md) | a plan-type discriminator | *"Lifecycle is a base-machine extension, not a new machine."* |
| [ADR-069](ADR-069-methodology-pack-composing-unit.md) | the composing unit | *"Adopt Option 1 — a methodology pack is the composing unit."* |
| [ADR-070](ADR-070-methodology-pack-composition-grammar.md) | the composition grammar | *"Widen the type-pack meta-schema with a pack-composition layer — additive and backward-compatible"* |
| [ADR-077](ADR-077-cross-cutting-control-field-layer.md) | a cross-cutting control-field layer | *"Meta-schema stays v1"* |

#### Is an existing surface already this fact's home, or must one be placed?

> *This fact needs exactly one canonical home — is some existing surface already that home, or does a home have to be placed for it?*

**Anchor:** ADR-065, which ADR-067 names in its own `## Related ADRs` as *"the immediately-preceding placement-correctness ADR."* This is the cluster whose exclusion was falsified and then conceded — see § Membership test above. It is indexed on PCM read against each record's `## Decision`, **not** on the `canonical-home` + `placement-correctness` tag pair two of its three members happen to share; that pair is a discovery aid here exactly as § What this index does not claim describes.

| Record | Trigger | Decision (verbatim, ≤15 words) |
|---|---|---|
| [ADR-010](ADR-010-secrets-handling-policy-substrate.md) | a net-new policy with no prior owner | *"The secrets-handling policy lives at `core/standards/secrets-handling-policy.md` as a single file"* |
| [ADR-065](ADR-065-health-rag-band-canonical-home.md) | a metric definition whose ownership was contested | *"It is retained as the owner; the bands are NOT moved."* |
| [ADR-067](ADR-067-stage-gate-eval-set-home.md) | a new content class under an existing skill | *"one directory per gate — and are kept OUT of eval-writer's demonstration `evals.json`"* |

### What this index does not claim

**It is incomplete by construction, and that is the safe direction.** It indexes clusters that pass PCM — never *all* convergent patterns in the corpus, and never *all* members of an indexed cluster. Three consequences follow, stated rather than hedged:

- **There is no automated maintenance mechanism for this section, and none can exist** — the same conclusion ADR-117 Decision (3) reached about this file. A lint requiring every new ADR to join a cluster would force a membership PCM-1 and PCM-2 may not support, manufacturing convergence to satisfy a gate. The `≥3` floor and the per-entry quote are the whole of the bound.
- **A record merged after this section was written does not appear in it until a human adds it.** The section therefore degrades toward *incomplete-but-correct*, never toward *incorrect*: a missing member leaves an entry short, not wrong. The only edit that could make it wrong is a change to a quoted clause — and PCM-2 puts every clause beside its source, where one read settles it.
- **Where a tag approximates a cluster it is a discovery aid, never the membership rule.** Measured: **no cluster in this index has a single tag held by all of its members** — the `work-item-type-layer` tag, for instance, is absent from ADR-018, the kernel its four carriers extend. The rule cuts both ways, and this section's own history is the worked case: an earlier draft *excluded* a record on a tag mismatch, and that exclusion is the one the § Membership test paragraph above records as falsified.

**Baseline.** Derived by full-body read against a corpus of **171** records (`core/ADRs/` 117 + `release/ADRs/` 54) on 2026-09-01, with the `canonical-home-placement` cluster admitted on 2026-09-02 after its exclusion was falsified at Dev Testing. Re-derive the denominator with `ls core/ADRs/ADR-*.md release/ADRs/ADR-*.md` rather than trusting that number after a merge; re-derive the roster by reading this section's own `####` entries rather than trusting any count stated elsewhere.

## Authoring new ADRs

New ADRs go to the ADRs/ subdirectory of the module that authored the decision:

- Cross-module / platform-architecture decision → `core/ADRs/`
- Operations-specific decision (PMO workflow, project artifact) → `operations/ADRs/`
- Release-specific decision (pipeline mechanic, release-process discipline) → `release/ADRs/`

Decisions affecting multiple modules but rooted in core go to `core/ADRs/` with cross-references from the consumer modules.

### Repo-integrity authoring discipline

ADR files cross-reference issues constantly — `source_observations:` frontmatter,
`## Status` / `## Context` provenance lines, `## Related ADRs` — and the PR-time
durable-corpus gates (the `repo-integrity.yml` gates defined in
[`core/rules/git-workflow.md` § Repository-Integrity Gates](../rules/git-workflow.md),
plus the reference-durability detector per
[`reference-durability-standard.md`](../standards/reference-durability-standard.md))
scan every changed markdown file. Author every ADR to satisfy them up front, not by
red CI:

1. **Reference issues as bare `#N`, never a full GitHub URL.** A
   `github.com/<owner>/pmo-platform/issues/N` URL embeds the operator handle and
   trips the **Depersonalization** gate; a bare `#N` carries no handle. Bare `#N`
   also keeps the reference resolvable-in-repo, which the **Issue-reference
   validity** gate requires (it rejects redirects, PR numbers, and 404s). One rule —
   bare `#N` — clears both gates.
2. **Put the reference in a sanctioned home — not behind the file-level marker.** An
   ADR has exactly two sanctioned homes for a provenance `#N`: the
   `source_observations:` frontmatter block, and a designated `## References` section
   placed after `## Related ADRs`. Every line in that section pairs the number with a
   summary noun phrase, so the meaning survives a renumber. The issue-ref gate
   recognizes `Issue References` / `References` / `Related` / `Provenance` / `Source` /
   `Sources` / `Source(s)` as reference-block headings, at any level; `## Related ADRs`
   is deliberately not among them, because a bare `#N` is prohibited there outright —
   use `ADR-NNN` form for cross-ADR links. The four placement zones and the full rule
   are stated once, in
   [`adr-authoring-guide.md` § Issue references in ADRs](../standards/adr-authoring-guide.md).
   The file-level marker `repo-integrity: allow-issue-ref` (wrapped in an HTML comment)
   is a **rare exception**, not the reliable mechanism: it is warranted only when the
   file *displays* an issue-reference construct as its subject matter (or its numbers
   are synthetic / out-of-repo) **and** neither relocation into a reference block nor
   an inline summary is available. Carrying provenance is not demonstration, so an ADR
   essentially never qualifies. A marker declared under that criterion carries a
   trailing rationale inside the comment naming which limb applies.
3. **This composes with reference-durability** (same file, § Reference Durability):
   lead with self-describing prose and demote a bare `#N` to a provenance footnote,
   so the ADR still reads correctly after issues renumber or the repo moves. The
   `## Repository-Integrity Gates` section of `git-workflow.md` is the canonical
   worked example — it stacks all three markers at the top of the file.

**Every PR-time durable-corpus gate and its override marker.** The two gate families
(`repo-integrity` and `reference-durability`) carry the following per-file override
markers — each an HTML comment declared once near the top of the file. Authoring
discipline item 2 above generalizes to any of them: when an ADR (or skill file)
legitimately carries a flagged construct, declare the matching marker up front rather
than letting CI go red. The one construct with **no** override marker is the bare-`#N`
positional rule (last row) — its only remedy is to rewrite the reference inline.

| Marker | Family | Suppresses (what the gate would otherwise flag) |
|---|---|---|
| `<!-- repo-integrity: allow-issue-ref -->` | repo-integrity | **The whole issue-ref gate, for the whole file** — placement *and* validity. The gate's override test runs at file scope before its per-line loop, so once the marker is present a 404, a redirect, a transferred issue, a pull-request number and a deprecated `IMP-NNN` all pass unexamined. There is no residual validity net behind it. That blast radius is why the marker is a rare exception under the two-limb criterion (see authoring discipline item 2), never a default remedy |
| `<!-- repo-integrity: allow-memory-ref -->` | repo-integrity | A reference to an operator-memory name (a `feedback_*` / `reference_*` / `project_*` memory) in durable-corpus prose — used when a memory is deliberately named as provenance / a composes-with sibling |
| `<!-- repo-integrity: allow-dead-file-ref -->` | repo-integrity | A `[text](path)` link / `![alt](path)` image whose target file or `#anchor` is missing (used for a deliberately-forward or intentionally-absent target) |
| `<!-- repo-integrity: allow-depersonalization -->` | repo-integrity | Operator/collaborator identifying values in a `core/`/`release/`/`operations/`/`packages/` file (rare; personal data is normally kept out per the secrets policy) |
| `<!-- reference-durability: allow-link -->` | reference-durability | Markdown link sequences (Class L) — for a file that legitimately carries summarized in-repo links |
| `<!-- reference-durability: allow-version-ref -->` | reference-durability | Version-cutover apparatus (Class V) — prose that a rule applies to releases after a given version, or that a version is itself exempt |
| `<!-- reference-durability: allow-url -->` | reference-durability | Raw GitHub issue/PR/milestone URLs (Class U) — distinct from `allow-link` so a links-carrying file does not silently also suppress the raw-URL prohibition |
| **(no marker — bare-`#N` positional rule)** | reference-durability | NONE — a bare issue reference OUTSIDE a recognized reference block, or content-free INSIDE one, **cannot** be marker-suppressed. The only remedy is to rewrite it inline: move it into a reference block with a summary noun phrase, or de-reference it in prose so the meaning survives the number's renumber. |

The same discipline applies to skill `SKILL.md` and skill `references/*.md` files,
which are equally durable-corpus and equally scanned by all of these gates.

## Status enum

ADR `status:` follows the [Nygard convention](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

| Status | Meaning |
|---|---|
| Proposed | Decision drafted, not yet operator-ratified |
| Accepted | Operator-ratified at the **Stage 13 Close ratification beat** (Phase A13), which is where the `Proposed → Accepted` transition is performed; for releases predating that beat, at the release's Collective Review or equivalent gate |
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
