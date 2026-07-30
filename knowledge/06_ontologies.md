# 06 — Ontologies: the controlled vocabularies and their governance

`02.FOMD/02.metadata_structure/01_FOMD_ontologies.xlsx` — and its SOMD counterpart
`01.SOMD/02.metadata_structure/01_SOMD_ontologies.xlsx`. Sizes: `01_status.md`.

## What it is

The ontology workbook is the Hub's **controlled vocabulary**: the master list of allowed practice names,
outcome names, units, crop/tree/animal names, countries and sites, plus how each maps to external
classifications (FAO/SPAM food groups, CPC, WFO, GBIF). Every standardized value in the data — every
`*_subpractice`, every `out_subindicator`, every plant name — must exist in it.

It is the **contract between every source, every extractor, and every analysis**. Two datasets are only
comparable because both were mapped to the same terms. That is why exactly one person changes it.

**The workbook is maintained by Lolita, by hand.** Scripts and AI assistants **read** it. Nothing else.

## ⛔ THE GOLDEN RULE: the live ontology file is never modified

**`01_FOMD_ontologies.xlsx` must never be modified, saved over, or replaced by a script or an AI assistant —
not "just this once with approval".** There is no approved automated path to writing that file. **Lolita edits
it by hand**; that is the only way it changes.

If you are Lolita: this rule is about *scripts and assistants*, not about you opening the workbook. The
prohibition exists because automation is what destroyed it once before (below), not because the file is
frozen.

### What you MAY do instead

**1. Suggest additions (preferred).** Produce a **list** — a CSV in `Downloads/`, or a table in your reply —
of the missing terms, saying which sheet each belongs in, with a proposed external classification where
confidently inferable and the classification columns left **blank** for a human to confirm.

**2. Use the standing human channel.** `02.FOMD/02.metadata_structure/New term request .xlsx` exists exactly
for this. It has 15 sheets, one per vocabulary — `Sites, Outcomes, Units, 01_product_new, 01_vars_crops,
01_tree, Fertilizer, Chemicals, Weeding, Residues, Econ_vars, Tillage, Agroforestry, Irrigation,
01_lookuplevels` — and every sheet follows the same shape: who is requesting, the `study_id` that needs the
term, the term-specific fields, then **`Accepted` / `Reviewer` / `Notes`** for the ontology maintainer
(Lolita) to sign off. This is the route an extractor takes when a paper reports something outside the
vocabulary. → `07_extraction.md`

**3. Write a NEW file to Downloads.** If a full workbook is genuinely more useful than a list, write a
**new, separately-named** file into **your own** `Downloads/` folder (`%USERPROFILE%/Downloads`), e.g.
`01_FOMD_ontologies_PROPOSED_<what-changed>.xlsx`. Rules:
- **Downloads only** — never in `02.metadata_structure/`.
- **A new name.** Never reuse `01_FOMD_ontologies.xlsx` as a filename, even in Downloads — a same-named file
  is one careless drag from replacing the real one.
- It is a **proposal for a human to review**, not a drop-in replacement. Say so when you hand it over.

### Forbidden, explicitly

- `saveWorkbook()` / `write.xlsx()` / any `openxlsx` write targeting the live path — in any script,
  including throwaway one-offs.
- Copying a backup, an older version, or a "cleaned" version over the live file.
- Editing it while telling the user you'll "fix it properly later".
- Deleting, renaming or moving it.

If you believe the live file is genuinely broken, **stop and tell the user**. Diagnosing is fine; writing is
not. Recovery of past damage is via **OneDrive version history**.

**The same applies to every other workbook in `02.metadata_structure/`** (`00_FOMD_ROSES`, `02_`–`10_`,
`New term request .xlsx`, `REMOVE_FOMD_outcomes`) and to the extractors' `.xlsm` files. Read them, propose
changes, don't write them.

### Cautionary tale — why the rule is this strict

A one-off script (`apply_to_original.R`) once did `loadWorkbook(BACKUP)` then `saveWorkbook(live)`, saving a
**stale backup over the live file** — reverting a colleague's animal exclusions and FAO classifications, and
adding new crops with blank FAO groups. A later per-product diff confirmed no *net* classification loss, but
the incident is the reason the rule has no exceptions. Recovery was via OneDrive version history.

## The sheets

`01_FOMD_ontologies.xlsx` — 18 sheets plus `01_readme`:

| Sheet | Holds |
|---|---|
| **`01_practices`** | **THE practice vocabulary.** `code.ERA`, `theme` → `practice` → `subpractice` (+ their ERA codes), `subpractice_description`, `Source`, **`agroecological principle`**. Themes include Agroforestry, Intercropping, Crop rotation, Mulching, Liming, Water harvesting, Input reduction/substitution, Monoculture, the tillage classes |
| **`01_outcomes`** | **THE outcome vocabulary.** `pillar` → `subpillar` → `indicator` → `subindicator` (+ codes), definitions, example units, sign conventions (`Negative Values`, `Sign`, `TC.Ratio`), and **`effect_size_type`** (Log Response Ratio / Standardized Mean Difference) with its logic and reference. Pillars: Mitigation, Productivity, Resilience, Other |
| `01_suboutcome_units`, `01_out_econ` | units per suboutcome; economic outcome variables |
| `01_product_new` | crops & food products: `Product.Type → Subtype → Product → Product.Simple`, `Scientific.Name`, `CPC_Code`, `WFO_Code`, SPAM/FAO food groups. (`01_product_old`, `01_products` are legacy) |
| `01_vars_crops`, `01_vars_animals` | crop varieties; animal varieties/breeds |
| `01_trees` | tree species: `WFO.Code`, GBIF, `Tree.Nfix`, `Tree.Legume`, mulched/incorporated/fallow |
| `01_countries`, `01_sites` | country + ISO3 + lat/lon bounds; site registry with coordinates, buffer, synonyms |
| `01_fertiliser`, `01_chemicals`, `01_residues` | fertiliser categories/types with N/P/K/S/Ca/Mg content; chemical types; residue types |
| **`01_lookuplevels`** | the **drop-down validation table** driving the extraction workbooks: `Table`, `Field`, `Values_Old`, `Values_New`, `Description`, plus Spanish translations and reference sources |

Note the heavy **ERA lineage** — `code.ERA` and `*.code.ERA` columns run throughout, because ERA's
vocabularies were the starting point for several of these sheets.

`01_SOMD_ontologies.xlsx` is the second-order counterpart: one sheet `01_SOMD_fp_definitions` defining
farming practices at synthesis level (`fp_id`, `fp_practice`, `fp_subpractice`, descriptions).

## How code uses it

`02.FOMD/04.metadata_effectsize/fomd_fun/fun_load_data_ontologies.R` loads the sheets into `fomd01.*` data
frames (countries, sites, trees, products, outcomes, practices). `fun_lookup_ontologies.R` provides the
generic `apply_lookup_ontologies()`, which maps a `..`-joined column through a reference table.
`fun_lookup_commodities.R` builds crop/tree → FAO Food Group lookups and the C-vs-T commodity-group
intersection. → `08_effect_sizes_and_analysis.md`

The extraction workbooks each carry an **embedded copy** of every ontology sheet so their drop-downs work
offline — which means an extractor's copy can be older than the live file. → `07_extraction.md`

## Verifying conformance after a vocabulary change

Split every `*_subpractice` column on its separators and check each token exists in `01_practices`
`subpractice`. Acceptable exceptions: **intentional control labels** ("Monoculture", "No Fertilizer
Application", "No Chemical Application", "No Liming (control)") and **legitimate residuals** that have no
ontology equivalent yet (e.g. livestock veterinary chemicals, water-harvesting "Other"). **Flag residuals,
don't force-map them** — a wrong mapping is worse than an honest gap.

## What this doc deliberately does not contain

**Term lists.** Not the 334 subpractices, not the 151 subindicators, not the crop names. Reasons: they
change, a copy here would be wrong within a sprint, and — most importantly — a copy invites someone to edit
the copy instead of requesting a change to the source. Read the sheets; they are the authority.

ERA-specific code→name crosswalks (e.g. the `PO.Codes` harvest/postharvest table) live with ERA, in
`sources/ERA/01_era_harmonization.md`, because they are mappings *into* the ontology, not part of it.
