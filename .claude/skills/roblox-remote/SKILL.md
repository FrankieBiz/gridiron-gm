---
name: roblox-remote
description: Add a client↔server endpoint to GRIDIRON GM (new RemoteFunction/RemoteEvent). Use whenever the UI needs to ask the server something new or the server must push data to clients — includes the mandatory validation skeleton.
---

# roblox-remote — new endpoint

## Steps

1. **Declare it** in `src/shared/Remotes.luau`: add a `getOrCreate("RemoteFunction",
   "Name") :: RemoteFunction` entry with the one-line contract comment above it
   (`-- (player, args) -> what it returns`), matching the existing table. Request→
   response = RemoteFunction (the default here). Server-push = RemoteEvent (and the
   server must NEVER invoke a client RemoteFunction — hang risk).
2. **Handle it** in the owning Service (`src/server/Services/…`), assigned in that
   service's `Init`/`Start` like its siblings. Mandatory skeleton:
   ```luau
   Remotes.DoThing.OnServerInvoke = function(player: Player, arg: unknown)
       local profile = SaveService.get(player)
       local franchise = profile and profile.Data.franchise
       if not franchise then
           return { ok = false, err = "no franchise" }
       end
       -- validate EVERYTHING the client sent: type, known id, range, phase, cost
       if typeof(arg) ~= "string" or not SomeTable[arg] then
           return { ok = false, err = "bad arg" }
       end
       -- (rate-limit here if the action is spammable/expensive)
       -- delegate to pure logic, persist, respond
       local result = Engine.doThing(franchise, arg)
       return { ok = true, result = result }
   end
   ```
   Treat every argument as `unknown` from a hostile client regardless of annotations.
   Validate game-phase (can't draft during the season, can't sign FA before offseason…)
   — the UI hiding a button is not enforcement.
3. **Call it** from the client: handler in `App.luau` via `useCallback` wrapping
   `task.spawn(function() local res = Remotes.DoThing:InvokeServer(arg) ... end)`,
   always guarding `if res and res.ok`. Pass the handler down as an `onX` prop — screens
   never call remotes directly.
4. Keep payloads lean (what the screen renders, not the whole league). Only
   JSON-able data crosses the wire: no Instances-with-meaning, functions, or metatables.
5. Typecheck will see remote returns as `any` — normalize/cast once at the fetch
   boundary (fetchAll pattern) with `or`-defaults.
6. `/roblox-ship` when wired end to end.
