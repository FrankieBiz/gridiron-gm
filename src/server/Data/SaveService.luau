--!strict
-- Wraps ProfileStore: session-locked, auto-saving, dupe-proof per-player saves.
-- Franchise state (chosen team, generated league, record) lives in profile.Data.franchise.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ProfileStore = require(ServerStorage:WaitForChild("ProfileStore"))

-- `false` = no franchise yet. Reconcile() fills this key on old saves.
local TEMPLATE = {
	franchise = false,
}

local store = ProfileStore.New("FranchiseData_v1", TEMPLATE)
local profiles: { [Player]: any } = {}

local SaveService = {}

function SaveService.get(player: Player): any?
	return profiles[player]
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync("player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Never let a player in with default data — that overwrites a real save on recovery.
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

function SaveService.init()
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
end

return SaveService
