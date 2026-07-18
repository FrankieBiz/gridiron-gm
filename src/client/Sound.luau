--!strict
-- Sound system v2: never-fatal UI audio with per-sound config, overlap-safe playback
-- (clone-play-destroy), slight pitch jitter so repeats don't machine-gun, and stinger
-- ducking (stingers dip the UI group briefly). Swap ids anytime for a different feel.

local SoundService = game:GetService("SoundService")

local Ticker = require(script.Parent.motion.Ticker)

export type PlayOpts = { volume: number?, speed: number? }

type Def = { id: string, volume: number, overlap: boolean, stinger: boolean? }

-- Well-known Roblox library SFX by role.
local DEFS: { [string]: Def } = {
	click = { id = "rbxassetid://6895079853", volume = 0.4, overlap = true },
	tick = { id = "rbxassetid://9119713951", volume = 0.25, overlap = true },
	pick = { id = "rbxassetid://9083889906", volume = 0.4, overlap = false },
	whistle = { id = "rbxassetid://663762266", volume = 0.4, overlap = false },
	cash = { id = "rbxassetid://607665037", volume = 0.4, overlap = false },
	swoosh = { id = "rbxassetid://9114065812", volume = 0.3, overlap = true },
	pop = { id = "rbxassetid://8071273586", volume = 0.4, overlap = true },
	drumroll = { id = "rbxassetid://9114221327", volume = 0.35, overlap = false },
	stinger_win = { id = "rbxassetid://9066717111", volume = 0.6, overlap = false, stinger = true },
	stinger_loss = { id = "rbxassetid://9058712757", volume = 0.5, overlap = false, stinger = true },
}

-- Aliases so optional call sites (toasts) stay fail-quiet but sensible.
local ALIASES: { [string]: { name: string, volume: number? } } = {
	toast_ok = { name = "tick" },
	toast_error = { name = "stinger_loss", volume = 0.2 },
}

local Sound = {}

local uiGroup: SoundGroup? = nil
local stingerGroup: SoundGroup? = nil
local cache: { [string]: Sound } = {}
local duckCancel: (() -> ())? = nil

local function groups(): (SoundGroup, SoundGroup)
	if not uiGroup then
		local ui = Instance.new("SoundGroup")
		ui.Name = "GridironUI"
		ui.Volume = 1
		ui.Parent = SoundService
		uiGroup = ui
		local st = Instance.new("SoundGroup")
		st.Name = "GridironStinger"
		st.Volume = 1
		st.Parent = SoundService
		stingerGroup = st
	end
	return uiGroup :: SoundGroup, stingerGroup :: SoundGroup
end

local function build(def: Def): Sound
	local ui, st = groups()
	local s = Instance.new("Sound")
	s.SoundId = def.id
	s.Volume = def.volume
	s.SoundGroup = if def.stinger then st else ui
	s.Parent = SoundService
	return s
end

-- Stingers dip the UI group to 0.3 for 1s, then recover linearly over 0.3s.
local function duckUI()
	local ui = groups()
	if duckCancel then
		duckCancel()
	end
	ui.Volume = 0.3
	local elapsed = 0
	duckCancel = Ticker.add(function(dt: number): boolean
		elapsed += dt
		if elapsed < 1 then
			return false
		end
		local recover = math.clamp((elapsed - 1) / 0.3, 0, 1)
		ui.Volume = 0.3 + 0.7 * recover
		if recover >= 1 then
			duckCancel = nil
			return true
		end
		return false
	end)
end

-- Preloadable asset ids (init.client warms these during boot).
function Sound.assetIds(): { string }
	local ids = {}
	for _, def in DEFS do
		table.insert(ids, def.id)
	end
	return ids
end

function Sound.play(name: string, opts: PlayOpts?)
	-- pcall so a bad/unresolved asset can never break gameplay.
	pcall(function()
		local volumeScale = 1
		local alias = ALIASES[name]
		if alias then
			volumeScale = alias.volume or 1
			name = alias.name
		end
		local def = DEFS[name]
		if not def then
			return
		end

		local volume = (if opts and opts.volume then opts.volume else def.volume) * volumeScale
		local speed = (if opts and opts.speed then opts.speed else 1) * (0.95 + math.random() * 0.1)

		if def.stinger then
			duckUI()
		end

		if def.overlap then
			local s = build(def)
			s.Volume = volume
			s.PlaybackSpeed = speed
			s.Ended:Once(function()
				s:Destroy()
			end)
			-- Backstop: a failed asset load never fires Ended — don't leak the clone.
			task.delay(10, function()
				if s.Parent then
					s:Destroy()
				end
			end)
			s:Play()
		else
			local s = cache[name]
			if not s then
				s = build(def)
				cache[name] = s
			end
			s.Volume = volume
			s.PlaybackSpeed = speed
			s:Play()
		end
	end)
end

return Sound
