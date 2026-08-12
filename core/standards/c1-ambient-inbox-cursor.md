---
title: C1 — Ambient Inbox Drop-Zone + Dedup Cursor
purpose: Declares the ambient-intake watched inbox drop-zone and the dedup cursor schema (path + SHA-256 content-hash identity) that the Path A scheduled intake sweep consumes to skip already-ingested files. Wiring spec only — no autonomous processing ships from the inbox itself.
type: standard
status: ACTIVE
consumers: "c2-intake-sweep-path-a.md (the Path-A scheduled sweep reads this cursor to skip already-ingested files); the OPERATIONS.md Daily Processing Cycle intake steps (consume the inbox drop-zone as an intake source)"
composes_with: [depersonalization-spec.md, ../disciplines/context-lifecycle-model.md, ../specs/autonomy-tiers.md]
reversibility: CHEAP (spec/token/field) — except the cursor identity scheme (MODERATE) / Confidence HIGH
---

<!-- repo-integrity: allow-issue-ref -->

# C1 — Ambient Inbox Drop-Zone + Dedup Cursor

> Reversibility: CHEAP (spec/token/field) — except the cursor identity scheme (MODERATE: the contract the Path A scheduled intake sweep, C2, binds to). Confidence: HIGH.
> Consumed by: the Path A scheduled intake sweep (C2), which reads the inbox + cursor to skip already-ingested files.

## 1. Drop-zone declaration
The ambient inbox is a single watched directory resolved via the operator-instance
path token `<OPERATOR_INSTANCE_INBOX_PATH>` (per core/standards/depersonalization-spec.md §4).
- Canonical default: `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/inbox` (gitignored).
- Override: `operator.toml [paths].operator_instance_inbox_path` (empty → default; non-empty → verbatim).
Transcripts and emails land here for ambient ingest. The directory is operator content
(OPERATOR-INSTANCE class) and is never git-tracked.

**The drop-zone is provisioned at install; it is not self-activating.** This spec declares
the directory, it does not create it. Creation is an install-time step: `create_dir_layout`
in `docs/scripts/setup-workspace.sh` creates it (together with the C2 run-log directory and
the C3 external-sync directory) on a fresh install, and `update.sh` back-fills all three onto
an already-installed workspace. **The two resolve the path differently, and the difference
is load-bearing.** `update.sh` and `validate-install.sh` check A2 both resolve through
`pmo_inbox_path_for` in `core/deploy/lib-instance-path.sh`, so they follow an override or a
relocation of the operator-instance family. `create_dir_layout` does **not**: it uses
`${WORKSPACE_ROOT}`-relative literals, deliberately and for a stated reason — that function
runs before the resolver is sourced, and every sibling entry in the same layout list is
already a workspace-relative literal (`docs/scripts/setup-workspace.sh` § Directory layout
creation records this in full).

**The consequence, stated rather than implied:** on a workspace whose operator-instance
family has been relocated, a fresh install provisions at the default path while A2 reads the
relocated one, so A2 FAILs naming the directories it expected. `update.sh` back-fills at the
resolved path and clears it. Relocation-proofing therefore holds for the back-fill and
assertion surfaces, and **not** for fresh install — do not read this section as claiming
otherwise. `validate-install.sh` check A2 asserts the three directories exist and FAILs
naming any that do not. Read this section as a
declaration whose provisioning lives in those four surfaces — not as a directory that appears
because this document says it should.

The **cursor** inside the drop-zone is deliberately NOT provisioned: it stays lazily created
on first ingest per §2, because an empty cursor file and an absent one are the same state and
creating one would assert an ingest that never happened.

## 2. Dedup cursor
- Runtime instance: `<OPERATOR_INSTANCE_INBOX_PATH>/.cursor.json` (gitignored; created lazily on first ingest).
- Format: a single JSON object, keyed by file identity. One record per ingested file.
- Identity key: `path + SHA-256(file content)`. Content-hash (not mtime+size) is the stable
  primitive: the governed MCP sync channel rewrites mtime, so an mtime+size key would
  falsely re-process an unchanged synced file. Identical content under a new name is a
  detectable duplicate.
- Record shape (per file):
    { "<sha256>": { "path": "<relative-to-inbox>", "state": "<Context-* state>",
                    "captured_at": "<ISO-8601>", "structured_at": "<ISO-8601|null>" } }

## 3. State mapping (context-lifecycle-model.md §2 — verbatim object-typed names)
- `Context-Captured` — set on arrival (§2 entry: "File present (user upload, MCP sync, drop)").
- `Context-Structured` — set once routed + registered (§2 entry: "Routing complete + register
  entry written"); reached via file-router classify+route (mechanism 1, the
  Context-Captured → Context-Structured transition).
The cursor writes ONLY these two §2 values during the inbox lifecycle; downstream states
(`Context-Reviewed` / `Context-Decided` / `Context-Closed`) are out of C1 scope.

## 4. Read-before-process flow (the dedup contract)
1. Scan the inbox directory for files.
2. For each file, compute `path + SHA-256(content)`.
3. Look up the identity in the cursor. If present AND state == `Context-Structured` → SKIP
   (already ingested; re-scan re-processes nothing — AC2).
4. If absent → record as `Context-Captured`, then (subject to the clamp, §6) route via
   file-router; on success set `Context-Structured` + `structured_at`.

## 5. Orphan-sweep fallback (C1 does NOT replace it)
Files that bypass the inbox (dropped at workspace root, routed directly to a project folder)
are caught by the existing Orphan Detection: OPERATIONS.md §Daily Processing Cycle step 15
+ context-lifecycle-model.md §5 mechanism 12 (allocated to the Context-Captured stall).
The inbox is the fast, dedup-aware path; the orphan sweep is the catch-all for bypass.
Both mechanisms compose; neither supersedes the other.

## 6. Clamp to automation_level (the C0 keystone)
Per operator.toml [automation].automation_level (C0; enum off/recommend/bounded_auto;
ceiling `effective = min(automation_level, per-action max)`):
- At `automation_level: off` the inbox is INERT — files accumulate, the cursor may passively
  record arrivals as `Context-Captured`, but NO auto-processing fires (no auto-route, no
  advance to `Context-Structured`). The orphan sweep still flags accumulation (step 15 is
  operator-cadence, not dial-gated).
- C1 itself performs no autonomous action at any level — it watches and records; the C2 sweep
  is what the dial governs. Tier semantics: see core/specs/autonomy-tiers.md (Tier 0 Manual =
  per-instance operator approval; `off` sits below the Tier-0 recommend floor).

## 7. Egress constraint
Ingestion uses the governed MCP channel, NOT Bash/WebFetch. core/hooks/block-egress.sh
matches only the Bash and WebFetch tools (matcher scope: Bash, WebFetch); MCP ingest tools
are not in scope and are the sanctioned channel.
