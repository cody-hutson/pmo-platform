<!-- reference-durability: allow-version-ref -->
# RELEASE_PROTOCOL.md — Platform Release Management

**Effective:** 2026-03-19
**Scope:** All governance changes across the workspace (CLAUDE.md, OPERATIONS.md, PORTFOLIO.md, SESSION_STATE.md, RELEASE_PROTOCOL.md, skills, folder structure, protocols)
**Owner:** [OPERATOR_NAME]
**Status:** Production

---

## Purpose

Defines the lifecycle for platform changes — from improvement intake through implementation to verification. This protocol governs how the workspace itself evolves and applies to all governance file modifications, skill updates, and structural changes.

Separated from OPERATIONS.md because the release process governs the entire workspace, not just PMO project management. OPERATIONS.md defines how projects are managed; this file defines how the platform changes.

---

## File Structure

```
core/governance/
└── OPERATIONS.md                ← Operational protocols and cross-project rules

release/governance/
├── RELEASE_PROTOCOL.md          ← This file. How changes are managed.
└── release-process.md           ← The 13-stage pipeline definition

release/releases/
├── RELEASE_LOG.md               ← Version history (engineering audit trail)
├── RELEASE_INDEX.md             ← One row per release (navigation surface)
├── RELEASE_DIGEST.md            ← One H3 entry per release, foldered by major-version H2
├── RELEASE_REVERSIONS.md        ← Re-version ledger (abandoned-version recovery record)
├── plans/                       ← Release plans, foldered by major version
│   ├── _unversioned/            ← Plans for version-less releases (slug-keyed)
│   ├── v1/  v2/  v3/            ← One folder per major version
├── notes/                       ← User-facing release notes, same foldering as plans/
│   ├── _unversioned/
│   ├── v1/  v2/  v3/
└── hub-state/                   ← release-hub orchestration state

packages/
└── [skill].skill                ← Production .skill packages (one per deployed skill)
```

**Naming convention:** `[version]_RELEASE_PLAN.md` / `[version]_RELEASE_NOTES.md` — foldered by
major version (`plans/v3/`, `notes/v3/`), with `_unversioned/` holding the slug-keyed artifacts for
version-less releases.

**Plans fold at the claim, not at major-version close-out.** A `versioned` release's plan is
**slug-keyed while it is in flight** — `plans/<slug>_RELEASE_PLAN.md`, flat at the `plans/` root
through Stages 4–11 — and binds its version only at the Stage-12 atomic claim, where the CAS-win
path renames it to `plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md` and resolves its `{{RELEASE_VERSION}}`
placeholder to the won number (ADR-092; see § Versioning Phase 1). Foldering a plan is therefore a
**per-release step performed at the claim**, not a batch performed when a major version closes out.
A `version-less` release has no number to bind: its plan stays slug-keyed permanently under
`_unversioned/` and the rename never fires.

Flat files at the **`notes/` root** are the recent-release working set; note foldering does happen
as major versions close out.

**Snapshots:** the `_snapshots/` and `_archive/` directories described by earlier revisions of this
protocol do not exist in the repository. Pre-change snapshots are the **Cowork-path** mechanism (see
§ Pre-Change Snapshot Protocol); on the **Claude Code path** git history *is* the snapshot and the PR
diff *is* the dry-run review gate, per CLAUDE.md § No ungoverned changes. Nothing writes a snapshot
directory into this repo.

---

## Lifecycle

1. **Intake** — Skill identifies gap → creates a GitHub Issue with structured fields (status: Proposed)
2. **Triage** — User reviews weekly → Approve, Reject, or Defer each item
3. **Bundle** — User groups approved items into a release (e.g., v5.1). System generates `[version]_RELEASE_PLAN.md` with full implementation details per IMP.
4. **Plan review** — User reviews/iterates the plan before execution
5. **Dry run** — Before execution, produce a diff preview for every affected file (see "Dry-Run Protocol" below). User reviews actual content changes — not just the plan description — and confirms execution. This step cannot be skipped.
6. **Snapshot** — Create timestamped copies of all files that will be modified (see "Pre-Change Snapshot Protocol" below). Snapshots provide rollback capability if the release introduces a regression.
7. **Execute** — Changes implemented per plan. Each issue status → In Progress → Implemented
8. **Close** — (a) Close GitHub Issues with verification evidence and release version. (b) Add release summary row to RELEASE_LOG.md Recent Releases section. If Recent Releases exceeds 5 entries, move the oldest entry to the Release History table. (c) If the release modified skill files, execute the Skill Build Protocol's rebuild and cleanup steps. (d) Author or verify the user-facing release note at `release/releases/notes/vX.Y_RELEASE_NOTES.md` per [`release/references/standards/release-notes-standard.md`](../references/standards/release-notes-standard.md) — distinct artifact and audience from `RELEASE_LOG.md` (engineering audit trail). Milestone close gates on note presence + structural lint pass per the release-notes standard. Release plan file serves as implementation audit trail. (e) A "Gate-Passage Proof" comment is recorded on the Stage 13 Close sub-task before Milestone close per the gate-passage-proof protocol. The comment lists each gated output with its verification command result, creating single-glance audit evidence durable in the sub-task comment thread. Operational mechanism: [`release/references/how-to/hub-spoke-bridge.md`](../references/how-to/hub-spoke-bridge.md) Procedure 7 §Gate-passage proof recording. *Cutover discipline: Applies to all releases going forward.*
9. **Verify** — Optional QA audit or regression test. Release marked VERIFIED in RELEASE_LOG.md.

---

## Change Description Protocol

A `## Change Description` section is embedded in every release plan FILE (`release/releases/plans/<slug>_RELEASE_PLAN.md` while in flight; renamed to the `vX.Y` form at the Stage-12 claim per § Versioning) to provide an operator-readable, git-resident, pre-merge summary of what the release delivers. The section is authored by the Stage 6 release-engineering spoke as part of PR creation and is visible at Stage 9 Plan Review in the PR diff.

**Distinct artifact.** This section is NOT the user-facing release note (which lives at `release/releases/notes/vX.Y_RELEASE_NOTES.md`, authored at Stage 13 Close per [`release/references/standards/release-notes-standard.md`](../references/standards/release-notes-standard.md)). The Change Description targets the operator at pre-merge time with engineering-OK voice; the release note targets non-technical platform users at post-merge time with voice-constrained framing per the release-notes standard. Both artifacts ship per release; they reference each other but do not substitute.

**Three-artifact chain.** The Change Description complements the Stage 3 Release Outcome Statement (authored at Stage 3 Phase B3 and embedded in the GitHub Milestone description as `### Release Outcome Statement` H3 per [`release/references/specs/release-outcome-statement-template.md`](../references/specs/release-outcome-statement-template.md)) — Outcome anchors pre-execution intent (future-tense capability statement); Change Description summarizes post-implementation delivery (past/present-tense engineering narrative); release notes target end users at post-merge time. Each artifact answers a different question for a different audience at a different point in the release lifecycle.

**Trigger stage.** Stage 6 (release-engineering spoke), as part of PR creation. The section is appended to the release plan FILE on the release branch BEFORE the PR is marked ready-for-review. If Stage 7/8 surface material changes (Tier 1 [ADJUST] fix commits that change which issues land or which D-decisions stand), the section is refreshed in a subsequent commit on the release branch using the existing release-plan-FILE-update discipline.

**Section heading.** `## Change Description` (verbatim, per the originating issue's acceptance criteria AC1).

**Location.** Appended at the bottom of the release plan FILE, after the "Verification Evidence" section and "Deployment Execution Log" section. No subfolders; no new file class.

**Required sub-sections (in order):**

| § | Sub-section | Required? | Length | Content |
|---|---|---|---|---|
| 1 | **Outcome** | Required | 2-3 sentences | What this release delivers in plain-but-engineering-OK language. Lead with operator-facing capability. |
| 2 | **Issues resolved** | Required | Table | Per-row: `# / one-line outcome / status (DONE / PARTIAL / DEFERRED)`. Operator-readable per-line outcome. |
| 3 | **Key decisions** | Conditional (omit when no D-decisions rendered) | Bullet list | Per D-decision: verdict + one-line rationale; link to release plan § Hub-Rendered D-Decisions row. |
| 4 | **Reversibility** | Required | One sentence | Tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) + confidence (HIGH / MEDIUM / LOW) + rollback mechanism. Maps to [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "Reversibility discipline." |
| 5 | **Downstream impact** | Required | Bullet list | What this release enables in the next release; affected surfaces; carry-forward items. |
| 6 | **Cross-references** | Required | Bullet list | Links to: release plan top, milestone (GitHub URL), user-facing release notes path. |

**Length target.** ~60 lines (40 lines minimum, 100 lines maximum). Single-screen-readable target for operator scan at Stage 9 Plan Review.

**Voice rules.**

1. **Operator-facing, engineering-OK.** Engineering nouns, internal IDs, skill names, file paths permitted. The operator reads SKILL.md files; the audience contract permits engineering language.
2. **Specificity rule.** No "various improvements," no "minor enhancements," no quality adjectives without measurement.
3. **Fabricate-or-omit.** Omit a sub-section rather than fill it with generalized content. The conditional Key decisions sub-section is omitted when no D-decisions are rendered; do not invent.
4. **No marketing voice.** No enthusiasm, no customer quotes, no named credit fabrication.
5. **Reversibility sub-section is mandatory.** Every release has a reversibility posture; this sub-section is never omitted.
6. **No strikethrough.** Per [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "No strikethrough in generated artifacts."

**Template.** The Change Description section template lives at [`release/skills/release-planner/references/release-plan-template.md`](../skills/release-planner/references/release-plan-template.md) as part of the release plan template. The Stage 6 spoke fills in placeholders during PR creation.

**Backfill.** Existing release plans (before the cutover) do not need retroactive Change Description sections. The protocol applies prospectively.

**Cutover discipline:** Applies to all releases going forward.

**Reversibility (of this protocol).** CHEAP / HIGH confidence — `git revert` on the release PR reverses the protocol section + template addition + Stage 6 cross-references cleanly; existing Change Description sections (one per post-cutover release) remain as historical record.

**Origin.** Operator observation 2026-04-21: difficulty understanding what agents are building to close gaps.

---

## Versioning

A release's version is **allocated in two phases, separated in time**: an *intent* declared at plan time, and the *concrete number* computed and claimed only at the merge moment. This is the authoritative allocation rule — it answers "what is the next version" deterministically, where the older "the bump-class decides the number" framing could not (a "Minor" change-type never said *which* minor). The rule is **host-agnostic**: it is pure version-tuple arithmetic over the canonical version grammar and consumes the repository-host adapter operations `anchor()` and `claimed_set()` **by name**. It does not itself call any host tool (no `gh`, no `git`); how a host computes the anchor and the claimed set is that host's adapter's concern, not this rule's. The adapter operations and the GitHub/git reference adapter are defined in the repo-host adapter version-claim interface (`core/standards/repo-host-adapter-versioning.md`); the version grammar, its integer-triple total order, and the comparator the arithmetic uses are defined in the version-grammar standard (`release/references/standards/version-grammar.md`), implemented once in `release/tools/version-grammar.sh`.

### Release-identity mode (`{versioned, version-less}`) — the precondition on this rule

Every release declares a **release-identity mode** at Bundle — the closed enum `{versioned, version-less}` whose declaration home is the Stage-3 bundle shard (`release/references/pipeline/stage-03-bundle.md` § Release-Identity Mode). The mode is the precondition on everything below:

- **`versioned`** (the default) — the release claims a version number, and the two-phase allocation rule in this section applies in full: a bump-class intent declared at plan time, a next-free computation and atomic claim performed at the merge moment.
- **`version-less`** — the release carries **no version string**; its identity is the capability slug alone. The allocation rule below is **inapplicable, not failed**: there is no floor to derive, no candidate to compute, and no tag to claim. A `version-less` release records `(none)` where a version key would sit and is identified in the release log by its slug.

`version-less` is an **identity-axis value, not a malformed or empty version string.** The version-grammar canonicalization, comparison, and freeness functions are therefore **never invoked** for a `version-less` release, so the grammar's rejection of the empty form is never reached and never contradicted. Do not synthesize a placeholder version to force a `version-less` release through the allocation rule, and do not read the absent version as a collision.

The mode is **orthogonal to bundle size** — all four combinations (`versioned` / `version-less` × single-item / bundle) are supported. Gate 3 asserts the mode's validity, and the mode-appropriate obligation (a declared bump-class intent for `versioned`; the absence of a version string for `version-less`), at the Bundle→Planning boundary via criterion **G3-19** in `core/schemas/gate-criteria-spec.md` § Gate 3. That gate deliberately asserts identity-mode validity only and **never version freeness** — freeness is claim-time state owned by Phase 2 below, where the compare-and-swap renders it.

**Cutover discipline:** applies to releases entering Bundle strictly AFTER this sub-block's introducing-release merge SHA recorded in the release log; pre-cutover releases grandfathered; the introducing release itself exempt (reflexive-pipeline-loop discipline).

### Phase 1 — Plan time: declare the bump-class + provisional-display version (the FLOOR)

The release plan declares a **bump-class** — one of `major`, `minor`, `patch` — and a **provisional-display version** for human readability. This is *intent to bump*: it binds **no concrete `vX.Y`**. It sets the **floor** the eventually-claimed number must satisfy. The bump-class is the operator's semantic signal, chosen by the change's nature; the **Bump-Class Selection Guide** below maps change types to bump-classes. The provisional-display version is a label, not a reservation — the concrete number is not known until Phase 2.

The **same "binds no concrete value" discipline extends beyond the tag to the release's other monotonic identifiers** — the **plan-file name** and the **branch name**. For a `versioned` release both are **slug-primary** while the release is in flight (`release/<slug>`, `release/releases/plans/<slug>_RELEASE_PLAN.md`), and in-file version references are carried as the `{{RELEASE_VERSION}}` placeholder; none of the three binds a concrete `vX.Y` at plan time. They bind only at Phase 2's atomic claim, where the CAS-win path renames the plan to `vX.Y_RELEASE_PLAN.md` and resolves the placeholder to the won number (ADR-092). **The rename is conditional on a resolvable stamp slug, and winning the CAS does not by itself guarantee it fires.** The claim tool derives the slug from the plan corpus and **declines when the derivation is ambiguous** — two or more plans carrying an unresolved placeholder at the `plans/` root, which happens whenever two releases are in flight at once. A decline is a correct refusal to guess, not an error: the tool returns zero, the tag is bound, and the rename and placeholder resolution simply do not happen. Nothing downstream reports the omission, so the failure is silent by construction and is detected later by the ADR-092 identity gate, which blocks the close. **The Stage-12 claim therefore passes `--stamp-slug` explicitly** — the explicit flag always wins over derivation — so a multi-candidate corpus cannot silently skip a stamp. For a `version-less` release the plan and branch stay slug-primary permanently — there is no number to bind, and the rename never fires. This **composes with** the release-identity mode precondition above (it is the plan-file/branch projection of the same defer-to-claim rule the tag already obeys); it does not collapse the `{versioned, version-less}` enum.

**Canonical home of the plan-file and branch naming convention.** This subsection — `RELEASE_PROTOCOL.md` § Versioning → Phase 1 — is the **canonical statement** of that convention. The rule is stated once, in the paragraph immediately above, and is not restated here or anywhere else as an independent authority. Every other surface carrying it is a **registered projection** and appears in the table below. What a projection carries depends on its treatment, and the table assigns it: a **cite** row carries an explicit citation to this section; a **restate** row carries the rule text itself, precisely because it ships where this contract cannot be reached, and so carries no citation to it. Both state no rule this section does not state, and both yield to this section on any disagreement. The table is the closed set: a surface carrying the rule with no row here is unregistered drift, not a permitted projection. The register is a per-domain exemption under `core/standards/duplicate-source-discipline.md` § 1 condition 3 — documented in the principle that owns the duplicated surface, which is this one.

| Registered projection | Treatment | Why this treatment |
|---|---|---|
| `release/releases/plans/README.md` § File naming | **cite** | Repo-reachable navigation surface; a reader who reaches it can reach this contract. |
| `release/references/standards/release-corpus-schema.md` § Type discriminator | **cite** | Repo-reachable reference tier; it projects the shipped-corpus filename patterns and states the rule, but is not the naming authority — the phrasing this card's sibling edit to `release-process.md` already uses. |
| `release/governance/release-process.md` § Artifact of record | **cite** | Repo-reachable governance sibling. |
| `release/skills/release-planner/SKILL.md` + its `references/release-plan-template.md` | **restate** | Both ship inside `packages/release-planner.skill`; a runtime reader has no repo, so the rule must travel with the surface. |
| `release/skills/release-executor/references/execution-checklist.md` | **restate** | Same — deployed surface, no repo at read time. |
| `release/references/how-to/hub-spoke-bridge.md` § Canonical location | **cite** | Repo-reachable how-to tier; it names the slug-primary plan path and cites this section plus ADR-092. Registered at Stage 8 — it carried the rule unregistered, which the sentence above forbids.
| `core/rules/git-workflow.md` § Branch naming + commit format | **restate** | Deployed to the agent config root, so a runtime reader has no repo and the rule must travel with the surface. It states the **branch** limb this section owns and cites ADR-092. Registered at Stage 8 for the same reason as the row above.

The cite-versus-restate split applies the existing rule in `duplicate-source-discipline.md` § 2 rather than introducing a new one: restate when the derived surface is deployed and its contract is not; cite when the contract is at least as reachable as the surface restating it. Adding a projection means adding a row to this register; a projection that states a rule this section does not state is drift, not an extension.

### Phase 2 — Claim time (at the merge): compute next-free ≥ floor, then claim atomically

The concrete version is computed and claimed only at the merge moment, against fresh authoritative host state:

1. **Floor from the bump-class.** Derive the floor from `anchor()` — the highest claimed version in the mainline lineage (orphan lineages excluded; this is the adapter's responsibility, not this rule's):
   - `major` → `(anchor.major + 1, 0)` — the `.0` of the next major line.
   - `minor` → `(anchor.major, anchor.minor + 1)` — the next minor above the anchor.
   - `patch` → computed from a shipped base, **not** from the anchor — see the Patch rule below.
2. **Next-free ≥ floor.** The claimed version is the **lowest version at or above the floor that is NOT in `claimed_set()`** — the union of all currently-claimed and in-flight versions the host adapter reports. Walk upward from the floor, by the bump-class's own increment (minor for major/minor; patch for patch), comparing with the version-grammar comparator (`version_cmp`), until a version not in `claimed_set()` is found. That version is the candidate.
3. **Atomic claim.** Claim the candidate via the adapter's `atomic_claim(version, release_ref)` compare-and-swap. On `OK`, the number is the release's. On `COLLISION` (another release claimed it first), **recompute from step 1 against fresh `anchor()` + `claimed_set()`** and retry — never overwrite. The compare-and-swap is what makes **ship-order = merge-order = tag-order** an architectural guarantee: whichever release wins the swap takes the lower free slot, in the order the host arbitrates; the loser recomputes upward. The claim mechanism (the recompute-and-retry loop) is a separate slice; this rule is the algorithm it executes.

```
ALLOCATE(bump_class, patch_base) -> claimed_version        # runs at the merge moment
                                                           # patch_base supplied only when bump_class = patch

floor := FLOOR(bump_class, patch_base)                     # step 1
candidate := floor
while candidate ∈ claimed_set():                           # step 2 — freeness oracle
    candidate := INCREMENT(bump_class, candidate)          # minor for major/minor; patch for patch
if atomic_claim(candidate, release_ref) == OK:             # step 3 — compare-and-swap
    return candidate
else:                                                      # COLLISION — never overwrite
    retry ALLOCATE against fresh anchor() + claimed_set()
```

**Patch rule (the X.Y.Z form) — a separate path.** A `patch` bump does **not** compute against the anchor: it corrects a specific already-shipped release **in place**, so its floor is derived from that shipped base, and its increment walks the **patch** component, never the minor. The hotfixed base version is an explicit input (`patch_base`) — it is not derivable from the anchor, which is exactly why the patch path is split out of the major/minor machinery:

- `FLOOR(patch, patch_base)` = `(patch_base.major, patch_base.minor, patch_base.patch + 1)` — e.g. a hotfix to the shipped `v2.06` floors at `v2.06.1`; a second hotfix to the same base floors at `v2.06.2`.
- `INCREMENT(patch, candidate)` = increment the **patch** component (`(M, N, P) → (M, N, P + 1)`), so a collided `v2.06.1` resolves to `v2.06.2` — **never** to a minor such as `v2.07` (which would steal the next minor slot).

`FLOOR`/`INCREMENT` for `major` and `minor` walk the **minor** component (`(M, N) → (M, N + 1)`); only `patch` walks the patch component. The canonical hotfix form is the three-component `vMAJOR.MINOR.PATCH` (e.g. `v2.06.1`); suffix forms (`vX.Yb`) are not a valid claimed shape — see the version-grammar standard.

**Monotonicity, and the reconciliation of the "non-monotonic" note.** Claimed versions are monotonic **at claim time** — each is next-free at or above the anchor, so each newly claimed number exceeds the prior tip. What is intentionally **not** preserved is the correlation between a release's *start time* and its number: a faster concurrent release claims a lower free slot than a slower release that started earlier. The release log records **claim order**, which is monotonic by construction, even when its rows are non-monotonic in *authoring* order. The historical note that "git-describe versioning was non-monotonic" is resolved here as **an artifact of reading a non-authoritative source**: `git describe` reports the nearest tag reachable from the current branch (the merge base on a feature branch), not the top of the mainline lineage, so it returns a stale, non-monotonic answer. The authoritative anchor is the adapter's `anchor()` (the highest claimed version in the mainline lineage), against which allocation is monotonic. The non-monotonicity the operator accepted was start-time-vs-number decorrelation for concurrent releases — preserved and explained by this rule — not a defect in the allocation order.

### Atomic claim (the prevention mechanism)

The allocation rule above computes the candidate; the **claim** is what makes the number the release's own, atomically, at the merge moment. The mechanism that performs the claim is the executable slice the allocation rule defers to — it calls the adapter's `atomic_claim(version, release_ref)` compare-and-swap and is responsible for the recompute-and-retry loop, not for the allocation arithmetic. Its standing properties:

- **Claim only at the merge tag, never reserved earlier.** The candidate is claimed via `atomic_claim()` against fresh authoritative host state read immediately before the call. Nothing is held between plan time and the claim — the held-but-unclaimed window the older "assign at bundle, tag at execute" flow left open is eliminated.
- **A collision retries; a failure halts.** `atomic_claim()` returns `COLLISION` only when the version was already claimed by a concurrent writer — the *one* outcome that recomputes next-free (re-reading `anchor()` + `claimed_set()`) and retries. The retry is **bounded**; on exhaustion the claim halts and escalates rather than looping. Every host-side failure that is **not** a collision — a transport, authentication, permission, or **signing** failure — is surfaced as a hard error that **halts**, and is **never** retried as if it were a collision. Retrying past a signing failure would defeat the never-bypass-signing guarantee, so the mechanism must not.
- **Never overwrite.** `atomic_claim()` has no force path: a colliding claim is never forced over the existing one. The winner of the compare-and-swap keeps the number; the loser recomputes upward. This is what makes **ship-order = merge-order = tag-order** an architectural guarantee rather than a convention.

The mechanism is **host-agnostic** — it composes the adapter operations defined in the repo-host adapter version-claim interface (`core/standards/repo-host-adapter-versioning.md`) and contains no host tool itself; the GitHub/git reference adapter's implementation of those operations (and of this claim loop) is `release/tools/claim-version.sh`, invoked at the Stage 12 execute step.

### Bump-Class Selection Guide (advisory input to the allocation rule)

The bump-class declared at Phase 1 is chosen by the change's nature. This guide maps change types to bump-classes — it is **advisory input** to the allocation rule: it declares the **floor**, it does **not** decide the concrete number (Phase 2 does, at claim time).

| Change Type | Bump-Class | Rationale |
|-------------|-----------|-----------|
| New skill added to the suite | **major** | New capability changes what the platform can do |
| New governance file created | **major** | Structural change to workspace architecture |
| Skill behavioral change (new mode, altered processing logic) | **major** | Changes how an existing skill operates; may affect downstream flows |
| Governance file structural rewrite | **major** | High-impact change to platform rules |
| Skill configuration update (description, trigger phrases, reference docs) | **minor** | Changes inputs/documentation but not core behavior |
| Protocol text addition or modification | **minor** | New rules or rule changes within existing structure |
| Tracker schema change | **minor** | Data structure change within existing trackers |
| Reference document addition or update | **minor** | Supporting material, not core behavior |
| Typo / formatting correction to a shipped release | **patch** | No behavioral or structural impact; corrects a shipped base in place |
| Documentation wording clarification to a shipped release (no rule change) | **patch** | Improves clarity without changing meaning |

### References

<!-- repo-integrity: allow-issue-ref -->
- #1673 — the authoritative version-allocation rule (this section satisfies its ACs: the rule stated with no contradiction to practice, and the prior semantic decision table corrected to an advisory selection guide).
- #1697 — the founding version-claim-determinism ADR (defer-to-merge claim, atomic compare-and-swap, slug-primary identity; the architecture this rule operationalizes).
- #1676 — the canonical version grammar and its comparator (`version-grammar.sh`), which this rule's arithmetic sources rather than re-encodes.

---

## IMP Entry Requirements

Every IMP entry must contain enough information to generate a detailed implementation plan without re-reading the original conversation. Required fields: Description, Evidence, Affected Files, Proposed Change, Dependencies, Acceptance Criteria.

---

## Implementation Plan Format

When a release is planned, generate `Releases/[version]_RELEASE_PLAN.md` documenting: what files change, what specific changes, what sequence, why each change (traced back to IMP evidence), and acceptance criteria per item.

**Bundle composition doctrine.** The release-bundle's composition (WHAT belongs in the release and WHY those items cohere as a shippable unit) follows the 7-step vertical capability slice methodology per [`release/references/standards/bundle-composition-doctrine.md`](../references/standards/bundle-composition-doctrine.md). The doctrine codifies: 7-step method (Name capability AFTER/BEFORE → list tickets → walk dep graph backward → check older milestones → size-check at 15-25 pts target → declare internal sequence → declare external deps ≤ 2); tight-merge mechanics for oversized parents (split + re-merge only with internal dep edges); naming convention (`v<MAJOR>.<NN-padded>-<capability-slug>`); 6 worked-example composition shapes (capability-slice / hotfix / audit-driven / cleanup-debt / new-track-inaugural / subsumption-fission); milestone description required-fields schema (Outcome + Class + Scope + Internal sequence + Dep Exceptions + A6 conditional + Amendment Log conditional + Bundle Composition Frame optional). **Current default frame per platform config:** F1 SAFe Feature-Slicing + Vertical Slice methodology; frame is swappable on milestone-creation and milestone-update via the unified pmo-platform global config mechanism per a forthcoming enhancement without rewriting doctrine prose. Implementation plan generation reads doctrine-derived fields from the milestone description (per `release-planner` SKILL.md Mode B persistence). **Cutover discipline:** Applies to all releases going forward.

### Lifecycle Definition Requirement

For every new file, folder, or data structure introduced in a release, the implementation plan **must** include a Lifecycle Definition answering these six questions:

1. **Growth pattern** — How does this artifact grow over time? (e.g., "one entry per release," "grows with project count," "fixed size")
2. **Size discipline** — Is there a cap? What happens when exceeded? (e.g., "120-line cap, overwrite model," "< 500 lines, extract to references/")
3. **Cleanup trigger** — What triggers maintenance? (e.g., "after each release," "every 30 days," "N/A — permanent")
4. **Archive path** — Where does content go when it ages out? (e.g., "Releases/_snapshots/," "move to Archive/," "delete after promotion")
5. **Ownership** — Who is responsible for maintenance? (e.g., "platform-level," "project-scoped — project owner," "skill-specific")
6. **Exit conditions** — When is this artifact retired? (e.g., "when the project closes," "when superseded by v2," "never — permanent infrastructure")

Plans that introduce new artifacts without lifecycle definitions are **rejected during review** as incomplete. This requirement applies to all new files, folders, reference documents, skills, trackers, and data structures — not just governance files.

Existing artifacts created before this requirement are grandfathered but should have lifecycle definitions added when they are next modified in a release.

### Release Scope Validation

Every release change manifest (the list of files modified in a release plan) must pass boundary validation before execution:

1. **No Layer 2 paths in release manifests.** Release plans govern Layer 1 (platform) files. If a release plan lists a file under `Projects/` (Layer 2) or `<OPERATOR_INSTANCE_SKILLS_PATH>/` (Layer 2 deployment target), the plan must be corrected before proceeding. Exception: bridge files (Layer 3) may appear in release manifests when the change is to their schema or structure — not their operational content.
2. **Skill Build Protocol handles deployment.** When a release modifies skill source files (Layer 1, in `release/skills/`), the Skill Build Protocol stages files for user-mediated copy to `<OPERATOR_INSTANCE_SKILLS_PATH>/` (Layer 2). The release manifest lists the Layer 1 source path, not the Layer 2 deployment target.
3. **Validation timing.** Scope validation runs during plan review (Step 4) and again during dry-run (Step 5). Both gates must pass.

---

## Dry-Run Protocol

Before executing any approved release, the agent produces a diff preview for every affected file. The user reviews actual content changes — not just the plan description — before confirming execution.

**Required for:** All releases that modify governance files (CLAUDE.md, OPERATIONS.md, PORTFOLIO.md, SESSION_STATE.md, RELEASE_PROTOCOL.md), skill files (SKILL.md), or protocols. Exempt: operational file updates (Tier 2/3) that follow their own approval flow.

**Diff preview format per file:**
1. **File path** and section being modified
2. **Before block:** The exact current content (with line numbers) that will be replaced or removed
3. **After block:** The exact new content that will be written
4. **Context:** 5 lines above and below the change for surrounding awareness
5. **Conflict check:** Flag any potential conflicts with adjacent rules, existing guardrails, or other IMP items in the same release
6. **Impact note:** Which skills, protocols, or processing flows are affected by this specific change

**For complex releases (5+ file changes or structural changes), also include:**
7. **Cross-file impact assessment:** How changes in one file affect behavior defined in another
8. **Regression risk identification:** Specific scenarios where the change could break existing behavior

**Rules:**
- The dry-run step cannot be skipped — it is a mandatory part of the release lifecycle.
- The user must explicitly confirm after reviewing the diff preview: "proceed" or "approved" or equivalent.
- If the user requests modifications to the diff, iterate the preview until approved.
- Diff previews are included in the release plan file (appended as a "Dry-Run Record" section) for audit trail.

---

## Pre-Change Snapshot Protocol

Before executing any release, create timestamped copies of all files that will be modified. Snapshots provide a clean rollback point if a release introduces a regression.

**Storage:** `Releases/_snapshots/[version]/[filename]_pre_[version].md`

Example: Before v5.1 modifies PMO.md → create `Releases/_snapshots/v5.1/PMO_pre_v5.1.md`

**Rules:**
1. Snapshot every file listed in the release plan's "Affected Files" before any modifications begin.
2. Snapshots are read-only reference — never modified after creation.
3. For files under 500 lines: snapshot the entire file.
4. For files over 500 lines: snapshot the entire file (storage is cheap; partial snapshots risk incomplete rollback).
5. The snapshot step occurs after dry-run approval and before execution begins. No file is modified until all snapshots are confirmed written.

**Retention policy:**
Snapshots follow a rolling-window retention model to prevent unbounded growth:
1. **Active window — last 15 releases:** Full snapshots retained. These are the "hot rollback" targets for regressions. At current release velocity, 15 releases covers approximately 2-3 weeks of active development.
2. **Beyond 15 releases:** Snapshot folders are pruned. The release plan file (which contains before/after diffs in the Dry-Run Record) serves as the permanent audit trail — it documents *what changed* without storing full file copies indefinitely.
3. **Pruning trigger:** During the Snapshot step (Step 6) of each new release, check `Releases/_snapshots/`. If more than 15 release version folders exist, delete the oldest. This keeps the snapshot directory at a constant size of ~15 versions.
4. **Rollback exception:** Any snapshot folder tied to a release marked `ROLLED BACK` in RELEASE_LOG.md is exempt from pruning and retained until the rollback is fully resolved and the release is re-closed.
5. **Manual override:** The user may mark any snapshot folder as `RETAIN` (add a `_RETAIN` file to the folder) to exempt it from automatic pruning indefinitely.
6. **Release plan file retention:** Release plan files follow the same rolling 15-release window. When more than 15 release plan files exist in `Releases/`, the oldest are moved to `Releases/_archive/`. RELEASE_LOG.md (which contains the complete release history in its Release History table) serves as the permanent index for finding archived release plans.

**Rollback protocol:**
If a regression is detected post-release:
1. Identify the affected file(s) and the release that introduced the regression.
2. If the release is within the active window (last 15): retrieve the pre-change snapshot from `Releases/_snapshots/[version]/`.
3. If the release is older than the active window: use the Dry-Run Record in the release plan file to reconstruct the pre-change state, or check if the nearest available snapshot can serve as a baseline.
4. Diff the current file against the snapshot (or reconstructed state) to isolate the regression.
5. Propose rollback (restore snapshot content) or targeted fix.
6. User approves rollback or fix.
7. Document the rollback in RELEASE_LOG.md with: release version, file(s) rolled back, reason, and date.

**Verification:** After creating snapshots, confirm each file exists at the expected path before proceeding to Execute. If any snapshot write fails, halt the release.

---

## Skill Build Protocol

When a release modifies skill files (SKILL.md or reference files), the agent cannot write
directly to `.skills/skills/` (read-only filesystem). This protocol standardizes the build,
staging, delivery, and confirmation lifecycle for skill file updates.

**Infrastructure:** `Projects/_Skill-Packages/` serves as the single home for all skill file
lifecycle stages:

```
_Skill-Packages/
├── [skill-name].skill              ← Production .skill packages
│                                      (one per skill, canonical name)
├── _working/                        ← Release build staging
│   └── [version]/
│       └── [skill-name]/
│           ├── SKILL.md             ← Complete rebuilt skill file
│           └── references/          ← If reference files also changed
└── _previous/                       ← One-deep previous version
    └── [skill-name]/                   (overwrite model)
        └── SKILL.md
```

**Build lifecycle (executed during Step 7 — Execute):**

1. **Build:** For each skill modified in the release, agent reads the current installed file
   from `.skills/skills/[skill-name]/SKILL.md`, applies all changes from the release plan,
   and writes the **complete rebuilt file** to
   `_Skill-Packages/_working/[version]/[skill-name]/SKILL.md`.
   No "insert after line X" instructions. No partial diffs. Complete files only.
   If reference files are also modified, include them in the same skill subfolder.
   Each rebuilt file sets the `version:` field in frontmatter to the release version (e.g., `version: v6.3`). Add the field if missing; update if present. No content (comments, whitespace, or markup) may appear before the opening `---` frontmatter delimiter — this breaks YAML parsing.

2. **Archive previous version:** Agent copies the current installed version (from
   `.skills/skills/[skill-name]/SKILL.md`) to
   `_Skill-Packages/_previous/[skill-name]/SKILL.md`, overwriting whatever was there.
   One-deep only; no version accumulation. This preserves the pre-update version before
   the user overwrites it in Step 4.
   (On the first-ever update cycle for a skill, `_previous/` will be empty — this step
   creates the initial entry.)

3. **Present:** Agent links each staged file via `computer://` with explicit copy instruction:
   "Copy `_Skill-Packages/_working/[version]/[skill-name]/SKILL.md`
   → `.skills/skills/[skill-name]/SKILL.md`"

4. **User confirms "saved to skills":** User copies files to `.skills/skills/` and confirms
   completion. This is the gate — no downstream steps execute until the user confirms.

5. **Rebuild .skill package:** Agent rebuilds the `.skill` package for each updated skill
   and places it at `_Skill-Packages/[skill-name].skill` (production, canonical name,
   no version suffix), overwriting the previous package.

6. **Clean working directory:** Remove `_Skill-Packages/_working/[version]/` after all
   skills are confirmed saved and packages rebuilt.

**Version tracking:** The `version:` field in each skill's frontmatter records which release last modified it (e.g., `version: v6.3`). During drift detection, the agent can compare this field against RELEASE_LOG.md to confirm skills are current. The `version:` field is not a recognized Claude Code frontmatter field — it is inert metadata for platform tracking purposes. It does not affect skill behavior, invocation, or display.

**Post-copy verification checklist (included in each release plan that modifies skills):**
For each modified skill:
- [ ] `_working/[version]/[skill-name]/SKILL.md` staged with complete rebuilt content
- [ ] `_previous/[skill-name]/SKILL.md` contains the pre-update version
- [ ] User confirmed "saved to skills"
- [ ] `_Skill-Packages/[skill-name].skill` rebuilt and current
- [ ] `_working/[version]/` cleaned

**Retention:**
- `_working/` is transient — cleaned after each release's "saved to skills" cycle.
- `_previous/` is overwrite-only — always contains exactly the last replaced version per skill.
- Production `.skill` packages at top level are permanent and current.
