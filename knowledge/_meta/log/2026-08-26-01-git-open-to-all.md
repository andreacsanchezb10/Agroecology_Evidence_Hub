2026-08-26 — Git policy changed (Lolita's decision): any team member may now run git in the Hub folder,
**one person at a time** — the team takes turns and checks OneDrive is synced before/after. The
`PreToolUse` hook in the three `.claude/settings.json` files (Hub root, `Agroecology_Evidence_Hub/`,
`ERA/Script/`) now prints a reminder on every git command instead of refusing git for anyone but `mlolita`;
the `SessionStart` banner was updated to match, and the `$owner='mlolita'` literal is gone. Verified: the
reminder fires on git commands, stays silent on non-git commands. Remote already configured: `origin` =
github.com/andreacsanchezb10/Agroecology_Evidence_Hub — teammates need collaborator access there to
push/pull. Docs updated: root `CLAUDE.md`, `ERA/Script/CLAUDE.md`, `09_conventions.md` §13,
`_meta/MAINTENANCE.md` health check.
