<!-- reference-durability: allow-link -->
# Doc-Link Maintenance — pmo-platform

**Release:** doc-cleanup
**Authoritative standard:** [`core/standards/doc-link-maintenance-protocol.md`](../standards/doc-link-maintenance-protocol.md)

## Purpose

Detect and remediate stale cross-references in the workspace's documentation corpus. Stale links and outdated path references survive reorganizations and erode navigability. The protocol provides automated detection (governance + skill SKILL.md via Check 14; release-corpus via Check 15) and a manual-checklist clause for the semantic-drift pattern that automation cannot reach.

## Three Patterns

| Pattern | Description | Originating evidence | Detection mechanism |
|---|---|---|---|
| **A — deleted-target** | Link resolves to a file that no longer exists |  (`IMPROVEMENTS.md` references) | Link-resolver primitive |
| **B — path-drift** | Link points to an outdated directory after a reorg |  (`.claude/evals/results/` → `pmo-platform/engineering/evals/results/`) | Link-resolver primitive |
| **C — temporal-language drift** | Stale "deferred", "interim", "Future:" framing |  | **Manual checklist; automation tracked at F-1** |

## The Primitive

`pmo-platform/engineering/tools/check-doc-links.py` — Python stdlib-only (`/usr/bin/python3` 3.9+). Parses markdown links, resolves relative paths, reports broken refs as TSV/JSON.

**Usage:**
```bash
python3 pmo-platform/engineering/tools/check-doc-links.py \
  --target-paths <comma-separated-globs> \
  [--allowlist .claude/skip-doc-link-check.txt] \
  [--output-format tsv|json|github]
```

**Self-test:** `python3 pmo-platform/engineering/tools/check-doc-links.py --self-test`

**Path resolution:** Inline `[text](path)` and reference-style `[text][label]`. Relative paths resolve from source-file directory; workspace-rooted-style paths (`pmo-platform/`, `.claude/`, `projects/`, `memory/`) get a workspace-root fallback (matches GitHub web rendering). Fenced code blocks excluded.

## Enforcement Surfaces

| Check | Scope | Posture |
|---|---|---|
| **Check 14** | Governance + skill SKILL.md (`pmo-platform/governance/`, `pmo-platform/reference/`, `.claude/rules/`, `pmo-platform/skills/*/SKILL.md`) | warn-mode initial; logs to `.claude/hooks/doc-link-warn-log.jsonl` |
| **Check 15** | Release corpus (`pmo-platform/governance/RELEASE_LOG.md`, `pmo-platform/releases/plans/*.md`, `pmo-platform/releases/notes/*.md`) | warn-mode initial; same log surface |

Both checks call the same primitive script with disjoint `--target-paths`. Layer 2 (Operations) is excluded per CLAUDE.md domain boundary.

## Allowlist

`.claude/skip-doc-link-check.txt` — one pattern per line; trailing slash matches directories; `#` introduces comments.

**Default entries:**
- `pmo-platform/releases/archive/` — historical references by design
- `pmo-platform/analysis/legacy-imp-audit-*/` — audit evidence
- `pmo-platform/analysis/cross-domain-drift-audit-*/` — audit evidence

**Adding entries:** standard text editor + governance approval for non-trivial scope expansion. Allowlist additions document WHY the path is allowlisted, not WHY the operator wants to silence warnings.

## When Scans Run

| Trigger | Authority |
|---|---|
| Post-reorg | Operator-initiated |
| Post-PR-merge | Automatic via `./deploy.sh --check` |
| Scheduled (deploy-time) | Every `./deploy.sh --check` invocation |
| Pre-release (Stage 9) | Operator-initiated as release readiness verification |

## Manual Checklist for Pattern C

Until F-1 ships automated text-pattern detection, operators executing post-reorg, major-content-migration, or Stage 9 Plan Review workflows perform this grep:

```bash
grep -rEn "\b(deferred|interim|Future:|TODO:|pending|will be|to be added|not yet)\b" \
  pmo-platform/reference/ .claude/rules/ pmo-platform/governance/
```

Findings route to the standard surgical-fix path — small commits, parser-clean PR body, mark stale framing as current-state or remove it.

## Initial Mode + Flip-to-Enforce Timeline

**Initial mode:** warn-mode per [`bypass-mode-readiness.md`](bypass-mode-readiness.md) precedent (Checks 8/9/10).

**Flip-to-enforce thresholds (per Collective Review CR-D6, whichever comes first):**

| Threshold | Action |
|---|---|
| 2-3 releases post-merge | Operator-driven warn-log review; broken-ref backlog drainage progress assessed |
| Broken-ref backlog drained to < 10 entries | Flip to enforce via `.claude/hooks/.mode` or `.claude/hooks/deploy-check.mode` |
| Until enforce-mode is activated | Operator must explicitly defer flip with rationale at each Stage 13 close; silent deferral is a process violation |

**Responsible party:** Workspace owner ([OPERATOR_NAME]). Stage 13 Close at the first release after merge MUST include a "Check 14 flip-to-enforce assessment" line item.

## Escalation

| Finding type | Routing |
|---|---|
| P1 in active governance | Tier 1 [ADJUST] commit on current release branch, or surface to operator |
| P2 in reference docs | Bundle into next release as surgical fix; create GitHub issue if not tracked |
| P3 informational | Log to warn-log; review during shakedown; bundle into the F-4 broken-ref drainage |
| Net-new drift | Operator decides: fix / defer / accept-as-residual / allowlist-with-rationale |

## Reference Durability vs Link Resolution

Link resolution (this protocol) is a distinct discipline from reference durability (the reference-durability standard under the core standards set, with its hook, deploy-check check, and CI workflow). The two are orthogonal and both run; neither subsumes the other.

| Discipline | Owns | Question it answers |
|---|---|---|
| Link resolution (this protocol plus its deploy-check check) | does a text-path link resolve to a file that exists? | Is this link alive today? |
| Reference durability (the standard plus its enforcement primitives) | should this reference exist at all in durable corpus, given it will break on renumber or migration? | Will this survive a rename, renumber, or migration? |

A link can be perfectly resolvable today — it passes the link-resolution check — yet still be a durability violation, because the durability standard says to summarize the content inline rather than carry a link. Conversely a durable inline summary has no link to resolve. Link resolution polices link liveness; reference durability polices whether a fragile construct belongs in durable corpus at all. When a reference fails link resolution, fix or remove the link; when it fails durability, rewrite it as an inline summary.

## Related

- Companion check: Check 15 (release-corpus scope)
- Pattern C automation: F-1
- Broken-ref backlog drainage: F-4
- Frontmatter schema backfill (corpus hygiene): F-3
- Mirror-pair discipline: [`skill-deployment.md`](skill-deployment.md)
- Hook layer precedent: [`bypass-mode-readiness.md`](bypass-mode-readiness.md)
