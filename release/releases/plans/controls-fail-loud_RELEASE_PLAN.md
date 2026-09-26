---
title: Release Plan — controls-fail-loud (a control that cannot evaluate its subject says so)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.70; the concrete number binds at the Stage-12 atomic claim)
milestone: controls-fail-loud
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH — one branch and one merge; every card reverts with its own commits, and reverting the merge restores main byte-for-byte. MODERATE rather than CHEAP because the release changes CI-gate exit contracts and a pre-launch gate, and two cards need a deployed-copy refresh on revert (the fragile-reference hook tier and the release-hub package). A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `controls-fail-loud`

**Milestone:** `controls-fail-loud` (ms#334) · Stage-4 sub-task **#7683** = the approved plan (parts 1–3), the Stage-4 gate **Decision Recorded** comment, the scaffolding record, the **Collective Review** scope-lock record, the pacing record, the D-Version re-determination and the short scope lock for #6237 · **#7801–#7807** = the seven Stage-5 designs (#4318, #5287, #4917, #7199, #6865, #6237, #6871 in that order), each with the hub's evaluation · **#7878–#7884** = the seven independent Phase A6.5 adversarial reviews, each with the hub's consumption · **#7808** = the Stage-6 Engineering sub-task whose spoke (card #4318, order 1) authored this file.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.70`**. Recorded as a determination (not a click-gate) at the Stage-4 gate, where the rule computed `v4.69`; `egress-hook-batch` then claimed `v4.69` at its merge, and the hub's D-Version re-determination moved the display to `v4.70`. The Commit-0 re-verify below re-ran both halves against fresh host state. The concrete `vX.Y` binds only at the Stage-12 atomic claim (ADR-092), so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp placeholder.

**Topology:** D-C **SINGLE** — one release branch (`release/controls-fail-loud`), one PR opened in draft immediately after this commit so the pull-request checks run on every later slice (hub action item AI-009), one merge, base `main`.

**Concurrency posture:** **P0 fully-serial**, in the order #4318 → #5287 → #4917 → #7199 → #6865 → #6237 → #6871. Force-push, including `--force-with-lease`, is prohibited on the shared branch.

**Release class:** `cross-cutting` (trigger (c): four in-bundle compositional edges). Stage 9 review **Deep**. See § Release Class declaration.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on #7683 (parts 1–3) and the Stage-4 gate **Decision Recorded** comment on it — whose amendments bind this commit (AC-Binding: an amended criterion obliges its bound row in the same change) — reconciled to the seven approved Stage-5 designs, the seven adversarial reviews and every operator decision recorded since: the **Collective Review** scope lock, the pacing decision, the D-Version re-determination and #6237's short scope lock. **Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority.** Card-level design detail (change specifications, arm tables, region maps) stays in each card's Stage-5 output; each card's Stage-6 spoke transcribes what its commits realize and records any further delta here. Every thread comment consumed was `OWNER`-authored (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — provisional display v4.70 (re-determined from v4.69, which another release claimed); binds at the Stage-12 atomic claim |
| **Date Created** | 2026-09-24 (Thursday) — the Stage-4 plan approval; committed as Engineering Commit 0 on 2026-09-25 (Friday, local) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing — Stage 6 Engineering, order 1 of 7 |
| **Branch** | `release/controls-fail-loud` |
| **PR** | opened in **draft** immediately after this commit per the SINGLE topology; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `controls-fail-loud` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-24, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): every row of the matrix targets an internal `pmo-platform` artifact. Software dominates — `deploy.sh`, a hook, `automated-closeout.sh`, two new release tools, tests and workflows — with governance (the gate-efficacy standard, the quota protocol) and security (a fail-closed hook) secondary. Transcribed unchanged from Stage-4 Phase A1.5 and carried unchanged by all seven Stage-5 designs; no Mode-B label existed to upgrade.

---

## Commit-0 Version Re-Verify Record

Run in full at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location.

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `35dbf418` (the `v4.69` Stage-13 corpus merge), 35 commits past the Stage-4 baseline pin `8e0ee084` |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `bash release/tools/claim-version.sh --sha 35dbf41847df2c1deab792d2944e46ac6ddd26fd --bump minor --dry-run` (the adapter's own `anchor()` + `claimed_set()`; no tag pushed) | **`v4.70`** (rc 0) — equal to the recorded provisional display |
| **3** | HALT on collision: the planned version must be absent from every `claimed_set()` arm AND equal the recomputed next-free. The tag arm binds; published Releases and the RELEASE_LOG corroborate | **no collision; PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.6*' 'refs/tags/v4.7*'     (tag arm — binds)
             grep -c '| v4\.70 ' <git show origin/main:release/releases/RELEASE_LOG.md>  (ledger arm)
             the adapter's claimed_set(), via --dry-run above                     (all three arms, unioned)
Denominator: every v4.6x/v4.7x tag on origin (v4.60 .. v4.69 plus v4.67.1); the RELEASE_LOG
             at origin/main, read with git show (never the worktree copy)
Control - sensitivity: the SAME readers on the v4.69 slot — tag arm: refs/tags/v4.69 present;
             ledger arm: 1 row (v4.69 egress-hook-batch VERIFIED). Every arm resolves and returns
             non-zero there, so a zero on the v4.70 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over an exact version tuple has
             no near-miss class
Extraction:  the full filtered ls-remote output; the full ledger read from origin/main
Result:      0 occupants of the (4,70) slot on every arm; the adapter recomputes v4.70
Verdict:     CLEAN — v4.70 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** three sibling releases carry `release/*` heads and open draft PRs, and all three recompute to the same slot — see § In-Flight Release Roster. None has claimed; the Stage-12 atomic claim arbitrates, so this release may claim `v4.71` or higher.

### Manifest half (step 3b, post-write / pre-commit)

`release/tools/claim-version.sh --verify-stamp controls-fail-loud` — run after this file was written and before it was committed. Required exit **0**. Result recorded in § Verification Evidence.

This plan carries **exactly one** double-brace `RELEASE_VERSION` placeholder — the Header `**Version**` cell — and every other mention names the placeholder instead of reproducing it. The claim tool resolves the token by global substitution across the whole file, so a literal prose citation would be rewritten at Stage 12 along with the record site.

### Commit-0 Survival Set

Every element the Stage-4 gate determined that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). A transcription that drops one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, no Mode-B rationale required) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1..6`) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (with the Stage-4 amendments as OBL rows and the 27-criterion AC baseline) | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, named rather than reproduced) | § Header `**Version**` cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | § Baseline pin |

---

## Scope

**Seven cards, one cause class (C09: an instrument failure or an absent input rendered as a verdict), two limbs.** Limb A — a check that did not measure reports clean — is #4318, #5287, #4917 and #7199. Limb B — an instrument's own failure is reported as a verdict about its subject — is #6237, #6865 and #6871. No dependency edge crosses the limbs.

| # | Issue | Problem | Size | Labels |
|---|---|---|---|---|
| 1 | #4318 | The close-completeness probe declares a verdict-driven red exit its body does not implement: in warn mode it exits 0 on an INCOMPLETE verdict, and SKIP exits 0 too | M | bug · cluster: automation · project:pipeline · project:platform-quality |
| 2 | #5287 | Automated checks silently omit part of the surface they are believed to cover; nothing requires a check to declare its population or report what it examined | L | improvement · cluster: automation · project:governance-hygiene |
| 3 | #4917 | The never-FAIL class: three sub-shapes of a control reporting success without measuring, each needing a different fix | L | bug · cluster: automation · project:pipeline · project:platform-quality |
| 4 | #7199 | `release/README.md` advertises `release/schemas/*`, one of three roots that have never existed; the same roots sit in a check's scan list, a hook and a workflow | S | improvement · type:bug |
| 5 | #6865 | The fragile-reference hook fail-closes on a valid Write above the argument-size limit and reports it as malformed JSON | S | bug |
| 6 | #6237 | Checkpoint B's host-API axis renders PROCEED on an unstarted window it cannot distinguish from a fresh one | L | bug · project:platform-quality |
| 7 | #6871 | Close-out resolves the merge SHA over GraphQL, which is exhausted exactly when close-out runs | M | bug |

**Size:** 36 raw / 47 effective (`cross-cutting` × 1.3) after the Collective Review's re-sizes (CR-B4), held by an extended G3-15 Override. The Stage-4 figure was 26 raw / 34 effective.

**Acceptance criteria.** The criteria's single home is each issue body: 27 checkbox criteria across the seven cards, plus the Stage-4 amendment blocks appended to each body at the Stage-4 gate. § Verification Plan binds each checkbox criterion by ordinal (AC rows) and carries every Stage-4 amended or added criterion as an OBL row, because the AC-binding oracle reads only the checkbox list (hub action item AI-003).

**Explicit non-scope.** #7466 keeps only its criterion 5 (convert the fused exit-space sites outside Check 48) and stays unmilestoned (D-Dup-7466); the release PR references it and does not resolve it. The Check 32 Surface-1 residual is recorded, not fixed (#4917's census names it, dormant). The drift engine's own exit contract belongs to #4714.

---

## Decision Record

### Stage-4 gate (operator, 2026-09-24)

Every recommendation was accepted, and the plan is approved as the scope lock.

| # | Decision | Outcome |
|---|---|---|
| D1 | **D-Size** | Keep all seven under a new G3-15 Override granted for this composition; the 2026-08-16 exception does not carry |
| D2 | **D-Outcome** | Adopt the reconciled Release Outcome Statement (§ Release Outcome Statement), under the verbatim H3 heading |
| D3 | **D-7199** | Approve (the missing Stage-2 verdict). Re-scope #7199 to its full population (16 lines in 7 files); the zero-resolving-root reporting mechanism belongs to #5287; size XS → S |
| D4 | **D-Dup-7466** | Allocate by criterion: #4318 absorbs #7466's criteria 2–4 and 6; #4917 absorbs criterion 1 as its census population; #7466 keeps criterion 5 and stays unmilestoned |
| D5 | **D-Drain-48 + D-Instr-48** | #4318 absorbs both: drain the 7 false version-less CHANGELOG findings, and give an instrument failure in the Surface-1 sub-check its own not-evaluated state; coordination note on #6872 |
| D6 | **D-ReleaseClass** | `cross-cutting` (trigger c). Engagement Tight · Stage-9 review Deep · Stage-5 activation ALL · Stage-13 outcome window 30-day |
| D7 | **D-C + D-Concurrency** | SINGLE branch + P0 fully serial — one release branch, one PR, one merge |
| — | **D-Version** (recorded determination) | `versioned` · minor · provisional `v4.69` at the gate; re-determined to `v4.70` (below) |

**Hub findings adopted with the approval:** the D-Instr-48 evidence (a clone whose remote the tool cannot resolve reports `INCOMPLETE — 84 89`, 75 false "absent" findings with the 13 real body-drift findings masked, against `INCOMPLETE — 22 89` from a resolvable one); a Parallelization-Map row for `telemetry-is-computable`; the risk that three releases rebuild the release-hub package (R18); and the measured #6865 population (37 `"$PRINTF"` lines, 13 input sites, six unbounded report emits).

### Stage 5 — Checkpoint B override (operator, 2026-09-25T08:38Z)

Checkpoint B rendered DEFER after two Stage-5 spokes (#4917, #6865) stopped at the account session limit, which lowered the usage-window basis to SERIALIZE under the observed-interruption rule. The operator overrode to PROCEED at **width 1**, one spoke at a time, for that batch only (hub action item AI-007). The Phase A6.5 review wave was later serialized the same way, one review at a time in Stage-6 order.

### Collective Review scope lock (operator, 2026-09-25)

Every recommendation was accepted; verdict **APPROVE**. Six cards locked through Stage 9; #6237 returned alone to Solutioning, then locked separately (below).

| ID | Decision | Operator choice |
|---|---|---|
| CR-B0 | #6237 Blocker: the specified GraphQL probe is not charged, so its declared-draw anchor cannot see a fresh window | Return #6237 alone to Solutioning; CD-1 is the directed repair |
| CR-A1 | May an instrument that could not evaluate gate, and in which mode? | **(ii):** #4318 NE-b — Check 48's NOT-EVALUATED exits 3 under every sentinel, with cause-conditional escalation decided at the enforce flip; #6865 P2 (mode-coupled per ADR-078). The ADR-134 amendment (G-6) is not needed |
| CR-A2 | Reach of #5287's population rule | **S2** (REQUIRED for file-root populations this release; list/glob, sub-file and rows populations named as non-detections) + **D-4917-3 (A)** (convert Check 47 in #4917) + **(a)** (#7199's gate edit carries its declaration, an examined count, and NOT-EVALUATED on a failed diff) |
| CR-A3 | Drift engine exit 3 after step (h) | **(a)** #4318's Change 4 `3)` arm emits NOT-EVALUATED, as exit 2 does |
| CR-A4 | #5287/#7199 D-9: the `.claude/rules` root | **(B)** repoint it to `core/rules`, with the operator's V-8 read before merge; add non-detection item 5, "a narrowed declaration" |
| CR-A5 | #5287 P6 on an empty ledger | **(A)** build P6 from a synthetic ledger fixture, plus the same fix on the posture harness's C5 summary line |
| CR-B1 | #4917 D-4917-4: the vacuous install-regression precision probe | **(A′)** repair it in #4917, deriving the member list rather than restating it |
| CR-B2 | #6865 D-Swallow | **(a′)** a compile canary for the four grep EREs at the constants gate; the hardened detector form for the transport residual |
| CR-B3 | D-F5: repair owner for the three graduated instances | **(b)** file one repair card (operator signed off its creation) |
| CR-B4 | Aggregate size | Accept #6871 S → M, #6237 M → L, #4917 M → L: 36 raw / 47 effective under an extended G3-15 Override |
| CR-B6 | #6871 D-6 | **CD-2:** under `--apply`, `read_state` fails closed before any write unless the release PR is answered as merged into `main` (DEFERRED excepted); `--dry-run` records and predicts |
| CR-BUNDLE-1 | As designed | #4318 D-1 (the four-member exit contract through one factored function) and F-3 (include the one `hub-spoke-bridge.md` sentence); #5287 D-2 to D-8 and D-10; #7199 D-R (A) with the two README token fixes |
| CR-BUNDLE-2 | As designed | #4917 D-4917-1 (census definitions), -2 (C), -5 (B), -6 (A), and the census ADR |
| CR-BUNDLE-3 | As designed | #6865 D-Blast (A); #6871 D-1, D-3, D-4 and D-5 |
| CR-BUNDLE-4 | Advisory flags | Move #7199's scope predicate into the shared pattern file; map #4318's cause tokens to the § 4.3b host-refusal classes; keep #4917's census rows where designed |

### Pacing decision (operator, 2026-09-25)

The account's weekly allowance read 77% after the scope lock (reset 2026-10-01 05:00Z, a Thursday), and the remaining pipeline was estimated at more weekly points than were left. The hub recommended finishing #6237's re-design and pausing Stage 6 until the reset. **The operator chose to continue without a pause and to make every phase resumable from a new hub session** (a divergence from the recommendation). Resumability is carried by the staged briefs, the pending-approvals surface, a resume pointer, a Stage-6 resume check that continues from work banked on the release branch, and write-early commits.

### D-Version re-determination (hub, recorded determination)

`v4.69` was claimed by `egress-hook-batch` (its tag sits on that release's merge commit `40cec0c7`). With no `v4.70` tag on the remote and no `v4.70` ledger row at `origin/main` (the `v4.69` rows serving as the control), the provisional display moved to **`v4.70`**, re-verified at this commit (§ Commit-0 Version Re-Verify Record). The version still binds only at the Stage-12 atomic claim; `verifier-grades-what-plans-declare`, `closeout-verification-rows-consistent` and `telemetry-is-computable` contend for the same slot.

### Short scope lock for #6237, with #6871 D-2 (operator, 2026-09-26 UTC)

Every recommendation was accepted; #6237's amended design is hard-locked through Stage 9, and all seven cards are now scope-locked.

| ID | Operator choice |
|---|---|
| ML-D-1′ | the GraphQL half of the declared-draw anchor: α a charged `__typename` probe · β the most conservative anchored reading on persistent disagreement · γ agreement means the same reset **and** `used` rising by at least the probe's draw |
| ML-D-4′ | grades per pool (`core` sourced; GraphQL an assumption to confirm until three clean releases); calibration events recorded as hub action items; the upgrade decided by ADR |
| ML-D-6′ | one re-probe per pool: 3 metered calls nominal, at most 5 |
| ML-D-7 | the `repo_host` interface altitude: (i) a named gap on the interface, owned by the repository-platform adapter work (#10), on the ADR-109 decision-5 precedent |
| ML-D-8 | the evaluator's repository derivation: (a) a repository-free probe (`GET /versions`, metered on `core`); `--repo` removed |
| ML-D-9 | the backoff bound: `min(60 × 2^N, 3600)` seconds, `[CALIBRATE-AFTER-3]` |
| ML-6871-D-2 | **B2:** #6237 authors `release/tools/lib/host-refusal-class.sh` (transport-aware, the full binding, #7884's boundary fixes); #6871 only sources it, and its library row, evaluator-edit row and Commit 7.0 drop out |
| ML-6871-size | #6871 stays M |

### #4318 — design decisions as locked (Stage-5 design #7801, Collective Review, Tier-1 routing)

| Decision | As locked |
|---|---|
| **D-1** exit contract | **(B)** the family's four-member contract through one factored `_cc_verdict_exit_code`: `0` CLEAN, its sole producer · `2` INCOMPLETE advisory under a non-enforce token · `3` NOT-EVALUATED (network leg unmeasured) or SKIP (whole gate withheld) · `1` blocking under `enforce`, or an unexpected verdict. Rejected: a verdict-driven red exit in warn mode (needs a second sentinel reader in YAML), the status quo (three producers of 0 — infeasible under amended AC-5), a fifth member |
| **D-2** the `3` member under `enforce` | **NE-b** (CR-A1 (ii), overriding the design's NE-a): NOT-EVALUATED exits **3 under every sentinel** — it never gates, per ADR-134 D3/D5 and PV-7c; SKIP stays sentinel-aware (3 under warn, 1 under enforce). Escalating NOT-EVALUATED by cause is decided at the enforce flip and is stated in the register row's flip clause, keyed to input-failure causes only |
| **D-3** Surface-1 instrument | **I-4:** resolve the repository once through gh's own remote resolution, read the published set once through the existing `_vf_published_tags_from_api`, test membership per row; any instrument failure, or an empty set, is NOT-EVALUATED, never "no published GitHub Release" |
| **D-4** roll-up | INCOMPLETE > NOT-EVALUATED > CLEAN; one aggregate NOT-EVALUATED stderr line (fan-in), a DEGRADED rider on INCOMPLETE, a network-leg denominator line; the NOT-EVALUATED protocol line carries no findings counter (PV-7b) |
| **D-5** surfaces | **L-b:** both surfaces classify an instrument failure identically; the lifecycle Check 48 arm renders it through `flag_not_evaluated` (no mode branch, no ISSUES increment) |
| **D-6** scope of NOT-EVALUATED | **S-2** — every instrument failure of the network leg; **plus CR-A3 (a):** the drift engine's exit 3 after the published-Release read found the Release emits NOT-EVALUATED too, as exit 2 does. The note-content lint's instrument failures stay out (G-4) |
| **D-7** test home | **T-3:** extend the existing close-completeness `--self-test` block (arms (8)–(15)) plus RC-5b in group RC. #7878 CD-2 (a standalone test file under the required shell harness) is **not adopted** |
| **D-8** AC-7 mechanism | **K-1:** class-gate limb (d) through the existing version-only machinery, and move the CHANGELOG row of `release-corpus-schema.md` § Row classes to DECLARED EXCLUDED in the same commit |
| **D-9** declaration surfaces | reconcile all of them in the contract commit: the header table, the arms, the usage line, the dispatch comment, the lifecycle-block sentinel sentence, the sentinel file's comments, the bridge sentence, and the required-subset header's cross-reference |
| **D-10** commit topology | Commit 1 = contract, instrument, consumer, register row, sentinel comments, bridge sentence, self-test arms (8)–(15). Commit 2 = limb (d), the DENOM text, the schema row, RC-5b. Each preceded by an arm observed RED against the pre-fix code |
| **CR-BUNDLE-4** | the contract carries a table mapping each Check-48 cause token onto the § 4.3b host-refusal classes (answered · refused-quota · failed-transport · failed-other) |
| **#7878 F-1** (Tier 1) | the leg-level "instrument failure → NOT-EVALUATED" claims are scoped to the Surface-1 limb and to the drift engine's reported exits; the engine's `PUBLISHED_BODY=… \|\| true` body read, which still surfaces a failed read as §5.1 drift, is routed to #4714 and named, not fixed here |
| **#7878 F-2** (Tier 1) | a transport handshake: the probe prints one `close-completeness-exit: <code>` line immediately before its single exit, and `close-completeness.yml` honours 2 and 3 only when that line equals the return code; self-test arm (15) requires it. The family defect is #7889's and is not widened here |
| **#7878 F-3** (Tier 1) | the register row's flip clause adds the deletion of the workflow's `paths:` filter; the sentinel's graduation steps gain a drain precondition; the probe and the workflow name both remedies (Phase-B backfill for a missing output, the §5.6 re-emit for §5.1 drift) |
| **#7878 cosmetics** (Tier 1) | PV-7a's "this is not a clean result" clause, lowercase and mid-sentence, on the SKIP arm and the workflow warning lines; the Register A status in the `flag_not_evaluated` detail; the register row names the sensitivity arm by its number, (11) |
| **Canonicalization #3** | the mapping function is named `_cc_verdict_exit_code`. **Justification: documented precedent** `[SOURCE]` — the family's two shipped mapping functions are named `_<engine-prefix>_verdict_exit_code` (`_de_verdict_exit_code`, `_c32_verdict_exit_code`), and `_cc_` is Check 48's engine prefix (`_cc_compute_verdict`, `_cc_row_findings`, `_cc_is_allowlisted`) |

---

## Implementation Sequence

One branch (`release/controls-fail-loud`), P0, commits per card in the order below. **Limb A runs first, then limb B.** Each remediation lands an arm **observed RED against the pre-fix code** before its fix — or, where RED-first is impossible, an armed-red-then-revert record with its predictions stated before the run — recorded in § Verification Evidence (CIAC-6).

| Order | Card | What lands (locked design on its Stage-5 sub-task) | RED-first arm |
|---|---|---|---|
| **0** | — | **Engineering Commit 0:** this plan file, with the Commit-0 re-verify (steps 1–3, then 3b). The draft release PR opens immediately after it (AI-009) | n/a |
| **1** | **#4318** (#7801) | **Commit 1:** `_cc_verdict_exit_code` as the probe's only exit path, with the handshake line; the contract table and the cause-to-class table; the Surface-1 instrument (repository precondition + batch published-set read); the network-leg NOT-EVALUATED state on both surfaces, including drift exit 3; the lifecycle arm through `flag_not_evaluated`; `close-completeness.yml` rewired to an integer `case` that honours 2/3 only on the handshake; the register row restated; the sentinel's comments; the bridge sentence; every other declaration surface; self-test arms (8)–(15). **Commit 2:** limb (d) class-gated, the DENOM text, the schema row, RC-5b | arms (12)–(15) RED at the pre-fix probe (5 literal exits; INCOMPLETE/warn and SKIP exit 0; a failed lookup reported as absent; a binary RC test); RC-5b RED (1 version-less CHANGELOG finding) |
| **2** | **#5287** (#7802) | Requirement (b)'s `population:` field and Requirement (c)'s population-shortfall mode (S2: REQUIRED for file-root populations); the hoisted `_population_resolve` / `_population_report` pair and self-test group DP; Check 25 and Check 31 as the worked reference; the harness's fourth invariant with P6 on a synthetic ledger (CR-A5) and the C5 summary line fixed; the `install-tests.yml` comments; `decision-emission.yml`'s group count de-literalized | the harness real-instance arm (Check 25's four zero-yield roots reported) and the runtime arm, RED before the fix |
| **3** | **#4917** (#7803) | the exit-consumer and executor census in #5287's population-record form, asserted by the harness; the census ADR; Check 47's verdict tail converted (D-4917-3 (A)) with self-test group BD; the install-regression precision probe repaired (A′); AC-2 recorded as discharged (v4.60) | census armed-red-then-revert (a deleted row fails); Check 47's false clean observed on an unresolvable `origin/main` |
| **4** | **#7199** (#7804) | Check 25's three never-existing release roots removed and `.claude/rules` repointed to `core/rules` (D-9 (B)); #5287's ledger entries retired; the hook's and the workflow's dead scope arms removed, with the scope predicate moved into the shared pattern file (CR-BUNDLE-4) and the workflow gate edit carrying its declaration, an examined count and NOT-EVALUATED on a failed diff (CR-A2 (a)); the README tokens (D-R (A)); the split rule; the `check-doc-links.py` markers | direct RED observation at the pre-fix commit (the defects are present there; FR-13) |
| **5** | **#6865** (#7805) | the 13 argv sites and the six report emits moved to here-strings; `INPUT-NOT-EVALUATED` separated from malformed JSON and mode-coupled (P2); the ERE compile canary (a′); the > 1 MiB arm | the > 1 MiB arm RED on the macOS CI runner — needs the open draft PR (R8, AI-009) |
| **6** | **#6237** (#7806, re-designed) | the host-API axis evaluator `release/tools/host-api-axis-verdict.sh` with a charged, twice-read probe; the shared transport-aware classifier `release/tools/lib/host-refusal-class.sh`; § 4.3b resolved, residual (c) kept narrowed; the five consumers reconciled (release-hub edits in a sanctioned `pmo-skill-editor` Mode A session) and the package rebuilt; the ADR superseding ADR-156 in part; the `repo_host` named gap | the evaluator's recorded-response arms: full pool, `used = 0`, no declared state → non-PROCEED |
| **7** | **#6871** (#7807) | close-out PR reads moved to REST ("`merged` flag first; SHA only when merged; a value only from an answered response"), sourcing #6237's classifier; unresolvable separated from not-merged; `read_state` fails closed under `--apply` (CR-B6); the group-4e text pin and the fixture; the stage-13 convention paragraph citing § 4.3b | self-test stub (GraphQL `RATE_LIMIT`, REST answers) → pre-fix `transition_release_log FAIL … false-VERIFIED` |

**Cross-card anchors.** Every card after order 1 edits files an earlier card touched, so **every spec anchor is located by quoted anchor text, never by line number.** Cards that share a file: `core/deploy/deploy.sh` (#4318, #5287, #4917, #7199), `core/standards/gate-efficacy-standard.md` (#4318, #5287, #4917), `core/deploy/tests/test_gate_efficacy_declarations.py` (#5287, #4917, #7199), `release/references/how-to/hub-spoke-bridge.md` (#4318's one sentence, then #6237's Checkpoint B regions), `core/hooks/block-fragile-refs.sh` (#7199, then #6865), `.github/workflows/install-tests.yml` (#5287, #4917).

**A2 container determination, recorded rather than assumed.** Every card is multi-file or structure-changing, so the threshold predicate selects the **GitHub sub-issue container**. The release runs each card's decomposition through the per-card Stage-6 sub-task the hub already scaffolded (#7808–#7814), with the change units enumerated in § File Change Matrix and rendered as checklist rows in the PR body; creating further sub-issues would duplicate a container the hub owns.

---

## Stage Applicability Matrix

| Stage | #4318 | #5287 | #4917 | #7199 | #6865 | #6237 | #6871 | Basis |
|---|---|---|---|---|---|---|---|---|
| **5 — Solutioning** | #7801 | #7802 | #7803 | #7804 | #7805 | #7806 | #7807 | ACTIVATE for all seven, plus the Collective Review; #6237 re-designed after CR-B0 |
| **6 — Engineering** | #7808 | #7809 | #7810 | #7811 | #7812 | #7813 (sanctioned session for the release-hub paths) | #7814 | P0 serial, orders 1–7 |
| **7 — Dev Testing** | #7815 | #7816 | #7817 | #7818 | #7819 | #7820 | #7821 | every card changes executable behaviour or an agent-executed gate; no skip admissible; runtime-suite rows fire for `deploy.sh`, the hook and the release tools |
| **8 — QA** | #7822 | #7823 | #7824 | #7825 | #7826 | #7827 | #7828 | per-criterion verdicts over the 27 criteria plus the OBL rows |
| **9 — Plan Review** | release #7829 | | | | | | | **Deep** (`cross-cutting`); A6.5/A6.6 re-measure the in-flight siblings; G-PR9 re-baselines against § Baseline pin |
| **10 — Dry Run** | release #7830 | | | | | | | PLATFORM-SATISFIED — the PR diff is the dry run; no schema or Layer-2 data migration |
| **11 — Snapshot** | release #7831 | | | | | | | PLATFORM-SATISFIED — git history is the snapshot |
| **12 — Execute** | release #7832 | | | | | | | merge + atomic claim; hash-verified hook-tier refresh; `deploy.sh --deploy release-hub` (manifest) |
| **13 — Close** | release #7833 | | | | | | | 30-day outcome window |

---

## File Change Matrix

One path per line, `<path>  <verb>`, fence-delimited for deterministic extraction; each path is listed once, under the first card that edits it. Conditional rows whose condition resolved at or before this commit are **promoted in this commit** (a comment line above each names its source token); rows whose condition resolved **false** stay CONDITIONAL and are recorded NOT DELIVERED in § Deviation Log.

```
# ── #4318 — Check 48 exit contract · network-leg NOT-EVALUATED · version-less CHANGELOG ──
core/deploy/deploy.sh                                                                edit
.github/workflows/close-completeness.yml                                             edit
core/standards/gate-efficacy-standard.md                                             edit
# added at Stage 5 (the sentinel-file comments; Tier 1, applied at this commit)
.github/close-completeness.enforce                                                   edit
# added at Stage 5 (F-2: the schema row moves with the drain; Tier 1, applied at this commit)
release/references/standards/release-corpus-schema.md                                edit
# promoted: the one-sentence Phase-0.7 row fired at CR-BUNDLE-1; #6237 edits other regions at order 6
release/references/how-to/hub-spoke-bridge.md                                        edit

# ── #5287 — declared population + examined count ──
core/deploy/tests/test_gate_efficacy_declarations.py                                 edit
# added at Stage 5 (F-3 (i): comment-only); #4917 then edits one run block (CR-B1)
.github/workflows/install-tests.yml                                                  edit
# de-literalized group count (#7879 PR-3 via hub action item AI-008; comment-only)
.github/workflows/decision-emission.yml                                              edit

# ── #4917 — never-FAIL census (+ #7466 criterion 1 partition) ──
# the census ADR (CR-BUNDLE-2); numbered at authoring against the mainline anchor
core/ADRs/ADR-*-census-asserts-exit-consumer-and-executor-populations.md             add

# ── #7199 — never-existing roots ──
release/README.md                                                                    edit
# added at Stage 5 (FR-3; D-R (A))
operations/README.md                                                                 edit
core/hooks/block-fragile-refs.sh                                                     edit
.github/workflows/reference-durability.yml                                           edit
core/standards/universal-vs-release-pipeline-split-rule.md                           edit
# promoted: D-R3 (a) fired (FR-3)
core/deploy/tools/check-doc-links.py                                                 edit
# the scope predicate moves into the shared pattern file (CR-BUNDLE-4)
core/hooks/lib/fragile-ref-patterns.sh                                               edit

# ── #6865 — hook argv ceiling ──
core/hooks/tests/block-fragile-refs.test.sh                                          edit
# added at Stage 5 (R7: comments only)
core/hooks/run-fragile-ref-fixtures.sh                                               edit
core/hooks/testdata/marker-resolution-fixtures.txt                                   edit
# promoted: the D-Swallow arm fired under (a′) at CR-B2 (basis inferred; the order-5 spoke confirms)
core/hooks/tests/ghsa-g9g6-primitive-fail-closed.test.sh                             edit

# ── #6237 — host-API axis ──
# promoted: the mechanized-evaluator condition fired (D-3)
release/tools/host-api-axis-verdict.sh                                               add
# added by the scoped re-design (B2; ML-6871-D-2)
release/tools/lib/host-refusal-class.sh                                              add
core/deploy/allowlists/selftest-coverage-manifest.txt                                edit
core/config/allowlists/script-execution-allowlist.txt                                edit
# added by the scoped re-design (FM-1's trigger path)
.github/workflows/release-tooling-smoke.yml                                          edit
release/references/standards/quota-budget-protocol.md                                edit
release/skills/release-hub/references/spoke-launch.md                                edit
# promoted: the consumer-in-skill-body condition fired
release/skills/release-hub/SKILL.md                                                  edit
packages/release-hub.skill                                                           edit
packages/release-hub.skill.sha256                                                    edit
# the ADR superseding ADR-156 in part (D-5); numbered at authoring against the mainline anchor
release/ADRs/ADR-*-checkpoint-b-host-api-axis-reads-its-own-probe-in-band.md         add
release/ADRs/ADR-156-checkpoint-b-second-axis-is-measured-not-declared.md            edit
release/ADRs/README.md                                                               edit
# added by the scoped re-design (ML-D-7 (i): the named-gap note)
core/standards/repo-host-adapter-versioning.md                                       edit

# ── #6871 — close-out transport ──
release/tools/automated-closeout.sh                                                  edit
# promoted: the stage-13 convention home fired (D-1)
release/references/pipeline/stage-13-close.md                                        edit

# ── Release corpus ──
release/releases/plans/controls-fail-loud_RELEASE_PLAN.md                            add

# ── CONDITIONAL — resolved FALSE at or before this commit; NOT DELIVERED, see § Deviation Log ──
CONDITIONAL:S5-EXITCODE-TEST-FILE          core/deploy/tests/test_close_completeness_exit_codes.sh  add
CONDITIONAL:S5-SCOPE-GAP-SELFREPAIR-ROW    core/schemas/gate-criteria-spec.md                       edit
CONDITIONAL:AC1-COLLAPSE-FOUND             release/tools/capture-release-bodies.sh                  edit
CONDITIONAL:AC1-COLLAPSE-FOUND             release/tools/preflight-release-body-reemit.py           edit
CONDITIONAL:AC1-COLLAPSE-FOUND             release/tools/reemit-release-bodies.sh                   edit
CONDITIONAL:SIZE-LIMIT-RETAINED            core/rules/bypass-mode-readiness.md                      edit
CONDITIONAL:AC4-CONSUMER-IN-A6-NOTE        release/references/pipeline/stage-04-planning.md         edit
CONDITIONAL:S5-CONVENTION-HOME-GHAPI       core/standards/gh-api-convention.md                      edit
```

#### Read-only inputs

```
release/tools/check-release-body-drift.sh                    READ
core/deploy/tools/lint_release_corpus.py                     READ
release/tools/claim-version.sh                               READ
release/tools/verify-release-plan.sh                         READ
release/tools/check-ac-binding.py                            READ
core/hooks/lib/dep-resolve.sh                                READ
core/deploy/tests/run-install-regression.sh                  READ
core/config/operator-toml-schema.json                        READ
```

#### Release-wide explicit non-scope

```
core/deploy/tools/reconcile-gate-posture.py                  NOT EDITED
core/schemas/entity-field-schemas.md                         NOT EDITED
release/tools/compute-cycle-time.sh                          NOT EDITED
```

- **New-executable companion obligation.** Two `add` rows are executable. `release/tools/host-api-axis-verdict.sh` carries its companion `script-execution-allowlist.txt` row (the four house invocation forms) and a `selftest-coverage-manifest.txt` row, and it is CI-executed by `release-tooling-smoke.yml`'s self-test discovery job. `release/tools/lib/host-refusal-class.sh` is a sourced library with no CLI; per the zero-row precedent of the four existing `release/tools/lib/` libraries it takes no allowlist row, and every exercise of it runs inside an allowlisted consumer's self-test — a design decision locked at #6237's short scope lock, recorded here so the omission is visible rather than silent.
- **ADR numbering.** The two ADR rows are declared in glob form because each number binds at authoring (`release/tools/renumber-adr.py --detect` first). The mainline anchor at this commit is ADR-206; `verifier-grades-what-plans-declare`'s open PR carries ADR-207 to ADR-210 (R19). The census ADR's module is recorded as `core/ADRs/` because the census lives in a core standard; the order-3 spoke re-points the row if the record lands under `release/ADRs/`, where the index must then be regenerated.
- **Skill-package rebuild.** Only #6237 touches a rostered skill tree (release-hub), and it rebuilds `packages/release-hub.skill` plus its content sidecar in the same PR. Every other card's paths resolve to no skill (checked per card with `build-skill-packages.sh --skills-for-paths`, paths on stdin).

### Agent-Editability Read

Transcribed from the Stage-4 derivation (controls read at `8e0ee084`) and extended to the rows added since.

- **Tier-0 floor** (`core/hooks/block-autonomy-ceiling.sh`, the two `always_block "BLOCK-AUTONOMY-001"` blocks): the projected tracked union is the basenames `CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md` at any depth. **No row matches**; `release/README.md` and `operations/README.md` have the basename `README.md`, and `RELEASE_PROTOCOL.md` appears only as text inside them.
- **Sanctioned-session gate** (`core/hooks/block-skill-direct-edit.sh`, `SKILL_SCOPE_RE` over `{operations,release,core,pmo-platform}/skills/<name>/(SKILL.md|references?/*.md)`): matches **only** `release/skills/release-hub/references/spoke-launch.md` and `release/skills/release-hub/SKILL.md` (release-hub is armed; the exemption list carries only the source-only canary).

| Card | Write-set | Tier-0 ∩ | Skill-gate ∩ | Path class | Execution path |
|---|---|---|---|---|---|
| #4318 | `deploy.sh`, `close-completeness.yml`, the gate-efficacy standard, `.github/close-completeness.enforce`, `release-corpus-schema.md`, one `hub-spoke-bridge.md` sentence, this plan | ∅ | ∅ — conjunct 1 false | unconstrained | ordinary Engineering spoke |
| #5287 | the harness, `install-tests.yml` (comments), `decision-emission.yml` (comments), plus the shared `deploy.sh` and standard | ∅ | ∅ | unconstrained | ordinary Engineering spoke |
| #4917 | the standard, the harness, `install-tests.yml`, `deploy.sh`, the census ADR | ∅ | ∅ | unconstrained | ordinary Engineering spoke |
| #7199 | both READMEs, the hook, its shared pattern file, the workflow, the split rule, `check-doc-links.py`, plus `deploy.sh` and the harness | ∅ — the floor names the deployed `.claude/hooks/*`, not `core/hooks/` | ∅ | unconstrained | ordinary Engineering spoke |
| #6865 | the hook, its test, the fixture runner, the marker fixture, the fail-closed primitive suite | ∅ | ∅ | unconstrained | ordinary Engineering spoke |
| #6237 | `spoke-launch.md` and `SKILL.md` under `release/skills/release-hub/` | ∅ | **yes** (scope ✓ · armed ✓ · not exempted ✓) | **sanctioned-session-required** | `pmo-skill-editor` Mode A (version field per the material-edit rule) |
| #6237 | `packages/release-hub.skill` + `.sha256` | — | — | generated; takes its source's class | built inside the same sanctioned session |
| #6237 | the evaluator, the classifier library, the manifest, the allowlist, `release-tooling-smoke.yml`, the protocol, the bridge regions, the ADRs, `repo-host-adapter-versioning.md` | ∅ | ∅ | unconstrained | ordinary Engineering spoke for these paths |
| #6871 | `automated-closeout.sh`, `stage-13-close.md` | ∅ | ∅ | unconstrained | ordinary Engineering spoke |

**Result: 0 Tier-0-floored paths; one card (#6237) sanctioned-session-required on its two release-hub paths only.** An `unconstrained` row means no control refuses the write — never that the change is ungoverned.

---

## Integration Points

| # | Seam | Why it binds |
|---|---|---|
| IP-1 | `cmd_check_close_completeness`'s exit space ↔ `close-completeness.yml`'s gate-decision `case` | one commit; no predicate re-encoded in YAML; the workflow never re-reads the sentinel |
| IP-2 | gate-efficacy register rows ↔ `test_gate_efficacy_declarations.py` ↔ Check 62's `runner-def:` pointers | a restated row keeps its anchors resolvable; the harness's `POSTURE_RESIDUALS` key on `close-completeness.yml`'s header tokens, which stay unchanged |
| IP-3 | `block-fragile-refs.sh` durable-corpus arms ↔ `reference-durability.yml` `is_durable()`, now through the shared pattern file (CR-BUNDLE-4); the hook's marker strip ↔ the workflow's `MARKER_SCAN` awk | "neither surface changes alone" (CIAC-4) |
| IP-4 | § 4.3b ↔ Checkpoint B in `hub-spoke-bridge.md` ↔ `spoke-launch.md` ↔ release-hub `SKILL.md` ↔ ADR-156 (the Stage-4 A6 note is invariant) | the full consumer set of the host-API axis verdict |
| IP-5 | release-hub `references/` and `SKILL.md` → `packages/release-hub.skill` + sidecar → Stage-12 `deploy.sh --deploy release-hub` | Check 7 always-enforce; the pre-merge freshness sentinel reads `enforce` |
| IP-6 | `_chore_pr_terminal_state` ↔ its self-test text pin (group 4e arm (i)) ↔ the fixture string | the positional composite is load-bearing |
| IP-7 | hook source → deployed hook copy (the hook and its `lib/` pattern file) | a hook edit reaches running sessions only after a hash-verified refresh |
| IP-8 | Check 25 / Check 31 declared roots ↔ #5287's population declaration ↔ #7199's removal and repoint (E3) | the RED → GREEN sequence across orders 2 and 4 |
| IP-9 | #6871's transport reads ↔ #6237's classifier library (B2) | one vocabulary for a host refusal (CIAC-5); #4714 owns the drift engine's rate-limit exit and is external |
| IP-10 | the probe's `close-completeness-exit: <code>` line ↔ `close-completeness.yml` | the gate honours an advisory 2 or 3 only when the verdict mapping issued it (#7878 F-2); arm (15) asserts the consumer side |
| IP-11 | Check 48's cause tokens ↔ the § 4.3b host-refusal classes (CR-BUNDLE-4) ↔ #6237's classifier | the flip-time cause-conditional escalation consumes the shared classifier rather than a Check-48-local taxonomy |

### Contention

- **Within the release:** `core/deploy/deploy.sh` MULTI-WAY (#4318 → #5287 → #4917 → #7199), in distinct regions: #4318 the Check 48 engine, the probe, the lifecycle Check 48 arm, the usage line, the dispatch comment and its self-test arms; #5287 a hoisted pair after `flag_not_evaluated`, Checks 25 and 31 and group DP; #4917 Check 47's verdict tail and group BD; #7199 Check 25's root array (E3, by design). The gate-efficacy standard MULTI-WAY (row `:271`; Requirements (b)/(c); the census section). The harness MULTI-WAY (#5287 → #4917 → #7199). `hub-spoke-bridge.md` BINARY (#4318's one sentence at order 1, anchored on "Scaffold-independent enforcement of this Step 4 table"; #6237's Checkpoint B regions at order 6). `block-fragile-refs.sh` BINARY (#7199 → #6865). `install-tests.yml` BINARY (#5287 comments → #4917's one `run:` block). Serial P0 makes each a rebase-free sequence, never a conflict.
- **Cross-PR at Commit 0:** 3 open PRs (`gh pr list --state open --limit 500` → 3). `closeout-verification-rows-consistent` (#7895) intersects on `hub-spoke-bridge.md`, `stage-13-close.md` and `automated-closeout.sh`; `verifier-grades-what-plans-declare` (#7839) on the gate-efficacy standard and `install-tests.yml`, and it claims ADR-207 to ADR-210; `telemetry-is-computable` (#7901) carries only its plan file today, and its plan edits `deploy.sh`'s Check 48 engine in regions disjoint from #4318's (the telemetry cutoff default and its self-test group). A pinned measurement, not a verdict — Stage 9 A6.6 renders it.
- **Dormant siblings:** `obligations-get-runners` (#6872's Check 48 instance co-discharges with #4318's drain), `completion-asserts-completeness`, `release-instruments-measure-what-happened`, `restated-facts-derive-from-their-source` and `authoring-conventions-enforced-or-retired` — each in regions disjoint from this release's, per the Stage-4 Parallelization Map.

### In-Flight Release Roster

**Measured at:** `35dbf418` · 2026-09-26T01:05Z (Commit 0) · **Population:** n=3 siblings (open PRs with a `release/*` head, drafts included; `git ls-remote --heads origin 'release/*'` → the same three).

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `telemetry-is-computable` | `#7901` | `ab3d6455` | `minor` | `v4.70` | `v4.70` | none today (its PR carries only its plan); planned: `core/deploy/deploy.sh` (Check 48 engine, disjoint regions) |
| `closeout-verification-rows-consistent` | `#7895` | `274087b9` | `minor` | `v4.70` | `v4.70` | `release/references/how-to/hub-spoke-bridge.md` · `release/references/pipeline/stage-13-close.md` · `release/tools/automated-closeout.sh` |
| `verifier-grades-what-plans-declare` | `#7839` | `38f9bcd2` | `minor` | `v4.69` (stale — the slot is taken) | `v4.70` | `core/standards/gate-efficacy-standard.md` · `.github/workflows/install-tests.yml` |

No verdict is rendered here. Stage 9 A6.6 re-measures fresh.

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | #4318's exit change lands without its consumer rewire; `close-completeness.yml` is path-filtered on `deploy.sh`, so a `deploy.sh`-only commit turns this release's own PR red | HIGH if split | HIGH | both halves, and the register row, in **one** commit (v4.64 R2 precedent) | #4318 spoke |
| R2 | The standing INCOMPLETE becomes a permanent visible advisory on every in-roster PR: 15 real findings (13 §5.1 drift, 2 Velocity) once the 7 false ones are drained | CERTAIN once shipped | MED (warning fatigue) | D-Drain-48 removes the 7 false findings; the 15 are genuine unreported debt, made visible and not drained here. Named follow-on: a §5.6 re-emit sweep for the 13 bodies; the sentinel's new drain precondition blocks a premature flip | Operator |
| R3 | Line-range overlap with `closeout-verification-rows-consistent` on `_chore_pr_terminal_state` / `phase_create_chore_pr` | MED | MED | whichever merges second re-baselines at Stage 6/9; semantically compatible | Hub |
| R4 | Hot-file churn on `deploy.sh` and the gate-efficacy standard | HIGH | MED | baseline pin; Stage-9 A6.5/A6.6 re-measure; P0; small regional hunks located by anchor text | Hub |
| R5 | #6865's RED arm is vacuous in CI if sized below the macOS limit | HIGH if not planned | HIGH | a > 1 MiB arm; RED observed on the draft PR's CI before the fix | #6865 spoke |
| R6 | #6237 has no executable (resolved) | — | — | the mechanized evaluator was chosen and re-designed | — |
| R7 | #6237 changes a gate consulted before every spawn; false DEFERs slow every release | MED | MED | measure the false-DEFER rate at Stage 7; the § 4.5 override remains | #6237 Stage 7 |
| R8 | Reflexive hazard: this release's hub launches spokes through the Checkpoint B being changed | LOW | LOW | the change reaches the running hub only at the Stage-12 release-hub deploy | Hub |
| R9 | Version-slot contention on `v4.70` with three siblings | HIGH | LOW | the Stage-12 atomic claim recomputes upward; the Commit-0 re-verify HALTs if the slot is already claimed | Stage 12 |
| R10 | #7199 was never Stage-2 approved (resolved: D-7199 Approve) | — | — | — | — |
| R11 | #7466 duplicate (resolved: D-Dup-7466) | — | — | #7466 keeps criterion 5 only | Operator |
| R12 | A parallel census structure in the standard | MED | MED | order #4318 → #5287 → #4917; CIAC-2 | Stage 6 |
| R13 | The hook edit does not reach running sessions; a stale-baseline deploy can no-op at exit 0 | MED | MED | manifest row 2: refresh and **verify by hash** | Stage 12 |
| R14 | ADR number collisions (see R19) | — | — | — | — |
| R15 | Named class residuals outside the point fixes (the pinned-external-`printf` idiom in other hooks; other GraphQL-bound close-out calls; #7466 criterion 5's fused workflow sites) | CERTAIN | MED | recorded as named residuals, never silent; class cards via intake | Operator |
| R16 | Size over band: 47 effective against 25 | CERTAIN | MED | the extended G3-15 Override (CR-B4); limb B last on the branch | Operator |
| R17 | Rollback coupling: #4318's exit change, consumer and register row must revert together | LOW | LOW | one commit, one `git revert` | Stage 12 |
| R18 | The release-hub package is rebuilt by this release (#6237), by `telemetry-is-computable` and conditionally by `closeout-verification-rows-consistent`; a binary package cannot be text-merged | MED | MED | whichever release merges later rebuilds after rebasing; Check 7 detects a stale package by content | Hub |
| R19 | ADR number contention: `verifier-grades-what-plans-declare` claims ADR-207 to ADR-210, and this release adds two records | MED | LOW | numbers bind at authoring against the mainline anchor (`renumber-adr.py --detect`); the ADR-number integrity job blocks a duplicate or gap at merge | #4917 and #6237 spokes |
| R20 | Cross-release statement drift: `telemetry-is-computable` arms Check 48's sub-check (l) by a committed default in its own release, and it asked #4318's register-row rewrite to record (l) as armed; (l) is inert on `main` at this commit, so the row states its present posture | MED | LOW | whichever of the two releases merges second reconciles the (l) clause of row `:271` at its sync or Stage-9 re-baseline; surfaced to the hub as a decision | Hub (Stage 9 A6.5) |
| R21 | A crashing probe reading as a measured advisory (a syntax error or a failed sentinel read also exits 2) | MED | HIGH | the F-2 handshake: the workflow honours 2 and 3 only on the probe's `close-completeness-exit:` line; the family instances are #7889's | #4318 spoke |
| R22 | The weekly allowance cap interrupts a spoke mid-card | MED | MED | resumable phases (pacing decision); write-early commits; a handoff comment before each long verification run | Hub |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential (dependency-ordered), orders 1–7; limb A then limb B |
| **Commit strategy** | Per card, an arm observed RED (or a declared armed-red record) and then the fix commit(s). #4318's exit change, consumer rewire and register row go in **one** commit; #7199's hook and workflow arm removal in one commit. Messages carry `release(controls-fail-loud):` and reference the source card; signed; never `--no-verify` |
| **Review approach** | A single PR for the whole release (`release/controls-fail-loud` → `main`), opened in **draft** immediately after this commit so the pull-request checks — the hook tests among them — run on every later slice (AI-009). The PR body is parser-clean: close-family verbs adjacent to an issue number appear only in the Issue References block |
| **Deployment mechanism** | Git merge, the Stage-12 atomic claim, `deploy.sh --deploy release-hub` (package included), and a hash-verified hook-tier refresh |
| **Stacked-base cleanup posture** | Option A (default); no stacked bases |

---

## Verification Plan

**Every method cell carries its command literally** — reproducible from the cell alone, with pipes escaped for the table (`\|`); read them unescaped. A `bash …` cell is dispatchable but not executed by `release/tools/verify-release-plan.sh`, whose runnable-verb set is closed to read-only queries by design; such a row reads `unclassified-method` there, and its guarantee lives in the suite's own CI-invoked run. **OBL rows** carry the Stage-4 amended and added criteria (the AC-binding oracle reads only each issue's checkbox list, so an amendment-block criterion is invisible to it; OBL is its sanctioned channel for obligations outside that list — reported DISPLACED and excluded from the criterion set). Each OBL row names the criterion it carries.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #4318 | AC-1 | Read the header contract table above `cmd_check_close_completeness`, the function body's arms, the usage line and the dispatch comment in `core/deploy/deploy.sh`; `bash core/deploy/deploy.sh --self-test` arms (8), (12), (13) | the header comment and the function body state one exit contract, and INCOMPLETE in warn-mode returns 2 on every surface; `declare -f cmd_check_close_completeness` has 0 numeric-literal exit statements (the Stage-4 pin: 5) |
| #4318 | AC-2 | Named read: § Decision Record → #4318 design decisions, row D-1 (the candidate contracts, the family precedent, reversibility) and CR-A1 | the resolution is recorded as a deliberate choice between the candidate contracts (verdict-driven red-exit, the sentinel-gated status quo, the family's four-member contract), not a silent edit |
| #4318 | AC-3 | `grep 'close-completeness probe' core/standards/gate-efficacy-standard.md \| grep -c 'warn: summary + exit 0'`, then read the gate-coverage register row | 0, and the register row states the shipped exit map, the NOT-EVALUATED state and the armed network cutover · control: the same pipeline at the Stage-4 pin `8e0ee084` → 1 |
| #4318 | AC-4 | Named read of `cmd_check_decision_emission`'s contract table, `_de_verdict_exit_code`, its seven body exits, its usage line and its dispatch comment in `core/deploy/deploy.sh` | `cmd_check_decision_emission` is classified correctly-declared (every surface and its consumer agree: CLEAN 0 · INCOMPLETE 2/1 · SKIP 3 · NOSET 4/1 · other 1), and the finding is recorded (Stage-5 F-6) |
| #4318 | OBL-1 | amended AC-5 (`0` has one producer; the consumer branches on the integer) — `grep -c 'if \[ "\$RC" -eq 0 \]' .github/workflows/close-completeness.yml`; `bash core/deploy/deploy.sh --self-test` arms (12) and (15) | 0 — the workflow branches on the integer, never re-reads the sentinel, and honours 2 and 3 only on the probe's handshake line · control: the same grep at the Stage-4 pin → 1 |
| #4318 | OBL-2 | amended AC-6 (population self-test with a sensitivity arm) — `bash core/deploy/deploy.sh --self-test` arms (8)–(11); then, on a scratch copy of `deploy.sh`, replace `_cc_st_pv7_violations`'s body with a constant zero and re-run | the population arms pass; under the mutation arm (11) alone fails |
| #4318 | OBL-3 | amended AC-7 (version-less rows are not asked for a CHANGELOG section) — `bash core/deploy/deploy.sh --self-test` arm RC-5b; the live probe `bash core/deploy/deploy.sh --check-close-completeness` on a checkout whose remote is the GitHub repository | 0 version-less CHANGELOG findings (the Stage-4 pin: 7); RC-5b's versioned control still reports |
| #4318 | OBL-4 | amended AC-8 (an instrument failure is not evaluated, never "absent") — `bash core/deploy/deploy.sh --self-test` arms (14a)–(14k); the live probe on a checkout whose remote does not resolve to a GitHub repository | NOT-EVALUATED for a failed lookup and 0 "no published GitHub Release" findings (the Stage-4 pin: 75); a genuinely absent Release is still a finding (14e) |
| #4318 | OBL-5 | the Stage-4 re-anchoring of AC-1 (every declaration agrees; SKIP joins the contract) — read each declaration surface: the header table, the arms, the usage line, the dispatch comment, the lifecycle-block sentinel sentence, `.github/close-completeness.enforce`'s comments and the `hub-spoke-bridge.md` sentence | each names the same map; SKIP never exits 0 |
| #4318 | OBL-6 | the Stage-4 amendment to AC-2 (a three-way choice) — the AC-2 named read | the choice is recorded as three-way, with the family precedent |
| #4318 | OBL-7 | the Stage-4 amendment to AC-3 (restated in the same commit) — `git show --stat` of #4318's contract commit | `deploy.sh`, `close-completeness.yml` and the gate-efficacy standard change in one commit |
| #5287 | AC-1 | Read Requirement (b)'s declaration schema and the gate-coverage register in `core/standards/gate-efficacy-standard.md`; `python3 -c "import re;print(sum(1 for l in open('core/deploy/deploy.sh') if re.match(r'^\s*#\s{2,}population:', l)))"` | the declaration seam requires every check to declare its population, machine-greppably, beside its implementation; the declaration count is 3 (Check 25 twice, Check 31 once; the pin: 0) |
| #5287 | AC-2 | `grep -c 'MUST report, on every run, the population it actually examined' core/standards/gate-efficacy-standard.md` | 1 — the standard requires a check to report its actually-scanned count |
| #5287 | AC-3 | `bash core/deploy/deploy.sh --self-test`, group DP arm DP-3 (a synthetic check over an empty glob) and its control DP-1 | DP-3 PASS: an empty scanned set emits a warning (NOT-EVAL), never a silent pass; the control DP-1 emits none |
| #5287 | AC-4 | `grep -c 'Escape-hatch granularity' core/standards/gate-efficacy-standard.md`, then read that section | 1; the escape-hatch rule states the narrowest resolving unit and requires a justification for file scope |
| #5287 | AC-5 | `bash core/deploy/deploy.sh --check --warn`, reading the `DENOM: reference-durability` line and Check 62; the harness's worked-reference arm | the worked reference (Check 25 and Check 31, amended from the card's named candidates) carries a conformant coverage declaration; Check 62 CLEAN; `status=fetched` |
| #5287 | OBL-1 | the Stage-4 confirmation of AC-1's seam — `/usr/bin/python3 core/deploy/tests/test_gate_efficacy_declarations.py` | exit 0; the seam is Requirement (b)'s declaration schema plus a fourth Requirement (c) audit mode, asserted by the harness |
| #5287 | OBL-2 | amended AC-3 (the real-instance arm) — on the commit before #7199's removal, `/usr/bin/python3 core/deploy/tests/test_gate_efficacy_declarations.py` and `bash core/deploy/deploy.sh --check --warn` | 4 `WARN (ledgered residual)` lines and 1 `NOT-EVAL: universal-vs-localized-context` line naming Check 25's four zero-yield roots (the amendment's "Check 23" is Check 25) |
| #5287 | OBL-3 | amended AC-5 (the worked reference re-ranked) — read Check 25's and Check 31's `#   population:` declarations | both conformant; a configured root resolving to zero files is reported not evaluated, never skipped |
| #5287 | OBL-4 | the amendment's mechanism ownership (D-7199) — CIAC-3 | the zero-resolving-root reporting mechanism lands in #5287's commits; #7199 only removes and repoints roots |
| #4917 | AC-1 | `/usr/bin/python3 core/deploy/tests/test_gate_efficacy_declarations.py; echo $?`, then read the census's two exit-consumer records | exit 0; the drift record lists 8 decision sites in 6 callers and the workflow record lists the binary-zero consumers, each audited and classified with a reason (figures per #4917's design at the pin; its order-3 spoke re-derives them) · control: a scratch copy with one row deleted → exit 1 |
| #4917 | AC-2 | `python3` read of `REGRESSION_MEMBERS` in `core/deploy/tests/run-install-regression.sh` for the five executor candidate names; `install-tests.yml` runs the runner on a non-comment `run:` line | 5 of 5 enrolled — resolved as executor confirmed, discharged by merged release v4.60 · control: `test_compose.py` is not a member |
| #4917 | AC-3 | read the census section; count `## Exit-consumer and executor census` headings; read the suite's anti-vacuity census line | exactly one census section publishing its definition, its population (three records, seven labels in order) and both probe arms · control: 0 census headings at the pin |
| #4917 | AC-4 | the close-completeness chain: #4318's RED → GREEN (the standing verdict, exit 0 → 2); Check 47: the RED-B record plus `bash core/deploy/deploy.sh --self-test` group BD | a run that did not measure reports something other than success: BD-1..BD-5 PASS; on the not-evaluated run, NOT-EVAL and no OK line |
| #4917 | OBL-1 | amended AC-1 (the drift-engine callers plus #7466 criterion 1's partition, the definition fixed first) — as AC-1 | as AC-1, and the census `Definitions` subsection precedes the records |
| #4917 | OBL-2 | amended AC-3 (in #5287's population form, one structure, asserted by a test) — as AC-3 | as AC-3; CIAC-2 |
| #4917 | OBL-3 | amended AC-4 (discharged for Check 48 by #4318's RED → GREEN) — as AC-4 | as AC-4 |
| #4917 | OBL-4 | the amendment's named residual (Check 32's Surface-1 sub-check) — read the census's `Named residuals` subsection | Check 32's published-Release sub-check is named as **dormant**, citing its cutoff owner #6620 |
| #4917 | OBL-5 | the Stage-4 discharge of AC-2 (sub-shape (iii), delivered by v4.60) — as AC-2 | recorded as discharged with the citation |
| #7199 | AC-1 | the AC-1 probe **P-7199-AC1** below, run from the repository root — the `ls` control generalized: every module-rooted token in `release/README.md` resolves to a tracked directory or file | exit 0, 0 UNRESOLVED, 2 CONDITIONAL (the lines marked "(when added)") — `release/README.md` lists only directories that exist · control: at the Stage-4 pin exit 1 with 4 UNRESOLVED; a planted `release/zzz-planted/*` token fails it |
| #7199 | AC-2 | `git grep -nE 'release/(schemas\|standards\|specs)([^a-zA-Z0-9_-]\|$)' -- ':!release/releases/**'` | exactly 4 lines in 2 files, each shown to be a non-reference: ADR-007's two decision lines (preserve-with-reason — historical decision text) and the Check 18 and Check 31 comments in `core/deploy/deploy.sh` (explanatory) · control: `git grep -c 'release/references/standards'` ≥1 (246 at the pin) |
| #7199 | OBL-1 | amended AC-2 (the 16-line, 7-file population, executable surfaces included) — the AC-2 command at the pin, then after the fix | 16 lines in 7 files before; only the 4 classified lines after; the hook's arms and the workflow's `is_durable()` change in one commit (CIAC-4) |
| #7199 | OBL-2 | the amendment's mechanism split — CIAC-3 | this card's removal turns #5287's real-instance arm green; this card adds no reporting mechanism |
| #6865 | AC-1 | `bash core/hooks/tests/test-runner.sh` in the materialized layout (`setup-ci-layout.sh` first), with the > 1 MiB arm | the hook adjudicates a large valid Write without dying: pre-fix BLOCKED as malformed JSON (RED); post-fix the same verdict as the small arm |
| #6865 | AC-2 | `grep -cE '"\$PRINTF" .*"\$(INPUT\|MARKER_SRC\|CONTENT\|STRIPPED)"' core/hooks/block-fragile-refs.sh` | 0 — every site fixed or assessed · control: the same grep at the pin → 13 |
| #6865 | AC-3 | the fixture pair (small, > 1 MiB) through the hook | hook adjudication is payload-size-independent: identical verdicts; the large arm observed RED pre-fix |
| #6865 | AC-4 | run the hook under `set -euo pipefail` with the pinned-binary indirection intact (the builtin/here-string remedy) | no behaviour change on the small arm; exit status propagated |
| #6865 | OBL-1 | amended AC-1 (both platforms) — arms S3, S4, S4b and S6 on the macOS CI runner with a payload above ARG_MAX | verdict independent of payload size |
| #6865 | OBL-2 | amended AC-2 (13 input sites, the six report emits, the exec-failure branch separated) — #6865's V-1, V-2 and V-3 probes and arms S8/S8b | 0 / 0 / 0 (pin: 13 / 6 / 13); an input the hook could not read reports `INPUT-NOT-EVALUATED`, never malformed JSON |
| #6865 | OBL-3 | amended AC-3 (RED observed in CI) — the order-5 RED commit's CI run on the draft release PR | the > 1 MiB arm FAILs on the macOS runner before the fix and passes after |
| #6237 | AC-1 | `grep -c 'undischarged residual' release/references/standards/quota-budget-protocol.md` | 0 — presentation (b)'s row resolves to a modelled outcome rather than an undischarged-residual marker · control: the same grep at the pin → 1 |
| #6237 | AC-2 | run the evaluator `release/tools/host-api-axis-verdict.sh` on the recorded full-pool, `used = 0`, no-declared-state input | non-PROCEED verdict where the axis cannot distinguish the read from an unstarted window |
| #6237 | AC-3 | the same evaluator on a genuinely fresh window with the declared state present | PROCEED, 0 deferrals (the discrimination arm) |
| #6237 | AC-4 | read every consuming rule in IP-4 | each consumer reconciles to the new state; none is left binding the old verdict |
| #6237 | OBL-1 | amended AC-4 (five surfaces; sanctioned session; package rebuilt) — read the five surfaces, and `deploy.sh --check-package-freshness` | all five reconciled; the release-hub package rebuilt in the same PR (fresh by content) |
| #6237 | OBL-2 | the amendment's method for AC-2 and AC-3 — the evaluator's recorded-response self-test arms, predictions stated before the run | the RED arm observed, not asserted |
| #6871 | AC-1 | `bash release/tools/automated-closeout.sh --self-test` — the arm with a GraphQL `RATE_LIMIT` stub and REST answering (PRT p1, p4, p11, p18) | merge-SHA resolution in `transition_release_log` succeeds while the GraphQL pool is exhausted; the phase does not FAIL |
| #6871 | AC-2 | `bash release/tools/automated-closeout.sh --self-test` — the test-merge-SHA arms p2 and p8 (an unmerged PR whose REST record carries a non-null test-merge SHA with `merged: false`) and the unmerged-PR stubs p10, p13 | a genuinely unmerged PR still reports unresolved as not-merged, distinct from unresolvable; neither is ever reported as merged, and a SHA is recorded only for a PR answered as merged (F-1) |
| #6871 | AC-3 | `grep -nE '\$GH pr (view\|list) .*--json' release/tools/automated-closeout.sh`, excluding comment and fixture lines | 0, or each remaining site carries a recorded reason · control: the pin → 6 sites |
| #6871 | AC-4 | the self-test arm with a VERIFIED row over an unmerged PR (p8 and the re-pointed group 4f (b)) | a false-VERIFIED row is still detected: FAIL `false-VERIFIED` fires |
| #6871 | OBL-1 | amended AC-1 (re-anchored; the `:2003` read moves too) — the PRT arms of AC-1 | pass after the fix; RED before |
| #6871 | OBL-2 | reworded AC-2 (not-merged is a state, unresolvable is a transport failure) — as AC-2 | as AC-2 |
| #6871 | OBL-3 | amended AC-3 (the population is the GraphQL-bound PR reads: 6 sites) — as AC-3, plus arm p22 | as AC-3 |
| #6871 | OBL-4 | the documentation-impact amendment — `grep -c 'quota-budget-protocol.md' release/references/pipeline/stage-13-close.md` | ≥1: the convention paragraph cites § 4.3b's refusal-reason classifier rather than restating it |

**Probe P-7199-AC1** (from #7199's Stage-5 design V-1; FR-2), run from the repository root:

```
/usr/bin/python3 - release/README.md <<'PY'
import re,sys,subprocess,fnmatch,os
tr=[f for f in subprocess.run(["git","ls-files"],capture_output=True,text=True,check=True).stdout.split("\n") if f]
ds={f.rsplit("/",i)[0] for f in tr for i in range(1,f.count("/")+1)}
un,co,ok=[],[],0
for n,l in enumerate(open(sys.argv[1],encoding="utf-8"),1):
    for a,b in re.findall(r"`([^`]+)`|\]\(([^)#\s]+)",l):
        t=(a or b).strip().split(" ")[0].rstrip(".,;:")
        if t.startswith("../"): t=os.path.normpath(os.path.join("release",t))
        if not re.match(r"(release|core|operations)/",t): continue
        hit=any(fnmatch.fnmatchcase(f,t) for f in tr) if any(c in t for c in "*?[") else (t.rstrip("/") in ds or t in tr)
        if hit: ok+=1
        else: (co if "(when added)" in l else un).append(f":{n} {t}")
print(f"resolved={ok} unresolved={len(un)} conditional={len(co)}")
for x in un: print("  UNRESOLVED",x)
for x in co: print("  CONDITIONAL",x)
sys.exit(1 if un else 0)
PY
```

**AC baseline** — the per-issue checkbox-criterion counts as read at the Stage-4 pin; re-read at Commit 0 (2026-09-26T01Z) from the live issue bodies with no change:

`ac_baseline: { #4318: 4, #5287: 5, #4917: 4, #7199: 2, #6865: 4, #6237: 4, #6871: 4, read_at: 8e0ee08450a5 }`

### Release-Level Verification

- [ ] File integrity: `bash -n` over every changed shell file; each changed suite shows 0 FAIL with an arm count at least its pre-change count
- [ ] `bash core/deploy/deploy.sh --self-test` → PASS (every group); `/usr/bin/python3 core/deploy/tests/test_gate_efficacy_declarations.py` → exit 0
- [ ] The hook suite under the CI layout (`setup-ci-layout.sh`, then `test-runner.sh`) and the install regression suite (`run-install-regression.sh`), per the runtime-suite selection map
- [ ] `bash release/tools/automated-closeout.sh --self-test` and the evaluator's self-test
- [ ] `deploy.sh --check` Checks 7, 9, 13, 14, 62 and 69 green; `--check-required-subset` green
- [ ] Cross-reference validity: `check-doc-links.py --require-targets` over the changed durable files; `check-release-links.py` with the CI flags and `--plan-depth-lint` over this plan
- [ ] Repository-integrity gates on the PR (depersonalization, issue-reference validity, dead-file reference, SIGPIPE idiom, ADR-number integrity, ADR durability)
- [ ] CIAC-1..6 (below)

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria** — all graded on the merged PR at Stage 9 QC3.5 / Phase A3.6.
- [ ] **CIAC-1 (#4318 × #4917 on the Check-48 exit contract):** "0 is CLEAN's alone" for Check 48, end to end. No verdict other than CLEAN produces exit 0 under any sentinel; the workflow branches on the integer and honours an advisory code only on the probe's handshake line; #4917's census lists this chain as a conformant consumer. *Method:* `bash core/deploy/deploy.sh --self-test` passes the close-completeness exit-map arms (8)–(15); `grep -c 'if \[ "\$RC" -eq 0 \]' .github/workflows/close-completeness.yml` → **0** · control: `git show 8e0ee084:.github/workflows/close-completeness.yml | grep -c 'if \[ "\$RC" -eq 0 \]'` → **1**. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5287 × #4917 on `core/standards/gate-efficacy-standard.md` Requirement (c)):** the executor and exit-state census is authored in the population-declaration form #5287 introduces (declared population, examined count, both arms), in **one** census structure. *Method:* read Requirement (c) and the census section; the census cites the population fields by the names #5287 defines; the count of census-defining sections is 1 · control: the same read at the pin shows the three prior audit modes and 0 census sections. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#5287 × #7199 on the Check 25 / Check 31 declared roots):** every root a scan declares resolves to ≥1 file, and a declared root resolving to zero is **reported, not skipped**. *Method:* on the commit before #7199's removal, `bash core/deploy/deploy.sh --check --warn` reports Check 25's zero-yield roots as not evaluated (`NOT-EVAL: universal-vs-localized-context …`) — the RED arm — and `python3 core/deploy/tests/test_gate_efficacy_declarations.py` prints one `WARN (ledgered residual)` line per such root. After the merge, `grep -cE '^[[:space:]]+"?(release/(schemas|specs|standards)|\.claude/rules)"?[[:space:]]*(\\)?$' core/deploy/deploy.sh` → **0** · control: the same command at the pin and at #5287's commit → **4**, and `grep -cE '^[[:space:]]+"?release/references"?[[:space:]]*(\\)?$' core/deploy/deploy.sh` → **1** at all three points; the harness prints no ledgered Check 25 residual. *(Check 25's locals carry the vestigial `c23_` prefix; the Stage-4 text's "Check 23" is this check. Under D-9 (B) the `.claude/rules` element is repointed to `core/rules`, so the subject pattern still reaches 0.)* *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#7199 × #6865 on the `block-fragile-refs.sh` ↔ `reference-durability.yml` mirror):** after both edits, the hook's durable-corpus arms and the workflow's `is_durable()` arms name the same path set with zero never-existing roots, and the hook's re-plumbed marker strip produces output byte-identical to the workflow's `MARKER_SCAN` awk for a fixture file. *Method:* extract both arm lists (or, after CR-BUNDLE-4, the shared pattern file's predicate as each surface reads it) and diff them → no difference; `grep -cE 'release/(schemas|specs|standards)/' core/hooks/block-fragile-refs.sh .github/workflows/reference-durability.yml` → 0 and 0 · control: the pin → 3 and 1; then run both strip paths over one fixture and `cmp` them → equal. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#6237 × #6871 on host refusal classification):** one vocabulary — a real call refused on quota grounds is exhaustion: never a probe failure (never fail-open) and never a state verdict (never "not merged"). *Method:* #6871's `--self-test` arms: a **REST** quota-refusal stub reports unresolvable (refused on quota grounds) and never `FAIL … false-VERIFIED`; a GraphQL `RATE_LIMIT` stub with REST answering reports merged; control: a MERGED stub reports PASS. The convention paragraph #6871 adds cites § 4.3b's refusal-reason classifier rather than restating it: `grep -c 'quota-budget-protocol.md' release/references/pipeline/stage-13-close.md` → ≥1 (the pin: 0). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-6 (all seven, the release's own standard):** every remediation commit on the branch is preceded by an arm **observed RED against the pre-fix code**, or, where RED-first is impossible, by an armed-red-then-revert record whose predictions were stated before the run. *Method:* Stage 7 reads the branch log per card and this plan's § Verification Evidence; one RED observation (or declared armed-red record) per card, 7 of 7. *Graded at Stage 9 QC3.5 on the merged PR.*

**Population enumerated** for cross-issue cohesion: shared exit contract, shared standard section, shared scan roots, shared hook ↔ workflow mirror, shared refusal vocabulary, and the release's own RED-first standard. Index freshness and package freshness are per-card checks, kept under Release-Level Verification.

---

## Quota Budget

**Verdict:** **PASS**, conditional on the UNSTATED conservative default (`quota-budget-protocol.md` Checkpoint A). Parallel-eligible spokes: Stage 5: **7** · Stage 7: **7** · Stage 8: **7**; Stage 6 is serial by D-Concurrency. Per-spoke cost estimate: the size-bucket ordinal band (L: moderate–high — #5287, #4917, #6237 after CR-B4; M: low–moderate — #4318, #6871; S: lowest — #7199, #6865). The usage-window envelope was UNSTATED at planning, so `W_max` is **2** (rolling lanes of 2). Observed since: two Stage-5 spokes stopped at the session limit, which lowered the basis to SERIALIZE (the width-1 override above); the weekly allowance, which Checkpoint B does not model, read 77% after the scope lock, and the operator chose resumable pacing over a pause. Checkpoint B re-validates at every launch on both axes, DEFER-dominant.

---

## Release Class declaration

**`cross-cutting`** — trigger (c) fires: four in-bundle compositional edges (E1 #4318 → #4917, E2 #5287 → #4917, E3 #5287 → #7199, E4 #6237 → #6871). `novel` (b) also fires on the D-class decisions; multi-trigger resolution selects `cross-cutting`.

- **Differentiation posture:** Engagement **Tight** · Stage 9 review **Deep** · Stage 5 activation **ALL** · outcome window **30-day**.
- **Size bound:** `effective_pts: raw 36 × 1.3 = 47 — over band vs 15-25`, held by the extended G3-15 Override (CR-B4).

---

## Release Outcome Statement

### Release Outcome Statement

**AFTER** — A control that cannot evaluate its subject says so: a check that did not measure, measured less than it declares, or lost its own instrument reports that state as its own outcome — never as a pass, and never as a verdict about the thing it checks.

**BEFORE** — Controls render their own blindness as a result: the close-completeness probe exits 0 on an INCOMPLETE verdict, checks report clean over a smaller population than they declare, the pre-launch quota gate reads PROCEED from a pool reading it cannot tell apart from exhaustion, and a transport or exec failure surfaces as an unmerged PR or a malformed input.

**Actor(s):** the platform's CI gates, deploy-time checks and hooks, and the release hub's pre-launch quota gate.

**Success Indicator:** for every control this release touches, the Stage-7 evidence ledger records one input the control cannot evaluate, the pre-fix run reporting it as clean or as a verdict about its subject, and the post-fix run reporting a distinct not-evaluated or instrument-failure state (CIAC-6).

---

## Tier-A Activated Design Artifacts

| Artifact path | Flow class | Trigger | Activation tier | G-CL6 obligation |
|---|---|---|---|---|
| `core/deploy/deploy.sh` — the VERDICT → EXIT CONTRACT table on `cmd_check_close_completeness`, with its cause-to-class table (the family's authoring-home convention) | data-flow | #4318 modifies an output contract with at least two consumers (the workflow gate step, lifecycle Check 48, the self-test, #4917's census) | A — rewritten wholesale | at close, the table equals `_cc_verdict_exit_code` (self-test arm (8) is its executable mirror) |
| `core/standards/gate-efficacy-standard.md` — the close-completeness register row | data-flow (governed projection) | the same contract | B — refresh | the row states the shipped map, NOT-EVALUATED, the armed network cutover and the flip clause |
| `release/references/standards/release-corpus-schema.md` § Row classes | data-flow | #4318 moves one limb in the limb × class contract read by five enumerators and the projector | B — refresh | CHANGELOG sits in the DECLARED EXCLUDED row; "five exclusions" |

Each later card's spoke adds its own Tier-A rows here when its commits land (for example #5287's population-record definition and #6871's stage-13 diagram, declared in their designs).

---

## Rollback Strategy

| Issue | Rollback method | Complexity |
|---|---|---|
| #4318 | `git revert` of its commits; commit 1's revert restores the exit contract, the consumer and the register row together (R17); commit 2's revert restores the CHANGELOG enumeration and the schema row together | Low |
| #5287, #4917 | `git revert` in reverse order (#4917 then #5287), because #4917's census is authored in #5287's form; the census ADR reverts with #4917 | Low–Med |
| #7199 | `git revert`; if #5287 stays, reverting #7199 re-surfaces the dead roots as not evaluated — correct behaviour, not a regression — and re-adds their ledger entries | Low |
| #6865 | `git revert` plus a hash-verified hook-tier refresh (the deployed copy must revert too) | Med |
| #6237 | `git revert` plus a release-hub package rebuild and redeploy; revert #6871 first, because it sources #6237's classifier library | Med |
| #6871 | `git revert` (the self-test pin reverts with it) | Low |

**Whole release:** a partial revert for an isolated card failure; revert the merge commit for systemic failure; a forward fix for a well-understood minor issue. **A claimed version tag is retained and recorded, never deleted** — version tags are host-protected. After the claim, `git revert -m 1` stops once on this plan's claim-stamp rename: keep the stamped plan and continue.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `release/skills/release-hub/**` + `packages/release-hub.skill` | the installed skill mirrors | `./deploy.sh --deploy release-hub` | `deploy.sh --check` Checks 1, 7, 12 and 13 green |
| 2 | `core/hooks/block-fragile-refs.sh` and `core/hooks/lib/fragile-ref-patterns.sh` | the deployed hook tier | a hook refresh through the governed update path | **hash equality** between each source and its deployed copy — never the refresh's exit code |
| 3 | `deploy.sh`, the workflows, the release tools (the evaluator and the classifier library included), the standards, the schema and the protocol | — | none (repository-resident; CI and the hub read them from the checkout) | n/a |

**Schema migrations:** N/A — enumerated over {RELEASE_LOG rows, operator config keys, log-record shapes, warn-log rows}; none is rewritten. The NOT-EVALUATED warn-log rows the lifecycle Check 48 arm writes use the existing `"evaluated":false` row class.

**`deliverable_state: deployed-copy-synced`** — reached at Stage 12 when rows 1 and 2 verify by content.

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **#4318 Stage-4 amendments:** AC-1 re-anchored (three declarations must agree; SKIP joins the contract); AC-2 a three-way choice; AC-3 restated in the same commit as the contract change; AC-5 to AC-8 added (absorbed from #7466's criteria 2–4 and 6; D-Drain-48; D-Instr-48); size S → M | Stage-4 gate D4, D5 (hub action item AI-001) | **APPLIED** — AC rows plus OBL-1..OBL-7 in § Verification Plan |
| **DEV-2** | **#5287 Stage-4 amendments:** the `[DRAFT]` seam confirmed; AC-3 gains a real-instance arm; AC-5's worked reference re-ranked; the zero-resolving-root mechanism owned here | Stage-4 gate (AI-001) | **APPLIED** — OBL-1..OBL-4; the amendment's "Check 23" is Check 25 (DEV-12) |
| **DEV-3** | **#4917 Stage-4 amendments:** sub-shape (iii) discharged (v4.60); AC-1 population (the drift-engine callers plus #7466 criterion 1's partition); AC-2 discharged; AC-3 in #5287's form; AC-4 discharged for Check 48 by #4318; affected files corrected; Check 32 named residual; size L → M | Stage-4 gate (AI-001) | **APPLIED** — OBL-1..OBL-5 |
| **DEV-4** | **#7199 Stage-4 amendments:** the Stage-2 verdict rendered (Approve); AC-2's population is 16 lines in 7 files; the mechanism belongs to #5287; size XS → S | Stage-4 gate D3 (AI-001) | **APPLIED** — OBL-1..OBL-2 |
| **DEV-5** | **#6865 Stage-4 amendments:** AC-1 on both platforms; AC-2's 13 sites plus the six report emits, with the malformed-JSON message separated from an exec failure; AC-3's arm above 1 MiB, observed RED in CI | Stage-4 gate (AI-001) | **APPLIED** — OBL-1..OBL-3 |
| **DEV-6** | **#6237 Stage-4 amendments:** AC-4's five consumer surfaces (sanctioned session; package rebuilt); AC-2/AC-3 made executable | Stage-4 gate (AI-001) | **APPLIED** — OBL-1..OBL-2 |
| **DEV-7** | **#6871 Stage-4 amendments:** AC-1 re-anchored (the second GraphQL-bound read moves too); AC-2 reworded (not-merged versus unresolvable); AC-3's population is the GraphQL-bound PR reads; the convention sentence cites § 4.3b; coordination with `closeout-verification-rows-consistent` | Stage-4 gate (AI-001) | **APPLIED** — OBL-1..OBL-4 |
| **DEV-8** | **#7466 scope allocation:** criteria 2, 3, 4 and 6 to #4318; criterion 1 to #4917; #7466 retains criterion 5 and stays unmilestoned | Stage-4 gate D4 (AI-001) | **RECORDED** — the PR references #7466 and does not resolve it |
| **DEV-9** | **Stage-5 Checkpoint B override:** DEFER after the #4917 and #6865 spokes stopped at the account session limit (basis lowered to SERIALIZE); the operator overrode to PROCEED at width 1, for that batch only | Operator, 2026-09-25T08:38Z (AI-007) | **RECORDED** — the recommendation diverged on timing only |
| **DEV-10** | **The Phase A6.5 review wave serialized**, one review at a time in Stage-6 order | Operator, 2026-09-25T14:10Z | **RECORDED** |
| **DEV-11** | **#4318 matrix, Tier 1 at this commit:** `.github/close-completeness.enforce` added (the sentinel comments) and `release-corpus-schema.md` added (F-2: the schema row moves with the drain); the `hub-spoke-bridge.md` sentence promoted (CR-BUNDLE-1); F-5: the register row re-arms (the network cutover is armed, not dormant). `CONDITIONAL:S5-EXITCODE-TEST-FILE` resolved **false** (D-7 T-3; the Collective Review did not adopt #7878 CD-2): **NOT DELIVERED** — `core/deploy/tests/test_close_completeness_exit_codes.sh` (add), and its allowlist and `install-tests.yml` companion rows, which no longer belong to #4318 | #4318's design and the hub's evaluation (Tier 1 at Commit 0) | **APPLIED** — § File Change Matrix |
| **DEV-12** | **#5287, Tier 1 at this commit:** CIAC-3's text (Check 25, not 23; the form-agnostic grep pair — the line-form grep is a broken probe on the array form; F-1); `install-tests.yml` added comment-only (F-3 (i)); `test_gate_efficacy_declarations.py` edited by #7199 too (F-3 (ii)); `CONDITIONAL:S5-SCOPE-GAP-SELFREPAIR-ROW` **NOT FIRED — NOT DELIVERED** (`core/schemas/gate-criteria-spec.md`; F-4); `decision-emission.yml`'s group count de-literalized in #5287's matrix (#7879 PR-3, AI-008) | #5287's design and the hub's evaluation | **APPLIED** |
| **DEV-13** | **#4917, Tier 1 at this commit:** `CONDITIONAL:AC1-COLLAPSE-FOUND` **NOT FIRED — NOT DELIVERED** (`release/tools/capture-release-bodies.sh`, `release/tools/preflight-release-body-reemit.py`, `release/tools/reemit-release-bodies.sh`; the audit found no collapse); the harness row is an edit; `install-tests.yml` becomes one `run:` edit under (A′) rather than comment-only; AC-1's "6 callers" becomes "8 decision sites in 6 callers" (F-5); OBL-1..OBL-4 per the design (OBL-4 cites #6620); the census ADR added (CR-BUNDLE-2); `decision-emission.yml` Change 5 does not fire, because #5287 de-literalizes the count | #4917's design, the hub's evaluation, CR-B1, CR-BUNDLE-2 | **APPLIED** |
| **DEV-14** | **#7199, Tier 1 at this commit:** AC-1's row replaced by probe P-7199-AC1 (FR-2); the matrix gains the harness edit, `check-doc-links.py` (D-R3 (a) fired) and `operations/README.md` (D-R (A)) (FR-3); CIAC-3 concurrence (FR-4); direct RED observation, not armed-red-then-revert (FR-13); ADR-007's two decision lines relabelled preserve-with-reason in AC-2's row (#7881 FM-2); `core/hooks/lib/fragile-ref-patterns.sh` added (CR-BUNDLE-4) | #7199's design, the hub's evaluation, #7881's consumption, CR-BUNDLE-4 | **APPLIED** |
| **DEV-15** | **#6865, Tier 1 at this commit:** the matrix gains the fixture runner and the marker fixture, comments only (R7); `CONDITIONAL:SIZE-LIMIT-RETAINED` resolved **false** — **NOT DELIVERED** (`core/rules/bypass-mode-readiness.md`); the Linux `install-tests.yml` leg is not taken; the D-Swallow arm's suite (`core/hooks/tests/ghsa-g9g6-primitive-fail-closed.test.sh`) promoted under CR-B2 (a′) `[INFERRED — (a′) keeps the invalid-ERE arm meaningful; the order-5 spoke confirms, or records NOT DELIVERED]` | #6865's design, the hub's evaluation, CR-B2 | **APPLIED** |
| **DEV-16** | **#6237, Tier 1 at this commit:** the mechanized-evaluator condition fired (evaluator add, manifest and allowlist edits promoted); the ADR rows (F-1); `CONDITIONAL:AC4-CONSUMER-IN-A6-NOTE` does **not** fire — **NOT DELIVERED** (`release/references/pipeline/stage-04-planning.md`, invariant with a probe record; ADR-156 is a sixth, decision-record surface; F-2); the consumer-in-skill-body condition fired (`SKILL.md` promoted); the re-design adds the classifier library, the `release-tooling-smoke.yml` trigger path and the `repo-host-adapter-versioning.md` named-gap note (re-design F-1); **re-design F-2:** #7883 PR-1's fresh-window consequence ("both read `used = 0` → false DEFER") was not reproduced at the one live GraphQL rollover `[INFERRED; not reproduced at one live rollover, which cannot separate a foreign window-start from a charged window-starting read]`; its steady-state premise was reproduced, and the repair stands — an anchor must be the probe's own draw in every window state | #6237's designs and the hub's evaluations | **APPLIED** |
| **DEV-17** | **#6871, Tier 1 at this commit:** plan row 7(a) reworded — "`merged` flag first; SHA only when merged; a value only from an answered response" — and AC-2's row bound to the test-merge-SHA arms (F-1); CIAC-5's method made precise (F-2); the stage-13 convention row fires and `CONDITIONAL:S5-CONVENTION-HOME-GHAPI` does not — **NOT DELIVERED** (`core/standards/gh-api-convention.md`; F-3); under B2 the library and evaluator-edit rows and Commit 7.0 drop out (ML-6871-D-2) | #6871's design, the hub's evaluation, the short scope lock | **APPLIED** |
| **DEV-18** | **CR-B0:** #6237 returned alone to Solutioning (the uncharged GraphQL probe); re-designed and short-locked | Collective Review; short scope lock | **APPLIED** — § Decision Record |
| **DEV-19** | **CR-A1 (ii):** #4318 NE-b (NOT-EVALUATED 3 under every sentinel; cause-conditional escalation at the flip) replaces the design's NE-a; #6865 P2; the ADR-134 amendment (G-6) is not needed | Collective Review | **APPLIED** — § Decision Record |
| **DEV-20** | **CR-A2:** #5287 S2 · #4917 D-4917-3 (A) · #7199 (a) | Collective Review | **APPLIED** — § Implementation Sequence |
| **DEV-21** | **CR-A3 (a):** #4318's drift-engine exit-3 arm emits NOT-EVALUATED | Collective Review | **APPLIED** — § Decision Record |
| **DEV-22** | **CR-A4 (B):** `.claude/rules` repointed to `core/rules` (D-9), with the operator's V-8 read before merge; non-detection item 5 | Collective Review | **APPLIED** — CIAC-3's note |
| **DEV-23** | **CR-A5 (A):** P6 from a synthetic ledger fixture, plus the C5 summary line | Collective Review | **APPLIED** — order 2 |
| **DEV-24** | **CR-B1 (A′):** #4917 repairs the vacuous install-regression precision probe | Collective Review | **APPLIED** — order 3; DEV-13 |
| **DEV-25** | **CR-B2 (a′):** #6865's ERE compile canary plus the hardened detector form for the transport residual | Collective Review | **APPLIED** — order 5; DEV-15 |
| **DEV-26** | **CR-B3 (b):** one repair card for the three graduated instances | Collective Review | **RECORDED** — filed by the hub, outside this release |
| **DEV-27** | **CR-B4:** #6871 S → M, #6237 M → L, #4917 M → L; 36 raw / 47 effective under an extended G3-15 Override | Collective Review | **APPLIED** — § Scope, § Release Class declaration |
| **DEV-28** | **CR-B6:** #6871 D-6 as CD-2 — `read_state` fails closed under `--apply` unless the release PR is answered merged into `main` (DEFERRED excepted); `--dry-run` records and predicts | Collective Review | **APPLIED** — order 7 |
| **DEV-29** | **CR-BUNDLE-1 to CR-BUNDLE-4** — the designs as recommended, the census ADR, the cause-to-class table, the shared pattern file | Collective Review | **APPLIED** — § Decision Record, § File Change Matrix |
| **DEV-30** | **Short scope lock for #6237 (PA-001), with #6871 D-2:** ML-D-1′, D-4′, D-6′, D-7 (i), D-8 (a), D-9, B2; #6871 stays M | Operator, 2026-09-26 UTC | **APPLIED** — § Decision Record |
| **DEV-31** | **Pacing:** continue without a pause; every phase resumable from a new hub session (a divergence from the recommended pause) | Operator, 2026-09-25 | **RECORDED** — R22 |
| **DEV-32** | **D-Version re-determination:** provisional `v4.69` → `v4.70`, re-verified at this commit | Hub (recorded determination) | **APPLIED** — § Header, § Commit-0 Version Re-Verify Record |
| **DEV-33** | **The A1–A2 checkpoint is presented after the fact.** The Stage-6 shard asks for A1–A2 to be presented before B1; the hub's brief directs Commit 0 → the draft PR → #4318's commits end to end, under the Collective Review scope lock (Tier 3 after that gate) | The hub's Stage-6 brief, under the operator's scope lock | **RECORDED** — A1 (entry contract: PROCEED — every input present; the stamp manifest resolvable) and A2 (§ Implementation Sequence) are in this file and in the Stage-6 output comment |
| **DEV-34** | **The Stage-4 hub findings adopted at the gate** (D-Instr-48's evidence; the `telemetry-is-computable` Parallelization-Map row; the release-hub package risk; #6865's measured population) | Stage-4 gate | **APPLIED** — R18, § Contention |
| **DEV-35** | **#4318 — the single exit path is a helper, not an inline expression.** The design's arms read `exit "$(_cc_verdict_exit_code …)"`; #7878 F-2's handshake needs a line printed immediately before every exit, so every arm calls `_cc_exit_through_mapping`, which prints `close-completeness-exit: <code>` and exits with the mapping's integer. Arm (12) asserts the probe body holds no exit statement and the helper's one exit is fed by the mapping | #7878 F-2 (Tier 1), implementation form | **APPLIED** — `dc81c7e1` |
| **DEV-36** | **#4318 — the RED arms landed one commit ahead of each fix** (`1eb7a2ee` before `dc81c7e1`; `e6fb603b` before `eeaa22be`), the design's optional RED-arm commit, so each RED is also observable in the draft PR's CI; D-10's Commit 1 therefore carries the fix without its arms | The design's commit topology ("a separate RED-arm commit is optional"); CIAC-6 | **APPLIED** |
| **DEV-37** | **#4318 — the cause set gains `body-drift-missing`** (CR-A3's drift-engine exit 3 after the Release was found), one token beyond Canonicalization #5's closed set; and two arms beyond the design's table: (14l) for that cause, and (14m) for the network-leg denominator (present + absent + NOT-EVALUATED = network-scoped, the design's Change 5) | CR-A3; the design's Change 5 | **APPLIED** — `1eb7a2ee`, `dc81c7e1` |
| **DEV-38** | **#4318 — two declarations reconciled beyond the design's sweep list**, in the file already being edited: the OS-group T1 comment in `cmd_self_test` ("the warn sentinel maps INCOMPLETE to 0") and the close-completeness block header, which listed arms (1)–(4) only | The Stage-6 cascade sweep (reconcile, don't annotate) | **APPLIED** — `1eb7a2ee`, `dc81c7e1` |
| **DEV-39** | **#4318 — the handshake is honoured for exits 2 and 3 only, as locked.** Extending it to exit 0 (so a run that ends without verdicting cannot read as CLEAN) is not taken here | #7878 F-2 as locked | **RECORDED** — surfaced as Informational in the Stage-6 output |
| **DEV-40** | **The `PMO Pipeline` project board is closed** (as are the owner's other boards), so the draft PR is on no board, like the two preceding release PRs | Stage-6 PR metadata | **RECORDED** |
| **DEV-41** | **#4318's verification stopped on a GraphQL quota refusal** at 2026-09-26T02:15Z, per the brief's stop rule. The RED and GREEN records, the baseline `deploy.sh --check`, the cascade sweep and the static scans ran; the AC-6 mutation arm, both live probes, the post-fix `deploy.sh --check`, the post-fix executor and the CI reads did not | The Stage-6 brief's quota rule | **RECORDED** — § Verification Evidence names each un-run row |

**Phase A6.5 Minor findings** (hub action item AI-010) — one line each, with its review sub-task:

| # | Review | Card | Finding (Minor) | Disposition |
|---|---|---|---|---|
| **MIN-1** | #7878 | #4318 | P-2 — the network-leg resolver is authored below two existing seams (the repo-host adapter; § 4.3b's classifier) | the cause-to-class table is applied (CR-BUNDLE-4); the resolver's header cites why `deploy.sh` does not source `claim-version.sh`; the adapter's `gh repo view` spelling is not adopted because it rides the GraphQL pool; sourcing `host-refusal-class.sh` is a named follow-on |
| **MIN-2** | #7878 | #4318 | CD-2 — the exit-map suite belongs under a required context (a standalone test file) | **not adopted** (the Collective Review kept T-3); raised as a Tier 2 finding only if found necessary at Stage 6 |
| **MIN-3** | #7879 | #5287 | PR-3 — C7's census finds 8 of the 10 assertion groups, hiding a count reference | into #5287's Stage-6 brief (AI-005): correct C7; `decision-emission.yml` de-literalized (DEV-12) |
| **MIN-4** | #7879 | #5287 | PR-4 — the `degraded` state changes the meaning of the frozen vocabulary it claims to consume | into #5287's brief: the `degraded` wording and the PV-7a rider |
| **MIN-5** | #7879 | #5287 | FM-1 — no standing arm exercises the worked references' call sites; a bash 3.2 empty-array abort in Check 25's not-run state | into #5287's brief |
| **MIN-6** | #7879 | #5287 | FM-2 — Check 25's declared exemption surface resolves to nothing | the declaration wording is a Tier 1 to #5287; the instance repair filed as #7892 |
| **MIN-7** | #7879 | #5287 | FM-3 — anti-vacuity arms keyed to live instances turn the target state red | into #5287's brief: synthetic arms, P6 included (CR-A5) |
| **MIN-8** | #7880 | #4917 | PR-3 — the shape rule classifies a step by the `case` keyword, not by the values it compares | into #4917's Stage-6 brief (AI-010) |
| **MIN-9** | #7880 | #4917 | PR-4 — the ADR skip rationale does not engage the guide's triggers | resolved: the census ADR is adopted (CR-BUNDLE-2) |
| **MIN-10** | #7880 | #4917 | PR-5 — the member rows sit in a governance document although the harness has a seam for keyed rows | advisory altitude flag; census rows kept where designed (CR-BUNDLE-4) |
| **MIN-11** | #7880 | #4917 | CD-2 — verify the probe-direction classification instead of recording it | to #4917's spoke at the Collective Review's discretion |
| **MIN-12** | #7880 | #4917 | cosmetic — six files name the drift engine, not five | into #4917's brief |
| **MIN-13** | #7881 | #7199 | PR-2 — the hook and the workflow keep two hand-copied predicates beside an existing seam | resolved: the predicate moves into the shared pattern file (CR-BUNDLE-4) |
| **MIN-14** | #7881 | #7199 | CD-2 — fix the two known mechanical defects in the README's Public-API block | resolved: the two README token fixes (CR-BUNDLE-1, D-R (A)) |
| **MIN-15** | #7881 | #7199 | FR-9 raised from Informational to Minor | recorded on the card |
| **MIN-16** | #7881 | #7199 | cosmetic — the split-rule line anchors in D-R6 and FR-10 are off by one | locate by anchor text at order 4 |
| **MIN-17** | #7882 | #6865 | PR-2 — the jq exit-code partition assigns jq's own instrument states to the payload-verdict branch | Tier 1 to #6865's spec: name jq exits 2 and 3 as a residual; print jq's exit code on the `INPUT-INVALID` line |
| **MIN-18** | #7882 | #6865 | CD-3 — keep the four pre-scope reads off the filesystem (builtin `printf` into a pipe before the scope gate) | considered at the Collective Review under CR-A1 (P2) |
| **MIN-19** | #7882 | #6865 | CD-4 — the class remedy's seam is the existing `lib/dep-resolve.sh`, not a copy per hook | enrichment on #7835 |
| **MIN-20** | #7883 | #6237 | FM-1 — an enum check copied from a single-owner selector onto a shared one | Tier 1 to #6237's spec: the runtime check tests the configured value; enum-versus-branch parity moves to a CI arm |
| **MIN-21** | #7883 | #6237 | FM-2 — a doubling backoff with no component that owns the count | Tier 1: the consecutive-refusal count is held on the DEFER action item; the cap is ML-D-9 |
| **MIN-22** | #7883 | #6237 | FM-3 — shared-file state carried from the Stage-4 map instead of the sibling designs | Tier 1: re-anchor after #4318's bridge sentence lands (this release, order 1) |
| **MIN-23** | #7883 | #6237 | CD-3 — keep (c) as a narrowed residual instead of deleting it | adopted in the re-design (item 2); the discriminator to #7847 |
| **MIN-24** | #7884 | #6871 | PR-2 — the convention paragraph restates its sources and overstates one | Tier 1 to #6871's spec: cite § 4.3b; drop the overstated clause |
| **MIN-25** | #7884 | #6871 | PR-3 — the REST facts are written at spec altitude without saying they apply to REST only | Tier 1: keep the stage-13 paragraph host-agnostic, citing the binding in § 4.3b |
| **MIN-26** | #7884 | #6871 | FM-2 — classifier boundaries assign classes the remedy map contradicts | Tier 1: gate `retry-after` on 403/429; a missing status line is transport only on `gh` exit 1; two arms (the rows live in #6237's binding) |
| **MIN-27** | #7884 | #6871 | FM-3 — the REST files fallback ends silently at the host's cap | Tier 1: a full page 30 sets a truncation note and returns 1 |

---

## Documentation Impact

| Issue | Declared docs | Status | Commit | Notes |
|---|---|---|---|---|
| #4318 | the gate-coverage register row for close-completeness (`core/standards/gate-efficacy-standard.md`) | done | `dc81c7e1` | restated in the contract commit (AC-3). Also reconciled: the enforce sentinel's comments and the `hub-spoke-bridge.md` sentence (`dc81c7e1`); `release-corpus-schema.md` § Row classes (`eeaa22be`) |
| #5287 | the gate-efficacy standard (Requirements (b)/(c), register rows) | pending — order 2 | — | |
| #4917 | the gate-efficacy standard's census section; the census ADR | pending — order 3 | — | |
| #7199 | `release/README.md`, `operations/README.md`, the split rule | pending — order 4 | — | |
| #6865 | none declared at Intake beyond the hook comments | pending — order 5 | — | |
| #6237 | `quota-budget-protocol.md` § 4.3b and its consumers; the ADR | pending — order 6 | — | |
| #6871 | `stage-13-close.md`'s convention paragraph | pending — order 7 | — | |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification, extended at Stages 7, 8, 12 and 13.*

| Check | Result |
|---|---|
| **Commit-0 version half** | `git fetch --tags origin` and `git fetch origin main` (exit 0); the adapter's dry-run recomputes **`v4.70`** for bump-class `minor` (rc 0, no tag pushed); the slot is free on the tag and ledger arms, with `v4.69` as the control (probe record above). **No HALT** |
| **Commit-0 manifest half** | `bash release/tools/claim-version.sh --verify-stamp controls-fail-loud`, run after this file was written and again after this section was written, before the commit → exit **0** both times: *"verify-stamp OK — controls-fail-loud carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s)); package-consequence checks not exercised"*. A fixed-string count of the double-brace placeholder over this file → **1**, the Header `**Version**` cell. **No HALT** |
| **AC binding at Commit 0** | `python3 release/tools/check-ac-binding.py --fetch` over this plan → **VERDICT BOUND**. 27 AC rows bind one-to-one to the 27 live checkbox criteria of the seven cards (#4318 4 · #5287 5 · #4917 4 · #7199 2 · #6865 4 · #6237 4 · #6871 4). The 27 OBL rows report DISPLACED — excluded from the criterion set, which is what a Stage-4 amendment row is. Every `ac_baseline` count equals its live count, so no criterion was added or dropped after `8e0ee084` |
| **Plan-driven executor at Commit 0** (pre-commit) | `bash release/tools/verify-release-plan.sh --stage4-comment <the three Stage-4 parts, concatenated> <this plan>` (md format; the FCM range defaults to `merge-base(origin/main, HEAD)..HEAD`), over this file before this section's Commit-0 rows were written → **12 PASS / 13 FAIL / 8 SKIP / 38 ERROR** over 54 per-issue rows (exit 3). This section lies outside every surface the executor parses, so the counts stand for the committed file. Every non-PASS row is classified. **FAIL 13:** FCM-1..FCM-5 are declared ADDs not yet delivered, as expected at Commit 0 — FCM-5 is this plan (untracked at that instant), FCM-1 the census ADR (order 3), FCM-2..FCM-4 #6237's two tools and its ADR (order 6). #5287 AC-2 and AC-4, #6871 OBL-4 and CIAC-5 are pre-fix zero counts that orders 2 and 7 raise; the per-issue family grades a zero-count `grep -c` on its exit status (#7899). #4318 OBL-3, #5287 AC-5 and OBL-2, and #6237 OBL-1 are `deploy.sh --check` exiting 1 on the base tree, graded on the exit alone. **SKIP 8:** a method naming a tool outside the executor's allowlist (#4318 OBL-5, whose first command-shaped span is `hub-spoke-bridge.md`; #7199 AC-2's `git grep`); documented-decision methods (#5287 OBL-4, #7199 OBL-2, CIAC-2, CIAC-6); no executable command (#6237 AC-3, #6871 OBL-1). **ERROR 38:** 36 `unclassified-method` — self-test arms and named reads, which the executor's closed read-only verb set cannot run by design — and 2 `count-unreadable`, #4318 AC-3's two-stage pipeline and #6865 AC-2's alternation, where the table's escaped pipe reaches the matcher. Their verdicts are the arms' and the direct reads', at each card and at Stage 7. **PASS 12:** FCM-COVERAGE (`declared=57 interpreted=57 obligations=5 excluded=11 conditional=1 uninterpreted=0 pathless=0`), FCM-6 (the conditional ADD, recorded not fired) and the four provenance rows are real verdicts. The six per-issue and CIAC PASS rows — #4318 OBL-1, #6237 AC-1, #6871 AC-3, CIAC-1, CIAC-3, CIAC-4 — are graded on exit status over pre-fix counts, not against their Expected cells, and carry no evidence until their cards land |
| **Provenance survival at Commit 0** | PRESENCE PASS (1 label) · GRAMMAR PASS (`form=X date=2026-09-24`) · DELTA PASS, **re-computed independently**. On this host the executor's delta limb reaches `prov-no-loss` without comparing: it hands a multi-line value to `awk -v`, which the macOS system awk rejects (`newline in string`, exit 2 — three such lines on this run's stderr), so the lost set it reads is empty whatever the inputs (#7898). Measured here: with a one-element value the replica reports the lost element; with a two-element value it exits 2 and prints nothing, where one element is lost. Re-computed with the executor's own five element predicates under `/usr/bin/grep`: the Stage-4 comment carries 5 elements and this plan carries all 5. Control: a planted copy with its `CIAC-` tokens altered loses exactly `ciac`. Routed, not changed here |
| **Links at Commit 0** | This plan carries no inline and no reference-style markdown link sequence (control: the release-corpus schema carries 18 inline ones), so the dead-file-reference gate and the release-corpus link checker have no target to resolve in it |
| **#4318 — baseline `deploy.sh --check` at the branch base** (`35dbf418`, before any #4318 commit) | `bash core/deploy/deploy.sh --check` → exit 1, "2 issue(s) found", both outside #4318's files and pre-existing: Check 47 (13 §5.1 body-drift findings) and Check 63 count-structure. Check 48 (lifecycle, this checkout's remote is the GitHub repository): WARN, 22 findings across 90 VERIFIED rows = 13 §5.1 drift + 2 Velocity-field + 7 version-less CHANGELOG; network sub-checks armed at `v3.96`, 83 rows network-checked. Check 62 OK (34 register pointers resolve); Check 69 OK (0 unsanctioned spellings, 299 sanctioned occurrences as its control) |
| **#4318 — RED, Commit 1a** (`1eb7a2ee`, arms (8)–(15) over the pre-fix probe) | **Predictions, stated before the run: 38 FAIL lines** — (8)–(10) 1 (the mapping function absent); (12) 3 (5 numeric-literal exits; 5 exit statements and 0 helper calls; the helper absent); (13) 15 (wrong exit on 6 runs — SKIP/warn 0, SKIP/enforce 0, NOT-EVALUATED/warn 0, NOT-EVALUATED/enforce 1, INCOMPLETE/warn 0, INCOMPLETE with no sentinel file 0 — and no handshake on all 9); (14a) 2; (14k)'s field count 1; (14b), (14c), (14d) second pair, (14f), (14g), (14h), (14i), (14j), (14k), (14l) 1 each; (14m) 3; (15) 3 (a binary RC test, no `case`, no handshake). Predicted GREEN: (11), (12b), (12c), the exits of (13) CLEAN×2 and INCOMPLETE/enforce, (14d) first pair, (14e), (15)'s sentinel-read count, (15b), (15c). **Observed:** `bash core/deploy/deploy.sh --self-test` → `self-test: FAIL (38 failure(s))`, exit 1 — exactly the 38 predicted lines and no other; every other group passes. Re-run after the (15b) fixture dropped a `\| head` pipe: the identical 38 lines (`cmp` equal) |
| **#4318 — GREEN, Commit 1b** (`dc81c7e1`, the contract, instrument, consumer and register row in one commit) | `--self-test` → `self-test: PASS`, exit 0, 0 FAIL lines: the 38 RED lines of Commit 1a now pass |
| **#4318 — RED, Commit 2a** (`e6fb603b`, arm RC-5b over the pre-fix limb (d)) | **Prediction, stated before the run:** exactly 1 FAIL line — the version-less row draws 1 CHANGELOG finding; the versioned control passes. **Observed:** `self-test: FAIL (1 failure(s))`, that line |
| **#4318 — GREEN, Commit 2b** (`eeaa22be`, limb (d), the DENOM text, the schema row) | `--self-test` → `self-test: PASS`, exit 0, 0 FAIL lines |
| **#4318 — AC-3 and OBL-1** | `grep 'close-completeness probe' core/standards/gate-efficacy-standard.md \| grep -c 'warn: summary + exit 0'` → **0** (control, the same pipeline at `8e0ee084` → 1). `grep -c 'if \[ "\$RC" -eq 0 \]' .github/workflows/close-completeness.yml` → **0** (control at `8e0ee084` → 1). Arm (12) passing is the AC-1 exit census: 0 exit statements in the probe body (pin: 5 numeric-literal exits) |
| **#4318 — cascade sweep** | `[REFCASCADE: a 9-pattern sweep of the retired contract's wording (verdict-driven red exit, sentinel swallow, the old 0/1 map, warn = exit 0, gate-offline finding, binary RC test, sentinel read by the workflow, network cutover dormant, CHANGELOG enumerated for version-less rows) over the 7 contract-surface files → pre 34 / post 7]`. Pre 34 = 28 UPDATE + 6 PRESERVE; post 7 = the same 6 PRESERVE (version-freeness's own contract, 3 hits; the required-subset's own warn-mode sentence; the register rows of two other gates) + 1 line of the (15b) sensitivity fixture. UPDATE sites: **pre 28 / post 0** |
| **#4318 — gate-efficacy declarations** | `/usr/bin/python3 core/deploy/tests/test_gate_efficacy_declarations.py` → exit 0: "OK — 39/39 gate-efficacy declaration(s) across 26 workflow file(s) agree with their triggers"; `close-completeness.yml`'s posture header is unchanged |
| **#4318 — static scans of the added lines** | Depersonalization: 0 operator identifiers in lines added under `core/`, `release/`, `.github/` (control: the fixture string `acme/widget` matches 4). Fragile references in the added markdown (the standard's row, the bridge sentence, the schema rows): 0 links, 0 issue references, 0 URLs, 0 version literals (control: the standard carries 3 issue references). SIGPIPE: the added shell lines pipe only into `sed -n …p` and `tail`, neither a short-circuiting reader |
| **#4318 — not run (stopped on a GraphQL quota refusal)** | At 02:15Z `gh issue comment` was refused: "GraphQL: API rate limit already exceeded". `gh api rate_limit`: graphql 0 of 5000, reset 02:20:17Z; core 4697 of 5000. Per the brief's quota rule the card stopped there (DEV-41). **Not run:** the AC-6 mutation arm (OBL-2); the live probe on a checkout whose remote is the GitHub repository (OBL-3; forecast INCOMPLETE 15 of 90, exit 2, 0 version-less CHANGELOG findings); the live probe on a clone whose remote is a local path (OBL-4; forecast NOT-EVALUATED `repo-unresolvable` for every network-scoped versioned row, with the aggregate line and the DEGRADED rider beside the non-network findings); the post-fix `deploy.sh --check` (Checks 48, 62, 69); the post-fix plan-driven executor; and the draft PR's CI results |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol, by #4318's Engineering spoke at Commit 0, and refreshed by each card's spoke as its commits land. Operator-facing.*

### Outcome

**A control that cannot evaluate its subject now says so, instead of reporting a pass or a verdict about the thing it checks.** Seven controls change. The close-completeness gate stops exiting 0 on an INCOMPLETE verdict: 0 becomes CLEAN's alone, a finding exits an advisory 2, and a check that could not reach GitHub reports NOT-EVALUATED on 3 rather than 75 false "no published Release" findings. Checks must declare the population they scan and report what they examined, and three never-existing scan roots stop being swallowed. A census names every consumer that could read "not measured" as "passed". Limb B fixes three instruments whose own failure was reported as a verdict: a hook that called a large valid Write "malformed", a quota gate that read PROCEED from a pool reading it cannot tell from exhaustion, and a close-out that called a merged PR unmerged when GraphQL ran out.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #4318 | the close-completeness probe exits 0 only on CLEAN; INCOMPLETE is advisory 2, a withheld verdict is 3, and a failed GitHub lookup is NOT-EVALUATED, never "absent" | LANDED (`1eb7a2ee`, `dc81c7e1`, `e6fb603b`, `eeaa22be`); verification partial — stopped on a GraphQL quota refusal (DEV-41) |
| #5287 | a check declares the population it covers and reports what it examined; an empty or short scan is reported, not passed | PENDING — order 2 |
| #4917 | every consumer that could collapse "not evaluated" into "passed" is censused and asserted by a test | PENDING — order 3 |
| #7199 | the three never-existing release roots leave the README, a check, a hook and a workflow | PENDING — order 4 |
| #6865 | a valid Write above the argument-size limit is adjudicated, and an unreadable input is reported as such, not as malformed JSON | PENDING — order 5 |
| #6237 | Checkpoint B's host-API axis reads its own charged probe and stops rendering PROCEED on an indistinguishable window | PENDING — order 6 |
| #6871 | close-out reads the merge fact over REST and reports an unresolvable read as unresolvable, never as not merged | PENDING — order 7 |

### Key decisions

- **#4318 D-1 — the family's four-member exit contract** through one factored function, over a verdict-driven red exit (which needs a second sentinel reader) and the status quo (three producers of 0).
- **CR-A1 (ii) — an instrument that could not evaluate never gates by default:** Check 48's NOT-EVALUATED exits 3 under every sentinel (ADR-134 D5); escalation by cause is decided at the enforce flip, for input failures only.
- **CR-A3 — the drift engine's exit 3 is NOT-EVALUATED**, consistent with #4917's Check 47 conversion.
- **D-Drain-48 — version-less rows are not asked for a CHANGELOG section**, and the governing schema moves in the same commit.
- **CR-A4 — `.claude/rules` is repointed to `core/rules`**, the corpus its check's standard names; **CR-B0 and the short scope lock** — #6237 re-designed around a charged probe and a shared, transport-aware classifier that #6871 sources.
- **D-Size, CR-B4 — kept whole at 47 effective** under an extended Override: one cause class with two limbs.

### Reversibility

**MODERATE — HIGH confidence.** Each card reverts with `git revert` of its own commits (#4318's contract, consumer and register row as one commit), and reverting the merge restores `main`; the release-hub package and the deployed hook tier are refreshed on revert. The claimed version tag is retained and recorded, never deleted.

### Downstream impact

- **The close-completeness gate goes advisory-visible:** 15 real findings (13 §5.1 body drifts, 2 Velocity fields) become a standing warning on every in-roster PR until a §5.6 re-emit sweep drains them; the sentinel cannot flip to `enforce` before that drain.
- **The flip to enforce is now a three-step clause plus a cause-conditional escalation decision**, recorded in the register row and the sentinel file.
- **Stage 12** refreshes the hook tier by hash and deploys the rebuilt release-hub package; the version claim contends with three in-flight siblings for `v4.70`.
- **Named residuals routed, not fixed:** the drift engine's failed body read surfacing as drift (#4714); the family's advisory-code handshake (#7889); #7466 criterion 5; the other hooks' pinned-`printf` idiom.

### Cross-references

- Release plan: this file — § Decision Record, § Verification Plan, § Deviation Log.
- Milestone: `controls-fail-loud`.
- User-facing release notes: `release/releases/notes/vX.Y_RELEASE_NOTES.md`, authored at Stage 13 Close per `release/references/standards/release-notes-standard.md`.

---

## Baseline pin

`origin/main` @ **`8e0ee084`** (`8e0ee08450a5e1d64f352279a3ab0f4a6ce46f6d`) — the Stage-4 baseline pin (the v4.68 Stage-13 corpus merge), measured at Stage-4 Phase A0 and carried by every Stage-5 design. Read by the Stage-9 mid-pipeline divergence re-check.

**The release branch's base:** `35dbf418` (`35dbf41847df2c1deab792d2944e46ac6ddd26fd`), `origin/main` at Engineering Commit 0 — 35 commits and 18 files past the pin (the `v4.69` merge and its close-out). **0 of those 18 files is an edited row of this matrix**; the one matrix-adjacent path, `core/rules/bypass-mode-readiness.md`, is a CONDITIONAL row that resolved false (DEV-15). Probe: `git diff --name-status 8e0ee084 35dbf418` → 18 files; control: the same diff restricted to #4318's six matrix paths → 0, against 18 for the whole tree.

---

## Issue References

The seven content members of this milestone are resolved by the release PR's Issue References block; #7466 is referenced only.

- **#4318** — the close-completeness probe declares a verdict-driven red exit its body does not implement. Four checkbox criteria plus four added at the Stage-4 gate.
- **#5287** — automated checks silently omit part of the surface they are believed to cover. Five criteria.
- **#4917** — the never-FAIL class: three sub-shapes of a control reporting success without measuring. Four criteria.
- **#7199** — `release/README.md` advertises roots that have never existed. Two criteria.
- **#6865** — the fragile-reference hook fail-closes on a large valid Write and reports it as malformed JSON. Four criteria.
- **#6237** — Checkpoint B's host-API axis renders PROCEED on an indistinguishable window. Four criteria.
- **#6871** — close-out resolves the merge SHA over GraphQL. Four criteria.
- **#7466** — the duplicate whose criteria were allocated to #4318 and #4917; it keeps criterion 5.
- **#4714** — owns the drift engine's exit contract (its failed body read, routed from #4318).
- **#7889** — the advisory-code handshake defect across the exit-code family (routed from #4318's review).
- **#6620** — owns Check 32's dormant cutoff (cited by #4917's census).
- **#6872** — the `obligations-get-runners` card whose Check 48 instance co-discharges with #4318's drain.
- **#7683 · #7801–#7807 · #7878–#7884 · #7808–#7814** — the Stage-4, Stage-5, Phase A6.5 and Stage-6 hub sub-tasks carrying the plan source, the designs, the reviews and the decision records.
