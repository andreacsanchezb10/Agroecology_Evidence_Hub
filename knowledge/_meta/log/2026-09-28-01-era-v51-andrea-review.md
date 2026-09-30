2026-09-28 — **ERA harmonization v51 built from Andrea's v50 review (ten points)** — `_status/era.md`,
`sources/ERA/03_era_changelog.md` (v50 + v51 sections), `sources/ERA/04_era_open_issues.md`,
`sources/ERA/01_era_harmonization.md` (script shape, companions, gotchas).

**Result:** `Downloads/ERA_crop_data_short_v51.csv`, 166,297 rows / 1,808 studies / 340 columns (v50: 191,019 /
1,810 / 332). Not yet moved to `ERA/data/`. Reply for Andrea: `Downloads/ERA_v51_reply_to_Andrea.md`.

**What changed in `era_harmonize.R`** (backup of v50 script: `Downloads/era_cache/inspect/era_harmonize_v50_backup_2026-09-28.R`):
- `align_pair_fields()` in step 3 after each merge: sampling window, `Out.Unit`, `Out.Agg.Stat`, `Out.WG.Days`
  must be equal or blank within a pair (single date inside the other arm's range = same campaign); blanks filled.
  24,719 pairs removed in 174 studies (dates 18,838; units 5,635; durations 246).
- `add_comparison_id()`: `out_comparison_id` = pairing key used, `|`-joined, fixed order, tier suffix.
- mh `ED.Sample.Start/End` Excel serials parsed (were lost in v50).
- `out_season_start` = measurement season from `Time` (was arm establishment season `Final.Start.Season`).
- New columns from ERA `Data.Out`: `out_npv_discount_rate`, `out_npv_econ_period`, `out_wg_start`,
  `out_wg_start_unit`, `out_wg_days`; `C/T_varietal_animal_trait` wired from `V.Trait`.
- Year-sentinel step no longer touches `WG.Start|Start.Weight` columns (it was blanking kilograms).
- Agroforestry whitelist: bare `Grazing` token removed; "Monoculture" control rule gated to plant systems.
- Study exclusion table (NN0376) + `excluded_studies_vNN.csv`; template drift check writes
  `template_drift_vNN.csv` (report only: 116 template-only / 128 output-only columns).

**Evidence from PDFs (all under `OneDrive - CGIAR/ERA/Data Entry/.../pdfs`, index
`Downloads/era_cache/inspect/all_pdfs.txt`):** AC0131 Grahmann 2018, NN0415 Aluoch 2022, JO0053 Zulu 2022 (shared
sampling calendars; April 2019 one campaign); CJ0067 Mureithi 2005, AC0007 Ndakidemi 2007, JO0143 Ndayisaba 2021
(all arms established together, so `Final.Start.Season` differences are ERA miscoding); JO0140 Assefa 2020 and
JS0070 Ahenkorah 1987 (yield tables are means; JS0070 Fig. 2 is a 20-year cumulative); DK0085 Ojiem 2014,
HK0306.1 Waddington 2001, NJ0037 Fahmi 2018 (NPV rate/period match ERA); BO1018 Kewan 2021, DK0037 Asizua 2014
(weight-gain days match); EO0045 Coffie 2015 (trait not in paper), AG0097 Zonabend König 2017 (trait supported);
EM1019, JO1046, BO1018 (stocking density only partly in papers); NN0376 Haftay 2013 (exclosure, herbage 2,642 vs
843 kg DM/ha, sign was inverted in v50); AC0143 Jezeer 2018, JO0069 Harmand 2007 (genuine shade agroforestry).

**Decisions taken with Lolita:** exclude NN0376 (Andrea's request); readable `out_comparison_id`; template drift
reported to Andrea rather than padded. **Open for Andrea / ERA team:** grazing-management family; template
alignment; `Final.Start.Season` and DK0053 miscoding at source; `animal_density` not recorded in ERA.

Verification: `Downloads/era_cache/inspect/verify_v51.R` (C/T fields differ on 0 rows; id non-blank, 12,833 ids
all with both arms; only aligned studies + NN0376 changed vs v50), `reconcile_rows_v47_v51.R`,
`annotate_alignment_v51.R`. Run log: `Downloads/era_cache/inspect/v51_run.log` (~38 min).
