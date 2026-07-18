All required reading is done — audit (including full data contract and react-API census), current Theme/App, Solver, and house conventions. Here is the complete Theme v2 spec.

---

# GRIDIRON GM — Theme v2 Spec (Visual Language & Tokens)

**File: `src/client/Theme.luau`** (single module, `--!strict`, no requires except `game:GetService("GuiService")` — used only by `Theme.safeArea()`). Theme v2 is a **strict superset** of v1: every v1 export survives byte-for-byte (values and signatures), so all ~15 current importers keep compiling while the rebuild migrates screen by screen.

**Perf posture of everything below:** zero CanvasGroups, zero images. All motifs are Frames + UIGradient + UIStroke + UICorner + TextLabels. Diagonals are drawn with hard-step gradient transparency on **unrotated** frames (rotated frames ignore Frame clipping; we never need clipping tricks). ColorSequence/NumberSequence constants are built once at module scope, never per frame.

---

## 0. Backwards-compat contract (must not change)

| Export | Value / signature | Status in v2 |
|---|---|---|
| `Theme.field` | `Color3.fromRGB(16, 30, 26)` | kept (aliased by `bg.mid`) |
| `Theme.field2` | `Color3.fromRGB(26, 52, 45)` | kept (aliased by `surface.base`) |
| `Theme.field3` | `Color3.fromRGB(11, 21, 18)` | kept (aliased by `bg.base`) |
| `Theme.panel` | `Color3.fromRGB(30, 58, 50)` | kept (aliased by `surface.raised`) |
| `Theme.flag` | `Color3.fromRGB(232, 92, 34)` | kept |
| `Theme.flagDeep` | `Color3.fromRGB(178, 62, 18)` | kept |
| `Theme.chalk` | `Color3.fromRGB(244, 246, 243)` | kept (aliased by `text.primary`) |
| `Theme.chalkSoft` | `Color3.fromRGB(150, 172, 162)` | kept (aliased by `text.secondary`) |
| `Theme.gold` | `Color3.fromRGB(233, 182, 62)` | kept |
| `Theme.green` | `Color3.fromRGB(74, 168, 120)` | kept (aliased by `semantic.success`) |
| `Theme.line` | `Color3.fromRGB(46, 70, 61)` | kept (aliased by `border.base`) |
| `Theme.bgTop` / `Theme.bgBottom` | `(22,40,34)` / `(9,17,14)` | kept |
| `Theme.stroke`, `Theme.strokeT` | white, `0.9` | kept |
| `Theme.font.display/bold/medium/body` | GothamBlack/GothamBold/GothamMedium/Gotham | kept; **additive** `font.mono = Enum.Font.RobotoMono` |
| `Theme.hex(hex: string): Color3` | same signature | hardened (§10) |
| `Theme.devColor(trait: string?): Color3` | same signature & mapping | kept |
| `Theme.ovrColor(ovr: number): Color3` | same signature | **return values extended to 5-stop ramp** (§10 — sanctioned change) |

---

## 1. Palette

All values `Color3.fromRGB`.

### 1.1 Background ramp `Theme.bg` (page depth, darkest = deepest)

| Token | RGB | Use |
|---|---|---|
| `bg.sunk` | `(7, 13, 11)` | bottom of hero gradients, scroll-well bottoms, void behind everything |
| `bg.base` | `(11, 21, 18)` | = `field3`. Page background base, TabBar fill |
| `bg.mid` | `(16, 30, 26)` | = `field`. Default screen background |
| `bg.high` | `(22, 40, 34)` | = `bgTop`. Elevated background zones (header bands) |

### 1.2 Surface / elevation ramp `Theme.surface` + gradient recipe per level

Every surface = `BackgroundColor3` + a **multiplicative white→gray UIGradient (Rotation 90)** + a stroke (§6.3). The gradient darkens the bottom slightly; higher elevation ⇒ stronger gradient + brighter stroke.

| Token | Fill RGB | Gradient `Theme.grad.*` (white → bottom stop) | Stroke transparency |
|---|---|---|---|
| `surface.sunken` | `(13, 25, 21)` | none (flat) — wells, progress tracks, input pits | 0.94 hairline |
| `surface.base` | `(26, 52, 45)` (= field2) | `grad.surface` = `ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(237,237,237))` | 0.90 |
| `surface.raised` | `(30, 58, 50)` (= panel) | `grad.raised` = white → `(232,232,232)` | 0.86 |
| `surface.overlay` | `(36, 70, 60)` | `grad.overlay` = white → `(226,226,226)` — modals/popovers only | 0.80 |

**Raised shadow recipe** (no images): two sibling Frames rendered *behind* the card (lower ZIndex), same Size/UICorner: shadow1 offset `(0, 2)` px, `Color3.fromRGB(0,0,0)`, `BackgroundTransparency 0.82`; shadow2 offset `(0, 5)`, transparency `0.92`. Use on `raised`/`overlay` cards only — never on list rows.

### 1.3 Line / border ramp `Theme.border`

| Token | RGB | Use |
|---|---|---|
| `border.soft` | `(36, 56, 48)` | in-card separators, table row rules |
| `border.base` | `(46, 70, 61)` (= `line`) | default dividers |
| `border.strong` | `(64, 94, 82)` | table-header underline, section rules |

### 1.4 Text ramp `Theme.text`

| Token | RGB | Use |
|---|---|---|
| `text.primary` | `(244, 246, 243)` (= chalk) | headings, values, row titles |
| `text.secondary` | `(150, 172, 162)` (= chalkSoft) | meta lines, labels, sublines |
| `text.tertiary` | `(108, 128, 119)` | eyebrows on quiet surfaces, table headers, footnotes |
| `text.disabled` | `(78, 94, 87)` | disabled controls only |
| `text.inverse` | `(16, 30, 26)` (= field) | ink on light/bright fills (gold, chalk, light team colors) |

### 1.5 Brand `Theme.brand` + gold family

| Token | RGB | Use |
|---|---|---|
| `brand.flag` | `(232, 92, 34)` | primary actions, active nav, "my team" accents |
| `brand.deep` | `(178, 62, 18)` (= flagDeep) | gradient bottoms, pressed states |
| `brand.glow` | `(255, 138, 76)` | **new** — focus strokes, hover gradient tops, pulses, 90+ OVR |
| `goldDeep` | `(176, 128, 34)` | gold gradient bottoms |
| `goldGlow` | `(255, 214, 110)` | shimmer highlight stop, champion pulses |

### 1.6 Semantic `Theme.semantic`

| Token | RGB | Notes |
|---|---|---|
| `semantic.success` | `(74, 168, 120)` (= green) | wins, positive deltas, money gained |
| `semantic.successDeep` | `(52, 118, 84)` | success gradient bottom |
| `semantic.danger` | `(222, 70, 70)` | **new** — losses, injuries, FIRED, negative deltas, hot seat |
| `semantic.dangerDeep` | `(150, 42, 42)` | danger gradient bottom |
| `semantic.warning` | `(233, 182, 62)` | deliberately **the same value as gold** — one yellow in the system; semantics carried by copy/iconography, token kept separate so it can diverge later |
| `semantic.info` | `(92, 158, 204)` | neutral notices, offseason phase, draft intel |

### 1.7 Scrim & glass `Theme.scrim`

| Token | Value | Use |
|---|---|---|
| `scrim.color` | `(4, 9, 7)` | modal backdrop Frame `BackgroundColor3` |
| `scrim.transparency` | `0.38` | resting backdrop transparency (motion animates 1 → 0.38) |
| Glass chip recipe | fill `(20, 38, 32)` at `BackgroundTransparency 0.25`, `grad.surface`, hairline stroke (white, 0.85, 1px) | floating chips over backgrounds (SKIP button, ticker bugs) |

**Modal recipe:** scrim Frame (full-screen, swallows input) → overlay Card (`surface.overlay`, `radius.xl`, stroke 0.80, shadow recipe). The card itself is a `TextButton` with `Active=true` and an empty handler so taps don't fall through (fixes the PlayerCard tap-through flaw).

---

## 2. Team-color integration system

Server sends `team.primary` / `team.secondary` as `"#RRGGBB"`. All team color enters the UI **only** through `Theme.withTeam`, never raw.

```lua
export type TeamPalette = {
	primary: Color3,
	secondary: Color3,
	ink: Color3,       -- text color guaranteed readable on primary
	barTop: Color3,    -- TopBar gradient top
	barBottom: Color3, -- TopBar gradient bottom
	barInk: Color3,    -- text color guaranteed readable on the bar gradient
	accent: Color3,    -- secondary, corrected for readability on barBottom
	tint: Color3,      -- team-tinted dark surface (stays chalk-readable for ANY team color)
}

function Theme.withTeam(primaryHex: string, secondaryHex: string): TeamPalette
```

Exact math (uses helpers from §10; memoize results in a module-level `{ [string]: TeamPalette }` cache keyed `primaryHex .. secondaryHex` — 12 teams ⇒ 12 entries):

- `local p = Theme.hex(primaryHex)`, `local s = Theme.hex(secondaryHex)`
- `local base = Theme.desaturate(p, 0.10)`
- `barTop = Theme.lighten(base, 0.08)`
- `barBottom = Theme.darken(base, 0.38)`
- `ink = Theme.contrastOn(p)`
- `barInk = Theme.contrastOn(Theme.mix(barTop, barBottom, 0.5))`
- `accent = Theme.readableAccent(s, barBottom)` (§10 — 2-step lighten with chalk fallback)
- `tint = Theme.mix(Theme.field2, Theme.desaturate(p, 0.35), 0.16)` — mixes only 16% of a desaturated primary into field2, so the result is always dark enough for chalk text regardless of how light the team color is.

**TopBar gradient formula:** bar Frame `BackgroundColor3 = Color3.fromRGB(255,255,255)`, child `UIGradient { Rotation = 90, Color = ColorSequence.new(tp.barTop, tp.barBottom) }`; title text `tp.barInk`, sub-line `tp.accent`, accent underline 3px `tp.accent`.

**TeamSelect card gradient formula:** `UIGradient { Rotation = 35, Color = ColorSequence.new(p, Theme.darken(p, 0.45)) }` over white fill; monogram watermark = `tp.accent` at `TextTransparency 0.82`; label ink = `Theme.contrastOn(Theme.darken(p, 0.2))`.

---

## 3. Typography `Theme.type`

```lua
export type TextStyle = { font: Enum.Font, size: number, scaled: boolean, maxSize: number? }
```

| Token | Font | Size (px) | Scaled? | Use |
|---|---|---|---|---|
| `type.hero` | `Enum.Font.GothamBlack` | 44 | **yes**, `UITextSizeConstraint.MaxTextSize = 44` | Menu wordmark, WIN!/LOSS banner, YOU'VE BEEN FIRED |
| `type.display` | `GothamBlack` | 30 | **yes**, MaxTextSize 30 | screen titles, champion card |
| `type.h1` | `GothamBlack` | 22 | no | card titles, TopBar team name |
| `type.h2` | `GothamBold` | 17 | no | row titles, button labels, section heads |
| `type.body` | `Gotham` | 14 | no | body copy, news text (TextWrapped) |
| `type.bodyBold` | `GothamBold` | 14 | no | emphasized inline |
| `type.caption` | `GothamMedium` | 12 | no | meta lines (age · trait), sublines |
| `type.eyebrow` | `GothamBold` | 11 | no | ALL-CAPS overlines, table headers, badges |
| `type.monoXL` | `RobotoMono` | 40 | **yes**, MaxTextSize 40 | scoreboard scores, dynasty-score hero |
| `type.mono` | `RobotoMono` | 16 | no | stat columns, OVR plates, credits, records |
| `type.monoSm` | `RobotoMono` | 13 | no | dense table cells, deltas, clock chips |

**Additive:** `Theme.font.mono = Enum.Font.RobotoMono`. Optional heavy digits: `Theme.fontFace.monoBold = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)` — assign to the **`FontFace`** host prop (never set `Font` and `FontFace` on the same label); use only for `monoXL` contexts.

**TextScaled policy (law):** TextScaled is a *shrink-only* safety valve — it is **always** paired with `UITextSizeConstraint { MaxTextSize = token.size }`, and it is only allowed on `hero`, `display`, `monoXL`. Everything in lists, rows, tables, buttons, and chips uses fixed `TextSize` (kills the "ransom-note" row sizing the audit flagged in six screens). Long strings truncate: `TextTruncate = Enum.TextTruncate.AtEnd` on every single-line label with dynamic content.

**Tabular-number strategy:** Gotham digits are proportional; **every number that aligns vertically or changes at runtime renders in RobotoMono**: scoreboards, count-ups (fixed TextSize ⇒ no per-frame relayout), standings columns (W/L/PF/PA/DIFF), OVR/POT, credits balance and costs, records ("9-5"), quarter/clock chips, week counters, deltas. Numbers inside prose sentences (news text) stay Gotham. Never animate a TextScaled label's content per frame — count-ups are always fixed-size mono.

---

## 4. Geometry tokens

### 4.1 Spacing `Theme.space`
`xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32, xxxl = 48`. All UIPadding/UIListLayout paddings come from here. Screen horizontal gutter = `space.lg` (16).

### 4.2 Radius `Theme.radius`
`xs = 4, sm = 6, md = 10, lg = 14, xl = 20, pill = 1000` (pill via `UICorner CornerRadius = UDim.new(1, 0)` — token documents intent).
Assignments (unifies the 8/10/12/14/16 drift): buttons + list rows + plates = `md` (10) · cards = `lg` (14) · modals = `xl` (20) · badges/pills/pips-track = `pill` · pips/rails/bones = `xs`/`sm`.

### 4.3 Stroke recipes `Theme.strokes`

```lua
export type StrokeSpec = { color: Color3, transparency: number, thickness: number }
```

| Token | Color | Transparency | Thickness | Use |
|---|---|---|---|---|
| `strokes.hairline` | `(255,255,255)` | 0.92 | 1 | separators, quiet chips, sunken wells |
| `strokes.edge` | `(255,255,255)` | 0.88 | 1 | default card/row edge-light (house signature) |
| `strokes.edgeRaised` | `(255,255,255)` | 0.86 | 1 | raised cards |
| `strokes.focus` | `brand.glow (255,138,76)` | 0.25 | 2 | selected cards, keyboard/gamepad focus |
| `strokes.glow` | context color (flag/gold) | rest 0.9 (motion animates ↔0.45) | 1.5 | breathing CTAs, "on the clock", mine-row pulse |
| `strokes.danger` | `(222,70,70)` | 0.35 | 2 | destructive confirm, hot-seat bar |

All `ApplyStrokeMode = Enum.ApplyStrokeMode.Border`.

### 4.4 Sizes & chrome

| Token | Value |
|---|---|
| `size.buttonH` / `size.buttonSmH` | 48 / 36 |
| `size.rowH` / `size.rowSmH` | 52 / 44 |
| `size.chipH` | 24 |
| `size.barH` (progress) | 8 |
| `size.touchMin` | 44 (no interactive element smaller — fixes the 34px SIM button) |
| `chrome.topBarH` | **64** (content zone; total bar = `64 + safeArea().top`) |
| `chrome.tabBarH` | **56** |
| `chrome.padX` | 16 |
| `chrome.contentMaxW` | 640 (UISizeConstraint on content columns — fixes 80%-wide desktop CTAs) |
| `chrome.modalMaxW` | 480 |

### 4.5 Z-index `Theme.z`
`base = 1, raised = 5, chrome = 10, modal = 20, toast = 30`. (Replaces PlayerCard's raw 20/21/22.)

### 4.6 Safe area

```lua
function Theme.safeArea(): { top: number, bottom: number }
	local topLeft, bottomRight = GuiService:GetGuiInset()
	return {
		top = math.max(topLeft.Y, 0),                 -- ≈58 with IgnoreGuiInset=true
		bottom = math.max(bottomRight.Y, Theme.space.sm),
	}
end
```

**Layout law (replaces App's magic 82/146):** TopBar Frame = `Position (0,0)`, `Size (1, 0, 0, chrome.topBarH + safeArea().top)` with internal `UIPadding.PaddingTop = safeArea().top` (background bleeds behind the Roblox topbar; content sits below it — no more menu-button collision). TabBar = `Size (1, 0, 0, chrome.tabBarH + safeArea().bottom)` anchored bottom with `PaddingBottom = safeArea().bottom`. Content pane = `Position (0, safeTop + topBarH)`, `Size (1, 0, 1, -(safeTop + topBarH + tabBarH + safeBottom))`.

---

## 5. Gradient constants `Theme.grad`

| Token | Exact value | Use |
|---|---|---|
| `grad.surface` / `grad.raised` / `grad.overlay` | §1.2 | surfaces |
| `grad.app` | `ColorSequence.new(bgTop (22,40,34), bgBottom (9,17,14))`, Rotation 90 | root background (current look, kept) |
| `grad.hero` | `ColorSequence{ (0, (26,52,45)), (0.55, (16,30,26)), (1, (7,13,11)) }`, Rotation 115 | Menu / GameResult backdrops |
| `grad.primaryBtn` | `ColorSequence.new(flag, flagDeep)`, Rotation 90 | primary button/active tab (fill = white, gradient multiplies to exact colors) |
| `grad.goldBtn` | `ColorSequence.new(gold (233,182,62), goldDeep (176,128,34))`, Rotation 90 | champion CTAs, gold pills |
| `grad.dangerBtn` | `ColorSequence.new((222,70,70), (150,42,42))`, Rotation 90 | danger button |
| `Theme.appGradient(phase: SeasonPhase?): ColorSequence` | `ColorSequence.new(Theme.mix(bgTop, Theme.phaseColor(phase), 0.06), bgBottom)` | phase-tinted root background — the whole app subtly re-lights per phase |

---

## 6. Motion tokens `Theme.motion` (values only — the motion system spec owns usage)

```lua
export type SpringPreset = { frequency: number, damping: number } -- matches Solver.SpringConfig
Theme.motion = {
	dur = { fast = 0.12, base = 0.20, slow = 0.35, reveal = 0.55 },
	spring = {
		press  = { frequency = 9,   damping = 1 },    -- button dip
		glide  = { frequency = 4,   damping = 1 },    -- position settles, count-downs
		pop    = { frequency = 5,   damping = 0.55 }, -- entrances with overshoot
		bounce = { frequency = 3.2, damping = 0.38 }, -- celebration pops
	},
	stagger = { row = 0.04, card = 0.06 },
	pressScale = 0.96,
	hoverScale = 1.02,
}
```

---

## 7. Signature motifs (the "broadcast package")

All are plain instance recipes — a `motifs/` folder under `src/client/components/` may wrap them, but the values live here.

### M1 · ChevronSlash — angled accent for headers & hero moments
Diagonals via hard-step gradient transparency on **unrotated** frames (crisp edge = two keypoints 0.01 apart; never animate the sequence).
```
Slash : Frame (BackgroundTransparency=1, Size=UDim2.fromOffset(72, H))   -- H = header height
├─ main : Frame — Size (0,44,1,0), Pos (0,0), BackgroundColor3=brand.flag, BorderSizePixel=0
│   └─ UIGradient { Rotation = 20, Transparency = NumberSequence{ (0,0),(0.68,0),(0.69,1),(1,1) } }
└─ thin : Frame — Size (0,26,1,0), Pos (0,48,0,0), BackgroundColor3=gold, BorderSizePixel=0
    └─ UIGradient { Rotation = 20, Transparency = NumberSequence{ (0,1),(0.42,1),(0.43,0),(0.63,0),(0.64,1),(1,1) } }
```
Renders a bold flag slash + trailing gold sliver, both edges leaning 20° — the ESPN lower-third look. **Where:** left of section titles (H=18), GameResult scoreboard corner (H=full), TopBar accent zone, "ON THE CLOCK" banner. Color swap allowed (gold/gold for playoffs, danger for FIRED).

### M2 · YardLines — field-texture background
```
Yard : Frame (transparent, ClipsDescendants=true, full-size, ZIndex under content)
└─ for i = 0..math.ceil(width/64): line_i : Frame — Size (0,1,1,0), Pos (0, i*64, 0, 0),
     BackgroundColor3 = chalk, BackgroundTransparency = 0.93 (every 5th line: 0.88), BorderSizePixel = 0
```
**Where:** Menu, loading screen, empty states, GameResult backdrop. Static — never animated (parallax drift is a motion-spec option on Menu only).

### M3 · StatChip — eyebrow + big mono number
```
chip : Frame — Size (0,W,0,56); BackgroundColor3=surface.raised; UICorner md; grad.raised; strokes.edgeRaised
├─ UIPadding { 8 / 8 / 12 / 12 }  (top/bottom/left/right)
├─ eyebrow : TextLabel — type.eyebrow, text.tertiary, UPPERCASE, XAlign Left, Size (1,0,0,12)
├─ value  : TextLabel — RobotoMono 22 fixed, text.primary (or semantic), XAlign Left, Size (1,0,0,26), Pos (0,0,0,18)
└─ delta? : TextLabel — type.monoSm, Theme.deltaColor(n), XAlign Right, Size (0,60,0,14), top-right
```
**Where:** Dashboard header row, CareerProfile 4-tile career strip, DraftRoom scout points, FreeAgency credits-in-context (fixes "credits only in TopBar").

### M4 · PhaseBadge — the "LIVE" bug
```
badge : Frame — AutomaticSize X, Size (0,0,0,24); BackgroundColor3 = Theme.mix(field2, phaseColor, 0.18);
        UICorner pill; UIStroke { phaseColor, 0.55, 1 }
├─ UIListLayout { Horizontal, Padding UDim.new(0,6), VerticalAlignment Center }
├─ UIPadding { left 10, right 12 }
├─ dot   : Frame — Size (0,6,0,6), BackgroundColor3 = phaseColor, UICorner pill
└─ label : TextLabel — type.eyebrow, UPPERCASE, text.primary, AutomaticSize X  ("WEEK 7 · REGULAR SEASON")
```
`Theme.phaseColor`: regular → `green`, playoffs → `gold`, offseason → `info`. Dot gets a 2s sine transparency pulse (motion spec) during `regular`/`playoffs`. **Where:** TopBar, Dashboard matchup card, GameResult header.

### M5 · OvrPlate — the rating tile (replaces bare colored numbers)
```
plate : Frame — Size (0,42,0,34); BackgroundColor3 = Theme.mix(bg.base, tier, 0.16); UICorner sm;
├─ UIGradient { Rotation 90, white → (235,235,235) }
├─ UIStroke { tier, 0.45 (elite 90+: 0.20), 1 }
└─ num : TextLabel — RobotoMono 18 fixed, TextColor3 = tier, centered
```
`tier = Theme.ovrColor(ovr)` (§10). **Where:** Roster rows, PlayerCard header, FreeAgency rows, DraftRoom (when fog collapses). Optional 8px eyebrow "OVR"/"POT" above in `text.tertiary`.

### M6 · ChampionShimmer — gold that moves
Fill-sweep variant (cards, banner):
```
sweep : Frame — full-size of target, matching UICorner, BackgroundColor3 = goldGlow (255,214,110), ZIndex +1
└─ UIGradient { Rotation = 25, Transparency = NumberSequence{ (0,1),(0.38,1),(0.5,0.72),(0.62,1),(1,1) } }
     -- motion system animates Offset.X from -1 → 1 over 1.6s, 2.4s period
```
Stroke-ring variant (trophies, champion rows): `UIGradient { Color = ColorSequence{ (0,gold),(0.5,goldGlow),(1,gold) } }` placed **inside the UIStroke**, Rotation slowly animated. **Budget: ≤ 2 shimmer instances animating concurrently, ever.** **Where:** History championship rows, Offseason champion hero, maxed facilities, `superstar` PlayerCard stroke (flag→gold→flag variant).

---

## 8. Component skins (all states)

### 8.1 Button (`components/Button.luau` v2) — `variant: "primary" | "secondary" | "ghost" | "danger"`
Geometry (all variants): height `size.buttonH` 48 (compact 36), `UICorner md`, `UIPadding` x16, label `type.h2` UPPERCASE fixed 17px, `AutoButtonColor = false` (we own every state).

| Variant | Rest | Hover | Pressed | Disabled |
|---|---|---|---|---|
| **primary** | fill white + `grad.primaryBtn` (flag→flagDeep); ink chalk; stroke white 0.82/1px | gradient → `ColorSequence.new(brand.glow, flag)`; stroke → 0.55 | gradient → `ColorSequence.new(flagDeep, (146,51,15))`; scale `pressScale` | see below |
| **secondary** | fill `surface.raised (30,58,50)`; ink chalk; stroke white 0.82 | fill `(43,69,62)` (= mix(panel, chalk, 0.06)) | fill `(25,48,41)` (= darken(panel, 0.18)) | " |
| **ghost** | `BackgroundTransparency 1`; ink `text.secondary`; stroke white 0.86 | ink → chalk; stroke → 0.62 | fill white @ `BackgroundTransparency 0.92` | " |
| **danger** | fill white + `grad.dangerBtn`; ink chalk; stroke `(222,70,70)` 0.5 | gradient → `((227,98,98) → (222,70,70))` | gradient → `((182,57,57) → (123,34,34))` | " |

**Disabled (any variant):** fill `surface.base`, no gradient, ink `text.disabled`, stroke white 0.94, `Active = false`. **Loading:** label hidden, three 6px `text.secondary` dots (motion spec animates). Press scale/springs and `Sound.play("click")` are the motion/sound specs' contract — the tokens above are the colors they animate between.

### 8.2 Card (`components/Card.luau` v2) — `variant: "flat" | "raised" | "highlight" | "team"`

| Variant | Fill | Gradient | Stroke | Extra |
|---|---|---|---|---|
| flat | `surface.base` | `grad.surface` | `strokes.edge` (0.88) | — |
| raised | `surface.raised` | `grad.raised` | 0.86 | shadow recipe (§1.2) |
| highlight | `Theme.mix(panel, flag, 0.10)` | `grad.raised` | `flag`, 0.45, 2px | for "NEXT UP", selected offers |
| team | `TeamPalette.tint` | `grad.surface` | `TeamPalette.accent`, 0.70, 1px | 3px left rail Frame in `accent`, own `UICorner xs`, inset 1px (fixes corner-poke bug) |

All: `UICorner lg` (14), `BorderSizePixel 0`. `selected: boolean?` swaps stroke to `strokes.focus`. Built-in children keyed `_corner/_stroke/_grad` (underscore prefix ends the `corner`/`stroke` collision footgun).

### 8.3 Badge / Pill
Height `size.chipH` 24 (small 18), `UICorner pill`, `UIPadding` x10, label `type.eyebrow` UPPERCASE.

| Variant | Fill | Ink |
|---|---|---|
| neutral | `(37, 62, 55)` (= mix(field2, chalk, 0.05)) | `text.secondary` |
| brand | `brand.flag` | chalk |
| gold | `gold` (+ `grad.goldBtn` for hero pills) | **`text.inverse`** (dark — gold luminance 0.51) |
| success | `semantic.success` | `text.inverse` |
| danger | `semantic.danger` | chalk (brand exception — alarm reads white-on-red) |
| outline | transparent, stroke context-color 0.5 | context color |

**Where:** phase tags, "REBUILD / WIN NOW" offer tags, dev-trait tags, W/L pills, "SIGNED ✓", news kind chips.

### 8.4 ProgressBar
Track: height `size.barH` 8, `UICorner pill`, fill `surface.sunken (13,25,21)`, `strokes.hairline`. Fill: `UICorner pill`, `UIGradient { Rotation 0, ColorSequence.new(color, Theme.lighten(color, 0.22)) }`, min width 8px when value > 0. Color by context: job security ⇒ `Theme.securityColor` (≥60 green / ≥30 gold / else **danger**), reputation ⇒ gold, week progress ⇒ flag with a 2px gold notch Frame at the playoff cutoff.
**Facility pips:** 10 segments, height 8, gap 4, per-pip width `UDim2.new(1/10, -36/10, 1, 0)` (subtracting `gap*(n-1)/n` — fixes the overflow bug), `UICorner xs`; filled = flag, empty = `surface.sunken` + hairline, all-maxed = gold + one ChampionShimmer sweep on mount.

### 8.5 Stat rows / tables (LeagueTable, Roster)
Header row: height 26, `type.eyebrow`, `text.tertiary`, 1px `border.strong` underline. Data rows: height `size.rowH` 52 (Roster) / `rowSmH` 44 (League); zebra = even rows `surface.base` @ `BackgroundTransparency 0.72`; numeric cells `type.mono` 16, `TextXAlignment.Right`, **fixed pixel column widths shared by header and rows** (League: W 40 · L 40 · PF 56 · PA 56 · DIFF 56, right-aligned block). DIFF colored `Theme.deltaColor(diff)`. "Mine" row = `team` card treatment (tint + rail + accent stroke @ 0.7). Playoff cutline: after seed 4, a 1px `gold` @ 0.55 divider row with centered eyebrow "PLAYOFF LINE".

### 8.6 Empty state
```
empty : Frame — transparent, AnchorPoint (0.5, 0.5), Position (0.5, 0.42), Size (0, 280, 0, 150)
├─ UIListLayout { Vertical, Center, Padding UDim.new(0, 8) }
├─ glyph    : TextLabel — Enum.Font.Gotham, TextSize 40 fixed, Size (1,0,0,48)   (emoji, e.g. 🏈 📋 🏆)
├─ headline : TextLabel — type.h2, text.primary, centered
└─ sub      : TextLabel — type.body, text.secondary, TextWrapped, Size (1,0,0,40), centered
```
Optional ghost Button below (Padding 16 above). Every list screen ships one (League pre-week-1, empty roster, no offers, empty history).

### 8.7 Skeleton shimmer
Bone: Frame `BackgroundColor3 (35, 60, 53)` (= mix(field2, chalk, 0.04)), `UICorner sm`; heights — title 20, text 14, row 44; widths alternate 0.9/0.6/0.4 of column.
Sweep (per bone, all sharing **one** animated binding): child Frame full-size, matching UICorner, `BackgroundColor3 chalk`, `BackgroundTransparency 0`, `UIGradient { Rotation 15, Transparency = NumberSequence{ (0,1),(0.42,1),(0.5,0.85),(0.58,1),(1,1) } }`; motion animates `Offset.X` −1 → 1 over 1.2s, looping with 0.4s rest. No CanvasGroup anywhere. **Where:** App loading screen (skeleton of the Menu), tab first-fetch states.

---

## 9. Semantic helper tokens (domain → color)

| Helper | Mapping |
|---|---|
| `Theme.ovrColor(ovr)` | ≥90 → `brand.glow (255,138,76)` · ≥80 → `gold` · ≥70 → `chalk` · ≥60 → `chalkSoft` · else → `text.tertiary (108,128,119)`. **Stepped, not lerped** — deliberate rejection of the audit's continuous-lerp wow: tiers must read as tiers at a glance; lerped in-betweens go muddy on dark green. |
| `Theme.ovrTier(ovr)` | same thresholds → `"elite" | "star" | "starter" | "backup" | "depth"` |
| `Theme.devColor(trait)` | superstar → flag · star → gold · else → chalkSoft (unchanged) |
| `Theme.deltaColor(n)` | n > 0 → success · n < 0 → danger · 0 → chalkSoft |
| `Theme.securityColor(sec)` | ≥60 → success · ≥30 → gold · else → danger |
| `Theme.phaseColor(phase)` | regular → green · playoffs → gold · offseason → info · unknown → chalkSoft |
| `Theme.newsColor(kind)` | title/award → gold · credits → success · career/draft → flag · league/retire → chalkSoft · unknown → chalkSoft (absorbs Dashboard's inline NEWS_COLOR) |

---

## 10. Function helpers — exact signatures & math

```lua
-- HARDENED (same signature): accepts "#RRGGBB", "RRGGBB", "#RGB", "RGB"; errors loudly on malformed.
function Theme.hex(hex: string): Color3
	-- strip leading "#"; if #s == 3 expand each digit ("f80" -> "ff8800");
	-- assert(#s == 6 and tonumber(s, 16), `Theme.hex: malformed color "{hex}"`)

function Theme.mix(a: Color3, b: Color3, t: number): Color3
	-- Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)

function Theme.darken(c: Color3, f: number): Color3   -- Theme.mix(c, Color3.new(0,0,0), f)
function Theme.lighten(c: Color3, f: number): Color3  -- Theme.mix(c, Color3.new(1,1,1), f)

function Theme.desaturate(c: Color3, f: number): Color3
	-- local g = 0.299*c.R + 0.587*c.G + 0.114*c.B   (gamma-space gray, perceptual approx)
	-- return Theme.mix(c, Color3.new(g, g, g), f)

function Theme.alpha(fg: Color3, a: number, bg: Color3?): Color3
	-- flattened compositing (Roblox has no color alpha): Theme.mix(bg or Theme.field, fg, a)
	-- use for hover fills/tints instead of stacking BackgroundTransparency

function Theme.luminance(c: Color3): number
	-- WCAG relative luminance: per channel v: v <= 0.03928 and v/12.92 or ((v+0.055)/1.055)^2.4
	-- return 0.2126*R' + 0.7152*G' + 0.0722*B'

function Theme.contrastRatio(a: Color3, b: Color3): number
	-- (max(L)+0.05) / (min(L)+0.05)

function Theme.contrastOn(bg: Color3): Color3
	-- Theme.luminance(bg) > 0.19 and Theme.text.inverse or Theme.chalk
	-- 0.19 is the crossover where chalk-on-bg and field-ink-on-bg have equal contrast ratio
	-- (solve (0.97)/(L+0.05) = (L+0.05)/0.0611 → L ≈ 0.19)

function Theme.readableAccent(candidate: Color3, bg: Color3): Color3
	-- if contrastRatio(candidate, bg) >= 2.5 → candidate
	-- else local c2 = Theme.lighten(candidate, 0.35); if contrastRatio(c2, bg) >= 2.5 → c2
	-- else → Theme.chalk

function Theme.withTeam(primaryHex: string, secondaryHex: string): TeamPalette  -- §2, memoized
function Theme.appGradient(phase: SeasonPhase?): ColorSequence                  -- §5
function Theme.safeArea(): { top: number, bottom: number }                      -- §4.6
function Theme.ovrColor(ovr: number): Color3
function Theme.ovrTier(ovr: number): OvrTier
function Theme.devColor(trait: string?): Color3   -- param stays string? for call-site compat
function Theme.deltaColor(n: number): Color3
function Theme.securityColor(sec: number): Color3
function Theme.phaseColor(phase: string?): Color3  -- tolerant param; internally matches SeasonPhase
function Theme.newsColor(kind: string?): Color3
```

**Exported types:**
```lua
export type DevTrait = "normal" | "star" | "superstar"
export type SeasonPhase = "regular" | "playoffs" | "offseason"
export type NewsKind = "career" | "league" | "title" | "retire" | "draft" | "credits" | "award"
export type OvrTier = "elite" | "star" | "starter" | "backup" | "depth"
export type TextStyle = { font: Enum.Font, size: number, scaled: boolean, maxSize: number? }
export type SpringPreset = { frequency: number, damping: number }
export type StrokeSpec = { color: Color3, transparency: number, thickness: number }
export type TeamPalette = { primary: Color3, secondary: Color3, ink: Color3, barTop: Color3,
	barBottom: Color3, barInk: Color3, accent: Color3, tint: Color3 }
```

---

## 11. Module layout order (for the implementer)

1. `--!strict` + header comment · 2. `GuiService` require · 3. legacy flat tokens (§0, unchanged block) · 4. `bg / surface / border / text / brand / semantic / scrim` tables · 5. gold family + `goldDeep/goldGlow`, `brand.glow` · 6. `space / radius / strokes / size / chrome / z` · 7. `type` + `font.mono` + `fontFace` · 8. `grad` ColorSequence constants · 9. `motion` · 10. type exports · 11. pure math helpers · 12. semantic helpers · 13. `withTeam` (+ cache) · 14. `safeArea` · 15. `return Theme`.

## 12. Adoption laws & budget (enforce in review)

- **No inline `Color3.fromRGB`, `Enum.Font.*`, radius, spacing, or z-index in any screen/component** — Theme or nothing (this is the rule the audit shows failing in 11 files; the token set above removes every excuse).
- Team hex strings only enter via `Theme.withTeam`; any color placed on an arbitrary background goes through `contrastOn`/`readableAccent`.
- Numbers that align or animate = RobotoMono, fixed size. TextScaled only with MaxTextSize, only on hero/display/monoXL.
- Perf budget of this language: **0 CanvasGroups**; ≤2 concurrent ChampionShimmer sweeps; skeleton sweep = 1 shared binding; shadow recipe on raised/overlay cards only (never per-row); gradient Color/Transparency sequences are constants — only `UIGradient.Offset` and `Rotation` are ever animated.
- Rejected audit wows, for the record: continuous ovrColor lerp (scannability — see §9), 9-slice ImageLabel card shadows (no-image constraint — replaced by stacked-frame shadow §1.2), per-row CanvasGroup fades (budget — GroupTransparency is reserved for whole-screen Fade).