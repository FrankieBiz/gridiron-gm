# Roblox architecture — client/server, remotes, security

## The split (as mapped by default.project.json)
- `src/shared` → `ReplicatedStorage.Shared` — visible to BOTH sides. Only types, static
  data (Teams, Facilities), the Remotes accessor, and side-neutral utilities belong here.
  Anything in shared is readable by exploiters — never put secrets or authoritative
  logic in it.
- `src/server` → `ServerScriptService.Server` — invisible to clients. All game logic.
- `src/client` → `StarterPlayer.StarterPlayerScripts.Client` — presentation only.
- `vendor/` → `ServerStorage` — server-only third-party code (ProfileStore).
- Exploiters own their client completely: they can read all replicated code, fire any
  remote with any arguments at any rate, and modify their local state. Design every
  server handler as if called by a hostile script — because eventually it is.

## Server layout
- **Services** (`src/server/Services/`) — stateful entry points registered in
  `init.server.luau` through `ServiceLoader` (two-phase: all `Init()`s run, then all
  `Start()`s; SaveService registers first because others read saves). A Service owns its
  remotes' `OnServerInvoke` and orchestrates; it should not contain simulation math.
- **League/** and **Sim/** — pure Luau engines (no `game`, no Instances, no yielding).
  This purity is load-bearing: Lune runs them headlessly in `tests/`, and it's why the
  sim can run 2000 games in seconds. New game logic starts here, not in a Service.
- **Data/Generator.luau** — procedural content, also pure.

## Remotes — the contract
- One shared accessor: `src/shared/Remotes.luau`. Server side creates each remote
  (`getOrCreate`), client side `WaitForChild`s. UI code never hard-codes Instance paths.
- This game is request→response, so **RemoteFunctions** are the default. Add
  RemoteEvents only for server-pushed notifications (e.g. live league news); use
  UnreliableRemoteEvent only for lossy high-frequency cosmetics (not applicable here yet).
- Never let the SERVER invoke a client RemoteFunction (a client that never returns hangs
  the server thread forever). Server→client is always a RemoteEvent fire.
- Every handler follows the same skeleton (see `/roblox-remote` skill):
  1. Resolve the player's profile/franchise; bail `{ ok = false, err = "..." }` if absent.
  2. Validate argument types AND ranges (`typeof(x) == "string"`, known id, affordable
     cost, correct season phase). Remote args arriving from a client are untyped `any`
     no matter what the annotation says.
  3. Mutate state through the pure engine, save via the profile, return a plain table.
- Responses are `{ ok = true, ... }` / `{ ok = false, err }`. Client always checks
  `res and res.ok` (a thrown server error surfaces as nil on the client).
- Rate-limit anything spammable or expensive server-side (per-player debounce/`os.clock`
  window) — InvokeServer costs the exploiter nothing.

## Determinism & simulation
- The engine takes an explicit seed; same seed → same game (asserted in `tests/sim.luau`).
  Thread the seeded RNG through — one stray `math.random()` breaks replayability and the
  determinism test.
- Balance changes are verified statistically (`tests/sim.luau` prints score distribution
  and favorite win-rate targets ~60–72%) — run it after touching engine numbers.

## Performance notes that matter for this game
- The heavy work (sim) is server-side and event-driven; there is no per-frame server
  loop. Keep it that way — no `RunService.Heartbeat` polling for game logic.
- Payloads: remotes serialize their tables on every call; return what the screen needs,
  not the whole league object graph, once payloads grow (roster screens are the risk).
- UI perf lives in the React doc (memo, stable keys, no per-frame setState).
- `Workspace.StreamingEnabled` and physics tuning are irrelevant while the game is
  UI-only with `CharacterAutoLoads = false` — don't cargo-cult 3D-game advice into here.
