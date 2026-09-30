# Status — ERA

**Owner: Lolita.** Read via `../01_status.md`. Figures verified **2026-09-28**.

## Three versions are in play at once

This is the single most confusing thing in the project. Read it before investigating any ERA discrepancy.

| Stage | Version | Where | Rows / studies |
|---|---|---|---|
| **Built** (newest) | **v51** | Lolita's `Downloads/ERA_crop_data_short_v51.csv` (28 Sept 2026) | 166,297 / 1,808 |
| **Released** to Andrea | **v50** | `ERA/data/ERA_data_short_v50.csv` (17 Sept 2026) | 191,019 / 1,810 |
| **Ingested** downstream | **v46** | read by `added_to_10_MD_Rosen_24_Effec_Sc_new.R` line 56 (last checked 2026-07-30) | — |

- 332 columns through v50; **340 in v51** (five economics / weight-gain fields, the two animal-trait
  fields and `out_comparison_id` added).
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

**v51 is built and awaited — release pending.** It sits in `Downloads/` with its companions
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
