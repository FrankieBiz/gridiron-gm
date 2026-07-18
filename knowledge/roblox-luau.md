# Luau — language & style for this repo

## File shape
- Every file starts `--!strict`, then a short header comment saying what the module is
  and where it sits (see any file in `src/` — match that voice: plain, specific, brief).
- One module per file, `PascalCase.luau` names. Server entry is `init.server.luau`,
  client entry `init.client.luau`, folder-as-module uses `init.luau`.
- `local Service = game:GetService("...")` lines first, then Packages requires, then
  sibling requires (`script.Parent...`), then constants, then the module body.

## Typing
- Strict mode is the default (`.luaurc` sets `languageMode: strict`). Annotate exported
  functions and props tables; let locals infer. `export type X = {...}` for shared
  shapes (see `src/shared/Types/`).
- Prefer typed struct-like tables over classes. Where OO is warranted use the
  `setmetatable({...}, Class)` + `Class.__index = Class` pattern (see ServiceLoader).
- Watch for: `{any}` unions from untyped remote payloads — cast at the boundary once
  (`res :: FranchiseState`) instead of sprinkling `any` through consumers.
- Generalized iteration is house style: `for _, x in list do` (no `ipairs`/`pairs`).

## Modern APIs only
- `task.spawn`/`task.defer`/`task.delay`/`task.wait` — never the deprecated globals
  `spawn`, `delay`, `wait`.
- Connections: keep the `RBXScriptConnection` and `:Disconnect()` on unmount/cleanup
  (Janitor is available in Packages when several need bundling).
- `Instance.new(className)` then set properties then set `.Parent` LAST (parenting first
  fires replication/listeners on a half-built instance).
- String interp: `` `like {this}` `` is fine; `string.format` for aligned/precision output.
- `os.clock()` for timing, `os.time()` for wall time. `math.random` only via the seeded
  RNG in engine code (determinism rule).

## Idioms this codebase relies on
- Fallback-with-`or` for optional server fields: `st.coachingCredits or 0` — keep doing
  this at the fetch boundary so screens can assume presence.
- Guard clauses over nesting: `if not (res and res.ok) then return end`.
- Small pure helper functions over methods when no state is involved.
- Comments explain WHY and game meaning ("fog-of-war scouting"), not what the line does.

## Pitfalls (Luau/Roblox-specific)
- `#t` and `table.insert` only work on array-like tables; holes (nil in the middle)
  silently truncate length. Filter by building a new array.
- Tables are reference types across remotes ONLY on the same side; a remote crossing
  deep-copies and strips metatables, mixed keys, and non-JSON-able values (Instances
  survive, functions/threads don't; numeric+string mixed keys get mangled).
- `string.sub(hex, 2, 3)` style indexing is 1-based and inclusive both ends.
- Float equality: compare with tolerance in sim assertions, never `==`.
- A ModuleScript runs once and caches its return — module-level state is shared by every
  requirer on that side (client and server each get their own copy).
