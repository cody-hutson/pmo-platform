---
title: Release Plan — deletion-guard-judges-every-segment-and-target (the deletion guard judges every segment and the target the command acts on, and reads a quoted here-document body as data)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.08; the concrete number binds at the Stage-12 atomic claim)
milestone: deletion-guard-judges-every-segment-and-target
release_class: novel
reversibility: MODERATE / Confidence MEDIUM — one branch, one pull request and one merge; reverting a card's fix commit (or the merge) restores the prior guard, but the hook tier is a deployed copy, so a revert must itself be republished through the hook carrier and verified by hash. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `deletion-guard-judges-every-segment-and-target`

**Milestone:** `deletion-guard-judges-every-segment-and-target` (milestone 444). Three cards on one hook: **#7644**, **#8122** and **#8123**. The Stage-4 planning sub-task **#8899** carries the approved plan (`#8899 comment 6859023656`), the Stage-4 gate's Decision Recorded (`#8899 comment 6859645556`) and the Stage-5 Collective Review scope-lock Decision Recorded (`#8899 comment 6864626024`). The Stage-5 designs are on **#8900** (#7644, `#8900 comment 6862663925`), **#8901** (#8122) and **#8902** (#8123); their independent Phase A6.5 adversarial reviews are on **#8989** (#7644, `#8989 comment 6863290206`), **#8990** (#8122) and **#8991** (#8123). The Stage-6 Engineering sub-tasks are **#8903** (#7644), **#8904** (#8122) and **#8905** (#8123); this file is Engineering Commit 0, authored by the spoke on **#8903**, which also builds #7644's slice.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.08`**, equal to the D-Version determination recorded at the Stage-4 gate (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/deletion-guard-judges-every-segment-and-target`, cut from `origin/main` at `29c60404`; one pull request opened in **draft** at Stage 6 Phase C2; one merge into `main`.

**Concurrency posture:** **P0 fully serial** — one Engineering spoke at a time, in the build order #7644 → #8122 → #8123. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8899 and is amended, in order, by: the Stage-4 gate's Decision Recorded on #8899 (plan approved as recommended, with the Release Outcome Statement revision; D-ReleaseClass `novel`; D-Version v5.08 minor as a recorded determination; D7 build order; D-Mechanism a private parser; D6 a named data-receiver list; #7644 AC3 re-anchored; D2 and D3 as recommended), then the three Stage-5 designs and their adversarial reviews as the Collective Review adopts them, then the Collective Review scope-lock Decision Recorded on #8899 (Q1 to Q8, and the binding decision list appended to each Stage-6 sub-task). Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log with the decision that caused it. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): guard logic and readiness text inside existing structure, per the Bump-Class Selection Guide's "protocol text addition or modification". The rule-computed next-free re-verified at Engineering Commit 0 is `v5.08` (§ Commit-0 Version Re-Verify Record). The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-13 (Friday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file), then each card's RED commit and fix commit in the build order #7644 → #8122 → #8123 |
| **Branch** | `release/deletion-guard-judges-every-segment-and-target` |
| **PR** | opened in **draft** at Stage 6 Phase C2; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `deletion-guard-judges-every-segment-and-target` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-13, domain: software }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform hook, hook suite, readiness fragment, generated registry, decision record or release plan, so no external body of practice is consumed. Dominant domain **`software`** (the deliverable is hook and test code); secondary domain governance (the rule fragments and the registry). Transcribed unchanged from the Stage-4 plan (Phase A1.5).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `29c60404` (`29c604045def22ebd21fb4a758c3bb56be277b20`), equal to the Stage-4 baseline pin. The release branch was cut from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 29c604045def22ebd21fb4a758c3bb56be277b20 --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v5.08`** (exit 0; "would claim v5.08 (no tag pushed)") — equal to the D-Version determination recorded at the Stage-4 gate |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each saved to a file and read by one python3 line scan that compares exact
             version tuples
Denominator: 468 ls-remote lines (228 distinct versions, the highest v5.07); 233 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             3,084 lines
Control - sensitivity: the same scan on the v5.07 slot reads 2 tag lines, 1 Release line and
             6 ledger lines; on the v5.05 slot it reads 2 tag lines, 1 Release line and 8
             ledger lines. Every arm returns non-zero on a claimed slot, so a zero on the
             v5.08 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (the comparator is tuple equality)
Extraction:  every line of the three reads, the ledger read from origin/main (never the
             worktree copy)
Result:      0 occupants of the (5,8) slot on every arm
Verdict:     CLEAN — v5.08 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** three sibling releases are in flight, each `minor`, each recomputing next-free to the same `v5.08` slot. That is a Tier-S serialization point resolved by merge order and the atomic claim, not a HALT at this rung: the slot binds at the claim (§ Cross-PR Overlap Audit → In-Flight Release Roster).

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp deletion-guard-judges-every-segment-and-target`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-13`** (Friday). Its one load-bearing consumer is the `date:` frontmatter field of #8122's new decision record (the #8122 Stage-5 design's Date Variable block), which carries this value unchanged.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria — CIAC-1 and CIAC-2, reworded by the Collective Review | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA) and the Commit-0 base | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Issue | Priority | Size | Title | Disposition |
|---|---|---|---|---|
| #7644 | P3 | M | block-rm-prefer-trash treats rm text inside a quoted heredoc's data as a command, blocking commands that delete nothing | carried; Stage-5 design on #8900 as amended by the Collective Review (Q1, Q2, Q3, Q5, PR-2, the budget reconciliation) |
| #8122 | P2 | M | Deletion hook stops judging a compound command before every segment | carried; Stage-5 design on #8901 as amended by the Collective Review (Q5, Q6, Q8) |
| #8123 | P3 | M | Deletion hook's outside-workspace check misses three target forms | carried; Stage-5 design on #8902 as amended by the Collective Review (Q4 grew it S → M) |

**Size:** 12 raw points, **14 effective** under `novel` (the milestone's composition total after #8123 grew from S to M at the Stage-5 scope lock).

### Exclusions

| Item | Why it is out of scope | Routed to |
|---|---|---|
| #8123's fourth form (the workspace-scope gate in the shared scope guard) | The fix sits in a library every hook loads and reverses a deliberate inert-outside-root design (D2) | its own card, filed at the Stage-13 follow-up step |
| #8123's further Finder-delete spellings and the earlier-segment path-resolution race | Open-ended, not enumerable into gradable criteria; a race-class design problem (D3 (b), (c)) | Stage-13 follow-up ledger |
| #8122 R-3 (a Finder delete with an unreadable path) and R-6 (retire the canonicalizer's unconsumed exit views) | Held by the Collective Review | Stage-13 follow-up ledger |
| An unquoted here-document's body read as data (D-Unquoted) | Its body is expanded, so a substitution in it must stay judged; #8122's plain-body pin stands | not taken |
| A quoted here-document inside a command substitution or a subshell (Q1) | bash 3.2 ends such a body at an unbalanced `)` inside an unquoted substitution and runs the following lines (the hub's shell probe); declined on every shell | not taken — its body stays judged |
| A body written to a file or named pipe that something later reads (D-Deferred); a `python3 -` program that itself hands text to a shell (D-PyNested) | Accepted as declared residuals (Q2, Q3); running a file stays the script-execution guard's concern | declared in the rule fragment |
| A shared here-document helper under `core/hooks/lib/` (with the egress guard's quoted-heredoc card) | The operator chose a private parser for this release (D-Mechanism) | the long-term consolidation path; not filed here |

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-13)

Approved as recommended, with the Release Outcome Statement revision: D-ReleaseClass `novel`; D-Version v5.08, bump-class minor, a recorded determination binding only at the Stage-12 atomic claim; D7 build order #7644 → #8122 → #8123; D-Mechanism a private parser inside `core/hooks/block-rm-prefer-trash.sh`; D6 a quoted here-document body is data only when its receiver is on a named data-receiver list, every other receiver (a shell reading the body as its script included) stays adjudicated, `python3 -` a named member measured at Stage 5, mirroring the carrier model `core/hooks/block-destructive.sh` uses; #7644 AC3 re-anchored to a command-substitution spelling the guard adjudicates today, with the declared `nested-shell` residual out of scope; D2 out (own card); D3 (a) in, (b) and (c) out; Stage 6 as a spawned worktree spoke measuring only through suite arms under the suite runner, with the hub rerunning a card attended on a safety-control stop. The seven issue-body edits, the milestone-description update and three labels were applied and read back.

### Stage-5 Collective Review scope lock (operator, 2026-11-13)

Scope locked; Engineering authorized; build order #7644 → #8122 → #8123 on one release branch.

| # | Decision |
|---|---|
| Q1 | #7644: every quoted here-document inside a command substitution (`$( … )` or backticks) is declined on every shell — its body stays judged. Only top-level quoted here-documents are removal candidates. A commit message carried this way, with deletion-verb text at a line start, becomes a declared allow→refuse move (#8122 AC4) |
| Q2 | #7644 D-Deferred (a body written to a file a later segment runs) — a declared residual |
| Q3 | #7644 D-PyNested (a `python3 -` program handing text to a shell) — a declared residual of the nested-shell class; CIAC-1/2 and the D6 control name the receiver classes that stay refused |
| Q4 | #8123: a non-literal Trash target word (brace, backslash, partial quote, wholly-quoted tilde) is refused as unresolvable; #8123 grows S → M |
| Q5 | #8122 A6.5 FM-1: #7644's `git` receiver check steps over `-C <dir>` and its one operand only, never `-c` |
| Q6 | #8122 R-2: three comment-only clauses in the `script-guard-reads-every-token-as-the-shell-does` release's files are corrected in this release after that release merges, by merging `origin/main` into this branch (merge, never rebase); DEC-31 order unchanged |
| Q7 | The Stage-5 spike evidence is accepted as design evidence; Stage 6 re-measures through committed arms |
| Q8 | Everything else as briefed: the receiver list (`cat`; `git commit`/`git tag` after `-C <dir>`; the built-in `gh issue`, `gh pr`, `gh release`, `gh api`; `python3 -`); #8122's D-TL A2 and a new decision record superseding ADR-235 decision 3; 21 apparatus arms retired or re-based; no decision record for #7644; the Tier-1 adjustments |

The binding decision list appended to each Stage-6 sub-task adds: PR-2 (CIAC-1/2 declare named rows only, no blanket invariant); the work budget's 20 000 against 400 000 mismatch is fixed to one value; all four suites that read this hook run on the final text.

---

## Dependency Graph

**In the release:** 0 native edges among #7644, #8122 and #8123, and 0 cycles. Parents: #7644 → #7176, #8122 and #8123 → #7932 (evergreen flow containers, co-claimed by design). #8122 and #7644 share the segmentation seam as a **design coupling**, not a dependency: #7644 narrows what is read (a quoted here-document body leaves the judged text first), #8122 widens where a command start is judged, and the two must compose (CIAC-1). That is why #7644 builds first.

**Across milestones:** `script-guard-reads-every-token-as-the-shell-does` (#8318) shares `core/rules/bypass-mode-readiness/_cross-cutting.md`, the generated registry and, for #8122's Q6 comment clauses, three `block-destructive` files. Under program decision DEC-31 that release merges first; this branch then merges `origin/main` and regenerates. `release-usage-measured-right` (#8821) adds a decision record, so the global decision-record number slot is shared with #8122's new record (renumber at merge if lost).

---

## Implementation Sequence

Three cards, posture P0, build order #7644 → #8122 → #8123 (D7). Each card lands a **RED commit** first — its new arms, shown failing on the pre-fix hook (or, where behaviour is believed correct, armed red and reverted with the prediction stated in the commit message before the run) — then its **fix commit**, in which the rule fragment edit and the regenerated registry land together so no head carries a stale index.

| Step | Commit | Content | Exit check |
|---|---|---|---|
| 0 | Engineering Commit 0 | This file, carrying the Commit-0 Survival Set. The Commit-0 version re-verify (steps 1–3), then `claim-version.sh --verify-stamp`. **Floor:** the four suites that read this hook, each run through the suite runner under the CI layout on the base `29c60404`; recorded in § Verification Evidence | stamp OK; FAIL=0 on the floor |
| 1 | #7644 RED | The HDATA arm family in `core/hooks/tests/block-rm-prefer-trash.test.sh`, run against the pinned hook; the predicted red set named in the commit message before the run | exactly the predicted arms red |
| 2 | #7644 fix | The quoted here-document pre-pass in `core/hooks/block-rm-prefer-trash.sh`; the fragment paragraph; the regenerated registry | four suites FAIL=0 |
| 3–4 | #8122 RED, fix | Per #8122's Stage-5 design as amended by Q5, Q6 and Q8; its new decision record | four suites FAIL=0 |
| 5–6 | #8123 RED, fix | Per #8123's Stage-5 design as amended by Q4 | four suites FAIL=0 |
| 7 | Q6 merge | After `script-guard-reads-every-token-as-the-shell-does` merges: merge `origin/main` into this branch (never rebase), apply #8122's three comment clauses, regenerate the registry, re-run the four suites | four suites FAIL=0 |

### #7644 — change specification

The specification is the Stage-5 design's Output for Stage 6 (#8900) **as amended by the Collective Review**; it is summarized here and not restated.

- **`core/hooks/block-rm-prefer-trash.sh`** — a private awk pre-pass, `HEREDOC_DATA_AWK`, inserted directly after the empty-command exit and before the canonicalizer canary. On a command carrying `<<`, it removes the body of a **top-level** quoted here-document (delimiter `'D'`, `"D"` or `\D`; `<<-` strips leading tabs), and the body's delimiter line, from the text every rule reads — only when the receiver predicate admits it and nothing on the command can route the body to a program that runs it. Any shape it cannot resolve leaves the command byte-for-byte unchanged (it prints `RAW`). The seam is S1: `readonly COMMAND_RAW="$COMMAND"`, then `COMMAND` is rebound to the judged text; the block-log digest and the memory-admission digest read `COMMAND_RAW`. Amendments to the design text:
  - **Q1:** any `<<` met inside a command substitution, a backtick or a subshell declines (marker `M-HD-ENCL`). The design's two-receiver substitution reading (the `arg` role and its marker `M-HD-OUTER`) is not built.
  - **Q5 and the receiver list:** the receiver is the first word of the simple command holding the operator, bare or under the canonical bin prefixes, with no wrapper, assignment or redirection first: `cat`; `git` whose next word is `commit` or `tag`, after at most one `-C <dir>` pair (never `-c`); `gh` whose next word is `issue`, `pr`, `release` or `api`; `python3` with zero or more single-letter flags from `-[BEIOSbdqsuv]` and then the operand `-`.
  - **Budget:** one value, **20 000** scanned characters outside bodies, in the awk, the comment block, the fragment and this file (with 500 lines, 8 bodies and a 4096-character line cap).
  - **PR-1:** the comment block and the fragment state the fail direction in two halves — every decline keeps today's verdict; every admission rests on the pre-pass ending a top-level body where the executing shell ends it (the exact-delimiter rule bash, zsh and dash share for a top-level here-document).
- **`core/hooks/tests/block-rm-prefer-trash.test.sh`** — the HDATA arm family: the AC1 arms (one per rule that refuses today: `-001`, `-002` and `-003`), their twins (a mechanics check of excision, outside the declared set), the AC2 and AC3 controls, the receiver controls (a shell, `osascript`, `python3 -c`, a non-canonical path, a wrapper, a `gh` extension, a pipe, a process substitution, the redefinition words, a parameter expansion, an unterminated body, arithmetic, mixed bodies), the enclosure controls (Q1, including the probe's unbalanced-parenthesis class), the `git` receiver arms (Q5) graded through a suite-built copy of the hook with its whole-line git exit removed while that exit exists, the declared residual pins, the budget arms at the cap, a timed arm, and four mutant pairs (`M-HD-RECV`, `M-HD-RISKY`, `M-HD-ENCL`, `M-HD-QUOTED`) in the suite's existing mutant-pair pattern.
- **`core/rules/bypass-mode-readiness/block-rm-prefer-trash.md`** — a new paragraph, *Quoted here-document data (runs first)*, directly before the command-position paragraph, which is retitled; it names the receiver list, the declines, the shells the reading assumes, the two-half fail direction, and the declared residuals (D-Deferred worded by mechanism, D-PyNested, a name redefined by state the line does not show).
- **`core/rules/bypass-mode-readiness.md`** — regenerated by `python3 core/deploy/tools/build-hook-registry.py`, never hand-edited.

### #8122 and #8123 — change specifications

Each is its Stage-5 design's Output for Stage 6 (#8901, #8902) as amended by the Collective Review; their Engineering spokes (#8904, #8905) build them and record any deviation here. #8122: delete both allow-on-match exits; judge every segment; refuse a target-less deletion or Trash segment (D-TL A2); a new decision record superseding ADR-235 decision 3, with ADR-235 taking a frontmatter pointer; the 21 apparatus arms bound to the removed exits retired or re-based; INT-1 and INT-2 (its contract with #7644's pre-pass) are **predicted** at Stage 5 and graded on the composed head after #8122's fix commit (A6.5 FM-2). #8123: recognise the keg-only Trash location; compare a root and a target in one normalized form, with a test-only seam for the normalizer-unavailable case; expand a home-relative operand from the HOME the line sets; refuse a non-literal Trash target word (Q4); reword the tier-2 registry sentence (D3 (a)).

### Agent-Editability Read

**Derivation** — controls read at commit `29c60404` (transcribed from the Stage-4 plan).
- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — every `case` block whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: 2 blocks observed. Block 1 names deployed-surface paths at the primary root (the context files, `.claude/settings.json`, `.claude/hooks/`, `.claude/rules/`); block 2 is the membership form for `CLAUDE.md`, `OPERATIONS.md` and `RELEASE_PROTOCOL.md` in a working tree. No write-set path matches either.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`; arming key `skill_discipline_migrated_v10_2: true`. Conjunct 1 (the scope regex) is false for every write-set path.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|------|----------------|----------|--------------|-----------|-----------|----------------|
| #7644 | `core/hooks/block-rm-prefer-trash.sh` · its suite · `block-rm-prefer-trash.md` · the generated registry | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8122 | the same, plus `_cross-cutting.md`, the fp-control suite, `command-position.awk` (comments), the new decision record, ADR-235 (frontmatter), and the three Q6 `block-destructive` files | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #8123 | `core/hooks/block-rm-prefer-trash.sh` · its suite · `block-rm-prefer-trash.md` · `_cross-cutting.md` · the generated registry | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| release | `release/releases/plans/deletion-guard-judges-every-segment-and-target_RELEASE_PLAN.md` | no | no | unconstrained | — | ordinary Engineering spoke |

`unconstrained` means no control mechanically floors or gates the write — not that the change is ungoverned: these are always-enforce security-hook edits, governed by the No-ungoverned-changes rule and authorized by the plan gate.

---

## Stage Applicability Matrix

Default: every stage applies. Stage-5 activation per the T1–T6 matrix; `novel` biases toward ALL.

| Issue | S5 | S6 | S7 | S8 | S9 | S10–13 | Fired S5 triggers |
|---|---|---|---|---|---|---|---|
| #8122 | ACTIVATE — done (#8901) | ✓ | ✓ | ✓ | ✓ Deep | ✓ | T3 (target-less-limb design) · T4 (interim over-block approaches) · T6 (the per-segment walk feeds the 4-hook canonicalizer; touches ADR-235's exits) |
| #7644 | ACTIVATE — done (#8900) | ✓ | ✓ | ✓ | ✓ Deep | ✓ | T3+T4 (private parser against shared helper; the D6 receiver carve-out) · T6 (a canonicalizer change would reach all 4 anchor hooks) |
| #8123 | ACTIVATE — done (#8902) | ✓ | ✓ | ✓ | ✓ Deep | ✓ | T3 (normalizer-unavailable test seam) · T4 (Trash-local pattern against the 4-hook anchor) · T6 (the anchor prefix set is duplicated across 4 hooks) |

No stage skips: each card is a functional change to an always-enforce security control (Stages 7–8 mandatory). Stage 9 depth **Deep**. Stages 10 and 11 compress for a git-native release (the pull-request diff is the dry run; git is the snapshot; the hook carrier's pre-refresh snapshot is the deployed tier's rollback point).

---

## File Change Matrix

```
# ── unconditional ──
EDIT  core/hooks/block-rm-prefer-trash.sh
EDIT  core/hooks/tests/block-rm-prefer-trash.test.sh
EDIT  core/rules/bypass-mode-readiness/block-rm-prefer-trash.md
EDIT  core/rules/bypass-mode-readiness/_cross-cutting.md
EDIT  core/rules/bypass-mode-readiness.md
EDIT  core/hooks/tests/command-position-fp-control.test.sh
EDIT  core/hooks/lib/command-position.awk
ADD   core/ADRs/ADR-*-deletion-guard-judges-every-segment.md
EDIT  core/ADRs/ADR-235-command-position-walks-wrapper-grammar-from-asserted-rows.md
ADD   release/releases/plans/deletion-guard-judges-every-segment-and-target_RELEASE_PLAN.md
# ── conditional (Q6: after script-guard-reads-every-token-as-the-shell-does merges) ──
EDIT  core/rules/bypass-mode-readiness/block-destructive.md     CONDITIONAL:AFTER-SIBLING-MERGE
EDIT  core/hooks/block-destructive.sh                            CONDITIONAL:AFTER-SIBLING-MERGE
EDIT  core/hooks/tests/block-destructive.test.sh                 CONDITIONAL:AFTER-SIBLING-MERGE
```

| Path | Intent | Card(s) | Change specification |
|---|---|---|---|
| `core/hooks/block-rm-prefer-trash.sh` | edit | #7644, #8122, #8123 | § Implementation Sequence, per card |
| `core/hooks/tests/block-rm-prefer-trash.test.sh` | edit | #7644, #8122, #8123 | the same |
| `core/rules/bypass-mode-readiness/block-rm-prefer-trash.md` | edit | #7644, #8122, #8123 | the same |
| `core/rules/bypass-mode-readiness/_cross-cutting.md` | edit | #8122, #8123 | #8122's line-laundering and exit-view sentences; #8123's normalization text and tier-2 wording |
| `core/rules/bypass-mode-readiness.md` | edit | all | generated: `python3 core/deploy/tools/build-hook-registry.py`; never hand-edited |
| `core/hooks/tests/command-position-fp-control.test.sh` | edit | #8122 | the M4 mutant re-based, plus 2 comments (#8122 Stage-5 matrix row 3) |
| `core/hooks/lib/command-position.awk` | edit | #8122 | header comments only, no code (#8122 Stage-5 matrix row 4) |
| `core/ADRs/ADR-*-deletion-guard-judges-every-segment.md` | add | #8122 | the new decision record superseding ADR-235 decision 3 (Q8); its number is taken at #8122's commit against the global sequence |
| `core/ADRs/ADR-235-command-position-walks-wrapper-grammar-from-asserted-rows.md` | edit | #8122 | frontmatter `superseded_by:` only |
| `release/releases/plans/deletion-guard-judges-every-segment-and-target_RELEASE_PLAN.md` | add | release | this file, at Engineering Commit 0 |
| the three `block-destructive` files above | edit, CONDITIONAL:AFTER-SIBLING-MERGE | #8122 | one comment-only clause each (Q6); promoted to unconditional in the commit that applies them, after the merge of `origin/main` |

#### Read-only inputs

- READ `core/deploy/tools/build-hook-registry.py` (the regenerator; run, not edited).
- READ `core/hooks/tests/setup-ci-layout.sh` and `core/hooks/tests/test-runner.sh` (run, not edited).
- READ `core/hooks/block-destructive.sh` § the here-document carrier model (the precedent D6 mirrors).

#### Release-wide explicit non-scope

- NOT EDITED `core/hooks/lib/scope-guard.sh`: #8123's fourth form is out (D2).
- NOT EDITED `core/ADRs/README.md`: a curated thematic document, not an index, which lists no hook-walk record (#8122's Stage-5 design); Stage 4's conditional row does not fire.
- NOT EDITED `core/hooks/lib/command-position.awk` by #7644: the private-parser route keeps the shared canonicalizer untouched (D-Mechanism); its header's here-document residual stays true of the canonicalizer.

**Mirror pairs:** none. `core/rules/bypass-mode-readiness*` is not in `mirror_pair_set()`.

**New-executable companion obligation:** N/A — the matrix has no `add` row for a `*.sh`.

**Deliverable domain:** `software`, with governance secondary. **Deliverable state:** the hook reaches `deployed-copy-synced` at Stage 12 (the hook-tier publish); the fragments, the registry and the decision records are corpus files with no propagation target; this file is the release's own record.

---

## Contention Map

**Within the release** (one branch, one PR → resolved by sequence):

| File | Issues | Severity | Resolution |
|---|---|---|---|
| `core/hooks/block-rm-prefer-trash.sh` | #7644, #8122, #8123 | MULTI-WAY | sequential commits; #7644's pre-pass lands first, so the per-segment walk never meets here-document data |
| `core/hooks/tests/block-rm-prefer-trash.test.sh` | #7644, #8122, #8123 | MULTI-WAY | additive arms; HOME-FIXTURE-01 kept; one differential is the exit bar |
| `core/rules/bypass-mode-readiness.md` (generated) | all | MULTI-WAY | never hand-merged — regenerated from source after each fragment edit |
| `core/rules/bypass-mode-readiness/block-rm-prefer-trash.md` | #7644, #8122, #8123 | MULTI-WAY | each card's paragraph lands, then the registry is regenerated |
| `core/rules/bypass-mode-readiness/_cross-cutting.md` | #8122, #8123 | BINARY | sequential |

**Across milestones and PRs (measured at Commit 0):** `script-guard-reads-every-token-as-the-shell-does` shares `_cross-cutting.md`, the generated registry and the three Q6 files; DEC-31 → it merges first, then this branch merges `origin/main` and regenerates. `release-usage-measured-right` (#8821) shares the decision-record number slot with #8122's new record. `engineering-harness-pages-published` (#8983) touches none of this release's write set.

---

## Cross-PR Overlap Audit

### Baseline SHA

- **Stage-4 baseline pin:** `29c604045def22ebd21fb4a758c3bb56be277b20` (the merge of PR #8844), read 2026-11-13T15:56Z.
- **Commit-0 base:** the same SHA — `origin/main` had not moved when the branch was cut. The Stage-9 A6.5 divergence re-check reads from this pin.

### In-Flight Release Roster

**Measured at:** `29c60404` · `2026-11-13T21:10Z` · **Population:** n=3 sibling(s) (open PRs with a `release/*` head, drafts included, 2 of 2 open PRs read; remote `release/*` heads without a PR, 1).

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `engineering-harness-pages-published` | `#8983` | `b65c6a48` | `minor` | `v5.08` | `v5.08` | — |
| `release-usage-measured-right` | `#8821` | `8974f500` | `minor` | `v5.02` (stale) | `v5.08` | — (the decision-record number slot only) |
| `script-guard-reads-every-token-as-the-shell-does` | `—` | `a78dfd83` | `minor` | `v5.08` | `v5.08` | `core/hooks/tests/block-destructive.test.sh` (the Q6 conditional row) |

The roster records a measurement only; Stage 9 A6.6 renders the verdict.

### Structural sub-audit

The mover-set is ∅: no rename, relocation or delete is planned, and the ADR-092 stamp is the routine claim rename. `SURFACE(R)` = {`Δversion/minor-from-v5.07`}, which all three in-flight siblings carry — a Tier-S serialization point resolved by merge order and the atomic claim.

---

## Risk Register

| ID | Class | Risk | Severity | Reversibility | Mitigation |
|---|---|---|---|---|---|
| R1 | Design-coupling | #8122's widening lands before #7644's exclusion → a transient over-block of quoted-heredoc-body deletion text | Minor | CHEAP | D7: #7644 builds first; the differential is graded on the composed head |
| R2 | Contention | `_cross-cutting.md`, the generated registry and the Q6 files are shared with `script-guard-reads-every-token-as-the-shell-does` | Major | MODERATE | DEC-31: the sibling merges first; merge `origin/main` (never rebase), then regenerate the registry from source |
| R3 | Scope creep | a shared-canonicalizer route for #7644 would widen the blast radius to all 4 anchor hooks | Major | MODERATE | D-Mechanism: the private parser; `command-position.awk` is not edited by #7644 |
| R4 | Scope sizing | #8123 grew S → M at the scope lock (Q4) | Minor | CHEAP | carried at 12 raw / 14 effective, inside the acceptable band |
| R5 | Rollback / live-safety | a PreToolUse guard the platform runs under; a regression is a live deletion-safety issue | Major | MODERATE | RED before every fix; the full-suite differential is the exit bar — no verdict moves refuse→allow except CIAC-1's named rows; a single-PR revert is clean |
| R6 | Security (carve-out) | "a quoted here-document body is data" would allow a real deletion in a body a program executes | Major | MODERATE | D6's default-deny receiver list; the route and redefinition declines; Q1's enclosure decline; a must-stay-refused control per receiver class and a live mutant per decline |
| R7 | Version slot | three in-flight siblings recompute the same `v5.08` slot | Minor | CHEAP | a version-axis serialization edge resolved at the atomic claim; no action now |
| R8 | Test integrity | #8123's normalizer-unavailable test seam could become a runtime override surface | Minor | CHEAP | the seam is test-only; Stage 7 asserts no runtime override path |
| R9 | Measurement constraint | hook measurement runs only through suite arms under the CI layout, never against deployed hooks | Minor | — | every spoke measures through the suite runner in its own sandbox; on a safety-control stop the hub reruns the card attended |
| R10 | Shell divergence | the pre-pass and the executing shell could disagree on where a body ends (A6.5 FM-1) | Major | MODERATE | Q1 declines every enclosure, where the hub probe measured bash 3.2 diverging; the top-level exact-delimiter rule is shared by bash, zsh and dash; the fragment names the shells the reading assumes |
| R11 | Decision-record slot | #8122's new record and #8821's record compete for the next global number | Minor | CHEAP | renumber at merge if the slot is lost; the record is cited by its slug token |

**Rollback strategy:** a single-PR revert (revert the merge, record the rollback; the version tag is retained per Tag Retention). All three cards ship on one branch, so there is no partial-release rollback surface (§ Rollback Strategy).

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8122 × #7644 on `core/hooks/block-rm-prefer-trash.sh` segmentation seam):** the integrated hook composes #8122's per-segment judgement with #7644's quoted here-document data exclusion such that the only suite verdicts that move refuse→allow are the named rows HDATA-AC1-A, HDATA-AC1-B, HDATA-AC1-C, HDATA-AC1-D, HDATA-AC1-F, HDATA-AC1-G, HDATA-AC1-H, HDATA-AC1-I and HDATA-AC1-J (a top-level quoted body read by a listed receiver), HDATA-CAP-IN (the same class at the scan budget), HDATA-PY-ODD (the declared D-PyNested residual) and HDATA-PIN-DEFERRED (the declared D-Deferred residual); and a quoted body whose receiver is a shell, `osascript`, `python3` with `-c`, `-m` or a script operand, any other unlisted receiver, or a listed receiver whose output is piped or process-substituted, and a quoted body inside a command substitution or a subshell, stays refused. *Method:* declared, verification deferred to `core/hooks/tests/block-rm-prefer-trash.test.sh` — the refuse→allow differential over the guard suite, with the HDATA-RX and HDATA-ENCL arm families as the must-stay-refused controls; graded at Stage 9 QC3.5 on the merged PR.
- [ ] **CIAC-2 (#8122 × #7644 × #8123 on the full guard suite):** the merged suite differential against the pre-fix hook shows exactly the declared verdict moves — the union of #8122's and #8123's allow→refuse gap closures (with #8122's declared allow→refuse move for a commit message carried by a here-document inside a command substitution), CIAC-1's named refuse→allow rows, and HDATA-CWD's rule move from `-001` to `-002` — and no other arm changes verdict; the HDATA-RX and HDATA-ENCL controls stay refused. *Method:* declared, verification deferred to `core/hooks/tests/block-rm-prefer-trash.test.sh` — the complete suite differential against the pre-fix hook; graded at Stage 9 QC3.5 on the merged PR.

The twin arms (HDATA-TWIN) check the excision mechanics — a command with its excised lines removed is judged as the excised command is — and are deliberately not members of the declared set (PR-2): a wrong excision satisfies that invariant too, so it cannot stand in for the named rows.

CIAC lint (`verify-release-plan.sh --ciac-lint`, G4-06) on this file at Engineering Commit 0: recorded in § Verification Evidence.

---

## Verification Plan

### Per-Issue Verification

**AC baseline:** #7644 has 5 criteria, #8122 5 and #8123 5 (AC-1 to AC-5 each, in body order), read at `29c60404` against the bodies as amended at the Stage-4 gate and the Stage-5 scope lock.

`ac_baseline: { #7644: 5, #8122: 5, #8123: 5, read_at: 29c604045def22ebd21fb4a758c3bb56be277b20 }`

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7644 | AC-1 | [DEFERRED — runner .claude/hooks/tests/test-runner.sh at Stage 7 and in CI; the HDATA-AC1 arms, one or more per rule that refuses today (-001, -002, -003), each red on the pre-fix hook in the RED commit] | each HDATA-AC1 arm allowed; red on the pre-fix hook |
| #7644 | AC-2 | [DEFERRED — runner; the HDATA-AC2 controls, an outside deletion after the delimiter, before the operator, and after a separator on the operator line] | each refused under -001 on both hooks |
| #7644 | AC-3 | [DEFERRED — runner; the HDATA-AC3 controls, an unquoted body whose substitution carries a deletion verb in a spelling the guard adjudicates today, and an unquoted plain body] | each refused on both hooks |
| #7644 | AC-4 | [DEFERRED — runner; the HDATA-RX controls, one per receiver class, and the HDATA-ENCL controls, each with its mutant pair live] | each refused on both hooks; each mutant allows its sentinel |
| #7644 | AC-5 | [DEFERRED — runner; the four suites that read this hook, on the final text] | FAIL=0 in each, at or above the Commit-0 floor plus the new arms |
| #8122 | AC-1 | [DEFERRED — runner; #8122's arm for a git segment then a later outside deletion] | refused (-001) |
| #8122 | AC-2 | [DEFERRED — runner; #8122's arms, one per shape: a target-less deletion then a later Trash move, and then a later deletion with a different verb; the same-verb control] | refused |
| #8122 | AC-3 | [DEFERRED — runner; #8122's arm for a Trash call with no literal target] | refused under the strict policy |
| #8122 | AC-4 | [DEFERRED — runner; #8122's controls: git alone, a commit message with deletion-verb text inline and in a top-level quoted here-document read by git commit, also behind -C dir; the here-document inside a command substitution as its declared allow→refuse move] | allowed, except the declared move, refused |
| #8122 | AC-5 | [DEFERRED — Stage 8 read of the regenerated registry row against the hook's git exemption] | the exemption is stated at the scope the hook implements |
| #8123 | AC-1 | [DEFERRED — runner; one arm per Trash install location the hook recommends, with an outside target] | classified; the outside target refused |
| #8123 | AC-2 | [DEFERRED — runner; arms on a symlinked sandbox root, inside and a .. escape, with the normalizer available and through the test-only seam] | inside = inside, escape = outside, both modes |
| #8123 | AC-3 | [DEFERRED — runner; the arm for a home-relative Trash operand after a HOME reassignment on the line] | not admitted as inside |
| #8123 | AC-4 | [DEFERRED — Stage 8 read of the regenerated registry's tier-2 Trash entry against the hook] | describes the location the hook recognises |
| #8123 | AC-5 | [DEFERRED — runner; the existing inside-workspace Trash arms, absolute and workspace-relative] | allowed, unchanged |

### Release-Level Verification

| Check | Method | Expected |
|---|---|---|
| Index freshness and corpus checks | `bash core/deploy/deploy.sh --check` | exit 0 |
| Suite differential (the exit bar) | [DEFERRED — Stage 7: per-arm verdicts of the guard suite on the base against the final head, read against CIAC-1 and CIAC-2's declared moves] | zero undeclared moves |
| Deployed parity (Stage 12) | [DEFERRED — operator handoff for the hook-tier publish; the hub reads the digest] | the deployed `block-rm-prefer-trash.sh` SHA-256 equals the merged source's |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential, posture **P0**, build order #7644 → #8122 → #8123 (D7) |
| Commit strategy | Commit 0 (this file, the version re-verify, the stamp, the floor) → per card a RED commit then a fix commit; the fragment edit and the regenerated registry land in the fix commit |
| Review approach | One PR for the milestone. Topology **SINGLE**, branch `release/deletion-guard-judges-every-segment-and-target`. Draft until the Stage-9 gate |
| Sync with `main` | After `script-guard-reads-every-token-as-the-shell-does` merges (DEC-31): merge `origin/main` (never rebase), regenerate the registry, re-run the four suites (Q6) |
| Deployment mechanism | Git merge, then the hook-tier publish through the hook carrier as a user-side handoff, verified by hash. No skill package changes |
| Stacked-base cleanup | N/A under SINGLE |

---

## Rollback Strategy

| Path | When | Steps | Complexity |
|---|---|---|---|
| Pre-merge | a card's fix misbehaves on the branch | revert that card's fix commit (linear history) and re-run the four suites | Low |
| Post-merge, before publish | a defect found after merge, before the hook tier is refreshed | revert the merge commit through a fix branch; the deployed tier is untouched | Low |
| Post-publish | a refusal storm or a fail-closed loop on the instance | operator: restore the hook tier from the carrier's pre-refresh snapshot for immediate relief; then revert the merge and republish. The version tag is retained | MODERATE |
| Forward fix | a narrow, understood defect | a fix branch through the pipeline | Low |

---

## Quota Budget

**Verdict:** PASS — ordinal-only, LOW confidence `[CALIBRATE-AFTER-3]` (per `quota-budget-protocol.md` Checkpoint A).
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 3 · Stage 7: 3 · Stage 8: 3.
**Per-spoke cost estimate:** size-bucket ordinal band (no telemetry medians); all three cards `size:M` after Q4.
**Assumed/stated remaining usage-window envelope:** operator-unstated at hub start; the conservative default applied.
**Estimated cumulative draw % (worst parallel batch):** not synthesized (the envelope is unstated), so the verdict is the ordinal ranking only.
**Routing:** PASS (ordinal) — proceed.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — and also gates on the host-API axis, combined DEFER-dominant. Checkpoint A stays usage-window-only. Bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

- **Class: `novel`** (D-ReleaseClass, carried). Novel (b) fires: the plan carries D-class decisions (the #7644 mechanism and receiver list, the #8122 seam, D6, D-PyNested, D-Deferred). Novel (c) fires: #8122 authors a decision record superseding ADR-235 decision 3. Corrections to a security control, one of them a P2 bypass, warrant more review than routine.
- **Posture:** engagement Standard · Stage 9 **Deep** · Stage 5 bias **ALL** · Stage 13 outcome window 30-day.

---

## Release Outcome Statement

**AFTER** — The deletion guard judges every segment of a compound command that carries a deletion or Trash verb, whatever the other segments hold. A `git` subcommand exempts only its own segment, and a deletion or Trash verb whose targets cannot be read from the line is refused under the guard's strict policy. A quoted heredoc's body outside any command substitution, read by a recognised data receiver, is data, so `rm` text inside it is not adjudicated; a quoted body any other receiver runs, a quoted heredoc inside a command substitution, and an unquoted heredoc's command substitution in a spelling the guard adjudicates today, are still adjudicated. The outside-workspace decision is made on the target the command acts on: the Trash location the guard itself recommends is recognised as a Trash invocation, a root and a target are compared in one form, and a home-relative operand is expanded from the HOME the line sets.

**BEFORE** — A `git` subcommand, or an `rm` with flags and no target, earlier on the line ends the judgement, so a later recursive `rm` outside the workspace passes. `rm` text inside a quoted heredoc's body is refused as a deletion, blocking commands that delete nothing. Three target forms are compared in a form the shell does not act on.

**Actor(s):** any session whose commands pass through the guard; the deployed hook bundle.

**Success Indicator:** the must-refuse arms for each compound shape and each target form are red against the pre-fix hook, beside plain-form controls. A quoted-heredoc arm with `rm` text in its body, read by a recognised data receiver, is admitted, while its shell-receiver twin and its unquoted command-substitution twin, in a spelling adjudicated today, are refused. No other arm in the guard's suite changes verdict, and the milestone ships as one PR.

**Limb owners:** every segment judged, `git` exempting only its own segment, a target-less deletion refused → #8122 · a quoted heredoc's body read as data → #7644 · the outside-workspace decision made on the target the command acts on → #8123

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/hooks/block-rm-prefer-trash.sh` | the deployed hook tier `<workspace-root>/.claude/hooks/block-rm-prefer-trash.sh` | operator-run hook refresh through the hook carrier after the merge and the primary's fast-forward, as a Hook-Blocked → User-Side Handoff (the precedent of the hook successor batches; Stage 12 confirms the mechanism) | the deployed copy's SHA-256 equals the merged source's |

### Schema Migrations

N/A — enumerated over the classes {data-schema change, frontmatter-schema change, config-key change, log-record shape change}; none present in this release (the block-log and memory-admission record shapes are unchanged; their digests are taken over the command as submitted, as today).

### Memory Evictions

N/A — enumerated over the classes {memory eviction, memory re-point}; none present in this release (no codification card ties an auto-memory entry).

---

## Deviation Log

| ID | Stage | Deviation | Basis |
|---|---|---|---|
| DEV-1 | 6 (Commit 0) | The AC baseline is `{ #7644: 5, #8122: 5, #8123: 5 }`, not the Stage-4 plan's `{ 4, 5, 4 }`: the Stage-4 gate added a receiver criterion to #7644 and a registry criterion to #8123, and the scope lock reworded #8122 AC4. The Verification Plan carries one row per criterion as the bodies now read | the Stage-4 gate's Decision Recorded (seven body edits); the Collective Review |
| DEV-2 | 6 (Commit 0) | #7644 does not build the Stage-5 design's substitution reading (a body inside one `$( … )` excised when two receivers pass). Every `<<` inside a command substitution, a backtick or a subshell declines; the `arg` role and the `M-HD-OUTER` marker are replaced by one enclosure decline, `M-HD-ENCL`, with its own mutant. The design's HDATA-AC1-E shape (a `gh` body carried by a double-quoted substitution) becomes HDATA-ENCL-A, a must-stay-refused control, and HDATA-AC1-E is not authored | Collective Review Q1 |
| DEV-3 | 6 (Commit 0) | The `git` receiver steps over one `-C <dir>` pair (never `-c`). Its arms (HDATA-GIT) are graded through a suite-built copy of the hook with the whole-line git exit removed while that exit exists, because the shipped exit allows every git-headed line today | Collective Review Q5 |
| DEV-4 | 6 (Commit 0) | The work budget is one value, 20 000 scanned characters outside bodies, in the awk, the comment block, the fragment and this file; the Stage-5 Evidence-Grounding figure of 400 000 is not used. It is grounded by arms at the cap and a timed arm | the binding decision list (the budget mismatch); A6.5 FM-6 |
| DEV-5 | 6 (Commit 0) | CIAC-1 and CIAC-2 name rows only, and name the receiver classes that stay refused; the twin invariant is a mechanics check outside the declared set | Collective Review PR-2, Q2, Q3 |
| DEV-6 | 6 (Commit 0) | The File Change Matrix promotes the conditionals that resolved at the scope lock (#8122's decision record and ADR-235's pointer, `_cross-cutting.md`, the fp-control suite, `command-position.awk` comments), adds the three Q6 `block-destructive` files as conditional on the sibling release's merge, and marks `core/ADRs/README.md` not edited | Collective Review Q6, Q8; #8122's Stage-5 matrix |
| DEV-7 | 6 (Commit 0) | The size line carries 12 raw / 14 effective; the Stage-4 plan's "#8123 stays S" is superseded | Collective Review Q4 |
| DEV-8 | 6 (Commit 0) | The D-Deferred residual is worded by its mechanism — a body written to any file or named pipe, whatever reads it and whenever — rather than by segment order | A6.5 FM-7, folded as a Tier-1 adjustment |
| DEV-9 | 6 (#7644 RED) | CIAC-1's named refuse→allow rows gain HDATA-CAP-IN: the budget arm that grounds the 20 000-character cap is a top-level `cat` body, the same class as HDATA-AC1-A, read at the cap | DEV-4; the budget arms |
| DEV-10 | 6 (#7644 fix) | HDATA-ENCL-C's payload now ends its subshell on a line carrying a command. With a `)` alone on the closing line, a second decline (an empty parenthesis pair, read as a function definition — toward today's verdict) held the sentinel through the enclosure mutant, so HDATA-MUT-ENCL-C could not show the enclosure decline live. HDATA-ENCL-C stays refused on both hooks | the first GREEN run (296/297, HDATA-MUT-ENCL-C) |

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

- **Version re-verify:** PROCEED at `v5.08` (§ Commit-0 Version Re-Verify Record).
- **Stamp manifest (step 3b):** `release/tools/claim-version.sh --verify-stamp deletion-guard-judges-every-segment-and-target` → exit 0, "carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". The file carries one literal double-brace release-version placeholder (`grep -c -F` → 1).
- **CIAC lint (A1, G4-06):** `release/tools/verify-release-plan.sh --ciac-lint` on this file → `CIAC-LINT-SUMMARY declared=2 parsed=2 clean=0 declared-deferral=2 flagged=0`, exit 0 — both declared in the verification-deferred form, none flagged.
- **Floor:** on the base `29c60404`, each suite run alone through `bash .claude/hooks/tests/test-runner.sh` from a sandbox built by `bash core/hooks/tests/setup-ci-layout.sh --sandbox <run dir>/sbx` (the sandbox hook's SHA-256 prefix `1336b7ae8af48ccb`, equal to the base's): `block-rm-prefer-trash.test.sh` 227/227, `command-position-fp-control.test.sh` 198/198, `ghsa-g9g6-primitive-fail-closed.test.sh` 45/45, `hook-fail-closed.test.sh` 75/75 — **545/545**, FAIL=0. This is the floor every card's fix head reads against.
- **ADR index:** N/A at Commit 0 — no record under `release/ADRs/`. #8122 adds its record under `core/ADRs/`, whose README is not a projected index.

### #7644 RED — Stage 6 B1

- **Arms:** 70 new HDATA arms in `core/hooks/tests/block-rm-prefer-trash.test.sh`, the prediction written before the run (29 red: the 9 AC1 arms, HDATA-CWD, HDATA-PY-ODD, HDATA-PIN-DEFERRED, HDATA-CAP-IN, HDATA-GIT-A to -C, and the 13 mutant pairs, whose marked lines do not exist yet).
- **Run:** the deletion-hook suite alone through the suite runner under the CI layout, with the sandbox hook replaced by the base's (SHA-256 prefix `1336b7ae8af48ccb`): `Total: 297  PASS: 268  FAIL: 29` — exactly the predicted 29, and the 227 existing arms all pass.
- **Rule IDs on the base hook**, read from the sandbox block log by each payload's input digest: the AC1 arms refuse under `-001` (A, B, D, F, G, H, I), `-002` (C) and `-003` (J), one or more per rule that refuses today; HDATA-CWD under `-001`; every control under its expected rule; the twins and HDATA-PY-EVEN leave no row.

### #7644 fix — Stage 6 B1 / C4

- **Change:** the quoted here-document pre-pass and the S1 seam in `core/hooks/block-rm-prefer-trash.sh` (the two digests read the command as submitted; three comments reconciled); the fragment paragraph; the registry regenerated (`build-hook-registry.py --check` → in sync).
- **The four suites that read this hook, on the final text,** each alone through the suite runner under the CI layout (sandbox hook SHA-256 prefix `72623a826e551775`, equal to the committed file): `block-rm-prefer-trash.test.sh` 297/297, `command-position-fp-control.test.sh` 198/198, `ghsa-g9g6-primitive-fail-closed.test.sh` 45/45, `hook-fail-closed.test.sh` 75/75 — **615/615**, FAIL=0, against the floor 545 plus the 70 new arms.
- **The final arms on the base hook** (the RED run repeated after the one payload change below): 30 red — the predicted 29 and HDATA-COST. The timed arm compares a refusal with an allow on the base hook, so its ratio there is not a cost of the pre-pass; it is read on the fixed head, where both commands are allowed, and it passed there in both runs.
- **Cascade sweep** (the Stage-5 design's four UPDATE rows, exact-phrase counts over the hook and the fragment): pre 1 / post 0 on each of "takes the raw command, as a failed", "deliberately keep the RAW", "The extractor reads the raw command" and "Command-position model (runs first)".
- **shellcheck:** no new finding in the hook or the suite against the base.
- **Integration with #8122 (INT-1, INT-2):** predicted, not measured — graded on the composed head after #8122's fix commit (A6.5 FM-2).
