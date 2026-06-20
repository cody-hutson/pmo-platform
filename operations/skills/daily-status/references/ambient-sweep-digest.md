<!-- reference-durability: allow-link -->
# Ambient Sweep Digest — Run-Record Reader Reference

## Purpose

This file is the reader-side reference for the daily-status **Ambient Sweep Digest**
block (see SKILL.md `## Ambient Sweep Digest`). It defines exactly which run-record
fields the heartbeat reads, the four anti-silent-failure states, the held-proposals
surface, and the source-resolution/degradation rules. The SKILL.md section states the
operational contract and the per-mode wiring; this file holds the field-level detail the
section points to.

The digest is **read-only synthesis**: it reads the two ambient-sweep run-logs and
renders their state into the AM/PM daily-status output. It writes nothing new, mutates no
external system, and surfaces the sweeps' own proposals attributed to the sweeps — it does
not first-person recommend. That preserves the host skill's `## Reversibility Scope`
opt-out.

---

## 1. The producer contract (consumed verbatim — do NOT re-canonicalize)

The two ambient sweeps freeze ONE append-only JSONL run-record schema, discriminated by a
first-class `sweep` field. The digest **reads** that schema — it never invents, renames,
or re-canonicalizes a run-record field. The two producers deliberately aligned to one
field set precisely so this heartbeat parses a single shape across both sweeps.

- **Path-A intake sweep** — canonical schema: `core/standards/c2-intake-sweep-path-a.md`
  section 5. Discriminator `sweep: "intake-path-a"`. Run-log token
  `<OPERATOR_INSTANCE_INTAKE_SWEEP_RUNLOG_PATH>`
  (default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/ambient-intake/run-log.jsonl`).
- **Path-B external-sync sweep** — canonical schema:
  `core/standards/c3-external-sync-path-b.md` section 5. Discriminator
  `sweep: "external-sync-path-b"`. Run-log token
  `<OPERATOR_INSTANCE_EXTERNAL_SYNC_RUNLOG_PATH>`
  (default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/external-sync/run-log.jsonl`).

Both run-logs are append-only JSONL; the digest reads the **latest record per file** (the
last line) and labels each heartbeat row by the record's `sweep` value. The two files are
distinct so the two sweeps' records never interleave; the digest reads both.

---

## 2. Heartbeat field-mapping (per sweep)

The heartbeat renders one line per configured sweep from the latest run-record in that
sweep's run-log. The fields it reads map per sweep as follows:

| Heartbeat element | Path-A (`sweep:"intake-path-a"`) | Path-B (`sweep:"external-sync-path-b"`) | Render |
|---|---|---|---|
| Sweep label | `sweep` = `"intake-path-a"` | `sweep` = `"external-sync-path-b"` | row discriminator |
| Last-run timestamp | `finished_at` (fallback `run_id` if mid-flight / errored before finish) | `finished_at` (fallback `run_id`) | "Last run: <ISO>" |
| Overall status | `status` (`ok` / `partial` / `error`) | `status` (`ok` / `partial` / `error`) | status glyph |
| Ran-but-empty flag | `empty: bool` | `empty: bool` | RAN-EMPTY when true |
| Processed count | `files_processed` | `drift_total` (or `proposals_emitted`) | "processed: N" |
| Skipped count | `files_skipped` | per-adapter `adapters[].skipped_reason` rows | "skipped: N" |
| Error count / failures | `errors[]` | `errors[]` | "errors: [..]" rendered verbatim |
| Held proposals | `proposals_held` | `proposals_held` | feeds the held-for-approval queue |
| Auto-executed (informational) | `auto_written` | `auto_closed` | "auto: N" |

The `errors[]` array is rendered **verbatim** (for example `"github: 503 from search API"`)
so a failure is visible, never summarized away.

---

## 3. The four anti-silent-failure states

The heartbeat distinguishes four observable states. Compute the state in **two steps**:
first decide fresh-vs-stale, only then read `status` / `empty`.

1. **RAN-OK (✅)** — a fresh `run_id` within the cadence window, `status: ok`,
   `empty: false`. The sweep ran and did work with no failure.
2. **RAN-EMPTY (◽)** — a fresh `run_id`, `status: ok`, `empty: true`. The sweep ran and
   found zero work. This is the explicit "nothing to do" signal — it is NOT a failure and
   NOT a silence. It proves the sweep is alive and was simply quiet.
3. **RAN-ERROR (❌) / RAN-PARTIAL (⚠️)** — a fresh `run_id`, `status: error` or
   `status: partial`, `errors[]` populated. The sweep ran and failed wholly or partially;
   render `errors[]` verbatim.
4. **DID-NOT-RUN / MISSED (⛔)** — **no `run_id` newer than the expected-cadence window.**
   The sweep did not fire. The run-log carries no fresh record, so the heartbeat computes
   staleness (the latest `finished_at` / `run_id` against the sweep's registered cadence)
   and renders an explicit MISSED row regardless of the stale record's `status`.

State 4 is the load-bearing distinction: the digest exists so a silent sweep failure is
impossible — a sweep that stopped firing leaves its last (successful) record as the newest
line, so reading "latest line = current run" would mask the exact did-not-run failure the
heartbeat is built to expose. RAN-EMPTY (state 2) versus MISSED (state 4) is the
"ran-and-found-nothing versus did-not-run" distinction the digest's parent acceptance
criteria require.

### Cadence-window source (the staleness threshold)

The "expected since" boundary is the sweep's **registered cadence** (the scheduled-task
cron), read as a parameter — do NOT hardcode a fixed window such as "24h" in the SKILL.md.
Each sweep registers a cadence (default once-daily, operator-local timezone). If the
cadence is unknown at render time, default the staleness window to one daily-processing
cycle and flag the assumption. This obeys the platform parameterize-over-hardcode rule.

---

## 4. Held-for-approval surface (autonomy Tier-1 surface-for-approval)

Each sweep clamps every action to `effective = min(automation_level, per-action max)` (the
ambient-automation dial). At `recommend` (the default) every Tier-1 mutating action is
drafted and surfaced but **held** — not executed. Each run-record carries `proposals_held`
plus the proposal evidence strings the sweeps emit.

The held queue reads `proposals_held` (and, for legibility, the per-proposal evidence
strings) and renders an operator-actionable list: "N actions the ambient sweeps proposed
but held at your `automation_level` — approve to apply." This is the autonomy-tiers
Tier-1 "agent drafts, operator approves before action" surface
(`core/specs/autonomy-tiers.md` Tier 1 — Recommend).

The digest **surfaces** the held queue (makes it visible); it does NOT approve or execute
the held actions. The approval gate for the underlying action lives at the sweep / tracker
surface (Tracker Manager → User Approval), not at the digest. Each held line is attributed
to its sweep and never first-person ("the intake sweep proposed X, held at `recommend`" —
never "I recommend X").

### Permanently-held items (irreducible floor)

Some sweep proposals are permanently held at any `automation_level` — RAID and
Document-Tier-1 stakeholder-facing closes never auto-execute (per the autonomy-tiers
Irreducible Human Tasks set). The held queue annotates these as "held — requires your
approval (never auto)" so a permanently-held item is not mistaken for one that
`bounded_auto` would have cleared. The digest does NOT re-enumerate the irreducible set; it
reads the sweep's own disposition from the run-record and surfaces what the sweep marked
held.

---

## 5. Document-Tier classification (two tiers, kept distinct)

Two different things sit at two different tiers; the digest keeps them distinct:

- **The digest REPORT** is **Document Tier 2** (auto-write). It renders into the
  daily-status AM/PM output, which is already a Document-Tier-2 auto-write per
  `core/governance/OPERATIONS.md` section Operational Artifacts (the Daily Status Log
  classification). The digest adds **no new approval gate** for the report itself — it
  rides the existing Post-Generation Actions flow.
- **The held PROPOSALS the digest surfaces** remain **Autonomy Tier 1**. The operator must
  approve the underlying action before the sweep applies it; that gate lives at the sweep /
  tracker surface.

Collapsing these two would either gate the report unnecessarily (defeating the auto-write)
or auto-execute held actions (violating Tier-1). The digest auto-writes the *visibility* of
the held queue; it does not auto-execute the *held actions*.

---

## 6. Source resolution + graceful degradation

The digest must never fail the AM/PM generation. It reads two operator-instance run-log
files and degrades gracefully:

- **Run-log file absent** → render "ambient sweep: not configured" (the sweep was never
  installed). Do NOT error, do NOT block the update. A sweep that was never set up is NOT a
  missed run.
- **Run-log present but empty** (zero records) → "ambient sweep: no runs recorded yet."
- **Run-log present, latest record stale** → ⛔ MISSED row (the anti-silent-failure surface,
  section 3 state 4).
- **Malformed / unparseable latest record** → "ambient sweep: run-log unreadable — check
  <path>" and flag it; never silently drop a corrupted run-log — a corrupted run-log is
  itself a signal.

This degradation discipline mirrors the host skill's existing `**Negative paths
(REQUIRED — never fail silently, never fabricate)**` convention in `## RAG, Variance &
Buffer Status`.

---

## 7. Teams-ready versus PMO-internal placement (load-bearing)

The heartbeat and held-proposals are **PMO-internal operational signal**, not
stakeholder-channel content. They render in the working surface (the Daily Status Log, or a
Daily-Connect prep-note), NOT inside the under-40-line Teams-ready body, and they obey the
host skill's existing **No internal IDs in stakeholder output** rule. The Teams-ready body
stays the team's carry-forward state; the digest is the operator's automation-health read.
This preserves the host skill's audience-calibration contract — the digest is additive to
the operator-facing record, not an injection into the team channel.
