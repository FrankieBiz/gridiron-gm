# Workflow — toolchain, Studio, and machine quirks

## Toolchain (pinned in rokit.toml, installed with `rokit install`)
| Tool | Version | Role |
| --- | --- | --- |
| rojo | 7.7.0 | file tree ↔ Studio sync + build + sourcemap |
| wally | 0.3.2 | package manager (`Packages/`, never edited by hand) |
| stylua | 2.5.2 | formatter (tabs, 100 cols, double quotes) |
| selene | 0.31.0 | linter (`std = "roblox"`, generated std) |
| lune | 0.10.5 | standalone Luau runtime — runs `tests/` headlessly |
| wally-package-types | 1.6.2 | re-exports package types for luau-lsp |
| luau-lsp | 1.68.1 | LSP + **headless typechecker** (`luau-lsp analyze`) |

Rokit lives at `~/.rokit/bin` (shims read `rokit.toml`, so commands run from repo root
pick up pinned versions automatically). `globalTypes.d.luau` (committed) is the Roblox
API surface for luau-lsp; refresh occasionally with:
`curl -o globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau`

## Edit → see it in Studio
1. `rojo serve` here; in Studio install the Rojo plugin once, then **Connect**.
2. Edit `.luau` files in the editor — changes stream in live. The place file is
   disposable; the repo is the source of truth (never edit scripts inside Studio).
3. After adding/renaming files: `rojo sourcemap default.project.json -o sourcemap.json`
   so luau-lsp resolves requires again.
4. Saving/DataStores need a published test place with *Studio access to API services*
   enabled — local play sessions have no DataStores.

## Fast loop without Studio
Game logic is pure Luau, so iterate with Lune (`lune run tests/sim.luau` etc.) — seconds
per run, no Studio. Studio is only needed for UI/feel and save-path testing. This split
is deliberate; protect it (see architecture doc).

## Typecheck backlog
`luau-lsp analyze` currently reports **61 pre-existing TypeErrors** (as of 2026-07-17),
almost all in `src/client` (untyped remote payloads flowing into screens, `{any}`
unions). Policy: new code adds zero; opportunistically shrink the backlog when touching
a file. Fixing the `fetchAll()` return type in App.luau would kill most of them.

## Claude Code sandbox quirks (this machine)
- This clone's git dir is `gitmeta/` (a `.git` PLAIN FILE points to it) because the
  sandbox blocks writes inside `.git`/`.vscode` directories. All git commands work
  normally. Writes to `.vscode/` must use the Write/Edit tools, not shell redirection.
- Network egress goes through a local HTTP proxy (env vars are set). Tools that honor
  proxy env work (curl, git-CLI, reqwest-based tools like wally's downloads and rokit);
  tools that open raw sockets fail with "Operation not permitted" — notably **wally's
  index clone (libgit2)** and **selene generate-roblox-std**.
- `wally install` recipe inside the sandbox:
  1. `git clone https://github.com/UpliftGames/wally-index.git "$TMPDIR/wallyhome/Library/Caches/wally/index/github.com-1ea56f4ad487f695"`
  2. `git -C <that dir> remote set-url origin "file://<that dir>"` (fetch becomes local)
  3. `HOME="$TMPDIR/wallyhome" ~/.rokit/tool-storage/upliftgames/wally/0.3.2/wally install`
     (real binary, NOT the shim — shims resolve through $HOME). A trailing
     "Operation not permitted (os error 1)" after all packages install is harmless;
     verify with `rojo build`.
  4. Then sourcemap + `wally-package-types` as usual.
- `selene src` works once the roblox std is cached; generating it needs one run OUTSIDE
  the sandbox (plain terminal: `selene generate-roblox-std`, or just `selene src` once —
  it auto-generates). Until then, rely on luau-lsp + stylua in sandboxed sessions.
- Machine context: MacBook Air M3 / 16GB, arm64. gh CLI not installed.
