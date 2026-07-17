--!strict
-- Procedural roster generator. Pure Luau (no Roblox APIs) so it runs under Lune too.
-- Deterministic: same seed -> same league. Frank owns the name pools & tuning feel.

type Player = {
	id: string,
	name: string,
	position: string,
	age: number,
	overall: number,
	speed: number,
	strength: number,
	awareness: number,
	potential: number,
	contractYears: number,
	salary: number,
	morale: number,
}

type TeamIdentity = {
	id: string,
	city: string,
	name: string,
	abbr: string,
	primary: string,
	secondary: string,
}

type Team = TeamIdentity & { roster: { Player } }

local Generator = {}

-- Park-Miller MINSTD: tiny deterministic PRNG, identical in Roblox and Lune.
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
		pick = function<T>(t: { T }): T
			return t[math.floor(nextFloat() * #t) + 1]
		end,
	}
end

local FIRST_NAMES = {
	"Jaylen",
	"Marcus",
	"Deshawn",
	"Trey",
	"Cole",
	"Xavier",
	"Bryce",
	"Malik",
	"Tanner",
	"Dominic",
	"Elijah",
	"Kaden",
	"Rashad",
	"Vince",
	"Grayson",
	"Amari",
	"Damian",
	"Hunter",
	"Isaiah",
	"Beau",
}
local LAST_NAMES = {
	"Carter",
	"Reeves",
	"Okafor",
	"Sanders",
	"Whitfield",
	"Boone",
	"Delgado",
	"Hayes",
	"Nakamura",
	"Voss",
	"Freeman",
	"Castillo",
	"Brooks",
	"Achebe",
	"Sundqvist",
	"Mercer",
	"Ellison",
	"Traore",
	"Bishop",
	"Kowalski",
}

-- position -> { count, offAdj } ; offense-ish get +power weighting handled in the sim.
local ROSTER_TEMPLATE = {
	{ pos = "QB", count = 2 },
	{ pos = "RB", count = 3 },
	{ pos = "WR", count = 4 },
	{ pos = "TE", count = 1 },
	{ pos = "OL", count = 5 },
	{ pos = "DL", count = 3 },
	{ pos = "LB", count = 2 },
	{ pos = "DB", count = 3 },
}

local function makePlayer(
	rng: any,
	teamId: string,
	index: number,
	pos: string,
	teamBase: number
): Player
	local age = rng.int(21, 35)
	-- Age curve: peak around 27; young + old are a touch below their raw talent.
	local agePenalty = math.floor(math.abs(27 - age) * 0.6)
	local overall = math.clamp(teamBase + rng.int(-11, 11) - agePenalty, 52, 95)
	-- Younger players carry more upside.
	local upside = if age <= 24 then rng.int(3, 14) else rng.int(0, 4)
	local potential = math.clamp(overall + upside, overall, 99)

	return {
		id = teamId .. "-" .. index,
		name = rng.pick(FIRST_NAMES) .. " " .. rng.pick(LAST_NAMES),
		position = pos,
		age = age,
		overall = overall,
		speed = math.clamp(overall + rng.int(-8, 8), 40, 99),
		strength = math.clamp(overall + rng.int(-8, 8), 40, 99),
		awareness = math.clamp(overall + rng.int(-8, 8), 40, 99),
		potential = potential,
		contractYears = rng.int(1, 4),
		salary = math.floor(overall * overall * 0.9), -- rough "coaching credits" cost
		morale = rng.int(62, 92),
	}
end

-- Build one team's roster off a per-team seed.
function Generator.rosterFor(teamId: string, teamBase: number, seed: number): { Player }
	local rng = makeRng(seed)
	local roster: { Player } = {}
	local index = 0
	for _, group in ROSTER_TEMPLATE do
		for _ = 1, group.count do
			index += 1
			table.insert(roster, makePlayer(rng, teamId, index, group.pos, teamBase))
		end
	end
	return roster
end

-- Build the whole league. `identities` comes from Shared/Data/Teams so this stays pure.
function Generator.buildLeague(identities: { TeamIdentity }, seed: number): { [string]: Team }
	local rng = makeRng(seed)
	local league: { [string]: Team } = {}
	for _, identity in identities do
		local teamBase = rng.int(66, 82) -- team-quality spread
		local team: Team = {
			id = identity.id,
			city = identity.city,
			name = identity.name,
			abbr = identity.abbr,
			primary = identity.primary,
			secondary = identity.secondary,
			roster = Generator.rosterFor(identity.id, teamBase, seed + rng.int(1, 1000000)),
		}
		league[identity.id] = team
	end
	return league
end

return Generator
