---
title: "ADR-209 — The runtime-suite selection map names one glob grammar and its reference resolver, and has rows for the suites it exists to select"
status: Accepted (rendered by the operator at the Stage-5 D-6876 gate as decisions D33 and D34, with the Collective Review's reading of the map's outcomes, D37; this file records them)
date: 2026-09-25
release: verifier-grades-what-plans-declare
deciders: "Workspace owner (operator), rendering the Stage-5 D-6876 gate as decisions D33 and D34 against the Stage-5 design and its Phase A6.5 adversarial review, whose fixes the operator adopted with the gate, and the Collective Review scope-lock as decisions D37 (the outcome reading) and D43 (the cross-release coupling) + the Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + the Stage 6 Engineering spoke that recorded them"
tags: [architecture, release-pipeline, runtime-suite-selection, glob-grammar, reference-resolver, precedence, per-path-runner, self-test, no-match-fallback, reversibility-cheap]
supersedes: none
source_observations:
  - "At the Stage-5 pin, read with real glob semantics — a single * never crosses / — the map's tool row reached 0 of the 17 tool test suites under release/tools/tests/ and 0 of the 8 skill scripts under core/skills/*/scripts/. Read with fnmatch, where * crosses /, it reached all 17 suites and 5 runnable fixtures besides. For core/deploy/**, fnmatch, PurePath.match, Path.glob and git's pathspec with the glob magic word selected 201, 9, 0 and 201 tracked paths. Measured by the Stage-5 design and reproduced by its Phase A6.5 review through different commands."
  - "The pre-change selection rule (evaluate rows top-to-bottom; the most-specific glob wins) contradicted the table it governed: row 2 (core/deploy/**) sat above row 4, so under any real-glob resolver the 45 top-level core/deploy/tools paths matched both and top-to-bottom picked the broader row. 47 runnables matched more than one row at the pin and 49 after the change, with 0 ties under the longest-literal-prefix rule."
  - "One selected suite read its inherited stdin: fed two lines, it consumed both, and a read-loop over the 14 shell suites under release/tools/tests/ ended after 2 of them while every suite it did run passed. With stdin on the null device the same loop reached 14 of 14. None of the 8 skill scripts consumed stdin. Measured by the Phase A6.5 review (its FM-1)."
  - "PR-2, measured by the Phase A6.5 review: the grammar as first drafted and git's :(top,glob) pathspec selected the same set for all 19 patterns of the proposed table, but a leading ** split them — **/tests/*.sh selected 0 tracked paths under a literal implementation of the drafted grammar and 82 under git, which reads a leading **/ as 'in every directory'."
  - "PR-2, re-measured at Stage 6 with git's pathspec over a change set holding every tracked path: a ** that shares its segment is resolved by its position, which git's documentation calls invalid — release/tools** selects 159 paths while release/tools* selects 0 — and a wildcard-free directory name selects every path below it, as core/deploy selects the same 201 paths core/deploy/** does. Forbidding the non-segment ** placements, and stating the directory reading, leaves git conformant on every pattern the column admits."
  - "FM-2, measured by the Phase A6.5 review: row 5's core/*.template matched 9 tracked paths under fnmatch and 2 under the grammar. Of the 7 that left, the two config templates under core/config/ matched no row at all and 5 hook templates resolved to row 3 alone; the config templates have runtime readers that row 5's suite exercises."
  - "Re-measured at Stage 6 on the map as landed, with git's pathspec over a change set holding all 2,087 tracked paths: the 17 release suites and the 2 deploy-tool suites select row 6, the 8 skill scripts select row 7, the 5 runnable fixtures select no row, no path ties, and a match-nothing control pattern selects 0. Against the pre-change map read by fnmatch, 91 paths change their row, in 9 classes: 45 top-level core/deploy/tools paths resolved to row 4 by precedence, 17 release suites from row 4 to row 6, 9 nested release/tools paths from row 4 to no row, 8 skill scripts newly selected by row 7, 5 hook templates from rows 3 and 5 to row 3, 2 row-1 files resolved to row 1 by precedence, 2 deploy-tool suites from rows 2 and 4 to row 6, the 2 config templates kept on row 5, and 1 deploy-tool fixture from rows 2 and 4 to row 2."
  - "The provider usage connector was the only one of the 8 skill scripts with no --self-test: it exited 2 on the flag at the Stage-5 pin and at the parent of this record's slice. With the self-test it passes 5 assertions offline, and two seeded failures — an unknown argument that exits 0, and an enabled path that prints the key — each make it fail with its own named assertion."
---

# ADR-209 — The runtime-suite selection map names one glob grammar and its reference resolver, and has rows for the suites it exists to select

## Status

**Accepted.** Rendered by the operator at the Stage-5 D-6876 gate as decisions D33 (option A, with the Phase A6.5 review's fixes) and D34 (the fallback cited by role, with the new rows numbered 6 and 7 and the fallback row 8). The Collective Review then adopted the design's reading of the map's outcomes in the release's outcome vocabulary (D37) and recorded the map's coupling to a sibling milestone's widening of the same globs (D43). Recorded at Stage 6 Engineering for the `verifier-grades-what-plans-declare` release, in the slice that lands the map change.

**Numbering provenance.** Claimed as **209** against an anchor of **206** on the mainline, read from the repository's own ADR-numbering tool at authoring, with **207** and **208** already held on this release's branch by {{ADR:a-rows-grading-route-is-declared-in-its-method-cell}} and {{ADR:a-method-the-verifier-cannot-run-is-reported-unrunnable}}. The number binds at the Stage-12 claim, and in-release prose cites this record by its slug token.

## Context

The runtime-suite selection map routes a changed path to the test suite that exercises it, and three stages read it: Engineering self-verification, the Dev Testing runtime-suite gate, and acceptance at Stage 8. It named no glob grammar and no resolver. Read with real glob semantics, where a single `*` never crosses `/`, its tool row reached none of the tool test suites and none of the skill scripts it exists to select; read with Python's `fnmatch`, where `*` crosses `/`, it reached the suites and several runnable fixtures besides. No consumer could honour "the resolver the consumer uses", because none was named, and the difference was silent: a suite that cannot be selected produces no error, only an absent selection.

Its precedence rule — evaluate rows top-to-bottom, the most-specific glob wins — also contradicted its own table, which placed a broader row above a narrower one. And once a row fills in its runner from the matched path, a runner that reads its inherited input can end a caller's loop over the selected suites early, with every suite it did run passing. The measurements behind each point are in `source_observations`.

## Decision Drivers

- **Measured reach**, as of the D33 decision: under real glob semantics the tool row selected none of the tool test suites and none of the skill scripts.
- **Several matchers, several maps**, as of the D33 decision: `fnmatch`, `PurePath.match`, `Path.glob` and git's pathspec each read the map's `**` rows differently.
- **ADR-119's discovery boundary.** Bare-invocation suites are not folded into `--self-test` discovery (its decision 6), and the tool row's globs are that gate's scope directives, so the tool row cannot simply be widened.
- **A per-path runner needs per-path guarantees.** A row whose runner is the matched path itself must say what happens to a runner that reads stdin, to a deleted path, and to a member the runner does not fit.

## Decision

1. **One glob grammar, and a reference resolver that implements it.** The map states the grammar: `*` matches inside one path segment and never crosses `/`; `?` and `[...]` match one character other than `/`; `**` is written only as a whole path segment — `/**/` for zero or more directories, a trailing `/**` for every path below a directory — and a leading `**`, or a `**` that shares its segment with another character, is never written in the column; every other character matches itself, and a wildcard-free pattern that names a directory covers every path below it. The reference resolver is git's pathspec with the `top` and `glob` magic words, applied to the change set with `--no-renames`, so both sides of a rename and a deleted path are seen and the answer does not depend on the working directory. Three matchers that do not conform are named: `fnmatch` (or a pathspec without the `glob` magic word), `PurePath.match`, and `Path.glob` over the checked-out tree.
2. **Precedence is the longest literal prefix.** When more than one row matches a path, the row whose matching pattern has the longest literal prefix — the characters before its first wildcard, or its full length when it has none — wins, and rows that tie are all selected. Row order does not decide.
3. **Rows for the suites the map exists to select.** Row 6 covers the tool test suites directly under `release/tools/tests/` and `core/deploy/tools/tests/`, `*.sh` and `*.py`, one level deep, and runs each matched suite by its own bare invocation. Its patterns are the `TEST_SUITE_GLOBS` of the self-test coverage engine's Arm D, verbatim, so a change to either is a visible decision on both (D43). Row 7 covers the skill scripts under `core/skills/*/scripts/`, and runs each through `--self-test`, only on a script that ADR-119's advertise predicate accepts; any other matched script is a named gap in the map, never an invocation. The provider usage connector gains an offline `--self-test`, so row 7's runner fits every current member.
4. **Every selected runner runs with stdin on the null device**, and the per-path runner forms carry the redirect. A matched path the change deletes records `test-run/suite-skip` with a named reason rather than invoking a missing file. The Sandbox cell of rows 6 and 7 is a membership rule: a member must be hermetic or read-only, and one that is not gets a row of its own.
5. **The last row is the explicit no-match fallback, and every consumer cites it by role** (D34): "the last row is the explicit no-match fallback". Rows 1–5 keep their ids; the new rows are 6 and 7 and the fallback is row 8. A path that carries runtime behaviour and still lands in the fallback is a gap in the map, not a no-op.
6. **Each outcome of the map has one reading in the plan verifier's vocabulary** (D37): a suite that passes reads PASS; a suite that fails reads FAIL; a change that runs no suite — the no-match row, a deleted matched path, or a row-7 script with no self-test — reads a named SKIP, carrying its reason; and a runner error, where zero units executed, reads can't run here (UNRUNNABLE), in the vocabulary of {{ADR:a-method-the-verifier-cannot-run-is-reported-unrunnable}}.

## Alternatives Considered

- **Widen the tool row to recursive globs.** Rejected: the tool row's globs are ADR-119's scope directives, so widening them folds bare-invocation suites into `--self-test` discovery, which that record's decision 6 rejects by name; the row's runner would still never execute a bare suite, and the widened globs pull in runnable fixtures named after real tools.
- **Add rows but name no resolver.** Rejected: "verified with the same resolver the consumer uses" stays unsatisfiable while no consumer names one, and the plausible readings diverge on the new rows themselves.
- **Name a Python matcher as the resolver.** Rejected: `PurePath.match` anchors at the right and reads `**` as `*`, so it silently shrinks rows 2 and 3; `Path.glob` finds no deleted path and, on some Python versions, no file below a trailing `**`.
- **A committed resolver tool that parses the map and selects suites.** Rejected: a new production tool and a second parser over a markdown table, where an extended contract satisfies the card.
- **Write the connector's usage contract into row 7 instead of giving it a self-test.** Not chosen (D33): the contract would live in two places, the map and the script.
- **Bring the skill scripts into ADR-119's self-test discovery.** Not chosen (D33): it widens a gate's declared scope, touches every conditional row the plan pre-registered, and contends with a sibling milestone on the smoke workflow's trigger block.
- **Adopt git's leading-`**/` rule into the grammar** (the other form PR-2 offered). Not chosen: git documents every other placement of `**` as invalid and resolves such a pattern by its position, as `source_observations` records, so adopting the one rule would still leave git and a conformant matcher reading those placements differently. Forbidding every non-segment placement is the form under which git conforms on every admitted pattern.
- **Cite the fallback by number** (the gate's sub-choice ii). Not chosen (D34): every citation would re-cascade the next time a row is added.
- **Keep the fallback at id 6 and number the new rows 7 and 8** (the review's counter-design). Not taken (D34): the ids would no longer run in order, for a benefit the by-role citation already gives.
- **Give the connector's self-test a CI executor in this release**, by adding it to the skill's existing smoke-workflow roster (the review's PR-1). Not taken (D33): that region of the smoke workflow lies outside the boundary this release drew; it is a follow-up.
- **Record a no-match on a runtime path as a distinct finding, and require one `test-run` event per selected path with a shortfall read as an infrastructure warning** (the design's residue and the review's FM-1 mitigation 5). Not taken (D37).

## Consequences

- **Positive:**
  - A change to a tool test suite or a skill script selects the suite that exercises it, and the runner that row names executes it.
  - The map has one reading: a new row can be checked against the reference resolver, and a verification that uses a non-conformant matcher is visibly measuring a different map.
  - Selection no longer depends on row order, and a per-path runner cannot end a caller's loop early or invoke a missing file.
  - A miss is nameable: a runtime path in the fallback is a gap, and a row-7 script with no self-test is a named gap.
- **Negative:**
  - The connector's new self-test has no CI executor yet; a follow-up gives it one.
  - Conformance between the grammar and the resolver is established at each verification by the resolver run, not by a committed test; a durable map-coverage check is a follow-up.
  - A change to a fixture, a library or a tool still selects no suite that reads it: a path-keyed row cannot express which suites read an input.
  - A no-match on a runtime path still reads as a named SKIP, the same as a documentation change (D37).
  - Historical prose that calls the fallback "row 6" now names the tool-test-suite row. That prose is historical record; the fallback's event payload stays `selected-by:no-match`.

## Reversibility

**CHEAP.** A revert restores the map, the three stage specs, the workflow comment, the connector, the exclusions line and the prior package bytes; rows 1–5 keep their ids, so historical `selected-by:glob-N` events still resolve. No data or event schema changes.

## Related ADRs

- ADR-119 — self-test coverage is discovered against a declared scope. Its decision 6 keeps the `tests/` trees outside that scope, which is why row 6 is a row of its own; its advertise predicate decides which scripts row 7 runs.
- ADR-074 — Stage 8 consumes Stage-7 runtime evidence for a behavioral acceptance criterion, keyed on this map. Its mention of the fallback as "row 6" is historical record.
- ADR-075 — the plan-verification executor's shared contract. Its runtime-suite family emits a named SKIP and runs no suite, and is unchanged.
- ADR-062 — the substrate-versus-canonical precedent. The card's issue-body figures stay historical record.
- ADR-181 — ADR citations bind at the claim, not at authorship. In-release prose cites this record by its slug token.
- {{ADR:a-method-the-verifier-cannot-run-is-reported-unrunnable}} — the release's outcome partition, whose vocabulary Decision 6 reads the map's outcomes in.

## References

- #6876 — the card whose map, grammar and rows this record carries.
- #7672 — the ADR issue holding this record's decision set.
- #7614 — the Stage-5 design sub-task, carrying the D33 and D34 decision record.
- #7669 — the design's Phase A6.5 adversarial review, whose fixes D33 adopted: the per-path runner guarantees, the config templates on row 5, the grammar's agreement with its resolver, the offline self-test and the stale workflow comment.
- #7547 — the Stage-4 planning sub-task, carrying the Collective Review record (D37, D43).
- #7494 — the card whose slice edits the same two stage specs after this one, in line-disjoint regions.
- #7615 — the Stage-6 slice that recorded this file.
