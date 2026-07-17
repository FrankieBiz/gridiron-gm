--!strict
-- Template-driven news feed: turns offseason/career events into headlines that name YOUR
-- players and teams. Cheap, endlessly varied, and it makes every system feel authored.
-- Pure Luau -> Lune-testable.

local News = {}

-- Build a fresh feed of headlines from an offseason summary + career report.
-- summary: from OffseasonController.run ; report: from CareerController.evaluate (optional)
function News.fromOffseason(
	summary: any,
	report: any?,
	teamName: string
): { { text: string, kind: string } }
	local items: { { text: string, kind: string } } = {}
	local function add(kind: string, text: string)
		table.insert(items, { kind = kind, text = text })
	end

	if summary.champion then
		if report and report.champion then
			add(
				"title",
				string.format(
					"🏆 %s WIN THE CHAMPIONSHIP! A season for the history books.",
					string.upper(teamName)
				)
			)
		else
			add("league", string.format("%s are crowned league champions.", summary.champion))
		end
	end

	if report then
		if report.fired then
			add(
				"career",
				"📰 Ownership has parted ways with the head coach after a disappointing season."
			)
		elseif report.champion then
			add("career", "Your stock is soaring — rival owners are taking notice.")
		elseif report.met then
			add(
				"career",
				string.format(
					"The front office is pleased: %d wins met expectations.",
					report.actualWins
				)
			)
		else
			add(
				"career",
				string.format(
					"Pressure builds — %d wins fell short of the owner's target of %d.",
					report.actualWins,
					report.expectedWins
				)
			)
		end
	end

	for _, p in summary.retirees do
		add(
			"retire",
			string.format(
				"👋 %s %s retires at age %d after a %d-OVR career.",
				p.position,
				p.name,
				p.age,
				p.overall
			)
		)
	end

	-- Highlight the most promising rookie.
	local best = nil
	for _, d in summary.rookies do
		if not best or d.potential > best.potential then
			best = d
		end
	end
	if best then
		local hype = if best.devTrait == "superstar"
			then "scouts are calling him a generational talent"
			elseif best.devTrait == "star" then "a potential franchise cornerstone"
			else "a solid building block"
		add(
			"draft",
			string.format(
				"🎯 Drafted %s %s (%d OVR, ceiling %d) — %s.",
				best.position,
				best.name,
				best.overall,
				best.potential,
				hype
			)
		)
	end

	add(
		"credits",
		string.format(
			"🪙 Earned %d coaching credits this offseason (bank: %d).",
			summary.creditsEarned,
			summary.totalCredits
		)
	)

	return items
end

-- One or two headlines from a week of games: your result + the biggest blowout.
-- games: the week's full GameResults. league: id -> team. myTeamId, label (e.g. "Week 4").
function News.weekly(
	games: { any },
	league: any,
	myTeamId: string,
	label: string
): { { text: string, kind: string } }
	local items: { { text: string, kind: string } } = {}
	local function nameOf(id: string): string
		return league[id] and league[id].name or id
	end

	for _, g in games do
		if g.homeId == myTeamId or g.awayId == myTeamId then
			local iWon = g.winnerId == myTeamId
			local myScore = if g.homeId == myTeamId then g.home.score else g.away.score
			local oppScore = if g.homeId == myTeamId then g.away.score else g.home.score
			local oppId = if g.homeId == myTeamId then g.awayId else g.homeId
			table.insert(items, {
				kind = if iWon then "award" else "retire",
				text = string.format(
					"%s: %s %s %d-%d vs %s",
					label,
					nameOf(myTeamId),
					if iWon then "beat" else "lost to",
					myScore,
					oppScore,
					nameOf(oppId)
				),
			})
			break
		end
	end

	local best, bestMargin = nil, -1
	for _, g in games do
		local margin = math.abs(g.home.score - g.away.score)
		if margin > bestMargin then
			bestMargin = margin
			best = g
		end
	end
	if best and bestMargin >= 21 then
		local loserId = if best.winnerId == best.homeId then best.awayId else best.homeId
		table.insert(items, {
			kind = "league",
			text = string.format(
				"Around the league: %s routed %s by %d.",
				nameOf(best.winnerId),
				nameOf(loserId),
				bestMargin
			),
		})
	end

	return items
end

return News
