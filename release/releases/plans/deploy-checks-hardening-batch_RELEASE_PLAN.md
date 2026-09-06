---
title: Release Plan — deploy-checks-hardening-batch (warn-log writer correctness, emitter-contract hygiene, and the deploy-check identifier/token surfaces)
type: release-plan
plan_type: release
status: EXECUTING
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: deploy-checks-hardening-batch
release_class: novel
reversibility: CHEAP / Confidence HIGH for the repository limb — every member is a bounded edit to tracked files plus three new files, and `git revert -m 1` of the merge restores `main` byte-for-byte. EXPENSIVE / Confidence MEDIUM for one out-of-tree limb — #6419's recovery pass mutates ~110 MB of live operator data outside git.
---
# Release Plan — `deploy-checks-hardening-batch`

**Milestone:** `deploy-checks-hardening-batch` (milestone #388) · hub sub-task **#7047** = Stage 4 plan source and the operator decision record (two **Decision Recorded** comments) · **#7137** = #6419's Stage 5 design source · **#7138** = the Stage 6 Engineering sub-task that authored this file.
**Version identity:** **versioned** — bump-class **`minor`**; the concrete `vX.Y` binds only at the Stage-12 atomic claim per ADR-092, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp token. The Commit-0 version re-verify ran in full — see § Commit-0 Version Re-Verify Record.
**Topology:** D-C **SINGLE** — one release branch (`release/deploy-checks-hardening-batch`), one PR opened once the last card lands, one merge, base `main`. This plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch. Justified independently by the C1/C3/C4 line-level contention map on one file. Every non-serial posture prohibits force-push (including `--force-with-lease`) on the shared release branch; P0 is in force, so the prohibition is moot here and is recorded for completeness.
**Release class:** `novel` — rendered by the operator at the Stage-4 gate (**D-2**, `routine` → `novel`). Differentiation posture: engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7047, together with both **Decision Recorded** comments on that sub-task (the Stage-4 routing point and the Collective Review scope-lock), and reconciles them to the Stage-5 design specification for #6419 posted on sub-task #7137. Where a later disposition superseded a Stage-4 value, the transcribed section carries the **ratified** value and § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #7138, card #6419).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination, declared at Bundle as intent-to-bump. It sets the floor and binds no concrete number. The Stage-4 recorded determination was **v4.57** (anchor `v4.56` + minor bump), provisional; the Commit-0 re-verify recomputed the same value against fresh authoritative host state. See § Commit-0 Version Re-Verify Record. |
| **Date Created** | 2026-09-05 (Saturday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/deploy-checks-hardening-batch` |
| **PR** | (populated at Stage 6 once the last card lands — this release ships as a SINGLE PR) |
| **Milestone** | `deploy-checks-hardening-batch` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-05, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): the File Change Matrix is entirely internal `pmo-platform` artifacts, so no external body of practice is consumed and no Form-A citation exists to record. Dominant domain `software` — 7 of the 8 members are shell implementation inside `core/deploy/deploy.sh`. Secondary domain `governance` — #6222's corpus token surface plus `core/standards/depersonalization-spec.md`. Dominant is recorded in the label, secondary noted here, per the A3-time classification rule. Transcribed unchanged from Stage-4 Phase A1.5; no Mode B → Mode A upgrade applies, because no external source is consumed at all.

---

## Commit-0 Version Re-Verify Record

The first Engineering spoke under SINGLE topology re-runs the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1** — refresh authoritative host state | **EXECUTED.** `origin/main` = `18e3e787fe56efeab50a8f96660cffaa322e9d6c`. The Stage-4 baseline pin was `18e3e787`; **the substrate did not move between Planning and Engineering** — zero commits landed on `main` in the interval, so the plan's pin and the Commit-0 base are the same commit. | `git fetch --tags origin`; `git fetch origin main`; `git rev-parse origin/main` |
| **2** — recompute next-free for bump-class `minor` | **EXECUTED. Next-free = `v4.57`.** `anchor()` = **v4.56**, the highest claimed version across all three `claimed_set()` arms. `FLOOR(minor)` = `(4, 57)`; `v4.57` is absent from `claimed_set()`, so the walk terminates at the floor. | Reproduced independently across the three arms: **origin tags** — `git tag -l 'v4.5*'` = `{v4.50 … v4.56}` over 200 `v*` refs, and `git tag -l 'v4.57'` returns empty; **published Releases** — `gh release list` latest = `v4.56`; **ledger** — `git show origin/main:release/releases/RELEASE_LOG.md` highest row `v4.56 \| kit-content-and-defaults \| … \| VERIFIED \| 2026-09-05`, and `RELEASE_INDEX.md` top row `v4.56`. `.version` at `origin/main` reads `v4.56`. |
| **3** — PROCEED / HALT on claimed-set membership | **PROCEED.** The planned version `v4.57` is **not** in the claimed set **and** equals the recomputed next-free, which is the conjunction the gate requires. No colliding tag and no colliding ledger row exists. | Sensitivity arm — the identical readers resolve `v4.56` as **present** on all three arms (tag ref exists; `gh release list` names it; the ledger carries a `VERIFIED` row), so membership detection demonstrably fires. Specificity arm — `v4.57` returns **0** occurrences in `RELEASE_LOG.md`, **0** in `RELEASE_INDEX.md`, and no `refs/tags/v4.57` exists, on the same non-empty inputs the sensitivity arm just resolved. |
| **3b** — stamp-manifest assertion | **EXECUTED post-write, pre-commit.** `release/tools/claim-version.sh --verify-stamp deploy-checks-hardening-batch` → **exit 0**. | Read-only and network-free — the identical pre-flight the Stage-12 atomic claim runs. The Header `**Version**` cell carries the literal unresolved `{{RELEASE_VERSION}}` token and no other text, which is what the Stage-12 claim resolves and renames on. |

**Why the number is recorded but not bound.** Step 2's `v4.57` is a Commit-0 *reading* of authoritative state, not a claim. Nothing is held between now and the merge; a concurrent release that merges first takes `v4.57` and this release's claim recomputes upward at the compare-and-swap. Recording the reading makes the Commit-0 PROCEED reproducible without asserting a reservation the allocation rule does not create. The v4.56 release is the worked example of why the distinction matters: its Stage-4 reading was correct when taken and stale fourteen hours later. **The numbers in this section are deliberately not restamped later** — they are a reading at a named SHA, reproducible by re-running the recorded commands at that SHA.

**`${AUDIT_DATE_UTC}` resolution.** Resolved once at this commit via `date -u +%Y-%m-%d` → **`2026-09-06`**. Its single consumer is #6419's pre-repair backup filename `<segment>.pre-repair-2026-09-06`. No other artifact in this release hardcodes a date in a load-bearing position. (Local civil date at resolution time was 2026-09-05 Saturday; the UTC anchor is the one the tool uses, and the divergence is named rather than silently reconciled.)

---

## Scope

### Issues Included

Eight members. #6222 was **retained** at the Stage-4 gate (**D-1**) rather than split out as the Stage-4 plan recommended; the milestone stays at 8 members and the size override stands.

| # | Issue | Title (abbreviated) | Priority | Size | Category |
|---|-------|------|----------|------|----------|
| 1 | #6419 | 659 rows in the deploy-check warn-log family are invalid JSON — a raw TAB in `detail` makes them invisible to any parsing drain | P3 | M | bug-adjacent |
| 2 | #6742 | `flag_advisory_only`'s authority pointer belongs to one check and is emitted for all of them | P3 | M | bug-adjacent |
| 3 | #6222 | Unregistered `<OPERATOR_INSTANCE_*>` tokens across the corpus | P3 | L | governance |
| 4 | #6214 | Check-72 carries `c71`-prefixed identifiers left behind by a check-number collision | P3 | XS | hygiene |
| 5 | #6165 | Check 16's report path does not honour the scoping its check path applies | P3 | M | bug |
| 6 | #5651 | Hook source/deployed parity is unchecked | P3 | S | gap |
| 7 | #5564 | `detect_changed_skills()` reports a stateless tag-diff as the deployed set | P3 | M | bug |
| 8 | #6213 | A stale ADR citation in the `_g1_03_evaluate` preamble | P3 | XS | hygiene |

### Exclusions

None. The Stage-4 plan recommended splitting #6222 into its own release on two independent grounds; the operator rendered **D-1 — Retain #6222, route it operator-executed**, so no member is excluded from this bundle. The exclusion class was enumerated over the eight members and the three Stage-4 recommendations that would have removed one; none is adopted.

### Dependency Graph

**Zero native dependency edges.** Probe: `blocked_by` / `blocking` / `sub_issues` over all 8 members → **0 / 0 / 0** each; denominator 8 of 8 queried. Sensitivity arm: the identical `sub_issues` endpoint on #6428 returns **30**, so the endpoint returns real edges and the eight zeros are true zeros.

The graph is therefore an **antichain** — no build-ordering constraint arises from dependency. All sequencing is driven by **file contention**, not dependency.

```
#6222   #5564   #5651   #6165   #6213   #6214   #6419   #6742
  |       |       |       |       |       |       |       |
  +-------+-------+-------+---- (no edges) ------+-------+
```

#### Artifact Relationship Graph

No typed artifact relationships between issues — the bundle has no native and no body dependency edge. Two file-level GENERATES edges arise from the File Change Matrix's `add` rows:

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #6419 | GENERATES | `core/deploy/tools/repair-warn-log-escapes.py` | #6419 → file | File Change Matrix (add) |
| #6419 | GENERATES | `core/deploy/tests/test_warn_log_json_escape.sh` | #6419 → file | File Change Matrix (add) |

#### Cross-Milestone Dependency Validation

**Suppressed — the bundle carries zero dependency edges of any type, so no cross-milestone check is possible.** Enumerated over `blocked_by`, `blocking`, `sub_issues` and body-declared `Dependencies:` prose across all 8 members; none yields an edge.

### Bundle Refresh State

N/A — enumerated over the four refresh triggers (T1 new-Approved inflow, T2 priority shift, T3 dependency-state change, T4 Stage-4 boundary). Gate G-BR fired only as T4 (the Stage-4 boundary itself), which is the no-op path; no T1/T2/T3 signal was detected between Bundle and Stage 4.

---

## Implementation Sequence

Contention-ordered, shared-substrate-first. **Principle:** the member that *reduces* the shared surface goes first, so every later member edits a smaller, single-definition substrate.

**Ratified sequence (8 members, #6222 retained at position 3 per D-1):**

`#6419 → #6742 → #6222 → #6214 → #6165 → #5651 → #5564 → #6213`

| # | Card | Why here |
|---|---|---|
| 1 | **#6419** | Extract **one** shared JSON-escape helper, replacing **9** duplicated escape pairs. Strictly reduces the surface every later member touches. Substrate-establishing. |
| 2 | **#6742** | Rewrite `flag_advisory_only`'s contract plus its **16** call sites across **9** check-id families. Lands on the escape helper #6419 just created rather than on nine copies. |
| 3 | **#6222** | Inserted here per D-1 — after #6742 settles its Check-44 call site at L12021 and before the remaining members. Carries an `operator-executed` limb and a `sanctioned-session` limb that no Engineering spoke can discharge (see § Agent-Editability Read). |
| 4 | **#6214** | Check-72 locals rename (**25** occurrences / **6** stems — corrected from the card's 14/3). Includes L14842, which step 2 rewrote; doing it after avoids a double-touch on one line. |
| 5 | **#6165** | Check 16 report-path parity. Its own emitter's escape pair is already the shared helper by now. |
| 6 | **#5651** | New **Check 79** hook-parity (next-free; gaps at 15 and 24 are retired, not reusable). Additive — appended at the end of the check list, minimal line-shift under others. |
| 7 | **#5564** | `detect_changed_skills` honesty. Isolated region (L4692 / L5177 / L5648); no contention with 1–6. |
| 8 | **#6213** | One comment line at L5769. Last — zero rebase risk, and its AC #2 sweep reads a file that has stopped moving. |

The milestone's originally-recorded sequence (`#6222 → #5564 → #5651 → #6165 → #6213 → #6214`) predates the #6419/#6742 inflow and models contention as *same-file*; it does not account for the line-level contentions below and is superseded.

### Issue #6419 — the warn-log JSON-escape defect

**Change specification** (from the Stage-5 design on #7137, which supersedes the Stage-4 outline where they differ):

- **Files modified:** `core/deploy/deploy.sh` · `core/config/allowlists/script-execution-allowlist.txt` · `.github/workflows/install-tests.yml`
- **Files added:** `core/deploy/tools/repair-warn-log-escapes.py` · `core/deploy/tests/test_warn_log_json_escape.sh`
- **Change description:** Extract **one** `json_escape_detail()` into `deploy.sh`'s existing warn-log helper block — an **extend** of that block, not a net-new surface. Full-C0 correct per RFC 8259 §7 behind a `[[:cntrl:]]` short-circuit, pure bash-3.2 parameter expansion, backslash substituted first, setting a global rather than echoing so no emitter forks a subshell. Convert all **9** free-text escape sites, keeping every `printf` emit line byte-identical so the C1/C3/C4 hunks stay minimal. Ship a stdlib-only recovery tool with tail-preserving concurrent-append safety, `--dry-run` by default and `os.replace()` atomicity.
- **Estimated complexity:** Medium
- **Dependencies:** None — first in the sequence.

### Issues #6742 · #6222 · #6214 · #6165 · #5651 · #5564 · #6213

Each card's change specification is carried by its own Stage-5 design comment (for the six cards that activated Stage 5) or by its issue body (for #6213 and #6214, whose Stage-5 applicability is SKIP). The Stage-4 write-set determination for each is transcribed into § File Change Matrix and § Agent-Editability Read below; the per-card design detail is not restated here, because the Stage-5 output is the authoritative design surface and a second copy in this file would rot independently of it.

---

## Stage Applicability Matrix

| Card | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9–S13 | Stage-5 rationale |
|---|---|---|---|---|---|---|
| #6419 | **APPLY** | APPLY | APPLY | APPLY | APPLY | Two-part remedy (writer fix + recovery pass over ~110 MB of live out-of-tree data) with a conservation requirement |
| #6742 | **APPLY** | APPLY | APPLY | APPLY | APPLY | Card states the obvious fix is insufficient and names two competing shapes — a D-class decision by construction |
| #6222 | **APPLY** | APPLY | APPLY | APPLY | APPLY | 18-token per-token triage = 18 dispositions; card explicitly says "per-token triage, not a bulk registration pass" |
| #6214 | **SKIP** | APPLY | APPLY | APPLY | APPLY | Mechanical rename — but AC #4 requires running `deploy.sh --check` and asserting Check 72 still emits, which is functional verification |
| #6165 | **APPLY** (light) | APPLY | APPLY | APPLY | APPLY | Card offers two remedy shapes (shared definition vs parity assertion) and requires the chosen one be shown able to fail |
| #5651 | **APPLY** | APPLY | APPLY | APPLY | APPLY | Card names an undecided question (whether hooks should be deploy-published is decided separately and recorded); plus scope, source-path map, operator-state exclusion |
| #5564 | **APPLY** | APPLY | APPLY | APPLY | APPLY | Fix must not regress the `EX_NOCHANGE(64)` contract that L5185-5195 documents as a prior fixed regression — a real design constraint |
| #6213 | **SKIP** | APPLY | **SKIP** | APPLY | APPLY | One comment line; no functional impact. AC #2's sweep is graded at S8, not exercised at S7 |

**6 of 8 activate Stage 5.** That is itself evidence against `routine`: the class's SKIP-where-trivial bias presumes met-by-letter-only triggers, and six cards carry genuine design uncertainty.

**Parallel-eligible counts** (feeding the Quota Budget): Stage 5 → **6** · Stage 7 → **7** · Stage 8 → **8**.

---

## File Change Matrix

Machine-readable, one path per line, `<path>  <VERB>` (path-first columnar-in-fence form). Intent markers normalize to the `add | edit | delete` enum.

```
# ── #6419 · warn-log JSON-escape correctness (sequence position 1) ──
core/deploy/deploy.sh                                                      edit
core/deploy/tools/repair-warn-log-escapes.py                               add
core/deploy/tests/test_warn_log_json_escape.sh                             add
core/config/allowlists/script-execution-allowlist.txt                      edit
.github/workflows/install-tests.yml                                        edit

# ── #6742 · flag_advisory_only contract + call sites (position 2) ──
core/deploy/deploy.sh                                                      edit

# ── #6222 · unregistered OPERATOR_INSTANCE token registration (position 3) ──
core/governance/OPERATIONS.md                                              edit
release/governance/RELEASE_PROTOCOL.md                                     edit
core/skills/pmo-qa-auditor/SKILL.md                                        edit
operations/skills/health-check/SKILL.md                                    edit
release/skills/release-executor/SKILL.md                                   edit
release/skills/release-planner/SKILL.md                                    edit
core/config/operator.toml.template                                         edit
core/config/operator-toml-schema.json                                      edit
core/standards/depersonalization-spec.md                                   edit
core/deploy/deploy.sh                                                      edit

# ── #6214 · Check-72 c71 identifier residue (position 4) ──
core/deploy/deploy.sh                                                      edit

# ── #6165 · Check 16 report-path parity (position 5) ──
core/deploy/deploy.sh                                                      edit

# ── #5651 · hook source/deployed parity check (position 6) ──
core/deploy/deploy.sh                                                      edit
core/hooks/block-destructive.sh                                            edit

# ── #5564 · detect_changed_skills honesty (position 7) ──
core/deploy/deploy.sh                                                      edit

# ── #6213 · stale ADR citation (position 8) ──
core/deploy/deploy.sh                                                      edit

# ── release-scoped ──
release/releases/plans/deploy-checks-hardening-batch_RELEASE_PLAN.md       add
```

**19 declared path×card write obligations over 15 distinct paths.** `core/deploy/deploy.sh` appears once per writing card and is written by all eight; § Contention Map carries the ordering.

### CONDITIONAL rows

```
core/<triaged-token-reference-site>                                        edit    CONDITIONAL:token-triage-resolves
```

**Condition token: `token-triage-resolves`.** #6222's AC #2 triages each of the 18 unregistered `<OPERATOR_INSTANCE_*>` tokens to one of three dispositions — `register` (edits the registry only), `correct-to-existing` (edits that token's reference sites), or `exclude-as-illustrative` (edits the checker). Only the `correct-to-existing` disposition produces reference-site edits, and **the per-token triage has not been run**, so the concrete path set is undetermined at plan time. The hub's Stage-4 R1 correction establishes the bound: the reference surface is **91 tracked files carrying ~341 references**, but the *write set* is the registry plus the checker plus the files carrying named typo variants — **roughly 10–11 files**, of which the ten unconditional `#6222` rows above are the determined members. **Per the FCM authoring contract, this row is promoted into the unconditional set in the commit in which its condition resolves**, carrying its now-concrete paths; a row left CONDITIONAL after triage has run is an authoring defect.

### Read-only inputs

```
core/standards/gate-efficacy-standard.md                                   READ
core/schemas/gate-criteria-spec.md                                         READ
core/rules/harness-deployment.md                                           READ
core/deploy/lib-instance-path.sh                                           READ
release/tools/blast-radius.sh                                              READ
core/deploy/tools/check-adr-flip.py                                        READ
```

### Release-wide explicit non-scope

```
core/hooks/verify-session-config.sh                                        NOT EDITED
core/deploy/tools/check-pv7-vocabulary.sh                                  NOT EDITED
core/hooks/block-autonomy-ceiling.sh                                       NOT EDITED
core/hooks/block-skill-direct-edit.sh                                      NOT EDITED
```

The non-scope block is **explicit and load-bearing, not hygiene.** `core/hooks/verify-session-config.sh` emits a JSON `detail` field by `printf` with **no escaping of any kind** at two sites — the enforce path near L244 and the warn path at L247. That is the **same defect class as #6419 on a different sink** (`verify-session-warn-log.jsonl`), and it is deliberately routed to a later release rather than folded in: it is a different file, a different writer path, and outside every member's declared write set. Declaring it out of scope is what makes the boundary falsifiable — a diff touching it is a scope violation, not a judgement call. `core/hooks/block-autonomy-ceiling.sh` and `core/hooks/block-skill-direct-edit.sh` are **read** by the Agent-Editability Read and are never written by it; #5651 writes `core/hooks/block-destructive.sh` only.

### New-executable companion obligations

Two `add` rows name tracked executables, so both carry the companion obligations the Stage-4 authoring contract requires:

| New executable | Allowlist companion | CI wiring |
|---|---|---|
| `core/deploy/tests/test_warn_log_json_escape.sh` | **Required** — four entries in `core/config/allowlists/script-execution-allowlist.txt`, matching the shipped four-form pattern (`[PMO_PLATFORM_ROOT]/…`, `[PMO_PLATFORM_ROOT]/.claude/worktrees/*/…`, `./…`, bare repo-relative) | **`.github/workflows/install-tests.yml`** — an explicit `run: bash core/deploy/tests/test_warn_log_json_escape.sh` step, matching the shipped convention for every other test in that directory |
| `core/deploy/tools/repair-warn-log-escapes.py` | **Not required** — enumerated rather than assumed: `core/deploy/tools/` carries 53 allowlist rows today, and the tool is an operator-run one-off over out-of-tree data, not a platform-invoked script. If a later stage wires it into any `bash`/`python3` invocation path, the companion rows ship in that same change | **Not CI-executed** — stated explicitly rather than left open. Its `--self-test` mode is runnable by hand and by a later CI step; no workflow step is added in this release |

---

## Agent-Editability Read

**Derivation** — controls read at commit `18e3e787`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — **4** `case "$ABS_TARGET"` blocks observed; **2** invoke `always_block "BLOCK-AUTONOMY-001"`. Arms quoted verbatim:
  - *Anchored block (L703–719):* `"${PRIMARY_ROOT}/CLAUDE.md"` · `"${PRIMARY_ROOT}/projects/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/.claude/settings.json"` · `"${PRIMARY_ROOT}/.claude/hooks/"*` · `"${PRIMARY_ROOT}/.claude/rules/"*`
  - *Membership block (L734–742), worktree-guarded and anchor-free — the operative arm for in-repo work:* `*/CLAUDE.md` · `*/OPERATIONS.md` · `*/RELEASE_PROTOCOL.md`, guarded by `is_platform_worktree`
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`; arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`; exemption list resolved at the **deployed** path `~/Claude/.claude/skill-editor-exemption-list.txt` — **present (1 entry)**.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #6222 | `core/governance/OPERATIONS.md` | **yes** (membership arm `*/OPERATIONS.md`) | — | `tier-0-floored` | **`tier-0-floored`** | **operator-executed** |
| #6222 | `release/governance/RELEASE_PROTOCOL.md` | **yes** (`*/RELEASE_PROTOCOL.md`) | — | `tier-0-floored` | ″ | **operator-executed** |
| #6222 | `core/skills/pmo-qa-auditor/SKILL.md` | no | **all 3 conjuncts true** | `sanctioned-session-required` | ″ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6222 | `operations/skills/health-check/SKILL.md` | no | all 3 true | `sanctioned-session-required` | ″ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6222 | `release/skills/release-executor/SKILL.md` | no | all 3 true | `sanctioned-session-required` | ″ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6222 | `release/skills/release-planner/SKILL.md` | no | all 3 true | `sanctioned-session-required` | ″ | `sanctioned-session: pmo-skill-editor Mode A` |
| #6222 | `core/config/operator.toml.template` · `core/config/operator-toml-schema.json` · `core/standards/depersonalization-spec.md` · `core/deploy/deploy.sh` · the triaged corpus reference sites | no | no | `unconstrained` | ″ | ordinary Engineering spoke |
| #5651 | `core/deploy/deploy.sh` · `core/hooks/block-destructive.sh` (source) | no | no | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #5651 | *(deployed hook copy under `~/Claude/.claude/hooks/`)* | **yes** (anchored arm `${PRIMARY_ROOT}/.claude/hooks/*`) | — | `tier-0-floored` | — | **not a write target** — reconcile by fixing source + `./deploy.sh`, never by writing the deployed copy |
| #5564 · #6165 · #6213 · #6214 · #6419 · #6742 | `core/deploy/deploy.sh` | no | no | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6419 | `core/deploy/tools/repair-warn-log-escapes.py` · `core/deploy/tests/test_warn_log_json_escape.sh` · `core/config/allowlists/script-execution-allowlist.txt` · `.github/workflows/install-tests.yml` | no | no | `unconstrained` | `unconstrained` | ordinary Engineering spoke |

**Conjunct discrimination recorded.** Skill-gate: conjunct 1 (scope regex) decided *inclusion* for the 4 SKILL.md paths; conjunct 2 (arming key) was **true** for all 4 — control arm: 52 of 57 tracked `SKILL.md` carry the key, so the probe discriminates rather than matching everything; conjunct 3 (absent from exemption list) **true** for all 4 — the list resolved and is non-empty, so this is `absent`, not `undetermined`. Tier-0: the membership predicate returns **3** matches over all 2,006 tracked files and **2** over #6222's carrier set — a discriminating read, since it excluded `operations/OPERATIONS.md`, which carries no unregistered token.

**Per-path rows are retained, never collapsed into the card class.** #6222's card class is the most-constrained of its paths. Per **D-1** the operator retained the card and routed it **operator-executed**; the Engineering spoke for position 3 discharges only the `unconstrained` limb, and the `tier-0-floored` and `sanctioned-session-required` limbs are executed on their own paths. **Editability class for #6419's sub-task (#7138): `unconstrained`** — no write-set path matches either the anchored or the membership Tier-0 arm, and none matches `SKILL_SCOPE_RE`.

---

## Contention Map

The milestone models contention as *same file*. At line level there are **three surviving hard contentions** and two soft ones; C2 dissolved at Stage 5.

| ID | Members | Site | Class | Status |
|---|---|---|---|---|
| **C1** | #6419 × #6742 | `flag_advisory_only()` **L6750–6759** | **HARD — same hunk** | **LIVE.** #6742 rewrites L6753 (the suffix) and L6758 (the emit); #6419 rewrites L6756–6757 (the escape pair). Ten-line function; one diff hunk at any default context. **Mitigated by design, not merely by sequencing** — #6419's call form keeps each site at exactly two lines and leaves every `printf` emit line byte-identical, so neither of #6742's two target lines is touched. |
| **C2** | #6419 × #6165 | `flag_status_label()` **L7721–7737** | **DISSOLVED** | **DISSOLVED at Stage 5.** #6165's chosen design does not touch `flag_status_label()`, so the two cards no longer share a hunk. #6419 still converts the escape pair at L7732–7733; it is now a single-owner edit. Recorded rather than deleted, because the Stage-4 map carried it as HARD and a reader comparing the two surfaces must be able to see why it went away. |
| **C3** | #6742 × #6222 | **L12021**, inside Check 44 | **HARD — same line** | **LIVE.** `flag_advisory_only "depersonalization-token" …` — #6742 changes the call signature; #6222 changes Check 44's body and population. L12020 also hardcodes `c44_owned="<OPERATOR_INSTANCE_RELEASE_LOG_PATH>"` as *"the one un-codified token that has a tracked owner"*; the census shows **18** un-codified tokens, so #6222 must revisit that line too. |
| **C4** | #6742 × #6214 | **L14842**, inside Check 72 | **HARD — same line** | **LIVE.** `flag_advisory_only "issue-body-anchor-drift" "$_c71_hit"` — #6742 rewrites the call; #6214 renames `_c71_hit`. One line, two owners. |
| **C5** | #5651 × all | Check-number allocation → **79** | SOFT | Live. 76 distinct live check numbers, max 78; gaps at 15 (documented retired) and 24 are **not reusable**. A concurrent release claiming 79 reproduces exactly the collision that created #6214. Re-verify next-free at position 6. |
| **C6** | #6419 × #5564 | `flag_not_evaluated()` L5845 vs summary L5648 | SOFT | Live. ~200 lines apart, no hunk overlap. Sequencing-free. |
| **C7** | #6419 × #6742 (new) | **L13346–13347**, Check 56 M4 `milestone-subtask-orphan` | **SOFT — newly noted** | Converting the ninth escape site touches a block no Stage-4 contention row covers. The Stage-5 sweep confirms **no sibling in this milestone declares that block**, so this is a single-owner edit recorded for completeness rather than a contention to sequence around. |

**#6419's true remediation surface — nine escape-pair sites, not eight.** The Stage-4 enumeration listed eight and mis-assigned the ninth into the integer-built group. Corrected:

```
L5845   flag_not_evaluated()                        _detail_escaped
L6261   flag_registry_field()                       _frf_esc          <- omitted from the Stage-4 pair list
L6725   flag_warn_or_issue()                        _detail_escaped   <- produces all 659 live malformed rows
L6756   flag_advisory_only()                        _detail_escaped   <- C1
L6881   check-scoped emitter                        _detail_escaped
L6911   check-scoped emitter                        _detail_escaped
L6932   recommend-level emitter                     _detail_escaped
L7732   flag_status_label()                         _detail_escaped   <- C2 (dissolved)
L13346  Check 56 M4 milestone-subtask-orphan        _c56_m4_esc       <- absent from the Stage-4 enumeration entirely
```

**The 12-vs-9-vs-3 reconciliation.** `deploy.sh:339` asserts "all 12 append sites". That total is correct and unchanged. The split is **9 free-text + 3 integer-built**, not the 8 + 4 the Stage-4 plan derived: nine sites interpolate a free-text `detail` through `"%s"` (emit lines L5848, 6263, 6727, 6758, 6883, 6913, 6934, 7734, 13348) and three build `detail` from integers only (L10760 `close-completeness`, L13631 `decision-emission`, L13684 `register-runner-resolution`). The Stage-4 split preserved the total while mis-assigning one member.

**#6742's call-site baseline is 16 sites / 9 check-id families**, not the 13 / 8 the Stage-4 plan recorded. Re-measured by the hub at `18e3e787`.

**Cross-PR contention:** none. In-flight sibling population **n = 0** at the pinned baseline. Probe: open PRs with a `release/*` head → **0**; remote `release/*` heads → **0**; total open PRs → **0** (unfiltered denominator). Sensitivity arm: the identical head predicate over **closed** PRs returns **15**, so the predicate matches real release heads and the open-state zero is a true empty population, not a broken filter.

**Structural blast radius (Tier-S):** no mover-set — no member declares a rename, relocate, or delete. `SURFACE(R)` is empty, so no sibling can intersect it. The version-slot token is unbound (slug-primary, pre-claim) and no sibling contends for a slot.

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| **R-1** | **#6214's AC #1 grades PASS on an incomplete fix.** `\bc71_` misses `_c71_hit` / `_c71_row` / `_c71_seen` — 11 occurrences, all inside the Check-72 block. A rename of the 3 bare stems alone satisfies the AC while leaving the hazard | High | High | **DISCHARGED at the Collective Review scope-lock.** AC #1's pattern widened to `c71_[A-Za-z0-9_]+`; AC #2 re-baselined to 152 occurrences / 18 names; AC #3 re-baselined to 25 renamed occurrences / 6 stems | Stage 6 spoke for #6214 |
| **R-2** | **#6222 cannot complete in an ordinary Engineering spoke** — 2 Tier-0-floored paths, 4 sanctioned-session paths | High | High | **D-1 rendered: retain and route operator-executed.** The `unconstrained` limb is spoke-executable; the other two limbs execute on their own paths before the release PR opens | Operator |
| **R-3** | **#5564's fix regresses the `EX_NOCHANGE(64)` contract.** L5185–5195 documents that reporting the raw tag-diff list as "Deployed: N skills" was itself a fixed regression; `update.sh` keys off that field | Med | High | Treat the prior-regression contract as a design constraint; the card's own control arm — a genuine no-op deploy still succeeds — is exactly the regression test. Make it executable. **Constraint added at Collective Review:** a bare `diff -rq` predicate flags 12 of 55 roster skills on a fully-current instance, all injection artifacts; Check 1's `TEMPLATE_SYNC_MAP` exclusion is mandatory | Stage 6 spoke for #5564 |
| **R-4** | **C1/C3/C4 rebase churn.** #6742 touches 16 call sites, of which 2 are inside blocks other members own | Med | Med | Follow the ratified sequence; one PR on one branch, serial (posture P0) | Hub |
| **R-5** | **#5651's parity check fails red on landing** — `block-destructive.sh` already diverges (source `ecd25742b2a1` vs deployed `fc03f71a0dce`). The card names this itself | Med | Med | Land warn-mode initial, or reconcile first. The deployed copy is Tier-0-floored: reconcile by fixing source and re-deploying, never by writing the deployed copy | Stage 6 spoke for #5651 |
| **R-6** | **#5651's scope is larger than the card models.** Full tree: 74 source files vs 45 deployed; 16 deployed-only, of which **14 are operator runtime state** and **2 are `.sh` deployed from elsewhere** (`lib-instance-path.sh` ← `core/deploy/`, `path-leak-patterns.sh` ← `core/deploy/tools/`) | Med | Med | The check needs a **source-path map**, not a same-basename walk, plus an operator-state exclusion class. `core/rules/harness-deployment.md` § Operator-State Preservation Policy already models this shape — reuse it rather than re-deriving | Stage 6 spoke for #5651 |
| **R-7** | **#6419's recovery pass touches ~110 MB of live out-of-tree operator data**, and a botched repair loses evidence | Med | **High — EXPENSIVE reversibility** | Three mitigations, **all required**: (i) `--dry-run` is the default and `--apply` is opt-in; (ii) a pre-repair copy `<segment>.pre-repair-2026-09-06` is written before any replacement; (iii) the tool writes a new file and finishes with `os.replace()`, so the original is never mutated in place and a crash mid-run leaves the source untouched. A fourth is added at Stage 5: **tail-preserving concurrent-append safety** — without it a concurrent `deploy.sh --check` silently destroys rows | Stage 6 spoke for #6419 |
| **R-8** | **#6419's magnitude is growing** — +215 malformed rows and +37,730 total rows in six days. A repair pinned to the card's 444 figure under-repairs | Med | Low | Re-measure at repair time; assert **0 malformed** rather than "444 repaired". The card's title and body are left unamended as historical record | Stage 6 spoke for #6419 |
| **R-9** | **Check-number 79 collision** with a concurrent release. This is precisely the shape that produced #6214 | Low | Med | Allocate 79 late (sequence position 6) and re-verify next-free at Engineering. Gaps at 15/24 are retired — do not reuse | Stage 6 spoke for #5651 |
| **R-10** | **Milestone lacks a Parallelization Map** on a post-adoption milestone | Low | Low | Tier 1 [ADJUST] — append a map recording the empty sibling population (n=0) against baseline `18e3e787`. Content would be empty either way; a one-line map is the remedy, not a re-scan | Hub |
| **R-11** | **Bundle is 3 pts over the 15–25 ceiling** under a recorded override whose stated rationale (single-file coherence) is falsified by #6222's measured surface | Med | Low | **Accepted at D-1** — #6222 retained, override stands. **AI-006** carries the residual: the override *decision* stands, its *stated ground* does not, and the rationale is to be reconciled | Operator |
| **R-12** | **`verify-session-config.sh`'s unescaped `detail` remains latent** — same defect class as #6419, different sink | Low | Low | Explicitly out of scope (§ Release-wide explicit non-scope). Routed to a later release. Noted, not fixed — folding it in would widen the write set past the Tier-0-adjacent hooks surface for no defect-closure in this bundle | Next release |

---

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (contention-ordered), posture **P0 fully-serial** |
| **Commit strategy** | One or more commits per issue, pushed as each coherent slice lands — never one terminal push |
| **Review approach** | **Single PR for the entire release**, opened once the last card lands |
| **Deployment mechanism** | Git merge. #5651's hook reconciliation additionally propagates through `./deploy.sh --deploy` to the runtime; no `.skill` rebuild is implied by any member's write set as declared |
| **Stacked-base cleanup posture** | N/A — no stacked-base waves are planned; single branch, single base |

---

## Verification Plan

### Per-Issue Verification

`ac_baseline: { #6419: 4, #6742: 5, #6222: 6, #6214: 4, #6165: 3, #5651: 4, #5564: 3, #6213: 2, read_at: 18e3e787 }`

Only #6419's rows are populated here at Commit 0; every other card's rows are populated by that card's Engineering spoke from its own Stage-5 design and its scope-locked criteria. A criterion this release deliberately will not verify still carries its row with the method cell reading `[DEFERRED — <reason>]`.

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6419 | AC-1 | `grep -c json_escape_detail core/deploy/tests/test_warn_log_json_escape.sh` — expect at least 2 (the subject arm and the control arm). The **behavioral** method the criterion actually grades is `bash core/deploy/tests/test_warn_log_json_escape.sh`, which drives a `detail` carrying a raw TAB through the shipped append path, parses the emitted row back with `python3` and asserts the decoded `detail` equals the input exactly; the executable row above asserts the graded artifact exists and drives the shipped helper, because this executor tokenizes without a shell and cannot grade a test-run outcome | Row parses as valid JSON and round-trips exactly · **control arm:** the same test reproduces the pre-fix two-substitution pair on the same input and asserts the row **fails** to parse → observed non-zero failure, so a passing test proves the fix rather than the harness |
| #6419 | AC-2 | `grep -c warn_log_segment_set core/deploy/tools/repair-warn-log-escapes.py` — expect at least 1, asserting the tool resolves the family in segment-set order rather than opening the hot file alone. The **behavioral** method is `python3 core/deploy/tools/repair-warn-log-escapes.py --verify`, run over the live out-of-tree family under the resolved instance path | **0** malformed rows · **sensitivity arm:** seed one malformed record into a copy and observe it detected → observed ≥1, so the zero is a measurement and not an unresolvable-pattern zero |
| #6419 | AC-3 | `grep -c UNREPAIRABLE core/deploy/tools/repair-warn-log-escapes.py` — expect at least 1, asserting the unrepairable counter the conservation assertion reads exists. The **behavioral** method is the tool's own pre-replacement assertion set, run under `--dry-run` and again under `--apply`: output line count **equals** input line count exactly; every previously-valid line byte-identical; every repaired line's decoded `detail` equal to the original raw `detail` byte-for-byte; `UNREPAIRABLE == 0` | Row count **UNCHANGED** (not risen) and every row content-round-trips · **control:** drop one line from a copy and observe the count assertion fail → observed failure, so the probe can detect a loss. *Corrected at Stage 5 from "the count must rise by exactly the number repaired", which is unsatisfiable — 0 fragment-starts and 0 fragment-ends over 444,273 rows* |
| #6419 | AC-4 | `grep -c json_escape_detail core/deploy/deploy.sh` — expect at least 10, being one definition plus nine call sites. The full criterion is graded by the **name- and keyword-agnostic FOUR-term** instrument recorded verbatim in the release-scoped cross-issue criteria below, which keys on neither the `local` keyword nor any variable name. **Control arm:** `grep -c zzq_not_a_helper core/deploy/deploy.sh` must return 0 on the same non-empty file | **`1 1 9 0`** from the four-term instrument — and the **fourth term is the one that grades completeness**. **Null-arm control:** the same instrument on the reconstructed pre-fix source returns **`9 0 0 9`**, so it demonstrably counts these constructs and a post-fix reading is a measurement · *the first term is **1**, not the 0 Stage 5 predicted, for a structural reason: the surviving definition necessarily contains the idiom it replaced. See DEV-10.* |

### Release-Level Verification

- [ ] File Integrity — every declared unconditional `add` present at its declared path on the release branch
- [ ] Content Correctness — `./deploy.sh --check` exit status unchanged in both default and `--strict` mode
- [ ] Cross-Reference Validity — `python3 core/deploy/tools/check-doc-links.py` over the governed scan scope
- [ ] Skill Invocation — N/A, enumerated: no member's write set names a `skills/` path other than #6222's four `SKILL.md` sanctioned-session limbs, which are graded by their own execution path
- [ ] Output Contract Compliance — the four Cross-Issue Acceptance Criteria below, graded at Stage 9 QC3.5 on the merged PR

---

## Cross-Issue Acceptance Criteria

Four release-scoped cohesion constraints. Each spans ≥2 issues with no dependency edge, and is graded on the merged PR at Stage 9 QC3.5 / Phase A3.6.

- [ ] **CIAC-1 (#6419 × #6742 on `core/deploy/deploy.sh` → `flag_advisory_only`):** after both land, every advisory row the helper emits is valid JSON **and** carries no authority pointer belonging to a different check. *Issues spanned:* #6419, #6742. *Shared surface:* the `flag_advisory_only` function body. *Method:* run `./deploy.sh --check`, then parse the warn log with `python3 -c "import json; rows=[json.loads(l) for l in open(WARN_LOG) if l.strip()]; adv=[r for r in rows if r.get('advisory')]; assert adv, 'EMPTY POPULATION'; print(len(adv))"` — non-empty extraction is asserted, not assumed. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#6419 × #6165 × #6742 on `core/deploy/deploy.sh` → the warn-log writer family):** exactly one JSON-escape definition exists in the file, and **all nine** former escape-pair sites route through it; no second copy survives at any call site. *Issues spanned:* #6419, #6165, #6742. *Shared surface:* the `detail`-escaping path shared by `flag_not_evaluated` / `flag_registry_field` / `flag_warn_or_issue` / `flag_advisory_only` / `flag_status_label`, the three check-scoped emitters, and Check 56's M4 block. *Method:* the four-term matcher shipped as `A7` in `core/deploy/tests/test_warn_log_json_escape.sh` — it counts, over `core/deploy/deploy.sh`, (i) every occurrence of the backslash-doubling escape idiom under a name-agnostic pattern, (ii) definitions of `json_escape_detail`, (iii) its call sites, and (iv) occurrences of (i) that lie **outside the definition's own body**, whose extent it derives by walking from the function header to its closing brace. Expect **`1 1 9 0`**, and **term (iv) is the one that grades completeness**. **Null-arm control (AC-Binding Limb 2):** the identical instrument over the reconstructed pre-fix source — arm `A8` of the same suite, which reverses the conversion on a copy — returns **`9 0 0 9`**, so the instrument demonstrably counts these constructs and a post-fix reading is a measurement rather than an unresolvable-pattern zero. A further arm, `A9`, asserts the retired `local _detail_escaped=` instrument reads only **7** of the 9 pre-fix sites, which is what makes the name-agnostic form load-bearing rather than stylistic. *Graded at Stage 9 QC3.5 on the merged PR.*

  > **Term (i) is 1 rather than 0, and the reason is structural rather than a residual.** The surviving definition necessarily contains the idiom it replaced — `json_escape_detail`'s own backslash substitution *is* the escape pair, written once. An instrument whose first term demanded 0 would be unsatisfiable by any implementation that keeps the escaping in bash, and Stage 5's predicted `0 1 9` did not account for it. Term (iv) is the corrected reading of the same intent: zero duplicated pairs **at call sites**, with the definition's own body excluded by construction rather than by a hand-maintained exception. See DEV-10.

  > **This criterion was CORRECTED at the Collective Review scope-lock, and the correction is load-bearing.** As authored at Stage 4 the method was `python3 -c "import re; n=len(re.findall(r'local _detail_escaped=', open('core/deploy/deploy.sh').read())); print(n)"` with a stated null-arm of **8**. Run verbatim at `18e3e787` that instrument returns **7**, not 8 — and it is **structurally blind** to two of the nine sites: `_frf_esc` at L6261 carries a different variable name, and `_c56_m4_esc` at L13346 is assigned without the `local` keyword. Under the original instrument a post-fix reading of **1** would grade **PASS with two sites unconverted** — the exact residual the criterion exists to close. The replacement keys on neither the keyword nor any variable name.

- [ ] **CIAC-3 (#6214 × #6742 on `core/deploy/deploy.sh` → the Check-72 block):** zero `c71`-prefixed identifiers remain at or after the Check-72 def-block header, **under the widened pattern**, and the block's `flag_advisory_only` call conforms to #6742's new contract. *Issues spanned:* #6214, #6742. *Shared surface:* line 14842 and the Check-72 region. *Method:* `python3 -c "import re; L=open('core/deploy/deploy.sh').read().split(chr(10)); h=[i for i,l in enumerate(L) if re.search(r'#\s*Check 72',l)][0]; print(sum(len(re.findall(r'c71_[A-Za-z0-9_]+',l)) for l in L[h:]))"` — expect **0**. **Null-arm control:** the identical invocation at baseline `18e3e787` returns **25**, and the same pattern before the header returns **152** post-fix (unchanged), so a zero after the header is discriminating rather than vacuous. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#6222 × #6742 on `core/deploy/deploy.sh` → Check 44):** Check 44's advisory emission names its own authority and its own enforce-capability posture, and its token inventory is derived from the registry rather than from the hardcoded single-token literal at L12020. *Issues spanned:* #6222, #6742. *Shared surface:* lines 12020–12021 inside the Check-44 block. *Method:* `grep -n 'c44_owned=\|flag_advisory_only "depersonalization-token"' core/deploy/deploy.sh` and read the two lines — assert no `G-CL9` literal and no single hardcoded `<OPERATOR_INSTANCE_*>` owner. **Null-arm control:** the same invocation at `18e3e787` returns **2** matching lines, so the reader resolves the construct. *Graded at Stage 9 QC3.5 on the merged PR.*

  > **The criterion above is IN FORCE.** As authored at Stage 4 it carried the condition *"applies only if #6222 stays in scope; if it is split out, this criterion is withdrawn with the card and the release declares three."* **D-1 retained #6222**, so the condition resolved in favour of the criterion and the release declares **four**. (The identifier is deliberately not repeated in bold at the head of this note: the plan's cross-issue criteria are parsed by locating a bold identifier at the start of a line, and a second bold occurrence would emit a phantom fifth criterion with no method.)

---

## Quota Budget

**Verdict:** **WARN** (per Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **6** · Stage 7: **7** · Stage 8: **8**
**Per-spoke cost estimate:** size-bucket ordinal band — 1 × `size:L` (moderate–high), 4 × `size:M` (low–moderate), 1 × `size:S` (lowest), 2 × `size:XS` (below the banded floor; treated as lowest). Source: heuristic — no telemetry medians available, and the cutover predicate is not met for any bucket.
**Assumed/stated remaining usage-window envelope:** **UNSTATED** — no operator quota state was captured at hub start; the conservative default applies, and `UNSTATED` sits deliberately tighter than `partial-N%`.
**Estimated cumulative draw % (worst parallel batch):** worst batch is **Stage 8 at 8 concurrent spokes**. Against a *fresh* window this lands in the **40–45 %** band (PASS); against any *partial* window — which `UNSTATED` must be assumed to be — it crosses **50 %**. The verdict is rendered on the conservative branch.
**Routing:** **WARN** → window-aware launch timing plus quota-budgeting recommended. Concretely: **split Stage 8 into two waves of 4**.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time. Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**Class: `novel`** — rendered by the operator at the Stage-4 gate as **D-2**, a re-classification from the milestone's declared `routine`.

| Class | Trigger | Fires? | Evidence |
|---|---|---|---|
| `routine` | (a) all issues P3/P4 **and** size:S/M | **NO** | #6222 is `size:L` and is retained |
| `routine` | (b) all change-spec files have ≥3 prior release touches | yes | `deploy.sh` is the most-touched file in the repo |
| `routine` | (c) zero new files added | **NO** | #6419 adds two files |
| `routine` | (d) zero new D-class decisions in the release plan | **NO** | ≥4: #6742's remedy shape, #5651's publish-or-declare, #6419's escape strategy + recovery design, #5564's detection semantics |
| `novel` | (a) ≥1 issue introduces a new reference doc, schema, or skill | likely | #6742's AC #5 requires the chosen contract be recorded where the other emitter contracts are documented; #5651 requires a recorded decision |
| `novel` | (b) **≥1 D-class decision in the release plan** | **YES** | the four above — the dominant trigger |
| `cross-cutting` | (a) ≥3 `pipeline/stage-*.md` files declared as changes | no | zero |
| `cross-cutting` | (b) ≥3 of the 6 rule-defining surfaces | no | **one** — `core/governance/OPERATIONS.md`. `deploy.sh` is not a member of that set |
| `cross-cutting` | (c) ≥3 in-bundle compositional edges | **no, on the letter** | dependency edges = **0**. The three surviving hard contentions are file-contention edges, not dependency edges. Named here because the distinction is the whole reason the class stays `novel` — a reader who sees "3 hard edges" and reaches for `cross-cutting` is reading the wrong axis |

**Multi-trigger resolution:** `routine` fails on (a), (c) and (d); `novel` (b) fires; `cross-cutting` fires on nothing. Highest-ceremony firing class = **`novel`**. The re-classification is cheaper-to-stricter: CHEAP reversibility, HIGH confidence — it adds ceremony, invalidates no downstream artifact, and can revert at the next gate.

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #6419 (repo limb) | `git revert` of the member's commits | Low — isolated to `core/deploy/deploy.sh` plus two new files |
| #6419 (data limb) | **Restore from `<segment>.pre-repair-2026-09-06`** | **High — NOT covered by any git operation** |
| #6742 · #6214 · #6165 · #5564 · #6213 | `git revert` of the member's commits | Low |
| #6222 | `git revert`; the operator-executed and sanctioned-session limbs revert on their own paths | Medium — multi-surface |
| #5651 | `git revert`, **then re-run `./deploy.sh --deploy`** | Medium — a revert of the merge does not un-deploy |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated member failure | Revert that member's commits on a fix branch |
| **Full Restore** | Systemic failure | `git revert -m 1 <merge-sha>` — the merge commit is two-parent by construction, so the whole-release revert is available |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch off `main` |

**Two limbs sit outside the git guarantee and are called out rather than implied:** (a) #6419's recovery pass mutates out-of-tree operator data and is **not** covered by a git revert — the pre-repair copy is the only restore path, which is why it is a required mitigation rather than a nicety; (b) #5651's hook reconciliation propagates through `./deploy.sh` to the runtime, so a revert of the merge does not un-deploy — re-run the deploy after any revert. Reversibility **CHEAP** for the repository; **EXPENSIVE** for #6419's data limb. Confidence **HIGH** / **MEDIUM** respectively.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `core/hooks/block-destructive.sh` | `~/Claude/.claude/hooks/block-destructive.sh` | `./deploy.sh --deploy` (hook mirror) — **#5651 only** | `./deploy.sh --check` reports no hook drift |

**No other propagation target exists in this release.** Enumerated over the four classes `deploy.sh --deploy` carries — `skills/` S-2 copy, `packages/` `.skill` rebuild, `core/rules/` mirror, and the hook mirror — against the declared File Change Matrix: **0** paths under `skills/`, **0** under `packages/`, **0** under `core/rules/`, and **1** under `core/hooks/`. #6222's four `SKILL.md` paths are `sanctioned-session-required` **edits to source**, and a deploy of them is a consequence of that limb's own execution path rather than a manifest row this plan schedules.

### Schema Migrations

N/A — enumerated over the classes a migration could take (data-format change on a persisted store, frontmatter schema field addition or removal, config-file key rename, registry re-keying). None is present: #6419 changes the *serialization correctness* of an existing JSONL row without changing its field set, and `repair-warn-log-escapes.py` is a one-off corrective pass over existing rows, not a format migration.

---

## Deviation Log

| # | Deviation from the Stage-4 transcription source | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **The escape surface is 9 free-text sites, not 8.** The Stage-4 Contention Map enumerated eight escape-pair sites and mis-assigned `_c56_m4_esc` at L13346 into the integer-built group; the Stage-4 append-site split of 8 + 4 is corrected to **9 + 3**, total unchanged at 12. | Stage-5 census on #7137 (E1/E2), independently re-measured by the hub at `18e3e787` | **RATIFIED before Engineering.** Carried into § Contention Map and the CIAC-2 expected value. |
| **DEV-2** | **CIAC-2's instrument is replaced.** The Stage-4 method `local _detail_escaped=` returns **7** at baseline, not the stated 8, and is blind to two of the nine sites. | Collective Review scope-lock (*"Correct all ACs before Stage 6 builds"*) | **RATIFIED.** Replaced with a name- and keyword-agnostic matcher carrying a `9 / 0 / 0` baseline null-arm. |
| **DEV-3** | **#6419's AC #3 is corrected, not merely re-baselined.** The original wording required the parsed-row count to *rise by exactly the number repaired*; measured across all 444,273 rows there are **0 fragment-starts and 0 fragment-ends**, so recovery conserves rows and the count cannot rise. | Collective Review scope-lock; Stage-5 D-3 on #7137 | **RATIFIED.** AC #3 now asserts the count is **UNCHANGED** with a per-row content round-trip. |
| **DEV-4** | **Contention C2 (#6419 × #6165) dissolves.** The Stage-4 map classified it HARD — same hunk. #6165's chosen design does not touch `flag_status_label()`. | Stage 5, hub-verified at `18e3e787` | **RATIFIED.** Recorded as DISSOLVED in § Contention Map rather than deleted, so the delta from the Stage-4 surface stays visible. |
| **DEV-5** | **#6742's call-site baseline is 16 sites / 9 check-id families**, not the 13 / 8 the Stage-4 plan recorded. | Collective Review scope-lock; hub re-measurement at `18e3e787` | **RATIFIED.** Carried into § Implementation Sequence position 2. |
| **DEV-6** | **#6222 is retained rather than split out.** The Stage-4 plan's first and strongest recommendation was to split it into its own release on two independent grounds. | **D-1** at the Stage-4 gate | **OPERATOR DECISION.** Milestone stays at 8 members; the size override stands; **AI-006** carries the residual that the override *decision* stands while its *stated ground* does not. CIAC-4 is in force rather than withdrawn. |
| **DEV-7** | **#6419's File Change Matrix gains two rows the Stage-5 design did not carry** — `core/config/allowlists/script-execution-allowlist.txt` and `.github/workflows/install-tests.yml`. | The Stage-4 authoring contract's **new-executable companion obligation**: an `add` row for a tracked executable `*.sh` obliges the allowlist companion row and an explicit statement of CI wiring | **DECLARED AT COMMIT 0, not silently absorbed.** The Stage-5 matrix declared three paths; a delivered test with no allowlist row is unrunnable agent-side on arrival, and a test with no CI step is never executed. Both are additive edits to existing files. |
| **DEV-8** | **The card's stated risk is narrowed.** #6419's body says the malformed rows matter *"because this file is the evidence base for gate graduation decisions."* Measured per check id: all 659 belong to six checks whose flip is declined or deferred on architectural or precondition grounds, while the one cohort whose flip **is** drain-gated carries **193,872 rows and 0 malformed**. | Stage-5 E6 on #7137, hub-verified | **ACCEPTED AS A NARROWING, not a withdrawal.** The card stands on the two grounds that survive: per-check integrity is locally severe (**26.8 %** of Check 56's rows are unparseable), and the writer is unsound for any `detail` carrying a control character — which is the actual invariant, since the 28 `check-*.py` primitives emit TSV diagnostics this writer does not control. |
| **DEV-10** | **CIAC-2's expected value is `1 1 9 0` under a FOUR-term instrument, not the `0 1 9` Stage 5 predicted under a three-term one.** The first term counts the backslash-doubling idiom, and the surviving definition necessarily contains it: `json_escape_detail`'s own substitution IS the escape pair, written once. No bash implementation that keeps the escaping in-language can read 0 there. | Measured at the Engineering commit; the criterion's own **intent** — zero duplicated pairs at call sites — is unchanged | **CORRECTED AT ENGINEERING, declared rather than absorbed.** A fourth term was added that bounds the definition's body by walking from its header to its closing brace and counts idiom occurrences **outside** it; that term reads **0** and is the one that grades completeness. The null arm moves with it: `9 0 0 9` over the reconstructed pre-fix source. Leaving the stated expectation at `0 1 9` would have graded a correct implementation as NOT MET. |
| **DEV-11** | **The recovery tool copies the source file's mode onto the replacement.** Not in the Stage-5 contract, which specified `os.replace()` atomicity and said nothing about permissions. | Defect found by a full-scale sandboxed `--apply` run at this commit | **FIXED IN THE SAME COMMIT, and the omission is worth naming.** `tempfile.mkstemp()` creates 0600 and `os.replace()` keeps the **temp** file's mode, so the specified sequence silently narrowed a 0644 drain to 0600 and would have broken every reader that is not the owner. Now pinned by a self-test arm that drives the real `--apply` path end to end and asserts the mode survives. A design contract that specifies atomicity but not metadata is atomically correct and operationally wrong. |
| **DEV-9** | **Issue #6419's title and body are left unamended** although both carry the stale `444` / `406,543` figures and a falsified causal claim (*"the record spans a line break"*). | Canonical-spec-wins-over-substrate-mutation precedent; carried as **AI-003** | **ACCEPTED RESIDUAL.** The body is historical record; the design is built against current state. The title count was corrected 444 → 659 at Stage 5; the body narrative was not. |

---

## Verification Evidence

(Populated after Stage 12 execution.)

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Change Description

(Authored by the Stage 6 release-engineering spoke at PR-creation time per [`RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Change Description Protocol, once the last card lands. Operator-facing, pre-merge, ~60 lines. Distinct from the user-facing release note authored at Stage 13 Close per [`release-notes-standard.md`](/release/references/standards/release-notes-standard.md).)

---

## Baseline pin

`origin/main` @ **`18e3e787`** (`18e3e787fe56efeab50a8f96660cffaa322e9d6c`), measured 2026-09-05. Read by the Stage-9 mid-pipeline divergence re-check. Confirmed unmoved at Engineering Commit 0 — the Stage-4 pin and the Commit-0 base are the same commit.

## Issue References

<!-- repo-integrity: allow-issue-ref — limb 1: a release plan's member enumeration IS its subject matter; the numbers are the release's own scope, not prose citations, and relocating them would delete the plan's scope statement -->

Every member of this milestone is transitioned to closed at Stage 13, by the Stage-13 close-out on the merged PR rather than by an auto-close keyword in the PR body. The members are #6419, #6742, #6222, #6214, #6165, #5651, #5564 and #6213.

- **#6419** — the warn-log `detail` field reaches `printf` with control characters unescaped, so 659 rows of the live family are invalid JSON.
- **#6742** — `flag_advisory_only` emits one check's authority pointer for every check that calls it.
- **#6222** — 18 `<OPERATOR_INSTANCE_*>` tokens are used across the corpus without being registered.
- **#6214** — Check 72 carries 25 `c71`-prefixed identifiers left behind by a check-number collision.
- **#6165** — Check 16's report path does not honour the scoping its check path applies.
- **#5651** — hook source and deployed copies have no parity check, and one already diverges.
- **#5564** — `detect_changed_skills()` reports a stateless tag-diff as though it were the deployed set.
- **#6213** — the `_g1_03_evaluate` preamble cites an ADR at a line that has moved.
