All required reading is done. Here is the complete motion & cinematics spec.

---

# GRIDIRON GM — Motion & Cinematics System Spec

Baseline: React-lua 17.2.1, `motion/Solver.luau` (lune-verified, untouched), Theme field-green/pylon-orange. Everything below is binding-driven: **one shared RenderStepped ticker updates bindings; bindings write host properties directly; setState is never called at frame cadence** (beat cadence ≤3/s is permitted, e.g. GameResult's reveal counter).

## 0. Performance laws (apply to every recipe below)

| Law | Rule |
|---|---|
| CanvasGroup budget | Max **3 alive** at once, never per-list-row. Census: `Transition(screen)` = 1, `Transition(tab)` = 1 (only while `screen=="app"`), + 1 floating (GameResult matchup card OR Confetti — never both, see §8). PlayerCard uses **zero** CanvasGroups. |
| List rows | Entrances via position-offset + `TextTransparency`/`BackgroundTransparency` maps only (§6). No CanvasGroup, no per-row RenderStepped connection. |
| Text | Never animate TextScaled size. `AnimatedNumber` mandates `TextScaled = false`. Text *content* changes only at beat cadence or inside a single counting label. |
| Rotation | Rotated Frames (confetti) live **only** inside a `ClipsDescendants = true` CanvasGroup. |
| Connections | Exactly one `RenderStepped` connection app-wide (`Ticker`), created lazily, disconnected when idle. |
| Reduced motion | Every hook checks `Motion.reducedMotion()`; springs snap, timelines finish instantly, ambients are disabled. This makes Fade's false comment true. |
| Frame budget | Worst case (GameResult beat: ~12 slot motors + 2 score counts + confetti task + 2 ambients ≈ 20 ticker tasks) target < 0.5 ms/frame on low-end phone; each task is one `Solver.springStep` or one lerp. |

## 1. Module layout — `src/client/motion/`

```
src/client/motion/
  Solver.luau        -- EXISTS. Untouched.
  Ticker.luau        -- NEW: the one shared RenderStepped registry (non-React, pure wiring)
  Motion.luau        -- NEW: presets, types, pure helpers (window/alpha/countDuration) — lune-testable
  useMotor.luau      -- NEW: spring motor hook
  useSpring.luau     -- NEW: convenience motor tracking a prop
  useProgress.luau   -- NEW: eased normalized one-shot (Fade's engine, fixed)
  useChoreo.luau     -- NEW: seconds-clock one-shot for multi-element storyboards
  useStagger.luau    -- NEW: list-entrance orchestrator
  usePulse.luau      -- NEW: ambient looping driver
  init.luau          -- NEW: aggregator re-export
```

`init.luau` (so consumers write `local M = require(script.Parent.Parent.motion)`):

```luau
--!strict
local motion = {
	Solver = require(script.Solver),
	Ticker = require(script.Ticker),
	Motion = require(script.Motion),
	useMotor = require(script.useMotor),
	useSpring = require(script.useSpring),
	useProgress = require(script.useProgress),
	useChoreo = require(script.useChoreo),
	useStagger = require(script.useStagger),
	usePulse = require(script.usePulse),
}
return motion
```

New components (consumers of the library):

```
src/client/components/Transition.luau      -- replaces components/Fade.luau (Fade.luau is DELETED; App is its only consumer)
src/client/components/AnimatedNumber.luau  -- count-up label
src/client/components/Confetti.luau        -- celebration burst (GameResult win, History new title, Offseason champion)
```

## 2. `Motion.luau` — tokens & pure helpers

```luau
--!strict
-- Motion vocabulary: every duration/spring/distance in the app comes from here.
-- Pure except reducedMotion(); helpers are lune-testable (add cases to tests/motion.luau).

export type MotorConfig = {
	frequency: number?, -- Hz, passed to Solver.springStep
	damping: number?,   -- ratio, passed to Solver.springStep
	epsilon: number?,   -- rest threshold for Solver.springDone; default 1e-3
}

export type TimelineConfig = {
	duration: number?,             -- seconds; default Motion.dur.base
	delay: number?,                -- seconds held at 0 before starting; default 0
	easing: ((number) -> number)?, -- default Solver.easeOutCubic
	onComplete: (() -> ())?,
}

export type StaggerConfig = {
	count: number,                 -- item count this trigger cycle
	step: number?,                 -- default Motion.stagger.step (0.045)
	span: number?,                 -- default Motion.stagger.span (0.26)
	delay: number?,                -- lead-in, default 0
	easing: ((number) -> number)?, -- per-item, default Solver.easeOutQuint
	maxTotal: number?,             -- default Motion.stagger.maxTotal (0.9); step compresses to fit
}

export type PulseConfig = {
	period: number,          -- seconds per cycle
	waveform: "sine" | "sweep"?, -- default "sine"
	active: number?,         -- sweep only: seconds of the period spent going 0→1 (rest holds 0)
	enabled: boolean?,       -- default true; false parks the binding at 0 and frees the ticker task
}
```

Presets (exact values — implementers never invent numbers):

```luau
Motion.spring = {
	snappy = { frequency = 8,   damping = 1 },    -- press-down; settles ~0.12s, no overshoot
	pop    = { frequency = 5,   damping = 0.58 }, -- release/entrance pop; ~10% overshoot, ~0.35s
	slide  = { frequency = 4.5, damping = 0.82 }, -- tab pill, panel slides; ~1% overshoot, ~0.3s
	gentle = { frequency = 3,   damping = 1 },    -- hovers, color/transparency eases; ~0.25s
	bounce = { frequency = 3.4, damping = 0.45 }, -- celebrations, badge lands; ~20% overshoot, ~0.6s
	shake  = { frequency = 8,   damping = 0.15 }, -- decaying-sine screen shake (impulse only)
	lazy   = { frequency = 1.8, damping = 1 },    -- ambient drift back to rest
}

Motion.dur = { whip = 0.09, fast = 0.14, base = 0.22, slow = 0.32, hero = 0.55 }

Motion.stagger = { step = 0.045, span = 0.26, maxTotal = 0.9 }

Motion.dist = { rise = 14, slide = 24, drop = 10, kick = 6 } -- px
```

Pure helpers:

```luau
-- Windowed sub-animation inside a seconds-clock choreography (see useChoreo).
function Motion.window(t: number, start: number, duration: number, easing: ((number) -> number)?): number
	-- clamp((t - start) / duration, 0, 1) passed through easing (default Solver.easeOutCubic)
end

-- Entrance alpha: p=0 fully transparent, p=1 at restTransparency.
function Motion.alpha(p: number, restTransparency: number?): number
	-- return 1 - (1 - (restTransparency or 0)) * p
end

-- AnimatedNumber magnitude rule.
function Motion.countDuration(delta: number): number
	-- |delta| <= 3 → 0.25 ; <= 20 → 0.45 ; <= 120 → 0.7 ; else 0.9
end

-- Cached UserGameSettings.ReducedMotion (pcall-guarded; GetPropertyChangedSignal keeps it fresh;
-- defaults false if the API is unavailable).
function Motion.reducedMotion(): boolean
```

## 3. `Ticker.luau` — the shared frame loop

**Decision: one shared RenderStepped connection with a central registry, not per-hook connections.** Justification: worst-case screens run 20+ simultaneous animations (30-row stagger + button springs + ambients); one connection plus a task array costs O(1) event overhead and makes cleanup a table flag instead of a Disconnect storm.

```luau
--!strict
-- One RenderStepped connection for every animation in the app. Tasks are functions
-- (dt) -> boolean; returning true (or erroring) removes the task. The connection is
-- created on the first add and disconnected when the registry empties.

export type TickerTask = (dt: number) -> boolean
export type CancelFn = () -> ()

function Ticker.add(fn: TickerTask): CancelFn
function Ticker.count(): number -- active tasks, for debugging/perf assertions
```

Implementation contract:
- Registry: `local tasks: { { fn: TickerTask, dead: boolean } } = {}`; `local conn: RBXScriptConnection? = nil`.
- `add`: `table.insert`; if `conn == nil`, `conn = RunService.RenderStepped:Connect(step)`. Returns `function() entry.dead = true end` (idempotent).
- `step(dt)`: iterate `for i = #tasks, 1, -1 do` (reverse ⇒ `table.remove(tasks, i)` is safe mid-loop). For each live entry: `local ok, done = pcall(entry.fn, dt)`; remove if `entry.dead or not ok or done`; on `not ok`, `warn` the error once (Studio only via `RunService:IsStudio()`). After the loop, if `#tasks == 0` then `conn:Disconnect(); conn = nil`.
- Tasks may call `Ticker.add` from inside a task (insert at end; reverse iteration skips it until next frame — acceptable and documented).

## 4. Hooks

General contract for all hooks: bindings come from `React.useBinding` (remember: the updater is a **free function** `setB(v)`, `getValue` is a **method**); ticker tasks are only ever registered from event handlers/effects, never during render; every hook cancels its task in a `useEffect(function() return cleanup end, {})` teardown; every hook obeys `Motion.reducedMotion()`.

### 4.1 `useMotor` — the spring primitive

```luau
--!strict
export type MotorApi = {
	setTarget: (target: number, config: Motion.MotorConfig?) -> (), -- spring toward target
	snap: (value: number) -> (),      -- cancel motion, jump, zero velocity
	impulse: (velocity: number) -> (),-- add velocity (units/sec), keep current target
	stop: () -> (),                   -- freeze at current value (velocity zeroed)
	getValue: () -> number,
	getVelocity: () -> number,
}

local function useMotor(initial: number, config: Motion.MotorConfig?): (React.Binding<number>, MotorApi)
```

Semantics (exact):
- Internal state in a `useRef`-held table created once: `{ state = { x = initial, v = 0 } :: Solver.SpringState, target = initial, base = config, override = nil, cancel = nil :: Motion? }`. The returned `MotorApi` table is also created once (stable identity — safe in deps arrays).
- `setTarget(t, c)`: store `target = t`, `override = c`; if `Motion.reducedMotion()` → behave as `snap(t)`. Else `ensureRunning()`.
- `ensureRunning()`: if no active cancel, `cancel = Ticker.add(stepFn)`. `stepFn(dt)`: `state = Solver.springStep(state, target, dt, override or base)`; if `Solver.springDone(state, target, (override or base or {}).epsilon)` then `state = { x = target, v = 0 }; setB(target); cancel = nil; return true` else `setB(state.x); return false`.
- `snap(v)`: cancel task if any, `state = { x = v, v = 0 }`, `target = v`, `setB(v)`.
- `impulse(v)`: no-op under reduced motion; else `state.v += v; ensureRunning()`. (Used for pulses/shakes: the motor rings around its unchanged target.)
- `stop()`: cancel task, `state.v = 0`, `target = state.x`.
- Unmount cleanup cancels any active task.
- Config priority: per-call `override` > hook `config` > Solver defaults (4 Hz, critical).
- Two-axis positions: join motors — `React.joinBindings({ x = xB, y = yB }):map(function(v) return UDim2.fromOffset(v.x, v.y) end)` (annotate the join result or map immediately; joined bindings are read-only).

### 4.2 `useSpring` — track a prop

```luau
local function useSpring(target: number, config: Motion.MotorConfig?): React.Binding<number>
-- useMotor(target, config); useEffect({ target }) → api.setTarget(target).
-- First render mounts AT target (no entrance). config is captured at mount; later changes ignored (documented).
```

Use for: TabBar pill position, fog-of-war bar edges, progress-bar fills that must re-track server data.

### 4.3 `useProgress` — eased one-shot 0→1 (Fade's fixed engine)

```luau
export type ProgressApi = {
	replay: () -> (),  -- restart from 0
	finish: () -> (),  -- snap to 1, fire onComplete (SKIP / reduced-motion path)
	reset: () -> (),   -- snap to 0 without playing
}

local function useProgress(trigger: any, config: Motion.TimelineConfig?): (React.Binding<number>, ProgressApi)
```

Semantics:
- Binding **initializes at 0** (content mounts invisible — this kills Fade's one-frame flash; the audit's `useBinding(1)`-then-effect bug must not be reproduced).
- `useEffect({ trigger })` calls `replay()` — so it plays on mount and on every trigger change. `trigger = nil` means "once on mount".
- `replay()`: cancel any task; if reduced motion → `setB(1)` + `onComplete()`. Else register one ticker task accumulating `elapsed += dt`; `raw = math.clamp((elapsed - delay) / duration, 0, 1)`; `setB(easing(raw))`; done at `raw >= 1` → `onComplete()`.
- The returned binding is **eased**. For multi-element choreography use `useChoreo` instead.

### 4.4 `useChoreo` — seconds clock for storyboards

```luau
local function useChoreo(trigger: any, total: number, onComplete: (() -> ())?): (React.Binding<number>, ProgressApi)
-- Binding carries ELAPSED SECONDS, clamped to `total`, linear. Same replay/finish/reset API.
```

Elements subscribe with windows in real seconds:

```luau
TextTransparency = clock:map(function(t)
	return Motion.alpha(Motion.window(t, 0.30, 0.25, Solver.easeOutCubic))
end),
```

`finish()` snaps the clock to `total` — every windowed map lands on its rest value in one frame. This is the universal SKIP mechanism.

### 4.5 `useStagger` — list entrances that scale to 30 rows

```luau
export type StaggerApi = {
	item: (index: number) -> React.Binding<number>, -- eased 0→1 for that row (memoized per index)
	skip: () -> (),
}

local function useStagger(trigger: any, config: Motion.StaggerConfig): StaggerApi
```

Semantics:
- ONE ticker task drives one hidden seconds binding. `item(i)` returns a cached `clock:map(function(t) return easing(Solver.staggerProgress(t, i, step, span)) end)` — Solver's helper takes raw seconds directly.
- Total = `delay + (count - 1) * step + span`; task ends there. If total > `maxTotal`, compress: `step = math.max(0.012, (maxTotal - span) / math.max(count - 1, 1))`. A 30-row roster at defaults therefore lands in ≤ 0.9 s.
- Reduced motion / `skip()`: clock snaps to total; every item binding reads 1.
- Cost: 1 connection-task, 1 binding update/frame, N mapped property writes — **no CanvasGroups, no per-row connections, no setState.**

### 4.6 `usePulse` — ambient loops

```luau
local function usePulse(config: Motion.PulseConfig): React.Binding<number>
-- "sine": binding = 0.5 - 0.5 * math.cos(2π * elapsed / period)  (starts at 0, peaks mid-period)
-- "sweep": binding = clamp(cycleElapsed / active, 0, 1); holds 1... no — holds 0 after the sweep:
--          p = cycleElapsed < active and cycleElapsed / active or 0  (one 0→1 wipe per period)
-- enabled=false or reducedMotion → binding parked at 0, no ticker task registered.
```

The task registers on mount (when enabled) and cancels on unmount or when `enabled` flips false (`useEffect({ config.enabled })`).

## 5. The cheap per-row entrance recipe (mandatory for all lists)

Rows sit under `UIListLayout`, which owns their `Position` — so the row itself is a **transparent fixed-size container** and the animated surface is a single inner Frame:

```
row (Frame, BackgroundTransparency = 1, Size = list-managed)   ← UIListLayout child, keyed by domain id
└── inner (Frame: the visible card — background, stroke, labels)
      Position    = b:map(function(p) return UDim2.fromOffset(math.floor(-Motion.dist.rise * (1 - p)), 0) end)
      BackgroundTransparency = b:map(function(p) return Motion.alpha(p, REST_BG_T) end)
      └── each TextLabel: TextTransparency = b:map(function(p) return Motion.alpha(p, 0) end)
      └── UIStroke: Transparency = b:map(function(p) return Motion.alpha(p, Theme.strokeT) end)
```

where `b = stagger.item(i)`. Horizontal variants use X offset (`-18` for tables). Exactly zero CanvasGroups; strokes/gradients ride their own transparency maps. `math.floor` on pixel offsets avoids shimmer.

## 6. Screen transition system — `components/Transition.luau`

**Decision: enter-only choreography, keyed by trigger.** React-lua exit animations require deferring unmount, which means double-rendering old+new trees in two CanvasGroups on every nav — that busts the ≤3 budget during the most common interaction. Instead: content mounts at progress 0 (invisible — no flash), enters with direction; where an "exit" is emotionally required (sim → result), the incoming screen opens with a full-bleed cover beat (GameResult's matchup card, §8) that functions as the exit mask. The **only** deferred unmount in the app is self-owned modal close (PlayerCard, §7.5), which the modal itself sequences before calling `onClose`.

```luau
--!strict
-- Replaces Fade.luau (deleted). App is the only consumer; the `trigger` contract is preserved.

type Props = {
	trigger: string,          -- replay entrance on change
	dir: number?,             -- 1 = slide in from right, -1 = from left, nil/0 = rise from below
	duration: number?,        -- default Motion.dur.base (0.22)
	distance: number?,        -- default Motion.dist.rise (dir nil) / Motion.dist.slide (dir ±1)
	onComplete: (() -> ())?,
	children: { [string]: any }?,
}
```

Render: one `CanvasGroup` (fromScale(1,1), transparent, BorderSizePixel 0) with `p, api = useProgress(props.trigger, { duration = duration, easing = Solver.easeOutQuint, onComplete = onComplete })`:

- `GroupTransparency = p:map(function(v) return 1 - v end)`
- `Position = p:map(function(v)
    local d = math.floor(distance * (1 - v))
    if dir == 1 then return UDim2.fromOffset(d, 0)
    elseif dir == -1 then return UDim2.fromOffset(-d, 0)
    else return UDim2.fromOffset(0, d) end
  end)`

**App wiring (edits to `src/client/App.luau`):**
- Require `Transition` instead of `Fade`; both call sites keep their triggers: root `e(Transition, { trigger = screen }, …)`, tab pane `e(Transition, { trigger = tab, dir = tabDir }, …)`.
- App holds `local TAB_ORDER = { "Season", "Roster", "League", "HQ", "Career", "History" }` and a `prevTabRef = React.useRef(tab)`; on tab change compute `tabDir = math.sign(indexOf(newTab) - indexOf(prevTabRef.current))`, update the ref. Tabs now read spatially (League→HQ slides left-to-right; going back slides the other way).
- Screen-level transitions use `dir = nil` (rise), except `menu → select` uses `dir = 1` and `select → menu` `dir = -1` (App passes a `screenDir` computed the same way from a small ordered pairs table; anything unlisted → nil).

**Per-screen entrance recipes** (what plays inside the screen, on top of the Transition; each screen owns its hooks):

| Screen | Recipe (element → property, from→to, driver) |
|---|---|
| **Menu** | `useChoreo("menu", 0.9)`. kicker: TextTransparency win(0, 0.18); accent bar: Size X.Scale 0→0.14 win(0.08, 0.22, easeOutQuint); GRIDIRON: X offset −30→0 + fade win(0.14, 0.28, easeOutQuint); GM: same win(0.22, 0.28); tagline: fade win(0.30, 0.25); CTA block: Y offset +18→0 win(0.38, 0.37, easeOutBack) + fade; footer: fade→0.4 win(0.5, 0.3). Ambient: §9. |
| **TeamSelect** | `useStagger("select", { count = 12, step = 0.05, span = 0.3 })` grid cascade per §5 (Y +16, easeOutQuint). Pick ceremony: chosen card UIScale motor `setTarget(1.04, Motion.spring.bounce)`; other 11 cards: per-card gentle motor → label TextTransparency +0.4; confirm bar: Y offset motor 64→0, `Motion.spring.slide`. Pending state freezes motors (`stop()`), confirm button shows loading. |
| **Dashboard** | Matchup card: inner Y +12→0 + fade, `useProgress` win via choreo(0.5): card [0, 0.25]; SIM button UIScale 0.94→1 easeOutBack [0.12, 0.28]; week progress bar fill `useSpring(week/totalWeeks, Motion.spring.gentle)`; news rows `useStagger(tab, { count = n, step = 0.04, span = 0.24 })`, X −12→0. |
| **Roster** | Rows `useStagger(tab, { count = #roster, step = 0.035, span = 0.24, maxTotal = 0.8 })`, X −18→0 per §5. **No per-row count-ups** (30 text relayouts — banned; count-ups are for ≤4 hero numbers per screen). |
| **LeagueTable** | Rows stagger step 0.03 (data table = brisk), X −14→0; after own row's entrance (+0.3 s) my-row UIStroke ambient `usePulse({ period = 2.4 })` mapping Transparency 0.9↔0.6. |
| **DraftRoom** | Board rows stagger (step 0.04, span 0.26); fog bars per prospect: two `useSpring` motors (min, max edges, `Motion.spring.slide`) — they squeeze visibly when the draft prop replaces after a scout; collapse (fog ≤ 2): fill flashes gold via a flash motor (snap 1 → target 0, gentle) lerping Color3 gold→ovrColor + UIScale pop `impulse(3.0)`. ON THE CLOCK: §9. |
| **FreeAgency** | Rows stagger; header credits = `AnimatedNumber`; signed-row send-off: row retains a local ghost 0.45 s — overlay "SIGNED ✓", inner X motor `setTarget(40, Motion.spring.gentle)` + fade `useProgress(nil, { duration = 0.3 })`, then release local state. |
| **Facilities** | Cards stagger step 0.06 span 0.3, Y +16→0 easeOutBack; pip earn (usePrevious level): new pip UIScale 0→1 `Motion.spring.bounce` + color flash motor gold→flag over 0.5 s. |
| **CareerProfile** | Bars: `useSpring(value/100, Motion.spring.slide)` fills, second bar mounts its target 0.12 s later (`task.delay` in mount effect); dynasty score `AnimatedNumber` 0→score (`animateOnMount = true`); 4 stat tiles: `AnimatedNumber`s with mount delays i*0.08. |
| **History** | Trophies: stagger step 0.08 span 0.25, UIScale 0→1 easeOutBack; banner counters `AnimatedNumber` (`animateOnMount = true`); rows stagger; championship rows: one-shot gold sheen — `useProgress(nil, { delay = rowDelay + 0.2, duration = 0.6 })` mapping UIGradient.Offset X −1→2. |
| **Offseason** | Ceremony `useChoreo("offseason", 2.2)`: champion card slide+fade [0, 0.5]; credits `AnimatedNumber` (mount delay 0.5) + gold stroke flash at land; retirements [1.0+, rows step 0.05]; rookies [1.4+, step 0.06]; START YEAR button Y +18→0 easeOutBack [1.9, 0.3]. Tap anywhere before done → `api.finish()` + AnimatedNumbers get `snap = true`. |
| **CareerDecision** | `useChoreo("career", 1.6)`: verdict card scale 1.06→1 + fade [0, 0.35, easeOutQuint]; FIRED variant adds full-screen flagDeep tint fade [0, 0.5] and screen shake — X-offset motor `Motion.spring.shake`, `impulse(260)` (≈5 px decaying sine, ~0.5 s); rep-delta chip UIScale 0→1 pop [0.55]; offer cards Y +20→0 easeOutBack, step 0.12 [0.8+]. |
| **GameResult** | Full storyboard — §8. |

## 7. Micro-interactions

### 7.1 Button (`components/Button.luau` upgrade)

Kill `AutoButtonColor` (it fights the gradient). Add a child `UIScale` + three motors:

| State | Recipe |
|---|---|
| Press down (`InputBegan`, touch/mouse1) | scale motor `setTarget(0.96, Motion.spring.snappy)`; press motor (0→1, snappy) maps BackgroundColor3 `base:Lerp(Theme.flagDeep, 0.35 * p)` |
| Release/Activated | scale `setTarget(1, Motion.spring.pop)` → natural ~1.005 overshoot; press motor `setTarget(0, gentle)`; `Sound.play("click")` |
| Release outside (`InputEnded` w/o Activated) | same targets, no sound |
| Hover (`MouseEnter`/`MouseLeave`) | hover motor 0↔1 (`gentle`): UIStroke.Transparency `0.82 → 0.45` (`hover:map(p → 0.82 - 0.37*p)`); gradient brighten: bind UIGradient.Color to `hover:map(p → ColorSequence.new(Theme.flag:Lerp(Color3.new(1,1,1), 0.08*p), Theme.flagDeep))` (allocs only during the 0.15 s ease — fine) |
| Disabled toggle | dim motor 0↔1 (`gentle`, 0.14 s): TextTransparency 0→0.5, BackgroundColor3 lerp → Theme.field3 — no more instant snap |

New prop: `sfx: string?` (default `"click"`, `""` to silence) played at Activated.

### 7.2 TabBar active-pill slide

- Render ONE pill Frame as a sibling *behind* the six buttons (ZIndex below), `Size = UDim2.new(1/#TABS, -12, 1, -16)`.
- `local xB = useSpring((activeIndex - 1) / #TABS, Motion.spring.slide)` where `activeIndex` derives from `props.active`; `Position = xB:map(function(x) return UDim2.new(x, 6, 0, 8) end)`. The pill glides and lightly overshoots between slots; on first mount it sits at rest (useSpring semantics).
- Icon bounce on becoming active: per-tab Y motor `snap(0)` then `impulse(-90)` with `{ frequency = 4, damping = 0.5 }` — icon hops ~4 px and settles.
- Label crossfade: per-tab active motor 0↔1 (`gentle`) mapping TextTransparency inactive 0.35 ↔ active 0 (replaces the hard color swap).
- Press dip: per-tab UIScale `setTarget(0.9, snappy)` on down, `setTarget(1, pop)` on up; `Sound.play("tick")` on select.
- Badge dot (future-proof): mounts with scale motor `snap(0)` → `setTarget(1, Motion.spring.bounce)`.

### 7.3 Credit-pill pulse (TopBar)

On `props.credits` change (usePrevious ref):
- Value: `AnimatedNumber` (right-aligned, fixed TextSize 16).
- Pill UIScale motor: `snap(1)` then `impulse(3.5)` with `Motion.spring.pop` → ~1.07 peak, rings once.
- Gold flash: stroke motor `snap(0.1)` → `setTarget(0.55, Motion.spring.gentle)`.
- Gain vs spend: number TextColor3 flash binding — flash motor 1→0 (gentle) lerping `Theme.green` (gain) / `Theme.flag` (spend) → `Theme.gold` rest.

Record odometer (TopBar "9-5" → "10-5"): container `ClipsDescendants = true`, height H; two stacked labels — current at Y-offset 0, incoming (new text) at Y-offset H; roll motor `snap(0)` → `setTarget(-H, Motion.spring.slide)`; both labels' Position bound to `roll:map(offset)` and `roll:map(offset + H)`; when the motor rests (schedule `task.delay(0.35)` in the same effect), swap current text and `snap(0)`. ~12 lines, local to TopBar.

### 7.4 `components/AnimatedNumber.luau`

```luau
--!strict
export type Props = {
	value: number,
	format: ((n: number) -> string)?,          -- default: tostring(math.floor(n + 0.5))
	durationFor: ((delta: number) -> number)?, -- default Motion.countDuration
	easing: ((p: number) -> number)?,          -- default Solver.easeOutExpo ("lands softly")
	animateOnMount: boolean?,                  -- default false: mounts showing `value`
	snap: boolean?,                            -- true: value changes apply instantly (skip mode)
	font: Enum.Font?,                          -- default Theme.font.display
	textColor3: (Color3 | React.Binding<Color3>)?,
	textSize: number?,                         -- default 16. TextScaled is HARD-CODED false.
	textXAlignment: Enum.TextXAlignment?,      -- default Right (digits grow leftward, no jitter)
	size: UDim2?, position: UDim2?, anchorPoint: Vector2?, layoutOrder: number?, zIndex: number?,
}
```

Semantics: displayed value lives in a binding; on `value` change (`useEffect({ value })`) run one ticker task lerping shown→value over `durationFor(math.abs(delta))` through `easing`, `Text = b:map(format)`. `snap = true` or reduced motion → `setB(value)` immediately. Only the Text property of ONE label relayouts per frame — acceptable; never combine with TextScaled.

### 7.5 PlayerCard modal (mount/unmount choreography)

- Enter (on mount): scrim BackgroundTransparency `useProgress(nil, { duration = 0.18 })` 1→0.45; card UIScale motor `snap(0.92)` → `setTarget(1, Motion.spring.pop)` + card Y motor 10→0 (slide). Attribute bars: `useStagger(nil, { count = 3, step = 0.07, span = 0.3 })` driving fill Size X.Scale 0→value/99; OVR = `AnimatedNumber` (`animateOnMount = true`, textColor3 bound to a ride binding lerping chalkSoft→ovrColor as it climbs).
- Exit (the app's one deferred unmount): modal owns a `closing` state; close tap → `setClosing(true)`, scrim/card reverse via a 0.12 s `useProgress` (scale target 0.94, fades), and `task.delay(0.13, props.onClose)`. Guard double-fire with a ref.
- Zero CanvasGroups: scrim is one Frame; the card fades by scale+position only.

## 8. THE FLAGSHIP — GameResult cinematic storyboard

Chassis: keep the audit-endorsed cancelable director (`task.spawn` walk + `running`/generation-counter guard), upgraded to a **beat list with variable cadence**. Frame-rate work stays in bindings; the director only calls `setRevealed(i)` / motor APIs at beat cadence.

Constants block at top of the rebuilt `screens/GameResult.luau`:

```luau
local CADENCE = {
	normal = 0.42,        -- per routine play
	fastNormal = 0.34,    -- used when #plays > 26
	bigPre = 0.50,        -- held breath BEFORE a play.big reveals
	bigHold = 1.0,        -- dwell after a big play
	scoreHold = 0.9,      -- dwell after any score change
	quarterBreak = 0.6,   -- interstitial when play.quarter increments
	finalPre = 0.8,       -- held breath before plays[#plays]
	doneHold = 0.7,       -- silence between last play and the verdict
}
```

Score-change detection: compare each play's homeScore/awayScore to the previous revealed play (first play compares to 0-0).

**Phase A — Matchup card intro (~1.75 s).** Full-bleed cover; this is the exit mask for whatever screen preceded. The card is the screen's ONE CanvasGroup (besides the App Transition). `useChoreo("intro", 1.75)`:

| t (s) | Beat |
|---|---|
| 0.05 | Away team block slides in from left: X offset −0.35·width→slot via win(0.05, 0.45, easeOutQuint), name fade win(0.05, 0.2). `Sound.play("swoosh")`. |
| 0.20 | Home block mirrors from the right. `Sound.play("swoosh", { speed = 0.94 })`. |
| 0.42 | Center chip (game.label — "WEEK 7" / "SEMIFINALS" / "CHAMPIONSHIP") UIScale 0→1 win(0.42, 0.3, easeOutBack); label == "Championship" → chip stroke Theme.gold. `Sound.play("pop")`. |
| 0.90 | "KICKOFF" sub-line fade win(0.9, 0.2); `Sound.play("drumroll", { volume = 0.3 })`. |
| 1.40 | Card CanvasGroup GroupTransparency 0→1 win(1.4, 0.3, easeInOutCubic) while the persistent scoreboard header (already laid out) fades in + drops Y −12→0 win(1.45, 0.25). Card unmounts at choreo complete → CanvasGroup freed. |

**Phase B — Play-by-play.** Persistent scoreboard: abbr + `AnimatedNumber` score per side (right-aligned columns — digits never drift) + quarter chip "Q1 12:00" updated per beat.

- Ticker list: **no UIListLayout** — a rolling window of the latest ≤ 10 mounted rows (keyed `play_<index>`), absolutely positioned by a per-row slot motor: Y target = `(slot - 1) * 40`; when a new play mounts, every live row's slot prop +1 → `useEffect({ slot })` → `motor.setTarget(newY, Motion.spring.slide)`. New row: motor `snap(slotY(1) - 12)` → target slot 1, inner text fade `useProgress(nil, { duration = 0.22 })`. Rows past slot 10 unmount (full list returns in Phase D). ≤ 10 motors briefly active per beat.
- Normal play: cadence `normal`. Row text chalkSoft, no extras.
- **Big play** (`play.big`): director waits `bigPre` (held breath — quarter chip dims slightly via a beat-set binding), then reveals: row inner UIScale `snap(0.96)` → `setTarget(1, pop)`, flag-colored left rail, bold text; scoreboard flash strip — a full-width Theme.flag Frame over the scoreboard, BackgroundTransparency motor `snap(0.75)` → `setTarget(1, gentle)` (~0.25 s sweep of heat); `Sound.play("pop", { speed = 0.9, volume = 0.6 })`; dwell `bigHold`. |
- **Score change**: the scoring side's `AnimatedNumber` counts (duration 0.4); its label UIScale motor `impulse(3.5)` (pop ring); TextColor3 flash gold→rest over 0.5 s (flash motor). TD (delta ≥ 6): also fire the flash strip + `Sound.play("pop", { speed = 0.85 })`; FG (delta 3): `Sound.play("tick", { speed = 1.15 })`. Dwell `scoreHold`.
- **Quarter transition** (quarter increments): chip dips — UIScale `snap(0.85)` → `setTarget(1, pop)` with text swapped 0.06 s into the dip (`task.delay`); a 1-px chalk line sweeps across the ticker area (Size X.Scale 0→1, easeOutQuint 0.4 s, Transparency 0.7, then fades); `Sound.play("tick")`; dwell `quarterBreak`.
- **Final play**: wait `finalPre` first (`Sound.play("drumroll", { volume = 0.45 })`), reveal, then `Sound.play("whistle", { speed = 1.1, volume = 0.3 })` as the final gun; quarter chip text → "FINAL".

**Phase C — The verdict (asymmetric by design).** After `doneHold`:

WIN:
1. t=0: `Sound.play("stinger_win")` (ducks UI group, §10); winner scoreboard row gold UIStroke bloom — stroke motor `snap(1)` → `setTarget(0.1, pop)`, then ambient `usePulse({ period = 2.2 })` breathing 0.1↔0.45.
2. t=0.15: Banner — the word "VICTORY" pre-split into one TextLabel per letter inside a banner Frame; `useStagger(nil, { count = 7, step = 0.04, span = 0.22, easing = Solver.easeOutBack })`: per letter Y +18→0 + TextTransparency 1→0; banner container UIScale `snap(0.9)` → `setTarget(1, pop)`; banner text Theme.gold, stroke chalk.
3. t=0.35: `Confetti { play = true }` (§8.1) — the screen's floating CanvasGroup slot (matchup card is long gone; census stays ≤ 3).
4. t=0.5: Phase D begins.

LOSS: no confetti, no gold. `Sound.play("stinger_loss")` (low thud). "DEFEAT" single label slides down Y −12→0 over 0.5 s easeOutCubic, color chalkSoft; a field3 full-screen tint fades to Transparency 0.65 over 0.6 s (somber dim); winner row gets a plain chalk stroke, no bloom. Phase D at t=0.6.

**Phase 8.1 — `components/Confetti.luau`:**

```luau
export type Props = {
	play: boolean,
	origin: UDim2?,     -- default UDim2.fromScale(0.5, 0.42)
	count: number?,     -- default 24, hard-clamped ≤ 32
	onDone: (() -> ())?,
}
```

- ONE CanvasGroup (fromScale(1,1), `ClipsDescendants = true` — the only legal home for rotated Frames), containing `count` Frames of 6×10 px, BorderSizePixel 0.
- Colors: 8 × Theme.gold, 8 × Theme.flag, 5 × Theme.chalk, 3 × Theme.green (proportional if count ≠ 24).
- Per-particle params generated once at burst (client cosmetic — `math.random` allowed here): spawn = origin ± (30, 10) px; `vy ∈ [−430, −260]` px/s (up), `vx ∈ [−180, 180]`, gravity 620 px/s², `rot0 ∈ [0, 360)`, `vr ∈ ±[240, 520]` deg/s; lifetime 1.6 s, fade over the last 0.4 s.
- ONE elapsed-seconds binding driven by ONE ticker task; each particle's Position/Rotation/BackgroundTransparency are `elapsed:map(closure over its params)` — 1 binding update, 72 mapped writes/frame, for 1.6 s. Task ends → `onDone` → parent flips `play` false and the CanvasGroup unmounts.
- Reduced motion: never mounts particles; `onDone` fires immediately.

**Phase D — Stats reveal.** Box score (`game.result.home/away`: passYards, rushYards, turnovers): three comparison rows, `useStagger(nil, { count = 3, step = 0.07, span = 0.3 })`: row label fades, left/right `AnimatedNumber`s count (durations from magnitude rule; right side delayed 0.1 s via mount `task.delay`), and center comparative bars fill via `useSpring(share, Motion.spring.slide)` (bar Frames have no children — Size animation is relayout-free). CONTINUE button enters last: Y +18→0 easeOutBack + `usePulse` stroke breathing (period 2.6 s, 0.82↔0.5). The rolling ticker crossfades out (rows' inner transparency → 1 over 0.15 s) and the full-plays ScrollingFrame mounts statically behind it.

**SKIP (must look intentional):**
- The SKIP button is visible through Phases A–B (secondary Theme.field2 styling, kept from current file).
- Skip during A/B: bump the director generation (cancels all pending `task.wait`s), unmount the matchup card and rolling ticker instantly, set `revealed = #plays`; scores count to final with `AnimatedNumber` duration override 0.3 s; then **Phase C and D play normally** — the player always gets the verdict moment, just sooner.
- Skip during C/D (button reads "CONTINUE ▸" by then — second press): every motor `snap`s to rest, every choreo `finish()`es, AnimatedNumbers get `snap = true`, Confetti unmounts, stats sit at final values, CONTINUE is present. One frame later the screen is the designed end-state — a composition, not a glitch.
- Reduced motion: behaves as an automatic skip-to-C with instant D.

## 9. Ambient life (idle motion)

All ambients run through `usePulse` (auto-disabled under reduced motion). Hard cap: ≤ 4 ambient tasks alive per screen; each is 1 shared-ticker task writing 1–3 properties/frame.

| Where | Recipe | Perf note |
|---|---|---|
| App root background | Root UIGradient Offset: `usePulse({ period = 9 })` mapping `Offset = Vector2.new(0, 0.04 * (p - 0.5))` — the field breathes | 1 write/frame; gradient re-render is GPU-trivial |
| Dashboard SIM button sheen | Second UIGradient on the button (chalk band, Transparency mostly 1 with a tight 0.85 window); `usePulse({ period = 5, waveform = "sweep", active = 0.9 })` mapping `Offset = Vector2.new(-1 + 2 * p, 0)` | Only exists on Dashboard; 1 write/frame; disabled while pressed |
| Dashboard SIM button stroke | `usePulse({ period = 2.8 })` stroke Transparency 0.82↔0.55 — the main verb invites the press | shares phase with sheen? No — independent; both cheap |
| DraftRoom "ON THE CLOCK" | When `isMyPick`: header UIStroke `usePulse({ period = 1.1 })` 0.8↔0.35 + PICK buttons UIScale `1 + 0.015 * p` (same pulse binding reused via map — 1 task total); `enabled = isMyPick` | Frees itself the moment the pick is made |
| Menu wordmark shine | UIGradient on GRIDIRON/GM labels (chalk→white→chalk tight band): `usePulse({ period = 4.5, waveform = "sweep", active = 0.8 })` Offset −1→2 | 2 writes/frame |
| Menu yard lines | 3 stripes X pixel offset `±3 * sin` via one `usePulse({ period = 14 })` binding mapped thrice | 3 writes/frame |
| LeagueTable my-row | Stroke pulse (see §6 table) | 1 write/frame |
| GameResult winner row / CONTINUE | Specified in §8 | — |

Banned ambients: anything animating TextScaled text, anything per-list-row, anything requiring a CanvasGroup.

## 10. Sound choreography

`Sound.luau` keeps its never-fatal contract and gains: per-sound config `{ id, volume, canOverlap }`, clone-play-destroy for overlappables, `PlaybackSpeed = 0.95 + math.random() * 0.1` jitter by default, a "UI" SoundGroup + "Stinger" SoundGroup, and `Sound.play(name, opts: { volume: number?, speed: number? }?)`. Ducking rule: playing either stinger sets the UI group volume to 0.3 for 1.0 s with a 0.3 s linear recover (single ticker task).

New slots (6) — ids to be picked from the free Roblox library (search terms given; swap-anytime per the file's existing comment):

| Name | Role | Vol | Overlap | Library search |
|---|---|---|---|---|
| `tick` | tab select, quarter chip, FG score, sort chips | 0.25 | yes | "UI tick click short" |
| `swoosh` | screen transitions, matchup blocks, modal open | 0.3 | yes | "whoosh short UI" |
| `stinger_win` | WIN banner (ducks UI) | 0.6 | no | "success fanfare short stinger" |
| `stinger_loss` | LOSS verdict (ducks UI) | 0.5 | no | "low thud defeat" |
| `drumroll` | final-play pre-beat, KICKOFF, draft final pick | 0.35 | no | "short drumroll" |
| `pop` | chip/badge pops, big plays, TDs, confetti burst | 0.4 | yes | "pop bubble UI" |

Beat → sound map (complete; anything not listed is silent):

| Motion beat | Sound |
|---|---|
| Button Activated (all) | `click` (existing id, finally wired) — via Button's `sfx` prop |
| Tab select | `tick` |
| Row/card press (Roster, TeamSelect, offers) | `tick` at 0.18 volume |
| Screen Transition (screen-level only, not tabs) | `swoosh` at 0.25 |
| PlayerCard open / close | `swoosh` / `swoosh` speed 1.1 |
| Sim pressed | `whistle` (existing, unchanged) |
| Matchup blocks in | `swoosh` ×2 (§8 A) |
| Label chip pop / KICKOFF | `pop` / `drumroll` 0.3 |
| Big play / TD / FG | `pop` 0.6 speed 0.9 / `pop` speed 0.85 / `tick` speed 1.15 |
| Quarter change | `tick` |
| Final play | `drumroll` 0.45 then `whistle` speed 1.1 vol 0.3 |
| WIN / LOSS | `stinger_win` / `stinger_loss` (+duck) |
| Confetti burst start | `pop` 0.5 |
| Credits gain/spend land | `cash` (existing) at the AnimatedNumber's completion, not at press |
| Draft pick confirmed | `pick` (existing) |
| ON THE CLOCK flip | `drumroll` 0.4 |
| FIRED verdict | `whistle` speed 0.8 vol 0.5 |
| Achievement/trophy pop (History) | `pop` |
| Count-ups | **no per-tick sounds** (chatty) |

## 11. Verification & definition of done

- `Motion.window`, `Motion.alpha`, `Motion.countDuration` and the cadence math are pure — add cases to `tests/motion.luau` (lune). Ticker/hooks are thin RunService/React wiring by design and stay out of lune.
- All new files `--!strict`, zero new `luau-lsp analyze` errors (annotate with `React.Binding<number>` — confirmed re-exported; remember: `useBinding` returns binding + a **free updater function**, `getValue` is a method, mapped/joined bindings are read-only).
- Studio spot-checks: 375×667 emulation — 30-row Roster stagger completes ≤ 0.9 s with `Ticker.count()` returning to 0 at rest; GameResult full run and both skip paths; `Ticker.count() == 0` on every idle screen without ambients.
- Delete `components/Fade.luau` after App switches to `Transition` (App is the sole consumer); rerun `rojo sourcemap`.