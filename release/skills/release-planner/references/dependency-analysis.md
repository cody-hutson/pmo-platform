# Dependency Analysis Methodology

## Purpose

This document defines the methodology for analyzing dependencies during release planning. The release-planner skill (Mode A) applies this methodology during Stage 3 (Bundle) to construct dependency graphs, detect conflicts, and produce dependency-ordered implementation sequences.

## Two Dependency Layers

Per the ITIL Dual-Practice Model, dependencies exist in two distinct layers that must be analyzed separately and then cross-linked:

| Layer | ITIL Practice | What It Tracks | Maintained During |
|-------|--------------|---------------|-------------------|
| **Logical** | Change Enablement | Issue-to-issue dependencies: "Issue A must be resolved before Issue B makes sense" | Triage and Bundle stages |
| **Technical** | Service Configuration Management | File-to-file dependencies: "File X references File Y; changing Y requires updating X" | Solutioning and Engineering stages |

Both layers feed into the implementation sequence. An issue may be logically independent but technically dependent (shares a file with another issue) or vice versa.

## File Contention Analysis

File contention occurs when multiple issues in a release modify the same file. Contention requires sequencing — parallel modification of the same file creates merge conflicts and review complexity.

### Contention Detection

For each file in the release's File Change Matrix, count the number of issues that modify it:

| File Path | Issues Modifying | Contention Level | Sequencing Required |
|-----------|-----------------|-----------------|-------------------|
| [path] | #N only | None | No — can be implemented in any order |
| [path] | #N, #M | Binary | Yes — one must land first |
| [path] | #N, #M, #P | Multi-way | Yes — full ordering required for this file |

### Contention Resolution

| Contention Level | Resolution Strategy |
|-----------------|-------------------|
| **None** | Issues are independent for this file; no constraint |
| **Binary** | Order by: (1) logical dependency, (2) smaller change first, (3) lower risk first |
| **Multi-way** | Order by: (1) logical dependency graph, (2) foundation-first (changes that others build on), (3) smallest delta first |

### Contention Matrix

For releases with 5+ issues, construct a contention matrix:

```
          Issue #N  Issue #M  Issue #P  Issue #Q
File A      X         X                           ← Binary contention
File B      X                   X                 ← Binary contention
File C                X         X         X       ← Multi-way contention
File D                                    X       ← No contention
```

Files with multi-way contention are the highest-risk files in the release and should receive the most review attention.

## Dependency Graph Construction

### Step 1: Collect Dependencies

For each issue in the release, identify:
- **Logical dependencies:** "This issue doesn't make sense until issue #X is done"
- **Technical dependencies:** "This issue modifies a file that issue #X also modifies"
- **Content dependencies:** "This issue references content that issue #X creates"

### Hard-vs-Soft Edge Classifier

When collecting dependencies from issue bodies (Step 1) AND when drafting the standing Parallelization Map convention defined in the Stage 3 Bundle spec, apply this classifier. The classifier MUST be reproducible (a regex-grep over issue-body text), not a judgment call — any operator or spoke re-running the scan reaches the same classification:

| Class | Trigger language in issue body | Action in dep graph |
|---|---|---|
| **Hard** | "blocks", "blocked by", "depends on", "requires", "after #N" | Enters bidirectional dep graph as a directed edge; participates in Kahn's BFS topological sort + DP-DAG CPM computation |
| **Soft** | "composes with", "coordinates with", "adjacent to", "relates to", "sibling of" | Does NOT enter dep graph; informational only — surfaced in Parallelization Map as a soft-coupled edge with body confirmation cite |
| **File-contention** | "same file as #N", "edits same section as #N" | Does NOT enter dep graph; enters File Contention Map only (per § File Contention Analysis above) |

**Reproducibility:** the classifier is a regex-grep over issue bodies, not a judgment call. A reproducible reconfirm scan uses:

```
gh issue list --milestone "<this milestone>" --state open --json number,body --jq '
  .[] | select(.body | test("(?i)blocked by|depends on|requires|after #[0-9]+|blocks #[0-9]+"))
'
```

with parallel scans for soft-edge and file-contention triggers. The Parallelization Map's "Reconfirm procedure" sub-section embeds a domain-narrowed form of this scan; both the Stage 3 A7 refresh trigger (Parallelization-Map staleness, T5) and the Stage 4 Phase A0 entry re-run the scan to detect map staleness.

**Composition with the typed-dep substrate:** when the typed-dep substrate is populated, edges carry an `edge_type` (FS / SS / FF / SF) per Step 5b. The hard-vs-soft classifier is the pre-substrate fallback — it operates on issue-body text directly, NOT on typed-edge metadata. Once the typed-dep substrate populates, the classifier becomes a redundant secondary signal (the typed edge IS the hard classification); without the substrate, it is the only deterministic source of edge classification.

**Standing applicability.** The classifier governs bundle dep-collection AND Parallelization Map drafting on milestones going forward; it does not retroactively bind milestones that predate its adoption, which carry no Parallelization Map by construction. For dep-graph construction unrelated to the Parallelization Map (e.g., Kahn's BFS over the typed-dep substrate), the classifier is informational where a typed edge already exists and is the required edge-classification source where it does not.

### Step 2: Build Directed Acyclic Graph (DAG)

```
#N ──→ #M ──→ #P
       ↑
#Q ────┘
```

Edges represent "must come before" relationships. The graph must be acyclic (no circular dependencies).

### Step 3: Circular Dependency Detection

If the dependency graph contains a cycle (e.g., #A depends on #B, #B depends on #C, #C depends on #A), the release cannot proceed as scoped.

**Cycle resolution strategies:**

| Strategy | When to Use | Action |
|----------|------------|--------|
| **Decompose** | One issue can be split into independent sub-issues | Split the cyclic issue; resolve dependency on the independent sub-issue |
| **Merge** | Two cyclic issues are so entangled they should be one issue | Combine into a single issue; no internal dependency |
| **Defer** | One issue in the cycle is lower priority | Remove from this release; break the cycle |
| **Re-sequence** | The dependency is assumed, not real | Re-examine the dependency; if it's not a true blocker, remove the edge |

### Step 4: Topological Sort

Apply topological sort to the DAG to produce a valid implementation sequence. When multiple valid orderings exist, prefer:
1. Issues with highest leverage (unblock the most downstream work) first
2. Lower-risk issues first (validate approach before high-risk changes)
3. Smaller issues first (faster feedback)

## Dependency Graph Construction Algorithm: Kahn's Implementation

Per ADR-1 + the typed-dep Model A, the release-planner skill (Mode A) uses Kahn's BFS topological sort with a deterministic priority-desc → issue-asc tie-breaker. The algorithm operates on the data-source surface defined by `read_dependencies(issue_number) → List[TypedEdge]` per the typed-dep substrate (body Dependencies field PRIMARY per `ticket-information-architecture.md § Conflict Resolution`; native `blocks`/`blocked-by` mirrors the FS+0d subset per Model A adoption). Edge identity is `.target` field; typed metadata in `.edge_type` per § Step 5b.

### Graph Storage

- **Adjacency:** `Map<issue_number, Set[issue_number]>` — `adj[u] = deps(u)`. Edge `(u, v)` means "u depends on v."
- **Indegree:** `Map<issue_number, int>` — per-node counter used by Kahn's.

### Topological Sort (Kahn's BFS)

```
FUNCTION topological_sort(nodes, edges) -> List[int]:
  indegree = {n: 0 for n in nodes}
  for (u, v) in edges:
    indegree[u] += 1   # u depends on v → outgoing edge from u

  # Initial queue: all nodes with no dependencies
  ready = [n for n in nodes if indegree[n] == 0]
  ready.sort(key=tie_breaker_key)   # deterministic ordering

  ordered = []
  while ready:
    n = ready.pop(0)
    ordered.append(n)
    for dependent in nodes_depending_on(n):
      indegree[dependent] -= 1
      if indegree[dependent] == 0:
        ready.append(dependent)
    ready.sort(key=tie_breaker_key)   # re-sort after each batch admission

  if len(ordered) < len(nodes):
    cycle_nodes = [n for n in nodes if indegree[n] > 0]
    raise CycleDetected(cycle_nodes)

  return ordered
```

### Tie-Breaker Rule

When multiple nodes have indegree 0 simultaneously, sort by:

1. **Priority descending** — P1 before P2 before P3 before P4 before unlabeled
2. **Issue number ascending** — lower numbers first (older = generally more foundational)

Both keys are pure functions of issue data; produces deterministic, reproducible ordering. Per AC4 (reproducibility), the same input produces the same output across runs.

**Rejected alternatives** (rationale in the Stage 5 ADR contribution):
- Leverage score (transitive dependent count) — circularity: requires graph built first; non-trivial to display.
- Lower-risk first — risk is judgment-bearing; not deterministic; defeats AC4.
- Smaller delta first — requires Stage 5+ inputs not available at Stage 3 Bundle.
- Issue number alone — loses business-priority signal.
- Lexical (title or label string) — loses business-priority signal AND opaque to operators.

### Cycle Detection + Path Extraction

Kahn's surfaces cycles naturally: when the queue empties and `len(ordered) < len(nodes)`, residual nodes (those with indegree > 0) form ≥1 cycle.

```
FUNCTION extract_cycle_path(residual_nodes, edges) -> List[int]:
  # Run DFS on residual subgraph, tracking the recursion stack.
  # When DFS revisits a node already in the recursion stack, the
  # path from that node forward in the stack is the cycle.

  for start in residual_nodes:
    stack = []
    visited = set()
    def dfs(n):
      if n in stack:
        return stack[stack.index(n):] + [n]   # cycle path
      if n in visited:
        return None
      visited.add(n)
      stack.append(n)
      for dep in edges.get(n, []):
        if dep in residual_nodes:
          result = dfs(dep)
          if result:
            return result
      stack.pop()
      return None
    cycle = dfs(start)
    if cycle:
      return cycle
  return residual_nodes   # fallback: nodes are in cycles, exact path not found
```

**Operator signal on detection:**
- Severity: ERROR
- Behavior: HALT bundle recommendation
- Emit cycle path: `#A → #B → #C → #A`
- Reference cycle-resolution strategies from § Step 3 Circular Dependency Detection (decompose / merge / defer / re-sequence)

### Composition

- **Mode A consumption:** Mode A Step 3 invokes this algorithm; cycle-detect HALT matches the existing failure-mode entry "Circular dependency silently bundled — PROC" in SKILL.md.
- **G3-02 gate (gate-criteria-spec.md):** Mode A's cycle detection IS the structural mechanism G3-02 expects.
- **G3-07 gate.** Consumes the topologically-sorted graph (with cross-milestone edges filtered out at step 2 of construction) as input for cross-milestone validation. Cross-milestone edge set is computed separately by the G3-07 logic — this algorithm does not produce it.
- **File contention composition:** The same `bundle-issues-parser.py` tool that powers `read_dependencies()` also produces the contention map per the canonical output format. See § File Contention Analysis below — the contention map is emitted as a `### File Contention Map` H3 section in Mode A/B output per the spec in `release/skills/release-planner/SKILL.md` Mode A Step 5 / Mode B Step 6.
- **CPM longest-path composition.** § Step 5 below runs a single forward-pass DP-DAG relaxation over the Kahn's-emitted topo-sorted sequence to produce the schedule-determining chain. Composes natively — no parallel graph machinery, same tie-breaker, same edge set.

## Step 5: Longest-Path Computation (CPM)

The release bundle's dep-graph carries an implicit **schedule-determining chain** — the longest dependency-determined sequence of issues, analogous to the Critical Path in PMBOK 7 Schedule Management. This step computes that chain via DP-DAG (dynamic programming over the topologically-sorted DAG) and emits it as a first-class Stage 3 / Mode B output.

### Canonicalization 1 — Algorithm choice

**Chosen algorithm:** **DP-DAG (single forward-pass longest-path relaxation over Kahn's-emitted topo-sorted sequence).**

**Rejected alternatives:**
- **Floyd-Warshall** (O(V³) time, O(V²) space) — all-pairs longest distance. Rejected: requires parallel adjacency-matrix machinery; does NOT compose with Kahn's; for V=8 the V³ vs V+E gap is operationally irrelevant (512 vs 16 ops), but adding a second graph framework is governance debt with no fidelity gain on sparse release DAGs.
- **Longest-chain heuristic** (O(V) chain-walk over depth-sorted nodes) — fast but no longest-path guarantee. Rejected as the primary algorithm; **retained as a tertiary annotation source if implementations want a sanity check**, not a substitute.

**Composability rationale:** Kahn's BFS (§ above) emits a topologically-sorted node list with the priority-desc → issue-asc tie-breaker. DP-DAG runs immediately on that same sequence — no re-sort, no parallel adjacency, no separate cycle check (DP-DAG is undefined on cyclic graphs and Kahn's HALT already covers that case). Reversibility: CHEAP (single function; revert = delete it + its callers).

**Reference:** CLRS Chapter 24.2 (longest path in a DAG via topological sort); PMBOK 7 §3 Activity-Network methods (CPM lineage from Kelley & Walker, 1959).

### Step 5a — Edge weights and degraded-mode predicate

Edge weights depend on whether typed-dep metadata is available (per the typed-dep substrate):

| Mode | Edge weight rule | Activation predicate |
|---|---|---|
| **Degraded mode** (DEFAULT until typed-dep substrate populates) | All edges weight = 1 | ANY in-bundle edge lacks typed metadata |
| **Typed mode** (post typed-dep-substrate full population) | FS edge → 1 + lead_lag; SS edge → lead_lag (zero-base, parallel start permitted); FF/SF → see typed-dep spec | ALL in-bundle edges carry typed metadata |

### Canonicalization 2 — Degraded-mode activation predicate

**Chosen predicate:** **any-untyped-edge activates degraded mode for the entire bundle (binary all-or-nothing).**

```python
def degraded_mode_active(bundle: List[IssueRecord]) -> bool:
    """Returns True iff ANY in-bundle edge lacks typed metadata.

    Binary all-or-nothing — partial-typed bundles still degrade to the
    lower-fidelity computation to avoid mixed-signal output (a chain
    where some edges count as weight-1 unweighted and others as
    weighted FS+lead_lag would produce a length number with no
    consistent semantic meaning).
    """
    for issue in bundle:
        for edge in issue.dependency_edges:
            if not is_typed_edge(edge):
                return True
    return False

def is_typed_edge(edge) -> bool:
    """Field-presence check. Adapts to the typed-dep encoding.

    Default: edge has an 'edge_type' attribute that is non-NULL and
    non-empty. The contract — 'any edge missing typed metadata triggers
    degraded mode' — survives encoding choice (dataclass attr, dict key,
    GraphQL field). When the typed-dep encoding ships, this helper is the
    single point of adaptation.
    """
    return hasattr(edge, 'edge_type') and edge.edge_type
```

**Why all-or-nothing over per-edge mode:** mixed-signal output (a chain length number whose semantic interpretation varies edge-by-edge) is unreadable. The operator cannot interpret "chain length 4" if 2 edges are weight-1 unweighted and 2 are weighted FS+lead_lag. Single-mode-per-bundle output is interpretable; mode header makes the interpretation explicit.

**Default state:** degraded mode is ALWAYS ACTIVE because the native-mirror only carries `FS+0d` and the body Dependencies field's typed-substrate adoption is gradual. Degraded mode is the DEFAULT and remains so until every in-bundle edge carries typed metadata — no manual mode-flag, no operator-cutover ceremony.

### Step 5b — DP-DAG longest-path algorithm

```
FUNCTION longest_dependency_chain(topo_sorted_nodes, edges, edge_weights, bundle) -> {chain, length, mode_annotation}:
  """DP-DAG longest path over the Kahn's-emitted topo-sorted sequence.

  Composes natively with the existing Kahn's BFS in § Dependency Graph
  Construction Algorithm — operates on the SAME topologically-sorted
  output with the SAME priority-desc → issue-number-asc tie-breaker.

  Inputs:
    topo_sorted_nodes: List[int] — output of topological_sort() from § Step 4
    edges: Map<int, Set[int]> — adjacency list; edge (u,v) means u depends on v
    edge_weights: Map<(int, int), int> — per-edge weight per mode:
      degraded mode: all edges weight=1
      typed mode (post typed-dep-substrate): FS edge → 1 + lead_lag; SS edge → lead_lag (zero base)
    bundle: List[IssueRecord] — used for degraded_mode_active() predicate

  Outputs:
    chain: List[int] — issue-ordered chain from head to tail
    length: int — numeric length (sum of edge weights along chain)
    mode_annotation: str — '[DEGRADED-MODE: ...]' or '[TYPED-MODE: ...]' per active state
  """
  # Edge case: bundle with zero dep edges has no chain to compute.
  if not any(edges.values()):
    return {'chain': [], 'length': 0,
            'mode_annotation': _mode_annotation(bundle)}

  dist = {n: 0 for n in topo_sorted_nodes}     # longest distance to reach n
  pred = {n: None for n in topo_sorted_nodes}  # predecessor on longest path to n

  for n in topo_sorted_nodes:                  # process in topo order (Kahn's emit)
    # Sort predecessors by priority-desc → issue-asc tie-breaker so chain
    # IDENTITY (not just chain length) is deterministic across runs. Without
    # this sort, set iteration order varies with Python hash seed, producing
    # non-reproducible chain identities on ties. Per AC4 + Stage 7 DT
    # F1 [ADJUST].
    for parent in sorted(nodes_with_edge_to(n, edges),
                         key=lambda p: (-priority_of(p), p)):
      candidate = dist[parent] + edge_weights[(parent, n)]
      if candidate > dist[n]:
        dist[n] = candidate
        pred[n] = parent

  # Find sink with maximum distance (apply tie-breaker: priority-desc → issue-asc)
  sink = argmax_with_tiebreaker(dist, priority_desc_issue_asc)

  # Reconstruct chain backwards
  chain = []
  cur = sink
  while cur is not None:
    chain.insert(0, cur)
    cur = pred[cur]

  return {
    'chain': chain,
    'length': dist[sink],
    'mode_annotation': _mode_annotation(bundle)
  }

FUNCTION _mode_annotation(bundle) -> str:
  if degraded_mode_active(bundle):
    return '[DEGRADED-MODE: typed-dep substrate absent; chain length is unweighted edge count; lead/lag NOT modeled]'
  return '[TYPED-MODE: edges carry FS/SS + lead/lag; chain length reflects FS-edge count + lead/lag delays]'
```

**Complexity:** O(V+E) time — single forward-pass over Kahn's-emitted topo-sorted sequence, O(E) total edge relaxation. Memory: O(V) for `dist` + `pred` maps.

**Tie-breaker preservation:** DP-DAG never re-orders Kahn's output — it only relaxes distances along the existing edge set. The sink selection applies the SAME priority-desc → issue-asc tie-breaker as Kahn's, preserving the AC4 reproducibility guarantee.

### Step 5c — Output schema

```markdown
### Critical Path

[DEGRADED-MODE: typed-dep substrate absent; chain length is unweighted edge count; lead/lag NOT modeled]
<OR: [TYPED-MODE: edges carry FS/SS + lead/lag; chain length reflects FS-edge count + lead/lag delays]>

**Chain (longest dependency-determined sequence):** #<head> → #<n2> → ... → #<tail>
**Chain length:** <integer> edges (degraded mode) | <integer> edges + <integer> lead/lag days (typed mode)
**Algorithm:** DP-DAG (topologically-sorted longest path) per `references/dependency-analysis.md` § Step 5
```

When the bundle has zero dependency edges, emit:

```markdown
### Critical Path

[DEGRADED-MODE: typed-dep substrate absent; chain length is unweighted edge count; lead/lag NOT modeled]

**Chain:** (none — bundle has no dependency edges)
**Chain length:** 0 edges
**Algorithm:** DP-DAG (topologically-sorted longest path) per `references/dependency-analysis.md` § Step 5
```

### Composition with the typed-dep read-surface

Per the typed-dep Stage 5 / Stage 6 design, the read-surface is `read_dependencies(issue_number) → List[TypedEdge]` where `TypedEdge` carries `edge_type` (FS / SS / FF / SF), `target` (int), and optional `lead_lag` (int days). The `is_typed_edge()` helper above is the single point of adaptation if the typed-dep encoding diverges from the default attribute-presence check (e.g., empty string instead of NULL); the predicate's contract — "any edge missing typed metadata triggers degraded mode" — survives encoding choice.

**Cutover discipline:** This CPM step applies to all releases entering Stage 3 going forward.

## Leverage Analysis

Leverage measures how much downstream work an issue unblocks:

| Issue | Direct Dependents | Transitive Dependents | Leverage Score |
|-------|-------------------|----------------------|---------------|
| #N | 2 | 4 | High (unblocks 4 issues) |
| #M | 0 | 0 | None (independent) |
| #P | 1 | 1 | Low |

**Leverage-based sequencing rule:** Issues with highest leverage score should be implemented earliest, even if they are more complex. Blocking the highest-leverage issue blocks the most work.

## Blast Radius Analysis

Blast radius = the set of files and skills affected by a change, including transitive effects.

### Computing Blast Radius

For each issue:
1. **Direct impact:** Files the issue directly modifies
2. **First-order transitive:** Files that reference the directly modified files
3. **Second-order transitive:** Files that reference first-order transitive files
4. **Skill impact:** Skills whose SKILL.md references any affected file

| Issue | Direct Files | First-Order | Second-Order | Skills Affected | Total Blast Radius |
|-------|-------------|-------------|-------------|----------------|-------------------|
| #N | 2 | 3 | 1 | 2 | 8 |
| #M | 1 | 0 | 0 | 1 | 2 |

**Blast radius determines review scope:** Higher blast radius = more review attention, more verification steps, higher rollback complexity.

## Capacity Assessment

### Effort Estimation

For each issue in the release, estimate implementation effort:

| Issue | Estimated Effort | File Count | Contention | Blast Radius | Complexity |
|-------|-----------------|-----------|------------|-------------|-----------|
| #N | [hours or relative] | [count] | [level] | [count] | Low/Med/High |

### Release Capacity Check

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Total estimated effort | [sum] | Available capacity for release window | PASS/FAIL |
| Max single-issue effort | [max] | <50% of total capacity (avoid single-issue dominance) | PASS/FAIL |
| Multi-way contention files | [count] | <3 (manageable review complexity) | PASS/FAIL |
| Maximum blast radius | [max] | <20 (manageable verification scope) | PASS/FAIL |

If any capacity check FAILS, recommend: scope reduction, release splitting, or timeline extension.
