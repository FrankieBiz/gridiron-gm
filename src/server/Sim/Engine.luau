--!strict
-- GRIDIRON GM — the simulation engine (the crown jewel).
--
-- Pure Luau, no Roblox APIs: runs inside Roblox AND under Lune (`lune run tests/sim.luau`),
-- so the math can be verified headlessly. Deterministic: same seed -> same game.
--
-- Model: drive-based, not "add ratings + roll a die". Each team gets ~11 possessions;
-- each drive resolves to TD / FG / punt / turnover from offense-vs-defense edge + tuned
-- variance, so scores land in realistic ranges and better teams win more (but upsets happen).

type PlayerLike = { position: string, overall: number }
type SimTeam = { id: string, name: string, roster: { PlayerLike } }

type Power = { off: number, def: number }

local Engine = {}

local DRIVES_PER_TEAM = 11
local HOME_FIELD_BONUS = 2

-- Park-Miller MINSTD PRNG (identical in Roblox & Lune). Intentionally self-contained.
local function makeRng(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local function nextFloat(): number
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
	return {
		float = nextFloat,
		int = function(min: number, max: number): number
			return math.floor(nextFloat() * (max - min + 1)) + min
		end,
		range = function(min: number, max: number): number
			return min + nextFloat() * (max - min)
		end,
	}
end

-- Average overall of the best `n` players at a position.
local function topAvg(roster: { PlayerLike }, pos: string, n: number): number
	local ovrs: { number } = {}
	for _, p in roster do
		if p.position == pos then
			table.insert(ovrs, p.overall)
		end
	end
	table.sort(ovrs, function(a, b)
		return a > b
	end)
	if #ovrs == 0 then
		return 60
	end
	local sum, count = 0, 0
	for i = 1, math.min(n, #ovrs) do
		sum += ovrs[i]
		count += 1
	end
	return sum / count
end

function Engine.computePower(roster: { PlayerLike }): Power
	local off = 0.42 * topAvg(roster, "QB", 1)
		+ 0.20 * topAvg(roster, "WR", 2)
		+ 0.14 * topAvg(roster, "RB", 1)
		+ 0.10 * topAvg(roster, "TE", 1)
		+ 0.14 * topAvg(roster, "OL", 3)
	local def = 0.40 * topAvg(roster, "DL", 2)
		+ 0.30 * topAvg(roster, "LB", 2)
		+ 0.30 * topAvg(roster, "DB", 2)
	return { off = off, def = def }
end

-- Resolve a single drive. Returns points, yards, and a description for scoring/turnover plays.
local function resolveDrive(rng: any, off: number, def: number)
	local edge = off - def
	local scoreChance = math.clamp(0.36 + edge * 0.006, 0.10, 0.72)

	if rng.float() < scoreChance then
		local tdChance = math.clamp(0.58 + edge * 0.003, 0.30, 0.82)
		if rng.float() < tdChance then
			return {
				kind = "TD",
				points = 7,
				yards = rng.range(55, 85),
				passHeavy = rng.float() < 0.58,
			}
		else
			return {
				kind = "FG",
				points = 3,
				yards = rng.range(35, 62),
				passHeavy = rng.float() < 0.5,
			}
		end
	end

	local turnoverChance = math.clamp(0.16 - edge * 0.003, 0.05, 0.32)
	if rng.float() < turnoverChance then
		return { kind = "TO", points = 0, yards = rng.range(5, 45), passHeavy = rng.float() < 0.5 }
	end
	return { kind = "PUNT", points = 0, yards = rng.range(2, 40), passHeavy = rng.float() < 0.55 }
end

local function quarterFor(possession: number): number
	return math.clamp(math.ceil(possession / (DRIVES_PER_TEAM * 2 / 4)), 1, 4)
end

function Engine.simulate(home: SimTeam, away: SimTeam, seed: number)
	local rng = makeRng(seed)
	local hp = Engine.computePower(home.roster)
	local ap = Engine.computePower(away.roster)
	hp = { off = hp.off + HOME_FIELD_BONUS, def = hp.def + HOME_FIELD_BONUS }

	local function newBox(teamId: string)
		return {
			teamId = teamId,
			score = 0,
			passYards = 0,
			rushYards = 0,
			turnovers = 0,
			tds = 0,
			fgs = 0,
		}
	end
	local home_box = newBox(home.id)
	local away_box = newBox(away.id)
	local plays: { any } = {}

	local function runDrive(
		possession: number,
		offTeam: SimTeam,
		box: any,
		off: number,
		def: number
	)
		local d = resolveDrive(rng, off, def)
		local passYds = math.floor(
			d.yards * (if d.passHeavy then rng.range(0.55, 0.72) else rng.range(0.3, 0.5))
		)
		box.passYards += passYds
		box.rushYards += math.floor(d.yards) - passYds

		local quarter = quarterFor(possession)
		local clock = string.format("%d:%02d", rng.int(0, 14), rng.int(0, 59))

		if d.kind == "TD" then
			box.score += 7
			box.tds += 1
			local yd = rng.int(1, 24)
			local how = if d.passHeavy
				then string.format("%d-yd TD pass", yd)
				else string.format("%d-yd TD run", yd)
			table.insert(plays, {
				quarter = quarter,
				clock = clock,
				text = string.format("TOUCHDOWN %s — %s", offTeam.name, how),
				homeScore = home_box.score,
				awayScore = away_box.score,
				big = true,
			})
		elseif d.kind == "FG" then
			box.score += 3
			box.fgs += 1
			table.insert(plays, {
				quarter = quarter,
				clock = clock,
				text = string.format("%s field goal — %d yards", offTeam.name, rng.int(21, 53)),
				homeScore = home_box.score,
				awayScore = away_box.score,
				big = false,
			})
		elseif d.kind == "TO" then
			box.turnovers += 1
			local what = if rng.float() < 0.5 then "INTERCEPTED" else "FUMBLE lost"
			table.insert(plays, {
				quarter = quarter,
				clock = clock,
				text = string.format("%s %s", offTeam.name, what),
				homeScore = home_box.score,
				awayScore = away_box.score,
				big = true,
			})
		end
	end

	for drive = 1, DRIVES_PER_TEAM do
		local hPoss = drive * 2 - 1
		local aPoss = drive * 2
		runDrive(hPoss, home, home_box, hp.off, ap.def)
		runDrive(aPoss, away, away_box, ap.off, hp.def)
	end

	-- Sudden-death OT: keep giving the stronger offense a crack until the tie breaks.
	local guard = 0
	while home_box.score == away_box.score and guard < 6 do
		guard += 1
		if hp.off >= ap.off then
			runDrive(DRIVES_PER_TEAM * 2 + guard, home, home_box, hp.off, ap.def)
		else
			runDrive(DRIVES_PER_TEAM * 2 + guard, away, away_box, ap.off, hp.def)
		end
	end
	if home_box.score == away_box.score then
		home_box.score += 3 -- absolute fallback, should ~never happen
	end

	local winnerId = if home_box.score > away_box.score then home.id else away.id

	return {
		seed = seed,
		homeId = home.id,
		awayId = away.id,
		home = home_box,
		away = away_box,
		plays = plays,
		winnerId = winnerId,
	}
end

return Engine
