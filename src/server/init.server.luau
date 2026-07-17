--!strict
-- GRIDIRON GM — server entry point.
--
-- Phase 0 smoke test (satisfies the playbook's Definition of Done):
--   * a client button fires a RemoteEvent -> the server prints it
--   * one number saves per player via ProfileStore, persists, and loads on rejoin
--
-- Everything authoritative lives here. The client only asks and displays.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local ProfileStore = require(ServerStorage:WaitForChild("ProfileStore"))

-- One number per player: how many times they've pinged the server.
local PROFILE_TEMPLATE = {
	pingCount = 0,
}

local store = ProfileStore.New("PlayerData_v1", PROFILE_TEMPLATE)
local profiles: { [Player]: any } = {}

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync("player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- If the load failed, never let them in with default data (playbook §03).
	if profile == nil then
		player:Kick("Data load failed — please rejoin.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile() -- old saves gain any new template fields

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Data session ended — please rejoin.")
	end)

	if player.Parent == Players then
		profiles[player] = profile
		print(
			string.format(
				"[GRIDIRON] %s loaded — pingCount = %d",
				player.Name,
				profile.Data.pingCount
			)
		)
	else
		profile:EndSession()
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = profiles[player]
	if profile then
		profile:EndSession()
	end
end)

Remotes.Ping.OnServerEvent:Connect(function(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Data.pingCount += 1
	print(
		string.format("[GRIDIRON] Ping from %s — total %d", player.Name, profile.Data.pingCount)
	)
end)

print("[GRIDIRON] Server up.")
