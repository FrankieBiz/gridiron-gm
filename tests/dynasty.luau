--!nocheck
-- Plays 3 full seasons through the offseason loop (aging, retirement, draft), headless.
-- Run: `lune run tests/dynasty.luau`

local Engine = require("../src/server/Sim/Engine")
local Generator = require("../src/server/Data/Generator")
local Teams = require("../src/shared/Data/Teams")
local Schedule = require("../src/server/League/Schedule")
local Standings = require("../src/server/League/Standings")
local SeasonController = require("../src/server/League/SeasonController")
local Development = require("../src/server/League/Development")
local DraftClass = require("../src/server/League/DraftClass")
local Draft = require("../src/server/League/Draft")
local OffseasonController = require("../src/server/League/OffseasonController")
local CareerController = require("../src/server/League/CareerController")

local league = Generator.buildLeague(Teams, 2026)
local teamIds = {}
for id in league do
	table.insert(teamIds, id)
end
table.sort(teamIds)

local f = {
	teamId = teamIds[1],
	seed = 4242,
	league = league,
	coachingCredits = 0,
	season = SeasonController.new(teamIds, Schedule.generate(teamIds)),
}

local deps = {
	Development = Development,
	DraftClass = DraftClass,
	Draft = Draft,
	Standings = Standings,
	Schedule = Schedule,
	SeasonController = SeasonController,
}

local simFn = function(h, a, seed)
	return Engine.simulate(league[h], league[a], seed)
end

local function avgAge(roster)
	local sum = 0
	for _, p in roster do
		sum += p.age
	end
	return sum / #roster
end

local function bestOverall(roster)
	local best = 0
	for _, p in roster do
		best = math.max(best, p.overall)
	end
	return best
end

local myId = f.teamId
local coach = CareerController.newCoach(myId)
print(
	string.format(
		"Managing %s. Starting roster: %d players, avg age %.1f, best OVR %d\n",
		myId,
		#league[myId].roster,
		avgAge(league[myId].roster),
		bestOverall(league[myId].roster)
	)
)

for s = 1, 3 do
	while f.season.phase ~= "offseason" do
		SeasonController.advanceWeek(f.season, simFn, Standings.compute, f.seed)
	end
	local rec = Standings.recordFor(f.season.teamIds, f.season.results, myId)
	local champ = f.season.playoffs and f.season.playoffs.champion
	print(
		string.format(
			"Season %d: %s went %d-%d. Champion: %s",
			f.season.year,
			myId,
			rec.wins,
			rec.losses,
			tostring(champ)
		)
	)

	local ranked = Standings.compute(f.season.teamIds, f.season.results)
	local rank = 99
	for i, row in ranked do
		if row.teamId == myId then
			rank = i
			break
		end
	end
	local report =
		CareerController.evaluate(coach, rec, champ == myId, rank <= 4, league[myId].prestige or 3)
	local offers =
		CareerController.generateOffers(coach, league, myId, report.fired, f.seed + f.season.year)
	print(
		string.format(
			"  Career: rep %d, security %d, fired=%s, %d offers",
			math.floor(coach.reputation),
			math.floor(coach.jobSecurity),
			tostring(report.fired),
			#offers
		)
	)

	local summary = OffseasonController.run(f, deps, f.seed)
	print(
		string.format(
			"  Offseason: %d retired, %d rookies drafted, +%d credits (total %d)",
			#summary.retirees,
			#summary.rookies,
			summary.creditsEarned,
			summary.totalCredits
		)
	)
	print(
		string.format(
			"  %s now: %d players, avg age %.1f, best OVR %d\n",
			myId,
			#league[myId].roster,
			avgAge(league[myId].roster),
			bestOverall(league[myId].roster)
		)
	)
end

assert(f.season.year == 4, "should be entering year 4")
assert(#league[myId].roster >= 15, "roster should not have collapsed")
assert(#f.history.seasons == 3, "history should record 3 seasons")
assert(coach.seasonsCoached == 3, "coach should have 3 seasons")
print(
	string.format(
		"Career: %d-%d, %d titles, rep %d. Dynasty + career ran cleanly. ✓",
		coach.careerWins,
		coach.careerLosses,
		coach.championships,
		math.floor(coach.reputation)
	)
)
