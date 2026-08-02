# Fixture fx-prose-only — prose about the mechanism, no themed artifact. Expect INDETERMINATE.

A document that DESCRIBES theme tokens without carrying one. It states that every fill
resolves through `var(--token)`, and that each `--token:` must appear once per theme block —
the same two strings a themed artifact carries, in a file with no `<style>` element at all.

Under whole-file scope those two prose strings pair with each other and the file passes as
though it had been checked. Under region scope there is nothing to check, and the honest
answer is INDETERMINATE, not CLEAN. A fenced block is present below so the failure is
attributed to the absent `<style>` region specifically, not to an empty subject.

```bash
grep -oE 'var\(--[a-z-]+\)' "$1" | sort -u
```
