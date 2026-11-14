---
title: Controls — deploy-check
purpose: The 83 controls whose mechanism kind is deploy-check, from the controls register
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Controls — deploy-check

83 controls from the controls register. The statement, the class and the surface are the register's cells. Cited by counts the pages that cite the control; the pages and steps are on [controls-cited](controls-cited.md).

| Control | Statement | Enforcement class | Surface | Source path | Cited by |
|---|---|---|---|---|---|
| C-119 | Every rostered skill's deployed copy is byte-identical to its module source | code-enforce | deploy-run | `core/deploy/deploy.sh` | 6 pages |
| C-120 | Every rostered skill has a compiled .skill package at the v2 packages/ root | code-enforce | deploy-run | `core/deploy/deploy.sh` | 4 pages |
| C-121 | No case-insensitive duplicate skill names exist across the deployed set | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-122 | The governance files the platform depends on are present at their canonical paths | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-123 | The deployed skill roster matches the deploy.sh module arrays (no stray or missing skill) | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-124 | Every rostered skill has a registry row and every row resolves to a live SKILL.md; row FIELD currency is reported | code-enforce (row layer) / code-warn (field layer) | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-125 | Every rostered SKILL.md carries the required frontmatter, meets the references threshold and documents ≥3 domain-specific failure modes | code-enforce | deploy-run | `core/deploy/deploy.sh` | 3 pages |
| C-126 | Every rostered skill's .skill package content-hash reflects current source | code-enforce | deploy-run | `core/deploy/deploy.sh` | 4 pages |
| C-127 | Deployed canonical-session-path artifacts are fresh against their source | code-warn | deploy-run | `core/deploy/deploy.sh` | 2 pages |
| C-128 | Every declared mirror pair (core/rules → `<deploy-root>`/.claude/rules) is byte-identical and, on a deployed workspace, EXISTS | code-warn | deploy-run | `core/deploy/deploy.sh` | 6 pages |
| C-129 | Every migrated skill carries the pmo-skill-editor audit trail (D-Editor dual gate) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-130 | Every registered harness artifact has a runtime counterpart byte-identical to source (operator-state files excluded) | code-enforce (vacuous) | deploy-run | `core/deploy/deploy.sh` | 3 pages |
| C-131 | The user-local skills mirror matches the deployed set | code-enforce | deploy-run | `core/deploy/deploy.sh` | 6 pages |
| C-132 | Every registered injected reference file is byte-identical to its canonical source in every consumer skill | code-enforce | deploy-run | `core/deploy/deploy.sh` | 4 pages |
| C-133 | Same-basename reference files spanning the canonical corpus and skill-local references/ trees are either registered complementary pairs with asserted shared sections, or surfaced as unregistered | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-134 | No governance / reference / rules / SKILL.md link in the declared scan scope is broken (shared --target-paths-file + tracked base allowlist) | code-warn | deploy-run | `core/deploy/deploy.sh` | 3 pages |
| C-135 | (retired in v2 — release-corpus cross-link integrity; number reserved, no body) | not-a-control | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-136 | Every intake issue satisfies the status-label invariants I1-I4 (exactly one status label; no contradictions) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-137 | status:proposed issues older than 14/30/45 days are flagged warn / escalate / critical | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-138 | Version anchors in the framework corpus agree | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-139 | The pipeline event log parses and satisfies its schema invariants | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-140 | Every release note conforms to release-notes-standard § 3.2 (via lint_release_corpus.py) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-141 | Issue-body dependency statements agree with native sub-issue / dependency links | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-142 | Every issue bundled into a milestone satisfies gate G1 (intake readiness) — live arm | code-warn | deploy-run | `core/deploy/deploy.sh` | 3 pages |
| C-143 | Every RELEASE_LOG row has a consistent RELEASE_INDEX row | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-144 | (initiative-roadmap staleness scan — retired, number reserved) | not-a-control | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-145 | Universal corpus surfaces carry no localized (operator/engagement-specific) context needles (DC1-DC4 + DC6) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-146 | Every release has its release-notes file (release-notes-standard AC 3) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-147 | Hub-spawned spoke agent files carry the designated model from platform-config [spoke_runtime] / the overrides allowlist | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-148 | Recent release PRs adhere to the doc-impact template at Stage 13 close | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-149 | Hub-spawned spoke definitions conform to the return-value contract | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-150 | pmo-authored slash commands quote $ARGUMENTS safely | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-151 | The durable corpus's fragile-reference saturation snapshot reproduces run-to-run; override markers are recognised | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-152 | Every RELEASE_LOG row at/after the corpus cutover implies its INDEX row + DIGEST entry + NOTES file (+ tag + published Release post-cutover) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-153 | The published GitHub Release body equals the frontmatter-stripped in-repo note | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-154 | Every VERIFIED RELEASE_LOG row has the full Stage-13 output set on main | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-155 | The platform-config template/instance surfaces are structurally sound | code-warn | deploy-run | `core/deploy/deploy.sh` | 2 pages |
| C-156 | Schema-bearing templates match their governing schema field sets | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-157 | Multi-mode SKILL.md mode enums stay recognizable from their triggers | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-158 | Auto-memory entries tied to corpus homes have not drifted (memory↔corpus boundary backstop) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-159 | Every core/hooks/block-*.sh maps to its declared owning doc and registry row | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-160 | The committed bypass-mode-readiness.md is byte-identical to what build-hook-registry.py regenerates | code-enforce | deploy-run | `core/deploy/deploy.sh` | 5 pages |
| C-161 | The platform .version stamp matches the latest published Release | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-162 | The touchpoint-inventory instance is structurally valid | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-163 | A release's candidate version is not already claimed (claim-time candidate vs claimed set) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-164 | K1-tier corpus prescribes no host-specific gh/git mechanism (host-binding leak) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-165 | Executable surfaces hardcode no operator-local install paths | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-166 | All tracked files use the registered depersonalization tokens (both delimiter families) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-167 | Every design-principle register row's governing_doc path:line resolves and contains the entry name | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-168 | Hub-spawned spoke agent files conform to the tools-list recursion ratchet | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-169 | Naming / layer-2 / evidence-label / placeholder / event-log-key conventions hold corpus-wide | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-170 | Every core/** platform doc carries the required frontmatter (title, purpose, type, status, reversibility …) | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-171 | The repository label set matches core/specs/label-taxonomy.md | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-172 | Milestone positions on the host match the corpus | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-173 | The approved-but-unbundled queue stays within its depth threshold | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-174 | Doc / backlog / coextension work-hierarchy legs (H1/H2/H3) agree | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-175 | Milestone membership, description reconciliation, scaffold completeness and sub-task orphan invariants (M1-M4) hold | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-176 | No two producers claim the same entity rendering (ADR-044 I1+I3+I4) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-177 | Every check def-block and emitter honours the roster extraction contract | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-178 | Proposed ADRs carrying a flip promise are surfaced — ADVISORY ONLY, never enforce-capable | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-179 | On a release branch before the Stage-12 claim, neither the branch name nor the plan basename binds a concrete version | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-180 | Every block-*.sh declares a valid MASTER_ENABLE_CLASS and all 7 D-R9 security/floor hooks declare security | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-181 | Every VERIFIED post-cutover release emitted each MUST decision class (resolved via the event-log release join key) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-182 | Every gate-coverage register runner-def / runner-src pointer resolves to a runner that carries the predicate | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-183 | A stated cardinality in the corpus reconciles with the structure beneath it (narrow scope; frozen artifacts exempt; baseline allowlist arm warn) | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-184 | Every var(--x) consumer is declared in every theme block | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-185 | The hot RELEASE_LOG stays within its row budget (archival trigger) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-186 | Line-number citation locators in the skill self-description tree still resolve | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-187 | No two skills' trigger phrases collide above threshold (registry-linked pairs exempt from WATCH) | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-188 | Derived template/playbook restatements of hub-state enums match the owning standard | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-189 | One sanctioned spelling of the degraded-state terminal token corpus-wide | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-190 | operator.toml declaration/template parity, no hand-written emit, and spec/template/declaration registry parity hold (MIXED MODE) | code-enforce (parity arms) / code-warn (schema arm) | deploy-run | `core/deploy/deploy.sh` | 6 pages |
| C-191 | The -022 exec/interp arms' deadline (repo-derivable) has not lapsed without a graduation decision; the evidence arm (operator-local drain review) is advisory (MIXED MODE) | code-enforce (deadline arm) / code-warn (evidence arm) | deploy-run | `core/deploy/deploy.sh` | 3 pages |
| C-192 | Numeric section anchors in OPEN issue bodies still resolve to their target headings — ADVISORY ONLY | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-193 | The G3-14 / G3-15 evaluators discriminate, their sinks cohere and config resolves (tree-resident half only) | code-warn | deploy-run | `core/deploy/deploy.sh` | 2 pages |
| C-194 | Warn-mode gates past their committed deadline have a recorded graduation decision (deadline arm) — evidence arm advisory (MIXED MODE) | code-enforce (deadline arm) / code-warn (evidence arm) | deploy-run | `core/deploy/deploy.sh` | 3 pages |
| C-195 | Work-item type packs conform to the meta-schema | code-warn | deploy-run | `core/deploy/deploy.sh` | 1 page |
| C-196 | Every declared automation has a conforming routine-spec row and every row round-trips to its entrypoint | code-enforce | deploy-run | `core/deploy/deploy.sh` | 7 pages |
| C-197 | Every marker-registered holder of the mirror-pair source set declares an identical set | code-warn | deploy-run | `core/deploy/deploy.sh` | 5 pages |
| C-198 | The deployed rules set stays within the published byte ceiling and every member carries the admission frontmatter | code-warn | deploy-run | `core/deploy/deploy.sh` | 5 pages |
| C-199 | Hook-tier publish map closure holds (enforcing-capable arm); deployed byte parity is advisory (MIXED) | code-enforce (map-closure arm) / code-warn (byte-parity arm) | deploy-run | `core/deploy/deploy.sh` | 2 pages |
| C-200 | Declared kinds take a position on every surface and every position names its source | code-warn | deploy-run | `core/deploy/deploy.sh` | 3 pages |
| C-201 | Every interpreter-line file under release/tools/ and core/deploy/tools/ is tracked executable or named by the exemption list with a reason | code-enforce | deploy-run | `core/deploy/deploy.sh` | 1 page |
