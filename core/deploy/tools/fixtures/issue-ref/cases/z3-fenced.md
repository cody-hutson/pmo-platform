Specificity fixture Z-3 — failing references inside a fenced code block.

Fence state is tracked as the scan walks lines, so a fence-toggle defect is
invisible without a fixture that opens a fence, fails inside it, and closes it
again. Everything outside the fence in this file is clean.

## Issue References

- Nothing outside the fence.

```text
@@REF@@909300 — inside the fence; the fence must swallow it.
@@IMP@@-013 — also inside the fence, and also swallowed.
```

The fence is closed above, and the line you are reading carries no reference.
