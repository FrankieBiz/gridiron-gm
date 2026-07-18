--!strict
-- Motion vocabulary + pure helpers: every duration, spring config, distance, and scale
-- in the app comes from here (spec: design/ui-v2-motion.md §2; Theme carries NO motion
-- values). Pure except reducedMotion(), which touches UserGameSettings lazily and only
-- on the client — requiring this module is side-effect-free, so Lune can test the
-- helpers (tests/motion.luau).

local Solver = require(script.Parent.Solver)

export type MotorConfig = {
	frequency: number?, -- Hz, passed to Solver.springStep
	damping: number?, -- ratio, passed to Solver.springStep
	epsilon: number?, -- rest threshold for Solver.springDone; default 1e-3
}

export type TimelineConfig = {
	duration: number?, -- seconds; default Motion.dur.base
	delay: number?, -- seconds held at 0 before starting; default 0
	easing: ((number) -> number)?, -- default Solver.easeOutCubic
	onComplete: (() -> ())?,
}

export type StaggerConfig = {
	count: number, -- item count this trigger cycle
	step: number?, -- default Motion.stagger.step
	span: number?, -- default Motion.stagger.span
	delay: number?, -- lead-in, default 0
	easing: ((number) -> number)?, -- per-item, default Solver.easeOutQuint
	maxTotal: number?, -- default Motion.stagger.maxTotal; step compresses to fit
}

export type PulseConfig = {
	period: number, -- seconds per cycle
	waveform: ("sine" | "sweep")?, -- default "sine"
	active: number?, -- sweep only: seconds of the period spent going 0->1
	enabled: boolean?, -- default true; false parks the binding at 0
}

local Motion = {}

Motion.spring = {
	snappy = { frequency = 8, damping = 1 } :: MotorConfig, -- press-down; ~0.12s, no overshoot
	pop = { frequency = 5, damping = 0.58 } :: MotorConfig, -- release/entrance; ~10% overshoot
	slide = { frequency = 4.5, damping = 0.82 } :: MotorConfig, -- tab pill, panel slides
	gentle = { frequency = 3, damping = 1 } :: MotorConfig, -- hovers, transparency eases
	bounce = { frequency = 3.4, damping = 0.45 } :: MotorConfig, -- celebrations, badge lands
	shake = { frequency = 8, damping = 0.15 } :: MotorConfig, -- decaying-sine shake (impulse)
	lazy = { frequency = 1.8, damping = 1 } :: MotorConfig, -- ambient drift back to rest
}

Motion.dur = { whip = 0.09, fast = 0.14, base = 0.22, slow = 0.32, hero = 0.55 }

Motion.stagger = { step = 0.045, span = 0.26, maxTotal = 0.9 }

Motion.dist = { rise = 14, slide = 24, drop = 10, kick = 6 } -- px

Motion.scale = { press = 0.96, hover = 1.02 }

-- ---- pure helpers ----

-- Windowed sub-animation inside a seconds-clock choreography (useChoreo): progress of
-- an element that starts at `start` and runs `duration` seconds, eased.
function Motion.window(
	t: number,
	start: number,
	duration: number,
	easing: ((number) -> number)?
): number
	local p = math.clamp((t - start) / duration, 0, 1)
	return (easing or Solver.easeOutCubic)(p)
end

-- Entrance transparency: p=0 fully transparent, p=1 at the element's rest transparency.
function Motion.alpha(p: number, restTransparency: number?): number
	return 1 - (1 - (restTransparency or 0)) * p
end

-- AnimatedNumber duration by count-up magnitude.
function Motion.countDuration(delta: number): number
	local d = math.abs(delta)
	if d <= 3 then
		return 0.25
	elseif d <= 20 then
		return 0.45
	elseif d <= 120 then
		return 0.7
	end
	return 0.9
end

-- ---- reduced motion (client-only; lazy so Lune can require this module) ----

local reducedCached: boolean? = nil

function Motion.reducedMotion(): boolean
	if reducedCached == nil then
		local ok, value = pcall(function()
			local settings = UserSettings():GetService("UserGameSettings")
			-- Subscribe once so the cache tracks the user toggling the setting mid-session.
			settings:GetPropertyChangedSignal("ReducedMotion"):Connect(function()
				reducedCached = settings.ReducedMotion
			end)
			return settings.ReducedMotion
		end)
		reducedCached = ok and value or false
	end
	return reducedCached :: boolean
end

return Motion
