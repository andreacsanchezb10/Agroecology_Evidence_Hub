# Status — deliverables, ownership, housekeeping

**Owner: Lolita and Andrea jointly** — coordinate before editing. Read via `../01_status.md`.
Figures verified **2026-07-30**.

## Deliverables and dates

**End of 2026:** publishable protocol; AI-assisted workflows; ontologies; a harmonized quality-checked
meta-dataset from **≥10 systematic reviews**; a ready-to-launch online platform. **Evidence availability
maps** end-2026; **evidence effect maps** 2027. Platform Beta was scheduled end-March 2026 (Stats4SD).
Priority countries: 45 across four consumer streams (FABLE, CFRA, MFL WP5, Biofincas).

## Ownership — who decides what

| Area | Owner |
|---|---|
| **The ontology workbook — all content** | **Lolita.** Maintained by hand; never written by a script or an AI. Additions requested via `New term request .xlsx` |
| **ERA harmonization** (`era_harmonize.R`) | **Lolita** |
| **Analysis method, effect sizes, pooling rules** | **Andrea** (`../08_effect_sizes_and_analysis.md` — its method section is deliberately empty) |
| The effect-size and meta-analysis R code | **Andrea** |
| Bibliography decisions (duplicate-DOI merges) | **Andrea** |
| Manual extraction | Andrea, Charlotte, Mario, Mordecai |
| Platform | Stats4SD |
| **`knowledge/` docs** | by folder — see `../09_conventions.md` §13 |

Confirmed with Lolita 2026-07-30: **she maintains the ontology**, which matches the protocol's TO DO list
assigning the practices and outcomes ontologies to her. Earlier notes in this base said Andrea maintained it —
that was wrong and is corrected.

## Known housekeeping items

- **v49 is built and awaited — release pending.** → `era.md`
- Andrea's scripts hardcode a **different OneDrive folder name** (`…Agroecology Evidence Hub - General`)
  from Lolita's (`…Agroecology Knowledge Hub - General`), plus older `Agroecology_Knolwedge_Hub` and
  `Bioversity` strings. → `../09_conventions.md`
- `08_FOMD_metadata_ai_long.xlsx` is an **empty placeholder** (0 columns) for planned AI-assisted extraction.
- **`07_` does not exist** in the FOMD series — a renumbering artefact; today's `06_` was once `07_`.
- `REMOVE_FOMD_outcomes.xlsx` is a superseded outcome ontology, marked for deletion.
- Six pre-restructure redirect stubs remain in `knowledge/` (`analysis.md`, `conventions.md`,
  `folder_structure.md`, `ontology.md`, `overview.md`, and five under `sources/ERA/`), each a 3-line pointer
  marked for removal in a later release.
