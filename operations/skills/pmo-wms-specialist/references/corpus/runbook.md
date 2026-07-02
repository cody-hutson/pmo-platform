# WMS Operational Runbook (ILLUSTRATIVE — pilot corpus)

> Illustrative operational runbook for a generic warehouse management system. Not a real vendor
> product. v1.0 · 2026-07-01.

## 1. Procedures

### 1.1 Release a wave
1. Open the planned wave.
2. Confirm the wave is before its `cutoff_time`. If past cutoff, obtain a supervisor override
   (required by the stated constraint).
3. Release the wave. The WMS allocates inventory and generates pick tasks.

### 1.2 Resolve a short-pick
1. A short-pick is recorded when a pick task cannot be completed in full.
2. If replenishment is **enabled** and reserve stock exists, a replenishment task refills the pick
   location; re-pick the line after replenishment completes.
3. If replenishment is **disabled** or no reserve stock exists, escalate the short to inventory
   control (out of WMS scope in this corpus).

### 1.3 Trigger replenishment manually
1. Identify the pick location below min.
2. Generate a manual replenishment task to refill up to max from a reserve location.

## 2. Integration edges (as documented)

| Direction | System | What crosses the edge (as documented) |
|---|---|---|
| Upstream | **Order source** | Orders to fulfill are received from the order source; the WMS does not originate orders. |
| Downstream | **Carrier integration** | Shipment confirmation notifies the carrier integration for label/manifest. |
| Reference | **Inventory master** | On-hand adjustments reconcile to the inventory master of record. |

> The corpus documents *which* systems connect and *what* crosses each edge at this level. It does
> **not** document the field-level API schemas of these integrations (a known corpus gap — see the
> manifest).

## 3. Escalation boundary

Anything the WMS corpus does not cover — labor management, cycle counting, yard/dock scheduling,
API field schemas — is **out of the WMS Specialist's grounded scope**. The Specialist names the gap
and routes (add the doc, or ask the vendor) rather than answering from generic knowledge.
