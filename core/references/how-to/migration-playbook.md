<!-- reference-durability: allow-link -->
# Migration Playbook

The proven steps, sequencing, verification, and rollback for a **corpus or structural migration** in this repository — a path restructure, a directory rename, a module-subtree move, a re-versioning, or a single-source consolidation. Grounded in this repo's own migration history; it teaches the *current* `core/` / `operations/` / `release/` modular-monolith structure as the target and cites prior migrations as the evidence base.

This is a **how-to** — directions toward a result. It lives in `core/` because migration is **cross-cutting**: the intake front door (`operations/`) elicits migration-type work, and the release pipeline (`release/`) executes it — both consume this playbook. Per [`../../disciplines/diataxis-framework.md`](../../disciplines/diataxis-framework.md), the Diátaxis quadrant informs this doc's *tone and structure* (how-to: numbered procedure, sequencing, verification) but does **not** determine its file location; placement follows the module-boundary organization in [`../../README.md`](../../README.md).

---

## When this fires

A migration = an operation that **moves or renames durable-corpus files**, or restructures the directory tree, or re-versions the platform. Concretely:

- relocating one or more durable-corpus `.md` files across directories;
- renaming a directory or moving a module subtree;
- a re-versioning (changing the platform's version lineage);
- a single-source consolidation (collapsing duplicated content to one canonical home with deploy-managed mirrors).

It does **not** fire for an in-place content edit that changes no path — editing a file's body without moving it is not a migration, and running the migration machinery for it is ceremony (the non-ceremony omission signal per [`../../disciplines/decision-discipline.md`](../../disciplines/decision-discipline.md)).

**Composes with [`stage-05-solutioning.md` Phase A3.2](../../../release/references/pipeline/stage-05-solutioning.md).** When a migration is designed in the pipeline, Phase A3.2 requires the complete six-form reference enumeration per [`doc-corpus-reorg-ref-forms.md`](../../../release/references/protocols/doc-corpus-reorg-ref-forms.md). This playbook is the **HOW** (the procedure); A3.2 is the **completeness gate** (the exit check that the six-form table is present and grounded). The playbook does not duplicate A3.2 — it invokes it at the right step.

---

## The 4 phases

### 1. Steps (the migration procedure)

1. **Pre-move survey — map the blast radius.** Before moving anything, enumerate the inbound references to every file in the moving set. Run [`blast-radius.sh`](../../../release/tools/blast-radius.sh) for the static inbound-reference fan-out. The survey answer is the scope of the rewrite the migration commits you to.
2. **Author the six-form reference enumeration.** For a doc-corpus reorg, emit the complete F1–F6 table per [`doc-corpus-reorg-ref-forms.md`](../../../release/references/protocols/doc-corpus-reorg-ref-forms.md): F1 module-rooted literal · F2 relative-inbound · F3 root-escape · F4 mover-internal-outbound · F5 retained-sibling→mover · F6 governed mirror-pair. Each form gets its sweep command and a per-occurrence disposition (REWRITE / N/A / MIRROR-SYNC). This is what makes the rewrite **complete-by-construction** rather than discovering missed forms after the move.
3. **Execute the moves.** Move/rename the files. Prefer a tool-assisted move that preserves history where the VCS supports it.
4. **Rewrite the references (F1–F6).** Apply the dispositions from step 2 — rewrite every REWRITE-form occurrence; sync every MIRROR-SYNC occurrence. The `blast-radius.sh` static survey covers inbound refs to a static target; the six-form enumeration covers the orthogonal *moving-set outbound* surface (mover-internal-outbound, root-escape past the module boundary) that a static inbound scan cannot reach.
5. **Byte-identity check on every mirror.** If the migration touched a single-sourced file with deploy-managed mirrors, confirm each injected copy is byte-identical to its canonical source (the `TEMPLATE_SYNC_MAP` injection mechanism in [`deploy.sh`](../../deploy/deploy.sh)). A mirror that drifted from canonical is a migration that is not yet done.

### 2. Sequencing

- **Substrate-first, blast-radius-ascending.** Migrate the files with the fewest inbound references first; the most-referenced substrate last, once the dependents have settled. This minimizes the window in which a reference points at a half-migrated target.
- **Single-writer per file.** One migration writer per file at a time. When two migration efforts run on a shared release branch concurrently, they contend on the same git surface (rebase / staging / partial-staging / branch-checkout races) — serialize them or isolate them per the concurrency safeguards in [`../../disciplines/concurrency-safeguards.md`](../../disciplines/concurrency-safeguards.md).
- **Claim a version number LATE.** For a re-versioning migration, do not pin the new version number at plan time — claim it at the release-execution stage. A version pinned early collides when another release claims the same number first; the immutable PR title then stands as a misleading historical record. The version is claimed at the latest responsible moment, against the live unclaimed set.

### 3. Verification

- **`deploy.sh --check` is the migration gate.** Run it after the rewrite. The load-bearing checks for a migration:
  - **Check 14 (doc-link maintenance)** — confirms no link points at a moved-away path; a relocated or typo'd scan surface fails loud rather than reading GREEN ([`../../rules/doc-link-maintenance.md`](../../rules/doc-link-maintenance.md)).
  - **Check 13 / 13b (shared-reference collision + byte-identity)** — confirms single-sourced files and their mirrors are consistent; 13b catches an *unregistered* reference basename that collides with a canonical one.
  - **Check 23 (LOG↔INDEX consistency)** — confirms the release record and its index agree after the migration.
- **Old-path drainage.** Grep the OLD path across the tree: it must return **zero hits** outside explicitly-marked historical record (a RELEASE_LOG row that preserves a pre-restructure path as provenance is *history*, not a live reference — do not "fix" it). Any live hit at the old path is an incomplete rewrite.
- **Tool-path rot check.** A structural move can leave tool/script path resolution pointing at the extinct path. After the move, confirm the deploy tooling and any path-resolving scripts resolve against the *new* structure — extinct-path drainage in the corpus and re-homed-path reconciliation in the tooling are two distinct surfaces; both must drain.

### 4. Rollback

- **`git revert -m 1 <migration-PR-merge>` is the forward-only rollback.** A migration ships as a reviewable PR; reverting that merge commit is the clean reversal. This is in-place — it does not re-move files by hand.
- **Restore deleted mirrors.** If the migration deleted mirror files after canonicalizing, the revert restores them; re-run `deploy.sh --deploy` to re-sync the mirror set to the restored canonical state.
- **Reversibility tier scales with blast radius.** A move of a low-inbound file is CHEAP (revert in hours). A re-versioning or a single-source consolidation touching many mirrors is MODERATE-to-EXPENSIVE (the revert is mechanical but the downstream re-sync and any already-claimed version number raise the cost). Tag the migration's reversibility tier per [`../../specs/reversibility-protocol.md`](../../specs/reversibility-protocol.md) at plan time.

---

## Worked examples (grounded in this repo's migration history)

These are the migrations this playbook generalizes from. Each is named descriptively; the patterns it teaches are drawn from the observed behavior of that migration.

| Migration event | Pattern it teaches |
|---|---|
| **The modular-monolith cutover** — the one-time `--init` cutover that split the tree into `core/` / `operations/` / `release/` (per [`../../disciplines/architecture-overview.md`](../../disciplines/architecture-overview.md) `--init` "one-time cutover migration"; the current-state map is [`../../diagrams/architecture-platform-structure.md`](../../diagrams/architecture-platform-structure.md)) | Module-boundary moves; the `via-public-api` cross-module reference discipline (a `core/` file never references `operations/` or `release/`); extraction-readiness as the migration's acceptance bar. |
| **The re-versioning collision** — a release re-versioning where two efforts contended for the same version number | Claim the version number LATE (at execution, not plan time); immutable PR titles stand as historical record; verify against the live unclaimed set at the claiming moment. |
| **The single-source reference consolidation** — collapsing duplicated reference content to one canonical home under `core/` with deploy-managed mirrors injected via `TEMPLATE_SYNC_MAP` | Single-source consolidation; template injection + the Check 13b collision gate; delete the mirrors only *after* the canonical home is established and the byte-identity check passes. |
| **Extinct-path drainage** — the fast-follow reconciliation after a structural move, where tool/script path resolution still pointed at the moved-away path | Post-migration tool-path rot is a distinct surface from corpus-ref rot; the re-homed-path reconciliation in tooling must drain alongside the corpus references. |

> **Historical-record discipline.** Some RELEASE_LOG / historical rows preserve **pre-restructure** paths (e.g., a `pmo-platform/…` path from before the modular-monolith cutover) as provenance. Those rows are immutable historical record — cite them as *history*, and teach the *current* `core/` / `operations/` / `release/` structure as the *target*. Do **not** rewrite a historical path to the current structure; doing so destroys the provenance the playbook teaches from.

---

## Anti-patterns

Three migration-specific anti-patterns, each per the 5-field template in [`../../standards/failure-mode-standard.md`](../../standards/failure-mode-standard.md), with one category tag (TRIG / INPUT / PROC / OUT / HAND).

### Version-pinned-early — PROC

- **Signature (observable signal):** A re-versioning migration pins the new version number in the plan / PR title at plan time, before execution; a second release claims the same number first, and the immutable PR title now stands as a misleading record of a version that effort did not actually ship.
- **Conditional:** do NOT pin a new version number at plan time for a re-versioning migration, because the number is a shared, first-come resource — pinning early races another release for the same claim, and the immutable PR title cements the collision as false historical record.
- **Root cause:** A version number feels like an identity the work should carry from the start; the plan wants a concrete label, so the agent claims one before the claiming moment, treating a contended resource as if it were reserved.
- **Mitigation:** Claim the version number at the latest responsible moment (release execution), against the live unclaimed set. Carry the migration under its descriptive name until then; let the execution stage bind the number.
- **Principal response vs. junior response:** Principal carries the work under its name and claims the number at execution, verifying it is still unclaimed. Junior writes "v1.X" into the plan and the PR title on day one, and the title outlives the collision as a permanent misstatement.

### Ref-rewrite-incomplete — PROC

- **Signature (observable signal):** The migration executes the moves and rewrites the *obvious* inbound references, but skips one or more of the six canonical ref-forms — typically the mover-internal-outbound (F4) or root-escape (F3) forms a static inbound scan does not reach — so a live reference still points at the old path after the migration is declared done.
- **Conditional:** do NOT execute a doc-corpus move without first authoring the complete six-form (F1–F6) reference enumeration per [`doc-corpus-reorg-ref-forms.md`](../../../release/references/protocols/doc-corpus-reorg-ref-forms.md), because a `blast-radius.sh` inbound scan covers only references *into* a static target — the moving set's *outbound* and *root-escaping* references are an orthogonal surface, and skipping them leaves live dangling refs the inbound scan reported clean.
- **Root cause:** The inbound survey is the visible, easy artifact and reads GREEN on the forms it covers; the moving-set-outbound forms require a separate enumeration, so "the blast-radius scan passed" is mistaken for "all references are rewritten."
- **Mitigation:** Author the F1–F6 table at design time (Phase A3.2) and drive the rewrite from it; run Check 14 + an old-path grep that must return zero live hits as the exit gate, not the inbound scan alone.
- **Principal response vs. junior response:** Principal enumerates all six forms, rewrites from the table, and proves zero old-path hits. Junior runs the inbound scan, sees GREEN, ships — and a `core/`-internal outbound link to the moved file dangles until a reader hits the 404.

### Mirror-drift-unverified — OUT

- **Signature (observable signal):** A single-source consolidation migration declares done after canonicalizing and deleting the duplicates, without a byte-identity check on every deploy-injected mirror; one injected copy silently drifts from its canonical source, and the two now disagree.
- **Conditional:** do NOT declare a single-source migration complete without a byte-identity check on every injected mirror (the `TEMPLATE_SYNC_MAP` set, gated by Check 13b), because the whole point of single-sourcing is that the mirrors equal canonical — an unverified mirror reintroduces the duplicate-source drift the consolidation existed to remove.
- **Root cause:** Canonicalizing and deleting the visible duplicates feels like the finish line; the mirror re-injection is a downstream deploy step, so "the duplicates are gone" is mistaken for "the single source is consistent everywhere."
- **Mitigation:** After canonicalizing, run `deploy.sh --check` and confirm Check 13 / 13b pass (registered single-sourced files and unregistered basename collisions both clean); treat a byte-identity mismatch on any mirror as an open migration, not a cosmetic warning.
- **Principal response vs. junior response:** Principal verifies every mirror byte-identical to canonical before closing. Junior deletes the duplicates, sees a clean working tree, and ships a "single source" whose one drifted mirror makes the corpus less true than before the consolidation.

---

## See also

- [`../../../release/references/protocols/doc-corpus-reorg-ref-forms.md`](../../../release/references/protocols/doc-corpus-reorg-ref-forms.md) — the six canonical ref-forms (F1–F6) and per-form sweep commands (step 2 / step 4).
- [`../../../release/references/pipeline/stage-05-solutioning.md`](../../../release/references/pipeline/stage-05-solutioning.md) — Phase A3.2, the completeness gate this playbook's procedure feeds.
- [`../../disciplines/architecture-overview.md`](../../disciplines/architecture-overview.md) — the modular-monolith structure (`--init` cutover) that is the migration target.
- [`../../disciplines/concurrency-safeguards.md`](../../disciplines/concurrency-safeguards.md) — concurrent-writer safeguards for two migrations on a shared branch (sequencing).
- [`../../specs/reversibility-protocol.md`](../../specs/reversibility-protocol.md) — reversibility-tier vocabulary for the rollback phase.
- [`../../rules/doc-link-maintenance.md`](../../rules/doc-link-maintenance.md) — Check 14 doc-link verification (the migration gate).
