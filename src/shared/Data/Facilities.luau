--!strict
-- Facility definitions + upgrade cost — shared so client and server agree on the numbers.

local Facilities = {}

Facilities.MAX_LEVEL = 10

Facilities.list = {
	{
		key = "training",
		name = "Training Center",
		icon = "🏋️",
		effect = "Players develop faster toward their potential",
	},
	{
		key = "rehab",
		name = "Medical & Rehab",
		icon = "🏥",
		effect = "Veterans decline slower and play longer",
	},
	{
		key = "stadium",
		name = "Stadium",
		icon = "🏟️",
		effect = "Bigger fanbase — more coaching credits each season",
	},
}

Facilities.default = { training = 1, rehab = 1, stadium = 1 }

-- Credits to go from `level` to `level + 1`.
function Facilities.costForNext(level: number): number
	return (level + 1) * 4
end

return Facilities
