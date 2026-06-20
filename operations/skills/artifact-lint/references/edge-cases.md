# Artifact Lint — Edge-Case Register

The seven edge cases below are the boundary conditions the five checks must handle without producing a false finding or a wrong recommendation. Each names the situation, the correct handling, and which check it touches. These carry forward from the artifact-lineage-graph Stage-5 deferrals (the 7-item edge-case register).

| # | Edge case | Touches | Correct handling |
|---|---|---|---|
| 1 | **Embedded/sidecar disagreement** — a markdown artifact has both embedded frontmatter AND a `<file>.meta.yml` sidecar, and the lineage values disagree. | all (input) | Resolution order is embedded-first for markdown (per the sidecar resolution rule); the embedded frontmatter wins. Note the disagreement in the report's evidence so the operator can reconcile the stray sidecar. Do NOT silently merge the two. |
| 2 | **Excluded-path parent** — an in-scope artifact's `parent_artifact` points into `09-Prototype/` or `_templates/` (an excluded path). | orphan (Check 1) | The parent resolves (the file exists) even though the path is excluded from *finding-scanning* — so this is NOT a dangling/orphan. Resolve the pointer read-only against the excluded path; do not flag it as orphan, and do not generate findings *about* the excluded parent itself. |
| 3 | **Supersedes cycle** — `A supersedes B` and `B supersedes A` (or a longer cycle). | version chain (Check 5) | Detect the cycle; do NOT attempt to assemble a linear chain or pick a head. Surface it as a chain-break of type "cycle" with the disambiguation block — the operator breaks the cycle by removing one edge. Never auto-resolve. |
| 4 | **Empty sibling_topic** — one or both sibling-duplicate candidates lack `sibling_topic`. | sibling duplicate (Check 2) | Degrade to the weak key `parent_artifact + artifact_type`, attach the "missing sibling_topic — weak match" warning, and surface as lower-confidence (MEDIUM/LOW). Never auto-merge a weak match; the operator decides. |
| 5 | **Two chain heads (fork)** — a version/supersede chain has two artifacts that nothing supersedes (the chain forked). | version chain (Check 5) | Surface both heads as a chain-break of type "fork" with the 3-option disambiguation block. Do NOT pick a head. The operator designates the current head (and links or archives the other branch). |
| 6 | **Promoted-still-in-08** — an artifact whose `artifact_state` is `PROMOTED` (or `lifecycle_state: published`) but whose `folder` is still `08-Generated/`. | displaced content (Check 4) | Flag as displaced; propose completing the promotion move to the `artifact_type` canonical home (per `work-plan-taxonomy.md`). This is the canonical displaced-content case — a promotion that updated the state but never moved the file. |
| 7 | **Archived-as-live-parent** — an artifact in `_archived/` (or `artifact_state: ARCHIVED`) is still cited as the `parent_artifact` of a live artifact. | orphan (Check 1) / version chain (Check 5) | Scan `_archived/` read-only to resolve the pointer (so the child is not falsely flagged as a dangling orphan), but surface a finding that a *live* artifact descends from an *archived* parent — the operator decides whether to re-parent the child or archive it too. `_archived/` is a read-only signal source here, never a write target. |

## Cross-cutting rules these edge cases imply

- **Read-only resolution against excluded/archived paths.** Cases 2 and 7 require resolving a `parent_artifact` pointer *into* an excluded or archived path to avoid a false orphan — but resolution is read-only and never generates findings *about* the excluded/archived artifact itself.
- **Never auto-resolve a break.** Cases 3 and 5 (cycle, fork) and case 4 (weak match) are always operator-decidable via the disambiguation block — the lint surfaces, the operator chooses.
- **Skip-with-note, never silent-drop.** An artifact with neither embedded frontmatter nor a sidecar (the input-resolution tail) is listed in the report's "unscannable" section, not dropped. Case 1 (disagreement) is noted in evidence, not silently merged.

### Sources
- #334 — the artifact-lineage-graph split whose Stage-5 deferrals seed this 7-item edge-case register.
