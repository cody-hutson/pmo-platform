# Fixture fx-nomanifest — an unmanifested placeholder. Expect INDETERMINATE.

Identical to `fx-clean.md` except the `subst:` manifest is reverted to the legacy free-prose
form. The check cannot know that `{{S}}` ranges over ok / warn / neut, so it cannot resolve
three of its consumers and its denominator is incomplete.

The whole point of this case is what the check must NOT do. Skipping the unresolvable
placeholder would print `0 undeclared consumer(s)` and exit 0 — a false CLEAN over a partial
population, which is the sample-presented-as-population shape and precisely the miss that
produced the original defect. The verdict is INDETERMINATE, exit 2.

Note that a prose-inference strategy would fare worse than skipping: the comment's right-hand
side yields `{ok, on, warn, neut}` — but also `PASS`, `FINDING`, `NOT`, `RUN` for anything
matching on word shape. An instrument that cannot separate a token value from an English word
over-matches, and an over-matching probe is unusable rather than lenient.

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
<!-- {{S}} = ok on PASS, warn on FINDING, neut on NOT RUN -->
</svg>
```
