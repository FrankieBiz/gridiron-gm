--!strict
-- The shape the sim engine returns and the result screen renders.

export type PlayEvent = {
	quarter: number,
	clock: string, -- "12:44"
	text: string, -- "TD! Redwoods RB 14yd run"
	homeScore: number,
	awayScore: number,
	big: boolean, -- highlight-worthy (TD / turnover / long)
}

export type TeamBox = {
	teamId: string,
	score: number,
	passYards: number,
	rushYards: number,
	turnovers: number,
	tds: number,
	fgs: number,
}

export type GameResult = {
	seed: number,
	homeId: string,
	awayId: string,
	home: TeamBox,
	away: TeamBox,
	plays: { PlayEvent },
	winnerId: string,
}

return {}
