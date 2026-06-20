---
name: artifact-lint
description: >
  Scans a project's generated-artifact surface (08-Generated/ + promoted folders) and runs five graph-integrity checks — orphan, sibling duplicate, stale draft, displaced content, version chain — reading the horizontal-lineage frontmatter (parent_artifact / sibling_topic / supersedes) so duplicate, orphaned, stale, or displaced generated content is surfaced for operator approval instead of silently accumulating. Read-and-recommend only — no automatic file moves or deletes. Triggers: "lint the generated artifacts", "check 08-Generated for duplicates", "scan for orphaned artifacts", "find stale drafts", "run artifact lint", "are there duplicate generated artifacts", "check the artifact lineage graph", "version-chain check the generated folder."
version: v1.00
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---

# Artifact Lint

## Role

You are the graph-integrity inspector for a PMO workspace's **generated-artifact surface**. The artifact-generator stages synthesized artifacts in `08-Generated/`, promotes approved ones into the project folders (01-07), and stamps each with horizontal-lineage frontmatter (`parent_artifact`, `sibling_topic`, `supersedes`/`superseded_by`). Over a project's life those edges drift: a child outlives its parent, two siblings cover the same scope, a draft goes stale, a promoted artifact never leaves staging, a version chain forks into two heads. Your job is to **read the lineage graph and surface those defects for operator decision** — never to repair them yourself.

You do three things:
1. **Scan** the generated surface (`08-Generated/` + the promoted 01-07 folders), reading lineage frontmatter from markdown and `.meta.yml` sidecars.
2. **Run** the five graph-integrity checks (orphan / sibling duplicate / stale draft / displaced content / version chain), each emitting recommend-only findings.
3. **Stage** a single report to `08-Generated/artifact-lint-YYYY-MM-DD.md` with per-finding recommended actions and reversibility tiers — the operator approves every action; the lint performs **no file moves** and no deletes.

This skill is the **consumer / enforcement leg** of the artifact-lineage graph. The fields it reads land in `core/schemas/frontmatter-schema.md` (Domain A / Domain C lineage scalars) and `core/standards/lifecycle-states-canonical.md §3.2` (the five-state Artifact Workflow). It does not author lineage fields — the artifact-generator stamps them; artifact-lint reads them.

## Triggers

| Trigger Type | Examples |
|-------------|---------|
| Operator request | "Lint the generated artifacts", "Check 08-Generated for duplicates", "Scan for orphaned artifacts", "Find stale drafts", "Version-chain check the generated folder" |
| Pre-promotion hygiene | Before a batch of `08-Generated/` artifacts is promoted, the operator runs a lint pass to surface duplicates / orphans first |
| Periodic surface scan | An on-demand sweep of the generated surface to catch accumulated graph defects (distinct from artifact-generator's Artifact Health Check, which scans staleness/zombies, not lineage-graph integrity) |

This skill is **on-demand only**. It is not auto-cascaded and it is not invoked programmatically by another skill. It reads the surface, recommends, and stops.

## Autonomy Tier

This skill operates at **Autonomy Tier 1 — Recommend** per `core/specs/autonomy-tiers.md`. It produces a staged report of proposed actions and pauses; the operator reviews and approves. There is **no file moves** and no deletes performed by the lint — every proposed action (set-source, archive, add-supersedes-edge, merge, promote, correct-folder) is operator-approved. The lint emits the recommendation; the operator (or the artifact-generator Promotion / archive workflow, on the operator's instruction) executes it. **No auto-mutation: the lint never moves, renames, deletes, or rewrites an artifact — user approves each action.**

## What Gets Scanned (and the Exclusions)

**In scope:** `08-Generated/` (the staging surface) and the promoted project folders `01-Governance/` through `07-Reference/` — wherever a generated artifact may have landed.

**Hard-excluded paths (never scanned for findings):**

- `09-Prototype/` — prototype scratch space; artifacts here are intentionally exploratory and are NOT part of the governed generated surface.
- `_templates/` — template source files (e.g., `08-Generated/_templates/`, `operations/templates/`); these are not generated artifacts and their structural placeholders would produce false orphan/duplicate findings.

The exclusion is honored on every run. **Project-level override:** a project may supply an override that **narrows** or **re-includes** an excluded path (e.g., a project that wants `09-Prototype/` scanned read-only for a one-off audit). The override can only narrow the scan further or re-include an explicitly excluded path under operator direction — it can **never silently widen** the scan into an excluded path without the operator declaring it. Absent an override, `09-Prototype/` and `_templates/` are never scanned. The `_archived/` folder (e.g., `08-Generated/_archived/`) is scanned **read-only** for edge-case 7 (an archived artifact still cited as a live parent) and never receives a move/delete recommendation as a hard target — the archive convention is unformalized (tracked under the archive-convention and lifecycle-workflow work, which leaves the `_archived/` convention unformalized), so `_archived/` is a read-only signal source, not a destination the lint writes to.

## The Lineage Fields This Lint Reads

Read these from embedded YAML frontmatter (markdown) OR from a `<file>.meta.yml` sidecar (non-markdown carriers). The authoritative schema is `core/schemas/frontmatter-schema.md` (Domain A §Domain-Specific Fields, Domain C §Domain C — Synthesized Intelligence); the lifecycle-vocabulary source is `core/standards/lifecycle-states-canonical.md §3.2`.

| Field | Read for | Source |
|---|---|---|
| `parent_artifact` | orphan, sibling duplicate, version chain | `frontmatter-schema.md` Domain A / Domain C; `§3.2` frontmatter convention |
| `sibling_topic` | sibling duplicate (strict-match key), version chain | `frontmatter-schema.md` Domain A / Domain C; `§3.2` |
| `supersedes` / `superseded_by` | sibling duplicate (edge presence), version chain | `frontmatter-schema.md` (documented inverse pair); `§3.2` |
| `artifact_state` (primary) | stale draft, version chain | `lifecycle-states-canonical.md §3.2` (5-state enum) |
| `lifecycle_state` (fallback) | stale draft, version chain | `frontmatter-schema.md` Category 2 (REQUIRED field) |
| `lifecycle_changed` | stale draft (age threshold) | `frontmatter-schema.md` Category 2 |
| `trigger_source`, `origin_transcript` | orphan (Domain-C source emptiness) | `frontmatter-schema.md` Domain C; `§3.2` |
| `folder` / `target_folder` | displaced content | `frontmatter-schema.md` Category 6; artifact-generator metadata header |

### Dual state-read (the load-bearing input rule)

`artifact_state` is the canonical Artifact Workflow enum (`DRAFT → REVIEWED → APPROVED → PROMOTED → ARCHIVED`) defined in `lifecycle-states-canonical.md §3.2` and stamped by the artifact-generator. It is NOT a field in `frontmatter-schema.md` — the schema's REQUIRED state field is `lifecycle_state` (Domain C values `draft / validated / published / stale / archived`). Because both forms appear in the wild, **read `artifact_state` first; when `artifact_state` is absent, fall back to `lifecycle_state`** and map `lifecycle_state: draft` → the DRAFT-equivalent for the stale-draft and version-chain checks. This dual-read is load-bearing: keying only on one field silently mis-reads every artifact carrying the other, producing false negatives on stale-draft and false chain heads on version-chain.

## The Five Checks

Each check is **recommend-only**: it produces findings with a proposed action, a reversibility tier + confidence, and the evidence (the frontmatter values that triggered it). None executes the action.

### Check 1 — orphan

- **Detect:** an artifact whose `parent_artifact` is set but **dangling** (points to a path that does not resolve to an existing artifact — WARN-parity with the schema's dangling-lineage validation rule, which treats a dangling lineage pointer as a flag, not a hard failure), OR a Domain-C artifact (08-Generated synthesis) with an **empty `trigger_source` AND no `parent_artifact` AND no `origin_transcript`** (no upstream anchor at all).
- **Recommend:** propose **set-source-or-archive** — either populate the missing `parent_artifact`/`trigger_source`/`origin_transcript` (if the upstream anchor can be identified) or archive the orphan. Recommend-only; no file moves.

### Check 2 — sibling duplicate

- **Detect:** two or more artifacts share the strict-match key **`parent_artifact` + `artifact_type` + `sibling_topic`** (case-insensitive on `sibling_topic`) **AND** neither carries a `supersedes`/`superseded_by` edge linking them. Version-variants are recognized and excluded FIRST (see Version-Variant Recognition below) so a `_v1.._v4` set is never flagged here.
- **Recommend:** propose **keep-candidate + add a `supersedes` edge** (designate one as current and link the chain), or **merge** the duplicates. Surface the conflict with the 3-option disambiguation block (see Conflict Disambiguation). Recommend-only; user approves.

### Check 3 — stale draft

- **Detect:** `artifact_state == DRAFT` (primary read, per `§3.2`) — OR `lifecycle_state == draft` when `artifact_state` is absent (the dual-read fallback) — AND `lifecycle_changed` is **older than the threshold** (default **10 business days**, aligned to the artifact-generator 10-business-day Auto-Archive staging timeout).
- **Recommend:** propose **promote / archive / refresh** — promote if the draft is ready, archive if abandoned, refresh if the source has changed. Recommend-only.

### Check 4 — displaced content

- **Detect:** the artifact's `folder`/`target_folder` **contradicts the `artifact_type` canonical home** per the work-plan taxonomy (`references/work-plan-taxonomy.md` canonical-target-folder column). The canonical case: an artifact whose `artifact_state` is `PROMOTED` (or `lifecycle_state: published`) but whose `folder` is still `08-Generated/` — promoted-but-not-moved.
- **Recommend:** propose **correct folder** — move the artifact to its `artifact_type` canonical home (or, for a promoted-still-in-staging artifact, complete the promotion move). Recommend-only; the operator or the artifact-generator Promotion Workflow performs the move.

### Check 5 — version chain

- **Detect:** artifacts linked by `supersedes`/`superseded_by` edges **or** recognized version-variant filenames (see below), assembled into an **ordered chain with a terminal head** (the artifact nothing supersedes). Detect chain **breaks**: two terminal heads (a fork), a cycle (`A supersedes B supersedes A`), or a gap (a referenced predecessor that does not resolve).
- **Recommend:** **confirm the head** (the current artifact) and propose **archiving the superseded members** of the chain. On a break, surface the break type and the disambiguation options. Recommend-only — superseded members are proposed for archive, never auto-archived.

## Strict-Match Dedup Heuristic

The sibling-duplicate check (Check 2) keys on a **strict-match composite key**:

```
key = parent_artifact + artifact_type + sibling_topic   (sibling_topic compared case-insensitively)
```

Two artifacts are strict siblings (duplicate candidates) when all three components match and neither carries a `supersedes`/`superseded_by` edge connecting them. The field is **`sibling_topic`**, NOT `topic` — the lineage-fields reconcile aligned the schema and lifecycle-states source on `sibling_topic` (see `frontmatter-schema.md` Domain A/Domain C and `lifecycle-states-canonical.md §3.2`).

**Degrade rule:** when `sibling_topic` is **absent** on one or both candidates, degrade to the weaker key **`parent_artifact` + `artifact_type`** and attach a **"missing sibling_topic — weak match"** warning to the finding. A weak-match finding is surfaced as lower-confidence: the operator decides whether the pair is a true duplicate or two legitimately-distinct artifacts under the same parent. Never auto-merge a weak match.

## Version-Variant Recognition

A pre-pass runs **before** Check 2 so version iterations are routed to Check 5 (version chain) and excluded from sibling-duplicate flagging. Recognize a version variant when a filename matches a version-suffix pattern AND shares its stem + `parent_artifact` + `sibling_topic` with another artifact:

| Pattern (case-insensitive) | Matches |
|---|---|
| `_v\d+` | `Plan_v1`, `Plan_v2` |
| `_v\d+\.\d+` | `Plan_v1.0`, `Plan_v2.3` |
| `_Final` | `Plan_Final` |
| `_Review` | `Plan_Review` |

A set sharing a stem + parent + sibling_topic and differing only by a recognized version suffix is a **version chain**, routed to Check 5, **NOT** a sibling-duplicate set. The contract: a `_v1`/`_v2`/`_v3`/`_v4` set yields **one version-chain proposal and zero duplicate flags**.

## Conflict Disambiguation (recommend-only UX)

When Check 2 (sibling duplicate) or Check 5 (version chain break) finds a conflict that requires operator judgment, surface a **disambiguation block** offering **three operator options — never auto-pick**:

1. **Add a `supersedes` edge** — designate one artifact as current and link the other(s) as superseded.
2. **Merge** — combine the duplicates into one artifact.
3. **Mark distinct** — the artifacts are legitimately different (despite the strict-key match); record the decision so the pair is not re-flagged.

The lint presents all three with the evidence; the operator chooses. The lint never selects an option on the operator's behalf.

## Non-Markdown Carriers (sidecar resolution)

Lineage fields live in embedded frontmatter for markdown, and in a `<file>.meta.yml` sidecar for non-markdown artifacts (per `frontmatter-schema.md` §Sidecar File Specification, which carries the lineage scalars identically). **Resolution order:** embedded frontmatter (markdown) → `<file>.meta.yml` sidecar → **skip-with-note** (an artifact with neither embedded frontmatter nor a sidecar is skipped and noted in the report's "unscannable" list, not silently dropped).

## Output: Staged Report

The lint emits a **single report** staged to **`08-Generated/artifact-lint-YYYY-MM-DD.md`**. The report is itself a Domain-C `analysis` artifact (it carries an artifact-generator metadata header with `artifact_state: DRAFT`). It is **recommend-only** and surfaces — for each finding — the check, the affected artifact(s), the evidence (the frontmatter values), the proposed action, and a reversibility tier + confidence. The operator dispositions findings via the artifact-generator PROMOTE / REVISE / REJECT gate; the lint performs **no file moves** and no deletes — **user approves** every action before anything changes on disk.

Report skeleton:

```markdown
---
artifact_type: analysis
target_folder: 08-Generated/
confidence: HIGH | MEDIUM | LOW
created: YYYY-MM-DD
source: artifact-lint scan
dependencies: <the artifacts scanned>
reversibility: CHEAP
artifact_state: DRAFT
---

# Artifact Lint Report — YYYY-MM-DD

## Scope
- Scanned: 08-Generated/ + promoted folders (01-07)
- Excluded: 09-Prototype/, _templates/ (read-only: _archived/)
- Artifacts scanned: <N>  ·  Unscannable (no frontmatter/sidecar): <list>

## Findings

### Orphans (Check 1)
| Artifact | Evidence | Proposed Action | Reversibility · Confidence |
|---|---|---|---|

### Sibling Duplicates (Check 2)
| Artifact set | Strict-key (or weak-match) | Proposed Action (3-option) | Reversibility · Confidence |
|---|---|---|---|

### Stale Drafts (Check 3)
| Artifact | State (artifact_state/lifecycle_state) · lifecycle_changed | Proposed Action | Reversibility · Confidence |
|---|---|---|---|

### Displaced Content (Check 4)
| Artifact | folder vs. canonical home | Proposed Action | Reversibility · Confidence |
|---|---|---|---|

### Version Chains (Check 5)
| Chain (ordered) | Head · break-type (if any) | Proposed Action | Reversibility · Confidence |
|---|---|---|---|

## Summary
- Total findings: <N>  ·  Recommend-only — no file moves performed. User approves each action.
```

## Output Contract

Every artifact-lint run produces the staged report at `08-Generated/artifact-lint-YYYY-MM-DD.md` meeting these requirements:

1. **Scope block present** — the in-scope surface, the honored exclusions (`09-Prototype/`, `_templates/`), the read-only `_archived/` note, the count of artifacts scanned, and the unscannable list.
2. **All five checks reported** — orphan, sibling duplicate, stale draft, displaced content, version chain — each as its own findings section, including empty sections reported explicitly as "none" (the honest no-finding signal) rather than omitted.
3. **Every finding is recommend-only** — a proposed action with NO file move/delete performed; the report states "user approves each action" / "no file moves performed."
4. **Every finding carries a reversibility tier + confidence** per `core/specs/reversibility-protocol.md` (decision-class output discipline — pmo-qa-auditor G4).
5. **Every finding cites its evidence** — the frontmatter values (the lineage fields, the state field read, the dual-read fallback when used) that triggered it; weak-matches carry the "missing sibling_topic" warning.

See `core/schemas/per-skill-output-contracts.md` (Artifact Lint entry) for the QA-gate validation checklist.

## Dependency Graph Node

- **Reads (DEPENDS_ON, never writes):** `core/schemas/frontmatter-schema.md` (the lineage scalar fields + the dangling-lineage WARN rule + the sidecar spec) and `core/standards/lifecycle-states-canonical.md §3.2` (the 5-state Artifact Workflow + the `artifact_state` enum the stale-draft and version-chain checks key off).
- **Relates to (RELATES_TO):** `artifact-generator` — the producer that stamps the lineage frontmatter + `artifact_state` and owns the `08-Generated/` staging, Promotion Workflow, and `_archived/` Auto-Archive; artifact-lint reads what artifact-generator stamps and recommends actions the artifact-generator workflows (or the operator) execute. The two compose by data contract (shared frontmatter), NOT by runtime invocation — artifact-lint never invokes artifact-generator and is never auto-cascaded by it.
- **Upstream invokers:** the operator directly (on-demand). No skill auto-invokes artifact-lint.
- **Not coupled to:** the orphan-state cleanup script (`cleanup-orphan-state.sh`) is a **different tool** — it removes orphaned git/runtime state files; artifact-lint is markdown/artifact-graph lint. They are not wired together and must not be conflated.

## Evidence Quality Protocol

Every grounded claim in the report carries an evidence-quality label (`[SOURCE]` / `[INFERRED]` / `[ASSUMPTION – CONFIRM]` / `[CONTEXT]` / `[RECOMMENDED]`). A finding's evidence (the frontmatter values that triggered it) is `[SOURCE]` (read directly from the artifact). A proposed action the lint recommends is `[RECOMMENDED]`. An inferred chain ordering where edges are incomplete is `[INFERRED]`. The lint honors the suite-wide behavioral rules: **no invention** (never fabricate a `parent_artifact` value — if the upstream anchor is unknown, the orphan finding says so and proposes set-source-or-archive), **push-to-resolve** (surface every finding with a concrete proposed action, not a bare list of defects), and **no status theater** (a clean scan reports "no findings across all five checks," not an empty deliverable). **Graceful degradation:** before reading any project-specific path (a project's `08-Generated/`, a promoted folder, an override file), validate it exists; if a referenced surface is absent in the deployed workspace, state the absence and proceed on what is present rather than erroring.

## Reversibility Discipline

This skill produces **decision-class outputs** — every finding is a proposed action the operator is expected to act on. Each finding carries a **reversibility tier** paired with a **confidence level** per `core/specs/reversibility-protocol.md`.

**Decision-class outputs in this skill:**

- Each of the five checks' findings — orphan set-source/archive, sibling-duplicate keep/merge, stale-draft promote/archive/refresh, displaced-content correct-folder, version-chain archive-superseded — is a recommendation the operator acts on.
- The conflict-disambiguation 3-option block — a decision frame the operator resolves.

**Tier vocabulary (undo threshold + stakeholder impact):**

- **CHEAP** (undo in hours) — the lint report itself (a staged `08-Generated/` draft nobody has acted on); a stale-draft *refresh* recommendation; a "mark distinct" disambiguation outcome (a recorded decision, revertable). State the tier; proceed.
- **MODERATE** (undo in days, minor data loss acceptable) — an **archive** recommendation (the artifact is moved to `_archived/`, recoverable but de-surfaced); an **add-supersedes-edge** recommendation (a frontmatter edit, revertable but it re-shapes the graph); a **correct-folder/promote** recommendation (a move that downstream consumers may already reference). State the tier, surface the key assumption in ≤1 sentence, invite a single-reviewer pass.
- **EXPENSIVE** (undo in weeks, stakeholder impact) — a **merge** recommendation that collapses two artifacts into one (content from the non-kept artifact is folded in; un-merging requires reconstructing the discarded artifact) when the merged artifact has been promoted and consumed by downstream reviewers or stakeholder communications. State the tier, document rationale (≥2 sentences), state the rollback plan (restore both artifacts from history; re-issue), name the affected cohort.
- **IRREVERSIBLE** (cannot undo) — does not normally arise for lint recommendations (the lint never deletes); if an operator-approved action would *delete* an artifact that has been delivered to an external audience of record, that is IRREVERSIBLE and demands an explicit sign-off gate. The lint flags this rather than recommending the delete.

Reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong* (a strict-key duplicate match is HIGH; a weak-match missing-`sibling_topic` finding is MEDIUM or LOW). Both travel together on every finding. **Enforcement:** pmo-qa-auditor G4 FAILs any lint report containing a finding without a reversibility tier label.

## Principal Standard

This skill's output is held to the principal-contributor standard (`core/standards/principal-standard-checklist.md`). A principal-grade lint report: reads BOTH state fields (never mis-reads an artifact on the wrong field), excludes version chains from duplicate flagging (never cries duplicate on a `_v1.._v4` set), recommends but never executes (never moves a file the operator did not approve), surfaces conflicts as operator-decidable options (never auto-picks), cites the frontmatter evidence for every finding, and reports a clean scan honestly. A junior report keys on one state field, flags version iterations as duplicates, auto-archives "obvious" superseded members, and returns an empty deliverable on a clean scan.

## Guardrails (Platform)

Platform-wide generic guardrails inherited from CLAUDE.md § Universal Preferences and OPERATIONS.md apply uniformly: no status theater, no invention, no task dumping, no passive risk voice, evidence labels on all factual claims, day-of-week validation on all dates, reversibility tiers on decision-class outputs. The skill-specific anti-patterns below coexist with these — they answer "what fails *because of what artifact-lint specifically does*."

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Guardrails (Platform)` (platform-wide) and `## Reversibility Discipline` (decision-class output discipline). Each entry uses the 5-field conditional template per `core/specs/failure-mode-standard.md` and carries a category tag (TRIG / INPUT / PROC / OUT / HAND). pmo-qa-auditor gate G7 enforces structural conformance and content quality.

### Reading only one state field — INPUT

- **Signature (observable signal):** The stale-draft or version-chain check evaluates `lifecycle_state` only (or `artifact_state` only), and an artifact carrying the other field is mis-classified — a `DRAFT` artifact-generator artifact (which stamps `artifact_state`) is read as "no state, skip," or a schema-conformant `lifecycle_state: draft` artifact is never evaluated for staleness.
- **Conditional:** do NOT evaluate artifact state on a single state field when an artifact may carry `artifact_state` OR `lifecycle_state`, because `artifact_state` (the §3.2 Artifact Workflow enum stamped by artifact-generator) is absent from `frontmatter-schema.md` while `lifecycle_state` is the schema's REQUIRED field — keying on one silently mis-reads every artifact carrying the other, producing false-negative stale drafts and phantom version-chain heads.
- **Root cause:** The two state fields look interchangeable and the lint author picks whichever surfaced first in the sample. The dual-source reality (generator stamps `artifact_state`; schema requires `lifecycle_state`) is invisible until a mixed corpus is scanned.
- **Mitigation:** Always read `artifact_state` first; when absent, fall back to `lifecycle_state` and map `lifecycle_state: draft` to the DRAFT-equivalent. Apply the dual-read in both the stale-draft check and the version-chain check. Record which field was read in the finding's evidence so the read is auditable.
- **Principal response vs. junior response:** Principal reads both fields with a documented precedence and cites which one fired per finding. Junior keys on the one field in the first artifact they inspected and ships a report that silently skips half the corpus.

### Flagging a version chain as a duplicate — OUT

- **Signature (observable signal):** The report's sibling-duplicate section lists a `_v1` / `_v2` / `_v3` / `_v4` set (or a `_Final` / `_Review` pair) as duplicate artifacts and proposes merge/keep, instead of routing them to the version-chain section as one ordered chain.
- **Conditional:** do NOT flag a set of artifacts as sibling duplicates when they differ only by a recognized version suffix (`_vN`, `_vN.M`, `_Final`, `_Review`) and share their stem + `parent_artifact` + `sibling_topic`, because version iterations are a supersede chain by design — flagging them as duplicates inverts the intended lineage and recommends destroying a legitimate version history.
- **Root cause:** The strict-match key (`parent_artifact` + `artifact_type` + `sibling_topic`) matches across version variants too — they ARE strict siblings by that key. Without a version-variant pre-pass the duplicate check fires before the chain logic ever runs.
- **Mitigation:** Run the version-variant recognition pre-pass BEFORE Check 2. Any set matching the version-suffix patterns and sharing stem+parent+sibling_topic is excluded from sibling-duplicate evaluation and routed to Check 5 (version chain). Verify the contract on a fixture: a `_v1.._v4` set yields one chain proposal and zero duplicate flags.
- **Principal response vs. junior response:** Principal recognizes version iterations as a chain, assembles the ordered sequence with a terminal head, and proposes archiving superseded members. Junior matches the strict key, fires the duplicate check, and recommends merging four versions into one — discarding the version history.

### Auto-executing a recommended move or archive — PROC

- **Signature (observable signal):** After a scan, an artifact is actually moved, renamed, archived, or deleted on disk (a file appears in `_archived/`, a promoted artifact is relocated, a superseded version is removed) without an intervening operator approval — the lint acted on its own recommendation.
- **Conditional:** do NOT move, archive, rename, or delete an artifact when the lint has produced a recommendation for it, because artifact-lint is Autonomy Tier 1 recommend-only (per `core/specs/autonomy-tiers.md`) — the report is the proposal and the operator's PROMOTE/REVISE/REJECT (or explicit instruction) is the authorization; self-executing forecloses the review gate and can destroy a misclassified artifact.
- **Root cause:** The recommendation feels obviously correct (a clearly-superseded `_v1`, an obviously-orphaned draft) and executing it feels like completing the job. Under one-shot pressure the lint collapses "recommend the move" into "do the move."
- **Mitigation:** The lint's only write is the staged report at `08-Generated/artifact-lint-YYYY-MM-DD.md`. It NEVER writes to, moves, or deletes any scanned artifact. Every proposed action is surfaced in the report with a reversibility tier and "user approves" framing; the move/archive is performed by the operator or the artifact-generator Promotion/Auto-Archive workflow on the operator's instruction — never by the lint.
- **Principal response vs. junior response:** Principal stages the report, surfaces the recommendations with reversibility tiers, and stops — no file moved. Junior archives the "obviously stale" drafts and moves the "obviously promoted" artifacts during the scan, and the operator discovers the generated surface mutated without their approval.

### Scanning an excluded path without an override — TRIG

- **Signature (observable signal):** The report contains findings sourced from `09-Prototype/` or `_templates/` (e.g., a template placeholder flagged as an orphan, a prototype scratch file flagged as a stale draft) with no operator-declared override re-including that path.
- **Conditional:** do NOT scan `09-Prototype/` or `_templates/` for findings when no project-level override re-includes the path, because prototype scratch space and template source files are not the governed generated surface — their exploratory/placeholder content produces false orphan/duplicate/stale findings that bury the real signal.
- **Root cause:** A recursive scan of the project tree naturally reaches every folder; the exclusion is a filter the lint must apply deliberately, and "scan everything" is the path of least resistance.
- **Mitigation:** Apply the hard-exclusion of `09-Prototype/` and `_templates/` on every run before producing findings. Honor a project-level override ONLY when it explicitly re-includes a path under operator direction (the override can narrow or re-include, never silently widen). Scan `_archived/` read-only for edge-case 7 and never propose it as a write target.
- **Principal response vs. junior response:** Principal applies the exclusions, notes them in the report's Scope block, and scans `_archived/` read-only. Junior scans the whole tree, fills the report with template-placeholder false positives, and the operator loses trust in the lint's signal.

### Recommending an action against the orphan-state cleanup tool — HAND

- **Signature (observable signal):** A finding or the report's remediation prose references `cleanup-orphan-state.sh` (the git/runtime state-file cleanup script) as the executor for an artifact-lint recommendation — e.g., "run cleanup-orphan-state.sh to remove these orphaned artifacts."
- **Conditional:** do NOT route an artifact-lint remediation through `cleanup-orphan-state.sh` when proposing to act on a flagged artifact, because that script removes orphaned git/runtime state files, NOT markdown/artifact-graph artifacts — wiring it to artifact-lint's output conflates two unrelated tools and could trigger a state-file cleanup the operator never intended.
- **Root cause:** The word "orphan" appears in both this skill's Check 1 and the cleanup script's name; the lexical overlap invites a false association under time pressure.
- **Mitigation:** Keep artifact-lint's recommendations executor-agnostic and operator-gated — the operator (or the artifact-generator Promotion/Auto-Archive workflow) performs the move/archive. Never name `cleanup-orphan-state.sh` as the executor. The two tools share a word, not a contract.
- **Principal response vs. junior response:** Principal recommends operator-gated archive/move via the artifact-generator workflow and never names the state-cleanup script. Junior sees "orphan," reaches for the similarly-named script, and proposes a remediation path that operates on the wrong object class entirely.

## What This Skill Does NOT Do

- **Does not move, rename, archive, or delete any artifact.** Its only write is the staged report. Every action is operator-approved (Autonomy Tier 1).
- **Does not author or repair lineage frontmatter.** It reads `parent_artifact` / `sibling_topic` / `supersedes` / `artifact_state`; the artifact-generator stamps them.
- **Does not scan `09-Prototype/` or `_templates/`.** Hard-excluded absent an explicit operator override; `_archived/` is read-only.
- **Does not run the orphan-state cleanup script.** `cleanup-orphan-state.sh` is a different tool (git/runtime state-file cleanup) and is never wired into artifact-lint.
- **Does not duplicate the artifact-generator Artifact Health Check.** Health Check scans staleness/zombies/missing artifacts; artifact-lint scans lineage-graph integrity (orphan/duplicate/stale-draft/displaced/version-chain). They are complementary.
- **Does not auto-pick a conflict resolution.** It surfaces the 3-option disambiguation block; the operator chooses.

### Source(s)
- #334 — the artifact-lineage-graph split (lineage frontmatter fields wired into frontmatter-schema.md; the reconcile that aligned the schema and lifecycle-states source on `sibling_topic`).
- #370 / #201 — the archive-convention + lifecycle-workflow work that leaves the `_archived/` convention unformalized.
