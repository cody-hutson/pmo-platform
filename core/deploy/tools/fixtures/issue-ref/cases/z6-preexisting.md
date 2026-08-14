Specificity fixture Z-6 — a pre-existing failing reference, untouched.

The line below was already present at the base commit and this change does not
touch it. Delta mode must not re-flag it: the gate scans the added-line delta so
that a file edited for unrelated reasons does not drag its whole history into
scope. Path mode SEES it, and must flag it — that difference is the point.

- @@REF@@909400 — present at BASE, unchanged by this delta.

An unrelated line added by this change, carrying no reference of any kind.
