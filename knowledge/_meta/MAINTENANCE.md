# Maintenance — keeping this knowledge base alive

These docs are only useful if they stay true. The rule: **a task isn't done until the knowledge base reflects
it.** This file explains how that works, for both AI assistants and people.

## Why a protocol instead of "remember to update the docs"

Docs rot because updating them is a separate, forgettable step. So we make it part of *finishing the task*,
and we route each kind of change to a specific doc so nobody has to guess where it goes. Because `../CLAUDE.md`
auto-loads, an assistant reads the protocol every session and applies it without being asked.

## The protocol — run at the end of every task

### 1. Did you learn or change anything durable that isn't already written here?

The test is **not** "did I change code". It is: **would the next person, or the next session, be better off
knowing this?**

| Situation | Counts? |
|---|---|
| Shipped a new harmonized version | **Yes** — the source's changelog **and every affected count in `../_status/`** |
| Learned what a raw field actually means, or that a source lacks something | **Yes** → that source's `00_…_overview.md` |
| Found a data-quality problem but didn't fix it | **Yes** → `04_…_open_issues.md`. Unfixed ≠ unrecorded |
| Fixed something already listed as open | **Yes** → strike it through there |
| A decision was made — including "defer it" or "leave as is" | **Yes** → `../09_conventions.md`, or the source's own doc |
| A new source synthesis arrived or advanced | **Yes** → copy `../sources/_TEMPLATE.md`, register in `../_status/sources.md` |
| A doc turned out to be wrong or stale | **Yes** — fix it; don't work around it |
| A gotcha cost you time (a shell quirk, a variable clash, a path mismatch) | **Yes** → `../09_conventions.md` or the source's harmonization doc |
| A number worth remembering | **Yes, in `../_status/` only** — in the one file that owns it, if it's a property of the data, not of your task |
| How you did the task, scratch scripts, conversation back-and-forth | No — see "What NOT to put here" |

If genuinely nothing → nothing to update. Otherwise → step 2.

### 2. Route it, and make a surgical edit

Add or adjust the relevant lines. **Don't rewrite a doc for a small change.**

| Change | Doc | Example edit |
|---|---|---|
| Shipped a version | the source's `03_…_changelog.md` **+ the owning `../_status/` file** (every affected count, incl. the version table) | Add a `## vNN` section: what changed + verified counts |
| Learned something about raw data | that source's `00_…_overview.md` | "cc has no treatment key in `Data.Out`; links via `MT.Out`" |
| Schema or column change | `../05_data_schemas.md` | note the family and the rule, never the full column list |
| Ontology mapping or governance change | `../06_ontologies.md` | update the sheet description; note where it was applied |
| New cross-cutting decision | `../09_conventions.md` | add a numbered rule |
| New source-specific decision | that source's `01_…_harmonization.md` | describe the rule **and why** |
| Resolved / found an issue | that source's `04_…_open_issues.md` | strike through, or add with its impact |
| Something about the extraction workflow | `../07_extraction.md` | — |
| Something about the effect-size / analysis code | `../08_effect_sizes_and_analysis.md` **Part A** | factual only |
| An analysis method or pooling rule | `../08_effect_sizes_and_analysis.md` **Part B — only if Andrea decided it** | record her rule, attributed to her |
| A data *limitation* relevant to analysis | the source's `04_…_open_issues.md`, **not** Part B | "Crop Yield spans 17+ units; DM vs fresh not convertible" |
| Project scope, partners, deliverables | `../02_the_project.md` | — |
| Added a source | `../sources/_TEMPLATE.md` → `sources/<name>/`; register in `../_status/sources.md` + `../00_START_HERE.md` | — |

### 3. Always add one new file to `log/`

`log/YYYY-MM-DD-NN-short-slug.md`, containing `YYYY-MM-DD — <what changed> — <docs updated>`. Even for small
changes. **One file per entry — never a shared list, never edit or delete someone else's entry**; the log is
how someone reading a pre-correction artefact learns the vocabulary or numbers shifted. `NN` is a two-digit
sequence within the day; if two people pick the same number both files still exist, which is the point.
Convention and the reason it replaced a single appended list: `UPDATE_LOG.md`.

Prefer facts over narration. These docs say what *is* true now; the log carries the history.

## One owner per fact

The single most important structural rule here, and the fix for this base's worst historical failure — the
same fact stated in seven places and drifting apart.

| Fact class | Sole owner | Everyone else |
|---|---|---|
| Rules and prohibitions | `../CLAUDE.md` | "see rule N" |
| **Any number, version, count, tally, percentage** | **the owning `../_status/` file** (indexed by `../01_status.md`) | qualitative only ("~190k rows") |
| Term definitions | `../00_START_HERE.md` (short) → `../03_somd_and_fomd.md` (long) | link |
| Reading paths | `../00_START_HERE.md` | link |
| Per-column meanings | the workbooks' own `_readme` sheets | families and rules only |
| Method normativity | Andrea, in `../08_effect_sizes_and_analysis.md` Part B | "ask her" |
| Protocol content | `protocol/Knowledge Hub Protocol.docx` | pointer + its draft date |

## Terminology check — run this after editing

The drifted use of "FOMD" to mean "the schema" was corrected on 2026-07-30
(`../03_somd_and_fomd.md`). It will creep back unless checked. Grep `knowledge/` for:

```
"FOMD schema"   "FOMD-format"   "FOMD format"   "to FOMD"   "shared FOMD"
"FOMD ontology"   "FOMD manual extraction"
```

**Expected residual: nothing.** Legitimate hits look like *filenames and object names* —
`01_FOMD_ontologies.xlsx`, `09_FOMD_*.xlsm`, `fomd_fun/`, `fomd10_*` — which are correct namespace prefixes
and **must never be renamed**.

## What NOT to put here

- Conversation-only detail, one-off scratch scripts, or anything already recorded in the code.
- **Numbers, anywhere but `../_status/`.**
- Copies of the workbooks' `_readme` sheets, or ontology term lists — they rot, and a copy invites someone to
  edit the copy instead of the source.
- Restatements of the protocol beyond what's needed to read the workbooks.
- Normative analysis method not written by Andrea.
- Budget figures, individual workload, contact details, partner-owned platform internals.
- Secrets, credentials, raw data dumps.
- Long AI-style essays. Keep it terse and checkable.

## For humans

Same rule, less ceremony: if you change the data, a script, or a decision, drop a line in the mapped doc and
a new file in `log/`. If you're not sure which doc, put it in the log and let the next pass file it.

## Health check — occasionally

- Do the counts in `../_status/` match reality? Does every file still carry a dated "verified" line?
- **Is any number living outside `../_status/`?** Grep for version tags and thousands-separated figures.
  `../01_status.md` is an index — if a figure has crept into it, move it into the owning file.
- Is the latest built version actually **released** (moved to the source's data folder), or still in
  `Downloads/`? Both facts should be stated — people can only open what's been moved.
- Do the three pointer `CLAUDE.md` files still exist? They must be at the **Hub root**, in **`ERA/Script/`**,
  and in **`Agroecology_Evidence_Hub/`**. Claude Code only auto-loads a `CLAUDE.md` at or above the working
  directory — without these, `../CLAUDE.md` here never loads and the rules are invisible. See
  `UPDATE_LOG.md` 2026-07-30.
- Has the drifted "FOMD = schema" usage reappeared? Run the grep above.
- Does each `sources/*/` have its doc set, and is every source in `../_status/sources.md`?
- Any `04_…_open_issues.md` item silently fixed but not struck through?
- Has anything crept in describing the **Hub** as Africa-only? (It isn't — only ERA is.)
- Has anyone written normative method into `../08_effect_sizes_and_analysis.md` Part B who isn't Andrea?
- **Any OneDrive conflict copies in `knowledge/`?** Two people share this folder, so a simultaneous edit can
  leave a second contradictory copy of a doc — which breaks "one owner per fact" silently.
  Run: `find knowledge -iname "*-Copy*" -o -iname "*conflict*" -o -iname "*-DESKTOP-*" -o -iname "*-LAPTOP-*"`
  Expected: nothing. → `../09_conventions.md` §13
- **Is `knowledge/` still under version control?** It was committed on 2026-07-30, on the designated git
  machine only. `git log --oneline -1 -- knowledge/` should return a commit. → `../09_conventions.md` §13
- **Do the three `.claude/settings.json` files still exist** (Hub root, `Agroecology_Evidence_Hub/`,
  `ERA/Script/`), still list the protected paths, and still carry both hooks — the `SessionStart` identity
  banner and the `PreToolUse` git reminder? They are what makes rule 2 enforced and rule 5 remembered.
  (Since 2026-08-26 the git hook reminds instead of refusing — any team member may run git, one at a time.)
  → `../09_conventions.md` §13
- **Is the log still one-file-per-entry?** A reappeared single appended list in `UPDATE_LOG.md` means the
  collision is back.

## Optional: a Claude Code reminder hook

The protocol above is the real mechanism. If you also want a mechanical nudge at the end of a session, a
**Stop hook** can print a reminder — it cannot know what changed, so it's a backstop, not automation. Ask
before adding hooks; they affect every session. Use the `update-config` workflow to wire one up.
