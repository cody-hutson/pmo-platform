<!-- reference-durability: allow-link -->
# Implementation Execution Pattern — Reference Workflow

This reference document defines the 7-step Read+Edit+Bash workflow for executing implementation plans emitted by `implementation-planner` in the Edit-ready format specified by [`release/skills/implementation-planner/references/output-format-spec.md`](../../skills/implementation-planner/references/output-format-spec.md) (Spec 5). This workflow **replaces the deprecated `implementer` skill** — the skill was a thin wrapper over Claude Code's native Read/Edit/Write/Bash with no irreplaceable logic. This doc preserves the workflow discipline (drift checks, write-verify, snapshots, failure modes, reversibility) while eliminating the skill-deployment surface and domain-lock that the old skill carried.

## Purpose

Document the surgical-execution pattern an operator (or agent acting as operator) follows when given an `implementation-planner` plan in Edit-ready format. Establishes the input contract (Spec 5), the Tool-to-Spec-5 mapping for each step, failure modes, and reversibility tiers — everything the deprecated `implementer` skill documented, expressed as a reference workflow rather than a skill.

**Rationale for replacement** (per the 2026-04-18 Anthropic mapping analysis): Claude Code's native tools (Read, Edit, Write, Bash) provide stronger safety primitives (built-in uniqueness enforcement on `old_string`, atomic file operations, shell-level error propagation) than the wrapper skill. Git-native snapshots + direct tool use achieve the same outcome with less code and stricter discipline.

## Scope

Applies when an operator has:
- An implementation plan emitted by `implementation-planner` in the format defined by [`output-format-spec.md`](../../skills/implementation-planner/references/output-format-spec.md) Section 2.
- Target files in expected state (source-file state matches the plan's expected `old_string` anchors).
- A git working tree on a feature branch under `<OPERATOR_INSTANCE_WORKTREES_PATH>/*` (not the primary checkout per `core/rules/git-workflow.md`).

Does NOT apply when:
- The plan is not in Edit-ready format (e.g., prose-style remediation spec from an earlier planner) — regenerate via the current planner first.
- The plan targets a gh-issue-body or gh-pr-body **and** the RI omits the `Target Type` field (Spec 5 body-target support landed via the body-target extension — body RIs MUST declare `Target Type: gh_issue_body | gh_pr_body` + `Target Ref` + `Body Edit Mode`; a body edit with no `Target Type` is treated as a malformed `file` RI and blocked at Step 1).
- The operator is working in the primary checkout — that's read-only per Primary Checkout Discipline; switch to a worktree first.

## Inputs

1. **Implementation plan** — a markdown document containing RI-NNN records per Spec 5 format. The plan's Implementation Register (Section 3 of the planner output) lists every RI with batch assignment. Per-RI Detailed Records (Section 4) contain the fenced `edit` or `bash` blocks the workflow consumes.
2. **Target files in expected state** — all files cited in RI `file_path` fields exist and contain the expected `old_string` anchors (verified at Step 1 Pre-execution Drift Check).
3. **Git working tree on a release branch** — the worktree's HEAD matches the branch name per git-workflow.md §Primary Checkout Discipline.

## Prerequisites

- Claude Code session with Read, Edit, Write, Bash, and Grep tools available.
- Working directory = a worktree under `${HOME}/Claude/<OPERATOR_INSTANCE_WORKTREES_PATH>/<branch-name>/` (confirm via `pwd`).
- `git status` clean or with only intentional staged/unstaged changes (no Layer 2 file leakage).
- Findings register referenced by the plan's Section 1 Plan Metadata exists and is accessible for traceback if needed.

---

## The 7-Step Workflow

The 7 steps are the **reference catalog** (they match the deprecated-implementer issue body's enumeration and output-format-spec.md Section 5's mapping table). The operational time-sequence is in the [Execution Order](#execution-order) section below — Step 4 (Snapshot) fires BEFORE Step 2 (Edit) despite its higher number in the reference order.

### Step 1 — Pre-execution Drift Check

- **Tool:** Grep + Read.
- **Spec 5 element consumed:** RI Metadata `file_path` + Edit spec `old_string` (Section 2).
- **Inputs:** Every RI's `file_path` and `old_string` from the plan's Section 4 Detailed Records.
- **Outputs:** Per-RI status — `DRIFT_OK` (anchor found, unique) / `EXECUTION_BLOCKED` (anchor not found or non-unique) with evidence.
- **Failure mode:** Anchor not found at specified `file_path`, OR anchor found at multiple locations (uniqueness violation).
- **Recovery:** Mark RI `EXECUTION_BLOCKED`. If ≥1 RI is BLOCKED, halt the entire workflow and return to planner via `[SCOPE CHANGE]` Tier 2 escalation per release-process.md Inter-Stage Feedback Protocol. Do NOT substitute a near-match anchor (see Failure Mode 3 below).
- **Reversibility tier:** CHEAP · Confidence: HIGH (read-only operation; no state change; evidence is unambiguous).
- **Target Type / `replace_all` branch:** For `Target Type: file` — unchanged (`grep -c -F` anchor; `replace_all` absent ⇒ count must == 1; `replace_all: true` ⇒ count must >= 1; 0 ⇒ `EXECUTION_BLOCKED`). For `gh_issue_body` / `gh_pr_body` with `Body Edit Mode: anchor` — fetch via `gh issue/pr view <N> --json body -q .body`, then run the same `grep -c -F` anchor gate over the fetched body. For `Body Edit Mode: full` — recompute `sha256` over the fetched body and compare to `Body SHA256 (captured)`. New outcome `BODY_DRIFTED` is a peer of `EXECUTION_BLOCKED` (same Phase-A halt + `[SCOPE CHANGE]` Tier 2).

### Step 2 — Per-Batch Edit (apply each RI)

- **Tool:** Edit.
- **Spec 5 element consumed:** Fenced `edit` block (Section 2 RT-1..RT-5) — the `file_path` + `old_string` + `new_string` tuple directly translates to Claude Code Edit tool parameters.
- **Inputs:** One RI's fenced `edit` block at a time; absolute `file_path`; verbatim `old_string` and `new_string` from the plan.
- **Outputs:** Edit applied; Edit tool reports success or a specific failure (anchor not found, not unique, or other).
- **Failure mode:** Edit reports `old_string not unique` or `old_string not found`. This should have been caught at Step 1 — if it surfaces here, Step 1 was skipped or the target file changed between Step 1 and Step 2.
- **Recovery:** `[SCOPE CHANGE]` Tier 2 — return RI to planner for anchor extension per Spec 5 Section 4 uniqueness contract. Do NOT edit the anchor at execution time (see Failure Mode 3 below).
- **Reversibility tier:** CHEAP (single RT-1..RT-3 Edit; git revert restores) to EXPENSIVE (RT-5 multi-doc coordination, reversal spans multiple files) — per the RI's declared tier in Metadata block.
- **`replace_all` dispatch:** read `replace_all` from the RI's `edit` block; when `true`, pass `replace_all: true` to the Claude Code Edit call (applies the correction to ALL occurrences of `old_string` in one call). This is the dispatch the ticket loosely calls "Step 3" — it is Step 2 (Edit), distinct from planner-Step-3 (validate) and executor-Step-3 (write-verify).
- **Body-target dispatch:** body `anchor` mode performs the in-memory `old_string`→`new_string` replace on the fetched body then `gh … edit -F -` write-back; body `full` mode performs the `sha256` precondition then `gh … edit -F -`. Both are `bash`-block-shaped and are dispatched in **Phase D** alongside RT-6/RT-7 (the wire mechanic is a `gh` Bash invocation, not a Claude-Code Edit call). `replace_all` rides the body `anchor` in-memory replace identically (it is a property of the `old_string`→`new_string` substitution, agnostic to file-vs-fetched-body source). `Body Edit Mode: full × replace_all` is N/A by construction (no `edit`/`old_string` key site).

### Step 3 — Write-Verify (Read post-Edit)

- **Tool:** Read.
- **Spec 5 element consumed:** Edit spec `new_string` (Section 2).
- **Inputs:** The `file_path` of the just-executed Edit; the expected `new_string` from the RI's Edit spec.
- **Outputs:** Per-RI status — `WRITE_VERIFIED` (Read shows `new_string` landed byte-for-byte) / `WRITE_VERIFY_FAILED` (mismatch — whitespace drift, line-ending mutation, or partial replacement).
- **Failure mode:** Expected `new_string` text is not present at the edited location, OR surrounding text has mutated unexpectedly (leading/trailing whitespace, line endings, or off-by-one line).
- **Recovery:** Mark RI `WRITE_VERIFY_FAILED`. Halt the batch (do NOT proceed to next RI in this batch). Investigate: compare byte-level diff between expected and actual; identify mutation source; either re-Edit with corrected `new_string` or return RI to planner for re-spec.
- **Reversibility tier:** CHEAP · Confidence: HIGH (read-only operation; evidence is exact byte comparison).
- **`replace_all` / body write-verify:** for `replace_all: true` — assert (i) **zero residual `old_string`** in the target AND (ii) `new_string` present at >=1 location; record the actual applied count M; **N≠M ⇒ advisory drift note** in the execution log (NOT an auto-BLOCK — surfaces the whitespace-variant footgun without rigidity). For body `anchor` — re-fetch via `gh … view --json body -q .body`; assert `new_string` present + `old_string` absent. For body `full` — re-fetch; assert `sha256` == `<post-state sha256>`. For `file` absent/false — unchanged (`new_string` landed at the location).

### Step 4 — Snapshot-Before-Execution

- **Tool:** Bash (git commit or stash).
- **Spec 5 element consumed:** None — Spec 5 doesn't specify this. Workflow-level step per release-process.md Stage 11 compression (git-native snapshot).
- **Inputs:** Current working tree state on the release branch before any Edit batch begins.
- **Outputs:** A git commit (or stash) with the message `snapshot: pre-execution state for <release> RIs <range>` marking the pre-state as a restore target.
- **Failure mode:** `git commit` fails — uncommitted changes not staged, pre-commit hook rejects, or git state is otherwise inconsistent.
- **Recovery:** Resolve git state per `core/rules/git-workflow.md` before proceeding. Do NOT proceed to Step 2 with an unresolved snapshot.
- **Reversibility tier:** CHEAP · Confidence: HIGH (single git commit; trivially reversible via `git reset HEAD~1`).

### Step 5 — Version Log Entries (Edit-applied)

- **Tool:** Edit (bundled with Step 2).
- **Spec 5 element consumed:** RI Metadata `Version log entry (pre-computed)` field (Section 2).
- **Inputs:** The pre-computed version log entry from the RI Metadata block.
- **Outputs:** Version log entry added to the target file's Version Log section (when applicable).
- **Failure mode / N/A condition:** Target file has no Version Log section (most `pmo-platform/` reference docs don't have one — Version Logs are more common in Copilot-pack documents). In that case, Step 5 is N/A for this RI.
- **Recovery:** When a Version Log section exists and the entry should be applied, it's bundled into the Step 2 Edit's `new_string` (not a separate Edit). Skip silently when the file has no such section.
- **Reversibility tier:** CHEAP (inherits Step 2's tier for the file modification).

### Step 6 — Execution Log (post-batch markdown)

- **Tool:** Bash (write markdown to a file) OR Edit (when appending to an existing execution log file).
- **Spec 5 element consumed:** RI Metadata block fields (Section 2: RI-ID, file_path, RT type, Reversibility tier, Status).
- **Inputs:** RI status accumulator from Steps 1-5 across the batch (`EXECUTED` / `EXECUTION_BLOCKED` / `WRITE_VERIFY_FAILED` per RI).
- **Outputs:** Markdown table summarizing the batch — one row per RI with (RI-ID, file_path, RT type, Reversibility, Status, notes for blocked/failed).
- **Failure mode:** Cannot write execution log (e.g., disk full, permission denied).
- **Recovery:** Emit log inline in PR body or commit message instead; do not let logging failure block workflow completion.
- **Reversibility tier:** CHEAP · Confidence: HIGH (documentation only; no effect on target files).

### Step 7 — RT-6 / RT-7 Bash Execution

- **Tool:** Bash.
- **Spec 5 element consumed:** Fenced `bash` block (Section 2 RT-6 / RT-7) — the executable script fragment.
- **Inputs:** RI's Bash spec with absolute paths + pack-specific script logic sourced from the active pack's Extract Specifics or Manifest Specifics section.
- **Outputs:** For RT-6 — derived artifact regenerated (e.g., `Runtime_Constitutional_Minimum_Set.md` for copilot-builder pack); for RT-7 — checksum values computed for operator to apply to manifest.
- **Failure mode:** Script returns non-zero; RT-6 output fails co-load guard check; RT-7 checksum computation errors.
- **Recovery:** Halt. RT-6 and RT-7 are typically EXPENSIVE (per ADR-E pack-declared default tiers). Sign-off gate before retry. For RT-6, investigate co-load guard violation before re-running. For RT-7, verify the affected-files list matches the release's actual touched-files set.
- **Reversibility tier:** EXPENSIVE (RT-6) / MODERATE (RT-7) per Spec 5 RI Metadata.

---

## Spec 5 Consumption Mapping

Authoritative cross-reference table. Any divergence between this table and [`output-format-spec.md`](../../skills/implementation-planner/references/output-format-spec.md) Section 5 = design-coherence regression; `[SCOPE CHANGE]` Tier 2 escalation required before merge.

| Workflow Step | Tool | Spec 5 Element Consumed | Failure Mode | Recovery |
|---|---|---|---|---|
| **1. Pre-execution drift check** | Grep + Read | RI Metadata `file_path` + Edit spec `old_string` (Spec 5 §2) | Anchor not found or non-unique at expected location | Mark RI `EXECUTION_BLOCKED`; if any RI blocked, halt and `[SCOPE CHANGE]` Tier 2 to planner |
| **2. Per-batch Edit (apply each RI)** | Edit | Fenced `edit` block (Spec 5 §2 RT-1..RT-5) | Edit tool reports `old_string not unique` / `not found` | Per Spec 5 §4 uniqueness contract: planner should have prevented this; if encountered, `[SCOPE CHANGE]` to extend anchor |
| **3. Write-verify (read post-Edit)** | Read | Edit spec `new_string` (Spec 5 §2) | Mismatch between expected `new_string` and actual file content | Mark RI `WRITE_VERIFY_FAILED`; halt batch; investigate (whitespace? trailing newline? indent?) |
| **4. Snapshot (pre-execution)** | Bash (git commit) | N/A — Spec 5 doesn't specify; workflow-level (per Stage 11 git-native compression) | git commit fails (uncommitted changes, hooks reject, etc.) | Resolve git state per `core/rules/git-workflow.md`; do NOT proceed with Edits |
| **5. Version log entries (Edit-applied)** | Edit (bundled with Step 2) | Spec 5 §2 `Version log entry (pre-computed)` field | File has no Version Log section | Skip silently (most pmo-platform files have no Version Log section; this is N/A) |
| **6. Execution log (post-batch markdown)** | Bash (cat/echo to file or commit message) | RI Metadata block fields (Spec 5 §2: RI-ID, file_path, RT type, Reversibility tier, Status) | Cannot generate log (e.g., file write blocked) | Emit log inline in PR body or commit message instead |
| **7. RT-6 / RT-7 Bash blocks** | Bash | Fenced `bash` block (Spec 5 §2 RT-6/RT-7) | Bash script returns non-zero | Halt; per ADR-E pack-declared applicability, RT-6/RT-7 are typically EXPENSIVE — sign-off gate before retry |

<!-- TWIN-TABLE-ALIGNMENT-BEGIN (byte-identical in output-format-spec.md §5 and implementation-execution-pattern.md Spec 5 Consumption Mapping; sha256-comparable; divergence ⇒ [SCOPE CHANGE] Tier 2) -->
**Target Type + `replace_all` consumption (Steps 1–3):**

- **Step 1 (drift check):** `Target Type: file` — unchanged (`grep -c -F` anchor; `replace_all` absent ⇒ count must == 1; `replace_all: true` ⇒ count must >= 1; 0 ⇒ `EXECUTION_BLOCKED`). Body `anchor` — fetch via `gh issue/pr view <N> --json body -q .body`, then the same `grep -c -F` anchor gate over the fetched body. Body `full` — recompute `sha256` over the fetched body, compare to `Body SHA256 (captured)`. Outcome vocabulary adds `BODY_DRIFTED` (peer of `EXECUTION_BLOCKED`; same Phase-A halt + `[SCOPE CHANGE]` Tier 2).
- **Step 2 (per-batch dispatch):** read `replace_all` from the RI's `edit` block; when `true`, pass `replace_all: true` to the Edit invocation (applies the correction to ALL occurrences in one call). `file` targets → Phase-C Edit loop. Body `anchor` → in-memory `old_string`→`new_string` replace then `gh … edit -F -` write-back in **Phase D** (the wire mechanic is a `gh` Bash invocation, not a Claude-Code Edit). Body `full` → `sha256` precondition then `gh … edit -F -` in Phase D. `Body Edit Mode: full × replace_all` is **N/A by construction** (a `full` block has no `edit`/`old_string`, so no `replace_all:` key site exists — documented, not validated).
- **Step 3 (write-verify):** `file`/body `anchor` with `replace_all: true` — assert (i) zero residual `old_string` AND (ii) `new_string` present at >=1 location; record the actual applied count M; **N≠M ⇒ advisory drift note** in the execution log (NOT an auto-BLOCK). Body `anchor` (absent/false) — re-fetch, assert `new_string` present + `old_string` absent. Body `full` — re-fetch, assert `sha256` == post-state. `file` (absent/false) — unchanged.
- **Backward-compat:** `Target Type` absent ⇒ `file`; `replace_all` absent ⇒ `false`. The joint default reproduces the exact pre-extension RT-1 behavior; every existing RI is byte-unchanged.
<!-- TWIN-TABLE-ALIGNMENT-END -->

**Critical integration point with Spec 5 Section 4 (uniqueness contract):** Step 1's drift check is the operational manifestation of the uniqueness contract on `old_string`. If the planner emits a non-unique anchor, Step 1 catches it BEFORE any Edit happens. This is the design coherence guarantee at the workflow ↔ planner boundary — **the workflow trusts the planner to deliver unique anchors, but Step 1 verifies before Step 2 acts.**

**Critical integration point with Spec 5 Section 6 (Edit tool semantics):** Step 3 write-verify is the operational manifestation of the "Edit tool enforces exact string matching with leading/trailing whitespace significant" note. Whitespace-significant matching is invisible until you Read post-Edit and diff. Step 3 catches whitespace/encoding/newline drift that survived the Edit but mutated the file in unexpected ways.

---

## Execution Order

The 7 steps above are the **reference catalog** (concept-by-tool). The actual time-sequence the operator follows is organized into 5 phases:

### Phase A — Pre-flight (read-only)

**Step 1 (drift check) for ALL RIs in the plan.** Sequential Grep+Read per RI; accumulate per-RI `DRIFT_OK` / `EXECUTION_BLOCKED` status.

**Gate:** If ≥1 RI is `EXECUTION_BLOCKED` **or `BODY_DRIFTED`** (body-target peer of `EXECUTION_BLOCKED`: anchor not found / non-unique in the fetched body, or a `Body Edit Mode: full` `sha256` mismatch against `Body SHA256 (captured)`), halt the entire workflow and return to the planner via `[SCOPE CHANGE]` Tier 2 per release-process.md Inter-Stage Feedback Protocol. Do NOT proceed to Phase B. Evidence to include in the escalation: list of blocked RIs with their `file_path` (or `target_ref`) and `old_string` and the observed actual state.

**Phase A reversibility:** CHEAP · Confidence: HIGH (read-only; no state change).

### Phase B — Pre-execution Snapshot

**Step 4 (git commit pre-state).** Single commit with message `snapshot: pre-execution state for <release> RIs <range>`. The commit can be empty (if the worktree was clean) — the commit message itself is the marker for `git revert`.

**Gate:** Snapshot commit must succeed before Phase C. If `git commit` fails, resolve the git state first.

**Phase B reversibility:** CHEAP · Confidence: HIGH (single git commit; reversible via `git reset HEAD~1`).

### Phase C — Per-Batch Loop

**For each batch in the plan's Section 5 Execution Batch Plan:** **for each RI in the batch:** Step 2 (Edit) → Step 3 (write-verify). Step 5 (Version log entry) is bundled into Step 2's Edit when applicable.

**On any Step 2 failure (anchor not unique / not found):** Halt batch. `[SCOPE CHANGE]` Tier 2 per Step 2 Recovery.

**On any Step 3 `WRITE_VERIFY_FAILED`:** Halt batch. Investigate per Step 3 Recovery. Append to execution-log accumulator. Return to operator for decision (re-Edit vs. return-to-planner).

**Sequencing note:** Per-batch ordering within a pack follows the active pack's `sequencing_rules_ref` section (see `domain-packs/<pack>-domain.md`). Example: for `copilot-builder` pack, constitutional fixes (Docs 01-04) go first; RT-5 multi-doc coordinations are batch-isolated.

**Phase C reversibility:** Inherits per-RI tier from Spec 5 Metadata block — CHEAP for RT-1..RT-3 default; MODERATE-to-EXPENSIVE for RT-4/RT-5.

### Phase D — Post-Edit Bash (RT-6 / RT-7)

**Step 7 for any RT-6 / RT-7 records** in the plan's Section 4 Detailed Records, in pack-declared order (typically: all RT-6 extract regenerations first, then all RT-7 manifest updates last — per copilot-builder pack sequencing).

**Body-target dispatch also runs here.** Any RI with `Target Type: gh_issue_body | gh_pr_body` dispatches in Phase D (not the Phase-C Edit loop) because the wire mechanic is a `gh … edit -F -` Bash invocation, not a Claude-Code Edit: `Body Edit Mode: anchor` → fetch body → in-memory `old_string`→`new_string` replace (carrying `replace_all: true` when set) → `gh … edit -F -` write-back; `Body Edit Mode: full` → mandatory `sha256` precondition → `gh … edit -F -` full-body write. Body-target write-verify (Step 3 re-fetch) runs immediately after each body dispatch, same halt-on-mismatch posture as file targets.

**Gate:** All Phase C batches must be complete. RT-6 regeneration operates on post-Edit source files; RT-7 checksums are computed on post-Edit (and post-RT-6) artifacts.

**On any Step 7 failure:** Halt. Sign-off gate before retry (RT-6 typically EXPENSIVE; RT-7 MODERATE but touches manifest). Do not proceed to Phase E until operator approves.

**Phase D reversibility:** EXPENSIVE (RT-6) / MODERATE (RT-7) per pack defaults.

### Phase E — Execution Log Emit

**Step 6 — generate the execution log as markdown** from the RI status accumulator (Phases A-D combined). Format: markdown table with columns from Spec 5 §2 Metadata block.

**Delivery:** Commit alongside the Edit commits (e.g., as `<OPERATOR_INSTANCE_ANALYSIS_PATH>/<release>-execution-<date>/execution-log.md`), OR write to a designated artifact file per operator choice. Log contents are replayed in the PR description for reviewer traceability.

**Phase E reversibility:** CHEAP · Confidence: HIGH (documentation only).

---

## Failure Modes

Three domain-specific failure modes govern workflow execution. Each follows the 5-field conditional template per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md). G7 gate-enforcement in pmo-qa-auditor only fires on SKILL.md files — this doc is a reference workflow, not a skill, so ≥3 floor is authored here as principal-grade discipline rather than gate-enforced.

### Skipping write-verify under batch-completion pressure — PROC

- **Signature (observable signal):** Execution log shows `EXECUTED` for an RI but no Read-after-Edit verification entry; later RIs target text the prior Edit was supposed to leave in place but didn't, producing cascade `EXECUTION_BLOCKED` failures.
- **Conditional:** do NOT skip the write-verify Read after each Edit when applying the workflow, because Claude Code Edit tool can succeed while leaving the file in an unintended state (whitespace drift, partial replacement, line-ending mutation) and downstream RIs depend on the exact `new_string` byte-pattern landing as Spec 5 specified.
- **Root cause:** Write-verify feels redundant after a successful Edit; under batch-completion pressure operators batch all Edits then verify only at the end of the batch — discovering cascade failures after sunk-cost has accumulated.
- **Mitigation:** Write-verify is per-Edit, not per-batch. Read the modified file IMMEDIATELY after each Edit; compare to expected `new_string`; mark `WRITE_VERIFY_FAILED` if mismatch and HALT the batch (do not proceed to next RI). Resume only after the failure root cause is identified (whitespace? indentation? trailing newline?).
- **Principal response vs. junior response:** Principal verifies after each Edit; if a write-verify fails, halts batch, examines the file, and either re-Edits with corrected `new_string` or returns RI to planner via `[SCOPE CHANGE]`. Junior batches all Edits then runs one final diff and discovers cascade failures across multiple RIs — by then the rollback target is unclear and several Edits' worth of work must be unwound.

### Snapshot deferred to mid-batch instead of pre-execution — PROC

- **Signature (observable signal):** Execution log shows the snapshot commit timestamp AFTER one or more Edit batches' commits; rollback would require multi-commit revert that touches both pre-state AND in-flight Edits.
- **Conditional:** do NOT defer the pre-execution snapshot (Phase B) until after Phase C has begun applying Edits, because git history is the rollback mechanism and an in-flight Edit batch interleaved with the pre-execution snapshot loses the clean rollback target — a single `git revert <snapshot-commit>` would either revert nothing (if snapshot is empty) or revert too much (if snapshot is post-some-Edits).
- **Root cause:** The pre-execution snapshot feels like an "if-needed" step that can be backfilled when something fails; staging a no-op commit feels wasteful before any Edits have happened.
- **Mitigation:** Stage the snapshot commit BEFORE the first Edit. Use a dedicated commit message like `snapshot: pre-execution state for vX.Y RIs <range>` so git log makes the rollback target unambiguous. The snapshot commit can be empty (if working tree was clean) — the message itself is the marker.
- **Principal response vs. junior response:** Principal commits a clean snapshot before any Edit and treats it as a non-negotiable Phase B step. Junior amortizes git operations to "save commits" and discovers post-failure that revert touches both pre-state AND in-flight Edits — the rollback becomes a multi-commit cherry-pick exercise instead of a single `git revert`.

### Improvising substitute anchor when `old_string` not located at Step 1 — PROC

- **Signature (observable signal):** Execution log shows `EXECUTED` for an RI whose Phase A drift check (Step 1) had marked `EXECUTION_BLOCKED`; notes attached like "matched at nearest location" or "anchor adjusted to current state" replace the original Spec 5 `old_string`.
- **Conditional:** do NOT substitute a near-match anchor when Spec 5's `old_string` is not located at the specified `file_path` during Step 1, because Spec 5 §4's uniqueness contract assumes drift checks gate execution; improvising at execution time inverts the gate, re-enters the planning surface that this workflow is specifically designed not to touch, and substitutes a surgical-executor role with an ad-hoc replanner role that the bundle's governance does not sanction.
- **Root cause:** The near-match feels like progress; marking `EXECUTION_BLOCKED` feels like failure when the near-match is "obviously what the planner meant." Under completion pressure the operator substitutes judgment for the plan — the specific behavior the deprecated implementer skill's Anti-Laziness Rule #3 was designed to prevent (and which this reference workflow inherits).
- **Mitigation:** When Step 1 marks an RI `EXECUTION_BLOCKED`, return the RI to `implementation-planner` for re-spec via `[SCOPE CHANGE]` Tier 2 escalation per release-process.md Inter-Stage Feedback Protocol. Do NOT execute the Edit with a substitute anchor. The planner re-specifies; the workflow does not.
- **Principal response vs. junior response:** Principal returns to planner with specific evidence: "RI-NNN specified `old_string` X at file F; X not found; actual text at that location is Y; recommended planner action — re-spec with anchor extended to include preceding heading." Junior finds the near-match, substitutes, applies the Edit with note "adjusted at execution time" — the bundle picks up an unauthorized edit and the downstream PR review flags the authority-boundary breach.

---

## Reversibility Discipline

Per [`reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md). Workflow-level reversibility is expressed phase-by-phase; per-RI reversibility inherits from the Spec 5 Metadata block.

**Workflow-level tiers:**

- **Phase A (Pre-flight drift check):** CHEAP — read-only; no state change; reversible by doing nothing.
- **Phase B (Pre-execution snapshot):** CHEAP — single git commit; reversible via `git reset HEAD~1`.
- **Phase C (Per-batch Edit + write-verify):** Inherits per-RI tier from Spec 5 Metadata (CHEAP for RT-1..RT-3 default; MODERATE-to-EXPENSIVE for RT-4/RT-5). Rollback target: the Phase B snapshot commit. Partial-batch failure: halt at the failing RI; Phase B snapshot preserves the clean pre-state.
- **Phase D (Post-Edit Bash for RT-6/RT-7):** Inherits per-RT tier — RT-6 typically EXPENSIVE (derived artifact rebuild; reversal requires re-running with prior-state sources); RT-7 typically MODERATE (manifest row update; revertable via git).
- **Phase E (Execution log emit):** CHEAP — documentation only; no target-file impact.

**Decision-class items in the execution log** (recommendations to operator on `EXECUTION_BLOCKED` / `WRITE_VERIFY_FAILED` RIs) carry tier labels per the SAME format as the deprecated implementer skill's `## Reversibility Discipline` section preserved here:

- `CHEAP · confidence: HIGH` for a single-RI drift-check recommendation ("return RI-042 to planner; anchor not found").
- `MODERATE · confidence: MEDIUM` for a batch-level escalation ("3 of 8 RIs in Batch 2 failed; recommend halting release and re-planning Batch 2").
- `EXPENSIVE · confidence: HIGH` for an RT-6/RT-7 post-execution remediation recommendation ("Doc 28 checksum update requires re-running RT-7 after Doc 11 hotfix").
- `IRREVERSIBLE` is rare at workflow level — would fire on a post-execution discovery that an RT-5 coordination left target files in an inconsistent state that cannot be reverted via single `git revert` (e.g., if Phase B snapshot was skipped — see Failure Mode 2).

---

## Relationship to Deprecated Implementer Skill

The `implementer` skill (now deprecated) encapsulated the workflow documented here as a skill definition under `release/skills/implementer/SKILL.md`. Per the 2026-04-18 Anthropic mapping analysis, the skill was a thin wrapper over Claude Code's native Read/Edit/Write/Bash tools with no irreplaceable logic — the workflow could equally be documented as a reference doc without the skill-deployment overhead.

**What was lost by removing the skill:**
- The `--skill implementer` invocation shortcut (minor ergonomic loss).
- Skill-level failure-mode enforcement via pmo-qa-auditor G7 gate (the gate fires on SKILL.md files only; this reference doc's Failure Modes are not G7-enforced but ARE authored to the same 5-field standard).

**What was gained by replacement:**
- Git-native snapshot (Phase B) replaces the deprecated skill's nonexistent snapshot primitive. The old skill had no built-in rollback target; this reference workflow makes the snapshot a gated, explicit, single-commit operation.
- Write-verify (Step 3) replaces the deprecated skill's nonexistent write-verify. The old skill trusted Edit's success signal; this reference workflow adds a Read post-Edit to catch whitespace/encoding drift that survives Edit but mutates the file.
- Direct Claude Code tool invocations (Edit, Read, Bash, Grep) vs. skill-layer indirection — stronger built-in safety primitives (exact-string enforcement, atomic file ops, shell error propagation).
- Reduced deployment surface — one fewer skill to deploy, version, and drift-check.

**Post-merge operator action (Layer 2 / Cowork-side):** After the deprecation PR merges, the installed copy of the `implementer` skill at the Cowork session path remains (per `deploy.sh` line 352 E-03 Deleted Skills warning). Manual cleanup: `rm -rf '<install-path>/implementer/'`. The post-merge operator should also verify that no ongoing Cowork sessions invoke the deleted skill (it simply won't be found, producing a user-visible error).

## Demonstration

This workflow has been demonstrated end-to-end executing a single real RT-1 fix (per the AC demonstration requirement, Option B per Finding 7 — the demonstration target is a small platform-file correction that stays squarely within Spec 5's file-path domain).

## See Also

- [`release/skills/implementation-planner/references/output-format-spec.md`](../../skills/implementation-planner/references/output-format-spec.md) — input contract (Spec 5).
- [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) — 5-field conditional template used by Failure Modes section above.
- [`reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md) — reversibility tier vocabulary.
- [`pipeline/stage-11-snapshot.md`](../pipeline/stage-11-snapshot.md) — Snapshot compression for git-native releases.
- [`release/governance/release-process.md`](../../governance/release-process.md) — git-native compression model.
- [`core/rules/git-workflow.md`](../../../core/rules/git-workflow.md) — Primary Checkout Discipline (worktree-only execution).
- [`../skills/implementation-planner/SKILL.md`](../../skills/implementation-planner/SKILL.md) — upstream skill that emits the plans this workflow consumes.
