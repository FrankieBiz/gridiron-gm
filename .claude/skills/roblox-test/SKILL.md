---
name: roblox-test
description: Add or extend a headless Lune test for GRIDIRON GM game logic. Use when new sim/league/draft logic needs coverage or when reproducing a game-logic bug outside Studio.
---

# roblox-test — headless game tests

Tests are plain Lune scripts in `tests/` (`lune run tests/<name>.luau`) — no framework,
no Studio, no DataStores. They exist because game logic is pure; if the code you want to
test can't be required without `game`, extract the logic first (that's the finding, not
a test problem).

## How the existing tests require modules

Lune has no Roblox DataModel, so tests start with `--!nocheck` and require by relative
file path: `local Engine = require("../src/server/Sim/Engine")`. This works because the
pure modules under test have ZERO requires of their own — dependencies (Teams data, RNG
seeds) are passed in as arguments (`Generator.buildLeague(Teams, 12345)`). Keep new
engine modules that way; a `game`/`script.Parent` require in one breaks every test that
imports it.

## Writing one

1. Name it after the system: `tests/<system>.luau`. Header comment: what it proves +
   the `lune run` line, like tests/sim.luau.
2. Structure (mirror tests/sim.luau / dynasty.luau):
   - **Deterministic case**: fixed seed → assert exact/known outcomes (records, ids,
     credit math). Same seed twice → identical result (protects the determinism rule).
   - **Statistical loop** for anything random: run hundreds/thousands of iterations,
     assert distributions inside sane bands (e.g. favorite win-rate 60–72%), and PRINT
     the numbers so balance changes are eyeballable in CI output.
   - **Lifecycle sweep** for season/offseason systems: run multiple full seasons and
     assert invariants hold every year (roster size floors, ages advance, no nil
     players, credits never negative).
3. Fail loudly with `error("...")` including actual vs expected; end with a green
   `print("... ✓")` line like the others.
4. Keep runtime seconds-fast (the 2000-game sim test is the ceiling).
5. Add the new test to the list in README + the `/roblox-ship` skill so the gate runs it.
