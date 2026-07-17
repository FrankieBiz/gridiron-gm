--!strict
-- Shared accessor for RemoteEvents.
-- The server creates each remote; the client waits for it. Require this from
-- both sides and read the same field — never hard-code Instance paths in UI code.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function getOrCreate(name: string): RemoteEvent
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			return existing
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
		return remote
	else
		return ReplicatedStorage:WaitForChild(name) :: RemoteEvent
	end
end

local Remotes = {
	Ping = getOrCreate("Ping"),
}

return Remotes
