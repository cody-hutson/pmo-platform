# Fixture fx-defect — the original defect, reproduced. Expect FINDINGS (4).

Byte-identical to `fx-clean.md` except that `--neutln` and `--neut` are removed from BOTH
theme blocks, leaving only `--neutbg`. This is the mutation form of the sensitivity arm: the
exact shape that made a `NOT RUN` row illegible in both light and dark, on the
graceful-degradation path.

Both incumbent invariants pass on this file, which is the gap TH-3 closes:
TH-1 (no literal hex outside the style block) passes — every hex is inside it.
TH-2 (light and dark declare the same key set) passes — a token absent from BOTH blocks
satisfies parity trivially.

```svg
<svg viewBox="0 0 200 40" xmlns="http://www.w3.org/2000/svg">
<style>
  svg{
    --ok:#1f7a4d; --okbg:#e6f4ec; --okln:#9ed3b6;
    --warn:#a8600a; --warnbg:#fbeeda; --warnln:#e6c187;
    --neutbg:#eef1f5;
  }
  @media (prefers-color-scheme: dark){svg{
    --ok:#5fcf98; --okbg:#173026; --okln:#2f5c46;
    --warn:#e6a94e; --warnbg:#332616; --warnln:#5e4a26;
    --neutbg:#24282d;
  }}
  .card{--pad:4px}
</style>
<rect x="0" y="0" width="12" height="12" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
<text x="20" y="11" fill="var(--{{S}})">STATUS</text>
<!-- subst: {{S}} = ok|warn|neut ; ok on PASS, warn on FINDING, neut on NOT RUN -->
</svg>
```
