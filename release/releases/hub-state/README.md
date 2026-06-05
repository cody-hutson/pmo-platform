# release/releases/hub-state/ — hub session continuity substrate (schema templates)

This directory holds **schema templates** for per-release hub-state. The runtime instance is operator-local — git-tracking the runtime would create dozens of micro-commits per release for state that has no cross-operator readership.

## What ships here (CUSTOMIZABLE-PUBLIC — tracked)

| Template | Surface | Schema spec |
|---|---|---|
| [`pending-approvals.md.template`](pending-approvals.md.template) | Surface A — queued-approval substrate (decisions awaiting operator) | [`../../../core/standards/hub-session-continuity.md`](../../../core/standards/hub-session-continuity.md) § 3.1 |
| [`action-items.md.template`](action-items.md.template) | Action-item tracking (durable commitments to execute at a future routing point) | [`../../../core/standards/hub-action-tracking.md`](../../../core/standards/hub-action-tracking.md) § 2 |
| [`sessions.md.template`](sessions.md.template) | Surface C (OPTIONAL) — session lineage with composite session-IDs | [`../../../core/standards/hub-session-continuity.md`](../../../core/standards/hub-session-continuity.md) § 3.3 |

Surface B (the hub-decisions / pipeline-event-log) is not represented here — it lives at the operator-instance evals path and reuses the existing `pipeline-event-log.md` schema. See [`../../../core/standards/hub-session-continuity.md`](../../../core/standards/hub-session-continuity.md) § 3.2.

## Runtime instance (OPERATOR-INSTANCE — NOT tracked)

The hub writes runtime instances to `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/` — the operator-local path that resolves at install time per the operator-instance path convention. Per-release `vX.Y/` subdirectories are created lazily by the hub on first surface emit; hubs do NOT pre-create empty per-release directories.

```
<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/
├── pending-approvals.md    # Surface A runtime instance
├── action-items.md         # Action-item runtime instance
└── sessions.md             # Surface C runtime instance (OPTIONAL)
```

## Authoring contract

- **Authored by:** Hub at every routing decision (Procedure 0b in [`../../references/how-to/hub-spoke-bridge.md`](../../references/how-to/hub-spoke-bridge.md) and every subsequent action-item emit or approval enqueue)
- **First emit:** Hub copies the template from this directory to `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/<surface>.md`, substitutes the milestone slug into the frontmatter, and appends the first row
- **Read by:** Hub on session resume (Resume Procedure Steps 7-8 in `hub-session-continuity.md`); operator (manually inspecting pending approvals)

## Classification

**CUSTOMIZABLE-PUBLIC** for the templates in this directory + **OPERATOR-INSTANCE** for the runtime instance, per [`../../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md). Rationale per the taxonomy § 4.3 worked example: hub-state mutates on every routing decision (typically 10–50+ writes per release); tracking the runtime instance produces release-branch noise with no cross-operator readership benefit. Audit trail is preserved via `pipeline-event-log.md` (also operator-instance) plus GitHub Issue comments carrying the Decision Briefing context.

## Cleanup

Runtime `vX.Y/` directories at the operator-instance path are NOT deleted post-release — they serve as a local release-close audit artifact. Workspace-wide cleanup is handled by [`../../tools/cleanup-orphan-state.sh`](../../tools/cleanup-orphan-state.sh) per Procedure 7 Step 6 in the bridge.
