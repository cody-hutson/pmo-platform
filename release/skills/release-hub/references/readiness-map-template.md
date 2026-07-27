<!-- reference-durability: allow-link -->
# Readiness Map Template (Mode R)

Elaborates Output-Contract requirement 7 in [`../SKILL.md`](../SKILL.md). The SKILL.md is authoritative;
this file is the worked structure, theme mechanism, legend derivation, and literal scaffold.
**The map renders the briefing. It owns no check, computes no value, and decides nothing.**

## 1. What the map is (and is not)

The readiness map is a **runtime output element** — a per-run, transient render of one Mode R emission.
It is **not** a design artifact: it anchors no platform state, it is never refreshed, and **it is never
persisted as a `.svg` file in the repository**. The scaffold lives here, in markdown, fully agent-readable.

**Scope determination vs. the design-artifact standard (on the record, so it is not re-litigated).**
[`design-artifact-standard.md`](../../../../core/standards/design-artifact-standard.md) rejects SVG as a
durable source-of-truth format, on the stated rationale that SVG is file-based and less agent-readable in
source form — git-diffable but not git-readable. **That rejection does not reach this element, and the
reason is scope, not exemption.** That standard governs artifacts which *anchor the current state of the
platform* — durable, stored, refresh-gated diagrams across its named flow classes. A per-milestone
readiness render anchors nothing: it is produced inside one emission, consumed by the operator reading
that emission, and never stored. This design **honors the standard's rationale by construction** rather
than arguing around it: the committed artifact is *this markdown file*, fully agent-readable in source
form, and **no `.svg` file is ever committed** anywhere in the repository. A rendered map that is
persisted to disk is a defect, not a variant.

**Derivation constraint (load-bearing).** The map renders only values already present in the same
emission's text briefing. No token may appear in the map that is absent from the briefing. Where the
two disagree, the **briefing is authoritative and the map is dropped** — never reconciled in the map's
favour.

## 2. Degradation contract

The briefing is the deliverable; the map is a projection. Named non-render conditions and their
prescribed behaviour:

| Condition | Behaviour |
|---|---|
| The emission surface cannot render inline SVG | **Omit the map.** State one line: `Readiness map omitted — <reason>. The briefing above is complete.` |
| An input for one rail row is unavailable (a composed surface is absent) | Render that row **NOT RUN** (neutral tone). Do **not** omit the map. |
| The map would disagree with the briefing | **Omit the map.** Never emit a map that contradicts the briefing. |

An emission with the briefing and no map is **complete**. An emission with the map and no briefing is
**incomplete**.

## 3. Theme mechanism

- One `<style>` element inside the SVG. **Selector is `svg { }`, not `:root { }`** — in a standalone SVG
  document the two are equivalent; when the SVG is inlined into a host document, `:root` would redefine
  generic token names (`--ink`, `--card`, `--panel`, `--line`) on the host page.
- The **light** palette is the default declaration, so a renderer without media-query support still
  produces a legible render.
- `@media (prefers-color-scheme: dark) { svg { … } }` overrides the **identical key set**.
- Every fill and stroke resolves through `var(--token)`.

**Invariants (mechanically checkable):**

| # | Invariant | Check |
|---|---|---|
| TH-1 | No literal hex outside the `<style>` block | `sed '/<style>/,/<\/style>/d' <file> \| grep -coE '#[0-9a-fA-F]{6}'` → `0` |
| TH-2 | Light and dark declare the same key set | each `--token:` appears exactly twice (16 tokens, 2× each) |

## 4. Self-containment predicate

Zero external assets. The verification predicate is the **fetch surface**, not the string `http`:

| # | Probe | Expect |
|---|---|---|
| SC-1 | `grep -cE '<image\|<script\|<foreignObject\|@import\|@font-face\|src=\|href="[^#]\|url\([^#]' <file>` | `0` |
| SC-2 | `grep -oE 'https?://[^"'"'"' )]+' <file> \| grep -v '^http://www\.w3\.org/2000/svg$'` | empty |

**Permitted by construction:** the single `xmlns="http://www.w3.org/2000/svg"` namespace declaration (a
namespace identifier, never dereferenced; the SVG is invalid without it) and same-document fragment
references (`url(#…)`, `href="#…"`). **Fonts are system-stack only** — no `@font-face`, no webfont fetch.

## 5. Accessibility contract (also the text fallback)

`role="img"` + `aria-labelledby` pointing at a `<title>` and a `<desc>`. `<desc>` carries the verdict and
the blocking findings in prose, so a surface that cannot paint still exposes a decision-complete sentence.

## 6. The legend — the Composition Rail

The rail is **both** the per-group roll-up (Output-Contract requirement 7) **and** the legend
(ADR-019 compose-not-absorb traceability). One structure, one enumeration — never two.

**Derivation rule (authoritative).** One rail row per row of the group table in
[`milestone-readiness-checklist.md`](milestone-readiness-checklist.md), **in table order**. Each row
carries: the group number and name **verbatim** from that table's columns 1–2; the group's status; and
the owning skill/spec from that table's column 4, compressed to the skill/spec name. The rail's row
count is the checklist's row count **by construction**.

Each row is wrapped in `<g id="grp-N">`, so the count is gradable: `grep -c 'id="grp-'`.

**Status vocabulary — exactly three, deliberately:**

| Status | Tone | Meaning |
|---|---|---|
| `PASS` | `--ok` | the group produced no finding in this run |
| `FINDING` | `--warn` | the group produced ≥1 finding; the disposition is on the affected issue card |
| `NOT RUN` | neutral (`--line` / `--muted`) | the group could not be composed (absent surface); see SKILL.md portability note |

**A severity ramp is deliberately refused.** Ranking findings by severity is a judgment the briefing does
not render. `--bad` is reserved for the verdict pill, the size-ceiling tick, and an external open
blocker — all values the briefing already states.

The **tone key** (`id="tonekey"`) is a separate 3-swatch strip that defines the tone vocabulary. It is
**not** the legend and is not counted against the per-group entry requirement.

## 7. Glyph → composed source (the traceability table)

Every glyph class and the composed value it copies. Nothing in this table is computed by the map.

| Glyph | Encodes | Sourced to |
|---|---|---|
| Verdict pill | GO / NO-GO | the milestone verdict |
| Banner subtitle | mode · read-only · reversibility tier · confidence | Output-Contract requirement 5 |
| Rail swatch + status word | per-group PASS / FINDING / NOT RUN | the group's finding set this run |
| Rail owner label | owning skill / spec | checklist group table, column 4 |
| Issue-card class token | `C1` / `C2` / `C3` (+ `PT-n`) | checklist § Output schema |
| Issue-card tone | C1/C2 → `--ok`, C3 → `--warn` | the existing GO rule (every requirement C1/C2) |
| Issue-card points | per-issue size | `size:` label → XS1/S2/M4/L8/XL16 |
| Issue-card disposition chip | the finding's disposition | Output-Contract requirement 4 |
| Dashed edge + marker | cross-milestone dependency / leak | checklist group 2 `2c`, composed `release-planner` |
| Gauge bar | bundle total points | sum of member points |
| Gauge band + ceiling tick | 15–25 pt target band, 25 ceiling | `bundle-composition-doctrine` § 3 Step 5 |
| Footer roll-up line | the one-line roll-up | the briefing's roll-up |

## 8. Layout

Two layouts. **Layout B is the default**; Layout A activates only when ≥1 cross-milestone edge exists.

| | Layout A (cross-milestone edge present) | Layout B (no edge) |
|---|---|---|
| Issue panel | `x=24 w=500` | `x=24 w=852` |
| Cross-milestone panel | `x=560 w=316` | omitted; the rail's group-2 row reads `PASS` |

**Height formula:** `height = 300 + 46 * issueCount + 22 * groupCount`.

**Size-gauge scale rule:** `scaleMax = max(40, ceil(total_pts / 10) * 10)`; `px_per_pt = trackWidth /
scaleMax`. The band rect, the ceiling tick, and the actual bar are all positioned by that one map, so
they stay consistent at any bundle size. When members are unsized, render the known subtotal with a
hatched tail and a `+N unsized` label.

## 9. Scaffold

Placeholders are `{{…}}`. `REPEAT` blocks emit one element per data row.

```svg
<svg viewBox="0 0 900 {{HEIGHT}}" xmlns="http://www.w3.org/2000/svg" role="img"
     aria-labelledby="mr-t mr-d"
     font-family="ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif">
<title id="mr-t">Milestone {{MS_REF}} readiness map — {{VERDICT}}</title>
<desc id="mr-d">{{DECISION_COMPLETE_SENTENCE}}</desc>
<style>
  svg{
    --ink:#1a1c1f; --muted:#5b6169; --line:#c9ced6; --panel:#f4f6f9; --panelln:#d5dae2; --card:#ffffff;
    --ok:#1f7a4d; --okbg:#e6f4ec; --okln:#9ed3b6;
    --warn:#a8600a; --warnbg:#fbeeda; --warnln:#e6c187;
    --bad:#b3261e; --badbg:#fbe6e4; --badln:#e8a9a4;
    --neutbg:#eef1f5;
  }
  @media (prefers-color-scheme: dark){svg{
    --ink:#e7eaee; --muted:#9aa3ad; --line:#3a4048; --panel:#1a1d21; --panelln:#333941; --card:#22262b;
    --ok:#5fcf98; --okbg:#173026; --okln:#2f5c46;
    --warn:#e6a94e; --warnbg:#332616; --warnln:#5e4a26;
    --bad:#f08a82; --badbg:#331d1c; --badln:#5e3330;
    --neutbg:#24282d;
  }}
  .mut{fill:var(--muted)} .b{font-weight:700} .sb{font-weight:600}
  text{fill:var(--ink)}
</style>

<!-- 1. BANNER -->
<rect x="0" y="0" width="900" height="56" fill="var(--neutbg)"/>
<text x="24" y="25" class="b" font-size="15">MILESTONE {{MS_REF}} · {{MS_SLUG}}</text>
<text x="24" y="44" class="mut" font-size="12">Mode R readiness gate · read-only · {{TIER}} · {{CONFIDENCE}} confidence</text>
<rect x="{{PILL_X}}" y="13" width="128" height="30" rx="15" fill="var(--{{V}}bg)" stroke="var(--{{V}}ln)"/>
<circle cx="{{PILL_X_PLUS_20}}" cy="28" r="5" fill="var(--{{V}})"/>
<text x="{{PILL_X_PLUS_32}}" y="32" class="b" font-size="14" fill="var(--{{V}})">{{VERDICT}}</text>
<!-- {{V}} = ok on GO, bad on NO-GO -->

<!-- 2. ISSUE PANEL -->
<rect x="24" y="68" width="{{PANEL_W}}" height="{{PANEL_H}}" rx="12" fill="var(--panel)" stroke="var(--panelln)"/>
<text x="42" y="94" class="b" font-size="13">Milestone {{MS_REF}} — as bundled</text>
<text x="42" y="111" class="mut" font-size="11.5">{{N}} issues · {{TOTAL_PTS}} pts · theme: {{THEME}}</text>
<!-- REPEAT per issue, pitch 46, first card y=126 -->
<g>
  <rect x="42" y="{{CARD_Y}}" width="{{CARD_W}}" height="40" rx="8"
        fill="var(--{{T}}bg)" stroke="var(--{{T}}ln)" {{DASH_IF_C3}}/>
  <text x="56" y="{{CARD_Y_PLUS_17}}" class="b" font-size="12">{{ISSUE_REF}} · {{ISSUE_TITLE}}</text>
  <text x="56" y="{{CARD_Y_PLUS_32}}" class="mut" font-size="11">{{SIZE}} · {{CLASS}}{{PT}} · {{DISPOSITION_OR_NOTE}}</text>
  <text x="{{CARD_RIGHT}}" y="{{CARD_Y_PLUS_25}}" text-anchor="end" class="sb" fill="var(--{{T}})">{{PTS}} pts</text>
</g>
<!-- {{T}} = ok when class is C1 or C2; warn when C3. DASH_IF_C3 = stroke-dasharray="5 3" -->

<!-- 3. CROSS-MILESTONE PANEL + EDGE — Layout A only; omit entirely in Layout B -->
<defs>
  <marker id="mr-ah" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7"
          orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="var(--bad)"/></marker>
</defs>
<rect x="560" y="{{XM_Y}}" width="316" height="{{XM_H}}" rx="12" fill="var(--panel)" stroke="var(--panelln)"/>
<text x="578" y="{{XM_Y_PLUS_26}}" class="b" font-size="13">Milestone {{XM_REF}}</text>
<text x="578" y="{{XM_Y_PLUS_43}}" class="mut" font-size="11">{{XM_NOTE}}</text>
<!-- REPEAT per external node, pitch 46 -->
<g>
  <rect x="578" y="{{XN_Y}}" width="280" height="40" rx="8" fill="var(--badbg)" stroke="var(--badln)"/>
  <text x="592" y="{{XN_Y_PLUS_18}}" class="b" font-size="12">{{XN_REF}} · {{XN_TITLE}}</text>
  <text x="592" y="{{XN_Y_PLUS_32}}" class="b" font-size="10.5" fill="var(--bad)">{{XN_STATE}}</text>
</g>
<path d="{{EDGE_PATH}}" fill="none" stroke="var(--bad)" stroke-width="2" stroke-dasharray="6 4"
      marker-end="url(#mr-ah)"/>
<rect x="{{EL_X}}" y="{{EL_Y}}" width="90" height="34" rx="6" fill="var(--badbg)" stroke="var(--badln)"/>
<text x="{{EL_CX}}" y="{{EL_Y_PLUS_16}}" text-anchor="middle" class="b" font-size="10" fill="var(--bad)">Depends on</text>
<text x="{{EL_CX}}" y="{{EL_Y_PLUS_28}}" text-anchor="middle" class="mut" font-size="9.5">cross-milestone</text>

<!-- 4. SIZE-BAND GAUGE -->
<text x="24" y="{{G_Y}}" class="sb" font-size="12">Bundle size vs 15–25 pt target band (bundle-composition-doctrine § 3 Step 5)</text>
<rect x="24" y="{{G_TY}}" width="{{TRACK_W}}" height="26" rx="6" fill="var(--neutbg)" stroke="var(--line)"/>
<rect x="{{BAND_X}}" y="{{G_TY}}" width="{{BAND_W}}" height="26" fill="var(--okbg)"/>
<line x1="{{CEIL_X}}" y1="{{G_TY_MINUS_6}}" x2="{{CEIL_X}}" y2="{{G_TY_PLUS_32}}" stroke="var(--bad)" stroke-width="2"/>
<text x="{{CEIL_X}}" y="{{G_TY_PLUS_44}}" text-anchor="middle" class="b" font-size="10" fill="var(--bad)">25 ceiling</text>
<rect x="24" y="{{G_TY_PLUS_6}}" width="{{BAR_W}}" height="14" rx="4" fill="var(--{{GT}})" opacity="0.85"/>
<text x="{{BAR_LABEL_X}}" y="{{G_TY_PLUS_17}}" class="b" font-size="11" fill="var(--{{GT}})">{{TOTAL_PTS}} pts</text>
<!-- {{GT}} = ok when 15 <= total <= 25; warn otherwise -->

<!-- 5. LEGEND · COMPOSITION RAIL — one row per checklist group, in table order -->
<g id="legend">
<text x="24" y="{{R_Y}}" class="sb" font-size="12">LEGEND · COMPOSITION RAIL — one entry per checklist group, each sourced to its composed owner (ADR-019)</text>
<!-- REPEAT per group row, pitch 22 -->
<g id="grp-{{N}}">
  <rect x="24" y="{{ROW_Y}}" width="12" height="12" rx="3" fill="var(--{{S}}bg)" stroke="var(--{{S}}ln)"/>
  <text x="46" y="{{ROW_Y_PLUS_11}}" class="sb" font-size="11">G{{N}} · {{GROUP_NAME}}</text>
  <text x="470" y="{{ROW_Y_PLUS_11}}" class="b" font-size="10.5" fill="var(--{{S}})">{{STATUS}}</text>
  <text x="876" y="{{ROW_Y_PLUS_11}}" text-anchor="end" class="mut" font-size="10.5">{{OWNER}}</text>
</g>
</g>
<!-- {{S}} = ok on PASS, warn on FINDING, neut on NOT RUN -->

<!-- 6. TONE KEY — defines the tone vocabulary; NOT the legend -->
<g id="tonekey" font-size="10.5">
  <rect x="24"  y="{{K_Y}}" width="12" height="12" rx="3" fill="var(--okbg)"   stroke="var(--okln)"/>
  <text x="44"  y="{{K_Y_PLUS_11}}" class="mut">PASS — no finding</text>
  <rect x="200" y="{{K_Y}}" width="12" height="12" rx="3" fill="var(--warnbg)" stroke="var(--warnln)"/>
  <text x="220" y="{{K_Y_PLUS_11}}" class="mut">FINDING — see the issue card's disposition</text>
  <rect x="510" y="{{K_Y}}" width="12" height="12" rx="3" fill="var(--neutbg)" stroke="var(--line)"/>
  <text x="530" y="{{K_Y_PLUS_11}}" class="mut">NOT RUN — composed surface unavailable</text>
</g>

<!-- 7. FOOTER ROLL-UP -->
<text x="24" y="{{F_Y}}" class="mut" font-size="10.5">{{ROLLUP_LINE}}</text>
</svg>
```

## 10. Worked instance — NON-AUTHORITATIVE

The following rail is the terminal state at the time of authoring. **It is a sample, not the
spec.** § 6's derivation rule is authoritative; always derive from the live group table.

| Row | Group | Owner (compressed) |
|---|---|---|
| G1 | Triage readiness | intake-desk + delivery-engine |
| G2 | Dependencies | release-planner |
| G3 | Staleness | triage-design-rereview PT-1 |
| G4 | Architecture | triage-design-rereview PT-3/PT-4 |
| G5 | Duplication | triage-design-rereview PT-2 + similarity |
| G6 | Bundle coherence | bundle-composition-doctrine |
| G7 | Methodology-neutrality & structural-cascade | bundle-composition-doctrine + ADR-033 |
| G8 | Backlog-altitude ownership & subsumption | release-planner + group 5 similarity owner |
| G9 | Problem-validity & abstraction-altitude | triage-design-rereview § 11 |

A row count that disagrees with the live group table means the sample is stale, not that the rule
changed — re-derive, do not patch the sample.

## 11. Never

- Never persist the map as a `.svg` file in the repository.
- Never render a value absent from the briefing.
- Never infer a group status; render `NOT RUN`.
- Never emit the map outside a Mode R emission.
- Never hardcode the rail rows.
