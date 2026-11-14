---
title: Controls — prose-rule
purpose: The 118 controls whose mechanism kind is prose-rule, from the controls register
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Controls — prose-rule

118 controls from the controls register. The statement, the class and the surface are the register's cells. Cited by counts the pages that cite the control; the pages and steps are on [controls-cited](controls-cited.md).

| Control | Statement | Enforcement class | Surface | Source path | Cited by |
|---|---|---|---|---|---|
| C-265 | Resolve actionable items as far as possible; the operator reviews completed work, not to-do lists | prose-only | — | `core/CLAUDE.md.template` | — |
| C-266 | Never fabricate data; unknowns carry [ASSUMPTION – CONFIRM] with a proposed answer | prose-only | — | `core/CLAUDE.md.template` | — |
| C-267 | At most 5 clarifying questions; everything else becomes a labeled assumption | prose-only | — | `core/CLAUDE.md.template` | — |
| C-268 | All state lives in files; sessions are ephemeral | prose-only | — | `core/CLAUDE.md.template` | — |
| C-269 | A fact has one home: tacit knowledge in the auto-memory store, codified knowledge in the corpus; memory holds at most an eviction pointer, never a copy | code-warn | — | `core/CLAUDE.md.template` | — |
| C-270 | Validate the day of week on every date reference | prose-only | — | `core/CLAUDE.md.template` | — |
| C-271 | Every factual claim carries an evidence label ([SOURCE] [INFERRED] [ASSUMPTION – CONFIRM] [CONTEXT] [RECOMMENDED]) | code-warn | — | `core/CLAUDE.md.template` | — |
| C-272 | At session start run a lightweight drift check on governance-file claims; flag with ⚠️ DRIFT DETECTED and a severity (Critical blocks; Moderate flags; Low logs) | prose-only | — | `core/CLAUDE.md.template` | — |
| C-273 | Every skill documents ≥3 domain-specific failure modes in the 5-field template with a category tag | code-enforce | — | `core/CLAUDE.md.template` | — |
| C-274 | Decision-class outputs state a reversibility tier (CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE) paired with a confidence level; process weight scales with tier | prose-only | — | `core/CLAUDE.md.template` | — |
| C-275 | Review-class skills apply review-discipline-principles (anti-laziness, root cause, 6-deliverable output) | prose-only | — | `core/CLAUDE.md.template` | — |
| C-276 | Discovery-class work is first-class, fires at activity entry, and produces the five discovery outputs | prose-only | — | `core/CLAUDE.md.template` | — |
| C-277 | RCA is the invokable 6-step method for root-causing a defect; it cites the review-discipline format rather than redefining it | prose-only | — | `core/CLAUDE.md.template` | — |
| C-278 | Approval of a Document Tier 1 artifact authorizes downstream Tier 2 writes within its declared cascade_scope only; governance files never auto-cascade | prose-only | — | `core/CLAUDE.md.template` | — |
| C-279 | Before creating a new file, artifact or tracking issue, search existing governance / open issues / milestones for an owner and cite the search | prose-only | — | `core/CLAUDE.md.template` | — |
| C-280 | Intermediate working artifacts are absorbed into the target structure and discarded, never promoted to perpetuity | code-off | — | `core/CLAUDE.md.template` | — |
| C-281 | Operator approval of a multi-step plan authorizes end-to-end execution; stop only at the framework's named decision points | prose-only | — | `core/CLAUDE.md.template` | — |
| C-282 | Before executing a batch/class authorization (>3 state changes) enumerate the covered actions and name adjacent ones NOT covered | prose-only | — | `core/CLAUDE.md.template` | — |
| C-283 | AskUserQuestion renders a question that is already warranted; it never manufactures one | prose-only | — | `core/CLAUDE.md.template` | — |
| C-284 | State a skill-boundary cross before acting; flagging a boundary is not consent to cross it; a requested process is never substituted without a go-ahead | prose-only | — | `core/CLAUDE.md.template` | — |
| C-285 | Default to the smallest change that achieves the goal; read a file end-to-end before editing, deleting or pattern-scripting it; sweeps are read → classify → plan → edit per file | prose-only | — | `core/CLAUDE.md.template` | — |
| C-286 | Before recommending work derived from a non-canonical input, verify the gap against the canonical source and cite the verification | prose-only | — | `core/CLAUDE.md.template` | — |
| C-287 | Durable state goes to the record; a comment on an external seam is warranted only when it addresses a person and carries an ask or an answer | code-off | — | `core/CLAUDE.md.template` | — |
| C-288 | Operator notes are directional inputs, not authoritative specifications; no gross deletion or mass-restructure on notes alone without reconciling against SSOT and confirming | prose-only | — | `core/CLAUDE.md.template` | — |
| C-289 | A finding resting on a transiently-empty population pins a baseline (commit anchor + window) and re-checks before relying on it | prose-only | — | `core/CLAUDE.md.template` | — |
| C-290 | On architecture/design work give evidence-grounded pushback: verify premises against the repo before endorsing | prose-only | — | `core/CLAUDE.md.template` | — |
| C-291 | Read architecture-overview.md before asserting platform structure | prose-only | — | `core/CLAUDE.md.template` | — |
| C-292 | When changing any surface consult its column in the build-philosophy coverage matrix; an empty cell is a named gap | prose-only | — | `core/CLAUDE.md.template` | — |
| C-293 | Spoke model / effort is changed only at platform-config [spoke_runtime] (+ the per-stage overrides allowlist), then verified with deploy.sh --check | code-warn | — | `core/CLAUDE.md.template` | 1 page |
| C-294 | No status theater: recaps without decisions/actions are rejected; a correction comment instead of the in-scope fix is status theater | prose-only | — | `core/CLAUDE.md.template` | — |
| C-295 | No fabricated owners, dates or metrics | prose-only | — | `core/CLAUDE.md.template` | — |
| C-296 | No task dumping: actions ship as full packages | prose-only | — | `core/CLAUDE.md.template` | — |
| C-297 | No [INSERT] or [TBD] placeholders in outputs | code-warn | — | `core/CLAUDE.md.template` | — |
| C-298 | No question flooding (>5 questions) | prose-only | — | `core/CLAUDE.md.template` | — |
| C-299 | No passive risk voice: name the risk, owner, mitigation | prose-only | — | `core/CLAUDE.md.template` | — |
| C-300 | No unmarked recommended dates (use [RECOMMENDED]) | prose-only | — | `core/CLAUDE.md.template` | — |
| C-301 | Consistent vendor labels | prose-only | — | `core/CLAUDE.md.template` | — |
| C-302 | Day-of-week validation on all dates | prose-only | — | `core/CLAUDE.md.template` | — |
| C-303 | No generalized date ranges in communications/status outputs; stop and ask when a date cannot be verified; surface conflicts | prose-only | — | `core/CLAUDE.md.template` | — |
| C-304 | Never report a write as done before it executed and was confirmed; tiered write sequences (approval for Tier 1/4; write-then-confirm for Tier 2) | prose-only | — | `core/CLAUDE.md.template` | — |
| C-305 | When a hook blocks an action with no agent-side alternative and a user-side equivalent exists, emit the structured Hook-Blocked → User-Side Handoff template and verify after the user runs it | prose-only | — | `core/CLAUDE.md.template` | — |
| C-306 | No strikethrough in generated project artifacts (one named exception for chat-ready status messages) | prose-only | — | `core/CLAUDE.md.template` | — |
| C-307 | Generated project artifacts target the active project's 01-08 folders or its 08-Generated/ staging area, never workspace or projects/ root | prose-only | — | `core/CLAUDE.md.template` | — |
| C-308 | Any modification to governance files, skills, folder structure, protocols or runtime harness tooling requires a GitHub Issue plus an approved implementation plan; per-path review mechanics follow (Cowork dry-run+snapshot; Claude Code branch+PR) | code-enforce (partial) | — | `core/CLAUDE.md.template` | — |
| C-309 | Prefer decision tables, schemas, rule sets and parameterized templates over prose examples and point-in-time narratives in governance files | prose-only | — | `core/CLAUDE.md.template` | — |
| C-310 | Reference the source of truth rather than embedding a value that will change (dates, versions, counts) | code-warn | — | `core/CLAUDE.md.template` | — |
| C-311 | Whenever a gap, inconsistency, broken handoff, missing artifact or improvement is identified during ANY processing, route it through intake-desk Mode C (ambient auto-log) under the automation_level ceiling — never mention a signal without routing it | prose-only | — | `core/CLAUDE.md.template` | — |
| C-312 | If SESSION_STATE.md Last Updated is older than 2 business days, flag it stale and recommend a full-state refresh | prose-only | — | `core/CLAUDE.md.template` | — |
| C-313 | At session start, a session running in a platform worktree whose work is operational/non-code STOPs and recommends relaunch in the operations workspace (auto-generated claude/* branch is the signal) | prose-only | — | `core/CLAUDE.md.template` | — |
| C-314 | All changes go through PRs; no direct commits to main | prose-only | — | `core/rules/git-workflow.md` | — |
| C-315 | Branch names follow feature/#N-…, fix/…, release/`<slug>` (slug-primary, no version stem); lowercase hyphenated | code-warn | — | `core/rules/git-workflow.md` | — |
| C-316 | An issue reference in a commit message is reference-only — never a close-family verb directly before #N (subject or body) | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-317 | Never use --no-verify; respect pre-commit hooks | prose-only | — | `core/rules/git-workflow.md` | — |
| C-318 | Never cd into the primary checkout and never run state-changing git operations there from a Claude Code session | prose-only | — | `core/rules/git-workflow.md` | — |
| C-319 | A spawned spoke has NO primary access — it operates only in its own worktree | prose-only | — | `core/rules/git-workflow.md` | — |
| C-320 | Never restore a user's uncommitted change without asking; diagnose by content before any irreversible discard | prose-only | — | `core/rules/git-workflow.md` | — |
| C-321 | After gh pr merge in a worktree never checkout main there — detach, remove, or branch; ExitWorktree is a no-op on harness worktrees | prose-only | — | `core/rules/git-workflow.md` | — |
| C-322 | Sweep-deletion of other sessions' worktrees re-lists before each delete, gates force-removal on a clean dirty-check, and verifies liveness per live process | prose-only | — | `core/rules/git-workflow.md` | — |
| C-323 | The primary checkout MUST always sit at origin/main; fast-forward it by default; stop only on a real conflict | prose-only | — | `core/rules/git-workflow.md` | — |
| C-324 | Worktrees are for platform-engineering work only; operations-domain work never runs from a worktree | prose-only | — | `core/rules/git-workflow.md` | — |
| C-325 | The PR body MUST carry closes #N per resolved issue in the Issue References block; partial PRs use References/Related, never a close-family verb | code-enforce (leak half) / prose-only (presence half) | — | `core/rules/git-workflow.md` | — |
| C-326 | Close-keyword parser-clean discipline — PR TITLE: no close-family verb before #N | code-warn | — | `core/rules/git-workflow.md` | — |
| C-327 | Close-keyword parser-clean discipline — COMMIT MESSAGES: no close-family verb before #N anywhere | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-328 | Pre-submit spot-check: run check-commit-close-keywords.py before every push and grep the body draft before gh pr create | prose-only | — | `core/rules/git-workflow.md` | — |
| C-329 | Release tags are signed-annotated; signing is never bypassed; a release version is claimed atomically by claim-version.sh, never hand-typed | prose-only | — | `core/rules/git-workflow.md` | — |
| C-330 | Branch cleanup uses cleanup-orphan-state.sh (dry-run default; --apply; --force double opt-in; protective classes never removed) | prose-only | — | `core/rules/git-workflow.md` | — |
| C-331 | PR titles follow type(scope): summary (#N) with the closed type set | code-warn | — | `core/rules/git-workflow.md` | — |
| C-332 | Durable-corpus files state rules inline, summarize rather than link, confine bare issue refs to a reference block; per-file override markers allowed | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-333 | No operator identifying values or collaborator names in core/ release/ operations/ packages/ (ADR deciders: name carve-out) | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-334 | Every issue reference in a changed markdown file resolves in this repo and sits in a designated reference block; allow-issue-ref markers carry a limb rationale | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-335 | No markdown link or image in the documentation corpus targets a missing file or heading | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-336 | Version tags are permanent: no procedure may prescribe deleting one; orphan tags are retained and recorded; rollback never deletes the tag | host-config | — | `core/rules/git-workflow.md` | — |
| C-337 | Every session begins with the 7-step Session Start Checklist (pwd context, clean tree, no Layer-2 leakage, Cowork diff, merge origin/main, read CLAUDE.md, read SESSION_STATE) | prose-only | — | `core/rules/git-workflow.md` | — |
| C-338 | Never force push | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-339 | Never git add . or git add -A — stage files explicitly | prose-only | — | `core/rules/git-workflow.md` | — |
| C-340 | Never commit Layer 2/3 files | code-enforce | — | `core/rules/git-workflow.md` | — |
| C-341 | Never run a batch gh/CLI query with a result cap without first computing the dataset size and setting the limit above it | prose-only | — | `core/rules/git-workflow.md` | — |
| C-342 | Never commit draft / scratch / proposal / working-notes content as a tracked file; homes are the issue tracker or the git-ignored runtime tier | code-warn | — | `core/rules/git-workflow.md` | — |
| C-343 | A truncated read must never feed a typed-field write (two pre-write guards + post-mutation read-back per gh-api-convention) | prose-only | — | `core/rules/git-workflow.md` | — |
| C-344 | DTA-1: when about to report a zero / clean / absent / N-of-M probe result, perform the ground-truth read (run the sensitivity arm in the same shape and state the denominator) and emit the [DTA-1: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-345 | DTA-2: when about to rely on a delegated agent's or tool's self-reported summary, perform the ground-truth read (read the underlying artifact at its canonical home) and emit the [DTA-2: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-346 | DTA-3: when about to conclude from a population observed empty, perform the ground-truth read (pin a baseline (commit anchor + window) and re-check) and emit the [DTA-3: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-347 | DTA-4: when about to recommend work derived from a point-in-time artifact, perform the ground-truth read (run the audit-snapshot reconciliation primitives ([VERIFIED …] trailer)) and emit the [DTA-4: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-348 | DTA-5: when about to report a write or state mutation as done, perform the ground-truth read (read back the mutated state) and emit the [DTA-5: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-349 | DTA-6: when about to create an unrequested durable claim in the operator auto-memory store, perform the ground-truth read (search the corpus for a governed home; save only if durable, non-obvious and homeless) and emit the [DTA-6: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-350 | DTA-7: when about to report a rename / move / delete as done, perform the ground-truth read (re-run the identical search for the old identifier ([REFCASCADE …] trailer)) and emit the [DTA-7: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-351 | DTA-8: when the operator disputes a factual claim for which a settling read exists, perform the ground-truth read (re-read the truth-maker with a differently-shaped read; HOLD or YIELD, once per proposition) and emit the [DTA-8: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-352 | DTA-9: when about to act on your own finding under an analysis-only mandate, perform the ground-truth read (re-read the operative ask and name the authorization) and emit the [DTA-9: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-353 | DTA-10: when about to conclude a comment is warranted on an external seam or a field there is safe to write, perform the ground-truth read (read the destination surface itself (state vs conversation; the two limbs; authorship class)) and emit the [DTA-10: …] token (or the governing trailer) | prose-only | — | `core/rules/decision-time-adherence.md` | — |
| C-354 | Under an analysis-only mandate, finish the analysis, hold the implied action, name what is held and what would authorize it, and emit the DTA-9 token | prose-only | — | `core/rules/analysis-mandate.md` | — |
| C-355 | Do not author a third general read-only guardrail; a new surface cites this rule and names only its own boundary | prose-only | — | `core/rules/analysis-mandate.md` | — |
| C-356 | A rename / move / delete of a referenceable entity sweeps every reference form and surface, updates every hit in the same change, re-runs the search to zero and emits [REFCASCADE: … pre N / post 0] | prose-only | — | `core/rules/rename-reference-cascade.md` | — |
| C-357 | A stated count of an enumerated set is a reference and is updated with the set | code-enforce (narrow) | — | `core/rules/rename-reference-cascade.md` | — |
| C-358 | In a mirror-pair file, a link to a non-mirrored target MUST use the leading-/ workspace-rooted form; the bare module-prefix form MUST NOT be used | code-enforce (added lines) | — | `core/rules/doc-link-maintenance.md` | — |
| C-359 | Stage 13 Close at the first release after merge MUST include a Check 14 flip-to-enforce assessment line; silent deferral is a process violation | prose-only | — | `core/rules/doc-link-maintenance.md` | 3 pages |
| C-360 | Until automation ships, operators run the Pattern-C temporal-language grep after reorgs / migrations / Stage 9 review | prose-only | — | `core/rules/doc-link-maintenance.md` | — |
| C-361 | An allowlist entry documents WHY the path is allowlisted; prefer a native engine skip over an allowlist entry | prose-only | — | `core/rules/doc-link-maintenance.md` | — |
| C-362 | A platform (Claude Code) session NEVER modifies Layer 2 files and never writes into projects/ | code-off | — | `core/rules/operations-bridge.md` | — |
| C-363 | An Operations session writing into pmo-platform/ is blocked unconditionally | code-enforce | — | `core/rules/operations-bridge.md` | — |
| C-364 | A Layer-1 file modified outside git (by Cowork) is reviewed; intentional → commit; accidental → restore; and an issue is created for the boundary violation | prose-only | — | `core/rules/operations-bridge.md` | — |
| C-365 | Close Cowork before git operations (no file locking between the two tools) | prose-only | — | `core/rules/operations-bridge.md` | — |
| C-366 | The operations context anchor's paths resolve relative to the anchor's own location, never the session cwd; it restates no procedure | prose-only | — | `core/rules/operations-bridge.md` | — |
| C-367 | The package never writes operator CONTENT; the installer/update path seeds managed Layer-2 files install-if-missing only | prose-only | — | `core/rules/operations-bridge.md` | 4 pages |
| C-368 | Edit governance files only on a feature branch; read the file completely first; the change must be part of an approved plan or issue | code-enforce (partial) | — | `core/rules/governance-files.md` | — |
| C-369 | All governance changes require a GitHub Issue + user approval; no quick fixes without a paper trail; the PR diff is the review | prose-only | — | `core/rules/governance-files.md` | — |
| C-370 | Check cross-file impact (CLAUDE.md ↔ OPERATIONS.md ↔ skills ↔ RELEASE_PROTOCOL ↔ release-process) and consult memory-architecture before writing any memory surface | prose-only | — | `core/rules/governance-files.md` | — |
| C-371 | After committing, review git diff main..HEAD, confirm no Layer 2/3 files changed, and ensure evidence labels on factual claims | prose-only | — | `core/rules/governance-files.md` | — |
| C-372 | Harness deploy MUST NEVER overwrite operator state: config.toml only-if-missing; target-only files never touched | code-off | — | `core/rules/harness-deployment.md` | 1 page |
| C-373 | Never copy a rules file into .claude/rules by hand — deploy.sh --deploy is the carrier; Check 9 verifies the mirror | code-warn | — | `core/rules/harness-deployment.md` | 1 page |
| C-374 | Every holder of the mirror-pair source set MUST carry the in-band mirror-pair-set marker so parity is asserted | code-warn | — | `core/rules/harness-deployment.md` | — |
| C-375 | Modifications to any SKILL.md or its references MUST flow through pmo-skill-editor | code-warn | — | `core/rules/skill-deployment.md` | — |
| C-376 | Editing a single-sourced canonical makes every consumer's mirror and .skill package stale — rebuild and re-sync in the same change | code-enforce | — | `core/rules/skill-deployment.md` | 1 page |
| C-377 | Skill counts are derived from the deploy.sh arrays, never hardcoded; the canary is never added to totals | code-enforce (narrow) | — | `core/rules/skill-deployment.md` | 3 pages |
| C-378 | Package freshness is asserted at two surfaces (deploy-time Check 7 always-enforce; pre-merge CI under its own sentinel) and they do not fail alike | code-enforce | — | `core/rules/skill-deployment.md` | 1 page |
| C-379 | The post-merge deploy hook carries no release identity and MUST NOT gain one; a release-stamped deploy never auto-detects and MUST resolve to one of two dispositions | prose-only | — | `core/rules/skill-deployment.md` | 3 pages |
| C-380 | Every hook rule that wrote drain rows since the previous review receives a specificity reading (classified sample with denominator) at each Stage 13 Close (HSR-1) | prose-only | — | `core/rules/bypass-mode-readiness.md` | 3 pages |
| C-381 | A warn-mode hook flips to enforce only after a ≥3-day warn-log review and allowlisting of legitimate false positives | prose-only | — | `core/rules/bypass-mode-readiness.md` | 2 pages |
| C-382 | Report a control firing as a layer-level signal (HSR-2) and maintain allowlists only through allowlist-add.sh | prose-only | — | `core/rules/bypass-mode-readiness.md` | 1 page |
