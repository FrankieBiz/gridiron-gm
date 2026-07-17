--!strict
-- Service: the interactive draft. Owns GetDraft / ScoutProspect / MakePick remotes and
-- finishes the offseason (finalize + achievements + news) when the draft completes.
-- The draft state lives on f.draft (a DraftBoard state table, fully saveable).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SaveService = require(script.Parent.SaveService)
local Draft = require(script.Parent.Parent.League.Draft)
local DraftBoard = require(script.Parent.Parent.League.DraftBoard)
local DraftClass = require(script.Parent.Parent.League.DraftClass)
local OffseasonController = require(script.Parent.Parent.League.OffseasonController)
local Achievements = require(script.Parent.Parent.League.Achievements)
local News = require(script.Parent.Parent.League.News)
local Development = require(script.Parent.Parent.League.Development)
local Schedule = require(script.Parent.Parent.League.Schedule)
local Standings = require(script.Parent.Parent.League.Standings)
local SeasonController = require(script.Parent.Parent.League.SeasonController)

local OFFSEASON_DEPS = {
	Development = Development,
	DraftClass = DraftClass,
	Draft = Draft,
	Standings = Standings,
	Schedule = Schedule,
	SeasonController = SeasonController,
}

local DraftService = {}

-- Wrap up the offseason once the draft ends: finalize rosters/credits/history/next season,
-- check achievements, and build the news feed. Returns the offseason summary.
local function completeDraft(f: any)
	local ctx = f.offseasonCtx
	local summary = OffseasonController.finalize(f, OFFSEASON_DEPS, ctx, f.draft.picks)

	f.achievements = f.achievements or {}
	local seasons = f.history.seasons
	local lastSeason = seasons[#seasons] or { wins = 0, losses = 0, wonIt = false }
	local achResult = Achievements.check(f.achievements, {
		coach = f.coach,
		history = seasons,
		lastSeason = lastSeason,
		madePlayoffs = ctx.madePlayoffs,
		prestige = ctx.prestigeBefore,
	})
	f.dynastyScore = achResult.dynastyScore

	f.news = f.news or {}
	local fresh = News.fromOffseason(summary, ctx.report, ctx.oldTeamName)
	if ctx.awards then
		for _, a in ctx.awards.majors do
			table.insert(fresh, {
				kind = "award",
				text = string.format(
					"🏅 %s: %s %s (%s) — %s",
					a.title,
					a.position,
					a.name,
					a.teamName,
					a.stat
				),
			})
		end
	end
	for _, def in achResult.newlyUnlocked do
		table.insert(fresh, {
			kind = "title",
			text = string.format("⭐ ACHIEVEMENT: %s — %s", def.name, def.desc),
		})
	end
	for i = #fresh, 1, -1 do
		table.insert(f.news, 1, fresh[i])
	end
	while #f.news > 60 do
		table.remove(f.news)
	end

	f.draft = nil
	f.offseasonCtx = nil
	return summary
end

local function franchiseWithDraft(player: Player): any?
	local profile = SaveService.get(player)
	if not profile or not profile.Data.franchise then
		return nil
	end
	local f = profile.Data.franchise
	if not f.draft then
		return nil
	end
	return f
end

function DraftService:Start()
	Remotes.GetDraft.OnServerInvoke = function(player: Player)
		local f = franchiseWithDraft(player)
		if not f then
			return { ok = false, error = "no draft" }
		end
		return { ok = true, draft = DraftBoard.view(f.draft, DraftClass) }
	end

	Remotes.ScoutProspect.OnServerInvoke = function(player: Player, prospectId: any)
		local f = franchiseWithDraft(player)
		if not f then
			return { ok = false, error = "no draft" }
		end
		if type(prospectId) == "string" then
			DraftBoard.scout(f.draft, prospectId, DraftClass)
		end
		return { ok = true, draft = DraftBoard.view(f.draft, DraftClass) }
	end

	Remotes.MakePick.OnServerInvoke = function(player: Player, prospectId: any)
		local f = franchiseWithDraft(player)
		if not f then
			return { ok = false, error = "no draft" }
		end
		-- Make sure it's actually the player's turn (resolve any pending AI picks first).
		DraftBoard.runToHumanOrEnd(f.draft, f.league, Draft)
		if
			type(prospectId) ~= "string"
			or not DraftBoard.humanPick(f.draft, prospectId, f.league, Draft)
		then
			return {
				ok = false,
				error = "invalid pick",
				draft = DraftBoard.view(f.draft, DraftClass),
			}
		end
		DraftBoard.runToHumanOrEnd(f.draft, f.league, Draft)

		if DraftBoard.done(f.draft) then
			local summary = completeDraft(f)
			return { ok = true, done = true, offseason = summary }
		end
		return { ok = true, done = false, draft = DraftBoard.view(f.draft, DraftClass) }
	end
end

return DraftService
