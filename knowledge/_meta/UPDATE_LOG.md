# Update log — how it works now

**The log is the `log/` folder next to this file. One file per entry.** There is no shared list to append to
any more.

## Why it changed (2026-07-30)

This file used to be a single list with newest at the top. Two people share this OneDrive folder, so two
sessions finishing work at the same time both wrote a new first line and **one of them was silently lost** —
every time. Separate files can't overwrite each other, because they aren't the same file.

## Writing an entry

Create **one new file** in `_meta/log/`:

```
_meta/log/YYYY-MM-DD-NN-short-slug.md
```

- `YYYY-MM-DD` — today.
- `NN` — a two-digit sequence **within that day**, counting up. Look at the folder, take the next number.
  If someone else took the same number, you both still have a file and nothing is lost — that's the point.
- `short-slug` — kebab-case, e.g. `era-v50`, `ontology-ownership-corrected`.

The content is the same one-liner the old log used: `YYYY-MM-DD — <what changed> — <docs updated>`. Longer is
fine when the change deserves it. **Never edit or delete someone else's entry** — the log is history, and a
pre-correction entry is how a reader learns the numbers or vocabulary later shifted.

## Reading the log

Newest first:

```bash
ls -r knowledge/_meta/log/
```

Everything at once:

```bash
cat knowledge/_meta/log/*.md
```

## Where the old entries went

All 11 pre-existing entries were split into individual files, content unchanged. The two that carried no date
(`v46`, `v47`) are `undated-era-v46.md` and `undated-era-v47.md`, each marked as predating the dated log.

Full protocol: `MAINTENANCE.md`. The rules: `../CLAUDE.md`.
