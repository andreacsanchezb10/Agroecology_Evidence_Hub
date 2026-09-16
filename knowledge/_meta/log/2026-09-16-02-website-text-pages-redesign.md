2026-09-16 — Website text pages redesigned and a map bug fixed (Lolita's feedback on the first release,
see [[2026-09-16-01-public-website-github-pages]]). Live at
https://mlolita26.github.io/agroecology-evidence-hub/, verified rendering on the deployed site, not just
locally.

**Map bug.** Clicking a country removed the world layer while the pointer was still over it, so Leaflet
never fired `mouseout` and the pink hover fill (`--geo-hover`) stayed baked into that country's inline
style. It reappeared on returning to the world view. Fixed with `base.resetStyle()` when the layer is
re-added in `applyMapMode()`. Verified in a headless browser: Kenya goes `#FFFFFF` → `#FBE4EC` on hover →
`#FFFFFF` after "World view".

**Masthead.** Removed the institutional strip (Alliance/CGIAR line plus the Living review, Draft 0.4 and
CC BY 4.0 stamps) and the "A living evidence synthesis" tagline under the wordmark, on Lolita's request.
Those facts still appear in the page footers and on About, so nothing was lost.

**Text pages.** The complaint was that they felt narrow and dull next to the map. They used an 820px
"sheet" with a 62ch column, so on a 1440px screen the content was a ribbon down the middle while Explore
ran full width. Replaced with a page header plus a 1240px two-column grid: prose (70ch) beside a sticky
316px rail carrying the reference tables and the To-be-filled stubs, which previously interrupted the
reading column. Home also gained a band of the six headline counts. Collapses to one column at 1040px and
stacks the header at 860px.

**Hero artwork, and the photograph question.** Lolita asked for something like the Adaptation Atlas, "a
photo idk". There are no licensed photographs available and inventing stock imagery would have been worse
than nothing, so each header instead shows the dataset itself: one cell per comparison on the map's own
diverging scale, teal down and pink up. `data-art="<field>"` bands the cells by outcome, practice, country
or synthesis, so the five pages differ; Home sorts by value into a clean gradient. A photograph can replace
the artwork on any page with `data-photo="img/…"`; `docs/img/README.md` explains it. **If the team supplies
project photography this is a one-attribute change per page**, and that is the intended end state.

Implementation note worth keeping: the artwork is painted to a canvas sized from `clientWidth/Height`, and
the first paint ran before webfonts settled the layout, leaving a 386px bitmap in a 327px box (squashed,
non-square cells). A `ResizeObserver` on each `.hero-art` fixed it and also removed the need for a resize
listener and a repaint on page switch, since a hidden page has zero width until it is shown. Cells are
sized with `max(w/cols, h/rows)` so the artwork bleeds past all four edges rather than leaving a ragged
margin.

Checked at 1440px and 390px in both themes: no console errors, no horizontal scroll on a phone.
