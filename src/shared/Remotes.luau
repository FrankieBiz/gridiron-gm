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
}

return Remotes
