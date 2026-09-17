2026-09-16 — Website now in English, Spanish and French, with photographs on three pages (Lolita's
request; follows [[2026-09-16-02-website-text-pages-redesign]]). Live and verified on the deployed site at
https://mlolita26.github.io/agroecology-evidence-hub/.

**Languages.** A switcher at the top right shows the current language and offers the other two; choosing one
swaps every string at once, no reload. English stays the single source: it lives in `index.html` behind 174
`data-t` keys and in the `KH_UI.en` block of `docs/i18n.js`, and `i18n.js` holds only the Spanish and French
overrides, so English is never duplicated. A missing key falls back to English, so a partial translation
still renders. Choice persists in `localStorage` (`kh-lang`); a first visit follows `navigator.language`.

**The Hub's own name is never translated**, on Lolita's instruction, in the wordmark, the Home kicker and
the Contact footer. Eleven other keys are deliberately left in English: partner organisation names (Alliance
of Bioversity International & CIAT, CGIAR Multifunctional Landscapes AoW05, CIRAD, Stats4SD), CC BY 4.0,
ROSES, and the two numeric scale labels.

**The data vocabulary is NOT translated.** Country, crop, practice and outcome values come from the
controlled vocabulary of the source syntheses. Translating them is a terminology decision for the review
team, not a UI one, and it would also desynchronise the filter values from the CSV download. Flagged to
Lolita as a decision still open.

**Translations are unreviewed.** The Spanish and French were produced alongside the build and no native
speaker on the team has read them. They should be checked before the site is promoted.

**Photographs.** Home, About and Methodology now use photographs instead of the generated artwork
(`docs/img/home.jpg` Olivier Asselin / FAO, `about.webp`, `methodology.jpg`). Get involved and Contact keep
the artwork because only three photographs were supplied. **Rights are not confirmed for any of them and
only the FAO one has a known photographer** — the repository is public, so this needs checking before
promotion; `docs/img/README.md` records the state and the per-page `data-photo` switch.

Also removed the five-bar logo glyph from the wordmark, and rewrote the Home standfirst, which described
the pipeline rather than the point ("We take the field trials that published studies have already measured
and put them on one map, so you can see what each practice actually changed").

Implementation notes worth keeping: the `data-t` keys were injected by a throwaway BeautifulSoup script
rather than by hand, which flattened the HTML indentation — restored afterwards with a depth-based
re-indent, since the file is meant to stay readable. Two ordering traps: `setTheme`'s parameter was named
`t` and shadowed the new translation function `t()`, and `setLang` must run **before** `buildFilters()` and
`buildHead()` at startup or the dropdowns and table header are built in English regardless of the saved
language. Both fixed and verified.

Checked in a browser at 1440px and 390px: all three languages round-trip across nav, headings, filters,
table header, the generated sentence and the record panel, with no console errors and no horizontal scroll.
