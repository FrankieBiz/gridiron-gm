# GRIDIRON GM

A football front-office simulation for Roblox. Code-first: built in Cursor, synced into
Studio with Rojo, versioned in Git. See `The Franchise Playbook` for the full roadmap.

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
  Types/Player.luau    the shared typed player struct
  Remotes.luau         RemoteEvent accessor
src/server/            → ServerScriptService.Server (sim engine, cap math, saves)
src/client/            → StarterPlayerScripts.Client (UI; React-lua from Phase 1)
vendor/ProfileStore.luau → ServerStorage.ProfileStore (committed, not from Wally)
```

## Phase 0 smoke test

Press **PING SERVER** in-game → the server prints the ping and increments a saved
counter. Rejoin and the count persists. That proves client↔server messaging and
ProfileStore saving — the Phase 0 Definition of Done.

## Quality commands

```sh
stylua src        # format
selene src        # lint
rojo sourcemap default.project.json -o sourcemap.json   # refresh LSP types
```
