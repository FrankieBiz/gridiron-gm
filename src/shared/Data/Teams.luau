--!strict
-- The fictional league identities. NO real NFL names/logos (legally clean + Roblox
-- rewards original metadata). Frank owns this list — add cities, rename, recolor freely.
-- Rosters are generated at franchise creation; this is just identity.

export type TeamIdentity = {
	id: string,
	city: string,
	name: string,
	abbr: string,
	primary: string,
	secondary: string,
}

local Teams: { TeamIdentity } = {
	{
		id = "RED",
		city = "Redwood",
		name = "Redwoods",
		abbr = "RED",
		primary = "#7A2E1D",
		secondary = "#E8C77A",
	},
	{
		id = "AVL",
		city = "Avalon",
		name = "Monarchs",
		abbr = "AVL",
		primary = "#1E2A55",
		secondary = "#C9A227",
	},
	{
		id = "IRN",
		city = "Ironport",
		name = "Anchors",
		abbr = "IRN",
		primary = "#14343B",
		secondary = "#4FB0C6",
	},
	{
		id = "STC",
		city = "Stone Creek",
		name = "Miners",
		abbr = "STC",
		primary = "#3A3A3A",
		secondary = "#F2A900",
	},
	{
		id = "SUN",
		city = "Sunspire",
		name = "Blaze",
		abbr = "SUN",
		primary = "#B23A16",
		secondary = "#F4E04D",
	},
	{
		id = "GLC",
		city = "Glacier",
		name = "Frost",
		abbr = "GLC",
		primary = "#2C5F8A",
		secondary = "#DDEBF5",
	},
	{
		id = "DUN",
		city = "Dunmoor",
		name = "Reapers",
		abbr = "DUN",
		primary = "#4B2E5A",
		secondary = "#9BE870",
	},
	{
		id = "CST",
		city = "Cinder Falls",
		name = "Foxes",
		abbr = "CST",
		primary = "#8A3B12",
		secondary = "#EDA24B",
	},
	{
		id = "HAR",
		city = "Harbor City",
		name = "Kraken",
		abbr = "HAR",
		primary = "#0E3B4A",
		secondary = "#3FD0C9",
	},
	{
		id = "MES",
		city = "Mesa Verde",
		name = "Coyotes",
		abbr = "MES",
		primary = "#7C4A1E",
		secondary = "#E0B15A",
	},
	{
		id = "NOR",
		city = "Northgate",
		name = "Sentinels",
		abbr = "NOR",
		primary = "#22303A",
		secondary = "#A9B7C2",
	},
	{
		id = "VOL",
		city = "Volta",
		name = "Surge",
		abbr = "VOL",
		primary = "#3A1C5A",
		secondary = "#F2D648",
	},
}

return Teams
