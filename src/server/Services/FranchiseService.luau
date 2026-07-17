--!strict
-- Service: create/read a franchise. Owns NewFranchise + GetState remotes.
-- Creating a franchise generates the league AND the season schedule.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Teams = require(ReplicatedStorage.Shared.Data.Teams)
local Facilities = require(ReplicatedStorage.Shared.Data.Facilities)

local SaveService = require(script.Parent.SaveService)
local Generator = require(script.Parent.Parent.Data.Generator)
local Schedule = require(script.Parent.Parent.League.Schedule)
local Standings = require(script.Parent.Parent.League.Standings)
local SeasonController = require(script.Parent.Parent.League.SeasonController)
local CareerController = require(script.Parent.Parent.League.CareerController)
local Achievements = require(script.Parent.Parent.League.Achievements)

-- Client-safe achievement metadata (no test predicates), computed once.
local ACHIEVEMENT_DEFS = {}
for _, def in Achievements.defs do
	table.insert(
		ACHIEVEMENT_DEFS,
		{ id = def.id, name = def.name, desc = def.desc, points = def.points }
	)
end

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
	f.facilities = f.facilities or table.clone(Facilities.default)
	local prestige = (f.league[f.teamId].prestige or 3)
	return {
		ok = true,
		hasFranchise = true,
		teamId = f.teamId,
		team = f.league[f.teamId],
		teams = teams,
		record = Standings.recordFor(f.season.teamIds, f.season.results, f.teamId),
		coachingCredits = f.coachingCredits,
		facilities = f.facilities,
		coach = f.coach,
		prestige = prestige,
		expectedWins = CareerController.expectedWins(prestige),
		pendingCareer = f.pendingCareer or false,
		news = f.news or {},
		history = (f.history and f.history.seasons) or {},
		achievements = f.achievements or {},
		achievementDefs = ACHIEVEMENT_DEFS,
		dynastyScore = f.dynastyScore or 0,
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
			facilities = table.clone(Facilities.default),
			coach = CareerController.newCoach(teamId),
			pendingCareer = false,
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

	Remotes.UpgradeFacility.OnServerInvoke = function(player: Player, key: any)
		if type(key) ~= "string" then
			return { ok = false, error = "bad key" }
		end
		local profile = SaveService.get(player)
		if not profile or not profile.Data.franchise then
			return { ok = false, error = "no franchise" }
		end
		local f = profile.Data.franchise
		f.facilities = f.facilities or table.clone(Facilities.default)
		local level = f.facilities[key]
		if level == nil then
			return { ok = false, error = "unknown facility" }
		end
		if level >= Facilities.MAX_LEVEL then
			return { ok = false, error = "maxed out" }
		end
		local cost = Facilities.costForNext(level)
		if (f.coachingCredits or 0) < cost then
			return { ok = false, error = "not enough credits" }
		end
		f.coachingCredits -= cost
		f.facilities[key] = level + 1
		return buildState(f)
	end
end

return FranchiseService
