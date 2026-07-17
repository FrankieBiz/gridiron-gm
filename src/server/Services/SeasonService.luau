--!strict
-- Service: advance the season. Owns SimGame (advance one week, return the player's game)
-- and GetSeason (schedule + standings for the dashboard). Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SaveService = require(script.Parent.SaveService)
local Engine = require(script.Parent.Parent.Sim.Engine)
local Standings = require(script.Parent.Parent.League.Standings)
local Schedule = require(script.Parent.Parent.League.Schedule)
local SeasonController = require(script.Parent.Parent.League.SeasonController)
local Development = require(script.Parent.Parent.League.Development)
local DraftClass = require(script.Parent.Parent.League.DraftClass)
local Draft = require(script.Parent.Parent.League.Draft)
local OffseasonController = require(script.Parent.Parent.League.OffseasonController)

local SeasonService = {}

local OFFSEASON_DEPS = {
	Development = Development,
	DraftClass = DraftClass,
	Draft = Draft,
	Standings = Standings,
	Schedule = Schedule,
	SeasonController = SeasonController,
}

local function makeSimFn(league: any)
	return function(homeId: string, awayId: string, seed: number)
		return Engine.simulate(league[homeId], league[awayId], seed)
	end
end

function SeasonService:Start()
	Remotes.SimGame.OnServerInvoke = function(player: Player)
		local profile = SaveService.get(player)
		if not profile or not profile.Data.franchise then
			return { ok = false, error = "no franchise" }
		end
		local f = profile.Data.franchise

		-- If last season is over, run the offseason (age/develop/retire + draft) and roll
		-- into the new year, then play its opening week in the same click.
		local offseasonSummary = nil
		if f.season.phase == "offseason" then
			offseasonSummary = OffseasonController.run(f, OFFSEASON_DEPS, f.seed)
		end

		local season = f.season
		local out =
			SeasonController.advanceWeek(season, makeSimFn(f.league), Standings.compute, f.seed)

		-- Surface the player's own game from this week's slate (fallback to the first game).
		local mine = out.games[1]
		for _, g in out.games do
			if g.homeId == f.teamId or g.awayId == f.teamId then
				mine = g
				break
			end
		end

		return {
			ok = true,
			result = mine,
			homeName = f.league[mine.homeId].name,
			awayName = f.league[mine.awayId].name,
			record = Standings.recordFor(season.teamIds, season.results, f.teamId),
			label = out.label,
			phase = out.phase,
			champion = out.champion,
			year = season.year,
			week = season.week,
			offseason = offseasonSummary, -- present only on the first game of a new season
		}
	end

	Remotes.GetSeason.OnServerInvoke = function(player: Player)
		local profile = SaveService.get(player)
		if not profile or not profile.Data.franchise then
			return { ok = false, error = "no franchise" }
		end
		local f = profile.Data.franchise
		local season = f.season
		return {
			ok = true,
			year = season.year,
			week = season.week,
			phase = season.phase,
			totalWeeks = #season.schedule,
			standings = Standings.compute(season.teamIds, season.results),
			schedule = season.schedule,
		}
	end
end

return SeasonService
