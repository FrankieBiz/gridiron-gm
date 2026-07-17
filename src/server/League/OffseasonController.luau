--!strict
-- The offseason: age & develop every roster, retire the old, run the draft, award coaching
-- credits, record the season in franchise history, then start next year's season.
-- Pure orchestration: all module dependencies are INJECTED via `deps` so this stays
-- Lune-testable and free of Roblox requires.

local OffseasonController = {}

local MAX_ROSTER = 30

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
function OffseasonController.finalize(f: any, deps: Deps, ctx: any, draftPicks: { any })
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

	f.season = deps.SeasonController.new(teamIds, deps.Schedule.generate(teamIds))
	f.season.year = ctx.year + 1

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

return OffseasonController
