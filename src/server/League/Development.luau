--!strict
-- Player development, aging, and retirement — run once per offseason on each roster.
-- Pure Luau (own PRNG, no requires) -> Lune-testable. Young players grow toward their
-- potential (faster with better dev traits); players past their positional peak decline;
-- the oldest retire. This is the engine that keeps the league alive across seasons.

local Development = {}

-- Positional peak age (growth before, decline after).
local PEAK = { QB = 29, RB = 26, WR = 27, TE = 28, OL = 29, DL = 28, LB = 28, DB = 27 }
local DEV_MULT = { normal = 1.0, star = 1.6, superstar = 2.3 }

local function makeRng(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local function nextFloat(): number
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
	return {
		float = nextFloat,
		int = function(min: number, max: number): number
			return math.floor(nextFloat() * (max - min + 1)) + min
		end,
		range = function(min: number, max: number): number
			return min + nextFloat() * (max - min)
		end,
	}
end

-- Returns { roster = survivors (aged/developed), retirees = removed players }.
function Development.ageAndDevelop(
	roster: { any },
	seed: number
): { roster: { any }, retirees: { any } }
	local rng = makeRng(seed)
	local survivors: { any } = {}
	local retirees: { any } = {}

	for _, p in roster do
		local age = p.age + 1

		local retire = false
		if age >= 38 then
			retire = true
		elseif age >= 35 then
			retire = rng.float() < 0.45
		elseif age >= 33 then
			retire = rng.float() < 0.18
		end

		if retire then
			table.insert(retirees, p)
		else
			local peak = PEAK[p.position] or 28
			local mult = DEV_MULT[p.devTrait] or 1.0
			local newP = table.clone(p)
			newP.age = age

			local delta: number
			if age <= peak then
				local gap = math.max(0, p.potential - p.overall)
				delta = math.floor(gap * 0.22 * mult + rng.range(0, 1.5))
				if delta < 1 and gap > 0 then
					delta = 1
				end
			else
				delta = -math.floor((age - peak) * rng.range(1.0, 2.2))
			end

			local ceiling = math.max(p.overall, p.potential)
			newP.overall = math.clamp(p.overall + delta, 40, ceiling)
			newP.speed =
				math.clamp(p.speed + (if age > peak then -rng.int(0, 2) else rng.int(0, 1)), 40, 99)
			newP.awareness = math.clamp(p.awareness + rng.int(0, 1), 40, 99) -- experience always helps a bit
			table.insert(survivors, newP)
		end
	end

	return { roster = survivors, retirees = retirees }
end

return Development
