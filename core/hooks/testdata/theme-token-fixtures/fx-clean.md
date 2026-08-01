# Fixture fx-clean — a well-formed themed artifact. Expect CLEAN.

This prose deliberately mentions `var(--token)` and `--token:` OUTSIDE the fence. Whole-file
scope would pair them with each other and pass coincidentally; the subject region is the
fenced block only, so the check never sees them. That is the wrong-scope shape designed out
rather than tested for.

```svg
<svg viewBox="0 0 200 40" xmlns="http://www.w3.org/2000/svg">
<style>
  svg{
    --ok:#1f7a4d; --okbg:#e6f4ec; --okln:#9ed3b6;
    --warn:#a8600a; --warnbg:#fbeeda; --warnln:#e6c187;
    --neut:#5b6169; --neutbg:#eef1f5; --neutln:#c9ced6;
  }
  @media (prefers-color-scheme: dark){svg{
    --ok:#5fcf98; --okbg:#173026; --okln:#2f5c46;
    --warn:#e6a94e; --warnbg:#332616; --warnln:#5e4a26;
    --neut:#9aa3ad; --neutbg:#24282d; --neutln:#3a4048;
  }}
  /* A component-local declaration. It must NOT register as a theme block — if it did,
     every global token would read as missing from it. Counted as OUT-OF-ROOT instead. */
  .card{--pad:4px}
</style>
<rect x="0" y="0" width="12" height="12" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
<text x="20" y="11" fill="var(--{{S}})">STATUS</text>
<!-- subst: {{S}} = ok|warn|neut ; ok on PASS, warn on FINDING, neut on NOT RUN -->
</svg>
```
