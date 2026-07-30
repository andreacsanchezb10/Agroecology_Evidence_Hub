# 02 — The project

> Orientation only. The authoritative document is the protocol:
> `protocol/Knowledge Hub Protocol.docx` — **version dated 2025-31-10, and a live working draft**. Where
> this doc and the protocol disagree, the protocol wins; tell Andrea so this gets fixed.

## What it is

**"A living Evidence Hub for agroecological meta-analyses: Protocol for an AI-assisted, FAIR-compliant
systematic review."**

Developed by the **Alliance of Bioversity International & CIAT** within the **CGIAR Multifunctional
Landscapes (MFL) Science Program**, area of work **AoW05**. PI: **Andrea Sanchez**. Conceived, in the
partners' own words, as *"a strategic evidence infrastructure rather than a short-term project activity"* —
a digital public good.

## The problem it addresses

The protocol's framing: *"The evidence base has expanded rapidly, but decision-makers lack a transparent,
harmonized map of where, when and by how much these practices outperform conventional or simplified
systems."* Evidence exists but is fragmented and inconsistently structured — and crucially, **many
systematic syntheses have already extracted primary-study data, yet those meta-datasets remain scattered
and underused.**

## The method: evidence recycling

This is the single most clarifying idea in the project, and it explains most of the folder structure:

> The Hub does **not** primarily read the primary literature afresh. It **harvests the primary-study-level
> datasets that previous meta-analyses already extracted**, harmonizes them into one shared template, and
> re-analyzes them — filling gaps by hand only where a source dataset was incomplete.

So the unit of ingestion is *a published synthesis and its underlying data*, not *a paper*. A source
synthesis arrives, its study list and meta-dataset are harmonized, and its studies enter the pool. ERA is
the first and largest such source. → `04_workflow_and_folders.md`

## The research questions

**Primary** (verbatim from the protocol):

> *"How effective are agroecological farming practices at improving agronomic, economic, environmental, and
> social outcomes compared with non-agroecological practices and/or natural or semi-natural habitats?"*

**Secondary** (paraphrased; the protocol's own text is still elliptical):
1. What is the **state of the evidence** — how many studies, what effect sizes, what geographic coverage,
   which intervention and comparator classes, which outcome metrics, which commodities?
2. Do effects **vary by context** — continent/region, intervention class, comparator class, management
   practice, farming context (farm size, experimental vs commercial vs subsistence), commodity type?
3. When does increasing agroecological integration produce positive outcomes, and **when does it produce
   trade-offs?** Backed by a planned 4×4 trade-off matrix across the four outcome domains.

## The four outcome domains

| Domain | Examples |
|---|---|
| **Agronomic** | yield, biomass, LER/ATER, animal productivity |
| **Economic** | income, profit, gross margin, benefit–cost ratio, cost indicators |
| **Environmental** | biodiversity (abundance, richness, Shannon, evenness), input-use efficiency, GHG, SOC |
| **Social** | food security & nutrition, labour & employment, equity & inclusion (incl. gender), well-being & livelihood resilience |

Social outcomes and under-represented regions are named priorities — they are where existing syntheses are
thinnest.

## Scope: global

The protocol's PICOC Population is explicit: studies *"in any part of the world."* No restriction on year,
language or geography is applied at search.

**This matters because it is easy to get wrong.** ERA — currently the only harmonized source — is
Africa-only, so today's data is African. **That is a property of ERA, not of the Hub.** Therefore:
- Don't describe the Hub, the research question, or the evidence base as African.
- Don't build region assumptions into code, column definitions, or the ontology.
- Say "in ERA" when a fact is ERA-specific. Most geographic facts are.

45 priority countries are tracked across four consumer streams (FABLE, CFRA, MFL WP5, Biofincas) —
see `04_FOMD_screening.xlsx` sheet `country_priorities`, and `01_status.md`.

## Standards

- **ROSES** (RepOrting standards for Systematic Evidence Syntheses) is the adopted standard — **not
  PRISMA**. ROSES exists precisely because PRISMA has limited applicability to environmental-management
  reviews. Reference kept at `protocol/references/s13750-018-0121-7.pdf`.
- **PICOC** — Population, Intervention, Comparator, Outcomes, Context — is the scoping framework.
- **FAIR** data principles; metadata aligned to the ROSES checklist extended with DataCite and Dublin Core.
- **Living review:** periodic re-search, re-screen and republish cycles; each release version-tagged with a
  changelog, a Zenodo DOI, and a mirror on the CGIAR Open Data Portal.

## What "agroecological vs conventional" means here — and why it needs care

The protocol defines agroecological practices as management that *harnesses ecological processes and
ecosystem services* — nutrient cycling, biological nitrogen fixation, pest regulation, biodiversity — rather
than relying on synthetic inputs or purely technological fixes. Practices improve input efficiency,
substitute external inputs with natural alternatives, or redesign whole systems. Comparators are systems
that do not intentionally integrate ecological processes, relying mainly on external synthetic inputs
(monocultures, conventional tillage, input-intensive systems), plus natural/semi-natural habitats.

**The hard part:** agroecology is a **gradient, not a binary**, and source datasets rarely label their arms
that way. Deciding which arm is the agroecological one and which is the control is therefore sometimes **an
analysis decision made by us**, not a fact inherited from the source. Don't assume Treatment = intervention
= agroecological. → `sources/ERA/01_era_harmonization.md`, `sources/ERA/04_era_open_issues.md`

## Partners and who consumes the output

**Collaborators**
- **CIRAD** — evidence synthesis and agroecology expertise (Damien Beillouin).
- **JRC** (European Commission Joint Research Centre) — owns the **second-order** evidence library
  (Schievano et al. 2024: 13,935 records screened, 759 meta-analyses included; local copy in
  `Schievano et al 2024/`). Division of labour: JRC covers second-order and prioritizes yield/income in the
  Global South; the Alliance covers **first-order** metadata integration and broader thematic coverage.
- **Stats4SD** — methodological/statistical workflow development and the web platform.
- **WorldFish**, plus CGIAR scientists and regional partners.

**Downstream consumers — why this is funded**
- **CFRA Work Package 2** — where to target agroecological/regenerative practices for nutrition and
  environmental benefit; nine African countries, focus **Ethiopia, Kenya, Zambia**. Currently the live
  deliverable (`05.meta_analysis/idrc-cfra_analysis/`).
- **FABLE** — feeding context-specific agroecology evidence into food-system modelling (the FABLE Calculator).
- **JRC policy** — CAP, Farm to Fork, EU–Africa partnerships.
- **Science** — meta-analyses and meta-regressions on synergies and trade-offs. Target journals:
  *Environmental Evidence*, *Campbell Systematic Reviews*.

## What this doc deliberately does not restate

Search strings, the full PICOC table, the 13 named exclusion criteria, the screening-level definitions, and
the ROSES flow-diagram counts. Reasons: they live in the protocol and in
`03_FOMD_selection_criteria.xlsx` / `04_FOMD_screening.xlsx`, restating them creates a second thing to keep
in sync, and **the protocol draft is internally inconsistent in places** — its §2 still attributes the
review to a "CGIAR Water, Land and Ecosystems / Sustainable Foods" project rather than MFL AoW05, and
carries `xx` placeholders, unresolved Spanish editing notes, and duplicated sections. Read it, don't mirror
it.

The screening **status codes** are the exception — you need those to read the workbooks at all, so they are
in `03_somd_and_fomd.md` and the glossary.
