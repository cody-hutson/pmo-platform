<!-- reference-durability: allow-link -->
# Stage 3: Bundle

> **Source:** Stage 3 originating spec
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Group Approved issues into a versioned Milestone (release), applying dependency ordering, scope coverage analysis, and capacity heuristics so the operator can commit to a release scope with confidence.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Task dependency mapping | Cross-file/cross-domain deps for single-operator PMO |
| Governance Focus | Dependency review, scope clarity | Dependency chain validation, Release Scope Coverage Analysis |
| Artifact Inputs | Charter/PBI, requirements | GitHub Issues in Approved status with triage-validated fields |
| Artifact Outputs | Work breakdown, dependency list | Milestone, dep-ordered list, allocation summary, coverage matrix |

Key compression: Ref Model assumes cross-team dependency mapping with integration architects. Ours: agent analyzes backlog, human decides Milestone scope.

## 3. Persona

| Role | Skills-Map Ref | Autonomy |
|---|---|---|
| Decision maker: Human operator | — | Tier 3 (Human-only) |
| Release planning assist: Release Mgr Skill 13, Mode 1 | Dependency analysis, scope coverage, capacity | Tier 2 (Recommend) |
| Strategic alignment: Portfolio Mgr Skill 1, Mode 2 | Priority sequencing, strategic alignment | Tier 2 (Recommend) |

> **Persona card:** see [`release-personas.md §Stage 3`](../specs/release-personas.md) for the chip-prompt persona card embedded in hub-spoke prompts.

## 4. Inputs
From Triage: all issue metadata, Decision Date, Approved status.
Set at Bundle: Milestone assignment, version number, bundle sequence, Release Class declaration in milestone description (per [release-class-taxonomy.md](../specs/release-class-taxonomy.md); the Release Class is declared in the milestone description for all releases going forward).
Contextual: full Approved backlog, existing Milestones, dep graph, file contention map, RELEASE_LOG.md velocity data.

## 5. Process
**Phase A (Agent, Tier 1/2):** A1 Release Readiness gate check (per procedure below; invokes Template-Conversion Rule for `observation`-labeled candidates BEFORE evaluating G3 criteria — see Template-Conversion Rule block below), A2 dependency graph construction (chains, cycles, depth, critical-path — per § A8 below), A3 Release Scope Coverage Analysis (Y/Partial/N per issue), A4 capacity heuristics (5-8 issues max, 60/20/20 allocation target — the governing capacity ceiling is the risk-weighted point-band at [`bundle-composition-doctrine.md § 3 Step 5`](../standards/bundle-composition-doctrine.md); the 5-8 item-count is a secondary readability heuristic, not an independent cap), A5 bundle recommendation (ordered list, allocation, coverage matrix, contention, version rec, exclusions with gate results). A5 additionally surfaces any related-issue cluster detected per **A5.1** (≥3 coordinated Approved issues), with a recommended tracking primitive from the A5.1 selection table for operator confirmation at Phase B1.

**A5.1 — Related-Issue-Cluster Detection & Tracking-Mechanism Selection (per the cluster-tracking design):** A pre-bundle backlog-scan signal that recognizes when scattered Approved issues — not yet milestoned — form a coordinated cluster that warrants a single tracking container. A5.1 **owns the detection threshold + the selection rule**; it **routes a detected cluster onto already-existing primitives and invents no new mechanism** (the `cluster:` / `epic:` / `project:` label axes and GitHub native sub-issues / Projects all ship today). A5.1 cites [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md) for the primitive definitions (owns neither) and [`work-item-type-schema.md § 1.2.1`](../../../core/schemas/work-item-type-schema.md) for the GitHub adapter mappings.

*Part 1 — Detection predicate (reproducible).* A candidate **related-issue cluster** is detected when **BOTH** hold over the Approved backlog (`status: approved`, not yet milestoned):

> **(C-1) Shared-goal signal — ANY of:**
> - **(a)** ≥3 Approved issues carry the **same `cluster:<name>` label** (the existing triage cluster axis), OR
> - **(b)** ≥3 Approved issues each share the **same ≥2 non-hot Affected-Files paths** read from the body Affected-Files field — a **single counting predicate** (the cluster must co-occur on at least two non-hot paths, so co-membership on one commonly-edited governance file cannot over-fire). A path is **hot** — and excluded from the count — by a **deterministic frequency rule computed from the candidate set itself** (no maintained list): a path is **hot when it appears in the Affected-Files field of a strict majority (> 50%) of the Approved-backlog candidates**. A surface touched by most open Approved work is a broadly-edited governance/hot file, not a coordination signal; the strict-majority threshold is above the cluster floor (3), so it excludes governance files without swallowing a genuine small cluster on any realistic backlog. Because the share is computed live from the same candidate population the predicate scans, the exclusion is **reproducible without any hardcoded or hand-maintained file list**, OR
> - **(c)** ≥3 Approved issues share a **Dependencies-field edge to a common issue** (a shared dependency hub — the centre of a dependency star).
>
> **AND (C-2) Coordination signal — ANY of:**
> - the issues declare **inter-issue `Blocked by:` / `Depends on:` edges among themselves** (a dependency chain, not independent items), OR
> - the issues must **land in a specific order** to deliver a coherent capability, stated as a sequencing note in ≥1 body, OR
> - the issues share **epic co-membership** — the same `epic:<thrust>` label OR a common `type:epic` parent. Epic co-membership is a coordination signal that exists **before** any inter-issue edge or ordering note is written (the common pre-triage state), and it is reproducible from labels/parent links alone — so a genuinely coordinated cluster whose members do not yet cite each other is still detected.

**Threshold = ≥3.** The `≥3 ∧ coordination` conjunction is the false-positive bound: three issues sharing a `cluster:` label *without* any C-2 coordination signal is ordinary triage-clustering, not a tracking-worthy cluster — the C-2 conjunct (inter-issue edges, an ordering note, OR epic co-membership) is what distinguishes a pile of thematically-similar tickets from a coordinated initiative needing a container. Detection is **Tier 1 advisory** — surfaced at Phase A5, never auto-acts (consistent with A5's recommend posture). Reproducible detection (C-1(a) cluster-label co-membership; C-1(b) frequency-ranked non-hot Affected-Files co-occurrence; C-1(c) shared Dependencies hub; C-2 epic co-membership via `epic:<thrust>` label or `type:epic` parent — all read from labels, parent links, and the body Affected-Files / Dependencies fields):

```bash
# C-1(a): cluster-label co-membership among Approved issues
gh issue list --label "status: approved" --json number,labels,body \
  --jq 'group_by(.labels[].name | select(startswith("cluster:"))) | .[] | select(length >= 3)'

# C-1(b): the hot-path set is computed from the candidate set itself (no maintained list).
# A path in a strict majority (> 50%) of Approved candidates is hot and dropped; the
# cluster fires when >= 3 issues co-occur on the SAME >= 2 surviving (non-hot) paths.
gh issue list --label "status: approved" --json number,body | python3 - <<'PY'
import json, re, sys, itertools
from collections import Counter, defaultdict
issues = json.load(sys.stdin)
def paths(body):
    m = re.search(r'(?is)affected[ -]files.*?(?:\n\n|\Z)', body or '')
    return set(re.findall(r'`([^`]+)`', m.group(0))) if m else set()
per = {i['number']: paths(i['body']) for i in issues}
n = len(per) or 1
freq = Counter(p for s in per.values() for p in s)
hot = {p for p, c in freq.items() if c > n / 2}    # strict majority => broadly-edited/hot file
non_hot = {num: (s - hot) for num, s in per.items()}
# group issues by each non-hot path-PAIR; a cluster needs >= 3 issues on the same >= 2 paths
by_pair = defaultdict(set)
for num, s in non_hot.items():
    for pair in itertools.combinations(sorted(s), 2):
        by_pair[pair].add(num)
clusters = {pair: sorted(members) for pair, members in by_pair.items() if len(members) >= 3}
print(json.dumps({" + ".join(p): m for p, m in clusters.items()}, indent=2))
PY

# C-2: epic co-membership is reproducible BEFORE any inter-issue edge exists
gh issue list --label "epic:<thrust>" --json number --jq 'length >= 3'
```

*Part 2 — Selection rule (which existing primitive for a detected cluster).* When C-1 ∧ C-2 fires, the spoke recommends ONE tracking primitive via this decision table — **first matching row wins** (most-specific container first). All four targets already exist; the rule is the net-new artifact. The choice is **operator-confirmed at Phase B1**: the spoke recommends the row + rationale in the A5 bundle-recommendation comment; the operator accepts or modifies.

| If the detected cluster is… | Track it as… (existing primitive) | Why |
|---|---|---|
| **Bounded, single-milestone-sized** (fits one release's point-band per the bundle-composition doctrine) with **inter-issue deps** | **GitHub native parent/sub-issue** links (one parent issue, children via native sub-issue) | Native deps + rollup; smallest container that survives one milestone. The `BELONGS_TO` realization per the GitHub adapter mapping. |
| **Multi-milestone capability** (the cluster will span ≥2 releases / be sliced into several milestones) | **`type:epic` umbrella issue + `epic:<thrust>` label** on all members | `type:epic` = the Agile umbrella kind; `epic:<thrust>` groups children for landscape queries. |
| **Long-running multi-epic initiative** (the cluster is itself one thrust within a larger program) | **`project:<name>` label** on all members (+ a GitHub **Project board** if active WIP-tracking is wanted) | `project:<name>` = the top-tier initiative grouping; the GitHub Project board = the `scope: board` set-aggregate realization per the GitHub adapter mapping. |
| **Capability-cluster recognition only** (thematic grouping, no coordinated container needed yet) | **`cluster:<name>` label** only (no umbrella) | The lightest primitive — the existing triage cluster axis; the detected-but-not-yet-container-worthy floor. |

A5.1 composes with — does not re-run — the G3-08 in-bundle similarity-routing gate: G3-08 detects duplicate/similar pairs *within one candidate bundle*, whereas A5.1 recognizes a coordinated cluster *across the Approved backlog*. Both are relatedness signals; the selection rule cites G3-08 as the sibling within-bundle dup-signal and leaves its evaluation to the gate. A5.1 is also distinct from the cross-milestone A9.6 Parallelization Map / A9.7 Cascading-Rebundle blocks (those handle relationships *between milestones*; A5.1 handles *pre-milestone* cluster recognition). **Cutover discipline:** Applies to all releases entering Stage 3 going forward.

**Template-Conversion Rule invocation (per gate-criteria-spec.md):** Phase A1 reads candidate-issue labels BEFORE evaluating G3 criteria. Any candidate carrying the `observation` intake-tier label halts with the failure signal `BUNDLE-BLOCKED: observation-template requires conversion` per [`gate-criteria-spec.md § Template-Conversion Rule`](../../../core/schemas/gate-criteria-spec.md#template-conversion-rule). Conversion path: route candidate back to Stage 2 Triage as a "promote observation" sub-step (re-run G1-02 observation-branch promotability; draft improvement.yml body; operator approves; body rewritten + label transitions `observation` → `improvement` + title rewritten to the informativeness floor (drop any `[Observation]:` prefix; no `[Category]:` prefix added — type is on the label); issue re-enters G1 evaluation under improvement-template applicability). Out-of-conversion paths (operator decision): (A) drop bundle binding (issue stays `observation`, milestone removed); (B) operator override + force-bundle with `[ASSUMPTION – CONFIRM]` markers + deviation log entry. **Cutover discipline:** Applies to all releases going forward.

**A8 — Critical-Path Analysis (CPM / longest-chain over typed-dep edges) (per the A8 CPM analysis):** After A2's Kahn's BFS topological sort completes, Phase A runs a single forward-pass DP-DAG longest-path relaxation over the emitted topo-sorted sequence to compute the **schedule-determining chain** — the longest dependency-determined chain across the release graph. The chain is emitted as a gate-signal at the Stage 3 Bundle approval surface (presented to operator at Phase B1 review) AND persisted at the durable-artifact surface (`release-planner` Mode B `## Dependency Graph` H2's new `### Critical Path` H3 — see [`release/skills/release-planner/SKILL.md`](../../skills/release-planner/SKILL.md) Mode B Output Format row 2). Same algorithm, two emit sites — Bundle gate AND release plan artifact.

- **Algorithm:** DP-DAG (dynamic programming over Kahn's-emitted topo-sorted DAG) per [`references/dependency-analysis.md` § Step 5: Longest-Path Computation (CPM)](../../skills/release-planner/references/dependency-analysis.md). Composes natively with the existing Kahn's BFS (ADR-1) — no parallel graph machinery; preserves the priority-desc → issue-asc tie-breaker. Complexity O(V+E).
- **Degraded-mode default (per the D-DegradedMode RATIFY decision):** Degraded mode is the **DEFAULT** until typed-dep substrate populates per-edge metadata for every in-bundle edge. Activation predicate is `any-untyped-edge` — if ANY edge lacks typed metadata, the whole computation runs in degraded mode and the output carries the `[DEGRADED-MODE: ...]` annotation. Transition to typed mode fires automatically when every edge carries typed metadata; no operator-cutover ceremony, no `.mode` flag.
- **Canonicalization 1 (algorithm choice):** DP-DAG over Floyd-Warshall over longest-chain heuristic — composability with existing Kahn's wins; Floyd-Warshall requires parallel adjacency-matrix machinery with no fidelity gain on sparse release DAGs. See `dependency-analysis.md § Canonicalization 1` for full rationale.
- **Canonicalization 2 (degraded-mode activation predicate):** any-untyped-edge activates degraded mode for the entire bundle (binary all-or-nothing) — prevents mixed-signal output where a chain length number's semantic interpretation varies edge-by-edge. See `dependency-analysis.md § Canonicalization 2`.
- **Read-surface coordination:** `read_dependencies(issue_number) → List[TypedEdge]` is the opaque interface owned by the typed-dep substrate; consumes the resolved output via `is_typed_edge(edge)` field-presence check. Body Dependencies field is the canonical read-surface per `ticket-information-architecture.md § Conflict Resolution` and per Stage 6 Model A adoption (body→native one-way mirror).
- **Gate impact:** A8 output is informational at Stage 3 (presented at Phase B1 review for operator awareness of the schedule-determining chain); not a blocking gate criterion. AC#3 of A8 contracts adding a schedule-network-fitness success signal to `release-process-fitness.md § 1`, closing the audit dimensional blind spot identified by the audit-dimensional gap.
- **Cutover discipline:** Applies to all releases going forward.

**A9.5 - Roadmap-Cascade Validation: RETIRED (ADR-012, 2026-06-02).** Roadmap-cascade validation is de-scoped: roadmap instances are operator-local, so in-repo cascade detection no longer runs. The G3-13 gate criterion is a numbered tombstone in [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md). No cascade output emitted at Bundle.

**A9.6 — Parallelization Map (standing milestone-description convention):** Every Milestone reaching Stage 3 Bundle carries a dated `## Parallelization Map (recorded YYYY-MM-DD)` section in its GitHub description — a durable, queryable record of which other in-flight milestones this milestone may run in parallel with vs. is hard-blocked by vs. is soft-coupled to. The map exists so operators stop re-deriving the parallelization answer ad-hoc on each ask, and so a single artifact is reconfirmed at the boundaries where it can go stale (Stage 3 A7 refresh, Stage 4 Phase A0 entry). Composes with A6 ("rationale-in-description" precedent) — same persistence surface (milestone description), same `gh api repos/.../milestones/<N> --jq .description` read-surface.

The map carries a bidirectional verdict + an evidence-cited per-edge table + an embedded reconfirm procedure. Authoring shape (drafted by the `release-planner` skill at its Mode B emit time; operator approves at Phase B1 alongside Outcome Statement + Release Class):

```
## Parallelization Map (recorded YYYY-MM-DD)

**Verdict:** [Tier-A clean / Tier-B soft-coupled / Tier-C blocking-dep / Tier-S structural-blast-radius — bidirectional scan]

| Other milestone | Direction | Edge type | Body confirmation |
|---|---|---|---|
| v<N.M> | this-blocks-other / other-blocks-this / bidirectional | hard / soft / file-contention / structural-blast-radius | <evidence cite — for a structural-blast-radius edge, the mover-classifier + F1–F6 sweep verdict line + the intersecting form(s); for a **version-slot contention** the same `structural-blast-radius` edge type is reused with the intersecting `Δversion/<claim-key>` token + both releases' provisional versions as the evidence (Step 2a) — no separate edge type> |

**Reconfirm procedure:** Run hard-vs-soft scan via:
`gh issue list --milestone "<this milestone>" --state open --json number,body --jq '.[] | select(.body | test("(?i)blocked by|depends on|requires|after #[0-9]+"))'`
AND, for any sibling milestone whose File Change Matrix declares a rename / relocate / delete, re-run the structural-blast-radius mover-classifier + F1–F6 sweep and re-test the intersection predicate (see the Structural-Blast-Radius axis below)
AND, for any sibling milestone whose **provisional-version intent has changed** since the map was recorded, re-mint the `Δversion/<claim-key>` token (Step 2a) and re-test the intersection — a version-only collision has no mover event to trip the rename/relocate/delete trigger, so this clause is its dedicated staleness path.

Reconfirmed at Stage 3 A7 refresh and Stage 4 Phase A0 entry; stale-dated map = finding.
```

**Hard-vs-soft edge-semantics classifier (reproducible, not judgment-only):** the same classifier `release-planner` applies during dep-graph construction is also applied here so the map is reproducible by any operator/spoke re-running the procedure:

| Class | Trigger language in issue body | Action |
|---|---|---|
| Hard | "blocks", "depends on", "requires", "after #N" | enters bidirectional graph as dep |
| Soft | "composes with", "coordinates with", "adjacent to", "relates to" | does NOT enter graph; informational |
| File-contention | "same file as #N", "edits same section" | enters Contention Map only, not dep graph |
| Structural-blast-radius | a sibling's edit-set intersects this release's structural surface — computed by the mover-classifier → F1–F6 sweep (`git`-computed; see the axis definition below). Pre-branch fallback (no release branch exists yet at Stage 3): the sibling's File Change Matrix `change_type` declaring rename / relocate / delete. | enters the Parallelization Map as a serialization edge (Tier-S); NOT the dep graph |

The full classifier note is the Hard-vs-Soft Edge Classifier in the release-planner dependency-analysis reference.

**Disambiguation from sibling-surface scope:** the Parallelization Map convention is the *standing-reference + reconfirm* layer; it is NOT the gate-emission surface. Two adjacent surfaces — distinct scopes:
- **Gate emission (G3-07 cross-milestone-sequence check) — runs at Stage 3 Phase A1 firing time** — defined in the Gate 3 Release-Readiness criteria. Emits PASS/FAIL on cross-milestone dep edges at the moment the Bundle gate evaluates. Does NOT persist between firings.
- **File-contention always-emit pattern — runs at the `release-planner` skill's Mode B emit time** — its Mode B Output Format always emits a `## File Contention Map` even when no file contention is detected (positive-signal pattern). Emit-once-per-release-plan; not a standing milestone-description artifact.

This A9.6 convention covers the standing/durable/reconfirmable record that those two surfaces do not. Three surfaces, three scopes — not conflated.

**A9.6.1 — Structural-Blast-Radius (Path-Invalidation) contention axis.** A third contention class sits alongside the ticket-dependency (Hard) and same-path (File-contention) classes above: **structural blast radius**. A file-mover release — one that renames, relocates, deletes-and-recreates, or restructures a directory of durable-corpus files — invalidates path assumptions for every concurrent release whose edit-set references the moved/deleted paths, even when the two releases carry **no ticket-dependency edge and no same-path content overlap**. This is the collision class the Hard and File-contention rows are structurally blind to (a sibling that references a renamed path by a relative `../` link shares no literal path with the mover and declares no dependency on it). A release intersecting another's structural surface is a **serialization point, not a parallel candidate**.

*Step 1 — produce the mover-set (reproducible 4-token git mover-classifier).* Deterministic, re-runnable by any operator/spoke; status codes map to git ground truth:

| Signal token | Definition | Reproducible detection command (repo-agnostic) |
|---|---|---|
| `RENAME` | a path renamed in place (same directory, new basename) | `git diff --name-status --find-renames=50% <base>..<head>` → `R` lines, dirname unchanged |
| `RELOCATE` | a path moved across directories (path prefix changed) | `git diff --name-status --find-renames=50% <base>..<head>` → `R` lines, dirname changed |
| `DELETE-RECREATE` | a path deleted (with or without a near-identical re-add elsewhere) | `git diff --name-status <base>..<head>` → `D` lines. A standalone `D <path>` is a mover unconditionally — not gated on a recreate being rename-paired — so a sub-threshold copy+delete still enters the sweep via the pre-move baseline tree |
| `DIR-RESTRUCTURE` | ≥2 paths under a common directory prefix all RENAME / RELOCATE / DELETE in one release | group the above by leading directory prefix; ≥2 movers sharing a prefix = a subtree restructure |

The mover-set = `{renamed-from} ∪ {renamed-to} ∪ {relocated, both ends} ∪ {deleted}`, plus restructured-subtree roots.

*Step 2 — compute the cross-release structural surface `SURFACE(R)` via the F1–F6 ref-form sweep.* Detection of the rewrite/break surface of a moving set is the canonical job of the **ref-form sweep** in [`doc-corpus-reorg-ref-forms.md`](../protocols/doc-corpus-reorg-ref-forms.md) (the same sweep Stage 5 Phase A3.2 fires for within-release rewrite-completeness); the cross-release axis **consumes that protocol parameterized by the mover-set's old/new path pairs** rather than re-deriving a second surface enumerator. For a deleted/renamed-from path the inbound forms run against the **pre-move baseline tree** (`git show <baseline>:<old-path>` exists where HEAD does not), because the sibling's edit-set still contains references to the old path string. The cross-release `SURFACE(R)` is the union of the REWRITE-dispositioned paths across **F1 (module-rooted) + F2 (relative-inbound) + F3 (root-escape) + F5 (retained-sibling→mover) + the in-tree half of F6 (governed mirror-pair)**. **F4 (mover-internal-outbound) is EXCLUDED from the cross-release intersection** — F4 links live *inside* the moving file and break because the mover's own base path changes; rewriting them is R₁'s own Stage-5 Phase A3.2 obligation, not an edit to the target files, so a sibling editing those targets is not a cross-release contention. Including F4 would over-serialize against the repo's highest-traffic governance files (the over-serialization guard). For F6, only **in-tree mirror pairs** enter the git predicate; a workspace-mirror partner (`~/.claude/rules/*`) is out-of-tree and inert in a `git log origin/main` predicate — that half is a deploy-check (Check 9) concern, not the cross-release surface.

*Step 2a — add the version slot as a contended axis (version-slot virtual-path token).* The structural surface above is path-derived, but the **version number a release intends to claim is itself a contended concurrent-release resource** — two in-flight releases racing for the same version slot collide exactly as two releases editing the same file do, yet the version is not a path, so the path-derived `SURFACE(R)` is blind to it. The version slot enters the **same** predicate as a reserved synthetic token, with no change to the operator or the operand types:

- **Token.** Each release contributes a **version-slot virtual-path token** `Δversion/<claim-key>` to the predicate operands. `<claim-key>` is the release's provisional-display version (the **intent-to-bump** value declared at the Stage 4 D-Version gate per the founding `version-claim-determinism` ADR — a release in-pipeline declares a bump-class + provisional display, not a bound `vX.Y`), canonicalized to **the integer tuple `<major>.<minor>.<patch>`** that the canonical version grammar's `version_parse` produces (`release/tools/version-grammar.sh`): leading zeros stripped, an absent patch coerced to `0`. The token keys on **slot identity, not spelling** — `v2.06`, `v2.6`, and `v2.6.0` all parse to `(2, 6, 0)` and therefore all mint the **same** token `Δversion/2.6.0`. Keying on the raw display string instead would mint two distinct tokens for `v2.06` vs `v2.6` and silently miss the collision (a false negative — the dangerous direction); the tuple form forecloses it by reusing the grammar's one parser rather than a second normalizer.
- **Where it goes.** The token is added to **`SURFACE(R)`** (the slot R is claiming) and to each sibling's **`EDITSET(R')`** (the slot R' intends to occupy). `Δversion/` is a reserved sentinel prefix that cannot collide with any real repo path (no corpus path begins with `Δversion/`), so the token is inert to every real-path consumer (e.g. a `git show <baseline>:<path>` read) and cannot be produced by a file edit — it lives only in the in-memory set the predicate evaluates.
- **Predicate unchanged.** `serialize(R₁, R₂) := EDITSET(R₂) ∩ SURFACE(R₁) ≠ ∅` is **not modified**. When two releases canonicalize to the same claim-key, the shared `Δversion/<k>` token sits in both `EDITSET(R₂)` and `SURFACE(R₁)`, the intersection is non-empty, and the pair is a serialization point on the (now version-inclusive) structural axis — flagged by the same machinery, the same verdict tier, and the same three downstream gates (Stage 4 A4 / Stage 9 G-PR9 / Stage 12 Phase A.5) that flag a file-surface overlap. No new predicate, no new edge type, no new gate.
- **Catch-point honesty (advisory at Stage 3, authoritative at Stage 4).** The version token inherits §A9.6.1's Stage-3-advisory / Stage-4-authoritative split, but for a *different reason* than the path surface: version assignment is a Stage-4 D-Version act, so at Stage 3 the provisional version may not yet exist. Stage 3 keys the token on the milestone-description provisional version **if already recorded**, else records `version-axis: deferred to Stage 4`; the **authoritative** version-axis intersection runs at **Stage 4 A4** (where the provisional version is bound in the release plan) and is re-confirmed at **Stage 9 G-PR9 / Stage 12 Phase A.5**.
- **Coverage boundary (stated, not implied).** The token fires only once **both** releases have bound **equal** canonicalized provisional-display strings. The bump-class-relative race — two releases both intending "the next minor off the same baseline" before either binds a concrete provisional string — is **not** detected by this token (each binds next-free independently and order-dependently at Stage 4, so the two operands may legitimately differ); that residual race is caught by the atomic compare-and-swap claim at merge (the authoritative resolver in the `version-claim-determinism` capability), not by this axis. The axis is a **detect-at-planning, defense-in-depth** surface: a CURRENT version-axis verdict is **not** a claim guarantee — only the atomic claim at the merge tag is — so the axis adds early signal without false safety.

*Step 3 — the intersection predicate (the serialization decision).* For each concurrent/planned sibling release R₂: `serialize(R₁, R₂) := EDITSET(R₂) ∩ SURFACE(R₁) ≠ ∅`. `true` → R₁ and R₂ are a serialization point (one merges, the other re-baselines); `false` → parallel-safe on the structural axis (still subject to the Hard + File-contention axes). The surface is bounded to the mover-set's own rewrite/break surface (the sweep is parameterized by the mover-set, never the whole repo) — a sibling edit outside the surface is explicitly not a serialization signal.

**Catch-point honesty.** At **Stage 3 Bundle no release branch exists yet**, so the git mover-classifier (which needs `base..head`) cannot run, and a zero-ticket-edge structural collision typically carries no mover-language in either issue body — therefore Stage 3 is an **advisory pre-filter** keyed on each sibling's File Change Matrix `change_type`. The **authoritative** structural detection runs at **Stage 4 A4** (the first point a release branch exists → the mover-classifier + F1–F6 sweep are runnable) and is re-confirmed at **Stage 9 G-PR9** / **Stage 12 Phase A.5**. The convention does not claim Stage-3 reliability for the zero-edge class.

**Scope.** This axis covers **corpus mover-sets** (markdown-reference forms rooted at `core/` / `release/` / `operations/` — every observed cross-release structural collision to date is a corpus reorg). A future release whose mover-set is **code** uses the domain-aware impact-analysis branch the Stage 5 Phase A3.1 domain-selector already defines (a code-import-graph analog), not this corpus sweep.

**Cutover (introducing-release-exempt).** The structural-blast-radius axis **and the version-slot token (Step 2a)** apply to milestones entering Stage 3 / Stage 4 strictly AFTER the respective introducing-release merge SHA recorded in the release log (the structural axis after the cross-release-impact-model introducing release; the version token after the `version-claim-determinism` introducing release). The introducing release itself is exempt (reflexive-pipeline-loop discipline — the release that adds an axis cannot fire it on its own bundling). All milestones that entered the relevant stage prior to the respective introducing release are also exempt.

**Auto-populator candidate:** the `release-planner` skill's Mode B already maps cross-milestone deps + emits G3-07 status + file contention; drafting the Parallelization Map is a natural extension of that surface. The skill SHOULD draft the map at Mode B emit time so operator review at Phase B1 covers the map alongside Outcome Statement + Release Class. The auto-populator convention note lives in the `release-planner` skill definition.

**Standing applicability.** The Parallelization Map convention does not retroactively bind milestones that predate its adoption — milestones already open carry no map by construction, and back-filling every open milestone across the active tracks would be a disproportionate scope expansion, so the convention binds milestones going forward. Future milestones reaching Stage 3 Bundle carry the standing Parallelization Map per this convention. The Stage 3 A7 refresh-trigger and the Stage 4 Phase A0 currency-check (defined in the Stage 3 Bundle Mutability Protocol in the release-process governance and in the Stage 4 Planning spec's Phase A0 entry, respectively) reconfirm it at the boundaries where it can go stale.

**A9.7 — Cascading-Rebundle Protocol:** When a re-milestone operation moves the namesake deliverable out of a donor milestone — i.e., an issue carrying the milestone's namesake-defining work is reassigned to another milestone via `gh issue edit --milestone` — the donor milestone enters re-evaluation per A7 refresh-classification (amend vs re-bundle vs defer per the standard Bundle Mutability Protocol). The cascading-rebundle protocol codifies this surface so future re-milestone events automatically trigger donor-milestone re-evaluation rather than leaving stale namesakes-without-deliverables on the books. Composes with A9.6 (Parallelization Map convention) and A7 (Bundle Mutability Protocol) — same milestone-description persistence surface, same `gh api repos/.../milestones/<N> --jq .description` read-surface, same Phase B authoring + Phase B1 operator-review touchpoints.

**Trigger.** A re-milestone operation moves the namesake deliverable out of the donor milestone. "Namesake deliverable" means an issue whose scope defines the milestone's identity as expressed in its title slug or Outcome Statement — typically the issue around which the milestone was bundled at Stage 3 Phase A1-A5. Operator judgment determines namesake status; the trigger fires when the operator (or hub at re-milestone time) recognizes the moved issue carried the donor's conceptual foundation.

**Detection.** Operator MAY detect manually OR via tooling. Manual: at the moment of `gh issue edit <N> --milestone <new>`, operator observes the donor milestone now lacks its namesake deliverable. Tooling: `gh api repos/[OPERATOR_GITHUB]/pmo-platform/issues/<re-milestoned-issue> --jq .milestone.title` confirms the new milestone; the donor milestone's coherence is then re-evaluated against the Stage 3 Phase A1-A5 bundle composition criteria (Outcome Statement still satisfiable? Remaining issues form a releasable unit? Internal sequence still coherent without the moved issue?).

**Response.** Donor milestone enters re-evaluation per A7 refresh-classification — the operator (Tier 3 decision per A7 § Refresh outcome paths) selects from:
1. **amend** — donor milestone keeps remaining issues + amended Outcome Statement / theme to reflect post-removal reality; per the Churn-budget threshold (≤ 30% composition delta AND theme preserved), this is the path when remaining issues coherently form a releasable unit under a refreshed theme.
2. **re-bundle** — donor milestone re-themed or re-scoped via Stage 3 Phase A1-A5 re-execution; per Churn-budget threshold (> 30% delta OR theme broken), this is the path when removing the namesake materially changes the donor's identity.
3. **defer** — donor milestone's remaining issues moved to next-eligible milestone via `gh issue edit --remove-milestone` per individual issue; donor milestone closed-as-superseded. This is the path when the donor is no longer viable in current sequence.

The classification follows the same Churn-budget threshold + Refresh outcome paths defined in the A7 Bundle Mutability Protocol in the release-process governance — the cascading-rebundle protocol is the trigger surface (T6); A7 is the disposition surface.

**Composition with existing A7 triggers.** T6 (namesake-deliverable removed) fires INDEPENDENTLY of T1 (Approved-queue depth), T2 (priority shift), T3 (dep-state change), T4 (Stage 4 boundary currency check), and T5 (Parallelization-Map staleness). T6 doesn't replace any prior trigger; doesn't conflict with any. A single re-milestone event MAY fire T6 alone OR may compound with T2 (the moved issue's removal alters priority-balance among remaining issues), T3 (issues whose hard-deps on the moved issue now sit cross-milestone — G3-07 cross-milestone-sequence check re-fires retroactively), and T5 (the donor's Parallelization Map's edge table may now misrepresent the donor's blocking-dep state).

**Recording.** When T6 fires, the operator records the disposition outcome in two surfaces — (1) `[BUNDLE *]` comment on the donor milestone naming the cascade-protocol-amend trigger, the moved issue, and the chosen disposition (amend/re-bundle/defer); (2) deviation-log entry in the relevant release plan if the donor milestone is mid-pipeline at Stage 4+ sub-window B/C per A7. Pre-Stage-4 dispositions (sub-window A) record the disposition only on the milestone — no release plan exists yet.

**Standing applicability.** The protocol governs future re-milestone events on current and forthcoming milestones. Re-milestone events that predate its adoption (e.g., historical events whose donor milestones do not even exist in this repo) do NOT retroactively trigger donor-milestone re-evaluation.

**Phase B (Human, Tier 3):** B1 review recommendation + gate results, B2 accept/modify/split/defer (including gate overrides), B3 create Milestone + assign issues (milestone description populates the doctrine-required fields per [`bundle-composition-doctrine.md § 7`](../standards/bundle-composition-doctrine.md): Outcome / Class / Scope / Internal sequence / Dep Exceptions [conditional] / A6 [conditional] / Amendment Log [conditional]), B4 cadence: after batch triage or threshold-triggered (5+ Approved).

**Bundle composition doctrine reference (per bundle-composition-doctrine.md):** Phase A1-A5 bundle recommendation + Phase B3 milestone-description authoring apply the 7-step vertical capability slice methodology per [`bundle-composition-doctrine.md § 3`](../standards/bundle-composition-doctrine.md). Spoke names the composition shape (per [`bundle-composition-doctrine.md § 8`](../standards/bundle-composition-doctrine.md) — capability-slice / hotfix / audit-driven / cleanup-debt / new-track-inaugural / subsumption-fission) in the Phase A5 bundle recommendation. Tight-merge mechanics for oversized parents (>15 tickets) per [`bundle-composition-doctrine.md § 4`](../standards/bundle-composition-doctrine.md). Naming convention (`v<MAJOR>.<NN-padded>-<capability-slug>`) per [`bundle-composition-doctrine.md § 5`](../standards/bundle-composition-doctrine.md). Size-target heuristics (15-25 pts target band; `[CALIBRATE-AFTER-3]`) per [`bundle-composition-doctrine.md § 3 Step 5`](../standards/bundle-composition-doctrine.md). The doctrine's bundle-composition frame defaults to F1 SAFe Feature-Slicing + Vertical Slice methodology (per platform config); frame is swappable via the unified config mechanism per the doctrine-config mechanism without rewriting doctrine prose. **Cutover discipline:** Applies to all releases going forward.

**Release Readiness Gate Check (A1):**
Automated validation of each candidate issue against [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-3-release-readiness) Gate 3 criteria. Routing per [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md) Path A — `structural` checks auto-execute (Tier 1), `judgment` checks produce agent assessment for operator review (Tier 2).

For each issue in the candidate bundle, evaluate:

| ID | Criterion | Check | Procedure |
|---|---|---|---|
| G3-01 | Dependencies in compatible states | structural → auto | Query `#N` refs via `gh issue view`. Compatible: Approved/Bundled/Done. Block on Rejected; warn on Deferred. |
| G3-02 | No circular dependency chains | structural → auto | Build dependency graph from candidate set. Detect cycles via topological sort. Block on any cycle. |
| G3-03 | Affected files identified | structural → auto | Verify Affected Files field contains specific file paths (not directory-only). Warn if empty or directory-level. |
| G3-04 | Scope is implementation-ready | judgment → recommend | Agent assesses Proposed Change + Affected Files specificity for Planning. Flag vague scope. |
| G3-05 | AC are measurable | judgment → recommend | Agent assesses whether AC can be verified at Stage 7/8. Flag untestable AC. |
| G3-06 | No blocking incompatible issues | structural → auto | Cross-check bundle set for blocked dependencies in incompatible states outside the bundle. Block if found. |
| G3-07 | Cross-milestone dependency sequence | structural → auto | For every dependency edge `#A → #B` declared on an in-bundle issue, assert milestone-position(A's milestone) ≥ milestone-position(B's milestone) per the Milestone-Position Resolution algorithm in [gate-criteria-spec.md § Gate 3](../../../core/schemas/gate-criteria-spec.md#gate-3-release-readiness). Edges registered in the candidate milestone's `## Dependency Exceptions` block PASS as governed exceptions. Per the dependency-exceptions spec. |
| G3-08 | In-bundle similarity routing | judgment → recommend | Apply Similarity Composite-Signal Detection per [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-3-release-readiness). Surface candidate pairs to operator; record routing in bundle rationale. Cross-bundle pairs advisory. Applies as a standing gate. |
| G3-09 | Size-driven decomposition routing | judgment → recommend | For every `size:XL` issue: routing decision required in bundle rationale (decompose-into-slice / split-into-sub-issues / approve-as-is-with-risk-note / defer-for-pre-bundle-analysis). `size:L` cross-stage informational only. Missing `size:*` label fails G3-09. Applies as a standing gate. |
| G3-10 | Release Class field present + valid in milestone description | structural → auto | After Phase B3, assert milestone description contains `## Release Class` H2 with `Class:` field matching closed enum `{routine, novel, cross-cutting, hotfix}` AND a non-empty `Rationale` sub-field. See [release-class-taxonomy.md](../specs/release-class-taxonomy.md) Classification Procedure for the milestone-description template. Applies as a standing gate to all releases entering Stage 3 going forward. |
| G3-11 | Release Outcome Statement heading present in milestone description (per the outcome-statement spec) | structural → auto-advisory | After Phase B3, grep `^### Release Outcome Statement$` against milestone description. Non-blocking advisory — failure logs to `core/hooks/deploy-check-warn-log.jsonl` and bundle proceeds. See [release-outcome-statement-template.md](../specs/release-outcome-statement-template.md) for the canonical empty-shape template (REQUIRED AFTER + BEFORE; OPTIONAL Actor(s) + Success Indicator). Applies as a standing advisory to all milestones created going forward. |
| G3-12 | Decomposition-review routing recorded at Bundle when ANY oversize predicate matches (per the composite-OR oversize predicate) | judgment → recommend | For every in-bundle issue: apply COMPOSITE-OR oversize predicate per [gate-criteria-spec.md § Composite-OR Oversize Predicate](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness) — **P1** `size:XL` label OR **P2** body cites declared decomposition hooks OR **P3** AC count ≥ 7 OR Affected Files count ≥ 5. On predicate fire: routing decision recorded in bundle rationale comment per 3-outcome enum (kept-as-one with rationale / split per [fission-convention.md](../protocols/fission-convention.md) / escalate per Tier 2 [SCOPE CHANGE] — re-bundle with fission-children replacing parent). G3-12 is the drift-backstop for G2-11 — catches issues whose body grew post-Triage. Issues that already routed at G2-11 pass G3-12 trivially unless body has materially changed. G3-12 SUBSUMES G3-09 when its predicate fires (the 3-outcome enum replaces G3-09's 4-option enum). Applies as a standing gate to all bundles entering Stage 3 going forward. |
| G3-13 | Roadmap-cascade validation - RETIRED (ADR-012) | - | De-scoped: roadmap instances operator-local; in-repo cascade detection no longer applies. Retained as a numbered tombstone so cross-references resolve. |

**Outcome Statement at Phase B3 (per the outcome-statement template):** The Milestone description authored at Phase B3 MUST include a `### Release Outcome Statement` H3 block per [release-outcome-statement-template.md](../specs/release-outcome-statement-template.md). The block carries REQUIRED `**AFTER**` (post-merge state, 1–3 sentences) and `**BEFORE**` (current state, 1–3 sentences); OPTIONAL `**Actor(s):**` and `**Success Indicator:**` sub-fields. The block is queryable via `gh api repos/.../milestones/<N> --jq .description`. Stage 3 spoke draft selects shape from Release Class (per [release-class-taxonomy.md](../specs/release-class-taxonomy.md) — routine / novel / cross-cutting / hotfix have differentiated AFTER/BEFORE length + Success Indicator requirements per the template § 4). Operator approves Outcome alongside scope at Phase B1 Decision Briefing. The Outcome is downstream-consumed at Stage 9 G-PR7 (goal-conformance check) and Stage 13 QC4-06 + G-CL7 (goal-attainment verification). **Cutover discipline:** The Outcome Statement is required for all milestones created going forward.

**Gate result:** PASS (all structural checks pass, judgment checks assessed) or FAIL (≥1 blocking criterion unresolved). Per-issue results surface in A5 bundle recommendation.
**Operator override:** On FAIL, operator may override with documented rationale in the bundle rationale comment (Phase B2). Overridden criteria carry forward as risk items to Planning (Stage 4). Issues failing the gate without override are excluded from A5 bundle recommendation.

**Ticket lifecycle:** Claim: validate Status=Approved, set Stage→3-Bundle. Execute: dependency/capacity analysis (A1-A5 + B1-B4). Resolve: post bundle rationale, set `status: bundled` label + Status→Bundled, assign Milestone. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md) Ticket Lifecycle Protocol.

**Framework dimensions touched:** Work Breakdown (Milestone scope); Handoff (Bundled status). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Milestone (GitHub) with description populated per [`bundle-composition-doctrine.md § 7`](../standards/bundle-composition-doctrine.md) required-fields schema (Outcome / Class / Scope / Internal sequence / Dep Exceptions [conditional] / A6 [conditional] / Amendment Log [conditional] / Bundle Composition Frame [optional]), issue-to-Milestone assignment, bundle sequence with composition shape declared per [`bundle-composition-doctrine.md § 8`](../standards/bundle-composition-doctrine.md), release version per [`bundle-composition-doctrine.md § 5`](../standards/bundle-composition-doctrine.md) naming convention. No separate release plan — that is Stage 4.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
**Release Readiness** — per [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-3-release-readiness). Automated gate check at A1 (G3-01 through G3-09; structural checks auto-execute, judgment checks agent-assessed). Gate passed or operator override with documented rationale, dep chains satisfiable, coverage assessed per issue, capacity checked, contention reviewed, no cross-milestone sequence violations without registered exceptions, in-bundle similarity pairs routed (G3-08), size:XL decomposition routing recorded (G3-09), Release Class declared in milestone description (G3-10), Release Outcome Statement heading present in milestone description (G3-11), oversize-predicate decomposition routing recorded at Bundle when ANY composite-OR predicate fires (G3-12), roadmap-cascade validation (G3-13; RETIRED per ADR-012 — roadmap instances operator-local, criterion no longer fires), version assigned (no collision), Milestone created + issues assigned.

## 8. Automation Level
Overall Tier 2. Today: fully manual. Target: release-planner skill reads GitHub Issues directly via the `improvement.yml` data model.

## 9. Gap Summary
8 gaps identified. Key: no bundling skill mode (P2), no Milestones exist yet (P3, resolved).

## 10. Retro
Key lessons: Bundle is simpler than Triage but bad bundles cascade through all downstream stages. Coverage analysis was breakthrough finding from Stage 2. 60/20/20 allocation aspirational — early releases will be 80%+ debt/protocol. Sprint batch cadence validated: batch triage → batch bundle → batch execute.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `gate-outcome` | `g3-release-readiness` | Milestone created via Phase B3 (Gate 3 G3-01..G3-07 outcome); ALSO captured in `calibration-data.md` — payload carries `projects_to: calibration-data.md:<row-anchor>` | `spoke:#N` |
| `decision` | `a6-new-track-rationale` | A6 condition fires (new version-prefix Milestone has no prior on-repo Milestones) and rationale baked into description | `spoke:#N` (Phase A6 analyst) |
| `decision` | `a7-bundle-amend` / `a7-bundle-rebundle` / `a7-bundle-defer` | A7 bundle-refresh outcome rendered post-bundle-creation per § Inter-Stage Feedback Protocol | `operator` |
| `decision` | `outcome-statement-authored` | Outcome Statement drafted at Phase B3 alongside Milestone-description authoring per [release-outcome-statement-template.md](../specs/release-outcome-statement-template.md); payload carries `class` (routine/novel/cross-cutting/hotfix) + `success_indicator_present` (bool) | `spoke:#N` (release-planner Mode A) |

Cutover discipline: audit events are emitted for all releases entering this stage going forward.
