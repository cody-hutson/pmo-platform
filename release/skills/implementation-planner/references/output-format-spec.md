# Implementation-Planner — Edit-Ready Output Format Specification

This document defines the **Edit-ready output contract** for implementation records (RI-NNN) emitted by `implementation-planner`. It is the **authoritative input contract** consumed by [`release/references/how-to/implementation-execution-pattern.md`](../../../references/how-to/implementation-execution-pattern.md) (the downstream reference workflow).

**Scope:** defines how RI-NNN records render for each RT type (RT-1..RT-8), the uniqueness contract for `old_string`, the file-path convention, and the step-by-step consumption mapping that the downstream reference workflow follows.

**See also:** [`domain-packs/README.md`](domain-packs/README.md) — pack registry; [`../../SKILL.md`](../SKILL.md) — the planner skill.

---

## Section 1 — Rationale

Previously, the planner emitted per-RT prose template blocks (`Current text: "[exact current text]"` / `Replacement text: "[exact replacement text]"`) that required human interpretation to translate into Claude Code Edit tool calls. With the `implementer` skill deprecated in favor of a reference workflow that directly invokes Claude Code's native Read/Edit/Write/Bash tools, the plan must be **directly consumable** — each RI-NNN renders as tool input the operator can execute with minimal transformation.

Design philosophy change: from "human-readable specification" to "machine-executable specification." Human readability is retained via the Metadata block framing each RI; machine-executability is added via fenced `edit` and `bash` blocks that match Claude Code's tool schemas.

**Why this matters for the reference workflow:** Every element of this spec is consumed at a specific step of the 7-step reference workflow. The mapping is deterministic (see Section 5). Divergence between this spec and the workflow's step definitions = design-coherence regression; `[SCOPE CHANGE]` Tier 2 escalation required before merge.

---

## Section 2 — Per-RT Output Format

Every RI-NNN record shares a **Metadata block** and carries exactly one rendering shape based on its Remediation Type.

### RI Metadata block (common to all RT types)

```markdown
**Metadata:**
- Finding Validation: CONFIRMED [SOURCE: <file>.md line <N>]
- Severity (validated): CS3_HIGH [HIGH]   (or: HIGH [CS3 equivalent] if pack's native is CRITICAL..LOW)
- Remediation Type: RT-N_NAME
- Reversibility: <TIER> · Confidence: <HIGH | MEDIUM | LOW>
- Blast Radius: semantic=<YES | NO>, structural=<YES | NO>, dependency=<YES | NO>
- Regression: <YES | NO> (<TARGETED | CROSS_DOCUMENT | EXTRACT_REBUILD>)
- Target Type: file | gh_issue_body | gh_pr_body      (OPTIONAL; absent ⇒ file)
- Replace All: true | false                            (OPTIONAL; absent ⇒ false)
- Replace All Match Count (planner-computed): <N>      (REQUIRED iff Replace All: true; `grep -c -F` count at plan time; recorded for traceability + the Step-3 N-vs-M drift signal — NOT a hard ceiling gate)
```

When `Target Type` ∈ {`gh_issue_body`, `gh_pr_body`} the Metadata block additionally carries (per the body-target extension):

```markdown
- Target Ref: #<N>                                     (issue/PR number; repo = current unless cross-repo-qualified `owner/repo#N`)
- Body Edit Mode: anchor | full                        (default: anchor; `full` requires explicit set + a Rationale clause)
- Body SHA256 (captured): <hex>                        ([SOURCE: `gh issue view <N> --json body -q .body` @ Body Captured At])
- Body Captured At: <ISO-8601>
- Body Pre-State Snapshot: <plan-adjacent artifact ref> (REQUIRED iff Body Edit Mode: full — the reversibility artifact; anchor mode omits it, self-inverting)
```

Every factual claim in Metadata carries an **evidence label** per CLAUDE.md Universal Preferences:
- `[SOURCE: file.md line N]` — finding located at a specific line/section.
- `[SOURCE: findings-register F-NNN]` — quoted from the upstream build-reviewer register.
- `[INFERRED: from <what>]` — severity adjustment or classification deduced.
- `[ASSUMPTION – CONFIRM: <what>]` — claim flagged for operator confirmation.
- `[CONTEXT: <what>]` — situational framing.
- `[RECOMMENDED: <what>]` — proposed action/severity.

### RT-1 Text Correction — renders as ONE `edit` block

```markdown
### RI-NNN — [Finding-ID] — RT-1 — [relative/path/to/file.md]

**Metadata:**
[standard block]

**Edit spec:**

~~~edit
file_path: ${HOME}/Claude/[absolute path]        # OR target_ref: gh_issue_body:#N | gh_pr_body:#N (body-target form)
old_string: |
  [exact current text — verbatim, including whitespace; appears at exactly ONE location, OR at >=1 location when replace_all: true]
new_string: |
  [exact replacement text]
replace_all: true                                          # OPTIONAL — default false
~~~

`replace_all` (OPTIONAL, default `false`). When `true`, the executor's Edit invocation carries `replace_all: true`, applying the correction to ALL occurrences of `old_string` in the target in a single Edit call. When absent or `false`, the exactly-one-match contract (Section 4) is unchanged. This key lives on the one `edit` grammar, so it applies to `file` RT-1 **and** `Body Edit Mode: anchor` uniformly, with no per-`Target Type` code.

**Version log entry (pre-computed):**
- [YYYY-MM-DD] [One-line summary — what changed, why, finding ID reference]

**Rationale:** [one sentence explaining why this change closes the finding]
```

### RT-1..RT-3 against body targets (`gh_issue_body` / `gh_pr_body`)

`gh issue edit -F -` / `gh pr edit -F -` read the entire new body from stdin (full-body replacement at the `gh` layer — there is no native section-edit verb). Section-diff for a body target is therefore a *planner/representation* construct (fetch full body → transform in memory → write full body back), not a `gh` mechanic. Two modes:

**`Body Edit Mode: anchor` (default; the only mode for the `[ADJUST]` Tier-1 issue-body-correction use case).** Renders the existing `edit` block grammar unchanged **except `file_path:` is replaced by `target_ref:`** — plus a sibling `bash` apply-wrapper. `old_string` / `new_string` semantics, the Section 4 uniqueness contract, and the Section 6 Edit-tool whitespace rules apply **identically** (the only delta is text-source = fetched body, not a file):

~~~edit
target_ref: gh_issue_body:#<N>
old_string: |
  [unique anchor from the fetched body — Section-4 validated, count==1 (or >=1 with replace_all: true)]
new_string: |
  [replacement]
~~~

~~~bash
# anchor-mode apply: fetch → fingerprint (advisory) → in-memory anchor replace → write-back
gh issue view <N> --repo {REPO} --json body -q .body > /tmp/ri-NNN.body
ACT=$(shasum -a 256 /tmp/ri-NNN.body | cut -d' ' -f1)
[ "$ACT" = "<Body SHA256 captured>" ] || echo "BODY_DRIFT_ADVISORY RI-NNN (anchor still primary gate)"
# executor applies the edit block to /tmp/ri-NNN.body via its Edit-equivalent (anchor is the hard gate), then:
gh issue edit <N> --repo {REPO} --body-file /tmp/ri-NNN.body
~~~

**`Body Edit Mode: full` (explicit opt-in for wholesale body re-scaffold).** Renders a `bash` block **only** (no `edit` block — no surgical diff exists) with a **mandatory** `sha256` fingerprint precondition and a verbatim pre-state snapshot reference:

~~~bash
# full-mode: MANDATORY fingerprint precondition (no anchor safe-fail available)
ACT=$(gh issue view <N> --repo {REPO} --json body -q .body | shasum -a 256 | cut -d' ' -f1)
if [ "$ACT" = "<post-state sha256>" ]; then echo "ALREADY_APPLIED RI-NNN"; exit 0; fi
[ "$ACT" = "<Body SHA256 captured>" ] || { echo "BODY_DRIFTED RI-NNN — halt, [SCOPE CHANGE] Tier 2"; exit 2; }
gh issue edit <N> --repo {REPO} --body-file - <<'RI_NNN_BODY'
<full new body verbatim>
RI_NNN_BODY
~~~

Backward-compat: `Target Type` absent ⇒ `file` ⇒ every existing `file_path`-only RI is byte-for-byte unchanged. `target_ref:` appears **only** on body RIs. `gh_pr_body:#<N>` substitutes `gh pr view/edit` for `gh issue view/edit`. The body-target ADR for this design is rendered inline above as the durable record.

### RT-2 Additive Clarification — renders as ONE `edit` block

Pattern: `old_string` = unique anchor text (a sentence, heading, or phrase that uniquely identifies the insertion point); `new_string` = anchor text **verbatim** + appended new content. This is the canonical "insert after X" pattern in Claude Code Edit (Edit's semantics replace the match exactly — so the anchor must re-appear in `new_string`).

```markdown
### RI-NNN — [Finding-ID] — RT-2 — [relative/path/to/file.md]

**Metadata:**
[standard block]

**Edit spec:**

~~~edit
file_path: ${HOME}/Claude/[absolute path]
old_string: |
  [unique anchor text — e.g., preceding heading + first sentence]
new_string: |
  [unique anchor text verbatim]
  [new clause/sentence/paragraph appended after]
~~~

**Version log entry (pre-computed):**
- [YYYY-MM-DD] [summary]

**Rationale:** [one sentence]
```

### RT-3 Reference Addition — renders as ONE `edit` block

Same pattern as RT-2 (anchor-extension). `new_string` adds the cross-reference text at the specified insertion location.

### RT-4 Section Addition — renders as ONE `edit` block

Pattern: `old_string` = preceding-section-closing-text (unique anchor that identifies the end of the section the new section follows); `new_string` = preceding text **verbatim** + new section heading + content.

```markdown
### RI-NNN — [Finding-ID] — RT-4 — [relative/path/to/file.md]

**Metadata:**
[standard block]

**Edit spec:**

~~~edit
file_path: ${HOME}/Claude/[absolute path]
old_string: |
  [closing text of preceding section — unique anchor]
new_string: |
  [closing text of preceding section — verbatim]

  ## [New Section Heading]

  [full content of the new section]
~~~

**Version log entry (pre-computed):**
- [YYYY-MM-DD] [summary]

**Rationale:** [one sentence]
```

### RT-5 Multi-Document Coordination — renders as a SEQUENCE of `edit` blocks with explicit ordering

Each RT-5 record declares a Primary Edit (applied first) and one or more Secondary Edits (applied in declared order). An executable post-execution verification command (grep, diff, or test) confirms the coordination invariant.

```markdown
### RI-NNN — [Finding-ID] — RT-5 — [N files: file1, file2, ...]

**Metadata:** (standard block + extra)
- Coordination Constraint: [exact invariant verifiable post-execution — e.g., "every CS3_HIGH enum reference in Docs 11, 14, 15, 19 appears with identical casing and tag form"]

**Primary Edit (apply first):**

~~~edit
file_path: [absolute path]
old_string: |
  [...]
new_string: |
  [...]
~~~

**Secondary Edit 1 (apply after primary):**

~~~edit
file_path: [absolute path]
old_string: |
  [...]
new_string: |
  [...]
~~~

**Secondary Edit 2 (apply after secondary 1):** (if ordering matters; declare sequentially)
(...additional Edits...)

**Post-execution verification:**

~~~bash
# Verify coordination invariant — executable grep/test command
grep -r "CS3_HIGH" Doc_11_*.md Doc_14_*.md Doc_15_*.md Doc_19_*.md
~~~

**Version log entries (one per file):** [N entries]

**Rationale:** [one sentence]
```

### RT-6 Extract Regeneration — renders as a `bash` block (domain-specific script sourced from active pack)

```markdown
### RI-NNN — [triggering-finding-id] — RT-6 — [extract-target]

**Metadata:**
- Trigger: [which upstream change requires regeneration]
- Affected Source Sections: [list]
- Expected Checksum Impact: [which downstream manifest rows]
- Co-load Guard Check: [pack-specific]
- Reversibility: EXPENSIVE · Confidence: HIGH (rebuild of derived artifact; reversal requires re-running with prior-state sources)

**Bash spec:**

~~~bash
# Pack-specific extract regeneration — see [pack-name]-domain.md § RT-6 Extract Specifics
[executable script fragment — deterministic, idempotent where possible]
~~~

**Expected outcome:** [what should be true after the script runs]

**Version log entry:** [pre-computed]

**Rationale:** [one sentence]
```

### RT-7 Manifest Update — renders as a `bash` block (checksum computation + manifest edit)

```markdown
### RI-NNN — [triggering-finding-id] — RT-7 — [manifest-target]

**Metadata:**
- Trigger: [which file change requires this update]
- Manifest Fields Affected: [checksums, risk register rows, inventory entries]
- Reversibility: MODERATE · Confidence: HIGH (revertable via git)

**Bash spec:**

~~~bash
# Compute new checksums
sha256sum [affected files] | awk '{print $1, $2}'
# Output consumed by operator to update manifest entries
~~~

**Expected outcome:** [what manifest rows should reflect after the new checksums are applied]

**Version log entry:** [pre-computed]

**Rationale:** [one sentence]
```

### RT-8 Accepted Residual — renders as a Markdown register entry (NOT an Edit)

```markdown
### RI-NNN — [Finding-ID] — RT-8 — [risk description]

**Metadata:**
- Risk Description: [concise statement]
- Why Not Fixing: [complexity cost / infrastructure dependency / theoretical-only impact]
- Revalidation Trigger: [condition under which this residual should be reassessed]
- Reversibility: MODERATE · Confidence: MEDIUM (acceptance can be overturned by re-opening the finding next round)

**Recommended register entry (for the pack's residual-risk register):**

[exact row to add — Doc 28 row for Copilot; release-plan Residual Risks section for pmo-platform]

**Rationale:** [one sentence]
```

---

## Section 3 — File Path Convention

All `file_path` values in `edit` specs MUST be **absolute paths**. This guards against cwd drift when the executor runs from a worktree (e.g., `${HOME}/Claude/<OPERATOR_INSTANCE_WORKTREES_PATH>/<name>/...`). When the plan targets files under a worktree, the absolute path reflects the worktree location, not the primary checkout.

Rationale: Claude Code's Edit tool resolves `file_path` literally; a relative path resolves against the executor's cwd, which may differ from the planner's cwd. Absolute paths eliminate ambiguity.

For body targets, `target_ref:` replaces `file_path:`. Form: `gh_issue_body:#<N>` | `gh_pr_body:#<N>` (optionally cross-repo-qualified `owner/repo#<N>`). The absolute-path rule applies to `file` targets only; `target_ref` is repo-qualified and cwd-independent by construction.

---

## Section 4 — Uniqueness Contract for `old_string`

Each `old_string` MUST match **exactly ONE location** in the target file. If the natural anchor text is non-unique (e.g., a common heading like `## Summary` appearing twice), the plan MUST extend the anchor until uniqueness is achieved.

### Extension tactics (in preferred order)

1. **Add preceding line context.** Include the line *above* the target line as part of `old_string`. Surrounding context disambiguates near-identical sections.
2. **Add the preceding heading.** If a heading + first sentence is unique even when the heading alone isn't, use both.
3. **Add structural markers.** Include the preceding `---` separator, the preceding blank line, or the preceding list item.
4. **Add wider body.** Include the full paragraph, not just the target sentence.

### Planner validation at Step 3

During SKILL.md Step 3 (Draft the Implementation Specification), the planner MUST validate anchor uniqueness for every RT-1..RT-5 `old_string`. Validation method:
- Compute the anchor's occurrence count in the target file (`grep -c -F "<anchor>"` semantics).
- If count = 1: valid.
- If count > 1: emit `EDIT_AMBIGUOUS: <RI-NNN> anchor non-unique in <file_path> (count=<N>)`. Retry with extended anchor until count = 1.
- If count = 0: emit `EDIT_NOT_FOUND: <RI-NNN> anchor missing in <file_path>`. Source-file state has drifted; mark `FINDING_NOT_CONFIRMED` and return to finding-validation step.

Claude Code's Edit tool enforces the same uniqueness contract at execution time — it fails loudly when `old_string` is non-unique or not found. The planner's Step 3 validation catches these at plan-emission time, not execution time. This is the primary safety primitive the output format provides.

### Non-file (body) anchor targets

Anchor-mode body targets (`Target Type` ∈ {`gh_issue_body`,`gh_pr_body`} with `Body Edit Mode: anchor`) are governed by the **same** exactly-one-match contract and the same Step-3 planner validation as file targets — only the text source differs (the planner runs `gh issue view <N> --json body -q .body` read-only, the body-target analog of `Read`). The uniqueness contract is the single authority for ALL anchor-based edits regardless of `Target Type`. `Body Edit Mode: full` is the sole edit class exempt from it, and is gated by the mandatory `sha256` fingerprint precondition in its stead (no anchor exists in full mode).

### Exception — `replace_all: true` (relaxation to at-least-one-match)

When an `edit` block carries `replace_all: true`, the exactly-one-match invariant relaxes to **at-least-one-match**, mirroring Claude Code's native Edit-tool semantic (Edit applies to every occurrence; fails only on zero). The relaxation does NOT remove planner obligations:

1. **Contextual-distinctness check (mandatory).** The planner MUST verify `old_string` is contextually distinct enough that **every** occurrence in the target is an intended target of the *identical* correction — not a coincidental textual collision. `replace_all` rewrites all matches indiscriminately; the planner owns the judgment "all matches == all intended." If any occurrence is not intended → extend the anchor (Extension tactics above) until the match set is exactly the intended set, OR split into per-location exactly-one-match RIs.
2. **Match-count recording.** Planner records the plan-time `grep -c -F` count in RI Metadata (`Replace All Match Count`); the workflow execution log records the actual count applied. Recorded for traceability and as a drift signal; it is NOT a declared-ceiling gate.

Planner validation at Step 3 — branch the existing check by `replace_all`:
- absent / false → count must **== 1** (unchanged: >1 ⇒ `EDIT_AMBIGUOUS`; 0 ⇒ `EDIT_NOT_FOUND`).
- `true` → count must be **>= 1** (0 ⇒ `EDIT_NOT_FOUND`, unchanged failure; >=1 ⇒ valid; record the contextual-distinctness assertion + count).

This exception is the **single authority for the relaxed contract across ALL anchor-based edits regardless of `Target Type`** (`file` RT-1..RT-5 AND `Body Edit Mode: anchor`). It is **not forked per target type**. `Body Edit Mode: full` is structurally outside this contract — see the orthogonality matrix.

### `Target Type` × `replace_all` orthogonality matrix

| `replace_all` ↓ \ target ⟶ | `Target Type: file` | body, `Body Edit Mode: anchor` | body, `Body Edit Mode: full` |
|---|---|---|---|
| absent / false | exactly-one (unchanged) | exactly-one (unchanged) | `sha256` fingerprint precond (no anchor) |
| `true` | **at-least-one** | **at-least-one (inherited via the single §4 exception)** | **N/A — by construction** |

`Body Edit Mode: full` renders a `bash`-only block with **no `edit` block**. There is structurally no `old_string` key and therefore **no `replace_all:` key site**. The cell is undefined by construction — not an error path. The spec documents it as N/A and adds **no validation rule** for it: validating "did someone set `replace_all` on a full-mode RI" would defend against a key site that the body-target grammar already precludes from existing. (`Target Type × Body Edit Mode` is the body-target axis; `replace_all` is the replacement-scope axis; they are independent except for this single structurally-empty cell.)

---

## Section 5 — Handoff to the Reference Workflow

This format is the **input contract** for `release/references/how-to/implementation-execution-pattern.md`. The 7 workflow steps consume this format as follows:

| Workflow Step | Tool | Consumes from this spec |
|---|---|---|
| **1. Pre-execution drift check** | Grep + Read | For each RI: `file_path` (Metadata) + `old_string` (Edit spec). Use Grep to confirm the anchor is present at the expected location; mark `EXECUTION_BLOCKED` if absent. |
| **2. Per-batch Edit** | Edit | Apply each RI's fenced `edit` block via Claude Code Edit tool (`file_path` / `old_string` / `new_string`), one RI at a time. |
| **3. Write-verify** | Read | After each Edit, Read the target file; confirm `new_string` landed byte-for-byte. Mark `WRITE_VERIFY_FAILED` on mismatch; halt batch. |
| **4. Snapshot-before-execution** | Bash (git) | Pre-Edit: git commit (or stash) the pre-state on the release branch. This spec does NOT specify the snapshot — it is workflow-level per release-process.md Stage 11 compression. |
| **5. Version log entries** | Edit (bundled with Step 2) | RI Metadata `Version log entry (pre-computed)`. Applied AS PART OF the Edit batch (not a separate edit) when the target file has a Version Log section the RI's `new_string` modifies. N/A for files without a Version Log section. |
| **6. Execution log** | Bash (write markdown) | Generated post-batch from RI status accumulator. Format: markdown table with columns from RI Metadata (RI-ID, file_path, RT type, Reversibility tier, status). |
| **7. RT-6 / RT-7 Bash** | Bash | Apply each RT-6 and RT-7 fenced `bash` block via Claude Code Bash tool AFTER all Edit batches complete (per active pack's sequencing rules — e.g., `copilot-builder` pack: RT-6 then RT-7 last). |

<!-- TWIN-TABLE-ALIGNMENT-BEGIN (body-target + replace-all twin tables — byte-identical in output-format-spec.md §5 and implementation-execution-pattern.md Spec 5 Consumption Mapping; sha256-comparable; divergence ⇒ [SCOPE CHANGE] Tier 2) -->
**Target Type + `replace_all` consumption (Steps 1–3):**

- **Step 1 (drift check):** `Target Type: file` — unchanged (`grep -c -F` anchor; `replace_all` absent ⇒ count must == 1; `replace_all: true` ⇒ count must >= 1; 0 ⇒ `EXECUTION_BLOCKED`). Body `anchor` — fetch via `gh issue/pr view <N> --json body -q .body`, then the same `grep -c -F` anchor gate over the fetched body. Body `full` — recompute `sha256` over the fetched body, compare to `Body SHA256 (captured)`. Outcome vocabulary adds `BODY_DRIFTED` (peer of `EXECUTION_BLOCKED`; same Phase-A halt + `[SCOPE CHANGE]` Tier 2).
- **Step 2 (per-batch dispatch):** read `replace_all` from the RI's `edit` block; when `true`, pass `replace_all: true` to the Edit invocation (applies the correction to ALL occurrences in one call). `file` targets → Phase-C Edit loop. Body `anchor` → in-memory `old_string`→`new_string` replace then `gh … edit -F -` write-back in **Phase D** (the wire mechanic is a `gh` Bash invocation, not a Claude-Code Edit). Body `full` → `sha256` precondition then `gh … edit -F -` in Phase D. `Body Edit Mode: full × replace_all` is **N/A by construction** (a `full` block has no `edit`/`old_string`, so no `replace_all:` key site exists — documented, not validated).
- **Step 3 (write-verify):** `file`/body `anchor` with `replace_all: true` — assert (i) zero residual `old_string` AND (ii) `new_string` present at >=1 location; record the actual applied count M; **N≠M ⇒ advisory drift note** in the execution log (NOT an auto-BLOCK). Body `anchor` (absent/false) — re-fetch, assert `new_string` present + `old_string` absent. Body `full` — re-fetch, assert `sha256` == post-state. `file` (absent/false) — unchanged.
- **Backward-compat:** `Target Type` absent ⇒ `file`; `replace_all` absent ⇒ `false`. The joint default reproduces the exact pre-extension RT-1 behavior; every existing RI is byte-unchanged.
<!-- TWIN-TABLE-ALIGNMENT-END -->

**Any deviation between this spec and the engineered reference workflow = Collective Review escalation.** Both sides are maintained in lockstep; each update to one MUST verify against the other via cross-reference audit in PR review.

---

## Section 6 — Compatibility Notes

- Claude Code's Edit tool enforces **exact string matching** with leading/trailing whitespace significant. `old_string` must include any whitespace that is part of the source match.
- `new_string` must NOT contain content already in the file beyond the `old_string` span. Edit's semantics: `new_string` replaces `old_string` byte-for-byte — so any text in `new_string` that exists in the file outside the matched region would be duplicated.
- For RT-2 / RT-3 / RT-4 where content is *added* rather than replaced, the canonical pattern is: `old_string` = unique anchor; `new_string` = anchor verbatim + appended content. This is the canonical "insert after X" pattern in Claude Code Edit.
- Line endings: markdown files use LF by default on this platform. Edit tool preserves existing line endings — `old_string` and `new_string` must match exactly, including any trailing newline.
- Heredoc quoting: fenced `edit` blocks use YAML-style pipe-multiline (`|`) for `old_string` and `new_string` values. Any `|` inside the value is literal (not a pipe). Operators copy-paste from the fenced block into Claude Code's Edit tool parameters directly.
- With `replace_all: true`, exact-string matching applies to **every** occurrence independently. An occurrence differing by even one whitespace/indentation character is **not** matched and is left unmodified. The planner's contextual-distinctness check (Section 4 exception) must account for whitespace-variant near-occurrences that look like targets but will not match; the Step-3 plan-N-vs-execute-M comparison is the safety signal that surfaces a silent under-application.

---

## Version Log

- **v1.0 (2026-04-19):** Initial authorship per the pluggable-domain Spec 5 (CLOSED). Establishes Edit-ready RI-NNN output contract for RT-1..RT-8 and the 7-step handoff to the downstream reference workflow.
- **v1.1 (2026-05-16):** body-target extension — add `Target Type: file | gh_issue_body | gh_pr_body` (absent ⇒ file) + body-target Metadata fields, the §2 body-rendering subsection (anchor-default / fingerprint-gated full), §3 `target_ref` convention, and the §4 non-file uniqueness subsection. replace-all extension — add the optional `replace_all` key (absent ⇒ false) on the one `edit` grammar, the §4 at-least-one-match Exception + `Target Type × replace_all` orthogonality matrix, the §6 whitespace-footgun note, and the §5 twin-table-alignment block. Purely additive; backward-compatible (joint default = pre-extension RT-1 behavior); no existing RI rewritten; no schema migration.
