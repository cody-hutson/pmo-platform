# WMS Module Reference (ILLUSTRATIVE — pilot corpus)

> Illustrative reference for a generic warehouse management system, authored to validate the
> System-Specialist template. Not a real vendor product. v1.0 · 2026-07-01.

## 1. Entities

| Entity | Definition | Key fields (as documented) |
|---|---|---|
| **Item** | A stock-keeping unit the warehouse handles. | `item_id`, `uom` (each/case/pallet), `hazmat_flag` |
| **Location** | A physical slot in the warehouse. | `location_id`, `zone`, `type` (pick / reserve / staging), `capacity` |
| **Wave** | A batch of order lines released together for picking. | `wave_id`, `status` (Planned / Released / In-Progress / Complete), `cutoff_time` |
| **Order** | A customer or transfer order to fulfill. | `order_id`, `priority`, `ship_by` |
| **Task** | A unit of directed work (pick, putaway, replenish). | `task_id`, `type`, `status` (Open / Assigned / Complete), `assigned_to` |

## 2. Core workflows

### 2.1 Receiving and putaway
Inbound stock is received against an expected receipt, then **putaway** tasks direct it to a reserve
or pick location by the configured putaway rule. A location at `capacity` is skipped for the next
eligible location.

### 2.2 Wave planning
Order lines are grouped into a **wave**. A wave moves `Planned → Released → In-Progress → Complete`.
A wave cannot be released after its `cutoff_time` without a supervisor override.

### 2.3 Allocation
On wave release, the WMS **allocates** inventory to each order line — reserving stock in a pick
location. If no pick-location stock is available, the line is marked **short** and (if replenishment
is enabled) a replenishment task is generated.

### 2.4 Picking
Released waves generate **pick tasks**. A picker is directed location-by-location. A pick that cannot
be completed in full is recorded as a **short-pick** against the task.

### 2.5 Replenishment
When a pick location falls below its **min** threshold, a **replenishment task** moves stock from a
reserve location to the pick location. (The trigger threshold is configurable — see the configuration
notes.)

### 2.6 Shipping
Completed picks are staged and confirmed for shipment. Shipment confirmation notifies the downstream
carrier integration.

## 3. Status vocabularies (as documented)

- **Wave status:** `Planned`, `Released`, `In-Progress`, `Complete`.
- **Task status:** `Open`, `Assigned`, `Complete`.

(No other statuses are defined in this corpus. A behavior, field, or status not listed here is not
documented — it must not be asserted as WMS behavior.)
