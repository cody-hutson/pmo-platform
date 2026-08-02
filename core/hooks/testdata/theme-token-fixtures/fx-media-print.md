# Fixture fx-media-print — an ordinary print stylesheet. Expect CLEAN.

A `@media print` block is ordinary CSS, not a theme. It carries no colour-scheme context, so
it must NOT register as a third theme block: every block in the theme list is required to
declare EVERY consumed token, and a print stylesheet legitimately overrides only a few. Before
the colour-scheme narrowing this file keyed a block labelled `media:@media print` and reported
one MISSING row per token the print block did not restate — a required gate turned red on
correct content.

The single declaration inside the print block is still COUNTED and PRINTED as OUT-OF-ROOT, so
narrowing the rule suppresses a false finding without silently dropping a declaration.

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
  /* Ordinary media query, not a colour-scheme context. Overrides one token for print. */
  @media print{svg{--neutbg:#ffffff}}
</style>
<rect x="0" y="0" width="12" height="12" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
<text x="20" y="11" fill="var(--{{S}})">STATUS</text>
<!-- subst: {{S}} = ok|warn|neut ; ok on PASS, warn on FINDING, neut on NOT RUN -->
</svg>
```
