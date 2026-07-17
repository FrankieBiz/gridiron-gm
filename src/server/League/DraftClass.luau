--!strict
-- Rookie draft class generation with FOG-OF-WAR scouting. Each prospect has HIDDEN true
-- ratings (trueOverall/truePotential/devTrait) computed here on the server; the player only
-- ever sees a SCOUTED range that tightens as scouting is spent. Never send true values to
-- the client — that's what makes the draft a real gamble. Pure Luau -> Lune-testable.

local DraftClass = {}

local FIRST = {
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
	"Rashad",
	"Vince",
	"Grayson",
	"Amari",
	"Damian",
	"Hunter",
	"Isaiah",
	"Beau",
	"Kai",
	"Ronan",
}
local LAST = {
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
	"Mercer",
	"Ellison",
	"Traore",
	"Bishop",
	"Kowalski",
	"Ramsey",
}
-- Weighted position pool (more skill players in a class).
local POOL = { "QB", "RB", "WR", "WR", "TE", "OL", "OL", "DL", "DL", "LB", "DB", "DB" }

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
	}
end

export type Prospect = {
	id: string,
	name: string,
	position: string,
	age: number,
	trueOverall: number, -- HIDDEN (server-only)
	truePotential: number, -- HIDDEN
	devTrait: string, -- HIDDEN
	scouted: { ovrMin: number, ovrMax: number, potMin: number, potMax: number, points: number },
}

function DraftClass.generate(year: number, count: number, seed: number): { Prospect }
	local rng = makeRng(seed)
	local prospects: { Prospect } = {}

	for i = 1, count do
		local pos = POOL[rng.int(1, #POOL)]
		local trueOverall = rng.int(56, 82)
		local truePotential = math.clamp(trueOverall + rng.int(4, 24), trueOverall, 99)
		local gap = truePotential - trueOverall

		local roll = rng.float()
		local devTrait = "normal"
		if gap >= 18 and roll < 0.15 then
			devTrait = "superstar"
		elseif gap >= 12 and roll < 0.35 then
			devTrait = "star"
		end

		local ovrBand = rng.int(6, 11)
		local potBand = rng.int(10, 18)
		prospects[i] = {
			id = "R" .. year .. "-" .. i,
			name = FIRST[rng.int(1, #FIRST)] .. " " .. LAST[rng.int(1, #LAST)],
			position = pos,
			age = rng.int(21, 22),
			trueOverall = trueOverall,
			truePotential = truePotential,
			devTrait = devTrait,
			scouted = {
				ovrMin = math.max(40, trueOverall - ovrBand),
				ovrMax = math.min(99, trueOverall + ovrBand),
				potMin = math.max(trueOverall, truePotential - potBand),
				potMax = math.min(99, truePotential + potBand),
				points = 0,
			},
		}
	end

	return prospects
end

-- Client-safe view: NEVER expose true values. Call this before sending prospects over the wire.
function DraftClass.scoutedView(prospect: Prospect)
	return {
		id = prospect.id,
		name = prospect.name,
		position = prospect.position,
		age = prospect.age,
		ovrMin = prospect.scouted.ovrMin,
		ovrMax = prospect.scouted.ovrMax,
		potMin = prospect.scouted.potMin,
		potMax = prospect.scouted.potMax,
		scoutPoints = prospect.scouted.points,
	}
end

-- Spend scouting effort on a prospect: narrows both ranges toward the truth.
function DraftClass.scout(prospect: Prospect)
	local s = prospect.scouted
	s.points += 1
	s.ovrMin = math.min(prospect.trueOverall, s.ovrMin + 2)
	s.ovrMax = math.max(prospect.trueOverall, s.ovrMax - 2)
	s.potMin = math.min(prospect.truePotential, s.potMin + 3)
	s.potMax = math.max(prospect.truePotential, s.potMax - 3)
end

return DraftClass
