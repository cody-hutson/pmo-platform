<!-- reference-durability: allow-link -->
# Doc-Link Maintenance — pmo-platform

**Release:** doc-cleanup
**Authoritative standard:** [`core/standards/doc-link-maintenance-protocol.md`](../standards/doc-link-maintenance-protocol.md)

## Purpose

Detect and remediate stale cross-references in the workspace's documentation corpus. Stale links and outdated path references survive reorganizations and erode navigability. The protocol provides automated detection (governance + skill SKILL.md via Check 14; the earlier release-corpus Check 15 was retired in v2 — the release-corpus link surface is covered by the release-corpus link checker) and a manual-checklist clause for the semantic-drift pattern that automation cannot reach.

## Three Patterns

| Pattern | Description | Originating evidence | Detection mechanism |
|---|---|---|---|
| **A — deleted-target** | Link resolves to a file that no longer exists |  (`IMPROVEMENTS.md` references) | Link-resolver primitive |
| **B — path-drift** | Link points to an outdated directory after a reorg |  (e.g. a pre-restructure `pmo-platform/...` path → its live `core/`/`release/`/`operations/` location) | Link-resolver primitive |
| **C — temporal-language drift** | Stale "deferred", "interim", "Future:" framing |  | **Manual checklist; automation tracked at F-1** |

## The Primitive

`core/deploy/tools/check-doc-links.py` — Python stdlib-only (`/usr/bin/python3` 3.9+). Parses markdown links, resolves relative paths, reports broken refs as TSV/JSON.

**Usage:**
```bash
python3 core/deploy/tools/check-doc-links.py \
  --target-paths <comma-separated-globs> \
  [--allowlist .claude/skip-doc-link-check.txt] \
  [--require-targets] \
  [--output-format tsv|json|github]
```

**Self-test:** `python3 core/deploy/tools/check-doc-links.py --self-test`

**Fail-loud on unresolved targets:** `--require-targets` treats a `--target-paths` glob entry that resolves to zero files as a path-resolution failure (exit 3) rather than a clean pass, so a relocated or typo'd scan surface cannot read GREEN. Check 14 passes this flag.

**Path resolution:** both inline links (`[text]` followed by a parenthesized path) and reference-style links (`[text]` followed by a `[label]`) are parsed. Relative paths resolve from source-file directory; workspace-rooted-style paths get a workspace-root fallback (matches GitHub web rendering). The resolver carries both the live module-relative prefixes (`core/`, `release/`, `operations/`, `docs/`) and the legacy `pmo-platform/`/`.claude/` prefixes for backward-compat. Fenced code blocks excluded.

## Enforcement Surfaces

| Check | Scope | Posture |
|---|---|---|
| **Check 14** | Governance + reference + rules + skill SKILL.md across the live modules (`core/governance/`, `core/disciplines/`, `core/schemas/`, `core/standards/`, `core/specs/`, `core/rules/`, `core/CLAUDE.md.template`, `release/governance/`, `release/references/`, `operations/OPERATIONS.md`, and `{core,operations,release}/skills/*/SKILL.md`) | warn-mode initial; logs to the deploy-check warn-log surface |
| **Check 15** | RETIRED in v2 — the release-corpus cross-link integrity check was removed; the release-corpus link surface is covered by the release-corpus link checker, and note-content is linted by Check 20 via `lint_release_corpus.py` | n/a (retired) |

Check 14 calls the primitive with the live module-scoped `--target-paths`. Layer 2 (Operations) governance + references are in scope; project/operational content is excluded per CLAUDE.md domain boundary.

## Allowlist

`.claude/skip-doc-link-check.txt` — one pattern per line; trailing slash matches directories; `#` introduces comments.

**Default entries (illustrative — the allowlist file itself is operator-instance):**
- `release/releases/archive/` — historical references by design
- audit-evidence subtrees (e.g. `legacy-imp-audit-*/`, `cross-domain-drift-audit-*/`) — read-once analysis artifacts

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
  core/standards/ core/specs/ core/rules/ release/references/ release/governance/
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

- Release-corpus link surface: covered by the release-corpus link checker (the earlier Check 15 was retired in v2)
- Pattern C automation: F-1
- Broken-ref backlog drainage: F-4
- Frontmatter schema backfill (corpus hygiene): F-3
- Mirror-pair discipline: [`skill-deployment.md`](skill-deployment.md)
- Hook layer precedent: [`bypass-mode-readiness.md`](bypass-mode-readiness.md)
