2026-10-01 — **ERA harmonization v52: explicit "no application" labels on the blank control arm, plus the mh
tillage recovery (Andrea's Kenya review)** — `_status/era.md`, `sources/ERA/03_era_changelog.md` (v52 section),
`sources/ERA/04_era_open_issues.md` (two new section-A items, four new section-C items),
`sources/ERA/01_era_harmonization.md` (explicit-controls section, companion files, two gotchas).

**Result:** `Downloads/ERA_crop_data_short_v52.csv`, 166,297 rows / 1,808 studies / 342 columns, built
2026-10-01 16:06 (34 min). Row count, study count and every outcome value identical to v51. **54 rows in 3
studies swap C/T** (see below). Not yet moved to `ERA/data/`. Reply for Andrea:
`Downloads/ERA_v52_email_to_Andrea.md` (plain-language, matches her own format);
`ERA_v52_reply_to_Andrea.md` is the longer point-by-point version.

**Why.** Andrea, analysing the Kenya subset of v51, found 4,002 rows / 51 studies where one arm has a
subpractice and the other is blank, and 181 rows / 17 studies where the arms are identical in every
subpractice column. Globally the first is 46,236 rows / 526 studies.

**The useful discovery:** ERA already owns the "no application" vocabulary. `ERA/dataverse_files/03g.
Practice_Codes.tab` defines an "h" series of control terms and `MT.Out$T.Codes` already carries the codes on
the arms. The script had never read either. So v52 mostly recovers ERA's own labels; only "No Residues
Applied" and "No Water Harvesting" are new terms (Lolita's call, 1 Oct: do not reuse ERA's "Crop Residues
Removed", which asserts more than a blank tells us).

**Changes in `era_harmonize.R`** (v51 backup: `Downloads/era_cache/inspect/era_harmonize_v51_backup_2026-10-01.R`):
- Step 5b2 reads `03g. Practice_Codes.tab`; `T.Codes` / `Base.Codes` added to `needed_cols` and carried as
  scratch columns, dropped before the write.
- Step 6g (before the Tier-1 reorientation): snapshot `HASV0` / `VALDIFF0`, then fill the blank arm by code,
  by raw level name, then by inference, both arms symmetrically. 76,942 arms labelled, 27,424 refused.
- The v32/v34 input rules now read the snapshot, so their row sets and flip counts are unchanged.
- mh tillage derived from `Till.Codes` (`Till.Practice` does not exist in that snapshot).
- New provenance columns `C/T_subpractice_filled`; new companion `subpractice_fill_vNN.csv`.

**Two traps worth remembering**, both caught before shipping:
1. In ERA `no-till` is a conservation *treatment* (b38), not an absence. The first pattern matched it and would
   have written "Conventional Tillage" onto the wrong arm. Always test absence patterns against the real
   distinct level names first. Same for component separators: "No manure +P" received P.
2. `.l_rev` (re-orients a no-liming treatment arm) reads the live column, so the new labels made it fire on
   195 extra rows and swapped their control and treatment — 195 inverted effect-size signs. Caught only by
   diffing every outcome value against v51; `ct_reoriented` alone would not have shown it, because a flipped
   row also swaps its join key and simply fails to join. Suppressed; those 195 rows are Andrea's decision.

**Evidence from the papers:** NN0261 Ayuke et al. 2011 Table 1 p. 150 (control's organic input "None");
NJ0109 Micheni et al. 2016 Table 2 p. 5 (farmer practice vs recommended tillage, flattened at extraction);
DK0129 Ngetich et al. 2014 p. 290; LM0265 Recke et al. 1997 p. 93 (0 vs 5 t/ha FYM, levels attached to the
wrong arms in ERA).

**Diagnosed, not fixed:** the multi-site join bug (`Fert.Method` / `Res.Method` join on `Site.ID` while
`Data.Out` holds a `..`-concatenation — 6,389 raw rows, ~204 studies; CJ0146's biochar is the visible symptom)
and the intercrop / crop-sequence arms that need a positive label rather than an absence. Both in
`04_era_open_issues.md` section A, proposed for v53.

**Final numbers** (build 20:18, 26.2 min, 350 columns). One-arm-empty 46,236 -> **19,051**, of which
**18,556 are explained by the new background columns** and only **495 are genuinely unexplained**
(tillage 361, intercrop 99, residues 24, fert 11). Kenya crop 4,058 rows / 53 studies -> 647 / 12, with
**4 rows in 1 study** unexplained. 84,219 arms labelled. **378 rows change C/T**, every one matching a v51
row with the arms swapped; `ct_reoriented` 2,438 -> 2,748. Every outcome value identical to v51 on all
165,919 joined rows.

**Two decisions by Lolita, 1 Oct, and the reasoning that drove them.**

1. **Background management belongs in its own row-level column, not in an arm's.** The first attempt wrote
   it into the blank arm. On **18,522 of 18,556 rows (99.8 %)** the other arm still showed only its
   distinguishing practice, so CJ0039 read control "Inorganic K..Inorganic P" against treatment "Manure",
   implying the treatment got no K or P when it got all three. **A property of every arm cannot live in one
   arm's column.** Two further reasons settled it: the arm columns are shared with ten other source datasets
   and ERA cannot redefine them alone; and the agroecology-gradient scoring needs each arm's full practice
   set read as `arm + background`, on the same basis for both arms, which an asymmetric column makes
   impossible. Eight `background_<family>_subpractice` columns, populated for every row of a study that has
   them.
2. **Intercrop and rotation controls are re-oriented.** 390 arms (249 intercrop, 141 crop_seq) where the
   blank arm was the CONTROL and its own crop list showed several crops. The convention is confirmed in the
   data (4,793 intercrop comparisons with monoculture as control, none reversed), so these are labelled and
   the Tier-1 rule flips them.

**The error this uncovered, which shipped in v51 and earlier.** The v32 Tier-2 rule wrote
"No Fertilizer Application" on a blank arm with no check on whether the study applied fertiliser to every
plot. Its own comment claimed "not constant background"; no such test existed. **14,334 fertiliser arms
carried that false label in v51 and every earlier version.** fert/ph/chem now consult the background column.
Flip sets deliberately untouched. **The general lesson: a rule whose comment states a precondition is not
evidence the precondition is tested.**

**A measurement lesson.** I told Lolita reverting the background fill would push one-arm-empty to ~19,400,
then a build appeared to show fertiliser at 1,804 and I could not reconcile it. Both were right: the real
figure is 13,286, and 1,804 was the false "No Fertilizer Application" labels masking it. **Simulating a
revert on a finished file is not the same as rebuilding** — a suppressed rule downstream can refill what you
think you removed.

**Four residual causes, each diagnosed against the save point in seconds rather than by rebuilding.** This
is the payoff from the `.rds` checkpoint and it changed the release:
1. **Trees are not in ERA's crop table.** All 63 species blocking the intercrop/rotation label were
   agroforestry species absent from `03e. EU_Codes`, which covers crops. Resolved by genus
   (`.NFIX_GENUS`): nodulating Fabaceae and the actinorhizal *Alnus*/*Casuarina* fix; the Caesalpinioid
   legumes (*Senna*, *Cassia*, *Tamarindus*, *Piliostigma*, *Acrocarpus*, *Delonix*) are legumes that do
   **not** nodulate. 24 species still unresolved over 86 occurrences → `nfix_unresolved_vNN.csv`, and those
   arms take "Intercrop (Unspecified)" rather than staying blank.
2. **`residues_N` / `residues_OC` were evidence of nothing.** Properties of the study's residue material,
   not of the arm: filled on **74 %** of arms with no residue practice against **12 %** of arms that have
   one. Dropped from the receipts.
3. **`tillage_method` is identical on C and T in 100 %** of the one-sided rows. It lists the trial's
   implements, not the arm's, so it can neither prove this arm was tilled nor name its practice. Dropped.
   **The general test worth reusing: a receipt column must be arm-specific. Check that before trusting it.**
4. **Route 1b.** The guard refuses an absence term when the arm's own codes name a practice — and then
   wrote nothing. Naming it from those codes clears all 847 varietal-crop arms, which carry h55.2 (the
   absence lookup only knows h55).

**The trade-off, stated for Andrea.** Filling blanks moves rows from "one arm empty" into "nothing to
compare". On her own identical-C/T query (Kenya crop, 19 columns) 312 rows / 23 studies → **235 / 19**:
DK0129, EO0145, NJ0041, NJ0163 resolve; **AG0034 returns** once its control's tillage is filled, because its
two arms genuinely do have the same tillage.

**The change that made the difference: route 2b, the study-level record.** The first v52 build left 22,118
arms blank, and the biggest block of them was the one the guard was built for — a practice recorded once for
the whole study rather than on each arm. Refusing an *absence* term there is right; leaving the cell blank is
not, because blank reads as "not applied". Resolving the practice's **own name** from `Base.Codes` filled
18,556 arms and dropped refusals to 3,562. **Interpretation check before trusting it:** `Base.Codes` and the
arm's own codes are **complementary, not overlapping** (4,000-row sample: 62 % of rows share no code, mean
overlap 0.16), so the study-level set is the fallback for a family the arm's own codes say nothing about.
Confirmed by CJ0039 (its "Control_N" arm received the N only `Base.Codes` records) and JS0278 (the base code
is the same practice the arm's own codes give). EO0131 alone accounts for 4,608 of the 4,614 tillage fills
and is worth a check against the paper. **Caveat recorded in the changelog:** the filled arm shows the
study-wide practices while the other arm still shows only its distinguishing ones, so the two arms are not
written on the same basis.

**Three things to know about this build.**

1. **54 rows in 3 studies changed orientation** — JS0006.1 (48), NJ0093 (4), AG0091 (2) — and their effect
   sizes change sign relative to v51. Cause: filling a blank Tier-1 arm makes both arms diversified at that
   tier, so the tier no longer "hits", and a lower tier (or no tier) claims `practice_primary` with a
   different `side`. JS0006.1: both arms are intercrops, the real contrast is rotation vs continuous, and
   the rotation sat on the control, so it is now the treatment. All three look more correct than v51, but
   they are changes and Andrea is told explicitly. `ct_reoriented` 2,438 → 2,480.
2. **Tillage one-arm-empty rises 1,570 → 5,091.** Not a regression: the mh recovery gives the T arm a label
   where previously BOTH arms were blank, so these rows newly enter the one-sided count. The C arm is
   refused because 4,793 of them have a tillage receipt column filled and 4,614 have tillage in
   `Base.Codes`. **Proposed v53 fix: resolve the family's name from `Base.Codes` and write it to the blank
   arm** (not an absence term — the practice WAS applied, study-wide). Would resolve ~4,600 tillage rows and
   is the same mechanism behind the 12,154 refused fertiliser arms.
3. **Ontology check reports 5 phantom values** with a leading dot (".Conventional Tillage" etc.): the check
   splits on `\.\.` but ERA's aggregation marker is `...`, so the third dot survives. Data is fine, the
   check's regex needs `\.{2,}`. The other 23 non-conforming values are real and mostly pre-existing,
   including "No Fertilizer Application" (56,576 cells) which the script has used since v32 and which is
   **not in `01_practices`** — worth raising with the ontology owner.

**Four bugs cost four full 28-minute runs today**, all in the new Step 6g, all shape/indexing rather than
logic: agroforestry has no entry in `.T1_SEP` and `|` does not short-circuit, so `[[` threw; the guard
refusal had 7 columns against the Tier-1 refusals' 8, so `rbindlist` halted; the companion CSV selected
columns by name and dropped `reason`; and `paste()` without `sep` broke the `(^|; )` tag pattern.
**Lesson: a new block at the end of a 28-minute script must be exercised standalone first.** A 10-line
harness with synthetic data caught all of these in seconds once written.
**Done: `fomd_out` (slim) + `HASV0` + `VALDIFF0` are saved to `Downloads/step6g_input_vNN.rds`**
immediately before Step 6g, wrapped in `try()` so it can never fail a run. Every diagnosis in the list above
was made against it in seconds. Build it into any future step that sits late in the script.

**A fifth bug, and the one to actually remember: the Bash heredoc eats backslashes.** `sub(..., "\1", p)`
written through a `<<'PY'` heredoc reached the file as `""` — an octal escape, not a backreference — so
the genus lookup silently resolved **nothing** and every species fell through to "(Unspecified)". It parsed
fine and would have shipped. The same collapsing broke two earlier patch attempts in the same session.
**Never write a patch containing a regex backslash through the shell; use the Write/Edit tools.** Guard:
`Select-String -Pattern '"\[0-9]"'` over the script finds this class of damage.

Verification: `Downloads/era_cache/inspect/verify_v52.R` (extended with sections 7 and 8) — all checks pass
except the deliberate `ct_reoriented` count, explained in point 1 above; 166,243 of 166,297 rows join to v51
with identical means and variances, and the 54 that do not all match a v51 row with C and T swapped.
Run log: `inspect/v52_run.log` (34 min).
