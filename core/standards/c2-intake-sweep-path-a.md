---
title: C2 — Path-A Scheduled Intake Sweep
purpose: Declares the scheduled Path-A intake sweep — a mcp__scheduled-tasks registration that drives the existing OPERATIONS.md Daily Processing Cycle intake steps (1 Intake / 2 Surfacing / 3 Classification / 4 PPM Triage / 5 Register / 6 Follow-up + 15 Orphan) over the C1 ambient inbox, reading the C1 cursor to skip already-Context-Structured files — clamped so every emitted action resolves effective = min(automation_level, per-action max). Wiring spec only — adds the scheduler + cursor-aware skip; it drives the existing intake steps, it does not fork a parallel intake engine. The sweep emits one run-record per run (field-aligned to the C3 sweep run-record) so a silent no-op is impossible.
type: standard
status: ACTIVE
consumers: "mcp__scheduled-tasks (the registration target that runs the sweep); OPERATIONS.md Daily Processing Cycle (the intake steps this sweep drives over the C1 inbox); c1-ambient-inbox-cursor.md (the cursor this sweep reads + advances)"
composes_with: [depersonalization-spec.md, c1-ambient-inbox-cursor.md, ../disciplines/context-lifecycle-model.md, ../specs/autonomy-tiers.md, ../governance/OPERATIONS.md]
reversibility: MODERATE (spec + 1 path field + 1 token row + a scheduled-task registration + a consumer registration) / Confidence HIGH — git revert restores the tracked surface; the scheduled-task registration rolls back by deregistration (non-git install-root state); the runtime cursor + run-log are gitignored, so their post-revert absence is harmless (a re-scan re-seeds). The one MODERATE commitment is binding to the C1 cursor identity scheme (changing it post-ship orphans cursor entries).
---

<!-- repo-integrity: allow-issue-ref -->

# C2 — Path-A Scheduled Intake Sweep

> Reversibility: MODERATE / Confidence: HIGH. The run-record schema (§5) is the load-bearing contract the C4 sweep-digest/heartbeat consumer binds to — do NOT change its field set after this spec ships without re-touching that consumer. It is field-aligned to the C3 sweep run-record so the C4 heartbeat reads ONE schema across both sweeps; the `sweep` discriminator is the only per-sweep difference.
> Consumed by: the C4 sweep-digest/heartbeat, which reads the latest run-record per sweep (last-run / processed / skipped / error / failures) and rolls `proposals_held` into its "actions proposed but held" digest block.
> Consumes: the C1 ambient inbox + dedup cursor (`c1-ambient-inbox-cursor.md`) — C2 is the cursor's sole hard consumer AND its writer; and the C0 automation dial (`operator.toml [automation].automation_level`) as its autonomy ceiling.
> Drives: `core/governance/OPERATIONS.md` §Daily Processing Cycle intake steps 1-6 + 15 — the existing cycle's intake sub-path. C2 is the automation half of "triggered by user or automation"; it adds the scheduler + cursor-aware skip, not the intake logic.

## 1. What C2 adds (the delta — scheduler + cursor-aware skip over the existing cycle)
The Daily Processing Cycle intake steps already exist and are pre-authorized for automation
("Execute this cycle once per day, triggered by user or automation"). What is missing is the
*scheduler* that drives them without the operator kicking off each cycle by hand, and the
*cursor-aware skip* so a re-scan over an unchanged inbox re-processes nothing. C2 adds exactly
those two things, as one scheduled sweep:
- **(a) a schedule** — a `mcp__scheduled-tasks` registration runs the intake sub-path independent
  of the manual daily cycle (§9).
- **(b) a cursor-aware skip** — read the C1 cursor (path + SHA-256 identity) and SKIP any file
  already at `Context-Structured` (§3); a re-scan over an unchanged inbox advances nothing.
- **(c) a clamp** — every emitted action resolves `effective = min(automation_level, per-action
  max)` (§7); at `recommend` (default) NO Tier-1 mutation executes — drafts/surfaces only.
- **(d) a run-record** — one per run (success / empty / error) so a silent no-op is impossible (§5).

C2 invents no new intake logic, no new state machine, and no parallel intake engine — it drives
the EXISTING Daily-Processing-Cycle steps. A parallel engine would fork the intake logic into two
drift-prone code paths for the same steps. The single sweep that drives the existing steps is the
forced approach (upstream-fixed by the parent story + epic).

## 2. The intake steps the sweep drives (verbatim from OPERATIONS.md §Daily Processing Cycle)
The sweep executes, in order, the intake sub-path of the existing cycle over the C1 inbox. It does
NOT execute steps 7-14 / 16-17 (specialist processing, comms digest, external sync — which is the
Path-B sweep's surface — consolidated update, approval, execution, artifact check, portfolio sync,
proactive next-steps, session-state); those fire under operator cadence or are owned by other cards.

| Step | Name (OPERATIONS.md) | What the sweep does over the inbox |
|---|---|---|
| 1 | File Intake | Enumerate new files in the C1 inbox (`<OPERATOR_INSTANCE_INBOX_PATH>`, the drop-zone). |
| 2 | Transcript Surfacing | Resurface `UNASSIGNED` / `PENDING` transcripts; `Context-Structured` >3bd escalates (mechanism 5, the §4 threshold). |
| 3 | File Classification | file-router classifies each new file (mechanism 1). |
| 4 | PPM Triage | PPM Agent processes new/unprocessed items against the carry-forward (mechanism 6). |
| 5 | Register Update | Transcript Register TR-### entry written (mechanism 2) — the file reaches `Context-Structured`. |
| 6 | Follow-up Tags | PPM emits `[DELIVERY]` / `[COMMS]` / `[TECHNICAL]` / `[CHANGE]` / `[RISK]` / `[DECISION]` (mechanism 7). |
| 15 | Orphan Detection | Flag files that bypassed the inbox (workspace-root / direct-to-folder) — mechanism 12, the C1 orphan-sweep fallback. |

Step 15 drives the existing Orphan Detection; it does NOT replace the orphan-sweep fallback — the
inbox is the fast dedup-aware path, the orphan sweep is the catch-all for bypass (both compose).

## 3. Consuming the C1 cursor (the dedup / skip contract)
C1 (`c1-ambient-inbox-cursor.md`) froze the inbox + cursor. C2 is its sole hard consumer AND the
cursor writer. The read-before-process flow (C1 §4, which C2 implements as the writer):
1. **Scan** `<OPERATOR_INSTANCE_INBOX_PATH>` for files (step 1).
2. For each file, **compute `path + SHA-256(content)`** — the C1 identity key (content-hash, NOT
   mtime+size: the governed MCP sync channel rewrites mtime, so mtime+size would falsely re-process
   an unchanged synced file).
3. **Look up** the identity in `<OPERATOR_INSTANCE_INBOX_PATH>/.cursor.json`. If present AND
   `state == Context-Structured` → **SKIP** (already ingested; a re-scan re-processes nothing).
4. If **absent** → record `Context-Captured` (cursor upsert), then — subject to the clamp (§7) —
   drive steps 3-6; on file-router + register success, upsert `Context-Structured` + `structured_at`.

C2 binds to the C1 identity scheme, the cursor format, and the two C1 state values — **changing the
C1 identity scheme post-ship is MODERATE-reversibility** (it orphans every cursor entry). The
cursor record shape (C1 §2, the contract C2 writes against):
```
{ "<sha256>": { "path": "<relative-to-inbox>", "state": "<Context-* state>",
                "captured_at": "<ISO-8601>", "structured_at": "<ISO-8601|null>" } }
```

## 4. The Context Lifecycle forward contract — consumed VERBATIM
C2 IS the daily-sweep automation the Context Lifecycle Model pre-registers as out-of-scope-deferred
(the "Automated daily-sweep scheduler that scans the workspace for stalled content and emits
escalation outputs" slot). Per the §6 forward contract, C2 re-derives nothing — it consumes the
state vocabulary, thresholds, and mechanism numbers verbatim.

**(1) State vocabulary — the 5 object-typed §2 names, verbatim, never aliased:**
- `Context-Captured` — file present in the inbox, not yet classified / registered (set at step 1).
- `Context-Structured` — classified by file-router AND registered (reached at step 5).
- `Context-Reviewed` — processed by an analytical skill; items + follow-up tags emitted (reached
  via step 6 / the PPM Triage mechanism).
- `Context-Decided` — items routed to trackers OR rejected with rationale (the clamp gates this
  write, §7).
- `Context-Closed` — items resolved per the Evidence Gate (terminal; closure is the Path-B sweep's
  Evidence-Gate surface, not C2's intake scope).

C2's intake span writes `Context-Captured` → `Context-Structured` (the cursor) and advances toward
`Context-Reviewed` / `Context-Decided` via the triage + tracker steps (clamped). It authors no
state name absent from §2.

**(2) Stall thresholds — §4 as canonical (quoted, not re-derived):**
- `Context-Captured`: **>1 business day** unrouted → mechanism 12 (Orphan Detection) — the sweep's
  step-15 surface.
- `Context-Structured`: **>3 business days** (escalation pending) / **>5 business days** (escalation
  to project lead) while `UNASSIGNED` / `PENDING` → mechanism 5 (Unassigned Transcript Escalation)
  — the sweep's step-2 surface.
- `Context-Reviewed`: **>1 daily processing cycle** tagged-but-not-written → mechanism 15 (Tracker
  Manager consolidated update).
- `Context-Decided`: per item type (RAID indefinite-open; Action 5bd without status; Decision
  open-until-evidence) → mechanism 9 (Evidence Gate).

**(3) Mechanism-number references in escalation strings (§5, verbatim numbers — written WITHOUT a
leading hash so the number is read as a Context Lifecycle mechanism number, not an issue reference):**
every escalation the sweep emits cites the §5 mechanism number. The canonical escalation-string
forms the sweep emits:
- `"Stall at Context-Captured — mechanism 12 escalation pending"` (orphan / unrouted >1bd).
- `"Stall at Context-Structured — mechanism 5 escalation pending"` (UNASSIGNED >3bd) →
  `"Stall at Context-Structured — mechanism 5 escalation to project lead"` (>5bd).
- `"Stall at Context-Reviewed — mechanism 15 escalation pending"` (tagged, tracker-write not yet
  executed beyond 1 cycle).

These strings carry the object-typed state name + the §5 mechanism number — the two elements that
make the escalation traceable to its anti-loss mechanism. (Mechanism numbers are Context Lifecycle
mechanism numbers, NOT issue references; they are written without a leading hash so the durable-corpus
reference-durability gate does not read them as issue refs.)

**(4) Consumer registration via `## Framework Reference`** — see the section at the end of this spec.

## 5. The run-record (failure-visibility producer contract — field-aligned to the C3 sweep)
Every sweep run — success, error, or empty — appends ONE run-record so a silent no-op is impossible.
The C4 sweep-digest/heartbeat reads **last-run / processed / skipped / error counts / failures +
held-proposals** per sweep, and must distinguish "ran and found nothing" from "did not run". The
C3 Path-B sweep already froze this run-record as the producer/consumer contract; **C2 adopts the
identical field set** (with the Path-A discriminator) so C4 parses ONE schema across both sweeps.

```
Intake-sweep run-record (one per scheduled sweep — JSONL append; field-aligned to the C3 sweep run-record):
  run_id: <ISO-8601 UTC start>
  sweep: "intake-path-a"                          # the discriminator the C4 digest reads (REQUIRED — first-class field; the C3 sweep emits "external-sync-path-b")
  status: ok | partial | error                    # partial = some steps/files failed, some succeeded
  files_scanned: N
  files_processed: N                              # advanced to Context-Structured this run
  files_skipped: N                                # cursor-hit (already Context-Structured) — the dedup proof
  skipped_detail: [ { reason } ]                  # e.g., "cursor-hit", "unsupported-format"
  drafts_surfaced: N                              # Tier-1 proposals surfaced (held) — PPM triage / tracker proposals
  auto_written: N                                 # Tier-2 in-scope writes executed (TR-###, carry-forward)
  proposals_held: N                               # Tier-1 / out-of-scope / RAID — held at the ceiling
  escalations: [ "Stall at Context-Structured — mechanism 5 escalation pending", ... ]
  errors: [ "<step>: <message>" ]
  empty: bool                                     # true = ran, processed zero new files (distinct from "did not run")
  finished_at: <ISO-8601 UTC>
```

- **`sweep` discriminator (REQUIRED):** the run-record MUST carry the literal `sweep: "intake-path-a"`
  as a first-class field. The C4 sweep-digest/heartbeat reads it to attribute each run-record to its
  producer sweep and to keep the two run-logs distinct (C2's `ambient-intake/run-log.jsonl` vs. the
  Path-B sweep's `external-sync/run-log.jsonl`). This field is the cross-card discriminator — do not
  drop or rename it.
- **Field-alignment to the C3 sweep run-record (the C4 one-schema guarantee):** C2's
  `files_processed` / `files_skipped` / `drafts_surfaced` / `proposals_held` / `errors` / `empty` /
  `status` / `run_id` / `finished_at` map one-to-one onto the C3 sweep's `polled` / `skipped` /
  `proposals_emitted` / `proposals_held` / `errors` / `empty` / `status` / `run_id` / `finished_at`.
  The `sweep` discriminator lets C4 label each heartbeat row by source. C4 reads the latest
  run-record per sweep (last-run / counts / failures) and rolls `proposals_held` into its "actions
  proposed but held" digest block.
- **The `empty` flag is the anti-silent-failure seam:** it distinguishes "sweep ran and processed
  nothing" from "sweep did not run" (absence of a fresh `run_id`) — the distinction the C4 heartbeat
  requires to tell RAN-EMPTY from MISSED.
- **Location:** operator-instance path token `<OPERATOR_INSTANCE_INTAKE_SWEEP_RUNLOG_PATH>` (per
  `core/standards/depersonalization-spec.md` §4). Canonical default:
  `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/ambient-intake/run-log.jsonl` (append-only JSONL;
  gitignored). Override: `operator.toml [paths].operator_instance_intake_sweep_runlog_path`
  (empty → default; non-empty → verbatim). Same schema as the C3 sweep's run-log, a **distinct file**
  so the two sweeps' run-records do not interleave (C4 reads both files).
- **Producer / consumer freeze:** C2 is the **producer**; the C4 sweep-digest/heartbeat is the
  **consumer** — do not change the field set after C2 ships without re-touching C4 (the C3↔C4 freeze,
  extended to C2↔C4).

## 6. Clamp to automation_level (the C0 keystone)
Every sweep-emitted action computes `effective = min(automation_level, per-action max)`, where
`automation_level` is read from `operator.toml [automation].automation_level` (the C0 dial; enum
`off` / `recommend` / `bounded_auto`; default `recommend`) and `per-action max` is the action's
Autonomy Tier ceiling per `core/specs/autonomy-tiers.md`. The per-step clamp:

| Sweep action (Daily-Cycle step) | per-action max (Autonomy Tier) | At `off` | At `recommend` (default) | At `bounded_auto` |
|---|---|---|---|---|
| File enumeration / classification / cursor `Context-Captured` upsert (steps 1, 3) | Tier 2 (read + route to staging; file-router HIGH-confidence auto-route is already Tier 2) | inbox INERT — nothing fires | execute (classify + record) | execute |
| Transcript Register TR-### write, `Context-Structured` upsert (step 5) | Tier 2 (Document Tier 2 operational tracker, in `cascade_scope`) | nothing | propose (surface; held) | AUTO-WRITE (in scope) |
| PPM triage analysis + follow-up tags (steps 4, 6) | Tier 1 (analytical output; drafts) | nothing | draft + surface | draft + surface (Tier-1-capped) |
| Tracker write → `Context-Decided`, Document Tier 2 item, in `cascade_scope` (steps 10-12) | Tier 2 (Bounded Auto) | nothing | propose | AUTO-WRITE |
| RAID / Document-Tier-1 stakeholder write (RAID, FDD, Project Plan) | Tier 1, irreducible (never auto) | nothing | draft + surface (HELD) | draft + surface (HELD — never auto) |
| Orphan-stall escalation string (step 15) | Tier 1 (surface for operator) | step 15 still flags (operator-cadence, not dial-gated) | surface | surface |

At `automation_level: recommend`, a sweep run produces **zero Tier-1 mutations** (no RAID / stakeholder
write executes — they are drafted + surfaced) AND **≥1 surfaced draft** (the PPM triage / tracker-update
proposals). At `bounded_auto`, Tier-2 tracker writes inside `cascade_scope` (the TR-### register, the
Daily-Status carry-forward) MAY execute; the irreducible Tier-0 set + the Tier-1 RAID / stakeholder
writes NEVER unlock. At `off` the inbox is INERT (nothing fires; the orphan sweep still flags
accumulation, step 15 being operator-cadence, not dial-gated).

**Irreducible floor (cross-reference the canonical set).** The dial cannot raise the
`core/specs/autonomy-tiers.md` §Irreducible Human Tasks set off the operator gate at any level
(financial / account-creation / security-permission / Stage 9 GO / Stage 12 Execute / governance-file
mod / cross-domain bridge / destructive-outside-workspace). The four-name gloss in the parent story
(governance / financial / security / RAID-close) maps onto the canonical set — governance, financial,
and security are named members, and RAID-close is a Document Tier 1 stakeholder-facing write (RAID
"never auto-closes"). The sweep **cross-references the canonical set**, never authoring a parallel
list (the duplicate-source discipline — a parallel list is a drift target).

**Cooperative until the C5 enforcement hook.** The clamp is **cooperative / soft** until the C5
PreToolUse autonomy-ceiling hook registers in `core/settings.json.template` — the same release, the
C0 soft→hard intra-release boundary. Until then the sweep self-limits (reads `automation_level`,
declines over-ceiling execution); after C5 the ceiling is hard-enforced. This is a documented
cooperative-window limitation, NOT "advisory indefinitely" — the sweep's correctness does not depend
on C5 (it self-limits); C5 adds the hard backstop.

## 7. State transition + Document-Tier gating (the safety clamp, restated per-transition)
The cursor writes `Context-Captured` → `Context-Structured` (steps 1-5); the triage steps advance
toward `Context-Reviewed` (step 6) and, via the tracker steps, `Context-Decided` (steps 10-12). Each
mutating transition is Document-Tier-gated by §6:
- **`Context-Captured` → `Context-Structured`** (classify + register, Tier 2 / Document Tier 2): at
  `recommend` the register write is **proposed** (surfaced, held); at `bounded_auto` in `cascade_scope`
  it **auto-writes**; at `off` nothing fires.
- **`Context-Structured` → `Context-Reviewed`** (PPM triage + tags, Tier 1 analytical): **draft +
  surface** at every level (Tier-1-capped) — the analysis is produced, the downstream write is held.
- **`Context-Reviewed` → `Context-Decided`** (tracker write): Document Tier 2 in `cascade_scope` may
  **auto-write** at `bounded_auto`; a Document Tier 1 / RAID / stakeholder item is **HELD as a
  proposal** at every level, never auto-executed.

The fixture: at `recommend`, the register / triage / tracker proposals are surfaced (≥1 draft) while
zero Tier-1 RAID / stakeholder writes execute — both behaviors fall straight out of the `min()` clamp
+ the Document-Tier gate.

## 8. Egress + ingest channel (the governed-MCP invariant)
Ingestion uses the **governed MCP channel**, NOT Bash / WebFetch. `core/hooks/block-egress.sh`
matches only the Bash and WebFetch tools; the `mcp__*` ingest read tools are not in its matcher scope
and are the sanctioned channel. C2 reads the inbox (a local directory) and the synced files via the
governed surface; it writes only LOCAL trackers / the cursor / the run-log. C2 issues no `mcp__*`
write verb against any external system — so the MCP write-gate (`block-mcp-writes.sh`) is orthogonal
to it. This is the same governed-ingest constraint C1 and the C3 sweep confirmed.

## 9. Scheduler surface + thin-bootstrap registration

> **Who performs the registration, and where the step is written down.** The registration
> below is **operator-performed**, and its documented home is the activation subsection of
> `docs/INSTALL.md` § 3 — which names this section as the source of the bootstrap prompt,
> states the cadence and notification settings, and states the reversal. No installer,
> deploy or update script performs it, and none can: `mcp__scheduled-tasks` is an
> agent-runtime surface, and every one of those scripts is bash, which has no path to it.
> This is not a gap awaiting automation. It matches the precedent the platform already set
> for the `platform-health` sentinels — sentinel registration is an operator-instance build
> step, not committed corpus, because a registration carries an instance-local path and is
> not portable; the tracked document states the policy and the instance owns the
> registration. What install DOES perform is the directory provisioning (see C1 §1): the
> run-log directory named in §5 exists on any workspace that has run the update path, and on
> any workspace whose install ran against a **default-located** operator-instance family, so
> this sweep has somewhere to write from its first run. **The installer limb is conditional
> and the condition is load-bearing:** install provisions at `${WORKSPACE_ROOT}`-relative
> literals rather than through the resolver, so on a **relocated** instance family a fresh
> install writes to the default path while the sweep reads the relocated one. The update path
> back-fills at the resolved location and closes the gap. C1 §1 records the mechanism and why
> the installer behaves that way.
- **Scheduler:** C2 registers a scheduled task named `ambient-intake-sweep` on the platform's
  existing `mcp__scheduled-tasks` surface — the same agent-runtime scheduler the operator.toml
  `[adapters] ai_tool` designates, and the SAME mechanism the two `platform-health-*` scheduled tasks
  use. C2 introduces no new scheduler primitive (NOT a new cron daemon). Properties inherited from
  the platform-health precedent verbatim:
  - **Registration:** a `mcp__scheduled-tasks` task named `ambient-intake-sweep` carrying the cadence
    + a prompt that spawns a session invoking the sweep.
  - **Cron + timezone:** a cron-expression cadence evaluated in the operator's LOCAL timezone (the
    platform-health split: LOCAL schedule, UTC for any date-stamped output — do not unify). Default
    once-daily, aligned to the daily-processing rhythm, at an early-morning local hour so the digest
    the C4 heartbeat renders is ready for the AM status. The cadence is a registration parameter,
    operator-configurable via the task's cron expression — not hardcoded in a tracked file.
  - **Notification:** `notifyOnCompletion` per-run (not conditional) — every run pings + emits its
    run-record, which is the anti-silent-failure guarantee (§5).
  - **Non-git state:** the registration is install-root MCP state, NOT a tracked repo file —
    recorded as a Stage 12 deploy-log line item; rollback is deregistration (`enabled:false` or task
    delete), NOT `git revert`. (Mirrors the platform-health registrations.)
  - **App-open caveat:** scheduled tasks run only while the app is open (deferred-to-launch otherwise)
    — a documented operational property, not a defect.
- **Thin-bootstrap prompt (the registration is a delegator, not a contract copy):** the scheduled
  task's `prompt` is a THIN BOOTSTRAP that delegates to THIS tracked spec — it does NOT inline the
  sweep contract. The full sweep behavior lives here (§1-§8); the registration only points at it, so
  the registration cannot drift away from the tracked source. Bootstrap shape (illustrative):
  > "Run the Path-A intake sweep per `core/standards/c2-intake-sweep-path-a.md`: enumerate the C1
  > inbox, skip files already at Context-Structured per the cursor, drive Daily-Processing-Cycle
  > intake steps 1-6 + 15 clamped to `automation_level`, emit mechanism-numbered stall escalations,
  > and append the run-record. Governed-MCP ingest + local write only."
- **Re-registration deploy step:** because the bootstrap references the spec rather than copying it,
  the bootstrap text stays small and stable — but any change to the bootstrap wording or the spec
  path MUST be followed by re-registering the scheduled task so the delegator stays in sync. The
  deploy / close checklist carries an explicit **"re-register the `ambient-intake-sweep` scheduled
  task"** step for this reason (alongside the Path-B `external-sync-path-b` re-registration); it runs
  at Stage 12 deploy and is a deregistration target at rollback.

## 10. Autonomy Tier declaration
The sweep declares its Autonomy Tier per `core/specs/autonomy-tiers.md`:
- **The sweep itself runs under standing authorization — Autonomy Tier 3, BOUNDED BY THE DIAL.**
  Standing authorization = the scheduled-task registration (a framework-granted, operator-installed
  cadence) — the Tier-3 policy-level-authorization criterion (the operator gates only at
  framework-level checkpoints, not per-action within the framework). The dial is the bound: the sweep
  runs autonomously *on schedule*, but each action it emits is independently tier-checked.
- **Per-action descent to Tier 1 outside the ceiling.** Per the autonomy-tiers boundary conditions
  (a Tier-3/2 action outside its declared scope automatically descends), any sweep action above
  `effective = min(automation_level, per-action max)` **descends to Tier 1** — drafted + surfaced for
  approval, not executed. At `recommend`, that is every mutating action (the zero-Tier-1-writes
  result).
- **The Tier-0 irreducible set is NEVER executed by the sweep**, regardless of the dial or the
  standing authorization (the autonomy-tiers §Irreducible Human Tasks set). The sweep cross-references
  the canonical set (§6); RAID-close + governance-file + financial + security + the rest are
  permanently held. "Tier collapse" — a scheduled actor silently executing an irreducible task — is
  the anti-pattern this declaration prevents.
- This composes the **per-action** classification (autonomy-tiers: classification is per-action, not
  per-skill) with the dial: the *skill* is a Tier-3 scheduled actor, but it *emits* Tier-1 drafts,
  Tier-2 in-scope writes, and never Tier-0 — the clamp is the per-action arbiter.

## Framework Reference
This spec consumes the Context Lifecycle Model (`core/disciplines/context-lifecycle-model.md`): it
IS the daily-sweep automation the §6 forward contract and the §8 Forward-citation row anticipate. It
drives the `Context-Captured` → `Context-Structured` transition (the file-router classify-and-register
mechanism) over the C1 inbox, and advances toward `Context-Reviewed` / `Context-Decided` via the PPM
Triage and Tracker Manager mechanisms — all clamped to `[automation].automation_level`. It consumes
the §4 stall thresholds and emits §5-mechanism-numbered stall escalations (the Unassigned-Escalation
step-2 surface, the Orphan-Detection step-15 surface, and the Tracker-Manager step-surface for tagged
items). It changes no §2 vocabulary, §4 threshold, or §5 mechanism — §8 consumer-registration is
Issue-exempt per §9.
