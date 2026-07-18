# GRIDIRON GM — UI v2 Master Spec (synthesis & conflict resolutions)

The three companion specs are the source of truth in their domains:
- `ui-v2-motion.md` — animation architecture, hooks, GameResult storyboard, sound choreography
- `ui-v2-visual.md` — every color/type/geometry token value, motifs, component skins
- `ui-v2-ixd.md` — app shell, resilience UX, screen-by-screen layouts, component kit, copy

Where they disagree, THIS file wins. Implementers read this first, then their screen's
section in ixd, then the motion recipes and visual tokens they reference.

## Resolved conflicts (binding decisions)

| # | Topic | Decision |
|---|---|---|
| R1 | Motion library layout | motion spec wins: `motion/` = Solver, Ticker, Motion, useMotor, useSpring, useProgress, useChoreo, useStagger, usePulse, init.luau aggregator. IXD's `motion/Hooks.luau` (useClock/useEntrance) is NOT built — `usePulse`/`useProgress`/`useStagger` cover those roles. |
| R2 | Motion token values | ONE authority: `motion/Motion.luau` with the motion spec's §2 values (spring.snappy/pop/slide/gentle/bounce/shake/lazy, dur, stagger, dist) **plus** `Motion.scale = { press = 0.96, hover = 1.02 }`. Theme carries NO spring/duration/motion tables (visual §6 and IXD-2's Theme.spring/duration are dropped). Screens require both Theme and motion. |
| R3 | Fade | `components/Fade.luau` DELETED. `components/Transition.luau` (motion §6) replaces it — enter-only, dir support, progress starts at 0 (no flash), reduced-motion snap. |
| R4 | Tab transitions | IXD-9 wins: NO CanvasGroup for tabs. Tab pane = plain Frame, X-offset slide binding (24px, direction from Nav.tabIndex delta, 0.18s easeOutCubic via useProgress) + each screen's own stagger supplies the fade. Transition (CanvasGroup) is used at screen level only. |
| R5 | CanvasGroup census | Screen-level Transition (1, always) + ONE transient (GameResult matchup card, OR banner bloom, OR Confetti — mutually sequential) = peak 2. Everything else: 0. |
| R6 | Spacing/type/geometry names | visual spec §1–§6 wins wholesale: `Theme.space {xs..xxxl}`, `Theme.type` ramp (hero/display/h1/h2/body/bodyBold/caption/eyebrow/monoXL/mono/monoSm), `Theme.radius`, `Theme.strokes`, `Theme.size`, `Theme.chrome { topBarH=64, tabBarH=56, padX=16, contentMaxW=640, modalMaxW=480 }`, `Theme.z`. Where ixd screens say `layout.topBar=72`→use 64; `maxContentWidth=560`→use `chrome.contentMaxW=640`; `Theme.text.title/heading/micro`→`type.h1/h2/eyebrow`. |
| R7 | Safe area | `src/client/SafeArea.luau` (IXD-3: `get()` + reactive `useInsets()`). Theme stays pure — NO GuiService require in Theme; visual §4.6 `Theme.safeArea` is NOT built. Chrome math per IXD-4 with R6 heights. |
| R8 | ovrColor | Stepped 5-stop ramp (visual §9), NOT continuous lerp. Thresholds: ≥90 brand.glow, ≥80 gold, ≥70 chalk, ≥60 chalkSoft, else text.tertiary. |
| R9 | danger / scrim / contrast | visual wins: danger (222,70,70); scrim (4,9,7) @ 0.38; `Theme.contrastOn` (WCAG, 0.19 crossover) — IXD's `textOn` name is NOT used. |
| R10 | Confetti | motion §8.1 wins: `components/Confetti.luau`, ≤32 rotated frames inside ONE ClipsDescendants CanvasGroup (rotation escapes Frame clipping — IXD's unclipped version rejected). `overlay/Celebration.luau` hosts Confetti + goldBloom for `overlay.celebrate()`; GameResult mounts Confetti directly. |
| R11 | PlayerCard | DELETED. `components/PlayerDetailModal.luau` via ModalHost, with motion §7.5 enter/exit choreography (the app's only deferred unmount). |
| R12 | GameResult | motion §8 storyboard is authoritative (cadence table, matchup intro, rolling ticker, VICTORY/DEFEAT verdict, Phase D stats). Adopt from IXD-28: spectator mode (`teamId == nil` → "FINAL", no YOU framing), `#plays == 0` → instant done, fixed 48px score columns. Banner word: **VICTORY** / **DEFEAT**. |
| R13 | Sound | motion §10 wins (per-sound config, SoundGroups UI/Stinger, ducking, `Sound.play(name, opts)`, 6 new slots). Toast sounds: `toast_ok` → `tick`, `toast_error` → `stinger_loss` at vol 0.2 (aliases, fail-silent). |
| R14 | Button | Variants: primary / secondary / ghost / danger (visual §8.1 — ixd's 3-variant table lacked secondary). Props: ixd kit + `sfx` + `pulse` + `loading` (motion §7.1 recipes; visual colors). Label type.h2 fixed 17. |
| R15 | Types file | `src/shared/Types/Franchise.luau` is ALREADY WRITTEN (predates ixd; field-verified against server). Names: `FranchiseData` (ixd says FranchiseState — use `FranchiseData`), `StatePayload`, `SeasonPayload`, `SimGameResponse`, `TeamRecord` (ixd says Record), `SeasonAwards` (ixd says Awards), `SeasonPhase` (ixd says Phase). Implementers use the file, not ixd §IXD-20's transcription. |
| R16 | Toast/modal engines | All frame-driven work goes through motion hooks (Ticker) — ixd's "ToastStack owns one RenderStepped connection" is satisfied globally by Ticker; no component creates its own RunService connection except Ticker itself. Skeleton's shared shimmer clock = ONE module-level `usePulse`-equivalent implemented inside Skeleton.luau via Ticker.add (refcounted). |
| R17 | Nav | `src/client/Nav.luau` per IXD-1 (Screen/Tab unions, TABS, tabIndex). Screen id "select" kept (knowledge doc's "teamselect" is corrected by this). |
| R18 | App data flow | `src/client/net/Fetch.luau` per IXD-19 returning `{ state: Franchise.FranchiseData?, hasFranchise: boolean, err: string? }`; includes inDraft + freeAgents (the bugfix all three specs demand). App state per IXD-10 (typed unions, pending map, per-id pendings). All ten handlers follow IXD-14's failure-toast law. |
| R19 | Boot | `screens/Loading.luau` (IXD-23), ErrorBoundary outside OverlayProvider (IXD-18/11), Fallback else-branch (IXD-17), init.client per IXD-5/11 (DisplayOrder 10/20, camera re-lock guard, sound preload). |
| R20 | Menu "New" confirm | With an existing franchise, NEW opens the IXD-25 confirm modal (START OVER?) before `onNew` proceeds — data loss guard. |

## Build order (dependency-sorted)

1. **Foundation** (one author, must compile as a unit):
   Theme v2 → SafeArea → Nav → motion/{Ticker,Motion,useMotor,useSpring,useProgress,useChoreo,useStagger,usePulse,init} → Sound v2 → net/Fetch → tests/motion.luau extension (Motion pure helpers).
2. **Kit** (parallel, each file independent once foundation lands):
   Transition, Spinner, Badge, SectionHeader, EmptyState, Skeleton, StatChip, ProgressBar, RangeBar, TeamCrest, PhaseBadge, SortChips, AnimatedNumber, Button, Card, Toast, ConfirmBar, PlayerRow, Confetti, ScoreBug.
3. **Overlay + shell**: OverlayProvider, ToastStack, ModalHost, Celebration, PlayerDetailModal, ProspectDetailModal, ErrorBoundary, Loading, Fallback, TopBar, TabBar, init.client.
4. **App rebuild** (single author — the state machine + all handlers + routing).
5. **Screens** (parallel): Menu, TeamSelect, Dashboard, GameResult, Roster, LeagueTable, Facilities, CareerProfile, History, CareerDecision, Offseason, DraftRoom, FreeAgency. Delete TeamOverview.luau, PlayerCard.luau, Fade.luau.
6. **Gate**: stylua → sourcemap → rojo build → luau-lsp (0 client errors) → all lune tests.

## Amendments from adversarial spec review (binding)

| # | Amendment |
|---|---|
| A1 | **GameResult props gain `teams: { Franchise.TeamSummary }`** — ScoreBug needs abbr + colors; resolve result.homeId/awayId → summary. App passes `data.teams`. |
| A2 | **CareerDecision props gain `teams: { Franchise.TeamSummary }`** — offer crests resolve `offer.teamId` → summary. |
| A3 | **Tab pane is a plain Frame** (X-offset slide via useProgress), NEVER a Transition/CanvasGroup — motion §6's App-wiring snippet is corrected by this line. |
| A4 | Press-dip spring = `Motion.spring.snappy`; release = `Motion.spring.pop`. Toast/ConfirmBar entrance = `Motion.spring.slide`. |
| A5 | R5 census corrected: peak = screen Transition (1) + {GameResult matchup card XOR Confetti} (1) = 2. No banner CanvasGroup exists. |
| A6 | GameResult rolling-ticker slot pitch = 44px (matches row height). |
| A7 | AnimatedNumber default font = `Theme.font.mono` (tabular-number law). |
| A8 | `Modal` shell is internal to ModalHost (one file); detail modals build on it. |
| A9 | `pendingOffseason`: cleared on every success route-away, KEPT on failure. |
| A10 | Overlay hosts (ToastStack/ModalHost/Celebration) receive state via props from the provider — never call useOverlay (require cycle). |
| A11 | Button state-change ColorSequence swaps are allowed; per-frame sequence animation remains banned (visual §12 softened). |
| A12 | TopBar record odometer CUT (YAGNI) — plain Badge swap. |
| A13 | DraftRoom renders a defensive terminal state when `draft.done` (empty board note + disabled actions); resume path routes to "app" if done. |

## Non-negotiables carried from all three specs

- Binding-driven animation only; never setState per frame; all frame work via Ticker.
- No inline Color3/Enum.Font/radius/spacing anywhere outside Theme.
- TextScaled only with MaxTextSize, only for type.hero/display/monoXL (+ Menu wordmark, TeamSelect monograms); every dynamic single-line label gets TextTruncate.
- Numbers that align or animate = RobotoMono fixed size.
- Every list keyed by domain id; every screen handles empty/nil data; every remote failure toasts; every interactive target ≥44px.
- `--!strict` everywhere; zero `any` in screens/; zero NEW luau-lsp errors (target: client errors → 0).
