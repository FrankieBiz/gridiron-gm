--!strict
-- Deterministic per-player season stat lines + an "impact" score used for awards.
-- Pure Luau (own PRNG) -> Lune-testable. Stats are synthesized from overall/position/team
-- success + seed so they're reproducible and cheap (no per-game storage needed).

local Stats = {}

local function makeRng(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
end

local OFFENSE = { QB = true, RB = true, WR = true, TE = true, OL = true }
local DEFENSE = { DL = true, LB = true, DB = true }

Stats.isOffense = OFFENSE
Stats.isDefense = DEFENSE

-- A single player's season line. teamWins scales counting stats (good teams score more).
function Stats.line(player: any, teamWins: number, seed: number)
	local rnd = makeRng(seed + player.overall * 31)
	local q = player.overall / 100
	local winBoost = 0.75 + teamWins * 0.035
	local pos = player.position

	local line: { [string]: number } = {}
	if pos == "QB" then
		line.passYds = math.floor((2600 + q * 2200) * winBoost * (0.85 + rnd() * 0.3))
		line.passTD = math.floor((10 + q * 30) * winBoost * (0.8 + rnd() * 0.4))
		line.int = math.floor((16 - q * 12) * (0.7 + rnd() * 0.6))
	elseif pos == "RB" then
		line.rushYds = math.floor((500 + q * 1300) * winBoost * (0.8 + rnd() * 0.4))
		line.rushTD = math.floor((3 + q * 14) * winBoost * (0.7 + rnd() * 0.5))
	elseif pos == "WR" or pos == "TE" then
		line.recYds = math.floor((400 + q * 1200) * winBoost * (0.8 + rnd() * 0.4))
		line.recTD = math.floor((2 + q * 12) * winBoost * (0.7 + rnd() * 0.5))
	elseif pos == "OL" then
		line.pancakes = math.floor((20 + q * 60) * (0.85 + rnd() * 0.3))
	else -- defense
		line.tackles = math.floor((40 + q * 70) * (0.85 + rnd() * 0.3))
		line.sacks = if pos == "DL" or pos == "LB"
			then math.floor((2 + q * 14) * (0.7 + rnd() * 0.6))
			else 0
		line.defInt = if pos == "DB" or pos == "LB"
			then math.floor((1 + q * 7) * (0.6 + rnd() * 0.7))
			else 0
	end
	return line
end

-- Impact score for ranking award candidates (higher = better season).
function Stats.impact(player: any, line: any, teamWins: number): number
	local base = player.overall + teamWins * 1.5
	if player.position == "QB" then
		return base + (line.passYds or 0) / 90 + (line.passTD or 0) * 2 - (line.int or 0) * 1.5
	elseif player.position == "RB" then
		return base + (line.rushYds or 0) / 70 + (line.rushTD or 0) * 2.5
	elseif player.position == "WR" or player.position == "TE" then
		return base + (line.recYds or 0) / 75 + (line.recTD or 0) * 2.5
	elseif player.position == "OL" then
		return base + (line.pancakes or 0) / 6
	end
	return base + (line.tackles or 0) / 6 + (line.sacks or 0) * 3 + (line.defInt or 0) * 4
end

-- Human-readable stat summary for a player's season.
function Stats.summary(player: any, line: any): string
	local p = player.position
	if p == "QB" then
		return string.format(
			"%d yds, %d TD, %d INT",
			line.passYds or 0,
			line.passTD or 0,
			line.int or 0
		)
	elseif p == "RB" then
		return string.format("%d rush yds, %d TD", line.rushYds or 0, line.rushTD or 0)
	elseif p == "WR" or p == "TE" then
		return string.format("%d rec yds, %d TD", line.recYds or 0, line.recTD or 0)
	elseif p == "OL" then
		return string.format("%d pancakes", line.pancakes or 0)
	end
	return string.format(
		"%d tkl, %d sacks, %d INT",
		line.tackles or 0,
		line.sacks or 0,
		line.defInt or 0
	)
end

return Stats
