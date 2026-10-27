2026-10-27 — **CFRA: Kenya checks closed, Ethiopia set-up, decision to change the excluded-contrast rule**
— no knowledge docs edited; code given to Andrea in chat (she edits the CFRA scripts herself).

- **Kenya extraction issues for Lolita (from PDF checks, 23–27 Oct):** JO0140 C/T swapped, crossed values and wrong
  coordinates (fixed 26 Oct; JO0140 and JO0135 left 2B). CJ0039: Control_N paired with −N organic treatments is
  ERA's pairing convention, not an extraction error (Andrea); tithonia coded as N-fixing and year-16 model-estimated
  yields (3 negative) still open; sawdust as mulch accepted. Pairing scan of all CFRA studies (26 Oct): 92 studies
  with all controls × all treatments, 24 with one treatment on several controls, 53 multi-practice; 26 Kenyan
  studies to check.
- **Ethiopia set-up (`02.cfra_analysis_ETH.R`):** three archetypes. 3A woreda polygons (`tier` 1–5), 3B and 3C 5 km
  rasters (criteria score), read as polygons with `read_arc()`; `sf_use_s2(FALSE)` needed (raster outlines are
  invalid on the sphere). Proposed high-priority rules (top class + next, as Kenya; to confirm by Andrea): 3A
  `tier <= 2`, 3B `score >= 4`, 3C `score >= 3`. Neighbouring project country: Kenya only. 3A and 3B sufficient;
  3C not (desert/arid zone covers ~79% of its areas, no study in Ethiopia or Kenya; Tanzania use undecided).
  Maps label administrative zones (from the 3A woreda layer). Output folder `02.cfra_analysis/Ethiopia/` did not exist.
- **Agroforestry gap, 3A:** the five Ethiopian agroforestry studies (AC0030.1, CJ0007, JO0125, NN0447, JO0027;
  parklands, multistrata) are all outside the 3A high-priority woredas, measure cereal yield only, and none is enset.
- **Method decision (Andrea, to implement 28 Oct):** step 5.7 of `reclassify_practices()` will drop only the rows of
  excluded contrasts (e.g. no fertilizer vs mineral fertilizer) and keep the other practice rows of the same
  comparison (e.g. monoculture vs intercropping), instead of removing the whole comparison. Checked impact:
  Kenya 2A crop rotation productivity neutral → positive strong and residue incorporation soil health positive →
  neutral; Ethiopia 3A pulse intercropping becomes strong negative. The added comparisons are confounded with the
  input (results follow which arm got the fertilizer or pesticide: DK0085, AN0129, AC0079, JO0078, JO0156); this was
  raised with Andrea. Kenya 2A text to be updated after the rerun.
