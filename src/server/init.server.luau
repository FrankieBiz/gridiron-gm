--!strict
-- GRIDIRON GM — server entry point. Authoritative: all sim + save logic lives here,
-- the client only requests and displays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Teams = require(ReplicatedStorage.Shared.Data.Teams)
local SaveService = require(script.Data.SaveService)
local Generator = require(script.Data.Generator)
local Engine = require(script.Sim.Engine)

SaveService.init()

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

-- The state blob the client renders for the team-overview screen.
local function buildState(franchise: any)
	local teams = {}
	for _, t in Teams do
		table.insert(teams, teamSummary(t))
	end
	return {
		ok = true,
		hasFranchise = true,
		teamId = franchise.teamId,
		team = franchise.league[franchise.teamId], -- full, with roster
		teams = teams,
		record = {
			wins = franchise.wins,
			losses = franchise.losses,
			gamesPlayed = franchise.gamesPlayed,
		},
	}
end

Remotes.NewFranchise.OnServerInvoke = function(player: Player, teamId: any)
	if type(teamId) ~= "string" or not isValidTeam(teamId) then
		return { ok = false, error = "invalid team" }
	end
	local profile = SaveService.get(player)
	if not profile then
		return { ok = false, error = "no profile" }
	end

	local seed = player.UserId * 131 + os.time() % 100003
	profile.Data.franchise = {
		teamId = teamId,
		seed = seed,
		league = Generator.buildLeague(Teams, seed),
		gamesPlayed = 0,
		wins = 0,
		losses = 0,
	}
	print(string.format("[GRIDIRON] %s started a franchise with %s.", player.Name, teamId))
	return buildState(profile.Data.franchise)
end

Remotes.SimGame.OnServerInvoke = function(player: Player)
	local profile = SaveService.get(player)
	if not profile or not profile.Data.franchise then
		return { ok = false, error = "no franchise" }
	end
	local f = profile.Data.franchise

	-- Rotate through the league for opponents (Slice 2 will replace this with a schedule).
	local opponents = {}
	for _, t in Teams do
		if t.id ~= f.teamId then
			table.insert(opponents, t.id)
		end
	end
	table.sort(opponents)
	local oppId = opponents[(f.gamesPlayed % #opponents) + 1]

	local home = f.league[f.teamId]
	local away = f.league[oppId]
	local gameSeed = f.seed + (f.gamesPlayed + 1) * 7919
	local result = Engine.simulate(home, away, gameSeed)

	f.gamesPlayed += 1
	if result.winnerId == f.teamId then
		f.wins += 1
	else
		f.losses += 1
	end

	return {
		ok = true,
		result = result,
		homeName = home.name,
		awayName = away.name,
		record = { wins = f.wins, losses = f.losses, gamesPlayed = f.gamesPlayed },
	}
end

Remotes.GetState.OnServerInvoke = function(player: Player)
	local profile = SaveService.get(player)
	if not profile then
		return { ok = false, error = "no profile" }
	end
	local f = profile.Data.franchise
	if not f then
		return { ok = true, hasFranchise = false }
	end
	return buildState(f)
end

print("[GRIDIRON] Server up.")
