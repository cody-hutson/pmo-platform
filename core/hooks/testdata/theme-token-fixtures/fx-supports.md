# Fixture fx-supports — declarations behind a capability guard. Expect CLEAN.

`@supports` is a capability guard, not a context switch: a root-scope block inside one is
still the colour-scheme context it already sat in. Before the colour-scheme narrowing the
enclosing at-rule was treated as a non-theme wrapper, so the two tokens declared here were
misfiled OUT-OF-ROOT, went missing from the `default` theme block, and their consumers read
as undeclared — two findings on correct, ordinary CSS.

This is the inverse of the `@media print` case and must be held separately: there the at-rule
had to STOP creating a block, here it has to stop DESTROYING one.

```svg
<svg viewBox="0 0 200 40" xmlns="http://www.w3.org/2000/svg">
<style>
  svg{
    --ok:#1f7a4d; --okbg:#e6f4ec; --okln:#9ed3b6;
    --warn:#a8600a; --warnbg:#fbeeda; --warnln:#e6c187;
    --neutbg:#eef1f5;
  }
  @supports (color: color-mix(in srgb, red, blue)){svg{
    --neut:#5b6169; --neutln:#c9ced6;
  }}
  @media (prefers-color-scheme: dark){svg{
    --ok:#5fcf98; --okbg:#173026; --okln:#2f5c46;
    --warn:#e6a94e; --warnbg:#332616; --warnln:#5e4a26;
    --neut:#9aa3ad; --neutbg:#24282d; --neutln:#3a4048;
  }}
  .card{--pad:4px}
</style>
<rect x="0" y="0" width="12" height="12" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
<text x="20" y="11" fill="var(--{{S}})">STATUS</text>
<!-- subst: {{S}} = ok|warn|neut ; ok on PASS, warn on FINDING, neut on NOT RUN -->
</svg>
```
