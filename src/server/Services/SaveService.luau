--!strict
-- Service: session-locked per-player saves via ProfileStore. Franchise state lives in
-- profile.Data.franchise. Bumped to _v2 (season-aware shape; old v1 saves are ignored).

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ProfileStore = require(ServerStorage:WaitForChild("ProfileStore"))

local TEMPLATE = {
	franchise = false,
}

local SaveService = {}
local profiles: { [Player]: any } = {}
local store: any = nil

function SaveService.get(player: Player): any?
	return profiles[player]
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync("player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		player:Kick("Data load failed — please rejoin.")
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Data session ended — please rejoin.")
	end)
	if player.Parent == Players then
		profiles[player] = profile
		print(string.format("[GRIDIRON] %s data loaded.", player.Name))
	else
		profile:EndSession()
	end
end

function SaveService:Init()
	store = ProfileStore.New("FranchiseData_v2", TEMPLATE)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile:EndSession()
		end
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return SaveService
