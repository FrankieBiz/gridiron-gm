--!nocheck
-- Plays a full season to a champion, headless. Run: `lune run tests/season.luau`

local Engine = require("../src/server/Sim/Engine")
local Generator = require("../src/server/Data/Generator")
local Teams = require("../src/shared/Data/Teams")
local Schedule = require("../src/server/League/Schedule")
local Standings = require("../src/server/League/Standings")
local SeasonController = require("../src/server/League/SeasonController")

local league = Generator.buildLeague(Teams, 2026)
local teamIds = {}
for id in league do
	table.insert(teamIds, id)
end
table.sort(teamIds)

local simFn = function(homeId, awayId, seed)
	return Engine.simulate(league[homeId], league[awayId], seed)
end

local schedule = Schedule.generate(teamIds)
print(string.format("Schedule: %d weeks x %d games", #schedule, #schedule[1]))

local season = SeasonController.new(teamIds, schedule)

local safety = 0
while season.phase ~= "offseason" and safety < 100 do
	safety += 1
	local out = SeasonController.advanceWeek(season, simFn, Standings.compute, 50000)
	local scoreline = ""
	for _, g in out.games do
		scoreline ..= string.format(
			"%s %d-%d %s  |  ",
			g.homeId,
			g.home.score,
			g.away.score,
			g.awayId
		)
	end
	print(string.format("[%s] %s", out.label, scoreline))
	if out.champion then
		print("\n*** CHAMPION: " .. out.champion .. " ***")
	end
end

print("\nFinal regular-season standings:")
local ranked = Standings.compute(teamIds, season.results)
for i, row in ranked do
	print(string.format("  %d. %s   %d-%d   (diff %+d)", i, row.teamId, row.w, row.l, row.diff))
end

assert(season.playoffs and season.playoffs.champion, "no champion crowned")
assert(season.phase == "offseason", "season did not reach offseason")
print("\nSeason completed cleanly. ✓")
