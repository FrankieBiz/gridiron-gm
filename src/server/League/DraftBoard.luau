--!strict
-- Interactive draft state machine. Pure Luau (Draft + DraftClass injected) so it's
-- Lune-testable and saveable (state is a plain table — no functions stored).
-- Human and AI share Draft.bestIndex/toPlayer. Deterministic via state.seed + cursor.

local DraftBoard = {}

-- order: flattened pick order across all rounds (worst-first each round).
-- prospects: DraftClass.generate output (hidden truth + scouted view).
function DraftBoard.new(
	order: { string },
	prospects: { any },
	myTeamId: string,
	scoutPoints: number,
	seed: number,
	rounds: number
)
	return {
		order = order,
		cursor = 1,
		rounds = rounds,
		scoutPoints = scoutPoints,
		myTeamId = myTeamId,
		remaining = prospects,
		picks = {},
		seedBase = seed,
	}
end

function DraftBoard.done(state: any): boolean
	return state.cursor > #state.order or #state.remaining == 0
end

function DraftBoard.onClock(state: any): string?
	if DraftBoard.done(state) then
		return nil
	end
	return state.order[state.cursor]
end

function DraftBoard.isMyPick(state: any): boolean
	return DraftBoard.onClock(state) == state.myTeamId
end

local function findProspect(state: any, prospectId: string): (number?, any?)
	for i, p in state.remaining do
		if p.id == prospectId then
			return i, p
		end
	end
	return nil, nil
end

-- Spend a scouting point to narrow a prospect's fog-of-war ranges. Allowed anytime.
function DraftBoard.scout(state: any, prospectId: string, DraftClass: any): boolean
	if (state.scoutPoints or 0) <= 0 then
		return false
	end
	local _, prospect = findProspect(state, prospectId)
	if not prospect then
		return false
	end
	DraftClass.scout(prospect)
	state.scoutPoints -= 1
	return true
end

local function recordAndApply(state: any, idx: number, teamId: string, league: any, Draft: any)
	local prospect = table.remove(state.remaining, idx)
	local picksPerRound = #state.order / state.rounds
	local round = math.floor((state.cursor - 1) / picksPerRound) + 1
	local player = Draft.toPlayer(prospect, teamId, (state.seedBase or 0) + state.cursor * 7)
	table.insert(league[teamId].roster, player)
	table.insert(state.picks, {
		teamId = teamId,
		round = round,
		name = player.name,
		position = player.position,
		overall = player.overall,
		potential = player.potential,
		devTrait = player.devTrait,
		mine = teamId == state.myTeamId,
	})
	state.cursor += 1
end

-- The team on the clock (must be AI) makes its pick.
function DraftBoard.aiPick(state: any, league: any, Draft: any): boolean
	local teamId = DraftBoard.onClock(state)
	if not teamId or teamId == state.myTeamId then
		return false
	end
	local idx =
		Draft.bestIndex(league[teamId], state.remaining, (state.seedBase or 0) + state.cursor)
	recordAndApply(state, idx, teamId, league, Draft)
	return true
end

-- The human picks a specific prospect (only valid when it's their turn).
function DraftBoard.humanPick(state: any, prospectId: string, league: any, Draft: any): boolean
	if not DraftBoard.isMyPick(state) then
		return false
	end
	local idx = findProspect(state, prospectId)
	if not idx then
		return false
	end
	recordAndApply(state, idx, state.myTeamId, league, Draft)
	return true
end

-- Resolve AI picks until it's the human's turn or the draft ends.
function DraftBoard.runToHumanOrEnd(state: any, league: any, Draft: any)
	while not DraftBoard.done(state) and not DraftBoard.isMyPick(state) do
		DraftBoard.aiPick(state, league, Draft)
	end
end

-- Client-safe view: never sends hidden true ratings, only scouted ranges.
function DraftBoard.view(state: any, DraftClass: any)
	local board = {}
	for _, p in state.remaining do
		table.insert(board, DraftClass.scoutedView(p))
	end
	table.sort(board, function(a, b)
		return (a.ovrMax + a.ovrMin) > (b.ovrMax + b.ovrMin)
	end)
	local myPicks = {}
	for _, pk in state.picks do
		if pk.mine then
			table.insert(myPicks, pk)
		end
	end
	return {
		onClock = DraftBoard.onClock(state),
		isMyPick = DraftBoard.isMyPick(state),
		done = DraftBoard.done(state),
		scoutPoints = state.scoutPoints,
		pickNumber = state.cursor,
		totalPicks = #state.order,
		prospects = board,
		myPicks = myPicks,
	}
end

return DraftBoard
