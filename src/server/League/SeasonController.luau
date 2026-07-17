--!strict
-- Season state machine: regular season -> playoffs -> offseason, one week per advance.
-- Pure Luau (no requires): the caller injects simFn (runs a game) and standingsFn
-- (ranks teams) so this module is fully Lune-testable and never touches Roblox APIs.

type GameResult = {
	homeId: string,
	awayId: string,
	winnerId: string,
	home: { score: number },
	away: { score: number },
}

-- simFn(homeId, awayId, seed) -> GameResult ; standingsFn(teamIds, results) -> sorted rows
type SimFn = (string, string, number) -> GameResult
type StandingsFn = ({ string }, { GameResult }) -> { { teamId: string } }

export type Season = {
	year: number,
	week: number,
	phase: string, -- "regular" | "playoffs" | "offseason"
	teamIds: { string },
	schedule: { { { home: string, away: string } } },
	results: { GameResult },
	playoffs: {
		round: number,
		seeds: { string },
		finalists: { string },
		champion: string?,
		games: { GameResult },
	}?,
}

export type AdvanceOutput = {
	games: { GameResult },
	phase: string,
	label: string,
	champion: string?,
}

local SeasonController = {}

function SeasonController.new(teamIds: { string }, schedule: any): Season
	return {
		year = 1,
		week = 1,
		phase = "regular",
		teamIds = table.clone(teamIds),
		schedule = schedule,
		results = {},
		playoffs = nil,
	}
end

local function gameSeed(season: Season, week: number, index: number): number
	return season.year * 1000000 + week * 1000 + index
end

function SeasonController.advanceWeek(
	season: Season,
	simFn: SimFn,
	standingsFn: StandingsFn,
	baseSeed: number
): AdvanceOutput
	if season.phase == "regular" then
		local week = season.schedule[season.week]
		local games: { GameResult } = {}
		for i, matchup in week do
			local res =
				simFn(matchup.home, matchup.away, baseSeed + gameSeed(season, season.week, i))
			-- Persist only a lean summary (keeps saves small); return the full result for display.
			table.insert(season.results, {
				homeId = res.homeId,
				awayId = res.awayId,
				winnerId = res.winnerId,
				home = { score = res.home.score },
				away = { score = res.away.score },
			})
			table.insert(games, res)
		end
		local label = "Week " .. season.week
		season.week += 1

		if season.week > #season.schedule then
			-- Seed the top 4 into the playoffs.
			local ranked = standingsFn(season.teamIds, season.results)
			local seeds = {}
			for i = 1, math.min(4, #ranked) do
				table.insert(seeds, ranked[i].teamId)
			end
			season.playoffs =
				{ round = 1, seeds = seeds, finalists = {}, champion = nil, games = {} }
			season.phase = "playoffs"
		end
		return { games = games, phase = season.phase, label = label }
	elseif season.phase == "playoffs" then
		local po = assert(season.playoffs, "playoffs missing")
		if po.round == 1 then
			local g1 = simFn(po.seeds[1], po.seeds[4], baseSeed + gameSeed(season, 100, 1))
			local g2 = simFn(po.seeds[2], po.seeds[3], baseSeed + gameSeed(season, 100, 2))
			po.finalists = { g1.winnerId, g2.winnerId }
			po.games = { g1, g2 }
			po.round = 2
			return { games = { g1, g2 }, phase = "playoffs", label = "Semifinals" }
		else
			local gf = simFn(po.finalists[1], po.finalists[2], baseSeed + gameSeed(season, 200, 1))
			po.champion = gf.winnerId
			table.insert(po.games, gf)
			season.phase = "offseason"
			return {
				games = { gf },
				phase = "offseason",
				label = "Championship",
				champion = gf.winnerId,
			}
		end
	end

	return { games = {}, phase = season.phase, label = "Offseason" }
end

return SeasonController
