--!strict
-- Theme v2 — the complete visual language: palette, elevation, typography, geometry,
-- gradients, and color math (spec: design/ui-v2-visual.md, resolutions in ui-v2-master.md).
-- Law: no inline Color3/Enum.Font/radius/spacing anywhere outside this file.
-- v1 compatibility: every v1 export survives with its original value and signature
-- (ovrColor's return ramp is the one sanctioned change). Motion values live in
-- motion/Motion.luau, NOT here. This module is pure — no service requires.

local Theme = {}

-- ---- v1 flat tokens (kept byte-for-byte; aliased by the structured tables below) ----

Theme.field = Color3.fromRGB(16, 30, 26)
Theme.field2 = Color3.fromRGB(26, 52, 45)
Theme.field3 = Color3.fromRGB(11, 21, 18)
Theme.panel = Color3.fromRGB(30, 58, 50)
Theme.flag = Color3.fromRGB(232, 92, 34)
Theme.flagDeep = Color3.fromRGB(178, 62, 18)
Theme.chalk = Color3.fromRGB(244, 246, 243)
Theme.chalkSoft = Color3.fromRGB(150, 172, 162)
Theme.gold = Color3.fromRGB(233, 182, 62)
Theme.green = Color3.fromRGB(74, 168, 120)
Theme.line = Color3.fromRGB(46, 70, 61)
Theme.bgTop = Color3.fromRGB(22, 40, 34)
Theme.bgBottom = Color3.fromRGB(9, 17, 14)
Theme.stroke = Color3.fromRGB(255, 255, 255)
Theme.strokeT = 0.9

-- ---- palette ----

Theme.bg = {
	sunk = Color3.fromRGB(7, 13, 11), -- hero gradient bottoms, the void
	base = Theme.field3, -- page base, TabBar fill
	mid = Theme.field, -- default screen background
	high = Theme.bgTop, -- elevated background zones
}

Theme.surface = {
	sunken = Color3.fromRGB(13, 25, 21), -- wells, progress tracks
	base = Theme.field2,
	raised = Theme.panel,
	overlay = Color3.fromRGB(36, 70, 60), -- modals/popovers only
}

Theme.border = {
	soft = Color3.fromRGB(36, 56, 48), -- in-card separators
	base = Theme.line,
	strong = Color3.fromRGB(64, 94, 82), -- table-header underline
}

Theme.text = {
	primary = Theme.chalk,
	secondary = Theme.chalkSoft,
	tertiary = Color3.fromRGB(108, 128, 119), -- eyebrows, table headers
	disabled = Color3.fromRGB(78, 94, 87),
	inverse = Theme.field, -- ink on light/bright fills
}

Theme.brand = {
	flag = Theme.flag,
	deep = Theme.flagDeep,
	glow = Color3.fromRGB(255, 138, 76), -- focus, hovers, pulses, 90+ OVR
}

Theme.goldDeep = Color3.fromRGB(176, 128, 34)
Theme.goldGlow = Color3.fromRGB(255, 214, 110)

Theme.semantic = {
	success = Theme.green,
	successDeep = Color3.fromRGB(52, 118, 84),
	danger = Color3.fromRGB(222, 70, 70),
	dangerDeep = Color3.fromRGB(150, 42, 42),
	warning = Theme.gold, -- one yellow in the system; may diverge later
	info = Color3.fromRGB(92, 158, 204),
}

Theme.scrim = {
	color = Color3.fromRGB(4, 9, 7),
	transparency = 0.38, -- resting backdrop (motion animates 1 -> this)
}

-- ---- typography ----

export type TextStyle = { font: Enum.Font, size: number, scaled: boolean, maxSize: number? }

Theme.font = {
	display = Enum.Font.GothamBlack,
	bold = Enum.Font.GothamBold,
	medium = Enum.Font.GothamMedium,
	body = Enum.Font.Gotham,
	mono = Enum.Font.RobotoMono,
}

-- TextScaled policy: scaled styles are shrink-only (ALWAYS pair with a
-- UITextSizeConstraint at maxSize). Everything else is fixed TextSize. Numbers that
-- align or animate use the mono styles.
Theme.type = {
	hero = { font = Theme.font.display, size = 44, scaled = true, maxSize = 44 } :: TextStyle,
	display = { font = Theme.font.display, size = 30, scaled = true, maxSize = 30 } :: TextStyle,
	h1 = { font = Theme.font.display, size = 22, scaled = false } :: TextStyle,
	h2 = { font = Theme.font.bold, size = 17, scaled = false } :: TextStyle,
	body = { font = Theme.font.body, size = 14, scaled = false } :: TextStyle,
	bodyBold = { font = Theme.font.bold, size = 14, scaled = false } :: TextStyle,
	caption = { font = Theme.font.medium, size = 12, scaled = false } :: TextStyle,
	eyebrow = { font = Theme.font.bold, size = 11, scaled = false } :: TextStyle,
	monoXL = { font = Theme.font.mono, size = 40, scaled = true, maxSize = 40 } :: TextStyle,
	mono = { font = Theme.font.mono, size = 16, scaled = false } :: TextStyle,
	monoSm = { font = Theme.font.mono, size = 13, scaled = false } :: TextStyle,
}

-- Heavy mono digits for monoXL contexts only. Assign to FontFace (never set Font AND
-- FontFace on the same label).
Theme.fontFace = {
	monoBold = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold),
}

-- ---- geometry ----

Theme.space = { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32, xxxl = 48 }

-- pill is applied as UICorner CornerRadius = UDim.new(1, 0); the number documents intent.
Theme.radius = { xs = 4, sm = 6, md = 10, lg = 14, xl = 20, pill = 1000 }

export type StrokeSpec = { color: Color3, transparency: number, thickness: number }

Theme.strokes = {
	hairline = { color = Theme.stroke, transparency = 0.92, thickness = 1 } :: StrokeSpec,
	edge = { color = Theme.stroke, transparency = 0.88, thickness = 1 } :: StrokeSpec,
	edgeRaised = { color = Theme.stroke, transparency = 0.86, thickness = 1 } :: StrokeSpec,
	focus = { color = Theme.brand.glow, transparency = 0.25, thickness = 2 } :: StrokeSpec,
	glow = { color = Theme.flag, transparency = 0.9, thickness = 1.5 } :: StrokeSpec,
	danger = { color = Theme.semantic.danger, transparency = 0.35, thickness = 2 } :: StrokeSpec,
}

Theme.size = {
	buttonH = 48,
	buttonSmH = 36,
	rowH = 52,
	rowSmH = 44,
	chipH = 24,
	barH = 8,
	touchMin = 44, -- no interactive element smaller
}

Theme.chrome = {
	topBarH = 64, -- content zone; total bar = topBarH + SafeArea top inset
	tabBarH = 56,
	padX = 16,
	contentMaxW = 640, -- UISizeConstraint on content columns / CTA stacks
	modalMaxW = 480,
}

Theme.z = { base = 1, raised = 5, chrome = 10, modal = 20, toast = 30 }

-- ---- gradients (constants — only Offset/Rotation are ever animated) ----

Theme.grad = {
	-- multiplicative white->gray over a colored fill; higher elevation = stronger
	surface = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(237, 237, 237)),
	raised = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(232, 232, 232)),
	overlay = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(226, 226, 226)),
	app = ColorSequence.new(Theme.bgTop, Theme.bgBottom),
	hero = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.field2),
		ColorSequenceKeypoint.new(0.55, Theme.field),
		ColorSequenceKeypoint.new(1, Theme.bg.sunk),
	}),
	primaryBtn = ColorSequence.new(Theme.flag, Theme.flagDeep),
	goldBtn = ColorSequence.new(Theme.gold, Theme.goldDeep),
	dangerBtn = ColorSequence.new(Theme.semantic.danger, Theme.semantic.dangerDeep),
}

-- ---- exported unions ----

export type DevTrait = "normal" | "star" | "superstar"
export type SeasonPhase = "regular" | "playoffs" | "offseason"
export type NewsKind = "career" | "league" | "title" | "retire" | "draft" | "credits" | "award"
export type OvrTier = "elite" | "star" | "starter" | "backup" | "depth"

export type TeamPalette = {
	primary: Color3,
	secondary: Color3,
	ink: Color3, -- readable on primary
	barTop: Color3, -- TopBar gradient top
	barBottom: Color3,
	barInk: Color3, -- readable on the bar gradient
	accent: Color3, -- secondary, corrected for readability on barBottom
	tint: Color3, -- team-tinted dark surface, chalk-readable for ANY team color
}

-- ---- color math ----

-- Accepts "#RRGGBB", "RRGGBB", "#RGB", "RGB"; errors loudly on malformed input.
function Theme.hex(hex: string): Color3
	local s = hex:gsub("^#", "")
	if #s == 3 then
		s = s:sub(1, 1):rep(2) .. s:sub(2, 2):rep(2) .. s:sub(3, 3):rep(2)
	end
	local n = tonumber(s, 16)
	assert(#s == 6 and n ~= nil, `Theme.hex: malformed color "{hex}"`)
	return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end

function Theme.mix(a: Color3, b: Color3, t: number): Color3
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

function Theme.darken(c: Color3, f: number): Color3
	return Theme.mix(c, Color3.new(0, 0, 0), f)
end

function Theme.lighten(c: Color3, f: number): Color3
	return Theme.mix(c, Color3.new(1, 1, 1), f)
end

function Theme.desaturate(c: Color3, f: number): Color3
	local g = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
	return Theme.mix(c, Color3.new(g, g, g), f)
end

-- Flattened compositing (Roblox has no color alpha): fg at strength `a` over bg.
function Theme.alpha(fg: Color3, a: number, bg: Color3?): Color3
	return Theme.mix(bg or Theme.field, fg, a)
end

-- WCAG relative luminance.
function Theme.luminance(c: Color3): number
	local function chan(v: number): number
		if v <= 0.03928 then
			return v / 12.92
		end
		return ((v + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * chan(c.R) + 0.7152 * chan(c.G) + 0.0722 * chan(c.B)
end

function Theme.contrastRatio(a: Color3, b: Color3): number
	local la, lb = Theme.luminance(a), Theme.luminance(b)
	local hi, lo = math.max(la, lb), math.min(la, lb)
	return (hi + 0.05) / (lo + 0.05)
end

-- 0.19 is where chalk-on-bg and field-ink-on-bg have equal contrast ratio.
function Theme.contrastOn(bg: Color3): Color3
	return if Theme.luminance(bg) > 0.19 then Theme.text.inverse else Theme.chalk
end

-- Accent that stays readable on `bg`: itself, a lightened step, or chalk.
function Theme.readableAccent(candidate: Color3, bg: Color3): Color3
	if Theme.contrastRatio(candidate, bg) >= 2.5 then
		return candidate
	end
	local c2 = Theme.lighten(candidate, 0.35)
	if Theme.contrastRatio(c2, bg) >= 2.5 then
		return c2
	end
	return Theme.chalk
end

-- ---- team-color integration (the ONLY entry point for team hex strings) ----

local teamPaletteCache: { [string]: TeamPalette } = {}

function Theme.withTeam(primaryHex: string, secondaryHex: string): TeamPalette
	local key = primaryHex .. secondaryHex
	local cached = teamPaletteCache[key]
	if cached then
		return cached
	end
	local p = Theme.hex(primaryHex)
	local s = Theme.hex(secondaryHex)
	local base = Theme.desaturate(p, 0.10)
	local barTop = Theme.lighten(base, 0.08)
	local barBottom = Theme.darken(base, 0.38)
	local palette: TeamPalette = {
		primary = p,
		secondary = s,
		ink = Theme.contrastOn(p),
		barTop = barTop,
		barBottom = barBottom,
		barInk = Theme.contrastOn(Theme.mix(barTop, barBottom, 0.5)),
		accent = Theme.readableAccent(s, barBottom),
		-- 16% of a desaturated primary into field2: always dark enough for chalk text.
		tint = Theme.mix(Theme.field2, Theme.desaturate(p, 0.35), 0.16),
	}
	teamPaletteCache[key] = palette
	return palette
end

-- Phase-tinted root background: the whole app subtly re-lights per season phase.
function Theme.appGradient(phase: SeasonPhase?): ColorSequence
	return ColorSequence.new(Theme.mix(Theme.bgTop, Theme.phaseColor(phase), 0.06), Theme.bgBottom)
end

-- ---- semantic helpers (domain -> color) ----

-- Stepped, not lerped: tiers must read as tiers at a glance.
function Theme.ovrColor(ovr: number): Color3
	if ovr >= 90 then
		return Theme.brand.glow
	elseif ovr >= 80 then
		return Theme.gold
	elseif ovr >= 70 then
		return Theme.chalk
	elseif ovr >= 60 then
		return Theme.chalkSoft
	end
	return Theme.text.tertiary
end

function Theme.ovrTier(ovr: number): OvrTier
	if ovr >= 90 then
		return "elite"
	elseif ovr >= 80 then
		return "star"
	elseif ovr >= 70 then
		return "starter"
	elseif ovr >= 60 then
		return "backup"
	end
	return "depth"
end

-- Dev-trait accent (param stays string? for call-site compat).
function Theme.devColor(trait: string?): Color3
	if trait == "superstar" then
		return Theme.flag
	elseif trait == "star" then
		return Theme.gold
	end
	return Theme.chalkSoft
end

function Theme.deltaColor(n: number): Color3
	if n > 0 then
		return Theme.semantic.success
	elseif n < 0 then
		return Theme.semantic.danger
	end
	return Theme.chalkSoft
end

function Theme.securityColor(sec: number): Color3
	if sec >= 60 then
		return Theme.semantic.success
	elseif sec >= 30 then
		return Theme.gold
	end
	return Theme.semantic.danger
end

function Theme.phaseColor(phase: string?): Color3
	if phase == "regular" then
		return Theme.green
	elseif phase == "playoffs" then
		return Theme.gold
	elseif phase == "offseason" then
		return Theme.semantic.info
	end
	return Theme.chalkSoft
end

-- Absorbs Dashboard's inline NEWS_COLOR table.
function Theme.newsColor(kind: string?): Color3
	if kind == "title" or kind == "award" then
		return Theme.gold
	elseif kind == "credits" then
		return Theme.semantic.success
	elseif kind == "career" or kind == "draft" then
		return Theme.flag
	end
	return Theme.chalkSoft
end

return Theme
