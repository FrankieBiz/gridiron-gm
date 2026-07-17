# GRIDIRON GM

A football front-office **dynasty simulation** for Roblox — Retro Bowl's loop with real
depth. You manage a franchise (no on-field play); the computer simulates games and you
build a dynasty over many seasons. Code-first: synced into Studio with Rojo, versioned in Git.

## The game loop
- **Sim your season** week by week → climb the standings → make the top-4 playoffs → win the title.
- **Offseason**: players age, develop toward their potential, and retire; you draft rookies
  (with fog-of-war scouting — true ratings are hidden) and earn coaching credits.
- **Team HQ**: spend credits to upgrade Training / Rehab / Stadium (real sim effects).
- **Coaching career**: owner expectations by team prestige; hit them or the seat gets hot
  and you're fired. Build reputation to unlock job offers and climb from a weak team to a
  blue-blood. Career record, titles, and a franchise Hall of Fame persist across seasons.
- **News feed**: headlines that name your players — retirements, breakout rookies, titles.

Tabs: **Season** (next game + news) · **Roster** · **League** (standings) · **HQ**
(facilities) · **Career** (reputation/job security) · **History** (banners + season log).

## Verify game logic headlessly (no Studio needed)
```sh
lune run tests/dynasty.luau   # plays 3 seasons: aging, draft, credits, career grades
lune run tests/season.luau    # plays one full season to a champion
lune run tests/sim.luau       # 2000-game realism + determinism check
```

## Toolchain (managed by Rokit)

Both machines run the same tools by running one command in this folder:

```sh
rokit install
```

That installs the versions pinned in `rokit.toml`:

| Tool   | Role                        | Web equivalent      |
| ------ | --------------------------- | ------------------- |
| Rojo   | sync `.luau` files → Studio | webpack dev server  |
| Wally  | package manager             | npm                 |
| StyLua | formatter                   | prettier            |
| Selene | linter                      | eslint              |

Saves use **ProfileStore** (vendored in `/vendor/ProfileStore.luau`).

## Daily workflow

1. `rojo serve` in this folder (or use the Rojo plugin's **Connect** button in Studio).
2. In Studio: install the **Rojo** plugin once, then click **Connect**.
3. Edit `.luau` files in Cursor — changes stream into Studio live.
4. To test DataStores (saving), **publish to a test place** and enable
   *Studio access to API services* in Game Settings — DataStores don't run in local play.

## Layout

```
default.project.json   Rojo tree: maps folders below into the DataModel
src/shared/            → ReplicatedStorage.Shared   (code both sides use)
  Types/               Player, Team, Game typed structs
  Data/Teams.luau      the fictional league identities (Frank owns this)
  Remotes.luau         RemoteFunction accessor (NewFranchise / SimGame / GetState)
src/server/            → ServerScriptService.Server (authoritative)
  Sim/Engine.luau      the simulation engine (pure Luau, drive-based)
  Data/Generator.luau  procedural roster generator (pure Luau)
  Data/SaveService.luau ProfileStore wrapper
  init.server.luau     wires the remotes together
src/client/            → StarterPlayerScripts.Client (React-lua UI)
  App.luau             screen state machine + server calls
  screens/             Menu, TeamSelect, TeamOverview, GameResult
  components/Button.luau
vendor/ProfileStore.luau → ServerStorage.ProfileStore (committed, not from Wally)
tests/sim.luau         headless sim check (run with Lune, not part of the build)
```

## Current build — Slice 1 ("feel a game")

Launch → **New Franchise** → pick a team → **Sim Next Game** → watch the play-by-play
reveal and the score climb, then win/loss. Your team + record persist across sessions.
The sim is server-authoritative and deterministic (same seed → same game).

## Verify the sim without Studio

```sh
lune run tests/sim.luau
```
Simulates 2000 games and prints score distribution + favorite win-rate (currently
~23 pts/team avg, favorites win ~70%). Great for tuning the engine fast.

## Quality commands

```sh
stylua src tests  # format
selene src        # lint
rojo build default.project.json -o build.rbxlx   # validate the whole tree
rojo sourcemap default.project.json -o sourcemap.json   # refresh LSP types
```
