# Control/treatment scoring — the agroecological-gradient reframing

How each experimental arm is classified as **control or treatment** and scored for its position on
the agroecological transition, so that effect sizes are oriented from *practice content* rather than
from a source dataset's inherited labels. Sits above the effect-size layer in
`08_effect_sizes_and_analysis.md`; the live orientation problem it addresses is in
`sources/ERA/04_era_open_issues.md`. Implemented (beta) in `ERA/Script/era_agroecology_beta.R`.

> **Status: draft method, for Andrea to ratify.** This is a *proposed* reframing of how control and
> treatment are defined for the gradient question, co-designed and grounded in the published
> literature (Wezel et al. 2020; Gliessman 2007, 2016). Per golden rule 5, the analysis method is
> Andrea's; nothing here is settled until she agrees it. A fuller, circulatable version exists as a
> standalone Word protocol (`Agroecology_control_treatment_scoring_protocol`, draft v0.1).

---

## Why the reframing is needed

The Hub's question is whether a **more-agroecological** system outperforms a **less-agroecological**
one. Recycled datasets did not label their arms for that question: their control and treatment were
assigned to serve the original authors' contrast, and many comparisons differ in two or more
practices at once. In ERA specifically, the harmonization logic labels the *no-fertiliser* or
*no-liming* arm as the control, whereas agroecology treats reduced dependency on purchased synthetic
inputs as a *movement along* the transition (principle 2, input reduction). Inherited labels
therefore cannot orient an agroecological effect size, and for input presence/absence contrasts they
point the opposite way to what the question needs (see `ct_reoriented` in
`sources/ERA/04_era_open_issues.md`).

The decision: **do not inherit the source's orientation.** Treat the `C_*`/`T_*` columns purely as
value carriers (the measured means of each arm) and re-derive orientation from the practices each arm
contains.

## Framework: two published dimensions (kept separate)

We use two constructs from the consolidated literature, which that literature keeps distinct (Wezel
et al. 2020, Fig. 4), and which we keep distinct too.

- **Transition levels** (Gliessman 2007, 2016). Level 1 (efficiency): reduce and optimise use of
  costly, scarce or damaging inputs. Level 2 (substitution): replace conventional inputs with
  agroecological alternatives. Level 3 (redesign): rebuild the agroecosystem on new ecological
  processes. Levels 1 and 2 are incremental, level 3 transformational; levels 4 and 5 are
  food-system scale, beyond a field trial. The conventional starting point is level 0.
- **Principles** (Wezel et al. 2020, Table 1; FAO 2018; HLPE 2019). Of the thirteen consolidated
  principles, six are field/farm-scale and measurable in a trial: (1) recycling, (2) input
  reduction, (3) soil health, (4) animal health, (5) biodiversity, (6) synergy, with (7) economic
  diversification partly so. The rest are food-system/social and not observable in ERA-type trials.

A level says *how far along* the transition an arm is; a principle count says *how many* principles
it engages at once. The two are scored separately and never merged into one index.

## Definitions

- **Treatment** = the arm at the greater transition depth (below). At equal depth, the arm of
  greater principle breadth.
- **Control** = the other arm. It is *defined by us*, from practice content, and may or may not
  match the arm the source labelled "control".
- **Absence is not agroecology.** The mere absence of a conventional input, with nothing substituted
  in its place, is level 0, not agroecological. Level 1 is the *active* reduction/optimisation of
  input use; an unfertilised plot with no compensating practice is a conventional reference, not a
  treatment. This is the decisive rule, and where inherited and agroecological orientation most often
  diverge.

## The score

Each arm is first resolved into the practice **families** it manages (soil fertility, tillage, pest
and weed management, spatial/temporal diversification, and so on). Each family gets the Gliessman
level of the practice used, or level 0 where the arm uses the conventional option or does nothing
agroecological in that family. An arm is thus a short profile of levels, one per family.

- **Transition depth** = the deepest level across the arm's families (a maximum, not a mean or sum).
  The maximum is used because Gliessman's levels denote a *stage reached*, not a quantity to
  accumulate, and because the levels are ordinal, so sums/means would impute cardinal distances the
  framework does not define. Depth also stratifies comparisons: by the treatment arm's absolute
  level, and by whether the control is conventional (level 0, *versus-conventional*) or already in
  transition (above level 0, *within-transition*).
- **Principle breadth** = the number of distinct field-scale principles the arm's practices engage
  (a count of principles, not practices, so two amendments both enacting recycling do not count
  twice). A coarse but defensible indicator of the synergy principle (6).

**Orientation** compares only the families in which the arms *differ* (shared families cannot
discriminate), hierarchically: (1) the arm higher in the deepest *differing* family is the
treatment; (2) if level-for-level in every differing family, the broader arm is the treatment; (3)
if equal on both, do not orient (lateral; see below). Comparing on the differing families rather than
overall depth keeps the rule correct when the arms share a deep practice.

## Hypotheses (one per dimension)

- **H1, depth.** Systems at a greater transition depth outperform less-transitioned systems across
  outcomes; in particular, transformational redesign (level 3) yields gains that incremental
  efficiency and substitution (levels 1 and 2) do not. Tests the incremental-vs-transformational
  distinction of Wezel et al. (2020).
- **H2, breadth/synergy.** Systems engaging a greater breadth of principles at once outperform those
  engaging fewer. Tests the synergy principle (6).

Depth and breadth enter analysis as separate, ordinal, pre-specified moderators, not one index.
(Breadth is used both as the orientation tie-break and as the H2 moderator; not circular, since the
tie-break uses it only when depth is equal, whereas H2 tests its association with outcomes.)

## The crosswalk (abridged)

Levels are assigned by an explicit, versioned crosswalk mapping each distinct practice value to a
level and to the principle(s) it enacts. It is co-designed and agreed before analysis; unmapped
values default to neutral and are logged as a coverage diagnostic.

| Practice (as recorded) | Level | Principle(s) | Anchor |
|---|---|---|---|
| Synthetic fertiliser; synthetic pesticide/herbicide; monoculture; conventional tillage; residue burning/removal; plastic mulch | L0 Conventional | none | Green-revolution baseline. |
| Reduced/zero tillage; reduced or precision input rates; IPM thresholds | L1 Efficiency | 2 | Gliessman level 1. |
| Organic fertiliser, manure, compost; biological pest control; residue retention/mulch; cover crops; green manure | L2 Substitution | 1, 2, 3 | Gliessman level 2. |
| Intercropping; crop rotation; agroforestry; crop-livestock (re-)integration | L3 Redesign | 5, 6 (also 1, 3) | Wezel et al. 2020 p. 8, the paper's own redesign examples. |

The crosswalk is realised, exhaustively, from the practices ontology (`01_practices`, 342
subpractices) as `agroecology_practice_crosswalk_v1.csv`: **every subpractice has a level and
principle, or is marked "not agroecology"** (174 agroecological, 168 not). The ontology's own
`agroecological principle` column seeded 108 of the decisions; the other 234 we assigned or corrected
(it is a coarse family tag that mislabels the conventional poles, e.g. Monoculture and Inorganic
Fertilizer, so it cannot be used directly). Applied to ERA v49 (crops), classification is a join to
this table (regex fallback only for the ~4 values absent from the ontology).

**Principle to practice (the mapping read the other way).** A practice may enact several principles,
which is why a principle count is richer than a family count:

| Principle | Practices that enact it |
|---|---|
| P1 Recycling | organic fertiliser (manure, compost, biochar, ash, biosolids, kraaling); green manure; residue retention/mulch/incorporation; tree-pruning returned to soil; crop-livestock integration |
| P2 Input reduction | reduced/zero/minimum tillage; inorganic fertiliser reduction, micro-dosing; IPM thresholds; mechanical/manual weeding; water-efficient irrigation (deficit, drip, AWD) |
| P3 Soil health | organic amendments; residue retention; reduced tillage; green manure; terracing/bunds/contour ridges; water harvesting |
| P4 Animal health | breed/welfare/diet (livestock; out of crop scope) |
| P5 Biodiversity | intercropping; crop rotation; agroforestry; improved/woody fallow; cover crops; varietal mixtures; local/landrace/stress-tolerant varieties; field-edge strips and hedges |
| P6 Synergy | intercropping; agroforestry/alley cropping; legume in rotation or green manure; crop-livestock integration; push-pull |
| P7 Economic diversification | agroforestry products; integrated/multi-product systems (partly on-farm, seldom recorded at plot level) |

**Neutral (off-transition) factors** correspond to no field-scale principle and do not themselves
move an arm along the transition (irrigation, liming/pH, planting date, harvest and post-harvest
timing). They never set depth or breadth but are kept as covariates and confounder flags. **Livestock**
breed/diet are scored by the same logic (on-farm/local feed and reduced purchased concentrate reach
levels 1 and 2; local breeds and crop-livestock integration reach level 3); a livestock annex is
still to be written, since the source datasets carry no livestock practice taxonomy beyond breed and
diet.

## Comparisons set aside (counted, never dropped)

- **No agroecological contrast** — both arms at level 0, or they differ only in a neutral factor, or
  only in the dose of the same practice.
- **Lateral (same-rung)** — same level via different practices (cultivar vs cultivar; manure vs
  compost). Set aside unless a within-level signal is both principle-grounded *and* recorded (a
  legume in a rotation; a documented local or resilient variety qualify; a bare cultivar or
  organic-type swap does not).
- **Unscoreable** — no practice classifiable (treatment-label-only trials; variety-code contrasts
  with no trait information).
- **Confounded** — two or more families change together with no single-factor arm to separate them
  (the factorial diagonal).
- **Conflicting** — each arm is the deeper in a *different* family. The rule forces a decision by the
  deepest differing family, but the outcome is arguable, so these are flagged for expert review.

Factorial experiments therefore yield **several control/treatment pairs, not one**: orientation is
per practice, so an arm can be a control in one pair and a treatment in another (worked through for
AC0105, the Sauvadet et al. 2019 coffee trial, in the standalone protocol).

## Effect size

For an oriented comparison, with `V_hi`/`V_lo` the treatment/control means and `s` the outcome
benefit sign (+1 higher-better, −1 lower-better): `yi = s · log(V_hi / V_lo)`, so `yi > 0` always
means the more-agroecological arm did better. Variance via ratio-of-means (lnRR) with CV imputation;
non-independence via a study random effect plus cluster-robust (RVE) variances clustered at the
study. Consistent with the lnRR layer in `08_effect_sizes_and_analysis.md`; the difference here is
only *which arm is numerator*, decided by the score rather than by the source label.

## Open questions

- Whether redesign (level 3) should always outrank substitution (level 2) when the deeper arm also
  carries a conventional input (the organic-monoculture vs synthetic-agroforestry case).
- Whether depth should always beat breadth when one arm is deeper but the other broader.
- Exactly which within-level signals earn a direction for same-rung pairs (legume/diversity and
  local/resilient germplasm are the current candidates).
- Whether neutral factors should be scored once their method is known (e.g. irrigation type).

These are Andrea's to settle; each is flagged in the per-comparison output for review.

## Sources

Wezel, A., Gemmill Herren, B., Bezner Kerr, R., Barrios, E., Rodrigues Gonçalves, A. L. & Sinclair, F.
(2020) Agroecological principles and elements and their implications for transitioning to sustainable
food systems. A review. *Agronomy for Sustainable Development* 40: 40. — Gliessman, S. R. (2007, 2016).
— FAO (2018) *The 10 elements of agroecology*. — HLPE (2019).
