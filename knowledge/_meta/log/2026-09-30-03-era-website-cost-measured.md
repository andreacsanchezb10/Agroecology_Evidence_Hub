2026-09-30 — **Measured what ERA would actually cost the website; corrects two claims made earlier today** —
`_status/website.md` (new "What ERA would actually cost" section), `website.md`, `website/build.py`.

Asked whether adding ERA means memory or hosting problems. Measured rather than estimated: Chrome via
Playwright, phone viewport 390x844, local server, all 89,245 records, against the 1,449 the site ships.

**Hosting is not a problem and needs no money.** GitHub Pages gzips: the 1.2 MB `data.js` shipped today
transfers as **62 KB**, verified with `curl` against the live site. 65 MB raw would transfer as about
**2.3 MB**. The repository would sit near 70 MB against a 1 GB soft limit; 100 GB/month of bandwidth is
roughly 43,000 full visits. No server, no Amazon, no paid hosting at this size. Real limits are GitHub's
100 MB hard per-file block, which 65 MB approaches, and that git keeps every version forever.

**The renderer is the problem, and the fix is nearly one line.** `L.map()` in `app.js` sets no
`preferCanvas`, so Leaflet uses SVG and creates one DOM node per record. With 89,245 points, median frame
during pan and zoom is **489 ms, about 2 fps** — unusable. With canvas it is **14 ms**, smooth, and the DOM
holds 3 nodes instead of 89,248. Remaining cost is memory: ~219 MB of heap, comfortable on desktop, the
genuine risk on older iOS where Safari discards tabs in that range.

## Two things written earlier today were wrong

1. **"~89k Leaflet circle markers will not render acceptably"** (`_status/website.md`) — true only of the
   SVG renderer. With canvas they pan at 60 fps. Corrected.
2. **"every visitor would download and parse all of it"** (`build.py`'s refusal message, and the same
   framing in `website.md`) — conflated file size on disk with what travels. The download is compressed and
   is not the main cost; parse (1.5 s), memory (113 MB after load) and rendering are. Corrected in all three
   places, and `MAX_DATA_MB`'s comment now says the data needs a different *shape*, not a smaller file.

The 20 MB guard still stands, because parse and memory scale with the uncompressed size, but the framing
"too big to publish, full stop" was too strong. ERA is feasible with modest work; what holds it back is the
effect-size bug, which is unchanged and remains Andrea's call.

**Cheaper shapes measured, for whoever does this:** the same records as columns rather than one object per
row is 1.4 MB gzipped; map fields only, as columns, is **260 KB** gzipped with the full record fetched on
demand; one file per country is 49 files, largest 323 KB (Brazil), median 16 KB.

**Scaling, measured the same way** (canvas, phone viewport, records replicated): heap 83 MB at 89k,
175 MB at 200k, 342 MB at 400k, 673 MB at 800k; pan hitch 275 / 371 / 845 / 1,810 ms. **Memory binds before
speed**, and this shape holds to roughly 200k records. Yield per study varies more than tenfold between
sources (ERA 48.5 records/study, Jones and Paut 2.7), so the total depends on which sources arrive more than
on how many papers. The 1,000+ papers expected put the total at 92k-138k — inside the headroom. Beyond that
the fix is aggregating per country at world zoom, not a bigger file. Table in `_status/website.md`.

**Not measured:** the comparisons table at 89k rows, the per-filter recount in `render()`, and the heatmap.
Those are app-level costs separate from the map and would need their own pass.
