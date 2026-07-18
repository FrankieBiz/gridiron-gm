---
name: roblox-system
description: Add a new game system to GRIDIRON GM (trades, injuries, contracts, playoffs seeding, morale…). Use when a feature needs new server-side game logic — creates a pure engine module, wires it into a Service, and covers it with a lune test.
---

# roblox-system — new server-side game system

The house pattern: **pure engine module → thin Service wiring → lune test → (maybe) a
remote + screen**. Never write game math directly inside a Service or remote handler.

## Steps

1. **Spec first** (2–10 lines in the conversation): what the system does each
   season/week, what state it reads/writes on `franchise`, what the player sees. For
   anything non-trivial run the spec past `spec-reviewer`.
2. **Pure module** in the right home:
   - League-structure logic (season flow, offseason, awards, news) → `src/server/League/X.luau`
   - Game-simulation math → `src/server/Sim/`
   - Procedural content → `src/server/Data/`
   Rules: `--!strict`; no `game`/Instances/yields; explicit inputs including the seeded
   RNG if randomness is needed; return plain data. Copy the module voice of
   `src/server/League/Development.luau` (header comment explaining the game meaning).
3. **Tunable constants** grouped at the top of the module (or the existing constants
   home if one exists for that area) — one place to balance from, like TrainingScience.
4. **Wire it** where the season/offseason flow calls it (`SeasonController` /
   `OffseasonController` / the owning Service). Persisted output lives under
   `profile.Data.franchise` — additive fields need the `/roblox-data` reconcile rules.
5. **Test**: extend the closest existing lune test, or add `tests/<system>.luau` via
   `/roblox-test`. Cover: one deterministic scenario with a fixed seed, plus a
   statistical sanity loop if the system has randomness (mirror tests/sim.luau style).
6. If the player interacts with it: `/roblox-remote` for the endpoint, `/roblox-screen`
   (or extend an existing screen) for UI. News-feed hooks: League/News.luau names the
   player's own athletes — new systems should emit headlines there too when notable.
7. Finish with `/roblox-ship`.
