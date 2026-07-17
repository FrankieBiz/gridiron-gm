--!strict
-- The offseason: age & develop every roster, retire the old, run the draft, award coaching
-- credits, record the season in franchise history, then start next year's season.
-- Pure orchestration: all module dependencies are INJECTED via `deps` so this stays
-- Lune-testable and free of Roblox requires.

local OffseasonController = {}

local MAX_ROSTER = 30

local FA_FIRST =
	{ "Wes", "Darnell", "Kai", "Rocco", "Levi", "Theo", "Zane", "Omar", "Silas", "Jude" }
local FA_LAST =
	{ "Vega", "Holt", "Ibarra", "Pace", "Nawrocki", "Ruiz", "Fenwick", "Ade", "Larsson", "Cross" }
local FA_POS = { "QB", "RB", "WR", "WR", "TE", "OL", "DL", "LB", "DB" }

local function makeRng(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(min: number, max: number): number
		state = (state * 16807) % 2147483647
		return math.floor(((state - 1) / 2147483646) * (max - min + 1)) + min
	end
end

-- A pool of signable veteran free agents with KNOWN ratings (no fog) and a credit cost.
local function buildFreeAgents(seed: number, count: number): { any }
	local rand = makeRng(seed)
	local pool: { any } = {}
	for i = 1, count do
		local overall = rand(66, 86)
		local age = rand(26, 33)
		pool[i] = {
			id = "FA-" .. seed .. "-" .. i,
			name = FA_FIRST[rand(1, #FA_FIRST)] .. " " .. FA_LAST[rand(1, #FA_LAST)],
			position = FA_POS[rand(1, #FA_POS)],
			age = age,
			overall = overall,
			speed = math.clamp(overall + rand(-6, 6), 40, 99),
			strength = math.clamp(overall + rand(-6, 6), 40, 99),
			awareness = math.clamp(overall + rand(-6, 6), 40, 99),
			potential = overall + rand(0, 3),
			contractYears = rand(1, 3),
			salary = overall * overall,
			morale = rand(60, 88),
			devTrait = "normal",
			cost = math.max(2, math.floor((overall - 58) / 2)), -- 66->4 .. 86->14 credits
		}
	end
	table.sort(pool, function(a, b)
		return a.overall > b.overall
	end)
	return pool
end

OffseasonController.buildFreeAgents = buildFreeAgents

export type Deps = {
	Development: any,
	DraftClass: any,
	Draft: any,
	Standings: any,
	Schedule: any,
	SeasonController: any,
}

-- Mutates franchise `f` in place; returns a summary for news/UI.
function OffseasonController.run(f: any, deps: Deps, baseSeed: number)
	local season = f.season
	local year = season.year
	local teamIds = season.teamIds

	-- Draft order = reverse of final standings (worst team picks first).
	local ranked = deps.Standings.compute(teamIds, season.results)
	local order: { string } = {}
	for i = #ranked, 1, -1 do
		table.insert(order, ranked[i].teamId)
	end

	-- Age & develop every roster; the player's facilities boost their own team's growth.
	local facilities = f.facilities or { training = 1, rehab = 1, stadium = 1 }
	local myRetirees: { any } = {}
	for _, teamId in teamIds do
		local team = f.league[teamId]
		local opts = if teamId == f.teamId
			then { trainingLevel = facilities.training, rehabLevel = facilities.rehab }
			else nil
		local res =
			deps.Development.ageAndDevelop(team.roster, baseSeed + year * 13 + #team.roster, opts)
		team.roster = res.roster
		if teamId == f.teamId then
			myRetirees = res.retirees
		end
	end

	-- Generate and run the draft (adds rookies to rosters).
	local class = deps.DraftClass.generate(year, #teamIds * 3 + 10, baseSeed + year * 77)
	local draftResults = deps.Draft.run(f.league, order, class, baseSeed + year * 131)

	-- Keep rosters bounded (trim the weakest).
	for _, teamId in teamIds do
		local team = f.league[teamId]
		if #team.roster > MAX_ROSTER then
			table.sort(team.roster, function(a, b)
				return a.overall > b.overall
			end)
			while #team.roster > MAX_ROSTER do
				table.remove(team.roster)
			end
		end
	end

	-- Coaching credits: base + a credit per win + championship bonus.
	local rec = deps.Standings.recordFor(teamIds, season.results, f.teamId)
	local champion = season.playoffs and season.playoffs.champion
	local stadiumBonus = (facilities.stadium - 1) * 2 -- bigger stadium -> more credits
	local creditsEarned = 10 + rec.wins + (if champion == f.teamId then 25 else 0) + stadiumBonus
	f.coachingCredits = (f.coachingCredits or 0) + creditsEarned

	-- Franchise history (append-only — feeds records / Hall of Fame later).
	f.history = f.history or { seasons = {} }
	table.insert(f.history.seasons, {
		year = year,
		wins = rec.wins,
		losses = rec.losses,
		champion = champion,
		wonIt = champion == f.teamId,
	})

	-- The player's own rookies (for the news feed).
	local myRookies: { any } = {}
	for _, d in draftResults do
		if d.teamId == f.teamId then
			table.insert(myRookies, d)
		end
	end

	-- Roll into next season.
	f.season = deps.SeasonController.new(teamIds, deps.Schedule.generate(teamIds))
	f.season.year = year + 1

	return {
		year = year,
		nextYear = year + 1,
		champion = champion,
		retirees = myRetirees,
		rookies = myRookies,
		creditsEarned = creditsEarned,
		totalCredits = f.coachingCredits,
	}
end

-- ---- Interactive-draft split (used by DraftService; `run` above stays for AI/tests) ----

-- Age & develop every roster and build the draft class + order. Does NOT draft.
-- Returns { class, order, retirees } (retirees are for f.teamId, i.e. the team you'll manage).
function OffseasonController.preDraft(f: any, deps: Deps, baseSeed: number)
	local season = f.season
	local year = season.year
	local teamIds = season.teamIds

	local ranked = deps.Standings.compute(teamIds, season.results)
	local order: { string } = {}
	for i = #ranked, 1, -1 do
		table.insert(order, ranked[i].teamId)
	end

	local facilities = f.facilities or { training = 1, rehab = 1, stadium = 1 }
	local myRetirees: { any } = {}
	for _, teamId in teamIds do
		local team = f.league[teamId]
		local opts = if teamId == f.teamId
			then { trainingLevel = facilities.training, rehabLevel = facilities.rehab }
			else nil
		local res =
			deps.Development.ageAndDevelop(team.roster, baseSeed + year * 13 + #team.roster, opts)
		team.roster = res.roster
		if teamId == f.teamId then
			myRetirees = res.retirees
		end
	end

	local class = deps.DraftClass.generate(year, #teamIds * 3 + 12, baseSeed + year * 77)
	return { class = class, order = order, retirees = myRetirees }
end

-- After the (interactive) draft: trim rosters, award credits, record history, roll next
-- season. `ctx` describes the season you just coached (captured before any team switch):
-- { year, champion, recWins, recLosses, wonIt, retirees }. `draftPicks` = DraftBoard.picks.
function OffseasonController.finalize(f: any, _deps: Deps, ctx: any, draftPicks: { any })
	local teamIds = f.season.teamIds

	for _, teamId in teamIds do
		local team = f.league[teamId]
		if #team.roster > MAX_ROSTER then
			table.sort(team.roster, function(a, b)
				return a.overall > b.overall
			end)
			while #team.roster > MAX_ROSTER do
				table.remove(team.roster)
			end
		end
	end

	local facilities = f.facilities or { training = 1, rehab = 1, stadium = 1 }
	local stadiumBonus = (facilities.stadium - 1) * 2
	local creditsEarned = 10 + ctx.recWins + (if ctx.wonIt then 25 else 0) + stadiumBonus
	f.coachingCredits = (f.coachingCredits or 0) + creditsEarned

	f.history = f.history or { seasons = {} }
	table.insert(f.history.seasons, {
		year = ctx.year,
		wins = ctx.recWins,
		losses = ctx.recLosses,
		champion = ctx.champion,
		wonIt = ctx.wonIt,
	})

	local myRookies: { any } = {}
	for _, d in draftPicks do
		if d.teamId == f.teamId then
			table.insert(myRookies, d)
		end
	end

	-- Open free agency (does NOT roll the season — startNextSeason does that after signing).
	f.freeAgents = buildFreeAgents(ctx.year * 733 + (f.seed or 0), 10)

	return {
		year = ctx.year,
		nextYear = ctx.year + 1,
		champion = ctx.champion,
		retirees = ctx.retirees,
		rookies = myRookies,
		creditsEarned = creditsEarned,
		totalCredits = f.coachingCredits,
	}
end

-- Sign a free agent by id (spends coaching credits). Returns true on success.
function OffseasonController.signFreeAgent(f: any, faId: string): boolean
	if not f.freeAgents then
		return false
	end
	for i, fa in f.freeAgents do
		if fa.id == faId then
			if (f.coachingCredits or 0) < fa.cost then
				return false
			end
			if #f.league[f.teamId].roster >= MAX_ROSTER + 6 then
				return false
			end
			f.coachingCredits -= fa.cost
			local player = table.clone(fa)
			player.cost = nil
			player.id = f.teamId .. "-" .. fa.id
			table.insert(f.league[f.teamId].roster, player)
			table.remove(f.freeAgents, i)
			return true
		end
	end
	return false
end

-- Close free agency and roll into next season.
function OffseasonController.startNextSeason(f: any, deps: Deps)
	local teamIds = f.season.teamIds
	local year = f.season.year
	f.season = deps.SeasonController.new(teamIds, deps.Schedule.generate(teamIds))
	f.season.year = year + 1
	f.freeAgents = nil
	f.offseasonCtx = nil
end

return OffseasonController
