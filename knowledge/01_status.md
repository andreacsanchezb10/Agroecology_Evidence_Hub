# 01 — Status: where the project stands, and every number

> **This is still the only place you read a number from.** Nothing outside `_status/` carries counts,
> versions, tallies or percentages — everywhere else stays qualitative ("~190k rows") and links here.
>
> **The numbers now live in `_status/`, one file per topic, each with one owner.** You *read* through this
> index; you *write* only your own file. That is deliberate: two people share this OneDrive folder, and one
> shared numbers file meant every task collided on it. → `09_conventions.md` §13
>
> **All figures verified 2026-07-30** against the workbooks and the filesystem, unless marked otherwise.

## Where each number lives

| File | Holds | Owner |
|---|---|---|
| **`_status/sources.md`** | the source-synthesis register · screening tallies (`I` / `PI` / …) · the `06_` / `09_` / `10_` table shapes | whoever ingests a source |
| **`_status/era.md`** | **the three ERA versions in play** (built / released / ingested) · row and study counts · the `10_FOMD_ERA_readme` crosswalk tallies | Lolita |
| **`_status/extraction.md`** | the 86 manual-extraction workbooks, by extractor and by `ss_id` | the extraction team |
| **`_status/code.md`** | script line counts, output file sizes, what runs and what is an empty stub | Andrea |
| **`_status/ontology.md`** | ontology sheet and term counts | Lolita |
| **`_status/project.md`** | deliverables and dates · the ownership table · known housekeeping items | Lolita + Andrea |

Everything at once:

```bash
cat knowledge/_status/*.md
```

## The four things most often asked

Stated here as pointers, not as figures — so this index never goes stale and never needs a shared write:

- **Which ERA version is where** — three are in play at once, and they differ by several releases' worth of
  fixes. → `_status/era.md`, then `sources/ERA/02_era_handoff.md`
- **How much manual extraction is left** — the `PI` backlog versus the workbooks that exist.
  → `_status/sources.md`, `_status/extraction.md`
- **Whether the `10_` template has data in it yet.** → `_status/sources.md`
- **Which analysis scripts actually run.** → `_status/code.md`

## Updating a number

1. Edit **only** the `_status/` file that owns it. If your change spans two files, you probably have two
   changes.
2. Re-date the "verified" line at the top of that file.
3. Use a **surgical edit**, not a whole-file rewrite — see `09_conventions.md` §13.
4. Add a new file to `_meta/log/` — one file per entry, never a shared list. → `_meta/UPDATE_LOG.md`

If a number doesn't fit any of the six files, it may not belong in this base at all — check
`_meta/MAINTENANCE.md` ("What NOT to put here") before adding a seventh.
