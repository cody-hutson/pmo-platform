<!-- repo-integrity: allow-issue-ref -->
<!-- PR TITLE: type(scope): summary (#N) — type one of {release,feat,fix,chore,docs,refactor,ci,test,revert}; scope = vX.Y for release PRs or a component (ci, a skill name); #N reference-only (no close-family verbs in the title). See core/rules/git-workflow.md section PR Title Convention. -->
## vX.Y: [Release Title]

### Summary (30 seconds)
<!-- What shipped, key decisions, any deviations from plan. -->
<!-- DO NOT write close/closes/closed/fix/fixes/fixed/resolve/resolves/resolved followed by #N here. -->
<!-- GitHub's auto-close parser is lexical — it triggers regardless of section context or surrounding negation. -->
<!-- Reference issues with "Issue #N" or bare "#N" without a close-family verb. -->

### Implementation

| Issue | Title | Sub-tasks | Status | Key Commits |
|---|---|---|---|---|
| #N | [title] | N/N | DONE | abc1234 |

<!-- Status: DONE = fully implemented, PARTIAL = implemented with caveats (explain in Deviation Log), SKIP = not implemented -->
<!-- For single-issue PRs, one row. For multi-issue release PRs, one row per issue. -->
<!-- Avoid close-family verbs + #N in title or status cells — use safe phrasing like "#N → Closed at Stage 13" or "mark #N as closed". -->

### Documentation Impact
<!-- Per-issue resolution of Stage 1 Documentation Impact declaration.  -->
<!-- One row per in-PR issue. Status: LINKED / CREATED / UPDATED / NONE. -->
<!-- NONE applies when the issue declared `None — no documentation impact (rationale: ...)` at Intake. -->
<!-- Resolution gate fires at Stage 13 Close (G-CL8 via deploy.sh Check 28). -->
<!-- Scope: K1 codified corpus only (.claude/rules/, pmo-platform/reference/, pmo-platform/governance/, pmo-platform/skills/*/SKILL.md + references/, CLAUDE.md). -->

| Issue | Declared docs | Status | Commit(s) | Notes |
|---|---|---|---|---|
| #N | file_a / file_b | LINKED / CREATED / UPDATED / NONE | abc1234 | optional |

### Deviation Log
<!-- Departures from release plan with severity (minor / scope / plan-rejection). "None" if clean execution. -->
<!-- Same parser-clean rule applies: do not write close/fixes/resolves followed by #N in deviation narratives. -->

### Verification Evidence
<!-- Per-issue checks, integration checks, regression checks, sync checks, layer boundary compliance. -->
<!-- When listing checks per issue, write "issue #N verified" not "fixes #N verified". -->

### Release Plan
<!-- Link to release plan file on this branch. -->

---

### Issue References

<!-- THIS is the ONLY place close-family verbs may appear with #N. -->
<!-- For PRs that fully resolve an issue, use one line per issue in plain text below: -->
<!--   Closes #N -->
<!-- For PRs that partially address an issue (deferred work / multi-release initiative): -->
<!--   References #N -->
<!-- Never write "does not close #N" — GitHub's parser ignores negation and triggers auto-close anyway. -->
<!-- Reframe positively instead: "Issue #N stays open through the multi-release initiative." -->
<!-- Spot-check before submit: -->
<!--   grep -inE "(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) +#?\[?[0-9]" pr-body-draft.md -->
<!-- Any match OUTSIDE this Issue References block needs scrutiny. -->
<!-- See .claude/rules/git-workflow.md § PR Process step 5 for full discipline. -->
<!-- CI workflow `.github/workflows/pr-body-parser-clean.yml` enforces this rule on PR open/edit. -->
<!-- Repository-integrity gates (depersonalization / issue-ref / dead-file-ref) run on PR open/sync via `.github/workflows/repo-integrity.yml`; they scan changed FILES, not this body. Override a single file by adding `<!-- repo-integrity: allow-<gate> -->` in that file. See git-workflow.md § Repository-Integrity Gates. -->

Closes #N
