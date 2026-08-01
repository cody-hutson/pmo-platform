# Fixture fx-unbounded — a declared-uncoverable domain. Expect CLEAN, with the boundary printed.

`{{Z}}` names a token whose value is computed from run-time data, so its domain is genuinely
unbounded at authoring time. It declares `= *`. Its consumer is not resolved and not asserted
against — but it IS counted, bucketed as UNBOUNDED / declared-uncoverable, and printed on
every run, and the verdict line names the count.

That is what keeps the escape hatch honest. An author cannot quietly disable the check by
declaring everything open, because the number is on the face of the record and a reviewer
reads it in the same glance as the denominator.

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
</style>
<rect x="0" y="0" width="12" height="12" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
<text x="20" y="11" fill="var(--{{S}})">STATUS</text>
<circle cx="180" cy="20" r="5" fill="var(--{{Z}}tone)"/>
<!-- subst: {{S}} = ok|warn|neut ; ok on PASS, warn on FINDING, neut on NOT RUN -->
<!-- subst: {{Z}} = * ; the palette key is computed from run-time data; unbounded by construction -->
</svg>
```
