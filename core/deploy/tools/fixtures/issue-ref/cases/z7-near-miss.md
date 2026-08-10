Specificity fixture Z-7 — near-miss tokens the tokenizer must not widen to.

Every construct below sits ABOVE the reference block, so any one of them
tokenizing as a reference would flag this file. A zero here is what pins the
tokenizer's width.

- The legacy prefix with no digits after its hyphen: @@IMP@@- and nothing more.
- A bare hash with no digits after it: # followed by a space.
- A shell array length: ${#arr[@]}.
- Heading markers used as prose mid-sentence: ### and ####.
- A hash bound to letters rather than digits: #alpha, #beta.

DELIBERATELY EXCLUDED from this class, and named rather than dropped: a URL
fragment whose hash is immediately followed by digits. The shipped tokenizer DOES
extract that number — it matches a hash followed by digits wherever it appears,
including inside a URL. That is current behaviour, not a defect, and asserting a
zero on it here would be asserting a behaviour change this extraction is
forbidden to make. It belongs in a follow-up that is allowed to change the rule,
not in the fixture suite whose whole purpose is proving the rule unchanged.

## Issue References

- Nothing here.
