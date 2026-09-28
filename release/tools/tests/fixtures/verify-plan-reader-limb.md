<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic
     release-plan test data (the parser groups checks by their #N headers), not
     references to real work items. -->
# vTEST Release Plan — a limb the verifier does not grade never leaves a row at plain PASS

> Fixture for `release/tools/tests/test_verify_release_plan.sh`, arms V6837-AC4r and
> V6848-AC2u (group G22). Every command reads this file, and every pattern is written
> with a bracketed hyphen, so no method cell matches its own pattern: the counts come
> from the data section at the end, where each of the two tokens appears twice. A null
> whose pattern would match its own cell reads the sibling multi-limb fixture, which
> carries none of those strings (G22-0 checks it). #990 declares reader-graded limbs,
> #991 names spans the tool catalog does not, #992 binds a one-command row's comparator
> to the command it follows, and the CIACs carry the same shapes on the cross-issue route.

## Verification Plan

**#990 — a limb no command grades is declared, never described**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the record states its runs used the pinned instrument] | the designated command holds and the reader limb is named, never run: the can't-run slot |
| AC-2 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the record states its runs used an unpinned instrument] | the reader limb's content is false, and the verifier cannot grade it: the same slot |
| AC-3 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 3. [READER-GRADED — the record states its runs used the pinned instrument] | a false first limb: FAIL, with the reader limb listed |
| AC-4 | `grep -c -E 'BETA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 0. [READER-GRADED — a control arm on the same file reads at least 1] | a violated null: the window ends at the marker, so the reader text does not grade the command: FAIL |
| AC-5 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. Record limb: the record states its runs used the pinned instrument | an undeclared prose limb is invisible: PASS on the command alone |
| AC-6 | [READER-GRADED — the record states its runs used the pinned instrument], then `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 | a marker before the command is limb 1: the slot |
| AC-7 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the first claim] and [READER-GRADED — the second claim] | two markers, two limbs: the slot, limbs run 1 of 3 |
| AC-8 | [READER-GRADED — a reader reads the whole claim in the record] | a marker alone names nothing to run: the no-command SKIP |
| AC-9 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the record states its runs used the pinned instrument], verification deferred to the Stage 8 reader | a declared deferral still wins: declared-deferred SKIP |
| AC-10 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2; paired `grep -c -E 'BETA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the record states its runs used the pinned instrument] | a second command and a reader limb: both named, in order |
| AC-11 | `grep -c -F '[READER-GRADED — pattern' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 0 | quoted, a marker is the command's pattern and declares nothing: PASS |
| AC-12 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the reader compares the count with `grep -c -E 'BETA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md`] | a command quoted inside the marker is a command of its own: named, never passed |
| AC-13 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [reader-graded — the record states its runs used the pinned instrument] | lower case declares too: the slot |
| AC-14 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the record states its runs used the pinned instrument | no closing bracket declares too: the slot |
| AC-15 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` [READER-GRADED — the record states its runs used the pinned instrument] expect 5 | the only comparator sits in the reader limb: ERROR comparator-in-reader-limb, never the exit status |
| AC-16 | Runnable limb: `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` — expect exactly 2, one literal data line per token. Structural limb [READER-GRADED — a reader reads the frame]: read the frame from `core/packs/scrum/pack.toml` and `core/packs/kanban/pack.toml` with a TOML parser — every check at `level = "L3"` plus every check at `level = "L2"` with `automatable = false` — and assert the Appendix A.4 binding ids set-equal to it, every binding's base token an A.3 block, and every real base item named in § Provenance. Record limb [READER-GRADED — a reader reads the record]: the record states that the reproducibility test's runs were executed against the pinned instrument, under a `## Limitations of the instrument as run` section | the originating shape, declared: the slot, limbs run 1 of 3 |
| AC-17 | Runnable limb: `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` — expect exactly 2, one literal data line per token. Structural limb: read the frame from `core/packs/scrum/pack.toml` and `core/packs/kanban/pack.toml` with a TOML parser — every check at `level = "L3"` plus every check at `level = "L2"` with `automatable = false` — and assert the Appendix A.4 binding ids set-equal to it, every binding's base token an A.3 block, and every real base item named in § Provenance. Record limb: the record states that the reproducibility test's runs were executed against the pinned instrument, under a `## Limitations of the instrument as run` section | the originating shape as authored, undeclared: PASS on the command alone |
| AC-18 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 then a stray ` and [READER-GRADED — the record states its runs used the pinned instrument] | a marker after a stray backtick is prose, and declares: the slot |
| AC-19 | Expect exactly 3 from `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md`. [READER-GRADED — the record states its runs used the pinned instrument] | a comparator written before the command, reader text cut: FAIL, with the reader limb listed |
| AC-20 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER GRADED — the record states its runs used the pinned instrument] | a space for the hyphen declares too: the slot |
| AC-21 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER–GRADED — the record states its runs used the pinned instrument] | an en dash for the hyphen declares too: the slot |
| AC-22 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADE — the record states its runs used the pinned instrument] | a truncated word declares too: the slot |
| AC-23 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 3. [READER-GRADED — DEFERRED to the Stage 8 reader] | a reader limb whose text says DEFERRED defers the whole row, and its false command never runs: declared-deferred SKIP |
| AC-24 | [READER-GRADED — the reader compares with `grep -c -E 'BETA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md`] then `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 3 | the command quoted inside a leading marker is the designated command, and the author's false command does not run: never PASS |
| AC-25 | `grep -c -F 'READER-GRADED' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 0; stage-04 documents the [READER-GRADED — <what a reader grades>] form | an unbackticked mention declares a limb: the slot |
| AC-26 | `grep -c -F 'READER-GRADED' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 0; stage-04 documents the `[READER-GRADED — <what a reader grades>]` form | a backticked mention declares nothing: PASS |
| AC-27 | Runnable limb: `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` — expect exactly 2. **Second limb is READER-GRADED:** whether the two data lines say the same thing is a read the executor cannot run | the author's bare upper-case word declares the limb: the slot |
| AC-28 | **READER-GRADED BY DECLARATION — no runnable command is present in this row, deliberately.** The read: the data section of this fixture | a declared limb with no command: the no-command SKIP |
| AC-29 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. The second limb is Reader-Graded by a person | mixed case is not the bare word: PASS on the command alone |
| AC-30 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. This row is not READER-GRADED | the accepted risk: a negation still declares, so the row reads the slot |

**#991 — a later span shaped as a command the catalog does not know**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` at least 1 and `rg -c "ALPHA" release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 | a catalogued tool beside the probe: named outside the verb set, never passed |
| AC-2 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` at least 1 and `/usr/bin/awk '/ALPHA/' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 | an absolute-path tool beside the probe: named not a recognised command, never passed |
| AC-3 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2, beside `level = "L3"` and `automatable = false` | field assignments are prose: PASS |
| AC-4 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2, beside `## Limitations of the instrument as run` | a heading is prose: PASS |
| AC-5 | `rg -c "ALPHA" release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 | a catalogued tool alone: UNRUNNABLE naming it |
| AC-6 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` at least 1 and `sed -n '1p' release/tools/tests/fixtures/verify-plan-reader-limb.md` | the catalogued twin: named outside the verb set |
| AC-7 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 beside `deploy --check non-clean (exit 1)` | the stated boundary: a quoted output line shaped as a command is named, a false demotion and never a pass |
| AC-8 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 beside `rg "ALPHA" release/tools/tests/fixtures/verify-plan-reader-limb.md` | a catalogued tool with no option: named, never passed |
| AC-9 | `git diff --name-only origin/main...HEAD -- core/skills/` expect 0 beside `rg -c "ALPHA" release/tools/tests/fixtures/verify-plan-reader-limb.md` | a scope assertion beside a catalogued tool: the slot |
| AC-10 | `git diff --name-only origin/main...HEAD -- core/skills/` expect 0. [READER-GRADED — the reader confirms at most 2 skill files moved] | a scope assertion beside a reader limb: the slot, not an ambiguous comparator |
| AC-11 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 then `rg -c "ALPHA" release/tools/tests/fixtures/verify-plan-reader-limb.md | a span no backtick closes is prose: PASS |
| AC-12 | `/usr/bin/awk '/ALPHA/' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 | an unrecognised span alone stays a method with no command: the no-command SKIP |
| AC-13 | `git diff --name-only origin/main...HEAD -- core/skills/` [READER-GRADED — the reader confirms at most 2 skill files changed] | the only comparator sits in the reader limb, so the row routes on none: UNRUNNABLE naming git |
| AC-14 | `/usr/bin/awk '/ALPHA/' release/tools/tests/fixtures/verify-plan-reader-limb.md` then `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 | written before the probe: named, never passed |
| AC-15 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 and `./release/tools/claim-version --check` | a relative path with no script suffix: named, never passed |
| AC-16 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 and `/usr/bin/grep -c -F "NO-SUCH-TOKEN" release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 1 | an absolute path to an allowlisted verb: named, never executed |
| AC-17 | `grep -c -E 'BETA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 0; then `/usr/bin/awk '/BETA/' release/tools/tests/fixtures/verify-plan-reader-limb.md` at least 1 | a violated null beside an unknown span with a comparator of its own: FAIL |
| AC-18 | `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2 and `fd -e md release/tools/tests/fixtures` | a word followed by an option: named, never passed |

**#992 — a one-command row is graded on the comparator written after its command**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `grep -c -E 'BETA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 0; a control arm on the same file reads at least 1 | two comparators after the command disagree: ERROR, never a pass of the violated null |
| AC-2 | `grep -c -E 'BETA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2; a prose arm reads at least 5 | two comparators after the command disagree: ERROR |
| AC-3 | Expect exactly 2 from `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` | a comparator written before the command still grades it: PASS |
| AC-4 | `grep -c 'at least 9' release/tools/tests/fixtures/verify-plan-multi-limb.md` expect 0 | a comparator phrase inside the backticks is the pattern: PASS |
| AC-5 | Expect exactly 3 from `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` | control: a false comparator before the command FAILs |

## Cross-Issue Acceptance Criteria (fixture-scoped)

- [ ] **CIAC-1 (#990 × #991 on `fixture`):** a reader limb on a cross-issue criterion. *Method:* `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. [READER-GRADED — the record states its runs used the pinned instrument]
- [ ] **CIAC-2 (#990 × #991 on `fixture`):** an undeclared prose limb. *Method:* `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2. Record limb: the record states its runs used the pinned instrument
- [ ] **CIAC-3 (#990 × #991 on `fixture`):** a catalogued tool beside the probe. *Method:* `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` at least 1 and `rg -c "ALPHA" release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2
- [ ] **CIAC-4 (#990 × #991 on `fixture`):** a scope assertion beside a catalogued tool. *Method:* `git diff --name-only origin/main...HEAD -- core/skills/` expect 0 beside `sed -n '1p' release/tools/tests/fixtures/verify-plan-reader-limb.md`
- [ ] **CIAC-5 (#990 × #991 on `fixture`):** a scope assertion beside a reader limb. *Method:* `git diff --name-only origin/main...HEAD -- core/skills/` expect 0. [READER-GRADED — the reader confirms at most 2 skill files moved]
- [ ] **CIAC-6 (#990 × #991 on `fixture`):** an absolute-path tool beside the probe. *Method:* `grep -c -E 'ALPHA[-]TOKEN' release/tools/tests/fixtures/verify-plan-reader-limb.md` at least 1 and `/usr/bin/awk '/ALPHA/' release/tools/tests/fixtures/verify-plan-reader-limb.md` expect 2
- [ ] **CIAC-7 (#990 × #991 on `fixture`):** control after the planted entries. *Method:* `test -f release/tools/tests/fixtures/verify-plan-reader-limb.md`

## Fixture data (read by the commands above; not a verification table)

ALPHA-TOKEN first line
ALPHA-TOKEN second line
BETA-TOKEN first line
BETA-TOKEN second line
