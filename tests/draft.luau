--!nocheck
-- Exercises the interactive draft state machine headlessly. Run: `lune run tests/draft.luau`

local Generator = require("../src/server/Data/Generator")
local Teams = require("../src/shared/Data/Teams")
local DraftClass = require("../src/server/League/DraftClass")
local Draft = require("../src/server/League/Draft")
local DraftBoard = require("../src/server/League/DraftBoard")

local league = Generator.buildLeague(Teams, 999)
local teamIds = {}
for id in league do
	table.insert(teamIds, id)
end
table.sort(teamIds)

local myTeamId = teamIds[1]
local rounds = 3

-- Draft order: worst-first each round (just use teamIds order for the test).
local order = {}
for _ = 1, rounds do
	for _, id in teamIds do
		table.insert(order, id)
	end
end

local prospects = DraftClass.generate(1, #teamIds * rounds + 12, 4242)
local rosterBefore = #league[myTeamId].roster

local state = DraftBoard.new(order, prospects, myTeamId, 8, 4242, rounds)

-- Fog-of-war: scout the top prospect a few times and watch the range tighten.
local before = DraftClass.scoutedView(state.remaining[1])
DraftBoard.scout(state, state.remaining[1].id, DraftClass)
DraftBoard.scout(state, state.remaining[1].id, DraftClass)
local after = DraftClass.scoutedView(state.remaining[1])
print(
	string.format(
		"Scouting: OVR range %d-%d -> %d-%d (points left %d)",
		before.ovrMin,
		before.ovrMax,
		after.ovrMin,
		after.ovrMax,
		state.scoutPoints
	)
)
assert(
	(after.ovrMax - after.ovrMin) <= (before.ovrMax - before.ovrMin),
	"scouting should narrow the range"
)

-- Play the draft: AI picks up to me, I take the best-looking available each time.
local myPicks = 0
while not DraftBoard.done(state) do
	DraftBoard.runToHumanOrEnd(state, league, Draft)
	if DraftBoard.done(state) then
		break
	end
	assert(DraftBoard.isMyPick(state), "should be my pick after runToHumanOrEnd")
	local view = DraftBoard.view(state, DraftClass)
	local pickId = view.prospects[1].id -- take the highest-rated available
	local ok = DraftBoard.humanPick(state, pickId, league, Draft)
	assert(ok, "human pick should succeed")
	myPicks += 1
end

print(string.format("Draft complete: %d total picks, I made %d picks", #state.picks, myPicks))
print(string.format("My roster: %d -> %d players", rosterBefore, #league[myTeamId].roster))
for _, pk in state.picks do
	if pk.mine then
		print(
			string.format(
				"  R%d: %s %s (%d OVR, ceiling %d, %s)",
				pk.round,
				pk.position,
				pk.name,
				pk.overall,
				pk.potential,
				pk.devTrait
			)
		)
	end
end

assert(myPicks == rounds, "should make one pick per round")
assert(#league[myTeamId].roster == rosterBefore + rounds, "roster should grow by my picks")
print("\nInteractive draft board ran cleanly. ✓")
