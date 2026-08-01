# Fixture fx-substr — a substring near-miss. Expect FINDINGS (2).

`--neutlnx` is declared in both blocks where `--neutln` is consumed. A matcher that tests by
prefix, by substring, or with a whitespace assumption around the colon reads this as
satisfied and returns a false CLEAN. Note also that every declaration here is written with NO
space after the colon (`--neut:#5b6169`) — the exact shape that produced a false alarm for a
whitespace-assuming pattern elsewhere. Both forms must parse identically.

TH-2 passes on this file (the key sets are equal across blocks), so this case also proves the
two invariants are independent in the second direction.

```svg
<svg viewBox="0 0 200 40" xmlns="http://www.w3.org/2000/svg">
<style>
  svg{
    --ok:#1f7a4d; --okbg:#e6f4ec; --okln:#9ed3b6;
    --warn:#a8600a; --warnbg:#fbeeda; --warnln:#e6c187;
    --neut:#5b6169; --neutbg:#eef1f5; --neutlnx:#c9ced6;
  }
  @media (prefers-color-scheme: dark){svg{
    --ok:#5fcf98; --okbg:#173026; --okln:#2f5c46;
    --warn:#e6a94e; --warnbg:#332616; --warnln:#5e4a26;
    --neut:#9aa3ad; --neutbg:#24282d; --neutlnx:#3a4048;
  }}
</style>
<rect x="0" y="0" width="12" height="12" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
<text x="20" y="11" fill="var(--{{S}})">STATUS</text>
<!-- subst: {{S}} = ok|warn|neut ; ok on PASS, warn on FINDING, neut on NOT RUN -->
</svg>
```
