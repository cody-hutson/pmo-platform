# Release Plan — public-flip-depersonalization-enforcement

**Project:** Governance Hygiene (epic #1181) · **Milestone:** 43-public-flip-depersonalization-enforcement (#122)
**Version:** version-less (theme-named; no tag at Stage 12 — operator D-Version decision 2026-06-21; v2.17 was claimed by the concurrent architecture-altitude-discipline release)
**Release Class:** novel · **Topology:** single-branch (D-C SINGLE) · **Base:** `origin/main` @ `5475c05`
**Stage 4 working reference:** sub-task #1813 · **This file:** Engineering Commit 0.

## Capability Outcome
After this release, the public repo's depersonalization + path-portability boundary is enforced by standing guards rather than held clean by manual vigilance: operator-handle, operator-local-path, and draft-file leaks are caught before they land (commit · PR · gh-issue-ops); the GitHub Projects token vocabulary is first-class and survives install/update; and the residual document-internal-ID corpus is operator-ratified.

## Locked scope (10 issues)

| # | Size | Deliverable |
|---|---|---|
| #383 | M | operator.toml lossless round-trip (Option-1: re-parse + verbatim pass-through of unmanaged sections) |
| #324 | M | register 6 tokens — 5 GitHub-Projects (§1.1 `[projects]` sub-table) + `[OPERATOR_GITHUB_PROJECT_URL]` |
| #1827 | XS | convert `[OPERATOR_JIRA]` → `{{JIRA_BASE_URL}}` (DC3 localized-value form) |
| #529 | M | Option-E orphan-var convergence (21+2 sites → `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance`) + path-portability deploy.sh check + shared `path-leak-patterns.sh` primitive |
| #1137 | S | gh-issue-ops path-leak guard (`block-gh-path-leak.sh`, consumes the primitive) |
| #323 | S | consolidated `depersonalization-token` deploy.sh check (PVT*-reintroduction + bracket-conformance) |
| #411(b) | M | draft-file commit guard (`block-draft-files.sh` hook + CI gate + Check-37 registration) |
| #1823(a) | S | sanctioned idea-refinement-surface rule (doc-only) |
| #1098 | XS | tokenize the one handle at `stage-03-bundle.md:130` |
| #376 | S | verify-only — operator KEEP disposition recorded; closes at Stage 13 |

## Engineering sequence (write-serialized; deploy.sh-check order respected)
`#383 → #324 → #1827 → #529 → #1137 → #323 → #411(b) → #1823(a) → #1098` · #376 closes at Stage 13.

## Hard dependency edges
- `#383 → #324` (shared operator.toml writer; #383's pass-through means #324 needs no writer-preservation change).
- `#529 → #1137` (shared `path-leak-patterns.sh` primitive, incl. `PATH_LEAK_RE_INSTANCE_REL`).
- `#324 + #1827 → #323` (bracket-conformance reads §1; the Jira token must be `{{}}`-converted so it isn't flagged).

## Adversarial-review corrections folded in (Collective Review scope-lock 2026-06-21)
- **#529 = Option-E, NOT Option-D.** Converge the orphan `PMO_INSTANCE_PATH` onto canonical `CLAUDE_WORKSPACE_ROOT` per accepted ADR-017/ADR-032; #1549 de-conflicted (its convergence item moves here). Option-D (retain the orphan) was contraindicated.
- **#324 registers 6, not 7.** `[OPERATOR_JIRA]` is a localized VALUE → `{{JIRA_BASE_URL}}` (DC3), not an `[OPERATOR_*]` token (→ #1827).
- **#411 allowlist** derived mechanically from live `.gitignore` (must include `steering-committee/` + the three `*/governance/roadmaps/` paths) — not an abbreviated glob.
- **#1137** `--body-file` content scanning is net-new (not block-egress parity) — spec fail-open + fixtures.
- **#383** `pmo_platform_repo_name` is a first-class preservation case (4 live consumers), value-or-default not hardcoded-reset.
- **#323** two mode-handles (PVT* enforces on ship; bracket-conformance waits for token registration); `[OPERATOR_FIRST_NAME]` is a derived-token exception.

## Mid-pipeline divergence reconciliation (Engineering entry, base 5475c05)
`main` advanced 11 commits during planning; v2.17 (architecture-altitude-discipline, #1812) shipped, adding **Check 42 (host-binding-leak, #1767)** + `check-host-binding.py`. Reconciliation: deploy.sh max is now **42** → #529 = **Check 43**, #323 = **Check 44**. #1767's host-binding-leak detector is the **host-axis sibling** of #529's path-portability (knowledge-architecture §4.1) — distinct concern; #529 mirrors its tool pattern (`--target-paths`/`--allowlist`/`--self-test`). No file-content conflict (additive).

## Risk / rollback
All findings CHEAP–MODERATE; every new guard ships warn-mode-first (no enforcement blast radius on rollback). Single integration PR → revert = one PR revert. No data migration (#383 writer change is backward-compatible). Stage 9 Plan Review is the operator GO gate.
