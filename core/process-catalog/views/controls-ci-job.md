---
title: Controls — ci-job
purpose: The 55 controls whose mechanism kind is ci-job, from the controls register
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Controls — ci-job

55 controls from the controls register. The statement, the class and the surface are the register's cells. Cited by counts the pages that cite the control; the pages and steps are on [controls-cited](controls-cited.md).

| Control | Statement | Enforcement class | Surface | Source path | Cited by |
|---|---|---|---|---|---|
| C-202 | Every declared automation is admitted to core/automations/registry.md (conformance + coverage) | code-enforce | ci-run | `.github/workflows/automation-registry-check.yml` | 4 pages |
| C-203 | The behavioural-regression eval corpus scores at or above [behavioral_regression].pass_rate_floor | code-warn | ci-run | `.github/workflows/behavioral-regression.yml` | — |
| C-204 | Every VERIFIED RELEASE_LOG row carries its complete Stage-13 output set (Check 48 verdict) | code-warn | ci-run | `.github/workflows/close-completeness.yml` | 2 pages |
| C-205 | No commit message in the PR range carries operator identity strings; close-keyword step: no close-family verb directly before an issue reference | code-enforce | merge-gate | `.github/workflows/commit-message-depersonalization.yml` | — |
| C-206 | Every commit in the PR range carries a host-verified signature (API verification object, never local git) | code-enforce | ci-run | `.github/workflows/commit-signature-check.yml` | — |
| C-207 | deploy.sh --self-test assertion group DE still discriminates (anti-vacuity arms) | code-enforce | ci-run | `.github/workflows/decision-emission.yml` | 2 pages |
| C-208 | Every VERIFIED post-cutover release emitted each MUST class — reported | code-warn | ci-run | `.github/workflows/decision-emission.yml` | 2 pages |
| C-209 | Checks 38, 73, 77, 78 pass pre-merge (`deploy.sh --check-required-subset`) | code-enforce | merge-gate | `.github/workflows/deploy-check-ci.yml` | 3 pages |
| C-210 | The eval-viewer Python test suite passes | code-enforce | merge-gate | `.github/workflows/eval-viewer-tests.yml` | — |
| C-211 | The eval-viewer headless-DOM tests pass | code-enforce | merge-gate | `.github/workflows/eval-viewer-tests.yml` | — |
| C-212 | The reconciler's self-test passes and the declared set is readable; performs the live branch-protection read | code-enforce | ci-run | `.github/workflows/gate-posture-reconciliation.yml` | 2 pages |
| C-213 | Declared-required contexts and live required_status_checks.contexts do not diverge (UNREGISTERED / HELD-AND-REGISTERED / UNDECLARED) | code-enforce | ci-run | `.github/workflows/gate-posture-reconciliation.yml` | 3 pages |
| C-214 | The core/deploy shell test suites pass (incl. the G1 resolver fixtures — Check 22 integrity arm) | code-enforce | merge-gate | `.github/workflows/install-tests.yml` | 4 pages |
| C-215 | Every core/hooks/tests/*.test.sh passes via test-runner.sh in a sandboxed deployed layout | code-enforce | merge-gate | `.github/workflows/install-tests.yml` | 3 pages |
| C-216 | Install / onboarding / update regression suites pass | code-enforce | merge-gate | `.github/workflows/install-tests.yml` | 4 pages |
| C-217 | Install/QA passes on the three OS runners (3 contexts) | code-enforce | merge-gate | `.github/workflows/install-tests.yml` | 4 pages |
| C-218 | No broken outbound link in the Check-14 scan scope (same engine, scope list and base allowlist as Check 14) | code-warn | ci-run | `.github/workflows/link-check.yml` | — |
| C-219 | Every deployed-skill reference resolves from a reconstructed runtime root | code-warn | ci-run | `.github/workflows/link-check.yml` | — |
| C-220 | No changed file references the operator-local memory store | code-enforce | merge-gate | `.github/workflows/operator-memory-ref.yml` | — |
| C-221 | No close-family keyword + issue number appears in the PR body outside the dedicated Issue References block | code-enforce | ci-run | `.github/workflows/pr-body-parser-clean.yml` | — |
| C-222 | The PR title follows type(scope): summary (#N) with no close-family verb before #N | code-warn | ci-run | `.github/workflows/pr-title-convention.yml` | — |
| C-223 | No added line in a durable-corpus file introduces a fragile reference (Classes L/V/positional enforce; Class U raw-URL warn-mode-initial) | code-enforce (Class U arm code-warn) | merge-gate | `.github/workflows/reference-durability.yml` | — |
| C-224 | Every RELEASE_LOG row at/after the cutover implies INDEX + DIGEST + NOTES (+ tag + Release) — Check 32 verdict | code-warn | ci-run | `.github/workflows/release-corpus-completeness.yml` | 2 pages |
| C-225 | Every intra-repo link under release/ resolves (check-release-links.py full walk) | code-enforce | ci-run | `.github/workflows/release-link-check.yml` | — |
| C-226 | The close-out automation's offline corpus-path smoke and the suites the job hosts pass on every PR | code-enforce | merge-gate | `.github/workflows/release-tooling-smoke.yml` | — |
| C-227 | Every tool that dispatches on --self-test across the two release tool trees runs it and passes (discovered set) | code-enforce | ci-run | `.github/workflows/release-tooling-smoke.yml` | — |
| C-228 | The FinOps usage-extractor self-tests pass | code-enforce | ci-run | `.github/workflows/release-tooling-smoke.yml` | 3 pages |
| C-229 | No changed file under core/ release/ operations/ packages/ carries the operator's identifying values or a collaborator's name (ADR deciders: carve-out) | code-enforce | merge-gate | `.github/workflows/repo-integrity.yml` | — |
| C-230 | Every issue reference in a changed markdown file resolves in this repo and sits in a designated reference block (release-tracking surface exempt) | code-enforce | merge-gate | `.github/workflows/repo-integrity.yml` | — |
| C-231 | No added-line markdown link or image targets a missing file (anchors warn-mode) | code-enforce (anchor arm code-warn) | merge-gate | `.github/workflows/repo-integrity.yml` | — |
| C-232 | The global ADR-NNN sequence across both ADR directories is unique and gap-free; index projection faithful; renumber fixture behaves | code-enforce | merge-gate | `.github/workflows/repo-integrity.yml` | — |
| C-233 | No file added by the PR has a draft / scratch / proposal path shape (CI twin of BLOCK-DRAFT-001) | code-warn | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-234 | The charter's Governance File Map agrees with the tree | code-warn | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-235 | No path reintroduces the legacy Projects/ casing | code-warn | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-236 | Changed ADR files' added lines satisfy the ADR durability rules (status enum, no pinned SHA/count, no handle, no bare ref in identity fields) | code-warn | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-237 | No added shell line pipes into a short-circuiting reader outside the three exemption tiers | code-enforce | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-238 | One sanctioned spelling of the degraded-state token (Check 69 mirror) | code-enforce | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-239 | operator.toml declaration/template/spec parity (Check 70 mirror) | code-enforce | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-240 | Interpreter-line tool files are tracked executable or exempted (Check 81 mirror) | code-enforce | ci-run | `.github/workflows/repo-integrity.yml` | — |
| C-241 | Workflow files pass actionlint | code-enforce | merge-gate | `.github/workflows/security.yml` | 3 pages |
| C-242 | Python sources pass bandit | code-enforce | merge-gate | `.github/workflows/security.yml` | 3 pages |
| C-243 | The custom semgrep rule self-tests and finds no template-context XSS | code-enforce | merge-gate | `.github/workflows/security.yml` | 3 pages |
| C-244 | Python dependencies carry no known vulnerabilities | code-enforce | merge-gate | `.github/workflows/security.yml` | 3 pages |
| C-245 | No secret in the PR delta (full-history audit step is continue-on-error: reported only) | code-enforce | merge-gate | `.github/workflows/security.yml` | 3 pages |
| C-246 | Hooks fail closed under enforce when the dependency helper is missing or corrupt | code-enforce | ci-run | `.github/workflows/security.yml` | 3 pages |
| C-247 | The eval-viewer security regression holds | code-enforce | ci-run | `.github/workflows/security.yml` | 3 pages |
| C-248 | The dark-branch classifier self-tests and the sweep input is usable | code-enforce | ci-run | `.github/workflows/sibling-merge-dark-branch.yml` | — |
| C-249 | No push to main leaves an open PR newly unmergeable without that being reported | code-enforce | ci-run | `.github/workflows/sibling-merge-dark-branch.yml` | — |
| C-250 | Every rostered SKILL.md is canonical-structure compliant pre-merge | code-warn | ci-run | `.github/workflows/skill-canonical-structure-check.yml` | — |
| C-251 | The PR introduces no stale skill-count literal or deprecated IMP-XXX reference | code-enforce | merge-gate | `.github/workflows/skill-count-imp-check.yml` | — |
| C-252 | Every compiled .skill package carries the BSL LICENSE | code-enforce | ci-run | `.github/workflows/skill-license-check.yml` | — |
| C-253 | Every rostered skill's .skill package reflects current source (Check 7 content hash) — STALE or NOT-EVALUATED exits 1 | code-enforce | merge-gate | `.github/workflows/skill-package-freshness.yml` | 3 pages |
| C-254 | Every rostered skill has a registry row and every row resolves (row layer) | code-enforce | ci-run | `.github/workflows/skill-registry-currency-check.yml` | — |
| C-255 | The candidate release version is not already claimed (Check 41 verdict) | code-warn | ci-run | `.github/workflows/version-freeness.yml` | 2 pages |
| C-454 | No commit or annotated tag a push adds carries a home-directory path, phone number, or personal-email pattern (accepted homes excepted), or a needle from the optional PII_NEEDLES secret; detective only, since the pushed branch is public before the job runs; findings are redacted | code-enforce | ci-run | `.github/workflows/pii-push-scan.yml` | — |
