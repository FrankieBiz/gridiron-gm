--!strict
-- Round-robin schedule generation (circle method). Pure Luau — Lune-testable.
-- Produces a double round-robin: every team plays every other twice (home + away).

export type Game = { home: string, away: string }
export type Week = { Game }

local Schedule = {}

-- teamIds must be an even count. For 8 teams -> 14 weeks of 4 games each.
function Schedule.generate(teamIds: { string }): { Week }
	local arr = table.clone(teamIds)
	local n = #arr
	assert(n % 2 == 0 and n >= 2, "Schedule needs an even team count")
	local rounds = n - 1
	local half = n // 2

	local firstHalf: { Week } = {}
	for r = 1, rounds do
		local week: Week = {}
		for i = 1, half do
			local a = arr[i]
			local b = arr[n - i + 1]
			-- Alternate home/away each round so nobody is always home.
			if r % 2 == 0 then
				table.insert(week, { home = a, away = b })
			else
				table.insert(week, { home = b, away = a })
			end
		end
		table.insert(firstHalf, week)
		-- Rotate: fix arr[1], move the last element to position 2.
		local last = table.remove(arr)
		table.insert(arr, 2, last :: string)
	end

	-- Second half mirrors the first with home/away flipped.
	local schedule: { Week } = {}
	for _, week in firstHalf do
		table.insert(schedule, week)
	end
	for _, week in firstHalf do
		local mirrored: Week = {}
		for _, g in week do
			table.insert(mirrored, { home = g.away, away = g.home })
		end
		table.insert(schedule, mirrored)
	end
	return schedule
end

return Schedule
