--!nocheck
-- Headless sim verification. Run: `lune run tests/sim.luau`
-- Not part of the Roblox build (tests/ is outside the Rojo tree). Checks that scores land
-- in realistic ranges and that better teams win more often than not.

local Engine = require("../src/server/Sim/Engine")
local Generator = require("../src/server/Data/Generator")
local Teams = require("../src/shared/Data/Teams")

local league = Generator.buildLeague(Teams, 12345)
local ids = {}
for id in league do
	table.insert(ids, id)
end
table.sort(ids)

local function powerTotal(roster)
	local p = Engine.computePower(roster)
	return p.off * 0.5 + p.def * 0.5
end

print("Team power ratings (off / def):")
for _, id in ids do
	local p = Engine.computePower(league[id].roster)
	print(
		string.format(
			"  %s  off=%.1f  def=%.1f  total=%.1f",
			id,
			p.off,
			p.def,
			powerTotal(league[id].roster)
		)
	)
end

local GAMES = 2000
local totalPoints, minScore, maxScore = 0, 999, 0
local favWins, decided = 0, 0
local buckets = { ["<10"] = 0, ["10-19"] = 0, ["20-29"] = 0, ["30-39"] = 0, ["40+"] = 0 }

local function bucket(s)
	if s < 10 then
		return "<10"
	elseif s < 20 then
		return "10-19"
	elseif s < 30 then
		return "20-29"
	elseif s < 40 then
		return "30-39"
	end
	return "40+"
end

for i = 1, GAMES do
	local h = league[ids[(i % #ids) + 1]]
	local a = league[ids[((i + 3) % #ids) + 1]]
	if h.id == a.id then
		continue
	end
	local r = Engine.simulate(h, a, 1000 + i)
	for _, box in { r.home, r.away } do
		totalPoints += box.score
		minScore = math.min(minScore, box.score)
		maxScore = math.max(maxScore, box.score)
		buckets[bucket(box.score)] += 1
	end
	local hPow, aPow = powerTotal(h.roster) + 2, powerTotal(a.roster) -- +2 home field
	local favIsHome = hPow >= aPow
	if hPow ~= aPow then
		decided += 1
		if (favIsHome and r.winnerId == h.id) or (not favIsHome and r.winnerId == a.id) then
			favWins += 1
		end
	end
end

print(string.format("\n%d games simulated", GAMES))
print(
	string.format(
		"Avg points/team: %.1f   (min %d, max %d)",
		totalPoints / (GAMES * 2),
		minScore,
		maxScore
	)
)
print(string.format("Favorite win rate: %.1f%%  (want ~60-72%%)", (favWins / decided) * 100))
print("Score distribution (per team):")
for _, key in { "<10", "10-19", "20-29", "30-39", "40+" } do
	print(
		string.format("  %-6s %5d  (%.1f%%)", key, buckets[key], (buckets[key] / (GAMES * 2)) * 100)
	)
end

-- Determinism check: same seed must reproduce the same final score.
local a1 = Engine.simulate(league[ids[1]], league[ids[2]], 777)
local a2 = Engine.simulate(league[ids[1]], league[ids[2]], 777)
assert(a1.home.score == a2.home.score and a1.away.score == a2.away.score, "sim not deterministic!")
print("\nDeterminism check passed (same seed -> same score).")
