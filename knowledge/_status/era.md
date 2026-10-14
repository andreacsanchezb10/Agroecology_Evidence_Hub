# Status — ERA

**Owner: Lolita.** Read via `../01_status.md`. Figures verified **2026-10-01**.

## Three versions are in play at once

This is the single most confusing thing in the project. Read it before investigating any ERA discrepancy.

| Stage | Version | Where | Rows / studies |
|---|---|---|---|
| **Built** (newest) | **v52** | Lolita's `Downloads/ERA_crop_data_short_v52.csv` (1 Oct 2026) | 166,297 / 1,808 |
| **Released** to Andrea | **v51** | `ERA/data/ERA_data_short_v51.csv` (28 Sept 2026) | 166,297 / 1,808 |
| **Ingested** downstream | **v46** | read by `added_to_10_MD_Rosen_24_Effec_Sc_new.R` line 56 (last checked 2026-07-30) | — |

- 332 columns through v50; 340 in v51; **342 in v52** (`C/T_subpractice_filled`, recording where each
  explicit no-application label came from).
- **The row-count drops 232,209 → 191,019 → 166,297 are not data loss.** They are spurious cross-joined
  rows being removed: v48 fixed biodiversity taxon×metric cross-products (230,267), v49 generalized the fix to
  soil depths and pest species×time (191,019), v51 made the two arms agree on sampling window, unit,
  aggregation statistic and weight-gain duration (166,297; per study × outcome in
  `pair_alignment_v51_reasons.csv`). Study count 1,810 through v50; **1,808 in v51**: NN0376 excluded at
  Andrea's request (rangeland exclosure, not agroforestry) and DK0053 left with no valid pair.
  → `../sources/ERA/03_era_changelog.md`
- Version history of row counts: 232,257 / 1,811 → 232,209 / 1,810 (v47 dedup) → 230,267 (v48) → 191,019 (v49,
  v50) → **166,297 / 1,808 (v51)**.
- **Consequence:** if Andrea reports an oddity, check whether v48/v49 already fixed it before investigating.
  → `../sources/ERA/02_era_handoff.md`

**v52 is built and awaited — release pending** (built 2026-10-01 20:18, 26.2 min, **350 columns**).
Two decisions by Lolita on 1 Oct shaped the final build.

**1. Background management has its own columns.** A practice in the study-level record was applied to every
arm, so it is a property of the comparison, not of one arm, and it must not sit in an arm's practice column.
Eight new row-level columns `background_<family>_subpractice` carry it: fert 43,925 rows, varietal_crop
31,696, irrig 18,134, ph 14,906, tillage 7,810, watharv 4,299, residues 987, chem 0. An arm's column stays
blank, which now means exactly one thing: **this arm had nothing EXTRA in that family**.

**The number that matters is the split, not the raw count.** One-arm-empty is 46,236 → **19,051**, but
**18,556 of those are explained by the background column** and only **495 are genuinely unexplained**
(tillage 361, intercrop 99, residues 24, fert 11). Kenya crop: 4,058 rows / 53 studies → 647 / 12, of which
**4 rows in 1 study** are unexplained.

**This exposed a pre-existing error in v51 and earlier.** The v32 rule labelled an arm
"No Fertilizer Application" without ever checking whether the study applied fertiliser to every plot — its
own comment said "not constant background" but it never tested it. **14,334 fertiliser arms were wrongly
labelled, and were wrong in v51 too.** The fert/ph/chem rules now consult the background column; the flip
sets are deliberately untouched so orientation does not move further.

**2. Intercrop and rotation controls are re-oriented.** Where the blank arm was the CONTROL and its own crop
list showed several crops, the row was the wrong way round against the convention (4,793 intercrop
comparisons have the monoculture as control, none the reverse). Those 390 arms (249 intercrop, 141 crop_seq)
are now labelled and the Tier-1 rule flips them, so the monoculture becomes the control.

Row count, study count and **every outcome value identical to v51** on all 165,919 joined rows.
**378 rows change C/T** and every one matches a v51 row with the arms swapped; `ct_reoriented` 2,438 →
2,748. 84,219 arms labelled; rows carrying a tillage practice 22,786 → 30,526.

**v51 was released on 28 Sept.** Earlier note, kept for the sequence: It sits in `Downloads/` with its companions
(`ERA_v51_reply_to_Andrea.md`, `ERA_field_notes_v51.csv`, `pair_alignment_v51_reasons.csv`,
`ERA_row_reconciliation_v47_v51.csv`, `excluded_studies_v51.csv`, `template_drift_v51.csv`). Moving the CSV to
`ERA/data/ERA_data_short_v51.csv` is a manual step. Until then, `v50` (released 17 Sept 2026) is what any
collaborator actually has; v50 = v49 rows plus the animal breed/diversity fill.

## The ERA → `10_` crosswalk

`10_FOMD_ERA_readme` sheet: **613 rows × 19 cols**. It is a field-by-field mapping *and* a review log
across ERA versions (columns `ERA_v6_AS_…`, `ERA_v16_LM_…`, `ERA_v24_…` — reviewer initials AS and LM).

| `ERA_harmonization` value | Rows |
|---|---|
| *(blank)* | 330 |
| **`ready`** | **132** |
| **`MISSING FROM ERA`** | **23** |
| review requests (various wordings) | rest |

The readme documents more fields (613 rows) than the `10_` sheet implements (287 columns) — it is a
superset/design document including pre-collapse field variants and planned multi-arm columns (`C2_`, `C3_`…).
Fields flagged missing from ERA include `site_latlong_type`, `exp_field_size`, `time_raw`,
`C_/T_system_type`, intercrop design/pattern, all `land_structure_*`, `bio_func_group`, `bio_ground_ref`,
most `postharvest_*`; animal-varietal and harvest fields map to NA.
