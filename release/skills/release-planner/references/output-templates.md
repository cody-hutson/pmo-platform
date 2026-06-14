<!-- reference-durability: allow-link -->

# Release Planner — Output Templates

Output-format examples for `release-planner` modes. Each block is the literal
shape the corresponding mode emits; the SKILL.md mode body carries a one-line
pointer here so the instructional text stays under the canonical-skill-structure
line guardrail. Moving these examples here is presentational only — the emit
rules that govern each section live in the mode bodies and the failure-mode
entries in `SKILL.md`.

## Mode A — Backlog Analysis output

Emitted by Mode A Step 5. Present a prioritized view with rationale in this
format:

```
## Backlog Analysis — [date]

### Dependency Graph
[Topo-sort sequence with priority annotations; optional Mermaid block when > 5 nodes]

### Suggested Bundles
**Bundle 1 (recommended next):** #X, #Y, #Z
- Theme: [description]
- Rationale: [why these together, why now]
- Estimated scope: [file count, change type]
- Version suggestion: [major/minor/patch with rationale]
- G3-07 Status: PASS | PASS-WITH-EXCEPTIONS (N registered) | FAIL (N unresolved)

### File Contention Map
| File | Issues | Intent Mix | Severity | Recommendation |
|---|---|---|---|---|
| <path> | #N, #M, ... | edit×K, add×J, delete×L | NONE \| BINARY \| MULTI-WAY \| CONFLICT | <operator hint per severity> |

**Parse-quality:** <N> issues parsed cleanly · <M> deferred (excluded) · <K> parse-failed (BLOCKING) — denominator = conformant-bundleable only (per Step 1.5)
**Pre-filter (Step 1.5):** <T> type-excluded (sub-task/observation/adr/[Initiative]/umbrella) · <R> needs-body-repair (improvement|bug, no Affected Files heading — surfaced to operator, excluded from denominator)

**Bundle 2:** ...
```

## Mode D — Pattern Review Decision Briefing output

Emitted by Mode D Step 6. The Decision Briefing presents the LITERAL Proposal
bodies inline — the operator approves the verbatim body, not just the verdict
abstraction:

```
## Pattern Review — YYYY-MM-DD (release-planner Mode D — DRAFT only)

### Open Observations Scanned
N total · grouped by (domain, Pass-2 broadened theme) tuple
Pass-1 narrow tags surfaced for operator reference

### Uncategorized Observations Requiring Operator Theme Assignment (if any)
- #<obs_n> — title — <reason Pass-2 produced unknown-mechanism>
  [HALT: awaits operator theme assignment before clustering]

### Candidate Clusters (count ≥ 2 within 180 days)
**Cluster 1:** (release-ops, drift-detection) — N=3 observations
- #<obs1> — <one-line title> — Pass-1 narrow: `dim-drift`
- #<obs2> — <one-line title> — Pass-1 narrow: `drift-check-enumeration`
- #<obs3> — <one-line title> — Pass-1 narrow: `pre-merge-spec-vs-reality`

**Proposed Proposal (verbatim — operator approves this body literally):**

    ### Priority
    P3 - Medium

    ### Category
    protocol

    ### Description
    [2-3 sentence emergent-theme summary.]

    > #<obs1> (filed YYYY-MM-DD by operator):
    > [verbatim quoted body of observation #<obs1>]

    > #<obs2> (filed YYYY-MM-DD by operator):
    > [verbatim quoted body of observation #<obs2>]

    > #<obs3> (filed YYYY-MM-DD by operator):
    > [verbatim quoted body of observation #<obs3>]

    ### Evidence
    [SOURCE: #<obs1>] — <one-line summary>
    [SOURCE: #<obs2>] — <one-line summary>
    [SOURCE: #<obs3>] — <one-line summary>

    ### Affected Files
    <union of source observation affected-files; dedup>

    ### Acceptance Criteria
    [Draft 2-4 AC per § 9-field map; operator refines at Triage]

    ### Origin
    Promoted from Observation tier via Pattern Review on YYYY-MM-DD per OPERATIONS.md § Pattern Review Cadence Protocol. Source observations: #<obs1>, #<obs2>, #<obs3>.

    ### Dependencies
    None

**Verdict requested:** PROMOTE / DEFER / CLOSE

**Cluster 2:** ...

### Singleton Observations (count = 1)
N observations not yet eligible; listed for operator awareness

### Reversibility-tier (per decision-discipline.md):
- PROMOTE verdict on Cluster N: MODERATE · confidence: <HIGH/MED/LOW>
- DEFER verdict: CHEAP
- CLOSE verdict: MODERATE (close-as-not-planned reversible by re-open)

### Adoption Counter (per § decision-discipline.md G5)
- Last Pattern Review: YYYY-MM-DD
- Clusters surfaced this cycle: N
- Draft Proposals presented: N
```

## Mode D — Operator-Explicit Handoff to release-executor Mode G

Emitted by Mode D Step 7 on any PROMOTE verdict — the handoff option presented
to the operator:

```
## Operator-Explicit Handoff to release-executor Mode G

PROMOTE verdicts on N clusters require write-execution. Invoke release-executor Mode G — Pattern Review Execute with the following manifest:

- Cluster 1: PROMOTE — approved body file `<path to literal body draft persisted by Mode D Step 5>`
- Cluster 2: ...

The release-executor Mode G invocation is operator-explicit (NOT a chained=true cascade — release-executor is not on the 4-skill cascade allowlist per its SKILL.md Dormant-branch note; operator invokes Mode G directly with the approved manifest).
```
