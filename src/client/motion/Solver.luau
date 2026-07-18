--!strict
-- Pure motion math: analytic damped-spring solution + easing curves.
-- No Instances, no services, no requires — Lune runs tests/motion.luau against this.
-- The analytic (closed-form) spring is exact for any dt, so animation never explodes
-- on a hitchy frame the way naive Euler integration does.

local Solver = {}

export type SpringConfig = {
	frequency: number?, -- natural frequency in Hz (responsiveness); default 4
	damping: number?, -- damping ratio: <1 bouncy, 1 critical (no overshoot); default 1
}

export type SpringState = {
	x: number, -- position
	v: number, -- velocity
}

local DEFAULT_FREQUENCY = 4
local DEFAULT_DAMPING = 1

-- Advance a spring toward `target` by `dt` seconds. Exact for any dt.
function Solver.springStep(
	state: SpringState,
	target: number,
	dt: number,
	config: SpringConfig?
): SpringState
	local f = (config and config.frequency) or DEFAULT_FREQUENCY
	local zeta = (config and config.damping) or DEFAULT_DAMPING
	local w = 2 * math.pi * f -- angular frequency

	local q0 = state.x - target
	local v0 = state.v

	local x: number, v: number
	if zeta < 1 then
		-- Underdamped: decaying oscillation.
		local wd = w * math.sqrt(1 - zeta * zeta)
		local decay = math.exp(-zeta * w * dt)
		local cosWd = math.cos(wd * dt)
		local sinWd = math.sin(wd * dt)
		local a = q0
		local b = (v0 + zeta * w * q0) / wd
		local q = decay * (a * cosWd + b * sinWd)
		x = target + q
		v = -zeta * w * q + decay * (-a * wd * sinWd + b * wd * cosWd)
	elseif zeta == 1 then
		-- Critically damped: fastest approach with no overshoot.
		local decay = math.exp(-w * dt)
		local c = v0 + w * q0
		x = target + decay * (q0 + c * dt)
		v = decay * (v0 - c * w * dt)
	else
		-- Overdamped: two real decay rates.
		local root = w * math.sqrt(zeta * zeta - 1)
		local r1 = -zeta * w + root
		local r2 = -zeta * w - root
		local c2 = (v0 - r1 * q0) / (r2 - r1)
		local c1 = q0 - c2
		local e1 = math.exp(r1 * dt)
		local e2 = math.exp(r2 * dt)
		x = target + c1 * e1 + c2 * e2
		v = c1 * r1 * e1 + c2 * r2 * e2
	end

	return { x = x, v = v }
end

-- A spring is at rest when it will no longer visibly move.
function Solver.springDone(state: SpringState, target: number, epsilon: number?): boolean
	local eps = epsilon or 1e-3
	return math.abs(state.x - target) < eps and math.abs(state.v) < eps
end

-- ---- easing curves: all take/return progress in [0, 1] ----

function Solver.easeOutCubic(p: number): number
	local q = 1 - p
	return 1 - q * q * q
end

function Solver.easeOutQuint(p: number): number
	local q = 1 - p
	return 1 - q * q * q * q * q
end

function Solver.easeInOutCubic(p: number): number
	if p < 0.5 then
		return 4 * p * p * p
	end
	local q = -2 * p + 2
	return 1 - q * q * q / 2
end

-- Overshoots slightly past 1 then settles — snappy "pop" for entrances.
function Solver.easeOutBack(p: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	local q = p - 1
	return 1 + c3 * q * q * q + c1 * q * q
end

-- Exponential approach — good for count-ups that land softly.
function Solver.easeOutExpo(p: number): number
	if p >= 1 then
		return 1
	end
	return 1 - math.pow(2, -10 * p)
end

function Solver.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Stagger helper: progress of item `index` (1-based) when children start `step` apart
-- and each takes `span` of the total normalized timeline.
function Solver.staggerProgress(overall: number, index: number, step: number, span: number): number
	local start = (index - 1) * step
	return math.clamp((overall - start) / span, 0, 1)
end

return Solver
