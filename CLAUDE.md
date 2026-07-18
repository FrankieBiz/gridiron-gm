# GRIDIRON GM — project instructions

Football front-office dynasty sim for Roblox. No 3D gameplay — the whole game is a
server-authoritative simulation rendered through a React-lua UI. Code-first: everything
lives in this repo and syncs into Studio with Rojo.

@knowledge/roblox-luau.md
@knowledge/roblox-architecture.md
@knowledge/roblox-data.md
@knowledge/roblox-ui-react.md
@knowledge/roblox-workflow.md

## Ground-truth commands (run from repo root, tools via `~/.rokit/bin` on PATH)

| What | Command |
| --- | --- |
| Format | `stylua src tests` (check-only: `stylua --check src tests`) |
| Lint | `selene src` (needs the Roblox std — see workflow doc) |
| Typecheck | `luau-lsp analyze --defs=globalTypes.d.luau --sourcemap=sourcemap.json --base-luaurc=.luaurc --ignore "Packages/**" --ignore "vendor/**" --no-strict-dm-types src` |
| Refresh sourcemap | `rojo sourcemap default.project.json -o sourcemap.json` (rerun after adding/renaming files) |
| Validate whole tree | `rojo build default.project.json -o "$TMPDIR/build.rbxlx"` |
| Headless game tests | `lune run tests/sim.luau` · `tests/season.luau` · `tests/dynasty.luau` · `tests/draft.luau` |
| Packages | `wally install`, then `rojo sourcemap …` + `wally-package-types --sourcemap sourcemap.json Packages/` |
| Toolchain | `rokit install` (versions pinned in `rokit.toml`) |

**Definition of done:** stylua clean, rojo build succeeds, all four lune tests pass, and
`luau-lsp analyze` introduces **zero new** type errors (there is a known pre-existing
backlog — never add to it). The `/roblox-ship` skill runs this whole gate.

## Architecture in one breath

`src/shared` → ReplicatedStorage.Shared (types, team data, Remotes accessor, ServiceLoader) ·
`src/server` → ServerScriptService.Server (ALL game logic: Services/, League/, Sim/, Data/) ·
`src/client` → StarterPlayerScripts.Client (React-lua UI only — renders state, calls remotes) ·
`vendor/ProfileStore.luau` → ServerStorage (saves) · `Packages/` = wally-managed, never edit.

Load order: `init.server.luau` registers services with `ServiceLoader` (two-phase
Init→Start; SaveService first). The client is a single React root (`init.client.luau` →
`App.luau` screen state machine).

## Iron rules

- **Server is the only authority.** The client never computes game outcomes, prices,
  ratings, or eligibility — it asks via RemoteFunction and renders the answer. Every
  remote handler validates its inputs (type, range, ownership, game-phase) before acting.
- **Pure logic, thin wiring.** Sim/league logic is pure Luau (no Instances, no services)
  so Lune can run it headlessly. If new logic can't run under `lune run`, extract it
  until it can — that's why the tests exist.
- **Determinism:** the sim takes an explicit seed; same seed → same game. Never call
  `math.random` bare in engine code — use the seeded RNG that the engine threads through.
- `--!strict` at the top of every file. New code must typecheck clean.
- Tabs, 100 cols, double quotes (`stylua.toml`); string-keyed children tables in React.
- Don't touch `Packages/`, `vendor/`, or `gitmeta/`. Don't hand-edit `wally.lock`.
- New save shape = bump/migrate via SaveService template + `profile:Reconcile()` — see
  the data knowledge doc before changing anything under `profile.Data`.

## Project skills & agent

`/roblox-ship` (quality gate) · `/roblox-system` (new server system) · `/roblox-screen`
(new UI screen) · `/roblox-remote` (new client↔server endpoint) · `/roblox-test` (new
lune test) · `/roblox-data` (save-schema change). Agent `roblox-specialist` for delegated
stack work. Global reflexes still apply: adversarial-verifier before trusting results,
spec-reviewer before building from a plan.
