--!strict
-- Shared accessor for the client<->server pipes.
-- Server creates each remote; client waits for it. Require this on both sides so UI
-- code never hard-codes Instance paths.
--
-- These are RemoteFunctions (request -> response): the client asks the authoritative
-- server to do something and gets the result back. All game logic stays server-side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function getOrCreate(className: string, name: string): Instance
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(name)
		if existing then
			return existing
		end
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = ReplicatedStorage
		return remote
	else
		return ReplicatedStorage:WaitForChild(name)
	end
end

local Remotes = {
	-- (player, teamId) -> state table for the chosen franchise
	NewFranchise = getOrCreate("RemoteFunction", "NewFranchise") :: RemoteFunction,
	-- (player) -> { result, record, ... } after simulating the next game
	SimGame = getOrCreate("RemoteFunction", "SimGame") :: RemoteFunction,
	-- (player) -> current franchise state (for reconnect / initial load)
	GetState = getOrCreate("RemoteFunction", "GetState") :: RemoteFunction,
	-- (player) -> full season: schedule, standings, phase (for the season dashboard)
	GetSeason = getOrCreate("RemoteFunction", "GetSeason") :: RemoteFunction,
	-- (player, facilityKey) -> spend coaching credits to upgrade a facility
	UpgradeFacility = getOrCreate("RemoteFunction", "UpgradeFacility") :: RemoteFunction,
	-- (player, teamId) -> stay or take a job offer; begins the interactive draft
	ChooseJob = getOrCreate("RemoteFunction", "ChooseJob") :: RemoteFunction,
	-- (player) -> current draft board view (prospects, who's on the clock, my picks)
	GetDraft = getOrCreate("RemoteFunction", "GetDraft") :: RemoteFunction,
	-- (player, prospectId) -> spend a scouting point to narrow that prospect's range
	ScoutProspect = getOrCreate("RemoteFunction", "ScoutProspect") :: RemoteFunction,
	-- (player, prospectId) -> draft that prospect; AI fills to your next pick / draft end
	MakePick = getOrCreate("RemoteFunction", "MakePick") :: RemoteFunction,
	-- (player, freeAgentId) -> sign a free agent with coaching credits
	SignFreeAgent = getOrCreate("RemoteFunction", "SignFreeAgent") :: RemoteFunction,
	-- (player) -> close free agency and start the next season
	FinishOffseason = getOrCreate("RemoteFunction", "FinishOffseason") :: RemoteFunction,
}

return Remotes
