# Subsumption Convention

Defines how to close an issue that is fully covered by a larger, broader issue. Subsumption is not the same as duplication — a subsumed issue is a subset of the surviving issue's scope, not an exact copy. For the inverse 1→N protocol (splitting a too-broad parent into N implementable children), see [fission-convention.md](fission-convention.md).

## When to Subsume

Use subsumption when:
- Issue A's scope is entirely contained within Issue B's scope
- Issue B will deliver everything Issue A requested (and more)
- Keeping both open would create redundant tracking

Do **not** subsume when:
- Issues overlap partially — use dependency links instead
- The subsumed issue has unique acceptance criteria not covered by the survivor — merge the AC first, then subsume

## Subsumption Procedure

### Step 1: Update the Surviving Issue

Add a note to the surviving issue's body (in the Notes or Dependencies section):

```
**Subsumes:** #N — [one-line description of what the subsumed issue covered]
```

If multiple issues are subsumed, list each on its own line.

### Step 2: Comment on the Subsumed Issue

Post a closing comment on the subsumed issue using this format:

```
## Subsumption

**Subsumed by:** #N — [one-line explanation of why this issue is covered by #N]

**Scope transfer:** [Confirm that all acceptance criteria from this issue are captured in #N, or note any AC that was merged into #N as part of this subsumption]
```

### Step 3: Close the Subsumed Issue

- **Close reason:** "not planned" (GitHub's closest semantic match — the work will happen, but under a different issue)
- **Label:** Add `duplicate` label for traceability

### Step 4: Cross-Reference

Verify that:
- The surviving issue's body references the subsumed issue
- The subsumed issue's closing comment references the surviving issue
- Both directions are navigable

## Integration with Triage (Stage 2)

During triage Phase A, Step A2 (duplicate/overlap detection):
1. Check for exact duplicates → close as duplicate with "Duplicate of #N"
2. Check for subsumption candidates → apply this convention
3. Check for partial overlap → add dependency link, do not subsume

## Examples

**Closing comment on subsumed issue:**
```
## Subsumption

**Subsumed by:** [LARGER-SCOPE-ISSUE] — The ticket information architecture ([LARGER-SCOPE-ISSUE]) defines the
three-layer model that fully covers this issue's request for standardized
comment formats.

**Scope transfer:** AC items 1-3 from this issue are captured in [LARGER-SCOPE-ISSUE] AC items
2 and 3. No unique scope remains.
```

**Surviving issue body update:**
```
**Subsumes:** [SUBSUMED-ISSUE] — standardized comment format (covered by AC item 2)
```

## Decision Table

| Scenario | Action | Convention |
|---|---|---|
| Exact duplicate | Close as duplicate | "Duplicate of #N" (GitHub native) |
| Full subset (A ⊂ B) | Subsume A into B | This convention |
| Partial overlap | Link, do not close | Dependency link: "Related to #N" |
| Superseded by redesign | Subsume with note | This convention + note that original approach was replaced |
