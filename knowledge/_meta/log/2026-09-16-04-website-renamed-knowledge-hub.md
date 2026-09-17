2026-09-16 — **The website is the "Agroecology Knowledge Hub", not the "Evidence Hub"** (Lolita's
correction). Renamed across the page title, wordmark, footers, README, `build.py` and the generated
`data.js` header; data regenerated, still 1464 records. Follows
[[2026-09-16-03-website-three-languages-photos]].

**The public URL still says `evidence-hub`**: https://mlolita26.github.io/agroecology-evidence-hub/. The
GitHub repo is `Mlolita26/agroecology-evidence-hub` and renaming it changes the Pages URL, so it was left
alone pending Lolita's decision. GitHub redirects the old repo name, but any link already shared would need
reissuing. **Open decision.**

Design changes from Lolita's feedback, in order:
- The five-bar logo glyph is gone from the wordmark.
- Photo captions removed from every page header. The FAO photo credit moved to the footer so the
  attribution survives.
- The band of six big counts on the home page was cut ("looks too much like Claude"). The counts went to
  the home rail as a dotted table, then the whole rail was cut too ("I don't like the two column thing").
  **The global-scope sentence was preserved** as body copy on Home, because the design brief flagged it as
  something that must not be dropped: coverage follows the harmonised sources, the Hub is not regional.
  Home is now single column (`.doc.solo`); the other four pages keep their rails.
- Partner table replaced by a centred partner band at the foot of About. Names sit in equal-width 270px
  flex slots, because with `justify-content:center` alone the differing name lengths bunched left.
- The Hub's name now leads the welcome page in display serif at `clamp(32px,3.9vw,50px)`, in the accent
  colour; masthead wordmark 23px → 26px.

**Spanish and French rewritten in plain language** on request: short sentences, everyday words, active
voice. Only terms the review needs stay technical (mediana, lnRR, ROSES, FAIR, DE/DME). 139 keys each, no
orphans; seven keys stay in English on purpose (partner names, the Hub's own name, CC BY 4.0, ROSES, and
the two numeric scale labels). **Still unreviewed by a native speaker** — this has now been flagged twice
and should be done before promotion.

Still outstanding for the team, all recorded in `website/docs/img/README.md`:
1. Two more photographs, for Get involved and Contact, which still fall back to the generated artwork.
2. Photo rights: only the FAO image has a known photographer, and the repo is public.
3. Partner logo files; the band currently sets names in type. Partner links were written from the usual
   addresses and need checking.
