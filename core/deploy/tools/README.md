---
title: core/deploy/tools/
purpose: Inventory and usage reference for the stdlib-only Python and bash primitives invoked by deploy.sh checks and their PR-time CI mirrors, and available for ad-hoc operator invocation.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# core/deploy/tools/

Stdlib-only primitives invoked by `core/deploy/deploy.sh` checks and by the
PR-time CI gates that mirror them, AND available for ad-hoc operator
invocation. The directory holds both Python tools and bash tools. The Python
tools run under `/usr/bin/python3` (system Python 3.9+; no virtualenv, no
external dependencies); the bash tools run under `bash`, and several are
`source`d as shared primitives rather than executed standalone.

## Inventory

**Coverage rule.** This inventory is **exhaustive**: every file matching
`core/deploy/tools/*.py` or `core/deploy/tools/*.sh` (top level only) carries
**exactly one** row below, keyed by its exact backticked basename. `tests/`
holds fixtures and test harnesses for these tools and is out of scope, as are
non-`.py`/`.sh` files. A tool added to this directory is not complete until its
row lands in the same change. Every row names its invoking consumer in
`Used by` — a tool with no automated caller records
`operator-only (no automated caller)` rather than leaving the cell empty.

**A new leg on an existing tool is an in-place cell edit, never a new row.**
When a tool already in the table gains a check leg, an invariant, a mode, or a
consumer, update that tool's existing `Used by` / `Mode(s)` / `Purpose` cells.
A second row keyed to a basename the table already contains breaks the
exactly-one-row invariant. Append a row **only** for a basename the table does
not yet contain.

**This file stores no tool count** — not in prose, not as an "as-of" figure,
not as a baseline date. A stored count is a fact that goes stale on the next
tool added; the rule is a fact that does not. Derive the count on demand
instead, and re-derive coverage at any commit with:

```bash
comm -23 \
  <(git ls-tree --name-only HEAD core/deploy/tools/ | grep -E '\.(py|sh)$' | xargs -n1 basename | sort) \
  <(sed -n '/^| Tool | Used by/,/^$/p' core/deploy/tools/README.md \
      | sed -nE 's/^\| `([^`]+)`.*/\1/p' | sort)
```

Empty output means coverage is complete; any line printed is an undocumented
tool. Separately, every tool listed in
`core/deploy/allowlists/selftest-coverage-manifest.txt` is run by the
`selftest-discovery` job in `.github/workflows/release-tooling-smoke.yml` —
that manifest is the authority for which tools that job reaches, so `Used by`
names the self-test job only where it is a tool's sole automated caller.

| Tool | Used by | Mode(s) | Purpose |
|---|---|---|---|
| `check-doc-links.py` | `deploy.sh` Check 14 + operator workflows + audit wrapper | broken-refs, rewrite-map | Doc-link drift detection + per-edit reference rewriting |
| `check-version-anchors.py` | `deploy.sh` Check 18 | structural | Verify version-anchor citations against current state |
| `check-doc-frontmatter.py` | `deploy.sh` Check 50 | structural (warn-mode across `core/`; enforce-flip deferred to the Tier-B/C backfill) | Validate platform-doc frontmatter per the platform-doc frontmatter standard: Tier-1 required fields + `type` singular enum + `framework_version_anchor`-IFF-cataloged + `consumers` for standard/schema/spec + `reversibility` tier-prefix |
| `_frontmatter.py` | `check-version-anchors.py` + `check-doc-frontmatter.py` (shared library) | library (not a check) | The single shared YAML-frontmatter block reader — the F1 consistency seam so Check 18b and Check 50 parse frontmatter byte-identically |
| `generate_release_index.py` | `deploy.sh` Check 23 (`--verify`); `automated-closeout.sh` phases 7/8/9.5 (`--emit`); `release-tooling-smoke.yml` `selftest-discovery` job (`--self-test`, reached by discovery — no roster); `release-executor` Mode E (Stage 13 close — `--verify` only) | `--emit {index,digest,changelog}` (one entry to stdout) / `--verify` / `--self-test` / `--output-stdout` read-only; **bare = destructive full regenerate** | **The release-corpus PROJECTOR** — the single writer of all three DERIVED ledgers (`RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, `CHANGELOG.md`) from their declared sources, per `release-corpus-schema.md` § Derived-Surface Contract. Clock-free and config-free by contract: both date anchors and the repo slug are REQUIRED CLI arguments. Emits **entries, never files** — a whole-file regenerate of the DIGEST or CHANGELOG destroys post-emission editorial content. **Stage 13 is append-only** — a bare invocation rewrites every row and restamps the grandfathered `Date` cells the INDEX header declares must not be rewritten (`release-process.md` § D6 / CR-D6). *Module name understates scope; accepted debt, rename is a legitimate follow-on.* |
| `lint_release_corpus.py` | `deploy.sh` Check 20 + `automated-closeout.sh` phases 9.2/9.3 (`--check note-content` / `--check plan-identity`); `release-tooling-smoke.yml` `selftest-discovery` job (`--self-test`, reached by discovery — no roster) | structural | Validate release-corpus filename regex (**SHAPE only** — that a name matches the canonical form, never that the version it names is the one the release shipped as) + frontmatter schema + type-coherence + note content + **plan-identity**. Plan-identity is the truthfulness question the shape check cannot answer: it joins each version-declaring plan filename to its `RELEASE_LOG.md` row and asserts, in the opposite direction, that every concrete-version row has a plan at its nested home. Sub-check (c) (INDEX row count) is **RETIRED, identifier reserved** — strictly weaker than Check 23's coexistence limb |
| `cross-module-audit.sh` | Module-restructure audit + operator | audit (read-only) | Cross-module extraction-readiness audit; bash entrypoint |
| `cross_module_audit_helper.py` | Invoked by `cross-module-audit.sh` | audit (read-only) | Imports check-doc-links primitives; classifies cross-module refs by 6 directionality rules + 3 cross-ref-types; emits TSV + markdown report |
| `stamp-node-frontmatter.py` | Operator + Layer-2 Stage-12 backfill | dry-run (default) / stamp | Classify-and-stamp the 11-field node-frontmatter core onto the operational corpus (the vertices of the doc warehouse); folder→domain classification, idempotent, `.meta.yml` sidecars for non-md files |
| `backfill-relationship-edges.py` | Operator + Layer-2 Stage-12 backfill | dry-run (default) / emit (gated) | Backfill `relationships[]` edges (the edges of the doc warehouse) — `BELONGS_TO` always-safe + evidence-anchored `GENERATES`/`DEPENDS_ON`; imports the node tool's classifiers for F1-consistent project derivation |
| `build-doc-index.py` | Operator + the lifecycle-automation incremental caller | rebuild / update-file / query / self-test | Materialize the disposable document-ecosystem SQLite index (`sqlite-index-schema.md`) from node frontmatter + edges — all 7 tables + FTS5 + the 7 named reference queries; deterministic byte-identical rebuild |
| `check-milestone-epic-membership.py` | `deploy.sh` Check 56 (warn-mode; enforce-flip deferred); `release-tooling-smoke.yml` (`--self-test`); `hub-spoke-bridge.md` Procedure 1 Step 6.5 (`--milestone … --leg M3`) | `--leg {M1,M2,M3,M4,all}` / `--milestone` / `--fixture` / `--self-test`; TSV out | Milestone↔issue-population invariants across legs at **deliberately different severities** (the leg list here is the authority — no count is stated, because a count goes stale the next leg that lands). **M1 membership** — every open non-sub-task child of an epic-declaring milestone must sit under that epic; enforce-capable. **M2 reconciliation** — the description's `### Scope` card list vs live membership; the **ADVISORY** emitter class, routed through `flag_advisory_only` under its **own** check_id `milestone-description-reconciliation`, because a description legitimately lags membership mid-release. Structurally non-gating twice over — the emitter has no mode branch and no failure-counter increment, and the id it names is disjoint from the `milestone-epic-membership` dial M1 graduates through, so a flip of that dial cannot reach M2. Each `named-not-member` ref carries exactly ONE inline bracketed sub-class token — `[elsewhere:ms#N]` · `[no-milestone]` · `[member-excluded:sub-task]` · `[unresolved]` — summarized by `COUNT_M2_NNM` plus one sub-counter per token, which sum to it. **Read the counters with `awk` exact field equality**: a `grep` for `COUNT_M2_NNM` prefix-collides with all four sub-counters. `unresolved` is a positively-emitted unknown, never a default — the ref→milestone overlay is tri-state (`{ref: n}` / `{ref: None}` / key absent), and `M2_REF_RESOLUTION` reports `fetched` vs `degraded` so a dead resolver is distinguishable from a population that genuinely could not be resolved. **M3 scaffold completeness** — advisory-only structurally, routed through `flag_advisory_only`, and never moves the exit code. **M4 sub-task milestone orphans** — a pipeline sub-task carrying **no milestone at all**, which is invisible to every milestone-scoped query the pipeline runs, including this check. WARN-capable with a real enforce path, on its **own** dial (`milestone-subtask-orphan`, committed default `warn`) so a graduation of the shared cohort cannot flip it by side effect; it is *not* advisory, because M2's and M3's advisory rationale is a legitimate state their predicates cannot distinguish from a defect and M4 has none. Repository-scoped, so it is a distinct leg rather than an extension of M3, whose orphan class is evaluated per-milestone by matching the slug inside the title and is therefore structurally blind to a sub-task naming no slug. Counted with `search/issues` `total_count`, **never** through the stage-title fetcher — that fetcher reads through the search API's 1,000-result retrieval cap and would report the count it can see rather than the count that exists. Emits `COUNT_M4` plus `COUNT_M4_OPEN` + `COUNT_M4_CLOSED`, which sum to it; **read them with `awk` exact field equality**, since a `grep` for `COUNT_M4` prefix-collides with both sub-counters. Gates on the **OPEN** subset only — a closed sub-task's missing milestone is history, not drift. `M4_SCAN <status> <total> <enumerated>` is five-valued (`fetched` · `truncated` · `degraded` · `fixture` · `not-run`); on `degraded` and `not-run` the counters are **omitted rather than zeroed**, and `not-run` is emitted positively on the milestone-scoped path so a consumer never reads "never looked" as "found nothing". Per `review-discipline-principles.md` § 8 PV-7: `degraded` and `not-run` are Register A statuses, the counters are ABSENT rather than zeroed, and a consumer MUST branch on the status before reading any counter. M1/M2 exclude sub-tasks; M3 and M4 count them, because the scaffold is their subject. Exit 0 no M1/M2 findings · 1 findings present · 3 input failure. M3 and M4 never move the exit code |
| `check-work-hierarchy.py` | `deploy.sh` Check 55 (warn-mode; enforce-flip deferred); `release-tooling-smoke.yml` `selftest-discovery` job (`--self-test`, reached by discovery — no roster) | structural (`--skip-backlog` = H1 only) / `--fixture-parent-map` / `--self-test` | Work-hierarchy drift detector, three invariants. **H1 (doc, offline):** no normative doc ASSERTS a banned parent tier (`Initiative` / `Roadmap`, per ADR-049 — neither is a container tier) above a licensed work-item kind, the kind vocabulary being DERIVED from `core/packs/*/pack.toml` at runtime, never hardcoded. **H1 scan scope:** all three platform modules — `core/`, `release/`, `operations/` — plus `core/CLAUDE.md.template`, which the tree walk cannot reach on its own because the walk filters on a `.md` suffix. `release/releases/` is EXCLUDED as the archival + generated release corpus, which legitimately narrates historical hierarchies. A configured scan surface that does not resolve is reported as a `SKIP H1` row, and an empty scan population exits 3 — a configured surface never contributes a silent zero. A chain inside a quoted or code span is CITED, not asserted, and is suppressed; the single-quote delimiter is boundary-anchored so a possessive or contraction does not mask the assertion around it. **H2 (backlog, needs `gh`):** no open `type:epic` issue has a `type:epic` parent; ONE batched paginated GraphQL query, never an N+1 loop; SKIPs offline. **H3 (coextension, advisory):** no open `type:epic` issue is really an initiative container — an issue coextensive with a whole `project:` family rather than with one thrust inside it, which H2 cannot see because such containers carry no epic-parent edge. Asserted as a three-way conjunction — family shape AND title coextension AND in-family fan-out — because the family shape alone is symmetric and matches every leaf epic in every family. Rides H2's single query (fields added to the existing selection set, no second call). **Advisory exit contract:** H3 findings are excluded from the exit-code total and can never fail a run in warn or enforce mode; every finding emits its matched slug tokens and in-family references as its own falsifiable evidence. A node set lacking H3's `labels`/`title`/`body` triple exits 3 rather than reporting a vacuous zero, and a skipped leg emits `SKIP H3` with no `COUNT_H3` row so NOT-EVALUATED is never read as zero (§ 8 PV-7 Register B). |
| `build-hook-registry.py` | `deploy.sh` deploy-time regeneration (direct invocation, best-effort — **not itself a check**); `deploy.sh` Check 38 verifies its output stayed fresh | (bare) write the index / `--check` (regenerate-and-diff) / `--stdout` / `--output` / `--self-test` | Assembles the GENERATED index `core/rules/bypass-mode-readiness.md` from the per-hook + cross-cutting source fragments under `core/rules/bypass-mode-readiness/`. The `The Hooks` table is emitted one row per per-hook fragment in lexicographic order, which makes undercount structurally impossible — the failure mode a hand-maintained registry produced. Deterministic: same sources always yield byte-identical output (no timestamps). Fragments name-prefixed `_` are cross-cutting and are NEVER treated as per-hook sources. Exit 0 success / in-sync · 1 `--check` found drift · 2 usage · 3 source-resolution failure (fail loud rather than emit a partial index that would read as a clean smaller file) |
| `build-skill-packages.sh` | `release/tools/automated-closeout.sh` (`rebuild_skill_packages` phase); `release/tools/claim-version.sh` (claim-time stamp pre-flight, `--root`-pinned to the sandbox); operator. `deploy.sh` Check 7 and `.github/workflows/skill-package-freshness.yml` NAME it as the remediation command but do not invoke it | (bare) all skills / `<skill> …` named skills / `--skills-for-paths` (stdin paths → skills; read-only query, never builds) / `--root <path>` | Builds each `.skill` archive from its source tree, injecting the canonical `core/standards/template-*.md` + `operations/templates/*` files per the `TEMPLATE_SYNC_MAP` extracted from `deploy.sh` at runtime — so the source tree carries no per-skill mirror copies of the canonicals. `--root` exists because the script otherwise derives its repo root from its own location, which would make a sandboxed caller silently write into the real `packages/`. Exit 0 built (or query set emitted) · 1 canonical missing, source skill missing, or packager failure |
| `check-adr-flip.py` | `deploy.sh` Check 58 (`--root . --output-format tsv`) — routed through a warn-only emitter that has **no enforce branch** | `--root` / `--output-format tsv` / `--self-test`; TSV out | Reports each `status: Proposed` ADR carrying conditional flip-promise wording, with the matched pattern, the extracted ratifying-reference phrase, and the record's age in days (age is the actionable axis — an old promise is likelier stuck). **Structurally incapable of enforcement by design, not by default:** the ratifying reference is free text, so it can answer "does a flip promise exist while the record is still Proposed?" but never "is the flip OVERDUE?" — a `PROMISED` row is a question for a human, and a genuinely-pending ADR correctly reports here every run. The Stage-13 G-CL9 close criterion is the authority; this is the non-authoritative half of the pair. Exit **0 always**, findings or not · 3 input failure (no ADR files resolved — the tree moved) |
| `check-approved-queue-depth.py` | `deploy.sh` Check 53 (`--threshold <n> --output-format tsv`; warn-mode initial, enforce-flip deferred) | `--threshold` (default 5) / `--output-format {tsv,text}`; needs `gh` | Counts the open approved-but-unbundled queue — issues labelled `status: approved` with NO milestone — and at/above the bundling threshold emits an ACTIONABLE bundle-candidate summary (count + themes from `cluster:*`/`project:*` labels + best-effort priority), not a bare number. The threshold VALUE is owned by the Stage-3 bundle definition and referenced via `--threshold`, never redefined here. Label-derived priority is explicitly a heuristic (the canonical priority lives in a Projects field absent from the label set), so gaps are reported as unlabeled, never invented. Exit 0 below threshold · 1 at/above (a finding) · 2 usage · 3 `gh` unavailable or the issue set unreadable — a blind read must not green a possibly-full queue |
| `check-canonical-structure.sh` | `deploy.sh` Check 6 AND `.github/workflows/skill-canonical-structure-check.yml` (PR-time mirror) — both invoke THIS script, so the predicate cannot drift between them | (bare) scan the full roster / `--self-test` | The single-sourced Check 6 predicate. For every rostered skill asserts (a) required frontmatter `name`/`description`/`version`, (b) the D-Refs threshold — a non-empty `references/` subdir once SKILL.md exceeds 400 lines or 25600 bytes, and (c) the failure-mode floor of at least three entries matching the 5-category heading pattern. The roster AND the skill→module resolver are both extracted from the `deploy.sh` arrays at runtime, never hardcoded, so neither the iteration set nor the module map can drift from the roster authority. An exemption-list member is exempt from the D-Refs threshold only — the required-field check still applies. Exit 0 compliant · 1 FAILs (count in the summary line) · 2 usage · 3 scan-surface error (roster unextractable, or a roster skill's SKILL.md missing) — hard-fail regardless of posture, so a relocated source tree can never read green |
| `check-citation-anchors.sh` | `deploy.sh` Check 66 (fixtures via `--self-test`, then a bare live scan; warn-mode initial, enforce-flip deferred) | (bare) live scan / `--self-test` | Asserts no tracked `*.md` under the three skill roots locates a cross-skill referent by LINE NUMBER; the canonical form is a `§` segment carrying the target heading verbatim. The line-number form is the defect because it fails OPEN — every line number in a long file "resolves", so a citation that has drifted onto the wrong content is mechanically indistinguishable from a correct one, whereas a section name that no longer exists greps to zero. Two lexical forms are matched (`<basename>.md:NNN`, for any markdown basename, and a backticked bare line number) because narrowing to one was measured to miss live carriers, including an entire third carrier file. A match requires a literal digit run immediately after the colon, so prose documenting the convention via a placeholder (`<other-file>.md:NNN`) is structurally invisible and needs no exemption. Scope is a tree + file-type predicate rather than a filename glob, so a newly-created contract file is covered on creation. POSIX-portable with no `\b`, which silently returns zero on this platform's grep. Exit 0 no findings · 1 findings · 3 scan-surface error |
| `check-convention.sh` | `deploy.sh` Check 49 (warn-mode initial, so a finding annotates without blocking during the shakedown window) | (bare) scan | The platform-convention linter for the four residual dimensions no other gate owns: lowercase-kebab `[topic]-[type].md` naming across the authored-doc dirs; a git-tracked file whose PATH sits under `projects/` (a Layer-2 boundary violation); a governance file that makes a dated factual assertion yet carries zero evidence-quality labels anywhere; and unfilled bracketed-placeholder leakage outside backticks (a backticked placeholder is documentation OF the token and is exempt). Deliberately does NOT re-enforce dead-file-reference, depersonalization, issue-reference, localized-context, or internal-link integrity — each has an owning gate, and duplicate enforcement is governance debt. Emits `FAIL:`/`OK:` lines plus a trailing `SUMMARY: N finding(s)` |
| `check-count-structure.py` | `deploy.sh` Check 63 (`--root . --output-format tsv`; enforcing, narrowly scoped, frozen artifacts exempt) | `--root` / `--path` (repeatable; a directory argument scopes to that subtree, any other argument names a single file) / `--paths-from` (accepts both forms) / `--baseline` / `--no-baseline` / `--no-exempt` / `--include-inline` / `--emit-baseline` / `--output-format {tsv,human}` / `--self-test` | Asserts that a stated cardinality sitting immediately above an enumerable structure reconciles with that structure under at least ONE reading — identity, partition, or sub-count. Deliberately NOT "nearest numeral equals list length", which flags 129 mostly-correct pairs on this corpus. A pair is EXAMINED only when a colon-TERMINATED line carries a cardinal bound to a plural noun and the next non-blank line opens a list or table; four suppressors strip cardinals that are not counts of the adjacent structure. Runs BOTH control arms in-memory on every invocation and reports them beside the denominator, so "zero found" is always distinguishable from "nothing examined" (§ 8 PV-7; a run that measures NOTHING reports Register A `not-run`, and a PARTIAL read reports `degraded` — never a zero) — a broken or over-matching control arm is a hard failure regardless of caller mode. Pre-existing non-reconciling pairs ship in a line-number-free sha1-keyed baseline, so ordinary edits elsewhere in a file cannot invalidate an entry while editing a baselined preamble re-keys it and FAILs — which is exactly the moment to re-verify the count. Emits a `SCOPE` record carrying `status=` (`fetched` / `degraded` / `not-run`) and `state=` (`-` / `DEGRADED` / `NOT-EVALUATED`); a consumer must branch on `status=` before reading any counter. Baseline reconciliation is scope-relative — an entry outside the requested scope is reported in neither the KNOWN nor the STALE population. Exit 0 clean · 1 finding · 3 input failure, where a scope resolving to zero readable files is an input failure. |
| `check-enum-parity.sh` | `deploy.sh` Check 68 (fixtures via `--self-test`, then a bare live scan; warn-mode initial, enforce-flip deferred) | (bare) live scan / `--self-test` | For every (derived surface, field) pair registered in `core/deploy/allowlists/hub-state-enum-parity-map.txt`, asserts **A1 set equality** — the derived restatement and the standard section that owns the enum declare the same values, order-insensitively — and **A2 cardinality** — a `(N values)` parenthetical on the standard's heading equals the size of the set beneath it. A2 is a separate arm because A1 alone stays green when a correct value set sits under a stale count; the two fail independently because they can be wrong independently. Every finding names the DERIVED side and states the symmetric difference in both directions, because a bare "mismatch" reproduces the ambiguity that let a 3-of-6 divergence sit readable for months. Handles both live standard-side declaration forms, parses wrapped continuation lines, and skips fenced blocks when bounding a section — ignoring any of the three returns a value set the file does not declare. The registry IS the denominator, and its rows are printed in the DENOM line |
| `check-extraction-contract.py` | `deploy.sh` Check 57 (`--root . --output-format tsv`; warn-mode initial, enforce-flip deferred) | `--deploy-sh` / `--root` / `--output-format tsv` / `--self-test` | Asserts, ENTIRELY inside `deploy.sh`, that the check roster is discoverable two ways that agree — the published single-source extraction command depends on two conventions holding for every check, and a check that follows one but not the other makes that command silently under- or over-report. The invariant is `E == (D \ R)`, where D is the set of `# Check N` definition blocks, R the subset whose header is marked RETIRED, and E the set of runtime `log "Check N:"` emitters. Three violation classes: MISSING_EMITTER (a live check invisible to the documented command), MISSING_DEFBLOCK, and RETIRED_EMITTING (a reserved number contradicting its own reservation). Retirement is detected structurally from the header line, never hardcoded, so retired-reserved numbers cannot false-FAIL |
| `check-host-binding.py` | `deploy.sh` Check 42 (`--target-paths <globs> --allowlist core/deploy/allowlists/skip-host-binding-check.txt`) | `--target-paths` (comma-separated globs, `**` supported) / `--allowlist` / `--self-test` | Emits CANDIDATE host-binding leaks — `gh`, `git`, or a host API hardcoded as *the* canonical mechanism inside universal K1-tier governance, where the operation belongs behind the `operator.toml` adapters seam. Signal-not-verdict by contract: a candidate requires a prescriptive-mechanism marker AND a host token within roughly 40 characters with no sentence break between them (so the host tool is the OBJECT of the prescription, not an unrelated later mention), outside fenced code blocks, in a non-allowlisted file. The prescription-versus-teaching adjudication is the review act, NOT this scan — discipline-defining files that legitimately quote the pattern are allowlisted and worked examples in fences are skipped natively. Host-axis sibling of the path-portability leak class. Exit 0 ran · 3 a `--target-paths` glob resolved to zero files (a relocated or typo'd scan surface must not read green) |
| `check-identity-conformance.py` | `deploy.sh` Check 59 (`--root .`; warn-mode initial, enforce-flip deferred) | `--root` / `--self-test` | Window-gated slug-primary release-identity check: IN SCOPE only when the runner is on a `release/*` branch AND the release is still PRE-claim, detected by the unresolved `{{RELEASE_VERSION}}` token in its in-flight plan. Within scope it REJECTS a concrete `vX.Y` bound into either the branch name or the new-on-branch plan filename before the Stage-12 claim; off a release branch, or once claimed, it SKIPs cleanly, because absence is not drift. The claim-state token is the ONLY discriminator between a version-primary in-flight plan (FAIL) and a legitimately renamed post-claim plan — both are new-on-branch `vX.Y` files, and nothing else tells them apart. Re-implements no version parser. Exit 0 clean or SKIP · 1 finding · 3 context failure (git unavailable or `origin/main` unreachable — unverifiable, not clean) |
| `check-label-parity.py` | `deploy.sh` Check 51 (`--source core/specs/label-taxonomy.md` plus each `core/packs/*/pack.toml`, `--output-format tsv`; warn-mode initial, MISSING-leg enforce-flip deferred) | `--source` (repeatable; `.md` and `.toml` auto-detected by extension) / `--output-format {tsv,text}` / `--emit-fix` (read-only renderer, a separate flag because the check pins `tsv`); needs `gh` | Compares the canonical label registry — the UNION of the grammar doc's namespace patterns and the per-pack `[[labels]]` rows, so a relocated-but-live label resolves and does not false-orphan — against the live `gh label list`, at two asymmetric severities. **MISSING** (canonical label absent from GitHub) is ENFORCE-capable, because a gate referencing a non-existent label fails silently. **ORPHAN** (live label unregistered) is WARN only, since some are legitimately operator-local or pending registration; a live label is an orphan only if it matches neither a concrete registered label nor a registered namespace prefix. `--emit-fix` renders the `gh label` commands that would close the gap and runs none of them, in CREATE / RECONCILE / UNRESOLVABLE blocks — and exposes the asymmetry that a row live with the wrong colour is invisible to the name-only diff. Exit 0 clean · 1 findings · 2 usage · 3 a source unreadable or the union parsed to zero labels |
| `check-ownership-collision.py` | `deploy.sh` Check 54 (`--output-format tsv`; warn-mode initial, enforce-flip deferred) | `--entity-model` / `--output-contracts` / `--artifact-inventory` / `--output-format {tsv,text}` / `--self-test`; pure local parse, no `gh` and therefore no offline SKIP leg | Reconciles three EXISTING corpus surfaces against each other — the owning-agent matrix in `core/disciplines/project-entity-model.md`, the per-skill declarations in `core/schemas/per-skill-output-contracts.md`, and the rendering set in `core/specs/operational-artifact-inventory.md` — and escalates a would-be **second maintainer**. It creates no new ownership store. ESCALATE fires only when a `Maintains` cell resolves to two or more distinct maintainer skills, when a skill declares maintainer-write against an entity a DIFFERENT skill maintains, or when a rendering carries a maintain marker (renderings are ownerless by design). A producer or creator declaration NEVER escalates — "many producers, one maintainer" is the governed pattern. Write-class is produce-by-default, so the predicate is zero-escalate on the current suite by construction while keeping independent live teeth. Exit 0 clean · 1 collision · 2 usage · 3 input failure (a required corpus surface missing or unparseable) |
| `check-pv7-vocabulary.sh` | `deploy.sh` Check 69 AND the `pv7-vocabulary` job in `.github/workflows/repo-integrity.yml` (PR-time, pre-merge) — both invoke THIS script, so the predicate cannot drift between them | (bare) corpus scan / `--no-exempt` (prices the exemptions) / `--root <dir>` / `--self-test` | Asserts the PV-7a Register B **terminal** token carries its ONE sanctioned hyphenated spelling everywhere in the tracked corpus: an all-caps rendering separated by anything other than a single hyphen is an unsanctioned third spelling and FAILs. Case-sensitivity is the load-bearing discriminator, not a nicety — the corpus carries ~30 legitimate lowercase prose uses ("the arm was not evaluated") and snake_case identifiers (`flag_not_evaluated`), which is precisely why ADR-134 D2 reconciled to a form a grep can isolate; a case-insensitive predicate here would be unusable rather than merely noisy. The scan is **whole-corpus rather than changed-files** because the four emits that motivated it arrived by merging `main` into a release branch — relative to the PR base they were unchanged lines, so a changed-file gate would have gone green on the exact event. Counts SANCTIONED occurrences as a built-in control arm on every run and exits 3 when that count is zero: a zero-violation verdict is only readable if the extractor demonstrably reaches the token at all, which is this gate's most likely rot path. Covers spelling ONLY — not PV-7c's non-escalating emitter, PV-7a's "this is not a clean result" clause, or PV-7b's absent-not-zero counters. Exit 0 clean · 1 findings · 3 broken probe (not a work tree, zero files enumerated, or a dead control arm) |
| `check-registry-currency.sh` | `.github/workflows/skill-registry-currency-check.yml` (PR-time gate — `--self-test`, then a bare scan). It is the CI mirror of `deploy.sh` Check 5(d)'s ROW layer, which `deploy.sh` implements inline rather than by invoking this script | (bare) scan the live roster / `--self-test` | Asserts the registry's Configuration Items rows are CURRENT against the `deploy.sh`-declared skill roster, in both directions: every registry row name is rostered, every roster member has a row (asymmetry FAILs either way), and every row name resolves to a live SKILL.md. `deploy.sh --check` is never invoked in CI, so this workflow is the row layer's only automatic run surface. Roster authority is the `deploy.sh` per-module arrays extracted at runtime with the canary EXCLUDED — never a hardcoded list and never a filesystem walk, which sweeps the shared and template dirs plus the canary and is empirically wrong; the generalizable rule is to duplicate a PARSE, which fails loud, never a POLICY, which drifts silent. The field layer is deliberately NOT mirrored: it resolves its mode from an operator-instance file CI never has, so mirroring it would be a guaranteed no-op. Exit 0 current · 1 findings · 2 usage · 3 scan-surface error — ALWAYS hard-fail regardless of posture |
| `check-skill-count-imp.py` | `.github/workflows/skill-count-imp-check.yml` (PR-time gate over the added-lines delta — `--self-test`, then the detector). It is the mirror of `deploy.sh` Check 5(c), which `deploy.sh` implements inline rather than by invoking this script | `--files` (whole-file local-audit form) / `--scan-pair` (repeatable; scans injected delta content while attributing findings to the real repo path) / `--mode {imp,count,both}` (default both) / `--repo-root` / `--output-format {github,tsv}` / `--self-test` | Two forward-looking drift detectors with a RUNTIME-COMPUTED authority, so the gate self-updates as the roster grows. The **imp** detector flags any live legacy audit identifier on a skill-spec content line — that namespace predates the issue tracker and no longer resolves. The **count** detector derives the authoritative roster by PARSING the `deploy.sh` per-module arrays, NOT by walking the skills directories (a walk wrongly counts the shared and template dirs and re-introduces the deliberately-excluded canary); both the public framing and the directory framing are accepted as correct because the corpus and `deploy.sh` both use both, and a totalizing roster claim matching NEITHER is flagged. The claim shape is deliberately tight, because the corpus uses bare "N skills" pervasively for subtotals and other populations that must not fire. Delta scope is why pre-existing corpus rot and closed-issue history structurally cannot fire — a structural mitigation, not an exemption list. Exit 0 clean · 1 findings · 2 usage · 3 an unreadable declared file or an empty parsed roster |
| `compose-portfolio.py` | `release-tooling-smoke.yml` `selftest-discovery` job (`--self-test`, reached by manifest discovery) — its ONLY automated caller. Production runs are operator-driven through the `weekly-status-rollup` Section-6 write-back, which describes the composer and passes `--as-of=today` but names no basename, so there is no automated production caller | `--root` (required except under `--self-test`) / `--as-of` (ISO; the fixed form is scoped to `--self-test` only) / `--out` (rejects any path resolving under `projects/`; default stdout) / `--self-test` | Renders the `PORTFOLIO.md` sections deterministically FROM the per-project rollup entities' typed frontmatter fields, so the dashboard is composed from fields rather than hand-synthesized prose that can read green over a failing subsystem. Fourth link in the doc-warehouse chain (node stamp → edge backfill → SQLite index → this); it reads frontmatter rather than the index because the index's portfolio-rollup query returns document-ecosystem aggregates, not the project-health contract fields. Determinism is the load-bearing property: projects sorted by `project_id`, intra-field order is the authored frontmatter order, and NO wall-clock is rendered into the body — the staleness marker is a pure function of the `--as-of` anchor and `last_published` in business days, never `date.today()` mid-render |
| `path-leak-patterns.sh` | **Four** behavioral consumers, each of which evaluates the predicate: `deploy.sh` Check 43 (**`source`d, not executed** — the tracked-file surface), `core/hooks/block-gh-path-leak.sh` (the `gh` issue/PR-ops surface), `core/hooks/block-scope-segregation.sh` (the tracker-filing surface), and the release-hub pre-spawn brief scan (via `--scan-file`, over one rendered brief) | library (sourced) — exports the regex constants plus the `path_leak_line_is_exempt` / `path_leak_scan_line` predicates; `--self-test` / `--scan-file <path>` when run directly | The shared path-leak detection primitive. Defines three leak classes — MACHINE (an absolute machine path carrying a username segment), RAWROOT (a raw workspace root used outside the sanctioned default-expansion; DEFINED for reference but deliberately NOT in the active scan, since the canonical default resolves per-user and is portable), and INSTANCE_REL (a BARE relative operator-instance path with no home or root prefix — the originating leak class the other two miss) — plus the shared exemption predicate. Seam contract: the regex CONSTANTS and the PREDICATE are shared across all four consumers, while each consumer supplies its OWN corpus and its OWN file allowlist. **No username is exempt** — a home path is flagged whatever account name it carries, on both the `/Users/` and `/home/` forms, because a username can never distinguish a fixture from a real path. That claim is bounded by the segment shape MACHINE matches — a lowercase initial followed by one or more characters drawn **only** from `[a-z0-9._-]`: a capitalised or non-alpha initial, a single-character segment, and any segment whose run is interrupted by a character outside that class (an internal capital, for instance) are not matched. A pattern property predating the username removal. The per-line `path-leak: allow` marker is the sole content-level escape; a fixture or worked example that must carry a flagged form declares it |
| `check-issue-ref-validity.sh` | the `issue-ref` job in `.github/workflows/repo-integrity.yml`, which is a **required status check on `main`** — the gate's only production caller; plus `release-tooling-smoke.yml` `selftest-discovery` (`--self-test`, reached by manifest discovery). **Not** a `deploy.sh --check` leg, and deliberately so: it needs a base/head SHA pair and network issue resolution, neither of which a local `--check` run has — so this row's `Used by` names a CI gate rather than a Check number | `--base`/`--head` (added-lines delta; CI parity) / `--path` (whole-file; the local form that needs no workflow run) / `--resolver gh\|fixture` + `--fixture-map` / `--self-test` / `--equivalence <pre-sha>` | The Issue-reference validity gate, lifted out of the workflow job that used to carry it inline. Flags an issue reference in changed markdown that does not resolve to a real issue IN THIS REPO (404, redirect, a transfer to another repo, or a pull-request number), the deprecated legacy identifier, and a resolving reference placed outside a designated reference block with no inline provenance marker; honors the whole-file override, the path exemptions, and fenced code. Two seams, both forced rather than chosen: the input seam is what makes a verdict reachable without a workflow run, and the resolver seam is what makes a fixture suite hermetic, since three of the five verdicts are properties of the live issue graph. `--equivalence` materializes the pre-extraction body straight out of git — never a tracked copy, which could drift from what it claims to represent — and asserts identical REPORT TEXT in BOTH directions, since flagging fewer is a weakened gate and flagging more is a strengthened one; it carries a sensitivity control and a mutation arm, because a differ that cannot report DISAGREE cannot meaningfully report AGREE. Exit 0 no findings · 1 findings · 3 input/config failure |
| `run-count-structure-fixtures.sh` | `deploy.sh` Check 63 fixture-regression beat (**hard-fail on every mode**, and a missing or non-executable harness is itself a FAIL — the gate would otherwise assert nothing about the predicate's discrimination); also run standalone for manual verification | (bare) run the committed fixture file / `[fixture-file]` positional override | The Check 63 labeled expected-match harness. Asserts every FLAG case is flagged, every CLEAN case is examined AND not flagged, and every SCOPE-OUT case is examined ZERO times. The three verdicts exist separately because "not flagged" and "not examined" are different results: a specificity arm whose input was never read returns zero, which is that arm's PASS condition and therefore reads as a passing control while proving nothing. A 0-byte case body fails for the same reason. Shared by manual verification and the automated beat so both surfaces measure the same thing. Exit 0 all cases pass · 1 one or more fail · 3 input failure (fixture file or predicate not found) |

## check-doc-links.py — Two Modes

### Mode 1: broken-refs (default)

Scans target files for broken cross-references. Default mode when
`--from-path/--to-path` are NOT supplied.

```bash
# Ad-hoc scan over an explicit scope. `--allowlist` is REPEATABLE and the
# pattern sets UNION — see "Check 14 (deploy.sh) Invocation" below for the
# tracked-base + instance-additions layering the recurring callers use.
python3 core/deploy/tools/check-doc-links.py \
  --target-paths "core/governance/,core/standards/,operations/skills/*/SKILL.md" \
  --allowlist core/deploy/allowlists/skip-doc-link-check-ci.txt \
  --output-format tsv \
  --exclude-code-blocks
```

**Output formats:**
- `tsv` (default): 6 columns — `source_file`, `line`, `target`, `category`,
  `severity`, `remediation_recommendation`
- `json`: array of objects with the same fields
- `github`: GitHub Actions `::warning::` annotations

**Exit codes:**
- `0` — no broken refs found
- `1` — broken refs found (count in TSV body)
- `2` — argparse failure (missing `--target-paths` or `--self-test`)

**Categories:** `broken-cross-ref`, `broken-anchor`, `deleted-target`.

**Severity tiers:**
- **P1** (must-fix): active governance + skill SKILL.md + per-module rules
- **P2** (should-fix): reference docs + per-module disciplines/schemas/specs/standards
- **P3** (informational): archived / audit artifacts (usually allowlisted)

### Mode 2: rewrite-map (EMIT-ONLY)

Scans target files for references whose path starts with `--from-path`,
emits a rewrite map showing the substituted target path under `--to-path`.
Triggered when BOTH `--from-path` AND `--to-path` are supplied. Designed for
per-edit discipline workflows where the operator (or a downstream tool like
`pmo-skill-editor` Mode A) consumes the map and applies the rewrites.

**Tool never mutates any file** — enforced structurally via self-test
Fixture 6 (mtime + content-hash assertion).

```bash
# Generate a rewrite map for a typical path migration
python3 core/deploy/tools/check-doc-links.py \
  --target-paths "core/disciplines/" \
  --from-path "pmo-platform/reference/explanation/" \
  --to-path "core/disciplines/" \
  --output-format markdown > /tmp/rewrite-map.md
```

**Output formats (rewrite-map mode):**
- `tsv` (default): 4 columns — `source_file`, `line`, `old_path`, `new_path`
- `json`: array of objects with the same fields
- `markdown`: GitHub-flavored markdown table for paste into per-edit plans

**Exit codes:**
- `0` — always (regardless of entry count) on successful scan
- `2` — flag asymmetry (one of `--from-path`/`--to-path` provided without the other)
- argparse errors propagate as exit 2 from argparse itself

**Anchor / query preservation:** If a matched ref carries `#anchor` or
`?query`, the suffix mirrors into `new_path` unchanged.

```
old_path: pmo-platform/reference/explanation/foo.md#section-2
new_path: core/disciplines/foo.md#section-2
```

**Operational note (asymmetric-segment-depth caution):** rewrite-map mode
performs prefix-only string substitution. If `--from-path` and `--to-path`
have different segment depths AND the source corpus contains refs with
additional path segments beyond `--from-path`, the substitution preserves
the trailing segments verbatim. Decompose multi-segment restructuring
renames into multiple invocations (one per `from→to` pair). Per failure-mode
FM-2 in adversarial-design-review at Stage 5.

## check-doc-frontmatter.py — Platform-Doc Frontmatter Gate (Check 50)

Validates the YAML frontmatter of authored K1 platform-reference docs under
`core/**` against [`core/standards/platform-doc-frontmatter-standard.md`](../../standards/platform-doc-frontmatter-standard.md).
It is the **presence-and-shape** complement to `check-version-anchors.py`
Check 18b: 18b checks the `framework_version_anchor` **value** and skips
no-frontmatter docs; Check 50 checks frontmatter **presence + required-field
shape** and treats a no-frontmatter doc as the headline finding.

```bash
# deploy.sh Check 50 invocation pattern
python3 core/deploy/tools/check-doc-frontmatter.py \
  --target-paths "core/standards/**/*.md,core/schemas/**/*.md,core/specs/**/*.md,core/disciplines/**/*.md,core/rules/**/*.md,core/governance/**/*.md,core/skills/**/references/*.md" \
  --allowlist core/deploy/allowlists/skip-doc-frontmatter-check.txt \
  --output-format tsv
```

**Six-step per-doc validation** (run for every resolved, non-allowlisted target):

1. **Missing-frontmatter** — first line is not a `---` fence → one finding.
2. **Tier-1 required-field presence** (all classes) — `title` / `purpose` /
   `type` / `status` / `reversibility` each present and non-empty.
3. **`type` ∈ singular enum** — the standard's §5 table (`standard` / `schema` /
   `spec` / `discipline` / `rule` / `protocol` / `how-to` / `template` /
   `reference`); a plural like `standards` flags with a did-you-mean hint.
4. **`framework_version_anchor` present IFF cataloged** — both directions are
   violations (cataloged-but-absent; present-but-not-cataloged). The anchor
   *value* is NOT checked here — that is 18b's job.
5. **`consumers` present for `standard`/`schema`/`spec`** — the blast-radius seam.
6. **`reversibility` tier-PREFIX match** — the value's first token must be one of
   `{CHEAP, MODERATE, EXPENSIVE, IRREVERSIBLE}`; a prose tail is allowed.

**Output (TSV):** header `frontmatter-check <N>`, then columns
`file<TAB>tier<TAB>field<TAB>violation<TAB>severity`. The **`tier` column**
(`A` | `other`) is the routing key `deploy.sh` consumes — `A` for a doc under
one of the six Tier-A governance-class dirs (`core/standards|schemas|specs|
disciplines|rules|governance/`), `other` for the rest of the scanned surface
(`core/skills/**/references/*.md`).

**Exit codes:**
- `0` — no violations
- `1` — violations found (count in the header line)
- `3` — path-resolution failure: a `--target-paths` glob OR `--catalog-path`
  resolved to zero/missing files (unverifiable, not clean — the fail-loud
  contract that 18b and Check 42 also honor).

**Global committed-default enforce posture (frontmatter gate).** The gate
ships **committed-default enforce across the authored-doc surface**: every finding
— Tier A and `other` alike — routes to a hard `FAIL` (the split Tier-A-enforce /
tier-other-warn partition the earlier warn-mode posture shipped has collapsed to one global-enforce
verdict). Activation is the committed default in `deploy.sh` (`c50_mode` is
hardcoded `enforce`) and does **not** depend on an un-committed
`doc-frontmatter.mode` file, so any clone enforces — a fresh non-conformant
`core/` doc `FAIL`s `deploy.sh --check`. The scan surface is the precise
authored-doc subtree globs (the six Tier-A governance-class dirs plus `core/*.md`,
`core/deploy/tools/*.md`, `core/diagrams/*.md`, `core/packs/*.md`,
`core/references/**/*.md`, and `core/skills/**/references/*.md`); `core/ADRs/`
(disjoint ADR schema, owned by a separate ADR-frontmatter effort) and `**/tests/fixtures/**` are excluded by
construction. The global `DEPLOY_CHECK_MODE=off` kill-switch is retained so the
gate stays disable-able in an emergency, not un-disableable.

**F1 consistency (shared with Check 18b).** Check 50 reads each doc's frontmatter
via the shared `_frontmatter.read_frontmatter` and builds the cataloged-doc set
via `check-version-anchors.py`'s own `parse_catalog_table` (imported directly).
So Check 50 and Check 18b cannot disagree about *what a frontmatter block is* or
*which docs are cataloged in `framework-catalog.md`* — they agree by construction.

**Allowlist** (`core/deploy/allowlists/skip-doc-frontmatter-check.txt`):
repo-relative paths, one per line (`#` comments + blanks ignored); a listed file
is skipped entirely. Seeded with the 11 `bypass-mode-readiness` files (1 generated
index + 10 ADR-030 assembly fragments) — generated content the platform-doc
frontmatter standard's §5 carve-out exempts and the Tier-A backfill deliberately
left un-backfilled.

**Self-test:** `python3 core/deploy/tools/check-doc-frontmatter.py --self-test`
runs fixtures (a)–(j): a clean doc, the two falsification fixtures (each Tier-1
field removed; whole frontmatter stripped), the plural-enum case, both IFF
directions plus the satisfied case, missing-consumers, the reversibility
prefix-passes-with-tail proof, tier tagging, and allowlist loading.

## build-doc-index.py — Document-Ecosystem SQLite Index Builder

Materializes the **disposable** document-ecosystem SQLite index defined by
[`core/schemas/sqlite-index-schema.md`](../../schemas/sqlite-index-schema.md).
The database is a **cache** — the files remain the source of truth; deleting the
`.db` and rebuilding produces a byte-identical result. It is the third link in the
doc-warehouse FK chain: `stamp-node-frontmatter.py` (nodes) →
`backfill-relationship-edges.py` (edges) → **`build-doc-index.py`** (reads both +
materializes the queryable index).

```bash
# Full deterministic rebuild from a corpus root.
python3 core/deploy/tools/build-doc-index.py --rebuild \
  --db /path/to/doc-index.db --root ~/Claude/projects

# Incremental single-file update (the lifecycle-automation callee — capability only, no watcher).
python3 core/deploy/tools/build-doc-index.py --update-file <file> \
  --db /path/to/doc-index.db --root ~/Claude/projects

# Run a named reference query (7 supported).
python3 core/deploy/tools/build-doc-index.py --query cross-project-deps \
  --db /path/to/doc-index.db
python3 core/deploy/tools/build-doc-index.py --query blast-radius \
  --db /path/to/doc-index.db --param changed_file=alpha_fdd.md --param max_depth=5
```

**What it builds:** all 7 schema tables — `files`, `relationships`, `files_fts`
(FTS5 external-content), `lifecycle_events`, `navigation_pages` (empty; a future
read-target), `synthesis_scope`. Populated from node frontmatter (the 11-field
NOT-NULL core; a partial stamp yields no `files` row) + `relationships[]` edges +
`source_inputs[]` provenance.

**Domain enum (migrated).** Reads/inserts the human-readable `{source, managed,
generated}` the node tool stamps; `{A, B, C}` are DEPRECATED aliases the schema
CHECK still accepts during the migration window, and the union-enum queries
(rollup / staleness / orphan) collapse both vocabularies.

**Edge resolution.** A `relationships[]` `target` resolves to `files.file_id` by
exact `filename`; a `BELONGS_TO` whose `target` is a **project name** (the shape
`backfill-relationship-edges.py` emits) resolves to that project's governance-root
representative node (`folder='01-governance'`), so a file whose only edge is
`BELONGS_TO` is not a false-positive orphan. A target that resolves to neither is a
**dangling WARN** (row skipped, never fabricated).

**Determinism (byte-identical rebuilds).** Discovered files are sorted by relative
POSIX path before insert, so `file_id` is a pure function of corpus content;
build-time timestamps are never synthesized (a missing `created_date` is stored as
read; `modified_date` is the filesystem mtime — a per-file property identical across
two rebuilds); the staleness queries use query-time `julianday('now')`, which does
not touch stored rows. Verified by SHA-256 over a canonical per-table dump
(`--dump-canonical`).

**Scope (builder / lifecycle-automation boundary).** Ships the incremental-update **capability**
(`update_file`, a tested callable entry point) + full rebuild + the reference
queries. The event source/watcher that auto-invokes `update_file` on a skill-write
is out of this tool's scope — it stays in the lifecycle-automation epic.

**Exit codes:** `0` clean · `1` dangling edges present (count in header) · `2` usage
error · `3` path-unresolvable (`--root`/`--db`).

**Self-test:** `python3 core/deploy/tools/build-doc-index.py --self-test` builds the
committed fixture (`tests/fixtures/doc-index/` — 2 projects, a cross-project
`DEPENDS_ON` edge, 2 Domain-C syntheses) and asserts: all 7 tables + indexes (AC1);
two rebuilds byte-identical (AC2); rebuild < 10s (AC3); portfolio-rollup +
cross-project-deps both non-empty and all 7 queries execute (AC4); `update_file`
round-trip equals a full rebuild of the mutated tree (FMF-2); Query-6's temporal
condition discriminates via a deterministic `os.utime` mtime push (FMF-3).

## Link-Resolution Rule (canonical)

`check-doc-links.py` resolves a markdown link target by one canonical rule
(ADR-085), implemented identically by `release/tools/check-release-links.py`:

1. A link resolves **relative to the source file's directory**.
2. A **leading `/`** denotes the **workspace (repo) root** — the GitHub-faithful
   workspace-rooted form (resolved against `--workspace-root` > `$CLAUDE_WORKSPACE_ROOT`
   > the in-repo default, in that precedence).
3. There is **no bare module-prefix fallback**: a bare `core/…` / `release/…`
   from a non-root file is an ordinary relative path, so it reads **broken**
   (exactly as GitHub renders it).

The earlier V1/V2 workspace-rooted prefix tables (ADR-009 Rule 2), which drove a
bare-prefix workspace-root fallback, were retired here — the fallback masked
links GitHub renders as 404s from non-root files. `core/CLAUDE.md.template`
(which deploys to the repo root) uses the leading-`/` form for its root-anchored
references, so it resolves correctly under the canonical rule both as a template
and as the deployed `CLAUDE.md`.

## Self-Test

```bash
python3 core/deploy/tools/check-doc-links.py --self-test
```

Runs 9 fixtures sequentially. Each fixture uses its own tmpdir scope;
failure on any → exit 1 with explicit assertion message.

| # | Fixture | Verifies |
|---|---|---|
| 1 | code-block exclusion + single broken ref | Original code-block-exclusion behavior |
| 2 | anti-fallback regression guard | a bare module-prefixed link from a non-root file reads BROKEN even when the path exists at the workspace root (ADR-009 Rule-2 fallback retired per ADR-085), while the leading-`/` form of the same target resolves |
| 3 | rewrite-map TSV + JSON + markdown output | All 3 output formats; column counts; header shape |
| 4 | AC-3 five-form parity (doc-links side) | the five link forms return the canonical verdicts: relative-ok / relative-broken / `../`-ok / bare-prefix-broken / `/`-rooted-ok |
| 5 | anchor preservation in rewrite-map | `#section` survives substitution |
| 6 | EMIT-ONLY structural enforcement | mtime + content-hash unchanged after rewrite-map scan (PR-3/FM-1) |
| 7 | `--require-targets` fail-loud | a `--target-paths` glob resolving to zero files is flagged (exit 3); a populated scan-root is not |
| 8 | placeholder / meta-doc-literal exclusion precision | `<…>` tokens, barewords, `...`, and blockquoted worked-example links are skipped while a genuine broken ref still fires |
| 9 | relocatable workspace-root + precedence | a `/`-rooted link re-roots under a sandbox root; CLI > `$CLAUDE_WORKSPACE_ROOT` > default |
| 10 | `--target-paths-file` loader (shared scan-scope SSOT) | one-glob-per-line parsing; blank/comment lines ignored; missing or comment-only file returns `[]` (which `main()` converts to a hard error, never a silent empty scan) |
| 11 | repeatable `--allowlist` UNION (shared tracked base + instance additions) | two allowlist files concatenate in argument order and neither shadows the other; a missing file does not discard the present one; the union actually suppresses (with an unallowlisted control that still fires) |

Expected output: `self-test OK (11 fixtures passed)`.

## Check 14 (deploy.sh) Invocation

`deploy.sh` Check 14 is the primary recurring consumer. Invocation scoped to
the governance + skill SKILL.md surface across all 3 modules:

```bash
python3 core/deploy/tools/check-doc-links.py \
  --target-paths-file core/deploy/allowlists/doc-link-target-paths.txt \
  --allowlist core/deploy/allowlists/skip-doc-link-check-ci.txt \
  --allowlist "$PMO_INSTANCE_PATH/skip-doc-link-check.txt" \
  --output-format tsv \
  --require-targets \
  --exclude-code-blocks
```

Scan scope comes from the shared `--target-paths-file`, the SAME list
`.github/workflows/link-check.yml` passes, so the two callers' scope cannot
drift.

Allowlist layering: `--allowlist` is repeatable and the pattern sets UNION in
argument order. The first is the **tracked corpus-level base** — also the SAME
file `link-check.yml` passes, so the two callers' ignore list cannot drift
either. The second carries operator-instance additions layered on top; when
`$PMO_INSTANCE_PATH/skip-doc-link-check.txt` does not exist, deploy.sh falls
back to `.claude/skip-doc-link-check.txt` (legacy operator-side workspace
location), and an absent instance file simply contributes no patterns.

Warn-mode initial per `core/rules/bypass-mode-readiness.md` shakedown
precedent; flip-to-enforce timeline codified in
`core/standards/doc-link-maintenance-protocol.md`.

## Check 15 (deploy.sh) — RETIRED in v2

Per the Stage 5 spec Surface 4 plus a later operator fix,
the in-repo release-corpus check (`RELEASE_LOG.md`, `releases/plans/`,
`releases/notes/`) is RETIRED in v2 — release-corpus is operator-instance per
the harness plan § 2.4.

The release-time integrity function is upheld by a 3-layer architectural
pattern:

| Layer | Surface | Owner |
|---|---|---|
| 1 (primary, operator-choice) | External release-notes tool — GitHub Releases per dual-write Surface 1 (default) + native validation; OR Azure DevOps; OR JIRA; OR Confluence; OR other | Operator's external system |
| 2 (fallback) | `~/Claude/pmo-instance/tools/check-release-corpus.sh` wrapper invoking `core/deploy/tools/check-doc-links.py` against operator-instance corpus paths | Operator (local) — authoring deferred to P2.5-T1 |
| 3 (release-pipeline gates) | Stage 12 + Stage 13 chip prompts per + Procedure 7 Step 4 completion-verification per fire regardless of Layer 1/2 choice | Hub (release pipeline) |

`deploy.sh` Check 15 block is replaced with a citation comment block.
Check numbering gap (15 retired) preserved for citation continuity of
Checks 16-30 across governance.

## cross-module-audit.sh — Extraction-Readiness Audit

Per the module-restructure Stage 5 spec: scans every file under
`operations/`, `release/`, and `core/` for cross-module references; classifies each per
6 directionality rules + 3 cross-ref-types; emits 7-strategy enum
`recommended_strategy` per finding for cleanup-framework consumption.

```bash
# From repo root (writes to audit-output/ by default; gitignored)
core/deploy/tools/cross-module-audit.sh \
  audit-output/cross-module-audit-$(date -u +%Y-%m-%d).md \
  audit-output/cross-module-audit-$(date -u +%Y-%m-%d).tsv
```

**Architecture (per CD-2 counter-design):** bash entrypoint (`cross-module-audit.sh`)
delegates to Python helper (`cross_module_audit_helper.py`) which imports
`extract_links()` + `resolve_target()` + `strip_code_blocks()` from
`check-doc-links.py` — inheriting FM-1 fenced-code-block stripping + FM-2
anchor-resolution. Primitive stays single-responsibility (link-integrity);
wrapper adds directionality classification + cross-ref-type refinement.

**Exit codes:**
- `0` — no cycle-class violations (clean OR non-cycle violations only)
- `1` — code-import cycle detected (BLOCKS module extraction)
- `2` — non-cycle violations detected (advisory; routes to cleanup queue)
- `3` — script error

**Cross-ref-type refinement (per counter-design CD-3):**
Cat-1/Cat-2 cycle matches are classified as:
- `code-import` — `.sh source X` or `.py from/import X` statements (BLOCKER)
- `markdown-doc-link` — `[text](path)` markdown links (Suspect; carry-forward allowed per ADR-007)
- `narrative-mention` — prose substring (Minor; route to operator)

Documentary references from `core/disciplines + core/schemas` to
`release/governance/release-process.md` + `release/references/pipeline/*` are
classified as `info-adr-007-carry-forward` (accepted cohesion per the ADR-007 carry-forward contract).

**Validation report:** `audit-output/cross-module-audit-<DATE>.md` (relative to repo root)
(markdown summary per Surface 6.2) + `.tsv` (machine-readable per Surface 6.1).
The `audit-output/` directory is gitignored — reports are point-in-time evidence, not committed artifacts.

**Self-test:** `python3 core/deploy/tools/cross_module_audit_helper.py --self-test`
runs 4 fixtures (source/target module classifiers, cross-ref-type classifier,
ADR-007 carry-forward allowance).

**Idempotent:** read-only; re-runs at the same commit emit identical TSV output.

## Related Documentation

- `core/standards/doc-link-maintenance-protocol.md` — full protocol
  (warn-mode posture, flip-to-enforce timeline, Pattern A/B/C definitions)
- `core/rules/doc-link-maintenance.md` — operator-facing recap (mirror)
- `core/rules/bypass-mode-readiness.md` — Shakedown → Enforce Transition Checklist
- Stage 5 spec — canonical authority for tool extension and
  Check 15 retirement
- Adversarial design review at (Stage 5 Phase A6.5) — PR-1, PR-3,
  CD-3 Tier 1 findings implemented in batch 1
