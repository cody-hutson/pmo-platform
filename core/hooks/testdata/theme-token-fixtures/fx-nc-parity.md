# Fixture fx-nc-parity — a parity break with no consumer. Expect CLEAN.

`--spare` is declared in the light block only and is never consumed anywhere. That is a TH-2
violation (the two blocks no longer declare the same key set) and NOT a TH-3 violation (no
consumer is left undeclared). TH-3 must report CLEAN here.

This is the specificity arm in its sharpest form: an input that is genuinely defective under a
NEIGHBOURING invariant. A check that flags it has absorbed TH-2's domain instead of owning its
own, and the two rows in the register would no longer be independent.

```svg
<svg viewBox="0 0 200 40" xmlns="http://www.w3.org/2000/svg">
<style>
  svg{
    --ok:#1f7a4d; --okbg:#e6f4ec; --okln:#9ed3b6;
    --warn:#a8600a; --warnbg:#fbeeda; --warnln:#e6c187;
    --neut:#5b6169; --neutbg:#eef1f5; --neutln:#c9ced6;
    --spare:#ffffff;
  }
  @media (prefers-color-scheme: dark){svg{
    --ok:#5fcf98; --okbg:#173026; --okln:#2f5c46;
    --warn:#e6a94e; --warnbg:#332616; --warnln:#5e4a26;
    --neut:#9aa3ad; --neutbg:#24282d; --neutln:#3a4048;
  }}
</style>
<rect x="0" y="0" width="12" height="12" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
<text x="20" y="11" fill="var(--{{S}})">STATUS</text>
<!-- subst: {{S}} = ok|warn|neut ; ok on PASS, warn on FINDING, neut on NOT RUN -->
</svg>
```
