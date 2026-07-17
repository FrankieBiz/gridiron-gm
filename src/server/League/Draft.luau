--!strict
-- Draft helpers + an AI-only auto-draft. `bestIndex`/`toPlayer` are reused by the
-- interactive DraftBoard so human and AI picks share one code path. Pure Luau (seed-based).

local Draft = {}

local ROUNDS = 3
local TARGET = { QB = 2, RB = 3, WR = 4, TE = 1, OL = 5, DL = 3, LB = 2, DB = 3 }

Draft.ROUNDS = ROUNDS

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
		int = function(a: number, b: number)
			return math.floor(nextFloat() * (b - a + 1)) + a
		end,
	}
end

local function positionCounts(roster: { any }): { [string]: number }
	local counts: { [string]: number } = {}
	for _, p in roster do
		counts[p.position] = (counts[p.position] or 0) + 1
	end
	return counts
end

-- Convert a drafted prospect into a real roster player (deterministic from seed).
function Draft.toPlayer(pick: any, teamId: string, seed: number): any
	local rng = makeRng(seed)
	return {
		id = teamId .. "-" .. pick.id,
		name = pick.name,
		position = pick.position,
		age = pick.age,
		overall = pick.trueOverall,
		speed = math.clamp(pick.trueOverall + rng.int(-6, 6), 40, 99),
		strength = math.clamp(pick.trueOverall + rng.int(-6, 6), 40, 99),
		awareness = math.clamp(pick.trueOverall + rng.int(-6, 6), 40, 99),
		potential = pick.truePotential,
		contractYears = rng.int(3, 4),
		salary = math.floor(pick.trueOverall * pick.trueOverall * 0.9),
		morale = rng.int(68, 92),
		devTrait = pick.devTrait,
	}
end

-- Index (into `remaining`) of the best prospect for this team by talent + positional need.
function Draft.bestIndex(team: any, remaining: { any }, seed: number): number
	local rng = makeRng(seed)
	local counts = positionCounts(team.roster)
	local bestIdx, bestScore = 1, -math.huge
	for idx, pr in remaining do
		local need = math.max(0, (TARGET[pr.position] or 2) - (counts[pr.position] or 0))
		local score = pr.trueOverall
			+ need * 9
			+ (pr.truePotential - pr.trueOverall) * 0.5
			+ rng.int(0, 3)
		if score > bestScore then
			bestScore = score
			bestIdx = idx
		end
	end
	return bestIdx
end

-- AI-only auto-draft (used for fully-simulated leagues / tests). order: worst-first.
function Draft.run(league: any, order: { string }, class: { any }, seed: number): { any }
	local remaining = table.clone(class)
	local results: { any } = {}
	local n = 0
	for round = 1, ROUNDS do
		for _, teamId in order do
			if #remaining == 0 then
				break
			end
			n += 1
			local team = league[teamId]
			local idx = Draft.bestIndex(team, remaining, seed + n)
			local pick = table.remove(remaining, idx)
			local player = Draft.toPlayer(pick, teamId, seed + n * 7)
			table.insert(team.roster, player)
			table.insert(results, {
				teamId = teamId,
				round = round,
				name = player.name,
				position = player.position,
				overall = player.overall,
				potential = player.potential,
				devTrait = player.devTrait,
			})
		end
	end
	return results
end

return Draft
