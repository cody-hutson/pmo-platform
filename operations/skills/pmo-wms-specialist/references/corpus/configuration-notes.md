# WMS Configuration Notes (ILLUSTRATIVE — pilot corpus)

> Illustrative configuration reference for a generic warehouse management system. Not a real vendor
> product. v1.0 · 2026-07-01.

## 1. Allocation strategy

The WMS supports two documented allocation strategies, set per warehouse:

| Strategy | Behavior (as documented) |
|---|---|
| **FEFO** (first-expiry-first-out) | Allocates the pick-location stock with the earliest expiry date first. Default for lot-controlled items. |
| **FIFO** (first-in-first-out) | Allocates the oldest received stock first. Default for non-lot items. |

> Only FEFO and FIFO are documented. No other allocation strategy (e.g. zone-priority, nearest-location)
> is defined in this corpus.

## 2. Replenishment trigger

Replenishment is **min/max** based:
- A pick location has a configured **min** and **max**.
- When on-hand at the pick location drops **at or below min**, a replenishment task is generated to
  refill it **up to max**.
- Replenishment can be globally **enabled** or **disabled** per warehouse. When disabled, a
  short-allocated line stays short (no replenishment task is created).

## 3. Wave-release policy

- Waves release **manually** by default (a supervisor releases a planned wave).
- An optional **auto-release** can release planned waves on a schedule, but **not** after a wave's
  `cutoff_time`.
- A wave released after `cutoff_time` requires a **supervisor override** (documented as an explicit
  constraint).

## 4. Stated constraints (invariants)

1. A wave cannot be released after its `cutoff_time` without a supervisor override.
2. A location at `capacity` is not eligible for putaway until space frees.
3. Replenishment refills up to **max**, never above.
4. When replenishment is disabled, short-allocated lines are not auto-recovered.

(These four are the only invariants this corpus states. A constraint not listed here is not
documented.)
