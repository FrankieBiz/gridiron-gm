# GRIDIRON GM — UI Rebuild: Information & Interaction Design Spec (v1)

Scope: complete structural spec — app shell, resilience UX, loading, all 13 screens, component kit, copy voice. Built on the existing `motion/Solver.luau` (do not modify), the audit's data contract (immutable law), and the Theme palette family. Every decision is numbered `IXD-n`. All paths relative to repo root. All code is `--!strict` Luau, React-lua 17.2.1, no JSX, binding-driven animation only.

Companion facts honored throughout: max ~3 CanvasGroups alive (this spec's steady state is **1**, peak **2**), never setState per frame, never animate TextScaled sizes, rotated elements only inside CanvasGroups (this spec uses **zero** rotated-and-clipped elements), no uploaded images, phone-first at 375×667.

---

## 0. File map (what exists after the rebuild)

```
src/shared/Types/Franchise.luau        NEW    — the whole client/server contract (§2.5)
src/client/init.client.luau            REBUILT— two ScreenGuis, ErrorBoundary, preload
src/client/App.luau                    REBUILT— typed state machine, pending map, toasts on every failure
src/client/Theme.luau                  EXTENDED (additive only, §1.1)
src/client/Nav.luau                    NEW    — Screen/Tab unions + tab metadata
src/client/SafeArea.luau               NEW    — inset math (§1.3)
src/client/ErrorBoundary.luau          NEW    (§2.4)
src/client/net/Fetch.luau              NEW    — typed fetchAll (§2.5)
src/client/Sound.luau                  KEPT   (typed names; wiring notes only)
src/client/motion/Solver.luau          KEPT AS-IS
src/client/motion/Hooks.luau           NEW    — useClock/useSpring/useEntrance (§5.1)
src/client/overlay/OverlayProvider.luau NEW   (§1.5)
src/client/overlay/ToastStack.luau     NEW    (§2.1)
src/client/overlay/ModalHost.luau      NEW    (§1.5)
src/client/overlay/Celebration.luau    NEW    (§1.5)
src/client/components/…                see kit inventory §5
src/client/screens/Loading.luau        NEW    (§3.2)
src/client/screens/Fallback.luau       NEW    (§2.3)
src/client/screens/<12 screens>        REBUILT (§4)
src/client/screens/TeamOverview.luau   DELETED (IXD-29)
src/client/components/PlayerCard.luau  DELETED — superseded by PlayerDetailModal (§5)
```

---

## 1. App shell architecture

### IXD-1 — Typed navigation unions live in `src/client/Nav.luau`

```luau
--!strict
-- Navigation vocabulary: the only legal screen/tab ids in the app.

export type Screen =
	"loading" | "menu" | "select" | "draft" | "freeagency"
	| "result" | "career" | "offseason" | "app"

export type Tab = "Season" | "Roster" | "League" | "HQ" | "Career" | "History"

export type TabDef = { id: Tab, icon: string, label: string }

local Nav = {}

Nav.TABS: { TabDef } = {
	{ id = "Season", icon = "\u{1F3C8}", label = "SEASON" },
	{ id = "Roster", icon = "\u{1F4CB}", label = "ROSTER" },
	{ id = "League", icon = "\u{1F3C6}", label = "LEAGUE" },
	{ id = "HQ", icon = "\u{1F3D7}", label = "HQ" },
	{ id = "Career", icon = "\u{1F454}", label = "CAREER" },
	{ id = "History", icon = "\u{1F4DC}", label = "HISTORY" },
}

function Nav.tabIndex(tab: Tab): number -- 1..6; used for directional tab slide
```

App's `useState` becomes `React.useState("loading" :: Nav.Screen)` and `React.useState("Season" :: Nav.Tab)`. A `setScreen` typo is now a compile error. The `else → History` fallthrough in the tab switch is removed: the switch is exhaustive over the union with History as an explicit branch.

### IXD-2 — Theme structural token extensions (additive; existing exports byte-for-byte preserved)

`src/client/Theme.luau` gains exactly these (the visual-design pass may deepen colors, but these names/values are the contract the kit compiles against):

```luau
Theme.space = { xs = 4, s = 8, m = 12, l = 16, xl = 24, xxl = 32 }
Theme.radius = { sm = 6, md = 10, lg = 14, xl = 20, pill = 1000 }
-- Fixed text sizes (phone-first @375w). TextScaled is reserved for the Menu wordmark
-- and TeamSelect monograms ONLY; every other label is a fixed token size.
Theme.text = { display = 30, title = 22, heading = 17, body = 14, caption = 12, micro = 10 }
Theme.layout = {
	topBar = 72,        -- chrome height BELOW the safe-area top inset
	tabBar = 56,        -- tab row height
	tabBarPad = 8,      -- bottom breathing room (home-indicator guard)
	contentPad = 16,    -- default horizontal screen padding
	maxContentWidth = 560, -- desktop clamp for columns/CTAs (UISizeConstraint)
	touchTarget = 44,   -- minimum interactive height/width
	rowS = 44, rowM = 56, rowL = 64, -- list row heights
}
Theme.duration = { fast = 0.12, base = 0.2, slow = 0.35, count = 0.6 }
Theme.spring = {   -- Solver.SpringConfig presets, the ONLY spring configs allowed
	press  = { frequency = 7, damping = 0.6 },  -- button dips
	snappy = { frequency = 5, damping = 0.85 }, -- toasts, pills, tab pill
	pop    = { frequency = 4, damping = 0.55 }, -- celebratory overshoot
	gentle = { frequency = 3, damping = 1 },    -- bars, count-assist
}
Theme.danger = Color3.fromRGB(198, 62, 50)   -- losses, errors, HOT SEAT, fired
Theme.win = Theme.green
Theme.loss = Theme.danger
Theme.scrim = Color3.fromRGB(4, 8, 6)        -- modal backdrop, used at 0.42 transparency
Theme.scrimT = 0.42

export type DevTrait = "normal" | "star" | "superstar"
function Theme.devColor(trait: DevTrait?): Color3          -- retyped, same behavior
function Theme.ovrColor(ovr: number): Color3               -- UPGRADED: continuous lerp
	-- chalkSoft at <=60 → chalk at 75 → gold at 85 → flag at 99 (piecewise Color3:Lerp)
function Theme.deltaColor(n: number): Color3               -- >0 green, <0 danger, ==0 chalkSoft
function Theme.darken(c: Color3, f: number): Color3        -- c:Lerp(black, 1 - f) ; f=0.7 → 70% brightness
function Theme.textOn(bg: Color3): Color3                  -- relative luminance > 0.45 → field3 else chalk
function Theme.newsColor(kind: string): Color3             -- title/award=gold, career=flag, draft/league=green,
                                                           -- retire=chalkSoft, credits=gold, else chalkSoft
function Theme.phaseColor(phase: string): Color3           -- regular=green, playoffs=gold, offseason=flag
```

Kills the Dashboard inline-color duplication and the `strokeT` orphan problem (it stays where it is for compat; new code reads it as today).

### IXD-3 — Safe-area handling: `src/client/SafeArea.luau`

Both ScreenGuis keep `IgnoreGuiInset = true` (full-bleed backgrounds must reach screen edges). All *content* is inset by measured values:

```luau
--!strict
local GuiService = game:GetService("GuiService")

export type Insets = { top: number, bottom: number, left: number, right: number }

local SafeArea = {}

function SafeArea.get(): Insets
	local tl, br = GuiService:GetGuiInset() -- Vector2 topLeft, Vector2 bottomRight
	return { top = tl.Y, left = tl.X, right = br.X, bottom = br.Y }
end

-- Hook: returns insets and re-renders when the viewport changes (rotation, window resize).
-- Implementation: useState(SafeArea.get()) + useEffect subscribing to
-- workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"); disconnect on unmount.
function SafeArea.useInsets(): Insets
```

Rules: (a) TopBar draws its background from y=0 but its content sits below `insets.top`; TopBar's total height = `insets.top + Theme.layout.topBar`. (b) TabBar's total height = `Theme.layout.tabBar + Theme.layout.tabBarPad`, anchored to bottom; the pad is dead space under the buttons (home-indicator guard) — TabBar background still bleeds to the screen edge. (c) Full-screen non-chrome screens (Menu, GameResult, DraftRoom, …) pad their own top content by `insets.top + Theme.space.m`. (d) ToastStack positions from `insets.top + Theme.space.s` (§2.1).

### IXD-4 — Chrome geometry is computed, never hardcoded

App's "app" layout (replaces the magic 82/146):

```luau
local insets = SafeArea.useInsets()
local topH = insets.top + Theme.layout.topBar
local botH = Theme.layout.tabBar + Theme.layout.tabBarPad
-- content frame:
Position = UDim2.fromOffset(0, topH)
Size = UDim2.new(1, 0, 1, -(topH + botH))
```

TopBar and TabBar read the same tokens. At 375×667 with a 58px inset: content = 375×473. Every screen in §4 is specced against that box.

### IXD-5 — DisplayOrder plan (set in `init.client.luau`)

| ScreenGui | Name | DisplayOrder | Contents |
|---|---|---|---|
| main | `GridironGM` | **10** | App tree (screens + chrome) |
| overlay | `GridironGM_Overlay` | **20** | portal target: celebrations (ZIndex band 10), modals (band 20), toasts (band 30) |

Both: `ResetOnSpawn = false`, `IgnoreGuiInset = true`, `ZIndexBehavior = Sibling`, properties set before `.Parent = playerGui`. Toasts render above modals so a failure during a modal flow is always visible. Nothing in the app may create a third ScreenGui.

### IXD-6 — OverlayProvider: one context, one portal, three hosts

`src/client/overlay/OverlayProvider.luau`:

```luau
--!strict
-- Overlay service: toasts, modals, and celebration effects rendered via createPortal
-- into the GridironGM_Overlay ScreenGui, above all screens and chrome.

export type ToastKind = "error" | "success" | "info"
export type ToastInput = {
	kind: ToastKind,
	title: string,          -- ALL-CAPS broadcast headline, <= 28 chars
	detail: string?,        -- one sentence, sentence case
	duration: number?,      -- seconds; defaults: error 5.0, success 3.5, info 3.0
}
export type CelebrationKind = "confetti" | "goldBloom"

export type OverlayApi = {
	toast: (input: ToastInput) -> (),
	open: (id: string, build: (close: () -> ()) -> any) -> (), -- `any` = React element
	close: (id: string) -> (),
	celebrate: (kind: CelebrationKind) -> (),
}

type ProviderProps = { gui: ScreenGui, children: any }

local Overlay = {}
Overlay.Context = React.createContext(nil :: OverlayApi?)

function Overlay.Provider(props: ProviderProps): any
-- Renders: props.children, plus ReactRoblox.createPortal(
--   { celebration = e(Celebration, ...), modals = e(ModalHost, ...), toasts = e(ToastStack, ...) },
--   props.gui)
-- The api table is useMemo'd once; state lives in the provider (toasts array, modals dict).

function Overlay.useOverlay(): OverlayApi
-- useContext; errors loudly ("useOverlay outside OverlayProvider") if nil.

return Overlay
```

Modal semantics: `open(id, build)` stores `build`; ModalHost renders `build(closeFn)` inside a scrim. Re-calling `open` with the same id replaces the content (no re-entrance animation). Only the topmost modal receives input; scrim tap and the X button call `close(id)`. Modals do **not** use CanvasGroups — entrance is scrim `BackgroundTransparency` binding 1→0.42 (0.18s easeOutCubic) + card `UIScale` spring 0.92→1 (`Theme.spring.pop`); exit is the reverse at `Theme.duration.fast` then unmount (ModalHost keeps the entry alive until the exit binding completes).

### IXD-7 — CanvasGroup budget ledger

| Owner | CanvasGroups | When alive |
|---|---|---|
| Screen-level `Fade` (App root) | 1 | always |
| GameResult final-banner bloom | 1 | ~1.2s at game end |
| Everything else (modals, toasts, tab switches, celebrations, skeletons, rows) | 0 | — |

**Decision:** the audit's "crossfade Fade upgrade" (two live CanvasGroups holding old+new screens) is **rejected** — it doubles the render-target cost on every transition for a marginal win. Entrance-only Fade stays, with the flash bug fixed (IXD-8). The audit's "wrap each roster row / facility card in a Fade with per-row delay" is **rejected** as written (per-row CanvasGroups); the same visual is achieved with per-row property bindings (§5.1). Tab switching drops its CanvasGroup entirely (IXD-9).

### IXD-8 — Fade v2 (rebuilt, same file)

```luau
export type Props = {
	trigger: string,               -- replay entrance when this changes
	duration: number?,             -- default Theme.duration.base + 0.08 (0.28)
	distance: number?,             -- px lift, default 16
	dir: ("up" | "down")?,         -- default "up" (content rises in)
	onComplete: (() -> ())?,
	children: any,
}
```

Fixes (all audit flaws): binding initialized to **0** (mounts invisible — kills the one-frame flash), progress reset in `useLayoutEffect` keyed on `{ props.trigger }`, reduced-motion guard (`UserSettings():GetService("UserGameSettings").ReducedMotion` → snap progress to 1, fire `onComplete` immediately), duration/distance/dir props, `onComplete` for gating. Still: one RenderStepped connection, disconnected on done and on cleanup; drives `GroupTransparency` + `Position` on its full-size CanvasGroup. Position writes are additive to `UDim2.fromOffset(0, offsetY)` only — documented constraint: wrap origin-positioned full-size containers only (unchanged from today).

### IXD-9 — Tab transitions: directional slide, no CanvasGroup

In App's "app" branch, tab content is wrapped in a plain Frame whose Position is a binding: on tab change, compute `delta = Nav.tabIndex(new) - Nav.tabIndex(old)`; slide from `UDim2.fromOffset(24 * math.sign(delta), 0)` → `(0,0)` over 0.18s easeOutCubic (one RenderStepped connection in App, reused). Each screen's own entrance stagger (§5.1) supplies the fade-in feel. Navigation now reads spatially left/right; screen-level pushes (menu→select, app→result) keep Fade's vertical rise. TabBar's sliding pill (§5, TabBar) springs in the same direction — the two motions agree.

### IXD-10 — App state shape (typed, complete)

```luau
local screen, setScreen = React.useState("loading" :: Nav.Screen)
local tab, setTab = React.useState("Season" :: Nav.Tab)
local data, setData = React.useState(nil :: Franchise.FranchiseState?)
local lastGame, setLastGame = React.useState(nil :: Franchise.SimGameResponse?)
local pendingOffseason, setPendingOffseason = React.useState(nil :: Franchise.OffseasonSummary?)
local career, setCareer = React.useState(nil :: Franchise.PendingCareer?)
local draft, setDraft = React.useState(nil :: Franchise.DraftView?)
local freeAgents, setFreeAgents = React.useState(nil :: { Franchise.FreeAgent }?)

export type PendingKey = "boot" | "resume" | "newFranchise" | "sim" | "refresh"
	| "chooseJob" | "pick" | "offseason" | "finish"
local pending, setPending = React.useState({} :: { [PendingKey]: boolean })
local scouting, setScouting = React.useState(nil :: string?)   -- prospectId in flight
local signing, setSigning = React.useState(nil :: string?)     -- freeAgent id in flight
local upgrading, setUpgrading = React.useState(nil :: string?) -- facility key in flight
```

Helper `withPending(key: PendingKey, fn: () -> ())`: early-returns if `pending[key]` (double-fire guard), sets true, `task.spawn`s fn, clears in all exit paths. Per-id pendings (`scouting`/`signing`/`upgrading`) guard their own rows. `offseasonDone` clears `pendingOffseason` in **every** branch (fixes the lingering-state nit).

### IXD-11 — `init.client.luau` rebuild

Order: (1) camera lock to Scriptable with a `GetPropertyChangedSignal("CurrentCamera")` re-lock guard; (2) create main + overlay ScreenGuis per IXD-5; (3) `task.spawn` a `ContentProvider:PreloadAsync` over all `Sound` asset ids (warm before first whistle); (4) mount:

```luau
root:render(e(ErrorBoundary, {}, {
	provider = e(Overlay.Provider, { gui = overlayGui }, { app = e(App) }),
}))
```

### IXD-12 — Desktop clamp

Any column of CTAs/cards (Menu buttons, TeamSelect confirm bar, modals, EmptyState) carries a `UISizeConstraint { MaxSize = Vector2.new(Theme.layout.maxContentWidth, math.huge) }` and is center-anchored. Nothing full-width ever exceeds 560px of interactive surface on desktop.

---

## 2. Resilience UX

### IXD-13 — Toast system (`overlay/ToastStack.luau` + `components/Toast.luau`)

**Layout.** Toasts stack top-center in the overlay gui: width `min(viewportW - 32, 420)`, AnchorPoint (0.5, 0), first toast at `y = insets.top + 8`, each subsequent `+ (measuredHeight + 8)`. A toast is a Card (radius `md`, `Theme.field2` at 0.05 transparency, UIStroke per kind): left accent bar 4px full-height (error=`Theme.danger`, success=`Theme.green`, info=`Theme.gold`), then a 12px-padded text block — title (GothamBold, `text.body`, kind color) over optional detail (Gotham, `text.caption`, chalkSoft, TextWrapped, AutomaticSize.Y). Min height 52; whole toast is a TextButton (tap = dismiss).

**Queue rules.** Max **3** visible; overflow queues FIFO and promotes as slots free. Dedupe: an incoming toast matching a visible toast's `kind..title` within 1.5s refreshes that toast's timer instead of stacking. Auto-dismiss: error 5.0s, success 3.5s, info 3.0s (overridable via `duration`). Entrance: Position spring from `y - 64` with `Theme.spring.snappy`; exit: 0.15s fade (per-element `BackgroundTransparency`/`TextTransparency` bindings — no CanvasGroup) + 8px rise; below-toasts re-spring to their new slots. ToastStack owns one RenderStepped connection total, driving all live toast springs. On show, ToastStack calls `Sound.play("toast_error" | "toast_ok")` — fail-silent if the audio pass hasn't registered those names.

### IXD-14 — Failed-remote feedback: the law, applied to all ten remote handlers

Pattern: every handler (a) guards re-entry via its pending key, (b) shows inline pending UI at the interaction site, (c) on `not (res and res.ok)` fires `overlay.toast({ kind = "error", title = ..., detail = res and res.error or defaultDetail })` and restores the pre-action UI. **No silent failure paths remain.**

| # | Handler | Pending UX (at the site) | Failure toast title / detail | On fail |
|---|---|---|---|---|
| 1 | `pickTeam` (NewFranchise) | ConfirmBar button → Spinner, team grid input-locked | `FRONT OFFICE UNAVAILABLE` / "Couldn't start your franchise. Take the podium again." | stay on TeamSelect, selection kept |
| 2 | `simWeek` (SimGame) | SIM button → Spinner + disabled | `PLAY CLOCK EXPIRED` / "The sim didn't come back. You're still on Week {n} — hit it again." | stay on Dashboard |
| 3 | `refreshToApp` (fetchAll) | 2px indeterminate hairline under TopBar (see IXD-16) | `STATS DESK OFFLINE` / "Showing your last synced numbers. Pull the tab again to retry." | keep stale `data`, still route to "app" |
| 4 | `chooseJob` (ChooseJob) | chosen offer card's button → Spinner, other cards dimmed | `THE OWNER'S LINE IS BUSY` / "Your decision didn't go through. Make the call again." | stay on CareerDecision |
| 5 | `scoutProspect` (ScoutProspect) | that row's SCOUT button → Spinner (`scouting = id`) | `SCOUT WENT DARK` / "No report came back. Your point wasn't spent." | row restored |
| 6 | `makePick` (MakePick) | all PICK buttons disabled; chosen row Spinner (`pending.pick`) | `PICK NEVER REACHED THE PODIUM` / "Turn it in again — the clock's still yours." | board restored |
| 7 | `offseasonDone` (fetchAll) | START YEAR button → Spinner | `LEAGUE OFFICE OFFLINE` / "Couldn't open the new league year. Try again." | stay on Offseason, `pendingOffseason` **kept** |
| 8 | `signFreeAgent` (SignFreeAgent) | that row's SIGN button → Spinner (`signing = id`) | `DEAL FELL THROUGH` / "{error}. Your credits are untouched." | row restored |
| 9 | `finishOffseason` (FinishOffseason) | footer CTA → Spinner | `SEASON WON'T START` / "The league didn't answer. Kick off again." | stay on FreeAgency (return value now checked — today it's ignored) |
| 10 | `upgradeFacility` (UpgradeFacility) | that card's UPGRADE → Spinner (`upgrading = key`) | `CONSTRUCTION DELAYED` / "{error}. No credits were spent." | card restored |

Success feedback (sparing — actions with visible state change need no toast): signFreeAgent → success toast `SIGNED AND SEALED` / "{name} is a {teamName} now." only when triggered from the detail modal (list row has its own send-off animation, §4.13). `Sound.play` sites unchanged (whistle/pick/cash at press — instant feedback is correct; the toast covers the failure case).

### IXD-15 — Menu resume path (currently dead) made real + guarded

`onContinue` (with `pending.resume`): if `data.pendingCareer` → career; elseif `data.inDraft` → Continue button shows Spinner, `GetDraft:InvokeServer()`; on fail → error toast `WAR ROOM LOCKED` / "Couldn't reopen the draft. Try again." and **stay on menu** (today it silently dumps to "app"); elseif `data.freeAgents ~= false and #data.freeAgents > 0` → freeagency; else → app. These branches come alive because fetchAll now carries `inDraft`/`freeAgents` (IXD-19).

### IXD-16 — Refresh hairline

`components/RefreshHairline` behavior folded into TopBar: when `pending.refresh` or `pending.offseason`, a 2px flag-colored bar under TopBar animates `Size.X.Scale` on a repeating 1.1s easeInOutCubic sweep (Position binding, one connection, alive only while pending). Data refreshes never blank the screen — stale data stays visible (skeletons are for *first* paint only, §3).

### IXD-17 — Router fallback screen (`screens/Fallback.luau`)

The routing `if/elseif` chain gets a terminal `else` (reachable when a screen's payload guard fails, e.g. `screen == "draft"` with `draft == nil`):

```luau
export type Props = { onRecover: () -> () }
```

Full-bleed field gradient, centered stack (UIListLayout, 12px padding): glyph "🏈" 44px; title `WE LOST THE FEED` (GothamBlack, `text.title`, chalk); body "The broadcast truck hit a snag. Tap below and we'll get you back to the booth." (Gotham, `text.body`, chalkSoft, wrapped, max 300 wide); primary Button `BACK TO THE BOOTH` (min 44 high). `onRecover` = App callback: sets `pending.refresh`, refetches via `Fetch.fetchAll`; success → `setData`, `setScreen("menu")`; failure → error toast (`STATS DESK OFFLINE`) and remain on Fallback (button re-enabled). Also fires a `warn(("[GGM] router fallthrough: screen=%s"):format(screen))` for diagnosis.

### IXD-18 — ErrorBoundary (`src/client/ErrorBoundary.luau`)

```luau
export type Props = { children: any }
type State = { generation: number, message: string? }

local ErrorBoundary = React.Component:extend("ErrorBoundary")
function ErrorBoundary.getDerivedStateFromError(err: any): { message: string }
function ErrorBoundary:componentDidCatch(err: any, info: any) -- warn() with stack
function ErrorBoundary:render(): any
```

When `state.message ~= nil`: render the themed crash screen — same layout skeleton as Fallback; glyph "📋"; title `CLIPBOARD MALFUNCTION`; body "Something snapped a play sheet in half. Tap to restart the booth — your franchise is safe on the server."; primary Button `RESTART THE BOOTH` → `setState({ generation = generation + 1, message = React.None })`. Children render as `e("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1 }, { [tostring(state.generation)] = props.children })` — the generation key forces a clean remount. Sits *outside* OverlayProvider (IXD-11) so even a provider crash recovers.

### IXD-19 — Typed fetchAll (`src/client/net/Fetch.luau`)

```luau
--!strict
-- The ONLY place server state is normalized. Everything downstream is typed.
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)

export type FetchResult = {
	state: Franchise.FranchiseState?, -- nil when no franchise OR on failure
	hasFranchise: boolean,
	err: string?,                     -- non-nil only on remote failure
}

function Fetch.fetchAll(): FetchResult
```

Behavior: `pcall` both invokes. `GetState` nil/not-ok → `{ state = nil, hasFranchise = false, err = "GetState failed" }`. ok-but-`hasFranchise == false` → `{ nil, false, nil }` (normal first run — **not** an error; App shows no toast). Otherwise builds the full normalized table with today's `or`-defaults **plus the two dropped fields**: `inDraft = st.inDraft == true` and `freeAgents = st.freeAgents or false`. `GetSeason` failure degrades to `standings = {}, schedule = {}` exactly as today (screens already tolerate empties). Cast once at the boundary (`st :: any` field reads into the typed table) per house style — this closes the App-side share of the 61-error backlog. Two serial invokes are kept: the data contract is law and no new remote is invented here.

### IXD-20 — `src/shared/Types/Franchise.luau` (exact contents, field for field from the audit dataContract)

```luau
--!strict
-- Shared client/server contract: the FranchiseState blob (GetState + GetSeason normalized)
-- and every payload type it composes. FranchiseService.buildState annotates its return
-- with these; the client's Fetch.fetchAll casts once at the boundary.

local Game = require(script.Parent.Game)

export type DevTrait = "normal" | "star" | "superstar"
export type Phase = "regular" | "playoffs" | "offseason"
export type NewsKind = "career" | "league" | "title" | "retire" | "draft" | "credits" | "award"
export type OfferTag = "REBUILD" | "PLAYOFF PUSH" | "WIN NOW"

export type TeamSummary = {
	id: string, city: string, name: string, abbr: string,
	primary: string, secondary: string, -- "#RRGGBB"
}

export type RosterPlayer = {
	id: string, name: string, position: string,
	age: number, overall: number, speed: number, strength: number, awareness: number,
	potential: number, contractYears: number, salary: number, morale: number,
	devTrait: DevTrait,
}

export type LeagueTeam = {
	id: string, city: string, name: string, abbr: string,
	primary: string, secondary: string,
	prestige: number, -- 1..5
	roster: { RosterPlayer },
}

export type Record = { wins: number, losses: number, gamesPlayed: number }
export type SeasonInfo = { year: number, week: number, phase: Phase, totalWeeks: number }
export type FacilityLevels = { training: number, rehab: number, stadium: number } -- 1..10

export type Coach = {
	reputation: number, jobSecurity: number, -- 0..100
	careerWins: number, careerLosses: number, championships: number,
	seasonsCoached: number, teamsCoached: { string },
}

export type CareerReport = {
	expectedWins: number, actualWins: number, met: boolean,
	champion: boolean, madePlayoffs: boolean,
	secDelta: number, repDelta: number, fired: boolean,
	jobSecurity: number, reputation: number,
}

export type JobOffer = {
	teamId: string, city: string, name: string,
	prestige: number, expectedWins: number, tag: OfferTag,
}

export type Award = {
	title: string, name: string, position: string,
	teamId: string, teamName: string, overall: number, stat: string,
}
export type Awards = { majors: { Award }, allLeague: { Award } }
export type PendingCareer = { report: CareerReport, offers: { JobOffer }, awards: Awards }

export type NewsItem = { kind: NewsKind, text: string }
export type HistoryEntry = {
	year: number, wins: number, losses: number,
	champion: string?, -- teamId
	wonIt: boolean,
}
export type AchievementDef = { id: string, name: string, desc: string, points: number }
export type StandingsRow = { teamId: string, w: number, l: number, pf: number, pa: number, diff: number }
export type ScheduleGame = { home: string, away: string }
export type ScheduleWeek = { ScheduleGame }

export type FreeAgent = {
	id: string, name: string, position: string,
	age: number, overall: number, speed: number, strength: number, awareness: number,
	potential: number, contractYears: number, salary: number, morale: number,
	devTrait: DevTrait,
	cost: number, -- coaching credits
}

export type ScoutedProspect = {
	id: string, name: string, position: string, age: number,
	ovrMin: number, ovrMax: number, potMin: number, potMax: number,
	scoutPoints: number,
}
export type DraftPick = {
	teamId: string, round: number, name: string, position: string,
	overall: number, potential: number, devTrait: DevTrait, mine: boolean,
}
export type DraftView = {
	onClock: string?, isMyPick: boolean, done: boolean,
	scoutPoints: number, pickNumber: number, totalPicks: number,
	prospects: { ScoutedProspect }, myPicks: { DraftPick },
}

export type OffseasonSummary = {
	year: number, nextYear: number,
	champion: string?, -- teamId
	retirees: { RosterPlayer }, rookies: { DraftPick },
	creditsEarned: number, totalCredits: number,
}

export type SimGameResponse = {
	ok: boolean, error: string?,
	-- present when ok (App only stores/forwards ok responses):
	result: Game.GameResult?, homeName: string?, awayName: string?,
	record: Record?, label: string?, -- "Week N" | "Semifinals" | "Championship"
	phase: string?, champion: string?, year: number?, week: number?,
	careerReport: PendingCareer?, -- also present on ok=false during offseason phase
}

export type FranchiseState = {
	teamId: string,
	team: LeagueTeam,
	teams: { TeamSummary },
	credits: number,
	record: Record,
	season: SeasonInfo,
	facilities: FacilityLevels,
	coach: Coach,
	prestige: number,        -- 1..5
	expectedWins: number,    -- 2 + prestige*2
	pendingCareer: PendingCareer | false, -- false sentinel (DataStore JSON drops nils)
	news: { NewsItem },      -- newest first, server-capped at 60
	history: { HistoryEntry },
	achievements: { [string]: boolean },
	achievementDefs: { AchievementDef },
	dynastyScore: number,
	standings: { StandingsRow }, -- server-sorted W desc → diff desc → PF desc
	schedule: { ScheduleWeek },
	inDraft: boolean,                 -- RESTORED (fetchAll previously dropped it)
	freeAgents: { FreeAgent } | false, -- RESTORED; false sentinel = FA window closed
}

return {}
```

Contract gotchas preserved verbatim: `false` sentinels stay truthiness-checked; `teams` (summaries) vs `team` (full) never merged; hex color strings parsed client-side via `Theme.hex`; every remote response checked `res and res.ok`.

### IXD-21 — Existing shared types get their missing fields (additive)

`src/shared/Types/Player.luau` gains `devTrait: string` — no; **decision:** leave `Player.luau`/`Team.luau` untouched (server code compiles against them today) and let `Franchise.RosterPlayer`/`Franchise.LeagueTeam` be the UI-facing truth. Zero server churn, zero new type errors.

---

## 3. Loading

### IXD-22 — Skeleton vs spinner strategy (the whole table)

| Surface | Treatment | Why |
|---|---|---|
| Boot (`screen == "loading"`) | **Full skeleton screen** (§3.2) | first impression; unknown wait |
| Menu → Continue (resume fetch) | Spinner inside the Continue button | context is the button |
| TeamSelect → confirm (NewFranchise) | Full-screen takeover: ConfirmBar → Spinner + headline `BUILDING YOUR FRONT OFFICE…` | franchise creation is a moment, not a wait |
| Tab screens (Season/Roster/League/HQ/Career/History) | **No skeletons** — data is already in memory when "app" mounts; refreshes keep stale data + TopBar hairline (IXD-16) | never blank a screen that had data |
| Row-level actions (scout/sign/upgrade/pick/sim/start-year) | Spinner replacing that button's label | feedback at the finger |
| GameResult | none (payload arrives with navigation) | — |

`Skeleton` shimmer = a `UIGradient` (chalk band on field2) whose `Offset.X` loops -1→1 over 1.4s via **one** module-level clock binding shared by every mounted skeleton (single RenderStepped connection in `Skeleton.luau`, refcounted by mount count).

### IXD-23 — Boot choreography (`screens/Loading.luau`, exact timeline)

```
t=0.00  mount: field gradient bg; wordmark "GRIDIRON GM" (two-line, chalk/flag,
        TextTransparency binding 1→0 over 0.25s easeOutCubic, 12px rise)
t=0.00  (parallel) Fetch.fetchAll() in task.spawn; ContentProvider preload already running
t=0.10  three Skeleton bars (280×14, radius pill, centered under wordmark, 10px apart)
        fade in staggered 60ms apart; shimmer loops
t=ready max(0.6s, fetch time): setScreen("menu")  -- minimum hold so the boot never strobes
        Fade (0.28s) brings Menu in; Menu's hero stagger (§4.1) runs on top
```

Failure at boot: `fetchAll` err → still `setScreen("menu")` with `hasFranchise = false` + error toast `STATS DESK OFFLINE` / "Couldn't reach your save. NEW FRANCHISE works; CONTINUE will retry." (Continue, if shown later, retries the fetch.)

---

## 4. Screen-by-screen spec

Common rules for every screen (IXD-24): horizontal padding `Theme.layout.contentPad`; every ScrollingFrame gets `AutomaticCanvasSize = Y`, `CanvasSize = UDim2.new()`, `ScrollBarThickness = 4`, `ScrollBarImageColor3 = Theme.line`, and `PaddingBottom = Theme.space.xl` inside its content; every list keyed by domain id; every interactive element ≥ 44px tall; all fonts via `Theme.font.*`, all sizes via `Theme.text.*`; one `Hooks.useEntrance` binding per screen drives all its stagger (§5.1). Every screen's Props are fully typed against `Franchise.*` — zero `any` remains in `screens/`.

### 4.1 Menu (IXD-25)

Props: `{ hasFranchise: boolean, continueContext: { teamName: string, season: number, wins: number, losses: number }?, resuming: boolean?, onNew: () -> (), onContinue: () -> () }` (App derives `continueContext` from `data.team`/`data.season`/`data.record`).

**Eye path:** 1) wordmark, 2) primary CTA, 3) continue-context chip / tagline.
**Layout (fixed, no scroll):** replace absolute-scale soup with a single centered UIListLayout column (AnchorPoint 0.5/0.5 at 0.5/0.44, `UISizeConstraint` max 560): kicker `A FRONT OFFICE DYNASTY` (caption, chalkSoft, letter-spaced via spaces) → accent bar (Frame 88×3 offset — pixel-sized, fixes the sub-pixel hairline) → `GRIDIRON` / `GM` two labels (TextScaled with `UITextSizeConstraint MaxTextSize = 64`) → tagline "Call the shots. Build the dynasty." (body, chalkSoft) → 20px spacer → button stack. Buttons: fixed `UDim2.new(1, 0, 0, 52)` inside a 320-wide (max) column — kills both the overflow lie and the desktop stretch. Footer `v1 · a two-person studio game` pinned at `1, -insets.bottom - 12` (caption, chalkSoft 0.4 transparency). Background: field gradient + yard lines generated **in a loop** (5 stripes, 2px, transparency 0.35 — brighter so phones see them).
**Data→visual:** `hasFranchise` forks CTA copy: `CONTINUE DYNASTY` (primary) + `NEW FRANCHISE` (ghost) vs single `START YOUR DYNASTY` (primary). `continueContext` renders under Continue as a chip row: `TeamCrest` (size 24) + "Redwood Redwoods · Season 3 · 9–5" (caption, chalkSoft).
**Interactions:** Continue → `onContinue` (`resuming` → Spinner in-button, IXD-15). New with an existing franchise opens a confirm modal via Overlay: title `START OVER?`, body "A new franchise replaces your current save. The {teamName} era ends here.", buttons `KEEP MY DYNASTY` (ghost) / `START FRESH` (danger).
**Empty/first-run:** the no-franchise fork *is* the first-run state; no extra copy needed.
**Wow (2):** ① Hero stagger — one entrance binding: kicker (delay 0), bar scale-X wipe 0→1 (80ms), GRIDIRON slide from -30px (140ms), GM (220ms), tagline (300ms), buttons rise with `easeOutBack` (380ms). ② Primary-CTA heartbeat — sine binding oscillates the button's UIStroke transparency 0.85↔0.45 on a 2.4s period (single clock, runs only on this screen).
Rejected from audit list: wordmark shine sweep (UIGradient offset on text) — kept **optional** for the visual pass; parallax yard-line drift accepted only as UIGradient `Offset` drift (no per-frame stripe repositioning).

### 4.2 TeamSelect (IXD-26)

Props: `{ pending: boolean?, onPick: (teamId: string) -> (), onBack: () -> () }` (still reads `Shared.Data.Teams` directly).

**Eye path:** 1) team cards, 2) header, 3) confirm bar (after selection).
**Layout:** header row (height `insets.top + 56`): Back button (44×44, "‹" glyph, top-left) + title `TAKE THE PODIUM` (title size, GothamBlack, **left-aligned** with `UITextSizeConstraint` — fixes the unconstrained-center-header flaw). Below: ScrollingFrame with `UIGridLayout` — cell `UDim2.new(1, 0, 0, 92)` when viewport width < 480, `UDim2.new(0.5, -8, 0, 92)` at 480–767, `(1/3, -12, 0, 92)` ≥768 (via `SafeArea.useInsets`-style viewport hook). Bottom: `ConfirmBar` (height 72 + `insets.bottom`), hidden until a selection exists, slides up via Position spring.
**Card recipe (data→visual):** Card radius `lg`; diagonal `UIGradient` (`Rotation = 115`) team primary → `Theme.darken(primary, 0.55)`; giant ghost monogram — `abbr` in GothamBlack, TextScaled inside a right-anchored 96-wide label, `TextTransparency 0.82`, `TextColor3 = Theme.hex(secondary)` (no rotation — clipping-safe); left block: CITY (caption, `Theme.textOn(primary)` at 0.35 transparency) over Name (heading, GothamBlack, `Theme.textOn(primary)` — luminance-guarded); bottom-left secondary-color underline bar 40×3. No stripe overhang (the old artifact dies with the stripe).
**Interactions:** tap card → selected: card gains secondary-color UIStroke (transparency 0.1) + UIScale spring to 1.03 (`Theme.spring.pop`); all other cards ease `BackgroundTransparency`-equivalent dim via a 0.5-transparency scrim frame per unselected card (bindings, 0.15s). ConfirmBar slides up: `TeamCrest` 32 + `BUILD THE {NAME} DYNASTY` primary Button. Confirm → `onPick(id)`; `pending` → Spinner + grid locked (IXD-14 #1). Tap selected card again = deselect (bar slides away). Back → `onBack`.
**Empty state:** not reachable (static data) — no spec needed.
**Wow (2):** ① Card cascade — entrance binding, `staggerProgress(t, i, 0.04, 0.45)` per card: 12px rise + transparency fade. ② Selection ceremony (above) — the confirm step also *creates the home* for pending/error states.

### 4.3 Dashboard — Season tab (IXD-27)

Props: `{ teamId: string, teams: { Franchise.TeamSummary }, season: Franchise.SeasonInfo, standings: { Franchise.StandingsRow }, schedule: { Franchise.ScheduleWeek }, news: { Franchise.NewsItem }, simming: boolean?, onSim: () -> (), onOpenLeague: () -> () }` — `standings` is now **used** (dead-prop flaw closed); `onOpenLeague` = App's `setTab("League")`.

**Eye path:** 1) matchup card + SIM, 2) season progress bar, 3) the wire (news).
**Layout:** fixed header stack, then scroll. Region A — Matchup Card, `1, 0, 0, 148`, Card radius `lg`, phase-tinted UIGradient (`Theme.phaseColor(season.phase)` → field2, vertical, subtle): row 1 = `PhaseBadge` + label ("WEEK 7 · NEXT UP" / "PLAYOFFS · SEMIFINALS" / offseason headline — keep the existing good phase copy); row 2 = two team blocks (TeamCrest 40 + abbr + city/name caption + W–L record from `standings`) with a center `VS` / `@` divider (home/away treatment: my side left when home); row 3 = SIM Button, primary, `1, 0, 0, 52` (fixes the 34px CTA), text `SIM WEEK 7 ▸` / `SIM SEMIFINAL ▸` / `RUN THE OFFSEASON ▸`; `simming` → Spinner. Region B — `ProgressBar` height 8 + caption row (`WEEK 7 / 14`, right: `PLAYOFF CUT` marker legend), `notch` at `10/14` gold. Region C — ScrollingFrame: first child = standings snapshot Card (height 148): `SectionHeader "DIVISION RACE"` + top-4 rows (mini: rank, crest 20, abbr, W–L) + my row appended if outside top 4, footer link row `FULL TABLE ▸` (44px, tap → `onOpenLeague`); then `SectionHeader "THE WIRE"` + news rows.
**News row recipe:** height auto (TextWrapped, AutomaticSize.Y, min 44): 3px kind-colored left rail (`Theme.newsColor`), text body chalk. Keyed `"n_" .. i` is banned; keys = `"n_" .. (#news - i)` stable-from-tail so prepends don't re-key existing rows (server prepends newest — tail-index is stable identity).
**Empty news:** EmptyState, icon "🗞", title `THE WIRE IS QUIET`, body "Sim your first week — headlines land here the moment the whistle blows."
**Wow (2):** ① Breathing SIM button (same heartbeat primitive as Menu — one shared component behavior, `Button.pulse = true`). ② Week progress bar tweens to its new fill (gentle spring) each time the tab mounts after a sim, with the notch flashing gold when crossed.
Rejected: per-row news Fades (CanvasGroup) → per-row property stagger instead.

### 4.4 GameResult (IXD-28)

Props: `{ game: Franchise.SimGameResponse, teamId: string?, onDone: () -> () }`.

**Eye path:** 1) ScoreBug, 2) latest play, 3) SKIP/CONTINUE.
**Layout (fixed, no outer scroll):** top: `ScoreBug` (height 92 + safe top pad; §5): crests, abbrs, right-aligned fixed-width score columns (**48px each — digits never drift**), center chip `Q3 · 8:42` live from the newest revealed play, sub-label `game.label`. Middle: play ticker ScrollingFrame (newest at top, kept): rows fixed height 44, fixed `text.body` size, `TextTruncate = AtEnd` (kills ransom-note scaling); `big` plays: height 52, GothamBold, flag text + 3px flag rail. Bottom bar (height 64 + `insets.bottom`): SKIP (ghost) during reveal → swaps to CONTINUE (primary) at done.
**Reveal pacing (constants table at top of file):** `CADENCE = { base = 0.4, big = 0.9, bigPreBeat = 0.35, finalHold = 0.7 }` — variable cadence replaces the metronome; `teamId == nil` → spectator mode: banner text `FINAL`, no YOU labels (fixes the degenerate LOSS bug).
**Data→visual:** scores render through `AnimatedNumber` (0.35s outExpo per step); scoring team's label spring-pulses (UIScale 1→1.15→1, `pop`) + flashes gold for 0.3s. Box score at done: two-column stat grid (PASS / RUSH / TO as three `StatChip` pairs), replacing the single-line string.
**Interactions:** SKIP jumps to done (kept). CONTINUE → `onDone`. No other taps.
**Empty state:** `#plays == 0` → instant done (kept), ticker shows one row "Final — see the box score below."
**Wow (2 — this screen is the emotional peak):** ① Win-banner sequence: 0.5s beat after the final play → banner (WIN in gold / LOSS in chalkSoft — asymmetric emotion) spring-scales 0.6→1 (`pop`) inside this screen's **one transient CanvasGroup** for a group-fade gold bloom (alive ~1.2s, within budget), `Sound.play("pick")` on win, whistle on the final play as the "final gun". ② Big-play flash: on `big` reveal, a full-width flag-colored frame over the ScoreBug animates BackgroundTransparency 0.75→1 over 0.25s.

### 4.5 Roster tab (IXD-29 …includes the TeamOverview verdict)

**TeamOverview.luau is DELETED.** Its two live ideas are absorbed: team-color identity → TopBar (already tinted) + Roster header; OVR-sorted list → this screen. No route, no fold — the file goes.

Props: `{ team: Franchise.LeagueTeam }`.

**Eye path:** 1) roster health strip, 2) sort chips, 3) rows (OVR column).
**Layout:** header strip (height 56): `SectionHeader "ROSTER · {n} PLAYERS"` + three `StatChip`s (AVG OVR with `ovrColor`, STARS count, AVG AGE). `SortChips` row (height 36): `OVR ▼` (default) / POS / AGE / POT — tap = set key, tap active = flip direction. Below: ScrollingFrame of `PlayerRow`s (height `rowM` 56).
**Row anatomy (kept from audit "keep"):** 3px devTrait rail → position block (flag, 40 wide, GothamBlack caption) → name (heading, chalk, `TextTruncate AtEnd` — no shrinking) + meta line ("26 · STAR" caption chalkSoft) → right column: OVR (title size, `Theme.ovrColor`) over `POT ▲{n}` (caption). Rows are `React.memo`'d (house rule); sort runs in `useMemo` keyed on `{ team, sortKey, sortDir }`.
**Interactions:** row tap → `overlay.open("player", ...)` with `PlayerDetailModal { player = p, context = "roster" }`. Press feedback: row UIScale spring dip 0.97 (`press`).
**Empty/nil:** `team.roster` nil or empty → EmptyState, icon "📋", title `NO ONE ON THE BOOKS`, body "Your roster fills in on draft night. The war room is waiting." (Also: nil-guard fixes the `table.clone(nil)` crash.)
**Wow (2):** ① Row cascade on tab entry — entrance binding + `staggerProgress(t, i, 0.03, 0.4)` mapped to X offset (-24→0) and TextTransparency (cap the stagger at the first 14 rows; rows 15+ appear at full progress — off-screen rows shouldn't burn budget). ② PlayerDetailModal reveal choreography (§5, PlayerDetailModal): staggered bar fills + OVR count-up with `ovrColor` ride.

### 4.6 LeagueTable — League tab (IXD-30)

Props: `{ teamId: string, teams: { Franchise.TeamSummary }, standings: { Franchise.StandingsRow } }`.

**Eye path:** 1) my row, 2) playoff line, 3) rank/W–L columns.
**Layout:** one shared column spec drives header and rows (fixes the whitespace-hack wobble forever):

```luau
local COLUMNS = { -- x = left offset (px), w = width (px); TEAM flexes between W and the stat block
	rank = { x = 12, w = 24 }, crest = { x = 40, w = 24 },
	team = { x = 72, wOffset = -72 - 116 },   -- flexes
	wl   = { xFromRight = 116, w = 60 },      -- "9–5", right-aligned
	diff = { xFromRight = 52, w = 44 },       -- "+37", right-aligned, Theme.deltaColor
}
```

Header row 32px (caption, chalkSoft, GothamBold: `#`, blank, `TEAM`, `W–L`, `DIFF`); rows 48px, same columns. PF/PA move to the tap popover (phone-first: 5 columns max at 375w).
**Data→visual:** rank = index; seeds 1–4 get gold rank numerals + a 3px gold rail; after row 4, a divider row (height 24): dashed line effect via 9 short 12×1 chalkSoft frames + centered caption `PLAYOFF LINE`; my row = field2 fill + flag team name + GothamBlack (kept). DIFF via `Theme.deltaColor`. Team cell = `TeamCrest` 20 + `ABBR Name` (truncated).
**Interactions:** rows tappable → Overlay modal `TEAM SHEET`: crest lg, city/name, record, PF/PA, DIFF, seed line ("Seed 3 · In the hunt"). On mount, if my row index > 6, spring `CanvasPosition` so my row lands center (one-shot, gentle spring).
**Empty:** EmptyState, icon "🏁", title `NOTHING ON THE BOARD`, body "Standings post after Week 1 kicks off. Go sim the opener."
**Wow (2):** ① Cascade entrance top-down (1st place lands first) with DIFF counting via AnimatedNumber. ② My-row pulse — slow sine UIStroke transparency 0.9↔0.6 (shared clock).
Deferred (needs data App doesn't hold): rank-movement arrows — noted for a future server field, **not** specced.

### 4.7 Facilities — HQ tab (IXD-31)

Props: `{ facilities: Franchise.FacilityLevels, credits: number, upgrading: string?, onUpgrade: (key: string) -> () }`. Metadata still from `Shared.Data.Facilities`.

**Eye path:** 1) credits banner, 2) per-card level pips, 3) UPGRADE buttons.
**Layout:** credits banner Card (height 48, gold stroke): "🪙" + `AnimatedNumber` credits (title size, gold) + caption `COACHING CREDITS` — in-context balance fixes the eye-travel flaw. Then ScrollingFrame of 3 facility Cards (height 148 each): row 1 icon glyph + name (heading) + `LV {n}` Badge right (no overlap: name width = `1, -140`); row 2 effect blurb (caption, chalkSoft, wrapped); row 3 segmented `ProgressBar` (`segments = 10`, exact pip math `UDim2.new(1/10, -4 * 9 / 10, 1, 0)` — fixes the overflow bug); row 4 right-aligned UPGRADE Button (140×40) + left caption: affordable → `COST {c} 🪙`; unaffordable → `NEED {c - credits} MORE`; maxed → gold Badge `MAXED OUT`.
**Interactions:** UPGRADE → `onUpgrade(key)`; `upgrading == key` → Spinner (IXD-14 #10). Card itself not tappable.
**Empty:** not reachable (static list + defaulted levels).
**Wow (2):** ① Pip-earn: previous levels held in a ref; on increment the new pip scales in `easeOutBack` 0→1 and flashes gold→flag. ② Affordable-beckon: when `credits >= cost`, that button runs the shared heartbeat pulse; a spend also floats a `-{c} 🪙` caption up 24px fading out (one binding, 0.6s).

### 4.8 CareerProfile — Career tab (IXD-32)

Props: `{ coach: Franchise.Coach, team: Franchise.LeagueTeam, prestige: number, expectedWins: number, record: Franchise.Record, achievements: { [string]: boolean }, achievementDefs: { Franchise.AchievementDef }, dynastyScore: number }`.

**Eye path:** 1) dynasty score, 2) hot-seat bar, 3) career tiles.
**Layout (whole tab = one ScrollingFrame):** ① Hero Card (height 96): `DYNASTY SCORE` caption + `AnimatedNumber` (display size, gold) + right: `🏅 {unlocked} / {total}`. ② Stat tile row (height 76): four `StatChip`s — WINS / LOSSES / TITLES / SEASONS (display numbers over caption labels) — replaces the prose blob. ③ Status Card (height 132): two `ProgressBar`s with side labels — REPUTATION (value as its own emphasized number, not baked into the label) and JOB SECURITY with status `Badge` (`SECURE` green / `ON NOTICE` gold / `HOT SEAT` danger — promoted to `Theme` semantics via `Theme.securityColor(v: number): (Color3, string)`). ④ Current Job Card (height 88): TeamCrest 32 + "{city} {name}" + prestige stars (5 glyph labels, gold/line) + "Owner wants {expectedWins}+ wins · You're at {wins}–{losses}" (wrapped, body size). ⑤ `SectionHeader "TROPHY CASE"` + achievement rows (height 52): unlocked = gold glyph + chalk name + points Badge; locked = 🔒 field3/chalkSoft dim; unlocked sort first via two-pass build (no `100 + i` hack — build unlocked list then locked list, LayoutOrder = running counter).
**Empty achievements:** EmptyState (compact), title `THE CASE IS EMPTY`, body "Win one game and the hardware starts arriving."
**Wow (2):** ① Bars spring-fill on mount (underdamped 0.85, second bar staggered 0.12s) + dynasty-score `easeOutExpo` count-up (the Solver comment's named use case). ② HOT SEAT drama: `jobSecurity < 25` → danger stroke pulse on the security bar (shared sine clock).

### 4.9 History tab (IXD-33)

Props: `{ history: { Franchise.HistoryEntry }, teams: { Franchise.TeamSummary }, coach: Franchise.Coach }` — both extra props now **used**: banner counts from `coach` (authoritative), champion names/colors resolved via `teams`.

**Layout:** Banner Card (height 112): trophy row (each 🏆 its own label, capped 8) + `"{coach.championships} TITLES · {coach.seasonsCoached} SEASONS"` via two AnimatedNumbers. Below: season rows (height 56), newest first, `LayoutOrder = i` **assigned while iterating the reversed array** (kills the `100 - idx` overflow bug at season 99+). Row: year (GothamBlack) → W–L Badge (green when wins>losses, danger when losses>wins, chalkSoft tie) → result: `wonIt` → gold rail + `🏆 CHAMPIONS`; else "Champion: {abbr} {name}" with a 8×8 team-primary dot. Key: `"h_" .. s.year` (server appends one entry per year — collision-safe by contract).
**Empty:** kept copy, restyled through EmptyState: icon "📜", title `NO BANNERS YET`, body "Finish a season to start writing your history."
**Wow (2):** ① Trophy pop-in — each 🏆 scales in `easeOutBack`, 80ms apart. ② New-title celebration: previous title count in a ref; on increment → newest trophy springs in at 1.6→1 (`pop`) + `overlay.celebrate("goldBloom")`.
Deferred: tappable expanding season rows (needs richer per-season data than the contract carries) — **not** specced.

### 4.10 CareerDecision (IXD-34)

Props: `{ report: Franchise.CareerReport, offers: { Franchise.JobOffer }, awards: Franchise.Awards, team: Franchise.LeagueTeam, prestige: number, choosing: boolean?, onChoose: (teamId: string) -> () }`.

**Eye path:** 1) verdict hero, 2) rep delta, 3) offers → confirm.
**Layout (ScrollingFrame under a fixed hero):** Hero Card (height 140, full-bleed tint: fired → `flagDeep→transparent` vertical gradient overlay on the whole screen bg; champion → gold version): headline (display size, GothamBlack) — `YOU'VE BEEN FIRED` (danger) / `CHAMPIONS!` (gold) / `SEASON REVIEW` (chalk); sub-line built from structured pieces, not a run-on: "Owner wanted **{expectedWins}+**. You won **{actualWins}**." (numbers emphasized GothamBold chalk) + verdict caption (`met` → "Expectations met." / else "Fell short."). Rep delta = its own `Badge` chip (`+12 REP` green / `-15 REP` danger — `Theme.deltaColor`) popping in after the count (see wow). Awards Card (when `#awards.majors > 0`): SectionHeader `LEAGUE HONORS` + rows "MVP · J. Moore · QB · Sunspire" (TextTruncate, 22px stride kept but derived: height = 44 + #majors * 22). Offers: SectionHeader `ON THE TABLE` + offer Cards (height 96, selectable): TeamCrest 32, city/name, prestige stars, `tag` Badge (REBUILD chalkSoft / PLAYOFF PUSH gold / WIN NOW flag), "Owner wants {expectedWins}+ wins" caption. Stay Card (when not fired) styled identically, tagged `STAY` green. Fired-with-no-offers: single Card `OWNER RECONSIDERS` + copy "One more year. Don't waste it." (safety net kept).
**Interactions:** select a card (same ceremony as TeamSelect — stroke + 1.03 scale, others dim) → bottom ConfirmBar slides up: `TAKE THE {NAME} JOB` / `RUN IT BACK` (stay). Confirm → `onChoose(teamId)`; `choosing` → Spinner (IXD-14 #4). Selection-then-confirm gives the life-changing action deliberate weight — single-tap accept is **rejected**.
**Empty:** structurally impossible (safety net covers zero offers).
**Wow (2):** ① Sequenced reveal on one master clock: hero slams in (`easeOutBack` scale from 1.06) at t=0, wins count-up lands by 0.5s, rep chip pops at 0.7s, awards fade at 0.9s, offer cards cascade from 1.1s (60ms apart). ② FIRED treatment: full-screen flagDeep tint + `Sound.play("whistle")` + headline letter-reveal via a binding mapping progress→`string.sub` (fixed-size text, cheap) — the screen feels different before you read a word.

### 4.11 Offseason (IXD-35)

Props: `{ summary: Franchise.OffseasonSummary, teams: { Franchise.TeamSummary }, starting: boolean?, onDone: () -> () }`. Screen self-defaults nil arrays (`retirees or {}`) — summary bypasses fetchAll normalization by design.

**Eye path:** 1) champion hero, 2) credits earned, 3) draft class.
**Layout (ScrollingFrame; beats gate visibility):** `SKIP ▸` ghost caption top-right (44px target — respects time like GameResult). Beat 1 Champion hero Card (height 120): 🏆 + `"{YEAR} CHAMPIONS"` kicker + team name (title, gold) on a `Theme.hex(champ.primary)→field3` gradient. Beat 2 Credits Card (height 72): `+{creditsEarned} 🪙` AnimatedNumber (gold) + caption `COACHING CREDITS EARNED · BANK: {totalCredits}`. Beat 3 `SectionHeader "RETIREMENTS"` + rows (height 44): pos block + name + "hangs it up at {age} · {overall} OVR" — keys `"ret_" .. p.id` (domain id, fixes index keys). Beat 4 `SectionHeader "YOUR DRAFT CLASS"` + rookie rows (height 56): `R{round}` Badge + pos + name + OVR (`ovrColor`) + devTrait-colored stroke — keys `"rk_" .. p.name .. "_" .. p.round` (picks carry no id — composite key documented). Footer: `START YEAR {nextYear} ▸` primary Button (52px), revealed with the final beat; `starting` → Spinner.
**Empty states (kept copy, restyled):** retirees → "None this year. The locker room holds." · rookies → "No picks came in. Free agency is next."
**Wow (2):** ① Beat choreography: one clock; beats land at 0 / 0.5 / 1.0 / 1.5s (SKIP jumps all to done); rows inside each beat micro-stagger 40ms. ② If **my** team is champion → `overlay.celebrate("confetti")` (§5 Celebration) + credits count-up gets the gold stroke flash.

### 4.12 DraftRoom (IXD-36)

Props: `{ draft: Franchise.DraftView, scouting: string?, picking: boolean?, onScout: (prospectId: string) -> (), onPick: (prospectId: string) -> () }`.

**Eye path:** 1) on-the-clock banner, 2) prospect range bars, 3) scout points.
**Layout:** Header (height `insets.top + 96`): row 1 `WAR ROOM` kicker + `PICK {pickNumber} OF {totalPicks}` (title) + scout points chip (`🔭 {scoutPoints}` gold Badge, AnimatedNumber). Row 2 status banner (height 32): `isMyPick` → flag fill, GothamBlack `YOU'RE ON THE CLOCK` + pulsing flag stroke (sine clock); else chalkSoft `{ABBR} ON THE CLOCK` (resolved from `onClock`). My-picks ticker strip (height 36, horizontal ScrollingFrame): each of `myPicks` as a compact Badge `R{round} · {pos} {name}`. Then prospect rows (height 68, ScrollingFrame): pos block → name (truncated) + age caption → `RangeBar` (OVR, width flexes) with `{ovrMin}–{ovrMax}` caption (single value when collapsed, colored `ovrColor`) → actions column: SCOUT ghost button (72×40; disabled state = 0.5 text transparency + `Active=false` when `scoutPoints == 0` — visibly dead, fixing the silent-swallow) and PICK primary (72×40, rendered only when `isMyPick`).
**Interactions:** SCOUT → `onScout(id)`, `scouting == id` → Spinner in that button (IXD-14 #5). PICK → `onPick(id)`, `picking` disables all PICK buttons (IXD-14 #6). Row tap (not on buttons) → Overlay `ProspectDetailModal` (§5): name/pos/age + OVR RangeBar + POT RangeBar large + scout hint copy.
**Empty prospects:** EmptyState, icon "🔭", title `THE BOARD IS BARE`, body "Every name is off the board. Turn in your pick."
**Wow (2 — flagship):** ① Fog-of-war RangeBar squeeze: on each new `draft` prop, both edges spring (`gentle`) to new min/max; when the range collapses (`max - min <= 2`) the fill snaps gold with an `easeOutBack` tick pop — scouting becomes the signature visual. ② ON THE CLOCK cut-in: when `isMyPick` flips true, banner height springs 32→44, stroke pulses, `Sound.play("whistle")` — broadcast cut-in feel.
Rejected: AI pick ticker with per-pick slide-ins (contract only delivers `pickNumber` deltas, not opponent pick events) — the my-picks strip covers continuity without inventing data.

### 4.13 FreeAgency (IXD-37)

Props: `{ freeAgents: { Franchise.FreeAgent }, credits: number, signing: string?, finishing: boolean?, onSign: (id: string) -> (), onFinish: () -> () }`.

**Eye path:** 1) credits, 2) best available (OVR color), 3) SIGN buttons.
**Layout:** Header (height `insets.top + 64`): `OPEN MARKET` (title) + credits chip (`🪙 {credits}` gold Badge, AnimatedNumber — counts down on spend). `SortChips` (36): `OVR ▼` default / COST / POS. Rows (height 60): pos block → name + "{age} yrs" caption → OVR (title, **`Theme.ovrColor`** — fixed) → SIGN Button (primary when affordable, ghost+dim when not; label `SIGN · {cost} 🪙`). Footer bar (height 64 + `insets.bottom`): full-width primary `KICK OFF THE SEASON ▸`; `finishing` → Spinner.
**Interactions:** SIGN → `onSign(id)`; `signing == id` → Spinner (IXD-14 #8). Row tap → `PlayerDetailModal { player = fa, context = "freeagent", action = { text = "SIGN · {cost} 🪙", onActivated = signFromModal, disabled = credits < cost } }`. Double-fire impossible while `signing` set.
**Empty (kept copy, restyled):** EmptyState, icon "🖊", title `MARKET'S CLOSED`, body "Every veteran found a home. Kick off the season!" — with `actionText = "KICK OFF THE SEASON ▸"` wired to `onFinish`.
**Wow (2):** ① Signed-row send-off: on prop-removal, hold the row in local state 0.4s, overlay `SIGNED ✓` (green), slide right + fade, then release (identity by `fa.id`). ② Credits drain: header AnimatedNumber counts down `easeOutExpo` + gold pulse; rows that just became unaffordable dim in a 0.2s fade (bindings) so the market visibly tightens.

---

## 5. Component kit inventory (`src/client/components/` unless noted)

### IXD-38 — Motion hooks (`src/client/motion/Hooks.luau`, NEW)

The kit's shared animation plumbing; every component below builds on these. Rules: one RenderStepped connection per hook instance; connections run **only while animating** (disconnect on `springDone`/completion); cleanup in `useEffect` teardown.

```luau
export type SpringHandle = {
	binding: React.Binding<number>,
	setTarget: (target: number, config: Solver.SpringConfig?) -> (), -- starts/redirects the spring
	snap: (value: number) -> (),                                     -- jump, no animation
}
function Hooks.useSpring(initial: number): SpringHandle

-- Shared clock: seconds since mount, one connection, for sine pulses/shimmers.
function Hooks.useClock(): React.Binding<number>

-- Entrance progress 0→1 over `duration` (default Theme.duration.slow), eased linearly
-- (consumers apply Solver easings in :map). Replays when any dep changes. Respects
-- ReducedMotion by snapping to 1.
function Hooks.useEntrance(duration: number?, deps: { any }?): React.Binding<number>

-- Stagger convention (the "StaggerList helper"): rows receive `entrance` + `index` props and map:
--   entrance:map(function(t)
--       return Solver.easeOutCubic(Solver.staggerProgress(t, math.min(index, 14), 0.03, 0.4))
--   end)
-- Cap index at 14 so below-the-fold rows mount settled.
```

### IXD-39 — Kit table

| Component | Status | Props type (exact) |
|---|---|---|
| **Button** | REBUILT | `{ text: string, variant: ("primary"\|"ghost"\|"danger")?, size: UDim2?, layoutOrder: number?, disabled: boolean?, loading: boolean?, pulse: boolean?, sfx: string?, onActivated: () -> () }` — variant replaces the color-override convention (primary = flag gradient; ghost = field2 + stroke; danger = `Theme.danger` fill). `AutoButtonColor = false`; press = UIScale spring dip 0.96 (`press`) + fill lerp toward flagDeep on the same binding; hover (desktop) = stroke transparency 0.82→0.5 over 0.12s via MouseEnter/Leave. `loading` swaps label for Spinner and sets `Active = false`. `sfx` default `"click"`, played at Activated. Radius `Theme.radius.md`. Fixed `text.body` size + `UITextSizeConstraint(MaxTextSize = 22)`. |
| **Card** | REBUILT | `{ size: UDim2?, position: UDim2?, anchorPoint: Vector2?, automaticSize: Enum.AutomaticSize?, color: Color3?, layoutOrder: number?, zIndex: number?, selectable: boolean?, selected: boolean?, onActivated: (() -> ())?, entrance: React.Binding<number>?, index: number?, children: { [string]: any }? }` — child-key collision guarded (asserts on `corner`/`stroke` keys in DEV); `selectable` swaps Frame→TextButton with press dip; `selected` animates stroke to `Theme.flag` transparency 0.1; radius `Theme.radius.lg`; subtle vertical white UIGradient (1.0→0.94 brightness). |
| **Fade** | REBUILT | see IXD-8. |
| **TopBar** | REBUILT | `{ team: Franchise.LeagueTeam, record: Franchise.Record, season: Franchise.SeasonInfo, credits: number, refreshing: boolean? }` — height `insets.top + Theme.layout.topBar`; TeamCrest 36 + city/name; record as `Badge` (`9–5`, odometer digit-slide on change); `PhaseBadge`; credits pill auto-width (`AutomaticSize.X`, min 96 — fixes the 110px squeeze) with AnimatedNumber + gold flash on change; `refreshing` renders the hairline (IXD-16). `darken` promoted to `Theme.darken`. |
| **TabBar** | REBUILT | `{ active: Nav.Tab, onSelect: (Nav.Tab) -> (), badges: { [Nav.Tab]: boolean }? }` — hairline moved OUTSIDE the UIListLayout container (fixes the layout bug); **one** sliding pill Frame behind the buttons, Position spring (`snappy`) to `UDim2.fromScale((i - 1) / 6, 0)`; icon-over-label layout (icon 18px label, label `text.micro` GothamBold, inactive labels at 0.4 TextTransparency); per-tab press dip + `Sound.play("click")`; badge = 8px flag dot, pop-in `easeOutBack`. Height tokens per IXD-4. |
| **AnimatedNumber** | NEW | `{ value: number, duration: number?, easing: ("outExpo"\|"outCubic")?, format: ((n: number) -> string)?, font: Enum.Font?, textSize: number, color: Color3?, alignX: Enum.TextXAlignment?, size: UDim2?, layoutOrder: number? }` — binding-driven count from previous value; **never TextScaled** (hard rule); default format `math.floor` tostring. |
| **ProgressBar** | NEW | `{ value: number, max: number, color: Color3?, trackColor: Color3?, height: number?, segments: number?, notch: number?, animate: boolean?, layoutOrder: number? }` — pill track (radius pill); `segments` renders discrete pips with the corrected gap math; `notch` = 0..1 gold tick; `animate` springs fill scale on mount/change (`gentle`). |
| **Badge** | NEW | `{ text: string, color: Color3?, textColor: Color3?, size: ("sm"\|"md")?, layoutOrder: number? }` — pill chip, sm=20px/`text.micro`, md=26px/`text.caption`, AutomaticSize.X with 8px pad. |
| **StatChip** | NEW | `{ label: string, value: string \| number, accent: Color3?, animate: boolean?, layoutOrder: number? }` — big number (title size, GothamBlack, accent or chalk; AnimatedNumber when `animate` and numeric) over caps label (`text.micro`, chalkSoft). |
| **SectionHeader** | NEW | `{ text: string, right: string?, accent: Color3?, layoutOrder: number? }` — 28px row: 3×14 accent tick (default flag) + caps title (`text.caption`, GothamBold, chalkSoft) + optional right-aligned caption. |
| **EmptyState** | NEW | `{ icon: string?, title: string, body: string?, actionText: string?, onAction: (() -> ())?, compact: boolean?, layoutOrder: number? }` — centered column, max width 320; icon 40px glyph; title GothamBlack `text.heading`; body wrapped chalkSoft; optional ghost Button. |
| **Skeleton** | NEW | `{ kind: ("row"\|"card"\|"bar")?, height: number?, width: UDim?, layoutOrder: number? }` — field2 rounded block + shared shimmer clock (IXD-22). |
| **Spinner** | NEW | `{ size: number?, color: Color3?, layoutOrder: number? }` — three 6px dots, staggered sine TextTransparency/scale (no rotation → no clipping hazard). |
| **Toast** | NEW (overlay-internal) | `{ kind: OverlayProvider.ToastKind, title: string, detail: string?, y: React.Binding<number>, onDismiss: () -> () }` (§2.1). |
| **ModalHost / Modal** | NEW (overlay) | Modal: `{ title: string?, onClose: () -> (), maxWidth: number?, children: { [string]: any }? }` — scrim (Theme.scrim @ scrimT, tap = close) + Card (width `min(vw-32, maxWidth or 420)`, AutomaticSize.Y, max height 0.72 of viewport with internal ScrollingFrame) + X button 44×44 top-right; card surface is an inert `TextButton (Active=true, AutoButtonColor=false)` swallowing taps — action buttons on modals are now possible (fixes tap-through). Entrance per IXD-6. |
| **PlayerRow** | NEW | `{ player: Franchise.RosterPlayer \| Franchise.FreeAgent, index: number, entrance: React.Binding<number>?, right: ("potential"\|"cost")?, disabled: boolean?, onTap: (() -> ())?, actionButton: any?, layoutOrder: number? }` — memo'd; anatomy per §4.5; `right`/`actionButton` cover Roster vs FreeAgency variants. |
| **PlayerDetailModal** | NEW (replaces PlayerCard) | `{ player: Franchise.RosterPlayer \| Franchise.FreeAgent, context: ("roster"\|"freeagent"\|"rookie")?, action: { text: string, onActivated: () -> (), disabled: boolean? }?, onClose: () -> () }` — via Overlay Modal. Header: pos Badge + name (title) + devTrait Badge; OVR AnimatedNumber (display size) riding `ovrColor`; attr bars (SPD/STR/AWR ProgressBars, staggered fills 60ms apart) + POT and MORALE micro-bars; contract line formatted `"$%.1fM · %d YRS"` (salary/1e6 — if salary is already in display units the formatter is `("$%d · %d YRS")`; implementer confirms against Generator output, formatting lives in ONE local `fmtSalary`); devTrait-colored card stroke kept; superstar = UIGradient rotation drift in the stroke (property animation, clipping-safe). |
| **ProspectDetailModal** | NEW | `{ prospect: Franchise.ScoutedProspect, scoutPoints: number, scouting: boolean?, isMyPick: boolean, onScout: () -> (), onPick: (() -> ())?, onClose: () -> () }` — large OVR + POT RangeBars, SCOUT/PICK actions mirrored from the row. |
| **RangeBar** | NEW | `{ min: number, max: number, floor: number?, ceil: number?, color: Color3?, height: number?, layoutOrder: number? }` — domain default 40..99; track + fill whose X-position/size springs on prop change; collapse (≤2 wide) → gold tick pop (§4.12). |
| **TeamCrest** | NEW | `{ abbr: string, primary: Color3, secondary: Color3, size: number, layoutOrder: number? }` — text-monogram recipe (no images, no rotation): square Frame `size×size`, UICorner `size*0.28`, UIGradient primary→`Theme.darken(primary, 0.6)` at Rotation 115, UIStroke secondary 2px transparency 0.15, bottom accent bar `1, 0, 0, max(2, size*0.1)` in secondary, abbr label GothamBlack `TextSize = size * 0.38`, color `Theme.textOn(primary)`. |
| **ScoreBug** | NEW | `{ homeAbbr: string, awayAbbr: string, homeColors: { primary: Color3, secondary: Color3 }, awayColors: { primary: Color3, secondary: Color3 }, homeScore: number, awayScore: number, quarter: string?, clock: string?, label: string, myIsHome: boolean?, winnerSide: ("home"\|"away")? }` — fixed 48px right-aligned score columns via AnimatedNumber; my side flag-tinted abbr; `winnerSide` snaps a gold stroke onto that row. |
| **PhaseBadge** | NEW | `{ phase: Franchise.Phase, size: ("sm"\|"md")?, layoutOrder: number? }` — Badge preset: REG green / PLAYOFFS gold / OFFSEASON flag. |
| **SortChips** | NEW | `{ options: { { id: string, label: string } }, active: string, ascending: boolean, onSelect: (id: string) -> (), layoutOrder: number? }` — 36px pill row; active chip flag fill + ▲/▼ glyph; tap active = caller flips `ascending`. |
| **ConfirmBar** | NEW | `{ text: string, crest: { abbr: string, primary: Color3, secondary: Color3 }?, pending: boolean?, visible: boolean, onConfirm: () -> () }` — bottom-anchored bar (height 72 + `insets.bottom`), Position spring on `visible`; used by TeamSelect + CareerDecision. |
| **Celebration** | NEW (overlay) | API via `overlay.celebrate`. `confetti`: 14 plain 8×14 Frames (flag/gold/green/chalk), each with Position + Rotation bindings falling over 1.6s then unmounting — full-screen layer, **no clipping container needed** (particles fade out before exiting bounds), zero CanvasGroups. `goldBloom`: full-screen gold frame BackgroundTransparency 0.85→1 over 0.5s. Hard rule: max one celebration live; new calls replace. |

### IXD-40 — Sound touchpoints (names only; audio pass owns ids/volumes)

`Sound.play` names this spec depends on: existing `"click"` (Button/TabBar default — finally wired), `"whistle"`, `"pick"`, `"cash"`; new fail-silent optionals: `"toast_error"`, `"toast_ok"`. Type `Sound.play(name: string)` unchanged (union-typing Sound is the audio pass's call).

---

## 6. Copy voice

### IXD-41 — Voice rules

Confident broadcast-booth energy: short declaratives, second person, present tense. Titles ALL-CAPS ≤28 chars; bodies one sentence, sentence case, never blame the player, always name the next action. Numbers get digits, not words. No exclamation marks in errors; earned ones only in wins.

### IXD-42 — Canonical strings (the 15)

| # | Context | String |
|---|---|---|
| 1 | Boot fail toast | `STATS DESK OFFLINE` — "Couldn't reach your save. NEW FRANCHISE works; CONTINUE will retry." |
| 2 | Sim fail toast | `PLAY CLOCK EXPIRED` — "The sim didn't come back. You're still on Week 7 — hit it again." |
| 3 | Sign fail toast | `DEAL FELL THROUGH` — "Not enough credits. Your bank is untouched." |
| 4 | Sign success toast | `SIGNED AND SEALED` — "M. Ortega is a Redwood now." |
| 5 | Pick fail toast | `PICK NEVER REACHED THE PODIUM` — "Turn it in again — the clock's still yours." |
| 6 | Fallback screen | `WE LOST THE FEED` — "The broadcast truck hit a snag. Tap below and we'll get you back to the booth." |
| 7 | Crash screen | `CLIPBOARD MALFUNCTION` — "Something snapped a play sheet in half. Tap to restart the booth — your franchise is safe on the server." |
| 8 | Empty news | `THE WIRE IS QUIET` — "Sim your first week — headlines land here the moment the whistle blows." |
| 9 | Empty roster | `NO ONE ON THE BOOKS` — "Your roster fills in on draft night. The war room is waiting." |
| 10 | Empty standings | `NOTHING ON THE BOARD` — "Standings post after Week 1 kicks off. Go sim the opener." |
| 11 | Empty market | `MARKET'S CLOSED` — "Every veteran found a home. Kick off the season!" |
| 12 | Empty trophy case | `THE CASE IS EMPTY` — "Win one game and the hardware starts arriving." |
| 13 | New-franchise confirm | `START OVER?` — "A new franchise replaces your current save. The Redwoods era ends here." |
| 14 | Buttons (set) | `START YOUR DYNASTY` · `CONTINUE DYNASTY` · `BUILD THE REDWOODS DYNASTY` · `SIM WEEK 7 ▸` · `KICK OFF THE SEASON ▸` · `RUN IT BACK` · `RESTART THE BOOTH` |
| 15 | Draft banner pair | `YOU'RE ON THE CLOCK` (mine) · `DEN ON THE CLOCK` (theirs) |

---

## Appendix A — Audit-wow triage summary (accepted / rejected on constraints)

**Accepted** (specced above): staggered entrances everywhere via one binding + `staggerProgress`; score/credits/dynasty count-ups; sliding TabBar pill; fog-of-war RangeBar; selection→confirm ceremonies; phase-tinted surfaces; hot-seat pulse; trophy pop-ins; signed-row send-off; win-banner spring + bloom; continue-context chip; luminance guard `Theme.textOn`; continuous `ovrColor` ramp.
**Rejected with reason:** Fade crossfade (2nd persistent CanvasGroup — budget); per-row/card Fade wrappers (CanvasGroup-per-row — budget; property bindings instead); AI pick ticker (data not in contract); rank-movement arrows (needs last-week standings App doesn't hold); tappable expanding History rows (needs per-season detail not in contract); GetState+GetSeason merge into one remote (contract is law); 9-slice drop shadows (no uploaded images — Card depth via gradient + stroke only); rotated secondary "slash" motifs (rotation escapes Frame clipping; monogram + accent bar instead).

## Appendix B — Definition of done for this spec's implementation

`stylua` clean · `rojo build` green · all four lune tests green · `luau-lsp analyze` **reduces** the 61-error backlog (App/screens/`any` elimination is designed in, not incidental) · every remote failure path visibly toasts · 375×667 Studio emulation shows no clipped chrome, no sub-44px targets, ≤2 CanvasGroups alive at the heaviest moment (GameResult banner during screen Fade).