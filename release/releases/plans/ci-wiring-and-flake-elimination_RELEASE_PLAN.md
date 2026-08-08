<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — ci-wiring-and-flake-elimination

> **Milestone:** `ci-wiring-and-flake-elimination` · **Release Class:** `novel` (Standard / Deep / ALL / 30-day) · **Version:** `v4.19` — **provisional; binds at the Stage-12 atomic claim (ADR-092)** · **Scope:** 3 issues (#4188, #3832, #3936) · **Topology:** D-C `SINGLE` · **Concurrency posture:** P0 fully-serial · One release branch, one PR, one merge gate · **Branch:** `release/ci-wiring-and-flake-elimination` (slug-primary, no version stem).

This file is the Stage-4 release plan rendered on sub-task #5031 (2026-08-07), committed as **Engineering Commit 0** on the release branch per the D-C SINGLE topology. It is reproduced from that sub-task comment with **three corrections** applied — each falsified at Stage 5 Solutioning and accepted by the operator at the Collective Review scope-lock. Corrections are marked inline where they land, and the superseded Stage-4 text is retained rather than overwritten, so the record shows what moved.

## Release Identity — slug-primary, version provisional

The plan file, the branch, and all hub state are keyed on the milestone **slug**, never the version. `v4.19` is **provisional** and binds only at the Stage-12 atomic compare-and-swap, where git's ref CAS is the authority.

> **Slot lost a second time — R-6 firing, exactly as this plan predicted (recorded at Engineering, 2026-08-08).** The `v4.17` determination below was correct when written and is now stale: `v4.17` was claimed by **#4979 `102-specialist-role-coverage`** at `c74de241`, and `v4.18` — the slot that would have succeeded it — was claimed by **#4924 `hub-spoke-execution-safety`** at `303de6e0`, before this release reached Stage 6. **R-6 named both of those releases as the contending claimants, and both claimed.** Recomputed next-free for bump-class `minor` is **`v4.19`** (tag surface, local and remote, highest claimed = `v4.18`; the `RELEASE_LOG.md` ledger reads `v4.16` and is now **two** releases behind the tags, which is why R-7 makes the tag surface authoritative). `v4.19` remains **provisional and binds at the Stage-12 atomic claim** — it is not re-verified here, and this plan does not treat it as bound. The table below is retained as the Stage-4/Commit-0 record rather than rewritten, because the point of R-6 is that the determination was sound and the slot moved anyway.

**Commit-0 freeness re-verification (2026-08-07).** The Stage-4 D-Version determination was re-verified before this file was written, because this release has already lost one slot mid-run: `v4.16` was recorded at planning entry and was claimed by a sibling release within the hour. Re-verified across **three independent claimed-set surfaces**, each with a live control, reading the ledger via `git show "origin/main:release/releases/RELEASE_LOG.md"` rather than the worktree copy:

| Surface | Denominator | `v4.17` (subject) | Sensitivity arm (`v4.16`) | Specificity arm (`v4.9999`) |
|---|---|---|---|---|
| git tags (**authoritative**) | 160 refs | **0** | 1 | 0 |
| published GitHub Releases | 158 releases | **0** | 1 | 0 |
| mainline `RELEASE_LOG.md` via `git show "origin/main:…"` | full ledger | **0** rows | 11 rows | — |

Highest claimed `v4.*` across all three surfaces is `v4.16`; recomputed next-free for bump-class `minor` is **`v4.17`**, which equals the planned version and appears in no claimed set. **Verdict: PROCEED.** The tag surface is treated as authoritative because the ledger legitimately lags the tag by one release — the exact condition that produced this release's original wrong `v4.16` determination (risk **R-7**).

## Corrections applied to the Stage-4 plan

| # | Section | Stage-4 statement | Corrected statement | Basis |
|---|---|---|---|---|
| 1 | Contention Map | *"within-release contention: NONE"* | **`#4188 ∩ #3936` = 1 path** — `.github/workflows/release-tooling-smoke.yml`. Practical impact **nil** under D-C SINGLE / P0 | Stage 5 (#5034) Tier 2 `[SCOPE CHANGE]`; accepted at Collective Review |
| 2 | File Change Matrix | #4188 = 1 file · #3936 = 2 files · #3832 = 134 sites | #4188 = **2 files** (adds `release-tooling-smoke.yml`) · #3936 = **3 files** (adds `install-tests.yml`, `core/config/allowlists/script-execution-allowlist.txt`) · #3832 = **140 sites across 34 files** | Stage 5 design outputs; accepted at Collective Review |
| 3 | Release identity | Release Class *proposed* `novel`; D-Version recorded `v4.16` | Release Class **is `novel`** (rendered at the Stage-4 gate) · D-Version **is `v4.19`** — recomputed at Engineering after `v4.17` (#4979) and `v4.18` (#4924) were both claimed; still provisional until the Stage-12 atomic claim | Stage-4 operator gate; Commit-0 re-verify above; Engineering re-verify (R-6) |

No other Stage-4 statement is altered. Everything below this line is the Stage-4 plan as rendered, carrying the three corrections inline.

---

## Stage 4 Release Planning — ci-wiring-and-flake-elimination

**Baseline pin (audit-baseline discipline).** Planning-entry baseline `37f68a2b` · re-measured against live `origin/main` `876f8632` · Mode R comparison pin `86bc649e`. All three are named per-probe below because `origin/main` advanced **during** this planning run (PR #4980 merged at `876f8632`, 2026-08-08T10:59+0900).

---

### Summary (30 seconds)

Three cards, one dependency edge, one live sibling collision, and **four scope findings that need the operator's Phase B1 gate**.

1. **#3936 scope HOLDS at 5 scripts** — the hub's handed-down "3 unwired of 10" is **refuted**. My probe reads **5 unwired of 12**, and the unwired set is byte-identical to the five #3936 names. The hub's probe excluded the two `.py` suites. **No scope shrink.** The AC's denominator (`11`) is stale — live is `12`.
2. **#3832 scope GREW 49 % since the readiness gate** — `90 → 134` sites, `32 → 34` files, in **two days**. My probe reproduces the recorded census **exactly** (31/65/25/32) at the Mode R pin, so this is real growth, not measurement drift. All five measurable ACs are stale. `size:L` is at its ceiling.
3. **PR #4924 is a live, two-sided collision** — it shares **5 files** with #3832's remediation set, **adds +17 new sites** into that set, and edits `release-tooling-smoke.yml`, the single file #3936 changes. It does **not** change which 5 scripts #3936 must wire.
4. **A governed detector for #3936's gap shipped after the readiness gate.** `check-selftest-coverage.py` Arm D (the #3702 deliverable, absent at `86bc649e`) already names the unwired suites — and it names **6**, not 5. #3936's "not subsumed by #3702" rationale is **partially falsified as written**; the card is still needed (Arm D is WARN-only and executes nothing), but its rationale and its verification method both need restating.

**Ordering `#3832 → #3936` VERIFIED and retained.** Both legs re-measured: `test_verify_release_plan.sh` = 6 `printf|grep -q` sites, `test_structural_blast_radius.sh` = 2 `grep|head` sites.

**Release Class: `novel`** — rendered at the Stage-4 operator gate (the Stage-3 `routine` declaration is superseded). **D-Version: `v4.19`** — the handed-down `v4.16` was REFUTED at Stage 4 (that tag is taken by milestone `methodology-fields-and-statuses`); `v4.17` was next-free when recorded and has since been claimed by #4979, as has `v4.18` by #4924. Recomputed next-free at Engineering is `v4.19`, still **provisional** until the Stage-12 atomic claim (see § Release Identity).

---

### Phase A0 — Triage→Design Re-Review

**`G-PL5` Mode R briefing cache-read: MISS.** Reason: sub-task #5031 carries **one** prior comment from the trusted author set (`cody-hutson`, `2026-08-08T01:59:37Z` — the hub's D-Version determination plus its Procedure-0 entry-state record). That comment is **not a briefing**: it carries no §1 six-column per-requirement table, and its single occurrence of the string `<!-- mode-r-briefing` is a **backticked prose mention** inside the hub's own note that no briefing exists — not a marker. The 2026-08-06 Mode R run recorded its outcome in the milestone description, which is not the surface the gate reads. Per the spec, **cache absence is never a FAIL** — PT-1..4 ran against live state below. Rows source: `re-derived` (not `mode-r-cache`).

> **Self-correction (recorded, not silently amended).** The first published revision of this artifact asserted "zero comments from any author" on #5031. That was **wrong** — asserted without probing, exactly the unprobed-zero this plan's own Probe-Validity discipline forbids. Probed after posting: `comments = 2` (one prior, plus this one). The **MISS verdict is unchanged and independently corroborated by the hub's own entry-state record**; only the stated reason was defective. Correction is surfaced here rather than quietly rewritten, per the same anti-pattern this release exists to close.

**Header metadata**

| Field | Value |
|---|---|
| `issue_number` | #4188, #3832, #3936 (release-scoped) |
| `release_milestone` | `ci-wiring-and-flake-elimination` (slug-primary, ADR-092) |
| `stage` | 4 |
| `spoke_author` | Stage-4 Release Planning spoke |
| `re_review_date` | 2026-08-07 (Friday) |
| `issue_body_revision` | per-card `updatedAt` at read time, 2026-08-07 |
| `triage_decision_date` | 2026-07-28 (Tue) triage-bundled; 2026-08-06 (Thu) readiness-gated |
| `effort_tier` | complex |

**Per-requirement table**

| Requirement | D1 finding | D2 finding | D3 finding | Cls | Delta / PT |
|---|---|---|---|---|---|
| #3936 scope = 5 scripts | Probe-validity (`review-discipline-principles.md` §8) satisfied: sensitivity arm non-zero, specificity arm zero, extraction non-empty | Re-derived at `37f68a2b`: **5 unwired of 12**, set identical to the card's five | Two sibling releases re-rendered class at Stage 4; census re-derivation is the established Stage-4 habit | **C1** | Survives verbatim — the hub's contradicting input is the artifact in error |
| #3936 AC "All **11** scripts" | G1-05 verifiability: an AC keyed to a stale denominator cannot be graded | `release/tools/tests/` holds **12** `test_*` at `37f68a2b`; `test_platform_toggle.sh` landed post-filing **and is wired** | — | **C2** | Restate denominator `11 → 12`; `13` if #4924 lands first |
| #3936 "Not subsumed by #3702" | Rule 4 root-cause: the stated cause ("its gate never reaches them") is now false; the true cause is different | `check-selftest-coverage.py` **did not exist** at `86bc649e`; added `fbc5e01e` (2026-08-05, #3702). Its `TEST_SUITE_GLOBS` **does** reach `release/tools/tests/test_*.sh` and `test_*.py` | Arm D's own text anticipates this card: *"wiring them is separate, tracked work"* | **C3 / PT-1** | Stale-assumption. Not-subsumed **verdict survives** (Arm D detects, never executes; WARN-only, exit 0) but the **rationale is falsified as written**. Restate + adopt Arm D as the verification method |
| #3936 scope boundary 5 vs 6 | Mode R already ruled "wiring one and leaving four is a point-fix on a class" — the same logic reaches the 6th | Arm D names **6** unwired suites; the 6th is `core/deploy/tools/tests/test-status-label-invariant.sh` (added `b6e27d5f`, 2026-07-20 — present at the Mode R pin, invisible to its `release/tools/tests/`-only probe) | — | **C2** | Operator decision at **D-ScopeBoundary**: include the 6th, or exclude with written rationale |
| #3832 census 65/31/25/32 | Rule 15 probe record: all four operands reproduce **exactly** at `86bc649e`, validating the probe definition | Live at `37f68a2b`: **89 / 42 / 45 / 34**. Growth is one file — `test_upgrade_config_durability.sh` (2→23, 1→20) via Suites P/S/C merged 2026-08-06→07 | The v4.14/v4.15 releases that grew it are the same mainline advance the boundary-currency check exists to catch | **C3 / PT-1** | Stale-assumption. Cite: `7e6036a6`, `e87f8e01`, `181732ce`, `0fd6767d`, `b2012fe6`, `8695de05`, `71249a70`. All five measurable ACs restate |
| #3832 `size:L` | Aggregate-scope signal, not per-site | 134 sites / 34 files vs the 90/32 the `L` re-size was rendered against | — | **C2** | `L` retained but **at ceiling**; growth is ongoing (see R-2) |
| #3832 AC method "returns 0 hits" | G1-05a pattern (b) file-state predicate — gradable **only against a pinned set** | Repo-wide zero is a moving target: #4924 alone re-adds +17. `block-shell-injection.test.sh:149-150` is a `grep\|head` **inside a test-payload string** — an irreducible false positive | — | **C2** | Pin the AC to a baseline-SHA file set; carry the payload-string exemption |
| #4188 coupling DISCHARGED | Reversibility CHEAP/HIGH stands | **Verified**: `rollup-attribution.sh:467` computes `n_legacy` via `has("worktree")\|not`, fails closed | — | **C1** | Survives verbatim |
| #4188 headline defect | G-PL4 empirical repro (below) | Defect byte-present at `extract-usage.sh:355`; jq errors live; swallow present at `:356` | — | **C1** | Survives verbatim |
| #4188 AC 4 (extend `--self-test`) | Rule 3 positive evidence required | `extract-usage.sh --self-test` **is** CI-wired (`release-tooling-smoke.yml:832`) **and guarded by a precision probe** (`:858–880`) asserting it fails on a removed seed | — | **C2** | Design constraint: extending `self_test()` must not disarm the precision probe. Route to Stage 5 |

**A0.5 / G-PL1 (AC/substrate currency):** FAIL → Tier 1 [ADJUST]. Three cards carry stale AC context (#3936 denominator; #3832 all five measurable ACs; #3936 dependency rationale). All route to body refinement before Engineering.

**A0.6 / G-PL2 (pre-plan crisping):** PASS. All three bodies satisfy G1-02 / G1-04 / G1-05 substantively — each names files, a method, and a verifiable predicate. Positive evidence: #3832 carries a per-phase method line; #3936 names its exact workflow anchor; #4188 carries a reproducible jq one-liner (executed below).

**A0.7 / G-PL3 (placement forward-check):** **SKIP** — correct non-ceremony signal. Mover-classifier `git log 37f68a2b..origin/main --name-status --find-renames` over this release's base window returns no directory-crossing `R` row and no `D` row on this release's surface. No structural reorg merged after the base; nothing to re-home. This release authors **no new files** under the recommended plan.

**A0.8 / G-PL4 (bundle-entry freshness re-verification):**

| Card | Runnable check | Re-run verdict at `37f68a2b` |
|---|---|---|
| **#4188** | jq binding repro | **admit-still-valid** — `extract-usage.sh:355` byte-present; `jq: error … Cannot index array with string "session_id"` reproduced live; correct form returns `null`; swallow `2>/dev/null … \|\| true` present at `:356` |
| **#3832** | 3 AC grep probes | **re-scope-changed** — reproduces, **magnitude grew 49 %**. Routes Tier 1 [ADJUST] → operator re-scope before build |
| **#3936** | name-reference sweep | **admit-still-valid, scope unchanged** — same 5 scripts unwired; denominator moved 11 → 12 (Tier 1 [ADJUST] on the AC only) |

Per the supersession clause, no card's A0 rows are superseded to the `close-resolved` verdict. The `re-scope-changed` verdict on #3832 supersedes that card's census rows, which is what the C3/PT-1 row above records.

**Parallelization-Map currency check:** The milestone's `## Parallelization Map (recorded 2026-07-28)` is **stale-dated** relative to the 2026-08-06 Mode R refresh event and the 2026-08-08 mainline advance → Tier 1 [ADJUST]. Tier-S re-derivation surfaces a **new structural edge the map does not carry**: the version-slot token `Δversion/minor-next-free` is contended three ways (this release, #4924, #4979 — all `minor`). See R-6.

**A0 currency-decision confidence gate:** Signal = **corroborated-and-grounded**. Three independent sources agree on the same composition delta: A0.5 AC-currency, A0.8 empirical re-run, and the Parallelization-Map re-derivation all say "scope moved, bundle membership did not." Refresh outcome = **amend** (in-window `[BUNDLE AMENDMENT]`, MODERATE reversibility), not re-bundle or defer. No PAUSE-TO-LEARN loop required — the gap is nameable and the corroboration is independent.

**Architecture evaluative-lens (advisory):** #3832's repo-wide-zero AC is a K1 codified-rule ambition enforced by a K3 one-time sweep. That is the plug-and-play seam: the rule survives only as long as no one writes the idiom again. Advisory, non-blocking — surfaced as **D-ScopeBoundary** option (c).

**Ticket-architecture reconciliation:** No card touches an ADR, discipline, registry, ledger or roadmap surface. N/A.

---

### Dependency Graph

```
#4188 ──────────────────────────────────► (independent)
                                           coupling to rollup-attribution.sh preflight
                                           DISCHARGED at b1f93b0a — re-verified

#3832 ──[hard, load-bearing]──► #3936
        8 idiom sites inside the 2 scripts #3936 wires

PR #4924 (external, in-flight) ──[contention]──► #3832  (5 shared files, +17 new sites)
PR #4924 (external, in-flight) ──[contention]──► #3936  (same workflow file)
```

**Edge `#3832 → #3936` — VERIFIED, retained as hard.** Re-measured at `37f68a2b`:

| Script #3936 wires | Idiom sites inside it | Consequence if wired first |
|---|---|---|
| `release/tools/tests/test_verify_release_plan.sh` | **6** `printf \| grep -q` | imports a latent SIGPIPE false-FAIL into `closeout-smoke` |
| `release/tools/tests/test_structural_blast_radius.sh` | **2** `grep \| head` | same |

Both legs confirmed by the same probe that reproduces the recorded census exactly. The rationale is load-bearing, not incidental — **retained**.

**#4188 independence — VERIFIED, not asserted.** Two separate checks: (a) the discharge holds (`rollup-attribution.sh:467` fails closed on any legacy record); (b) **zero file overlap** — `extract-usage.sh` carries **0** sites in either idiom census (its `grep` calls already use the safe brace-group + `|| true` form at `:56`, `:67`, `:70`, `:328`, which is why the probe correctly excludes them). No edge to #3832 or #3936.

**Zero circular chains.** Denominator: 3 cards, 3 ordered pairs tested. One directed edge found (#3832→#3936); the reverse pair and both #4188 pairs are empty. A cycle requires ≥2 edges among 3 nodes; 1 edge cannot close one.

---

### Implementation Sequence

**Milestone proposal `#4188 → #3832 → #3936`: VERIFIED and RETAINED.** No revision to the internal order. Each position is now evidence-backed rather than inherited:

| # | Card | Why here |
|---|---|---|
| 1 | **#4188** | Independent (verified), smallest surface (1 file), highest severity (silent data destruction). Lands a clean commit before the large sweep touches 34 files. Its file is disjoint from every other card's set — zero rebase cost wherever it sits, so severity decides |
| 2 | **#3832** | Hard prerequisite of #3936. Largest surface; must land before the wiring or the wiring imports the flake |
| 3 | **#3936** | Consumes #3832's output. Single-file edit; its negative test is meaningful only once the idiom is converted |

**Sibling sequencing is the open question, not the internal order.** See **D-SiblingSequencing**. Recommended posture: **land this release's #3832 before #4924**, and place the obligation to convert #4924's own +17 new sites on #4924 as the later merger. Rationale: #4924 is a **draft** with unknown timing; blocking a 3-card release on a draft PR trades a certain delay for an uncertain one, and the reverse order forces #3832 to re-derive its whole 34-file census after #4924 lands. The residual (a post-merge regression of the repo-wide AC) is what **D-ScopeBoundary** option (b)/(c) exists to absorb.

---

### Stage Applicability Matrix

| Stage | #4188 | #3832 | #3936 | Note |
|---|---|---|---|---|
| 5 Solutioning | **APPLY** | **APPLY** | **APPLY** | Under the proposed `novel` class the activation bias is ALL. Each carries a real design question — see below |
| 6 Engineering | APPLY | APPLY | APPLY | Write-serialized under D-C SINGLE |
| 7 Dev Testing | APPLY | APPLY | APPLY | All three have functional impact; none is a doc-only change |
| 8 QA Testing | APPLY | APPLY | APPLY | Per-criterion AC verdicts; ACs are being restated at A0.5, so grading needs the refreshed bodies |
| 9 Plan Review | APPLY (release-scoped) | | | **Deep** depth under `novel`. CIACs graded at QC3.5 |
| 10 Dry Run | APPLY (release-scoped) | | | |
| 11 Snapshot | APPLY (release-scoped) | | | |
| 12 Execute | APPLY (release-scoped) | | | Version binds here (ADR-092 atomic claim) — see R-6 |
| 13 Close | APPLY (release-scoped) | | | 30-day outcome window |

**No stage is skipped for any card.** Stage 5 activation is *not* ceremony here — the design question per card is concrete:

- **#4188** — extending `self_test()` to cover the carry-forward branch must not disarm the `release-tooling-smoke.yml:858–880` precision probe, which asserts `--self-test` returns **non-zero** when a reserved seed is removed. Making the swallowed error fatal also changes the script's exit contract for four CI-invoked siblings.
- **#3832** — phase boundaries, the pinned-set-vs-repo-wide AC form, the payload-string exemption, and whether a durable guard ships (D-ScopeBoundary).
- **#3936** — one CI step or several; 5 scripts or 6; and adopting Arm D as the verification method rather than the hand-rolled filename sweep.

---

### Contention Map

> **⚠️ CORRECTED at Stage 5 / Collective Review scope-lock (2026-08-07).** The Stage-4 verdict below — *"within-release contention: NONE"* — is **FALSE** and is superseded. It is retained verbatim as the historical record; the corrected verdict follows it.

**Within-release contention: 1 shared path — `#4188 ∩ #3936` on `.github/workflows/release-tooling-smoke.yml`.** [SOURCE — Stage 5 Solutioning, sub-task #5034; accepted by the operator at the Collective Review scope-lock]

The Stage-4 probe was correct against the file sets it was given; the *file sets themselves* moved at Stage 5. #4188's design requires a CI runner to make its extended `--self-test` provably able to fail, and the only in-repo runner for that tool is the `finops-selftest` job in `release-tooling-smoke.yml` — the same workflow #3936 edits. Corrected denominator: **37 path-slots, 36 distinct paths**; one non-empty pairwise intersection.

**Practical impact: NIL.** Under D-C **SINGLE** + D-Concurrency **P0**, the three cards commit serially onto one branch — #4188 lands first and #3936's spoke sees the new step already present. There is no merge to resolve and no ordering hazard. #4188's change is an **append** after the existing precision-probe step (`:890`); #3936's own step additions land in the `closeout-smoke` job and do not interact. Against **PR #4924**, its four hunks on this file sit at `:138 / :274 / :308 / :359` — nowhere near the append point — so **R-4 is not aggravated**.

*Superseded Stage-4 text, retained as the historical record:*

> **Within-release contention: NONE.** Probe record — denominator: the 3 cards' declared file sets (1 + 34 + 1 = 36 path-slots, 36 distinct paths). Pairwise intersection across all 3 ordered pairs returns empty. **Sensitivity arm:** the same intersection operator run against `#3832 ∩ PR #4924` returns **5** (non-zero, below), so the operator discriminates. **Specificity arm:** `#4188 ∩ #3936` returns 0 against two sets known disjoint by inspection. Extraction non-empty for subject and both arms. This is a real empty set, not a broken probe.

**Cross-PR contention (A4 extension) — baseline `37f68a2b`, re-measured against live `876f8632`.**

> **Probe-validity note (PV-4/PV-6), recorded because it changes the finding.** My first pass used `gh pr view --json files,baseRefName,headRefSha --jq '.files[].path'` and returned **48 paths for both PRs — identical lists**. That was a **BROKEN PROBE**: the malformed jq emitted the JSON *field-name* list, not file paths. Caught by the identical-count control. Re-derived by two independent methods that agree exactly — `gh api .../pulls/N/files --paginate` and `git diff <merge-base>..<head>` — giving **#4924 = 85 files, #4979 = 15 files**. All findings below use the corrected sets.

| PR | Head | State | ∩ #4188 | ∩ #3832 | ∩ #3936 | Class |
|---|---|---|---|---|---|---|
| **#4924** `release/hub-spoke-execution-safety` | `246f353b` | open, **draft** | 0 | **5 files + 17 new sites** | **1 file** (`release-tooling-smoke.yml`) | `line-range-overlap` |
| **#4979** `release/102-specialist-role-coverage` | `290b5180` | open, **draft** | 0 | 0 | 0 | `single-pr` — no code surface (skills/ADRs/packages only) |
| **#4980** `release/265-methodology-fields-and-statuses` | — | **MERGED `876f8632`** during this planning run | 0 | 0 | 0 | resolved — but it **claimed `v4.16`** (see R-6) |

**#4924 ∩ #3832 — the 5 shared files:**

```
core/deploy/deploy.sh
core/deploy/tests/run-install-regression.sh
docs/scripts/setup-workspace.sh
release/tools/cleanup-orphan-state.sh
update.sh
```

**#4924 also grows #3832's surface.** Census at `#4924`'s head vs live `main`: `printf|grep -q` **89 → 106** (+17), `grep|head` **45 → 46** (+1), files **34 → 38** (+4). New sites land in `test_refresh_surfaces.sh` (4), `test_spoke_run_directory.sh` (5), `test_rehome_hook_wiring.sh` (3), plus edits alongside existing sites in `session-retro-trigger.sh`.

**#4924 does NOT change what #3936 must wire.** Measured at `#4924`'s head: the unwired set is still exactly the same **5 scripts**. #4924 adds `test_spoke_run_directory.sh` **and wires it in the same PR** (good hygiene), and adds `ac3_concurrent_load.sh` unwired — but that name does not match the `test_*` convention #3936's AC keys on, so it falls outside the card and outside Arm D. The contention with #3936 is therefore **merge-conflict only** (same workflow file), not scope.

---

### File Change Matrix

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-07, domain: software }`

*Classification rationale (A3-time, from this matrix):* every path is executable tooling or CI workflow — shell scripts, a Python suite runner, and a GitHub Actions workflow. No governance, pipeline-spec or ADR artifact appears. Dominant and sole domain: `software`.

**Intent legend:** all rows are `edit`. **Zero `add` rows** under the recommended plan → the new-executable companion obligation (`script-execution-allowlist.txt` + CI-wiring statement) does **not** fire. Verified: the three `.sh` scripts #3936 wires already carry their 4 allowlist invocation-form rows each (sensitivity arm: `test_domain_blast_radius.sh` = 4 rows; specificity arm: fabricated name = 0 rows); the two `.py` suites are invoked via `python3` and take no allowlist row. **If D-ScopeBoundary option (c) is selected, a guard script becomes an `add` row and the companion obligation fires** — planned for, not rediscovered at Stage 5.

```
# --- #4188 (edit) --- CORRECTED at Stage 5: 2 files, not 1
core/skills/finops-usage-extractor/scripts/extract-usage.sh
.github/workflows/release-tooling-smoke.yml

# --- #3936 (edit) --- CORRECTED at Stage 5: 3 files, not 2
.github/workflows/release-tooling-smoke.yml
.github/workflows/install-tests.yml
core/config/allowlists/script-execution-allowlist.txt

# --- #3936, conditional row retained from Stage 4 (edit) ---
# D-ScopeBoundary (i) rendered "wire all 6", so this row's condition FIRED. It is
# retained as the Stage-4 record; whether the 6th suite needs an edit of its own, or
# is wired purely from the workflow files above, is #3936's Stage-5/6 determination —
# the corrected 3-file set above is the authoritative #3936 count.
core/deploy/tools/tests/test-status-label-invariant.sh

# --- #3832 remediation surface, 34 files (edit) ---
core/deploy/deploy.sh
core/deploy/tests/run-install-regression.sh
core/deploy/tests/test_agent_tools_conformance.sh
core/deploy/tests/test_check19_event_log_integrity.sh
core/deploy/tests/test_detect_install_path_spaces.sh
core/deploy/tests/test_doctor.sh
core/deploy/tests/test_g1_form_family.sh
core/deploy/tests/test_g1_release_resolver.sh
core/deploy/tests/test_install_end_to_end.sh
core/deploy/tests/test_install_exit_propagation.sh
core/deploy/tests/test_instance_path_roundtrip.sh
core/deploy/tests/test_notify_version_skew.sh
core/deploy/tests/test_ps1_dryrun_contract.sh
core/deploy/tests/test_refresh_hooks.sh
core/deploy/tests/test_update_nonrepo_root_cwd.sh
core/deploy/tests/test_upgrade_config_durability.sh
core/deploy/tools/check-canonical-structure.sh
core/deploy/tools/check-convention.sh
core/deploy/tools/path-leak-patterns.sh
core/hooks/notify-version-skew.sh
core/hooks/session-retro-trigger.sh
core/hooks/tests/block-shell-injection.test.sh
core/skills/finops-usage-extractor/scripts/estimate-usage.sh
core/skills/finops-usage-extractor/scripts/rollup-attribution.sh
core/skills/pmo-qa-auditor/scripts/fitness-audit-search-primitives.sh
docs/scripts/setup-workspace.sh
release/tools/blast-radius.sh
release/tools/cleanup-orphan-state.sh
release/tools/lib/deciders-carveout.sh
release/tools/synthesize-release-learnings.sh
release/tools/tests/test_renumber_adr.sh
release/tools/tests/test_structural_blast_radius.sh
release/tools/tests/test_verify_release_plan.sh
update.sh
```

> **⚠️ CORRECTED at Stage 5 / Collective Review scope-lock (2026-08-07).** #3832's remediation surface is **140 sites across 34 files**, not the 134 the Stage-4 census below records. The file count (34) is unchanged. The per-file table below is retained as the Stage-4 record; its `Total` row is superseded by the corrected figure.

**Per-phase site distribution for #3832 (at `37f68a2b`), highest-density first:**

| File | `printf\|grep -q` | `grep\|head` |
|---|---|---|
| `core/deploy/tests/test_upgrade_config_durability.sh` | **23** | **20** |
| `core/deploy/tests/test_check19_event_log_integrity.sh` | 12 | — |
| `core/skills/pmo-qa-auditor/scripts/fitness-audit-search-primitives.sh` | 8 | 1 |
| `release/tools/tests/test_verify_release_plan.sh` | 6 | — |
| `release/tools/lib/deciders-carveout.sh` | 4 | — |
| `release/tools/cleanup-orphan-state.sh` | 3 | 3 |
| `core/hooks/notify-version-skew.sh` | — | 3 |
| remaining 27 files | 33 | 18 |
| **Total** (Stage-4 census — superseded) | **89** | **45** |

**Corrected total: 140 sites across 34 files.** The Stage-4 census above totals 134 (89 + 45); the corrected figure accepted at the Collective Review scope-lock is **140**. The file count (**34**) is unchanged, and the per-file distribution above is retained as the Stage-4 record — only the total is superseded.

---

### Risk Register

| ID | Risk | Owner | Severity | Reversibility / Confidence | Mitigation |
|---|---|---|---|---|---|
| **R-1** | **#3832's AC is a moving target.** "Repo-wide zero hits" is graded against a population that grew 49 % in two days and that #4924 will grow again by +17. The AC can be true at merge and false hours later | Stage 5 (#3832) | **HIGH** | CHEAP / HIGH | **D-ScopeBoundary.** Pin the AC to the 34-file set at baseline `37f68a2b`; option (c) adds a durable guard so the class cannot regrow |
| **R-2** | **Scope growth is ongoing, not a one-time correction.** The +44 sites arrived via three *new test suites* — the repo is actively growing this idiom because nothing prevents it. `size:L` (8 pts) was set against 90 sites; it now covers 134 | Operator (B1) | **HIGH** | MODERATE / HIGH | Re-size or re-scope at B1. A pure sweep without a guard buys a fix with a known decay rate |
| **R-3** | **#4924 merge conflict on 5 shared `.sh` files.** Both PRs edit the same lines in `deploy.sh`, `update.sh`, `cleanup-orphan-state.sh`, `setup-workspace.sh`, `run-install-regression.sh` | Stage 12 | **MEDIUM** | CHEAP / HIGH | **D-SiblingSequencing.** Whichever merges second rebases; #3832's edits are mechanical and per-site, so conflict resolution is low-risk |
| **R-4** | **#4924 merge conflict on `release-tooling-smoke.yml`.** #3936's only file; #4924 edits the same workflow | Stage 12 | **MEDIUM** | CHEAP / HIGH | Coordinate step placement; #3936 appends steps, #4924 edits existing ones — likely auto-mergeable, verify at Stage 12 Phase A.5 |
| **R-5** | **#4188's fix can disarm a live CI precision probe.** `release-tooling-smoke.yml:858–880` asserts `extract-usage.sh --self-test` exits **non-zero** with a reserved seed removed. Extending `self_test()` and/or making the swallowed jq error fatal both change the exit contract | Stage 5 (#4188) | **MEDIUM** | CHEAP / HIGH | Stage 5 design step must run the precision probe before and after. This is the release's own failure class turned on itself |
| **R-6** | **Version-slot contention, three ways.** `v4.16` was claimed by #4980 at `876f8632` **during this planning run**. #4979's plan still carries `v4.16` as its provisional; #4924 is `minor` slug-only. All three compete for `v4.17` | Stage 12 | **MEDIUM** | CHEAP / HIGH | **FIRED — both named claimants won a slot.** #4979 took `v4.17` (`c74de241`), #4924 took `v4.18` (`303de6e0`), both before this release reached Stage 6. Recomputed next-free at Engineering = **`v4.19`**, provisional. Mitigation held: the plan is slug-primary, so no rename was needed. Tier-S serialization edge — record in the Parallelization Map. Bind at the Stage-12 atomic claim only; **read the tag surface, never the ledger** (see R-7) |
| **R-7** | **The ledger lags the tag.** `RELEASE_LOG.md` on live `main` tops out at **v4.15** while the **v4.16 tag exists**. A next-free computation trusting the ledger returns a false PROCEED — exactly the error in the handed-down `v4.16` determination, and exactly the lesson #4924's own plan records at its D-13 | Stage 12 | **MEDIUM** | CHEAP / HIGH | Freeness re-verifies at Stage-12 pre-merge against `git tag`, not `RELEASE_LOG.md` |
| **R-8** | **#3936's stated rationale is falsified while its verdict stands.** Shipping the card with prose asserting "#3702's gate never reaches them" commits a false statement to the corpus | Stage 5 (#3936) | **LOW** | CHEAP / HIGH | Restate at A0.5 body refinement: Arm D *reaches and reports*, but is WARN-only and executes nothing |
| **R-9** | **Irreducible AC false positives.** `core/hooks/tests/block-shell-injection.test.sh:149–150` contains `grep … \| head` **inside a test-payload string** — it is the fixture under test, not a live idiom. A literal "zero hits" AC can never pass | Stage 5 (#3832) | **LOW** | CHEAP / HIGH | Carry the card's existing inline-rationale exemption mechanism (already specified for Phase 3) into Phases 1–2 |
| **R-10** | **Rollback of #3832 is wide.** 34 files, 134 edits. A defect found at Stage 8 means either a broad revert or per-site triage | Stage 12 | **LOW** | CHEAP / HIGH | Per-phase commits (Phase 1 / 2 / 3 as separate commits) give three revert points instead of one; the card's own AC already requires the suite to pass after **each** phase |

**Rollback strategy.** D-C SINGLE topology: one release branch, one PR, one merge. Rollback is `git revert` of the merge commit — CHEAP, no data migration, no external state. Per-card granularity comes from commit structure: #4188 = 1 commit; #3832 = 3 commits (one per phase); #3936 = 1 commit. Reverting #3936 alone is safe at any time. Reverting #3832 **after** #3936 has merged re-imports the SIGPIPE exposure into `closeout-smoke` — so the revert order is the inverse of the merge order: **#3936 before #3832**. #4188's revert restores the silent data-loss defect and is therefore a last resort; prefer forward-fix. No rollback of this release invalidates any other release's artifacts.

---

### Quota Budget

**Verdict:** **WARN** (per `quota-budget-protocol.md` Checkpoint A)

**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix):** Stage 5: **3** · Stage 7: **3** · Stage 8: **3**

**Per-spoke cost estimate:** size-bucket ordinal band per `quota-budget-protocol.md` § 5 (source: heuristic — no telemetry medians available; the § 5.1 per-bucket cutover predicate is unmet for every bucket in this release, so all three keep their ordinal band). Batch composition: `size:L` × 1 (#3832, moderate–high) + `size:M` × 2 (#3936, #4188, low–moderate).

**Assumed/stated remaining usage-window envelope:** **unstated by the operator at hub start** → conservative default applied per § 6.

**Estimated cumulative draw % (worst parallel batch):** worst batch is any of Stage 5 / 7 / 8 at N=3 with an `L` present. Against a conservative default envelope this lands in the **50–80 %** band. The `L` spoke dominates: #3832's spoke must read a 34-file / 134-site surface, which is the highest single-spoke read cost in the release.

**Routing:** **WARN → window-aware launch timing + quota-budgeting (split batch) recommended.** Concrete recommendation: split each parallel wave **2 + 1** — launch #3936 and #4188 together (both `M`), then #3832 alone. This keeps the `L` spoke's draw out of a concurrent batch without serializing the whole wave.

**Note:** Checkpoint B re-validates at **every** parallel wave at runtime (`hub-spoke-bridge.md` Procedure 2 Step 5.5) with PROCEED / SERIALIZE / DEFER / REDUCE-scope — **that** is the load-bearing gate; this plan-time estimate is advisory. STAGGER is a secondary rate-limit-only defense and is **not** a mitigation for a usage-window overrun. Bands and the cumulative-draw budget are `[CALIBRATE-AFTER-3]`, MEDIUM confidence.

---

### Cross-Issue Acceptance Criteria

All three cards instantiate one failure class — *a check that stops doing its job while its output stays indistinguishable from success*. The CIACs below assert the **integrated** release closes that class rather than three unrelated defects.

- [ ] **CIAC-1 (#3936 × #3832 on `.github/workflows/release-tooling-smoke.yml`):** Every suite `#3936` newly wires **executes and can fail** — i.e. the `closeout-smoke` job runs each of the five, and none of them false-FAILs from an unconverted SIGPIPE site. The predicate is the conjunction: `check-selftest-coverage.py --reconcile` prints `ARM D PASSED` (zero unwired suites) **AND** the newly-wired steps are green **AND** `grep -rnE '^[^#]*printf[^|]*\|[[:space:]]*grep[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-q' release/tools/tests/test_verify_release_plan.sh` plus the `grep\|head` probe over `test_structural_blast_radius.sh` both return 0. *Method:* `python3 release/tools/check-selftest-coverage.py --reconcile` + the two grep probes on the merged PR. *Graded at Stage 9 QC3.5 on the merged PR.* — **This is the release's central cohesion constraint: it is the only predicate that fails if the two cards land in the wrong order.**

- [ ] **CIAC-2 (#4188 × #3832 × #3936 on the negative-control surface):** Each card ships a control arm that **fails when the thing under test is broken**, so no card's green is vacuous. Concretely: the extended `--self-test` from #4188 fails against the unrepaired jq binding; the >64KB-haystack fixture from #3832 false-FAILs against an unconverted guard; the deliberately-broken assertion from #3936 in `test_structural_blast_radius.sh` propagates exit 1 to the job. *Method:* declared, verification executed at Stage 7 Dev Testing per card; Stage 9 reads the three emitted verdicts read-only (single-runner discipline). *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#4188 × #3832 on `core/skills/finops-usage-extractor/`):** The four finops scripts remain mutually consistent under the `finops-selftest` CI job after both cards edit the directory — #4188 edits `extract-usage.sh`, #3832 converts sites in `rollup-attribution.sh` (3) and `estimate-usage.sh` (1). The predicate: all four `--self-test` invocations exit 0 **and** the `release-tooling-smoke.yml:858–880` precision probe still exits non-zero with its reserved seed removed. *Method:* `for s in extract-usage rollup-attribution report-usage estimate-usage; do bash core/skills/finops-usage-extractor/scripts/${s}.sh --self-test; done` plus the precision-probe step. *Graded at Stage 9 QC3.5 on the merged PR.*

---

### Operator Decisions (D-gates)

#### D-Version: which version slot does this release claim?
**Gate input:** Rule-computed next-free, re-derived at live `origin/main` `876f8632`.
**Recorded determination — NOT a gate.** Next-free `minor` = **`v4.19`** (recomputed at Engineering, 2026-08-08). The Stage-4 determination recorded `v4.17`; that slot and the one after it have both since been claimed — see § Release Identity and the R-6 row.
**⚠️ The `v4.16` determination is REFUTED — and it is recorded on this sub-task, so it needs correcting at the source.** The prior comment on #5031 (`2026-08-08T01:59:37Z`) records `D-Version = v4.16` on the basis "`RELEASE_LOG.md` highest `v4.*` row = `v4.15`" and "`git tag -l 'v4.*'` highest tag = `v4.15`". Both operands have since moved. Evidence: `git tag -l 'v4.*'` now shows **`v4.16` exists**, pointing at `876f8632` — claimed by PR #4980 (`release/265-methodology-fields-and-statuses`) at 2026-08-08T10:59+0900, roughly an hour after that determination was recorded and minutes into this planning run. `RELEASE_LOG.md` still tops out at `v4.15` because #4980's Stage 13 close-out has not written its row, so the ledger operand **agrees with the stale answer** and cannot catch the drift. This is precisely the failure #4924's own plan records at its D-13: **the tag is the authoritative freeness surface; the ledger alone returns a false PROCEED.**
**Identity:** slug-primary per ADR-092 — branch `release/ci-wiring-and-flake-elimination`, plan file `ci-wiring-and-flake-elimination_RELEASE_PLAN.md`, no version stem. `v4.19` is **provisional**; it binds at the Stage-12 atomic compare-and-swap and re-verifies against the tag surface there. Bump class `minor` (capability/remediation, not corrective against a deployed release).
**Contention:** three-way on the `minor` slot — this release, #4924 (`minor`, slug-only), #4979 (still carrying a now-dead `v4.16`). Recorded as a Tier-S edge (R-6).
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface.
**Reversibility / Confidence:** CHEAP / HIGH.

#### D-C: Branch topology — SINGLE or OPTION-A?
**Gate input:** A4 contention map (within-release contention = **zero**), 3 cards, 1 dependency edge, 1 external contending PR.
**Gate decision:** **(A) SINGLE** *(recommended)* — one `release/ci-wiring-and-flake-elimination` branch, one PR, one merge · **(B) OPTION-A** — per-issue branches and per-issue PRs.
**Recommendation: SINGLE.** Within-release file contention is empty, so OPTION-A's isolation benefit is nil — it would buy nothing and add three PR-merge orderings to manage against a live external collision (#4924). The `#3832 → #3936` edge is a hard sequence that SINGLE enforces for free via commit order, whereas OPTION-A would push it to PR-merge ordering at Stage 12 — the same serialization on a worse surface. This also honors the standing one-milestone-one-PR-one-merge posture.
**Blocks:** Stage 6 Engineering routing; the Stage-4 plan's commit path (Engineering Commit 0 under SINGLE).
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface.
**Reversibility / Confidence:** CHEAP / HIGH.

#### D-Concurrency Posture: Stage-6 parallelism posture?
**Gate input:** D-C = SINGLE, contention map empty, wave count 3, one hard edge.
**Gate decision:** **P0 fully-serial** *(recommended — and the default when undeclared)*.
**Recommendation: P0.** SINGLE topology **is** P0 by construction. The one hard edge plus a live external collision makes any opt-in parallel posture a net risk for a 3-card release. Force-push (including `--force-with-lease`) on the shared release branch is prohibited under any non-serial posture; P0 keeps that moot.
**Upstream compatibility:** N/A — does not modify skill-authoring surface.
**Reversibility / Confidence:** CHEAP / HIGH.

#### D-ReleaseClass: `routine`, or something stricter?
**Gate input:** Milestone declares `routine`. Stage-4 evidence re-derived below.
**Gate decision:** **(A) `novel`** *(recommended)* · **(B) retain `routine`** · **(C) `cross-cutting`**.

**Challenging the declared `routine` — trigger-condition evidence:**

| Class | Trigger | Fires? |
|---|---|---|
| `routine` (a) | all issues P3/P4 **+ size:S/M** | **NO** — #3832 is `size:L` |
| `routine` (b) | all change-spec files have ≥3 prior release touches | YES for most of the 34 |
| `routine` (c) | zero new files added | YES *under the recommended plan*; **NO** if D-ScopeBoundary (c) is selected |
| `routine` (d) | zero new D-class decisions in the release plan | **NO** — two genuinely new, non-recurring D-decisions below |
| `novel` (a) | ≥1 issue introduces a new reference doc/schema/skill | conditional on D-ScopeBoundary (c) |
| `novel` (b) | **≥1 D-class decision in the release plan** | **YES** — `D-ScopeBoundary` and `D-SiblingSequencing` are substantive, multi-option, not rule-determined |
| `cross-cutting` (a) | ≥3 `pipeline/stage-*.md` files | NO — zero |
| `cross-cutting` (b) | ≥3 of the named governance surfaces | NO — zero |
| `cross-cutting` (c) | ≥3 in-bundle compositional edges | NO — one edge |

**Recommendation: `novel`.** Two `routine` triggers are affirmatively falsified, `novel` (b) fires, and `cross-cutting` fires none — so multi-trigger resolution lands on `novel`. The substantive argument is not the trigger arithmetic: a release whose scope grew 49 % between the readiness gate and planning entry, whose ACs must all be restated, and which collides live with an in-flight sibling on both of its surfaces, is not a release that should run at Light engagement density and Standard review depth. **Learnings support this:** both in-flight sibling releases (#4924, #4979) had their Stage-3 class **re-rendered to `novel` at their Stage-4 gates** — 2 of 2 recent precedents corrected in the same direction.
**Differentiation posture under `novel`:** engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.
**Blocks:** engagement density for every subsequent routing decision; Stage 5 activation; Stage 9 depth.
**Upstream compatibility:** N/A — does not modify skill-authoring surface.
**Reversibility / Confidence:** CHEAP / HIGH (`routine` → `novel` is cheaper-to-stricter; revertible at the next gate).

#### D-ScopeBoundary: what exactly is #3832 and #3936 accountable for?
**Gate input:** #3832's census grew 49 % post-gate and keeps growing; Arm D names 6 unwired suites where #3936 scopes 5.
**Gate decision — two independent parts:**

**(i) #3936 — 5 suites or 6?**
· **(a)** wire the 5 in `release/tools/tests/` *(as filed)*, and record the 6th, `core/deploy/tools/tests/test-status-label-invariant.sh`, as explicitly out-of-scope with written rationale · **(b)** *(recommended)* wire all **6**, so `ARM D PASSED` becomes the card's verification method.
**Recommendation: (b).** Arm D is the governed detector and it reports 6. Leaving one behind means the card's own verification cannot be the governed check — it would have to be a hand-rolled filename sweep, and the job would still emit an Arm D warning after the card ships. The Mode R gate already applied exactly this reasoning to widen 1 → 5 ("wiring one and leaving four is a point-fix on a class"); 5 of 6 is the same shape. Marginal cost is one `run:` line.

**(ii) #3832 — what form does the AC take?**
· **(a)** keep the repo-wide "zero hits" AC · **(b)** *(recommended)* pin the AC to the **34-file set at baseline `37f68a2b`**, carrying the payload-string exemption · **(c)** (b) **plus** a durable CI guard that fails on any *newly introduced* site.
**Recommendation: (b), with (c) as the strongly-preferred variant if the operator will accept one new file.** (a) is ungradable — the population moved 49 % in two days and #4924 will move it again by +17; an AC that can be true at merge and false hours later is not an AC. (b) makes it gradable. (c) is what actually closes the class: the +44 sites arrived because three *brand-new test suites* were written using the idiom, with nothing to stop them — a sweep without a guard has a measured decay rate. Note (c) flips `routine` trigger (c) and fires `novel` trigger (a), which is consistent with the `novel` recommendation above, and it fires the new-executable companion obligation (allowlist rows + CI wiring statement) already planned for in the File Change Matrix.
**Blocks:** Stage 5 design for both cards; Stage 8 AC grading.
**Upstream compatibility:** N/A — does not modify skill-authoring surface.
**Reversibility / Confidence:** (i) CHEAP / HIGH · (ii) (b) CHEAP / HIGH, (c) MODERATE / MEDIUM.

#### D-SiblingSequencing: this release vs PR #4924
**Gate input:** #4924 shares 5 files with #3832, adds +17 sites to its surface, and edits #3936's only file. Both PRs are drafts; #4924's timing is unknown.
**Gate decision:** **(a)** *(recommended)* proceed now; #3832's AC pins to baseline `37f68a2b`; the obligation to convert #4924's own new sites falls on #4924 as the later merger · **(b)** hold this release until #4924 merges, then re-derive the census · **(c)** coordinate — ask #4924 to adopt the safe idiom in its new files before merge.
**Recommendation: (a), with (c) as a free addition.** (b) blocks a ready 3-card release on a draft PR with no committed timeline, and forces a full 34-file census re-derivation afterward — trading a certain delay for an uncertain one. (a) plus a pinned AC absorbs the residual. (c) costs a comment on #4924 and would prevent the +17 from ever landing; it is not mutually exclusive with (a).
**Blocks:** Stage 12 merge ordering; #3832's AC baseline.
**Upstream compatibility:** N/A — does not modify skill-authoring surface.
**Reversibility / Confidence:** CHEAP / HIGH.

---

### Verification Plan

**Per-issue verification**

| Issue | Verification method | Expected result |
|---|---|---|
| **#4188** | (1) `bash core/skills/finops-usage-extractor/scripts/extract-usage.sh --self-test` — must now exercise the **carry-forward** branch, not the no-source-change early return; (2) the `release-tooling-smoke.yml:858–880` precision probe re-run; (3) a fixture run of `--incremental` with prior records present | (1) exit 0 and the new branch is provably reached; (2) still exits **non-zero** with the reserved seed removed — the probe is not disarmed; (3) prior session records **survive** the rewrite |
| **#3832** | Per phase, the card's own probes over the pinned 34-file set: Phase 1 `if printf…\|grep -q` → 0; Phase 2 `printf…\|grep -q` → 0; Phase 3 `grep…\|head` → 0 or exempt-with-rationale. Plus the full install-regression suite on the macOS runner **after each phase**, and the >64KB-haystack early-match fixture under `pipefail` | 0 hits per phase over the pinned set; suite green after each of the three phases; the fixture does **not** false-FAIL, demonstrating the conversion fixes the defect rather than merely compiling |
| **#3936** | `python3 release/tools/check-selftest-coverage.py --reconcile` (the governed check, Arm D) + the `closeout-smoke` job + the negative test | `ARM D PASSED — every committed test suite is referenced by >=1 workflow`; all newly-wired steps green; a deliberately-broken assertion in `test_structural_blast_radius.sh` propagates exit 1 and **fails the job** |

**Baseline probe record (reproduce with these exact invocations).** Every count in this plan carries: invocation, denominator, sensitivity arm with observed non-zero, specificity arm with observed zero, non-empty extraction for subject and both arms.

| Claim | Invocation | Denominator | Sensitivity (observed) | Specificity (observed) |
|---|---|---|---|---|
| 5 unwired of 12 | per-basename `grep -rlF "<basename>" .github/` over `release/tools/tests/test_*` | 12 basenames; 37 files under `.github/` | `test_domain_blast_radius.sh` → **1 file** (non-zero) | fabricated `test_zzz_nonexistent_control.sh` → **0** |
| no loop-runner masking the sweep | `grep -rnF 'release/tools/tests' .github/` | same | **8 hits**, all hardcoded single-script `run:` lines | — (positive-result probe) |
| 89 / 42 / 45 / 34 | the three issue-verbatim `grep -rnE … --include="*.sh" .` probes | 141 `*.sh` files | probe reproduces recorded 65/**31**/25/32 exactly at `86bc649e` | fabricated `zzprintfzz…` → **0**; `#3210` control file `test_sandbox_roots.sh` → **0** residual while containing 3 `grep -q` (so the file is reachable) |
| within-release contention = 0 | pairwise path-set intersection | 3 cards, 3 ordered pairs, 36 path-slots | `#3832 ∩ #4924` → **5** (non-zero) | `#4188 ∩ #3936` → **0** on sets disjoint by inspection |
| #4924 = 85 files, #4979 = 15 | `gh api …/pulls/N/files --paginate` **and** `git diff <merge-base>..<head>` | 2 open PRs | two independent methods agree exactly | first method (`gh pr view --json`) returned identical 48-path lists → **rejected as broken probe** |
| Arm D = 6 unwired | `python3 release/tools/check-selftest-coverage.py --reconcile` | 4 `TEST_SUITE_GLOBS` | ARM B / ARM C both PASSED in the same run (engine live) | at `86bc649e` the tool **does not exist** → correctly emits nothing |

**In-Flight Release Roster**

**Measured at:** `37f68a2b` · re-measured `876f8632` · 2026-08-07 (Friday) · **Population:** n=**2** siblings

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `hub-spoke-execution-safety` | `#4924` | `246f353b` | `minor` | slug-only (no number carried) | `v4.17` | `core/deploy/deploy.sh`, `core/deploy/tests/run-install-regression.sh`, `docs/scripts/setup-workspace.sh`, `release/tools/cleanup-orphan-state.sh`, `update.sh`, `.github/workflows/release-tooling-smoke.yml` |
| `102-specialist-role-coverage` | `#4979` | `290b5180` | `minor` | **`v4.16` (STALE — slot claimed by #4980)** | `v4.17` | — |

`265-methodology-fields-and-statuses` left the roster during this run: merged at `876f8632`, claiming `v4.16`.

---

### Recommendations

1. **Correct the handed-down D-Version before anything else.** `v4.16` is taken (tag → `876f8632`, PR #4980). Next-free is **`v4.17`**, provisional until the Stage-12 atomic claim. Confirm freeness against `git tag`, never `RELEASE_LOG.md` — the ledger is 1 release behind right now.
2. **Amend the milestone (Tier 1 `[BUNDLE AMENDMENT]`), do not re-bundle.** Membership is unchanged and correct; only scope facts moved. The A0 confidence gate rendered `amend` on a corroborated-and-grounded signal from three independent sources.
3. **Refresh all three issue bodies at A0.5 before Engineering:** #3832's five measurable ACs (`65→89`, `31→42`, `25→45`, `32→34`, `90→134`); #3936's denominator (`11→12`) and its `#3702` rationale (Arm D reaches them but is WARN-only and executes nothing); #4188's design constraint about the precision probe.
4. **Take D-ScopeBoundary (ii)(c) if you will accept one new file.** The evidence that a sweep alone decays is already in hand: 44 new sites arrived in two days from three brand-new test suites, and #4924 has 17 more queued. Without a guard this card buys a fix with a measured half-life — which is itself an instance of the failure class this release's Outcome Statement names.
5. **Comment on PR #4924 now (D-SiblingSequencing option (c)).** Asking it to adopt the here-string idiom in its four new files is a zero-cost coordination move that prevents +17 sites from ever landing, and it is independent of the sequencing choice.
6. **Update the milestone's Parallelization Map.** It is stale-dated (2026-07-28) and does not carry the Tier-S version-slot edge now contended three ways.
7. **Out-of-scope discoveries (noted, not actioned):**
   - `release/tools/tests/ac3_concurrent_load.sh` (added by #4924) is CI-unwired and, because its name does not match `test_*`, is invisible to **both** #3936's AC and Arm D's globs. A genuine gap in the detector's own coverage, owned by neither card.
   - `check-selftest-coverage.py`'s exclusions list flags `release/tools/cleanup-orphan-state.sh` as *"1 exclusion suppressing an in-scope tool that genuinely DISPATCHES on `--self-test`"* and requires each such exclusion to name a tracking issue. That file is also in #3832's remediation set (3+3 sites) — worth checking whether the tracking issue exists.
   - `RELEASE_LOG.md` is missing its `v4.16` row while the tag and merge exist — #4980's Stage 13 close-out appears incomplete.

---

### Canonical-checklist attestation

Every codified Phase step in `release/references/pipeline/stage-04-planning.md` ran, or is recorded N/A with reason.

| Step | Status |
|---|---|
| **G-PL5** Mode R briefing cache-read | **RAN — MISS**, reason recorded (no marker-bearing comment on #5031). PT-1..4 run live; `rows_source: re-derived` |
| **Phase A0** Triage→Design re-review (§1 6-column) | **RAN** — 8 header fields authored; 10 rows; 2× C3/PT-1, 5× C2, 3× C1 |
| Ticket-architecture reconciliation | **N/A** — no card touches an ADR / discipline / registry / ledger / roadmap surface |
| Architecture evaluative-lens (advisory) | **RAN** — one advisory finding (K1-ambition/K3-enforcement seam), routed to D-ScopeBoundary, non-blocking |
| **A0.5 / G-PL1** AC-currency | **RAN — FAIL** → Tier 1 [ADJUST] on all three cards |
| **A0.6 / G-PL2** pre-plan crisping | **RAN — PASS** with positive evidence per card (Rule 3) |
| **A0.7 / G-PL3** placement forward-check | **RAN — SKIP** (empty mover-set; correct non-ceremony signal). Zero new files planned |
| **A0.8 / G-PL4** bundle-entry freshness re-verify | **RAN** — 3/3 cards had runnable checks; verdicts admit-still-valid ×2, re-scope-changed ×1 |
| Parallelization-Map currency check | **RAN — stale-dated** → Tier 1 [ADJUST]; Tier-S re-derivation surfaced a new version-slot edge |
| A0 currency-decision confidence gate | **RAN** — corroborated-and-grounded; outcome `amend`; no PAUSE loop required |
| **A1** Milestone validation entry gate | **RAN** — 3 cards, all `status: bundled`, milestone assigned, Composition Lock honored (membership unchanged) |
| **A1.5** Domain-best-practice sourcing-or-flag | **RAN** — pipeline-internal exemption from *external sourcing*; `domain_practice` label authored with mandatory `domain: software` class |
| **A2** Dependency-ordered sequencing | **RAN** — 1 hard edge verified by re-measurement; sequence retained |
| **A3** Per-issue change specification | **RAN** — File Change Matrix, 36 paths, all `edit`; new-executable companion obligation evaluated and does not fire (conditional path planned) |
| **A4** File contention resolution | **RAN** — within-release empty (control-armed); Cross-PR Overlap Audit run against live population, baseline pinned; one broken probe caught and corrected |
| A4 ext. Structural-blast-radius sub-audit | **RAN** — no corpus mover-set in this release; version-slot token `Δversion/minor-next-free` contended 3 ways → Tier-S edge recorded |
| A4 ext. Sibling-merge stale-pin self-invalidation | **RAN and FIRED** — #4980 merged to `main` during planning; audit re-run against `876f8632`; findings unchanged for the code surface, version slot changed |
| **A5** Release plan assembly | **RAN** — all required sections present incl. Rollback Strategy and Verification Plan |
| **A6** Quota-budget pre-check (terminal) | **RAN — WARN**, split-batch 2+1 recommended |
| Cross-Issue Acceptance Criteria | **RAN** — 3 CIACs authored (non-zero, so section present) |
| **G4** Plan Readiness (G4-01..05) | Structural sections all present: Implementation Sequence · File Change Matrix · Risk Register · Verification Plan · Delivery Strategy (D-C SINGLE / P0 / one PR / one merge) |
| **Phase B** operator approve/modify/split/hold | **PENDING** — this is the operator's gate; 6 D-decisions surfaced, 4 scope findings raised |

**Note on issue closure phrasing:** all three cards are to be **marked as closed at Stage 13**; no close-family verb is paired with an issue reference anywhere in this plan, so transcription into a PR body cannot trip GitHub's auto-close parser.
