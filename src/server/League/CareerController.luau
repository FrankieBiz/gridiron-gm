--!strict
-- The coaching career: owner expectations by team prestige, a reputation + job-security
-- track, firing when the seat gets too hot, and end-of-season job offers that let you climb
-- from a bottom team to a blue-blood. Pure Luau -> Lune-testable.

local CareerController = {}

export type Coach = {
	reputation: number,
	jobSecurity: number,
	careerWins: number,
	careerLosses: number,
	championships: number,
	seasonsCoached: number,
	teamsCoached: { string },
}

function CareerController.newCoach(startTeamId: string): Coach
	return {
		reputation = 40,
		jobSecurity = 55,
		careerWins = 0,
		careerLosses = 0,
		championships = 0,
		seasonsCoached = 0,
		teamsCoached = { startTeamId },
	}
end

-- Owner's win target for a team of the given prestige (14-game season).
function CareerController.expectedWins(prestige: number): number
	return 2 + prestige * 2 -- p1=4 (rebuild) .. p5=12 (title-or-bust)
end

function CareerController.tagFor(prestige: number): string
	if prestige <= 2 then
		return "REBUILD"
	elseif prestige == 3 then
		return "PLAYOFF PUSH"
	end
	return "WIN NOW"
end

-- Grade the finished season, mutate the coach, and report what happened.
function CareerController.evaluate(
	coach: Coach,
	rec: any,
	champion: boolean,
	madePlayoffs: boolean,
	prestige: number
)
	local expected = CareerController.expectedWins(prestige)
	local delta = rec.wins - expected

	-- -6 baseline so treading water slowly cools the seat; wins/playoffs/titles heat it up.
	local secDelta = delta * 4 - 6 + (if champion then 30 else 0) + (if madePlayoffs then 10 else 0)
	local repDelta = delta * 2 + (if champion then 12 else 0) + (if madePlayoffs then 4 else 0)

	coach.jobSecurity = math.clamp(coach.jobSecurity + secDelta, 0, 100)
	coach.reputation = math.clamp(coach.reputation + repDelta, 0, 100)
	coach.careerWins += rec.wins
	coach.careerLosses += rec.losses
	coach.seasonsCoached += 1
	if champion then
		coach.championships += 1
	end

	local fired = coach.jobSecurity <= 0

	return {
		expectedWins = expected,
		actualWins = rec.wins,
		met = rec.wins >= expected,
		champion = champion,
		madePlayoffs = madePlayoffs,
		secDelta = secDelta,
		repDelta = repDelta,
		fired = fired,
		jobSecurity = coach.jobSecurity,
		reputation = coach.reputation,
	}
end

-- End-of-season job offers. Reputation gates how prestigious a team will hire you.
-- `_fired`/`_seed` are kept for call-site symmetry and future variation.
function CareerController.generateOffers(
	coach: Coach,
	league: any,
	currentTeamId: string,
	_fired: boolean,
	_seed: number
)
	local ceiling = math.clamp(math.floor(coach.reputation / 18) + 1, 1, 5)

	local candidates = {}
	for id, team in league do
		if id ~= currentTeamId and (team.prestige or 3) <= ceiling then
			table.insert(candidates, id)
		end
	end
	-- Highest-prestige jobs first (the tempting step up).
	table.sort(candidates, function(a, b)
		return (league[a].prestige or 3) > (league[b].prestige or 3)
	end)

	local offers = {}
	local count = math.min(3, #candidates)
	for i = 1, count do
		local id = candidates[i]
		local team = league[id]
		local p = team.prestige or 3
		table.insert(offers, {
			teamId = id,
			city = team.city,
			name = team.name,
			prestige = p,
			expectedWins = CareerController.expectedWins(p),
			tag = CareerController.tagFor(p),
		})
	end
	return offers
end

return CareerController
