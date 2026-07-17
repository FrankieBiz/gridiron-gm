--!strict
-- Tiny sound helper. Uses Roblox library sound asset IDs; if an ID doesn't resolve the
-- call is simply silent (never fatal). Volume kept low so UI stays pleasant.

local SoundService = game:GetService("SoundService")

local Sound = {}

-- Well-known Roblox library SFX. Swap these ids anytime for a different feel.
local IDS = {
	click = "rbxassetid://6895079853", -- soft UI click
	pick = "rbxassetid://9083889906", -- confirm / positive
	whistle = "rbxassetid://663762266", -- referee whistle
	cash = "rbxassetid://607665037", -- coin / purchase
}

local cache: { [string]: Sound } = {}

local function get(name: string): Sound?
	local id = IDS[name]
	if not id then
		return nil
	end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = 0.4
		s.Parent = SoundService
		cache[name] = s
	end
	return s
end

function Sound.play(name: string)
	-- pcall so a bad/unresolved asset can never break gameplay.
	pcall(function()
		local s = get(name)
		if s then
			s:Play()
		end
	end)
end

return Sound
