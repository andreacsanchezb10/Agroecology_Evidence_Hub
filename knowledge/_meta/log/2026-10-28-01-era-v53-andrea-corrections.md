2026-10-28 — **ERA harmonization v53: eight per-study corrections from Andrea's review of v52, hardcoded in
the script** — `_status/era.md`, `sources/ERA/03_era_changelog.md` (v53 section), `sources/ERA/04_era_open_issues.md`
(new items), `sources/ERA/01_era_harmonization.md` (Steps 3b/6c, companion file, gotcha).

**Result:** `Downloads/ERA_crop_data_short_v53.csv`, **166,223 rows / 1,808 studies / 350 columns** (v52 had
166,297; the 74 fewer rows are exactly JO0140's 30 cartesian duplicates and LM0264's 44 wrong-control rows).
Built 14:23–15:00 (35.7 min). `verify_v53.R`: ALL CHECKS PASSED — every one of the 165,837 rows outside the
eight studies is identical to v52 (multiset equality on 70 columns), the three flip counts are unchanged
(1,813 / 921 / 14), and all 19 JO0140 rows match the paper's printed CT/CA pairs. Not yet moved to `ERA/data/`.
Companions: `study_corrections_v53.csv` (23 rules, 746 rows touched, 0 residual defects),
`ERA_v53_ontology_proposal.md`, `ERA_v53_email_to_Andrea.md`.

**Why.** Andrea (28 Oct) listed extraction errors in EO0081, CJ0186, CJ0190, JO0135, JO0140, JO0188, JS0204
and LM0264 (urgent). The source workbooks under `Alliance - ClimateActionNetZero - 1_Projects\ERA\Data Entry\`
are wrong and will not be re-extracted, so the fixes are hardcoded in `era_harmonize.R` and re-applied on every
build. Every claim was checked against the raw `ie`/`mh` snapshots and the four PDFs before coding.

**Two mechanisms, deliberately separate.**
- **Step 3b — raw overrides** (before Step 4, `ie` only), for anything that changes WHICH rows pair: CJ0186's
  `T.Control` was inverted at source (CA flagged as control); LM0264's "Sole Maize" rows carrying a rotation
  id (2A/B, 3A/B) are the maize phase of rotation treatments, not controls — flagged `No` and renamed; JO0140's
  CA/CT rows are a one-to-one series per (site, crop, table), so a `Pair.Ord` column ("Table 5#2") is folded
  into `Pair.Subkey` by `add_pair_subkey()` (49 → 19 pairs).
- **Step 6c — value fixes** (after the v20 fills, before Step 6g), one commented sub-block per study, each
  through a `.fix()` helper that counts the defect before and after (after must be 0) into a ledger written at
  Step 8 as `study_corrections_<v>.csv`.

**What the papers changed before anything was coded.**
- Rao & Mathuva 2000 §2.2: "M_G/M inter block" is system 6 (MMG) — sole maize green-manured with gliricidia
  prunings cut in a separate block and incorporated. Not an intercrop. Now Monoculture + "Tree Prunings
  Incorporated (N fixing)"; `practice_primary` moves to Residues. That is Andrea's "monoculture without vs with
  green manure".
- Assefa 2020 Tables 4–5: CA and CT values swapped at extraction for **every** crop, tomato included (an earlier
  read of the raw row order had wrongly exempted tomato — the design review caught it). At Mkindo the Table-4
  nightshade and Chinese-cabbage rows were entered on each other's lines.
- Omondi 2015 p.477: both TGx lines are IITA improved varieties; SB20 was blank, not "Hybrid". Rule: Hybrid or
  blank → Cultivar (the type vocabulary has no "Improved").
- ERA's `03e. EU_Codes`: "Pepper (Seed/Fruit)" = *Piper* (spice); the vegetable is "Capsicum or Bell Pepper".
  Andrea asked for "Pepper (Fruit)", which would have kept CJ0186/CJ0190 as a spice. **Lolita's decision:**
  Capsicum, with `_product_simple` "Capsicum" and `_product_subtype` "Vegetables", on CJ0186, CJ0190 and
  JO0140 Yemu. Same likely error, not changed: JO0106, EO0019, DK0136, AG0116.

**Found on the way (open issues).** The v26 residue-fate rule (Step 5c) replaces the whole string with the fate
term and drops `Res.Out` P2 — that is why JO0188's "Plastic Mulch" was missing; patched per study, general fix
→ v54. The ontology conformance check scans only `*_subpractice`, so "Black Pepper" has to be proposed by hand.
LM0264's alley arm carries no agroforestry label. `practice_compared` diffs the `_raw` columns too, so a fix that
removes a contrast must move the `_raw` with it (done for JO0188 watharv and LM0264's block arm).

**Process.** Both new blocks were exercised against the save point / the v52 file in minutes before the build
(`inspect/dryrun_v53_pairing.R`, `dryrun_v53_step6c.R`); the pairing dry run caught that the ordinal had been
folded into the key without the table (35 pairs instead of 19). One `stopifnot` guards the Mkindo exchange.
All edits via the editor tool, no shell heredocs (see memory `shell-eats-backslashes`).

**Ninth correction, added after the first build.** AN0129 was in Andrea's list but missing from the copy first
worked from. Step 6h (after the Tier-1/2 rules, before `practice_compared`) flips the 50 rows of "FYM + R M-M N0" vs
"FYM - R + M-M N90" so the residue-incorporation arm is the treatment. Rebuilt 16:28 (39.9 min): 24 ledger rules, 796
rows touched, `verify_v53.R` ALL CHECKS PASSED, AN0129's other 42 rows identical to v52. **Lesson: check the incoming
list against the plan's list before building.**

**Separate, not ERA:** the Zotero/screening cross-fill was done the same day and lives only in
`Downloads/zotero_crossfill/` (Lolita's decision) — 759 of 813 blank ERA titles filled into a copy of
`04_FOMD_screening.xlsx`; 720 papers in the four Zotero source collections tagged `study_id:` / `status:`.
