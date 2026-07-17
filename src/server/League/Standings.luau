--!strict
-- Standings from a list of game results. Pure Luau — Lune-testable.
-- Sort: wins desc, then point differential desc, then points-for desc.

export type Row = { teamId: string, w: number, l: number, pf: number, pa: number, diff: number }

type GameResult = {
	homeId: string,
	awayId: string,
	winnerId: string,
	home: { score: number },
	away: { score: number },
}

local Standings = {}

function Standings.compute(teamIds: { string }, results: { GameResult }): { Row }
	local rec: { [string]: Row } = {}
	for _, id in teamIds do
		rec[id] = { teamId = id, w = 0, l = 0, pf = 0, pa = 0, diff = 0 }
	end

	for _, r in results do
		local h = rec[r.homeId]
		local a = rec[r.awayId]
		if h and a then
			h.pf += r.home.score
			h.pa += r.away.score
			a.pf += r.away.score
			a.pa += r.home.score
			if r.winnerId == r.homeId then
				h.w += 1
				a.l += 1
			else
				a.w += 1
				h.l += 1
			end
		end
	end

	local arr: { Row } = {}
	for _, row in rec do
		row.diff = row.pf - row.pa
		table.insert(arr, row)
	end
	table.sort(arr, function(x, y)
		if x.w ~= y.w then
			return x.w > y.w
		end
		if x.diff ~= y.diff then
			return x.diff > y.diff
		end
		return x.pf > y.pf
	end)
	return arr
end

-- Convenience: one team's W-L record derived from the same results.
function Standings.recordFor(teamIds: { string }, results: { GameResult }, teamId: string)
	for _, row in Standings.compute(teamIds, results) do
		if row.teamId == teamId then
			return { wins = row.w, losses = row.l, gamesPlayed = row.w + row.l }
		end
	end
	return { wins = 0, losses = 0, gamesPlayed = 0 }
end

return Standings
