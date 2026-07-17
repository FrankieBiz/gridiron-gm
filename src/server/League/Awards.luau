--!strict
-- End-of-season awards computed across the whole league: MVP, Offensive/Defensive Player of
-- the Year, Rookie of the Year, and an All-League team (best at each position).
-- Pure Luau -> Lune-testable. Consumes final standings for team win totals.

local Awards = {}

local ALL_LEAGUE_POS = { "QB", "RB", "WR", "TE", "OL", "DL", "LB", "DB" }

-- `Stats` is injected so this module stays pure (Lune-testable + no script.Parent require).
-- league: { [teamId] = team }, standings: sorted rows from Standings.compute, seed
function Awards.compute(league: any, standings: { any }, seed: number, Stats: any)
	local winsById: { [string]: number } = {}
	for _, row in standings do
		winsById[row.teamId] = row.w
	end

	-- Build a scored candidate list for every player in the league.
	type Cand = { player: any, teamId: string, line: any, impact: number }
	local cands: { Cand } = {}
	for teamId, team in league do
		local wins = winsById[teamId] or 7
		for _, p in team.roster do
			local line = Stats.line(p, wins, seed + string.len(p.id) + p.overall)
			table.insert(cands, {
				player = p,
				teamId = teamId,
				line = line,
				impact = Stats.impact(p, line, wins),
			})
		end
	end
	table.sort(cands, function(a, b)
		return a.impact > b.impact
	end)

	local function toAward(c: Cand, title: string)
		return {
			title = title,
			name = c.player.name,
			position = c.player.position,
			teamId = c.teamId,
			teamName = league[c.teamId].name,
			overall = c.player.overall,
			stat = Stats.summary(c.player, c.line),
		}
	end

	local mvp, opoy, dpoy, roy
	for _, c in cands do
		if not mvp then
			mvp = toAward(c, "MVP")
		end
		if not opoy and Stats.isOffense[c.player.position] then
			opoy = toAward(c, "Offensive POY")
		end
		if not dpoy and Stats.isDefense[c.player.position] then
			dpoy = toAward(c, "Defensive POY")
		end
		if not roy and c.player.age <= 22 then
			roy = toAward(c, "Rookie of the Year")
		end
	end

	-- All-League: highest-impact player at each position.
	local allLeague = {}
	for _, pos in ALL_LEAGUE_POS do
		for _, c in cands do
			if c.player.position == pos then
				table.insert(allLeague, toAward(c, pos))
				break
			end
		end
	end

	local majors = {}
	for _, a in { mvp, opoy, dpoy, roy } do
		if a then
			table.insert(majors, a)
		end
	end

	return { majors = majors, allLeague = allLeague }
end

return Awards
