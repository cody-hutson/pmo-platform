<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# RELEASE_INDEX_ARCHIVE-v3

Archive segment of [`RELEASE_INDEX.md`](RELEASE_INDEX.md) — the **v3** release family.

This file is the same record as its parent ledger, relocated. It is a **Vital**
record under `core/governance/RECORDS_POLICY.md`, retained permanently, and it
inherits its parent's class: a segment is a disposition *destination*, never
itself a disposition *source*. Nothing here is a lesser record for having aged
out of the working set.

It lives in the same directory as its parent deliberately, so `grep -r` over
that directory still finds this content exactly as it did before the move. Each
entry below retains its heading in the parent ledger, with a pointer here.

Entries are appended by `release/tools/sweep-release-corpus.py`; the file is
append-only and is never itself swept.

---
#### v3.87

Design artifacts made findable — every diagram and process flow embedded in the docs now declares itself with a one-line marker (**ADR-089**), the `depicts:` / `flow_class:` frontmatter is promoted to required, and a new §12 adds per-flow-type detection criteria + an enumeration query, so the whole set is listable with one search. The spike's confirm-or-collapse decision **collapsed** 5 of 6 flow-type builds into a declare-sweep (24 embedded-marker declarations across 5 already-covered types; 14 skill packages rebuilt) and kept human-process as the one real build (new `docs/release-record-keeping.md`). `novel` class, MODERATE reversibility.

#### v3.79

Deploy/gate tooling de-duplicated + tested — one canonical link-resolution rule across both checkers (ADR-085, supersedes ADR-009), the last template-sync resolver single-sourced, hook ownership derived by enumeration (both C37 arrays deleted), and hook↔test parity restored 12/12

#### v3.78

PORTFOLIO.md composed deterministically from per-project rollups — freshness-gated three-layer health scoring, cross-component risk aggregation, and a portfolio/program/project tier taxonomy

#### v3.77

Skill-suite hardening — on-demand health-check rollups, semantic routing-conflict detection, and a clarified SKILL.md sizing rule

#### v3.76

Corpus-wide frontmatter enforce + AUDIT_FRAMEWORK refreshed + SPI bands single-sourced + `[PROJECT_KEY]` classified + vision/install codified (ADR-083)

#### v3.74

Durable CI regression-prevention gates for the two build-security advisory classes (hook fail-open + eval-viewer stored XSS) + Security elevated to build-philosophy's 6th first-class value (ADR-081)

#### v3.73.1

`update.sh` now refreshes the deployed security-hook bundle, so hook/helper fixes reach already-installed workspaces

#### v3.69.1

Security patch — the PreToolUse hook perimeter no longer fails open when `jq` is unresolvable (GHSA-9cjm), stored XSS closed at the eval-viewer render sinks (GHSA-rw36), and the shared hook helper is co-deployed so the hardening actually reaches an installed workspace

#### v3.66

Software-domain artifact templates (7 families) + taxonomy registry completion

#### v3.65.1

Comment author-association trust boundary (prompt-injection hardening) + lock-at-close

#### v3.63

GitHub-native PR-review surfaces + release-manager skill↔pipeline reconciliation

#### v3.57

Domain-aware impact analysis + git-native-aware release-executor — a code-import-graph blast-radius analyzer for `domain: software` changes emitting the design-review schema (#505, ADR-068), and the release-executor dry-run-record halt no longer dead-ends git-native releases where the PR diff is the dry-run review (#674).

#### v3.56

Stage-3 bundling composer + version-identity — a self-triggering Stage-3 composer: approved-queue-depth monitor (#30), automated milestone-position derivation feeding the G3-07 gate (#52), a bundle-composer identity distinct from Stage-4 planning (#25), and a first-class version-less release-identity mode reconciled to the version-grammar SSOT (#415).

#### v3.50

Stage-gate criteria completeness — the release pipeline can now evaluate every stage transition from the canonical gate specs alone: discrete gate IDs for Stages 4/6 (G4/G6, schema v1.21→v1.22), late-stage judgment dimensions anchored to their structural criteria (#118), all 10 Stage-I/O boundary contracts authored (#29), bidirectional G1-04 (#96), a Stage-5 structural-premise review gate + ticket-architecture reconciliation discipline (#501/#889), and CLI lifted out of criterion cells into a Validation-method column (#119, schema v1.23→v2.0).

#### v3.49

Governed file movement — the file router now governs all four movement directions (inbound / generated-staging / promotion / cross-project) rather than inbound-only (#240; resolves the promotion target and cites artifact-generator's PROMOTE/REVISE/REJECT gate, owning a new gate only for cross-project-out); an intake-desk Phase-2 container-altitude existing-owner scan that blocks duplicate containers (#565); and intake-desk Mode C — Ambient Auto-Log, non-interactive detect→create governed by `automation_level`, Tier-0 never auto-created (#289). `routine`-class, three EXTEND-mode skill slices.

#### v3.48

Knowledge-corpus tail close-out — the design-before-slicing gate conditioned on `delivery_approach` (ADR-066 + criterion G3-18, schema v1.20→v1.21), a notes-non-authoritative + destructive-action guardrail in CLAUDE.md (#1093), and the health-RAG band/watermelon canonical home (ADR-065, #930); closes the last child of KA-Standards #1171 and KA-Discipline #1174.

#### v3.43

Spoke-execution safety — five properties that make a Stage-6 pipeline spoke unable, by construction, to (1) push unsafely under multi-chip parallelism, (2) drift from its intake substrate undetected, (3) spawn commit work without a signing key, (4) wander to the operator's primary checkout, or (5) run outside security-hook coverage. **#307** authors **ADR-062** (canonical-spec edit wins over substrate-body mutation; issue bodies remain historical-record) + wires the cross-repo-citation-translation discipline into `stage-05-solutioning.md` A1 + indexes it in the ADR README. **#47** adds the Stage-5 **M1.1 substrate-drift reconciliation chip** (one canonical home in `hub-spoke-bridge.md`, emitting a structured 4-field drift report — `drift_class` / `body_claim` / `current_state` / `gap_age_days`) + the `intake-substrate` PROC failure-mode class (`failure-mode-standard.md`); the optional `check-substrate-drift.sh` primitive was scoped OUT. **#1639** corrects the `block-destructive.sh` BLOCK-DESTRUCTIVE-019 worktree-exemption base from workspace-root to repo-root (derived per ADR-017) + retargets 13 allowlist worktree-globs + repoints the hook-test fixtures with both-direction gate-teeth — a LIVE always-enforce defect fixed before #1531's hook-loading wiring lands. **#1642** adds the spoke-template no-`cd`/never-primary clause in `hub-spoke-bridge.md` + the `git-workflow.md § Primary Checkout Discipline` spoke line (AC-2 subagent-hook coverage deferred to #1531). **#1351** adds the CLAUDE.md governance self-check + a structural local-work entry point rooted outside `pmo-platform/` (`CLAUDE.md.template`; T1+T2a this release). **#59** adds the `ssh-add -l` pre-flight in the commit-producing-spoke spawn procedures + a user-side handoff on empty-agent. `novel`-class; milestone 67-spoke-execution-safety, six cards on one branch / one squash-merged PR (#2799), D-C SINGLE · P0 fully-serial (the 3-way `hub-spoke-bridge.md` edit forecloses parallel chips). #20 (subsumed by v3.28 ADR-052) and #1472 (folded into #1531 + #1639) closed during readiness. CHEAP-to-MODERATE / `git revert` of the release PR restores prior state; the one MODERATE surface is #1639's executable hook edit (clean revert, but a wrong base with #1531 enforce already flipped would mis-block worktree edits — hence the ordering mitigation). #1531 stays open (separate milestone `96-update-install-config-safety`; owns #1642 AC-2).

#### v3.42

`cleanup-orphan-state.sh` reliability cluster — the branch-cleanup tool now truthfully reaps squash-merged release/chore branches on this squash-merging repo. **#2790** (keystone) resolves `gh` absolutely via `resolve_gh_bin()` (mirroring `resolve_lsof_bin`) so it is reachable under the script's pinned `PATH=/usr/bin:/bin`; without it #2216's MERGED-branch rescue and #655's PR-state prefetch were inert on the canonical host. **#2216** wires `--release-close` to reap squash-merged branches (ancestry SKIP no longer pre-empts the PR-state rescue; `require_pr=0`). **#684** extends `--release-close` scope to `chore/vX.Y-stage-*` branches (additive to v2.09's four slug-anchored patterns; owns the #2048-item-3 cross-milestone duplicate; carries the release's only Stage-10 Docs touch, `git-workflow.md § Step 10`). **#683** lets `--apply` delete a merged branch from a behind-HEAD checkout without `--force` (origin/main-relative eligibility vs HEAD-relative `-d`). **#655** batch-prefetches PR state (O(1) `gh` calls per run). **#670** de-duplicates local-branch rows under `--all`. **#669** trims to a residual `--help`/self-test fix (primary defect resolved earlier by #1678). `routine`-class; milestone 85-cleanup-orphan-tooling-reliability, seven cards on one branch / one squash-merged PR (#2789) against the single file `release/tools/cleanup-orphan-state.sh` (+ `git-workflow.md` for #684). #1552 (refuted P1 data-loss) cut at the Stage-4 gate; #654/#1481/#1552 verified already-resolved. `v3.42` free at the Stage-12 atomic claim (anchor = published v3.41). MODERATE / `git revert`; the only lasting effect of the fixed tool is branch deletions (themselves recreatable from merge commits).

#### v3.41

Skill-suite structural hygiene plus two net-new measurement auditors. **Hygiene (Wave A):** **#1135** ratifies the canonical mode-heading separator standard (` — `, em-dash flanked by spaces, U+2014) in `canonical-skill-structure.md §4` (survey-grounded em-dash majority over the colon-form minority); **#1136** applies the em-dash separator across the colon-form multi-mode SKILL.md set; **#1132** consolidates vestigial Mode-Detection sections (project-initiator + eval-writer); **#1133** brings the SKILL.md catalog to full `## Guardrails (Platform)` conformance (12 inserts + 26 renames of bare `## Guardrails`, pmo-qa-auditor's `## Guardrails (Extended)` preserved) and fixes a folded `failure-mode-standard.md` drift; **#571** cross-references delivery-engine's DoR/DoD gate vocabulary to G1/G3 + DT-2; **#676** reconciles the stale canary entry in `per-skill-output-contracts.md §Skill 12`. **Measurement (Wave B):** **#16** adds the `context-budget-auditor` skill (token consumption across loaded components); **#17** adds the `skill-compliance-auditor` skill (trigger-rate accuracy) plus **ADR-061** (trigger-rate metric class + eval-writer boundary). **#704** ships SPEC-ONLY (routing-conflict detection beyond Jaccard; deferred code half → #2699). `novel`-class; milestone 07-INFRA-hygiene-measurement, nine slices on one branch / one merge across two waves. Stage 4 live-verified the catalog at 48 skills (not the 23 the source issues assumed); #1133/#1136 re-priced size:M. Re-versioned forward v3.39 → v3.41 pre-merge (A.5.6c lineage — branch descends from v3.40); `claim-version.sh` bound v3.41 at the merge SHA with no CAS collision. CHEAP / `git revert -m 1`; two new `core/` skills + one ADR + catalog-wide SKILL.md structural edits, no `.skill` package committed in-PR (source-only; packages build at close-out), runtime blast radius none.

#### v3.40

Four documentation-drift sites drained from the internal reference corpus — no behavior, schema, or runtime change, all guards and historical records preserved. **#108** reconciles `doc-link-maintenance-protocol.md` §8 to the shared warn-log the protocol actually writes (vs `deploy.sh` Check 14). **#131** lowercases the genuine capital-P `Projects/` prose references in `core/governance/OPERATIONS.md` + `operations/OPERATIONS.md` to canonical `projects/` (re-scoped 2026-06-30 to the real OPERATIONS refs; a changelog line naming the historical casing is preserved intact). **#2684** drains the last live IMPROVEMENTS.md / IMP-### Self-Update-Protocol instruction in `routing-rules.md`, routing it to the current GitHub-Issues intake. **#2700** unifies the project-path placeholder to the canonical `projects/[Project]/` form across `frontmatter-schema.md`, `navigation-layer-schema.md`, `routing-rules.md`, `sqlite-index-schema.md`, `health-check-specification.md`, and `project-initiator/SKILL.md` (owns all placeholder-token variants per the BROAD boundary resolution surfaced by the #131 re-scope). `routine`-class; milestone 30-doc-link-drift-drainage, four file-disjoint drainage cards on one branch / one merge. No re-version (v3.40 free at the Stage-12 atomic claim; anchor = published v3.38). CHEAP / `git revert -m 1`; additive documentation edits, the one migrated skill (`project-initiator`) had its `.skill` package rebuilt in-PR so the artifact stays atomic, runtime blast radius none.

#### v3.38

The release pipeline's own rules get three additive precision fixes to sharpen release-identity and frozen-spec handling across Stages 4/5/6 — a Stage-4 placement forward-check (Phase A0.7 / G-PL3) that detects directory-crossing renames and in-scope deletions on the mainline since the release branch's base, so a "release cut before a structural reorg → new-file placement collides at deploy" pattern is caught up front (#3); a Stage-6 commit-group traceability note (documented simplification — advisory, not enforced) plus a sub-task-methodology enforcement-posture sentence, carrying the release's genuine design decision rendered ADVISORY at Stage 5 (#226); and a Stage-5 frozen-spec prose-vs-artifact precision rule as a required-when-triggered block in the solutioning-output-template's Blast Radius section with a DEFERRED escape, plus a routing pointer in the Stage-5 solutioning reference (#75, with a stale `templates/` → `standards/` milestone-path correction carried into the plan at Stage 4). `novel`-class; three file-disjoint cards on one branch / one merge. Re-versioned forward v3.37 → v3.38 at the Stage-12 pre-merge freeness check (a concurrent sibling release claimed v3.37 first, its plan file also on the same path); the atomic claim then bound v3.38 with no collision — the plan's R1 contingency firing as anticipated, forward-only. CHEAP / `git revert -m 1`; additive documentation/protocol edits to the release-pipeline reference corpus, no skill or `.skill` package touched, runtime blast radius none.

#### v3.37

Shared project facts (people, systems, vendors, workstreams, decisions, cross-project dependencies) now live in one shared `projects/_pmo/` area with a consistent page per entity, and `PROJECT.md` becomes a thin composed wiki-link index that links out to those shared pages instead of restating them — plus plans (comms/training/hypercare/cutover/change-mgmt) become typed sub-entities with relationship typing. **#362** establishes the `projects/_pmo/{people,systems,vendors,workstreams,decisions,dependencies}/` layout with six entity-page templates (aligned to ADR-040 `person_id` + people-roster; compose, not fork) and a `project-initiator` Mode A `_pmo/` bootstrap step; **#363** redesigns PROJECT.md as a ≤50-line composed index linking INTO #362's entity pages, adds the Mode A Step-3 template-ref swap, and defines a 4-step live-migration protocol with a backwards-compat consumer table; **#159** models plans as typed sub-entities, resolves the deferred `plan_type` G5 enum membership, and drops `plan_subtype`. `novel`-class; three stories on one branch / one merge (build order `#159 ∥ #362 → #363`). **AC-5 live-project migration DEFERRED** — the merge ships the capability only; the gated POC migration of ≥1 live PROJECT.md (git-ignored ops tree, out-of-diff, snapshot-before/verify-after) is a follow-up per plan R1. No re-version (v3.37 free at the Stage-12 atomic claim; anchor = published v3.36). CHEAP / `git revert -m 1`; additive structure + schema + templates, runtime blast radius none, the only non-git-reversible step (live migration) deferred.

#### v3.36

Process-domain specialist skills anchored to one best-practice guide, plus a new support-domain guide and the change-domain decision — the four process specialists (pmo-scrum-master, pmo-release-train-engineer, pmo-business-analyst single-anchor; pmo-product-owner dual-anchor to BOTH `process.md` and `governance.md`) each gain a compose-by-reference `## Reference docs` pointer (ADR-019; no content absorption) and the guides' `consumers:` fields list them (#2177, #2178, #2179, #2180); a net-new `core/standards/domain-best-practices/support.md` K1 guide covers ITIL 4 + tiered incident & escalation practice + SRE, with three EXTERNAL + one INTERNAL row registered in `framework-catalog.md` (#2210); and the change domain's best-practice content stays self-bundled in `change-management/references/` with the framework catalog as its registry — no shared `change.md`, pmo-ocm-lead unchanged (transitive via ADR-019), recorded in ADR-057 (`Proposed`) with a reversal trigger, plus a build-philosophy coverage-matrix row (#2211). The process-domain sequel to v3.30 (software) and v3.33 (governance). `routine`-class; milestone 90-skill-anchoring-process-support-change, all six issues on one branch / one merge. No re-version (v3.36 free at the Stage-12 atomic claim). CHEAP / `git revert -m 1`; additive reference wiring + one new guide + one ADR, runtime blast radius none.

#### v3.35

Records management, file/folder naming, and 08-Generated cleanup are now governed: a records-management policy (`core/governance/RECORDS_POLICY.md`) defining ISO 15489-1 retention, a four-class classification, disposition, and authenticity (#372, ADR-054); a unified `core/standards/artifact-naming-standard.md` covering POSIX-safe syntax + a controlled type vocabulary + explicit folder-naming rules + a validation regex, wired into the seven emitting skills + OPERATIONS.md + a `pmo-qa-auditor` check (#369, ADR-055, absorbing #117); a new `generated-cleanup` skill running `08-Generated/` cleanup under an unconditional approval gate, grouped by lifecycle `artifact_state`, archiving to `_archived/` (#277, ADR-056); and `project-initiator` Mode A folder-name validation against the new standard (#232). `novel`-class; four cards on one branch / one merge. Re-versioned forward v3.34 → v3.35 at the Stage-12 atomic claim (A.5.6c — a concurrent telemetry release claimed v3.34 between Stage 9 GO and Stage 12 Execute; branch name retained). CHEAP / `git revert -m 1`; additive, runtime blast radius limited to two operational skills.

#### v3.34

Pipeline telemetry suite — the release pipeline gains canonical self-measurement: the 4 DORA key metrics (deployment frequency / lead time for changes / change-failure rate / MTTR) at the Build+Deploy layer via a tracked `dora-telemetry.md` schema + `compute-dora-metrics.sh` (#7), and Close-class observability (retro conformance, lessons-learned population, carry-forward closure, cross-release pattern emergence) at the Close layer via `close-class-telemetry.md` + `compute-close-class-telemetry.sh` (#143), with a cross-release aggregation tool extending `synthesize-release-learnings.sh` to emit `cross_release_pattern_emergence_rate` (#2612). `novel`-class — first-of-kind net-new schema + compute tooling; milestone 65-pipeline-telemetry-suite, all three issues on one branch / one merge. No re-version (v3.34 free at the Stage-12 atomic claim). CHEAP / `git revert -m 1`; additive schema + tooling, no skill or `.skill` package touched, runtime blast radius none.

#### v3.33

Governance-domain specialist skills anchored to one best-practice guide — the six governance-domain specialists (pmo-project-manager, pmo-program-manager, pmo-program-coordinator, pmo-portfolio-manager, pmo-knowledge-manager, release-planner) each gain a compose-by-reference `## Reference docs` pointer to `domain-best-practices/governance.md` (ADR-019; no content absorption) and the guide's `consumers:` field lists them (#2172, #2173, #2174, #2175, #2176, #2181). The governance-domain sequel to v3.30's software-domain anchoring. `routine`-class; milestone 89-skill-anchoring-governance, all six issues on one branch / one merge. Re-versioned forward v3.32 → v3.33 at the Stage-12 atomic claim (a concurrent release published v3.32 first; branch name retained). CHEAP / `git revert -m 1`; additive reference wiring, runtime blast radius none.

#### v3.30

Software-domain specialist skills anchored to one best-practice guide — the five software-domain specialists each gain a compose-by-reference `## Reference docs` pointer to `domain-best-practices/software.md` (ADR-019; no content absorption), the guide's `consumers:` lists them, pmo-technical-program-manager is dual-domain (also `governance.md`), and the build-philosophy BP×Skills cells are reconciled (software skill-wired; governance/process skill-wiring-pending) so the coverage map no longer over-claims (#2165, #2167, #2169, #2170, #2171, #2209). `routine`-class; milestone 88-skill-anchoring-software, all six issues on one branch / one merge. Re-versioned forward v3.29 → v3.30 at the Stage-12 atomic claim (a concurrent release published v3.29 first; branch name retained; a benign orphan v3.31 tag left in place). CHEAP / `git revert -m 1`; additive reference wiring, runtime blast radius none.

#### v3.29

Stage-6 Engineering parallelism postures — a founding ADR (ADR-052) fixes a named parallelism-posture taxonomy (`parallelism-posture-taxonomy.md`) for how a release's Stage-6 engineering work runs concurrently vs. serially, wired into the Stage-4/Stage-6 references, the hub-spoke orchestration bridge, `failure-mode-standard`, and the release-planner skill (#19). `novel`-class; a single-card slice of milestone 73-concurrent-execution-safety (2 issues remain open). Re-versioned forward v3.28 → v3.29 at the Stage-12 atomic claim (v3.28 was published first by the label-taxonomy milestone; the `release/v3.28` branch name is retained). MODERATE / `git revert -m 1`; release-pipeline governance + one skill, runtime blast radius none.

#### v3.28

Label-taxonomy canonicalization + a GitHub label-set parity check — the cluster axis gains an orthogonality protocol (one domain cluster per issue vs the `cluster: cross-cutting` span-marker that composes alongside it), the stale cluster color column is reconciled to live, and the undocumented `cluster: security` is registered (12 clusters, was 11) (#80); observation promotion strips the `[Observation]:` title prefix under a deterministic title↔category parity invariant, cross-referenced from the Stage-3 Template-Conversion Rule (#74); and `deploy.sh` Check 51 + `check-label-parity.py` assert label-taxonomy ↔ GitHub label-set parity (enforce-capable MISSING / warn-only ORPHAN, warn-mode-initial, source-agnostic) — its first run surfaced pre-existing drift routed to #1828 / #1777 (#749). `cross-cutting` class; all three issues on one branch / one merge per the milestone-as-one-PR model. Claimed v3.28 at the Stage-12 atomic claim (anchor v3.27, no collision). MODERATE / `git revert -m 1`; the warn-mode check cannot break CI, runtime blast radius none.

#### v3.24

Release-hub orchestrator skill — a net-new whole-release control plane (`release/skills/release-hub/`) that takes a milestone and drives it through the release pipeline by composing the stage skills, owning sequencing and readiness-gating but never the stage work itself. Two modes: **Mode R (Milestone Readiness, #2115)** is a pre-flight that confirms a bundled milestone is ready to START before a run is committed — it composes triage/dup, staleness/architecture, dependency, and bundle-coherence checks into one GO / NO-GO with a per-finding disposition list; **Mode O (Orchestrate Release, #2212)** runs the full hub-and-spoke orchestration — spawning the per-stage spokes in order, gating the operator only at the named pipeline checkpoints (plan-review GO/NO-GO, execute) rather than per action. The skill ships with 4 references (the readiness checklist, the orchestration playbook, the spoke-launch contract, and the decision-briefing format), a deploy-roster entry, and the built `.skill` package. `novel` class; both child issues delivered on one branch / one merge per the milestone-as-one-PR model. Claimed v3.24 at the Stage-12 atomic claim (anchor v3.23, `--bump minor`, no collision — the provisional and claimed version coincide, so no abandoned-version row). CHEAP / `git revert -m 1`; additive net-new orchestrator skill that composes existing stage skills and adds no new autonomous mutation surface, runtime blast radius none.

#### v3.23

Project health-check skill — a net-new intent-driven project-state drift auditor (`operations/skills/health-check/`) that audits one project for drift between its tracked state and its canonical sources (MCP-primary: Confluence/Jira/Smartsheet/SharePoint; local-fallback: trackers/PROJECT.md/PORTFOLIO.md/transcripts/emails/generated) and emits a categorized 5-section punch list — `## Confirmed` / `## Auto-Actionable` / `## Decisions` / `## Unknowns` / `## Rollup-Diffs` — that is never auto-applied (auto-actionable items stage a `TRACKER_UPDATES:` block for `/tracker-manager` approval; Rollup-Diffs are diff-only in `08-Generated/_health-check/`). Seven modes on one shared contract (4-intent block + 5-section output + S0–S3 confidence bands): `full` (total sweep, default), `timeline` (date/milestone drift with day-of-week validation, no generalized ranges), `attribution` (owner drift, no fabricated owners), `comms` (Communications-Tracker lifecycle; closures route to `/comms-writer` status-only), `plan <name>` (one named plan; requires the arg, prompts rather than guessing), `raid` (RAID-guardrail enforcement; never auto-closes a risk), `sources` (canonical-source inventory + graceful-degradation surface). **v1 foundation (#1125)** built the full contract once + the 3 foundation modes; **v2 (#1126)** implemented the 4 extended modes — both on one branch / one merge. Founding **ADR-051** records the MCP-primary/local-fallback source set + the graceful-degradation contract (unreachable connector → local-only run + banner; uncross-validated finding capped at MEDIUM, never auto-actionable). `novel` class; carried a provisional v2.42 label, claimed v3.23 at the Stage-12 atomic claim (no collision). Adds the `/health-check` command + registry row + deploy roster + `.skill` package. CHEAP / `git revert -m 1`; additive net-new skill + one ADR, runtime blast radius none, read-and-recommend only.

#### v3.22

PMBOK artifact coverage + PROJECT.md schema axes — PROJECT.md frontmatter gains three additive axes: the first-class `deliverable_type` deliverable-domain axis (open enum `{software, governance, web, data, enterprise-platform, hardware, process}` + lowercase-kebab open-escape; V13) with §5A Domain-Axis Consumption Pattern + G3-05 conditioning + founding ADR-050 (#351, keystone); `org_structure_type` (the PMBOK org-shape enum; V14, default `functional`) and a refs-only `team_roster` (`{person_ref, role_on_project}`; V15, no-inline-PII invariant) appended off the keystone's post-V13 tail (#262); five PMBOK artifact templates (charter, lessons-learned, change-log, RACI, stakeholder-register) + Tracker 8 (Stakeholder Register) + Tracker 9 (RACI) + OPERATIONS.md registration + deploy-sync wiring (#206); and a new `lifecycle-tailoring.md` mapping the 3-state agent model → PMBOK 5-process-group convention + 3 pointers (#371, foundation). `cross-cutting` class (Deep Stage-9 review; ADR-050 Proposed → Accepted at review). Carried a provisional v2.42 label; claimed v3.22 at the Stage-12 atomic claim (no collision). CHEAP / `git revert -m 1`; additive schema/template/reference fields, runtime blast radius none.

#### v3.21

Terminology & controlled-vocabulary canonicalization — the K1 terminology glossary is refreshed for AI-agent comprehension as autonomy expands: discoverable frontmatter, the Role term anchored to the Autonomy-Tier framework, and four first-class actor terms (Hub, Spoke, Skill, Sub-agent) (#68, keystone); the Tier Disambiguation Table in `autonomy-tiers.md` is extended to cover Hierarchy Tier with every other named convention's disposition stated (#128); and canonical `Initiative` / `Roadmap` terms are added to the glossary, reconciling it with the initiative-roadmap framework and the live `epic:*` label namespace, with Appendix B's "not modeled" assertion removed and ADR-049 recording the canonical vocabulary + the `initiative:` → `epic:`/`project:` label mapping (#432). `novel` class (#432 authors ADR-049 + carries the D-432-Wording canonical-vocabulary decision). Re-versioned v2.42 → v3.21 at the Stage-12 atomic claim (v3.20 spine frontier; see RELEASE_REVERSIONS). MODERATE / `git revert -m 1`; runtime blast radius none.

#### v3.20

Release-corpus verification surface (real checks, not grep proxies) — the two corpus tools rewired to the live `core/`/`release/` layout with deploy-checks made fail-loud (no more green-on-broken); bundle-issues parser to ≥90% combined-clean on the conformant-bundleable substrate; release-executor on live-taxonomy labels only; deploy-check class exits non-zero on path-resolution failure

#### v3.19

Stage 13 close-out reliability backstops (release-corpus completeness gate; outcome-bound mandatory-close mandate + documented merge-ahead path; CI smoke gate for the close-out tooling; schema-aware slug + locked-Keychain degradation; working orphan-branch `--apply` with chore-branch scope + stale-ref prune + post-apply verify)

#### v3.18

Corpus-integrity enforcement (reference-durability standard + three-primitive enforcement spine; three repository-integrity PR gates — depersonalization, issue-reference validity, dead-file references)
