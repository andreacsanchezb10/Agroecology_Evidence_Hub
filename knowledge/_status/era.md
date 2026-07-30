# Status — ERA

**Owner: Lolita.** Read via `../01_status.md`. Figures verified **2026-07-30**.

## Three versions are in play at once

This is the single most confusing thing in the project. Read it before investigating any ERA discrepancy.

| Stage | Version | Where | Rows / studies |
|---|---|---|---|
| **Built** (newest) | **v49** | Lolita's `Downloads/ERA_crop_data_short_v49.csv` | 191,019 / 1,810 |
| **Released** to Andrea | **v47** | `ERA/data/ERA_data_short_v47.csv` | 232,209 / 1,810 |
| **Ingested** downstream | **v46** | read by `added_to_10_MD_Rosen_24_Effec_Sc_new.R` line 56 | — |

- 332 columns throughout.
- **The row-count drop 232,209 → 191,019 is not data loss.** It is spurious cross-joined rows being
  removed: v48 fixed biodiversity taxon×metric cross-products (230,267), v49 generalized the fix to soil
  depths and pest species×time (191,019). Study count held at 1,810 the whole way.
  → `../sources/ERA/03_era_changelog.md`
- Version history of row counts: 232,257 / 1,811 → 232,209 / 1,810 (v47 dedup) → 230,267 (v48) → 191,019 (v49).
- **Consequence:** if Andrea reports an oddity, check whether v48/v49 already fixed it before investigating.
  → `../sources/ERA/02_era_handoff.md`

**v49 is built and awaited — release pending.** It sits in `Downloads/` and nobody but Lolita can open it
yet; the team is waiting for it. Moving it to `ERA/data/` is a manual step and is the thing that unblocks
everyone else. Until then, `v47` is what any collaborator actually has.

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
