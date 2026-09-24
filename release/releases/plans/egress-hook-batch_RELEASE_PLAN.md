---
title: Release Plan — egress-hook-batch (egress allowlist rows are consulted only in their own match domain, and an unparseable refusal leaves a classifiable record)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.68; the concrete number binds at the Stage-12 atomic claim)
milestone: egress-hook-batch
release_class: novel
reversibility: CHEAP / Confidence HIGH — every row is a bounded edit to tracked files plus new markdown records on one branch with one merge, so `git revert -m 1` of the merge restores `main` byte-for-byte; the allowlist change is revert-safe because a scope directive is a comment line to the prior matcher. The one qualification is recorded in § Rollback Strategy: a claimed version tag is retained and recorded rather than deleted.
---
# Release Plan — `egress-hook-batch`

**Milestone:** `egress-hook-batch` · Stage-4 sub-task **#7546** = the approved plan (parts 1–2), the hub's R1 adversarial evaluation, the Stage-4 gate **Decision Recorded** comment, the scaffolding record and the release-level Collective Review record · **#7553** = #5592's Stage-5 design (parts 1–3), its independent adversarial review and its Collective Review scope-lock · **#7554** = #6201's Stage-5 design (parts 1–2), its adversarial review and its scope-lock · **#7555** = the Stage-6 Engineering sub-task that authored this file · **#7556** = #6201's Stage-6 Engineering sub-task, whose spoke transcribed the second card's sections at slices 2b–2c.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.68`**. Recorded as a determination (not a click-gate) at the Stage-4 gate; the concrete `vX.Y` binds only at the Stage-12 atomic claim per ADR-092, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp placeholder. The Commit-0 re-verify ran in full, both halves — see § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch (`release/egress-hook-batch`), one PR opened in draft at Commit 0 so CI runs while the later slices land, one merge, base `main`. This plan lands as **Engineering Commit 0**, authored by #5592's Engineering spoke; #6201's Engineering spoke runs after it on the same branch.

**Concurrency posture:** **P0 fully-serial** — both cards edit the same hook and the same suite. Every non-serial posture prohibits force-push (including `--force-with-lease`) on the shared release branch; P0 is in force.

**Release class:** `novel` — switched from `routine` at Stage 5 under the operator's Stage-4 pre-authorization, at the first Stage-5 D-class decision. Stage 9 review depth **Deep**. See § Release Class declaration.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on #7546 and the Stage-4 gate **Decision Recorded** comment on it — whose amendments bind this commit (AC-Binding: an amended criterion obliges its bound row in the same change) — reconciled to the approved Stage-5 designs on #7553 and #7554 and to the three **Collective Review scope-lock** records. **Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority.** Every thread comment consumed was `OWNER`-authored (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — provisional display v4.68; binds at the Stage-12 atomic claim |
| **Date Created** | 2026-09-24 (Thursday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/egress-hook-batch` |
| **PR** | **#7638** — opened in **draft** at Commit 0 per the SINGLE topology; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `egress-hook-batch` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-24, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): every row targets an internal `pmo-platform` artifact. The determinative evidence is one shell hook, its shell suites, an allowlist data file and the allowlist helper — executable behaviour — which resolves `domain-best-practices/software.md` (§ Security covers fail-closed and validation). Secondary domain `security`, because the partition is a trust-domain question; `security.md` was consulted at Stage 5 as the secondary lens. Transcribed unchanged from Stage-4 Phase A1.5 and re-affirmed by both Stage-5 designs; no Mode-B label existed to upgrade.

---

## Commit-0 Version Re-Verify Record

Run in full at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location.

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `0c759aaf`, the baseline pin, unmoved |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 0c759aaf992726c2cba5e43400ca6daa4056fdf3 --bump minor --dry-run` (the adapter's own `anchor()` + `claimed_set()`; no tag pushed) | **`v4.68`** — equal to the recorded provisional display |
| **3** | HALT on collision: the planned version must be absent from every `claimed_set()` arm AND equal the recomputed next-free. The tag arm binds; published Releases and the RELEASE_LOG corroborate | **no collision; PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.68*'                        (tag arm — binds)
             gh release list --limit 5000 --json tagName   → startswith("v4.68")    (Releases arm)
             grep -c 'v4\.68' <git show origin/main:release/releases/RELEASE_LOG.md> (ledger arm)
Denominator: 212 v* origin tags (peeled refs excluded); 210 published Releases (limit 5000, so the
             read is not truncated); RELEASE_LOG at origin/main, 2567 lines
Control - sensitivity: the SAME three readers on the v4.67 slot — tags: v4.67 and v4.67.1 (2);
             Releases: ["v4.67.1","v4.67"] (2); ledger: 16 lines. Every arm resolves and returns
             non-zero, so a zero on the v4.68 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over an exact version tuple has no
             near-miss class; the tag glob v4.68* is broader than the tuple, so its zero implies
             the tuple's zero
Extraction:  full ls-remote output; the full 210-row release list; the full ledger read from
             origin/main (never the worktree copy)
Result:      0 occupants of the (4,68) slot on every arm
Verdict:     CLEAN — v4.68 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** `git ls-remote --heads origin 'release/*'` → **0** heads (control: the unfiltered reader → 2 heads, `main` and one orphan chore branch); open PRs → **0** (`--limit 500`). The concurrent release `autonomy-ceiling-domains-resolve-canonically` observed at scaffolding had pushed no head at Commit 0.

### Manifest half (step 3b, post-write / pre-commit)

`release/tools/claim-version.sh --verify-stamp egress-hook-batch` — run after this file was written and before it was committed. Required exit **0**. Result recorded in § Verification Evidence.

This plan carries **exactly one** double-brace `RELEASE_VERSION` placeholder — the Header `**Version**` cell — and every other mention names the placeholder instead of reproducing it. The claim tool resolves the token by global substitution across the whole file, so a literal prose citation would be rewritten at Stage 12 along with the record site.

### Commit-0 Survival Set

Every element the Stage-4 gate determined that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). A transcription that drops one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, no Mode-B rationale required) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1..3`) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (with the Decision Recorded amendments and the 5/5 AC baseline) | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, named rather than reproduced) | § Header `**Version**` cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | § Baseline pin |

---

## Scope

**Two content members, both P2 bugs, independent of each other** — zero in-release edges, verified at Stage 4 by a native-edge read of both cards with a live control.

| # | Issue | Problem | Priority | Labels |
|---|---|---|---|---|
| 1 | #5592 | The egress allowlist serves two match domains — the host of a curl upload and the path of a `gh api` write — and the matcher applied every row to both. A bash `case` glob's `*` crosses `/`, so the host wildcard `*.github.com` allowlisted any `gh api` write whose path ends in `.github.com`; a query-string suffix makes any write endpoint end that way | P2 | bug · cluster: security · size:S · project:platform-quality |
| 2 | #6201 | Every `BLOCK-EGRESS-007` refusal with cause `unparseable` writes the same constant evidence string, so a correct refusal and a false one cannot be told apart afterwards and the rule's false-positive rate cannot be audited | P2 (confirmed at the Stage-4 gate) | bug · cluster: security · size:S · project:platform-quality |

**Acceptance criteria.** Each card carries **five** — the four originals reworded to the verification-verb form at the Stage-4 gate (meaning unchanged), plus a fifth usability predicate added there; #6201's AC-3 was re-scoped to the measured pre-fix population. The criteria's single home is each issue body; § Verification Plan binds each one by ordinal and never restates it.

**Registered dependency exception (co-discharge).** #6201 → #6194 (milestone `evergreen-cleanup-batch`): #6201 settles the refusal-record field set (FS-6201) that #6194 then serializes one record per line. Ordering only — no native link (creating it was not authorized). G3-07: `PASS-WITH-EXCEPTIONS (1 registered)`.

**Explicit non-scope.** #6194 (compact serialization of the same writers) and #7544 (one shared refusal-record writer across hooks) stay out. No `core/hooks/lib/` member is added — it would trigger the three-roster cascade — and no other hook's writers change.

---

## Decision Record

### Stage-4 gate (operator, 2026-09-24)

| Decision | Outcome |
|---|---|
| **D1** | The Stage-4 plan is approved as the scope-lock |
| **D2** | The reconciled Release Outcome Statement is adopted (§ Release Outcome Statement) |
| **D-ReleaseClass** | `routine` at Stage 4, with the switch to `novel` pre-authorized at the first Stage-5 D-class decision or ADR (it fired — § Release Class declaration). `hotfix` declined: the release introduces two conventions whose design was open at Stage 4 (the allowlist row-scope grammar and the refusal-record field set) |
| **D-Adjust A–D** | Applied before scaffolding: A — #5592's criteria reworded, AC-5 added; B — #6201's criteria reworded, AC-3 re-scoped to the measured population (304 warn-log would-block records and 4 block-log denials as of 2026-09-24), AC-4 sharpened to "a field other than `ts`, `input_digest` and `cwd`", AC-5 added; C — the milestone description (Outcome Statement, release-class rationale, `## Release Identity`, `## Parallelization Map`); D — #6201's Environment and Actual Behavior corrected to warn-mode would-block records. #6201 Severity **P2** confirmed |
| **D-C Branch Topology** | **SINGLE** — one branch, one PR, one merge |
| **D-Concurrency Posture** | **P0** fully-serial |
| **D-Version** | Recorded determination: `versioned` · bump-class `minor` · provisional display `v4.68`; re-verified at Commit 0 (above) and bound only at the Stage-12 claim |
| **AI-001** (hub commitment) | Once FS-6201 settles, post its location on #6194 with the writer-mode correction (informational; #6194's body is not edited from this release) |

### Stage 5 — #5592, locked at its Collective Review scope-lock (operator, 2026-09-24)

| Decision | Outcome |
|---|---|
| **D5-1 — partition encoding** | **(A)** an adjacent `# egress-scope: host` / `# egress-scope: gh-api-path` directive above each managed row, binding only the row on the line directly below it, **plus** the gh-api-path-site anchoring guard: a pattern whose first path segment carries a glob character is never a candidate there. `is_allowlisted` takes an optional domain argument, passed only at the -004 and -007 call sites; the ssh (-011) and WebFetch (-013) sites pass none and keep single-domain behaviour. Rejected: per-row prefixes (not revert-safe), section directives (silent scope inheritance), one file per domain (net-new surface where the in-place change suffices), shape inference, pathname-glob semantics, a shared matcher library, the guard alone |
| **D5-2 — rows with no directive** | **(A)** a row with no directive keeps dual scope (the pre-change behaviour), made safe for the host-wildcard-over-path direction by the guard. `allowlist-add.sh` gains an optional `--scope host\|gh-api-path`; without it the row is written undeclared with a stderr notice saying how it will be matched |
| **D5-3 — rollout reach** | **(A)** confirmed: the positional classifier is unchanged, so the narrowed deny enforces from day one at the command positions the replaced matcher adjudicated and is shadow-logged at every widening position. The residual (implicit POST, later invocations, new command positions) is owned by -007's graduation (#6195) |
| **ADR** | *egress allowlist rows declare their match domain* — {{ADR:egress-allowlist-rows-declare-their-match-domain}} — authored at Engineering, Accepted at the lock |
| **Spoke additions accepted** | the helper's Operational Deployment Manifest row is unconditional and is verified at Stage 12 by content together with the hook; AC-5's verification method plants the operator-region rows through the sandboxed helper; the hook-comment reconciliation (Change 1e) is included |
| **Adversarial refinements folded in** | (1) correct the claim that the guard closes the class for every row, and name the residual: an undeclared, slashless operator row remains consultable in both domains; (2) a `--scope` re-add of an existing bare row replaces that row rather than adding a second one (upgrade in place); (3) header and `docs/UPDATE.md` wording: the host check applies to curl URLs, and wget uploads are denied unconditionally; (4) one added arm: an undeclared slashless operator row against a curl-host payload |
| **Routed out of scope** | host-token normalization at the query-string tail (the reviewer's counter-design) — a separate observation card |

### Stage 5 — #6201, locked at its Collective Review scope-lock (operator, 2026-09-24)

| Decision | Outcome |
|---|---|
| **D5-4 — FS-6201** | **(A)** a nested, versioned `features` object on `BLOCK-EGRESS-007` `cause=unparseable` records in **both** writers, plus a top-level `hook_build`; `evidence` byte-identical; no `phase` key; no serialization change |
| **D5-5 — AC-3 disposition** | **(A)** write off the pre-fix records as unrecoverable, with the predicate corrected per the review: the write-off binds to records produced **before the fix deploys** (by producing build or by deploy time), never to "no `features` key", so a post-fix record written without features is never counted as pre-fix |
| **ADR** | *a refusal record carries structure, never the command* — {{ADR:a-refusal-record-carries-structure-never-the-command}} — with its Decision item 4 scoped to this record |
| **R6 accepted** | `log_block`'s two digest pipelines are replaced with the failure-proof, byte-identical parameter-expansion form |
| **Refinements folded in** | name the parse oracle inside the record; a non-syntax oracle failure records its own value, never `error`; cap the heredoc scan at the oracle's bound; reconcile the registry fragment's two untrue claims in place |
| **Resolved** | the Tier-2 note on the shared `apply_block` call — no scope change; #5592's locked design leaves `egress_007_verdict` untouched |

#### FS-6201 — the `unparseable` refusal-record field set, as built

The named output #6194's Stage 5 and #7544 consume. Present **only** on `BLOCK-EGRESS-007` records whose `evidence` reads `path=unknown cause=unparseable`, and in **both** writers — `log_warn` (`egress-warn-log.jsonl`, `.mode=warn`) and `log_block` (`block-log.jsonl`, `.mode=enforce`).

| Key | Level | Values | Computed by | Privacy |
|---|---|---|---|---|
| `features` | top-level, optional | a JSON object | `egress_007_unparseable_features` | a container only |
| `features.schema_version` | member | the integer `1` | the constant `EGRESS_007_FEATURES_SCHEMA_VERSION` | none |
| `features.oracle` | member | `bash-<major>.<minor>` · `unknown` | `egress_parse_oracle_label` — `BASH_VERSINFO` of the running shell, which is the oracle; `unknown` if the configured oracle is not the running shell (the lock's oracle-naming refinement) | host-constant; not command-derived |
| `features.shell_parse` | member | `ok` · `error` · `skipped` · `unavailable` | `egress_shell_parse` — `/usr/bin/env -i <oracle> -n` fed a here-string; exit 0 → `ok`, exit 2 → `error`, any other outcome → `unavailable`, never `error` (the lock's oracle-failure refinement) | one enum |
| `features.heredoc` | member | `none` · `quoted` · `unquoted` · `both` · `skipped` | `egress_heredoc_kind` — delimiter quoting only, never the delimiter word | one enum |
| `hook_build` | top-level, optional | 16 lowercase hex · `unknown` | `egress_hook_build` — the git blob id of the hook file that wrote the record | constant per build |

**Bounds and failure.** One size cap, `EGRESS_007_PARSE_CAP` (1,048,576 characters), is applied once to the whole feature path: above it both computations report `skipped` (the lock's cap refinement). Every feature step is failure-proof: a record whose features cannot be written is written with `hook_build` alone, and one that cannot carry either is written in the plain template. `log_block`'s two digest steps are guarded, and the 16 hex are cut by parameter expansion (R6). `evidence` is byte-identical; no `phase` key and no top-level `cause` key is added; serialization is unchanged.

#### AC3 disposition

| Card | Criterion | Disposition |
|---|---|---|
| #6201 | AC-3 | **Written off as unrecoverable** — D5-5 (A), the operator's decision at #6201's Collective Review scope-lock, with the predicate corrected per the adversarial review. **Predicate:** every `BLOCK-EGRESS-007` record in the deployed warn log or block log whose `evidence` reads `path=unknown cause=unparseable` **and which was produced before the fix deployed** — bound to deploy time (a `ts` earlier than the Stage-12 republish instant: the moment Check 79 first reads the deployed `block-egress.sh` content-equal to the merged source) and, where a record's producer is identifiable, to its producing build (a build that predates the field set writes no `hook_build`). **The absence of a `features` key is never the discriminator:** a post-fix record written without its features — by the writer's fallback, which keeps `hook_build`, or by a stale deployed copy — is never counted as pre-fix. **Read at Stage-5 entry** (counts, key sets and dates only): 305 warn-log records (`log_warn`, `.mode=warn`) and 4 block-log records (`log_block`, enforce), all written by one hook build (blob `6a40b38d`), varying only in `ts`; the Stage-4 gate's figure (304 + 4) and this read (305 + 4) are instances of the same predicate. Transcript correlation was not performed. **Re-stamp at Stage 12:** re-count the population with this same predicate after the republish, and record with it the zero-claim *post-republish `unparseable` records lacking `features` = 0*, whose sensitivity arm is `AC-E007-V7d`'s mutation |

### Release-level Collective Review (operator, 2026-09-24)

Both designs are locked with their review refinements folded in; release class `novel`, Stage 9 review Deep; Stage 6 runs serially, #5592 first (it lands Engineering Commit 0), then #6201. Follow-ups routed by the hub: #7548 enriched with the further `unparseable` false-refusal mechanisms, a note on #6195, and two new observation cards.

---

## Implementation Sequence

One branch (`release/egress-hook-batch`), P0, slices in order. Each remediation lands its RED arms first: **arm → observe RED → fix → observe GREEN**, with the RED observation (command plus FAIL lines) recorded in § Verification Evidence.

| # | Slice | Card | Content | Satisfies |
|---|---|---|---|---|
| **0** | Engineering Commit 0 | release | This plan file, with the Commit-0 re-verify (steps 1–3, then 3b) | Survival Set |
| **1a** | RED arms | #5592 | The hermetic `AC-E007-D*` family in `core/hooks/tests/block-egress.test.sh` — the design's arms D1, D1q, D1s, D1w, D2 (armed-red-then-revert, predictions stated before the run), D2g, D3, D3c, D4a–D4d, D5a, D5b, D6s, D6w, D8, D9; plus **D7**, the AC-5 method (both regions × both modes × three payloads, operator-region rows planted through a sandboxed `allowlist-add.sh`), and **D10**, the lock's added arm (an undeclared slashless operator row against a curl-host payload) — every gh-api payload spells its method flag explicitly. The helper arms in `core/hooks/tests/allowlist-add.test.sh` (`--scope`, the notice, validation, the dangling-directive blank line, upgrade in place). Observed RED at `0c759aaf` | AC-1..AC-5 |
| **1b** | Fix | #5592 | Changes 1–10 of the locked design: the `# egress-scope:` directives; `is_allowlisted`'s optional domain argument and the path-site anchoring guard; the header rewrite; `allowlist-add.sh --scope` with upgrade in place; `docs/UPDATE.md` § 4; the registry fragment row and data-flow section plus the regenerated index (Check 38 fresh); the ADR; the hook-comment reconciliation (Change 1e). Observed GREEN | AC-1..AC-5 |
| **2a** | RED arms `AC-E007-V*` | #6201 | The hermetic `AC-E007-V*` family (28 lines) in `core/hooks/tests/block-egress.test.sh`, run through the D family's sandbox runner under both `.mode=enforce` and `.mode=warn`: V1 (both modes); V2 and the armed-red V2m1–V2m3, predictions printed before each run; V3; V4; V5 (both modes); V6; the mutation arms V7b, V7b2, V7c, V7d (both modes — corrected at the lock: the record keeps `hook_build`), V7e and V7f, each with its guard triple; the controls V7c0 and V7g; V8; and **V9, CIAC-1's record-contract arm**. Observed RED at the unchanged hook: 21 of 28 FAIL | AC-1, AC-2, AC-4, AC-5 |
| **2b** | Fix | #6201 | FS-6201 in both writers, with the lock's refinements folded in (the oracle named in the record; a non-syntax oracle failure recorded `unavailable`; one cap over both computations; the fallback keeping `hook_build`); the R6 digest guard; the `log_block` comment rewritten (Documentation Impact) and the call-site comment reconciled; the registry fragment's two untrue claims reconciled in place, with reading guidance for this class, and the index regenerated (Check 38 fresh); {{ADR:a-refusal-record-carries-structure-never-the-command}}, numbered at creation. Observed GREEN: 28 of 28 | AC-1, AC-2, AC-4, AC-5 |
| **2c** | AC-3 disposition | #6201 | The D5-5 write-off row with the corrected predicate (§ Decision Record → AC3 disposition). No repository file beyond this plan | AC-3 |
| **3** | Release-level verification | release | Full hook suite under the CI layout · install regression suite (selection-map row 5) · CIAC-1..3 · `bash -n` · Check 38 | — |

**Slices 1a–1b are the high-value core.** Interrupted after 1b, the live exposure is closed on a shippable increment. The Stage-4 plan's CONDITIONAL docs slice is folded into 1b and 2b (DEV-5): each card edits the fragment and regenerates the index in its own fix slice.

**CIAC-1's record-contract arm is `AC-E007-V9`**, authored at slice 2a and GREEN from slice 2b. Its `unparseable` limb asserts the FS-6201 fields, which do not exist before those slices. #5592's limb — a `not-allowlisted` record still carries the denied path after the scope change — is pinned from slice 1a by arm D1's evidence assertion (`AC-E007-D1e`) and asserted again inside V9, which already passed that limb at the RED run.

**A2 container determination, recorded rather than assumed.** The threshold predicate is evaluated from the change matrix: #5592's decomposition is nine file-level units and the work is multi-file and structure-changing, so the predicate selects the **GitHub sub-issue container** on its literal reading. The release nonetheless runs each card's Stage-6 decomposition through the **per-issue Stage-6 sub-task the hub already scaffolded** (#7555, #7556), with the change units enumerated in § File Change Matrix and rendered as checklist rows in the PR body. Creating further sub-issues per card would duplicate a container the hub already owns — the same determination an earlier release recorded for the same shape.

**Armed-red-then-revert** (the arms grading already-correct behaviour, with predictions stated before the run): #5592 D2 — delete the sandbox's `api.anthropic.com` row and its directive, predict exit 2 `BLOCK-EGRESS-004`, run, restore, predict exit 0, run; #6201 V2 per its design. Where a mutated copy is used: guard that the mutation removed what it claims, confirm the copy still parses, and confirm it still enforces an untouched rule.

---

## Stage Applicability Matrix

| Stage | #5592 | #6201 | Basis |
|---|---|---|---|
| **5 — Solutioning** | APPLY (#7553) | APPLY (#7554) | T3 · T4 · T6 fire for both cards; ran in parallel |
| **6 — Engineering** | APPLY (#7555) | APPLY (#7556) | All-`unconstrained` write set, P0, #5592 first |
| **7 — Dev Testing** | **APPLY** (#7557) | **APPLY** (#7558) | Executable hook behaviour with an agent-runnable suite; selection-map row 3 (`core/hooks/**`) for both, plus row 5 (`core/config/allowlists/**`) for #5592 |
| **8 — QA** | **APPLY** (#7559) | **APPLY** (#7560) | Both cards change a security control's behaviour or output |
| **9 — Plan Review** | APPLY (#7561) | — | **Deep** (release class `novel`) |
| **10 — Dry Run** | COMPRESS (#7562) | — | Skip-closed. Reopens as a read-only operator-row impact preview only if D5-2 changes a deployed operator row's scope: the authoring instance's operator region held **0** rows at Stage 5 — re-read at Stage-12 entry |
| **11 — Snapshot** | COMPRESS (#7564) | — | Git history is the snapshot |
| **12 — Execute** | APPLY (#7566) | — | Merge + atomic claim (versioned) + hook republish + allowlist regeneration, verified by content (Check 79 for `block-egress.sh` **and** `allowlist-add.sh`) |
| **13 — Close** | APPLY (#7568) | — | 30-day outcome window; #5592 and #6201 are transitioned to closed at Stage 13, after the Stage-12 deployed-state checks |

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. Both Stage-5-promoted CONDITIONAL tokens resolved at the Collective Review, before this commit, so their rows are **promoted in this commit** (DEV-4); the option-(b) rows resolved **false** and are recorded NOT DELIVERED (DEV-3).

```
# ── Production ──
core/hooks/block-egress.sh                                                   edit
core/config/allowlists/egress-allowlist.txt                                  edit
# promoted from CONDITIONAL:D5-2-HELPER-SCOPE (D5-2 = A edits the helper)
core/hooks/allowlist-add.sh                                                  edit

# ── Verification ──
core/hooks/tests/block-egress.test.sh                                        edit
# promoted from CONDITIONAL:D5-2-HELPER-SCOPE
core/hooks/tests/allowlist-add.test.sh                                       edit

# ── Documentation ──
# promoted from CONDITIONAL:D5-1-FRAGMENT-SCOPE (D5-1 = A adds an allowlist-scope row to the -007 table)
core/rules/bypass-mode-readiness/block-egress.md                             edit
# generator output of the fragment above — build-hook-registry.py, never hand-edited
core/rules/bypass-mode-readiness.md                                          edit
# promoted from CONDITIONAL:D5-2-HELPER-SCOPE
docs/UPDATE.md                                                               edit

# ── Decision records (both originated at Stage 5 — DEV-1, DEV-2) ──
core/ADRs/ADR-204-egress-allowlist-rows-declare-their-match-domain.md        add
# numbered at creation by #6201's Engineering spoke: anchor 203 on origin/main, 204 held by the record above
core/ADRs/ADR-205-a-refusal-record-carries-structure-never-the-command.md    add

# ── Release corpus ──
release/releases/plans/egress-hook-batch_RELEASE_PLAN.md                     add

# ── CONDITIONAL — resolved FALSE at Stage 5 (D5-1 = A, not option b); NOT DELIVERED, see DEV-3 ──
CONDITIONAL:D5-1-OPTION-B  core/config/allowlists/<per-domain-allowlist>.txt  add
CONDITIONAL:D5-1-OPTION-B  core/deploy/composition-surface-manifest.sh        edit
CONDITIONAL:D5-1-OPTION-B  core/rules/bypass-mode-readiness/_cross-cutting.md  edit
```

#### Read-only inputs

```
core/hooks/lib/scope-guard.sh                                READ
core/hooks/lib/master-enable.sh                              READ
core/hooks/lib/command-position.awk                          READ
core/hooks/tests/setup-ci-layout.sh                          READ
core/hooks/tests/test-runner.sh                              READ
core/deploy/compose.py                                       READ
core/deploy/tools/build-hook-registry.py                     READ
core/hooks/block-autonomy-ceiling.sh                         READ
core/hooks/block-skill-direct-edit.sh                        READ
.github/workflows/install-tests.yml                          READ
```

#### Release-wide explicit non-scope

```
core/hooks/lib/                                              NOT EDITED
core/deploy/deploy.sh                                        NOT EDITED
core/config/allowlists/script-execution-allowlist.txt        NOT EDITED
core/config/allowlists/webfetch-allowlist.txt                NOT EDITED
core/ADRs/README.md                                          NOT EDITED
```

- **No new executable**, so the new-executable companion obligation does **not** fire: the `add` rows are two markdown ADRs and this plan, and both edited suites are existing, allowlisted, CI-wired files.
- **`core/ADRs/` adds no index obligation.** The release-module ADR index is generated only for `release/ADRs/`; `core/ADRs/README.md` is a curated thematic document with no projector, so a `core/`-only ADR addition trips no projection trigger. The whole-tree `adr-number-integrity` job still asserts the gap-free sequence, which is why ADR-204 was claimed against the mainline anchor (203) rather than a branch-local maximum.
- **The generated index is not a mirror-pair member** (`mirror_pair_set()` carries 9 rows and it is not one), so no Check-9 obligation attaches and no deployed copy exists.
- **The webfetch allowlist header** carries the same comment-rule misstatement the egress header is corrected for here (Stage-5 finding); it is a next-release item, not this release's.

### Agent-Editability Read

Transcribed from the Stage-4 derivation, controls read at commit `0c759aaf`, and extended to the promoted and added rows. **Every row decided on conjunct 1** — no path carries a `*/skills/<name>/` segment, so the skill-gate's first conjunct is false everywhere and the exemption list is never load-bearing. The Tier-0 `.claude/hooks/*` and `.claude/rules/*` arms name the **deployed** trees, not `core/hooks/` or `core/rules/`.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class |
|---|---|---|---|---|
| #5592 | `core/hooks/block-egress.sh` · `core/hooks/allowlist-add.sh` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| #5592 | `core/config/allowlists/egress-allowlist.txt` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| #5592 · #6201 | `core/hooks/tests/block-egress.test.sh` · `core/hooks/tests/allowlist-add.test.sh` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| #5592 · #6201 | `core/rules/bypass-mode-readiness/block-egress.md` + the generated index | ∅ — not a mirror-pair member | ∅ — conjunct 1 false | `unconstrained` |
| #5592 | `docs/UPDATE.md` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| #5592 · #6201 | `core/ADRs/ADR-204-…md` · `core/ADRs/ADR-205-…md` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| release | `release/releases/plans/egress-hook-batch_RELEASE_PLAN.md` | ∅ | ∅ — conjunct 1 false | `unconstrained` |

**Card class `unconstrained` for both; execution path: ordinary Engineering spoke.** An `unconstrained` row means no control refuses the write — never that the change is ungoverned.

---

## Integration Points

| # | Seam | Why it binds |
|---|---|---|
| IP-1 | `is_allowlisted` ↔ 4 call sites (-004 host, -007 gh-api path, -011 ssh, -013 WebFetch) | A signature change reaches two rules neither card names; only -004 and -007 pass a domain |
| IP-2 | `egress_007_verdict` → `apply_block` → `log_warn` (warn, exit 0) \| `log_block` (enforce, exit 2) | The dual-writer seam; #6201's AC-1 holds only if both writers carry FS-6201 |
| IP-3 | Allowlist ↔ composition surface (manifest row unchanged) ↔ managed section + preserved OPERATOR ADDITIONS region ↔ `allowlist-add.sh` insert-before-END ↔ ADR-014 two-hash regeneration | Operator rows live outside git, and the matcher change reaches them |
| IP-4 | `block-log.jsonl` / `egress-warn-log.jsonl` ↔ consumers (#6194's drain count, the specificity readings, the suite's growth and last-record reads) | Record-shape changes propagate |
| IP-5 | Hook tier ↔ the publisher / installer refresh ↔ Check 79 | Deployed ≠ source is the recent defect class — for the helper as well as the hook (S5-R1) |
| IP-6 | Registry fragment → generated index (Check 38) | Both cards edit the fragment; regenerate after each edit |
| IP-7 | CI: `install-tests.yml` (hook suite via `setup-ci-layout.sh` + `test-runner.sh`) · install regression (row 5) · repo-integrity (SIGPIPE, depersonalization, issue-ref, dead-file-ref, ADR number integrity, ADR durability) | Merge gates |

### Contention

- **Within the release:** `core/hooks/block-egress.sh` and `core/hooks/tests/block-egress.test.sh` are BINARY-contended by the two cards over **disjoint** ranges (#5592: the constants, `is_allowlisted`, the -004 and -007 call sites and the authority-prefix comment; #6201: the writers, `apply_block`, `egress_007_verdict` and the unparseable call site). Serial P0 makes it a rebase, never a conflict. `core/rules/bypass-mode-readiness/block-egress.md` is edited by both in disjoint sections.
- **Cross-PR:** 0 open PRs at Commit 0 (`--limit 500`; control: the merged-PR reader returns non-zero). A pinned baseline, not a verdict — re-run before every build wave; Stage 9 A6.6 renders it.
- **Dormant siblings** (not yet at Stage 4; whichever merges second re-baselines): `evergreen-cleanup-batch` (#6194 — the same writers as #6201; #6195 — the rollout-phase constant, owner of D5-3's residual) · `hook-walk-adjudicates-every-operand` (#7004 — the prefix walk and the suite, disjoint lines) · `install-resolves-identically` (#5274 — **now contends** on `allowlist-add.sh`, because D5-2 promotes the helper edit) · `detectors-match-the-property-not-the-spelling` (#6866 — the widened SIGPIPE gate; CIAC-3) · `one-primitive-per-operation` (#7212 — no overlap; no lib is added).

### In-Flight Release Roster

**Measured at:** `0c759aaf` · `2026-09-24` Commit 0 · **Population:** n=0 — none in flight at `0c759aaf` (0 `release/*` heads, 0 open PRs; controls above).

---

## Risk Register

| # | Risk | Mitigation | Sev / Rev |
|---|---|---|---|
| **R1** | The live exposure persists until merge **and** republish; a merged fix that never reaches the deployed hook tier closes nothing | #5592 first; Stage-12 verification by **content** (Check 79), never the publisher's exit status; never deploy the hook tier from the branch for testing — the hermetic sandbox only | HIGH / CHEAP |
| **R2** | Operator-added rows acquire an unknown scope; the preserved region is not in git | D5-2 (A): an undeclared row keeps its pre-change matching; the rule is stated in the managed header, the helper notice, `docs/UPDATE.md` and the release note; the Stage-12 entry read of the deployed operator region | HIGH / MODERATE |
| **R3** | The narrowing enforces only at old-reachable spellings | D5-3 (A) confirmed; the residual is -007's graduation (#6195); arm D1s proves the verdict is computed at widening positions | MEDIUM / CHEAP |
| **R4** | A signature change on `is_allowlisted` regresses -011/-013 | No domain argument at those sites (the pre-change loop, where a directive is an ordinary comment); allow-direction arms D6s / D6w | MEDIUM / CHEAP |
| **R5** | #6201 false-PASS on writer coverage (the recorded rows are warn-shape) | FS-6201 names both writers; its arms run under both modes | HIGH / CHEAP |
| **R6** | The privacy floor on a public repository | Enumerated structure only; no command text, offsets, lengths or path fragments; sentinel arm plus its mutation form | HIGH / MODERATE |
| **R7** | The co-discharge ordering with #6194 slips | FS-6201 is a named output; no `phase` key on non-shadow rows; no serialization change here | MEDIUM / CHEAP |
| **R8** | Record-shape lock-in for #7544 | A nested, versioned `features` object (D5-4) | MEDIUM / MODERATE |
| **R9** | #6201 AC-4 false-PASS via `input_digest` | The method compares non-identity fields only | MEDIUM / CHEAP |
| **R10** | Rollback asymmetry | D5-1 (A) is revert-safe: a directive is a comment line to the prior matcher | LOW / CHEAP |
| **R11** | Test-suite ambient coupling (the suite mutates the shared `.mode`; its allowlisted-path arms fail in a bare checkout) | CIAC-2: every new arm is hermetic — own allowlist, own `.mode`, payload cwd inside the sandbox | MEDIUM / CHEAP |
| **R12** | A SIGPIPE idiom introduced unseen | CIAC-3; new logic uses here-strings and `case`, never a pipe into a short-circuiting reader | LOW / CHEAP |
| **R13** | A stall on #6201 holds #5592's fix in the single PR | No split recommended; the Tier-2 lever (split #5592 forward) is recorded for the operator | MEDIUM / CHEAP |
| **R14** | Class mis-fit | Resolved: the pre-authorized switch to `novel` fired; `effective_pts` 5, under band | LOW / CHEAP |
| **R15** | #6201's AC-3 targets rows whose producer build is unknown | D5-5 binds the write-off to deploy time or producing build; FS-6201 adds `hook_build` so the gap does not recur | LOW / CHEAP |
| **S5-R1** | A stale deployed helper drops operator rows — **true on the authoring instance** (its deployed `allowlist-add.sh` predates the marker-aware insert) | The helper's deployment row is **unconditional**; Stage 12 shows Check 79 content MATCH for `allowlist-add.sh` as well as `block-egress.sh` | MODERATE / HIGH |
| **S5-R2** | An operator slashless glob **path** row (`gist*`) stops matching at -007 | Fails closed at first use, with the standard deny message; the header rule and the release note name it | CHEAP / HIGH |
| **S5-R3** | Publish-order skew (new hook, old file) leaves the `graphql` row a host candidate | The update path regenerates before refreshing hooks; arm D9 pins the skew behaviour | CHEAP / HIGH |
| **S5-R4** | Cross-release contention on the helper (#5274) | Stage-9 in-flight contention check; the second merger rebaselines | CHEAP / HIGH |
| **S5-R5** | The grammar drifts between surfaces | Arms D5a and D5b fail on managed-file drift; the fragment's Tier-A artifact is refresh-gated (G-CL6) | CHEAP / MEDIUM |
| **S5-R6** | The second-order dependency through the generated index | `build-hook-registry.py --check` exits 0 (Check 38) after each fragment edit | CHEAP / HIGH |
| **R16** | Fail-open in the record path (#6201's Stage 5): under `set -e` a failing command in a writer ends the hook with status 1, which PreToolUse treats as non-blocking — **measured at the unchanged hook**: a failing digest step turned an enforce-mode refusal into exit 1 with no record | Every feature step failure-proof; the R6 digest guard; the mutation arms V7b–V7f prove the verdict survives each broken step (V7f RED at the unchanged hook, GREEN after) | HIGH / CHEAP |
| **R17** | Oracle fidelity: the oracle is bash while the shell that runs a command may differ | `features.oracle` names the parser and every verdict is read as scoped to it; on the authoring host `bash -n` and `zsh -n` agree on accept-versus-reject for all 10 V fixtures (§ Verification Evidence); Stage 7 re-records the agreement, adding a divergence-class fixture | MEDIUM / CHEAP |
| **R18** | The V1 false-refusal fixture exists only while the heredoc false-refusal class does | The suite names the coupling: when that class is fixed, re-point `E007_V_FP` to `E007_V_FP2` (an escaped quote the scanner also mis-models), never delete the arm | LOW / CHEAP |
| **R19** | The feature path's size cap | Unreachable on the reference platforms — the hook's input validation fails closed on a payload above the argument-size limit before -007 is reached (V7c0); the `skipped` path is proven by a lowered-cap mutation (V7c); Stage 7 measures the feature path's latency near the largest reachable command | LOW / CHEAP |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential, one branch, P0 (same-file contention) |
| **Commit strategy** | Per slice: RED-arm commit, then fix commit(s). The draft PR stays red between them by design; the merge happens only on green. Commit messages carry the `release(egress-hook-batch):` prefix and reference the source card |
| **Review approach** | Single PR for the whole release (D-C SINGLE), opened in draft at Commit 0. The PR body is parser-clean: close-family verbs adjacent to an issue number appear only in the dedicated Issue References block, and the cards are transitioned to closed at Stage 13 |
| **Deployment mechanism** | Git merge + hook-tier republish (the hook **and** the helper) + composition-surface regeneration of the allowlist. **No skill S-2 deploy, no package rebuild** — no path in the matrix sits under a rostered skill tree |
| **Stacked-base cleanup posture** | Option A (default). No stacked bases |

---

## Verification Plan

**Every method cell carries its command literally**, reproducible from the cell alone. A `bash …` cell is dispatchable but **not executed** by the plan-driven executor `release/tools/verify-release-plan.sh`, whose runnable-verb set is closed to read-only queries by design; such a row reads as ERROR (`unclassified-method`) there, and its mechanical guarantee lives in the suite's own CI-invoked run (`install-tests.yml`).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #5592 | AC-1 | `bash core/hooks/tests/block-egress.test.sh` — arms `AC-E007-D1`, `AC-E007-D1q`, `AC-E007-D1s`, `AC-E007-D3`, `AC-E007-D5b`, `AC-E007-D9` (each in its own hermetic sandbox holding the token-resolved managed rows) | D1 and D1q exit 2 naming `BLOCK-EGRESS-007`, the sandbox block log gaining one record whose `evidence` carries `cause=not-allowlisted` · D1s (the implicit-POST spelling of D1's path) exit 0 plus one shadow `would-fire` record with cause `not-allowlisted` · D3 exit 2 naming `BLOCK-EGRESS-004` (a declared path row is never consulted as a host) · D5b every managed row granted in exactly its declared domain · D9 (new hook, pre-change file) D1's payload exit 2 · each observed RED at `0c759aaf` before GREEN |
| #5592 | AC-2 | `bash core/hooks/tests/block-egress.test.sh` — arm `AC-E007-D1` at `.mode=enforce` and its warn twin `AC-E007-D1w` | enforce: exit 2 and one new block-log record naming the cause · warn: exit 0, one new warn-log record for `BLOCK-EGRESS-007` and no new block-log record · at `0c759aaf` both allow and write no record at all |
| #5592 | AC-3 | `bash core/hooks/tests/block-egress.test.sh` — arm `AC-E007-D2` (armed-red-then-revert) and arm `AC-E007-D2g` | D2 exit 0 · control: the armed mutation (the `api.anthropic.com` row and its directive removed) exit 2 naming `BLOCK-EGRESS-004`, then restored, exit 0 · D2g exit 0 |
| #5592 | AC-4 | `bash core/hooks/tests/block-egress.test.sh` — arm `AC-E007-D5a` (structural census of `core/config/allowlists/egress-allowlist.txt`, token-resolved) and arm `AC-E007-D5b` (behavioural agreement) | D5a: 15 of 15 managed rows declared, 0 undeclared, 0 violations · control: the same census over the pre-change shape (directives stripped) returns 15 undeclared, and over a planted mis-declared fixture returns at least one violation · D5b as AC-1 · the header states the two-domain grammar the matcher applies |
| #5592 | AC-5 | After the Stage-12 republish and Check 79 content MATCH for the hook and the helper: `E007_D_HOOK_SRC_DIR=~/Claude/.claude/hooks E007_D_COMPOSED_ALLOWLIST=~/Claude/.claude/egress-allowlist.txt PMO_TEST_GITHUB_HANDLE=<the owner the deployed allowlist resolved the operator token to> bash core/hooks/tests/block-egress.test.sh` — arms `AC-E007-D7*`. The deployed operator region held 0 rows at Stage 5, so the arms plant one host wildcard with no `--scope` and one `--scope gh-api-path` path row through the sandboxed copy of the deployed `allowlist-add.sh` | per region (managed, operator), the three payloads — the Reproduction-Steps write ending in that region's host suffix, a curl upload to that region's host row, a gh-api write to that region's path row that does not end in host-shaped text: enforce exit 2 / 0 / 0 with block-log delta 1 / 0 / 0 · warn exit 0 / 0 / 0 with warn-log delta 1 / 0 / 0 · the near-miss writes 0 deny records in both modes · control: the same arms run at slice 1a against the pre-fix hook deny nothing (the Reproduction-Steps write exits 0 with delta 0) |
| #6201 | AC-1 | `bash core/hooks/tests/block-egress.test.sh` — arms `AC-E007-V1` and `AC-E007-V3` under both modes | the malformed and the heredoc-carrying records differ in at least one FS-6201 field, in `block-log.jsonl` **and** in `egress-warn-log.jsonl` · RED at `0c759aaf` |
| #6201 | AC-2 | `bash core/hooks/tests/block-egress.test.sh` — arm `AC-E007-V2`: a count of the planted sentinel over both sandbox logs, with its armed-red mutation `AC-E007-V2m1`–`AC-E007-V2m3` (predictions printed before each run) | 0 · control: a count of `BLOCK-EGRESS-007` over the same logs returns at least 2; the mutation arm (`V2m2`) returns at least 1, then is reverted (`V2m3`: 0) |
| #6201 | AC-3 | Named read: this plan's `AC3 disposition` row (D5-5) | a classification table or a reasoned write-off covering the pre-fix `cause=unparseable` records — 304 warn-log and 4 block-log records as of 2026-09-24, plus any accrued before the fix deploys — with each record's writer and mode confirmed from the deployed logs |
| #6201 | AC-4 | `bash core/hooks/tests/block-egress.test.sh` — arm `AC-E007-V1`, comparing non-identity fields only | at least one differing field other than `ts`, `input_digest` and `cwd` · note: a whole-record comparison is GREEN at `main` (the digest differs), which is why the method excludes identity fields |
| #6201 | AC-5 | Hermetic copy of the deployed hook under `.mode=enforce` (block log) and `.mode=warn` (warn log); payloads: an unterminated-quote gh-api write, a well-formed heredoc-carrying gh-api write, and two structurally identical malformed commands differing only in literal text, each carrying a planted sentinel. After the Stage-12 republish and Check 79 content MATCH for the hook: `E007_D_HOOK_SRC_DIR=~/Claude/.claude/hooks bash core/hooks/tests/block-egress.test.sh` — arms `AC-E007-V1` and `AC-E007-V5` (both modes) and `AC-E007-V2`, each in its own sandbox holding a copy of the deployed hook | the first pair differs in at least one field other than `ts`, `input_digest`, `cwd` in both logs · the near-miss pair differs in 0 feature fields · sentinel count 0 · control: a count of `BLOCK-EGRESS-007` over the same new rows returns at least 1 · method control: the same arms at slice 2a, against the pre-fix hook, FAIL — the first pair agreed in every non-identity field |

**AC baseline** (replaces the Stage-4 plan's, per the Decision Recorded amendment):

`ac_baseline: { #5592: 5, #6201: 5, read_at: 0c759aaf, amended: 2026-09-24 Stage-4 gate }`

Re-read at Commit 0: both issue bodies carry exactly five `- [ ]` criteria each.

### Release-Level Verification

- [ ] File integrity: `bash -n core/hooks/block-egress.sh` and `bash -n core/hooks/allowlist-add.sh`; the full hook suite shows 0 FAIL and an arm count at least its pre-change count
- [ ] Install regression suite: `bash core/deploy/tests/run-install-regression.sh` (selected by row 5, because `core/config/allowlists/**` changed)
- [ ] CIAC-1..3 (below)
- [ ] Index freshness after each fragment edit: `python3 core/deploy/tools/build-hook-registry.py --check`, exit 0
- [ ] ADR number integrity and durability: `python3 release/tools/check-adr-numbers.py` passes; the ADR durability lint reports no finding on the added records
- [ ] Output contract: the D-decisions and FS-6201 are recorded in this plan

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#5592 × #6201 on the -007 refusal-record contract — `egress_007_verdict` → `apply_block` → `log_block`/`log_warn` in `core/hooks/block-egress.sh`):** Under `.mode=enforce`, one hermetic fixture command per -007 cause (`not-allowlisted`, `unresolvable`, `unparseable`, `no-path`) writes exactly one `block-log.jsonl` record. Each record has `rule` `BLOCK-EGRESS-007` and a recoverable cause token. The `not-allowlisted` record still carries the denied path after #5592's scope change. The `unparseable` record carries the FS-6201 fields. No record carries command text. *Method:* the release's hermetic record-contract arm in `bash core/hooks/tests/block-egress.test.sh` (authored at Stage 6; its emitted verdict is read at Stage 9). Null limb: `grep -c` for the planted sentinel over the sandbox block log → 0 · control: `grep -c 'BLOCK-EGRESS-007'` over the same sandbox block log → 4. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5592 × #6201 on `core/hooks/tests/block-egress.test.sh`):** Every arm either card adds is hermetic (own sandbox allowlist, own `.mode`, payload cwd inside the sandbox), so the new `AC-E007-D*` / `AC-E007-V*` PASS set is identical in a bare checkout and under the CI layout. *Method:* run `bash core/hooks/tests/block-egress.test.sh` in a bare checkout, then again after `TESTS_DIR="$(bash core/hooks/tests/setup-ci-layout.sh)"`, and diff the `PASS: AC-E007-D` and `PASS: AC-E007-V` lines between the two runs → no difference · control: the pre-existing ambient-dependent arm `gh api -X POST repos/<handle>/pmo-platform/issues allows (allowlisted)` FAILs in the bare checkout, per the suite's own header, proving the bare run really was bare. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#5592 × #6201 on the added lines of `core/hooks/block-egress.sh`):** No line either card adds pipes into a short-circuiting reader. *Method:* `git diff --unified=0 <release-base>..HEAD -- core/hooks/block-egress.sh | python3 -c 'import re,sys; print(sum(1 for l in sys.stdin if l.startswith("+") and not l.startswith("+++") and re.search(r"[|]\s*(\"\$(GREP|HEAD)\"|/usr/bin/(grep|head))\s+-(q|m|c|1)", l)))'` → 0 · control: the same regex over `git show <release-base>:core/hooks/block-egress.sh` → **6** at `0c759aaf`, including the `matches()` pipe · specificity (checked at planning): a here-string `"$GREP" -q` line and a pipe into `tr` → 0, while a planted pipe into `"$GREP" -qE` → 1. *Graded at Stage 9 QC3.5 on the merged PR.*

**Population enumerated** for cross-issue cohesion: shared file, shared function or seam, shared test harness, shared record schema, shared doc surface. Index freshness is a per-card check (each card edits the fragment), kept under Release-Level Verification.

---

## Quota Budget

**Verdict:** **PASS** (per `quota-budget-protocol.md` Checkpoint A). Parallel-eligible spokes: Stage 5: **2** · Stage 7: **2** · Stage 8: **2**. Per-spoke cost estimate: `size:S` → the lowest ordinal band. The remaining usage-window envelope was **UNSTATED** at planning, so the conservative default applies and `W_max` is **2**; the worst parallel batch is 2 × lowest band, which fits with no split. Stage 6 is serial by D-Concurrency. Checkpoint B re-validates at every launch.

---

## Release Class declaration

**`novel`** — switched from `routine` at Stage 5 under the operator's Stage-4 pre-authorization, which named the switch as firing at the first Stage-5 D-class decision or ADR. #6201's design rendered D5-4 first (and #5592's rendered D5-1..D5-3 and an ADR), so triggers (b) and (c) of the `novel` class fire.

- **Differentiation posture:** Engagement **Standard** · Stage 9 review **Deep** · Stage 5 bias **ALL** · outcome window **30-day**.
- **Size bound:** `effective_pts: raw 4 × 1.15 = 5 — under band vs 15-25`.
- **Why not `hotfix`:** hotfix's disqualifier is a fix that also introduces a new protocol, and this release introduces two conventions; hotfix's Light Stage-9 depth puts design discussion out of scope, the wrong posture for a security control.

---

## Release Outcome Statement

**AFTER** — block-egress applies each allowlist row only to its own match domain, so a gh-api write whose path merely ends in host-shaped text is no longer allowlisted by a host row; and every BLOCK-EGRESS-007 `unparseable` refusal record, in the warn log and the block log alike, carries non-identifying structural features, so a correct refusal and a false one can be told apart afterwards.

**BEFORE** — Host and path rows share one scope-less matcher, so a host wildcard admits a path suffix; every `unparseable` record carries the same constant evidence string, so the rule's false-positive rate cannot be audited.

**Actor(s):** platform engineering session; the deployed block-egress hook.

**Success Indicator:** the Reproduction Steps write is DENIED by the deployed hook at enforce while a curl upload to a managed host row passes; and a malformed and a heredoc-carrying unparseable refusal produce records differing in a field other than ts / input_digest / cwd — each observed RED at the pin before its fix and GREEN after.

---

## Tier-A Activated Design Artifacts

| Artifact path | Flow class | Trigger | Activation tier | G-CL6 obligation |
|---|---|---|---|---|
| `core/rules/bypass-mode-readiness/block-egress.md` § "Allowlist row scope — who writes a row, and which rule reads it" (embedded; marker `<!-- design-artifact: flow-class=data-flow; name=egress-allowlist-row-scope; depicts=core/config/allowlists/egress-allowlist.txt,core/hooks/block-egress.sh,core/hooks/allowlist-add.sh -->`) | data-flow | #5592 changes a contract file — the egress allowlist's row grammar — with at least two producers (the composition writer; `allowlist-add.sh` and operator hand-edits) and at least two consumers (-004 and -007, and the helper's duplicate check) | A — NEW | Stage 13 G-CL6 reads this declaration and confirms the embedded artifact exists with its marker and that its `depicts` paths resolve |
| `core/ADRs/ADR-205-a-refusal-record-carries-structure-never-the-command.md` § "Data flow — the refusal-record contract" (embedded; its declaration marker — flow-class `data-flow`, name `refusal-record`, depicting `core/hooks/block-egress.sh` — sits directly below that heading) | data-flow — producer and consumer tables plus Mermaid, since there are at least two actors | #6201 creates a contract, the `unparseable` refusal record's field set, with two producers (`log_warn`, `log_block`) and three consumers (the drain counts and record-shape census, the specificity reading, the hook suite's contract arms) | A — NEW; embedded in its parent ADR | Stage 13 G-CL6 reads this declaration and confirms the embedded artifact exists with its marker and that its `depicts` path resolves; the artifact is refreshed whenever the field set changes — a `schema_version` bump |

---

## Rollback Strategy

| Issue | Method | Complexity |
|---|---|---|
| #5592 | `git revert -m 1` of the merge, then republish the hook bundle and let the update path regenerate the allowlist's managed section | **Low.** A scope directive is a comment line to the prior matcher, so the prior matcher reads the new-format file exactly as it read the old one and a revert restores the prior grant set; nothing in the operator region needs rewriting. Publish-order skew is benign in both directions (arm D9) |
| #6201 | The same revert | **Low.** Written records keep their keys; new ones simply stop carrying them |

**Whole release:** a partial revert per slice; a full restore by reverting the merge; a forward fix preferred for anything well understood. **A claimed version tag is retained and recorded, never deleted** — version tags are host-protected.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/hooks/block-egress.sh` | workspace hook tier `.claude/hooks/block-egress.sh` | installer hook refresh (update path) | **Check 79 content comparison** — never the publisher's exit status |
| 2 | `core/config/allowlists/egress-allowlist.txt` | workspace `.claude/egress-allowlist.txt` | update-path composition regeneration: managed section regenerated, OPERATOR ADDITIONS preserved | the managed section equals main's token-resolved source; the operator region is byte-identical before and after |
| 3 | `core/hooks/allowlist-add.sh` | workspace hook tier `.claude/hooks/allowlist-add.sh` | installer hook refresh (update path) — **UNCONDITIONAL** (S5-R1: the deployed copy on the authoring instance is stale) | **Check 79 content MATCH** |

**Repository-only surfaces** (no deployed copy to sync): the two suites (CI- and agent-executed from the repo), the registry fragment and its generated index (not mirror-pair members), `docs/UPDATE.md`, the ADRs and this plan.

**`deliverable_state: deployed-copy-synced`** — reached at Stage 12 when rows 1–3 verify by content.

**Schema migrations:** N/A — enumerated over {allowlist rows, log records, config keys}. No operator row is rewritten (the package never touches the operator region); log records are append-only, and the new fields are additive.

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **One path added to the operator-locked File Change Matrix:** `core/ADRs/ADR-204-egress-allowlist-rows-declare-their-match-domain.md`. It originated at Stage 5 (#5592's design named the record under the slug-token discipline); the matrix ratified at the Stage-4 gate carried no path for it | #5592's Collective Review scope-lock ("ADR — authored at Engineering") | **APPLIED** at `8652a57d`. The row is in § File Change Matrix under *Decision records*; the number is claimed against the mainline anchor (203 → 204), and the detector reports it `BINDS` |
| **DEV-2** | **A second path added:** `core/ADRs/ADR-205-a-refusal-record-carries-structure-never-the-command.md`, originated at Stage 5 in #6201's design | #6201's Collective Review scope-lock | **APPLIED** at `a8da701f`. Declared at Commit 0 in the `NNN` placeholder form the matrix contract recognizes; numbered at creation against the mainline anchor — 203, with 204 held by this release's other record, so 205 — and the detector reports it `BINDS` |
| **DEV-3** | `CONDITIONAL:D5-1-OPTION-B` — **NOT DELIVERED** (3 rows: `core/config/allowlists/<per-domain-allowlist>.txt` add, `core/deploy/composition-surface-manifest.sh` edit, `core/rules/bypass-mode-readiness/_cross-cutting.md` edit). The condition resolved **false**: D5-1 = (A), not option (b) | #5592's Collective Review scope-lock (D5-1 A) | **RECORDED.** No file under the three rows is touched; the `_cross-cutting.md` allowlist table stays accurate (its counts of 8 and 9 are unchanged) |
| **DEV-4** | `CONDITIONAL:D5-1-FRAGMENT-SCOPE` (2 rows: the fragment and its generated index) and `CONDITIONAL:D5-2-HELPER-SCOPE` (3 rows: the helper, its suite, `docs/UPDATE.md`) are **promoted in this commit** — both conditions resolved true at the Collective Review, before Commit 0 | The matrix authoring contract (a fired conditional is promoted in the same commit its condition resolves) | **APPLIED.** The rows are unconditional in § File Change Matrix, each carrying an in-fence comment naming its source token |
| **DEV-5** | The Stage-4 plan's CONDITIONAL docs slice (slice 3) is folded into slices 1b and 2b — each card edits the fragment and regenerates the index in its own fix slice | Stage-5 designs (both cards edit the fragment; the second edit regenerates again) | **APPLIED** — § Implementation Sequence |
| **DEV-6** | **AC-5's verification method is refined; the AC text is unchanged.** The deployed operator region held 0 rows at Stage 5, so a row "taken from each region" cannot be taken from this deployment; the method plants the operator-region rows through the sandboxed helper — one host wildcard with no `--scope`, one `--scope gh-api-path` path row — which also exercises D5-2 end to end | #5592's Collective Review scope-lock (spoke addition accepted) | **APPLIED** — § Verification Plan, #5592 AC-5 |
| **DEV-7** | **Release class `routine` → `novel`** | The operator's Stage-4 pre-authorization, executed at the first Stage-5 D-class decision; ratified at the release-level Collective Review | **APPLIED** — § Release Class declaration |
| **DEV-8** | **Four adversarial-review refinements folded into #5592's design:** the corrected every-row claim with the undeclared-slashless residual named; upgrade in place for a `--scope` re-add of a bare row; the curl-only host wording; one added arm | #5592's Collective Review scope-lock | **APPLIED.** (1) The allowlist header, the fragment's data-flow section, `docs/UPDATE.md` and the ADR's Consequences each name the residual and no longer claim the class closed for every row; the header's top line reads "a declared row". (2) `allowlist-add.sh --scope` upgrades a bare row in place (arms T-17, `AC-E007-D10u`). (3) Every host-domain statement says curl, and states that wget uploads are denied unconditionally. (4) `AC-E007-D10` pins the residual, with its control `D10-c` |
| **DEV-9** | #5592's ADR is authored **Accepted**, where the Stage-5 draft read `Proposed — flips to Accepted at the scope-lock`: the draft assumed authorship before the lock, and the lock that ratifies it preceded Stage 6 | #5592's Collective Review scope-lock ("Proposed → Accepted at this lock") | **APPLIED** at `8652a57d` |
| **DEV-10** | **The new arms are hermetic one step past the design's model.** Beyond their own allowlist, `.mode` and cwd, every `AC-E007-D*` hook invocation pins the scope root (`PMO_SCOPE_GUARD_ROOT`) to its sandbox and the master-enable config root (`PMO_PLATFORM_CONFIG_ROOT`) to an empty sandbox directory, and counts log records with `jq -s length` rather than lines | Stage-6 engineering judgement, surfaced — CIAC-2 requires a verdict independent of the invocation layout, and the runner exports both variables while an operator environment may export the workspace root | **APPLIED — minor.** Measured: the D-family verdict set is identical in a bare checkout and in the CI layout, directly and under the runner (§ Verification Evidence) |
| **DEV-11** | **Upgrade in place is confined to the helper's writable span.** Refinement (2) names the behaviour, not its bound. The helper declares a bare copy of the entry only inside the OPERATOR ADDITIONS region (or anywhere in a file carrying no marker text); a bare row in a managed section is left alone and the declared pair lands in the region | Stage-6 engineering judgement, surfaced: the managed section belongs to the composition writer, and an edit there is tampering the next update detects (ADR-014) — so an unbounded upgrade would have converted an operator's `--scope` run into a discarded file | **APPLIED — minor.** Pinned by T-18 (the managed section stays byte-identical) and T-19 (the marker-less case) |
| **DEV-12** | **CIAC-2's Stage-4 control arm discriminates only under the runner.** Its stated control — the ambient allowlisted arm FAILs in a bare checkout — holds when the suite runs under `test-runner.sh`, which exports `PMO_SCOPE_GUARD_ROOT=/`. Under a direct invocation the workspace scope guard makes the ambient hook inert at the ambient arms' cwd `/tmp`, so that arm PASSES vacuously; there the must-block ambient arms (for example `curl POST to attacker.com blocks`) are what FAIL | Stage-6 finding: the control's premise predates the workspace scope guard | **RECORDED.** Both shapes were run: the D-family PASS set is identical across all four (bare / CI layout × direct / runner), and the control FAILs under the bare runner. The Stage-9 grader should read the control under the runner |
| **DEV-13** | **The A1–A2 checkpoint is presented after the fact.** The Stage-6 shard asks for A1–A2 to be presented before B1; the hub's brief directed Commit 0 → slice 1a → slice 1b end-to-end, under the operator's scope-lock (D1) and the Collective Review design lock | The hub's Stage-6 brief, under the operator's standing plan approval | **RECORDED.** A1 (entry contract: PROCEED — every input present, the stamp manifest resolvable) and A2 (container determination, above) are in this file and in the Stage-6 output comment |
| **DEV-14** | **Control arms beyond the design's arm table.** The design named D1..D10's subjects; the delivered family also carries each subject's control — `D1e`, `D1s2`, `D1w2`, `D2m1`..`D2m3`, `D4-plant`, `D5a-c1`, `D5a-c2`, `D6s-c`, `D6w-c`, `D8c`, `D9h`, `D9p`, `D10-c`, `D10p`, `D10u`, `D10u2` — and the helper suite carries T-17..T-19 beyond the design's T-10..T-16 | Probe-validity discipline (a verdict whose arm cannot fail is not evidence) and the lock's refinements | **APPLIED — minor.** No arm tests anything outside #5592's locked design |
| **DEV-15** | **#6201's record is authored `Proposed`**, where #5592's was authored `Accepted` (DEV-9). #6201's scope-lock locked the record's content — with its Decision item 4 scoped to this record — and rendered no acceptance, and the `Proposed → Accepted` transition is a Tier-0 ratification the Stage 13 Close ratification beat performs | The ADR status enum in `core/ADRs/README.md`; Stage 13's ratification beat | **APPLIED — minor.** Stage 13 presents {{ADR:a-refusal-record-carries-structure-never-the-command}} for per-record ratification |
| **DEV-16** | **V7(c)'s method is refined; its assertion is unchanged.** The design pads the correct refusal past the 1,048,576-character cap, but no such payload reaches the -007 branch on the reference platforms: the hook's input validation hands the whole payload to an external printf, which the argument-size limit refuses, and the hook fails closed there. The `skipped` path is therefore proven by a lowered-cap mutation copy (`AC-E007-V7c`, cap 16, with its guard triple), and the real-cap payload is kept as a control (`AC-E007-V7c0`: exit 2 on whichever path; were -007 reached, both computations would have to read `skipped`) | Stage-6 engineering judgement, measured — V7c0 observed the input-validation path at slice 2a | **APPLIED — minor** |
| **DEV-17** | **Arms beyond the design's arm table, each tied to a locked refinement.** `AC-E007-V7b2` (an oracle that runs and exits 1 records `unavailable`); `AC-E007-V7d` in both writers, its mutation at the call site so non-JSON features reach each writer's fallback, asserting the lock's correction (`hook_build` kept, `features` absent); `AC-E007-V7e` (a build id that cannot be computed reads `unknown`); `AC-E007-V7f` (a failing digest step can no longer cost the deny — RED at the unchanged hook: exit 1 and no record) with its byte-identity control `AC-E007-V7g`; and `AC-E007-V9`, CIAC-1's record-contract arm. Each mutation's guard triple is asserted as one arm; the digest mutation's liveness is read at warn, because every enforce-mode deny passes through the mutated step | The lock's refinements, R6, CIAC-1, and probe-validity discipline | **APPLIED — minor.** No arm tests anything outside #6201's locked design |
| **DEV-18** | **The V family is hermetic one step past its design's harness, by reuse.** The design's runner pinned neither the scope root nor the master-enable config root. The family runs through the D family's runner, which pins both per invocation (DEV-10), so an environment exporting the workspace root cannot make an arm vacuous. The reuse also brings `E007_D_HOOK_SRC_DIR`, which points the family at a deployed hook tier — this card's AC-5 method at Stage 12. `E007_V_FIXTURE_DIR`, inert unless set, exports the fixture commands byte-exact for the cross-shell parse record | CIAC-2; Stage-6 engineering judgement | **APPLIED — minor.** The D and V PASS sets are identical in the bare checkout and the CI layout (§ Verification Evidence) |
| **DEV-19** | **The oracle label reads `unknown` when the configured oracle is not the running shell.** The lock names the oracle from `BASH_VERSINFO`, which describes the oracle only while the oracle is the running bash — true by construction. The label compares the two, so it can never name a parser that did not run (pinned by `AC-E007-V7b`) | The lock's oracle-naming refinement | **APPLIED — minor** |
| **DEV-20** | **Two reconciliations beyond the design's hunks.** The hook comment directly above the `unparseable` call site asserted the two claims the lock corrects in the registry fragment — that a comment cannot produce the cause, and that the class is scoped to input that cannot execute; it is reconciled in place, comment-only. The fragment's Cannot-evaluate row said a comment cannot produce `unparseable`, which the corrected paragraph beneath it contradicts for a comment the scanner does not recognize; the row now says a comment it recognizes cannot, and a well-formed command it mis-models can | The lock's in-place fragment reconciliation, applied per reconcile-don't-annotate | **APPLIED — minor** at `4f8d58a8` (hook comment) and `a8da701f` (fragment row) |
| **DEV-21** | **The near-miss pair carries the planted sentinel, and #6201's AC-2 and AC-5 method cells name the delivered arms.** The plan's AC-5 method plants a sentinel in every payload, the near-miss pair included; the design's near-miss fixtures carried none, so both now carry it at the same position — still structurally identical and equal-length — and `AC-E007-V5` asserts its absence with the rule id as the control. The AC-5 cell gains the deployed-tier command for Stage 12; no criterion's text changes | AC-Binding (an amended or refined method obliges its row in the same change) | **APPLIED — minor** at `01487a20` (the fixture) and in this plan |

---

## Documentation Impact

| Issue | Declared docs | Status | Commit | Notes |
|---|---|---|---|---|
| #5592 | the egress allowlist header, which documented its patterns as host-scoped (the card's Documentation Impact) | **UPDATED** | `584ff6a5` | the header states the two-domain grammar the matcher applies, the curl-only host check and the undeclared-slashless residual; the matcher and the header agree by execution (arms D5a and D5b) |
| #5592 | `core/rules/bypass-mode-readiness/block-egress.md` (+ generated index) · `docs/UPDATE.md` § 4 · {{ADR:egress-allowlist-rows-declare-their-match-domain}} | **UPDATED** / **CREATED** | `8652a57d` | the fragment's -007 table gains an allowlist-scope row and the embedded data-flow artifact; the index is regenerated (Check 38 fresh); UPDATE.md gains the directive form and the `--scope` example; the ADR is new |
| #6201 | the `log_block` comment block (the writers' record contract, the card's Documentation Impact) · the registry fragment's reconciled claims (+ generated index) · {{ADR:a-refusal-record-carries-structure-never-the-command}} | **UPDATED** / **CREATED** | `4f8d58a8` · `a8da701f` | the `log_block` comment now describes what a record actually carries — the plain template for every rule, plus the feature set and the producing build for the `unparseable` class — instead of claiming that `evidence` separates a genuine catch from a false positive for every cause; the fragment's two untrue claims are reconciled in place and it gains reading guidance for this class; the index is regenerated (Check 38 fresh); the ADR is new |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification, extended at Stages 7 and 8.*

| Check | Result |
|---|---|
| **Commit-0 version half** | `git fetch --tags origin` and `git fetch origin main` (exit 0); the adapter's dry-run recomputes **`v4.68`** for bump-class `minor`; the slot is free on all three `claimed_set()` arms (probe record above). **No HALT** |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp egress-hook-batch` → **exit 0**, *"verify-stamp OK — egress-hook-batch carries a resolvable stamp manifest; plan-only manifest"*. Exactly one double-brace `RELEASE_VERSION` placeholder in this file (the Header `**Version**` cell); the two other mentions use the named form |
| **Plan-driven executor at Commit 0** | `release/tools/verify-release-plan.sh --format=md --merge-base origin/main --stage4-comment <the Stage-4 plan comment, both parts> <this plan>` (pre-commit): **provenance-survival 4 of 4 PASS** — the label is present in the 5.7 form, Form X, and the Commit-0 set-difference against the Stage-4 comment reports `prov-no-loss` (5 of 5 survival elements present). **FCM coverage PASS** — 29 declared rows, 29 interpreted, 0 uninterpreted, 0 pathless. The conditional option-(b) ADD reads `conditional-not-fired (recorded)` against DEV-3. The three unconditional ADDs read `declared-add-not-delivered` at that instant, by construction: this plan was not yet committed and the ADRs land at slices 1b and 2b. The per-issue `bash` rows read `unclassified-method` by the executor's design (its runnable-verb set is closed to read-only queries); CIAC-2 and CIAC-3 are SKIP for the same reason, and CIAC-1 is ERROR because its record-contract arm is not yet authored — see § Implementation Sequence |
| **Plan-driven executor after #5592's slices** | the same invocation over this plan with this record added, at head `8652a57d`: **8 PASS / 1 FAIL / 2 SKIP / 11 ERROR** (Commit 0: 6 / 3 / 2 / 11). The FCM rows for this plan and for the new egress record moved to `declared-add-delivered`. The one FAIL is #6201's record, `declared-add-not-delivered` until slice 2b. The 11 ERROR rows are the Commit-0 set, unchanged and for the same reasons. Provenance survival is still 4 of 4 PASS |
| **Slice 1a — RED at `0c759aaf`** (`d6b7fcc1`) | `bash core/hooks/tests/block-egress.test.sh` in a bare checkout, against the unchanged hook, allowlist and helper: **20 of 49** `AC-E007-D*` lines FAIL — D1, D1e, D1q, D1s, D1s2, D1w, D1w2, D3, D5a, D5b, D8, D9, D4a, the four D7 `repro` arms, D10p, D10u, D10u2 — and 29 PASS (the already-correct controls). Observed: D1 `exit=0 (want 2); block-log records +0 (want +1)`; D5a `rows=15 declared=0 undeclared=15`; D5b every host row `host-grant=1 path-grant=1`, and `graphql[host-grant=1 path-grant=1]`. `bash core/hooks/tests/allowlist-add.test.sh`: **11 of 11** new assertions FAIL (for example T-13 `got rc=0` against an expected refusal) and every pre-existing arm passes. The D-family verdict set is identical in the CI layout |
| **Slice 1b — GREEN** (`584ff6a5`) | the same suites after the fix: **49 of 49** `AC-E007-D*` PASS; the helper suite **34 of 34** PASS (no RESIDUAL — `compose.py` resolved, so the extraction arms ran); the pre-existing `AC-E007-M1..M6` mutation differential still PASS, including M3 (an undeclared literal-first-segment path row is still a path candidate); the bare direct run's non-D failure set is byte-identical before and after the fix (its 69 ambient arms, unmoved) |
| **Full hook harness, CI layout (selection-map row 3)** | `setup-ci-layout.sh`, then `test-runner.sh`, at head `8652a57d`: **AGGREGATE PASS=1640, FAIL=0** across 24 suites. `block-egress.test.sh` 200 / 200 — 151 pre-existing arms plus 49 new, so the arm count rises from 151 to 200. `allowlist-add.test.sh` 25 / 25 in that layout (its compose-dependent arms skip-and-disclose there; they ran in the bare checkout). `test-run/suite-pass` emitted for `suite:hook-suite` (`stage=6`, `actor=spoke:#7555`) |
| **Install regression (row 5)** | `bash core/deploy/tests/run-install-regression.sh` → **2045 passed, 0 failed — VERDICT PASS**; the runner emitted its own `test-run/suite-pass` event |
| **CIAC-2** | the `PASS: AC-E007-D` lines are identical between the bare checkout and the CI layout (49 = 49), directly and under the runner, which forwards 0 D-family FAIL lines in either layout. Control: under the runner in the bare checkout, the ambient `gh api -X POST repos/<handle>/pmo-platform/issues allows (allowlisted)` arm FAILs, so the bare run really was bare (DEV-12 records why the control needs the runner) |
| **CIAC-3** | the Stage-4 regex over the added lines of `core/hooks/block-egress.sh` (`git diff --unified=0 origin/main`) → **0** of 59 added lines; control: the same regex over `origin/main`'s file → **6**, the value recorded at planning. A local pre-check of the SIGPIPE-idiom class over all four changed shell files (858 added lines) → 0 flagged; its planted control flags 5 of 5 must-flag forms and 0 of 3 near-misses — its first version missed the `sed …q` and `awk …exit` forms and was repaired before its result was used |
| **AC-5 method against the deployed tier (its control)** | the D7 arms pointed at the **currently deployed, pre-fix** hook tier and composed allowlist (`E007_D_HOOK_SRC_DIR` / `E007_D_COMPOSED_ALLOWLIST`, copied read-only into sandboxes): the four `repro` arms FAIL and the eight curl / near-miss arms PASS — the live exposure, measured on the deployed artifact. `AC-E007-D4-plant` also FAILs there: the stale deployed `allowlist-add.sh` planted **0** of 3 rows inside the operator region, which is S5-R1 reproduced end to end. The deployed hook equals `origin/main`'s by content; the deployed helper does not. The post-republish run is Stage 12's |
| **Revert safety, measured** | the `origin/main` hook, run by the suite's own D5b probes over the **new-format** managed rows, grants each row exactly what it granted over the pre-change file: **0 of 30** verdicts differ. Sensitivity: the new hook over the new file differs from those grants on 6 rows (the five host rows lose their path grant; `graphql` loses its host grant). The first comparison was a broken probe — D5b lists only disagreeing rows, so the two listings had different shapes — and was repaired by joining per row |
| **File integrity** | `bash -n` over `block-egress.sh`, `allowlist-add.sh` and both suites → clean |
| **Allowlist invariants** | the 15 rows are identical to `origin/main`'s, in order; 15 directive lines, each directly above a row; no line begins with `# ===` |
| **Index freshness (Check 38)** | `build-hook-registry.py --check` → drift (exit 1) after the fragment edit, before regeneration; in sync (exit 0) after; the index gains exactly the fragment's 22 lines |
| **Pre-merge required subset** | `deploy.sh --check-required-subset` → hook-registry index FRESH · bundle-metrics gate integrity PASS · mirror-pair parity PASS · rules budget PASS |
| **ADR number integrity** | `check-adr-numbers.py` → PASS (204 ADRs, contiguous 001..204, no duplicates); `renumber-adr.py --detect` → `CLAIM ADR-204 … BINDS` |
| **ADR durability** | `check-adr-durability.py --files <the new record> --diff-base origin/main` → SCANNED 1, COUNT 0; its `--self-test` → 138 / 138 |
| **Issue-reference validity** | `check-issue-ref-validity.sh --base origin/main --head HEAD --resolver gh` → every `#N` in the changed markdown resolves in-repo and sits in a reference block; its `--self-test` (the 8-cell S/Z matrix plus a mutation arm) → PASS |
| **Dead-file reference and plan depth** | `check-release-links.py` over the five changed markdown files with the CI flags → 0 broken; `--plan-depth-lint` over this plan → 0; its `--self-test` → OK (the lint scopes and fires correctly) |
| **Doc-link integrity** | `check-doc-links.py --require-targets` over the four changed durable and docs files → no findings; its `--self-test` → 11 fixtures passed |
| **ADR slug-token stamp (dry run)** | `renumber-adr.py --stamp` without `--apply` → refuses, with zero mutation, on exactly one site: this plan's citation of #6201's record, whose file does not exist yet. Every other token site resolves. #6201's Engineering spoke authors its record under that exact slug, or re-points the citation |
| **Skill-package freshness** | **N/A — measured:** `build-skill-packages.sh --skills-for-paths` over the ten changed paths returns no skill; sensitivity: the same resolver on a known injected canonical returns 6 |
| **ADR index freshness** | **N/A — this release adds no record under `release/ADRs/`**; the new record is under `core/ADRs/`, which has no projector |
| **Mirror-pair parity** | **N/A — no mirror-pair member is added, removed or renamed** (the registry fragment and index are not members); the required subset's parity check passes |
| **#6201 slice 2a — RED at the unchanged hook** (`3b24dfed`) | `bash core/hooks/tests/block-egress.test.sh` in a bare checkout, with #6201's functions still byte-identical to `origin/main`: **21 of 28** `AC-E007-V*` lines FAIL — V1 (both modes), V3, V4, V5 (both modes), V6, V7b / V7b2 / V7c / V7d (both modes) / V7e and their guards, V7f, V8, V9 — and 7 PASS: V2, V2m1–V2m3 (the armed-red leak, each prediction printed before its run), V7c0, V7f-guard and V7g. Observed: V1 `the two records agree in every non-identity field`; V3 `block-log=[[],false] warn-log=[[],false]`; **V7f `exit=1, want 2 … unparseable records +0` — with the digest step broken, an enforce-mode refusal exited non-blocking and wrote no record**; V9 failed its field-set limb alone, every other contract limb already holding. Every pre-existing arm unchanged: 131 PASS and the 69 ambient FAIL arms, as at the pre-change run |
| **#6201 slice 2b — GREEN** (`4f8d58a8` · `a8da701f` · `01487a20`) | the same suite: **28 of 28** `AC-E007-V*` PASS and 49 of 49 `AC-E007-D*`; outside the V family the PASS set (131) is byte-identical to the pre-change run and the FAIL set is the same 69 ambient arms (DEV-12) |
| **Full hook harness, CI layout, at `01487a20`** | `setup-ci-layout.sh`, then `test-runner.sh` → **AGGREGATE PASS=1668, FAIL=0** across 24 suites, with 0 forwarded FAIL lines; `block-egress.test.sh` 228 / 228 — the 200 of #5592's slices plus these 28. `test-run/suite-pass` emitted and read back (`stage=6`, `actor=spoke:#7556`, `passed:1668; failed:0`) |
| **CIAC-1** | `AC-E007-V9`: one fixture per -007 cause, at enforce, into a fresh sandbox block log → exactly one record each; rule `BLOCK-EGRESS-007` on every record; cause tokens `no-path`, `not-allowlisted`, `unparseable`, `unresolvable`; the `not-allowlisted` record keeps `path=repos/evil-org/secret/issues`; the field set on the `unparseable` record alone. Null limb: the planted sentinel over that block log → **0 lines**; control: `BLOCK-EGRESS-007` over the same log → **4 lines**. RED at slice 2a on the field-set limb only; GREEN from slice 2b |
| **CIAC-2, after #6201's slices** | the 77 `PASS: AC-E007-D` and `PASS: AC-E007-V` lines (49 + 28) are byte-identical between the bare checkout and the CI layout at `01487a20`, with 0 D or V FAIL lines in either. Control, per DEV-12: under the bare-checkout runner the ambient allowlisted arm FAILs while the runner forwards 0 D or V FAIL lines, so the bare run really was bare |
| **CIAC-3, after #6201's slices** | the Stage-4 regex over the added lines of `core/hooks/block-egress.sh` against `origin/main` → **0** of 269 added lines (both cards'); control: the same regex over `origin/main`'s file → **6**; specificity: a planted pipe into `"$GREP" -qE` → 1, while a here-string `"$GREP" -q` line and a pipe into `tr` → 0 |
| **File integrity, #6201** | `bash -n core/hooks/block-egress.sh` and `bash -n core/hooks/tests/block-egress.test.sh` → clean |
| **Oracle cross-shell agreement (R10), authoring host** | the ten fixture commands the V family sends, exported byte-exact through `E007_V_FIXTURE_DIR`: `bash -n` and `zsh -n` agree on accept-versus-reject for **10 of 10**. The correct refusal and the near-miss pair are rejected by both (bash exit 2, zsh exit 1); the false-refusal, escaped-quote and five heredoc fixtures are accepted by both (exit 0). The two rejection statuses differ, which is why the verdict mapping is oracle-specific and the record names its oracle. The fixtures were authored for the arms, not drawn from the refused population |
| **Index freshness (Check 38), #6201's fragment edit** | `build-hook-registry.py --check` → drift (exit 1) after the fragment edit and before regeneration; in sync (exit 0) after |
| **Pre-merge required subset, after #6201's slices** | `deploy.sh --check-required-subset` → hook-registry index FRESH · bundle-metrics gate integrity PASS · mirror-pair parity PASS · rules budget PASS |
| **ADR number integrity and claim, #6201** | `check-adr-numbers.py` → PASS (205 ADRs, contiguous 001..205, no duplicates); `renumber-adr.py --detect` → `CLAIM ADR-205 … BINDS` |
| **ADR durability, #6201** | `check-adr-durability.py --files <the new record> --diff-base origin/main` → SCANNED 1, COUNT 0; its `--self-test` → 138 / 138 |
| **Issue-reference validity, #6201's changed markdown** | `check-issue-ref-validity.sh --base origin/main --head HEAD --resolver gh` → every `#N` resolves in-repo and sits in a reference block; its `--self-test`, mutation arm included → PASS |
| **Dead-file reference, #6201's changed markdown** | `check-release-links.py` with the CI flags over the new record, the fragment and the index → 0 broken. Sensitivity: an in-repo scratch file carrying a broken link, scanned in the same call → 1 broken across 1 file, after which the scratch file was removed. An out-of-repo plant read 0, because the tool drops every file outside the repository root — a broken probe of that shape, recorded and not relied on. Its `--self-test` → OK |
| **Doc-link integrity, #6201** | `check-doc-links.py --require-targets` over the fragment, the index and the new record → no findings; its `--self-test` → 11 fixtures passed |
| **Skill-package freshness, #6201** | **N/A — measured:** `build-skill-packages.sh --skills-for-paths` over #6201's six changed paths returns no skill; sensitivity: the same resolver on an injected canonical returns 6 |
| **Install regression, #6201** | **N/A — #6201's slices change no path under selection-map row 5** (`core/config/allowlists/**` is #5592's; its 2045 / 0 run stands) |
| **AC3 disposition (#6201 AC-3)** | the named read is § Decision Record → AC3 disposition: a reasoned write-off bound to deploy time and producing build, with the count re-stamped at Stage 12 by the same predicate |
| **ADR slug-token stamp (dry run), after #6201's slices** | `renumber-adr.py --stamp` without `--apply` → **every token resolves**: 14 tokens across 4 files, zero mutation. The one refusal recorded at #5592's slices — this plan's citation of a record that did not yet exist — is gone |
| **Plan-driven executor after #6201's slices** | the same invocation over this plan, at code head `01487a20`: **9 PASS / 0 FAIL / 2 SKIP / 11 ERROR** (after #5592's slices: 8 / 1 / 2 / 11). The one FAIL — this card's record, `declared-add-not-delivered` — now reads `declared-add-delivered`. The 10 per-issue `bash` rows are ERROR by the executor's design (`unclassified-method`; its runnable-verb set is closed to read-only queries), and CIAC-2 and CIAC-3 SKIP for the same reason. CIAC-1 is still ERROR, for a different reason than at Commit 0: its arm now exists (`AC-E007-V9`, PASS in the suite), but its null limb's `grep -c` names the suite's ephemeral sandbox log, which the executor cannot reach (`count-unreadable:matcher-exit-2`) — its verdict is the suite's, read at Stage 9. Provenance survival is still 4 of 4 PASS |
| **Version stamp manifest, after #6201's slices** | `claim-version.sh --verify-stamp egress-hook-batch` → exit 0, *"verify-stamp OK … plan-only manifest"*; the Header `**Version**` cell still carries the file's only double-brace `RELEASE_VERSION` placeholder |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol, by #5592's Engineering spoke, and refreshed by #6201's when its slices landed. Operator-facing.*

### Outcome

**The egress hook consults each allowlist row only in its own match domain, so a host wildcard can no longer grant a GitHub write.** Before this release one scope-less matcher applied every row of the egress allowlist to both the host of a curl upload and the path of a `gh api` write. A `case` glob's `*` crosses `/`, so the host wildcard `*.github.com` allowlisted any `gh api` write whose path ends in `.github.com` — and a query string (`issues?x=a.github.com`) makes every write endpoint end that way, which put issue creation on any public repository within reach with no write access needed. The reverse held too: the path row `graphql` allowlisted a curl upload to a host of that name.

Each managed row now carries a `# egress-scope: host` or `# egress-scope: gh-api-path` directive on the line directly above it, and the matcher reads it. Independently of any directive, the gh-api path check never consults a pattern whose first path segment is a glob — so the reported construction is closed even for operator rows written before directives existed, and even if the hook is republished before the allowlist is regenerated.

**And a `gh api` write refused as unparseable now leaves a record that says whether the refusal was right.** BLOCK-EGRESS-007 refuses a write it cannot tokenize with the cause `unparseable`. That cause has no path, so every such record used to carry the same constant evidence, and no reader could tell a correct refusal from a false one. Each record of the class — in the warn log and the block log alike — now carries a `features` object (whether bash itself accepts the command's syntax, read and never executed, naming which bash judged it; and which heredoc delimiter quoting the command uses) plus the build id of the hook that wrote it, and never the command's text, offsets or lengths. The verdicts are unchanged: the same commands are refused exactly as before. And a broken feature step can no longer cost a deny — measured before the fix, a failing digest step turned an enforce-mode refusal into a non-blocking exit with no record.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #5592 | a host row can no longer grant a `gh api` write, a row declared `gh-api-path` can no longer grant a curl upload, and the allowlist header and the matcher state the same grammar | DONE (Stage 6) |
| #6201 | every BLOCK-EGRESS-007 `unparseable` refusal record carries non-identifying structure — a parse verdict scoped to its named parser, the heredoc delimiter quoting and the producing build — in both writers; the records written before the fix are written off by deploy time | DONE (Stage 6) |

### Key decisions

- **D5-1 (A) — adjacent directives plus a path-site guard.** A directive binds only the row directly below it, so a later row can never inherit a scope; a mistyped directive makes its row match nothing. Chosen over per-row prefixes and a second allowlist file because it is the only shape that is revert-safe and safe in either publish order.
- **D5-2 (A) — a row with no directive keeps dual scope.** No operator grant is revoked on upgrade. The guard removes the dangerous direction for every row; `allowlist-add.sh --scope` confines a row, and a `--scope` re-add declares an existing bare row in place rather than adding a twin.
- **D5-3 (A) — rollout reach unchanged.** The narrowed deny enforces from day one at the command positions the replaced matcher adjudicated; implicit-POST and new-position spellings stay shadow-logged until the rule's widening phase graduates.
- **D5-4 (A) — FS-6201.** A nested, versioned `features` object plus a top-level `hook_build`, on the `unparseable` class only and in both writers. Chosen over tokens packed into `evidence`, flat keys and a per-rule container because it is the only shape that classifies every measured false-refusal mechanism, carries no command-derived text, and needs no relocation if a shared writer adopts it. The adversarial review's refinements are folded in: the parser is named in the record, a failed parser run records `unavailable` rather than a verdict, and one size cap bounds both computations.
- **D5-5 (A) — the pre-fix records are written off**, bound to deploy time and producing build rather than to the absence of a key, so a current-build record that lost its features is never counted among them. {{ADR:a-refusal-record-carries-structure-never-the-command}} records the decision, and stays `Proposed` until Stage 13's ratification beat.
- **Release class `novel`** (the operator's pre-authorized switch at the first Stage-5 D-class decision); D-C SINGLE, P0 serial.

### Reversibility

**CHEAP — HIGH confidence.** `git revert -m 1` of the merge, then republish the hook bundle and let the update path regenerate the allowlist. A directive is a comment line to the prior matcher, and that is measured, not argued: the `origin/main` hook grants exactly the same verdicts over the new-format file as over the old one (0 of 30 differ). #6201 reverts the same way: records already written keep their keys, and new ones simply stop carrying them. The claimed version tag is retained and recorded, never deleted.

### Downstream impact

- **Stage 12 must republish the helper as well as the hook, and verify both by content.** The deployed `allowlist-add.sh` on the authoring instance is stale: exercised against the deployed file, it planted operator rows outside the preserved region, where the next update discards them.
- **Operators:** a row with no directive and no `/` in the operator region stays consultable in both domains; the helper's notice and the header say so and name `--scope` as the remedy. The Stage-13 release note must carry this.
- **The shadow-allowed residual** (implicit POST, later invocations, new command positions) stays owned by BLOCK-EGRESS-007's widening-phase graduation (#6195). **Contention:** `install-resolves-identically` (#5274) edits the same helper — whichever merges second rebaselines.
- **#6194 serializes this release's refusal-record field set** one record per line: the hub's AI-001 posts FS-6201's location on #6194 with the writer-mode correction, and its schema census gains one non-shadow record variant (`hook_build` plus `features`).
- **Stage 12 re-stamps #6201's AC-3 count** with the write-off predicate after the republish, and records the zero-claim that no post-republish `unparseable` record lacks `features`.
- **The scanner's false-refusal remedy (#7548) can be sized from records** once the fix deploys: the false-refusal share is `features.shell_parse = ok`, split by `features.heredoc`.

### Cross-references

- Release plan: this file — § Decision Record, § Verification Plan, § Deviation Log.
- Milestone: `egress-hook-batch`.
- Decision records: {{ADR:egress-allowlist-rows-declare-their-match-domain}} · {{ADR:a-refusal-record-carries-structure-never-the-command}}.
- User-facing release notes: `release/releases/notes/vX.Y_RELEASE_NOTES.md`, authored at Stage 13 Close per `release/references/standards/release-notes-standard.md`.

---

## Baseline pin

`origin/main` @ **`0c759aaf`** (`0c759aaf992726c2cba5e43400ca6daa4056fdf3`), measured at Stage-4 Phase A0, re-confirmed by the hub's R1 evaluation and by both Stage-5 designs (0 commits since the pin), and re-confirmed unmoved at Engineering Commit 0 — the release branch is cut from exactly this commit. Read by the Stage-9 mid-pipeline divergence re-check.

---

## Issue References

The two content members of this milestone are transitioned to closed at Stage 13, by the Stage-13 close-out on the merged PR rather than by an auto-close keyword in the PR body.

- **#5592** — the egress allowlist conflates host patterns with path patterns, so a gh-api write to a host-shaped path suffix is allowlisted. Five acceptance criteria.
- **#6201** — `unparseable` refusals from the gh-api write rule leave no classifiable evidence. Five acceptance criteria; AC-3 re-scoped to the measured pre-fix population.
- **#6194** — the co-discharge partner in `evergreen-cleanup-batch` that serializes the refusal-record field set this release settles.
- **#6195** — the graduation of BLOCK-EGRESS-007's widening phase, which owns the shadow-allowed residual of D5-3.
- **#7544** — the proposed shared refusal-record writer across hooks, which adopts FS-6201's shape.
- **#7548** — the observation card for the heredoc and further `unparseable` false-refusal mechanisms.
- **#7546 · #7553 · #7554 · #7555 · #7556** — the Stage-4, Stage-5 (both cards) and Stage-6 (both cards) hub sub-tasks carrying the plan source, the designs, their reviews and the decision records.
