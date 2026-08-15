# fcm-no-matrix — fail-closed arm for the fcm-delivery family

A plan with no File Change Matrix heading at all. "No matrix" and "no declared ADDs"
are indistinguishable to any reader, so the gate must refuse to distinguish them: the
verdict is ERROR, never a PASS and never silence. This is the single most important
fail-closed arm, because an absent matrix is exactly where a missing obligation would
be most invisible.

Expected: `ERROR — fcm-section-absent`, exit 3.

## Verification Plan

**#999 — nothing to see**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `test -f release/tools/verify-release-plan.sh` | exists |
