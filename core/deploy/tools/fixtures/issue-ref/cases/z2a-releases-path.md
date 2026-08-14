Specificity fixture Z-2a — the release-tracking-surface path exemption.

This is the exemption arm the rules register omitted for as long as it has
shipped, which makes it the arm most likely to be silently lost in a rewrite.
The body fails on purpose; the exemption is by PATH, not by any marker in the
file, so nothing here can rescue it except the exemption itself.

- @@REF@@909600 — does not resolve.
- @@IMP@@-011 — the deprecated legacy identifier.
