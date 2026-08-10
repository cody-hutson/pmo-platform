Sensitivity fixture S-3 — the number is a pull request, not an issue.

The issues endpoint returns 200 for a pull-request number, so the payload has to
be branched on the pull-request field. Exit-code branching alone passes this.

## Issue References

- @@REF@@909003 — a pull-request number wearing an issue number's shape.
