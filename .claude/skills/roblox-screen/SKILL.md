---
name: roblox-screen
description: Add a React-lua screen or component to GRIDIRON GM's UI. Use for new full-screen views, new tabs, or reusable components — follows the App state-machine wiring, Theme tokens, and props conventions.
---

# roblox-screen — new UI screen / component

Read `knowledge/roblox-ui-react.md` conventions first. Screens render; App owns state
and remotes.

## Steps

1. Decide: full-screen view → `src/client/screens/X.luau`; reusable piece →
   `src/client/components/X.luau`. Skim the closest existing sibling (Menu for simple,
   Dashboard for data-heavy, DraftRoom for interactive) and match it.
2. File skeleton: `--!strict`, header comment, GetService + requires, `local e =
   React.createElement`, `type Props = {...}` (data in, `onX: () -> ()` callbacks out),
   `local function X(props: Props)`, `return X`.
3. Style ONLY with `Theme` tokens (colors, `Theme.font.*`, stroke/gradient patterns) —
   missing color = add a token to Theme.luau, never an inline `Color3.fromRGB`.
   Children as string-keyed tables; dynamic lists keyed by domain id; layout via
   UIListLayout/UIGridLayout + LayoutOrder; `AutomaticCanvasSize` on ScrollingFrames.
4. Wire into `App.luau`: require at top with its siblings; render it from the `screen`
   state machine (or the tab switch — also add the tab to `TabBar` usage). Data flows
   from App's fetched state; interactions bubble up via `onX` props and App invokes the
   remote inside `task.spawn` (needs a new endpoint? `/roblox-remote` first).
   `Sound.play(...)` on meaningful interactions; `Fade` for screen transitions.
5. Handle the empty/first-run state explicitly (`data == nil`, empty arrays) — the
   first-join path hits it immediately.
6. Verify: `rojo sourcemap` then typecheck (new files often need the sourcemap refresh),
   and eyeball in Studio via `rojo serve` if feel/layout matters. Then `/roblox-ship`.
