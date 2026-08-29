<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
<!-- CIAC-1 requires both members to NAME the operator-local memory store and give consistent
     answers on whether it is reached, so the plan's non-coverage section and its CIAC predicate
     both cite it. Same deliberately-documented exception the prior release plans carry. -->
---
title: Release Plan — declarations-have-a-firing-surface (a governed procedure that declares a trigger acquires a named runner or a named gap)
type: release-plan
plan_type: release
status: ACTIVE
release: version-less (theme-named; no tag claimed)
milestone: 368-declarations-have-a-firing-surface
release_class: novel
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `declarations-have-a-firing-surface`

**Milestone:** `declarations-have-a-firing-surface` (#368) · hub sub-task #6260 = Stage 4 plan source · #6264 = #5825 Stage 5 Solutioning source · #6265 = #5826 Stage 5 Solutioning source · #6266 = this Engineering slice
**Version identity:** **version-less / theme-named** — the milestone title is slug-only, so the release carries no version key. **No tag is claimed at Stage 12**; the Engineering-Commit-0 version re-verify and the Stage-12 atomic version claim are **INAPPLICABLE** (there is no version slot to contend for). No `{{RELEASE_VERSION}}` token is emitted anywhere in this plan, and `claim-version.sh --verify-stamp` is not run.
**Topology:** D-C SINGLE — one release branch (`release/declarations-have-a-firing-surface`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (operator-ratified) — Stage 6 slices route one at a time in dep order on the single branch. #5826's slice builds on this branch after #5825's lands.
**Release class:** `novel` — **re-classified from `routine`** at Stage 4 Plan Review (2026-08-28); see § Operator Decisions § D-ReleaseClass.
**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-29, domain: governance }` — determined at Stage 4 Phase A1.5 and carried unchanged through Stage 5 (§ 5.7: the design depends on no external best-practice; the governance domain guide was consulted and no contraindication fired).

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #6260, reconciled to the approved **Stage-5 Solutioning** designs posted on #6264 (#5825) and #6265 (#5826) and to the **Collective Review scope-lock dispositions** posted on #6266 (decisions **D-3** / **D-4** / **D-5**). Where a scope-lock disposition superseded a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at Engineering Commit 0 by the first Engineering spoke (#6266).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (theme-named; no tag, no stamp manifest) |
| **Date Created** | 2026-08-29 (Saturday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/declarations-have-a-firing-surface` |
| **Baseline pin** | `origin/main` @ `e19a9d30682abefac51cca1ff8aa0ebbf8708593` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `declarations-have-a-firing-surface` (#368) |

---

## Scope

### Summary

Two members, no hard dependency edge, one in-bundle file contention, **zero stage skips**. The release's capability outcome: **a governed procedure that declares a trigger acquires a named runner or a named gap** — the platform's existing firing-surface machine (the gate-efficacy class-3 register plus `deploy.sh --check` Check 62) is extended by one admission form so it reaches obligation-shaped procedures, and its first instance ships in the same PR.

The mechanism is an **admission-limb extension, not a new registry.** `core/standards/gate-efficacy-standard.md` already defines a class-3 *prose-declared normative predicate* admitted by `L1 ∧ L2` — where `L1` is a **verdict** limb, and the standard excludes conduct-constraining rules in terms. Class 3 gains a second admission form, `L1′ ∧ L2` (the **obligation** limb), routed into the same gate-coverage register and the same Check 62. **Check 62 needs no code change** — its computation was already general over `runner-def:` pointers; only the admission test was narrow.

**A second FORM, not a fourth CLASS.** The standard's `## Scope boundary — three gate classes` heading stays at three, by construction. That is the reason for the form-not-class shape: a fourth class would cascade across the heading, the version-history rows, and every consumer that repeats the count.

### Members

| # | Issue | Size | Surface | Slice |
|---|-------|------|---------|-------|
| 1 | **#5825** Governed procedures declare triggers with no surface that enforces them | L(8) | `core/standards/gate-efficacy-standard.md`, `release/references/templates/design-review-checklist.md`, `core/CLAUDE.md.template`, `release/references/standards/bundle-composition-doctrine.md`, `release/skills/release-hub/references/milestone-readiness-checklist.md`, one ADR | Engineering spoke 1 (this slice) |
| 2 | **#5826** Ship the deferred detector for the `external-target-referent-stored` drift class | M(4) | `core/deploy/deploy.sh` (Check 36, in place), `core/disciplines/knowledge-architecture.md`, `core/disciplines/memory-architecture.md`, `core/deploy/tests/test_check36_drift_classes.sh`, `release/references/how-to/memory-corpus-drift-audit.md`, `core/config/allowlists/script-execution-allowlist.txt`, `.github/workflows/install-tests.yml` | Engineering spoke 2 |

Raw Σ = 12 pts, inside the acceptable band for a two-member capability slice. **No merge, no split** — the members are a rule and its first instance, with a clear capability boundary.

### Capability Outcome Statement

**BEFORE:** a governed procedure could state a trigger in prose and carry no surface that acts when the trigger fires; whether it ran depended on whether the agent happened to recall it, and a skip left no record.
**AFTER:** a governed procedure that declares a trigger is admitted to the gate-coverage register, where it either names a runner whose predicate is recomputed on every `deploy.sh --check` run, or is recorded as a **named gap** carrying the observable that would close it.

---

## Change Description

### Outcome

Governed procedures in this platform state their trigger in prose — *"whenever you identify a gap"*, *"the method applies per proposed milestone"* — and, until now, nothing acted at the moment the trigger fired. Whether a procedure ran depended on whether the agent happened to recall it, and a skip left no trace. Three such procedures were each skipped in a single session; none produced any signal.

This release makes a declared trigger **detectable**. A governed procedure that names a condition and an act is now admitted to the platform's existing gate-coverage register, where it either names a runner whose check set is re-resolved on every `deploy.sh --check` run, or is recorded as a **named gap** carrying the observable that would close it. An unenforced obligation is still unenforced — but it is now *counted* rather than invisible, and a runner that quietly stops carrying its half of a procedure turns the check red instead of going unnoticed.

The change is deliberately small. The platform already owned this machine for verdict-shaped rules; what it lacked was an admission test that could see obligation-shaped ones. One alternative first limb was added to that test. **No code changed.**

### Issues resolved

| Issue | What landed |
|---|---|
| **#5825** | The `L1′` obligation limb, its disposition pair, its seven-item non-coverage statement, three seed register rows, the two evidence passages' `**Runner:**` labels, and the authoring-time checklist trigger. Marked as closed at Stage 13. |
| **#5826** | Not yet built — its slice lands on this same branch and PR in the next Engineering spoke. Marked as closed at Stage 13 alongside its sibling. |
| **Major-1** (operator disposition D-4) | `release-hub` Mode R group 6 gains composition-doctrine Steps 3 and 4. Not a separate ticket — an in-release fix locked into this slice at Collective Review. |

### Key decisions

- **A second admission FORM, not a fourth gate class** (ADR-162). The "three gate classes" count is held at three by construction, so nothing cascades. The falsifiable evidence that this was the right home is that the check required no code change to admit the new form.
- **An unenforceable obligation is registered, never downgraded.** Deleting an unrunnable verdict is a correction; deleting a correct instruction is a regression. That asymmetry is the whole reason class 3-O's second disposition differs from class 3-V's.
- **A tool-call-time hook was eliminated on a falsified premise, not on cost.** The sanctioned path and the bypassing path issue byte-identical tool calls. Recorded so the question stops being re-opened.
- **The mechanism's own limits ship with it.** Seven of them, stated in the standard rather than left implied — because a mechanism that hides its limits reproduces the failure class it exists to close. The last two are the population boundary itself (the class resolves over *registered* governed procedures) and the declared observable's reviewer-verified status; both were added at the AC-4 remediation (§ Deviation Log Δ17).

### Reversibility

**CHEAP** for this slice; **MODERATE** for the release as a whole, per the operator's scope-lock record. Everything here is additive prose plus three register rows and one sub-check pair, with no code path touched. `git revert -m 1 <merge-sha>` restores the prior state exactly and returns the register's pointer count to its previous value of four.

### Downstream impact

- **Authors of governed procedures** gain an obligation: a passage that names a trigger and an act now owes a `**Runner:**` label and a register row. The obligation attaches **on the change**, not retroactively — no existing document is swept, and no new frontmatter field exists.
- **Stage 5 design review** gains the second trigger form in check 4.9, including the named-gap pass path.
- **`release-hub` Mode R** readiness runs now report on the dependency half of composition, which they previously did not. Its `.skill` package is rebuilt in this PR.
- **The next Engineering spoke** adds the `runner-def:` pointer to the third register row when it ships the detector that makes it resolvable.

### Cross-references

The decision record is `core/ADRs/ADR-162-obligation-limb-is-a-form-not-a-fourth-gate-class.md`. The mechanism lives in `core/standards/gate-efficacy-standard.md` § *Scope boundary* and § *Runner resolution — class 3*. The authoring-time surface is `release/references/templates/design-review-checklist.md` check 4.9.

---

## Dependency Graph

Directional edges (`A ──▶ B` = B depends on A).

```
#5825 ──E1 coherence / sequencing (soft)──▶ #5826
#5826 ──E2 grading (soft, REVERSE)───────▶ #5825
#5825 ◀──E3 design-boundary (cross-milestone)──▶ #5286  [milestone #347, epic #5867]
```

**Hard blocking edges: none.** Both issue bodies state it: #5825 — *"the `external-target-referent-stored` detector, filed separately — it is one concrete instance of this gap and is independently shippable."* #5826 — *"Independently shippable — this one has a pre-specified target shape, that one does not."*

| # | Edge | Direction | Type | Consequence |
|---|------|-----------|------|-------------|
| **E1** | #5825 → #5826 | forward | coherence (sequencing) | #5825 states the class rule; #5826 ships its first instance. The instance should conform to the rule, so the rule is built first. |
| **E2** | #5826 → #5825 | **reverse** | grading | #5825's AC-5 (*"ADR-109's deferred detector is either delivered by this work or explicitly excluded from it"*) is not gradable from #5825's own outputs — it needs #5826's disposition to be known. |
| **E3** | #5825 ↔ #5286 (milestone #347) | cross-milestone | design-boundary | Both are children of epic #5867. **Settled at Stage 5 (AI-001) — a composition seam, not a duplication.** #5825 owns the DECLARATION and the AT-TRIGGER fire-or-record surface; #5286 owns the AT-CLOSE MEASUREMENT of newly-declared obligations. Neither relocation nor duplicate-treatment is indicated. |

**E1 and E2 point opposite ways on the same pair.** That is not a cycle — they are different relations (build-order vs grade-order) — but it is load-bearing: **#5825 cannot be fully graded until #5826 has landed.** D-C SINGLE resolves it for free (one branch, both issues present at grading time).

**The falsifying test for "#5825 and #5286 are the same machine."** A close-time population count structurally cannot observe a runtime skip: #5286's criterion measures corpus state at a release boundary; #5825's AC-2 concerns agent conduct at the moment of an act. #5286 cannot deliver #5825's AC-2, and #5825 cannot deliver #5286's per-release population number. **Two machines.**

---

## Implementation Sequence

Single branch, serial:

| Order | Issue | Why here |
|-------|-------|----------|
| 1 | **#5825** | Foundation. States the class rule and owns the D-Mechanism decision. Carries the Major-1 fix (D-4) and the combined ADR (D-5). |
| 2 | **#5826** | The rule's first instance. Target shape pre-specified by ADR-109 § 8, so its design surface is narrow. Builds on #5825's branch after it lands. |

**Sequence is preferred, not mandatory.** #5826's shape does not depend on the details of #5825's mechanism; if #5825 stalls, #5826 proceeds independently rather than blocking.

### Commit sequence within slice 1 (#5825)

| # | Commit | Contents |
|---|--------|----------|
| **0** | Engineering Commit 0 | This plan file, alone. Lands before any implementation commit. |
| **1** | `feat(gate-efficacy)` | `core/standards/gate-efficacy-standard.md` — the `L1′` admission form, the class-3-O disposition pair, the non-coverage statement, and 3 seed register rows. `release/references/templates/design-review-checklist.md` — check 4.9's second trigger form. |
| **2** | `feat(declarations)` | `core/CLAUDE.md.template` + `release/references/standards/bundle-composition-doctrine.md` — the two `**Runner:**` labels for Instances 1 and 2. |
| **3** | `fix(release-hub)` | `release/skills/release-hub/references/milestone-readiness-checklist.md` — Mode R group 6 gains doctrine Steps 3 + 4 (D-4 / Major-1), plus the `release-hub` `.skill` package rebuild + `.sha256` sidecar. |
| **4** | `docs(adr)` | The combined ADR (D-5), number allocated live against the mainline anchor at commit time. |
| **5** | `docs(plan)` | The plan's `## Change Description` section, per Stage-6 Phase C1. |

---

## Stage Applicability Matrix

**Verdict: all stages apply to both issues. Zero skips.** Stages 10 and 11 are skip-closed by the git-native path (branch protection + PR review are the environment-promotion and approval surfaces).

| Stage | #5825 | #5826 | Basis |
|-------|-------|-------|-------|
| 5 Solutioning | APPLY | APPLY | The `SKIP-where-trivial` bias does not fire — its precondition ("no design uncertainty surfaced") is false for both; each body defers its mechanism to Stage 5 by name. Superseded anyway by the `novel` re-classification, whose bias is ALL. |
| 6 Engineering | APPLY | APPLY | Both produce shipped surfaces. |
| 7 Dev Testing | APPLY | APPLY | Both have functional impact — a mechanism that must fire, and a detector that must discriminate FLAG from CLEAN. |
| 8 QA / Acceptance | APPLY | APPLY | Both carry gradable per-criterion ACs (5 and 6 respectively). |
| 9 Plan Review | APPLY | APPLY | Release-scoped; depth **Deep** per the `novel` class. |
| 10 Environment promotion | skip-closed | skip-closed | Git-native: the release branch IS the environment, and branch protection is the promotion gate. No separate environment exists to promote into. |
| 11 Approval | skip-closed | skip-closed | Git-native: PR review at Stage 9 IS the approval. No separate approval surface exists. |
| 12 Execute | APPLY | APPLY | Merge + Deployment Log. **No version claim** — version-less. |
| 13 Close | APPLY | APPLY | Standard close path; both members are marked as closed at Stage 13 on the single merge. |

---

## Contention Map

**In-bundle file contention: exactly one file.**

| File | #5825 | #5826 | Contention |
|------|-------|-------|------------|
| `core/disciplines/knowledge-architecture.md` | **cites, does not edit** — Instance 3's register row points at the drift-class home | edits § 7 (class table, count five → six, sixth class row) | **RESOLVED — zero shared write paths.** #5826 is the sole writer. |
| `core/standards/gate-efficacy-standard.md` | sole writer | — | none |
| `core/deploy/deploy.sh` | **NO CHANGE** — Check 62 needs no code change | Check 36 block, in place | none (single writer) |
| `release/skills/release-hub/references/milestone-readiness-checklist.md` | sole writer (D-4) | — | none |
| `core/ADRs/ADR-109-external-target-knowledge-scope.md` | cites | cites | **none — read-only for both.** An immutable decision record; its § 8 forward-reference resolves without an edit. |
| `core/config/operator.toml.template` | — | read-only reference (arm 2's whitelist subject) | none |

**Cross-release contention on `core/deploy/deploy.sh` — downgraded, with evidence.** The live renumber churn on that file is **tail-allocation** contention (two releases racing for the next free check number; Checks 70/71/72 sit at lines 12518 / 12627 / 12757). #5826 edits Check 36 **in place at line 9459** and **claims no new check number**, so it is structurally immune to the numbering collision, with ~3,000 lines of hunk separation. **Revised severity: numbering NONE, textual LOW.**

---

## Cross-PR Overlap Audit

### Baseline SHA

`e19a9d30682abefac51cca1ff8aa0ebbf8708593` — `origin/main` at Stage-4 audit start, re-verified at Engineering Commit 0 (`git fetch origin main`; `HEAD == origin/main == FETCH_HEAD`).

### In-Flight Release Roster

**Measured at:** `d40de588` · 2026-08-28 · **Population: n=0 siblings in flight**

Recorded explicitly rather than omitted, per audit-baseline discipline — a default-to-zero over a transiently-empty population is not load-bearing without its pinned baseline. Derivation:

- Open PRs with a `release/*` head: **0**. Instrument control: `gh pr list --state closed --limit 3` returned 3 rows, so the zero-open reading is a real absence rather than a dead instrument.
- Remote `release/*` heads with no open PR: **1** — `release/operational-folder-enforcement-migration` @ `9dcb960f`. Tested with `git merge-base --is-ancestor`: it **is an ancestor of `origin/main`**, i.e. already merged. Excluded with its reason rather than silently dropped.
- **Net in-flight: 0.** No sibling declares a rename, relocate, or delete, because there is no sibling.

**This roster is a pinned measurement and carries no verdict.** Stage 9 Phase A6.6 re-measures fresh pre-GO and renders the `CONTENTION-*` verdict.

---

## Risk Register

| ID | Class | Sev | Risk | Owner | Mitigation | Reversibility |
|----|-------|-----|------|-------|------------|---------------|
| **R1** | Blast radius | **HIGH → CLOSED** | The five → six drift-class move asserts the literal "five" at 11 sites across 5 files; #5826's Affected Files named 2 of the 5. One unnamed surface (`memory-corpus-drift-audit.md:133`) states that the manual audit and Check 36 *"agree by construction"* — a partial update silently falsifies that invariant. | Stage 5 → Eng 2 | **Closed at Stage 4:** the File Change Matrix below carries all five files. Stage 7 runs `test_check36_drift_classes.sh` as a gating check, not an optional one. | CHEAP |
| **R2** | Scope | **HIGH → CLOSED** | #5825's scope was unbounded until the mechanism was decided; its 8-pt estimate sized the decision, not the sweep the decision might authorize. | Stage 5 | **Closed at Stage 5 (AI-002): the sweep collapses to zero.** Class 3's obligation already attaches *"on the change, not on the corpus: no scan and no allowlist"*, and the register is *"never required to be exhaustive in one pass."* No `trigger:` field is added to any document; no existing passage is rewritten except the two that are themselves the evidence instances. | CHEAP |
| **R3** | Cross-milestone | **MED-HIGH → CLOSED** | #5825's conformance half and #5286's Gate-13 criterion are plausibly the same machine, specified in two milestones reaching Stage 5 independently. | Stage 5 entry | **Closed at Stage 5 (AI-001):** a composition seam, not a duplication. Ownership split stated in § Dependency Graph E3. Coordination note only — no edit to #5286 from this release. | CHEAP |
| **R4** | Coherence | **MED** | The shipped detector may not satisfy the rule its sibling states. Check 36 is warn-mode and SKIPs entirely when `~/.claude/memory` is absent (fresh install / CI) — exactly where the observed violation lived. | Stage 9 QC3.5 | Graded by **CIAC-1** and **CIAC-2**. #5825 deliberately defines "detectable signal" as *a named, resolvable runner whose verdict is observable and whose resolution is recomputed* — a definition Check 36 satisfies — precisely so #5826 stays conformant rather than being defined out. | CHEAP |
| **R5** | Contention | **LOW** | `core/deploy/deploy.sh` cross-release textual contention. | Stage 6 | ~3,000 lines of hunk separation; no new check number claimed; in-flight sibling population n=0 at `d40de588`. Re-check at Stage 9 Phase A6.6 — the roster is a pinned prior, not a durable verdict. | CHEAP |
| **R6** | Anchor | **LOW** | `{#drift-classes}` at `knowledge-architecture.md:313` is an **explicitly declared** anchor. Converting it to auto-derived while retitling "five" → "six" breaks the inbound reference at `:358`. | Eng 2 | Preserve the explicit `{#drift-classes}` anchor **verbatim**. Covered by CIAC-3's anchor-resolution arm. | CHEAP |
| **R7** | Teeth | **MED** | The mechanism inherits deploy-time-only, warn-mode teeth. Check 62 declares `advisory / deploy-time-only`; Requirement (b′) bars `required` while no CI mirror exists; `deploy-check-ci.yml`'s required subset is one member (Check 38). AC-2's "detectable signal" is real but not pre-merge. | operator | **Accepted as a stated residual.** Pre-existing debt this release inherits and does not worsen. Stated in the standard's own non-coverage clause rather than hidden. Do not attempt a CI mirror here — that belongs to `deploy-check-ci.yml`'s own back-fill effort. | n/a |
| **R8** | Anchor grammar | **MED** | Check 62's `runner-def:` anchor is captured by the character class `[A-Za-z0-9._-]`, which **stops at the first space**. A space-bearing anchor silently truncates to its first word and asserts a weaker predicate than the author wrote — a CLEAN verdict over an assertion nobody made. The standard states no anchor-form rule. | Eng 1 | **Mitigated in this release by authoring space-free anchors only**, each currently absent from its runner-definition file so its presence is a real assertion. **The standard is NOT edited for it** — stating an anchor-form rule is scope beyond the lock; routed as a follow-on (§ Findings F-1). | CHEAP |

### Rollback strategy

Single release branch, single PR, single merge (D-C SINGLE) → `git revert -m 1 <merge-sha>` restores prior state wholesale.

| Surface | Rollback | Tier |
|---------|----------|------|
| `gate-efficacy-standard.md` admission form + 3 register rows | `git revert` — additive limb; Check 62's pointer count returns to its prior value (4) | **CHEAP** |
| `design-review-checklist.md` check 4.9 | `git revert` — trigger-form extension only; Section 4's conjunction arity unchanged | **CHEAP** |
| Two `**Runner:**` passage labels (`CLAUDE.md.template`, `bundle-composition-doctrine.md`) | `git revert` — additive labels; no obligation text reworded | **CHEAP** |
| Mode R group 6 Steps 3 + 4 (D-4) | `git revert` — one table cell plus one line, plus the package rebuild | **CHEAP** |
| The combined ADR | `git revert` — a new file | **CHEAP** |
| #5826's Check 36 sixth class + class-table edits | `git revert` restores the five-class table; nothing downstream depends on the sixth | **CHEAP** |
| **Aggregate** | | **MODERATE** — the release inherits the stricter of the two, and the operator recorded MODERATE / HIGH at the D-3 scope lock. **#5825's own tier improved MODERATE → CHEAP** once the sweep collapsed (§ Deviation Log Δ1). |

---

## Cross-Issue Acceptance Criteria

Three. All span both members, all gradable on the merged PR at Stage 9 QC3.5.

**CIAC-1's grading predicate is settled by operator ruling D-6 and is stated here so Stage 9 grades against a written predicate rather than re-deriving one.** Stage 9 QC3.5 grades CIAC-1 against: *both mechanisms reach the auto-memory store at deploy-check time on the operator machine, and neither reaches it in CI* — stated **per-mechanism (subject-scoped)**. The subject-scoping is **ratified, not tolerated**: it is what makes the converged answer legible instead of collapsing two mechanisms into one ambiguous sentence. The two Stage-5 statements were never opposite answers to one question — #5826 answers the reach question directly, while #5825 makes a *definitional* choice about what counts as a detectable signal, which is a claim about the predicate rather than about reach. On reach itself they converge, and both are CI-blind for the same structural reason: the store is not checked out in CI and `deploy.sh --check` is not invoked there. **No re-edit of the shipped statements is owed.** Slice 1's shipped statement already conforms (§ Non-coverage item 2 names its own mechanism explicitly). **Slice 2's grading surface is the `core/deploy/deploy.sh` Check 36 header block, and only that block** — its `NOT reached` enumeration names the store as arm 1's root and names deploy-check invocation as the trigger, and its `Degrades gracefully: SKIP when ~/.claude/memory/ is absent (fresh install / CI …)` clause names CI as the case in which the check does not run at all. That block is the one surface carrying **both** limbs of the D-6 answer, so it is where Stage 9 QC3.5 grades CIAC-1's slice-2 half. **The earlier pointer at `knowledge-architecture.md` § 7.1 is withdrawn** — measured over that whole subsection, it carries the memory store (5 occurrences) and deploy-check time (1) and **zero** occurrences of CI: it states the *temporal* residual (a violation authored today stays undetected until the next `./deploy.sh --check`) and never the *surface* residual, so grading against it would leave D-6's second limb unstated. This is a **pointer correction, not a content gap** — AC-5 is met on the `deploy.sh` header as delivered, and § 7.1 is deliberately **not** amended, because a second home for a fact `deploy.sh` already states in full is the shadow copy the corpus's single-home discipline forbids.

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#5825 × #5826 on the non-coverage declarations):** Both issues ship an explicit non-coverage statement, both name the auto-memory store (`~/.claude/memory`), and the two give a **consistent** answer on whether that surface is reached — consistent meaning each statement names the mechanism it is about, so that "#5825's register-and-Check-62 mechanism does not reach the store" and "#5826's Check 36 reads the store at deploy time on an operator machine and cannot in CI, where it does not exist" are read as the two non-overlapping facts they are, rather than as a contradiction. *Method:* `git diff origin/main...HEAD -- '*.md' '*.sh' | grep -n 'claude/memory'` · control: the same instrument against the same target for `runner-def` → non-zero, so a zero on the subject is a real absence and not an unresolvable diff range. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5825 × #5826 on the firing-surface mechanism):** The ADR-109 detector shipped by #5826 is **either** registered with the firing-surface mechanism #5825 establishes, **or** recorded by that mechanism as explicitly out of its declared population with a stated reason. **Affirmative branch taken:** #5825 ships the class-3-O register row for the `external-target-referent-stored` drift class, naming `deploy.sh --check` Check 36 as its enforcing gate. *Method:* read the gate-coverage register in `core/standards/gate-efficacy-standard.md` for the `external-target-referent-stored` row and confirm it names Check 36 and describes a posture the merged PR delivers. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#5825 × #5826 on ADR-109 § 8's forward reference):** #5825's shipped disposition of its own AC-5 — "delivered by this work" or "explicitly excluded from it" — is consistent with #5826's merged state in the same PR, and the `{#drift-classes}` anchor still resolves from every inbound reference after the heading retitle. **#5825's disposition: explicitly excluded from #5825 and registered by it; delivered by #5826 in the same PR.** *Method:* `python3 -c "import re; t=open('core/disciplines/knowledge-architecture.md').read(); print('anchor:', bool(re.search(r'\{#drift-classes\}', t)), 'six:', len(re.findall(r'six drift classes', t)), 'five:', len(re.findall(r'five drift classes', t)))"` — expect `anchor: True`, `six > 0`, `five == 0` in the class-table context. **Null arm carries its control:** the `five == 0` expectation is paired with the same instrument against the same target returning **non-zero for `six`** — a zero on both means the file was not read, not that the transition landed. *Graded at Stage 9 QC3.5 on the merged PR.*

---

## File Change Matrix

Machine-readable path list — one path per line, `<VERB>  <path>`. Intent tokens: `add` (new file) · `edit` (modify).

```
# ── slice 1 — #5825 (+ Major-1 D-4, + combined ADR D-5) ──
add   release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md
edit  core/standards/gate-efficacy-standard.md
edit  release/references/templates/design-review-checklist.md
edit  core/CLAUDE.md.template
edit  release/references/standards/bundle-composition-doctrine.md
edit  release/skills/release-hub/references/milestone-readiness-checklist.md
edit  packages/release-hub.skill
edit  packages/release-hub.skill.sha256
# ── slice 2 — #5826 ──
edit  core/deploy/deploy.sh
edit  core/disciplines/knowledge-architecture.md
edit  core/disciplines/memory-architecture.md
edit  core/deploy/tests/test_check36_drift_classes.sh
edit  release/references/how-to/memory-corpus-drift-audit.md
edit  core/config/allowlists/script-execution-allowlist.txt
edit  .github/workflows/install-tests.yml
# ── scope refinement, operator ruling D-7 — belongs to neither card's subject matter ──
edit  release/tools/verify-release-plan.sh
# ── Dev-Testing touch-up, operator ruling D-8 — Stage-6-class rework, no issue added ──
edit  core/disciplines/decision-discipline.md
edit  core/standards/regression-checks.md
edit  packages/pmo-skill-editor.skill
edit  packages/pmo-skill-editor.skill.sha256
```

**The ADR row is deliberately outside the fenced block above and is declared here instead, with its path resolved at commit time.** ADR numbering is a global sequence spanning `core/ADRs/` and `release/ADRs/`, allocated against the mainline anchor at commit time and never reserved ahead of a sibling's unmerged claim — so a literal path authored at Commit 0 would be a pre-reservation, which the numbering discipline forbids. The delivered path is recorded in § Deviation Log Δ6 once allocated.

| Path | Intent | Issue | Note |
|------|--------|-------|------|
| `release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md` | add | release | **Flat in `plans/`** — version-less releases are not version-keyed, so there is no `v<MAJOR>/` home and no Stage-12 `git mv`. Workspace-rooted links only. |
| `core/standards/gate-efficacy-standard.md` | edit | #5825 | § *Scope boundary*: "three gate classes" preserved **verbatim**; the class-3 admission paragraph gains the `L1′` obligation limb, the stated-trigger admission bar, and the precedence rule. § *Runner resolution — class 3*: the class-3-O disposition pair (**wire it** / **register as a named gap with a declared observable**) plus the rationale for its divergence from 3-V, and the explicit non-coverage statement. § *Gate-coverage register*: **3 rows appended** (Instances 1–3). |
| `release/references/templates/design-review-checklist.md` | edit | #5825 | Check **4.9**: the two-limb trigger gains `L1′ ∧ L2` = class 3-O; the 3-O disposition pair is named in the check body and in the `**Fail action:**` sentence; the `**Pass criterion:**` gains the 3-O clause. **No new checklist member** — Section 4's conjunction arity is unchanged. |
| `core/CLAUDE.md.template` | edit | #5825 | § Continuous Improvement, the auto-logging rule: append the `**Runner:**` label recording that no runner is resolvable, pointing at the register row (Instance 2). **Surgical** — the rule's obligation text is not reworded, restructured, or softened. |
| `release/references/standards/bundle-composition-doctrine.md` | edit | #5825 | § 3 *The 7-Step Method*, opening paragraph: append the `**Runner:**` label naming `release-hub` Mode R group 6 (Instance 1). The `runner-def:` pointer lives in the register row alone, per the shipped convention (§ Deviation Log Δ10). **No step text is edited.** |
| `release/skills/release-hub/references/milestone-readiness-checklist.md` | edit | #5825 (D-4 / Major-1) | Mode R group 6's Sub-checks cell gains doctrine **Step 3** (backward dep walk to discover *unbundled* prerequisites) and **Step 4** (older-milestone prerequisite check), plus the one-line composition sentence naming which doctrine steps group 6 composes. **Skill-adjacent reference file** → the `pmo-skill-editor` discipline applies, and the `.skill` package rebuilds. |
| `packages/release-hub.skill` + `.sha256` | edit | #5825 | **Mandatory companion** of the row above. `release-hub` is a rostered skill; a `references/` edit without a package rebuild fails `deploy.sh --check` Check 7 and the pre-merge `skill-package-freshness` CI gate. |
| `core/deploy/deploy.sh` | edit | #5826 | Check 36 block, **in place at ~L9459**. Sixth drift class, three arms. **No new check number claimed** — this is what keeps the mainline renumber edge latent. |
| `core/disciplines/knowledge-architecture.md` | edit | #5826 | Class table five → six; retitle the `:313` heading; **preserve the `{#drift-classes}` anchor verbatim**; reconcile the `:358` *"Detector deferred / not one of the five"* paragraph. |
| `core/disciplines/memory-architecture.md` | edit | #5826 | Two stale "five drift classes" cross-refs at `:24` and `:114`. **Undeclared by #5826's own Affected Files** — carried here per R1. |
| `core/deploy/tests/test_check36_drift_classes.sh` | edit | #5826 | Sixth-class FLAG + CLEAN fixtures (sanctioned `identifier` = CLEAN; observed violation = FLAG). **Undeclared by #5826's own Affected Files** — carried here per R1. |
| `release/references/how-to/memory-corpus-drift-audit.md` | edit | #5826 | H2 at `:22` + the *"agree by construction"* invariant at `:133`. **Undeclared by #5826's own Affected Files** — carried here per R1. |
| `core/config/allowlists/script-execution-allowlist.txt` | edit | #5826 | Entry for `core/deploy/tests/test_check36_drift_classes.sh`. **Locked in at D-3** — the fixture is 0 of 281 entries today, so `BLOCK-DESTRUCTIVE-022` fires on this card's own test file and Stage 6/7 cannot run it. |
| `.github/workflows/install-tests.yml` | edit | #5826 | L484–489 carry a "two new Check 36 detectors" enumeration that goes stale on a sixth class. **Locked in at D-3 as the 6th file.** |
| `release/tools/verify-release-plan.sh` | edit | scope refinement (D-7) | **Operator ruling D-7 — F-6 fixed in-release.** The Verification-Plan table parser silently dropped any data row whose cells used the vocabulary of the schema's own column names; header detection becomes positional (first row of a table block) rather than keyword-based. Its own distinct commit, because it belongs to neither card's subject matter. **Not a scope-lock override** — see § Deviation Log Δ13. |
| `core/disciplines/decision-discipline.md` | edit | D-8 touch-up | **Escape found at Stage 7 DT (m-1).** The G8 falsification-pair passage describes its own admission as *"that class's two-limb admission test"* — a live first-order referrer, not edited by slice 1, whose classification stays correct (a REJECT verdict → class 3-V) but whose description of the class's admission *structure* went stale when `L1′` landed. Reworded to name the **verdict-limb** form and its sibling obligation limb. **One sentence; no predicate, verdict, or runner claim is touched.** This site also **falsifies the Stage-5 blast-radius claim** that the only live admission-test consumers were `design-review-checklist.md` and `regression-checks.md` — see § Deviation Log Δ16. |
| `core/standards/regression-checks.md` | edit | D-8 touch-up | **Promoted out of the read-only table below.** § Category 7 carried two claims that went stale when the 3-O rows landed: a **false universal** (*"each class-3 row declares `runner-def:` pointing at this file"* — of the six class-3 rows, three point here, two point elsewhere and one correctly carries none) and an **"Applies to" scope that silently widened** to three further documents while the operative Trigger table did not, which — against the same section's *"a check that was not run is a FAIL"* — handed a literal reader a required-but-unrunnable check. Both scoped to the class-3-V / Mode-C population, with the scope read off the trigger table. **Documentation-only:** the sole executable reference to `RCP-*` is a comment at `deploy.sh:1949`, so no gate's behaviour changes. This is the same sentence-class Stage 6 correctly reconciled twice *inside* the standard (F-3); the mirror on the other end of the pointer was not swept. |
| `packages/pmo-skill-editor.skill` + `.sha256` | edit | D-8 touch-up | **Mandatory companion of the row above, and not anticipated by the touch-up brief.** `core/standards/regression-checks.md` is a TEMPLATE_SYNC_MAP canonical **injected** into the `pmo-skill-editor` package at build time — the tree holds exactly one copy of that file, and the package embeds it as `pmo-skill-editor/references/regression-checks.md`. Editing the canonical therefore stales the committed package exactly as a `references/` edit does, which is the same relationship `packages/release-hub.skill` has to `milestone-readiness-checklist.md`. Verified by content rather than inferred: the packaged member was **byte-identical** to the canonical at `9a06be99` and **differed** at HEAD, with an untouched member (`SKILL.md`) matching its source as the specificity control. Rebuilt via `build-skill-packages.sh pmo-skill-editor`; `deploy.sh --check-package-freshness` moves from `FAIL: pmo-skill-editor — source content changed since build` to `55 rostered skill package(s) content-fresh — OK`, exit 0. |
| `core/standards/gate-efficacy-standard.md` | edit | D-8 touch-up (m-3) | **Third touch.** The Instance-1 register row anchored on doctrine **Step 3** only, so deleting Step 4's `older-milestone-prerequisite-check` sub-check left Check 62 reporting `CLEAN` — half of the D-4 / Major-1 fix unenforced. The row gains a **second `runner-def:` pointer** on Step 4's anchor, and its falsification cell now asserts both directions. Check 62 extracts pointers globally, so **no code change**; the pointer count moves 6 → 7 and V-1 moves with it. Anchor is space-free per F-1 — capture verified equal to intent against the shipped extraction regex. |
| `core/ADRs/ADR-162-obligation-limb-is-a-form-not-a-fourth-gate-class.md` | edit | D-8 touch-up (m-4) | **Declared here rather than in the fenced block, per the ADR-path convention above.** `source_observations` recorded *"five after this change"*, a slice-1-scoped count read at merge as a merge-time one. Corrected to state the slice count and the merge count, the latter now **seven** because the same touch-up adds the Step-4 pointer. Frontmatter re-parsed as valid YAML after the edit. |
| `core/standards/gate-efficacy-standard.md` | edit | #5826 (CIAC-2) | **Second touch, by slice 2.** The class-3-O register row for `external-target-referent-stored` shipped as a named gap whose own text says the `runner-def:` pointer *"is added by the change that ships the detector"*. That change is slice 2, so the row now carries `runner-def: core/deploy/deploy.sh::declared-live-read-with-stored-value` — the CIAC-2 affirmative branch. Nothing else in the file is touched. See § Deviation Log Δ12. |

#### Read-only inputs (NOT EDITED — excluded from the delivery obligation set)

| Path | Why read | Issue |
|------|----------|-------|
| `core/ADRs/ADR-109-external-target-knowledge-scope.md` | READ — immutable decision record; its § 8 forward-reference resolves without an edit | both |
| `core/config/operator.toml.template` | READ — `[trackers.<id>].identifier` is the one sanctioned stored item; #5826's arm 2 must **not** flag it | #5826 |
| `core/hooks/**` | NOT EDITED — Candidate A (a `PreToolUse` hook) was eliminated on a falsified premise; see § Operator Decisions § D-Mechanism | #5825 |
| `core/deploy/deploy.sh` Check 62 / `_rr_compute_verdict()` | READ — **Check 62 needs no code change**; the computation was already general over `runner-def:` pointers. Editing it would be a scope deviation | #5825 |
| `core/standards/regression-checks.md` | **No longer read-only — PROMOTED to the delivery matrix above by the D-8 touch-up.** It was declared read-only on the reasoning that no *existing* row changes; what Stage 7 DT found is that the file's own § Category 7 makes universal claims **about** the register, and those claims went stale when the new rows landed. Row retained here so the transition is legible rather than silent. | #5825 → D-8 |

---

## Verification Plan

### AC baseline

Per-issue acceptance-criterion counts as read at plan time, with the commit the read was taken against. The ordinal in the `AC` column is positional, so this baseline is what makes ordinal drift countable rather than silent. **The baseline is a pinned measurement and carries no verdict.**

| Issue | AC count at plan time | Read at |
|-------|----------------------|---------|
| #5825 | **5** | `e19a9d30682abefac51cca1ff8aa0ebbf8708593` |
| #5826 | **6** | `e19a9d30682abefac51cca1ff8aa0ebbf8708593` |

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|--------------------|-----------------|
| #5825 | AC-1 | `grep -c 'class 3-O' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'class 3-V'` → non-zero, so a zero on the subject is a real absence rather than an unreadable file | Three register rows present, one per Evidence instance; each names its admission form, its runner-or-named-gap, and its disposition |
| #5825 | AC-2 | Re-resolve every pointer the register declares — the Check-62 `_rr_compute_verdict` predicate, run over the edited standard rather than as a full `--check` sweep: `grep -c 'runner-def:' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'runner-def-never-present'` → zero | `CLEAN` with a pointer count of **7** — four pre-existing, plus Instance 1's **two** runner pointers (one per doctrine step the row names, Δ16), plus Instance 3's, which slice 2 adds when it ships the detector (Δ9 → Δ12). Instance 2 remains a named gap and correctly carries none: it has no resolvable runner at all |
| #5825 | AC-3 | `grep -c 'L1′' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'L1 — verdict limb'` → non-zero, so a zero on the subject is a real absence rather than an unreadable file | `L1′` present; the register row is data and Check 62 is a computation over it; no new prose instruction to the agent is added anywhere in the diff |
| #5825 | AC-4 | Read the standard's non-coverage clause and confirm it enumerates what the mechanism cannot detect: `grep -c 'does NOT detect' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'Runner resolution'` → non-zero | Seven numbered non-coverage items present — the runtime-skip limit, the auto-memory-store limit, the payload-indistinguishability limit, the R1-granularity (anchor-presence, not predicate-completeness) limit, the advisory deploy-time-only limit, the never-registered-obligation limit (the population boundary: the class resolves over *registered* governed procedures), and the declared-observable limit (required in the row's form, reviewer-verified rather than machine-checked). Items 6 and 7 were added at the AC-4 remediation (D-9); items 1–5 are unchanged and un-renumbered, since register rows cite them by number |
| #5825 | AC-5 | `grep -c 'external-target-referent-stored' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'NAMED GAP'` → non-zero | The row is present, names `deploy.sh --check` Check 36 as its intended enforcing gate, and records the disposition *explicitly excluded from this card and registered by it*; the detector itself ships in the sibling slice on this same branch |
| #5826 | AC-1 | `grep -c 'external-target-referent-stored (declared-live-read-with-stored-value)' core/deploy/deploy.sh` · control arm, same instrument, same target: `grep -c 'memory-corpus-tie-drift'` → non-zero, so a zero on the subject is a real absence rather than an unreadable file | The arm-1 emitter is present, so a surface declaring a live-read obligation and holding one of its own declared referent kinds as a value is detected. The behavioural proof — the flag/clean fixture pair and its must-trip control — is V-7 |
| #5826 | AC-2 | `grep -c 'six drift classes' core/disciplines/knowledge-architecture.md` · control arm, same instrument, same target: `grep -c 'drift-classes'` → non-zero | The count reads six in the class table and in the Check 36 header enumeration, the `external-target-referent-stored` row is present, and the `{#drift-classes}` anchor is preserved verbatim |
| #5826 | AC-3 | `grep -c 'key != "identifier"' core/deploy/deploy.sh` · control arm, same instrument, same target: `grep -c 'unsanctioned-tracker-key'` → non-zero | The sanctioned `[trackers.<id>].identifier` address is on arm 2's whitelist, so it cannot flag — a positive structural exemption rather than a heuristic carve-out. The clean/flag `operator.toml` fixture pair in V-7 is the behavioural proof |
| #5826 | AC-4 | `grep -c 'DECLARATION-SCOPED, not content-scoped' core/deploy/deploy.sh` · control arm, same instrument, same target: `grep -c 'external-target-referent-stored'` → non-zero | The population is declaration-scoped, so an operator-side practice statement that merely names a target and declares nothing is never evaluated. That outcome is reported as distinct from evaluated-and-clean, not folded into it |
| #5826 | AC-5 | `grep -c 'NOT reached, stated rather than discovered later' core/deploy/deploy.sh` · control arm, same instrument, same target: `grep -c 'Degrades gracefully'` → non-zero | The non-coverage enumeration is present and states that the auto-memory store IS reached at deploy-check time on an operator machine and is structurally unreachable in CI, then names what is not reached: write time, an undeclared cache, operator config outside `[trackers.*]`, and the codified corpus |
| #5826 | AC-6 | `grep -c 'c6_flag_pre_reconciliation' core/deploy/tests/test_check36_drift_classes.sh` · control arm, same instrument, same target: `grep -c 'assert_emits'` → non-zero | The observed violation ships as the flagging fixture in its pre-reconciliation form — declaring the obligation and holding the same kinds as values — alongside its reconciled twin as a clean fixture and a must-trip control |

---

## Release-Scoped Verification

Held in its own H2, deliberately. The plan verifier extracts everything under `## Verification Plan` and parses every markdown table it finds there as per-issue check rows, so a second table with different columns living inside that section is read at the per-issue column indices and emits spurious records. Promoting this table out of the section is the authoring fix; the column names below are also deliberately distinct from the per-issue table's.

| # | Release-scoped check | Invocation | Result required |
|---|----------------------|-----------|-----------------|
| **V-1** | Check 62 resolves | The `_rr_compute_verdict` computation over the edited register | `CLEAN`, pointer count **7** — four pre-existing, plus Instance 1's Step-3 anchor (slice 1), plus Instance 3's (slice 2, the CIAC-2 affirmative branch), plus Instance 1's **Step-4** anchor (the D-8 touch-up, Δ16). The count moved 5 → 6 at Δ12 and 6 → 7 at Δ16; a run reporting 6 means the Step-4 anchor did not land, and a run reporting 5 means Instance 3's pointer did not either |
| **V-7** | The Class-6 detector discriminates | `bash core/deploy/tests/test_check36_drift_classes.sh` — six Class-6 assertions plus the cardinality guard | Every assertion passes. The four arm-1 outcomes are asserted as **four distinguishable verdicts** (not-in-population / unscoped / clean / flag), never collapsed to flag-vs-clean, which a predicate finding no declarations at all would satisfy vacuously |
| **V-8** | The fixture guard forces a fixture update | The cardinality assertion in that same suite, run against this branch and against `origin/main` | `six` here and `five` at `origin/main`, so a class added without fixturing it fails the suite. An unreadable enumeration fails closed, never passes silently |
| **V-9** | The plan verifier recovers the rows F-6 dropped | Parse this plan's Verification Plan with the `origin/main` parser and with the fixed one; diff the row sets | The two rows drop under the old parser and parse under the fixed one, with a sensitivity arm (rows never at risk parse under both) and a specificity arm (a malformed row still ERRORs under both) |
| **V-2** | ADR numbering contiguity | `python3 release/tools/check-adr-numbers.py` | Zero duplicates, zero gaps across both ADR homes |
| **V-3** | Plan conformance | `bash release/tools/verify-release-plan.sh release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md` | Every family PASS or a named SKIP. The `release-version-stamp` element is **correctly absent** — it fires only when a version-stamp token is present, and a version-less plan emits none |
| **V-4** | Doc-link integrity | `deploy.sh --check` Check 14 over the modified `.md` files | Every internal markdown link in a modified file resolves |
| **V-5** | Skill-package freshness | `deploy.sh --check` Check 7 after the `release-hub` rebuild | `FRESH` — package content-hash matches source |
| **V-6** | Register-row anchor liveness | For each new `runner-def: <path>::<anchor>`, assert the anchor is **absent** from the runner-definition file at `origin/main` and **present** after the edit | Absent-before / present-after for both new anchors, with a sensitivity arm (a token present in both) and a specificity arm (a token present in neither) |

**Anti-vacuity note on V-6.** A pointer whose anchor was already present before the change asserts nothing the release delivered; the absent-before arm is what distinguishes a real assertion from a pointer aimed at pre-existing text.

---

## Delivery Strategy

- **One branch, one PR, one merge** (D-C SINGLE). #5826's slice lands on this same branch and PR in the next Engineering spoke.
- **P0 fully-serial.** No force-push on the shared branch under multi-chip activity.
- **Sub-task container: PR-body checklist.** Slice 1 decomposes into 5 file-level units plus the 3 always-generated special sub-tasks (sync / plan-update / verification) — the threshold predicate selects the checklist container for the doc-and-governance-only, single-logical-unit shape, and the checklist rows are the decomposition record.
- **Commit messages reference their source issue.** Close-family verbs bound to an issue number appear only in the PR body's dedicated Issue References block — never in a commit message, a plan section, or a PR narrative section.

---

## Quota Budget

**Verdict:** **PASS** (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **2** · Stage 7: **2** · Stage 8: **2**
**Per-spoke cost estimate:** ordinal size-bucket band (no telemetry medians available; the cutover conditions — n≥3, rMAD≤0.50, confidence≥MEDIUM — are met for neither bucket). #5825 `size:L` → **moderate–high**; #5826 `size:M` → **low–moderate**. Source: `quota-budget-protocol.md` § 5 heuristic.
**Assumed/stated remaining usage-window envelope:** not operator-stated at hub start → **conservative default assumed**.
**Estimated cumulative draw % (worst parallel batch):** worst batch = **2 spokes** (1×L + 1×M), the smallest non-trivial parallel batch the pipeline can produce. Estimated cumulative draw **well under 50 %** of a conservative envelope → **PASS band**.
**Routing:** **PASS — proceed parallel; no warning required in plan.**
**Confidence:** `[CALIBRATE-AFTER-3]` **MEDIUM** — bands and cumulative-draw budget are provisional.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time.

---

## Operator Decisions (recorded)

### D-Version — RECORDED DETERMINATION (rule-determined; not an operator gate)

- **Determination:** **version-less / theme-named** — the milestone title is slug-only, so no version key is claimed. Bump-class / next-free: **N/A**. **No tag at Stage 12.**
- **Consequence:** the Commit-0 version re-verify and the Stage-12 atomic claim are **INAPPLICABLE**. This plan emits **no `{{RELEASE_VERSION}}` token** and `release/tools/claim-version.sh --verify-stamp` is **not run** — there is no version slot to contend for and no stamp manifest to assert. The plan file therefore stays **flat in `plans/`** and is never `git mv`'d into a `v<MAJOR>/` subdirectory.
- **Reversibility / Confidence:** CHEAP / HIGH.

### D-ReleaseClass — SETTLED: `novel` (re-classified from `routine`)

- **Value:** **`novel`**, re-classified at Stage 4 Plan Review (2026-08-28). Both the prior and current values are recorded because the change is load-bearing on Stage 9 depth.
- **Why `routine` was wrong, tested literally against the class enum:** (a) *all issues P3/P4 and size:S/M* — **NO**, #5825 is P2 and `size:L`; (b) *all change-spec files have ≥3 prior release touches* — **NO**, not assertible while the mechanism was undecided; (c) *zero new files added* — **NO**, the candidate directions included a new hook and a new check; (d) *zero new D-class decisions in the release plan* — **NO**, both bodies defer a mechanism decision to Stage 5 by name. **`routine` fires nothing.**
- **Why `novel`:** trigger (b) fires — ≥1 D-class decision in the release plan (D-Mechanism for #5825; D-DetectorScope for #5826) — and (c) very likely, a Stage-5 ADR. `cross-cutting` does not fire: no `pipeline/stage-*.md` files; fewer than 3 of the 6 rule-defining surfaces; and a 2-node bundle admits at most 1 in-bundle compositional edge against a ≥3 requirement. Multi-trigger resolution (`cross-cutting` > `novel` > `routine`) lands on **`novel`**.
- **Differentiation posture:** engagement density **Standard** (from Light) · Stage 9 review depth **Deep** (from Standard) · Stage 5 activation bias **ALL** (from SKIP-where-trivial) · Stage 13 outcome-window 30-day (unchanged).
- **Reversibility / Confidence:** CHEAP / HIGH — cheaper-to-stricter adds ceremony, invalidates no downstream artifact.

### D-C Branch Topology — **SINGLE**

One release branch, one PR, one merge. Chosen independently, and independently justified by edge **E2**: under a split-PR topology, #5825's AC-5 could not be graded until #5826's PR merged.

### D-Concurrency Posture — **P0 fully-serial**

### D-Mechanism (#5825) — **Extend the class-3 admission test with an obligation limb**

Five candidates were generated across all three altitude bands and narrowed on hard constraints first.

| Candidate | Altitude | Disposition |
|-----------|----------|-------------|
| **A** — a `PreToolUse` hook keyed to the tool calls that mark a governed task class | point-fix | **ELIMINATED on a falsified premise, not on cost.** Compliance is not a payload property: `intake-desk` Mode C's *sanctioned* `gh issue create` and a bypassing agent's `gh issue create` are **byte-identical tool calls**, and hooks read no session / subagent / skill / mode field. Two of the three evidence rows have no distinguishing tool-call signature at all — composing an oversized milestone leaves a `gh issue edit` on a milestone description indistinguishable from any other milestone edit. It also re-opens two settled dispositions (ADR-053 Alternative D; ADR-112) on the same infeasibility. |
| **B** — a net-new `trigger:` frontmatter field plus a net-new deploy check | new-abstraction | **ELIMINATED on extend-before-create plus blast radius.** Two covering surfaces exist; a third parallel declaration registry is a shadow SSOT of *"what the platform declares, and what enforces it."* It also manufactures the unbounded corpus sweep at MODERATE reversibility, where an on-change posture achieves the same outcome at CHEAP. |
| **C** — extend the class-3 **admission test** with an obligation limb; route into the same register and Check 62 | extend-seam | **CHOSEN.** |
| **D** — corpus-wide honesty pass labelling unrunnable obligation rules advisory | point-fix | **Dominated as a sole answer; adopted as a sub-limb.** It is already class 3's existing exit disposition, and C routes obligation-shaped rules to a disposition of which honest-labelling is one. |
| **E** — extend the decision-time-adherence index with an action-shaped checkpoint row | extend-seam (different seam) | **Dominated as a sole answer; its one load-bearing part reused.** As the mechanism it is prose whose enforcement is *"the agent honoring the index plus a reviewer inspecting the emitted token"* — the failure class the card forbids. Its **emitted-observable** pattern is reused rather than a second trailer family being invented. |

**Extend-before-create determination:** *extend `core/standards/gate-efficacy-standard.md`'s class-3 admission test, its gate-coverage register, and `deploy.sh --check` Check 62*, because (i) the register and Check 62 already compute exactly this obligation — a named runner that still carries its predicate, recomputed rather than vouched for; (ii) the extension requires **zero code change**; (iii) the authoring-time surface (checklist 4.9) and the Stage-7 backstop already exist and need only the second trigger form; (iv) a net-new surface would be a second registry of the same concept. **Chosen altitude: `extend-seam`.**

**Nearest-seam search, cited:** `gate-efficacy-standard.md` class 3 (**fits — chosen**); `core/rules/decision-time-adherence.md` § 2 index (does not fit — § 1's predicate is claim-shaped, and widening it re-opens ADR-112's bounded-index decision); `core/standards/platform-doc-frontmatter-standard.md` + Check 50 (does not fit — scope is `core/**` only, and `bundle-composition-doctrine.md` lives outside it); `core/hooks/` `PreToolUse` (does not fit — Candidate A); `operator.toml [adapters]` selectors (not applicable — no host binding).

**Reversibility / Confidence:** **CHEAP / HIGH** (improved from the card's recorded MODERATE / MEDIUM — see § Deviation Log Δ1).

### D-3 — Scope lock: **LOCK AS DESIGNED** (Collective Review, 2026-08-29)

**Reversibility: MODERATE / confidence HIGH.** The bundle is **hard scope-locked**; a post-lock change requires a governed override. The locked change set is the File Change Matrix above, including the two elements the scope lock expanded into it: #5826's `operator.toml [trackers.*]` schema arm (closing ADR-109's own recorded Alternative C), the `script-execution-allowlist.txt` entry (a Stage-6/7 blocker — the fixture is 0 of 281 entries), and `install-tests.yml` as the 6th file.

### D-4 — Major-1: **FIX IN-RELEASE**

**Reversibility: CHEAP / confidence HIGH.** `release-hub` Mode R group 6 carries `bundle-composition-doctrine` Steps **1** (Outcome Statement) and **5** (size band) — and **not** Steps **3** (backward dep walk) or **4** (older-milestone prerequisites). Group 2 validates the dependency graph (`2a` validity / `2b` acyclic + ordered / `2c` cross-milestone leaks); it never checks whether the composition *performed* the walk. Hub-verified independently.

That is precisely the half the motivating defect skipped, and **this milestone is a live instance**: its own Parallelization-Map reconfirm query is a broken probe (2 of 2 false positives, hub finding at Stage 4), so #368 carries no valid record that a backward dep walk was performed.

**Disposition:** add Steps 3 + 4 to Mode R group 6 — one table cell plus one line in `milestone-readiness-checklist.md`. Group 6's owning spec is `bundle-composition-doctrine`; this **widens what the group composes**, and adds no new check logic to the hub (ADR-019 compose-not-absorb).

### D-5 — ADR: **ONE COMBINED ADR**

**Reversibility: MODERATE / confidence MEDIUM.** The number is **not reserved in this document.** ADR numbering is a global monotonic sequence spanning both `core/ADRs/` and `release/ADRs/`; the number is allocated live at commit time against the mainline anchor via `release/tools/renumber-adr.py --next-free`, never ahead of a sibling's unmerged claim (a gap blocks the repo; a duplicate is tooled).

The ADR records: the **form-not-class** shape and its cascade rationale; the **hook-infeasibility falsification**; the **#5286 composition boundary**; and #5826's **declaration-scoped predicate**.

---

## Non-coverage — what this release does NOT deliver

Stated here as well as in the standard itself, because a release that leaves its own limits implied reproduces the failure class it exists to close.

1. **No runtime-skip detector.** For a row whose runner is a named review step or a named gap, the detectable record is the **absent observable**, which a reviewer must notice. Check 62 asserts that the *named runner still carries the predicate*; it asserts nothing about whether the procedure *ran on any given occasion*.
2. **The mechanism does not reach the operator auto-memory store.** `runner-def: <path>::<anchor>` resolves against **repo** paths, and the auto-memory store sits outside the repository. This is a statement about **#5825's register-and-Check-62 mechanism** and about nothing else; #5826's Check 36 *does* read that store at deploy-check time on an operator machine and structurally cannot in CI, where the store does not exist. The two statements are non-overlapping facts, not a contradiction — see CIAC-1.
3. **No hook can distinguish compliance from bypass on a byte-identical tool call.** A property of the payload, not of any hook's implementation.
4. **Check 62's R1 is anchor-presence, not predicate-completeness.** A runner that carries **half** its predicate resolves `CLEAN`. Instance 1 was a live example of exactly this before D-4 fixed it, and the general limitation remains.
5. **The mechanism is advisory and deploy-time-only.** Check 62 declares `advisory / deploy-time-only; warn-mode initial`, and Requirement (b′) bars `required` while no CI mirror exists. **This release makes governed obligations detectable, not enforced** — the mechanism's own runner is advisory and its first instance is warn-mode. That is coherent and deliberate, and it is recorded here so Stage 9 reviews it as a stated property rather than discovering it.
6. **No detector for an obligation that was never registered.** Check 62 resolves the rows the register *contains*; nothing scans the corpus for a prose-declared normative predicate carrying no row. A never-registered obligation and a de-registered one are therefore the same state to it — deleting a row returns `CLEAN` with a lower pointer count rather than a finding. The population is *registered* governed procedures, not governed procedures, and what puts a row in that population is the authoring-time review step (`design-review-checklist.md` 4.9 primary, `pmo-qa-auditor` Mode G backstop), not a computation. **Added at the AC-4 remediation** (§ Deviation Log Δ17), where Stage 8 demonstrated it live rather than deriving it.
7. **The declared observable is reviewer-verified, not machine-checked.** A 3-O row MUST state the observable the compliant path emits and the bypassing path does not, and no executable surface in this repository reads that statement. A row that states none, and a row whose stated observable the compliant path never actually emits, both resolve exactly as a conforming row does. **Added at the same remediation.**

---

## Findings routed forward (not fixed in this release)

| # | Finding | Severity | Routing |
|---|---------|----------|---------|
| **F-1** | **The gate-efficacy standard states no lexical form for a `runner-def:` anchor, and a space-bearing anchor silently truncates.** Check 62 captures the anchor with `[A-Za-z0-9._-]`, which stops at the first space, so `::Bundle coherence` is asserted as `::Bundle` — a weaker predicate than the author wrote, resolving CLEAN. Demonstrated against the shipped regex during this release. | **Major** | Follow-on card. Mitigated here by authoring space-free anchors only; **the standard is not edited for it**, which is scope beyond the D-3 lock. |
| **F-2** | **A shipped skill file states a false claim about hook behaviour.** `operations/skills/intake-desk/SKILL.md:228` says `gh issue create` is *"not payload-detectable — the hook never sees it."* `core/hooks/block-gh-path-leak.sh:176` gates on `TOOL_NAME = "Bash"` and `:192` acts on gh issue/PR writes, so the hook demonstrably does see it. The **operative** claim (not a `block-autonomy-ceiling.sh` Tier-0 class) is true; the **stated** claim is not, and the phrasing is mirrored at `references/output-contract.md:119` and repeated at SKILL.md `:474` and `:728`. Opened by the hub as **AI-004**. | **Major** | Filed as a `bug`, carrying the corrected framing: *the non-detectability is semantic (compliant and bypassing calls are byte-identical), not lexical.* Not fixed inline — a skill-file edit outside this card's declared scope, requiring the `pmo-skill-editor` discipline plus a package rebuild. The corrected framing already ships in this release's non-coverage statement, so the release is accurate even before the skill file is amended. |
| **F-3** | **A latent mis-cascade target.** The consumer-reference bullet in `core/standards/gate-efficacy-standard.md` read *"those three class-3 rows"* and *"the resolution target **every** class-3 `runner-def:` pointer resolves against"* — correct in intent for the `RCP-01`/`02`/`03` rows that name `pmo-skill-editor` Mode C, but a later author re-reading it as a class-3 **total** would mis-cascade it once 3-O rows landed. | **Minor** | **RESOLVED IN-RELEASE — the record above is corrected, not the delivered state.** Stage 6 and an earlier revision of this row both recorded the line as *"deliberately not touched"* and instructed Stage 7 to confirm it still read scoped. Stage 7 DT (finding i-1) measured the delivered file and found it **had** been scoped in the same Engineering commit that created the exposure: `class-3 rows` → `class-3-V rows`, and *"**every** class-3 `runner-def:` pointer"* → *"**those** rows' pointers"*, with the 3-O resolution target added as its own bullet. Engineering's own *Reconciliations* section records the edit; only this row contradicted it. **The delivered state is better than the record was** — the mis-cascade target is closed, and Stage 9 carries no phantom residual here. The mirror of the same sentence-class in `core/standards/regression-checks.md` § Category 7 was **not** swept at Stage 6 and is fixed by the D-8 touch-up (§ Deviation Log Δ16). |
| **F-4** | **The failure-mode anti-pattern entry for this signature.** `root-cause-analysis.md` § 3 step 6 routes an N≥2 recurring root cause to a `failure-mode-standard.md` 5-field entry, and N=3 here. Recommended home, from precedent rather than invention: a third `<class>-class workflow` subsection of `## Examples` (the file already hosts two non-skill-scoped workflow-class subsections at `:274` and `:720`), category tag **`TRIG`** — the failure is at the trigger surface, a declared trigger that fires nothing. | **Minor** | Follow-on card. Genuinely separable, and it needs the shipped mechanism to name in its Mitigation field. |
| **F-6** | **`verify-release-plan.sh` silently DROPS any Verification-Plan table row whose cells use the vocabulary of the schema's own column names.** The parser's header detector runs over every table row, not only the first, and sets `is_header` when any cell contains the substring `predicate`, `expected`, or `verification method` (or lowercases to exactly `issue` / `ac` / `method`). A data row matching any of those is consumed as a header and `next`ed — no record, no `parity-error`, no ERROR verdict. This is the **silent-drop class the tool's own design notes say was rejected in another candidate**, and it is a false-clean vector: a plan can lose acceptance-criterion rows and still read all-PASS. Two rows of this very plan were lost to it before it was found, both because their cells said *"predicate"* — a word an author writing about gate predicates uses constantly. | **Major** | **FIXED IN THIS RELEASE per operator ruling D-7** — this row is retained as the finding record, not as open scope. Header detection is now **positional** (a header is the first row of a table block) rather than keyword-based, so a data row is never mistaken for one whatever words it contains. Reproduced first with a controlled 9-arm probe: 4 sensitivity arms dropped (`predicate` in the result cell, `expected`, `verification method`, `predicate` in the method cell), 5 specificity arms kept (two plain-ASCII controls, an exact-`issue` near-miss, a hyphenated `pred-icate` near-miss, and a nonsense token). Then closed against D-7's own acceptance test — the two rows this plan lost reappear (V-9) — and regression-tested across the whole 185-plan corpus: **+23 records recovered, 12 plans gained, zero plans lost**. A stricter variant requiring two schema column names was tried and **rejected** against that corpus: it zeroed five plans whose real headers name only one. The two rows are restored to their natural vocabulary above, so this plan is now its own live regression case rather than a workaround. See § Deviation Log Δ13. |
| **F-7** | **The pre-merge `.skill` package-freshness gate reports FRESH on a genuinely stale package, because its content verdict does not execute in CI.** Found live on this branch: commit `ac781257` edited `core/standards/regression-checks.md` — a TEMPLATE_SYNC_MAP canonical injected into `pmo-skill-editor` — without rebuilding the package. Local `deploy.sh --check` Check 7 reported `FAIL: pmo-skill-editor — source content changed since build (rebuilt hash != committed baseline)`. The pre-merge gate, on a checkout of `Merge ac781257 into e19a9d30`, reported `55 rostered skill package(s) content-fresh — OK`, exit 0, **green, zero annotations**. Root cause read from the job log, not inferred: `_c7_compute_verdict`'s staged rebuild — the step that makes the verdict *"mtime-independent … catches a committed-stale package on a fresh checkout"* — emitted `staged rebuild failed to run; falling back to baseline-vs-package content compare` for **55 of 55** rostered skills. The fallback flags only when source mtime exceeds package mtime, and a fresh CI checkout stamps every file with the same mtime, so the fallback is structurally inert there. The committed-package-vs-sidecar compare still passes, because a stale package and a stale sidecar agree with each other. Net: in CI the gate asserts a **proxy** (mtime) that cannot fire, and publishes a content verdict it did not compute. Its own declared falsification test — *"edit a `references/` without rebuilding the package → the probe reports STALE"* — does not hold in CI, and this branch is the counter-example. This is the v3.35 defect the gate was built to close, reproduced through a different path. | **Major** | **Not fixed here — out of the D-8 touch-up's declared scope, and a workflow/engine change needs its own governed intake.** The stale package this found **is** fixed (row above): the touch-up rebuilds `pmo-skill-editor`, so nothing stale merges. Surfaced rather than absorbed, because a green gate over a real violation is the exact failure class this release exists to make impossible, and it was found *by* this release's own change. Diagnosis to carry into that intake: find why `build_skill_to_dir` fails on a GitHub-hosted macOS runner for every skill, and make an all-skills staged-rebuild failure a loud verdict rather than a silent fallback — a rebuild that never runs should not be able to publish FRESH. |
| **F-5** | **Check 62 and Check 50 have no CI mirror.** `deploy-check-ci.yml`'s required subset resolves to exactly one member (Check 38). Pre-existing, declared honestly by Requirement (b′). | **Minor** | Belongs to `deploy-check-ci.yml`'s own back-fill effort, whose header states the subset *"grows as posture:required checks lacking a mirror are back-filled."* Not this release's scope. |

---

## Deviation Log

Deltas between the Stage-4 plan of record and the delivered position — as ratified at Stage 5 / Collective Review, then refined through Engineering (Δ6–Δ15), Dev Testing (Δ16), and Acceptance Review (Δ17). All are refinements, reductions, or corrections; none re-opens the bundle.

| # | Stage-4 record | Ratified delta | Basis |
|---|----------------|----------------|-------|
| **Δ1** | #5825 reversibility **MODERATE / MEDIUM**, justified as *"every governed procedure edited to carry a trigger declaration is a corpus-wide change that is tedious to walk back."* | **CHEAP / HIGH.** The premise no longer holds: the mechanism inherits class 3's on-change posture (*"the check is on the change, not on the corpus: no scan and no allowlist"*), so **the sweep collapses to zero retroactive edits**. `git revert -m 1` restores the prior state exactly and Check 62's pointer count returns to 4. This is a rollback-complexity reduction, which was R2's stated purpose. The **aggregate** release tier stays MODERATE per the operator's D-3 record. | Stage 5 AI-002; operator D-3 |
| **Δ2** | Hub assertion at Stage 4: *editing Check 36 without updating `test_check36_drift_classes.sh` fails the suite* — the drift guard was treated as a forcing function. | **FALSIFIED.** The guard is a **presence-only** assertion over six Class-4/5 fragments, all of which an **additive** sixth class preserves. Tested by the Stage-5 spoke (baseline PASS / additive PASS / control-break FAIL) and re-read by the hub. The finding survives inverted: the fixture guard is a **missing forcing function**, and #5826's spec ships one. | Stage 5 spoke test + hub re-read |
| **Δ3** | Hub assertion at Stage 4: the `{#drift-classes}` anchor has **three** live inbound references. | **FALSIFIED — it has ONE** (`knowledge-architecture.md:358`). `memory-architecture.md:24` and `:114` link `#memory-corpus-boundary`, carrying the class count as prose only. R6's mitigation is unchanged; only the count was wrong. | Stage 5 spoke measurement + hub re-read |
| **Δ4** | Change set = 4 file edits + 1 ADR (the Stage-5 in-release footprint), with `milestone-readiness-checklist.md` **conditional** on the Major-1 disposition. | **The conditional row is PROMOTED to unconditional in this commit**, its condition having resolved at D-4 (FIX IN-RELEASE). The change set grows to include it, plus its mandatory `release-hub` `.skill` package rebuild, plus #5826's 6th file (`install-tests.yml`) and the allowlist entry. | Operator D-3 + D-4 |
| **Δ5** | #5826's declared Affected Files named 2 of the 5 files asserting the literal "five". | **All five carried** in the File Change Matrix (adding `memory-architecture.md`, `test_check36_drift_classes.sh`, `memory-corpus-drift-audit.md`). Routed as a body refinement, not a scope change — the work was always implied by ADR-109 § 8's *"the class joins that table"*, it was simply not enumerated. | Stage 4 R1 |
| **Δ6** | The Stage-5 File Change Matrix declared the ADR at a placeholder path (`core/ADRs/ADR-<next>-….md`). | **The ADR path is declared outside the machine-readable fenced block**, because a literal path authored at Commit 0 would pre-reserve a number the allocation discipline forbids reserving ahead of a sibling's unmerged claim. The number was allocated live at the ADR commit via `release/tools/renumber-adr.py --next-free`, which returned **162** both at authoring time and again after a fresh `git fetch origin main` immediately before that commit. **Delivered as `core/ADRs/ADR-162-obligation-limb-is-a-form-not-a-fourth-gate-class.md`**; `check-adr-numbers.py` reports PASS, contiguous 001..162, zero duplicates. Recorded here at the plan-update commit — this file states the number once it is a fact rather than once it is an intention. | ADR numbering discipline; § Operator Decisions D-5 |
| **Δ7** | Stage 5 proposed `runner-def: release/skills/release-hub/references/milestone-readiness-checklist.md::Bundle coherence` for Instance 1. | **Anchor changed to a space-free token.** Check 62's capture class stops at the first space, so the proposed anchor would have asserted only `Bundle`. The shipped anchors are `backward-dep-walk-performed` and, for the doctrine passage, a space-free token absent from the runner-definition file before this release — so its presence is an assertion this release actually adds. Recorded as **F-1**, and the standard is deliberately **not** edited to state the rule (scope beyond the lock). | Stage 6 mechanism probe against the shipped regex |
| **Δ8** | CIAC-1 as authored at Stage 4 asked only whether the two cards give *"a consistent answer on whether that surface is reached"*, and the two Stage-5 spokes returned literally opposite words — #5825 *"not reached"*, #5826 *"reached at deploy-check time."* The scope-lock record did not adjudicate it. | **Reconciled in the shipped text rather than left to a grader.** The two statements are about **different mechanisms** and are both true; each shipped statement now names the mechanism it is about. CIAC-1's predicate is restated above to make that the grading standard. No design changed — only the subject scoping that makes the claim gradable. | Stage 6, reading #6264 and #6265 together |
| **Δ9** | Instance 3's register row was to carry `runner-def:` naming Check 36. | **The row names Check 36 as its enforcing gate and carries NO `runner-def:` pointer at this commit.** Check 36 does not carry the sixth class until #5826 lands, so a pointer resolving CLEAN here would assert something not yet true — the false-confidence this standard exists to forbid. The row ships as a **named gap** naming its intended gate, and the pointer lands with the detector. **Coordination note for slice 2:** #5826's spoke adds the `runner-def:` pointer to that row when it ships the sixth class. | Stage 5 Instance-3 disposition (*"Pre-#5826: none — a named gap"*); Requirement (a) |
| **Δ10** | Stage 5's matrix specified that the `bundle-composition-doctrine.md` § 3 passage gains *"the `**Runner:**` label … plus the `runner-def:` pointer."* | **The passage carries the `**Runner:**` label only; the `runner-def:` pointer lives in the register row alone.** That is the shipped class-3-V convention, measured rather than assumed: across the tracked corpus every `runner-def:` pointer sits in the gate-coverage register or in Check 62's own parser and fixtures, and **not one source passage carries one** — `core/schemas/tracker-schemas.md` § Template parity, the `RCP-01` precedent, names its runner in prose and stops there. Check 62 reads only the standard, so a pointer in the passage would be inert *and* a second copy of the register's value. Following the spec literally would have created the duplicate the standard's own single-home discipline forbids. | Stage 6 corpus measurement of the shipped convention |
| **Δ11** | The Verification Plan was authored in the natural vocabulary of the subject, and the release-scoped check table sat inside the `## Verification Plan` H2. | **Both re-authored around a parser defect (F-6).** The plan verifier drops any per-issue row whose cells contain `predicate`, `expected`, or `verification method`, and parses every table inside the Verification Plan section at the per-issue column indices. Two acceptance-criterion rows were silently lost, and six spurious `PENDING` records were emitted from the release-scoped table, before the cause was isolated. Cells now avoid the trigger vocabulary and the release-scoped table is promoted to its own H2 with distinct column names. **The tool is not edited** — that is scope beyond the lock, and the finding is routed as a follow-on. | Stage 6 C4 self-verification; controlled 9-arm probe |
| **Δ12** | Δ9 recorded that Instance 3's register row ships as a **named gap** with no `runner-def:` pointer, because Check 36 did not yet carry the sixth class, and left a coordination note: *"#5826's spoke adds the `runner-def:` pointer to that row when it ships the sixth class."* | **Discharged. The pointer landed with the detector**, exactly as Δ9 and the row's own text specified: `runner-def: core/deploy/deploy.sh::declared-live-read-with-stored-value`. This is the **CIAC-2 affirmative branch**, and it is the one edit slice 2 makes inside slice 1's file — flagged rather than silent, since #5825 is otherwise done. The anchor names the arm-1 sub-label rather than the class name because the sub-label exists only on the emitting code path, so it cannot resolve against a comment; and it is **space-free by construction** per F-1, since Check 62's capture class stops at the first space. Check 62's pointer count moves 5 → 6, and V-1 is updated with it. | Δ9 coordination note; slice 1 Stage-6 handoff (*"load-bearing"*); operator D-3 CIAC-2 |
| **Δ13** | F-6 was routed as a **follow-on card**, with the tool explicitly **not edited**: *"it is outside the D-3 lock."* | **Reversed by operator ruling D-7: FIX THE TOOL IN THIS RELEASE.** The hub's initial framing — that this needed a governed override — was **overstated and is corrected**: the post-Collective-Review hard lock binds `issues_added`, meaning *new issues into the bundle*, and adding a file to an existing slice's change set is not that act. The protocol names this case explicitly under what the composition lock does **not** lock — item 1 (per-issue scope and AC refinement) and item 4 (release-plan revisions). So it lands as a **scope refinement plus this Deviation Log entry, and no more**: no override, no re-bundle, no `[BUNDLE AMENDMENT]` comment, and **no issue moved into or out of this milestone**. `release/tools/verify-release-plan.sh` joins the File Change Matrix; the fix rides slice 2 as its own distinct commit because it belongs to neither card's subject matter. Its acceptance test is D-7's own: the two rows this plan lost must reappear — demonstrated, with both control arms, at V-9. | Operator ruling D-7 |
| **Δ15** | Δ13 restored #5825's AC-2 and AC-4 rows **verbatim** from `2a21bf80`, on the reasoning that a verbatim restoration makes this plan its own live regression case for F-6. | **Restored in vocabulary, bounded in invocation.** The verbatim AC-2 method named `` `deploy.sh --check` `` in backticks, and `handle_per_issue` *extracts and executes* a backticked command — so the row the fix had just un-dropped made every future verifier run on this plan dispatch a full ~20-minute deploy sweep. Observed directly: the verifier sat for 15 minutes with a live `deploy.sh --check` child before the cause was found. Both rows keep the F-6 **trigger vocabulary** (`predicate` in AC-2's method, `predicate-completeness` in AC-4's expected cell), which is what preserves the regression property — the trigger is the word, not the command — and both now carry a bounded `grep -c` with its own control arm. **Measured after the change:** the `origin/main` parser reads **6** records from this plan and the fixed parser reads **11**, recovering D-7's two named rows *and three of the #5826 rows authored in this very commit*, which the old parser would have dropped for the same reason. Zero rows lost. F-6 caught in the act a second time, on rows written the same day. | Stage 6 observation of a live dispatch; D-7 acceptance test re-run |
| **Δ14** | Stage 5 finding F-4 forecast that editing `deploy.sh` makes **Check 10** (editor audit-trail trailer) a history-level finding resolved by the Stage-6 commit carrying the trailer. | **Does not apply — the forecast named the wrong check.** Check 10 is scoped to migrated skills' `SKILL.md` files (`<module>/skills/<skill>/SKILL.md`, gated on the `skill_discipline_migrated_v10_2` frontmatter flag); it never reads `deploy.sh`. This change touches no `SKILL.md`, so Check 10 SKIPs on it and no trailer is owed. Recorded rather than silently ignored, so a reviewer looking for the forecast finding knows why it is absent. | Stage 6 read of the Check 10 implementation |
| **Δ16** | Stage 7 Dev Testing returned `PASS` on both cards with **0 Blockers**, routing five Minor / Informational findings forward as follow-on cards and record corrections — m-1 and m-2 as one reconcile, m-3 as an operator call, m-4 and i-1 (F-3) as Stage-9 ratification edits, and F-05 as a plan-pointer correction. | **Fixed in-release as a Dev-Testing touch-up, authorized by operator ruling D-8 at Stage 7.** Six corrections, run **before Stage 8** so acceptance grades a clean delivered state rather than a state plus a list of known-stale sentences: **m-1** the stale `two-limb` referrer in `decision-discipline.md`; **m-2** § Category 7's false universal and silently-widened *Applies to* in `regression-checks.md`; **m-3** the Step-4 register anchor that left half the D-4 / Major-1 fix unenforced; **m-4** ADR-162's stale pointer count; **F-05** the CIAC-1 grading pointer (repointed at the `deploy.sh` Check 36 header, § 7.1 withdrawn, **no doctrine content added**); and the **F-3 record**, corrected to `RESOLVED IN-RELEASE`. **Every one is a documentation or pointer correction. No predicate, verdict, admission limb, or detector body is changed, and Check 62 still needs no code change.** **This is a scope refinement, not an issue addition** — identically to Δ13: the post-Collective-Review hard lock binds `issues_added`, and **no issue moved into or out of this milestone**; two file paths join the File Change Matrix, one of them promoted out of the read-only table. **Two records this touch-up falsifies rather than restates.** (1) **The Stage-5 blast-radius claim is wrong**: it asserted the only live consumers of the class-3 admission test were `design-review-checklist.md` and `regression-checks.md`; `decision-discipline.md`'s G8 passage is a third, first-order and unfrozen, and neither it nor its own risk was enumerated. A corpus sweep at the touch-up measured `two-limb` at **15 occurrences across 12 files** of 1261 markdown files, read-then-classified per file: 13 are unrelated subjects (G2-13's conditional-fire predicate, SR-G6, provenance grammar, probe unions) and one is this standard's own **version-history row**, which correctly records what its release did and is deliberately left byte-unchanged; exactly one was the stale referrer. (2) **The count in m-4 is seven, not six** — the brief that authorized this touch-up said the merge-time pointer count was six, which was true when it was written and is superseded **by m-3 in this same touch-up**; the ADR, V-1, and this row all state seven, and the real Check 62 runner confirms it — `OK: all 7 gate-coverage register runner-def pointer(s) resolve`. **One consequence the touch-up brief did not anticipate, carried rather than dropped:** `core/standards/regression-checks.md` is an injected canonical, so m-2 staled `packages/pmo-skill-editor.skill`; the mandatory rebuild joins the File Change Matrix. Chasing that down surfaced **F-7** — the pre-merge package-freshness gate published FRESH over the genuinely stale package, because its staged rebuild fails for all 55 rostered skills in CI and the mtime fallback cannot fire on a fresh checkout. The stale package is fixed here; the gate defect is routed forward, not absorbed. | Stage 7 DT reports on #6268 / #6269; operator ruling **D-8** |
| **Δ17** | Stage 8 Acceptance Review graded #5825 **4 of 5**, rendering **REJECT on AC-4** (*"What the mechanism cannot detect is stated explicitly, rather than left implied"*) and holding release-state. The delivered non-coverage enumeration carried **five** items, all of them *in-population* limits — properties of predicates that already hold a register row. | **Fixed in-release as an AC-4 remediation, authorized by operator ruling D-9.** Two items appended to § *Runner resolution*'s non-coverage enumeration, taking it to **seven**, and mirrored into this plan's own § *Non-coverage* restatement so the two do not drift. **Item 6 — the population boundary:** the class resolves over *registered* governed procedures, not governed procedures; Check 62 resolves the pointers the register contains and nothing scans the corpus for a prose-declared predicate carrying no row, so a never-registered obligation and a de-registered one are the same state to it. Established behaviourally, not argued: Stage 8's **ARM7** deleted the whole class-3-O row for this release's own Evidence Instance 1 and the check returned `OK: all 5 … resolve` — green, with a lower count and no finding — while the obligation text and both runner anchors remained in the corpus. **Item 7 — the declared observable:** a required element of a 3-O row's form that no executable surface reads, verified independently at this remediation (zero occurrences across the repository's `.sh`/`.py`/`.yml`/`.yaml` files, with both control arms firing). **Append-only by construction: items 1–5 are byte-unchanged and un-renumbered**, because two register rows cite them positionally (*"non-coverage item 4"*, *"non-coverage item 3"*) and this plan cites a third — renumbering would silently break those citations. **The count cascade was swept corpus-wide rather than assumed**, which found **five** assertions, not the one: this standard's version-history row, `ADR-162`'s *"Five of them"* restatement, this plan's *"five-item"* scope cell, this plan's *"Five of them"* key-decision bullet, and the AC-4 verification row's expected result — all five updated to seven. **The fifth was found by a control arm, not by the first sweep**, and the miss is recorded rather than smoothed over: the initial probe keyed on a count-word appearing near an *enumeration-context* token (`non-coverage`, `enumeration`, `limits are enumerated`), and the key-decision bullet says only *"The mechanism's own limits ship with it. Five of them"* — carrying the count and the subject but none of the context tokens. The arm that caught it keyed on the count-word **form** instead and ran over the target files exhaustively. Both arms are retained. **No predicate, register-row pointer, verdict, or code is touched; Check 62 still needs no code change and still resolves seven pointers.** Reversibility **CHEAP** / confidence **HIGH**. | Stage 8 acceptance report on #6270 (finding QA-1, Lane 2); operator ruling **D-9** |

---

*Closure-phrasing note: every per-issue closure reference in this plan is written as "marked as closed at Stage 13" — no close-family verb is bound to an issue number anywhere in this file, so transcription into PR bodies cannot trip GitHub's close parser.*
