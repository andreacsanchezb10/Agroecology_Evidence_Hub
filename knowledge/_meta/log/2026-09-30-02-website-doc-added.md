2026-09-30 — **The website now has a doc and a `_status/` owner** — new `website.md`, new
`_status/website.md`; one-line registrations in `CLAUDE.md`, `01_status.md`, `00_START_HERE.md`; "six
`_status/` files" corrected to seven in `CLAUDE.md`, `01_status.md`, `09_conventions.md`.

Closes the gap named in `2026-09-30-01-website-vendored-dependencies.md`: the public site had no document
anywhere in `knowledge/` and no `_status/` figure, so everything about it lived in `website/README.md` and
the log.

**`website.md`** — qualitative only, per golden rule 4. What the site is and deliberately is not (no server,
no framework, no build step beyond one Python script, because the Hub has no web developer); that it is not
the Stats4SD platform; where it lives and that pushing `main` publishes; how `build.py` reaches
`03.fomd10_clean`; and the three rules enforced in code — everything served from the repository, a synthesis
is published unless named in `SKIP_SOURCES`, and the build refuses a dataset too large to load. Plus an
ownership table for what is still open.

Three consequences of the architecture written down there because they are easy to get wrong:

- The site's data is a **committed snapshot**, not a live view of `03.fomd10_clean`. Nothing warns when it
  has drifted; it has already been stale once.
- The site **computes its own effect sizes** from the paired `C_…`/`T_…` means rather than reading the
  effect-size columns, so it escapes bugs in those scripts but also their fixes. It shows a percentage
  change, **not** an analysis Andrea has ratified.
- **Downloads are always English** whatever language the page is in, so everyone works from one vocabulary.

**`_status/website.md`** (seventh `_status/` file, owner Lolita) — what is published, the file sizes, why ERA
is not on the site, and the boundary coverage it would need. Added rather than writing website figures into
`_status/code.md`, which is Andrea's. `01_status.md` said to check `_meta/MAINTENANCE.md` before adding a
seventh; "What NOT to put here" excludes budget figures and partner-owned platform internals, neither of
which these are, and the site is a distinct deliverable with a distinct owner.

The user asked for this as a `.md`, not a folder — so no `website/` directory under `knowledge/`, matching
`analysis.md` and `control_treatment_scoring.md`. Not numbered `10_`, which would read as the `10_` schema.

**Note for whoever edits next:** a guard in my first patch script compared against the wrong line and
reported the `CLAUDE.md` and `01_status.md` rows as "already present" when they had not been written. Both
were added on a second pass and verified by grep. When scripting a surgical edit, check for the text being
**added**, not the anchor it goes after.
