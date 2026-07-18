---
name: roblox-ship
description: Definition-of-done gate for GRIDIRON GM. Use before declaring any change finished, before committing, or when asked to verify the project is green — runs format, build, typecheck, and all headless game tests.
---

# roblox-ship — quality gate

Run every step from the repo root with `~/.rokit/bin` on PATH. Report each step's
result; a change is NOT done until all pass. Fix and rerun rather than reporting red.

## Steps (in order — cheap fails first)

1. **Format**: `stylua --check src tests` — on failure run `stylua src tests` and note
   the files it changed.
2. **Sourcemap** (needed by later steps, and stale after file adds/renames):
   `rojo sourcemap default.project.json -o sourcemap.json`
3. **Full-tree build**: `rojo build default.project.json -o "$TMPDIR/build.rbxlx"` —
   catches broken project mapping, missing Packages, syntax errors anywhere.
4. **Typecheck**:
   `luau-lsp analyze --defs=globalTypes.d.luau --sourcemap=sourcemap.json --base-luaurc=.luaurc --ignore "Packages/**" --ignore "vendor/**" --no-strict-dm-types src`
   There is a known pre-existing backlog (count recorded in knowledge/roblox-workflow.md).
   The gate is **no NEW errors**: compare against the recorded count; if you reduced it,
   update the recorded number.
5. **Lint** (best-effort in sandbox): `selene src` — if it fails with "Could not collect
   standard library", note it as skipped-in-sandbox and move on (see workflow doc).
6. **Headless game tests** (all four must pass):
   - `lune run tests/sim.luau` — also eyeball the printed realism stats (avg points
     ~20s, favorite win rate 60–72%) if the engine was touched
   - `lune run tests/season.luau`
   - `lune run tests/dynasty.luau`
   - `lune run tests/draft.luau`

## After the gate
- If the change touched sim/league balance numbers, quote the before/after stats from
  tests/sim.luau in your summary.
- Leave the tree formatted and the sourcemap fresh. Do not commit unless asked.
