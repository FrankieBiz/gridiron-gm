# UI — React-lua, screens, and the house look

Stack: **React + ReactRoblox 17.2.1** (jsdotlua) from Packages. Charm/CharmSync/
ReactCharm and Sift are installed and available, but the current pattern is plain
**hooks + props drilling from App** ("simple + robust" — App.luau header). Follow the
existing pattern; reach for Charm atoms only if a piece of state genuinely needs many
distant subscribers, and say so in the PR/commit message.

## Structure
- `init.client.luau` mounts ONE React root; `App.luau` is a screen state machine:
  `screen` state ∈ loading/menu/teamselect/app/result/career/offseason/draft/….
  Inside "app", `tab` switches Season/Roster/League/HQ/Career/History panels.
- `screens/` = full-screen views. `components/` = reusable pieces (Button, Card,
  PlayerCard, TopBar, TabBar, Fade). One component per file, file exports the function.
- Server data enters through `fetchAll()` in App (GetState + GetSeason → one normalized
  table with `or`-defaults). Screens receive data + callbacks as typed `Props`; they do
  NOT call remotes themselves — user actions bubble up as `onX` callbacks and App does
  the invoke inside `task.spawn` (InvokeServer yields; never yield in render).

## Component idioms (match these exactly)
- `local e = React.createElement` at module top; `type Props = { ... }` above the
  component; `local function ScreenName(props: Props)`.
- Children passed as a **string-keyed table** — keys are the child names and stable
  identity (`menuChildren.continueBtn = e(Button, {...})`). For dynamic lists, key by
  domain id (player id), never by array index.
- Layout via `UIListLayout`/`UIGridLayout` + `LayoutOrder`, sizes with
  `UDim2.fromScale`/`UDim2.new` mixes, `BorderSizePixel = 0` everywhere, rounded corners
  via `UICorner`, edge light via `UIStroke` with `Theme.strokeT` transparency.
- Conditional children by building the table imperatively before the `e(...)` call
  (see Menu.luau) — not nested ternaries.
- Hooks: `useState` for local screen state, `useCallback` for handlers passed down,
  `useEffect(fn, {})` for on-mount fetches (deps array is a TABLE in React-lua).
  `React.memo` heavy list rows (roster tables) when they re-render under polling.

## The look — Theme.luau is law
- All colors/fonts come from `Theme` (field greens, `flag` pylon-orange accent, `chalk`
  text, `gold` highlights; `Theme.font.display/bold/medium/body` = Gotham family).
  Never inline a `Color3.fromRGB` in a screen — add a token to Theme if one is missing.
- Semantic helpers exist — `Theme.ovrColor(ovr)` rating ramp, `Theme.devColor(trait)` —
  extend that pattern for new semantic colors.
- Sfx via `Sound.play("name")` at the interaction site (see simWeek in App).
- Screen transitions: `Fade` component; entrance animation lives in App's mount.

## UI checklist before shipping a screen
- Renders from a `data == nil` / empty-array state without erroring (first-join path).
- Text uses `TextScaled` or explicit sizes that survive a phone screen; test in Studio
  with a small viewport emulation at least once.
- All `ScrollingFrame`s get `CanvasSize` from content (`AutomaticCanvasSize`) not magic
  numbers.
- No remote calls in render; no `while` loops — subscriptions and events only.
- New screen wired: require in App, added to the screen switch (and TabBar if tabbed).
