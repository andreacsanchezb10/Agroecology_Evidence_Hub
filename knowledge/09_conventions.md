# 09 — Conventions

Cross-cutting working rules. The **prohibitions** live in `CLAUDE.md` (the five golden rules); this doc is
the practical detail behind them plus the R-and-shell conventions of this workspace.

## 1. Output flow — never write into a shared data folder

Scripts write to **`C:/Users/mlolita/Downloads/`** first. A human reviews and moves deliverables into the
data folder (e.g. `ERA/data/`). Rationale: the data folders sit in shared OneDrive, and a bad run must never
clobber a reviewed deliverable. Keep the Downloads filename descriptive; the human renames on move.

## 2. Shared workbooks and the ontology are read-only

See `CLAUDE.md` rule 2 and `06_ontologies.md` for the full rule, the permitted alternatives, and the incident
that prompted it. Short version: **suggest, never write.**

## 3. Verify every change against the data

Before calling anything done: check counts against expectation, **and inspect the actual rows you touched** —
not just that the code ran. "The script finished" is not verification. Pick fresh examples you didn't use
while writing the fix. Each source's harmonization doc lists its own spot-checks.

## 4. Fixes live in code; outputs are disposable

Never hand-edit an output CSV. Every correction goes into the script so it survives the next regeneration.
Outputs are reproducible artifacts; the script plus the ontology are the source of truth. Large derived CSVs
are `.gitignore`d and regenerated, not tracked.

## 5. Versioning

Each harmonized deliverable carries a version tag (`vNN`), bumped once per release and recorded in that
source's changelog. One release = one coherent set of changes plus a verification pass. **Don't bump the tag
without running and verifying**, and don't ship without updating the counts in the owning `_status/` file.

## 6. One row = one comparison

The shared shape: one row per Control-vs-Treatment outcome comparison, `C_…`/`T_…` paired columns,
standardized values from the ontology. Details and serialization rules: `05_data_schemas.md`.

## 7. Don't touch what you don't own

FAO/SPAM classifications, externally-maintained fields, and other people's review columns are passed through
untouched unless the task is explicitly about them. When in doubt, leave a field alone and say so.

## 8. Numbers live in one place — read via `01_status.md`, write only your own file

Every count, version, tally and percentage belongs in the **`_status/`** set and nowhere else. Elsewhere stay
qualitative. This is the main defence against the staleness that plagued an earlier version of these docs,
where version numbers appeared in seven files and drifted apart.

`01_status.md` is the **index you read** — it says which of the six `_status/` files owns each kind of number.
You **write only the file you own** (each names its owner at the top). One shared numbers file meant every
task, on any topic, ended by writing the same file; with two people on one OneDrive folder that guaranteed
collisions. Splitting it keeps the single reading entry point and removes the shared write. → §13

## 9. The evidence base is global, not African

The Hub's scope is worldwide. ERA is Africa-only, so today's data is African — a fact about *one source*.
Don't phrase the research question, the docs, or column semantics as African, and don't hard-code region
assumptions. Say "in ERA" when a fact is ERA-specific. → `02_the_project.md`

## 10. Analysis method is Andrea's

Effect-size choice, pooling rules, variance handling, exclusions — hers. Don't write house analysis guidance;
ask, then record her answer attributed to her. Documenting *data limitations* is different and encouraged
(`sources/ERA/04_era_open_issues.md`). → `08_effect_sizes_and_analysis.md`

## 11. Communication with collaborators

Emails and messages are written in a natural human voice — short, direct, no AI boilerplate. State what was
done, what was found, and what needs their decision.

## 12. ⟳ Write down what you learn

Finishing a task includes updating the mapped doc and adding **one new file** to `_meta/log/` (named
`YYYY-MM-DD-NN-short-slug.md`). The trigger is **any durable new knowledge**, not just code changes. Routing
table in `CLAUDE.md`; full protocol in `_meta/MAINTENANCE.md`; the one-file-per-entry convention and why it
replaced the single shared list in `_meta/UPDATE_LOG.md`.

## 13. ⚠️ Several people share this one OneDrive folder

**This folder is synced to every team member's machine.** It is one logical folder replicated to N machines —
not N copies to be merged. Everything below follows from that, and it is the main way work gets silently lost
here.

**The failure mode, precisely.** OneDrive never merges: two people editing one file resolves as
last-writer-wins, or it drops a `-Copy` conflict file. And an AI assistant's edits can replace **whole
files** — so what would be a text merge conflict becomes a *clobbered document*. The loser's paragraph
doesn't conflict; it ceases to exist, and nothing records that it did. A quieter second failure: a session
**reads stale numbers** because OneDrive hasn't pulled the other machine's change yet, then acts on them.
Nobody overwrote anything — the conclusion is just wrong.

**Git is not the merge mechanism between us.** We already see the same files, so git's only value in this
folder is **history and recovery**, never coordination. Coordinate by owning different files (below).

### The five working rules

1. **Surgical edits only, never whole-file rewrites, on anything in `knowledge/`.** A targeted
   find-and-replace *fails loudly* when someone else has changed that passage — and that failure is the
   point. Re-read the file and redo the edit; never force it through. A whole-file write would have
   succeeded, silently, destroying their work.
2. **Write only what you own.** `sources/<X>/` belongs to whoever owns that source; every `_status/` file
   names its owner at the top; `08_effect_sizes_and_analysis.md` Part B is Andrea's alone. The genuinely
   shared docs (`00`, `02`–`09`, `CLAUDE.md`) change rarely — **say in the team chat before editing one.**
3. **Never run two Claude sessions against `knowledge/` at once.**
4. **Check OneDrive shows synced** before editing a shared doc, and let it settle afterwards. If a count
   looks wrong, confirm you're synced *before* investigating.
5. **Only ONE machine runs git commands in this folder — Lolita's (`mlolita`).** `.git/` sits *inside* the
   synced tree, so OneDrive replicates `index`, `refs/` and `objects/`. Two people running git around the
   same time means OneDrive copying git internals mid-write, which corrupts the repo — phantom uncommitted
   changes, "index file corrupt", detached HEAD. Symptoms look like data loss and are hard to unwind.
   **This is now enforced, not just agreed** (below), so nobody has to remember it. If you need something
   committed, ask Lolita. (The structurally clean fix is a working copy outside OneDrive, but that collides
   with the hardcoded absolute paths above — so the designation is the practical rule.)

### What was changed on 2026-07-30 to make collisions structurally rare

- **The two collision points were removed.** Every task used to end by writing `01_status.md` *and*
  `_meta/UPDATE_LOG.md`, so two people collided even on unrelated work. Now: numbers live in six owned files
  under `_status/` read through the `01_status.md` index (§8), and the log is **one file per entry** in
  `_meta/log/` — separate filenames cannot overwrite each other (`_meta/UPDATE_LOG.md`).
- **Rule 2 is enforced mechanically, not by prose.** `.claude/settings.json` files at the **Hub root**, in
  **`Agroecology_Evidence_Hub/`** and in **`ERA/Script/`** carry `deny` rules on the master workbooks and
  ontology (`02.metadata_structure/`), `03.extraction/`, `01.SOMD/`, `ERA/data/`, `protocol/` and
  `partners/`. The rules use user- and cwd-independent absolute patterns
  (`//c/Users/*/*/*/Agroecology_Evidence_Hub/…`), so they hold for **Andrea's differently-named root** too,
  and are checked in so every teammate inherits them. **Verified by probe on 2026-07-30:** writes to a path
  of that shape are refused. If a write there fails, the protection is working — **don't route around it.**
- **`knowledge/` is now committed to git**, so a clobbered doc is recoverable.
- **Each session identifies who you are, and the git rule enforces itself.** Two hooks in the same three
  settings files:
  - a **`SessionStart`** hook reads `%USERNAME%` and states, at the top of every session, who you are, whether
    you are the git machine, and the shared-folder rules — and passes the same text to Claude as context, so
    the assistant knows the constraints before it does anything. **Detected, not asked:** a question can be
    answered wrongly, skipped, or simply not asked, whereas the username is unambiguous
    (`mlolita` vs `andreasanchez`).
  - a **`PreToolUse`** hook on `Bash|PowerShell` **refuses any git command when `%USERNAME%` is not
    `mlolita`**, with an explanation pointing here. So a teammate's Claude cannot corrupt the repo even if it
    never read this file. **Verified 2026-07-30:** the guard denies `git status`, `git -C x log`, chained
    `… && git push` and bare `git` for a non-owner, allows them for `mlolita`, and does not false-positive on
    `digital`, `legit`, `cat repo/.git/config` or `Rscript`; a sentinel confirmed the hook actually fires.
  - **To change the designated machine**, edit `$owner='mlolita'` in the `hooks` block of all three
    `.claude/settings.json` files. It is deliberately one literal, not a lookup, so it is greppable.

**What this does NOT cover.** The deny rules stop *Claude's own* edits, not an R script's `saveWorkbook()` —
the incident behind rule 2 was a script, so rule 2 still binds every script you write. And nothing above
stops a teammate's Claude from legitimately but over-enthusiastically **rewriting a doc it had every right to
edit**; rule 1 plus git history is the only guard there, and it is a soft one.

**Recovery.** Every file, including the binary workbooks, has **OneDrive version history** — right-click →
Version history. That needs no setup and works for everyone. `knowledge/` additionally has git history now,
on the designated git machine.

**Check for conflict copies** — if one exists, the base has two contradictory versions and rule 8 has broken
silently:

```bash
find knowledge -iname "*-Copy*" -o -iname "*conflict*" -o -iname "*-DESKTOP-*" -o -iname "*-LAPTOP-*"
```

**Binary workbooks are already safe** by rule 2 (nobody edits them), now backed by the deny rules, plus
Excel's own file locking. They can never be merged, so that prohibition is doing real work — don't relax it.

**If the team grows past ~3 Claude users**, the structurally correct answer is to move `knowledge/` out of
OneDrive into a git repo each person clones, so git actually merges. That costs every teammate a clone plus a
per-user `CLAUDE.md` pointer, so it was deliberately not done yet.

---

# Working with the R scripts here

This is a **data-and-analysis workspace, not a software project.** There is no build, no test suite, no
`renv.lock`, no `DESCRIPTION`. "Running the project" means opening `Agroecology_Evidence_Hub.Rproj` in
RStudio and running scripts interactively, top to bottom, reading the sanity-check output as you go.

## ⚠️ Absolute paths, and two different folder names

**Every script hardcodes absolute OneDrive paths for one person's machine.** Check and adjust the path block
at the top before running anything.

Worse, **two spellings of the root folder are in circulation**:
- Lolita's: `…/OneDrive - CGIAR/Alliance-Agroecology **Knowledge** Hub - General/`
- Andrea's scripts: `…/OneDrive - CGIAR/Alliance-Agroecology **Evidence** Hub - General/`

Plus older strings in legacy scripts: `Agroecology_Knolwedge_Hub` (typo included) and `Bioversity`. A script
that fails immediately with "cannot open file" is almost always this, not a missing file.

## The check-as-you-go style is deliberate

Lines like `sort(unique(df$col))` scattered through the scripts are **validation, not dead code** — they are
how the author confirms a join or a recode behaved. Likewise the `# Quick checks`, `## TO CHECK:` and
`### ARREGLAR` markers flag open questions in place. **Don't delete them to "tidy up".** If you add
processing, add the matching check.

## Repeated-slot loops

Columns like `crop01…crop15`, `country01…country05`, `chem_subpractice01…03` are looped with
`sprintf("%02d", 1:N)`. Nutrient columns (`fert_inorganicN/P/K/P2O5/K2O`) stay separate by design — don't
merge them.

## Naming hazards

- **Don't shadow helper functions with loop variables.** In `era_harmonize.R`, `nc` is a numeric-coercion
  *function*; a fix once assigned `nc <- <vector>` inside a loop and the whole run failed later at an
  unrelated line. Use dotted, unique names for temporaries (`.arm`, `.pc`, `.xcs`). Same care for `nn`,
  `norm_star`, `coalesce_chr`, `samp_clean`.
- `study_id` / `ss_id` truncations keep trailing commas and spaces — **never "clean" an ID**.
  → `03_somd_and_fomd.md`
- `FOMD` / `fomd` in filenames and object names is a correct namespace prefix — **never rename it**.
  → `03_somd_and_fomd.md`

## Shell gotchas (Git Bash on Windows)

- **Always quote paths** — the root folder name contains spaces.
- Heredocs (`<<'EOF'`) can collapse `\\` to `\`, breaking R regexes. Prefer writing R scripts with a file
  tool, or use character classes (`[.]`, `[*]`) instead of `\\.`, `\\*`.
- Never end a backgrounded command with a stray `&` inside another background wrapper — it detaches the real
  process and you get a false "completed" while nothing ran.
- Long runs: launch in the background and wait for completion rather than polling.

## Before a long run, parse-check

A syntax error found after 20 minutes is 20 minutes wasted:

```bash
Rscript -e 'invisible(parse("path/to/script.R")); cat("PARSE OK\n")'
```
