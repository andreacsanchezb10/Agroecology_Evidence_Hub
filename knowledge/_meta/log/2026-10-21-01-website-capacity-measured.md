# 2026-10-21-01 · Website capacity measured on the whole explore page

Lolita asked how heavy the data can get before the website breaks and whether it would have to move to
S3. Measured instead of guessed: the shipped explore page with the records replicated ×10, ×25, ×50 and
×90 (ERA scale). Results and the reading are in `_status/website.md`, "Measured again 2026-10-21".

The short version written back to her: doubling is nothing; ×10 is where the build guard stops on purpose;
×25 (≈ 1,000 more papers at 46 rows per study) works on desktop but is the point to change the data format;
ERA scale fails as one file. The host is not the limit, the browser is, so S3 alone solves nothing; the
cheap wins are a canvas map renderer and a virtualised table, and the real step is Parquet + DuckDB-WASM
or an API. No code changed.

Also 2026-10-19 evening (recorded in that day's log): effect-size outlier review, no data errors found in
the extremes; three new open items for Andrea in `website.md`.
