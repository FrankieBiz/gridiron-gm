--!strict
-- A team: identity (owned by design/Frank) + a generated roster.

local Player = require(script.Parent.Player)

export type Team = {
	id: string,
	city: string,
	name: string, -- nickname, e.g. "Redwoods"
	abbr: string, -- 2-3 letters, e.g. "RED"
	primary: string, -- hex color "#RRGGBB"
	secondary: string, -- hex color
	roster: { Player.Player },
}

return {}
