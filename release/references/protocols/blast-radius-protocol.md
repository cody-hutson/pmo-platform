<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
# Blast Radius Protocol

> **Source:** Sub-slice 1 — Stage 5 Solutioning support.
> **CLI:** [`release/tools/blast-radius.sh`](../../tools/blast-radius.sh)

---

## 1. What this is

The blast-radius CLI traces **file-reference fan-out** for a target file across the workspace: which files mention it (first-order), which files mention THOSE files (second-order), and where those references live (line numbers + snippets). This protocol document is the CLI's **consumer-facing manual** — when to run it, how to read its output, how to classify impact, and how Stage 4 release-planner / Stage 5 design reviewers consume the result.

The tool answers a single Stage 5 question: **"If I change this file, what else could break?"** It does so via grep-based reference detection (not static analysis), so it captures markdown links, prose mentions, frontmatter cross-references, and shell-script path strings — anything that mentions the target by full path, repo-relative path, or basename.

The schema is the contract; the implementation is replaceable. Schema v1 is locked at this release.

---

## 2. When to use

Three primary triggers — plus operator-initiated ad-hoc use:

| Trigger | Stage | Use |
|---|---|---|
| **Cross-PR contention check** | Stage 4 (Release Planning A4) | Before bundling a Milestone, run the CLI against each affected file in the change matrix. Compare results against in-flight PRs (open + last-N merged) to identify external collisions. |
| **Transitive dependency mapping** | Stage 5 (Solutioning A3) | Replaces the manual `grep` step in [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) Phase A §A3. Each Stage 5 spoke runs the CLI on the target file(s) under design; cites the output in the spoke's Evidence section. |
| **Operator ad-hoc impact analysis** | Any | Operator inspecting a proposed change can run the CLI directly to gauge reach before authorizing scope. |

**Do NOT use** for: byte-identity verification of mirror pairs (use `core/deploy/deploy.sh --check` Check 9), skill-deployment drift (use `core/deploy/deploy.sh --check` Check 12), or production-state audit. The CLI is a static-content analyzer over markdown/sh/json/yml/toml files in the source tree — not a runtime observer.

---

## 3. Invocation

### Synopsis

```
./release/tools/blast-radius.sh [OPTIONS] <target_file>
```

### Flags

| Flag | Default | Purpose |
|---|---|---|
| `--format=json\|table\|md` | `table` if stdout is a tty, `json` otherwise | Output presenter |
| `--depth=N` | `2` | Recursion depth for second-order detection; hard cap `4` |
| `--max-expand=N` | `300` | Deterministic cap on how many first-order referrers are expanded for second-order detection. `0` = unlimited. When the cap fires the run emits a partial-result marker and exits `6` (see § Traversal bound) |
| `--include-mirrors` | unset (mirrors filtered) | Include mirror-pair references in output (annotated `[MIRROR]`) |
| `--root=PATH` | `git rev-parse --show-toplevel` | Repo root for scanning; falls back to invocation cwd |
| `--exclude=GLOB` | (additive to default) | Additional exclusion path-prefix; repeatable |
| `--no-color` | unset | Disable ANSI color in table output |
| `-h`, `--help` | — | Usage banner |
| `--version` | — | CLI version + schema version |
| `--self-test` | — | Built-in hermetic regression suite (13 assertions over mktemp fixtures scanned via `--root`; no network, no git). Exits `0` on pass. Discovered and executed pre-merge by the `selftest-discovery` CI job — it is not separately wired |

### Examples

```bash
# Default: table output, depth=2
./release/tools/blast-radius.sh release/references/pipeline/stage-05-solutioning.md

# JSON for downstream skill consumption
./release/tools/blast-radius.sh --format=json --depth=1 CLAUDE.md

# Forensic mode — show mirror-pair references too
./release/tools/blast-radius.sh --include-mirrors release/governance/release-process.md

# Embed in a sub-task comment
./release/tools/blast-radius.sh --format=md CLAUDE.md > /tmp/blast.md
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Success; output on stdout |
| `1` | Internal error or invalid flag value |
| `2` | Bad target (does not exist or not a regular file) |
| `3` | Target is under an exclusion glob |
| `4` | Missing dependency (`jq` not on PATH) |
| `6` | **Partial result** — second-order expansion was capped by `--max-expand`. Output IS produced and carries `partial: true`; it is **truncated, not empty**. Never read a `6` as "no blast radius" |

`5` is deliberately skipped: [`release/tools/domain-blast-radius.sh`](../../tools/domain-blast-radius.sh) already uses it for `EXIT_SCANNER_NOT_IMPLEMENTED`. Both tracers emit the same schema-v1 contract, so a consumer switching on exit code must be able to tell "the domain scanner is unavailable" apart from "your result was truncated".

### Traversal bound

Second-order detection expands each first-order referrer, so its cost grows with fan-in. `--max-expand` bounds that expansion **deterministically**: the first-order list is already sorted `reference_count` DESC then `path` ASC, and the cap truncates that sorted list, so the same input always yields the same truncation and the highest-signal referrers are the ones kept. First-order output is never capped — only the second-order expansion is.

The default (`300`) sits above the largest first-order fan-out observed in this corpus, so it does not fire today and changes no output today. Its purpose is fail-loud-not-hang: as the corpus grows, a target that would once have run unbounded instead returns a marked partial. **This is a cap on a sorted list, not a wall-clock timeout** — a timeout would make the same input produce different output on a loaded machine, and this tool's output feeds Stage-8 verification, where non-reproducible impact analysis is disqualifying.

A capped run signals itself on **both** limbs: exit `6` **and** `partial: true` in the JSON (plus a visible `!! PARTIAL RESULT` line in the `table` and `md` presenters). A consumer that checks only the exit code catches it; a consumer that reads only the JSON catches it.

### Hook compliance

The CLI uses only `grep`, `find`, `jq`, `sort`, `awk`, `sed`, `tr`, `wc` and — for tracked-file scoping — `git rev-parse` / `git ls-files`, all permitted under the `bypass-mode-readiness.md` hook layer. `git` is an **optional** dependency, guarded by `command -v`: when it is absent the CLI falls back to the `find` enumeration and says so in `stats.scan_scope_status`. **However**, BLOCK-DESTRUCTIVE-022 (subprocess script execution) requires the CLI's path to be present in `core/config/allowlists/script-execution-allowlist.txt` before bash invocation succeeds **wherever that guard is in force**. This is a one-time operator/deployment step; the entry covers absolute, worktree, and relative invocation forms. See [`core/rules/bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) §"Allowlist Maintenance".

**Coverage boundary — four conditions.** BLOCK-DESTRUCTIVE-022 is enforced by a PreToolUse hook, and such a control is in force only when **all four** hold, and not when any one fails: (1) **loading** — the session resolved a settings surface declaring the hook wiring (any session, main or spawned, whose working directory is under the governed workspace root; a session resolving no such surface loads no hooks at all, and one outside the root is excluded by the scope guard); (2) **bypass** — `CLAUDE_HOOK_BYPASS` was not set in the launching environment (layer 1, which exits **both** hook classes, so the security/workflow asymmetry does **not** exist there); (3) **master-activation class** — `security` always enforces, `workflow` is inert while master activation is off; (4) **mode** — most block hooks warn-and-allow in warn mode, a minority are mode-independent. A citation naming fewer than four overstates the coverage. Canonical statement: [`core/standards/subagent-security-posture.md` § 3.1](../../../core/standards/subagent-security-posture.md).

**Read this as a deployment prerequisite, not as a guarantee.** The allowlist entry is what makes the CLI runnable *under the guard*; it is not what makes the CLI runnable, and its absence is not a reason to expect an unallowlisted invocation to be caught.

---

## 4. Output interpretation

The CLI emits a JSON v1 document (or a table/markdown rendering of it). Schema:

```json
{
  "schema_version": "1",
  "cli_version": "0.1.0",
  "target": "release/references/pipeline/stage-05-solutioning.md",
  "scanned_at": "2026-05-11T16:42:00Z",
  "scan_root": "${HOME}/Claude",
  "depth": 2,
  "include_mirrors": false,
  "stats": {
    "total_files_scanned": 593,
    "scan_scope": "tracked",
    "scan_scope_status": "fetched",
    "first_order_count": 16,
    "second_order_status": "fetched",
    "second_order_count": 24,
    "unreadable_files": 0,
    "filtered_mirrors": 0,
    "elapsed_seconds": 4.2
  },
  "first_order": [
    {
      "path": "release/references/how-to/hub-spoke-bridge.md",
      "reference_count": 4,
      "matches": [
        {"line": 56, "snippet": "see pipeline/stage-05-solutioning.md"},
        {"line": 212, "snippet": "per pipeline/stage-05-solutioning.md"}
      ],
      "is_mirror": false
    }
  ],
  "second_order": [
    {
      "path": "release/references/pipeline/stage-04-planning.md",
      "via": "release/references/how-to/hub-spoke-bridge.md",
      "reference_count": 2,
      "matches": [
        {"line": 102, "snippet": "hub-spoke-bridge.md Procedure 0"}
      ],
      "depth": 2,
      "is_mirror": false
    }
  ],
  "filtered_mirrors_detail": []
}
```

### Field semantics

- **`schema_version`** — Output contract version. Increments on backward-incompatible changes; consumers pin to a major version with a 1-release transition window for v2 migration.
- **`cli_version`** — Implementation version. Bumped per material code change; does not affect schema.
- **`target`** — Repo-relative path of the analyzed file.
- **`scan_root`** — Absolute repo root (from `git rev-parse --show-toplevel` or `--root`).
- **`depth`** — Maximum recursion depth applied. `1` = first-order only; `2` = first + second order; `3-4` = transitive.
- **`include_mirrors`** — Reflects the `--include-mirrors` flag at invocation time.
- **`stats.first_order_count`** — Distinct files in `first_order`. **This is the AC2 metric.**
- **`stats.filtered_mirrors`** — Count of mirror-partner files suppressed from `first_order` (when `--include-mirrors` is unset). Detail lives in `filtered_mirrors_detail`.
- **`partial`** / **`partial_reason`** / **`stats.partial`** — **OPTIONAL; present ONLY on a run whose second-order expansion was capped by `--max-expand`.** `partial` is `true`, `partial_reason` names both the cap and the true first-order total, and `stats.partial` mirrors the boolean for consumers reading the stats block. On a complete run all three keys are **absent**, so output is unchanged for every existing consumer and no `schema_version` bump is required. A consumer that does not know these keys still cannot misread a capped run, because the process also exits `6`. Treat their presence as "this analysis is incomplete", never as "this analysis found nothing".
- **`stats.second_order_status`** — the MEASUREMENT STATE of `second_order_count`, drawn verbatim from the PV-7a **Register A** closed set. Emitted on every path: `fetched` (the traversal ran to completion), `truncated` (the `--max-expand` cap fired, so the enumeration is a sample), `degraded` (a scan-listed file could not be read), `not-run` (`--depth < 2`, or `--mode=structural`). `fixture` is not emitted — this tool has no fixture-vs-live distinction in its emit path.
- **`stats.second_order_status_reason`** — present on `not-run` and `degraded`, naming which cause fired. **Absent** on a clean status; never an empty string.
- **`stats.unreadable_files`** — count of scan-listed files that could not be read, measured on every path, including as a genuine `0`. It is the checkable basis for `fetched`; read its scope limit under *Reading a count* below.
- **`stats.scan_scope`** — a **POPULATION LABEL**, `tracked` or `all-files`, naming which population `total_files_scanned` covers. Deliberately **not** a Register A member: Register A can say *whether* a measurement happened, but has no member for *"measured, over a different population."*
- **`stats.scan_scope_status`** — Register A verbatim, reporting whether **tracked** scoping was achieved: `fetched`, `degraded` (git present and the read failed, or the tracked enumeration was measurably short), `not-run` (git absent, the root is not a work tree, or the work tree has no tracked files under it).
- **`stats.scan_scope_status_reason`** — present whenever `scan_scope_status` is not `fetched`; absent otherwise, never `""`.

### Reading a count

**A consumer MUST branch on a counter's sibling status field before reading the counter.** Both counters in `stats` that carry one are governed by this rule, and it is the same rule for each:

```
For a counter C in .stats with sibling status field C_status:

  0. If .stats has no C_status  -> this tool publishes no measurement warrant
                                   for C. Do not infer one.
  1. Read .stats.C_status FIRST. Never read C before branching on it.
       fetched    -> C is PRESENT. C == 0 means MEASURED EMPTY.
       truncated  -> C is PRESENT, measured over a SAMPLED enumeration.
       not-run    -> C is ABSENT. Never attempted.
       degraded   -> C is ABSENT. Attempted, and incomplete.
  2. The discriminator is the counter's ABSENCE, not any of its values.
     `has("C") == false` is the only sound not-computed test. There is no
     value to misread, because on a non-measuring status there is no value.
```

| `second_order_status` | `stats.second_order_count` | Means |
|---|---|---|
| `fetched` | **present** — `0` here means **measured empty** | the traversal examined the scan list |
| `truncated` | **present** — over the sampled expansion | the `--max-expand` cap fired |
| `degraded` | **ABSENT** | attempted, but a scan-listed file could not be read |
| `not-run` | **ABSENT** | `--depth < 2`, or `--mode=structural` |

**What `fetched` does and does not warrant.** `fetched` warrants that every **scan-listed** member was read — **not** that the scan list is complete. `stats.unreadable_files` counts scan-listed files that could not be read; it is a read-completeness measure over the scan list, **never** an enumeration-completeness measure. **Scan-list completeness is reported by `stats.scan_scope_status`, not by `unreadable_files`:** a member dropped because an ancestor directory could not be traversed yields `degraded` with a count in the reason; drops caused by the type filter, by an exclusion prefix, or by a path deleted from the working tree are intentional and leave the status `fetched`. A residual remains on the `all-files` fallback, where `find` cannot descend an untraversable directory at all — under the tool's `set -euo pipefail` that aborts the run rather than under-reporting, but the diagnostic naming the directory is discarded. Capturing it is a tracked follow-on; **this tool does not detect enumeration incompleteness on that path.**

**A count is comparable only against another count over the same population.** Read `stats.scan_scope` **before** comparing any count across runs — `tracked` and `all-files` are different populations, and a `degraded` scope status means the tracked population was never established. `stats.total_files_scanned` is the one counter that is **never** deleted and never null: it is measured on every path, because the `all-files` fallback genuinely counts a population — just a different one, which is exactly what `scan_scope` exists to name.

**Legal `scan_scope` / `scan_scope_status` pairs** — any other pair is a bug:

| `scan_scope` | `scan_scope_status` | reason | Meaning |
|---|---|---|---|
| `tracked` | `fetched` | absent | tracked enumeration, complete |
| `tracked` | `degraded` | present | tracked enumeration, N members unreachable |
| `all-files` | `not-run` | present | git absent, root not a work tree, or no tracked files under it |
| `all-files` | `degraded` | present | git present, `ls-files` failed — the tracked population is UNMEASURED |

### `first_order` vs. `second_order` vs. `filtered_mirrors_detail`

| Array | Meaning | Sort order |
|---|---|---|
| `first_order` | Files directly mentioning the target | `reference_count` DESC, then `path` ASC |
| `second_order` | Files mentioning a first-order file (transitive at depth=2). `via` records which first-order file led to this finding. | Same as above |
| `filtered_mirrors_detail` | Mirror-partner files that WOULD have appeared in `first_order` but were suppressed because the target is one half of a registered mirror pair (and `--include-mirrors` was unset) | Same as above |

### `via` chain interpretation

`second_order[].via` names the first-order file that pointed to the second-order finding (first match wins on ties). At `depth=2`, `via` is always a first-order path. At `depth>2`, `via` chains back to depth-2 and so on — but the CLI does not record the full chain in v1 schema; it records the most-recent hop.

### Match snippet truncation

`matches[].snippet` is truncated to 200 characters with a trailing `…` ellipsis. Up to 5 match lines are recorded per file; if the file has >5 matches, `reference_count` still reflects the total.

---

## 5. Impact classification rules

Apply these tiers to the CLI output to decide release-process treatment:

### Cosmetic — ship without escalation

- **Criteria:** ≤1 first-order referrer AND all matches are non-load-bearing (index entries, navigation lists, README "see also" lists, file enumerations).
- **Decision:** Ship in the release plan without ceremony. Mention in the change spec only.
- **Stage routing:** Stage 5 Solutioning spoke may issue brief output ("Cosmetic — no design surface"). Stage 6 commits without sub-task decomposition beyond the issue itself.

### Behavioral — Risk Register entry + per-referrer verify

- **Criteria:** 2-5 first-order referrers, OR any second-order chain that crosses a skill / governance / rules boundary (i.e., a referrer in `release/skills/**` or `core/rules/**` or `core/governance/**`).
- **Decision:** Add a Risk Register entry to the release plan. Stage 6 verifies each referrer at commit time (does it still resolve? does it still mean what it meant?). Stage 7 DT runs the CLI again post-edit to confirm no new break references.
- **Stage routing:** Standard Stage 5 / Stage 6 / Stage 7 / Stage 8 flow with explicit per-referrer verification.

### Structural — requires Solutioning treatment (cannot skip Stage 5)

- **Criteria:** ≥6 first-order referrers, OR any reference from a CRITICAL file (`CLAUDE.md`, `core/rules/*`, `deploy.sh`, any `SKILL.md`).
- **Decision:** Treat as architectural change. Stage 5 Solutioning is mandatory (cannot skip via mixed-routing protocol). If the reference chain crosses 3+ governance layers (e.g., touches CLAUDE.md AND `core/rules/*` AND a skill SKILL.md), surface as a D-class operator decision.
- **Stage routing:** Full pipeline with explicit Operator Decision Gate at Stage 5.

### Tiebreaker rules

- If the count places the change in one tier but criticality places it in a higher tier, take the higher tier.
- If the CLI reports `is_mirror: true` matches and `--include-mirrors` was set, exclude those from the count for classification purposes (they are byte-identical-by-design, not load-bearing references).

---

## 6. How Stage 4 release-planner consumes the output

Stage 4 (Release Planning) integrates blast-radius output into two activities:

1. **A4 Cross-PR Overlap Audit** — For each file in the change matrix, run the CLI to compute first-order fan-out. Compare against `gh pr list --state open` files-touched and the last-N merged PRs at the baseline SHA. Surface external collisions as Risk Register entries (R6-class).
2. **A5 Change-spec sequencing** — When two issues in the same Milestone touch the same file, blast-radius output informs the sequencing decision. The issue whose change has the larger blast radius typically commits LAST (so it can verify against the smaller change already merged).

The CLI's `--format=md` output is suitable for direct paste into a release plan's Contention Map section.

---

## 7. How Stage 5 spokes consume the output

Stage 5 spokes (per-issue solutioning) cite the CLI invocation + summarize output in their Evidence section. Pattern:

```
### Evidence
- Ran `./release/tools/blast-radius.sh <target>`:
  - first_order_count: <N>
  - Impact classification: <Cosmetic | Behavioral | Structural>
  - Notable referrers: <list top 3-5 by reference_count>
  - Mirror partners filtered: <count>
```

For Structural-tier targets, the Stage 5 spoke MUST enumerate the affected referrers and address each in the design spec ("how does this change preserve referrer X's expectation?").

The CLI replaces the manual `grep -rln` step that previously lived in spoke prompts.

---

## 8. Mirror-pair handling

The CLI detects mirror pairs from a **canonical table** (a faithful shadow of `core/deploy/deploy.sh` Check 9 `MIRROR_PAIRS`): any file whose repo-relative path matches a source entry in that table (`core/rules/<f>` or `release/governance/release-process.md`) is registered as a mirror pair against its `.claude/rules/<f>` deploy-mirror partner at scan time. By default, when the target is one half of a mirror pair, the CLI suppresses references to its partner from `first_order` and records the count in `stats.filtered_mirrors` (detail in `filtered_mirrors_detail`). (The former `core/governance/OPERATIONS.md` ↔ `operations/OPERATIONS.md` repo-internal pair was retired when `operations/OPERATIONS.md` became an SSOT pointer stub rather than a byte-identical mirror — its link to the SSOT is a real edge that is no longer mirror-suppressed.)

**Why suppress?** The mirror pair is enforced byte-identical by `core/deploy/deploy.sh --check` Check 9. A reference between a mirror source and its deploy-target partner (e.g., `release/governance/release-process.md` and `.claude/rules/release-process.md`) is a structural artifact of the mirror discipline, not an organic dependency. Suppressing it cleans the signal.

**When to use `--include-mirrors`:** Forensic operator review — auditing whether mirror partners reference each other in unexpected ways, or whether the mirror discipline is leaking. The `filtered_mirrors_detail` array is also populated even when filtering is on, so the operator can see what was hidden.

**Source of truth:** [`core/rules/skill-deployment.md`](../../../core/rules/skill-deployment.md) and [`core/rules/harness-deployment.md`](../../../core/rules/harness-deployment.md) define the mirror discipline. The enumerated pair topology is `core/deploy/deploy.sh` Check 9 `MIRROR_PAIRS`, which Check 9 also enforces byte-identical. The CLI's `detect_mirror_pairs` mirrors that table (emitting a row per pair whose in-repo source exists), so the two stay in lockstep — see §10 for the keep-in-sync rule.

---

## 9. Limitations

- **Markdown link parsing only.** The CLI does not parse YAML frontmatter cross-references (e.g., `consumed-by:` fields in SKILL.md). If a skill ecosystem grows to depend on structured frontmatter, future v2 schema may add a `frontmatter_references` field.
- **Code-block false positives possible but rare.** A path mentioned inside a fenced code block ( ``` ) is still captured. Sampling on `release-process.md` shows <5% false-positive rate. Operator verification of each finding is cheap (re-run the grep manually).
- **Performance shape.** Cost is driven by the second-order expansion, not by first-order: a `--depth=2` run scans the corpus once per token per expanded referrer, so wall-clock scales with `(1 + first_order_count) x tokens x corpus_size`. First-order alone (`--depth=1`) is fast on any target. `--depth=2` is fast on a low-fan-in target and slowest on the architecturally central files — precisely the ones most worth tracing. `--max-expand` bounds the worst case structurally (see § Traversal bound); it does not make the scan asymptotically cheaper. The asymptotic fix — a single inverted pass over the corpus for all referrers at once — is deferred: it would lose the per-target token gating that keeps basename matches from over-counting. If growth makes the worst case intolerable, that inversion (or migration to Python + a real dependency graph) is the escape; schema v1 is preserved across migrations.
- **Mirror-pair detection is canonical-table driven.** A pair listed in the canonical mirror table (e.g., `core/rules/<f>` ↔ `.claude/rules/<f>`) is treated as a mirror, regardless of byte-identity. Intentional but documented: byte-identity enforcement is `deploy.sh --check` Check 9's job, not the CLI's.
- **Symlinks not followed.** The CLI scans the source tree as-stored on disk.
- **Cross-repo references not detected.** Any reference outside `--root` is invisible. If skills/external repos consume PMO files, this is not captured.

---

## 10. Maintenance

- **Adding new mirror pairs:** Add the pair to BOTH `core/deploy/deploy.sh` Check 9 `MIRROR_PAIRS` and the mirror table in `blast-radius.sh::detect_mirror_pairs` (keep the two in sync — the CLI table is a faithful shadow of the canonical Check 9 array, not an auto-detector). Check 9 enforces byte-identity for the new pair.
- **Adding new scanned file types:** Edit the `SCANNED_TYPES` array in `blast-radius.sh` and commit per standard release process.
- **Adding new default exclusions:** Edit the `DEFAULT_EXCLUSIONS` array in `blast-radius.sh`. Prefer operator-passed `--exclude` flags over hardcoded defaults when the exclusion is contextual. **This is no longer the only way a tree leaves the scan.** On a git work tree the CLI enumerates from the index, so a git-ignored tree never becomes a candidate and needs no `DEFAULT_EXCLUSIONS` entry — adding one would be a second home for a fact `.gitignore` already owns. Reserve the array for trees that are tracked but must not count as referrers (mirror copies, packaged artifacts), and note that it still applies to **both** enumeration paths, because `--exclude=GLOB` and the `*.lock` filter must keep working under either scope.
- **Re-deriving the `--max-expand` default:** the default is set above the largest first-order fan-out in the corpus so it cannot fire on normal targets. Re-derive it when the corpus maximum approaches the current default — a default that starts firing on real targets silently converts complete analyses into partials. Lowering it to bound latency is an operator-visible trade (it truncates second-order expansion on the most-referenced files), not a bug fix.
- **Changing the traversal or the grep invocation:** `blast-radius.sh --self-test` group T1 asserts the *shape* of `grep_token`'s scan (batched, not one process per file), because the per-file form is a silent performance regression that no output diff would catch. If that function is refactored, keep the assertion pointed at the real invocation rather than relaxing it.
- **Schema bumps to v2:** Backward-incompatible changes (renaming fields, restructuring arrays) require a 1-release transition window where v1 readers and v2 readers must coexist. Document v1→v2 migration in `blast-radius-protocol-v2-migration.md` at the time of the bump.
- **Hook allowlist:** The CLI's path lives in `core/config/allowlists/script-execution-allowlist.txt`. If the path moves (e.g., directory rename), update the allowlist entry per [`core/rules/bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) §"Allowlist Maintenance".

---

## 11. See also

- [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) — Stage 5 Phase A §A3 cross-reference (canonical consumer)
- [`release/references/pipeline/stage-04-planning.md`](../pipeline/stage-04-planning.md) — Stage 4 A4 Cross-PR Overlap Audit (canonical consumer)
- [`core/rules/skill-deployment.md`](../../../core/rules/skill-deployment.md) — Mirror-pair source of truth (`core/rules/<f>` ↔ `.claude/rules/<f>`; canonical table at `core/deploy/deploy.sh` Check 9)
- [`core/rules/harness-deployment.md`](../../../core/rules/harness-deployment.md) — Mirror discipline for harness artifacts
- [`core/rules/bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) — Hook layer + allowlist maintenance
- [`release/references/how-to/hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) — Spoke prompt templates citing this CLI
- [`release/tools/blast-radius.sh`](../../tools/blast-radius.sh) — The CLI itself
- [`release/references/protocols/mixed-release-solutioning-routing.md`](mixed-release-solutioning-routing.md) — § 6 C1 dependency-isolation consumer of blast-radius output (§ 12 forward-note)

---

## 12. Domain-appropriate impact analysis (method selection + opt-out)

`blast-radius.sh` is the **doc-corpus inbound-reference tracer**: it answers "which files mention this file?" over the markdown/sh/json/yml/toml source tree (§ 1, § 9). It is the **DEFAULT** Stage-5 A3 impact-analysis instrument for doc / governance / pipeline-internal deliverables, and that default is unchanged. For a deliverable whose domain is not the doc corpus — a code module's import graph, a UI component's dependency tree, a platform's solution-component dependency — the markdown tracer returns a structurally-inapplicable signal (§ 9 names this limitation). The Stage-5 A3 method-selector that chooses the domain-appropriate fan-out method lives in [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) Phase A3.1; that selector is the **activation authority** (it decides which method fires for which domain). This section is the protocol-level **home** for the opt-out record schema the selector references and for a worked code-domain example. The selector branches on the `domain:` class field authored at Stage 4 Phase A1.5 (per [`release/references/pipeline/stage-04-planning.md`](../pipeline/stage-04-planning.md) § 5.7) — the same single substrate field the domain-guide index reads; the method-selection consumes that field, it does not re-derive a domain signal.

### Opt-out record schema

When a non-doc deliverable has no domain-appropriate instrument at design time, the Stage-5 spoke records the following block in its Evidence section (modeled on the § 7 spoke-citation block — it cites a *different* method plus a not-applicable statement for the default tool). This is a **within-A3 opt-out**: the issue stays in Stage 5, A3 fires, and design proceeds; it is NOT the whole-issue `SKIP` token from the mixed-routing protocol (which removes the issue from Stage 5 entirely, with no design at all).

```
### Impact analysis (Phase A3 — domain-aware)
- Deliverable domain (domain: class field): <software | web | enterprise-platform | ...>
- Method selected: <code import-graph | component dependency-tree | solution-component graph | blast-radius.sh>
- blast-radius.sh applicability: NOT APPLICABLE — markdown-tree tracer has no model of <import graph | component tree | solution-component dependency> (§ 9)
- Fan-out performed: <command(s) run OR manual trace described> → <N first-order consumers, top referrers>
- Impact classification: <Cosmetic | Behavioral | Structural> (§ 5 tiers, reused domain-agnostically)
```

The impact-classification tiers in § 5 (Cosmetic ≤1 / Behavioral 2–5 / Structural ≥6-or-critical) are **domain-agnostic** — they branch on first-order count plus criticality, not on "doc-ness" — and apply to every method. Only the fan-out discovery mechanism is domain-specific. An opt-out record missing the `Fan-out performed` line (no command and no manual-trace description) is an incomplete A3, not a valid opt-out: it fails the Section 1 exit gate in [`design-review-checklist.md`](../templates/design-review-checklist.md), which accepts a populated opt-out record's method + applicability + fan-out + tier lines in lieu of the schema-v1 fields when the method selected is not `blast-radius.sh`.

### Worked example — code-domain fan-out

A Stage-5 spoke designs a change to the `parse_skill_md` function inside the Python module `release/skills/pmo-skill-refiner/scripts/utils.py`, classified `domain: software`. `blast-radius.sh` would surface *doc* mentions of the file path but not the modules that `import` the symbol — the wrong set for impact purposes (this is precisely the import edge the markdown tracer has no model of, § 9). The domain-appropriate method is **import/call-graph fan-out** over the real `from … import` statements:

```
# first-order: who imports this module? (run from the repo root; reproduces exactly)
rg -n "from scripts\.utils import|import scripts\.utils" --type py release/skills/pmo-skill-refiner/scripts/
# → 4 importers:
#     run_eval.py:19           from scripts.utils import parse_skill_md
#     run_eval_audit.py:36     from scripts.utils import parse_skill_md
#     improve_description.py:17 from scripts.utils import parse_skill_md
#     run_loop.py:21           from scripts.utils import parse_skill_md
# second-order: who imports THOSE? (transitive, depth=2 to match blast-radius depth)
rg -n "from scripts\.(run_eval|run_eval_audit|improve_description|run_loop) import" --type py release/skills/pmo-skill-refiner/scripts/
# → run_loop.py imports improve_description + run_eval (the only depth-2 edges)
```

`first_order = 4 importers` → **Behavioral** tier (§ 5) → Risk Register entry + per-caller verify at Stage 6. The fan-out is over the **import graph** (genuine `from scripts.utils import` edges `blast-radius.sh` cannot reach), not the doc-reference graph. First-order semantics for this method: a first-order consumer is a file that directly sources, imports, or calls the changed module (a re-export counted once); second-order is depth=2, matching the blast-radius depth default, so the § 5 count-tiers are computed on a reproducibly-defined population. The pinned first-order command above is the reproducibility contract — running it against the branch tree returns exactly the 4 importers shown.

### Domain-fan-out tooling (software shipped; component/solution deferred)

A domain-fan-out *instrument* — an import-graph / component-tree / solution-component-graph CLI analogous to `blast-radius.sh` for the doc corpus — ships as a **sibling** CLI, `release/tools/domain-blast-radius.sh`, keyed off the `domain:` class field (a sibling rather than an extension of `blast-radius.sh`, which has no scanner-plug seam — see [ADR-068](../../../core/ADRs/ADR-068-domain-fan-out-sibling-vs-extend.md)). Both tracers emit the identical schema-v1 contract via the shared library `release/tools/lib/schema-v1-emit.sh`.

- **`--domain=software` — SHIPPED.** A code import-graph fan-out: it traces the files that directly `import` / `require` / `#include` the changed module (a re-export counted once) and emits schema-v1 `first_order[]`. Domain semantics that differ from the doc tracer: `reference_count` is an import-STATEMENT count (a comment-only mention is not an edge), `is_mirror` is the constant `false`, `second_order[].via`/`.depth` are **scoped out for v1** (emitted as `[]`, `second_order_count: 0` — a named follow-on, not claimed here), and `stats.total_files_scanned` is the code-file denominator, not the whole corpus. The tool's header + ADR-068 hold the full field-semantics table.
- **`--domain=web` (component-tree) and `--domain=enterprise-platform` (solution-component graph) — DEFERRED.** The scanners are honest not-implemented stubs (exit 5). Until those ship, those domains use the manual fan-out documented above plus the opt-out record.

For any domain the tool cannot run, the manual fan-out + opt-out is a **complete** A3 on its own — design still happens; the tool is an ergonomics upgrade, not a correctness gate.

### Downstream blast-radius consumers (forward-note)

Other surfaces compute gates from `blast-radius.sh` schema-v1 output on a deliverable's files — the mixed-routing dependency-isolation control (per [`mixed-release-solutioning-routing.md`](mixed-release-solutioning-routing.md) § 6 C1) and the Stage 4 A4 Cross-PR Overlap Audit (§ 6 above). When a deliverable's A3 records a non-markdown method plus an opt-out, those consumers must use the domain-appropriate fan-out set rather than the structurally-inapplicable markdown trace; the wiring for each is authored when that path activates (mixed-routing is documented-but-disabled today, so this is latent, not live). Stating it here prevents a silent divergence in which one consumer opts a deliverable out of the markdown tracer while another still computes a gate from its degraded output.

### Cutover (introducing-release-exempt)

This section's method-selection home + opt-out record apply to releases entering Stage 5 strictly AFTER this protocol's introducing-release merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). **The introducing release itself is exempt** (reflexive-pipeline-loop discipline — it is itself a pipeline-internal/governance release, so its own Stage-5 A3 takes the markdown-tree DEFAULT). All releases that entered Stage 5 prior to the introducing release are also exempt.

## 13. Structural / path-move mode (`--mode=structural`)

The default tracer answers *"who references this FILE?"* and the domain sibling answers *"who imports this MODULE?"*. Neither answers *"who hard-codes this PATH?"* — the consumer class that a **directory or file move** breaks: a script whose `RELEASE_NOTES_DIR="…/release/releases/notes"` default, a config's path literal, or an allowlist entry that names the OLD path by string. That miss is not hypothetical — the release-notes-folder move silently broke the Stage-13 GitHub-Release emit for ~5 releases before it was root-caused. The structural mode is the instrument that catches this class at design time.

### Invocation

```
blast-radius.sh --mode=structural [OPTIONS] <old_path>
```

- `<old_path>` is a **path string to search for**, not a file to resolve. It may be a **directory prefix** (`release/releases/notes` or `release/releases/notes/`), a single file path, or a path that **no longer exists on disk** (it was moved away — the whole point). Unlike the default mode, structural mode does NOT require the target to be an existing regular file and does NOT reject a target under an exclusion (a moved-FROM path under an excluded tree is still a valid query).
- A directory-prefix input matches any hard-coded reference containing that prefix (via `grep -F` literal-substring match). A trailing slash is normalized off, so `notes/` and `notes` behave identically.
- The scan runs over the same corpus, the same enumeration (tracked-file scoping where the root is a git work tree, `find` otherwise), the same `DEFAULT_EXCLUSIONS` (including the `.claude/worktrees/` exclusion) and the same `SCANNED_TYPES` as the default tracer — it is a NEW query over the SAME scan list, not a new scanner. Both modes therefore emit `stats.scan_scope` and `stats.scan_scope_status`, and both are read the same way. The default doc-tracer path is untouched.

### Output semantics (schema-v1)

The mode emits the full schema-v1 envelope via the shared library, with three fields carrying structural-specific meaning (mirrors the domain tracer's F4 semantics block):

- `first_order[].path` — a file that **hard-codes the old path literal** (a consumer).
- `first_order[].reference_count` — count of distinct `(file, line)` hits of the old-path literal in that file.
- `first_order[].matches[]` — up to 5 `{line, snippet}` of the hard-coded references.
- `first_order[].is_mirror` — **always `false`** (a path sweep has no mirror concept; a deliberate documented constant, exactly as the software domain does).
- `second_order` / `stats.second_order_status` / `stats.second_order_count` — **`[]`** / **`not-run`** / **ABSENT** (scoped out): a path-literal consumer sweep is first-order by nature — "who hard-codes this path?" has no transitive depth-2. The scope-out is stated **positively** rather than as a zero: the counter is deleted from the emit and `second_order_status_reason` names the mode. A `0` here would have been a not-computed value in a measured value's slot, indistinguishable from a depth-2 run that examined the corpus and found nothing.
- `stats.total_files_scanned` — the doc-corpus denominator over the population `stats.scan_scope` names (same as the default tracer — it scans the same list, built by the same enumeration).

Because `grep -F` is a literal-substring match, the mode deliberately **over-includes**: it will surface references that legitimately need no update (a path named in a historical comment, an archived plan, a coincidental substring, prose documenting the OLD layout). That is by design — see the update-or-accept workflow below.

### Update-or-accept workflow (the gate posture)

When a release moves or renames a directory/file, the Stage-5 structural/path-move consumer sweep (Phase A3.3 in [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md)) runs `--mode=structural <old-path>` and requires each flagged consumer to carry an explicit **disposition** before the design-handoff gate:

- **updated** — the path was rewritten to the new location, or
- **accepted** — recorded "not a real consumer, reason: …" (a false positive, a historical mention, an intentionally-retained reference).

A consumer with **neither** disposition is *unreconciled* and is what the gate flags. This is a **soft, reconcilable** gate — never a hard merge-block on a raw literal hit — so a false positive cannot day-one-block a legitimate merge. It rolls out **shadow → warn → enforce**: report-only first (characterize the false-positive rate on real moves), then non-blocking warn, then gate-blocking on any unreconciled consumer once the rate is understood. The gate criterion is **SR-G5** in [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) § 7.2; the extend-vs-sibling architecture and the soft-gate rollout are recorded in [ADR-090](../../../core/ADRs/ADR-090-structural-path-move-mode-extend-vs-sibling.md) (which qualifies the ADR-068 sibling decision with the "same-scanner → extend; different-scanner → sibling" boundary).

### Cutover (introducing-release-exempt)

The Phase A3.3 sweep + SR-G5 gate apply to releases entering Stage 5 strictly AFTER this mode's introducing-release merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). The introducing release itself is exempt (reflexive-pipeline-loop discipline). The mode ships in **shadow** for its introducing release — available to run, not yet gate-blocking.
