# ERA handoff — from `era_harmonize.R` into the project pipeline

Versions: `../../01_status.md`. What the downstream code does: `../../08_effect_sizes_and_analysis.md`.

## The thing to understand first

**`era_harmonize.R` does not feed the effect-size pipeline directly.** There is a second script, owned by
Andrea, in between:

```
Lolita                                    │  Andrea
                                          │
era_harmonize.R                           │
   │                                      │
   ▼  Downloads/ERA_crop_data_short_vNN.csv
   │                                      │
   ▼  (a human moves + renames)           │
ERA/data/ERA_data_short_vNN.csv ──────────┼──►  added_to_10_MD_Rosen_24_Effec_Sc_new.R
                                          │        │  (~2,140 lines)
                                          │        ▼
                                          │     fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv
                                          │        │  03.fomd10_clean.R → 04.fomd10_effect_size.R
                                          │        ▼
                                          │     fomd10_effect_size.csv → 05.meta_analysis/
```

So "the ERA pipeline" is **two scripts owned by two people**, meeting at the `10_` schema. Andrea's ingestion
script lives at:

```
02.FOMD/01.metadata_harmonisation/02.metadata/04.added_to_06_FOMD_metadata_original_long/
    added_to_10_MD_Rosen_24_Effec_Sc_new.R
```

Note the folder says `added_to_06_…` but the script writes to `fomd10` — ERA skips the `06_` long stage
because `era_harmonize.R` already delivers comparison-shaped rows. → `../../04_workflow_and_folders.md`

That script also generates the per-version error reports that land in `ERA/data/vNN_error_report/` — the
files Andrea's review comments come from.

## ⚠️ Three versions are in play at once

This is the single most confusing thing about ERA, and the first thing to check when something looks wrong.
Current values in `../../01_status.md`; the shape of the problem is permanent:

| Stage | Who holds it | Typical state |
|---|---|---|
| **Built** | Lolita's `Downloads/` | newest — nobody else can see it |
| **Released** | `ERA/data/` | what Andrea can actually open |
| **Ingested** | hardcoded in Andrea's script (currently line 56) | what the analysis actually ran on |

At the time of writing these were **three different versions**, spanning several releases' worth of fixes.

**What this means in practice:**
- **When Andrea reports a problem, check which version she's holding before investigating.** It may already
  be fixed. The released version has been behind the built version by two releases.
- **When you fix something, releasing it is a separate manual act** — moving the CSV to `ERA/data/` — and
  Andrea adopting it is a third act, editing the active line in her script. Neither happens automatically.
- **Row counts differ between versions for good reasons.** The drop across v48/v49 was spurious cross-joined
  rows being removed, not data loss. Don't treat a count difference as a bug without checking the changelog.

The commented-out history in Andrea's script (`v6`, `v12`, `v16`, `v22`, `v24`, `v32`, `v41`, `v45`, then the
active line) is a useful record of which versions were actually adopted — several releases were skipped.

## ⚠️ Andrea's scripts use a different folder name

Her scripts hardcode:

```
C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/...
```

against Lolita's `Alliance-Agroecology **Knowledge** Hub - General/`. Different user, **and a different
folder name**. A script that fails instantly with "cannot open file" is almost always this, not a missing
file. → `../../09_conventions.md`

## The contract: the `10_FOMD_ERA_readme` sheet

The field-by-field agreement between ERA and the `10_` schema lives in the **`10_FOMD_ERA_readme`** sheet of
`10_FOMD_metadata_synthesis_short.xlsx`. It is both a **crosswalk** and a **running review log**.

Its columns include `Field.Name.ERA`, `ERA_harmonization` (the status), then one column per review round —
`ERA_v6_AS_…`, `ERA_v16_LM_…`, `ERA_v24_…` — with reviewer initials **AS** (Andrea) and **LM** (Lolita), plus
the target `field_name`, `data_type`, `description` and `Example`.

Example mappings: `study_id ← B.Code` · `effect_size_id ← Index` · `authors ← C.B.Author.Last` ·
`site_buffer ← Buffer.Manual` · `C_subpractice_description_raw ← C.T.Name` ·
`C_tillage_method ← C.Till.Out__T.Method` · `C_out_value ← C.ED.Mean.T` ·
`C_out_var_metric ← C.ED.Error.Type` · `C_out_sample_size ← C.ED.Reps` · `out_subindicator ← Out.Subind` ·
`time_season ← paste0(C.Time.Season.Start, ", ", C.Time.Season.End)`.

Statuses tally into `ready`, **`MISSING FROM ERA`**, and a long tail of review requests phrased as questions
to Lolita ("could you please check if…", "here I think it should be…"). Counts in `../../01_status.md`.

**How to use it:** it is the to-do list for ERA harmonization. A field marked with a request is work waiting;
`MISSING FROM ERA` means ERA genuinely doesn't carry it (`site_latlong_type`, `exp_field_size`, `time_raw`,
`C_/T_system_type`, intercrop design/pattern, all `land_structure_*`, `bio_func_group`, `bio_ground_ref`, most
`postharvest_*`; animal-varietal and harvest fields map to NA) — those are documented gaps, not bugs.

**Don't edit the sheet from a script.** It lives in `02.metadata_structure/` and is annotated by hand from
both sides — the `AS_` and `LM_` review columns are Andrea's requests and Lolita's replies. `era_harmonize.R`
produces `ERA_to_FOMD_field_map_vNN.csv` in Downloads for pasting in — that's the intended route.
→ `../../06_ontologies.md`

Caveat: the readme documents **more fields than the `10_` sheet implements** — it includes pre-collapse field
variants and planned multi-arm columns (`C2_`, `C3_`…). Treat it as a superset and design document; the `10_`
header row is what actually exists.

## A related, orphaned artefact

`Agroecology_Evidence_Hub/review_added_to_10_MD_Rosen_24_Effec_Sc_new.md` (~22 KB) is a review of Andrea's
ingestion script, sitting loose at the repository root. **Referenced, not absorbed** — it is a dated review
artefact, and re-summarising it here would drift from what it actually says. Read it directly if you're
working on that script.

## Checklist when handing over a new ERA version

1. Run, verify (`01_era_harmonization.md`), and log the release in `03_era_changelog.md`.
2. Update **every** count in `../../_status/era.md`, including the three-stage version table.
3. **Move the CSV** from `Downloads/` to `ERA/data/`, renaming `ERA_crop_data_short_vNN.csv` →
   `ERA_data_short_vNN.csv`. Until this happens, nobody else has the fix.
4. Tell Andrea, plainly: what changed, what the counts are now, what needs her decision. Note explicitly if
   row counts moved and why.
5. Hand over `ERA_to_FOMD_field_map_vNN.csv` for the readme sheet, and `product_to_confirm_vNN.csv` for the
   rows needing her call.
6. Flag anything she previously requested that is now resolved, so the readme's review columns can be closed.
