--!strict
-- Service: advance the season. Owns SimGame (advance one week, return the player's game)
-- and GetSeason (schedule + standings for the dashboard). Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SaveService = require(script.Parent.SaveService)
local Engine = require(script.Parent.Parent.Sim.Engine)
local Standings = require(script.Parent.Parent.League.Standings)
local Schedule = require(script.Parent.Parent.League.Schedule)
local SeasonController = require(script.Parent.Parent.League.SeasonController)
local Development = require(script.Parent.Parent.League.Development)
local DraftClass = require(script.Parent.Parent.League.DraftClass)
local Draft = require(script.Parent.Parent.League.Draft)
local DraftBoard = require(script.Parent.Parent.League.DraftBoard)
local OffseasonController = require(script.Parent.Parent.League.OffseasonController)
local CareerController = require(script.Parent.Parent.League.CareerController)
local Awards = require(script.Parent.Parent.League.Awards)
local Stats = require(script.Parent.Parent.League.Stats)

local SeasonService = {}

local OFFSEASON_DEPS = {
	Development = Development,
	DraftClass = DraftClass,
	Draft = Draft,
	Standings = Standings,
	Schedule = Schedule,
	SeasonController = SeasonController,
}

local function makeSimFn(league: any)
	return function(homeId: string, awayId: string, seed: number)
		return Engine.simulate(league[homeId], league[awayId], seed)
	end
end

function SeasonService:Start()
	Remotes.SimGame.OnServerInvoke = function(player: Player)
		local profile = SaveService.get(player)
		if not profile or not profile.Data.franchise then
			return { ok = false, error = "no franchise" }
		end
		local f = profile.Data.franchise

		-- Season's over — the player must handle their career (stay / take a job) first.
		if f.season.phase == "offseason" then
			return {
				ok = false,
				error = "Season over — choose your next move.",
				careerReport = f.pendingCareer,
			}
		end

		local season = f.season
		local out =
			SeasonController.advanceWeek(season, makeSimFn(f.league), Standings.compute, f.seed)

		-- Surface the player's own game from this week's slate (fallback to the first game).
		local mine = out.games[1]
		for _, g in out.games do
			if g.homeId == f.teamId or g.awayId == f.teamId then
				mine = g
				break
			end
		end

		-- If that game just ended the season, grade the coach and generate job offers.
		local careerReport = nil
		if out.phase == "offseason" then
			local ranked = Standings.compute(season.teamIds, season.results)
			local rank = 99
			for i, row in ranked do
				if row.teamId == f.teamId then
					rank = i
					break
				end
			end
			local rec = Standings.recordFor(season.teamIds, season.results, f.teamId)
			local prestige = f.league[f.teamId].prestige or 3
			f.coach = f.coach or CareerController.newCoach(f.teamId)
			local report = CareerController.evaluate(
				f.coach,
				rec,
				out.champion == f.teamId,
				rank <= 4,
				prestige
			)
			local offers = CareerController.generateOffers(
				f.coach,
				f.league,
				f.teamId,
				report.fired,
				f.seed + season.year
			)
			-- League awards (MVP / POYs / ROY / All-League) from the finished season.
			local awards = Awards.compute(f.league, ranked, f.seed + season.year * 17, Stats)
			f.pendingCareer = { report = report, offers = offers, awards = awards }
			careerReport = f.pendingCareer
		end

		return {
			ok = true,
			result = mine,
			homeName = f.league[mine.homeId].name,
			awayName = f.league[mine.awayId].name,
			record = Standings.recordFor(season.teamIds, season.results, f.teamId),
			label = out.label,
			phase = out.phase,
			champion = out.champion,
			year = season.year,
			week = season.week,
			careerReport = careerReport, -- present only on the game that ends a season
		}
	end

	Remotes.GetSeason.OnServerInvoke = function(player: Player)
		local profile = SaveService.get(player)
		if not profile or not profile.Data.franchise then
			return { ok = false, error = "no franchise" }
		end
		local f = profile.Data.franchise
		local season = f.season
		return {
			ok = true,
			year = season.year,
			week = season.week,
			phase = season.phase,
			totalWeeks = #season.schedule,
			standings = Standings.compute(season.teamIds, season.results),
			schedule = season.schedule,
		}
	end

	-- Stay or accept a job offer, then run the offseason into next season.
	Remotes.ChooseJob.OnServerInvoke = function(player: Player, teamId: any)
		local profile = SaveService.get(player)
		if not profile or not profile.Data.franchise then
			return { ok = false, error = "no franchise" }
		end
		local f = profile.Data.franchise
		if f.season.phase ~= "offseason" or not f.pendingCareer then
			return { ok = false, error = "no career decision pending" }
		end

		-- Only the current team (stay) or one of the offered jobs is valid.
		local valid = teamId == f.teamId
		for _, offer in f.pendingCareer.offers do
			if offer.teamId == teamId then
				valid = true
				break
			end
		end
		if not valid then
			return { ok = false, error = "not an available job" }
		end

		-- Capture the season you just coached (before any team switch) for finalize/news.
		local oldTeamId = f.teamId
		local oldRec = Standings.recordFor(f.season.teamIds, f.season.results, oldTeamId)
		local champion = f.season.playoffs and f.season.playoffs.champion
		f.offseasonCtx = {
			year = f.season.year,
			oldTeamName = f.league[oldTeamId].name,
			recWins = oldRec.wins,
			recLosses = oldRec.losses,
			champion = champion,
			wonIt = champion == oldTeamId,
			prestigeBefore = f.league[oldTeamId].prestige or 3,
			madePlayoffs = f.pendingCareer.report.madePlayoffs,
			report = f.pendingCareer.report,
			awards = f.pendingCareer.awards,
		}

		-- Take the job (you'll draft for your NEW team).
		local switched = teamId ~= oldTeamId
		if switched then
			f.teamId = teamId
			f.coach.teamsCoached = f.coach.teamsCoached or {}
			table.insert(f.coach.teamsCoached, teamId)
			f.news = f.news or {}
			table.insert(f.news, 1, {
				kind = "career",
				text = string.format(
					"✍️ Signed on as the new head coach of the %s!",
					f.league[teamId].name
				),
			})
		end
		f.pendingCareer = false

		-- Age everyone, generate the class, and open the interactive draft.
		local prep = OffseasonController.preDraft(f, OFFSEASON_DEPS, f.seed)
		f.offseasonCtx.retirees = prep.retirees

		local rounds = Draft.ROUNDS
		local fullOrder = {}
		for _ = 1, rounds do
			for _, id in prep.order do
				table.insert(fullOrder, id)
			end
		end
		f.draft = DraftBoard.new(
			fullOrder,
			prep.class,
			f.teamId,
			10,
			f.seed + f.offseasonCtx.year,
			rounds
		)
		DraftBoard.runToHumanOrEnd(f.draft, f.league, Draft)

		return {
			ok = true,
			enteringDraft = true,
			switched = switched,
			draft = DraftBoard.view(f.draft, DraftClass),
		}
	end
end

return SeasonService
