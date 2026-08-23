# release/releases/plans/ — release plan files

Per-release Stage 4 release plans live here, one file per release. A plan's filename binds its identity in **two phases, separated in time** (the plan-file analogue of the two-phase version claim in [`../../governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Versioning): it is authored **slug-primary / pre-claim** (`<slug>_RELEASE_PLAN.md`, keyed to the milestone/theme slug) while the release is in flight, and — for a `versioned` release — is renamed to its **versioned** form (`vX.Y_RELEASE_PLAN.md`) only at the Stage-12 atomic claim (per ADR-092; the rename + `{{RELEASE_VERSION}}` content resolution are performed by `../../tools/claim-version.sh` on the CAS-win path).

## File naming

- **Pre-claim / in-flight** (no `RELEASE_LOG.md` row yet): `<slug>_RELEASE_PLAN.md`, where `<slug>` is the milestone/theme slug (e.g., `release-identity-and-plan-naming_RELEASE_PLAN.md`). The concrete version is not yet known — the file carries no version stem, and in-file version references use the `{{RELEASE_VERSION}}` placeholder. This is the universal pre-claim form for **both** identity modes.
- **Post-claim, `versioned`**: `vX.Y_RELEASE_PLAN.md`, where `vX.Y` is the version won at the Stage-12 claim (e.g., `v3.60_RELEASE_PLAN.md`). The slug-named pre-claim file is `git mv`'d to this form at the claim.
- **Post-claim, `version-less`**: stays `<slug>_RELEASE_PLAN.md` and resolves to `_unversioned/` (records `(none)` — no version is ever claimed).

## Directory layout — major-version subfolders

Plan files are organized into **per-major-version subfolders**, not stored flat. This keeps each directory scannable as the corpus grows. **This scheme governs plans only** — `../notes/` is flat except for its own `_unversioned/` bucket, per [`../../references/standards/release-notes-standard.md`](../../references/standards/release-notes-standard.md) § File Location, Naming, Frontmatter. The asymmetry is deliberate: plan placement is ADR-092-backed and enforced by `--check plan-identity`, and no equivalent placement assertion exists for notes.

```
plans/
├── README.md            ← this file (stays at top level)
├── v1/                  ← every v1.x release plan
├── v2/                  ← every v2.x release plan
├── v3/                  ← every v3.x release plan
└── _unversioned/        ← un-versioned plans: pre-claim OR version-less-by-design (see disposition rule)
```

`README.md` lives at the top level, alongside any **pre-claim / in-flight** plans (slug-keyed, no `RELEASE_LOG.md` row yet — work in progress). Once a release is claimed, a `versioned` release's plan is filed under the subfolder for its major version (`plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md`) via the Stage-12 `git mv`; a `version-less` release's plan resolves to `_unversioned/`.

### Disposition rule (which subfolder a file belongs to)

Every **plan** resolves to exactly one subfolder by this rule, applied in order. (Notes do not: they are flat except for `../notes/_unversioned/`, and only rule 2's second bullet — the version-less case — has a note analogue.)

0. **Pre-claim / in-flight** (slug-keyed filename, no `RELEASE_LOG.md` row yet — the release is in flight and has not reached the Stage-12 claim) → **stays at the plans/ top level**, slug-keyed, pending the claim. This is the universal pre-claim home for both identity modes; the file has no version stem to subfolder on yet. At the Stage-12 claim, a `versioned` release advances to rule 1 (via `git mv` to `v<MAJOR>/`), a `version-less` release to rule 2 (`_unversioned/`).
1. **Version-prefixed filename** (`vX.Y…_RELEASE_PLAN.md`) → `v<MAJOR>/` taken from the filename's major (`v3.45…` → `v3/`).
2. **Version-less filename** (milestone-number-prefixed like `22-ticket-information-architecture_RELEASE_PLAN.md`, or theme-named like `architecture-altitude-discipline_RELEASE_PLAN.md`) whose release has **shipped** (has a `RELEASE_LOG.md` row) — the version binds only at the Stage 12 atomic claim, so these files carry no version stem. Resolve the **shipping release's major** by matching the filename's milestone/theme slug against its row in [`../RELEASE_LOG.md`](../RELEASE_LOG.md):
   - If the slug appears in a **version-keyed** LOG row (e.g. `22-ticket-information-architecture` is the Milestone cell of the `v2.27` row) → file under that major (`v2/`).
   - If the slug appears only in a **version-less LOG row** (the release shipped VERIFIED with Tag `(none)` and never claimed a version) → file under `_unversioned/`.

`_unversioned/` is the bucket for **un-versioned** plans and notes — both a genuinely version-less shipped release (rule 2, second bullet) and a pre-claim plan an author chooses to stage there rather than at the top level are legitimate residents. When a version-less (or pre-claim) release is later assigned a version, move its **plan** into the matching `v<MAJOR>/` subfolder with `git mv` (the Stage-12 stamp pass does this for a `versioned` claim) — and move its **note** to the flat `../notes/` root, since notes shard on nothing — then repair that release's INDEX link **by editing its row in place**. Do **not** re-run a bare `../../../core/deploy/tools/generate_release_index.py` to "refresh" the links: a full regenerate rewrites every row, restamping the grandfathered `Date` cells the [`../RELEASE_INDEX.md`](../RELEASE_INDEX.md) header § *Grandfathering* declares must not be rewritten. Confirm the repair with the read-only `../../../core/deploy/tools/generate_release_index.py --verify`. **Grandfathering:** the cutover is forward-only — existing `vX.Y_RELEASE_PLAN.md` files are not renamed to the slug form.

### Tooling contract

The generators that read this corpus discover files **recursively** (`rglob`), so subfoldering is transparent to them:
- [`../../../core/deploy/tools/generate_release_index.py`](../../../core/deploy/tools/generate_release_index.py) — resolves each note link to the note's actual on-disk path: flat `notes/<name>_RELEASE_NOTES.md`, or `notes/_unversioned/…` for a version-less release. Run it as `--verify` (read-only) unless an operator has explicitly accepted a full-INDEX restamp — see the regeneration prohibition above.
- [`../../../core/deploy/tools/lint_release_corpus.py`](../../../core/deploy/tools/lint_release_corpus.py) — scans all subfolders for filename **shape** compliance, frontmatter schema, type-coherence, note content, and **plan-identity**. The filename check validates SHAPE ONLY — that a name matches the canonical regex — and says nothing about whether the version it names is the one the release shipped as. That second, independent question is the plan-identity check (`--check plan-identity`): it compares each version-declaring plan filename against its `../RELEASE_LOG.md` row, resolved by a ledger-row identity join, and asserts in the opposite direction that every concrete-version ledger row has a plan at `v<MAJOR>/<VERSION>_RELEASE_PLAN.md`. A plan whose filename declares no version is outside its antecedent and passes without a rule, which is why the pre-claim and `_unversioned/` forms above need no exemption.

The `../RELEASE_LOG.md`, `../RELEASE_DIGEST.md`, and `../RELEASE_INDEX.md` **path pointers** reflect each artifact's actual layout — subfoldered for plans, flat-except-`_unversioned/` for notes.

**Frozen-record rule, and its one exception.** Historical release-plan and release-note bodies retain their as-authored self-referential paths as a frozen record: a path that records *what the corpus looked like when the artifact was written* is a factual claim and is not rewritten. That rule does **not** cover a body's own outbound **links**. A link that a later corpus move broke is not a factual claim about the past — it is a navigational target that no longer resolves — so it is repaired in the same change that moves the file, to the artifact the author was pointing at. Repairing it restores the author's original intent rather than rewriting history.

## Authoring contract

- **Authored by:** Stage 4 release-planning spoke (Procedure 0 in [`../../references/how-to/hub-spoke-bridge.md`](../../references/how-to/hub-spoke-bridge.md))
- **Committed by:** Determined by the D-C Branch Topology decision gate:
  - **D-C SINGLE topology** (default): Engineering Commit 0 on the release branch
  - **D-C OPTION-A topology** (per-issue branches): Stage 4 release-plan chore PR landing on main BEFORE per-issue sub-task scaffolding
- **Read by:** All per-issue Stage 5/6/7/8 spokes; the hub Procedure 1 scaffolding; the operator at Stage 9 plan review

## Contents per file

Stage 4 spoke produces the plan with these sections (see [`../../references/pipeline/stage-04-planning.md`](../../references/pipeline/stage-04-planning.md) for the full spec):

- Summary (30 seconds)
- Dependency Graph
- Implementation Sequence
- Stage Applicability Matrix
- Contention Map
- Risk Register
- Operator Decisions / D-Gate blocks
- Release Class declaration
- Recommendations

## Classification

**UNIVERSAL-PUBLIC** per [`../../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md). Every per-issue Stage 5/6/7/8 spoke session reads the plan to ground its work; spokes run in isolated worktrees and cannot see operator-local files — git is the substrate that makes hub-spoke coordination work.
