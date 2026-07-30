# Adding a new source synthesis — the template

**How to use this:** create a folder `sources/<SOURCE_NAME>/` and write the docs below, using the same
filenames ERA uses so anyone can navigate any source the same way. Fill them as you learn — a stub saying
"unknown / TBD" beats a missing file. Keep the house style: **plain language first, then exact field names
and paths.**

The target is **≥10 source syntheses**; ERA is the first and by far the most complicated. Most sources will
need much less than ERA does.

## The doc set

| File | What goes in it |
|---|---|
| `00_<name>_overview.md` | What this dataset is, its `ss_id`, who maintains it, why it's in the Hub, its **geographic coverage**, its licence/access, and the structure of its raw data — tables, key fields, identifiers, how comparisons are encoded, per-part quirks |
| `01_<name>_harmonization.md` | The script that translates it into the `10_` schema: where it is, how to run it, runtime, the decisions baked into it, gotchas, and the verification recipe |
| `02_<name>_handoff.md` | Where the output goes, who consumes it, the crosswalk that defines the contract, and any version lag between what you produce and what's actually being used |
| `03_<name>_changelog.md` | One section per version: what changed and what verification showed. Newest on top. **Only once the source has versioned releases** — skip it for a one-off ingestion |
| `04_<name>_open_issues.md` | Known gaps, deferred decisions, and their impact on analysis. Separate "ours to fix" from "handed to a human for a decision" |

Do **not** create an analysis or method doc. Analysis method is Andrea's, project-wide
(`../08_effect_sizes_and_analysis.md`). Document what the data *is* and what it *can't support*; leave how to
analyze it to her.

Do **not** restate the shared schema, the ontology, or the workflow — link to `../05_data_schemas.md`,
`../06_ontologies.md`, `../04_workflow_and_folders.md`. Document only what is specific to your source.

Do **not** put counts in these docs. All numbers live in `../_status/`, read through the `../01_status.md`
index. Register your source's counts in `../_status/sources.md`; if the source becomes large enough to need
its own status file, add one and list it in the index.

## Onboarding checklist

1. [ ] Get read access to the raw data; note its location. **Never write into it.**
2. [ ] Record the **`ss_id`** (`TYPE_Auth5_YY_Titl5_Jr2` — see `../03_somd_and_fomd.md`) and register the
       source in `../_status/sources.md`.
3. [ ] Note its **screening class** and what that implies: are its studies `I` (data complete → harmonize by
       script) or `PI` (partial → manual extraction needed → `../07_extraction.md`)? A source can have both.
4. [ ] Note its **geographic coverage** in `00_…_overview.md`. The Hub is global and sources differ — ERA is
       Africa-only. Recording this stops anyone generalizing one source's coverage to the Hub.
5. [ ] Write `00_…_overview.md` from the raw files: identifiers, how control-vs-treatment (or comparison)
       structure is encoded, which vocabulary fields exist, and the quirks that will bite.
6. [ ] Map its fields to the `10_` schema. List any vocabulary terms **missing from the ontology** and hand
       them over via `New term request .xlsx` — **never** edit `01_FOMD_ontologies.xlsx`
       (`../06_ontologies.md`).
7. [ ] Decide the route: straight to the `10_` schema (like ERA, if the data is already comparison-shaped) or
       via the `06_` long table (like Jones/Paut/Sanchez). → `../04_workflow_and_folders.md`
8. [ ] Write the harmonization script. Output to `Downloads/` — never into a shared data folder
       (`../CLAUDE.md` rule 1).
9. [ ] Verify counts **and the rows you touched**; record the expected numbers in `../_status/sources.md` and the
       spot-checks in `01_…_harmonization.md`.
10. [ ] Fill `04_…_open_issues.md` honestly, including anything you noticed but didn't fix.
11. [ ] Add one new entry file to `../_meta/log/`.
