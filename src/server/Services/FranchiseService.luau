--!strict
-- Service: create/read a franchise. Owns NewFranchise + GetState remotes.
-- Creating a franchise generates the league AND the season schedule.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Teams = require(ReplicatedStorage.Shared.Data.Teams)

local SaveService = require(script.Parent.SaveService)
local Generator = require(script.Parent.Parent.Data.Generator)
local Schedule = require(script.Parent.Parent.League.Schedule)
local Standings = require(script.Parent.Parent.League.Standings)
local SeasonController = require(script.Parent.Parent.League.SeasonController)

local FranchiseService = {}

local function teamSummary(team: any)
	return {
		id = team.id,
		city = team.city,
		name = team.name,
		abbr = team.abbr,
		primary = team.primary,
		secondary = team.secondary,
	}
end

local function isValidTeam(teamId: string): boolean
	for _, t in Teams do
		if t.id == teamId then
			return true
		end
	end
	return false
end

-- The blob the client renders for the team-overview screen.
local function buildState(f: any)
	local teams = {}
	for _, t in Teams do
		table.insert(teams, teamSummary(t))
	end
	return {
		ok = true,
		hasFranchise = true,
		teamId = f.teamId,
		team = f.league[f.teamId],
		teams = teams,
		record = Standings.recordFor(f.season.teamIds, f.season.results, f.teamId),
		coachingCredits = f.coachingCredits,
		season = {
			year = f.season.year,
			week = f.season.week,
			phase = f.season.phase,
			totalWeeks = #f.season.schedule,
		},
	}
end

FranchiseService.buildState = buildState

function FranchiseService:Start()
	Remotes.NewFranchise.OnServerInvoke = function(player: Player, teamId: any)
		if type(teamId) ~= "string" or not isValidTeam(teamId) then
			return { ok = false, error = "invalid team" }
		end
		local profile = SaveService.get(player)
		if not profile then
			return { ok = false, error = "no profile" }
		end

		local seed = player.UserId * 131 + os.time() % 100003
		local league = Generator.buildLeague(Teams, seed)
		local teamIds = {}
		for id in league do
			table.insert(teamIds, id)
		end
		table.sort(teamIds)

		profile.Data.franchise = {
			teamId = teamId,
			seed = seed,
			league = league,
			coachingCredits = 0,
			season = SeasonController.new(teamIds, Schedule.generate(teamIds)),
		}
		print(string.format("[GRIDIRON] %s started a franchise with %s.", player.Name, teamId))
		return buildState(profile.Data.franchise)
	end

	Remotes.GetState.OnServerInvoke = function(player: Player)
		local profile = SaveService.get(player)
		if not profile then
			return { ok = false, error = "no profile" }
		end
		if not profile.Data.franchise then
			return { ok = true, hasFranchise = false }
		end
		return buildState(profile.Data.franchise)
	end
end

return FranchiseService
