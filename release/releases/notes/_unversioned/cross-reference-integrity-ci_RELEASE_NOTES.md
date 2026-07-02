---
version: cross-reference-integrity-ci
date: 2026-06-13
type: note
issues: ["#314", "#169", "#130"]
pr: "#745"
links:
  plan: release/releases/plans/cross-reference-integrity-ci_RELEASE_PLAN.md
  log_anchor: "#deployment-log-cross-reference-integrity-ci"
reversibility-tier: CHEAP
themes: ["epic:governance-hygiene", "cluster:automation"]
summary: "Three PR-time reference-integrity CI gates go live (warn-mode-initial): positional #N parity with the hook, a link-check gate, and a forward IMP-XXX / skill-count drift gate. Version-less."
requires_action: false
breaking: false
components: [".github/workflows/link-check.yml", ".github/workflows/skill-count-imp-check.yml", ".github/workflows/reference-durability.yml", "core/deploy/tools/check-doc-links.py", "core/deploy/tools/check-skill-count-imp.py", "core/hooks/lib/positional-issueref.awk"]
followups: ["#704"]
---

# Three reference-integrity checks now run on every pull request

2026-06-13 · cross-reference-integrity-ci (version-less)

The same reference-integrity rules the pre-commit hook applies locally now also run as checks when a pull request opens — so a broken intra-repo link, a stale skill-count claim, or a positional issue reference the hook would catch is now caught in the pull request too, not only on the contributor's own machine. The three new checks start in a non-blocking warn-mode: they annotate a pull request without failing it during the shakedown window.

> **Skip the rest** unless you open pull requests against this repository or audit what shipped in this release.

## Who this affects

- Anyone opening a pull request against the repository — three new status checks now report on the pull request. During the initial warn-mode they annotate but do not block; nothing you do today fails because of them.

## What changed for everyone using the platform

- **Broken intra-repo links are now caught when a pull request opens.** A new link-check runs the same link-resolution engine the deploy step already uses, over the same files, so a markdown link to a file that does not exist is flagged on the pull request. *Why it matters:* a dead cross-reference is surfaced while it is still easy to fix, instead of being discovered later at deploy time.
- **A stale skill-count claim or a live legacy IMP-XXX reference in a skill spec is now caught on a pull request.** A new check compares any skill-count claim a pull request adds against the actual roster, and flags a leftover IMP-XXX reference added to a skill specification. *Why it matters:* the platform's own documentation can't quietly drift out of sync with how many skills actually ship.
- **The positional issue-reference check now agrees exactly with the pre-commit hook.** The pull-request check was previously blind to where an issue reference sits relative to its reference block; it now uses the same line-position logic as the hook. *Why it matters:* the same reference passes or is flagged the same way whether it is checked on your machine or on the pull request — no surprises between the two.

## Known limits

- **Version-less by design.** No `vMAJOR.MINOR` is assigned and no git tag or GitHub Release is cut; the release ships under the slug `cross-reference-integrity-ci`, and the release-tracking corpus carries the slug in place of a version with a `(none)` Tag column.
- **The three checks start in warn-mode.** They annotate a pull request but do not fail it yet. Whether and when they begin to block (flip-to-enforce) is a later operator decision, assessed first at this release's close — the recommendation is to keep them in warn-mode through the standard shakedown window. They ship green against the current repository (zero outstanding findings).
- **The skill-count drift check is intentionally bounded.** It flags totalizing count claims (for example "all N skills"); a few looser phrasings are out of scope by design and are covered by a documented override or by simply using the correct number. A follow-up tracks tightening this before the checks ever begin to block.
- **One planned capability was split out.** The cross-skill routing-conflict analysis originally bundled into one of these issues is a distinct capability and was moved to its own follow-up, outside this release.

Report issues at https://github.com/cody-hutson/pmo-platform/issues.

## Reversibility

CHEAP / HIGH confidence. The whole release reverses with a single `git revert -m 1` of the release pull request — every deliverable is additive CI and tooling, and the checks run warn-mode-initial so no pull request is hard-blocked during the shakedown window. Standard rollback window.

---

### Operator and engineering detail

**Three file-disjoint CI surfaces, one source of truth each** — the release hardens PR-time reference-integrity enforcement across three independent workflows with no file overlap. **#314** replaces the position-blind existence check in `.github/workflows/reference-durability.yml` with a true line-position classifier extracted to NEW `core/hooks/lib/positional-issueref.awk`, now invoked by BOTH the pre-commit hook (`core/hooks/block-fragile-refs.sh`) and the CI step — closing the one divergent shape (a self-describing `#N` in body prose with its reference block below it) where the hook flagged `OUTSIDE-BLOCK` while CI passed, a flip-to-enforce false-negative. The divergence fixture (a FLAG + CLEAN pair) is wired into `core/hooks/run-fragile-ref-fixtures.sh` + `core/hooks/testdata/cutover-fixtures.txt` (25 passed / 0 failed). The diff-hunk mapper was inlined in the CI step rather than shipped as a second library (no current second consumer; scope discipline), and `core/deploy/deploy.sh` was deliberately not touched. **#169** promotes the `core/deploy/tools/check-doc-links.py` primitive to a PR-time gate via NEW `.github/workflows/link-check.yml`, with `<OPERATOR_INSTANCE_*>` token-class exclusion in the engine and a repo-resident allowlist (NEW `core/deploy/allowlists/skip-doc-link-check-ci.txt`, since CI has no operator-instance allowlist); it is the SAME primitive over the SAME `--target-paths` as deploy-time Check 14, so the deploy-time and PR-time verdicts cannot drift, and it runs on PR open + push plus a push-to-`main` post-merge guard. **#130** adds a forward-looking detector (NEW `core/deploy/tools/check-skill-count-imp.py`) + workflow (NEW `.github/workflows/skill-count-imp-check.yml`) scoped to the added-lines delta, so pre-existing corpus rot and closed-issue history structurally cannot fire.

**Baseline drainage (#169)** — the link-check baseline over the #169 scope was 221 raw broken-reference rows, reproduced and reduced to 0 real residual: 200 angle-bracket placeholders (194 `<OPERATOR_INSTANCE_*>` + 6 generic documentation-illustration) and 8 meta-doc literals are skipped natively by the engine, and the 13 genuine residual refs were source-fixed (11 legacy `pmo-platform/*` path-drift in `core/CLAUDE.md.template` + 2 illustrative version references in `release-notes-standard.md`). A Stage 8 178-file population audit confirmed the broadened exclusions mask zero real broken refs in the live corpus — the correct engineering trade against eliminating 200+ documentation-literal false-positives.

**Re-scope and split (#130, D-130-Rescope = C+D)** — the literal `imp-references.tsv`-consumer acceptance criteria were dead-on-arrival because that dataset is absent from both the working tree and the entire git history; the issue was re-scoped to forward-looking CI (no historical artifact required). The cross-skill routing-conflict-detection portion — a distinct capability class from reference-integrity CI — was split to its own issue #704 (OPEN, correctly off milestone #112).

**Acceptance + closure** — Stage 8 QA returned binary ACCEPT/PASS on all three (sub-tasks #697 / #698 / #699): #314 all 3 ACs PASS (the modified-file-diff boundary with real hunk offsets maps to true file lines and flags `OUTSIDE-BLOCK`; hook and CI byte-identical on the same content); #169 7/7 ACs MET (AC #6's stale "~50 per X1" parenthetical surgically reconciled in-place to the true 221→0 figure); #130 both salvageable ACs MET with the F1/F3/F4 remediation holding at AC level (drift fires 11/11, zero over-fire across 17 legit framings, a planted live IMP-099 fires with precise 3-module path-scoping). All three issues were marked closed at Stage 13 on those verdicts, the merge SHA, and the live warn-mode-initial gate per issue.

**Check 14 flip-to-enforce assessment (required at the first release after the link-check merge, per `doc-link-maintenance.md`)** — recommendation: keep all three new gates at warn-mode-initial through the standard 2-3-release shakedown window. They ship green at a 0-finding baseline and have no warn-log history to draw a flip decision from yet; flipping now would gate on an unproven precision/recall profile. The flip is explicitly deferred with rationale per the timeline's no-silent-deferral rule. The #130 detector's intentionally-bounded recall (documented at `check-skill-count-imp.py:85–117`) and two benign #314 cosmetics (the CI `minwords=3` literal; the fixture refline not numeric-validated — both fail-safe) are folded into a single off-milestone pre-flip hardening follow-up filed at this close.

**Process notes** — version-less identifier (operator decision at the Stage 12 gate; no `vMAJOR.MINOR`, no git tag, no GitHub Release; `.version` unchanged), `novel` release class (Deep Stage 9 review; 30-day outcome window), single-branch D-C SINGLE with the plan committed as Engineering Commit 0 and serialized per-issue commits in the #314 → #169 → #130 order. The release PR #745 merged with 21/21 CI green; the deploy was a near-no-op (zero changed skills/packages/harness — `deploy.sh --deploy` reported nothing to deploy), and the primary checkout fast-forwarded to the merge SHA `5ebec77`.

For full implementation detail see the [RELEASE_LOG.md entry](../RELEASE_LOG.md#deployment-log-cross-reference-integrity-ci) and [the release plan](../plans/cross-reference-integrity-ci_RELEASE_PLAN.md).

### References

- Milestone: cross-reference-integrity-ci (#112)
- Release PR: [#745](https://github.com/cody-hutson/pmo-platform/pull/745) at `5ebec77d5997d7bbbc77cc21efd93ce2cdd5c168`
- Issues: [#314](https://github.com/cody-hutson/pmo-platform/issues/314) · [#169](https://github.com/cody-hutson/pmo-platform/issues/169) · [#130](https://github.com/cody-hutson/pmo-platform/issues/130) — all three marked closed at Stage 13 with per-AC verification evidence
- Stage 8 QA verdicts: [#697](https://github.com/cody-hutson/pmo-platform/issues/697) (#314) · [#698](https://github.com/cody-hutson/pmo-platform/issues/698) (#169) · [#699](https://github.com/cody-hutson/pmo-platform/issues/699) (#130) — all ACCEPT/PASS
- Tag: (none) — version-less release, no git tag and no GitHub Release cut
- Follow-up (out of scope): [#704](https://github.com/cody-hutson/pmo-platform/issues/704) (routing-conflict detection beyond Jaccard, off-milestone) · the pre-flip-to-enforce hardening issue filed off-milestone at this close
