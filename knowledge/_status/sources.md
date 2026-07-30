# Status — source syntheses, screening, and the three tables

**Owner: whoever ingests a source** (register the source when you add it). Read via `../01_status.md`.
Figures verified **2026-07-30**.

## Source syntheses — the register

The target is **≥10** source syntheses. **4 are in progress**; none has completed screening
(`pa_studies_after_screening` is still blank for all four in `00_FOMD_ROSES.xlsx`).

| `ss_id` | Known as | Primary studies identified | After dedup | In screening | Doc set |
|---|---|---|---|---|---|
| `MD_Rosen_24_Effec_Sc` | **ERA** (Rosenstock et al. 2024) | 1,811 | 1,811 | 1,811 | `../sources/ERA/` |
| `MD_Paut,_24_A glo_Sc` | Paut et al. 2024 | 292 | 274 | 283 | — |
| `MD_Jones_21_A glo_Sc` | Jones et al. 2021 | 237 | 236 | 237 | — |
| `MA_Sanch_22_Finan_Ec` | Sanchez et al. 2022 | 119 | 113 | 117 | — |

Note the dedup and screening columns disagree for Paut (274 vs 283) and Sanchez (113 vs 117) — the ROSES
counts and the screening sheet were populated at different times. Not yet reconciled.

## Screening — the work split

`02_FOMD_identified_studies.xlsx`: **2,459 rows × 18 cols** (pre-dedup).
`04_FOMD_screening.xlsx`: **2,449 rows × 25 cols** (unique records).

| Status | Count | Means |
|---|---|---|
| **`I`** | **1,851** | Included, data complete — already extracted in the source dataset. **Harmonized by script, no manual work.** |
| **`PI`** | **579** | Included, data partially complete — **needs manual extraction from the PDF** → becomes a `09_FOMD_*.xlsm` workbook |
| `O` | 16 | Excluded at full text |
| `unresolved` | 2 | Pending second reviewer |
| `I in removed` | 1 | Anomalous status value |
| *(ss_id `error`)* | 1 | One row has `ss_id` = `"error"` — a data-entry artefact |

So the manual-extraction backlog is **579 studies**, of which 86 workbooks exist → `extraction.md`.

## The three tables

| Table | Shape | Contents |
|---|---|---|
| `06_FOMD_metadata_original_long.xlsx` | **9,985 rows × 364 cols** | As-received long data: Jones 5,487 + Paut 4,497 (+1 header artefact row) |
| `09_FOMD_metadata_extraction_long.xlsx` | **923 rows × 424 cols** | Manual-extraction master. 25 rows `row_status` = verified, 898 blank. `extraction_person`: AS 897, Lolita 25. 17 distinct `study_id` |
| `10_FOMD_metadata_synthesis_short.xlsx` | **0 data rows × 287 cols** | **The target template.** Schema only — no data has been loaded into it yet |

Sheets in `10_`: `10_FOMD_metadata_synthesis` | `10_FOMD_ERA_readme` | `10_FOMD_readme`.

**Note the 424 vs 364 column split** — the `09_` master has 424 columns (`crop01–15` and `tree01–15`
separate) but the V3 `.xlsm` template extractors actually fill has 364 (`crop_tree01–15` merged, identical
column names to `06_`). Ingesting extractor workbooks needs a split step. → `../05_data_schemas.md`
