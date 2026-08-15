# fcm-no-matrix — fail-closed arm for the fcm-delivery family

A plan with no File Change Matrix heading at all. "No matrix" and "no declared ADDs"
are indistinguishable to any reader, so the gate must refuse to distinguish them: the
verdict is ERROR, never a PASS and never silence. This is the single most important
fail-closed arm, because an absent matrix is exactly where a missing obligation would
be most invisible.

Expected: `ERROR — fcm-section-absent`, exit 3.

## Verification Plan

The family label below deliberately carries no issue number. This fixture asserts
only that an absent File Change Matrix is a fail-closed ERROR; the label is inert
scaffolding that gives the run one check to execute, and nothing here reads it. A
bare `#N` in this position would be a resolving reference sitting outside any
designated reference block — a second, unrelated finding on a fixture whose whole
subject is matrix delivery.

**Synthetic issue family — nothing to see**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `test -f release/tools/verify-release-plan.sh` | exists |
