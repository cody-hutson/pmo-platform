<!-- reference-durability: allow-link -->
# Doc-Link Maintenance Protocol

**Status:** ACTIVE
**Owner:** Platform engineering — release-ops domain
**Enforcement:** Automated via `./deploy.sh --check` Check 14 (governance + skill SKILL.md scope) + Check 15 (release-corpus scope)
**Primitive:** [`core/deploy/tools/check-doc-links.py`](../deploy/tools/check-doc-links.py)
**Mirror:** This standard's canonical source [`core/rules/doc-link-maintenance.md`](../rules/doc-link-maintenance.md) is mirrored to the deployed workspace mirror `~/.claude/rules/doc-link-maintenance.md` for operator-facing visibility (Check 9 byte-identity).

---

## 1. Purpose

Detect and remediate stale cross-references across the platform's documentation corpus. Stale references survive major reorganizations, file renames, and content migrations — producing silent rot that erodes navigability and undermines the "files are the memory" principle in `CLAUDE.md`.

The protocol codifies (a) what counts as a stale reference, (b) when scans run, (c) what tooling enforces detection, (d) escalation path, and (e) the flip-to-enforce timeline that prevents warn-mode from normalizing drift.

---

## 2. Stale-Reference Categories

Three patterns observed during the 2026-04-24 platform reorganization and subsequent cleanups:

| Pattern | Description | Originating evidence | Detection |
|---|---|---|---|
| **A — deleted-target** | Markdown link resolves to a file that no longer exists | stale `IMPROVEMENTS.md` references | Link-resolver primitive |
| **B — path-drift** | Markdown link points to an outdated directory after a reorg | `.claude/evals/results/` vs. `pmo-platform/engineering/evals/results/` | Link-resolver primitive |
| **C — temporal-language drift** | Prose contains stale temporal framing ("deferred", "interim", "Future:") for work that has since shipped or been abandoned |  (`execution-framework.md:111`, `terminology-glossary.md:55-57`) | **Manual-checklist (see §6); automation deferred to F-1** |

Patterns A and B are addressable by mechanical link-resolution; the link-resolver primitive treats both as the same finding category (`broken-cross-ref`) since the remediation path is identical (correct the link to a valid target).

Pattern C requires text-pattern detection (semantic, not structural) and is out of scope for this primitive. The manual-checklist clause in §6 covers the operational gap until F-1 ships.

---

## 3. Scan Triggers

| Trigger | Scope | Authority |
|---|---|---|
| **Post-reorg** | Full Layer 1 governance + skill SKILL.md + release corpus | Operator-initiated after any major file move or directory restructure (e.g., 2026-04-24 reorg, future arc reorgs) |
| **Post-PR-merge** | Files touched by the merged PR + immediate dependents | Automatic via `./deploy.sh --check` invocation during Stage 12 Execute or Stage 13 Close verification |
| **Scheduled (deploy-time)** | Full Check 14 + Check 15 scope | Every `./deploy.sh --check` invocation (operator-driven) — surfaces drift accumulated since last invocation |
| **Pre-release (Stage 9 Plan Review)** | Full scope | Operator-initiated as part of release readiness verification |

---

## 4. Tooling

### 4.1 Primitive script

[`core/deploy/tools/check-doc-links.py`](../deploy/tools/check-doc-links.py) — Python stdlib-only (no external dependencies; uses `/usr/bin/python3` 3.9+, matching the `block-rm-prefer-trash.sh` posture per [bypass-mode-readiness.md](../rules/bypass-mode-readiness.md)).

**Interface contract:**
```
python3 core/deploy/tools/check-doc-links.py \
  --target-paths <comma-separated-globs> \
  [--allowlist .claude/skip-doc-link-check.txt] \
  [--output-format tsv|json|github] \
  [--exclude-code-blocks]

Output (TSV, default):
  source_file<TAB>line<TAB>target<TAB>category<TAB>severity<TAB>remediation_recommendation

Categories: broken-cross-ref, broken-anchor, deleted-target
Severity: P1 (must-fix), P2 (should-fix), P3 (informational)
Exit codes: 0 = no broken refs, 1 = broken refs found
```

**Path resolution:** Inline `[text](path)` and reference-style `[text][label]` are both parsed. Relative paths anchor on the source file's directory and normalize via `os.path.realpath`. Workspace-rooted-style paths (starting with `pmo-platform/`, `.claude/`, `projects/`, `memory/`) get a fallback resolution against workspace root — matches GitHub web rendering semantics. Fenced code blocks (` ``` ` and `~~~`) are excluded from link extraction.

**Self-test:** `python3 core/deploy/tools/check-doc-links.py --self-test` runs an internal smoke test (parser + resolver + code-block exclusion) and exits 0 on pass.

### 4.2 Enforcement-surface integration

| Check | Scope | Source |
|---|---|---|
| **Check 14** | Layer 1 governance (`core/governance/`, `release/governance/`, `core/standards|specs|schemas|disciplines/`, `.claude/rules/`) + skill SKILL.md (`<module>/skills/*/SKILL.md`) | This protocol |
| **Check 15** | Release corpus (`release/releases/RELEASE_LOG.md`, `release/releases/plans/*.md`, `release/releases/notes/*.md`) | This protocol |

Both checks invoke the same primitive script with disjoint `--target-paths` arguments. Disjoint scopes per Collective Review CR-D2.

Layer 2 (Operations) is intentionally excluded per CLAUDE.md domain boundary — Claude Code cannot remediate Layer 2 drift, and Cowork is the appropriate agent for that surface.

---

## 5. Allowlist Policy

Allowlist: [`.claude/skip-doc-link-check.txt`](<OPERATOR_INSTANCE_CLAUDE_DIR>/skip-doc-link-check.txt).

**Format:** One pattern per line. Trailing slash matches directories. `#` introduces comments. Empty lines ignored.

**Allowlisted by default:**
- `release/releases/archive/` — archived release plans contain intentional historical references (e.g., to deleted files like `IMPROVEMENTS.md` from an earlier bridge era)
- `pmo-platform/analysis/legacy-imp-audit-*/` — audit artifacts cite broken refs as evidence (the broken-ref TSV literally enumerates broken refs as data)
- `pmo-platform/analysis/cross-domain-drift-audit-*/` — same evidentiary purpose

**Adding entries:** Use any standard text editor. Each addition should include a comment line documenting why the path is allowlisted (e.g., "intentional historical reference", "audit evidence"). Allowlist additions are governed under the standard "No ungoverned changes" protocol — operator approval required for non-trivial scope expansion.

**Anti-pattern:** Do NOT allowlist files solely to silence Check 14 warnings. Allowlist entries should reflect a deliberate "this file's broken refs are by design" judgment, not a "the broken refs here are too numerous to fix" judgment. The latter case routes to the broken-ref backlog drainage tracked at F-4.

---

## 6. Manual-Checklist Clause for Pattern C

Pattern C (temporal-language drift) cannot be automatically detected by the link-resolver. Until F-1 ships an automated text-pattern check, operators executing any of the following workflows MUST perform a manual scan:

1. **Post-reorg cleanup** (Stage 13 Close or follow-up release): grep the affected file set for stale temporal framing:
   ```bash
   grep -rEn "\b(deferred|interim|Future:|TODO:|pending|will be|to be added|not yet)\b" core/standards/ core/specs/ core/schemas/ core/disciplines/ .claude/rules/ core/governance/ release/governance/
   ```
2. **Major content migration**: same grep, scoped to the migrated content.
3. **Stage 9 Plan Review** (release readiness): scan the release's touched files for temporal language that should now be historical (e.g., "deferred to vX.Y" when the release is vX.Y itself).

Findings route to the standard surgical-fix path — small commits, parser-clean PR body, mark stale framing as current-state or remove it.

---

## 7. Escalation Path

| Finding type | Routing |
|---|---|
| **P1 (must-fix) in active governance** | Tier 1 [ADJUST] commit on the current release branch, or surface to operator if cross-cutting |
| **P2 (should-fix) in reference docs** | Bundle into next release as a surgical fix; create GitHub issue if not already tracked |
| **P3 (informational)** | Log to warn-log; review during shakedown reviews; bundle into broken-ref backlog drainage (F-4) |
| **Net-new drift** (post-warn-log-review) | Operator decides: fix in current release / defer to next / accept as residual / extend allowlist with rationale |

Stage 7 Dev Testing and Stage 8 QA Testing inherit the doc-link-check via `./deploy.sh --check` invocation; findings appear in the verification evidence.

---

## 8. Initial Enforcement Posture

**Mode:** warn-mode (per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) § Warn-Mode vs. Enforce-Mode shakedown precedent for Checks 8/9/10).

**Mechanism:** Check 14 logs findings to `.claude/hooks/doc-link-warn-log.jsonl` and exits 0. The check does NOT block deploy during the shakedown window.

**Rationale:** A baseline broken-ref backlog (~78 findings at merge time, dominated by the historical RELEASE_LOG and ADR cross-references that survive multiple reorgs) cannot be drained in the same release that ships the check. Always-enforce on day 1 would block deploy on the very release that introduces the check. Warn-mode lets the protocol ship + surface drift without blocking, gives the operator visibility into the drift backlog (which informs follow-up tickets), and matches the established Check 8/9/10 rollout pattern.

---

## 9. Flip-to-Enforce Timeline (Governance-Theater Mitigation)

**MANDATORY clause per Collective Review CR-D6.**

Warn-mode without operator-driven review degrades to ceremony. To prevent that, the protocol commits to a flip-to-enforce checkpoint at the following thresholds, whichever comes first:

| Threshold | Action |
|---|---|
| **2-3 releases post-merge** | Operator-driven review of `doc-link-warn-log.jsonl`; broken-ref backlog drainage (F-4) progress assessed |
| **Broken-ref backlog drained to < 10 entries** | Flip to enforce-mode via `.claude/hooks/.mode` or `.claude/hooks/deploy-check.mode` |
| **Until enforce-mode is activated** | Operator must explicitly defer the flip with rationale at each Stage 13 close; silent deferral is a process violation |

**Responsible party:** Workspace owner ([OPERATOR_NAME]). The Stage 13 Close ceremony at the first release after merge MUST include a "Check 14 flip-to-enforce assessment" line item.

**Reversibility:** Flip-to-enforce is reversible — single-line edit in `.claude/hooks/.mode` or `deploy-check.mode`. If enforce-mode produces false-positive flood post-flip, revert to warn-mode while addressing root cause.

---

## 10. Cross-References

- **Stage 5 spec:** D-decisions endorsed at Collective Review
- **Mirror pair:** canonical source [`core/rules/doc-link-maintenance.md`](../rules/doc-link-maintenance.md) ↔ deployed mirror `~/.claude/rules/doc-link-maintenance.md`
- **Companion scope:** Check 15 — release-corpus scope
- **Pattern C treatment:** manual-checklist treatment; automation at F-1
- **Broken-ref backlog drainage:** F-4
- **Frontmatter schema backfill (related corpus hygiene):** F-3
- **Hook layer precedent:** [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) (warn-mode / enforce-mode pattern)
- **Mirror-pair discipline:** [`skill-deployment.md`](../rules/skill-deployment.md) (Check 9 byte-identity enforcement)
