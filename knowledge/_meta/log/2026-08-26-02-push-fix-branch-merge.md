2026-08-26 — Fixed a blocked GitHub push and reconciled a two-machine branch fork. No docs updated
(process/history note only; see open items below for follow-up someone should do).

**Push blocker (twice):** `git push` was rejected by GitHub's 100 MB file-size limit for two different
generated `fomd10` CSVs (`fomd10_MD_Rosen_24_Effec_Sc.csv`, 378 MB; `fomd10_clean_MD_Rosen_24_Effec_Sc.csv`,
551 MB) that got swept into commits via `git add -A`. Both times the oversized blobs were only in local,
never-pushed commits, so fixed without touching shared history: first via `git reset --soft` + re-add
(single offending commit), second via `git filter-branch --index-filter 'git rm --cached ...' -- <base>..HEAD`
(oversized files were 2 commits deep, including a merge commit, so a plain reset would have meant redoing
merge-conflict resolution).

**Branch fork:** `origin/main` had a commit (`fcbeb4c`, message "r") authored by Andrea on 2026-08-12 —
almost certainly pushed from a different machine and never pulled here, so today's local work forked off
the same shared parent (`6a9dbdc`) instead of building on it. Real overlapping edits existed on both sides
for `01_FOMD_ontologies.xlsx`, `04_FOMD_screening.xlsx`, `10_FOMD_metadata_synthesis_short.xlsx`, and 8
extraction `.xlsm` files under `01_verified_papers/MD_Paut,_24_A glo_Sc/`. Andrea chose (after being told
this discards content, not files) to **keep the local Aug 26 version for all of those**, discarding
whatever was uniquely added on Aug 12 for those specific files. That Aug 12 content isn't gone — it's still
reachable in git history at commit `fcbeb4c` (now merged as a parent of `2ac67dd`) if anyone ever needs to
recover it.

Also resolved via merge: 5 extraction files (Alam, Kaur, Mutsa, Banti `.xlsm`, and the old
`fomd09_clean/MD_Paut,_24_A glo_Sc.csv`) were deleted on the Aug 12 side — Andrea confirmed these were
intentional exclusions, so the deletions were accepted.

**Open items for whoever touches this next:**
- `.gitignore` still lists the *pre-reorg* output folder names (`fomd10_formating/`, `fomd10_clean/`,
  `fomd10/`). Today's work renamed these to `01.fomd09_clean/`, `02.fomd10_formated/`, `03.fomd10_clean/`
  (part of the pairing-refactor reorg — see also the note on `fun_pairing_CT.R` co-editing). The mismatch is
  *why* the two oversized CSVs above weren't ignored in the first place. Needs updating to the new names, or
  a broader `02.FOMD/04.metadata_effectsize/**/*.csv` pattern, before the next commit touches that folder.
- `02.FOMD/01.metadata_harmonisation/02.metadata/04.added_to_06_FOMD_metadata_original_long/added_to_10_MD_Rosen_24_Effec_Sc_new.R`
  (~line 1971 on) still calls `apply_lookup_ontologies(ref = ..., key_col = ..., ...)` — the pre-refactor
  signature. The current `apply_lookup_ontologies()` in `fomd_fun/fun_lookup_ontologies.R` now takes
  `path.metadata.structure`/`sheet_name` instead of `ref`; the old-style function was preserved under the
  new name `apply_lookup_ontologies_ERA()`. This ERA script's calls will error as written — likely just not
  re-run since the refactor landed. Not fixed here (out of scope), flagging so it isn't a surprise later.
