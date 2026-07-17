--!strict
-- Milestone achievements + a cumulative dynasty score. Long-term goals that always sit in
-- front of the player. Pure Luau -> Lune-testable. Checked once per season end.

local Achievements = {}

-- Every achievement: id, name, description, and a predicate over the career context.
-- ctx = { coach, history (seasons), lastSeason = {wins,losses,champion,wonIt}, prestige }
local DEFS = {
	{
		id = "first_win",
		name = "On the Board",
		desc = "Win your first game",
		points = 5,
		test = function(ctx)
			return ctx.coach.careerWins >= 1
		end,
	},
	{
		id = "playoffs",
		name = "January Football",
		desc = "Make the playoffs",
		points = 10,
		test = function(ctx)
			return ctx.madePlayoffs
		end,
	},
	{
		id = "first_title",
		name = "Champion",
		desc = "Win a championship",
		points = 25,
		test = function(ctx)
			return ctx.coach.championships >= 1
		end,
	},
	{
		id = "back_to_back",
		name = "Dynasty Begins",
		desc = "Win two titles in a row",
		points = 40,
		test = function(ctx)
			local h = ctx.history
			return #h >= 2 and h[#h].wonIt and h[#h - 1].wonIt
		end,
	},
	{
		id = "perfect",
		name = "Perfect Season",
		desc = "Go undefeated in the regular season",
		points = 50,
		test = function(ctx)
			return ctx.lastSeason.losses == 0 and ctx.lastSeason.wins >= 10
		end,
	},
	{
		id = "ten_wins",
		name = "Contender",
		desc = "Win 10+ games in a season",
		points = 15,
		test = function(ctx)
			return ctx.lastSeason.wins >= 10
		end,
	},
	{
		id = "vet",
		name = "Grizzled Vet",
		desc = "Coach 5 seasons",
		points = 15,
		test = function(ctx)
			return ctx.coach.seasonsCoached >= 5
		end,
	},
	{
		id = "legend",
		name = "Living Legend",
		desc = "Coach 15 seasons",
		points = 30,
		test = function(ctx)
			return ctx.coach.seasonsCoached >= 15
		end,
	},
	{
		id = "century",
		name = "Centurion",
		desc = "Reach 100 career wins",
		points = 30,
		test = function(ctx)
			return ctx.coach.careerWins >= 100
		end,
	},
	{
		id = "journeyman",
		name = "Journeyman",
		desc = "Coach 3 different teams",
		points = 20,
		test = function(ctx)
			return ctx.coach.teamsCoached and #ctx.coach.teamsCoached >= 3
		end,
	},
	{
		id = "three_peat",
		name = "Three-Peat",
		desc = "Win three titles in a row",
		points = 75,
		test = function(ctx)
			local h = ctx.history
			return #h >= 3 and h[#h].wonIt and h[#h - 1].wonIt and h[#h - 2].wonIt
		end,
	},
	{
		id = "blue_blood",
		name = "Blue Blood",
		desc = "Coach a 5-star prestige team",
		points = 20,
		test = function(ctx)
			return ctx.prestige >= 5
		end,
	},
}

Achievements.defs = DEFS

-- Returns { unlocked = { ids }, newlyUnlocked = { defs }, dynastyScore } given prior `owned`
-- (a set of ids already earned) and the season context.
function Achievements.check(owned: { [string]: boolean }, ctx: any)
	local newly = {}
	for _, def in DEFS do
		if not owned[def.id] and def.test(ctx) then
			owned[def.id] = true
			table.insert(newly, def)
		end
	end

	-- Dynasty score = achievement points + career signal (wins, titles, reputation).
	local pts = 0
	for _, def in DEFS do
		if owned[def.id] then
			pts += def.points
		end
	end
	local score = pts
		+ (ctx.coach.careerWins or 0)
		+ (ctx.coach.championships or 0) * 30
		+ math.floor((ctx.coach.reputation or 0) / 2)

	return { owned = owned, newlyUnlocked = newly, dynastyScore = score }
end

return Achievements
