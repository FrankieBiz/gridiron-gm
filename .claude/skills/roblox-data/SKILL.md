---
name: roblox-data
description: Change GRIDIRON GM's save schema (ProfileStore) safely. Use whenever anything under profile.Data changes — new persisted fields, shape changes, or save-related bugs like data loss or session locks.
---

# roblox-data — save-schema changes

SaveService (`src/server/Services/SaveService.luau`) is the only ProfileStore touchpoint.
Read `knowledge/roblox-data.md` before editing. Data-loss bugs are the one class of bug
this game can't shrug off — be paranoid here.

## Adding a persisted field (common case)
1. Add it to `TEMPLATE` in SaveService with a correct default — `profile:Reconcile()`
   back-fills existing saves on next load. (Fields nested inside `franchise` are created
   by the code that builds/updates the franchise table — give them defaults at creation
   AND `or`-defaults at read sites for saves written before the deploy.)
2. Write reads defensively for one version: `franchise.newThing or default`.
3. Confirm the value is JSON-safe: strings/numbers/bools/clean tables; ids not object
   references; no mixed keys, no unbounded growth (cap logs/history arrays).

## Changing shape incompatibly
- Pre-launch: bump the store name (`FranchiseData_v2` → `_v3`) and update the header
  comment — old saves are deliberately orphaned. State this clearly in your summary.
- Post-launch: DO NOT bump the store. Add `schemaVersion` inside the data and write an
  explicit migration that runs after Reconcile on load, transforming old → new in place.

## Verifying
- Lune can't run ProfileStore. Test the logic around it by keeping transforms pure
  (migration function takes a table, returns a table → unit-test THAT in `tests/`).
- Real persistence check: publish to the test place (Studio access to API services on),
  join, mutate state, rejoin — state survives; check the kick paths still behave
  (profile nil → "Data load failed" kick, not a broken session).
- Grep for every read of the field you changed (`franchise.foo`) — stale readers of a
  renamed field fail silently as nil.
