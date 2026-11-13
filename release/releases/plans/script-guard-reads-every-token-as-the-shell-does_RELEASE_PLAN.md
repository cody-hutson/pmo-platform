---
title: Release Plan — script-guard-reads-every-token-as-the-shell-does (BLOCK-DESTRUCTIVE-022 reads every token as the shell does)
type: release-plan
plan_type: release
status: OPEN
release: versioned (bump-class minor; provisional display v5.08; the concrete number binds at the Stage-12 atomic claim)
milestone: script-guard-reads-every-token-as-the-shell-does
release_class: novel
reversibility: MODERATE / Confidence MEDIUM — one branch and one merge of a security hook; reverting the merge restores the hook, its suite, corpus and fragments, and the deployed copy is restored by the hook carrier's refresh
---
# Release Plan — `script-guard-reads-every-token-as-the-shell-does`

**Milestone:** `script-guard-reads-every-token-as-the-shell-does` (milestone 439; epic #7932). The Stage-4 planning sub-task **#8898** carries the approved plan (`#8898 comment 6859275987`).

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v5.08`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-keyed until then.

**Topology:** D-C **SINGLE** — one release branch, `release/script-guard-reads-every-token-as-the-shell-does`, one pull request opened in **draft** at Stage 6, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — 8317 → 8318 → 8319 → 8491 → 8320 → 8316 → 8492, one Engineering slice at a time.

**Release class:** `novel` — Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8898 and is amended, in order, by: the Stage-4 gate's Decision Recorded (`#8898 comment 6859599888`); D-PayloadRoute (`#8898 comment 6860105499`); the wave-5A close — D-SpawnRule, D-Family, D-SecurityItems (`#8898 comment 6860962310`); and the Collective Review scope lock (`#8898 comment 6864573397`). Where they disagree, the later record wins. The per-card designs live on the Stage-5 sub-tasks named under § Build From.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): a security hook's behaviour changes inside its existing rule, with its suite, corpus and readiness fragments |
| **Date Created** | 2026-11-13 (Friday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering, Engineering Commit 0 |
| **Branch** | `release/script-guard-reads-every-token-as-the-shell-does` |
| **PR** | opened in **draft** at Stage 6; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `script-guard-reads-every-token-as-the-shell-does` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-13, domain: software }`

---

## Commit-0 Version Re-Verify Record

- **Baseline pin:** `origin/main` = `29c604045def22ebd21fb4a758c3bb56be277b20`, unchanged since the Stage-4 pin.
- **Steps 1–3 (pre-write):** `git fetch --tags origin && git fetch origin main`; latest version tag `v5.07`; `v5.08` absent from the local tags and from `git ls-remote --tags origin` (0 refs). The planned `v5.08` equals the recomputed next-free for bump-class `minor`: **PROCEED**. Draft PR #8821 (`release-usage-measured-right`) computes the same slot; the Stage-12 atomic claim settles it (the tag arm binds).
- **Step 3b (post-write, pre-commit):** recorded below this file's commit as the `claim-version.sh --verify-stamp` result.

---

## Build From

**Build from (Stage 6 reads these, never the plan alone):**

| Card | Design | Plus |
|---|---|---|
| #8317 | #8928 comment 6860818149 | review CD-1 (#8981 comment 6861782973); D-8317-Scope IN; the shared `$$'` fix in `script_qadvance` and `script_word_scan` (an odd-length `$` run before a quote opens ANSI-C; an even-length run does not); AC2 as #8317 proposed |
| #8318 | #8931 comments 6860402453, 6860917414 (Amendment 1) | the join scans incrementally, bounded by 1,024 characters |
| #8319 | #8934 comment 6862652300 | review Blocker fix (shared, via #8317) and CD-1 readable-set restriction (#8988 comment 6863359021); D-8319-RefRec (A); D-8319-Sep OUT |
| #8491 | #8937 comment 6862082436 | J0 (no second join site); T1 with T1b; S3 OUT; the four AC adjustments; size M |
| #8320 | #8940 comment 6863118539 (Amendment 1, which supersedes 6861769808) | second walk + receiver conjunction; replace nothing |
| #8316 | #8943 comment 6862160469 | its six calls as recommended; review CD-1, CD-2, the FM-2 gate; FM-1 declared (#8985 comment 6862950117) |
| #8492 | #8945 comments 6862228230, 6863490039 (Amendment 1) | N1 |

---

## Dependency Graph

Native edges: #8492 ← #7020 only (CLOSED, satisfied). All seven bodies have no Dependencies section (scan `NO-SECTION:7`). The edges below come from **code**: which card's change another card's change reads. A "hard" edge means the downstream design consumes the upstream decision. A "soft" edge means a shared region, ordered to cut rebase churn.

**Basis of each edge:**
- **Card text:** #8317→#8319 (the card says it reuses the scanner) and #8318→#8319/#8491 (one family, per #8491's Evidence).
- **Code read:** #8317→#8320 (the pre-pass calls `script_qnext`) and #8316→#8492 (the deny sits after the position walk).
- **Inferred from region adjacency; L407–700 not read line by line:** #8317→#8318, #8318→#8316, and #8318→#8492.

None of these changes the order.

```
Commit 0b (corpus format + rows) ─┬─► every card
#8317 quote state (L1960–2139, carrier step L3160–3260)
   ├─hard─► #8318  operand reader reads the carried quote state
   ├─hard─► #8319  the card names "the hook's own quote scanner reused"
   └─hard─► #8320  a backslash-newline is literal inside single quotes, so the join must read quote state
#8318 quote-removal reader / tokenization decision (L407–750, operand branch ~L4072–4200)
   ├─hard─► #8319  same judged-before-quote-removal family (assignment value)
   ├─hard─► #8491  same family (split value)
   └─hard─► #8316  quoted wrapper word reads the normalized token
#8319 prefix walk assignment skip (L3264–3360) ─soft─► #8316 (same prefix loop, L3264–3420)
#8491 split-scan (L1330–1478, awk L401–460) ─soft─► #8316 (M-WRAP-OPTIONS call site)
#8320 segment join (L3091–3095, here-doc pre-pass L2274–2560) ─soft─► #8316 (segments it walks)
#8316 position walk ─hard─► #8492  the xargs deny reads the walk's resolved verb and operand exit (L3634–3665)
#8318 operand walk exit ─hard─► #8492
```

No cycles: the order 8317 → 8318 → 8319 → 8491 → 8320 → 8316 → 8492 is a topological sort, and it matches the milestone's internal sequence. A "these are independent" claim is made for no pair.

---

## Implementation Sequence

Delivery: D-C **SINGLE**, one branch `release/script-guard-reads-every-token-as-the-shell-does`, one PR, posture **P0 fully serial**.

| Step | Card | What lands (evidence shape: RED commit → GREEN commit, prediction stated in the RED commit message) |
|---|---|---|
| 0 | — | Plan file (Engineering Commit 0, version re-verify) |
| 0b | all | Corpus: `@NL@` placeholder (if D-CorpusFormat A), README and the reader's `wc_expand`. One `# --- seed 15.<k>` block per card, carrying rows for each class plus a plain-form control and a near-miss, recorded at today's verdicts. Groups: `open-rt-<class>` while open, `rt-<class>` once graded. The `rt-` prefix is unused (0 groups; control: 10 `rv-`/`open-` groups). An accepted residual therefore never lands in `open-encl` or `wrap-declared`. The commit message states each class's predicted verdict before the run. Row-id prefixes reserved and verified unused (0 hits each): QC #8317 · OP #8318 · AV #8319 · SV #8491 · LC #8320 · CP #8316 · XF #8492 |
| 1 | #8317 | Arms `QSCAN-CMT-*`, `QSCAN-NESTQ-*`. Comment state in the quote scan, and nested-quote phasing. EN86 re-graded |
| 2 | #8318 | Arms `OPND-QSFX-*`, `OPND-SPLIT-*` (F-09 slots included), `OPND-WS-*`. Operand path reads the word reader. DS71/DS73 re-graded. FWALK-QDASH suite comment corrected. `_cross-cutting.md` L237 |
| 3 | #8319 | Arms `ASGN-QVAL-*` (+ `-near`). WR126–WR131 re-graded. `WRAPDIV-qval-*` pins re-pointed. Precision rows declared |
| 4 | #8491 | Arms `SPLITV-QUOTED-*`, `SPLITV-SLASH-*`, `SPLITV-near`. Twin `cp_split_scan`. **Full runner** (five consumer suites) |
| 5 | #8320 | Arms `CONT-INTERP-*`, `CONT-HD-*`. Continuation joined before the split, quote-aware. `AC-ENCL-RESIDUAL-hd-continuation` re-pointed |
| 6 | #8316 | Arms `REACH-REDIR`, `-ESC`, `-QWRAP`, `-CASE`, `-COPROC`, `-BRACE`, `-ZPRE`. WR140–WR142, EN80, EN81, EN83, EN84 re-graded. `WRAPVOCAB-PARITY-*` declarations updated |
| 7 | #8492 | Arms `XARGS-IFLAG-*`, `XARGS-ENCL-*`. WR43–WR53 re-graded. `WRAPDIV-xargs-interp-flag` re-pointed to must-refuse |
| 8 | all | Fragment rows; `build-hook-registry.py` regenerates `core/rules/bypass-mode-readiness.md`. Final runner and differential |

Every hook measurement runs under `setup-ci-layout.sh` in the spoke's worktree. Payloads are written to files with Write/Edit and never typed into Bash command text: this session's command text tripped -023 and the isolation guard (§ Recommendations).

### Agent-Editability Read

**Derivation** — controls read at commit `29c60404`:
- Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh`. Of four `case "$ABS_TARGET"` blocks, **2** carry arms that invoke `always_block "BLOCK-AUTONOMY-001"`. Arms verbatim:
  - Block 1 (L725): `"${PRIMARY_ROOT}/CLAUDE.md"` · `"${PRIMARY_ROOT}/projects/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/.claude/settings.json"` · `"${PRIMARY_ROOT}/.claude/hooks/"*` · `"${PRIMARY_ROOT}/.claude/rules/"*`
  - Block 2 (L770, the membership arm): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`
  - Projected to repository-relative form: `CLAUDE.md`, `*/CLAUDE.md`, `OPERATIONS.md`, `*/OPERATIONS.md`, `RELEASE_PROTOCOL.md`, `*/RELEASE_PROTOCOL.md`. The `.claude/` arms name the workspace-root deployed bundle; the repository tracks no `.claude/` file, so they are discarded. `core/hooks/` is not `.claude/hooks/`.
- Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `'(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$'`; arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`. Exemption list: `undetermined` (not resolved). Conjunct 1 is false for every write-set path, so the list decides no row, and the fail-safe rule never applies.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| all | `core/hooks/block-destructive.sh` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| all | `core/hooks/tests/block-destructive.test.sh` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| all | `core/hooks/tests/fixtures/walk-payload-corpus.txt` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8317, #8320 | `core/hooks/tests/fixtures/README.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8491 | `core/hooks/lib/command-position.awk` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| all | `core/rules/bypass-mode-readiness/block-destructive.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8318 | `core/rules/bypass-mode-readiness/_cross-cutting.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| all | `core/rules/bypass-mode-readiness.md` (generated; class of its sources) | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| — | plan file; CONDITIONAL ADR + `core/ADRs/README.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |

Every row is `unconstrained`. That does **not** answer the attended-session question: the stop recorded on #8177 came from neither control. See D-Attended.

---

## Stage Applicability Matrix

| Stage | #8317 | #8318 | #8319 | #8491 | #8320 | #8316 | #8492 | Note |
|---|---|---|---|---|---|---|---|---|
| 5 Solutioning | A | A | A | A | A | A | A | `novel` → ALL. Wave 5A {#8317, #8318}: the family decision (carried quote state; quote-removal reader / tokenizer; ADR). Wave 5B {#8319, #8491, #8320, #8316, #8492} consumes it. The inbound items are folded in at 5B |
| 6 Engineering | A | A | A | A | A | A | A | serial, single branch |
| 7 Dev Testing | A | A | A | A | A | A | A | functional change to a security control |
| 8 QA | A | A | A | A | A | A | A | per-card AC verdicts |
| 9 Plan Review | release | | | | | | | Deep (`novel`); #8318 AC2 residual accepted, or not, at this GO |
| 10–11 | compress | | | | | | | git-native release |
| 12 Execute | release | | | | | | | Deploy; the deployed copy of each edited hook equals the merged source |
| 13 Close | release | | | | | | | 30-day outcome window |

No merge or split of the seven is recommended. They form one capability on one walk, and the milestone already split the -022 family by sub-capability.

---

## File Change Matrix

| Path | Intent | Cards | Change |
|---|---|---|---|
| `release/releases/plans/script-guard-reads-every-token-as-the-shell-does_RELEASE_PLAN.md` | add | all | the plan (Commit 0) |
| `core/hooks/block-destructive.sh` | edit | all | the per-card regions in § Dependency Graph |
| `core/hooks/tests/block-destructive.test.sh` | edit | all | new arms; pins re-pointed; parity declarations; `wc_expand` `@NL@`; `WALKCORPUS-ROWS` |
| `core/hooks/tests/fixtures/walk-payload-corpus.txt` | edit | all | seed 15 blocks; re-grades |
| `core/hooks/tests/fixtures/README.md` | edit | #8317, #8320 | `@NL@` placeholder (D-CorpusFormat A) |
| `core/hooks/lib/command-position.awk` | edit | #8491 | `cp_split_scan` twin, or a declared divergence (Stage 5) |
| `core/rules/bypass-mode-readiness/block-destructive.md` | edit | all | fragment rows (A0.6) |
| `core/rules/bypass-mode-readiness/_cross-cutting.md` | edit | #8318 | L237 row |
| `core/rules/bypass-mode-readiness.md` | edit | all | regenerated by `core/deploy/tools/build-hook-registry.py` |
| `core/ADRs/ADR-NNN-*.md` | `CONDITIONAL:shared-lexer-adr` add | #8317, #8318 | only if Stage 5 picks a shared lexer or quote-aware tokenization (reopens ADR-187/227) |
| `core/ADRs/README.md` | `CONDITIONAL:shared-lexer-adr` edit | #8317, #8318 | index row |

### Read-only inputs
`core/hooks/block-egress.sh` READ · `core/hooks/block-fs-boundary.sh` READ · `core/hooks/block-rm-prefer-trash.sh` READ — these consume the awk; their suites run at step 4.

### Release-wide explicit non-scope
`core/config/allowlists/script-execution-allowlist.txt` NOT EDITED — the release adds no executable script, so the companion obligation does not fire.

**A1.5 / domain:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-13, domain: software }`. The matrix is hook code and its suite (software, dominant) plus readiness fragments (governance, secondary). Every file is internal.

---

## Contention Map

**Within the release** (`overlap_class` per ADR-005; region ranges at `29c60404`):

| File | Cards | Class | Resolution |
|---|---|---|---|
| `block-destructive.sh` prefix loop L3264–3420 | #8319, #8316 (and #8491 via the L3370 call) | line-range-overlap | serial; #8319 first |
| `block-destructive.sh` quote scan L1960–2139 / pre-pass L2274–2560 | #8317, #8320 | line-range-overlap (pre-pass calls `script_qnext` at L2324–2329) | serial; #8317 first |
| `block-destructive.sh` operand exit and xargs deny L3634–3665, ~L4072–4200 | #8318, #8492 | line-range-overlap | serial; #8492 last |
| `block-destructive.test.sh` `WRAPDIV-*` pin block | #8316, #8319, #8491, #8492 | line-range-overlap (pins re-pointed in place) | serial |
| `walk-payload-corpus.txt` | all | append-pattern (seed 15) + in-place re-grades | serial |
| `block-destructive.md` items 2, 3, 9 | all | line-range-overlap | one fragment pass at step 8 |
| `bypass-mode-readiness.md` | all | generated | regenerate once, at step 8 |

**Cross-release** (DEC-31: this release merges first):

| Sibling | Its cards / surface | Overlap with this release | Edge |
|---|---|---|---|
| ms#440 `script-guard-refuses-only-what-executes` | #8326 here-document receiver; #8490 exec arm; #8327 per-command ceiling; #8493 latch message — all in `block-destructive.sh`, its suite and its fragment | #8326 ↔ #8320 (pre-pass); #8327 ↔ every added scan; #8493 ↔ #8318 flag walk. #8326 and #8317 both defer "a shared lexer" — **this release's Stage 5 decision binds #8326** | file-contention; ms#440 builds after merge |
| ms#444 `deletion-guard-judges-every-segment-and-target` | #8123 `_cross-cutting.md`; #8122 and #8123 the generated registry; `block-rm-prefer-trash.sh` consumes the awk | `_cross-cutting.md` (#8318); generated registry (all); awk behaviour (#8491) | file-contention + behavioural; ms#444 rebases and regenerates |
| #8821 `release-usage-measured-right` (draft) | 47 files | `core/ADRs/README.md` (CONDITIONAL row only); version slot | Tier-S version and ADR number |

### In-Flight Release Roster

**Measured at:** `29c60404` · `2026-11-13T16:18:35Z` · **Population:** n=1 sibling (open PRs with a `release/*` head, plus remote `release/*` heads without a PR: one head in all)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `release-usage-measured-right` | `#8821` | `8974f500` | `minor` | `v5.02` (stale) | `v5.08` (latest tag `v5.07`) | `core/ADRs/README.md` (CONDITIONAL) |

This roster is a pinned measurement only; Stage 9 A6.6 renders the verdict.

---

## Risk Register

| # | Risk | Sev | Mitigation / disposition | Owner |
|---|---|---|---|---|
| R1 | Seven cards in one walk: a later card silently changes an earlier card's verdict | High | P0 serial. RED → GREEN per card. Full WALKCORPUS differential at every commit. CIAC-4 | Stage 6 |
| R2 | A safety control stops a spawned session in #8491's region (#8177) | Med | D-Attended. Stop-and-surface (never reword or retry), then reroute #8491 alone. This session read the region unimpeded (n=1) | operator |
| R3 | Code moved after measurement (v5.05 `f57d23fc`, `a2a604bc`, `b070baa2`); five sub-classes are only code-read | Med | Commit-0b rows are the empirical gate; if one does not read `a`, close or re-scope before that card's RED commit | hub |
| R4 | The corpus cannot hold a newline (README L66), so two classes cannot be rows | Med | D-CorpusFormat | operator |
| R5 | The awk twin changes the canonicalizer view of four hooks | Med | Full runner at step 4; ms#444 informed; a divergence, if chosen, is declared in `WRAPVOCAB-PARITY-*` | Stage 5/6 |
| R6 | A quote-aware tokenizer or shared lexer reopens ADR-187/227 (rejected for v4.80's scope) and binds ms#440 #8326 | High | Wave 5A decides it once; CONDITIONAL ADR; ADR number re-checked at merge (`renumber-adr.py --detect`) against #8821 | Stage 5 |
| R7 | Two withheld security items arrive late or grow scope | Med | Required before Stage 5; re-size at 5B; exact details stay off public surfaces | operator |
| R8 | Over-band size: 27.6 effective if #8316 is L | Low | D-Size | operator |
| R9 | Enclosure positions follow `DESTRUCTIVE_022_ENCL_PHASE` = warn: EN81, EN86 and #8492's enclosure-closer member reach **W**, not B | Med | AC wording "reached (recorded at the enclosure phase)". Graduation is owed by Check 71 (warning 2026-12-15 (Tue), finding 2027-01-14 (Thu)) and has no owner (§ Recommendations) | operator |
| R10 | A refuse-to-allow precision move (#8319 AC2) is read as a regression | Low | Declared precision rows; A0.6 item 2 | Stage 6 |
| R11 | Added scans (comment state, continuation join, `case` tracking) raise per-call latency on every Bash call | Med | `AC-CPH-*` timing arms stay green; ms#440 #8327 owns the ceiling | Stage 7 |
| R12 | Exact must-refuse spellings in tracked rows on a public repository (#8491's open assumption) | Med | Stage 5 decides per class; issue and PR surfaces carry row ids only | Stage 5 |
| R13 | Rollback of a deployed security hook | Med | § Rollback | operator |

**Phase A4 control census:** R1 rests on the WALKCORPUS arms; they were observed acting this session via `WALKCORPUS-DET-fires` (83). R5 rests on the parity arms, green at head (runner). No other risk rests on a control.

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8317 × #8318 × #8319 × #8491 × #8320 × #8316 × #8492 on `core/hooks/tests/fixtures/walk-payload-corpus.txt`):** the shared corpus carries one seed-15 block per card. *Method:* `grep -c -F "# --- seed 15." core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 7. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#8316 × #8317 on `core/hooks/tests/fixtures/walk-payload-corpus.txt`):** only the out-of-scope enclosure rows (EN82, EN85, EN87, EN88) stay declared open. *Method:* `grep -c -F "|open-encl|" core/hooks/tests/fixtures/walk-payload-corpus.txt` at most 4. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#8316 × #8319 × #8492 on `core/hooks/tests/fixtures/walk-payload-corpus.txt`):** only the out-of-scope wrapper rows (WR68–WR70, WR132, WR133, WR143–WR149) stay declared. *Method:* `grep -c -F "|wrap-declared|" core/hooks/tests/fixtures/walk-payload-corpus.txt` at most 12. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#8317 × #8318 × #8319 × #8491 × #8320 × #8316 × #8492 on the corpus differential):** no refused row moves to allow except a declared precision row, and no quoted row is weaker than its twin. *Method:* declared, verification deferred to core/hooks/tests/block-destructive.test.sh arms WALKCORPUS-REC, WALKCORPUS-TWIN and WALKCORPUS-OPEN. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#8491 × #8316 on `core/hooks/lib/command-position.awk` and the -022 wrapper vocabulary):** the two walks agree, or every difference is declared. *Method:* declared, verification deferred to core/hooks/tests/block-destructive.test.sh arms WRAPROWS-PARITY and WRAPVOCAB-PARITY. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-6 (#8317 × #8318 × #8319 × #8491 × #8320 × #8316 × #8492 on `core/rules/bypass-mode-readiness.md`):** the generated index equals its regenerated form from the edited fragments. *Method:* declared, verification deferred to core/deploy/tools/build-hook-registry.py. *Graded at Stage 9 QC3.5 on the merged PR.*

Baselines at `29c60404`: seed-15 headers 0 (14 seed headers in all), `|open-encl|` 9, `|wrap-declared|` 32. Every CIAC's bound is under its baseline.

The CIAC-2 and CIAC-3 bounds assume the recommended D-Scope calls. The hub re-derives them if the operator changes a call: each changed row adds or removes one from the bound.

**G4-06 lint** (`release/tools/verify-release-plan.sh --ciac-lint` on this drafted body): `CIAC-LINT-SUMMARY declared=6 parsed=6 clean=3 declared-deferral=3 flagged=0`

---

## Verification Plan

**AC baseline:** 22 criteria (#8317 3 · #8318 3 · #8319 3 · #8491 4 · #8320 3 · #8316 3 · #8492 3), read 2026-11-13 (Fri) against `29c60404`. Any A0.6 amendment re-binds its row in the same change.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8317 | AC-1 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arms QSCAN-CMT and QSCAN-NESTQ | red at the RED commit, green after |
| #8317 | AC-2 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm QSCAN-CMT-near | allowed |
| #8317 | AC-3 | declared, verification deferred to core/hooks/tests/test-runner.sh | 0 FAIL |
| #8318 | AC-1 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arms OPND-QSFX and OPND-SPLIT | red, then green |
| #8318 | AC-2 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm OPND-WS, or this card's Stage 9 GO record | refused, or an accepted residual with an owner |
| #8318 | AC-3 | declared, verification deferred to the Stage 8 reader of core/rules/bypass-mode-readiness/_cross-cutting.md | row matches the measured state |
| #8319 | AC-1 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm ASGN-QVAL | red, then green |
| #8319 | AC-2 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm ASGN-QVAL-near | allowed |
| #8319 | AC-3 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm WALKCORPUS-REC | only declared precision moves |
| #8491 | AC-1 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm SPLITV-QUOTED | red, then green |
| #8491 | AC-2 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm SPLITV-SLASH | red, then green |
| #8491 | AC-3 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm SPLITV-near | allowed |
| #8491 | AC-4 | `grep -c -F "two split-value classes stay open" core/rules/bypass-mode-readiness/block-destructive.md` expect 0 | 0 · control: `grep -c -F "Wrapper-prefix residuals" core/rules/bypass-mode-readiness/block-destructive.md` → 1 |
| #8320 | AC-1 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm CONT-INTERP | red, then green |
| #8320 | AC-2 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm CONT-HD | correct arm |
| #8320 | AC-3 | declared, verification deferred to core/hooks/tests/test-runner.sh | 0 FAIL |
| #8316 | AC-1 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arms REACH-REDIR, REACH-ESC, REACH-QWRAP, REACH-CASE, REACH-COPROC, REACH-BRACE, REACH-ZPRE | red, then green (or an accepted residual per A0.6) |
| #8316 | AC-2 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arm WALKCORPUS-REC | 0 refuse-to-allow |
| #8316 | AC-3 | declared, verification deferred to core/hooks/tests/test-runner.sh | 0 FAIL |
| #8492 | AC-1 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh arms XARGS-IFLAG and XARGS-ENCL | red, then green |
| #8492 | AC-2 | declared, verification deferred to core/hooks/tests/block-destructive.test.sh group wrap-xargs-ctl | allowed |
| #8492 | AC-3 | `grep -c -F "is narrowed rather than closed" core/rules/bypass-mode-readiness/block-destructive.md` expect 0 | 0 · control: `grep -c -F "Wrapper-prefix residuals" core/rules/bypass-mode-readiness/block-destructive.md` → 1 |

---

## Delivery Strategy and Rollback

- **Delivery.** D-C SINGLE: one branch and one draft PR, opened at Stage 6 C2. Posture P0. Each card's RED and GREEN commits are separate. No force-push of any kind on the shared branch.
- **Stage 12.** The deployed copy of `block-destructive.sh` and of `lib/command-position.awk` must byte-equal the merged source (Success Indicator).
- **Rollback (MODERATE · confidence HIGH).** Revert the merge commit on `main`, then perform the operator-side restore of the deployed bundle with `docs/scripts/setup-workspace.sh --refresh-hooks`, verifying byte-equality against the reverted source. The version tag is retained per § Tag Retention and recorded as withdrawn. ms#440 and ms#444 re-baseline if they had rebased.

---

## Release Class declaration

**Proposed class: `novel` (confirming the milestone).**
- Trigger (b) fires: there are ≥1 D-class decisions in this plan (D-Size, D-Attended, D-CorpusFormat, the scope calls).
- Trigger (c) is possible: the CONDITIONAL ADR.
- `routine` trigger (a) fails, because all seven cards are P1.
- `cross-cutting` does not fire: the matrix touches 0 pipeline stage files and 0 of the six rule-defining surfaces.

**Posture:** engagement Standard · Stage 9 **Deep** · Stage 5 activation ALL · Stage 13 outcome window 30 days. Platform weight 1.15.

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix):** Stage 5: 2 (wave 5A), then 5 (wave 5B) · Stage 7: 7 · Stage 8: 7
**Per-spoke cost estimate:** S/M ordinal bands, about 5 % of a 5-hour window per spoke (source: heuristic — the operator's recorded fan-out budget) [CONTEXT]
**Assumed/stated remaining usage-window envelope:** UNSTATED — conservative default [ASSUMPTION – CONFIRM]
**Estimated cumulative draw % (worst parallel batch):** Stage 7 or 8 at 7 spokes, about 35 % [ASSUMPTION – CONFIRM]
**Routing:** PASS: proceed
**Note:** Checkpoint B re-validates at every `Agent`-tool launch, wave or singleton, every stage; it is runtime and load-bearing. A wave gets PROCEED/SERIALIZE/DEFER/REDUCE-scope; a singleton gets PROCEED/DEFER. Under UNSTATED, `W_max` is 2, so the 7-wide stages run as re-gated sub-waves. STAGGER is a secondary, rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry: the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant per `quota-budget-protocol.md` § 4.3b. Checkpoint A stays usage-window-only, because a plan-time pool reading has no predictive value at Engineering time (§ 3.1). The bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Outcome Statement

**AFTER** — BLOCK-DESTRUCTIVE-022 reaches the interpreter behind a leading redirection, an escaped or quoted verb, a quoted wrapper word, a `case` arm, `coproc`, a zsh precommand word and a brace group; it reads an interpreter and its operand across a line continuation as one command, judges each token after quote removal with the quote state carried correctly past a comment or a nested quote, and keeps an xargs-fed interpreter inside its deny whatever flags it carries. An unlisted script reached through any of those shapes is refused at a first-view position on the always-enforce arms, as its plain form is, and is recorded at the enclosure view's rollout phase at a position that view opens, as the ungrouped enclosure form is.

**BEFORE** — Several command positions (a leading redirection, an escaped or quoted verb, a `case` arm, `coproc`, some zsh precommand words, a brace group) leave the verb unreached. An unbalanced quote in an earlier segment, a quote or whitespace inside the path token, a space-bearing quoted assignment value and a quoted or slash-bearing split-string value each strand the operand. A line continuation drops the line to the warn-phase arm, and one interpreter flag defeats the xargs deny, so in every case an unlisted script runs; the predecessor release declared and pinned these classes and named these cards their owners.

**Actor(s):** any session whose commands pass through the guard; the deployed hook bundle.

**Success Indicator:** every member's arms pass at their stated verdicts (refused at a first-view position, recorded at an enclosure position) beside plain-form controls on the tracked walk payload corpus, and no refused row moves to allowed except a declared precision row; one PR for the milestone; at Stage 12 the deployed copy of every edited hook equals the merged source.

**Limb owners:** reaches the interpreter at the named positions → #8316 · reads an interpreter and its operand across a line continuation as one command → #8320 · judges each token after quote removal with the quote state carried correctly → #8317, #8318, #8319, #8491 · keeps an xargs-fed interpreter inside its deny whatever flags it carries → #8492 · refuses at a first-view position and records at an enclosure position → #8316, #8317, #8318, #8319, #8320, #8491, #8492

---

## Issue References

References #8317, References #8318, References #8319, References #8491, References #8320, References #8316, References #8492 — the cards are marked as closed at Stage 13 when their criteria are met.

---

## Deviation Log

| # | Stage | Deviation from the Stage-4 plan | Authority |
|---|---|---|---|
| DEV-1 | 5 | The measure-first amendment is dropped; Stage 5 designs by class only; Engineering Commits 0 and 0b are authored hub-direct | D-PayloadRoute, `#8898 comment 6860105499` |
| DEV-2 | 5 | A spawned spoke stopped by a model-output safety classifier is not re-spawned; the hub runs that card's stage (Stage 5: #8318, #8320, #8492 designed hub-direct) | D-SpawnRule, `#8898 comment 6860962310` |
| DEV-3 | 5 | The CONDITIONAL ADR rows in the File Change Matrix are not taken: every card extends the hook's own readers, with no ADR | D-Family, `#8898 comment 6860962310` |
| DEV-4 | 5 | Commit 0b's seed-15 rows carry ground truth `?` in groups named `rt-<class>` (not `open-rt-<class>`, which requires ground truth `X`); rows that would move refuse → allow keep their recorded verdict, and each precision move is declared in the fragment and pinned by an arm | D-GroundTruth, `#8898 comment 6864573397` |
| DEV-5 | 5 | #8491 re-sized S → M; the release is 26 raw / 30 effective points (a third G3-15 exception) | D-Size, `#8898 comment 6864573397` |
| DEV-6 | 5 | The Outcome limb for #8320 reads "reads an interpreter and its operand across a line continuation as one command" (Amendment 1 on #8940 adds a second walk rather than joining segments) | Collective Review, `#8898 comment 6864573397` |
