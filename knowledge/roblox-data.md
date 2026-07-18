# Saves & DataStores — ProfileStore discipline

Saves use **ProfileStore** (vendored at `vendor/ProfileStore.luau` → ServerStorage).
`SaveService` is the only module that touches it; everything else goes through
`SaveService.get(player)` and mutates `profile.Data`.

## The current shape
- Store: `ProfileStore.New("FranchiseData_v2", TEMPLATE)` — the store NAME carries the
  major version. `TEMPLATE = { franchise = false }`; the whole game state lives under
  `profile.Data.franchise`.
- Session locking is the point of ProfileStore: one server owns a profile at a time, so
  no dupes from rejoin/server-hop races. Respect the lifecycle SaveService implements:
  `StartSessionAsync` with a Cancel that checks the player is still present → kick on
  nil profile ("Data load failed") → `AddUserId` (GDPR) → `Reconcile()` → `OnSessionEnd`
  kicks → `EndSession()` on PlayerRemoving. ProfileStore auto-saves periodically and on
  EndSession — do NOT add manual save loops.

## Changing the save schema (the `/roblox-data` skill walks this)
1. **Additive field** (the common case): add it to the template with a sane default —
   `Reconcile()` back-fills existing profiles on next load. Code may still see profiles
   from sessions started before the deploy, so read defensively (`x or default`) for one
   version anyway.
2. **Shape change / incompatible rewrite**: bump the store name (`_v2` → `_v3`) — old
   data is simply orphaned (that's how v1 was retired). Only acceptable while the game
   is pre-launch; post-launch you must write an in-place migration keyed on a
   `schemaVersion` field inside the data instead.
3. Never store: Instances, functions, metatables, mixed-key tables, NaN/inf, or numeric
   keys with holes — DataStore JSON rejects or mangles them. Strings + numbers + bools +
   clean arrays/dicts only. Player-relative data (ids not object refs).

## Testing saves
- DataStores are dead in local Studio play by default. To exercise real persistence:
  publish to a **test place** and enable *Studio access to API services* in Game
  Settings. Lune tests cannot cover SaveService — that seam is why game logic stays out
  of it.
- ProfileStore failure modes worth simulating before launch: join with DataStores down
  (profile nil → kick path), two-server contention (session steal → OnSessionEnd kick).

## Raw DataStore facts (for when something bypasses ProfileStore)
- Budgets are per-server and shared across keys; ~60+numPlayers×10 reads/min class
  budgets. Exceeding queues, then drops. ProfileStore already batches within budget.
- 4MB value cap per key. A long dynasty (history log, news archive) can genuinely grow —
  cap unbounded arrays (e.g. keep last N seasons of full detail, summarize older).
- `MemoryStoreService` is for cross-server ephemera (matchmaking, live leaderboards),
  `MessagingService` for cross-server pub/sub. Neither is a save store.
