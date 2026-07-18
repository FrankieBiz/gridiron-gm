--!strict
-- The ONLY place server state is normalized. GetState + GetSeason merge into one typed
-- FranchiseData table with or-defaults, so screens can assume every field is present.
-- Includes inDraft/freeAgents (the fields the old fetchAll dropped, which killed the
-- resume-into-draft and resume-into-free-agency paths).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Franchise = require(ReplicatedStorage.Shared.Types.Franchise)

export type FetchResult = {
	state: Franchise.FranchiseData?, -- nil when no franchise OR on failure
	hasFranchise: boolean,
	err: string?, -- non-nil only on remote failure
}

local Fetch = {}

-- Normalize a raw StatePayload-shaped table (from GetState / NewFranchise /
-- UpgradeFacility) plus an optional SeasonPayload into FranchiseData.
function Fetch.normalize(st: any, se: any?): Franchise.FranchiseData
	return {
		teamId = st.teamId,
		team = st.team,
		teams = st.teams or {},
		credits = st.coachingCredits or 0,
		record = st.record or { wins = 0, losses = 0, gamesPlayed = 0 },
		season = st.season,
		facilities = st.facilities or { training = 1, rehab = 1, stadium = 1 },
		coach = st.coach,
		prestige = st.prestige or 3,
		expectedWins = st.expectedWins or 8,
		pendingCareer = st.pendingCareer or false,
		news = st.news or {},
		history = st.history or {},
		achievements = st.achievements or {},
		achievementDefs = st.achievementDefs or {},
		dynastyScore = st.dynastyScore or 0,
		standings = (se and se.ok and se.standings) or {},
		schedule = (se and se.ok and se.schedule) or {},
		inDraft = st.inDraft == true,
		freeAgents = st.freeAgents or false,
	}
end

-- Yields (InvokeServer) — call from task.spawn only, never in render.
function Fetch.fetchAll(): FetchResult
	local ok, st = pcall(function()
		return Remotes.GetState:InvokeServer()
	end)
	if not ok or not (st and st.ok) then
		return { state = nil, hasFranchise = false, err = "GetState failed" }
	end
	if st.hasFranchise == false then
		-- Normal first run — not an error.
		return { state = nil, hasFranchise = false, err = nil }
	end

	-- Season fetch failure degrades to empty standings/schedule (screens tolerate it).
	local okSeason, se = pcall(function()
		return Remotes.GetSeason:InvokeServer()
	end)

	return {
		state = Fetch.normalize(st, if okSeason then se else nil),
		hasFranchise = true,
		err = nil,
	}
end

return Fetch
